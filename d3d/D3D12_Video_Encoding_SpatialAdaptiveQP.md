# D3D12 Video Encoding Spatial Adaptive QP

**Overview**

Hardware encoders offer new functionality in which the spatial features of the frames are analyzed and the QP values selected by the rate control algorithm are altered accordingly to improve perceptual visual quality. This feature applies to all DX12 rate control modes.

This spec focuses on the different points of extension where the existing D3D12 Video Encode API needs new structures to add spatial adaptive QP. The rest of the D3D12 Encode API will remain unmodified for this feature unless explicited in this spec.

## API and DDI similarities

The next sections detail the API and DDI for video encoding. In many cases, the DDI is extremely similar to the API. The structures and enumerations which are basically the same (differing solely in name convention) are not repeated in the this specification. We include just the DDI structures/enumerations and functions that differ substantially from the API.

# Video Encoding API

### ENUM: D3D12_VIDEO_ENCODER_SUPPORT_FLAGS

```C++
typedef enum D3D12_VIDEO_ENCODER_SUPPORT_FLAGS
{
    ...
    // New flags added in this spec
    D3D12_VIDEO_ENCODER_SUPPORT_FLAG_RATE_CONTROL_SPATIAL_ADAPTIVE_QP_AVAILABLE = ...,
} D3D12_VIDEO_ENCODER_SUPPORT_FLAGS;
```

**Remarks**

Driver reports optional support for `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_RATE_CONTROL_SPATIAL_ADAPTIVE_QP_AVAILABLE` using the associated support cap inputs (e.g the `DXGI_FORMAT` of the encoding input texture, the rate control mode, etc).


### ENUM: D3D12_VIDEO_ENCODER_SUPPORT_FLAGS
```C++
typedef enum D3D12_VIDEO_ENCODER_RATE_CONTROL_FLAGS
{
    ...
    D3D12_VIDEO_ENCODER_RATE_CONTROL_FLAG_ENABLE_SPATIAL_ADAPTIVE_QP = ...,
} D3D12_VIDEO_ENCODER_RATE_CONTROL_FLAGS;
```

*D3D12_VIDEO_ENCODER_RATE_CONTROL_FLAG_ENABLE_SPATIAL_ADAPTIVE_QP*

This flag can be enabled when `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_RATE_CONTROL_SPATIAL_ADAPTIVE_QP_AVAILABLE` is reported by the driver, to enable spatial adaptive QP on this frame.
