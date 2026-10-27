# Async Commands runtime fallback

Status: implemented in the D3D12 runtime.
Companion spec: [D3D12AsyncCommands.md](D3D12AsyncCommands.md).

- [Purpose and scope](#purpose-and-scope)
- [API surface covered](#api-surface-covered)
- [Enabling the fallback](#enabling-the-fallback)
  - [Opting in](#opting-in)
  - [Forcing the fallback](#forcing-the-fallback)
  - [Reporting which implementation is in use](#reporting-which-implementation-is-in-use)
  - [Queue scoping](#queue-scoping)
- [Per-API fallback design](#per-api-fallback-design)
  - [Copies](#copies)
  - [ResolveSubresourceRegionAsync](#resolvesubresourceregionasync)
  - [ResolveQueryDataAsync](#resolvequerydataasync)
  - [FillBuffers](#fillbuffers)
  - [ClearTextureSubresources](#cleartexturesubresources)
  - [Bound clears](#bound-clears)
- [Barriers and predication](#barriers-and-predication)
- [Shared runtime infrastructure](#shared-runtime-infrastructure)
- [Diagnostics](#diagnostics)
- [Tooling and partner impact](#tooling-and-partner-impact)
- [Test coverage](#test-coverage)
- [Performance testing](#performance-testing)
- [Known issues](#known-issues)
- [Appendix: route summary](#appendix-route-summary)

## Purpose and scope

Async Commands adds ten new command-list APIs on `ID3D12GraphicsCommandList12`.
Drivers that implement the new Async DDIs get them natively.
On everything else we want apps to be able to use the same API without writing a second code path, so the runtime can lower each call onto DDIs that drivers already support.
That lowering is what this spec covers.

The fallback is a runtime feature.
It doesn't need a new DDI, and native support always wins unless a developer forces the fallback for testing.
It's also opt-in: a device without native support only reports the feature when the app asks for the fallback or a developer forces it.

Everything the fallback emits is an existing DDI: copies, resolves, enhanced barriers, legacy clears, draws, and compute dispatches.
The fallback requires Enhanced Barriers, so it always uses them.
It only uses `ResolveSubresourceRegion` and `SetProgram` when the app's own calls already do.

The fallback can't do everything native drivers can, and it adds overhead for state tracking.
That's why it's opt-in rather than on by default.
Where a call can't be lowered at all, the runtime removes the command list with `E_FAIL` (or `E_INVALIDARG` for bad input).
A few routes can produce a slightly different value than a native clear would, for example rounding very large integer clear values.
Both kinds of case are listed per API below and collected under [known issues](#known-issues).

## API surface covered

| API | Fallback |
|---|---|
| `CopyBufferRegions` | Loop of `CopyBufferRegion` |
| `CopyTextureRegions` | Loop of `CopyTextureRegion` |
| `CopyResources` | Loop of `CopyResource` |
| `CopyTilesAsync` | One `CopyTiles` |
| `ResolveSubresourceRegionAsync` | One `ResolveSubresourceRegion` |
| `ResolveQueryDataAsync` | One `ResolveQueryData` |
| `FillBuffers` | Compute dispatch, or copies from a CPU-filled upload buffer |
| `ClearTextureSubresources` | Copy from a pattern buffer, an in-place clear through a private RTV/DSV, or a clear-and-copy through a private MSAA texture |
| `ClearBoundRenderTargetViews` | Runtime-owned draws inside a render pass; legacy `ClearRenderTargetView` where it's safe outside one |
| `ClearBoundDepthStencilView` | Same as above with `ClearDepthStencilView` |

The full per-route matrix is in the [appendix](#appendix-route-summary).

## Enabling the fallback

### Opting in

Apps opt in through the device factory before creating the device:

```c++
CComPtr<ID3D12DeviceFactory> factory;
RETURN_IF_FAILED(D3D12GetInterface(CLSID_D3D12DeviceFactory, IID_PPV_ARGS(&factory)));

CComPtr<ID3D12AsyncCommandsFallback> fallback;
if (SUCCEEDED(factory->GetConfigurationInterface(CLSID_D3D12AsyncCommandsFallback, IID_PPV_ARGS(&fallback))))
{
    RETURN_IF_FAILED(fallback->SetFallbackLayerEnabled(TRUE));
}

RETURN_IF_FAILED(factory->CreateDevice(adapter, D3D_FEATURE_LEVEL_12_0, IID_PPV_ARGS(&device)));
```

```c++
interface ID3D12AsyncCommandsFallback : IUnknown
{
    HRESULT SetFallbackLayerEnabled(BOOL Enable);
    BOOL GetFallbackLayerEnabled();
};
```

The setting shows up as `D3D12_DEVICE_FLAG_ASYNC_COMMANDS_FALLBACK_ENABLED` in `D3D12_DEVICE_CONFIGURATION_DESC::Flags`, and internally as `D3D_RUNTIME_STARTUP_OPTIONS::bAsyncCommandsFallbackEnabled`.

Opting in is a permission, not a preference.
If the driver supports Async Commands natively, the app still gets the native implementation.

The setting has to be in place before the device is created.
If a singleton device already exists with a different setting, creating another one through the same path fails, so apps (and tests) that change the setting partway through need to create the new device with `D3D12_DEVICE_FACTORY_FLAG_DISALLOW_STORING_NEW_DEVICE_AS_SINGLETON` or from a separate factory.

### Forcing the fallback

For testing, developers can force the fallback on a device that has native support:

```
d3dconfig device force-async-commands-fallback=true
```

This sets the `ForceAsyncCommandsFallback` app-compat behavior, which the runtime reads into `D3D_RUNTIME_STARTUP_OPTIONS::bAsyncCommandsForceFallback`.
Forcing doesn't require the app to opt in.
It still can't get around the Enhanced Barriers requirement: on a device without Enhanced Barriers, forcing does nothing, and the device reports whatever it would have reported anyway.

The forced setting is kept separate from the app's own opt-in, so turning forcing off doesn't change what the app asked for.

### Reporting which implementation is in use

`D3D12_FEATURE_DATA_ASYNC_COMMANDS` reports a tri-state instead of a `BOOL`:

```c++
typedef enum D3D12_ASYNC_COMMANDS_IMPL
{
    D3D12_ASYNC_COMMANDS_IMPL_NOT_SUPPORTED    = 0,
    D3D12_ASYNC_COMMANDS_IMPL_FALLBACK         = 1,
    D3D12_ASYNC_COMMANDS_IMPL_NATIVE           = 2,
} D3D12_ASYNC_COMMANDS_IMPL;

typedef struct D3D12_FEATURE_DATA_ASYNC_COMMANDS
{
    D3D12_ASYNC_COMMANDS_IMPL Impl;
} D3D12_FEATURE_DATA_ASYNC_COMMANDS;
```

Apps that only care whether they can call the APIs check `Impl != D3D12_ASYNC_COMMANDS_IMPL_NOT_SUPPORTED`.
Apps that care about performance can tell the two implementations apart.

The runtime picks the value once, at device creation:

* `FALLBACK` if the device supports Enhanced Barriers and either the fallback is forced, or the app opted in and the driver doesn't support Async Commands natively.
* Otherwise `NATIVE` if the driver reports the Async Commands DDI and feature version.
* Otherwise `NOT_SUPPORTED`.

Enhanced Barriers is required because the Async APIs are specified entirely in terms of enhanced barrier sync, access, and layout values, and the fallback tracks resource state that way.
The `FillBuffers` compute path also needs feature level 11_0 and DXIL; without them, fills use the CPU upload route.

The Enhanced Barriers requirement only applies to the fallback.
A native driver on a device without Enhanced Barriers still reports `NATIVE`.

### Queue scoping

The fallback keeps the queue rules of each API.

| API | Direct | Compute | Copy | Bundle | Render pass |
|---|---|---|---|---|---|
| `CopyBufferRegions`, `CopyTextureRegions`, `CopyResources`, `CopyTilesAsync` | ✓ | ✓ | ✓ | | |
| `ResolveQueryDataAsync` | ✓ | ✓ | ✓ | | |
| `ResolveSubresourceRegionAsync` | ✓ | | | | |
| `FillBuffers`, `ClearTextureSubresources` | ✓ | ✓ | | | |
| `ClearBoundRenderTargetViews`, `ClearBoundDepthStencilView` | ✓ | | | Native only | ✓ |

Bound clears are legal in bundles at the API level, but the fallback doesn't support them there yet.
See [bound clears in bundles](#bound-clears-in-bundles).

## Per-API fallback design

### Copies

`CopyBufferRegions`, `CopyTextureRegions`, and `CopyResources` loop over the matching legacy call.
`CopyTilesAsync` becomes one `CopyTiles` call, with `Flags` passed through unchanged.
Copies were already async-safe at the DDI level, so there's nothing else to do.

The debug layer already checks `CopyBufferRegions` for overlapping destinations and source/destination conflicts within one call before the fallback runs.
The serialized loop is one of the orderings native hardware is allowed to use, so a correct app can't tell the difference.

### ResolveSubresourceRegionAsync

One `ResolveSubresourceRegion` call.
Like the legacy API, this is direct-queue only and not allowed in bundles.

### ResolveQueryDataAsync

One `ResolveQueryData` call.

Upload-heap destinations are rejected with `E_INVALIDARG` for both the native and fallback paths, the same as legacy `ResolveQueryData`.
An `UPLOAD` heap can't be a copy destination, so there's no reasonable way to support it.
Default and readback destinations go straight through.

### FillBuffers

Each fill takes one of two routes.

**Compute.**
A small runtime-owned compute shader writes the pattern through a root UAV.
A fill can use it when:

* the device created the fill pipeline (feature level 11_0 and DXIL),
* the list is a direct or compute list without a protected session, and the destination isn't protected,
* the destination isn't in an `UPLOAD` or `READBACK` heap,
* the offset and byte count are both multiples of 4, since the shader writes whole dwords,
* the runtime is tracking the buffer's barrier state, so it can put it back after the dispatch. If tracking isn't available (for example, after running out of memory), every fill uses CPU upload,
* the app's compute state can be restored exactly afterward, and
* the buffer can be a UAV. On drivers at DDI 0022 or later every buffer is UAV-capable; on older drivers, the app has to have created the buffer with `D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS`.

The pattern is encoded into root constants, so every valid pattern size works, including 12-byte patterns on non-reserved buffers.

**CPU upload.**
Everything else uses copies from an upload buffer that the runtime fills on the CPU.
Each source chunk is at most 1 MiB.
If the next fill in the same recording uses the same pattern, the runtime reuses the last chunk instead of filling a new one.
On discrete GPUs, unprotected fills larger than one chunk first copy into a private VRAM staging block, and the repeated copies into the destination read from VRAM instead of the upload heap.

All fills in a call are planned before anything is recorded.
Runs of fills that take the same route are recorded together, so fills in the same call that overlap may land in any order.
That matches the public spec, which doesn't define an order for overlapping fills.

Formatted fills (`Format != DXGI_FORMAT_UNKNOWN`) require the format to report `D3D12_FORMAT_SUPPORT1_BUFFER`.
Fills into reserved buffers are limited to element sizes of 1, 2, 4, 8, or 16 bytes for both raw and formatted patterns, and that's checked before a route is picked.

### ClearTextureSubresources

`ClearTextureSubresources` is the main reason apps want Async Commands: clearing textures that weren't created with RTV/DSV/UAV flags, on direct and compute lists.
The fallback picks one of three routes per texture.

**Pattern copy.**
The runtime builds a tile of the encoded clear value in an upload buffer and copies it into each target region with `CopyTextureRegion`.
The upload tiles are written once on the CPU and cached by byte pattern and footprint in the command allocator, so any command list using that allocator can reuse them until it's reset.
On discrete GPUs the tiles can be staged through VRAM first.
The VRAM staging blocks belong to a single recording, and every `ClearTextureSubresources` call copies its tiles into them again before using them, so no command list ever depends on a staging copy made by another list.
Depth/stencil formats are handled one plane at a time.
This route handles single-sample textures on direct and compute lists, as long as the format can be encoded and the region can be copied.
It's the only route on compute lists.

**In-place clear.**
On direct lists, if the texture allows render target or depth stencil, the runtime creates a private RTV or DSV and calls the legacy clear.
That only happens when all of the following hold:

* the texture isn't 1D, and if it's a color texture it has a single plane,
* there's no protected session on the list or the texture,
* the texture doesn't use `ALLOW_SIMULTANEOUS_ACCESS`,
* the runtime knows the texture's layout and it's one the clear can transition out of and back to (`COMMON`, `COPY_DEST`, or the direct-queue versions of those),
* the clear format supports render target or depth stencil on this device and can be viewed that way, and
* for single-sample textures, the view clear produces exactly the same bits as the requested value. Otherwise the texture uses the pattern copy.

MSAA textures can't use the pattern copy, so when the value can't be produced exactly they still clear in place with the closest value a legacy view clear can take.
See [inexact clear values](#inexact-clear-values) for what that means in practice.

The runtime transitions the texture to `RENDER_TARGET` or `DEPTH_STENCIL_WRITE`, clears, and transitions it back.

For partial-region clears of single-sample textures on discrete GPUs, we only use the in-place route when the region covers more than a quarter of the subresource.
At a quarter or less we use the pattern copy, since in a region sweep on a 4K target the layout transitions cost more than the clear itself.
This doesn't apply to MSAA textures, or to depth/stencil textures on devices where a partial copy isn't legal; those stay on the in-place route.
On UMA we use the in-place route whenever it's available.

**MSAA clear-and-copy.**
MSAA textures can't use the pattern copy, since copies don't reach individual samples.
On direct lists, the runtime either clears in place (if the texture allows it) or clears a private MSAA texture with the same sample count and copies that into the target.
That second path works even when the target has no RT/DS flags.
For depth/stencil, the private texture uses the matching combined depth/stencil format.
It needs the format, sample count, and quality to be supported for MSAA rendering, and neither the list nor the target can be protected.
On devices without programmable sample positions, the copy has to cover the whole subresource.
The private clear takes the same closest value as the in-place route when the exact value isn't possible.

The main cases the fallback rejects:

* MSAA textures on compute lists. There's no copy route and no way to clear MSAA on compute.
* MSAA textures with a protected list or target, or with a format and sample count that can't be rendered.
* Partial-region clears on devices without programmable sample positions when the in-place route isn't available. That covers depth/stencil textures (single-sample or MSAA) and MSAA color textures. Copying into part of those subresources isn't legal on those devices.
* Formats or regions the pattern copy can't represent.

These remove the command list with `E_FAIL`.

On compute lists, single-sample depth/stencil clears use the pattern copy like anything else.
The only depth/stencil-specific rejection there is a partial region on a device without programmable sample positions, since the in-place route isn't available on compute.
Whole subresources are fine, and so are partial regions on devices that support programmable sample positions.

### Bound clears

`ClearBoundRenderTargetViews` and `ClearBoundDepthStencilView` clear whatever is currently bound, so they're the APIs most tied to graphics state.
They're direct-list only in the fallback.

#### Inside a render pass

Inside an open render pass the fallback draws.
Like any other GPU work, a bound clear between a suspending `EndRenderPass` and the resuming `BeginRenderPass` is rejected with `E_FAIL`.
Ending the pass for a legacy clear would cost a tile store and reload on tile-based hardware, which defeats the point of clearing inside the pass.

Each selected region is clipped to the target and becomes one draw of a three-vertex, full-viewport triangle with a scissor.
Array slices get one draw each, and the vertex shader writes `SV_RenderTargetArrayIndex` from a root constant.
Empty regions or slice ranges are skipped.

`ClearBoundRenderTargetViews` writes the clear value to the selected render targets with a color write mask so that nothing else changes.
`ClearBoundDepthStencilView` uses one pixel shader that writes depth, and the PSO controls which planes are written.
A stencil-only clear turns off depth writes, and stencil is masked out for formats without stencil.

Raster output is limited to the smallest bound render target or depth buffer.
If a selected region goes past that, the fallback can't draw it, so inside a pass the command list is removed with `E_FAIL`.
Bound outputs with different sample counts are also rejected inside a pass, as is app state the fallback can't restore.

Writing to a read-only depth or stencil plane is rejected with `E_INVALIDARG`, as is clearing a depth or stencil plane whose beginning access is `NO_ACCESS` inside a pass.

#### Outside a render pass

Outside a render pass, the fallback uses legacy clears where they produce the same result:

* Whole-view clears go straight to `ClearRenderTargetView` when every selected target is a float format and every value is finite and not subnormal.
* Whole-view depth/stencil clears go straight to `ClearDepthStencilView`.
* Regions past the smallest bound output, mixed sample counts, and app state the fallback can't restore all fall back to legacy clears, with regions passed as rects. These can't draw, so they use the legacy clear even when the value isn't exact. See [inexact clear values](#inexact-clear-values).

The app can change or free its RTV and DSV CPU descriptors as soon as `OMSetRenderTargets` or `BeginRenderPass` returns, so the runtime can't read them at clear time.
Instead it captures the resource and view description when the targets are bound, and the legacy clears create private descriptors from that capture.
The capture doesn't hold a reference on the resource, so the app still has to keep it alive, the same as with any bound target.

Everything else draws, the same as inside a pass.

#### State save and restore

The draws need their own root signature, PSO, viewport, scissor, and so on.
The runtime keeps track of the app's graphics state as it's set, and restores it after the draws:

* the pipeline: a legacy PSO, a `SetPipelineState1` state object, or a `SetProgram` generic program, plus any dynamic depth-bias and strip-cut overrides,
* the graphics root signature and all root arguments,
* topology, viewports, scissors, and stencil references, and
* the variable-rate shading base rate and combiners. The fallback sets these to 1x1 and passthrough for its draws, then puts them back. The shading-rate image stays bound.

State is only recorded after the runtime has forwarded a call and the command list is still healthy.
If the app is using a pipeline mode the fallback can't replay exactly, it doesn't draw: outside a pass it uses legacy clears, and inside a pass it removes the command list.

Descriptor heaps aren't touched, since the clear shaders only use root constants.

#### Pipeline cache

The device owns one root signature and a cache of up to 64 clear PSOs.
The key covers the render target formats and count, the depth format, sample count and quality, the target slot, the output class (float, uint, or sint), and the depth/stencil flags.
PSOs are created lazily the first time a combination is used, so the first clear with a new format combination pays for a PSO creation during recording.
Command allocators keep the PSOs they used alive until they're reset, so evicting a cache entry is always safe.

#### Predication and queries

Predication stays bound during the draws, so a predicated-off bound clear doesn't happen.
Active queries stay active, so the draws count toward occlusion and pipeline-statistics queries like any other draw.
That means query results around a bound clear won't match what a native driver reports.
Legacy clears outside a pass count the way legacy clears always have.

#### Missing outputs

A selected render target slot with nothing bound (or past the bound count) is skipped.
A depth/stencil clear with no DSV bound does nothing.
The debug layer reports both as errors.
See [null and unbound outputs](#null-and-unbound-outputs).

#### Render pass slot numbering

Outside a render pass, `RenderTargetMask` bit `i` refers to slot `i` from `OMSetRenderTargets`, as the companion spec says, and the fallback reads `pClearValues[i]`, `pNumRegions[i]`, and `ppRegions[i]` for that same slot.
Inside a render pass, slot `i` is the `i`th render target the pass binds for drawing.
Render targets whose beginning access is `NO_ACCESS`, `PRESERVE_LOCAL_SRV`, or `PRESERVE_LOCAL_UAV` aren't bound, so the ones after them move down a slot.
That's the same binding the runtime's render pass emulation and the debug layer use, and WARP uses the same numbering.
Slots that aren't selected in the mask are ignored.

## Barriers and predication

The Async Commands APIs use the existing enhanced barrier sync and access bits.
There are no Async-specific bits, and the runtime doesn't remap anything.
Instead, each fallback route leaves the destination in the scope the app's barriers already expect for that API:

* **Copies, `CopyTilesAsync`, and the resolves** are the legacy operations, so they're in the normal copy and resolve scopes.
* **`FillBuffers` on the copy route** and **`ClearTextureSubresources` on the pattern-copy and MSAA clear-and-copy routes** write the destination with copies, so the writes are in `COPY` / `COPY_DEST`. The runtime doesn't add barriers on the app's resource.
* **`FillBuffers` on the compute route** transitions the buffer from its tracked scope to `COMPUTE_SHADING` / `UNORDERED_ACCESS`, dispatches, and transitions it back to `COPY` / `COPY_DEST`.
* **`ClearTextureSubresources` in place** transitions the texture from its tracked scope and layout to render target or depth-write, clears, and transitions it back to `COPY` / `COPY_DEST` in the layout it started in.
* **Bound clears**, both the draws and the legacy clears, write in `RENDER_TARGET` or `DEPTH_STENCIL` scope, the same as a native bound clear. There's no extra barrier on the app's resource.

So an app's barrier after a fill or texture clear only has to cover `COPY` / `COPY_DEST`, whichever route the runtime took, and a barrier after a bound clear only has to cover render target or depth/stencil writes.
Barriers on the runtime's private staging buffers and MSAA textures are internal.

The fallback never changes the app's predication.
All of its internal work, including staging copies, view clears, dispatches, and draws, is predicated the same way the app's own work is.
A staging copy that gets predicated away is never treated as holding valid data later, since staging is refreshed on every call.

## Shared runtime infrastructure

**Command-allocator-owned resources.**
The GPU-visible things the fallback creates during recording (upload chunks, pattern tiles, VRAM staging blocks, descriptor blocks) belong to the command allocator.
They're recycled only after the allocator has been reset successfully, which is the point where the app guarantees the GPU is done with them.
Resetting a command list releases its tracked state, but doesn't recycle any of those.

**Buffer pools.**
Upload and VRAM staging buffers come from size-classed pools that share one 128 MiB budget for buffers kept between uses.
Protected or unhealthy cases skip recycling.

**Descriptor blocks.**
Private RTVs and DSVs come from small CPU descriptor heaps, normally 64 descriptors each, that are used linearly and reset with the allocator.
The texture clear routes and the outside-pass bound clears use these.

**Resource scope tracking.**
The fallback tracks each touched resource's state with an open-addressing pointer table.
That's what lets the compute and in-place clear routes know the layout they have to restore, and what lets the runtime dedupe destinations within a batch.
When GPU-based validation emulates render passes, the barriers it records go through the tracker too, so the two stay in sync.

**Root signature layouts.**
Each root signature used while the fallback is active gets a compact, immutable description of its layout when it's created.
That's what the state save and restore uses to replay the app's root arguments.

## Diagnostics

When the fallback can't lower a call, it removes the command list, and `Close` returns the failure.
Where the API already has a message for the problem, the fallback uses it, for example `RESOLVE_QUERY_DATA_INVALID_PARAMETERS` for upload-heap query resolves.
Otherwise it reports `D3D12_MESSAGE_ID_ASYNC_COMMANDS_FALLBACK_UNSUPPORTED`, an `EXECUTION` error whose text names the API and why the fallback can't lower the call.
That's the fallback's only message ID.
Allocation failures still remove the command list as out of memory.

## Tooling and partner impact

* **IHVs** don't need to implement anything new. The fallback uses DDIs they already have, and a native implementation of the Async DDIs is preferred unless the fallback is forced. The fallback does emit draw and barrier combinations apps might not, so driver validation is still worth doing.
* **WARP** implements the Async DDIs natively and also runs the forced fallback. Several tests select WARP directly.
* **API and SDK**: the tri-state `Impl`, `ID3D12AsyncCommandsFallback`, `CLSID_D3D12AsyncCommandsFallback`, `D3D12_DEVICE_FLAG_ASYNC_COMMANDS_FALLBACK_ENABLED`, and `D3D12_MESSAGE_ID_ASYNC_COMMANDS_FALLBACK_UNSUPPORTED` are new since the earlier preview headers. Those headers had a `BOOL Supported` field in the same place. Code built against those headers that tests `Supported` as a boolean keeps working, but code that compares `Supported == TRUE` will treat `NATIVE` (2) as unsupported. The preview SDK shipped the old field, but preview APIs can change before release, so this goes in the release notes.
* **ISVs** opt in, so nothing changes for apps that don't ask for the fallback unless a developer forces it.
* **GPU-based validation** sees the legacy DDIs the fallback emits. The main integration point is the render pass barrier tracking mentioned above.

## Test coverage

The functional tests are in `src/d3dtest/func/d3d12/AsyncCommands`.
Besides the original `AsyncCommands.cpp` coverage, there are suites for bound clears (dispatch, readback, robustness, ledger, metadata, plan), texture clears (copy route, in-place route, plan), fill encoding, the pointer table, and cross-feature dynamic state.
The device-backed tests check the effective `Impl` instead of the old `Supported` field. The planner, encoder, ledger, metadata, and pointer-table tests exercise the helpers directly without a device.

Fallback coverage comes from rerunning tests with the fallback forced.
The tests turn on the `ForceAsyncCommandsFallback` behavior with a scoped guard, so they run against WARP or native hardware without changing machine settings.
There are also tests for how opt-in and forcing interact, including forcing on a device without Enhanced Barriers.
Route-specific tests use DDI spies to check which legacy calls get emitted.

The `D3D12Conf` AsyncCommands tests also check `Impl`.
`D3D12Conf` doesn't have its own way to force the fallback, so running it against the fallback needs the fallback configured outside the suite first, for example with `d3dconfig`.
The `FillBuffers` formatted-fill tests skip formats that don't report `D3D12_FORMAT_SUPPORT1_BUFFER`.

## Performance testing

We want to know three things on the same machine:

* **Legacy**: the app does it the old way, with its own clear loops and fill copies.
* **Fallback**: the Async APIs with the fallback forced.
* **Native**: the Async APIs on a native driver.

Fallback against Legacy is the number that matters most.
The fallback should be reasonably close to what an app would have written by hand, though we expect some overhead due to the extra burden of state tracking in the runtime.
Native against Fallback shows the use cases where native provides the most benefit.

All three have to run on the same machine, since comparing numbers across hardware tells us nothing.
Use `d3dconfig` to force the fallback for the Fallback runs, and check `Impl` after creating each device to confirm you got the implementation you meant to.
If a device reports `NOT_SUPPORTED`, check that it supports Enhanced Barriers before assuming the machine just can't run the fallback.

The things we expect to be expensive, and want numbers for:

* first use of a new format combination in a bound clear, since that creates a PSO during recording,
* bound clears inside a pass compared to native clears, since the draws don't get any hardware fast-clear or compression-metadata benefits a native clear might have, and
* `ClearTextureSubresources` and `FillBuffers` on large resources, across the copy, in-place, and compute routes.

The perf harness is tracked separately, in the DirectX-Graphics-Samples repo.

## Known issues

### Bound clears in bundles

Native bound clears can be recorded in a bundle and pick up the parent list's bindings when the bundle runs.
The fallback can't do that: it would need to record the clear without knowing what's bound and then lower it when the bundle executes, but `ExecuteBundle` hands the driver's own bundle to the driver.
For now the fallback rejects bound clears recorded in bundles.

The runtime already keeps a summary of each bundle's state changes so the parent list's tracking stays right after `ExecuteBundle`.
Supporting bound clears in bundles needs some way to put off lowering the clear until the bundle runs.
One option is for the runtime to record and replay the bundle itself, which is a lot more work and has its own memory and CPU costs.
We'd want to see whether apps actually use bound clears in bundles before doing that.

### Null and unbound outputs

The runtime skips selected render target slots with nothing bound, and does nothing for a depth/stencil clear with no DSV bound.
The debug layer reports both as errors.
We need to decide whether the runtime should also reject them, or whether skipping them is the intended behavior, and make the companion spec say the same thing.

### Inexact clear values

Two routes can produce a value that's slightly different from what a native clear would produce:

* `ClearTextureSubresources` on MSAA textures, both in place and through the private MSAA texture.
* `ClearBoundRenderTargetViews` and `ClearBoundDepthStencilView` outside a render pass, when they fall back to a legacy clear because the region is past the smallest output, the sample counts are mixed, or the app's state can't be restored.

Both go through a legacy view clear, which takes float color values.
Integer values are converted to float, so `UINT` and `SINT` values with a magnitude above 2^24 can round.
Float subnormals are flushed to zero, keeping the sign.
NaN values are passed to the driver, but the stored NaN payload isn't guaranteed.
Depth is clamped to [0, 1], with NaN and negative zero mapped to +0.
There's no debug-layer message when this happens.

Single-sample texture clears never approximate: if the view clear can't produce the exact value, they use the pattern copy, or are rejected if the pattern copy isn't possible either.
Bound-clear draws pass integer values straight through to `UINT` / `SINT` shader outputs, so they don't lose precision.

## Appendix: route summary

| API | Route | Notes |
|---|---|---|
| `CopyBufferRegions` | `CopyBufferRegion` per region | |
| `CopyTextureRegions` | `CopyTextureRegion` per region | |
| `CopyResources` | `CopyResource` per pair | |
| `CopyTilesAsync` | `CopyTiles` | Flags unchanged |
| `ResolveSubresourceRegionAsync` | `ResolveSubresourceRegion` | Direct only |
| `ResolveQueryDataAsync` | `ResolveQueryData` | `UPLOAD` destination rejected |
| `FillBuffers` | Compute dispatch | Direct/compute, dword-aligned, tracked barrier state, restorable compute state, UAV-capable buffer |
| | Copies from a CPU-filled upload buffer | Everything else; 1 MiB chunks, VRAM staging for large unprotected fills on discrete GPUs |
| `ClearTextureSubresources` | Pattern copy | Single-sample, encodable format, copyable region; the only route on compute |
| | In-place RTV/DSV clear | Direct, RT/DS-capable, known layout; exact clear value for single-sample; single-sample partial regions on discrete GPUs need more than 1/4 coverage unless a partial copy isn't legal |
| | MSAA clear-and-copy | Direct, MSAA, unprotected, renderable format and sample count, when in-place isn't possible |
| | Rejected | MSAA on compute; protected or unrenderable MSAA; partial depth/stencil or MSAA copies on devices without programmable sample positions; formats or regions the copy can't represent |
| `ClearBoundRenderTargetViews` | Draws | Inside a pass, or outside a pass when there's no legacy shortcut |
| | Legacy `ClearRenderTargetView` | Outside a pass: whole-view float clears with finite, non-subnormal values; regions past the smallest output; mixed sample counts; state that can't be restored |
| | Rejected | Bundles; suspended render pass; inside a pass with regions past the smallest output, mixed sample counts, or state that can't be restored |
| `ClearBoundDepthStencilView` | Draws | Inside a pass, or outside a pass when there's no legacy shortcut |
| | Legacy `ClearDepthStencilView` | Outside a pass: whole-view clears, regions past the smallest output, mixed sample counts, state that can't be restored |
| | Rejected | Bundles; suspended render pass; read-only planes; inside a pass with regions past the smallest output, mixed sample counts, state that can't be restored, or a `NO_ACCESS` plane |
