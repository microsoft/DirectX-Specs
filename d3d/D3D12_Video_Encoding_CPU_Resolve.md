# D3D12 Video Encoding CPU Resolve

# Introduction

This spec adds a CPU-based resolve operation for encoder output metadata, removing the dependency on the GPU timeline `ID3D12VideoEncodeCommandList::ResolveEncoderOutputMetadata1` operation.

In many cases, the DDI is extremely similar to the API. The structures and enumerations which are basically the same (differing solely in name convention) are not repeated in this specification.

# Motivation

For IHV platforms that use the compute engine to perform the resolve operation, significant latency can be added when waiting for GPU-based `ResolveEncoderOutputMetadata1` to complete. For example, in vGPU scenarios with a fixed ms quantum, latency can reach up to (N-1)*QuantumTime where there are N VMs per host doing round robin scheduling of the GPU among the VMs.

For certain codecs and encoding modes, metadata required to build the bitstream headers is only available after full frame completion via `ResolveEncoderOutputMetadata1`. This blocks low-latency streaming scenarios that want to avoid a dependency on GPU timeline resolving.

Additionally, the resolved stats outputs (SATD, QP map, etc.), while less time-critical than bitstream-header data, are still required within tight deadlines that the (N-1)*QuantumTime worst case described above can exceed, leaving GPU-timeline resolve unsuitable for them in vGPU scenarios.

# Workflow comparison

## GPU Resolve Path (pre-existing)

::: mermaid
sequenceDiagram
    participant Submit as App (submission thread)
    participant CmdList as ID3D12VideoEncodeCommandList
    participant Consumer as App (consumer thread)

    Submit->>CmdList: EncodeFrame1
    Submit->>CmdList: ResolveEncoderOutputMetadata1<br/>(input: opaque metadata resource,<br/>output: resolved metadata resources)
    CmdList-->>Consumer: Signal fence (EncodeFrame1 + resolve complete)
    Consumer->>Consumer: read resolved metadata
    Consumer->>Consumer: read compressed bitstream
    Consumer->>Consumer: Build frame bitstream with post-encode values from resolved metadata
    Consumer->>Consumer: read resolved stats
:::

## CPU Resolve Path (this spec)

::: mermaid
sequenceDiagram
    participant Submit as App (submission thread)
    participant CmdList as ID3D12VideoEncodeCommandList
    participant Encoder as ID3D12VideoEncoder1
    participant Consumer as App (consumer thread)

    Submit->>CmdList: EncodeFrame1
    CmdList-->>Consumer: Signal fence (EncodeFrame1 complete)
    Consumer->>Consumer: Wait for EncodeFrame1 fence
    Consumer->>Encoder: ResolveEncoderOutputMetadataCPU<br/>(call 1: write only ResolvedLayoutMetadata,<br/>stats outputs skipped via {NULL, 0})
    Encoder-->>Consumer: Return (base resolved metadata written)
    Consumer->>Consumer: Read compressed bitstream
    Consumer->>Consumer: Build frame bitstream with post-encode values from resolved metadata
    Consumer->>Encoder: ResolveEncoderOutputMetadataCPU<br/>(call 2: write only optional stats outputs,<br/>ResolvedLayoutMetadata skipped via {NULL, 0})
    Encoder-->>Consumer: Return (stats outputs written)
    Consumer->>Consumer: read resolved stats
:::

> Note: Alternatively, the app can resolve all outputs in a single call; this diagram shows the split-call pattern for the case where bitstream-related metadata has a tighter deadline than the stats.

---

# Video Encoding API

## ENUM: D3D12_FEATURE_VIDEO

```C++
typedef enum D3D12_FEATURE_VIDEO
{
    ...
    D3D12_FEATURE_VIDEO_ENCODER_CPU_RESOLVE = ...,
} D3D12_FEATURE_VIDEO;
```

*D3D12_FEATURE_VIDEO_ENCODER_CPU_RESOLVE*

Queries CPU resolve support. Associated data structure: `D3D12_FEATURE_DATA_VIDEO_ENCODER_CPU_RESOLVE`.

## ENUM: D3D12_VIDEO_ENCODER_CPU_RESOLVE_SUPPORT_FLAGS

```C++
typedef enum D3D12_VIDEO_ENCODER_CPU_RESOLVE_SUPPORT_FLAGS
{
    D3D12_VIDEO_ENCODER_CPU_RESOLVE_SUPPORT_FLAG_NONE      = 0x0,
    D3D12_VIDEO_ENCODER_CPU_RESOLVE_SUPPORT_FLAG_AVAILABLE = 0x1,
} D3D12_VIDEO_ENCODER_CPU_RESOLVE_SUPPORT_FLAGS;
```

*D3D12_VIDEO_ENCODER_CPU_RESOLVE_SUPPORT_FLAG_NONE*

No flags set. CPU resolve is not supported.

*D3D12_VIDEO_ENCODER_CPU_RESOLVE_SUPPORT_FLAG_AVAILABLE*

CPU resolve is supported via `ID3D12VideoEncoder1::ResolveEncoderOutputMetadataCPU`. Not available with protected resource sessions. The runtime validates this flag is reported before allowing calls to `ResolveEncoderOutputMetadataCPU`.

## STRUCT: D3D12_FEATURE_DATA_VIDEO_ENCODER_CPU_RESOLVE

```C++
typedef struct D3D12_FEATURE_DATA_VIDEO_ENCODER_CPU_RESOLVE
{
    UINT NodeIndex;                                                // input
    D3D12_VIDEO_ENCODER_CODEC Codec;                               // input
    D3D12_VIDEO_ENCODER_PROFILE_DESC Profile;                      // input
    DXGI_FORMAT InputFormat;                                       // input
    D3D12_VIDEO_ENCODER_PICTURE_RESOLUTION_DESC Resolution;        // input
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION CodecConfiguration;    // input
    D3D12_VIDEO_ENCODER_CPU_RESOLVE_SUPPORT_FLAGS SupportFlags;    // output
    UINT QPMapResolvedRowPitch;                                    // output
    UINT SATDMapResolvedRowPitch;                                  // output
    UINT BitAllocationMapResolvedRowPitch;                         // output
} D3D12_FEATURE_DATA_VIDEO_ENCODER_CPU_RESOLVE;
```

**Members**

*NodeIndex*

In multi-adapter operation, identifies the physical adapter.

*Codec*

A `D3D12_VIDEO_ENCODER_CODEC` specifying the codec for which to query CPU resolve support.

*Profile*

A `D3D12_VIDEO_ENCODER_PROFILE_DESC` specifying the profile for which to query CPU resolve support.

*InputFormat*

A `DXGI_FORMAT` specifying the input format of the source video textures of the encoding session.

*Resolution*

A `D3D12_VIDEO_ENCODER_PICTURE_RESOLUTION_DESC` specifying the resolution of the source video textures of the encoding session.

*CodecConfiguration*

A `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION` specifying the codec configuration for which to query CPU resolve support.

*SupportFlags*

CPU resolve support per `D3D12_VIDEO_ENCODER_CPU_RESOLVE_SUPPORT_FLAGS`.

*QPMapResolvedRowPitch*, *SATDMapResolvedRowPitch*, *BitAllocationMapResolvedRowPitch*

Row pitches in bytes for `OutputQPMap`, `OutputSATDMap`, and `OutputBitAllocationMap` respectively. Each pitch is >= `Width * sizeof(element)` (dimensions and element type per the table in [`D3D12_VIDEO_ENCODER_RESOLVE_METADATA_CPU_OUTPUT_ARGUMENTS`](#struct-d3d12_video_encoder_resolve_metadata_cpu_output_arguments)). `0` when the corresponding stats feature is not supported for the queried codec/config.

## STRUCT: D3D12_VIDEO_ENCODER_RESOLVE_METADATA_CPU_INPUT_ARGUMENTS

```C++
typedef struct D3D12_VIDEO_ENCODER_RESOLVE_METADATA_CPU_INPUT_ARGUMENTS
{
    D3D12_VIDEO_ENCODER_PICTURE_RESOLUTION_DESC          EncodedPictureEffectiveResolution;
    D3D12_VIDEO_ENCODER_ENCODE_OPERATION_METADATA_BUFFER HWLayoutMetadata;
    D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAGS   OptionalMetadata;
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION              CodecConfiguration;
} D3D12_VIDEO_ENCODER_RESOLVE_METADATA_CPU_INPUT_ARGUMENTS;
```

Mirrors the GPU timeline [`D3D12_VIDEO_ENCODER_RESOLVE_METADATA_INPUT_ARGUMENTS1`](D3D12_Video_Encoding_Stats_Metadata.md) struct. The codec, profile, and input format fields present on the GPU path struct are omitted here because the CPU resolve method is called on `ID3D12VideoEncoder1`, and the runtime/driver already have those values from `D3D12_VIDEO_ENCODER_DESC` at `CreateVideoEncoder` time.

**Members**

*EncodedPictureEffectiveResolution*

Effective resolution from the `EncodeFrame1` call that produced `HWLayoutMetadata`.

*HWLayoutMetadata*

A `D3D12_VIDEO_ENCODER_ENCODE_OPERATION_METADATA_BUFFER` describing the opaque metadata buffer written by `EncodeFrame1` that is to be resolved.

The app creates and manages the lifetime of the `HWLayoutMetadata` resource and must ensure that the GPU has completed writing to it before calling `ResolveEncoderOutputMetadataCPU`. This can be typically done by waiting on a fence signaled after `EncodeFrame1` completion.

> Note: For this CPU resolve method, the underlying resource must be allocated in system memory on a CPU-accessible heap (`D3D12_HEAP_TYPE_READBACK`, or `D3D12_HEAP_TYPE_CUSTOM` with CPU-readable memory properties). This requirement applies only when using the CPU resolve path introduced by this spec; the pre-existing GPU-based `ResolveEncoderOutputMetadata1` path has no new requirements and continues to work with other types of heaps too such as GPU-only buffers (`D3D12_HEAP_TYPE_DEFAULT`).

*OptionalMetadata*

Must match exactly the `OptionalMetadata` value passed to the `EncodeFrame1` call that produced `HWLayoutMetadata`; tells the resolver which optional metadata kinds are present in the input. Which of those kinds are actually written to output buffers on a given call is governed by [`D3D12_VIDEO_ENCODER_RESOLVE_METADATA_CPU_OUTPUT_ARGUMENTS`](#struct-d3d12_video_encoder_resolve_metadata_cpu_output_arguments).

*CodecConfiguration*

_Optional_ input parameter. Same semantics as the GPU path [`D3D12_VIDEO_ENCODER_RESOLVE_METADATA_INPUT_ARGUMENTS1.CodecConfiguration`](D3D12_Video_Encoding_Stats_Metadata.md): when required by a selected `OptionalMetadata` kind, pass the codec configuration used in the corresponding `EncodeFrame1` call; otherwise zeroed/NULL.

## STRUCT: D3D12_VIDEO_ENCODER_RESOLVE_METADATA_CPU_OUTPUT_BUFFER

```C++
typedef struct D3D12_VIDEO_ENCODER_RESOLVE_METADATA_CPU_OUTPUT_BUFFER
{
    _Field_size_bytes_opt_(ByteSize) void* pData;
    UINT64                             ByteSize;
} D3D12_VIDEO_ENCODER_RESOLVE_METADATA_CPU_OUTPUT_BUFFER;
```

App-owned system memory buffer used as a CPU resolve output.

> Note: `ByteSize` is computed by the app from the reported caps and must match what the driver expects:
> - `ResolvedLayoutMetadata`: per-codec resolved-layout size in [D3D12_Video_Encoding_H264_HEVC.md](D3D12_Video_Encoding_H264_HEVC.md#resolved-metadata-memory-layout-for-id3d12resource-example) or [D3D12_Video_Encoding_AV1.md](D3D12_Video_Encoding_AV1.md#resolved-buffer-layouts-for-resolveencoderoutputmetadata).
> - 2D map outputs (`OutputQPMap`, `OutputSATDMap`, `OutputBitAllocationMap`): `<Map>ResolvedRowPitch * EncoderOutputMetadata<Map>TextureDimensions.Height`, with the row pitch from `D3D12_FEATURE_DATA_VIDEO_ENCODER_CPU_RESOLVE` and the texture height from [`D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOURCE_REQUIREMENTS1`](D3D12_Video_Encoding_Stats_Metadata.md).
> - `ResolvedFramePSNRData`: `sizeof(D3D12_VIDEO_ENCODER_RESOLVE_METADATA_OUTPUT_PSNR_RESOLVED_LAYOUT)`.
> - `ResolvedSubregionsPSNRData`: `EncoderOutputMetadataSubregionsPSNRResolvedMetadataBufferSize` from [`D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOURCE_REQUIREMENTS1`](D3D12_Video_Encoding_Stats_Metadata.md).


## STRUCT: D3D12_VIDEO_ENCODER_RESOLVE_METADATA_CPU_OUTPUT_ARGUMENTS

```C++
typedef struct D3D12_VIDEO_ENCODER_RESOLVE_METADATA_CPU_OUTPUT_ARGUMENTS
{
    D3D12_VIDEO_ENCODER_RESOLVE_METADATA_CPU_OUTPUT_BUFFER ResolvedLayoutMetadata;
    D3D12_VIDEO_ENCODER_RESOLVE_METADATA_CPU_OUTPUT_BUFFER OutputQPMap;
    D3D12_VIDEO_ENCODER_RESOLVE_METADATA_CPU_OUTPUT_BUFFER OutputSATDMap;
    D3D12_VIDEO_ENCODER_RESOLVE_METADATA_CPU_OUTPUT_BUFFER OutputBitAllocationMap;
    D3D12_VIDEO_ENCODER_RESOLVE_METADATA_CPU_OUTPUT_BUFFER ResolvedFramePSNRData;
    D3D12_VIDEO_ENCODER_RESOLVE_METADATA_CPU_OUTPUT_BUFFER ResolvedSubregionsPSNRData;
} D3D12_VIDEO_ENCODER_RESOLVE_METADATA_CPU_OUTPUT_ARGUMENTS;
```

Element formats and per-codec interpretation rules are identical to the GPU resolve path and are defined in [D3D12_Video_Encoding_Stats_Metadata.md](D3D12_Video_Encoding_Stats_Metadata.md).

**Remarks**

- Pass `{NULL, 0}` for any output to skip it on the current call; the driver writes only outputs with a non-NULL `pData`.
- Outputs whose corresponding kind is not enabled in `pInputArguments->OptionalMetadata` must always be skipped.
- Per-output `ByteSize` formulas are listed in [`D3D12_VIDEO_ENCODER_RESOLVE_METADATA_CPU_OUTPUT_BUFFER`](#struct-d3d12_video_encoder_resolve_metadata_cpu_output_buffer).

> Note: This lets apps split a single frame's resolve across multiple `ResolveEncoderOutputMetadataCPU` calls on the same `HWLayoutMetadata`. e.g., a first call that resolves only `ResolvedLayoutMetadata` to finalize the decodable frame bitstream as soon as possible, and a later call that resolves the optional stats outputs (which can be consumed after the bitstream is sent).

### Output element types

| Output | DXGI_FORMAT (GPU path) | App ElementType |
|---|---|---|
| `OutputQPMap` (H264, HEVC) | `DXGI_FORMAT_R8_SINT` | `INT8` |
| `OutputQPMap` (AV1) | `DXGI_FORMAT_R8_UINT` | `UINT8` |
| `OutputSATDMap` | `DXGI_FORMAT_R32_UINT` | `UINT32` |
| `OutputBitAllocationMap` | `DXGI_FORMAT_R32_UINT` | `UINT32` |
| `ResolvedFramePSNRData` | Buffer | `D3D12_VIDEO_ENCODER_RESOLVE_METADATA_OUTPUT_PSNR_RESOLVED_LAYOUT` |
| `ResolvedSubregionsPSNRData` | Buffer | Packed array of `D3D12_VIDEO_ENCODER_RESOLVE_METADATA_OUTPUT_PSNR_RESOLVED_LAYOUT`, length `WrittenSubregionsCount` (read from `ResolvedLayoutMetadata.pData` previously or currently resolved by the app) |

App read pattern for an (x, y) pixel of type `ElementType` (2D map outputs only):

```C++
auto* pRow = reinterpret_cast<ElementType*>(static_cast<BYTE*>(pData) + y * <Map>ResolvedRowPitch);
ElementType value = pRow[x];
```

## INTERFACE: ID3D12VideoEncoder1

Extends `ID3D12VideoEncoder` to add support for CPU-based resolution of encoder output metadata.


```C++
interface ID3D12VideoEncoder1 : ID3D12VideoEncoder
{
    HRESULT ResolveEncoderOutputMetadataCPU(
        [annotation("_In_")] const D3D12_VIDEO_ENCODER_RESOLVE_METADATA_CPU_INPUT_ARGUMENTS* pInputArguments,
        [annotation("_In_")] const D3D12_VIDEO_ENCODER_RESOLVE_METADATA_CPU_OUTPUT_ARGUMENTS* pOutputArguments);
};
```

**Parameters**

*pInputArguments*

Input parameters for the resolve operation.

*pOutputArguments*

App-allocated output buffers. Per-output required sizes are documented in [`D3D12_VIDEO_ENCODER_RESOLVE_METADATA_CPU_OUTPUT_ARGUMENTS`](#struct-d3d12_video_encoder_resolve_metadata_cpu_output_arguments).

**Remarks**

Executes synchronously on the CPU timeline. `ResolveEncoderOutputMetadataCPU` must be called on the same `ID3D12VideoEncoder1` instance that was used (via `EncodeFrame1`) to produce the `HWLayoutMetadata` buffer being resolved.

If any input or output parameter doesn't satisfy the requirements documented above, the method returns `E_INVALIDARG`; the debug layer emits a message identifying the failing argument.

Apps can call this method from multiple app threads concurrently, both for different frames on the same encoder object and for different encoder objects when running multiple encoding sessions. The driver must support these concurrent calls in the associated encoder DDI without data races or corruption. The threading model is:

- **Same encoder, different frames:** Concurrent DDI calls are permitted; whether they execute in parallel or are serialized internally is implementation-defined.
- **Same encoder, same frame (split-call pattern):** Concurrent DDI calls writing different output kinds on the same `HWLayoutMetadata` (e.g., base metadata in one call, stats in another) are permitted under the same rules as the different-frames case above.
- **Different encoder objects:** Concurrent DDI calls must be independent. A call on one encoder must not block a call on another.

Concurrent calls to `ResolveEncoderOutputMetadataCPU` must follow these rules:
- When suballocating from a single `ID3D12Resource` buffer, each concurrent call to `EncodeFrame1` must use non-overlapping regions with appropriate offsets. `ResolveEncoderOutputMetadataCPU` and `ResolveEncoderOutputMetadata1` act as readers under D3D12's multiple-readers/single-writer rules (e.g., `EncodeFrame1` is the writer), allowing multiple concurrent readers to access the same region after the write completes.
- Offsets must be multiples of `EncoderMetadataBufferAccessAlignment` from `D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOURCE_REQUIREMENTS1`. Since `EncodeFrame1` writes to these aligned offsets, resolve operations naturally use the same boundaries.
- Each call must write to non-overlapping regions of the output buffers, or use separate system memory allocations per call.

---

# Testing

HLK encode tests will be extended to use CPU resolve and validate equivalence with the GPU path. Coverage:

- Base resolved metadata equivalence between `ResolveEncoderOutputMetadataCPU.ResolvedLayoutMetadata` and the GPU path's `ResolveEncoderOutputMetadata1.ResolvedLayoutMetadata` for the same `HWLayoutMetadata` input.
- For each optional metadata kind supported on the GPU path, equivalence between the CPU-resolved output and the corresponding GPU-resolved output (`OutputQPMap` / `OutputSATDMap` / `OutputBitAllocationMap` / `ResolvedFramePSNRData` / `ResolvedSubregionsPSNRData`).