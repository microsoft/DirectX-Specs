# D3D12: PIX Markers <!-- omit in toc -->
v0.06 06/17/2026

---

# Contents <!-- omit in toc -->
- [Summary](#summary)
- [Proposed API](#proposed-api)
    - [D3D12\_USER\_DEFINED\_ANNOTATION\_MODE](#d3d12_user_defined_annotation_mode)
    - [ID3D12DeviceTools2](#id3d12devicetools2)
    - [D3D12\_FEATURE\_USER\_DEFINED\_ANNOTATION](#d3d12_feature_user_defined_annotation)
    - [Marker Data Lifetime](#marker-data-lifetime)
    - [Thread Safety and Synchronization](#thread-safety-and-synchronization)
- [Proposed DDI](#proposed-ddi)
    - [Command List DDIs](#command-list-ddis)
- [Use Case Example](#use-case-example)
- [D3DConfig Override](#d3dconfig-override)
- [Open Questions](#open-questions)
- [Test Plan](#test-plan)
  - [Functional tests](#functional-tests)
  - [Conformance tests](#conformance-tests)
- [WARP support](#warp-support)
- [Spec History](#spec-history)

---

# Summary

As of 2025, [PIXEvents](https://github.com/microsoft/PixEvents) provides APIs to instrument your game, labeling regions of CPU or GPU work and marking important occurrences. Common APIs include `PixBeginEvent`, `PixEndEvent`, and `PixSetMarker` which internally call `ID3D12GraphicsCommandList::BeginEvent`, `ID3D12CommandQueue::BeginEvent`, `ID3D12GraphicsCommandList::EndEvent` `ID3D12CommandQueue::EndEvent`, `ID3D12GraphicsCommandList::SetMarker` and `ID3D12CommandQueue::SetMarker` depending on the context.

The limitation of these APIs is that they operate only at the runtime level and do not propagate to the driver. As a result, these markers are absent in [DX dump files](D3D12GpuDumps.md), making it difficult to trace the marker hierarchy that led to a GPU crash or TDR.

This proposal introduces a new D3D12 functionality that adds new APIs to configure D3D12 runtime to allow PIX markers and device object names to reach the driver. By doing so, these markers and device object names can be included in DX dump files for postmortem debugging and made accessible to IHV tools at the driver level—something previously impossible. This driver-level visibility also allows IHVs to incorporate markers and device object names into profiling data.

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

### ID3D12DeviceTools2

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

The D3D12 runtime manages marker data by maintaining an internal copy whose lifetime is tied to the associated command allocator. When the command allocator is reset, all marker data linked to it is discarded. If the marker is set in the context of a command queue instead of a command list, its lifetime is instead bound to the command queue.

The runtime also maintains a mapping between each marker’s data and a unique identifier known as an EventID. This EventID is passed along with the marker data to the driver, which may utilize them as needed. The driver’s handling of this data is described in [Proposed DDI](#proposed-ddi) section.

It's important to note that the driver is responsible for managing the lifetime of data that's passed through `PFND3D12DDI_SET_NAME`.

Note that when the annotation mode is `D3D12_USER_DEFINED_ANNOTATION_MODE_RUNTIME_ONLY`, the runtime does not retain a copy of marker data. This is intentional to avoid the bookkeeping cost: since no marker EventID is ever issued to the driver in this mode, the runtime has no need to map an EventID back to marker data.

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

Drivers are expected to embed runtime marker EventIDs in GPU crash reports to enable the runtime to associate those IDs with corresponding marker data. This correlation allows the runtime to include relevant marker information in the crash dump. Access to runtime marker data is provided to drivers to support decoding by IHV tools. Drivers may disregard this data if such decoding is not required.

Unlike marker EventIDs, device object names are optional and may be included only if the driver manages the associated device object name data.

# Use Case Example

Application developers typically want different marker behavior between development and retail builds:

* **During development:** all PIX markers should be visible in tools and in DX dump files, even if that comes at some CPU cost.
* **After the game ships (retail):** only a curated subset of "retail" markers should reach the driver and appear in dumps, so that shipping performance is not impacted by high-frequency development-only markers.

[PIXEvents](https://github.com/microsoft/PixEvents) supports this split with two families of marker macros:

* `PIXBeginEvent` / `PIXEndEvent` / `PIXSetMarker` - general-purpose markers used liberally during development.
* `PIXBeginRetailEvent` / `PIXEndRetailEvent` / `PIXSetRetailMarker` - markers that the application developer explicitly designates as safe to keep in a shipped title.

When the `USE_PIX_RETAIL` preprocessor symbol is defined, the non-retail macros (`PIXBeginEvent`, `PIXEndEvent`, `PIXSetMarker`) compile to no-ops. Only the `PIX*Retail*` variants make runtime calls.

The recommended configurations are:

|Scenario|`USE_PIX_RETAIL` defined?|PIX APIs reaching the runtime|`D3D12_USER_DEFINED_ANNOTATION_MODE`|Result|
|--------|-------------------------|-----------------------------|-------------------------------------|------|
|Development build|No|Both `PIX*` and `PIX*Retail*`|`DRIVER_RETAIL`|All PIX markers are forwarded to the driver and available in DX dump files.|
|Retail build|No|Both `PIX*` and `PIX*Retail*`|`DRIVER_RETAIL`|All markers, including high-frequency development markers, are forwarded to the driver.|
|Retail build|Yes|Only `PIX*Retail*`|`RUNTIME_ONLY`|No markers are forwarded to the driver at runtime.|
|Retail build|Yes|Only `PIX*Retail*`|`DRIVER_RETAIL`|Only retail markers are forwarded to the driver and available in DX dump files. Non-retail markers are compiled out.|

The intent of this design is that existing users of the PIX Event APIs need to make only minimal changes to opt into driver-visible markers in shipped titles.

# D3DConfig Override

A new boolean option, `ForceDriverRetailAnnotations`, is added to [D3DConfig](https://devblogs.microsoft.com/directx/d3dconfig-a-new-tool-to-manage-directx-control-panel-settings/) to force `D3D12_USER_DEFINED_ANNOTATION_MODE_DRIVER_RETAIL` on every D3D12 device created on the system. This lets developer tools and IHVs collect driver-visible markers (and have them appear in DX dump files) without modifying or rebuilding the title.

Behavior:

* The setting is read once at device creation. If it is enabled, the device's annotation mode is initialized to `D3D12_USER_DEFINED_ANNOTATION_MODE_DRIVER_RETAIL` instead of the default `D3D12_USER_DEFINED_ANNOTATION_MODE_RUNTIME_ONLY`.
* While the override is in effect, subsequent calls to `SetUserDefinedAnnotationMode` on that device are accepted but have no effect; the effective mode is not changed.
* `GetUserDefinedAnnotationMode` always returns the device's effective mode. When the override is active, that is `D3D12_USER_DEFINED_ANNOTATION_MODE_DRIVER_RETAIL`.
* The setting only changes the mode in the `DRIVER_RETAIL` direction. There is no corresponding force for `RUNTIME_ONLY`; an application that wants `RUNTIME_ONLY` simply doesn't enable the override (and the default is already `RUNTIME_ONLY`).
* The override applies per-device. Devices created before the setting changes continue using whatever mode they were initialized with.

Example usage from the command line:

```
# Force DRIVER_RETAIL on for all subsequently created D3D12 devices on the system.
d3dconfig device force-driver-retail-annotations=on

# Inspect current D3DConfig device settings (verifies the override is on).
d3dconfig device

# Turn the override back off when finished.
d3dconfig device force-driver-retail-annotations=off
```

# Open Questions

* Question: Historically, drivers have had the flexibility to rearrange markers relative to other GPU work. Can drivers do that for PIX markers?

  This can potentially lead to incorrect marker placement in DX dump files. Specifically, markers intended to align with recorded GPU commands in the application may appear out of order in DX dump file, which complicates hang debugging scenarios. It's important to note that such reordering typically occurs within a relatively small scope of GPU work. Therefore, while the impact of marker rearrangement may sound concerning, its practical effect is often limited. However, if future observations reveal that rearrangement spans a broader scope, this issue should be revisited and addressed accordingly.

* Question: Can it get expensive to keep copies of marker data in D3D12 runtime? Is there some optimization that could be done here?

  In practice, we do not anticipate a large volume of marker strings that would result in significant memory overhead. This is because the D3D12 runtime releases marker data upon command allocator reset. We should revisit this if this becomes a substantial issue.

  One way to mitigate this would be to hand over the responsibility of managing marker data to the application. We could add an extra API for this and call it "fast path" scenario for now. Since PIX events add a level of indirection, we could potentially get rid of it as well and ask applications to use the runtime API directly. The runtime does not copy the string, and instead keeps a map of marker EventID to app provided data pointer. The copy only happens when generating TDR crash dump. Of course, there's the issue of dangling pointer here though.

* Question: Could PIX marker APIs be integrated with auto breadcrumbs for correlation between D3D runtime and driver-level data?

  Auto breadcrumbs are a runtime-side diagnostic feature that's part of DRED. Retail marker APIs could be tracked as part of auto breadcrumbs that could facilitate cross-layer correlation. However, this might be beyond the scope of this feature.

# Test Plan

## Functional tests

* Validate that, with `D3D12_USER_DEFINED_ANNOTATION_MODE_DRIVER_RETAIL`, each `SetMarker` / `BeginEvent` / `EndEvent` call on `ID3D12CommandQueue` and `ID3D12GraphicsCommandList` issues exactly one matching DDI call with the expected `Metadata`, `Size`, and `pData`; and with `D3D12_USER_DEFINED_ANNOTATION_MODE_RUNTIME_ONLY` no DDI call is made.
* Validate `ID3D12Object::SetName` propagation in both annotation modes: only device-child objects trigger `PFND3D12DDI_SET_NAME`.
* Validate that when the driver does not report `D3D12DDI_FEATURE_0121_USER_DEFINED_ANNOTATIONS`, the marker APIs and `ID3D12Object::SetName` succeed on the app side but make no driver DDI calls.
* Validate `SetUserDefinedAnnotationMode` rejects invalid mode and emits `D3D12_MESSAGE_ID_SET_USER_DEFINED_ANNOTATION_MODE_INVALID_ARGUMENT`.

## Conformance tests

Covered by the `D3DConf_12_PixMarkers` HLK test class:

* Validate `CheckFeatureSupport(D3D12_FEATURE_USER_DEFINED_ANNOTATION)` succeeds.
* Validate command-list markers (`SetMarker` / `BeginEvent` / `EndEvent`) under `DRIVER_RETAIL` on Direct, Compute, Copy, and Bundle command lists, around real GPU work; driver must not crash or remove the device.
* Validate command-queue markers under `DRIVER_RETAIL` on Direct, Compute, and Copy queues; driver must not crash or remove the device.
* Validate `ID3D12Object::SetName` under `DRIVER_RETAIL` across the major object kinds with ASCII, Unicode, and very long names.
* Validate switching annotation mode between object creations: markers work on objects created both before and after the switch.

# WARP support

WARP reports support for the PIX marker DDIs and logs the marker calls, but does not retain the marker data. If we expand WARP to produce real crash dumps in the future, we should look into retaining marker data inside WARP so it can be included.

# Spec History

| Version | Date | Details | Author |
|-|-|-|-|
| v0.06 | 17 Jun 2026 | Fix typos, and correct ID3D12DeviceTools2 heading | Henchhing Limbu (PIX) |
| v0.05 | 01 Jun 2026 | Clarify RUNTIME_ONLY marker data behavior, add development vs retail use case example, expand D3DConfig override section, and flesh out Test Plan and WARP support | Henchhing Limbu (PIX) |
| v0.04 | 30 Jan 2026 | Remove caps DDI calls and add multithreading synchronization | Henchhing Limbu (PIX) |
| v0.03 | 20 Jan 2026 | Flesh out DDIs and update them to pass device object name | Henchhing Limbu (PIX) |
| v0.02 | 07 Jan 2026 | Revise runtime configuration behavior | Henchhing Limbu (PIX) |
| v0.01 | 03 Oct 2025 | Initial draft spec | Henchhing Limbu (PIX) | 