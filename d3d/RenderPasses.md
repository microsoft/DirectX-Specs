<h1>D3D12 Render Passes</h1>

Version 1.14
2/20/2023

---

<h1>Contents</h1>

- [Background](#background)
- [Optimization Goals](#optimization-goals)
  - [Goals](#goals)
    - [Allow applications to avoid unnecessary loads/stores of resources from/to main memory on TBDR architectures](#allow-applications-to-avoid-unnecessary-loadsstores-of-resources-fromto-main-memory-on-tbdr-architectures)
    - [Allow TBDR architectures to opportunistically persistent resources in on-chip cache across Render Passes (even in separate Command Lists)](#allow-tbdr-architectures-to-opportunistically-persistent-resources-in-on-chip-cache-across-render-passes-even-in-separate-command-lists)
      - [Case A: Reading/Writing One-to-One](#case-a-readingwriting-one-to-one)
      - [Case B: Writes to the same Render Targets across multiple Command Lists](#case-b-writes-to-the-same-render-targets-across-multiple-command-lists)
    - [Allow the new APIs to be used on drivers that don't take advantage of them](#allow-the-new-apis-to-be-used-on-drivers-that-dont-take-advantage-of-them)
    - [Design allows UMD to choose optimal rendering path without heavy CPU penalty](#design-allows-umd-to-choose-optimal-rendering-path-without-heavy-cpu-penalty)
    - [Allow ISVs to verify proper use of the feature even on drivers that aren't necessarily making behavior changes based on feature use](#allow-isvs-to-verify-proper-use-of-the-feature-even-on-drivers-that-arent-necessarily-making-behavior-changes-based-on-feature-use)
  - [Non-goals](#non-goals)
- [API Summary](#api-summary)
  - [Render Pass output bindings](#render-pass-output-bindings)
  - [Render Pass workloads](#render-pass-workloads)
    - [Resource Barriers within a Render Pass](#resource-barriers-within-a-render-pass)
  - [Resource Access declaration](#resource-access-declaration)
    - [D3D12\_RENDER\_PASS\_BEGINNING\_ACCESS\_DISCARD](#d3d12_render_pass_beginning_access_discard)
    - [D3D12\_RENDER\_PASS\_BEGINNING\_ACCESS\_PRESERVE](#d3d12_render_pass_beginning_access_preserve)
    - [D3D12\_RENDER\_PASS\_BEGINNING\_ACCESS\_CLEAR](#d3d12_render_pass_beginning_access_clear)
    - [D3D12\_RENDER\_PASS\_BEGINNING\_ACCESS\_NO\_ACCESS](#d3d12_render_pass_beginning_access_no_access)
    - [D3D12\_RENDER\_PASS\_BEGINNING\_ACCESS\_TYPE\_PRESERVE\_LOCAL\_RENDER](#d3d12_render_pass_beginning_access_type_preserve_local_render)
    - [D3D12\_RENDER\_PASS\_BEGINNING\_ACCESS\_TYPE\_PRESERVE\_LOCAL\_SRV](#d3d12_render_pass_beginning_access_type_preserve_local_srv)
    - [D3D12\_RENDER\_PASS\_BEGINNING\_ACCESS\_TYPE\_PRESERVE\_LOCAL\_UAV](#d3d12_render_pass_beginning_access_type_preserve_local_uav)
    - [D3D12\_RENDER\_PASS\_ENDING\_ACCESS\_DISCARD](#d3d12_render_pass_ending_access_discard)
    - [D3D12\_RENDER\_PASS\_ENDING\_ACCESS\_PRESERVE](#d3d12_render_pass_ending_access_preserve)
    - [D3D12\_RENDER\_PASS\_ENDING\_ACCESS\_PRESERVE\_LOCAL\_RENDER](#d3d12_render_pass_ending_access_preserve_local_render)
    - [D3D12\_RENDER\_PASS\_ENDING\_ACCESS\_PRESERVE\_LOCAL\_SRV](#d3d12_render_pass_ending_access_preserve_local_srv)
    - [D3D12\_RENDER\_PASS\_ENDING\_ACCESS\_PRESERVE\_LOCAL\_UAV](#d3d12_render_pass_ending_access_preserve_local_uav)
    - [D3D12\_RENDER\_PASS\_ENDING\_ACCESS\_RESOLVE](#d3d12_render_pass_ending_access_resolve)
    - [D3D12\_RENDER\_PASS\_ENDING\_ACCESS\_NO\_ACCESS](#d3d12_render_pass_ending_access_no_access)
  - [Render Pass Flags](#render-pass-flags)
    - [UAV writes within a Render Pass](#uav-writes-within-a-render-pass)
    - [Suspend and Resume](#suspend-and-resume)
    - [Read Only Depth Stencil](#read-only-depth-stencil)
  - [Surfaces That BeginRenderPass Binds For Raster](#surfaces-that-beginrenderpass-binds-for-raster)
  - [Surface Flow Between Passes](#surface-flow-between-passes)
    - [State At End Of Command List](#state-at-end-of-command-list)
  - [Local Compute Access Mode](#local-compute-access-mode)
  - [Checking for Support](#checking-for-support)
    - [Minimum Driver DDI version](#minimum-driver-ddi-version)
- [API Headers](#api-headers)
- [Runtime validation](#runtime-validation)
- [HLK Testing](#hlk-testing)
- [History of changes](#history-of-changes)

---

# Background

Render Passes are intended to help TBDR-based (and other) renderers
improve GPU efficiency by reducing memory traffic to/from off-chip
memory, by enabling applications to better identify resource rendering
ordering requirements/data dependencies.

# Optimization Goals

## Goals

### Allow applications to avoid unnecessary loads/stores of resources from/to main memory on TBDR architectures

This feature introduces the concept of Render Passes, which are intended
to provide a central location for applications to indicate their data
dependencies for a set of rendering operations.

These data dependencies are intended to allow drivers to inspect this
data at bind/barrier time, and issue instructions that minimize resource
loads/stores from/to main memory.

### Allow TBDR architectures to opportunistically persistent resources in on-chip cache across Render Passes (even in separate Command Lists)

#### Case A: Reading/Writing One-to-One

A common rendering pattern is for an application to render to RTV A, then turn around and texture from that resource as SRV A at some time in future (while rendering to RTV B). For cases in which the writes to RTV B are reading from pixels 'one-to-one' (mapped to the identical location in SRV A), some architectures may be able to continue the current binning pass during the writes to RTV A, and avoid a flush to main memory (since the SRV A reads only have a dependency on the current tile).

A design goal is to enable these two passes to be coalesced, without a intervening flush to main memory.

This goal was postponed from the first version of render passes - justification at the time being that ISV scenarios that would benefit were not common.  An updated version of renderpasses does tackle this one-to-one paradigm.  The justification now is that even if the scenarios are rare, allowing devices that do care about this to be programmed efficiently is worth it, particularly given the small API change needed.  See `PRESERVE_LOCAL_RENDER`, `PRESERVE_LOCAL_SRV` and `PRESERVE_LOCAL_UAV` in this spec.

#### Case B: Writes to the same Render Targets across multiple Command Lists

Another common rendering pattern is for the application to render to the
same render target(s) across multiple command lists serially, even
though the rendering commands are generated in parallel. This design
seeks to allow drivers to avoid a flush to main memory on Command List
boundaries, when the application knows it will resume rendering on the
immediate succeeding Command List.

A design goal is to allow these two passes to be combined in a way that
avoids an intervening flush to main memory.

### Allow the new APIs to be used on drivers that don't take advantage of them

The design allows the APIs to be called on drivers that don't take advantage of the feature.
As long as the application is running on a sufficiently new runtime
(which can be ensured via AgilitySDK), RenderPasses
can be used on all devices.  Apps can write one path.  
Devices that don't care will get runtime translation of the feature to non-render passes. 
And devices that do want to take advantage can do so.

### Design allows UMD to choose optimal rendering path without heavy CPU penalty

This feature should be aligned with the low CPU-overhead goals of D3D12,
and should be designed in such a way to not significantly impact CPU
usage for common rendering workloads (no more than \~20%).

### Allow ISVs to verify proper use of the feature even on drivers that aren't necessarily making behavior changes based on feature use

The debug layer should be able to help identify incorrect use of the
feature even when running on a non-supporting driver. (e.g. how the DX11
debug layer clears a resource to a random color in response to a Discard
call).

---

## Non-goals

- This design relies on applications to properly identify
    data/ordering dependencies for its operations, it does not intend to
    allow the runtime or driver to deduce opportunities to
    re-order/avoid loads and stores.

- The design does not seek to remove/reduce the need for resource
    barriers, or resource state tracking by applications (there would
    obviously be value in that, but that is orthogonal from this
    feature).

- Automatic fixing of 'bad app behavior' (e.g. unneeded copies/clears)
    -- our preferred solution is the automated performance warnings
    already in PIX (which continue to be added).

- Allow re-ordering of workloads based on app-indicated flexible
    ordering dependencies. This design optimizes for apps ordering their
    own submissions in a way that reduces flushes (e.g. maximizing use
    of a _RESUME flags, and minimizing use of _PRESERVE).

---

# API Summary

A Render Pass is defined by:

- A set of output bindings (RTVs, DSV) fixed for the duration of the
    Render Pass, and

- A list of GPU operations that target that set of output bindings,
    and

- Metadata that describes the load/store dependencies for all output
    bindings targeted by the Pass, and

- (optionally) an object that identifies the Render Pass as a
    specific, persistent workload where the cost of any upfront
    PGO-style training is likely worth future gains.

  - This last area is not currently in the spec, but may be
        addressed in a future iteration.

---

## Render Pass output bindings

Render Target and Depth Buffer bindings are declared at the start of a
Render Pass, directly in the ID3D12GraphicsCommandList::BeginRenderPass
call.

The BeginRenderPass call accepts the lists of RTVs/DSV -- either are
optional, though at least one must be specified. All bindings are via
CPU descriptors, and like OMSetRenderTargets they are 'snapped' at
BeginRenderPass time from their respective (CPU) descriptor heaps.

RTVs/the DSV are not inherited into the Render Pass, they must be set.
The RTVs/DSV set in BeginRenderPass the Render Pass are *not* propagated
out to the Command List; they are in an undefined state following the
Render Pass (the driver does not need to manually clear these to
something well-defined).

For more detail, see [Surfaces that BeginRenderPass For Raster](#surfaces-that-beginrenderpass-binds-for-raster).

---

## Render Pass workloads

A Render Pass is a subset of commands within a Command List, a Command
List may contain multiple Render Passes. The boundaries of a Render Pass
are declared explicitly on the Command List via the
BeginRenderPass/EndRenderPass Command List APIs.

Render Passes may not be nested, and they must be ended within the
current Command List (they cannot straddle Command Lists, see below for
optimizations designed to enable efficient multi-threaded Render Pass
generation).

Writes from within a Render Pass are not 'valid' to be read until the
end of the Render Pass. This precludes some types of barriers from
within the Render Pass (e.g. barriering from `RENDER_TARGET` to
`SHADER_RESOURCE` on the currently-bound render target), but some other
barriers may be allowed. See sub-section below for more details.

The sole exception to the 'no reads on writes that occurred within the
render pass' are the implicit reads that occur as part of depth-testing
and render target blending.

Thus, the list of disallowed APIs within a Render Pass is:

- AtomicCopyBuffer*

- BeginRenderPass

- ClearState

- ClearRenderTargetView

- ClearDepthStencilView

- ClearUnorderedAccessViewUint

- ClearUnorderedAccessViewFloat

- CopyBufferRegion

- CopyTextureRegion

- CopyResource

- CopyTiles

- DiscardResource

- Dispatch*

- OMSetRenderTargets

- ResolveQueryData

- ResolveSubresource(Region)

- SetProtectedResourceSession

The core runtime will remove the Command List if any of the above APIs
are called during Command List recording (the UMD can assume those DDIs
will never be called during a render pass).

---

### Resource Barriers within a Render Pass

As stated earlier, an application may not read from or consume writes
that occurred within the same render pass. This disallows certain
barriers, for example from `RENDER_TARGET` to `SHADER_RESOURCE` on the
currently-bound render target (and the debug layer will error to that
effect). But, that same barrier on a render target that was written
*outside* the current Render Pass is completely valid, as the writes
should have all completed ahead of the Render Pass even starting.

So as a (crucial) optimization, given a conformant workload, the UMD is
free to assume that the application is not depending on any writes
within a Render Pass, and thus it is free to automatically move any
barriers encountered in a Render Pass to the beginning of the Render
Pass, where they can be coalesced (and not interfere with any
tiling/binning operations). This should be valid, as all writes should
have been finished by the time the Render Pass starts.

To give a more complete example, if a rendering engine has a \~DX11
resource binding design, and does barriers 'on demand' based on how
resources are bound, when writing into a UAV near the end of the frame
(and will be consumed in the next frame), it may happen to leave the
resource in the `UNORDERED_ACCESS` state at the conclusion of the frame.

In the next frame, when the engine goes to bind the resource as an SRV,
it will then find that the resource is not in the correct state, and
issue a `UNORDERED_ACCESS` -> `PIXEL_SHADER_RESOURCE` barrier. If this
barrier occurs within the Render Pass, the UMD is free to assume all
writes occurred *outside* the Render Pass, and thus 'move' the barrier
up to the start of the Render Pass -- even if the UMD can't prove that
(given how UAV writes can't be tracked with the bindless design we
have).

Example non-conformant barriers:

- `RENDER_TARGET`/`DEPTH_WRITE` to *any read state* on currently-bound
    RTVs/DSVs

- Any aliasing barrier

- UAV barriers

Example conformant barriers:

- `UNORDERED_ACCESS` to `INDIRECT_ARGUMENT` (the UMD can assume the UAV
    writes occurred before the Render Pass)

- `COPY_DEST` to `PIXEL_SHADER_RESOURCE` (the UMD can assume that the
    copy occurred before the Render Pass started).

---

## Resource Access declaration

At BeginRenderPass time, the user must declare all Resources that are
serving as RTVs/DSVs within that Render Pass, and specify their
beginning/engine 'access' characteristics.

| | |
|-|-|
`D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_DISCARD`, | `D3D12_RENDER_PASS_ENDING_ACCESS_TYPE_DISCARD`,
`D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_PRESERVE`, |  `D3D12_RENDER_PASS_ENDING_ACCESS_TYPE_PRESERVE`,
`D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_CLEAR`, |`D3D12_RENDER_PASS_ENDING_ACCESS_TYPE_RESOLVE`,
`D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_NO_ACCESS`, |`D3D12_RENDER_PASS_ENDING_ACCESS_TYPE_NO_ACCESS`
`D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_PRESERVE_LOCAL_RENDER`, |  `D3D12_RENDER_PASS_ENDING_ACCESS_TYPE_PRESERVE_LOCAL_RENDER`,
`D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_PRESERVE_LOCAL_SRV`, |  `D3D12_RENDER_PASS_ENDING_ACCESS_TYPE_PRESERVE_LOCAL_SRV`,
`D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_PRESERVE_LOCAL_UAV`, |  `D3D12_RENDER_PASS_ENDING_ACCESS_TYPE_PRESERVE_LOCAL_UAV`,

The "`BEGINING`" and "`ENDING`" enums must both be provided for all
resources, and both are provided at BeginRenderPass time.

---

### D3D12_RENDER_PASS_BEGINNING_ACCESS_DISCARD

`BEGINNING_DISCARD` signifies that the application does not have any
dependency on the prior contents of the resource. A given implementation
may return the previously-written contents, or it may return
uninitialized data. However, reading from the resource must not produce
a GPU hang, the read may 'at worst' only return undefined data.

A read is defined as a traditional UAV/SRV/CBV/VBV/IBV/IndirectArg
binding/read, or as a blend/depth-testing-induced read.

BeginRenderPass with this state means the surface will be bound at the rasterizer/depth (whichever applies) for the pass. See [Surfaces that BeginRenderPass binds for raster](#surfaces-that-beginrenderpass-binds-for-raster).

---

### D3D12_RENDER_PASS_BEGINNING_ACCESS_PRESERVE

`BEGIN_PRESERVE` signifies the application has a dependency on the prior
contents of the resource, and the contents must be loaded from main
memory.

BeginRenderPass with this state means the surface will be bound at the rasterizer/depth (whichever applies) for the pass. See [Surfaces that BeginRenderPass binds for raster](#surfaces-that-beginrenderpass-binds-for-raster).

---

### D3D12_RENDER_PASS_BEGINNING_ACCESS_CLEAR

`BEGIN_CLEAR` signifies the application has a dependency on the resource
being cleared to a specific (app-provided) color. *This clear occurs
whether or not the resource is interacted with any further in the Render
Pass*.

The API allows the application to specify the clear values at
BeginRenderPass time, via a `D3D12_CLEAR_VALUE` struct.

BeginRenderPass with this state means the surface will be bound at the rasterizer/depth (whichever applies) for the pass. See [Surfaces that BeginRenderPass binds for raster](#surfaces-that-beginrenderpass-binds-for-raster).

---

### D3D12_RENDER_PASS_BEGINNING_ACCESS_NO_ACCESS

`NO_ACCESS` signifies the resource will not be read from or written to
during the Render Pass. It is most expected to be used to denote whether
the depth/stencil plane for a DSV is not accessed.

BeginRenderPass with this state means the surface will not be bound at the rasterizer/depth (whichever applies) for the pass. See [Surfaces that BeginRenderPass binds for raster](#surfaces-that-beginrenderpass-binds-for-raster).  Unless it is on only one of depth or stencil and the other has a state that is renderable, in which case the DSV is bound with only one part being accessible.

See [Surface Flow Between Passes](#surface-flow-between-passes) for a discussion on lining up states across passes, and [State At End Of Command List](#state-at-end-of-command-list) describing restrictions on ending a command list with a surface in `NO_ACCESS` state.

---

### D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_PRESERVE_LOCAL_RENDER

`PRESERVE_LOCAL_RENDER` signifies:

- The resource was read or written in the preceding pass, and data from that resource that may be in tile memory can stay there for the current pass.  
- The current pass will render to the resource in such a way that processing for a given 
pixel coordinate will access the same location in the resource that
the previous pass accessed.  

AdditionalWidth and AdditionalHeight parameters must be 0 since they don't make sense in the context of rendering.  

The end of the previous pass must specify `ENDING_ACCESS_TYPE_PRESERVE_LOCAL_RENDER` and the same AdditionalWidth/AdditionalHeight parameters.

See [Surface Flow Between Passes](#surface-flow-between-passes) for a discussion on lining up states across passes, and [State At End Of Command List](#state-at-end-of-command-list) describing that command lists can't finish with a surface in `PRESERVE_LOCAL_*` state.

BeginRenderPass with this state means the surface will be bound at the rasterizer/depth (whichever applies) for the pass. See [Surfaces that BeginRenderPass binds for raster](#surfaces-that-beginrenderpass-binds-for-raster).

---

### D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_PRESERVE_LOCAL_SRV

- The resource was read or written in the preceding pass, and data from that resource that may be in tile memory can stay there for the current pass.  
- The current pass will read from the resource via SRV binding(s) in the descriptor heap in such a way that processing for a given pixel coordinate will access the same location in the resource that the previous pass accessed.  

If AdditionalWidth/AdditionalHeight parameters for the pass are nonzero, they define a border of additional pixel locations around the current one that can also be read.  For instance AdditionalWidth of 1 and AdditionalHeight of 2 means a region 3 pixels wide and 5 pixels tall around the current pixel can be read by the current pixel.

The end of the previous pass must specify `ENDING_ACCESS_PRESERVE_LOCAL_SRV` and the same
AdditionalWidth/AdditionalHeight parameters.

The pass's surface definition is the same rendertarget or depthstencil descriptor used in neighboring passes (even though the application will actually accesses the surface via SRV in the descriptor heap).  This lets implementations match up neighboring passes.  If none of the passes are actually using a rendertarget/depth surface (e.g. UAV/SRV only rendering), the application still must create a dummy rendertarget or depthstencil descriptor to use in the pass description, for simplicity of the API.  The view used in the descriptor heap to actually access the surface can use compatible format casting, so the format doesn't have to exactly match the pass's descriptor as long as the memory identified is the same.

See [Surface Flow Between Passes](#surface-flow-between-passes) for a discussion on lining up states across passes, and [State At End Of Command List](#state-at-end-of-command-list) describing that command lists can't finish with a surface in `PRESERVE_LOCAL_*` state.

Compute shaders invoked in the pass follow the semantics of [Local compute access mode](#local-compute-access-mode).

BeginRenderPass with this state means the surface will not be bound at the rasterizer/depth (whichever applies) for the pass.  The exception is read only DSVs. See [Surfaces that BeginRenderPass binds for raster](#surfaces-that-beginrenderpass-binds-for-raster) and [Read only depth stencil](#read-only-depth-stencil).

---

### D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_PRESERVE_LOCAL_UAV

- The resource was read or written in the preceding pass, and data from that resource that may be in tile memory can stay there for the current pass.  
- The current pass will read/write the resource via UAV binding(s) in the descriptor heap in such a way that processing for a given pixel coordinate will access the same location in the resource that the previous pass accessed.  

If AdditionalWidth/AdditionalHeight parameters for the pass are nonzero, they define a border of additional pixel locations around the current one that can also be read/written.  For instance AdditionalWidth of 1 and AdditionalHeight of 2 means a region 3 pixels wide and 5 pixels tall around the current pixel can be read/written by the current pixel.

The end of the previous pass must specify `ENDING_ACCESS_PRESERVE_LOCAL_UAV` and the same
AdditionalWidth/AdditionalHeight parameters.

The pass's surface definition is the same rendertarget or depthstencil descriptor used in neighboring passes (even though the application will actually accesses the surface via UAV in the descriptor heap).  This lets implementations match up neighboring passes.  If none of the passes are actually using a rendertarget/depth surface (e.g. UAV/SRV only rendering), the application still must create a dummy rendertarget or depthstencil descriptor to use in the pass description, for simplicity of the API.  The view used in the descriptor heap to actually access the surface can use compatible format casting, so the format doesn't have to exactly match the pass's descriptor as long as the memory identified is the same.

See [Surface Flow Between Passes](#surface-flow-between-passes) for a discussion on lining up states across passes, and [State At End Of Command List](#state-at-end-of-command-list) describing that command lists can't finish with a surface in `PRESERVE_LOCAL_*` state.

Compute shaders invoked in the pass follow the semantics of [Local compute access mode](#local-compute-access-mode).

BeginRenderPass with this state means the surface will not be bound at the rasterizer/depth (whichever applies) for the pass.  See [Surfaces that BeginRenderPass binds for raster](#surfaces-that-beginrenderpass-binds-for-raster).

---

### D3D12_RENDER_PASS_ENDING_ACCESS_DISCARD

`ENDING_ACCESS_DISCARD` signifies the application will have no future
dependency on the data written to the resource during this Render Pass
(may be appropriate for a depth buffer where the depth buffer will never
be textured from prior to future writes).

See [Surface Flow Between Passes](#surface-flow-between-passes) for a discussion on lining up states across passes.

---

### D3D12_RENDER_PASS_ENDING_ACCESS_PRESERVE

`ENDING_ACCESS_PRESERVE` signifies the application will have a
dependency on the written contents of this resource in the future (and
they must be preserved).

See [Surface Flow Between Passes](#surface-flow-between-passes) for a discussion on lining up states across passes.

---

### D3D12_RENDER_PASS_ENDING_ACCESS_PRESERVE_LOCAL_RENDER

`ENDING_ACCESS_PRESERVE_LOCAL_RENDER` signifies surface contents must be preserved
for rendering with a local access pattern in the next pass.

The pass's surface definition is the same rendertarget or depthstencil descriptor used in neighboring passes (even though the application might actually accesses the surface some other way in the current pass).  This lets implementations match up neighboring passes.  If none of the passes are actually using a rendertarget/depth surface (e.g. UAV/SRV only rendering), the application still must create a dummy rendertarget or depthstencil descriptor to use in the pass description, for simplicity of the API.  The view used in the descriptor heap to actually access the surface can use compatible format casting, so the format doesn't have to exactly match the pass's descriptor as long as the memory identified is the same.

Compute shaders invoked in the current pass follow the semantics of [Local compute access mode](#local-compute-access-mode).  This doesn't apply if the surface is a rendertarget, since compute shaders can't access them, in which case the compute shader executes as normal (though its presence in the middle pass like this likely disrupts pass optimization ability for implementations).

See [Surface Flow Between Passes](#surface-flow-between-passes) for a discussion on lining up states across passes, and [State At End Of Command List](#state-at-end-of-command-list) describing that command lists can't finish with a surface in `PRESERVE_LOCAL_*` state.

---

### D3D12_RENDER_PASS_ENDING_ACCESS_PRESERVE_LOCAL_SRV

`ENDING_ACCESS_PRESERVE_LOCAL_SRV` signifies surface contents must be preserved
for use as an SRV with a local access pattern in the next pass.

The pass's surface definition is the same rendertarget or depthstencil descriptor used in neighboring passes (even though the application might actually accesses the surface some other way in the current pass).  This lets implementations match up neighboring passes.  If none of the passes are actually using a rendertarget/depth surface (e.g. UAV/SRV only rendering), the application still must create a dummy rendertarget or depthstencil descriptor to use in the pass description, for simplicity of the API.  The view used in the descriptor heap to actually access the surface can use compatible format casting, so the format doesn't have to exactly match the pass's descriptor as long as the memory identified is the same.

Compute shaders invoked in the current pass follow the semantics of [Local compute access mode](#local-compute-access-mode).  This doesn't apply if the surface is a rendertarget, since compute shaders can't access them, in which case the compute shader executes as normal (though its presence in the middle pass like this likely disrupts pass optimization ability for implementations).

See [Surface Flow Between Passes](#surface-flow-between-passes) for a discussion on lining up states across passes, and [State At End Of Command List](#state-at-end-of-command-list) describing that command lists can't finish with a surface in `PRESERVE_LOCAL_*` state.

---

### D3D12_RENDER_PASS_ENDING_ACCESS_PRESERVE_LOCAL_UAV

`ENDING_ACCESS_PRESERVE_LOCAL_SRV` signifies surface contents must be preserved
for use as a UAV with a local access pattern in the next pass.

The pass's surface definition is the same rendertarget or depthstencil descriptor used in neighboring passes (even though the application might actually accesses the surface some other way in the current pass).  This lets implementations match up neighboring passes.  If none of the passes are actually using a rendertarget/depth surface (e.g. UAV/SRV only rendering), the application still must create a dummy rendertarget or depthstencil descriptor to use in the pass description, for simplicity of the API.  The view used in the descriptor heap to actually access the surface can use compatible format casting, so the format doesn't have to exactly match the pass's descriptor as long as the memory identified is the same.

Compute shaders invoked in the current pass follow the semantics of [Local compute access mode](#local-compute-access-mode).  This doesn't apply if the surface is a rendertarget, since compute shaders can't access them, in which case the compute shader executes as normal (though its presence in the middle pass like this likely disrupts pass optimization ability for implementations).

See [Surface Flow Between Passes](#surface-flow-between-passes) for a discussion on lining up states across passes, and [State At End Of Command List](#state-at-end-of-command-list) describing that command lists can't finish with a surface in `PRESERVE_LOCAL_*` state.

---

### D3D12_RENDER_PASS_ENDING_ACCESS_RESOLVE

`ENDING_ACCESS_RESOLVE` allows the application to directly resolve a
MSAA surface to a separate resource at the conclusion of the Render Pass
(ideally while the MSAA contents are currently in the tile cache, for
TBDRs).

The resolve dest is expected to be in the `RESOLVE_DEST` resource state
at the time the Render Pass ends.

The resolve source will be left in its initial resource state at the time the Render Pass
ends. Resolve operations sumbmitted by a render pass will not implicitly change the state of any resources.

See [Surface Flow Between Passes](#surface-flow-between-passes) for a discussion on lining up states across passes.

---

### D3D12_RENDER_PASS_ENDING_ACCESS_NO_ACCESS

`ENDING_ACCESS_NO_ACCESS` signifies the resource will not be read from
or written to during the Render Pass. It is most expected to used to
denote whether the depth/stencil plane for a DSV is not accessed.

See [Surface Flow Between Passes](#surface-flow-between-passes) for a discussion on lining up states across passes, and [State At End Of Command List](#state-at-end-of-command-list) describing that command lists can't finish with a surface in `NO_ACCESS` state.

---

## Render Pass Flags

```C++
typedef enum D3D12_RENDER_PASS_FLAGS
{
    D3D12_RENDER_PASS_FLAG_NONE = 0,
    D3D12_RENDER_PASS_FLAG_ALLOW_UAV_WRITES = 0x1,
    D3D12_RENDER_PASS_FLAG_SUSPENDING_PASS = 0x2,
    D3D12_RENDER_PASS_FLAG_RESUMING_PASS = 0x4,
    D3D12_RENDER_PASS_FLAG_BIND_READ_ONLY_DEPTH = 0x8,
    D3D12_RENDER_PASS_FLAG_BIND_READ_ONLY_STENCIL = 0x10,
} D3D12_RENDER_PASS_FLAGS;
```

---

### UAV writes within a Render Pass

UAV writes are permitted within a Render Pass, but the user must
specifically indicate that they will be issuing UAV writes within the
Render Pass with the `ALLOW_UAV_WRITES` flag, to let UMDs opt out of
tiling if necessary.

UAV accesses must follow the earlier "writes are not valid to read until
the end of the Render Pass". Relatedly, UAV barriers are not permitted
within a Render Pass.

UAV bindings (via root tables or root descriptors) **are** inherited
into Render Passes, and are propagated out of Render Passes.

This flag is not necessary/ignored for passes with `BEGINNING_ACCESS_TYPE`/`ENDING_ACCESS_TYPE` `_PRESERVE_LOCAL_*` flags.  In these passes, if the application wants to do UAV accesses it must ensure that the memory access pattern is such that if an implementation breaks up passes into tiles, the UAV accesses will behave identically as if the implementation didn't do so and executed each GPU command fully before moving to the next. `ALLOW_UAV_WRITES` refers to UAVs other than the pass surface, so is independent of the `_PRESERVE_LOCAL_UAV` flag, which is specifically calling out the pass surface for UAV access with a local access pattern.

---

### Suspend and Resume

Applications can suspend/resume a sequence of render passes.  This means suspending at the end of
the last render pass in one command list and resuming with the first render pass in another command list.

These command lists can be recorded in parallel or any order, but when executed, they have to be placed in 
the intended order in an execute command lists call.

A render pass can be both resuming and suspending if it is the only thing in a command list, connecting a prior command list that suspends 
and a subsequent command list that resumes.

The way the ending state of a suspending pass lines up with the beginning state of a resuming pass 
that will execute after it follows the same rules/restrictions as in between any two passes
within a command list.  These rules are described in [Surface flow between passes](#surface-flow-between-passes).
All that suspend/resume is doing is calling out that a logical flow of passes is straddling command list boundaries.

Thre cannot be intervening GPU ops (draws,
dispatches, discards, clears, copies, updatetilemappings,
writebufferimmediates, queries, query resolves, ..) between the
suspending/resuming render passes.

It is recommended to only use suspend/resume when there actually is a connection between surfaces acrosss the suspending and resuming passes (e.g. surfaces in common across the passes), 
as opposed to blindly doing suspend/resume across command lists.  Unneeded suspend/resume will not cause any rendering issues, but might incur extra overhead during execution as the driver
tries to stich together the passes.

---

### Read Only Depth Stencil

If an application wishes to bind a DSV where one or both of depth/stencil is read only to the rasterizer for a given pass, it can provide the appropriate read-only DSV descriptor to the pass.  It is fine for neighboring passes to use the same surface in read/write mode via read-write DSV descriptor.  This is the one case with render passes where it is valid for adjacent passes to refer to the same surface via different cpu descriptors.

When a read only DSV is specified, the application must include one or both of `D3D12_RENDER_PASS_FLAG_BIND_READ_ONLY_DEPTH_AT_RASTERIZER` and `D3D12_RENDER_PASS_FLAG_BIND_READ_ONLY_STENCIL_AT_RASTERIZER` (whichever apply) in render pass flags.  They indicate to the system to bind the read only DSV at the rasterizer.

These flags can only be specified when the depth/stencil surfaces that have been initialized before the current pass (by a previous pass or some other way).  

Here is a table of behaviors when combining `D3D12_RENDER_PASS_FLAG_BIND_READ_ONLY_DEPTH/STENCIL_AT_RASTERIZER` flags with various `D3D12_RENDER_PASS_BEGINNING_ACCESS_*` options for the depth and/or stencil surface:

|`D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_*` |Behavior with `D3D12_RENDER_PASS_FLAG_BIND_READ_ONLY_DEPTH/STENCIL_AT_RASTERIZER`|
|--------------------------------------|---------------------------------------------------------------------------------|
|`PRESERVE`|The surface will be bound at the rasterizer for read only access.  The application can still bind an SRV for this surface, and is not promising any pixel local access, which is the `PRESERVE_LOCAL_SRV` option below.|
|`PRESERVE_LOCAL_SRV`|The surface will be bound at the rasterizer for read only access while shaders can also access it via SRV in a local fashion.|
|`PRESERVE_LOCAL_RENDER`|The surface will be bound at the rasterizer for read only access with no access from shaders. This can be done for read/write DSVs as well (no `D3D12_RENDER_PASS_FLAG_BIND_READ_ONLY_DEPTH/STENCIL_AT_RASTERIZER` flags in that case).|

If an application wants to do pixel local access to a depth buffer via SRV while no depth buffer is bound at the rasterizer, it must specify a normal DSV cpu descriptor (not a read only one) in BeginPass, and use `BEGINNING_ACCESS_TYPE_PRESERVE_LOCAL_SRV`. In this case the `D3D12_RENDER_PASS_FLAG_BIND_READ_ONLY_DEPTH/STENCIL_AT_RASTERIZER` are not specified, and the DSV will not be bound at the rasterizer.

If an application wants to do random access to a depth buffer via SRV that is different from the depth buffer bound at the rasterizer (if any), the pass description doesn't need to mention anything about the surface accessed via SRV binding.  This is just like any other non-pass surface.   It could have been a depth buffer rendered in a previous pass (for example a shadow map) in which that pass ended with `ENDING_ACCESS_TYPE_PRESERVE`.

---

## Surfaces That BeginRenderPass Binds For Raster

This is a description of which surfaces specified in BeginRenderPass get bound for rasterization/depth/stencil and how they match up with surfaces listed in PSO definitions used in the pass.

Surfaces listed in BeginPass in the following access modes will be bound for raster/depth/stencil, as if OMSetRenderTargets() was called at BeginRenderPass():

|`D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_*`|`R` == bound for raster,<br>`NR` == not bound for raster|
|-----------|-----------------------------------------------------|
|`DISCARD`|`R`|
|`PRESERVE`|`R`|
|`CLEAR`|`R`|
|`PRESERVE_LOCAL_RENDER`|`R`|
|`PRESERVE_LOCAL_SRV` with `D3D12_RENDER_PASS_FLAG_BIND_READ_ONLY_DEPTH/STENCIL_AT_RASTERIZER`<br> flag(s) and matching read-only DSV cpuDescriptor. See [Read Only Depth Stencil](#read-only-depth-stencil).|`R`|
|`PRESERVE_LOCAL_SRV` in all other cases|`NR`|
|`PRESERVE_LOCAL_UAV`|`NR`|
|`NO_ACCESS`|`NR`|

Indeed for drivers that don't support render passes, the runtime uses these rules to convert BeginRenderPass() into the equivalent OMSetRenderTargets() call.

Suppose a given BeginRenderPass() call lists a set of RTVs (and DSV) with the following distribution of `R` (bound for raster) and `NR` (not bound for raster) surfaces based on the above:

RTV list:

`[0] PRESERVE_LOCAL_SRV (NR)`<br>
`[1] NO_ACCESS (NR)`<br>
`[2] PRESERVE_LOCAL_RENDER (R)`<br>
`[3] PRESERVE_LOCAL_UAV (NR)`<br>
`[4] PRESERVE (R)`

DSV: `CLEAR (R)`

In this case, the pass binds 2 RTVs (`[2]` and `[4]` in the array) to raster, plus the DSV - all the `R` surfaces..  As if OMSetRenderTargets() is called with these 2 RTVs and DSV.

Therefore, any PSOs used in the pass must specify descriptions of at least 2 RTV formats and a DSV format.  If Blend desc is applicable, there would be at least 2 entries in the PSO desc there as well.  Any additional RTVs specified beyond 2 in the PSO get unused.  As might be expected, in a PSO definition's list of RTVs, entries `[0]` and `[1]` map to BeginPass surfaces `[2]` and `[4]` respectively - the order the raster bound surfaces appear in the render pass RTV list without any gaps. 

---

## Surface Flow Between Passes

For a given surface specified in BeginRenderPass, regardless of what beginning access (`D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_*`) it uses all ending access (`D3D12_RENDER_PASS_ENDING_ACCESS_TYPE_*`) options are valid.

Conversely, when a pass ends with a surface in a given ending access type, here is a summary of options for the next pass beginning access type:

|Previous pass `D3D12_RENDER_PASS_ENDING_ACCESS_TYPE_*`|Next pass `D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_*` options|
|-|-|
|`DISCARD`/`PRESERVE`/`RESOLVE`/`NO_ACCESS` or no previous reference to surface|Any of `DISCARD`/`PRESERVE`/`CLEAR`/`NO_ACCESS` for the next pass that references the surface.  It is also fine for new passes to not use the surface again or until a later pass.  The begin state can differ from the previous end state to allow for non-pass operations on the surface between the passes, such as copying or running a compute shader. |
|`PRESERVE_LOCAL_RENDER`|`PRESERVE_LOCAL_RENDER`. Between the passes, the only valid operations are setting up rendering state for the next pass.  This includes necessary resource transitions.  Also valid are binding shaders/root parameters, though these can be done within the pass as well.
|`PRESERVE_LOCAL_SRV`|`PRESERVE_LOCAL_SRV`. Between the passes, the only valid operations are setting up rendering state for the next pass.  This includes necessary resource transitions.  Also valid are binding shaders/root parameters, though these can be done within the pass as well.|
|`PRESERVE_LOCAL_UAV`|`PRESERVE_LOCAL_UAV`. Between the passes, the only valid operations are setting up rendering state for the next pass.  This includes necessary resource transitions.  Also valid are binding shaders/root parameters, though these can be done within the pass as well.|

The order that RTV descriptors appear in the list in BeginRenderPass does not have to match the order they are listed in neighboring passes.

These rules also apply across passes that [suspend/resume](#suspend-and-resume) across command lists.

---

### State At End Of Command List

A command list cannot end with any surface in `PRESERVE_LOCAL_RENDER / PRESERVE_LOCAL_SRV / PRESERVE_LOCAL_UAV` states.  It is also invalid to end a command list with a surface in `NO_ACCESS` if it was in any other state earlier in the sequence of passes.

The exception is if the last pass in a command list uses flag `D3D12_RENDER_PASS_FLAG_SUSPENDING_PASS`, indicating a subsequent command list in the same ExecuteCommandLists call will have a pass starting with `D3D12_RENDER_PASS_FLAG_RESUMING_PASS`. See [Suspend/Resume](#suspend-and-resume)

---

## Local Compute Access Mode

> This is an initial proposal and likely needs refinement.

This section defines local compute (shader) access in the context of render passes.

This pplies to passes that specify either `BEGINNING_ACCESS_PRESERVE_LOCAL_SRV/UAV` or `ENDING_ACCESS_PRESERVE_LOCAL_RENDER/SRV/UAV` (e.g. next pass is using preserve local semantics).  This does not apply to passes that specify `BEGINNING_ACCESS_PRESERVE_LOCAL_RENDER`, since compute shaders do not have access to surfaces in render target state.

In these passes, if a compute shader is invoked via `Dispatch()` or the equivalent in `ExecuteIndirect()` the system assumes local compute access, which means the following:

Suppose the current viewport and scissor (slot `[0]`) define a rectangle of pixels whose top left coordinate is `(xTopLeft,yTopLeft)`, `w` pixels wide and `h` pixels high.

For each thread invoked by compute shader, it's pixel location in any surfaces with `*PRESERVE_LOCAL*` flags are as follows.  The thread's `SV_DispatchThreadID` `(x,y)` components (regardless of `z` value) correspond to pixel `(xTopLeft+x,yTopLeft+y)`.  Any thread whose `SV_DispatchThreadcID` `x < w` or `y < h` can only access it's local location - `(xTopLeft+x,yTopLeft+y)` in the surface, plus any `AdditionalWidth/Height` pixel border specified, clamped to the extents `w` and `h`.  If a thread accesses anything outside its local location, behavior is undefined.  This also applies to threads whose `x >= w` or `y >= h`, which must not access the surface or else behavior is undefined.

The threads cannot use thread group shared memory or do any cross thread communication or request thread group execution sync, otherwise behavior is undefined.  In other words, the shader author must treat of the threads as if they operate on their own and not depend on any particular neighboring threads to be running with them.

> This convention allows implementations to break up the compute shader thread grid into the same tile boundaries that can be shared with other passes that may be doing other compute or rendering work on the same data in a local access fashion.  Different implementations may have different size tiles, hence the requirement that threads don't depend on neighboring threads.

---

## Checking for Support

This feature originally shipped in an incomplete form that drivers 
could not take advantage of.  The feature has been repaired now, and
so to use RenderPasses, applications must first confirm `CheckFeatureSupport` 
reports `RenderPassesValid` (in `D3D12_OPTIONS_18`).
  
On older D3D12 runtimes with the non-functioning RenderPass support, 
the `RenderPassesValid` query isn't recognized so the query will fail. 
That is an indication that use of RenderPasses at all is invalid, and can
result in undefined behavior. On newer runtimes (which applications can 
guaranteed by using the AgilitysSDK), `RenderPassesValid` will be `TRUE`, 
in which case the APIs in this spec can all be used.

Separately, applications can check the Tier of support described next to 
understand how much the driver/harddware takes advantage of the feature
versus runtime emulation.

There are three tiers of support:

- `D3D12_RENDER_PASS_TIER_0` -- Driver has not implemented DDI
    Table, supported via SW emulation

- `D3D12_RENDER_PASS_TIER_1` -- Render Passes implemented by
    UMD, RT/DB writes may be accelerated. UAV writes *not* efficiently
    supported within the Render Pass.

- `D3D12_RENDER_PASS_TIER_2` -- Tier 1, plus that UAV writes
    (pursuant to the read-after-write prohibition) are likely to be
    efficiently supported (more efficient than issuing the same work
    without a Render Pass).

The driver will report back these tiers to the runtime. The runtime will
validate that drivers which fill out the DDI table at least report back
TIER_1, and at the same time will validate that drivers which do not fill
out the DDI table do not claim anything other than TIER_0 support (the
runtime will fail device creation in this case).

This requirement will only be present for drivers supporting the minimum
DDI version described in [Minimum Driver DDI version](#minimum-driver-ddi-version).

---

### Minimum Driver DDI version

Even if drivers report support for `TIER_1+`, if the device doesn't support DDI revision `D3D12DDI_SUPPORTED_0101` or greater, the runtime maps all uses of RenderPasses to non-renderpass DDIs (and report `TIER_0` at the API).  This is the DDI revision where the `*PRESERVE_LOCAL*` flags were introduced, and it is deemed simpler to only support these features going forward, all or none.

---

# API Headers

```C++
// Beginning Access
typedef enum D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE
{
    D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_DISCARD,
    D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_PRESERVE,
    D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_CLEAR,
    D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_NO_ACCESS,
    D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_PRESERVE_LOCAL_RENDER,
    D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_PRESERVE_LOCAL_SRV,
    D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_PRESERVE_LOCAL_UAV
} D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE;

typedef struct D3D12_RENDER_PASS_BEGINNING_ACCESS_CLEAR_PARAMETERS
{
    D3D12_CLEAR_VALUE ClearValue;
} D3D12_RENDER_PASS_BEGINNING_ACCESS_CLEAR_PARAMETERS;

typedef struct D3D12_RENDER_PASS_BEGINNING_ACCESS_PRESERVE_LOCAL_PARAMETERS
{
    UINT16 AdditionalWidth;
    UINT16 AdditionalHeight;
} D3D12_RENDER_PASS_BEGINNING_ACCESS_PRESERVE_LOCAL_PARAMETERS;

typedef struct D3D12_RENDER_PASS_BEGINNING_ACCESS
{
    D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE Type;
    union
    {
    D3D12_RENDER_PASS_BEGINNING_ACCESS_CLEAR_PARAMETERS Clear;
        D3D12_RENDER_PASS_BEGINNING_ACCESS_PRESERVE_LOCAL_PARAMETERS PreserveLocal;
    };
} D3D12_RENDER_PASS_BEGINNING_ACCESS;

// Ending Access
typedef enum D3D12_RENDER_PASS_ENDING_ACCESS_TYPE
{
    D3D12_RENDER_PASS_ENDING_ACCESS_TYPE_DISCARD,
    D3D12_RENDER_PASS_ENDING_ACCESS_TYPE_PRESERVE,
    D3D12_RENDER_PASS_ENDING_ACCESS_TYPE_RESOLVE,
    D3D12_RENDER_PASS_ENDING_ACCESS_TYPE_NO_ACCESS,
    D3D12_RENDER_PASS_ENDING_ACCESS_TYPE_PRESERVE_LOCAL_RENDER,
    D3D12_RENDER_PASS_ENDING_ACCESS_TYPE_PRESERVE_LOCAL_SRV,
    D3D12_RENDER_PASS_ENDING_ACCESS_TYPE_PRESERVE_LOCAL_UAV,
} D3D12_RENDER_PASS_ENDING_ACCESS_TYPE;

typedef struct D3D12_RENDER_PASS_ENDING_ACCESS_RESOLVE_SUBRESOURCE_PARAMETERS
{
  UINT SrcSubresource;
  UINT DstSubresource;
  UINT DstX;
  UINT DstY;
  D3D12_RECT* pSrcRect;
} D3D12_RENDER_PASS_ENDING_ACCESS_RESOLVE_SUBRESOURCE_PARAMETERS;

typedef struct D3D12_RENDER_PASS_ENDING_ACCESS_RESOLVE_PARAMETERS
{
    ID3D12Resource* pSrcResource;
    ID3D12Resource* pDstResource;

    // Can be a subset of RT's array slices, but can't target
    // subresources that weren't part of RTV/DSV.
    UINT SubresourceCount;

    const D3D12_RENDER_PASS_ENDING_ACCESS_RESOLVE_SUBRESOURCE_PARAMETERS* pSubresourceParameters;

    DXGI_FORMAT Format;
    D3D12_RESOLVE_MODE ResolveMode;
    BOOL PreserveResolveSource; // New to v0.08
} D3D12_RENDER_PASS_ENDING_ACCESS_RESOLVE_PARAMETERS;

typedef struct D3D12_RENDER_PASS_ENDING_ACCESS_PRESERVE_LOCAL_PARAMETERS
{
    UINT16 AdditionalWidth;
    UINT16 AdditionalHeight;
} D3D12_RENDER_PASS_ENDING_ACCESS_PRESERVE_LOCAL_PARAMETERS;

typedef struct D3D12_RENDER_PASS_ENDING_ACCESS
{
    D3D12_RENDER_PASS_ENDING_ACCESS_TYPE Type;
    union
    {
        D3D12_RENDER_PASS_ENDING_ACCESS_RESOLVE_PARAMETERS Resolve;
        D3D12_RENDER_PASS_ENDING_ACCESS_PRESERVE_LOCAL_PARAMETERS PreserveLocal;
    };
} D3D12_RENDER_PASS_ENDING_ACCESS;

// Render Target Desc
typedef struct D3D12_RENDER_PASS_RENDER_TARGET_DESC
{
    D3D12_CPU_DESCRIPTOR_HANDLE cpuDescriptor;
    D3D12_RENDER_PASS_BEGINNING_ACCESS BeginningAccess;
    D3D12_RENDER_PASS_ENDING_ACCESS EndingAccess;
} D3D12_RENDER_PASS_RENDER_TARGET_DESC;

// Depth-Stencil Desc
typedef struct D3D12_RENDER_PASS_DEPTH_STENCIL_DESC
{
    D3D12_CPU_DESCRIPTOR_HANDLE cpuDescriptor;
    D3D12_RENDER_PASS_BEGINNING_ACCESS DepthBeginningAccess;
    D3D12_RENDER_PASS_BEGINNING_ACCESS StencilBeginningAccess;
    D3D12_RENDER_PASS_ENDING_ACCESS DepthEndingAccess;
    D3D12_RENDER_PASS_ENDING_ACCESS StencilEndingAccess;
} D3D12_RENDER_PASS_DEPTH_STENCIL_DESC;

// UAV Access Mode
typedef enum D3D12_RENDER_PASS_FLAGS
{
    D3D12_RENDER_PASS_FLAG_NONE = 0x0,
    D3D12_RENDER_PASS_FLAG_ALLOW_UAV_WRITES = 0x1,
    D3D12_RENDER_PASS_FLAG_SUSPENDING_PASS = 0x2,
    D3D12_RENDER_PASS_FLAG_RESUMING_PASS = 0x4
} D3D12_RENDER_PASS_UAV_ACCESS_FLAGS;

DEFINE_ENUM_FLAG_OPERATORS( D3D12_RENDER_PASS_FLAGS );

[uuid(9742FB99-3D7D-4572-977C-CED7D15EB709), object, local, pointer_default(unique)]
interface ID3D12GraphicsCommandList4 : ID3D12GraphicsCommandList3
{
    void BeginRenderPass(
        [annotation("_In_")]  UINT NumRenderTargets,
        [annotation("_In_reads_opt_(NumRenderTargets)")] const D3D12_RENDER_PASS_RENDER_TARGET_DESC* pRenderTargets,
        [annotation("_In_opt_")] const D3D12_RENDER_PASS_DEPTH_STENCIL_DESC* pDepthStencil,
        D3D12_RENDER_PASS_FLAGS  Flags
        );

    void EndRenderPass();
}
```

---

# Runtime validation

The runtime does the following validation:

- *Render Passes may not be started within
    non-DIRECT command lists*

- *Render Passes must be ended before calling
    ID3D12CommandList::Close*

- *Render Passes may not be nested (two begins
    in a row)*

- *A Render Pass may not be ended twice in a
    row*

- *Disallowed APIs may not be called during a
    Render Pass (command list will be removed)

The debug layer does the following validation:

- Translate `DISCARD` (`BEGINNING_ACCCESS` or
    `ENDING_ACCESS`) to "clear-to-a-random-value", since that shouldn't
    impact app at all.*

The following potential debug layer validation haven't been implemented:

- No GPU work occurs within a command list between a `ENDING_SUSPEND`
    and `BEGINNING_RESUME`.

- If a Command List ends with a `ENDING_SUSPEND`, the next command list
    within that ExecuteCommandLists group must exist, and must begin
    with a `BEGINNING_RESUME` (with matching RT/DBs).

- A ResourceBarrier is not issued on a resource that was actually
    written within the current Render Pass (e.g. a bound UAV, or
    currently-bound RTs/DBs).

---

# HLK Testing

11on12 replaces OMSetRenderTargets calls with
BeginRenderPass/EndRenderPass as appropriate to test general rendering
functionality with Render Passes.

For testing more specific functionality, the following will be exercised
via the HLK:

- A BEGINNING **clear**, with no rendering in Render Pass, and an
    ending PRESERVE results in a clear, for various resource formats and
    types (and RT counts).

- A BEGINNING **clear**, *with* rendering in the Render Pass, and an
    ending PRESERVE results in a clear (with drawing properly ordered
    after the clear), for various resource formats and types (and RT
    counts).

- A BEGINNING **discard**, that uses a blending or depth operations
    that have dependencies on existing contents does *not* result in a
    GPU hang (undefined rendering values is fine).

- A ENDING **resolve** correctly resolves resources in a variety of
    configurations (including using the new MIN/MAX capabilities for
    depth/stencil that were added in ResolveSubresourceRegion).

- Utilizing **SUSPEND/RESUME** results in no rendering difference
    (versus `ENDING_PRESERVE`/`BEGINNING_PRESERVE`), for various resource
    formats and types.

- For a BEGINNING/ENDING **preserve**/**preserve_local**, when no work occurs in the
    Render Pass, the values are still present in the Render Target
    outside of the Render Pass

---

# History of changes

Date | Version | Description
-|-|-
2/20/2023 | 1.14 | <li>In [Surface flow between passes](#surface-flow-between-passes), relaxed rules for surfaces ending a pass in `DISCARD`/`PRESERVE`/`RESOLVE`/`NO_ACCESS` such that the next pass that references these can begin with any of `DISCARD`/`PRESERVE`/`CLEAR`/`NO_ACCESS` state.  It used to be required that ending with `DISCARD` must be paired with the next pass starting with `DISCARD`.  Relaxing this rule allows for operations like copying or compute shaders using a surface between render passes.</li><li>Also in [Surface flow between passes](#surface-flow-between-passes), for `PRESERVE_LOCAL_*` states, clarified what operations are allowed between passes.</li>
1/4/2023 | 1.13 | <li>In [Minimum Driver DDI Version](#minimum-driver-ddi-version) updated the minimum version to `D3D12DDI_SUPPORTED_0101` now that this has been implemented in the runtime.</li><li>Fleshed out `NO_ACCESS` behavior.</li>
12/15/2022 | 1.12 | <li>Fleshed out behavior of the `NO_ACCESS` state.  See [Surface flow between passes](#surface-flow-between-passes) and [State At End Of Command List](#state-at-end-of-command-list)</li>
11/18/2022 | 1.11 | <li>Defined how to support read only depth/stencil with render passes.  Added new [Render pass flags](#render-pass-flags), `_BIND_READ_ONLY_DEPTH` and `_STENCIL`.  And added [Read only depth stencil](#read-only-depth-stencil) section describing supported scenarios and how they work.</li><li>Added [Surfaces that BeginRenderPass binds for raster](#surfaces-that-beginrenderpass-binds-for-raster) section to make clear exactly which surfaces get bound, the equivalent of being passed into OMSetRenderTargets() at BeginRenderPass.  This also clarifies the mapping from surfaces listed in BeginRenderPass to surfaces listed in PSO definitions for PSOs used within a pass.  Also, the rules here for what counts as raster binding are used by the runtime on drivers that don't support render passes to convert BeginRenderPass() calls to the equivalent OMSetRenderTargets().</li><li>Added [Surface Flow Between Passes](#surface-flow-between-passes) for a discussion on lining up states across passes.</li><li>Added [State At End Of Command List](#state-at-end-of-command-list) describing that command lists can't finish with a surface in `PRESERVE_LOCAL_*` state.</li><li>Removed `D3D12_RENDER_PASS_TIER_3`, and added [Minimum Driver DDI Version](#minimum-driver-ddi-version) section.  Drivers that don't support the latest DDIs where `_PRESERVE_LOCAL_*` are exposed are demoted to `TIER_0` and the runtime converts RenderPass use to non-RenderPass.  It is deemed to be only worth supporting the latest feature set, all/none.</li><li>Added `RenderPassesValid` cap that will be `TRUE` on new runtimes and the cap is unrecognized on old runtimes.  When the cap is not recognized, using the RenderPass APIs is invalid an produces undefined behavior.  When the cap is `TRUE`, the APIs can be used, and then the `TIER_*` levels indicate how much the driver takes advantage of the APIs vs runtime emulation.</li>
9/21/2022 | 1.1 | <li>Added support for apps promising they are doing "local" access to surfaces, meaning during rendering pixel (x,y) only accesses the corresponding location in surfaces.  This is accomplished by new pass beggining access types: `D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_PRESERVE_LOCAL_RENDER`, `_PRESERVE_LOCAL_SRV` and `_PRESERVE_LOCAL_UAV`, and similar ending access types.</li><li>Added proposed [Local compute access mode](#local-compute-access-mode) that is assumed for compute shaders when the `PRESERVE_LOCAL` flags are used, so they can participate in the same tiling as rendering.</li><li>Added `D3D12_RENDER_PASS_TIER_3` indicating that in addition to caring about previous tiers, the implementation makes uses of the `_PRESERVE_LOCAL_` flags to make optimizations (doesn't just ignore them).</li>
8/7/2019 | 1.0 | Updated public spec to match implementation regarding SetDescriptorHeaps 
10/30/2018 | 0.09 | Clarified inconsistency about what resource state render targets and depth buffers are left in after a render pass that ends with a resolve
5/15/2018 | 0.08 | General API/DDI refactoring – runtime support for previous DDI version remains, but will be removed prior to feature complete. Suspend/Resume has been refactored to be at the pass level, rather than per-view. Suspend/Resume_LOCAL has been removed from the API/DDI, will be re-added if more ISV scenarios are identified in a future release. SetDescriptorHeaps no longer allowed during a render pass. Applications can now explicitly specify whether during a resolve the resolve source (e.g. the bound RT/DB) should be preserved or not. Minor API/DDI enum renaming to better follow D3D12 conventions
4/10/2018|0.07| Allow Resource Barriers that obey the “no read dependencies may be taken on a write that occurred during the Render Pass” rule. Add new API/DDI CAP for applications to know whether Render Passes are potentially more optimal on the hardware (e.g. whether the DDI table is even implemented), and for the driver to reflect whether UAV writes within the Render Pass can be implemented efficiently. Remove SOSetTargets from the list of disallowed APIs within a Render Pass, fill in some APIs that were missing from the list (notably copies). One new HLK test case
3/7/2018|0.06|Allow the Resolve-at-EndRenderPass operation to (optionally) target multiple subresources, earlier design assumed just a single subresource per RTV. Changes to `D3D12_RENDER_PASS_ENDING_ACCESS_RESOLVE_SUBRESOURCE_PARAMETERS` and `D3D12_RENDER_PASS_ENDING_ACCESS_RESOLVE_PARAMETERS`
2/16/2018|0.05|Address feedback: Remove Resource Barrier integration from BeginRenderPass, feedback is that it is likely not a significant win, and this simplifies the design. Can add back in if potential wins identified once up and running. Change `ONE_TO_ONE_READ` to `LOCAL_READ`, where user specifies kernel size for reads.
2/14/2018|0.04|Address feedback: Clear\*View APIs are not allowed within a Render Pass. Clarified that Render Targets/Depth Buffer are in an undefined state following a Render Pass, don’t necessarily need to be cleanly unbound by UMD. Open issue if runtime enforces this, similar to how it unbinds RTs at start of Command List. Added following to list of open issues: Should SO be allowed within a Render Pass?
2/13/2018|0.03|Add API headers. Move access specification to sub-resource granularity.Reduce verbosity of UAV bindings.Add “ISV can validate proper usage of feature even if UMD does not support feature” design goal.
01/23/2018|0.02|Design simplification to only allow a single set of writable surfaces per Render Pass.
01/09/2018|0.01|Initial version
