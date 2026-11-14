<a id="video-processing"></a>

# Video: processing reference

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

<ins><!-- d3d12-review-inline:begin:video-process:N-entry:0:authored:migration-05ae9c3d48234999-0 -->This subordinate reference describes the selected ordinary processing contracts
introduced by the [Video processing model](video.md#video-processing-model).
A processor fixes the input and output
stream descriptions. Each processing call supplies the current surfaces,
reference surfaces and operation arguments. Capability results apply to the
queried format, color space, size, field, stereo and rate combination, not to
arbitrary combinations of individually reported features.<!-- d3d12-review-inline:end:video-process:N-entry:0:authored:migration-05ae9c3d48234999-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-process:N-entry:1:authored:migration-842e5f89440f71f4-0 -->This is a **qualified draft**. The qualifications below distinguish published
contracts and scoped runtime validation from unestablished algorithm,
precision and hardware guarantees.<!-- d3d12-review-inline:end:video-process:N-entry:1:authored:migration-842e5f89440f71f4-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-process:LA-video-annotation-owner:0:authored:migration-e3b1864c01851463-0 -->The [command list annotation reference](diagnostics.md#command-list-annotations)
defines BeginEvent/EndEvent/SetMarker on `ID3D12VideoProcessCommandList`.
Their recording and allocator data lifetime follows
[common annotation state](command-list-state.md#annotations).<!-- d3d12-review-inline:end:video-process:LA-video-annotation-owner:0:authored:migration-e3b1864c01851463-0 --></ins>

<a id="process-model"></a>

## Processing model and shared contracts

<ins><!-- d3d12-review-inline:begin:video-process:N-route:0:authored:migration-c9bcd15f4a5f0f7d-0 -->The compact route is [capabilities](#process-discovery),
[processor creation and reflection](#process-objects), and
[recording](#process-recording). The subordinate
[stream types](#process-stream-types), [capability values](#process-capability-types)
and [driver reference](#process-driver) provide the operative details.<!-- d3d12-review-inline:end:video-process:N-route:0:authored:migration-c9bcd15f4a5f0f7d-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-process:N-route:1:authored:migration-81a85fcaded2dcb6-0 -->The shared [format](video-decode.md#d3d12-video-format),
[sample](video-decode.md#d3d12-video-sample),
[size range](video-decode.md#d3d12-video-size-range),
[scale support](video-decode.md#d3d12-video-scale-support) and
[scale flags](video-decode.md#d3d12-video-scale-support-flags) retain their
canonical definitions. Processing uses these types without changing their
layout.<!-- d3d12-review-inline:end:video-process:N-route:1:authored:migration-81a85fcaded2dcb6-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-process:N-route:2:authored:migration-3146418e9760fe45-0 -->[CPU threading](execution.md#threading),
[submission threading](execution.md#submission-threading),
[queue types](execution.md#command-list-types),
[submission and ordering](execution.md#submission), and
[recording storage](execution.md#command-storage) retain their shared owners.
Processing uses a command list and allocator of type
`D3D12_COMMAND_LIST_TYPE_VIDEO_PROCESS`, submitted to a queue of that type.
Recording and submission must use compatible device/node associations for
the processor, list, allocator, queue and picture resource objects.
The [creation rules](execution.md#creation) require matching allocator/list
types, and [submission validation](execution.md#validation) requires matching
queue/list types and compatible node masks.<!-- d3d12-review-inline:end:video-process:N-route:2:authored:migration-3146418e9760fe45-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-process:N-route:3:authored:migration-83b9de45b66c0c81-0 -->[Object/resource lifetime](execution.md#lifetime),
[completion and lifetime](execution.md#completion-lifetime), and the
[video resource contract](video.md#video-resource-contract) own lifetime,
completion and residency. The processor is an
`ID3D12Pageable` object, not image storage or a graphics pipeline state object.
The application must keep its processor, current/reference inputs and output
resources alive for every recorded use that will execute,
including uses in unsubmitted recordings, and until the corresponding GPU
uses finish. Residency for GPU use follows the video resource contract.
CPU argument structures and arrays are recording inputs. The
[nested CPU pointer qualification](#process-argument-rules) addresses their
unresolved retention and null-array behavior.<!-- d3d12-review-inline:end:video-process:N-route:3:authored:migration-83b9de45b66c0c81-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-process:N-route:4:authored:migration-108a47f130dea34e-0 -->Processing reads current and reference pictures and writes output pictures.
The corresponding legacy states are `D3D12_RESOURCE_STATE_VIDEO_PROCESS_READ`
and `D3D12_RESOURCE_STATE_VIDEO_PROCESS_WRITE`; enhanced access/layout rules
are defined by [video process barriers](synchronization.md#process-enhanced-barrier),
and [legacy process barriers](synchronization.md#process-resource-barrier)
retain their full declaring owner. There is no implicit transition, fence wait,
graphics binding or application picture resource allocation in `ProcessFrames`/`ProcessFrames1`.
Ordering with decode, graphics, compute or another queue follows the shared
submission and synchronization contracts.<!-- d3d12-review-inline:end:video-process:N-route:4:authored:migration-108a47f130dea34e-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-process:N-route:5:authored:migration-5a95f5fe1ba0f959-0 -->[Predication](counters-queries-and-predication.md#videoprocess-setpredication)
and [its operation matrix](counters-queries-and-predication.md#predication-operation-matrix)
own conditional processing. [Process queries](counters-queries-and-predication.md#videoprocess-beginquery)
and [resolution](counters-queries-and-predication.md#videoprocess-resolvequerydata)
retain their declarations and query lifecycle. They are not processor
capability queries.<!-- d3d12-review-inline:end:video-process:N-route:5:authored:migration-5a95f5fe1ba0f959-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-process:D162-reference-only-dpb-processing-forward:0:authored:migration-6331d25699e9e27f-0 -->Encoding's lower-resolution frame analysis route contributes the [reference-only DPB scaling contract](video-encoding-controls.md#source-s08-032): the DPB_ENCODER_RESOURCES scale capability, one reference-only input, matched dimension/mip/format/reference-only flags, full-surface requirements, disabled transforms and processor description restrictions. Its rectangle qualification remains explicit. Ordinary readable reconstructed textures retain the ordinary processing path. The scale flag's [shared declaration](video-decode.md#d3d12-video-scale-support-flags) remains canonical.<!-- d3d12-review-inline:end:video-process:D162-reference-only-dpb-processing-forward:0:authored:migration-6331d25699e9e27f-0 --></ins>

<a id="process-discovery"></a>

## Capability queries

<ins><!-- d3d12-review-inline:begin:video-process:N-query-protocol:0:authored:migration-4192c9f0f19ff45b-0 -->The full declaring entry for
[`ID3D12VideoDevice::CheckFeatureSupport`](video-decode.md#video-check-feature-support)
owns the common protocol and return values. For each processing case below,
`FeatureSupportDataSize` must equal `sizeof` the named payload. Initialize its
input fields before the call. Inspect output fields only on success.
`NodeIndex` is a zero-based node index, whereas the processor size query and
creation take a `NodeMask`. A successful query does not itself mean that the
requested processing operation is supported.<!-- d3d12-review-inline:end:video-process:N-query-protocol:0:authored:migration-4192c9f0f19ff45b-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-process:N-query-protocol:1:authored:migration-e172608621f040c0-0 -->These are fixed payloads, not capacity/MORE_DATA enumerations.
`FilterRangeSupport` is an embedded 32-element array in PROCESS_SUPPORT,
not a caller-allocated pointer. PROCESS_REFERENCE_INFO returns scalar counts;
PROCESS_MAX_INPUT_STREAMS returns a scalar limit. PROCESSOR_SIZE takes an
input array of exactly `NumInputStreamDescs` descriptions and reports
allocation sizes. It does not allocate or return stream descriptions.<!-- d3d12-review-inline:end:video-process:N-query-protocol:1:authored:migration-e172608621f040c0-0 --></ins>

<!-- d3d12-review-alert:begin:video-process:N-query-table:0:authored:migration-4f285398b46bb8ad-0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | `D3D12_FEATURE_VIDEO` case | Value | Payload | Inputs | Outputs |
> |---|---|---|---|---|
> | `D3D12_FEATURE_VIDEO_PROCESS_SUPPORT` | 5 | [`D3D12_FEATURE_DATA_VIDEO_PROCESS_SUPPORT`](#d3d12-feature-data-video-process-support) | `NodeIndex`, `InputSample`, `InputFieldType`, `InputStereoFormat`, `InputFrameRate`, `OutputFormat`, `OutputStereoFormat`, `OutputFrameRate` | `SupportFlags`, `ScaleSupport`, `FeatureSupport`, `DeinterlaceSupport`, `AutoProcessingSupport`, `FilterSupport`, `FilterRangeSupport[32]` |
> | `D3D12_FEATURE_VIDEO_PROCESS_MAX_INPUT_STREAMS` | 6 | [`D3D12_FEATURE_DATA_VIDEO_PROCESS_MAX_INPUT_STREAMS`](#d3d12-feature-data-video-process-max-input-streams) | `NodeIndex` | `MaxInputStreams` |
> | `D3D12_FEATURE_VIDEO_PROCESS_REFERENCE_INFO` | 7 | [`D3D12_FEATURE_DATA_VIDEO_PROCESS_REFERENCE_INFO`](#d3d12-feature-data-video-process-reference-info) | `NodeIndex`, `DeinterlaceMode`, `Filters`, `FeatureSupport`, `InputFrameRate`, `OutputFrameRate`, `EnableAutoProcessing` | `PastFrames`, `FutureFrames` |
> | `D3D12_FEATURE_VIDEO_PROCESSOR_SIZE` | 9 | [`D3D12_FEATURE_DATA_VIDEO_PROCESSOR_SIZE`](#d3d12-feature-data-video-processor-size) | `NodeMask`, `pOutputStreamDesc`, `NumInputStreamDescs`, `pInputStreamDescs` | `MemoryPoolL0Size`, `MemoryPoolL1Size` |

<!-- d3d12-review-alert:end:video-process:N-query-table:0:authored:migration-4f285398b46bb8ad-0 -->

<ins><!-- d3d12-review-inline:begin:video-process:N-query-tuple:0:authored:migration-e0afe79f6d4d8cdd-0 -->PROCESS_SUPPORT describes the actual input sample (including width, height,
DXGI format and color space), input field/stereo mode and input rate, together
with output format/color space, stereo mode and output rate. The
`SUPPORTED` bit establishes support for that conversion tuple. The remaining
outputs describe scaling and supported processing options for that tuple.
`ScaleSupport.OutputSizeRange` and its flags constrain output sizes; supported
filter bits and `FilterRangeSupport` constrain enabled filters and their levels.
PROCESS_MAX_INPUT_STREAMS is the node's simultaneous enabled-stream limit,
not a guarantee that every tuple or multi-stream feature combination works.
PROCESS_REFERENCE_INFO describes the selected deinterlace, filters, features,
rates and automatic-processing choice. Its counts determine the processor's
past/future reference requirements.<!-- d3d12-review-inline:end:video-process:N-query-tuple:0:authored:migration-e0afe79f6d4d8cdd-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-process:N-query-tuple:1:authored:migration-db7b46a87cefd5f0-0 -->**Scoped runtime validation:** the inspected ordinary query path rejects an
invalid node index or malformed input with `E_INVALIDARG`. An unsupported
input/output format can instead complete with `S_OK` and no `SUPPORTED` bit.
Creation validates each stream's conversion/scaling tuple and requested
features and reference counts. These checks do not prove an adapter's
algorithms, support for an arbitrary combination of features, or a reservation
of resources after a successful query.<!-- d3d12-review-inline:end:video-process:N-query-tuple:1:authored:migration-db7b46a87cefd5f0-0 --></ins>

<a id="process-objects"></a>

## Processor creation and immutable reflection

<a id="create-video-processor"></a>

### ID3D12VideoDevice::CreateVideoProcessor

#### Declaration

```cpp
HRESULT CreateVideoProcessor(
  UINT                                         NodeMask,
  const D3D12_VIDEO_PROCESS_OUTPUT_STREAM_DESC *pOutputStreamDesc,
  UINT                                         NumInputStreamDescs,
  const D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC  *pInputStreamDescs,
  REFIID                                       riid,
  void                                         **ppVideoProcessor
);
```

#### Behavior

Creates a video processor instance.

#### Parameters

`NodeMask`

The node mask specifying the physical adapter on which the video processor will be used. For single GPU operation, set this to zero. If there are multiple GPU nodes, set a bit to identify the node, i.e. the device's physical adapter, <ins><!-- d3d12-review-inline:begin:video-process:P-create-processor-parameters:1:modified:source-2538d79c459cef5a-0-0 -->on which the video processor will be used<!-- d3d12-review-inline:end:video-process:P-create-processor-parameters:1:modified:source-2538d79c459cef5a-0-0 --></ins>. Each bit in the mask corresponds to a single node. Only 1 bit may be set.

`pOutputStreamDesc`

<ins><!-- d3d12-review-inline:begin:video-process:P-create-processor-parameters:3 -->A pointer to a [D3D12_VIDEO_PROCESS_OUTPUT_STREAM_DESC](#d3d12-video-process-output-stream-desc) structure describing the output stream.<!-- d3d12-review-inline:end:video-process:P-create-processor-parameters:3 --></ins>

`NumInputStreamDescs`

The number of input streams provided in the *pInputStreamDescs* parameter.

`pInputStreamDescs`

<ins><!-- d3d12-review-inline:begin:video-process:P-create-processor-parameters:7 -->A pointer to a list of [D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC](#d3d12-video-process-input-stream-desc) structures describing the input streams. The number of structures provided should match the value specified in the *NumInputStreamDescs* parameter.<!-- d3d12-review-inline:end:video-process:P-create-processor-parameters:7 --></ins>

`riid`

The globally unique identifier (GUID) for the video processor interface.

`ppVideoProcessor`

<ins><!-- d3d12-review-inline:begin:video-process:P-create-processor-parameters:11 -->A pointer to a memory block that receives a pointer to the [ID3D12VideoProcessor](#process-objects) interface.<!-- d3d12-review-inline:end:video-process:P-create-processor-parameters:11 --></ins>

#### Return values

This method returns HRESULT.

#### Remarks

To change the parameters set during creation, you must recreate the video processor object.

<ins><!-- d3d12-review-inline:begin:video-process:N-creation-validation:0:authored:migration-dcf2f398041fcc23-0 -->The application must provide at least one input stream description and no more
simultaneously enabled streams than the node's reported limit. The creation
descriptions fix formats/color spaces, rates, size ranges, stereo, deinterlace,
filter, orientation, blending, luma key and automatic-processing choices.
The input/reference and output resources are supplied later, not allocated
by this call. The runtime copies the creation descriptions. Their caller-owned
storage is not retained as mutable processor state.<!-- d3d12-review-inline:end:video-process:N-creation-validation:0:authored:migration-dcf2f398041fcc23-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-process:N-creation-validation:1:authored:migration-ab4a9e1f2d6ec5b8-0 -->On successful creation, `ppVideoProcessor` receives a caller-owned COM interface
reference. The caller releases that reference under the normal
[reference counting and recorded use lifetime rules](execution.md#lifetime).
The application must preserve the processor and referenced resources for
unsubmitted recordings that will execute and for outstanding GPU uses. This
does not assume that recording automatically takes a COM reference on its behalf.<!-- d3d12-review-inline:end:video-process:N-creation-validation:1:authored:migration-ab4a9e1f2d6ec5b8-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-process:N-creation-validation:2:authored:migration-d2c3e19059af4175-0 -->**Scoped runtime validation:** invalid node selection, zero input streams,
invalid size ranges, a failed/unsupported conversion query, unsupported
requested options or mismatched required reference counts are rejected with
`E_INVALIDARG` on the inspected ordinary creation path. Interface selection,
allocation and device removal failures can propagate. The short public method
page does not supply an exhaustive HRESULT catalog.<!-- d3d12-review-inline:end:video-process:N-creation-validation:2:authored:migration-d2c3e19059af4175-0 --></ins>

<a id="protected-video-api-contracts"></a>

<a id="protected-session-video-api-contracts"></a>

<a id="api-id3d12videodevice2-createvideoprocessor1"></a>

### ID3D12VideoDevice2::CreateVideoProcessor1

#### Declaration

```cpp
HRESULT CreateVideoProcessor1(
    UINT NodeMask,
    const D3D12_VIDEO_PROCESS_OUTPUT_STREAM_DESC* pOutputStreamDesc,
    UINT NumInputStreamDescs,
    const D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC *pInputStreamDescs,
    ID3D12ProtectedResourceSession *pProtectedResourceSession,
    REFIID riid,
    void **ppVideoProcessor);
```

#### Behavior

Creates a video processor instance with support for protected resources.

<ins><!-- d3d12-review-inline:begin:video-process:AB-id3d12videodevice2-createvideoprocessor1-contract:0:authored:migration-f2d2319fefeceab9-0 -->Retains the [processor's immutable stream description contract](#create-video-processor)
and adds the protected session association. Null creates an unprotected
processor. A non-null session requires compatible device/node/type and
protected processing support. Recreate the processor to change its immutable
creation descriptions. The association is not a per-frame setter.<!-- d3d12-review-inline:end:video-process:AB-id3d12videodevice2-createvideoprocessor1-contract:0:authored:migration-f2d2319fefeceab9-0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:video-process:AB-id3d12videodevice2-createvideoprocessor1-contract:2:authored:migration-0ca72eb524d52a4c-0 -->NodeMask selects one applicable node. pOutputStreamDesc describes output, NumInputStreamDescs counts the pInputStreamDescs array, and pProtectedResourceSession is optional. riid/ppVideoProcessor request and receive the processor interface.<!-- d3d12-review-inline:end:video-process:AB-id3d12videodevice2-createvideoprocessor1-contract:2:authored:migration-0ca72eb524d52a4c-0 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:video-process:AB-id3d12videodevice2-createvideoprocessor1-contract:4:authored:migration-b33c4526090579e7-0 -->Returns the creation/interface HRESULT. Existing processing tuple, allocation and numerical/hardware qualifications remain; no GPU completion is implied.<!-- d3d12-review-inline:end:video-process:AB-id3d12videodevice2-createvideoprocessor1-contract:4:authored:migration-b33c4526090579e7-0 --></ins>

<a id="video-processor-get-node-mask"></a>

### ID3D12VideoProcessor::GetNodeMask

#### Declaration

```cpp
UINT GetNodeMask();
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:video-process:P-get-node-mask-summary:0:modified:source-7a82d3d6a7f7d1bb-0-0 -->Gets the<!-- d3d12-review-inline:end:video-process:P-get-node-mask-summary:0:modified:source-7a82d3d6a7f7d1bb-0-0 --></ins> node mask specifying the physical adapter on which the video processor will be used.

#### Return values

This method returns a UINT.

<a id="video-processor-get-num-input-stream-descs"></a>

### ID3D12VideoProcessor::GetNumInputStreamDescs

#### Declaration

```cpp
UINT GetNumInputStreamDescs();
```

#### Behavior

Gets the number of input stream descriptions provided when the video processor was created with a call to [ID3D12VideoDevice::CreateVideoProcessor](#create-video-processor).

#### Return values

This method returns UINT. Use this value to determine the correct size of the array you pass in the *pInputStreamDescs* parameter to [ID3D12VideoProcessor::GetInputStreamDescs](#video-processor-get-input-stream-descs).

<a id="video-processor-get-input-stream-descs"></a>

### ID3D12VideoProcessor::GetInputStreamDescs

#### Declaration

```cpp
HRESULT GetInputStreamDescs(
  UINT                                  NumInputStreamDescs,
  D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC *pInputStreamDescs
);
```

#### Behavior

Gets the input stream descriptions provided when the video processor was created with a call to [ID3D12VideoDevice::CreateVideoProcessor](#create-video-processor).

#### Parameters

`NumInputStreamDescs`

The size of the array pointed to by *pInputStreamDescs*. Get the number of input stream descriptions associated with the video processor by calling <ins><!-- d3d12-review-inline:begin:video-process:P-get-input-stream-descs-parameters:1 -->[ID3D12VideoProcessor::GetNumInputStreamDescs](#video-processor-get-num-input-stream-descs)<!-- d3d12-review-inline:end:video-process:P-get-input-stream-descs-parameters:1 --></ins>.

`pInputStreamDescs`

An array of [D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC](#d3d12-video-process-input-stream-desc) structures that is populated with the input stream descriptions associated with the video processor.

#### Return values

This method returns HRESULT.

#### Reflection contract

<ins><!-- d3d12-review-inline:begin:video-process:N-reflection-count:0:authored:migration-541cbf83912d3050-0 -->`NumInputStreamDescs` must equal the value returned by
`GetNumInputStreamDescs`, and `pInputStreamDescs` must address that many writable
descriptions. The inspected reflection path returns `E_INVALIDARG` for a mismatched
count or null output pointer, otherwise `S_OK`. It returns copied creation
descriptions; modifying the copies does not reconfigure the processor.<!-- d3d12-review-inline:end:video-process:N-reflection-count:0:authored:migration-541cbf83912d3050-0 --></ins>

<a id="video-processor-get-output-stream-desc"></a>

### ID3D12VideoProcessor::GetOutputStreamDesc

#### Declaration

```cpp
D3D12_VIDEO_PROCESS_OUTPUT_STREAM_DESC GetOutputStreamDesc();
```

#### Behavior

Gets the output stream description provided when the video processor was created with a call to [ID3D12VideoDevice::CreateVideoProcessor](#create-video-processor).

#### Return values

This method returns [D3D12_VIDEO_PROCESS_OUTPUT_STREAM_DESC](#d3d12-video-process-output-stream-desc).

#### Reflection contract

<ins><!-- d3d12-review-inline:begin:video-process:N-reflection-ownership:0:authored:migration-669c622f20b3db5e-0 -->The returned output description is a value copy of the creation description.
`GetNodeMask` returns the creation node selection; `GetNumInputStreamDescs`
returns the immutable number of creation descriptions. None of these methods
records GPU work or reports mutable per-call picture arguments.<!-- d3d12-review-inline:end:video-process:N-reflection-ownership:0:authored:migration-669c622f20b3db5e-0 --></ins>

<a id="api-id3d12videoprocessor1-getprotectedresourcesession"></a>

### ID3D12VideoProcessor1::GetProtectedResourceSession

#### Declaration

```cpp
HRESULT GetProtectedResourceSession(
    REFIID riid,
    void** ppProtectedSession);
```

#### Behavior

Gets the [ID3D12ProtectedResourceSession](resources.md#protected-resource-sessions) that was passed into [ID3D12VideoDevice2::CreateVideoProcessor1](#api-id3d12videodevice2-createvideoprocessor1) when the [ID3D12VideoProcessor1](#protected-video-api-contracts) was created.

<ins><!-- d3d12-review-inline:begin:video-process:AB-id3d12videoprocessor1-getprotectedresourcesession-contract:0:authored:migration-3882a3011e685de2-0 -->Retrieves the session associated with this object's creation, not the current
command list session. Association does not change when a command list selects
a different protection context.<!-- d3d12-review-inline:end:video-process:AB-id3d12videoprocessor1-getprotectedresourcesession-contract:0:authored:migration-3882a3011e685de2-0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:video-process:AB-id3d12videoprocessor1-getprotectedresourcesession-contract:2:authored:migration-8bd70e5deebd23e7-0 -->`riid` selects an interface on the associated protected resource session.
`ppProtectedSession` receives that interface with a caller-owned COM reference.<!-- d3d12-review-inline:end:video-process:AB-id3d12videoprocessor1-getprotectedresourcesession-contract:2:authored:migration-8bd70e5deebd23e7-0 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:video-process:AB-id3d12videoprocessor1-getprotectedresourcesession-contract:4:authored:migration-9a454cb07437c167-0 -->Returns the interface query's HRESULT. With no associated session it returns
`DXGI_ERROR_NOT_FOUND` and a null output. An unsupported requested interface
returns `E_NOINTERFACE`. Retrieval does not create or signal a session.<!-- d3d12-review-inline:end:video-process:AB-id3d12videoprocessor1-getprotectedresourcesession-contract:4:authored:migration-9a454cb07437c167-0 --></ins>

<a id="process-recording"></a>

## Recording lifecycle and processing calls

<ins><!-- d3d12-review-inline:begin:video-process:N-recording:0:authored:migration-bdf906ee2320ed00-0 -->`ID3D12VideoProcessCommandList` records video process work. Its version-1
interface adds `ProcessFrames1`. `Reset` selects a compatible process allocator
and opens a new recording. `ClearState` changes state within the recording, without reclaiming
allocator storage or submitting work. Neither method takes a graphics PSO.
Both reset predication to disabled (null buffer, zero offset,
`D3D12_PREDICATION_OP_EQUAL_ZERO`).<!-- d3d12-review-inline:end:video-process:N-recording:0:authored:migration-bdf906ee2320ed00-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-process:N-recording:1:authored:migration-84fbe69c38d7f57b-0 -->The shared [recording boundaries](command-list-state.md#recording-boundaries),
[allocator storage](execution.md#command-storage) and
[threading rules](execution.md#threading) remain applicable.
Closing is not GPU completion. The runtime close wrapper can perform queued
query resolution work before reaching the close DDI. It is not merely a
direct driver call.<!-- d3d12-review-inline:end:video-process:N-recording:1:authored:migration-84fbe69c38d7f57b-0 --></ins>

<a id="process-clear-state"></a>

### ID3D12VideoProcessCommandList::ClearState

#### Declaration

```cpp
void ClearState();
```

#### Behavior

Resets the state of a <ins><!-- d3d12-review-inline:begin:video-process:P-clear-summary:0:modified:source-30b405a035a90708-0-0 -->video process<!-- d3d12-review-inline:end:video-process:P-clear-summary:0:modified:source-30b405a035a90708-0-0 --></ins> command list back to the state it was in when the command list was created.

#### Return values

None

<a id="process-close"></a>

### ID3D12VideoProcessCommandList::Close

#### Declaration

```cpp
HRESULT Close();
```

#### Behavior

Indicates that recording to the command list has finished.

#### Return values

Type: **[HRESULT](devices-and-capabilities.md#api-result-codes)**

Returns **S\_OK** if successful; otherwise, returns one of the following values:

- **E\_FAIL** if the command list has already been closed, or an invalid API was called during command list recording.
- **E\_OUTOFMEMORY** if the operating system ran out of memory during recording.
- **E\_INVALIDARG** if an invalid argument was passed to the command list API during recording.

See [Direct3D 12 Return Codes](devices-and-capabilities.md#api-result-codes) for other possible return values.

#### Remarks

The runtime will validate that the command list has not previously been closed. If an error was encountered during recording, the error code is returned here. The runtime won't call the close device driver interface (DDI) in this case.

<a id="process-reset"></a>

### ID3D12VideoProcessCommandList::Reset

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

A pointer to the [ID3D12CommandAllocator](execution.md#command-storage) object that the device creates command lists from.

#### Return values

Type: **[HRESULT](devices-and-capabilities.md#api-result-codes)**

Returns **S\_OK** if successful; otherwise, returns one of the following values:

- **E\_FAIL** if the command list was not in the "closed" state when the **Reset** call was made, or the per-device limit would have been exceeded.
- **E\_OUTOFMEMORY** if the operating system ran out of memory.
- **E\_INVALIDARG** if the allocator is currently being used with another command list in the "recording" state or if the specified allocator was created with the wrong type.

See [Direct3D 12 Return Codes](devices-and-capabilities.md#api-result-codes) for other possible return values.

<a id="api-id3d12videoprocesscommandlist2-setprotectedresourcesession"></a>

### ID3D12VideoProcessCommandList2::SetProtectedResourceSession

#### Declaration

```cpp
void SetProtectedResourceSession(
    ID3D12ProtectedResourceSession *pProtectedResourceSession);
```

#### Behavior

Specifies whether or not protected resources can be accessed by subsequent commands in the video process command list. By default, no protected resources are enabled. After calling **SetProtectedResourceSession** with a valid session, protected resources of the same type can refer to that session. After calling **SetProtectedResourceSession** with **NULL**, no protected resources can be accessed.

<ins><!-- d3d12-review-inline:begin:video-process:AB-id3d12videoprocesscommandlist2-setprotectedresourcesession-contract:0:authored:migration-b486de2c6a7588d8-0 -->Selects only the supported command list's protection context. Ordinary
bindings are preserved (D272). This is not ClearState. Null disables protected
access. [Session/device/node/type and operation support](video.md#protected-video-support),
the [canonical selection and open-query rules](command-list-state.md#protection)
and [protected operation predication](counters-queries-and-predication.md#predication-operation-matrix)
remain required.<!-- d3d12-review-inline:end:video-process:AB-id3d12videoprocesscommandlist2-setprotectedresourcesession-contract:0:authored:migration-b486de2c6a7588d8-0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:video-process:AB-id3d12videoprocesscommandlist2-setprotectedresourcesession-contract:2:authored:migration-a8601bf2fe89bed0-0 -->`pProtectedResourceSession` is the optional translated session association. It is not a video encoder/decoder object and its selection does not allocate one.<!-- d3d12-review-inline:end:video-process:AB-id3d12videoprocesscommandlist2-setprotectedresourcesession-contract:2:authored:migration-a8601bf2fe89bed0-0 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:video-process:AB-id3d12videoprocesscommandlist2-setprotectedresourcesession-contract:4:authored:migration-a4feab9e4f4c45e5-0 -->Returns no value. Recording/list errors remain distinct from content validity and GPU completion.<!-- d3d12-review-inline:end:video-process:AB-id3d12videoprocesscommandlist2-setprotectedresourcesession-contract:4:authored:migration-a4feab9e4f4c45e5-0 --></ins>
<a id="process-frames"></a>

### ID3D12VideoProcessCommandList::ProcessFrames

#### Declaration

```cpp
void ProcessFrames(
  ID3D12VideoProcessor                              *pVideoProcessor,
  const D3D12_VIDEO_PROCESS_OUTPUT_STREAM_ARGUMENTS *pOutputArguments,
  UINT                                              NumInputStreams,
  const D3D12_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS  *pInputArguments
);
```

#### Behavior

Records a video processing operation to the command list, operating on one or more input samples and writing the result to an output surface.

<ins><!-- d3d12-review-inline:begin:video-process:N-process-forward:0:authored:migration-ff7cbe5647d14044-0 -->The [shared processing argument rules](#process-argument-rules) specify
stream correspondence, resource roles, field type versioning and validation
for both processing calls.<!-- d3d12-review-inline:end:video-process:N-process-forward:0:authored:migration-ff7cbe5647d14044-0 --></ins>

#### Parameters

`pVideoProcessor`

A pointer to an [ID3D12VideoProcessor](#process-objects) interface representing a video processor instance.

`pOutputArguments`

A [D3D12_VIDEO_PROCESS_OUTPUT_STREAM_ARGUMENTS](#d3d12-video-process-output-stream-arguments) structure specifying the output surface and output arguments.

`NumInputStreams`

The count of input streams.

`pInputArguments`

A pointer to an array of [D3D12_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS](#d3d12-video-process-input-stream-arguments) structures specifying the input parameters.

#### Return values

None

<a id="process-frames1"></a>

### ID3D12VideoProcessCommandList1::ProcessFrames1

#### Declaration

```cpp
void ProcessFrames1(
  ID3D12VideoProcessor                              *pVideoProcessor,
  const D3D12_VIDEO_PROCESS_OUTPUT_STREAM_ARGUMENTS *pOutputArguments,
  UINT                                              NumInputStreams,
  const D3D12_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS1 *pInputArguments
);
```

#### Behavior

Records a video processing operation to the command list, operating on one or more input samples and writing the result to an output surface. This version of the method supports changing the [D3D12_VIDEO_FIELD_TYPE](#d3d12-video-field-type) for each call, unlike [ID3D12VideoProcessCommandList::ProcessFrames](#process-frames).

#### Parameters

`pVideoProcessor`

A pointer to an [ID3D12VideoProcessor](#process-objects) interface representing a video processor instance.

`pOutputArguments`

A [D3D12_VIDEO_PROCESS_OUTPUT_STREAM_ARGUMENTS](#d3d12-video-process-output-stream-arguments) structure specifying the output surface and output arguments.

`NumInputStreams`

The count of input streams.

`pInputArguments`

A pointer to an array of [D3D12_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS1](#d3d12-video-process-input-stream-arguments1) structures specifying the input parameters.

#### Return values

None

<a id="process-argument-rules"></a>

### Shared processing argument rules

<ins><!-- d3d12-review-inline:begin:video-process:N-call-contract:0:authored:migration-18b1e28eed2fbec5-0 -->`pVideoProcessor` supplies the immutable configuration.
`NumInputStreams` must match its number of input stream descriptions;
`pInputArguments[i]` corresponds to creation description `i`.
`pOutputArguments` describes the output views and target rectangle.
The current inputs and temporal references are Texture2D surfaces with
subresources, not descriptor table bindings. Their formats must match the
corresponding processor descriptions.<!-- d3d12-review-inline:end:video-process:N-call-contract:0:authored:migration-18b1e28eed2fbec5-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-process:N-call-contract:1:authored:migration-4183ebb01566d73b-0 -->`ProcessFrames` uses each creation description's `FieldType`.
`ProcessFrames1` uses the `FieldType` in each
`D3D12_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS1` for that call. This permits mixed
progressive/interlaced content without recreating the processor merely to
change field type. It does not remove capability requirements for the actual
field type and processing tuple.<!-- d3d12-review-inline:end:video-process:N-call-contract:1:authored:migration-4183ebb01566d73b-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-process:N-call-contract:2:authored:migration-c0e671d3b65a0130-0 -->**Scoped validation:** the inspected path checks stream count equality,
current/reference/output Texture2D dimensions and formats, subresource bounds,
single mip level and plane-zero selection of planar pictures. It rejects
reserved pictures and applies the shared video architecture/heap restrictions.
The path checks nonnegative, non-inverted rectangles, configured source and
nonempty destination size ranges, enabled orientation/blending, and known
input flags. These observations are not an exhaustive error table or a
hardware layout guarantee. A missing retail check is not permission.
The void recording methods report recording failure through command list
error handling and `Close`, not a per-frame HRESULT.<!-- d3d12-review-inline:end:video-process:N-call-contract:2:authored:migration-c0e671d3b65a0130-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-process:N-call-contract:3:authored:migration-136f732ed0d47197-0 -->**Nested CPU pointer qualification:** the retained public reference-set contract
allows null subresource arrays to mean subresource zero. The inspected
validation path directly indexes these arrays, while recording forwards some
subresource pointers to the driver. This draft retains the published default
but does not claim that every implementation honors it, or establish a
universal post-call release point for every nested CPU array. Resource/object
lifetime through GPU completion is a separate shared contract.<!-- d3d12-review-inline:end:video-process:N-call-contract:3:authored:migration-136f732ed0d47197-0 --></ins>

<a id="process-query-payloads"></a>

## Processing query payload reference

<a id="d3d12-feature-data-video-process-support"></a>

### D3D12_FEATURE_DATA_VIDEO_PROCESS_SUPPORT

Provides data for calls to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) when the feature specified is [D3D12_FEATURE_VIDEO_PROCESS_SUPPORT](#d3d12-feature-data-video-process-support).

```cpp
typedef struct D3D12_FEATURE_DATA_VIDEO_PROCESS_SUPPORT
{
    UINT NodeIndex;                                                                         // input
    D3D12_VIDEO_SAMPLE InputSample;                                                         // input
    D3D12_VIDEO_FIELD_TYPE InputFieldType;                                                  // input
    D3D12_VIDEO_FRAME_STEREO_FORMAT InputStereoFormat;                                      // input
    DXGI_RATIONAL InputFrameRate;                                                           // input
    D3D12_VIDEO_FORMAT OutputFormat;                                                        // input
    D3D12_VIDEO_FRAME_STEREO_FORMAT OutputStereoFormat;                                     // input
    DXGI_RATIONAL OutputFrameRate;                                                          // input
    D3D12_VIDEO_PROCESS_SUPPORT_FLAGS SupportFlags;                                         // output
    D3D12_VIDEO_SCALE_SUPPORT ScaleSupport;                                                 // output
    D3D12_VIDEO_PROCESS_FEATURE_FLAGS FeatureSupport;                                       // output
    D3D12_VIDEO_PROCESS_DEINTERLACE_FLAGS DeinterlaceSupport;                               // output
    D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAGS AutoProcessingSupport;                        // output
    D3D12_VIDEO_PROCESS_FILTER_FLAGS FilterSupport;                                         // output
    D3D12_VIDEO_PROCESS_FILTER_RANGE FilterRangeSupport[D3D12_VIDEO_PROCESS_MAX_FILTERS];   // output
} D3D12_FEATURE_DATA_VIDEO_PROCESS_SUPPORT;
```

#### Members

`NodeIndex`

An integer indicating which physical adapter of the device the operation applies to, in a multi-adapter operation.

`InputSample`

A [D3D12_VIDEO_SAMPLE](video-decode.md#d3d12-video-sample) structure defining the width, height, and format of the input sample.

`InputFieldType`

A member of the [D3D12_VIDEO_FIELD_TYPE](#d3d12-video-field-type) enumeration specifying the interlaced field type of the input sample.

`InputStereoFormat`

A member of the [D3D12_VIDEO_FRAME_STEREO_FORMAT](#d3d12-video-frame-stereo-format) enumeration specifying the stereo format of the input sample.

`InputFrameRate`

The input frame rate.

`OutputFormat`

A [D3D12_VIDEO_FORMAT](video-decode.md#d3d12-video-format) structure specifying the output DXGI format and color space.

`OutputStereoFormat`

A member of the [D3D12_VIDEO_FRAME_STEREO_FORMAT](#d3d12-video-frame-stereo-format) enumeration specifying the stereo format of the output.

`OutputFrameRate`

The output frame rate.

`SupportFlags`

A member of the [D3D12_VIDEO_PROCESS_SUPPORT_FLAGS](#d3d12-video-process-support-flags) indicating whether the requested format and colorspace conversion is supported. This value is populated by the call to <ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_feature_data_video_process_support-members:17 -->**ID3D12VideoDevice::CheckFeatureSupport**<!-- d3d12-review-inline:end:video-process:P-d3d12_feature_data_video_process_support-members:17 --></ins>.

`ScaleSupport`

A [D3D12_VIDEO_SCALE_SUPPORT](video-decode.md#d3d12-video-scale-support) structure specifying the supported scaling capabilities. This value is populated by the call to <ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_feature_data_video_process_support-members:19 -->**ID3D12VideoDevice::CheckFeatureSupport**<!-- d3d12-review-inline:end:video-process:P-d3d12_feature_data_video_process_support-members:19 --></ins>.

`FeatureSupport`

A bitwise OR combination of values from the [D3D12_VIDEO_PROCESS_FEATURE_FLAGS](#d3d12-video-process-feature-flags) enumeration specifying the supported video processing features. This value is populated by the call to <ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_feature_data_video_process_support-members:21 -->**ID3D12VideoDevice::CheckFeatureSupport**<!-- d3d12-review-inline:end:video-process:P-d3d12_feature_data_video_process_support-members:21 --></ins>.

`DeinterlaceSupport`

A member of the [D3D12_VIDEO_PROCESS_DEINTERLACE_FLAGS](#d3d12-video-process-deinterlace-flags) enumeration specifying the supported deinterlacing capabilities. This value is populated by the call to <ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_feature_data_video_process_support-members:23 -->**ID3D12VideoDevice::CheckFeatureSupport**<!-- d3d12-review-inline:end:video-process:P-d3d12_feature_data_video_process_support-members:23 --></ins>.

`AutoProcessingSupport`

A member of the [D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAGS](#d3d12-video-process-auto-processing-flags) specifying the supported automatic processing capabilities. This value is populated by the call to <ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_feature_data_video_process_support-members:25 -->**ID3D12VideoDevice::CheckFeatureSupport**<!-- d3d12-review-inline:end:video-process:P-d3d12_feature_data_video_process_support-members:25 --></ins>.

`FilterSupport`

A bitwise OR combination of values from the [D3D12_VIDEO_PROCESS_FILTER_FLAGS](#d3d12-video-process-filter-flags) enumeration specifying the supported video filtering features. This value is populated by the call to <ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_feature_data_video_process_support-members:27 -->**ID3D12VideoDevice::CheckFeatureSupport**<!-- d3d12-review-inline:end:video-process:P-d3d12_feature_data_video_process_support-members:27 --></ins>.

`FilterRangeSupport[32]`

An array of [D3D12_VIDEO_PROCESS_FILTER_RANGE](#d3d12-video-process-filter-range) structures representing the filter range values. This value is populated by the call to <ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_feature_data_video_process_support-members:29 -->**ID3D12VideoDevice::CheckFeatureSupport**<!-- d3d12-review-inline:end:video-process:P-d3d12_feature_data_video_process_support-members:29 --></ins>.<ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_feature_data_video_process_support-members:29 --> The filter range list is embedded in this structure.<!-- d3d12-review-inline:end:video-process:P-d3d12_feature_data_video_process_support-members:29 --></ins>

<a id="d3d12-feature-data-video-process-max-input-streams"></a>

### D3D12_FEATURE_DATA_VIDEO_PROCESS_MAX_INPUT_STREAMS

Provides data for calls to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) when the feature specified is [D3D12_FEATURE_VIDEO_PROCESS_MAX_INPUT_STREAMS](#d3d12-feature-data-video-process-max-input-streams). Retrieves the maximum number of enabled input streams supported by the video processor.

```cpp
typedef struct D3D12_FEATURE_DATA_VIDEO_PROCESS_MAX_INPUT_STREAMS
{
    UINT NodeIndex;                                             // input
    UINT MaxInputStreams;                                       // output
} D3D12_FEATURE_DATA_VIDEO_PROCESS_MAX_INPUT_STREAMS;
```

#### Members

`NodeIndex`

An integer indicating which physical adapter of the device the operation applies to, in a multi-adapter operation.

`MaxInputStreams`

The maximum number of streams that can be enabled for the video processor at the same time.

<a id="d3d12-feature-data-video-process-reference-info"></a>

### D3D12_FEATURE_DATA_VIDEO_PROCESS_REFERENCE_INFO

Provides data for calls to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) when the feature specified is [D3D12_FEATURE_VIDEO_PROCESS_REFERENCE_INFO](#d3d12-feature-data-video-process-reference-info). Retrieves the number of past and future reference frames required for the specified deinterlace mode, filter, rate conversion, or auto processing features.

```cpp
typedef struct D3D12_FEATURE_DATA_VIDEO_PROCESS_REFERENCE_INFO
{
    UINT NodeIndex;                                             // input
    D3D12_VIDEO_PROCESS_DEINTERLACE_FLAGS DeinterlaceMode;      // input
    D3D12_VIDEO_PROCESS_FILTER_FLAGS Filters;                   // input
    D3D12_VIDEO_PROCESS_FEATURE_FLAGS FeatureSupport;           // input
    DXGI_RATIONAL InputFrameRate;                               // input
    DXGI_RATIONAL OutputFrameRate;                              // input
    BOOL EnableAutoProcessing;                                  // input
    UINT PastFrames;                                            // output
    UINT FutureFrames;                                          // output
} D3D12_FEATURE_DATA_VIDEO_PROCESS_REFERENCE_INFO;
```

#### Members

`NodeIndex`

An integer indicating which physical adapter of the device the operation applies to, in a multi-adapter operation.

`DeinterlaceMode`

A member of the [D3D12_VIDEO_PROCESS_DEINTERLACE_FLAGS](#d3d12-video-process-deinterlace-flags) enumeration specifying the deinterlacing mode for which the required past and future reference frame counts are retrieved.

`Filters`

A bitwise OR combination of values from the [D3D12_VIDEO_PROCESS_FILTER_FLAGS](#d3d12-video-process-filter-flags) enumeration specifying the filters for which the required past and future reference frame counts are retrieved.

`FeatureSupport`

A bitwise OR combination of values from the [D3D12_VIDEO_PROCESS_FEATURE_FLAGS](#d3d12-video-process-feature-flags) enumeration specifying the features for which the required past and future reference frame counts are retrieved.

`InputFrameRate`

The input frame rate of the stream for which the required past and future reference frame counts are retrieved.

`OutputFrameRate`

The output frame rate of the stream for which the required past and future reference frame counts are retrieved.

`EnableAutoProcessing`

True if autoprocessing will be used; otherwise, false.

`PastFrames`

The number of past frames required to support the specified processing features.

`FutureFrames`

The number of future frames required to support the specified processing features.

<a id="d3d12-feature-data-video-processor-size"></a>

### D3D12_FEATURE_DATA_VIDEO_PROCESSOR_SIZE

Describes the allocation size of a video <ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_feature_data_video_processor_size-summary:0:modified:source-1f76c48a6d6e06ef-0-0 -->processor<!-- d3d12-review-inline:end:video-process:P-d3d12_feature_data_video_processor_size-summary:0:modified:source-1f76c48a6d6e06ef-0-0 --></ins>.

```cpp
typedef struct D3D12_FEATURE_DATA_VIDEO_PROCESSOR_SIZE
{
    UINT NodeMask;
    const D3D12_VIDEO_PROCESS_OUTPUT_STREAM_DESC* pOutputStreamDesc;    // input
    UINT NumInputStreamDescs;                                           // input
    const D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC *pInputStreamDescs;     // input
    UINT64 MemoryPoolL0Size;                                            // output
    UINT64 MemoryPoolL1Size;                                            // output
} D3D12_FEATURE_DATA_VIDEO_PROCESSOR_SIZE;
```

#### Members

`NodeMask`

For single GPU operation, set this to zero. If there are multiple GPU nodes, set a bit to identify the node (the device's physical adapter) <ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_feature_data_video_processor_size-members:1:modified:source-4a62c9ffdd897bec-0-0 -->on which the video processor will be used<!-- d3d12-review-inline:end:video-process:P-d3d12_feature_data_video_processor_size-members:1:modified:source-4a62c9ffdd897bec-0-0 --></ins>. Each bit in the mask corresponds to a single node. Only 1 bit may be set.

`pOutputStreamDesc`

<ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_feature_data_video_processor_size-members:3 -->A pointer to a [D3D12_VIDEO_PROCESS_OUTPUT_STREAM_DESC](#d3d12-video-process-output-stream-desc) structure describing the output stream.<!-- d3d12-review-inline:end:video-process:P-d3d12_feature_data_video_processor_size-members:3 --></ins>

`NumInputStreamDescs`

The number of input streams provided in the *pInputStreamDescs* parameter.

`pInputStreamDescs`

<ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_feature_data_video_processor_size-members:7 -->A pointer to a list of [D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC](#d3d12-video-process-input-stream-desc) structures describing the input streams.<!-- d3d12-review-inline:end:video-process:P-d3d12_feature_data_video_processor_size-members:7 --></ins>

`MemoryPoolL0Size`

The allocation size of the video processor in the L0 memory pool. L0 is the physical system memory pool. When the adapter is discrete/NUMA, this pool has greater bandwidth for the CPU and less bandwidth for the GPU. When the adapter is UMA, this pool is the only one which is valid. For more information, see [Residency](resources.md#residency).

`MemoryPoolL1Size`

The allocation size of the video processor in the L1 memory pool. L1 is typically known as the physical video memory pool. L1 is only available when the adapter is discrete/NUMA, and has greater bandwidth for the GPU and cannot even be accessed by the CPU. When the adapter is UMA, this pool is not available. For more information, see [Residency](resources.md#residency).

<a id="process-stream-types"></a>

## Stream descriptions and operation arguments

<ins><!-- d3d12-review-inline:begin:video-process:N-array-constants:0:authored:migration-c35064a66af9dabe-0 -->`D3D12_VIDEO_PROCESS_STEREO_VIEWS` is 2;
`D3D12_VIDEO_PROCESS_MAX_FILTERS` is 32. The 32-element arrays reserve positions
beyond the eight defined filter indices. Disabled/reserved filter levels
are zero, not the device's reported active-filter default.<!-- d3d12-review-inline:end:video-process:N-array-constants:0:authored:migration-c35064a66af9dabe-0 --></ins>

<a id="d3d12-video-process-input-stream-desc"></a>

### D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC

Specifies the parameters for the input stream for a video process operation.

```cpp
typedef struct D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC
{
    DXGI_FORMAT Format;
    DXGI_COLOR_SPACE_TYPE ColorSpace;
    DXGI_RATIONAL SourceAspectRatio;
    DXGI_RATIONAL DestinationAspectRatio;
    DXGI_RATIONAL FrameRate;
    D3D12_VIDEO_SIZE_RANGE SourceSizeRange;
    D3D12_VIDEO_SIZE_RANGE DestinationSizeRange;
    BOOL EnableOrientation;
    D3D12_VIDEO_PROCESS_FILTER_FLAGS FilterFlags;
    D3D12_VIDEO_FRAME_STEREO_FORMAT StereoFormat;
    D3D12_VIDEO_FIELD_TYPE FieldType;
    D3D12_VIDEO_PROCESS_DEINTERLACE_FLAGS DeinterlaceMode;
    BOOL EnableAlphaBlending;
    D3D12_VIDEO_PROCESS_LUMA_KEY LumaKey;
    UINT NumPastFrames;
    UINT NumFutureFrames;
    BOOL EnableAutoProcessing;
} D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC;
```

#### Members

`Format`

A value from the [DXGI_FORMAT](formats.md#dxgi-format) enumeration specifying the format of the input stream. In the case of stereo, this format is the format of both inputs.

`ColorSpace`

A value from the [DXGI_COLOR_SPACE_TYPE](https://learn.microsoft.com/en-us/windows/desktop/api/dxgicommon/ne-dxgicommon-dxgi_color_space_type) enumeration specifying the color space of the video processor input and reference surfaces.

`SourceAspectRatio`

A [DXGI_RATIONAL](https://learn.microsoft.com/en-us/windows/desktop/api/dxgicommon/ns-dxgicommon-dxgi_rational) structure specifying the source aspect ratio.

`DestinationAspectRatio`

A [DXGI_RATIONAL](https://learn.microsoft.com/en-us/windows/desktop/api/dxgicommon/ns-dxgicommon-dxgi_rational) structure specifying the destination aspect ratio.

`FrameRate`

A [DXGI_RATIONAL](https://learn.microsoft.com/en-us/windows/desktop/api/dxgicommon/ns-dxgicommon-dxgi_rational) structure specifying the frame rate of the input video stream.

`SourceSizeRange`

A [D3D12_VIDEO_SIZE_RANGE](video-decode.md#d3d12-video-size-range) structure representing the size of the source rectangle. This argument specifies the input range size this video processor must support for [ProcessFrames](#process-frames). If a source size exceeds the range, the video processor must be recreated.

`DestinationSizeRange`

<ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_video_process_input_stream_desc-members:13 -->A [D3D12_VIDEO_SIZE_RANGE](video-decode.md#d3d12-video-size-range) structure representing the size of the destination rectangle. This argument specifies the destination range size this video processor must support for [ProcessFrames](#process-frames). If a destination size exceeds the range, the video processor must be recreated.<!-- d3d12-review-inline:end:video-process:P-d3d12_video_process_input_stream_desc-members:13 --></ins>

`EnableOrientation`

<ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_video_process_input_stream_desc-members:15 -->A boolean value specifying whether orientation is enabled for [ProcessFrames](#process-frames).<!-- d3d12-review-inline:end:video-process:P-d3d12_video_process_input_stream_desc-members:15 --></ins>

`FilterFlags`

A bitwise OR combination of one or more flags from the [D3D12_VIDEO_PROCESS_FILTER_FLAGS](#d3d12-video-process-filter-flags) enumeration specifying the filters to enable.

`StereoFormat`

A value from the [D3D12_VIDEO_FRAME_STEREO_FORMAT](#d3d12-video-frame-stereo-format) enumeration specifies whether the stream is stereo or not. A value of <ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_video_process_input_stream_desc-members:19 -->**D3D12\_VIDEO\_FRAME\_STEREO\_FORMAT\_SEPARATE**<!-- d3d12-review-inline:end:video-process:P-d3d12_video_process_input_stream_desc-members:19 --></ins> indicates that there will be two sets of input textures, and two sets of references for the stereo interlaced case.

`FieldType`

<ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_video_process_input_stream_desc-members:21 -->A value from the [D3D12_VIDEO_FIELD_TYPE](#d3d12-video-field-type) enumeration specifying the interlaced field type of the input source. When working with mixed content, use [ID3D12VideoProcessCommandList1::ProcessFrames1](#process-frames1) which supports changing the field type for each call.<!-- d3d12-review-inline:end:video-process:P-d3d12_video_process_input_stream_desc-members:21 --></ins>

`DeinterlaceMode`

A value from the [D3D12_VIDEO_PROCESS_DEINTERLACE_FLAGS](#d3d12-video-process-deinterlace-flags) enumeration specifying the deinterlace mode to use.

`EnableAlphaBlending`

A boolean value specifying whether alpha blending is enabled. Alpha blending settings are provided to [ProcessFrames](#process-frames) <ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_video_process_input_stream_desc-members:25 -->with the *AlphaBlending* field<!-- d3d12-review-inline:end:video-process:P-d3d12_video_process_input_stream_desc-members:25 --></ins> of the [D3D12_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS](#d3d12-video-process-input-stream-arguments) structure.

`LumaKey`

A [D3D12_VIDEO_PROCESS_LUMA_KEY](#d3d12-video-process-luma-key) structure specifying the luma key for an input stream on the video processor.

`NumPastFrames`

An integer specifying the number of past reference frames.

`NumFutureFrames`

An integer specifying the number of future reference frames.

`EnableAutoProcessing`

A boolean value specifying <ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_video_process_input_stream_desc-members:33:modified:source-f59b44b4a7e54ef0-0-0 -->whether<!-- d3d12-review-inline:end:video-process:P-d3d12_video_process_input_stream_desc-members:33:modified:source-f59b44b4a7e54ef0-0-0 --></ins> automatic processing features are enabled for the video processor.

<a id="d3d12-video-process-output-stream-desc"></a>

### D3D12_VIDEO_PROCESS_OUTPUT_STREAM_DESC

Specifies output stream arguments for the output passed to [ID3D12VideoProcessCommandList::ProcessFrames](#process-frames).

```cpp
typedef struct D3D12_VIDEO_PROCESS_OUTPUT_STREAM_DESC
{
    DXGI_FORMAT Format;
    DXGI_COLOR_SPACE_TYPE ColorSpace;
    D3D12_VIDEO_PROCESS_ALPHA_FILL_MODE AlphaFillMode;
    UINT AlphaFillModeSourceStreamIndex;
    FLOAT BackgroundColor[4];
    DXGI_RATIONAL FrameRate;
    BOOL EnableStereo;
} D3D12_VIDEO_PROCESS_OUTPUT_STREAM_DESC;
```

#### Members

`Format`

A <ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_video_process_output_stream_desc-members:1:modified:source-9f1446ef417f3f3a-0-0 -->[DXGI_FORMAT](formats.md#dxgi-format) enumeration<!-- d3d12-review-inline:end:video-process:P-d3d12_video_process_output_stream_desc-members:1:modified:source-9f1446ef417f3f3a-0-0 --></ins> specifying the format of the output resources.

`ColorSpace`

A [DXGI_COLOR_SPACE_TYPE](https://learn.microsoft.com/en-us/windows/desktop/api/dxgicommon/ne-dxgicommon-dxgi_color_space_type) value that specifies the colorspace for the video processor output surface.

`AlphaFillMode`

A value from the [D3D12_VIDEO_PROCESS_ALPHA_FILL_MODE](#d3d12-video-process-alpha-fill-mode) enumeration specifying the alpha fill mode for data that the video processor writes to the render target.

`AlphaFillModeSourceStreamIndex`

The zero-based index of an input stream. This parameter is used if *AlphaFillMode* is [D3D12_VIDEO_PROCESS_ALPHA_FILL_MODE_SOURCE_STREAM](#d3d12-video-process-alpha-fill-mode). Otherwise, the parameter is ignored.

`BackgroundColor[4]`

The video processor uses the background color to fill areas of the target rectangle that do not contain a video image. Areas outside the target rectangle are not affected. The meaning of the values <ins><!-- d3d12-review-inline:begin:video-process:weekend-background-agreement:0 -->is<!-- d3d12-review-inline:end:video-process:weekend-background-agreement:0 --></ins> specified by the *ColorSpace* parameter.

| BackgroundColor | YCbCrA | RGBA |
| --- | --- | --- |
| BackgroundColor[0] | Y | R |
| BackgroundColor[1] | Cb | G |
| BackgroundColor[2] | Cr | B |
| BackgroundColor[3] | A | A |

`FrameRate`

A [DXGI_RATIONAL](https://learn.microsoft.com/en-us/windows/desktop/api/dxgicommon/ns-dxgicommon-dxgi_rational) structure specifying the frame rate of the output video stream.

`EnableStereo`

If TRUE, stereo output is enabled. Otherwise, the video processor produces mono video frames.

<a id="d3d12-video-process-reference-set"></a>

### D3D12_VIDEO_PROCESS_REFERENCE_SET

Contains the reference frames needed to perform video processing.

```cpp
typedef struct D3D12_VIDEO_PROCESS_REFERENCE_SET
{
    UINT NumPastFrames;
    ID3D12Resource **ppPastFrames;
    UINT *pPastSubresources;
    UINT NumFutureFrames;
    ID3D12Resource **ppFutureFrames;
    UINT *pFutureSubresources;
} D3D12_VIDEO_PROCESS_REFERENCE_SET;
```

#### Members

`NumPastFrames`

The number of past reference frames provided in *ppPastFrames*.

`ppPastFrames`

A pointer to an array of [ID3D12Resource](resources.md#resource-storage) surfaces. The number of elements in the array is *NumPastFrames*.

`pPastSubresources`

An array of subresource indices for the list of *ppPastFrames* textures. NULL indicates subresource 0 for each resource.

`NumFutureFrames`

The number of future reference frames provided in *<ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_video_process_reference_set-members:7:modified:source-82d7a8f9a882aae4-0-0 -->ppFutureFrames<!-- d3d12-review-inline:end:video-process:P-d3d12_video_process_reference_set-members:7:modified:source-82d7a8f9a882aae4-0-0 --></ins>*.

`ppFutureFrames`

A pointer to an array of [ID3D12Resource](resources.md#resource-storage) surfaces. The number of elements in the array is *NumFutureFrames*.

`pFutureSubresources`

An array of subresource indices for the list of *ppFutureFrames* textures. NULL indicates subresource 0 for each resource.

<a id="d3d12-video-process-input-stream"></a>

### D3D12_VIDEO_PROCESS_INPUT_STREAM

Contains input information for the video processor blend functionality.

```cpp
typedef struct D3D12_VIDEO_PROCESS_INPUT_STREAM
{
    ID3D12Resource *pTexture2D;
    UINT Subresource;
    D3D12_VIDEO_PROCESS_REFERENCE_SET ReferenceSet;
} D3D12_VIDEO_PROCESS_INPUT_STREAM;
```

#### Members

`pTexture2D`

An [ID3D12Resource](resources.md#resource-storage) representing the current input field or frame.

`Subresource`

The subresource index to use of the *pTexture2D* argument.

`ReferenceSet`

A [D3D12_VIDEO_PROCESS_REFERENCE_SET](#d3d12-video-process-reference-set) containing the set of references for video processing. Some video processing algorithms require forward or backward frame references. For more information, see [D3D12_FEATURE_VIDEO_PROCESS_REFERENCE_INFO](#d3d12-feature-data-video-process-reference-info).

<a id="d3d12-video-process-transform"></a>

### D3D12_VIDEO_PROCESS_TRANSFORM

Specifies transform parameters for video processing. Used by the [D3D12_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS](#d3d12-video-process-input-stream-arguments) structure.

```cpp
typedef struct D3D12_VIDEO_PROCESS_TRANSFORM
{
    D3D12_RECT SourceRectangle;
    D3D12_RECT DestinationRectangle;
    D3D12_VIDEO_PROCESS_ORIENTATION Orientation;
} D3D12_VIDEO_PROCESS_TRANSFORM;
```

#### Members

`SourceRectangle`

Specifies the source rectangle of the transform. This is the portion of the input surface that is blitted to the destination surface. The source rectangle is given in pixel coordinates, relative to the input surface.

`DestinationRectangle`

Specifies the destination rectangle of the transform. This is the portion of the output surface that receives the blit for this stream. The destination rectangle is given in pixel coordinates, relative to the output surface.

`Orientation`

The rotation and flip operation to apply to the source. Source and Destination rectangles are specified in post orientation coordinates.

#### Remarks

For stereo formats, the orientation is applied before the stereo format is applied.

<ins><!-- d3d12-review-inline:begin:video-process:N-rect-qualification:0:authored:migration-dfb1f428e9d44e96-0 -->**Coordinate qualification:** the published transform contract states that
source and destination rectangles use post-orientation coordinates and that
orientation precedes stereo format application. This draft retains those
statements without inventing chroma-edge alignment, clipping, interpolation,
sample positions or a vendor-independent coordinate/precision algorithm.
The per-stream destination rectangle places that stream. The output target
rectangle bounds the drawn/background-filled region. They are distinct roles,
not interchangeable descriptions of one rectangle.<!-- d3d12-review-inline:end:video-process:N-rect-qualification:0:authored:migration-dfb1f428e9d44e96-0 --></ins>

<a id="d3d12-video-process-input-stream-rate"></a>

### D3D12_VIDEO_PROCESS_INPUT_STREAM_RATE

Provides information about the stream rate.

```cpp
typedef struct D3D12_VIDEO_PROCESS_INPUT_STREAM_RATE
{
    UINT OutputIndex;
    UINT InputFrameOrField;
} D3D12_VIDEO_PROCESS_INPUT_STREAM_RATE;
```

#### Members

`OutputIndex`

The zero-based index number of the output frame. The OutputIndex member is a zero-based cyclic number that indicates the frame index number of the output. The driver uses this output-index information to perform the video processing in a certain pattern or cycle, especially when the driver performs deinterlacing or frame-rate conversion. For example, with the following output-index pattern, the driver performs the indicated video processing:

- <ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_video_process_input_stream_rate-members:2 -->Progressive format at normal and half rate:<!-- d3d12-review-inline:end:video-process:P-d3d12_video_process_input_stream_rate-members:2 --></ins>
    - *OutputIndex* = 0, 0,...
- Progressive format at 2/1 custom rate (double frame-rate conversion, OutputFrames=2):
    - *OutputIndex* = 0, 1, 0, 1,...
- Interlaced format at normal rate:
    - *OutputIndex* = 0, 1, 0, 1,... (0: first field, 1: second field)
- Interlaced format at half rate:
    - *OutputIndex* = 0, 0,... (for example, first and second fields are blended to one frame)
- Interlaced at 4/5 custom rate (3:2 inverse telecine, OutputFrames=4):
    - *OutputIndex* = 0, 1, 2, 3, 0, 1, 2, 3,... (0:A, 1:B, 2:C, 3:D film frame)

`InputFrameOrField`

The zero-based index number of the input frame or field. The InputFrameOrField member is a zero-based number that indicates the frame or the field number of the input surface. For example, with the following <ins><!-- d3d12-review-inline:begin:video-process:weekend-style-input-frame-or-field:0 -->input frame or field<!-- d3d12-review-inline:end:video-process:weekend-style-input-frame-or-field:0 --></ins> number, the driver can perform the indicated video processing:

- Progressive format and interlaced format at normal rate:
    - *InputFrameOrField* = 0, 1, 2,...
- Progressive format and interlaced format at half rate:
    - *InputFrameOrField* = 0, 2, 4,...
- Interlaced format at 4/5 custom rate (3:2 inverse telecine, OutputFrames=4 and InputFrameOrField=10):
    - *InputFrameOrField* = 0, 0, 0, 0, 10, 10, 10, 10, 20, 20, 20, 20,...
- Interlaced format at 4/15 custom rate (8:7 inverse telecine, OutputFrames=2 and InputFrameOrField=15):
    - *InputFrameOrField* = 0, 0, 15, 15, 30, 30,...

<a id="d3d12-video-process-input-stream-arguments"></a>

### D3D12_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS

Specifies input stream arguments for an input stream passed to <ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_video_process_input_stream_arguments-summary:0:modified:source-3c9c624d4a92cdb8-0-0 -->[ID3D12VideoProcessCommandList::ProcessFrames](#process-frames)<!-- d3d12-review-inline:end:video-process:P-d3d12_video_process_input_stream_arguments-summary:0:modified:source-3c9c624d4a92cdb8-0-0 --></ins>.

```cpp
typedef struct D3D12_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS
{
    D3D12_VIDEO_PROCESS_INPUT_STREAM InputStream[D3D12_VIDEO_PROCESS_STEREO_VIEWS];
    D3D12_VIDEO_PROCESS_TRANSFORM Transform;
    D3D12_VIDEO_PROCESS_INPUT_STREAM_FLAGS Flags;
    D3D12_VIDEO_PROCESS_INPUT_STREAM_RATE RateInfo;
    INT FilterLevels[D3D12_VIDEO_PROCESS_MAX_FILTERS];
    D3D12_VIDEO_PROCESS_ALPHA_BLENDING AlphaBlending;
} D3D12_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS;
```

#### Members

`InputStream[2]`

An array of [D3D12_VIDEO_PROCESS_INPUT_STREAM](#d3d12-video-process-input-stream) structures containing the set of references for video processing. If the stereo format is <ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_video_process_input_stream_arguments-members:1 -->[D3D12_VIDEO_FRAME_STEREO_FORMAT_SEPARATE](#d3d12-video-frame-stereo-format)<!-- d3d12-review-inline:end:video-process:P-d3d12_video_process_input_stream_arguments-members:1 --></ins>, then two sets of input streams must be supplied. For all other stereo formats, the first set of reference must be supplied, and the second should be zero initialized.

`Transform`

A [D3D12_VIDEO_PROCESS_TRANSFORM](#d3d12-video-process-transform) structure specifying the flip, rotation, scale and destination translation for the video input.

`Flags`

A value from the [D3D12_VIDEO_PROCESS_INPUT_STREAM_FLAGS](#d3d12-video-process-input-stream-flags) enumeration specifying the options for the input stream.

`RateInfo`

A [D3D12_VIDEO_PROCESS_INPUT_STREAM_RATE](#d3d12-video-process-input-stream-rate) structure specifying the framerate and input and output indices for framerate conversion and deinterlacing.

`FilterLevels[32]`

The level to apply for each enabled filter. The filter level is specified in the order that filters appear in the [D3D12_VIDEO_PROCESS_FILTER_FLAGS](#d3d12-video-process-filter-flags) enumeration. Specify 0 if a filter is not enabled or the filter index is reserved.

`AlphaBlending`

A [D3D12_VIDEO_PROCESS_ALPHA_BLENDING](#d3d12-video-process-alpha-blending) structure specifying the planar alpha for an input stream on the video processor.

<a id="d3d12-video-process-input-stream-arguments1"></a>

### D3D12_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS1

Specifies input stream arguments for an input stream passed to [ID3D12VideoProcessCommandList1::ProcessFrames1](#process-frames1), which supports changing the field type for each call.

```cpp
typedef struct D3D12_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS1
{
    D3D12_VIDEO_PROCESS_INPUT_STREAM InputStream[D3D12_VIDEO_PROCESS_STEREO_VIEWS];
    D3D12_VIDEO_PROCESS_TRANSFORM Transform;
    D3D12_VIDEO_PROCESS_INPUT_STREAM_FLAGS Flags;
    D3D12_VIDEO_PROCESS_INPUT_STREAM_RATE RateInfo;
    INT FilterLevels[D3D12_VIDEO_PROCESS_MAX_FILTERS];
    D3D12_VIDEO_PROCESS_ALPHA_BLENDING AlphaBlending;
    D3D12_VIDEO_FIELD_TYPE FieldType;
} D3D12_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS1;
```

<ins><!-- d3d12-review-inline:begin:video-process:N-args1-common:0:authored:migration-eb07afbdf3af7349-0 -->The common members have the same meanings as
[`D3D12_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS`](#d3d12-video-process-input-stream-arguments).
The following member supplies the per-call difference.<!-- d3d12-review-inline:end:video-process:N-args1-common:0:authored:migration-eb07afbdf3af7349-0 --></ins>

#### Members

`FieldType`

A value from the [D3D12_VIDEO_FIELD_TYPE](#d3d12-video-field-type) enumeration <ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_video_process_input_stream_arguments1-members:1 -->specifying<!-- d3d12-review-inline:end:video-process:P-d3d12_video_process_input_stream_arguments1-members:1 --></ins> the interlaced field type of the input source. When working with mixed content, use [ID3D12VideoProcessCommandList1::ProcessFrames1](#process-frames1) which supports changing the field type for each call.

<a id="d3d12-video-process-output-stream"></a>

### D3D12_VIDEO_PROCESS_OUTPUT_STREAM

Represents the output stream for video processing commands. Points to the target surface for the processing operation.

```cpp
typedef struct D3D12_VIDEO_PROCESS_OUTPUT_STREAM
{
    ID3D12Resource* pTexture2D;
    UINT Subresource;
} D3D12_VIDEO_PROCESS_OUTPUT_STREAM;
```

#### Members

`pTexture2D`

A pointer to a [ID3D12Resource](resources.md#resource-storage) representing the output surfaces for the video process command.

`Subresource`

The subresource <ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_video_process_output_stream-members:3:modified:source-a289d897a41439ee-0-0 -->index<!-- d3d12-review-inline:end:video-process:P-d3d12_video_process_output_stream-members:3:modified:source-a289d897a41439ee-0-0 --></ins> to use within the resource specified <ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_video_process_output_stream-members:3:modified:source-a289d897a41439ee-0-1 -->by *pTexture2D*<!-- d3d12-review-inline:end:video-process:P-d3d12_video_process_output_stream-members:3:modified:source-a289d897a41439ee-0-1 --></ins>.

<a id="d3d12-video-process-output-stream-arguments"></a>

### D3D12_VIDEO_PROCESS_OUTPUT_STREAM_ARGUMENTS

Specifies output stream arguments for the output passed to <ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_video_process_output_stream_arguments-summary:0 -->[ID3D12VideoProcessCommandList::ProcessFrames](#process-frames)<!-- d3d12-review-inline:end:video-process:P-d3d12_video_process_output_stream_arguments-summary:0 --></ins>.

```cpp
typedef struct D3D12_VIDEO_PROCESS_OUTPUT_STREAM_ARGUMENTS
{
    D3D12_VIDEO_PROCESS_OUTPUT_STREAM OutputStream[D3D12_VIDEO_PROCESS_STEREO_VIEWS];
    D3D12_RECT TargetRectangle;
} D3D12_VIDEO_PROCESS_OUTPUT_STREAM_ARGUMENTS;
```

#### Members

`OutputStream[2]`

An array of [D3D12_VIDEO_PROCESS_OUTPUT_STREAM](#d3d12-video-process-output-stream) structures representing the output surfaces for the video process command. If stereo output is enabled, index zero contains the left output while <ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_video_process_output_stream_arguments-members:1:modified:migration-acbc0fa54017b90c-0 -->index 1 contains the right output<!-- d3d12-review-inline:end:video-process:P-d3d12_video_process_output_stream_arguments-members:1:modified:migration-acbc0fa54017b90c-0 --></ins>. If stereo output is not enabled, only index 0 is used to specify the output while <ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_video_process_output_stream_arguments-members:1:modified:migration-8372db8e82832a5e-1 -->index 1 should be zero initialized<!-- d3d12-review-inline:end:video-process:P-d3d12_video_process_output_stream_arguments-members:1:modified:migration-8372db8e82832a5e-1 --></ins>.

`TargetRectangle`

The target rectangle is the area within the destination surface where the output will be drawn. The target rectangle is given in pixel coordinates, relative to the destination surface.

<a id="d3d12-video-process-alpha-blending"></a>

### D3D12_VIDEO_PROCESS_ALPHA_BLENDING

Specifies alpha blending parameters for video processing. Used by the <ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_video_process_alpha_blending-summary:0:modified:source-b80b1aa056284f02-0-0 -->[D3D12_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS](#d3d12-video-process-input-stream-arguments)<!-- d3d12-review-inline:end:video-process:P-d3d12_video_process_alpha_blending-summary:0:modified:source-b80b1aa056284f02-0-0 --></ins> structure.

```cpp
typedef struct D3D12_VIDEO_PROCESS_ALPHA_BLENDING
{
    BOOL Enable;
    FLOAT Alpha;
} D3D12_VIDEO_PROCESS_ALPHA_BLENDING;
```

#### Members

`Enable`

A boolean value specifying whether alpha blending is enabled.

`Alpha`

The planar alpha value. The value can range from 0.0 (transparent) to 1.0 (opaque). If *Enable* is <ins><!-- d3d12-review-inline:begin:video-process:P-d3d12_video_process_alpha_blending-members:3:modified:source-0b6dadd3067f9f47-0-0 -->FALSE<!-- d3d12-review-inline:end:video-process:P-d3d12_video_process_alpha_blending-members:3:modified:source-0b6dadd3067f9f47-0-0 --></ins>, this parameter is ignored.

#### Remarks

For each pixel, the destination color value is computed as follows:

`Cd = Cs * (As * Ap * Ae) + Cd * (1.0 - As * Ap * Ae)`

where:

- Cd = The color value of the destination pixel
- Cs = The color value of the source pixel
- As = The per-pixel source alpha
- Ap = The planar alpha value
- Ae = The palette-entry alpha value, or 1.0 (palette-entry alpha values apply only to palettized color formats)

<ins><!-- d3d12-review-inline:begin:video-process:N-blend-qualification:0:authored:migration-3f4d89dda8f3eb4b-0 -->**Numeric qualification:** the published expression describes color blending;
it is not a complete precision, rounding, saturation or color space conversion
specification. The palette entry term does not establish support for any
palettized resource format. No universal linear-light conversion sequence,
interpolation kernel or implementation-specific automatic-processing algorithm
is inferred here.<!-- d3d12-review-inline:end:video-process:N-blend-qualification:0:authored:migration-3f4d89dda8f3eb4b-0 --></ins>

<a id="d3d12-video-process-luma-key"></a>

### D3D12_VIDEO_PROCESS_LUMA_KEY

Specifies the settings used for luma keying. This value is used with the [D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC](#d3d12-video-process-input-stream-desc) structure.

```cpp
typedef struct D3D12_VIDEO_PROCESS_LUMA_KEY
{
    BOOL Enable;
    FLOAT Lower;
    FLOAT Upper;
} D3D12_VIDEO_PROCESS_LUMA_KEY;
```

#### Members

`Enable`

A boolean value specifying whether luma keying is enabled.

`Lower`

The lower bound for the luma key. The valid range is [0…1]. If *Enable* is FALSE, this parameter is ignored.

`Upper`

The upper bound for the luma key. The valid range is [0…1]. If *Enable* is FALSE, this parameter is ignored.

#### Remarks

The values of *Lower* and *Upper* give the lower and upper bounds of the luma key, using a nominal range of [0...1]. Given a format with n bits per channel, these values are converted to luma values as follows:

`val = f * ((1 << n)-1)`

Any pixel whose luma value falls within the upper and lower bounds (inclusive) is treated as transparent. For example, if the pixel format uses 8-bit luma, the upper bound is calculated as follows:

`BYTE Y = BYTE(max(min(1.0, Upper), 0.0) * 255.0)`

Note that the value is clamped to the range [0...1] before multiplying by 255.

<a id="d3d12-video-process-filter-range"></a>

### D3D12_VIDEO_PROCESS_FILTER_RANGE

Defines the range of supported values for an image filter.

```cpp
typedef struct D3D12_VIDEO_PROCESS_FILTER_RANGE
{
    INT   Minimum;
    INT   Maximum;
    INT   Default;
    FLOAT Multiplier;
} D3D12_VIDEO_PROCESS_FILTER_RANGE;
```

#### Members

`Minimum`

The minimum value of the filter.

`Maximum`

The maximum value of the filter.

`Default`

The default value of the filter.

`Multiplier`

A multiplier. Use the following formula to translate the filter setting into the actual filter value:

`Actual Value = Set Value × Multiplier.`

#### Remarks

The multiplier enables the filter range to have a fractional step value. For example, a hue filter might have an actual range of [–180.0 ... +180.0] with a step size of 0.25. The device would report the following range and multiplier:

- Minimum: –720
- Maximum: +720
- Multiplier: 0.25

In this case, a filter value of 2 would be interpreted by the device as 0.50 (or 2 × 0.25).

The device should use a multiplier that can be represented exactly as a base-2 fraction.

<a id="process-capability-types"></a>

## Capability and option values

<a id="d3d12-video-field-type"></a>

### D3D12_VIDEO_FIELD_TYPE

Specifies how a video frame is interlaced.

```cpp
typedef enum D3D12_VIDEO_FIELD_TYPE
{
    D3D12_VIDEO_FIELD_TYPE_NONE = 0,
    D3D12_VIDEO_FIELD_TYPE_INTERLACED_TOP_FIELD_FIRST = 1,
    D3D12_VIDEO_FIELD_TYPE_INTERLACED_BOTTOM_FIELD_FIRST = 2,
} D3D12_VIDEO_FIELD_TYPE;
```

#### Constants

<!-- d3d12-review-alert:begin:video-process:P-d3d12_video_field_type-constants:0:modified:migration-3f4c2f9f5cb50914-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Value | Meaning |
> |---|---|
> | `D3D12_VIDEO_FIELD_TYPE_NONE` | The frame is progressive. |
> | `D3D12_VIDEO_FIELD_TYPE_INTERLACED_TOP_FIELD_FIRST` | The frame is interlaced. The top field of each frame is displayed first. |
> | `D3D12_VIDEO_FIELD_TYPE_INTERLACED_BOTTOM_FIELD_FIRST` | The frame is interlaced. The bottom field of each frame is displayed first. |

<!-- d3d12-review-alert:end:video-process:P-d3d12_video_field_type-constants:0:modified:migration-3f4c2f9f5cb50914-0 -->

<a id="d3d12-video-frame-stereo-format"></a>

### D3D12_VIDEO_FRAME_STEREO_FORMAT

Defines the layout in memory of a stereo 3D video frame. All drivers that support stereo must support all of the defined formats.

```cpp
typedef enum D3D12_VIDEO_FRAME_STEREO_FORMAT
{
    D3D12_VIDEO_FRAME_STEREO_FORMAT_NONE = 0,
    D3D12_VIDEO_FRAME_STEREO_FORMAT_MONO = 1,
    D3D12_VIDEO_FRAME_STEREO_FORMAT_HORIZONTAL = 2,
    D3D12_VIDEO_FRAME_STEREO_FORMAT_VERTICAL = 3,
    D3D12_VIDEO_FRAME_STEREO_FORMAT_SEPARATE = 4,
} D3D12_VIDEO_FRAME_STEREO_FORMAT;
```

#### Constants

<!-- d3d12-review-alert:begin:video-process:P-d3d12_video_frame_stereo_format-constants:0:modified:migration-25f16ca720b71550-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Value | Meaning |
> |---|---|
> | `D3D12_VIDEO_FRAME_STEREO_FORMAT_NONE` | No stereo format is specified. |
> | `D3D12_VIDEO_FRAME_STEREO_FORMAT_MONO` | The sample does not contain stereo data. |
> | `D3D12_VIDEO_FRAME_STEREO_FORMAT_HORIZONTAL` | Frame 0 and frame 1 are packed side-by-side. |
> | `D3D12_VIDEO_FRAME_STEREO_FORMAT_VERTICAL` | Frame 0 and frame 1 are packed top-to-bottom. |
> | `D3D12_VIDEO_FRAME_STEREO_FORMAT_SEPARATE` | Frame 0 and frame 1 are placed in separate resources |

<!-- d3d12-review-alert:end:video-process:P-d3d12_video_frame_stereo_format-constants:0:modified:migration-25f16ca720b71550-0 -->

<a id="d3d12-video-process-support-flags"></a>

### D3D12_VIDEO_PROCESS_SUPPORT_FLAGS

Specifies whether a video format and colorspace conversion operation is supported.

```cpp
typedef enum D3D12_VIDEO_PROCESS_SUPPORT_FLAGS
{
    D3D12_VIDEO_PROCESS_SUPPORT_FLAG_NONE = 0x0,
    D3D12_VIDEO_PROCESS_SUPPORT_FLAG_SUPPORTED = 0x1,

} D3D12_VIDEO_PROCESS_SUPPORT_FLAGS;
```

#### Constants

<!-- d3d12-review-alert:begin:video-process:P-d3d12_video_process_support_flags-constants:0:modified:migration-ff5c7643e220c885-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Value | Meaning |
> |---|---|
> | `D3D12_VIDEO_PROCESS_SUPPORT_FLAG_NONE` | The conversion from the source format and colorspace to destination format and colorspace is not supported. |
> | `D3D12_VIDEO_PROCESS_SUPPORT_FLAG_SUPPORTED` | The conversion from the source format and colorspace to destination format and colorspace is supported. |

<!-- d3d12-review-alert:end:video-process:P-d3d12_video_process_support_flags-constants:0:modified:migration-ff5c7643e220c885-0 -->

#### Remarks

This enumeration is used by the [D3D12_FEATURE_DATA_VIDEO_PROCESS_SUPPORT](#d3d12-feature-data-video-process-support) structure.

<a id="d3d12-video-process-feature-flags"></a>

### D3D12_VIDEO_PROCESS_FEATURE_FLAGS

Specifies the features that a video processor can support.

```cpp
typedef enum D3D12_VIDEO_PROCESS_FEATURE_FLAGS
{
    D3D12_VIDEO_PROCESS_FEATURE_FLAG_NONE = 0x0,
    D3D12_VIDEO_PROCESS_FEATURE_FLAG_ALPHA_FILL = 0x1,
    D3D12_VIDEO_PROCESS_FEATURE_FLAG_LUMA_KEY = 0x2,
    D3D12_VIDEO_PROCESS_FEATURE_FLAG_STEREO = 0x4,
    D3D12_VIDEO_PROCESS_FEATURE_FLAG_ROTATION = 0x8,
    D3D12_VIDEO_PROCESS_FEATURE_FLAG_FLIP = 0x10,
    D3D12_VIDEO_PROCESS_FEATURE_FLAG_ALPHA_BLENDING = 0x20,
    D3D12_VIDEO_PROCESS_FEATURE_FLAG_PIXEL_ASPECT_RATIO = 0x40,

} D3D12_VIDEO_PROCESS_FEATURE_FLAGS;
```

#### Constants

<!-- d3d12-review-alert:begin:video-process:P-d3d12_video_process_feature_flags-constants:0:modified:migration-498c93df80bd98de-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Value | Meaning |
> |---|---|
> | `D3D12_VIDEO_PROCESS_FEATURE_FLAG_NONE` | No features are supported. |
> | `D3D12_VIDEO_PROCESS_FEATURE_FLAG_ALPHA_FILL` | The video processor can set alpha values on the output pixels. The alpha fill mode is used in [D3D12_VIDEO_PROCESS_OUTPUT_STREAM_DESC](#d3d12-video-process-output-stream-desc). [D3D12_VIDEO_PROCESS_ALPHA_FILL_MODE_OPAQUE](#d3d12-video-process-alpha-fill-mode) must be always supported. The background, destination, and source stream modes are only supported when the driver reports D3D12\_VIDEO\_PROCESS\_FEATURE\_FLAG\_ALPHA\_FILL. |
> | `D3D12_VIDEO_PROCESS_FEATURE_FLAG_LUMA_KEY` | The video processor can perform luma keying. Luma keying is configured via the **LumaKey** member of the [D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC](#d3d12-video-process-input-stream-desc) structure. For more information see [D3D12_VIDEO_PROCESS_LUMA_KEY](#d3d12-video-process-luma-key). |
> | `D3D12_VIDEO_PROCESS_FEATURE_FLAG_STEREO` | The video processor can support 3D stereo video. For more information, see [D3D12_VIDEO_FRAME_STEREO_FORMAT](#d3d12-video-frame-stereo-format). All drivers setting this capability must support the following stereo formats: D3D12\_VIDEO\_FRAME\_STEREO\_FORMAT\_HORIZONTAL, D3D12\_VIDEO\_FRAME\_STEREO\_FORMAT\_VERTICAL, and D3D12\_VIDEO\_FRAME\_STEREO\_FORMAT\_SEPARATE. |
> | `D3D12_VIDEO_PROCESS_FEATURE_FLAG_ROTATION` | The driver can rotate the input data either 90, 180, or 270 degrees clockwise as part of the video processing operation. |
> | `D3D12_VIDEO_PROCESS_FEATURE_FLAG_FLIP` | The driver can flip the input data horizontally or vertically, together or separately with a video rotation operation. |
> | `D3D12_VIDEO_PROCESS_FEATURE_FLAG_ALPHA_BLENDING` | Alpha blending and a planar alpha may be set in the **AlphaBlending** member of the [D3D12_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS](#d3d12-video-process-input-stream-arguments) structure. For more information see [D3D12_VIDEO_PROCESS_ALPHA_BLENDING](#d3d12-video-process-alpha-blending). |
> | `D3D12_VIDEO_PROCESS_FEATURE_FLAG_PIXEL_ASPECT_RATIO` | The driver supports changing the pixel aspect ratio. If the driver does not report this capability, then the **SourceAspectRatio** and **DestinationAspectRatio** members of [D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC](#d3d12-video-process-input-stream-desc) structure must indicate a 1:1 aspect ratio. |

<!-- d3d12-review-alert:end:video-process:P-d3d12_video_process_feature_flags-constants:0:modified:migration-498c93df80bd98de-0 -->

<ins><!-- d3d12-review-inline:begin:video-process:N-feature-qualification:0:authored:migration-d641ac09f5e282e5-0 -->**Aspect-ratio qualification:** the published 1:1 restriction above is retained.
The inspected creation validation compares the source and destination rational
fields for equality when PIXEL_ASPECT_RATIO is unavailable. That does not
establish that arbitrary equal non-unit ratios are universally legal. The exact
meaning of 1:1 and rational equivalence remains qualified rather than replaced
with an implementation-derived policy. Feature flags describe support. They
do not make every enabled option or combination universally available.<!-- d3d12-review-inline:end:video-process:N-feature-qualification:0:authored:migration-d641ac09f5e282e5-0 --></ins>

<a id="d3d12-video-process-deinterlace-flags"></a>

### D3D12_VIDEO_PROCESS_DEINTERLACE_FLAGS

Specifies the deinterlacing video processor capabilities.

```cpp
typedef enum D3D12_VIDEO_PROCESS_DEINTERLACE_FLAGS
{
    D3D12_VIDEO_PROCESS_DEINTERLACE_FLAG_NONE = 0x0,
    D3D12_VIDEO_PROCESS_DEINTERLACE_FLAG_BOB = 0x1,
    D3D12_VIDEO_PROCESS_DEINTERLACE_FLAG_CUSTOM = 0x80000000,

} D3D12_VIDEO_PROCESS_DEINTERLACE_FLAGS;
```

#### Constants

<!-- d3d12-review-alert:begin:video-process:P-d3d12_video_process_deinterlace_flags-constants:0:modified:migration-91c935abe8c66fc5-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Value | Meaning |
> |---|---|
> | `D3D12_VIDEO_PROCESS_DEINTERLACE_FLAG_NONE` | No deinterlacing capabilities are available. |
> | `D3D12_VIDEO_PROCESS_DEINTERLACE_FLAG_BOB` | The video processor can perform bob deinterlacing. In bob deinterlacing, missing field lines are interpolated from the lines above and below. Bob deinterlacing does not require reference frames. |
> | `D3D12_VIDEO_PROCESS_DEINTERLACE_FLAG_CUSTOM` | The video processor can perform a custom high-quality deinterlacing, which requires the number of reference frames indicated in *PastFrames* and *FutureFrames* output fields of the [D3D12_FEATURE_DATA_VIDEO_PROCESS_REFERENCE_INFO](#d3d12-feature-data-video-process-reference-info) populated by a call to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) when the feature specified is [D3D12_FEATURE_VIDEO_PROCESS_REFERENCE_INFO](#d3d12-feature-data-video-process-reference-info). If the video processor doesn’t have the necessary number of reference frames, it falls back to bob deinterlacing. |

<!-- d3d12-review-alert:end:video-process:P-d3d12_video_process_deinterlace_flags-constants:0:modified:migration-91c935abe8c66fc5-0 -->

<ins><!-- d3d12-review-inline:begin:video-process:N-deinterlace-qualification:0:authored:migration-349d211313fdc75f-0 -->**Reference qualification:** the published CUSTOM description above specifies
bob fallback when the necessary references are unavailable. Processor creation
still declares the queried required counts. The selected public material does
not completely define short/null per-call reference arrays, temporal array
ordering, stream start/end padding or the boundary between fallback and invalid
usage. This draft does not turn the fallback sentence into permission to pass
arbitrary missing or malformed references.<!-- d3d12-review-inline:end:video-process:N-deinterlace-qualification:0:authored:migration-349d211313fdc75f-0 --></ins>

<a id="d3d12-video-process-filter"></a>

### D3D12_VIDEO_PROCESS_FILTER

<ins><!-- d3d12-review-inline:begin:video-process:N-filter-index:0:authored:migration-aa94ba5d65dab672-0 -->The filter enumeration supplies zero-based indices for the filter level and
filter range arrays. The corresponding filter flag is `1 << filter_index`.<!-- d3d12-review-inline:end:video-process:N-filter-index:0:authored:migration-aa94ba5d65dab672-0 --></ins>

```cpp
typedef enum  D3D12_VIDEO_PROCESS_FILTER
{
    D3D12_VIDEO_PROCESS_FILTER_BRIGHTNESS = 0,
    D3D12_VIDEO_PROCESS_FILTER_CONTRAST = 1,
    D3D12_VIDEO_PROCESS_FILTER_HUE = 2,
    D3D12_VIDEO_PROCESS_FILTER_SATURATION = 3,
    D3D12_VIDEO_PROCESS_FILTER_NOISE_REDUCTION = 4,
    D3D12_VIDEO_PROCESS_FILTER_EDGE_ENHANCEMENT = 5,
    D3D12_VIDEO_PROCESS_FILTER_ANAMORPHIC_SCALING = 6,
    D3D12_VIDEO_PROCESS_FILTER_STEREO_ADJUSTMENT = 7,
} D3D12_VIDEO_PROCESS_FILTER;
```

<a id="d3d12-video-process-filter-flags"></a>

### D3D12_VIDEO_PROCESS_FILTER_FLAGS

Specifies support for the image filters.

```cpp
typedef enum  D3D12_VIDEO_PROCESS_FILTER_FLAGS
{
    D3D12_VIDEO_PROCESS_FILTER_FLAG_NONE = 0x0,
    D3D12_VIDEO_PROCESS_FILTER_FLAG_BRIGHTNESS = (1 << D3D12_VIDEO_PROCESS_FILTER_BRIGHTNESS),
    D3D12_VIDEO_PROCESS_FILTER_FLAG_CONTRAST = (1 << D3D12_VIDEO_PROCESS_FILTER_CONTRAST),
    D3D12_VIDEO_PROCESS_FILTER_FLAG_HUE = (1 << D3D12_VIDEO_PROCESS_FILTER_HUE),
    D3D12_VIDEO_PROCESS_FILTER_FLAG_SATURATION = (1 << D3D12_VIDEO_PROCESS_FILTER_SATURATION),
    D3D12_VIDEO_PROCESS_FILTER_FLAG_NOISE_REDUCTION = (1 << D3D12_VIDEO_PROCESS_FILTER_NOISE_REDUCTION),
    D3D12_VIDEO_PROCESS_FILTER_FLAG_EDGE_ENHANCEMENT = (1 << D3D12_VIDEO_PROCESS_FILTER_EDGE_ENHANCEMENT),
    D3D12_VIDEO_PROCESS_FILTER_FLAG_ANAMORPHIC_SCALING = (1 << D3D12_VIDEO_PROCESS_FILTER_ANAMORPHIC_SCALING),
    D3D12_VIDEO_PROCESS_FILTER_FLAG_STEREO_ADJUSTMENT = (1 << D3D12_VIDEO_PROCESS_FILTER_STEREO_ADJUSTMENT),

} D3D12_VIDEO_PROCESS_FILTER_FLAGS;
```

#### Constants

<!-- d3d12-review-alert:begin:video-process:P-d3d12_video_process_filter_flags-constants:0:modified:migration-feb4ec4dc08307bb-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Value | Meaning |
> |---|---|
> | `D3D12_VIDEO_PROCESS_FILTER_FLAG_NONE` | The video processor doesn't support any filters. |
> | `D3D12_VIDEO_PROCESS_FILTER_FLAG_BRIGHTNESS` | The video processor can adjust the brightness level. |
> | `D3D12_VIDEO_PROCESS_FILTER_FLAG_CONTRAST` | The video processor can adjust the contrast level. |
> | `D3D12_VIDEO_PROCESS_FILTER_FLAG_HUE` | The video processor can adjust hue. |
> | `D3D12_VIDEO_PROCESS_FILTER_FLAG_SATURATION` | The video processor can adjust the saturation level. |
> | `D3D12_VIDEO_PROCESS_FILTER_FLAG_NOISE_REDUCTION` | The video processor can perform noise reduction. |
> | `D3D12_VIDEO_PROCESS_FILTER_FLAG_EDGE_ENHANCEMENT` | The video processor can perform edge enhancement. |
> | `D3D12_VIDEO_PROCESS_FILTER_FLAG_ANAMORPHIC_SCALING` | The video processor can perform anamorphic scaling. Anamorphic scaling can be used to stretch 4:3 content to a widescreen 16:9 aspect ratio. |
> | `D3D12_VIDEO_PROCESS_FILTER_FLAG_STEREO_ADJUSTMENT` | For stereo 3D video, the video processor can adjust the offset between the left and right views, allowing the user to reduce potential eye strain. |

<!-- d3d12-review-alert:end:video-process:P-d3d12_video_process_filter_flags-constants:0:modified:migration-feb4ec4dc08307bb-0 -->

#### Remarks

See [D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC](#d3d12-video-process-input-stream-desc) for information on applying a particular filter.

<a id="d3d12-video-process-auto-processing-flags"></a>

### D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAGS

Specifies the automatic processing features that a video processor can support.

```cpp
typedef enum D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAGS
{
    D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_NONE = 0x0,
    D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_DENOISE = 0x01,
    D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_DERINGING = 0x02,
    D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_EDGE_ENHANCEMENT = 0x04,
    D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_COLOR_CORRECTION = 0x08,
    D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_FLESH_TONE_MAPPING = 0x10,
    D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_IMAGE_STABILIZATION = 0x20,
    D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_SUPER_RESOLUTION = 0x40,
    D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_ANAMORPHIC_SCALING = 0x80,
    D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_CUSTOM = 0x80000000,

} D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAGS;
```

#### Constants

<!-- d3d12-review-alert:begin:video-process:P-d3d12_video_process_auto_processing_flags-constants:0:modified:migration-cb7de82bdeb2dfb1-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Value | Meaning |
> |---|---|
> | `D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_NONE` | No automatic processing features are supported. |
> | `D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_DENOISE` | Denoise is supported. |
> | `D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_DERINGING` | Deringing is supported. |
> | `D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_EDGE_ENHANCEMENT` | Edge enhancement is supported. |
> | `D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_COLOR_CORRECTION` | Color correction is supported. |
> | `D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_FLESH_TONE_MAPPING` | Flesh tone mapping is supported. |
> | `D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_IMAGE_STABILIZATION` | Image stabilization is supported. |
> | `D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_SUPER_RESOLUTION` | Enhanced image resolution is supported. |
> | `D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_ANAMORPHIC_SCALING` | Anamorphic scaling is supported. |
> | `D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_CUSTOM` | Additional processing features, not described by the other flags, are available. |

<!-- d3d12-review-alert:end:video-process:P-d3d12_video_process_auto_processing_flags-constants:0:modified:migration-cb7de82bdeb2dfb1-0 -->

#### Remarks

This enumeration is used by the [D3D12_FEATURE_DATA_VIDEO_PROCESS_SUPPORT](#d3d12-feature-data-video-process-support) structure.

<a id="d3d12-video-process-orientation"></a>

### D3D12_VIDEO_PROCESS_ORIENTATION

Specifies an orientation operation to be performed by a video processor.

```cpp
typedef enum D3D12_VIDEO_PROCESS_ORIENTATION
{
    D3D12_VIDEO_PROCESS_ORIENTATION_DEFAULT = 0,
    D3D12_VIDEO_PROCESS_ORIENTATION_FLIP_HORIZONTAL = 1,
    D3D12_VIDEO_PROCESS_ORIENTATION_CLOCKWISE_90 = 2,
    D3D12_VIDEO_PROCESS_ORIENTATION_CLOCKWISE_90_FLIP_HORIZONTAL = 3,
    D3D12_VIDEO_PROCESS_ORIENTATION_CLOCKWISE_180 = 4,
    D3D12_VIDEO_PROCESS_ORIENTATION_FLIP_VERTICAL = 5,
    D3D12_VIDEO_PROCESS_ORIENTATION_CLOCKWISE_270 = 6,
    D3D12_VIDEO_PROCESS_ORIENTATION_CLOCKWISE_270_FLIP_HORIZONTAL = 7,
} D3D12_VIDEO_PROCESS_ORIENTATION;
```

#### Constants

<!-- d3d12-review-alert:begin:video-process:P-d3d12_video_process_orientation-constants:0:modified:migration-284a7b05ea35af14-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Value | Meaning |
> |---|---|
> | `D3D12_VIDEO_PROCESS_ORIENTATION_DEFAULT` | No change in orientation. 0 degrees. |
> | `D3D12_VIDEO_PROCESS_ORIENTATION_FLIP_HORIZONTAL` | The image is flipped horizontally. |
> | `D3D12_VIDEO_PROCESS_ORIENTATION_CLOCKWISE_90` | The image is rotated 90 degrees clockwise. |
> | `D3D12_VIDEO_PROCESS_ORIENTATION_CLOCKWISE_90_FLIP_HORIZONTAL` | The image is rotated 90 degrees clockwise and then flipped horizontally. |
> | `D3D12_VIDEO_PROCESS_ORIENTATION_CLOCKWISE_180` | The image is rotated 180 degrees clockwise. |
> | `D3D12_VIDEO_PROCESS_ORIENTATION_FLIP_VERTICAL` | The image is flipped vertically. |
> | `D3D12_VIDEO_PROCESS_ORIENTATION_CLOCKWISE_270` | The image is rotated 270 degrees clockwise. |
> | `D3D12_VIDEO_PROCESS_ORIENTATION_CLOCKWISE_270_FLIP_HORIZONTAL` | The image is rotated 270 degrees clockwise and then flipped horizontally. |

<!-- d3d12-review-alert:end:video-process:P-d3d12_video_process_orientation-constants:0:modified:migration-284a7b05ea35af14-0 -->

<a id="d3d12-video-process-input-stream-flags"></a>

### D3D12_VIDEO_PROCESS_INPUT_STREAM_FLAGS

Specifies flags for video processing input streams. Used by the [D3D12_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS](#d3d12-video-process-input-stream-arguments) structure.

```cpp
typedef enum D3D12_VIDEO_PROCESS_INPUT_STREAM_FLAGS
{
    D3D12_VIDEO_PROCESS_INPUT_STREAM_FLAG_NONE = 0x0,
    D3D12_VIDEO_PROCESS_INPUT_STREAM_FLAG_FRAME_DISCONTINUITY = 0x1,
    D3D12_VIDEO_PROCESS_INPUT_STREAM_FLAG_FRAME_REPEAT = 0x2,

} D3D12_VIDEO_PROCESS_INPUT_STREAM_FLAGS;
```

#### Constants

<!-- d3d12-review-alert:begin:video-process:P-d3d12_video_process_input_stream_flags-constants:0:modified:migration-be30b1b69648d06e-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Value | Meaning |
> |---|---|
> | `D3D12_VIDEO_PROCESS_INPUT_STREAM_FLAG_NONE` | No flags specified. |
> | `D3D12_VIDEO_PROCESS_INPUT_STREAM_FLAG_FRAME_DISCONTINUITY` | Set this flag when not processing frames in order, such as seeking between frames |
> | `D3D12_VIDEO_PROCESS_INPUT_STREAM_FLAG_FRAME_REPEAT` | Set this flag when applying video process operation to the same set of inputs. |

<!-- d3d12-review-alert:end:video-process:P-d3d12_video_process_input_stream_flags-constants:0:modified:migration-be30b1b69648d06e-0 -->

<a id="d3d12-video-process-alpha-fill-mode"></a>

### D3D12_VIDEO_PROCESS_ALPHA_FILL_MODE

Specifies the alpha fill mode for video processing. This value is used by the [D3D12_VIDEO_PROCESS_OUTPUT_STREAM_DESC](#d3d12-video-process-output-stream-desc) structure.

```cpp
typedef enum D3D12_VIDEO_PROCESS_ALPHA_FILL_MODE
{
    D3D12_VIDEO_PROCESS_ALPHA_FILL_MODE_OPAQUE = 0,
    D3D12_VIDEO_PROCESS_ALPHA_FILL_MODE_BACKGROUND = 1,
    D3D12_VIDEO_PROCESS_ALPHA_FILL_MODE_DESTINATION = 2,
    D3D12_VIDEO_PROCESS_ALPHA_FILL_MODE_SOURCE_STREAM = 3,
} D3D12_VIDEO_PROCESS_ALPHA_FILL_MODE;
```

#### Constants

<!-- d3d12-review-alert:begin:video-process:P-d3d12_video_process_alpha_fill_mode-constants:0:modified:migration-74647399ff149f1d-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Value | Meaning |
> |---|---|
> | `D3D12_VIDEO_PROCESS_ALPHA_FILL_MODE_OPAQUE` | Alpha values inside the target rectangle are set to opaque. |
> | `D3D12_VIDEO_PROCESS_ALPHA_FILL_MODE_BACKGROUND` | Alpha values inside the target rectangle are set to the alpha value specified in the background color. |
> | `D3D12_VIDEO_PROCESS_ALPHA_FILL_MODE_DESTINATION` | Existing alpha values remain unchanged in the output surface. |
> | `D3D12_VIDEO_PROCESS_ALPHA_FILL_MODE_SOURCE_STREAM` | Alpha values are taken from an input stream, scaled, and copied to the corresponding destination rectangle for that stream. The input stream is specified in the *AlphaFillModeSourceStreamIndex* member of [D3D12_VIDEO_PROCESS_OUTPUT_STREAM_DESC](#d3d12-video-process-output-stream-desc). If the input stream does not have alpha data, the video processor sets the alpha values in the target rectangle to opaque. If the input stream is disabled or the source rectangle is empty, the alpha values in the target rectangle are not modified. |

<!-- d3d12-review-alert:end:video-process:P-d3d12_video_process_alpha_fill_mode-constants:0:modified:migration-74647399ff149f1d-0 -->

#### Remarks

**D3D12\_VIDEO\_PROCESS\_ALPHA\_FILL\_MODE\_OPAQUE** must be always supported. The background, destination, and source stream modes are only supported when the driver reports [D3D12_VIDEO_PROCESS_FEATURE_FLAG_ALPHA_FILL](#d3d12-video-process-feature-flags).

<a id="process-driver"></a>

## Published driver contracts

<ins><!-- d3d12-review-inline:begin:video-process:N-ddi-intro:0:authored:migration-ad1a931abe7f5c5d-0 -->Private processor sizing reports CPU object storage. The separate processor size capability query reports memory pool requirements.<!-- d3d12-review-inline:end:video-process:N-ddi-intro:0:authored:migration-ad1a931abe7f5c5d-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-process:N-ddi-intro:1:authored:migration-c1f1f52f0aa8afac-0 -->Current creation supplies counted input stream descriptions, the output description and protected session association. Per-frame `FieldType` is supplied in recording arguments. The output stream description and recording output layout retain `_0032`.<!-- d3d12-review-inline:end:video-process:N-ddi-intro:1:authored:migration-c1f1f52f0aa8afac-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-process:N-ddi-shared:0:authored:migration-01c75846824167a7-0 -->DDI stereo uses `MONO = 0`, whereas the API distinguishes `NONE = 0` and `MONO = 1`. The DDI automatic-processing `CUSTOM` bit is `0x100`, not API `0x80000000`. DDI orientation names the value-5 180-degree/horizontal-flip alias. `D3D12DDI_VIDEO_PROCESS_MAX_FILTERS_0020` is 32.<!-- d3d12-review-inline:end:video-process:N-ddi-shared:0:authored:migration-01c75846824167a7-0 --></ins>

<a id="d3d12ddi-video-field-type-0020"></a>

### D3D12DDI_VIDEO_FIELD_TYPE_0020

```cpp
typedef enum D3D12DDI_VIDEO_FIELD_TYPE_0020
{
    D3D12DDI_VIDEO_FIELD_TYPE_0020_NONE = 0,
    D3D12DDI_VIDEO_FIELD_TYPE_0020_INTERLACED_TOP_FIELD_FIRST = 1,
    D3D12DDI_VIDEO_FIELD_TYPE_0020_INTERLACED_BOTTOM_FIELD_FIRST = 2
} D3D12DDI_VIDEO_FIELD_TYPE_0020;
```

<a id="d3d12ddi-video-frame-stereo-format-0020"></a>

### D3D12DDI_VIDEO_FRAME_STEREO_FORMAT_0020

```cpp
typedef enum D3D12DDI_VIDEO_FRAME_STEREO_FORMAT_0020
{
    D3D12DDI_VIDEO_FRAME_STEREO_FORMAT_0020_MONO = 0,
    D3D12DDI_VIDEO_FRAME_STEREO_FORMAT_0020_HORIZONTAL = 1,
    D3D12DDI_VIDEO_FRAME_STEREO_FORMAT_0020_VERTICAL = 2,
    D3D12DDI_VIDEO_FRAME_STEREO_FORMAT_0020_SEPARATE = 3
} D3D12DDI_VIDEO_FRAME_STEREO_FORMAT_0020;
```

<a id="d3d12ddi-video-process-feature-support-flags-0020"></a>

### D3D12DDI_VIDEO_PROCESS_FEATURE_SUPPORT_FLAGS_0020

```cpp
typedef enum D3D12DDI_VIDEO_PROCESS_FEATURE_SUPPORT_FLAGS_0020
{
    D3D12DDI_VIDEO_PROCESS_FEATURE_SUPPORT_FLAG_0022_NONE = 0x0,
    D3D12DDI_VIDEO_PROCESS_FEATURE_SUPPORT_FLAG_0020_ALPHA_FILL = 0x1,
    D3D12DDI_VIDEO_PROCESS_FEATURE_SUPPORT_FLAG_0020_LUMA_KEY = 0x2,
    D3D12DDI_VIDEO_PROCESS_FEATURE_SUPPORT_FLAG_0020_STEREO = 0x4,
    D3D12DDI_VIDEO_PROCESS_FEATURE_SUPPORT_FLAG_0020_ROTATION = 0x8,
    D3D12DDI_VIDEO_PROCESS_FEATURE_SUPPORT_FLAG_0020_FLIP = 0x10,
    D3D12DDI_VIDEO_PROCESS_FEATURE_SUPPORT_FLAG_0020_ALPHA_BLENDING = 0x20,
    D3D12DDI_VIDEO_PROCESS_FEATURE_SUPPORT_FLAG_0020_PIXEL_ASPECT_RATIO  = 0x40,

} D3D12DDI_VIDEO_PROCESS_FEATURE_SUPPORT_FLAGS_0020;
```

<a id="d3d12ddi-video-process-deinterlace-flags-0020"></a>

### D3D12DDI_VIDEO_PROCESS_DEINTERLACE_FLAGS_0020

```cpp
typedef enum D3D12DDI_VIDEO_PROCESS_DEINTERLACE_FLAGS_0020
{
    D3D12DDI_VIDEO_PROCESS_DEINTERLACE_FLAG_0020_NONE = 0x0,
    D3D12DDI_VIDEO_PROCESS_DEINTERLACE_FLAG_0020_BOB = 0x1,
    D3D12DDI_VIDEO_PROCESS_DEINTERLACE_FLAG_0020_CUSTOM = 0x80000000,

} D3D12DDI_VIDEO_PROCESS_DEINTERLACE_FLAGS_0020;
```

<a id="d3d12ddi-video-process-filter-0020"></a>

### D3D12DDI_VIDEO_PROCESS_FILTER_0020

```cpp
typedef enum  D3D12DDI_VIDEO_PROCESS_FILTER_0020
{
    D3D12DDI_VIDEO_PROCESS_FILTER_0020_BRIGHTNESS         = 0,
    D3D12DDI_VIDEO_PROCESS_FILTER_0020_CONTRAST           = 1,
    D3D12DDI_VIDEO_PROCESS_FILTER_0020_HUE                = 2,
    D3D12DDI_VIDEO_PROCESS_FILTER_0020_SATURATION         = 3,
    D3D12DDI_VIDEO_PROCESS_FILTER_0020_NOISE_REDUCTION    = 4,
    D3D12DDI_VIDEO_PROCESS_FILTER_0020_EDGE_ENHANCEMENT   = 5,
    D3D12DDI_VIDEO_PROCESS_FILTER_0020_ANAMORPHIC_SCALING = 6,
    D3D12DDI_VIDEO_PROCESS_FILTER_0020_STEREO_ADJUSTMENT  = 7,
} D3D12DDI_VIDEO_PROCESS_FILTER_0020;
```

<a id="d3d12ddi-video-process-filter-flags-0020"></a>

### D3D12DDI_VIDEO_PROCESS_FILTER_FLAGS_0020

```cpp
typedef enum  D3D12DDI_VIDEO_PROCESS_FILTER_FLAGS_0020
{
    D3D12DDI_VIDEO_PROCESS_FILTER_FLAG_0020_NONE                = 0,
    D3D12DDI_VIDEO_PROCESS_FILTER_FLAG_0020_BRIGHTNESS          = (1 << D3D12DDI_VIDEO_PROCESS_FILTER_0020_BRIGHTNESS),
    D3D12DDI_VIDEO_PROCESS_FILTER_FLAG_0020_CONTRAST            = (1 << D3D12DDI_VIDEO_PROCESS_FILTER_0020_CONTRAST),
    D3D12DDI_VIDEO_PROCESS_FILTER_FLAG_0020_HUE                 = (1 << D3D12DDI_VIDEO_PROCESS_FILTER_0020_HUE),
    D3D12DDI_VIDEO_PROCESS_FILTER_FLAG_0020_SATURATION          = (1 << D3D12DDI_VIDEO_PROCESS_FILTER_0020_SATURATION),
    D3D12DDI_VIDEO_PROCESS_FILTER_FLAG_0020_NOISE_REDUCTION     = (1 << D3D12DDI_VIDEO_PROCESS_FILTER_0020_NOISE_REDUCTION),
    D3D12DDI_VIDEO_PROCESS_FILTER_FLAG_0020_EDGE_ENHANCEMENT    = (1 << D3D12DDI_VIDEO_PROCESS_FILTER_0020_EDGE_ENHANCEMENT),
    D3D12DDI_VIDEO_PROCESS_FILTER_FLAG_0020_ANAMORPHIC_SCALING  = (1 << D3D12DDI_VIDEO_PROCESS_FILTER_0020_ANAMORPHIC_SCALING),
    D3D12DDI_VIDEO_PROCESS_FILTER_FLAG_0020_STEREO_ADJUSTMENT   = (1 << D3D12DDI_VIDEO_PROCESS_FILTER_0020_STEREO_ADJUSTMENT),

} D3D12DDI_VIDEO_PROCESS_FILTER_FLAGS_0020;
```

<a id="d3d12ddi-video-process-orientation-0020"></a>

### D3D12DDI_VIDEO_PROCESS_ORIENTATION_0020

```cpp
typedef enum D3D12DDI_VIDEO_PROCESS_ORIENTATION_0020
{
    D3D12DDI_VIDEO_PROCESS_ORIENTATION_0020_DEFAULT = 0,
    D3D12DDI_VIDEO_PROCESS_ORIENTATION_0020_FLIP_HORIZONTAL = 1,
    D3D12DDI_VIDEO_PROCESS_ORIENTATION_0020_CLOCKWISE_90 = 2,
    D3D12DDI_VIDEO_PROCESS_ORIENTATION_0020_CLOCKWISE_90_FLIP_HORIZONTAL = 3,
    D3D12DDI_VIDEO_PROCESS_ORIENTATION_0020_CLOCKWISE_180 = 4,
    D3D12DDI_VIDEO_PROCESS_ORIENTATION_0020_FLIP_VERTICAL = 5,
    D3D12DDI_VIDEO_PROCESS_ORIENTATION_0020_CLOCKWISE_180_FLIP_HORIZONTAL = 5,
    D3D12DDI_VIDEO_PROCESS_ORIENTATION_0020_CLOCKWISE_270 = 6,
    D3D12DDI_VIDEO_PROCESS_ORIENTATION_0020_CLOCKWISE_270_FLIP_HORIZONTAL = 7
} D3D12DDI_VIDEO_PROCESS_ORIENTATION_0020;
```

<a id="d3d12ddi-video-process-input-stream-flags-0020"></a>

### D3D12DDI_VIDEO_PROCESS_INPUT_STREAM_FLAGS_0020

```cpp
typedef enum D3D12DDI_VIDEO_PROCESS_INPUT_STREAM_FLAGS_0020
{
    D3D12DDI_VIDEO_PROCESS_INPUT_STREAM_FLAG_0020_NONE = 0x0,
    D3D12DDI_VIDEO_PROCESS_INPUT_STREAM_FLAG_0020_FRAME_DISCONTINUITY = 0x1,
    D3D12DDI_VIDEO_PROCESS_INPUT_STREAM_FLAG_0020_FRAME_REPEAT = 0x2,
} D3D12DDI_VIDEO_PROCESS_INPUT_STREAM_FLAGS_0020;
```

<a id="d3d12ddi-video-process-alpha-fill-mode-0020"></a>

### D3D12DDI_VIDEO_PROCESS_ALPHA_FILL_MODE_0020

```cpp
typedef enum D3D12DDI_VIDEO_PROCESS_ALPHA_FILL_MODE_0020
{
  D3D12DDI_VIDEO_PROCESS_ALPHA_FILL_MODE_0020_OPAQUE         = 0,
  D3D12DDI_VIDEO_PROCESS_ALPHA_FILL_MODE_0020_BACKGROUND     = 1,
  D3D12DDI_VIDEO_PROCESS_ALPHA_FILL_MODE_0020_DESTINATION    = 2,
  D3D12DDI_VIDEO_PROCESS_ALPHA_FILL_MODE_0020_SOURCE_STREAM  = 3
} D3D12DDI_VIDEO_PROCESS_ALPHA_FILL_MODE_0020;
```

<a id="d3d12ddi-video-process-support-flags-0022"></a>

### D3D12DDI_VIDEO_PROCESS_SUPPORT_FLAGS_0022

```cpp
typedef enum D3D12DDI_VIDEO_PROCESS_SUPPORT_FLAGS_0022
{
    D3D12DDI_VIDEO_PROCESS_SUPPORT_FLAG_0022_NONE                   = 0x0,
    D3D12DDI_VIDEO_PROCESS_SUPPORT_FLAG_0022_SUPPORTED              = 0x1,

} D3D12DDI_VIDEO_PROCESS_SUPPORT_FLAGS_0022;
```

<a id="d3d12ddi-video-process-auto-processing-flags-0022"></a>

### D3D12DDI_VIDEO_PROCESS_AUTO_PROCESSING_FLAGS_0022

```cpp
typedef enum D3D12DDI_VIDEO_PROCESS_AUTO_PROCESSING_FLAGS_0022
{
    D3D12DDI_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_0022_NONE = 0x0,
    D3D12DDI_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_0022_DENOISE = 0x01,
    D3D12DDI_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_0022_DERINGING = 0x02,
    D3D12DDI_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_0022_EDGE_ENHANCEMENT = 0x04,
    D3D12DDI_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_0022_COLOR_CORRECTION = 0x08,
    D3D12DDI_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_0022_FLESH_TONE_MAPPING = 0x10,
    D3D12DDI_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_0022_IMAGE_STABILIZATION = 0x20,
    D3D12DDI_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_0022_SUPER_RESOLUTION = 0x40,
    D3D12DDI_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_0022_ANAMORPHIC_SCALING = 0x80,
    D3D12DDI_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_0022_CUSTOM = 0x100,

} D3D12DDI_VIDEO_PROCESS_AUTO_PROCESSING_FLAGS_0022;
```

<a id="d3d12ddi-video-process-alpha-blending-0020"></a>

### D3D12DDI_VIDEO_PROCESS_ALPHA_BLENDING_0020

```cpp
typedef struct D3D12DDI_VIDEO_PROCESS_ALPHA_BLENDING_0020
{
    BOOL Enable;
    FLOAT Alpha;
} D3D12DDI_VIDEO_PROCESS_ALPHA_BLENDING_0020;
```

<a id="d3d12ddi-video-process-luma-key-0020"></a>

### D3D12DDI_VIDEO_PROCESS_LUMA_KEY_0020

```cpp
typedef struct D3D12DDI_VIDEO_PROCESS_LUMA_KEY_0020
{
    BOOL Enable;
    FLOAT Lower;
    FLOAT Upper;
} D3D12DDI_VIDEO_PROCESS_LUMA_KEY_0020;
```

<a id="d3d12ddi-video-process-filter-range-0020"></a>

### D3D12DDI_VIDEO_PROCESS_FILTER_RANGE_0020

```cpp
typedef struct D3D12DDI_VIDEO_PROCESS_FILTER_RANGE_0020
{
    INT   Minimum;
    INT   Maximum;
    INT   Default;
    FLOAT Multiplier;
} D3D12DDI_VIDEO_PROCESS_FILTER_RANGE_0020;
```

<a id="d3d12ddi-video-process-max-input-streams-data-0020"></a>

### D3D12DDI_VIDEO_PROCESS_MAX_INPUT_STREAMS_DATA_0020

```cpp
typedef struct D3D12DDI_VIDEO_PROCESS_MAX_INPUT_STREAMS_DATA_0020
{
    UINT NodeIndex;                                                     // input
    UINT MaxInputStreams;                                               // output
} D3D12DDI_VIDEO_PROCESS_MAX_INPUT_STREAMS_DATA_0020;
```

<a id="d3d12ddi-video-process-references-info-0020"></a>

### D3D12DDI_VIDEO_PROCESS_REFERENCES_INFO_0020

```cpp
typedef struct D3D12DDI_VIDEO_PROCESS_REFERENCES_INFO_0020
{
    UINT NumPastFrames;
    D3D12DDI_HRESOURCE *hDrvPastFrames;
    UINT *pPastSubresources;
    UINT NumFutureFrames;
    D3D12DDI_HRESOURCE *hDrvFutureFrames;
    UINT *pFutureSubresources;
} D3D12DDI_VIDEO_PROCESS_REFERENCES_INFO_0020;
```

<a id="d3d12ddi-video-process-input-stream-0020"></a>

### D3D12DDI_VIDEO_PROCESS_INPUT_STREAM_0020

```cpp
typedef struct D3D12DDI_VIDEO_PROCESS_INPUT_STREAM_0020
{
    D3D12DDI_HRESOURCE hDrvInputTexture;
    UINT Subresource;
    D3D12DDI_VIDEO_PROCESS_REFERENCES_INFO_0020 ReferenceInfo;
} D3D12DDI_VIDEO_PROCESS_INPUT_STREAM_0020;
```

<a id="d3d12ddi-video-process-output-stream-0020"></a>

### D3D12DDI_VIDEO_PROCESS_OUTPUT_STREAM_0020

```cpp
typedef struct D3D12DDI_VIDEO_PROCESS_OUTPUT_STREAM_0020
{
    D3D12DDI_HRESOURCE hDrvTexture2D;
    UINT Subresource;
} D3D12DDI_VIDEO_PROCESS_OUTPUT_STREAM_0020;
```

<a id="d3d12ddi-video-process-reference-info-data-0020"></a>

### D3D12DDI_VIDEO_PROCESS_REFERENCE_INFO_DATA_0020

```cpp
typedef struct D3D12DDI_VIDEO_PROCESS_REFERENCE_INFO_DATA_0020
{
    UINT NodeIndex;                                                     // input
    D3D12DDI_VIDEO_PROCESS_DEINTERLACE_FLAGS_0020 DeinterlaceMode;      // input
    D3D12DDI_VIDEO_PROCESS_FILTER_FLAGS_0020 Filters;                   // input
    D3D12DDI_VIDEO_PROCESS_FEATURE_SUPPORT_FLAGS_0020 FeatureSupport;   // input
    DXGI_RATIONAL InputFrameRate;                                       // input
    DXGI_RATIONAL OutputFrameRate;                                      // input
    BOOL EnableAutoProcessing;                                          // input
    UINT PastFrames;                                                    // output
    UINT FutureFrames;                                                  // output
} D3D12DDI_VIDEO_PROCESS_REFERENCE_INFO_DATA_0020;
```

<a id="d3d12ddi-video-process-support-data-0032"></a>

### D3D12DDI_VIDEO_PROCESS_SUPPORT_DATA_0032

```cpp
typedef struct D3D12DDI_VIDEO_PROCESS_SUPPORT_DATA_0032
{
    UINT NodeIndex;                                                                                                 // input
    D3D12DDI_VIDEO_SAMPLE_DESCRIPTION_0020 InputSample;                                                             // input
    D3D12DDI_VIDEO_FIELD_TYPE_0020 InputFieldType;                                                                  // input
    D3D12DDI_VIDEO_FRAME_STEREO_FORMAT_0020 InputStereoFormat;                                                      // input
    DXGI_RATIONAL InputFrameRate;                                                                                   // input
    D3D12DDI_VIDEO_FORMAT_DESCRIPTION_0020 OutputFormat;                                                            // input
    D3D12DDI_VIDEO_FRAME_STEREO_FORMAT_0020 OutputStereoFormat;                                                     // input
    DXGI_RATIONAL OutputFrameRate;                                                                                  // input
    D3D12DDI_VIDEO_PROCESS_SUPPORT_FLAGS_0022 SupportFlags;                                                         // output
    D3D12DDI_VIDEO_SCALE_SUPPORT_0032 ScaleSupport;                                                                 // output
    D3D12DDI_VIDEO_PROCESS_FEATURE_SUPPORT_FLAGS_0020 FeatureSupport;                                               // output
    D3D12DDI_VIDEO_PROCESS_DEINTERLACE_FLAGS_0020 DeinterlaceSupport;                                               // output
    D3D12DDI_VIDEO_PROCESS_AUTO_PROCESSING_FLAGS_0022 AutoProcessingSupport;                                        // output
    D3D12DDI_VIDEO_PROCESS_FILTER_FLAGS_0020 FilterSupport;                                                         // output
    D3D12DDI_VIDEO_PROCESS_FILTER_RANGE_0020 FilterRangeSupport[D3D12DDI_VIDEO_PROCESS_MAX_FILTERS_0020];           // output
} D3D12DDI_VIDEO_PROCESS_SUPPORT_DATA_0032;
```

<a id="d3d12ddi-video-processor-input-stream-desc-0032"></a>

### D3D12DDI_VIDEO_PROCESSOR_INPUT_STREAM_DESC_0032

```cpp
typedef struct D3D12DDI_VIDEO_PROCESSOR_INPUT_STREAM_DESC_0032
{
    DXGI_FORMAT Format;
    DXGI_COLOR_SPACE_TYPE ColorSpace;
    DXGI_RATIONAL SourceAspectRatio;
    DXGI_RATIONAL DestinationAspectRatio;
    DXGI_RATIONAL FrameRate;
    D3D12DDI_VIDEO_SIZE_RANGE_0032 SourceSizeRange;
    D3D12DDI_VIDEO_SIZE_RANGE_0032 DestinationSizeRange;
    BOOL EnableOrientation;
    D3D12DDI_VIDEO_PROCESS_FILTER_FLAGS_0020 FilterFlags;
    D3D12DDI_VIDEO_FRAME_STEREO_FORMAT_0020 StereoFormat;
    D3D12DDI_VIDEO_FIELD_TYPE_0020 FieldType;
    D3D12DDI_VIDEO_PROCESS_DEINTERLACE_FLAGS_0020 DeinterlaceMode;
    BOOL EnableAlphaBlending;
    D3D12DDI_VIDEO_PROCESS_LUMA_KEY_0020 LumaKey;
    UINT NumPastFrames;
    UINT NumFutureFrames;
    BOOL EnableAutoProcessing;
} D3D12DDI_VIDEO_PROCESSOR_INPUT_STREAM_DESC_0032;
```

<a id="d3d12ddi-video-process-output-stream-desc-0032"></a>

### D3D12DDI_VIDEO_PROCESS_OUTPUT_STREAM_DESC_0032

```cpp
typedef struct D3D12DDI_VIDEO_PROCESS_OUTPUT_STREAM_DESC_0032
{
    DXGI_FORMAT Format;
    DXGI_COLOR_SPACE_TYPE ColorSpace;
    D3D12DDI_VIDEO_PROCESS_ALPHA_FILL_MODE_0020 AlphaFillMode;
    UINT AlphaFillModeSourceStreamIndex;
    FLOAT BackgroundColor[4];
    DXGI_RATIONAL FrameRate;
    BOOL EnableStereo;
} D3D12DDI_VIDEO_PROCESS_OUTPUT_STREAM_DESC_0032;
```

<a id="d3d12ddiarg-create-video-processor-0032"></a>

### D3D12DDIARG_CREATE_VIDEO_PROCESSOR_0032

```cpp
typedef struct D3D12DDIARG_CREATE_VIDEO_PROCESSOR_0032
{
    UINT NodeMask;
    D3D12DDI_VIDEO_PROCESS_OUTPUT_STREAM_DESC_0032 OutputStream;
    D3D12DDI_VIDEO_PROCESSOR_INPUT_STREAM_DESC_0032* pInputStreams;
    UINT NumInputStreams;
} D3D12DDIARG_CREATE_VIDEO_PROCESSOR_0032;
```

<a id="d3d12ddi-video-processor-size-data-0032"></a>

### D3D12DDI_VIDEO_PROCESSOR_SIZE_DATA_0032

```cpp
typedef struct D3D12DDI_VIDEO_PROCESSOR_SIZE_DATA_0032
{
    D3D12DDIARG_CREATE_VIDEO_PROCESSOR_0032 VideoProcessorDesc;         // input
    UINT64 MemoryPoolL0Size;                                            // output
    UINT64 MemoryPoolL1Size;                                            // output
} D3D12DDI_VIDEO_PROCESSOR_SIZE_DATA_0032;
```

<a id="d3d12ddi-video-processor-input-stream-desc-0043"></a>

### D3D12DDI_VIDEO_PROCESSOR_INPUT_STREAM_DESC_0043

```cpp
typedef struct D3D12DDI_VIDEO_PROCESSOR_INPUT_STREAM_DESC_0043
{
    DXGI_FORMAT Format;
    DXGI_COLOR_SPACE_TYPE ColorSpace;
    DXGI_RATIONAL SourceAspectRatio;
    DXGI_RATIONAL DestinationAspectRatio;
    DXGI_RATIONAL FrameRate;
    D3D12DDI_VIDEO_SIZE_RANGE_0032 SourceSizeRange;
    D3D12DDI_VIDEO_SIZE_RANGE_0032 DestinationSizeRange;
    BOOL EnableOrientation;
    D3D12DDI_VIDEO_PROCESS_FILTER_FLAGS_0020 FilterFlags;
    D3D12DDI_VIDEO_FRAME_STEREO_FORMAT_0020 StereoFormat;
    D3D12DDI_VIDEO_PROCESS_DEINTERLACE_FLAGS_0020 DeinterlaceMode;
    BOOL EnableAlphaBlending;
    D3D12DDI_VIDEO_PROCESS_LUMA_KEY_0020 LumaKey;
    UINT NumPastFrames;
    UINT NumFutureFrames;
    BOOL EnableAutoProcessing;
} D3D12DDI_VIDEO_PROCESSOR_INPUT_STREAM_DESC_0043;
```

<a id="d3d12ddiarg-create-video-processor-0043"></a>

### D3D12DDIARG_CREATE_VIDEO_PROCESSOR_0043

```cpp
typedef struct D3D12DDIARG_CREATE_VIDEO_PROCESSOR_0043
{
    UINT NodeMask;
    D3D12DDI_VIDEO_PROCESS_OUTPUT_STREAM_DESC_0032 OutputStream;
    D3D12DDI_VIDEO_PROCESSOR_INPUT_STREAM_DESC_0043* pInputStreams;
    UINT NumInputStreams;
} D3D12DDIARG_CREATE_VIDEO_PROCESSOR_0043;
```

<a id="d3d12ddi-video-processor-size-data-0043"></a>

### D3D12DDI_VIDEO_PROCESSOR_SIZE_DATA_0043

```cpp
typedef struct D3D12DDI_VIDEO_PROCESSOR_SIZE_DATA_0043
{
    D3D12DDIARG_CREATE_VIDEO_PROCESSOR_0043 VideoProcessorDesc;         // input
    UINT64 MemoryPoolL0Size;                                            // output
    UINT64 MemoryPoolL1Size;                                            // output
} D3D12DDI_VIDEO_PROCESSOR_SIZE_DATA_0043;
```

<a id="d3d12ddi-video-process-transform-0032"></a>

### D3D12DDI_VIDEO_PROCESS_TRANSFORM_0032

```cpp
typedef struct D3D12DDI_VIDEO_PROCESS_TRANSFORM_0032
{
    D3D12DDI_RECT SourceRectangle;
    D3D12DDI_RECT DestinationRectangle;
    D3D12DDI_VIDEO_PROCESS_ORIENTATION_0020 Orientation;
} D3D12DDI_VIDEO_PROCESS_TRANSFORM_0032;
```

<a id="d3d12ddi-video-process-input-stream-rate-info-0032"></a>

### D3D12DDI_VIDEO_PROCESS_INPUT_STREAM_RATE_INFO_0032

```cpp
typedef struct D3D12DDI_VIDEO_PROCESS_INPUT_STREAM_RATE_INFO_0032
{
    UINT OutputIndex;
    UINT InputFrameOrField;
} D3D12DDI_VIDEO_PROCESS_INPUT_STREAM_RATE_INFO_0032;
```

<a id="d3d12ddiarg-video-process-input-stream-arguments-0032"></a>

<a id="d3d12ddiarg-video-process-output-stream-arguments-0032"></a>

### D3D12DDIARG_VIDEO_PROCESS_OUTPUT_STREAM_ARGUMENTS_0032

```cpp
typedef struct D3D12DDIARG_VIDEO_PROCESS_OUTPUT_STREAM_ARGUMENTS_0032
{
    D3D12DDI_VIDEO_PROCESS_OUTPUT_STREAM_0020 OutputStream[2];
    D3D12DDI_RECT TargetRectangle;
} D3D12DDIARG_VIDEO_PROCESS_OUTPUT_STREAM_ARGUMENTS_0032;
```

<a id="d3d12ddiarg-video-process-input-stream-arguments-0043"></a>

<a id="pfnd3d12ddi-calcprivatevideoprocessorsize-0032"></a>

<a id="pfnd3d12ddi-createvideoprocessor-0032"></a>

<a id="pfnd3d12ddi-calcprivatevideoprocessorsize-0043"></a>

<a id="pfnd3d12ddi-createvideoprocessor-0043"></a>

<a id="pfnd3d12ddi-destroyvideoprocessor-0021"></a>

### PFND3D12DDI_DESTROYVIDEOPROCESSOR_0021

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_DESTROYVIDEOPROCESSOR_0021 )( D3D12DDI_HDEVICE hDrvDevice, D3D12DDI_HVIDEOPROCESSOR_0020 hDrvVideoProcessor );
```

<a id="pfnd3d12ddi-video-process-frame-0032"></a>

<a id="pfnd3d12ddi-video-process-frame-0043"></a>

<a id="process-ddi-associations"></a>

<a id="callback-responsibilities-and-table-associations"></a>

### DDI responsibilities and table associations

#### Driver processor sizing

This method is used to calculate the driver object size. The Direct3D runtime allocates memory for storing the <ins><!-- d3d12-review-inline:begin:video-process:P-ddi-size-summary:0:modified:source-07fb10e0933b44e4-0-0 -->driver's<!-- d3d12-review-inline:end:video-process:P-ddi-size-summary:0:modified:source-07fb10e0933b44e4-0-0 --></ins> CPU object that represents the video processor.

##### Parameters

`hDrvDevice`

<ins><!-- d3d12-review-inline:begin:video-process:weekend-vi05-size-device:0:modified:device-handle -->Handle to the driver's device.<!-- d3d12-review-inline:end:video-process:weekend-vi05-size-device:0:modified:device-handle --></ins>

`pArgs`

The arguments used to create a video processor.

##### Return values

Returns the size of the video processor in bytes.

#### Driver processor creation

The *pfnCreateVideoProcessor* function creates a video processor.

##### Parameters

`hDrvDevice`

<ins><!-- d3d12-review-inline:begin:video-process:weekend-vi05-create-device:0:modified:device-handle -->Handle to the driver's device.<!-- d3d12-review-inline:end:video-process:weekend-vi05-create-device:0:modified:device-handle --></ins>

`pArgs`

The arguments used to create a video processor.

`hDrvVideoProcessor`

The video processor.

#### Driver processor destruction

The *pfnDestroyVideoProcessor* function destroys a video processor.

##### Parameters

`hDrvDevice`

The handle of a device driver.

`hDrvVideoProcessor`

The handle of a video processor.

##### Return values

None

<a id="current-process-frame-ddi"></a>

#### Driver frame processing

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_VIDEO_PROCESS_FRAME_0106) (
    D3D12DDI_HCOMMANDLIST hDrvCommandList,
    D3D12DDI_HVIDEOPROCESSOR_0020 hDrvVideoProcessor,
    const D3D12DDIARG_VIDEO_PROCESS_OUTPUT_STREAM_ARGUMENTS_0032*   pOutputParameters,
    const D3D12DDIARG_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS_0106*    pInputStreamParameters,
    UINT NumInputStreams
    );
```

Performs a video processing operation on one or more input samples and writes the result to an output surface<ins><!-- d3d12-review-inline:begin:video-process:P-ddi-process-summary:0:authored:source-351b63e29a4d49f2-0-0 -->.<!-- d3d12-review-inline:end:video-process:P-ddi-process-summary:0:authored:source-351b63e29a4d49f2-0-0 --></ins>

##### Parameters

`hDrvCommandList`

The command list used to record this process frames command.

`hDrvVideoProcessor`

The video processor instance to use for this video process call. The video processor holds state for a video processing session, including required intermediate memory, cached processing data, or other temporary working space.

`pOutputParameters`

<ins><!-- d3d12-review-inline:begin:video-process:P-ddi-process-Parameters:5 -->The output arguments for the video process. The available parameters are in the [D3D12DDIARG_VIDEO_PROCESS_OUTPUT_STREAM_ARGUMENTS_0032](#d3d12ddiarg-video-process-output-stream-arguments-0032) structure.<!-- d3d12-review-inline:end:video-process:P-ddi-process-Parameters:5 --></ins>

`pInputStreamParameters`

<ins><!-- d3d12-review-inline:begin:video-process:P-ddi-process-Parameters:7 -->Specifies an array of input parameters. The available parameters are in the [D3D12DDIARG_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS_0106](#process-input-arguments) structure.<!-- d3d12-review-inline:end:video-process:P-ddi-process-Parameters:7 --></ins>

`NumInputStreams`

The count of input streams.

##### Return values

None

<a id="current-processor-abi"></a>

### Current processor creation and argument layouts

```cpp
typedef enum D3D12DDI_VIDEO_PROCESS_LUT_TRANSFORM_CONFIGURATION_FLAGS_0111_0
{
    D3D12DDI_VIDEO_PROCESS_LUT_TRANSFORM_CONFIGURATION_FLAG_0111_0_NONE = 0x0,
    D3D12DDI_VIDEO_PROCESS_LUT_TRANSFORM_CONFIGURATION_FLAG_0111_0_ENABLE = 0x1,
} D3D12DDI_VIDEO_PROCESS_LUT_TRANSFORM_CONFIGURATION_FLAGS_0111_0;
```

```cpp
typedef enum D3D12DDI_VIDEO_PROCESS_3DLUT_INTERPOLATION_MODE_0106
{
    D3D12DDI_VIDEO_PROCESS_3DLUT_INTERPOLATION_MODE_0106_TRILINEAR = 0,
    D3D12DDI_VIDEO_PROCESS_3DLUT_INTERPOLATION_MODE_0106_TETRAHEDRAL = 1,
} D3D12DDI_VIDEO_PROCESS_3DLUT_INTERPOLATION_MODE_0106;
```

```cpp
typedef enum D3D12DDI_VIDEO_PROCESS_3DLUT_TABLE_DIMENSION_0106
{
    D3D12DDI_VIDEO_PROCESS_3DLUT_TABLE_DIMENSION_0106_17x17x17 = 0,
    D3D12DDI_VIDEO_PROCESS_3DLUT_TABLE_DIMENSION_0106_33x33x33 = 1,
    D3D12DDI_VIDEO_PROCESS_3DLUT_TABLE_DIMENSION_0106_45x45x45 = 2,
    D3D12DDI_VIDEO_PROCESS_3DLUT_TABLE_DIMENSION_0106_65x65x65 = 3,
} D3D12DDI_VIDEO_PROCESS_3DLUT_TABLE_DIMENSION_0106;
```

```cpp
typedef struct D3D12DDI_VIDEO_PROCESS_LUT_TRANSFORM_CONFIGURATION_0111_0
{
    D3D12DDI_VIDEO_PROCESS_LUT_TRANSFORM_CONFIGURATION_FLAGS_0111_0 ConfigFlags;
    DXGI_COLOR_SPACE_TYPE UpsampledChromaInput;
    DXGI_FORMAT Format1DLUT;
    DXGI_FORMAT Format3DLUT;
    DXGI_COLOR_SPACE_TYPE ColorSpace3DLUTOutput;
    D3D12DDI_VIDEO_PROCESS_3DLUT_INTERPOLATION_MODE_0106 Interpolation3DLUT;
    D3D12DDI_VIDEO_PROCESS_3DLUT_TABLE_DIMENSION_0106 Dimension3DLUT;
} D3D12DDI_VIDEO_PROCESS_LUT_TRANSFORM_CONFIGURATION_0111_0;
```

```cpp
typedef struct D3D12DDI_VIDEO_PROCESSOR_INPUT_STREAM_DESC_0106
{
    DXGI_FORMAT Format;
    DXGI_COLOR_SPACE_TYPE ColorSpace;
    DXGI_RATIONAL SourceAspectRatio;
    DXGI_RATIONAL DestinationAspectRatio;
    DXGI_RATIONAL FrameRate;
    D3D12DDI_VIDEO_SIZE_RANGE_0032 SourceSizeRange;
    D3D12DDI_VIDEO_SIZE_RANGE_0032 DestinationSizeRange;
    BOOL EnableOrientation;
    D3D12DDI_VIDEO_PROCESS_FILTER_FLAGS_0020 FilterFlags;
    D3D12DDI_VIDEO_FRAME_STEREO_FORMAT_0020 StereoFormat;
    D3D12DDI_VIDEO_PROCESS_DEINTERLACE_FLAGS_0020 DeinterlaceMode;
    BOOL EnableAlphaBlending;
    D3D12DDI_VIDEO_PROCESS_LUMA_KEY_0020 LumaKey;
    UINT NumPastFrames;
    UINT NumFutureFrames;
    BOOL EnableAutoProcessing;
    D3D12DDI_VIDEO_PROCESS_LUT_TRANSFORM_CONFIGURATION_0111_0 ConfigurationLUT;
} D3D12DDI_VIDEO_PROCESSOR_INPUT_STREAM_DESC_0106;
```

```cpp
typedef struct D3D12DDIARG_CREATE_VIDEO_PROCESSOR_0106
{
    UINT NodeMask;
    D3D12DDI_VIDEO_PROCESS_OUTPUT_STREAM_DESC_0032 OutputStream;
    D3D12DDI_VIDEO_PROCESSOR_INPUT_STREAM_DESC_0106* pInputStreams;
    UINT NumInputStreams;
    D3D12DDI_HPROTECTEDRESOURCESESSION_0030 hDrvProtectedResourceSession;
} D3D12DDIARG_CREATE_VIDEO_PROCESSOR_0106;
```

```cpp
typedef enum D3D12DDI_VIDEO_PROCESS_LUT_UPDATE_FLAGS_0111_0
{
    D3D12DDI_VIDEO_PROCESS_LUT_UPDATE_FLAG_0111_0_NONE = 0x0,
    D3D12DDI_VIDEO_PROCESS_LUT_UPDATE_FLAG_0111_0_CSC = 0x1,
    D3D12DDI_VIDEO_PROCESS_LUT_UPDATE_FLAG_0111_0_1DLUT = 0x2,
    D3D12DDI_VIDEO_PROCESS_LUT_UPDATE_FLAG_0111_0_1DLUT_SPACING = 0x4,
    D3D12DDI_VIDEO_PROCESS_LUT_UPDATE_FLAG_0111_0_3DLUT = 0x8,
} D3D12DDI_VIDEO_PROCESS_LUT_UPDATE_FLAGS_0111_0;
```

```cpp
typedef struct D3D12DDI_VIDEO_PROCESS_TRANSFORM_LUT_0111_0
{
    // LUT Compound config
    D3D12DDI_VIDEO_PROCESS_LUT_TRANSFORM_CONFIGURATION_0111_0 Configuration;

    // LUT Compound flags
    D3D12DDI_VIDEO_PROCESS_LUT_UPDATE_FLAGS_0111_0 UpdateFlags;

    // CSC
    float pCSCMatrix[4][3];

    // 1DLUT
    D3D12DDI_HRESOURCE hDrv1DLUTtransform;
    UINT Subresource1DLUT;
    D3D12DDI_HRESOURCE hDrv1DLUTInputSpacing;
    UINT Subresource1DLUTInputSpacing;

    // 3DLUT
    D3D12DDI_HRESOURCE hDrv3DLUTTransform; // No subresource for Texture3D
} D3D12DDI_VIDEO_PROCESS_TRANSFORM_LUT_0111_0;
```

<a id="process-input-arguments"></a>

```cpp
typedef struct D3D12DDIARG_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS_0106
{
    D3D12DDI_VIDEO_PROCESS_INPUT_STREAM_0020 InputStream[2];
    D3D12DDI_VIDEO_PROCESS_TRANSFORM_0032 Transform;
    D3D12DDI_VIDEO_PROCESS_INPUT_STREAM_FLAGS_0020 Flags;
    D3D12DDI_VIDEO_PROCESS_INPUT_STREAM_RATE_INFO_0032 RateInfo;
    INT FilterLevels[D3D12DDI_VIDEO_PROCESS_MAX_FILTERS_0020];
    D3D12DDI_VIDEO_PROCESS_ALPHA_BLENDING_0020 AlphaBlending;
    D3D12DDI_VIDEO_FIELD_TYPE_0020 FieldType;
    D3D12DDI_VIDEO_PROCESS_TRANSFORM_LUT_0111_0 LUTMode;
} D3D12DDIARG_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS_0106;
```

```cpp
typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALCPRIVATEVIDEOPROCESSORSIZE_0106 )( D3D12DDI_HDEVICE hDrvDevice, _In_ CONST D3D12DDIARG_CREATE_VIDEO_PROCESSOR_0106* pArgs);
```

```cpp
typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATEVIDEOPROCESSOR_0106 )( D3D12DDI_HDEVICE hDrvDevice, _In_ CONST D3D12DDIARG_CREATE_VIDEO_PROCESSOR_0106* pArgs, D3D12DDI_HVIDEOPROCESSOR_0020 hDrvVideoProcessor);
```

<!-- d3d12-review-alert:begin:video-process:N-ddi-table:0:authored:migration-ef56a55287b7ff2b-0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Current table | Member | DDI typedef |
> |---|---|---|
> | `D3D12DDI_DEVICE_FUNCS_VIDEO_0110` | `pfnCalcPrivateVideoProcessorSize` | `PFND3D12DDI_CALCPRIVATEVIDEOPROCESSORSIZE_0106` |
> | `D3D12DDI_DEVICE_FUNCS_VIDEO_0110` | `pfnCreateVideoProcessor` | `PFND3D12DDI_CREATEVIDEOPROCESSOR_0106` |
> | `D3D12DDI_DEVICE_FUNCS_VIDEO_0110` | `pfnDestroyVideoProcessor` | `PFND3D12DDI_DESTROYVIDEOPROCESSOR_0021` |
> | `D3D12DDI_COMMAND_LIST_FUNCS_VIDEO_PROCESS_0106` | `pfnProcessFrame` | `PFND3D12DDI_VIDEO_PROCESS_FRAME_0106` |

<!-- d3d12-review-alert:end:video-process:N-ddi-table:0:authored:migration-ef56a55287b7ff2b-0 -->

<ins><!-- d3d12-review-inline:begin:video-process:N-ddi-table:1:authored:migration-9434527b82b2ce92-0 -->`D3D12DDICAPS_TYPE_VIDEO_0020_PROCESS_SUPPORT` uses
`D3D12DDI_VIDEO_PROCESS_SUPPORT_DATA_0032` for the selected support layout;
`D3D12DDICAPS_TYPE_VIDEO_0020_PROCESS_REFERENCE_INFO` uses
`D3D12DDI_VIDEO_PROCESS_REFERENCE_INFO_DATA_0020`.
`D3D12DDICAPS_TYPE_VIDEO_0020_PROCESS_MAX_INPUT_STREAMS` uses
`D3D12DDI_VIDEO_PROCESS_MAX_INPUT_STREAMS_DATA_0020`, with input node index
and output simultaneous stream limit.
`D3D12DDICAPS_TYPE_VIDEO_0032_PROCESSOR_SIZE` uses the processor size layout
appropriate to the selected DDI version, with input creation description and
output L0/L1 sizes. The device table's `pfnGetCaps` owns these capability
exchanges. The create DDI returns `HRESULT`. Success is not an NTSTATUS
contract.<!-- d3d12-review-inline:end:video-process:N-ddi-table:1:authored:migration-9434527b82b2ce92-0 --></ins>
