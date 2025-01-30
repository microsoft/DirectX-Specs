# 1. HEVC 422/444 D3D12 Video Encoding

# 2. General considerations

This spec focuses on the points of extension where the existing D3D12 Video Encode API needs new structures to support HEVC 422/444 Encode support. The rest of the D3D12 Encode API will remain unmodified for this feature unless explicited in this spec.
The next sections detail the API and DDI for video encoding. In many cases, the DDI is extremely similar to the API. The structures and enumerations which are basically the same (differing solely in name convention) are not repeated in the this specification.

# 3. Video Encoding API

## 3.1. Video Encoding Support API

### 3.1.1. ENUM: D3D12_VIDEO_ENCODER_PROFILE_HEVC

```C++
typedef enum D3D12_VIDEO_ENCODER_PROFILE_HEVC
{
    // Already existing HEVC profiles in DX12 API:
    
    // 8-bit 4:2:0 content
    D3D12_VIDEO_ENCODER_PROFILE_HEVC_MAIN = 0,
    // 10-bit 4:2:0 content
    D3D12_VIDEO_ENCODER_PROFILE_HEVC_MAIN10 = 1,

    // This spec adds the following profiles below:
    
    // 12-bit 4:2:0 content
    D3D12_VIDEO_ENCODER_PROFILE_HEVC_MAIN12 = 2,
    // 8/10-bit 4:2:2 content
    D3D12_VIDEO_ENCODER_PROFILE_HEVC_MAIN10_422 = 3,
    // 12-bit 4:2:2 content
    D3D12_VIDEO_ENCODER_PROFILE_HEVC_MAIN12_422 = 4,
    // 8-bit 4:4:4 content
    D3D12_VIDEO_ENCODER_PROFILE_HEVC_MAIN_444 = 5,
    // 8/10-bit 4:4:4 content
    D3D12_VIDEO_ENCODER_PROFILE_HEVC_MAIN10_444 = 6,
    // 12-bit 4:4:4 content
    D3D12_VIDEO_ENCODER_PROFILE_HEVC_MAIN12_444 = 7,
    // 16-bit 4:4:4 content
    D3D12_VIDEO_ENCODER_PROFILE_HEVC_MAIN16_444 = 8,
} D3D12_VIDEO_ENCODER_PROFILE_HEVC;
```

**Remarks**

Driver uses `D3D12_FEATURE_VIDEO_ENCODER_PROFILE_LEVEL` to report support for a given codec/profile configuration with these new profile entries. This cap must be used by the app to ensure runtime/driver support before using any of the new structures defined below.

Driver uses `D3D12_FEATURE_DATA_VIDEO_ENCODER_INPUT_FORMAT` to report optionally supported formats for a given input `D3D12_VIDEO_ENCODER_PROFILE_HEVC` to the query. For consistency with DXVA decode spec, driver should also report lower subsampling/bitdepth formats as supported other than the maximum allowed by the profile (e.g 8 bit 4:2:0 and others can also be supported when using higher profiles like Main10, etc).

The `DXGI_FORMAT`s are consistent with the HEVC DXVA decode counterpart spec. These are the formats expected for higher subsampling/bit depth content:

- `DXGI_FORMAT_NV12` for 8-bit 4:2:0
- `DXGI_FORMAT_P010` for 10-bit 4:2:0
- `DXGI_FORMAT_P016` for 12-bit 4:2:0
- `DXGI_FORMAT_YUY2` for 8-bit 4:2:2
- `DXGI_FORMAT_Y210` for 10-bit 4:2:2
- `DXGI_FORMAT_Y216` for 12-bit 4:2:2
- `DXGI_FORMAT_AYUV` for 8-bit 4:4:4
- `DXGI_FORMAT_Y410` for 10-bit 4:4:4
- `DXGI_FORMAT_Y416` for 12-bit 4:4:4
- `DXGI_FORMAT_Y416` for 16-bit 4:4:4

### 3.1.2.1 ENUM: D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS

```C++
typedef enum D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS
{
    // Existing flags in DX12 Encode
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_NONE = 0x0,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_BFRAME_LTR_COMBINED_SUPPORT = 0x1,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_INTRA_SLICE_CONSTRAINED_ENCODING_SUPPORT = 0x2,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_CONSTRAINED_INTRAPREDICTION_SUPPORT = 0x4,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_SAO_FILTER_SUPPORT = 0x8,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_ASYMETRIC_MOTION_PARTITION_SUPPORT = 0x10,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_ASYMETRIC_MOTION_PARTITION_REQUIRED = 0x20,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_TRANSFORM_SKIP_SUPPORT = 0x40,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_DISABLING_LOOP_FILTER_ACROSS_SLICES_SUPPORT = 0x80,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_P_FRAMES_IMPLEMENTED_AS_LOW_DELAY_B_FRAMES  = 0x100,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_NUM_REF_IDX_ACTIVE_OVERRIDE_FLAG_SLICE_SUPPORT = 0x200,

    // New flags added in this spec
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_TRANSFORM_SKIP_ROTATION_ENABLED_SUPPORT = 0x400,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_TRANSFORM_SKIP_ROTATION_ENABLED_REQUIRED = 0x800,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_TRANSFORM_SKIP_CONTEXT_ENABLED_SUPPORT = 0x1000,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_TRANSFORM_SKIP_CONTEXT_ENABLED_REQUIRED = 0x2000,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_IMPLICIT_RDPCM_ENABLED_SUPPORT = 0x4000,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_IMPLICIT_RDPCM_ENABLED_REQUIRED = 0x8000,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_EXPLICIT_RDPCM_ENABLED_SUPPORT = 0x10000,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_EXPLICIT_RDPCM_ENABLED_REQUIRED = 0x20000,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_EXTENDED_PRECISION_PROCESSING_SUPPORT = 0x40000,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_EXTENDED_PRECISION_PROCESSING_REQUIRED = 0x80000,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_INTRA_SMOOTHING_DISABLED_SUPPORT = 0x100000,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_INTRA_SMOOTHING_DISABLED_REQUIRED = 0x200000,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_HIGH_PRECISION_OFFSETS_ENABLED_SUPPORT = 0x400000,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_HIGH_PRECISION_OFFSETS_ENABLED_REQUIRED = 0x800000,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_PERSISTENT_RICE_ADAPTATION_ENABLED_SUPPORT = 0x1000000,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_PERSISTENT_RICE_ADAPTATION_ENABLED_REQUIRED = 0x2000000,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_CABAC_BYPASS_ALIGNMENT_ENABLED_SUPPORT = 0x4000000,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_CABAC_BYPASS_ALIGNMENT_ENABLED_REQUIRED = 0x8000000,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_CROSS_COMPONENT_PREDICTION_ENABLED_FLAG_SUPPORT = 0x10000000,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_CROSS_COMPONENT_PREDICTION_ENABLED_FLAG_REQUIRED = 0x20000000,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_CHROMA_QP_OFFSET_LIST_ENABLED_FLAG_SUPPORT = 0x40000000,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_CHROMA_QP_OFFSET_LIST_ENABLED_FLAG_REQUIRED = 0x80000000, // 2^31 bits on 32 bit integer
} D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS;
```

### 3.1.2.2 ENUM: D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS1

```C++
// New enum since D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS reached 32 bits capacity
typedef enum D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS1
{
    // New flags added in this spec
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG1_NONE = 0x0,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG1_SEPARATE_COLOR_PLANE_SUPPORT = 0x1,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG1_SEPARATE_COLOR_PLANE_REQUIRED = 0x2,

} D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS1;
```

Reports HW capabilities for HEVC.

Flags ending in `_SUPPORT` indicate the driver optionally supports setting this flag in the bitstream headers and encoder params.
Flags ending in `_REQUIRED` indicate the driver requires setting this flag in the bitstream headers and encoder params as mandatory. Note that required flags implies the support flag is also reported.

### 3.1.3. STRUCT: D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC1
```C++
typedef struct D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC1 {
    // Inherited from D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS SupportFlags;
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_CUSIZE MinLumaCodingUnitSize;
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_CUSIZE MaxLumaCodingUnitSize;
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_TUSIZE MinLumaTransformUnitSize;
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_TUSIZE MaxLumaTransformUnitSize;
    UCHAR max_transform_hierarchy_depth_inter;
    UCHAR max_transform_hierarchy_depth_intra;

    // New params added in this spec (binary compatible with D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC)
    UINT allowed_diff_cu_chroma_qp_offset_depth_values;
    UINT allowed_log2_sao_offset_scale_luma_values;
    UINT allowed_log2_sao_offset_scale_chroma_values;
    UINT allowed_log2_max_transform_skip_block_size_minus2_values;
    UINT allowed_chroma_qp_offset_list_len_minus1_values;
    UINT allowed_cb_qp_offset_list_values[6];
    UINT allowed_cr_qp_offset_list_values[6];
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS1 SupportFlags1;
} D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC1;
```

The existing `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC` expects `MinLumaCodingUnitSize`, `MaxLumaCodingUnitSize`, `MinLumaTransformUnitSize`, `MaxLumaTransformUnitSize`, `max_transform_hierarchy_depth_inter`, `max_transform_hierarchy_depth_intra` as inputs from the app to the driver, which will then return the result in `SupportFlags` and `D3D12_FEATURE_DATA_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT.IsSupported`

The new added flags in `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS` and `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS1` are outputs from the driver.
When the driver indicated support or requirement for a given coding tool flag, the following new parameters, also driver outputs, indicate the configuration restrictions for using the associated flag coding feature when encoding a frame.

*allowed_diff_cu_chroma_qp_offset_depth_values*

Driver output. A bitmask indicating which values are allowed to be configured when encoding with `diff_cu_chroma_qp_offset_depth`.

Codec valid range for support for `diff_cu_chroma_qp_offset_depth` is [0, 3].

For driver to indicate that `value` is supported, it must set the following in the reported bitmask.

    allowed_diff_cu_chroma_qp_offset_depth_values |= (1 << value)

Apps wanting to set `value` in `diff_cu_chroma_qp_offset_depth`, must validate support by checking:

    (allowed_diff_cu_chroma_qp_offset_depth_values & (1 << value) != 0)

*allowed_log2_sao_offset_scale_luma_values*

Driver output. A bitmask indicating which values are allowed to be configured when encoding with `log2_sao_offset_scale_luma`.

Codec valid range for support for `log2_sao_offset_scale_luma` is [0, 6].

For driver to indicate that `value` is supported, it must set the following in the reported bitmask.

    allowed_log2_sao_offset_scale_luma_values |= (1 << value)

Apps wanting to set `value` in `log2_sao_offset_scale_luma`, must validate support by checking:

    (allowed_log2_sao_offset_scale_luma_values & (1 << value) != 0)

*allowed_log2_sao_offset_scale_chroma_values*

Driver output. A bitmask indicating which values are allowed to be configured when encoding with `log2_sao_offset_scale_chroma`.

Codec valid range for support for `log2_sao_offset_scale_chroma` is [0, 6].

For driver to indicate that `value` is supported, it must set the following in the reported bitmask.

    allowed_log2_sao_offset_scale_chroma_values |= (1 << value)

Apps wanting to set `value` in `log2_sao_offset_scale_chroma`, must validate support by checking:

    (allowed_log2_sao_offset_scale_chroma_values & (1 << value) != 0)

*allowed_log2_max_transform_skip_block_size_minus2_values*

Driver output. A bitmask indicating which values are allowed to be configured when encoding with `log2_max_transform_skip_block_size_minus2`.

Codec valid range for support for `log2_max_transform_skip_block_size_minus2` is [0, 3].

For driver to indicate that `value` is supported, it must set the following in the reported bitmask.

    allowed_log2_max_transform_skip_block_size_minus2_values |= (1 << value)

Apps wanting to set `value` in `log2_max_transform_skip_block_size_minus2`, must validate support by checking:

    (allowed_log2_max_transform_skip_block_size_minus2_values & (1 << value) != 0)

*allowed_chroma_qp_offset_list_len_minus1_values*

Driver output. A bitmask indicating which values are allowed to be configured when encoding with `chroma_qp_offset_list_len_minus1`.

Codec valid range for support for `chroma_qp_offset_list_len_minus1` is [0, 5].

For driver to indicate that `value` is supported, it must set the following in the reported bitmask.

    allowed_chroma_qp_offset_list_len_minus1_values |= (1 << value)

Apps wanting to set `value` in `chroma_qp_offset_list_len_minus1`, must validate support by checking:

    (allowed_chroma_qp_offset_list_len_minus1_values & (1 << value) != 0)

*allowed_cb_qp_offset_list_values*

Driver output. A bitmask indicating which values are allowed to be configured when encoding with `cb_qp_offset_list`.
For `allowed_cb_qp_offset_list_values[index]` with `index` in such that `(allowed_chroma_qp_offset_list_len_minus1_values & (1 << (index)) != 0)`, the driver reports:

Codec valid range for support for `cb_qp_offset_list[index]` is [-12, 12].

For driver to indicate that `value` is supported, it must set the following in the reported bitmask.

    allowed_cb_qp_offset_list_values |= (1 << (value + 12))

Apps wanting to set `value` in `cb_qp_offset_list[index]`, must validate support by checking:

    (allowed_cb_qp_offset_list_values & (1 << (value + 12)) != 0)

*allowed_cr_qp_offset_list_values*

Driver output. A bitmask indicating which values are allowed to be configured when encoding with `cr_qp_offset_list`.
For `allowed_cr_qp_offset_list_values[index]` with `index` in such that `(allowed_chroma_qp_offset_list_len_minus1_values & (1 << (index)) != 0)`, the driver reports:

Codec valid range for support for `cr_qp_offset_list[index]` is [-12, 12].

For driver to indicate that `value` is supported, it must set the following in the reported bitmask.

    allowed_cr_qp_offset_list_values |= (1 << (value + 12))

Apps wanting to set `value` in `cr_qp_offset_list[index]`, must validate support by checking:

    (allowed_cr_qp_offset_list_values & (1 << (value + 12)) != 0)

### 3.1.4. UNION: D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT
```C++
typedef struct D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT {
    UINT DataSize;
    union
    {
        D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_H264* pH264Support;
        D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC* pHEVCSupport;
        D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC1* pHEVCSupport1;
        D3D12_VIDEO_ENCODER_AV1_CODEC_CONFIGURATION_SUPPORT* pAV1Support;
    };
} D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT;
```

For new profiles defined in the spec, the app must ensure support by calling `D3D12_FEATURE_VIDEO_ENCODER_PROFILE_LEVEL` first and then use `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC1` which contains the additional parameters to report the associated profile features.

For compatibility, the previously existing profiles defined before this spec, must continue to use the legacy cap `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC`, to ensure that older runtime/driver versions that do not implement support for `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC1` work as expected.

### 3.1.5.1 ENUM: D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAGS
```C++
typedef enum D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAGS
{
    // Existing flags in DX12 Encode
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAG_NONE = 0x0,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAG_DISABLE_LOOP_FILTER_ACROSS_SLICES = 0x1,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAG_ALLOW_REQUEST_INTRA_CONSTRAINED_SLICES = 0x2,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAG_ENABLE_SAO_FILTER = 0x4,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAG_ENABLE_LONG_TERM_REFERENCES = 0x8,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAG_USE_ASYMETRIC_MOTION_PARTITION = 0x10,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAG_ENABLE_TRANSFORM_SKIPPING = 0x20,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAG_USE_CONSTRAINED_INTRAPREDICTION = 0x40,

    // New flags added in this spec
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAG_TRANSFORM_SKIP_ROTATION = 0x80,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAG_TRANSFORM_SKIP_CONTEXT = 0x100,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAG_IMPLICIT_RDPCM = 0x200,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAG_EXPLICIT_RDPCM = 0x400,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAG_EXTENDED_PRECISION_PROCESSING = 0x800,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAG_INTRA_SMOOTHING_DISABLED = 0x1000,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAG_HIGH_PRECISION_OFFSETS = 0x2000,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAG_PERSISTENT_RICE_ADAPTATION = 0x4000,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAG_CABAC_BYPASS_ALIGNMENT = 0x8000,
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAG_SEPARATE_COLOUR_PLANE = 0x10000,
} D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAGS;
```

Defines the set of flags for the codec-specific encoder configuration properties and SPS syntax. These flags set by the client must conform to the caps reported in `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS` and `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS1`.
Also, the coded bistream headers for the current frame where the associated syntax with these flags is used must match with the ones set when recording EncodeFrame for the current frame.


### 3.1.5.2 ENUM: D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC_FLAGS

```C++
typedef enum D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC_FLAGS
{
    // Existing flags in DX12 Encode
    D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC_FLAGS_NONE = 0x0,
    D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC_FLAG_REQUEST_INTRA_CONSTRAINED_SLICES = 0x1,
    D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC_FLAG_REQUEST_NUM_REF_IDX_ACTIVE_OVERRIDE_FLAG_SLICE = 0x2,

    // New flags added in this spec
    D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC_FLAG_CROSS_COMPONENT_PREDICTION = 0x4,
    D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC_FLAG_CHROMA_QP_OFFSET_LIST = 0x8,
} D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC_FLAGS;
```

Defines the set of flags for the codec-specific picture control properties and PPS syntax. These flags set by the client must conform to the caps reported in `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS` and `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS1`.
Also, the coded bistream headers for the current frame where the associated syntax with these flags is used must match with the ones set when recording EncodeFrame for the current frame.

### 3.1.6. STRUCT: D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC1

```C++
typedef struct D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC1
{
    // Inherited from D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC
    D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC_FLAGS Flags;
    D3D12_VIDEO_ENCODER_FRAME_TYPE_HEVC FrameType;
    UINT slice_pic_parameter_set_id;
    UINT PictureOrderCountNumber;
    UINT TemporalLayerIndex;    
    UINT List0ReferenceFramesCount;
    [annotation("_Field_size_full_(List0ReferenceFramesCount)")] UINT* pList0ReferenceFrames;
    UINT List1ReferenceFramesCount;
    [annotation("_Field_size_full_(List1ReferenceFramesCount)")] UINT* pList1ReferenceFrames;
    UINT ReferenceFramesReconPictureDescriptorsCount;
    [annotation("_Field_size_full_(ReferenceFramesReconPictureDescriptorsCount)")] D3D12_VIDEO_ENCODER_REFERENCE_PICTURE_DESCRIPTOR_HEVC* pReferenceFramesReconPictureDescriptors;
    UINT List0RefPicModificationsCount;
    [annotation("_Field_size_full_(List0RefPicModificationsCount)")] UINT* pList0RefPicModifications;
    UINT List1RefPicModificationsCount;
    [annotation("_Field_size_full_(List1RefPicModificationsCount)")] UINT* pList1RefPicModifications;    
    UINT QPMapValuesCount;
    [annotation("_Field_size_full_(QPMapValuesCount)")] INT8 *pRateControlQPMap;

    // New params added in this spec
    UCHAR diff_cu_chroma_qp_offset_depth;
    UCHAR log2_sao_offset_scale_luma;
    UCHAR log2_sao_offset_scale_chroma;
    UCHAR log2_max_transform_skip_block_size_minus2;
    UCHAR chroma_qp_offset_list_len_minus1;
    CHAR cb_qp_offset_list[6];
    CHAR cr_qp_offset_list[6];
} D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC1;
```

The new added parameters must conform the codec spec, the new flags added to `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS` and `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS1` as well as any driver cap limitations exposed by `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC1`.

### 3.1.7. UNION: D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA

```C++
typedef struct D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA
{
    UINT DataSize;
    union
    {
        D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_H264* pH264PicData;
        D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC* pHEVCPicData;
        D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC1* pHEVCPicData1;
        D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA* pAV1PicData;
    };
} D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA;
```

For new profiles defined in the spec, the app must ensure support by calling `D3D12_FEATURE_VIDEO_ENCODER_PROFILE_LEVEL` first and then use `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC1` which contains the additional parameters to use the associated profile features.

For compatibility, the previously existing profiles defined before this spec, must continue to use the legacy picture param structure `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC`, to ensure that older runtime/driver versions that do not implement support for `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC1` work as expected.
