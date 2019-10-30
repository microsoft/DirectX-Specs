# D3D12 Motion Estimation

## Change History

| Date           | Change        |
| -------------- | ------------- |
| **04/09/2018** | Initial draft |
| **04/29/2019** | Update to shipped DDI spec |
| **05/09/2019** | Unsupported DDI functions *may* be null. |

## Open Issues

  | Issue Number | Description |
  | ------------ | ----------- |
  |              |             |


## Overview 

This feature exposes a motion search operation to produce motion vectors for the purpose of extrapolating future frames. Our Analog team wants to leverage motion vectors in the VR compositor to boost an applications effective frame rate from 45 FPS to 90 FPS.

Video encoders include a motion search as part of the encoder process, so the aim is to use the fixed function encoder to produce motion vectors in parallel to application 3d rendering.  Encoders are optimized to improve compression, but the goal is to understand motion.  Any tuning toward that end is interesting.

The VR compositor is D3D12 based, and this is a D3D12 only feature.

## Quality

Microsoft is not specifying the details of the algorithm used to produce motion vectors. Instead we will validate the feature on how well it works in the scenario with the VR compositor. Automated testing for the HLK will be developed by the analog team to represent this higher level scenario. In RS5, this testing will focus on confirming basic function of the feature and not certifying the motion estimation works well in the VR scenario. Instead analog will rely on manual scenario testing.

This spec defines a Luma only motion search at this time, but are evaluating if a chroma search would be useful.

While encoder motion search is typically optimized for compression, this feature is intended for motion vectors that represent visual motion. We are interested in improvements targeting this scenario.

## Performance

Generating motion vectors for both eyes should take less than 5 ms. Analog team is typically color converting and pre-scaling from 1700x1700 to 1200x1200 per eye. Analog team is willing to explore more aggressive scaling if results are still high enough quality for their scenario.

## Color Conversion Or Other GPU Work

The intent of this feature is to perform a motion search on a separate engine from 3D/Compute in order to boost framerate and give the maximum 3D/Compute time to applications.   Any pre or post steps involving other engines, especially 3d/compute, should be discussed with Microsoft. For example, Analog team can handle shaders to scale and color convert. Resolving the IHV dependent layout for motion vectors from HW to the API specified format is an example of work that may be acceptable to use 3D/Compute for. Please identify any such work so we can provide a proper extraction as needed.

Solutions that do not use a fixed function engine separate from the 3D/Compute engine may still be interesting, but these solutions must make use of some hardware advantage not exposed through D3D already (for example, a purely shader based solution that could be written at the API would not be interesting, but the use of unexposed intrinsic or other
optimizations would be). These solutions may need to be faster due to lack of parallelism, and we'll need to consider priority, etc. It may be
more appropriate to move this type of solution to a Meta command.

## HWDRM Support

The motion estimation operation may support reading from and writing to HWDRM protected resources when the driver supports D3D12 protected
resource support. If the inputs are HWDRM protected, the runtime will require that the output is a HWDRM protected resource.

The motion estimation operation is assumed to write to both the MotionEstimator context object and to the MotionVectorHeap, so these must be created with a protected resource session when the input
textures are protected.

## Querying Capabilities

### ENUM: D3D12DDICAPS_TYPE_VIDEO_0020

```c++
typedef enum D3D12DDICAPS_TYPE_VIDEO_0020
{
...
    D3D12DDICAPS_TYPE_VIDEO_0053_FEATURE_AREA_SUPPORT                           = 19,
    D3D12DDICAPS_TYPE_VIDEO_0053_MOTION_ESTIMATOR                               = 20,
    D3D12DDICAPS_TYPE_VIDEO_0053_MOTION_ESTIMATOR_SIZE                          = 21,
...
} D3D12DDICAPS_TYPE_VIDEO_0020;
```

The D3D12DDICAPS_TYPE_VIDEO_0020 enum is extended for new capability checks.  Describes new video capability checks for Motion Estimation.

**Constants**  

*D3D12DDICAPS_TYPE_VIDEO_0053_FEATURE_AREA_SUPPORT*  
Video Decode, Video Processing, and Video Encoding are all versioned under the D3D12 Video extended feature. However, these DDI mostly describe optional features. This cap is added to help shortcut understanding of driver support for any decode, video processing, or encode support making it easier to block queue/commandlist/command recorder/command pool objects. Each of these queue types has required functionality that we don't want to require for encode if motion estimation or encode is not supported. In all cases, all function tables must be fully populated, but not reporting a queue type allows you to populate the function tables with nullptr.

By reporting any video feature version, driver must support the pfnGetCaps member of D3D12DDI_DEVICE_FUNCS_VIDEO.

*D3D12DDICAPS_TYPE_VIDEO_0053_MOTION_ESTIMATOR*  
Checks for motion estimator support.  See D3D12DDI_VIDEO_MOTION_ESTIMATOR_DATA_0053.

*D3D12DDICAPS_TYPE_VIDEO_0053_MOTION_ESTIMATOR_SIZE*  
Checks for Motion Estimator object sizes.  D3D12 applications are given a budget.  This helps applications account for these objects.

### STRUCT: D3D12DDI_VIDEO_FEATURE_AREA_SUPPORT_DATA_0053
```c++
// D3D12DDICAPS_TYPE_VIDEO_0053_FEATURE_AREA_SUPPORT
// *pInfo = nullptr
// pData = D3D12DDI_VIDEO_FEATURE_AREA_SUPPORT_DATA_0053
// DataSize = sizeof(D3D12DDI_VIDEO_FEATURE_AREA_SUPPORT_DATA_0053)
typedef struct D3D12DDI_VIDEO_FEATURE_AREA_SUPPORT_DATA_0053
{
    UINT NodeIndex;                                                     // input
    BOOL VideoDecodeSupport;                                            // output
    BOOL VideoProcessSupport;                                           // output
    BOOL VideoEncodeSupport;                                            // output
} D3D12DDI_VIDEO_FEATURE_AREA_SUPPORT_DATA_0053;
```
The command types supported by driver. Driver must report support for at least one video command type if the video feature version is supported.  

**Members**

*NodeIndex*  
In multi-adapter operation, this indicates which physical adapter of the device this operation applies to.

*VideoDecodeSupport*  

If VideoDecodeSupport is TRUE:

- Predication, timestamp queries, and history buffers must be supported with the decode queue type.
  
- The table corresponding to the following table types for the reported video feature must be fully populated:  
D3D12DDI_TABLE_TYPE_0022_COMMAND_LIST_VIDEO_DECODE  
D3D12DDI_TABLE_TYPE_0022_COMMAND_QUEUE_VIDEO_DECODE.

- Also, the following members of the table type corresponding to D3D12DDI_TABLE_TYPE_0020_DEVICE_VIDEO and the reported video feature version must be populated:  
pfnCalcPrivateVideoDecoderSize  
pfnCreateVideoDecoder  
pfnDestroyVideoDecoder  
pfnCalcPrivateVideoDecoderHeapSize  
pfnCreateVideoDecoderHeap  
pfnDestroyVideoDecoderHeap  

When the flag is not set, all of these functions may be set to nullptr.


*VideoProcessSupport*  

If VideoProcessSupport is TRUE:

- Predication, timestamp queries, and history buffers must be supported with the video process queue type.
  
- The table corresponding to the following table types for the reported video feature must be fully populated:  
D3D12DDI_TABLE_TYPE_0022_COMMAND_LIST_VIDEO_PROCESS
D3D12DDI_TABLE_TYPE_0022_COMMAND_QUEUE_VIDEO_PROCESS

-Also, the following members of the table type corresponding to D3D12DDI_TABLE_TYPE_0020_DEVICE_VIDEO and the reported video feature version must be populated:  
pfnCalcPrivateVideoProcessorSize  
pfnCalcPrivateVideoProcessorSize  
pfnCreateVideoProcessor  
pfnDestroyVideoProcessor  

When the flag is not set, all of these functions may be set to nullptr.

*VideoEncodeSupport*  

If VideoEncodeSupport is TRUE:

- Predication, timestamp queries, and history buffers must be supported with the video encode queue type.

- The table corresponding to the following table types for the reported video feature must be fully populated:  
D3D12DDI_TABLE_TYPE_COMMAND_LIST_VIDEO_ENCODE  
D3D12DDI_TABLE_TYPE_0053_COMMAND_QUEUE_VIDEO_ENCODE  

- Also, the following members of the table type corresponding to D3D12DDI_TABLE_TYPE_0020_DEVICE_VIDEO and the reported video feature version must be populated:  
pfnCalcPrivateMotionEstimatorSize  
pfnCreateMotionEstimator  
pfnDestroyMotionEstimator  

When the flag is not set, all of these functions may be set to nullptr.

### STRUCT: D3D12DDI_VIDEO_MOTION_ESTIMATOR_DATA_0053
```c++
// D3D12DDICAPS_TYPE_VIDEO_0053_MOTION_ESTIMATOR
// *pInfo = nullptr
// pData = D3D12DDI_VIDEO_MOTION_ESTIMATOR_DATA_0060
// DataSize = sizeof(D3D12DDI_VIDEO_MOTION_ESTIMATOR_DATA_0060)
typedef struct D3D12DDI_VIDEO_MOTION_ESTIMATOR_DATA_0060
{
    UINT NodeIndex;                                                                           // input
    DXGI_FORMAT InputFormat;                                                                  // input
    D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_FLAGS_0053 BlockSizeFlags;              // output
    D3D12DDI_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_FLAGS_0053 PrecisionFlags;               // output
    D3D12DDI_VIDEO_SIZE_RANGE_0032 SizeRange;                                                 // output
} D3D12DDI_VIDEO_MOTION_ESTIMATOR_DATA_0060;
```

**Members**

*NodeIndex*  
In multi-adapter operation, this indicates which physical adapter of the device this operation applies to.

*InputFormat*  
The DXGI_FORMAT of the input frame and reference frame. Currently only DXGI_FORMAT_NV12 is allowed.

*BlockSizeFlags*  
The block sizes supported by driver. At least one bit must be set to support the motion estimation operation. Set to NONE if not supported. See D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_FLAGS_0053 for more details.

*PrecisionFlags*  
The precision supported by driver. At least one bit must be set to support the motion estimation operation. Set to NONE if not supported. See D3D12DDI_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_FLAGS_0053 for more details.

*SizeRange*  
Sets the minimum and maximum input and reference size in Pixels supported by driver. Set to zeros when motion estimation is not supported.

### STRUCT: D3D12DDI_VIDEO_MOTION_ESTIMATOR_SIZE_DATA_0060
-------------------------------------------------------
```c++
// D3D12DDICAPS_TYPE_VIDEO_0053_MOTION_ESTIMATOR_SIZE
// *pInfo = nullptr
// pData = D3D12DDI_VIDEO_MOTION_ESTIMATOR_SIZE_DATA_0060
// DataSize = sizeof(D3D12DDI_VIDEO_MOTION_ESTIMATOR_SIZE_DATA_0060)
typedef struct D3D12DDI_VIDEO_MOTION_ESTIMATOR_SIZE_DATA_0060
{
    UINT NodeMask;                                                              // input
    DXGI_FORMAT InputFormat;                                                    // input
    D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_0053 BlockSize;           // input
    D3D12DDI_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_0053 Precision;            // input
    D3D12DDI_VIDEO_SIZE_RANGE_0032 SizeRange;                                   // input
    BOOL Protected;                                                             // input 
    UINT64 MotionEstimatorMemoryPoolL0Size;                                     // output
    UINT64 MotionEstimatorMemoryPoolL1Size;                                     // output
    UINT64 MotionVectorHeapMemoryPoolL0Size;                                    // output
    UINT64 MotionVectorHeapMemoryPoolL1Size;                                    // output
} D3D12DDI_VIDEO_MOTION_ESTIMATOR_SIZE_DATA_0060;
```
This cap determines the residency size for the motion estimator and the hardware dependent output buffer when called with the same creation parameters.

**Members**

*NodeIndex*  
In multi-adapter operation, this indicates which physical adapter of the device this operation applies to.

*InputFormat*  
The DXGI_FORMAT of the input frame and reference frame. Currently only DXGI_FORMAT_NV12 is allowed.

*BlockSize*  
The block size to use with the motion estimator. See D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_0053 for details.

*Precision*  
The precision to use with the motion estimator. See D3D12DDI_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_0053 for more details.

*SizeRange*  
The size range allowed with the Motion Estimator. This may be a subset of the size range supported by the driver to optimize memory usage.

*Protected*  
TRUE if the motion estimator operates on protected resource input and produces protected output. The driver must also support protected resources for D3D12 to set TRUE. FALSE otherwise.

*MotionEstimatorMemoryPoolL0Size*  
Driver outputs the L0 size of the motion estimator object.  L0 is GPU memory for dGPU and system memory for iGPU.

*MotionEstimatorMemoryPoolL1Size*  
Driver outputs the L1 size of the motion estimator object.  L0 is system memory for dGPU and 0 for iGPU.

*MotionVectorHeapMemoryPoolL0Size*  
Driver outputs the L0 size of the motion vector heap object.  L0 is GPU memory for dGPU and system memory for iGPU.

*MotionVectorHeapMemoryPoolL1Size*  
Driver outputs the L1 size of the motion vector heap object.  L0 is system memory for dGPU and 0 for iGPU.

## Motion Estimator Context Object 

### Motion Estimator
The motion estimation operation has a context object to associate the lifetime of internal allocations needed to perform the operation. All allocations associated with his object should be allocated when the object is created and deallocated when the object is de-allocated. This should include any buffers used as temporary/scratch storage.

Operations against this object may be recorded to command lists in a different order than execution. No two API queue instances may be executing command lists containing this object at the same time and expect valid results. The application is responsible for synchronizing access across multiple queue instances.

### Make Resident and Evict
This object must support PFND3D12DDI_MAKERESIDENT and PFND3D12DDI_EVICT.

### Get Debug Allocation Info
This object must support the PFND3D12DDI_GET_DEBUG_ALLOCATION_INFO DDI. This pre-existing DDI returns the associated kernel mode allocation handles and GPU Virtual Address ranges.

### Query Size
D3D12 applications manage a memory budget and may need to know the size of the motion estimator to do so. See the D3D12DDICAPS_TYPE_VIDEO_0053_MOTION_ESTIMATOR_SIZE caps check.

### Motion Estimator Handle
D3D10DDI_H( D3D12DDI_HMOTIONESTIMATOR )

### Enum: D3D12DDI_HANDLETYPE

```c++
typedef enum D3D12DDI_HANDLETYPE
{
...
D3D12DDI_HT_0053_VIDEO_MOTION_ESTIMATOR = 45,
...
} D3D12DDI_HANDLETYPE;
```

A new handle and Handle Type are defined for the motion estimator object.

### Creating the Motion Estimator

These methods create a motion estimator instance.

#### STRUCT: D3D12DDIARG_CREATE_VIDEO_MOTION_ESTIMATOR_0060
```c++
typedef struct D3D12DDIARG_CREATE_VIDEO_MOTION_ESTIMATOR_0060
{
    UINT NodeMask;
    DXGI_FORMAT InputFormat;
    D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_0053 BlockSize;
    D3D12DDI_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_0053 Precision;
    D3D12DDI_VIDEO_SIZE_RANGE_0032 SizeRange;
    D3D12DDI_HPROTECTEDRESOURCESESSION_0030 hDrvProtectedResourceSession;
} D3D12DDIARG_CREATE_VIDEO_MOTION_ESTIMATOR_0060;
```
Specifies the creation arguments for the motion estimator. Valid arguments are determined by the D3D12DDICAPS_TYPE_0053_VIDEO_MOTION_ESTIMATOR caps check.

**Members**

*NodeMask*  
For single GPU operation, set this to zero. If there are multiple GPU nodes, set a bit to identify the node (the device\'s physical adapter) to which the command queue applies. Each bit in the mask corresponds to a single node. Only 1 bit may be set.

*InputFormat*  
The DXGI_FORMAT of the input and reference frames. This motion estimator may only be used with input textures of this format.

*BlockSize*  
The search block size to use with this motion estimator. This parameter determines the number of motion vectors and difference metrics output during the resolve step. This must be a block size reported as supported by the driver. See D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_0053.

*Precision*  
The precision of motion vector components. This must be a precision reported as supported by the driver. See D3D12DDI_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_0053.

*SizeRange*  
Indicates the minimum and maximum size of the inputs to the motion estimation operation. Actual size is provided at motion estimation time. Driver should allocate at the creation of the motion estimator to support any size within the range. This size range must be a subset of the size range supported by the driver.

*hDrvProtectedResourceSession*  
Indicates the protected resource session to use for the motion estimator. This can inform internal allocations for the motion estimator. This value is NULL if the motion estimator will operate on unprotected resources.

#### FUNCTION: PFND3D12DDI_CALCPRIVATEVIDEOMOTIONESTIMATORSIZE_0060

```c++
typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALCPRIVATEVIDEOMOTIONESTIMATORSIZE_0060 )( D3D12DDI_HDEVICE hDrvDevice, _In_ CONST D3D12DDIARG_CREATE_VIDEO_MOTION_ESTIMATOR_0060* pArgs);
```

The D3D runtime allocates memory for storing the drivers cpu object representing the motion estimator. This method is used to calculate the driver object size.

#### FUNCTION: PFND3D12DDI_CREATEVIDEOMOTIONESTIMATOR_0060

```c++
typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATEVIDEOMOTIONESTIMATOR_0060 )( D3D12DDI_HDEVICE hDrvDevice, _In_ CONST D3D12DDIARG_CREATE_VIDEO_MOTION_ESTIMATOR_0060* pArgs, D3D12DDI_HVIDEOMOTIONESTIMATOR_0053 hDrvMotionEstimator);
```
Creates the Motion Estimator.

### Destroy the Motion Estimator

#### FUNCTION: PFND3D12DDI_DESTROYVIDEOMOTIONESTIMATOR_0053
```c++
typedef VOID ( APIENTRY* PFND3D12DDI_DESTROYVIDEOMOTIONESTIMATOR_0053 )( D3D12DDI_HDEVICE hDrvDevice, D3D12DDI_HVIDEOMOTIONESTIMATOR_0053 hDrvMotionEstimator );
```
Destroys the Motion Estimator.

## Motion Estimation Output Object

### Motion Vector Heap

The Motion Vector Heap object is created to store hardware dependent motion vector output. Motion vector output is opaque.  A resolve operation on a will take this opaque object as input and resolve it to the specified format. The size of this object is driver controlled and determined by D3D12DDICAPS_TYPE_VIDEO_0053_MOTION_ESTIMATOR_SIZE. 

### Make Resident and Evict

This object must support PFND3D12DDI_MAKERESIDENT and PFND3D12DDI_EVICT.

### Get Debug Allocation Info
This object must support the PFND3D12DDI_GET_DEBUG_ALLOCATION_INFO DDI. This pre-existing DDI returns the associated kernel mode allocation handles and GPU Virtual Address ranges.

### Query Size
D3D12 applications manage a memory budget and may need to know the size of the motion vector heap to do so. See the D3D12DDICAPS_TYPE_VIDEO_0053_MOTION_ESTIMATOR_SIZE caps check.

### Motion Vector Heap Handle
D3D10DDI_H( D3D12DDI_HVIDEOMOTIONVECTORHEAP_0053 )

### Enum: D3D12DDI_HANDLETYPE

```c++
typedef enum D3D12DDI_HANDLETYPE
{
...
D3D12DDI_HT_0053_VIDEO_MOTION_VECTOR_HEAP = 46,
...
} D3D12DDI_HANDLETYPE;
```

A new handle and Handle Type are defined for the motion vector heap object.

### Creating the Motion Vector Heap

These methods create a motion estimator instance.

#### STRUCT: D3D12DDIARG_CREATE_VIDEO_MOTION_VECTOR_HEAP_0060
```c++
typedef struct D3D12DDIARG_CREATE_VIDEO_MOTION_VECTOR_HEAP_0060
{
    UINT NodeMask;
    DXGI_FORMAT InputFormat;
    D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_0053 BlockSize;
    D3D12DDI_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_0053 Precision;
    D3D12DDI_VIDEO_SIZE_RANGE_0032 SizeRange;
    D3D12DDI_HPROTECTEDRESOURCESESSION_0030 hDrvProtectedResourceSession;
} D3D12DDIARG_CREATE_VIDEO_MOTION_VECTOR_HEAP_0060;
```
Specifies the creation arguments for the motion vector heap. Valid arguments are determined by the D3D12DDICAPS_TYPE_0053_VIDEO_MOTION_ESTIMATOR caps check.

**Members**

*NodeMask*  
For single GPU operation, set this to zero. If there are multiple GPU nodes, set a bit to identify the node (the device\'s physical adapter) to which the command queue applies. Each bit in the mask corresponds to a single node. Only 1 bit may be set.

*InputFormat*  
The DXGI_FORMAT of the input and reference frames. This motion vector heap may only be used with input textures of this format.

*BlockSize*  
The search block size to use with this motion vector heap. This parameter determines the number of motion vectors and difference metrics output during the resolve step. This must be a block size reported as supported by the driver. See D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_0053.

*Precision*  
The precision of motion vector components. This must be a precision reported as supported by the driver. See D3D12DDI_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_0053.

*SizeRange*  
Indicates the minimum and maximum size of the inputs to the motion estimation operation. Actual size is provided at motion estimation time. Driver should allocate at the creation of the motion estimator to support any size within the range. This size range must be a subset of the size range supported by the driver.

*hDrvProtectedResourceSession*  
Indicates the protected resource session to use for the motion vector heap. This can inform if internal allocations must be allocated as protected. This value is NULL if the motion estimation operation will operate on only unprotected resources.

#### FUNCTION: PFND3D12DDI_CALCPRIVATEVIDEOMOTIONVECTORHEAPSIZE_0060

```c++
typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALCPRIVATEVIDEOMOTIONVECTORHEAPSIZE_0060 )( D3D12DDI_HDEVICE hDrvDevice, _In_ CONST D3D12DDIARG_CREATE_VIDEO_MOTION_VECTOR_HEAP_0060* pArgs);
```

The D3D runtime allocates memory for storing the drivers cpu object representing the motion vector heap. This method is used to calculate the driver object size.

#### FUNCTION: PFND3D12DDI_CREATEVIDEOMOTIONVECTORHEAP_0060

```c++
typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATEVIDEOMOTIONVECTORHEAP_0060 )( D3D12DDI_HDEVICE hDrvDevice, _In_ CONST D3D12DDIARG_CREATE_VIDEO_MOTION_VECTOR_HEAP_0060* pArgs, D3D12DDI_HVIDEOMOTIONVECTORHEAP_0053 hDrvMotionEstimator);
```
Creates the Motion Vector Heap.  This object represents the hardware dependent output of a motion search.

### Destroy the Motion Vector Heap

#### FUNCTION: PFND3D12DDI_DESTROYVIDEOMOTIONVECTORHEAP_0053
```c++
typedef VOID ( APIENTRY* PFND3D12DDI_DESTROYVIDEOMOTIONVECTORHEAP_0053 )( D3D12DDI_HDEVICE hDrvDevice, D3D12DDI_HVIDEOMOTIONVECTORHEAP_0053 hDrvMotionEstimator );
```
Destroys the Motion Vector Heap.

## Motion Estimation Operation

### Struct: D3D12DDI_VIDEO_MOTION_ESTIMATOR_OUTPUT_0053
```c++
typedef struct D3D12DDI_VIDEO_MOTION_ESTIMATOR_OUTPUT_0053
{
    D3D12DDI_HVIDEOMOTIONVECTORHEAP_0053                  hDrvMotionVectorHeap;
} D3D12DDI_VIDEO_MOTION_ESTIMATOR_OUTPUT_0053;
```
Describes the output of the motion estimation operation.

**Members**

*hDrvMotionEstimatorHeap*  
The motion estimator heap stores the motion estimator output in hardware dependent layout.

### Struct: D3D12DDI_VIDEO_MOTION_ESTIMATOR_INPUT_0053
```c++
typedef struct D3D12DDI_VIDEO_MOTION_ESTIMATOR_INPUT_0053
{
    D3D12DDI_HRESOURCE                          hDrvInputTexture2D;
    UINT                                        InputSubresourceIndex;
    D3D12DDI_HRESOURCE                          hDrvReferenceTexture2D;
    UINT                                        ReferenceSubresourceIndex;
    D3D12DDI_HVIDEOMOTIONVECTORHEAP_0053        hDrvPreviousMotionVectorHeap;
} D3D12DDI_VIDEO_MOTION_ESTIMATOR_INPUT_0053;
```

Describes the input to the motion estimation operation.

**Members**

*hDrvInputTexture2D*  
The handle of the current frame.  The operation applies to the entire frame.

*InputSubresourceIndex*  
Indicates the base plane of the Mip and Array Slice to use for the input.

*hDrvReferenceTexture2D*  
The handle of the reference frame, or Past frame, used for motion estimation.

*ReferenceSubresourceIndex*  
Indicates the base plane of the Mip and Array Slice to use for the reference.

*hDrvPreviousMotionVectorHeap*  
This parameter may be NULL indicating that previous motion estimator output should not be considered for this operation. If non-NULL, this buffer contains the hardware dependent output of the previous motion estimator operation and may be used for hinting the current operation.

### Function: PFND3D12DDI_ESTIMATE_MOTION_0053

typedef VOID ( APIENTRY* PFND3D12DDI_ESTIMATE_MOTION_0053 )(
    D3D12DDI_HCOMMANDLIST hDrvCommandList,
    D3D12DDI_HVIDEOMOTIONESTIMATOR_0053 hDrvMotionEstimator,
    CONST D3D12DDI_VIDEO_MOTION_ESTIMATOR_OUTPUT_0053* pOutputArguments,
    CONST D3D12DDI_VIDEO_MOTION_ESTIMATOR_INPUT_0053* pInputArguments
    );

Function to perform the motion estimation operation.

**Members**

*hDrvCommandList*  
Driver handle for a video encode command list.

*hDrvMotionEstimator*  
 Handle to the motion estimator context object. See the Motion Estimation Context Object section for more details.

*pOutputArguments*  
 The output arguments for the motion estimation operation. See D3D12DDI_VIDEO_MOTION_ESTIMATOR_OUTPUT_0053.

*pInputArguments*  
The input arguments for the motion estimation operation. See D3D12DDI_VIDEO_MOTION_ESTIMATOR_INPUT_0053.



Resolving IHV Dependent Output
------------------------------

The resolve operation is expected to be a light-weight translation of hardware dependent output to the API spec'd format.

### STRUCT: D3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT_0060
```c++
typedef struct D3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT_0060
{
    D3D12DDI_HRESOURCE hDrvMotionVectorTexture2D;
    D3D12DDI_RESOURCE_COORDINATE_0053 MotionVectorCoordinate;
} D3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT_0060;
```

Describes the output output of the resolve operation.

**Members**

*hDrvMotionVectorTexture2D*  
The output resource for resolved motion vectors. Motion vectors are resolved to a or DXGI_FORMAT_R16G16_SINT 2d textures. The resolved data is expected to be signed 16 byte integer with quarter pel units with the X vector component stored in the R component and the Y vector component stored in the G component. Motion vectors are stored in a 2D layout that corresponds to the pixel layout of the original input textures.

*MotionVectorCoordinate*  
Specifies the output origin of the motion vectors. The remaining sub-region must be large enough to store all motion vectors per block specified by the input PixelWidth/Pixelheight and the D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_FLAGS_0053.


### STRUCT: D3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_INPUT_0053
```c++
typedef struct D3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_INPUT_0053
{
    D3D12DDI_HVIDEOMOTIONVECTORHEAP_0053                    hDrvMotionVectorHeap;
    UINT                                                    PixelWidth;
    UINT                                                    PixelHeight;
} D3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_INPUT_0053;
```
Describes the input of the resolve operation.

**Members**

*hDrvMotionVectorHeap*  
The motion vector heap containing the hardware dependent data layout of the motion search.

*PixelWidth*  
The pixel width of the texture that the motion estimation operation was performed on.  The motion estimator heap may be allocated to support a size range, this parameter informs the size of the last motion estimation operation.

*PixelHeight*  
The pixel height of the texture that the motion estimation operation was performed on.  The motion estimator heap may be allocated to support a size range, this parameter informs the size of the last motion estimation operation.

### FUNCTION: PFND3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_0060

```c++
typedef VOID ( APIENTRY* PFND3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_0060 )( 
    D3D12DDI_HCOMMANDLIST hDrvCommandList,
    CONST D3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT_0060* pOutputArguments,
    CONST D3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_INPUT_0053* pInputArguments    
    );
```

The function used to record the resolve operation for the motion estimation data.

**Members**

*hDrvCommandList*  
This video encode command list used to record the resolve operation.

*pOutputArguments*  
The output arguments for the resolve operation. See D3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT_0060.

*pInputArguments*  
The input arguments for the resolve operation. See D3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_INPUT_0053.

## DDI Versioning

The D3D12DDI_FEATURE_VERSION_VIDEO is revised to indicate the capability check is valid and a new video encode command list function table should be used. This feature version depends on supporting an RS5 core DDI version.

### Revised Tables

```c++
typedef struct D3D12DDI_DEVICE_FUNCS_VIDEO_0063
{
    PFND3D12DDI_VIDEO_GETCAPS                                           pfnGetCaps;
    PFND3D12DDI_CALCPRIVATEVIDEODECODERSIZE_0032                        pfnCalcPrivateVideoDecoderSize;
    PFND3D12DDI_CREATEVIDEODECODER_0032                                 pfnCreateVideoDecoder;
    PFND3D12DDI_DESTROYVIDEODECODER_0021                                pfnDestroyVideoDecoder;
    PFND3D12DDI_CALCPRIVATEVIDEODECODERHEAPSIZE_0033                    pfnCalcPrivateVideoDecoderHeapSize;
    PFND3D12DDI_CREATEVIDEODECODERHEAP_0033                             pfnCreateVideoDecoderHeap;
    PFND3D12DDI_DESTROYVIDEODECODERHEAP_0032                            pfnDestroyVideoDecoderHeap;
    PFND3D12DDI_CALCPRIVATEVIDEOPROCESSORSIZE_0043                      pfnCalcPrivateVideoProcessorSize;
    PFND3D12DDI_CREATEVIDEOPROCESSOR_0043                               pfnCreateVideoProcessor;
    PFND3D12DDI_DESTROYVIDEOPROCESSOR_0021                              pfnDestroyVideoProcessor;
    PFND3D12DDI_CALCPRIVATEVIDEOMOTIONESTIMATORSIZE_0060                pfnCalcPrivateVideoMotionEstimatorSize;
    PFND3D12DDI_CREATEVIDEOMOTIONESTIMATOR_0060                         pfnCreateVideoMotionEstimator;
    PFND3D12DDI_DESTROYVIDEOMOTIONESTIMATOR_0053                        pfnDestroyVideoMotionEstimator;
    PFND3D12DDI_CALCPRIVATEVIDEOMOTIONVECTORHEAPSIZE_0060               pfnCalcPrivateVideoMotionVectorHeapSize;
    PFND3D12DDI_CREATEVIDEOMOTIONVECTORHEAP_0060                        pfnCreateVideoMotionVectorHeap;
    PFND3D12DDI_DESTROYVIDEOMOTIONVECTORHEAP_0053                       pfnDestroyVideoMotionVectorHeap;
    PFND3D12DDI_CALCPRIVATEVIDEOEXTENSIONCOMMANDSIZE_0061               pfnCalcPrivateVideoExtensionCommandSize;
    PFND3D12DDI_CREATEVIDEOEXTENSIONCOMMAND_0063                        pfnCreateVideoExtensionCommand;
    PFND3D12DDI_DESTROYVIDEOEXTENSIONCOMMAND_0063                       pfnDestroyVideoExtensionCommand;

} D3D12DDI_DEVICE_FUNCS_VIDEO_0063;
```

### New Tables

```c++
// D3D12DDI_TABLE_TYPE_0053_COMMAND_LIST_VIDEO_ENCODE
typedef struct D3D12DDI_COMMAND_LIST_FUNCS_VIDEO_ENCODE_0060
{
    PFND3D12DDI_CLOSECOMMANDLIST                            pfnCloseCommandList;
    PFND3D12DDI_RESETCOMMANDLIST_0040                       pfnResetCommandList;
    PFND3D12DDI_DISCARD_RESOURCE_0003                       pfnDiscardResource;
    PFND3D12DDI_SET_MARKER                                  pfnSetMarker; 
    PFND3D12DDI_SET_PREDICATION                             pfnSetPredication;
    PFND3D12DDI_BEGIN_END_QUERY_0003                        pfnBeginQuery;
    PFND3D12DDI_BEGIN_END_QUERY_0003                        pfnEndQuery;
    PFND3D12DDI_RESOLVE_QUERY_DATA                          pfnResolveQueryData;
    PFND3D12DDI_RESOURCEBARRIER_0022                        pfnResourceBarrier;
    PFND3D12DDI_ESTIMATE_MOTION_0053                        pfnEstimateMotion;
    PFND3D12DDI_SETPROTECTEDRESOURCESESSION_0030            pfnSetProtectedResourceSession;
    PFND3D12DDI_WRITEBUFFERIMMEDIATE_0032                   pfnWriteBufferImmediate;
    PFND3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_0060       pfnResolveVideoMotionVectorHeap;
} D3D12DDI_COMMAND_LIST_FUNCS_VIDEO_ENCODE_0060;
```

Additionally, the D3D12DDI_TABLE_TYPE_0022_COMMAND_QUEUE_VIDEO_ENCODE table type must be supported with a D3D12DDI_COMMAND_QUEUE_FUNCS_VIDEO_0020.

## Testing

Existing HLK tests are updated for standard queue functionality including writebufferimmediate, predication, timestamp query, and markers.

The motion estimation operation itself is tested in the HLK to ensure basic operation and levels of quality, but subjective usage will determine how fit the support
is for VR scenarios.
