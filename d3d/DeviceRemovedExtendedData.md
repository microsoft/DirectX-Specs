# D3D12 Device Removed Extended Data
Version 1.1

## Introduction
Root cause analysis of GPU device removal can be a frustrating experience for both application developers and hardware vendors.  Existing debugging aids like the Debug Layer, GPU-Based Validation and PIX help, but these do not catch all errors that potentially produce GPU faults, and certainly do not help with post-mortem debugging when device removals occur outside the lab on end-user systems.  IHV’s do provide some limited GPU dumps for system-wide TDR’s, but this data is opaque to Microsoft and ISV’s and is not available outside of OCA kernel dumps.
DRED extends the debugging toolset by provided additional data about the state of the GPU at (or near) the time of the GPU error.  The DRED data can be examined in a user-mode debugger or with the use of the DRED interface API’s.  
For post-mortem debugging, device removal will be able to produce a Watson report with a heap dump containing DRED data. 

## Device Removed Extended Data (DRED)
Device Removed Extended Data (DRED) is a D3D feature that provides user-mode debugger with access to data related to a device removed event. 
The following are examples of DRED data:
* Automatic runtime-generated breadcrumb data
    * Breadcrumbs are GPU progress markers that help to identify the location of an error in a command stream, even after the device has been removed.
    * Does not require new hardware or drivers assuming WriteBufferImmediate and existing memory heaps are already supported.
* GPU page fault data, including existing runtime object allocations that match a faulting VA as well as recently freed VA ranges.  

### Goals
* Allow the use of a user-mode debuggers to help with root cause analysis of unexpected GPU device removals.
* Enable process-wide device removed events to produce a Watson report that can be post-mortem analyzed by Microsoft, GPU vendors and independent developers with access to Watson reports.
* Provide developers with access to DRED controls and results in either the debugger or through the use of API’s.
* Minimal performance overhead.

### Non-Goals
* Always on - DRED is not zero-cost.  A non-trivial amount of memory and execution overhead is expected. 

## Versioning
The DRED data is expected to evolve across Windows release cycles.  DRED is designed to be safely versioned such that older apps continue to work while newer apps can take advantage of DRED feature updates.

## Watson
DRED data from in-market customers is provided using Watson.  The Watson reports are used to bucketize device removal cases and provide a heap dump of the system at the time the removal was reported to the D3D runtime.  Since the DRED data lives in the process’ user-mode heap, giving debuggers and debugger extensions an ability to analyze the DRED data.
A Watson report is generated in the following conditions:
•	More data is requested via Watson Portal on a D3DDRED2 event
o	Requires at least one D3DDRED2 extra event to detect the additional data request and set a cookie on the system (via a registry key)
•	A customer uses FeedbackHub to DiagTrack for Game Performance scenarios.  
o	The runtime detects the presence of the Game Perf DiagTrack ETW listener before building the DRED data and creating a Watson report.
•	SetWatsonDumpEnablement is used to force a Watson report
Certain internal builds may have DRED and AutoBreadcrumbs always-enabled.
The event ID used to track DRED for 19H1 builds is D3DDRED2.

## WinDbg debugger extension
DRED data is designed to be easily accessible in a user-mode debugger.  D3D12 exports the D3D12DeviceRemovedExtendedData global variable, making it visible to user-mode debuggers using public symbols.  The layout of this data can be complex and may change over time.  A well curated debugger extension is a necessary tool for post-mortem analysis of DRED output.

WinDbg is the first place to invest in debugger extensions for DRED.  The WinDbg data model is easy to work with and can be leveraged by other extensions, such as D3DDBG.  There are currently no plans to implement Visual Studio debugger extensions for DRED.

## DRED API's
### D3D12_DRED_VERSION
Version used by D3D12_VERSIONED_DEVICE_REMOVED_EXTENDED_DATA.

```c++
enum D3D12_DRED_VERSION
{
    D3D12_DRED_VERSION_1_0	= 0x1,
    D3D12_DRED_VERSION_1_1	= 0x2
};

```
| Constants              |                  |
|------------------------|:-----------------|
| D3D12_DRED_VERSION_1_0 | Dred version 1.0 |
| D3D12_DRED_VERSION_1_1 | Dred version 1.1 |

### D3D12_AUTO_BREADCRUMB_OP
Enum values corresponding to render/compute GPU operations

```c++
enum D3D12_AUTO_BREADCRUMB_OP
{
    D3D12_AUTO_BREADCRUMB_OP_SETMARKER	= 0,
    D3D12_AUTO_BREADCRUMB_OP_BEGINEVENT	= 1,
    D3D12_AUTO_BREADCRUMB_OP_ENDEVENT	= 2,
    D3D12_AUTO_BREADCRUMB_OP_DRAWINSTANCED	= 3,
    D3D12_AUTO_BREADCRUMB_OP_DRAWINDEXEDINSTANCED	= 4,
    D3D12_AUTO_BREADCRUMB_OP_EXECUTEINDIRECT	= 5,
    D3D12_AUTO_BREADCRUMB_OP_DISPATCH	= 6,
    D3D12_AUTO_BREADCRUMB_OP_COPYBUFFERREGION	= 7,
    D3D12_AUTO_BREADCRUMB_OP_COPYTEXTUREREGION	= 8,
    D3D12_AUTO_BREADCRUMB_OP_COPYRESOURCE	= 9,
    D3D12_AUTO_BREADCRUMB_OP_COPYTILES	= 10,
    D3D12_AUTO_BREADCRUMB_OP_RESOLVESUBRESOURCE	= 11,
    D3D12_AUTO_BREADCRUMB_OP_CLEARRENDERTARGETVIEW	= 12,
    D3D12_AUTO_BREADCRUMB_OP_CLEARUNORDEREDACCESSVIEW	= 13,
    D3D12_AUTO_BREADCRUMB_OP_CLEARDEPTHSTENCILVIEW	= 14,
    D3D12_AUTO_BREADCRUMB_OP_RESOURCEBARRIER	= 15,
    D3D12_AUTO_BREADCRUMB_OP_EXECUTEBUNDLE	= 16,
    D3D12_AUTO_BREADCRUMB_OP_PRESENT	= 17,
    D3D12_AUTO_BREADCRUMB_OP_RESOLVEQUERYDATA	= 18,
    D3D12_AUTO_BREADCRUMB_OP_BEGINSUBMISSION	= 19,
    D3D12_AUTO_BREADCRUMB_OP_ENDSUBMISSION	= 20,
    D3D12_AUTO_BREADCRUMB_OP_DECODEFRAME	= 21,
    D3D12_AUTO_BREADCRUMB_OP_PROCESSFRAMES	= 22,
    D3D12_AUTO_BREADCRUMB_OP_ATOMICCOPYBUFFERUINT	= 23,
    D3D12_AUTO_BREADCRUMB_OP_ATOMICCOPYBUFFERUINT64	= 24,
    D3D12_AUTO_BREADCRUMB_OP_RESOLVESUBRESOURCEREGION	= 25,
    D3D12_AUTO_BREADCRUMB_OP_WRITEBUFFERIMMEDIATE	= 26,
    D3D12_AUTO_BREADCRUMB_OP_DECODEFRAME1	= 27,
    D3D12_AUTO_BREADCRUMB_OP_SETPROTECTEDRESOURCESESSION	= 28,
    D3D12_AUTO_BREADCRUMB_OP_DECODEFRAME2	= 29,
    D3D12_AUTO_BREADCRUMB_OP_PROCESSFRAMES1	= 30,
    D3D12_AUTO_BREADCRUMB_OP_BUILDRAYTRACINGACCELERATIONSTRUCTURE	= 31,
    D3D12_AUTO_BREADCRUMB_OP_EMITRAYTRACINGACCELERATIONSTRUCTUREPOSTBUILDINFO	= 32,
    D3D12_AUTO_BREADCRUMB_OP_COPYRAYTRACINGACCELERATIONSTRUCTURE	= 33,
    D3D12_AUTO_BREADCRUMB_OP_DISPATCHRAYS	= 34,
    D3D12_AUTO_BREADCRUMB_OP_INITIALIZEMETACOMMAND	= 35,
    D3D12_AUTO_BREADCRUMB_OP_EXECUTEMETACOMMAND	= 36,
    D3D12_AUTO_BREADCRUMB_OP_ESTIMATEMOTION	= 37,
    D3D12_AUTO_BREADCRUMB_OP_RESOLVEMOTIONVECTORHEAP	= 38,
    D3D12_AUTO_BREADCRUMB_OP_SETPIPELINESTATE1	= 39
};
```

### D3D12_DRED_ALLOCATION_TYPE
Congruent with and numerically equivalent to D3D12DDI_HANDLETYPE enum values.

```c++
enum D3D12_DRED_ALLOCATION_TYPE
{
    D3D12_DRED_ALLOCATION_TYPE_COMMAND_QUEUE	= 19,
    D3D12_DRED_ALLOCATION_TYPE_COMMAND_ALLOCATOR	= 20,
    D3D12_DRED_ALLOCATION_TYPE_PIPELINE_STATE	= 21,
    D3D12_DRED_ALLOCATION_TYPE_COMMAND_LIST	= 22,
    D3D12_DRED_ALLOCATION_TYPE_FENCE	= 23,
    D3D12_DRED_ALLOCATION_TYPE_DESCRIPTOR_HEAP	= 24,
    D3D12_DRED_ALLOCATION_TYPE_HEAP	= 25,
    D3D12_DRED_ALLOCATION_TYPE_QUERY_HEAP	= 27,
    D3D12_DRED_ALLOCATION_TYPE_COMMAND_SIGNATURE	= 28,
    D3D12_DRED_ALLOCATION_TYPE_PIPELINE_LIBRARY	= 29,
    D3D12_DRED_ALLOCATION_TYPE_VIDEO_DECODER	= 30,
    D3D12_DRED_ALLOCATION_TYPE_VIDEO_PROCESSOR	= 32,
    D3D12_DRED_ALLOCATION_TYPE_RESOURCE	= 34,
    D3D12_DRED_ALLOCATION_TYPE_PASS	= 35,
    D3D12_DRED_ALLOCATION_TYPE_CRYPTOSESSION	= 36,
    D3D12_DRED_ALLOCATION_TYPE_CRYPTOSESSIONPOLICY	= 37,
    D3D12_DRED_ALLOCATION_TYPE_PROTECTEDRESOURCESESSION	= 38,
    D3D12_DRED_ALLOCATION_TYPE_VIDEO_DECODER_HEAP	= 39,
    D3D12_DRED_ALLOCATION_TYPE_COMMAND_POOL	= 40,
    D3D12_DRED_ALLOCATION_TYPE_COMMAND_RECORDER	= 41,
    D3D12_DRED_ALLOCATION_TYPE_STATE_OBJECT	= 42,
    D3D12_DRED_ALLOCATION_TYPE_METACOMMAND	= 43,
    D3D12_DRED_ALLOCATION_TYPE_SCHEDULINGGROUP	= 44,
    D3D12_DRED_ALLOCATION_TYPE_VIDEO_MOTION_ESTIMATOR	= 45,
    D3D12_DRED_ALLOCATION_TYPE_VIDEO_MOTION_VECTOR_HEAP	= 46,
    D3D12_DRED_ALLOCATION_TYPE_MAX_VALID	= 47,
    D3D12_DRED_ALLOCATION_TYPE_INVALID	= 0xffffffff
};
```

### D3D12_DRED_ENABLEMENT
Used by ID3D12DeviceRemovedExtendedDataSettings to specify how individual DRED features are enabled.  As of DRED v1.1, the default value for all settings is D3D12_DRED_ENABLEMENT_SYSTEM_CONTROLLED.

```c++
enum D3D12_DRED_ENABLEMENT
{
    D3D12_DRED_ENABLEMENT_SYSTEM_CONTROLLED = 0,
    D3D12_DRED_ENABLEMENT_FORCED_OFF = 1,
    D3D12_DRED_ENABLEMENT_FORCED_ON = 2,
} D3D12_DRED_ENABLEMENT;
```

| Constants                               |                                                                                                                                                 |
|-----------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------|
| D3D12_DRED_ENABLEMENT_SYSTEM_CONTROLLED | The DRED feature is enabled only when DRED is turned on by the system automatically (e.g. when a user is reproducing a problem via FeedbackHub) |
| D3D12_DRED_FLAG_FORCE_ON                | Forces a DRED feature on, regardless of system state.                                                                                           |
| D3D12_DRED_FLAG_DISABLE_AUTOBREADCRUMBS | Disables a DRED feature, regardless of system state.                                                                                            |

### D3D12_AUTO_BREADCRUMB_NODE
D3D12_AUTO_BREADCRUMB_NODE objects are singly linked to each other via the pNext member.  The last node in the list will have a null pNext.

```c++
typedef struct D3D12_AUTO_BREADCRUMB_NODE
{
    const char *pCommandListDebugNameA;
    const wchar_t *pCommandListDebugNameW;
    const char *pCommandQueueDebugNameA;
    const wchar_t *pCommandQueueDebugNameW;
    ID3D12GraphicsCommandList *pCommandList;
    ID3D12CommandQueue *pCommandQueue;
    UINT32 BreadcrumbCount;
    const UINT32 *pLastBreadcrumbValue;
    const D3D12_AUTO_BREADCRUMB_OP *pCommandHistory;
    const struct D3D12_AUTO_BREADCRUMB_NODE *pNext;
} D3D12_AUTO_BREADCRUMB_NODE;
```

| Members                 |                                                                          |
|-------------------------|--------------------------------------------------------------------------|
| pCommandListDebugNameA  | Pointer to the ANSI debug name of the command list (if any)              |
| pCommandListDebugNameW  | Pointer to the wide debug name of the command list (if any)              |
| pCommandQueueDebugNameA | Pointer to the ANSI debug name of the command queue (if any)             |
| pCommandQueueDebugNameW | Pointer to the wide debug name of the command queue (if any)             |
| pCommandList            | Address of the command list at the time of execution                     |
| pCommandQueue           | Address of the command queue                                             |
| BreadcrumbCount         | Number of render operations used in the command list recording           |
| pLastBreadcrumbValue    | Pointer to the number of GPU-completed render operations                 |
| pNext                   | Pointer to the next node in the list or nullptr if this is the last node |

### D3D12_DRED_ALLOCATION_NODE
Describes allocation data for a DRED-tracked allocation.  If device removal is caused by a GPU page fault, DRED reports all matching allocation nodes for active and recently-freed runtime objects.

D3D12_DRED_ALLOCATION_NODE objects are singly linked to each other via the pNext member.  The last node in the list will have a null pNext.

```c++
struct D3D12_DRED_ALLOCATION_NODE
{
    const char *ObjectNameA;
    const wchar_t *ObjectNameW;
    D3D12_DRED_ALLOCATION_TYPE AllocationType;
    const struct D3D12_DRED_ALLOCATION_NODE *pNext;
};
```

### D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT
Contains pointer to the head of a linked list of D3D12_AUTO_BREADCRUMB_NODE structures.
```c++
struct D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT
{
    const D3D12_AUTO_BREADCRUMB_NODE *pHeadAutoBreadcrumbNode;
};
```
| Members                 |                                                                            |
|-------------------------|----------------------------------------------------------------------------|
| pHeadAutoBreadcrumbNode | Pointer to the head of a linked list of D3D12_AUTO_BREADCRUMB_NODE objects |

### D3D12_DRED_PAGE_FAULT_OUTPUT
Provides the VA of a GPU page fault and contains a list of matching allocation nodes for active objects and a list of allocation nodes for recently deleted objects.
```c++
struct D3D12_DRED_PAGE_FAULT_OUTPUT
{
    D3D12_GPU_VIRTUAL_ADDRESS PageFaultVA;
    const D3D12_DRED_ALLOCATION_NODE *pHeadExistingAllocationNode;
    const D3D12_DRED_ALLOCATION_NODE *pHeadRecentFreedAllocationNode;
};
```
| Members                        |                                                                                                              |
|--------------------------------|--------------------------------------------------------------------------------------------------------------|
| PageFaultVA                    | GPU Virtual Address of GPU page fault                                                                        |
| pHeadExistingAllocationNode    | Pointer to head allocation node for existing runtime objects with VA ranges that match the faulting VA       |
| pHeadRecentFreedAllocationNode | Pointer to head allocation node for recently freed runtime objects with VA ranges that match the faulting VA |

### D3D12_DEVICE_REMOVED_EXTENDED_DATA1
DRED V1.1 data structure.
```c++
struct D3D12_DEVICE_REMOVED_EXTENDED_DATA1
{
    HRESULT DeviceRemovedReason;
    D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT AutoBreadcrumbsOutput;
    D3D12_DRED_PAGE_FAULT_OUTPUT PageFaultOutput;
};
```
| Members               |                                                                               |
|-----------------------|-------------------------------------------------------------------------------|
| DeviceRemovedReason   | The device removed reason matching the return value of GetDeviceRemovedReason |
| AutoBreadcrumbsOutput | Contained D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT member                           |
| PageFaultOutput       | Contained D3D12_DRED_PAGE_FAULT_OUTPUT member                                 |

### D3D12_VERSIONED_DEVICE_REMOVED_EXTENDED_DATA
Encapsulates the versioned DRED data.  The appropriate unioned Dred_* member must match the value of Version.
```c++
struct D3D12_VERSIONED_DEVICE_REMOVED_EXTENDED_DATA
{
    D3D12_DRED_VERSION Version;
    union
    {
        D3D12_DEVICE_REMOVED_EXTENDED_DATA Dred_1_0;
        D3D12_DEVICE_REMOVED_EXTENDED_DATA1 Dred_1_1;
    };
};
```
| Members  |                                                      |
|----------|------------------------------------------------------|
| Dred_1_0 | DRED data as of Windows 10 version 1809              |
| Dred_1_1 | DRED data as of Windows 10 19H1                      |

### ID3D12DeviceRemovedExtendedDataSettings
Interface controlling DRED settings.  All DRED settings must be configured prior to D3D12 device creation.  Use D3D12GetDebugInterface to get the ID3D12DeviceRemovedExtendedDataSettings interface object.

| Methods                      |                                                                   |
|------------------------------|-------------------------------------------------------------------|
| SetAutoBreadcrumbsEnablement | Configures the enablement settings for DRED auto-breadcrumbs.     |
| SetPageFaultEnablement       | Configures the enablement settings for DRED page fault reporting. |
| SetWatsonDumpEnablement      | Configures the enablement settings for DRED watson dumps.         |

### ID3D12DeviceRemovedExtendedDataSettings::SetAutoBreadcrumbsEnablement
Configures the enablement settings for DRED auto-breadcrumbs.
```c++
void ID3D12DeviceRemovedExtendedDataSettings::SetAutoBreadcrumbsEnablement(D3D12_DRED_ENABLEMENT Enablement);
```
| Parameters |                                                                        |
|------------|------------------------------------------------------------------------|
| Enablement | Enablement value (defaults to D3D12_DRED_ENABLEMENT_SYSTEM_CONTROLLED) |

### ID3D12DeviceRemovedExtendedDataSettings::SetPageFaultEnablement
Configures the enablement settings for DRED page fault reporting.
```c++
void ID3D12DeviceRemovedExtendedDataSettings::SetPageFaultEnablement(D3D12_DRED_ENABLEMENT Enablement);
```
| Parameters |                                                                        |
|------------|------------------------------------------------------------------------|
| Enablement | Enablement value (defaults to D3D12_DRED_ENABLEMENT_SYSTEM_CONTROLLED) |

### ID3D12DeviceRemovedExtendedDataSettings::SetWatsonDumpEnablement
Configures the enablement settings for DRED Watson dumps.
```c++
void ID3D12DeviceRemovedExtendedDataSettings::SetWatsonDumpEnablement(D3D12_DRED_ENABLEMENT Enablement);
```
| Parameters |                                                                        |
|------------|------------------------------------------------------------------------|
| Enablement | Enablement value (defaults to D3D12_DRED_ENABLEMENT_SYSTEM_CONTROLLED) |


### ID3D12DeviceRemovedExtendedData
Provides access to DRED data.  Methods return DXGI_ERROR_NOT_CURRENTLY_AVAILABLE if the device is not in a removed state.

Use ID3D12Device::QueryInterface to get the ID3D12DeviceRemovedExtendedData interface.

| Methods                      |                                        |
|------------------------------|----------------------------------------|
| GetAutoBreadcrumbsOutput     | Gets the DRED auto-breadcrumbs output. |
| GetPageFaultAllocationOutput | Gets the DRED page fault data.         |


### ID3D12DeviceRemovedExtendedData::GetAutoBreadcrumbsOutput
Gets the DRED auto-breadcrumbs output.
```c++
HRESULT ID3D12DeviceRemovedExtendedData::GetAutoBreadcrumbsOutput(D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT *pOutput);
```
| Parameters |                                                                        |
|------------|------------------------------------------------------------------------|
| pOutput    | Pointer to a destination D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT structure. |

### ID3D12DeviceRemovedExtendedData::GetPageFaultAllocationOutput
Gets the DRED page fault data, including matching allocation for both living, and recently-deleted runtime objects.

```c++
HRESULT ID3D12DeviceRemovedExtendedData::GetPageFaultAllocationOutput(D3D12_DRED_PAGE_FAULT_OUTPUT *pOutput);
```
| Parameters |                                                                  |
|------------|------------------------------------------------------------------|
| pOutput    | Pointer to a destination D3D12_DRED_PAGE_FAULT_OUTPUT structure. |

