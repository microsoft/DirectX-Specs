# Command recording and execution

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

**Coverage: source-preserving draft.** This chapter assembles selected recording, submission, completion, lifetime, and threading text. It does not yet cover every execution contract.

<a id="execution-objects"></a>

## Command lists and queues

<ins><!-- d3d12-review-inline:begin:execution:P01:0 -->To render, applications can
create a *command list* off of the device, on which traditional
rendering APIs can be called. Each individual command list is
not free-threaded, but multiple command lists *can* be recorded
concurrently (which enables multi-threading).<!-- d3d12-review-inline:end:execution:P01:0 --></ins>

### Bundles

<ins><!-- d3d12-review-inline:begin:execution:P02:0 -->Bundles are a 'second level' of command lists. The purpose of Bundles is to allow apps to
group a small number of API commands together for later execution. At
Bundle creation time, the driver will perform as much pre-processing as
is possible to make these cheap to execute later. Command lists, on the
other hand, are typically executed only a single time (to enable
multi-threaded command buffer recording). However, a command list can be
executed multiple times (as long as the application ensures that the
previous executions have completed before submitting new executions).<!-- d3d12-review-inline:end:execution:P02:0 --></ins>

<a id="command-list-types"></a>

### Queue types

Command queues can be created by calling [`ID3D12Device::CreateCommandQueue`](command-queues.md#id3d12device-createcommandqueue). <ins><!-- d3d12-review-inline:begin:execution:P03:0:modified:migration-25b4015aefa73cf9-0 -->The `Type` field of `D3D12_COMMAND_QUEUE_DESC` is a<!-- d3d12-review-inline:end:execution:P03:0:modified:migration-25b4015aefa73cf9-0 --></ins> [`D3D12_COMMAND_LIST_TYPE`](#command-list-types) indicating what type of queue should be created, and therefore, what type of commands can be submitted to that queue. Remember that bundles can only be called from direct command lists and can't be submitted directly to a queue. The supported queue types are:

- [`D3D12_COMMAND_LIST_TYPE_DIRECT`](#command-list-types)
- [`D3D12_COMMAND_LIST_TYPE_COMPUTE`](#command-list-types)
- [`D3D12_COMMAND_LIST_TYPE_COPY`](#command-list-types)
- <ins><!-- d3d12-review-inline:begin:execution:P03:1 -->[`D3D12_COMMAND_LIST_TYPE_VIDEO_DECODE`](#command-list-types)<!-- d3d12-review-inline:end:execution:P03:1 --></ins>
- <ins><!-- d3d12-review-inline:begin:execution:P03:1 -->[`D3D12_COMMAND_LIST_TYPE_VIDEO_PROCESS`](#command-list-types)<!-- d3d12-review-inline:end:execution:P03:1 --></ins>
- <ins><!-- d3d12-review-inline:begin:execution:P03:1 -->[`D3D12_COMMAND_LIST_TYPE_VIDEO_ENCODE`](#command-list-types)<!-- d3d12-review-inline:end:execution:P03:1 --></ins>
- <ins><!-- d3d12-review-inline:begin:execution:P03:1 -->[`D3D12_COMMAND_LIST_TYPE_NONE`](#synchronization-only-queues)<!-- d3d12-review-inline:end:execution:P03:1 --></ins>

In general, DIRECT queues and command lists accept <ins><!-- d3d12-review-inline:begin:execution:P03:2:modified:source-7d6789ef7d350142-0-0 -->graphics, compute, and copy commands<!-- d3d12-review-inline:end:execution:P03:2:modified:source-7d6789ef7d350142-0-0 --></ins>, COMPUTE queues and command lists accept compute and copy related commands, and COPY queues and command lists accept only copy commands.

<ins><!-- d3d12-review-inline:begin:execution:D157-video-recording-reference:0:authored:migration-39684a1d022f18e2-0 -->Video decode recording, lifecycle, ordering and lifetime are defined in [Video](video.md#video-recording-lifetime), using the common queue/submission and completion contracts.<!-- d3d12-review-inline:end:execution:D157-video-recording-reference:0:authored:migration-39684a1d022f18e2-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:D158-processing-execution-forward:0:authored:migration-5f292714f2e24377-0 -->The distinct video process list/queue and processor route is defined in [Video processing](video.md#video-processing-model), using the common creation, submission, threading and completion contracts.<!-- d3d12-review-inline:end:execution:D158-processing-execution-forward:0:authored:migration-5f292714f2e24377-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:D160-encode-execution-forward:0:authored:migration-eff0633401ddb137-0 -->The VIDEO_ENCODE [base list lifecycle and motion operations](video-motion-estimation.md#motion-recording) use these common creation, allocator storage, threading, submission and completion contracts. The motion estimator's [cross-queue exclusion rule](video-motion-estimation.md#motion-driver-objects) is an additional object-specific requirement, not decoder recording serialization.<!-- d3d12-review-inline:end:execution:D160-encode-execution-forward:0:authored:migration-eff0633401ddb137-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:D161-extension-execution-forward:0:authored:migration-897e9b17966a2905-0 -->Video [GPU extension initialization/execution](video-extension-commands.md#extension-recording) records into the selected compatible video list and follows these common submission/storage/lifetime contracts. The distinct [device extension method](video-extension-commands.md#videodevice2-executeextensioncommand) has a published completion-before-return contract. Its parameter stages are not GPU execution stages.<!-- d3d12-review-inline:end:execution:D161-extension-execution-forward:0:authored:migration-897e9b17966a2905-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:D162-encoding-execution-forward:0:authored:migration-d5e22f4b9539e6de-0 -->Encoding's [object and recording contract](video-encoding.md#encoding-recording) includes encoder/heap serialization and recorded execution order, creation description copies distinct from GPU storage, caller-owned COM references without assumed recording AddRef, and lifetime through unsubmitted recordings that will execute and completion of submitted uses. Reconfiguration does not mutate immutable creation properties or supply codec header/DPB policy.<!-- d3d12-review-inline:end:execution:D162-encoding-execution-forward:0:authored:migration-d5e22f4b9539e6de-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:D151-meta-command-reference:0:authored:migration-ece133d2de408c95-0 -->Meta command discovery, resource parameter layouts and initialization/execution are defined in the subordinate [Meta commands reference](meta-commands.md).<!-- d3d12-review-inline:end:execution:D151-meta-command-reference:0:authored:migration-ece133d2de408c95-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QF-queue-api-reference:0:authored:migration-8476c98cd5a09ff9-0 -->The [command queue chapter](command-queues.md) defines creation,
creator IDs, the returned description and the four dynamic priority methods.<!-- d3d12-review-inline:end:execution:QF-queue-api-reference:0:authored:migration-8476c98cd5a09ff9-0 --></ins>

<a id="synchronization-only-queues"></a>

### Synchronization-only queues

<ins><!-- d3d12-review-inline:begin:execution:QF-N01:0:authored:migration-393ececc3ba816c8-0 -->`D3D12_COMMAND_LIST_TYPE_NONE` selects a runtime-managed synchronization-only
queue. It supports queued fence Signal/Wait operations, but cannot execute
command lists or perform queue tile mapping operations. This queue type does
not make `NONE` a valid type for command list or command allocator creation.<!-- d3d12-review-inline:end:execution:QF-N01:0:authored:migration-393ececc3ba816c8-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QF-N02:0:authored:migration-48096954e8c0b046-0 -->Its Signal/Wait operations retain queue timeline ordering. They are not
immediate CPU fence updates or a requirement for the calling CPU thread to
wait for the fence threshold. The runtime manages its synchronization
transport without a UMD command queue object. The UMD queue DDI transport
rules do not imply that these operations invoke those DDIs.<!-- d3d12-review-inline:end:execution:QF-N02:0:authored:migration-48096954e8c0b046-0 --></ins>

<a id="queue-creation-priority"></a>

### Creation priority for grouped queues

<ins><!-- d3d12-review-inline:begin:execution:QF-P01:0:authored:migration-e8749727f4730cd7-0 -->Hardware scheduling may associate DIRECT and COMPUTE queues with a scheduling
group. For grouped queues created without
`D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY`,
`D3D12_COMMAND_QUEUE_DESC.Priority` does not
cause the runtime to set the corresponding kernel context scheduling priority.
This compatibility behavior does not waive validation of the requested
priority, global realtime privileges or the applicable support requirements.<!-- d3d12-review-inline:end:execution:QF-P01:0:authored:migration-e8749727f4730cd7-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QF-P02:0:authored:migration-8216d2301ffd6dbf-0 -->`ID3D12CommandQueue::GetDesc` reports the queue's stored creation priority,
not its current kernel scheduling priority. For a grouped queue created
without `D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY`, successful
creation or that returned priority value does not establish that the requested
priority was applied to the kernel scheduling context.<!-- d3d12-review-inline:end:execution:QF-P02:0:authored:migration-8216d2301ffd6dbf-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QF-P03:0:authored:migration-84375f967aef6b38-0 -->Where the negotiated queue creation DDI carries `QueueCreationFlags` and
UMD-based global realtime priority is supported for the queue's workload,
the runtime must still set
`D3D12DDI_COMMAND_QUEUE_CREATION_FLAG_GLOBAL_REALTIME_PRIORITY` for a
`D3D12_COMMAND_QUEUE_PRIORITY_GLOBAL_REALTIME` request, including for a grouped
queue. Omitting kernel priority setting must not suppress this UMD request.
Passing the flag does not mean that the runtime set the group's kernel
scheduling priority.<!-- d3d12-review-inline:end:execution:QF-P03:0:authored:migration-84375f967aef6b38-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QF-P04:0:authored:migration-e87dd6a15a41f40e-0 -->**History.** The compatibility path's omission of kernel priority setting originated
as a bug. Correcting it caused application compatibility regressions, so the
prior behavior was restored and is retained for compatibility.<!-- d3d12-review-inline:end:execution:QF-P04:0:authored:migration-e87dd6a15a41f40e-0 --></ins>

<a id="dynamic-queue-priority"></a>

### Dynamic queue priority

<ins><!-- d3d12-review-inline:begin:execution:QF-D01:0:authored:migration-9123eaf417499eea-0 -->`D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY` opts a queue into dynamic
priority setting. An adjustment through an opt-in queue applies to the
scheduling group that contains it, including the other queues in that group.
Opt-in queues are not grouped with queues that lack this flag.<!-- d3d12-review-inline:end:execution:QF-D01:0:authored:migration-9123eaf417499eea-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QF-D02:0:authored:migration-3e6c392dffa116ee-0 -->Creating an opt-in queue that joins an existing group overrides that group's
process and global priority settings according to the new queue's creation
priority. The creation priority is not merely inherited from the existing
group, and no separate setter call is required to request the override.<!-- d3d12-review-inline:end:execution:QF-D02:0:authored:migration-3e6c392dffa116ee-0 --></ins>

| `D3D12_COMMAND_QUEUE_PRIORITY` | `D3D12_COMMAND_QUEUE_PROCESS_PRIORITY` | `D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY` |
| -------- | -------- | -------- |
| `D3D12_COMMAND_QUEUE_PRIORITY_GLOBAL_REALTIME` | `D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_HIGH` | `D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_HARD_REALTIME` |
| `D3D12_COMMAND_QUEUE_PRIORITY_HIGH` | `D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_HIGH` | `D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_DEFAULT` |
| `D3D12_COMMAND_QUEUE_PRIORITY_NORMAL` | `D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_NORMAL` | `D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_DEFAULT` |

<ins><!-- d3d12-review-inline:begin:execution:QF-D04:0:authored:migration-e6cbed6187538608-0 -->An ignored request to `ID3D12CommandQueue1::SetProcessPriority` or
`SetGlobalPriority` returns `S_FALSE`, not `S_OK`. It does not replace the
prior cached setting returned by the corresponding getter. The getters
report runtime-maintained priority state, not an independent readback of
the current OS scheduling state. `GetDesc` continues to report the stored
creation description rather than these mutable settings.<!-- d3d12-review-inline:end:execution:QF-D04:0:authored:migration-e6cbed6187538608-0 --></ins>

<a id="hardware-scheduling-queue-groupings"></a>

### Hardware-scheduling grouping query

<ins><!-- d3d12-review-inline:begin:execution:QF-D05:0:authored:migration-b3ae88c020faa824-0 -->`ID3D12Device::CheckFeatureSupport` accepts
`D3D12_FEATURE_HARDWARE_SCHEDULING_QUEUE_GROUPINGS` (selector value `60`)
with a `D3D12_FEATURE_DATA_HARDWARE_SCHEDULING_QUEUE_GROUPINGS` payload and
its exact `sizeof` as the data size. The payload has no input fields.<!-- d3d12-review-inline:end:execution:QF-D05:0:authored:migration-b3ae88c020faa824-0 --></ins>

```cpp
typedef struct D3D12_FEATURE_DATA_HARDWARE_SCHEDULING_QUEUE_GROUPINGS
{
    UINT ComputeQueuesPer3DQueue;
} D3D12_FEATURE_DATA_HARDWARE_SCHEDULING_QUEUE_GROUPINGS;
```

<ins><!-- d3d12-review-inline:begin:execution:QF-D07:0:authored:migration-aea002e7c324772a-0 -->`ComputeQueuesPer3DQueue`<!-- d3d12-review-inline:end:execution:QF-D07:0:authored:migration-aea002e7c324772a-0 --></ins>

When reported as greater than zero, indicates the maximum number of `COMPUTE` command queues (with the same `CreatorID`) <ins><!-- d3d12-review-inline:begin:execution:QF-D08:0:authored:source-f18203cbb72807f4-0-0 -->that <!-- d3d12-review-inline:end:execution:QF-D08:0:authored:source-f18203cbb72807f4-0-0 --></ins>can be grouped together with a `DIRECT` queue in the same scheduling group.

When reported as zero, means that scheduling groups do not group more than one queue.

<a id="recording-lifecycle"></a>

## Recording lifecycle

<a id="create-command-allocator"></a>

### ID3D12Device::CreateCommandAllocator

#### Declaration

```cpp
HRESULT CreateCommandAllocator(
    D3D12_COMMAND_LIST_TYPE type,
    REFIID riid,
    void** ppCommandAllocator
);
```

#### Behavior

Creates a command allocator object.

<ins><!-- d3d12-review-inline:begin:execution:D189-003:0:authored:migration-faa013d57df04ee0-0 -->The allocator supplies storage for recordings of the selected command list
type; creation does not begin a command list recording. The same allocator
may store several recordings, but only one command list may be recording to
it at a time. [Allocator storage and reuse](#command-storage), the
[Reset preconditions](#allocator-reset) and [CPU threading](#threading)
apply to this object.<!-- d3d12-review-inline:end:execution:D189-003:0:authored:migration-faa013d57df04ee0-0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:execution:D189-004:0:authored:migration-c0f8b328fbf2d39d-0 -->`type` specifies the command list type for the allocator: DIRECT, BUNDLE,
COMPUTE, COPY, VIDEO_DECODE, VIDEO_PROCESS or VIDEO_ENCODE. The type must be
supported by the device. Video types require the corresponding video support.
The allocator type must match the type of the command list that records to it.<!-- d3d12-review-inline:end:execution:D189-004:0:authored:migration-c0f8b328fbf2d39d-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:D189-005:0:authored:migration-dc5b1984805cd8f7-0 -->`riid` identifies the requested interface on the command allocator, normally
`ID3D12CommandAllocator`.<!-- d3d12-review-inline:end:execution:D189-005:0:authored:migration-dc5b1984805cd8f7-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:D189-006:0:authored:migration-85e59bbd80a66897-0 -->`ppCommandAllocator` is a required output pointer that receives the requested
interface on the created allocator.<!-- d3d12-review-inline:end:execution:D189-006:0:authored:migration-85e59bbd80a66897-0 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:execution:D189-007:0:authored:migration-36d8692974215fac-0 -->Successful object creation returns `S_OK`. An invalid or unsupported
command list type returns `E_INVALIDARG`.<!-- d3d12-review-inline:end:execution:D189-007:0:authored:migration-36d8692974215fac-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:D189-008:0:modified:migration-e24c1c365e3cf428-0 -->This method returns `E_OUTOFMEMORY` if there is insufficient memory to create the command allocator.<!-- d3d12-review-inline:end:execution:D189-008:0:modified:migration-e24c1c365e3cf428-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:D189-009:0:authored:migration-273029650cb97f59-0 -->Other creation/interface failures are reported through the returned `HRESULT`.<!-- d3d12-review-inline:end:execution:D189-009:0:authored:migration-273029650cb97f59-0 --></ins>

<a id="command-list-get-type"></a>

### ID3D12CommandList::GetType

#### Declaration

```cpp
D3D12_COMMAND_LIST_TYPE GetType();
```

#### Behavior

Gets the type of the command list, such as direct, bundle, compute, or copy.

#### Return values

<ins><!-- d3d12-review-inline:begin:execution:D189-012:0:modified:migration-6d3c35ca91123555-0 -->This method returns the type of the command list,
as a `D3D12_COMMAND_LIST_TYPE` enumeration constant,
such as direct, bundle, compute, or copy.<!-- d3d12-review-inline:end:execution:D189-012:0:modified:migration-6d3c35ca91123555-0 --></ins>

<a id="creation"></a>

### ID3D12Device::CreateCommandList

#### Declaration

```cpp
HRESULT CreateCommandList(
    UINT nodeMask,
    D3D12_COMMAND_LIST_TYPE type,
    ID3D12CommandAllocator* pCommandAllocator,
    ID3D12PipelineState* pInitialState,
    REFIID riid,
    void** ppCommandList
);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:execution:P04:0 -->This API creates a command list or a bundle. The command list starts out
in the "recording" state.<!-- d3d12-review-inline:end:execution:P04:0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:P05:0 -->This API also takes a command allocator as input. A given allocator can
be associated no more than 1 recording command list at a time. The
allocator type must match the type of command
list which is being created.<!-- d3d12-review-inline:end:execution:P05:0 --></ins>

### ID3D12Device4::CreateCommandList1

#### Declaration

```cpp
HRESULT CreateCommandList1(
    UINT nodeMask,
    D3D12_COMMAND_LIST_TYPE type,
    D3D12_COMMAND_LIST_FLAGS flags,
    REFIID riid,
    void** ppCommandList
);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:execution:creation1-behavior:0 -->`CreateCommandList1` creates a command list in the closed state. Also see [ID3D12Device::CreateCommandList](#creation).<!-- d3d12-review-inline:end:execution:creation1-behavior:0 --></ins>

<a id="lifecycle"></a>

## Closing and reusing command lists

<ins><!-- d3d12-review-inline:begin:execution:A04:0:authored:migration-8c5f0a9bd7402940-0 -->This section covers DIRECT, COMPUTE, COPY, and BUNDLE recordings made through `ID3D12GraphicsCommandList`, and the corresponding `ID3D12CommandAllocator` objects. The three methods below belong to the baseline D3D12 interfaces. They do not require an optional feature query. Calls on the same command list or allocator object must obey the [CPU threading requirements](#threading).<!-- d3d12-review-inline:end:execution:A04:0:authored:migration-8c5f0a9bd7402940-0 --></ins>

<a id="command-storage"></a>

### Recorded commands and allocator storage

You can record multiple lists to the same allocator before it is reset, provided only one list is recording to a given allocator at one time. You can visualise each list as owning a portion of the allocator which indicates what [`ID3D12CommandQueue::ExecuteCommandLists`](#execute-command-lists) will execute.

<ins><!-- d3d12-review-inline:begin:execution:A01:0:authored:migration-1bd80dbd4ff53d3c-0 -->Resetting a command list object does not reset command allocator storage. After resetting and re-recording a command list object, the new recorded command stream may be submitted while an older stream recorded through the same object executes, provided that allocator storage and referenced resources remain valid for both streams. An unchanged recorded command stream must not be resubmitted while an earlier execution of that stream is still in progress.<!-- d3d12-review-inline:end:execution:A01:0:authored:migration-1bd80dbd4ff53d3c-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:A05:0:authored:migration-b28c4a6c11c37a60-0 -->`ExecuteBundle` records an execution of the bundle recording selected at that call. Resetting and re-recording the bundle object later does not replace the commands already selected by an earlier `ExecuteBundle` in a parent recording. The application may begin a new bundle recording with the same allocator without resetting that allocator, or use another compatible allocator.<!-- d3d12-review-inline:end:execution:A05:0:authored:migration-b28c4a6c11c37a60-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:A05:1:authored:migration-81b26cfa550eab30-0 -->The allocator storage backing the earlier recording must remain valid for every parent recording that will execute it. Resetting the allocator invalidates the recordings stored there, including bundle recordings already referenced by unsubmitted parents. The application must finish all GPU uses before reclaiming that storage and must not subsequently submit or resubmit an invalidated recording. An unsubmitted parent may instead be discarded without executing it.<!-- d3d12-review-inline:end:execution:A05:1:authored:migration-81b26cfa550eab30-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:A05:2:authored:migration-769efd40dcecaa43-0 -->Selecting a recorded command stream does not snapshot the contents of resources that its commands access, or remove their lifetime, residency, descriptor, and synchronization requirements. Neither closing a list nor resetting a list object or allocator provides proof of GPU completion.<!-- d3d12-review-inline:end:execution:A05:2:authored:migration-769efd40dcecaa43-0 --></ins>

Use a fence to determine when a given allocator is able to be reused.

<a id="close"></a>

### ID3D12GraphicsCommandList::Close

#### Declaration

```cpp
HRESULT Close();
```

#### Behavior

This API is called to indicate that recording to a command list has
finished.

<ins><!-- d3d12-review-inline:begin:execution:A06:0:authored:migration-09889e4f00e853d5-0 -->`Close` ends CPU recording. It does not submit the recorded commands to a queue or wait for GPU execution. Queries begun in the command list must be ended before it is closed. An active render pass must also be ended before closing the list. These unmatched query/render pass cases record an `E_FAIL` error against the list.<!-- d3d12-review-inline:end:execution:A06:0:authored:migration-09889e4f00e853d5-0 --></ins>

#### Return values

Returns `S_OK` if successful; otherwise, returns one of the following values:

- `E_INVALIDARG`: An invalid argument was passed to the command list API
  during recording

- <ins><!-- d3d12-review-inline:begin:execution:P07-errors:0 -->`E_FAIL`: The command list has already been closed, an invalid API was<!-- d3d12-review-inline:end:execution:P07-errors:0 --></ins>
  called during command list recording, or a query or render pass is still open

- <ins><!-- d3d12-review-inline:begin:execution:P07-errors:0 -->`E_OUTOFMEMORY`: The system ran out of memory during recording or closing<!-- d3d12-review-inline:end:execution:P07-errors:0 --></ins>

- <ins><!-- d3d12-review-inline:begin:execution:A09:0:authored:migration-9a6bd1d547972f8a-0 -->`DXGI_ERROR_DEVICE_REMOVED`: A device-removing driver error was stored as the command list error.<!-- d3d12-review-inline:end:execution:A09:0:authored:migration-9a6bd1d547972f8a-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:A09:1:authored:migration-c4c651320dbffee9-0 -->For a driver-reported device removal failure, the application can query [ID3D12Device::GetDeviceRemovedReason](diagnostics.md#id3d12device-getdeviceremovedreason) for the device's removal reason.<!-- d3d12-review-inline:end:execution:A09:1:authored:migration-c4c651320dbffee9-0 --></ins>

#### Runtime validation

The runtime will validate that the command list has not previously been
closed. If an error was encountered during recording, the error code is
returned here. The runtime will not call the close DDI in this case.

#### Debug layer

<ins><!-- d3d12-review-inline:begin:execution:P07-debug:0 -->Validation failures can generate debug layer errors. A failed `Close`, including a driver-reported failure, does not necessarily produce a corresponding debug layer message.<!-- d3d12-review-inline:end:execution:P07-debug:0 --></ins>

<a id="list-reset"></a>

### ID3D12GraphicsCommandList::Reset

#### Declaration

```cpp
HRESULT Reset(
    ID3D12CommandAllocator* pAllocator,
    ID3D12PipelineState* pInitialState
);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:execution:P08-behavior:0 -->This API is called to reset a command list back to its initial state (as
if a new command list was just created). This enables command list
tracking structures to be re-used.<!-- d3d12-review-inline:end:execution:P08-behavior:0 --></ins>

After `Reset` succeeds, the command list is left in the "recording" state.

Applications <ins><!-- d3d12-review-inline:begin:execution:P08-permission:0:modified:migration-4dc9ff72906a0b90-0 -->**are allowed**<!-- d3d12-review-inline:end:execution:P08-permission:0:modified:migration-4dc9ff72906a0b90-0 --></ins> to call this method before the
GPU has finished all previous executions of the command list (unlike
`ID3D12CommandAllocator::Reset`).

This method works for both command lists and bundles.

#### Parameters

**pAllocator**

A pointer to the [`ID3D12CommandAllocator`](#command-storage) object that the device creates command lists from.

This API also takes a command allocator as input. A given allocator can
be associated with no more than 1 recording command list at a time. The
allocator type <ins><!-- d3d12-review-inline:begin:execution:P08-allocator:0:modified:source-70ada0efb8230b25-0-0 -->must match the type of command
list<!-- d3d12-review-inline:end:execution:P08-allocator:0:modified:source-70ada0efb8230b25-0-0 --></ins> that is being <ins><!-- d3d12-review-inline:begin:execution:P08-allocator:0:modified:source-70ada0efb8230b25-0-1 -->reset<!-- d3d12-review-inline:end:execution:P08-allocator:0:modified:source-70ada0efb8230b25-0-1 --></ins>.

**pInitialState**

<ins><!-- d3d12-review-inline:begin:execution:P35-initial-state:1 -->A pointer to the [`ID3D12PipelineState`](pipeline-state.md#ordinary-pipeline-state) object that contains the initial pipeline state for the command list. This is optional and can be NULL. If NULL, the runtime sets a dummy initial pipeline state so that drivers don't have to deal with undefined state.<!-- d3d12-review-inline:end:execution:P35-initial-state:1 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:A08:0:authored:migration-5670f1ea6706bd3e-0 -->On a direct, compute, or bundle command list that uses graphics or compute pipeline state, `pInitialState` supplies the initial pipeline state. If it is NULL, the runtime selects its default graphics state for direct lists and bundles, or its default compute state for compute lists. This default does not supply an application shader program. The application must establish the pipeline state required by a draw or dispatch. Copy command lists have no pipeline state and do not use `pInitialState`.<!-- d3d12-review-inline:end:execution:A08:0:authored:migration-5670f1ea6706bd3e-0 --></ins>

<a id="reset-initial-state"></a>

#### Initial recording state

<ins><!-- d3d12-review-inline:begin:execution:A07:0:authored:migration-421af0376f7a96ba-0 -->Creation/Reset values and bundle entry/exit behavior are defined in [Command list state initialization](command-list-state.md#state-index). This includes the depth bounds, sample position, view mask, VRS, dynamic-PSO, protection, and recording context contributions.<!-- d3d12-review-inline:end:execution:A07:0:authored:migration-421af0376f7a96ba-0 --></ins>

#### Return values

Returns `S_OK` if successful; otherwise, returns one of the following values:

- `E_FAIL`: The command list was not in the "closed" state when the call
  was made.

- `E_INVALIDARG`: The allocator is currently being used with another
  command list in the "recording" state

- `E_INVALIDARG`: The specified allocator was created with the wrong type

- `E_OUTOFMEMORY`: The system ran out of memory

<ins><!-- d3d12-review-inline:begin:execution:A03:0:authored:migration-20031501d1e8aab9-0 -->For a closed command list with a recorded error, `Reset` returns that recorded error. See [Runtime validation](#list-reset-validation) and [Deferred recording errors](#lifecycle-driver-errors).<!-- d3d12-review-inline:end:execution:A03:0:authored:migration-20031501d1e8aab9-0 --></ins>

<a id="list-reset-validation"></a>

#### Runtime validation

<ins><!-- d3d12-review-inline:begin:execution:P09:0 -->Before calling `Reset`, the command list must be in the "closed" state.
The API call will fail if this is not the case. Note that if an error has been recorded against the command list when
`ID3D12GraphicsCommandList::Close` returns, then that command list can never be
reset. Calling `ID3D12GraphicsCommandList::Reset` will result in the recorded error
being returned.<!-- d3d12-review-inline:end:execution:P09:0 --></ins>

Applications must specify a command list allocator. The runtime will
ensure that an allocator is never associated with more than one
recording command list at the same time.

<ins><!-- d3d12-review-inline:begin:execution:A02:0:authored:migration-d07cfce80ea2b84e-0 -->Calling `Close` on a command list that is already closed returns `E_FAIL` but does not, by itself, prevent a subsequent `Reset`.<!-- d3d12-review-inline:end:execution:A02:0:authored:migration-d07cfce80ea2b84e-0 --></ins>

<a id="allocator-reset"></a>

### ID3D12CommandAllocator::Reset

#### Declaration

```cpp
HRESULT Reset();
```

#### Behavior

Your app calls `Reset` to re-use the memory that is associated with a command allocator. From this call to `Reset`, the runtime and driver assume that the graphics processing unit (GPU) is no longer executing any command lists that have recorded commands with the command allocator. So you should ensure that you don't call `Reset` until the GPU is done executing command lists associated with the allocator.

It's undefined behavior to call **Reset** on a command allocator while it has a command list still being executed.

#### Return values

<ins><!-- d3d12-review-inline:begin:execution:A10:0:authored:migration-0135b082f3aab547-0 -->Returns `S_OK` on success. The active-recording failure is described below. Callers must check the returned HRESULT. Success is not proof of GPU completion.<!-- d3d12-review-inline:end:execution:A10:0:authored:migration-0135b082f3aab547-0 --></ins>

This method returns `E_FAIL` if there is an actively recording command list referencing the command allocator. The debug layer will also issue an error in this case. See [Direct3D 12 Return Codes](devices-and-capabilities.md#api-result-codes) for other possible return values.

#### Debug layer

The debug layer will issue <ins><!-- d3d12-review-inline:begin:execution:P12-debug:0:modified:source-ae4302862c6c4b6b-0-0 -->an error<!-- d3d12-review-inline:end:execution:P12-debug:0:modified:source-ae4302862c6c4b6b-0-0 --></ins> if it can't prove that there are no pending GPU references to command lists that have recorded commands in the allocator.

The debug layer will issue an error if `Reset` is called concurrently by multiple threads (on the same allocator object).

<a id="executebundle"></a>

### ID3D12GraphicsCommandList::ExecuteBundle

#### Declaration

```cpp
void ExecuteBundle(ID3D12GraphicsCommandList* pCommandList);
```

#### Behavior

Executes a bundle.

<ins><!-- d3d12-review-inline:begin:execution:EF-bundle-api-contract:0:authored:migration-e87ff5cd7e0a5ca3-0 -->`pCommandList` must identify a closed BUNDLE from the same device. The caller must be an open DIRECT recording. A bundle cannot execute another bundle. The bundle's device node selection must include the parent's execution node. Descriptor heaps explicitly set by the bundle must match the parent's corresponding heaps. Recording the call selects the bundle recording at that call, not a later re-recording of the same bundle object.<!-- d3d12-review-inline:end:execution:EF-bundle-api-contract:0:authored:migration-e87ff5cd7e0a5ca3-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:EF-bundle-api-contract:1:authored:migration-2efa30ac00f75acf-0 -->The [bundle entry/exit state contract](command-list-state.md#base-bundle-state), [root/descriptor inheritance](command-list-state.md#resource-binding) and [static descriptor/data promises](command-list-state.md#static-descriptors) remain canonical. A bundle does not inherit the parent's PSO or primitive topology. This wrapper is not predicated, but eligible work inside the bundle uses the inherited predicate under the [operation matrix](counters-queries-and-predication.md#predication-operation-matrix). Its state effects are not skipped with that work.<!-- d3d12-review-inline:end:execution:EF-bundle-api-contract:1:authored:migration-2efa30ac00f75acf-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:EF-bundle-api-contract:2:authored:migration-912d7ee2a6430376-0 -->The bundle's contents must satisfy the parent's [render pass admission and dependencies](output-merger.md#render-pass-operation-surface). The [recording generation and allocator storage rules](#command-storage), [object/resource lifetime](#lifetime), [residency](resources.md#residency) and [binding lifetime](binding.md#table-indexing-and-descriptor-lifetime) apply through all uses of the selected recording. Resetting/re-recording the bundle object does not retarget an earlier parent recording, and resetting its allocator does not make old references valid. This CPU recording call neither submits the parent to a queue nor waits for GPU completion.<!-- d3d12-review-inline:end:execution:EF-bundle-api-contract:2:authored:migration-912d7ee2a6430376-0 --></ins>

#### Parameters

##### pCommandList

<ins><!-- d3d12-review-inline:begin:execution:EF-bundle-parameter:0:modified:migration-0b77ba9dbed3670c-0 -->Specifies the [ID3D12GraphicsCommandList](#executebundle) that determines the bundle to be executed.<!-- d3d12-review-inline:end:execution:EF-bundle-parameter:0:modified:migration-0b77ba9dbed3670c-0 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:execution:EF-bundle-api-return:0:authored:migration-1dd397974a696d2b-0 -->This method returns no value. Recording failures are reported through the parent's [deferred Close result](#deferred-recording-errors), not a direct HRESULT returned by `ExecuteBundle`. The common first-recorded-error precedence remains applicable, including when a validation failure records `E_INVALIDARG`.<!-- d3d12-review-inline:end:execution:EF-bundle-api-return:0:authored:migration-1dd397974a696d2b-0 --></ins>

#### Runtime validation

The runtime will validate that the "callee" is a bundle and that the
"caller" is a direct command list. The runtime will also validate that
the bundle has been closed. If the contract is violated, the runtime
will silently drop the call.

Validation failure will result in <ins><!-- d3d12-review-inline:begin:execution:EF-bundle-close:0:modified:migration-bc40558d7b259830-0 -->[Close](#close)<!-- d3d12-review-inline:end:execution:EF-bundle-close:0:modified:migration-bc40558d7b259830-0 --></ins> returning E_INVALIDARG.

#### Debug layer

<ins><!-- d3d12-review-inline:begin:execution:EF-bundle-resource-debug:0:modified:source-44c32d13cde6376b-0-0 -->The<!-- d3d12-review-inline:end:execution:EF-bundle-resource-debug:0:modified:source-44c32d13cde6376b-0-0 --></ins> debug layer will issue an error if it detects that any resource <ins><!-- d3d12-review-inline:begin:execution:EF-bundle-resource-debug:0:modified:source-44c32d13cde6376b-1-0 -->referenced<!-- d3d12-review-inline:end:execution:EF-bundle-resource-debug:0:modified:source-44c32d13cde6376b-1-0 --></ins> by the command list has been destroyed.

The debug layer will also validate that the command allocator associated with the bundle has not been reset since <ins><!-- d3d12-review-inline:begin:execution:EF-bundle-allocator-debug:0:modified:migration-1907dd897784e580-0 -->[Close](#close)<!-- d3d12-review-inline:end:execution:EF-bundle-allocator-debug:0:modified:migration-1907dd897784e580-0 --></ins> was called on the command list.  This validation occurs at <ins><!-- d3d12-review-inline:begin:execution:EF-bundle-allocator-debug:0:modified:migration-e562f88b942ca44c-1 -->`ExecuteBundle`<!-- d3d12-review-inline:end:execution:EF-bundle-allocator-debug:0:modified:migration-e562f88b942ca44c-1 --></ins> time, and when the parent command list is executed on a command queue.

<a id="bundle-driver"></a>

#### PFND3D12DDI_EXECUTE_BUNDLE

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_EXECUTE_BUNDLE )(
    D3D12DDI_HCOMMANDLIST, D3D12DDI_HCOMMANDLIST );
```

<ins><!-- d3d12-review-inline:begin:execution:EF-bundle-driver-contract:0:authored:migration-860758548cfc7060-0 -->The first `D3D12DDI_HCOMMANDLIST` is the parent direct command list. The second is the closed bundle. Both `D3D12DDI_COMMAND_LIST_FUNCS_3D_0108::pfnExecuteBundle` and `D3D12DDI_COMMAND_LIST_FUNCS_3D_0114::pfnExecuteBundle` use this same signature and these ordinary driver handles. The API handle table does not change this entry into an API handle argument pair.<!-- d3d12-review-inline:end:execution:EF-bundle-driver-contract:0:authored:migration-860758548cfc7060-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:EF-bundle-driver-contract:1:authored:migration-39b83c4ac0464d2c-0 -->The UMD records execution of the selected bundle generation under the [ExecuteBundle contract](#executebundle). The ABI does not require either CPU expansion or one particular GPU indirection strategy. The driver must preserve the selected recording's meaning when the bundle object is later reset. This `VOID` DDI uses [recording error reporting](#lifecycle-driver-errors).<!-- d3d12-review-inline:end:execution:EF-bundle-driver-contract:1:authored:migration-39b83c4ac0464d2c-0 --></ins>

<a id="lifecycle-driver"></a>

### Driver responsibilities and error reporting

<ins><!-- d3d12-review-inline:begin:execution:A11:0:authored:migration-283a6002a66bac09-0 -->The driver must preserve previously recorded command streams and bundle references across a command list object Reset while their allocator storage remains valid. A driver may copy recorded commands or reference their storage, but resetting the bundle object must not retarget an existing parent recording to the bundle's new commands. Allocator reset, not list object reset, permits reclamation of the affected command storage under the application preconditions described above.<!-- d3d12-review-inline:end:execution:A11:0:authored:migration-283a6002a66bac09-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:A13:0:authored:migration-33404920bc8a90d8-0 -->The `_0040` reset arguments identify a recorder associated with a command pool. Earlier arguments identify a command allocator. Neither carries the initial PSO, which the runtime supplies with state setting DDIs.<!-- d3d12-review-inline:end:execution:A13:0:authored:migration-33404920bc8a90d8-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:A13:1:authored:migration-189e9fefe71991a9-0 -->Close invokes the close-list DDI unless a recorded error prevents it. Allocator Reset invokes the pool/allocator storage reset DDI.<!-- d3d12-review-inline:end:execution:A13:1:authored:migration-189e9fefe71991a9-0 --></ins>

<a id="lifecycle-driver-errors"></a>

#### Deferred recording errors

```cpp
typedef VOID (APIENTRY CALLBACK *PFND3D12DDI_SETCOMMANDLISTERROR_CB)( D3D12DDI_HRTCOMMANDLIST, HRESULT );
```

<ins><!-- d3d12-review-inline:begin:execution:CS-recording-error-protection:0:authored:migration-08ad31ae95351332-0 -->SetCommandListErrorCb uses `D3D12DDI_HRTCOMMANDLIST`. The runtime translates and records the error under the [recording error contract](#lifecycle-driver-errors).<!-- d3d12-review-inline:end:execution:CS-recording-error-protection:0:authored:migration-08ad31ae95351332-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:P42:0 -->`SetCommandListErrorCb` is used for errors encountered while executing
command list recording DDIs. There are only 3 errors which drivers
should pass to this function:<!-- d3d12-review-inline:end:execution:P42:0 --></ins>

- `E_OUTOFMEMORY`
- `D3DDDIERR_DEVICEREMOVED`
- <ins><!-- d3d12-review-inline:begin:execution:P42:1 -->`D3DDDIERR_APPLICATIONERROR`<!-- d3d12-review-inline:end:execution:P42:1 --></ins>

After the `SetCommandListErrorCb` <ins><!-- d3d12-review-inline:begin:execution:WEF-recording-error-actor:0 -->runtime callback<!-- d3d12-review-inline:end:execution:WEF-recording-error-actor:0 --></ins> is called, the runtime will drop all
calls into the driver which record commands on the specified command
list.

<ins><!-- d3d12-review-inline:begin:execution:A12:0:authored:migration-6e47056a30e897b0-0 -->A successful command list Reset starts a new recording, but errors reported through the command list error callback while initializing that recording are stored for Close to report. Reset's HRESULT does not replace the requirement to check Close.<!-- d3d12-review-inline:end:execution:A12:0:authored:migration-6e47056a30e897b0-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:A12:1:authored:migration-36b60a52240c3524-0 -->Driver-reported errors are translated before the resulting command list error is stored. A driver-reported `E_OUTOFMEMORY` remains `E_OUTOFMEMORY` unless the device has already been removed. Driver-reported device removal or application error removes the device and is translated to `DXGI_ERROR_DEVICE_REMOVED`. The more specific device reason is available from [GetDeviceRemovedReason](diagnostics.md#id3d12device-getdeviceremovedreason). If an earlier command list error has already been recorded, it remains the error returned by Close and later Reset. Device removal does not replace that earlier stored error.<!-- d3d12-review-inline:end:execution:A12:1:authored:migration-36b60a52240c3524-0 --></ins>

<a id="driver-recording-objects"></a>

### Driver recording objects and storage

<a id="object-model"></a>

#### Objects and recording lifetime

<ins><!-- d3d12-review-inline:begin:execution:R002:0:authored:migration-50fe45430d46c7a0-0 -->The application command allocator supplies storage for recorded commands. An
application command list is the object through which commands are recorded.
At the driver interface using the `_0040` recording object protocol, a command
pool owns command storage, a command recorder supplies the CPU recording
machinery, and a driver command list identifies a command list object.
The older protocol combines the pool/recording storage role in a driver
command allocator.<!-- d3d12-review-inline:end:execution:R002:0:authored:migration-50fe45430d46c7a0-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:R003:0:authored:migration-39b7e29624018428-0 -->An application allocator permits at most one recording list at a time.
This API restriction is not a one-recorder-per-pool DDI restriction. Several
driver recorders may target the same pool and record concurrently. Each
recorder may be used for only one recording at a time. The driver must support
concurrent recording through distinct recorders sharing a pool. This does not
permit concurrent calls on the same command list object.<!-- d3d12-review-inline:end:execution:R003:0:authored:migration-39b7e29624018428-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:R004:0:authored:migration-00aa4b5f40af6e80-0 -->Reset associates a driver list's new recording with the supplied recorder.
Normal Close ends recording and releases that recorder's recording use.
The [failed-recording rules](#failed-recording) distinguish logical API
closure from delivery of the Close DDI. The recorder's use is a
recording lease, not allocation and destruction of a recorder for every
recording. Creation of an initially recording application list can require
both driver list creation and recording initialization. There is no requirement
that each such DDI call identify a different recording.<!-- d3d12-review-inline:end:execution:R004:0:authored:migration-00aa4b5f40af6e80-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:R005:0:authored:migration-eccc82fe8f7f5b9b-0 -->Recorded commands remain backed by their pool after Close. An idle recorder
may be reused, retargeted or destroyed while older recordings execute, provided
their pool storage remains valid. Reusing the recorder or resetting the
command list object does not reset that storage or prove GPU completion.
The [recorded stream and bundle-storage rules](execution.md#command-storage)
apply independently of recorder reuse.<!-- d3d12-review-inline:end:execution:R005:0:authored:migration-eccc82fe8f7f5b9b-0 --></ins>

<a id="recording-identifiers"></a>

##### Recording generation identifiers

<ins><!-- d3d12-review-inline:begin:execution:R006:0:authored:migration-b06ba4bf78cb6d86-0 -->The `UINT64 ID` in driver list creation and reset identifies a recording
generation, not the persistent application or driver command list object.
Valid IDs must be unique within the driver device, apart from eventual
64-bit wraparound. Zero and `UINT64_MAX` are reserved; `UINT64_MAX` denotes
no current recording, including initially closed creation.<!-- d3d12-review-inline:end:execution:R006:0:authored:migration-b06ba4bf78cb6d86-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:R007:0:authored:migration-19a33936eeb36382-0 -->Creation and an implicit reset that initialize the same recording may use
the same ID. A later recording established by application Reset receives
a new valid ID. The contract does not prescribe a counter, starting value,
ordering of IDs or uniqueness across distinct driver devices.<!-- d3d12-review-inline:end:execution:R007:0:authored:migration-19a33936eeb36382-0 --></ins>

<a id="target-and-reclamation"></a>

##### Targets, reset and destruction

<ins><!-- d3d12-review-inline:begin:execution:R008:0:authored:migration-63b8629db96a2016-0 -->The runtime may change a recorder's pool target only while that recorder is
idle. An idle recorder may retain a stale, non-owning target identity. It does
not keep the target pool alive. Before recording resumes, the runtime must
establish a valid target association. This is not a null handle unbinding
protocol.<!-- d3d12-review-inline:end:execution:R008:0:authored:migration-63b8629db96a2016-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:R009:0:authored:migration-43fe1dac5a1f4798-0 -->A pool must not be reset while a CPU recording is using it or before all
GPU uses of its recorded storage have completed. As with application allocator
Reset, the application is responsible for GPU completion synchronization.
Reset makes that storage available for reuse and invalidates the old
recordings, even if their command list objects still exist. An invalidated
recording must not subsequently be submitted or selected for execution.
Destroying the pool likewise requires no active CPU recording or outstanding
GPU use and ends the validity of its recorded storage. Neither operation
waits for the application to make otherwise invalid use safe.<!-- d3d12-review-inline:end:execution:R009:0:authored:migration-43fe1dac5a1f4798-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:R010:0:authored:migration-37bc09b7523df7c3-0 -->Before destroying a recorder, its associated command list must be closed or
destroyed. Destroying a command list may abandon an open recording without a
preceding Close DDI. The driver must release that recording's CPU recorder
use during abandonment. This does not allow destruction of a recorder still
used by a live recording list.<!-- d3d12-review-inline:end:execution:R010:0:authored:migration-37bc09b7523df7c3-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:R011:0:authored:migration-9889a9435a6925ba-0 -->Destroying a list ends its driver object lifetime, not the lifetime of
pool-backed recordings that are still executing. Driver cleanup must also
obey the [command list resource lifetime rule](execution.md#driver-responsibilities):
referenced resources may already have been destroyed. Cleanup must not
require an implicit Close that accesses those resources.<!-- d3d12-review-inline:end:execution:R011:0:authored:migration-9889a9435a6925ba-0 --></ins>

<a id="failed-recording"></a>

##### Failed recording and recorder reuse

<ins><!-- d3d12-review-inline:begin:execution:R034:0:authored:migration-5f1bda752c08b5c9-0 -->A stored recording error makes the failed recording non-executable and
prevents that command list object from being reset again. Application Close
still ends the logical recording and releases its allocator/recorder recording
use, even when the runtime omits the Close DDI. If the device remains usable,
a different compatible list may begin recording with that allocator/recorder
while the failed list object remains alive. This permission does not reset
pool storage or relax its GPU use and reclamation requirements.<!-- d3d12-review-inline:end:execution:R034:0:authored:migration-5f1bda752c08b5c9-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:R035:0:authored:migration-6e93564725fe0ab6-0 -->An error callback does not itself release the runtime's recording ownership.
In particular, an error reported during Reset or its state initialization
can be stored for Close to report even when the application Reset returns
`S_OK`. Until application Close or list destruction ends that recording,
the runtime must not reuse its recorder for another recording. The driver
may clean up failed-recording state earlier, provided it preserves the
other recordings and object lifetimes required by this contract. A retained
lifetime reference is distinct from active recording ownership.<!-- d3d12-review-inline:end:execution:R035:0:authored:migration-6e93564725fe0ab6-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:R036:0:authored:migration-37f626e48fb3fd23-0 -->The driver must tolerate later reuse, idle retargeting or destruction of the
recorder after logical recording closure without a preceding Close DDI.
The [associated-list destruction precondition](#target-and-reclamation)
uses this logical closed state, not guaranteed delivery of a Close DDI.
Later cleanup or destruction of the failed list must not release, reset or
invalidate recording state or backing allocations now used by a successor
recording, or dereference a recorder or pool object whose lifetime has ended.
The driver must not require an implicit Close or access to already-destroyed
referenced resources to perform that cleanup.<!-- d3d12-review-inline:end:execution:R036:0:authored:migration-37f626e48fb3fd23-0 --></ins>

<a id="private-storage"></a>

#### Private storage and errors

<ins><!-- d3d12-review-inline:begin:execution:R012:0:authored:migration-249bf3d5765b2e6c-0 -->For each allocator, pool, recorder or list, the runtime queries and allocates private driver storage before creation.<!-- d3d12-review-inline:end:execution:R012:0:authored:migration-249bf3d5765b2e6c-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:R013:0:authored:migration-01e3cc90b6d6e922-0 -->The actual supplied private pointer is aligned to `MEMORY_ALLOCATION_ALIGNMENT`:
16 bytes on Win64 and 8 bytes on Win32. The runtime owns this region. The
driver owns auxiliary allocations it makes for the object and must release
them during destruction. The driver's Destroy DDI does not free the supplied
runtime-owned private region.<!-- d3d12-review-inline:end:execution:R013:0:authored:migration-01e3cc90b6d6e922-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:R014:0:authored:migration-3eb4b1368daa842a-0 -->Creation returns an `HRESULT`. On failure the driver must clean up its partial
initialization and auxiliary allocations. The runtime does not call Destroy
for a failed creation. After successful creation, subsequent abandonment or
initialization failure requires destruction of that successfully created
object before its supplied storage is released.<!-- d3d12-review-inline:end:execution:R014:0:authored:migration-3eb4b1368daa842a-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:R015:0:authored:migration-2e8ef53d8444ed12-0 -->Reset and Close DDIs report recording failures through the [deferred error callback](#lifecycle-driver-errors). Pool/allocator Reset must not wait for GPU completion.<!-- d3d12-review-inline:end:execution:R015:0:authored:migration-2e8ef53d8444ed12-0 --></ins>

<a id="recording-descriptions"></a>

#### Shared recording descriptions

<ins><!-- d3d12-review-inline:begin:execution:R017:0:authored:migration-10bdf368021fc950-0 -->`D3D12DDI_COMMAND_LIST_TYPE` distinguishes direct-style recording from bundles.
It is not the application's full `D3D12_COMMAND_LIST_TYPE` enumeration;
compute, copy and video API enum values must not be cast to this DDI enum.
`QueueFlags` identifies the workload capabilities of the recording machinery.
The paging flag is a driver interface flag, not an additional application
command list type.<!-- d3d12-review-inline:end:execution:R017:0:authored:migration-10bdf368021fc950-0 --></ins>

```cpp
typedef enum D3D12DDI_COMMAND_LIST_TYPE
{
    D3D12DDI_COMMAND_LIST_TYPE_DIRECT  = 0,
    D3D12DDI_COMMAND_LIST_TYPE_BUNDLE  = 1,
} D3D12DDI_COMMAND_LIST_TYPE;

typedef enum D3D12DDI_COMMAND_QUEUE_FLAGS
{
    D3D12DDI_COMMAND_QUEUE_FLAG_NONE                = 0x00000000,
    D3D12DDI_COMMAND_QUEUE_FLAG_3D                  = 0x00000001,
    D3D12DDI_COMMAND_QUEUE_FLAG_COMPUTE             = 0x00000002,
    D3D12DDI_COMMAND_QUEUE_FLAG_COPY                = 0x00000004,
    D3D12DDI_COMMAND_QUEUE_FLAG_PAGING              = 0x00000008,
    D3D12DDI_COMMAND_QUEUE_FLAG_0020_VIDEO_LEGACY   = 0x00000010, // Deprecated
    D3D12DDI_COMMAND_QUEUE_FLAG_0022_VIDEO_DECODE   = 0x00000010,
    D3D12DDI_COMMAND_QUEUE_FLAG_0022_VIDEO_PROCESS  = 0x00000020,
    D3D12DDI_COMMAND_QUEUE_FLAG_0053_VIDEO_ENCODE   = 0x00000040,

} D3D12DDI_COMMAND_QUEUE_FLAGS;

typedef enum D3D12DDI_COMMAND_LIST_FLAGS
{
    D3D12DDI_COMMAND_LIST_FLAG_NONE                             = 0x00000000,
    D3D12DDI_COMMAND_LIST_FLAG_ENABLE_MARKERS                   = 0x00000001,
    D3D12DDI_COMMAND_LIST_FLAG_0010_ENABLE_FULLPIPELINE_MARKERS = 0x00000002,
} D3D12DDI_COMMAND_LIST_FLAGS;
```

<ins><!-- d3d12-review-inline:begin:execution:R019:0:authored:migration-4c663d8e4d48a74c-0 -->`CommandListFlags` carries diagnostic-marker controls, including the full-pipeline
marker flag named with the `_0010` suffix. It is not the application's
`D3D12_COMMAND_LIST_FLAGS` creation flags type. `NodeMask` selects the list's
device node under the [device/node model](devices-and-capabilities.md#adapter-identity-and-linked-nodes).
Neither these fields nor queue flags replace the recording generation ID.<!-- d3d12-review-inline:end:execution:R019:0:authored:migration-4c663d8e4d48a74c-0 --></ins>

<a id="legacy-allocators"></a>

<a id="command-pools"></a>

#### Command pools

<ins><!-- d3d12-review-inline:begin:execution:R020:0:authored:migration-cd695b8216e5e0f9-0 -->The `_0040` protocol separates pool storage from the recorder. Reset reclaims pool storage under the [CPU/GPU preconditions](#target-and-reclamation).<!-- d3d12-review-inline:end:execution:R020:0:authored:migration-cd695b8216e5e0f9-0 --></ins>

```cpp
typedef enum D3D12DDI_COMMAND_POOL_FLAGS
{
    D3D12DDI_COMMAND_POOL_FLAG_NONE          = 0x00000000
} D3D12DDI_COMMAND_POOL_FLAGS;

typedef struct D3D12DDIARG_CREATE_COMMAND_POOL_0040
{
    D3D12DDI_COMMAND_POOL_FLAGS PoolFlags;
} D3D12DDIARG_CREATE_COMMAND_POOL_0040;

typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALC_PRIVATE_COMMAND_POOL_SIZE_0040 )( D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATE_COMMAND_POOL_0040* );
typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATE_COMMAND_POOL_0040 ) ( D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATE_COMMAND_POOL_0040*, D3D12DDI_HCOMMANDPOOL_0040 );
typedef VOID ( APIENTRY* PFND3D12DDI_DESTROY_COMMAND_POOL_0040 ) ( D3D12DDI_HDEVICE, D3D12DDI_HCOMMANDPOOL_0040 );
typedef VOID ( APIENTRY* PFND3D12DDI_RESET_COMMAND_POOL_0040 ) ( D3D12DDI_HDEVICE, D3D12DDI_HCOMMANDPOOL_0040 );
```

<a id="command-recorders"></a>

#### Command recorders

<ins><!-- d3d12-review-inline:begin:execution:R022:0:authored:migration-2523247168bfe39d-0 -->Recorder creation does not begin a recording or select a target pool.<!-- d3d12-review-inline:end:execution:R022:0:authored:migration-2523247168bfe39d-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:R023:0:authored:migration-bd25196c8967c871-0 -->SetCommandPoolAsTarget changes the recorder's target under the [idle target rules](#target-and-reclamation). Recorder destruction leaves valid pool-backed recordings intact.<!-- d3d12-review-inline:end:execution:R023:0:authored:migration-bd25196c8967c871-0 --></ins>

```cpp
typedef enum D3D12DDI_COMMAND_RECORDER_FLAGS
{
    D3D12DDI_COMMAND_RECORDER_FLAG_NONE = 0x00000000
} D3D12DDI_COMMAND_RECORDER_FLAGS;

typedef struct D3D12DDIARG_CREATE_COMMAND_RECORDER_0040
{
    D3D12DDI_COMMAND_QUEUE_FLAGS QueueFlags;
    D3D12DDI_COMMAND_RECORDER_FLAGS RecorderFlags;
} D3D12DDIARG_CREATE_COMMAND_RECORDER_0040;

typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALC_PRIVATE_COMMAND_RECORDER_SIZE_0040 )( D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATE_COMMAND_RECORDER_0040* );
typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATE_COMMAND_RECORDER_0040 ) ( D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATE_COMMAND_RECORDER_0040*, D3D12DDI_HCOMMANDRECORDER_0040 );
typedef VOID ( APIENTRY* PFND3D12DDI_DESTROY_COMMAND_RECORDER_0040 ) ( D3D12DDI_HDEVICE, D3D12DDI_HCOMMANDRECORDER_0040 );
typedef VOID ( APIENTRY* PFND3D12DDI_COMMAND_RECORDER_SET_COMMAND_POOL_AS_TARGET_0040 ) ( D3D12DDI_HDEVICE, D3D12DDI_HCOMMANDRECORDER_0040, D3D12DDI_HCOMMANDPOOL_0040 );
```

<a id="command-lists"></a>

#### Command list creation and recording

<ins><!-- d3d12-review-inline:begin:execution:R025:0:authored:migration-04861f0e2eb5f338-0 -->Driver command list creation receives separate driver and runtime list handles. The creation description does not supply a pool or recorder.<!-- d3d12-review-inline:end:execution:R025:0:authored:migration-04861f0e2eb5f338-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:R026:0:authored:migration-2912c112e40123cc-0 -->Reset takes the existing driver list and a description containing the recorder
for the new recording, its generation ID and marker flags. The recorder must
be available for that recording and have a valid target pool. Reset starts a
new recording without reclaiming old pool storage. The runtime supplies the
initial pipeline state and other applicable state through state setting DDIs,
not through these reset arguments. The canonical
[initial/reset state](command-list-state.md) defines those contributions.<!-- d3d12-review-inline:end:execution:R026:0:authored:migration-2912c112e40123cc-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:R027:0:authored:migration-1c24d5372d3f476a-0 -->Close ends recording and releases recorder use. List destruction must support [abandonment without Close](#target-and-reclamation).<!-- d3d12-review-inline:end:execution:R027:0:authored:migration-1c24d5372d3f476a-0 --></ins>

```cpp
typedef struct D3D12DDIARG_CREATE_COMMAND_LIST_0040
{
    D3D12DDI_COMMAND_LIST_TYPE   Type;
    D3D12DDI_COMMAND_QUEUE_FLAGS QueueFlags;
    UINT64                       ID;
    D3D12DDI_COMMAND_LIST_FLAGS  CommandListFlags;
    UINT                         NodeMask;
} D3D12DDIARG_CREATE_COMMAND_LIST_0040;

typedef struct D3D12DDIARG_RESETCOMMANDLIST_0040
{
    D3D12DDI_HCOMMANDRECORDER_0040   hDrvCommandRecorder;
    UINT64                           ID;
    D3D12DDI_COMMAND_LIST_FLAGS      CommandListFlags;
} D3D12DDIARG_RESETCOMMANDLIST_0040;

typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALC_PRIVATE_COMMAND_LIST_SIZE_0040 )( D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATE_COMMAND_LIST_0040* );
typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATE_COMMAND_LIST_0040 ) ( D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATE_COMMAND_LIST_0040*, D3D12DDI_HCOMMANDLIST, D3D12DDI_HRTCOMMANDLIST );
typedef VOID ( APIENTRY* PFND3D12DDI_RESETCOMMANDLIST_0040 )( D3D12DDI_HCOMMANDLIST, _In_ CONST D3D12DDIARG_RESETCOMMANDLIST_0040*);
typedef VOID ( APIENTRY* PFND3D12DDI_CLOSECOMMANDLIST )( D3D12DDI_HCOMMANDLIST );
typedef VOID ( APIENTRY* PFND3D12DDI_DESTROYCOMMANDLIST ) ( D3D12DDI_HDEVICE, D3D12DDI_HCOMMANDLIST );
```

<a id="work-command-handles"></a>

### Current work command handle representations

```cpp
typedef struct D3D12DDI_RUNTIME_BYPASS_HEADER
{
    const void* pInterfaceVtable;
    void*   pDriverObject;
} D3D12DDI_RUNTIME_BYPASS_HEADER;

D3D10DDI_H( D3D12DDI_API_HCOMMANDLIST )

inline D3D12DDI_HCOMMANDLIST GetDriverCommandListHandle(D3D12DDI_API_HCOMMANDLIST ApiHandle)
{
    D3D12DDI_RUNTIME_BYPASS_HEADER* pBypassHeader = (D3D12DDI_RUNTIME_BYPASS_HEADER*)ApiHandle.pDrvPrivate;
    D3D12DDI_HCOMMANDLIST hCommandList;

    hCommandList.pDrvPrivate = pBypassHeader->pDriverObject;
    return hCommandList;
}
```

<ins><!-- d3d12-review-inline:begin:execution:EF-api-handle-contract:0:authored:migration-da261d2c2fe00661-0 -->The current command list layouts are alternative representations. In `D3D12DDI_COMMAND_LIST_FUNCS_3D_0108`, the ordinary draw/dispatch entries receive `D3D12DDI_HCOMMANDLIST`. Their API-compatible counterparts in `D3D12DDI_COMMAND_LIST_FUNCS_3D_0114` instead receive `D3D12DDI_API_HCOMMANDLIST`. All remaining ordered draw counts/starts, signed base vertex and dispatch group counts retain the linked logical API meanings.<!-- d3d12-review-inline:end:execution:EF-api-handle-contract:0:authored:migration-da261d2c2fe00661-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:EF-api-handle-contract:1:authored:migration-10274074fd374143-0 -->The API handle identifies the application-side object/header, not the driver's ordinary command list storage. The published `GetDriverCommandListHandle` helper obtains `pDriverObject` from that header. The driver must not treat the API handle itself as its ordinary private object pointer. Neither the handle nor the header transfers COM ownership or changes the normal recording/object lifetime. The header's interface table member does not make driver-private memory interchangeable with an application object.<!-- d3d12-review-inline:end:execution:EF-api-handle-contract:1:authored:migration-10274074fd374143-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:EF-api-handle-contract:2:authored:migration-52738cbd1f1a7227-0 -->These are conditional selected-table contracts, not a guarantee of bypass support or a particular performance benefit on every device. Changing representation does not relax input, state, resource, predicate, render pass or recording error requirements and does not prove that the runtime validated or clamped the arguments. Bundle execution retains its explicitly ordinary handle pair in both tables.<!-- d3d12-review-inline:end:execution:EF-api-handle-contract:2:authored:migration-52738cbd1f1a7227-0 --></ins>

<!-- d3d12-review-alert:begin:execution:EF-api-handle-contract:3:authored:migration-8bf93e4a377ff144-0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Current member | Signature | Contract |
> | --- | --- | --- |
> | `D3D12DDI_COMMAND_LIST_FUNCS_3D_0108::pfnDrawInstanced` | `PFND3D12DDI_DRAWINSTANCED` | [Responsibility](vertex-processing.md#driver-draw) |
> | `D3D12DDI_COMMAND_LIST_FUNCS_3D_0108::pfnDrawIndexedInstanced` | `PFND3D12DDI_DRAWINDEXEDINSTANCED` | [Responsibility](vertex-processing.md#driver-draw) |
> | `D3D12DDI_COMMAND_LIST_FUNCS_3D_0108::pfnDispatch` | `PFND3D12DDI_DISPATCH` | [Responsibility](compute.md#driver-dispatch) |
> | `D3D12DDI_COMMAND_LIST_FUNCS_3D_0108::pfnExecuteBundle` | `PFND3D12DDI_EXECUTE_BUNDLE` | [Responsibility](execution.md#bundle-driver) |
> | `D3D12DDI_COMMAND_LIST_FUNCS_3D_0114::pfnDrawInstanced` | `PFND3D12DDI_DRAWINSTANCED_0114` | [Responsibility](vertex-processing.md#driver-draw) |
> | `D3D12DDI_COMMAND_LIST_FUNCS_3D_0114::pfnDrawIndexedInstanced` | `PFND3D12DDI_DRAWINDEXEDINSTANCED_0114` | [Responsibility](vertex-processing.md#driver-draw) |
> | `D3D12DDI_COMMAND_LIST_FUNCS_3D_0114::pfnDispatch` | `PFND3D12DDI_DISPATCH_0114` | [Responsibility](compute.md#driver-dispatch) |
> | `D3D12DDI_COMMAND_LIST_FUNCS_3D_0114::pfnExecuteBundle` | `PFND3D12DDI_EXECUTE_BUNDLE` | [Responsibility](execution.md#bundle-driver) |

<!-- d3d12-review-alert:end:execution:EF-api-handle-contract:3:authored:migration-8bf93e4a377ff144-0 -->

<a id="submission"></a>

## Submission and ordering

<ins><!-- d3d12-review-inline:begin:execution:SUB-scope:0:authored:migration-0c2fd91e3cc01c48-0 -->The submission and completion rules below apply to all supporting D3D12 command queue types, including video decode, process, and encode. The core queue/fence methods are declared by `ID3D12CommandQueue`, `ID3D12Device`, and `ID3D12Fence`. `SetEventOnMultipleFenceCompletion` is declared by `ID3D12Device1`. `GetCreationFlags` is declared by `ID3D12Fence1`.<!-- d3d12-review-inline:end:execution:SUB-scope:0:authored:migration-0c2fd91e3cc01c48-0 --></ins>

<a id="execute-command-lists"></a>

### ID3D12CommandQueue::ExecuteCommandLists

#### Declaration

```cpp
void ExecuteCommandLists(
    UINT NumCommandLists,
    ID3D12CommandList * const * ppCommandLists
);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:execution:execute-behavior:0 -->`ExecuteCommandLists` submits an array of command lists for execution.<!-- d3d12-review-inline:end:execution:execute-behavior:0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QF-none-execute-ref:0:authored:migration-392bb603b62f7bd7-0 -->Synchronization-only queues do not accept this operation. Their supported
operation model is defined [above](#synchronization-only-queues).<!-- d3d12-review-inline:end:execution:QF-none-execute-ref:0:authored:migration-392bb603b62f7bd7-0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:execution:execute-parameters:0:modified:migration-48e143852bdb92f2-0 -->**NumCommandLists**<!-- d3d12-review-inline:end:execution:execute-parameters:0:modified:migration-48e143852bdb92f2-0 --></ins>

The number of command lists to be executed.

<ins><!-- d3d12-review-inline:begin:execution:execute-parameters:2:modified:migration-56bf3a84cdd3cf35-0 -->**ppCommandLists**<!-- d3d12-review-inline:end:execution:execute-parameters:2:modified:migration-56bf3a84cdd3cf35-0 --></ins>

The array of [ID3D12CommandList](#recording-lifecycle) command lists to be executed.

#### Ordering and recording lifetime

Calling `ExecuteCommandLists` <ins><!-- d3d12-review-inline:begin:execution:P14:0 -->twice in succession on the same queue<!-- d3d12-review-inline:end:execution:P14:0 --></ins> (from the same thread, or different threads) guarantees that the first workload (A) finishes before the second workload (B). Calling `ExecuteCommandLists` with *two* command lists allows the driver to merge the two command lists such that the second command list (D) may begin executing work before all work from the first (C) has finished. Specifically, your application is allowed to insert a fence signal or wait between A and B, and the driver has no visibility into this, so the driver must ensure that everything in A is complete before the fence operation. There is no such opportunity in a single call to the API, so the driver is able to optimize that scenario.

The driver is free to patch the submitted command lists. It is the calling application’s responsibility to ensure that the graphics processing unit (GPU) is not currently reading any of the submitted recorded command streams from a previous execution.

Applications are encouraged to batch together command list executions to reduce fixed costs associated with submitted commands to the GPU.

<ins><!-- d3d12-review-inline:begin:execution:SUB-recording:0:authored:migration-a693956154f7fca9-0 -->The no-concurrent-reexecution rule concerns a particular recorded stream, not every recording ever made through the list object. Reset/re-recording may produce a new stream while an older stream executes, with valid backing storage and resources. See [recorded commands and allocator storage](#command-storage). Returning from `ExecuteCommandLists` does not establish GPU completion or make allocator/resource storage reusable.<!-- d3d12-review-inline:end:execution:SUB-recording:0:authored:migration-a693956154f7fca9-0 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:execution:SUB-execute-return:0:authored:migration-057db7e2b7ac625f-0 -->`ExecuteCommandLists` returns no value. Submission failures are not returned as an `HRESULT` from this method.<!-- d3d12-review-inline:end:execution:SUB-execute-return:0:authored:migration-057db7e2b7ac625f-0 --></ins>

<a id="validation"></a>

#### Runtime validation

Bundles can't be submitted to a command queue directly. If a bundle is passed to this method, the runtime will drop the call. The runtime will also drop the call if the <ins><!-- d3d12-review-inline:begin:execution:P17:0:modified:source-b4e56c9bd7c61324-0-0 -->[Close](#close)<!-- d3d12-review-inline:end:execution:P17:0:modified:source-b4e56c9bd7c61324-0-0 --></ins> function has not <ins><!-- d3d12-review-inline:begin:execution:P17:0:modified:source-b4e56c9bd7c61324-0-1 -->successfully closed<!-- d3d12-review-inline:end:execution:P17:0:modified:source-b4e56c9bd7c61324-0-1 --></ins> one or more of the command lists.

The runtime will detect if the command allocators associated with the command lists have been reset after [Close](#close) was called. The runtime will drop the call and remove the device in this situation.

<ins><!-- d3d12-review-inline:begin:execution:SUB-validation:0:authored:migration-992fc34bed67612e-0 -->Submitted lists must match the queue's command list type and have compatible node masks. A list created initially closed by `CreateCommandList1` must first begin a recording with `Reset` and successfully close it. An object that has never begun a recording is not executable. An empty but successfully closed recording is distinct from an object that has never begun recording.<!-- d3d12-review-inline:end:execution:SUB-validation:0:authored:migration-992fc34bed67612e-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:SUB-validation:1:authored:migration-f7fc057265f92d84-0 -->Runtime-detected submission failures drop the submission and remove the device. This includes invalid recorded/closed state, allocator generation invalidation, and type/node incompatibility. It is not a guarantee that every invalid application action is detected by the retail runtime.<!-- d3d12-review-inline:end:execution:SUB-validation:1:authored:migration-f7fc057265f92d84-0 --></ins>

#### Debug layer

<ins><!-- d3d12-review-inline:begin:execution:SUB-debug:0:authored:migration-87a814ff28ea94ba-0 -->Debug validation checks previous execution of the recorded stream, deferred resource transition and query requirements, and tracked resource lifetimes. Applications must meet those usage requirements whether or not validation is enabled. They must not depend on universal retail detection or device removal for every barrier/query or overlapping-execution error.<!-- d3d12-review-inline:end:execution:SUB-debug:0:authored:migration-87a814ff28ea94ba-0 --></ins>

The debug layer issues an error if it detects that any resource referenced by the command lists, including queries, has been destroyed.

<a id="execute-command-lists-ddi"></a>

### PFND3D12DDI_EXECUTECOMMANDLISTS

UMD's <ins><!-- d3d12-review-inline:begin:execution:QT-I01:0:modified:migration-763d2ed1507f7eef-0 -->`PFND3D12DDI_EXECUTECOMMANDLISTS`<!-- d3d12-review-inline:end:execution:QT-I01:0:modified:migration-763d2ed1507f7eef-0 --></ins> function executes an array of command lists submitted by an application.

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_EXECUTECOMMANDLISTS ) (
    D3D12DDI_HCOMMANDQUEUE,
    UINT Count,
    _In_reads_(Count) CONST D3D12DDI_HCOMMANDLIST* pCommandLists
    );
```

<ins><!-- d3d12-review-inline:begin:execution:QT-N03:0:authored:migration-9d23c1699ce7216f-0 -->The UMD executes the supplied recordings under the
[application ordering and recording lifetime contract](execution.md#execute-command-lists)
and [driver recording storage rules](execution.md#object-model).
Runtime adaptation does not establish a universal one-to-one relationship
between an application call, a DDI call and a kernel command buffer submission.<!-- d3d12-review-inline:end:execution:QT-N03:0:authored:migration-9d23c1699ce7216f-0 --></ins>

Drivers must implement command list execution DDIs in a free threaded
manner so that multiple queues can accept command lists for execution
concurrently.

<ins><!-- d3d12-review-inline:begin:execution:QT-I03:0:modified:migration-c1350bd416c80220-0 -->On a kernel-mediated submission path, when the command list execution DDI<!-- d3d12-review-inline:end:execution:QT-I03:0:modified:migration-c1350bd416c80220-0 --></ins> is called, the driver <ins><!-- d3d12-review-inline:begin:execution:QT-I03:0 -->must immediately<!-- d3d12-review-inline:end:execution:QT-I03:0 --></ins>
call the command buffer submission callback. Drivers may not defer
submission of command buffers until a later time.

<ins><!-- d3d12-review-inline:begin:execution:QT-N04:0:authored:migration-2aee6c96187e4490-0 -->The DDI returns no `HRESULT`. Returning does not establish GPU completion
or permit reuse of recording storage still in use. An execution failure that
the UMD cannot resolve is reported through `PFND3D12DDI_SETERROR_CB`, not
through the command list recording error callback or an application return
value. Callback failures may be handled within the execution attempt, but
do not provide a recoverable execution error return channel to the application.
Device removal observation remains governed by the
[completion/removal rules](execution.md#completion-lifetime).<!-- d3d12-review-inline:end:execution:QT-N04:0:authored:migration-2aee6c96187e4490-0 --></ins>

<a id="submission-threading"></a>

### Submission threading

Applications can submit command lists to any command queue from multiple threads. The runtime will perform the work of serializing these requests in the order of submission.

<ins><!-- d3d12-review-inline:begin:execution:SUB-queue-order:0:authored:migration-2b7ccfe45dd43343-0 -->Serialization is per queue. It does not establish dependencies between independent queues. Use [queue signals](#queue-signal) and [queue waits](#queue-waits) to express inter-queue dependencies. If CPU threads require a particular submission order, synchronize those threads rather than inferring an order from unsynchronized concurrent calls.<!-- d3d12-review-inline:end:execution:SUB-queue-order:0:authored:migration-2b7ccfe45dd43343-0 --></ins>

<a id="submission-barriers"></a>

### Submission boundaries and resource barriers

<ins><!-- d3d12-review-inline:begin:execution:SUB-finish-flush:0:authored:source-419090fc07c614bc-0-0 -->For successive submissions on the same queue, <!-- d3d12-review-inline:end:execution:SUB-finish-flush:0:authored:source-419090fc07c614bc-0-0 --></ins>D3D12 requires a full finish and flush of all GPU work at `ExecuteCommandLists` completion. Therefore, any writes to a resource during a preceding `ExecuteCommandLists` scope will be fully completed when that resource is needed in a subsequent `ExecuteCommandLists` scope.  However, drivers are not expected to keep track of when a resource was last written to.  So in addition to sync, a transition from a WRITE state may force a cache flush, even if the resource is already up-to-date from an earlier cache flush.

#### Legacy resource state rules

<ins><!-- d3d12-review-inline:begin:execution:SUB-state-reference:0:authored:migration-f7ae587041c62d07-0 -->Legacy resource state behavior at submission boundaries is defined in [Common state promotion and decay](synchronization.md#legacy-promotion-and-decay).<!-- d3d12-review-inline:end:execution:SUB-state-reference:0:authored:migration-f7ae587041c62d07-0 --></ins>

#### Enhanced layouts and cross-queue access

<ins><!-- d3d12-review-inline:begin:execution:S-layout-forward:0:authored:migration-a50f1a2094c76fa4-0 -->Texture layout transitions and queue/layout compatibility are defined in [Synchronization and barriers](synchronization.md#layout-transitions).<!-- d3d12-review-inline:end:execution:S-layout-forward:0:authored:migration-a50f1a2094c76fa4-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:SUB-barrier-boundary:0:authored:migration-7ec73c0989fdc28a-0 -->Fence ordering does not select a resource's legacy state or change a texture's enhanced layout. Apply the relevant [legacy multi-queue state rules](synchronization.md#legacy-common-state-promotion), [enhanced queue layout compatibility](synchronization.md#queue-compatibility), [access compatibility](synchronization.md#queue-compatibility), and [copy queue rules](synchronization.md#queue-compatibility). These requirements are distinct from waiting for a producer's queue signal.<!-- d3d12-review-inline:end:execution:SUB-barrier-boundary:0:authored:migration-7ec73c0989fdc28a-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:SUB-barrier-boundary:1:authored:migration-f0f8358691258b1b-0 -->Suspended/resumed render passes must be paired within one `ExecuteCommandLists` group. See [render pass recording and execution context](command-list-state.md#render-pass). A list boundary inside a batch is not a new submission boundary. Fine-grained [fence barriers](fence-barriers.md) synchronize selected barrier work within a submission.<!-- d3d12-review-inline:end:execution:SUB-barrier-boundary:1:authored:migration-f0f8358691258b1b-0 --></ins>

<a id="submission-driver"></a>

### Runtime and driver submission responsibilities

<ins><!-- d3d12-review-inline:begin:execution:SUB-driver-execute:0 -->The [ExecuteCommandLists DDI contract](#execute-command-lists-ddi) defines submission of the application's command lists to the user-mode driver.<!-- d3d12-review-inline:end:execution:SUB-driver-execute:0 --></ins>

<a id="driver-submission-transport"></a>

### Driver submission transport

<a id="shared-callback-contract"></a>

#### Shared callback contract and handle domains

<ins><!-- d3d12-review-inline:begin:execution:QT-N05:0:authored:migration-6c0866cc390b6ee2-0 -->The shared callbacks are supplied through the device's `pKTCallbacks`
`D3DDDI_DEVICECALLBACKS` table. Their first `HANDLE hDevice` identifies the
runtime device callback context, not a UMD-private `D3D12DDI_HDEVICE` or an
application command queue. Table lifetime and interface selection follow
[Runtime UMD initialization](devices-and-capabilities.md#table-selection).<!-- d3d12-review-inline:end:execution:QT-N05:0:authored:migration-6c0866cc390b6ee2-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QT-N06:0:authored:migration-f0ae94f4694dbaf6-0 -->Context and hardware queue `HANDLE` values returned by these D3D12 runtime
callbacks are opaque runtime handles. The runtime translates them to kernel
handles when performing the operation. In contrast, returned `D3DKMT_HANDLE`
synchronization object values are OS synchronization object handles. Neither
kind is interchangeable with a UMD private fence handle.<!-- d3d12-review-inline:end:execution:QT-N06:0:authored:migration-f0ae94f4694dbaf6-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QT-N07:0:authored:migration-27870efc7b76f4e5-0 -->In the declarations below, `_In_` descriptions provide the request and
`_Inout_` descriptions also return the indicated results. Array counts and
fixed-array capacities are part of the corresponding payload contract;
counts must describe the supplied arrays, and reserved flag bits must be
zero. The callback's `HRESULT` reports its operation result.
Some removal paths can return `S_OK` after the device has failed, so success
does not independently establish a healthy device.<!-- d3d12-review-inline:end:execution:QT-N07:0:authored:migration-27870efc7b76f4e5-0 --></ins>

<a id="internal-contexts"></a>

#### UMD-internal contexts and hardware queues

```cpp
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_CREATECONTEXTCB)(
    _In_ HANDLE hDevice, _Inout_ D3DDDICB_CREATECONTEXT*);
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_CREATECONTEXTVIRTUALCB)(
    _In_ HANDLE hDevice, _Inout_ D3DDDICB_CREATECONTEXTVIRTUAL*);
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_DESTROYCONTEXTCB)(
    _In_ HANDLE hDevice, _In_ CONST D3DDDICB_DESTROYCONTEXT*);
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_CREATEHWQUEUECB)(
    _In_ HANDLE hDevice, _Inout_ D3DDDICB_CREATEHWQUEUE*);
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_DESTROYHWQUEUECB)(
    _In_ HANDLE hDevice, _In_ CONST D3DDDICB_DESTROYHWQUEUE*);
```

<ins><!-- d3d12-review-inline:begin:execution:QT-N09:0:authored:migration-2496c0c943e10fb6-0 -->The shared CreateContext forms create device-associated contexts for driver
internal work. Both supply node ordinal, engine affinity, context flags and
private KMD data, returning `hContext`. The non-virtual form additionally
returns the software submission command buffer and allocation/patch lists.
The virtual form creates a GPU virtual address context. These are distinct
from [queue/group-associated context callbacks](command-queues.md#context-creation-callbacks).<!-- d3d12-review-inline:end:execution:QT-N09:0:authored:migration-2496c0c943e10fb6-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QT-N10:0:authored:migration-9be6fa0ead3b77f2-0 -->CreateHwQueue supplies a context handle and hardware queue flags/private
data, and returns a hardware queue handle plus its progress fence handle and
CPU/GPU addresses. At the `_0050` queue/group interface, the shared creation
callback is for internal contexts, not for creating a global hardware queue
against a context owned by an application queue or scheduling group.<!-- d3d12-review-inline:end:execution:QT-N10:0:authored:migration-9be6fa0ead3b77f2-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QT-N11:0:authored:migration-bfa7ca8a1db0a897-0 -->The UMD requests destruction of its internal hardware queues and contexts
through the matching shared Destroy callbacks. These actually destroy the
internal objects. The shared context callback is not the
[legacy D3D12 compatibility no-op](command-queues.md#legacy-destroy-context).
Shared DestroyContext rejects queue/group-owned contexts, and shared
DestroyHwQueue rejects queue/group-owned contexts or hardware queues.
The shared callbacks are not an escape from the managed object creation
window or runtime ownership of application-associated objects.<!-- d3d12-review-inline:end:execution:QT-N11:0:authored:migration-bfa7ca8a1db0a897-0 --></ins>

If the specified context has not finished the work that is currently queued to it, the <ins><!-- d3d12-review-inline:begin:execution:QT-I04:0:modified:migration-b83152cc1c8f4990-0 -->`pfnDestroyContextCb`<!-- d3d12-review-inline:end:execution:QT-I04:0:modified:migration-b83152cc1c8f4990-0 --></ins> function blocks until the context finishes its work and then returns.

<a id="kernel-submission"></a>

#### Kernel-mediated command buffer submission

```cpp
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_RENDERCB)(
    _In_ HANDLE hDevice, _Inout_ D3DDDICB_RENDER*);
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_SUBMITCOMMANDCB)(
    _In_ HANDLE hDevice, _In_ CONST D3DDDICB_SUBMITCOMMAND*);
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_SUBMITCOMMANDTOHWQUEUECB)(
    _In_ HANDLE hDevice, _In_ CONST D3DDDICB_SUBMITCOMMANDTOHWQUEUE*);
```

The <ins><!-- d3d12-review-inline:begin:execution:QT-I05:0:modified:migration-fc422c33364c5f50-0 -->`pfnRenderCb`<!-- d3d12-review-inline:end:execution:QT-I05:0:modified:migration-fc422c33364c5f50-0 --></ins> function submits the current command buffer for rendering to the display miniport driver.

<ins><!-- d3d12-review-inline:begin:execution:QT-I06:0:modified:migration-46666362d482ca16-0 -->`pfnSubmitCommandCb`<!-- d3d12-review-inline:end:execution:QT-I06:0:modified:migration-46666362d482ca16-0 --></ins> is used to submit command buffers on contexts that support graphics processing unit (GPU) virtual addressing. These contexts generate commands directly from user mode, manage their own command buffer pool and don<ins><!-- d3d12-review-inline:begin:execution:QT-I06:0:modified:migration-500743ceaa3117f4-1 -->'<!-- d3d12-review-inline:end:execution:QT-I06:0:modified:migration-500743ceaa3117f4-1 --></ins>t make use of allocation or patch location list.

<ins><!-- d3d12-review-inline:begin:execution:QT-I07:0:modified:migration-6127bcc2f6f2d67d-0 -->`pfnSubmitCommandCb`<!-- d3d12-review-inline:end:execution:QT-I07:0:modified:migration-6127bcc2f6f2d67d-0 --></ins> replaces the old <ins><!-- d3d12-review-inline:begin:execution:QT-I07:0:modified:migration-f7b4991423edacc4-1 -->[pfnRenderCb](#kernel-submission)<!-- d3d12-review-inline:end:execution:QT-I07:0:modified:migration-f7b4991423edacc4-1 --></ins> for such contexts and must be used in its place. Contexts that operate in legacy patch mode must continue to use the old <ins><!-- d3d12-review-inline:begin:execution:QT-I07:0:modified:migration-c2b18d0e7d652bcd-2 -->`pfnRenderCb`<!-- d3d12-review-inline:end:execution:QT-I07:0:modified:migration-c2b18d0e7d652bcd-2 --></ins>.

Although the user mode driver doesn<ins><!-- d3d12-review-inline:begin:execution:QT-I08:0:modified:migration-a4c87b30a175ab85-0 -->'<!-- d3d12-review-inline:end:execution:QT-I08:0:modified:migration-a4c87b30a175ab85-0 --></ins>t generate patch locations it must still generate a list of the primaries <ins><!-- d3d12-review-inline:begin:execution:QT-I08:0:modified:migration-977912ded6a47adf-1 -->that are<!-- d3d12-review-inline:end:execution:QT-I08:0:modified:migration-977912ded6a47adf-1 --></ins> being written to. The video memory manager uses the allocation list to determine which primary allocations are being referenced for write by each command buffer. This information is used to synchronize rendering to the primaries with <ins><!-- d3d12-review-inline:begin:execution:QT-I08:0:modified:migration-c76a13960923ec12-2 -->`Flip`<!-- d3d12-review-inline:end:execution:QT-I08:0:modified:migration-c76a13960923ec12-2 --></ins> operations.

<!-- d3d12-review-alert:begin:execution:QT-N13:0:authored:migration-3e9f020e9f13d96a-0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Callback | Request and result responsibilities |
> |---|---|
> | `PFND3DDDI_RENDERCB` | Supply the context, command offset/byte length, allocation and patch counts, broadcast contexts and any resize requests in `D3DDDICB_RENDER`. The in/out payload returns the next command buffer/list information for continued legacy recording. |
> | `PFND3DDDI_SUBMITCOMMANDCB` | Supply GPU command address/length, broadcast contexts, written primaries and submission private data in `D3DDDICB_SUBMITCOMMAND`. Broadcast contexts must belong to one queue and must not be owned by a scheduling group. |
> | `PFND3DDDI_SUBMITCOMMANDTOHWQUEUECB` | Supply the hardware queue handle, command address/length, progress fence ID, written primaries and private data in `D3DDDICB_SUBMITCOMMANDTOHWQUEUE`. The runtime translates the hardware queue handle and performs the kernel submission. |

<!-- d3d12-review-alert:end:execution:QT-N13:0:authored:migration-3e9f020e9f13d96a-0 -->

<ins><!-- d3d12-review-inline:begin:execution:QT-N14:0:authored:migration-f4d00d8e0f68f7be-0 -->Submission private data is input to the KMD. The runtime may augment the submitted written-primary set with tracked application references.<!-- d3d12-review-inline:end:execution:QT-N14:0:authored:migration-f4d00d8e0f68f7be-0 --></ins>

<a id="completion"></a>

## Completion and fences

<a id="fence-operations"></a>

### Fence values and timelines

<ins><!-- d3d12-review-inline:begin:execution:F-timeline-scope:0:authored:migration-41650de147e71e1b-0 -->The application-controlled timelines below use writable fences. System-controlled [protected session status fences](#status-fences) are read-only and do not represent application work completion. [Command list scoped fences](#command-list-scoped-fences) instead use the scoped barrier model, not this ordinary queue timeline.<!-- d3d12-review-inline:end:execution:F-timeline-scope:0:authored:migration-41650de147e71e1b-0 --></ins>

The multi-engine API provides explicit APIs to create and synchronize using fences. A fence is a synchronization construct controlled by a `UINT64` value. Fence values are set by the application. A signal operation modifies the fence value and a wait operation blocks until the fence has reached the requested value or greater. An event can be fired when a fence reaches a certain value.

The [`Signal`](#fence-signal) method on the [`ID3D12Fence`](#completion) interface updates a fence from the CPU side. This update occurs immediately. The [`Signal`](#queue-signal) method on [`ID3D12CommandQueue`](#execution-objects) updates a fence from the GPU side. This update occurs after all other operations on the command queue have been completed.

A fence *may* be *rewound*. This means that the fence value does not need to solely increment. If a `Signal` operation is enqueued on two different command queues, or if two CPU threads are both calling `Signal` on a fence, there may be a race to determine which `Signal` completes last, and therefore which fence value is the one which will remain. If a fence is rewound, any new waits (including `SetEventOnCompletion` requests) will be compared against the new lower fence value, and therefore may not be satisfied, even if the fence value had previously been high enough to satisfy them. If a race does occur, between a value which will satisfy an outstanding wait, and a lower value which will not, the wait *will* be satisfied regardless of which value remains afterwards.

The fence APIs provide powerful synchronization functionality but can create potentially difficult to debug issues. It is recommended that each fence only be used to indicate progress on one timeline to prevent races between signalers.

<ins><!-- d3d12-review-inline:begin:execution:F-wait-liveness:0:authored:migration-26b8737b907124b1-0 -->A queued wait blocks subsequent work on that queue, not the calling CPU thread. The operation that can satisfy it must be able to run: placing the only satisfying signal behind an unsatisfied wait on the same queue does not make progress.<!-- d3d12-review-inline:end:execution:F-wait-liveness:0:authored:migration-26b8737b907124b1-0 --></ins>

<a id="status-fences"></a>

### Protected session status fences

The D3D12 protected resource session has a status fence whose fence value is incremented whenever protected content becomes invalid.  Status may be pulled from the protected session.  This typically happens when the system enters a sleep state and wakes back up, but could also be triggered by tamper protection from driver or hardware.

<ins><!-- d3d12-review-inline:begin:execution:F-status-observation:0 -->[`ID3D12ProtectedSession::GetStatusFence`](../ProtectedResources.md#method-id3d12protectedsessiongetstatusfence) returns the fence for the protected session. From the fence, we can get
the current uniqueness validity value (using `GetCompletedValue`), and add
monitors for change of its value. This is a read-only fence.<!-- d3d12-review-inline:end:execution:F-status-observation:0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:F-status-meaning:0:authored:migration-5f18ee5bb0eca22f-0 -->Read-only status fences must not be signaled through `ID3D12Fence::Signal`, `ID3D12CommandQueue::Signal`, or `ID3D12Device3::EnqueueMakeResident`. Their value changes indicate protected content invalidation, not completion of submitted application work. These writability and value meaning rules are separate from the [monitoring capability restrictions](#fence-flags).<!-- d3d12-review-inline:end:execution:F-status-meaning:0:authored:migration-5f18ee5bb0eca22f-0 --></ins>

<a id="fence-flags"></a>

### Fence options and CPU observation

```cpp
typedef enum D3D12_FENCE_FLAGS
{
    D3D12_FENCE_FLAG_NONE = 0x0,
    D3D12_FENCE_FLAG_SHARED = 0x1,
    D3D12_FENCE_FLAG_SHARED_CROSS_ADAPTER = 0x2,
    D3D12_FENCE_FLAG_NON_MONITORED = 0x4,
    D3D12_FENCE_FLAG_ALLOW_COMMAND_LIST_BARRIERS = 0x8,
    D3D12_FENCE_FLAG_ALLOW_QUEUE_AND_CPU_SYNC = 0x10,
} D3D12_FENCE_FLAGS;
```

<a id="base-fence-options"></a>

#### Base fence options

<!-- d3d12-review-alert:begin:execution:fence-flags-meanings:0:modified:migration-c793409899ea3352-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Flag | Value | Meaning |
> |---|---|---|
> | `D3D12_FENCE_FLAG_NONE` | `0` | No options are specified. |
> | `D3D12_FENCE_FLAG_SHARED` | `0x1` | The fence is shared. |
> | `D3D12_FENCE_FLAG_SHARED_CROSS_ADAPTER` | `0x2` | The fence is shared with another GPU adapter. |
> | `D3D12_FENCE_FLAG_NON_MONITORED` | `0x4` | The fence is of the non-monitored type. Non-monitored fences should only be used when the adapter doesn't support monitored fences, or when a fence is shared with an adapter that doesn't support monitored fences. |

<!-- d3d12-review-alert:end:execution:fence-flags-meanings:0:modified:migration-c793409899ea3352-0 -->

<a id="fence-barrier-options"></a>

#### Fence barrier options

<a id="allow-command-list-barriers"></a>

##### D3D12_FENCE_FLAG_ALLOW_COMMAND_LIST_BARRIERS

<ins><!-- d3d12-review-inline:begin:execution:FB-flag-cl:0 -->`D3D12_FENCE_FLAG_ALLOW_COMMAND_LIST_BARRIERS` requests barrier support; the actual fence must report that flag to be eligible for command-list `SignalBarrier` or `WaitBarrier`.
Fences created with `D3D12_FENCE_FLAG_ALLOW_COMMAND_LIST_BARRIERS` set but without `D3D12_FENCE_FLAG_ALLOW_QUEUE_AND_CPU_SYNC` bit also set are referred to as [Command List Scoped Fences](#command-list-scoped-fences).<!-- d3d12-review-inline:end:execution:FB-flag-cl:0 --></ins>

<a id="allow-queue-and-cpu-sync"></a>

##### D3D12_FENCE_FLAG_ALLOW_QUEUE_AND_CPU_SYNC

This flag is necessary to support GPU command-buffer-level fence synchronization between multiple queues or between the GPU and CPU.

`D3D12_FENCE_FLAG_ALLOW_QUEUE_AND_CPU_SYNC` must be combined with `D3D12_FENCE_FLAG_ALLOW_COMMAND_LIST_BARRIERS`.

If an app doesn't require queue or CPU sync, then it is recommended not setting this flag as it may significantly reduce barrier performance.

All fences created with `D3D12_FENCE_FLAG_SHARED` or `D3D12_FENCE_FLAG_SHARED_CROSS_ADAPTER` require Queue and CPU sync. As such, the `D3D12_FENCE_FLAG_SHARED` and `D3D12_FENCE_FLAG_SHARED_CROSS_ADAPTER` bits cannot be used when `D3D12_FENCE_FLAG_ALLOW_COMMAND_LIST_BARRIERS` is set without also setting `D3D12_FENCE_FLAG_ALLOW_QUEUE_AND_CPU_SYNC`.

<ins><!-- d3d12-review-inline:begin:execution:FB-explicit-shared:0:authored:migration-c219717e1865cc98-0 -->Fence barrier use requires `D3D12_FENCE_FLAG_ALLOW_COMMAND_LIST_BARRIERS` explicitly. For a shared or cross-adapter fence, also request `D3D12_FENCE_FLAG_ALLOW_QUEUE_AND_CPU_SYNC`. Sharing alone does not supply barrier eligibility. Creation can fail when the device/platform cannot supply the required GPU-accessible fence. A flag-only `S_FALSE` probe does not test that construction path.<!-- d3d12-review-inline:end:execution:FB-explicit-shared:0:authored:migration-c219717e1865cc98-0 --></ins>

<a id="fence-observation-requirements"></a>

#### Creation and observation requirements

<ins><!-- d3d12-review-inline:begin:execution:F-flag-validation:0:authored:migration-cbf97dc0e883a998-0 -->`D3D12_FENCE_FLAG_SHARED_CROSS_ADAPTER` requires `D3D12_FENCE_FLAG_SHARED`. `D3D12_FENCE_FLAG_NON_MONITORED` creation requires both sharing flags and adapter support for non-monitored fences. Unsupported flag combinations fail with `E_INVALIDARG`.<!-- d3d12-review-inline:end:execution:F-flag-validation:0:authored:migration-cbf97dc0e883a998-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:F-flag-validation:1:authored:migration-ee4d6cd55d7371d3-0 -->Adapter fence support is described by [`DXGI_ADAPTER_DESC3::Flags`](https://learn.microsoft.com/en-us/windows/win32/api/dxgi1_6/ns-dxgi1_6-dxgi_adapter_desc3), including `DXGI_ADAPTER_FLAG3_SUPPORT_MONITORED_FENCES` and `DXGI_ADAPTER_FLAG3_SUPPORT_NON_MONITORED_FENCES`. When `IDXGIAdapter4` is available, obtain the description through [`IDXGIAdapter4::GetDesc3`](https://learn.microsoft.com/en-us/windows/win32/api/dxgi1_6/nf-dxgi1_6-idxgiadapter4-getdesc3).<!-- d3d12-review-inline:end:execution:F-flag-validation:1:authored:migration-ee4d6cd55d7371d3-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:D111-shared-fence-handles:0:authored:migration-f8f0909315523b2f-0 -->The complete [shared fence export/open and handle contract](sharing-and-interoperability.md#sharing-synchronization) defines how participating devices and processes obtain the same fence. Exporting or opening a handle does not signal or wait for the fence, supply command list barrier eligibility or relax these creation and CPU observation requirements.<!-- d3d12-review-inline:end:execution:D111-shared-fence-handles:0:authored:migration-f8f0909315523b2f-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:F-cpu-limits:0:authored:migration-c2ca8aadf2070774-0 -->Non-monitored fences are used for GPU-side synchronization. They do not provide the CPU progress observation operations of monitored fences. `ID3D12Fence::Signal` and `ID3D12Fence::SetEventOnCompletion` reject a non-monitored fence with `E_INVALIDARG`. `GetCompletedValue` is invalid for a non-monitored fence and returns `UINT64_MAX`. That value is not a completed-work measurement. Multi-fence CPU notification/wait also requires CPU-wait-capable fences, not non-monitored fences. `GetCreationFlags` is a property query, not a progress query, and is not prohibited by this restriction. Non-monitored instances do not report `D3D12_FENCE_FLAG_ALLOW_COMMAND_LIST_BARRIERS` and are not eligible for command list fence barriers.<!-- d3d12-review-inline:end:execution:F-cpu-limits:0:authored:migration-c2ca8aadf2070774-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:F-residency-producer:0:authored:migration-d749740f1c8edbd4-0 -->[`ID3D12Device3::EnqueueMakeResident`](resources.md#enqueue-make-resident) is another fence value producer. Its eligibility and completion rules are defined with residency. Its signal indicates completion of residency work, not completion of the application's GPU accesses to those resources.<!-- d3d12-review-inline:end:execution:F-residency-producer:0:authored:migration-d749740f1c8edbd4-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:XC04-subregion-fence-producer:0:authored:migration-3f053e0632f1a643-0 -->Video encode subregion notification is a distinct fence value producer.
Its [support prerequisites](video-encoding-controls.md#source-s04-003) and
[interval-limited completion and visibility](video-encoding-controls.md#source-s04-009)
are defined by Video encoding controls. These notifications can occur while
the encode continues.<!-- d3d12-review-inline:end:execution:XC04-subregion-fence-producer:0:authored:migration-3f053e0632f1a643-0 --></ins>

<a id="command-list-scoped-fences"></a>

### Command list scoped fences

Command List Scoped fences are fences created with the `D3D12_FENCE_FLAG_ALLOW_COMMAND_LIST_BARRIERS` bit set but without the `D3D12_FENCE_FLAG_ALLOW_QUEUE_AND_CPU_SYNC` bit set. Command List Scoped fences are usable with `ID3D12Fence::Signal` and command list `SignalBarrier` and `WaitBarrier` methods, but cannot support `ID3D12CommandQueue::Wait`, `ID3D12CommandQueue::Signal`, or `ID3D12Fence::SetEventOnCompletion`. Command List Scoped fences are designed to efficiently manage barrier dependencies within a single command list or a set of command lists in the same `ExecuteCommandLists` scope. The primary use for Command List Scoped fences is to perform efficient split barrier operations.

`WaitBarrier` values using Command List Scoped fences must already be satisfied either by the most recent preceding `SignalBarrier` operation in the same command queue or by `ID3D12Fence::Signal` called prior to GPU timeline execution of the submitted command list containing the `WaitBarrier`.

`ID3D12Fence::GetCompletedValue` always returns UINT64_MAX for Command List Scoped fences. Signaling a Command List Scoped fence currently in use in an in-execution command list by other command list, CPU or queue is invalid.

Unlike Monitored fences, Command List Scoped fences are not internally signaled to UINT64_MAX upon device removal. However, `ID3D12Fence::GetCompletedValue` for Command List Scoped fences still returns UINT64_MAX while a device is in a removed state.

<ins><!-- d3d12-review-inline:begin:execution:FB-cl-extra:0:authored:migration-0a1884722d441136-0 -->A CPU `Signal` initializes the scoped fence value before GPU use. It must not race an in-flight scoped fence use. The scalar `GetCompletedValue` result is always `UINT64_MAX`, not a progress measurement. Multi-fence CPU notification also requires CPU-wait-capable fences and cannot observe command list scoped fence completion. Creation/property queries do not turn this mode into an ordinary CPU/queue timeline.<!-- d3d12-review-inline:end:execution:FB-cl-extra:0:authored:migration-0a1884722d441136-0 --></ins>

<a id="create-fence"></a>

### ID3D12Device::CreateFence

#### Declaration

```cpp
HRESULT CreateFence(
    UINT64 InitialValue,
    D3D12_FENCE_FLAGS Flags,
    REFIID riid,
    void** ppFence
);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:execution:create-fence-behavior:0 -->`CreateFence` creates a fence object.<!-- d3d12-review-inline:end:execution:create-fence-behavior:0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:execution:create-fence-parameters:0:modified:migration-e1346751ff758b2f-0 -->**InitialValue**<!-- d3d12-review-inline:end:execution:create-fence-parameters:0:modified:migration-e1346751ff758b2f-0 --></ins>

The initial value for the fence.

<ins><!-- d3d12-review-inline:begin:execution:create-fence-parameters:2 -->**Flags**<!-- d3d12-review-inline:end:execution:create-fence-parameters:2 --></ins>

A combination of [D3D12_FENCE_FLAGS](#fence-flags)-typed values that are combined by using a bitwise OR operation. The resulting value specifies options for the fence.

<ins><!-- d3d12-review-inline:begin:execution:create-fence-parameters:4:modified:migration-977dfb9215832762-0 -->**riid**<!-- d3d12-review-inline:end:execution:create-fence-parameters:4:modified:migration-977dfb9215832762-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:create-fence-parameters:5 -->The globally unique identifier (**GUID**) for the fence interface ([ID3D12Fence](#completion)). The **REFIID**, or **GUID**, of the interface to the fence can be obtained by using the `__uuidof()` macro. For example, `__uuidof(ID3D12Fence)` will get the **GUID** of the interface to a fence.<!-- d3d12-review-inline:end:execution:create-fence-parameters:5 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:create-fence-parameters:6:modified:migration-fbaeb5d0dd98af2b-0 -->**ppFence**<!-- d3d12-review-inline:end:execution:create-fence-parameters:6:modified:migration-fbaeb5d0dd98af2b-0 --></ins>

A pointer to a memory block that receives a pointer to the [ID3D12Fence](#completion) interface that is used to access the fence.

<ins><!-- d3d12-review-inline:begin:execution:F-create-probe:0:authored:migration-c20303f49f952400-0 -->`ppFence` may be `NULL` to check the fence flags without creating a fence object. This path returns `S_FALSE` when flag validation succeeds. It does not establish that object allocation, GPU-accessible backing, or the requested interface would succeed.<!-- d3d12-review-inline:end:execution:F-create-probe:0:authored:migration-c20303f49f952400-0 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:execution:create-fence-returns:0 -->Returns `S_OK` if a fence is created; failures return one of the [Direct3D 12 Return Codes](devices-and-capabilities.md#api-result-codes).<!-- d3d12-review-inline:end:execution:create-fence-returns:0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:F-create-results:0:authored:migration-bbdb6eebd5d980af-0 -->`S_FALSE` is the no-object validation result described above, not a returned fence interface.<!-- d3d12-review-inline:end:execution:F-create-results:0:authored:migration-bbdb6eebd5d980af-0 --></ins>

<a id="fence-creation-flags"></a>

### ID3D12Fence1::GetCreationFlags

#### Declaration

```cpp
D3D12_FENCE_FLAGS GetCreationFlags();
```

#### Return values

<ins><!-- d3d12-review-inline:begin:execution:fence-flags-get-returns:0 -->`GetCreationFlags` returns the flags used to create the fence.<!-- d3d12-review-inline:end:execution:fence-flags-get-returns:0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:FB-effective-properties:0:authored:migration-0a33bf8cd1f99c9d-0 -->The result describes the fence's effective creation properties, not a guarantee that every requested option survived construction. In particular, a non-monitored instance does not report `D3D12_FENCE_FLAG_ALLOW_COMMAND_LIST_BARRIERS`; requesting the bit alone does not make that object barrier eligible. Use the actual properties and capability rules, not the requested mask, to determine eligibility.<!-- d3d12-review-inline:end:execution:FB-effective-properties:0:authored:migration-0a33bf8cd1f99c9d-0 --></ins>

#### Remarks

The flags returned by `GetCreationFlags` are used mainly for opening a shared fence.

<a id="fence-driver-objects"></a>

### Fence driver objects and backing

<a id="fence-creation-descriptions"></a>

#### Fence backing and creation descriptions

```cpp
typedef struct D3D12DDI_FENCE_PLACEMENT
{
    D3DGPU_VIRTUAL_ADDRESS BaseAddress;
} D3D12DDI_FENCE_PLACEMENT;

typedef enum D3D12DDI_FENCE_FLAGS
{
    D3D12DDI_FENCE_FLAG_NONE           = 0x0,
    D3D12DDI_FENCE_FLAG_BOTTOM_OF_PIPE = 0x1,
} D3D12DDI_FENCE_FLAGS;

typedef struct D3D12DDI_FENCE
{
    D3D12DDI_FENCE_PLACEMENT FenceValue;
    D3D12DDI_FENCE_PLACEMENT FenceMonitoredValue;
    D3D12DDI_FENCE_FLAGS Flags;
} D3D12DDI_FENCE;

typedef enum D3D12DDI_FENCE_TYPE_0112 {
   D3D12DDI_FENCE_TYPE_MONITORED = 0,
   D3D12DDI_FENCE_TYPE_NATIVE = 1,
   D3D12DDI_FENCE_TYPE_OPENED_NATIVE = 2,
   D3D12DDI_FENCE_TYPE_COMMAND_LIST_SCOPED = 3,
} D3D12DDI_FENCE_TYPE_0112;
```

<ins><!-- d3d12-review-inline:begin:execution:QF-U02:0:authored:migration-0879b98cbdc4f559-0 -->`FenceValue.BaseAddress` describes the value's GPU placement when supplied.
`FenceMonitoredValue` is a retained, unused placement in this contract. The
runtime supplies a zero `BaseAddress` there. It does not identify a second
usable GPU location.<!-- d3d12-review-inline:end:execution:QF-U02:0:authored:migration-0879b98cbdc4f559-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QF-U03:0:authored:migration-3e3254200de4203f-0 -->`Flags` is also retained and unused in this contract. The declared `NONE`
and `BOTTOM_OF_PIPE` values do not impose additional signal-placement or
ordering behavior. The [queue timeline and ordering rules](execution.md#fence-operations),
not this field, determine operation semantics. In particular, the
`BOTTOM_OF_PIPE` name is not an additional completion guarantee.<!-- d3d12-review-inline:end:execution:QF-U03:0:authored:migration-3e3254200de4203f-0 --></ins>

```cpp
typedef struct D3D12DDI_COMMAND_LIST_SCOPED_FENCE
{
    UINT64 **ppFenceValue;
} D3D12DDI_COMMAND_LIST_SCOPED_FENCE;
```

```cpp

typedef struct D3D12DDIARG_CREATE_FENCE_0116
{
   D3D12DDI_FENCE_TYPE_0112 FenceType;
   union {
      D3D12DDI_FENCE MonitoredFenceArgs;
      D3DKMT_CREATENATIVEFENCE *pNativeFenceArgs;
      D3DKMT_OPENNATIVEFENCEFROMNTHANDLE *pNativeFenceOpenArgs;
      D3D12DDI_COMMAND_LIST_SCOPED_FENCE CLScopedFenceArgs;
   };
} D3D12DDIARG_CREATE_FENCE_0116;
```

<ins><!-- d3d12-review-inline:begin:execution:QF-U05:0:authored:migration-d6e9ffb1e829d7d3-0 -->`FenceType` selects the active union member and the
[creation protocol](#fence-creation-lifecycle). Command list scoped creation
requires the applicable [fence barrier support and API flags](execution.md#fence-flags);
the description's version suffix alone does not establish support for every
fence kind. The [size query rules](#fence-private-sizing) determine which
description fields are valid during sizing, independently of creation.<!-- d3d12-review-inline:end:execution:QF-U05:0:authored:migration-d6e9ffb1e829d7d3-0 --></ins>

<a id="fence-private-sizing"></a>

#### Fence private size queries

```cpp
typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALCPRIVATEFENCESIZE_0116 )( D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATE_FENCE_0116* );
```

<ins><!-- d3d12-review-inline:begin:execution:QF-S03:0:authored:migration-820d6a265bb94d68-0 -->Within the `_0116` creation description supplied to the size query,
only `FenceType` is valid. The remaining payload is zero-initialized, not
a complete creation request. The driver must calculate the size without
consuming creation-only payload data or dereferencing native create,
native open or command list scoped output pointers, where applicable to the selected fence kind. Those pointers are null
in the size query. The applicable creation call supplies its payload later.<!-- d3d12-review-inline:end:execution:QF-S03:0:authored:migration-820d6a265bb94d68-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QF-S04:0:authored:migration-75bf8382e9a49ac7-0 -->For `D3D12DDI_FENCE_TYPE_OPENED_NATIVE`, the returned size must accommodate
both opened-native and monitored fence creation. The runtime may use that
same private allocation for `D3D12DDI_FENCE_TYPE_MONITORED` creation after a
failed native open attempt, without another size query or reallocation.
This requirement does not make the reported sizes identical for every
fence kind or device. It requires the opened-native size result to cover
both of these possible uses.<!-- d3d12-review-inline:end:execution:QF-S04:0:authored:migration-75bf8382e9a49ac7-0 --></ins>

<a id="fence-creation-lifecycle"></a>

#### Fence creation and destruction

<ins><!-- d3d12-review-inline:begin:execution:QF-FN03:0:authored:migration-3c2dde70f644169a-0 -->The following DDIs initialize or destroy UMD fence state. A CreateFence DDI
is also used to initialize a driver object for an opened shared fence. Its
name does not mean that every invocation creates a new OS synchronization
object. The runtime selects the form from the negotiated device table and
the representation from the OS/device fence capabilities and application
request. The function pointer revision alone does not choose `FenceType`.<!-- d3d12-review-inline:end:execution:QF-FN03:0:authored:migration-3c2dde70f644169a-0 --></ins>

```cpp

typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATEFENCE_0116 )( D3D12DDI_HDEVICE, D3D12DDI_HFENCE, D3D12DDI_HRTFENCE, _In_ CONST D3D12DDIARG_CREATE_FENCE_0116* );

typedef VOID ( APIENTRY* PFND3D12DDI_DESTROYFENCE )( D3D12DDI_HDEVICE, D3D12DDI_HFENCE );
```

<ins><!-- d3d12-review-inline:begin:execution:QF-FN05:0:authored:migration-6448b71e13625df4-0 -->The runtime supplies private fence storage aligned to 16 bytes on Win64 and 8 bytes on Win32. The driver initializes it and must not free it.<!-- d3d12-review-inline:end:execution:QF-FN05:0:authored:migration-6448b71e13625df4-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QF-FN06:0:authored:migration-3980bf27fea3264e-0 -->The monitored payload's `D3D12DDI_FENCE` contains `FenceValue` and
`FenceMonitoredValue` GPU VA placements and `Flags`. In the runtime's
monitored fence creation path, `FenceValue.BaseAddress` supplies the available
GPU address, `FenceMonitoredValue.BaseAddress` is zero and `Flags` is
`D3D12DDI_FENCE_FLAG_BOTTOM_OF_PIPE`. A zero value address supplies no GPU
backing location; driver object creation alone does not establish that a
fence can be used by a GPU fence barrier.<!-- d3d12-review-inline:end:execution:QF-FN06:0:authored:migration-3980bf27fea3264e-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QF-FN07:0:authored:migration-38ebe97c125051e9-0 -->Creation receives `D3D12DDI_HRTFENCE`, the runtime fence association used
by the native callbacks. `FenceType` selects the creation payload.<!-- d3d12-review-inline:end:execution:QF-FN07:0:authored:migration-38ebe97c125051e9-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QF-FN08:0:authored:migration-3256511caa611235-0 -->For the callback that creates or opens this runtime-associated native fence,
the UMD supplies the received `hRTFence`. A null callback association instead
denotes a separate UMD-internal object, with the distinct ownership described
in the [native callback contract](#native-fence-callbacks).<!-- d3d12-review-inline:end:execution:QF-FN08:0:authored:migration-3256511caa611235-0 --></ins>

<!-- d3d12-review-alert:begin:execution:QF-FN09:0:authored:migration-19afd8ac24e64ce9-0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | `FenceType` | Creation payload and UMD responsibility |
> |---|---|
> | `D3D12DDI_FENCE_TYPE_MONITORED` | Consume `MonitoredFenceArgs`, the runtime-supplied monitored backing description. The runtime manages the associated OS synchronization object. |
> | `D3D12DDI_FENCE_TYPE_NATIVE` | Use `pNativeFenceArgs` with the native create callback to create the OS object and obtain its handle/mappings. |
> | `D3D12DDI_FENCE_TYPE_OPENED_NATIVE` | Follow the versioned shared open protocol below. Do not treat an opened fence as a fresh native create request. |
> | `D3D12DDI_FENCE_TYPE_COMMAND_LIST_SCOPED` | Return the scoped CPU value address through `CLScopedFenceArgs.ppFenceValue`, as defined below. |

<!-- d3d12-review-alert:end:execution:QF-FN09:0:authored:migration-19afd8ac24e64ce9-0 -->

<ins><!-- d3d12-review-inline:begin:execution:QF-FN10:0:authored:migration-0e3132105b0b7fe4-0 -->`pNativeFenceOpenArgs` supplies the shared open request, and the UMD
calls the native open callback to perform the open and exchange private data.
The [native callback ownership and failure rules](#native-fence-callbacks)
apply. An opened-native failure and monitored retry must also satisfy the
[sizing envelope](#fence-private-sizing).<!-- d3d12-review-inline:end:execution:QF-FN10:0:authored:migration-0e3132105b0b7fe4-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QF-FN11:0:authored:migration-c8177635598329ef-0 -->The driver unwinds failed fence creation. Successfully created fence objects receive destruction, including when later runtime initialization fails. DestroyFence releases driver-owned state without freeing runtime-supplied storage or runtime-owned OS objects.<!-- d3d12-review-inline:end:execution:QF-FN11:0:authored:migration-c8177635598329ef-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QF-FN12:0:authored:migration-b801520f175964de-0 -->The runtime calls DestroyFence before releasing its associated OS object
ownership. Monitored, native and command list scoped representations have
driver-visible objects on these paths. A runtime-managed legacy non-monitored
fence does not imply a UMD CreateFence/DestroyFence pair. A size query alone
does not commit the runtime to subsequently creating a driver object.
Application [fence lifetimes and operation restrictions](execution.md#completion)
remain separate from this transport selection.<!-- d3d12-review-inline:end:execution:QF-FN12:0:authored:migration-b801520f175964de-0 --></ins>

<a id="scoped-fence-output"></a>

#### Command list scoped fence output

<ins><!-- d3d12-review-inline:begin:execution:QF-FN13:0:authored:migration-1bb29e7507d06fe9-0 -->For command list scoped creation, `CLScopedFenceArgs` supplies the output
description defined in [Fence backing and creation descriptions](#fence-creation-descriptions).<!-- d3d12-review-inline:end:execution:QF-FN13:0:authored:migration-1bb29e7507d06fe9-0 --></ins>

Unlike other fence creation DDI args, the `D3D12DDI_COMMAND_LIST_SCOPED_FENCE` arguments have an output parameter, expecting the driver to provide the CPU address of the CL-scoped fence. The <ins><!-- d3d12-review-inline:begin:execution:QF-FI01:0:modified:migration-4b949dd40f831140-0 -->driver-provided<!-- d3d12-review-inline:end:execution:QF-FI01:0:modified:migration-4b949dd40f831140-0 --></ins> address contains the most current CL-Scoped fence value at the start and <ins><!-- d3d12-review-inline:begin:execution:QF-FI01:0:modified:migration-ef96ba95f59d6d84-1 -->end of<!-- d3d12-review-inline:end:execution:QF-FI01:0:modified:migration-ef96ba95f59d6d84-1 --></ins> command buffer execution. It is not expected that this address is updated as the fence is signaled during command buffer execution on the GPU.

<ins><!-- d3d12-review-inline:begin:execution:QF-FN15:0:authored:migration-8d680db6182022ac-0 -->Successful scoped creation must write a non-null, suitably aligned, writable
`UINT64` value address through `ppFenceValue`. The runtime writes the
application's initial fence value to that slot after the UMD creation DDI
succeeds, and uses the slot for CPU Signal operations. The UMD must ensure
the backing remains valid until fence destruction. The output cannot refer
to temporary storage that expires when the creation call returns. This does
not require one particular allocation mechanism or transfer ownership of
UMD-managed backing to the runtime.<!-- d3d12-review-inline:end:execution:QF-FN15:0:authored:migration-8d680db6182022ac-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QF-FN16:0:authored:migration-509b5028b1887d6d-0 -->The command list scoped fence value address is not a live output during sizing. See [private sizing](#fence-private-sizing).<!-- d3d12-review-inline:end:execution:QF-FN16:0:authored:migration-509b5028b1887d6d-0 --></ins>

<a id="native-fence-callbacks"></a>

#### Native fence creation and opening callbacks

<ins><!-- d3d12-review-inline:begin:execution:QF-C01:0:authored:migration-eb7a4fba4345b77e-0 -->The native fence callbacks create or open OS synchronization objects and exchange private data with the KMD.<!-- d3d12-review-inline:end:execution:QF-C01:0:authored:migration-eb7a4fba4345b77e-0 --></ins>

```cpp
typedef HRESULT (APIENTRY CALLBACK *PFND3D12DDI_CREATENATIVEFENCE_CB_0112)(
    D3D12DDI_HRTDEVICE hRTDevice,
    D3D12DDI_HRTFENCE hRTFence,
    _Inout_ D3DKMT_CREATENATIVEFENCE *pArgs
);

typedef HRESULT (APIENTRY CALLBACK *PFND3D12DDI_OPENNATIVEFENCE_CB_0116)(
    D3D12DDI_HRTDEVICE hRTDevice,
    D3D12DDI_HRTFENCE hRTFence,
    _Inout_ D3DKMT_OPENNATIVEFENCEFROMNTHANDLE *pArgs
);
```

<ins><!-- d3d12-review-inline:begin:execution:QF-C03:0:authored:migration-36a40f919fbd1360-0 -->`hRTDevice` identifies the runtime device context for the operation.
`hRTFence` optionally associates the result with a runtime fence object;
it is not a UMD private fence handle or the OS synchronization object handle.
`pArgs` carries the native creation request or shared NT handle open request.
On success, the in/out payload returns the OS synchronization object handle,
fence mappings and updated private driver data. The callback's `HRESULT`
reports success or failure of that operation, not success of the enclosing
UMD creation DDI.<!-- d3d12-review-inline:end:execution:QF-C03:0:authored:migration-36a40f919fbd1360-0 --></ins>

<a id="ownership"></a>

##### Ownership

<ins><!-- d3d12-review-inline:begin:execution:QF-C04:0:authored:migration-dd05adadba454ae1-0 -->With a non-null `hRTFence`, the runtime adopts the created or opened OS
synchronization object and owns its release. The UMD owns its driver-side
state and auxiliary allocations, not independent destruction of that
runtime-associated OS object.<!-- d3d12-review-inline:end:execution:QF-C04:0:authored:migration-dd05adadba454ae1-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QF-C05:0:authored:migration-5041d54a932e3b4b-0 -->With a null `hRTFence`, the callbacks may create or open UMD-internal native
fences independently of an application fence object. The UMD is responsible
for eventually releasing the returned OS synchronization object through the
appropriate destruction path; no application fence runtime object will
perform that cleanup.<!-- d3d12-review-inline:end:execution:QF-C05:0:authored:migration-5041d54a932e3b4b-0 --></ins>

<a id="native-fence-creation-failure"></a>

##### Failure after callback success

<ins><!-- d3d12-review-inline:begin:execution:QF-C06:0:authored:migration-1eccc7d1ab3e0e0a-0 -->A successful runtime callback does not commit CreateFence to success. If CreateFence fails, the driver unwinds its state without relying on DestroyFence.<!-- d3d12-review-inline:end:execution:QF-C06:0:authored:migration-1eccc7d1ab3e0e0a-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QF-C07:0:authored:migration-1809760909d56bde-0 -->The runtime releases adopted OS objects when creation is abandoned and before retrying another representation. A retry must meet the [private sizing requirements](#fence-private-sizing).<!-- d3d12-review-inline:end:execution:QF-C07:0:authored:migration-1809760909d56bde-0 --></ins>

<a id="queue-signal"></a>

### ID3D12CommandQueue::Signal

#### Declaration

```cpp
HRESULT Signal(
    ID3D12Fence* pFence,
    UINT64 Value
);
```

#### Behavior

Use this method to set a fence value <ins><!-- d3d12-review-inline:begin:execution:F-queue-signal-behavior:0:modified:migration-11b2d0670be0bc73-0 -->on the queue timeline<!-- d3d12-review-inline:end:execution:F-queue-signal-behavior:0:modified:migration-11b2d0670be0bc73-0 --></ins>. Use [ID3D12Fence::Signal](#fence-signal) to set a fence from the CPU side.

<ins><!-- d3d12-review-inline:begin:execution:F-queue-signal-writable:0:authored:migration-f4ade1f9f85208d5-0 -->The target must be writable. [Read-only status fences](#status-fences) cannot be signaled. Command list scoped fences cannot be used with queue `Signal`.<!-- d3d12-review-inline:end:execution:F-queue-signal-writable:0:authored:migration-f4ade1f9f85208d5-0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:execution:queue-signal-parameters:0 -->**pFence**<!-- d3d12-review-inline:end:execution:queue-signal-parameters:0 --></ins>

A pointer to the [ID3D12Fence](#completion) object.

<ins><!-- d3d12-review-inline:begin:execution:queue-signal-parameters:2 -->**Value**<!-- d3d12-review-inline:end:execution:queue-signal-parameters:2 --></ins>

The value to set the fence to.

#### Return values

This method returns one of the [Direct3D 12 Return Codes](devices-and-capabilities.md#api-result-codes).

<ins><!-- d3d12-review-inline:begin:execution:F-queue-signal-result:0:authored:migration-be169bef254a2f6a-0 -->A successful return on a device that has not failed queues the signal. It does not wait for the GPU to reach it. The completion relationship is defined in [Fence values and timelines](#fence-operations). A [native UMD device failure report](execution.md#native-queue-errors) need not be reflected as failure from this call.<!-- d3d12-review-inline:end:execution:F-queue-signal-result:0:authored:migration-be169bef254a2f6a-0 --></ins>

<a id="queue-waits"></a>

### ID3D12CommandQueue::Wait

#### Declaration

```cpp
HRESULT Wait(
    ID3D12Fence* pFence,
    UINT64 Value
);
```

#### Behavior

Because a wait is being queued, the API returns immediately. It's the command queue that waits (during which time no work is executed) until the fence specified reaches the requested value.

If you want to perform a CPU-side wait (where the calling thread blocks until a fence reaches a particular value), then you should use the [`ID3D12Fence::SetEventOnCompletion`](#id3d12fenceseteventoncompletion) API in conjunction with [`WaitForSingleObject`](https://learn.microsoft.com/en-us/windows/win32/api/synchapi/nf-synchapi-waitforsingleobject) (or a similar API).

#### Parameters

<ins><!-- d3d12-review-inline:begin:execution:queue-wait-parameters:0 -->**pFence**<!-- d3d12-review-inline:end:execution:queue-wait-parameters:0 --></ins>

A pointer to the [ID3D12Fence](#completion) object.

<ins><!-- d3d12-review-inline:begin:execution:queue-wait-parameters:2 -->**Value**<!-- d3d12-review-inline:end:execution:queue-wait-parameters:2 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:queue-wait-parameters:3 -->The value that the command queue is waiting for the fence to reach or exceed.<!-- d3d12-review-inline:end:execution:queue-wait-parameters:3 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:F-queue-wait-observation:0:authored:migration-7698426f1f78e960-0 -->The threshold refers to the fence's synchronization value, not to a sentinel from an invalid CPU query. See [CPU observation restrictions](#fence-flags) and [device removal interpretation](#completion-lifetime). Command list scoped fences cannot be used with queue `Wait`.<!-- d3d12-review-inline:end:execution:F-queue-wait-observation:0:authored:migration-7698426f1f78e960-0 --></ins>

#### Return values

This method returns one of the [Direct3D 12 Return Codes](devices-and-capabilities.md#api-result-codes).

<ins><!-- d3d12-review-inline:begin:execution:QF-wait-error-result:0:authored:migration-75a57957a442e24e-0 -->A [native UMD device failure report](execution.md#native-queue-errors)
need not be reflected in a failing return from this call; device status and
the API's `HRESULT` remain distinct observations.<!-- d3d12-review-inline:end:execution:QF-wait-error-result:0:authored:migration-75a57957a442e24e-0 --></ins>

<a id="queue-signal-wait"></a>

### Queue Signal and Wait DDIs

<ins><!-- d3d12-review-inline:begin:execution:QF-T01:0:authored:migration-848bc7d31fcecf81-0 -->`PFND3D12DDI_SIGNAL_FENCE` and `PFND3D12DDI_WAIT_FOR_FENCE` receive the driver
queue handle and a fence operation description. `Fence` and `Value` identify
the requested fence operation. `PhysicalAdapterMask` is an output used by the
runtime-broadcast path described below. These DDIs return no `HRESULT`;
their signatures are not the application methods' return value contract.
The [application fence timelines and queue ordering](execution.md#fence-operations)
remain applicable. These are UMD queue DDI contracts;
[synchronization-only queues](execution.md#synchronization-only-queues)
use their runtime-managed path rather than a UMD command queue object.<!-- d3d12-review-inline:end:execution:QF-T01:0:authored:migration-848bc7d31fcecf81-0 --></ins>

```cpp
typedef struct D3D12DDIARG_FENCE_OPERATION
{
    D3D12DDI_HFENCE Fence;
    UINT64 Value;
    UINT PhysicalAdapterMask;
} D3D12DDIARG_FENCE_OPERATION;

typedef void( APIENTRY* PFND3D12DDI_SIGNAL_FENCE )( D3D12DDI_HCOMMANDQUEUE, D3D12DDIARG_FENCE_OPERATION*);
typedef void( APIENTRY* PFND3D12DDI_WAIT_FOR_FENCE )( D3D12DDI_HCOMMANDQUEUE, D3D12DDIARG_FENCE_OPERATION*);
```

<ins><!-- d3d12-review-inline:begin:execution:QF-T03:0:authored:migration-4190a55c3e135e65-0 -->For native fences, the UMD is responsible for the requested signal or wait,
using the appropriate runtime/OS handoff or driver-submitted GPU operation
for the submission mode. The runtime does not append another kernel
signal/wait operation after this DDI, and ignores `PhysicalAdapterMask` on
this path. Before returning, the UMD must have queued the operation or
arranged its submission without requiring another application call.
Return does not establish GPU completion. This submission requirement does
not make a wait independent of the producers that can satisfy its threshold.<!-- d3d12-review-inline:end:execution:QF-T03:0:authored:migration-4190a55c3e135e65-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QF-T04:0:authored:migration-b8b86a83569a0762-0 -->For non-native fences, implicit multi-GPU handling can invoke the same DDIs
to obtain the physical adapter broadcast scope. The runtime then submits the
corresponding operation using the selected kernel contexts or hardware
queues. Other ordinary non-native paths can submit through the runtime
without invoking these DDIs. There is no universal one-to-one API/DDI/kernel
call sequence.<!-- d3d12-review-inline:end:execution:QF-T04:0:authored:migration-b8b86a83569a0762-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QF-T05:0:authored:migration-1db76fe807fd7167-0 -->On that non-native runtime-broadcast path, mask bits select underlying
physical adapters, not the application's `NodeMask`. The UMD must return a
mask selecting at least one eligible physical adapter context or hardware
queue for the requested operation. A zero mask or an otherwise empty eligible
target set is not a supported way to suppress the runtime broadcast. This
output requirement does not apply to the ignored mask on the native path.<!-- d3d12-review-inline:end:execution:QF-T05:0:authored:migration-1db76fe807fd7167-0 --></ins>

<a id="native-queue-errors"></a>

#### Failure reporting for native operations

<ins><!-- d3d12-review-inline:begin:execution:QF-E01:0:authored:migration-2b0c878e236238b2-0 -->The native UMD Signal/Wait path does not provide a recoverable operation error
channel. If the UMD cannot arrange the requested operation, it must report
device failure through the callback `PFND3D12DDI_SETERROR_CB`.
An out-of-memory condition is not a recoverable UMD operation result on this
path. This is device failure reporting, not a command list recording error
deferred until Close.<!-- d3d12-review-inline:end:execution:QF-E01:0:authored:migration-2b0c878e236238b2-0 --></ins>

```cpp
typedef VOID (APIENTRY CALLBACK *PFND3D12DDI_SETERROR_CB)( D3D10DDI_HRTDEVICE, HRESULT );
```

<ins><!-- d3d12-review-inline:begin:execution:QF-E03:0:authored:migration-691b6c4338db954e-0 -->The first callback argument identifies the runtime device context. The
second is the reported failure `HRESULT`. The legacy device handle spelling
in the released typedef does not change this callback's D3D12 runtime role.
For these native operation DDIs, the callback reports device failure rather
than supplying a recoverable operation result. Other DDIs' error contracts
remain specific to their own call sites.<!-- d3d12-review-inline:end:execution:QF-E03:0:authored:migration-691b6c4338db954e-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QF-E04:0:authored:migration-56ceba67010c0a99-0 -->A synchronous device failure report does not guarantee that the original
application Signal/Wait call returns a failing `HRESULT`. It does not
guarantee `S_OK` either. Device removal is observed through
[GetDeviceRemovedReason](diagnostics.md#id3d12device-getdeviceremovedreason)
and the established [completion/removal notification rules](execution.md#completion-lifetime),
independently of that return. A successful return is not proof of a healthy
device or successful GPU execution.<!-- d3d12-review-inline:end:execution:QF-E04:0:authored:migration-56ceba67010c0a99-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QF-E05:0:authored:migration-890f8c01500d0674-0 -->The runtime's own validation and non-native transport work may still return
their normal `HRESULT` failures, including recoverable allocation failures.
The native UMD failure model must not be generalized into a device-fatal
interpretation of every application Signal/Wait error.<!-- d3d12-review-inline:end:execution:QF-E05:0:authored:migration-890f8c01500d0674-0 --></ins>

<a id="fence-signal"></a>

### ID3D12Fence::Signal

#### Declaration

```cpp
HRESULT Signal(
    UINT64 Value
);
```

#### Behavior

Use this method to set a fence value from the CPU side. Use [ID3D12CommandQueue::Signal](#queue-signal) to set a fence from the GPU side.

<ins><!-- d3d12-review-inline:begin:execution:F-cpu-signal-completion:0:authored:migration-564976ee239c6b0b-0 -->CPU signaling does not wait for preceding GPU work. A CPU-written value is therefore not evidence that unrelated queued work has completed. This method must not be used on [read-only status fences](#status-fences). For command list scoped fences, CPU signaling is only an initialization before the relevant GPU use, not an in-flight signaling operation.<!-- d3d12-review-inline:end:execution:F-cpu-signal-completion:0:authored:migration-564976ee239c6b0b-0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:execution:fence-signal-parameters:0 -->**Value**<!-- d3d12-review-inline:end:execution:fence-signal-parameters:0 --></ins>

The value to set the fence to.

#### Return values

This method returns one of the [Direct3D 12 Return Codes](devices-and-capabilities.md#api-result-codes).

<a id="id3d12fencegetcompletedvalue"></a>

### ID3D12Fence::GetCompletedValue

#### Declaration

```cpp
UINT64 GetCompletedValue();
```

<a id="fence-completed-value"></a>

#### Return values

Returns the current value of the fence. If the device has been removed, the return value will be `UINT64_MAX`.

<ins><!-- d3d12-review-inline:begin:execution:F-completed-scope:0:authored:migration-e15bc1867be3224f-0 -->The CPU observation restrictions in [Fence options](#fence-flags) apply. An observed [status fence counter](#status-fences) tracks protected content validity changes, not GPU work completion. For device removal interpretation, see [Completion, device removal, and lifetime](#completion-lifetime). Command list scoped fences also return a constant sentinel, as defined [above](#command-list-scoped-fences).<!-- d3d12-review-inline:end:execution:F-completed-scope:0:authored:migration-e15bc1867be3224f-0 --></ins>

<a id="id3d12fenceseteventoncompletion"></a>

### ID3D12Fence::SetEventOnCompletion

#### Declaration

```cpp
HRESULT SetEventOnCompletion(
    UINT64 Value,
    HANDLE hEvent
);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:execution:F-event-behavior:0 -->`SetEventOnCompletion` specifies an event that's raised when the fence reaches a certain value.<!-- d3d12-review-inline:end:execution:F-event-behavior:0 --></ins>

If <ins><!-- d3d12-review-inline:begin:execution:P24:0:modified:migration-c301e3361293b4d7-0 -->`hEvent`<!-- d3d12-review-inline:end:execution:P24:0:modified:migration-c301e3361293b4d7-0 --></ins> is a null handle, then this API will not return until the <ins><!-- d3d12-review-inline:begin:execution:P24:0:modified:migration-5e7648adfc8a8e45-1 -->specified fence value has been reached<!-- d3d12-review-inline:end:execution:P24:0:modified:migration-5e7648adfc8a8e45-1 --></ins>.

This method can be safely called from multiple threads at one time.

#### Parameters

<ins><!-- d3d12-review-inline:begin:execution:event-parameters:0 -->**Value**<!-- d3d12-review-inline:end:execution:event-parameters:0 --></ins>

The fence value when the event is to be signaled.

<ins><!-- d3d12-review-inline:begin:execution:event-parameters:2 -->**hEvent**<!-- d3d12-review-inline:end:execution:event-parameters:2 --></ins>

A handle to the event object.

#### Return values

<ins><!-- d3d12-review-inline:begin:execution:event-returns:0 -->This method returns `E_OUTOFMEMORY` if the kernel components don’t have sufficient memory to store the event in a list. See [Direct3D 12 return codes](devices-and-capabilities.md#api-result-codes) for other possible return values.<!-- d3d12-review-inline:end:execution:event-returns:0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:F-event-results:0:authored:migration-9a79c1a63a5eb695-0 -->With a non-NULL event, successful registration is not itself a CPU wait for completion. With `hEvent == NULL`, the blocking behavior describes a successful wait. An error can return without establishing completion. Device removal can also satisfy a notification, as described [below](#completion-lifetime). For system-controlled status fences, the [status interpretation](#status-fences) also applies. [Command list scoped fences](#command-list-scoped-fences) do not support this notification.<!-- d3d12-review-inline:end:execution:F-event-results:0:authored:migration-9a79c1a63a5eb695-0 --></ins>

<a id="multiple-fence-completion"></a>

### ID3D12Device1::SetEventOnMultipleFenceCompletion

#### Declaration

```cpp
HRESULT SetEventOnMultipleFenceCompletion(
    ID3D12Fence* const* ppFences,
    const UINT64* pFenceValues,
    UINT NumFences,
    D3D12_MULTIPLE_FENCE_WAIT_FLAGS Flags,
    HANDLE hEvent
);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:execution:multi-event-behavior:0 -->`SetEventOnMultipleFenceCompletion` specifies an event that should be fired when one or more of a collection of fences reach specific values.<!-- d3d12-review-inline:end:execution:multi-event-behavior:0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:execution:multi-event-parameters:0:modified:migration-27f93ff1238dd96d-0 -->**ppFences**<!-- d3d12-review-inline:end:execution:multi-event-parameters:0:modified:migration-27f93ff1238dd96d-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:multi-event-parameters:1 -->An array of length `NumFences` that specifies the [ID3D12Fence](#completion) objects.<!-- d3d12-review-inline:end:execution:multi-event-parameters:1 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:multi-event-parameters:2:modified:migration-4dc98c9ec1764557-0 -->**pFenceValues**<!-- d3d12-review-inline:end:execution:multi-event-parameters:2:modified:migration-4dc98c9ec1764557-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:multi-event-parameters:3 -->An array of length `NumFences` that specifies the fence values required for the event to be signaled.<!-- d3d12-review-inline:end:execution:multi-event-parameters:3 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:multi-event-parameters:4:modified:migration-d4dd91c9fa12131a-0 -->**NumFences**<!-- d3d12-review-inline:end:execution:multi-event-parameters:4:modified:migration-d4dd91c9fa12131a-0 --></ins>

Specifies the number of fences to be included.

<ins><!-- d3d12-review-inline:begin:execution:multi-event-parameters:6 -->**Flags**<!-- d3d12-review-inline:end:execution:multi-event-parameters:6 --></ins>

Specifies one of the [D3D12_MULTIPLE_FENCE_WAIT_FLAGS](#multiple-fence-flags) that determines how to proceed.

<ins><!-- d3d12-review-inline:begin:execution:multi-event-parameters:8 -->**hEvent**<!-- d3d12-review-inline:end:execution:multi-event-parameters:8 --></ins>

A handle to the event object.

<ins><!-- d3d12-review-inline:begin:execution:F-event-pairs:0:authored:migration-1175546ac8bfc5d6-0 -->`pFenceValues[i]` is the threshold for `ppFences[i]`. Both arrays contain `NumFences` entries. The arrays describe the registration and are consumed by the call, not retained as application memory for later GPU use.<!-- d3d12-review-inline:end:execution:F-event-pairs:0:authored:migration-1175546ac8bfc5d6-0 --></ins>

<a id="multiple-fence-flags"></a>

#### Wait selection

```cpp
typedef enum D3D12_MULTIPLE_FENCE_WAIT_FLAGS
{
    D3D12_MULTIPLE_FENCE_WAIT_FLAG_NONE = 0x0,
    D3D12_MULTIPLE_FENCE_WAIT_FLAG_ANY = 0x1,

    D3D12_MULTIPLE_FENCE_WAIT_FLAG_ALL = 0x0, // Alias, default behavior is ALL
} D3D12_MULTIPLE_FENCE_WAIT_FLAGS;
```

<!-- d3d12-review-alert:begin:execution:wait-flags-meanings:0:modified:migration-ebd4dc0393580648-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Flag | Value | Meaning |
> |---|---|---|
> | `D3D12_MULTIPLE_FENCE_WAIT_FLAG_NONE` | `0` | No flags are being passed. This means to use the default behavior, which is to wait for all fences before signaling the event. |
> | `D3D12_MULTIPLE_FENCE_WAIT_FLAG_ANY` | `0x1` | Modifies behavior to indicate that the event should be signaled after any one of the fence values has been reached by its corresponding fence. |
> | `D3D12_MULTIPLE_FENCE_WAIT_FLAG_ALL` | `0` | An alias for `D3D12_MULTIPLE_FENCE_WAIT_FLAG_NONE`, meaning to use the default behavior and wait for all fences. |

<!-- d3d12-review-alert:end:execution:wait-flags-meanings:0:modified:migration-ebd4dc0393580648-0 -->

#### Blocking and return values

If <ins><!-- d3d12-review-inline:begin:execution:F-multi-null:0:modified:migration-4a36bb2632342c58-0 -->`hEvent`<!-- d3d12-review-inline:end:execution:F-multi-null:0:modified:migration-4a36bb2632342c58-0 --></ins> is a null handle, then this API will not return until the <ins><!-- d3d12-review-inline:begin:execution:F-multi-null:0:modified:migration-4c710cc3c3eea8fa-1 -->selected ANY/ALL fence condition has been satisfied<!-- d3d12-review-inline:end:execution:F-multi-null:0:modified:migration-4c710cc3c3eea8fa-1 --></ins>.

This method returns an HRESULT success or error code.

<ins><!-- d3d12-review-inline:begin:execution:F-multi-errors:0:authored:migration-216818c29b2731cb-0 -->Unrecognized `Flags` bits return `E_INVALIDARG`. Storage allocation can fail with `E_OUTOFMEMORY`. Successful non-NULL registration and blocking NULL event use have the same completion/error distinction as [single-fence notification](#id3d12fenceseteventoncompletion). Read-only status fence inputs retain their [status interpretation](#status-fences). Command list scoped fences are not CPU-wait-capable inputs.<!-- d3d12-review-inline:end:execution:F-multi-errors:0:authored:migration-216818c29b2731cb-0 --></ins>

<a id="completion-lifetime"></a>

### Completion, device removal, and lifetime

<ins><!-- d3d12-review-inline:begin:execution:F-removal:0 -->The full [`ID3D12Device::GetDeviceRemovedReason` contract](diagnostics.md#id3d12device-getdeviceremovedreason) defines device removal status. To be called back when a device is removed, consider using [ID3D12Fence::SetEventOnCompletion](#id3d12fenceseteventoncompletion) with a value of `UINT64_MAX`. That's because device removal causes CPU-wait-capable fences to be signaled to that value (which also implies completing all events waited on, because their thresholds are at most `UINT64_MAX`).<!-- d3d12-review-inline:end:execution:F-removal:0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:F-removal-lifetime:0:authored:migration-f6f8b21626deaa77-0 -->An event becoming signaled or a fence reading `UINT64_MAX` is not by itself proof of successful GPU execution. Check device status rather than interpreting removal-induced notification as normally completed rendering or valid output data.<!-- d3d12-review-inline:end:execution:F-removal-lifetime:0:authored:migration-f6f8b21626deaa77-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:F-removal-lifetime:1:authored:migration-147abd771401b522-0 -->A completion value is useful for storage reuse only when its signal follows the relevant work and competing CPU/queue signals cannot satisfy the same threshold prematurely. Apply the [allocator storage](#command-storage) and [resource lifetime](#lifetime) requirements. Neither API return nor list Reset is a completion proof.<!-- d3d12-review-inline:end:execution:F-removal-lifetime:1:authored:migration-147abd771401b522-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:F-removal-lifetime:2:authored:migration-0c2ba1b72e47fcfb-0 -->`hEvent` names an application-supplied Windows event, not an event created by these D3D12 methods. Event handle ownership and CPU waits follow the [Windows event object contract](https://learn.microsoft.com/en-us/windows/win32/sync/event-objects). These notifications do not retain unrelated resources referenced by recorded GPU work.<!-- d3d12-review-inline:end:execution:F-removal-lifetime:2:authored:migration-0c2ba1b72e47fcfb-0 --></ins>

<a id="driver-synchronization-transport"></a>

### Driver synchronization transport

<a id="internal-sync-objects"></a>

#### Driver-owned synchronization objects

```cpp
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_CREATESYNCHRONIZATIONOBJECTCB)(
    _In_ HANDLE hDevice, _Inout_ D3DDDICB_CREATESYNCHRONIZATIONOBJECT*);
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_CREATESYNCHRONIZATIONOBJECT2CB)(
    _In_ HANDLE hDevice, _Inout_ D3DDDICB_CREATESYNCHRONIZATIONOBJECT2*);
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_DESTROYSYNCHRONIZATIONOBJECTCB)(
    _In_ HANDLE hDevice, _In_ CONST D3DDDICB_DESTROYSYNCHRONIZATIONOBJECT*);
```

<ins><!-- d3d12-review-inline:begin:execution:QT-N16:0:authored:migration-8b35b29a82f84105-0 -->The creation callbacks take `Info` describing the synchronization object
type and attributes and return its OS `hSyncObject`. The `2` form carries
the extended object information, including monitored fence mappings where
applicable. The UMD manages its internal object's lifetime and releases
its OS handle through DestroySynchronizationObject.<!-- d3d12-review-inline:end:execution:QT-N16:0:authored:migration-8b35b29a82f84105-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QT-N17:0:authored:migration-bd2111b98a8510e8-0 -->This ownership is not permission to independently destroy an OS object
adopted by a runtime fence. That separate
[native fence association and cleanup contract](execution.md#native-fence-callbacks)
continues to apply even when the UMD knows the OS handle.<!-- d3d12-review-inline:end:execution:QT-N17:0:authored:migration-bd2111b98a8510e8-0 --></ins>

<a id="context-sync-callbacks"></a>

#### Context stream and CPU synchronization

```cpp
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_WAITFORSYNCHRONIZATIONOBJECTCB)(
    _In_ HANDLE hDevice, _In_ CONST D3DDDICB_WAITFORSYNCHRONIZATIONOBJECT*);
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_SIGNALSYNCHRONIZATIONOBJECTCB)(
    _In_ HANDLE hDevice, _In_ CONST D3DDDICB_SIGNALSYNCHRONIZATIONOBJECT*);
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_WAITFORSYNCHRONIZATIONOBJECT2CB)(
    _In_ HANDLE hDevice, _In_ CONST D3DDDICB_WAITFORSYNCHRONIZATIONOBJECT2*);
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_SIGNALSYNCHRONIZATIONOBJECT2CB)(
    _In_ HANDLE hDevice, _In_ CONST D3DDDICB_SIGNALSYNCHRONIZATIONOBJECT2*);
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_WAITFORSYNCHRONIZATIONOBJECTFROMCPUCB)(
    _In_ HANDLE hDevice, _In_ CONST D3DDDICB_WAITFORSYNCHRONIZATIONOBJECTFROMCPU*);
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_SIGNALSYNCHRONIZATIONOBJECTFROMCPUCB)(
    _In_ HANDLE hDevice, _In_ CONST D3DDDICB_SIGNALSYNCHRONIZATIONOBJECTFROMCPU*);
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_WAITFORSYNCHRONIZATIONOBJECTFROMGPUCB)(
    _In_ HANDLE hDevice, _In_ CONST D3DDDICB_WAITFORSYNCHRONIZATIONOBJECTFROMGPU*);
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_SIGNALSYNCHRONIZATIONOBJECTFROMGPUCB)(
    _In_ HANDLE hDevice, _In_ CONST D3DDDICB_SIGNALSYNCHRONIZATIONOBJECTFROMGPU*);
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_SIGNALSYNCHRONIZATIONOBJECTFROMGPU2CB)(
    _In_ HANDLE hDevice, _In_ CONST D3DDDICB_SIGNALSYNCHRONIZATIONOBJECTFROMGPU2*);
```

<!-- d3d12-review-alert:begin:execution:QT-N19:0:authored:migration-034ab6b344d1aec9-0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Family | Input and operation |
> |---|---|
> | `WaitForSynchronizationObjectCB` / `SignalSynchronizationObjectCB` | Supply `hContext`, an OS object array and `ObjectCount`; wait or signal in that context stream. Signal also carries its operation flags. |
> | `WaitForSynchronizationObject2CB` | Adds the object-type-specific `FenceValue` threshold to the context/object request. |
> | `SignalSynchronizationObject2CB` | Adds broadcast contexts and a flags-selected fence value or CPU event payload. `Flags.EnqueueCpuEvent` selects `CpuEventHandle`, not `FenceValue`. |
> | `WaitForSynchronizationObjectFromCpuCB` | Supply OS object/value arrays, flags and optional `hAsyncEvent`. On a usable device, null selects a blocking CPU wait. A non-null event requests notification when the wait condition is satisfied. This is not a queued GPU wait. |
> | `SignalSynchronizationObjectFromCpuCB` | Supply OS object/value arrays for CPU-side signaling. It is not insertion of a signal after prior work in a GPU context. |
> | `WaitForSynchronizationObjectFromGpuCB` | Supply `hContext`, OS objects and the object-type-selected scalar or monitored fence threshold array for a context stream wait. |
> | `SignalSynchronizationObjectFromGpuCB` | Supply `hContext`, OS objects and monitored fence values for GPU stream signaling. |
> | `SignalSynchronizationObjectFromGpu2CB` | Uses a counted broadcast-context array and an object type/flags-selected scalar value, monitored value array or CPU event. It is not interchangeable with the single-context form's payload. |

<!-- d3d12-review-alert:end:execution:QT-N19:0:authored:migration-034ab6b344d1aec9-0 -->

<a id="hardware-queue-sync"></a>

#### Hardware queue synchronization

```cpp
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_SUBMITWAITFORSYNCOBJECTSTOHWQUEUECB)(
    _In_ HANDLE hDevice, _In_ CONST D3DDDICB_SUBMITWAITFORSYNCOBJECTSTOHWQUEUE*);
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_SUBMITSIGNALSYNCOBJECTSTOHWQUEUECB)(
    _In_ HANDLE hDevice, _In_ CONST D3DDDICB_SUBMITSIGNALSYNCOBJECTSTOHWQUEUE*);
```

<ins><!-- d3d12-review-inline:begin:execution:QT-N22:0:authored:migration-27dd8c34d53b0527-0 -->The wait callback supplies one runtime hardware queue handle and counted
OS object/fence value arrays. The signal callback supplies counted broadcast
hardware queue handles, OS object/value arrays and signal flags. The runtime
translates the hardware queue handles and inserts the corresponding kernel
operations. These callbacks do not release the handles or establish that a
wait has been satisfied or a signal reached by the GPU before return.
The [native versus non-native queue fence routing](execution.md#queue-signal-wait)
determines which party arranges an application's operation.<!-- d3d12-review-inline:end:execution:QT-N22:0:authored:migration-27dd8c34d53b0527-0 --></ins>

<a id="native-shared-callback"></a>

#### Native fence callback selection

```cpp
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_CREATENATIVEFENCECB)(
    _In_ HANDLE hDevice, _Inout_ D3DKMT_CREATENATIVEFENCE*);
```

<ins><!-- d3d12-review-inline:begin:execution:QT-N24:0:authored:migration-a6a144d9688c1d5c-0 -->The D3D12 shared callback table does not supply
`PFND3DDDI_CREATENATIVEFENCECB`. Native fence operations use the
[D3D12 native create/open callbacks](execution.md#native-fence-callbacks)
for the documented associated or UMD-internal native fence operations.
The generic typedef is not an alias for the D3D12 callback with an additional
runtime fence association.<!-- d3d12-review-inline:end:execution:QT-N24:0:authored:migration-a6a144d9688c1d5c-0 --></ins>

<a id="downlevel-sync-callbacks"></a>

#### Downlevel synchronization callback table

```cpp
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3D12DDI_CREATESYNCHRONIZATIONOBJECT2CB)(
    _In_ D3D12DDI_HRTDEVICE hDevice, _Inout_ D3D12DDICB_CREATESYNCHRONIZATIONOBJECT2*);
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3D12DDI_WAITFORSYNCHRONIZATIONOBJECT2CB)(
    _In_ D3D12DDI_HRTDEVICE hDevice, _In_ CONST D3D12DDICB_WAITFORSYNCHRONIZATIONOBJECT2*);
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3D12DDI_SIGNALSYNCHRONIZATIONOBJECT2CB)(
    _In_ D3D12DDI_HRTDEVICE hDevice, _In_ CONST D3D12DDICB_SIGNALSYNCHRONIZATIONOBJECT2*);
```

<ins><!-- d3d12-review-inline:begin:execution:QT-N26:0:authored:migration-bf55ee200ef8ee38-0 -->These three signatures belong to `D3D12DDI_DOWNLEVEL_SUPPORT_CALLBACKS_0054`,
not the ordinary core callback table or the shared `D3DDDI_DEVICECALLBACKS`
slots. When that downlevel table is supplied, use its runtime device handle
and `D3D12DDICB_*` payloads rather than substituting the similarly named
shared callback types.<!-- d3d12-review-inline:end:execution:QT-N26:0:authored:migration-bf55ee200ef8ee38-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:QT-N27:0:authored:migration-75cd42cb943a8fa0-0 -->Creation supplies `Info` and returns the OS `hSyncObject`. Wait supplies
`hContext`, an object array/count and `FenceValue` for a context stream wait.
Signal supplies context/object arrays, broadcast contexts and flags selecting
a fence value or CPU event. The callbacks return an `HRESULT` for the
requested operation. Their separate table ownership
does not imply that every D3D12 device supplies downlevel support.<!-- d3d12-review-inline:end:execution:QT-N27:0:authored:migration-75cd42cb943a8fa0-0 --></ins>

<a id="lifetime"></a>

## Object and resource lifetime

### Reference counting

Most D3D12 APIs continue to use reference counting as per COM
conventions. 1 notable exception to this is the D3D12 command list APIs.
All APIs on <ins><!-- d3d12-review-inline:begin:execution:P25:0:modified:source-617293af6b81c6cf-0-0 -->ID3D12GraphicsCommandList<!-- d3d12-review-inline:end:execution:P25:0:modified:source-617293af6b81c6cf-0-0 --></ins> do not hold references to the objects
passed into those APIs. This means applications are responsible for
ensuring that a command list is never submitted for execution that
references a destroyed resource.

<ins><!-- d3d12-review-inline:begin:execution:DN-execution-lifetime-owner:0:authored:migration-ebe7614c451d77a1-0 -->The [destruction-notifier interface](devices-and-capabilities.md#destruction-notifications)
observes CPU object destruction. Its callbacks and cancellation IDs do not
retain recorded resource uses, prove GPU completion, or replace these
application lifetime requirements.<!-- d3d12-review-inline:end:execution:DN-execution-lifetime-owner:0:authored:migration-ebe7614c451d77a1-0 --></ins>

### Resource lifetime separated from binding

<ins><!-- d3d12-review-inline:begin:execution:P26:0 -->Before freeing any resource, such as a texture, applications must
make sure the GPU has completed referencing it.<!-- d3d12-review-inline:end:execution:P26:0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:FB-resource-last-use:0:authored:migration-bfbb07032bfd9e63-0 -->Completion of the whole command list is sufficient, but is not required when a correctly scoped fence barrier signal proves every GPU use of the resource has completed and no later use remains. This does not permit resetting allocator storage while any recorded stream still uses it.<!-- d3d12-review-inline:end:execution:FB-resource-last-use:0:authored:migration-bfbb07032bfd9e63-0 --></ins>

### CPU/GPU access to mapped memory

<ins><!-- d3d12-review-inline:begin:execution:P27:0 -->Applications have the responsibility to synchronize CPU and GPU memory accesses. To
help with this the system provides mechanisms for the application to
request sleeping of a CPU thread until work completes. Polling could
also be done, but can be wasteful.<!-- d3d12-review-inline:end:execution:P27:0 --></ins>

Resources on CPU-accessible heaps can be persistently mapped, meaning **Map** can be called once, immediately after resource creation. [Unmap](resources.md#resource-unmap) never needs to be called, but the address returned from **Map** must no longer be used after the last reference to the resource is released. When using persistent map, the application must ensure the CPU finishes writing data into memory before the GPU executes a command list that reads or writes the memory. In common scenarios, the application merely must write to memory before calling [ExecuteCommandLists](#execute-command-lists); but using a fence to delay command list execution works as well.
All CPU-accessible memory types support persistent mapping usage, where the resource is mapped but then never unmapped, provided the application does not access the pointer after the resource has been disposed.

### Command list object destruction

Note that applications are allowed to call <ins><!-- d3d12-review-inline:begin:execution:P29:0:modified:source-8c1c17c32891fd98-0-0 -->ID3D12GraphicsCommandList<!-- d3d12-review-inline:end:execution:P29:0:modified:source-8c1c17c32891fd98-0-0 --></ins>::Reset
before previous executions of the associated command list have
completed. Additionally, applications can destroy command lists before
previous executions have completed.

<a id="threading"></a>

## CPU threading

<ins><!-- d3d12-review-inline:begin:execution:P30:0 -->All methods on the device interface are free-threaded.<!-- d3d12-review-inline:end:execution:P30:0 --></ins>

Methods on a specific command list object are not free-threaded with
respect to each other. Applications must ensure that they never
concurrently call methods on the same command list.

Methods on a command allocator are not free-threaded with respect to
each other. Applications must ensure that they never concurrently call
methods on the same command list allocator.

All methods on the command queue are free-threaded.

<ins><!-- d3d12-review-inline:begin:execution:P30:4:modified:source-3e8ffd60ccb0c296-0-0 -->The<!-- d3d12-review-inline:end:execution:P30:4:modified:source-3e8ffd60ccb0c296-0-0 --></ins> D3D12 threading behavior is not configurable.

<a id="driver-responsibilities"></a>

## Driver responsibilities

<ins><!-- d3d12-review-inline:begin:execution:QF-sizing-forward:0:authored:migration-494bb6306c3fc7a1-0 -->Driver fence [private sizing requirements](execution.md#fence-private-sizing)
and [native fence callback ownership and failure cleanup](execution.md#native-fence-callbacks)
are defined in this chapter, alongside
the [queue Signal/Wait transport split](execution.md#queue-signal-wait).
The [native operation error contract](execution.md#native-queue-errors)
distinguishes device failure reporting from the application method's `HRESULT`.<!-- d3d12-review-inline:end:execution:QF-sizing-forward:0:authored:migration-494bb6306c3fc7a1-0 --></ins>

### Threading

Drivers are expected to implement the threading model described in this
document. The one exception is the atomicity of command queue operation.
The D3D12 runtime acquires a lock around all command queue APIs.
Additionally, the runtime acquires the command queue lock around the
DXGI Present and Blt DDIs. Drivers can thus assume that the following
DDI calls are serialized:

- ExecuteCommandLists
- <ins><!-- d3d12-review-inline:begin:execution:P31:1 -->[UpdateTileMappings](resources.md#update-tile-mappings)<!-- d3d12-review-inline:end:execution:P31:1 --></ins>
- <ins><!-- d3d12-review-inline:begin:execution:P31:1 -->[CopyTileMappings](resources.md#copy-tile-mappings)<!-- d3d12-review-inline:end:execution:P31:1 --></ins>

### Command list resource lifetime

The runtime implementation of command lists does not hold references
<ins><!-- d3d12-review-inline:begin:execution:WEF-list-reference-grammar:0 -->to<!-- d3d12-review-inline:end:execution:WEF-list-reference-grammar:0 --></ins> objects (resources, pipeline state objects, queries, etc) used by a
command list. Applications must guarantee that they do not call
<ins><!-- d3d12-review-inline:begin:execution:P32:0:modified:migration-d97db14a47d0fcdb-0 -->ID3D12CommandQueue::ExecuteCommandLists<!-- d3d12-review-inline:end:execution:P32:0:modified:migration-d97db14a47d0fcdb-0 --></ins> if any resource
referenced by the command list has been destroyed. This however does not
guarantee the order of destruction. Drivers must be robust to the case
where a command list is destroyed after the resources that it references
have been destroyed.

<a id="driver-runtime-services"></a>

## Driver presentation services

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_BLT ) ( D3D12DDI_HCOMMANDLIST, _In_ CONST D3D12DDIARG_BLT* );

typedef struct D3D12DDIARG_BLT
{
    D3D12DDI_HRESOURCE          hDstResource;
    UINT                        DstSubresource;
    UINT                        DstLeft;
    UINT                        DstTop;
    UINT                        DstRight;
    UINT                        DstBottom;
    D3D12DDI_HRESOURCE          hSrcResource;
    UINT                        SrcSubresource;
    UINT                        SrcLeft;
    UINT                        SrcTop;
    UINT                        SrcRight;
    UINT                        SrcBottom;
    DXGI_DDI_ARG_BLT_FLAGS      Flags;
    DXGI_DDI_MODE_ROTATION      Rotate;
} D3D12DDIARG_BLT;

typedef UINT ( APIENTRY* PFND3D12DDI_GET_PRESENT_PRIVATE_DRIVER_DATA_SIZE ) ( D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_PRESENT_0001* );

typedef struct D3D12DDI_ARG_PRESENTSURFACE
{
    D3D12DDI_HRESOURCE hSurface;
    UINT               SubResourceIndex;
} D3D12DDI_ARG_PRESENTSURFACE;

typedef struct D3D12DDIARG_PRESENT_0001
{
    CONST D3D12DDI_ARG_PRESENTSURFACE*  phSurfacesToPresent;
    UINT                                SurfacesToPresent;
    D3D12DDI_HRESOURCE                  hDstResource;
    UINT                                DstSubResourceIndex;
    DXGI_DDI_PRESENT_FLAGS              Flags;
    DXGI_DDI_FLIP_INTERVAL_TYPE         FlipInterval;
    D3DDDI_VIDEO_PRESENT_SOURCE_ID      VidPnSourceID;
    CONST RECT*                         pDirtyRects;
    UINT                                DirtyRects;
    UINT                                PrivateDriverDataSize;
    VOID*                               pPrivateDriverData;
    BOOL                                OptimizeForComposition;
} D3D12DDIARG_PRESENT_0001;

typedef VOID ( APIENTRY* PFND3D12DDI_PRESENT_0051 ) ( D3D12DDI_HCOMMANDLIST, D3D12DDI_HCOMMANDQUEUE, _In_ CONST D3D12DDIARG_PRESENT_0001*,
    _Out_ D3D12DDI_PRESENT_0051*, _Out_opt_ D3D12DDI_PRESENT_CONTEXTS_0051*, _Out_opt_ D3D12DDI_PRESENT_HWQUEUES_0051* );

typedef struct D3D12DDI_PRESENT_0051
{
    D3DKMT_HANDLE   BroadcastSrcAllocation[D3DDDI_MAX_BROADCAST_CONTEXT+1];
    D3DKMT_HANDLE   BroadcastDstAllocation[D3DDDI_MAX_BROADCAST_CONTEXT+1];
    BOOL            AddedGpuWork;
    UINT            BackBufferMultiplicity;

    BOOL                        SyncIntervalOverrideValid;
    DXGI_DDI_FLIP_INTERVAL_TYPE SyncIntervalOverride;
} D3D12DDI_PRESENT_0051;

typedef struct D3D12DDI_PRESENT_CONTEXTS_0051
{
    HANDLE          hContext;
    UINT            BroadcastContextCount;
    HANDLE          BroadcastContext[D3DDDI_MAX_BROADCAST_CONTEXT];
} D3D12DDI_PRESENT_CONTEXTS_0051;

typedef struct D3D12DDI_PRESENT_HWQUEUES_0051
{
    UINT            BroadcastQueueCount;
    HANDLE          hHwQueues[D3DDDI_MAX_BROADCAST_CONTEXT+1];
} D3D12DDI_PRESENT_HWQUEUES_0051;

```

<ins><!-- d3d12-review-inline:begin:execution:CS-presentation-services:0:authored:migration-41d8c6a6a944129c-0 -->Blt records the presentation/interoperation transfer specified by its driver resource, region, DXGI flag and rotation inputs.<!-- d3d12-review-inline:end:execution:CS-presentation-services:0:authored:migration-41d8c6a6a944129c-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:CS-presentation-services:1:authored:migration-243797c68418a42f-0 -->`GetPresentPrivateDriverDataSize` returns a `UINT` byte requirement for the
specified present request. The runtime provides that private data storage
to `Present`. It remains allocator-backed for the recorded operation rather
than being a call-borrowed local scratch buffer. A zero requirement supplies
no private data storage.<!-- d3d12-review-inline:end:execution:CS-presentation-services:1:authored:migration-243797c68418a42f-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:CS-presentation-services:2:authored:migration-b16f81f272a8c9b0-0 -->Present returns allocation/broadcast, added-GPU-work, back buffer and interval-override information. Software scheduling writes context results. Hardware scheduling writes hardware queue results. The unselected optional output is null.<!-- d3d12-review-inline:end:execution:CS-presentation-services:2:authored:migration-b16f81f272a8c9b0-0 --></ins>

<a id="driver-clock-calibration"></a>

### Driver clock calibration

<ins><!-- d3d12-review-inline:begin:execution:XC06-clock-calibration-forward:0:authored:migration-bf96ed8907c081a7-0 -->See the [downlevel clock calibration driver interface and data](counters-queries-and-predication.md#ddi-clock-calibration).<!-- d3d12-review-inline:end:execution:XC06-clock-calibration-forward:0:authored:migration-bf96ed8907c081a7-0 --></ins>

<a id="background-processing"></a>

## Background processing

```cpp
typedef
enum D3D12_BACKGROUND_PROCESSING_MODE
    {
        D3D12_BACKGROUND_PROCESSING_MODE_ALLOWED	= 0,
        D3D12_BACKGROUND_PROCESSING_MODE_ALLOW_INTRUSIVE_MEASUREMENTS	= ( D3D12_BACKGROUND_PROCESSING_MODE_ALLOWED + 1 ) ,
        D3D12_BACKGROUND_PROCESSING_MODE_DISABLE_BACKGROUND_WORK	= ( D3D12_BACKGROUND_PROCESSING_MODE_ALLOW_INTRUSIVE_MEASUREMENTS + 1 ) ,
        D3D12_BACKGROUND_PROCESSING_MODE_DISABLE_PROFILING_BY_SYSTEM	= ( D3D12_BACKGROUND_PROCESSING_MODE_DISABLE_BACKGROUND_WORK + 1 )
    } 	D3D12_BACKGROUND_PROCESSING_MODE;

typedef
enum D3D12_MEASUREMENTS_ACTION
    {
        D3D12_MEASUREMENTS_ACTION_KEEP_ALL	= 0,
        D3D12_MEASUREMENTS_ACTION_COMMIT_RESULTS	= ( D3D12_MEASUREMENTS_ACTION_KEEP_ALL + 1 ) ,
        D3D12_MEASUREMENTS_ACTION_COMMIT_RESULTS_HIGH_PRIORITY	= ( D3D12_MEASUREMENTS_ACTION_COMMIT_RESULTS + 1 ) ,
        D3D12_MEASUREMENTS_ACTION_DISCARD_PREVIOUS	= ( D3D12_MEASUREMENTS_ACTION_COMMIT_RESULTS_HIGH_PRIORITY + 1 )
    } 	D3D12_MEASUREMENTS_ACTION;
```

<a id="id3d12device6-setbackgroundprocessingmode"></a>

### ID3D12Device6::SetBackgroundProcessingMode

#### Declaration

```cpp
HRESULT SetBackgroundProcessingMode(
    D3D12_BACKGROUND_PROCESSING_MODE Mode,
    D3D12_MEASUREMENTS_ACTION MeasurementsAction,
    HANDLE hEventToSignalUponCompletion,
    BOOL* pbFurtherMeasurementsDesired);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:execution:CS-background-api-intro:5:authored:migration-f243e5e87aca284a-0 -->Controls optional driver optimization/profiling work, not correctness-critical
processing or GPU submission. The mode/action behavior is defined below.<!-- d3d12-review-inline:end:execution:CS-background-api-intro:5:authored:migration-f243e5e87aca284a-0 --></ins>

Developers and profiling tools can adjust this behavior using combinations of the above enums.  The BACKGROUND_PROCESSING_MODE parameter indicates what level of dynamic profiling and shader recompilation is enabled:

**ALLOWED** is the default state, in which drivers may instrument workloads in any manner of their choosing, and may submit CPU tasks (typically PSO recompiles) to the D3D runtime for low priority execution.  The goal of this mode is to enable dynamic optimizations, but without impacting foreground rendering performance.

**ALLOW_INTRUSIVE_MEASUREMENTS** hints that the driver should prioritize richness and completeness of instrumentation over avoiding glitches, because the rendering currently taking place is being done specifically for training purposes and does not need to execute with usual smooth performance.  This kind of heavy-weight profiling will be used by analysis tools such as PIX.  It could also be used by benchmarks to warm the optimization state before taking their actual performance measurements, or directly by games at appropriate times (eg. pre-training the driver by rendering invisible content behind a menu).

**DISABLE_BACKGROUND_WORK** prevents the execution of background processing tasks.  When this flag is first turned on, all submitted tasks will be allowed to run to completion.  Any calls to <ins><!-- d3d12-review-inline:begin:execution:CS-background-primary-behavior:3:modified:source-8b164c4c62993eae-0-0 -->QueueProcessingWorkCb<!-- d3d12-review-inline:end:execution:CS-background-primary-behavior:3:modified:source-8b164c4c62993eae-0-0 --></ins> while already in this state will <ins><!-- d3d12-review-inline:begin:execution:CS-background-primary-behavior:3:modified:source-8b164c4c62993eae-0-1 -->be canceled before returning;<!-- d3d12-review-inline:end:execution:CS-background-primary-behavior:3:modified:source-8b164c4c62993eae-0-1 --></ins> the cancel callback <ins><!-- d3d12-review-inline:begin:execution:CS-background-primary-behavior:3:modified:source-8b164c4c62993eae-0-2 -->is invoked if supplied<!-- d3d12-review-inline:end:execution:CS-background-primary-behavior:3:modified:source-8b164c4c62993eae-0-2 --></ins>.

Of course the UMD may choose to skip task submission entirely while in the disabled state, but if it does submit work, the runtime will cancel rather than just failing the submit operation, in order to avoid the UMD having to bother synchronizing between work submission and mode changes.

If the disable flag is turned on at the same time as specifying D3D12_MEASUREMENTS_ACTION_COMMIT_*, any new tasks that the UMD generates in response to the commit request will be allowed to execute before the disable takes effect.

The disable flag is only valid when developer mode is enabled.

**DISABLE_PROFILING_BY_SYSTEM** is a superset of the DISABLE_BACKGROUND_WORK mode, and requests a more complete disable of PGO.  In addition to suspending dynamic shader recompilation, this indicates that the driver should avoid making any behavioral changes that would perturb performance, such as dynamically tuning cache policies or compute dispatch patterns.  This is for use during profiling sessions, where an A/B comparison must provide stable timing results.

This flag is only valid when developer mode is enabled.

In addition to specifying a BACKGROUND_PROCESSING_MODE, which controls future PGO behavior, SetBackgroundProcessingMode takes a D3D12_MEASUREMENTS_ACTION enum describing what to do with the result of previous PGO measurements.  Options are:

**KEEP_ALL** does not request any specific change of behavior.  Previous results are still valid, and the driver may continue tracking whatever statistics are in the middle of being measured.

**COMMIT_RESULTS** hints that the workload seen so far represents the complete set of what is worth optimizing based on, for instance that a scene flythrough has finished in a benchmarking tool, or playback of the single frame being analyzed has completed in PIX. The UMD should kick off any desired background processing based on what it has seen so far, as no different work will be incoming in the near future.  After the UMD returns from a SetBackgroundProcessingMode call that specifies COMMIT_RESULTS, all currently queued background tasks will be considered part of the commit.  Once that set of tasks finishes executing, the provided <ins><!-- d3d12-review-inline:begin:execution:CS-background-primary-behavior:11:modified:source-d9ce10ae43a398f3-0-0 -->hEventToSignalUponCompletion<!-- d3d12-review-inline:end:execution:CS-background-primary-behavior:11:modified:source-d9ce10ae43a398f3-0-0 --></ins> will be signaled. As indicated above, if this is combined with DISABLE_BACKGROUND_WORK, the disable state (i.e. the inability to submit more tasks) will take effect after returning from the SetBackgroundProcessingMode call.

If the UMD has been gathering statistics about eg. commonly used constant values, and is waiting for some threshold amount of data to be recorded before acting on this information, the commit flag should scale up whatever frequency histograms have been recorded so far to give the same result as if the normal act-now threshold had been reached after a longer period of data collection.  This is important to let PIX replay only one single frame capture, but then request a final set of optimized shaders matching that work, without having to waste time repeating a single frame many hundreds of times.

If the COMMIT_RESULTS or COMMIT_RESULTS_HIGH_PRIORITY modes are not used, <ins><!-- d3d12-review-inline:begin:execution:CS-background-primary-behavior:13:modified:source-9263b2f2e371bc81-0-0 -->hEventToSignalUponCompletion<!-- d3d12-review-inline:end:execution:CS-background-primary-behavior:13:modified:source-9263b2f2e371bc81-0-0 --></ins> must be null.

**COMMIT_RESULTS_HIGH_PRIORITY** is a superset of the COMMIT_RESULTS mode which modifies the thread scheduling behavior.  This indicates that getting background compiles done fast is more important than avoiding glitches, so the D3D runtime will schedule more than one task simultaneously using multiple threads, and execute these at higher than idle priority.  This boost lasts until all tasks generated by the commit have finished executing.

The high priority mode is only valid when developer mode is enabled.

**DISCARD_PREVIOUS** hints to the UMD that the workload has changed in a significant way, so any results of previous measurements are no longer meaningful.

The **FurtherMeasurementsDesired** output value indicates whether the implementation has reached a steady state, or if it would like a chance to examine additional GPU work.  This is useful if, for instance, playback of a single frame in a tool such as PIX identifies opportunities for constant folding.  Once the resulting optimized shaders have been applied, further optimizations might be identified by profiling the workload again with that first round of optimization in place. This value will return false once the PGO implementation has reached a steady state, measuring a workload without identifying any further optimizations that can be made to it.  Analysis tools will typically replay a single frame inside a loop until this returns false, but should break out after some number of attempts in case the implementation never converges on a steady state.

#### Parameters

<ins><!-- d3d12-review-inline:begin:execution:CS-background-api-tail:1:authored:migration-135a02da869e0a07-0 -->`Mode` and `MeasurementsAction` are values of their published enumerations.
`hEventToSignalUponCompletion` can be supplied for a commit action and must
be null otherwise. The event tracks completion of that commit's background
tasks, not GPU work. `pbFurtherMeasurementsDesired` is optional and receives
whether the driver wants further training. This indication is not a promise
of convergence after a fixed number of workloads.<!-- d3d12-review-inline:end:execution:CS-background-api-tail:1:authored:migration-135a02da869e0a07-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:CS-background-api-tail:2:authored:migration-1274b8d6fe372aa7-0 -->`OPTIONS6.BackgroundProcessingSupported` reports support. A valid call
without driver support is a benign no-op: a supplied event is signaled and a
supplied further-measurements output is `FALSE`, whether or not an event was
supplied. Changing modes does not synchronize with GPU queues. Applications
requiring an idle transition must establish GPU completion separately.<!-- d3d12-review-inline:end:execution:CS-background-api-tail:2:authored:migration-1274b8d6fe372aa7-0 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:execution:CS-background-api-tail:4:authored:migration-4d576eec8e4626e9-0 -->Returns `S_OK` on success or an `HRESULT` failure. Invalid enum/event/developer-
mode combinations are not valid requests. Runtime bookkeeping allocation
can fail. A successful CPU return is not background task or GPU completion.<!-- d3d12-review-inline:end:execution:CS-background-api-tail:4:authored:migration-4d576eec8e4626e9-0 --></ins>

### Driver background scheduling

<a id="driver-background-scheduling"></a>

```cpp
typedef enum D3D12DDI_BACKGROUND_PROCESSING_MODE_0062
{
    D3D12DDI_BACKGROUND_PROCESSING_MODE_0062_ALLOWED,
    D3D12DDI_BACKGROUND_PROCESSING_MODE_0062_ALLOW_INTRUSIVE_MEASUREMENTS,
    D3D12DDI_BACKGROUND_PROCESSING_MODE_0062_DISABLE_BACKGROUND_WORK,
    D3D12DDI_BACKGROUND_PROCESSING_MODE_0062_DISABLE_ALL_PROFILING,
} D3D12DDI_BACKGROUND_PROCESSING_MODE_0062;

typedef enum D3D12DDI_MEASUREMENTS_ACTION_0062
{
    D3D12DDI_MEASUREMENTS_ACTION_0062_KEEP_ALL,
    D3D12DDI_MEASUREMENTS_ACTION_0062_COMMIT_RESULTS,
    D3D12DDI_MEASUREMENTS_ACTION_0062_COMMIT_RESULTS_HIGH_PRIORITY,
    D3D12DDI_MEASUREMENTS_ACTION_0062_DISCARD_PREVIOUS,
} D3D12DDI_MEASUREMENTS_ACTION_0062;

typedef void (APIENTRY* PFND3D12DDI_UMD_CALLBACK_METHOD)(void* pContext);

typedef HRESULT (APIENTRY CALLBACK *PFND3D12DDI_QUEUEPROCESSINGWORK_CB_0062)(
    D3D12DDI_HRTDEVICE hRTDevice,
    _In_ PFND3D12DDI_UMD_CALLBACK_METHOD pfnCallback,       // Called from thread where work is being performed.
    _In_opt_ PFND3D12DDI_UMD_CALLBACK_METHOD pfnCancel,     // Called if the device is destroyed before pfnCallback has executed.
    _In_opt_ void* pContext                                 // Passed to pfnCallback or pfnCancel.
);

typedef void (APIENTRY* PFND3D12DDI_SET_BACKGROUND_PROCESSING_MODE_0063)(
    D3D12DDI_HDEVICE hRTDevice,
    D3D12DDI_BACKGROUND_PROCESSING_MODE_0062 Mode,
    D3D12DDI_MEASUREMENTS_ACTION_0062 MeasurementsAction,
    _Out_ BOOL* pbFurtherMeasurementsDesired
);
```

<ins><!-- d3d12-review-inline:begin:execution:CS-background-driver:1:authored:migration-134b9d95d720aa17-0 -->The mode DDI receives a driver device handle despite the parameter name `hRTDevice`. API DISABLE_PROFILING_BY_SYSTEM maps to driver DISABLE_ALL_PROFILING (3). The driver BOOL output is required, so the runtime supplies temporary storage when the API output is omitted.<!-- d3d12-review-inline:end:execution:CS-background-driver:1:authored:migration-134b9d95d720aa17-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:CS-background-driver:2:authored:migration-93e844c60c0963b8-0 -->`QueueProcessingWorkCb` runs in the opposite direction with a
runtime device handle, execution callback, optional cancellation callback
and opaque context. A successful enqueue makes that context available to
the selected asynchronous action. It is not a callback completion result.
The runtime manages workers and serializes submissions, but parallel work
does not imply completion in submission order or driver choice of worker.<!-- d3d12-review-inline:end:execution:CS-background-driver:2:authored:migration-93e844c60c0963b8-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:CS-background-driver:3:authored:migration-420ecc7182f9e2d1-0 -->An accepted item is executed or canceled, never both. If a cancellation
callback was supplied it receives the same opaque context on cancellation;
absence of a callback does not invent a cancellation notification. In a
disabled mode, cancellation can occur inline before enqueue returns.
The driver manages context and referenced-object lifetimes, including a PSO
destroyed while optimization is pending. Queuing optimization does not keep
arbitrary application objects alive. Mode changes and commit events do not
synchronize GPU execution.<!-- d3d12-review-inline:end:execution:CS-background-driver:3:authored:migration-420ecc7182f9e2d1-0 --></ins>


The runtime is responsible for cleaning up threads during device destruction. The runtime may, or may not, call any existing queued work.  <ins><!-- d3d12-review-inline:begin:execution:CS-background-primary-lifetime:0:modified:migration-212f41f7124afc43-0 -->If a queued work item is canceled (i.e. pfnCallback is skipped), its pfnCancel method will be called instead if one was supplied.<!-- d3d12-review-inline:end:execution:CS-background-primary-lifetime:0:modified:migration-212f41f7124afc43-0 --></ins>  <ins><!-- d3d12-review-inline:begin:execution:CS-background-primary-lifetime:0:modified:migration-fa9a4cd9179a9dd5-1 -->Execution and cancellation are mutually exclusive for each successfully queued work item.<!-- d3d12-review-inline:end:execution:CS-background-primary-lifetime:0:modified:migration-fa9a4cd9179a9dd5-1 --></ins>

A hard guarantee is that the runtime will let the UMD complete any in-progress work items (the runtime won't call TerminateThread on the thread), and will wait until all in-flight work items are completed before calling pfnDestroyDevice.

<a id="recording-state-lifetime-apis"></a>

## Recording state and tracked object lifetime APIs

```cpp
typedef
enum D3D12_LIFETIME_STATE
    {
        D3D12_LIFETIME_STATE_IN_USE	= 0,
        D3D12_LIFETIME_STATE_NOT_IN_USE	= ( D3D12_LIFETIME_STATE_IN_USE + 1 )
    } 	D3D12_LIFETIME_STATE;
```

<a id="api-id3d12graphicscommandlist-clearstate"></a>

### ID3D12GraphicsCommandList::ClearState

#### Declaration

```cpp
void ClearState(
    ID3D12PipelineState* pPipelineState);
```

#### Behavior

Resets the state of a direct <ins><!-- d3d12-review-inline:begin:execution:AB-primary-id3d12graphicscommandlist-clearstate:0:authored:source-30b405a035a90708-0-0 -->or compute <!-- d3d12-review-inline:end:execution:AB-primary-id3d12graphicscommandlist-clearstate:0:authored:source-30b405a035a90708-0-0 --></ins>command list back to the state it was in when the command list was created.

<ins><!-- d3d12-review-inline:begin:execution:AB-id3d12graphicscommandlist-clearstate-contract:0:authored:migration-1e71fd96b951a510-0 -->The precise [canonical ClearState effects](command-list-state.md#clear-state)
apply. This records state changes on an open DIRECT/COMPUTE list. It does not
erase commands, reset/reclaim its allocator, repair a recording error or end
queries. It is invalid on COPY/BUNDLE lists or inside an open render pass.
Custom sample positions and view mask are not implicitly restored by the
generic reset description. Their explicit canonical setters remain required.<!-- d3d12-review-inline:end:execution:AB-id3d12graphicscommandlist-clearstate-contract:0:authored:migration-1e71fd96b951a510-0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:execution:AB-id3d12graphicscommandlist-clearstate-contract:2:authored:migration-d108f0a0ff7ad979-0 -->`pPipelineState` supplies the graphics/compute PSO to select. Null selects the
appropriate default state, not an application shader program. PSO-derived
dynamic state follows that selection. Ordinary bindings/predication and the
supported protection/VRS/depth state follow the canonical definition.<!-- d3d12-review-inline:end:execution:AB-id3d12graphicscommandlist-clearstate-contract:2:authored:migration-d108f0a0ff7ad979-0 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:execution:AB-id3d12graphicscommandlist-clearstate-contract:4:authored:migration-4f88456e95f6c6bf-0 -->Returns no value; invalid recording follows the [Close/error contract](#close).<!-- d3d12-review-inline:end:execution:AB-id3d12graphicscommandlist-clearstate-contract:4:authored:migration-4f88456e95f6c6bf-0 --></ins>

<a id="api-id3d12graphicscommandlist3-setprotectedresourcesession"></a>

### ID3D12GraphicsCommandList3::SetProtectedResourceSession

#### Declaration

```cpp
void SetProtectedResourceSession(
    ID3D12ProtectedResourceSession *pProtectedResourceSession);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:execution:AB-primary-id3d12graphicscommandlist3-setprotectedresourcesession:0 -->Specifies whether or not protected resources can be accessed by subsequent commands in the command list. By default, no protected resources are enabled. After calling **SetProtectedResourceSession** with a valid session, protected resources of the same type can refer to that session. After calling **SetProtectedResourceSession** with **NULL**, no protected resources can be accessed.<!-- d3d12-review-inline:end:execution:AB-primary-id3d12graphicscommandlist3-setprotectedresourcesession:0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:AB-id3d12graphicscommandlist3-setprotectedresourcesession-contract:0:authored:migration-9d7870aba5d72d07-0 -->Selects only the [protection context](command-list-state.md#protection).
Ordinary pipeline/root/descriptor/output bindings and predication are preserved;
this is not ClearState. Protected operations retain their no-predication
requirement, so the caller must establish a valid predicate state separately.
End all open query intervals before a supported session change. The session
must be compatible with the device/node and operation; selection is not session
creation or GPU completion. Supported DIRECT/COMPUTE/COPY lists, bundle-side
setter exclusion and render pass restrictions remain canonical.<!-- d3d12-review-inline:end:execution:AB-id3d12graphicscommandlist3-setprotectedresourcesession-contract:0:authored:migration-9d7870aba5d72d07-0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:execution:AB-id3d12graphicscommandlist3-setprotectedresourcesession-contract:2:authored:migration-bc99a6596041982f-0 -->`pProtectedResourceSession` is an optional session interface; null disables protected access for subsequent work. Passing it transfers no caller-owned COM reference.<!-- d3d12-review-inline:end:execution:AB-id3d12graphicscommandlist3-setprotectedresourcesession-contract:2:authored:migration-bc99a6596041982f-0 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:execution:AB-id3d12graphicscommandlist3-setprotectedresourcesession-contract:4:authored:migration-88d046185b547816-0 -->Returns no value; recording failures use the canonical list/Close path. It does not report protected content validity; query the session/status fence.<!-- d3d12-review-inline:end:execution:AB-id3d12graphicscommandlist3-setprotectedresourcesession-contract:4:authored:migration-88d046185b547816-0 --></ins>

<a id="protected-session-driver"></a>

#### Driver interface

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_SETPROTECTEDRESOURCESESSION_0030 )( D3D12DDI_HCOMMANDLIST, D3D12DDI_HPROTECTEDRESOURCESESSION_0030 );
```

<ins><!-- d3d12-review-inline:begin:execution:CS-recording-error-protection:1:authored:migration-7806e5ee03f91e43-0 -->SetProtectedResourceSession uses ordinary driver command list and session handles in both 3D layouts and the selected video tables. A null session handle clears the association.<!-- d3d12-review-inline:end:execution:CS-recording-error-protection:1:authored:migration-7806e5ee03f91e43-0 --></ins>

<a id="api-id3d12protectedsession-getstatusfence"></a>

### ID3D12ProtectedSession::GetStatusFence

#### Declaration

```cpp
HRESULT GetStatusFence(
    REFIID riid,
    void** ppFence);
```

#### Behavior

Retrieves the fence for the protected session. From the fence, you can retrieve the current uniqueness validity value (using <ins><!-- d3d12-review-inline:begin:execution:AB-primary-id3d12protectedsession-getstatusfence:0 -->[ID3D12Fence::GetCompletedValue](#id3d12fencegetcompletedvalue)<!-- d3d12-review-inline:end:execution:AB-primary-id3d12protectedsession-getstatusfence:0 --></ins>), and add monitors for changes to its value. This is a read-only fence.

<ins><!-- d3d12-review-inline:begin:execution:AB-id3d12protectedsession-getstatusfence-contract:0:authored:migration-8df63c59301f8692-0 -->The [status fence contract](#status-fences) is a uniqueness/invalidation
protocol, not an application completion timeline. The returned read-only fence
can be observed and monitored. It must not be signaled by CPU, queues or
residency-enqueue operations. Fence changes alone do not initialize invalid
protected contents or prove a pending application workload completed.<!-- d3d12-review-inline:end:execution:AB-id3d12protectedsession-getstatusfence-contract:0:authored:migration-8df63c59301f8692-0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:execution:AB-id3d12protectedsession-getstatusfence-contract:2:authored:migration-32cedbc907064941-0 -->`riid` requests an interface on the status fence. `ppFence` receives the resulting caller-owned COM reference; normal interface release remains the caller's responsibility.<!-- d3d12-review-inline:end:execution:AB-id3d12protectedsession-getstatusfence-contract:2:authored:migration-32cedbc907064941-0 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:execution:AB-id3d12protectedsession-getstatusfence-contract:4:authored:migration-ebeffec4f914d6a7-0 -->Returns `S_OK` on successful interface retrieval, `E_NOINTERFACE` for an unsupported fence interface, or the applicable failure. No GPU wait is performed by retrieval.<!-- d3d12-review-inline:end:execution:AB-id3d12protectedsession-getstatusfence-contract:4:authored:migration-ebeffec4f914d6a7-0 --></ins>

<a id="api-id3d12device5-createlifetimetracker"></a>

### ID3D12Device5::CreateLifetimeTracker

#### Declaration

```cpp
HRESULT CreateLifetimeTracker(
    ID3D12LifetimeOwner* pOwner,
    REFIID riid,
    void** ppvTracker);
```

#### Behavior

Creates a lifetime tracker associated with an application-defined callback; the callback receives notifications when the lifetime of a tracked object is changed.

<ins><!-- d3d12-review-inline:begin:execution:AB-id3d12device5-createlifetimetracker-contract:0:authored:migration-2dbfcf2959023275-0 -->Creates an explicit ownership/lifetime tracker for objects created with its
association, including the [compatibility resource path](sharing-and-interoperability.md#compatibility-creation).
Its notifications reflect aggregate reference/use transitions, not a new
application fence. Creating a tracker does not attach it to arbitrary existing
objects or make ordinary resource lifetimes automatic.<!-- d3d12-review-inline:end:execution:AB-id3d12device5-createlifetimetracker-contract:0:authored:migration-2dbfcf2959023275-0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:execution:AB-id3d12device5-createlifetimetracker-contract:2:authored:migration-963b20beff0f89c3-0 -->`pOwner` supplies the lifetime callback object retained by the tracker. `riid` selects the tracker interface and `ppvTracker` receives its COM reference.<!-- d3d12-review-inline:end:execution:AB-id3d12device5-createlifetimetracker-contract:2:authored:migration-963b20beff0f89c3-0 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:execution:AB-id3d12device5-createlifetimetracker-contract:4:authored:migration-762d5e1a9f0987e2-0 -->Returns `S_OK` on successful construction or an HRESULT failure, including allocation/interface failures. The output tracker is not a GPU completion result.<!-- d3d12-review-inline:end:execution:AB-id3d12device5-createlifetimetracker-contract:4:authored:migration-762d5e1a9f0987e2-0 --></ins>

<a id="api-id3d12lifetimeowner-lifetimestateupdated"></a>

### ID3D12LifetimeOwner::LifetimeStateUpdated

#### Declaration

```cpp
void LifetimeStateUpdated(
    D3D12_LIFETIME_STATE NewState);
```

#### Behavior

Called when the lifetime state of a lifetime-tracked object changes.

<ins><!-- d3d12-review-inline:begin:execution:AB-id3d12lifetimeowner-lifetimestateupdated-contract:0:authored:migration-d845c4aa6f392a4d-0 -->The runtime invokes this application callback when the tracker's aggregate
observed references/uses transition between zero and nonzero. `IN_USE` means
an observed reference/use exists; `NOT_IN_USE` means none remain at that
transition. A notification is not one callback per command or per individual
object, nor a promise of a dedicated callback thread or an initial notification.
Callback/context ownership must remain valid while the tracker can notify.<!-- d3d12-review-inline:end:execution:AB-id3d12lifetimeowner-lifetimestateupdated-contract:0:authored:migration-d845c4aa6f392a4d-0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:execution:AB-id3d12lifetimeowner-lifetimestateupdated-contract:2:authored:migration-3e14ed6312b519ed-0 -->`NewState` is `D3D12_LIFETIME_STATE_IN_USE` or `D3D12_LIFETIME_STATE_NOT_IN_USE`.<!-- d3d12-review-inline:end:execution:AB-id3d12lifetimeowner-lifetimestateupdated-contract:2:authored:migration-3e14ed6312b519ed-0 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:execution:AB-id3d12lifetimeowner-lifetimestateupdated-contract:4:authored:migration-88b1b07894b7ad80-0 -->Returns no value. The callback does not itself destroy owned objects or substitute for application queue synchronization.<!-- d3d12-review-inline:end:execution:AB-id3d12lifetimeowner-lifetimestateupdated-contract:4:authored:migration-88b1b07894b7ad80-0 --></ins>

<a id="api-id3d12lifetimetracker-destroyownedobject"></a>

### ID3D12LifetimeTracker::DestroyOwnedObject

#### Declaration

```cpp
HRESULT DestroyOwnedObject(
    ID3D12DeviceChild* pObject);
```

#### Behavior

Destroys a lifetime-tracked object.

<ins><!-- d3d12-review-inline:begin:execution:AB-id3d12lifetimetracker-destroyownedobject-contract:0:authored:migration-22974bb0e5fe4fa0-0 -->Requests destruction of an object owned by this tracker and removes that
ownership association. Physical cleanup retains outstanding runtime/GPU use
lifetime rules. This method is not a GPU wait. Tracker destruction also
releases its remaining owned objects. The caller must not treat a destroyed
object as a new reusable resource merely because a COM pointer still exists.<!-- d3d12-review-inline:end:execution:AB-id3d12lifetimetracker-destroyownedobject-contract:0:authored:migration-22974bb0e5fe4fa0-0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:execution:AB-id3d12lifetimetracker-destroyownedobject-contract:2:authored:migration-68dc74786c67cf3c-0 -->`pObject` identifies the device child belonging to this tracker, not an arbitrary device child or shared handle.<!-- d3d12-review-inline:end:execution:AB-id3d12lifetimetracker-destroyownedobject-contract:2:authored:migration-68dc74786c67cf3c-0 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:execution:AB-id3d12lifetimetracker-destroyownedobject-contract:4:authored:migration-801717008a31c8e9-0 -->Returns `S_OK` for the owned-object destruction request. An object not in this tracker's ownership set returns `E_INVALIDARG`, and interface failures remain failures.<!-- d3d12-review-inline:end:execution:AB-id3d12lifetimetracker-destroyownedobject-contract:4:authored:migration-801717008a31c8e9-0 --></ins>
