<a id="video"></a>

# Video

**Qualified draft.** This chapter introduces the Video device and workload
families. The [decode](video-decode.md#video-decode),
[processing](video-processing.md#video-processing),
[motion-estimation](video-motion-estimation.md#video-motion-estimation),
[extension-command](video-extension-commands.md#video-extension-commands) and
[encoding](video-encoding.md#video-encoding)
references provide the selected API, type and driver contracts.
Capabilities do not guarantee every operation on every device; the
qualifications identify requirements not established by this draft.

<a id="video-device-model"></a>

## Device and capability model

`ID3D12VideoDevice` is obtained through `QueryInterface` on the Direct3D 12
device. It derives directly from `IUnknown`, rather than the core-device
interface inheritance chain. Its
[`CheckFeatureSupport`](video-decode.md#video-check-feature-support) takes
`D3D12_FEATURE_VIDEO` and video-specific payloads. It is not
[`ID3D12Device::CheckFeatureSupport`](devices-and-capabilities.md#id3d12device-checkfeaturesupport).
Decoder and decoder-heap objects derive from `ID3D12Pageable`; their inherited
device/object methods retain their declaring owners.

Decode discovery separates the node's profile list, the formats supported for
a decode configuration, and support for an actual configuration, size, decode
format, frame rate and bit rate. Enumerating a profile does not establish
support for every such tuple. Conversion and histogram support have their own
queries. The [selected video query protocol](video-decode.md#decode-discovery)
defines count/result payloads, input/output fields and exact payload sizes.
The ordinary unencrypted configuration uses
`D3D12_BITSTREAM_ENCRYPTION_TYPE_NONE`.

The shared [command-family availability query](video-motion-estimation.md#d3d12-feature-data-video-feature-area-support) reports decode, process and encode availability separately. Operation-specific capability queries still determine support for each requested configuration; the [driver capability contract](video-motion-estimation.md#video-feature-area-support) defines the corresponding table-population obligations.

<a id="decode-model"></a>

## Decode objects and one frame

A Direct3D 12 video decoder contains resolution-independent resources and state for performing the decode operation.

A Direct3D 12 video decoder heap contains resolution-dependent resources and state for performing the decode operation.

The decoder's configuration selects a decode profile, bitstream encryption
type and coded-frame interlace type. The heap additionally describes the
native decode dimensions, format, rates and maximum decode-picture-buffer
count. It is not an application `ID3D12Heap` or the decoded-picture allocation.
The [heap-size query](video-decode.md#d3d12-feature-data-video-decoder-heap-size)
reports allocation sizes in memory pools L0 and L1; it is distinct from the
driver-private CPU-object sizing callbacks.

Each [`DecodeFrame`](video-decode.md#decode-frame) operation supplies the current
decoder heap, compressed-bitstream buffer range, codec-specific CPU frame
arguments, explicit reference-picture resources/subresources, and output
texture/subresource. The application manages the reference frames and sets
them for every decode. Conversion can produce an ordinary output separately
from the native picture retained for future references.
[`DecodeFrame1`](video-decode.md#decode-frame1) uses the same input type, with
explicit conversion dimensions and per-component histogram destinations in
its version-1 output type.

Changing resolution alone does not require recreating the
resolution-independent decoder. The heap describes the applicable resolution
and decode-picture-buffer capacity. **Resolution-change qualification:** this
contract does not promise
arbitrary heap reuse, mixed-resolution references or codec support for
non-key-frame changes merely because a decoder can be retained.

<a id="video-processing-model"></a>

## Video processing

A video processor fixes input and output stream descriptions; each [processing call](video-processing.md#process-recording) supplies current/reference pictures and per-call operation arguments. The [processing capability and reflection reference](video-processing.md#process-discovery) defines the supported tuple, stream limits and immutable descriptions.

A video-process command list has type `D3D12_COMMAND_LIST_TYPE_VIDEO_PROCESS` and is submitted to a compatible video-process queue. Core [creation](execution.md#creation), [submission](execution.md#execute-command-lists), [threading](execution.md#threading) and [lifetime](execution.md#lifetime) contracts remain common. The [processing reference](video-processing.md#process-model) defines its input/output states and object/resource use; decoder-specific recording serialization below is not a generic processor rule.

<a id="video-motion-model"></a>

## Motion estimation and vector resolution

A [motion estimator](video-motion-estimation.md#motion-model) compares current and reference pictures; an opaque vector heap holds its output, and a resolve writes the published vector representation into an application texture. Motion estimation and resolution use VIDEO_ENCODE lists, allocators and queues. The [motion reference](video-motion-estimation.md#motion-recording) also owns the base encode-list ClearState, Close and Reset contracts; decoder-specific serialized recording is not inherited.

<a id="video-extension-model"></a>

## Extension commands

An [extension command](video-extension-commands.md#extension-discovery) is identified by a command GUID and command-defined parameter structures. Its reflected stages distinguish creation, GPU initialization/execution, capability queries and CPU device execution. [GPU recording](video-extension-commands.md#extension-recording) uses the reported compatible video family; [device execution](video-extension-commands.md#videodevice2-executeextensioncommand) completes before return under its published contract. The extension's own contract defines its algorithm and additional sequencing requirements.

<a id="video-encoding-model"></a>

## Encoding

The [encoding reference](video-encoding.md) defines encoder/heap objects, combined capability tuples, H.264/HEVC/AV1 picture and DPB controls, frame recording, opaque-output metadata resolution, optional statistics, subregion notifications, GPU input-map resolution and full/lower-resolution frame analysis. Its codec/control, type and published driver references are subordinate to that route.

<a id="video-recording-lifetime"></a>

## Recording, ordering and lifetime

A video decode command list has type `D3D12_COMMAND_LIST_TYPE_VIDEO_DECODE`.
The core device creates the command allocator, command list and queue; the
video interface creates the decoder and decoder heap. The selected lifecycle
methods are [ClearState, Close and Reset](video-decode.md#decode-list-lifecycle).
The list has no graphics pipeline-state argument on Reset.

Core [list creation](execution.md#creation),
[submission](execution.md#execute-command-lists), [command storage](execution.md#command-storage),
and [CPU threading](execution.md#threading) remain common contracts.
A video decode list is submitted to a compatible video decode queue.
Recording a decode and closing the list do not submit or complete decoding.
Successful Close is a recording result, not a decoded-picture success status.
The [video decode statistics](counters-queries-and-predication.md#video-decode-statistics)
contract defines the GPU decode status and rate feedback, including its
EndQuery/ResolveQueryData protocol; the statistics query does not use BeginQuery.

The ordinary video state contribution is precise: creation/Reset initialize
predication disabled; ClearState disables predication without resetting the
allocator or starting a new recording. DecodeFrame and DecodeFrame1 are
predicated work. The canonical
[video SetPredication entry](counters-queries-and-predication.md#videodecode-setpredication)
and [operation policies](counters-queries-and-predication.md#predication-operation-matrix)
define the predicate; no graphics root-binding reset model is implied.

The decoder may be used to record commands with multiple command lists, but commands cannot be recorded simultaneously. The application is responsible for synchronizing access to the decoder while recording commands.

Commands recorded against the decoder must also be executed in the order they were recorded. [decode-frame DDI](video-decode.md#decode-driver) operations may modify the contents of the decoder’s internal resources when they are executed on the GPU and subsequent decode-frame operations may depend upon those modifications.

On a single queue, the application is responsible for calling execute command lists in the order that decode-frame commands were recorded with the decoder object. When the application does so, the driver is then responsible for synchronizing decode-frame operations access to decoder resources.

When the application uses multiple queues with a single decoder object, the application is responsible for synchronizing and ordering the commands using fences.

CPU argument structures and arrays are distinct from the GPU resources and
objects they name. `FrameArguments[i].pData` addresses codec argument bytes;
`CompressedBitstream.pBuffer` names a D3D12 buffer, not those CPU bytes.
Both descriptions and CPU argument data are consumed as recording inputs.
**CPU-storage qualification:** the selected public decode pages do not
explicitly establish the precise release point for every nested CPU pointer;
this draft does not create a separate post-return CPU-storage retention rule
or claim that keeping a CPU descriptor alive retains its resources.

The application must keep the decoder, current and referenced decoder heaps,
bitstream, reference pictures, native conversion picture, output picture and
enabled histogram buffers valid for every recorded/submitted use. Reuse of
GPU storage follows [completion and lifetime](execution.md#completion-lifetime),
[resource lifetime and CPU/GPU access](execution.md#lifetime), and
[residency](resources.md#residency). Reusing CPU descriptions is not permission
to overwrite compressed data while the GPU reads it. Resetting the command
list is not a proof that its old allocator storage or resources can be reused.
Cross-queue producer/decode/consumer dependencies use
[queue waits and completion fences](execution.md#queue-waits); a resource
transition alone does not establish another queue's completion.

<a id="video-resource-contract"></a>

## Resources, states and formats

Video object backing allocations follow [application-controlled residency](resources.md#residency) and [object/resource lifetime](execution.md#lifetime). Workload-specific resource roles and capability constraints are defined by [decode](video-decode.md#decode-capabilities), [processing](video-processing.md#process-model), [motion estimation](video-motion-estimation.md#motion-model), [extension parameters](video-extension-commands.md#extension-resources) and [encoding](video-encoding.md#encoding-recording). The decode-specific state, tier and plane rules below do not redefine the other workloads' contracts.

The compressed bitstream and reference pictures actually read by the codec are
decode reads; the output,
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
identifies it.

The reported decode tier and configuration flags constrain texture-array
references, compressed-input alignment/packing, output height and separate
native-reference allocations; see [decode capabilities](video-decode.md#decode-capabilities).
Reference-only allocations remain restricted by
[`VIDEO_DECODE_REFERENCE_ONLY`](resources.md#d3d12_resource_flag_video_decode_reference_only)
and the [ordinary-copy prohibition](resource-operations.md#copy-self-and-alias).

Decode capability does not itself grant arbitrary shader/RTV/UAV views.
[Video-format views](formats.md#video-views), [logical planes](formats.md#planes),
and [format support](formats.md#support) retain format/channel, view and plane
ownership. Video color-space labels do not change the stored DXGI format or
grant a shader binding. Codec bitstream grammar and codec-specific DXVA payload
layouts are [external decode inputs](video-decode.md#codec-input-boundary),
not inferred from a profile GUID.

<a id="driver-shared-object-contracts"></a>

## Current video driver object and recording boundary

The selected video device table retains a separate `pfnGetCaps`, not the
adapter/core-device capability callback. Its typed payload protocol and
conditional table-population obligations are defined by
[decode discovery](video-decode.md#ddi-capability-payloads),
[processing discovery](video-processing.md#process-discovery),
[motion/command-family reporting](video-motion-estimation.md#motion-driver-capabilities),
[extension reflection](video-extension-commands.md#extension-ddi-behavior)
and [encoding](video-encoding.md#encoding-driver-capabilities).
A table member does not make an optional operation available.

Private size callbacks report driver CPU-object bytes. The runtime allocates
that storage; create callbacks construct the selected decoder/decoder heap,
processor, motion estimator/vector heap, extension command or encoder/encoder
heap there. These are not implicit application picture allocations or the
separate L0/L1 residency-size reports. Creation returns `HRESULT`; failed
construction is cleaned up by the driver. Successful objects receive the
matching destroy callback, which releases driver-owned state without freeing
the runtime-provided private region. Per-operation creation-result and
hardware qualifications remain with each owner.

Recording callbacks use ordinary driver command-list/object/resource handles
and translated CPU metadata, not interchangeable application structures.
Capture of CPU parameters is not capture of referenced GPU pictures,
bitstreams, LUTs, vector data or encoded metadata. Their
[resource and recording lifetimes](#video-recording-lifetime) remain required.
Decode/process/motion/encode void results do not report GPU completion.
The [extension initialization/execution HRESULT protocol](video-extension-commands.md#extension-ddi-behavior)
is a separate recording-error channel; CPU device execution retains its
[synchronous output contract](video-extension-commands.md#extension-ddi-cpu-callback).
