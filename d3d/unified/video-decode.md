<a id="video-decode"></a>

# Video: decode reference

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

<!-- d3d12-review-alert:begin:video-decode:N-entry:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The compact [Video model](video.md#video) introduces device discovery,
> recording, ordering, lifetime and shared ownership. This subordinate reference
> places ten declaring API contracts and their directly required decode types.
> It is a **qualified draft**, not a complete hardware/codec conformance
> specification. The explicit qualifications below withhold unsupported
> generalisations; capability reports remain scoped to their input tuple.

<!-- d3d12-review-alert:end:video-decode:N-entry:0 -->

<!-- d3d12-review-alert:begin:video-decode:LA-video-annotation-owner:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [command list annotation reference](diagnostics.md#command-list-annotations)
> defines the three internal BeginEvent/EndEvent/SetMarker support methods
> on `ID3D12VideoDecodeCommandList`. Their recording and allocator data lifetime
> follows [common annotation state](command-list-state.md#annotations), not
> a new video processing mode or GPU synchronization operation.

<!-- d3d12-review-alert:end:video-decode:LA-video-annotation-owner:0 -->

<a id="decode-discovery"></a>

## Discovery and query protocol

<a id="video-check-feature-support"></a>

### ID3D12VideoDevice::CheckFeatureSupport

#### Declaration

```cpp
HRESULT CheckFeatureSupport(
  D3D12_FEATURE_VIDEO FeatureVideo,
  void                *pFeatureSupportData,
  UINT                FeatureSupportDataSize
);
```

#### Behavior

Gets information about the features that are supported by the current video driver.

#### Parameters

`FeatureVideo`

A member of the [D3D12_FEATURE_VIDEO](https://learn.microsoft.com/en-us/windows/win32/api/d3d12video/ne-d3d12video-d3d12_feature_video) enumeration that specifies the feature to query for support.

`pFeatureSupportData`

A structure that contains data that describes the configuration details of the feature for which support is requested and, upon the completion of the call, is populated with details about the level of support available. For information on the structure that is associated with each type of feature support request, see the field descriptions for [D3D12_FEATURE_VIDEO](https://learn.microsoft.com/en-us/windows/win32/api/d3d12video/ne-d3d12video-d3d12_feature_video).

`FeatureSupportDataSize`

The size of the structure passed to the *pFeatureSupportData* parameter.

#### Return values

Returns **S\_OK** if successful; otherwise, returns **E\_INVALIDARG** if an unsupported data type is passed to the *pFeatureSupportData* parameter or a size mismatch is detected for the *FeatureSupportDataSize* parameter.

<!-- d3d12-review-alert:begin:video-decode:N-cfs-protocol:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> For the cases below, `FeatureSupportDataSize` is exactly `sizeof` the named
> payload, not the byte count of any pointed-to array. Input fields are
> initialized before the call; output fields describe that request on success.
> The selected cases do not define a universal capacity/prefix or `MORE_DATA`
> enumeration convention. For PROFILES and FORMATS, the supplied count must
> match the corresponding count query, and the caller allocates the result array.
> The inspected ordinary query path returns `E_INVALIDARG` for mismatched
> profile/format counts. It does not fill a successful truncated prefix.

<!-- d3d12-review-alert:end:video-decode:N-cfs-protocol:0 -->

<!-- d3d12-review-alert:begin:video-decode:N-cfs-protocol:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `NodeIndex` is a zero-based node index in these payloads, not a node mask.
> `NodeMask` in creation descriptors is a different field: zero for single-node
> operation, or one selected node bit.

<!-- d3d12-review-alert:end:video-decode:N-cfs-protocol:1 -->

<!-- d3d12-review-alert:begin:video-decode:N-cfs-protocol:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` means the query completed, not that every requested operation is
> supported. For DECODE_SUPPORT and DECODE_CONVERSION_SUPPORT the returned
> support flag makes that distinction. Profiles, formats, conversion support and
> histograms are not universal feature level guarantees.

<!-- d3d12-review-alert:end:video-decode:N-cfs-protocol:2 -->

<!-- d3d12-review-alert:begin:video-decode:N-query-table:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | `D3D12_FEATURE_VIDEO` case | Value | Payload (`sizeof` this type) | Inputs | Outputs |
> |---|---|---|---|---|
> | `D3D12_FEATURE_VIDEO_DECODE_PROFILE_COUNT` | 10 | [`D3D12_FEATURE_DATA_VIDEO_DECODE_PROFILE_COUNT`](#d3d12-feature-data-video-decode-profile-count) | `NodeIndex` | `ProfileCount` |
> | `D3D12_FEATURE_VIDEO_DECODE_PROFILES` | 1 | [`D3D12_FEATURE_DATA_VIDEO_DECODE_PROFILES`](#d3d12-feature-data-video-decode-profiles) | `NodeIndex`, `ProfileCount` | `pProfiles[ProfileCount]` |
> | `D3D12_FEATURE_VIDEO_DECODE_FORMAT_COUNT` | 11 | [`D3D12_FEATURE_DATA_VIDEO_DECODE_FORMAT_COUNT`](#d3d12-feature-data-video-decode-format-count) | `NodeIndex`, `Configuration` | `FormatCount` |
> | `D3D12_FEATURE_VIDEO_DECODE_FORMATS` | 2 | [`D3D12_FEATURE_DATA_VIDEO_DECODE_FORMATS`](#d3d12-feature-data-video-decode-formats) | `NodeIndex`, `Configuration`, `FormatCount` | `pOutputFormats[FormatCount]` |
> | `D3D12_FEATURE_VIDEO_DECODE_SUPPORT` | 0 | [`D3D12_FEATURE_DATA_VIDEO_DECODE_SUPPORT`](#d3d12-feature-data-video-decode-support) | `NodeIndex`, `Configuration`, `Width`, `Height`, `DecodeFormat`, `FrameRate`, `BitRate` | `SupportFlags`, `ConfigurationFlags`, `DecodeTier` |
> | `D3D12_FEATURE_VIDEO_DECODE_CONVERSION_SUPPORT` | 3 | [`D3D12_FEATURE_DATA_VIDEO_DECODE_CONVERSION_SUPPORT`](#d3d12-feature-data-video-decode-conversion-support) | `NodeIndex`, `Configuration`, `DecodeSample`, `OutputFormat`, `FrameRate`, `BitRate` | `SupportFlags`, `ScaleSupport` |
> | `D3D12_FEATURE_VIDEO_DECODER_HEAP_SIZE` | 8 | [`D3D12_FEATURE_DATA_VIDEO_DECODER_HEAP_SIZE`](#d3d12-feature-data-video-decoder-heap-size) | `VideoDecoderHeapDesc` | `MemoryPoolL0Size`, `MemoryPoolL1Size` |
> | `D3D12_FEATURE_VIDEO_ARCHITECTURE` | 17 | [`D3D12_FEATURE_DATA_VIDEO_ARCHITECTURE`](#d3d12-feature-data-video-architecture) | None | `IOCoherent` |
> | `D3D12_FEATURE_VIDEO_DECODE_HISTOGRAM` | 18 | [`D3D12_FEATURE_DATA_VIDEO_DECODE_HISTOGRAM`](#d3d12-feature-data-video-decode-histogram) | `NodeIndex`, `DecodeProfile`, `Width`, `Height`, `DecodeFormat` | `Components`, `BinCount`, `CounterBitDepth` |

<!-- d3d12-review-alert:end:video-decode:N-query-table:0 -->

<!-- d3d12-review-alert:begin:video-decode:D158-processing-query-forward:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Processing-specific query payloads and input/result rules for this same video device method are defined in [Video processing capabilities](video-processing.md#process-discovery).

<!-- d3d12-review-alert:end:video-decode:D158-processing-query-forward:0 -->

<!-- d3d12-review-alert:begin:video-decode:D160-motion-query-forward:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The same video device method also owns the fixed [command family and motion estimation capability cases](video-motion-estimation.md#motion-capabilities). Their input/output payloads do not introduce another query API identity.

<!-- d3d12-review-alert:end:video-decode:D160-motion-query-forward:0 -->

<!-- d3d12-review-alert:begin:video-decode:D161-extension-query-forward:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The same video device method also owns [extension command discovery, parameter stage reflection, support and size queries](video-extension-commands.md#extension-discovery). Their exact counts, byte directions and packing are not Meta command enumeration or initialization policies.

<!-- d3d12-review-alert:end:video-decode:D161-extension-query-forward:0 -->

<!-- d3d12-review-alert:begin:video-decode:D162-encoding-query-forward:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Encoding contributes the [fixed query selectors and payloads](video-encoding-controls.md#encoding-query-selectors) and [combined tuple/count/size/version rules](video-encoding.md#encoding-capabilities), including encoder resource/heap sizes, per-resolution support, optional-statistics requirements, GPU map layout allocation and lower-resolution frame analysis. These remain contributions to this declaring method, not additional API identities.

<!-- d3d12-review-alert:end:video-decode:D162-encoding-query-forward:0 -->

<a id="decode-objects"></a>

## Decoder and decoder heap

<a id="create-video-decoder"></a>

### ID3D12VideoDevice::CreateVideoDecoder

#### Declaration

```cpp
HRESULT CreateVideoDecoder(
  const D3D12_VIDEO_DECODER_DESC *pDesc,
  REFIID                         riid,
  void                           **ppVideoDecoder
);
```

#### Behavior

Creates a video decoder instance that contains the resolution-independent driver resources and state.

#### Parameters

`pDesc`

A pointer to a [D3D12_VIDEO_DECODER_DESC](#d3d12-video-decoder-desc) structure describing the decode profile and bitstream encryption for the decoder.

`riid`

The globally unique identifier (GUID) for the decode video state interface.

`ppVideoDecoder`

A pointer to a memory block that receives a pointer to the [ID3D12VideoDecoder](#decode-objects) interface.

#### Return values

This method returns HRESULT.

#### Remarks

Decoding a new stream requires instantiating a new decoder object.

<!-- d3d12-review-alert:begin:video-decode:N-create-decoder:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The configuration and selected node must be valid for the video device.
> The ordinary path uses `D3D12_BITSTREAM_ENCRYPTION_TYPE_NONE`.
> `riid` identifies the requested decoder interface. `ppVideoDecoder` receives
> that interface, not decoded picture storage.

<!-- d3d12-review-alert:end:video-decode:N-create-decoder:0 -->

<!-- d3d12-review-alert:begin:video-decode:N-create-decoder:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Scoped runtime validation:** invalid node selection, an unsupported decode
> profile/encryption choice, or an invalid coded-interlace value are rejected
> with `E_INVALIDARG` by the inspected runtime path. Creation can propagate
> allocation, interface selection or device removal failure. The short public
> method page does not specify an exhaustive creation error table. These
> observations do not establish which profiles a hardware device implements.

<!-- d3d12-review-alert:end:video-decode:N-create-decoder:1 -->

<a id="create-video-decoder-heap"></a>

### ID3D12VideoDevice::CreateVideoDecoderHeap

#### Declaration

```cpp
HRESULT CreateVideoDecoderHeap(
  const D3D12_VIDEO_DECODER_HEAP_DESC *pVideoDecoderHeapDesc,
  REFIID                              riid,
  void                                **ppVideoDecoderHeap
);
```

#### Behavior

Allocates a video decoder heap that contains the resolution-dependent driver resources and state.

#### Parameters

`pVideoDecoderHeapDesc`

A pointer to a [D3D12_VIDEO_DECODER_HEAP_DESC](#d3d12-video-decoder-heap-desc) describing the decoding configuration.

`riid`

The globally unique identifier (GUID) for the decode video state interface.

`ppVideoDecoderHeap`

A pointer to a memory block that receives a pointer to the [ID3D12VideoDecoderHeap](#decode-objects) interface.

#### Return values

This method returns an HRESULT.

<!-- d3d12-review-alert:begin:video-decode:N-create-heap:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The heap's decode support tuple must be supported. `riid` selects the heap
> interface and `ppVideoDecoderHeap` receives it. Heap allocation does not
> allocate the application's reference/output pictures.

<!-- d3d12-review-alert:end:video-decode:N-create-heap:0 -->

<!-- d3d12-review-alert:begin:video-decode:N-create-heap:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Scoped runtime validation:** the inspected creation path rejects a failed
> DECODE_SUPPORT query or a tuple without the SUPPORTED flag with `E_INVALIDARG`,
> and validates the descriptor's node mask. Allocation, interface selection and
> device removal failures can propagate. This is not an exhaustive HRESULT
> catalog or a guarantee that a successful capability query reserves memory.

<!-- d3d12-review-alert:end:video-decode:N-create-heap:1 -->

<a id="video-decoder-get-desc"></a>

### ID3D12VideoDecoder::GetDesc

#### Declaration

```cpp
D3D12_VIDEO_DECODER_DESC GetDesc();
```

#### Behavior

Gets the [D3D12_VIDEO_DECODER_DESC](#d3d12-video-decoder-desc) structure that was passed into [ID3D12VideoDevice::CreateVideoDecoder](#create-video-decoder) when the [ID3D12VideoDecoder](#decode-objects) was created.

#### Return values

This method returns a **D3D12\_VIDEO\_DECODER\_DESC** structure.

<a id="video-decoder-heap-get-desc"></a>

### ID3D12VideoDecoderHeap::GetDesc

#### Declaration

```cpp
D3D12_VIDEO_DECODER_HEAP_DESC GetDesc();
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:video-decode:P-heap-desc-summary:0 -->Gets the [D3D12_VIDEO_DECODER_HEAP_DESC](#d3d12-video-decoder-heap-desc) structure that was passed into [ID3D12VideoDevice::CreateVideoDecoderHeap](#create-video-decoder-heap) when the [ID3D12VideoDecoderHeap](#decode-objects) was created.<!-- d3d12-review-inline:end:video-decode:P-heap-desc-summary:0 --></ins>

#### Return values

This method returns a **D3D12\_VIDEO\_DECODER\_HEAP\_DESC** structure.

<a id="decode-list-lifecycle"></a>

## Decode command list lifecycle

<a id="decode-clear-state"></a>

### ID3D12VideoDecodeCommandList::ClearState

#### Declaration

```cpp
void ClearState();
```

#### Behavior

Resets the state of <ins><!-- d3d12-review-inline:begin:video-decode:P-clear-summary:0 -->a video decode command list<!-- d3d12-review-inline:end:video-decode:P-clear-summary:0 --></ins> back to the state it was in when the command list was created.

#### Return values

None

<!-- d3d12-review-alert:begin:video-decode:N-clear:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> ClearState disables predication on the existing recording. It is not Reset
> and does not reclaim command allocator storage or erase earlier recorded
> decode work. The ordinary video contribution does not imply graphics root,
> descriptor heap or PSO initialization.

<!-- d3d12-review-alert:end:video-decode:N-clear:0 -->

<a id="decode-close"></a>

### ID3D12VideoDecodeCommandList::Close

#### Declaration

```cpp
HRESULT Close();
```

#### Behavior

Indicates that recording to the command list has finished.

#### Return values

Returns **S\_OK** if successful; otherwise, returns one of the following values:

- **E\_FAIL** if the command list has already been closed, or an invalid API was called during command list recording.
- **E\_OUTOFMEMORY** if the operating system ran out of memory during recording.
- **E\_INVALIDARG** if an invalid argument was passed to the command list API during recording.

See [Direct3D 12 Return Codes](devices-and-capabilities.md#api-result-codes) for other possible return values.

#### Remarks

The runtime will validate that the command list has not previously been closed. If an error was encountered during recording, the error code is returned here. The runtime won't call the close device driver interface (DDI) in this case.

<!-- d3d12-review-alert:begin:video-decode:N-close:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Close ends recording, not GPU execution. It is a lifecycle/query resolution
> wrapper: pending query resolution work can be emitted while closing. The
> wrapper classification does not assign a new predicate policy to the
> generated work or turn a successful Close into a decode status query.
> The [query protocol](counters-queries-and-predication.md#videodecode-resolvequerydata)
> and [completion rules](execution.md#completion-lifetime) remain canonical.

<!-- d3d12-review-alert:end:video-decode:N-close:0 -->

<a id="decode-reset"></a>

### ID3D12VideoDecodeCommandList::Reset

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

Returns **S\_OK** if successful; otherwise, returns one of the following values:

- **E\_FAIL** if the command list was not in the "closed" state when the **Reset** call was made, or the per-device limit would have been exceeded.
- **E\_OUTOFMEMORY** if the operating system ran out of memory.
- **E\_INVALIDARG** if the allocator is currently being used with another command list in the "recording" state or if the specified allocator was created with the wrong type.

See [Direct3D 12 Return Codes](devices-and-capabilities.md#api-result-codes) for other possible return values.

<!-- d3d12-review-alert:begin:video-decode:N-reset:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The allocator has video decode type and is available for recording with
> this list. Successful Reset puts the list into recording state and disables
> predication. Reset does not wait for GPU completion and is distinct from
> [`ID3D12CommandAllocator::Reset`](execution.md#allocator-reset). The allocator's
> recorded storage remains subject to its reuse/completion requirements.
> There is no initial graphics PSO parameter.

<!-- d3d12-review-alert:end:video-decode:N-reset:0 -->

<a id="decode-frame-apis"></a>

## Recording a decode

<a id="decode-frame"></a>

### ID3D12VideoDecodeCommandList::DecodeFrame

#### Declaration

```cpp
void DecodeFrame(
  ID3D12VideoDecoder                               *pDecoder,
  const D3D12_VIDEO_DECODE_OUTPUT_STREAM_ARGUMENTS *pOutputArguments,
  const D3D12_VIDEO_DECODE_INPUT_STREAM_ARGUMENTS  *pInputArguments
);
```

#### Behavior

Records a decode frame operation to the command list. Inputs, outputs, and parameters for the decode are specified as arguments to this method.

#### Parameters

`pDecoder`

A pointer to an [ID3D12VideoDecoder](#decode-objects) interface representing a decoder instance.

`pOutputArguments`

A [D3D12_VIDEO_DECODE_OUTPUT_STREAM_ARGUMENTS](#d3d12-video-decode-output-stream-arguments) structure specifying the output surface and output arguments.

`pInputArguments`

A [D3D12_VIDEO_DECODE_INPUT_STREAM_ARGUMENTS](#d3d12-video-decode-input-stream-arguments) structure specifying the input bitstream, reference frames, and other input parameters.

#### Return values

None

#### Remarks

The [ID3D12VideoDecodeCommandList1::DecodeFrame1](#decode-frame1) method provides the same functionality as this method, but adds support for decode histograms.

<a id="decode-frame1"></a>

### ID3D12VideoDecodeCommandList1::DecodeFrame1

#### Declaration

```cpp
void DecodeFrame1(
  ID3D12VideoDecoder                                *pDecoder,
  const D3D12_VIDEO_DECODE_OUTPUT_STREAM_ARGUMENTS1 *pOutputArguments,
  const D3D12_VIDEO_DECODE_INPUT_STREAM_ARGUMENTS   *pInputArguments
);
```

#### Behavior

Records a decode frame operation to the command list. Inputs, outputs, and parameters for the decode are specified as arguments to this method. Takes a [D3D12_VIDEO_DECODE_OUTPUT_STREAM_ARGUMENTS1](#d3d12-video-decode-output-stream-arguments1) structure to support video decode histograms.

#### Parameters

`pDecoder`

A pointer to an [ID3D12VideoDecoder](#decode-objects) interface representing a decoder instance.

`pOutputArguments`

A [D3D12_VIDEO_DECODE_OUTPUT_STREAM_ARGUMENTS1](#d3d12-video-decode-output-stream-arguments1) structure specifying the output surface and output arguments.

`pInputArguments`

A [D3D12_VIDEO_DECODE_INPUT_STREAM_ARGUMENTS](#d3d12-video-decode-input-stream-arguments) structure specifying the input bitstream, reference frames, and other input parameters.

#### Return values

None

<!-- d3d12-review-alert:begin:video-decode:N-frame-validation:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Both methods record a frame. Neither returns an HRESULT or the hardware
> decode result. The public Close contract reports deferred recording errors.
> The runtime checks frame argument types/picture parameter sizes, decoder/heap
> configuration compatibility, bitstream resource/range, reference resources
> and output/conversion/histogram arguments on the inspected ordinary path.
> This is not a promise to detect every malformed codec bitstream or every
> invalid pointer. The debug layer also checks resource states; debug checks
> are not hardware completion evidence.

<!-- d3d12-review-alert:end:video-decode:N-frame-validation:0 -->

<!-- d3d12-review-alert:begin:video-decode:N-frame-validation:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Reference array qualification:** the public reference type allows
> `pSubresources == nullptr` to mean all-zero subresources. The inspected
> ordinary validation path dereferences this pointer for non-null references.
> The documented meaning is retained below, but null pointer safety is not
> established by this draft. This qualification does not replace the documented
> default with a mandatory-array ABI.

<!-- d3d12-review-alert:end:video-decode:N-frame-validation:1 -->

<!-- d3d12-review-alert:begin:video-decode:N-frame-validation:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Legacy conversion qualification:** the base conversion page says texture
> sizes determine scaling. The inspected base DecodeFrame translation supplies
> native heap dimensions to the version-1 conversion path instead. The draft
> does not guarantee legacy downscaling from different-sized resources alone.
> DecodeFrame1 explicitly supplies `OutputWidth`/`OutputHeight`. Conversion
> support still depends on the actual configuration, formats, color spaces and
> reported scaling range/flags.

<!-- d3d12-review-alert:end:video-decode:N-frame-validation:2 -->

<a id="decode-query-payloads"></a>

## Selected query payloads

<a id="d3d12-feature-data-video-decode-profile-count"></a>

### D3D12_FEATURE_DATA_VIDEO_DECODE_PROFILE_COUNT

#### Declaration

```cpp
typedef struct D3D12_FEATURE_DATA_VIDEO_DECODE_PROFILE_COUNT
{
    UINT NodeIndex;                                             // input
    UINT ProfileCount;                                          // output
} D3D12_FEATURE_DATA_VIDEO_DECODE_PROFILE_COUNT;
```

<!-- d3d12-review-alert:begin:video-decode:N-feature_data_video_decode_profile_count:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `NodeIndex` is the input node index. `ProfileCount` receives the number of supported decoder profiles for that node.

<!-- d3d12-review-alert:end:video-decode:N-feature_data_video_decode_profile_count:0 -->

<a id="d3d12-feature-data-video-decode-profiles"></a>

### D3D12_FEATURE_DATA_VIDEO_DECODE_PROFILES

#### Declaration

```cpp
typedef struct D3D12_FEATURE_DATA_VIDEO_DECODE_PROFILES
{
    UINT NodeIndex;                                                   // input
    UINT ProfileCount;                                                // input
    GUID *pProfiles;  // output. The list of supported profiles. The caller allocates storage for the profile list before calling CheckFeatureSupport.
} D3D12_FEATURE_DATA_VIDEO_DECODE_PROFILES;
```

Provides data for calls to [ID3D12VideoDevice::CheckFeatureSupport](#video-check-feature-support) when the feature specified is [D3D12_FEATURE_VIDEO_DECODE_PROFILES](#d3d12-feature-data-video-decode-profiles). Retrieves the list of supported profiles.

#### Members

`NodeIndex`

<ins><!-- d3d12-review-inline:begin:video-decode:P-feature_data_video_decode_profiles-members:2 -->The zero-based index of the device node to query. For a single-node device, this is zero.<!-- d3d12-review-inline:end:video-decode:P-feature_data_video_decode_profiles-members:2 --></ins>

`ProfileCount`

The number of profiles to retrieve. This number must match the value returned from a call [ID3D12VideoDevice::CheckFeatureSupport](#video-check-feature-support) when the feature specified is [D3D12_FEATURE_VIDEO_DECODE_PROFILE_COUNT](#d3d12-feature-data-video-decode-profile-count).

`pProfiles`

A list of GUIDs representing the supported profiles. The calling application must allocate storage for the profile list before calling **CheckFeatureSupport**.

<a id="d3d12-feature-data-video-decode-format-count"></a>

### D3D12_FEATURE_DATA_VIDEO_DECODE_FORMAT_COUNT

#### Declaration

```cpp
typedef struct D3D12_FEATURE_DATA_VIDEO_DECODE_FORMAT_COUNT
{
    UINT NodeIndex;                                                             // input
    D3D12_VIDEO_DECODE_CONFIGURATION Configuration;                             // input
    UINT FormatCount;                                                           // output
} D3D12_FEATURE_DATA_VIDEO_DECODE_FORMAT_COUNT;
```

<!-- d3d12-review-alert:begin:video-decode:N-feature_data_video_decode_format_count:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `NodeIndex` and `Configuration` select the request. `FormatCount` receives the number of output formats for that decode configuration.

<!-- d3d12-review-alert:end:video-decode:N-feature_data_video_decode_format_count:0 -->

<a id="d3d12-feature-data-video-decode-formats"></a>

### D3D12_FEATURE_DATA_VIDEO_DECODE_FORMATS

#### Declaration

```cpp
typedef struct D3D12_FEATURE_DATA_VIDEO_DECODE_FORMATS
{
    UINT NodeIndex;                                                              // input
    D3D12_VIDEO_DECODE_CONFIGURATION Configuration;                              // input
    UINT FormatCount;                                                            // input
    DXGI_FORMAT *pOutputFormats;  // output. The list of supported video formats. The caller allocates storage for the format list before calling CheckFeatureSupport.
} D3D12_FEATURE_DATA_VIDEO_DECODE_FORMATS;
```

Provides data for calls to [ID3D12VideoDevice::CheckFeatureSupport](#video-check-feature-support) when the feature specified is <ins><!-- d3d12-review-inline:begin:video-decode:P-feature_data_video_decode_formats-summary:0 -->[D3D12_FEATURE_VIDEO_DECODE_FORMATS](#d3d12-feature-data-video-decode-formats)<!-- d3d12-review-inline:end:video-decode:P-feature_data_video_decode_formats-summary:0 --></ins>. Retrieves the list of supported formats.

#### Members

`NodeIndex`

<ins><!-- d3d12-review-inline:begin:video-decode:P-feature_data_video_decode_formats-members:2 -->The zero-based index of the device node to query. For a single-node device, this is zero.<!-- d3d12-review-inline:end:video-decode:P-feature_data_video_decode_formats-members:2 --></ins>

`Configuration`

A [D3D12_VIDEO_DECODE_CONFIGURATION](#d3d12-video-decode-configuration) structure describing the decode configuration for the list of formats.

`FormatCount`

The number of formats to retrieve. This number must match the value returned from a call [ID3D12VideoDevice::CheckFeatureSupport](#video-check-feature-support) when the feature specified is [D3D12_FEATURE_VIDEO_DECODE_FORMAT_COUNT](#d3d12-feature-data-video-decode-format-count).

`pOutputFormats`

A list of [DXGI_FORMAT](formats.md#dxgi-format) <ins><!-- d3d12-review-inline:begin:video-decode:P-feature_data_video_decode_formats-members:8 -->values representing the supported formats.<!-- d3d12-review-inline:end:video-decode:P-feature_data_video_decode_formats-members:8 --></ins>

<a id="d3d12-feature-data-video-decode-support"></a>

### D3D12_FEATURE_DATA_VIDEO_DECODE_SUPPORT

#### Declaration

```cpp
typedef struct D3D12_FEATURE_DATA_VIDEO_DECODE_SUPPORT
{
    UINT NodeIndex;                                            // input
    D3D12_VIDEO_DECODE_CONFIGURATION Configuration;            // input
    UINT Width;                                                // input
    UINT Height;                                               // input
    DXGI_FORMAT DecodeFormat;                                  // input
    DXGI_RATIONAL FrameRate;                                   // input
    UINT BitRate;                                              // input
    D3D12_VIDEO_DECODE_SUPPORT_FLAGS SupportFlags;             // output
    D3D12_VIDEO_DECODE_CONFIGURATION_FLAGS ConfigurationFlags; // output
    D3D12_VIDEO_DECODE_TIER DecodeTier;                        // output
} D3D12_FEATURE_DATA_VIDEO_DECODE_SUPPORT;
```

Provides data for calls to [ID3D12VideoDevice::CheckFeatureSupport](#video-check-feature-support) when the feature specified is [D3D12_FEATURE_VIDEO_DECODE_SUPPORT](#d3d12-feature-data-video-decode-support). Retrieves support information for video decoding.

#### Members

`NodeIndex`

<ins><!-- d3d12-review-inline:begin:video-decode:P-feature_data_video_decode_support-members:2 -->The zero-based index of the device node to query. For a single-node device, this is zero.<!-- d3d12-review-inline:end:video-decode:P-feature_data_video_decode_support-members:2 --></ins>

`Configuration`

A [D3D12_VIDEO_DECODE_CONFIGURATION](#d3d12-video-decode-configuration) structure specifying the decode profile, bitstream encryption, and interlace type of the source stream.

`Width`

The decode width of the source stream.

`Height`

The decode height of the source stream

`DecodeFormat`

The [DXGI_FORMAT](formats.md#dxgi-format) to use as the decode format. This format is the output format if no decoder conversion is specified.

`FrameRate`

The frame rate of the video format. A value of 0 means the frame rate is unknown.

`BitRate`

The average bits per second data compression rate for the compressed video stream. This information is used by the driver to determine whether the video can be decoded in real-time. A value of 0 means the bit rate is unknown.

`SupportFlags`

A combination of values from the [D3D12_VIDEO_DECODE_SUPPORT_FLAGS](#d3d12-video-decode-support-flags) enumeration indicating the support for video decoding. This value is populated by the call to <ins><!-- d3d12-review-inline:begin:video-decode:P-feature_data_video_decode_support-members:16 -->**ID3D12VideoDevice::CheckFeatureSupport**<!-- d3d12-review-inline:end:video-decode:P-feature_data_video_decode_support-members:16 --></ins>.

`ConfigurationFlags`

A combination of values from the [D3D12_VIDEO_DECODE_CONFIGURATION_FLAGS](#d3d12-video-decode-configuration-flags) enumeration describing the video decode configuration. This value is populated by the call to <ins><!-- d3d12-review-inline:begin:video-decode:P-feature_data_video_decode_support-members:18 -->**ID3D12VideoDevice::CheckFeatureSupport**<!-- d3d12-review-inline:end:video-decode:P-feature_data_video_decode_support-members:18 --></ins>.

`DecodeTier`

A member of the [D3D12_VIDEO_DECODE_TIER](#d3d12-video-decode-tier) enumeration specifying the decoding tier of a hardware video decoder.

<a id="d3d12-feature-data-video-decode-conversion-support"></a>

### D3D12_FEATURE_DATA_VIDEO_DECODE_CONVERSION_SUPPORT

#### Declaration

```cpp
typedef struct D3D12_FEATURE_DATA_VIDEO_DECODE_CONVERSION_SUPPORT
{
    UINT NodeIndex;                                             // input
    D3D12_VIDEO_DECODE_CONFIGURATION Configuration;             // input
    D3D12_VIDEO_SAMPLE DecodeSample;                            // input
    D3D12_VIDEO_FORMAT OutputFormat;                            // input
    DXGI_RATIONAL FrameRate;                                    // input
    UINT BitRate;                                               // input
    D3D12_VIDEO_DECODE_CONVERSION_SUPPORT_FLAGS SupportFlags;   // output
    D3D12_VIDEO_SCALE_SUPPORT ScaleSupport;                     // output
} D3D12_FEATURE_DATA_VIDEO_DECODE_CONVERSION_SUPPORT;
```

<ins><!-- d3d12-review-inline:begin:video-decode:P-feature_data_video_decode_conversion_support-summary:0 -->Provides data for calls to [ID3D12VideoDevice::CheckFeatureSupport](#video-check-feature-support) when the feature specified is [D3D12_FEATURE_VIDEO_DECODE_CONVERSION_SUPPORT](#d3d12-feature-data-video-decode-conversion-support). Check if a colorspace conversion, format conversion, and scale are supported.<!-- d3d12-review-inline:end:video-decode:P-feature_data_video_decode_conversion_support-summary:0 --></ins>

#### Members

`NodeIndex`

<ins><!-- d3d12-review-inline:begin:video-decode:P-feature_data_video_decode_conversion_support-members:2 -->The zero-based index of the device node to query. For a single-node device, this is zero.<!-- d3d12-review-inline:end:video-decode:P-feature_data_video_decode_conversion_support-members:2 --></ins>

`Configuration`

A [D3D12_VIDEO_DECODE_CONFIGURATION](#d3d12-video-decode-configuration) structure describing the decode configuration.

`DecodeSample`

A [D3D12_VIDEO_SAMPLE](#d3d12-video-sample) structure representing the source decoded as sample description.

`OutputFormat`

A [D3D12_VIDEO_FORMAT](#d3d12-video-format) structure containing the output sample description.

`FrameRate`

The frame rate of the video content. This is used by the driver to determine whether the video can be decoded in real-time.

`BitRate`

The average bits per second data compression rate for the compressed video stream. This is used by the driver to determine whether the video can be decoded in real-time.

`SupportFlags`

A combination of values from the [D3D12_VIDEO_DECODE_CONVERSION_SUPPORT_FLAGS](#d3d12-video-decode-conversion-support-flags) indicating the support for the specified conversion.

`ScaleSupport`

A [D3D12_VIDEO_SCALE_SUPPORT](#d3d12-video-scale-support) structure representing the output size range for decode conversion.

#### Remarks

<ins><!-- d3d12-review-inline:begin:video-decode:P-feature_data_video_decode_conversion_support-remarks:1 -->If the colorspace and format conversion is supported, `ScaleSupport.Flags` will have the [D3D12_VIDEO_SCALE_SUPPORT_FLAGS](#d3d12-video-scale-support-flags) set. Callers should check the [D3D12_VIDEO_SIZE_RANGE](#d3d12-video-size-range) field `ScaleSupport.OutputSizeRange` to determine if the requested scale is supported.<!-- d3d12-review-inline:end:video-decode:P-feature_data_video_decode_conversion_support-remarks:1 --></ins>

<a id="d3d12-feature-data-video-decoder-heap-size"></a>

### D3D12_FEATURE_DATA_VIDEO_DECODER_HEAP_SIZE

#### Declaration

```cpp
typedef struct D3D12_FEATURE_DATA_VIDEO_DECODER_HEAP_SIZE
{
    D3D12_VIDEO_DECODER_HEAP_DESC VideoDecoderHeapDesc;         // input
    UINT64 MemoryPoolL0Size;                                    // output
    UINT64 MemoryPoolL1Size;                                    // output
} D3D12_FEATURE_DATA_VIDEO_DECODER_HEAP_SIZE;
```

Describes the allocation size of a video decoder heap.

#### Members

`VideoDecoderHeapDesc`

A [D3D12_VIDEO_DECODER_HEAP_DESC](#d3d12-video-decoder-heap-desc) describing a [ID3D12VideoDecoderHeap](#decode-objects).

`MemoryPoolL0Size`

The allocation size of the video decoder heap in the L0 memory pool. L0 is the physical system memory pool. When the adapter is discrete/NUMA, this pool has greater bandwidth for the CPU and less bandwidth for the GPU. When the adapter is UMA, this pool is the only one which is valid. For more information, see [Residency](resources.md#residency).

`MemoryPoolL1Size`

The allocation size of the video decoder heap in the L1 memory pool. L1 is typically known as the physical video memory pool. L1 is only available when the adapter is discrete/NUMA, and has greater bandwidth for the GPU and cannot even be accessed by the CPU. When the adapter is UMA, this pool is not available. For more information, see [Residency](resources.md#residency).

<a id="d3d12-feature-data-video-architecture"></a>

### D3D12_FEATURE_DATA_VIDEO_ARCHITECTURE

#### Declaration

```cpp
typedef struct D3D12_FEATURE_DATA_VIDEO_ARCHITECTURE
{
    BOOL IOCoherent;
} D3D12_FEATURE_DATA_VIDEO_ARCHITECTURE;
```

<!-- d3d12-review-alert:begin:video-decode:N-feature_data_video_architecture:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `IOCoherent` is the output video I/O-coherence indicator. **Qualification:**
> the selected public declaration supplies this field but no complete
> decode-specific heap/cacheability truth table. This draft does not infer a
> new memory consistency rule or universal CPU-cacheable allocation permission
> from it. [CPU/GPU access and heap properties](resources.md#cpu-access) and
> [explicit completion](execution.md#completion-lifetime) retain their owners.

<!-- d3d12-review-alert:end:video-decode:N-feature_data_video_architecture:0 -->

<a id="d3d12-feature-data-video-decode-histogram"></a>

### D3D12_FEATURE_DATA_VIDEO_DECODE_HISTOGRAM

#### Declaration

```cpp
typedef struct D3D12_FEATURE_DATA_VIDEO_DECODE_HISTOGRAM
{
    UINT NodeIndex;                                                       // in
    GUID DecodeProfile;                                                   // in
    UINT Width;                                                           // in
    UINT Height;                                                          // in
    DXGI_FORMAT DecodeFormat;                                             // in
    D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAGS Components;              // out
    UINT BinCount;                                                        // out
    UINT CounterBitDepth;                                                 // out
} D3D12_FEATURE_DATA_VIDEO_DECODE_HISTOGRAM;
```

Provides data for calls to [ID3D12VideoDevice::CheckFeatureSupport](#video-check-feature-support) when the feature specified is [D3D12_FEATURE_VIDEO_DECODE_HISTOGRAM](#d3d12-feature-data-video-decode-histogram). Retrieves the histogram capabilities for the specified decoder configuration.

#### Members

`NodeIndex`

<ins><!-- d3d12-review-inline:begin:video-decode:P-feature_data_video_decode_histogram-members:2 -->The zero-based index of the device node to query. For a single-node device, this is zero.<!-- d3d12-review-inline:end:video-decode:P-feature_data_video_decode_histogram-members:2 --></ins>

`DecodeProfile`

A GUID representing the decode profile for which histogram capabilities will be queried. Get a list of available profile GUIDs by calling [ID3D12VideoDevice::CheckFeatureSupport](#video-check-feature-support) when the feature specified is [D3D12_FEATURE_VIDEO_DECODE_PROFILES](#d3d12-feature-data-video-decode-profiles).

`Width`

The decode width of the source stream.

`Height`

The decode height of the source stream.

`DecodeFormat`

The [DXGI_FORMAT](formats.md#dxgi-format) representing the decode format.

`Components`

A bitwise OR combination of values from the [D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAGS](#d3d12-video-decode-histogram-component-flags) enumeration <ins><!-- d3d12-review-inline:begin:video-decode:P-feature_data_video_decode_histogram-members:12 -->reporting the components of a DXGI\_FORMAT for which histograms are supported.<!-- d3d12-review-inline:end:video-decode:P-feature_data_video_decode_histogram-members:12 --></ins>

`BinCount`

The number of per component bins supported. <ins><!-- d3d12-review-inline:begin:video-decode:P-feature_data_video_decode_histogram-members:14 -->When histograms are supported, this value must be greater than or equal to 64<!-- d3d12-review-inline:end:video-decode:P-feature_data_video_decode_histogram-members:14 --></ins> and must be a power of 2 (e.g. 64, 128, 256, 512...).

`CounterBitDepth`

The bit depth of the bin counter. The counter is always stored in a 32-bit value and therefore this value must specify 32 bits or less. The counter is stored in the lower bits of the 32-bit storage. The upper bits are set to zero. <ins><!-- d3d12-review-inline:begin:video-decode:P-feature_data_video_decode_histogram-members:16 -->If a bin's counter exceeds this bit depth<!-- d3d12-review-inline:end:video-decode:P-feature_data_video_decode_histogram-members:16 --></ins>, the value is set to the maximum counter value. <ins><!-- d3d12-review-inline:begin:video-decode:P-feature_data_video_decode_histogram-members:16 -->When histograms are supported, valid values for *CounterBitDepth* are 16, 24, and 32.<!-- d3d12-review-inline:end:video-decode:P-feature_data_video_decode_histogram-members:16 --></ins>

<!-- d3d12-review-alert:begin:video-decode:N-histogram-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `Components` is an output support mask. Y/R share component index 0,
> U/G index 1, V/B index 2, and A index 3. It is not a seven-element histogram.
> An enabled destination holds `BinCount` 32-bit counters, so its required byte
> range is `Offset + 4 * BinCount` within its buffer, without integer overflow.
> The reported counter depth controls saturation and zeroed upper storage bits,
> not the storage stride.

<!-- d3d12-review-alert:end:video-decode:N-histogram-contract:0 -->

<!-- d3d12-review-alert:begin:video-decode:N-histogram-contract:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Histogram/allocation qualification:** the public histogram buffer page's
> heap/resource flag lists are not used here as a blanket allocation whitelist.
> They include combinations whose legality also depends on the ordinary
> buffer/resource contract. Allocate under the canonical
> [resource and heap requirements](resources.md#resource-contracts). This draft
> does not override them. The generic decode reference also does not specify
> an unverified codec-specific histogram stage relative to conversion.

<!-- d3d12-review-alert:end:video-decode:N-histogram-contract:1 -->

<a id="decode-arguments"></a>

## Decoder configuration and input/output types

<!-- d3d12-review-alert:begin:video-decode:N-array-extents:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The declarations use `D3D12_VIDEO_DECODE_MAX_ARGUMENTS` for the ten
> frame argument slots and `D3D12_VIDEO_DECODE_MAX_HISTOGRAM_COMPONENTS` for the
> four per-component histogram slots. Their capacities are also shown in the
> owning public member descriptions. Neither expands codec support.

<!-- d3d12-review-alert:end:video-decode:N-array-extents:0 -->

<a id="d3d12-video-decode-configuration"></a>

### D3D12_VIDEO_DECODE_CONFIGURATION

#### Declaration

```cpp
typedef struct D3D12_VIDEO_DECODE_CONFIGURATION
{
    GUID DecodeProfile;
    D3D12_BITSTREAM_ENCRYPTION_TYPE BitstreamEncryption;
    D3D12_VIDEO_FRAME_CODED_INTERLACE_TYPE InterlaceType;
} D3D12_VIDEO_DECODE_CONFIGURATION;
```

Describes the configuration for a video decoder.

#### Members

`DecodeProfile`

A GUID identifying the profile for the decoder, such as D3D12\_VIDEO\_DECODE\_PROFILE\_H264 or D3D12\_VIDEO\_DECODE\_PROFILE\_HEVC\_MAIN. For a list of supported GUIDs, see [Direct3D 12 Video GUIDs](https://learn.microsoft.com/en-us/windows/desktop/medfound/direct3d-12-video-guids).

`BitstreamEncryption`

A member of the [D3D12_BITSTREAM_ENCRYPTION_TYPE](#d3d12-bitstream-encryption-type) enumeration specifying the type of bitstream encryption. For no encryption, use D3D12\_BITSTREAM\_ENCRYPTION\_TYPE\_NONE.

`InterlaceType`

A member of the [D3D12_VIDEO_FRAME_CODED_INTERLACE_TYPE](#d3d12-video-frame-coded-interlace-type) <ins><!-- d3d12-review-inline:begin:video-decode:P-video_decode_configuration-members:6 -->enumeration specifying the desired interlace type<!-- d3d12-review-inline:end:video-decode:P-video_decode_configuration-members:6 --></ins> used by the coded frames.

<a id="d3d12-video-decoder-desc"></a>

### D3D12_VIDEO_DECODER_DESC

#### Declaration

```cpp
typedef struct D3D12_VIDEO_DECODER_DESC
{
    UINT NodeMask;
    D3D12_VIDEO_DECODE_CONFIGURATION Configuration;
} D3D12_VIDEO_DECODER_DESC;
```

Describes a [ID3D12VideoDecoder](#decode-objects). Pass this structure into [ID3D12VideoDevice::CreateVideoDecoder](#create-video-decoder) to create an instance of **ID3D12VideoDecoder**.

#### Members

`NodeMask`

<ins><!-- d3d12-review-inline:begin:video-decode:P-video_decoder_desc-members:2 -->The node mask specifying the physical adapter on which the video decoder will be used. For single GPU operation, set this to zero. If there are multiple GPU nodes, set a bit to identify the node, i.e. the device's physical adapter, on which the video decoder will be used. Each bit in the mask corresponds to a single node. Only 1 bit may be set.<!-- d3d12-review-inline:end:video-decode:P-video_decoder_desc-members:2 --></ins>

`Configuration`

A [D3D12_VIDEO_DECODE_CONFIGURATION](#d3d12-video-decode-configuration) structure specifying the configuration of the video decoder.

<a id="d3d12-video-decoder-heap-desc"></a>

### D3D12_VIDEO_DECODER_HEAP_DESC

#### Declaration

```cpp
typedef struct D3D12_VIDEO_DECODER_HEAP_DESC
{
    UINT NodeMask;
    D3D12_VIDEO_DECODE_CONFIGURATION Configuration;
    UINT DecodeWidth;
    UINT DecodeHeight;
    DXGI_FORMAT Format;
    DXGI_RATIONAL FrameRate;
    UINT BitRate;
    UINT MaxDecodePictureBufferCount;
} D3D12_VIDEO_DECODER_HEAP_DESC;
```

Describes a [ID3D12VideoDecoderHeap](#decode-objects). Pass this structure into [ID3D12VideoDevice::CreateVideoDecoderHeap](#create-video-decoder-heap) to create an instance of **ID3D12VideoDecoderHeap**.

#### Members

`NodeMask`

<ins><!-- d3d12-review-inline:begin:video-decode:P-video_decoder_heap_desc-members:2 -->The node mask specifying the physical adapter on which the video decoder heap will be used. For single GPU operation, set this to zero. If there are multiple GPU nodes, set a bit to identify the node, i.e. the device's physical adapter, on which the video decoder heap will be used. Each bit in the mask corresponds to a single node. Only 1 bit may be set.<!-- d3d12-review-inline:end:video-decode:P-video_decoder_heap_desc-members:2 --></ins>

`Configuration`

A [D3D12_VIDEO_DECODE_CONFIGURATION](#d3d12-video-decode-configuration) structure specifying the configuration of the video decoder.

`DecodeWidth`

The decode width of the bitstream to be decoded.

`DecodeHeight`

The decode height of the bitstream to be decoded.

`Format`

<ins><!-- d3d12-review-inline:begin:video-decode:P-video_decoder_heap_desc-members:10 -->A value from [DXGI_FORMAT](formats.md#dxgi-format) specifying the native decoded picture format.<!-- d3d12-review-inline:end:video-decode:P-video_decoder_heap_desc-members:10 --></ins>

`FrameRate`

The frame rate of the input video stream. For more information, see the Remarks section.

`BitRate`

The average bits per second data compression rate for the compressed video stream. For more information, see the Remarks section.

`MaxDecodePictureBufferCount`

The maximum number of decode picture buffers this stream can have.

#### Remarks

The *BitRate* and *FrameRate* parameters may be used by drivers to inform heuristics such as intermediate allocation sizes. Decoding a frame may fail if these values are insufficient for the video stream. Use <ins><!-- d3d12-review-inline:begin:video-decode:P-video_decoder_heap_desc-remarks:1 -->[D3D12_QUERY_DATA_VIDEO_DECODE_STATISTICS](counters-queries-and-predication.md#video-decode-statistics)<!-- d3d12-review-inline:end:video-decode:P-video_decoder_heap_desc-remarks:1 --></ins> to determine if the video decode succeeded. If decode fails due to insufficient *BitRate* and *FrameRate* parameters, the *Status* field of this query is set to [D3D12_VIDEO_DECODE_STATUS_RATE_EXCEEDED](counters-queries-and-predication.md#video-decode-statistics). This query also returns new *BitRate* and *FrameRate* values that would succeed.

The *BitRate* and *FrameRate* parameters may also be set to zero. Drivers make worst-case assumptions when these values are used which may result in higher memory consumption with some adapters.

<a id="d3d12-video-format"></a>

### D3D12_VIDEO_FORMAT

#### Declaration

```cpp
typedef struct D3D12_VIDEO_FORMAT
{
    DXGI_FORMAT Format;
    DXGI_COLOR_SPACE_TYPE ColorSpace;
} D3D12_VIDEO_FORMAT;
```

Defines the combination of a pixel format and color space for a resource content description.

#### Members

`Format`

A value from the [DXGI_FORMAT](formats.md#dxgi-format) enumeration, specifying the DXGI format of the data.

`ColorSpace`

A value from the [DXGI_COLOR_SPACE_TYPE](https://learn.microsoft.com/en-us/windows/desktop/api/dxgicommon/ne-dxgicommon-dxgi_color_space_type) enumeration, specifying the color space of the data.

<a id="d3d12-video-sample"></a>

### D3D12_VIDEO_SAMPLE

#### Declaration

```cpp
typedef struct D3D12_VIDEO_SAMPLE
{
    UINT Width;
    UINT Height;
    D3D12_VIDEO_FORMAT Format;
} D3D12_VIDEO_SAMPLE;
```

Describes the width, height, format, and color space of a picture buffer.

#### Members

`Width`

The width of the sample.

`Height`

The height of the sample.

`Format`

A [D3D12_VIDEO_FORMAT](#d3d12-video-format) structure describing the format and colorspace of the sample.

<a id="d3d12-video-size-range"></a>

### D3D12_VIDEO_SIZE_RANGE

#### Declaration

```cpp
typedef struct D3D12_VIDEO_SIZE_RANGE
{
    UINT MaxWidth;
    UINT MaxHeight;
    UINT MinWidth;
    UINT MinHeight;
} D3D12_VIDEO_SIZE_RANGE;
```

Describes the range of supported sizes for a video scaler.

#### Members

`MaxWidth`

The largest output width to which content can be scaled. The largest value allowed is **D3D12\_REQ\_TEXTURE2D\_U\_OR\_V\_DIMENSION** (16384).

`MaxHeight`

The largest output height to which content can be scaled. The largest value allowed is **D3D12\_REQ\_TEXTURE2D\_U\_OR\_V\_DIMENSION** (16384).

`MinWidth`

The smallest output width to which content can be scaled. The smallest allowed value is 1.

`MinHeight`

The smallest output height to which content can be scaled. The smallest allowed value is 1.

<a id="d3d12-video-scale-support"></a>

### D3D12_VIDEO_SCALE_SUPPORT

#### Declaration

```cpp
typedef struct D3D12_VIDEO_SCALE_SUPPORT
{
    D3D12_VIDEO_SIZE_RANGE OutputSizeRange;
    D3D12_VIDEO_SCALE_SUPPORT_FLAGS Flags;
} D3D12_VIDEO_SCALE_SUPPORT;
```

Describes the supported scaling range of output sizes for a video scaler.

#### Members

`OutputSizeRange`

A [D3D12_VIDEO_SIZE_RANGE](#d3d12-video-size-range) structure describing the supported output size range for the scaler.

`Flags`

A member of the [D3D12_VIDEO_SCALE_SUPPORT_FLAGS](#d3d12-video-scale-support-flags) enumeration specifying the supported scaling capabilities of the scaler.

#### Remarks

By default, all possible output size combinations that exist between the maximum size and minimum size for the extent, inclusive, are supported. <ins><!-- d3d12-review-inline:begin:video-decode:P-video_scale_support-remarks:1 -->`Flags`<!-- d3d12-review-inline:end:video-decode:P-video_scale_support-remarks:1 --></ins> may add additional restrictions to the supported scale sizes. When scaling is not supported, the minimum and maximum sizes should both be set to the input size and no flags should be specified.

<a id="d3d12-video-decode-frame-argument"></a>

### D3D12_VIDEO_DECODE_FRAME_ARGUMENT

#### Declaration

```cpp
typedef struct D3D12_VIDEO_DECODE_FRAME_ARGUMENT
{
    D3D12_VIDEO_DECODE_ARGUMENT_TYPE Type;
    UINT Size;
    void *pData;
} D3D12_VIDEO_DECODE_FRAME_ARGUMENT;
```

Represents the decode parameters for a frame. Parameter definitions are specified by the codec specification for each decode profile.

#### Members

`Type`

A member of the [D3D12_VIDEO_DECODE_ARGUMENT_TYPE](#d3d12-video-decode-argument-type) enumeration specifying the type of argument.

`Size`

The size of the data in <ins><!-- d3d12-review-inline:begin:video-decode:P-video_decode_frame_argument-members:4 -->*pData*<!-- d3d12-review-inline:end:video-decode:P-video_decode_frame_argument-members:4 --></ins>, in bytes.

`pData`

A pointer to the argument data.

<a id="d3d12-video-decode-compressed-bitstream"></a>

### D3D12_VIDEO_DECODE_COMPRESSED_BITSTREAM

#### Declaration

```cpp
typedef struct D3D12_VIDEO_DECODE_COMPRESSED_BITSTREAM
{
    ID3D12Resource* pBuffer;
    UINT64 Offset;
    UINT64 Size;
} D3D12_VIDEO_DECODE_COMPRESSED_BITSTREAM;
```

Represents a compressed bitstream from which video is decoded.

#### Members

`pBuffer`

A pointer to an [ID3D12Resource](resources.md#resource-storage) representing the source buffer containing the compressed bitstream to decode.

`Offset`

The offset to the beginning of the first slice. This offset has alignment requirements based on the tier value of the video decoder. For more information on decoding tiers, see [D3D12_VIDEO_DECODE_TIER](#d3d12-video-decode-tier).

`Size`

The size of the subregion of *pBuffer* that contains the bitstream.

<a id="d3d12-video-decode-reference-frames"></a>

### D3D12_VIDEO_DECODE_REFERENCE_FRAMES

#### Declaration

```cpp
typedef struct D3D12_VIDEO_DECODE_REFERENCE_FRAMES
{
    UINT NumTexture2Ds;
    ID3D12Resource** ppTexture2Ds;
    UINT* pSubresources;
    ID3D12VideoDecoderHeap** ppHeaps; // If null, assume single decoder heap from input args.
} D3D12_VIDEO_DECODE_REFERENCE_FRAMES;
```

Contains the list of reference frames for the current decode operation. Either a texture array or an array of textures can be specified.

#### Members

`NumTexture2Ds`

The number of references specified in the *ppTexture2Ds* field.

`ppTexture2Ds`

<ins><!-- d3d12-review-inline:begin:video-decode:P-video_decode_reference_frames-members:4 -->A list of reference textures. When specifying texture arrays, each entry will point to the same resource. When specifying an array of textures, each entry will point to a separate resource.<!-- d3d12-review-inline:end:video-decode:P-video_decode_reference_frames-members:4 --></ins>

`pSubresources`

An array of subresource indices for the reference textures specified in *ppTexture2Ds*. NULL indicates that subresource 0 should be assumed for each resource.

With texture arrays within a single resource, the subresource indices point to the array index of the first resource plane. With an array of textures in individual resources, the subresource index is typically zero.

The video device driver uses the "PicEntry" indices defined in the DXVA spec for the codec to dereference this array to find the subresource index to use with the corresponding resource. For example, in HEVC, the Driver uses [DXVA_PicEntry_HEVC::Index7Bits](https://learn.microsoft.com/en-us/windows/win32/medfound/dxva-picentry-hevc) as an index for this array.

`ppHeaps`

An array of [ID3D12VideoDecoderHeap](#decode-objects) objects. This field is used with formats that support non-key frame resolution changes, allowing the caller to pass in the previous resolution's heap, relative to the reference it's being used for, in addition to the current resolution heap.

#### Remarks

Reference textures may have limitations such as a requirement to allocate reference buffers as a texture array. For information on the requirements for different decoder configurations, see [D3D12_VIDEO_DECODE_TIER](#d3d12-video-decode-tier).

<!-- d3d12-review-alert:begin:video-decode:N-reference-defaults:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> If `ppHeaps` is null, the input's current decoder heap is the default for
> the references, as declared in the released interface. **Qualification:**
> the documented null `pSubresources` default above conflicts with the inspected
> ordinary validation path. See the [reference array qualification](#decode-frame1).
> Mixed previous-resolution heaps are not a codec-independent permission;
> the applicable configuration flag and codec contract still govern them.

<!-- d3d12-review-alert:end:video-decode:N-reference-defaults:0 -->

<a id="d3d12-video-decode-input-stream-arguments"></a>

### D3D12_VIDEO_DECODE_INPUT_STREAM_ARGUMENTS

#### Declaration

```cpp
typedef struct D3D12_VIDEO_DECODE_INPUT_STREAM_ARGUMENTS
{
    UINT NumFrameArguments;
    D3D12_VIDEO_DECODE_FRAME_ARGUMENT FrameArguments[D3D12_VIDEO_DECODE_MAX_ARGUMENTS];
    D3D12_VIDEO_DECODE_REFERENCE_FRAMES ReferenceFrames;
    D3D12_VIDEO_DECODE_COMPRESSED_BITSTREAM CompressedBitstream;
    ID3D12VideoDecoderHeap *pHeap;
} D3D12_VIDEO_DECODE_INPUT_STREAM_ARGUMENTS;
```

Specifies the parameters for the input stream for a video decode operation.

#### Members

`NumFrameArguments`

The count of frame parameters provided in the *FrameArguments* field. The maximum number of frame arguments is 10.

`FrameArguments[10]`

An array of [D3D12_VIDEO_DECODE_FRAME_ARGUMENT](#d3d12-video-decode-frame-argument) structures containing the parameters to decode a frame.

`ReferenceFrames`

A [D3D12_VIDEO_DECODE_REFERENCE_FRAMES](#d3d12-video-decode-reference-frames) structure containing the reference frames needed to decode a frame.

`CompressedBitstream`

A [D3D12_VIDEO_DECODE_COMPRESSED_BITSTREAM](#d3d12-video-decode-compressed-bitstream) structure representing the compressed bitstream in a single continuous buffer.

`pHeap`

An [ID3D12VideoDecoderHeap](#decode-objects) representing a pointer to the heap for the current decode resolution.

<a id="d3d12-video-decode-conversion-arguments"></a>

### D3D12_VIDEO_DECODE_CONVERSION_ARGUMENTS

#### Declaration

```cpp
typedef struct D3D12_VIDEO_DECODE_CONVERSION_ARGUMENTS
{
    BOOL Enable;
    ID3D12Resource* pReferenceTexture2D;
    UINT ReferenceSubresource;
    DXGI_COLOR_SPACE_TYPE OutputColorSpace;
    DXGI_COLOR_SPACE_TYPE DecodeColorSpace;
} D3D12_VIDEO_DECODE_CONVERSION_ARGUMENTS;
```

<ins><!-- d3d12-review-inline:begin:video-decode:P-video_decode_conversion_arguments-summary:0 -->Specifies the parameters for decode output conversion. [D3D12_VIDEO_DECODE_CONVERSION_ARGUMENTS1](#d3d12-video-decode-conversion-arguments1) is used for the same purpose, but provides additional fields for output width and output height.<!-- d3d12-review-inline:end:video-decode:P-video_decode_conversion_arguments-summary:0 --></ins>

#### Members

`Enable`

A boolean value indicating whether decode conversion should be used.

`pReferenceTexture2D`

A pointer to an [ID3D12Resource](resources.md#resource-storage) containing the native decoding output. When downsampling is enabled, the output at native decode resolution, color space, and format may be required for future decode submissions (as reference frames, for instance).

`ReferenceSubresource`

The subresource index of the resource provided in <ins><!-- d3d12-review-inline:begin:video-decode:P-video_decode_conversion_arguments-members:6 -->*pReferenceTexture2D*<!-- d3d12-review-inline:end:video-decode:P-video_decode_conversion_arguments-members:6 --></ins> to use.

`OutputColorSpace`

A value from the [DXGI_COLOR_SPACE_TYPE](https://learn.microsoft.com/en-us/windows/desktop/api/dxgicommon/ne-dxgicommon-dxgi_color_space_type) enumeration specifying the target color space of the output.

`DecodeColorSpace`

A value from the [DXGI_COLOR_SPACE_TYPE](https://learn.microsoft.com/en-us/windows/desktop/api/dxgicommon/ne-dxgicommon-dxgi_color_space_type) enumeration specifying the source-decoded color space before conversion.

#### Remarks

Scaling is specified by the difference between the native decode texture size and the output texture size.

Use [D3D12_FEATURE_VIDEO_DECODE_CONVERSION_SUPPORT](#d3d12-feature-data-video-decode-conversion-support) to determine if a conversion combination is supported.

The source and destination resolution and format are communicated by the resource properties of decode textures and the output buffer specified in <ins><!-- d3d12-review-inline:begin:video-decode:P-video_decode_conversion_arguments-remarks:3 -->[ID3D12VideoDecodeCommandList::DecodeFrame](#decode-frame)<!-- d3d12-review-inline:end:video-decode:P-video_decode_conversion_arguments-remarks:3 --></ins>.

<!-- d3d12-review-alert:begin:video-decode:N-base-conversion-adjacent:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Qualification:** the preceding resource size description is a public
> source assertion, not an independently established legacy downscale guarantee.
> See the [legacy conversion qualification](#decode-frame1). The version-1
> conversion type has explicit dimensions.

<!-- d3d12-review-alert:end:video-decode:N-base-conversion-adjacent:0 -->

<a id="d3d12-video-decode-output-stream-arguments"></a>

### D3D12_VIDEO_DECODE_OUTPUT_STREAM_ARGUMENTS

#### Declaration

```cpp
typedef struct D3D12_VIDEO_DECODE_OUTPUT_STREAM_ARGUMENTS
{
    ID3D12Resource* pOutputTexture2D;
    UINT OutputSubresource;
    D3D12_VIDEO_DECODE_CONVERSION_ARGUMENTS ConversionArguments;
} D3D12_VIDEO_DECODE_OUTPUT_STREAM_ARGUMENTS;
```

Specifies the parameters for the output stream for a video decode operation. [D3D12_VIDEO_DECODE_OUTPUT_STREAM_ARGUMENTS1](#d3d12-video-decode-output-stream-arguments1) is used for the same purpose, but provides an additional field for histograms.

#### Members

`pOutputTexture2D`

An [ID3D12Resource](resources.md#resource-storage) representing the output texture. If decode conversion is enabled, this texture will contain the post-conversion output. If decode conversion is not enabled, this texture will contain the decode output.

`OutputSubresource`

The index of the output subresource of *pOutputTexture2D* to use. This allows you to specify array indices if the output is an array.

`ConversionArguments`

An optional [D3D12_VIDEO_DECODE_CONVERSION_ARGUMENTS](#d3d12-video-decode-conversion-arguments) structure containing output conversion parameters.

<a id="d3d12-video-decode-conversion-arguments1"></a>

### D3D12_VIDEO_DECODE_CONVERSION_ARGUMENTS1

#### Declaration

```cpp
typedef struct D3D12_VIDEO_DECODE_CONVERSION_ARGUMENTS1
{
    BOOL Enable;
    ID3D12Resource* pReferenceTexture2D;
    UINT ReferenceSubresource;
    DXGI_COLOR_SPACE_TYPE OutputColorSpace;
    DXGI_COLOR_SPACE_TYPE DecodeColorSpace;
    UINT OutputWidth;
    UINT OutputHeight;
} D3D12_VIDEO_DECODE_CONVERSION_ARGUMENTS1;
```

Specifies the parameters for decode output conversion. [D3D12_VIDEO_DECODE_CONVERSION_ARGUMENTS](#d3d12-video-decode-conversion-arguments) is used for the same purpose, but does not contain fields for output width and output height.

#### Members

`Enable`

A boolean value indicating whether decode conversion should be used.

`pReferenceTexture2D`

A pointer to an [ID3D12Resource](resources.md#resource-storage) containing the native decoding output. When downsampling is enabled, the output at native decode resolution, color space, and format may be required for future decode submissions (as reference frames, for instance).

`ReferenceSubresource`

The subresource index of the resource provided in <ins><!-- d3d12-review-inline:begin:video-decode:P-video_decode_conversion_arguments1-members:6 -->*pReferenceTexture2D*<!-- d3d12-review-inline:end:video-decode:P-video_decode_conversion_arguments1-members:6 --></ins> to use.

`OutputColorSpace`

A value from the [DXGI_COLOR_SPACE_TYPE](https://learn.microsoft.com/en-us/windows/desktop/api/dxgicommon/ne-dxgicommon-dxgi_color_space_type) enumeration specifying the target color space of the output.

`DecodeColorSpace`

A value from the [DXGI_COLOR_SPACE_TYPE](https://learn.microsoft.com/en-us/windows/desktop/api/dxgicommon/ne-dxgicommon-dxgi_color_space_type) enumeration specifying the source-decoded color space before conversion.

`OutputWidth`

The output width, in pixels.

`OutputHeight`

<ins><!-- d3d12-review-inline:begin:video-decode:P-video_decode_conversion_arguments1-members:14 -->The output height, in pixels.<!-- d3d12-review-inline:end:video-decode:P-video_decode_conversion_arguments1-members:14 --></ins>

<a id="d3d12-video-decode-output-histogram"></a>

### D3D12_VIDEO_DECODE_OUTPUT_HISTOGRAM

#### Declaration

```cpp
typedef struct D3D12_VIDEO_DECODE_OUTPUT_HISTOGRAM
{
    UINT64 Offset;
    ID3D12Resource* pBuffer;
} D3D12_VIDEO_DECODE_OUTPUT_HISTOGRAM;
```

Represents the histogram output buffer for a single component.

#### Members

`Offset`

The offset location in *pBuffer* to write the component histogram. Must be 256-byte aligned. Set to zero when a component is disabled.

`pBuffer`

<ins><!-- d3d12-review-inline:begin:video-decode:P-video_decode_output_histogram-members:4 -->An [ID3D12Resource](resources.md#resource-storage)<!-- d3d12-review-inline:end:video-decode:P-video_decode_output_histogram-members:4 --></ins> representing the target buffer for hardware to write the components histogram. Set to a nullptr when the component histogram is disabled.

#### Remarks

Histogram output buffers are provided in the *Histograms* field of the [D3D12_VIDEO_DECODE_OUTPUT_STREAM_ARGUMENTS1](#d3d12-video-decode-output-stream-arguments1) structure.

<a id="d3d12-video-decode-output-stream-arguments1"></a>

### D3D12_VIDEO_DECODE_OUTPUT_STREAM_ARGUMENTS1

#### Declaration

```cpp
typedef struct D3D12_VIDEO_DECODE_OUTPUT_STREAM_ARGUMENTS1
{
    ID3D12Resource* pOutputTexture2D;
    UINT OutputSubresource;
    D3D12_VIDEO_DECODE_CONVERSION_ARGUMENTS1 ConversionArguments;
    D3D12_VIDEO_DECODE_OUTPUT_HISTOGRAM Histograms[D3D12_VIDEO_DECODE_MAX_HISTOGRAM_COMPONENTS];
} D3D12_VIDEO_DECODE_OUTPUT_STREAM_ARGUMENTS1;
```

Specifies the parameters for the output stream for a video decode operation. [D3D12_VIDEO_DECODE_OUTPUT_STREAM_ARGUMENTS](#d3d12-video-decode-output-stream-arguments) is used for the same purpose, but does not provide a field for histograms.

#### Members

`pOutputTexture2D`

An [ID3D12Resource](resources.md#resource-storage) representing the output texture. If decode conversion is enabled, this texture will contain the post-conversion output. If decode conversion is not enabled, this texture will contain the decode output.

`OutputSubresource`

The index of the output subresource of *pOutputTexture2D* to use. This allows you to specify array indices if the output is an array.

`ConversionArguments`

<ins><!-- d3d12-review-inline:begin:video-decode:P-video_decode_output_stream_arguments1-members:6 -->An optional [D3D12_VIDEO_DECODE_CONVERSION_ARGUMENTS1](#d3d12-video-decode-conversion-arguments1) structure containing output conversion parameters.<!-- d3d12-review-inline:end:video-decode:P-video_decode_output_stream_arguments1-members:6 --></ins>

`Histograms[4]`

An array of [D3D12_VIDEO_DECODE_OUTPUT_HISTOGRAM](#d3d12-video-decode-output-histogram) <ins><!-- d3d12-review-inline:begin:video-decode:P-video_decode_output_stream_arguments1-members:8 -->structures specifying destinations for histogram data.<!-- d3d12-review-inline:end:video-decode:P-video_decode_output_stream_arguments1-members:8 --></ins> The maximum size of the array is 4.

<!-- d3d12-review-alert:begin:video-decode:N-resource-validation:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Scoped ordinary validation:** the inspected runtime rejects reserved
> compressed bitstream, reference, output and histogram resources. The bitstream
> is a nonempty buffer range: `Offset + Size` must fit in the buffer without
> overflow, and Offset is 128-byte aligned on this path. Reference/output
> pictures are Texture2D resources with one mip. Their selected subresource
> identifies plane 0 for the chosen array slice. The current heap configuration
> matches the decoder; reference formats match the applicable heap. The native
> decode picture's format matches the heap's Format. An enabled conversion has
> a non-null native reference destination.

<!-- d3d12-review-alert:end:video-decode:N-resource-validation:0 -->

<!-- d3d12-review-alert:begin:video-decode:N-resource-validation:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The normal output texture must not be reference-only. When separate
> reference-only allocations are required, output conversion supplies the native
> reference destination separately from the interoperable output.

<!-- d3d12-review-alert:end:video-decode:N-resource-validation:1 -->

<!-- d3d12-review-alert:begin:video-decode:N-resource-validation:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Qualification:** these scoped validation facts are not a complete codec
> validity definition or a conformance claim for every runtime/driver.
> Mixed-resolution reference heap applicability, null/default arrays and some
> size/error paths have unresolved evidence limits. The type definitions retain
> the public meanings without promising that every malformed description is
> rejected or every documented default works on the inspected path.

<!-- d3d12-review-alert:end:video-decode:N-resource-validation:2 -->

<a id="decode-capabilities"></a>

## Capability enums and tier constraints

<a id="d3d12-bitstream-encryption-type"></a>

### D3D12_BITSTREAM_ENCRYPTION_TYPE

#### Declaration

```cpp
typedef enum D3D12_BITSTREAM_ENCRYPTION_TYPE
{
    D3D12_BITSTREAM_ENCRYPTION_TYPE_NONE = 0,
} D3D12_BITSTREAM_ENCRYPTION_TYPE;
```

Specifies a bitstream encryption type. This enumeration is used by the [D3D12_VIDEO_DECODE_CONFIGURATION](#d3d12-video-decode-configuration) which describes the configuration for a video decoder.

#### Constants

##### D3D12_BITSTREAM_ENCRYPTION_TYPE_NONE

<ins><!-- d3d12-review-inline:begin:video-decode:P-bitstream_encryption_type-members:2 -->The bitstream is not encrypted.<!-- d3d12-review-inline:end:video-decode:P-bitstream_encryption_type-members:2 --></ins>

<a id="d3d12-video-frame-coded-interlace-type"></a>

### D3D12_VIDEO_FRAME_CODED_INTERLACE_TYPE

#### Declaration

```cpp
typedef enum D3D12_VIDEO_FRAME_CODED_INTERLACE_TYPE
{
    D3D12_VIDEO_FRAME_CODED_INTERLACE_TYPE_NONE = 0,
    D3D12_VIDEO_FRAME_CODED_INTERLACE_TYPE_FIELD_BASED = 1,
} D3D12_VIDEO_FRAME_CODED_INTERLACE_TYPE;
```

Specifies the interlace type of coded video frames.

#### Constants

##### D3D12_VIDEO_FRAME_CODED_INTERLACE_TYPE_NONE

The coded frames are not interlaced, often referred to as "progressive".

##### D3D12_VIDEO_FRAME_CODED_INTERLACE_TYPE_FIELD_BASED

<ins><!-- d3d12-review-inline:begin:video-decode:P-video_frame_coded_interlace_type-members:4 -->The coded frames may be interlaced.<!-- d3d12-review-inline:end:video-decode:P-video_frame_coded_interlace_type-members:4 --></ins>

<a id="d3d12-video-decode-support-flags"></a>

### D3D12_VIDEO_DECODE_SUPPORT_FLAGS

#### Declaration

```cpp
typedef enum D3D12_VIDEO_DECODE_SUPPORT_FLAGS
{
    D3D12_VIDEO_DECODE_SUPPORT_FLAG_NONE = 0x0,
    D3D12_VIDEO_DECODE_SUPPORT_FLAG_SUPPORTED = 0x1,

} D3D12_VIDEO_DECODE_SUPPORT_FLAGS;
```

Specifies whether a video decoding operation is supported.

#### Constants

##### D3D12_VIDEO_DECODE_SUPPORT_FLAG_NONE

The video decoding operation isn't supported.

##### D3D12_VIDEO_DECODE_SUPPORT_FLAG_SUPPORTED

<ins><!-- d3d12-review-inline:begin:video-decode:P-video_decode_support_flags-members:4 -->The video decoding operation is supported.<!-- d3d12-review-inline:end:video-decode:P-video_decode_support_flags-members:4 --></ins>

#### Remarks

This enumeration is used by the [D3D12_FEATURE_DATA_VIDEO_DECODE_SUPPORT](#d3d12-feature-data-video-decode-support) structure.

<a id="d3d12-video-decode-configuration-flags"></a>

### D3D12_VIDEO_DECODE_CONFIGURATION_FLAGS

#### Declaration

```cpp
typedef enum D3D12_VIDEO_DECODE_CONFIGURATION_FLAGS
{
    D3D12_VIDEO_DECODE_CONFIGURATION_FLAG_NONE                                      = 0x0,
    D3D12_VIDEO_DECODE_CONFIGURATION_FLAG_HEIGHT_ALIGNMENT_MULTIPLE_32_REQUIRED     = 0x1,
    D3D12_VIDEO_DECODE_CONFIGURATION_FLAG_POST_PROCESSING_SUPPORTED                 = 0x2,
    D3D12_VIDEO_DECODE_CONFIGURATION_FLAG_REFERENCE_ONLY_ALLOCATIONS_REQUIRED       = 0x4,
    D3D12_VIDEO_DECODE_CONFIGURATION_FLAG_ALLOW_RESOLUTION_CHANGE_ON_NON_KEY_FRAME  = 0x8,

} D3D12_VIDEO_DECODE_CONFIGURATION_FLAGS;
```

Specifies the configuration for video decoding.

#### Constants

##### D3D12_VIDEO_DECODE_CONFIGURATION_FLAG_NONE

No configuration flags.

##### D3D12_VIDEO_DECODE_CONFIGURATION_FLAG_HEIGHT_ALIGNMENT_MULTIPLE_32_REQUIRED

The height of the output decoded surfaces must be a multiple of 32.

##### D3D12_VIDEO_DECODE_CONFIGURATION_FLAG_POST_PROCESSING_SUPPORTED

The driver supports post processing. If this flag is set, the host decoder can set up post-processing by using the conversion flags in the [D3D12_VIDEO_DECODE_CONVERSION_ARGUMENTS](#d3d12-video-decode-conversion-arguments).

##### D3D12_VIDEO_DECODE_CONFIGURATION_FLAG_REFERENCE_ONLY_ALLOCATIONS_REQUIRED

Reference resources must be allocated with the [D3D12_RESOURCE_FLAG_VIDEO_DECODE_REFERENCE_ONLY](resources.md#d3d12-resource-flags) resource flag. <ins><!-- d3d12-review-inline:begin:video-decode:P-video_decode_configuration_flags-members:8 -->Reference textures<!-- d3d12-review-inline:end:video-decode:P-video_decode_configuration_flags-members:8 --></ins> must be separate from output textures, similar to performing a format conversion or downscale. This flag must not be set for [D3D12_VIDEO_DECODE_TIER_3](#d3d12-video-decode-tier) or greater.

##### D3D12_VIDEO_DECODE_CONFIGURATION_FLAG_ALLOW_RESOLUTION_CHANGE_ON_NON_KEY_FRAME

<ins><!-- d3d12-review-inline:begin:video-decode:P-video_decode_configuration_flags-members:10 -->The decode resolution can be changed on a non-key frame.<!-- d3d12-review-inline:end:video-decode:P-video_decode_configuration_flags-members:10 --></ins>

<!-- d3d12-review-alert:begin:video-decode:N-postprocess-height-qualification:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Configuration qualification:** the public POST_PROCESSING_SUPPORTED
> description refers to conversion, whose actual combination still requires the
> conversion support query. It does not establish that codec picture parameter
> post-processing switches are accepted. The inspected frame validation rejects
> such switches on its ordinary path.

<!-- d3d12-review-alert:end:video-decode:N-postprocess-height-qualification:0 -->

<!-- d3d12-review-alert:begin:video-decode:N-postprocess-height-qualification:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The public height alignment text above requires a multiple-of-32 decoded
> surface height. The inspected validation instead compares native reference
> height against the stream height rounded up to 32. This draft retains the
> source requirement but does not infer a complete conversion output height
> rule or a promise to reject every non-multiple allocation.

<!-- d3d12-review-alert:end:video-decode:N-postprocess-height-qualification:1 -->

<a id="d3d12-video-decode-conversion-support-flags"></a>

### D3D12_VIDEO_DECODE_CONVERSION_SUPPORT_FLAGS

#### Declaration

```cpp
typedef enum D3D12_VIDEO_DECODE_CONVERSION_SUPPORT_FLAGS
{
    D3D12_VIDEO_DECODE_CONVERSION_SUPPORT_FLAG_NONE = 0x0,
    D3D12_VIDEO_DECODE_CONVERSION_SUPPORT_FLAG_SUPPORTED = 0x1,

} D3D12_VIDEO_DECODE_CONVERSION_SUPPORT_FLAGS;
```

Specifies whether a video decode conversion operation is supported.

#### Constants

##### D3D12_VIDEO_DECODE_CONVERSION_SUPPORT_FLAG_NONE

The video decode conversion operation isn't supported.

##### D3D12_VIDEO_DECODE_CONVERSION_SUPPORT_FLAG_SUPPORTED

<ins><!-- d3d12-review-inline:begin:video-decode:P-video_decode_conversion_support_flags-members:4 -->The video decode conversion operation is supported.<!-- d3d12-review-inline:end:video-decode:P-video_decode_conversion_support_flags-members:4 --></ins>

#### Remarks

This enumeration is used by the [D3D12_FEATURE_DATA_VIDEO_DECODE_CONVERSION_SUPPORT](#d3d12-feature-data-video-decode-conversion-support) structure.

<a id="d3d12-video-scale-support-flags"></a>

### D3D12_VIDEO_SCALE_SUPPORT_FLAGS

#### Declaration

```cpp
typedef enum D3D12_VIDEO_SCALE_SUPPORT_FLAGS
{
    D3D12_VIDEO_SCALE_SUPPORT_FLAG_NONE = 0x0,
    D3D12_VIDEO_SCALE_SUPPORT_FLAG_POW2_ONLY = 0x1,
    D3D12_VIDEO_SCALE_SUPPORT_FLAG_EVEN_DIMENSIONS_ONLY = 0x2,
    D3D12_VIDEO_SCALE_SUPPORT_FLAG_DPB_ENCODER_RESOURCES = 0x4,

} D3D12_VIDEO_SCALE_SUPPORT_FLAGS;
```

Specifies the scaling capabilities of the video scaler.

#### Constants

##### D3D12_VIDEO_SCALE_SUPPORT_FLAG_NONE

All possible output size width/height combinations that exist between the maximum size and minimum size for the extent, inclusive, are supported.

##### D3D12_VIDEO_SCALE_SUPPORT_FLAG_POW2_ONLY

The scaler only supports output sizes at a power of two scale factors within the range. The x and y scale factors must be the same for both dimensions when this flag is set.

##### D3D12_VIDEO_SCALE_SUPPORT_FLAG_EVEN_DIMENSIONS_ONLY

<ins><!-- d3d12-review-inline:begin:video-decode:P-video_scale_support_flags-members:6 -->The scaler only supports output sizes with even output dimensions.<!-- d3d12-review-inline:end:video-decode:P-video_scale_support_flags-members:6 --></ins>

<a id="d3d12-video-decode-argument-type"></a>

### D3D12_VIDEO_DECODE_ARGUMENT_TYPE

#### Declaration

```cpp
typedef enum D3D12_VIDEO_DECODE_ARGUMENT_TYPE
{
    D3D12_VIDEO_DECODE_ARGUMENT_TYPE_PICTURE_PARAMETERS = 0,
    D3D12_VIDEO_DECODE_ARGUMENT_TYPE_INVERSE_QUANTIZATION_MATRIX = 1,
    D3D12_VIDEO_DECODE_ARGUMENT_TYPE_SLICE_CONTROL = 2,
    D3D12_VIDEO_DECODE_ARGUMENT_TYPE_HUFFMAN_TABLE = 3,
} D3D12_VIDEO_DECODE_ARGUMENT_TYPE;
```

Specifies the argument type of a [D3D12_VIDEO_DECODE_FRAME_ARGUMENT](#d3d12-video-decode-frame-argument).

#### Constants

##### D3D12_VIDEO_DECODE_ARGUMENT_TYPE_PICTURE_PARAMETERS

The argument is a picture decoding parameter buffer.

##### D3D12_VIDEO_DECODE_ARGUMENT_TYPE_INVERSE_QUANTIZATION_MATRIX

The argument is an inverse quantization matrix buffer.

##### D3D12_VIDEO_DECODE_ARGUMENT_TYPE_SLICE_CONTROL

<ins><!-- d3d12-review-inline:begin:video-decode:P-video_decode_argument_type-members:6 -->The argument is a slice control buffer.<!-- d3d12-review-inline:end:video-decode:P-video_decode_argument_type-members:6 --></ins>

#### Remarks

The values used with the argument type are defined by the DXVA specification for a given codec.

<!-- d3d12-review-alert:begin:video-decode:N-huffman-layout:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> For MJPEG decoding, `D3D12_VIDEO_DECODE_ARGUMENT_TYPE_HUFFMAN_TABLE`
> uses the published
> [`DXVA_HuffmanTable_MJPEG`](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/dxva/ns-dxva-dxva_huffmantable_mjpeg)
> payload. This codec-specific layout does not make the argument applicable
> to every decode profile. The [codec input boundary](#codec-input-boundary)
> governs payload/version matching.

<!-- d3d12-review-alert:end:video-decode:N-huffman-layout:0 -->

<a id="d3d12-video-decode-histogram-component"></a>

### D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT

#### Declaration

```cpp
typedef enum D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT
{
    D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_Y = 0,
    D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_U = 1,
    D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_V = 2,

    D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_R = 0,
    D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_G = 1,
    D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_B = 2,

    D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_A = 3,
} D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT;
```

Specifies indices for arrays of per component histogram information.

#### Constants

##### D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_Y

If the format is a YUV format, indicates a histogram for the Y component.

##### D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_U

If the format is a YUV format, indicates a histogram for the U component.

##### D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_V

If the format is a YUV format, indicates a histogram for the V component.

##### D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_R

If the format is an RGB/BGR format, indicates a histogram for the R component.

##### D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_G

If the format is an RGB/BGR format, indicates a histogram for the G component.

##### D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_B

If the format is an RGB/BGR format, indicates a histogram for the B component.

##### D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_A

<ins><!-- d3d12-review-inline:begin:video-decode:P-video_decode_histogram_component-members:14 -->If the format has an alpha channel, indicates a histogram for the A component.<!-- d3d12-review-inline:end:video-decode:P-video_decode_histogram_component-members:14 --></ins>

#### Remarks

The [D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAGS](#d3d12-video-decode-histogram-component-flags) is the flags enumeration used by [D3D12_FEATURE_DATA_VIDEO_DECODE_HISTOGRAM](#d3d12-feature-data-video-decode-histogram) <ins><!-- d3d12-review-inline:begin:video-decode:P-video_decode_histogram_component-remarks:1 -->to report the components for which histograms are supported.<!-- d3d12-review-inline:end:video-decode:P-video_decode_histogram_component-remarks:1 --></ins>

<a id="d3d12-video-decode-histogram-component-flags"></a>

### D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAGS

#### Declaration

```cpp
typedef enum D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAGS
{
    D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAG_NONE = 0x0,

    D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAG_Y = (1 << D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_Y),
    D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAG_U = (1 << D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_U),
    D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAG_V = (1 << D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_V),

    D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAG_R = (1 << D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_R),
    D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAG_G = (1 << D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_G),
    D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAG_B = (1 << D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_B),

    D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAG_A = (1 << D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_A),
} D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAGS;
```

Flags for indicating a subset of components used with video decode histogram. This enumeration is used by the [D3D12_FEATURE_DATA_VIDEO_DECODE_HISTOGRAM](#d3d12-feature-data-video-decode-histogram) structure.

#### Constants

##### D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAG_NONE

No associated component.

##### D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAG_Y

If the format is a YUV format, indicates the Y component.

##### D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAG_U

If the format is a YUV format, indicates the U component.

##### D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAG_V

If the format is a YUV format, indicates the V component.

##### D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAG_R

If the format is an RGB/BGR format, indicates the R component.

##### D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAG_G

If the format is an RGB/BGR format, indicates the G component.

##### D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAG_B

If the format is an RGB/BGR format, indicates the B component.

##### D3D12_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAG_A

<ins><!-- d3d12-review-inline:begin:video-decode:P-video_decode_histogram_component_flags-members:16 -->If the format is an RGB/BGR format, indicates the A component.<!-- d3d12-review-inline:end:video-decode:P-video_decode_histogram_component_flags-members:16 --></ins>

<a id="d3d12-video-decode-tier"></a>

### D3D12_VIDEO_DECODE_TIER

#### Declaration

```cpp
typedef enum D3D12_VIDEO_DECODE_TIER
{
    D3D12_VIDEO_DECODE_TIER_NOT_SUPPORTED = 0,
    D3D12_VIDEO_DECODE_TIER_1 = 1,
    D3D12_VIDEO_DECODE_TIER_2 = 2,
    D3D12_VIDEO_DECODE_TIER_3 = 3,
} D3D12_VIDEO_DECODE_TIER;
```

#### D3D12_VIDEO_DECODE_TIER_NOT_SUPPORTED

Video decoding is not supported.

#### D3D12_VIDEO_DECODE_TIER_1

In tier 1, the hardware decoder requires that the application allocate reference textures as a texture array. This is to accommodate hardware requirements that the textures be "close" in address space because the hardware doesn't support a full size pointer for each individual picture buffer. Instead it has one pointer and a more limited bit offset. For more information on texture arrays, see [Introduction To Textures in Direct3D 11](resources.md#resource-dimensions).

<ins><!-- d3d12-review-inline:begin:video-decode:P-tier-1:1 -->If the decoder hardware requires a unique memory layout that is not supported for operations on other engines or different video operations, the decoder may set the [D3D12_VIDEO_DECODE_CONFIGURATION_FLAG_REFERENCE_ONLY_ALLOCATIONS_REQUIRED](#d3d12-video-decode-configuration-flags) configuration flag in the [D3D12_FEATURE_DATA_VIDEO_DECODE_SUPPORT](#d3d12-feature-data-video-decode-support) structure when queried for profile support. This flag indicates that the application must allocate references with the [D3D12_RESOURCE_FLAG_VIDEO_DECODE_REFERENCE_ONLY](resources.md#d3d12-resource-flags) flag. The application should use the [D3D12_VIDEO_DECODE_CONVERSION_ARGUMENTS](#d3d12-video-decode-conversion-arguments) structure to set a reference-only output if the output is needed as a future reference frame. The output frame passed to [ID3D12VideoDecodeCommandList::DecodeFrame](#decode-frame) is a D3D12 resource that can be consumed by other portions of the pipeline and must not have the D3D12\_RESOURCE\_FLAG\_VIDEO\_DECODE\_REFERENCE\_ONLY flag.<!-- d3d12-review-inline:end:video-decode:P-tier-1:1 --></ins>

##### Tier 1 requirements for compressed input buffers

-  <ins><!-- d3d12-review-inline:begin:video-decode:P-tier-1:3 -->All slices for a given frame must be placed in order and must be contiguous, i.e. there must be no gaps between slices. Slice control buffers must specify offset and size parameters that meet this requirement.<!-- d3d12-review-inline:end:video-decode:P-tier-1:3 --></ins>
- The first slice must begin on a 128 Byte boundary. The offset set in the [D3D12_VIDEO_DECODE_COMPRESSED_BITSTREAM](#d3d12-video-decode-compressed-bitstream) structure must be a multiple of 128 Bytes.
- Decoding is supported from buffers allocated with [D3D12_MEMORY_POOL_L0](resources.md#d3d12-memory-pool). This is always system memory, but still a D3D12 buffer.
- Decoding is supported from buffers allocated with D3D12\_MEMORY\_POOL\_L1, the default pool, including those allocated with D3D12\_CPU\_PAGE\_PROPERTY\_NOT\_AVAILABLE.

#### D3D12_VIDEO_DECODE_TIER_2

<ins><!-- d3d12-review-inline:begin:video-decode:P-tier-2:0 -->In decode tier 2, textures can be referenced as a texture array or as an array of separate texture 2D resources (each resource having array size of 1). This is more flexible for the caller and is important in scenarios where the resolution changes frequently such as in streaming video, because a texture array can only be allocated and deallocated as a single unit, but separate texture 2D resources can be allocated and deallocated individually. If decode hardware requires a unique tiling format that is not supported for operations on other engines or different video operations, the decoder may set the [D3D12_VIDEO_DECODE_CONFIGURATION_FLAG_REFERENCE_ONLY_ALLOCATIONS_REQUIRED](#d3d12-video-decode-configuration-flags) configuration flag in the [D3D12_FEATURE_DATA_VIDEO_DECODE_SUPPORT](#d3d12-feature-data-video-decode-support) structure when queried for profile support. This flag indicates that the application must allocate references with the [D3D12_RESOURCE_FLAG_VIDEO_DECODE_REFERENCE_ONLY](resources.md#d3d12-resource-flags) flag. The application should use the [D3D12_VIDEO_DECODE_CONVERSION_ARGUMENTS](#d3d12-video-decode-conversion-arguments) structure to set a reference only output if the output is needed as a future reference frame. The output frame passed to [ID3D12VideoDecodeCommandList::DecodeFrame](#decode-frame) is a D3D12 resource that can be consumed by other portions of the pipeline and must not have the D3D12\_RESOURCE\_FLAG\_VIDEO\_DECODE\_REFERENCE\_ONLY flag.<!-- d3d12-review-inline:end:video-decode:P-tier-2:0 --></ins>

##### Tier 2 requirements for compressed input buffers

These requirements are identical to the tier 1 requirements.

- All slices for a given frame must be placed in order and must be contiguous, i.e. there must be no gaps between slices. Slice control buffers must specify offset and size parameters that meet this requirement.
- The first slice must begin on a 128 Byte boundary. The offset set in the [D3D12_VIDEO_DECODE_COMPRESSED_BITSTREAM](#d3d12-video-decode-compressed-bitstream) structure must be a multiple of 128 Bytes.
- Decoding is supported from buffers allocated with [D3D12_MEMORY_POOL_L0](resources.md#d3d12-memory-pool). This is always system memory, but still a D3D12 buffer.
- <ins><!-- d3d12-review-inline:begin:video-decode:P-tier-2:3 -->Decoding is supported from buffers allocated with D3D12\_MEMORY\_POOL\_L1, the default pool, including those allocated with D3D12\_CPU\_PAGE\_PROPERTY\_NOT\_AVAILABLE.<!-- d3d12-review-inline:end:video-decode:P-tier-2:3 --></ins>

<!-- d3d12-review-alert:begin:video-decode:N-tier-qualification:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Tier-3 qualification:** a complete tier-3 layout, packing and support
> guarantee is not established here. The declared value does not by itself
> establish those capabilities. The established
> [reference-only resource restriction](resources.md#d3d12_resource_flag_video_decode_reference_only)
> is not retracted.

<!-- d3d12-review-alert:end:video-decode:N-tier-qualification:0 -->

<!-- d3d12-review-alert:begin:video-decode:N-tier-qualification:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A frame argument enum member does not establish that every decode profile
> accepts that argument type. The codec's DXVA contract determines the applicable
> buffers.

<!-- d3d12-review-alert:end:video-decode:N-tier-qualification:1 -->

<a id="codec-input-boundary"></a>

## Codec input boundary

<!-- d3d12-review-alert:begin:video-decode:N-codec-boundary:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12_VIDEO_DECODE_FRAME_ARGUMENT.Type` identifies picture parameters,
> inverse quantization matrices, slice controls or Huffman tables. `Size` is
> the byte size of the corresponding typed payload and `pData` points to those
> bytes. These are not shader constants or a portable untyped parameter grammar.
> `NumFrameArguments <= 10` is the generic descriptor capacity, not a guarantee
> that a codec accepts ten arbitrary arguments or every enumerated type.

<!-- d3d12-review-alert:end:video-decode:N-codec-boundary:0 -->

<!-- d3d12-review-alert:begin:video-decode:N-codec-boundary:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The codec/profile's DXVA specification supplies the buffer layouts and meanings.
> For example, the public
> [`DXVA_PicEntry_HEVC`](https://learn.microsoft.com/en-us/windows/win32/medfound/dxva-picentry-hevc)
> defines `Index7Bits`. The D3D12 reference frame contract uses that codec index
> to dereference the supplied reference/subresource arrays. It is not a GPU
> address or a D3D12 resource identifier. Published
> [DXVA declarations](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/dxva/)
> and the
> [H.264/AVC DXVA specification](https://www.microsoft.com/en-us/download/details.aspx?id=11323)
> and
> [HEVC DXVA specification](https://www.microsoft.com/en-us/download/details.aspx?id=39947)
> are external authorities, not additional APIs declared by this chapter.

<!-- d3d12-review-alert:end:video-decode:N-codec-boundary:1 -->

<!-- d3d12-review-alert:begin:video-decode:N-codec-boundary:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Codec layout qualification:** this selected generic baseline does not
> reproduce or certify every codec's picture parameter, matrix, slice/tile control
> or Huffman layout, profile mapping, bitstream grammar and invalid-bitstream
> recovery rules. A profile GUID or a released C declaration alone does not
> establish those behavioral contracts. Codec-specific layout/version matching
> remains an explicit external boundary. This draft does not substitute invented
> buffers or a universal supported profile list.

<!-- d3d12-review-alert:end:video-decode:N-codec-boundary:2 -->

<a id="decode-driver"></a>

## Published driver and hardware responsibilities

<!-- d3d12-review-alert:begin:video-decode:N-ddi-overview:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The following DDIs implement decode capability queries, object creation/destruction and frame recording. The runtime can cache and translate capability results.

<!-- d3d12-review-alert:end:video-decode:N-ddi-overview:0 -->

### Video capability query

The D3D runtime calls a client driver's **PFND3D12DDI\_VIDEO\_GETCAPS** function to query for video-related support provided by the driver for a specified type.

```cpp
typedef HRESULT (APIENTRY *PFND3D12DDI_VIDEO_GETCAPS)(
    D3D12DDI_HDEVICE hDrvDevice,
    _In_ CONST D3D12DDIARG_VIDEO_GETCAPS_0020* pArgs
    );
```

#### Parameters

`[in] hDrvDevice`

The handle of a device.

`[in, out] pArgs`

Pointer to a caller-allocated [**D3D12DDIARG\_VIDEO\_GETCAPS\_0020**](#ddi-capability-payloads) structure used to request a video-specific capability.

#### Return values

If this function succeeds, it returns **S\_OK**. Otherwise, it returns an **HRESULT** error code.

### Decoder private CPU object sizing

<ins><!-- d3d12-review-inline:begin:video-decode:P-ddi-size-decoder-summary:0 -->`PFND3D12DDI_CALCPRIVATEVIDEODECODERSIZE_0072` calculates the size of a video decoder. The D3D runtime allocates memory for storing the driver's CPU object representing the video decoder.<!-- d3d12-review-inline:end:video-decode:P-ddi-size-decoder-summary:0 --></ins>

#### Parameters

`hDrvDevice`

The hardware device being processed.

`[in] pArgs`

The arguments used to create a video decoder.

#### Return values

Returns the size of the video decoder in bytes.

#### Remarks

The runtime allocates memory for storing the driver CPU object that represents the video decoder. This method is used to calculate the driver object size.

### Decoder heap private CPU object sizing

<ins><!-- d3d12-review-inline:begin:video-decode:P-ddi-size-heap-summary:0 -->`PFND3D12DDI_CALCPRIVATEVIDEODECODERHEAPSIZE_0072` calculates the size of a video decoder heap. The D3D runtime allocates memory for storing the driver's CPU object representing the video decoder heap.<!-- d3d12-review-inline:end:video-decode:P-ddi-size-heap-summary:0 --></ins>

#### Parameters

`hDrvDevice`

The hardware device being processed.

`pArgs`

The arguments used to create a video decoder heap.

#### Return values

Returns the size of the heap in bytes.

### Decoder creation

<ins><!-- d3d12-review-inline:begin:video-decode:P-ddi-create-decoder-summary:0 -->`PFND3D12DDI_CREATEVIDEODECODER_0072` creates a video decoder.<!-- d3d12-review-inline:end:video-decode:P-ddi-create-decoder-summary:0 --></ins>

#### Parameters

`hDrvDevice`

The hardware device being processed.

`pArgs`

The arguments used to create a video decoder.

`hDrvVideoDecoder`

The video decoder.

### Decoder heap creation

<ins><!-- d3d12-review-inline:begin:video-decode:P-ddi-create-heap-summary:0 -->`PFND3D12DDI_CREATEVIDEODECODERHEAP_0072` creates a video decoder heap.<!-- d3d12-review-inline:end:video-decode:P-ddi-create-heap-summary:0 --></ins>

#### Parameters

`hDrvDevice`

The hardware device being processed.

<ins><!-- d3d12-review-inline:begin:video-decode:P-ddi-create-heap-params:3 -->`pArgs`<!-- d3d12-review-inline:end:video-decode:P-ddi-create-heap-params:3 --></ins>

The arguments used to create a video decoder heap.

`hDrvVideoDecoderHeap`

The video decoder heap.

<a id="decode-frame-recording-callback"></a>

### Decode frame recording DDI

<ins><!-- d3d12-review-inline:begin:video-decode:P-ddi-decode-summary:0 -->**PFND3D12DDI\_VIDEO\_DECODE\_FRAME\_0041\_1** records a decode frame operation to the command list. Inputs, outputs, and parameters for the decode are specified as arguments to this method.<!-- d3d12-review-inline:end:video-decode:P-ddi-decode-summary:0 --></ins>

#### Parameters

`hDrvCommandList`

A handle to the driver's data for the command list. The driver uses this region of memory to store internal data structures that are related to its command list.

`hDrvDecoder`

The video decoder that contains internal state for this decode session. Examples include motion vectors, internal temporary allocations, etc. See [Creating a Video Decoder](#decode-driver).

`pOutputStreamParameters`

Specifies the output surface and output parameters. See [D3D12DDI_VIDEO_DECODE_OUTPUT_STREAM_ARGUMENTS](#ddi-argument-layouts).

`pInputStreamParameters`

Specifies the input bit stream, parameters, reference frames, and other input parameters for the decode operation. See [D3D12DDI_VIDEO_DECODE_INPUT_STREAM_ARGUMENTS](#ddi-argument-layouts).

#### Return values

None

<a id="versioned-decode-frame-recording-callback"></a>

### Versioned decode frame recording DDI

<ins><!-- d3d12-review-inline:begin:video-decode:P-ddi-decode1-summary:0 -->The client driver implements this DDI to decode a video frame.<!-- d3d12-review-inline:end:video-decode:P-ddi-decode1-summary:0 --></ins>

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_VIDEO_DECODE_FRAME_0041_1 )(
    D3D12DDI_HCOMMANDLIST hDrvCommandList,
    D3D12DDI_HVIDEODECODER_0020 hDrvDecoder,
    const D3D12DDI_VIDEO_DECODE_OUTPUT_STREAM_ARGUMENTS_0041_1* pOutputStreamParameters,
    const D3D12DDI_VIDEO_DECODE_INPUT_STREAM_ARGUMENTS_0032* pInputStreamParameters
    );
```

#### Parameters

`hDrvCommandList`

A handle to the driver's data for the command list. The driver uses this region of memory to store internal data structures that are related to its command list.

`hDrvDecoder`

The video decoder that contains internal state for this decode session. Examples include motion vectors, internal temporary allocations, etc. See [Creating a Video Decoder](#decode-driver).

`pOutputStreamParameters`

Specifies the output surface and output parameters. See [D3D12DDI_VIDEO_DECODE_OUTPUT_STREAM_ARGUMENTS](#ddi-argument-layouts).

`pInputStreamParameters`

Specifies the input bit stream, parameters, reference frames, and other input parameters for the decode operation. See [D3D12DDI_VIDEO_DECODE_INPUT_STREAM_ARGUMENTS](#ddi-argument-layouts).

#### Return values

None

<a id="ddi-argument-layouts"></a>

### Driver argument layouts

<!-- d3d12-review-alert:begin:video-decode:N-ddi-layout-roles:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12DDI_VIDEO_DECODE_CONFIGURATION_0020.BitstreamEncryption` uses a GUID rather than the API enum. The unencrypted value is `D3D12DDI_VIDEO_DECODE_BITSTREAM_ENCRYPTION_NONE`. Its decryption handle, pointers, sizes and counts are zero.

<!-- d3d12-review-alert:end:video-decode:N-ddi-layout-roles:1 -->

#### Configuration and creation

```cpp
typedef enum D3D12DDI_VIDEO_CODED_INTERLACE_TYPE_0020
{
    D3D12DDI_VIDEO_CODED_INTERLACE_TYPE_0020_NONE = 0,
    D3D12DDI_VIDEO_CODED_INTERLACE_TYPE_0020_FIELD_BASED = 1,
} D3D12DDI_VIDEO_CODED_INTERLACE_TYPE_0020;
```

```cpp
typedef struct D3D12DDI_VIDEO_DECODE_CONFIGURATION_0020
{
    GUID DecodeProfile;
    GUID BitstreamEncryption;
    D3D12DDI_VIDEO_CODED_INTERLACE_TYPE_0020 InterlaceType;
} D3D12DDI_VIDEO_DECODE_CONFIGURATION_0020;
```

```cpp
DEFINE_GUID(D3D12DDI_VIDEO_DECODE_BITSTREAM_ENCRYPTION_NONE, 0x1b81beD0, 0xa0c7, 0x11d3, 0xb9, 0x84, 0x00, 0xc0, 0x4f, 0x2e, 0x73, 0xc5);
```

```cpp
typedef struct D3D12DDIARG_CREATE_VIDEO_DECODER_HEAP_0033
{
    UINT NodeMask;
    D3D12DDI_VIDEO_DECODE_CONFIGURATION_0020    Configuration;
    UINT                                        DecodeWidth;
    UINT                                        DecodeHeight;
    DXGI_FORMAT                                 Format;
    DXGI_RATIONAL                               FrameRate;
    UINT                                        BitRate;
    UINT                                        MaxDecodePictureBufferCount;
} D3D12DDIARG_CREATE_VIDEO_DECODER_HEAP_0033;
```

#### Frame input

```cpp
typedef enum D3D12DDI_VIDEO_DECODE_PARAMETER_TYPE_0020
{
    D3D12DDI_VIDEO_DECODE_PARAMETER_TYPE_0020_PICTURE_PARAMETERS = 0,
    D3D12DDI_VIDEO_DECODE_PARAMETER_TYPE_0020_INVERSE_QUANTIZATION_MATRIX = 1,
    D3D12DDI_VIDEO_DECODE_PARAMETER_TYPE_0020_SLICE_CONTROL = 2,
    D3D12DDI_VIDEO_DECODE_PARAMETER_TYPE_0097_HUFFMAN_TABLE = 3,
} D3D12DDI_VIDEO_DECODE_PARAMETER_TYPE_0020;
```

```cpp
#define D3D12DDI_VIDEO_DECODE_MAX_ARGUMENTS_0020 10
```

```cpp
typedef struct D3D12DDI_VIDEO_DECODE_FRAME_ARGUMENT_0020
{
    D3D12DDI_VIDEO_DECODE_PARAMETER_TYPE_0020 Type;
    void *pData;
    UINT Size;
} D3D12DDI_VIDEO_DECODE_FRAME_ARGUMENT_0020;
```

```cpp
typedef struct D3D12DDI_VIDEO_DECODE_REFERENCE_FRAMES_0032
{
    D3D12DDI_HRESOURCE* hDrvTexture2Ds;
    UINT* pSubresources;
    D3D12DDI_HVIDEODECODERHEAP_0032* hDrvVideoDecoderHeaps;
    UINT NumTexture2Ds;
} D3D12DDI_VIDEO_DECODE_REFERENCE_FRAMES_0032;
```

```cpp
typedef struct D3D12DDI_VIDEO_DECODE_COMPRESSED_BITSTREAM_0032
{
    D3D12DDI_HRESOURCE hDrvBuffer;
    UINT64 Offset;
    UINT64 Size;
} D3D12DDI_VIDEO_DECODE_COMPRESSED_BITSTREAM_0032;
```

```cpp
typedef struct D3D12DDI_VIDEO_DECODE_DECRYPTION_ARGUMENTS_0030
{
    D3D12DDI_HCRYPTOSESSIONPOLICY_0030 hDrvCryptoSessionPolicy;
    CONST VOID* pIV;
    UINT IVSize;
    CONST VOID* pSubSampleMappingBlock;
    UINT SubSampleMappingCount;
} D3D12DDI_VIDEO_DECODE_DECRYPTION_ARGUMENTS_0030;
```

```cpp
typedef struct D3D12DDI_VIDEO_DECODE_INPUT_STREAM_ARGUMENTS_0032
{
    D3D12DDI_VIDEO_DECODE_FRAME_ARGUMENT_0020 FrameArguments[D3D12DDI_VIDEO_DECODE_MAX_ARGUMENTS_0020];
    UINT NumFrameArguments;
    D3D12DDI_VIDEO_DECODE_REFERENCE_FRAMES_0032 ReferenceFrames;
    D3D12DDI_VIDEO_DECODE_COMPRESSED_BITSTREAM_0032 CompressedBitstream;
    D3D12DDI_VIDEO_DECODE_DECRYPTION_ARGUMENTS_0030 DecryptionParameters;
    D3D12DDI_HVIDEODECODERHEAP_0032 hDrvVideoDecoderHeap;
} D3D12DDI_VIDEO_DECODE_INPUT_STREAM_ARGUMENTS_0032;
```

#### Output, conversion and histogram variants

```cpp
#define D3D12DDI_VIDEO_DECODE_MAX_HISTOGRAM_COMPONENTS 4
```

```cpp
typedef struct D3D12DDI_VIDEO_DECODE_COMPONENT_HISTOGRAM_0041
{
    UINT64 Offset;
    D3D12DDI_HRESOURCE hDrvBuffer;
} D3D12DDI_VIDEO_DECODE_COMPONENT_HISTOGRAM_0041;
```

```cpp
typedef struct D3D12DDI_VIDEO_DECODE_CONVERSION_ARGUMENTS_0041
{
    BOOL Enable;
    D3D12DDI_HRESOURCE hDrvReferenceTexture2D;
    UINT ReferenceSubresource;
    DXGI_COLOR_SPACE_TYPE OutputColorSpace;
    DXGI_COLOR_SPACE_TYPE DecodeColorSpace;
    UINT OutputWidth;
    UINT OutputHeight;
} D3D12DDI_VIDEO_DECODE_CONVERSION_ARGUMENTS_0041;
```

```cpp
typedef struct D3D12DDI_VIDEO_DECODE_OUTPUT_STREAM_ARGUMENTS_0041_1
{
    D3D12DDI_HRESOURCE hDrvOutputTexture2D;
    UINT OutputSubresource;
    D3D12DDI_VIDEO_DECODE_CONVERSION_ARGUMENTS_0041 ConversionArguments;
    D3D12DDI_VIDEO_DECODE_COMPONENT_HISTOGRAM_0041 Histograms[D3D12DDI_VIDEO_DECODE_MAX_HISTOGRAM_COMPONENTS];
} D3D12DDI_VIDEO_DECODE_OUTPUT_STREAM_ARGUMENTS_0041_1;
```

<!-- d3d12-review-alert:begin:video-decode:N-ddi-layout-versioning:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Current decoding uses `_0032` input stream arguments and `_0041_1` output arguments, including four histogram destinations and explicit conversion dimensions. `_0033` remains the heap size capability description, while current heap creation uses `_0072`.

<!-- d3d12-review-alert:end:video-decode:N-ddi-layout-versioning:0 -->

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_DESTROYVIDEODECODER_0021 )( D3D12DDI_HDEVICE hDrvDevice, D3D12DDI_HVIDEODECODER_0020 hDrvVideoDecoder );
```

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_DESTROYVIDEODECODERHEAP_0032 )( D3D12DDI_HDEVICE hDrvDevice, D3D12DDI_HVIDEODECODERHEAP_0032 hDrvVideoDecoderHeap );
```

<a id="ddi-capability-payloads"></a>

### Decode capability payloads

```cpp
typedef struct D3D12DDIARG_VIDEO_GETCAPS_0020
{
    D3D12DDICAPS_TYPE_VIDEO_0020 Type;
    VOID* pInfo;
    VOID* pData;
    UINT DataSize;
} D3D12DDIARG_VIDEO_GETCAPS_0020;
```

<!-- d3d12-review-alert:begin:video-decode:N-ddi-caps-boundary:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `Type` selects the capability payload and its `pInfo`, `pData` and `DataSize` protocol. The following definitions specify each request.

<!-- d3d12-review-alert:end:video-decode:N-ddi-caps-boundary:0 -->

<!-- d3d12-review-alert:begin:video-decode:N-ddi-cap-values:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Capability (`D3D12DDICAPS_TYPE_VIDEO_0020`) | Value |
> |---|---|
> | `D3D12DDICAPS_TYPE_VIDEO_0020_DECODE_SUPPORT` | 0 |
> | `D3D12DDICAPS_TYPE_VIDEO_0020_DECODE_PROFILES` | 1 |
> | `D3D12DDICAPS_TYPE_VIDEO_0020_DECODE_FORMATS` | 2 |
> | `D3D12DDICAPS_TYPE_VIDEO_0020_DECODE_CONVERSION_SUPPORT` | 3 |
> | `D3D12DDICAPS_TYPE_VIDEO_0032_DECODER_HEAP_SIZE` | 8 |
> | `D3D12DDICAPS_TYPE_VIDEO_0032_DECODE_PROFILE_COUNT` | 10 |
> | `D3D12DDICAPS_TYPE_VIDEO_0032_DECODE_FORMAT_COUNT` | 11 |
> | `D3D12DDICAPS_TYPE_VIDEO_0040_DECODE_HISTOGRAM` | 18 |

<!-- d3d12-review-alert:end:video-decode:N-ddi-cap-values:0 -->

```cpp
typedef struct D3D12DDI_VIDEO_DECODE_PROFILE_COUNT_DATA_0032
{
    UINT NodeIndex;                                             // input
    UINT ProfileCount;                                          // output
} D3D12DDI_VIDEO_DECODE_PROFILE_COUNT_DATA_0032;
```

```cpp
typedef struct D3D12DDI_VIDEO_DECODE_PROFILES_DATA_0020
{
    UINT NodeIndex;                                  // input
    UINT ProfileCount;                               // input
    GUID *pProfiles;                                 // output
} D3D12DDI_VIDEO_DECODE_PROFILES_DATA_0020;
```

```cpp
typedef struct D3D12DDI_VIDEO_DECODE_FORMAT_COUNT_DATA_0032
{
    UINT NodeIndex;                                                             // input
    D3D12DDI_VIDEO_DECODE_CONFIGURATION_0020 Configuration;                     // input
    UINT FormatCount;                                                           // output
} D3D12DDI_VIDEO_DECODE_FORMAT_COUNT_DATA_0032;
```

```cpp
typedef struct D3D12DDI_VIDEO_DECODE_FORMATS_DATA_0020
{
    UINT NodeIndex;                                          // input
    D3D12DDI_VIDEO_DECODE_CONFIGURATION_0020 Configuration;  // input
    UINT FormatCount;                                        // input
    DXGI_FORMAT *pOutputFormats;                             // output
} D3D12DDI_VIDEO_DECODE_FORMATS_DATA_0020;
```

```cpp
typedef struct D3D12DDI_VIDEO_DECODE_SUPPORT_DATA_0020
{
    UINT NodeIndex;                                                         // input
    D3D12DDI_VIDEO_DECODE_CONFIGURATION_0020 Configuration;                 // input
    UINT Width;                                                             // input
    UINT Height;                                                            // input
    DXGI_FORMAT DecodeFormat;                                               // input
    DXGI_RATIONAL FrameRate;                                                // input
    UINT BitRate;                                                           // input
    D3D12DDI_VIDEO_DECODE_SUPPORT_FLAGS_0020 SupportFlags;                  // output
    D3D12DDI_VIDEO_DECODE_CONFIGURATION_FLAGS_0020 ConfigurationFlags;      // output
    D3D12DDI_VIDEO_DECODE_TIER_0020 DecodeTier;                             // output
} D3D12DDI_VIDEO_DECODE_SUPPORT_DATA_0020;
```

```cpp
typedef struct D3D12DDI_VIDEO_DECODE_CONVERSION_SUPPORT_DATA_0032
{
    UINT NodeIndex;                                                            // input
    D3D12DDI_VIDEO_DECODE_CONFIGURATION_0020 Configuration;                    // input
    D3D12DDI_VIDEO_SAMPLE_DESCRIPTION_0020 DecodeSample;                       // input
    D3D12DDI_VIDEO_FORMAT_DESCRIPTION_0020 OutputFormat;                       // input
    DXGI_RATIONAL FrameRate;                                                   // input
    UINT BitRate;                                                              // input
    D3D12DDI_VIDEO_DECODE_CONVERSION_SUPPORT_FLAGS_0020 SupportFlags;          // output
    D3D12DDI_VIDEO_SCALE_SUPPORT_0032 ScaleSupport;                            // output
} D3D12DDI_VIDEO_DECODE_CONVERSION_SUPPORT_DATA_0032;
```

```cpp
typedef struct D3D12DDI_VIDEO_DECODER_HEAP_SIZE_DATA_0033
{
    D3D12DDIARG_CREATE_VIDEO_DECODER_HEAP_0033 VideoDecoderHeapDesc;    // input
    UINT64 MemoryPoolL0Size;                                            // output
    UINT64 MemoryPoolL1Size;                                            // output
} D3D12DDI_VIDEO_DECODER_HEAP_SIZE_DATA_0033;
```

```cpp
typedef struct D3D12DDI_VIDEO_DECODE_HISTOGRAM_DATA_0041
{
    UINT NodeIndex;                                                         // in
    GUID DecodeProfile;                                                     // in
    UINT Width;                                                             // in
    UINT Height;                                                            // in
    DXGI_FORMAT DecodeFormat;                                               // in
    D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAGS_0041 Components;        // out
    UINT BinCount;                                                          // out
    UINT CounterBitDepth;                                                   // out
} D3D12DDI_VIDEO_DECODE_HISTOGRAM_DATA_0041;
```

```cpp
typedef enum D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_0041
{
    D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_0041_Y = 0,
    D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_0041_U = 1,
    D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_0041_V = 2,

    D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_0041_R = 0,
    D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_0041_G = 1,
    D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_0041_B = 2,

    D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_0041_A = 3,
} D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_0041;
```

```cpp
typedef enum D3D12DDI_VIDEO_DECODE_SUPPORT_FLAGS_0020
{
    D3D12DDI_VIDEO_DECODE_SUPPORT_FLAG_0020_NONE                    = 0,
    D3D12DDI_VIDEO_DECODE_SUPPORT_FLAG_0020_SUPPORTED               = 0x1,

} D3D12DDI_VIDEO_DECODE_SUPPORT_FLAGS_0020;
```

```cpp
typedef enum D3D12DDI_VIDEO_DECODE_CONFIGURATION_FLAGS_0020
{
    D3D12DDI_VIDEO_DECODE_CONFIGURATION_FLAG_0020_NONE                                     = 0x0,
    D3D12DDI_VIDEO_DECODE_CONFIGURATION_FLAG_0020_HEIGHT_ALIGNMENT_MULTIPLE_32_REQUIRED    = 0x1,
    D3D12DDI_VIDEO_DECODE_CONFIGURATION_FLAG_0020_POST_PROCESSING_SUPPORTED                = 0x2,
    D3D12DDI_VIDEO_DECODE_CONFIGURATION_FLAG_0020_REFERENCE_ONLY_ALLOCATIONS_REQUIRED      = 0x4,
    D3D12DDI_VIDEO_DECODE_CONFIGURATION_FLAG_0032_ALLOW_RESOLUTION_CHANGE_ON_NON_KEY_FRAME = 0x8,

} D3D12DDI_VIDEO_DECODE_CONFIGURATION_FLAGS_0020;
```

```cpp
typedef enum D3D12DDI_VIDEO_DECODE_TIER_0020
{
    D3D12DDI_VIDEO_DECODE_TIER_0020_NOT_SUPPORTED = 0,
    D3D12DDI_VIDEO_DECODE_TIER_0020_1 = 1,
    D3D12DDI_VIDEO_DECODE_TIER_0020_2 = 2,
    D3D12DDI_VIDEO_DECODE_TIER_0020_3 = 3,
} D3D12DDI_VIDEO_DECODE_TIER_0020;
```

```cpp
typedef struct D3D12DDI_VIDEO_SAMPLE_DESCRIPTION_0020
{
    UINT Width;
    UINT Height;
    D3D12DDI_VIDEO_FORMAT_DESCRIPTION_0020 Format;
} D3D12DDI_VIDEO_SAMPLE_DESCRIPTION_0020;
```

```cpp
typedef struct D3D12DDI_VIDEO_FORMAT_DESCRIPTION_0020
{
    DXGI_FORMAT Format;
    DXGI_COLOR_SPACE_TYPE ColorSpace;
} D3D12DDI_VIDEO_FORMAT_DESCRIPTION_0020;
```

```cpp
typedef enum D3D12DDI_VIDEO_DECODE_CONVERSION_SUPPORT_FLAGS_0020
{
    D3D12DDI_VIDEO_DECODE_CONVERSION_SUPPORT_FLAG_0020_NONE = 0,
    D3D12DDI_VIDEO_DECODE_CONVERSION_SUPPORT_FLAG_0020_SUPPORTED = 0x1,

} D3D12DDI_VIDEO_DECODE_CONVERSION_SUPPORT_FLAGS_0020;
```

```cpp
typedef struct D3D12DDI_VIDEO_SCALE_SUPPORT_0032
{
    D3D12DDI_VIDEO_SIZE_RANGE_0032 OutputSizeRange;
    D3D12DDI_VIDEO_SCALE_SUPPORT_FLAGS_0022 Flags;
} D3D12DDI_VIDEO_SCALE_SUPPORT_0032;
```

```cpp
typedef enum D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAGS_0041
{
    D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAG_0041_NONE = 0x0,

    D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAG_0041_Y = (1 << D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_0041_Y),
    D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAG_0041_U = (1 << D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_0041_U),
    D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAG_0041_V = (1 << D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_0041_V),

    D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAG_0041_R = (1 << D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_0041_R),
    D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAG_0041_G = (1 << D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_0041_G),
    D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAG_0041_B = (1 << D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_0041_B),

    D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAG_0041_A = (1 << D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_0041_A),

} D3D12DDI_VIDEO_DECODE_HISTOGRAM_COMPONENT_FLAGS_0041;
```

```cpp
typedef struct D3D12DDI_VIDEO_SIZE_RANGE_0032
{
    UINT MaxWidth;
    UINT MaxHeight;
    UINT MinWidth;
    UINT MinHeight;
} D3D12DDI_VIDEO_SIZE_RANGE_0032;
```

```cpp
typedef enum D3D12DDI_VIDEO_SCALE_SUPPORT_FLAGS_0022
{
    D3D12DDI_VIDEO_SCALE_SUPPORT_FLAG_0022_NONE = 0x0,
    D3D12DDI_VIDEO_SCALE_SUPPORT_FLAG_0022_POW2_ONLY = 0x1,
    D3D12DDI_VIDEO_SCALE_SUPPORT_FLAG_0022_EVEN_DIMENSIONS_ONLY = 0x2,
    D3D12DDI_VIDEO_SCALE_SUPPORT_FLAG_0110_DPB_ENCODER_RESOURCES = 0x4,

} D3D12DDI_VIDEO_SCALE_SUPPORT_FLAGS_0022;
```

<a id="ddi-table-members"></a>

### Current driver declarations and table members

```cpp
typedef struct D3D12DDIARG_CREATE_VIDEO_DECODER_HEAP_0072
{
    UINT NodeMask;
    D3D12DDI_VIDEO_DECODE_CONFIGURATION_0020    Configuration;
    UINT                                        DecodeWidth;
    UINT                                        DecodeHeight;
    DXGI_FORMAT                                 Format;
    DXGI_RATIONAL                               FrameRate;
    UINT                                        BitRate;
    UINT                                        MaxDecodePictureBufferCount;
    D3D12DDI_HPROTECTEDRESOURCESESSION_0030     hDrvProtectedResourceSession;
} D3D12DDIARG_CREATE_VIDEO_DECODER_HEAP_0072;
```

```cpp
typedef struct D3D12DDIARG_CREATE_VIDEO_DECODER_0072
{
    UINT NodeMask;
    D3D12DDI_VIDEO_DECODE_CONFIGURATION_0020    Configuration;
    D3D12DDI_HPROTECTEDRESOURCESESSION_0030     hDrvProtectedResourceSession;
} D3D12DDIARG_CREATE_VIDEO_DECODER_0072;
```

```cpp
typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALCPRIVATEVIDEODECODERHEAPSIZE_0072 )( D3D12DDI_HDEVICE hDrvDevice, _In_ CONST D3D12DDIARG_CREATE_VIDEO_DECODER_HEAP_0072* pArgs);
```

```cpp
typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALCPRIVATEVIDEODECODERSIZE_0072 )( D3D12DDI_HDEVICE hDrvDevice, _In_ CONST D3D12DDIARG_CREATE_VIDEO_DECODER_0072* pArgs);
```

```cpp
typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATEVIDEODECODERHEAP_0072 )( D3D12DDI_HDEVICE hDrvDevice, _In_ CONST D3D12DDIARG_CREATE_VIDEO_DECODER_HEAP_0072*, D3D12DDI_HVIDEODECODERHEAP_0032 hDrvVideoDecoderHeap );
```

```cpp
typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATEVIDEODECODER_0072 )( D3D12DDI_HDEVICE hDrvDevice, _In_ CONST D3D12DDIARG_CREATE_VIDEO_DECODER_0072* pArgs, D3D12DDI_HVIDEODECODER_0020 hDrvVideoDecoder );
```

<!-- d3d12-review-alert:begin:video-decode:N-ddi-table-members:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Current table | Member | DDI typedef |
> |---|---|---|
> | `D3D12DDI_DEVICE_FUNCS_VIDEO_0110` | `pfnGetCaps` | `PFND3D12DDI_VIDEO_GETCAPS` |
> | `D3D12DDI_DEVICE_FUNCS_VIDEO_0110` | `pfnCalcPrivateVideoDecoderSize` | `PFND3D12DDI_CALCPRIVATEVIDEODECODERSIZE_0072` |
> | `D3D12DDI_DEVICE_FUNCS_VIDEO_0110` | `pfnCreateVideoDecoder` | `PFND3D12DDI_CREATEVIDEODECODER_0072` |
> | `D3D12DDI_DEVICE_FUNCS_VIDEO_0110` | `pfnDestroyVideoDecoder` | `PFND3D12DDI_DESTROYVIDEODECODER_0021` |
> | `D3D12DDI_DEVICE_FUNCS_VIDEO_0110` | `pfnCalcPrivateVideoDecoderHeapSize` | `PFND3D12DDI_CALCPRIVATEVIDEODECODERHEAPSIZE_0072` |
> | `D3D12DDI_DEVICE_FUNCS_VIDEO_0110` | `pfnCreateVideoDecoderHeap` | `PFND3D12DDI_CREATEVIDEODECODERHEAP_0072` |
> | `D3D12DDI_DEVICE_FUNCS_VIDEO_0110` | `pfnDestroyVideoDecoderHeap` | `PFND3D12DDI_DESTROYVIDEODECODERHEAP_0032` |
> | `D3D12DDI_COMMAND_LIST_FUNCS_VIDEO_DECODE_0094` | `pfnDecodeFrame` | `PFND3D12DDI_VIDEO_DECODE_FRAME_0041_1` |

<!-- d3d12-review-alert:end:video-decode:N-ddi-table-members:0 -->

<a id="protected-video-api-contracts"></a>

## Protected session video API contracts

<a id="api-id3d12videodecoder1-getprotectedresourcesession"></a>

### ID3D12VideoDecoder1::GetProtectedResourceSession

#### Declaration

```cpp
HRESULT GetProtectedResourceSession(
    REFIID riid,
    void** ppProtectedSession);
```

#### Behavior

Gets the [ID3D12ProtectedResourceSession](resources.md#protected-resource-sessions) that was passed into [ID3D12VideoDevice2::CreateVideoDecoder1](#api-id3d12videodevice2-createvideodecoder1) when the [ID3D12VideoDecoder1](#protected-video-api-contracts) was created.

<!-- d3d12-review-alert:begin:video-decode:AB-id3d12videodecoder1-getprotectedresourcesession-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Retrieves the session associated with this object's creation, not the current
> command list session. Association does not change when a command list selects
> a different protection context.

<!-- d3d12-review-alert:end:video-decode:AB-id3d12videodecoder1-getprotectedresourcesession-contract:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:video-decode:AB-id3d12videodecoder1-getprotectedresourcesession-contract:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `riid` selects an interface on the associated protected resource session.
> `ppProtectedSession` receives that interface with a caller-owned COM reference.

<!-- d3d12-review-alert:end:video-decode:AB-id3d12videodecoder1-getprotectedresourcesession-contract:2 -->

#### Return values

<!-- d3d12-review-alert:begin:video-decode:AB-id3d12videodecoder1-getprotectedresourcesession-contract:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns the interface query's HRESULT. With no associated session it returns
> `DXGI_ERROR_NOT_FOUND` and a null output. An unsupported requested interface
> returns `E_NOINTERFACE`. Retrieval does not create or signal a session.

<!-- d3d12-review-alert:end:video-decode:AB-id3d12videodecoder1-getprotectedresourcesession-contract:4 -->

<a id="api-id3d12videodecoderheap1-getprotectedresourcesession"></a>

### ID3D12VideoDecoderHeap1::GetProtectedResourceSession

#### Declaration

```cpp
HRESULT GetProtectedResourceSession(
    REFIID riid,
    void** ppProtectedSession);
```

#### Behavior

Gets the [ID3D12ProtectedResourceSession](resources.md#protected-resource-sessions) that was passed into [ID3D12VideoDevice2::CreateVideoDecoderHeap1](#api-id3d12videodevice2-createvideodecoderheap1) when the [ID3D12VideoDecoderHeap1](#protected-video-api-contracts) was created.

<!-- d3d12-review-alert:begin:video-decode:AB-id3d12videodecoderheap1-getprotectedresourcesession-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Retrieves the session associated with this object's creation, not the current
> command list session. Association does not change when a command list selects
> a different protection context.

<!-- d3d12-review-alert:end:video-decode:AB-id3d12videodecoderheap1-getprotectedresourcesession-contract:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:video-decode:AB-id3d12videodecoderheap1-getprotectedresourcesession-contract:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `riid` selects an interface on the associated protected resource session.
> `ppProtectedSession` receives that interface with a caller-owned COM reference.

<!-- d3d12-review-alert:end:video-decode:AB-id3d12videodecoderheap1-getprotectedresourcesession-contract:2 -->

#### Return values

<!-- d3d12-review-alert:begin:video-decode:AB-id3d12videodecoderheap1-getprotectedresourcesession-contract:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns the interface query's HRESULT. With no associated session it returns
> `DXGI_ERROR_NOT_FOUND` and a null output. An unsupported requested interface
> returns `E_NOINTERFACE`. Retrieval does not create or signal a session.

<!-- d3d12-review-alert:end:video-decode:AB-id3d12videodecoderheap1-getprotectedresourcesession-contract:4 -->

<a id="api-id3d12videodevice2-createvideodecoder1"></a>

### ID3D12VideoDevice2::CreateVideoDecoder1

#### Declaration

```cpp
HRESULT CreateVideoDecoder1(
    const D3D12_VIDEO_DECODER_DESC* pDesc,
    ID3D12ProtectedResourceSession *pProtectedResourceSession,
    REFIID riid,
    void** ppVideoDecoder);
```

#### Behavior

Creates a video decoder instance that contains the resolution-independent driver resources and state, with support for protected resources.

<!-- d3d12-review-alert:begin:video-decode:AB-id3d12videodevice2-createvideodecoder1-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Retains the corresponding [decoder/heap creation contract](#create-video-decoder)
> and adds the explicit protected session association. Null selects an
> unprotected object; non-null requires the supported protected-video tuple
> and compatible device/node/type. Decoder and decoder heap lifetimes/roles
> remain distinct; no output/reference picture allocation is implied.

<!-- d3d12-review-alert:end:video-decode:AB-id3d12videodevice2-createvideodecoder1-contract:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:video-decode:AB-id3d12videodevice2-createvideodecoder1-contract:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pDesc` supplies the existing creation description. pProtectedResourceSession supplies the optional session; riid selects the interface and `ppVideoDecoder` receives its COM reference.

<!-- d3d12-review-alert:end:video-decode:AB-id3d12videodevice2-createvideodecoder1-contract:2 -->

#### Return values

<!-- d3d12-review-alert:begin:video-decode:AB-id3d12videodevice2-createvideodecoder1-contract:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns the creation/interface HRESULT. Existing video creation result, optional capability and hardware qualifications remain. Success does not report frame execution.

<!-- d3d12-review-alert:end:video-decode:AB-id3d12videodevice2-createvideodecoder1-contract:4 -->

<a id="api-id3d12videodevice2-createvideodecoderheap1"></a>

### ID3D12VideoDevice2::CreateVideoDecoderHeap1

#### Declaration

```cpp
HRESULT CreateVideoDecoderHeap1(
    const D3D12_VIDEO_DECODER_HEAP_DESC* pVideoDecoderHeapDesc,
    ID3D12ProtectedResourceSession *pProtectedResourceSession,
    REFIID riid,
    void** ppVideoDecoderHeap);
```

#### Behavior

Allocates a video decoder heap that contains the resolution-dependent driver resources and state, with support for protected resources.

<!-- d3d12-review-alert:begin:video-decode:AB-id3d12videodevice2-createvideodecoderheap1-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Retains the corresponding [decoder/heap creation contract](#create-video-decoder-heap)
> and adds the explicit protected session association. Null selects an
> unprotected object; non-null requires the supported protected-video tuple
> and compatible device/node/type. Decoder and decoder heap lifetimes/roles
> remain distinct; no output/reference picture allocation is implied.

<!-- d3d12-review-alert:end:video-decode:AB-id3d12videodevice2-createvideodecoderheap1-contract:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:video-decode:AB-id3d12videodevice2-createvideodecoderheap1-contract:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pVideoDecoderHeapDesc` supplies the existing creation description. pProtectedResourceSession supplies the optional session; riid selects the interface and `ppVideoDecoderHeap` receives its COM reference.

<!-- d3d12-review-alert:end:video-decode:AB-id3d12videodevice2-createvideodecoderheap1-contract:2 -->

#### Return values

<!-- d3d12-review-alert:begin:video-decode:AB-id3d12videodevice2-createvideodecoderheap1-contract:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns the creation/interface HRESULT. Existing video creation result, optional capability and hardware qualifications remain. Success does not report frame execution.

<!-- d3d12-review-alert:end:video-decode:AB-id3d12videodevice2-createvideodecoderheap1-contract:4 -->

<a id="api-id3d12videodecodecommandlist2-setprotectedresourcesession"></a>

### ID3D12VideoDecodeCommandList2::SetProtectedResourceSession

#### Declaration

```cpp
void SetProtectedResourceSession(
    ID3D12ProtectedResourceSession *pProtectedResourceSession);
```

#### Behavior

Specifies whether or not protected resources can be accessed by subsequent commands in the video decode command list. By default, no protected resources are enabled. After calling **SetProtectedResourceSession** with a valid session, protected resources of the same type can refer to that session. After calling **SetProtectedResourceSession** with **NULL**, no protected resources can be accessed.

<!-- d3d12-review-alert:begin:video-decode:AB-id3d12videodecodecommandlist2-setprotectedresourcesession-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Selects only the supported command list's protection context. Ordinary
> bindings are preserved (D272). This is not ClearState. Null disables protected
> access. [Session/device/node/type and operation support](video.md#protected-video-support),
> the [canonical selection and open-query rules](command-list-state.md#protection)
> and [protected operation predication](counters-queries-and-predication.md#predication-operation-matrix)
> remain required.

<!-- d3d12-review-alert:end:video-decode:AB-id3d12videodecodecommandlist2-setprotectedresourcesession-contract:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:video-decode:AB-id3d12videodecodecommandlist2-setprotectedresourcesession-contract:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pProtectedResourceSession` is the optional translated session association. It is not a video encoder/decoder object and its selection does not allocate one.

<!-- d3d12-review-alert:end:video-decode:AB-id3d12videodecodecommandlist2-setprotectedresourcesession-contract:2 -->

#### Return values

<!-- d3d12-review-alert:begin:video-decode:AB-id3d12videodecodecommandlist2-setprotectedresourcesession-contract:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns no value. Recording/list errors remain distinct from content validity and GPU completion.

<!-- d3d12-review-alert:end:video-decode:AB-id3d12videodecodecommandlist2-setprotectedresourcesession-contract:4 -->
