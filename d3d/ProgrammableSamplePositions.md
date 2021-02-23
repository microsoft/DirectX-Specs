<h1>D3D12 Programmable Sample Positions</h1>

v0.5

3/20/2017

---

<h1>Contents</h1>

- [Overview](#overview)
- [API](#api)
  - [Position](#position)
  - [SetSamplePositions](#setsamplepositions)
  - [Sample Position Operational Semantics](#sample-position-operational-semantics)
    - [CommandList](#commandlist)
    - [Clear RenderTarget](#clear-rendertarget)
    - [Clear DepthStencil](#clear-depthstencil)
    - [Draw using RenderTarget](#draw-using-rendertarget)
    - [Draw using DepthStencil](#draw-using-depthstencil)
    - [Resolve RenderTarget](#resolve-rendertarget)
    - [Resolve DepthStencil](#resolve-depthstencil)
    - [Copy RenderTarget](#copy-rendertarget)
    - [Copy DepthStencil (Full Subresource)](#copy-depthstencil-full-subresource)
    - [Copy DepthStencil (Partial Subresource)](#copy-depthstencil-partial-subresource)
    - [Shader SamplePos](#shader-samplepos)
    - [Transitioning out of DEPTH_READ or DEPTH_WRITE state](#transitioning-out-of-depth_read-or-depth_write-state)
    - [Transitioning out of RENDER_TARGET state](#transitioning-out-of-render_target-state)
- [ResolveSubresourceRegion](#resolvesubresourceregion)
- [Experimental Feature: Mixed Rate Rasterization](#experimental-feature-mixed-rate-rasterization)
- [Hardware Tiers](#hardware-tiers)
- [DDI](#ddi)
  - [SetSamplePositions DDI](#setsamplepositions-ddi)
  - [ResolveSubresourceRegion DDI](#resolvesubresourceregion-ddi)
  - [Capability Support](#capability-support)
- [Validation](#validation)
  - [Runtime](#runtime)
  - [Debug Layer](#debug-layer)
- [Testing](#testing)
  - [Functional Tests](#functional-tests)
  - [Conformance Tests](#conformance-tests)
    - [Initial Bringup Test](#initial-bringup-test)
    - [SetSamplePositions Tier 2 test](#setsamplepositions-tier-2-test)
    - [Copy Test](#copy-test)
    - [Decompress Test](#decompress-test)
- [Change Log](#change-log)

---

# Overview

This feature allows applications to program the sample pattern used by
the rasterizer for all bound RenderTargets and Depth/Stencil buffers.
This feature is optional for IHVs to implement.

---

# API

===

---

## Position

```C++
typedef struct D3D12_SAMPLE_POSITION
{
    INT8 X;
    INT8 Y;
} D3D12_SAMPLE_POSITION;
```

Sample positions have the origin (0,0) at the pixel center.

X spans [-8..7], left to right.

Y spans [-8..7], top to bottom.

So the right and bottom edges of a pixel are not reachable by samples
(the neighboring pixels get them). Positions outside this range are
invalid.

Integer position values represent 1/16ths of a pixel. So for example
integer position (-8,4) means (-0.5,0.25) in floating point.

---

## SetSamplePositions

```C++
void
ID3D12GraphicsCommandList2::SetSamplePositions(
        UINT NumSamplesPerPixel,
        UINT NumPixels,
        __in_ecount(NumSamplesPerPixel*NumPixels) D3D12_SAMPLE_POSITION* pSamplePositions);
```

NumPixels can be 1 or 4, otherwise the call is dropped. 1 configures a
sample pattern to be repeated for every pixel. 4 configures a separate
sample pattern for each pixel in a 2x2 grid that repeats over the
RenderTarget / viewport space aligned to even coordinates in the
floating point pixel coordinate space.

NumSamplesPerPixel can be 1, 2, 4, 8 or 16, otherwise the call is
dropped. At Draw, this number must match the sample count in the PSO
else behavior is undefined. (In the Mixed Rate Rasterization experiment
described later, NumSamplesPerPixel must match the highest sample count,
which would be the DepthStencil's count if it is used)

NumPixels * NumSamplesPerPixel cannot exceed 16, otherwise the call is
dropped.

pSamplePositions specifies NumPixels*NumSamplesPerPixel positions. The
ordering of positions is all samples for a given pixel before moving to
the next pixel, in left->right, top->bottom order for the pixels
(relevant when NumPixels > 1).

The order of positions for a given pixel also indicates centroid
sampling priority ordering (if centroid interpolation is used during
rendering). In other words, with centroid sampling, the first covered
sample in the order specified is chosen as the centroid sample location.

---

## Sample Position Operational Semantics

---

### CommandList

In the absence of any calls to SetSamplePositions on a CommandList (so
far), sample positions assume the default for whatever the Pipeline
State Object used for drawing indicates, either via the SAMPLE_DESC
portion of the PSO if that applies, or standard sample positions if
ForcedSampleCount > 0 is being used in the RASTERIZER_DESC portion of
the PSO.

Once SetSamplePositions has been called, subsequent Draw* calls must
use a PSO that either specifies a matching sample count as
SetSamplePositions via the SAMPLE_DESC portion of the PSO, or a
matching ForcedSampleCount value in the RASTERIZER_DESC.

SetSamplePositions also impacts Resolve*() anc Clear*() APIs called on
depth surfaces (does not impact stencil), as well as certain resource
state transition calls -- discussed later.

Calling SetSamplePositions(0,0,NULL) reverts state back to the default.

SetSamplePositions can be called on Graphics CommandLists only.

SetSamplePositions cannot be called in a Bundle. Bundles inherit sample
position state from the calling CommandList and leave it unchanged on
return.

---

### Clear RenderTarget

Sample positions are ignored when clearing an RT.

---

### Clear DepthStencil

Sample positions set at time of clearing of the *depth* portion of a
depth/stencil surface must be configured consistently with future
rendering to the cleared portion of the surface, and the contents of any
uncleared region become undefined if they contain content that was
produced with a different sample pattern.

Sample positions set at time of clearing of the *stencil* portion of a
depth/stencil are ignored.

---

### Draw using RenderTarget

Sample positions can be changed between rendering to an RT via separate
draws, whether for separate areas of the RT or even rendering to the
same pixels. At any given draw, the current sample locations dictate the
semantics, and whatever colors happen to be in the RT get used as the
colors for the current sample locations (even if the colors got there
from being rendered with different sample locations).

---

### Draw using DepthStencil

Draws to read/writing DepthStencil surface must be done with the current
sample positions matching the sample positions set at the previous clear
(for the region being rendered).

To use a different sample position state, the region to be rendered in
the surface must be Cleared first. The state of pixels outside the clear
region is unaffected.

*Implementations may store plane equations for depth as an optimization,
evaluating the plane equations to produce specific depth values when the
application issues a read. Only the rasterizer and Output Merger's
depth/stencil portion are required to be able to correctly sample at
programmed sample locations when reading/writing Depth. Any other read
or write of a depth buffer that has been rendered with programmed sample
positions may ignore the programmed locations and instead sample at the
standard/default sample positions.*

---

### Resolve RenderTarget

Sample positions are ignored when using the Resolve*() APIs on
RenderTargets. These APIs simply operate on stored color values.

---

### Resolve DepthStencil

Currently set sample positions at calls to Resolve*() on the depth
portion of depth/stencil surfaces must match the sample positions used
when previously writing to the area being resolved.

Currently set sample positions at calls to Resolve*() on the stencil
portion of depth/stencil surfaces are ignored. Just like RenderTarget
resolves, stencil resolves just operate on the stored values.

---

### Copy RenderTarget

Sample positions are ignored when using RenderTarget data as input to
Copy*() APIs, regardless of full or partial copy.

---

### Copy DepthStencil (Full Subresource)

Full subresource DepthStencil copies via Copy*() APIs require sample
positions to be set, matching content in the source. Not all
implementations need this, but the API simply requires this uniformly.
On some hardware the implementation details in the source surface (such
as stored plane equations for depth values) transfer to the destination.
So if the destination content is subsequently drawn to, the sample
positions originally used to generate the source content need to be used
with the destination surface. The API requires this on all hardware for
consistency even if it may only apply to some.

*Aside: Previously, driver support for copying MSAA DepthStencil
resources (including partial copies of a subregion of a single plane --
depth or stencil) was unreliable. From now on this will be required to
function correctly, backed by conformance tests.*

---

### Copy DepthStencil (Partial Subresource)

Partial subresource copies via Copy*() APIs of the *depth* portion of
DepthStencil require sample positions to be set, matching content in the
source, similar to full resource copies. If any content in affected
destination subresources is only partially covered by the copy, the
contents of the uncovered portion within those subresources becomes
undefined unless all of it was generated using the same sample positions
as the copy source.

Partial subresource copies via Copy* APIs of the *stencil* portion of
DepthStencil ignore the currently set sample positions and it doesn't
matter what sample positions were used to generate content for any other
areas of the destination buffer not covered by the copy -- those
contents remain valid.

---

### Shader SamplePos

The HLSL SamplePos intrinsic is not aware of programmable sample
positions and results returned to shaders calling this on a surface
rendered with programmable positions is undefined. Applications must
pass coordinates into their shader manually if needed. Similarly
evaluating attributes by sample index is undefined with programmable
sample positions.

---

### Transitioning out of DEPTH_READ or DEPTH_WRITE state

If a subresource in DEPTH_* state is transitioned to any other state,
including even COPY_SOURCE or RESOLVE_SOURCE, some implementations may
need to perform a decompress on the surface. Therefore, the same sample
positions used to put content into the source surface must be set on the
command list. Furthermore, any subsequent transitions of the surface,
with the same depth data remaining in it, must continue to be done with
the same sample positions set on the command list.

If an application wants to minimize the decompressed area (knowing only
a portion needs to be used) and/or preserve compression,
ResolveSubresourceRegion() can be called in DECOMPRESS mode with a rect
specified. This will decompress just the relevant area to a separate
resource, leaving the source intact *on some implementations*, though on
others implementations even the source area gets decompressed. The
separate explicitly decompressed resource (which may be a smaller size)
can then be transitioned to the desired state (such as
SHADER_RESOURCE).

---

### Transitioning out of RENDER_TARGET state

If a subresource in RENDER_TARGET state is transitioned to anything
other than COPY_SOURCE or RESOLVE_SOURCE, some implementations may
need to perform a decompress on the surface. This decompression is
agnostic to sample patterns, so the currently set sample positions don't
matter.

If an application wants to minimize the decompressed area (knowing only
a portion needs to be used) and/or preserve compression,
ResolveSubresourceRegion() can be called in DECOMPRESS mode with a rect
specified. This will decompress just the relevant area to a separate
resource leaving the source intact *on some implementations*, though on
others implementations even the source area gets decompressed. The
separate explicitly decompressed resource (which may be a smaller size)
can then be transitioned to the desired state (such as
SHADER_RESOURCE).

---

# ResolveSubresourceRegion

```C++
typedef enum D3D12_RESOLVE_MODE
{
    D3D12_RESOLVE_MODE_DECOMPRESS,
    D3D12_RESOLVE_MODE_MIN,
    D3D12_RESOLVE_MODE_MAX,
    D3D12_RESOLVE_MODE_AVERAGE
} D3D12_RESOLVE_MODE;

void ID3D12GraphicsCommandList1::ResolveSubresourceRegion(
    ID3D12Resource* pDstResource,
    UINT DstSubresource,
    UINT DstX, UINT DstY,
    ID3D12Resource* pSrcResource,
    UINT SrcSubresource,
    __in_opt D3D12_RECT* pSrcRect,
    DXGI_FORMAT Format
    D3D12_RESOLVE_MODE Mode
);
```

ResolveSubresourceRegion operates like the existing ResolveSubresource
API but adding a couple of features:

1. A portion of a subresource can be resolved, via source rect and
    destination top-left corner parameters

    - passing NULL for pSrcRect uses the entire source subresource
        size

2. The resolve operation can be specified -- MIN, MAX, AVERAGE (all
    following D3D arithmetic precision rules), and DECOMPRESS:

    - MIN or MAX can be used with any RenderTarget or DepthStencil
        format (depth or stencil plane)

    - AVERAGE can be used with any non-integer format -- UNORM, FLOAT,
        SNORM etc, including depth (not stencil)

    - DECOMPRESS can be used when the source and destination have the
        same sample count, as opposed to the other modes that require
        the destination to have a sample count of 1. DECOMPRESS mode
        resolves any compression data structures (if necessary). In this
        case the destination surface can optionally be the same as the
        source and in the RESOLVE_SOURCE state, as long as rect/region
        match as well, in which case the decompress is done in place.
        Even if the source and destination are different surfaces, on
        some implementations, even the source will get decompressed. If
        a decompress is requested on a subset of the subresource, the
        actual amount of the surface decompressed may be larger
        depending on the implementation. The same sample positions used
        to put content into the source surface must be set on the
        command list if DECOMPRESS is done on depth content.

Implementations can often perform Multisample resolve faster than an
application writing its own shader, but in the worst case an
implementation may need to simply use the same sort of shader an
application would use to perform the resolve.

The partial resolve can be useful, for instance, in multi-GPU scenarios
where the render area has been partitioned arbitrarily across GPUs for a
given frame and thus the relevant partial resolves can be done to
produce a final buffer.

---

# Experimental Feature: Mixed Rate Rasterization

An experimental feature will be exposed (available only in developer
mode) as follows, when a driver optionally supports it:

- Each simultaneously bound Depth and RT surface can have separate
    sample count subject only to a few constraints:

  - DS must have sample count \>= RTs

  - If there are any variations in sample counts, the quality level
        across the DS/RTs must all be one of:
    - D3D12_1_COVERAGE_SAMPLE = 0xfffffffd
    - D3D12_2_COVERAGE_SAMPLES = 0xfffffffc
    - D3D12_4_COVERAGE_SAMPLES = 0xfffffffb
    - D3D12_8_COVERAGE_SAMPLES = 0xfffffffa.
    - D3D12_16_COVERAGE_SAMPLES = 0xfffffff9

  - Otherwise if all sample counts are the same, the quality level
        for all bindings can be the same value from standard patterns or
        the usual IHV specific quality levels (old behavior) or any of
        the above list.

  - The number of coverage samples selected above must be greater
        than or equal to the number of samples in a surface

- In place of the SAMPLE_DESC member of the PSO data stream
    (containing only one sample count and quality level for all
    targets), D3D12_MIXED_SAMPLE_DESC can be used by applications for
    more expressiveness:

```C++
typedef struct D3D12_MIXED_SAMPLE_DESC_EXPERIMENTAL
{
    UINT CoverageSampleCount;
    INT Log2ShadingRate;
    UINT NumRenderTargets;
    UINT RTSampleCounts[8];
    UINT DepthStencilSampleCount;
} D3D12_MIXED_SAMPLE_DESC_EXPERIMENTAL;
```

CoverageSampleCount indicates the total number of samples tracked per
pixel and can be greater or equal to the sample counts of the RTs or
DepthStencil. Sample counts indicate how many color/depth slots there
are. If a given RT or depth will not be bound, its sample count can be
0. if no RTs are bound, either the array entries for RTSampleCounts can
have 0s or NumRenderTargets can be 0.

All RenderTarget and DepthStencil Views used at draw time with a PSO
that uses the MIXED_SAMPLE_DESC must have a quality value from the set
listed above that matches CoverageSampleCount in the PSO.

The exact semantics are to be defined for when the CoverageSampleCount
is greater than the sample count of the RTs or Depth, or if the RTs or
Depth have varying sample counts. Various IHVs have already implemented
solutions for these scenarios that can be exposed with this experimental
feature until the details are ironed out.

Log2ShadingRate must be 0, 1, 2, or 3 (for now). 2\^Log2ShadingRate
indicates the shading rate - maximum number of Pixel Shader shader
invocations per pixel per triangle, when the Pixel Shader requests
per-sample execution frequency. The actual number of invocations depends
on the number of CoverageSamples (or ForcedSampleCount samples if
greater) samples covered by a primitive. If the number of covered
samples exceeds the shading rate, covered samples locations are picked
in sample position list order ideally.

If sample frequency invocation is not requested by the Pixel Shader,
Log2ShadingRate is ignored and there is one Pixel Shader invocation per
covered pixel.

The reason this parameter is in log2 is to be open to the possibility
that a shading rate less than one -- like ½, ¼ etc. could be meaningful
in the future.

---

# Hardware Tiers

 | | |
---|---
Tier 0                            | No support for Programmable Sample Positions
Tier 1                            | <p>NumPixels parameter to SetSamplePositions can be 1.</p><p>1x and 16x sample counts do not support programamble positions.</p><p>ResolveSubresourceRegion supported.</p>
Tier 2                            | <p>NumPixels parameter to SetSamplePositions can be 1 or 4.</p><p>No more restriction on 1x and 16x sample counts -- all sample counts support programmable positions.</p>

Hardware support can be queried via the CheckFeatureSupport() API using
the information in the header snippet below:

```C++
typedef enum D3D12_FEATURE
{
    ...
    D3D12_FEATURE_D3D12_OPTIONS2 = 18
} D3D12_FEATURE;

typedef enum D3D12_PROGRAMMABLE_SAMPLE_POSITIONS_TIER
{
    D3D12_PROGRAMMABLE_SAMPLE_POSITIONS_TIER_0 = 0,
    D3D12_PROGRAMMABLE_SAMPLE_POSITIONS_TIER_1 = 1,
    D3D12_PROGRAMMABLE_SAMPLE_POSITIONS_TIER_2 = 2,
} D3D12_PROGRAMMABLE_SAMPLE_POSITIONS_TIER;

// D3D12_FEATURE_D3D12_OPTIONS2
typedef struct D3D12_FEATURE_DATA_D3D12_OPTIONS2
{
    ...
    _Out_ D3D12_PROGRAMMABLE_SAMPLE_POSITIONS_TIER ProgrammableSamplePositionsTier;
    ...
} D3D12_FEATURE_DATA_D3D12_OPTIONS2;
```

---

# DDI

---

## SetSamplePositions DDI

```C++
typedef struct D3D12DDI_SAMPLE_POSITION
{
    INT8 X;
    INT8 Y;
} D3D12DDI_SAMPLE_POSITION;

typedef VOID ( APIENTRY* PFND3D12DDI_SETSAMPLEPOSITIONS_0027 )(
    D3D12DDI_HCOMMANDLIST,
    UINT NumSamplesPerPixel,
    UINT NumPixels,
    __in_ecount(NumSamplesPerPixel*NumPixels) D3D12_SAMPLE_POSITION* pSamplePositions
);
```

The SetSamplePositions method above appears in
D3D12DDI_COMMANDLIST_FUNCS_3D_0026:

...

PFND3D12DDI_SETSAMPLEPOSITIONS_0026 pfnSetSamplePositions

...

## ResolveSubresourceRegion DDI

```C++
typedef enum D3D12DDI_RESOLVE_MODE
{
    D3D12DDI_RESOLVE_MODE_DECOMPRESS,
    D3D12DDI_RESOLVE_MODE_MIN,
    D3D12DDI_RESOLVE_MODE_MAX,
    D3D12DDI_RESOLVE_MODE_AVERAGE
} D3D12DDI_RESOLVE_MODE;

typedef VOID ( APIENTRY*
PFND3D12DDI_RESOURCERESOLVESUBRESOURCEREGION_0027 )(
    D3D12DDI_HCOMMANDLIST,
    D3D12DDI_HRESOURCE DstResource,
    UINT DstX,
    UINT DstY,
    D3D12DDI_HRESOURCE SrcResource,
    UINT SrcSubresource,
    __in_opt D3D12DI_RECT* pSrcRect,
    DXGI_FORMAT Format,
   D3D12DDI_RESOLVE_MODE ResolveMode
);
```

The ResolveSubresourceRegion method above appears in
D3D12DDI_COMMANDLIST_FUNCS_3D_0026:

```C++
...
PFND3D12DDI_SETSAMPLEPOSITIONS_0027 pfnSetSamplePositions
...
```

## Capability Support

```C++
typedef enum D3D12DDI_PROGRAMMABLE_SAMPLE_POSITIONS_TIER
{
    D3D12DDI_PROGRAMMABLE_SAMPLE_POSITIONS_TIER_0 = 0,
    D3D12DDI_PROGRAMMABLE_SAMPLE_POSITIONS_TIER_1 = 1,
    D3D12DDI_PROGRAMMABLE_SAMPLE_POSITIONS_TIER_2 = 2,
} D3D12DDI_PROGRAMMABLE_SAMPLE_POSITIONS_TIER;

// D3D12DDICAPS_TYPE_D3D12_OPTIONS
typedef struct D3D12DDI_D3D12_OPTIONS_DATA_0027
{
    ...
    D3D12DDI_PROGRAMMABLE_SAMPLE_POSITIONS_TIER ProgrammableSamplePositionsTier;
} D3D12DDI_D3D12_OPTIONS_DATA_0027;
```

---

# Validation

---

## Runtime

- Device Removed if SetSamplePositions or ResolveSubresourceRegion
    called on device without Tier1 programmable sample positions support

- ResolveSubresourceRegion follows similar validation path as
    ResolveSubresource - shared validation between debug layer and
    runtime. And add to this validation for the new parameters in
    ResolveSubresourceRegion of course, including validating the rect
    extents.

---

## Debug Layer

- SetSamplePositions parameters are valid and work on the hardware's
    programmable positions tier (runtime doesn't do any validation)

- ResolveSubresourceRegion: see runtime above for most validation.
    Debug layer only validation: Validate resource states for source and
    dest are resolve_source/dest (or both resolve_source when a
    decompress is being done on same source as dest). Other than the new
    validation, this generally follows the flow of the debug layer
    validation code for ResolveSubresource.

- Larger task: Debug layer needs to track per subresource whether a
    programmable pattern has been used with it based on the rules
    described in the spec, flagging invalid mixing of sample patterns

---

# Testing

---

## Functional Tests

- Test runtime behavior for SetSamplePositions and
    ResolveSubresourceRegion depending on what driver reports
    Programmable Sample Positions tier to be

- Debug layer testing: Look for appropriate error messages on invalid
    paramters

- Advanced debug layer testing: Check that the debug layer correctly
    tracks the sample pattern used with any given subresource by
    printing an error if any attempt to mix sample patterns is done,
    including across command lists

---

## Conformance Tests

---

### Initial Bringup Test

- Check for Tier 1 support

- SetSamplePositions with NumPixels = 1 and NumSamplesPerPixel = 4,
    and sample positions:

  - (-6,-4),(-2,-3),(1,5),(0,7)

- Clear a 4x MSAA RT and DS, 2 pixels wide, 2 high

  - Depth cleared to 0.5

- Make viewport / scissor cover full RT

- Set depth test to be less_than, rasterizer cull mode none, blending
    disabled

- Render a triangle that covers all 4 pixels but should fail the depth
    test (so the color of this triangle does not show up in the RT)

  - Vertex positions (-1,1,0.8,1), (3,1,0.8,1),(-1,-3,0.8,1) should
        do it

- Render a triangle that covers two samples in the top left pixel of
    the RT with a unique color (and should pass depth)

  - Vertex positions (-1,1,0.4,1),(0,1,0.4,1),(-1,0,0.4,1) should do
        it

- Render a triangle that covers two samples, one overlapping the
    previous, and should pass depth (even for the overlap with the
    previous), with another unique color.

  - Vertex positions (-0.75,1,0.2,1),(0,1,0.2,1),(-0.4375,0,0.2,1)
        should do it

- Transition the DSV and RTV both to SRVs

- In a compute shader, read the contents of the DSV and RTV (that are
    SRVs) and write them out to a UAV to do a golden image compare

- Transition the DSV and RTV both to RESOLVE_SOURCE state

- For the DSV, do a resolve with resolve mode MIN, with a subrect
    covering only the left top and bottom pixels, to a 1x2 pixel dest
    (sample count of 1). Do a golden image compare.

- For the RTV, do a resolve with resolve mode AVERAGE, with a subrect
    covering only the top left and right pixels, to a 2x1 pixel dest
    (sample count of 1). Do a golden image compare.

- Time permitting, in the same command list that does all of the
    above, change the sample positions to a pattern and repeat the rest
    of the test (with appropriately modified geometry rendering). This
    verifies the driver handles sample position changes.

  - Alternate sample pattern: (6,-6),(-5,-2),(1,2),(-3,4)

  - Rendering covers bottom right pixel

    - Positions for first triangle: same as first test case

    - Positions for second triangle (covering 2 samples in bottom
            right pixel):

      - (0.5,0,0.4,1),(0.5,-1,0.4,1),(0,-0.5,0.4,1)

    - Positions for third triangle (covering 2 samples, one
            overlapping previous):

      - (0,-0.5,0.2,1),(1,-0.5,0.2,1),(0.5,-1,0.2,1)

---

### SetSamplePositions Tier 2 test

- Check for Tier 2 support

- SetSamplePositions with NumPixels = 4 and NumSamplesPerPixel = 2,
    and different sample positions for each of the 2x2 (4) pixels

- Use a 4 pixel x 4 pixel RT/DS to be able to verify the 2x2 pixel
    sample pattern gets repeated

- Follow a similar pattern to previous test (use MAX for the DSV
    instead of MIN for more coverage). For the second round of
    rendering, can reuse the second round from the first test that only
    used NumPixels = 1, just to verify that changing the positions
    including changing NumPixels worked mid command list.

---

### Copy Test

- Render some content into an RTV and DSV with programmed sample
    positions

- Do both a full resource copy as well as partial resource copies and
    make sure the data in the destination is correct. For cases where
    the spec says the sample positions must match the rendered content
    at the time of copy, make sure that is the case, and if the spec
    says sample positions are not needed, the test should set the sample
    positions to some different pattern at the time of copy to verify
    that the sample positions don't affect the copy.

---

### Decompress Test

- Variation of the Copy Test

- Render some content into an RTV and DSV with programmed sample
    positions

- Perform a decompress of a portion of the surface to the same surface
    as a destination (with correct sample positions set where
    applicable - depth)

- Transition the surface to SRV, sample positions set to some
    different pattern for depth since they shouldn't get used on data
    that has been decompressed already)

- Read out data to a UAV via compute shader

- Repeat except with the destination of the decompress being a
    different surface.

---

# Change Log

10/28/2016 -- v0.2, Added ResolveSubresourceRegion API which allows
partial buffer MSAA resolves as well as supporting a small choice of
operations -- MIN, MAX, AVERAGE.

11/29/2016 -- v0.3

- fleshed out Sample Position Operational Semantics

- fleshed out ResolveSubresourceRegion behavior, adding a DECOMPRESS
    option for a resolve to a same sample count destination only doing a
    decompress, applicable to depth buffers only.

- added DDIs

- added beginnings of an experimental API for further configurability
    such as varying sample counts across bound RTs, as well as
    separating sample storage count from rasterizer coverage amount

  - DDIs to be added soon

12/7/2016 -- v0.4

- Clarified that when doing a decompress resolve to a separate
    surface, on some implementations even the source surface will get
    decompressed

3/20/2017 -- v0.5

- For the Mixed Rate Rasterization experimental feature, fixed
    Log2ShadingRate valid values to be 0,1,2,3 (as opposed to 1,2,3,4).

- Added restriction for Tier 1: does not support programmable
    positions for 1x and 16x patterns.
