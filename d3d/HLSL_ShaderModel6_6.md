<h1>HLSL Shader Model 6.6</h1>

v1.0 2021-04-20

# Contents

- [Introduction](#introduction)
  - [New Atomic Operations](#64-bit-and-float-atomics)
  - [Dynamic Resources](#dynamic-resource)
  - [IsHelperLane()](#is-helper-lane)
  - [Derivative Operations in Compute, Mesh and Amplification Shaders](#derivatives)
  - [Pack and Unpack Intrinsics](#pack-and-unpack)
  - [WaveSize](#wavesize)
  - [Raytracing Payload Access Qualifiers](#ray-payload)

---


<a id="introduction"></a>
# Introduction

This document covers the new Shader Model 6.6.  A brief summary of each new feature
is listed below along with links to detailed specifications.



<a id="64-bit-and-float-atomics"></a>
# New Atomic Operations

Shader Model 6.6 introduces 64-bit integer and limited bitwise floating-point atomic operations
by overloading the `Interlocked`* functions and methods used on group shared memory, raw buffer,
and typed (RWBuffer/RWTexture) resources.

See the [Shader Model 6.6. Atomic Operations](HLSL_SM_6_6_Int64_and_Float_Atomics.md) documenation for more details.



<a id="dynamic-resource"></a>
# Dynamic Resources

Shader Model 6.6 introduces the ability to create resources from descriptors by directly indexing into the 
CBV_SRV_UAV heap or the Sampler heap. No root signature descriptor table mapping is required for this resource
creation method, but new global root signature flags are used to indicate the use of each heap from the shader.

A short example is below.
```C++
Texture2D<float4> myTexture = ResourceDescriptorHeap[texIdx];
float4 result = myTexture.Sample(SamplerDescriptorHeap[sampIdx], coord);
```

See the [Shader Model 6.6 Dynamic Resources](SM_6_6_DynamicResources.md) documentation for more details.




<a id="is-helper-lane"></a>
# IsHelperLane()

IsHelperLane() is a new intrinsic introduced in Shader Model 6.6 that returns true if a given lane in a pixel shader is
a helper lane.  Helper lanes are nonvisible pixels that are executing due to gradient operations or discarded pixels.  
IsHelperLane() returns false for all visible pixels in a pixel shader and it returns false for all other shader stages.

IsHelperLane() is supported in previous shader models via a software fallback.

When using wave intrinsics in pixel shaders because helper lanes do not participate, you can end up with undefined results for certain
values in helper lanes.  This can lead to problems, like undefined screen-space derivatives or unintentional infinite loops (hangs), 
when depending on results from wave intrinsics.  In the past, we attempted to guard against this problem by disallowing potentially 
problematic operations from being dependent on the result of wave intrinsics.  However, this could be too strict, or even miss some dependencies.  
This guard has been changed into a warning but leaves the shader author without an explicit way to write safe code in that area of interaction.  
IsHelperLane provides a way for the shader to explicitly vary behavior on helper lanes to guard against potential problems, for instance by 
explicitly excluding helper lanes from entering a loop which depends on a wave intrinsic for its exit condition.

```cpp
bool IsHelperLane()
```



<a id="derivatives"></a>
# Derivative Operations in Compute, Mesh and Amplification Shaders

Shader Model 6.6 introduces support for quad-based derivative operations to
compute and optionally mesh and amplification shaders.  We define how threads are mapped to 2x2 quads in these stages and
specifically which operations are available.

See the [Derivative Operations in Compute, Mesh and Amplification Shaders](HLSL_SM_6_6_Derivatives.md) documenation for more details.




<a id="pack-and-unpack"></a>
# Pack and Unpack Intrinsics

A new set of intrinsics are being added to HLSL for processing of packed 8bit data such as colors. New packed datatype 
are also added to HLSL's front end to symbolize a vector of packed 8bit values. 

See the [Pack/Unpack Math Intrinsics](HLSL_SM_6_6_Pack_Unpack_Intrinisics.md) documenation for more details.




<a id="wavesize"></a>
# WaveSize

Shader Model 6.6 introduces a new option that allows the shader author to specify a wave size that the shader is compatible with.

See the [Wave Size](HLSL_SM_6_6_WaveSize.md) documenation for more details.



<a id="ray-payload"></a>
# Raytracing Payload Access Qualifiers

Shader models 6.6 adds payload access qualifiers (PAQs) to the ray payload structure. PAQs are annotations which describe the read and write semantics 
of a payload field, that is, which shader stages read or write a given field. The added semantic information can help implementations reduce register pressure
 and can avoid spilling of payload state to memory. This incentivizes the use of the narrowest-possible qualifiers for each payload field.

See the new [Payload Access Qualifiers](Raytracing.md#payload-access-qualifiers) section of the raytracing documentation for more details.


# Change Log

Version|Date|Description
-|-|-
1.00|20 Apr 2021|Minor Edits for Publication

