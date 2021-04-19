# HLSL Shader Model 6.6 Atomic Operations

v1.00 2021-04-20

Shader Model 6.6 introduces 64-bit integer
and limited bitwise floating-point atomic operations
by overloading the `Interlocked`* functions and methods
used on group shared memory, raw buffer,
and typed (RWBuffer/RWTexture) resources.

Previously, atomic operations have been restricted to 32-bit integer values
 which lack the flexibility, range, and precision of 64-bit integer values.
This feature adds to HLSL the ability to perform atomic addition operations,
atomically calculate and store minimum and maximum values,
bitwise AND, OR, and XOR operations
and perform atomic value exchanges
on 64-bit integer `RWByteAddressBuffer` and `RWStructuredBuffer` resources
declared by root descriptors inlined in the root signature.
These same 64-bit integer operations can optionally
be supported on group group shared memory and typed resources
and for resources in descriptor heaps.

This document also describes support for
exchange operations and bitwise compare exchange
operations on floating-point values.

Atomic operations allow the multiple threads involved in graphics processing
 to communicate using group shared memory by providing mechanisms
 that allow the user to perform useful operations without risk
 of other threads intervening during the reads and writes involved
 in those operations.
 HLSL support for atomic operations through the various `Interlocked`*
 functions has enabled developers to use this inter-thread communications
 to render more realistic scenes with greater performance in a variety of ways.

By adding support for 64-bit integer and bitwise floating-point values to these operations,
original new rendering methods and optimizations become possible.

---

# Contents

- [New Atomic Functions](#new-atomic-functions)
  - [InterlockedAdd](#interlockedadd)
  - [InterlockedAnd](#interlockedand)
  - [InterlockedOr](#interlockedor)
  - [InterlockedXor](#interlockedxor)
  - [InterlockedMin](#interlockedmin)
  - [InterlockedMax](#interlockedmax)
  - [InterlockedExchange](#interlockedexchange)
  - [InterlockedCompareStore](#interlockedcomparestore)
  - [InterlockedCompareStoreFloatBitwise](#interlockedcomparestorefloatbitwise)
  - [InterlockedCompareExchange](#interlockedcompareexchange)
  - [InterlockedCompareExchangeFloatBitwise](#interlockedcompareexchangefloatbitwise)
  - [Examples](#examples)
- [Device Capability](#device-capability)
  - [Integer 64-bit Capabilities](#integer-64-bit-capabilities)
  - [Float Capabilities](#float-capabilities)
- [Capability Queries](#capability-queries)
- [Issues](#issues)
- [Change Log](#change-log)

---

# New Atomic Function Prototypes

This feature introduces overloaded versions of existing `Interlocked*` functions
that take 64-bit integer and floating-point parameters,
but otherwise function exactly as the originals.
This feature similarly extends the `Interlocked*` member methods
of RWByteAddressBuffer to include overloaded versions
that take 64-bit integer parameters
but otherwise function as the existing methods.
Unlike the other intrinsics, RWByteAddressBuffer methods include
a suffix to indicate their type
since the resource includes no type information.

These functions operate exclusively on scalar values.
No arrays, structs, or vectors will be processed atomically.
Implicit truncation of vectors will proceed according to
normal rules meaning a vector type passed to a scalar parameter may perform the
atomic operation on its first element.
Scalar member elements of aggregate types may be passed to atomic
operations by referencing the member using the usual appropriate
indices and dot operators which will perform the atomic
operation on that scalar element only.
Such referencing of individual members of aggregates
is how resource buffers make use of these operations.

In the functions below, the `dest` parameter serves
as both input and output of the atomic operation.
Operations are performed on the `dest` and `value` parameters
and the result is copied to the memory location referenced by `dest`.
`dest` must be writable or compilation will fail.
If `dest` is a group shared memory variable, the result is copied to
that group shared memory register.
If `dest` is from a resource, the result is copied to
that resource location.

The `dest` parameter can
be of one of three kinds of memory:
local group shared memory, structured buffers or typed resources.
A group shared memory input is derived from a local variable
with the `groupshared` keyword.
A structured buffer input is derived from a global structured buffer.
A typed resource input is an indexed reference to a global typed resource
which includes typed buffers and textures.
Regardless of memory type,
the type of the `dest` input must match that of the `value` parameter.
The function overloads specified below use

The type of the `dest` parameter indicates
the memory type the function overload accepts.
`ShmemType` indicates a `groupshared` memory overload.
`SbufType` indicates a `RWStructuredBuffer` overload.
`TresType` indicates a typed resource overload
such as `RWTexture2D` or `RWBuffer`.

Typed resources used in these functions
must have format(`DXGI_FORMAT` value)
appropriate to the type of the overload.
Typed resources used in floating-point operations
must be declared with HLSL type `float`
and have format `R32_FLOAT`.
Typed resources used in 64-bit integer operations
must be declared with HLSL type `int64_t` or `uint64_t`
and have format `R32G32_UINT`.
If a typed resource with an incompatible format
is used as the `dest` in an atomic operation,
compilation will fail.

All the RWByteAddressBuffer methods take
 a unsigned integer `dest_offset` parameter
that represents an offset into the resource buffer.
The operation is performed on the `value` parameter
and the resource location indexed by `dest_offset`.
The result is stored in the resource location indexed by `dest`.

Shader Model 6.6 requires support for 64-bit integer type
atomic operations on 64-bit integer
`RWByteAddressBuffer` and `RWStructuredBuffer` resources
and float type exchange and bitwise compare exchange operations.
Optionally, and where capability bits indicate support,
overloads for 64-bit integer atomic operations
on group shared memory and typed resources are added.

## InterlockedAdd

Atomically adds the provided `value`
 to that indicated by `dest`
 or indexed in the resource by `dest_offset`
 stores the result in that location
 and optionally returns the original input value
 through the `original_value` parameter.

### Syntax

```C++
void RWByteAddressBuffer::InterlockedAdd64(in uint dest_offset, in int64_t value, out int64_t original_value);
void RWByteAddressBuffer::InterlockedAdd64(in uint dest_offset, in uint64_t value, out uint64_t original_value);

void InterlockedAdd(inout SbufType dest, in int64_t value, out int64_t original_value);
void InterlockedAdd(inout SbufType dest, in uint64_t value, out uint64_t original_value);

void InterlockedAdd(inout TresType dest, in int64_t value, out int64_t original_value);
void InterlockedAdd(inout TresType dest, in uint64_t value, out uint64_t original_value);

void InterlockedAdd(inout ShmemType dest, in int64_t value, out int64_t original_value);
void InterlockedAdd(inout ShmemType dest, in uint64_t value, out uint64_t original_value);
```

## InterlockedAnd

Atomically performs a bitwise AND
 of the provided unsigned 64-bit integer `value`
 and that in the given `dest` location
 or indexed in the resource by `dest_offset`,
 stores the result in that location
 and optionally returns the original input value
 through the `original_value` parameter.

### Syntax

```C++
void RWByteAddressBuffer::InterlockedAnd64(in uint dest_offset, in uint64_t value, out uint64_t original_value);
void InterlockedAnd(inout SbufType dest, in uint64_t value, out uint64_t original_value);
void InterlockedAnd(inout TresType dest, in uint64_t value, out uint64_t original_value);
void InterlockedAnd(inout ShmemType dest, in uint64_t value, out uint64_t original_value);
```

## InterlockedOr

Atomically  performs a bitwise OR
 of the provided unsigned 64-bit integer `value`
 and that in the given `dest` location
 or indexed in the resource by `dest_offset`,
 stores the result in that location
 and optionally returns the original input value
 through the `original_value` parameter.

### Syntax

```C++
void RWByteAddressBuffer::InterlockedOr64(in uint dest_offset, in uint64_t value, out uint64_t original_value);
void InterlockedOr(inout SbufType dest, in uint64_t value, out uint64_t original_value);
void InterlockedOr(inout TresType dest, in uint64_t value, out uint64_t original_value);
void InterlockedOr(inout ShmemType dest, in uint64_t value, out uint64_t original_value);
```

## InterlockedXor

Atomically performs a bitwise XOR(exclusive or)
 of the provided unsigned 64-bit integer `value`
 and that in the given `dest` location
 or indexed in the resource by `dest_offset`,
 stores the result in that location
 and optionally returns the original input value
 through the `original_value` parameter.

### Syntax

```C++
void RWByteAddressBuffer::InterlockedXor64(in uint dest_offset, in uint64_t value, out uint64_t original_value);
void InterlockedXor(inout SbufType dest, in uint64_t value, out uint64_t original_value);
void InterlockedXor(inout TresType dest, in uint64_t value, out uint64_t original_value);
void InterlockedXor(inout ShmemType dest, in uint64_t value, out uint64_t original_value);
```

## InterlockedMin

Atomically calculates the smaller of the provided `value`
 and that in the given `dest` location
 or indexed in the resource by `dest_offset`,
  stores the smaller value in that location
 and optionally returns the original input value
 through the `original_value` parameter.

### Syntax

```C++
void RWByteAddressBuffer::InterlockedMin64(in uint dest_offset, in int64_t value, out int64_t original_value);
void RWByteAddressBuffer::InterlockedMin64(in uint dest_offset, in uint64_t value, out uint64_t original_value);

void InterlockedMin(inout SbufType dest, in int64_t value, out int64_t original_value);
void InterlockedMin(inout SbufType dest, in uint64_t value, out uint64_t original_value);

void InterlockedMin(inout TresType dest, in int64_t value, out int64_t original_value);
void InterlockedMin(inout TresType dest, in uint64_t value, out uint64_t original_value);

void InterlockedMin(inout ShmemType dest, in int64_t value, out int64_t original_value);
void InterlockedMin(inout ShmemType dest, in uint64_t value, out uint64_t original_value);
```

## InterlockedMax

Atomically calculates the larger of the provided `value`
 and that in the given `dest` location
 or indexed in the resource by `dest_offset`,
 stores the larger value in that location
 and optionally returns the original input value
 through the `original_value` parameter.

### Syntax

```C++
void RWByteAddressBuffer::InterlockedMax64(in uint dest_offset, in int64_t value, out int64_t original_value);
void RWByteAddressBuffer::InterlockedMax64(in uint dest_offset, in uint64_t value, out uint64_t original_value);

void InterlockedMax(inout SbufType dest, in int64_t value, out int64_t original_value);
void InterlockedMax(inout SbufType dest, in uint64_t value, out uint64_t original_value);

void InterlockedMax(inout TresType dest, in int64_t value, out int64_t original_value);
void InterlockedMax(inout TresType dest, in uint64_t value, out uint64_t original_value);

void InterlockedMax(inout ShmemType dest, in int64_t value, out int64_t original_value);
void InterlockedMax(inout ShmemType dest, in uint64_t value, out uint64_t original_value);
```

## InterlockedExchange

Atomically assigns the provided `value`
 to the location given by `dest`
 or indexed in the resource by `dest_offset`,
 and returns the original value from that location
 through the `original_value` parameter.

The floating-point overrides of these functions
simply use the same operations used by the existing integer functions.
As a result, unlike the other functions,
these two overrides are supported on SM 6.0
even without capability bits.

### Syntax

```C++
void RWByteAddressBuffer::InterlockedExchangeFloat(in uint dest_offset, in float value, out float original_value);[issue 3](#issues)
void RWByteAddressBuffer::InterlockedExchange64(in uint dest_offset, in int64_t value, out int64_t original_value);
void RWByteAddressBuffer::InterlockedExchange64(in uint dest_offset, in uint64_t value, out uint64_t original_value);

void InterlockedExchange(inout SbufType dest, in float value, out float original_value);[issue 3](#issues)
void InterlockedExchange(inout SbufType dest, in int64_t value, out int64_t original_value);
void InterlockedExchange(inout SbufType dest, in uint64_t value, out uint64_t original_value);

void InterlockedExchange(inout TresType dest, in float value, out float original_value);[issue 3](#issues)
void InterlockedExchange(inout TresType dest, in int64_t value, out int64_t original_value);
void InterlockedExchange(inout TresType dest, in uint64_t value, out uint64_t original_value);

void InterlockedExchange(inout ShmemType dest, in float value, out float original_value);[issue 3](#issues)
void InterlockedExchange(inout ShmemType dest, in int64_t value, out int64_t original_value);
void InterlockedExchange(inout ShmemType dest, in uint64_t value, out uint64_t original_value);
```

## InterlockedCompareStore

Atomically compares and assigns the indicated value.
The value in `dest`
or indexed by `dest_offset`
 is compared to `compare_value`.
If they are identical, the provided `value` is assigned
 to the that location.

Note that floating-point values are not accepted by InterlockedCompareStore
but can be performed using InterlockedCompareStoreFloatBitwise.

### Syntax

```C++
void RWByteAddressBuffer::InterlockedCompareStore64(in uint dest_offset, in int64_t compare_value, in int64_t value);
void RWByteAddressBuffer::InterlockedCompareStore64(in uint dest_offset, in uint64_t compare_value, in uint64_t value);

void InterlockedCompareStore(inout SbufType dest, in int64_t compare_value, in int64_t value);
void InterlockedCompareStore(inout SbufType dest, in uint64_t compare_value, in uint64_t value);

void InterlockedCompareStore(inout TresType dest, in int64_t compare_value, in int64_t value);
void InterlockedCompareStore(inout TresType dest, in uint64_t compare_value, in uint64_t value);

void InterlockedCompareStore(inout ShmemType dest, in int64_t compare_value, in int64_t value);
void InterlockedCompareStore(inout ShmemType dest, in uint64_t compare_value, in uint64_t value);
```

## InterlockedCompareStoreFloatBitwise

Atomically compares and assigns the indicated floating-point value
using a bitwise compare.
The value in `dest`
or indexed by `dest_offset`
 is compared to `compare_value`
 using a bitwise comparison of the value
 without consideration for floating-point special cases.
If they are bitwise identical, the provided `value` is assigned
 to the that location.

The floating-point overrides of these functions
simply use the same operations used by the existing integer functions.
As a result, unlike the other functions,
these overrides are supported on SM 6.0
even without capability bits.

### Syntax

```C++
void RWByteAddressBuffer::InterlockedCompareStoreFloatBitwise(in uint dest_offset, in float compare_value, in float value);
void InterlockedCompareStoreFloatBitwise(inout SbufType dest, in float compare_value, in float value);
void InterlockedCompareStoreFloatBitwise(inout TresType dest, in float compare_value, in float value);
void InterlockedCompareStoreFloatBitwise(inout ShmemType dest, in float compare_value, in float value);
```

## InterlockedCompareExchange

Atomically compares, returns and assigns the indicated value.
The value in `dest`
or indexed by `dest_offset`
 is compared to `compare_value`.
If they are identical, the provided `value` is assigned
 to the that location and
 the original value from that location is returned
 through the `original_value` parameter.
 After calling this function,
 the user can determine if the assignment was successful
 by verifying that `compare_value` is equal to `original_value`.

Note that floating-point values are not accepted by InterlockedCompareExchange
but can be performed using InterlockedCompareExchangeFloatBitwise.

### Syntax

```C++
void RWByteAddressBuffer::InterlockedCompareExchange64(in uint dest_offset, in int64_t compare_value, in int64_t value, out int64_t original_value);
void RWByteAddressBuffer::InterlockedCompareExchange64(in uint dest_offset, in uint64_t compare_value, in uint64_t value, out uint64_t original_value);

void InterlockedCompareExchange(inout SbufType dest, in int64_t compare_value, in int64_t value, out int64_t original_value);
void InterlockedCompareExchange(inout SbufType dest, in uint64_t compare_value, in uint64_t value, out uint64_t original_value);

void InterlockedCompareExchange(inout TresType dest, in int64_t compare_value, in int64_t value, out int64_t original_value);
void InterlockedCompareExchange(inout TresType dest, in uint64_t compare_value, in uint64_t value, out uint64_t original_value);

void InterlockedCompareExchange(inout ShmemType dest, in int64_t compare_value, in int64_t value, out int64_t original_value);
void InterlockedCompareExchange(inout ShmemType dest, in uint64_t compare_value, in uint64_t value, out uint64_t original_value);
```

## InterlockedCompareExchangeFloatBitwise

Atomically compares, returns and assigns the indicated floating-point value
using a bitwise compare.
The value in `dest`
or indexed by `dest_offset`
 is compared to `compare_value`
 using a bitwise comparison of the value
 without consideration for floating-point special cases.
If they are bitwise identical, the provided `value` is assigned
 to the that location and
 the original value from that location is returned
 through the `original_value` parameter.
 After calling this function,
 the user can determine if the assignment was successful
 by verifying that `compare_value` is equal to `original_value`.

The floating-point overrides of these functions
simply use the same operations used by the existing integer functions.
As a result, unlike the other functions,
these overrides are supported on SM 6.0
even without capability bits.

### Syntax

```C++
void RWByteAddressBuffer::InterlockedCompareExchangeFloatBitwise(in uint dest_offset, in float compare_value, in float value, out float original_value);
void InterlockedCompareExchangeFloatBitwise(inout SbufType dest, in float compare_value, in float value, out float original_value);
void InterlockedCompareExchangeFloatBitwise(inout TresType dest, in float compare_value, in float value, out float original_value);
void InterlockedCompareExchangeFloatBitwise(inout ShmemType dest, in float compare_value, in float value, out float original_value);
```

---

# Examples

Using a floating-point resource location for `dest`:

```C++
RWStructuredBuffer<float> intensities;
...
InterlockedExchange(intensities[pixelIndex], intensity);
```

Using a floating-point group shared memory register for `dest`:

```C++
groupshared float red;
...
InterlockedCompareExchangeFloatBitwise(red, oldred, newred, oldred);
```

Using a 64-bit integer resource location for `dest`:

```C++
RWTexture2D<int64_t> FragmentListHead;
int2 screenAddress;
...
InterlockedExchange(FragmentListHead[screenAddress], newHead, oldHead);
```

Using a 64-bit integer group shared memory register for `dest`:

```C++
groupshared int64_t peakDensity;
...
InterlockedMax(peakDensity, density, lastDensity);
```

Using a RWByteAddressBuffer with 64-bit max calculation:

```C++
RWByteAddressBuffer offsets : register(u4)
uint position;
uint64_t curOffset, lastOffset;
...
offsets.InterLockedMax64(position, curOffset, lastOffset);
```

---

# Device Capability

## Integer 64-bit Capabilities

Devices that support `D3D_SHADER_MODEL_6_6`
and support 64-bit integers as indicated by
the `Int64ShaderOps` member
of `D3D12_FEATURE_D3D12_OPTIONS1`
must support
all atomic operations with 64-bit
integer typed `value` parameters
that are methods of `RWByteAddressBuffer`
or whose `dest` parameter is of type `SbufType`
when those resources are declared as root descriptors
in the root signature.

Devices that support Shader model 6.6
may optionally support atomic operations
on typed resource or group shared memory
as indicated by capability bits.
Typed resource atomics are those with 64-bit
integer `value` parameters
whose `dest` parameter is
of type `TresType`.
Group shared memory atomics are those with 64-bit
integer `value` parameters
whose `dest` parameter is
of type `ShmemType`.

Devices that support Shader model 6.6
may also optionally support atomic operations
on resources in descriptor heaps
as indicated by capability bits.

## Float Capabilities

Devices that support `D3D_SHADER_MODEL_6_6`
must support Atomic `InterlockedExchange`
operations with float `value` parameters
and all `InterlockedCompareExchangeFloatBitwise` and
`InterlockedCompareStoreFloatBitwise` operations

# Capability Queries

Applications can query the availability
 of these SM 6.6 atomic operation variants
 using `ID3D12Device::CheckFeatureSupport()`
passing `D3D12_FEATURE_D3D12_OPTIONS9` or `D3D12_FEATURE_D3D12_OPTIONS11`
as the `Feature` parameter
and retrieving the `pFeatureSupportData` parameter
 as a struct of type `D3D12_FEATURE_DATA_D3D12_OPTIONS9` or `D3D12_FEATURE_DATA_D3D12_OPTIONS11`.
The relevant parts of these structs are defined below.

```C++
typedef enum D3D12_FEATURE {
    ...
    D3D12_FEATURE_D3D12_OPTIONS9,
    ...
    D3D12_FEATURE_D3D12_OPTIONS11
} D3D12_FEATURE;

typedef struct D3D12_FEATURE_DATA_D3D12_OPTIONS9 {
    ...
    BOOL AtomicInt64OnTypedResourceSupported;
    BOOL AtomicInt64OnGroupSharedSupported;
} D3D12_FEATURE_DATA_D3D12_OPTIONS9;

typedef struct D3D12_FEATURE_DATA_D3D12_OPTIONS11 {
    ...
    BOOL AtomicInt64OnDescriptorHeapResourceSupported;
} D3D12_FEATURE_DATA_D3D12_OPTIONS11;

```

`AtomicInt64OnTypedResourceSupported` is a boolean that specifies
whether typed resource 64-bit integer atomics are supported.
`AtomicInt64OnGroupSharedSupported` is a boolean that specifies
whether typed resource 64-bit integer atomics are supported.
`AtomicInt64OnDescriptorHeapResourceSupported` is a boolean that specifies
whether 64-bit integer atomics on resources
in descriptor heaps are supported.
All are optional in Shader Model 6.6.

---
# Issues

1. Should floats of different sizes be supported?
   - RESOLVED: No. The only question was 16 bit floats which will be supported.
   Though it has been found to be useful in existing projects, hardware vendors
   have viewed it with alarm or indifference.

2. Should vector types be supported?
   - RESOLVED: No. The existing atomic operators only accept scalars.

3. Should InterlockedExchange be extended to include floating-point variants?
   - RESOLVED: Yes. It can be treated as a bitwise equivalent of the integer variants.
This means that 6.6 is not required for this feature.
It will still be documented here,
but support is extended to 6.0 even without capability bits.

4. Should InterlockedCompareExchange be extended to include floating-point variants?
   - RESOLVED: No. Until IEEE support is more widely available,
   only bitwise compares are available.
   However, to allow usage on buffer types,
   a bitwise variant is of some use.
   We are adding InterlockedCompareExchangeFloatBitwise to allow this use.
   The suggested name InterlockedCompareExchangeFloatyMcBitface was rejected.

5. Do we need signed int64_t type operations?
   - RESOLVED: Yes. They are generally available in some form
    and the min/max variants provide genuine utility
    while the other operations are available by the same
    mechanisms as unsigned int.

6. What form should the capability query take?
   - RESOLVED: 64-bit integer support will include support for all atomic ops on rawbuffers
   as baseline 6.6.
   Capability bits for each of group shared memory and typed resources are included for those mem types.
   What floating point support there is is all baseline.

7. What floating-point support should this include?
   - RESOLVED: Support for bitwise exchange/store operations is available through the same mechanisms
   as existing 32-bit integers. These are supported. Nothing else is.

---

# Change Log

Version|Date|Description
-|-|-
1.00|20 Apr 2021|Minor Edits for Publication
0.17|16 Feb 2021|Rename Descriptor Heap cap bit and allocate to OPTIONS11
0.16|11 Jan 2021|Switch to OPTIONS9
0.15|07 Dec 2020|Add cap bit for descriptor heap support.
0.14|20 Aug 2020|Rename cap bit and ByteAddressBuffer methods
0.13|08 May 2020|Change references from typed buffer to typed resource. Fix typo
0.12|24 Apr 2020|Add CompareStore ops. Add separate cap bit for shmem and typed bufs. rename sharedmem to groupshared
0.11|09 Apr 2020|Revise capability bits to reflect memory type support.
0.10|09 Apr 2020|Remove floating point operations besides exchange and bitwise compare exchange
0.9|09 Apr 2020|Restore signed integer operations
0.8|09 Apr 2020|Add Capability bit queries
0.7|08 Apr 2020|Add InterlockedCompareExchangeFloatBitwise for bitwise float compares
0.6|08 Apr 2020|Better explain memory types. Enumerate overloads for each. Explain formats of used buffers.
0.5|07 Apr 2020|Remove fp16, interlockedcmpexchange for fp16 again
0.4|06 Mar 2020|Restore interlockedcmpexchange. Add fp16. hyphenate.
0.3|02 Mar 2020|Remove interlockedcmpexchange. Resolve issues. Reshuffle sections
0.2|12 Feb 2020|add tiers, clarify examples, remove spurious text, merge specs
0.1|07 Feb 2020|Initial draft
