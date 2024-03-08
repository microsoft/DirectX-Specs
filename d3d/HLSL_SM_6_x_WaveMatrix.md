# Wave Matrix

GPUs and compute devices have begun adding dedicated silicon to their hardware to support 
Matrix Multiplication at higher bandwidths for usage in Machine Learning and Imaging applications.
To allow access to this dedicated silicon, HLSL is adding Wave Matrix objects with methods for
performing Wave Matrix Multiply and Accumulate (WaveMMA) operations.

The goal this feature is to abstract the hardware specific details of the underlying 
silicon devices and provide a more unified programming model that is compatible with existing
HLSL concepts. To achieve this goal, HLSL is defining a new abstract datatype, Wave Matrix, 
which is designed to provide the underlying hardware with an abstract and opaque object.

At a high level, the Wave Matrix object provides a mechanism for the underlying silicon to 
store, rearrange, and duplicate data across all threads in a wave. The Wave Matrix object also could
allow for the hardware to move the data into special WaveMMA specific registers. A Wave Matrix object is
defined to have the scope of a wave. This means that there is a single Wave Matrix object for every 
wave in the thread group and the data of the Wave Matrix is spread opaquely across all the threads in that 
wave. Having the data in this opaque and potentially divided state means that access to the data in the 
object needs to be limited. As such only a small set of predefined math operations are defined as functions 
on the Wave Matrix. These predefined operations are to allow for Matrix Multiplication and Convolution 
algorithms to be written efficiently on top of the abstracted hardware silicon.

To upload data into this new Wave Matrix object the developer uses a Load intrinsic. This load
intrinsic is defined to be able to load data from groupshared memory or from a UAV resource. The process
of loading the data is what converts the data into the opaque format. The data in groupshared memory or UAV 
resource is interpreted as a 1D buffer whose formatting is configured by the load parameters and matrix 
configuration.

Once loaded the Wave Matrix can perform basic math operations such as matrix multiplication, summing, 
and simple scalar operations. If the user requires any additional access to the data then they must use 
the Store instruction to move the data out of the opaque format and into the standard groupshared memory
or UAV resources.

As the dimensions of the matrix multiplication unit is device specific, HLSL is defining the dimensions
of the Wave Matrix to preserve as much flexibility in the hardware implementation that is feasible while 
also trying to make it useable for HLSL developers. The matrix multiplication unit is defined by three 
dimensions M, N, and K. The matrix multiplication unit then would defined to be a multiplication of two
matrices of dimensions, MxK and KxN with a resulting matrix of size MxN. 

The Wave Matrix object is defined to have sizes M, N, and K. This means that for the matrix multiply of 
AxB, matrix A is M rows of K elements and matrix B is K rows of N elements. A hardware implementation may 
support only one K value for each combination of M, N, and datatype. The possible dimensions of M and N 
are restricted to the allowed enum values defined by D3D12_WAVE_MMA_DIMENSION M and D3D12_WAVE_MMA_DIMENSION N. 
The K dimension is defined to be an even multiple of 16 provided by the driver through the 
D3D12_FEATURE_DATA_WAVE_MMA CheckFeatureSupport Caps. The K value also accessible via a function on the 
input matrices. This allows for programable shaders and hardcoded shaders. The K value is considered 
a constant and the driver should unroll loops using it, if possible.

Performing operations on wave matrix data within a lane that is divergent within the local wave 
produces undefined results. The actual distribution of work across SIMD lanes is not exposed to 
the app code. This implies that the number of threads in a thread group must be a multiple of 
the wave size in order to use the Wave MMA intrinsics.

Non-WaveMatrix arguments to WaveMatrix operations will be taken from the first lane in the wave
in order to provide a uniform value for the operation.

Hardware implementations which do not natively support M and N values may emulate this size 
via tiling the underlying device specific dimensions.

## Matrix Object Template

HLSL has always supported matrices as system-defined type of 4x4 elements.
These matrices are not exposed directly to the driver, but are scalarized 
into individual operations like fma(). The WaveMatrix will be different as
it is an abstracted matrix.

```C++
// existing:
matrix <float32_t, 4, 4> float4x4; // system-defined type for float 4x4 matrices
matrix <float16_t, 4, 4> half4x4;  // system-defined type for half 4x4 matrices
```

This feature adds the following matrix types:

```C++
// K dimension is hardware dependent
// With TYPE_IN one of {float32_t, float16_t, uint8_t4_packed, int8_t4_packed}
WaveMatrixLeft  <TYPE_IN, M, N> ;             // M x K
WaveMatrixRight <TYPE_IN, M, N> ;             // K x N

// With TYPE_ACC one of {float32_t, float16_t, int32_t}
WaveMatrixAccumulator <TYPE_ACC, M, N> ;      // M x N
// WaveMatrixLeftColAcc and WaveMatrixRightRowAcc are provided support for quantization algorithms.
// See Zero Point section

// For accumulating columns from WaveMatrixLeft into a single column of sums
WaveMatrixLeftColAcc  <TYPE_ACC, M, N> ;      // M x 1

// For accumulating rows from WaveMatrixRight into a single row of sums
WaveMatrixRightRowAcc <TYPE_ACC, M, N> ;      // 1 x N
```

### Wave Matrix Dimensions
The WaveMatrix* types require the upfront definition of both M and N for all matrix types. These data 
structures wrap abstract formats which could be reliant on the all three M, N, and K values. It is also 
possible that devices will want to support multiple dimension configurations in the future so HLSL is defining
the feature to be extensible if required.

#### Wave Matrix Depth
The Wave Matrix Depth(or K) value is defined by the hardware. An intrinsic is defined to return the
constant Depth(K) of the matrix multiply unit for a given combination of M, N, and datatype. A device 
is only allowed to support one K for each combination of datatype, M, and N. WaveMatrixLeft and 
WaveMatrixRight are the only valid matrix types for this intrinsic. Only even multiples of 16 
are allowed.

```C++
uint WaveMatrixLeft<T, M, N>::MatrixDepth();
uint WaveMatrixRight<T, M, N>::MatrixDepth();
```

## CheckFeatureSupport
This Wave MMA feature will require a CheckFeatureSupport addition into D3D12. 
Additional D3D12_FEATURE Enum and D3D12_FEATURE_DATA struct are added to query for support for WaveMMA.

```C++
typedef enum D3D12_FEATURE {
    ...
    D3D12_FEATURE_WAVE_MMA
};

typedef enum D3D12_WAVE_MMA_DATATYPE {
    D3D12_WAVE_MMA_DATATYPE_BYTE,
    D3D12_WAVE_MMA_DATATYPE_FLOAT16,
    D3D12_WAVE_MMA_DATATYPE_FLOAT
};

typedef enum D3D12_WAVE_MMA_DIMENSION {
    D3D12_WAVE_MMA_DIMENSION_16,
    D3D12_WAVE_MMA_DIMENSION_64
    // Expandable to other M sizes if needed
}

// Enum Flags to allow multiply precisions to be supported
typedef enum D3D12_WAVE_MMA_ACCUM_PRECISION {
    D3D12_WAVE_MMA_ACCUM_PRECISION_16 = 0x1,
    D3D12_WAVE_MMA_ACCUM_PRECISION_32 = 0x2
};

typedef struct D3D12_FEATURE_DATA_WAVE_MMA {
    In D3D12_WAVE_MMA_DATATYPE DataType;     // Datatype set by user
    In D3D12_WAVE_MMA_DIMENSION M;           // M Sizes set by user
    In D3D12_WAVE_MMA_DIMENSION N;           // N Sizes set by user
    Out BOOL Supported;                      // Returns true if Datatype/Dimensions are supported.
    Out UINT K;                              // Shared dimension size returned by driver must be an even multiple of 16
    Out D3D12_WAVE_MMA_ACCUM_PRECISION AccumPrecision;
    Out UINT RequiredWaveSize;
};
```

Example calling pattern

```C++
D3D12_FEATURE_DATA_WAVE_MMA waveMmaSupport = {};
waveMmaSupport.DataType = D3D12_WAVE_MMA_DATATYPE_FLOAT16;
waveMmaSupport.MDimension = D3D12_WAVE_MMA_DIMENSION_16;
waveMmaSupport.NDimension = D3D12_WAVE_MMA_DIMENSION_16;

d3d12Device->CheckFeatureSupport(D3D12_FEATURE_WAVE_MMA, &waveMmaSupport, sizeof(D3D12_FEATURE_DATA_WAVE_MMA));

if (waveMmaSupport.Supported && 
    waveMmaSupport.K == 16 && 
   (waveMmaSupport.AccumPrecision & D3D12_WAVE_MMA_ACCUM_PRECISION_32))
{
    // Use WaveMMA shader hardcoded with K of 16 and Accumulator Precision of 32 bits
}
else if (waveMmaSupport.Supported && 
         waveMmaSupport.K == 16 && 
        (waveMmaSupport.AccumPrecision & D3D12_WAVE_MMA_ACCUM_PRECISION_16))
{
    // Use WaveMMA shader hardcoded with K of 16 and Accumulator Precision of 16 bits
}
// Else don't use Wave MMA
```

### CheckFeatureSupport RequiredWaveSize

The cap field RequiredWaveSize returns the required wave size for the WaveMMA intrinsics. This size is used to determine 
how many wave matrices are present in a threadgroup. This number is defined to be (Number of threads per group) / RequiredWaveSize.
The shader author must insure that (Number of threads per group) % RequiredWaveSize == 0. RequiredWaveSize must be a value 
within the range defined by WaveLaneCountMin and WaveLaneCountMax defined in the D3D_Feature, D3D12_FEATURE_DATA_D3D12_OPTIONS1. 

Zero is allowed to be returned by RequiredWaveSize if all values within range of WaveLaneCountMin and WaveLaneCountMax are valid.

### CheckFeatureSupport Definitions: Byte

If byte is supported then the following matrices must be supported with all defined intrinsics. int8 and uint8 can
be used in mix mode matrix multiplies. No integer data loss is allowed unless it overflows in int32 precision.
Only 32 bit Accumulator Precision is allowed.

```C++
WaveMatrixLeft       <uint8_t4_packed,  M, N> ;
WaveMatrixRight      <uint8_t4_packed,  M, N> ;

WaveMatrixLeft       <int8_t4_packed,  M, N> ;
WaveMatrixRight      <int8_t4_packed,  M, N> ;

WaveMatrixAccumulator<int32_t,  M, N> ;

WaveMatrixLeftColAcc <int32_t,  M, N> ;
WaveMatrixRightRowAcc<int32_t,  M, N> ;
```

### CheckFeatureSupport Definitions: Float16
If float16 is supported then the following matrices must be supported with all defined intrinsics. The
caps bits Accumulator Precision defines what the precision of the accumulator is supported. Only 16 or 
32 bit Accumulator Precisions are allowed.

```C++
WaveMatrixLeft       <float16_t,  M, N> ;
WaveMatrixRight      <float16_t,  M, N> ;

// Accumulator Type defined by caps bits Accumulator Precision
WaveMatrixAccumulator<float16_t,  M, N> ;
WaveMatrixAccumulator<float32_t,  M, N> ;

WaveMatrixLeftColAcc <float16_t,  M, N> ;
WaveMatrixRightRowAcc<float16_t,  M, N> ;

WaveMatrixLeftColAcc <float32_t,  M, N> ;
WaveMatrixRightRowAcc<float32_t,  M, N> ;
```

### CheckFeatureSupport Definitions: Float32
If float is supported then these matrices must be supported with all defined intrinsics. Accumulator Precision 
defines what the precision of the accumulator is supported. Only 32 bit Accumulator Precision is allowed.

```C++
WaveMatrixLeft       <float32_t, M, N> ;
WaveMatrixRight      <float32_t, M, N> ;

WaveMatrixAccumulator<float32_t, M, N> ;

WaveMatrixLeftColAcc <float32_t, M, N> ;
WaveMatrixRightRowAcc<float32_t, M, N> ;
```

## Fill Intrinsic
Intrinsic for filling a wave matrix with a value. Can support a constant or non-constant value. All wave 
threads must provide the same value or get undefined results. All WaveMatrix types must support this function.

```C++
WaveMatrix*<T, M, N>::Fill(T value);
```

## Load and Store

Each WaveMatrix object supports loading from and storing to `[RW]ByteAddressBuffer` memory or `groupshared` arrays.

Load and Store with `[RW]ByteAddressBuffer` uses offset, stride, and alignment specified in bytes.

Load and Store with `groupshared` array uses offset and stride specified in array elements.

The storage layout of matrix elements in `[RW]ByteAddressBuffer` memory or `groupshared` arrays may be in row-major or column-major orientation.
The layout of elements in the opaque WaveMatrix object is device-dependent, and not visible to the program.
The term *memory-layout row* refers to a contiguous row of components in memory depending on the selected orientation.
This will be the same as the logical row if `bColMajor` is `false`, or it will be the same as a logical column if `bColMajor` is `true`.

For packed element formats, the elements packed together in memory map to the same row or column as the other elements in the *memory-layout row* (depending on layout selected).
For instance, if `bColMajor` is `false`, elements from the same row are packed together,
but if `bColMajor` is `true`, elements from the same column are packed together instead.

Fragment Accumulators `WaveMatrixLeftColAcc` and `WaveMatrixRightRowAcc` are loaded/stored as a vector of components,
with a specified stride between elements in the memory layout or groupshared array layout.

Strides have minimums to prevent rows or elements from overlapping in the resulting memory layout.

### Load from Resource

```C++
// Load from [RW]ByteAddressBuffer
WaveMatrixLeft<T, M, N>::Load([RW]ByteAddressBuffer inputResource, uint startOffsetInBytes, uint rowStrideInBytes, bool bColMajor, uint alignment = 0);
WaveMatrixRight<T, M, N>::Load([RW]ByteAddressBuffer inputResource, uint startOffsetInBytes, uint rowStrideInBytes, bool bColMajor, uint alignment = 0);

WaveMatrixAccumulator<T, M, N>::Load([RW]ByteAddressBuffer inputResource, uint startOffsetInBytes, uint rowStrideInBytes, bool bColMajor, uint alignment = 0);

WaveMatrixLeftColAcc<T, M, N>::Load([RW]ByteAddressBuffer inputResource, uint startOffsetInBytes, uint elementStrideInBytes, uint alignment = 0);
WaveMatrixRightRowAcc<T, M, N>::Load([RW]ByteAddressBuffer inputResource, uint startOffsetInBytes, uint elementStrideInBytes, uint alignment = 0);
```

Loads matrix with data from a RWByteAddress buffer (UAV) or ByteAddress buffer (SRV).
The amount of data loaded is dependent on the WaveMatrix type and dimensions.
All WaveMatrix types must support this method.

`inputResource` is the input resource to read from.
This resource object must be uniform across threads in the wave.

`uint startOffsetInBytes` is the offset in bytes from the start of the `inputResource` buffer view to load from.
All wave threads must provide the same value or get undefined results.
This offset must be at least DWORD aligned.

`uint rowStrideInBytes` is the pitch in bytes between memory-layout rows of the matrix in `inputResource`.
When `bColMajor` is true, `rowStrideInBytes` indicates the pitch in bytes between columns instead of rows.
The minimum value for `rowStrideInBytes` is the size of the memory-layout row in bytes.

`uint elementStrideInBytes` is the pitch in bytes between elements to load from `inputResource`.
The minimum value for `elementStrideInBytes` is the element size in bytes.

`bool bColMajor` indicates whether to load from column-major orientation.
When false, it indicates that the data is loaded from row-major orientation in the buffer.
When true, it indicates that the data is loaded from column-major orientation in the buffer.
The data is loaded into the native local matrix layout.
The actual hardware layout of the local WaveMatrix is abstracted from the user.

`uint alignment` optional alignment in bytes of the combined address alignment of the base address of the buffer view plus the `startOffsetInBytes`.
Each row(or column if `bColMajor`) must be aligned by this amount, therefore, `rowStrideInBytes` must follow this alignment.
`0` or unspecified means that the alignment is the minimum determined by the buffer, which is 4 bytes for ByteAddressBuffer and RWByteAddressBuffer.
If non-zero, it must be a power of 2 and greater than or equal to 4.
This alignment value does not apply to `elementStrideInBytes`.

### Load from groupshared Array

```C++
// Load from groupshared array
WaveMatrixLeft<T, M, N>::Load(groupshared inputArray, uint offsetInArrayElements, uint rowStrideInElements, bool bColMajor);
WaveMatrixRight<T, M, N>::Load(groupshared inputArray, uint offsetInArrayElements, uint rowStrideInElements, bool bColMajor);

WaveMatrixAccumulator<T, M, N>::Load(groupshared inputArray, uint offsetInArrayElements, uint rowStrideInElements, bool bColMajor);

WaveMatrixLeftColAcc<T, M, N>::Load(groupshared inputArray, uint offsetInArrayElements, uint elementStrideInArrayElements);
WaveMatrixRightRowAcc<T, M, N>::Load(groupshared inputArray, uint offsetInArrayElements, uint elementStrideInArrayElements);
```

Loads matrix with data from a groupshared array.
The amount of data loaded is dependent on the WaveMatrix type and dimensions.
All WaveMatrix types must support this method.
The element type of the groupshared array must match the element type of the matrix.

`inputArray` is the groupshared array to read from.

`uint offsetInArrayElements` is the offset in array elements from the start of the `inputArray` to load from.
All wave threads must provide the same value or get undefined results.

`uint rowStrideInElements` is the pitch in array elements between memory-layout rows of the matrix in `inputArray`.
When `bColMajor` is true, `rowStrideInElements` indicates the pitch in array elements between columns instead of rows.
The minimum value for `rowStrideInElements` is the number of array elements in a memory-layout row.

`uint elementStrideInArrayElements` is the pitch in array elements between elements to load from `inputArray`.
The minimum value for `elementStrideInArrayElements` is 1.

`bool bColMajor` indicates whether to load from column-major orientation.
When false, it indicates that the data is loaded from row-major orientation in the array.
When true, it indicates that the data is loaded from column-major orientation in the array.
The data is loaded into the native local matrix layout.
The actual hardware layout of the local WaveMatrix is abstracted from the user.

### Store to Resource

```C++
// Store to RWByteAddressBuffer
WaveMatrixLeft<T, M, N>::Store(RWByteAddressBuffer outputResource, uint startOffsetInBytes, uint rowStrideInBytes, bool bColMajor, uint alignment = 0);
WaveMatrixRight<T, M, N>::Store(RWByteAddressBuffer outputResource, uint startOffsetInBytes, uint rowStrideInBytes, bool bColMajor, uint alignment = 0);

WaveMatrixAccumulator<T, M, N>::Store(RWByteAddressBuffer outputResource, uint startOffsetInBytes, uint rowStrideInBytes, bool bColMajor, uint alignment = 0);

WaveMatrixLeftColAcc<T, M, N>::Store(RWByteAddressBuffer outputResource, uint startOffsetInBytes, uint elementStrideInBytes, uint alignment = 0);
WaveMatrixRightRowAcc<T, M, N>::Store(RWByteAddressBuffer outputResource, uint startOffsetInBytes, uint elementStrideInBytes, uint alignment = 0);
```

Writes a wave matrix to a RWByteAddressBuffer (UAV).
The amount of data stored is dependent on the WaveMatrix type and dimensions.
All WaveMatrix types must support this method.

`outputResource` is the RWByteAddressBuffer to write to.
This resource object must be uniform across threads in the wave.

`uint startOffsetInBytes` is the offset in bytes from the start of the `outputResource` buffer view to store to.
All wave threads must provide the same value or get undefined results.
This offset must be at least DWORD aligned.

`uint rowStrideInBytes` is the pitch in bytes between memory-layout rows of the matrix in `outputResource`.
When `bColMajor` is true, `rowStrideInBytes` indicates the pitch in bytes between columns instead of rows.
The minimum value for `rowStrideInBytes` is the size of the memory-layout row in bytes.

`uint elementStrideInBytes` is the pitch in bytes between elements stored to `outputResource`.
The minimum value for `elementStrideInBytes` is the element size in bytes.

`bool bColMajor` indicates whether to store to column-major orientation.
When false, it indicates that the data will be stored to row-major orientation in the buffer.
When true, it indicates that the data will be stored to column-major orientation in the buffer.
The data is logically transposed as necessary from the native local matrix layout.
The actual hardware layout of the local WaveMatrix is abstracted from the user.

`uint alignment` optional alignment in bytes of the combined address alignment of the base address of the buffer view plus the `startOffsetInBytes`.
Each row(or column if `bColMajor`) must be aligned by this amount, therefore, `rowStrideInBytes` must follow this alignment.
`0` or unspecified means that the alignment is the minimum determined by the buffer, which is 4 bytes for RWByteAddressBuffer.
If non-zero, it must be a power of 2 and greater than or equal to 4.
This alignment value does not apply to `elementStrideInBytes`.

### Store to groupshared Array

```C++
// Store to groupshared array
WaveMatrixLeft<T, M, N>::Store(groupshared outputArray, uint offsetInArrayElements, uint rowStrideInElements, bool bColMajor);
WaveMatrixRight<T, M, N>::Store(groupshared outputArray, uint offsetInArrayElements, uint rowStrideInElements, bool bColMajor);

WaveMatrixAccumulator<T, M, N>::Store(groupshared outputArray, uint offsetInArrayElements, uint rowStrideInElements, bool bColMajor);

WaveMatrixLeftColAcc<T, M, N>::Store(groupshared outputArray, uint offsetInArrayElements, uint elementStrideInArrayElements);
WaveMatrixRightRowAcc<T, M, N>::Store(groupshared outputArray, uint offsetInArrayElements, uint elementStrideInArrayElements);
```

Writes a wave matrix to a groupshared array.
The amount of data stored is dependent on the WaveMatrix type and dimensions.
All WaveMatrix types must support this method.
The element type of the groupshared array must match the element type of the matrix.

`outputArray` is the groupshared array to write to.

`uint offsetInArrayElements` is the offset in array elements from the start of the `outputArray` to store to.
All wave threads must provide the same value or get undefined results.

`uint rowStrideInElements` is the pitch in array elements between memory-layout rows of the matrix in `outputArray`.
When `bColMajor` is true, `rowStrideInElements` indicates the pitch in array elements between columns instead of rows.
The minimum value for `rowStrideInElements` is the number of array elements in a memory-layout row.

`uint elementStrideInArrayElements` is the pitch in array elements between elements stored to `outputArray`.
The minimum value for `elementStrideInArrayElements` is 1.

`bool bColMajor` indicates whether to store to column-major orientation.
When false, it indicates that the data will be stored to row-major orientation in the array.
When true, it indicates that the data will be stored to column-major orientation in the array.
The data is logically transposed as necessary from the native local matrix layout.
The actual hardware layout of the local WaveMatrix is abstracted from the user.

## Matrix Multiply

Standard multiplication of matrices is provided via an intrinsic:

```C++
// matC.Multiply(matA, matB);
WaveMatrixAccumulator<T, M, N>::Multiply(WaveMatrixLeft matA, WaveMatrixRight matB)
```

Performs matrix multiplication of matA and matB leaving the result in matC.

matA, matB, and matC must have valid typing defined by the runtime caps bits. matA must be
a WaveMatrixLeft matrix and matB must be a WaveMatrixRight matrix. matA and matB must match 
types with the exception that uint8 and int8 which can be mixed.

To enable more flexibility in implementation, this function operates at the wave level,
so must not be used inside flow control that is divergent within the wave.

## Matrix Multiply with Accumulate

Multiplication of matrices into an accumulator matrix is expressed via an intrinsic:

```C++
// matC.MultiplyAccumulate(matA, matB);
WaveMatrixAccumulator<T, M, N>::MultiplyAccumulate(WaveMatrixLeft matA, WaveMatrixRight matB);
```

Performs matrix multiplication of matA and matB and adding that result into matC. All three matrices 
must have valid datatypes defined by the runtime caps bits. matA must be a WaveMatrixLeft matrix and
matB must be a WaveMatrixRight matrix. matA and matB must match types with the exception that uint8 
and int8 which can be mixed.

To enable more flexibility in implementation, this function operates at the wave level,
so must not be used inside flow control that is divergent within the wave.

## Scalar Matrix Operators

WaveMatrixAccumulator, WaveMatrixLeftColAcc, and WaveMatrixRightRowAcc support scalar operations
to support simple operations without having to spill matrix accumulator data back into normal, non-opaque
registers.

```C++
// WaveMatrixAccumulator, WaveMatrixLeftColAcc, and WaveMatrixRightRowAcc 
WaveMatrix*::ScalarMultiply(ACCUM_TYPE value);
WaveMatrix*::ScalarDivide(ACCUM_TYPE value);
WaveMatrix*::ScalarAdd(ACCUM_TYPE value);
WaveMatrix*::ScalarSubtract(ACCUM_TYPE value);
```

## Zero Point
The Wave MMA intrinsics are defined to support quantization calculations. This includes the ability
to calculate a sum for the rows of the left matrix and a sum of the columns of the right matrix. This 
additional functionality is achieved through the WaveMatrixRightRowAcc and WaveMatrixLeftColAcc matrices.

The following is the equation for Matrix Multiply with zero point adjustment included:

$C_{[x,y]} = (\sum_{i=0}^{K} A_{[x,i]} * B_{[i,y]}) - Z_a * (\sum_{i=0}^{K} B_{[i,y]}) - Z_b * (\sum_{i=0}^{K} A_{[x,i]}) + Z_a * Z_b * K$

$(\sum_{i=0}^{K} A_{[x,i]} * B_{[i,y]})$ is basic Matrix Multiply

$- Z_a * (\sum_{i=0}^{K} B_{[i,y]})$ is the zero point adjustment for matrix $A$

$- Z_b * (\sum_{i=0}^{K} A_{[x,i]})$ is the zero point adjustment for matrix $B$

$+ Z_a * Z_b * K$ is the static zero point adjustment for both matrix $A$ and $B$

$Z_*$ are constant zero points values

### Wave Matrix SumAccumulate

Accumulates the values of `mat` into the fragment wave matrix, WaveMatrixRightRowAcc or WaveMatrixLeftColAcc. 
A limited set of types and matrix types are allowed which are defined by the caps bits. The fragment WaveMatrix
must have the same data type as the accumulator matrix controlled by the Accumulator Precision Caps bit. 

For example, if Byte support is set to true and Accumulator Precision is 32, then `mat` could be
int8 or uint8 and WaveMatrix fragment would be int32.

Sidedness must match for the matrix type, WaveMatrixLeftColAcc to WaveMatrixLeft and WaveMatrixRightRowAcc to 
WaveMatrixRight. The integer intrinsic must not overflow unless it is in int32 space.

This intrinsics is used to calculated $(\sum_{i=0}^{K} A_{[x,i]})$ and $(\sum_{i=0}^{K} B_{[i,y]})$ from our above equation.

```C++
WaveMatrixRightRowAcc::SumAccumulate(WaveMatrixRight mat);
WaveMatrixLeftColAcc::SumAccumulate(WaveMatrixLeft mat);
```

### Broadcast Add
This intrinsic does an element-wise add of an accumulator matrix and `broadcastedMatrix`. The add must 
broadcast the `broadcastedMatrix` to all appropriate elements in the accumulator matrix. The 
`broadcastedMatrix` is broadcast up from a Mx1 or 1xN matrix to a MxN matrix and is then element-wise 
added to the accumulator matrix. 

The `broadcastedMatrix` must be of matrix type WaveMatrixLeftColAcc, WaveMatrixRightRowAcc or 
WaveMatrixAccumulator. If the datatypes of the input matrices don't match then `broadcastMatrix` 
is casted to match accumulator matrix.

```C++
WaveMatrixAccumulator::Add(WaveMatrixLeftColAcc broadcastedMatrix);   // Broadcasted Elementwise Add
WaveMatrixAccumulator::Add(WaveMatrixRightRowAcc broadcastedMatrix);  // Broadcasted Elementwise Add
WaveMatrixAccumulator::Add(WaveMatrixAccumulator fullMatrix);       // Elementwise Add
```

## Wave Matrix Resource Example:

```C++
// Matrix Multiply Of AxB [M,K]x[K,N] using Resource Loading and Storing
// Requirements:
// NWHC Layout and K is an even multiple of Matrix K

#define TILESIZE_X 16
#define TILESIZE_Y 16

// Use runtime caps to choose from specialized shaders compiled with matching WAVE_SIZE.
[wavesize(WAVE_SIZE)]
[numthreads(WAVE_SIZE,1,1)]
void CSMain(
    uint3 globalThreadId : SV_DispatchThreadId,
    uint3 groupId : SV_GroupID,
    uint groupIndex : SV_GroupIndex
    )
{
    // Define the Wave Wide Matrices
    WaveMatrixLeft <float16_t, 16, 16> matA;
    WaveMatrixRight <float16_t, 16, 16> matB;
    WaveMatrixAccumulator <float32_t, 16, 16> matC;

    uint matrixDepth = matA.MatrixDepth(); // Returns K must be a multiple of 16

    // Adding threadId logic (based on groupIndex) here would make multiple waves per thread group work.
    const uint row = groupId.y * TILESIZE_Y + startRowIndex; 
    const uint col = groupId.x * TILESIZE_X + startColIndex;

    const uint rowStrideA = CalculateRowStrideMatrixA();
    const uint colStrideB = CalculateColStrideMatrixB();

    matC.Fill(0);

    // K must be an even multiple of matrixDepth use cap bits to make sure that this is true
    for (uint step = 0; step < K; step += matrixDepth)
    {
        // Calculate the sub matrix start location as the combination of group's row and the current step 
        uint subMatrixAStart = row * rowStrideA + step;
        uint subMatrixBStart = col * colStrideB + step;

        // Load A: WaveMatrixLeft is logically: M=16 rows by K columns
        // Reads M=16 memory-layout rows of K elements from row-major storage layout for left matrix.
        matA.Load(inputA, subMatrixAStart, rowStrideA, /*bColMajor*/false);
        // Load B: WaveMatrixRight is logically: K rows by N=16 columns
        // Reads N=16 memory-layout rows of K elements from column-major storage layout for right matrix.
        // The memory layout is transposed from the logical layout of the right matrix,
        // because input is pre-transposed in NHWC layout.
        matB.Load(inputB, subMatrixBStart, colStrideB, /*bColMajor*/true);

        matC.MultiplyAccumulate(matA, matB);
    }

    // Stores 16x16 output elements
    matC.Store(output, row * outputRowStride + col, outputRowStride, false);
}
```

## Wave Matrix ZeroPoint Example:

```C++
// Quantized Matrix Multiply Of AxB [M,K]x[K,N] using Resource Loading and Storing and Zero points
// Requirements:
// NWHC Layout and K is an even multiple of Matrix K

#define TILESIZE_X 16
#define TILESIZE_Y 16

[wavesize(WAVE_SIZE)]
[numthreads(WAVE_SIZE,1,1)]
void CSMain(
    uint3 globalThreadId : SV_DispatchThreadId,
    uint3 groupId : SV_GroupID,
    uint groupIndex : SV_GroupIndex
    )
{
    // Define the Wave Wide Matrices
    WaveMatrixLeft <int8_t4_packed, 16, 16> matA;
    WaveMatrixRight <uint8_t4_packed, 16, 16> matB;
    WaveMatrixLeftColAcc <int32_t, 16, 16> matAZeroPoint;
    WaveMatrixRightRowAcc <int32_t, 16, 16> matBZeroPoint;
    WaveMatrixAccumulator <int32_t, 16, 16> matC;

    uint matrixDepth = matA.MatrixDepth(); // Returns K must be a multiple of 16

    // Adding threadId logic (based on groupIndex) here would make multiple waves per thread group work.
    const uint row = groupId.y * TILESIZE_Y + startRowIndex; 
    const uint col = groupId.x * TILESIZE_X + startColIndex;

    const uint rowStrideA = CalculateRowStrideMatrixA();
    const uint colStrideB = CalculateColStrideMatrixB();

    matAZeroPoint.Fill(0);
    matBZeroPoint.Fill(0);
    matC.Fill(0);

    // K must be an even multiple of matrixDepth use cap bits to make sure that this is true
    for (uint step = 0; step < K; step += matrixDepth)
    {
        // Calculate the sub matrix start location as the combination of group's row and the current step 
        uint subMatrixAStart = row * rowStrideA + step;
        uint subMatrixBStart = col * colStrideB + step;

        // Load A: WaveMatrixLeft is logically: M=16 rows by K columns
        // Reads M=16 memory-layout rows of K elements from row-major storage layout for left matrix.
        matA.Load(inputA, subMatrixAStart, rowStrideA, /*bColMajor*/false);
        // Load B: WaveMatrixRight is logically: K rows by N=16 columns
        // Reads N=16 memory-layout rows of K elements from column-major storage layout for right matrix.
        // The memory layout is transposed from the logical layout of the right matrix,
        // because input is pre-transposed in NHWC layout.
        matB.Load(inputB, subMatrixBStart, colStrideB, /*bColMajor*/true);

        // SumAccumulate K elements into one row or col of 16 elements
        matAZeroPoint.SumAccumulate(matA);
        matBZeroPoint.SumAccumulate(matB);

        matC.MultiplyAccumulate(matA, matB);
    }

    int zeroPointScalarA = GetZeroPointScalarA();
    int zeroPointScalarB = GetZeroPointScalarB();

    // Scalar multiply to entire matrix
    matAZeroPoint.ScalarMultiply(-zeroPointScalarB);
    matBZeroPoint.ScalerMultiply(-zeroPointScalarA);

    // Broadcasting one row or column to entire accumulator matrix
    matC.Add(matAZeroPoint);
    matC.Add(matBZeroPoint);

    // Scalar addition to entire accumulator matrix
    matC.ScalarAdd(zeroPointScalarA * zeroPointScalarB * K)

    // Stores 16x16 output elements
    matC.Store(output, row * outputRowStride + col, outputRowStride, false);
}
```

## Wave Matrix Groupshared Example:

```C++
// Matrix Multiply Of AxB [M,K]x[K,N] using Group Shared Loading and Storing
// Requirements:
// TILESIZE_Z is evenly divisible by Matrix K

#define WAVE_MATRIX_DIM 16

#define TILESIZE_X 32
#define TILESIZE_Y 32
#define TILESIZE_Z 32
#define NUM_THREADS_X WAVE_SIZE // Use runtime caps to choose from specialized shaders
#define NUM_THREADS_Y 2 // Y and Z threads would be mappings to accumulators matC
#define NUM_THREADS_Z 2

// Shared Memory
float16_t groupMatA[TILESIZE_Y * TILESIZE_Z];
float16_t groupMatB[TILESIZE_X * TILESIZE_Z];
float     groupMatC[TILESIZE_X * TILESIZE_Y];

// Use 1D numthreads and manually decompose the row-major threadId,
// otherwise there's no guarantee for the scheduled layout of threadId values.
[wavesize(WAVE_SIZE)]
[numthreads(NUM_THREADS_X * NUM_THREADS_Y * NUM_THREADS_Z, 1, 1)]
void CSMain(
    uint3 globalThreadId : SV_DispatchThreadId,
    uint3 groupId : SV_GroupID,
    uint groupIndex : SV_GroupIndex
    )
{
    // Construct row-major threadId from flattened groupIndex:
    uint3 threadId = {  groupIndex % NUM_THREADS_X,
                        (groupIndex / NUM_THREADS_X) % NUM_THREADS_Y,
                        groupIndex / (NUM_THREADS_X * NUM_THREADS_Y)  };

    // Define the Wave Wide Matrices
    WaveMatrixLeft <float16_t, 16, 16> matA;
    WaveMatrixRight <float16_t, 16, 16> matB;
    WaveMatrixAccumulator <float32_t, 16, 16> matC;

    uint matrixDepth = GetWaveMatrixDepth(matA); // Returns K must be a multiple of 16

    const uint row = groupId.y * TILESIZE_Y + startRowIndex;
    const uint col = groupId.x * TILESIZE_X + startColIndex;

    const uint rowStrideA = CalculateRowStrideMatrixA();
    const uint colStrideB = CalculateColStrideMatrixB();

    matC.Fill(0);

    // K must be an even multiple of matrixDepth use cap bits to make sure that this is true or account
    // for miss match in shared memory load.
    for (uint step = 0; step < K; step += matrixDepth)
    {
        // Calculate the sub matrix start location as the combination of group's row and the current step 
        uint subMatrixAStart = row * rowStrideA + step;
        uint subMatrixBStart = col * colStrideB + step;

        // Load A into Shared Memory omitted for brevity
        GlobalToSharedLoad(ResourceA, subMatrixAStart, groupMatA);
        GlobalToSharedLoad(ResourceB, subMatrixBStart, groupMatB); // Does not transpose during read

        // Sync to make sure data is fully loaded into groupshared
        GroupMemoryBarrierWithGroupSync();

        // TILESIZE_Z is 32 and matrixDepth is a multiple of 16 so this should be unrolled in the 
        // driver.
        for (uint fragK = 0; fragK < TILESIZE_Z; fragK += matrixDepth)
        {
            // Use waves in a thread group to map to each output region. 2x2
            // regions because tile size is 32x32 and output blocks are 16x16.
            // This could be looped over if less threads are desired or a larger 
            // tile size in required.
            uint fragA = threadId.y * WAVE_MATRIX_DIM;
            uint fragB = threadId.z * WAVE_MATRIX_DIM;

            // Load A: WaveMatrixLeft is logically: M=16 rows by K columns
            // Reads M=16 memory-layout rows of K elements from row-major storage layout for left matrix.
            matA.Load(groupMatA, fragA * TILESIZE_Z + fragK * TILESIZE_Y, TILESIZE_Z, /*bColMajor*/false);

            // Load B: WaveMatrixRight is logically: K rows by N=16 columns
            // Reads N=16 memory-layout rows of K elements from column-major storage layout for right matrix.
            // The memory layout is transposed from the logical layout of the right matrix,
            // because input is pre-transposed in NHWC layout.
            matB.Load(groupMatB, fragB * TILESIZE_Z + fragK * TILESIZE_X, TILESIZE_Z, /*bColMajor*/true);

            matC.MultiplyAccumulate(matA, matB);
        }
        
        // Sync to before evicting group shared memory
        GroupMemoryBarrierWithGroupSync();
    }

    uint fragA = threadId.y * WAVE_MATRIX_DIM;
    uint fragB = threadId.z * WAVE_MATRIX_DIM;
    // Store result matrix out to shared memory for optional additional processing.
    matC.Store(groupMatC, fragA + fragB * TILESIZE_X, TILESIZE_X, false);
    
    // Write results from shared to global memory
    WriteOutResults(groupMatC);
}
```

_______________________________________

# Revision History

  |Date/Revision |  Key Changes           |
  |--------------|----------------------------------------|
  | 4-25-2019    |  Initial Version Checkin   |
  | 5-02-2019    |  Added intrinsics for load/store from groupshared   |
  | 12-06-2019   |  nickfe revision   |
  | 11-21-2020   |  Update WaveMatrix* names for final HLSL objects   |
  | 05-25-2022   |  <li>Expand and clarify Load/Store method signatures and descriptions, with separate buffer and groupshared descriptions.</li><li>Change fragment load/store signatures to remove stride and transpose.</li><li>Update some leftover wave_matrix references.</li> |
  | 06-15-2022   |  <li>added "Acc" to the end of the fragment accumulator types</li><li>added an element stride parameter to the fragment accumulator Load/Store methods</li><li>updated stride constraints and descriptions around stride and alignment</li><li>renamed bTranspose to bColMajor for clarity.</li><li>updated comments in examples around transpose</li><li>fixed out-of-spec behavior in third example</li><li>added wavesize attribute usage to examples</li>  |

_______________________________________
