<h1>D3D12 View Instancing Functional Spec</h1>

v0.4, 5/12/2017

---

# Contents

- [Contents](#contents)
- [Overview](#overview)
- [API](#api)
  - [View Instancing Declaration](#view-instancing-declaration)
    - [View Instance Locations](#view-instance-locations)
    - [View Instance Masking](#view-instance-masking)
    - [Maximum ViewInstanceCount](#maximum-viewinstancecount)
- [SetViewInstanceMask](#setviewinstancemask)
  - [Referencing Views in Shaders](#referencing-views-in-shaders)
    - [SV_ViewID](#sv_viewid)
    - [View Dependent Vertex Storage](#view-dependent-vertex-storage)
      - [Validation/Enforcement of View Dependent Storage](#validationenforcement-of-view-dependent-storage)
    - [Implementation Flexibility](#implementation-flexibility)
    - [Input Assembler Interaction](#input-assembler-interaction)
    - [Rasterizer Interaction](#rasterizer-interaction)
    - [ExecuteIndirect Interaction](#executeindirect-interaction)
    - [Degenerate Instancing](#degenerate-instancing)
    - [Shader Awareness of View Instancing](#shader-awareness-of-view-instancing)
    - [UAV Accesses](#uav-accesses)
    - [About Tessellation](#about-tessellation)
    - [View Instancing Work Ordering Semantics](#view-instancing-work-ordering-semantics)
      - [Overlapping Viewport/Scissors](#overlapping-viewportscissors)
  - [Capability Exposure](#capability-exposure)
- [DDI](#ddi)
- [Pipeline State](#pipeline-state)

---

# Overview

This feature enables instancing of the graphics pipeline by "view", in a
manner that is orthogonal to draw instancing. Looping of view instances
can happen anywhere from before draw instancing to late in the graphics
pipeline depending on the sophistication of the implementation.
Meanwhile applications can write one codepath for driving multiple views
that can target the breadth of hardware.

The view instance count is a fixed declaration in Pipeline State
Objects. Graphics shaders can read system value SV_ViewID [0..view
instance count] identifying the current view.

An obvious way for an app to use the feature is for the shader stage
feeding the rasterizer to generate SV_Position position as a function
of SV_ViewID. The render target and viewport that each view goes to is
declared in the PSO. So a single draw call can send geometry to multiple
output surface locations with different projections, such as left and
right eye for stereo rendering. The view instance locations declared in
the PSO can also be offset by shaders outputting existing system values
SV_RenderTargetArrayIndex and/or SV_ViewportArrayIndex.

*This is a replacement for the D3D12 Primitive Broadcast spec, which
attempted to expose both multi position shaders as well as the ability
for a given position going to the rasterizer to be broadcast in a fixed
function way to a set of viewport/scissor/RTArrays. The per view
broadcast portion proved difficult to align across IHVs, so instead the
spec has been simplified to simply handle shaders instancing multiple
views. In the future, more sophistication about what happens for a given
view could be added.*

---

# API

---

## View Instancing Declaration

View instancing is declared in PSOs via
`D3D12_PIPELINE_STATE_SUBOBJECT_TYPE`:

```C++
D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_VIEW_INSTANCING
```

The PSO subobject corresponding to this is `D3D12_VIEW_INSTANCING_DESC`
below:

```C++
typedef struct D3D12_VIEW_INSTANCE_LOCATION
{
    UINT ViewportArrayIndex;
    UINT RenderTargetArrayIndex;
} D3D12_VIEW_INSTANCE_LOCATION;

typedef enum D3D12_VIEW_INSTANCING_FLAGS
{
    D3D12_VIEW_INSTANCING_FLAG_NONE = 0x0,
    D3D12_VIEW_INSTANCING_FLAG_ENABLE_VIEW_INSTANCE_MASKING = 0x1,
} D3D12_VIEW_INSTANCING_FLAGS;

typedef struct D3D12_VIEW_INSTANCING_DESC
{
    UINT ViewInstanceCount;
    _Field_size_full_(ViewInstanceCount) const D3D12_VIEW_INSTANCE_LOCATION\* pViewInstanceLocations;
    D3D12_VIEW_INSTANCING_FLAGS Flags;
} D3D12_VIEW_INSTANCING_DESC;
```

The reason the view instance count is fixed in the PSO is to allow whole
pipeline optimization based on the desired view count.

The absence of a view instancing declaration or ViewInstanceCount set to
0 in a PSO means view instancing is disabled. What disabled really means
is rendering behaves the same as having ViewInstanceCount set to 1.
Shaders that input SV_ViewID will only see the value 0 and whether or
not they input SV_ViewID, only one view instance is produced. In this
way an application can author shaders that are view instancing aware
that can function even in PSOs that have view instancing disabled.
Drivers that support shader model 6.1 (which exposes SV_ViewID ) but
which do not expose support for view instancing must still support
running shaders that input SV_ViewID in PSOs that declare
ViewInstanceCount as 0 (disabled) or 1 (the same).

---

### View Instance Locations

A part of the view instancing declaration is an array of view instance
locations of size equal to the view instance count. Each view instance
location specifies a viewport array index (which selects both a viewport
and paired scissor) and rendertarget array index to be used for the
view.

The shader feeding the rasterizer can output RenderTargetArrayIndex
and/or ViewportArrayIndex if desired (may or may not be dependent on
SV_ViewID). These get added to the view instance locations in the PSO's
view instancing declaration via 32 bit UINT arithmetic (which can wrap)
to determine the final location to send primitives. Out of range values
go to array index 0 for the relevant array.

If the shader will be dynamically selecting render target or viewport
array index, a scenario that can make sense for an application is to set
all the view instance locations in the PSO to the same values (such as
0), acting as uniform base value for all views.

---

### View Instance Masking

The view instance declaration can include a flag for enabling view
instance masking. The presence of this flag means that a bitmask can be
set from the CommandList/Bundle to mask off individual view instances in
the set 0...ViewInstanceCount-1 views -- see SetViewInstanceMask().

---

### Maximum ViewInstanceCount

There may need to be an upper limit on ViewInstanceCount. If it would
help keep hardware on fast paths, ViewInstanceCount could be limited to
somewhere around 4 to 16 instances. Picking 4 for now:

```C++
#define D3D12_MAX_VIEW_INSTANCE_COUNT 4
```

---

# SetViewInstanceMask

```C++
ID3D12CommandList2::SetViewInstanceMask(UINT Mask);
```

Set a mask controlling which view instances are enabled for subsequent
draws. If bit *i* starting from the LSB is set, view instance *i* is
enabled. This enables coarsely culling draws from particular views that
an application knows will not be covered.

The view instance mask is only honored by PSOs that have view instancing
enabled and declare that they look at the view instance mask.

The view instance mask defaults to 0 (all views disabled). The reason
the default is 0 is if an application declares in PSO(s) that it wants
to use the view instance mask, it must actually use the mask, otherwise
nothing will be rendered to any views. If the default were the opposite,
all bits set, an application might forget to change the mask as
intended, resulting in draws wasting vertex processing by being sent to
views that will not be covered.

Bundles do not inherit the view instance mask in from the caller, and
the state starts at the default of 0. The reason for this is if the mask
setting affects how an implementation records draws, it must be known
when the bundle is recorded. View instance mask state set by a bundle
does leak back out to the caller after the bundle completes. These
inheritance semantics are similar to PSOs.

---

## Referencing Views in Shaders

---

### SV_ViewID

Graphics shaders in shader model 6.1+ can input unsigned 32-bit integer
system value SV_ViewID identifying the current view. These inputs don't
appear in shader input or output signatures for the purpose of shader
linkage, and shaders can't output them (as system values).

If a shader references SV_ViewID, that reference and its dependencies
logically/implicitly become instanced by ViewInstanceCount.

If the Pixel Shader inputs SV_ViewID, one of the input vertex data
scalars is reserved (taken away from the amount of data the application
can put in its vertices) to allow some implementations to pass the
SV_ViewID through vertex data. Applications don't need to bother
outputting SV_ViewID to the Pixel Shader from the upstream shader --
only the implementations that need to will do it when compiling the PSO.

---

### View Dependent Vertex Storage

Any shader output that is a function of SV_ViewID implicitly costs
ViewInstanceCount scalars (as opposed to just 1 without instancing)
towards the 128 scalar limit on vertex size between any two shader
stages. Not all implementations have this limit but it is enforced for
uniformity.

There is nothing the application has to indicate in its shader output
declaration about which attributes are view dependent. The HLSL compiler
does annotate, in the bytecode it generates, which outputs could have
been influenced by an SV_ViewID reference based on code flow.
Regardless of whether the actual computed values end up being view
varying or not, any output with a possible SV_ViewID dependency is
assumed to vary per view by implementations. This annotation is used
during PSO creation to enforce the vertex size cost function based on
the PSO's declared ViewInstanceCount.

---

#### Validation/Enforcement of View Dependent Storage

The HLSL compiler generates metadata in shader bytecode to assist with
validation of vertex size as a function of ViewInstanceCount at PSO
creation time. There are three components to the metadata:

(1) A bit for every scalar output of a shader indicating if it could be
    influenced by a reference to ViewID in that shader

(2) A bit vector that describes for every scalar output from a shader
    which inputs influence it

(3) Arrays in shader inputs or outputs have a bit indicating whether
    they are dynamically indexed

When a PSO is created with a pipeline of shaders, any data passing
between shader stages that depends on ViewID needs to be costed as
ViewInstanceCount scalars towards maximum data size between shader
stages. (1) above provides the most obvious indication of direct
dependency. (2) above allows a dependence on ViewID from an output from
one shader to be propagated through to the outputs of the next shader
and so on. Subsequent shaders may inherit a ViewID dependence from an
output of the previous stage.

(3) above helps with the following: Suppose interstage data contains
arrays and the producing shader stage computes some part of the array as
a function of ViewID. If either the producing shader stage or the
consuming stage use dynamic indexing to address the array, then for
costing purposes the entire array is considered to be dependent on
ViewID. On the other hand if both the producing shader stage and the
consuming stage only statically index the elements of the array, then
any ViewID dependence is costed only against the specific entries in the
array that are ViewID dependent. The reason dynamically indexed arrays
take a conservative approach to propagating ViewID dependency is to give
implementations an obvious solution to how to handle the dynamic
indexing -> just replicate the entire array knowing it will certainly
fit within interstage storage limits.

At PSO creation, the runtime uses (1) (2) and (3) to generate an updated
version of the view ID dependency bits (1) taking account all the
shaders in the PSO. This is what is validated against storage limits.
Drivers must do the same if they need to determine unambiguously what
might depend on ViewID.

If developers show interest over time, the debug layer could report this
dependency information for PSOs back to applications during development.

---

### Implementation Flexibility

It is up to an implementation how much redundant shading work can be
saved by only instancing view dependent portions of code, while
executing non view dependent portions only once. On one extreme, a basic
implementation could loop draw calls at the top of the pipeline even
before draw instance looping, even if SV_ViewID is only referenced far
downstream shader such as in the Domain Shader. On another extreme, an
implementation might choose to (and be able to) instance as late as the
first shader stage that references SV_ViewID, and even then, possibly
only instancing the portions of the code that are dependent on view.

If a shader stage has external side effects, such as UAV accesses, this
can reveal implementation differences in terms of how different
implementations choose to implement instancing.

If a shader stage that is not last before rasterizer compute outputs
based on SV_ViewID, downstream shaders are logically instanced such
that each logical downstream shader instance sees inputs that appear to
be for its single view instance. The downstream shaders can choose to
input SV_ViewID or not and either way they are effectively instanced
logically already due to the upstream SV_ViewID dependency. Despite the
logical instancing, in practice an advanced implementation might only
instance/loop over the SV_ViewID dependent work throughout all
downstream shader stages, minimizing redundant work for non-SV_ViewID
dependent code.

---

### Input Assembler Interaction

With *draw* instancing, Input Assembler vertex fetches can be made to be
dependent on the current instance, but with *view* instancing the Input
Assembler doesn't perform any SV_ViewID dependent work -- that is left
for shader code. Said another way, view instancing doesn't interact with
the Input Assembler. If a naïve implementation of view instancing looped
entire draw calls, the IA work gets done per view. But in a smarter
implementation, IA work is only done once for all views.

---

### Rasterizer Interaction

If the rasterizer is active, view instancing results in rasterization of
each view's primitives using the selected viewport/scissor and render
target array index. The array index selections come from the PSO view
instancing declaration. On higher tier hardware the array indices in the
view instan7cing declaration get added to any viewport and/or render
target array index outputs the shader feeding the rasterizer might
produce (which could be a function of SV_ViewID if desired).

---

### ExecuteIndirect Interaction

Lower tier hardware that loops draws to implement view instancing is
permitted to loop over an entire execute indirect buffer per view rather
than looping each individual draw in the execute indirect buffer.

---

### Degenerate Instancing

If a PSO defines a ViewInstanceCount > 1 but no shader computes any
view dependent outputs, and all view locations in the PSO are identical,
a valid implementation is repeating a completely identical draw call
ViewInstanceCount times. Since an implementation can choose to only
instance shader code that is dependent on view, another equally valid
implementation is to execute this draw's shaders only once (not per
view). While this entire scenario isn't likely useful, it is stated
merely to give perspective on how the system works.

---

### Shader Awareness of View Instancing

It is intentional that shaders authored without instancing in mind can
be combined with shaders that are aware of instancing. To minimize the
impact on an application's shader assets for supporting view instancing,
SV_ViewID does not factor into valid linkage between shaders.

That said, it is certainly possible that if a given shader gets used
with PSOs that use view instancing as well as PSOs that do not use view
instancing, drivers may need to compile the shader separately for each
use case. Even ignoring view instancing, however, drivers have the
freedom to perform such per-PSO specialization of shaders if they want
to anyway. So there's nothing unique about View Instancing in this
context.

---

### UAV Accesses

It is fine for UAV accesses to have their address and/or the data
involved be dependent on SV_ViewID.

Depending on hardware tier, implementations may or may not treat the
result of a UAV read before the rasterizer as a quantity that is
dependent on SV_ViewID. This applies regardless if it may or may not be
obvious that somewhere earlier in a shader an SV_ViewID dependent value
was written to the same UAV address now being read. An implementation
that loops draws to implement view instancing will run all UAV memory
accesses per-view. But at Tier 3, implementations must assume the
results of UAV reads before the rasterizer are not SV_ViewID dependent.

---

### About Tessellation

When View Instancing is used with Tessellation, an application may want
the same tessellation factor selections to apply to all views so that
topology is consistent across views (such as for stereo rendering --
matching triangles to allow for stereo fusion). This can be accomplished
by computing tessellation factors without referencing SV_ViewID, such
as basing the calculations on view 0 for instance (therefore shared for
all views). Then only using SV_ViewID for other patch related
calculations as needed, even if it may result in some redundant work
between the fixed/shared view 0 based calculations mentioned and
SV_ViewID based calculation when SV_ViewID is 0.

---

### View Instancing Work Ordering Semantics

The implementation may perform view instancing anywhere earlier than the
first dependency on SV_ViewID in the shaders provided by an
application, including before or after draw instancing, with the
possibility of with varying levels of redundancy in shader invocations
to get the requested job done. That all said, there are some properties
about primitive ordering that must hold:

Suppose a draw is submitted that contains multiple primitives, possibly
with draw instancing, but without considering any view instancing yet.
Consider any two of those primitives, *p*, and *p'*, where *p'* > *p*
in the draw workload.

Without view instancing, recall that it is guaranteed that *p* and any
primitives descended/expanded from it (such as from tessellation) are
guaranteed to be retired by the rasterizer / output merger before *p'*
and its descendants retire. The order of shader invocations in this
workload earlier than the rasterizer is not strictly defined, and may
include redundant shader invocations depending on the implementation.

Now consider adding view instancing. Consider any two of the views in a
workload, having SV_ViewIDs *v*, and *v'*, where *v'* > *v*. Factoring
in the draw described above, consider also primitives *p* and *p'* (sent
to each view instance now), where *p' > p*.

With view instancing, primitive p for view v is guaranteed to be
processed at the rasterizer before primitive p' for view v. However
primitive p for view v' is not guaranteed to be processed before p' for
view v.

In other words, an implementation may complete the entire draw instance
for a given view instance before moving to the next view instance. Or it
may go through a subset of primitives (or parts of a given primitive in
the case of tessellation) for each view instance before advancing to the
next subset of primitives (or part of a given primitive in the case of
tessellation) for each view instance. Regardless, when looking at a
particular view, all primitives are retired by the rasterizer in order.

---

#### Overlapping Viewport/Scissors

If multiple view instances go to overlapping viewport/scissor regions on
the same renderTargetArrayIndex, rendering results in the overlapping
area are undefined given the flexibility implementations have in
progressing through work over separate views.

---

## Capability Exposure

Tier 0                            | View instancing not supported.
---|---
Tier 1                            | View instancing supported by draw level looping only. The shader feeding the rasterizer cannot output viewport array index or render target array index. View instance locations come from the view instancing declaration in the PSO.
Tier 2                            | <p>Functionally no different than Tier 1 within work order tolerances allowed by spec.</p><p>View instancing supported by draw level looping in the worst case, but in certain cases can run more efficiently. Specific fast path cases could be called out if interesting, though they would likely be specific to individual hardware architectures.</p><p>As an example, one possible hardware implementation can do better than draw level looping if the shader feeding the rasterizer satisfies the following:</p><p>View instance locations {RenderTargetArrayIndex,ViewportArrayIndex} are defined as: {n,0}, {n+1,0}, {n+2,0}... where n is any value.</p><p>Perhaps there will be a universal fast path that works for this tier that falls out of the intersection of the fast paths on various implementations.</p>
Tier 3                            | <p>Functionally the same as Tier 1 within work order tolerances allowed by spec, with the following improvement:</p><p>The implementation of view instancing always occurs at the first shader stage that references SV_ViewID (or rasterizer, whichever is earliest). This indicates that redundant non SV_ViewID dependent shader work across view instances is relatively minimal. Redundant shading is limited to just the first SV_ViewID dependent shader stage's code, if not avoided completely.

```C++
typedef enum D3D12_VIEW_INSTANCING_TIER
{
    D3D12_VIEW_INSTANCING_TIER_0;
    D3D12_VIEW_INSTANCING_TIER_1;
    D3D12_VIEW_INSTANCING_TIER_2;
D3D12_VIEW_INSTANCING_TIER_3;
} D3D12_VIEW_INSTANCING_TIER;

typedef struct D3D12_FEATURE_DATA_D3D12_OPTIONS3
{
    ...
    <Snip>

    ...
    D3D12_VIEW_INSTANCING_TIER ViewInstancingTier;
} D3D12_FEATURE_DATA_OPTIONS3;

// The above is the capability reporting data structure used with
CheckFeatureSupport() and

// the feature set: D3D12_FEATURE_D3D12_OPTIONS3
```

---

# DDI

---

# Pipeline State

A view instancing desc is added to pipeline state.

```C++
typedef struct D3D12DDI_VIEW_INSTANCE_LOCATION
{
    UINT ViewportArrayIndex;
    UINT RenderTargetArrayIndex;
} D3D12DDI_VIEW_INSTANCE_LOCATION;

typedef enum D3D12DDI_VIEW_INSTANCING_FLAGS
{
    D3D12DDI_VIEW_INSTANCING_FLAG_NONE = 0x0,
    D3D12DDI_VIEW_INSTANCING_FLAG_ENABLE_VIEW_INSTANCE_MASKING = 0x1,
} D3D12DDI_VIEW_INSTANCING_FLAGS;

typedef struct D3D12DDI_VIEW_INSTANCING_DESC
{
    UINT ViewInstanceCount;
    _Field_size_full_(ViewInstanceCount) const D3D12DDI_VIEW_INSTANCE_LOCATION* pViewInstanceLocations;
    D3D12DDI_VIEW_INSTANCING_FLAGS Flags;
} D3D12DDI_VIEW_INSTANCING_DESC;

typedef struct D3D12DDIARG_CREATE_PIPELINE_STATE_0033
{
    D3D12DDI_HSHADER hComputeShader;
    D3D12DDI_HSHADER hVertexShader;
    D3D12DDI_HSHADER hPixelShader;
    D3D12DDI_HSHADER hDomainShader;
    D3D12DDI_HSHADER hHullShader;
    D3D12DDI_HSHADER hGeometryShader;
    D3D12DDI_HROOTSIGNATURE hRootSignature;
    D3D12DDI_HBLENDSTATE hBlendState;
    UINT SampleMask;
    D3D12DDI_HRASTERIZERSTATE hRasterizerState;
    D3D12DDI_HDEPTHSTENCILSTATE hDepthStencilState;
    D3D12DDI_HELEMENTLAYOUT hElementLayout;
    D3D12DDI_INDEX_BUFFER_STRIP_CUT_VALUE IBStripCutValue;
    D3D12DDI_PRIMITIVE_TOPOLOGY_TYPE PrimitiveTopologyType;
    UINT NumRenderTargets;
    DXGI_FORMAT RTVFormats[8];
    DXGI_FORMAT DSVFormat;
    DXGI_SAMPLE_DESC SampleDesc;
    D3D12DDI_VIEW_INSTANCINC_DESC ViewInstancingDesc;
    UINT NodeMask;
    D3D12DDI_LIBRARY_REFERENCE_0010 LibraryReference;
} D3D12DDIARG_CREATE_PIPELINE_STATE_0033;

## CommandList

```C++
typedef VOID ( APIENTRY\* PFND3D12DDI_SETVIEWINSTANCEMASK_0031 )( D3D12DDI_HCOMMANDLIST, UINT Mask );

typedef struct D3D12DDI_COMMAND_LIST_FUNCS_3D_0033
{
    ...
    <snip>
    ...
    PFND3D12DDI_SETVIEWINSTANCEMASK_0033 pfnSetViewInstanceMask;
} D3D12DDI_COMMAND_LIST_FUNCS_3D_0033;
```

---

## Capability Reporting

```C++
typedef enum D3D12DDI_VIEW_INSTANCING_TIER
{
    D3D12DDI_VIEW_INSTANCING_TIER_0;
    D3D12DDI_VIEW_INSTANCING_TIER_1;
    D3D12DDI_VIEW_INSTANCING_TIER_2;
    D3D12DDI_VIEW_INSTANCING_TIER_3;
} D3D12DDI_VIEW_INSTANCING_TIER;

// D3D12DDICAPS_TYPE_D3D12_OPTIONS
typedef struct D3D12DDI_D3D12_OPTIONS_DATA_0033
{
    ...
    <snip>
    ...
    D3D12_VIEW_INSTANCING_TIER ViewInstancingTier;
} D3D12DDI_D3D12_OPTIONS_DATA_0033;
```

---

## Change History

v0.4 5/2/2017

- Clarified the behavior of ViewInstanceCount set to 0 (or not part of
    PSO): works the same as ViewInstanceCount set to 1. In fact even
    drivers that do not support view instancing but otherwise support
    shader model 6.1 must support shaders inputting SV_ViewID, as long
    as ViewInstanceCount in the PSO has been declared as 1 (or 0 /
    disabled), so the driver compiler can just replace references to
    SV_ViewID with 0. This lets applications author shaders that are
    SV_ViewID aware that can be used with or without view instancing
    being used

- Picked 4 for MaxViewInstanceCount, at least for now. We could choose
    to allow larger values but say that even on the current highest
    tier, going above 4 means the implementation can fall back to draw
    looping.

- Fleshed out DDIs. Still need to add DDI for input->output and
    viewID->output dependency graphs for shaders within a PSO.

- Added UAV Accesses section to discuss their interaction with
    SV_ViewID dependent data.

- Allow SV_RenderTargetArrayIndex and SV_ViewportArrayIndex to be
    written by any tier (was limited to Tier 3 only before). These get
    added with UINT32 arithmetic to the corresponding view instance
    location declared in the PSO for each view, and if the result of the
    add is out of range it clamps to 0 (like the standard behavior for
    these SV_ values).

v0.3 4/17/2017

- Removed SV_ViewInstanceCount. If apps need this in shaders they can
    just pass it themselves.

- Added section: "Validation/Enforcement of View Dependent Storage",
    detailing metadata that the HLSL compiler will generate to help with
    vertex size validation (when a function of ViewID) at PSO creation
    time. Computed ViewID dependencies for shader outputs, including
    propagating them across shaders in a PSO, will be passed to the
    driver to be concrete about exactly what in any given PSO is ViewID
    dependent.

- Added SetViewInstanceMask(UINT mask) state to the command list. This
    determines which view instances for a draw are enabled (enabling
    view culling from the command list). PSOs that want to honor the
    mask must indicate it in their view instancing declaration.

- Added array of view instance locations, {RenderTargetArrayIndex,
    ViewportArrayIndex} pairs, to the PSO view instancing declaration.
    For lower tier hardware, the shader feeding the rasterizer cannot
    output RTAI/VPAI and the view instance locations simply come from
    the PSO declaration. Higher tier hardware supports the shader
    feeding the rasterizer to export RTAI/VPAI and it gets added to the
    instance locations declared in the PSO.

- Allowed SV_ViewID input in the Pixel Shader again, at the cost of
    reserving one scalar slot in the input vertex data to allow
    implementations to manually pass ViewID to the Pixel Shader if
    needed.

- Refined Tier definitions to discuss view instance location
    flexibility.

v0.2 3/9/2017

- More crisp definition of which outputs HLSL compiler will mark as
    SV_ViewID dependent (doesn't matter if the actual calculated result
    would vary based on view).

- Clarified that implementations may not need to instance all work
    downstream of an SV_ViewID dependency -- perhaps only limiting the
    looping/instancing to just the SV_ViewID dependent code.

- Clarified that the IA does not interact with view instancing

- Disallowed SV_ViewID input at the Pixel Shader, given a conceptual
    model that views are ultimately manifested at the rasterizer. That
    said, if an application need SV_ViewID in the Pixel Shader for some
    reason it can manually pass the value through vertex data.
