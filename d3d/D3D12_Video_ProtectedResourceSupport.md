# D3D12 Video Protected Resource Support

## Change History

| Date           | Change        |
| -------------- | ------------- |
| **05/29/2019** | Initial draft |

## Open Issues

  | Issue Number | Description |
  | ------------ | ----------- |
  |              |             |

## Overview 

This feature adds optional protected resource support to D3D12 Video operations to WDDM 2.7.  Protected resources for Cross-API sharing and Graphics/Compute/Operations was introduced in WDDM 2.4, but these resources were not yet permitted for video operations until now.

Each video operation adds a new capability check with a support flag so drivers can indicate if that operation supports protected resources .  Indicating support means that operation can read/write protected resources and supports Cross-API sharing if the resource type supports it. Operation support for protected resources is orthogonal to other operation capabilities with the exception of decode profile and interlace type for decode.  Once protected resource support is reported, it must be supported by all the existing non-protected resource capabilities of that operation.  For example, if Decode reports protected resource support and reports decode histogram support for a given format, the decoder must support decode histogram for both non-protected and protected resources.

Creation methods are modified to take an optional D3D12DDI_HPROTECTEDRESOURCESESSION instance.  Drivers are given this parameter at object creation time to inform setup and allocations.  Further, the memory budget checks are revised to indicate whether or not the operation will use protected resources.  When the parameter is non-NULL, this indicates that the operation will write to protected resources.  To write to an unprotected resource, the operation object must be recreated.

Decoder and motion estimation references must be protected resources when the output is a protected resource.  Video processing may read from a combination of protected and unprotected resources when writing to a protected resource.

Before recording one ore more operations that writes to a protected resource, PFND3D12DDI_SETPROTECTEDRESOURCESESSION_0030 must be called with a non-NULL protected resource session.  Calling PFND3D12DDI_SETPROTECTEDRESOURCESESSION_0030 with NULL is required before recording one or more operations that write to non-protected resources.

NOTE: Motion Estimation initially shipped with WDDM 2.6 requiring support for Protected Resources, but this was withdrawn late in the release.  This feature is reintroducing optional protected resource support for motion estimation.

## DDI Changes
Below details the DDI changes that result from this feature.  The _0072 postfix is used to indicate new items in the DDI, but this number is based on the current usermode DDI when the feature is submitted.  Therefore it may be _0073, _0074 etc. in the actual header.

PFND3D12DDI_SETPROTECTEDRESOURCESESSION_0030 has been in video command list DDI tables for some time.  They are not listed as additions below.

Existing support flags for video decode and video processing are extended to indicated protected resource support.

Motion estimation previously introduced creation and size data parameters for protected resource support.  The optional capability check is introduced in WDDM 2.7.  The runtime assumes protected resources are not supported on WDDM 2.6 drivers.

```c++

//----------------------------------------------------------------------------------------------------------------------------------
// D3D12 Extended Feature Video
// Version: D3D12DDI_FEATURE_VERSION_VIDEO_0072
// Usermode DDI Min Version: D3D12DDI_SUPPORTED_0043

#define D3D12DDI_FEATURE_VERSION_VIDEO_0072_0 16u

typedef enum D3D12DDICAPS_TYPE_VIDEO_0020
{
    /* Pre-existing values omitted for clarity */
    D3D12DDICAPS_TYPE_VIDEO_0072_DECODE_PROTECTED_RESOURCES                     = 28,
    D3D12DDICAPS_TYPE_VIDEO_0072_PROCESS_PROTECTED_RESOURCES                    = 29,
    D3D12DDICAPS_TYPE_VIDEO_0072_MOTION_ESTIMATOR_PROTECTED_RESOURCES           = 30,

} D3D12DDICAPS_TYPE_VIDEO_0020;

typedef enum D3D12DDI_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAGS_0072
{
    D3D12DDI_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAG_0072_NONE                    = 0,
    D3D12DDI_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAG_0072_SUPPORTED               = 0x1,

} D3D12DDI_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAGS_0072;
DEFINE_ENUM_FLAG_OPERATORS( D3D12DDI_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAGS_0072 );

// D3D12DDICAPS_TYPE_VIDEO_0072_DECODE_PROTECTED_RESOURCES
// *pInfo = nullptr
// pData = D3D12DDI_VIDEO_DECODE_PROTECTED_RESOURCES_DATA_0072
// DataSize = sizeof(D3D12DDI_VIDEO_DECODE_PROTECTED_RESOURCES_DATA_0072)
typedef struct D3D12DDI_VIDEO_DECODE_PROTECTED_RESOURCES_DATA_0072 
{
    UINT NodeIndex;                                                         // input
    D3D12DDI_VIDEO_DECODE_CONFIGURATION_0020 Configuration;                 // input
    D3D12DDI_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAGS_0072 SupportFlags;      // output
} D3D12DDI_VIDEO_DECODE_PROTECTED_RESOURCES_DATA_0072;

// D3D12DDICAPS_TYPE_VIDEO_0072_PROCESS_PROTECTED_RESOURCES
// *pInfo = nullptr
// pData = D3D12DDI_VIDEO_PROCESS_PROTECTED_RESOURCES_DATA_0072
// DataSize = sizeof(D3D12DDI_VIDEO_PROCESS_PROTECTED_RESOURCES_DATA_0072)
typedef struct D3D12DDI_VIDEO_PROCESS_PROTECTED_RESOURCES_DATA_0072
{
    UINT NodeIndex;                                                                           // input
    D3D12DDI_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAGS_0072 SupportFlags;                        // output
} D3D12DDI_VIDEO_PROCESS_PROTECTED_RESOURCES_DATA_0072;

// D3D12DDICAPS_TYPE_VIDEO_0072_MOTION_ESTIMATOR_PROTECTED_RESOURCES
// *pInfo = nullptr
// pData = D3D12DDI_VIDEO_MOTION_ESTIMATOR_PROTECTED_RESOURCES_DATA_0072
// DataSize = sizeof(D3D12DDI_VIDEO_MOTION_ESTIMATOR_PROTECTED_RESOURCES_DATA_0072)
typedef struct D3D12DDI_VIDEO_MOTION_ESTIMATOR_PROTECTED_RESOURCES_DATA_0072
{
    UINT NodeIndex;                                                                           // input
    D3D12DDI_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAGS_0072 SupportFlags;                        // output
} D3D12DDI_VIDEO_MOTION_ESTIMATOR_PROTECTED_RESOURCES_DATA_0072;

// D3D12DDICAPS_TYPE_VIDEO_0032_DECODER_HEAP_SIZE
// *pInfo = nullptr
// pData = D3D12DDI_VIDEO_DECODER_HEAP_SIZE_DATA_0072
// DataSize = sizeof(D3D12DDI_VIDEO_DECODER_HEAP_SIZE_DATA_0072)
typedef struct D3D12DDI_VIDEO_DECODER_HEAP_SIZE_DATA_0072
{
    D3D12DDIARG_CREATE_VIDEO_DECODER_HEAP_0033  VideoDecoderHeapDesc;       // input
    BOOL                                        Protected;                  // input 
    UINT64                                      MemoryPoolL0Size;           // output
    UINT64                                      MemoryPoolL1Size;           // output
} D3D12DDI_VIDEO_DECODER_HEAP_SIZE_DATA_0072;

// D3D12DDICAPS_TYPE_VIDEO_0032_PROCESSOR_SIZE
// *pInfo = nullptr
// pData = D3D12DDI_VIDEO_PROCESSOR_SIZE_DATA_0072
// DataSize = sizeof(D3D12DDI_VIDEO_PROCESSOR_SIZE_DATA_0072)
typedef struct D3D12DDI_VIDEO_PROCESSOR_SIZE_DATA_0072
{
    D3D12DDIARG_CREATE_VIDEO_PROCESSOR_0043 VideoProcessorDesc;         // input
    BOOL Protected;                                                     // input 
    UINT64 MemoryPoolL0Size;                                            // output
    UINT64 MemoryPoolL1Size;                                            // output
} D3D12DDI_VIDEO_PROCESSOR_SIZE_DATA_0072;

typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALCPRIVATEVIDEODECODERSIZE_0072 )( D3D12DDI_HDEVICE hDrvDevice, _In_ CONST D3D12DDIARG_CREATE_VIDEO_DECODER_0032* pArgs, _In_opt_ D3D12DDI_HPROTECTEDRESOURCESESSION_0030 hDrvProtectedResourceSession);
typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATEVIDEODECODER_0072 )( D3D12DDI_HDEVICE hDrvDevice, _In_ CONST D3D12DDIARG_CREATE_VIDEO_DECODER_0032* pArgs, _In_opt_ D3D12DDI_HPROTECTEDRESOURCESESSION_0030 hDrvProtectedResourceSession, D3D12DDI_HVIDEODECODER_0020 hDrvVideoDecoder );

typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALCPRIVATEVIDEODECODERHEAPSIZE_0072 )( D3D12DDI_HDEVICE hDrvDevice, _In_ CONST D3D12DDIARG_CREATE_VIDEO_DECODER_HEAP_0033* pArgs, _In_opt_ D3D12DDI_HPROTECTEDRESOURCESESSION_0030 hDrvProtectedResourceSession);
typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATEVIDEODECODERHEAP_0072 )( D3D12DDI_HDEVICE hDrvDevice, _In_ CONST D3D12DDIARG_CREATE_VIDEO_DECODER_HEAP_0033*, _In_opt_ D3D12DDI_HPROTECTEDRESOURCESESSION_0030 hDrvProtectedResourceSession, D3D12DDI_HVIDEODECODERHEAP_0032 hDrvVideoDecoderHeap );

typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALCPRIVATEVIDEOPROCESSORSIZE_0072 )( D3D12DDI_HDEVICE hDrvDevice, _In_ CONST D3D12DDIARG_CREATE_VIDEO_PROCESSOR_0043* pArgs, _In_opt_ D3D12DDI_HPROTECTEDRESOURCESESSION_0030 hDrvProtectedResourceSession);
typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATEVIDEOPROCESSOR_0072 )( D3D12DDI_HDEVICE hDrvDevice, _In_ CONST D3D12DDIARG_CREATE_VIDEO_PROCESSOR_0043* pArgs, _In_opt_ D3D12DDI_HPROTECTEDRESOURCESESSION_0030 hDrvProtectedResourceSession, D3D12DDI_HVIDEOPROCESSOR_0020 hDrvVideoProcessor);

// D3D12DDI_TABLE_TYPE_0020_DEVICE_VIDEO
typedef struct D3D12DDI_DEVICE_FUNCS_VIDEO_0072
{
    PFND3D12DDI_VIDEO_GETCAPS                                           pfnGetCaps;
    PFND3D12DDI_CALCPRIVATEVIDEODECODERSIZE_0072                        pfnCalcPrivateVideoDecoderSize;
    PFND3D12DDI_CREATEVIDEODECODER_0072                                 pfnCreateVideoDecoder;
    PFND3D12DDI_DESTROYVIDEODECODER_0021                                pfnDestroyVideoDecoder;
    PFND3D12DDI_CALCPRIVATEVIDEODECODERHEAPSIZE_0072                    pfnCalcPrivateVideoDecoderHeapSize;
    PFND3D12DDI_CREATEVIDEODECODERHEAP_0072                             pfnCreateVideoDecoderHeap;
    PFND3D12DDI_DESTROYVIDEODECODERHEAP_0032                            pfnDestroyVideoDecoderHeap;
    PFND3D12DDI_CALCPRIVATEVIDEOPROCESSORSIZE_0072                      pfnCalcPrivateVideoProcessorSize;
    PFND3D12DDI_CREATEVIDEOPROCESSOR_0072                               pfnCreateVideoProcessor;
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
} D3D12DDI_DEVICE_FUNCS_VIDEO_0072;

```