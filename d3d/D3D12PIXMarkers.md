# D3D12: PIX Markers
v0.01 12 Mar 2026

---

# Contents
- [D3D12: PIX Markers ](#d3d12-pix-markers)
- [Contents](#contents)
- [Summary](#summary)
- [Proposed API](#proposed-api)
- [Proposed DDI](#proposed-ddi)
- [Open Questions](#open-questions)
- [Test Plan](#test-plan)
- [Spec History](#spec-history)

---

# Summary

As of 2025, [PIXEvents](https://github.com/microsoft/PixEvents) provides APIs to instrument your game, labeling regions of CPU or GPU work and marking important occurences. Common APIs include `PixBeginEvent`, `PixEndEvent`, and `PixSetMarker` which internally call `ID3D12GraphicsCommandList::BeginEvent`, `ID3D12CommandQueue::BeginEvent`, `ID3D12GraphicsCommandList::EndEvent` `ID3D12CommandQueue::EndEvent`, `ID3D12GraphicsCommandList::SetMarker` and `ID3D12CommandQueue::SetMarker` depending on the context.

The limitation of these APIs is that they operate only at the runtime level and do not propagate to the driver. As a result, these markers are absent in [DirectX dump files](D3D12GpuDumps.md), making it difficult to trace the marker hierarchy that led to a TDR or device error.

This proposal introduces a new D3D12 functionality that adds new APIs to configure D3D12 runtime to allow PIX markers and device object names to reach the driver. By doing so, these markers and device object names can be included in GPU dumps for postmortem debugging and made accessible to IHV tools at the driver level—something previously impossible. This driver-level visibility also allows IHVs to incorporate markers and device object names into profiling data.

This functionality is designed to integrate seamlessly with any Windows tooling, including IHV-specific tools, and is not exclusive to PIX. Additionally, PIX Events is available as an open-source software. If IHV tools need to decode marker data, they could use the [PIX events decoder](https://github.com/microsoft/PixEvents) instead of creating their own decoder.

# Proposed API

_Note: The interface numbers are subject to change._

### D3D12_USER_DEFINED_ANNOTATION_MODE

```c++
typedef
enum D3D12_USER_DEFINED_ANNOTATION_MODE
    {
        D3D12_USER_DEFINED_ANNOTATION_MODE_RUNTIME_ONLY = 1,
        D3D12_USER_DEFINED_ANNOTATION_MODE_DRIVER_RETAIL = 2,
    } D3D12_USER_DEFINED_ANNOTATION_MODE;
```
|Enum|Meaning|
|----|-------|
|```D3D12_USER_DEFINED_ANNOTATION_MODE_RUNTIME_ONLY```| API does not make DDI call to UMD |
|```D3D12_USER_DEFINED_ANNOTATION_MODE_DRIVER_RETAIL```| API makes DDI call to UMD |

### ID3D12Tools3

```c++
interface ID3D12DeviceTools2 : ID3D12DeviceTool1
{
    void SetUserDefinedAnnotationMode(D3D12_USER_DEFINED_ANNOTATION_MODE mode);
    D3D12_USER_DEFINED_ANNOTATION_MODE GetUserDefinedAnnotationMode();
}
```

`ID3D12DeviceTools2` interface can be QueryInterface'd from an `ID3D12Device` object. This interface will always be supported by newer versions of D3D12 going forward.

`SetUserDefinedAnnotationMode` configures the behavior of `ID3D12Object::SetName(LPCWSTR Name)` and D3D12 marker APIs listed below.
 * `ID3D12GraphicsCommandList::BeginEvent(UINT Metadata, const void *pData, UINT Size)`
 * `ID3D12GraphicsCommandList::EndEvent()`
 * `ID3D12GraphicsCommandList::SetMarker(UINT Metadata, const void *pData, UINT Size)`

Similar APIs exist for `ID3D12CommandQueue` and `ID3D12VideoProcessCommandList`.

This means that any configuration applied using `ID3D12DeviceTools2` will apply to subsequent device children, such as `ID3D12GraphicsCommandList`, `ID3D12CommandQueue` and `ID3D12VideoProcessCommandList`, created using the device interface. If the annotation mode is modified after some device child objects have already been created, the new setting will only apply to device children that are created after the change. Previously created device children will continue using the annotation mode that was active at the time of their creation. 

For `ID3D12Object::SetName(LPCWSTR Name)`, it is important to note that only device children objects will make DDI calls to UMD.

By default, the runtime annotation mode is `D3D12_USER_DEFINED_ANNOTATION_MODE_RUNTIME_ONLY`.

`GetUserDefinedAnnotationMode` returns the currently active annotation mode.

A new option will be added in [D3DConfig](https://devblogs.microsoft.com/directx/d3dconfig-a-new-tool-to-manage-directx-control-panel-settings/) tool to overwrite annotation mode for all devices and their children. This allows developer tools to enable driver retail mode without awkward workarounds.

### D3D12_FEATURE_USER_DEFINED_ANNOTATION

`D3D12_FEATURE_USER_DEFINED_ANNOTATION` is added to define support check for this feature.

```c++
typedef struct D3D12_FEATURE_DATA_USER_DEFINED_ANNOTATION
{
    BOOL Supported;
} D3D12_FEATURE_DATA_USER_DEFINED_ANNOTATION;
```

```c++
typedef enum D3D12_FEATURE
{
    D3D12_FEATURE_D3D12_OPTIONS                         =  0,
    D3D12_FEATURE_ARCHITECTURE                          =  1, // Deprecated by D3D12_FEATURE_ARCHITECTURE1
    ...
    D3D12_FEATURE_USER_DEFINED_ANNOTATION
} D3D12_FEATURE;
```

### Marker Data Lifetime

The D3D12 runtime marker data by maintaining an internal copy whose lifetime is tied to the associated command allocator. When the command allocator is reset, all marker data linked to it is discarded. If the marker is set in the context of a command queue instead of a command list, its lifetime is instead bound to the command queue.

The runtime also maintains a mapping between each marker’s data and a unique identifier known as an EventID. This EventID is passed along with the marker data to the driver, which may utilize them as needed. The driver’s handling of this data is described in [Proposed DDI](#proposed-ddi) section.

It's important to note that the driver is responsible for managing the lifetime of data that's passed through `PFND3D12DDI_SET_NAME`.

### Thread Safety and Synchronization 
Applications are responsible for synchronizing calls to `SetUserDefinedAnnotationMode` with device child object creation. The annotation mode is device specific mutable state that can be modified concurrently by multiple threads. For example, one thread may set the mode to `D3D12_USER_DEFINED_ANNOTATION_MODE_DRIVER_RETAIL` and create a command queue, while another thread sets the mode to `D3D12_USER_DEFINED_ANNOTATION_MODE_RUNTIME_ONLY` and create a command list. Although the intended behavior is for command queue marker APIs to be forwarded to the driver and command list marker APIs to be remain runtime-only, subsequent mode changes may occur before object creation completes, causing both objects to use the most recently set mode.

# Proposed DDI

### Command List DDIs

DDI rev 121 adds `D3D12DDI_USER_DEFINED_ANNOTATION_FUNCS_0121`.

```c++
//----------------------------------------------------------------------------------------------------------------------------------
// D3D12 PIX Markers
// Feature: D3D12DDI_FEATURE_0121_USER_DEFINED_ANNOTATIONS
// Version: D3D12DDI_FEATURE_VERSION_USER_DEFINED_ANNOTATIONS_0121_0
// Usermode DDI Min Version: D3D12DDI_SUPPORTED_0121
//
//----------------------------------------------------------------------------------------------------------------------------------

#define D3D12DDI_FEATURE_VERSION_USER_DEFINED_ANNOTATIONS_0121_0 1u
#define D3D12DDI_FEATURE_VERSION_USER_DEFINED_ANNOTATIONS_LATEST D3D12DDI_FEATURE_VERSION_USER_DEFINED_ANNOTATIONS_0121_0

// Command Queue 
typedef VOID ( APIENTRY* PFND3D12DDI_COMMAND_QUEUE_BEGIN_EVENT_ON_DRIVER )(
    D3D12DDI_HCOMMANDQUEUE,                     // in: Runtime handle
    UINT Metadata,                              // in: Runtime marker format data version
    _In_reads_(Size) CONST VOID* pData,         // in: Pointer to runtime marker data
    UINT Size,                                  // in: Size in bytes of runtime marker data
    UINT64 EventID);                            // in: ID mapping to runtime marker data

typedef VOID (APIENTRY* PFND3D12DDI_COMMAND_QUEUE_END_EVENT_ON_DRIVER )(
    D3D12DDI_HCOMMANDQUEUE,                     // in: Runtime handle
    UINT64 EventID);                            // in: ID mapping to runtime marker data

typedef VOID ( APIENTRY* PFND3D12DDI_COMMAND_QUEUE_SET_MARKER_ON_DRIVER )(
    D3D12DDI_HCOMMANDQUEUE,                     // in: Runtime handle
    UINT Metadata,                              // in: Runtime marker format data version
    _In_reads_(Size) CONST VOID* pData,         // in: Pointer to runtime marker data
    UINT Size,                                  // in: Size in bytes of runtime marker data
    UINT64 EventID);                            // in: ID mapping to runtime marker data

// Command List
typedef VOID (APIENTRY* PFND3D12DDI_COMMAND_LIST_SET_MARKER_ON_DRIVER )(
    D3D12DDI_HCOMMANDLIST,                      // in: Runtime handle
    UINT Metadata,                              // in: Runtime marker format data version
    CONST VOID* pData,                          // in: Pointer to runtime marker data
    UINT Size,                                  // in: Size in bytes of runtime marker data
    UINT64 EventID);                            // in: ID mapping to runtime marker data

typedef VOID (APIENTRY* PFND3D12DDI_COMMAND_LIST_END_EVENT_ON_DRIVER)(
    D3D12DDI_HCOMMANDLIST,                      // in: Runtime handle
    UINT64 EventID);                            // in: ID mapping to runtime marker data

typedef VOID (APIENTRY* PFND3D12DDI_COMMAND_LIST_BEGIN_EVENT_ON_DRIVER)(
    D3D12DDI_HCOMMANDLIST,                      // in: Runtime handle
    UINT Metadata,                              // in: Runtime marker format data version
    CONST VOID* pData,                          // in: Pointer to runtime marker data
    UINT Size,                                  // in: Size in bytes of runtime marker data
    UINT64 EventID);                            // in: ID mapping to runtime marker data

// SetName
typedef VOID (APIENTRY* PFND3D12DDI_SET_NAME)(
    D3D12DDI_HANDLE_AND_TYPE,                   // in: Runtime handle and handle type
    _In_opt_ LPCWSTR Name);                     // _In_opt_: Name associated with the command list. nullptr if there's no associated name

typedef struct D3D12DDI_USER_DEFINED_ANNOTATION_FUNCS_0121
{
    // Command Queue
    PFND3D12DDI_COMMAND_QUEUE_BEGIN_EVENT     pfnCmdQueueBeginEvent;
    PFND3D12DDI_COMMAND_QUEUE_END_EVENT       pfnCmdQueueEndEvent;
    PFND3D12DDI_COMMAND_QUEUE_SET_MARKER      pfnCmdQueueSetMarker;

    // Command List
    PFND3D12DDI_COMMAND_LIST_BEGIN_EVENT      pfnCmdListBeginEvent;
    PFND3D12DDI_COMMAND_LIST_END_EVENT        pfnCmdListEndEvent;
    PFND3D12DDI_COMMAND_LIST_SET_MARKER       pfnCmdListSetMarker;

    PFND3D12DDI_SET_NAME                      pfnSetName;
} D3D12DDI_USER_DEFINED_ANNOTATION_FUNCS_0121;
```

Drivers are expected to embed runtime marker EventIDs in GPU crash reports to enable the runtime to associate those IDs with corresponding marker data. This correlation allows the runtime to include relevant marker information in the GPU dump. Access to runtime marker data is provided to drivers to support decoding by IHV tools. Drivers may disregard this data if such decoding is not required.

Unlike marker EventIDs, device object names are optional and may be included only if the driver manages the associated device object name data.

# Open Questions

#### Question: Historically, drivers have had the flexibility to rearrange markers relative to other GPU work. Can drivers do that for PIX markers?

This can potentially lead to incorrect marker placement in GPU dumps. Specifically, markers intended to align with recorded GPU commands in the application may appear out of order in the GPU dump, which complicates hang debugging scenarios. It's important to note that such reordering typically occurs within a relatively small scope of GPU work. Therefore, while the impact of marker rearrangement may sound concerning, its practical effect is often limited.However, if future observations reveal that rearrangement spans a broader scope, this issue should be revisited and addressed accordingly.

#### Question: Can it get expesive to keep copies of marker data in D3D12 runtime? Is there some optimization that could be done here?

In practice, we do not anticipate a large volume of marker strings that would result in significant memory overhead. This is because the D3D12 runtime releases marker data upon command allocator reset. We should revisit this if this becomes a substantial issue.

One way to mitigate this would be to hand over the responsibility of managing marker data to the application. We could add an extra API for this and call it "fast path" scenario for now. Since PIX events add a level of indirection, we could potentially get rid of it as well and ask applications to use the runtime API directly. The runtime does not copy the string, and instead keeps a map of marker EventID to app provided data pointer. The copy only happens when generating GPU dump. Of course, there's the issue of dangling pointer here though.

#### Question: Could PIX marker APIs be integrated with auto breadcrumbs for correaltion between D3D runtime and driver-level data?

Auto breadcrumbs are a runtime-side diagnostic feature that's part of DRED. Retail marker APIs could be tracked as part of auto breadcrumbs that could facilitate cross-layer correlation. However, this might be beyond the scope of this feature.

# Test Plan

* Functional test
* Conformance test
* WARP support

_TODO: Update this with more details_

# Spec History

| Version | Date | Details | Author |
|-|-|-|-|
| v0.01 | 12 Mar 2026 | Initial draft spec | Henchhing Limbu (PIX) | 