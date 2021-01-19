# D3D12 Device Removed Extended Data (DRED)

## Introduction
DRED stands for Device Removed Extended Data.  Debugging unexpected Device Removals (aka TDR's) remains a top pain point for graphics developers using D3D12 API's.  Existing debugging aids like the Debug Layer, GPU-Based Validation and PIX help, but these do not catch all errors that potentially produce GPU faults, and certainly do little to help with post-mortem debugging when device removals occur outside the lab on end-user systems.  

DRED extends the debugging toolset by provided additional data about the state of GPU workload execution at (or near) the time of the GPU error.  DRED data includes automatic breadcrumbs (with optional PIX event/marker context) and GPU Page Fault analysis. DRED data can be examined in a user-mode debugger or with the use of the DRED interface API’s.  

For post-mortem debugging, device removal will be able to produce a Watson report with a heap dump containing DRED data. 

### Design Goals
* Allow the use of a user-mode debuggers to help with root cause analysis of unexpected GPU device removals.
* Provide developers with access to DRED controls and results in either the debugger or through the use of API’s.
* Minimal performance overhead.
* Support both PIX event and marker strings.
* Can enable or disable individual aspects of DRED programmatically.
* DRED remains backward compatible with older interfaces and debugging tools.
* Developers rejoice when elusive TDR's are finally root caused and fixed.

### Non-Goals
* Always on - DRED is not zero-cost.  A non-trivial amount of memory and execution overhead is expected.  
* Seamless debug layer support
    * Debug layer injected command ops normally hidden from ISV developers will leave breadcrumbs.
* DX Control Panel integration
    * The DirectX Control Panel is not CoreOS compatible.  A likely command line replacement is being considered.

### Open Issues
It may make sense to add a new ID3D12GraphicsCommandList[n]::AutoBreadcrumbMarker command.  While PIXBeginEvent and PIXSetMarker already do the job, they also have additional overhead related to the PIX functionality.

## Auto-Breadcrumbs
In Windows 10 version 1803 (April 2018 Update / Redstone 4) Microsoft introduced the ID3D12GraphicsCommandList2::WriteBufferImmediate API and encouraged developers to use this to place "breadcrumbs" in the GPU command stream to track GPU progress before a TDR.  This is still a good approach if a developer wishes to create a custom, low-overhead breadcrumb implementation, but may lack some of the versatility of a standardized solution, such as debugger extensions, PIX event/marker support, or Watson reporting.  

DRED Auto-Breadcrumbs also uses WriteBufferImmediate to place progress counters in the GPU command stream.  DRED inserts a breadcrumb after each "render op" - meaning, after every operation that results in GPU work (e.g. Draw, Dispatch, Copy, Resolve, etc...).  If the device is removed in the middle of a GPU workload, the DRED breadcrumb value is essentially a count of render ops completed **before** the error.  

Up to 64KiB operations in a given command list are retained in the breadcrumb history ring buffer.  If there are more than 65536 operations in a command list then only the last 64KiB operations are stored, overwriting the oldest operations first.  However, the breadcrumb counter value continues to count up to UINT_MAX.  Therefore, LastOpIndex = (BreadcrumbCount - 1) % 65536.  

**Performance**  
Although Auto-Breadcrumbs are designed to be low-overhead, they are far from free.  Empirical measurements show between 2-5% performance loss on typical "AAA" D3D12 graphics game engines.  For this reason, Auto-Breadcrumbs are off-by-default.

**Hardware Requirements**  
Because the breadcrumb counter values must be preserved after device removal, the resource containing breadcrumbs must exist in system memory and must persist in the event of device removal.  This means the driver must support D3D12_FEATURE_EXISTING_HEAPS.  Fortunately, this is true for most 19H1 D3D12 drivers.

**Caveats**  
* Because GPU's are heavily pipelined, there is no guarantee that the breadcrumb counter will indicate the exact operation that failed.  In fact on some tile-based deferred render devices, it is possible for the breadcrumb counter to be a full resource or uav barrier behind the actual GPU progress.
* Drivers can reorder commands, pre-fetch from resource memory well before executing a command, or flush cached memory well-after completion of a command.  Any of these can produce GPU errors.  In such cases the autobreadcrumb counters may be less helpful or misleading.

## GPU Page Fault Data (DRED version 1.1 and later)
DRED v1.1, released in Window 10 19H1, provides GPU Page Fault Reporting.  GPU page faults commonly occur when:
* An application mistakenly executes work on the GPU that references a deleted object.
* An application mistakenly executes work on the GPU that accesses an evicted resource or non-resident tile.
* A shader references an uninitialized or stale descriptor.
* A shader indexes beyond the end of a root binding.

DRED attempts to address some of these scenarios by reporting the names and types of existing or recently freed API objects that match the VA of the GPU-reported page fault.

Premature release of objects in-flight is one of the top causes for unexpected device removals.  DRED keeps track of the 65,000 most recently freed objects.  DRED reports when any of these objects correlate to the faulting VA.  

**Performance**  
The D3D12 runtime must actively curate a collection of existing and recently-deleted API objects indexable by VA.  This increases the system memory overhead and introduces a small performance hit to object creation and destruction.  For now this is still off-by-default.

**Hardware Requirements**  
Many, but not all, GPU's currently support GPU page faults.  Hardware that doesn't support page faulting can still benefit from Auto-Breadcrumbs.

**Caveat**  
Not all GPU's support page faults.  Some GPU's respond to memory faults by bit-bucket writes, reading simulated data (e.g. zeros), or simply hanging. Unfortunately, in cases where the GPU doesn't immediately hang, TDR's can happen later in it pipe, making it even harder to locate the root cause.

## Breadcrumb Context Strings (DRED version 1.2 and later)
During command list recording, operations that support breadcrumb context data append both the command index and context string to the end of an array.  The array is naturally sorted, making it trivial to use a binary search utility such as std::equal_range.  Keeping the breadcrumb context strings separate from the auto-breadcrumb table reduces memory overhead over storing a string pointer for every breadcrumb.

The following is an example of DRED auto-breadcrumb data with context strings:

**Breadcrumbs**
| Index | Op                                          |
|-------|---------------------------------------------|
| 00    | D3D12_AUTO_BREADCRUMB_OP_SETMARKER          |
| 01    | D3D12_AUTO_BREADCRUMB_OP_COPYRESOURCE       |
| 02    | D3D12_AUTO_BREADCRUMB_OP_COPYRESOURCE       |
| 03    | D3D12_AUTO_BREADCRUMB_OP_RESOURCEBARRIER    |
| 04    | D3D12_AUTO_BREADCRUMB_OP_SETMARKER          |
| 05    | D3D12_AUTO_BREADCRUMB_OP_DRAWINSTANCED      |
| 06    | D3D12_AUTO_BREADCRUMB_OP_RESOURCEBARRIER    |
| 07    | D3D12_AUTO_BREADCRUMB_OP_SETMARKER          |
| 08    | D3D12_AUTO_BREADCRUMB_OP_RESOLVESUBRESOURCE |
| 09    | D3D12_AUTO_BREADCRUMB_OP_RESOURCEBARRIER    |
| 10    | D3D12_AUTO_BREADCRUMB_OP_SETMARKER          |
| 11    | D3D12_AUTO_BREADCRUMB_OP_COPYRESOURCE       |

**Breadcrumb Contexts**
| Op Index | Context String                           |
|----------|------------------------------------------|
| 00       | "Copying TexA and TexB to TexC and TexD" |
| 04       | "Drawing object X"                       |
| 07       | "Resolving diffuse texture"              |
| 10       | "Copying diffuse texture"                |

## Setting up DRED in Code
DRED settings must be configure prior to creating a D3D12 Device.  Use D3D12GetDebugInterface to get an interface to the ID3D12DeviceRemovedExtendedDataSettings object.

Example:
```c++
CComPtr<ID3D12DeviceRemovedExtendedDataSettings1> pDredSettings;
VERIFY_SUCCEEDED(D3D12GetDebugInterface(IID_PPV_ARGS(&pDredSettings)));

// Turn on AutoBreadcrumbs and Page Fault reporting
pDredSettings->SetAutoBreadcrumbsEnablement(D3D12_DRED_ENABLEMENT_FORCED_ON);
pDredSettings->SetPageFaultEnablement(D3D12_DRED_ENABLEMENT_FORCED_ON);
```
## Accessing DRED Data in Code
After device removal has been detected (e.g. Present returns DXGI_ERROR_DEVICE_REMOVED), use ID3D12DeviceRemovedExtendedData methods to access the DRED data for the removed device.

The ID3D12DeviceRemovedExtendedData interface can be QI'd from an ID3D12Device object.

Example:
```c++
void MyDeviceRemovedHandler(ID3D12Device *pDevice)
{
    CComPtr<ID3D12DeviceRemovedExtendedData1> pDred;
    VERIFY_SUCCEEDED(pDevice->QueryInterface(IID_PPV_ARGS(&pDred)));

    D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT1 DredAutoBreadcrumbsOutput;
    D3D12_DRED_PAGE_FAULT_OUTPUT DredPageFaultOutput;
    VERIFY_SUCCEEDED(pDred->GetAutoBreadcrumbsOutput1(&DredAutoBreadcrumbsOutput));
    VERIFY_SUCCEEDED(pDred->GetPageFaultAllocationOutput(&DredPageFaultOutput));

    // Custom processing of DRED data can be done here.
    // Produce telemetry...
    // Log information to console...
    // break into a debugger...
}
```

## DRED Telemetry
Applications can use the DRED API's to control DRED features and collect telemetry for post-mortem analysis.  This gives app developers a much broader net for catching those hard-to-repro TDR's.

As of 19H1, all user-mode device-removed events are reported to Watson.  If a particular app + GPU + driver combination generates enough device-removed events, Microsoft may temporarily enable DRED for customers launching the same app on a similar configuration.

## Versioning
DRED is expected to evolve over time.  DRED is designed to be safely versioned such that older apps continue to work while newer apps can take advantage of DRED feature updates.

## Watson
DRED data from in-market customers is provided using Watson.  The Watson reports are used to bucketize device removal cases and provide a heap dump of the system at the time the removal was reported to the D3D runtime.  Since the DRED data lives in the process’ user-mode heap, giving debuggers and debugger extensions an ability to analyze the DRED data.
A Watson report is generated in the following conditions:
* More data is requested via Watson Portal on a D3DDRED2 event
    * Requires at least one D3DDRED2 extra event to detect the additional data request and set a cookie on the system (via a registry key)
* A customer uses FeedbackHub to DiagTrack for Game Performance scenarios.  
    * The runtime detects the presence of the Game Perf DiagTrack ETW listener before building the DRED data and creating a Watson report.
* SetWatsonDumpEnablement is used to force a Watson report
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
    D3D12_DRED_VERSION_1_1	= 0x2,
    D3D12_DRED_VERSION_1_2	= 0x3
};

```
| Constants              | Meaning          |
|------------------------|:-----------------|
| D3D12_DRED_VERSION_1_0 | Dred version 1.0 |
| D3D12_DRED_VERSION_1_1 | Dred version 1.1 |
| D3D12_DRED_VERSION_1_2 | Dred version 1.2 |

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

| Constants                               | Description                                                                                                                                     |
|-----------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------|
| D3D12_DRED_ENABLEMENT_SYSTEM_CONTROLLED | The DRED feature is enabled only when DRED is turned on by the system automatically (e.g. when a user is reproducing a problem via FeedbackHub) |
| D3D12_DRED_FLAG_FORCE_ON                | Forces a DRED feature on, regardless of system state.                                                                                           |
| D3D12_DRED_FLAG_DISABLE_AUTOBREADCRUMBS | Disables a DRED feature, regardless of system state.                                                                                            |

### D3D12_DRED_AUTO_BREADCRUMB_FLAGS
Used by ID3D12DeviceRemovedExtendedDataSettings2::SetAutoBreadcrumbFlags to modify default auto-breadcrumb behavior.

```c++
enum D3D12_DRED_AUTO_BREADCRUMB_FLAGS
{
    D3D12_DRED_AUTO_BREADCRUMB_FLAG_NONE = 0x0000,
    D3D12_DRED_AUTO_BREADCRUMB_FLAG_NO_MARKERS = 0x0001,
    D3D12_DRED_AUTO_BREADCRUMB_FLAG_NO_SHADER_OPS = 0x0002,
    D3D12_DRED_AUTO_BREADCRUMB_FLAG_NO_FIXED_OPS = 0x0004,
} D3D12_DRED_AUTO_BREADCRUMB_FLAGS;
```

| Constants                                     | Description                                                                                                                       |
|-----------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------|
| D3D12_DRED_AUTO_BREADCRUMB_FLAG_NONE          | Default auto-breadcrumb behavior                                                                                                  |
| D3D12_DRED_AUTO_BREADCRUMB_FLAG_NO_MARKERS    | Set to suppress DRED auto-breadcrumb output for Marker and BeginEvent/EndEvent operations.                                        |
| D3D12_DRED_AUTO_BREADCRUMB_FLAG_NO_SHADER_OPS | Set to suppress DRED auto-breadcrumb output for shader executing operations, including Draw*, Dispatch*, ExecuteIndirect, etc.    |
| D3D12_DRED_AUTO_BREADCRUMB_FLAG_NO_FIXED_OPS  | Set to suppress DRED auto-breadcrumb output for fixed-function GPU operations, including Copy*, Resolve*, Clear*, etc.            |

### D3D12_AUTO_BREADCRUMB_NODE (DRED version 1.1)
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

| Members                 | Description                                                              |
|-------------------------|--------------------------------------------------------------------------|
| pCommandListDebugNameA  | Pointer to the ANSI debug name of the command list (if any)              |
| pCommandListDebugNameW  | Pointer to the wide debug name of the command list (if any)              |
| pCommandQueueDebugNameA | Pointer to the ANSI debug name of the command queue (if any)             |
| pCommandQueueDebugNameW | Pointer to the wide debug name of the command queue (if any)             |
| pCommandList            | Address of the command list at the time of execution                     |
| pCommandQueue           | Address of the command queue                                             |
| BreadcrumbCount         | Number of render operations used in the command list recording           |
| pLastBreadcrumbValue    | Pointer to the number of GPU-completed render operations                 |
| pCommandHistory         | Pointer to the array of breadcrumbs used by the command list             |
| pNext                   | Pointer to the next node in the list or nullptr if this is the last node |

### D3D12_DRED_BREADCRUMB_CONTEXT (DRED version 1.2)
Context string data associated with a DRED auto-breadcrumb.

```c++
typedef struct D3D12_DRED_BREADCRUMB_CONTEXT
{
    UINT BreadcrumbIndex;
    const wchar_t *pContextString;
} D3D12_DRED_BREADCRUMB_CONTEXT;
```

| Members         | Description                                                           |
|-----------------|-----------------------------------------------------------------------|
| BreadcrumbIndex | Index of the associated auto-breadcrumb operation in the command list |
| pContextString  | Points to the breadcrumb context string                               |

### D3D12_AUTO_BREADCRUMB_NODE1 (DRED version 1.2)  
An extended version of struct D3D12_AUTO_BREADCRUMB_NODE that includes breadcrumb context data.

```c++
typedef struct D3D12_AUTO_BREADCRUMB_NODE1
{
    const char *pCommandListDebugNameA;
    const wchar_t *pCommandListDebugNameW;
    const char *pCommandQueueDebugNameA;
    const wchar_t *pCommandQueueDebugNameW;
    ID3D12GraphicsCommandList *pCommandList;
    ID3D12CommandQueue *pCommandQueue;
    UINT BreadcrumbCount;
    const UINT *pLastBreadcrumbValue;
    const D3D12_AUTO_BREADCRUMB_OP *pCommandHistory;
    const struct D3D12_AUTO_BREADCRUMB_NODE1 *pNext;
    UINT BreadcrumbContextsCount;
    D3D12_DRED_BREADCRUMB_CONTEXT *pBreadcrumbContexts;
} D3D12_AUTO_BREADCRUMB_NODE1;
```

| Members                 | Description                                                                 |
|-------------------------|-----------------------------------------------------------------------------|
| pCommandListDebugNameA  | Pointer to the ANSI debug name of the command list (if any)                 |
| pCommandListDebugNameW  | Pointer to the wide debug name of the command list (if any)                 |
| pCommandQueueDebugNameA | Pointer to the ANSI debug name of the command queue (if any)                |
| pCommandQueueDebugNameW | Pointer to the wide debug name of the command queue (if any)                |
| pCommandList            | Address of the command list at the time of execution                        |
| pCommandQueue           | Address of the command queue                                                |
| BreadcrumbCount         | Number of render operations used in the command list recording              |
| pLastBreadcrumbValue    | Pointer to the number of GPU-completed render operations                    |
| pCommandHistory         | Pointer to the array of breadcrumbs used by the command list                |
| pNext                   | Pointer to the next node in the list or nullptr if this is the last node    |
| BreadcrumbContextsCount | Number of breadcrumb context elements used by the command list at execution |
| pBreadcrumbContexts     | Pointer to the array of breadcrumb context elements                         |

### D3D12_DRED_ALLOCATION_NODE (DRED version 1.1)  
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

| Members        | Description                                                                          |
|----------------|--------------------------------------------------------------------------------------|
| ObjectNameA    | ANSI name of the API object or nullptr of no ANSI name exists.                       |
| ObjectNameW    | UTF-16 name of the API object or nullptr of no UTF-16 name exists.                   |
| AllocationType | Type of allocation                                                                   |
| pNext          | Pointer to next allocation node in linked list, or nullptr if this is the last node. |

### D3D12_DRED_ALLOCATION_NODE1 (DRED version 1.2)  
Describes allocation data for a DRED-tracked allocation.  If device removal is caused by a GPU page fault, DRED reports all matching allocation nodes for active and recently-freed runtime objects.

D3D12_DRED_ALLOCATION_NODE1 objects are singly linked to each other via the pNext member.  The last node in the list will have a null pNext.

```c++
struct D3D12_DRED_ALLOCATION_NODE1
{
    const char *ObjectNameA;
    const wchar_t *ObjectNameW;
    D3D12_DRED_ALLOCATION_TYPE AllocationType;
    const struct D3D12_DRED_ALLOCATION_NODE1 *pNext;
    const IUnknown *pObject;
};
```

| Members        | Description                                                                          |
|----------------|--------------------------------------------------------------------------------------|
| ObjectNameA    | ANSI name of the API object or nullptr of no ANSI name exists.                       |
| ObjectNameW    | UTF-16 name of the API object or nullptr of no UTF-16 name exists.                   |
| AllocationType | Type of allocation                                                                   |
| pNext          | Pointer to next allocation node in linked list, or nullptr if this is the last node. |
| pObject        | Address of the IUnknown object associated with the allocation.                       |


### D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT (DRED version 1.1)  
Contains pointer to the head of a linked list of D3D12_AUTO_BREADCRUMB_NODE structures.

```c++
struct D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT
{
    const D3D12_AUTO_BREADCRUMB_NODE *pHeadAutoBreadcrumbNode;
};
```

| Members                 | Description                                                                |
|-------------------------|----------------------------------------------------------------------------|
| pHeadAutoBreadcrumbNode | Pointer to the head of a linked list of D3D12_AUTO_BREADCRUMB_NODE objects |

### D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT1 (DRED version 1.2)  
Contains pointer to the head of a linked list of D3D12_AUTO_BREADCRUMB_NODE1 structures.  The last member node in the list has a null pNext member.  The value of pHeadAutoBreadcrumbNode will be null if there are no auto-breadcrumbs.

```c++
typedef struct D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT1
{
    const D3D12_AUTO_BREADCRUMB_NODE1 *pHeadAutoBreadcrumbNode;
} D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT1;
```

| Members                 | Description                                                                         |
|-------------------------|-------------------------------------------------------------------------------------|
| pHeadAutoBreadcrumbNode | Pointer to the head of a linked list of D3D12_AUTO_BREADCRUMB_NODE1 objects or NULL |

### D3D12_DRED_PAGE_FAULT_OUTPUT (DRED version 1.1)  
Provides the VA of a GPU page fault and contains a list of matching allocation nodes for active objects and a list of allocation nodes for recently deleted objects.

```c++
struct D3D12_DRED_PAGE_FAULT_OUTPUT
{
    D3D12_GPU_VIRTUAL_ADDRESS PageFaultVA;
    const D3D12_DRED_ALLOCATION_NODE *pHeadExistingAllocationNode;
    const D3D12_DRED_ALLOCATION_NODE *pHeadRecentFreedAllocationNode;
};
```

| Members                        | Description                                                                                                   |
|--------------------------------|--------------------------------------------------------------------------------------------------------------|
| PageFaultVA                    | GPU Virtual Address of GPU page fault                                                                        |
| pHeadExistingAllocationNode    | Pointer to head allocation node for existing runtime objects with VA ranges that match the faulting VA       |
| pHeadRecentFreedAllocationNode | Pointer to head allocation node for recently freed runtime objects with VA ranges that match the faulting VA |

### D3D12_DRED_PAGE_FAULT_OUTPUT1 (DRED version 1.2)  
Provides the VA of a GPU page fault and contains a list of matching allocation nodes for active objects and a list of allocation nodes for recently deleted objects.

```c++
struct D3D12_DRED_PAGE_FAULT_OUTPUT1
{
    D3D12_GPU_VIRTUAL_ADDRESS PageFaultVA;
    const D3D12_DRED_ALLOCATION_NODE1 *pHeadExistingAllocationNode;
    const D3D12_DRED_ALLOCATION_NODE1 *pHeadRecentFreedAllocationNode;
};
```

| Members                        | Description                                                                                                   |
|--------------------------------|--------------------------------------------------------------------------------------------------------------|
| PageFaultVA                    | GPU Virtual Address of GPU page fault                                                                        |
| pHeadExistingAllocationNode    | Pointer to head allocation node for existing runtime objects with VA ranges that match the faulting VA       |
| pHeadRecentFreedAllocationNode | Pointer to head allocation node for recently freed runtime objects with VA ranges that match the faulting VA |

### D3D12_DEVICE_REMOVED_EXTENDED_DATA1 (DRED version 1.1)  
DRED V1.1 data structure.

```c++
struct D3D12_DEVICE_REMOVED_EXTENDED_DATA1
{
    HRESULT DeviceRemovedReason;
    D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT AutoBreadcrumbsOutput;
    D3D12_DRED_PAGE_FAULT_OUTPUT PageFaultOutput;
};
```

| Members               | Description                                                                   |
|-----------------------|-------------------------------------------------------------------------------|
| DeviceRemovedReason   | The device removed reason matching the return value of GetDeviceRemovedReason |
| AutoBreadcrumbsOutput | Contained D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT member                           |
| PageFaultOutput       | Contained D3D12_DRED_PAGE_FAULT_OUTPUT member                                 |

### D3D12_DEVICE_REMOVED_EXTENDED_DATA2 (DRED version 1.2)  
DRED V1.2 data structure.

```c++
typedef struct D3D12_DEVICE_REMOVED_EXTENDED_DATA2
{
    HRESULT DeviceRemovedReason;
    D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT1 AutoBreadcrumbsOutput;
    D3D12_DRED_PAGE_FAULT_OUTPUT1 PageFaultOutput;
} D3D12_DEVICE_REMOVED_EXTENDED_DATA2;
```

| Members               | Description                                                                   |
|-----------------------|-------------------------------------------------------------------------------|
| DeviceRemovedReason   | The device removed reason matching the return value of GetDeviceRemovedReason |
| AutoBreadcrumbsOutput | D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT1 data                                       |
| PageFaultOutput       | D3D12_DRED_PAGE_FAULT_OUTPUT1 data                                             |

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
        D3D12_DEVICE_REMOVED_EXTENDED_DATA2 Dred_1_2;
    };
};
```

| Members  | Description                                                                                |
|----------|--------------------------------------------------------------------------------------------|
| Dred_1_0 | DRED data as of Windows 10 version 1809.  Valid only if Version is D3D12_DRED_VERSION_1_0. |
| Dred_1_1 | DRED data as of Windows 10 19H1.  Valid only if Version is D3D12_DRED_VERSION_1_1.         |
| Dred_1_2 | DRED data as of Windows 10 Vibranium.  Valid only if Version is D3D12_DRED_VERSION_1_2.    |

### ID3D12DeviceRemovedExtendedDataSettings::SetAutoBreadcrumbsEnablement (DRED version 1.1)  
Configures the enablement settings for DRED auto-breadcrumbs.

```c++
void ID3D12DeviceRemovedExtendedDataSettings::SetAutoBreadcrumbsEnablement(D3D12_DRED_ENABLEMENT Enablement);
```

| Parameters | Description                                                            |
|------------|------------------------------------------------------------------------|
| Enablement | Enablement value (defaults to D3D12_DRED_ENABLEMENT_SYSTEM_CONTROLLED) |

### ID3D12DeviceRemovedExtendedDataSettings::SetPageFaultEnablement (DRED version 1.1)  
Configures the enablement settings for DRED page fault reporting.

```c++
void ID3D12DeviceRemovedExtendedDataSettings::SetPageFaultEnablement(D3D12_DRED_ENABLEMENT Enablement);
```

| Parameters | Description                                                            |
|------------|------------------------------------------------------------------------|
| Enablement | Enablement value (defaults to D3D12_DRED_ENABLEMENT_SYSTEM_CONTROLLED) |

### ID3D12DeviceRemovedExtendedDataSettings::SetWatsonDumpEnablement (DRED version 1.1)  
Configures the enablement settings for DRED Watson dumps.

```c++
void ID3D12DeviceRemovedExtendedDataSettings::SetWatsonDumpEnablement(D3D12_DRED_ENABLEMENT Enablement);
```

| Parameters | Description                                                            |
|------------|------------------------------------------------------------------------|
| Enablement | Enablement value (defaults to D3D12_DRED_ENABLEMENT_SYSTEM_CONTROLLED) |

### ID3D12DeviceRemovedExtendedDataSettings1::SetBreadcrumbsContextEnablement (DRED version 1.2)  
Configures the enablement settings for DRED auto-breadcrumbs context data.

```c++
void ID3D12DeviceRemovedExtendedDataSettings1::SetBreadcrumbContextEnablement(D3D12_DRED_ENABLEMENT Enablement);
```

| Parameters | Description                                                            |
|------------|------------------------------------------------------------------------|
| Enablement | Enablement value (defaults to D3D12_DRED_ENABLEMENT_SYSTEM_CONTROLLED) |

### ID3D12DeviceRemovedExtendedDataSettings2::SetAutoBreadcrumbFlags
Sets DRED auto-breadcrumb flags used to customize auto-breadcrumb behavior, such as limiting breadcrumb output.

```c++
void ID3D12DeviceRemovedExtendedDataSettings2::SetAutoBreadcrumbFlags(D3D12_DRED_AUTO_BREADCRUMB_FLAGS Flags);
```

| Parameters | Description                                                                 |
|------------|-----------------------------------------------------------------------------|
| Flags      | Logical combination of one or more D3D12_DRED_AUTO_BREADCRUMB_FLAGS bits    |

### ID3D12DeviceRemovedExtendedData::GetAutoBreadcrumbsOutput (DRED version 1.1)  
Gets the DRED auto-breadcrumbs output.

```c++
HRESULT ID3D12DeviceRemovedExtendedData::GetAutoBreadcrumbsOutput(D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT *pOutput);
```

| Parameters | Description                                                            |
|------------|------------------------------------------------------------------------|
| pOutput    | Pointer to a destination D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT structure. |

### ID3D12DeviceRemovedExtendedData::GetPageFaultAllocationOutput (DRED version 1.1)  
Gets the DRED page fault data, including matching allocation for both living, and recently-deleted runtime objects.

```c++
HRESULT ID3D12DeviceRemovedExtendedData::GetPageFaultAllocationOutput(D3D12_DRED_PAGE_FAULT_OUTPUT *pOutput);
```

| Parameters | Description                                                      |
|------------|------------------------------------------------------------------|
| pOutput    | Pointer to a destination D3D12_DRED_PAGE_FAULT_OUTPUT structure. |

## ID3D12DeviceRemovedExtendedData1::GetAutoBreadcrumbsOutput1 (DRED version 1.2)  
Gets the DRED v1.2 auto-breadcrumbs output.

```c++
HRESULT ID3D12DeviceRemovedExtendedData1::GetAutoBreadcrumbsOutput1(D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT1 *pOutput);
```

| Parameters | Description                                                             |
|------------|-------------------------------------------------------------------------|
| pOutput    | Pointer to a destination D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT1 structure. |

### ID3D12DeviceRemovedExtendedData1::GetPageFaultAllocationOutput (DRED version 1.1)  
Gets the DRED page fault data, including matching allocation for both living, and recently-deleted runtime objects.

```c++
HRESULT ID3D12DeviceRemovedExtendedData1::GetPageFaultAllocationOutput1(D3D12_DRED_PAGE_FAULT_OUTPUT1 *pOutput);
```

| Parameters | Description                                                      |
|------------|------------------------------------------------------------------|
| pOutput    | Pointer to a destination D3D12_DRED_PAGE_FAULT_OUTPUT1 structure. |

