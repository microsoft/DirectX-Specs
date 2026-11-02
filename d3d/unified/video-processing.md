<a id="video-processing"></a>

# Video: processing reference

This subordinate reference describes the selected ordinary processing contracts
introduced by the [Video processing model](video.md#video-processing-model).
A processor fixes the input and output
stream descriptions; each processing call supplies the current surfaces,
reference surfaces and operation arguments. Capability results apply to the
queried format, color-space, size, field, stereo and rate combination, not to
arbitrary combinations of individually reported features.

This is a **qualified draft**. The qualifications below distinguish published
contracts and scoped runtime validation from unestablished algorithm,
precision and hardware guarantees.

The [command-list annotation reference](diagnostics.md#command-list-annotations)
defines the three internal BeginEvent/EndEvent/SetMarker support methods
on `ID3D12VideoProcessCommandList`. Their recording and allocator-data lifetime
follows [common annotation state](command-list-state.md#annotations), not
a new video processing mode or GPU synchronization operation.

<a id="process-model"></a>

## Processing model and shared contracts

The compact route is [capabilities](#process-discovery),
[processor creation and reflection](#process-objects), and
[recording](#process-recording). The subordinate
[stream types](#process-stream-types), [capability values](#process-capability-types)
and [driver reference](#process-driver) provide the operative details.

The shared [format](video-decode.md#d3d12-video-format),
[sample](video-decode.md#d3d12-video-sample),
[size range](video-decode.md#d3d12-video-size-range),
[scale support](video-decode.md#d3d12-video-scale-support) and
[scale flags](video-decode.md#d3d12-video-scale-support-flags) retain their
canonical definitions. Processing uses these types without changing their
layout or interpreting a format alone as a color space.

[CPU threading](execution.md#threading),
[submission threading](execution.md#submission-threading),
[queue types](execution.md#command-list-types),
[submission and ordering](execution.md#submission), and
[recording storage](execution.md#command-storage) retain their shared owners.
Processing uses a command list and allocator of type
`D3D12_COMMAND_LIST_TYPE_VIDEO_PROCESS`, submitted to a queue of that type.
Recording and submission must use compatible device/node associations for
the processor, list, allocator, queue and picture-resource objects.
The [creation rules](execution.md#creation) require matching allocator/list
types, and [submission validation](execution.md#validation) requires matching
queue/list types and compatible node masks.

[Object/resource lifetime](execution.md#lifetime),
[completion and lifetime](execution.md#completion-lifetime), and the
[video resource contract](video.md#video-resource-contract) own lifetime,
completion and residency. The processor is an
`ID3D12Pageable` object, not image storage or a graphics pipeline-state object.
The application must keep its processor, current/reference inputs and output
resources alive for every recorded use that will execute,
including uses in unsubmitted recordings, and until the corresponding GPU
uses finish. Residency for GPU use follows the video resource contract.
Discarding an unsubmitted recording is distinct from completing
an executed one. Resetting the command-list object does not complete old GPU
uses or reclaim the old recording's allocator storage. CPU argument structures and arrays
are recording inputs, not GPU buffers; the nested-pointer qualification below
does not extend CPU storage into a new GPU memory model.

Processing reads current and reference pictures and writes output pictures.
The corresponding legacy states are `D3D12_RESOURCE_STATE_VIDEO_PROCESS_READ`
and `D3D12_RESOURCE_STATE_VIDEO_PROCESS_WRITE`; enhanced access/layout rules
are defined by [video process barriers](synchronization.md#process-enhanced-barrier),
and [legacy process barriers](synchronization.md#process-resource-barrier)
retain their full declaring owner. There is no implicit transition, fence wait,
graphics binding or application picture-resource allocation in `ProcessFrames`/`ProcessFrames1`.
Ordering with decode, graphics, compute or another queue follows the shared
submission and synchronization contracts.

[Predication](counters-queries-and-predication.md#videoprocess-setpredication)
and [its operation matrix](counters-queries-and-predication.md#predication-operation-matrix)
own conditional processing. [Process queries](counters-queries-and-predication.md#videoprocess-beginquery)
and [resolution](counters-queries-and-predication.md#videoprocess-resolvequerydata)
retain their declarations and query lifecycle; they are not processor
capability queries.

Encoding's lower-resolution frame-analysis route contributes the [reference-only DPB scaling contract](video-encoding-controls.md#source-s08-032): the DPB_ENCODER_RESOURCES scale capability, one reference-only input, matched dimension/mip/format/reference-only flags, full-surface requirements, disabled transforms and processor-description restrictions. Its rectangle qualification remains explicit. Ordinary readable reconstructed textures retain the ordinary processing path; the scale flag's [shared declaration](video-decode.md#d3d12-video-scale-support-flags) remains canonical.

<a id="process-discovery"></a>

## Capability queries

The full declaring entry for
[`ID3D12VideoDevice::CheckFeatureSupport`](video-decode.md#video-check-feature-support)
owns the common protocol and return values. For each processing case below,
`FeatureSupportDataSize` must equal `sizeof` the named payload. Initialize its
input fields before the call; inspect output fields only on success.
`NodeIndex` is a zero-based node index, whereas the processor-size query and
creation take a `NodeMask`. A successful query does not itself mean that the
requested processing operation is supported.

These are fixed payloads, not capacity/MORE_DATA enumerations.
`FilterRangeSupport` is an embedded 32-element array in PROCESS_SUPPORT,
not a caller-allocated pointer. PROCESS_REFERENCE_INFO returns scalar counts;
PROCESS_MAX_INPUT_STREAMS returns a scalar limit. PROCESSOR_SIZE takes an
input array of exactly `NumInputStreamDescs` descriptions and reports
allocation sizes; it does not allocate or return stream descriptions.

| `D3D12_FEATURE_VIDEO` case | Value | Payload | Inputs | Outputs |
|---|---|---|---|---|
| `D3D12_FEATURE_VIDEO_PROCESS_SUPPORT` | 5 | [`D3D12_FEATURE_DATA_VIDEO_PROCESS_SUPPORT`](#d3d12-feature-data-video-process-support) | `NodeIndex`, `InputSample`, `InputFieldType`, `InputStereoFormat`, `InputFrameRate`, `OutputFormat`, `OutputStereoFormat`, `OutputFrameRate` | `SupportFlags`, `ScaleSupport`, `FeatureSupport`, `DeinterlaceSupport`, `AutoProcessingSupport`, `FilterSupport`, `FilterRangeSupport[32]` |
| `D3D12_FEATURE_VIDEO_PROCESS_MAX_INPUT_STREAMS` | 6 | [`D3D12_FEATURE_DATA_VIDEO_PROCESS_MAX_INPUT_STREAMS`](#d3d12-feature-data-video-process-max-input-streams) | `NodeIndex` | `MaxInputStreams` |
| `D3D12_FEATURE_VIDEO_PROCESS_REFERENCE_INFO` | 7 | [`D3D12_FEATURE_DATA_VIDEO_PROCESS_REFERENCE_INFO`](#d3d12-feature-data-video-process-reference-info) | `NodeIndex`, `DeinterlaceMode`, `Filters`, `FeatureSupport`, `InputFrameRate`, `OutputFrameRate`, `EnableAutoProcessing` | `PastFrames`, `FutureFrames` |
| `D3D12_FEATURE_VIDEO_PROCESSOR_SIZE` | 9 | [`D3D12_FEATURE_DATA_VIDEO_PROCESSOR_SIZE`](#d3d12-feature-data-video-processor-size) | `NodeMask`, `pOutputStreamDesc`, `NumInputStreamDescs`, `pInputStreamDescs` | `MemoryPoolL0Size`, `MemoryPoolL1Size` |

PROCESS_SUPPORT describes the actual input sample (including width, height,
DXGI format and color space), input field/stereo mode and input rate, together
with output format/color space, stereo mode and output rate. The
`SUPPORTED` bit establishes support for that conversion tuple; the remaining
outputs describe scaling and supported processing options for that tuple.
`ScaleSupport.OutputSizeRange` and its flags constrain output sizes; supported
filter bits and `FilterRangeSupport` constrain enabled filters and their levels.
PROCESS_MAX_INPUT_STREAMS is the node's simultaneous enabled-stream limit,
not a guarantee that every tuple or multi-stream feature combination works.
PROCESS_REFERENCE_INFO describes the selected deinterlace, filters, features,
rates and automatic-processing choice; its counts determine the processor's
past/future reference requirements.

**Scoped runtime validation:** the inspected ordinary query path rejects an
invalid node index or malformed input with `E_INVALIDARG`. An unsupported
input/output format can instead complete with `S_OK` and no `SUPPORTED` bit.
Creation validates each stream's conversion/scaling tuple and requested
features and reference counts. These checks do not prove an adapter's
algorithms, support for an arbitrary combination of features, or a reservation
of resources after a successful query.

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

The node mask specifying the physical adapter on which the video processor will be used. For single GPU operation, set this to zero. If there are multiple GPU nodes, set a bit to identify the node, i.e. the device's physical adapter, on which the video processor will be used. Each bit in the mask corresponds to a single node. Only 1 bit may be set.

`pOutputStreamDesc`

A pointer to a [D3D12_VIDEO_PROCESS_OUTPUT_STREAM_DESC](#d3d12-video-process-output-stream-desc) structure describing the output stream.

`NumInputStreamDescs`

The number of input streams provided in the *pInputStreamDescs* parameter.

`pInputStreamDescs`

A pointer to a list of [D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC](#d3d12-video-process-input-stream-desc) structures describing the input streams. The number of structures provided should match the value specified in the *NumInputStreamDescs* parameter.

`riid`

The globally unique identifier (GUID) for the video processor interface.

`ppVideoProcessor`

A pointer to a memory block that receives a pointer to the [ID3D12VideoProcessor](https://learn.microsoft.com/en-us/windows/win32/api/d3d12video/nn-d3d12video-id3d12videoprocessor) interface.

#### Return values

This method returns HRESULT.

#### Remarks

To change the parameters set during creation, you must recreate the video processor object.

The application must provide at least one input stream description and no more
simultaneously enabled streams than the node's reported limit. The creation
descriptions fix formats/color spaces, rates, size ranges, stereo, deinterlace,
filter, orientation, blending, luma-key and automatic-processing choices.
The input/reference and output resources are supplied later, not allocated
by this call. The runtime copies the creation descriptions; their caller-owned
storage is not retained as mutable processor state.

On successful creation, `ppVideoProcessor` receives a caller-owned COM interface
reference. The caller releases that reference under the normal
[reference-counting and recorded-use lifetime rules](execution.md#lifetime).
The application must preserve the processor and referenced resources for
unsubmitted recordings that will execute and for outstanding GPU uses; this
does not assume that recording automatically takes a COM reference on its behalf.

**Scoped runtime validation:** invalid node selection, zero input streams,
invalid size ranges, a failed/unsupported conversion query, unsupported
requested options or mismatched required reference counts are rejected with
`E_INVALIDARG` on the inspected ordinary creation path. Interface selection,
allocation and device-removal failures can propagate; the short public method
page does not supply an exhaustive HRESULT catalog.

<a id="video-processor-get-node-mask"></a>

### ID3D12VideoProcessor::GetNodeMask

#### Declaration

```cpp
UINT GetNodeMask();
```

#### Behavior

Gets the node mask specifying the physical adapter on which the video processor will be used.

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

The size of the array pointed to by *pInputStreamDescs*. Get the number of input stream descriptions associated with the video processor by calling [ID3D12VideoProcessor::GetNumInputStreamDescs](#video-processor-get-num-input-stream-descs).

`pInputStreamDescs`

An array of [D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC](#d3d12-video-process-input-stream-desc) structures that is populated with the input stream descriptions associated with the video processor.

#### Return values

This method returns HRESULT.

#### Reflection contract

`NumInputStreamDescs` must equal the value returned by
`GetNumInputStreamDescs`, and `pInputStreamDescs` must address that many writable
descriptions. This is an exact-count copy, not a count query or a capacity/prefix
protocol. The inspected reflection path returns `E_INVALIDARG` for a mismatched
count or null output pointer, otherwise `S_OK`. It returns copied creation
descriptions; modifying the copies does not reconfigure the processor.

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

The returned output description is a value copy of the creation description.
`GetNodeMask` returns the creation node selection; `GetNumInputStreamDescs`
returns the immutable number of creation descriptions. None of these methods
records GPU work or reports mutable per-call picture arguments.

<a id="process-recording"></a>

## Recording lifecycle and processing calls

`ID3D12VideoProcessCommandList` records video process work; its version-1
interface adds `ProcessFrames1`. `Reset` selects a compatible process allocator
and opens a new recording; `ClearState` changes state within the recording, without reclaiming
allocator storage or submitting work. Neither method takes a graphics PSO.
Both reset predication to disabled (null buffer, zero offset,
`D3D12_PREDICATION_OP_EQUAL_ZERO`).

The shared [recording boundaries](command-list-state.md#recording-boundaries),
[allocator storage](execution.md#command-storage) and
[threading rules](execution.md#threading) remain applicable.
Closing is not GPU completion. The runtime close wrapper can perform queued
query-resolution work before reaching the close DDI; it is not merely a
direct driver call.

<a id="process-clear-state"></a>

### ID3D12VideoProcessCommandList::ClearState

#### Declaration

```cpp
void ClearState();
```

#### Behavior

Resets the state of a video process command list back to the state it was in when the command list was created.

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

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

Returns **S\_OK** if successful; otherwise, returns one of the following values:

- **E\_FAIL** if the command list has already been closed, or an invalid API was called during command list recording.
- **E\_OUTOFMEMORY** if the operating system ran out of memory during recording.
- **E\_INVALIDARG** if an invalid argument was passed to the command list API during recording.

See [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/win32/direct3d12/d3d12-graphics-reference-returnvalues) for other possible return values.

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

A pointer to the [ID3D12CommandAllocator](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nn-d3d12-id3d12commandallocator) object that the device creates command lists from.

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

Returns **S\_OK** if successful; otherwise, returns one of the following values:

- **E\_FAIL** if the command list was not in the "closed" state when the **Reset** call was made, or the per-device limit would have been exceeded.
- **E\_OUTOFMEMORY** if the operating system ran out of memory.
- **E\_INVALIDARG** if the allocator is currently being used with another command list in the "recording" state or if the specified allocator was created with the wrong type.

See [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/win32/direct3d12/d3d12-graphics-reference-returnvalues) for other possible return values.

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

The [shared processing argument rules](#process-argument-rules) specify
stream correspondence, resource roles, field-type versioning and validation
for both processing calls.

#### Parameters

`pVideoProcessor`

A pointer to an [ID3D12VideoProcessor](https://learn.microsoft.com/en-us/windows/win32/api/d3d12video/nn-d3d12video-id3d12videoprocessor) interface representing a video processor instance.

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

A pointer to an [ID3D12VideoProcessor](https://learn.microsoft.com/en-us/windows/win32/api/d3d12video/nn-d3d12video-id3d12videoprocessor) interface representing a video processor instance.

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

`pVideoProcessor` supplies the immutable configuration.
`NumInputStreams` must match its number of input stream descriptions;
`pInputArguments[i]` corresponds to creation description `i`.
`pOutputArguments` describes the output views and target rectangle.
The current inputs and temporal references are Texture2D surfaces with
subresources, not descriptor-table bindings; their formats must match the
corresponding processor descriptions.

`ProcessFrames` uses each creation description's `FieldType`.
`ProcessFrames1` uses the `FieldType` in each
`D3D12_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS1` for that call. This permits mixed
progressive/interlaced content without recreating the processor merely to
change field type; it does not remove capability requirements for the actual
field type and processing tuple.

**Scoped validation:** the inspected path checks stream-count equality,
current/reference/output Texture2D dimensions and formats, subresource bounds,
single mip level and plane-zero selection of planar pictures. It rejects
reserved pictures and applies the shared video architecture/heap restrictions.
The path checks nonnegative, non-inverted rectangles, configured source and
nonempty destination size ranges, enabled orientation/blending, and known
input flags. These observations are not an exhaustive error table or a
hardware-layout guarantee; a missing retail check is not permission.
The void recording methods report recording failure through command-list
error handling and `Close`, not a per-frame HRESULT.

**Nested CPU-pointer qualification:** the retained public reference-set contract
allows null subresource arrays to mean subresource zero. The inspected
validation path directly indexes these arrays, while recording forwards some
subresource pointers to the driver. This draft retains the published default
but does not claim that every implementation honors it, or establish a
universal post-call release point for every nested CPU array. Resource/object
lifetime through GPU completion is a separate shared contract.

<a id="process-query-payloads"></a>

## Processing query payload reference

<a id="d3d12-feature-data-video-process-support"></a>

### D3D12_FEATURE_DATA_VIDEO_PROCESS_SUPPORT

Provides data for calls to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) when the feature specified is [D3D12_FEATURE_VIDEO_PROCESS_SUPPORT](https://learn.microsoft.com/en-us/windows/win32/api/d3d12video/ne-d3d12video-d3d12_feature_video).

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

A member of the [D3D12_VIDEO_PROCESS_SUPPORT_FLAGS](#d3d12-video-process-support-flags) indicating whether the requested format and colorspace conversion is supported. This value is populated by the call to **ID3D12VideoDevice::CheckFeatureSupport**.

`ScaleSupport`

A [D3D12_VIDEO_SCALE_SUPPORT](video-decode.md#d3d12-video-scale-support) structure specifying the supported scaling capabilities. This value is populated by the call to **ID3D12VideoDevice::CheckFeatureSupport**.

`FeatureSupport`

A bitwise OR combination of values from the [D3D12_VIDEO_PROCESS_FEATURE_FLAGS](#d3d12-video-process-feature-flags) enumeration specifying the supported video processing features. This value is populated by the call to **ID3D12VideoDevice::CheckFeatureSupport**.

`DeinterlaceSupport`

A member of the [D3D12_VIDEO_PROCESS_DEINTERLACE_FLAGS](#d3d12-video-process-deinterlace-flags) enumeration specifying the supported deinterlacing capabilities. This value is populated by the call to **ID3D12VideoDevice::CheckFeatureSupport**.

`AutoProcessingSupport`

A member of the [D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAGS](#d3d12-video-process-auto-processing-flags) specifying the supported automatic processing capabilities. This value is populated by the call to **ID3D12VideoDevice::CheckFeatureSupport**.

`FilterSupport`

A bitwise OR combination of values from the [D3D12_VIDEO_PROCESS_FILTER_FLAGS](#d3d12-video-process-filter-flags) enumeration specifying the supported video filtering features. This value is populated by the call to **ID3D12VideoDevice::CheckFeatureSupport**.

`FilterRangeSupport[32]`

An array of [D3D12_VIDEO_PROCESS_FILTER_RANGE](#d3d12-video-process-filter-range) structures representing the filter range values. This value is populated by the call to **ID3D12VideoDevice::CheckFeatureSupport**. The filter range list is embedded in this structure.

<a id="d3d12-feature-data-video-process-max-input-streams"></a>

### D3D12_FEATURE_DATA_VIDEO_PROCESS_MAX_INPUT_STREAMS

Provides data for calls to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) when the feature specified is [D3D12_FEATURE_VIDEO_PROCESS_MAX_INPUT_STREAMS](https://learn.microsoft.com/en-us/windows/win32/api/d3d12video/ne-d3d12video-d3d12_feature_video). Retrieves the maximum number of enabled input streams supported by the video processor.

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

Provides data for calls to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) when the feature specified is [D3D12_FEATURE_VIDEO_PROCESS_REFERENCE_INFO](https://learn.microsoft.com/en-us/windows/win32/api/d3d12video/ne-d3d12video-d3d12_feature_video). Retrieves the number of past and future reference frames required for the specified deinterlace mode, filter, rate conversion, or auto processing features.

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

Describes the allocation size of a video processor.

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

For single GPU operation, set this to zero. If there are multiple GPU nodes, set a bit to identify the node (the device's physical adapter) on which the video processor will be used. Each bit in the mask corresponds to a single node. Only 1 bit may be set.

`pOutputStreamDesc`

A pointer to a [D3D12_VIDEO_PROCESS_OUTPUT_STREAM_DESC](#d3d12-video-process-output-stream-desc) structure describing the output stream.

`NumInputStreamDescs`

The number of input streams provided in the *pInputStreamDescs* parameter.

`pInputStreamDescs`

A pointer to a list of [D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC](#d3d12-video-process-input-stream-desc) structures describing the input streams.

`MemoryPoolL0Size`

The allocation size of the video processor in the L0 memory pool. L0 is the physical system memory pool. When the adapter is discrete/NUMA, this pool has greater bandwidth for the CPU and less bandwidth for the GPU. When the adapter is UMA, this pool is the only one which is valid. For more information, see [Residency](https://learn.microsoft.com/en-us/windows/win32/direct3d12/residency).

`MemoryPoolL1Size`

The allocation size of the video processor in the L1 memory pool. L1 is typically known as the physical video memory pool. L1 is only available when the adapter is discrete/NUMA, and has greater bandwidth for the GPU and cannot even be accessed by the CPU. When the adapter is UMA, this pool is not available. For more information, see [Residency](https://learn.microsoft.com/en-us/windows/win32/direct3d12/residency).

<a id="process-stream-types"></a>

## Stream descriptions and operation arguments

`D3D12_VIDEO_PROCESS_STEREO_VIEWS` is 2;
`D3D12_VIDEO_PROCESS_MAX_FILTERS` is 32. The 32-element arrays reserve positions
beyond the eight defined filter indices. Disabled/reserved filter levels
are zero, not the device's reported active-filter default.

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

A value from the [DXGI_FORMAT](https://learn.microsoft.com/en-us/windows/desktop/api/dxgiformat/ne-dxgiformat-dxgi_format) enumeration specifying the format of the input stream. In the case of stereo, this format is the format of both inputs.

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

A [D3D12_VIDEO_SIZE_RANGE](video-decode.md#d3d12-video-size-range) structure representing the size of the destination rectangle. This argument specifies the destination range size this video processor must support for [ProcessFrames](#process-frames). If a destination size exceeds the range, the video processor must be recreated.

`EnableOrientation`

A boolean value specifying whether orientation is enabled for [ProcessFrames](#process-frames).

`FilterFlags`

A bitwise OR combination of one or more flags from the [D3D12_VIDEO_PROCESS_FILTER_FLAGS](#d3d12-video-process-filter-flags) enumeration specifying the filters to enable.

`StereoFormat`

A value from the [D3D12_VIDEO_FRAME_STEREO_FORMAT](#d3d12-video-frame-stereo-format) enumeration specifies whether the stream is stereo or not. A value of **D3D12\_VIDEO\_FRAME\_STEREO\_FORMAT\_SEPARATE** indicates that there will be two sets of input textures, and two sets of references for the stereo interlaced case.

`FieldType`

A value from the [D3D12_VIDEO_FIELD_TYPE](#d3d12-video-field-type) enumeration specifying the interlaced field type of the input source. When working with mixed content, use [ID3D12VideoProcessCommandList1::ProcessFrames1](#process-frames1) which supports changing the field type for each call.

`DeinterlaceMode`

A value from the [D3D12_VIDEO_PROCESS_DEINTERLACE_FLAGS](#d3d12-video-process-deinterlace-flags) enumeration specifying the deinterlace mode to use.

`EnableAlphaBlending`

A boolean value specifying whether alpha blending is enabled. Alpha blending settings are provided to [ProcessFrames](#process-frames) with the *AlphaBlending* field of the [D3D12_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS](#d3d12-video-process-input-stream-arguments) structure.

`LumaKey`

A [D3D12_VIDEO_PROCESS_LUMA_KEY](#d3d12-video-process-luma-key) structure specifying the luma key for an input stream on the video processor.

`NumPastFrames`

An integer specifying the number of past reference frames.

`NumFutureFrames`

An integer specifying the number of future reference frames.

`EnableAutoProcessing`

A boolean value specifying whether automatic processing features are enabled for the video processor.

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

A [DXGI_FORMAT](https://learn.microsoft.com/en-us/windows/desktop/api/dxgiformat/ne-dxgiformat-dxgi_format) enumeration specifying the format of the output resources.

`ColorSpace`

A [DXGI_COLOR_SPACE_TYPE](https://learn.microsoft.com/en-us/windows/desktop/api/dxgicommon/ne-dxgicommon-dxgi_color_space_type) value that specifies the colorspace for the video processor output surface.

`AlphaFillMode`

A value from the [D3D12_VIDEO_PROCESS_ALPHA_FILL_MODE](#d3d12-video-process-alpha-fill-mode) enumeration specifying the alpha fill mode for data that the video processor writes to the render target.

`AlphaFillModeSourceStreamIndex`

The zero-based index of an input stream. This parameter is used if *AlphaFillMode* is [D3D12_VIDEO_PROCESS_ALPHA_FILL_MODE_SOURCE_STREAM](#d3d12-video-process-alpha-fill-mode). Otherwise, the parameter is ignored.

`BackgroundColor[4]`

The video processor uses the background color to fill areas of the target rectangle that do not contain a video image. Areas outside the target rectangle are not affected. The meaning of the values are specified by the *ColorSpace* parameter.

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

A pointer to an array of [ID3D12Resource](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nn-d3d12-id3d12resource) surfaces. The number of elements in the array is *NumPastFrames*.

`pPastSubresources`

An array of subresource indices for the list of *ppPastFrames* textures. NULL indicates subresource 0 for each resource.

`NumFutureFrames`

The number of future reference frames provided in *ppFutureFrames*.

`ppFutureFrames`

A pointer to an array of [ID3D12Resource](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nn-d3d12-id3d12resource) surfaces. The number of elements in the array is *NumFutureFrames*.

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

An [ID3D12Resource](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nn-d3d12-id3d12resource) representing the current input field or frame.

`Subresource`

The subresource index to use of the *pTexture2D* argument.

`ReferenceSet`

A [D3D12_VIDEO_PROCESS_REFERENCE_SET](#d3d12-video-process-reference-set) containing the set of references for video processing. Some video processing algorithms require forward or backward frame references. For more information, see [D3D12_FEATURE_VIDEO_PROCESS_REFERENCE_INFO](https://learn.microsoft.com/en-us/windows/win32/api/d3d12video/ne-d3d12video-d3d12_feature_video).

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

**Coordinate qualification:** the published transform contract states that
source and destination rectangles use post-orientation coordinates and that
orientation precedes stereo-format application. This draft retains those
statements without inventing chroma-edge alignment, clipping, interpolation,
sample positions or a vendor-independent coordinate/precision algorithm.
The per-stream destination rectangle places that stream; the output target
rectangle bounds the drawn/background-filled region. They are distinct roles,
not interchangeable descriptions of one rectangle.

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

- Progressive format at normal and half rate:
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

The zero-based index number of the input frame or field. The InputFrameOrField member is a zero-based number that indicates the frame or the field number of the input surface. For example, with the following input-frame-or-field number, the driver can perform the indicated video processing:

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

Specifies input stream arguments for an input stream passed to [ID3D12VideoProcessCommandList::ProcessFrames](#process-frames).

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

An array of [D3D12_VIDEO_PROCESS_INPUT_STREAM](#d3d12-video-process-input-stream) structures containing the set of references for video processing. If the stereo format is [D3D12_VIDEO_FRAME_STEREO_FORMAT_SEPARATE](#d3d12-video-frame-stereo-format), then two sets of input streams must be supplied. For all other stereo formats, the first set of reference must be supplied, and the second should be zero initialized.

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

The common members have the same meanings as
[`D3D12_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS`](#d3d12-video-process-input-stream-arguments).
The following member supplies the per-call difference.

#### Members

`FieldType`

A value from the [D3D12_VIDEO_FIELD_TYPE](#d3d12-video-field-type) enumeration specifying the interlaced field type of the input source. When working with mixed content, use [ID3D12VideoProcessCommandList1::ProcessFrames1](#process-frames1) which supports changing the field type for each call.

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

A pointer to a [ID3D12Resource](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nn-d3d12-id3d12resource) representing the output surfaces for the video process command.

`Subresource`

The subresource index to use within the resource specified by *pTexture2D*.

<a id="d3d12-video-process-output-stream-arguments"></a>

### D3D12_VIDEO_PROCESS_OUTPUT_STREAM_ARGUMENTS

Specifies output stream arguments for the output passed to [ID3D12VideoProcessCommandList::ProcessFrames](#process-frames).

```cpp
typedef struct D3D12_VIDEO_PROCESS_OUTPUT_STREAM_ARGUMENTS
{
    D3D12_VIDEO_PROCESS_OUTPUT_STREAM OutputStream[D3D12_VIDEO_PROCESS_STEREO_VIEWS];
    D3D12_RECT TargetRectangle;
} D3D12_VIDEO_PROCESS_OUTPUT_STREAM_ARGUMENTS;
```

#### Members

`OutputStream[2]`

An array of [D3D12_VIDEO_PROCESS_OUTPUT_STREAM](#d3d12-video-process-output-stream) structures representing the output surfaces for the video process command. If stereo output is enabled, index zero contains the left output while index 1 contains the right output. If stereo output is not enabled, only index 0 is used to specify the output while index 1 should be zero initialized.

`TargetRectangle`

The target rectangle is the area within the destination surface where the output will be drawn. The target rectangle is given in pixel coordinates, relative to the destination surface.

<a id="d3d12-video-process-alpha-blending"></a>

### D3D12_VIDEO_PROCESS_ALPHA_BLENDING

Specifies alpha blending parameters for video processing. Used by the [D3D12_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS](#d3d12-video-process-input-stream-arguments) structure.

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

The planar alpha value. The value can range from 0.0 (transparent) to 1.0 (opaque). If *Enable* is FALSE, this parameter is ignored.

#### Remarks

For each pixel, the destination color value is computed as follows:

`Cd = Cs * (As * Ap * Ae) + Cd * (1.0 - As * Ap * Ae)`

where:

- Cd = The color value of the destination pixel
- Cs = The color value of the source pixel
- As = The per-pixel source alpha
- Ap = The planar alpha value
- Ae = The palette-entry alpha value, or 1.0 (palette-entry alpha values apply only to palettized color formats)

**Numeric qualification:** the published expression describes color blending;
it is not a complete precision, rounding, saturation or color-space conversion
specification. The palette-entry term does not establish support for any
palettized resource format. No universal linear-light conversion sequence,
interpolation kernel or implementation-specific automatic-processing algorithm
is inferred here.

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

| Value | Meaning |
|---|---|
| `D3D12_VIDEO_FIELD_TYPE_NONE` | The frame is progressive. |
| `D3D12_VIDEO_FIELD_TYPE_INTERLACED_TOP_FIELD_FIRST` | The frame is interlaced. The top field of each frame is displayed first. |
| `D3D12_VIDEO_FIELD_TYPE_INTERLACED_BOTTOM_FIELD_FIRST` | The frame is interlaced. The bottom field of each frame is displayed first. |

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

| Value | Meaning |
|---|---|
| `D3D12_VIDEO_FRAME_STEREO_FORMAT_NONE` | No stereo format is specified. |
| `D3D12_VIDEO_FRAME_STEREO_FORMAT_MONO` | The sample does not contain stereo data. |
| `D3D12_VIDEO_FRAME_STEREO_FORMAT_HORIZONTAL` | Frame 0 and frame 1 are packed side-by-side. |
| `D3D12_VIDEO_FRAME_STEREO_FORMAT_VERTICAL` | Frame 0 and frame 1 are packed top-to-bottom. |
| `D3D12_VIDEO_FRAME_STEREO_FORMAT_SEPARATE` | Frame 0 and frame 1 are placed in separate resources |

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

| Value | Meaning |
|---|---|
| `D3D12_VIDEO_PROCESS_SUPPORT_FLAG_NONE` | The conversion from the source format and colorspace to destination format and colorspace are not supported. |
| `D3D12_VIDEO_PROCESS_SUPPORT_FLAG_SUPPORTED` | The conversion from the source format and colorspace to destination format and colorspace are supported. |

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

| Value | Meaning |
|---|---|
| `D3D12_VIDEO_PROCESS_FEATURE_FLAG_NONE` | No features are supported. |
| `D3D12_VIDEO_PROCESS_FEATURE_FLAG_ALPHA_FILL` | The video processor can set alpha values on the output pixels. The alpha fill mode is used in [D3D12_VIDEO_PROCESS_OUTPUT_STREAM_DESC](#d3d12-video-process-output-stream-desc). [D3D12_VIDEO_PROCESS_ALPHA_FILL_MODE_OPAQUE](#d3d12-video-process-alpha-fill-mode) must be always supported. The background, destination, and source stream modes are only supported when the driver reports D3D12\_VIDEO\_PROCESS\_FEATURE\_FLAG\_ALPHA\_FILL. |
| `D3D12_VIDEO_PROCESS_FEATURE_FLAG_LUMA_KEY` | The video processor can perform luma keying. Luma keying is configured via the **LumaKey** member of the [D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC](#d3d12-video-process-input-stream-desc) structure. For more information see [D3D12_VIDEO_PROCESS_LUMA_KEY](#d3d12-video-process-luma-key). |
| `D3D12_VIDEO_PROCESS_FEATURE_FLAG_STEREO` | The video processor can support 3D stereo video. For more information, see [D3D12_VIDEO_FRAME_STEREO_FORMAT](#d3d12-video-frame-stereo-format). All drivers setting this capability must support the following stereo formats: D3D12\_VIDEO\_FRAME\_STEREO\_FORMAT\_HORIZONTAL, D3D12\_VIDEO\_FRAME\_STEREO\_FORMAT\_VERTICAL, and D3D12\_VIDEO\_FRAME\_STEREO\_FORMAT\_SEPARATE. |
| `D3D12_VIDEO_PROCESS_FEATURE_FLAG_ROTATION` | The driver can rotate the input data either 90, 180, or 270 degrees clockwise as part of the video processing operation. |
| `D3D12_VIDEO_PROCESS_FEATURE_FLAG_FLIP` | The driver can flip the input data horizontally or vertically, together or separately with a video rotation operation. |
| `D3D12_VIDEO_PROCESS_FEATURE_FLAG_ALPHA_BLENDING` | Alpha blending and a planar alpha may be set in the **AlphaBlending** member of the [D3D12_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS](#d3d12-video-process-input-stream-arguments) structure. For more information see [D3D12_VIDEO_PROCESS_ALPHA_BLENDING](#d3d12-video-process-alpha-blending). |
| `D3D12_VIDEO_PROCESS_FEATURE_FLAG_PIXEL_ASPECT_RATIO` | The driver supports changing the pixel aspect ratio. If the driver does not report this capability, then the **SourceAspectRatio** and **DestinationAspectRatio** members of [D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC](#d3d12-video-process-input-stream-desc) structure must indicate a 1:1 aspect ratio. |

**Aspect-ratio qualification:** the published 1:1 restriction above is retained.
The inspected creation validation compares the source and destination rational
fields for equality when PIXEL_ASPECT_RATIO is unavailable; that does not
establish that arbitrary equal non-unit ratios are universally legal. The exact
meaning of 1:1 and rational equivalence remains qualified rather than replaced
with an implementation-derived policy. Feature flags describe support; they
do not make every enabled option or combination universally available.

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

| Value | Meaning |
|---|---|
| `D3D12_VIDEO_PROCESS_DEINTERLACE_FLAG_NONE` | No deinterlacing capabilities are available. |
| `D3D12_VIDEO_PROCESS_DEINTERLACE_FLAG_BOB` | The video processor can perform bob deinterlacing. In bob deinterlacing, missing field lines are interpolated from the lines above and below. Bob deinterlacing does not require reference frames. |
| `D3D12_VIDEO_PROCESS_DEINTERLACE_FLAG_CUSTOM` | The video processor can perform a custom high-quality deinterlacing, which requires the number of reference frames indicated in *PastFrames* and *FutureFrames* output fields of the [D3D12_FEATURE_DATA_VIDEO_PROCESS_REFERENCE_INFO](#d3d12-feature-data-video-process-reference-info) populated by a call to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) when the feature specified is [D3D12_FEATURE_VIDEO_PROCESS_REFERENCE_INFO](https://learn.microsoft.com/en-us/windows/win32/api/d3d12video/ne-d3d12video-d3d12_feature_video). If the video processor doesn’t have the necessary number of reference frames, it falls back to bob deinterlacing. |

**Reference qualification:** the published CUSTOM description above specifies
bob fallback when the necessary references are unavailable. Processor creation
still declares the queried required counts. The selected public material does
not completely define short/null per-call reference arrays, temporal array
ordering, stream-start/end padding or the boundary between fallback and invalid
usage. This draft does not turn the fallback sentence into permission to pass
arbitrary missing or malformed references.

<a id="d3d12-video-process-filter"></a>

### D3D12_VIDEO_PROCESS_FILTER

The filter enumeration supplies zero-based indices for the filter-level and
filter-range arrays. The corresponding filter flag is `1 << filter_index`.

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

| Value | Meaning |
|---|---|
| `D3D12_VIDEO_PROCESS_FILTER_FLAG_NONE` | The video processor doesn't support any filters. |
| `D3D12_VIDEO_PROCESS_FILTER_FLAG_BRIGHTNESS` | The video processor can adjust the brightness level. |
| `D3D12_VIDEO_PROCESS_FILTER_FLAG_CONTRAST` | The video processor can adjust the contrast level. |
| `D3D12_VIDEO_PROCESS_FILTER_FLAG_HUE` | The video processor can adjust hue. |
| `D3D12_VIDEO_PROCESS_FILTER_FLAG_SATURATION` | The video processor can adjust the saturation level. |
| `D3D12_VIDEO_PROCESS_FILTER_FLAG_NOISE_REDUCTION` | The video processor can perform noise reduction. |
| `D3D12_VIDEO_PROCESS_FILTER_FLAG_EDGE_ENHANCEMENT` | The video processor can perform edge enhancement. |
| `D3D12_VIDEO_PROCESS_FILTER_FLAG_ANAMORPHIC_SCALING` | The video processor can perform anamorphic scaling. Anamorphic scaling can be used to stretch 4:3 content to a widescreen 16:9 aspect ratio. |
| `D3D12_VIDEO_PROCESS_FILTER_FLAG_STEREO_ADJUSTMENT` | For stereo 3D video, the video processor can adjust the offset between the left and right views, allowing the user to reduce potential eye strain. |

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

| Value | Meaning |
|---|---|
| `D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_NONE` | No automatic processing features are supported. |
| `D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_DENOISE` | Denoise is supported. |
| `D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_DERINGING` | Deringing is supported. |
| `D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_EDGE_ENHANCEMENT` | Edge enhancement is supported. |
| `D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_COLOR_CORRECTION` | Color correction is supported. |
| `D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_FLESH_TONE_MAPPING` | Flesh tone mapping is supported. |
| `D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_IMAGE_STABILIZATION` | Image stabilization is supported. |
| `D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_SUPER_RESOLUTION` | Enhanced image resolution is supported. |
| `D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_ANAMORPHIC_SCALING` | Anamorphic scaling is supported. |
| `D3D12_VIDEO_PROCESS_AUTO_PROCESSING_FLAG_CUSTOM` | Additional processing features, not described by the other flags, are available. |

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

| Value | Meaning |
|---|---|
| `D3D12_VIDEO_PROCESS_ORIENTATION_DEFAULT` | No change in orientation. 0 degrees. |
| `D3D12_VIDEO_PROCESS_ORIENTATION_FLIP_HORIZONTAL` | The image is flipped horizontally. |
| `D3D12_VIDEO_PROCESS_ORIENTATION_CLOCKWISE_90` | The image is rotated 90 degrees clockwise. |
| `D3D12_VIDEO_PROCESS_ORIENTATION_CLOCKWISE_90_FLIP_HORIZONTAL` | The image is rotated 90 degrees clockwise and then flipped horizontally. |
| `D3D12_VIDEO_PROCESS_ORIENTATION_CLOCKWISE_180` | The image is rotated 180 degrees clockwise. |
| `D3D12_VIDEO_PROCESS_ORIENTATION_FLIP_VERTICAL` | The image is flipped vertically. |
| `D3D12_VIDEO_PROCESS_ORIENTATION_CLOCKWISE_270` | The image is rotated 270 degrees clockwise. |
| `D3D12_VIDEO_PROCESS_ORIENTATION_CLOCKWISE_270_FLIP_HORIZONTAL` | The image is rotated 270 degrees clockwise and then flipped horizontally. |

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

| Value | Meaning |
|---|---|
| `D3D12_VIDEO_PROCESS_INPUT_STREAM_FLAG_NONE` | No flags specified. |
| `D3D12_VIDEO_PROCESS_INPUT_STREAM_FLAG_FRAME_DISCONTINUITY` | Set this flag when not processing frames in order, such as seeking between frames |
| `D3D12_VIDEO_PROCESS_INPUT_STREAM_FLAG_FRAME_REPEAT` | Set this flag when applying video process operation to the same set of inputs. |

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

| Value | Meaning |
|---|---|
| `D3D12_VIDEO_PROCESS_ALPHA_FILL_MODE_OPAQUE` | Alpha values inside the target rectangle are set to opaque. |
| `D3D12_VIDEO_PROCESS_ALPHA_FILL_MODE_BACKGROUND` | Alpha values inside the target rectangle are set to the alpha value specified in the background color. |
| `D3D12_VIDEO_PROCESS_ALPHA_FILL_MODE_DESTINATION` | Existing alpha values remain unchanged in the output surface. |
| `D3D12_VIDEO_PROCESS_ALPHA_FILL_MODE_SOURCE_STREAM` | Alpha values are taken from an input stream, scaled, and copied to the corresponding destination rectangle for that stream. The input stream is specified in the *AlphaFillModeSourceStreamIndex* member of [D3D12_VIDEO_PROCESS_OUTPUT_STREAM_DESC](#d3d12-video-process-output-stream-desc). If the input stream does not have alpha data, the video processor sets the alpha values in the target rectangle to opaque. If the input stream is disabled or the source rectangle is empty, the alpha values in the target rectangle are not modified. |

#### Remarks

**D3D12\_VIDEO\_PROCESS\_ALPHA\_FILL\_MODE\_OPAQUE** must be always supported. The background, destination, and source stream modes are only supported when the driver reports [D3D12_VIDEO_PROCESS_FEATURE_FLAG_ALPHA_FILL](#d3d12-video-process-feature-flags).

<a id="process-driver"></a>

## Published driver contracts

The runtime queries video driver capabilities, sizes/creates the driver
processor object and records processing through video command-list callbacks.
Private object bytes reported by the sizing callback are CPU driver storage;
the processor-size capability query separately reports memory-pool allocation
sizes. Neither is the application's output-picture allocation.

The layouts and callback typedefs below are selected published WDK contracts.
DDI suffixes identify contract versions; they are not new API identities or
universal hardware capability guarantees. The current creation description supplies the output and counted input
stream descriptions and protected-session association. `FieldType` is
supplied in each recorded input argument. The output stream description
and recording-output layout retain their `_0032` representations; an older
nested type name does not make that current field layout obsolete. No
one-to-one driver call is inferred for every runtime wrapper.

The shared DDI format/sample/size/scale layouts retain their
[decode capability-payload owner](video-decode.md#ddi-capability-payloads).
The immediately used processing enum declarations below are actual DDI
declarations, not application enums used as binary-layout stand-ins.
In particular, the DDI stereo enum starts with `MONO = 0`, whereas the
application enum has distinct `NONE = 0` and `MONO = 1` values; the published
DDI automatic-processing `CUSTOM` bit is `0x100`, not the application's
`0x80000000`. The DDI orientation declaration also names the value-5
180-degree/horizontal-flip alias. These are separate representations;
matching logical operation names do not authorize a binary cast or establish
an undocumented NONE/MONO default. `D3D12DDI_VIDEO_PROCESS_MAX_FILTERS_0020`
is 32, matching the published processing filter-array extent.

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

### Callback responsibilities and table associations

#### Driver processor sizing

This method is used to calculate the driver object size. The Direct3D runtime allocates memory for storing the driver's CPU object that represents the video processor.

##### Parameters

`hDrvDevice`

A handle to the display device (graphics context).

`pArgs`

The arguments used to create a video processor.

##### Return values

Returns the size of the video processor in bytes.

#### Driver processor creation

The *pfnCreateVideoProcessor* callback function creates a video processor.

##### Parameters

`hDrvDevice`

A handle to the display device (graphics context).

`pArgs`

The arguments used to create a video processor.

`hDrvVideoProcessor`

The video processor.

#### Driver processor destruction

The *pfnDestroyVideoProcessor* callback function destroys a video processor.

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

Performs a video processing operation on one or more input samples and writes the result to an output surface.

##### Parameters

`hDrvCommandList`

The command list used to record this process frames command.

`hDrvVideoProcessor`

The video processor instance to use for this video process call. The video processor holds state for a video processing session, including required intermediate memory, cached processing data, or other temporary working space.

`pOutputParameters`

The output arguments for the video process. The available parameters are in the [D3D12DDIARG_VIDEO_PROCESS_OUTPUT_STREAM_ARGUMENTS_0032](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/d3d12umddi/ns-d3d12umddi-d3d12ddiarg_video_process_output_stream_arguments_0032) structure.

`pInputStreamParameters`

Specifies an array of input parameters. The available parameters are in the [D3D12DDIARG_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS_0106](#process-input-arguments) structure.

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

| Current table | Member | Callback typedef |
|---|---|---|
| `D3D12DDI_DEVICE_FUNCS_VIDEO_0110` | `pfnCalcPrivateVideoProcessorSize` | `PFND3D12DDI_CALCPRIVATEVIDEOPROCESSORSIZE_0106` |
| `D3D12DDI_DEVICE_FUNCS_VIDEO_0110` | `pfnCreateVideoProcessor` | `PFND3D12DDI_CREATEVIDEOPROCESSOR_0106` |
| `D3D12DDI_DEVICE_FUNCS_VIDEO_0110` | `pfnDestroyVideoProcessor` | `PFND3D12DDI_DESTROYVIDEOPROCESSOR_0021` |
| `D3D12DDI_COMMAND_LIST_FUNCS_VIDEO_PROCESS_0106` | `pfnProcessFrame` | `PFND3D12DDI_VIDEO_PROCESS_FRAME_0106` |

`D3D12DDICAPS_TYPE_VIDEO_0020_PROCESS_SUPPORT` uses
`D3D12DDI_VIDEO_PROCESS_SUPPORT_DATA_0032` for the selected support layout;
`D3D12DDICAPS_TYPE_VIDEO_0020_PROCESS_REFERENCE_INFO` uses
`D3D12DDI_VIDEO_PROCESS_REFERENCE_INFO_DATA_0020`.
`D3D12DDICAPS_TYPE_VIDEO_0020_PROCESS_MAX_INPUT_STREAMS` uses
`D3D12DDI_VIDEO_PROCESS_MAX_INPUT_STREAMS_DATA_0020`, with input node index
and output simultaneous-stream limit.
`D3D12DDICAPS_TYPE_VIDEO_0032_PROCESSOR_SIZE` uses the processor-size layout
appropriate to the selected DDI version, with input creation description and
output L0/L1 sizes. The device table's `pfnGetCaps` owns these capability
exchanges. The create callback returns `HRESULT`; success is not an NTSTATUS
contract.

**Hardware qualification:** the driver implements the processing supported for
the reported tuple and selected modes. The declarations and capability flags
do not alone define universal scaling/filter kernels, custom deinterlacing,
automatic-processing choices, numeric tolerances, rounding or colorimetric
conformance. Those claims are not inferred from callback availability.
