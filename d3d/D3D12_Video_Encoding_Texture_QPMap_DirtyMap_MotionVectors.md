# 1. D3D12 Video Encoding Quantization matrix, Dirty pixel, Motion Vectors

# 2. General considerations

This spec focuses on the points of extension where the existing D3D12 Video Encode API needs new structures for the new features, the rest of the D3D12 Encode API will remain unmodified for this feature unless explicited in this spec. The next sections detail the API and DDI for video encoding. In many cases, the DDI is extremely similar to the API. The structures and enumerations which are basically the same (differing solely in name convention) are not repeated in the this specification.

# 3.1 Video Encoding API

The general steps for using the new features would be:

*From inputs in CPU buffers:*

1. Call `CheckFeatureSupport` for the desired `D3D12_FEATURE_VIDEO_ENCODER_*` feature indicating `D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE_CPU_BUFFER`.
2. Use the new CPU inputs in `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_DESC1` for the desired feature. Please note QP Matrix uses the existing `pRateControlQPMap` CPU buffer in the picture parameters.

*From inputs in GPU textures:*

1. Call `CheckFeatureSupport` for the desired `D3D12_FEATURE_VIDEO_ENCODER_*` feature.
2. Call `CheckFeatureSupport` for `D3D12_FEATURE_VIDEO_ENCODER_RESOLVE_INPUT_PARAM_LAYOUT` with `D3D12_VIDEO_ENCODER_INPUT_MAP_TYPE` indicating the desired feature and allocate an `ID3D12Resource` buffer of size `D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLVE_INPUT_PARAM_LAYOUT.MaxResolvedBufferAllocationSize` to be used as the output of `ResolveInputParamLayout`.
3. Record an `ResolveInputParamLayout`, indicating the `D3D12_VIDEO_ENCODER_INPUT_MAP_TYPE` and filling its `D3D12_VIDEO_ENCODER_INPUT_MAP_DATA` with the input map textures. In the case of submitting all commands in the same command lists, `ResolveInputParamLayout` must be recorded before `EncodeFrame1`. If executing `ResolveInputParamLayout` from another queue, its execution must be sinifhed before any `EncodeFrame1` operation consumes the opaque buffer written by `ResolveInputParamLayout` and must be synchronized appropiately (e.g using fences between queues). 
4. Record an `EncodeFrame1` command and pass in the output buffer from `ResolveInputParamLayout` in the new GPU inputs in `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_DESC1` for the desired feature.

The following sections are ordered in the intended order of usage explained above.

## 3.1.1 Feature support

### ENUM: D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE

```C++
typedef enum D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE
{
    ...
    D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE_AUTO = 7,
} D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE;
```

**Constants**

*D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE_AUTO*

When this mode is used, the associated `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_SUBREGIONS_LAYOUT_DATA` passed along the subregions mode must be `NULL`.

The driver decides the subregion partitioning and communicates to the user in post-encode metadata. The subregion count can be between 1 and up to the driver reported `D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS.MaxSubregionsNumber`.
The driver reports the actual subregion count after encode execution in `D3D12_VIDEO_ENCODER_OUTPUT_METADATA.WrittenSubregionsCount`. For AV1 additionally, the driver reports the tile layout in `D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_SUBREGIONS_LAYOUT_DATA_TILES`.

In case the driver needs to take ownership of the subregion partitioning when used in combination with dirty regions or motion vector features, this mode can be used and the driver should report so in the query caps below for each of these features.

### ENUM:  D3D12_FEATURE_VIDEO

```C++
typedef enum D3D12_FEATURE_VIDEO
{
…
    D3D12_FEATURE_VIDEO_ENCODER_RESOLVE_INPUT_PARAM_LAYOUT = ...,
    D3D12_FEATURE_VIDEO_ENCODER_QPMAP_INPUT = ...,
    D3D12_FEATURE_VIDEO_ENCODER_DIRTY_REGIONS = ...,
    D3D12_FEATURE_VIDEO_ENCODER_MOTION_SEARCH = ...,
    D3D12_FEATURE_VIDEO_ENCODER_SUPPORT2 = ...,
} D3D12_FEATURE_VIDEO;
```

### STRUCT: D3D12_VIDEO_ENCODER_INPUT_MAP_SESSION_INFO

```C++
typedef struct D3D12_VIDEO_ENCODER_INPUT_MAP_SESSION_INFO
{
    D3D12_VIDEO_ENCODER_CODEC Codec;
    D3D12_VIDEO_ENCODER_PROFILE_DESC Profile;
    D3D12_VIDEO_ENCODER_LEVEL_SETTING Level;
    DXGI_FORMAT InputFormat;
    D3D12_VIDEO_ENCODER_PICTURE_RESOLUTION_DESC InputResolution;
    D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION CodecConfiguration;
    D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE SubregionFrameEncoding;
    D3D12_VIDEO_ENCODER_PICTURE_CONTROL_SUBREGIONS_LAYOUT_DATA SubregionFrameEncodingData;
} D3D12_VIDEO_ENCODER_INPUT_MAP_SESSION_INFO;
```

### ENUM: D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE

```C++
typedef enum D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE
{
    D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE_CPU_BUFFER = 0,
    D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE_GPU_TEXTURE = 1,
} D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE;
```

*D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE_CPU_BUFFER*

Indicates the input is a CPU structure/buffer.

*D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE_GPU_TEXTURE*

Indicates the input is a `ID3D12Resource` texture.

### STRUCT: D3D12_FEATURE_DATA_VIDEO_ENCODER_QPMAP_INPUT

```C++
// D3D12_FEATURE_VIDEO_ENCODER_QPMAP_INPUT
typedef struct D3D12_FEATURE_DATA_VIDEO_ENCODER_QPMAP_INPUT
{
    UINT NodeIndex;                                          // input
    D3D12_VIDEO_ENCODER_INPUT_MAP_SESSION_INFO SessionInfo;  // input
    D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE MapSource;          // input
    BOOL IsSupported;                                        // output
    UINT MapSourcePreferenceRanking;                         // output
    UINT BlockSize;                                          // output
} D3D12_FEATURE_DATA_VIDEO_ENCODER_QPMAP_INPUT;
```

*NodeIndex*

Input parameter, in multi-adapter operation, this indicates which physical adapter of the device this operation applies to.

*SessionInfo*

Input parameter, contains information pertaining to the encoding session.

*MapSource*

Input parameter, indicates to the driver which source does the user intends to use (e.g GPU/CPU input).

*IsSupported*

Output parameter, indicates if given value for feature is supported. When using `D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE_CPU_BUFFER`, the driver must be consistent in the reporting of `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_RATE_CONTROL_DELTA_QP_AVAILABLE` (existing flag for CPU buffer delta qp in per-codec picture params) in existing caps like `D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT` and `D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT1`. Please see `D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT2` section for more information as well.

*MapSourcePreferenceRanking*

Output parameter, indicates the driver preference (allowed output range [0..1]) for the input `MapSource` passed in. This is a hint to indicate the app in case of supporting multiple `MapSource` types, which ones may incur in bigger resolve/conversion performance hit so apps having the option to provide multiple sources can make an informed decision. In cases were there is no difference between `MapSource` inputs, driver can report both preference rankings as zero. The lowest the value reported, the best performance for this `MapSource` input type.

*BlockSize*

Output parameter, indicates the pixel size of the blocks. Note that when input is `D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE_CPU_BUFFER`, this must match with the driver reported `D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS.QPMapRegionPixelsSize` value in existing caps like `D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT` and `D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT1`. Please see `D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT2` section for more information as well.

### ENUM: D3D12_VIDEO_ENCODER_DIRTY_REGIONS_MAP_VALUES_MODE

```C++
typedef enum D3D12_VIDEO_ENCODER_DIRTY_REGIONS_MAP_VALUES_MODE
{
    D3D12_VIDEO_ENCODER_DIRTY_REGIONS_MAP_VALUES_MODE_DIRTY = 0,
    D3D12_VIDEO_ENCODER_DIRTY_REGIONS_MAP_VALUES_MODE_SKIP = 1,
} D3D12_VIDEO_ENCODER_DIRTY_REGIONS_MAP_VALUES_MODE;
```

*D3D12_VIDEO_ENCODER_DIRTY_REGIONS_MAP_VALUES_MODE_DIRTY*

Indicates if the pixel is different with value non-zero or identical with value zero.

When applied to `D3D12_VIDEO_ENCODER_DIRTY_RECT_INFO`, indicates the group of pixels inside the rect have this meaning.

*D3D12_VIDEO_ENCODER_DIRTY_REGIONS_MAP_VALUES_MODE_SKIP*

Indicates if the pixel is different with value zero or identical with value non-zero.

When applied to `D3D12_VIDEO_ENCODER_DIRTY_RECT_INFO`, indicates the group of pixels inside the rect have this meaning.

### ENUM: D3D12_VIDEO_ENCODER_DIRTY_REGIONS_SUPPORT_FLAGS

```C++
typedef enum D3D12_VIDEO_ENCODER_DIRTY_REGIONS_SUPPORT_FLAGS
{
    D3D12_VIDEO_ENCODER_DIRTY_REGIONS_SUPPORT_FLAG_NONE = 0x0,
    D3D12_VIDEO_ENCODER_DIRTY_REGIONS_SUPPORT_FLAG_REPEAT_FRAME = 0x1,
    D3D12_VIDEO_ENCODER_DIRTY_REGIONS_SUPPORT_FLAG_DIRTY_REGIONS = 0x2,
    D3D12_VIDEO_ENCODER_DIRTY_REGIONS_SUPPORT_FLAG_DIRTY_REGIONS_REQUIRE_FULL_ROW = 0x4,
} D3D12_VIDEO_ENCODER_DIRTY_REGIONS_SUPPORT_FLAGS;
```

*D3D12_VIDEO_ENCODER_DIRTY_REGIONS_SUPPORT_FLAG_NONE*

Indicates no support.

*D3D12_VIDEO_ENCODER_DIRTY_REGIONS_SUPPORT_FLAG_REPEAT_FRAME*

Indicates the driver supports setting `FullFrameIdentical = TRUE` (in `D3D12_VIDEO_ENCODER_DIRTY_RECT_INFO` or `D3D12_VIDEO_ENCODER_INPUT_MAP_DATA_DIRTY_REGIONS`)

    Note that for AV1, identical frames can be coded using `show_existing_frame` in `uncompressed_header` of `frame_header_obu`, which is coded by the app in D3D12 and hence no driver/hardware involvement is required.

    If the user were not to use this syntax, for consistency, drivers reporting D3D12_VIDEO_ENCODER_DIRTY_REGIONS_SUPPORT_FLAG_REPEAT_FRAME supported for AV1 must assume that when encoding frames with FullFrameIdentical = TRUE, all blocks in the frame can be considered `skip` respect to the indicated DPB reference.

*D3D12_VIDEO_ENCODER_DIRTY_REGIONS_SUPPORT_FLAG_DIRTY_REGIONS*

Indicates the driver supports setting `FullFrameIdentical = FALSE` (in `D3D12_VIDEO_ENCODER_DIRTY_RECT_INFO` or `D3D12_VIDEO_ENCODER_INPUT_MAP_DATA_DIRTY_REGIONS`)

*D3D12_VIDEO_ENCODER_DIRTY_REGIONS_SUPPORT_FLAG_DIRTY_REGIONS_REQUIRE_FULL_ROW*

Indicates that when the driver supports `D3D12_VIDEO_ENCODER_DIRTY_REGIONS_SUPPORT_FLAG_DIRTY_REGIONS`, the regions (either in CPU buffer rects or GPU texture map) passed by the app must be full rows.

### STRUCT: D3D12_FEATURE_DATA_ENCODER_DIRTY_REGIONS

```C++
// D3D12_FEATURE_ENCODER_DIRTY_REGIONS
typedef struct D3D12_FEATURE_DATA_ENCODER_DIRTY_REGIONS
{
    UINT NodeIndex;                                                   // input
    D3D12_VIDEO_ENCODER_INPUT_MAP_SESSION_INFO SessionInfo;           // input
    D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE MapSource;                   // input
    D3D12_VIDEO_ENCODER_DIRTY_REGIONS_MAP_VALUES_MODE MapValuesType;  // input
    D3D12_VIDEO_ENCODER_DIRTY_REGIONS_SUPPORT_FLAGS SupportFlags;     // output
    UINT MapSourcePreferenceRanking;                                  // output
} D3D12_FEATURE_DATA_ENCODER_DIRTY_REGIONS;
```

*NodeIndex*

Input parameter, in multi-adapter operation, this indicates which physical adapter of the device this operation applies to.

*SessionInfo*

Input parameter, contains information pertaining to the encoding session.

*MapSource*

Input parameter, indicates to the driver which source does the user intends to use (e.g GPU/CPU input).

*MapValuesType*

Input parameter, desired dirty region map type to check support for.

*SupportFlags*

Output parameter, indicates if given input params for feature are supported. Flags can be combined.

*MapSourcePreferenceRanking*

Output parameter, indicates the driver preference (allowed output range [0..1]) for the input `MapSource` passed in. This is a hint to indicate the app in case of supporting multiple `MapSource` types, which ones may incur in bigger resolve/conversion performance hit so apps having the option to provide multiple sources can make an informed decision. In cases were there is no difference between `MapSource` inputs, driver can report both preference rankings as zero. The lowest the value reported, the best performance for this `MapSource` input type.

### ENUM: D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE

```C++
typedef enum D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE
{
    D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE_FULL_SEARCH = 0,
    D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE_START_HINT = 1,
    D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE_START_HINT_LIMITED_DISTANCE = 2,
} D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE;
```

*D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE_FULL_SEARCH*

The driver will perform the full motion search. When `D3D12_VIDEO_ENCODER_INPUT_MAP_DATA_MOTION_VECTORS.NumHintsPerPixel > 0`, the motion vectors are just hints for the driver.

Requires `D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE_FULL_SEARCH` supported in `D3D12_FEATURE_DATA_VIDEO_ENCODER_MOTION_SEARCH`.

*D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE_START_HINT*

The driver will take the motion vectors input per pixel, convert them to the codec specific block partition, and use the input motion vectors as starting points in the motion search algorithm. Driver is allowed to perform additional motion search to fine-tune and optimize based on the input motion vector hints.

Requires `D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE_START_HINT` supported in `D3D12_FEATURE_DATA_VIDEO_ENCODER_MOTION_SEARCH`.

*D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE_START_HINT_LIMITED_DISTANCE*

The driver will take the motion vectors input per pixel, convert them to the codec specific block partition, and use the input motion vectors as starting points in the motion search algorithm. Driver is allowed to perform **limited** motion search to fine-tune and optimize based on the input motion vector hints, but the resulting new motion vectors from this additional search must not deviate more than `SearchDeviationLimit` **percent** in terms of euclidean vector distance, from the motion input vector.

When considering multiple input vectors from *the same reference picture*, located in a `[(x, y), (w, z)]` pixel box region in `ppMotionVectorMaps[i]` that will produce a single vector for a single motion search block, the driver must use the input vectors average directions and the newly calculated fine-tuned motion vectors (in this same pixel box region) average directions to enforce the distance limit.

When blocks will have multiple vectors (e.g from more than one reference frame), motion vectors from different reference frames are taken into account separately when averaging to enforce the distance limit.

Requires `D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE_START_HINT_LIMITED_DISTANCE` supported in `D3D12_FEATURE_DATA_VIDEO_ENCODER_MOTION_SEARCH`.

### ENUM: D3D12_VIDEO_ENCODER_FRAME_INPUT_MOTION_UNIT_PRECISION

```C++
typedef enum D3D12_VIDEO_ENCODER_FRAME_INPUT_MOTION_UNIT_PRECISION
{
    D3D12_VIDEO_ENCODER_FRAME_INPUT_MOTION_UNIT_PRECISION_FULL_PIXEL = 0,
    D3D12_VIDEO_ENCODER_FRAME_INPUT_MOTION_UNIT_PRECISION_HALF_PIXEL = 1,
    D3D12_VIDEO_ENCODER_FRAME_INPUT_MOTION_UNIT_PRECISION_QUARTER_PIXEL = 2,
} D3D12_VIDEO_ENCODER_FRAME_INPUT_MOTION_UNIT_PRECISION;
```

Defines the numerical unit used in input motion vector/rect values. For example `D3D12_VIDEO_ENCODER_FRAME_INPUT_MOTION_UNIT_PRECISION_FULL_PIXEL` indicates that a vector `(-2, 3)` must be taken as a -2 pixel shift in X axis and an 3 pixel shift in Y axis. Similarly for the same motion vector, for `D3D12_VIDEO_ENCODER_FRAME_INPUT_MOTION_UNIT_PRECISION_HALF_PIXEL` it indicates a -1 shift in X axis, and a 1.5 pixel shift in axis Y, and so on.

### STRUCT: D3D12_VIDEO_ENCODER_FRAME_INPUT_MOTION_UNIT_PRECISION_SUPPORT_FLAGS
```C++
typedef enum D3D12_VIDEO_ENCODER_FRAME_INPUT_MOTION_UNIT_PRECISION_SUPPORT_FLAGS {
    D3D12_VIDEO_ENCODER_FRAME_INPUT_MOTION_UNIT_PRECISION_SUPPORT_FLAG_NONE = 0x0,
    D3D12_VIDEO_ENCODER_FRAME_INPUT_MOTION_UNIT_PRECISION_SUPPORT_FLAG_FULL_PIXEL = (1 << D3D12_VIDEO_ENCODER_FRAME_INPUT_MOTION_UNIT_PRECISION_FULL_PIXEL),
    D3D12_VIDEO_ENCODER_FRAME_INPUT_MOTION_UNIT_PRECISION_SUPPORT_FLAG_HALF_PIXEL = (1 << D3D12_VIDEO_ENCODER_FRAME_INPUT_MOTION_UNIT_PRECISION_HALF_PIXEL),
    D3D12_VIDEO_ENCODER_FRAME_INPUT_MOTION_UNIT_PRECISION_SUPPORT_FLAG_QUARTER_PIXEL = (1 << D3D12_VIDEO_ENCODER_FRAME_INPUT_MOTION_UNIT_PRECISION_QUARTER_PIXEL),
} D3D12_VIDEO_ENCODER_FRAME_INPUT_MOTION_UNIT_PRECISION_SUPPORT_FLAGS;
```

Used for reporting support of different precision modes.

### ENUM: D3D12_VIDEO_ENCODER_MOTION_SEARCH_SUPPORT_FLAGS

```C++
typedef enum D3D12_VIDEO_ENCODER_MOTION_SEARCH_SUPPORT_FLAGS
{
    D3D12_VIDEO_ENCODER_MOTION_SEARCH_SUPPORT_FLAG_NONE = 0x0,
    D3D12_VIDEO_ENCODER_MOTION_SEARCH_SUPPORT_FLAG_SUPPORTED = 0x1,
    D3D12_VIDEO_ENCODER_MOTION_SEARCH_SUPPORT_FLAG_MULTIPLE_HINTS = 0x2,
    D3D12_VIDEO_ENCODER_MOTION_SEARCH_SUPPORT_FLAG_GPU_TEXTURE_MULTIPLE_REFERENCES = 0x4,
} D3D12_VIDEO_ENCODER_MOTION_SEARCH_SUPPORT_FLAGS;
```

*D3D12_VIDEO_ENCODER_MOTION_SEARCH_SUPPORT_FLAG_NONE*

Indicates no support for the given input parameters.

*D3D12_VIDEO_ENCODER_MOTION_SEARCH_SUPPORT_FLAG_SUPPORTED*

Indicates support for the given input parameters.

*D3D12_VIDEO_ENCODER_MOTION_SEARCH_SUPPORT_FLAG_MULTIPLE_HINTS*

When `D3D12_FEATURE_DATA_VIDEO_ENCODER_MOTION_SEARCH.MapSource == D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE_CPU_BUFFER`, indicates that `D3D12_VIDEO_ENCODER_MOVEREGION_INFO.pMoveRegions` can contain overlapping rects.

When `D3D12_FEATURE_DATA_VIDEO_ENCODER_MOTION_SEARCH.MapSource == D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE_GPU_TEXTURE`, indicates that `D3D12_VIDEO_ENCODER_INPUT_MAP_DATA_MOTION_VECTORS.NumHintsPerPixel` can be `> 1` and driver will report the upper limit in `D3D12_FEATURE_DATA_VIDEO_ENCODER_MOTION_SEARCH.MaxMotionHints` accordingly.

*D3D12_VIDEO_ENCODER_MOTION_SEARCH_SUPPORT_FLAG_GPU_TEXTURE_MULTIPLE_REFERENCES*

Indicates that each GPU motion map can have motion vectors that point to different DPB indices. In other words, when supported, the `(!= 255)` values in the `D3D12_VIDEO_ENCODER_INPUT_MAP_DATA_MOTION_VECTORS.ppMotionVectorMapsMetadata[i]` texture can point to different reference indices in the DPB. If this flag is not supported, all the motion vectors in `D3D12_VIDEO_ENCODER_INPUT_MAP_DATA_MOTION_VECTORS.ppMotionVectorMaps[i]` must correspond to the same DPB index, meaning that the `(!= 255)` values in the `D3D12_VIDEO_ENCODER_INPUT_MAP_DATA_MOTION_VECTORS.ppMotionVectorMapsMetadata[i]` must be unique, where `i` is in the range `[0, NumHintsPerPixel)`.

### STRUCT: D3D12_FEATURE_DATA_VIDEO_ENCODER_MOTION_SEARCH

```C++
// D3D12_FEATURE_VIDEO_ENCODER_MOTION_SEARCH
typedef struct D3D12_FEATURE_DATA_VIDEO_ENCODER_MOTION_SEARCH
{
    UINT NodeIndex;                                                                                 // input
    D3D12_VIDEO_ENCODER_INPUT_MAP_SESSION_INFO SessionInfo;                                         // input
    D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE MotionSearchMode;                                  // input
    D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE MapSource;                                                 // input
    BOOL BidirectionalRefFrameEnabled;                                                              // input
    D3D12_VIDEO_ENCODER_MOTION_SEARCH_SUPPORT_FLAGS SupportFlags;                                   // output
    UINT MaxMotionHints;                                                                            // output
    UINT MinDeviation;                                                                              // output
    UINT MaxDeviation;                                                                              // output
    UINT MapSourcePreferenceRanking;                                                                // output
    D3D12_VIDEO_ENCODER_FRAME_INPUT_MOTION_UNIT_PRECISION_SUPPORT_FLAGS MotionUnitPrecisionSupport; // output
} D3D12_FEATURE_DATA_VIDEO_ENCODER_MOTION_SEARCH;
```

*NodeIndex*

Input parameter, in multi-adapter operation, this indicates which physical adapter of the device this operation applies to.

*SessionInfo*

Input parameter, contains information pertaining to the encoding session.

*MapSource*

Input parameter, indicates to the driver which source does the user intends to use (e.g GPU/CPU input).

*MotionSearchMode*

Input parameter, desired motion search mode to check support for.

*BidirectionalRefFrameEnabled*

Input parameter, indicates if the user will use the feature when calling `EncodeFrame1` for bidirectional reference frames (e.g B frames for H264). If false, indicates the user will only use the feature when calling `EncodeFrame1` for single direction reference frames (e.g P frames for H264).

*Note:* When encoding sessions use picture type patterns with both single direction and bidirectional reference frames (e.g GOPs with both P and B in H264), and the driver only reports support for one frame type in this support query, the user can still make use of the feature, only enabling the feature in `EncodeFrame1` when encoding the supported frame types.

*IsSupported*

Output parameter, indicates if given input params for feature are supported.

*MaxMotionHints*

Output parameter. Indicates the maximum value supported by the driver for `D3D12_VIDEO_ENCODER_INPUT_MAP_DATA_MOTION_VECTORS.NumHintsPerPixel` on `D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE_GPU_TEXTURE` mode or `D3D12_VIDEO_ENCODER_MOVEREGION_INFO.NumMoveRegions` on `D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE_CPU_BUFFER` mode.

For `D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE_CPU_BUFFER`, the driver must support `MaxMotionHints` of at least the number of blocks in the frame for the given resolution. This requirement is so that at least one motion vector per block can be specified to be consistent with [MFSampleExtension_FeatureMap ](https://learn.microsoft.com/en-us/windows/win32/medfound/mfsampleextension-featuremap) and [MACROBLOCK_DATA](https://learn.microsoft.com/en-us/windows/win32/api/mfapi/ns-mfapi-macroblock_data).

*MinDeviation*

Output parameter. For `D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE_START_HINT_LIMITED_DISTANCE` indicates the minimum value supported by the driver for `D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE_CONFIG.SearchDeviationLimit`.

*MaxDeviation*

Output parameter. For `D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE_START_HINT_LIMITED_DISTANCE` indicates the maximum value supported by the driver for `D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE_CONFIG.SearchDeviationLimit`.

*MapSourcePreferenceRanking*

Output parameter, indicates the driver preference (allowed output range [0..1]) for the input `MapSource` passed in. This is a hint to indicate the app in case of supporting multiple `MapSource` types, which ones may incur in bigger resolve/conversion performance hit so apps having the option to provide multiple sources can make an informed decision. In cases were there is no difference between `MapSource` inputs, driver can report both preference rankings as zero. The lowest the value reported, the best performance for this `MapSource` input type.

*MotionUnitPrecisionSupport*

Output parameter. Driver reports flag combination of supported precision modes for input vectors/rects.

### ENUM: D3D12_VIDEO_ENCODER_INPUT_MAP_TYPE

```C++
typedef enum D3D12_VIDEO_ENCODER_INPUT_MAP_TYPE
{
    D3D12_VIDEO_ENCODER_INPUT_MAP_TYPE_QUANTIZATION_MATRIX = 0,
    D3D12_VIDEO_ENCODER_INPUT_MAP_TYPE_DIRTY_REGIONS = 1,
    D3D12_VIDEO_ENCODER_INPUT_MAP_TYPE_MOTION_VECTORS = 2,
} D3D12_VIDEO_ENCODER_INPUT_MAP_TYPE;
```

### STRUCT: D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLVE_INPUT_PARAM_LAYOUT

Driver reports support for `ID3D12VideoEncodeCommandList4::ResolveInputParamLayout`.

```C++
// D3D12_FEATURE_VIDEO_ENCODER_RESOLVE_INPUT_PARAM_LAYOUT
typedef struct D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLVE_INPUT_PARAM_LAYOUT
{
    UINT NodeIndex;                                          // input
    D3D12_VIDEO_ENCODER_INPUT_MAP_SESSION_INFO SessionInfo;  // input
    D3D12_VIDEO_ENCODER_INPUT_MAP_TYPE MapType;              // input
    BOOL IsSupported;                                        // output
    UINT64 MaxResolvedBufferAllocationSize;                  // output
} D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLVE_INPUT_PARAM_LAYOUT;
```

*MaxResolvedBufferAllocationSize*

Output parameter, indicates the size of the allocation the user must make for the output opaque buffer result of the `ResolveInputParamLayout` operation.

### ENUM: D3D12_VIDEO_ENCODER_VALIDATION_FLAGS

Adds a new flags to the existing `D3D12_VIDEO_ENCODER_VALIDATION_FLAGS`, to be reported by driver with the using new extended query cap `D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT2` additional inputs.

```C++
typedef enum D3D12_VIDEO_ENCODER_VALIDATION_FLAGS
{
    D3D12_VIDEO_ENCODER_VALIDATION_FLAG_NONE = 0x0,
    ...
    D3D12_VIDEO_ENCODER_VALIDATION_FLAG_QPMAP_NOT_SUPPORTED = ...,
    D3D12_VIDEO_ENCODER_VALIDATION_FLAG_DIRTY_REGIONS_NOT_SUPPORTED = ...,
    D3D12_VIDEO_ENCODER_VALIDATION_FLAG_MOTION_SEARCH_NOT_SUPPORTED = ...,
} D3D12_VIDEO_ENCODER_VALIDATION_FLAGS;
```

### STRUCT: D3D12_VIDEO_ENCODER_QPMAP_CONFIGURATION

Defines the configuration for QPMap as input for `D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT2`.

```C++
struct D3D12_VIDEO_ENCODER_QPMAP_CONFIGURATION
{
    BOOL Enabled;
    D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE MapSource;
};
```

### STRUCT: D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_QPMAP

Defines the reported support for QPMap as output for `D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS1`.

```C++
typedef D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_QPMAP
{
    // Reuse existing D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS1.QPMapRegionPixelsSize for BlockSize
    UINT MapSourcePreferenceRanking;
} D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_QPMAP;
```

### STRUCT: D3D12_VIDEO_ENCODER_DIRTY_REGIONS_CONFIGURATION

Defines the configuration for dirty regions as input for `D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT2`.

```C++
struct D3D12_VIDEO_ENCODER_DIRTY_REGIONS_CONFIGURATION
{
    BOOL Enabled;
    D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE MapSource;
    D3D12_VIDEO_ENCODER_DIRTY_REGIONS_MAP_VALUES_MODE MapValuesType;
};
```

### STRUCT: D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_DIRTY_REGIONS

Defines the reported support for dirty regions as output for `D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS1`.

```C++
typedef D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_DIRTY_REGIONS
{
    D3D12_VIDEO_ENCODER_DIRTY_REGIONS_SUPPORT_FLAGS DirtyRegionsSupportFlags;
    UINT MapSourcePreferenceRanking;
} D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_DIRTY_REGIONS;
```

### STRUCT: D3D12_VIDEO_ENCODER_MOTION_SEARCH_CONFIGURATION

Defines the configuration for motion search as input for `D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT2`.

```C++
struct D3D12_VIDEO_ENCODER_MOTION_SEARCH_CONFIGURATION
{
    BOOL Enabled;
    D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE MapSource;
    D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE MotionSearchMode;
    BOOL BidirectionalRefFrameEnabled;
};
```

### STRUCT: D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_MOTION_SEARCH

Defines the reported support for motion search as output for `D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS1`.

```C++
typedef D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_MOTION_SEARCH
{
    UINT MaxMotionHints;
    UINT MinDeviation;
    UINT MaxDeviation;
    UINT MapSourcePreferenceRanking;
    D3D12_VIDEO_ENCODER_FRAME_INPUT_MOTION_UNIT_PRECISION_SUPPORT_FLAGS MotionUnitPrecisionSupportFlags;
    D3D12_VIDEO_ENCODER_MOTION_SEARCH_SUPPORT_FLAGS MotionSearchSupportFlags;
} D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_MOTION_SEARCH;
```

### STRUCT: D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS1

Adds the new reported support structs defined above to be reportable by the driver per-resolution in `D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT2`.

```C++
struct D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS1
{
    /* Below match existing D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS */
    UINT MaxSubregionsNumber;
    UINT MaxIntraRefreshFrameDuration;
    UINT SubregionBlockPixelsSize;
    UINT QPMapRegionPixelsSize;

    /* Below are new arguments for D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS1 */
    D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_QPMAP QPMap;
    D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_DIRTY_REGIONS DirtyRegions;
    D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_MOTION_SEARCH MotionSearch;
};
```

**New members**

*QPMap*

Output parameter. See remarks of `D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT2` for more info.

*DirtyRegions*

Output parameter. Only reported when `D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT2.DirtyRegions.Enabled == TRUE` and driver supports it. Zeroed memory otherwise.

*MotionSearch*

Output parameter. Only reported when `D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT2.MotionSearch.Enabled == TRUE` and driver supports it. Zeroed memory otherwise.


### STRUCT: D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT2

Extends `D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT1`, for the driver to be able to report support details when enabling the QPMap, Dirty regions and/or motion search hints features of this spec in combination with the rest of the encode features. As usual, if the driver does not support a given combination with the new features, must report `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_NONE` and specify in `D3D12_VIDEO_ENCODER_VALIDATION_FLAGS` the conflicting features.

This new query must behave exactly as `D3D12_FEATURE_VIDEO_ENCODER_SUPPORT1` semantics when the new input parameters features are not enabled.

```C++
typedef struct D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT2
{
    /*
     * Below params match existing D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT1 binary size
     * please note pResolutionDependentSupport type changes from D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS to D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS1
    */

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
    [annotation("_Field_size_full_(ResolutionsListCount)")] D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS1* pResolutionDependentSupport;
    D3D12_VIDEO_ENCODER_PICTURE_CONTROL_SUBREGIONS_LAYOUT_DATA SubregionFrameEncodingData;
    UINT MaxQualityVsSpeed;

    /* Below are new arguments for D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT2 */
    D3D12_VIDEO_ENCODER_QPMAP_CONFIGURATION QPMap;
    D3D12_VIDEO_ENCODER_DIRTY_REGIONS_CONFIGURATION DirtyRegions;
    D3D12_VIDEO_ENCODER_MOTION_SEARCH_CONFIGURATION MotionSearch;
} D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT2;
```

**Remarks**

- Backward compatibility with `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_RATE_CONTROL_DELTA_QP_AVAILABLE`/`D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS1.QPMapRegionPixelsSize`:
    - For `D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT2` to behave like previous caps, when `D3D12_VIDEO_ENCODER_QPMAP_CONFIGURATION.MapSource == D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE_CPU_BUFFER`, the support flag and per resolution value must be reported (if supported) disregarding the input value of `D3D12_VIDEO_ENCODER_QPMAP_CONFIGURATION.Enabled`.
    - For `D3D12_VIDEO_ENCODER_QPMAP_CONFIGURATION.MapSource == D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE_GPU_TEXTURE`, driver reports `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_RATE_CONTROL_DELTA_QP_AVAILABLE` when supported from GPU source, and `D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS1.QPMapRegionPixelsSize` indicates `D3D12_FEATURE_DATA_VIDEO_ENCODER_QPMAP_INPUT.BlockSize` only when `D3D12_VIDEO_ENCODER_QPMAP_CONFIGURATION.Enabled == TRUE`.

**New members**

*pResolutionDependentSupport*

Output parameter. Driver fills this in for each resolution passed in `pResolutionList`. New output params in `D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS1` for QPMap, dirty regions, motion search depend on the new inputs to `D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT2`.

*QPMap*

Input parameter. Intended configuration to be used for QPMap.

*DirtyRegions*

Input parameter. Intended configuration to be used for dirty regions.

*MotionSearch*

Input parameter. Intended configuration to be used for motion search.

## 3.1.2 Input parameter layout conversions API

In order for the GPU to accept the `ID3D12Resource` **texture** input parameters  added in this spec in `ID3D12VideoEncodeCommandList4::EncodeFrame1`, certain memory layout conversions may need to happen before the hardware can understand the inputs, and a new command `ID3D12VideoEncodeCommandList4::ResolveInputParamLayout` is added to this end.

### METHOD: ID3D12VideoEncodeCommandList4::ResolveInputParamLayout

```C++
VOID ResolveInputParamLayout(
    [annotation("_In_")] const D3D12_VIDEO_ENCODER_RESOLVE_INPUT_PARAM_LAYOUT_INPUT_ARGUMENTS *pInputArguments,
    [annotation("_In_")] const D3D12_VIDEO_ENCODER_RESOLVE_INPUT_PARAM_LAYOUT_OUTPUT_ARGUMENTS *pOutputArguments)
```

**Remarks**

Converts from the hardware agnostic input layouts of the maps defined in this spec, into the hardware specific opaque layouts.

Input resources must be in `D3D12_RESOURCE_STATE_VIDEO_ENCODE_READ` and output resources in `D3D12_RESOURCE_STATE_VIDEO_ENCODE_WRITE` before executing this command.

### STRUCT: D3D12_VIDEO_ENCODER_RESOLVE_INPUT_PARAM_LAYOUT_INPUT_ARGUMENTS

```C++
typedef struct D3D12_VIDEO_ENCODER_RESOLVE_INPUT_PARAM_LAYOUT_INPUT_ARGUMENTS
{
    D3D12_VIDEO_ENCODER_INPUT_MAP_SESSION_INFO SessionInfo;
    D3D12_VIDEO_ENCODER_INPUT_MAP_DATA InputData;
} D3D12_VIDEO_ENCODER_RESOLVE_INPUT_PARAM_LAYOUT_INPUT_ARGUMENTS;
```

*SessionInfo*

Contains information pertaining to the encoding session.

*InputData*

Contains the input data along with the input type being resolved.

```C++
typedef struct D3D12_VIDEO_ENCODER_RESOLVE_INPUT_PARAM_LAYOUT_OUTPUT_ARGUMENTS
{
    ID3D12Resource* pOpaqueLayoutBuffer;
} D3D12_VIDEO_ENCODER_RESOLVE_INPUT_PARAM_LAYOUT_OUTPUT_ARGUMENTS;
```

*pOpaqueLayoutBuffer*

Contains the resolved output to hardware specific layout. This allocation is owned by the app and must be allocated according to the value reported in` D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLVE_INPUT_PARAM_LAYOUT.MaxResolvedBufferAllocationSize` for the input argument being resolved.

### UNION: D3D12_VIDEO_ENCODER_INPUT_MAP_DATA

```C++
typedef struct D3D12_VIDEO_ENCODER_INPUT_MAP_DATA
{
    D3D12_VIDEO_ENCODER_INPUT_MAP_TYPE MapType;
    union
    {
        // For MapType: D3D12_VIDEO_ENCODER_INPUT_MAP_TYPE_QUANTIZATION_MATRIX
        D3D12_VIDEO_ENCODER_INPUT_MAP_DATA_QUANTIZATION_MATRIX Quantization;
        // For MapType: D3D12_VIDEO_ENCODER_INPUT_MAP_TYPE_DIRTY_REGIONS
        D3D12_VIDEO_ENCODER_INPUT_MAP_DATA_DIRTY_REGIONS DirtyRegions;
        // For MapType: D3D12_VIDEO_ENCODER_INPUT_MAP_TYPE_MOTION_VECTORS
        D3D12_VIDEO_ENCODER_INPUT_MAP_DATA_MOTION_VECTORS MotionVectors;
    };
} D3D12_VIDEO_ENCODER_INPUT_MAP_DATA;
```

### STRUCT: D3D12_VIDEO_ENCODER_INPUT_MAP_DATA_QUANTIZATION_MATRIX

```C++
typedef struct D3D12_VIDEO_ENCODER_INPUT_MAP_DATA_QUANTIZATION_MATRIX
{
    ID3D12Resource* pQuantizationMap;
} D3D12_VIDEO_ENCODER_INPUT_MAP_DATA_QUANTIZATION_MATRIX;
```

**Remarks**

*pQuantizationMap*

A texture with format `DXGI_FORMAT_R8_SINT` for H264, HEVC or `DXGI_FORMAT_R16_SINT` for AV1. The dimensions must correspond with the driver supported QP Map region block size `D3D12_FEATURE_DATA_VIDEO_ENCODER_QPMAP_INPUT.BlockSize` and the current frame's resolution, and each (x, y) position on this texture corresponds to the QP value used on that block.

- QPMap Width: `(align(FrameResolution.Width, BlockSize) / BlockSize)`
- QPMap Height: `(align(FrameResolution.Height, BlockSize) / BlockSize)`

### STRUCT: D3D12_VIDEO_ENCODER_INPUT_MAP_DATA_DIRTY_REGIONS

```C++
typedef struct D3D12_VIDEO_ENCODER_INPUT_MAP_DATA_DIRTY_REGIONS
{
    BOOL FullFrameIdentical;
    D3D12_VIDEO_ENCODER_DIRTY_REGIONS_MAP_VALUES_MODE MapValuesType;
    ID3D12Resource* pDirtyRegionsMap;
    UINT SourceDPBFrameReference;
} D3D12_VIDEO_ENCODER_INPUT_MAP_DATA_DIRTY_REGIONS;
```

*FullFrameIdentical*

Indicates that the current frame is a repeat frame from the frame referenced by `SourceDPBFrameReference`. When this parameter is `TRUE`, `pDirtyRegionsMap` must be `NULL` and the driver will interpret it as a dirty regions map being present and an all-zero matrix in mode `D3D12_VIDEO_ENCODER_DIRTY_REGIONS_MAP_VALUES_MODE_DIRTY`.

    Note that for AV1, identical frames can be coded using `show_existing_frame` in `uncompressed_header` of `frame_header_obu`, which is coded by the app in D3D12 and hence no driver/hardware involvement is required.

*MapValuesType*

Indicates the semantic of the values of `pDirtyRegionsMap`.

*pDirtyRegionsMap*

Indicates the positions and dimensions of the dirty region. The texture must have the same dimension as the input texture to be encoded, and have format `DXGI_FORMAT_R8_UINT`. Each (x, y) position indicates if the pixel at that position is different or identical to a pixel in the same (x, y) position located in previous frame in the DPB used as reference, indicated by `SourceDPBFrameReference`.

*SourceDPBFrameReference*

Indicates which previous frame (currently in the DPB and used as reference by the current frame) is this dirty region referring to.

The hardware can encode skip regions (e.g skip blocks, skip slices) on the areas the current frame didn't change respect to this previous frame, and focus only on the dirty areas.

This is an index into the picture parameters's DPB descriptor.

- For AV1 indexes into `D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA.ReferenceFramesReconPictureDescriptors[]`
- For H264 indexes into `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_H264.pReferenceFramesReconPictureDescriptors[]`
- For HEVC indexes into  `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC.pReferenceFramesReconPictureDescriptors[]`.

### STRUCT: D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE_CONFIG

```C++
typedef struct D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE_CONFIG
{
    D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE    MotionSearchMode;
    UINT                                            SearchDeviationLimit;
} D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE_CONFIG;
```

*MotionSearchMode*

Specifies the motion search mode in which the driver will use the motion vector hints.
- If `NumHintsPerPixel == 0`, `MotionSearchMode` must be `D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE_FULL_SEARCH`.
- If `NumHintsPerPixel > 0`, `MotionSearchMode` may specify motion search configuration on how to use the motion vector hints.

*SearchDeviationLimit*

To be used with `D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE_START_HINT_LIMITED_DISTANCE`.

### STRUCT: D3D12_VIDEO_ENCODER_INPUT_MAP_DATA_MOTION_VECTORS

```C++
typedef struct D3D12_VIDEO_ENCODER_INPUT_MAP_DATA_MOTION_VECTORS
{
    D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE_CONFIG                  MotionSearchModeConfiguration;
    UINT                                                                 NumHintsPerPixel;
    [annotation("_Field_size_full_(NumHintsPerPixel)")] ID3D12Resource** ppMotionVectorMaps;
    [annotation("_Field_size_full_(NumHintsPerPixel)")] UINT*            pMotionVectorMapsSubresources;
    [annotation("_Field_size_full_(NumHintsPerPixel)")] ID3D12Resource** ppMotionVectorMapsMetadata;
    [annotation("_Field_size_full_(NumHintsPerPixel)")] UINT*            pMotionVectorMapsMetadataSubresources;
    D3D12_VIDEO_ENCODER_FRAME_INPUT_MOTION_UNIT_PRECISION                MotionUnitPrecision;
    D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA                       PictureControlConfiguration;
} D3D12_VIDEO_ENCODER_INPUT_MAP_DATA_MOTION_VECTORS;
```

*MotionSearchModeConfiguration*

Specifies more details about how the motion input vectors will be used.

*NumHintsPerPixel*

Number of motion vector hint maps. Each map provides an additional motion vector hint for each (x, y) pixel position.

*ppMotionVectorMaps*

Each 2D texture in `ppMotionVectorMaps[i]` represents the i-th motion vector hint for each (x, y) pixel position, where `i` is in the range `[0, NumHintsPerPixel)`.

The dimension must match with the input texture frame. Each component of this 2D texture is an `DXGI_FORMAT_R16G16_SINT` element where `R16` holds the horizontal component and `G16` holds the vertical component of the motion vector.

*pMotionVectorMapsSubresources*

Subresources indices for when `ppMotionVectorMaps` is a texture array, `NULL` otherwise.

*ppMotionVectorMapsMetadata*

Each 2D texture in `ppMotionVectorMaps[i]` represents the metadata for the i-th motion vector hint for each (x, y) pixel position, where `i` is in the range `[0, NumHintsPerPixel)`.

The dimension must match with the input texture frame. Each component of this 2D texture is an `DXGI_FORMAT_R8_UINT` element where `R8` holds the reference frame index in the DPB from which this motion vector **points from**. A value of `255` indicates the current motion vector must be ignored from the driver. Other value indicates current motion vector may be used by driver.

- Semantics for AV1:
    - `R8` indexes into `D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA.ReferenceFramesReconPictureDescriptors[]`.

- Semantics for H264:
    - `R8` indexes into `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_H264.pReferenceFramesReconPictureDescriptors[]`.

- Semantics for HEVC:
    - `R8` indexes into  `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC.pReferenceFramesReconPictureDescriptors[]`..

> Check the support flag `D3D12_VIDEO_ENCODER_MOTION_SEARCH_SUPPORT_FLAG_GPU_TEXTURE_MULTIPLE_REFERENCES` for more details about this parameter.

*pMotionVectorMapsMetadataSubresources*

Subresources indices for when `ppMotionVectorMapsMetadata` is a texture array, `NULL` otherwise.

*MotionUnitPrecision*

Defines the numerical unit used in the motion vector values.

*PictureControlConfiguration*

Provides more information to the driver about picture control associated with the frame that will be encoded with this motion info, such as reference lists, reordering, etc depending on the codec.

**Remarks**

For example, if `MotionUnitPrecision` is `D3D12_VIDEO_ENCODER_FRAME_INPUT_MOTION_UNIT_PRECISION_FULL_PIXEL`, a motion vector in position `(x, y)` of a `ppMotionVectorMaps[0]` texture having a `R16G16` value of `(-3, 6)` and with associated `(x, y)` metadata in `ppMotionVectorMapsMetadata[0]` having a `R8` value of `1`, indicates this is a motion vector starting from the `(x - 3, y + 6)` pixel position of the DPB descriptors entry number `1`, pointing into the pixel position `(x, y)` of the current frame.

To clarify also, all positions (x, y) where ppMotionVectorMapsMetadata[0] has an `R8` value `255` indicates that there is no motion vector hint for the driver in that position.

## 3.1.2 EncodeFrame API

### ENUM: D3D12_VIDEO_ENCODER_HEAP_FLAGS

```C++
typedef enum D3D12_VIDEO_ENCODER_HEAP_FLAGS
{
    ...
    // New flags added in this spec
    D3D12_VIDEO_ENCODER_HEAP_FLAG_ALLOW_DIRTY_REGIONS = ...,
} D3D12_VIDEO_ENCODER_HEAP_FLAGS;
```

### STRUCT: D3D12_VIDEO_ENCODER_QUANTIZATION_OPAQUE_MAP

```C++
typedef enum D3D12_VIDEO_ENCODER_PICTURE_CONTROL_FLAGS
{
    ...
    D3D12_VIDEO_ENCODER_PICTURE_CONTROL_FLAG_ENABLE_QUANTIZATION_MATRIX_INPUT = ...,
    D3D12_VIDEO_ENCODER_PICTURE_CONTROL_FLAG_ENABLE_DIRTY_REGIONS_INPUT = ...,
    D3D12_VIDEO_ENCODER_PICTURE_CONTROL_FLAG_ENABLE_MOTION_VECTORS_INPUT = ...,
} D3D12_VIDEO_ENCODER_PICTURE_CONTROL_FLAGS;
```

*D3D12_VIDEO_ENCODER_PICTURE_CONTROL_FLAG_ENABLE_QUANTIZATION_MATRIX_INPUT*

User must enable this flag when using the `D3D12_VIDEO_ENCODER_QUANTIZATION_OPAQUE_MAP QuantizationTextureMap` parameter. App must also enable `D3D12_VIDEO_ENCODER_RATE_CONTROL_FLAG_ENABLE_DELTA_QP` for any kind (CPU/GPU) of delta QP Map, also setting `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_FLAG_ENABLE_QUANTIZATION_MATRIX_INPUT` indicates this is a GPU map instead of the usual CPU matrix.

*D3D12_VIDEO_ENCODER_PICTURE_CONTROL_FLAG_ENABLE_DIRTY_REGIONS_INPUT*

User must enable this flag when using the `D3D12_VIDEO_ENCODER_DIRTY_REGIONS DirtyRects` parameter.

For apps to use `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_FLAG_ENABLE_DIRTY_REGIONS_INPUT`, the associated `ID3D12VideoEncoderHeap` passed to `EncodeFrame1` needs to have been created with `CreateVideoEncoderHeap` with the `D3D12_VIDEO_ENCODER_HEAP_FLAG_ALLOW_DIRTY_REGIONS` set in `D3D12_VIDEO_ENCODER_HEAP_DESC.Flags`.

Please note that the driver must report variations (if any) in memory usage when these flags are set in `D3D12_FEATURE_DATA_VIDEO_ENCODER_HEAP_SIZE`.

*D3D12_VIDEO_ENCODER_PICTURE_CONTROL_FLAG_ENABLE_MOTION_VECTORS_INPUT*

User must enable this flag when using the `D3D12_VIDEO_ENCODER_FRAME_MOTION_VECTORS MotionVectors` parameter.

### STRUCT: D3D12_VIDEO_ENCODER_QUANTIZATION_OPAQUE_MAP

```C++
typedef struct D3D12_VIDEO_ENCODER_QUANTIZATION_OPAQUE_MAP
{
    ID3D12Resource* pOpaqueQuantizationMap;
} D3D12_VIDEO_ENCODER_QUANTIZATION_OPAQUE_MAP;
```

**Remarks**

User must check support for `D3D12_FEATURE_VIDEO_ENCODER_QPMAP_INPUT` before using this feature.

*pOpaqueQuantizationMap*

Contains a quantization map for the current frame. To be used in the same cases as the previously existing parameters `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_H264.pRateControlQPMap`, `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC.pRateControlQPMap` or `D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA.pRateControlQPMap`. 

When this parameter is `not NULL` it superseeds the previously existing CPU buffers `pRateControlQPMap` picture control structure parameters and the driver will consider `pOpaqueQuantizationMap` as the Quantization map to use over the CPU buffer. Otherwise, `pRateControlQPMap` CPU parameters may still be used as previously. 

When present, must be first resolved into this opaque layout using `ID3D12VideoEncodeCommandList4::ResolveInputParamLayout`.

### STRUCT: D3D12_VIDEO_ENCODER_DIRTY_RECT_INFO

```C++
typedef struct D3D12_VIDEO_ENCODER_DIRTY_RECT_INFO
{
    BOOL FullFrameIdentical;
    D3D12_VIDEO_ENCODER_DIRTY_REGIONS_MAP_VALUES_MODE MapValuesType;
    UINT NumDirtyRects;
    [annotation("_Field_size_full_(NumDirtyRects)")] RECT* pDirtyRects;
    UINT SourceDPBFrameReference;
} D3D12_VIDEO_ENCODER_DIRTY_RECT_INFO;
```

*FullFrameIdentical*

Indicates that the current frame is a repeat frame from the frame referenced by `SourceDPBFrameReference`. When this parameter is `TRUE`, `pDirtyRects` must be `NULL` and the driver will interpret it as a dirty regions map being present and an all-zero matrix in mode `D3D12_VIDEO_ENCODER_DIRTY_REGIONS_MAP_VALUES_MODE_DIRTY`.

    Note that for AV1, identical frames can be coded using `show_existing_frame` in `uncompressed_header` of `frame_header_obu`, which is coded by the app in D3D12 and hence no driver/hardware involvement is required.

*MapValuesType*

Indicates the semantic of the values of `pDirtyRects`.

*pDirtyRects*

Each rect indicates the pixels at those position are different or identical to the pixels in the same positions located in previous frame in the DPB used as reference, indicated by `SourceDPBFrameReference`.

*SourceDPBFrameReference*

Indicates which previous frame (currently in the DPB and used as reference by the current frame) is this dirty region referring to.

The hardware can encode skip regions (e.g skip blocks, skip slices) on the areas the current frame didn't change respect to this previous frame, and focus only on the dirty areas.

This is an index into the picture parameters's DPB descriptor.

- For AV1 indexes into `D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA.ReferenceFramesReconPictureDescriptors[]`
- For H264 indexes into `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_H264.pReferenceFramesReconPictureDescriptors[]`
- For HEVC indexes into  `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC.pReferenceFramesReconPictureDescriptors[]`.

### STRUCT: D3D12_VIDEO_ENCODER_DIRTY_REGIONS

```C++
typedef struct D3D12_VIDEO_ENCODER_DIRTY_REGIONS
{
    D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE MapSource;
    union
    {
        // Use with: D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE_GPU_TEXTURE
        ID3D12Resource* pOpaqueLayoutBuffer;
        // Use with: D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE_CPU_BUFFER
        D3D12_VIDEO_ENCODER_DIRTY_RECT_INFO* pCPUBuffer;
    };
} D3D12_VIDEO_ENCODER_DIRTY_REGIONS;
```

**Remarks**

User must check support for `D3D12_FEATURE_VIDEO_ENCODER_DIRTY_REGIONS` before using this feature.

*MapSource*

Indicates which source uses for the feature.

*pOpaqueLayoutBuffer*

Use with `D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE_GPU_TEXTURE`.

Contains the resolved output to hardware specific layout. This allocation is owned by the app and must be allocated according to the value reported in` D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLVE_INPUT_PARAM_LAYOUT.MaxResolvedBufferAllocationSize` for the input argument being resolved.

*pCPUBuffer*

Use with `D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE_CPU_BUFFER`.

### STRUCT: D3D12_VIDEO_ENCODER_MOVE_RECT

```C++
typedef struct D3D12_VIDEO_ENCODER_MOVE_RECT
{
    POINT   SourcePoint;
    RECT    DestRect;
} D3D12_VIDEO_ENCODER_MOVE_RECT;
```
### ENUM: D3D12_VIDEO_ENCODER_MOVEREGION_INFO_FLAGS

```C++
typedef enum D3D12_VIDEO_ENCODER_MOVEREGION_INFO_FLAGS
{
    D3D12_VIDEO_ENCODER_MOVEREGION_INFO_FLAG_NONE = 0x0,
    D3D12_VIDEO_ENCODER_MOVEREGION_INFO_FLAG_MULTIPLE_HINTS = 0x1,
} D3D12_VIDEO_ENCODER_MOVEREGION_INFO_FLAGS;
```

*D3D12_VIDEO_ENCODER_MOVEREGION_INFO_FLAG_MULTIPLE_HINTS*

Indicates that `D3D12_VIDEO_ENCODER_MOVEREGION_INFO.pMoveRegions` contains overlapped rects, producing multiple hints for the positions where the overlap occurs. Check support with `D3D12_VIDEO_ENCODER_MOTION_SEARCH_SUPPORT_FLAG_MULTIPLE_HINTS` before using this flag.

### STRUCT: D3D12_VIDEO_ENCODER_MOVEREGION_INFO

```C++
typedef struct D3D12_VIDEO_ENCODER_MOVEREGION_INFO
{
    UINT NumMoveRegions;
    [annotation("_Field_size_full_(NumMoveRegions)")] D3D12_VIDEO_ENCODER_MOVE_RECT* pMoveRegions;
    D3D12_VIDEO_ENCODER_FRAME_MOTION_SEARCH_MODE_CONFIG MotionSearchModeConfiguration;
    UINT SourceDPBFrameReference;
    D3D12_VIDEO_ENCODER_FRAME_INPUT_MOTION_UNIT_PRECISION MotionUnitPrecision;
    D3D12_VIDEO_ENCODER_MOVEREGION_INFO_FLAGS Flags;
} D3D12_VIDEO_ENCODER_MOVEREGION_INFO;
```

*MotionSearchModeConfiguration*

Specifies more details about how the motion input vectors will be used.

*NumMoveRegions*

Number of elements in `pMoveRegions`.

*pMoveRegions*

Move regions, that specify all the pixels inside them move in the same direction. For each pixel inside one of the move rects, a motion vector can be inferred, all these vectors will point to the same direction the "move rect" points to.

*SourceDPBFrameReference*

Indicates which previous frame (currently in the DPB and used as reference by the current frame) is this move region referring to.

This is an index into the picture parameters's DPB descriptor.

- For AV1 indexes into `D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA.ReferenceFramesReconPictureDescriptors[]`
- For H264 indexes into `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_H264.pReferenceFramesReconPictureDescriptors[]`
- For HEVC indexes into  `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC.pReferenceFramesReconPictureDescriptors[]`.

*MotionUnitPrecision*

Defines the numerical unit used in the `D3D12_VIDEO_ENCODER_MOVE_RECT` values.

### STRUCT: D3D12_VIDEO_ENCODER_FRAME_MOTION_VECTORS

```C++
typedef struct D3D12_VIDEO_ENCODER_FRAME_MOTION_VECTORS
{
    D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE MapSource;
    union
    {
        // Use with: D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE_GPU_TEXTURE
        ID3D12Resource* pOpaqueLayoutBuffer;
        // Use with: D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE_CPU_BUFFER
        D3D12_VIDEO_ENCODER_MOVEREGION_INFO* pCPUBuffer;
    };
} D3D12_VIDEO_ENCODER_FRAME_MOTION_VECTORS;
```

User must check support for `D3D12_FEATURE_DATA_VIDEO_ENCODER_MOTION_SEARCH` before using this feature.

*MapSource*

Indicates which source uses for the feature.

*pOpaqueLayoutBuffer*

Use with `D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE_GPU_TEXTURE`.

Contains the resolved output to hardware specific layout. This allocation is owned by the app and must be allocated according to the value reported in` D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLVE_INPUT_PARAM_LAYOUT.MaxResolvedBufferAllocationSize` for the input argument being resolved.

*pCPUBuffer*

Use with `D3D12_VIDEO_ENCODER_INPUT_MAP_SOURCE_CPU_BUFFER`.

### STRUCT: D3D12_VIDEO_ENCODER_PICTURE_CONTROL_DESC1

```C++
typedef struct D3D12_VIDEO_ENCODER_PICTURE_CONTROL_DESC1
{
    UINT IntraRefreshFrameIndex;
    D3D12_VIDEO_ENCODER_PICTURE_CONTROL_FLAGS Flags;
    D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA PictureControlCodecData;
    D3D12_VIDEO_ENCODE_REFERENCE_FRAMES ReferenceFrames;
    D3D12_VIDEO_ENCODER_FRAME_MOTION_VECTORS MotionVectors;
    D3D12_VIDEO_ENCODER_DIRTY_REGIONS DirtyRects;
    D3D12_VIDEO_ENCODER_QUANTIZATION_OPAQUE_MAP QuantizationTextureMap;
} D3D12_VIDEO_ENCODER_PICTURE_CONTROL_DESC1;
```

### STRUCT: D3D12_VIDEO_ENCODER_ENCODEFRAME_INPUT_ARGUMENTS1
```C++
typedef struct D3D12_VIDEO_ENCODER_ENCODEFRAME_INPUT_ARGUMENTS1
{
    D3D12_VIDEO_ENCODER_SEQUENCE_CONTROL_DESC SequenceControlDesc;
    D3D12_VIDEO_ENCODER_PICTURE_CONTROL_DESC1 PictureControlDesc;
    ID3D12Resource *pInputFrame;
    UINT64 InputFrameSubresource;
    UINT64 CurrentFrameBitstreamMetadataSize;
} D3D12_VIDEO_ENCODER_ENCODEFRAME_INPUT_ARGUMENTS1;
```

### METHOD: ID3D12VideoEncodeCommandList4::EncodeFrame1

```C++
VOID EncodeFrame1(
    [annotation("_In_")] ID3D12VideoEncoder* pEncoder,
    [annotation("_In_")] ID3D12VideoEncoderHeap *pHeap;
    [annotation("_In_")] const D3D12_VIDEO_ENCODER_ENCODEFRAME_INPUT_ARGUMENTS1 *pInputArguments
    [annotation("_In_")] const D3D12_VIDEO_ENCODER_ENCODEFRAME_OUTPUT_ARGUMENTS *pOutputArguments)
```
