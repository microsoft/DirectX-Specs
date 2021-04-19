# HLSL Derivative Operations in Compute, Mesh and Amplification Shaders

v1.00 2021-04-20

Shader Model 6.6 introduces
support for quad-based
derivative operations to
compute and optionally mesh and amplification shaders.

Previously, these operations were unavailable
 in these shader stages
because they require computations on
2x2 quads of adjacent values.
 Shaders without this explicit structure
 can now use these operations.

---

# Contents

- [Thread Groups and Quads](#thread-groups-and-quads)
  - [1D Quads](#1D-quads)
  - [2D Quads](#2D-quads)
- [Added Functions](#added-functions)
  - [Derivative Functions](#derivative-functions)
  - [Texture Sample Methods](#texture-sample-methods)
  - [Quad Read Functions](#quad-read-functions)
- [Device Capability](#device-capability)
- [Issues](#issues)

---

# Thread Groups and Quads
<!--issue 1 -->

Because they lack render targets,
compute, mesh and amplification shaders
don't have natural quads as pixel shaders do.
Instead, their quads are determined by the dimensions
of their `numthreads` attribute.

Derivative operations use values from neighboring threads
in a 2x2 quad (or grid) of threads
operating in lock-step.
In this document,
 each thread within a quad is referred to as a lane.
In compute, mesh and amplification shaders,
the lanes that make up the 2x2 quad depends on `numthreads`.
Where `numthreads` has an X value divisible by 4
and Y and Z are both 1,
the quad layouts are determined according to 1D quad rules.
Where `numthreads` X and Y values are divisible by 2,
the quad layouts are determined according to 2D quad rules.
Using derivative operations in
any `numthreads` configuration not matching either of these
is invalid and will produce an error.

For both layouts, previously-established associations
between quads and lane indices remain:

- quadID = WaveGetLaneIndex() / 4;
- quadIndex = WaveGetLaneIndex() % 4;

Note that quadID is meaningless for most purposes
except to enforce that all lanes with the same quadID value
must share the same quad.
The quadIndex follows a Z-ordering beginning in
the upper left, proceeding right and then starting over on the next row down:

|quadIndex Values|
|:-----------:|
|(0) (1)<br>(2) (3)|

If not all lanes of a quad are active,
such as via non-uniform flow control
or work group size,
the derivatives used and returned
by these operations are undefined.

## 1D Quads

Where only the X dimension is greater than 1,
the 2x2 quad is based on the group index
as provided by the `SV_GroupIndex` parameter.

- X position in quad from left = `SV_GroupIndex & 1`
- Y position in quad from top = `(SV_GroupIndex & 2) >> 1`

The result is that lanes in the group
form a sequence of serialized quads.
Every four sequential lanes form an individual quad.
The first and second lanes in the foursome
form the upper left and upper right respectively.
The third and fourth lanes
form the lower left and lower right respectively.
The lane after the fourth, if present represents
the upper left of the next quad.
This is sometimes called Z-order.

To provide a deterministic mapping between SV_GroupIndex
and the lanes within a quad,
1D quad ordering requires that threads are assigned lane indices
in the same order within the quad as specified by the SV_GroupIndex parameter.
Such that:

For 1D quads: SV_GroupThreadID.x % 4 == SV_GroupIndex % 4 == WaveGetLaneIndex() % 4

For example,
a thread group defined by `[numthreads (32, 1, 1)]`
might contain a single wave containing 32 lanes that make up 8 quads.
The layout for the first quad would be as follows where (##)
represents the group index in decimal:

|Quad 0|
|:-----------:|
|(00) (01)<br>(02) (03)|

And a later quad would be:

|**Quad _n_**|
|:-----------:|
|(16) (17)<br>(18) (19)|

## 2D Quads

Where the X and Y dimensions are divisible by 2,
the 2x2 quad is based on the x and y components
of group thread ID
as provided by the `SV_GroupThreadID` parameter.

- X position in quad from left = `SV_GroupThreadID.x & 1`
- Y position in quad from top = `SV_GroupThreadID.y & 1`

As a result, for every even x and y value within the thread group,
a quad is made up of the values (x,y) , (x+1,y), (x, y+1), (x+1, y+1).
There is no defined assignment of any quad within any wave
and no relation between the values of SV_GroupIndex and
the return value of WaveGetLaneIndex() should be assumed.

While existing compute Quad* operations required
the same association with lane indices,
no mapping of quad lanes to SV_GroupThreadID was required.
This new mapping is not required for pre 6.6 shader models.


For example,
a thread group defined by `[numthreads (8,4,1)]`
might contain a single wave containing 32 lanes that make up 8 quads.
The layout for the first quad would be as follows where (#,#)
represents the corresponding(GroupThreadID.x, GroupThreadID.y) values:

|Quad 0|
|:-----------:|
|(0,0) (1,0)<br>(0,1) (1,1)|

|**Quad _n_**|
|:-----------:|
|(6,2) (7,2)<br>(6,3) (7,3)|


# Added Functions

The functions added operate exactly
 as their existing counterparts
 with the exception of using the local
 quads as specified above.

## Derivative Functions

These functions calculate the
derivative in the x or y direction
using coarse or fine calculations.

These functions take a varying
 `value` of type `T`.
 The return value type must also be `T`.

```C++
T ddx(in T value)
T ddx_coarse(in T value)
T ddy(in T value)
T ddy_coarse(in T value)
T ddx_fine(in T value)
T ddy_fine(in T value)
```

## Texture Sample Methods

Having the ability to calculate the derivatives as above
also allows the calculation of level of detail(LOD) values
and also enables the standard sampling operations
that depend on LOD calculations.
Previously, only sample operations that didn't
 require derivative calculations were available.

Return type `R` is dependent on the texture content type.
`F` and `I` are float and integer values whose dimensions
 depend on the dimensions of the texture type.

```C++
float TexObject::CalculateLevelOfDetail( in SamplerState sampler_state, in F pos )
float TexObject::CalculateLevelOfDetailUnclamped( in SamplerState sampler_state, in F pos )
R TexObject::Sample( in SamplerState sampler_state, in F location, in [I Offset])
R TexObject::SampleBias( in SamplerState sampler_state, in F location, float Bias, [I Offset])
float TexObject::SampleCmp( in SamplerComparisonState S, F location, float compare_value, [int Offset])
```

# Quad Read Functions
<!-- Issue 2 -->

These functions enable the reading of
varying values from other lanes of the current quad
using explicit indices (`QuadReadLaneAt`)
 or from a position relative to the current lane.
Unlike other entries here,
these must be supported on Shader Model 6.0.

These functions take a varying
 `value` of type `T`.
 The return value type must also be `T`.

```C++
T QuadReadLaneAt( in T value, uint index)
T QuadReadAcrossDiagonal( in T value)
T QuadReadAcrossX( in T value)
T QuadReadAcrossY( in T value)
```

---

# Device Capability
<!-- Issue 3 -->

Derivative and derivative-dependent texture sample operations must be supported
in compute shaders
on devices that support `D3D_SHADER_MODEL_6_6`.

Derivative and derivative-dependent texture sample operations must be supported
in amplification and mesh shaders
on devices that support `D3D_SHADER_MODEL_6_6`
and have the `DerivativesInMeshAndAmplificationShadersSupported` capability.

The Quad Read Functions must be supported
 on devices that support `D3D_SHADER_MODEL_6_0`
 and report support for the `WaveOps` capability.

# Capability Queries

Applications can query the availability
of the texture sample operations listed here
in mesh and amplification shaders
 using `ID3D12Device::CheckFeatureSupport()`
passing `D3D12_FEATURE_D3D12_OPTIONS9`
as the `Feature` parameter
and retrieving the `pFeatureSupportData` parameter
 as a struct of type `D3D12_FEATURE_DATA_D3D12_OPTIONS9`.
The relevant part of this struct is defined below.

```C++
typedef enum D3D12_FEATURE {
    ...
    D3D12_FEATURE_D3D12_OPTIONS9
} D3D12_FEATURE;

typedef struct D3D12_FEATURE_DATA_D3D12_OPTIONS9 {
    ...
    BOOL DerivativesInMeshAndAmplificationShadersSupported;
} D3D12_FEATURE_DATA_D3D12_OPTIONS9;

```

`DerivativesInMeshAndAmplificationShadersSupported` is a boolean that specifies
whether the [Texture Sample Methods](#texture-sample-methods)
are supported in the mesh and amplification shader stages.

---
# Issues

1. What restrictions should be placed on work group size?
   - RESOLVED: The restrictions are principally on the wave size,
   which are not entirely under the control of the user.
   Mention is made of how work group size could impact the
   availability of active lanes for each quad, but details are left out.

2. Should QuadRead* functions be included?
   - RESOLVED: Yes. They were already available in these shader stages,
   but the definition of the quads they depend on wasn't well specified.

3. What device capabilities are required?
   - RESOLVED: Any device that supports Shader Model 6.6
should be able to support derivative and sample operations in compute shaders and
quad operations in all shaders.
Derivative and sample operations in amplification and mesh shaders
are supported if the appropriate capability bit is true.
Quad Read functions should be supported on Shader Model 6.0

4. How should the quads be ordered?
   - RESOLVED: Group Index.
This has advantages and drawbacks.
It introduces a restriction that the thread group
must be traversed in row-order.
Without it, there is no way to identify where the current
quad is in the group.

---
# Change Log

Version|Date|Description
-|-|-
1.00|20 Apr 2021|Minor Edits for Publication
0.11|25 Jan 2021|Constrain linear quad mode to 1D NumThreads. Introduce new 2D quad mapping
0.10|11 Jan 2021|Switch to OPTIONS9
0.9|01 Dec 2020|Revert to basing quads on group index
0.8|24 Apr 2020|Include ddx/ddy in the cap bit and rename accordingly.
0.7|13 Apr 2020|Use Wave Index to define the makeup of the quads
0.6|09 Apr 2020|Add Capability bit for Amplification/Mesh Shaders
0.5|16 Mar 2020|Clarify ascii diagram
0.4|05 Mar 2020|Respond to feedback. Spelling and caps, validation error
0.3|02 Mar 2020|Add ascii art for quads
0.2|21 Feb 2020|Simplify function descriptions. Expand on quad description.
0.1|19 Feb 2020|Initial draft
