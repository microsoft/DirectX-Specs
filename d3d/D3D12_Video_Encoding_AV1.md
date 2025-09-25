# 1. AV1 D3D12 Video Encoding

# 2. General considerations

This spec focuses on the different points of extension where the existing D3D12 Video Encode API needs new structures to support AV1 Encode. The rest of the D3D12 Encode API will remain unmodified for this feature unless explicited in this spec.

## 2.2 API and DDI similarities

The next sections detail the API and DDI for video encoding. In many cases, the DDI is extremely similar to the API. The structures and enumerations which are basically the same (differing solely in name convention) are not repeated in the this specification. We include just the DDI structures/enumerations and functions that differ substantially from the API.

# 3. Video Encoding API

## 3.0 Extensions to rate control API

### 3.0.1 Rate control support flags

```C++
typedef enum D3D12_VIDEO_ENCODER_SUPPORT_FLAGS
{
    ...
    D3D12_VIDEO_ENCODER_SUPPORT_FLAG_RATE_CONTROL_EXTENSION1_SUPPORT = 0x2000,
    D3D12_VIDEO_ENCODER_SUPPORT_FLAG_RATE_CONTROL_QUALITY_VS_SPEED_AVAILABLE = 0x4000,
} D3D12_VIDEO_ENCODER_SUPPORT_FLAGS;
```

*D3D12_VIDEO_ENCODER_SUPPORT_FLAG_RATE_CONTROL_EXTENSION1_SUPPORT*

When enabled, indicates the use of `D3D12_VIDEO_ENCODER_RATE_CONTROL_FLAG_ENABLE_EXTENSION1_SUPPORT` is available.

*D3D12_VIDEO_ENCODER_SUPPORT_FLAG_RATE_CONTROL_QUALITY_VS_SPEED_AVAILABLE*

Requires `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_RATE_CONTROL_EXTENSION1_SUPPORT`. When enabled, indicates the use of `D3D12_VIDEO_ENCODER_RATE_CONTROL_FLAG_ENABLE_QUALITY_VS_SPEED` is available.

### 3.0.2 Rate control flags

```C++
typedef enum D3D12_VIDEO_ENCODER_RATE_CONTROL_FLAGS
{
    ...
    D3D12_VIDEO_ENCODER_RATE_CONTROL_FLAG_ENABLE_EXTENSION1_SUPPORT = 0x40,
    D3D12_VIDEO_ENCODER_RATE_CONTROL_FLAG_ENABLE_QUALITY_VS_SPEED = 0x80,
} D3D12_VIDEO_ENCODER_RATE_CONTROL_FLAGS;
```

*D3D12_VIDEO_ENCODER_RATE_CONTROL_FLAG_ENABLE_EXTENSION1_SUPPORT*

Requires `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_RATE_CONTROL_EXTENSION1_SUPPORT`. Indicates when enabled that the extended rate control structures will be used in *D3D12_VIDEO_ENCODER_RATE_CONTROL_CONFIGURATION_PARAMS.pConfiguration_\* or legacy when disabled, as per table below.

*When DISABLED:*

| Rate control mode | D3D12_VIDEO_ENCODER_RATE_CONTROL_CONFIGURATION_PARAMS type | D3D12_VIDEO_ENCODER_RATE_CONTROL_CONFIGURATION_PARAMS DataSize |
|--------------|-------------|-------------|
| D3D12_VIDEO_ENCODER_RATE_CONTROL_MODE_ABSOLUTE_QP_MAP | NULL | 0 |
| D3D12_VIDEO_ENCODER_RATE_CONTROL_MODE_CQP | D3D12_VIDEO_ENCODER_RATE_CONTROL_CQP | sizeof(D3D12_VIDEO_ENCODER_RATE_CONTROL_CQP) |
| D3D12_VIDEO_ENCODER_RATE_CONTROL_MODE_CBR | D3D12_VIDEO_ENCODER_RATE_CONTROL_CBR | sizeof(D3D12_VIDEO_ENCODER_RATE_CONTROL_CBR) |
| D3D12_VIDEO_ENCODER_RATE_CONTROL_MODE_VBR | D3D12_VIDEO_ENCODER_RATE_CONTROL_VBR | sizeof(D3D12_VIDEO_ENCODER_RATE_CONTROL_VBR) |
| D3D12_VIDEO_ENCODER_RATE_CONTROL_MODE_QVBR | D3D12_VIDEO_ENCODER_RATE_CONTROL_QVBR | sizeof(D3D12_VIDEO_ENCODER_RATE_CONTROL_QVBR) |

*When ENABLED:*

| Rate control mode | D3D12_VIDEO_ENCODER_RATE_CONTROL_CONFIGURATION_PARAMS type | D3D12_VIDEO_ENCODER_RATE_CONTROL_CONFIGURATION_PARAMS DataSize |
|--------------|-------------|-------------|
| D3D12_VIDEO_ENCODER_RATE_CONTROL_MODE_ABSOLUTE_QP_MAP | D3D12_VIDEO_ENCODER_RATE_CONTROL_ABSOLUTE_QP_MAP | sizeof(D3D12_VIDEO_ENCODER_RATE_CONTROL_ABSOLUTE_QP_MAP) |
| D3D12_VIDEO_ENCODER_RATE_CONTROL_MODE_CQP | D3D12_VIDEO_ENCODER_RATE_CONTROL_CQP1 | sizeof(D3D12_VIDEO_ENCODER_RATE_CONTROL_CQP1) |
| D3D12_VIDEO_ENCODER_RATE_CONTROL_MODE_CBR | D3D12_VIDEO_ENCODER_RATE_CONTROL_CBR1 | sizeof(D3D12_VIDEO_ENCODER_RATE_CONTROL_CBR1) |
| D3D12_VIDEO_ENCODER_RATE_CONTROL_MODE_VBR | D3D12_VIDEO_ENCODER_RATE_CONTROL_VBR1 | sizeof(D3D12_VIDEO_ENCODER_RATE_CONTROL_VBR1) |
| D3D12_VIDEO_ENCODER_RATE_CONTROL_MODE_QVBR | D3D12_VIDEO_ENCODER_RATE_CONTROL_QVBR1 | sizeof(D3D12_VIDEO_ENCODER_RATE_CONTROL_QVBR1) |


*D3D12_VIDEO_ENCODER_RATE_CONTROL_FLAG_ENABLE_QUALITY_VS_SPEED*

Requires `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_RATE_CONTROL_EXTENSION1_SUPPORT` and `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_RATE_CONTROL_QUALITY_VS_SPEED_AVAILABLE`. When enabled, indicates the use of `QualityVsSpeed` in the rate control structure.

### 3.0.2 Extensions to rate control structures

The following D3D12_VIDEO_ENCODER_RATE_CONTROL_* structures are added. `QualityVsSpeed` is added to all modes and `VBVCapacity`, `InitialVBVFullness` are added to QVBR1 in addition.

`QualityVsSpeed` must be in the range [0, D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT1.MaxQualityVsSpeed]. The lower the value, the fastest the encode operation, similar as defined [in the MF API](https://learn.microsoft.com/en-us/windows/win32/directshow/avenccommonqualityvsspeed-property).

The settings associated to each of the levels exposed by `QualityVsSpeed` must only refer to hardware/driver implementation optimizations and heuristics that **are not** related to specific codec configurations or encoding tools selection, which are already independently exposed in the D3D12 API to the user individually. Please note that other codec configurations and codec encoding tools exposed through this API may also affect quality and speed.

```C++
typedef struct D3D12_VIDEO_ENCODER_RATE_CONTROL_CQP1
{
    UINT ConstantQP_FullIntracodedFrame;
    UINT ConstantQP_InterPredictedFrame_PrevRefOnly;
    UINT ConstantQP_InterPredictedFrame_BiDirectionalRef;
    UINT QualityVsSpeed;
} D3D12_VIDEO_ENCODER_RATE_CONTROL_CQP1;
```

> For any codecs/configurations where the QP ranges can be negative, the ranges used by these `D3D12_VIDEO_ENCODER_RATE_CONTROL_CQP1` parameters are shifted into a positive range. For example for HEVC `[0, 51]` range for 8 bit pixel depth is unchanged, however the range for 10 bits `[-12, 51]` (and similar for higher bit depths) is considered `[0, 63]`.

```C++
typedef struct D3D12_VIDEO_ENCODER_RATE_CONTROL_CBR1
{
    UINT InitialQP;
    UINT MinQP;
    UINT MaxQP;
    UINT64 MaxFrameBitSize;
    UINT64 TargetBitRate;
    UINT64 VBVCapacity;
    UINT64 InitialVBVFullness;
    UINT QualityVsSpeed;
} D3D12_VIDEO_ENCODER_RATE_CONTROL_CBR1;
```

```C++
typedef struct D3D12_VIDEO_ENCODER_RATE_CONTROL_VBR1
{
    UINT InitialQP;
    UINT MinQP;
    UINT MaxQP;
    UINT64 MaxFrameBitSize;
    UINT64 TargetAvgBitRate;
    UINT64 PeakBitRate;
    UINT64 VBVCapacity;
    UINT64 InitialVBVFullness;
    UINT QualityVsSpeed;
} D3D12_VIDEO_ENCODER_RATE_CONTROL_VBR1;
```

```C++
typedef struct D3D12_VIDEO_ENCODER_RATE_CONTROL_QVBR1
{
    UINT InitialQP;
    UINT MinQP;
    UINT MaxQP;
    UINT64 MaxFrameBitSize;
    UINT64 TargetAvgBitRate;
    UINT64 PeakBitRate;
    UINT64 VBVCapacity;
    UINT64 InitialVBVFullness;
    UINT ConstantQualityTarget;
    UINT QualityVsSpeed;
} D3D12_VIDEO_ENCODER_RATE_CONTROL_QVBR1;
```

```C++
typedef struct D3D12_VIDEO_ENCODER_RATE_CONTROL_ABSOLUTE_QP_MAP {
    UINT QualityVsSpeed;
} D3D12_VIDEO_ENCODER_RATE_CONTROL_ABSOLUTE_QP_MAP;
```

```C++
typedef struct D3D12_VIDEO_ENCODER_RATE_CONTROL_CONFIGURATION_PARAMS
{
    UINT DataSize;
    union
    {
        ...
        const D3D12_VIDEO_ENCODER_RATE_CONTROL_CQP *pConfiguration_CQP;
        const D3D12_VIDEO_ENCODER_RATE_CONTROL_CBR *pConfiguration_CBR;
        const D3D12_VIDEO_ENCODER_RATE_CONTROL_VBR *pConfiguration_VBR;
        const D3D12_VIDEO_ENCODER_RATE_CONTROL_QVBR *pConfiguration_QVBR;

        // Extension 1 structs
        const D3D12_VIDEO_ENCODER_RATE_CONTROL_CQP1 *pConfiguration_CQP1;
        const D3D12_VIDEO_ENCODER_RATE_CONTROL_CBR1 *pConfiguration_CBR1;
        const D3D12_VIDEO_ENCODER_RATE_CONTROL_VBR1 *pConfiguration_VBR1;
        const D3D12_VIDEO_ENCODER_RATE_CONTROL_QVBR1 *pConfiguration_QVBR1;
        const D3D12_VIDEO_ENCODER_RATE_CONTROL_ABSOLUTE_QP_MAP* pConfiguration_AbsoluteQPMap;
    };
} D3D12_VIDEO_ENCODER_RATE_CONTROL_CONFIGURATION_PARAMS;
```

## 3.1. Video Encoding Support API

### 3.1.1. ENUM:  D3D12_FEATURE_VIDEO

```C++
typedef enum D3D12_FEATURE_VIDEO
{
…
    D3D12_FEATURE_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_CONFIG = 46,
    D3D12_FEATURE_VIDEO_ENCODER_SUPPORT1 = 47,
} D3D12_FEATURE_VIDEO;
```

**New members**

*D3D12_FEATURE_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_CONFIG*

Used with struct D3D12_FEATURE_DATA_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_CONFIG.

*D3D12_FEATURE_VIDEO_ENCODER_SUPPORT1*

Used with struct D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT1.

### 3.1.2. ENUM: D3D12_VIDEO_ENCODER_CODEC

```C++
typedef enum D3D12_VIDEO_ENCODER_CODEC
{
    ...
    D3D12_VIDEO_ENCODER_CODEC_AV1  = 3,
} D3D12_VIDEO_ENCODER_CODEC;
```

### 3.1.3. ENUM: D3D12_VIDEO_ENCODER_AV1_PROFILE

```C++
typedef enum D3D12_VIDEO_ENCODER_AV1_PROFILE
{
    D3D12_VIDEO_ENCODER_AV1_PROFILE_MAIN = 0,
    D3D12_VIDEO_ENCODER_AV1_PROFILE_HIGH = 1,
    D3D12_VIDEO_ENCODER_AV1_PROFILE_PROFESSIONAL = 2,
} D3D12_VIDEO_ENCODER_AV1_PROFILE;
```

**Remarks**

Driver uses `D3D12_FEATURE_DATA_VIDEO_ENCODER_INPUT_FORMAT` to report optionally supported formats for a given input `D3D12_VIDEO_ENCODER_AV1_PROFILE` to the query.

When a format is supported, the API Client sets accordingly the related AV1 syntax elements based on the `DXGI_FORMAT` used: `color_config()`, `high_bitdepth`, `twelve_bit`, `mono_chrome`, `subsampling_x`, `subsampling_y`, etc.

The` DXGI_FORMAT`s are consistent with the AV1 DXVA decode counterpart spec.

- `D3D12_VIDEO_ENCODER_AV1_PROFILE_MAIN` allows driver reporting support for:
    - `DXGI_FORMAT_NV12` for 8-bit YUV 4:2:0
    - `DXGI_FORMAT_P010` for 10-bit YUV 4:2:0
    - `DXGI_FORMAT_R8_UNORM` for 8-bit monochrome
    - `DXGI_FORMAT_R16_UNORM` for 10-bit monochrome
- `D3D12_VIDEO_ENCODER_AV1_PROFILE_HIGH` also allows:
    - `DXGI_FORMAT_AYUV` for 8-bit YUV 4:4:4
    - `DXGI_FORMAT_Y410` for 10-bit YUV 4:4:4
- `D3D12_VIDEO_ENCODER_AV1_PROFILE_PROFESSIONAL` also allows:
    - `DXGI_FORMAT_YUY2` for 8-bit YUV 4:2:2
    - `DXGI_FORMAT_Y210` for 10-bit YUV 4:2:2
    - `DXGI_FORMAT_Y216` for 12-bit YUV 4:2:2
    - `DXGI_FORMAT_Y416` for 12-bit YUV 4:4:4
    - `DXGI_FORMAT_R16_UNORM` for 12-bit monochrome
    - `DXGI_FORMAT_R16_UNORM` for 12-bit monochrome
    - `DXGI_FORMAT_P016` for 12-bit YUV 4:2:0

### 3.1.4. UNION: D3D12_VIDEO_ENCODER_PROFILE_DESC

```C++
typedef struct D3D12_VIDEO_ENCODER_PROFILE_DESC
{
    UINT DataSize;
    union
    {
        ...
        D3D12_VIDEO_ENCODER_AV1_PROFILE* pAV1Profile;
    };
} D3D12_VIDEO_ENCODER_PROFILE_DESC;
```

Generic structure for codec profiles.

### 3.1.5. ENUM: D3D12_VIDEO_ENCODER_AV1_LEVELS

```C++
typedef enum D3D12_VIDEO_ENCODER_AV1_LEVELS
{
    D3D12_VIDEO_ENCODER_AV1_LEVELS_2_0 = 0,
    D3D12_VIDEO_ENCODER_AV1_LEVELS_2_1 = 1,
    D3D12_VIDEO_ENCODER_AV1_LEVELS_2_2 = 2,
    D3D12_VIDEO_ENCODER_AV1_LEVELS_2_3 = 3,
    D3D12_VIDEO_ENCODER_AV1_LEVELS_3_0 = 4,
    D3D12_VIDEO_ENCODER_AV1_LEVELS_3_1 = 5,
    D3D12_VIDEO_ENCODER_AV1_LEVELS_3_2 = 6,
    D3D12_VIDEO_ENCODER_AV1_LEVELS_3_3 = 7,
    D3D12_VIDEO_ENCODER_AV1_LEVELS_4_0 = 8,
    D3D12_VIDEO_ENCODER_AV1_LEVELS_4_1 = 9,
    D3D12_VIDEO_ENCODER_AV1_LEVELS_4_2 = 10,
    D3D12_VIDEO_ENCODER_AV1_LEVELS_4_3 = 11,
    D3D12_VIDEO_ENCODER_AV1_LEVELS_5_0 = 12,
    D3D12_VIDEO_ENCODER_AV1_LEVELS_5_1 = 13,
    D3D12_VIDEO_ENCODER_AV1_LEVELS_5_2 = 14,
    D3D12_VIDEO_ENCODER_AV1_LEVELS_5_3 = 15,
    D3D12_VIDEO_ENCODER_AV1_LEVELS_6_0 = 16,
    D3D12_VIDEO_ENCODER_AV1_LEVELS_6_1 = 17,
    D3D12_VIDEO_ENCODER_AV1_LEVELS_6_2 = 18,
    D3D12_VIDEO_ENCODER_AV1_LEVELS_6_3 = 19,
    D3D12_VIDEO_ENCODER_AV1_LEVELS_7_0 = 20,
    D3D12_VIDEO_ENCODER_AV1_LEVELS_7_1 = 21,
    D3D12_VIDEO_ENCODER_AV1_LEVELS_7_2 = 22,
    D3D12_VIDEO_ENCODER_AV1_LEVELS_7_3 = 23,
} D3D12_VIDEO_ENCODER_AV1_LEVELS;
```

### 3.1.6. ENUM: D3D12_VIDEO_ENCODER_AV1_TIER
```C++
typedef enum D3D12_VIDEO_ENCODER_AV1_TIER
{
    D3D12_VIDEO_ENCODER_AV1_TIER_MAIN = 0,
    D3D12_VIDEO_ENCODER_AV1_TIER_HIGH = 1,
} D3D12_VIDEO_ENCODER_AV1_TIER;
```

### 3.1.7. STRUCT: D3D12_VIDEO_ENCODER_AV1_LEVEL_TIER_CONSTRAINTS

```C++
typedef struct D3D12_VIDEO_ENCODER_AV1_LEVEL_TIER_CONSTRAINTS
{
    D3D12_VIDEO_ENCODER_AV1_LEVELS Level;
    D3D12_VIDEO_ENCODER_AV1_TIER Tier;
} D3D12_VIDEO_ENCODER_AV1_LEVEL_TIER_CONSTRAINTS;
```

### 3.1.8. UNION: D3D12_VIDEO_ENCODER_LEVEL_SETTING

```C++
typedef struct D3D12_VIDEO_ENCODER_LEVEL_SETTING
{
    UINT DataSize;
    union
    {
        ...
        D3D12_VIDEO_ENCODER_AV1_LEVEL_TIER_CONSTRAINTS* pAV1LevelSetting;
    };
} D3D12_VIDEO_ENCODER_LEVEL_SETTING;
```

### 3.1.9. ENUM: D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE

```C++
typedef enum D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE
{
    D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE_UNIFORM_GRID_PARTITION = 5,
    D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE_CONFIGURABLE_GRID_PARTITION = 6,
} D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE;
```

**Constants**

*D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE_UNIFORM_GRID_PARTITION*

Allows the driver to *uniformly* partition the frame into a grid with only input from the API Client being number of rows and columns. Driver will return the heights and widths of each cell in the partitioned grid after the execution of the EncodeFrame command in resolved metadata buffer.

    For the AV1 codec, This corresponds to the AV1 spec syntax uniform_tile_spacing_flag equal to 1, when using D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE_UNIFORM_GRID_PARTITION, tiles are uniformly partitioned except the right and bottom edges. When the dimensions cannot be partitioned exactly, the last tile can have smaller size.

*D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE_CONFIGURABLE_GRID_PARTITION*

Allows the API Client to *fully* customize a grid partition of the frame. API Client will pass a list of rows and columns along with the heights and widths of each cell in the partitioned grid in the EncodeFrame command and they have to be honored exactly.

    For the AV1 codec, this corresponds to uniform_tile_spacing_flag equal to 0 means that the tile sizes are coded.

**Remarks**

For further tile support details, please check the associated tile details support cap D3D12_FEATURE_DATA_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_CONFIG.

### 3.1.10. ENUM: D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAGS

```C++

typedef 
enum D3D12_VIDEO_ENCODER_MOTION_ESTIMATION_PRECISION_MODE
{
    ...
    D3D12_VIDEO_ENCODER_MOTION_ESTIMATION_PRECISION_MODE_EIGHTH_PIXEL = 4;
} D3D12_VIDEO_ENCODER_MOTION_ESTIMATION_PRECISION_MODE;
```

### 3.1.11. ENUM: D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAGS

```C++
typedef enum D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAGS
{
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_NONE = 0x0,
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_128x128_SUPERBLOCK = 0x1,
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_FILTER_INTRA = 0x2,
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_INTRA_EDGE_FILTER = 0x4,
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_INTERINTRA_COMPOUND = 0x8,
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_MASKED_COMPOUND = 0x10,
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_WARPED_MOTION = 0x20,
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_DUAL_FILTER = 0x40,
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_JNT_COMP = 0x80,
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_FORCED_INTEGER_MOTION_VECTORS = 0x100,
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_SUPER_RESOLUTION = 0x200,
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_LOOP_RESTORATION_FILTER = 0x400,
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_PALETTE_ENCODING = 0x800,    
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_CDEF_FILTERING = 0x1000,    
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_INTRA_BLOCK_COPY = 0x2000,    
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_FRAME_REFERENCE_MOTION_VECTORS = 0x4000,
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_ORDER_HINT_TOOLS = 0x8000,
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_AUTO_SEGMENTATION = 0x10000,
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_CUSTOM_SEGMENTATION = 0x20000,
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_LOOP_FILTER_DELTAS = 0x40000,
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_QUANTIZATION_DELTAS = 0x80000,
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_QUANTIZATION_MATRIX = 0x100000,
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_REDUCED_TX_SET = 0x200000,
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_MOTION_MODE_SWITCHABLE = 0x400000,
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_ALLOW_HIGH_PRECISION_MV = 0x800000,
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_SKIP_MODE_PRESENT = 0x1000000,
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_DELTA_LF_PARAMS = 0x2000000,
} D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAGS;
```

Reports encoding capabilities for AV1.

**Constants**

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_128x128_SUPERBLOCK*

Indicates if support is available for 128x128 Superblocks.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_FILTER_INTRA*

Indicates if support is available for Intra prediction filter.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_INTRA_EDGE_FILTER*

Indicates if support is available for intra edge filtering process.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_INTERINTRA_COMPOUND*

Indicates if support is available for interintra, where the mode info for inter blocks may contain the syntax element interintra. Equal to 0 specifies that the syntax element interintra will not be present.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_MASKED_COMPOUND*

Indicates if support is available for masked compound, where the mode info for inter blocks may contain the syntax element compound_type. Equal to 0 specifies that the syntax element compound_type will not be present.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_WARPED_MOTION*

Equal to 1 indicates that the syntax element motion_mode may be present. If equal to 0 indicates that the syntax element motion_mode will not be present (this means that LOCALWARP cannot be signaled if this flag is equal to 0).

Related to AV1 syntax enable_warped_motion in the sequence header.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_DUAL_FILTER*

Indicates if support is available for dual filter mode, where the inter prediction filter type may be specified independently in the horizontal and vertical directions. If the flag is equal to 0, only one filter type may be specified, which is then used in both directions.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_JNT_COMP*

Indicates if support is available for the scenario where distance weights process may be used for inter prediction.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_FORCED_INTEGER_MOTION_VECTORS*

Indicates if support is available for using the syntax element force_integer_mv.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_SUPER_RESOLUTION*

Indicates if support is available for super resolution.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_LOOP_RESTORATION_FILTER*

Indicates if support is available for loop restoration filtering.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_PALETTE_ENCODING*

Indicates if support is available for frame level control on palette encoding; Equal to 0 indicates that palette encoding is never used.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_CDEF_FILTERING*

Indicates if support is available for constrained directional enhancement filtering.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_INTRA_BLOCK_COPY*

Indicates if intra block copy is supported or not at frame level. Same syntax as AV1 spec. 

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_FRAME_REFERENCE_MOTION_VECTORS*

Indicates if support is available for use_ref_frame_mvs to be configured on a per frame basis. Equal to 0 specifies that use_ref_frame_mvs syntax element will not be used.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_ORDER_HINT_TOOLS*

Indicates if support is available for usage of tools based on the values of order hints. Equal to 0 indicates that tools based on order hints are not supported and can't be enabled.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_AUTO_SEGMENTATION*

Indicates if the driver can perform segmentation without API Client input and return segmentation_params() information in D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES.
Driver will write the segment map in the compressed bitstream.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_CUSTOM_SEGMENTATION*

Indicates if the driver supports the API Client passing customized segmentation segmentation_params() as well as the segment map and driver will honor exactly.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_LOOP_FILTER_DELTAS*

Indicates if the driver supports use of loop filter deltas. Related to _loop_filter_delta_enabled_ AV1 syntax in loop_filter_params().

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_QUANTIZATION_DELTAS*

Indicates if the driver supports use of quantization delta syntax. 

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_QUANTIZATION_MATRIX*

Indicates if the driver supports use of quantization matrix syntax. 

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_REDUCED_TX_SET*

Indicates if driver supports setting _reduced_tx_set_ in the frame header or must be always set to zero. 

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_MOTION_MODE_SWITCHABLE*

Indicates if driver supports setting _is_motion_mode_switchable_ in the frame header or must be always set to zero. 

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_ALLOW_HIGH_PRECISION_MV*

Indicates if driver supports setting _allow_high_precision_mv_ in the frame header or must be always set to zero. 

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_SKIP_MODE_PRESENT*

Indicates if driver supports setting _skip_mode_present_ in the frame header or must be always set to zero.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_DELTA_LF_PARAMS*

Indicates if the driver supports use of loop filter delta params syntax. Related to _delta_lf_params()_ AV1 syntax.

### 3.1.12. STRUCT: D3D12_VIDEO_ENCODER_AV1_TX_MODE
```C++
typedef enum D3D12_VIDEO_ENCODER_AV1_TX_MODE {
    D3D12_VIDEO_ENCODER_AV1_TX_MODE_ONLY4x4 = 0,
    D3D12_VIDEO_ENCODER_AV1_TX_MODE_LARGEST = 1,
    D3D12_VIDEO_ENCODER_AV1_TX_MODE_SELECT = 2,
} D3D12_VIDEO_ENCODER_AV1_TX_MODE;
```

### 3.1.13. STRUCT: D3D12_VIDEO_ENCODER_AV1_TX_MODE_FLAGS
```C++
typedef enum D3D12_VIDEO_ENCODER_AV1_TX_MODE_FLAGS {
    D3D12_VIDEO_ENCODER_AV1_TX_MODE_FLAG_NONE = 0x0,
    D3D12_VIDEO_ENCODER_AV1_TX_MODE_FLAG_ONLY4x4 = (1 << D3D12_VIDEO_ENCODER_AV1_TX_MODE_ONLY4x4),
    D3D12_VIDEO_ENCODER_AV1_TX_MODE_FLAG_LARGEST = (1 << D3D12_VIDEO_ENCODER_AV1_TX_MODE_LARGEST),
    D3D12_VIDEO_ENCODER_AV1_TX_MODE_FLAG_SELECT = (1 << D3D12_VIDEO_ENCODER_AV1_TX_MODE_SELECT),
} D3D12_VIDEO_ENCODER_AV1_TX_MODE_FLAGS;
```

### 3.1.14. STRUCT: D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS
```C++
typedef enum D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS {
    D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS_EIGHTTAP = 0,
    D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS_EIGHTTAP_SMOOTH = 1,
    D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS_EIGHTTAP_SHARP = 2,
    D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS_BILINEAR = 3,
    D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS_SWITCHABLE = 4,
} D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS;
```

### 3.1.15. STRUCT: D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS_FLAGS
```C++
typedef enum D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS_FLAGS {
    D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS_FLAG_NONE = 0x0,
    D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS_FLAG_EIGHTTAP = (1 << D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS_EIGHTTAP),
    D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS_FLAG_EIGHTTAP_SMOOTH = (1 << D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS_EIGHTTAP_SMOOTH),
    D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS_FLAG_EIGHTTAP_SHARP = (1 << D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS_EIGHTTAP_SHARP),
    D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS_FLAG_BILINEAR = (1 << D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS_BILINEAR),
    D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS_FLAG_SWITCHABLE = (1 << D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS_SWITCHABLE),
} D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS_FLAGS;
```

### 3.1.16. enum: D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_BLOCK_SIZE
```C++
typedef enum D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_BLOCK_SIZE {
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_BLOCK_SIZE_4x4 = 0,
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_BLOCK_SIZE_8x8 = 1,
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_BLOCK_SIZE_16x16 = 2,
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_BLOCK_SIZE_32x32 = 3,
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_BLOCK_SIZE_64x64 = 4,
} D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_BLOCK_SIZE;
```

### 3.1.17. enum: D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE
```C++
typedef enum D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE {
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_DISABLED = 0,
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_ALT_Q = 1,
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_ALT_LF_Y_V = 2,
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_ALT_LF_Y_H = 3,
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_ALT_LF_U = 4,
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_ALT_LF_V = 5,
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_ALT_REF_FRAME = 6,
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_ALT_SKIP = 7,
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_ALT_GLOBALMV = 8,
} D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE;
```

### 3.1.18. enum: D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_FLAGS
```C++
typedef enum D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_FLAGS {
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_FLAG_NONE = 0,
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_FLAG_DISABLED = (1 << D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_DISABLED),
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_FLAG_ALT_Q = (1 << D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_ALT_Q),
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_FLAG_ALT_LF_Y_V = (1 << D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_ALT_LF_Y_V),
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_FLAG_ALT_LF_Y_H = (1 << D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_ALT_LF_Y_H),
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_FLAG_ALT_LF_U = (1 << D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_ALT_LF_U),
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_FLAG_ALT_LF_V = (1 << D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_ALT_LF_V),
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_FLAG_REF_FRAME = (1 << D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_ALT_REF_FRAME),
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_FLAG_ALT_SKIP = (1 << D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_ALT_SKIP),
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_FLAG_ALT_GLOBALMV = (1 << D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_ALT_GLOBALMV),
} D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_FLAGS;
```
### 3.1.19. enum: D3D12_VIDEO_ENCODER_AV1_RESTORATION_TYPE
```C++
typedef enum D3D12_VIDEO_ENCODER_AV1_RESTORATION_TYPE {
    D3D12_VIDEO_ENCODER_AV1_RESTORATION_TYPE_DISABLED = 0,
    D3D12_VIDEO_ENCODER_AV1_RESTORATION_TYPE_SWITCHABLE = 1,
    D3D12_VIDEO_ENCODER_AV1_RESTORATION_TYPE_WIENER = 2,
    D3D12_VIDEO_ENCODER_AV1_RESTORATION_TYPE_SGRPROJ = 3,
} D3D12_VIDEO_ENCODER_AV1_RESTORATION_TYPE;
```

### 3.1.20. enum: D3D12_VIDEO_ENCODER_AV1_RESTORATION_TILESIZE
```C++
typedef enum D3D12_VIDEO_ENCODER_AV1_RESTORATION_TILESIZE {
    D3D12_VIDEO_ENCODER_AV1_RESTORATION_TILESIZE_DISABLED = 0,
    D3D12_VIDEO_ENCODER_AV1_RESTORATION_TILESIZE_32x32 = 1,
    D3D12_VIDEO_ENCODER_AV1_RESTORATION_TILESIZE_64x64 = 2,
    D3D12_VIDEO_ENCODER_AV1_RESTORATION_TILESIZE_128x128 = 3,
    D3D12_VIDEO_ENCODER_AV1_RESTORATION_TILESIZE_256x256 = 4,
} D3D12_VIDEO_ENCODER_AV1_RESTORATION_TILESIZE;
```

Corresponds to the the size of loop restoration units in units of samples in the current plane. The enum values are based on lr_unit_shift and lr_uv_shift in lr_params() AV1 syntax and the RESTORATION_TILESIZE_MAX(256) AV1 spec constant.

```C++
typedef enum D3D12_VIDEO_ENCODER_AV1_RESTORATION_SUPPORT_FLAGS {
    D3D12_VIDEO_ENCODER_AV1_RESTORATION_SUPPORT_FLAG_NOT_SUPPORTED = 0,
    D3D12_VIDEO_ENCODER_AV1_RESTORATION_SUPPORT_FLAG_32x32 = 0x1,
    D3D12_VIDEO_ENCODER_AV1_RESTORATION_SUPPORT_FLAG_64x64 = 0x2,
    D3D12_VIDEO_ENCODER_AV1_RESTORATION_SUPPORT_FLAG_128x128 = 0x4,
    D3D12_VIDEO_ENCODER_AV1_RESTORATION_SUPPORT_FLAG_256x256 = 0x8,
} D3D12_VIDEO_ENCODER_AV1_RESTORATION_SUPPORT_FLAGS;
```

### 3.1.21 ENUM: D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION
```C++
typedef enum D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION
{
    D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_IDENTITY = 0,
    D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_TRANSLATION = 1,
    D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_ROTZOOM = 2,
    D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_AFFINE = 3,
} D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION;
```

**Constants**

*D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_IDENTITY*

Identity transformation. 0 parameters in D3D12_VIDEO_ENCODER_AV1_REFERENCE_PICTURE_WARPED_MOTION_INFO.

*D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_TRANSLATION*

Translational motion. 2 parameters in D3D12_VIDEO_ENCODER_AV1_REFERENCE_PICTURE_WARPED_MOTION_INFO.

*D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_ROTZOOM*

Simplified affine with rotation with zoom. 4 parameters in D3D12_VIDEO_ENCODER_AV1_REFERENCE_PICTURE_WARPED_MOTION_INFO.

*D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_AFFINE*

Affine transform. 6 parameters in D3D12_VIDEO_ENCODER_AV1_REFERENCE_PICTURE_WARPED_MOTION_INFO.

### 3.1.22. enum: D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_FLAGS
```C++
typedef enum D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_FLAGS {
    D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_FLAG_NONE = 0,
    D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_FLAG_IDENTITY = (1 << D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_IDENTITY),
    D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_FLAG_TRANSLATION = (1 << D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_TRANSLATION),
    D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_FLAG_ROTZOOM = (1 << D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_ROTZOOM),
    D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_FLAG_AFFINE = (1 << D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_AFFINE),
} D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_FLAGS;
```

**Remarks**

If only D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_FLAG_NONE is supported, reference warp motion arguments are ignored and AV1 _is_global_ syntax is false for all references.

### 3.1.23. enum: D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAGS
```C++
typedef enum D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAGS {
    D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_NONE = 0,
    D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_QUANTIZATION = 0x1,
    D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_QUANTIZATION_DELTA = 0x2,
    D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_LOOP_FILTER = 0x4,
    D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_LOOP_FILTER_DELTA = 0x8,
    D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_CDEF_DATA = 0x10,
    D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_CONTEXT_UPDATE_TILE_ID = 0x20,
    D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_COMPOUND_PREDICTION_MODE = 0x40,
    D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_PRIMARY_REF_FRAME = 0x80,
    D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_REFERENCE_INDICES = 0x100,
} D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAGS;
```

Specifies for which AV1 encoding features, the underlying encoder is able to override (partially or totally) the associated AV1 syntax values or honor API Client exact configuration input otherwise.

When the bitflag is **SET** for a given feature, the driver receives the related API Client input and is able to override all or certain parameters of the associated structure with the given reported flag, which will then write back in D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES with the final values for the API Client to re-pack the AV1 headers accordingly. API Client can compare this to the associated input structure to determine the driver changes (if any).

When the bitflag is **NOT SET** for a given feature, the driver honors the related API Client input exactly and **copies** the input values in D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES. This way the client can always copy the post encode values to pack the headers directly.

**Constants**

*D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_QUANTIZATION*

Related to D3D12_VIDEO_ENCODER_CODEC_AV1_QUANTIZATION_CONFIG values. Used to code _quantization_params()_. 

*D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_QUANTIZATION_DELTA*

Related to D3D12_VIDEO_ENCODER_CODEC_AV1_QUANTIZATION_DELTA_CONFIG values. Used to code _delta_q_params()_.

*D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_LOOP_FILTER*

Related to D3D12_VIDEO_ENCODER_CODEC_AV1_LOOP_FILTER_CONFIG values. Used to code AV1 syntax _loop_filter_params()_. 

*D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_LOOP_FILTER_DELTA*

Related to D3D12_VIDEO_ENCODER_CODEC_AV1_LOOP_FILTER_DELTA_CONFIG values. Used to code AV1 syntax _delta_lf_params()_. 

*D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_CDEF_DATA*

Related to D3D12_VIDEO_ENCODER_AV1_CDEF_CONFIG values. Used to code AV1 syntax _cdef_params()_.

*D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_CONTEXT_UPDATE_TILE_ID*

Related to *ContextUpdateTileId* element in D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_SUBREGIONS_LAYOUT_DATA_TILES.
Used to code AV1 element syntax _context_update_tile_id_ in _tile_info()_.

*D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_COMPOUND_PREDICTION_MODE*

Related to D3D12_VIDEO_ENCODER_AV1_COMP_PREDICTION_TYPE values. 

**Remarks**

* When API Client selects D3D12_VIDEO_ENCODER_AV1_COMP_PREDICTION_TYPE_COMPOUND_REFERENCE and this flag is set, the driver will return D3D12_VIDEO_ENCODER_AV1_COMP_PREDICTION_TYPE in post encode values. The returned value must be used to code reference_select = 0 (SINGLE) or reference_select = 1 (COMPOUND) syntax accordingly.
* When API Client selects D3D12_VIDEO_ENCODER_AV1_COMP_PREDICTION_TYPE_COMPOUND_SINGLE and this flag is set, the driver will return D3D12_VIDEO_ENCODER_AV1_COMP_PREDICTION_TYPE_COMPOUND_SINGLE and reference_select must be coded as 0 (SINGLE).

*D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_PRIMARY_REF_FRAME*

Related to *PrimaryRefFrame* element in D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA.
Used to code AV1 element syntax _primary_ref_frame_ in _uncompressed_header()_.

*D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_REFERENCE_INDICES*

When the flag is reported by the driver, the driver may reorder/remap (but not change the number of references) of the D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES.ReferenceIndices array output, based on the user input D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA.ReferenceIndices. Otherwise, driver must copy each array entry of this post encode output parameter as-is from D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA.ReferenceIndices.

API Client will write the picture header *ref_frame_idx* AV1 syntax from this output parameter.

### 3.1.24. STRUCT: D3D12_VIDEO_ENCODER_AV1_CODEC_CONFIGURATION_SUPPORT
```C++
typedef struct D3D12_VIDEO_ENCODER_AV1_CODEC_CONFIGURATION_SUPPORT {
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAGS SupportedFeatureFlags;
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAGS RequiredFeatureFlags;
    D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS_FLAGS SupportedInterpolationFilters;
    D3D12_VIDEO_ENCODER_AV1_RESTORATION_SUPPORT_FLAGS SupportedRestorationParams[3][3];
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_FLAGS SupportedSegmentationModes;
    D3D12_VIDEO_ENCODER_AV1_TX_MODE_FLAGS SupportedTxModes[4];
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_BLOCK_SIZE SegmentationBlockSize;
    D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAGS PostEncodeValuesFlags;
    UINT MaxTemporalLayers;
    UINT MaxSpatialLayers;
} D3D12_VIDEO_ENCODER_AV1_CODEC_CONFIGURATION_SUPPORT;
```

**Members**

*SupportedFeatureFlags*

Output param. Indicates which features are supported for the codec. Supported features can be set or not by the API Client.

*RequiredFeatureFlags*

Output param. Indicates which features the driver **requires** to be set.

*SupportedInterpolationFilters*

Output parameter. Indicates which values can be selected on input parameters of type D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS.

*SupportedRestorationParams*

Output parameter. Indicates which values can be selected as input parameters for *FrameRestorationType* and *LoopRestorationPixelSize* in *D3D12_VIDEO_ENCODER_AV1_RESTORATION_CONFIG*. 

The first array indexing corresponds to the restoration filter type:
| Index i in SupportedRestorationParams[i][j] | Filter type |
|--------------|-------------|
| 0 | SWITCHABLE |
| 1 | WIENER     |
| 2 | SGRPROJ    |

*Note the indexing of the filter types corresponds to D3D12_VIDEO_ENCODER_AV1_RESTORATION_TYPE **minus 1** (skipping D3D12_VIDEO_ENCODER_AV1_RESTORATION_TYPE_DISABLED)*.

The second array indexing corresponds to the planes:
| Index j in SupportedRestorationParams[i][j] | Plane |
|--------------|-------------|
| 0 | Y plane |
| 1 | U plane |
| 2 | V plane |

The value returned in SupportedRestorationParams[i][j] is a bitflag mask indicating whether the i-th filter in the j-th plane is either:

1. Not supported indicated by SupportedRestorationParams[i][j] = D3D12_VIDEO_ENCODER_AV1_RESTORATION_SUPPORT_FLAG_NOT_SUPPORTED.
2. Supported with any of the D3D12_VIDEO_ENCODER_AV1_RESTORATION_TILESIZE as indicated by the combinable bit flags in SupportedRestorationParams[i][j].

*SupportedSegmentationModes*

Output parameter. Indicates which segmentation modes can be selected in D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_CONFIG.

*SupportedTxModes*

Output parameter. Indicates which values can be selected on input parameters of type D3D12_VIDEO_ENCODER_AV1_TX_MODE for different D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE.

**Note**: Driver must support at least 1 mode for each frame type (ie. mask value cannot be 0).

*SegmentationBlockSize*

Output parameter. Indicates the block size for the segment map. 
This is both the for input blocks in D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MAP for custom segmentation or the block size of the segment map written in the compressed bitstream by the driver in auto segmentation.

*PostEncodeValuesFlags*

Specifies for which AV1 encoding features, the underlying encoder is able to override the associated AV1 syntax values or accept API Client configurable input exactly.

*MaxTemporalLayers*

Specifies the maximum number of temporal layers that can be supported. 
The reported values must be in the range [1..MaxTemporalIdSupported + 1]. A reported value 1, there is no temporal scalability support.

*MaxSpatialLayers*

Specifies the maximum number of spatial layers that can be supported. 
The reported values must be in the range [1..MaxSpatialIdSupported + 1]. A reported value 1, there is no spatial scalability support.


### 3.1.25. UNION: D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT
```C++
typedef struct D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT {
    UINT DataSize;
    union
    {
        ...
        D3D12_VIDEO_ENCODER_AV1_CODEC_CONFIGURATION_SUPPORT* pAV1Support;
    };
} D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT;
```

### 3.1.26 ENUM: D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE

```C++
typedef enum D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE
{
    D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_KEY_FRAME = 0,
    D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_INTER_FRAME = 1,
    D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_INTRA_ONLY_FRAME = 2,
    D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_SWITCH_FRAME = 3,
} D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE;
```

### 3.1.27. STRUCT: D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_FLAGS
```C++
typedef enum D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_FLAGS {
    D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_FLAG_NONE = 0x0,
    D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_FLAG_KEY_FRAME = (1 << D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_KEY_FRAME),
    D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_FLAG_INTER_FRAME = (1 << D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_INTER_FRAME),
    D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_FLAG_INTRA_ONLY_FRAME = (1 << D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_INTRA_ONLY_FRAME),
    D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_FLAG_SWITCH_FRAME = (1 << D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_SWITCH_FRAME),
} D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_FLAGS;
```

### 3.1.28. ENUM: D3D12_VIDEO_ENCODER_AV1_COMP_PREDICTION_TYPE

```C++
typedef enum D3D12_VIDEO_ENCODER_AV1_COMP_PREDICTION_TYPE
{
    D3D12_VIDEO_ENCODER_AV1_COMP_PREDICTION_TYPE_SINGLE_REFERENCE = 0,
    D3D12_VIDEO_ENCODER_AV1_COMP_PREDICTION_TYPE_COMPOUND_REFERENCE = 1,
} D3D12_VIDEO_ENCODER_AV1_COMP_PREDICTION_TYPE;
```

**Constants**

*D3D12_VIDEO_ENCODER_AV1_COMP_PREDICTION_TYPE_SINGLE_REFERENCE*

Indicates that all inter blocks will use single prediction. Equivalent to AV1 syntax _reference_select_ equal to 0.

*D3D12_VIDEO_ENCODER_AV1_COMP_PREDICTION_TYPE_COMPOUND_REFERENCE*

Indicates that the mode info for inter blocks contains the syntax element comp_mode that indicates whether to use single or compound reference prediction. Equivalent to AV1 syntax _reference_select_ equal to 1.

### 3.1.29. STRUCT: D3D12_VIDEO_ENCODER_CODEC_AV1_PICTURE_CONTROL_SUPPORT
```C++
typedef struct D3D12_VIDEO_ENCODER_CODEC_AV1_PICTURE_CONTROL_SUPPORT {
    D3D12_VIDEO_ENCODER_AV1_COMP_PREDICTION_TYPE PredictionMode;
    UINT MaxUniqueReferencesPerFrame;
    D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_FLAGS SupportedFrameTypes;
    D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_FLAGS SupportedReferenceWarpedMotionFlags;
} D3D12_VIDEO_ENCODER_CODEC_AV1_PICTURE_CONTROL_SUPPORT;
```

**Members**

*PredictionMode*

Input param. The requested prediction mode to be used. The driver must return the output parameters below assuming a frame will be encoded using this prediction mode in the picture params structure.

*MaxUniqueReferencesPerFrame*

Output param. Indicates how many unique reference frames in the DPB can be selected at the same time for a given frame from any of the reference types (LAST, ..., ALTREF, etc) in the picture control parameters from the DPB that the API Client manages. In other words, the maximum number distinct (and with ReconstructedPictureResourceIndex != 0xFF) entries in D3D12_VIDEO_ENCODE_REFERENCE_FRAMES.ppTexture2Ds[ReferenceFramesReconPictureDescriptors[ReferenceIndices[i]].ReconstructedPictureResourceIndex] for i in [0..7].

*SupportedFrameTypes*

Output param. Indicates the supported frame types to be used in D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE.

*SupportedReferenceWarpedMotionFlags*

Output param. Indicates the supported types to be used in D3D12_VIDEO_ENCODER_AV1_REFERENCE_PICTURE_WARPED_MOTION_INFO.TransformationType.

### 3.1.30. STRUCT: D3D12_VIDEO_ENCODER_CODEC_PICTURE_CONTROL_SUPPORT
```C++
typedef struct D3D12_VIDEO_ENCODER_CODEC_PICTURE_CONTROL_SUPPORT {
    UINT DataSize;
    union
    {
        ...
        D3D12_VIDEO_ENCODER_CODEC_AV1_PICTURE_CONTROL_SUPPORT* pAV1Support;
    };
} D3D12_VIDEO_ENCODER_CODEC_PICTURE_CONTROL_SUPPORT;
```
### 3.1.31. STRUCT: D3D12_VIDEO_ENCODER_AV1_CODEC_CONFIGURATION
```C++
typedef struct D3D12_VIDEO_ENCODER_AV1_CODEC_CONFIGURATION {
    D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAGS FeatureFlags;
    UINT OrderHintBitsMinus1;
} D3D12_VIDEO_ENCODER_AV1_CODEC_CONFIGURATION;
```

**Members**

*FeatureFlags*

Defines the set of enabled features. Flags can be combined based on the reported capabilities/requirements by the driver.

**Remarks**

### 3.1.32. STRUCT: D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAGS

```C++
typedef enum D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAGS
{
    D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_NONE = 0x0,
    D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_NOT_SPECIFIED  = 0x1,
    D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_CODEC_CONSTRAINT  = 0x2,
    D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_HARDWARE_CONSTRAINT  = 0x4,
    D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_ROWS_COUNT  = 0x8,
    D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_COLS_COUNT  = 0x10,
    D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_WIDTH   = 0x20,
    D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_AREA    = 0x40,
    D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_TOTAL_TILES    = 0x80,
} D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAGS;
```

**Constants**

*D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_NONE*

No flags.

*D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_NOT_SPECIFIED*

When this flag is set, indicates that the requested tiles configuration is not supported due to a reason not specified by any of the other flag categories.

*D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_CODEC_CONSTRAINT*

When this flag is set, indicates that the requested tiles configuration is not supported due to codec constraints. An example on this for AV1 would be D3D12_FEATURE_DATA_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_CONFIG.Level.

*D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_HARDWARE_CONSTRAINT*

When this flag is set, indicates that the requested tiles configuration is not supported due to hardware constraints.

*D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_ROWS_COUNT*

When this flag is set, indicates that the number of tile rows requested is not supported.

*D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_COLS_COUNT*

When this flag is set, indicates that the number of tile columns requested is not supported.

*D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_WIDTH*

When this flag is set, indicates that one or more tiles widths in the requested configuration is not supported.

*D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_AREA*

When this flag is set, indicates that one or more tiles areas in the requested configuration is not supported.

*D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_TOTAL_TILES*

When this flag is set, indicates that the total number of tiles in the requested partition exceeds the total supported tiles count. Please see D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS.MaxSubregionsNumber.

### 3.1.33. STRUCT: D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_SUPPORT

```C++
typedef struct D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_SUPPORT
{
    BOOL Use128SuperBlocks;
    D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_SUBREGIONS_LAYOUT_DATA_TILES TilesConfiguration;
    D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAGS ValidationFlags;
    UINT MinTileRows;
    UINT MaxTileRows;
    UINT MinTileCols;
    UINT MaxTileCols;
    UINT MinTileWidth;
    UINT MaxTileWidth;
    UINT MinTileArea;
    UINT MaxTileArea;
    UINT TileSizeBytesMinus1;
} D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_SUPPORT;
```

**Members**

*Use128SuperBlocks*

Input parameter. Indicates if the returned values by the driver in superblock units need to be expressed as 128x128 superblocks.
Otherwise the superblock default size 64x64 must be used.

*TilesConfiguration*

Input parameter. Desired tile configuration to check support for.

*ValidationFlags*

Output parameter. Indicates more details when D3D12_FEATURE_DATA_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_CONFIG.IsSupported is false.

*MinTileRows*

Output parameter. Minimum number of horizontal partitions.

*MaxTileRows*

Output parameter. Maximum number of horizontal partitions.

*MinTileCols*

Output parameter. Minimum number of vertical partitions.

*MaxTileCols*

Output parameter. Maximum number of vertical partitions.

*MinTileWidth*

Output parameter. Minimum width of any tile, in superblock units.

*MaxTileWidth*

Output parameter. Maximum width of any tile, in superblock units.

*MinTileArea*

Output parameter. Minimum dimension of any tile, in superblock units.

*MaxTileArea*

Output parameter. Maximum dimension of any tile, in superblock units.

*TileSizeBytesMinus1*

Output parameter. Specifies the number of bytes needed to code each tile size. Related to the driver writing the D3D12_VIDEO_ENCODER_FRAME_SUBREGION_METADATA.bSize elements in the resolved metadata.
The API Client will write **tile_size_bytes_minus_1 = (TileSizeBytesMinus1)** in frame_header_obu/uncompressed_header/tile_info when writing the frame header OBU, and when writing *le(TileSizeBytes)* **tile_size_minus_1** in **tile_group_obu()**.

### 3.1.34. STRUCT: D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_CONFIG

```C++
typedef struct D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_CONFIG_SUPPORT {
    UINT DataSize;
    union
    {
        D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_SUPPORT* pAV1Support;
    };
} D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_CONFIG_SUPPORT;
```

### 3.1.35. STRUCT: D3D12_FEATURE_DATA_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_CONFIG

```C++
typedef struct D3D12_FEATURE_DATA_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_CONFIG
{
    UINT NodeIndex; // input
    D3D12_VIDEO_ENCODER_CODEC Codec;                           // input
    D3D12_VIDEO_ENCODER_PROFILE_DESC Profile;                  // input
    D3D12_VIDEO_ENCODER_LEVEL_SETTING Level;                   // input
    D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE SubregionMode; // input
    D3D12_VIDEO_ENCODER_PICTURE_RESOLUTION_DESC FrameResolution; // input
    D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_CONFIG_SUPPORT CodecSupport; // input/output
    BOOL IsSupported; // output
} D3D12_FEATURE_DATA_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_CONFIG;
```

**Remarks**

    At the moment, this support query is only supported for input Codec == D3D12_VIDEO_ENCODER_CODEC_AV1, as it can only be compiled with CodecSupport.pAV1Support pointer of type D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_SUPPORT.

**Members**

*NodeIndex*

Input parameter. in multi-adapter operation, this indicates which physical adapter of the device this operation applies to.

*Codec*

Input parameter. Desired codec to check support for.

*Profile*

Input parameter, desired profile to check support for.

*Level*

Input parameter, desired level to check support for.

*SubregionMode*

Input parameter. Desired subregion mode to check support for.

*FrameResolution*

Input parameter. Indicates the resolution to check support for.

*CodecSupport*

Input/Output parameter. Indicates the codec specific input/output arguments for this cap.

*IsSupported*
Output parameter. Indicates if the driver supports this subregion layout configuration based on the input values, including the codec, profile, level, resolution and any other codec specific parameters.

### 3.1.36. UNION: D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION

```C++
typedef struct D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION
{
    UINT DataSize;
    union
    {
        ...
        D3D12_VIDEO_ENCODER_AV1_CODEC_CONFIGURATION* pAV1Config;
    };
} D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION;
```

### 3.1.37. ENUM: D3D12_VIDEO_ENCODER_VALIDATION_FLAGS

Adds a new flag to the existing D3D12_VIDEO_ENCODER_VALIDATION_FLAGS, for usage with the new extended query cap D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT1.

```C++
typedef enum D3D12_VIDEO_ENCODER_VALIDATION_FLAGS
{
    D3D12_VIDEO_ENCODER_VALIDATION_FLAG_NONE = 0x0,
    ...
    D3D12_VIDEO_ENCODER_VALIDATION_FLAG_SUBREGION_LAYOUT_DATA_NOT_SUPPORTED = 0x1000,
} D3D12_VIDEO_ENCODER_VALIDATION_FLAGS;
```

*New Constants*

*D3D12_VIDEO_ENCODER_VALIDATION_FLAG_SUBREGION_LAYOUT_DATA_NOT_SUPPORTED*

When using D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT1, indicates the subregions configuration passed was not valid. Please use D3D12_FEATURE_DATA_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_CONFIG for more information. D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS.MaxSubregionsNumber and D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS.SubregionBlockPixelsSize still must be reported when driver issues no support result in D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT1.

### 3.1.38. STRUCT: D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT1

Extends on the previous D3D12_FEATURE_VIDEO_ENCODER_SUPPORT query, adding new parameters at the bottom of the associated data structure. This new query can be used with all H264, HEVC and AV1 codecs and must behave exactly as D3D12_FEATURE_VIDEO_ENCODER_SUPPORT semantics.

Please note the previous D3D12_FEATURE_VIDEO_ENCODER_SUPPORT **will not work for AV1 codec** as *Codec* input, and attempting to call it for AV1 will still return S_OK with **ValidationFlags=D3D12_VIDEO_ENCODER_VALIDATION_FLAG_CODEC_NOT_SUPPORTED** and print a debug layer message indicating to instead use the new D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT1 instead.

```C++
typedef struct D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT1
{
    /* Below match existing D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT */
    UINT NodeIndex;
    D3D12_VIDEO_ENCODER_CODEC Codec;
    DXGI_FORMAT InputFormat;
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION CodecConfiguration;
    D3D12_VIDEO_ENCODER_SEQUENCE_GOP_STRUCTURE CodecGopSequence;
    D3D12_VIDEO_ENCODER_RATE_CONTROL RateControl;
    D3D12_VIDEO_ENCODER_INTRA_REFRESH_MODE IntraRefresh;
    D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE SubregionFrameEncoding;
    UINT ResolutionsListCount;
    const D3D12_VIDEO_ENCODER_PICTURE_RESOLUTION_DESC* pResolutionList;
    UINT MaxReferenceFramesInDPB;
    D3D12_VIDEO_ENCODER_VALIDATION_FLAGS ValidationFlags;
    D3D12_VIDEO_ENCODER_SUPPORT_FLAGS SupportFlags;
    D3D12_VIDEO_ENCODER_PROFILE_DESC SuggestedProfile;
    D3D12_VIDEO_ENCODER_LEVEL_SETTING SuggestedLevel;
    [annotation("_Field_size_full_(ResolutionsListCount)")] D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS* pResolutionDependentSupport;

    /* Below are new arguments for D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT1 */
    D3D12_VIDEO_ENCODER_PICTURE_CONTROL_SUBREGIONS_LAYOUT_DATA SubregionFrameEncodingData; // input
    UINT MaxQualityVsSpeed;// output
} D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT1;
```

*New members*

*SubregionFrameEncodingData*

Used to calculate D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT1.SuggestedLevel in codecs that have subregions constraints per level and used for related validation with the new flag D3D12_VIDEO_ENCODER_VALIDATION_FLAG_SUBREGION_LAYOUT_DATA_NOT_SUPPORTED.

*MaxQualityVsSpeed*

Reported by driver. Used as the maximum value allowed for the `QualityVsSpeed` parameter in the rate control structures. When `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_RATE_CONTROL_QUALITY_VS_SPEED_AVAILABLE` is not reported, this value must be reported as zero.

### 3.1.39. STRUCT: D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS
```C++
typedef struct D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS
{
    UINT MaxSubregionsNumber;
    UINT MaxIntraRefreshFrameDuration;
    UINT SubregionBlockPixelsSize;
    UINT QPMapRegionPixelsSize;        
} D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS;
```

Member already present in existing API, see semantics for AV1 below.

*Members*

*MaxSubregionsNumber*

Indicates the maximum number of tiles supported by the hardware for the associated resolution.

*SubregionBlockPixelsSize*

Indicates the tiles block sizes in pixels for the associated resolution. This value must be equal or a multiple of the superblock size, which is passed in the input D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION parameter.

*QPMapRegionPixelsSize*

Indicates for the associated resolution, the size in pixels of the squared regions that will be affected by each of the values in the QP map buffer in absolute or delta QP modes. The resolution of the frame will be rounded up to be aligned to this value when it's partitioned in blocks for QP maps and the number of QP values in those maps will be the number of blocks of these indicated pixel size that comprise a full frame. This value must be equal or a multiple of the superblock size, which is passed in the input D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION parameter.

### 3.1.40. STRUCT: D3D12_VIDEO_ENCODER_AV1_SEQUENCE_STRUCTURE
```C++
typedef struct D3D12_VIDEO_ENCODER_AV1_SEQUENCE_STRUCTURE
{    
    UINT IntraDistance;
    UINT InterFramePeriod;
} D3D12_VIDEO_ENCODER_AV1_SEQUENCE_STRUCTURE;
```

This is a hint to the driver of the GOP being used for rate control purposes only.

**Members**

*IntraDistance*

Indicates the distance between intra-only frames (or key frames) in the video sequence, or the number of pictures on a sequence of inter-frame pictures. If set to 0, only the first frame will be an key-frame. 

*InterPeriod*

Indicates the period for inter-frames to be inserted within the inter frame structure. Note that if *IntraDistance* is set to 0 for infinite inter frame structure, this value must be greater than zero.

### 3.1.41. STRUCT: D3D12_VIDEO_ENCODER_SEQUENCE_GOP_STRUCTURE
```C++
typedef struct D3D12_VIDEO_ENCODER_SEQUENCE_GOP_STRUCTURE
{
    UINT DataSize;
    union
    {
        ...
        D3D12_VIDEO_ENCODER_AV1_SEQUENCE_STRUCTURE* pAV1SequenceStructure;
    };
} D3D12_VIDEO_ENCODER_SEQUENCE_GOP_STRUCTURE;
```

# 4. Encoding Operation

## Expected bitstream header values for AV1

## **Remarks**

### **Driver/host header coding responsabilities**

Given an encoded frame with K tiles, the driver will write the K **decode_tile()** AV1 syntax elements in the compressed bitstream, corresponding to the requested tiles in EncodeFrame arguments.

The API Client then builds the tile_group_obu() AV1 syntax elements with tile_start_and_end_present_flag/tg_start/tg_end elements to arrange the tiles into tile groups as desired with the condition that the tiles are placed sequentially. The tile_size_minus_1 element is coded from the related tile D3D12_VIDEO_ENCODER_FRAME_SUBREGION_METADATA information and decode_tile() elements are copied from the compressed bitstream buffer. Finally, each tile_group_obu() is wrapped around open_bitstream_unit() elements of type OBU_TILE_GROUP and prepended with an OBU_FRAME_HEADER, or in case of a single tile group an OBU_FRAME type can be used.

The API Client is responsible for inferring _obu_extension_flag_ as !(TemporalLayerIndexPlus1 || SpatialLayerIndexPlus1) for the current frame and also code if necessary _temporal_id_ and _spatial_id_ in the open_bitstream_unit().

The EncodeFrame submissions are in encode order, like the other codecs implemented in D3D12 Encode API.

### **Resolution changes and spatial scalability**

If D3D12_VIDEO_ENCODER_SUPPORT_FLAG_RESOLUTION_RECONFIGURATION_AVAILABLE is reported by the driver, this still only applies to resolution changes **on a key frame**. 

The active sequence header must have the max_frame_*_minus_1 
syntax set to the max resolution present in the associated *ID3D12VideoEncoderHeap* being used, and different frames using resolutions also present in the associated *ID3D12VideoEncoderHeap* can use th AV1 syntax _frame_size_override_flag_ in frame_size() to convey change of resolution.

If D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_FLAG_SWITCH_FRAME is supported, the reference frames must point to higher or equal resolution than the current switch frame being encoded and the different resolutions must be all present in the associated *ID3D12VideoEncoderHeap* being used.

Similarly, if spatial scalability is supported, the different resolutions of the reference frames must be all present in the associated *ID3D12VideoEncoderHeap* being used.

### **Rate control notes**

The accepted range for D3D12_VIDEO_ENCODER_RATE_CONTROL_QVBR.ConstantQualityTarget is [0..63]. The lowest the value, the highest the quality.

In general, `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_RATE_CONTROL_RECONFIGURATION_AVAILABLE` applies to the quality vs speed tweaking and the following RC parameters of the different RC modes: QP in constant QP, bitrates and quality levels in CBR, VBR and QVBR. Driver can return `D3D12_VIDEO_ENCODER_ENCODE_ERROR_FLAG_RECONFIGURATION_REQUEST_NOT_SUPPORTED` in `D3D12_VIDEO_ENCODER_OUTPUT_METADATA.EncodeErrorFlags` for other unsupported RC params reconfiguration. 

## 4.1 Encoding Operation API

### 4.1.1 STRUCT: D3D12_VIDEO_ENCODER_AV1_REFERENCE_PICTURE_WARPED_MOTION_INFO
```C++
typedef struct D3D12_VIDEO_ENCODER_AV1_REFERENCE_PICTURE_WARPED_MOTION_INFO
{
    D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION TransformationType;
    
    INT TransformationMatrix[8];
    bool InvalidAffineSet;
} D3D12_VIDEO_ENCODER_AV1_REFERENCE_PICTURE_WARPED_MOTION_INFO;
```

**Remarks**

Related to warped motion transformation/global motion type. Transform to be applied to motion vectors.

### 4.1.2 STRUCT: D3D12_VIDEO_ENCODER_AV1_REFERENCE_PICTURE_DESCRIPTOR
```C++
#define D3D12_VIDEO_ENCODER_AV1_INVALID_DPB_RESOURCE_INDEX 0xFF
typedef struct D3D12_VIDEO_ENCODER_AV1_REFERENCE_PICTURE_DESCRIPTOR
{
    UINT ReconstructedPictureResourceIndex;
    UINT TemporalLayerIndexPlus1;
    UINT SpatialLayerIndexPlus1;
    D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE FrameType;    
    D3D12_VIDEO_ENCODER_AV1_REFERENCE_PICTURE_WARPED_MOTION_INFO WarpedMotionInfo;
    UINT OrderHint;
    UINT PictureIndex;
} D3D12_VIDEO_ENCODER_AV1_REFERENCE_PICTURE_DESCRIPTOR;
```

**Members**

*ReconstructedPictureResourceIndex*

Maps the current reference picture described by this structure to a resource in the D3D12_VIDEO_ENCODER_PICTURE_CONTROL_DESC.ReferenceFrames array.

If the associated slot in ReferenceFramesReconPictureDescriptors containing this structure has a valid *ReconstructedPictureResourceIndex* reference to the D3D12_VIDEO_ENCODER_PICTURE_CONTROL_DESC.ReferenceFrames array then the allowed range of values is [0..254]. Otherwise, if it corresponds to an empty/unused slot in the DPB, then the value must be set to D3D12_VIDEO_ENCODER_AV1_INVALID_DPB_RESOURCE_INDEX.

*TemporalLayerIndexPlus1*

Picture temporal layer index plus one of the previously encoded frame now used as reference.

*SpatialLayerIndexPlus1*

Picture spatial layer index plus one of the previously encoded frame now used as reference.

*FrameType*

The type of frame used to encode the described reference frame associated to this entry.

*WarpedMotionInfo*

Global motion params. Only used if supported in D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_FLAGS.

*OrderHint*

The reference _ref_order_hint_ AV1 syntax. Even when reference order hints are not coded in the AV1 bitstream, *OrderHint* here must be set to the value used in D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA.OrderHint for the previously encoded frame that is now being held as reference by this descriptor.
This information will hint the driver, in a frame type that allows frame references, which are from past frames and which are from future frames (in display order) when comparing against the current frame value of D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA.OrderHint.

*PictureIndex*

The unique picture index of the previously encoded frame that is stored in this entry as a reference. This parameter is not related in any way to the AV1 standard syntax, but merely used for API client implementation tracking instead.

### 4.1.3. ENUM: D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAGS

```C++
typedef enum D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAGS
{
    D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_NONE = 0x0,
    D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_ERROR_RESILIENT_MODE = 0x1,
    D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_DISABLE_CDF_UPDATE = 0x2,
    D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_PALETTE_ENCODING = 0x4, 
    D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_SKIP_MODE = 0x8,
    D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_FRAME_REFERENCE_MOTION_VECTORS = 0x10,
    D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_FORCE_INTEGER_MOTION_VECTORS = 0x20,
    D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ALLOW_INTRA_BLOCK_COPY = 0x40,
    D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_USE_SUPER_RESOLUTION = 0x80,
    D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_DISABLE_FRAME_END_UPDATE_CDF = 0x100,
    D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_FRAME_SEGMENTATION_AUTO = 0x200,
    D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_FRAME_SEGMENTATION_CUSTOM = 0x400,
    D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_WARPED_MOTION  = 0x800,
    D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_REDUCED_TX_SET = 0x1000,
    D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_MOTION_MODE_SWITCHABLE = 0x2000,
    D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ALLOW_HIGH_PRECISION_MV = 0x4000,
} D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAGS;
```

Defines the set of flags for the codec-specific picture control properties.

**Constants**

*D3D12_VIDEO_ENCODER_PICTURE_CONTROL_FLAG_NONE*

No flags

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_ERROR_RESILIENT_MODE*

Related to error_resilient_mode AV1 syntax in frame header.

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_DISABLE_CDF_UPDATE*

Related to AV1 syntax for disable_cdf_update.

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_PALETTE_ENCODING*

Enables the usage of palette encoding for this frame. 

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_SKIP_MODE*

Related to AV1 syntax skip_mode_present. skip_mode element will be present for this frame if this flag is set. Please check support in AV1 query caps before enabling this feature.

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_FRAME_REFERENCE_MOTION_VECTORS*

Related to AV1 syntax use_ref_frame_mvs. Equal to 1 specifies that motion vector information from a previous frame can be used when encoding the current frame. use_ref_frame_mvs equal to 0 specifies that this information will not be used.

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_FORCE_INTEGER_MOTION_VECTORS*

Equal to 1 specifies that force_integer_mv may be enabled on a per frame basis. Equal to 0 specifies that force_integer_mv syntax element will not be used. Please check support in AV1 query caps before enabling this feature.

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ALLOW_INTRA_BLOCK_COPY*

Indicates if intra block copy is supported or not at per frame basis. Related to allow_intrabc syntax in AV1 spec. 

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_USE_SUPER_RESOLUTION*

Related to AV1 syntax use_superres.

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_DISABLE_FRAME_END_UPDATE_CDF*

Related to AV1 syntax disable_frame_end_update_cdf.

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_FRAME_SEGMENTATION_AUTO*

Enables automatic (performed by driver without API Client input) segmentation for the current frame.
Requires D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_AUTO_SEGMENTATION.
This flag must *not* be combined with D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_FRAME_SEGMENTATION_CUSTOM.

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_FRAME_SEGMENTATION_CUSTOM*

Enables customized segmentation with the API Client sending the driver segmentation config and segment map.
Requires D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_CUSTOM_SEGMENTATION.
This flag must *not* be combined with D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_FRAME_SEGMENTATION_AUTO.

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_WARPED_MOTION*

Related to AV1 syntax _allow_warped_motion_ to be coded in the frame header. Requires D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_WARPED_MOTION.

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_REDUCED_TX_SET*

Related to AV1 syntax _reduced_tx_set_. Requires D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_REDUCED_TX_SET.
 
*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_MOTION_MODE_SWITCHABLE*

Related to AV1 syntax _is_motion_mode_switchable_. Requires D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_MOTION_MODE_SWITCHABLE.

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ALLOW_HIGH_PRECISION_MV*

Related to AV1 syntax _allow_high_precision_mv_. Requires D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_ALLOW_HIGH_PRECISION_MV.

### 4.1.4. STRUCT: D3D12_VIDEO_ENCODER_AV1_RESTORATION_CONFIG
```C++
typedef struct D3D12_VIDEO_ENCODER_AV1_RESTORATION_CONFIG {
    D3D12_VIDEO_ENCODER_AV1_RESTORATION_TYPE FrameRestorationType[3];
    D3D12_VIDEO_ENCODER_AV1_RESTORATION_TILESIZE LoopRestorationPixelSize[3];
} D3D12_VIDEO_ENCODER_AV1_RESTORATION_CONFIG;
```

**Remarks**

Related to AV1 syntax lr_params(). The array entries correspond to Y, U, V planes.

### 4.1.5. STRUCT: D3D12_VIDEO_ENCODER_AV1_SEGMENT_DATA
```C++
// 64bit aligned access for SetPredication as part of resolved metadata memory layout
typedef struct D3D12_VIDEO_ENCODER_AV1_SEGMENT_DATA {
    UINT64 EnabledFeatures;
    INT64 FeatureValue[8];
} D3D12_VIDEO_ENCODER_AV1_SEGMENT_DATA;
```

**Members**

*EnabledFeatures*

Accepts a bit mask combination of values from D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_FLAGS.

*FeatureValue*

For the enabled bit flags features in EnabledFeatures, the array FeatureValue is indexed by D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE - 1 for it's associated feature value.

### 4.1.6. STRUCT: D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_CONFIG
```C++
// 64bit aligned access for SetPredication as part of resolved metadata memory layout
typedef struct D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_CONFIG {
    UINT64 UpdateMap;
    UINT64 TemporalUpdate;
    UINT64 UpdateData;
    UINT64 NumSegments;
    D3D12_VIDEO_ENCODER_AV1_SEGMENT_DATA SegmentsData[8];
} D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_CONFIG;
```

Related to AV1 syntax segmentation_params()

*NumSegments*

When using D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_FRAME_SEGMENTATION_AUTO and the driver writes it back on post encode values, NumSegments = 0 indicated that segmentation_enabled must be 0 in the frame header. Otherwise, the API client codes segmentation_params() in the frame header accordingly with the other parameters in this structure.

When using D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_FRAME_SEGMENTATION_CUSTOM, indicates the input number of segments.

### 4.1.7. STRUCT: D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MAP
```C++
typedef struct D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MAP {
    UINT SegmentsMapByteSize;
    UINT8* pSegmentsMap;
} D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MAP;
```

**Members**

*SegmentsMapByteSize*

Byte size of pSegmentsMap buffer.

*pSegmentsMap*

In raster order, contains the AV1 syntax segment_id between [0..7] for each block in the frame.
The block size is SegmentationBlockSize as reported by driver in D3D12_VIDEO_ENCODER_AV1_CODEC_CONFIGURATION_SUPPORT.

### 4.1.8. STRUCT: D3D12_VIDEO_ENCODER_CODEC_AV1_LOOP_FILTER_CONFIG
```C++
// 64bit aligned access for SetPredication as part of resolved metadata memory layout
typedef struct D3D12_VIDEO_ENCODER_CODEC_AV1_LOOP_FILTER_CONFIG {
    UINT64 LoopFilterLevel[2];
    UINT64 LoopFilterLevelU;
    UINT64 LoopFilterLevelV;
    UINT64 LoopFilterSharpnessLevel;
    UINT64 LoopFilterDeltaEnabled;
    UINT64 UpdateRefDelta;
    INT64 RefDeltas[8];
    UINT64 UpdateModeDelta;
    INT64 ModeDeltas[2];
} D3D12_VIDEO_ENCODER_CODEC_AV1_LOOP_FILTER_CONFIG;
```

Related to AV1 syntax loop_filter_params().

**Remarks**

AV1 syntax loop_filter_delta_update is derived from members as (UpdateRefDelta || UpdateModeDelta).

**Members**

*LoopFilterLevel*

Related to AV1 syntax loop_filter_level[0], loop_filter_level[1]

*LoopFilterLevelU*

Related to AV1 syntax loop_filter_level[2]

*LoopFilterLevelV*

Related to AV1 syntax loop_filter_level[3]

*LoopFilterSharpnessLevel*

Related to AV1 syntax loop_filter_sharpness

*LoopFilterDeltaEnabled*

Related to AV1 syntax loop_filter_delta_enabled. Requires D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_LOOP_FILTER_DELTAS supported/enabled.

*UpdateRefDelta*

Bitmask related to AV1 syntax update_ref_delta. The i-th bit is associated with the `RefDeltas[i]` entry with i in range [0..7].

*RefDeltas*

Related to AV1 syntax loop_filter_ref_deltas.

*UpdateModeDelta*

Bitmask related to AV1 syntax update_mode_delta. The i-th bit is associated with the `ModeDeltas[i]` entry with i in range [0..1].

*ModeDeltas*

Related to AV1 syntax loop_filter_mode_deltas

### 4.1.9. STRUCT: D3D12_VIDEO_ENCODER_CODEC_AV1_LOOP_FILTER_DELTA_CONFIG
```C++
// 64bit aligned access for SetPredication as part of resolved metadata memory layout
typedef struct D3D12_VIDEO_ENCODER_CODEC_AV1_LOOP_FILTER_DELTA_CONFIG {
    UINT64 DeltaLFPresent;
    UINT64 DeltaLFMulti;
    UINT64 DeltaLFRes;
} D3D12_VIDEO_ENCODER_CODEC_AV1_LOOP_FILTER_DELTA_CONFIG;
```

Related to AV1 syntax delta_lf_params().

**Members**

*DeltaLFPresent*

Related to AV1 syntax delta_lf_params(). Requires D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_DELTA_LF_PARAMS supported/enabled.

*DeltaLFMulti*

Related to AV1 syntax delta_lf_params()

*DeltaLFRes*

Related to AV1 syntax delta_lf_params()


### 4.1.10. STRUCT: D3D12_VIDEO_ENCODER_CODEC_AV1_QUANTIZATION_CONFIG
```C++
// 64bit aligned access for SetPredication as part of resolved metadata memory layout
typedef struct D3D12_VIDEO_ENCODER_CODEC_AV1_QUANTIZATION_CONFIG {
    UINT64 BaseQIndex;
    INT64 YDCDeltaQ;
    INT64 UDCDeltaQ;
    INT64 UACDeltaQ;
    INT64 VDCDeltaQ;
    INT64 VACDeltaQ;
    UINT64 UsingQMatrix;
    UINT64 QMY;
    UINT64 QMU;
    UINT64 QMV;
} D3D12_VIDEO_ENCODER_CODEC_AV1_QUANTIZATION_CONFIG;
```

**Remarks**

* AV1 syntax separate_uv_delta_q will be coded as 1 always
* AV1 syntax diff_uv_delta can be inferred from below if U and V AC/DC components are the same.

**Members**

*BaseQIndex*

Related to AV1 syntax in quantization_params().

*YDCDeltaQ*

Related to AV1 syntax in quantization_params().

*UDCDeltaQ*

Related to AV1 syntax in quantization_params().

*UACDeltaQ*

Related to AV1 syntax in quantization_params().

*VDCDeltaQ*

Related to AV1 syntax in quantization_params().

*VACDeltaQ*

Related to AV1 syntax in quantization_params().

*UsingQMatrix*

Related to AV1 syntax in quantization_params().

*QMY*

Related to AV1 syntax in quantization_params().

*QMU*

Related to AV1 syntax in quantization_params().

*QMV*

Related to AV1 syntax in quantization_params().

### 4.1.11. STRUCT: D3D12_VIDEO_ENCODER_CODEC_AV1_QUANTIZATION_DELTA_CONFIG
```C++
// 64bit aligned access for SetPredication as part of resolved metadata memory layout
typedef struct D3D12_VIDEO_ENCODER_CODEC_AV1_QUANTIZATION_DELTA_CONFIG {
    UINT64 DeltaQPresent;
    UINT64 DeltaQRes;
} D3D12_VIDEO_ENCODER_CODEC_AV1_QUANTIZATION_DELTA_CONFIG;
```
**Members**

*DeltaQPresent*

Related to AV1 syntax in delta_q_params().

*DeltaQRes*

Related to AV1 syntax in delta_q_params().

### 4.1.12. STRUCT: D3D12_VIDEO_ENCODER_AV1_CDEF_CONFIG
```C++
// 64bit aligned access for SetPredication as part of resolved metadata memory layout
typedef struct D3D12_VIDEO_ENCODER_AV1_CDEF_CONFIG {
    UINT64 CdefBits;
    UINT64 CdefDampingMinus3;
    UINT64 CdefYPriStrength[8];
    UINT64 CdefUVPriStrength[8];
    UINT64 CdefYSecStrength[8];
    UINT64 CdefUVSecStrength[8];
} D3D12_VIDEO_ENCODER_AV1_CDEF_CONFIG;
```

**Members**

*CdefBits*

Related to AV1 syntax in cdef_params().

*CdefDampingMinus3*

Related to AV1 syntax in cdef_params().

*CdefYPriStrength*

Related to AV1 syntax in cdef_params().

*CdefUVPriStrength*

Related to AV1 syntax in cdef_params().

*CdefYSecStrength*

Related to AV1 syntax in cdef_params().

*CdefUVSecStrength*

Related to AV1 syntax in cdef_params().

### 4.1.13. STRUCT: D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA

```C++
#define D3D12_VIDEO_ENCODER_AV1_SUPERRES_DENOM_MIN 9

typedef struct D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA
{
    D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAGS Flags;
    D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE FrameType;
    D3D12_VIDEO_ENCODER_AV1_COMP_PREDICTION_TYPE CompoundPredictionType;
    D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS InterpolationFilter;
    D3D12_VIDEO_ENCODER_AV1_RESTORATION_CONFIG FrameRestorationConfig;
    D3D12_VIDEO_ENCODER_AV1_TX_MODE TxMode;
    UINT SuperResDenominator;
    UINT OrderHint;
    UINT PictureIndex;
    UINT TemporalLayerIndexPlus1;
    UINT SpatialLayerIndexPlus1;
    D3D12_VIDEO_ENCODER_AV1_REFERENCE_PICTURE_DESCRIPTOR ReferenceFramesReconPictureDescriptors[8];
    UINT ReferenceIndices[7];
    UINT PrimaryRefFrame;
    UINT RefreshFrameFlags;
    D3D12_VIDEO_ENCODER_CODEC_AV1_LOOP_FILTER_CONFIG LoopFilter;
    D3D12_VIDEO_ENCODER_CODEC_AV1_LOOP_FILTER_DELTA_CONFIG LoopFilterDelta;
    D3D12_VIDEO_ENCODER_CODEC_AV1_QUANTIZATION_CONFIG Quantization;
    D3D12_VIDEO_ENCODER_CODEC_AV1_QUANTIZATION_DELTA_CONFIG QuantizationDelta;
    D3D12_VIDEO_ENCODER_AV1_CDEF_CONFIG CDEF;
    UINT QPMapValuesCount;
    [annotation("_Field_size_full_(QPMapValuesCount)")] INT16 *pRateControlQPMap;
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_CONFIG CustomSegmentation;
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MAP SegmentsMap;
} D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA;
```

**Constants**

*D3D12_VIDEO_ENCODER_AV1_SUPERRES_DENOM_MIN*

As defined by the AV1 codec standard. Associated to SuperResDenominator param below.

**Members**

*Flags*

Configuration flags for this frame to be encoded.

*FrameType*

Sets the picture type. See D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE values.

*CompoundPredictionType*

Specifies whether single or compound prediction is used for the given frame.
Related to AV1 syntax _reference_select_.

*InterpolationFilter*

InterpolationFilter to be used for inter prediction on the current frame, related to syntax interpolation_filter.

*FrameRestorationConfig*

Indicates the restoration config to be used.

*InterIntraConfig*

Indicates the configuration for inter intra.

*FilterIntraMode*

Indicates the configuration for filter intra.

*MotionMode*

Indicates the configuration for motion mode.

*CompoundTypeConfig*

Indicates the configuration for compound config.

*SuperResDenominator*

Indicates the configuration for super resolution. Has to be greater or equal than D3D12_VIDEO_ENCODER_AV1_SUPERRES_DENOM_MIN when super resolution is enabled.

*OrderHint*

Current frame _order_hint_ AV1 syntax. For this API purposes, *OrderHint* must be always passed even when not coding the order hint in the AV1 bitstream, and it must reflect the display order of the frame.

*PictureIndex*

The unique picture index for this frame that will be used to uniquely identify it as a reference for future frames. This parameter is not related in any way to the AV1 standard syntax, but merely used for API client implementation tracking instead.

API Client should initialize this value at 0 for the first *D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_KEY_FRAME* and increment it by one on each subsequent frame until the next *D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_KEY_FRAME*, when it should be reset to zero and follow the same process.

Note: OrderHint cannot be used for this purpose as it has a max range of [0..2^(OrderHintBitsMinus1+1)], which can wrap around and not work as unique identifier of the frames and their references.

*TemporalLayerIndexPlus1*

Picture temporal layer index plus one. A value of zero indicates temporal scalability not used.
This value must be within the range [0..D3D12_VIDEO_ENCODER_AV1_CODEC_CONFIGURATION_SUPPORT.MaxTemporalLayers].

*SpatialLayerIndexPlus1*

Picture spatial layer index plus one. A value of zero indicates spatial scalability not used.
This value must be within the range [0..D3D12_VIDEO_ENCODER_AV1_CODEC_CONFIGURATION_SUPPORT.MaxSpatialLayers].

*ReferenceFramesReconPictureDescriptors*

Describes the current state snapshot of the **complete** (ie. including frames that are not used by current frame but used by future frames, etc) DPB buffer kept in D3D12_VIDEO_ENCODER_PICTURE_CONTROL_DESC.ReferenceFrames. The reference indices (ie. last, altref, etc) map from past/future references into this descriptors array. The AV1 codec allows up to 8 references in the DPB.

This array of descriptors, in turn, maps a reference picture for this frame into a resource index in the reconstructed pictures array D3D12_VIDEO_ENCODER_PICTURE_CONTROL_DESC.ReferenceFrames.

The size of this array always matches D3D12_VIDEO_ENCODER_PICTURE_CONTROL_DESC.ReferenceFrames.NumTextures for the associated EncodeFrame command.

*ReferenceIndices*

Corresponds to the *ref_frame_idx[i]* AV1 syntax. For a reference type *i*, ReferenceIndices[i] indicates an index between [0..7] into *ReferenceFramesReconPictureDescriptors* where the current frame i-th reference type is stored in the DPB. In other words *ReferenceFramesReconPictureDescriptors[ReferenceIndices[i]]* contains the DPB descriptor for the i-th reference type.

The i-th entry of ReferenceIndices[] corresponds to each reference type as follows:

| Index i | Reference type | ReferenceFramesReconPictureDescriptors[ReferenceIndices[i]] |
|-----------|------------|------------|
| 0 | Last | DPB Descriptor for Last |
| 1 | Last2 | DPB Descriptor for Last2 |
| 2 | Last3 | DPB Descriptor for Last3 |
| 3 | Golden | DPB Descriptor for Golden |
| 4 | Bwdref | DPB Descriptor for Bwdref |
| 5 | Altref | DPB Descriptor for Altref |
| 6 | Altref2 | DPB Descriptor for Altref2 |

*PrimaryRefFrame*

Corresponds to the AV1 element syntax _primary_ref_frame_ in _uncompressed_header()_. Specifies which reference frame contains the CDF values and other state that must be loaded at the start of the frame. The allowed range is [0..7] and the values corresponds as follows:

| PrimaryRefFrame value | AV1 syntax value (primary_ref_frame) | Reference frame selected |
|--------|------------|------------|
| 0 | 0 | Last |
| 1 | 1 | Last2 |
| 2 | 2 | Last3 |
| 3 | 3 | Golden |
| 4 | 4 | Bwdref |
| 5 | 5 | Altref |
| 6 | 6 | Altref2 |
| 7 | 7 (PRIMARY_REF_NONE) | None |

*RefreshFrameFlags*

Corresponds to the *refresh_frame_flags* AV1 syntax element.

*QPMapValuesCount*

Contains the number of elements present in QPMapValuesCount. This must match the number of coding blocks in the frame, rounding up the frame resolution to the closest aligned values.

*LoopFilter*

Specifies the loop filter parameters.

*LoopFilterDelta*

Specifies the loop filter delta parameters. Related to _delta_lf_params_ AV1 syntax.

*Quantization*

Specifies the quantization parameters.

*QuantizationDelta*

Specifies the quantization delta parameters.

*CDEF*

Specifies the constrained directional enhancement filtering parameters.

*pRateControlQPMap*

Array containing in row/column scan order, the QP map values to use on each squared region for this frame.
The QP map dimensions can be calculated using the current resolution and D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS.QPMapRegionPixelsSize conveying the squared region sizes.
The range for Delta QP values is [-255;255].

*CustomSegmentation*

Only used when D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_FRAME_SEGMENTATION_CUSTOM is set for current frame.

*SegmentsMap*

Only used when D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_FRAME_SEGMENTATION_CUSTOM is set for current frame.
Segment map to be used if CustomSegmentation.UpdateMap is set. Otherwise, the segment map is inherited from ref frame.

**Remarks**

*DPB Management expectations*

The following is the contract the API client and the driver must conform to when using this API:

1. When encoding D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_KEY_FRAME:

    - PrimaryRefFrame must be 7 (PRIMARY_REF_NONE)

    - RefreshFrameFlags must be 0xFF (conforming to the AV1 codec standard bitstream syntax)

    - For all array entries in *ReferenceFramesReconPictureDescriptors*, *ReconstructedPictureResourceIndex* must be set to *D3D12_VIDEO_ENCODER_AV1_INVALID_DPB_RESOURCE_INDEX*

    - The values in *ReferenceIndices[7]* are indistinct as any value [0..7] will point to an unused DPB slot in *ReferenceFramesReconPictureDescriptors* as per the point above.

    - D3D12_VIDEO_ENCODE_REFERENCE_FRAMES will be filled as:

        - NumTexture2Ds = 0

        - ppTexture2Ds = NULL

        - pSubresources = NULL

2. When encoding a frame type with references (ie. SWITCH/INTER):

    - PrimaryRefFrame specifies which reference frame contains the CDF values and other state that must be loaded at the start of the frame.

    - RefreshFrameFlags must be set accordingly to indicate on which *ReferenceFramesReconPictureDescriptors* DPB slots the current encoded frame reconstructed picture will be placed after encoding execution. This value must match exactly what the API client will code for *refresh_frame_flags* AV1 syntax element in the associated picture header for the current frame.

    - The array entries in *ReferenceFramesReconPictureDescriptors* for the current frame will follow exactly what *RefreshFrameFlags* indicated for the previous frame. 

        - For example: if *RefreshFrameFlags* indicates the current frame N will be placed in slots 2, 3 and 6, then in the next *EncodeFrame* call for frame N+1, the *ReconstructedPictureResourceIndex* parameter in the entries *ReferenceFramesReconPictureDescriptors[1]*, *ReferenceFramesReconPictureDescriptors[2]*, *ReferenceFramesReconPictureDescriptors[5]* param must point to frame N reconstructed picture in *D3D12_VIDEO_ENCODE_REFERENCE_FRAMES*.
        - Note this includes considering RefreshFrameFlags=0xFF for *D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_KEY_FRAME* as well, by marking all ReferenceFramesReconPictureDescriptors entries pointing to the KEY frame reconstructed picture.
        - If a (non key frame) picture won't be marked with D3D12_VIDEO_ENCODER_PICTURE_CONTROL_FLAG_USED_AS_REFERENCE_PICTURE, their RefreshFrameFlags must be zero to indicate this.

    - The values in *ReferenceIndices[7]* are within [0..7] and point to DPB slots in *ReferenceFramesReconPictureDescriptors*.
        - The values of ReferenceIndices[7] must match exactly what the API client codes in the picture header for *ref_frame_idx*.
        - As per AV1 syntax definition of *ref_frame_idx* there is **no requirement** that the array entry values must be unique.
        - If ReferenceFramesReconPictureDescriptors[ReferenceIndices[i]].
        ReconstructedPictureResourceIndex == D3D12_VIDEO_ENCODER_AV1_INVALID_DPB_RESOURCE_INDEX
            - This indicates the reference picture i-th won't be used for the current frame and must be ignored.
        - Otherwise (Valid ReferenceFramesReconPictureDescriptors[ReferenceIndices[i]].
        ReconstructedPictureResourceIndex)
            - This indicates the reference i-th will point to the DPB slot *ReferenceIndices[i]* and the reconstructed picture to be used is **D3D12_VIDEO_ENCODE_REFERENCE_FRAMES.ppTexture2Ds[ReferenceFramesReconPictureDescriptors[ReferenceIndices[i]].ReconstructedPictureResourceIndex]**

    - D3D12_VIDEO_ENCODE_REFERENCE_FRAMES will be filled as:

        - NumTexture2Ds = {number of **unique** values of *ReferenceFramesReconPictureDescriptors.ReconstructedPictureResourceIndex[j] != D3D12_VIDEO_ENCODER_AV1_INVALID_DPB_RESOURCE_INDEX* for j in {0..7} }

        - ppTexture2Ds = { compact array (no null entries) containing the reconstructed picture from the previously encoded frames that will be used as references }

        - [Texture Array mode only] pSubresources = { compact array (no null entries) containing the subresource index of the texture array from the previously encoded frames that will be used as references }

3. When encoding a frame type without references but without clearing the DPB (ie. INTRA_ONLY)

    - PrimaryRefFrame must be 7 (PRIMARY_REF_NONE)

    - RefreshFrameFlags must be set accordingly to indicate on which *ReferenceFramesReconPictureDescriptors* DPB slots the current encoded frame reconstructed picture will be placed after encoding execution. This value must match exactly what the API client will code for *refresh_frame_flags* AV1 syntax element in the associated picture header for the current frame.

    - The array entries in *ReferenceFramesReconPictureDescriptors* for the current frame will follow exactly what *RefreshFrameFlags* indicated for the previous frame. 

    - The values in *ReferenceIndices[7]* are ignored as the intra-only frame doesn't use any references.

    - D3D12_VIDEO_ENCODE_REFERENCE_FRAMES contains the DPB snapshot and will be filled as:

        - NumTexture2Ds = {number of **unique** values of *ReferenceFramesReconPictureDescriptors.ReconstructedPictureResourceIndex[j] != D3D12_VIDEO_ENCODER_AV1_INVALID_DPB_RESOURCE_INDEX* for j in {0..7} }

        - ppTexture2Ds = { compact array (no null entries) containing the reconstructed picture from the previously encoded frames referred to by ReferenceFramesReconPictureDescriptors.ReconstructedPictureResourceIndex[j] for j in {0..7} }

        - [Texture Array mode only] pSubresources = { compact array (no null entries) containing the subresource index of the texture array from the previously encoded frames referred to by ReferenceFramesReconPictureDescriptors.ReconstructedPictureResourceIndex[j] for j in {0..7} }

### 4.1.14. UNION: D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA

```C++
typedef struct D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA
{
    UINT DataSize;
    union
    {
        ...
        D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA* pAV1PicData;
    };
} D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA;
```

### 4.1.15. STRUCT: D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_SUBREGIONS_LAYOUT_DATA_TILES

```C++
constexpr UINT MAX_TILE_ROWS = 64u;
constexpr UINT MAX_TILE_COLS = 64u;

// 64bit aligned access for SetPredication as part of resolved metadata memory layout
typedef struct D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_SUBREGIONS_LAYOUT_DATA_TILES
{
    UINT64 RowCount;
    UINT64 ColCount;
    UINT64 RowHeights[MAX_TILE_ROWS];
    UINT64 ColWidths[MAX_TILE_COLS];
    UINT64 ContextUpdateTileId;
} D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_SUBREGIONS_LAYOUT_DATA_TILES;
```

**Remarks**

This operates in different ways using different D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE configurations.

For D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE_CONFIGURABLE_GRID_PARTITION,

* Input parameters: RowCount, ColCount, RowHeights, ColWidths within the reported tile caps. The integer values must match the AV1 codec standard expectations (ie. power of two, etc).
* Driver honors exactly and copies the exact same structure after EncodeFrame execution. 

For D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE_UNIFORM_GRID_PARTITION
* Input parameters: RowCount, ColCount. The integer values must match the AV1 codec standard expectations (ie. power of two, etc).
* Driver copies RowCount/ColCount as passed by API Client, and returns also RowHeights, ColWidths after EncodeFrame execution.

For ContextUpdateTileId, is an input parameter from the API Client corresponding to the frame header context_update_tile_id AV1 syntax and if D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_CONTEXT_UPDATE_TILE_ID was reported then the driver is able to overwrite the API client input after EncodeFrame execution, otherwise must be copied by the driver from the input to the post encode values.

**Constants**

*MAX_TILE_ROWS*

As defined in the AV1 codec standard.

*MAX_TILE_COLS*

As defined in the AV1 codec standard.

**Members**

*RowCount*

Number of tile rows.

*ColCount*

Number of tile cols.

*RowHeights*

Heights of tile rows.

*ColWidths*

Widths of tile cols.

*ContextUpdateTileId*

Related to AV1 syntax context_update_tile_id.

**Remarks**

    Please check the limitations for tile configuration returned in D3D12_FEATURE_DATA_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_CONFIG for AV1 codec.

    For the width and height parameter lists, please make sure they fall under the codec standard defined dimension limitations specified above. The units of these arrays are measured in block of size D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS.SubregionBlockPixelsSize. For example if ColHeights[0] = 2 and SubregionBlockPixelsSize = 64,
    then the ColHeightInPixels[0] = ColHeights[0] * SubregionBlockPixelsSize = 2 * 64 = 128.

### 4.1.16. UNION: D3D12_VIDEO_ENCODER_PICTURE_CONTROL_SUBREGIONS_LAYOUT_DATA

```C++
typedef struct D3D12_VIDEO_ENCODER_PICTURE_CONTROL_SUBREGIONS_LAYOUT_DATA
{
    UINT DataSize;
    union
    {
        ...
        const D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_SUBREGIONS_LAYOUT_DATA_TILES* pTilesPartition_AV1;
    };
    
} D3D12_VIDEO_ENCODER_PICTURE_CONTROL_SUBREGIONS_LAYOUT_DATA;
```

### 4.1.17. STRUCT: D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES

```C++
typedef struct D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES
{
    D3D12_VIDEO_ENCODER_AV1_COMP_PREDICTION_TYPE CompoundPredictionType;
    D3D12_VIDEO_ENCODER_CODEC_AV1_LOOP_FILTER_CONFIG LoopFilter;
    D3D12_VIDEO_ENCODER_CODEC_AV1_LOOP_FILTER_DELTA_CONFIG LoopFilterDelta;
    D3D12_VIDEO_ENCODER_CODEC_AV1_QUANTIZATION_CONFIG Quantization;
    D3D12_VIDEO_ENCODER_CODEC_AV1_QUANTIZATION_DELTA_CONFIG QuantizationDelta;
    D3D12_VIDEO_ENCODER_AV1_CDEF_CONFIG CDEF;
    D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_CONFIG SegmentationConfig;
    UINT64 PrimaryRefFrame; // Aligned to 64 for use of post encode metadata with predication
    UINT64 ReferenceIndices[7]; // Aligned to 64 for use of post encode metadata with predication
} D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES;
```

**Remarks**

If D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAGS was reported for the respective structures, driver must write the values after EncodeFrame execution with or without modifications (copy API client input) done by the driver.
Otherwise, driver must copy the values from the associated API Client input when calling EncodeFrame.

**Members**

*CompoundPredictionType*

Associated flag is D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_COMPOUND_PREDICTION_MODE.

*LoopFilter*

Associated flag is D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_LOOP_FILTER.

*LoopFilterDelta*

Associated flag is D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_LOOP_FILTER_DELTA.

*Quantization*

Associated flag is D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_QUANTIZATION.

*QuantizationDelta*

Associated flag is D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_QUANTIZATION_DELTA.

*CDEF*

Associated flag is D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_CDEF_DATA.

*SegmentationConfig*

This operates in different modes depending the segmentation mode selected.

* D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_FRAME_SEGMENTATION_AUTO is on for current frame
    * Driver will calculate and write SegmentationConfig which will be used by the API Client to code the segmentation_params() syntax in the frame header.
    * Driver will calculate and write the read_segment_id() map information directly in the compressed bitstream
* D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_FRAME_SEGMENTATION_CUSTOM is on for current frame
    * Driver will copy here the SegmentationConfig sent by the API Client in the encode frame parameters for API Client to code the segmentation_params() syntax in the frame header.
    * Driver will copy the read_segment_id() map sent by the API Client in the encode frame parameters directly in the compressed bitstream
* Otherwise (both segmentation modes are off)
    * Driver should write all zeroes
    * API Client will write segmentation_enabled = 0 accordingly in the segmentation_params() section of the frame header

*PrimaryRefFrame*

Associated flag is D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_PRIMARY_REF_FRAME. If the flag was set, the driver controls the selection of the primary reference frame from which the segment id map, CDF, etc are inherited from.

When used together with D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_AUTO_SEGMENTATION, allows the driver to force a value **other than** _PRIMARY_REF_NONE_ when applicable, giving the driver full control of the AV1 syntax: _segmentation_update_map_, _segmentation_temporal_update_ and _segmentation_update_data_ in _segmentation_params()_.

*ReferenceIndices*

When the flag is reported, the driver may reorder/remap (but not change the number of references) the ReferenceIndices array, based on the user input D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA.ReferenceIndices. Otherwise, driver must copy each array entry of this parameter as-is from D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA.ReferenceIndices.

API Client will write the picture header *ref_frame_idx* AV1 syntax from this output parameter.

### 4.1.18. METHOD: ID3D12VIDEOCOMMANDLIST2::ResolveEncoderOutputMetadata

```C++
    void ResolveEncoderOutputMetadata(
        [annotation("_In_")] const D3D12_VIDEO_ENCODER_RESOLVE_METADATA_INPUT_ARGUMENTS* pInputArguments,
        [annotation("_In_")] const D3D12_VIDEO_ENCODER_RESOLVE_METADATA_OUTPUT_ARGUMENTS* pOutputArguments);
```

Resolves the output metadata to a readable format. **Already present in existing Video Encode API.**

**Remarks**

    - The API Client must interpret the contents of pOutputArguments as a memory blob that contains the data as specified in the buffer layout defined for ResolveEncoderOutputMetadata below. All the information in the layout is positioned in memory contiguously. API Client will parse accordingly depending on the value of D3D12_VIDEO_ENCODER_RESOLVE_METADATA_INPUT_ARGUMENTS.EncodeCodec.
    - For D3D12_VIDEO_ENCODER_RESOLVE_METADATA_INPUT_ARGUMENTS.EncodeCodec equal to values supported before this extension to the API (ie. H264/HEVC) the resolved buffer memory layout will **not** be changed.
    - For D3D12_VIDEO_ENCODER_RESOLVE_METADATA_INPUT_ARGUMENTS.EncodeCodec == D3D12_VIDEO_ENCODER_CODEC_AV1, a new resolved buffer layout is defined below.

### **Resolved buffer layouts for ResolveEncoderOutputMetadata**

Please refer to [D3D12_Video_Encoding_Stats_Metadata](D3D12_Video_Encoding_Stats_Metadata.md) for additional resolved metadata layout data.

#### *For H264/HEVC codecs*

    - Same as existing ResolveEncoderOutputMetadata layout:
            - D3D12_VIDEO_ENCODER_OUTPUT_METADATA structure
            - WrittenSubregionsCount elements of type D3D12_VIDEO_ENCODER_FRAME_SUBREGION_METADATA indicating each tile in the same order they're written in the compressed output bitstream.

    - The maximum size of the resolved metadata buffer can be inferred by the H264/HEVC layout for ResolveEncoderOutputMetadata.

            maxSliceNumber = D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS.MaxSubregionsNumber (driver reported output);
            MaxEncoderOutputMetadataResolvedBufferSize = sizeof(D3D12_VIDEO_ENCODER_OUTPUT_METADATA) +
                        (maxSliceNumber * sizeof(D3D12_VIDEO_ENCODER_FRAME_SUBREGION_METADATA));

#### *For AV1 codec*

    - New memory layout defined as:
            - D3D12_VIDEO_ENCODER_OUTPUT_METADATA structure
            - WrittenSubregionsCount elements of type D3D12_VIDEO_ENCODER_FRAME_SUBREGION_METADATA indicating each tile in the same order they're written in the compressed output bitstream.
                - bSize = tile_size_minus_1 + 1 + bStartOffset
                - bStartOffset = Bytes to skip relative to this tile, the actual bitstream coded tile size is tile_size_minus_1 = (bSize - bStartOffset - 1).
                - bHeaderSize = 0
                - The i-th tile is read from the compressed_bitstream[offset] with  offset = D3D12_VIDEO_ENCODER_COMPRESSED_BITSTREAM.FrameStartOffset + [sum j = (0, (i-1)){ tile[j].bSize }] + tile[i].bStartOffset
            - D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_SUBREGIONS_LAYOUT_DATA_TILES structure indicating the encoded frame tile grid structure
            - D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES indicating encoding metadata values that are only obtained post-execution of EncodeFrame on the GPU.

    - The maximum size of the resolved metadata buffer can be inferred by the layout for AV1 in ResolveEncoderOutputMetadata.

        MaxTiles = D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS.MaxSubregionsNumber (driver reported output);
        MaxEncoderOutputMetadataResolvedBufferSize =
                sizeof(D3D12_VIDEO_ENCODER_OUTPUT_METADATA) +
                (MaxTiles * sizeof(D3D12_VIDEO_ENCODER_FRAME_SUBREGION_METADATA));
                + sizeof(D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_SUBREGIONS_LAYOUT_DATA_TILES)
                + sizeof(D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES)
