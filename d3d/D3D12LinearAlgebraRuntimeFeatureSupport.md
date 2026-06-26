# D3D12 Linear Algebra Runtime Feature Support <!-- omit in toc -->

Version 0.9 (Draft)

---

## Contents <!-- omit in toc -->

- [Introduction](#introduction)
- [Granular Capability Query API](#granular-capability-query-api)
  - [D3D12\_LINEAR\_ALGEBRA\_OPERATION\_TYPE](#d3d12_linear_algebra_operation_type)
  - [D3D12\_LINEAR\_ALGEBRA\_DATATYPE](#d3d12_linear_algebra_datatype)
  - [D3D12\_LINEAR\_ALGEBRA\_OPERATION\_SUPPORT\_QUERY](#d3d12_linear_algebra_operation_support_query)
    - [D3D12\_LINEAR\_ALGEBRA\_MATRIX\_SHAPE](#d3d12_linear_algebra_matrix_shape)
    - [D3D12\_LINEAR\_ALGEBRA\_MATRIX\_CONSTRUCTION\_SUPPORT](#d3d12_linear_algebra_matrix_construction_support)
    - [D3D12\_LINEAR\_ALGEBRA\_WAVE\_MATRIX\_MULTIPLY\_INPUTS](#d3d12_linear_algebra_wave_matrix_multiply_inputs)
    - [D3D12\_LINEAR\_ALGEBRA\_MULTIPLICATION\_SUPPORT\_FLAGS](#d3d12_linear_algebra_multiplication_support_flags)
    - [D3D12\_LINEAR\_ALGEBRA\_WAVE\_MATRIX\_MULTIPLY\_SUPPORT](#d3d12_linear_algebra_wave_matrix_multiply_support)
    - [D3D12\_LINEAR\_ALGEBRA\_THREADGROUP\_MATRIX\_MULTIPLY\_SUPPORT](#d3d12_linear_algebra_threadgroup_matrix_multiply_support)
    - [D3D12\_LINEAR\_ALGEBRA\_THREAD\_VECTOR\_MATRIX\_MULTIPLY\_SUPPORT](#d3d12_linear_algebra_thread_vector_matrix_multiply_support)
    - [D3D12\_LINEAR\_ALGEBRA\_THREAD\_OUTER\_PRODUCT\_SUPPORT](#d3d12_linear_algebra_thread_outer_product_support)
    - [D3D12\_LINEAR\_ALGEBRA\_ATOMIC\_ACCUMULATE\_STORE\_SUPPORT](#d3d12_linear_algebra_atomic_accumulate_store_support)
    - [D3D12\_FEATURE\_DATA\_LINEAR\_ALGEBRA\_MATRIX\_OPERATION\_SUPPORT](#d3d12_feature_data_linear_algebra_matrix_operation_support)
  - [Usage Example](#usage-example)
- [Operation Enumeration API](#operation-enumeration-api)
  - [Enumeration Entry Structures](#enumeration-entry-structures)
  - [D3D12\_FEATURE\_DATA\_LINEAR\_ALGEBRA\_OPERATION\_ENUMERATION](#d3d12_feature_data_linear_algebra_operation_enumeration)
  - [Enumeration Usage Example](#enumeration-usage-example)
- [D3D12\_LINEAR\_ALGEBRA\_TIER](#d3d12_linear_algebra_tier)
- [Tier 1 Support](#tier-1-support)
  - [Matrix-Matrix Operations](#matrix-matrix-operations)
  - [Vector-Matrix Operations](#vector-matrix-operations)
  - [Native Matrix Dimensions](#native-matrix-dimensions)
  - [Outer Product](#outer-product)
  - [Accumulation Store](#accumulation-store)
- [Runtime Validation](#runtime-validation)
- [Convert Matrix to desired layout and type](#convert-matrix-to-desired-layout-and-type)
  - [Query Destination Size](#query-destination-size)
  - [Conversion descriptors](#conversion-descriptors)
  - [Conversion APIs](#conversion-apis)
- [D3D12 DDI Additions](#d3d12-ddi-additions)
- [Change Log](#change-log)
---

## Introduction

This document specifies the D3D12 runtime support requirements for the HLSL Linear Algebra feature as defined in [HLSL proposal 0035 - Linear Algebra Matrix](https://github.com/microsoft/hlsl-specs/blob/main/proposals/0035-linalg-matrix.md). While the HLSL specification defines the language-level API and shader capabilities, this document establishes the minimum hardware and driver support requirements that all D3D12 implementations must meet to enable these features. The primary focus is to define consistent baseline capabilities across GPU vendors, ensuring that applications can rely on a predictable set of matrix operations, formats, and dimensions regardless of the underlying hardware architecture. This standardization enables portable high-performance linear algebra workloads while allowing vendors to expose additional capabilities through higher tiers or extended feature sets.

The fundamental capability here is the ability for a single GPU wave to distribute a matrix multiply (i.e. dot products) across a wave, often using smaller data types than would be used for traditional shader math. The GPU instructions used to accomplish this have fixed tile sizes/shapes, which are different from one architecture to another, even in hardware from a single vendor. Some GPUs have a few choices for shapes as well. Fortunately, matrix multiplication can be broken down into smaller tiles, so customers need not match the exact hardware capabilities of their specific target device.

Additionally, this same hardware can be used to perform vector-matrix multiplication, if you construct a wave matrix out of a set of per-thread vectors. The exact mechanism for doing this is left to the driver to implement, for maximum efficiency. And some hardware has the capability to use even larger tiles that would be expensive to emulate on devices with smaller tiles - if the data can support it, allowing the driver to break down the problem using thread-group-wide matrices can help as well.

With all of that said, the fundamental thing that D3D allows querying from the driver is which data types can be multiplied together using wave-level matrix multiplication hardware, what results they can produce, and what tile sizes are used.

## Granular Capability Query API

While the tier system provides a convenient way to target well-defined hardware profiles, some applications may need to query support for specific matrix operation configurations that fall outside standard tier definitions or to leverage vendor-specific capabilities. The D3D12 runtime exposes two complementary capability query APIs:

* The **granular capability query API** described in this section answers the targeted question *"is this specific configuration supported?"* It is the natural fit for runtime validation (for example, checking whether a precompiled shader's matrix operation can be executed on the current device).
* The [Operation Enumeration API](#operation-enumeration-api) answers the discovery question *"which configurations does the driver natively support?"* It is the natural fit for applications that want to pick an operation shape or data-type combination based on driver capabilities, rather than test a specific one.

Both APIs report the same underlying capabilities; an application is free to use either or both.

### D3D12_LINEAR_ALGEBRA_OPERATION_TYPE

```cpp
typedef enum D3D12_LINEAR_ALGEBRA_OPERATION_TYPE
{
    D3D12_LINEAR_ALGEBRA_OPERATION_TYPE_MATRIX_CONSTRUCTION,
    D3D12_LINEAR_ALGEBRA_OPERATION_TYPE_WAVE_MATRIX_MULTIPLY,
    D3D12_LINEAR_ALGEBRA_OPERATION_TYPE_THREADGROUP_MATRIX_MULTIPLY,
    D3D12_LINEAR_ALGEBRA_OPERATION_TYPE_THREAD_VECTOR_MATRIX_MULTIPLY,
    D3D12_LINEAR_ALGEBRA_OPERATION_TYPE_THREAD_OUTER_PRODUCT,
    D3D12_LINEAR_ALGEBRA_OPERATION_TYPE_ATOMIC_ACCUMULATE_STORE,
} D3D12_LINEAR_ALGEBRA_OPERATION_TYPE;
```

### D3D12_LINEAR_ALGEBRA_DATATYPE
```cpp
typedef enum D3D12_LINEAR_ALGEBRA_DATATYPE {
    D3D12_LINEAR_ALGEBRA_DATATYPE_NONE = 0,
    D3D12_LINEAR_ALGEBRA_DATATYPE_SINT16 = 2,
    D3D12_LINEAR_ALGEBRA_DATATYPE_UINT16 = 3,
    D3D12_LINEAR_ALGEBRA_DATATYPE_SINT32 = 4,
    D3D12_LINEAR_ALGEBRA_DATATYPE_UINT32 = 5,
    D3D12_LINEAR_ALGEBRA_DATATYPE_FLOAT16 = 7,
    D3D12_LINEAR_ALGEBRA_DATATYPE_FLOAT32 = 8,
    D3D12_LINEAR_ALGEBRA_DATATYPE_SINT8 = 18,
    D3D12_LINEAR_ALGEBRA_DATATYPE_UINT8 = 19,
    D3D12_LINEAR_ALGEBRA_DATATYPE_FLOAT8_E4M3FN = 20,
    D3D12_LINEAR_ALGEBRA_DATATYPE_FLOAT8_E5M2 = 21
} D3D12_LINEAR_ALGEBRA_DATATYPE;
```

### D3D12_LINEAR_ALGEBRA_OPERATION_SUPPORT_QUERY

#### D3D12_LINEAR_ALGEBRA_MATRIX_SHAPE
``` cpp
typedef struct D3D12_LINEAR_ALGEBRA_MATRIX_SHAPE
{
    UINT M;  // Rows in matrix A
    UINT K;  // Columns in matrix A / Rows in matrix B
    UINT N;  // Columns in matrix B
} D3D12_LINEAR_ALGEBRA_MATRIX_SHAPE;
```

- `M`, `K`, `N` - Matrix dimensions following the formula MxK * KxN = MxN. Each matrix shape simultaneously names a supported A matrix (MxK), B matrix (KxN), and accumulator matrix (MxN) layout. The same shape type is used for both matrix construction and matrix multiplication queries.

#### D3D12_LINEAR_ALGEBRA_MATRIX_CONSTRUCTION_SUPPORT
``` cpp
typedef struct D3D12_LINEAR_ALGEBRA_MATRIX_CONSTRUCTION_SUPPORT
{
    // Inputs
    D3D12_LINEAR_ALGEBRA_DATATYPE ComponentType;
    UINT WaveSize;
    D3D12_LINEAR_ALGEBRA_MATRIX_SHAPE Shape;

    // Outputs
    BOOL Supported;
} D3D12_LINEAR_ALGEBRA_MATRIX_CONSTRUCTION_SUPPORT;
```

This query indicates a driver's level of support for general operations on wave-scope and group-scope matrices. Since matrices at these scopes can be loaded, stored, manipulated, and converted without actually being used in a multiplication operation, multiplication support is not sufficient. Essentially, a driver that responds positively to this query indicates that it knows how to lay out these components in registers. If a driver supports a particular component type and shape, then it must support:
* Loading a matrix of that type and shape from buffer or group-shared memory, and similarly for storing (`Load()`/`Store()`).
* Operating on elements of a matrix (`Length()`/`GetCoordinate()`/`Get()`/`Set()`/`Splat()`).
* Being used as a source or destination of a conversion (`Cast()`).

- `ComponentType` - The matrix component type being queried.

- `WaveSize` - The wave size for the shader constructing the matrix. Must be a power of 2 in the device's valid wave size range, or else 0 to indicate any.

- `Shape` - The matrix shape being queried. Application matrix shapes that are an integer multiple of any native shape in each dimension are reported as supported, so apps can either query a known native shape (discovered via the [Operation Enumeration API](#operation-enumeration-api)) or directly query the matrix size they wish to construct.

- `Supported` - On output, `TRUE` if the driver can construct the requested shape for the requested component type.

For any `(ComponentType, Shape)` reported as supported by the [wave-scope](#d3d12_linear_algebra_wave_matrix_multiply_support) or [threadgroup-scope](#d3d12_linear_algebra_threadgroup_matrix_multiply_support) multiplication queries, this query must also report support for that component type and shape -- every matrix that can participate in a supported multiplication must also be constructible. Drivers that support multiple multiplication tilings for the same type combination (for example 4x16x16 alongside 16x4x16) implicitly support construction at each tiling.

#### D3D12_LINEAR_ALGEBRA_WAVE_MATRIX_MULTIPLY_INPUTS
``` cpp
typedef struct D3D12_LINEAR_ALGEBRA_WAVE_MATRIX_MULTIPLY_INPUTS
{
    UINT WaveSize;
    D3D12_LINEAR_ALGEBRA_DATATYPE MatrixAComponentType;
    D3D12_LINEAR_ALGEBRA_DATATYPE MatrixBComponentType;
    D3D12_LINEAR_ALGEBRA_DATATYPE AccumulatorComponentType;
} D3D12_LINEAR_ALGEBRA_WAVE_MATRIX_MULTIPLY_INPUTS;
```

- `WaveSize` - The wave size for the shader executing the operation. Must be a power of 2 in the device's valid wave size range, or else 0 to indicate any.

- `MatrixAComponentType` - Component type of the A matrix.

- `MatrixBComponentType` - Component type of the B matrix.

- `AccumulatorComponentType` - Component type of the accumulator matrix.

#### D3D12_LINEAR_ALGEBRA_MULTIPLICATION_SUPPORT_FLAGS

```cpp
typedef enum D3D12_LINEAR_ALGEBRA_MULTIPLICATION_SUPPORT_FLAGS
{
    D3D12_LINEAR_ALGEBRA_MULTIPLICATION_SUPPORT_FLAG_SUPPORTED = 1,
    D3D12_LINEAR_ALGEBRA_MULTIPLICATION_SUPPORT_FLAG_EMULATED_INPUTS = 2,
    D3D12_LINEAR_ALGEBRA_MULTIPLICATION_SUPPORT_FLAG_EMULATED_OUTPUTS = 4,
    D3D12_LINEAR_ALGEBRA_MULTIPLICATION_SUPPORT_FLAG_TRANSPOSE = 8,
} D3D12_LINEAR_ALGEBRA_MULTIPLICATION_SUPPORT_FLAGS;
```

|Flag|Meaning|
|----|-------|
|`D3D12_LINEAR_ALGEBRA_MULTIPLICATION_SUPPORT_FLAG_SUPPORTED`|The driver will accept the operation in a shader.|
|`D3D12_LINEAR_ALGEBRA_MULTIPLICATION_SUPPORT_FLAG_EMULATED_INPUTS`|The hardware does not have acceleration for multiplication of the specified input types. This is only relevant for thread-scope vector-matrix multiplication. This may only be present when `MatrixInputType` is `FLOAT8_E4M3` or `FLOAT8_E5M2`. If this flag is present, then the operation may be performed at higher precision, i.e. the vector input type may not be converted to the matrix type before multiplication. Additionally, the input matrix data *must* be loaded from a `MulOptimal` layout, or `MulOptimalTransposed` layout if `D3D12_LINEAR_ALGEBRA_THREAD_VECTOR_MATRIX_SUPPORT_FLAG_TRANSPOSE` is also present.|
|`D3D12_LINEAR_ALGEBRA_MULTIPLICATION_SUPPORT_FLAG_EMULATED_OUTPUTS`|The hardware does not have acceleration for accumulation of the specified output types. If this flag is present, then the operation may be performed with higher or lower internal precision, followed by a final conversion step. For example, if present on an operation with `FLOAT16` inputs and outputs, then the accumulation step for each individual `FLOAT16` output may be performed at `FLOAT32` precision with a final rounding step, rather than `FLOAT16` rounding after each multiply-add step in the dot product of the outputs.|
|`D3D12_LINEAR_ALGEBRA_MULTIPLICATION_SUPPORT_FLAG_TRANSPOSE`|The driver can perform loads through transposed layouts. This is only relevant for thread-scope vector-matrix multiplication.|

#### D3D12_LINEAR_ALGEBRA_WAVE_MATRIX_MULTIPLY_SUPPORT
``` cpp
typedef struct D3D12_LINEAR_ALGEBRA_WAVE_MATRIX_MULTIPLY_SUPPORT
{
    // Inputs
    D3D12_LINEAR_ALGEBRA_WAVE_MATRIX_MULTIPLY_INPUTS Inputs;
    D3D12_LINEAR_ALGEBRA_MATRIX_SHAPE Shape;

    // Outputs
    D3D12_LINEAR_ALGEBRA_MULTIPLICATION_SUPPORT_FLAGS SupportFlags;
} D3D12_LINEAR_ALGEBRA_WAVE_MATRIX_MULTIPLY_SUPPORT;
```

- `Inputs` - The type combination being queried.

- `Shape` - The matrix shape being queried. Application matrix shapes that are an integer multiple of any native shape in each dimension are reported as supported. There is no limitation on maximum matrix size, though larger matrices may result in significantly adverse performance. Native shapes can be discovered via the [Operation Enumeration API](#operation-enumeration-api).

- `SupportFlags` - Indicates whether the operation is supported, and whether any emulation of the requested data types would occur. See [D3D12_LINEAR_ALGEBRA_MULTIPLICATION_SUPPORT_FLAGS](#d3d12_linear_algebra_multiplication_support_flags) for the meaning of each flag.

#### D3D12_LINEAR_ALGEBRA_THREADGROUP_MATRIX_MULTIPLY_SUPPORT
``` cpp
typedef struct D3D12_LINEAR_ALGEBRA_THREADGROUP_MATRIX_MULTIPLY_SUPPORT
{
    // Inputs
    D3D12_LINEAR_ALGEBRA_WAVE_MATRIX_MULTIPLY_INPUTS WaveInputs;
    D3D12_LINEAR_ALGEBRA_MATRIX_SHAPE Shape;

    // Outputs
    D3D12_LINEAR_ALGEBRA_MULTIPLICATION_SUPPORT_FLAGS SupportFlags;
    UINT MinThreadGroupSize;
    UINT MaxThreadGroupSize;
    UINT PreferredThreadGroupSize;
} D3D12_LINEAR_ALGEBRA_THREADGROUP_MATRIX_MULTIPLY_SUPPORT;
```

- `WaveInputs` - The type combination being queried.

- `Shape` - The matrix shape being queried. Application matrix shapes that are an integer multiple of any native shape in each dimension are reported as supported. There is no limitation on maximum matrix size, though larger matrices may result in significantly adverse performance. Native shapes can be discovered via the [Operation Enumeration API](#operation-enumeration-api).

- `SupportFlags` - Indicates whether the operation is supported, and whether any emulation of the requested data types would occur. See [D3D12_LINEAR_ALGEBRA_MULTIPLICATION_SUPPORT_FLAGS](#d3d12_linear_algebra_multiplication_support_flags) for the meaning of each flag.

- `MinThreadGroupSize` - The minimum number of threads in a group that can perform this multiplication for the requested shape.

- `MaxThreadGroupSize` - The maximum number of threads in a group that can perform this multiplication for the requested shape. Valid sizes are then multiples of the minimum, up to and including the maximum.

- `PreferredThreadGroupSize` - The driver's estimate for the most efficient thread group size to perform this multiplication for the requested shape. This may be zero, indicating that there are trade-offs (e.g. register pressure vs throughput) and it is not possible for the driver to report an optimal size.

#### D3D12_LINEAR_ALGEBRA_THREAD_VECTOR_MATRIX_MULTIPLY_SUPPORT
``` cpp
typedef struct D3D12_LINEAR_ALGEBRA_THREAD_VECTOR_MATRIX_MULTIPLY_SUPPORT
{
    // Inputs
    D3D12_LINEAR_ALGEBRA_DATATYPE VectorInputType;
    D3D12_LINEAR_ALGEBRA_DATATYPE MatrixInputType;
    D3D12_LINEAR_ALGEBRA_DATATYPE BiasInputType;
    D3D12_LINEAR_ALGEBRA_DATATYPE VectorResultType;

    // Outputs
    D3D12_LINEAR_ALGEBRA_MULTIPLICATION_SUPPORT_FLAGS SupportFlags;
} D3D12_LINEAR_ALGEBRA_THREAD_VECTOR_MATRIX_MULTIPLY_SUPPORT;
```

- `VectorInputType` - The HLSL-author-visible type of the input vector operand. If the HLSL vector is an `InterpretedVector`, this is the interpreted type; otherwise this is the native HLSL vector element type.

- `MatrixInputType` - The type of the input matrix. This is also the precision at which the multiplication itself is performed: at the DXIL/DDI level the vector operand always matches the matrix type (differing at most in integer signedness for integer types) when the multiply executes.

- `BiasInputType` - The type of data that's added to the multiplication result before returning the result.

- `VectorResultType` - The type of the bias and result vectors.

- `SupportFlags` - Indicates level of support for this operation. See [D3D12_LINEAR_ALGEBRA_MULTIPLICATION_SUPPORT_FLAGS](#d3d12_linear_algebra_multiplication_support_flags) for the meaning of each flag.

**Conversion semantics.** The application supplies the vector operand to the multiplication via one of two paths:

* As a `linalg::InterpretedVector` whose interpretation type matches `MatrixInputType` (differing at most in integer signedness). The HLSL compiler does not insert a conversion; the multiply consumes the interpretation directly. Valid only when `VectorInputType` already matches `MatrixInputType` under the same equivalence.
* As a native HLSL vector of element type `VectorInputType`. When `VectorInputType` matches `MatrixInputType` (differing at most in integer signedness) no conversion is needed. Otherwise the HLSL compiler emits a conversion to `MatrixInputType` before the multiply. This compiler-inserted conversion is lossy when `VectorInputType` has higher precision or wider range than `MatrixInputType`, and applications using such combinations (for example INT8-quantized weight workflows that supply Fp32 activations against an SInt8 matrix) are responsible for any quantization or normalization required to make the conversion meaningful.

**Native vs. emulated execution.** When the implementation can natively accelerate the requested type combination, neither `EMULATED_INPUTS` nor `EMULATED_OUTPUTS` is reported in `SupportFlags`. Either flag being set implies the operation is not natively accelerated; the two flags are independent and either, both, or neither may be reported.

#### D3D12_LINEAR_ALGEBRA_THREAD_OUTER_PRODUCT_SUPPORT

``` cpp
typedef struct D3D12_LINEAR_ALGEBRA_THREAD_OUTER_PRODUCT_SUPPORT
{
    // Inputs
    D3D12_LINEAR_ALGEBRA_DATATYPE InputComponentType;
    D3D12_LINEAR_ALGEBRA_DATATYPE ResultComponentType;

    // Outputs
    BOOL Supported;
} D3D12_LINEAR_ALGEBRA_THREAD_OUTER_PRODUCT_SUPPORT;
```

- `InputComponentType` - Type of the input vectors. Both vectors must have the same type.
- `ResultComponentType` - Type of the output vector.
- `Supported` - Output: Whether the outer product operation is supported.

#### D3D12_LINEAR_ALGEBRA_ATOMIC_ACCUMULATE_STORE_SUPPORT

``` cpp
typedef struct D3D12_LINEAR_ALGEBRA_ATOMIC_ACCUMULATE_STORE_SUPPORT
{
    // Inputs
    D3D12_LINEAR_ALGEBRA_DATATYPE ComponentType;

    // Outputs
    BOOL RWByteAddressBufferSupported;
    BOOL GroupSharedSupported;
} D3D12_LINEAR_ALGEBRA_ATOMIC_ACCUMULATE_STORE_SUPPORT;
```

- `ComponentType` - Type of the input matrix or vector.
- `RWByteAddressBufferSupported` - Whether this atomic operation is supported on UAVs.
- `GroupSharedSupported` - Whether this atomic operation is supported on group-shared arrays.

#### D3D12_FEATURE_DATA_LINEAR_ALGEBRA_MATRIX_OPERATION_SUPPORT

```cpp
typedef struct D3D12_FEATURE_DATA_LINEAR_ALGEBRA_MATRIX_OPERATION_SUPPORT
{
    D3D12_LINEAR_ALGEBRA_OPERATION_TYPE OperationType;
    union
    {
        D3D12_LINEAR_ALGEBRA_MATRIX_CONSTRUCTION_SUPPORT MatrixConstruction;
        D3D12_LINEAR_ALGEBRA_WAVE_MATRIX_MULTIPLY_SUPPORT WaveMatrixMultiply;
        D3D12_LINEAR_ALGEBRA_THREADGROUP_MATRIX_MULTIPLY_SUPPORT ThreadGroupMatrixMultiply;
        D3D12_LINEAR_ALGEBRA_THREAD_VECTOR_MATRIX_MULTIPLY_SUPPORT ThreadVectorMatrixMultiply;
        D3D12_LINEAR_ALGEBRA_THREAD_OUTER_PRODUCT_SUPPORT ThreadOuterProductSupport;
        D3D12_LINEAR_ALGEBRA_ATOMIC_ACCUMULATE_STORE_SUPPORT AccumulateStore;
    };
} D3D12_FEATURE_DATA_LINEAR_ALGEBRA_MATRIX_OPERATION_SUPPORT;
```
Members:

- `OperationType` - The type of operation to query support for.

- `MatrixConstruction` - Used when `OperationType` is `D3D12_LINEAR_ALGEBRA_OPERATION_TYPE_MATRIX_CONSTRUCTION`.

- `WaveMatrixMultiply` - Used when `OperationType` is `D3D12_LINEAR_ALGEBRA_OPERATION_TYPE_WAVE_MATRIX_MULTIPLY`.

- `ThreadGroupMatrixMultiply` - Used when `OperationType` is `D3D12_LINEAR_ALGEBRA_OPERATION_TYPE_THREADGROUP_MATRIX_MULTIPLY`.

- `ThreadVectorMatrixMultiply` - Used when `OperationType` is `D3D12_LINEAR_ALGEBRA_OPERATION_TYPE_THREAD_VECTOR_MATRIX_MULTIPLY`.

- `ThreadOuterProductSupport` - Used when `OperationType` is `D3D12_LINEAR_ALGEBRA_OPERATION_TYPE_THREAD_OUTER_PRODUCT`. Output formats from outer product must be supported for accumulate-store.

- `AccumulateStore` - Used when `OperationType` is `D3D12_LINEAR_ALGEBRA_OPERATION_TYPE_ATOMIC_ACCUMULATE_STORE`.

### Usage Example
``` cpp
// I have a shader that tries to use wave scope matrix multiplication with MxKxN = 64x64x64, FP16xFP16->FP32.
// Query if it's valid for me to use that shader.
D3D12_FEATURE_DATA_LINEAR_ALGEBRA_MATRIX_OPERATION_SUPPORT opSupport = {};
opSupport.OperationType = D3D12_LINEAR_ALGEBRA_OPERATION_TYPE_WAVE_MATRIX_MULTIPLY;
opSupport.WaveMatrixMultiply.Inputs.WaveSize = 0; // I don't care about the wave size
opSupport.WaveMatrixMultiply.Inputs.MatrixAComponentType = D3D12_LINEAR_ALGEBRA_DATATYPE_FLOAT16;
opSupport.WaveMatrixMultiply.Inputs.MatrixBComponentType = D3D12_LINEAR_ALGEBRA_DATATYPE_FLOAT16;
opSupport.WaveMatrixMultiply.Inputs.AccumulatorComponentType = D3D12_LINEAR_ALGEBRA_DATATYPE_FLOAT32;
opSupport.WaveMatrixMultiply.Shape = { 64, 64, 64 };

HRESULT hr = device->CheckFeatureSupport(
    D3D12_FEATURE_LINEAR_ALGEBRA_MATRIX_OPERATION_SUPPORT,
    &opSupport,
    sizeof(opSupport));

if (SUCCEEDED(hr) &&
    (opSupport.WaveMatrixMultiply.SupportFlags & D3D12_LINEAR_ALGEBRA_MULTIPLICATION_SUPPORT_FLAG_SUPPORTED))
{
    // 64x64x64 FP16xFP16->FP32 is supported on this device. The driver will internally
    // tile the operation using one of its native shapes; see the Operation Enumeration
    // API if the application needs to know which native shapes are available.
}

// Query vector-matrix multiply support
D3D12_FEATURE_DATA_LINEAR_ALGEBRA_MATRIX_OPERATION_SUPPORT vecMatSupport = {};
vecMatSupport.OperationType = D3D12_LINEAR_ALGEBRA_OPERATION_TYPE_THREAD_VECTOR_MATRIX_MULTIPLY;
vecMatSupport.ThreadVectorMatrixMultiply.VectorInputType = D3D12_LINEAR_ALGEBRA_DATATYPE_FLOAT16;
vecMatSupport.ThreadVectorMatrixMultiply.MatrixInputType = D3D12_LINEAR_ALGEBRA_DATATYPE_FLOAT16;
vecMatSupport.ThreadVectorMatrixMultiply.BiasInputType = D3D12_LINEAR_ALGEBRA_DATATYPE_NONE;
vecMatSupport.ThreadVectorMatrixMultiply.VectorResultType = D3D12_LINEAR_ALGEBRA_DATATYPE_FLOAT16;

hr = device->CheckFeatureSupport(
    D3D12_FEATURE_LINEAR_ALGEBRA_MATRIX_OPERATION_SUPPORT,
    &vecMatSupport,
    sizeof(vecMatSupport));

if (SUCCEEDED(hr) &&
    (vecMatSupport.ThreadVectorMatrixMultiply.SupportFlags & D3D12_LINEAR_ALGEBRA_MULTIPLICATION_SUPPORT_FLAG_SUPPORTED))
{
    // Device supports this vector-matrix operation configuration
}
```

## Operation Enumeration API

The granular query API in the previous section answers the question *"is this exact configuration supported?"* -- useful for runtime validation but inconvenient for applications that want to *discover* the configurations a driver natively supports without iterating the entire cross-product of types, shapes, and wave sizes. The Operation Enumeration API directly returns the flat list of native configurations for a given operation type.

This API enumerates the native configurations the driver supports for a given operation type. The relationship to the granular query is one-directional: every configuration the enumeration returns must be reported as supported by the granular query (including any integer multiple of a returned shape, where the operation type has a shape), and conversely the granular query reports as supported only configurations covered by the enumeration's flat list expanded with the integer-multiples rule.

### Enumeration Entry Structures

Each enumeration entry describes one fully-specified native configuration. For operation types whose native support is expressed in terms of tile shapes (matrix construction, wave-scope multiply, threadgroup-scope multiply), the enumeration is flat: one entry per `(type combination, tile shape)` pair. Drivers that support multiple tilings for the same type combination report each as a separate entry. Configurations the driver supports only with emulation are included, with the appropriate `EMULATED_INPUTS` / `EMULATED_OUTPUTS` flag set in `SupportFlags`.

For operation types that depend on wave size, each entry reports the inclusive range `[MinWaveSize, MaxWaveSize]` over which the rest of the entry's fields apply. Every power-of-2 wave size in that range that also lies in the device's valid wave size range is supported by the entry. Drivers whose support is not contiguous in wave size emit a separate entry per contiguous range.

```cpp
typedef struct D3D12_LINEAR_ALGEBRA_MATRIX_CONSTRUCTION_ENUMERATION_ENTRY
{
    D3D12_LINEAR_ALGEBRA_DATATYPE ComponentType;
    UINT MinWaveSize;
    UINT MaxWaveSize;
    D3D12_LINEAR_ALGEBRA_MATRIX_SHAPE Shape;
} D3D12_LINEAR_ALGEBRA_MATRIX_CONSTRUCTION_ENUMERATION_ENTRY;

typedef struct D3D12_LINEAR_ALGEBRA_WAVE_MATRIX_MULTIPLY_ENUMERATION_ENTRY
{
    UINT MinWaveSize;
    UINT MaxWaveSize;
    D3D12_LINEAR_ALGEBRA_DATATYPE MatrixAComponentType;
    D3D12_LINEAR_ALGEBRA_DATATYPE MatrixBComponentType;
    D3D12_LINEAR_ALGEBRA_DATATYPE AccumulatorComponentType;
    D3D12_LINEAR_ALGEBRA_MULTIPLICATION_SUPPORT_FLAGS SupportFlags;
    D3D12_LINEAR_ALGEBRA_MATRIX_SHAPE Shape;
} D3D12_LINEAR_ALGEBRA_WAVE_MATRIX_MULTIPLY_ENUMERATION_ENTRY;

typedef struct D3D12_LINEAR_ALGEBRA_THREADGROUP_MATRIX_MULTIPLY_ENUMERATION_ENTRY
{
    UINT MinWaveSize;
    UINT MaxWaveSize;
    D3D12_LINEAR_ALGEBRA_DATATYPE MatrixAComponentType;
    D3D12_LINEAR_ALGEBRA_DATATYPE MatrixBComponentType;
    D3D12_LINEAR_ALGEBRA_DATATYPE AccumulatorComponentType;
    D3D12_LINEAR_ALGEBRA_MULTIPLICATION_SUPPORT_FLAGS SupportFlags;
    D3D12_LINEAR_ALGEBRA_MATRIX_SHAPE Shape;
    UINT MinThreadGroupSize;
    UINT MaxThreadGroupSize;
    UINT PreferredThreadGroupSize;
} D3D12_LINEAR_ALGEBRA_THREADGROUP_MATRIX_MULTIPLY_ENUMERATION_ENTRY;

typedef struct D3D12_LINEAR_ALGEBRA_THREAD_VECTOR_MATRIX_MULTIPLY_ENUMERATION_ENTRY
{
    D3D12_LINEAR_ALGEBRA_DATATYPE VectorInputType;
    D3D12_LINEAR_ALGEBRA_DATATYPE MatrixInputType;
    D3D12_LINEAR_ALGEBRA_DATATYPE BiasInputType;
    D3D12_LINEAR_ALGEBRA_DATATYPE VectorResultType;
    D3D12_LINEAR_ALGEBRA_MULTIPLICATION_SUPPORT_FLAGS SupportFlags;
} D3D12_LINEAR_ALGEBRA_THREAD_VECTOR_MATRIX_MULTIPLY_ENUMERATION_ENTRY;

typedef struct D3D12_LINEAR_ALGEBRA_THREAD_OUTER_PRODUCT_ENUMERATION_ENTRY
{
    D3D12_LINEAR_ALGEBRA_DATATYPE InputComponentType;
    D3D12_LINEAR_ALGEBRA_DATATYPE ResultComponentType;
} D3D12_LINEAR_ALGEBRA_THREAD_OUTER_PRODUCT_ENUMERATION_ENTRY;

typedef struct D3D12_LINEAR_ALGEBRA_ATOMIC_ACCUMULATE_STORE_ENUMERATION_ENTRY
{
    D3D12_LINEAR_ALGEBRA_DATATYPE ComponentType;
    BOOL RWByteAddressBufferSupported;
    BOOL GroupSharedSupported;
} D3D12_LINEAR_ALGEBRA_ATOMIC_ACCUMULATE_STORE_ENUMERATION_ENTRY;
```

### D3D12_FEATURE_DATA_LINEAR_ALGEBRA_OPERATION_ENUMERATION

The new feature value `D3D12_FEATURE_LINEAR_ALGEBRA_OPERATION_ENUMERATION` is queried with a struct that selects an operation type and provides a typed pointer to the caller's entry array. `NumEntries` lives outside the union -- it carries the array capacity on input and the number of entries the driver would write on output, in entries (not bytes), regardless of which operation type is selected. The runtime writes up to `min(input capacity, available)` entries.

```cpp
typedef struct D3D12_FEATURE_DATA_LINEAR_ALGEBRA_OPERATION_ENUMERATION
{
    D3D12_LINEAR_ALGEBRA_OPERATION_TYPE OperationType;
    UINT NumEntries;
    union
    {
        D3D12_LINEAR_ALGEBRA_MATRIX_CONSTRUCTION_ENUMERATION_ENTRY          *MatrixConstruction;
        D3D12_LINEAR_ALGEBRA_WAVE_MATRIX_MULTIPLY_ENUMERATION_ENTRY         *WaveMatrixMultiply;
        D3D12_LINEAR_ALGEBRA_THREADGROUP_MATRIX_MULTIPLY_ENUMERATION_ENTRY  *ThreadGroupMatrixMultiply;
        D3D12_LINEAR_ALGEBRA_THREAD_VECTOR_MATRIX_MULTIPLY_ENUMERATION_ENTRY *ThreadVectorMatrixMultiply;
        D3D12_LINEAR_ALGEBRA_THREAD_OUTER_PRODUCT_ENUMERATION_ENTRY         *ThreadOuterProduct;
        D3D12_LINEAR_ALGEBRA_ATOMIC_ACCUMULATE_STORE_ENUMERATION_ENTRY      *AccumulateStore;
    };
} D3D12_FEATURE_DATA_LINEAR_ALGEBRA_OPERATION_ENUMERATION;
```

The intended usage is the standard two-call sequence: pass `NumEntries = 0` and a null union pointer to learn how many entries the driver would emit, allocate, then call again with the allocated array and `NumEntries` set to its capacity.

### Enumeration Usage Example

```cpp
// Discover every native wave-scope matrix multiply configuration the driver supports.
D3D12_FEATURE_DATA_LINEAR_ALGEBRA_OPERATION_ENUMERATION enumerate = {};
enumerate.OperationType = D3D12_LINEAR_ALGEBRA_OPERATION_TYPE_WAVE_MATRIX_MULTIPLY;

// First call: get the count.
HRESULT hr = device->CheckFeatureSupport(
    D3D12_FEATURE_LINEAR_ALGEBRA_OPERATION_ENUMERATION,
    &enumerate,
    sizeof(enumerate));

if (SUCCEEDED(hr) && enumerate.NumEntries > 0)
{
    std::vector<D3D12_LINEAR_ALGEBRA_WAVE_MATRIX_MULTIPLY_ENUMERATION_ENTRY> entries(
        enumerate.NumEntries);
    enumerate.WaveMatrixMultiply = entries.data();

    // Second call: fill the array.
    hr = device->CheckFeatureSupport(
        D3D12_FEATURE_LINEAR_ALGEBRA_OPERATION_ENUMERATION,
        &enumerate,
        sizeof(enumerate));

    // entries[] now holds (MinWaveSize, MaxWaveSize, A, B, Acc, SupportFlags, Shape) tuples
    // and the application can pick the configuration that best fits its workload.
}
```


## D3D12_LINEAR_ALGEBRA_TIER

The `D3D12_LINEAR_ALGEBRA_TIER` enumeration is the primary mechanism for standardizing linear algebra support across D3D12 hardware. By defining discrete tiers with mandatory format and dimension support, this system eliminates the need for developers to query and handle dozens of individual capability bits for different combinations of data types, matrix sizes, and operation scopes. Each tier represents a well-tested, cohesive set of capabilities that hardware vendors commit to supporting in their entirety, ensuring that applications can target a specific tier and rely on all associated features being available.

```cpp
typedef enum D3D12_LINEAR_ALGEBRA_TIER
{
    D3D12_LINEAR_ALGEBRA_TIER_NOT_SUPPORTED = 0,
    D3D12_LINEAR_ALGEBRA_TIER_1 = 1,
} D3D12_LINEAR_ALGEBRA_TIER;
```

**Members:**

- **D3D12_LINEAR_ALGEBRA_TIER_NOT_SUPPORTED** - The device does not support linear algebra operations.

- **D3D12_LINEAR_ALGEBRA_TIER_1** - The device supports Tier 1 linear algebra operations. See the [Tier 1 Support](#tier-1-support) section.

**Usage:**

Applications can query for linear algebra support using the feature check:

```cpp
D3D12_FEATURE_DATA_LINEAR_ALGEBRA_SUPPORT linearAlgebraSupport = {};
HRESULT hr = device->CheckFeatureSupport(
    D3D12_FEATURE_LINEAR_ALGEBRA_SUPPORT,
    &linearAlgebraSupport,
    sizeof(linearAlgebraSupport));

if (SUCCEEDED(hr) && linearAlgebraSupport.LinearAlgebraTier >= D3D12_LINEAR_ALGEBRA_TIER_1)
{
    // Device supports Tier 1 linear algebra operations
}
```
## Tier 1 Support

As mentioned in the [introduction](#introduction), the primary capability being queried here is data types and tile shapes. Tier 1 devices must support:

### Matrix-Matrix Operations

  A         |  B         |   Acc.  | Native   |
------------|------------|---------|----------|
  UInt8     |  UInt8     |  SInt32 | Required |
  SInt8     |  SInt8     |  SInt32 | Required |
  Fp16      |  Fp16      |  Fp16   | Optional |

**Column Definitions:**

- **A** and **B**: The data format for input matrices A and B. Tier 1 only requires support for matched A/B types; integer signedness is not required to match between A and B. A driver may expose mixed-signedness A/B combinations as an additional capability through the granular [wave-scope](#d3d12_linear_algebra_wave_matrix_multiply_support) and [threadgroup-scope](#d3d12_linear_algebra_threadgroup_matrix_multiply_support) queries, or discoverable via the [Operation Enumeration API](#operation-enumeration-api).
- **Acc.**: The accumulator format used for intermediate and final results. Higher precision accumulators prevent overflow and maintain accuracy during computation.

It is valid for drivers to use higher internal precision for Fp16 multiplication and then convert final results to Fp16.

### Vector-Matrix Operations

Vector | Matrix   | Result | Native   |
-------|----------|--------|----------|
SInt8  | SInt8    | SInt32 | Required |
UInt8  | UInt8    | SInt32 | Required |
Fp32   | SInt8    | SInt32 | Required |
Fp16   | Fp16     | Fp16   | Required |
Fp16   | Fp8_E4M3 | Fp16   | Optional |
Fp16   | Fp8_E5M2 | Fp16   | Optional |

Column meaning, HLSL supply paths, and conversion behavior are described under [D3D12_LINEAR_ALGEBRA_THREAD_VECTOR_MATRIX_MULTIPLY_SUPPORT](#d3d12_linear_algebra_thread_vector_matrix_multiply_support). The **Native** column governs whether tier-1 implementations are required to accelerate the row natively:

* `Required` -- implementations MUST accept the row and execute it natively (no `EMULATED_INPUTS` or `EMULATED_OUTPUTS`).
* `Optional` -- implementations MUST accept the row but MAY emulate it; the granular query reports the emulation strategy via `EMULATED_INPUTS` and/or `EMULATED_OUTPUTS`.

Integer signedness is not required to match between the vector type and the matrix type. Every row in the table happens to list matched-signedness combinations because mixed-signedness support is not part of the tier-1 contract, but a driver may expose any mixed-signedness combination as an additional capability through the granular and enumeration queries.

Note: Bias is omitted from the table. It is required that bias types matching the result type must be supported, as well as `NONE` (no bias).

Note that FP8 data types are required to be supported for inputs, but it is recognized that these may not be natively supported. If these are not natively supported, the driver is required to emulate them. This emulation is required, recognizing that applications will not want to ship multiple versions of models, and if a model is quantized to FP8, applications should be able to ship the smallest version of that model. If FP8 was optional, it would increase the install footprint of applications leveraging this functionality.

Due to hardware diversity, both emulation of the conversion to FP8, as well as emulation of FP8->FP16 multiplication are allowed. Transposing loads and stores are not required for any format.

### Native Matrix Dimensions

For wave-scope and threadgroup-scope multiplication, the driver natively supports one or more tile shapes per type combination, discoverable via the [Operation Enumeration API](#operation-enumeration-api). Application matrix shapes are accepted by the driver -- and reported as supported by the granular [wave-scope](#d3d12_linear_algebra_wave_matrix_multiply_support) and [threadgroup-scope](#d3d12_linear_algebra_threadgroup_matrix_multiply_support) queries -- when they are an integer multiple of one of those native shapes in each dimension; matrices smaller than the smallest native shape are not supported.

For a supported wave-scope or threadgroup-scope data type, there must be at least one reported shape whose *largest* component is less than or equal to 16 for types that are 16-bit or larger, or whose largest bit size is 256 for types that are smaller than 16-bit. This ensures that 16x16x16 will always be a valid tile shape for 16-bit types, while smaller types may support a minimum size of 32x16x16.

Applications that want to use smaller shapes will need to query them on a case-by-case basis. Hardware that wants to expose larger tile sizes must do so alongside a size that meets this requirement.

Note that there is no requirement around thread-scope vector-matrix multiplication dimensions.

### Outer Product

No specific formats are required to be supported for tier 1.

### Accumulation Store

Accumulation store requires atomic addition to memory, either for vectors or matrices. No formats are required to be supported for tier 1. Optional formats to support are FP16 and FP32.

## Runtime Validation

The HLSL compiler emits detailed metadata about vector and matrix operations used in shaders as part of the Pipeline State Validation (PSV0) section of the shader bytecode. This metadata includes information about the specific linear algebra operations invoked, the data formats used (input, accumulator, and output types), matrix dimensions, and operation scopes (Thread, Wave, or ThreadGroup). When a shader containing linear algebra operations is used to create a pipeline state object, the D3D12 runtime parses this PSV0 metadata and validates it against the hardware's reported `D3D12_FEATURE_LINEAR_ALGEBRA_MATRIX_OPERATION_SUPPORT` capabilities. If the shader requests operations, formats, or dimensions that are not supported by the driver, the runtime will fail pipeline creation with a descriptive error indicating which specific capability requirement was not met.

## Convert Matrix to desired layout and type

The matrices used in the Linear Algebra load/store/accumulate intrinsics are (RW)ByteAddressBuffers with implementation specific alignment constraints and performance characteristics. We introduce a driver side API to change the layout and dataype of the weight matrix between layouts in `D3D12_LINEAR_ALGEBRA_MATRIX_LAYOUT` and datatypes in `D3D12_LINEAR_ALGEBRA_DATATYPE`.

```c++
enum D3D12_LINEAR_ALGEBRA_MATRIX_LAYOUT
{
    D3D12_LINEAR_ALGEBRA_MATRIX_LAYOUT_ROW_MAJOR,
    D3D12_LINEAR_ALGEBRA_MATRIX_LAYOUT_COLUMN_MAJOR,
    D3D12_LINEAR_ALGEBRA_MATRIX_LAYOUT_MUL_OPTIMAL,
    D3D12_LINEAR_ALGEBRA_MATRIX_LAYOUT_OUTER_PRODUCT_OPTIMAL,
}
```

### Query Destination Size

The destination buffer (to hold the matrix) size can be implementation dependent. The API `GetLinearAlgebraMatrixConversionDestinationInfo` is added to query the size of the destination buffer in the desired layout and datatype. It takes a pointer to `D3D12_LINEAR_ALGEBRA_MATRIX_CONVERSION_DEST_INFO` descriptor that provides the inputs required to calculate the necessary size. The same descriptor, updated with the calculated output size, is then passed to the conversion API. 

The `DestSize` and `DestStride` must be a multiple of 16 bytes. The `DestVA` must be 128-byte aligned.

```c++

// Descriptor to query the destination buffer size
typedef struct D3D12_LINEAR_ALGEBRA_MATRIX_CONVERSION_DEST_INFO { 
    UINT                                   DestSize;      // !< [out]Destination buffer size in bytes
                                                          // required for conversion 
    D3D12_LINEAR_ALGEBRA_MATRIX_LAYOUT     DestLayout;    // !< [in] Is the layout the matrix is converted to
    UINT                                   DestStride;    // !< [in] Is the number of bytes between a consecutive 
                                                          // row or column (depending on DestLayout) of the 
                                                          // destination matrix if it is row-major or 
                                                          // column-major.
    UINT                                   NumRows;       // !< [in] Is the number of rows in the matrix. 
    UINT                                   NumColumns;    // !< [in] Is the number of columns in the matrix. 
    D3D12_LINEAR_ALGEBRA_DATATYPE          DestDataType;  // !< [in] the type of a destination matrix element. 
};

// An API to return the number of bytes required in the destination buffer to
// store the result of conversion. The size of the destination is a function of
// the destination layout information and does not depend on the source layout
// information.

void ID3D12DevicePreview::GetLinearAlgebraMatrixConversionDestinationInfo(
    D3D12_LINEAR_ALGEBRA_MATRIX_CONVERSION_DEST_INFO* pDesc);

```

### Conversion descriptors

After the size of the destination buffer is known, user can pass the `D3D12_LINEAR_ALGEBRA_MATRIX_CONVERSION_DEST_INFO` descriptor along with
information of source layout and datatype in `D3D12_LINEAR_ALGEBRA_MATRIX_CONVERSION_SOURCE_INFO` and addresses of the source and destination buffers to the layout and datatype conversion API.

```c++

// GPU VAs of source and destination buffers

typedef struct D3D12_LINEAR_ALGEBRA_MATRIX_CONVERSION_DATA {
    D3D12_GPU_VIRTUAL_ADDRESS               DestVA;               //!< [inout] GPU VA of destination 
                                                                  // buffer
    D3D12_GPU_VIRTUAL_ADDRESS               SrcVA;                //!< [in]    GPU VA of source 
                                                                  // buffer
};
 
// Source information descriptor. Destination information comes from 
// D3D12_LINEAR_ALGEBRA_MATRIX_CONVERSION_DEST_INFO

typedef struct D3D12_LINEAR_ALGEBRA_MATRIX_CONVERSION_SRC_INFO {
    UINT                                    SrcSize;                // !< [in] Is the length in bytes of 
                                                                    // srcData    
    D3D12_LINEAR_ALGEBRA_DATATYPE           SrcDataType;            // !< [in] Is the type of a 
                                                                    // source matrix 
                                                                    // element        
    D3D12_LINEAR_ALGEBRA_MATRIX_LAYOUT      SrcLayout;              // !< [in] Is the layout of the 
                                                                    // source matrix.
    UINT                                    SrcStride;              // !< [in] Is the number of bytes  
                                                                    // between a consecutive row or column 
                                                                    // (depending on srcLayout) 
                                                                    // of the source matrix, if it is row-major 
                                                                    // or column-major.   
};

// Descriptor passed to the conversion API
typedef struct D3D12_LINEAR_ALGEBRA_MATRIX_CONVERSION_INFO {
    D3D12_LINEAR_ALGEBRA_MATRIX_CONVERSION_DEST_INFO      DestInfo;
    D3D12_LINEAR_ALGEBRA_MATRIX_CONVERSION_SRC_INFO       SrcInfo;    
    D3D12_LINEAR_ALGEBRA_MATRIX_CONVERSION_DATA           DataDesc;   
};
```

### Conversion APIs

New API is added to the ID3D12CommandList interface. Multiple conversions can be done in a single call of the API. The number of descriptors pointed to by pDesc is specified using DescCount. If DestSize passed to this API is less than the number of bytes returned in call to `GetLinearAlgebraMatrixConversionDestinationInfo`, behavior is undefined.

```c++
// Converts source matrix to desired layout and datatype
void ID3D12GraphicsCommandListPreview::ConvertLinearAlgebraMatrix(
    D3D12_LINEAR_ALGEBRA_MATRIX_CONVERSION_INFO* pDesc,
    UINT DescCount);

```

*Valid Usage:* 

* If SrcLayout is row-major or column-major, then SrcStride should be greater than the length of a row/column, and a multiple of the element size.
* If DestLayout is row-major or column-major, then DestStride should be greater than the length of a row/column, and a multiple of 16.
* SrcComponentType and DestComponentType must be identical. In other words, this conversion only modifies memory layout and not data.
* SrcComponentType and DestComponentType must be valid for either vector-matrix or matrix-matrix multiplication.

*CommandList interactions:*

- Synchronization around `ConvertLinearAlgebraMatrix` calls:
   - Legacy Barrier
     - Source buffer: Must be in `D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE` state
     - Dest buffer: Must be in `D3D12_RESOURCE_STATE_UNORDERED_ACCESS` state
     - UAV barrier synchronizes writes to the destination
   - Enhanced Barrier:
     - Source buffer access: `D3D12_BARRIER_ACCESS_SHADER_RESOURCE`
     - Dest buffer access: `D3D12_BARRIER_ACCESS_UNORDERED_ACCESS`
     - Sync point: `D3D12_BARRIER_SYNC_CONVERT_LINEAR_ALGEBRA_MATRIX`
 - Predication is supported
 - Available in Compute or Graphics CommandLists
 - Not supported in Bundles

*Usage Example:*

```c++

D3D12_LINEAR_ALGEBRA_MATRIX_CONVERSION_INFO infoDesc = 
{ 
    // DestInfo
    {
        0,                                                              // DestSize to be populated by 
                                                                        // driver implementation
        D3D12_LINEAR_ALGEBRA_MATRIX_LAYOUT_MUL_OPTIMAL,                 // convert to mul optimal layout
        0,                                                              // stride is ignored since optimal layout 
                                                                        // is implementation dependent
        numRows,                                                        // number of rows in weight matrix to be 
                                                                        // converted
        numColumns,                                                     // number of columns in weight matrix to 
                                                                        // be converted
        D3D12_LINEAR_ALGEBRA_DATATYPE_FLOAT8_E4M3                       // FP8 datatype
    },

    //SrcInfo
    {
        srcSize,                                                        // number of bytes of matrix in source 
                                                                        // layout and datatype
        D3D12_LINEAR_ALGEBRA_DATATYPE_FLOAT8_E4M3,                      // FP8 datatype
        D3D12_LINEAR_ALGEBRA_MATRIX_LAYOUT_ROW_MAJOR,                   // convert from row major layout
        (numColumns * sizeof(float))                                    // row major stride without padding
    },

    //DataDesc
    {
        0,                                                              // dest buffer address not known yet. 
                                                                        // Will be intialized after destSize 
                                                                        // query
        srcVA                                                           // GPU VA of src buffer
    }                                              
}

// Query destSize
pD3D12Device->GetLinearAlgebraMatrixConversionDestinationInfo(&infoDesc.DestInfo);

// After the size is known, initialize the DestVA. Offset the SrcVA with DestSize to get DestVA 
// (alignment requirements are ignored for simplicity)
infoDesc.DataDesc.DestVA = srcVA + infoDesc.DestInfo.DestSize;

// Perform the conversion
pD3D12CommandList->ConvertLinearAlgebraMatrix(&infoDesc, 0);

```
## D3D12 DDI Additions

The linear algebra DDI is exposed under D3D12 core DDI version 0115, using
function table type `D3D12DDI_TABLE_TYPE_0115_LINEAR_ALGEBRA` and `D3D12DDI_FEATURE`
enum value 15 (shared with cooperative vectors). The feature version this spec
defines is `D3D12DDI_FEATURE_VERSION_LINEAR_ALGEBRA_0115_2`; drivers reporting
this feature version MUST implement every requirement described below.

#### Granular caps query

`D3D12DDICAPS_TYPE_LINEAR_ALGEBRA_MATRIX_OPERATION_SUPPORT` is the per-configuration
"is this specific configuration supported?" caps query. Its data struct
`D3D12DDI_LINEAR_ALGEBRA_MATRIX_OPERATION_SUPPORT_0115_2` mirrors the API
[D3D12_FEATURE_DATA_LINEAR_ALGEBRA_MATRIX_OPERATION_SUPPORT](#d3d12_feature_data_linear_algebra_matrix_operation_support)
field-for-field, with each per-op-type DDI struct mirroring its API counterpart
(single-shape input, single-result output). Drivers MAY implement this caps
query on a per-operation-type basis; see Per-op-type query form advertisement
below.

#### Enumeration caps query

`D3D12DDICAPS_TYPE_LINEAR_ALGEBRA_OPERATION_ENUMERATION` is the
"give me every native configuration for this operation type" caps query. Its
data struct `D3D12DDI_LINEAR_ALGEBRA_OPERATION_ENUMERATION_0115_2` mirrors the
API [D3D12_FEATURE_DATA_LINEAR_ALGEBRA_OPERATION_ENUMERATION](#d3d12_feature_data_linear_algebra_operation_enumeration)
field-for-field. The union holds DDI-namespace pointer types
(`D3D12DDI_LINEAR_ALGEBRA_*_ENUMERATION_ENTRY_0115_2 *`) that mirror their API
counterparts. The runtime services the caps query with the standard two-call
sequence (size query, then array fill); the driver MUST return the same
`NumEntries` value across the two calls for a given operation type.

The enumerated table is required to be stable for the lifetime of the device
and independent of any per-process or per-pipeline state. The runtime caches
the table at device init and uses it both to serve application enumeration
queries and to synthesize per-configuration answers for operation types where
the driver does not implement the granular caps query.

Drivers MUST implement this caps query for every operation type their device
supports.

#### Per-op-type query form advertisement

Drivers advertise which operation types they serve granularly via a caps query:

```c
typedef enum D3D12DDI_LINEAR_ALGEBRA_QUERY_FORM_FLAGS_0115_2
{
    D3D12DDI_LINEAR_ALGEBRA_QUERY_FORM_FLAG_NONE        = 0x0,
    D3D12DDI_LINEAR_ALGEBRA_QUERY_FORM_FLAG_GRANULAR    = 0x1,
    D3D12DDI_LINEAR_ALGEBRA_QUERY_FORM_FLAG_ENUMERATION = 0x2,
} D3D12DDI_LINEAR_ALGEBRA_QUERY_FORM_FLAGS_0115_2;

typedef struct D3D12DDI_LINEAR_ALGEBRA_QUERY_FORMS_0115_2
{
    D3D12DDI_LINEAR_ALGEBRA_QUERY_FORM_FLAGS_0115_2 MatrixConstruction;
    D3D12DDI_LINEAR_ALGEBRA_QUERY_FORM_FLAGS_0115_2 WaveMatrixMultiply;
    D3D12DDI_LINEAR_ALGEBRA_QUERY_FORM_FLAGS_0115_2 ThreadGroupMatrixMultiply;
    D3D12DDI_LINEAR_ALGEBRA_QUERY_FORM_FLAGS_0115_2 ThreadVectorMatrixMultiply;
    D3D12DDI_LINEAR_ALGEBRA_QUERY_FORM_FLAGS_0115_2 ThreadOuterProduct;
    D3D12DDI_LINEAR_ALGEBRA_QUERY_FORM_FLAGS_0115_2 AtomicAccumulateStore;
} D3D12DDI_LINEAR_ALGEBRA_QUERY_FORMS_0115_2;
```

Queried via caps type `D3D12DDICAPS_TYPE_LINEAR_ALGEBRA_QUERY_FORMS` once at
device init. Required behavior:

* Each field MUST include `ENUMERATION` for operation types the device supports
  and MUST be `NONE` for operation types the device does not support.
* `GRANULAR` is set on a field when the driver implements the granular caps
  handler for that operation type. The runtime forwards application granular
  queries to the driver when this flag is set, and synthesizes answers from
  the cached enumeration table otherwise. Drivers without efficient
  predicate-based granular logic should leave this flag clear.
* Reported form support is fixed for the lifetime of the device.

When both forms are advertised for an operation type, granular and enumeration
results MUST be self-consistent: for every `(types, shape)` combination the
enumeration would expand to (including every integer-multiple shape of any
native shape), the granular query MUST report supported, and vice versa. The
D3D12 debug layer cross-checks this invariant on every application-level
granular call when both forms are advertised.

#### `_1` deprecation

The prior preview release advertised `D3D12DDI_FEATURE_VERSION_LINEAR_ALGEBRA_0115_1`,
with a different granular caps struct shape -- `MATRIX_CONSTRUCTION_SUPPORT`
returned a single `MinM/MinK/MinN` triple, and `WAVE_MATRIX_MULTIPLY_SUPPORT`
returned a native-shape array -- and no enumeration caps query. `_1` is
deprecated; new drivers SHOULD report `_2` exclusively.

The runtime continues to load `_1` drivers and exposes the granular
[API](#granular-capability-query-api) on them by translating each `_2`-shaped
application query into the corresponding `_1` DDI call(s):

* `MATRIX_CONSTRUCTION_SUPPORT`: runtime reads `MinM/MinK/MinN` from the `_1`
  DDI and returns `Supported = TRUE` iff the application's `Shape` is an integer
  multiple of `(MinM, MinK, MinN)` in each dimension. (The `_1` DDI only reports
  a single tiling, so drivers using `_1` cannot express multi-tiling support;
  this is a `_1` limitation, not a runtime translation issue.)
* `WAVE_MATRIX_MULTIPLY_SUPPORT`: runtime reads the native shape array from the
  `_1` DDI and returns supported iff the application's `Shape` is an integer
  multiple of any reported native shape in each dimension.
* `THREADGROUP_MATRIX_MULTIPLY_SUPPORT`: shape input was already present in
  `_1`; the runtime forwards the query directly.
* Other operation types: `_1` and `_2` granular shapes are identical; the
  runtime forwards directly.

The [Operation Enumeration API](#operation-enumeration-api) is not exposed on
`_1` drivers -- `CheckFeatureSupport` for
`D3D12_FEATURE_LINEAR_ALGEBRA_OPERATION_ENUMERATION` returns
`DXGI_ERROR_UNSUPPORTED` on a device backed by a `_1` driver, regardless of
operation type. Applications that depend on enumeration must fall back to the
granular query or report an unsupported configuration to the user.

## Change Log
Version | Date | Description
------- | ---- | -----------
0.1 | Oct 2025 | Skeleton created (no content filled)
0.2 | Nov 2025 | Added the basic outlines of TIER_1 support
0.3 | Nov 2025 | Added the individual support query
0.4 | Dec 2025 | Reworked and reorganized
0.5 | Dec 2025 | FP8 is required for tier 1. Merge with https://github.com/microsoft/hlsl-specs/blob/main/proposals/0029-cooperative-vector.md
0.6 | Mar 2026 | Add transpose, outer product, relax tier 1 restrictions.
0.7 | Mar 2026 | LINALG -> LINEAR ALGEBRA. Address one more round of feedback.
0.8 | Apr 2026 | Add matrix construction caps.
0.9 | Jun 2026 | Granular queries take a single shape (input) and return supported (output); native shape discovery moves to the new Operation Enumeration API (#240, #244, customer ask). Vector-Matrix table split into interpretation/matrix/result with conversion semantics called out (#245).