<h1>D3D12 RS5 Render Passes -- Unified Spec</h1>

Version 1.0

---

<h1>Contents</h1>

- [Background](#background)
- [Optimization Goals](#optimization-goals)
  - [Goals](#goals)
    - [Allow applications to avoid unnecessary loads/stores of resources from/to main memory on TBDR architectures](#allow-applications-to-avoid-unnecessary-loadsstores-of-resources-fromto-main-memory-on-tbdr-architectures)
    - [Allow TBDR architectures to opportunistically persistent resources in on-chip cache across Render Passes (even in separate Command Lists)](#allow-tbdr-architectures-to-opportunistically-persistent-resources-in-on-chip-cache-across-render-passes-even-in-separate-command-lists)
      - [Case A: Reading/Writing One-to-One](#case-a-readingwriting-one-to-one)
      - [Case B: Writes to the same Render Targets across multiple Command Lists](#case-b-writes-to-the-same-render-targets-across-multiple-command-lists)
    - [Allow the new APIs to be used with existing drivers](#allow-the-new-apis-to-be-used-with-existing-drivers)
    - [Design allows UMD to choose optimal rendering path without heavy CPU penalty](#design-allows-umd-to-choose-optimal-rendering-path-without-heavy-cpu-penalty)
    - [Allow ISVs to verify proper use of the feature even on drivers that aren't necessarily making behavior changes based on feature use](#allow-isvs-to-verify-proper-use-of-the-feature-even-on-drivers-that-arent-necessarily-making-behavior-changes-based-on-feature-use)
  - [Non-goals](#non-goals)
- [Summary of API changes](#summary-of-api-changes)
  - [Render Pass output bindings](#render-pass-output-bindings)
  - [Render Pass workloads](#render-pass-workloads)
    - [Resource Barriers within a Render Pass](#resource-barriers-within-a-render-pass)
  - [Resource Access declaration](#resource-access-declaration)
    - [D3D12_RENDER_PASS_BEGINNING_ACCESS_DISCARD](#d3d12_render_pass_beginning_access_discard)
    - [D3D12_RENDER_PASS_BEGINNING_ACCESS_PRESERVE](#d3d12_render_pass_beginning_access_preserve)
    - [D3D12_RENDER_PASS_BEGINNING_ACCESS_CLEAR](#d3d12_render_pass_beginning_access_clear)
    - [D3D12_RENDER_PASS_BEGINNING_ACCESS_NO_ACCESS](#d3d12_render_pass_beginning_access_no_access)
    - [~~D3D12_RENDER_PASS_BEGINNING_ACCESS_RESUME_WRITING~~](#d3d12_render_pass_beginning_access_resume_writing)
    - [~~D3D12_RENDER_PASS_BEGINNING_ACCESS_RESUME_LOCAL_READ~~](#d3d12_render_pass_beginning_access_resume_local_read)
    - [D3D12_RENDER_PASS_ENDING_ACCESS_DISCARD](#d3d12_render_pass_ending_access_discard)
    - [D3D12_RENDER_PASS_ENDING_ACCESS_PRESERVE](#d3d12_render_pass_ending_access_preserve)
    - [D3D12_RENDER_PASS_ENDING_ACCESS_RESOLVE](#d3d12_render_pass_ending_access_resolve)
    - [D3D12_RENDER_PASS_ENDING_ACCESS_NO_ACCESS](#d3d12_render_pass_ending_access_no_access)
    - [~~D3D12_RENDER_PASS_ENDING_ACCESS_SUSPEND_WRITING~~](#d3d12_render_pass_ending_access_suspend_writing)
    - [~~D3D12_RENDER_PASS_ENDING_ACCESS_SUSPEND_LOCAL_READ~~](#d3d12_render_pass_ending_access_suspend_local_read)
  - [Render Pass Flags](#render-pass-flags)
    - [UAV writes within a Render Pass](#uav-writes-within-a-render-pass)
    - [Suspend/Resume](#suspendresume)
  - [Render Pass tiers/CheckFeatureSupport](#render-pass-tierscheckfeaturesupport)
  - [Open Issues](#open-issues)
- [API Headers](#api-headers)
- [Runtime validation](#runtime-validation)
- [HLK Test Plan](#hlk-test-plan)
- [History of changes](#history-of-changes)

---

# Background

Render Passes are intended to help TBDR-based (and other) renderers
improve GPU efficiency by reducing memory traffic to/from off-chip
memory, by enabling applications to better identify resource rendering
ordering requirements/data dependencies.

The name "Render Passes" may be changed in a future spec.

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

~~A common rendering pattern is for an application to render to RTV A, then turn around and texture from that resource as SRV A at some time in future (while rendering to RTV B). For cases in which the writes to RTV B are reading from pixels 'one-to-one' (mapped to the identical location in SRV A), some architectures may be able to continue the current binning pass during the writes to RTV A, and avoid a flush to main memory (since the SRV A reads only have a dependency on the current tile).~~

~~A design goal is to enable these two passes to be coalesced, without a intervening flush to main memory.~~  

*[v0.08] Postponed to a future release, were not able to identify
common ISV scenarios for this functionality.*

#### Case B: Writes to the same Render Targets across multiple Command Lists

Another common rendering pattern is for the application to render to the
same render target(s) across multiple command lists serially, even
though the rendering commands are generated in parallel. This design
seeks to allow drivers to avoid a flush to main memory on Command List
boundaries, when the application knows it will resume rendering on the
immediate succeeding Command List.

A design goal is to allow these two passes to be combined in a way that
avoids an intervening flush to main memory.

### Allow the new APIs to be used with existing drivers

The design seeks to allow new APIs to be run on existing drivers (not
necessarily with any performance improvements), to ensure as
wide-as-possible an install base for the APIs.

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

# Summary of API changes

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

  - *[v0.08] Will not be addressed in RS5*

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

- Dispatch [*added in v0.08*]

- OMSetRenderTargets

- ResolveQueryData

- ResolveSubresource(Region)

- SetProtectedResourceSession

- ~~SetDescriptorHeaps [*added in v0.08, removed in v1.0*]~~

- Else?

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

- `RENDER_TARGET`/`DEPTH_WRITE` to _any read state_ on currently-bound
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

---

### D3D12_RENDER_PASS_BEGINNING_ACCESS_PRESERVE

`BEGIN_PRESERVE` signifies the application has a dependency on the prior
contents of the resource, and the contents must be loaded from main
memory.

---

### D3D12_RENDER_PASS_BEGINNING_ACCESS_CLEAR

`BEGIN_CLEAR` signifies the application has a dependency on the resource
being cleared to a specific (app-provided) color. *This clear occurs
whether or not the resource is interacted with any further in the Render
Pass*.

The API will allow the application to specify the clear values at
BeginRenderPass time, via a `D3D12_CLEAR_VALUE` struct.

---

### D3D12_RENDER_PASS_BEGINNING_ACCESS_NO_ACCESS

`NO_ACCESS` signifies the resource will not be read from or written to
during the Render Pass. It is most expected to used to denote whether
the depth/stencil plane for a DSV is not accessed.

Must be paired with `ENDING_ACCESS_NO_ACCESS`.

---

### ~~D3D12_RENDER_PASS_BEGINNING_ACCESS_RESUME_WRITING~~

~~`BEGIN_RESUME_WRITING` signifies that the application is resuming
writing to a surface that was previously written to in the previous
Render Pass and had the `ENDING_ACCESS_SUSPEND_WRITING` flag, *and no
intervening GPU work occurred between these two Render Passes*.~~

~~It is spec'd that the writes in the 'resuming' Render Pass occur after
the writes in the 'suspending' Render Pass.~~

~~The intent of this flag is to allow writes to the same Render Target
to span multiple command lists, without flushing any on-chip caches.~~

~~`RESUME_WRITING` may resume from a Render Pass in a separate Command
List, as long as the suspending/resuming Command Lists are executed
(back to back) in the same ExecuteCommandLists group.~~

[v0.08] -- In v0.08, suspend/resume was moved from being a per-view
flag and moved to be a general command list flag. Same semantics
(suspend/resumes must not have any intervening GPU work, and if they
span command lists those command lists must be in the same
ExecuteCommandLists call.)

---

### ~~D3D12_RENDER_PASS_BEGINNING_ACCESS_RESUME_LOCAL_READ~~

~~`BEGINNING_ACCESS_RESUME_LOCAL_READ` signifies that the application
wants to read from a resource that was *previously immediately written
to by the GPU (i.e. still potentially in tile cache), and will be read
from in a pixel-local fashion (i.e. reads will always be on the exact
output pixel, or adjacent pixels)*.~~

~~The goal of this enum (paired with
`ENDING_ACCESS_SUSPEND_LOCAL_READ`) is to allow resources to be read
from (when possible) without issuing a flush between two subsequent
Render Pass operations.~~

~~Specifically, the application warrants:~~

- ~~The resource has previously been written to in a Render Pass that
    had the 'write' characteristics of
    `D3D12_RENDER_PASS_ENDING_ACCESS_SUSPEND_LOCAL_READ`.~~

- ~~No GPU operations have occurred between the previous Render Pass'
    `SUSPEND_LOCAL` and the current Render Pass.~~

  - ~~A `RESUME_LOCAL_READ` may be chained from within the same
        Command List -or- between Command Lists in the same
        ExecuteCommandLists call, but *not* across separate
        ExecuteCommandLists calls.~~

- ~~The resource to be read from matches the size and format of the
    newly-bound render target~~

- ~~All reads/writes are '1-to-1' (plus optional gutter read pixels
    specified by the app), the reads from the source texture will be
    written to the same location on the target texture, and the render
    target texture is the same size as the source texture.~~

~~The kernel size of the read (how many surrounding pixels are needed)
are specified at BeginRenderPass time, through the
AdditionalWidth/AdditionalHeight fields on
`D3D12_RENDER_PASS_BEGINNING_ACCESS_RESUME_LOCAL_READ_PARAMETERS`.
The AdditionalWidth/AdditionalHeight parameters must match those on the
previous `ENDING_ACCESS_SUSPEND_LOCAL_READ`.~~

[v0.08] Removed from API/DDI, may be added in future release in
response to ISV usage scenarios.

---

### D3D12_RENDER_PASS_ENDING_ACCESS_DISCARD

`ENDING_ACCESS_DISCARD` signifies the application will have no future
dependency on the data written to the resource during this Render Pass
(may be appropriate for a depth buffer where the depth buffer will never
be textured from prior to future writes).

---

### D3D12_RENDER_PASS_ENDING_ACCESS_PRESERVE

`ENDING_ACCESS_PRESERVE` signifies the application will have a
dependency on the written contents of this resource in the future (and
they must be preserved).

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

---

### D3D12_RENDER_PASS_ENDING_ACCESS_NO_ACCESS

`ENDING_ACCESS_NO_ACCESS` signifies the resource will not be read from
or written to during the Render Pass. It is most expected to used to
denote whether the depth/stencil plane for a DSV is not accessed.

Must be paired with `BEGINNING_ACCESS_NO_ACCESS`.

---

### ~~D3D12_RENDER_PASS_ENDING_ACCESS_SUSPEND_WRITING~~

~~See *D3D12_RENDER_PASS_BEGINNING_ACCESS_RESUME_WRITING.*~~

~~`ENDING_ACCESS_SUSPEND_WRITING` signifies that the application will
continue writing to the resource in an immediately succeeding Render
Pass (with no intervening GPU work).~~

---

### ~~D3D12_RENDER_PASS_ENDING_ACCESS_SUSPEND_LOCAL_READ~~

~~See *D3D12_RENDER_PASS_BEGINNING_ACCESS_RESUME_LOCAL_READ.*~~

~~Signifies the application has written to the resource, and it will
read from the resource in the future in a one-to-one (plus optional
gutter pixels) fashion (in the pixel shader, only the current pixel plus
an optional number of surrounding pixels will be read from). Most
importantly, this enum signifies that no GPU operations will occur
between the SUSPEND and RESUME.~~

---

## Render Pass Flags

```C++
typedef enum D3D12_RENDER_PASS_FLAGS
{
    D3D12_RENDER_PASS_FLAG_NONE = 0,
    D3D12_RENDER_PASS_FLAG_ALLOW_UAV_WRITES = 0x1,
    D3D12_RENDER_PASS_FLAG_SUSPENDING_PASS = 0x2,
    D3D12_RENDER_PASS_FLAG_RESUMING_PASS = 0x4
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

---

### Suspend/Resume

In v0.08, applications now suspend/resume an entire render pass.
Suspending/Resuming render passes must have identical views/access flags
between the passes, and may not have any intervening GPU ops (draws,
dispatches, discards, clears, copies, updatetilemappings,
writebufferimmediates, queries, query resolves, ..) between the
suspending/resuming render passes.

The intended use case is multi-threaded rendering, where say four CLs
(each with their own render passes) could target the same render
targets. When render passes are suspended/resumed across command lists,
the command lists must be executed in the same ExecuteCommandLists call.

A render pass can be both resuming and suspending -- in the
multi-threaded example, CLs 2 and 3 would be resuming from 1 and 2
respectively, and suspending to 3 and 4 respectively.

---

## Render Pass tiers/CheckFeatureSupport

Applications will be able to query the extent to which a UMD/HW
efficiently supports Render Passes.

Though Render Passes will always function given the runtime's mapping
logic, this allows applicatinos (notably 11on12) to determine when it is
(possibly) worth their while to issue their commands as Render Passes,
and when it is definitely not a benefit (when the runtime is just
mapping to the existing API surface).

There will be three tiers of support:

- `D3D12_RENDER_PASS_TIER_0` -- UMD has not implemented DDI
    Table, supported via SW emulation

- `D3D12_RENDER_PASS_TIER_1` -- Render Passes implemented by
    UMD, RT/DB writes may be accelerated. UAV writes *not* efficiently
    supported within the Render Pass.

- `D3D12_RENDER_PASS_TIER_2` -- Tier 1, plus that UAV writes
    (pursuant to the read-after-write prohibition) are likely to be
    efficiently supported (more efficient than issuing the same work
    without a Render Pass).

The UMD will report back these tiers to the runtime. The runtime will
validate that UMDs which fill out the DDI table at least report back
TIER_1, and at the same time will validate that UMDs which do not fill
out the DDI table do not claim anything other than TIER_0 support (the
runtime will fail device creation in this case).

This requirement will only be present for UMDs supporting a the DDI
build version in which this change is made.

---

## Open Issues

- Should the `BEGINNING/ENDING_ACCESS` flags be at the sub-resource
    level for RTVs? They are already specific to the depth/stencil
    planes.

  - [v0.08] Not for RS5

- Should the user specify at the Render Pass level the
    write/read-regions of a resource? Can that be inferred through
    viewport/scissor information mostly-well-enough?

  - [v0.08] Not for RS5

- Do PSOs, VBs/IBs need to be incorporated into the Render Pass
    structure?

  - [v0.08] No indication this is needed.

- Better name than `_DISCARD`? E.g. "`DON'T_CARE`"?

- Is it ok to not support SO within a Render Pass (spec currently does
    not support this)

  - [v0.08] SO is supported within render passes

- Should we let users call `OMSetRenderTargets` within a Render Pass, as
    long as they still to RTVs specified?

  - Need to determine if there's a scenario for this that's worth
        the extra complexity

  - [v0.08] No

- Should we add back in resource barriers associated with
    BeginRenderPass? Is that buying UMDs anything?

- Can ROV writes be supported?

- Else?

---

# API Headers

```C++
// Beginning Access
typedef enum D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE
{
    D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_DISCARD,
    D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_PRESERVE,
    D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_CLEAR,
    D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE_NO_ACCESS
} D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE;

typedef struct D3D12_RENDER_PASS_BEGINNING_ACCESS_CLEAR_PARAMETERS
{
    D3D12_CLEAR_VALUE ClearValue;
} D3D12_RENDER_PASS_BEGINNING_ACCESS_CLEAR_PARAMETERS;

typedef struct D3D12_RENDER_PASS_BEGINNING_ACCESS
{
    D3D12_RENDER_PASS_BEGINNING_ACCESS_TYPE Type;
    union
    {
        D3D12_RENDER_PASS_BEGINNING_ACCESS_CLEAR_PARAMETERS Clear;
    };
} D3D12_RENDER_PASS_BEGINNING_ACCESS;

// Ending Access
typedef enum D3D12_RENDER_PASS_ENDING_ACCESS_TYPE
{
    D3D12_RENDER_PASS_ENDING_ACCESS_TYPE_DISCARD,
    D3D12_RENDER_PASS_ENDING_ACCESS_TYPE_PRESERVE,
    D3D12_RENDER_PASS_ENDING_ACCESS_TYPE_RESOLVE,
    D3D12_RENDER_PASS_ENDING_ACCESS_TYPE_NO_ACCESS
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

typedef struct D3D12_RENDER_PASS_ENDING_ACCESS
{
    D3D12_RENDER_PASS_ENDING_ACCESS_TYPE Type;
    union
    {
        D3D12_RENDER_PASS_ENDING_ACCESS_RESOLVE_PARAMETERS Resolve;
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

The following validation will be added to the core runtime:

- *[checked in 3/15/18] Render Passes may not be started within
    non-DIRECT command lists*

- *[checked in 3/20/18] Render Passes must be ended before calling
    ID3D12CommandList::Close*

- *[checked in 3/20/18] Render Passes may not be nested (two begins
    in a row)*

- *[checked in 3/20/18] A Render Pass may not be ended twice in a
    row*

- *[checked in 3/22/18]* Disallowed APIs may not be called during a
    Render Pass (command list will be removed)

The following will be added to SDK Layers:

- *[checked in 3/20/18] Translate `DISCARD` (`BEGINNING_ACCCESS` or
    `ENDING_ACCESS`) to "clear-to-a-random-value", since that shouldn't
    impact app at all.*

- No GPU work occurs within a command list between a `ENDING_SUSPEND`
    and `BEGINNING_RESUME`.

- If a Command List ends with a `ENDING_SUSPEND`, the next command list
    within that ExecuteCommandLists group must exist, and must begin
    with a `BEGINNING_RESUME` (with matching RT/DBs).

- A ResourceBarrier is not issued on a resource that was actually
    written within the current Render Pass (e.g. a bound UAV, or
    currently-bound RTs/DBs).

---

# HLK Test Plan

11on12 will replace OMSetRenderTargets calls with
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

- For a BEGINNING/ENDING **preserve**, when no work occurs in the
    Render Pass, the values are still present in the Render Target
    outside of the Render Pass

---

# History of changes

Date | Version | Description
-|-|-
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
