# 1. D3D12 Video Encoding status metadata output

# 2. General considerations

This spec focuses on the points of extension where the existing D3D12 Video Encode API needs new structures to support new driver  metadata stats output per frame blocks. The rest of the D3D12 Encode API will remain unmodified for this feature unless explicited in this spec.
The next sections detail the API and DDI for video encoding. In many cases, the DDI is extremely similar to the API. The structures and enumerations which are basically the same (differing solely in name convention) are not repeated in the this specification.

# 3. Video Encoding API

### ENUM: D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAGS
```C++
typedef enum D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAGS
{
…
    D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_NONE = 0x0,
    D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_QP_MAP = 0x1,
    D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_SATD_MAP = 0x2,
    D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_RC_BIT_ALLOCATION_MAP = 0x4,
} D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAGS;
```

Indicates which optional metadata features are enabled. Future flags here can determine new optional parameters to `D3D12_VIDEO_ENCODER_RESOLVE_METADATA_OUTPUT_ARGUMENTS1` associated with each new flag.

*D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_NONE*

Indicates that no additional optional metadata is present. Please note that all previously existing metadata/stats that were not optional are still mandatory for app back-compat.

*D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_QP_MAP*

Indicates that QPMap output in metadata is enabled. The reported QP values by the driver must be the final QP values used to encode each block (e.g including any QP delta map added on top of the QP value calculated by the driver/hardware rate control algorithm).

The user must check `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_PER_BLOCK_QP_MAP_METADATA_AVAILABLE` first before using this flag. When user sets `D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_QP_MAP`, the driver will write the QP value used per each block of the encoded frame along with the rest of the metadata. If the flag is not set by the user, the driver can avoid calculating this metadata during the frame encoding, and the metadata won't contain it, even when supported by the driver. This is done to avoid performance hits of collecting this information unless required by the customer.

*D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_SATD_MAP*

Indicates that SATD output in metadata is enabled. The reported SATD values by the driver must be before quantization and for each block.

The user must check `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_PER_BLOCK_SATD_MAP_METADATA_AVAILABLE` first before using this flag. When user sets `D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_SATD_MAP`, the driver will write the SATD value used per each block of the encoded frame along with the rest of the metadata. If the flag is not set by the user, the driver can avoid calculating this metadata during the frame encoding, and the metadata won't contain it, even when supported by the driver. This is done to avoid performance hits of collecting this information unless required by the customer.

*D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_RC_BIT_ALLOCATION_MAP*

Indicates that per block rate control bit allocation output in metadata is enabled.

The user must check `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_PER_BLOCK_RC_BIT_ALLOCATION_MAP_METADATA_AVAILABLE` first before using this flag. When user sets `D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_RC_BIT_ALLOCATION_MAP`, the driver will write the number of allocated bits used for each block of the encoded frame along with the rest of the metadata. If the flag is not set by the user, the driver can avoid calculating this metadata during the frame encoding, and the metadata won't contain it, even when supported by the driver. This is done to avoid performance hits of collecting this information unless required by the customer.

### ENUM: D3D12_FEATURE_VIDEO
```C++
typedef enum D3D12_FEATURE_VIDEO
{
…
    D3D12_FEATURE_VIDEO_ENCODER_RESOURCE_REQUIREMENTS1 = ...
} D3D12_FEATURE_VIDEO;
```

### STRUCT: D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOURCE_REQUIREMENTS1

Associated to `D3D12_FEATURE_VIDEO_ENCODER_RESOURCE_REQUIREMENTS1`.

```C++
typedef struct D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOURCE_REQUIREMENTS1
{
    UINT NodeIndex;                                                                                     // input
    D3D12_VIDEO_ENCODER_CODEC Codec;                                                                    // input
    D3D12_VIDEO_ENCODER_PROFILE_DESC Profile;                                                           // input
    DXGI_FORMAT InputFormat;                                                                            // input
    D3D12_VIDEO_ENCODER_PICTURE_RESOLUTION_DESC PictureTargetResolution;                                // input

    BOOL IsSupported;                                                                                   // output
    UINT CompressedBitstreamBufferAccessAlignment;                                                      // output
    UINT EncoderMetadataBufferAccessAlignment;                                                          // output
    UINT MaxEncoderOutputMetadataBufferSize;                                                            // output

    // New entries at the end for binary back-compat with D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOURCE_REQUIREMENTS
    D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAGS OptionalMetadata;                                // input
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION CodecConfiguration;                                         // input
    D3D12_VIDEO_ENCODER_PICTURE_RESOLUTION_DESC EncoderOutputMetadataQPMapTextureDimensions;            // output
    D3D12_VIDEO_ENCODER_PICTURE_RESOLUTION_DESC EncoderOutputMetadataSATDMapTextureDimensions;          // output
    D3D12_VIDEO_ENCODER_PICTURE_RESOLUTION_DESC EncoderOutputMetadataBitAllocationMapTextureDimensions; // output
} D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOURCE_REQUIREMENTS1;
```

The driver uses this new information to differentiate the outputs based on this new information (e.g The `MaxEncoderOutputMetadataBufferSize` may vary if different `OptionalMetadata` flags are enabled or disabled).

**Remarks**

-	When `OptionalMetadata == D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_NONE`, the `D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOURCE_REQUIREMENTS1` cap must behave and report exactly the same outputs (that are present in both structs) as the legacy cap `D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOURCE_REQUIREMENTS`, to maintain backward compatibility.
-	When `OptionalMetadata != D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_NONE`
    - Reported `D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOURCE_REQUIREMENTS1.MaxEncoderOutputMetadataBufferSize` must include all the selected `D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAGS` that `EncodeFrame1` will write into the opaque layout output metadata buffer.
    - Reported `D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOURCE_REQUIREMENTS1.EncoderMetadataBufferAccessAlignment` must take into account all the selected `D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAGS` that `EncodeFrame1` will write into the opaque layout output metadata buffer, and the driver can report here a different alignment requirement than the legacy cap `D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOURCE_REQUIREMENTS` in case one of the optional selected metadatas requires so.
    - Reported `D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOURCE_REQUIREMENTS1.CompressedBitstreamBufferAccessAlignment` must be unchanged respect to the legacy cap `D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOURCE_REQUIREMENTS` (since stats flow in different buffers and doesn't affect output compressed bitstream).
    - The `D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOURCE_REQUIREMENTS1.*Dimensions` and other outputs of non-selected `D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAGS` must be reported as zero.

**New parameters**

*OptionalMetadata*

Indicates the driver which additional optional metadata is requested.

*CodecConfiguration*

_Optional_ input parameter. When required for any of the selected metadatas in `OptionalMetadata` bit mask, user passes the codec configuration that will be used in the encoding session when requesting the optional metadata. Otherwise, is passed as `zeroed/NULL`.

| `OptionalMetadata`    | `CodecConfiguration` |
| -------- | ------- |
| `D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_NONE` | **Null/Zeroed** |
| `D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_QP_MAP` | Required |
| `D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_SATD_MAP` | Required |
| `D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_RC_BIT_ALLOCATION_MAP` | Required |

*EncoderOutputMetadataQPMapTextureDimensions*

Output parameter. When `D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_QP_MAP` is set, indicates the texture dimensions required for `D3D12_VIDEO_ENCODER_RESOLVE_METADATA_OUTPUT_ARGUMENTS1.pOutputQPMap`. The block size can be derived dividing the components of `PictureTargetResolution` by the components of `EncoderOutputMetadataQPMapTextureDimensions`.

*EncoderOutputMetadataSATDMapTextureDimensions*

Output parameter. When `D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_SATD_MAP` is set, indicates the texture dimensions required for `D3D12_VIDEO_ENCODER_RESOLVE_METADATA_OUTPUT_ARGUMENTS1.pOutputSATDMap`. The block size can be derived dividing the components of `PictureTargetResolution` by the components of `EncoderOutputMetadataSATDMapTextureDimensions`.

*EncoderOutputMetadataBitAllocationMapTextureDimensions*

Output parameter. When `D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_RC_BIT_ALLOCATION_MAP` is set, indicates the texture dimensions required for `D3D12_VIDEO_ENCODER_RESOLVE_METADATA_OUTPUT_ARGUMENTS1.pOutputBitAllocationMap`. The block size can be derived dividing the components of `PictureTargetResolution` by the components of `EncoderOutputMetadataBitAllocationMapTextureDimensions`.

### ENUM: D3D12_VIDEO_ENCODER_SUPPORT_FLAGS

```C++
typedef enum D3D12_VIDEO_ENCODER_SUPPORT_FLAGS
{
    ...
    // New flags added in this spec
    D3D12_VIDEO_ENCODER_SUPPORT_FLAG_PER_BLOCK_QP_MAP_METADATA_AVAILABLE	= ...,
    D3D12_VIDEO_ENCODER_SUPPORT_FLAG_PER_BLOCK_SATD_MAP_METADATA_AVAILABLE  = ...,
    D3D12_VIDEO_ENCODER_SUPPORT_FLAG_PER_BLOCK_RC_BIT_ALLOCATION_MAP_METADATA_AVAILABLE  = ...,
} D3D12_VIDEO_ENCODER_SUPPORT_FLAGS;
```

**Remarks**

Driver reports optional support for `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_PER_BLOCK_QP_MAP_METADATA_AVAILABLE` using the associated support cap input parameters to determine support.

### STRUCT: D3D12_VIDEO_ENCODER_ENCODEFRAME_INPUT_ARGUMENTS1
```C++
typedef struct D3D12_VIDEO_ENCODER_ENCODEFRAME_INPUT_ARGUMENTS1
{
    D3D12_VIDEO_ENCODER_SEQUENCE_CONTROL_DESC SequenceControlDesc;
    D3D12_VIDEO_ENCODER_PICTURE_CONTROL_DESC PictureControlDesc;
    ID3D12Resource *pInputFrame;
    UINT64 InputFrameSubresource;
    UINT64 CurrentFrameBitstreamMetadataSize;
    D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAGS OptionalMetadata;
} D3D12_VIDEO_ENCODER_ENCODEFRAME_INPUT_ARGUMENTS1;
```

Extension of `D3D12_VIDEO_ENCODER_ENCODEFRAME_INPUT_ARGUMENTS` with a new input parameter addition `OptionalMetadata`.

*OptionalMetadata*

Input parameter. Indicates the driver which optional metadata (if any) needs to be enabled when encoding this frame.

### INTERFACE: ID3D12VideoEncodeCommandList4

We add a new revision to `ID3D12VideoEncodeCommandList` to add the new methods below.

### METHOD: ID3D12VIDEOCOMMANDLIST4::ENCODEFRAME1

```C++
VOID EncodeFrame1(
    [annotation("_In_")] ID3D12VideoEncoder* pEncoder,
    [annotation("_In_")] ID3D12VideoEncoderHeap *pHeap;
    [annotation("_In_")] const D3D12_VIDEO_ENCODER_ENCODEFRAME_INPUT_ARGUMENTS1 *pInputArguments
    [annotation("_In_")] const D3D12_VIDEO_ENCODER_ENCODEFRAME_OUTPUT_ARGUMENTS *pOutputArguments)
```

# 4. Extensions to ResolveEncoderOutputMetadata

### STRUCT: D3D12_VIDEO_ENCODER_RESOLVE_METADATA_INPUT_ARGUMENTS1

```C++
typedef struct D3D12_VIDEO_ENCODER_RESOLVE_METADATA_INPUT_ARGUMENTS1
{
    D3D12_VIDEO_ENCODER_CODEC EncoderCodec;
    D3D12_VIDEO_ENCODER_PROFILE_DESC EncoderProfile;
    DXGI_FORMAT EncoderInputFormat; 
    D3D12_VIDEO_ENCODER_PICTURE_RESOLUTION_DESC EncodedPictureEffectiveResolution;
    D3D12_VIDEO_ENCODER_ENCODE_OPERATION_METADATA_BUFFER HWLayoutMetadata;
    D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAGS OptionalMetadata;
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION CodecConfiguration;
} D3D12_VIDEO_ENCODER_RESOLVE_METADATA_INPUT_ARGUMENTS1;
```

Extension of `D3D12_VIDEO_ENCODER_RESOLVE_METADATA_INPUT_ARGUMENTS` with a new input parameter addition `OptionalMetadata`.

*OptionalMetadata*

Input parameter. Indicates the driver which optional metadata (if any) was enabled when encoding this frame and needs layout resolving.

*CodecConfiguration*

_Optional_ input parameter. When required for any of the selected metadatas in `OptionalMetadata` bit mask, user passes the codec configuration that used in the associated `EncodeFrame1` that wrote the `HWLayoutMetadata` input. Otherwise, is passed as `zeroed/NULL`.

| `OptionalMetadata`    | `CodecConfiguration` |
| -------- | ------- |
| `D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_NONE` | **Null/Zeroed** |
| `D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_QP_MAP` | Required |
| `D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_SATD_MAP` | Required |
| `D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_RC_BIT_ALLOCATION_MAP` | Required |

### STRUCT: D3D12_VIDEO_ENCODER_RESOLVE_METADATA_OUTPUT_ARGUMENTS1
```C++
typedef struct D3D12_VIDEO_ENCODER_RESOLVE_METADATA_OUTPUT_ARGUMENTS1
{
    
    D3D12_VIDEO_ENCODER_ENCODE_OPERATION_METADATA_BUFFER ResolvedLayoutMetadata;
    ID3D12Resource* pOutputQPMap;
    ID3D12Resource* pOutputSATDMap;
    ID3D12Resource* pOutputBitAllocationMap;
} D3D12_VIDEO_ENCODER_RESOLVE_METADATA_OUTPUT_ARGUMENTS1;
```

*ResolvedLayoutMetadata*

Corresponds to mandatory metadata associated with `D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_NONE`. Resolved layouts are unchanged.

*pOutputQPMap*

Corresponds to the metadata associated with `D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_QP_MAP`. Can be `NULL` if `D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_QP_MAP` is not set.

When present, must be a texture with format `DXGI_FORMAT_R8_SINT` for H264, HEVC or `DXGI_FORMAT_R16_SINT` for AV1. The dimensions must correspond with the value returned by the driver in `D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOURCE_REQUIREMENTS1.EncoderOutputMetadataQPMapTextureDimensions`.

*pOutputSATDMap*

Corresponds to the metadata associated with `D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_SATD_MAP`. Can be `NULL` if `D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_SATD_MAP` is not set.

When present, must be a texture with format `DXGI_FORMAT_R32_UINT`. The dimensions must correspond with the value returned by the driver in `D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOURCE_REQUIREMENTS1.EncoderOutputMetadataSATDMapTextureDimensions`.

*pOutputBitAllocationMap*

Corresponds to the metadata associated with `D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_RC_BIT_ALLOCATION_MAP`. Can be `NULL` if `D3D12_VIDEO_ENCODER_OPTIONAL_METADATA_ENABLE_FLAG_RC_BIT_ALLOCATION_MAP` is not set.

When present, must be a texture with format `DXGI_FORMAT_R32_UINT`. The dimensions must correspond with the value returned by the driver in `D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOURCE_REQUIREMENTS1.EncoderOutputMetadataBitAllocationMapTextureDimensions`.

### METHOD: ID3D12VIDEOCOMMANDLIST4::ResolveEncoderOutputMetadata1

```C++
void ResolveEncoderOutputMetadata1(
        [annotation("_In_")] const D3D12_VIDEO_ENCODER_RESOLVE_METADATA_INPUT_ARGUMENTS1* pInputArguments,
        [annotation("_In_")] const D3D12_VIDEO_ENCODER_RESOLVE_METADATA_OUTPUT_ARGUMENTS1* pOutputArguments);
```
