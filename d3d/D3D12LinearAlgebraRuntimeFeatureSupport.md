# D3D12 Linear Algebra Runtime Feature Support <!-- omit in toc -->

Version 0.8 (Draft)

---

## Contents <!-- omit in toc -->

- [Introduction](#introduction)
- [Granular Capability Query API](#granular-capability-query-api)
  - [D3D12\_LINEAR\_ALGEBRA\_OPERATION\_TYPE](#d3d12_linear_algebra_operation_type)
  - [D3D12\_LINEAR\_ALGEBRA\_DATATYPE](#d3d12_linear_algebra_datatype)
  - [D3D12\_LINEAR\_ALGEBRA\_OPERATION\_SUPPORT\_QUERY](#d3d12_linear_algebra_operation_support_query)
    - [D3D12\_LINEAR\_ALGEBRA\_MATRIX\_CONSTRUCTION\_SUPPORT](#d3d12_linear_algebra_matrix_construction_support)
    - [D3D12\_LINEAR\_ALGEBRA\_MATRIX\_MULTIPLY\_SHAPE](#d3d12_linear_algebra_matrix_multiply_shape)
    - [D3D12\_LINEAR\_ALGEBRA\_WAVE\_MATRIX\_MULTIPLY\_INPUTS](#d3d12_linear_algebra_wave_matrix_multiply_inputs)
    - [D3D12\_LINEAR\_ALGEBRA\_MULTIPLICATION\_SUPPORT\_FLAGS](#d3d12_linear_algebra_multiplication_support_flags)
    - [D3D12\_LINEAR\_ALGEBRA\_WAVE\_MATRIX\_MULTIPLY\_SUPPORT](#d3d12_linear_algebra_wave_matrix_multiply_support)
    - [D3D12\_LINEAR\_ALGEBRA\_THREADGROUP\_MATRIX\_MULTIPLY\_SUPPORT](#d3d12_linear_algebra_threadgroup_matrix_multiply_support)
    - [D3D12\_LINEAR\_ALGEBRA\_THREAD\_VECTOR\_MATRIX\_MULTIPLY\_SUPPORT](#d3d12_linear_algebra_thread_vector_matrix_multiply_support)
    - [D3D12\_LINEAR\_ALGEBRA\_THREAD\_OUTER\_PRODUCT\_SUPPORT](#d3d12_linear_algebra_thread_outer_product_support)
    - [D3D12\_LINEAR\_ALGEBRA\_ATOMIC\_ACCUMULATE\_STORE\_SUPPORT](#d3d12_linear_algebra_atomic_accumulate_store_support)
    - [D3D12\_FEATURE\_DATA\_LINEAR\_ALGEBRA\_MATRIX\_OPERATION\_SUPPORT](#d3d12_feature_data_linear_algebra_matrix_operation_support)
  - [Usage Example](#usage-example)
- [D3D12\_LINEAR\_ALGEBRA\_TIER](#d3d12_linear_algebra_tier)
- [Tier 1 Support:](#tier-1-support)
  - [Matrix-Matrix Operations:](#matrix-matrix-operations)
  - [Vector-Matrix Operations:](#vector-matrix-operations)
  - [Wave-Scope Matrix Dimensions](#wave-scope-matrix-dimensions)
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

While the tier system provides a convenient way to target well-defined hardware profiles, some applications may need to query support for specific matrix operation configurations that fall outside standard tier definitions or to leverage vendor-specific capabilities. The D3D12 runtime provides a granular capability query API that allows applications to check whether a particular combination of operation type, data formats, dimensions, and scope is supported on the current device.

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

#### D3D12_LINEAR_ALGEBRA_MATRIX_CONSTRUCTION_SUPPORT
``` cpp
typedef struct D3D12_LINEAR_ALGEBRA_MATRIX_CONSTRUCTION_SUPPORT
{
    // Inputs
    D3D12_LINEAR_ALGEBRA_DATATYPE ComponentType;
    UINT WaveSize;

    // Outputs
    UINT MinM;
    UINT MinK;
    UINT MinN;
} D3D12_LINEAR_ALGEBRA_MATRIX_CONSTRUCTION_SUPPORT;
```

This query indicates a driver's level of support for general operations on wave-scope and group-scope matrices. Since matrices at these scopes can be loaded, stored, manipulated, and converted without actually being used in a multiplication operation, multiplication support is not sufficient. Essentially, a driver that responds positively to this query indicates that it knows how to lay out these components in registers. If a driver supports a particular component type, then it must support:
* Loading a matrix of that type from buffer or group-shared memory, and similarly for storing (`Load()`/`Store()`).
* Operating on elements of a matrix (`Length()`/`GetCoordinate()`/`Get()`/`Set()`/`Splat()`).
* Being used as a source or destination of a conversion (`Cast()`).

If a component type is not supported, `MinM`, `MinK`, and `MinN` will all be set to 0. Otherwise, all three must be nonzero, indicating support for A matrices (MxK), B matrices (KxN), and accumulator matrices (MxN).

#### D3D12_LINEAR_ALGEBRA_MATRIX_MULTIPLY_SHAPE
``` cpp
typedef struct D3D12_LINEAR_ALGEBRA_MATRIX_MULTIPLY_SHAPE
{
    UINT M;  // Rows in matrix A
    UINT K;  // Columns in matrix A / Rows in matrix B
    UINT N;  // Columns in matrix B
} D3D12_LINEAR_ALGEBRA_MATRIX_MULTIPLY_SHAPE;
```

- `M`, `K`, `N` - Matrix dimensions following the formula M×K * K×N = M×N.

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

    // Outputs
    D3D12_LINEAR_ALGEBRA_MULTIPLICATION_SUPPORT_FLAGS SupportFlags;
    UINT NumShapes;
    D3D12_LINEAR_ALGEBRA_MATRIX_MULTIPLY_SHAPE *Shapes;
} D3D12_LINEAR_ALGEBRA_WAVE_MATRIX_MULTIPLY_SUPPORT;
```

- `Inputs` - The type of operation being queried.

- `SupportFlags` - Indicates whether the operation is supported, and whether any emulation of the requested data types would occur.

- `NumShapes` - On input, the size of the `ValidShapes` array. On output, the number of valid tile shapes. If the operation is not supported, this will be 0.

- `Shapes` - On input, array of size `NumShapes` (null allowed if `NumShapes` is 0). If non-null, on output the array elements indicate native matrix shapes for the input matrix properties. Valid application matrix shapes are allowed to use an integer multiple of one of these resulting shapes. Note that more than one may be valid and it is up to the driver to choose a tiling strategy, for example a 32x32x16 matrix can be tiled using either 16x16x16 tiles or 8x32x16 tiles. Also note that there is no limitation on maximum matrix size, though larger matrices may result in significantly adverse performance.

#### D3D12_LINEAR_ALGEBRA_THREADGROUP_MATRIX_MULTIPLY_SUPPORT
``` cpp
typedef struct D3D12_LINEAR_ALGEBRA_THREADGROUP_MATRIX_MULTIPLY_SUPPORT
{
    // Inputs
    D3D12_LINEAR_ALGEBRA_WAVE_MATRIX_MULTIPLY_INPUTS WaveInputs;
    D3D12_LINEAR_ALGEBRA_MATRIX_MULTIPLY_SHAPE Shape;

    // Outputs
    D3D12_LINEAR_ALGEBRA_MULTIPLICATION_SUPPORT_FLAGS SupportFlags;
    UINT MinThreadGroupSize;
    UINT MaxThreadGroupSize;
    UINT PreferredThreadGroupSize;
} D3D12_LINEAR_ALGEBRA_THREADGROUP_MATRIX_MULTIPLY_SUPPORT;
```

- `WaveInputs` - The type of operation being queried.

- `Shape` - The size of the matrix.

- `SupportFlags` - Indicates whether the operation is supported, and whether any emulation of the requested data types would occur.

- `MinThreadGroupSize` - The minimum number of threads in a group that can perform this multiplication.

- `MaxThreadGroupSize` - The maximum number of threads in a group that can perform this multiplication. Valid sizes are then multiples of the minimum, up to and including the maximum.

- `PreferredThreadGroupSize` - The driver's estimate for the most efficient thread group size to perform this multiplication. This may be zero, indicating that there are trade-offs (e.g. register pressure vs throughput) and it is not possible for the driver to report an optimal size.

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

- `VectorInputType` - The interpreted type of the input HLSL vector. If the HLSL vector is an `InterpretedVector`, this is the interpreted type, otherwise this is the native HLSL vector element type.

- `MatrixInputType` - The type of the input matrix. If the vector data is packed, this must match the unpacked type. If the vector data is not packed, then the vector data may be converted to this format for the operation.

- `BiasInputType` - The type of data that's added to the multiplication result before returning the result.

- `VectorResultType` - The type of the bias and result vectors.

- `SupportFlags` - Indicates level of support for this operation.

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
- `OutputComponentType` - Type of the output vector.
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
typedef struct D3D12_FEATURE_DATA_MATRIX_OPERATION_SUPPORT
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
- 
- `ThreadOuterProductSupport` - Used when `OperationType` is `D3D12_LINEAR_ALGEBRA_OPERATION_TYPE_THREAD_OUTER_PRODUCT`. Output formats from outer product must be supported for accumulate-store.

- `AccumulateStore` - Used when `OperationType` is `D3D12_LINEAR_ALGEBRA_OPERATION_TYPE_ATOMIC_ACCUMULATE_STORE`.

### Usage Example
``` cpp
// I have a shader that tries to use wave scope matrix multiplication with MxKxN = 64x64x64, FP16xFP16->FP32.
// Query if it's valid for me to use that shader.
D3D12_FEATURE_DATA_MATRIX_OPERATION_SUPPORT opSupport = {};
opSupport.OperationType = D3D12_LINEAR_ALGEBRA_OPERATION_TYPE_WAVE_MATRIX_MULTIPLY;
opSupport.WaveMatrixMultiply.Inputs.WaveSize = 0; // I don't care about the wave size
opSupport.WaveMatrixMultiply.Inputs.MatrixAComponentType = D3D12_LINEAR_ALGEBRA_DATATYPE_FLOAT16;
opSupport.WaveMatrixMultiply.Inputs.MatrixBComponentType = D3D12_LINEAR_ALGEBRA_DATATYPE_FLOAT16;
opSupport.WaveMatrixMultiply.Inputs.AccumulatorComponentType = D3D12_LINEAR_ALGEBRA_DATATYPE_FLOAT32;
opSupport.WaveMatrixMultiply.NumShapes = 0;

HRESULT hr = device->CheckFeatureSupport(
    D3D12_FEATURE_MATRIX_OPERATION_SUPPORT,
    &opSupport,
    sizeof(opSupport));

if (SUCCEEDED(hr) && opSupport.WaveMatrixMultiply.NumShapes > 0)
{
    // Device supports FP16xFP16->FP32, check if 64x64x64 will work
    std::vector<D3D12_LINEAR_ALGEBRA_MATRIX_MULTIPLY_SHAPE> shapes(opSupport.WaveMatrixMultiply.NumShapes);
    opSupport.WaveMatrixMultiply.Shapes = shapes.data();
    hr = device->CheckFeatureSupport(
        D3D12_FEATURE_MATRIX_OPERATION_SUPPORT,
        &opSupport,
        sizeof(opSupport));
    if (SUCCEEDED(hr))
    {
        for (D3D12_LINEAR_ALGEBRA_MATRIX_MULTIPLY_SHAPE &shape : shapes)
        {
            if ((64 % shape.M) == 0 && (64 % shape.K) == 0 && (64 % shape.N) == 0)
            {
                // The driver can support this shape
                break;
            }
        }
    }
}

// Query vector-matrix multiply support
D3D12_FEATURE_DATA_MATRIX_OPERATION_SUPPORT vecMatSupport = {};
vecMatSupport.OperationType = D3D12_LINEAR_ALGEBRA_OPERATION_TYPE_THREAD_VECTOR_MATRIX_MULTIPLY;
vecMatSupport.ThreadVectorMatrixMultiply.VectorInputType = D3D12_LINEAR_ALGEBRA_DATATYPE_FLOAT16;
vecMatSupport.ThreadVectorMatrixMultiply.MatrixInputType = D3D12_LINEAR_ALGEBRA_DATATYPE_FLOAT16;
vecMatSupport.ThreadVectorMatrixMultiply.BiasInputType = D3D12_LINEAR_ALGEBRA_DATATYPE_NONE;
vecMatSupport.ThreadVectorMatrixMultiply.VectorResultType = D3D12_LINEAR_ALGEBRA_DATATYPE_FLOAT16;

hr = device->CheckFeatureSupport(
    D3D12_FEATURE_MATRIX_OPERATION_SUPPORT,
    &vecMatSupport,
    sizeof(vecMatSupport));

if (SUCCEEDED(hr) && vecMatSupport.ThreadVectorMatrixMultiply.Supported)
{
    // Device supports this vector-matrix operation configuration
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
## Tier 1 Support:

As mentioned in the [introduction](#introduction), the primary capability being queried here is data types and tile shapes. Tier 1 devices must support:

### Matrix-Matrix Operations:

  A         |  B         |   Acc.  | Native   |
------------|------------|---------|----------|
  UInt8     |  UInt8     |  SInt32 | Required |
  SInt8     |  SInt8     |  SInt32 | Required |
  Fp16      |  Fp16      |  Fp16   | Optional |

**Column Definitions:**

- **A** and **B**: The data format for input matrices A and B. Some devices may support having different signedness for A and B matrices, but it is not required, only exactly matching A and B matrix types are required.
- **Acc.**: The accumulator format used for intermediate and final results. Higher precision accumulators prevent overflow and maintain accuracy during computation.

It is valid for drivers to use higher internal precision for Fp16 multiplication and then convert final results to Fp16.

### Vector-Matrix Operations:

Vector | Matrix   | Result | Native   |
-------|----------|--------|----------|
SInt8  | SInt8    | SInt32 | Required |
UInt8  | UInt8    | SInt32 | Required |
Fp32   | SInt8    | SInt32 | Required |
Fp16   | Fp16     | Fp16   | Required |
Fp16   | Fp8_E4M3 | Fp16   | Optional |
Fp16   | Fp8_E5M2 | Fp16   | Optional |

Note: Bias is omitted from the table. It is required that bias types matching the result type must be supported, as well as `NONE` (no bias).

Note that FP8 data types are required to be supported for inputs, but it is recognized that these may not be natively supported. If these are not natively supported, the driver is required to emulate them. This emulation is required, recognizing that applications will not want to ship multiple versions of models, and if a model is quantized to FP8, applications should be able to ship the smallest version of that model. If FP8 was optional, it would increase the install footprint of applications leveraging this functionality.

Due to hardware diversity, both emulation of the conversion to FP8, as well as emulation of FP8->FP16 multiplication are allowed. Transposing loads and stores are not required for any format.

### Wave-Scope Matrix Dimensions

For a supported data type, there must be at least one reported dimension result whose *largest* component is less than or equal to 16 for types that are 16-bit or larger, or whose largest bit size is 256 for types that are smaller than 16-bit. Recall that applications can use matrix dimensions that are a multiple of the native supported size in any dimension. This ensures that 16x16x16 will always be a valid tile shape for 16-bit types, while smaller types may support a minimum size of 32x16x16.

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
### D3D12 DDI Additions

The DDIs for this feature are straightforward API mappings and have therefore
been excluded from this document. The minimum D3D12 core DDI version is 0115, matching
the cooperative vectors DDIs. The same D3D12DDI_FEATURE enum value (15) is re-used, with
feature version 2 (`D3D12DDI_FEATURE_VERSION_LINEAR_ALGEBRA_0115_1`) indicating support for
linear algebra rather than cooperative vectors.

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