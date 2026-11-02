# Command recording and execution

**Coverage: source-preserving draft.** This chapter assembles selected recording, submission, completion, lifetime, and threading text. It does not yet cover every execution contract.

<a id="execution-objects"></a>

## Command lists and queues

To render, applications can
create a *command list* off of the device, on which traditional
rendering APIs can be called. Each individual command list is
not free-threaded, but multiple command lists *can* be recorded
concurrently (which enables multi-threading).

### Bundles

Bundles are a 'second level' of command lists. The purpose of Bundles is to allow apps to
group a small number of API commands together for later execution. At
Bundle creation time, the driver will perform as much pre-processing as
is possible to make these cheap to execute later. Command lists, on the
other hand, are typically executed only a single time (to enable
multi-threaded command buffer recording). However, a command list can be
executed multiple times (as long as the application ensures that the
previous executions have completed before submitting new executions).

<a id="command-list-types"></a>

### Queue types

Command queues can be created by calling [`ID3D12Device::CreateCommandQueue`](command-queues.md#id3d12device-createcommandqueue). The `Type` field of `D3D12_COMMAND_QUEUE_DESC` is a [`D3D12_COMMAND_LIST_TYPE`](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/ne-d3d12-d3d12_command_list_type) indicating what type of queue should be created, and therefore, what type of commands can be submitted to that queue. Remember that bundles can only be called from direct command lists and can't be submitted directly to a queue. The supported queue types are:

- [`D3D12_COMMAND_LIST_TYPE_DIRECT`](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/ne-d3d12-d3d12_command_list_type)
- [`D3D12_COMMAND_LIST_TYPE_COMPUTE`](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/ne-d3d12-d3d12_command_list_type)
- [`D3D12_COMMAND_LIST_TYPE_COPY`](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/ne-d3d12-d3d12_command_list_type)
- [`D3D12_COMMAND_LIST_TYPE_VIDEO_DECODE`](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_command_list_type)
- [`D3D12_COMMAND_LIST_TYPE_VIDEO_PROCESS`](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_command_list_type)
- [`D3D12_COMMAND_LIST_TYPE_VIDEO_ENCODE`](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_command_list_type)
- [`D3D12_COMMAND_LIST_TYPE_NONE`](#synchronization-only-queues)

In general, DIRECT queues and command lists accept graphics, compute, and copy commands, COMPUTE queues and command lists accept compute and copy related commands, and COPY queues and command lists accept only copy commands.

Video-decode recording, lifecycle, ordering and lifetime are defined in [Video](video.md#video-recording-lifetime), using the common queue/submission and completion contracts.

The distinct video-process list/queue and processor route is defined in [Video processing](video.md#video-processing-model), using the common creation, submission, threading and completion contracts.

The VIDEO_ENCODE [base list lifecycle and motion operations](video-motion-estimation.md#motion-recording) use these common creation, allocator-storage, threading, submission and completion contracts. The motion estimator's [cross-queue exclusion rule](video-motion-estimation.md#motion-driver-objects) is an additional object-specific requirement, not decoder recording serialization.

Video [GPU extension initialization/execution](video-extension-commands.md#extension-recording) records into the selected compatible video list and follows these common submission/storage/lifetime contracts. The distinct [device extension method](video-extension-commands.md#videodevice2-executeextensioncommand) has a published completion-before-return contract; its parameter stages are not GPU execution stages.

Encoding's [object and recording contract](video-encoding.md#encoding-recording) includes encoder/heap serialization and recorded execution order, creation-description copies distinct from GPU storage, caller-owned COM references without assumed recording AddRef, and lifetime through unsubmitted recordings that will execute and completion of submitted uses. Reconfiguration does not mutate immutable creation properties or supply codec-header/DPB policy.

Meta-command discovery, resource-parameter layouts and initialization/execution are defined in the subordinate [Meta commands reference](meta-commands.md).

The [command-queue chapter](command-queues.md) defines creation,
creator IDs, the returned description and the four dynamic-priority methods.

<a id="synchronization-only-queues"></a>

### Synchronization-only queues

`D3D12_COMMAND_LIST_TYPE_NONE` selects a runtime-managed synchronization-only
queue. It supports queued fence Signal/Wait operations, but cannot execute
command lists or perform queue tile-mapping operations. This queue type does
not make `NONE` a valid type for command-list or command-allocator creation.

Its Signal/Wait operations retain queue-timeline ordering; they are not
immediate CPU fence updates or a requirement for the calling CPU thread to
wait for the fence threshold. The runtime manages its synchronization
transport without a UMD command-queue object. The UMD queue-DDI transport
rules do not imply that these operations invoke those DDIs.

<a id="queue-creation-priority"></a>

### Creation priority for grouped queues

Hardware scheduling may associate DIRECT and COMPUTE queues with a scheduling
group. For grouped queues created without
`D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY`,
`D3D12_COMMAND_QUEUE_DESC.Priority` does not
cause the runtime to set the corresponding kernel-context scheduling priority.
This compatibility behavior does not waive validation of the requested
priority, global-realtime privileges or the applicable support requirements.

`ID3D12CommandQueue::GetDesc` reports the queue's stored creation priority,
not its current kernel scheduling priority. For a grouped queue created
without `D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY`, successful
creation or that returned priority value does not establish that the requested
priority was applied to the kernel scheduling context.

Where the negotiated queue-creation DDI carries `QueueCreationFlags` and
UMD-based global-realtime priority is supported for the queue's workload,
the runtime must still set
`D3D12DDI_COMMAND_QUEUE_CREATION_FLAG_GLOBAL_REALTIME_PRIORITY` for a
`D3D12_COMMAND_QUEUE_PRIORITY_GLOBAL_REALTIME` request, including for a grouped
queue. Omitting kernel priority setting must not suppress this UMD request.
Passing the flag does not mean that the runtime set the group's kernel
scheduling priority.

**History.** The compatibility path's omission of kernel priority setting originated
as a bug. Correcting it caused application compatibility regressions, so the
prior behavior was restored and is retained for compatibility.

<a id="dynamic-queue-priority"></a>

### Dynamic queue priority

`D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY` opts a queue into dynamic
priority setting. An adjustment through an opt-in queue applies to the
scheduling group that contains it, including the other queues in that group.
Opt-in queues are not grouped with queues that lack this flag.

Creating an opt-in queue that joins an existing group overrides that group's
process and global priority settings according to the new queue's creation
priority. The creation priority is not merely inherited from the existing
group, and no separate setter call is required to request the override.

| `D3D12_COMMAND_QUEUE_PRIORITY` | `D3D12_COMMAND_QUEUE_PROCESS_PRIORITY` | `D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY` |
| -------- | -------- | -------- |
| `D3D12_COMMAND_QUEUE_PRIORITY_GLOBAL_REALTIME` | `D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_HIGH` | `D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_HARD_REALTIME` |
| `D3D12_COMMAND_QUEUE_PRIORITY_HIGH` | `D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_HIGH` | `D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_DEFAULT` |
| `D3D12_COMMAND_QUEUE_PRIORITY_NORMAL` | `D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_NORMAL` | `D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_DEFAULT` |

An ignored request to `ID3D12CommandQueue1::SetProcessPriority` or
`SetGlobalPriority` returns `S_FALSE`, not `S_OK`. It does not replace the
prior cached setting returned by the corresponding getter. The getters
report runtime-maintained priority state, not an independent readback of
the current OS scheduling state. `GetDesc` continues to report the stored
creation description rather than these mutable settings.

<a id="hardware-scheduling-queue-groupings"></a>

### Hardware-scheduling grouping query

`ID3D12Device::CheckFeatureSupport` accepts
`D3D12_FEATURE_HARDWARE_SCHEDULING_QUEUE_GROUPINGS` (selector value `60`)
with a `D3D12_FEATURE_DATA_HARDWARE_SCHEDULING_QUEUE_GROUPINGS` payload and
its exact `sizeof` as the data size. The payload has no input fields.

```cpp
typedef struct D3D12_FEATURE_DATA_HARDWARE_SCHEDULING_QUEUE_GROUPINGS
{
    UINT ComputeQueuesPer3DQueue;
} D3D12_FEATURE_DATA_HARDWARE_SCHEDULING_QUEUE_GROUPINGS;
```

`ComputeQueuesPer3DQueue`

When reported as greater than zero, indicates the maximum number of `COMPUTE` command queues (with the same `CreatorID`) that can be grouped together with a `DIRECT` queue in the same scheduling group.

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

The allocator supplies storage for recordings of the selected command-list
type; creation does not begin a command-list recording. The same allocator
may store several recordings, but only one command list may be recording to
it at a time. [Allocator storage and reuse](#command-storage), the
[Reset preconditions](#allocator-reset) and [CPU threading](#threading)
apply to this object.

#### Parameters

`type` specifies the command-list type for the allocator: DIRECT, BUNDLE,
COMPUTE, COPY, VIDEO_DECODE, VIDEO_PROCESS or VIDEO_ENCODE. The type must be
supported by the device; video types require the corresponding video support.
The allocator type must match the type of the command list that records to it.

`riid` identifies the requested interface on the command allocator, normally
`ID3D12CommandAllocator`.

`ppCommandAllocator` is a required output pointer that receives the requested
interface on the created allocator.

#### Return values

Successful object creation returns `S_OK`. An invalid or unsupported
command-list type returns `E_INVALIDARG`.

This method returns `E_OUTOFMEMORY` if there is insufficient memory to create the command allocator.

Other creation/interface failures are reported through the returned `HRESULT`.

<a id="command-list-get-type"></a>

### ID3D12CommandList::GetType

#### Declaration

```cpp
D3D12_COMMAND_LIST_TYPE GetType();
```

#### Behavior

Gets the type of the command list, such as direct, bundle, compute, or copy.

#### Return values

This method returns the type of the command list,
as a `D3D12_COMMAND_LIST_TYPE` enumeration constant,
such as direct, bundle, compute, or copy.

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

This API creates a command list or a bundle. The command list starts out
in the "recording" state.

This API also takes a command allocator as input. A given allocator can
be associated no more than 1 recording command list at a time. The
allocator type must match the type of command
list which is being created.

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

`CreateCommandList1` creates a command list in the closed state. Also see [ID3D12Device::CreateCommandList](#creation).

<a id="lifecycle"></a>

## Closing and reusing command lists

This section covers DIRECT, COMPUTE, COPY, and BUNDLE recordings made through `ID3D12GraphicsCommandList`, and the corresponding `ID3D12CommandAllocator` objects. The three methods below belong to the baseline D3D12 interfaces; they do not require an optional feature query. Calls on the same command-list or allocator object must obey the [CPU threading requirements](#threading).

<a id="command-storage"></a>

### Recorded commands and allocator storage

You can record multiple lists to the same allocator before it is reset, provided only one list is recording to a given allocator at one time. You can visualise each list as owning a portion of the allocator which indicates what [`ID3D12CommandQueue::ExecuteCommandLists`](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12commandqueue-executecommandlists) will execute.

Resetting a command-list object does not reset command-allocator storage. After resetting and re-recording a command-list object, the new recorded command stream may be submitted while an older stream recorded through the same object executes, provided that allocator storage and referenced resources remain valid for both streams. An unchanged recorded command stream must not be resubmitted while an earlier execution of that stream is still in progress.

`ExecuteBundle` records an execution of the bundle recording selected at that call. Resetting and re-recording the bundle object later does not replace the commands already selected by an earlier `ExecuteBundle` in a parent recording. The application may begin a new bundle recording with the same allocator without resetting that allocator, or use another compatible allocator.

The allocator storage backing the earlier recording must remain valid for every parent recording that will execute it. Resetting the allocator invalidates the recordings stored there, including bundle recordings already referenced by unsubmitted parents. The application must finish all GPU uses before reclaiming that storage and must not subsequently submit or resubmit an invalidated recording. An unsubmitted parent may instead be discarded without executing it.

Selecting a recorded command stream does not snapshot the contents of resources that its commands access, or remove their lifetime, residency, descriptor, and synchronization requirements. Neither closing a list nor resetting a list object or allocator provides proof of GPU completion.

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

`Close` ends CPU recording; it does not submit the recorded commands to a queue or wait for GPU execution. Queries begun in the command list must be ended before it is closed. An active render pass must also be ended before closing the list. These unmatched query/render-pass cases record an `E_FAIL` error against the list.

#### Return values

Returns `S_OK` if successful; otherwise, returns one of the following values:

- `E_INVALIDARG`: An invalid argument was passed to the command list API
  during recording

- `E_FAIL`: The command list has already been closed, an invalid API was
  called during command list recording, or a query or render pass is still open

- `E_OUTOFMEMORY`: The system ran out of memory during recording or closing

- `DXGI_ERROR_DEVICE_REMOVED`: A device-removing driver error was stored as the command-list error.

For a driver-reported device-removal failure, the application can query [ID3D12Device::GetDeviceRemovedReason](diagnostics.md#id3d12device-getdeviceremovedreason) for the device's removal reason.

#### Runtime validation

The runtime will validate that the command list has not previously been
closed. If an error was encountered during recording, the error code is
returned here. The runtime will not call the close DDI in this case.

#### Debug layer

Validation failures can generate debug-layer errors. A failed `Close`, including a driver-reported failure, does not necessarily produce a corresponding debug-layer message.

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

This API is called to reset a command list back to its initial state (as
if a new command list was just created). This enables command list
tracking structures to be re-used.

After `Reset` succeeds, the command list is left in the "recording" state.

Applications **are allowed** to call this method before the
GPU has finished all previous executions of the command list (unlike
`ID3D12CommandAllocator::Reset`).

This method works for both command lists and bundles.

#### Parameters

**pAllocator**

A pointer to the [`ID3D12CommandAllocator`](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nn-d3d12-id3d12commandallocator) object that the device creates command lists from.

This API also takes a command allocator as input. A given allocator can
be associated with no more than 1 recording command list at a time. The
allocator type must match the type of command
list that is being reset.

**pInitialState**

A pointer to the [`ID3D12PipelineState`](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nn-d3d12-id3d12pipelinestate) object that contains the initial pipeline state for the command list. This is optional and can be NULL. If NULL, the runtime sets a dummy initial pipeline state so that drivers don't have to deal with undefined state.

On a direct, compute, or bundle command list that uses graphics or compute pipeline state, `pInitialState` supplies the initial pipeline state. If it is NULL, the runtime selects its default graphics state for direct lists and bundles, or its default compute state for compute lists. This default does not supply an application shader program; the application must establish the pipeline state required by a draw or dispatch. Copy command lists have no pipeline state and do not use `pInitialState`.

<a id="reset-initial-state"></a>

#### Initial recording state

Creation/Reset values and bundle entry/exit behavior are defined in [Command-list state initialization](command-list-state.md#state-index). This includes the depth-bounds, sample-position, view-mask, VRS, dynamic-PSO, protection, and recording-context contributions.

#### Return values

Returns `S_OK` if successful; otherwise, returns one of the following values:

- `E_FAIL`: The command list was not in the "closed" state when the call
  was made.

- `E_INVALIDARG`: The allocator is currently being used with another
  command list in the "recording" state

- `E_INVALIDARG`: The specified allocator was created with the wrong type

- `E_OUTOFMEMORY`: The system ran out of memory

For a closed command list with a recorded error, `Reset` returns that recorded error; see [Runtime validation](#list-reset-validation) and [Deferred recording errors](#lifecycle-driver-errors).

<a id="list-reset-validation"></a>

#### Runtime validation

Before calling `Reset`, the command list must be in the "closed" state.
The API call will fail if this is not the case. Note that if an error has been recorded against the command list when
`ID3D12GraphicsCommandList::Close` returns, then that command list can never be
reset. Calling `ID3D12GraphicsCommandList::Reset` will result in the recorded error
being returned.

Applications must specify a command list allocator. The runtime will
ensure that an allocator is never associated with more than one
recording command list at the same time.

Calling `Close` on a command list that is already closed returns `E_FAIL` but does not, by itself, prevent a subsequent `Reset`.

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

Returns `S_OK` on success. The active-recording failure is described below. Callers must check the returned HRESULT; success is not proof of GPU completion.

This method returns `E_FAIL` if there is an actively recording command list referencing the command allocator. The debug layer will also issue an error in this case. See [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues) for other possible return values.

#### Debug layer

The debug layer will issue an error if it can't prove that there are no pending GPU references to command lists that have recorded commands in the allocator.

The debug layer will issue an error if `Reset` is called concurrently by multiple threads (on the same allocator object).

<a id="executebundle"></a>

### ID3D12GraphicsCommandList::ExecuteBundle

#### Declaration

```cpp
void ExecuteBundle(ID3D12GraphicsCommandList* pCommandList);
```

#### Behavior

Executes a bundle.

`pCommandList` must identify a closed BUNDLE from the same device. The caller must be an open DIRECT recording; a bundle cannot execute another bundle. The bundle's device-node selection must include the parent's execution node. Descriptor heaps explicitly set by the bundle must match the parent's corresponding heaps. Recording the call selects the bundle recording at that call, not a later re-recording of the same bundle object.

The [bundle entry/exit state contract](command-list-state.md#base-bundle-state), [root/descriptor inheritance](command-list-state.md#resource-binding) and [static descriptor/data promises](command-list-state.md#static-descriptors) remain canonical. A bundle does not inherit the parent's PSO or primitive topology. This wrapper is not predicated, but eligible work inside the bundle uses the inherited predicate under the [operation matrix](counters-queries-and-predication.md#predication-operation-matrix); its state effects are not skipped with that work.

The bundle's contents must satisfy the parent's [render-pass admission and dependencies](output-merger.md#render-pass-operation-surface). The [recording-generation and allocator-storage rules](#command-storage), [object/resource lifetime](#lifetime), [residency](resources.md#residency) and [binding lifetime](binding.md#table-indexing-and-descriptor-lifetime) apply through all uses of the selected recording. Resetting/re-recording the bundle object does not retarget an earlier parent recording, and resetting its allocator does not make old references valid. This CPU recording call neither submits the parent to a queue nor waits for GPU completion.

#### Parameters

##### pCommandList

Specifies the [ID3D12GraphicsCommandList](#executebundle) that determines the bundle to be executed.

#### Return values

This method returns no value. Recording failures are reported through the parent's [deferred Close result](#deferred-recording-errors), not a direct HRESULT returned by `ExecuteBundle`. The common first-recorded-error precedence remains applicable, including when a validation failure records `E_INVALIDARG`.

#### Runtime validation

The runtime will validate that the "callee" is a bundle and that the
"caller" is a direct command list. The runtime will also validate that
the bundle has been closed. If the contract is violated, the runtime
will silently drop the call.

Validation failure will result in [Close](#close) returning E_INVALIDARG.

#### Debug layer

The debug layer will issue an error if it detects that any resource referenced by the command list has been destroyed.

The debug layer will also validate that the command allocator associated with the bundle has not been reset since [Close](#close) was called on the command list.  This validation occurs at `ExecuteBundle` time, and when the parent command list is executed on a command queue.

<a id="bundle-driver"></a>

#### PFND3D12DDI_EXECUTE_BUNDLE

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_EXECUTE_BUNDLE )(
    D3D12DDI_HCOMMANDLIST, D3D12DDI_HCOMMANDLIST );
```

The first `D3D12DDI_HCOMMANDLIST` is the parent direct command list; the second is the closed bundle. Both `D3D12DDI_COMMAND_LIST_FUNCS_3D_0108::pfnExecuteBundle` and `D3D12DDI_COMMAND_LIST_FUNCS_3D_0114::pfnExecuteBundle` use this same signature and these ordinary driver handles. The API-handle table does not change this entry into an API-handle argument pair.

The UMD records execution of the selected bundle generation, preserving the [API context, state, predicate and lifetime contract](#executebundle). The ABI does not require either CPU expansion or one particular GPU indirection strategy. Passing the two handles transfers no COM reference or allocation ownership. The driver must preserve the selected recording's meaning when the bundle object is later reset; the allocator-storage lifetime obligation remains with the application. This `VOID` DDI uses [recording error reporting](#lifecycle-driver-errors), not an operation HRESULT or GPU-completion result.

<a id="lifecycle-driver"></a>

### Driver responsibilities and error reporting

The driver must preserve previously recorded command streams and bundle references across a command-list-object Reset while their allocator storage remains valid. A driver may copy recorded commands or reference their storage, but resetting the bundle object must not retarget an existing parent recording to the bundle's new commands. Allocator reset, not list-object reset, permits reclamation of the affected command storage under the application preconditions described above.

For DDI versions using the `_0040` reset arguments, the runtime supplies a command-recorder handle associated with the allocator's command pool. Earlier reset arguments supply a command-allocator handle. The initial pipeline-state object is not an argument to either reset structure: the runtime initializes pipeline and other applicable state with state-setting DDIs. This API behavior does not require an application to negotiate a DDI version.

Closing a list invokes the close-list DDI when no previously recorded error prevents it. Resetting an allocator invokes the corresponding pool/allocator storage-reset DDI; it is not a request to wait for GPU completion. The [driver recording-object model](#object-model) defines allocator/pool/recorder/list associations, recording-generation IDs, private storage and versioned creation/reset/destruction interfaces. Its [failed-recording rules](execution.md#failed-recording) define logical closure, recorder reuse and cleanup without guaranteed Close-DDI delivery. [Runtime UMD initialization](devices-and-capabilities.md#runtime-driver-initialization) owns capability and table negotiation; [command-list state](command-list-state.md) owns pipeline and other initial/reset state.

<a id="lifecycle-driver-errors"></a>

#### Deferred recording errors

`SetCommandListErrorCb` is used for errors encountered while executing
command list recording DDIs. There are only 3 errors which drivers
should pass to this function:

- `E_OUTOFMEMORY`
- `D3DDDIERR_DEVICEREMOVED`
- `D3DDDIERR_APPLICATIONERROR`

After the `SetCommandListErrorCb` DDI is called, the runtime will drop all
calls into the driver which record commands on the specified command
list.

A successful command-list Reset starts a new recording, but errors reported through the command-list error callback while initializing that recording are stored for Close to report. Reset's HRESULT does not replace the requirement to check Close.

Driver-reported errors are translated before the resulting command-list error is stored. A driver-reported `E_OUTOFMEMORY` remains `E_OUTOFMEMORY` unless the device has already been removed. Driver-reported device removal or application error removes the device and is translated to `DXGI_ERROR_DEVICE_REMOVED`; the more specific device reason is available from [GetDeviceRemovedReason](diagnostics.md#id3d12device-getdeviceremovedreason). If an earlier command-list error has already been recorded, it remains the error returned by Close and later Reset. Device removal does not replace that earlier stored error.

<a id="driver-recording-objects"></a>

### Driver recording objects and storage

<a id="object-model"></a>

#### Objects and recording lifetime

The application command allocator supplies storage for recorded commands; an
application command list is the object through which commands are recorded.
At the driver interface using the `_0040` recording-object protocol, a command
pool owns command storage, a command recorder supplies the CPU recording
machinery, and a driver command list identifies a command-list object.
The older protocol combines the pool/recording-storage role in a driver
command allocator.

An application allocator permits at most one recording list at a time.
This API restriction is not a one-recorder-per-pool DDI restriction. Several
driver recorders may target the same pool and record concurrently. Each
recorder may be used for only one recording at a time. The driver must support
concurrent recording through distinct recorders sharing a pool; this does not
permit concurrent calls on the same command-list object.

Reset associates a driver list's new recording with the supplied recorder.
Normal Close ends recording and releases that recorder's recording use.
The [failed-recording rules](#failed-recording) distinguish logical API
closure from delivery of the Close DDI. The recorder's use is a
recording lease, not allocation and destruction of a recorder for every
recording. Creation of an initially recording application list can require
both driver-list creation and recording initialization; there is no requirement
that each such DDI call identify a different recording.

Recorded commands remain backed by their pool after Close. An idle recorder
may be reused, retargeted or destroyed while older recordings execute, provided
their pool storage remains valid. Reusing the recorder or resetting the
command-list object does not reset that storage or prove GPU completion.
The [recorded-stream and bundle-storage rules](execution.md#command-storage)
apply independently of recorder reuse.

<a id="recording-identifiers"></a>

##### Recording-generation identifiers

The `UINT64 ID` in driver-list creation and reset identifies a recording
generation, not the persistent application or driver command-list object.
Valid IDs must be unique within the driver device, apart from eventual
64-bit wraparound. Zero and `UINT64_MAX` are reserved; `UINT64_MAX` denotes
no current recording, including initially closed creation.

Creation and an implicit reset that initialize the same recording may use
the same ID. A later recording established by application Reset receives
a new valid ID. The contract does not prescribe a counter, starting value,
ordering of IDs or uniqueness across distinct driver devices.

<a id="target-and-reclamation"></a>

##### Targets, reset and destruction

The runtime may change a recorder's pool target only while that recorder is
idle. An idle recorder may retain a stale, non-owning target identity; it does
not keep the target pool alive. Before recording resumes, the runtime must
establish a valid target association. This is not a null-handle unbinding
protocol.

A pool must not be reset while a CPU recording is using it or before all
GPU uses of its recorded storage have completed. As with application allocator
Reset, the application is responsible for GPU-completion synchronization.
Reset makes that storage available for reuse and invalidates the old
recordings, even if their command-list objects still exist. An invalidated
recording must not subsequently be submitted or selected for execution.
Destroying the pool likewise requires no active CPU recording or outstanding
GPU use and ends the validity of its recorded storage. Neither operation
waits for the application to make otherwise invalid use safe.

Before destroying a recorder, its associated command list must be closed or
destroyed. Destroying a command list may abandon an open recording without a
preceding Close DDI; the driver must release that recording's CPU recorder
use during abandonment. This does not allow destruction of a recorder still
used by a live recording list.

Destroying a list ends its driver-object lifetime, not the lifetime of
pool-backed recordings that are still executing. Driver cleanup must also
obey the [command-list resource-lifetime rule](execution.md#driver-responsibilities):
referenced resources may already have been destroyed. Cleanup must not
require an implicit Close that accesses those resources.

<a id="failed-recording"></a>

##### Failed recording and recorder reuse

A stored recording error makes the failed recording non-executable and
prevents that command-list object from being reset again. Application Close
still ends the logical recording and releases its allocator/recorder recording
use, even when the runtime omits the Close DDI. If the device remains usable,
a different compatible list may begin recording with that allocator/recorder
while the failed list object remains alive. This permission does not reset
pool storage or relax its GPU-use and reclamation requirements.

An error callback does not itself release the runtime's recording ownership.
In particular, an error reported during Reset or its state initialization
can be stored for Close to report even when the application Reset returns
`S_OK`. Until application Close or list destruction ends that recording,
the runtime must not reuse its recorder for another recording. The driver
may clean up failed-recording state earlier, provided it preserves the
other recordings and object lifetimes required by this contract. A retained
lifetime reference is distinct from active recording ownership.

The driver must tolerate later reuse, idle retargeting or destruction of the
recorder after logical recording closure without a preceding Close DDI.
The [associated-list destruction precondition](#target-and-reclamation)
uses this logical closed state, not guaranteed delivery of a Close DDI.
Later cleanup or destruction of the failed list must not release, reset or
invalidate recording state or backing allocations now used by a successor
recording, or dereference a recorder or pool object whose lifetime has ended.
The driver must not require an implicit Close or access to already-destroyed
referenced resources to perform that cleanup.

<a id="private-storage"></a>

#### Private storage and errors

For each allocator, pool, recorder or list, the runtime queries the matching
private size, allocates the supplied driver-private region, and supplies its
driver handle at creation. Size queries return a byte count as `SIZE_T`, not
an `HRESULT`, and do not construct the object. Creation arguments used for
sizing describe the object to be created; output/private handles are supplied
for creation, not returned as newly allocated COM objects by the driver.

The actual supplied private pointer is aligned to `MEMORY_ALLOCATION_ALIGNMENT`:
16 bytes on Win64 and 8 bytes on Win32. The runtime owns this region. The
driver owns auxiliary allocations it makes for the object and must release
them during destruction. The driver's Destroy DDI does not free the supplied
runtime-owned private region.

Creation returns an `HRESULT`. On failure the driver must clean up its partial
initialization and auxiliary allocations; the runtime does not call Destroy
for a failed creation. After successful creation, subsequent abandonment or
initialization failure requires destruction of that successfully created
object before its supplied storage is released.

The VOID command-list Reset and Close DDIs do not return the application method's `HRESULT`.
The [recording-error callback and deferred-error rules](execution.md#lifecycle-driver-errors)
govern recording failures and the runtime's suppression of later recording
calls. Application allocator Reset's GPU-completion precondition is not
implemented by waiting inside the pool/allocator reset DDI.

The [CPU threading contract](execution.md#threading) and the pool/recorder
concurrency rules above apply together. Interface selection and table/callback
lifetimes follow [Runtime UMD initialization](devices-and-capabilities.md#table-selection).
The runtime owns the API-to-DDI adaptation; applications do not negotiate
these DDI versions.

<a id="recording-descriptions"></a>

#### Shared recording descriptions

`D3D12DDI_COMMAND_LIST_TYPE` distinguishes direct-style recording from bundles.
It is not the application's full `D3D12_COMMAND_LIST_TYPE` enumeration;
compute, copy and video API enum values must not be cast to this DDI enum.
`QueueFlags` identifies the workload capabilities of the recording machinery.
The paging flag is a driver-interface flag, not an additional application
command-list type.

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

`CommandListFlags` carries diagnostic-marker controls, including the full-pipeline
marker flag named with the `_0010` suffix. It is not the application's
`D3D12_COMMAND_LIST_FLAGS` creation-flags type. `NodeMask` selects the list's
device node under the [device/node model](devices-and-capabilities.md#adapter-identity-and-linked-nodes).
Neither these fields nor queue flags replace the recording-generation ID.

<a id="legacy-allocators"></a>

<a id="command-pools"></a>

#### Command pools

The `_0040` protocol separates pool storage from the recorder. `PoolFlags`
has only the `NONE` value in this declaration. The size query reports private
pool bytes; Create initializes the supplied pool handle for the driver device.
Reset reclaims that pool's recording storage under the
[CPU/GPU preconditions](#target-and-reclamation); Destroy releases its
driver-owned allocations and ends the pool object.

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

`QueueFlags` describes the recorder's workload capabilities; `RecorderFlags`
has only the `NONE` value in this declaration. The size query reports private
recorder bytes; Create initializes the supplied recorder handle. Creation does
not begin a command-list recording or supply a pool target.

`PFND3D12DDI_COMMAND_RECORDER_SET_COMMAND_POOL_AS_TARGET_0040` takes, in order,
the driver device, recorder and pool handles. It establishes the recorder's
target under the [idle-target rules](#target-and-reclamation); it does not
reset the pool or invalidate its older recordings. Destroy releases the
recorder's driver-owned allocations under the associated-list precondition,
without reclaiming unrelated, still-valid pool-backed recordings.

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

#### Command-list creation and recording

The `_0040` size query reports private list bytes. Create takes the driver
device, creation description, supplied driver-private list handle and runtime
list handle, in that order. The runtime handle identifies the list when the
driver calls its runtime callbacks; it is not the private-storage handle.
The creation description contains no pool or recorder handle.

Reset takes the existing driver list and a description containing the recorder
for the new recording, its generation ID and marker flags. The recorder must
be available for that recording and have a valid target pool. Reset starts a
new recording without reclaiming old pool storage. The runtime supplies the
initial pipeline state and other applicable state through state-setting DDIs,
not through these reset arguments; the canonical
[initial/reset state](command-list-state.md) defines those contributions.

Close takes the driver list, finishes its recording and releases recorder use;
it neither submits the commands nor proves GPU completion. Destroy takes the
driver device and list handles. It releases list-owned auxiliary state and
supports [abandonment without Close](#target-and-reclamation). Both functions
are shared with the older allocator-based protocol.

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

### Current work-command handle representations

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

The current command-list layouts are alternative representations. In `D3D12DDI_COMMAND_LIST_FUNCS_3D_0108`, the ordinary draw/dispatch entries receive `D3D12DDI_HCOMMANDLIST`. Their API-compatible counterparts in `D3D12DDI_COMMAND_LIST_FUNCS_3D_0114` instead receive `D3D12DDI_API_HCOMMANDLIST`; all remaining ordered draw counts/starts, signed base vertex and dispatch group counts retain the linked logical API meanings.

The API handle identifies the application-side object/header, not the driver's ordinary command-list storage. The published `GetDriverCommandListHandle` helper obtains `pDriverObject` from that header. The driver must not treat the API handle itself as its ordinary private-object pointer. Neither the handle nor the header transfers COM ownership or changes the normal recording/object lifetime. The header's interface-table member does not make driver-private memory interchangeable with an application object.

These are conditional selected-table contracts, not a guarantee of bypass support or a particular performance benefit on every device. Changing representation does not relax input, state, resource, predicate, render-pass or recording-error requirements and does not prove that the runtime validated or clamped the arguments. Bundle execution retains its explicitly ordinary handle pair in both tables.

| Current member | Signature | Contract |
| --- | --- | --- |
| `D3D12DDI_COMMAND_LIST_FUNCS_3D_0108::pfnDrawInstanced` | `PFND3D12DDI_DRAWINSTANCED` | [Responsibility](vertex-processing.md#driver-draw) |
| `D3D12DDI_COMMAND_LIST_FUNCS_3D_0108::pfnDrawIndexedInstanced` | `PFND3D12DDI_DRAWINDEXEDINSTANCED` | [Responsibility](vertex-processing.md#driver-draw) |
| `D3D12DDI_COMMAND_LIST_FUNCS_3D_0108::pfnDispatch` | `PFND3D12DDI_DISPATCH` | [Responsibility](compute.md#driver-dispatch) |
| `D3D12DDI_COMMAND_LIST_FUNCS_3D_0108::pfnExecuteBundle` | `PFND3D12DDI_EXECUTE_BUNDLE` | [Responsibility](execution.md#bundle-driver) |
| `D3D12DDI_COMMAND_LIST_FUNCS_3D_0114::pfnDrawInstanced` | `PFND3D12DDI_DRAWINSTANCED_0114` | [Responsibility](vertex-processing.md#driver-draw) |
| `D3D12DDI_COMMAND_LIST_FUNCS_3D_0114::pfnDrawIndexedInstanced` | `PFND3D12DDI_DRAWINDEXEDINSTANCED_0114` | [Responsibility](vertex-processing.md#driver-draw) |
| `D3D12DDI_COMMAND_LIST_FUNCS_3D_0114::pfnDispatch` | `PFND3D12DDI_DISPATCH_0114` | [Responsibility](compute.md#driver-dispatch) |
| `D3D12DDI_COMMAND_LIST_FUNCS_3D_0114::pfnExecuteBundle` | `PFND3D12DDI_EXECUTE_BUNDLE` | [Responsibility](execution.md#bundle-driver) |

<a id="submission"></a>

## Submission and ordering

The submission and completion rules below apply to all supporting D3D12 command-queue types, including video decode, process, and encode. The core queue/fence methods are declared by `ID3D12CommandQueue`, `ID3D12Device`, and `ID3D12Fence`. `SetEventOnMultipleFenceCompletion` is declared by `ID3D12Device1`; `GetCreationFlags` is declared by `ID3D12Fence1`.

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

`ExecuteCommandLists` submits an array of command lists for execution.

Synchronization-only queues do not accept this operation; their supported
operation model is defined [above](#synchronization-only-queues).

#### Parameters

**NumCommandLists**

The number of command lists to be executed.

**ppCommandLists**

The array of [ID3D12CommandList](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nn-d3d12-id3d12commandlist) command lists to be executed.

#### Ordering and recording lifetime

Calling `ExecuteCommandLists` twice in succession on the same queue (from the same thread, or different threads) guarantees that the first workload (A) finishes before the second workload (B). Calling `ExecuteCommandLists` with *two* command lists allows the driver to merge the two command lists such that the second command list (D) may begin executing work before all work from the first (C) has finished. Specifically, your application is allowed to insert a fence signal or wait between A and B, and the driver has no visibility into this, so the driver must ensure that everything in A is complete before the fence operation. There is no such opportunity in a single call to the API, so the driver is able to optimize that scenario.

The driver is free to patch the submitted command lists. It is the calling application’s responsibility to ensure that the graphics processing unit (GPU) is not currently reading any of the submitted recorded command streams from a previous execution.

Applications are encouraged to batch together command list executions to reduce fixed costs associated with submitted commands to the GPU.

The no-concurrent-reexecution rule concerns a particular recorded stream, not every recording ever made through the list object. Reset/re-recording may produce a new stream while an older stream executes, with valid backing storage and resources; see [recorded commands and allocator storage](#command-storage). Returning from `ExecuteCommandLists` does not establish GPU completion or make allocator/resource storage reusable.

#### Return values

`ExecuteCommandLists` returns no value. Submission failures are not returned as an `HRESULT` from this method.

<a id="validation"></a>

#### Runtime validation

Bundles can't be submitted to a command queue directly. If a bundle is passed to this method, the runtime will drop the call. The runtime will also drop the call if the [Close](#close) function has not successfully closed one or more of the command lists.

The runtime will detect if the command allocators associated with the command lists have been reset after [Close](#close) was called. The runtime will drop the call and remove the device in this situation.

Submitted lists must match the queue's command-list type and have compatible node masks. A list created initially closed by `CreateCommandList1` must first begin a recording with `Reset` and successfully close it; an object that has never begun a recording is not executable. An empty but successfully closed recording is distinct from an object that has never begun recording.

Runtime-detected submission failures drop the submission and remove the device. This includes invalid recorded/closed state, allocator-generation invalidation, and type/node incompatibility. It is not a guarantee that every invalid application action is detected by the retail runtime.

#### Debug layer

Debug validation checks previous execution of the recorded stream, deferred resource-transition and query requirements, and tracked resource lifetimes. Applications must meet those usage requirements whether or not validation is enabled; they must not depend on universal retail detection or device removal for every barrier/query or overlapping-execution error.

The debug layer issues an error if it detects that any resource referenced by the command lists, including queries, has been destroyed.

<a id="execute-command-lists-ddi"></a>

### PFND3D12DDI_EXECUTECOMMANDLISTS

UMD's `PFND3D12DDI_EXECUTECOMMANDLISTS` function executes an array of command lists submitted by an application.

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_EXECUTECOMMANDLISTS ) (
    D3D12DDI_HCOMMANDQUEUE,
    UINT Count,
    _In_reads_(Count) CONST D3D12DDI_HCOMMANDLIST* pCommandLists
    );
```

The first argument identifies the UMD queue. `Count` gives the number of
driver command-list handles in `pCommandLists`; these are not COM interface
pointers. The UMD executes the supplied recordings under the
[application ordering and recording-lifetime contract](execution.md#execute-command-lists)
and [driver recording-storage rules](execution.md#object-model).
Runtime adaptation does not establish a universal one-to-one relationship
between an application call, a DDI call and a kernel command-buffer submission.

Drivers must implement command list execution DDIs in a free threaded
manner so that multiple queues can accept command lists for execution
concurrently.

On a kernel-mediated submission path, when the command list execution DDI is called, the driver must immediately
call the command buffer submission callback. Drivers may not defer
submission of command buffers until a later time.

The DDI returns no `HRESULT`. Returning does not establish GPU completion
or permit reuse of recording storage still in use. An execution failure that
the UMD cannot resolve is reported through `PFND3D12DDI_SETERROR_CB`, not
through the command-list recording-error callback or an application return
value. Callback failures may be handled within the execution attempt, but
do not provide a recoverable execution-error return channel to the application.
Device removal observation remains governed by the
[completion/removal rules](execution.md#completion-lifetime).

<a id="submission-threading"></a>

### Submission threading

Applications can submit command lists to any command queue from multiple threads. The runtime will perform the work of serializing these requests in the order of submission.

Serialization is per queue; it does not establish dependencies between independent queues. Use [queue signals](#queue-signal) and [queue waits](#queue-waits) to express inter-queue dependencies. If CPU threads require a particular submission order, synchronize those threads rather than inferring an order from unsynchronized concurrent calls.

<a id="submission-barriers"></a>

### Submission boundaries and resource barriers

For successive submissions on the same queue, D3D12 requires a full finish and flush of all GPU work at `ExecuteCommandLists` completion. Therefore, any writes to a resource during a preceding `ExecuteCommandLists` scope will be fully completed when that resource is needed in a subsequent `ExecuteCommandLists` scope.  However, drivers are not expected to keep track of when a resource was last written to.  So in addition to sync, a transition from a WRITE state may force a cache flush, even if the resource is already up-to-date from an earlier cache flush.

#### Legacy resource-state rules

Legacy resource-state behavior at submission boundaries is defined in [Common-state promotion and decay](synchronization.md#legacy-promotion-and-decay).

#### Enhanced layouts and cross-queue access

Texture layout transitions and queue/layout compatibility are defined in [Synchronization and barriers](synchronization.md#layout-transitions).

Fence ordering does not select a resource's legacy state or change a texture's enhanced layout. Apply the relevant [legacy multi-queue state rules](https://learn.microsoft.com/en-us/windows/win32/direct3d12/user-mode-heap-synchronization#multi-queue-resource-access), [enhanced queue-layout compatibility](synchronization.md#queue-compatibility), [access compatibility](synchronization.md#queue-compatibility), and [copy-queue rules](synchronization.md#queue-compatibility). These requirements are distinct from waiting for a producer's queue signal.

Suspended/resumed render passes must be paired within one `ExecuteCommandLists` group; see [render-pass recording and execution context](command-list-state.md#render-pass). A list boundary inside a batch is not a new submission boundary. Fine-grained [fence barriers](fence-barriers.md) synchronize selected barrier work within a submission.

<a id="submission-driver"></a>

### Runtime and driver submission responsibilities

The user-mode driver's `PFND3D12DDI_EXECUTECOMMANDLISTS` function executes an array of command lists submitted by an application.

`PFND3D12DDI_EXECUTECOMMANDLISTS` receives the driver's queue handle, a count, and an array of driver command-list handles. The application API submits interface pointers; the driver entry point does not receive that application pointer array. Driver execution must preserve the submission-boundary ordering and completion/flush requirements above.

Queue `Signal`/`Wait` operations preserve the queue's ordering contract even when runtime, operating-system, and driver synchronization transports differ. Do not infer a universal one-to-one fence-DDI call sequence from the API signatures. [Recorded storage and driver error reporting](#lifecycle-driver) remain applicable.

<a id="driver-submission-transport"></a>

### Driver submission transport

The callbacks below are not a requirement that every submission transport use
the same kernel call sequence.

<a id="shared-callback-contract"></a>

#### Shared callback contract and handle domains

The shared callbacks are supplied through the device's `pKTCallbacks`
`D3DDDI_DEVICECALLBACKS` table. Their first `HANDLE hDevice` identifies the
runtime device callback context, not a UMD-private `D3D12DDI_HDEVICE` or an
application command queue. Table lifetime and interface selection follow
[Runtime UMD initialization](devices-and-capabilities.md#table-selection).

Context and hardware-queue `HANDLE` values returned by these D3D12 runtime
callbacks are opaque runtime handles. The runtime translates them to kernel
handles when performing the operation. In contrast, returned `D3DKMT_HANDLE`
synchronization-object values are OS synchronization-object handles. Neither
kind is interchangeable with a UMD private-fence handle or a COM pointer.

In the declarations below, `_In_` descriptions provide the request and
`_Inout_` descriptions also return the indicated results. Array counts and
fixed-array capacities are part of the corresponding payload contract;
counts must describe the supplied arrays, and reserved flag bits must be
zero. The callback's `HRESULT` reports its operation, not GPU completion.
Some removal paths can return `S_OK` after the device has failed, so success
does not independently establish a healthy device.

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

The shared CreateContext forms create device-associated contexts for driver
internal work. Both supply node ordinal, engine affinity, context flags and
private KMD data, returning `hContext`; the non-virtual form additionally
returns the software-submission command buffer and allocation/patch lists.
The virtual form creates a GPU-virtual-address context. These are distinct
from [queue/group-associated context callbacks](command-queues.md#context-creation-callbacks).

CreateHwQueue supplies a context handle and hardware-queue flags/private
data, and returns a hardware-queue handle plus its progress-fence handle and
CPU/GPU addresses. At the `_0050` queue/group interface, the shared creation
callback is for internal contexts, not for creating a global hardware queue
against a context owned by an application queue or scheduling group.

The UMD requests destruction of its internal hardware queues and contexts
through the matching shared Destroy callbacks. These actually destroy the
internal objects; the shared context callback is not the
[legacy D3D12 compatibility no-op](command-queues.md#legacy-destroy-context).
Shared DestroyContext rejects queue/group-owned contexts, and shared
DestroyHwQueue rejects queue/group-owned contexts or hardware queues.
The shared callbacks are not an escape from the managed-object creation
window or runtime ownership of application-associated objects.

If the specified context has not finished the work that is currently queued to it, the `pfnDestroyContextCb` function blocks until the context finishes its work and then returns.

<a id="kernel-submission"></a>

#### Kernel-mediated command-buffer submission

```cpp
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_RENDERCB)(
    _In_ HANDLE hDevice, _Inout_ D3DDDICB_RENDER*);
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_SUBMITCOMMANDCB)(
    _In_ HANDLE hDevice, _In_ CONST D3DDDICB_SUBMITCOMMAND*);
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_SUBMITCOMMANDTOHWQUEUECB)(
    _In_ HANDLE hDevice, _In_ CONST D3DDDICB_SUBMITCOMMANDTOHWQUEUE*);
```

The `pfnRenderCb` function submits the current command buffer for rendering to the display miniport driver.

`pfnSubmitCommandCb` is used to submit command buffers on contexts that support graphics processing unit (GPU) virtual addressing. These contexts generate commands directly from user mode, manage their own command buffer pool and don't make use of allocation or patch location list.

`pfnSubmitCommandCb` replaces the old [pfnRenderCb](#kernel-submission) for such contexts and must be used in its place. Contexts that operate in legacy patch mode must continue to use the old `pfnRenderCb`.

Although the user mode driver doesn't generate patch locations it must still generate a list of the primaries that are being written to. The video memory manager uses the allocation list to determine which primary allocations are being referenced for write by each command buffer. This information is used to synchronize rendering to the primaries with `Flip` operations.

| Callback | Request and result responsibilities |
|---|---|
| `PFND3DDDI_RENDERCB` | Supply the context, command offset/byte length, allocation and patch counts, broadcast contexts and any resize requests in `D3DDDICB_RENDER`. The in/out payload returns the next command-buffer/list information for continued legacy recording. |
| `PFND3DDDI_SUBMITCOMMANDCB` | Supply GPU command address/length, broadcast contexts, written primaries and submission private data in `D3DDDICB_SUBMITCOMMAND`. Broadcast contexts must belong to one queue and must not be scheduling-group-owned contexts. |
| `PFND3DDDI_SUBMITCOMMANDTOHWQUEUECB` | Supply the hardware-queue handle, command address/length, progress-fence ID, written primaries and private data in `D3DDDICB_SUBMITCOMMANDTOHWQUEUE`. The runtime translates the hardware-queue handle and performs the kernel submission. |

Submission private data is input to the KMD, not a return-data channel.
The runtime may augment the submitted written-primary set with tracked
application references. A successful callback is not a GPU-completion
notification; the callback also does not replace the driver's obligations
to preserve queue ordering and report an unresolvable execution failure.

<a id="completion"></a>

## Completion and fences

<a id="fence-operations"></a>

### Fence values and timelines

The application-controlled timelines below use writable fences. System-controlled [protected-session status fences](#status-fences) are read-only and do not represent application-work completion. [Command-list-scoped fences](#command-list-scoped-fences) instead use the scoped barrier model, not this ordinary queue timeline.

The multi-engine API provides explicit APIs to create and synchronize using fences. A fence is a synchronization construct controlled by a `UINT64` value. Fence values are set by the application. A signal operation modifies the fence value and a wait operation blocks until the fence has reached the requested value or greater. An event can be fired when a fence reaches a certain value.

The [`Signal`](#fence-signal) method on the [`ID3D12Fence`](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nn-d3d12-id3d12fence) interface updates a fence from the CPU side. This update occurs immediately. The [`Signal`](#queue-signal) method on [`ID3D12CommandQueue`](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nn-d3d12-id3d12commandqueue) updates a fence from the GPU side. This update occurs after all other operations on the command queue have been completed.

A fence *may* be *rewound*. This means that the fence value does not need to solely increment. If a `Signal` operation is enqueued on two different command queues, or if two CPU threads are both calling `Signal` on a fence, there may be a race to determine which `Signal` completes last, and therefore which fence value is the one which will remain. If a fence is rewound, any new waits (including `SetEventOnCompletion` requests) will be compared against the new lower fence value, and therefore may not be satisfied, even if the fence value had previously been high enough to satisfy them. If a race does occur, between a value which will satisfy an outstanding wait, and a lower value which will not, the wait *will* be satisfied regardless of which value remains afterwards.

The fence APIs provide powerful synchronization functionality but can create potentially difficult to debug issues. It is recommended that each fence only be used to indicate progress on one timeline to prevent races between signalers.

A queued wait blocks subsequent work on that queue, not the calling CPU thread. The operation that can satisfy it must be able to run: placing the only satisfying signal behind an unsatisfied wait on the same queue does not make progress.

<a id="status-fences"></a>

### Protected-session status fences

The D3D12 protected resource session has a status fence whose fence value is incremented whenever protected content becomes invalid.  Status may be pulled from the protected session.  This typically happens when the system enters a sleep state and wakes back up, but could also be triggered by tamper protection from driver or hardware.

[`ID3D12ProtectedSession::GetStatusFence`](../ProtectedResources.md#method-id3d12protectedsessiongetstatusfence) returns the fence for the protected session. From the fence, we can get
the current uniqueness validity value (using `GetCompletedValue`), and add
monitors for change of its value. This is a read-only fence.

Read-only status fences must not be signaled through `ID3D12Fence::Signal`, `ID3D12CommandQueue::Signal`, or `ID3D12Device3::EnqueueMakeResident`. Their value changes indicate protected-content invalidation, not completion of submitted application work. These writability and value-meaning rules are separate from the [monitoring-capability restrictions](#fence-flags).

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

| Flag | Value | Meaning |
|---|---|---|
| `D3D12_FENCE_FLAG_NONE` | `0` | No options are specified. |
| `D3D12_FENCE_FLAG_SHARED` | `0x1` | The fence is shared. |
| `D3D12_FENCE_FLAG_SHARED_CROSS_ADAPTER` | `0x2` | The fence is shared with another GPU adapter. |
| `D3D12_FENCE_FLAG_NON_MONITORED` | `0x4` | The fence is of the non-monitored type. Non-monitored fences should only be used when the adapter doesn't support monitored fences, or when a fence is shared with an adapter that doesn't support monitored fences. |

<a id="fence-barrier-options"></a>

#### Fence-barrier options

<a id="allow-command-list-barriers"></a>

##### D3D12_FENCE_FLAG_ALLOW_COMMAND_LIST_BARRIERS

`D3D12_FENCE_FLAG_ALLOW_COMMAND_LIST_BARRIERS` requests barrier support; the actual fence must report that flag to be eligible for command-list `SignalBarrier` or `WaitBarrier`.
Fences created with `D3D12_FENCE_FLAG_ALLOW_COMMAND_LIST_BARRIERS` set but without `D3D12_FENCE_FLAG_ALLOW_QUEUE_AND_CPU_SYNC` bit also set are referred to as [Command List Scoped Fences](#command-list-scoped-fences).

<a id="allow-queue-and-cpu-sync"></a>

##### D3D12_FENCE_FLAG_ALLOW_QUEUE_AND_CPU_SYNC

This flag is necessary to support GPU command-buffer-level fence synchronization between multiple queues or between the GPU and CPU.

`D3D12_FENCE_FLAG_ALLOW_QUEUE_AND_CPU_SYNC` must be combined with `D3D12_FENCE_FLAG_ALLOW_COMMAND_LIST_BARRIERS`.

If an app doesn't require queue or CPU sync, then it is recommended not setting this flag as it may significantly reduce barrier performance.

All fences created with `D3D12_FENCE_FLAG_SHARED` or `D3D12_FENCE_FLAG_SHARED_CROSS_ADAPTER` require Queue and CPU sync. As such, the `D3D12_FENCE_FLAG_SHARED` and `D3D12_FENCE_FLAG_SHARED_CROSS_ADAPTER` bits cannot be used when `D3D12_FENCE_FLAG_ALLOW_COMMAND_LIST_BARRIERS` is set without also setting `D3D12_FENCE_FLAG_ALLOW_QUEUE_AND_CPU_SYNC`.

Fence-barrier use requires `D3D12_FENCE_FLAG_ALLOW_COMMAND_LIST_BARRIERS` explicitly. For a shared or cross-adapter fence, also request `D3D12_FENCE_FLAG_ALLOW_QUEUE_AND_CPU_SYNC`. Sharing alone does not supply barrier eligibility. Creation can fail when the device/platform cannot supply the required GPU-accessible fence; a flag-only `S_FALSE` probe does not test that construction path.

<a id="fence-observation-requirements"></a>

#### Creation and observation requirements

`D3D12_FENCE_FLAG_SHARED_CROSS_ADAPTER` requires `D3D12_FENCE_FLAG_SHARED`. `D3D12_FENCE_FLAG_NON_MONITORED` creation requires both sharing flags and adapter support for non-monitored fences. Unsupported flag combinations fail with `E_INVALIDARG`.

Adapter fence support is described by [`DXGI_ADAPTER_DESC3::Flags`](https://learn.microsoft.com/en-us/windows/win32/api/dxgi1_6/ns-dxgi1_6-dxgi_adapter_desc3), including `DXGI_ADAPTER_FLAG3_SUPPORT_MONITORED_FENCES` and `DXGI_ADAPTER_FLAG3_SUPPORT_NON_MONITORED_FENCES`. When `IDXGIAdapter4` is available, obtain the description through [`IDXGIAdapter4::GetDesc3`](https://learn.microsoft.com/en-us/windows/win32/api/dxgi1_6/nf-dxgi1_6-idxgiadapter4-getdesc3).

The complete [shared-fence export/open and handle contract](sharing-and-interoperability.md#sharing-synchronization) defines how participating devices and processes obtain the same fence. Exporting or opening a handle does not signal or wait for the fence, supply command-list-barrier eligibility or relax these creation and CPU-observation requirements.

Non-monitored fences are used for GPU-side synchronization; they do not provide the CPU progress-observation operations of monitored fences. `ID3D12Fence::Signal` and `ID3D12Fence::SetEventOnCompletion` reject a non-monitored fence with `E_INVALIDARG`. `GetCompletedValue` is invalid for a non-monitored fence and returns `UINT64_MAX`; that value is not a completed-work measurement. Multi-fence CPU notification/wait also requires CPU-wait-capable fences, not non-monitored fences. `GetCreationFlags` is a property query, not a progress query, and is not prohibited by this restriction. Non-monitored instances do not report `D3D12_FENCE_FLAG_ALLOW_COMMAND_LIST_BARRIERS` and are not eligible for command-list fence barriers.

[`ID3D12Device3::EnqueueMakeResident`](resources.md#enqueue-make-resident) is another fence-value producer. Its eligibility and completion rules are defined with residency. Its signal indicates completion of residency work, not completion of the application's GPU accesses to those resources.

<a id="command-list-scoped-fences"></a>

### Command-list-scoped fences

Command List Scoped fences are fences created with the `D3D12_FENCE_FLAG_ALLOW_COMMAND_LIST_BARRIERS` bit set but without the `D3D12_FENCE_FLAG_ALLOW_QUEUE_AND_CPU_SYNC` bit set. Command List Scoped fences are usable with `ID3D12Fence::Signal` and command list `SignalBarrier` and `WaitBarrier` methods, but cannot support `ID3D12CommandQueue::Wait`, `ID3D12CommandQueue::Signal`, or `ID3D12Fence::SetEventOnCompletion`. Command List Scoped fences are designed to efficiently manage barrier dependencies within a single command list or a set of command lists in the same `ExecuteCommandLists` scope. The primary use for Command List Scoped fences is to perform efficient split barrier operations.

`WaitBarrier` values using Command List Scoped fences must already be satisfied either by the most recent preceding `SignalBarrier` operation in the same command queue or by `ID3D12Fence::Signal` called prior to GPU timeline execution of the submitted command list containing the `WaitBarrier`.

`ID3D12Fence::GetCompletedValue` always returns UINT64_MAX for Command List Scoped fences. Signaling a Command List Scoped fence currently in use in an in-execution command list by other command list, CPU or queue is invalid.

Unlike Monitored fences, Command List Scoped fences are not internally signaled to UINT64_MAX upon device removal. However, `ID3D12Fence::GetCompletedValue` for Command List Scoped fences still returns UINT64_MAX while a device is in a removed state.

A CPU `Signal` initializes the scoped fence value before GPU use; it must not race an in-flight scoped-fence use. The scalar `GetCompletedValue` result is always `UINT64_MAX`, not a progress measurement. Multi-fence CPU notification also requires CPU-wait-capable fences and cannot observe command-list-scoped fence completion. Creation/property queries do not turn this mode into an ordinary CPU/queue timeline.

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

`CreateFence` creates a fence object.

#### Parameters

**InitialValue**

The initial value for the fence.

**Flags**

A combination of [D3D12_FENCE_FLAGS](#fence-flags)-typed values that are combined by using a bitwise OR operation. The resulting value specifies options for the fence.

**riid**

The globally unique identifier (**GUID**) for the fence interface ([ID3D12Fence](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nn-d3d12-id3d12fence)). The **REFIID**, or **GUID**, of the interface to the fence can be obtained by using the `__uuidof()` macro. For example, `__uuidof(ID3D12Fence)` will get the **GUID** of the interface to a fence.

**ppFence**

A pointer to a memory block that receives a pointer to the [ID3D12Fence](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nn-d3d12-id3d12fence) interface that is used to access the fence.

`ppFence` may be `NULL` to check the fence flags without creating a fence object. This path returns `S_FALSE` when flag validation succeeds; it does not establish that object allocation, GPU-accessible backing, or the requested interface would succeed.

#### Return values

Returns `S_OK` if a fence is created; failures return one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

`S_FALSE` is the no-object validation result described above, not a returned fence interface.

<a id="fence-creation-flags"></a>

### ID3D12Fence1::GetCreationFlags

#### Declaration

```cpp
D3D12_FENCE_FLAGS GetCreationFlags();
```

#### Return values

`GetCreationFlags` returns the flags used to create the fence.

The result describes the fence's effective creation properties, not a guarantee that every requested option survived construction. In particular, a non-monitored instance does not report `D3D12_FENCE_FLAG_ALLOW_COMMAND_LIST_BARRIERS`; requesting the bit alone does not make that object barrier eligible. Use the actual properties and capability rules, not the requested mask, to determine eligibility.

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

`FenceValue.BaseAddress` describes the value's GPU placement when supplied.
`FenceMonitoredValue` is a retained, unused placement in this contract. The
runtime supplies a zero `BaseAddress` there; it does not identify a second
usable GPU location.

`Flags` is also retained and unused in this contract. The declared `NONE`
and `BOTTOM_OF_PIPE` values do not impose additional signal-placement or
ordering behavior. The [queue timeline and ordering rules](execution.md#fence-operations),
not this field, determine operation semantics. In particular, the
`BOTTOM_OF_PIPE` name is not an additional completion guarantee.

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

`FenceType` selects the active union member and the
[creation protocol](#fence-creation-lifecycle). Command-list-scoped creation
requires the applicable [fence-barrier support and API flags](execution.md#fence-flags);
the description's version suffix alone does not establish support for every
fence kind. The [size-query rules](#fence-private-sizing) determine which
description fields are valid during sizing, independently of creation.

<a id="fence-private-sizing"></a>

#### Fence private-size queries

```cpp
typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALCPRIVATEFENCESIZE_0116 )( D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATE_FENCE_0116* );
```

`PFND3D12DDI_CALCPRIVATEFENCESIZE_0116` returns the required driver-private
storage size in bytes as `SIZE_T`. The device handle supplies the driver
device context.

Within the `_0116` creation description supplied to the size query,
only `FenceType` is valid. The remaining payload is zero-initialized, not
a complete creation request. The driver must calculate the size without
consuming creation-only payload data or dereferencing native-create,
native-open or command-list-scoped output pointers, where applicable to the selected fence kind. Those pointers are null
in the size query; the applicable creation call supplies its payload later.

For `D3D12DDI_FENCE_TYPE_OPENED_NATIVE`, the returned size must accommodate
both opened-native and monitored fence creation. The runtime may use that
same private allocation for `D3D12DDI_FENCE_TYPE_MONITORED` creation after a
failed native-open attempt, without another size query or reallocation.
This requirement does not make the reported sizes identical for every
fence kind or device; it requires the opened-native size result to cover
both of these possible uses.

<a id="fence-creation-lifecycle"></a>

#### Fence creation and destruction

The following DDIs initialize or destroy UMD fence state. A CreateFence DDI
is also used to initialize a driver object for an opened shared fence; its
name does not mean that every invocation creates a new OS synchronization
object. The runtime selects the form from the negotiated device table and
the representation from the OS/device fence capabilities and application
request; the function-pointer revision alone does not choose `FenceType`.

```cpp

typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATEFENCE_0116 )( D3D12DDI_HDEVICE, D3D12DDI_HFENCE, D3D12DDI_HRTFENCE, _In_ CONST D3D12DDIARG_CREATE_FENCE_0116* );

typedef VOID ( APIENTRY* PFND3D12DDI_DESTROYFENCE )( D3D12DDI_HDEVICE, D3D12DDI_HFENCE );
```

The device argument identifies the UMD device. `D3D12DDI_HFENCE` identifies
the runtime-provided driver-private region, not an OS synchronization object.
The size query returns required private bytes, excluding runtime storage;
the actual private pointer is aligned to 16 bytes on Win64 and 8 bytes on
Win32. The UMD initializes that region and owns its auxiliary allocations,
but must not free the runtime-provided region.

The monitored payload's `D3D12DDI_FENCE` contains `FenceValue` and
`FenceMonitoredValue` GPU-VA placements and `Flags`. In the runtime's
monitored-fence creation path, `FenceValue.BaseAddress` supplies the available
GPU address, `FenceMonitoredValue.BaseAddress` is zero and `Flags` is
`D3D12DDI_FENCE_FLAG_BOTTOM_OF_PIPE`. A zero value address supplies no GPU
backing location; driver-object creation alone does not establish that a
fence can be used by a GPU fence barrier.

Creation receives `D3D12DDI_HRTFENCE`, the runtime fence association used
by the native callbacks. `FenceType` selects the creation payload.

For the callback that creates or opens this runtime-associated native fence,
the UMD supplies the received `hRTFence`. A null callback association instead
denotes a separate UMD-internal object, with the distinct ownership described
in the [native-callback contract](#native-fence-callbacks).

| `FenceType` | Creation payload and UMD responsibility |
|---|---|
| `D3D12DDI_FENCE_TYPE_MONITORED` | Consume `MonitoredFenceArgs`, the runtime-supplied monitored backing description. The runtime manages the associated OS synchronization object. |
| `D3D12DDI_FENCE_TYPE_NATIVE` | Use `pNativeFenceArgs` with the native-create callback to create the OS object and obtain its handle/mappings. |
| `D3D12DDI_FENCE_TYPE_OPENED_NATIVE` | Follow the versioned shared-open protocol below; do not treat an opened fence as a fresh native-create request. |
| `D3D12DDI_FENCE_TYPE_COMMAND_LIST_SCOPED` | Return the scoped CPU value address through `CLScopedFenceArgs.ppFenceValue`, as defined below. |

`pNativeFenceOpenArgs` supplies the shared-open request, and the UMD
calls the native-open callback to perform the open and exchange private data.
The [native-callback ownership and failure rules](#native-fence-callbacks)
apply; an opened-native failure and monitored retry must also satisfy the
[sizing envelope](#fence-private-sizing).

Creation returns `S_OK` on success or a failing `HRESULT`. On failure the
UMD unwinds its partial state and auxiliary allocations; the runtime does
not call DestroyFence for that failed UMD creation. Successful creation
requires destruction if the driver object is later retired or abandoned,
including after a subsequent application-object initialization failure.
DestroyFence receives the UMD device and successful driver fence handle,
returns no `HRESULT`, and releases UMD state without freeing the supplied
private region or independently releasing a runtime-owned OS object.

The runtime calls DestroyFence before releasing its associated OS-object
ownership. Monitored, native and command-list-scoped representations have
driver-visible objects on these paths; a runtime-managed legacy non-monitored
fence does not imply a UMD CreateFence/DestroyFence pair. A size query alone
does not commit the runtime to subsequently creating a driver object.
Application [fence lifetimes and operation restrictions](execution.md#completion)
remain separate from this transport selection.

<a id="scoped-fence-output"></a>

#### Command-list-scoped fence output

For command-list-scoped creation, `CLScopedFenceArgs` supplies the output
description defined in [Fence backing and creation descriptions](#fence-creation-descriptions).

Unlike other fence creation DDI args, the `D3D12DDI_COMMAND_LIST_SCOPED_FENCE` arguments have an output parameter, expecting the driver to provide the CPU address of the CL-scoped fence. The driver-provided address contains the most current CL-Scoped fence value at the start and end of command buffer execution. It is not expected that this address is updated as the fence is signaled during command buffer execution on the GPU.

Successful scoped creation must write a non-null, suitably aligned, writable
`UINT64` value address through `ppFenceValue`. The runtime writes the
application's initial fence value to that slot after the UMD creation DDI
succeeds, and uses the slot for CPU Signal operations. The UMD must ensure
the backing remains valid until fence destruction; the output cannot refer
to temporary storage that expires when the creation call returns. This does
not require one particular allocation mechanism or transfer ownership of
UMD-managed backing to the runtime.

This value address is not a native OS synchronization-object handle, and its
boundary-update contract is not a promise of per-signal CPU observation
during GPU command-buffer execution. The
[command-list-scoped API restrictions](fence-barriers.md#fence-kinds)
and modern [size-query input rules](#fence-private-sizing) still apply:
`ppFenceValue` is not a live output slot during sizing.

<a id="native-fence-callbacks"></a>

#### Native-fence creation and opening callbacks

The UMD calls the runtime's native-fence callbacks to create or open an OS
native-fence synchronization object and exchange private driver data with
the kernel-mode driver. These are driver-to-runtime calls, not UMD-implemented
creation DDIs.

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

`hRTDevice` identifies the runtime device context for the operation.
`hRTFence` optionally associates the result with a runtime fence object;
it is not a UMD private-fence handle or the OS synchronization-object handle.
`pArgs` carries the native creation request or shared NT-handle open request.
On success, the in/out payload returns the OS synchronization-object handle,
fence mappings and updated private driver data. The callback's `HRESULT`
reports success or failure of that operation, not success of the enclosing
UMD creation DDI.

<a id="ownership"></a>

##### Ownership

With a non-null `hRTFence`, the runtime adopts the created or opened OS
synchronization object and owns its release. The UMD owns its driver-side
state and auxiliary allocations, not independent destruction of that
runtime-associated OS object.

With a null `hRTFence`, the callbacks may create or open UMD-internal native
fences independently of an application fence object. The UMD is responsible
for eventually releasing the returned OS synchronization object through the
appropriate destruction path; no application-fence runtime object will
perform that cleanup.

<a id="native-fence-creation-failure"></a>

##### Failure after callback success

A successful runtime-associated callback does not commit the enclosing UMD
CreateFence DDI to success. The UMD may still return a failing `HRESULT`.
It must unwind its own partial driver state and UMD-owned auxiliary objects.
The runtime does not call DestroyFence for a failed UMD CreateFence DDI.

The runtime remains responsible for releasing the OS synchronization object
already adopted through the callback. It must release that object if the
attempt is abandoned, and before retrying with another representation.
Such a retry must also meet the [private-sizing requirements](#fence-private-sizing);
callback success is not permission to leak an earlier OS object, overwrite
an outstanding ownership association or use an insufficient private allocation.

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

Use this method to set a fence value on the queue timeline. Use [ID3D12Fence::Signal](#fence-signal) to set a fence from the CPU side.

The target must be writable; [read-only status fences](#status-fences) cannot be signaled. Command-list-scoped fences cannot be used with queue `Signal`.

#### Parameters

**pFence**

A pointer to the [ID3D12Fence](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nn-d3d12-id3d12fence) object.

**Value**

The value to set the fence to.

#### Return values

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/win32/direct3d12/d3d12-graphics-reference-returnvalues).

A successful return on a device that has not failed queues the signal; it does not wait for the GPU to reach it. The completion relationship is defined in [Fence values and timelines](#fence-operations). A [native UMD device-failure report](execution.md#native-queue-errors) need not be reflected as failure from this call.

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

**pFence**

A pointer to the [ID3D12Fence](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nn-d3d12-id3d12fence) object.

**Value**

The value that the command queue is waiting for the fence to reach or exceed.

The threshold refers to the fence's synchronization value, not to a sentinel from an invalid CPU query. See [CPU-observation restrictions](#fence-flags) and [device-removal interpretation](#completion-lifetime). Command-list-scoped fences cannot be used with queue `Wait`.

#### Return values

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/win32/direct3d12/d3d12-graphics-reference-returnvalues).

A [native UMD device-failure report](execution.md#native-queue-errors)
need not be reflected in a failing return from this call; device status and
the API's `HRESULT` remain distinct observations.

<a id="queue-signal-wait"></a>

### Queue Signal and Wait DDIs

`PFND3D12DDI_SIGNAL_FENCE` and `PFND3D12DDI_WAIT_FOR_FENCE` receive the driver
queue handle and a fence-operation description. `Fence` and `Value` identify
the requested fence operation; `PhysicalAdapterMask` is an output used by the
runtime-broadcast path described below. These DDIs return no `HRESULT`;
their signatures are not the application methods' return-value contract.
The [application fence timelines and queue ordering](execution.md#fence-operations)
remain applicable. These are UMD queue-DDI contracts;
[synchronization-only queues](execution.md#synchronization-only-queues)
use their runtime-managed path rather than a UMD command-queue object.

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

For native fences, the UMD is responsible for the requested signal or wait,
using the appropriate runtime/OS handoff or driver-submitted GPU operation
for the submission mode. The runtime does not append another kernel
signal/wait operation after this DDI, and ignores `PhysicalAdapterMask` on
this path. Before returning, the UMD must have queued the operation or
arranged its submission without requiring another application call.
Return does not establish GPU completion. This submission requirement does
not make a wait independent of the producers that can satisfy its threshold.

For non-native fences, implicit multi-GPU handling can invoke the same DDIs
to obtain the physical-adapter broadcast scope. The runtime then submits the
corresponding operation using the selected kernel contexts or hardware
queues. Other ordinary non-native paths can submit through the runtime
without invoking these DDIs; there is no universal one-to-one API/DDI/kernel
call sequence.

On that non-native runtime-broadcast path, mask bits select underlying
physical adapters, not the application's `NodeMask`. The UMD must return a
mask selecting at least one eligible physical-adapter context or hardware
queue for the requested operation. A zero mask or an otherwise empty eligible
target set is not a supported way to suppress the runtime broadcast. This
output requirement does not apply to the ignored mask on the native path.

<a id="native-queue-errors"></a>

#### Failure reporting for native operations

The native UMD Signal/Wait path does not provide a recoverable operation-error
channel. If the UMD cannot arrange the requested operation, it must report
device failure through the callback `PFND3D12DDI_SETERROR_CB`.
An out-of-memory condition is not a recoverable UMD operation result on this
path. This is device-failure reporting, not a command-list recording error
deferred until Close.

```cpp
typedef VOID (APIENTRY CALLBACK *PFND3D12DDI_SETERROR_CB)( D3D10DDI_HRTDEVICE, HRESULT );
```

The first callback argument identifies the runtime device context; the
second is the reported failure `HRESULT`. The legacy device-handle spelling
in the released typedef does not change this callback's D3D12 runtime role.
For these native operation DDIs, the callback reports device failure rather
than supplying a recoverable operation result. Other DDIs' error contracts
remain specific to their own call sites.

A synchronous device-failure report does not guarantee that the original
application Signal/Wait call returns a failing `HRESULT`; it does not
guarantee `S_OK` either. Device removal is observed through
[GetDeviceRemovedReason](diagnostics.md#id3d12device-getdeviceremovedreason)
and the established [completion/removal notification rules](execution.md#completion-lifetime),
independently of that return. A successful return is not proof of a healthy
device or successful GPU execution.

The runtime's own validation and non-native transport work may still return
their normal `HRESULT` failures, including recoverable allocation failures.
The native UMD failure model must not be generalized into a device-fatal
interpretation of every application Signal/Wait error.

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

CPU signaling does not wait for preceding GPU work. A CPU-written value is therefore not evidence that unrelated queued work has completed. This method must not be used on [read-only status fences](#status-fences). For command-list-scoped fences, CPU signaling is only an initialization before the relevant GPU use, not an in-flight signaling operation.

#### Parameters

**Value**

The value to set the fence to.

#### Return values

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/win32/direct3d12/d3d12-graphics-reference-returnvalues).

<a id="id3d12fencegetcompletedvalue"></a>

### ID3D12Fence::GetCompletedValue

#### Declaration

```cpp
UINT64 GetCompletedValue();
```

<a id="fence-completed-value"></a>

#### Return values

Returns the current value of the fence. If the device has been removed, the return value will be `UINT64_MAX`.

The CPU-observation restrictions in [Fence options](#fence-flags) apply. An observed [status-fence counter](#status-fences) tracks protected-content validity changes, not GPU-work completion. For device-removal interpretation, see [Completion, device removal, and lifetime](#completion-lifetime). Command-list-scoped fences also return a constant sentinel, as defined [above](#command-list-scoped-fences).

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

`SetEventOnCompletion` specifies an event that's raised when the fence reaches a certain value.

If `hEvent` is a null handle, then this API will not return until the specified fence value has been reached.

This method can be safely called from multiple threads at one time.

#### Parameters

**Value**

The fence value when the event is to be signaled.

**hEvent**

A handle to the event object.

#### Return values

This method returns `E_OUTOFMEMORY` if the kernel components don’t have sufficient memory to store the event in a list. See [Direct3D 12 return codes](https://learn.microsoft.com/en-us/windows/win32/direct3d12/d3d12-graphics-reference-returnvalues) for other possible return values.

With a non-NULL event, successful registration is not itself a CPU wait for completion. With `hEvent == NULL`, the blocking behavior describes a successful wait; an error can return without establishing completion. Device removal can also satisfy a notification, as described [below](#completion-lifetime). For system-controlled status fences, the [status interpretation](#status-fences) also applies. [Command-list-scoped fences](#command-list-scoped-fences) do not support this notification.

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

`SetEventOnMultipleFenceCompletion` specifies an event that should be fired when one or more of a collection of fences reach specific values.

#### Parameters

**ppFences**

An array of length `NumFences` that specifies the [ID3D12Fence](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nn-d3d12-id3d12fence) objects.

**pFenceValues**

An array of length `NumFences` that specifies the fence values required for the event to be signaled.

**NumFences**

Specifies the number of fences to be included.

**Flags**

Specifies one of the [D3D12_MULTIPLE_FENCE_WAIT_FLAGS](#multiple-fence-flags) that determines how to proceed.

**hEvent**

A handle to the event object.

`pFenceValues[i]` is the threshold for `ppFences[i]`; both arrays contain `NumFences` entries. The arrays describe the registration and are consumed by the call, not retained as application memory for later GPU use.

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

| Flag | Value | Meaning |
|---|---|---|
| `D3D12_MULTIPLE_FENCE_WAIT_FLAG_NONE` | `0` | No flags are being passed. This means to use the default behavior, which is to wait for all fences before signaling the event. |
| `D3D12_MULTIPLE_FENCE_WAIT_FLAG_ANY` | `0x1` | Modifies behavior to indicate that the event should be signaled after any one of the fence values has been reached by its corresponding fence. |
| `D3D12_MULTIPLE_FENCE_WAIT_FLAG_ALL` | `0` | An alias for `D3D12_MULTIPLE_FENCE_WAIT_FLAG_NONE`, meaning to use the default behavior and wait for all fences. |

#### Blocking and return values

If `hEvent` is a null handle, then this API will not return until the selected ANY/ALL fence condition has been satisfied.

This method returns an HRESULT success or error code.

Unrecognized `Flags` bits return `E_INVALIDARG`. Storage allocation can fail with `E_OUTOFMEMORY`. Successful non-NULL registration and blocking NULL-event use have the same completion/error distinction as [single-fence notification](#id3d12fenceseteventoncompletion). Read-only status-fence inputs retain their [status interpretation](#status-fences). Command-list-scoped fences are not CPU-wait-capable inputs.

<a id="completion-lifetime"></a>

### Completion, device removal, and lifetime

The full [`ID3D12Device::GetDeviceRemovedReason` contract](diagnostics.md#id3d12device-getdeviceremovedreason) defines device-removal status. To be called back when a device is removed, consider using [ID3D12Fence::SetEventOnCompletion](#id3d12fenceseteventoncompletion) with a value of `UINT64_MAX`. That's because device removal causes CPU-wait-capable fences to be signaled to that value (which also implies completing all events waited on, because their thresholds are at most `UINT64_MAX`).

An event becoming signaled or a fence reading `UINT64_MAX` is not by itself proof of successful GPU execution. Check device status rather than interpreting removal-induced notification as normally completed rendering or valid output data.

A completion value is useful for storage reuse only when its signal follows the relevant work and competing CPU/queue signals cannot satisfy the same threshold prematurely. Apply the [allocator storage](#command-storage) and [resource lifetime](#lifetime) requirements; neither API return nor list Reset is a completion proof.

`hEvent` names an application-supplied Windows event, not an event created by these D3D12 methods. Event-handle ownership and CPU waits follow the [Windows event-object contract](https://learn.microsoft.com/en-us/windows/win32/sync/event-objects). These notifications do not retain unrelated resources referenced by recorded GPU work.

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

The creation callbacks take `Info` describing the synchronization-object
type and attributes and return its OS `hSyncObject`. The `2` form carries
the extended object information, including monitored-fence mappings where
applicable. The UMD manages its internal object's lifetime and releases
its OS handle through DestroySynchronizationObject.

This ownership is not permission to independently destroy an OS object
adopted by a runtime fence. That separate
[native-fence association and cleanup contract](execution.md#native-fence-callbacks)
continues to apply even when the UMD knows the OS handle.

<a id="context-sync-callbacks"></a>

#### Context-stream and CPU synchronization

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

| Family | Input and operation |
|---|---|
| `WaitForSynchronizationObjectCB` / `SignalSynchronizationObjectCB` | Supply `hContext`, an OS-object array and `ObjectCount`; wait or signal in that context stream. Signal also carries its operation flags. |
| `WaitForSynchronizationObject2CB` | Adds the object-type-specific `FenceValue` threshold to the context/object request. |
| `SignalSynchronizationObject2CB` | Adds broadcast contexts and a flags-selected fence-value or CPU-event payload. `Flags.EnqueueCpuEvent` selects `CpuEventHandle`, not `FenceValue`. |
| `WaitForSynchronizationObjectFromCpuCB` | Supply OS-object/value arrays, flags and optional `hAsyncEvent`. On a usable device, null selects a blocking CPU wait; a non-null event requests notification when the wait condition is satisfied. This is not a queued GPU wait. |
| `SignalSynchronizationObjectFromCpuCB` | Supply OS-object/value arrays for CPU-side signaling. It is not insertion of a signal after prior work in a GPU context. |
| `WaitForSynchronizationObjectFromGpuCB` | Supply `hContext`, OS objects and the object-type-selected scalar or monitored-fence threshold array for a context-stream wait. |
| `SignalSynchronizationObjectFromGpuCB` | Supply `hContext`, OS objects and monitored-fence values for GPU-stream signaling. |
| `SignalSynchronizationObjectFromGpu2CB` | Uses a counted broadcast-context array and an object-type/flags-selected scalar value, monitored-value array or CPU event. It is not interchangeable with the single-context form's payload. |

These are synchronization-object operations, not application COM-fence
methods. A queued wait may require a later producer. CPU and GPU forms have
different placement and notification contracts; one must not be substituted
for the other merely because their names contain Signal or Wait.

<a id="hardware-queue-sync"></a>

#### Hardware-queue synchronization

```cpp
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_SUBMITWAITFORSYNCOBJECTSTOHWQUEUECB)(
    _In_ HANDLE hDevice, _In_ CONST D3DDDICB_SUBMITWAITFORSYNCOBJECTSTOHWQUEUE*);
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_SUBMITSIGNALSYNCOBJECTSTOHWQUEUECB)(
    _In_ HANDLE hDevice, _In_ CONST D3DDDICB_SUBMITSIGNALSYNCOBJECTSTOHWQUEUE*);
```

The wait callback supplies one runtime hardware-queue handle and counted
OS-object/fence-value arrays. The signal callback supplies counted broadcast
hardware-queue handles, OS-object/value arrays and signal flags. The runtime
translates the hardware-queue handles and inserts the corresponding kernel
operations. These callbacks do not release the handles or establish that a
wait has been satisfied or a signal reached by the GPU before return.
The [native versus non-native queue-fence routing](execution.md#queue-signal-wait)
determines which party arranges an application's operation.

<a id="native-shared-callback"></a>

#### Native-fence callback selection

```cpp
typedef _Check_return_ HRESULT (APIENTRY CALLBACK *PFND3DDDI_CREATENATIVEFENCECB)(
    _In_ HANDLE hDevice, _Inout_ D3DKMT_CREATENATIVEFENCE*);
```

The D3D12 shared callback table does not supply
`PFND3DDDI_CREATENATIVEFENCECB`. Native-fence operations use the
[D3D12 native-create/open callbacks](execution.md#native-fence-callbacks)
for the documented associated or UMD-internal native-fence operations.
The generic typedef is not an alias for the D3D12 callback with an additional
runtime-fence association.

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

These three signatures belong to `D3D12DDI_DOWNLEVEL_SUPPORT_CALLBACKS_0054`,
not the ordinary core callback table or the shared `D3DDDI_DEVICECALLBACKS`
slots. When that downlevel table is supplied, use its runtime-device handle
and `D3D12DDICB_*` payloads rather than substituting the similarly named
shared callback types.

Creation supplies `Info` and returns the OS `hSyncObject`. Wait supplies
`hContext`, an object array/count and `FenceValue` for a context-stream wait.
Signal supplies context/object arrays, broadcast contexts and flags selecting
a fence value or CPU event. The callbacks return an `HRESULT` for the
requested operation, not GPU completion. Their separate table ownership
does not imply that every D3D12 device supplies downlevel support.

<a id="lifetime"></a>

## Object and resource lifetime

### Reference counting

Most D3D12 APIs continue to use reference counting as per COM
conventions. 1 notable exception to this is the D3D12 command list APIs.
All APIs on ID3D12GraphicsCommandList do not hold references to the objects
passed into those APIs. This means applications are responsible for
ensuring that a command list is never submitted for execution that
references a destroyed resource.

The [destruction-notifier interface](devices-and-capabilities.md#destruction-notifications)
observes CPU object destruction. Its callbacks and cancellation IDs do not
retain recorded resource uses, prove GPU completion, or replace these
application lifetime requirements.

### Resource lifetime separated from binding

Before freeing any resource, such as a texture, applications must
make sure the GPU has completed referencing it.

Whole-command-list completion is sufficient, but is not required when a correctly scoped fence-barrier signal proves every GPU use of the resource has completed and no later use remains. This does not permit resetting allocator storage while any recorded stream still uses it.

### CPU/GPU access to mapped memory

Applications have the responsibility to synchronize CPU and GPU memory accesses. To
help with this the system provides mechanisms for the application to
request sleeping of a CPU thread until work completes. Polling could
also be done, but can be wasteful.

Resources on CPU-accessible heaps can be persistently mapped, meaning **Map** can be called once, immediately after resource creation. [Unmap](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nf-d3d12-id3d12resource-unmap) never needs to be called, but the address returned from **Map** must no longer be used after the last reference to the resource is released. When using persistent map, the application must ensure the CPU finishes writing data into memory before the GPU executes a command list that reads or writes the memory. In common scenarios, the application merely must write to memory before calling [ExecuteCommandLists](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nf-d3d12-id3d12commandqueue-executecommandlists); but using a fence to delay command list execution works as well.
All CPU-accessible memory types support persistent mapping usage, where the resource is mapped but then never unmapped, provided the application does not access the pointer after the resource has been disposed.

### Command-list object destruction

Note that applications are allowed to call ID3D12GraphicsCommandList::Reset
before previous executions of the associated command list have
completed. Additionally, applications can destroy command lists before
previous executions have completed.

<a id="threading"></a>

## CPU threading

All methods on the device interface are free-threaded.

Methods on a specific command list object are not free-threaded with
respect to each other. Applications must ensure that they never
concurrently call methods on the same command list.

Methods on a command allocator are not free-threaded with respect to
each other. Applications must ensure that they never concurrently call
methods on the same command list allocator.

All methods on the command queue are free-threaded.

The D3D12 threading behavior is not configurable.

<a id="driver-responsibilities"></a>

## Driver responsibilities

Driver fence [private-sizing requirements](execution.md#fence-private-sizing)
and [native-fence callback ownership and failure cleanup](execution.md#native-fence-callbacks)
are defined in this chapter, alongside
the [queue Signal/Wait transport split](execution.md#queue-signal-wait).
The [native operation error contract](execution.md#native-queue-errors)
distinguishes device-failure reporting from the application method's `HRESULT`.

### Threading

Drivers are expected to implement the threading model described in this
document. The one exception is the atomicity of command queue operation.
The D3D12 runtime acquires a lock around all command queue APIs.
Additionally, the runtime acquires the command queue lock around the
DXGI Present and Blt DDIs. Drivers can thus assume that the following
DDI calls are serialized:

- ExecuteCommandLists
- [UpdateTileMappings](resources.md#update-tile-mappings)
- [CopyTileMappings](resources.md#copy-tile-mappings)

### Command-list resource lifetime

The runtime implementation of command lists does not hold references
objects (resources, pipeline state objects, queries, etc) used by a
command list. Applications must guarantee that they do not call
ID3D12CommandQueue::ExecuteCommandLists if any resource
referenced by the command list has been destroyed. This however does not
guarantee the order of destruction. Drivers must be robust to the case
where a command list is destroyed after the resources that it references
have been destroyed.
