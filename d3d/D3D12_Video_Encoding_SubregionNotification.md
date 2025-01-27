# 1. D3D12 Video encoding subregion notification

# 2. General considerations

This spec focuses on the points of extension where the existing D3D12 Video Encode API needs new structures to support notifying the API client of subregion completion (e.g slices/tiles) so they can begin consuming these results without having to wait for the complete frame do be fully encoded. The rest of the D3D12 Encode API will remain unmodified for this feature unless explicited in this spec.
The next sections detail the API and DDI for video encoding. In many cases, the DDI is extremely similar to the API. The structures and enumerations which are basically the same (differing solely in name convention) are not repeated in the this specification.

For the scope of the feature on this spec, we’ll still kick-off the encoding for the whole frame (e.g a single EncodeFrame command), but the driver will be able to write the subregion (e.g slice/tile) data to ID3D12Resource buffers and report the byte sizes/offsets before frame completion and metadata/stats translation (e.g before ResolveEncoderOutputMetadata) on feedback resources sent with the EncodeFrame command.

> Due to a bug in dxgkernel for mid-buffer signaling of fences on software engine/nodes, this feature requires Windows 11 24H2 or newer which has the fix.

# 3. Video Encoding API

### ENUM: D3D12_VIDEO_ENCODER_SUPPORT_FLAGS

```C++
typedef enum D3D12_VIDEO_ENCODER_SUPPORT_FLAGS
{
    ...
    // New flags added in this spec
    D3D12_VIDEO_ENCODER_SUPPORT_FLAG_SUBREGION_NOTIFICATION_AVAILABLE_ARRAY_OF_BUFFERS	= ...,
    D3D12_VIDEO_ENCODER_SUPPORT_FLAG_SUBREGION_NOTIFICATION_AVAILABLE_SINGLE_BUFFER	= ...,
} D3D12_VIDEO_ENCODER_SUPPORT_FLAGS;
```

**Remarks**

Driver reports `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_SUBREGION_NOTIFICATION_AVAILABLE_*` to report hardware capabilities that would allow user to wait for interrupt notifications using fences.

Please note that the runtime will require `e_DDI_12_8_0111` or higher DDI version reported by the driver and also verify [`DXGK_VIDSCHCAPS.No64BitAtomics`](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/d3dkmddi/ns-d3dkmddi-_dxgk_vidschcaps) is reported as `FALSE` by the driver in addition to `D3D12DDI_VIDEO_ENCODER_SUPPORT_FLAG_0102_SUBREGION_NOTIFICATION_AVAILABLE_*` to be reported by the driver, before reporting `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_SUBREGION_NOTIFICATION_AVAILABLE_*`. This is a synchronization requirement for the [`FenceValueGPUVirtualAddress`](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/d3dukmdt/ns-d3dukmdt-_d3dddi_synchronizationobjectinfo2) of the fences, to point to an underlying 64 bit fence value and the GPU to be able to atomically signal/update it.


### ENUM: D3D12_VIDEO_ENCODER_HEAP_FLAGS

```C++
typedef enum D3D12_VIDEO_ENCODER_HEAP_FLAGS
{
    ...
    // New flags added in this spec
    D3D12_VIDEO_ENCODER_HEAP_FLAG_ALLOW_SUBREGION_NOTIFICATION_ARRAY_OF_BUFFERS = 0x1,
    D3D12_VIDEO_ENCODER_HEAP_FLAG_ALLOW_SUBREGION_NOTIFICATION_SINGLE_BUFFER = 0x2,
} D3D12_VIDEO_ENCODER_HEAP_FLAGS;
```

For apps to be able to use a given `D3D12_VIDEO_ENCODER_SUBREGION_COMPRESSED_BITSTREAM.BufferMode`, the associated `ID3D12VideoEncoderHeap` passed to `EncodeFrame1` needs to have been created with `CreateVideoEncoderHeap` with the associated encoder heap flag(s) set. Passing these flags allows the driver to make tighter allocations based on the buffer use case (if any).

Please note that the driver must report variations (if any) in memory usage when these flags are set in `D3D12_FEATURE_DATA_VIDEO_ENCODER_HEAP_SIZE`.

Before using any of these new flags in `D3D12_VIDEO_ENCODER_HEAP_DESC` for usages such as `CreateVideoEncoderHeap` or `D3D12_FEATURE_DATA_VIDEO_ENCODER_HEAP_SIZE`, the app (and runtime will validate as well) must validate first the driver reported support for `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_SUBREGION_NOTIFICATION_AVAILABLE_*` using the `ID3D12VideoDevice` object.

### ENUM: D3D12_VIDEO_ENCODER_COMPRESSED_BITSTREAM_NOTIFICATION_MODE

```C++
typedef enum D3D12_VIDEO_ENCODER_COMPRESSED_BITSTREAM_NOTIFICATION_MODE
{
    D3D12_VIDEO_ENCODER_COMPRESSED_BITSTREAM_NOTIFICATION_MODE_FULL_FRAME = 0,
    D3D12_VIDEO_ENCODER_COMPRESSED_BITSTREAM_NOTIFICATION_MODE_SUBREGIONS = 1,
} D3D12_VIDEO_ENCODER_COMPRESSED_BITSTREAM_NOTIFICATION_MODE;
```

After checking for feature support in `D3D12_VIDEO_ENCODER_SUPPORT_FLAGS`, user sets `D3D12_VIDEO_ENCODER_COMPRESSED_BITSTREAM_NOTIFICATION_MODE_SUBREGIONS` on a given `EncodeFrame` command to enable this new mode for subregion notification, or uses `D3D12_VIDEO_ENCODER_COMPRESSED_BITSTREAM_NOTIFICATION_MODE_FULL_FRAME` for the already existing full frame encoding process as usual.

### ENUM: D3D12_VIDEO_ENCODER_SUBREGION_COMPRESSED_BITSTREAM_BUFFER_MODE

```C++
typedef enum D3D12_VIDEO_ENCODER_SUBREGION_COMPRESSED_BITSTREAM_BUFFER_MODE
{
    D3D12_VIDEO_ENCODER_SUBREGION_COMPRESSED_BITSTREAM_BUFFER_MODE_ARRAY_OF_BUFFERS = 0,
    D3D12_VIDEO_ENCODER_SUBREGION_COMPRESSED_BITSTREAM_BUFFER_MODE_SINGLE_BUFFER = 1,
} D3D12_VIDEO_ENCODER_SUBREGION_COMPRESSED_BITSTREAM_BUFFER_MODE;
```

Indicates how will the output buffers be passed in `D3D12_VIDEO_ENCODER_SUBREGION_COMPRESSED_BITSTREAM` below.

*D3D12_VIDEO_ENCODER_SUBREGION_COMPRESSED_BITSTREAM_BUFFER_MODE_ARRAY_OF_BUFFERS*

Requires `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_SUBREGION_NOTIFICATION_AVAILABLE_ARRAY_OF_BUFFERS` supported.

*D3D12_VIDEO_ENCODER_SUBREGION_COMPRESSED_BITSTREAM_BUFFER_MODE_SINGLE_BUFFER*

Requires `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_SUBREGION_NOTIFICATION_AVAILABLE_SINGLE_BUFFER` supported.

### STRUCT: D3D12_VIDEO_ENCODER_SUBREGION_COMPRESSED_BITSTREAM
```C++
typedef struct D3D12_VIDEO_ENCODER_SUBREGION_COMPRESSED_BITSTREAM
{
    D3D12_VIDEO_ENCODER_SUBREGION_COMPRESSED_BITSTREAM_BUFFER_MODE BufferMode;
    UINT ExpectedSubregionCount;
    UINT64* pSubregionBitstreamsBaseOffsets;
    ID3D12Resource **ppSubregionBitstreams;
    ID3D12Resource** ppSubregionSizes;
    ID3D12Resource** ppSubregionOffsets;
    ID3D12Fence** ppSubregionFences;
    UINT64 *pSubregionFenceValues;
}
```

*BufferMode*

Indicates how the output buffers passed in `ppSubregionBitstreams` must be interpreted and used.

#### Buffer inputs and partitioning expectations

The table below specifies the expectations for the app input and the driver partitioning of the buffers. Please note that only one mode at a time is permitted (e.g no mixing modes for different i-th entries in `D3D12_VIDEO_ENCODER_SUBREGION_COMPRESSED_BITSTREAM`).

| Mode/Expectation | `D3D12_VIDEO_ENCODER_SUBREGION_COMPRESSED_BITSTREAM_BUFFER_MODE_SINGLE_BUFFER` | `D3D12_VIDEO_ENCODER_SUBREGION_COMPRESSED_BITSTREAM_BUFFER_MODE_ARRAY_OF_BUFFERS` |
| -------- | -------- | -------- |
| Inputs in `ppSubregionBitstreams` | **Same** `ID3D12Resource` buffer object for all i-th entries | **Different** `ID3D12Resource` buffer objects on each i-th entry |
| Driver buffer partitioning |  Driver must partition the buffer into `ExpectedSubregionCount` non-overlapped regions that fall into different cache lines for the hardware to be able to flush the writes of individual subregions at their byte interval boundaries independently and allow readback from another queue while the encode queue continues to write other non-overlapping byte intervals in the buffer. Any alignment/padding in this mode's partitioning is reported by the driver into the **absolute** byte offsets at `ppSubregionOffsets[i]` | No partitioning. Driver writes individual subregions at the beginning of each individual `ID3D12Resource` buffer object. Any additional padding required is reported by the driver at `ppSubregionOffsets[i]` |

#### Memory availability expectations

For all `BufferMode` modes, at the moment the driver signals completion at `ppSubregionFences[i]`, all pending writes and cache flushes to output buffers **on the byte intervals specified below** must be completed by the driver to ensure the data is accessible.

| Output buffer | Byte interval |
| -------- | -------- |
| `ppSubregionOffsets[i]` | `[0, sizeof(UINT64)]` | `[0, sizeof(UINT64)]` |
| `ppSubregionSizes[i]` | `[0, sizeof(UINT64)]`  | `[0, sizeof(UINT64)]` | 
| `ppSubregionBitstreams[i]` | `[ppSubregionOffsets[i], ppSubregionOffsets[i] + ppSubregionSizes[i]]` |

This allows the app to begin readbacks from different threads on copy queues waiting on `ppSubregionFences[i]`, while `ID3D12VideoEncodeCommandList::EncodeFrame1` is still in execution. Once the fence wait is unblocked on the reader, the app will readback from `ppSubregionOffsets[i]` and `ppSubregionSizes[i]` respectively at the `[0, sizeof(UINT64)]` byte intervals to gather the `ReadbackOffset` and `ReadbackSize` values. Then it will kick-off a `CopyBufferRegion` operation from `ppSubregionBitstreams[i]` at the `[ReadbackOffset, ReadbackOffset + ReadbackSize]` byte interval to retrieve the subregion result.

To avoid unnecessary performance penalties, the driver must issue pending writes and cache flushes to the smallest possible memory blocks that cover the subregion data being signaled as ready. For cache flushes these can be aligned to the cache line byte size.

*ExpectedSubregionCount*

Number of expected subregions passed by the app. The rest of the arrays referring to subregions in this struct will have this many entries. 

**Note:** When the number of subregions is not known before execution (e.g max bytes per slice, etc), this can be the maximum number of subregions expected (also used to calculate the resolved metadata buffer size), and a fence signal on the completion of `EncodeFrame` (the entire frame) can be used to detect there won't be any more pending subregions.

*pSubregionBitstreamsBaseOffsets*

Array contains `ExpectedSubregionCount` buffers passed by the app.

This indicates to the driver a list of base offsets to where to begin writing at each `ppSubregionBitstreams[i]`.

The app must send values aligned to the value in `D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOURCE_REQUIREMENTS.CompressedBitstreamBufferAccessAlignment` reported by the driver.

| Mode/Expectation | `D3D12_VIDEO_ENCODER_SUBREGION_COMPRESSED_BITSTREAM_BUFFER_MODE_SINGLE_BUFFER` | `D3D12_VIDEO_ENCODER_SUBREGION_COMPRESSED_BITSTREAM_BUFFER_MODE_ARRAY_OF_BUFFERS` |
| -------- | -------- | -------- |
| Outputs in `ppSubregionBitstreams[i]` | The driver starts writing the subregion at `pSubregionBitstreamsBaseOffsets[i]` plus the offset calculated by the driver managed partition for the i-th slice | The driver starts writing the i-th subregion at `pSubregionBitstreamsBaseOffsets[i]` |
| Outputs in `ppSubregionOffsets[i]` |  The driver adds `pSubregionBitstreamsBaseOffsets[i]` as part of the absolute offset reported for the i-th slice | The driver adds `pSubregionBitstreamsBaseOffsets[i]` as part of the absolute offset reported for the i-th slice |

*ppSubregionBitstreams*

Array contains `ExpectedSubregionCount` buffers.

Subregion bitstream output buffers passed by the app **for driver to write subregions into**.

*ppSubregionSizes*

Array contains `ExpectedSubregionCount` buffers passed by the app.

On each subregion completion, **driver writes** the byte size of the i-th packed subregion codec payload that the driver **finished writing** to `ppSubregionBitstreams[i]` in this feedback resource as an `UINT64`, without any additional offsets or padding baked into that size.

Note: When [D3D12TightPlacedResourceAlignment](D3D12TightPlacedResourceAlignment.md) is released, this feature can be used to create/place smaller buffers than the current 64Kib minimum size.

*ppSubregionOffsets*

Array contains `ExpectedSubregionCount` buffers passed by the app.

On each subregion completion, **driver writes the absolute byte offset** into `ppSubregionBitstreams[i]` in this feedback resource as an `UINT64`, where the i-th subregion first byte starts, including any padding/alignment requirements, plus the base offset input received at `pSubregionBitstreamsBaseOffsets[i]`.

Please note this is **not** an input parameter with offsets for the driver, but instead a parameter for the driver to report the offsets of the written subregions.

Note: When [D3D12TightPlacedResourceAlignment](D3D12TightPlacedResourceAlignment.md) is released, this feature can be used to create/place smaller buffers than the current 64Kib minimum size.

*ppSubregionFences*

Array contains `ExpectedSubregionCount` fences passed by the app **to be notified by the driver** when the associated `ppSubregionBitstreams[i]` i-th subregion is complete.

*pSubregionFenceValues*

Array contains `ExpectedSubregionCount` fences passed by the app. `pSubregionFenceValues[i]` is the expected value the driver must use to signal the `ppSubregionFences[i]`.

### STRUCT: D3D12_VIDEO_ENCODER_COMPRESSED_BITSTREAM1

```C++
typedef struct D3D12_VIDEO_ENCODER_COMPRESSED_BITSTREAM1
{
    D3D12_VIDEO_ENCODER_COMPRESSED_BITSTREAM_NOTIFICATION_MODE NotificationMode;
    union
    {
        D3D12_VIDEO_ENCODER_COMPRESSED_BITSTREAM FrameOutputBuffer;
        D3D12_VIDEO_ENCODER_SUBREGION_COMPRESSED_BITSTREAM SubregionOutputBuffers;
    };
} D3D12_VIDEO_ENCODER_COMPRESSED_BITSTREAM1;
```

*NotificationMode*

Selects **one** among the available output modes.

*FrameOutputBuffer*

Full frame output bitstream.

Only used when `NotificationMode` is `D3D12_VIDEO_ENCODER_COMPRESSED_BITSTREAM_NOTIFICATION_MODE_FULL_FRAME`.

*SubregionOutputBuffers*

Subregion individual output bitstreams.

Only used when `NotificationMode` is `D3D12_VIDEO_ENCODER_COMPRESSED_BITSTREAM_NOTIFICATION_MODE_SUBREGIONS`.

### STRUCT: D3D12_VIDEO_ENCODER_ENCODEFRAME_OUTPUT_ARGUMENTS1
```C++
typedef struct D3D12_VIDEO_ENCODER_ENCODEFRAME_OUTPUT_ARGUMENTS1
{    
    D3D12_VIDEO_ENCODER_COMPRESSED_BITSTREAM1 Bitstream;
    D3D12_VIDEO_ENCODER_RECONSTRUCTED_PICTURE ReconstructedPicture;
    D3D12_VIDEO_ENCODER_ENCODE_OPERATION_METADATA_BUFFER EncoderOutputMetadata;
} D3D12_VIDEO_ENCODER_ENCODEFRAME_OUTPUT_ARGUMENTS1;
```

*DDI associated structure*

```
typedef struct D3D12DDI_VIDEO_ENCODER_SUBREGION_COMPRESSED_BITSTREAM_0102
{
    D3D12DDI_VIDEO_ENCODER_SUBREGION_COMPRESSED_BITSTREAM_BUFFER_MODE_104 BufferMode;
    UINT ExpectedSubregionCount;
    UINT64* pSubregionBitstreamsBaseOffsets;
    D3D12DDI_HRESOURCE* hDrvSubregionBitstreams;
    D3D12DDI_HRESOURCE hDrvSubregionSizes;
    D3D12DDI_HRESOURCE hDrvSubregionOffsets;
    D3D12DDI_HFENCE* hDrvSubregionFences;
    UINT64 *pSubregionFenceValues;
} D3D12DDI_VIDEO_ENCODER_SUBREGION_COMPRESSED_BITSTREAM_0102;
```

*Driver implementation notes:*

On `e_DDI_12_8_0111` and higher Core DDI versions, on `ID3D12Fence*` creation, the D3D12 runtime calls [`PFND3D12DDI_CREATEFENCE`](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/d3d12umddi/nc-d3d12umddi-pfnd3d12ddi_createfence) with the `D3D12DDI_HFENCE` and `D3D12DDIARG_CREATE_FENCE` with `D3D12DDIARG_CREATE_FENCE.FenceValue.BaseAddress` containing the `FenceValueGPUVirtualAddress` of the synchronization object.

When receiving `D3D12DDI_HFENCE* hDrvSubregionFences` to notify each subregion completion, the driver already has the `FenceValueGPUVirtualAddress`, which is a read-write mapping of the fence value for the GPU. A driver can signal a new fence value by inserting a GPU write command for this address into a command buffer, and the DirectX graphics kernel will unblock waiters for this fence object value when receiving the interrupt [`DXGK_INTERRUPT_MONITORED_FENCE_SIGNALED`](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/d3dkmddi/ne-d3dkmddi-_dxgk_interrupt_type).

Depending on the value of [`DXGK_VIDSCHCAPS.No64BitAtomics`](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/d3dkmddi/ns-d3dkmddi-_dxgk_vidschcaps) cap, [`FenceValueGPUVirtualAddress`](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/d3dukmdt/ns-d3dukmdt-_d3dddi_synchronizationobjectinfo2) points to either a 32 bit or a 64 bit underlying value. For using this feature, the driver **must** report `DXGK_VIDSCHCAPS.No64BitAtomics=FALSE` which indicates a GPU is capable of updating 64 bit values atomically as visible by the CPU.

### INTERFACE: ID3D12VideoEncodeCommandList4

We add a new revision to ID3D12VideoEncodeCommandList to add the encoding method below.

### METHOD: ID3D12VIDEOCOMMANDLIST2::ENCODEFRAME1

```C++
VOID EncodeFrame1(
    [annotation("_In_")] ID3D12VideoEncoder* pEncoder,
    [annotation("_In_")] ID3D12VideoEncoderHeap *pHeap;
    [annotation("_In_")] const D3D12_VIDEO_ENCODER_ENCODEFRAME_INPUT_ARGUMENTS *pInputArguments
    [annotation("_In_")] const D3D12_VIDEO_ENCODER_ENCODEFRAME_OUTPUT_ARGUMENTS1 *pOutputArguments)
```

## Feature Usage

This section explain how would the user/app leverage the subregion notification feature exposed in this spec.

### Bitstream notification mode selection

- When `D3D12_VIDEO_ENCODER_COMPRESSED_BITSTREAM_NOTIFICATION_MODE_FULL_FRAME` is selected, no changes to existing encoding/metadata consumption process are done by the new features added in this spec and `D3D12_VIDEO_ENCODER_COMPRESSED_BITSTREAM1.FrameOutputBuffer` is used.

- When `D3D12_VIDEO_ENCODER_COMPRESSED_BITSTREAM_NOTIFICATION_MODE_SUBREGIONS` is selected:

    -	`D3D12_VIDEO_ENCODER_OUTPUT_METADATA.WrittenSubregionsCount` must be zero. User can determine the final number of subregions from `D3D12_VIDEO_ENCODER_SUBREGION_COMPRESSED_BITSTREAM.ExpectedSubregionCount` (if known before execution) or by counting the number of non-zero `D3D12_VIDEO_ENCODER_SUBREGION_COMPRESSED_BITSTREAM.ppSubregionSizes[]` after a fence was signaled for `EncodeFrame` completion (e.g max bytes per slice).
    - The driver can write subregions out of order if it supports to do so. In any case, the user/app needs to wait on the fences without assuming any expected notification ordering. This allows drivers/hardware with multiple encode hardware engines to possibly work on different subregions and notifications in parallel.
    - The driver must **NOT** write to `D3D12_VIDEO_ENCODER_COMPRESSED_BITSTREAM1.FrameOutputBuffer`. `D3D12_VIDEO_ENCODER_OUTPUT_METADATA.EncodedBitstreamWrittenBytesCount` must be zero to reflect this.
    - Given `D3D12_VIDEO_ENCODER_OUTPUT_METADATA.WrittenSubregionsCount` is zero, there will **not** be any `D3D12_VIDEO_ENCODER_FRAME_SUBREGION_METADATA` elements present in the metadata resolved buffer.

- When any of the notification modes are selected:

    -	The frame stats in `D3D12_VIDEO_ENCODER_OUTPUT_METADATA` (eg. AverageQp, etc) and tile information/post encode values (e.g for AV1 codec) will be only available after full frame completion and reportable through `ResolveEncoderOutputMetadata` as usual. For AV1, user could begin consuming the compressed tile data but would need to wait until frame completion for the post encode values necessary to build the rest of the bitstream headers.

    - For AV1, `D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_SUBREGIONS_LAYOUT_DATA_TILES` and `D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES` values are written as usual after `WrittenSubregionsCount` elements of type `D3D12_VIDEO_ENCODER_FRAME_SUBREGION_METADATA`. Note this also includes the case where `WrittenSubregionsCount` is zero in the `D3D12_VIDEO_ENCODER_COMPRESSED_BITSTREAM_NOTIFICATION_MODE_SUBREGIONS` mode.

### Subregion notification mode usage example

1. User fills in `D3D12_VIDEO_ENCODER_SUBREGION_COMPRESSED_BITSTREAM`
    - `BufferMode` selecting the mode of operation of `ppSubregionBitstreams`.
    - `ExpectedSubregionCount` to indicate the number or elements sent down in the rest of array parameters in this struct.
    - `ppSubregionBitstreams` with app allocated `ID3D12Resource` buffers as per `BufferMode`.
    - `ppSubregionSizes` and `ppSubregionOffsets` with `ExpectedSubregionCount` app-allocated **zeroed** buffers.
    - `ppSubregionFences/pSubregionFenceValues` with the expected fences and values to wait on.
2. User sets `D3D12_VIDEO_ENCODER_COMPRESSED_BITSTREAM_NOTIFICATION_MODE_SUBREGIONS`, records `EncodeFrame1` and calls `ExecuteCommandLists` to kick-off the full frame encoding execution in the GPU.
3. User launches one new threads per subregion, waiting on `ppSubregionFences[i]`, without assuming any subregion completion ordering from the CPU timeline in parallel to the GPU `EncodeFrame` execution.
    - On each slice reader thread:
        - When `ppSubregionFences[i]` is signaled by the driver with the `pSubregionFenceValues[i]` value, the subregion output memory is flushed and accessible, user acknowledges this notification and begins a new operation (**in parallel, without waiting for `EncodeFrame` to finish for the whole frame**) to:
        - Read `ppSubregionOffsets[i]` and `ppSubregionSizes[i]` with the reported values from the driver.
        - Read the `[ppSubregionOffsets[i], ppSubregionOffsets[i]+ppSubregionSizes[i]]` region from `ppSubregionBitstreams[i]`.
5. A signal to a fence after `EncodeFrame` (whole frame) is completed in the command queue can be used by the user to detect no more subregions are pending (useful in modes like bytes per slice where exact subregion number is not known before execution).
