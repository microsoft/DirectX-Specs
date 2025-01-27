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
