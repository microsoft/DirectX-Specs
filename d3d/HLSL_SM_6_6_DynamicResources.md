# HLSL Dynamic Resources

v1.00 2021-04-20

Shader Model 6.6 introduces the ability to create resources from descriptors
by directly indexing into the CBV_SRV_UAV heap or the Sampler heap.
No root signature descriptor table mapping is required for this resource creation method,
but new global root signature flags are used to indicate the use of each heap from the shader.

In HLSL, the feature is exposed as
two new builtin global indexable objects:
`ResourceDescriptorHeap` and `SamplerDescriptorHeap`.
Indexing each results in an internal handle object
that can be assigned to temporary resource or sampler objects,
without requiring resource binding locations
or mapping through root signature descriptor tables.

In HLSL, the CBV/SRV/UAV Descriptor Heap is referred to as the Resource Descriptor Heap.

Additional changes to existing handle patterns
are introduced in this shader model
to unify code paths and remove unnecessary metadata.

## Contents

- [HLSL Dynamic Resources](#hlsl-dynamic-resources)
  - [Contents](#contents)
  - [HLSL Changes](#hlsl-changes)
    - [ResourceDescriptorHeap and SamplerDescriptorHeap](#resourcedescriptorheap-and-samplerdescriptorheap)
  - [Root Signature Changes](#root-signature-changes)
    - [SetDescriptorHeaps and Set*RootSignature](#setdescriptorheaps-and-setrootsignature)
    - [Descriptor and Data Volatility](#descriptor-and-data-volatility)
  - [Device Capability](#device-capability)
    - [Shader Feature Requirement Flags](#shader-feature-requirement-flags)
  - [Change Log](#change-log)

## HLSL Changes

### ResourceDescriptorHeap and SamplerDescriptorHeap

In HLSL, two new builtin global indexable objects
allow you to set local resource and sampler objects by
directly indexing into the
CBV_SRV_UAV (Resource) descriptor heap or the Sampler descriptor heap.

```C++
<resource variable> = ResourceDescriptorHeap[uint index];
<sampler variable> = SamplerDescriptorHeap[uint index];
```

`ResourceDescriptorHeap[index]` must be used to assign a local or global
CBV, SRV, or UAV resource variable or function call argument.

`SamplerDescriptorHeap[index]` must be used to assign a local or global
SamplerState or SamplerComparisonState variable or function call argument.

This example demonstrates how resources of different types can come from the heaps:

```C++
Texture2D<float3> myTexture = ResourceDescriptorHeap[texIdx];
SamplerState samp = SamplerDescriptorHeap[sampIdx];
float3 color = myTexture.Sample(samp, coord);

Texture2D<float4> myShadowMap = ResourceDescriptorHeap[texIdx+1];
SamplerComparisonState compSamp = SamplerDescriptorHeap[sampIdx+1];
float shadow = myShadowMap.SampleCmp(compSamp, shadowCoord, cmpVal);
```

The object type returned by these indexing operations
cannot be declared, stored, or used directly in HLSL,
other than to assign a resource or sampler variable.

By default, indexing into the resource or sampler heap is considered uniform.
If the index is not uniform,
you must use the `NonUniformResourceIndex` intrinsic on the index.
If the index is not uniform and `NonUniformResourceIndex` is not used,
The result may be undefined.

Example:

```C++
RWByteAddressBuffer buf = ResourceDescriptorHeap[NonUniformResourceIndex(index)];
SamplerState samp = SamplerDescriptorHeap[NonUniformResourceIndex(index)];
```

Descriptors and their data looked up using
`ResourceDescriptorHeap` and `SamplerDescriptorHeap`
must be considered volatile.
See [Descriptor and Data Volatility](#descriptor-and-data-volatility).

## Root Signature Changes

While the exact mechanism of providing this direct heap indexing may vary,
the root signature is a good place to indicate to the driver
when the heap addresses must be made available to the shader.

Two new global root signature flags are introduced,
which are only allowed on a device supporting this feature.
See [Device Capability](#device-capability).
These new flags are not allowed on local root signatures
(D3D12_ROOT_SIGNATURE_FLAG_LOCAL_ROOT_SIGNATURE).

D3D12 Root Signature flags added are as follows:

```C++
typedef enum D3D12_ROOT_SIGNATURE_FLAGS
{
    ...

    D3D12_ROOT_SIGNATURE_FLAG_CBV_SRV_UAV_HEAP_DIRECTLY_INDEXED     = 0x400,
    D3D12_ROOT_SIGNATURE_FLAG_SAMPLER_HEAP_DIRECTLY_INDEXED         = 0x800,

} D3D12_ROOT_SIGNATURE_FLAGS;
```

Root signature flags as used in a root signature defined in HLSL:

```C++
RootFlags( CBV_SRV_UAV_HEAP_DIRECTLY_INDEXED | SAMPLER_HEAP_DIRECTLY_INDEXED )
```

The `CBV_SRV_UAV_HEAP_DIRECTLY_INDEXED` flag must be set
to allow shaders using `ResourceDescriptorHeap`
to assign CBV, SRV, or UAV objects.

The `SAMPLER_HEAP_DIRECTLY_INDEXED` flag must be set
to allow shaders using `SamplerDescriptorHeap`
to assign Sampler objects.

Shader to Root Signature validation
will fail if the shader creates resources from one of these heaps and
the corresponding flag is not set in the root signature.
This validation is run at shader compilation time
if a root signature is attached to the entry point.
It is also run in D3D12 during pipeline state creation
when a root signature is attached to the pipeline
for every shader that wasn't already validated
with a matching root signature.

### SetDescriptorHeaps and Set*RootSignature

The heaps indexed by `ResourceDescriptorHeap` and `SamplerDescriptorHeap` are
the CBV_SRV_UAV heap and the Sampler heap
set by the ID3D12GraphicsCommandList::SetDescriptorHeaps call.

There is a new ordering constraint between SetDescriptorHeaps and
SetGraphicsRootSignature or SetComputeRootSignature.
SetDescriptorHeaps must be called,
passing the corresponding heaps,
before a call to SetGraphicsRootSignature or SetComputeRootSignature
that uses either CBV_SRV_UAV_HEAP_DIRECTLY_INDEXED or SAMPLER_HEAP_DIRECTLY_INDEXED flags.
This is in order to make sure the correct heap pointers are available
when the root signature is set.
Additionally, SetDescriptorHeaps may not be called after
SetGraphicsRootSignature or SetComputeRootSignature
with different heap pointers before a Draw or Dispatch.

### Descriptor and Data Volatility

Root Signature version 1.1 introduced the ability to define the volatility of descriptors
and data in buffers pointed to by descriptors,
to allow certain driver optimizations to take place under the right conditions.
Additionally, version 1.1 changed the default assumption to match common usage at the time,
assuming descriptors are static, and data is static for SRV/CBV over the course of execution.

In Shader Model 6.6,
the descriptor and data for a resource or sampler
created from `ResourceDescriptorHeap` or `SamplerDescriptorHeap`
must both be considered **volatile** -
equivalent to `DESCRIPTORS_VOLATILE | DATA_VOLATILE`
in the root signature descriptor range flags.

This is for the following reasons:

- An expected use case for heap indexed resources (Dynamic Resources) is with dynamic indexing.
- Dynamically indexed resource descriptors are unlikely to benefit from these optimizations.
- A suitable design for indicating static state for heap indexed resources has not yet been determined.
- Resources bound through root signatures are still usable in combination with heap indexed resources,
  keeping optimization opportunities there.

As is specified elsewhere, `DESCRIPTORS_VOLATILE`
does not mean that the descriptor can be changed
during execution (draw/dispatch).
In addition, the volatility of read-only SRVs and CBVs with `DATA_VOLATILE` is also limited,
since it requires a resource transition
between modification and use in an SRV or CBV.

## Device Capability

`ResourceDescriptorHeap`/`SamplerDescriptorHeap` (DXIL: `dx.op.createHandleFromHeap`)
must be supported on devices that support
both `D3D12_RESOURCE_BINDING_TIER_3` and `D3D_SHADER_MODEL_6_6`.
Then, on a given PSO, the global root signature flags indicate
which heaps are potentially accessed by shaders
by using this intrinsic.

`dx.op.createHandleFromBinding` and `dx.op.annotateHandle`
are a core part of DXIL 1.6 and Shader Model 6.6, and
must be supported on devices that support `D3D_SHADER_MODEL_6_6`.

### Shader Feature Requirement Flags

The compiled shader object will have the following feature requirement flags
corresponding to the indexing of each heap,
set in the blob part `DFCC_FeatureInfo` (FourCC `SFI0`).

```c++
#define D3D_SHADER_REQUIRES_RESOURCE_DESCRIPTOR_HEAP_INDEXING  0x02000000
#define D3D_SHADER_REQUIRES_SAMPLER_DESCRIPTOR_HEAP_INDEXING   0x04000000
```

## Change Log

Version|Date|Description
-|-|-
1.00|31 Jul 2024|Corrected malfunctioning sample, added a cmp example
1.00|20 Apr 2021|Minor Edits for Publication
0.7|2020-10-07|Added Descriptor and Data Volatility
0.6|2020-09-25|Note for local root signature, update feature flags
0.5|2020-07-22|Move DXIL details to DXIL 1.6 spec.
0.4|2020-05-11|Update ResourceProperties, add align and type info.
0.3|2020-04-14|Remove SampleCountPow2, no resources in function arguments.
0.2|2020-03-09|Split by heap, index global objects, clarify NonUniform, update issues
0.1|2020-02-21|First Draft
