# D3D12 Depth Texture Unordered Access Views<!-- omit in toc -->

Version 1.0

This document proposes a new D3D12 feature that enables the creation of unordered access views (UAVs) for depth-stencil textures, providing direct read-write access to both depth and stencil planes from all shader stages.

---

## Contents <!-- omit in toc -->

- [Introduction](#introduction)
- [Goals](#goals)
- [Non-Goals](#non-goals)
- [Overall Design](#overall-design)
- [API](#api)
  - [Interleaved Depth-Stencil Format Support](#interleaved-depth-stencil-format-support)
- [Hardware Compression](#hardware-compression)
- [HLSL Usage](#hlsl-usage)
  - [Depth Plane Access](#depth-plane-access)
  - [Stencil Plane Access](#stencil-plane-access)
  - [Interleaved Layout Access](#interleaved-layout-access)
- [Format Support](#format-support)
- [Usage Examples](#usage-examples)
  - [Custom Depth Testing](#custom-depth-testing)
  - [Stencil-Based Algorithm](#stencil-based-algorithm)
- [Validation](#validation)
  - [Debug Layer Validation](#debug-layer-validation)
  - [Runtime Validation](#runtime-validation)
- [Test Plan](#test-plan)
  - [Conformance Tests](#conformance-tests)
  - [Functional Tests](#functional-tests)
- [Change Log](#change-log)

---

## Introduction

D3D12's current depth-stencil texture support limits applications to read-only shader resource views (SRVs) or traditional depth-stencil views (DSVs) for rasterization output. This restriction prevents advanced rendering techniques that require direct read-write access to depth and stencil data from shader code outside of the traditional rasterization pipeline.

The feature supports accessing both depth and stencil planes independently through UAVs, providing full flexibility for depth-stencil manipulation scenarios.

---

## Goals

- Enable creation of UAVs for depth-stencil textures
- Support independent access to both depth and stencil planes
- Maintain compatibility with existing depth-stencil texture formats
- Provide efficient shader access patterns for both depth and stencil data
- Support all depth-stencil texture dimensions.
- Ensure feature works across all D3D12 hardware that supports UAVs
- Drivers should be able to continue to perform depth compression such as HiZ with metadata being resolved at state transition time.

---

## Non-Goals

- Modify existing DSV or SRV behavior for depth-stencil textures
- Support for depth-stencil UAVs in the graphics pipeline's output-merger stage
- Automatic synchronization between depth-stencil UAVs and traditional DSVs
- Support for UAVs of multisampled (MSAA) depth-stencil textures
---

## Overall Design

The depth-stencil UAV feature uses the existing D3D12 UAV system for creating UAVs of 1D and 2D textures:

1. **Plane-Specific Access**: Separate UAVs for Depth and Stencil planes, or a single interleaved UAV when `D32S8Interleaved` is TRUE.
2. **Format Compatibility**: UAVs automatically map to appropriate single-component formats (e.g., R32_FLOAT for depth, X[24|32]_TYPELESS_G8_* for stencil)
3. **Validation**: Comprehensive validation ensures UAVs are only created for appropriate depth-stencil formats

---

## API

Applications should use `ID3D12Device::CheckFeatureSupport` in conjunction with `D3D12_FEATURE_D3D12_OPTIONS_PREVIEW` and `D3D12_FEATURE_DATA_D3D12_OPTIONS_PREVIEW` to check device support for UAVs of depth-stencil textures:

```c++
typedef struct D3D12_FEATURE_DATA_D3D12_OPTIONS_PREVIEW
{
    // ... other preview fields ...
    _Out_  BOOL UAVOfDepthStencilSupported;
    _Out_  BOOL D32S8Interleaved;
} D3D12_FEATURE_DATA_D3D12_OPTIONS_PREVIEW;
```
- `UAVOfDepthStencilSupported`: When this is TRUE it indicates that UAVs are supported for depth-stencil textures in the following formats:
    - `DXGI_FORMAT_D32_FLOAT`
    - `DXGI_FORMAT_D16_UNORM`
    - `DXGI_FORMAT_D32_FLOAT_S8X24_UINT` (both depth and stencil planes)

Additionally, applications should use `D3D12Device::CheckFeatureSupport` and `D3D12_FEATURE_FORMAT_SUPPORT` to check supported UAV operations such as `D3D12_FORMAT_SUPPORT2_UAV_TYPED_LOAD`, `D3D12_FORMAT_SUPPORT2_UAV_TYPED_STORE` and `D3D12_FORMAT_SUPPORT2_UAV_ATOMIC_*` for the formats that they are interested in. These caps are reported against the UAV *view* format (e.g. `DXGI_FORMAT_R32_FLOAT`, `DXGI_FORMAT_R16_UNORM`, `DXGI_FORMAT_R32G32_UINT` for the interleaved D32S8 layout, or `DXGI_FORMAT_R32_FLOAT_X8X24_TYPELESS` / `DXGI_FORMAT_X32_TYPELESS_G8X24_UINT` for per-plane access) -- not against the `DXGI_FORMAT_D*` depth-stencil format of the resource itself.

Applications should use the existing UAV creation structures and APIs to create and bind UAVs of depth-stencil resources.

### Interleaved Depth-Stencil Format Support

Some hardware architectures store the `DXGI_FORMAT_D32_FLOAT_S8X24_UINT` format with depth and stencil values interleaved in memory rather than as separate planes. Applications must query hardware capabilities to determine the memory layout.

**Capability Query:**

The `D32S8Interleaved` field in `D3D12_FEATURE_DATA_D3D12_OPTIONS_PREVIEW` (shown above) indicates whether the hardware uses an interleaved depth-stencil layout.

Applications query this capability using `CheckFeatureSupport`:

```cpp
D3D12_FEATURE_DATA_D3D12_OPTIONS_PREVIEW options = {};
HRESULT hr = device->CheckFeatureSupport(
    D3D12_FEATURE_D3D12_OPTIONS_PREVIEW,
    &options,
    sizeof(options));

if (SUCCEEDED(hr) && options.D32S8Interleaved)
{
    // Hardware uses interleaved depth-stencil layout
    // Must use 8-byte UAV of plane 0
}
else
{
    // Hardware uses separate plane layout
    // Use separate UAVs for depth and stencil planes
}
```

**Interleaved Memory Layout:**

When `D32S8Interleaved` is `TRUE`, the memory layout for `DXGI_FORMAT_D32_FLOAT_S8X24_UINT` is standardized as follows:
- Each texel occupies 8 bytes (64 bits)
- **First DWORD (bits 0-31)**: 32-bit depth value (float)
- **Second DWORD (bits 32-63)**: Low byte (bits 32-39) contains 8-bit stencil value (uint), upper 24 bits (bits 40-63) **must be zero**

**Important:** When writing to the interleaved format bits 40-63 must be written as zero. Writing non-zero values to these bits results in undefined behavior.

**UAV Creation for Interleaved Layout:**

Applications must create a single 8-byte UAV targeting plane 0:

```cpp
// Create UAV for interleaved depth-stencil access
D3D12_UNORDERED_ACCESS_VIEW_DESC uavDesc = {};
uavDesc.Format = DXGI_FORMAT_R32G32_UINT; // 8-byte format
uavDesc.ViewDimension = D3D12_UAV_DIMENSION_TEXTURE2D;
uavDesc.Texture2D.MipSlice = 0;
uavDesc.Texture2D.PlaneSlice = 0; // Plane 0 contains interleaved data

device->CreateUnorderedAccessView(depthStencilBuffer.Get(), nullptr, 
    &uavDesc, interleavedUAVDescriptor);
```

---

## Hardware Compression

For many GPUs compression of depth-stencil resources is vital for maintaining performance. UAVs of depth-stencil resources should not disable compression and drivers should resolve any compression metadata during transition of the resource into UAV access state. Likewise, when returning to a depth state from UAV the driver has the opportunity compress the resource in an optimal format again.

---

## HLSL Usage

### Depth Plane Access

Depth plane UAVs are accessed as single-component textures with the appropriate format:

```hlsl
// Depth UAV declaration (format is inferred from resource)
RWTexture2D<float> DepthUAV : register(u0);

// Reading depth values
float currentDepth = DepthUAV[pixelCoord];

// Writing depth values
DepthUAV[pixelCoord] = newDepthValue;

// Atomic operations on depth (when using castable formats)
RWTexture2D<uint> DepthUAVInt : register(u1);
uint originalDepth;
InterlockedMin(DepthUAVInt[pixelCoord], newDepthAsUint, originalDepth);

```

### Stencil Plane Access

Stencil plane UAVs are accessed as 8-bit unsigned integer textures:

```hlsl
// Stencil UAV declaration
RWTexture2D<uint2> StencilUAV : register(u2);

// Reading stencil values
uint currentStencil = StencilUAV[pixelCoord].g;

// Writing stencil values (note: the red channel will be discarded)
StencilUAV[pixelCoord] = uint2(0, newStencilValue);

```

### Interleaved Layout Access

Shaders must perform 8-byte reads and writes, interpreting the surface as `uint2`:

```hlsl
RWTexture2D<uint2> InterleavedDepthStencilUAV : register(u0);

// Reading depth and stencil
uint2 depthStencilPacked = InterleavedDepthStencilUAV[pixelCoord];
float depth = asfloat(depthStencilPacked.x);  // First DWORD is depth
uint stencil = depthStencilPacked.y & 0xFF;   // Low byte of second DWORD is stencil

// Writing depth and stencil
float newDepth = 0.5f;
uint newStencil = 128;
uint2 newValue;
newValue.x = asuint(newDepth);                // Depth in first DWORD
newValue.y = newStencil & 0xFF;               // Stencil in low byte, upper 24 bits MUST be zero
InterleavedDepthStencilUAV[pixelCoord] = newValue;
```
---

## Format Support

The following depth-stencil formats can support UAV creation:

| DXGI Format | Depth UAV Format | Stencil UAV Format | Notes |
|-------------|------------------|-------------------|--------|
| DXGI_FORMAT_D32_FLOAT | DXGI_FORMAT_R32_FLOAT | N/A | Depth only |
| DXGI_FORMAT_D16_UNORM | DXGI_FORMAT_R16_UNORM | N/A | Depth only |
| DXGI_FORMAT_D32_FLOAT_S8X24_UINT | DXGI_FORMAT_R32_FLOAT_X8X24_TYPELESS | DXGI_FORMAT_X32_TYPELESS_G8X24_UINT | Both planes (separate layout) |
| DXGI_FORMAT_D32_FLOAT_S8X24_UINT | DXGI_FORMAT_R32G32_UINT | N/A | Interleaved layout (when `D32S8Interleaved` is TRUE) |

**Unsupported Formats:**
- `DXGI_FORMAT_D24_UNORM_S8_UINT` is **not supported** for UAV creation. Applications requiring UAV access to depth-stencil data with stencil support must use `DXGI_FORMAT_D32_FLOAT_S8X24_UINT` instead.

**Unsupported Configurations:**
- **Multisampled (MSAA) depth-stencil textures** are **not supported** for UAV creation. Depth-stencil resources must have `SampleDesc.Count` equal to 1 to be eligible for UAV access.

---

## Usage Examples

### Custom Depth Testing

```cpp
// Create depth-stencil resource
D3D12_RESOURCE_DESC depthDesc = {};
depthDesc.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE2D;
depthDesc.Width = 1920;
depthDesc.Height = 1080;
depthDesc.DepthOrArraySize = 1;
depthDesc.MipLevels = 1;
depthDesc.Format = DXGI_FORMAT_R32_TYPELESS; // Note: typeless 
depthDesc.Flags = D3D12_RESOURCE_FLAG_ALLOW_DEPTH_STENCIL | 
                  D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;

ComPtr<ID3D12Resource> depthBuffer;
device->CreateCommittedResource(&heapProps, D3D12_HEAP_FLAG_NONE,
    &depthDesc, D3D12_RESOURCE_STATE_DEPTH_WRITE, nullptr,
    IID_PPV_ARGS(&depthBuffer));

// Create Depth Stencil View
D3D12_DEPTH_STENCIL_VIEW_DESC dsvDesc = {};
dsvDesc.Format = DXGI_FORMAT_D32_FLOAT;
dsvDesc.ViewDimension = D3D12_DSV_DIMENSION_TEXTURE2D;
dsvDesc.Texture2D.MipSlice = 0;
dsvDesc.Flags = D3D12_DSV_FLAG_NONE

pDevice->CreateDepthStencilView(depthBuffer.Get(), &dsvDesc, dsvDescriptor);

// Create depth plane UAV
D3D12_UNORDERED_ACCESS_VIEW_DESC uavDesc = {};
uavDesc.Format = DXGI_FORMAT_R32_FLOAT;
uavDesc.ViewDimension = D3D12_UAV_DIMENSION_TEXTURE2D;
uavDesc.Texture2D.MipSlice = 0;
uavDesc.Texture2D.PlaneSlice = 0; // Depth plane

device->CreateUnorderedAccessView(depthBuffer.Get(), nullptr, 
    &uavDesc, depthUAVDescriptor);
```

### Stencil-Based Algorithm

```cpp
// Query for interleaved layout support
D3D12_FEATURE_DATA_D3D12_OPTIONS_PREVIEW options = {};
device->CheckFeatureSupport(D3D12_FEATURE_D3D12_OPTIONS_PREVIEW, &options, sizeof(options));

// Create depth-stencil resource with stencil
D3D12_RESOURCE_DESC depthStencilDesc = {};
depthStencilDesc.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE2D;
depthStencilDesc.Width = 1920;
depthStencilDesc.Height = 1080;
depthStencilDesc.DepthOrArraySize = 1;
depthStencilDesc.MipLevels = 1;
depthStencilDesc.Format = DXGI_FORMAT_D32_FLOAT_S8X24_UINT;
depthStencilDesc.Flags = D3D12_RESOURCE_FLAG_ALLOW_DEPTH_STENCIL | 
                         D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;

ComPtr<ID3D12Resource> depthStencilBuffer;
device->CreateCommittedResource(&heapProps, D3D12_HEAP_FLAG_NONE,
    &depthStencilDesc, D3D12_RESOURCE_STATE_DEPTH_WRITE, nullptr,
    IID_PPV_ARGS(&depthStencilBuffer));

if (options.D32S8Interleaved)
{
    // Create interleaved UAV for combined depth-stencil access
    D3D12_UNORDERED_ACCESS_VIEW_DESC interleavedUAVDesc = {};
    interleavedUAVDesc.Format = DXGI_FORMAT_R32G32_UINT;
    interleavedUAVDesc.ViewDimension = D3D12_UAV_DIMENSION_TEXTURE2D;
    interleavedUAVDesc.Texture2D.MipSlice = 0;
    interleavedUAVDesc.Texture2D.PlaneSlice = 0;
    
    device->CreateUnorderedAccessView(depthStencilBuffer.Get(), nullptr, 
        &interleavedUAVDesc, interleavedUAVDescriptor);
}
else
{
    // Create depth plane UAV
    D3D12_UNORDERED_ACCESS_VIEW_DESC depthUAVDesc = {};
    depthUAVDesc.Format = DXGI_FORMAT_R32_FLOAT_X8X24_TYPELESS;
    depthUAVDesc.ViewDimension = D3D12_UAV_DIMENSION_TEXTURE2D;
    depthUAVDesc.Texture2D.MipSlice = 0;
    depthUAVDesc.Texture2D.PlaneSlice = 0; // Depth plane
    
    device->CreateUnorderedAccessView(depthStencilBuffer.Get(), nullptr, 
        &depthUAVDesc, depthUAVDescriptor);
    
    // Create separate stencil plane UAV
    D3D12_UNORDERED_ACCESS_VIEW_DESC stencilUAVDesc = {};
    stencilUAVDesc.Format = DXGI_FORMAT_X32_TYPELESS_G8X24_UINT;
    stencilUAVDesc.ViewDimension = D3D12_UAV_DIMENSION_TEXTURE2D;
    stencilUAVDesc.Texture2D.MipSlice = 0;
    stencilUAVDesc.Texture2D.PlaneSlice = 1; // Stencil plane
    
    device->CreateUnorderedAccessView(depthStencilBuffer.Get(), nullptr, 
        &stencilUAVDesc, stencilUAVDescriptor);
}
```

---

## Validation

### Debug Layer Validation

The D3D12 debug layer performs comprehensive validation for depth-stencil UAVs:

**Resource Validation:**
- Verifies that resources have `D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS` flag
- Ensures depth-stencil resources are created with compatible formats
- Validates that plane slice corresponds to available planes in the format

**Format Validation:**
- Confirms UAV format is compatible with the specified plane
- Ensures format matches the expected component type (float for depth, uint for stencil)
- Validates format support on the current hardware

**State Validation:**
- Ensures resources are in compatible states when UAVs are used
- Validates transitions between depth-stencil and UAV states

### Runtime Validation

**Creation Validation:**
- Parameter validation for UAV descriptor fields
- Hardware capability checks for depth-stencil UAV support
- Format and dimension compatibility verification
- Multisampled (MSAA) depth-stencil textures are rejected for UAV creation

**Usage Validation:**
- Ensures proper synchronization between different access types

---

## Test Plan

### Conformance Tests
- Validate UAV creation for all supported depth-stencil formats
- Test plane-specific access for both depth and stencil components
- Verify format compatibility and validation error cases
- Test array texture support with multiple slices
- Basic read/write operations to depth and stencil planes
- Atomic operations on depth data
- State transition testing between DSV and UAV usage

### Functional Tests  
- Basic resource and view creation tests
- Negative testing for debug layer

---

## Change Log

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | September 2025 | Initial specification for depth texture UAVs |
| 1.1 | November 2025 | Spec out D32S8 interleaved |
| 1.2 | February 2026 | Consolidate UAVOfDepthPlaneSupported and UAVOfStencilPlaneSupported into single UAVOfDepthStencilSupported cap. Move caps to OPTIONS_EXPERIMENTAL. |
| 1.3 | May 2026 | Correct caps location to `D3D12_FEATURE_DATA_D3D12_OPTIONS_PREVIEW` to match the shipped implementation. Clarify that `D3D12_FEATURE_FORMAT_SUPPORT` UAV typed load/store caps are reported against the UAV view format, not the `DXGI_FORMAT_D*` resource format. |
