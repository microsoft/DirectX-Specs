<h1>HLSL Shader Model 6.5</h1>

v1.0 2019-10-15

# Contents

- [Introduction](#introduction)
  - [DXR 1.1](#dxr-11)
  - [Sampler Feedback](#sampler-feedback)
  - [Mesh and Amplification Shaders](#mesh-and-amplification-shaders)
- [New Wave Intrinsics](#new-wave-intrinsics)
  - [Overview](#overview)
    - [WaveMatch() function](#wavematch-function)
    - [WaveMatch() Illustration](#wavematch-illustration)
    - [WaveMultiPrefix*() Functions](#wavemultiprefix-functions)
    - [WaveMultiPrefix*() Illustration](#wavemultiprefix-illustration)
    - [Example usage](#example-usage)

---

# Introduction

This doc covers the new shader model 6.5 for Vibranium release (20H1).
With the exception of the WaveMatch and WaveMultiPrefix intrinsics,
the new features are defined in separate documents.

## DXR 1.1

DirectX Raytracing (DXR) Tier 1.1 adds:

- [`uint GeometryIndex()`](Raytracing.md#geometryindex):
a new intrinsic for retrieving the generated geometry index
to the existing raytracing shader types with intersection information
(intersection, any hit, and closest hit).
- [`RayQuery`](Raytracing.md#rayquery):
a new object, available to every shader stage,
that enables inline access to raytracing operations.

Feature support is indicated by the
[Raytracing Tier](Raytracing.md#d3d12_raytracing_tier).

See the
[DirectX Raytracing (DXR) Functional spec](Raytracing.md)
for details.

## Sampler Feedback

Sampler Feedback is an optional feature available in shader model 6.5
that adds 2 new Texture resource types:
`FeedbackTexture2D<type>` and `FeedbackTexture2DArray<type>` to HLSL.
These resource types have a template argument
specifying the format of the feedback map.

See the
[HLSL section of the Sampler Feedback spec](SamplerFeedback.md#hlsl-constructs-for-writing-to-feedback-maps)
for details.

## Mesh and Amplification Shaders

Two new shader types are added to HLSL for the new mesh shader  graphics pipeline.
These are Mesh Shaders `ms_6_5` and Amplification Shaders `as_6_5`.

See the
[Mesh Shader spec](MeshShader.md)
for details.

# New Wave Intrinsics

`WaveMatch()`, and a number of `WaveMultiPrefix*()` intrinsics,
are available starting with shader model 6.5,
when the optional Wave Intrinsics feature is supported.

All shader stages, except for Raytracing shaders,
support wave intrinsics as of shader model 6.5.

## Overview

Shader model 6 introduces a set of data parallel wave intrinsics, which
implement fundamental computational primitives such as voting,
reductions and prefix operations among the lanes in a wave. These
intrinsics are valuable tools for many compute algorithms, exploiting
efficiency of SIMD execution model of modern GPUs.

Shader model 6.5 adds two new classes of wave intrinsics.
They are useful for many data parallel algorithms involving
deduplication of data streams,
coalescing of memory operations,
and implementing efficient concurrent data structures
such as hash tables and maps.
In particular, these new intrinsics are important building blocks
texture-space shading,
and provide support for index buffer deduplication in the context of the
meshlet programming model.

We believe these data parallel primitives will grow in importance as
applications embrace more compute-centric algorithms.

As with the other wave intrinsics,
when executed in pixel shaders,
these intrinsics operate as if helper lanes are not active
when executing the wave intrinsic.
This means that the value returned by a wave intrinsic
is only defined on active, non-helper lanes.
Similarly, the inputs to a wave intrinsic on helper lanes
do not impact the result returned from that wave intrinsic
on active, non-helper lanes.

## WaveMatch() Function

### `uint4 WaveMatch( <type> val )`

The `WaveMatch()` intrinsic compares the value of the expression in the current lane
to its value in all other active lanes in the current wave and returns a
bitmask representing the set of lanes matching current lane's value.

`val` can be any expression which evaluates to any of the currently
supported primitive data types (e.g. float4, uint2, etc.).

The return value is a uint4 representing a 128b bit mask which
identifies lanes in the current wave matching current lane's value of `val`.
Bits in the mask corresponding to inactive lanes, or at positions
beyond current implementation's wave width, will contribute 0's.
Bits in the mask corresponding to active lanes
which match the value of `val` in the current lane will be set to 1.
The bit in the mask corresponding to the current lane will always be set to 1.

In pixel shaders, bits corresponding to helper lanes are set to 0,
and on helper lanes, the resulting bitmask is undefined.

## WaveMatch() Illustration

The following table demonstrates the action of
`WaveMatch()` assuming an implementation with a wave width of 8 lanes.
Lanes 0 and 4 are inactive or helper lanes, indicated by "`-`".
Bits in the mask beyond bit position 7
are guaranteed to be cleared (effective mask width is 8).

```C++
uint4 mask = WaveMatch(input);
```

|laneID   | 7     | 6     | 5     | 4 | 3     | 2     | 1     | 0
|:-       |-      |-      |-      |-  |-      |-      |-      |-
| input   | 15    | -1    | -1    | - | 123   | 0     | 123   | -
| mask.x  | 0x80  | 0x60  | 0x60  | - | 0x0a  | 0x04  | 0x0a  | -

## WaveMultiPrefix*() Functions

`WaveMultiPrefix*()` is a set of functions which implement
*multi-prefix* operations among the set of active lanes in the current wave.

A multi-prefix operation comprises a set of prefix operations, executed
in parallel within subsets of lanes identified with the provided bitmasks.
These bitmasks represent partitioning of the set of active
lanes in the current wave into N groups
(where N is the number of unique masks across all lanes in the wave).
N prefix operations are then performed each within its corresponding group.
The groups are assumed to be non-intersecting
(that is, a given lane can be a member of one and only one group),
and bitmasks in all lanes belonging to the same group are required to be the same after excluding inactive/helper lane in the bitmask.

The following operations evaluates multiple prefix operations within groups of threads identified by `mask`:

*`<type>`* can be any of the currently supported
integer or floating point primitive types.

*`<int_type>`* can be any of the currently supported
integer primitive types.

*`val`* is the value to perform the prefix operation on.

*`mask`* is a 128b bitmask,
representing the partitioning of the current wave into groups of lanes,
as described above.
Bits in the masks at positions beyond current implementation's wave width,
or corresponding to inactive or helper lanes, are ignored (assumed to be 0).
If the masks do not form non-intersecting subsets of lanes,
then the values returned by this intrinsic are undefined.
Bitmasks for all lanes belonging to the same group are required to match,
otherwise the results returned by this intrinsic are undefined.

Returned *`<type>`* is the same type as the input type for `val`.
The result of the prefix operation is computed with
values from prior lanes in the same group only;
it does not include the value from the current lane.
A postfix value would be computed by
applying the corresponding operator between
the result of the prefix operation
and the value passed in to the prefix operation.

### `<type> WaveMultiPrefixSum( <type> val, uint4 mask )`

val0 + val1 + val2 ...

### `<type> WaveMultiPrefixProduct( <type> val, uint4 mask )`

val0 \* val1 \* val2 ...

### `uint WaveMultiPrefixCountBits( bool val, uint4 mask )`

(val0 ? 1 : 0) + (val1 ? 1 : 0) + (val2 ? 1 : 0) ...

### `<int_type> WaveMultiPrefixAnd( <int_type> val, uint4 mask )`

val0 & val1 & val2 ...

### `<int_type> WaveMultiPrefixOr( <int_type> val, uint4 mask )`

val0 \| val1 \| val2 ...

### `<int_type> WaveMultiPrefixXor( <int_type> val, uint4 mask )`

val0 ^ val1 ^ val2 ...

## WaveMultiPrefixSum() Illustration

The following table demonstrates the action of
`WaveMultiPrefixSum()`, assuming an implementation with wave width of 8 lanes.
Lane 1 is an inactive or helper lane, and is indicated by "`-`".

```C++
output = WaveMultiPrefixSum(value, mask);
```

|laneID   | 7     | 6     | 5     | 4     | 3     | 2     | 1 | 0
|:-       |-      |-      |-      |-      |-      |-      |-  |-
| mask.x  | 0xe0  | 0xe0  | 0xe0  | 0x14  | 0x09  | 0x14  | - | 0x0b
| value   | 5     | 4     | 1     | -2    | 3     | 0     | - | 6
| output  | 5     | 1     | 0     | 0     | 6     | 0     | - | 0

Note how subset with `mask.x == 0x0b` refers to lane 1,
which is either inactive or is a helper lane.
This doesn't affect the result since bits in the mask
corresponding to inactive or helper lanes are ignored
(lane 0's `mask.x` effectively becomes `0x09`, so there
is no intersecting subset of lanes).

## Example usage

`WaveMatch()` and `WaveMultiPrefix*()` intrinsics are designed to work together.
In particular, the masks returned by the `WaveMatch()` intrinsic can be used directly
as group masks in the `WaveMultiPrefix*()` set of intrinsics.

The following illustrates obtaining an equivalent result
to a `WaveMultiPrefixSum` operation using the
`WaveReadLaneFirst` and `WavePrefixSum` intrinsics.
However, using the new wave intrinsics provides more
optimization opportunities for hardware to take advantage of.

```C++
// Given:
int sum = 0, value = ...;
int expr = ...;  // Uniform subsets exist for this expr value

// The following:
uint4 mask = WaveMatch(expr);
sum = WaveMultiPrefixSum(value, mask);

// Is equivalent to writing a loop like this:
while (true) {
  if (WaveReadLaneFirst(expr) == expr) {
    sum = WavePrefixSum(value));
    break;
  }
}
```

The following example demonstrates how to coalesce atomic OR operations to a surface
with x,y coordinates computed dynamically per lane.

```C++
uint key = computeHash(x, y); // compute a key for matching

uint4 groupMask = WaveMatch( key );

// firstbithigh returns -1 when no bit set, otherwise < 32,
// so OR will add lane index offset without changing -1.
int4 highLanes = (int4)(firstbithigh(groupMask) | uint4(0, 0x20, 0x40, 0x60));
// The signed max should be the highest lane index in the group.
uint highLane = (uint)max(max(max(highLanes.x, highLanes.y), highLanes.z), highLanes.w);
bool leader = WaveGetLaneIndex() == highLane;

unsigned int result = WaveMultiPrefixBitOr( myValueToOr, groupMask );

if (leader)
    InterlockedOr( mem[key], result | myValueToOr );
```

First, WaveMatch() is used to identify sets of threads
which have the same x,y coordinates
(that is, will update the same location in memory).
Then, a single thread from each set is elected to issue a single atomic operation
to memory on behalf of all lanes in the set.
The `WaveMultiPrefixBitOr()` function is used to apply bitwise-OR
reduction within multiple sets of colliding lanes concurrently,
the results of which are then used in the elected threads to issue atomic operations to memory.
