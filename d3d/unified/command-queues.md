# Command queues

<a id="queue-description"></a>

## Queue description

```cpp
typedef enum D3D12_COMMAND_QUEUE_FLAGS
{
    D3D12_COMMAND_QUEUE_FLAG_NONE = 0x0,
    D3D12_COMMAND_QUEUE_FLAG_DISABLE_GPU_TIMEOUT = 0x1,
    D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY = 0x2,
} D3D12_COMMAND_QUEUE_FLAGS;

typedef enum D3D12_COMMAND_QUEUE_PRIORITY
{
    D3D12_COMMAND_QUEUE_PRIORITY_NORMAL = 0,
    D3D12_COMMAND_QUEUE_PRIORITY_HIGH = 100,
    D3D12_COMMAND_QUEUE_PRIORITY_GLOBAL_REALTIME = 10000
} D3D12_COMMAND_QUEUE_PRIORITY;

typedef struct D3D12_COMMAND_QUEUE_DESC
{
    D3D12_COMMAND_LIST_TYPE Type;
    INT Priority;
    D3D12_COMMAND_QUEUE_FLAGS Flags;
    UINT NodeMask;
} D3D12_COMMAND_QUEUE_DESC;
```

`Type` selects DIRECT, COMPUTE, COPY, VIDEO_DECODE, VIDEO_PROCESS,
VIDEO_ENCODE or NONE. The type must be supported by the device. A video
queue requires the corresponding video support on the selected node.
BUNDLE is not a queue creation type. NONE selects the
[synchronization-only queue](execution.md#synchronization-only-queues),
not a command list execution queue.

`Priority` selects one of the three named `D3D12_COMMAND_QUEUE_PRIORITY`
values. NORMAL and HIGH describe process-relative priority; GLOBAL_REALTIME
requests global realtime priority. See [Creation priority for grouped queues](execution.md#queue-creation-priority)
and [Dynamic queue priority](execution.md#dynamic-queue-priority)
for how grouping affects creation priority. The INT field does not admit
arbitrary unnamed priority values.

`D3D12_COMMAND_QUEUE_FLAG_NONE` indicates a default command queue.
`D3D12_COMMAND_QUEUE_FLAG_DISABLE_GPU_TIMEOUT` indicates that the GPU
timeout should be disabled for this command queue.
`D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY` permits the priority
setters and selects the [opt-in grouping/priority contract](execution.md#dynamic-queue-priority).
Unrecognized flag bits are invalid.

`NodeMask` selects one API-visible node. Zero selects node zero and is
normalized to its one-bit mask. A nonzero mask must contain exactly one
valid node bit. API node selection and the driver's implicit physical adapter
broadcast mask are distinct. See [device nodes](devices-and-capabilities.md#identity)
and [queue fence operation broadcast](execution.md#queue-signal-wait).

<a id="creator-ids"></a>

## Creator IDs and grouping

When multiple components in the same process are sharing a single Direct3D 12 device, often they will end up with separate workloads on independent command queues. In some hardware implementations, independent queues can run in parallel only with specific other command queues.

Direct3D 12 applies a first-come, first-serve grouping for queues, which might not work well for all application or component designs. To help inform Direct3D 12's grouping of queues, applications can specify a *creator ID* (which is unique per component) that restricts the grouping to other queues with the same ID. When possible, a component should choose the same unique ID for all of its queues. Microsoft has reserved a few well-known creator IDs for use by Microsoft-developed implementations of APIs on top of Direct3D 12.

[`CreateCommandQueue`](#id3d12device-createcommandqueue) uses the zero creator GUID.
[`CreateCommandQueue1`](#id3d12device9-createcommandqueue1) supplies the component's chosen creator GUID.

Hardware scheduling groups for DIRECT/COMPUTE queues are partitioned by
node, creator ID, and the presence/absence of the dynamic priority flag.

The scheduling groups can hold up to 1 `DIRECT` queue and up to `ComputeQueuesPer3DQueue` compute queues, before they become full. Once they are full, a new scheduling group is created as the next queue of these types is created.

At queue creation, the runtime looks for a non-full scheduling group from the first to the last existing scheduling groups in creation order to associate the new queue with, or creates a new one if no suitable scheduling group was found.

Deleting a command queue in a scheduling group with surviving queues will open up a spot in an otherwise possibly full scheduling group, and the next queue created will be able to take up this spot and prevent creation of a new scheduling group if no other spots were available.

See the [grouping query](execution.md#hardware-scheduling-queue-groupings)
for the reported COMPUTE capacity and [dynamic queue priority](execution.md#dynamic-queue-priority)
for the priority override when an opt-in queue joins an existing group.

<a id="queue-creation-results"></a>

## Common creation requirements and results

<a id="shared-creation-requirements-and-results"></a>

Both creation methods require a valid `pDesc`. `ppCommandQueue` is optional.
When non-NULL, it must point to writable storage that receives the interface
selected by `riid`, normally `ID3D12CommandQueue`. Passing NULL for
`ppCommandQueue` requests validation-only creation. Successful validation
returns `S_FALSE`.

Successful object creation returns `S_OK`. A null or invalid description returns `E_INVALIDARG`. An unsupported queue type also fails validation. Insufficient
global realtime privilege returns `DXGI_ERROR_ACCESS_DENIED`. Absence of
the required global realtime support returns `DXGI_ERROR_UNSUPPORTED`.
Interface, allocation and OS priority operation failures are returned as
the corresponding creation `HRESULT`.

Both queue creation methods are [free-threaded](execution.md#threading).

<a id="id3d12device-createcommandqueue"></a>

## ID3D12Device::CreateCommandQueue

### Declaration

```cpp
HRESULT CreateCommandQueue(
    const D3D12_COMMAND_QUEUE_DESC* pDesc,
    REFIID riid,
    void** ppCommandQueue
);
```

### Behavior

Creates a command queue.

### Parameters

`pDesc`

Specifies a **D3D12_COMMAND_QUEUE_DESC** that describes the command queue.

`riid`

The globally unique identifier (GUID) for the command queue interface.

`ppCommandQueue`

A pointer to a memory block that receives a pointer to the `ID3D12CommandQueue` interface for the command queue.

### Return values

[Common creation results](#queue-creation-results).

<a id="id3d12device9-createcommandqueue1"></a>

## ID3D12Device9::CreateCommandQueue1

### Declaration

```cpp
HRESULT CreateCommandQueue1(
    const D3D12_COMMAND_QUEUE_DESC* pDesc,
    REFIID CreatorID,
    REFIID riid,
    void** ppCommandQueue
);
```

### Behavior

Creates a command queue with a creator ID.

The method follows the same description, validation, output and lifetime
rules as [`CreateCommandQueue`](#id3d12device-createcommandqueue), with [creator-ID grouping](#creator-ids)
instead of the zero creator GUID.

### Parameters

`pDesc`

Specifies a **D3D12_COMMAND_QUEUE_DESC** that describes the command queue.

`CreatorID`

The component's creator GUID restricts eligible scheduling group peers as
defined in [Creator IDs and grouping](#creator-ids).

`riid`

The globally unique identifier (GUID) for the command queue interface.

`ppCommandQueue`

A pointer to a memory block that receives a pointer to the `ID3D12CommandQueue` interface for the command queue.

### Return values

[Common creation results](#queue-creation-results).

<a id="id3d12commandqueue-getdesc"></a>

## ID3D12CommandQueue::GetDesc

### Declaration

```cpp
D3D12_COMMAND_QUEUE_DESC GetDesc();
```

### Behavior

Gets the description of the command queue.

### Return values

The returned `D3D12_COMMAND_QUEUE_DESC` contains the queue's type, stored
creation priority, creation flags and normalized API-visible node mask.
It is not a byte-for-byte echo of unnormalized input: an input zero node mask
selects node zero, whose returned mask has that bit set.

The result is a creation description, not a current OS priority readback or
the mutable cached values returned by
[`GetProcessPriority`](#id3d12commandqueue1-getprocesspriority) and
[`GetGlobalPriority`](#id3d12commandqueue1-getglobalpriority).

<a id="dynamic-priority-values"></a>

## Dynamic priority values and common behavior

<a id="dynamic-priority-values-and-shared-behavior"></a>

```cpp
typedef enum D3D12_COMMAND_QUEUE_PROCESS_PRIORITY
{
    D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_NORMAL = 0,
    D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_HIGH = 1,
} D3D12_COMMAND_QUEUE_PROCESS_PRIORITY;

typedef enum D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY
{
    D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_IDLE = 0,
    D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_DEFAULT = 1,
    D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_NORMAL_0 = 2,
    D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_0 = 18,
    D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_1 = 19,
    D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_2 = 20,
    D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_3 = 21,
    D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_4 = 22,
    D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_5 = 23,
    D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_6 = 24,
    D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_7 = 25,
    D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_8 = 26,
    D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_9 = 27,
    D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_10 = 28,
    D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_11 = 29,
    D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_12 = 30,
    D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_13 = 31,
    D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_HARD_REALTIME = 32,
} D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY;
```

`D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY` specifies priority relative to other
applications. `D3D12_COMMAND_QUEUE_PROCESS_PRIORITY` specifies the
process-relative non-yielding boost. Only the declared values are accepted;
the numeric gaps in the global enum are not additional supported priorities,
and D3D12 values must not be cast to OS scheduling priority encodings.

The setters require `D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY`.
They affect the queue's context owner: all queues in its scheduling group,
or the standalone queue when not grouped. The
[creation mapping, group override and ignored-request policy](execution.md#dynamic-queue-priority)
define the shared state. An ignored setter returns `S_FALSE` and leaves
the prior cached setting intact.

The getters return runtime-maintained cached state for that same owner.
They require a valid output pointer but do not require the opt-in flag.
The cached initial state and accepted updates are distinct from `GetDesc`'s
creation request and are not an OS state query. In particular, when queues
are grouped, the creation priority may be ignored. See [queue creation priority](execution.md#queue-creation-priority).

The cached baseline is `D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_NORMAL` and
`D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_DEFAULT`. Successful creation time
priority application updates the cache using the
[creation mapping](execution.md#dynamic-queue-priority). Accepted setters
update the corresponding setting. On the compatibility grouped path that
omits creation priority application, the baseline values are the initial
getter settings, not the queue's ignored creation priority request.

<a id="id3d12commandqueue1-setprocesspriority"></a>

## ID3D12CommandQueue1::SetProcessPriority

### Declaration

```cpp
HRESULT SetProcessPriority(D3D12_COMMAND_QUEUE_PROCESS_PRIORITY Priority);
```

### Behavior

Requires a queue created with `D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY`.

Sets a [`Priority`](#dynamic-priority-values) for this queue for the current process. On `S_OK`, the priority is applied immediately. All the work scheduled with calls to `ID3D12CommandQueue::ExecuteCommandLists` that is still pending execution before the call to `SetProcessPriority` is executed with the new priority set. All the new work submitted with `ID3D12CommandQueue::ExecuteCommandLists` after the call to `SetProcessPriority` also is executed with the new priority.

### Parameters

`Priority` is one of the two declared `D3D12_COMMAND_QUEUE_PROCESS_PRIORITY`
values. It is not a `D3D12_COMMAND_QUEUE_PRIORITY` creation value or an
arbitrary OS priority integer.

### Return values

| HRESULT | Meaning |
|---|---|
| `S_OK` | The priority was set correctly |
| `S_FALSE` | The priority request for this adapter couldn't be applied and the request was ignored |
| `E_INVALIDARG` | Invalid parameter |
| `DXGI_ERROR_UNSUPPORTED` | `D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY` not present in this queue |
| `E_ACCESSDENIED` | Not enough permissions to set this priority |

Elevation is required to configure some priorities.

<a id="id3d12commandqueue1-getprocesspriority"></a>

## ID3D12CommandQueue1::GetProcessPriority

### Declaration

```cpp
HRESULT GetProcessPriority(D3D12_COMMAND_QUEUE_PROCESS_PRIORITY* pOutValue);
```

### Behavior

Returns the [cached process priority setting](#dynamic-priority-values) for
the queue's context owner.

### Parameters

`pOutValue` is a required writable pointer that receives the cached
`D3D12_COMMAND_QUEUE_PROCESS_PRIORITY`.

### Return values

Returns `S_OK` after writing the result. A null `pOutValue` returns `E_INVALIDARG`.

<a id="id3d12commandqueue1-setglobalpriority"></a>

## ID3D12CommandQueue1::SetGlobalPriority

### Declaration

```cpp
HRESULT SetGlobalPriority(D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY Priority);
```

### Behavior

Requires a queue created with `D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY`.

Sets a global [`Priority`](#dynamic-priority-values) for this queue. On `S_OK`, the priority is applied immediately. All the work scheduled with calls to `ID3D12CommandQueue::ExecuteCommandLists` that is still pending execution before the call to `SetGlobalPriority` is executed with the new priority set. All the new work submitted with `ID3D12CommandQueue::ExecuteCommandLists` after the call to `SetGlobalPriority` also is executed with the new priority.

### Parameters

`Priority` is a declared `D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY` value.
Unnamed integers, including numeric gaps between declared values, are invalid.
These D3D12 enum values are not OS priority encodings.

### Return values

| HRESULT | Meaning |
|---|---|
| `S_OK` | The priority was set correctly |
| `S_FALSE` | The priority request for this adapter couldn't be applied and the request was ignored |
| `E_INVALIDARG` | Invalid parameter |
| `DXGI_ERROR_UNSUPPORTED` | `D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY` not present in this queue |
| `E_ACCESSDENIED` | Not enough permissions to set this priority |

Elevation is required to configure some priorities.

<a id="id3d12commandqueue1-getglobalpriority"></a>

## ID3D12CommandQueue1::GetGlobalPriority

### Declaration

```cpp
HRESULT GetGlobalPriority(D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY* pOutValue);
```

### Behavior

Returns the [cached global priority setting](#dynamic-priority-values) for
the queue's context owner.

### Parameters

`pOutValue` is a required writable pointer that receives the cached
`D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY`.

### Return values

Returns `S_OK` after writing the result. A null `pOutValue` returns `E_INVALIDARG`.

<a id="queue-driver-objects"></a>

## Queue and scheduling group driver contracts

<a id="queue-group-private-storage"></a>

### Queue and scheduling group private storage

[Synchronization-only queues](execution.md#synchronization-only-queues) have no UMD queue object.

The runtime allocates the private bytes reported by the size DDIs, aligned to 16 bytes on Win64 and 8 bytes on Win32. The driver initializes that storage and must not free it.

For these objects, a failed UMD creation DDI receives no matching Destroy DDI.
The UMD must unwind its own partial state and auxiliary allocations before
returning failure. Runtime-managed contexts and hardware queues remain subject
to the [managed object cleanup contract](#context-hardware-queue-lifetime);
their successful creation callbacks do not commit the owning DDI to success.

After a successful UMD creation DDI, the runtime calls the corresponding
Destroy DDI when retiring or abandoning the driver object, including if later
application object initialization fails. Success of the UMD creation DDI
is therefore not a guarantee of application creation success. The private
region remains available through the Destroy DDI. The runtime releases its
storage, while the UMD releases its own auxiliary state.

<a id="queue-creation-descriptions"></a>

### Queue creation descriptions

```cpp

typedef enum D3D12DDI_COMMAND_QUEUE_CREATION_FLAGS
{
    D3D12DDI_COMMAND_QUEUE_CREATION_FLAG_NONE                     = 0x00000000,
    D3D12DDI_COMMAND_QUEUE_CREATION_FLAG_GLOBAL_REALTIME_PRIORITY = 0x00000001
} D3D12DDI_COMMAND_QUEUE_CREATION_FLAGS;

typedef struct D3D12DDIARG_CREATECOMMANDQUEUE_0050
{
    D3D12DDI_COMMAND_QUEUE_FLAGS          QueueFlags;
    UINT                                  NodeMask;
    D3D12DDI_COMMAND_QUEUE_CREATION_FLAGS QueueCreationFlags;
    D3D12DDI_HSCHEDULINGGROUP_0050        SchedulingGroup; // May be NULL
} D3D12DDIARG_CREATECOMMANDQUEUE_0050;
```

`QueueFlags` uses the driver
[workload flags](execution.md#recording-descriptions), not a
cast of the application command list type or queue flags.
`NodeMask` selects the runtime's DDI-visible node for this queue. The runtime
normalizes API node selection and translates it into the DDI node space before
supplying this description. It is distinct from the kernel execution node `NodeOrdinal` supplied
when creating a context.

`QueueCreationFlags` carries creation requests separately from the workload
flags. The global realtime bit is subject to the negotiated field/support
conditions and the [kernel-versus-UMD priority contract](execution.md#queue-creation-priority).
It is not proof that a kernel scheduling priority was applied.
`SchedulingGroup` is a UMD scheduling group handle, or null for a queue
without an associated group. It is not the runtime callback handle.

<a id="queue-size-create-ddis"></a>

### Queue sizing and creation DDIs

The `pfnCalcPrivateCommandQueueSize` DDI is used to calculate the size of a private command queue.

```cpp

typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALCPRIVATECOMMANDQUEUESIZE_0050 )( D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATECOMMANDQUEUE_0050* );
typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATECOMMANDQUEUE_0050 )( D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATECOMMANDQUEUE_0050*, D3D12DDI_HCOMMANDQUEUE, D3D12DDI_HRTCOMMANDQUEUE);
```

Creation receives the driver-private queue handle as the third argument
and the runtime queue handle as the fourth argument. Neither is an output
parameter. The runtime handle is used for
[queue-associated context and hardware queue callbacks](#context-creation-callbacks),
not as driver-private storage. The nullable scheduling group association is
supplied in the description during sizing as well as creation.

If a queue creation DDI succeeds, it returns `S_OK`. Otherwise, it returns an `HRESULT` error code.

During creation, the UMD creates the contexts and hardware queues required
for its queue's transport using the applicable runtime callbacks and their
[synchronous creation window](#context-creation-window).
The [Signal/Wait transport split](execution.md#queue-signal-wait) does not require every
queue to use the same context or hardware queue submission path.

<a id="queue-destruction-ddi"></a>

#### PFND3D12DDI_DESTROYCOMMANDQUEUE

Destroys a command queue.

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_DESTROYCOMMANDQUEUE )( D3D12DDI_HDEVICE, D3D12DDI_HCOMMANDQUEUE );
```

DestroyCommandQueue releases driver-owned queue state before the runtime tears down its managed contexts and group association. It must not free runtime-provided private storage or destroy a group still used by other queues.

<a id="scheduling-group-lifecycle"></a>

### Scheduling group sizing and creation

```cpp
typedef struct D3D12DDIARG_CREATESCHEDULINGGROUP_0050
{
    UINT                         NodeMask;
} D3D12DDIARG_CREATESCHEDULINGGROUP_0050;

typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALCPRIVATESCHEDULINGGROUPSIZE_0050 )( D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATESCHEDULINGGROUP_0050* );
typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATESCHEDULINGGROUP_0050 )( D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATESCHEDULINGGROUP_0050*, D3D12DDI_HSCHEDULINGGROUP_0050, D3D12DDI_HRTSCHEDULINGGROUP_0050 );
```

Scheduling group creation receives driver and runtime group handles. The driver uses the runtime handle for [group-associated context creation](#context-creation-callbacks).

A scheduling group is a driver object that the runtime creates, and which must have at least one 3D/compute context created during its construction. The runtime allows multiple contexts to be constructed. Once the driver returns from CreateSchedulingGroup, no more contexts may be added.

The scheduling group should contain all contexts which target shared hardware or resources that will be leveraged by any child command queues. It does not need to contain all contexts for all child queues.

The runtime establishes a group's driver object before supplying its handle
to a member queue's `_0050` sizing or creation DDI. A queue may use contexts
owned by itself, by its associated group, or both, subject to the
[hardware queue context restrictions](#hardware-queue-creation).
Runtime selection of member queues follows the
[application grouping contract](command-queues.md#creator-ids);
the UMD must not reinterpret a borrowed group handle as ownership of the
group's lifetime.

<a id="scheduling-group-destruction"></a>

#### PFND3D12DDI_DESTROYSCHEDULINGGROUP_0050

Destroys a hardware scheduling group.

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_DESTROYSCHEDULINGGROUP_0050 )( D3D12DDI_HDEVICE, D3D12DDI_HSCHEDULINGGROUP_0050 );
```

DestroySchedulingGroup is called after successful creation and after member queues no longer need the group. The driver releases group state before the runtime reclaims associated contexts and private storage.

<a id="context-creation-callbacks"></a>

### Context creation callbacks

The UMD uses `PFND3D12DDI_CREATECONTEXT_CB` and
`PFND3D12DDI_CREATECONTEXTVIRTUAL_CB` to create contexts associated with a
runtime command queue. The `_0050` scheduling group forms instead associate
the context with the runtime scheduling group. Their first argument is the
owning runtime handle, not a UMD private object handle or an OS device handle.

```cpp
typedef _Check_return_ HRESULT(APIENTRY CALLBACK *PFND3D12DDI_CREATECONTEXT_CB)(
    _In_    D3D12DDI_HRTCOMMANDQUEUE hRTCommandQueue,
    _Inout_ D3DDDICB_CREATECONTEXT*
    );

typedef _Check_return_ HRESULT(APIENTRY CALLBACK *PFND3D12DDI_CREATECONTEXTVIRTUAL_CB)(
    _In_    D3D12DDI_HRTCOMMANDQUEUE hRTCommandQueue,
    _Inout_ D3DDDICB_CREATECONTEXTVIRTUAL*
    );

typedef _Check_return_ HRESULT(APIENTRY CALLBACK *PFND3D12DDI_CREATESCHEDULINGGROUPCONTEXT_CB_0050)(
    _In_    D3D12DDI_HRTSCHEDULINGGROUP_0050 hRTSchedulingGroup,
    _Inout_ D3DDDICB_CREATECONTEXT*
    );

typedef _Check_return_ HRESULT(APIENTRY CALLBACK *PFND3D12DDI_CREATESCHEDULINGGROUPCONTEXTVIRTUAL_CB_0050)(
    _In_    D3D12DDI_HRTSCHEDULINGGROUP_0050 hRTSchedulingGroup,
    _Inout_ D3DDDICB_CREATECONTEXTVIRTUAL*
    );
```

Both context descriptions supply `NodeOrdinal`, `EngineAffinity`, `Flags`,
`pPrivateDriverData` and `PrivateDriverDataSize`. The ordinal and affinity
select the execution node and engine. Private driver data is passed to the
kernel-mode driver, with its size in bytes. Reserved flag bits must be zero.
Scheduling group context creation requires `Flags.HwQueueSupported`.

On success, `hContext` is an opaque runtime context handle. It is not the raw
kernel context handle and must not be substituted for one in a direct OS call.
The non-virtual description also returns command buffer, allocation list and
patch location list information where applicable to that transport.
Command buffer sizes are in bytes. Allocation list and patch location list
sizes are element counts. The virtual context form is for contexts supporting
GPU virtual addressing and does not return those software submission buffers.

<a id="context-creation-window"></a>

#### Creation window

Queue context creation callbacks must execute synchronously on the thread
performing the owning CreateCommandQueue DDI, before that DDI returns.
Scheduling group context creation callbacks have the corresponding requirement
for the owning CreateSchedulingGroup DDI. Worker thread calls and calls after
the owning creation DDI has returned are not permitted. This is a requirement
of these D3D12 object-associated callbacks, not a general threading rule for
all common device callbacks.

<a id="hardware-queue-creation"></a>

### Hardware queue creation callback

`PFND3D12DDI_CREATEHWQUEUE_CB_0050` creates a hardware queue associated with
the runtime command queue identified by `hRTCommandQueue`. It must execute
synchronously on the thread performing that queue's CreateCommandQueue DDI,
before the DDI returns, with the same restriction on worker thread or later
calls as the [context creation window](#context-creation-window).

```cpp
typedef _Check_return_ HRESULT(APIENTRY CALLBACK *PFND3D12DDI_CREATEHWQUEUE_CB_0050)(
    _In_    D3D12DDI_HRTCOMMANDQUEUE hRTCommandQueue,
    _Inout_ D3DDDICB_CREATEHWQUEUE*
    );
```

Hardware queue creation must be done against a context either associated with the same command queue, or with a parent scheduling group. The driver is allowed to create hardware queues which reference both types of contexts for a single [CreateCommandQueue](#queue-driver-objects).

The driver is allowed to have a command queue which owns both software-scheduled contexts, and hardware queues, if and only if the command queue also owns the contexts for those hardware queues. Each command queue must be capable of performing broadcast synchronization across only contexts for mixed hardware and software, or only hardware queues.

`D3DDDICB_CREATEHWQUEUE::hHwContext` supplies that runtime context handle.
`Flags` supplies hardware queue creation flags, with reserved bits zero.
`pPrivateDriverData` and its byte size describe the in/out private data
exchange with the kernel-mode driver. On success, `hHwQueue` is an opaque
runtime hardware queue handle, not the raw OS hardware queue handle.
The payload also returns `hHwQueueProgressFence` and the progress fence's CPU
and GPU virtual addresses. That OS fence handle is a different handle domain
from `hHwQueue`.

<a id="context-hardware-queue-lifetime"></a>

### Managed context and hardware queue lifetime

Individual destruction operations are not provided for these objects, as their lifetime is completely managed by the owning runtime object.

The creation callbacks' `HRESULT` reports the callback operation, not success
of the enclosing UMD owner creation DDI. Successful callback creation does not
commit that enclosing DDI to success. The runtime manages reclamation of its
associated contexts and hardware queues through owning object teardown or
creation failure cleanup. The UMD remains responsible for its own partial
driver state and auxiliary allocations. Runtime ownership does not promise
an exact physical reclamation time.

<a id="legacy-destroy-context"></a>

#### Legacy D3D12 DestroyContext callback

```cpp
typedef _Check_return_ HRESULT(APIENTRY CALLBACK *PFND3D12DDI_DESTROYCONTEXT_CB)(
    _In_    D3D12DDI_HRTCOMMANDQUEUE hRTCommandQueue,
    _In_ const D3DDDICB_DESTROYCONTEXT*
    );
```

For a valid invocation, `PFND3D12DDI_DESTROYCONTEXT_CB` is a compatibility
no-op that returns `S_OK`. `hRTCommandQueue` identifies the runtime queue and
the description's `hContext` identifies the context. This callback does not
destroy or invalidate that context or transfer cleanup responsibility to the
UMD. Its success is not evidence that resources were released. This behavior
is specific to the D3D12 callback above, not a contract for the similarly
named common device destruction callbacks.
