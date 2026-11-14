<a id="video"></a>

# Video

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

<ins><!-- d3d12-review-inline:begin:video-foundation:N-status:0:authored:migration-15e1c6e76d5662c0-0 -->**Qualified draft.** This chapter introduces the Video device and workload
families. The [decode](video-decode.md#video-decode),
[processing](video-processing.md#video-processing),
[motion estimation](video-motion-estimation.md#video-motion-estimation),
[extension command](video-extension-commands.md#video-extension-commands) and
[encoding](video-encoding.md#video-encoding)
references provide the selected API, type and driver contracts.
The qualifications identify requirements not established by this draft.<!-- d3d12-review-inline:end:video-foundation:N-status:0:authored:migration-15e1c6e76d5662c0-0 --></ins>

<a id="video-device-model"></a>

## Device and capability model

<ins><!-- d3d12-review-inline:begin:video-foundation:N-discovery:0:authored:migration-9c5305079ce5e2e7-0 -->`ID3D12VideoDevice` is obtained through `QueryInterface` on the Direct3D 12
device and derives directly from `IUnknown`. Its
[`CheckFeatureSupport`](video-decode.md#video-check-feature-support) takes
`D3D12_FEATURE_VIDEO` and video-specific payloads. It is not
[`ID3D12Device::CheckFeatureSupport`](devices-and-capabilities.md#id3d12device-checkfeaturesupport).
Decoder and decoder heap objects derive from `ID3D12Pageable`. Their inherited
device/object methods retain their declaring owners.<!-- d3d12-review-inline:end:video-foundation:N-discovery:0:authored:migration-9c5305079ce5e2e7-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-foundation:N-discovery:1:authored:migration-467f66b65c68d8fa-0 -->Decode discovery separates the node's profile list, the formats supported for
a decode configuration, and support for an actual configuration, size, decode
format, frame rate and bit rate. Enumerating a profile does not establish
support for every such tuple. Conversion and histogram support have their own
queries. The [selected video query protocol](video-decode.md#decode-discovery)
defines count/result payloads, input/output fields and exact payload sizes.
The ordinary unencrypted configuration uses
`D3D12_BITSTREAM_ENCRYPTION_TYPE_NONE`.<!-- d3d12-review-inline:end:video-foundation:N-discovery:1:authored:migration-467f66b65c68d8fa-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-foundation:D160-family-availability:0:authored:migration-29ce7529301be73c-0 -->The shared [command family availability query](#video-feature-area-support-api) reports decode, process and encode availability separately. Operation-specific capability queries still determine support for each requested configuration. The [driver capability contract](#video-feature-area-support-driver) defines the corresponding table population obligations.<!-- d3d12-review-inline:end:video-foundation:D160-family-availability:0:authored:migration-29ce7529301be73c-0 --></ins>

<a id="video-feature-area-support-api"></a>

### D3D12_FEATURE_DATA_VIDEO_FEATURE_AREA_SUPPORT

<ins><!-- d3d12-review-inline:begin:video-foundation:weekend-family-query-protocol:0 -->`D3D12_FEATURE_VIDEO_FEATURE_AREA_SUPPORT` (19) uses this fixed payload through the [video CheckFeatureSupport protocol](video-decode.md#video-check-feature-support).<!-- d3d12-review-inline:end:video-foundation:weekend-family-query-protocol:0 --></ins>

```cpp
typedef struct D3D12_FEATURE_DATA_VIDEO_FEATURE_AREA_SUPPORT
{
    UINT NodeIndex;                                                     // input
    BOOL VideoDecodeSupport;                                            // output
    BOOL VideoProcessSupport;                                           // output
    BOOL VideoEncodeSupport;                                            // output
} D3D12_FEATURE_DATA_VIDEO_FEATURE_AREA_SUPPORT;
```

<ins><!-- d3d12-review-inline:begin:video-motion:N-area-members:0:authored:migration-af445b1f2246359c-0 -->`NodeIndex` selects the physical adapter. The three BOOL outputs identify
availability of the decode, process and encode command families separately.<!-- d3d12-review-inline:end:video-motion:N-area-members:0:authored:migration-af445b1f2246359c-0 --></ins>

<a id="video-feature-area-support-driver"></a>

### D3D12DDI_VIDEO_FEATURE_AREA_SUPPORT_DATA_0053

By reporting any video feature version, driver must support the `pfnGetCaps` member of `D3D12DDI_DEVICE_FUNCS_VIDEO`.

<ins><!-- d3d12-review-inline:begin:video-foundation:weekend-family-ddi-protocol:0 -->`D3D12DDICAPS_TYPE_VIDEO_0053_FEATURE_AREA_SUPPORT` (19) uses this payload with null `pInfo`, `pData` addressing the payload and `DataSize` equal to its `sizeof`, under the [video driver capability protocol](video-decode.md#ddi-capability-payloads).<!-- d3d12-review-inline:end:video-foundation:weekend-family-ddi-protocol:0 --></ins>

```cpp
typedef struct D3D12DDI_VIDEO_FEATURE_AREA_SUPPORT_DATA_0053
{
    UINT NodeIndex;                                                     // input
    BOOL VideoDecodeSupport;                                            // output
    BOOL VideoProcessSupport;                                           // output
    BOOL VideoEncodeSupport;                                            // output
} D3D12DDI_VIDEO_FEATURE_AREA_SUPPORT_DATA_0053;
```

<ins><!-- d3d12-review-inline:begin:video-motion:R-98:0:modified:source-92a2758caf135a8d-0-0 -->This payload describes the<!-- d3d12-review-inline:end:video-motion:R-98:0:modified:source-92a2758caf135a8d-0-0 --></ins> command types supported by<ins><!-- d3d12-review-inline:begin:video-motion:R-98:0:modified:source-92a2758caf135a8d-0-1 --> the<!-- d3d12-review-inline:end:video-motion:R-98:0:modified:source-92a2758caf135a8d-0-1 --></ins> driver. Driver must report support for at least one video command type if the video feature version is supported.

<ins><!-- d3d12-review-inline:begin:video-motion:R-102:0:modified:migration-ff23305bc6cc3b26-0 -->`NodeIndex`<!-- d3d12-review-inline:end:video-motion:R-102:0:modified:migration-ff23305bc6cc3b26-0 --></ins>

In multi-adapter operation, this indicates which physical adapter of the device this operation applies to.

<ins><!-- d3d12-review-inline:begin:video-motion:N-feature-area-decode-owner:0:authored:migration-dac01aa2fdffeceb-0 -->The [decode driver associations](video-decode.md#ddi-table-members)
define the decoding operations named by the following device slots.<!-- d3d12-review-inline:end:video-motion:N-feature-area-decode-owner:0:authored:migration-dac01aa2fdffeceb-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-motion:R-107:0:modified:migration-f2bf24d2a34f6416-0 -->If `VideoDecodeSupport` is TRUE:<!-- d3d12-review-inline:end:video-motion:R-107:0:modified:migration-f2bf24d2a34f6416-0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:video-motion:N-feature-area-process-owner:0:authored:migration-eac3cda9671dc18b-0 -->The [processing driver associations](video-processing.md#process-ddi-associations)
define the processing operations named by the following device slots.<!-- d3d12-review-inline:end:video-motion:N-feature-area-process-owner:0:authored:migration-eac3cda9671dc18b-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-motion:R-128:0:modified:migration-ffdba8c006797177-0 -->If `VideoProcessSupport` is TRUE:<!-- d3d12-review-inline:end:video-motion:R-128:0:modified:migration-ffdba8c006797177-0 --></ins>

- Predication, timestamp queries, and history buffers must be supported with the video process queue type.

- The table corresponding to the following table types for the reported video feature must be fully populated:
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-132:0 -->`D3D12DDI_TABLE_TYPE_0022_COMMAND_LIST_VIDEO_PROCESS`<!-- d3d12-review-inline:end:video-motion:R-132:0 --></ins>
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-132:0 -->`D3D12DDI_TABLE_TYPE_0022_COMMAND_QUEUE_VIDEO_PROCESS`<!-- d3d12-review-inline:end:video-motion:R-132:0 --></ins>

- Also, the following members of the table type corresponding to `D3D12DDI_TABLE_TYPE_0020_DEVICE_VIDEO` and the reported video feature version must be populated:
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-136:0 -->`pfnCalcPrivateVideoProcessorSize`<!-- d3d12-review-inline:end:video-motion:R-136:0 --></ins>
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-136:0 -->`pfnCreateVideoProcessor`<!-- d3d12-review-inline:end:video-motion:R-136:0 --></ins>
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-136:0 -->`pfnDestroyVideoProcessor`<!-- d3d12-review-inline:end:video-motion:R-136:0 --></ins>

When the flag is not set, all of these functions may be set to nullptr.

<ins><!-- d3d12-review-inline:begin:video-motion:R-146:0:modified:migration-39c99a9647805b1b-0 -->If `VideoEncodeSupport` is TRUE:<!-- d3d12-review-inline:end:video-motion:R-146:0:modified:migration-39c99a9647805b1b-0 --></ins>

- Predication, timestamp queries, and history buffers must be supported with the video encode queue type.

- The table corresponding to the following table types for the reported video feature must be fully populated:
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-150:0 -->`D3D12DDI_TABLE_TYPE_0053_COMMAND_LIST_VIDEO_ENCODE`<!-- d3d12-review-inline:end:video-motion:R-150:0 --></ins>
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-150:0 -->`D3D12DDI_TABLE_TYPE_0053_COMMAND_QUEUE_VIDEO_ENCODE`<!-- d3d12-review-inline:end:video-motion:R-150:0 --></ins>

- Also, the following members of the table type corresponding to `D3D12DDI_TABLE_TYPE_0020_DEVICE_VIDEO` and the reported video feature version must be populated:
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-154:0 -->`pfnCalcPrivateVideoMotionEstimatorSize`<!-- d3d12-review-inline:end:video-motion:R-154:0 --></ins>
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-154:0 -->`pfnCreateVideoMotionEstimator`<!-- d3d12-review-inline:end:video-motion:R-154:0 --></ins>
  - <ins><!-- d3d12-review-inline:begin:video-motion:R-154:0 -->`pfnDestroyVideoMotionEstimator`<!-- d3d12-review-inline:end:video-motion:R-154:0 --></ins>

When the flag is not set, all of these functions may be set to nullptr.

<ins><!-- d3d12-review-inline:begin:video-foundation:weekend-codec-table-contribution:0 -->Codec encoding's [current table associations](video-encoding.md#encoding-ddi-table-associations) define its additional encoder and encoder-heap device functions and versioned recording functions.<!-- d3d12-review-inline:end:video-foundation:weekend-codec-table-contribution:0 --></ins>

<a id="decode-model"></a>

## Decode objects and one frame

<ins><!-- d3d12-review-inline:begin:video-foundation:P-decoder-role:0:modified:migration-99e971bdcb7b3b08-0 -->A Direct3D 12 video decoder<!-- d3d12-review-inline:end:video-foundation:P-decoder-role:0:modified:migration-99e971bdcb7b3b08-0 --></ins> <ins><!-- d3d12-review-inline:begin:video-foundation:P-decoder-role:0:modified:migration-1beb11135b15fe9d-1 -->contains<!-- d3d12-review-inline:end:video-foundation:P-decoder-role:0:modified:migration-1beb11135b15fe9d-1 --></ins> resolution-independent resources and state for performing the decode operation.

<ins><!-- d3d12-review-inline:begin:video-foundation:P-heap-role:0:modified:migration-6a23a29f23d415e6-0 -->A Direct3D 12 video decoder heap<!-- d3d12-review-inline:end:video-foundation:P-heap-role:0:modified:migration-6a23a29f23d415e6-0 --></ins> <ins><!-- d3d12-review-inline:begin:video-foundation:P-heap-role:0:modified:migration-dddea14732078a71-1 -->contains<!-- d3d12-review-inline:end:video-foundation:P-heap-role:0:modified:migration-dddea14732078a71-1 --></ins> resolution-dependent resources and state for performing the decode operation.

<ins><!-- d3d12-review-inline:begin:video-foundation:N-frame-route:0:authored:migration-eab8ae4983a40411-0 -->The decoder's configuration selects a decode profile, bitstream encryption
type and coded-frame interlace type. The heap additionally describes the
native decode dimensions, format, rates and maximum decode picture buffer
count. It is not an application `ID3D12Heap` or the decoded picture allocation.
The [heap size query](video-decode.md#d3d12-feature-data-video-decoder-heap-size)
reports allocation sizes in memory pools L0 and L1. It is distinct from the
driver-private CPU object sizing DDIs.<!-- d3d12-review-inline:end:video-foundation:N-frame-route:0:authored:migration-eab8ae4983a40411-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-foundation:N-frame-route:1:authored:migration-a111aa1e3400d4d9-0 -->Each [`DecodeFrame`](video-decode.md#decode-frame) operation supplies the current
decoder heap, compressed bitstream buffer range, codec-specific CPU frame
arguments, explicit reference picture resources/subresources, and output
texture/subresource. The application manages the reference frames and sets
them for every decode. Conversion can produce an ordinary output separately
from the native picture retained for future references.
[`DecodeFrame1`](video-decode.md#decode-frame1) uses the same input type, with
explicit conversion dimensions and per-component histogram destinations in
its version-1 output type.<!-- d3d12-review-inline:end:video-foundation:N-frame-route:1:authored:migration-a111aa1e3400d4d9-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-foundation:N-frame-route:2:authored:migration-4ca5bd799e7d0a1a-0 -->Changing resolution alone does not require recreating the
resolution-independent decoder. The heap describes the applicable resolution
and decode picture buffer capacity. **Resolution change qualification:** this
contract does not promise
arbitrary heap reuse, mixed-resolution references or codec support for
non-key-frame changes merely because a decoder can be retained.<!-- d3d12-review-inline:end:video-foundation:N-frame-route:2:authored:migration-4ca5bd799e7d0a1a-0 --></ins>

<a id="video-processing-model"></a>

## Video processing

<ins><!-- d3d12-review-inline:begin:video-foundation:D158-processing-route:0:authored:migration-cd72d6a269910155-0 -->A video processor fixes input and output stream descriptions. Each [processing call](video-processing.md#process-recording) supplies current/reference pictures and per-call operation arguments. The [processing capability and reflection reference](video-processing.md#process-discovery) defines the supported tuple, stream limits and immutable descriptions.<!-- d3d12-review-inline:end:video-foundation:D158-processing-route:0:authored:migration-cd72d6a269910155-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-foundation:D158-processing-route:1:authored:migration-08c69cec1fb1d6f4-0 -->A video process command list has type `D3D12_COMMAND_LIST_TYPE_VIDEO_PROCESS` and is submitted to a compatible video process queue. Core [creation](execution.md#creation), [submission](execution.md#execute-command-lists), [threading](execution.md#threading) and [lifetime](execution.md#lifetime) contracts remain common. The [processing reference](video-processing.md#process-model) defines its input/output states and object/resource use; decoder-specific recording serialization below is not a generic processor rule.<!-- d3d12-review-inline:end:video-foundation:D158-processing-route:1:authored:migration-08c69cec1fb1d6f4-0 --></ins>

<a id="video-motion-model"></a>

## Motion estimation and vector resolution

<ins><!-- d3d12-review-inline:begin:video-foundation:D160-motion-route:0:authored:migration-75e287dec13ad99d-0 -->A [motion estimator](video-motion-estimation.md#motion-model) compares current and reference pictures. An opaque vector heap holds its output, and a resolve writes the published vector representation into an application texture. Motion estimation and resolution use VIDEO_ENCODE lists, allocators and queues. The [motion reference](video-motion-estimation.md#motion-recording) also owns the base encode list ClearState, Close and Reset contracts; decoder-specific serialized recording is not inherited.<!-- d3d12-review-inline:end:video-foundation:D160-motion-route:0:authored:migration-75e287dec13ad99d-0 --></ins>

<a id="video-extension-model"></a>

## Extension commands

<ins><!-- d3d12-review-inline:begin:video-foundation:D161-extension-route:0:authored:migration-0ff860bb1a517834-0 -->An [extension command](video-extension-commands.md#extension-discovery) is identified by a command GUID and command-defined parameter structures. Its reflected stages distinguish creation, GPU initialization/execution, capability queries and CPU device execution. [GPU recording](video-extension-commands.md#extension-recording) uses the reported compatible video family; [device execution](video-extension-commands.md#videodevice2-executeextensioncommand) completes before return under its published contract. The extension's own contract defines its algorithm and additional sequencing requirements.<!-- d3d12-review-inline:end:video-foundation:D161-extension-route:0:authored:migration-0ff860bb1a517834-0 --></ins>

<a id="video-encoding-model"></a>

## Encoding

<ins><!-- d3d12-review-inline:begin:video-foundation:D162-encoding-route:0:authored:migration-348d0d9133aca387-0 -->The [encoding reference](video-encoding.md) defines encoder/heap objects, combined capability tuples, H.264/HEVC/AV1 picture and DPB controls, frame recording, opaque output metadata resolution, optional statistics, subregion notifications, GPU input map resolution and full/lower-resolution frame analysis. Its codec/control, type and published driver references are subordinate to that route.<!-- d3d12-review-inline:end:video-foundation:D162-encoding-route:0:authored:migration-348d0d9133aca387-0 --></ins>

<a id="video-recording-lifetime"></a>

## Recording, ordering and lifetime

<ins><!-- d3d12-review-inline:begin:video-foundation:N-recording:0:authored:migration-a5109b03ad5aa0d3-0 -->A video decode command list has type `D3D12_COMMAND_LIST_TYPE_VIDEO_DECODE`.
The core device creates the command allocator, command list and queue. The
video interface creates the decoder and decoder heap. The selected lifecycle
methods are [ClearState, Close and Reset](video-decode.md#decode-list-lifecycle).
The list has no graphics pipeline state argument on Reset.<!-- d3d12-review-inline:end:video-foundation:N-recording:0:authored:migration-a5109b03ad5aa0d3-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-foundation:N-recording:1:authored:migration-5ea01e0663627a5e-0 -->Core [list creation](execution.md#creation),
[submission](execution.md#execute-command-lists), [command storage](execution.md#command-storage),
and [CPU threading](execution.md#threading) remain common contracts.
A video decode list is submitted to a compatible video decode queue.
Successful Close is a recording result, not a decoded picture success status.
The [video decode statistics](counters-queries-and-predication.md#video-decode-statistics)
contract defines the GPU decode status and rate feedback, including its
EndQuery/ResolveQueryData protocol. The statistics query does not use BeginQuery.<!-- d3d12-review-inline:end:video-foundation:N-recording:1:authored:migration-5ea01e0663627a5e-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-foundation:N-recording:2:authored:migration-587eb4624483c22e-0 -->Creation/Reset initialize
predication disabled; ClearState disables predication without resetting the
allocator or starting a new recording. DecodeFrame and DecodeFrame1 are
predicated work. The canonical
[video SetPredication entry](counters-queries-and-predication.md#videodecode-setpredication)
and [operation policies](counters-queries-and-predication.md#predication-operation-matrix)
define the predicate.<!-- d3d12-review-inline:end:video-foundation:N-recording:2:authored:migration-587eb4624483c22e-0 --></ins>

The decoder may be used to record commands with multiple command lists, but commands cannot be recorded simultaneously. The application is responsible for synchronizing access to the decoder while recording commands.

<ins><!-- d3d12-review-inline:begin:video-foundation:P-ordering:1 -->Commands recorded against the decoder must also be executed in the order they were recorded. [decode frame DDI](video-decode.md#decode-driver) operations may modify the contents of the decoder’s internal resources when they are executed on the GPU and subsequent decode frame operations may depend upon those modifications.<!-- d3d12-review-inline:end:video-foundation:P-ordering:1 --></ins>

<ins><!-- d3d12-review-inline:begin:video-foundation:P-ordering:2 -->On a single queue, the application is responsible for calling execute command lists in the order that decode frame commands were recorded with the decoder object. When the application does so, the driver is then responsible for synchronizing decode frame operations access to decoder resources.<!-- d3d12-review-inline:end:video-foundation:P-ordering:2 --></ins>

When the application uses multiple queues with a single decoder object, the application is responsible for synchronizing and ordering the commands using fences.

<ins><!-- d3d12-review-inline:begin:video-foundation:N-lifetime:0:authored:migration-1b2c5298d6e0374b-0 -->CPU argument structures and arrays are distinct from the GPU resources and
objects they name. `FrameArguments[i].pData` addresses codec argument bytes;
`CompressedBitstream.pBuffer` names a D3D12 buffer, not those CPU bytes.
Both descriptions and CPU argument data are consumed as recording inputs.
**CPU storage qualification:** the selected public decode pages do not
explicitly establish the precise release point for every nested CPU pointer;
this draft does not create a separate post-return CPU storage retention rule
or claim that keeping a CPU descriptor alive retains its resources.<!-- d3d12-review-inline:end:video-foundation:N-lifetime:0:authored:migration-1b2c5298d6e0374b-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-foundation:N-lifetime:1:authored:migration-1c8262936eb58f7d-0 -->The application must keep the decoder, current and referenced decoder heaps,
bitstream, reference pictures, native conversion picture, output picture and
enabled histogram buffers valid for every recorded/submitted use. Reuse of
GPU storage follows [completion and lifetime](execution.md#completion-lifetime),
[resource lifetime and CPU/GPU access](execution.md#lifetime), and
[residency](resources.md#residency).
Cross-queue producer/decode/consumer dependencies use
[queue waits and completion fences](execution.md#queue-waits).<!-- d3d12-review-inline:end:video-foundation:N-lifetime:1:authored:migration-1c8262936eb58f7d-0 --></ins>

<a id="video-resource-contract"></a>

## Resources, states and formats

<ins><!-- d3d12-review-inline:begin:video-foundation:D162-common-video-resource-owners:0:authored:migration-ff05bfd010b53a3f-0 -->Video object backing allocations follow [application-controlled residency](resources.md#residency) and [object/resource lifetime](execution.md#lifetime). Workload-specific resource roles and capability constraints are defined by [decode](video-decode.md#decode-capabilities), [processing](video-processing.md#process-model), [motion estimation](video-motion-estimation.md#motion-model), [extension parameters](video-extension-commands.md#extension-resources) and [encoding](video-encoding.md#encoding-recording). The decode-specific state, tier and plane rules below do not redefine the other workloads' contracts.<!-- d3d12-review-inline:end:video-foundation:D162-common-video-resource-owners:0:authored:migration-ff05bfd010b53a3f-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-foundation:N-states:0:authored:migration-3c4bf3c08d5a15de-0 -->The compressed bitstream and reference pictures actually read by the codec are
decode reads. The output,
native conversion destination and enabled histogram buffers are decode writes.
Their legacy states are `D3D12_RESOURCE_STATE_VIDEO_DECODE_READ` and
`D3D12_RESOURCE_STATE_VIDEO_DECODE_WRITE`, respectively. The canonical
[legacy video states](synchronization.md#legacy-states) and
[enhanced barrier model](synchronization.md#enhanced-barriers) define transitions,
access/layout combinations and queue compatibility.
Video [`ResourceBarrier`](synchronization.md#decode-resource-barrier) and
[`Barrier`](synchronization.md#decode-enhanced-barrier) retain their full definitions there.
For planar pictures, decoding selects the first plane for the chosen array
slice and accesses the picture's planes; subresource numbering remains the
[resource subresource/plane contract](resources.md#subresources).
An entry in the codec's picture table is not by itself a simultaneous read:
the current output picture has the write role, even when that table also
identifies it.<!-- d3d12-review-inline:end:video-foundation:N-states:0:authored:migration-3c4bf3c08d5a15de-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-foundation:N-states:1:authored:migration-a4576329a063c838-0 -->The reported decode tier and configuration flags constrain texture array
references, compressed input alignment/packing, output height and separate
native reference allocations. See [decode capabilities](video-decode.md#decode-capabilities).
Reference-only allocations remain restricted by
[`VIDEO_DECODE_REFERENCE_ONLY`](resources.md#d3d12_resource_flag_video_decode_reference_only)
and the [ordinary-copy prohibition](resource-operations.md#copy-self-and-alias).<!-- d3d12-review-inline:end:video-foundation:N-states:1:authored:migration-a4576329a063c838-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-foundation:N-states:2:authored:migration-f43aab781580f988-0 -->Decode capability does not itself grant arbitrary shader/RTV/UAV views.
[Video format views](formats.md#video-views), [logical planes](formats.md#planes),
and [format support](formats.md#support) retain format/channel, view and plane
ownership. Video color space labels do not change the stored DXGI format or
grant a shader binding. Codec bitstream grammar and codec-specific DXVA payload
layouts are [external decode inputs](video-decode.md#codec-input-boundary),
not inferred from a profile GUID.<!-- d3d12-review-inline:end:video-foundation:N-states:2:authored:migration-f43aab781580f988-0 --></ins>

<a id="driver-shared-object-contracts"></a>

## Current video driver object and recording boundary

<ins><!-- d3d12-review-inline:begin:video-foundation:CS-video-shared:0:authored:migration-74a48cc3400822ac-0 -->Video uses its own `pfnGetCaps`. Its typed protocols are defined by [decode](video-decode.md#ddi-capability-payloads), [processing](video-processing.md#process-discovery), [motion estimation](video-motion-estimation.md#motion-driver-capabilities), [extension commands](video-extension-commands.md#extension-ddi-behavior) and [encoding](video-encoding.md#encoding-driver-capabilities).<!-- d3d12-review-inline:end:video-foundation:CS-video-shared:0:authored:migration-74a48cc3400822ac-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-foundation:CS-video-shared:1:authored:migration-d758997e8d59af04-0 -->The runtime allocates the reported private CPU object storage. The driver unwinds failed creation and destroys successfully created objects without freeing runtime-provided storage. Picture allocations and L0/L1 memory requirements are separate.<!-- d3d12-review-inline:end:video-foundation:CS-video-shared:1:authored:migration-d758997e8d59af04-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-foundation:CS-video-shared:2:authored:migration-15c54b1c9bab358b-0 -->Recording uses driver handles and translated CPU metadata. Extension command initialization/execution has a distinct [HRESULT error protocol](video-extension-commands.md#extension-ddi-behavior). Device CPU execution uses its [synchronous output contract](video-extension-commands.md#extension-ddi-cpu-callback).<!-- d3d12-review-inline:end:video-foundation:CS-video-shared:2:authored:migration-15c54b1c9bab358b-0 --></ins>

<a id="protected-video-support"></a>

## Protected video capability and access model

<ins><!-- d3d12-review-inline:begin:video-foundation:AB-protected-video-model:0:authored:migration-63ee39cd9ced016e-0 -->Protected support is per video operation. The following contracts apply to
decode, processing and motion estimation/vector resolution operations and
their associated creation/selection paths. Motion operations use the
VIDEO_ENCODE family. The queue type or a protected session setter does not
by itself establish protected support for every codec encoding operation.
API session interfaces and the corresponding driver handles remain distinct.<!-- d3d12-review-inline:end:video-foundation:AB-protected-video-model:0:authored:migration-63ee39cd9ced016e-0 --></ins>

```cpp
typedef
enum D3D12_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAGS
    {
        D3D12_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAG_NONE	= 0,
        D3D12_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAG_SUPPORTED	= 0x1
    } 	D3D12_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAGS;

typedef struct D3D12_FEATURE_DATA_VIDEO_DECODE_PROTECTED_RESOURCES
    {
    UINT NodeIndex;
    D3D12_VIDEO_DECODE_CONFIGURATION Configuration;
    D3D12_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAGS SupportFlags;
    } 	D3D12_FEATURE_DATA_VIDEO_DECODE_PROTECTED_RESOURCES;

typedef struct D3D12_FEATURE_DATA_VIDEO_PROCESS_PROTECTED_RESOURCES
    {
    UINT NodeIndex;
    D3D12_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAGS SupportFlags;
    } 	D3D12_FEATURE_DATA_VIDEO_PROCESS_PROTECTED_RESOURCES;

typedef struct D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_PROTECTED_RESOURCES
    {
    UINT NodeIndex;
    D3D12_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAGS SupportFlags;
    } 	D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_PROTECTED_RESOURCES;
```

```cpp
typedef enum D3D12DDI_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAGS_0072
{
    D3D12DDI_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAG_0072_NONE                    = 0,
    D3D12DDI_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAG_0072_SUPPORTED               = 0x1,

} D3D12DDI_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAGS_0072;

typedef struct D3D12DDI_VIDEO_DECODE_PROTECTED_RESOURCES_DATA_0072
{
    UINT NodeIndex;                                                         // input
    D3D12DDI_VIDEO_DECODE_CONFIGURATION_0020 Configuration;                 // input
    D3D12DDI_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAGS_0072 SupportFlags;      // output
} D3D12DDI_VIDEO_DECODE_PROTECTED_RESOURCES_DATA_0072;

typedef struct D3D12DDI_VIDEO_PROCESS_PROTECTED_RESOURCES_DATA_0072
{
    UINT NodeIndex;                                                                           // input
    D3D12DDI_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAGS_0072 SupportFlags;                        // output
} D3D12DDI_VIDEO_PROCESS_PROTECTED_RESOURCES_DATA_0072;

typedef struct D3D12DDI_VIDEO_MOTION_ESTIMATOR_PROTECTED_RESOURCES_DATA_0072
{
    UINT NodeIndex;                                                                           // input
    D3D12DDI_VIDEO_PROTECTED_RESOURCE_SUPPORT_FLAGS_0072 SupportFlags;                        // output
} D3D12DDI_VIDEO_MOTION_ESTIMATOR_PROTECTED_RESOURCES_DATA_0072;
```

Each video operation <ins><!-- d3d12-review-inline:begin:video-foundation:AB-primary-protected-video-requirements:0:modified:source-7e94914d7d055c4c-0-0 -->has a protected resource<!-- d3d12-review-inline:end:video-foundation:AB-primary-protected-video-requirements:0:modified:source-7e94914d7d055c4c-0-0 --></ins> capability check with a support flag so drivers can indicate if that operation supports protected resources .  Indicating support means that operation can read/write protected resources and supports Cross-API sharing if the resource type supports it. Operation support for protected resources is orthogonal to other operation capabilities with the exception of decode profile and interlace type for decode.  Once protected resource support is reported, it must be supported by all the existing non-protected resource capabilities of that operation.  For example, if Decode reports protected resource support and reports decode histogram support for a given format, the decoder must support decode histogram for both non-protected and protected resources.

<ins><!-- d3d12-review-inline:begin:video-foundation:AB-primary-protected-video-requirements:1:modified:vi04-driver-creation -->Driver creation DDIs take an optional<!-- d3d12-review-inline:end:video-foundation:AB-primary-protected-video-requirements:1:modified:vi04-driver-creation --></ins> D3D12DDI_HPROTECTEDRESOURCESESSION instance.  Drivers are given this parameter at object creation time to inform setup and allocations.  Further, the memory budget checks are revised to indicate whether or not the operation will use protected resources.  When the parameter is non-NULL, this indicates that the operation will write to protected resources.  To write to an unprotected resource, the operation object must be recreated.

Decoder and motion estimation references must be protected resources when the output is a protected resource.  Video processing may read from a combination of protected and unprotected resources when writing to a protected resource.

<ins><!-- d3d12-review-inline:begin:video-foundation:AB-primary-protected-video-requirements:3:modified:vi04-runtime-to-driver -->Before recording one or more operations that write to a protected resource, the runtime must call the driver through PFND3D12DDI_SETPROTECTEDRESOURCESESSION_0030 with a non-NULL protected resource session. The runtime must call this DDI with NULL before recording one or more operations that write to non-protected resources.<!-- d3d12-review-inline:end:video-foundation:AB-primary-protected-video-requirements:3:modified:vi04-runtime-to-driver --></ins>

<ins><!-- d3d12-review-inline:begin:video-foundation:AB-protected-video-discovery:0:authored:migration-cbb55bb10c5d33ad-0 -->Call `ID3D12VideoDevice::CheckFeatureSupport` with the selected Feature below,
pFeatureSupportData pointing to the matching payload above and
FeatureSupportDataSize equal to sizeof that payload. Initialize the listed
input fields. A successful query writes SupportFlags.<!-- d3d12-review-inline:end:video-foundation:AB-protected-video-discovery:0:authored:migration-cbb55bb10c5d33ad-0 --></ins>

<!-- d3d12-review-alert:begin:video-foundation:AB-protected-video-discovery:1:authored:migration-cafec5f511c58273-0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | API Feature | Value | Payload | Input fields |
> |---|---|---|---|
> | D3D12_FEATURE_VIDEO_DECODE_PROTECTED_RESOURCES | 28 | D3D12_FEATURE_DATA_VIDEO_DECODE_PROTECTED_RESOURCES | NodeIndex, Configuration |
> | D3D12_FEATURE_VIDEO_PROCESS_PROTECTED_RESOURCES | 29 | D3D12_FEATURE_DATA_VIDEO_PROCESS_PROTECTED_RESOURCES | NodeIndex |
> | D3D12_FEATURE_VIDEO_MOTION_ESTIMATOR_PROTECTED_RESOURCES | 30 | D3D12_FEATURE_DATA_VIDEO_MOTION_ESTIMATOR_PROTECTED_RESOURCES | NodeIndex |

<!-- d3d12-review-alert:end:video-foundation:AB-protected-video-discovery:1:authored:migration-cafec5f511c58273-0 -->

<ins><!-- d3d12-review-inline:begin:video-foundation:AB-protected-video-discovery:2:authored:migration-99cfc6d45e96672c-0 -->Decode Configuration selects the profile and interlace/encryption configuration;
processing and motion report support for the selected node. NodeIndex is an
index, not a node mask bit. These are the protected support routes for
[decode discovery](video-decode.md#decode-discovery),
[processing discovery](video-processing.md#process-discovery) and
[motion discovery](video-motion-estimation.md#motion-driver-capabilities).
The driver reports the corresponding support flag through
video GetCaps with its typed decode/process/motion payload. API and driver
configuration layouts are translated, not assumed byte-identical.<!-- d3d12-review-inline:end:video-foundation:AB-protected-video-discovery:2:authored:migration-99cfc6d45e96672c-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-foundation:AB-protected-video-discovery:3:authored:migration-b58997c474674913-0 -->The driver capability cases are
`D3D12DDICAPS_TYPE_VIDEO_0072_DECODE_PROTECTED_RESOURCES` (28),
`D3D12DDICAPS_TYPE_VIDEO_0072_PROCESS_PROTECTED_RESOURCES` (29) and
`D3D12DDICAPS_TYPE_VIDEO_0072_MOTION_ESTIMATOR_PROTECTED_RESOURCES` (30).
They use null pInfo, the corresponding payload in pData and that payload's
sizeof as DataSize. NONE reports unsupported and SUPPORTED reports support;
the negotiated video payload contract selects the layouts above.<!-- d3d12-review-inline:end:video-foundation:AB-protected-video-discovery:3:authored:migration-b58997c474674913-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-foundation:AB-protected-video-discovery:4:authored:migration-2f408c62857b6fb8-0 -->[Command family availability](video-motion-estimation.md#video-feature-area-support)
and [protected session resource support](resources.md#protected-resource-sessions)
are separate from the operation-specific protected capability queries above.<!-- d3d12-review-inline:end:video-foundation:AB-protected-video-discovery:4:authored:migration-2f408c62857b6fb8-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-foundation:AB-protected-video-discovery:5:authored:migration-22e295b924d8fa75-0 -->**History:** motion protection was not a mandatory inference from the
WDDM2.6 motion interface. The later WDDM2.7/video0072 contract makes it optional
through explicit reporting. Existing setter slots alone did not establish it.<!-- d3d12-review-inline:end:video-foundation:AB-protected-video-discovery:5:authored:migration-22e295b924d8fa75-0 --></ins>
