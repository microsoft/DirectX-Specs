# D3D12: Application Specific Driver State<!-- omit in TOC -->

v0.04 12/14/2023

---

# Contents <!-- omit in TOC -->

- [D3D12: Application Specific Driver State](#d3d12-application-specific-driver-state)
- [Contents ](#contents-)
- [Summary](#summary)
- [Proposed API/DDI](#proposed-apiddi)
  - [API](#api)
    - [ID3D12DeviceTools](#id3d12devicetools)
    - [ID3D12DeviceFactory1](#id3d12devicefactory1)
  - [DDI](#ddi)
  - [Blob layout](#blob-layout)
  - [D3D12\_SERIALIZED\_DATA\_TYPE](#d3d12_serialized_data_type)
  - [Meta Command version](#meta-command-version)
- [Test Plan](#test-plan)
- [Spec History](#spec-history)

---

# Summary

D3D12 drivers occasionally have to perform workarounds for bugs in specific applications. For example, this may occur if an older game shipped with a bug that only affects a new generation of GPUs. The driver may be forced to detect when the application is running and then perform an application-specific workaround for the bug. This behavior is often called "app detect".

This "app detect" behavior causes problems for capture/replay tools like PIX on Windows. For example, if PIX is capturing an application that is subject to "app detect" driver changes, then the application will work at capture time but PIX may hit errors when it tries to replay the captured GPU workload in a separate PIX process.

This spec proposes new D3D12 functionality that would allow capture/replay tools such as PIX to capture any active application specific workarounds, store them in the capture file, and then tell the driver to set them at replay time. This is generalized to "application specific driver state".

# Proposed API/DDI

## API

### ID3D12DeviceTools

```c++

typedef enum D3D12_APPLICATION_SPECIFIC_DRIVER_BLOB_STATUS
{
    D3D12_APPLICATION_SPECIFIC_DRIVER_BLOB_UNKNOWN	        = 1,
    D3D12_APPLICATION_SPECIFIC_DRIVER_BLOB_USED             = 2,
    D3D12_APPLICATION_SPECIFIC_DRIVER_BLOB_IGNORED	        = 3,
    D3D12_APPLICATION_SPECIFIC_DRIVER_BLOB_NOT_SPECIFIED	= 4
} 	D3D12_APPLICATION_SPECIFIC_DRIVER_BLOB_STATUS;

interface ID3D12DeviceTools
{
    HRESULT GetApplicationSpecificDriverState(ID3DBlob** ppBlob);
    D3D12_APPLICATION_SPECIFIC_DRIVER_BLOB_STATUS GetApplicationSpecificDriverBlobStatus();
}
```

|Enum|Meaning|
|----|-------|
|```D3D12_APPLICATION_SPECIFIC_DRIVER_BLOB_UNKNOWN```|Runtime does not know the status|
|```D3D12_APPLICATION_SPECIFIC_DRIVER_BLOB_USED```|Set application specific driver blob is used by the driver|
|```D3D12_APPLICATION_SPECIFIC_DRIVER_BLOB_IGNORED```|Set application specific driver blob is ignored by the driver|
|```D3D12_APPLICATION_SPECIFIC_DRIVER_BLOB_NOT_SPECIFIED```|No application specific driver blob has been set|

```ID3D12DeviceTools``` can be QueryInterface'd from an ```ID3D12Device``` object. This interface will always be supported by new versions of D3D12.

```GetApplicationSpecificDriverState()``` is used to retrieve a blob of bytes that represents the application-specific driver state. Tools like PIX on Windows would be expected to call this API at capture time. The API will return DXGI_ERROR_UNSUPPORTED if the current driver doesn't support the corresponding DDI. The API is not restricted to developer mode.

```GetApplicationSpecificDriverBlobStatus()``` is used to inquire whether a driver is using set application specific driver state or not. `D3D12_APPLICATION_SPECIFIC_DRIVER_BLOB_STATUS` provides information about whether the device is using application specific driver blob passed in `SetApplicationSpecificDriverState()`. However, it's important to note that this enum does not indicate anything about whether `GetApplicationSpecificDriverState()` can be called or not.

### ID3D12Tools1

```c++
interface ID3D12Tools1 : ID3D12Tools
{
    HRESULT SetApplicationSpecificDriverState(IUnknown* pAdapter, ID3DBlob* pBlob);
}
```

```ID3D12Tools1``` can be QueryInterface'd from an ```ID3D12Tools``` object. This interface will always be supported by new versions of D3D12. This interface is only intended to be used by tools such as PIX.

```SetApplicationSpecificDriverState()``` can be used to set blob of bytes that was previously retrieved via ```GetApplicationSpecificDriverState()```. Tools like PIX on Windows would be expected to call ```SetApplicationSpecificDriverState()``` at replay time.

```SetApplicationSpecificDriverState()``` must be called before any devices are created in the process. The blob cannot be changed once the device is created. It is, however, legal for the ```pBlob``` parameter to be nullptr: this resets the application-specific driver state to the same state it was in before any call to ```SetApplicationSpecificDriverState()``` was made on ```ID3D12Tools1```.

```pAdapter``` cannot be nullptr. The caller is responsible for selecting the right adapter/driver for the blob. Internally, the runtime maintains a map of adapter LUIDs to blobs of bytes. At device creation time, the runtime can then look up adapter-specific blob in the map and pass it to the driver. This is for multi-GPU scenarios: the caller could, for example, pass in one blob captured from a dGPU and another blob from an iGPU. Without additional information, such as ```pAdapter```, the runtime cannot match the blobs with their adapters. 

```SetApplicationSpecificDriverState()``` can only succeed if Windows developer mode is enabled. The API will return a failure HRESULT if Windows developer mode is not enabled.

### D3D12_FEATURE_APPLICATION_SPECIFIC_DRIVER_STATE
`D3D12_FEATURE_APPLICATION_SPECIFIC_DRIVER_STATE` is added to define a cap for this feature.
```
typedef struct D3D12_FEATURE_DATA_APPLICATION_SPECIFIC_DRIVER_STATE
{
    [annotation("_Out_")] BOOL Supported;
} D3D12_FEATURE_DATA_APPLICATION_SPECIFIC_DRIVER_STATE;
```
```
typedef enum D3D12_FEATURE
{
    D3D12_FEATURE_D3D12_OPTIONS                         =  0,
    D3D12_FEATURE_ARCHITECTURE                          =  1, // Deprecated by D3D12_FEATURE_ARCHITECTURE1
    ...
    D3D12_FEATURE_APPLICATION_SPECIFIC_DRIVER_STATE     = 56,
```

## DDI

### `D3D12DDI_APP_SPECIFIC_DRIVER_BLOB_STATUS`

```
typedef enum D3D12DDI_APPLICATION_SPECIFIC_DRIVER_BLOB_STATUS
{
  D3D12DDI_APPLICATION_SPECIFIC_DRIVER_BLOB_UNKNOWN       = 1,
  D3D12DDI_APPLICATION_SPECIFIC_DRIVER_BLOB_USED          = 2,
  D3D12DDI_APPLICATION_SPECIFIC_DRIVER_BLOB_IGNORED       = 3,
  D3D12DDI_APPLICATION_SPECIFIC_DRIVER_BLOB_NOT_SPECIFIED = 4,
} D3D12DDI_APPLICATION_SPECIFIC_DRIVER_BLOB_STATUS;
```

### `D3D12DDI_DEVICE_FUNCS_CORE_0113`

DDI rev 113 adds `pfnGetApplicationSpecificDriverStateBlobSize`, `pfnGetApplicationSpecificDriverState` and `pfnGetApplicationSpecificDriverBlobStatus` to get application specific driver state blob size, blob data, and blob status, respectively.

```
typedef UINT ( APIENTRY* PFND3D12DDI_GET_APPLICATION_SPECIFIC_DRIVER_STATE_BLOB_SIZE_0113 )(
    D3D12DDI_HDEVICE hDrvDevice);
```

```
typedef HRESULT ( APIENTRY* PFND3D12DDI_GET_APPLICATION_SPECIFIC_DRIVER_STATE_0113 )(
    D3D12DDI_HDEVICE hDrvDevice,
    void *pApplicationSpecificDriverBlob,
    UINT pApplicationSpecificDriverBlobSize
     );
```

```
typedef D3D12DDI_APPLICATION_SPECIFIC_DRIVER_BLOB_STATUS (APIENTRY* PFND3D12DDI_GET_APPLICATION_SPECIFIC_DRIVER_BLOB_STATUS_0113)(
    D3D12DDI_HDEVICE hDrvDevice);
```

```
typedef struct D3D12DDI_DEVICE_FUNCS_CORE_0113
{
    PFND3D12DDI_CHECKFORMATSUPPORT                                      pfnCheckFormatSupport;
    PFND3D12DDI_CHECKMULTISAMPLEQUALITYLEVELS                           pfnCheckMultisampleQualityLevels;
    PFND3D12DDI_GETMIPPACKING                                           pfnGetMipPacking;
    ....
    PFND3D12DDI_GET_APPLICATION_SPECIFIC_DRIVER_STATE_BLOB_SIZE_0113    pfnGetApplicationSpecificDriverStateBlobSize;
    PFND3D12DDI_GET_APPLICATION_SPECIFIC_DRIVER_STATE_0113              pfnGetApplicationSpecificDriverState;
    PFND3D12DDI_GET_APPLICATION_SPECIFIC_DRIVER_BLOB_STATUS_0113        pfnGetApplicationSpecificDriverBlobStatus;
} D3D12DDI_DEVICE_FUNCS_CORE_0113;
```

### `D3DDDI_QUERYADAPTERTYPE`

`D3DDDI_QUERYADAPTERTYPE` adds a new enum type, `D3DDDI_QUERYADAPTERTYPE_APPLICATIONSPECIFICDRIVERBLOB`, for application specific driver blob. This enum allows the driver to get the application specific driver blob as early as possible through `QueryAdapterInfoCB2`.

```
typedef enum _D3DDDI_QUERYADAPTERTYPE
{
    D3DDDI_QUERYADAPTERTYPE_DRIVERPRIVATE                   = 0,
    D3DDDI_QUERYADAPTERTYPE_QUERYREGISTRY                   = 1,
    D3DDDI_QUERYADAPTERTYPE_APPLICATIONSPECIFICDRIVERBLOB   = 2, 
} D3DDDI_QUERYADAPTERTYPE;
```

When the driver queries for application specific driver blob:

- For existing runtimes, this returns `E_INVALIDARG`.

- For runtimes that don't have any application specific driver blob, this returns `D3DDDIERR_NOTAVAILABLE`.

- For runtimes that have application specific driver blob for the adapter, this returns `S_OK`. The buffer that `pPrivateDriverData` in `D3DDDICB_QUERYADAPTERINFO2` points to is populated with application specific driver blob. `PrivateDriverDataSize` in `D3DDDICB_QUERYADAPTERINFO2`, which specifies the buffer size on input, is set to the size of application specifc driver blob. Note that a pointer to `D3DDDICB_QUERYADAPTERINFO2` is passed as an arguemnt to `QueryAdapterInfoCB2`. The driver is responsible for ensuring that the buffer is large enough to contain the application specific driver blob. If the buffer size is less than the size of the application specific driver blob, then this function returns `E_NOT_SUFFICIENT_BUFFER` and sets `PrivateDriverDataSize` to the required buffer size, i.e. application specific driver blob size. 

## Blob layout
The outputted blob will be a ```D3D12_SERIALIZED_DATA_DRIVER_MATCHING_IDENTIFIER``` header followed by an driver-specific opaque blob of bytes that represents its internal application specific state. Both the header and the opaque blob are generated by the driver.

Please see the [DirectX Raytracing functional](https://microsoft.github.io/DirectX-Specs/d3d/Raytracing.html#d3d12_serialized_data_driver_matching_identifier) spec for more information about driver matching identifiers.

The size and layout of the opaque blob is determined by the driver. 

## D3D12_SERIALIZED_DATA_TYPE 
A new value is added to this enum:

```c++
typedef enum D3D12_SERIALIZED_DATA_TYPE {
  D3D12_SERIALIZED_DATA_RAYTRACING_ACCELERATION_STRUCTURE = 0,
  D3D12_SERIALIZED_DATA_APPLICATION_SPECIFIC_DRIVER_STATE = 1,
} ;
```

This allows an application to call ```ID3D12Device5::CheckDriverMatchingIdentifier()``` to validate that a blob previously retrieved via ```GetApplicationSpecificDriverState()``` is compatible with the current device/driver. This can be used to determine if the driver ignored the set application specific driver state blob due to incompatiblity issues. 

## Meta Command version
The new interface and method defined in this spec will be supported by all versions of D3D12 going forward. However, tools like PIX on Windows also want to be able to retrieve the application-specific driver state from applications that are using older versions of D3D12. To enable this, we also define a meta command version of ```GetApplicationSpecificDriverState()``` that will work on older versions of D3D12.

We reserve a new meta command called ```GUID_MetaCommand_GetApplicationSpecificDriverState```. This meta command does not take any parameters as input during creation, and need not be initialized via ```InitializeMetaCommand()```. 

When ```GUID_MetaCommand_GetApplicationSpecificDriverState``` is executed, a pointer to a struct of ```{ UINT *pBlobSize, void *pApplicationSpecificDriverStateBlob }``` will be passed into ```ExecuteMetaCommand()```. ```pApplicationSpecificDriverStateBlob``` points to CPU memory that the driver is expected to write application specific driver state blob to. Note that this operation is expected to occur when the command is recorded into the command list. ```pBlobSize``` points to UINT that represents the allocated memory size. The blob should be identical to the blob that would be returned by ```GetApplicationSpecificDriverState()```. If ```*pBlobSize``` is less than the size of the application specific driver blob, then the driver is expected to write required size to ```pBlobSize```.  

We do not need an equivalent meta command for ```SetApplicationSpecificDriverState()``` because we can assume that the callers (i.e. tools like PIX on Windows) are using a new enough version of D3D12.

# Test Plan
## Functional Tests
Functional tests will be written using the TAEF framework, use driver-type WARP, hook original DDI calls to mock driver behaviors, and integrate into D3DFunc_12_Core.dll.

* Test runtime behaviors for GetApplicationSpecificDriverState and GetApplicationSpecificDrierBlobStatus
* Validate appropriate debug layer error messages on invalid parameters

## Driver Conformance Tests
Driver conformance tests will be written using the TAEF framework, use driver-type hardware, integrate into D3DConf_12_Core.dll, and verify driver and hardware behavior when application specific driver state blob is retrieved and set.

The important behaviors to test are:
* Verify ```GetApplicationSpecificDriverState``` outputted blob adheres to the blob layout from the spec
* Verify ```GetApplicationSpecificDriverState``` outputted blob can be validated using ```ID3D12Device5::CheckDriverMatchingIdentifier()```
* Verify ```SetApplicationSpecificDriverState``` set blob of bytes is accessible to the driver during device creation, and driver returns appropriate status for it when ```GetApplicationSpecificDriverBlobStatus``` is called after device creation
* Verify ```GetApplicationSpecificDriverBlobStatus``` returns appropriate status
    - If the test set ```GetApplicationSpecificDriverState``` returned "dummy" blob, the driver should return ```BLOB_USED```.
    - If the test set some random blob, the driver should return ```BLOB_IGNORED```.
    - If the test did not set blob, the driver should return ```BLOB_NOT_SPECIFIED```.

Drivers do not need to behave differently for HLK conformance tests so ```GetApplicationSpecificDriverState``` does not populate output blob. For HLK conformance tests, we would need the driver to return a non-empty "dummy" blob. Conformance tests need to be able to tell the driver to return this dummy blob. For this, we use a new meta command called ```GUID_MetaCommand_EnableDummyApplicationSpecificDriverStateBlob```. This meta command does not take any parameters as input during creation, and need not be initialized via ```InitializeMetaCommand()```.

When ```GUID_MetaCommand_EnableDummyApplicationSpecificDriverStateBlob``` is executed, a pointer to a struct of ```{ bool enableDummyApplicationSpecificDriverStateBlob }``` will be passed into ```ExecuteMetaCommand()```. If ```enableDummyApplicationSpecificDriverStateBlob``` is ```true```, the driver is expected to return dummy blob when ```GetApplicationSpecificDriverState``` is called.

Driver can decide what they want to output for driver-specific opaque blob part of the dummy blob. However, the blob needs to follow aforementioned blob layout.

# Spec History

| Version | Date | Details | Author |
|-|-|-|-|
| v0.01 | 30 Dec 2022 | Initial draft spec | Austin Kinross (PIX) |
| v0.02 | 27 Jul 2023 | Documented issues with previous replay side API. Proposed new replay side API to address them | Henchhing Limbu (PIX) |
| v0.03 | 18 Aug 2023 | Updated replay side API to specify what adapter the set blob belongs to | Henchhing Limbu (PIX) |
| v0.04 | 14 Dec 2023 | Add DDI to get blob through QueryAdapterInfo | Henchhing Limbu (PIX) |
| v0.05 | 22 Feb 2024 | Add `D3D12_FEATURE_APPLICATION_SPECIFIC_DRIVER_STATE` | Henchhing Limbu (PIX) |
| v0.06 | 08 Mar 2024 | Update MetaCommand spec | Henchhing Limbu (PIX) |
| v0.07 | 07 Aug 2024 | Update proposed DDI version to 113, add ```D3D12_APPLICATION_SPECIFIC_DRIVER_BLOB_UNKNOWN```, add functional and conformance tests plan | Henchhing Limbu (PIX) |
