# Command queues

<!-- d3d12-review-legend:begin -->

> [!NOTE]
> **Draft provenance annotations.**
> Underlining marks pending replacement wording or authored list items. Warning boxes
> mark authored, mixed or reopened passages awaiting editorial review.
> Editorial adoption does not establish factual or hardware verification. Exact approved factual
> corrections do not trigger a marker. Unmarked text elsewhere, declarations
> and structural Markdown are not assertions of approval.
> [Annotation scope and approvals](../../spec-maintenance/d3d12/prose-annotations.md).

<!-- d3d12-review-legend:end -->

<!-- d3d12-review-alert:begin:command-queues:QA-001:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Coverage: selected draft.** This chapter defines queue creation,
> description, grouping, priority and driver queue-object contracts. Shared
> [queue timelines, submission, CPU threading and lifetime](execution.md)
> and [fence driver contracts](execution.md#fence-driver-objects) retain their
> execution owner. Queue
> [timestamps and clock calibration](counters-queries-and-predication.md)
> are defined with queries.

<!-- d3d12-review-alert:end:command-queues:QA-001:0 -->

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

<!-- d3d12-review-alert:begin:command-queues:QA-003:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `Type` selects DIRECT, COMPUTE, COPY, VIDEO_DECODE, VIDEO_PROCESS,
> VIDEO_ENCODE or NONE. The type must be supported by the device; a video
> queue requires the corresponding video support on the selected node.
> BUNDLE is not a queue-creation type. NONE selects the
> [synchronization-only queue](execution.md#synchronization-only-queues),
> not a command-list execution queue.

<!-- d3d12-review-alert:end:command-queues:QA-003:0 -->

<!-- d3d12-review-alert:begin:command-queues:QA-004:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `Priority` selects one of the three named `D3D12_COMMAND_QUEUE_PRIORITY`
> values. NORMAL and HIGH describe process-relative priority; GLOBAL_REALTIME
> requests global-realtime priority. The [compatibility grouped-queue
> omission and separate UMD request](execution.md#queue-creation-priority)
> and the [opt-in group override](execution.md#dynamic-queue-priority)
> qualify how creation priority is applied. The INT field does not admit
> arbitrary unnamed priority values.

<!-- d3d12-review-alert:end:command-queues:QA-004:0 -->

<!-- d3d12-review-alert:begin:command-queues:QA-005:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12_COMMAND_QUEUE_FLAG_NONE` indicates a default command queue.
> `D3D12_COMMAND_QUEUE_FLAG_DISABLE_GPU_TIMEOUT` indicates that the GPU
> timeout should be disabled for this command queue.
> `D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY` permits the priority
> setters and selects the [opt-in grouping/priority contract](execution.md#dynamic-queue-priority).
> Unrecognized flag bits are invalid.

<!-- d3d12-review-alert:end:command-queues:QA-005:0 -->

<!-- d3d12-review-alert:begin:command-queues:QA-006:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `NodeMask` selects one API-visible node. Zero selects node zero and is
> normalized to its one-bit mask. A nonzero mask must contain exactly one
> valid node bit. API node selection and the driver's implicit physical-adapter
> broadcast mask are distinct; see [device nodes](devices-and-capabilities.md#identity)
> and [queue fence-operation broadcast](execution.md#queue-signal-wait).

<!-- d3d12-review-alert:end:command-queues:QA-006:0 -->

<a id="creator-ids"></a>

## Creator IDs and grouping

When multiple components in the same process are sharing a single Direct3D 12 device, often they will end up with separate workloads on independent command queues. In some hardware implementations, independent queues can run in parallel only with specific other command queues.

Direct3D 12 applies a first-come, first-serve grouping for queues, which might not work well for all application or component designs. To help inform Direct3D 12's grouping of queues, you can specify a *creator ID* (which is unique per component) that restricts the grouping to other queues with the same ID. When possible, a component should choose the same unique ID for all of its queues. Microsoft has reserved a few well-known creator IDs for use by Microsoft-developed implementations of APIs on top of Direct3D 12.

<!-- d3d12-review-alert:begin:command-queues:QA-009:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The ordinary `CreateCommandQueue` entry uses the zero creator GUID.
> `CreateCommandQueue1` supplies the component's chosen creator GUID instead;
> this is not the interface IID in `riid` and does not change the device/node
> selection. A creator ID restricts grouping eligibility, not a guarantee of
> parallel execution.

<!-- d3d12-review-alert:end:command-queues:QA-009:0 -->

<!-- d3d12-review-alert:begin:command-queues:QA-010:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Hardware scheduling groups for DIRECT/COMPUTE queues are partitioned by
> node and creator ID. Opt-in dynamic-priority queues do not share a group
> with queues lacking the flag.

<!-- d3d12-review-alert:end:command-queues:QA-010:0 -->

The scheduling groups can hold up to 1 `DIRECT` queue and up to `ComputeQueuesPer3DQueue` compute queues, before they become full. Once they are full, a new scheduling group is created as the next queue of these types is created.

At queue creation, the runtime looks for a non-full scheduling group from the first to the last existing scheduling groups in creation order to associate the new queue with, or creates a new one if no suitable scheduling group was found.

<ins><!-- d3d12-review-inline:begin:command-queues:QA-013:0 -->Deleting a command queue in a scheduling group with surviving queues will open up a spot in an otherwise possibly full scheduling group, and the next queue created will be able to take up this spot and prevent creation of a new scheduling group if no other spots were available.<!-- d3d12-review-inline:end:command-queues:QA-013:0 --></ins>

<!-- d3d12-review-alert:begin:command-queues:QA-014:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [grouping query](execution.md#hardware-scheduling-queue-groupings)
> defines the reported COMPUTE capacity; the
> [creation override](execution.md#dynamic-queue-priority) applies when an
> opt-in queue joins an existing group.

<!-- d3d12-review-alert:end:command-queues:QA-014:0 -->

<a id="queue-creation-results"></a>

## Shared creation requirements and results

<!-- d3d12-review-alert:begin:command-queues:QA-015:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Both creation methods require a valid `pDesc` and a writable
> `ppCommandQueue`. They create an interface selected by `riid`, normally
> `ID3D12CommandQueue`. A null output pointer is not a specified
> validation-only `S_FALSE` operation.

<!-- d3d12-review-alert:end:command-queues:QA-015:0 -->

<!-- d3d12-review-alert:begin:command-queues:QA-016:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Successful object creation returns `S_OK`. A null description pointer or
> invalid queue types, priorities, flag bits or node masks return `E_INVALIDARG`;
> an unsupported video queue type also fails validation. Insufficient
> global-realtime privilege returns `DXGI_ERROR_ACCESS_DENIED`; absence of
> the required global-realtime support returns `DXGI_ERROR_UNSUPPORTED`.
> The grouped-queue compatibility behavior does not waive these checks.
> Interface, allocation and OS priority-operation failures are returned as
> the corresponding creation `HRESULT`.

<!-- d3d12-review-alert:end:command-queues:QA-016:0 -->

<!-- d3d12-review-alert:begin:command-queues:QA-017:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The device creation methods are [free-threaded](execution.md#threading).
> Creating a queue does not execute application command lists. Its return
> does not establish completion of work submitted on other queues.

<!-- d3d12-review-alert:end:command-queues:QA-017:0 -->

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

<ins><!-- d3d12-review-inline:begin:command-queues:QA-019:0 -->Creates a command queue.<!-- d3d12-review-inline:end:command-queues:QA-019:0 --></ins>

<!-- d3d12-review-alert:begin:command-queues:QA-020:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The method uses the [ordinary zero creator ID](#creator-ids) and the shared
> creation rules. The queue's type determines its permitted operations; NONE
> does not acquire command-list execution capability by implementing the same
> queue interface.

<!-- d3d12-review-alert:end:command-queues:QA-020:0 -->

### Parameters

<!-- d3d12-review-alert:begin:command-queues:QA-021:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **pDesc**

<!-- d3d12-review-alert:end:command-queues:QA-021:0 -->

Specifies a **D3D12_COMMAND_QUEUE_DESC** that describes the command queue.

<!-- d3d12-review-alert:begin:command-queues:QA-023:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The pointer is required; its fields follow the [queue description](#queue-description).

<!-- d3d12-review-alert:end:command-queues:QA-023:0 -->

<!-- d3d12-review-alert:begin:command-queues:QA-024:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **riid**

<!-- d3d12-review-alert:end:command-queues:QA-024:0 -->

The globally unique identifier (GUID) for the command queue interface.

<!-- d3d12-review-alert:begin:command-queues:QA-026:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **ppCommandQueue**

<!-- d3d12-review-alert:end:command-queues:QA-026:0 -->

<ins><!-- d3d12-review-inline:begin:command-queues:QA-027:0 -->A pointer to a memory block that receives a pointer to the `ID3D12CommandQueue` interface for the command queue.<!-- d3d12-review-inline:end:command-queues:QA-027:0 --></ins>

<!-- d3d12-review-alert:begin:command-queues:QA-028:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The output pointer is required and receives the interface selected by `riid`.

<!-- d3d12-review-alert:end:command-queues:QA-028:0 -->

### Return values

<!-- d3d12-review-alert:begin:command-queues:QA-029:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [shared creation results](#queue-creation-results) apply, including `S_OK`
> for a created object, validation/privilege/support failures and `E_OUTOFMEMORY`.

<!-- d3d12-review-alert:end:command-queues:QA-029:0 -->

<ins><!-- d3d12-review-inline:begin:command-queues:QA-030:0 -->This method returns `E_OUTOFMEMORY` if there is insufficient memory to create the command queue.<!-- d3d12-review-inline:end:command-queues:QA-030:0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:command-queues:QA-032:0 -->Creates a command queue with a creator ID.<!-- d3d12-review-inline:end:command-queues:QA-032:0 --></ins>

<!-- d3d12-review-alert:begin:command-queues:QA-033:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The method follows the same description, validation, output and lifetime
> rules as `CreateCommandQueue`, with [creator-ID grouping](#creator-ids)
> instead of the ordinary zero creator GUID.

<!-- d3d12-review-alert:end:command-queues:QA-033:0 -->

### Parameters

<!-- d3d12-review-alert:begin:command-queues:QA-034:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **pDesc**

<!-- d3d12-review-alert:end:command-queues:QA-034:0 -->

Specifies a **D3D12_COMMAND_QUEUE_DESC** that describes the command queue.

<!-- d3d12-review-alert:begin:command-queues:QA-036:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **CreatorID**

<!-- d3d12-review-alert:end:command-queues:QA-036:0 -->

<!-- d3d12-review-alert:begin:command-queues:QA-037:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The component's creator GUID restricts eligible scheduling-group peers as
> defined in [Creator IDs and grouping](#creator-ids). It is not `riid`.

<!-- d3d12-review-alert:end:command-queues:QA-037:0 -->

<!-- d3d12-review-alert:begin:command-queues:QA-038:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **riid**

<!-- d3d12-review-alert:end:command-queues:QA-038:0 -->

The globally unique identifier (GUID) for the command queue interface.

<!-- d3d12-review-alert:begin:command-queues:QA-040:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **ppCommandQueue**

<!-- d3d12-review-alert:end:command-queues:QA-040:0 -->

<ins><!-- d3d12-review-inline:begin:command-queues:QA-041:0 -->A pointer to a memory block that receives a pointer to the `ID3D12CommandQueue` interface for the command queue.<!-- d3d12-review-inline:end:command-queues:QA-041:0 --></ins>

### Return values

<!-- d3d12-review-alert:begin:command-queues:QA-042:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [shared creation results](#queue-creation-results) apply. Supplying a
> creator ID does not define an additional success result or remove the
> ordinary creation preconditions.

<!-- d3d12-review-alert:end:command-queues:QA-042:0 -->

<a id="id3d12commandqueue-getdesc"></a>

## ID3D12CommandQueue::GetDesc

### Declaration

```cpp
D3D12_COMMAND_QUEUE_DESC GetDesc();
```

### Behavior

<ins><!-- d3d12-review-inline:begin:command-queues:QA-044:0 -->Gets the description of the command queue.<!-- d3d12-review-inline:end:command-queues:QA-044:0 --></ins>

### Return values

<!-- d3d12-review-alert:begin:command-queues:QA-045:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The returned `D3D12_COMMAND_QUEUE_DESC` contains the queue's type, stored
> creation priority, creation flags and normalized API-visible node mask.
> It is not a byte-for-byte echo of unnormalized input: an input zero node mask
> selects node zero, whose returned mask has that bit set.

<!-- d3d12-review-alert:end:command-queues:QA-045:0 -->

<!-- d3d12-review-alert:begin:command-queues:QA-046:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The result is a creation description, not a current OS priority readback or
> the mutable values returned by the two dynamic-priority getters. Creator ID
> and scheduling-group identity are not fields of this result.

<!-- d3d12-review-alert:end:command-queues:QA-046:0 -->

<a id="queue-driver-objects"></a>

## Queue and scheduling-group driver contracts

<a id="queue-group-private-storage"></a>

### Queue and scheduling-group private storage

<!-- d3d12-review-alert:begin:command-queues:QF-LN01:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The queue and scheduling-group DDIs below are implemented by the UMD and
> called by the runtime. They are distinct from the driver-callable creation
> callbacks later in this reference. The [application queue contracts](command-queues.md)
> define creation requests and grouping policy.
> [Synchronization-only queues](execution.md#synchronization-only-queues)
> have no UMD command-queue object and do not use this object-creation sequence.

<!-- d3d12-review-alert:end:command-queues:QF-LN01:0 -->

<!-- d3d12-review-alert:begin:command-queues:QF-LN02:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The private-size DDIs return the required UMD storage size in bytes as
> `SIZE_T`, excluding the runtime's own object storage. The runtime supplies the
> driver-private region when calling the corresponding creation DDI.
> `D3D12DDI_HCOMMANDQUEUE::pDrvPrivate` and
> `D3D12DDI_HSCHEDULINGGROUP_0050::pDrvPrivate` address those regions.
> Their actual addresses are aligned to 16 bytes on Win64 and 8 bytes on Win32.
> The UMD initializes its state there and must not free the runtime-provided
> region. UMD-owned auxiliary allocations remain the UMD's responsibility.

<!-- d3d12-review-alert:end:command-queues:QF-LN02:0 -->

<!-- d3d12-review-alert:begin:command-queues:QF-LN03:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> For these objects, a failed UMD creation DDI receives no matching Destroy DDI.
> The UMD must unwind its own partial state and auxiliary allocations before
> returning failure. Runtime-managed contexts and hardware queues remain subject
> to the [managed-object cleanup contract](#context-hardware-queue-lifetime);
> their successful creation callbacks do not commit the owning DDI to success.

<!-- d3d12-review-alert:end:command-queues:QF-LN03:0 -->

<!-- d3d12-review-alert:begin:command-queues:QF-LN04:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> After a successful UMD creation DDI, the runtime calls the corresponding
> Destroy DDI when retiring or abandoning the driver object, including if later
> application-object initialization fails. Success of the UMD creation DDI
> is therefore not a guarantee of application creation success. The private
> region remains available through the Destroy DDI; the runtime releases its
> storage, while the UMD releases its own auxiliary state.

<!-- d3d12-review-alert:end:command-queues:QF-LN04:0 -->

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

<!-- d3d12-review-alert:begin:command-queues:QF-LN06:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `QueueFlags` uses the driver
> [workload flags](execution.md#recording-descriptions), not a
> cast of the application command-list type or queue flags.
> `NodeMask` selects the runtime's DDI-visible node for this queue. The runtime
> normalizes API node selection and translates it into the DDI node space before
> supplying this description. It is distinct from the kernel execution-node `NodeOrdinal` supplied
> when creating a context.

<!-- d3d12-review-alert:end:command-queues:QF-LN06:0 -->

<!-- d3d12-review-alert:begin:command-queues:QF-LN07:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `QueueCreationFlags` carries creation requests separately from the workload
> flags. The global-realtime bit is subject to the negotiated field/support
> conditions and the [kernel-versus-UMD priority contract](execution.md#queue-creation-priority).
> It is not proof that a kernel scheduling priority was applied.
> `SchedulingGroup` is a UMD scheduling-group handle, or null for a queue
> without an associated group. It is not the runtime callback handle.

<!-- d3d12-review-alert:end:command-queues:QF-LN07:0 -->

<a id="queue-size-create-ddis"></a>

### Queue sizing and creation DDIs

<ins><!-- d3d12-review-inline:begin:command-queues:QF-LI01:0 -->The `pfnCalcPrivateCommandQueueSize` DDI is used to calculate the size of a private command queue.<!-- d3d12-review-inline:end:command-queues:QF-LI01:0 --></ins>

```cpp

typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALCPRIVATECOMMANDQUEUESIZE_0050 )( D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATECOMMANDQUEUE_0050* );
typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATECOMMANDQUEUE_0050 )( D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATECOMMANDQUEUE_0050*, D3D12DDI_HCOMMANDQUEUE, D3D12DDI_HRTCOMMANDQUEUE);
```

<!-- d3d12-review-alert:begin:command-queues:QF-LN09:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The first parameter identifies the UMD device. The description identifies the
> queue whose storage is being sized or initialized. The runtime selects the
> matching description/function-pointer form from the negotiated device table;
> the suffixes do not mean that all forms are called for one queue.

<!-- d3d12-review-alert:end:command-queues:QF-LN09:0 -->

<!-- d3d12-review-alert:begin:command-queues:QF-LN11:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Creation receives the driver-private queue handle as the third argument
> and the runtime queue handle as the fourth argument. Neither is an output
> parameter. The runtime handle is used for
> [queue-associated context and hardware-queue callbacks](#context-creation-callbacks),
> not as driver-private storage. The nullable scheduling-group association is
> supplied in the description during sizing as well as creation.

<!-- d3d12-review-alert:end:command-queues:QF-LN11:0 -->

If <ins><!-- d3d12-review-inline:begin:command-queues:QF-LI02:0 -->a queue-creation DDI<!-- d3d12-review-inline:end:command-queues:QF-LI02:0 --></ins> succeeds, it returns <ins><!-- d3d12-review-inline:begin:command-queues:QF-LI02:0 -->`S_OK`<!-- d3d12-review-inline:end:command-queues:QF-LI02:0 --></ins>. Otherwise, it returns an <ins><!-- d3d12-review-inline:begin:command-queues:QF-LI02:0 -->`HRESULT`<!-- d3d12-review-inline:end:command-queues:QF-LI02:0 --></ins> error code.

<!-- d3d12-review-alert:begin:command-queues:QF-LN12:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> During creation, the UMD creates the contexts and hardware queues required
> for its queue's transport using the applicable runtime callbacks and their
> [synchronous creation window](#context-creation-window).
> The [Signal/Wait transport split](execution.md#queue-signal-wait) does not require every
> queue to use the same context or hardware-queue submission path.

<!-- d3d12-review-alert:end:command-queues:QF-LN12:0 -->

<a id="queue-destruction-ddi"></a>

#### PFND3D12DDI_DESTROYCOMMANDQUEUE

<ins><!-- d3d12-review-inline:begin:command-queues:QF-LI03:0 -->Destroys a command queue.<!-- d3d12-review-inline:end:command-queues:QF-LI03:0 --></ins>

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_DESTROYCOMMANDQUEUE )( D3D12DDI_HDEVICE, D3D12DDI_HCOMMANDQUEUE );
```

<!-- d3d12-review-alert:begin:command-queues:QF-LN14:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The runtime supplies the UMD device and the successfully created UMD queue
> handle. The UMD releases its queue state and auxiliary allocations without
> freeing the runtime-provided private region. The runtime calls this DDI
> before tearing down the queue's managed contexts and group association.
> Destroying one queue does not authorize destroying a scheduling group still
> used by other queues. This DDI returns no `HRESULT`.

<!-- d3d12-review-alert:end:command-queues:QF-LN14:0 -->

<a id="scheduling-group-lifecycle"></a>

### Scheduling-group sizing and creation

```cpp
typedef struct D3D12DDIARG_CREATESCHEDULINGGROUP_0050
{
    UINT                         NodeMask;
} D3D12DDIARG_CREATESCHEDULINGGROUP_0050;

typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALCPRIVATESCHEDULINGGROUPSIZE_0050 )( D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATESCHEDULINGGROUP_0050* );
typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATESCHEDULINGGROUP_0050 )( D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATESCHEDULINGGROUP_0050*, D3D12DDI_HSCHEDULINGGROUP_0050, D3D12DDI_HRTSCHEDULINGGROUP_0050 );
```

<!-- d3d12-review-alert:begin:command-queues:QF-LN16:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The sizing DDI receives the UMD device and the group's DDI-visible `NodeMask`,
> and returns the group's required private bytes. Creation receives the same
> description, a driver-private group handle as its third argument and the
> runtime group handle as its fourth argument. The UMD initializes the supplied
> private region and uses the runtime handle for
> [scheduling-group context callbacks](#context-creation-callbacks).
> Creation returns `S_OK` on success or a failing `HRESULT`.
> The [private-storage and failure rules](#queue-group-private-storage) apply
> to both queue and scheduling-group creation.

<!-- d3d12-review-alert:end:command-queues:QF-LN16:0 -->

A scheduling group is a driver object that the runtime <ins><!-- d3d12-review-inline:begin:command-queues:QF-LI04:0 -->creates<!-- d3d12-review-inline:end:command-queues:QF-LI04:0 --></ins>, and which must have at least one 3D/compute context created during its construction. The runtime <ins><!-- d3d12-review-inline:begin:command-queues:QF-LI04:0 -->allows<!-- d3d12-review-inline:end:command-queues:QF-LI04:0 --></ins> multiple contexts to be constructed. Once the driver returns from CreateSchedulingGroup, no more contexts may be added.

The scheduling group should contain all contexts which target shared hardware or resources that will be leveraged by any child command queues. It does not need to contain all contexts for all child queues.

<!-- d3d12-review-alert:begin:command-queues:QF-LN17:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The runtime establishes a group's driver object before supplying its handle
> to a member queue's `_0050` sizing or creation DDI. A queue may use contexts
> owned by itself, by its associated group, or both, subject to the
> [hardware-queue context restrictions](#hardware-queue-creation).
> Runtime selection of member queues follows the
> [application grouping contract](command-queues.md#creator-ids);
> the UMD must not reinterpret a borrowed group handle as ownership of the
> group's lifetime.

<!-- d3d12-review-alert:end:command-queues:QF-LN17:0 -->

<a id="scheduling-group-destruction"></a>

#### PFND3D12DDI_DESTROYSCHEDULINGGROUP_0050

<ins><!-- d3d12-review-inline:begin:command-queues:QF-LI06:0 -->Destroys a hardware scheduling group.<!-- d3d12-review-inline:end:command-queues:QF-LI06:0 --></ins>

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_DESTROYSCHEDULINGGROUP_0050 )( D3D12DDI_HDEVICE, D3D12DDI_HSCHEDULINGGROUP_0050 );
```

<!-- d3d12-review-alert:begin:command-queues:QF-LN19:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The runtime supplies the UMD device and successfully created driver group
> handle. The group is not retired while member queues still require it.
> The UMD releases its group state and auxiliary allocations; the runtime
> manages the private region and associated contexts. The runtime calls this
> DDI before reclaiming those context objects. It returns no `HRESULT` and is
> not called for a failed UMD CreateSchedulingGroup DDI.

<!-- d3d12-review-alert:end:command-queues:QF-LN19:0 -->

<a id="context-creation-callbacks"></a>

### Context creation callbacks

<!-- d3d12-review-alert:begin:command-queues:QF-X01:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The UMD uses `PFND3D12DDI_CREATECONTEXT_CB` and
> `PFND3D12DDI_CREATECONTEXTVIRTUAL_CB` to create contexts associated with a
> runtime command queue. The `_0050` scheduling-group forms instead associate
> the context with the runtime scheduling group. Their first argument is the
> owning runtime handle, not a UMD private-object handle or an OS device handle.

<!-- d3d12-review-alert:end:command-queues:QF-X01:0 -->

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

<!-- d3d12-review-alert:begin:command-queues:QF-X03:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Both context descriptions supply `NodeOrdinal`, `EngineAffinity`, `Flags`,
> `pPrivateDriverData` and `PrivateDriverDataSize`. The ordinal and affinity
> select the execution node and engine; private driver data is passed to the
> kernel-mode driver, with its size in bytes. Reserved flag bits must be zero.
> Scheduling-group context creation requires `Flags.HwQueueSupported`.

<!-- d3d12-review-alert:end:command-queues:QF-X03:0 -->

<!-- d3d12-review-alert:begin:command-queues:QF-X04:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> On success, `hContext` is an opaque runtime context handle. It is not the raw
> kernel context handle and must not be substituted for one in a direct OS call.
> The non-virtual description also returns command-buffer, allocation-list and
> patch-location-list information where applicable to that transport.
> Command-buffer sizes are in bytes; allocation-list and patch-location-list
> sizes are element counts. The virtual-context form is for contexts supporting
> GPU virtual addressing and does not return those software-submission buffers.

<!-- d3d12-review-alert:end:command-queues:QF-X04:0 -->

<a id="context-creation-window"></a>

#### Creation window

<!-- d3d12-review-alert:begin:command-queues:QF-X05:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Queue-context creation callbacks must execute synchronously on the thread
> performing the owning CreateCommandQueue DDI, before that DDI returns.
> Scheduling-group context creation callbacks have the corresponding requirement
> for the owning CreateSchedulingGroup DDI. Worker-thread calls and calls after
> the owning creation DDI has returned are not permitted. This is a requirement
> of these D3D12 object-associated callbacks, not a general threading rule for
> all shared-device callbacks.

<!-- d3d12-review-alert:end:command-queues:QF-X05:0 -->

<a id="hardware-queue-creation"></a>

### Hardware-queue creation callback

<!-- d3d12-review-alert:begin:command-queues:QF-X06:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `PFND3D12DDI_CREATEHWQUEUE_CB_0050` creates a hardware queue associated with
> the runtime command queue identified by `hRTCommandQueue`. It must execute
> synchronously on the thread performing that queue's CreateCommandQueue DDI,
> before the DDI returns, with the same restriction on worker-thread or later
> calls as the [context creation window](#context-creation-window).

<!-- d3d12-review-alert:end:command-queues:QF-X06:0 -->

```cpp
typedef _Check_return_ HRESULT(APIENTRY CALLBACK *PFND3D12DDI_CREATEHWQUEUE_CB_0050)(
    _In_    D3D12DDI_HRTCOMMANDQUEUE hRTCommandQueue,
    _Inout_ D3DDDICB_CREATEHWQUEUE*
    );
```

<ins><!-- d3d12-review-inline:begin:command-queues:QF-X08:0 -->Hardware<!-- d3d12-review-inline:end:command-queues:QF-X08:0 --></ins> queue creation must be done against a context either associated with the same command queue, or with a parent scheduling group. The driver is allowed to create hardware queues which reference both types of contexts for a single [CreateCommandQueue](https://learn.microsoft.com/windows-hardware/drivers/ddi/d3d12umddi/nc-d3d12umddi-pfnd3d12ddi_createcommandqueue_0050).

The driver is allowed to have a command queue which owns both software-scheduled contexts, and hardware queues, if and only if the command queue also owns the contexts for those hardware queues. Each command queue must be capable of performing broadcast synchronization across only contexts for mixed hardware and software, or only hardware queues.

<!-- d3d12-review-alert:begin:command-queues:QF-X09:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3DDDICB_CREATEHWQUEUE::hHwContext` supplies that runtime context handle.
> `Flags` supplies hardware-queue creation flags, with reserved bits zero.
> `pPrivateDriverData` and its byte size describe the in/out private-data
> exchange with the kernel-mode driver. On success, `hHwQueue` is an opaque
> runtime hardware-queue handle, not the raw OS hardware-queue handle.
> The payload also returns `hHwQueueProgressFence` and the progress fence's CPU
> and GPU virtual addresses; that OS fence handle is a different handle domain
> from `hHwQueue`.

<!-- d3d12-review-alert:end:command-queues:QF-X09:0 -->

<a id="context-hardware-queue-lifetime"></a>

### Managed context and hardware-queue lifetime

<ins><!-- d3d12-review-inline:begin:command-queues:QF-X10:0 -->Individual destruction operations<!-- d3d12-review-inline:end:command-queues:QF-X10:0 --></ins> are not provided for these objects, as their lifetime is completely managed by the owning runtime object.

<!-- d3d12-review-alert:begin:command-queues:QF-X11:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The creation callbacks' `HRESULT` reports the callback operation, not success
> of the enclosing UMD owner-creation DDI. Successful callback creation does not
> commit that enclosing DDI to success. The runtime manages reclamation of its
> associated contexts and hardware queues through owning-object teardown or
> creation-failure cleanup. The UMD remains responsible for its own partial
> driver state and auxiliary allocations. Runtime ownership does not promise
> an exact physical reclamation time.

<!-- d3d12-review-alert:end:command-queues:QF-X11:0 -->

<a id="legacy-destroy-context"></a>

#### Legacy D3D12 DestroyContext callback

```cpp
typedef _Check_return_ HRESULT(APIENTRY CALLBACK *PFND3D12DDI_DESTROYCONTEXT_CB)(
    _In_    D3D12DDI_HRTCOMMANDQUEUE hRTCommandQueue,
    _In_ const D3DDDICB_DESTROYCONTEXT*
    );
```

<!-- d3d12-review-alert:begin:command-queues:QF-X13:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> For a valid invocation, `PFND3D12DDI_DESTROYCONTEXT_CB` is a compatibility
> no-op that returns `S_OK`. `hRTCommandQueue` identifies the runtime queue and
> the description's `hContext` identifies the context; this callback does not
> destroy or invalidate that context or transfer cleanup responsibility to the
> UMD. Its success is not evidence that resources were released. This behavior
> is specific to the D3D12 callback above, not a contract for the similarly
> named shared-device destruction callbacks.

<!-- d3d12-review-alert:end:command-queues:QF-X13:0 -->

<a id="dynamic-priority-values"></a>

## Dynamic-priority values and shared behavior

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

<!-- d3d12-review-alert:begin:command-queues:QA-048:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY` specifies priority relative to other
> applications; `D3D12_COMMAND_QUEUE_PROCESS_PRIORITY` specifies the
> process-relative non-yielding boost. Only the declared values are accepted;
> the numeric gaps in the global enum are not additional supported priorities,
> and D3D12 values must not be cast to OS scheduling-priority encodings.

<!-- d3d12-review-alert:end:command-queues:QA-048:0 -->

<!-- d3d12-review-alert:begin:command-queues:QA-049:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The setters require `D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY`.
> They affect the queue's context owner: all queues in its scheduling group,
> or the standalone queue when not grouped. The
> [creation mapping, group override and ignored-request policy](execution.md#dynamic-queue-priority)
> define the shared state. An ignored setter returns `S_FALSE` and leaves
> the prior cached setting intact.

<!-- d3d12-review-alert:end:command-queues:QA-049:0 -->

<!-- d3d12-review-alert:begin:command-queues:QA-050:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The getters return runtime-maintained cached state for that same owner.
> They require a valid output pointer but do not require the opt-in flag.
> The cached initial state and accepted updates are distinct from `GetDesc`'s
> creation request and are not an OS-state query. In particular, the
> [compatibility grouped-queue omission](execution.md#queue-creation-priority)
> does not establish that a requested creation priority was applied.

<!-- d3d12-review-alert:end:command-queues:QA-050:0 -->

<!-- d3d12-review-alert:begin:command-queues:QA-R01:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The cached baseline is `D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_NORMAL` and
> `D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_DEFAULT`. Successful creation-time
> priority application updates the cache using the
> [creation mapping](execution.md#dynamic-queue-priority); accepted setters
> update the corresponding setting. On the compatibility grouped path that
> omits creation-priority application, the baseline values are the initial
> getter settings, not the queue's ignored creation-priority request.

<!-- d3d12-review-alert:end:command-queues:QA-R01:0 -->

<a id="id3d12commandqueue1-setprocesspriority"></a>

## ID3D12CommandQueue1::SetProcessPriority

### Declaration

```cpp
HRESULT SetProcessPriority(D3D12_COMMAND_QUEUE_PROCESS_PRIORITY Priority);
```

### Behavior

Requires a queue created with `D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY`.

<ins><!-- d3d12-review-inline:begin:command-queues:QA-053:0 -->Sets a `Priority` for this queue for the current process. On `S_OK`, the priority is applied immediately. All the work scheduled with calls to `ID3D12CommandQueue::ExecuteCommandLists` that is still pending execution before the call to `SetProcessPriority` is executed with the new priority set. All the new work submitted with `ID3D12CommandQueue::ExecuteCommandLists` after the call to `SetProcessPriority` also is executed with the new priority.<!-- d3d12-review-inline:end:command-queues:QA-053:0 --></ins>

<!-- d3d12-review-alert:begin:command-queues:QA-054:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The shared [context-owner/group and ignored-request rules](#dynamic-priority-values)
> apply. This operation changes priority; it does not submit command lists or
> establish completion of already submitted work.

<!-- d3d12-review-alert:end:command-queues:QA-054:0 -->

### Parameters

<!-- d3d12-review-alert:begin:command-queues:QA-055:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `Priority` is one of the two declared `D3D12_COMMAND_QUEUE_PROCESS_PRIORITY`
> values. It is not a `D3D12_COMMAND_QUEUE_PRIORITY` creation value or an
> arbitrary OS priority integer.

<!-- d3d12-review-alert:end:command-queues:QA-055:0 -->

### Return values

<!-- d3d12-review-alert:begin:command-queues:QA-056:0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | HRESULT | Meaning |
> |---|---|
> | `S_OK` | The priority was set correctly |
> | `S_FALSE` | The priority request for this adapter couldn't be applied and the request was ignored |
> | `E_INVALIDARG` | Invalid parameter |
> | `DXGI_ERROR_UNSUPPORTED` | `D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY` not present in this queue |
> | `E_ACCESSDENIED` | Not enough permissions to set this priority |

<!-- d3d12-review-alert:end:command-queues:QA-056:0 -->

<!-- d3d12-review-alert:begin:command-queues:QA-057:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_FALSE` does not replace the prior cached getter setting.

<!-- d3d12-review-alert:end:command-queues:QA-057:0 -->

<ins><!-- d3d12-review-inline:begin:command-queues:QA-058:0 -->Elevation is required to configure some priorities.<!-- d3d12-review-inline:end:command-queues:QA-058:0 --></ins>

<a id="id3d12commandqueue1-getprocesspriority"></a>

## ID3D12CommandQueue1::GetProcessPriority

### Declaration

```cpp
HRESULT GetProcessPriority(D3D12_COMMAND_QUEUE_PROCESS_PRIORITY* pOutValue);
```

### Behavior

<!-- d3d12-review-alert:begin:command-queues:QA-060:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns the [cached process-priority setting](#dynamic-priority-values) for
> the queue's context owner. An ignored setter does not change that result.
> Calling a setter is not a prerequisite for obtaining the cached initial
> state.

<!-- d3d12-review-alert:end:command-queues:QA-060:0 -->

### Parameters

<!-- d3d12-review-alert:begin:command-queues:QA-061:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pOutValue` is a required writable pointer that receives the cached
> `D3D12_COMMAND_QUEUE_PROCESS_PRIORITY`.

<!-- d3d12-review-alert:end:command-queues:QA-061:0 -->

### Return values

<!-- d3d12-review-alert:begin:command-queues:QA-062:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns `S_OK` after writing the result. A null `pOutValue` returns `E_INVALIDARG`.

<!-- d3d12-review-alert:end:command-queues:QA-062:0 -->

<a id="id3d12commandqueue1-setglobalpriority"></a>

## ID3D12CommandQueue1::SetGlobalPriority

### Declaration

```cpp
HRESULT SetGlobalPriority(D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY Priority);
```

### Behavior

Requires a queue created with `D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY`.

<ins><!-- d3d12-review-inline:begin:command-queues:QA-065:0 -->Sets a global `Priority` for this queue. On `S_OK`, the priority is applied immediately. All the work scheduled with calls to `ID3D12CommandQueue::ExecuteCommandLists` that is still pending execution before the call to `SetGlobalPriority` is executed with the new priority set. All the new work submitted with `ID3D12CommandQueue::ExecuteCommandLists` after the call to `SetGlobalPriority` also is executed with the new priority.<!-- d3d12-review-inline:end:command-queues:QA-065:0 --></ins>

<!-- d3d12-review-alert:begin:command-queues:QA-066:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The shared [context-owner/group and ignored-request rules](#dynamic-priority-values)
> apply. This operation changes priority; it does not submit command lists or
> establish completion of already submitted work.

<!-- d3d12-review-alert:end:command-queues:QA-066:0 -->

### Parameters

<!-- d3d12-review-alert:begin:command-queues:QA-067:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `Priority` is a declared `D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY` value.
> Unnamed integers, including numeric gaps between declared values, are invalid.
> These D3D12 enum values are not OS priority encodings.

<!-- d3d12-review-alert:end:command-queues:QA-067:0 -->

### Return values

<!-- d3d12-review-alert:begin:command-queues:QA-068:0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | HRESULT | Meaning |
> |---|---|
> | `S_OK` | The priority was set correctly |
> | `S_FALSE` | The priority request for this adapter couldn't be applied and the request was ignored |
> | `E_INVALIDARG` | Invalid parameter |
> | `DXGI_ERROR_UNSUPPORTED` | `D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY` not present in this queue |
> | `E_ACCESSDENIED` | Not enough permissions to set this priority |

<!-- d3d12-review-alert:end:command-queues:QA-068:0 -->

<!-- d3d12-review-alert:begin:command-queues:QA-069:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_FALSE` does not replace the prior cached getter setting.

<!-- d3d12-review-alert:end:command-queues:QA-069:0 -->

<ins><!-- d3d12-review-inline:begin:command-queues:QA-070:0 -->Elevation is required to configure some priorities.<!-- d3d12-review-inline:end:command-queues:QA-070:0 --></ins>

<a id="id3d12commandqueue1-getglobalpriority"></a>

## ID3D12CommandQueue1::GetGlobalPriority

### Declaration

```cpp
HRESULT GetGlobalPriority(D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY* pOutValue);
```

### Behavior

<!-- d3d12-review-alert:begin:command-queues:QA-072:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns the [cached global-priority setting](#dynamic-priority-values) for
> the queue's context owner. An ignored setter does not change that result.
> Calling a setter is not a prerequisite for obtaining the cached initial
> state.

<!-- d3d12-review-alert:end:command-queues:QA-072:0 -->

### Parameters

<!-- d3d12-review-alert:begin:command-queues:QA-073:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pOutValue` is a required writable pointer that receives the cached
> `D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY`.

<!-- d3d12-review-alert:end:command-queues:QA-073:0 -->

### Return values

<!-- d3d12-review-alert:begin:command-queues:QA-074:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns `S_OK` after writing the result. A null `pOutValue` returns `E_INVALIDARG`.

<!-- d3d12-review-alert:end:command-queues:QA-074:0 -->
