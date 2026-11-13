<a id="video-motion-estimation"></a>

# Video: motion estimation reference

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

<!-- d3d12-review-alert:begin:video-motion:N-entry:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This subordinate [Video](video.md) reference describes motion estimation,
> opaque motion vector storage and its resolution, together with the base
> VIDEO_ENCODE command list lifecycle. A motion estimator maintains operation
> context. A motion vector heap stores hardware-dependent output. A resolve
> records conversion into an application texture.

<!-- d3d12-review-alert:end:video-motion:N-entry:0 -->

<!-- d3d12-review-alert:begin:video-motion:N-entry:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This is a **qualified draft**. Published motion search requirements remain
> source-only where algorithm, hardware-quality or implementation evidence is
> insufficient. Specific qualifications below do not establish expert or
> hardware approval.

<!-- d3d12-review-alert:end:video-motion:N-entry:1 -->

<a id="motion-model"></a>

## Motion search and execution

<ins><!-- d3d12-review-inline:begin:video-motion:R-purpose:0 -->This feature exposes a motion search operation to produce motion vectors for the purpose of extrapolating future frames.<!-- d3d12-review-inline:end:video-motion:R-purpose:0 --></ins>

<!-- d3d12-review-alert:begin:video-motion:N-search:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The operation performs a luma-only motion search between the current input
> frame and a reference (past) frame. Microsoft does not specify the details
> of the search algorithm. Search block sizes are 8×8 or 16×16 pixels, as
> reported for the node and input format. The selected vector precision is
> quarter-pixel. The block size is not a search window radius. There is no
> published fixed search radius, tie-breaking rule or guaranteed VR quality
> in this contract. A prior heap may supply hints, not mandatory search results.

<!-- d3d12-review-alert:end:video-motion:N-search:0 -->

<!-- d3d12-review-alert:begin:video-motion:N-search:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The compact route is [capabilities](#motion-capabilities),
> [objects](#motion-objects), [recording](#motion-recording), and the subordinate
> [type](#motion-types) and [driver](#motion-driver) references.

<!-- d3d12-review-alert:end:video-motion:N-search:1 -->

<!-- d3d12-review-alert:begin:video-motion:N-search:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Motion estimation uses a list and allocator of
> `D3D12_COMMAND_LIST_TYPE_VIDEO_ENCODE`, submitted to a VIDEO_ENCODE queue.
> [CPU threading](execution.md#threading),
> [submission threading](execution.md#submission-threading),
> [queue/list types](execution.md#command-list-types),
> [creation](execution.md#creation) and [submission validation](execution.md#validation)
> own device/node and list/allocator/queue compatibility.
> [Submission and ordering](execution.md#submission) own execution order.
> The motion estimator's explicit exclusion of concurrent use on distinct queues
> is defined under [driver object lifetime](#motion-driver-objects). It is not
> a decoder-wide rule or a restriction to VIDEO_DECODE.

<!-- d3d12-review-alert:end:video-motion:N-search:2 -->

<!-- d3d12-review-alert:begin:video-motion:N-search:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> [Recording storage](execution.md#command-storage),
> [object/resource lifetime](execution.md#lifetime),
> [completion and lifetime](execution.md#completion-lifetime), and
> [video resources](video.md#video-resource-contract) own storage, completion
> and residency. Both motion objects derive from `ID3D12Pageable`.
> The estimator, output and hint heaps, and input, reference and resolved output
> resources must remain alive for their recorded uses that will execute and
> until those GPU uses finish. CPU descriptions and argument structures are
> recording inputs, not GPU picture storage. Resetting the list does not complete
> earlier GPU work or reset its allocator. Caller-owned interface references do
> not imply that recording motion commands automatically takes additional
> references to those objects.

<!-- d3d12-review-alert:end:video-motion:N-search:3 -->

<!-- d3d12-review-alert:begin:video-motion:N-search:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Input and reference pictures are read in motion estimation. The legacy states
> are `D3D12_RESOURCE_STATE_VIDEO_ENCODE_READ` for those pictures and
> `D3D12_RESOURCE_STATE_VIDEO_ENCODE_WRITE` for the resolve destination texture.
> The opaque heap is not an `ID3D12Resource` to which an application applies
> resource barriers. [Enhanced encode barriers](synchronization.md#encode-enhanced-barrier)
> and [legacy encode barriers](synchronization.md#encode-resource-barrier)
> retain their full declarations; [access](synchronization.md#barrier-access),
> [synchronization scopes](synchronization.md#barrier-sync), and
> [barrier model interoperation](synchronization.md#model-interoperation) own
> the enhanced path. Neither motion call inserts an application resource
> transition or a cross-queue fence wait.

<!-- d3d12-review-alert:end:video-motion:N-search:4 -->

<!-- d3d12-review-alert:begin:video-motion:N-search:5 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> [Encode predication](counters-queries-and-predication.md#videoencode-setpredication)
> and the [operation matrix](counters-queries-and-predication.md#predication-operation-matrix)
> own conditional execution: both `EstimateMotion` and `ResolveMotionVectorHeap`
> are predicated. [Encode queries](counters-queries-and-predication.md#videoencode-beginquery),
> [timestamp ending](counters-queries-and-predication.md#videoencode-endquery), and
> [query resolution](counters-queries-and-predication.md#videoencode-resolvequerydata)
> own the query/list/heap combinations and lifecycle. The encode route supports
> timestamp queries, not a motion estimation statistics or completion query.

<!-- d3d12-review-alert:end:video-motion:N-search:5 -->

<a id="motion-capabilities"></a>

## Capability queries

<!-- d3d12-review-alert:begin:video-motion:N-query:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> [`ID3D12VideoDevice::CheckFeatureSupport`](video-decode.md#video-check-feature-support)
> owns the common declaring entry and return protocol. Each query below uses
> a fixed payload and `FeatureSupportDataSize` equal to `sizeof` that payload.
> Initialize input fields and read output fields only on success.

<!-- d3d12-review-alert:end:video-motion:N-query:0 -->

<!-- d3d12-review-alert:begin:video-motion:N-query:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | `D3D12_FEATURE_VIDEO` case | Value | Payload | Inputs | Outputs |
> |---|---|---|---|---|
> | `FEATURE_AREA_SUPPORT` | 19 | `D3D12_FEATURE_DATA_VIDEO_FEATURE_AREA_SUPPORT` | `NodeIndex` | `VideoDecodeSupport`, `VideoProcessSupport`, `VideoEncodeSupport` |
> | `MOTION_ESTIMATOR` | 20 | `D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR` | `NodeIndex`, `InputFormat` | `BlockSizeFlags`, `PrecisionFlags`, `SizeRange` |
> | `MOTION_ESTIMATOR_SIZE` | 21 | `D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_SIZE` | `NodeIndex`, `InputFormat`, `BlockSize`, `Precision`, `SizeRange`, `Protected` | Four estimator/heap pool size fields |
> | `MOTION_ESTIMATOR_PROTECTED_RESOURCES` | 30 | `D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_PROTECTED_RESOURCES` | `NodeIndex` | `SupportFlags` |

<!-- d3d12-review-alert:end:video-motion:N-query:1 -->

<!-- d3d12-review-alert:begin:video-motion:N-query:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The case names in this table have prefix `D3D12_FEATURE_VIDEO_`.
> `NodeIndex` is a zero-based index, not the creation `NodeMask`.
> The [shared feature area driver contract](#video-feature-area-support)
> defines the decode, process and encode command family obligations.
> Feature area encode support makes the queue/list family available. It is
> not itself support for every motion estimation format or block size.
> `MOTION_ESTIMATOR` establishes the supported tuple: at least one block size
> bit and precision bit must be set, and the size range must contain the inputs.
> For an unsupported format both flags are `NONE` and every size range field
> is zero. A successful query alone is not support.
> The selected baseline input/reference format is `DXGI_FORMAT_NV12`.

<!-- d3d12-review-alert:end:video-motion:N-query:2 -->

<!-- d3d12-review-alert:begin:video-motion:N-query:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The size query reports residency allocations for both the context and opaque
> output heap using the supplied creation parameters. It does not allocate
> either object. The heap and estimator size outputs have distinct names;
> their API field order is not the DDI field order.
> `Protected` is TRUE for protected input/output operation and FALSE otherwise.
> Narrow protected creation additionally requires motion estimator protected
> resource support on that node. A non-null creation session is not an ordinary
> unprotected object.

<!-- d3d12-review-alert:end:video-motion:N-query:3 -->

<!-- d3d12-review-alert:begin:video-motion:N-query:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Scoped runtime validation:** an out-of-range query node returns
> `E_INVALIDARG`. The inspected support path returns no-support outputs for
> an unavailable encode route or disallowed input format. Invalid driver
> capability flags, inconsistent support outputs or malformed size ranges can
> produce `DXGI_ERROR_DRIVER_INTERNAL_ERROR`. The size path rejects a driver
> report with both motion vector heap pool sizes zero. These source-inspected
> checks do not prove an adapter's capabilities or search quality.

<!-- d3d12-review-alert:end:video-motion:N-query:4 -->

<a id="motion-objects"></a>

## Object creation and reflection

<!-- d3d12-review-alert:begin:video-motion:N-object:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Both creation descriptions are input-only. Their `NodeMask` selects one
> physical node: zero for single-GPU operation, or one bit for the selected
> node in multi-node operation. Input format, block size, precision and size
> range must be supported for that node. The selected size range may be a
> subset of supported sizes to reduce allocation requirements. It must
> accommodate each actual input and reference.

<!-- d3d12-review-alert:end:video-motion:N-object:0 -->

<!-- d3d12-review-alert:begin:video-motion:N-object:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> On successful creation, `ppVideoMotionEstimator` or
> `ppVideoMotionVectorHeap` receives a caller-owned reference to the requested
> interface identified by `riid`. The caller releases that reference under the
> common [object lifetime rules](execution.md#lifetime). Each creation method
> copies its CPU description during the call. The caller need not retain the
> description's storage after the call returns.

<!-- d3d12-review-alert:end:video-motion:N-object:1 -->

<!-- d3d12-review-alert:begin:video-motion:N-object:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Each `GetDesc` returns a value copy of the immutable creation description.
> Changing that returned copy does not reconfigure the object. Different
> creation parameters require a new object.

<!-- d3d12-review-alert:end:video-motion:N-object:2 -->

<!-- d3d12-review-alert:begin:video-motion:N-object:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pProtectedResourceSession` may be null for unprotected operation.
> For protected input, the estimator and vector heap must be created with a
> protected resource session and the output must be protected. These are
> narrow object association requirements, not an independent session lifecycle.
> On success, each `GetProtectedResourceSession` returns an owned reference to
> the requested session interface through `ppProtectedSession`, identified by
> `riid`. The caller releases that reference under the same object lifetime
> rules; retrieving the interface does not create a new protection session.

<!-- d3d12-review-alert:end:video-motion:N-object:3 -->

<!-- d3d12-review-alert:begin:video-motion:N-object:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Scoped creation validation:** the inspected creation paths validate the
> node, size range, reported block size and precision bits and protected support.
> They propagate validation or creation failures as HRESULTs. A null result
> pointer has a validation-only path returning `S_FALSE` on successful validation;
> it creates no object. This observed path does not change the required output
> pointer annotation in the released declaration.

<!-- d3d12-review-alert:end:video-motion:N-object:4 -->

<!-- d3d12-review-alert:begin:video-motion:N-object:5 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Session getter qualification:** the published getters retrieve the creation
> session and return HRESULT. The precise no-session failure and null output
> postcondition are not established by the selected owning references; no
> specific success/failure code for that case is asserted here.

<!-- d3d12-review-alert:end:video-motion:N-object:5 -->

<a id="motion-create-estimator"></a>

### ID3D12VideoDevice1::CreateVideoMotionEstimator

#### Declaration

```cpp
HRESULT CreateVideoMotionEstimator(
  const D3D12_VIDEO_MOTION_ESTIMATOR_DESC *pDesc,
  ID3D12ProtectedResourceSession          *pProtectedResourceSession,
  REFIID                                  riid,
  void                                    **ppVideoMotionEstimator
);
```

#### Behavior

Creates an <ins><!-- d3d12-review-inline:begin:video-motion:A1-behavior:0 -->[ID3D12VideoMotionEstimator](#motion-objects)<!-- d3d12-review-inline:end:video-motion:A1-behavior:0 --></ins>, which maintains context for video motion estimation operations.

#### Parameters

`pDesc`

<ins><!-- d3d12-review-inline:begin:video-motion:A1-parameters:1 -->A [D3D12_VIDEO_MOTION_ESTIMATOR_DESC](#d3d12-video-motion-estimator-desc) describing the parameters used for motion estimation.<!-- d3d12-review-inline:end:video-motion:A1-parameters:1 --></ins>

`pProtectedResourceSession`

<ins><!-- d3d12-review-inline:begin:video-motion:A1-parameters:3 -->A [ID3D12ProtectedResourceSession](resources.md#protected-resource-sessions) for managing access to protected resources.<!-- d3d12-review-inline:end:video-motion:A1-parameters:3 --></ins>

`riid`

The globally unique identifier (GUID) for the **ID3D12VideoMotionEstimator** interface.

`ppVideoMotionEstimator`

A pointer to a memory block that receives a pointer to the **ID3D12VideoMotionEstimator** interface.

#### Return values

This method returns HRESULT.

<a id="motion-create-heap"></a>

### ID3D12VideoDevice1::CreateVideoMotionVectorHeap

#### Declaration

```cpp
HRESULT CreateVideoMotionVectorHeap(
  const D3D12_VIDEO_MOTION_VECTOR_HEAP_DESC *pDesc,
  ID3D12ProtectedResourceSession            *pProtectedResourceSession,
  REFIID                                    riid,
  void                                      **ppVideoMotionVectorHeap
);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:video-motion:A2-behavior:0 -->Allocates a heap<!-- d3d12-review-inline:end:video-motion:A2-behavior:0 --></ins> that contains motion vectors for video motion estimation.

#### Parameters

`pDesc`

<ins><!-- d3d12-review-inline:begin:video-motion:A2-parameters:1 -->A pointer to a [D3D12_VIDEO_MOTION_VECTOR_HEAP_DESC](#d3d12-video-motion-vector-heap-desc) describing the format of the heap.<!-- d3d12-review-inline:end:video-motion:A2-parameters:1 --></ins>

`pProtectedResourceSession`

<ins><!-- d3d12-review-inline:begin:video-motion:A2-parameters:3 -->A [ID3D12ProtectedResourceSession](resources.md#protected-resource-sessions) for managing access to protected resources.<!-- d3d12-review-inline:end:video-motion:A2-parameters:3 --></ins>

`riid`

The globally unique identifier (GUID) for the **ID3D12VideoMotionVectorHeap** interface.

`ppVideoMotionVectorHeap`

A pointer to a memory block that receives a pointer to the **ID3D12VideoMotionVectorHeap** interface.

#### Return values

This method returns HRESULT.

<a id="motion-estimator-get-desc"></a>

### ID3D12VideoMotionEstimator::GetDesc

#### Declaration

```cpp
D3D12_VIDEO_MOTION_ESTIMATOR_DESC GetDesc();
```

#### Behavior

Gets the <ins><!-- d3d12-review-inline:begin:video-motion:A3-behavior:0 -->[D3D12_VIDEO_MOTION_ESTIMATOR_DESC](#d3d12-video-motion-estimator-desc)<!-- d3d12-review-inline:end:video-motion:A3-behavior:0 --></ins> structure that was passed into <ins><!-- d3d12-review-inline:begin:video-motion:A3-behavior:0 -->[ID3D12VideoDevice1::CreateVideoMotionEstimator](#motion-create-estimator)<!-- d3d12-review-inline:end:video-motion:A3-behavior:0 --></ins> when the <ins><!-- d3d12-review-inline:begin:video-motion:A3-behavior:0 -->[ID3D12VideoMotionEstimator](#motion-objects)<!-- d3d12-review-inline:end:video-motion:A3-behavior:0 --></ins> was created.

#### Return values

This method returns a **D3D12\_VIDEO\_MOTION\_ESTIMATOR\_DESC** structure.

<a id="motion-estimator-get-session"></a>

### ID3D12VideoMotionEstimator::GetProtectedResourceSession

#### Declaration

```cpp
HRESULT GetProtectedResourceSession(
  REFIID riid,
  void   **ppProtectedSession
);
```

#### Behavior

Gets the <ins><!-- d3d12-review-inline:begin:video-motion:A4-behavior:0 -->[ID3D12ProtectedResourceSession](resources.md#protected-resource-sessions)<!-- d3d12-review-inline:end:video-motion:A4-behavior:0 --></ins> that was passed into <ins><!-- d3d12-review-inline:begin:video-motion:A4-behavior:0 -->[ID3D12VideoDevice1::CreateVideoMotionEstimator](#motion-create-estimator)<!-- d3d12-review-inline:end:video-motion:A4-behavior:0 --></ins> when the <ins><!-- d3d12-review-inline:begin:video-motion:A4-behavior:0 -->[ID3D12VideoMotionEstimator](#motion-objects)<!-- d3d12-review-inline:end:video-motion:A4-behavior:0 --></ins> was created.

#### Parameters

`riid`

The globally unique identifier (GUID) for the **ID3D12ProtectedResourceSession** interface.

`ppProtectedSession`

Receives a void pointer representing the **ID3D12ProtectedResourceSession** interface.

#### Return values

This method returns HRESULT.

<a id="motion-heap-get-desc"></a>

### ID3D12VideoMotionVectorHeap::GetDesc

#### Declaration

```cpp
D3D12_VIDEO_MOTION_VECTOR_HEAP_DESC GetDesc();
```

#### Behavior

Gets the <ins><!-- d3d12-review-inline:begin:video-motion:A5-behavior:0 -->[D3D12_VIDEO_MOTION_VECTOR_HEAP_DESC](#d3d12-video-motion-vector-heap-desc)<!-- d3d12-review-inline:end:video-motion:A5-behavior:0 --></ins> structure that was passed into <ins><!-- d3d12-review-inline:begin:video-motion:A5-behavior:0 -->[ID3D12VideoDevice1::CreateVideoMotionVectorHeap](#motion-create-heap)<!-- d3d12-review-inline:end:video-motion:A5-behavior:0 --></ins> when the <ins><!-- d3d12-review-inline:begin:video-motion:A5-behavior:0 -->[ID3D12VideoMotionVectorHeap](#motion-objects)<!-- d3d12-review-inline:end:video-motion:A5-behavior:0 --></ins> was created.

#### Return values

This method returns a **D3D12\_VIDEO\_MOTION\_VECTOR\_HEAP\_DESC** structure.

<a id="motion-heap-get-session"></a>

### ID3D12VideoMotionVectorHeap::GetProtectedResourceSession

#### Declaration

```cpp
HRESULT GetProtectedResourceSession(
  REFIID riid,
  void   **ppProtectedSession
);
```

#### Behavior

Gets the <ins><!-- d3d12-review-inline:begin:video-motion:A6-behavior:0 -->[ID3D12ProtectedResourceSession](resources.md#protected-resource-sessions)<!-- d3d12-review-inline:end:video-motion:A6-behavior:0 --></ins> that was passed into <ins><!-- d3d12-review-inline:begin:video-motion:A6-behavior:0 -->[ID3D12VideoDevice1::CreateVideoMotionVectorHeap](#motion-create-heap)<!-- d3d12-review-inline:end:video-motion:A6-behavior:0 --></ins> when the <ins><!-- d3d12-review-inline:begin:video-motion:A6-behavior:0 -->[ID3D12VideoMotionVectorHeap](#motion-objects)<!-- d3d12-review-inline:end:video-motion:A6-behavior:0 --></ins> was created.

#### Parameters

`riid`

The globally unique identifier (GUID) for the **ID3D12ProtectedResourceSession** interface.

`ppProtectedSession`

Receives a void pointer representing the **ID3D12ProtectedResourceSession** interface.

#### Return values

This method returns HRESULT.

<a id="motion-recording"></a>

## Encode list lifecycle and motion recording

<!-- d3d12-review-alert:begin:video-motion:N-recording:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The base encode list has no graphics pipeline state argument.
> `ClearState` resets video recording state without beginning a new recording;
> `Reset` starts recording with the supplied encode allocator after a successful
> close. `Close` ends recording, not GPU execution. Submission and allocator
> reuse follow [recording and storage](execution.md#command-storage) and
> [completion](execution.md#completion-lifetime).

<!-- d3d12-review-alert:end:video-motion:N-recording:0 -->

<!-- d3d12-review-alert:begin:video-motion:N-recording:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Scoped reset state evidence:** shared video list reset and clear state code
> disable predication (null predicate, zero offset, `EQUAL_ZERO`) and clear the
> protected session binding on a protection-capable node. They do not clear
> motion vector heap contents or recreate a motion estimator.
> There is no graphics PSO or decoder binding implied by this state reset.

<!-- d3d12-review-alert:end:video-motion:N-recording:1 -->

<a id="encode-clear-state"></a>

### ID3D12VideoEncodeCommandList::ClearState

#### Declaration

```cpp
void ClearState();
```

#### Behavior

Resets the state of <ins><!-- d3d12-review-inline:begin:video-motion:A7-behavior:0 -->a video encode command list<!-- d3d12-review-inline:end:video-motion:A7-behavior:0 --></ins> back to the state it was in when the command list was created.

#### Return values

None

<a id="encode-close"></a>

### ID3D12VideoEncodeCommandList::Close

#### Declaration

```cpp
HRESULT Close();
```

#### Behavior

Indicates that recording to the command list has finished.

#### Return values

Type: <ins><!-- d3d12-review-inline:begin:video-motion:A8-returns:0 -->**[HRESULT](devices-and-capabilities.md#api-result-codes)**<!-- d3d12-review-inline:end:video-motion:A8-returns:0 --></ins>

Returns **S\_OK** if successful; otherwise, returns one of the following values:

- **E\_FAIL** if the command list has already been closed, or an invalid API was called during command list recording.
- **E\_OUTOFMEMORY** if the operating system ran out of memory during recording.
- **E\_INVALIDARG** if an invalid argument was passed to the command list API during recording.

See <ins><!-- d3d12-review-inline:begin:video-motion:A8-returns:3 -->[Direct3D 12 Return Codes](devices-and-capabilities.md#api-result-codes)<!-- d3d12-review-inline:end:video-motion:A8-returns:3 --></ins> for other possible return values.

#### Runtime validation

The runtime will validate that the command list has not previously been closed. If an error was encountered during recording, the error code is returned here. The runtime won't call the close device driver interface (DDI) in this case.

<a id="encode-reset"></a>

### ID3D12VideoEncodeCommandList::Reset

#### Declaration

```cpp
HRESULT Reset(
  ID3D12CommandAllocator *pAllocator
);
```

#### Behavior

Resets a command list back to its initial state as if a new command list was just created.

#### Parameters

`pAllocator`

Type: **ID3D12CommandAllocator\***

A pointer to the <ins><!-- d3d12-review-inline:begin:video-motion:A9-parameters:2 -->[ID3D12CommandAllocator](execution.md#command-storage)<!-- d3d12-review-inline:end:video-motion:A9-parameters:2 --></ins> object that the device creates command lists from.

#### Return values

Type: <ins><!-- d3d12-review-inline:begin:video-motion:A9-returns:0 -->**[HRESULT](devices-and-capabilities.md#api-result-codes)**<!-- d3d12-review-inline:end:video-motion:A9-returns:0 --></ins>

Returns **S\_OK** if successful; otherwise, returns one of the following values:

- <ins><!-- d3d12-review-inline:begin:video-motion:A9-returns:2 -->**E\_FAIL** if the command list was not in the "closed" state when the **Reset** call was made, or the per-device limit would have been exceeded.<!-- d3d12-review-inline:end:video-motion:A9-returns:2 --></ins>
- **E\_OUTOFMEMORY** if the operating system ran out of memory.
- **E\_INVALIDARG** if the allocator is currently being used with another command list in the "recording" state or if the specified allocator was created with the wrong type.

 See [Direct3D 12 Return Codes](devices-and-capabilities.md#api-result-codes) for other possible return values.

#### Recording storage

<!-- d3d12-review-alert:begin:video-motion:A9-storage:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The allocator must have type `D3D12_COMMAND_LIST_TYPE_VIDEO_ENCODE`.
> The list can be reset while an earlier execution is in flight, but the
> allocator's memory cannot be reclaimed until its GPU uses finish. A recording
> error returned by `Close` is not repaired by `Reset`. The shared
> [recording lifecycle](execution.md#recording-lifecycle) owns failed-recording handling.

<!-- d3d12-review-alert:end:video-motion:A9-storage:0 -->

<a id="motion-estimate"></a>

### ID3D12VideoEncodeCommandList::EstimateMotion

#### Declaration

```cpp
void EstimateMotion(
  ID3D12VideoMotionEstimator                *pMotionEstimator,
  const D3D12_VIDEO_MOTION_ESTIMATOR_OUTPUT *pOutputArguments,
  const D3D12_VIDEO_MOTION_ESTIMATOR_INPUT  *pInputArguments
);
```

#### Behavior

Performs the motion estimation operation.

#### Parameters

`pMotionEstimator`

An <ins><!-- d3d12-review-inline:begin:video-motion:A10-parameters:1 -->[ID3D12VideoMotionEstimator](#motion-objects)<!-- d3d12-review-inline:end:video-motion:A10-parameters:1 --></ins> representing the video motion estimator context object.

`pOutputArguments`

A <ins><!-- d3d12-review-inline:begin:video-motion:A10-parameters:3 -->[D3D12_VIDEO_MOTION_ESTIMATOR_OUTPUT](#d3d12-video-motion-estimator-output)<!-- d3d12-review-inline:end:video-motion:A10-parameters:3 --></ins> structure representing the video motion estimation output arguments.

`pInputArguments`

A <ins><!-- d3d12-review-inline:begin:video-motion:A10-parameters:5 -->[D3D12_VIDEO_MOTION_ESTIMATOR_INPUT](#d3d12-video-motion-estimator-input)<!-- d3d12-review-inline:end:video-motion:A10-parameters:5 --></ins> structure representing the video motion estimation input arguments.

#### Return values

None

#### Operation and runtime validation

<!-- d3d12-review-alert:begin:video-motion:A10-constraints:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pMotionEstimator` supplies the context; `pOutputArguments->pMotionVectorHeap`
> receives opaque output. `pInputArguments` selects the whole current frame,
> the reference frame and an optional previous heap for hints. Input and
> reference subresource indices select the base plane of the chosen array slice.
> The estimator and output heap must agree in input format, block size and
> precision. Input/reference dimensions must agree and fit the objects'
> creation ranges.

<!-- d3d12-review-alert:end:video-motion:A10-constraints:0 -->

<!-- d3d12-review-alert:begin:video-motion:A10-constraints:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Scoped recording validation:** the inspected path requires non-reserved 2D
> input/reference textures, one mip level, valid subresources selecting plane
> zero, supported video heap properties, matching input format and matching
> input/reference dimensions. It checks actual input size against the output
> heap's range. This does not independently establish a complete estimator range,
> reference format, hint-compatibility or aliasing validation contract.
> Estimator/output heap node mismatches emit validation diagnostics, but the
> selected function does not set a failure HRESULT in those branches.
> The caller still must satisfy the node associations and creation contracts.
> Protected session compatibility is checked for the estimator, output heap,
> both pictures and a non-null hint heap.

<!-- d3d12-review-alert:end:video-motion:A10-constraints:1 -->

<!-- d3d12-review-alert:begin:video-motion:A10-constraints:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Invalid motion arguments can invalidate recording. These void methods do not
> return an immediate HRESULT. The inspected path records an error for later
> `Close`. Diagnostic presence or absence is not a hardware validity guarantee.

<!-- d3d12-review-alert:end:video-motion:A10-constraints:2 -->

<a id="motion-resolve"></a>

### ID3D12VideoEncodeCommandList::ResolveMotionVectorHeap

#### Declaration

```cpp
void ResolveMotionVectorHeap(
  const D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT *pOutputArguments,
  const D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_INPUT  *pInputArguments
);
```

#### Behavior

Translates the motion vector output of the <ins><!-- d3d12-review-inline:begin:video-motion:A11-behavior:0 -->[EstimateMotion](#motion-estimate)<!-- d3d12-review-inline:end:video-motion:A11-behavior:0 --></ins> method from hardware-dependent formats into a consistent format defined by the video motion estimation APIs.

#### Parameters

`pOutputArguments`

A <ins><!-- d3d12-review-inline:begin:video-motion:A11-parameters:1 -->[D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT](#d3d12-resolve-video-motion-vector-heap-output)<!-- d3d12-review-inline:end:video-motion:A11-parameters:1 --></ins> structure containing the translated motion vectors.

`pInputArguments`

A <ins><!-- d3d12-review-inline:begin:video-motion:A11-parameters:3 -->[D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_INPUT](#d3d12-resolve-video-motion-vector-heap-input)<!-- d3d12-review-inline:end:video-motion:A11-parameters:3 --></ins> structure containing the motion vectors to translate.

#### Return values

None

#### Operation and runtime validation

<!-- d3d12-review-alert:begin:video-motion:A11-constraints:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This records conversion, not a CPU readback. The input heap must contain
> the motion search result for `PixelWidth` and `PixelHeight`. Those are the
> dimensions of the last estimated pictures, not the heap's maximum dimensions.
> The output is the application-provided 2D vector texture at
> `MotionVectorCoordinate`. Its remaining region must hold one vector per
> selected search block.

<!-- d3d12-review-alert:end:video-motion:A11-constraints:0 -->

<!-- d3d12-review-alert:begin:video-motion:A11-constraints:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Scoped recording validation:** the selected path checks the heap size range,
> a non-reserved 2D destination, one mip and a valid destination subresource;
> it checks protected session compatibility of the heap and texture.
> It diagnoses nonzero Z, an out-of-bounds destination region and an
> incompatible heap node, but the selected branches do not themselves set a
> failure HRESULT. The region check uses integer `PixelWidth / blockSize` and
> `PixelHeight / blockSize`. It is not evidence that partial edge blocks may
> be truncated. Non-block-aligned picture rounding and the treatment of such
> edges remain unestablished; no floor/ceil rule is asserted.

<!-- d3d12-review-alert:end:video-motion:A11-constraints:1 -->

<!-- d3d12-review-alert:begin:video-motion:A11-constraints:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Format qualification:** the published resolve contract specifies
> `DXGI_FORMAT_R16G16_SINT`. The inspected validator also accepts
> `DXGI_FORMAT_R16G16_SNORM`, but that does not establish normalized vector
> scaling or universal driver support. No SNORM output contract is asserted.

<!-- d3d12-review-alert:end:video-motion:A11-constraints:2 -->

<a id="motion-types"></a>

## API types and layout

<!-- d3d12-review-alert:begin:video-motion:N-type-context:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The declarations below are API layouts, not driver layouts.
> [`D3D12_VIDEO_SIZE_RANGE`](video-decode.md#d3d12-video-size-range) retains its
> shared definition: maximum width/height and minimum width/height constrain
> both input and reference pictures. Query direction annotations identify
> inputs and outputs; creation descriptions contain only inputs.

<!-- d3d12-review-alert:end:video-motion:N-type-context:0 -->

<a id="d3d12-video-motion-estimator-search-block-size"></a>

### D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE

```cpp
typedef enum D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE
{
    D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_8X8       = 0,
    D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_16X16     = 1,
} D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE;
```

<!-- d3d12-review-alert:begin:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE:0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Constant | Meaning |
> |---|---|
> | `D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_8X8` | Value: *0*. The search block size is 8x8 pixels. |
> | `D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_16X16` | Value: *1*. The search block size is 16x16 pixels. |

<!-- d3d12-review-alert:end:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE:0 -->

<a id="d3d12-video-motion-estimator-search-block-size-flags"></a>

### D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_FLAGS

```cpp
typedef enum D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_FLAGS
{
    D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_FLAG_NONE  = 0,
    D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_FLAG_8X8        = (1 << D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_8X8),
    D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_FLAG_16X16      = (1 << D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_16X16),

} D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_FLAGS;
```

<!-- d3d12-review-alert:begin:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_FLAGS:0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Constant | Meaning |
> |---|---|
> | `D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_FLAG_NONE` | Value: *0*. Search block size is not supported by the encoder. |
> | `D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_FLAG_8X8` | The encoder supports a search block size of 8x8 pixels. |
> | `D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_FLAG_16X16` | The encoder supports a search block size of 16x16 pixels. |

<!-- d3d12-review-alert:end:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_FLAGS:0 -->

<a id="d3d12-video-motion-estimator-vector-precision"></a>

### D3D12_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION

```cpp
typedef enum D3D12_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION
{
    D3D12_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_QUARTER_PEL       = 0,
} D3D12_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION;
```

<!-- d3d12-review-alert:begin:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION:0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Constant | Meaning |
> |---|---|
> | `D3D12_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_QUARTER_PEL` | Value: *0*. The vector precision is quarter-pixel motion. |

<!-- d3d12-review-alert:end:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION:0 -->

<a id="d3d12-video-motion-estimator-vector-precision-flags"></a>

### D3D12_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_FLAGS

```cpp
typedef enum D3D12_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_FLAGS
{
    D3D12_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_FLAG_NONE           = 0,
    D3D12_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_FLAG_QUARTER_PEL    = (1 << D3D12_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_QUARTER_PEL),

} D3D12_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_FLAGS;
```

<!-- d3d12-review-alert:begin:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_FLAGS:0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Constant | Meaning |
> |---|---|
> | `D3D12_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_FLAG_NONE` | Value: *0*. Vector precision is not supported by the encoder. |
> | `D3D12_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_FLAG_QUARTER_PEL` | The vector precision is quarter-pixel motion. |

<!-- d3d12-review-alert:end:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_FLAGS:0 -->

<a id="d3d12-feature-data-video-feature-area-support"></a>

### D3D12_FEATURE_DATA_VIDEO_FEATURE_AREA_SUPPORT

```cpp
typedef struct D3D12_FEATURE_DATA_VIDEO_FEATURE_AREA_SUPPORT
{
    UINT NodeIndex;                                                     // input
    BOOL VideoDecodeSupport;                                            // output
    BOOL VideoProcessSupport;                                           // output
    BOOL VideoEncodeSupport;                                            // output
} D3D12_FEATURE_DATA_VIDEO_FEATURE_AREA_SUPPORT;
```

<!-- d3d12-review-alert:begin:video-motion:N-area-members:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `NodeIndex` selects the physical adapter. The three BOOL outputs identify
> availability of the decode, process and encode command families separately;
> this payload does not replace operation-specific motion support.

<!-- d3d12-review-alert:end:video-motion:N-area-members:0 -->

<a id="d3d12-feature-data-video-motion-estimator"></a>

### D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR

```cpp
typedef struct D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR
{
    UINT NodeIndex;                                                                 // input
    DXGI_FORMAT InputFormat;                                                        // input
    D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_FLAGS BlockSizeFlags;            // output
    D3D12_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_FLAGS PrecisionFlags;             // output
    D3D12_VIDEO_SIZE_RANGE SizeRange;                                               // output
} D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR;
```

`NodeIndex`

In multi-adapter operation, identifies the physical adapter of the device this operation applies to.

`InputFormat`

A <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR:3 -->[DXGI_FORMAT](formats.md#dxgi-format)<!-- d3d12-review-inline:end:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR:3 --></ins> structure specifying the format of the input resources.

`BlockSizeFlags`

A bitwise OR combination of values from the <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR:5 -->[D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_FLAGS](#d3d12-video-motion-estimator-search-block-size-flags)<!-- d3d12-review-inline:end:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR:5 --></ins> enumeration specifying the encoder's supported search block sizes for motion estimation.

`PrecisionFlags`

A bitwise OR combination of values from the <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR:7 -->[D3D12_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_FLAGS](#d3d12-video-motion-estimator-vector-precision-flags)<!-- d3d12-review-inline:end:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR:7 --></ins> enumeration specifying the encoder's supported vector precision for motion estimation.

`SizeRange`

A <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR:9 -->[D3D12_VIDEO_SIZE_RANGE](video-decode.md#d3d12-video-size-range)<!-- d3d12-review-inline:end:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR:9 --></ins> structure representing the minimum and maximum input size supported by the driver. The driver sets the fields of this structure to zero if motion estimation is unsupported.

<a id="d3d12-feature-data-video-motion-estimator-size"></a>

### D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_SIZE

```cpp
typedef struct D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_SIZE
{
    UINT NodeIndex;                                                     // input
    DXGI_FORMAT InputFormat;                                            // input
    D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE BlockSize;           // input
    D3D12_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION Precision;            // input
    D3D12_VIDEO_SIZE_RANGE SizeRange;                                   // input
    BOOL Protected;                                                     // input
    UINT64 MotionVectorHeapMemoryPoolL0Size;                            // output
    UINT64 MotionVectorHeapMemoryPoolL1Size;                            // output
    UINT64 MotionEstimatorMemoryPoolL0Size;                             // output
    UINT64 MotionEstimatorMemoryPoolL1Size;                             // output
} D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_SIZE;
```

`NodeIndex`

In multi-adapter operation, identifies the physical adapter of the device this operation applies to.

`InputFormat`

A <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_SIZE:3 -->[DXGI_FORMAT](formats.md#dxgi-format)<!-- d3d12-review-inline:end:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_SIZE:3 --></ins> structure specifying the format of the input and reference resources.

`BlockSize`

A value from the <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_SIZE:5 -->[D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE](#d3d12-video-motion-estimator-search-block-size)<!-- d3d12-review-inline:end:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_SIZE:5 --></ins> specifying the search block size for motion estimation.

`Precision`

<ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_SIZE:7 -->A value from the [D3D12_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION](#d3d12-video-motion-estimator-vector-precision) specifying the vector precision for motion estimation.<!-- d3d12-review-inline:end:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_SIZE:7 --></ins>

`SizeRange`

A <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_SIZE:9 -->[D3D12_VIDEO_SIZE_RANGE](video-decode.md#d3d12-video-size-range)<!-- d3d12-review-inline:end:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_SIZE:9 --></ins> structure representing the minimum and maximum input and reference frame size, in pixels, used by the motion estimator.

`Protected`

TRUE if the motion estimator operates on protected resource input and produces protected output; otherwise, FALSE.

`MotionVectorHeapMemoryPoolL0Size`

The allocation size of the motion vector heap in the L0 memory pool. L0 is the physical system memory pool. When the adapter is discrete/NUMA, this pool has greater bandwidth for the CPU and less bandwidth for the GPU. When the adapter is UMA, this pool is the only one which is valid. For more information, see <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_SIZE:13 -->[Residency](resources.md#residency)<!-- d3d12-review-inline:end:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_SIZE:13 --></ins>.

`MotionVectorHeapMemoryPoolL1Size`

The allocation size of the motion vector heap in the L1 memory pool. L1 is typically known as the physical video memory pool. L1 is only available when the adapter is discrete/NUMA, and has greater bandwidth for the GPU and cannot even be accessed by the CPU. When the adapter is UMA, this pool is not available. For more information, see <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_SIZE:15 -->[Residency](resources.md#residency)<!-- d3d12-review-inline:end:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_SIZE:15 --></ins>.

`MotionEstimatorMemoryPoolL0Size`

<ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_SIZE:17 -->The allocation size of the motion estimator<!-- d3d12-review-inline:end:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_SIZE:17 --></ins> in the L0 memory pool. L0 is the physical system memory pool. When the adapter is discrete/NUMA, this pool has greater bandwidth for the CPU and less bandwidth for the GPU. When the adapter is UMA, this pool is the only one which is valid. For more information, see <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_SIZE:17 -->[Residency](resources.md#residency)<!-- d3d12-review-inline:end:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_SIZE:17 --></ins>.

`MotionEstimatorMemoryPoolL1Size`

<ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_SIZE:19 -->The allocation size of the motion estimator<!-- d3d12-review-inline:end:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_SIZE:19 --></ins> in the L1 memory pool. L1 is typically known as the physical video memory pool. L1 is only available when the adapter is discrete/NUMA, and has greater bandwidth for the GPU and cannot even be accessed by the CPU. When the adapter is UMA, this pool is not available. For more information, see <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_SIZE:19 -->[Residency](resources.md#residency)<!-- d3d12-review-inline:end:video-motion:M-D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_SIZE:19 --></ins>.

<a id="d3d12-video-protected-resource-support-flags"></a>

### D3D12_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAGS

```cpp
typedef enum D3D12_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAGS
{
    D3D12_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAG_NONE                  = 0x0,
    D3D12_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAG_SUPPORTED             = 0x1,

} D3D12_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAGS;
```

<!-- d3d12-review-alert:begin:video-motion:N-protected-flags:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `NONE` is zero; `SUPPORTED` (`0x1`) reports protected resource operation support. These flags describe capability, not a session or encryption policy.

<!-- d3d12-review-alert:end:video-motion:N-protected-flags:0 -->

<a id="d3d12-feature-data-video-motion-estimator-protected-resources"></a>

### D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_PROTECTED_RESOURCES

```cpp
typedef struct D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_PROTECTED_RESOURCES
{
    UINT NodeIndex;                                                                 // input
    D3D12_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAGS SupportFlags;                      // output
} D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_PROTECTED_RESOURCES;
```

<!-- d3d12-review-alert:begin:video-motion:N-protected-query:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `NodeIndex` selects the physical adapter. `SupportFlags` reports motion estimator protected resource support; non-null protected session creation requires `SUPPORTED`.

<!-- d3d12-review-alert:end:video-motion:N-protected-query:0 -->

<a id="d3d12-video-motion-estimator-desc"></a>

### D3D12_VIDEO_MOTION_ESTIMATOR_DESC

```cpp
typedef struct D3D12_VIDEO_MOTION_ESTIMATOR_DESC
{
    UINT NodeMask;
    DXGI_FORMAT InputFormat;
    D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE BlockSize;
    D3D12_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION Precision;
    D3D12_VIDEO_SIZE_RANGE SizeRange;

} D3D12_VIDEO_MOTION_ESTIMATOR_DESC;
```

`NodeMask`

<ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_DESC:1 -->The node mask specifying the physical adapter on which the motion object will be used. For single GPU operation, set this to zero. If there are multiple GPU nodes, set a bit to identify the node, i.e. the device's physical adapter, on which the motion object will be used. Each bit in the mask corresponds to a single node. Only 1 bit may be set.<!-- d3d12-review-inline:end:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_DESC:1 --></ins>

`InputFormat`

A value from the <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_DESC:3 -->[DXGI_FORMAT](formats.md#dxgi-format)<!-- d3d12-review-inline:end:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_DESC:3 --></ins> enumeration specifying the format of the input and reference frames.

`BlockSize`

A value from the <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_DESC:5 -->[D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE](#d3d12-video-motion-estimator-search-block-size)<!-- d3d12-review-inline:end:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_DESC:5 --></ins> enumeration specifying the search block size the video motion estimator will use.

`Precision`

A value from the <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_DESC:7 -->[D3D12_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION](#d3d12-video-motion-estimator-vector-precision)<!-- d3d12-review-inline:end:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_DESC:7 --></ins> enumeration specifying the vector precision the video motion estimator will use.

`SizeRange`

A <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_DESC:9 -->[D3D12_VIDEO_SIZE_RANGE](video-decode.md#d3d12-video-size-range)<!-- d3d12-review-inline:end:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_DESC:9 --></ins> structure representing the minimum and maximum input and reference frame size, in pixels, that the motion estimator will accept.

<a id="d3d12-video-motion-vector-heap-desc"></a>

### D3D12_VIDEO_MOTION_VECTOR_HEAP_DESC

```cpp
typedef struct D3D12_VIDEO_MOTION_VECTOR_HEAP_DESC
{
    UINT NodeMask;
    DXGI_FORMAT InputFormat;
    D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE BlockSize;
    D3D12_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION Precision;
    D3D12_VIDEO_SIZE_RANGE SizeRange;

} D3D12_VIDEO_MOTION_VECTOR_HEAP_DESC;
```

`NodeMask`

<ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_VIDEO_MOTION_VECTOR_HEAP_DESC:1 -->The node mask specifying the physical adapter on which the motion object will be used. For single GPU operation, set this to zero. If there are multiple GPU nodes, set a bit to identify the node, i.e. the device's physical adapter, on which the motion object will be used. Each bit in the mask corresponds to a single node. Only 1 bit may be set.<!-- d3d12-review-inline:end:video-motion:M-D3D12_VIDEO_MOTION_VECTOR_HEAP_DESC:1 --></ins>

`InputFormat`

A value from the <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_VIDEO_MOTION_VECTOR_HEAP_DESC:3 -->[DXGI_FORMAT](formats.md#dxgi-format)<!-- d3d12-review-inline:end:video-motion:M-D3D12_VIDEO_MOTION_VECTOR_HEAP_DESC:3 --></ins> enumeration specifying the format of the input and reference frames.

`BlockSize`

A value from the <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_VIDEO_MOTION_VECTOR_HEAP_DESC:5 -->[D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE](#d3d12-video-motion-estimator-search-block-size)<!-- d3d12-review-inline:end:video-motion:M-D3D12_VIDEO_MOTION_VECTOR_HEAP_DESC:5 --></ins> enumeration specifying the search block size the video motion estimator will use.

`Precision`

A value from the <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_VIDEO_MOTION_VECTOR_HEAP_DESC:7 -->[D3D12_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION](#d3d12-video-motion-estimator-vector-precision)<!-- d3d12-review-inline:end:video-motion:M-D3D12_VIDEO_MOTION_VECTOR_HEAP_DESC:7 --></ins> enumeration specifying the vector precision the video motion estimator will use.

`SizeRange`

A <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_VIDEO_MOTION_VECTOR_HEAP_DESC:9 -->[D3D12_VIDEO_SIZE_RANGE](video-decode.md#d3d12-video-size-range)<!-- d3d12-review-inline:end:video-motion:M-D3D12_VIDEO_MOTION_VECTOR_HEAP_DESC:9 --></ins> structure representing the minimum and maximum input and reference frame size, in pixels, that the motion estimator will accept.

<a id="d3d12-resource-coordinate"></a>

### D3D12_RESOURCE_COORDINATE

```cpp
typedef struct D3D12_RESOURCE_COORDINATE
{
    // Coordinate values below index pixels.
    UINT64 X; // Used for buffer, 1D, 2D, 3D
    UINT Y; // Used for 2D, 3D
    UINT Z; // Used for 3D
    UINT SubresourceIndex; // indexes into mips, arrays, and planes. Used for 1D, 2D, 3D
} D3D12_RESOURCE_COORDINATE;
```

`X`

The x-coordinate of the resource.

`Y`

The y-coordinate of the resource.

`Z`

The z-coordinate of the resource.

`SubresourceIndex`

The index of the subresource for the resource.

<a id="d3d12-video-motion-estimator-output"></a>

### D3D12_VIDEO_MOTION_ESTIMATOR_OUTPUT

```cpp
typedef struct D3D12_VIDEO_MOTION_ESTIMATOR_OUTPUT
{
    ID3D12VideoMotionVectorHeap* pMotionVectorHeap;
} D3D12_VIDEO_MOTION_ESTIMATOR_OUTPUT;
```

`pMotionVectorHeap`

An <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_OUTPUT:1 -->[ID3D12VideoMotionVectorHeap](#motion-objects)<!-- d3d12-review-inline:end:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_OUTPUT:1 --></ins> <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_OUTPUT:1 -->containing the hardware-dependent motion estimation output.<!-- d3d12-review-inline:end:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_OUTPUT:1 --></ins>

<!-- d3d12-review-alert:begin:video-motion:N-heap-resolve-link:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The resolved texture representation is defined by [resolve output](#d3d12-resolve-video-motion-vector-heap-output). It is not the opaque heap's layout.

<!-- d3d12-review-alert:end:video-motion:N-heap-resolve-link:0 -->

<a id="d3d12-video-motion-estimator-input"></a>

### D3D12_VIDEO_MOTION_ESTIMATOR_INPUT

```cpp
typedef struct D3D12_VIDEO_MOTION_ESTIMATOR_INPUT
{
    ID3D12Resource*                     pInputTexture2D;
    UINT                                InputSubresourceIndex;
    ID3D12Resource*                     pReferenceTexture2D;
    UINT                                ReferenceSubresourceIndex;
    ID3D12VideoMotionVectorHeap*        pHintMotionVectorHeap;
} D3D12_VIDEO_MOTION_ESTIMATOR_INPUT;
```

`pInputTexture2D`

An <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_INPUT:1 -->[ID3D12Resource](resources.md#resource-storage)<!-- d3d12-review-inline:end:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_INPUT:1 --></ins> representing the current frame. The motion estimation operation applies to the entire frame.

`InputSubresourceIndex`

The base plane of the MIP and array slice to use for the input.

`pReferenceTexture2D`

An <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_INPUT:5 -->[ID3D12Resource](resources.md#resource-storage)<!-- d3d12-review-inline:end:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_INPUT:5 --></ins> representing the reference frame, or past frame, used for motion estimation.

`ReferenceSubresourceIndex`

The base plane of the MIP and array slice to use for the reference.

`pHintMotionVectorHeap`

An <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_INPUT:9 -->[ID3D12VideoMotionVectorHeap](#motion-objects)<!-- d3d12-review-inline:end:video-motion:M-D3D12_VIDEO_MOTION_ESTIMATOR_INPUT:9 --></ins> representing the buffer containing the hardware-dependent output of the previous motion estimator operation which may be used for hinting the current operation. This parameter may be NULL, indicating that previous motion estimator output should not be considered for the current operation.

<a id="d3d12-resolve-video-motion-vector-heap-output"></a>

### D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT

```cpp
typedef struct D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT
{
    ID3D12Resource*             pMotionVectorTexture2D;
    D3D12_RESOURCE_COORDINATE   MotionVectorCoordinate;
} D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT;
```

`pMotionVectorTexture2D`

An <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT:1 -->[ID3D12Resource](resources.md#resource-storage)<!-- d3d12-review-inline:end:video-motion:M-D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT:1 --></ins> representing the output resource for resolved motion vectors. Motion vectors are resolved to <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT:1 -->[DXGI_FORMAT_R16G16_SINT](formats.md#dxgi-format)<!-- d3d12-review-inline:end:video-motion:M-D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT:1 --></ins> 2D textures. The resolved data is a <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT:1 -->pair of signed 16-bit integers<!-- d3d12-review-inline:end:video-motion:M-D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT:1 --></ins> with quarter PEL units with the X vector component stored in the R component and the Y vector component stored in the G component. Motion vectors are stored in a 2D layout that corresponds to the pixel layout of the original input textures.

`MotionVectorCoordinate`

A <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT:3 -->[D3D12_RESOURCE_COORDINATE](#d3d12-resource-coordinate)<!-- d3d12-review-inline:end:video-motion:M-D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT:3 --></ins> structure specifying the output origin of the motion vectors. The remaining sub-region must be large enough to store all motion vectors per block specified by the <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT:3 -->input pixel width and pixel height<!-- d3d12-review-inline:end:video-motion:M-D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT:3 --></ins> and the specified <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT:3 -->[D3D12_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE](#d3d12-video-motion-estimator-search-block-size)<!-- d3d12-review-inline:end:video-motion:M-D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT:3 --></ins>.

<!-- d3d12-review-alert:begin:video-motion:N-vector-limits:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The signed 16-bit representation can encode integer
> components −32768 through 32767, corresponding arithmetically to −8192
> through 8191.75 pixels at that scale. This is a representation range, not a
> guaranteed search displacement, clipping rule or algorithmic search window.
> The block grid corresponds spatially to the original input pictures.
> The sign convention for displacement direction and partial-block edge handling
> are not established by the selected source. They are not inferred from
> component width.

<!-- d3d12-review-alert:end:video-motion:N-vector-limits:0 -->

<a id="d3d12-resolve-video-motion-vector-heap-input"></a>

### D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_INPUT

```cpp
typedef struct D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_INPUT
{
    ID3D12VideoMotionVectorHeap*                    pMotionVectorHeap;
    UINT                                            PixelWidth;
    UINT                                            PixelHeight;
} D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_INPUT;
```

`pMotionVectorHeap`

The <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_INPUT:1 -->[ID3D12VideoMotionVectorHeap](#motion-objects)<!-- d3d12-review-inline:end:video-motion:M-D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_INPUT:1 --></ins> containing the hardware-dependent data layout of the motion search.

`PixelWidth`

The pixel width of the texture that the motion estimation operation was performed on. The <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_INPUT:3 -->motion vector heap<!-- d3d12-review-inline:end:video-motion:M-D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_INPUT:3 --></ins> may be allocated to support a size range, this parameter informs the size of the last motion estimation operation.

`PixelHeight`

The pixel height of the texture that the motion estimation operation was performed on. The <ins><!-- d3d12-review-inline:begin:video-motion:M-D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_INPUT:5 -->motion vector heap<!-- d3d12-review-inline:end:video-motion:M-D3D12_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_INPUT:5 --></ins> may be allocated to support a size range, this parameter informs the size of the last motion estimation operation.

<a id="motion-driver"></a>

## Driver reference

<!-- d3d12-review-alert:begin:video-motion:N-driver-entry:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The API size query uses NodeIndex and heap size fields first. The DDI uses NodeMask and estimator size fields first. API `pHintMotionVectorHeap` becomes driver `hDrvPreviousMotionVectorHeap`. The `_0060` support and resolve layouts omit the earlier `_0053` differences-metric fields.

<!-- d3d12-review-alert:end:video-motion:N-driver-entry:0 -->

<!-- d3d12-review-alert:begin:video-motion:N-driver-entry:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The selected _0060 device table slots are
> `pfnCalcPrivateVideoMotionEstimatorSize`, `pfnCreateVideoMotionEstimator`,
> `pfnDestroyVideoMotionEstimator`, `pfnCalcPrivateVideoMotionVectorHeapSize`,
> `pfnCreateVideoMotionVectorHeap`, and `pfnDestroyVideoMotionVectorHeap`.
> Their function declarations appear with their objects below.
> The encode list _0060 table maps `pfnEstimateMotion` to
> `PFND3D12DDI_ESTIMATE_MOTION_0053` and
> `pfnResolveVideoMotionVectorHeap` to
> `PFND3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_0060`.
> `pfnCloseCommandList` and `pfnResetCommandList` use the common
> `PFND3D12DDI_CLOSECOMMANDLIST` and `PFND3D12DDI_RESETCOMMANDLIST_0040`;
> `ClearState` is not a dedicated slot in this table.

<!-- d3d12-review-alert:end:video-motion:N-driver-entry:1 -->

<!-- d3d12-review-alert:begin:video-motion:N-driver-entry:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Feature `D3D12DDI_FEATURE_VERSION_VIDEO_0060_0` is 14 and requires at least `D3D12DDI_SUPPORTED_0043`. Motion work uses the video encode queue table.

<!-- d3d12-review-alert:end:video-motion:N-driver-entry:2 -->

<a id="motion-driver-types"></a>

### Driver block size, precision and coordinate types

```cpp
typedef enum D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_0053
{
    D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_0053_8X8       = 0,
    D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_0053_16X16     = 1,
} D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_0053;
```

```cpp
typedef enum D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_FLAGS_0053
{
    D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_FLAG_0053_NONE  = 0,
    D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_FLAG_0053_8X8        = (1 << D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_0053_8X8),
    D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_FLAG_0053_16X16      = (1 << D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_0053_16X16),

} D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_FLAGS_0053;
```

```cpp
typedef enum D3D12DDI_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_0053
{
    D3D12DDI_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_0053_QUARTER_PEL       = 0,
} D3D12DDI_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_0053;
```

```cpp
typedef enum D3D12DDI_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_FLAGS_0053
{
    D3D12DDI_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_FLAG_0053_NONE           = 0,
    D3D12DDI_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_FLAG_0053_QUARTER_PEL    = (1 << D3D12DDI_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_0053_QUARTER_PEL),

} D3D12DDI_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_FLAGS_0053;
```

```cpp
typedef struct D3D12DDI_RESOURCE_COORDINATE_0053
{
    // Coordinate values below index pixels.
    UINT64 X; // Used for buffer, 1D, 2D, 3D
    UINT Y; // Used for 2D, 3D
    UINT Z; // Used for 3D
    UINT SubresourceIndex; // indexes into mips, arrays. Used for 1D, 2D, 3D
} D3D12DDI_RESOURCE_COORDINATE_0053;
```

<!-- d3d12-review-alert:begin:video-motion:N-driver-shared-range:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The shared [driver capability definitions](video-decode.md#ddi-capability-payloads) supply `D3D12DDI_VIDEO_SIZE_RANGE_0032`.

<!-- d3d12-review-alert:end:video-motion:N-driver-shared-range:0 -->

<!-- d3d12-review-alert:begin:video-motion:N-driver-protected-gate:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The protected motion capability case is `D3D12DDICAPS_TYPE_VIDEO_0072_MOTION_ESTIMATOR_PROTECTED_RESOURCES` (30).

<!-- d3d12-review-alert:end:video-motion:N-driver-protected-gate:0 -->

```cpp
typedef enum D3D12DDI_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAGS_0072
{
    D3D12DDI_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAG_0072_NONE                    = 0,
    D3D12DDI_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAG_0072_SUPPORTED               = 0x1,

} D3D12DDI_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAGS_0072;
```

```cpp
typedef struct D3D12DDI_VIDEO_MOTION_ESTIMATOR_PROTECTED_RESOURCES_DATA_0072
{
    UINT NodeIndex;                                                                           // input
    D3D12DDI_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAGS_0072 SupportFlags;                        // output
} D3D12DDI_VIDEO_MOTION_ESTIMATOR_PROTECTED_RESOURCES_DATA_0072;
```

<a id="motion-driver-capabilities"></a>

### Driver capability payloads

<!-- d3d12-review-alert:begin:video-motion:N-driver-query-protocol:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The shared
> [driver capability protocol](video-decode.md#ddi-capability-payloads) defines
> `D3D12DDIARG_VIDEO_GETCAPS_0020` and the
> [video driver entry](video-decode.md#decode-driver) defines
> `PFND3D12DDI_VIDEO_GETCAPS`. For the motion cases, `pInfo` is null,
> `pData` addresses the named payload and `DataSize` is `sizeof` that payload:

<!-- d3d12-review-alert:end:video-motion:N-driver-query-protocol:0 -->

* <ins><!-- d3d12-review-inline:begin:video-motion:N-driver-query-protocol:1 -->`D3D12DDICAPS_TYPE_VIDEO_0053_FEATURE_AREA_SUPPORT` (19) uses<!-- d3d12-review-inline:end:video-motion:N-driver-query-protocol:1 --></ins>
  `D3D12DDI_VIDEO_FEATURE_AREA_SUPPORT_DATA_0053`.
* <ins><!-- d3d12-review-inline:begin:video-motion:N-driver-query-protocol:1 -->`D3D12DDICAPS_TYPE_VIDEO_0053_MOTION_ESTIMATOR` (20) uses<!-- d3d12-review-inline:end:video-motion:N-driver-query-protocol:1 --></ins>
  `D3D12DDI_VIDEO_MOTION_ESTIMATOR_DATA_0060`.
* <ins><!-- d3d12-review-inline:begin:video-motion:N-driver-query-protocol:1 -->`D3D12DDICAPS_TYPE_VIDEO_0053_MOTION_ESTIMATOR_SIZE` (21) uses<!-- d3d12-review-inline:end:video-motion:N-driver-query-protocol:1 --></ins>
  `D3D12DDI_VIDEO_MOTION_ESTIMATOR_SIZE_DATA_0060`.
* <ins><!-- d3d12-review-inline:begin:video-motion:N-driver-query-protocol:1 -->`D3D12DDICAPS_TYPE_VIDEO_0072_MOTION_ESTIMATOR_PROTECTED_RESOURCES` (30)<!-- d3d12-review-inline:end:video-motion:N-driver-query-protocol:1 --></ins>
  uses `D3D12DDI_VIDEO_MOTION_ESTIMATOR_PROTECTED_RESOURCES_DATA_0072`.

<!-- d3d12-review-alert:begin:video-motion:N-driver-query-protocol:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The negotiated video DDI version selects the payload layout. A shared capability case number does not make `_0053` and `_0060` payloads interchangeable.

<!-- d3d12-review-alert:end:video-motion:N-driver-query-protocol:2 -->

The `D3D12DDICAPS_TYPE_VIDEO_0020` <ins><!-- d3d12-review-inline:begin:video-motion:R-69:0 -->enum identifies capability checks for Motion Estimation.<!-- d3d12-review-inline:end:video-motion:R-69:0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-motion:R-73:0 -->`D3D12DDICAPS_TYPE_VIDEO_0053_FEATURE_AREA_SUPPORT`<!-- d3d12-review-inline:end:video-motion:R-73:0 --></ins>

Video Decode, Video Processing, and Video Encoding are all versioned under the D3D12 Video extended feature. However, <ins><!-- d3d12-review-inline:begin:video-motion:R-73:1 -->these DDIs mostly<!-- d3d12-review-inline:end:video-motion:R-73:1 --></ins> describe optional features. <ins><!-- d3d12-review-inline:begin:video-motion:R-73:1 -->This cap helps shortcut understanding<!-- d3d12-review-inline:end:video-motion:R-73:1 --></ins> of driver support for any decode, video processing, or encode support making it easier to block queue/commandlist/command recorder/command pool objects. Each of these queue types has required functionality that we don't want to require for encode if motion estimation or encode is not supported. In all cases, <ins><!-- d3d12-review-inline:begin:video-motion:R-73:1 -->function tables for a supported queue type must be fully populated; functions for an unsupported queue type may be nullptr.<!-- d3d12-review-inline:end:video-motion:R-73:1 --></ins>

By reporting any video feature version, driver must support the `pfnGetCaps` member of `D3D12DDI_DEVICE_FUNCS_VIDEO`.

<ins><!-- d3d12-review-inline:begin:video-motion:R-78:0 -->`D3D12DDICAPS_TYPE_VIDEO_0053_MOTION_ESTIMATOR`<!-- d3d12-review-inline:end:video-motion:R-78:0 --></ins>

Checks for motion estimator support.  <ins><!-- d3d12-review-inline:begin:video-motion:R-78:1 -->See D3D12DDI_VIDEO_MOTION_ESTIMATOR_DATA_0060.<!-- d3d12-review-inline:end:video-motion:R-78:1 --></ins>

<ins><!-- d3d12-review-inline:begin:video-motion:R-81:0 -->`D3D12DDICAPS_TYPE_VIDEO_0053_MOTION_ESTIMATOR_SIZE`<!-- d3d12-review-inline:end:video-motion:R-81:0 --></ins>

Checks for Motion Estimator object sizes.  D3D12 applications are given a budget.  This helps applications account for these objects.

<a id="video-feature-area-support"></a>

#### D3D12DDI_VIDEO_FEATURE_AREA_SUPPORT_DATA_0053

```cpp
typedef struct D3D12DDI_VIDEO_FEATURE_AREA_SUPPORT_DATA_0053
{
    UINT NodeIndex;                                                     // input
    BOOL VideoDecodeSupport;                                            // output
    BOOL VideoProcessSupport;                                           // output
    BOOL VideoEncodeSupport;                                            // output
} D3D12DDI_VIDEO_FEATURE_AREA_SUPPORT_DATA_0053;
```

<ins><!-- d3d12-review-inline:begin:video-motion:R-98:0 -->This payload describes the command types supported by the driver.<!-- d3d12-review-inline:end:video-motion:R-98:0 --></ins> Driver must report support for at least one video command type if the video feature version is supported.

<ins><!-- d3d12-review-inline:begin:video-motion:R-102:0 -->`NodeIndex`<!-- d3d12-review-inline:end:video-motion:R-102:0 --></ins>

In multi-adapter operation, this indicates which physical adapter of the device this operation applies to.

<!-- d3d12-review-alert:begin:video-motion:N-feature-area-decode-owner:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [decode driver associations](video-decode.md#ddi-table-members)
> define the decoding operations named by the following device slots.

<!-- d3d12-review-alert:end:video-motion:N-feature-area-decode-owner:0 -->

<ins><!-- d3d12-review-inline:begin:video-motion:R-107:0 -->If `VideoDecodeSupport` is TRUE:<!-- d3d12-review-inline:end:video-motion:R-107:0 --></ins>

- Predication, timestamp queries, and history buffers must be supported with the decode queue type.

- The table corresponding to the following table types for the reported video feature must be fully populated:
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-111:0 -->`D3D12DDI_TABLE_TYPE_0022_COMMAND_LIST_VIDEO_DECODE`<!-- d3d12-review-inline:end:video-motion:R-111:0 --></ins>
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-111:0 -->`D3D12DDI_TABLE_TYPE_0022_COMMAND_QUEUE_VIDEO_DECODE`<!-- d3d12-review-inline:end:video-motion:R-111:0 --></ins>

- Also, the following members of the table type corresponding to `D3D12DDI_TABLE_TYPE_0020_DEVICE_VIDEO` and the reported video feature version must be populated:
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-115:0 -->`pfnCalcPrivateVideoDecoderSize`<!-- d3d12-review-inline:end:video-motion:R-115:0 --></ins>
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-115:0 -->`pfnCreateVideoDecoder`<!-- d3d12-review-inline:end:video-motion:R-115:0 --></ins>
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-115:0 -->`pfnDestroyVideoDecoder`<!-- d3d12-review-inline:end:video-motion:R-115:0 --></ins>
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-115:0 -->`pfnCalcPrivateVideoDecoderHeapSize`<!-- d3d12-review-inline:end:video-motion:R-115:0 --></ins>
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-115:0 -->`pfnCreateVideoDecoderHeap`<!-- d3d12-review-inline:end:video-motion:R-115:0 --></ins>
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-115:0 -->`pfnDestroyVideoDecoderHeap`<!-- d3d12-review-inline:end:video-motion:R-115:0 --></ins>

When the flag is not set, all of these functions may be set to nullptr.

<!-- d3d12-review-alert:begin:video-motion:N-feature-area-process-owner:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [processing driver associations](video-processing.md#process-ddi-associations)
> define the processing operations named by the following device slots.

<!-- d3d12-review-alert:end:video-motion:N-feature-area-process-owner:0 -->

<ins><!-- d3d12-review-inline:begin:video-motion:R-128:0 -->If `VideoProcessSupport` is TRUE:<!-- d3d12-review-inline:end:video-motion:R-128:0 --></ins>

- Predication, timestamp queries, and history buffers must be supported with the video process queue type.

- The table corresponding to the following table types for the reported video feature must be fully populated:
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-132:0 -->`D3D12DDI_TABLE_TYPE_0022_COMMAND_LIST_VIDEO_PROCESS`<!-- d3d12-review-inline:end:video-motion:R-132:0 --></ins>
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-132:0 -->`D3D12DDI_TABLE_TYPE_0022_COMMAND_QUEUE_VIDEO_PROCESS`<!-- d3d12-review-inline:end:video-motion:R-132:0 --></ins>

- Also, the following members of the table type corresponding to `D3D12DDI_TABLE_TYPE_0020_DEVICE_VIDEO` and the reported video feature version must be populated:
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-136:0 -->`pfnCalcPrivateVideoProcessorSize`<!-- d3d12-review-inline:end:video-motion:R-136:0 --></ins>
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-136:0 -->`pfnCreateVideoProcessor`<!-- d3d12-review-inline:end:video-motion:R-136:0 --></ins>
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-136:0 -->`pfnDestroyVideoProcessor`<!-- d3d12-review-inline:end:video-motion:R-136:0 --></ins>

When the flag is not set, all of these functions may be set to nullptr.

<ins><!-- d3d12-review-inline:begin:video-motion:R-146:0 -->If `VideoEncodeSupport` is TRUE:<!-- d3d12-review-inline:end:video-motion:R-146:0 --></ins>

- Predication, timestamp queries, and history buffers must be supported with the video encode queue type.

- The table corresponding to the following table types for the reported video feature must be fully populated:
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-150:0 -->`D3D12DDI_TABLE_TYPE_0053_COMMAND_LIST_VIDEO_ENCODE`<!-- d3d12-review-inline:end:video-motion:R-150:0 --></ins>
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-150:0 -->`D3D12DDI_TABLE_TYPE_0053_COMMAND_QUEUE_VIDEO_ENCODE`<!-- d3d12-review-inline:end:video-motion:R-150:0 --></ins>

- Also, the following members of the table type corresponding to `D3D12DDI_TABLE_TYPE_0020_DEVICE_VIDEO` and the reported video feature version must be populated:
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-154:0 -->`pfnCalcPrivateVideoMotionEstimatorSize`<!-- d3d12-review-inline:end:video-motion:R-154:0 --></ins>
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-154:0 -->`pfnCreateVideoMotionEstimator`<!-- d3d12-review-inline:end:video-motion:R-154:0 --></ins>
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-154:0 -->`pfnDestroyVideoMotionEstimator`<!-- d3d12-review-inline:end:video-motion:R-154:0 --></ins>

When the flag is not set, all of these functions may be set to nullptr.

#### D3D12DDI_VIDEO_MOTION_ESTIMATOR_DATA_0060

```cpp
typedef struct D3D12DDI_VIDEO_MOTION_ESTIMATOR_DATA_0060
{
    UINT NodeIndex;                                                                           // input
    DXGI_FORMAT InputFormat;                                                                  // input
    D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_FLAGS_0053 BlockSizeFlags;              // output
    D3D12DDI_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_FLAGS_0053 PrecisionFlags;               // output
    D3D12DDI_VIDEO_SIZE_RANGE_0032 SizeRange;                                                 // output
} D3D12DDI_VIDEO_MOTION_ESTIMATOR_DATA_0060;
```

<ins><!-- d3d12-review-inline:begin:video-motion:R-179:0 -->`NodeIndex`<!-- d3d12-review-inline:end:video-motion:R-179:0 --></ins>

In multi-adapter operation, this indicates which physical adapter of the device this operation applies to.

<ins><!-- d3d12-review-inline:begin:video-motion:R-182:0 -->`InputFormat`<!-- d3d12-review-inline:end:video-motion:R-182:0 --></ins>

The DXGI_FORMAT of the input frame and reference frame. Currently only DXGI_FORMAT_NV12 is allowed.

<ins><!-- d3d12-review-inline:begin:video-motion:R-185:0 -->`BlockSizeFlags`<!-- d3d12-review-inline:end:video-motion:R-185:0 --></ins>

The block sizes supported by driver. At least one bit must be set to support the motion estimation operation. Set to NONE if not supported. See `D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_FLAGS_0053` for more details.

<ins><!-- d3d12-review-inline:begin:video-motion:R-188:0 -->`PrecisionFlags`<!-- d3d12-review-inline:end:video-motion:R-188:0 --></ins>

The precision supported by driver. At least one bit must be set to support the motion estimation operation. Set to NONE if not supported. See `D3D12DDI_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_FLAGS_0053` for more details.

<ins><!-- d3d12-review-inline:begin:video-motion:R-191:0 -->`SizeRange`<!-- d3d12-review-inline:end:video-motion:R-191:0 --></ins>

Sets the minimum and maximum input and reference size in Pixels supported by driver. Set to zeros when motion estimation is not supported.

#### D3D12DDI_VIDEO_MOTION_ESTIMATOR_SIZE_DATA_0060

```cpp
typedef struct D3D12DDI_VIDEO_MOTION_ESTIMATOR_SIZE_DATA_0060
{
    UINT NodeMask;                                                              // input
    DXGI_FORMAT InputFormat;                                                    // input
    D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_0053 BlockSize;           // input
    D3D12DDI_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_0053 Precision;            // input
    D3D12DDI_VIDEO_SIZE_RANGE_0032 SizeRange;                                   // input
    BOOL Protected;                                                             // input
    UINT64 MotionEstimatorMemoryPoolL0Size;                                     // output
    UINT64 MotionEstimatorMemoryPoolL1Size;                                     // output
    UINT64 MotionVectorHeapMemoryPoolL0Size;                                    // output
    UINT64 MotionVectorHeapMemoryPoolL1Size;                                    // output
} D3D12DDI_VIDEO_MOTION_ESTIMATOR_SIZE_DATA_0060;
```

This cap determines the residency size for the motion estimator and the hardware dependent output buffer when called with the same creation parameters.

<ins><!-- d3d12-review-inline:begin:video-motion:R-219:0 -->`NodeMask`<!-- d3d12-review-inline:end:video-motion:R-219:0 --></ins>

In multi-adapter operation, this indicates which physical adapter of the device this operation applies to.

<ins><!-- d3d12-review-inline:begin:video-motion:R-222:0 -->`InputFormat`<!-- d3d12-review-inline:end:video-motion:R-222:0 --></ins>

The DXGI_FORMAT of the input frame and reference frame. Currently only DXGI_FORMAT_NV12 is allowed.

<ins><!-- d3d12-review-inline:begin:video-motion:R-225:0 -->`BlockSize`<!-- d3d12-review-inline:end:video-motion:R-225:0 --></ins>

The block size to use with the motion estimator. See `D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_0053` for details.

<ins><!-- d3d12-review-inline:begin:video-motion:R-228:0 -->`Precision`<!-- d3d12-review-inline:end:video-motion:R-228:0 --></ins>

The precision to use with the motion estimator. See `D3D12DDI_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_0053` for more details.

<ins><!-- d3d12-review-inline:begin:video-motion:R-231:0 -->`SizeRange`<!-- d3d12-review-inline:end:video-motion:R-231:0 --></ins>

The size range allowed with the Motion Estimator. This may be a subset of the size range supported by the driver to optimize memory usage.

<ins><!-- d3d12-review-inline:begin:video-motion:R-234:0 -->`Protected`<!-- d3d12-review-inline:end:video-motion:R-234:0 --></ins>

TRUE if the motion estimator operates on protected resource input and produces protected output. The driver must also support protected resources for D3D12 to set TRUE. FALSE otherwise.

<ins><!-- d3d12-review-inline:begin:video-motion:R-237:0 -->`MotionEstimatorMemoryPoolL0Size`<!-- d3d12-review-inline:end:video-motion:R-237:0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-motion:R-237:1 -->Driver outputs the L0 size of the motion estimator object. L0 is system memory.<!-- d3d12-review-inline:end:video-motion:R-237:1 --></ins>

<ins><!-- d3d12-review-inline:begin:video-motion:R-240:0 -->`MotionEstimatorMemoryPoolL1Size`<!-- d3d12-review-inline:end:video-motion:R-240:0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-motion:R-240:1 -->Driver outputs the L1 size of the motion estimator object. L1 is local video memory for discrete/NUMA adapters and unavailable for UMA adapters.<!-- d3d12-review-inline:end:video-motion:R-240:1 --></ins>

<ins><!-- d3d12-review-inline:begin:video-motion:R-243:0 -->`MotionVectorHeapMemoryPoolL0Size`<!-- d3d12-review-inline:end:video-motion:R-243:0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-motion:R-243:1 -->Driver outputs the L0 size of the motion vector heap object. L0 is system memory.<!-- d3d12-review-inline:end:video-motion:R-243:1 --></ins>

<ins><!-- d3d12-review-inline:begin:video-motion:R-246:0 -->`MotionVectorHeapMemoryPoolL1Size`<!-- d3d12-review-inline:end:video-motion:R-246:0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-motion:R-246:1 -->Driver outputs the L1 size of the motion vector heap object. L1 is local video memory for discrete/NUMA adapters and unavailable for UMA adapters.<!-- d3d12-review-inline:end:video-motion:R-246:1 --></ins>

<a id="motion-driver-objects"></a>

### Driver object lifetime and allocation

The motion estimation operation has a context object to associate the lifetime of internal allocations needed to perform the operation. All allocations <ins><!-- d3d12-review-inline:begin:video-motion:R-252:0 -->associated with this object<!-- d3d12-review-inline:end:video-motion:R-252:0 --></ins> should be allocated when the object is created and deallocated when the object is de-allocated. This should include any buffers used as temporary/scratch storage.

Operations against this object may be recorded to command lists in a different order than execution. No two API queue instances may be executing command lists containing this object at the same time and expect valid results. The application is responsible for synchronizing access across multiple queue instances.

#### Make Resident and Evict

This object must support `PFND3D12DDI_MAKERESIDENT` and `PFND3D12DDI_EVICT`.

#### Get Debug Allocation Info

This object must support the `PFND3D12DDI_GET_DEBUG_ALLOCATION_INFO` DDI. This pre-existing DDI returns the associated kernel mode allocation handles and GPU Virtual Address ranges.

#### Query Size

D3D12 applications manage a memory budget and may need to know the size of the motion estimator to do so. See the `D3D12DDICAPS_TYPE_VIDEO_0053_MOTION_ESTIMATOR_SIZE` caps check.

<!-- d3d12-review-alert:begin:video-motion:N-handle-266:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12DDI_HVIDEOMOTIONESTIMATOR_0053` is the driver handle. Its `D3D12DDI_HANDLETYPE` value is `D3D12DDI_HT_0053_VIDEO_MOTION_ESTIMATOR = 45`.

<!-- d3d12-review-alert:end:video-motion:N-handle-266:0 -->

<ins><!-- d3d12-review-inline:begin:video-motion:R-279:0 -->A handle and Handle Type are defined<!-- d3d12-review-inline:end:video-motion:R-279:0 --></ins> for the motion estimator object.

#### Creating the Motion Estimator

These methods create a motion estimator instance.

#### D3D12DDIARG_CREATE_VIDEO_MOTION_ESTIMATOR_0060

```cpp
typedef struct D3D12DDIARG_CREATE_VIDEO_MOTION_ESTIMATOR_0060
{
    UINT NodeMask;
    DXGI_FORMAT InputFormat;
    D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_0053 BlockSize;
    D3D12DDI_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_0053 Precision;
    D3D12DDI_VIDEO_SIZE_RANGE_0032 SizeRange;
    D3D12DDI_HPROTECTEDRESOURCESESSION_0030 hDrvProtectedResourceSession;
} D3D12DDIARG_CREATE_VIDEO_MOTION_ESTIMATOR_0060;
```

Specifies the creation arguments for the motion estimator. Valid arguments are determined by the <ins><!-- d3d12-review-inline:begin:video-motion:R-297:0 -->D3D12DDICAPS_TYPE_VIDEO_0053_MOTION_ESTIMATOR<!-- d3d12-review-inline:end:video-motion:R-297:0 --></ins> caps check.

<ins><!-- d3d12-review-inline:begin:video-motion:R-301:0 -->`NodeMask`<!-- d3d12-review-inline:end:video-motion:R-301:0 --></ins>

For single GPU operation, set this to zero. If there are multiple GPU nodes, set a bit to identify the node (the device\'s physical adapter) <ins><!-- d3d12-review-inline:begin:video-motion:R-301:1 -->on which the motion object will be used<!-- d3d12-review-inline:end:video-motion:R-301:1 --></ins>. Each bit in the mask corresponds to a single node. Only 1 bit may be set.

<ins><!-- d3d12-review-inline:begin:video-motion:R-304:0 -->`InputFormat`<!-- d3d12-review-inline:end:video-motion:R-304:0 --></ins>

The DXGI_FORMAT of the input and reference frames. This motion estimator may only be used with input textures of this format.

<ins><!-- d3d12-review-inline:begin:video-motion:R-307:0 -->`BlockSize`<!-- d3d12-review-inline:end:video-motion:R-307:0 --></ins>

The search block size to use with this motion estimator. This parameter determines the number of <ins><!-- d3d12-review-inline:begin:video-motion:R-307:1 -->motion vectors<!-- d3d12-review-inline:end:video-motion:R-307:1 --></ins> output during the resolve step. This must be a block size reported as supported by the driver. See `D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_0053`.

<ins><!-- d3d12-review-inline:begin:video-motion:R-310:0 -->`Precision`<!-- d3d12-review-inline:end:video-motion:R-310:0 --></ins>

The precision of motion vector components. This must be a precision reported as supported by the driver. See `D3D12DDI_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_0053`.

<ins><!-- d3d12-review-inline:begin:video-motion:R-313:0 -->`SizeRange`<!-- d3d12-review-inline:end:video-motion:R-313:0 --></ins>

Indicates the minimum and maximum size of the inputs to the motion estimation operation. Actual size is provided at motion estimation time. Driver should allocate at the creation of the motion estimator to support any size within the range. This size range must be a subset of the size range supported by the driver.

<ins><!-- d3d12-review-inline:begin:video-motion:R-316:0 -->`hDrvProtectedResourceSession`<!-- d3d12-review-inline:end:video-motion:R-316:0 --></ins>

Indicates the protected resource session to use for the motion estimator. This can inform internal allocations for the motion estimator. This value is NULL if the motion estimator will operate on unprotected resources.

#### PFND3D12DDI_CALCPRIVATEVIDEOMOTIONESTIMATORSIZE_0060

```cpp
typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALCPRIVATEVIDEOMOTIONESTIMATORSIZE_0060 )( D3D12DDI_HDEVICE hDrvDevice, _In_ CONST D3D12DDIARG_CREATE_VIDEO_MOTION_ESTIMATOR_0060* pArgs);
```

The D3D runtime allocates memory for storing <ins><!-- d3d12-review-inline:begin:video-motion:R-325:0 -->the driver's CPU object<!-- d3d12-review-inline:end:video-motion:R-325:0 --></ins> representing the motion estimator. This method is used to calculate the driver object size.

#### PFND3D12DDI_CREATEVIDEOMOTIONESTIMATOR_0060

```cpp
typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATEVIDEOMOTIONESTIMATOR_0060 )( D3D12DDI_HDEVICE hDrvDevice, _In_ CONST D3D12DDIARG_CREATE_VIDEO_MOTION_ESTIMATOR_0060* pArgs, D3D12DDI_HVIDEOMOTIONESTIMATOR_0053 hDrvMotionEstimator);
```

Creates the Motion Estimator.

#### Destroy the Motion Estimator

#### PFND3D12DDI_DESTROYVIDEOMOTIONESTIMATOR_0053

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_DESTROYVIDEOMOTIONESTIMATOR_0053 )( D3D12DDI_HDEVICE hDrvDevice, D3D12DDI_HVIDEOMOTIONESTIMATOR_0053 hDrvMotionEstimator );
```

Destroys the Motion Estimator.

### Motion Estimation Output Object

The Motion Vector Heap object is created to store hardware dependent motion vector output. Motion vector output is opaque.  <ins><!-- d3d12-review-inline:begin:video-motion:R-346:0 -->A resolve operation will take<!-- d3d12-review-inline:end:video-motion:R-346:0 --></ins> this opaque object as input and resolve it to the specified format. The size of this object is driver controlled and determined by `D3D12DDICAPS_TYPE_VIDEO_0053_MOTION_ESTIMATOR_SIZE`.

#### Make Resident and Evict

This object must support `PFND3D12DDI_MAKERESIDENT` and `PFND3D12DDI_EVICT`.

#### Get Debug Allocation Info

This object must support the `PFND3D12DDI_GET_DEBUG_ALLOCATION_INFO` DDI. This pre-existing DDI returns the associated kernel mode allocation handles and GPU Virtual Address ranges.

#### Query Size

D3D12 applications manage a memory budget and may need to know the size of the motion vector heap to do so. See the `D3D12DDICAPS_TYPE_VIDEO_0053_MOTION_ESTIMATOR_SIZE` caps check.

<!-- d3d12-review-alert:begin:video-motion:N-handle-359:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12DDI_HVIDEOMOTIONVECTORHEAP_0053` is the driver handle. Its `D3D12DDI_HANDLETYPE` value is `D3D12DDI_HT_0053_VIDEO_MOTION_VECTOR_HEAP = 46`.

<!-- d3d12-review-alert:end:video-motion:N-handle-359:0 -->

<ins><!-- d3d12-review-inline:begin:video-motion:R-372:0 -->A handle and Handle Type are defined<!-- d3d12-review-inline:end:video-motion:R-372:0 --></ins> for the motion vector heap object.

#### Creating the Motion Vector Heap

<ins><!-- d3d12-review-inline:begin:video-motion:R-376:0 -->These methods create a motion vector heap instance.<!-- d3d12-review-inline:end:video-motion:R-376:0 --></ins>

#### D3D12DDIARG_CREATE_VIDEO_MOTION_VECTOR_HEAP_0060

```cpp
typedef struct D3D12DDIARG_CREATE_VIDEO_MOTION_VECTOR_HEAP_0060
{
    UINT NodeMask;
    DXGI_FORMAT InputFormat;
    D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_0053 BlockSize;
    D3D12DDI_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_0053 Precision;
    D3D12DDI_VIDEO_SIZE_RANGE_0032 SizeRange;
    D3D12DDI_HPROTECTEDRESOURCESESSION_0030 hDrvProtectedResourceSession;
} D3D12DDIARG_CREATE_VIDEO_MOTION_VECTOR_HEAP_0060;
```

Specifies the creation arguments for the motion vector heap. Valid arguments are determined by the <ins><!-- d3d12-review-inline:begin:video-motion:R-390:0 -->D3D12DDICAPS_TYPE_VIDEO_0053_MOTION_ESTIMATOR<!-- d3d12-review-inline:end:video-motion:R-390:0 --></ins> caps check.

<ins><!-- d3d12-review-inline:begin:video-motion:R-394:0 -->`NodeMask`<!-- d3d12-review-inline:end:video-motion:R-394:0 --></ins>

For single GPU operation, set this to zero. If there are multiple GPU nodes, set a bit to identify the node (the device\'s physical adapter) <ins><!-- d3d12-review-inline:begin:video-motion:R-394:1 -->on which the motion object will be used<!-- d3d12-review-inline:end:video-motion:R-394:1 --></ins>. Each bit in the mask corresponds to a single node. Only 1 bit may be set.

<ins><!-- d3d12-review-inline:begin:video-motion:R-397:0 -->`InputFormat`<!-- d3d12-review-inline:end:video-motion:R-397:0 --></ins>

The DXGI_FORMAT of the input and reference frames. This motion vector heap may only be used with input textures of this format.

<ins><!-- d3d12-review-inline:begin:video-motion:R-400:0 -->`BlockSize`<!-- d3d12-review-inline:end:video-motion:R-400:0 --></ins>

The search block size to use with this motion vector heap. This parameter determines the number of <ins><!-- d3d12-review-inline:begin:video-motion:R-400:1 -->motion vectors<!-- d3d12-review-inline:end:video-motion:R-400:1 --></ins> output during the resolve step. This must be a block size reported as supported by the driver. See `D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_0053`.

<ins><!-- d3d12-review-inline:begin:video-motion:R-403:0 -->`Precision`<!-- d3d12-review-inline:end:video-motion:R-403:0 --></ins>

The precision of motion vector components. This must be a precision reported as supported by the driver. See `D3D12DDI_VIDEO_MOTION_ESTIMATOR_VECTOR_PRECISION_0053`.

<ins><!-- d3d12-review-inline:begin:video-motion:R-406:0 -->`SizeRange`<!-- d3d12-review-inline:end:video-motion:R-406:0 --></ins>

Indicates the minimum and maximum size of the inputs to the motion estimation operation. Actual size is provided at motion estimation time. Driver should <ins><!-- d3d12-review-inline:begin:video-motion:R-406:1 -->allocate at the creation of the motion vector heap<!-- d3d12-review-inline:end:video-motion:R-406:1 --></ins> to support any size within the range. This size range must be a subset of the size range supported by the driver.

<ins><!-- d3d12-review-inline:begin:video-motion:R-409:0 -->`hDrvProtectedResourceSession`<!-- d3d12-review-inline:end:video-motion:R-409:0 --></ins>

Indicates the protected resource session to use for the motion vector heap. This can inform if internal allocations must be allocated as protected. This value is NULL if the motion estimation operation will operate on only unprotected resources.

#### PFND3D12DDI_CALCPRIVATEVIDEOMOTIONVECTORHEAPSIZE_0060

```cpp
typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALCPRIVATEVIDEOMOTIONVECTORHEAPSIZE_0060 )( D3D12DDI_HDEVICE hDrvDevice, _In_ CONST D3D12DDIARG_CREATE_VIDEO_MOTION_VECTOR_HEAP_0060* pArgs);
```

The D3D runtime allocates memory for storing <ins><!-- d3d12-review-inline:begin:video-motion:R-418:0 -->the driver's CPU object<!-- d3d12-review-inline:end:video-motion:R-418:0 --></ins> representing the motion vector heap. This method is used to calculate the driver object size.

#### PFND3D12DDI_CREATEVIDEOMOTIONVECTORHEAP_0060

```cpp
typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATEVIDEOMOTIONVECTORHEAP_0060 )( D3D12DDI_HDEVICE hDrvDevice, _In_ CONST D3D12DDIARG_CREATE_VIDEO_MOTION_VECTOR_HEAP_0060* pArgs, D3D12DDI_HVIDEOMOTIONVECTORHEAP_0053 hDrvMotionEstimator);
```

Creates the Motion Vector Heap.  This object represents the hardware dependent output of a motion search.

#### Destroy the Motion Vector Heap

#### PFND3D12DDI_DESTROYVIDEOMOTIONVECTORHEAP_0053

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_DESTROYVIDEOMOTIONVECTORHEAP_0053 )( D3D12DDI_HDEVICE hDrvDevice, D3D12DDI_HVIDEOMOTIONVECTORHEAP_0053 hDrvMotionEstimator );
```

Destroys the Motion Vector Heap.

### Motion Estimation Operation

#### D3D12DDI_VIDEO_MOTION_ESTIMATOR_OUTPUT_0053

```cpp
typedef struct D3D12DDI_VIDEO_MOTION_ESTIMATOR_OUTPUT_0053
{
    D3D12DDI_HVIDEOMOTIONVECTORHEAP_0053                  hDrvMotionVectorHeap;
} D3D12DDI_VIDEO_MOTION_ESTIMATOR_OUTPUT_0053;
```

Describes the output of the motion estimation operation.

<ins><!-- d3d12-review-inline:begin:video-motion:R-448:0 -->*hDrvMotionVectorHeap*<!-- d3d12-review-inline:end:video-motion:R-448:0 --></ins>
The <ins><!-- d3d12-review-inline:begin:video-motion:R-448:0 -->motion vector heap<!-- d3d12-review-inline:end:video-motion:R-448:0 --></ins> stores the motion estimator output in hardware dependent layout.

#### D3D12DDI_VIDEO_MOTION_ESTIMATOR_INPUT_0053

```cpp
typedef struct D3D12DDI_VIDEO_MOTION_ESTIMATOR_INPUT_0053
{
    D3D12DDI_HRESOURCE                          hDrvInputTexture2D;
    UINT                                        InputSubresourceIndex;
    D3D12DDI_HRESOURCE                          hDrvReferenceTexture2D;
    UINT                                        ReferenceSubresourceIndex;
    D3D12DDI_HVIDEOMOTIONVECTORHEAP_0053        hDrvPreviousMotionVectorHeap;
} D3D12DDI_VIDEO_MOTION_ESTIMATOR_INPUT_0053;
```

Describes the input to the motion estimation operation.

<ins><!-- d3d12-review-inline:begin:video-motion:R-467:0 -->`hDrvInputTexture2D`<!-- d3d12-review-inline:end:video-motion:R-467:0 --></ins>

The handle of the current frame.  The operation applies to the entire frame.

<ins><!-- d3d12-review-inline:begin:video-motion:R-470:0 -->`InputSubresourceIndex`<!-- d3d12-review-inline:end:video-motion:R-470:0 --></ins>

Indicates the base plane of the Mip and Array Slice to use for the input.

<ins><!-- d3d12-review-inline:begin:video-motion:R-473:0 -->`hDrvReferenceTexture2D`<!-- d3d12-review-inline:end:video-motion:R-473:0 --></ins>

The handle of the reference frame, or Past frame, used for motion estimation.

<ins><!-- d3d12-review-inline:begin:video-motion:R-476:0 -->`ReferenceSubresourceIndex`<!-- d3d12-review-inline:end:video-motion:R-476:0 --></ins>

Indicates the base plane of the Mip and Array Slice to use for the reference.

<ins><!-- d3d12-review-inline:begin:video-motion:R-479:0 -->`hDrvPreviousMotionVectorHeap`<!-- d3d12-review-inline:end:video-motion:R-479:0 --></ins>

This parameter may be NULL indicating that previous motion estimator output should not be considered for this operation. If non-NULL, this buffer contains the hardware dependent output of the previous motion estimator operation and may be used for hinting the current operation.

#### PFND3D12DDI_ESTIMATE_MOTION_0053

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_ESTIMATE_MOTION_0053 )(
    D3D12DDI_HCOMMANDLIST hDrvCommandList,
    D3D12DDI_HVIDEOMOTIONESTIMATOR_0053 hDrvMotionEstimator,
    CONST D3D12DDI_VIDEO_MOTION_ESTIMATOR_OUTPUT_0053* pOutputArguments,
    CONST D3D12DDI_VIDEO_MOTION_ESTIMATOR_INPUT_0053* pInputArguments
    );
```

Function to perform the motion estimation operation.

<ins><!-- d3d12-review-inline:begin:video-motion:R-495:0 -->`hDrvCommandList`<!-- d3d12-review-inline:end:video-motion:R-495:0 --></ins>

Driver handle for a video encode command list.

<ins><!-- d3d12-review-inline:begin:video-motion:R-498:0 -->`hDrvMotionEstimator`<!-- d3d12-review-inline:end:video-motion:R-498:0 --></ins>

 Handle to the motion estimator context object. <ins><!-- d3d12-review-inline:begin:video-motion:R-498:1 -->See [driver object lifetime and allocation](#motion-driver-objects)<!-- d3d12-review-inline:end:video-motion:R-498:1 --></ins> for more details.

<ins><!-- d3d12-review-inline:begin:video-motion:R-501:0 -->`pOutputArguments`<!-- d3d12-review-inline:end:video-motion:R-501:0 --></ins>

 The output arguments for the motion estimation operation. See `D3D12DDI_VIDEO_MOTION_ESTIMATOR_OUTPUT_0053`.

<ins><!-- d3d12-review-inline:begin:video-motion:R-504:0 -->`pInputArguments`<!-- d3d12-review-inline:end:video-motion:R-504:0 --></ins>

The input arguments for the motion estimation operation. See `D3D12DDI_VIDEO_MOTION_ESTIMATOR_INPUT_0053`.

### Resolving hardware-dependent output

The resolve operation is expected to be a light-weight translation of hardware dependent output to the API spec'd format.

#### D3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT_0060

```cpp
typedef struct D3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT_0060
{
    D3D12DDI_HRESOURCE hDrvMotionVectorTexture2D;
    D3D12DDI_RESOURCE_COORDINATE_0053 MotionVectorCoordinate;
} D3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT_0060;
```

<ins><!-- d3d12-review-inline:begin:video-motion:R-523:0 -->Describes the output<!-- d3d12-review-inline:end:video-motion:R-523:0 --></ins> of the resolve operation.

<ins><!-- d3d12-review-inline:begin:video-motion:R-527:0 -->`hDrvMotionVectorTexture2D`<!-- d3d12-review-inline:end:video-motion:R-527:0 --></ins>

The output resource for resolved motion vectors. <ins><!-- d3d12-review-inline:begin:video-motion:R-527:1 -->Motion vectors are resolved to DXGI_FORMAT_R16G16_SINT 2D textures.<!-- d3d12-review-inline:end:video-motion:R-527:1 --></ins> The resolved data is expected to be <ins><!-- d3d12-review-inline:begin:video-motion:R-527:1 -->a pair of signed 16-bit integers<!-- d3d12-review-inline:end:video-motion:R-527:1 --></ins> with quarter pel units with the X vector component stored in the R component and the Y vector component stored in the G component. Motion vectors are stored in a 2D layout that corresponds to the pixel layout of the original input textures.

<ins><!-- d3d12-review-inline:begin:video-motion:R-530:0 -->`MotionVectorCoordinate`<!-- d3d12-review-inline:end:video-motion:R-530:0 --></ins>

Specifies the output origin of the motion vectors. The remaining sub-region must be large enough to store all motion vectors per block specified by the input PixelWidth/Pixelheight and the <ins><!-- d3d12-review-inline:begin:video-motion:R-530:1 -->D3D12DDI_VIDEO_MOTION_ESTIMATOR_SEARCH_BLOCK_SIZE_0053.<!-- d3d12-review-inline:end:video-motion:R-530:1 --></ins>

#### D3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_INPUT_0053

```cpp
typedef struct D3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_INPUT_0053
{
    D3D12DDI_HVIDEOMOTIONVECTORHEAP_0053                    hDrvMotionVectorHeap;
    UINT                                                    PixelWidth;
    UINT                                                    PixelHeight;
} D3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_INPUT_0053;
```

Describes the input of the resolve operation.

<ins><!-- d3d12-review-inline:begin:video-motion:R-547:0 -->`hDrvMotionVectorHeap`<!-- d3d12-review-inline:end:video-motion:R-547:0 --></ins>

The motion vector heap containing the hardware dependent data layout of the motion search.

<ins><!-- d3d12-review-inline:begin:video-motion:R-550:0 -->`PixelWidth`<!-- d3d12-review-inline:end:video-motion:R-550:0 --></ins>

The pixel width of the texture that the motion estimation operation was performed on.  The <ins><!-- d3d12-review-inline:begin:video-motion:R-550:1 -->motion vector heap<!-- d3d12-review-inline:end:video-motion:R-550:1 --></ins> may be allocated to support a size range, this parameter informs the size of the last motion estimation operation.

<ins><!-- d3d12-review-inline:begin:video-motion:R-553:0 -->`PixelHeight`<!-- d3d12-review-inline:end:video-motion:R-553:0 --></ins>

The pixel height of the texture that the motion estimation operation was performed on.  The <ins><!-- d3d12-review-inline:begin:video-motion:R-553:1 -->motion vector heap<!-- d3d12-review-inline:end:video-motion:R-553:1 --></ins> may be allocated to support a size range, this parameter informs the size of the last motion estimation operation.

#### PFND3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_0060

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_0060 )(
    D3D12DDI_HCOMMANDLIST hDrvCommandList,
    CONST D3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT_0060* pOutputArguments,
    CONST D3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_INPUT_0053* pInputArguments
    );
```

The function used to record the resolve operation for the motion estimation data.

<ins><!-- d3d12-review-inline:begin:video-motion:R-570:0 -->`hDrvCommandList`<!-- d3d12-review-inline:end:video-motion:R-570:0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-motion:R-570:1 -->The video encode command list used<!-- d3d12-review-inline:end:video-motion:R-570:1 --></ins> to record the resolve operation.

<ins><!-- d3d12-review-inline:begin:video-motion:R-573:0 -->`pOutputArguments`<!-- d3d12-review-inline:end:video-motion:R-573:0 --></ins>

The output arguments for the resolve operation. See `D3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_OUTPUT_0060`.

<ins><!-- d3d12-review-inline:begin:video-motion:R-576:0 -->`pInputArguments`<!-- d3d12-review-inline:end:video-motion:R-576:0 --></ins>

The input arguments for the resolve operation. See `D3D12DDI_RESOLVE_VIDEO_MOTION_VECTOR_HEAP_INPUT_0053`.
