# 1. D3D12 Video Encoding readable reconstructed pictures 

# 2. General considerations

This spec focuses on the points of extension where the existing D3D12 Video Encode API needs new structures to support reconstructed pictures (EncodeFrame output and DPB reference pictures) being readable, meaning NOT requiring `D3D12_RESOURCE_FLAG_VIDEO_ENCODE_REFERENCE_ONLY` anymore. The rest of the D3D12 Encode API will remain unmodified for this feature unless explicited in this spec.
The next sections detail the API and DDI for video encoding. In many cases, the DDI is extremely similar to the API. The structures and enumerations which are basically the same (differing solely in name convention) are not repeated in the this specification.

# 3. Video Encoding API

### ENUM: D3D12_VIDEO_ENCODER_SUPPORT_FLAGS

```C++
typedef enum D3D12_VIDEO_ENCODER_SUPPORT_FLAGS
{
    ...
    // New flags added in this spec
    D3D12_VIDEO_ENCODER_SUPPORT_FLAG_READABLE_RECONSTRUCTED_PICTURE_LAYOUT_AVAILABLE	= ...,
} D3D12_VIDEO_ENCODER_SUPPORT_FLAGS;
```

**Remarks**

Driver reports optional support for `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_READABLE_RECONSTRUCTED_PICTURE_LAYOUT_AVAILABLE` using the associated support cap inputs (e.g the `DXGI_FORMAT` of the encoding input texture).

- When the driver does **NOT** report this flag, `D3D12_RESOURCE_FLAG_VIDEO_ENCODE_REFERENCE_ONLY` is still mandatory as usual. 

- When the driver DOES report this flag, the reconstructed picture output in `D3D12_VIDEO_ENCODER_ENCODEFRAME_OUTPUT_ARGUMENTS.ReconstructedPicture` and the pictures in the DPB in `D3D12_VIDEO_ENCODE_REFERENCE_FRAMES.ppTexture2Ds` can be just regular textures without `D3D12_RESOURCE_FLAG_VIDEO_ENCODE_REFERENCE_ONLY`. All other existing restrictions still apply (e.g  must be the same `DXGI_FORMAT`, dimensions, etc as `D3D12_VIDEO_ENCODER_ENCODEFRAME_INPUT_ARGUMENTS.pInputFrame`)

Please note that even when the driver reports `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_READABLE_RECONSTRUCTED_PICTURE_LAYOUT_AVAILABLE`, the usage of reconstructed pictures with `D3D12_RESOURCE_FLAG_VIDEO_ENCODE_REFERENCE_ONLY` must be still supported along with also readable textures.

Drivers must only report `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_READABLE_RECONSTRUCTED_PICTURE_LAYOUT_AVAILABLE` when the reconstructed pictures are in a readable layout, and **must not perform any conversions (e.g using shaders) within the driver that would mean a performance hit** respect using resources with `D3D12_RESOURCE_FLAG_VIDEO_ENCODE_REFERENCE_ONLY`. The intent of this feature is to allow users consume the reconstructed pictures where hardware/drivers allow it without any performance hit.

# 4. Video Processing API

The feature described in Section 3 allows drivers to expose reconstructed pictures in a readable layout natively, without requiring any conversion.

For drivers that cannot expose reconstructed pictures in a readable layout natively and require `D3D12_RESOURCE_FLAG_VIDEO_ENCODE_REFERENCE_ONLY`, the following APIs are extended to support an explicit application-requested conversion into readable resources using D3D12 Video Processing.

## 4.1 Feature support

### ENUM: D3D12_VIDEO_PROCESS_FEATURE_FLAGS

```C++
typedef enum D3D12_VIDEO_PROCESS_FEATURE_FLAGS
{
    ...
    D3D12_VIDEO_PROCESS_FEATURE_FLAG_ENCODER_READABLE_REFERENCE_CONVERSION = 0x80,
} D3D12_VIDEO_PROCESS_FEATURE_FLAGS;
```

*D3D12_VIDEO_PROCESS_FEATURE_FLAG_ENCODER_READABLE_REFERENCE_CONVERSION*

Indicates support for converting an input resource with `D3D12_RESOURCE_FLAG_VIDEO_ENCODE_REFERENCE_ONLY` into an output resource without `D3D12_RESOURCE_FLAG_VIDEO_ENCODE_REFERENCE_ONLY`.

## 4.2 Feature usage

**Remarks**

The following rules will be enforced in `ID3D12VideoProcessCommandList::ProcessFrames` for this feature:

- `D3D12_VIDEO_PROCESS_FEATURE_FLAG_ENCODER_READABLE_REFERENCE_CONVERSION` needs to be reported by the driver.
- If the input and output resource dimensions differ, `D3D12_VIDEO_SCALE_SUPPORT_FLAG_DPB_ENCODER_RESOURCES` *also* needs to be reported by the driver. In this case a single call to ProcessFrames does both the scaling from the input and the conversion to non-reference-only in the output.
- Only 1 input stream with `D3D12_RESOURCE_FLAG_VIDEO_ENCODE_REFERENCE_ONLY` passed to `ProcessFrames` (e.g no blending)
- The `ID3D12Resource` objects for input/output streams must have matching values for the following `D3D12_RESOURCE_DESC` properties:
    - `Dimension`
    - `MipLevels`
    - `Format`
    - The input must have `D3D12_RESOURCE_FLAG_VIDEO_ENCODE_REFERENCE_ONLY` in `Flags`
    - The output must not have `D3D12_RESOURCE_FLAG_VIDEO_ENCODE_REFERENCE_ONLY` in `Flags`
- `D3D12_VIDEO_PROCESS_OUTPUT_STREAM_ARGUMENTS.TargetRectangle` must cover the entire `D3D12_VIDEO_PROCESS_OUTPUT_STREAM` texture dimensions. (e.g no additional transforms)
- Restrictions to other transforms in `D3D12_VIDEO_PROCESS_INPUT_STREAM_ARGUMENTS`:
    - `D3D12_VIDEO_PROCESS_TRANSFORM` must contain `D3D12_VIDEO_PROCESS_ORIENTATION_DEFAULT`
    - `SourceRectangle` must cover the entire `D3D12_VIDEO_PROCESS_INPUT_STREAM` texture dimensions.
    - `DestinationRectangle` must cover the entire `D3D12_VIDEO_PROCESS_OUTPUT_STREAM` texture dimensions.
    - `D3D12_VIDEO_PROCESS_INPUT_STREAM_FLAGS`, `D3D12_VIDEO_PROCESS_INPUT_STREAM_RATE` are ignored by the driver.
    - `FilterLevels` is ignored (since `D3D12_VIDEO_PROCESS_FILTER_FLAGS` are restricted in `ID3D12VideoProcessor` objects to use this feature)
    - `D3D12_VIDEO_PROCESS_ALPHA_BLENDING.Enabled` must be `FALSE`.
    - `D3D12_VIDEO_PROCESS_REFERENCE_SET.NumPastFrames` and `D3D12_VIDEO_PROCESS_REFERENCE_SET.NumFutureFrames` must be `0`.

- Restrictions to the `ID3D12VideoProcessor` used in `ID3D12VideoProcessCommandList::ProcessFrames` for this feature:
    - From `D3D12_VIDEO_PROCESS_OUTPUT_STREAM_DESC` and `D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC`:
        - `D3D12_VIDEO_PROCESS_OUTPUT_STREAM_DESC.AlphaFillMode` must be `D3D12_VIDEO_PROCESS_ALPHA_FILL_MODE_OPAQUE`
        - `D3D12_VIDEO_PROCESS_OUTPUT_STREAM_DESC.EnableStereo` must be `FALSE`.
        - `D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC.StereoFormat` must be `D3D12_VIDEO_FRAME_STEREO_FORMAT_NONE`.
        - `D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC.EnableOrientation` must be `FALSE`.
        - `D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC.FilterFlags` must be `D3D12_VIDEO_PROCESS_FILTER_FLAG_NONE`.
        - `D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC.DeinterlaceMode` must be `D3D12_VIDEO_PROCESS_DEINTERLACE_FLAG_NONE`.
        - `D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC.EnableAlphaBlending` must be `FALSE`.
        - `D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC.LumaKey.Enable` must be `FALSE`.
        - `D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC.EnableAutoProcessing` must be `FALSE`.
    - From `D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC1`:
        - `D3D12_VIDEO_PROCESS_INPUT_STREAM_DESC1.ConfigurationLUT.ConfigFlags` must be `D3D12_VIDEO_PROCESS_LUT_TRANSFORM_CONFIGURATION_FLAG_NONE`.

- For drivers requiring texture array DPB allocations, `ID3D12VideoProcessCommandList::ProcessFrames` will allow the input/output streams to be converted from `{EncodeReferenceOnlyDPBTexArray + EncodeReferenceOnlySubres}` into `{ReadableDPBTexArray + ReadableSubres}` in `D3D12_VIDEO_PROCESS_INPUT_STREAM` and `D3D12_VIDEO_PROCESS_OUTPUT_STREAM` arguments respectively.
