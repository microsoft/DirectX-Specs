# D3D12 Revised Create Views

Version 1.0

---

## Contents

- [D3D12 Revised Create Views](#d3d12-revised-create-views)
  - [Contents](#contents)
  - [Background](#background)
  - [Detailed Design](#detailed-design)
    - [API Design](#api-design)
      - [ID3D12Device16](#id3d12device16)
      - [Feature Check D3D12\_FEATURE\_DATA\_D3D12\_OPTIONS22.CreateByteOffsetViewsSupported](#feature-check-d3d12_feature_data_d3d12_options22createbyteoffsetviewssupported)
      - [D3D12\_SRV\_DIMENSION\_BUFFER\_BYTE\_OFFSET](#d3d12_srv_dimension_buffer_byte_offset)
      - [D3D12\_BUFFER\_SRV\_BYTE\_OFFSET](#d3d12_buffer_srv_byte_offset)
      - [D3D12\_SHADER\_RESOURCE\_VIEW\_DESC](#d3d12_shader_resource_view_desc)
      - [TryCreateShaderResourceView](#trycreateshaderresourceview)
      - [D3D12\_UAV\_DIMENSION\_BUFFER\_BYTE\_OFFSET](#d3d12_uav_dimension_buffer_byte_offset)
      - [D3D12\_BUFFER\_UAV\_BYTE\_OFFSET](#d3d12_buffer_uav_byte_offset)
      - [D3D12\_UNORDERED\_ACCESS\_VIEW\_DESC](#d3d12_unordered_access_view_desc)
      - [TryCreateUnorderedAccessView](#trycreateunorderedaccessview)
      - [TryCreateConstantBufferView](#trycreateconstantbufferview)
      - [TryCreateSampler2](#trycreatesampler2)
      - [TryCreateRenderTargetView](#trycreaterendertargetview)
      - [TryCreateDepthStencilView](#trycreatedepthstencilview)
      - [TryCreateSamplerFeedbackUnorderedAccessView](#trycreatesamplerfeedbackunorderedaccessview)
      - [D3D12.h Changes](#d3d12h-changes)
  - [DDI Design](#ddi-design)
    - [DDI Changes](#ddi-changes)
  - [Runtime validation](#runtime-validation)
  - [Debug layer validation](#debug-layer-validation)
  - [Changelog](#changelog)

---

## Background

Historically, D3D12 APIs for creating buffer views—such as `ID3D12Device::CreateShaderResourceView` and `ID3D12Device::CreateUnorderedAccessView`—were limited to element-based offsets rather than byte offsets. This approach constrained flexibility, particularly when suballocating buffers with non-power of 2 formats. As a result, applications often encountered challenges managing buffers whose sizes did not align with expected format types, leading to inefficient resource utilization and increased complexity.

With this revision, D3D12 now supports buffer views defined by byte offsets and sizes, aligning its capabilities with those already present in APIs like Vulkan. This enhancement enables more precise suballocation and resource management, leveraging hardware support that is already widely available. Additionally, the updated APIs provide improved error reporting through `HRESULT` return values, allowing developers to diagnose failures more effectively without relying on device removal as the sole indicator of issues.

This specification documents the completed changes that address both the flexibility of buffer view creation and the robustness of error handling in D3D12.

---

## Detailed Design

### API Design

**Summary of Proposed API Changes:**

- Introduce new versions of buffer view creation APIs: `TryCreateShaderResourceView`, `TryCreateUnorderedAccessView`, `TryCreateSampler2`, `TryCreateRenderTargetView`, `TryCreateConstantBufferView`, and `TryCreateDepthStencilView`, which returns a `HRESULT` for improved error reporting and validation.
- Introduces new `ID3D12Device` variant, `ID3D12DeviceExtended` to host these new methods.
- The new APIs for shader resource and unordered access views support specifying buffer views using byte offsets via new enum values (`D3D12_SRV_DIMENSION_BUFFER_BYTE_OFFSET` and `D3D12_UAV_DIMENSION_BUFFER_BYTE_OFFSET`) and corresponding struct fields.
  - The [Validation](#validation) in the offset is a big part of the change
- Starting with DDI version 121, the view descriptor's `ViewDimension` field can use these new enum values, enabling applications to define buffer views in terms of bytes rather than elements.
- These changes increase flexibility and clarity for buffer suballocation and align D3D12 with capabilities already present in other graphics APIs.
- Raw SRV/UAV buffers may be created with the new dimension, but they behave the same as before
  - When `D3D12_BUFFER_SRV_FLAG_RAW` is specified, offset must be 16 byte aligned (aka `D3D12_RAW_UAV_SRV_BYTE_ALIGNMENT`)

---

#### ID3D12Device16
These new methods are available in ID3D12Device16 interfaces or newer

```c++
class ID3D12Device16 : public ID3D12Device15
{
public:
    virtual HRESULT TryCreateShaderResourceView(
        ID3D12Resource* pResource,
        const D3D12_SHADER_RESOURCE_VIEW_DESC* pDesc,
        D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor
    ) = 0;

    virtual HRESULT TryCreateUnorderedAccessView(
        ID3D12Resource* pResource,
        ID3D12Resource* pCounterResource,
        const D3D12_UNORDERED_ACCESS_VIEW_DESC* pDesc,
        D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor
    ) = 0;

    virtual HRESULT TryCreateConstantBufferView(
        const D3D12_CONSTANT_BUFFER_VIEW_DESC* pDesc,
        D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor
    ) = 0;

    virtual HRESULT TryCreateSampler2(
        const D3D12_SAMPLER_DESC2* pDesc,
        D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor
    ) = 0;

    virtual HRESULT TryCreateRenderTargetView(
        ID3D12Resource* pResource,
        const D3D12_RENDER_TARGET_VIEW_DESC* pDesc,
        D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor
    ) = 0;

    virtual HRESULT TryCreateDepthStencilView(
        ID3D12Resource* pResource,
        const D3D12_DEPTH_STENCIL_VIEW_DESC* pDesc,
        D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor
    ) = 0;

    virtual HRESULT TryCreateSamplerFeedbackUnorderedAccessView(
        ID3D12Resource* pTargetedResource,
        ID3D12Resource* pFeedbackResource,
        D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor
    ) = 0;
};
```


#### Feature Check D3D12_FEATURE_DATA_D3D12_OPTIONS22.CreateByteOffsetViewsSupported
Applications can check for the support for creating views based on byte offset with the following check. This will return true when the driver DDI is above 121, and false if not.

```c++
typedef 
enum D3D12_FEATURE
    {
        // ... removed for brevity
        D3D12_FEATURE_DATA_D3D12_OPTIONS22	= 65 // Options 22
    } 	D3D12_FEATURE;

    typedef struct D3D12_FEATURE_DATA_D3D12_OPTIONS22
    {
        //... removed for brevity
        _Out_  BOOL CreateByteOffsetViewsSupported;
    } 	D3D12_FEATURE_DATA_D3D12_OPTIONS22;

    // Example usage
bool CheckFeatureSupport()
{
    // m_Device is ID3D12Device
    D3D12_FEATURE_DATA_D3D12_OPTIONS22 createByteOffset = {};
    HRESULT hr = m_Device->CheckFeatureSupport(D3D12_FEATURE_D3D12_OPTIONS22,
        &createByteOffset, sizeof(createByteOffset));
    
    if (FAILED(hr)) {
        WEX::Logging::Log::Comment(L"Failed to query D3D12_FEATURE_CREATE_BYTE_OFFSET_VIEWS");
        return false;
    }
    
    return createByteOffset.CreateByteOffsetViewsSupported;
}
```
---

#### D3D12_SRV_DIMENSION_BUFFER_BYTE_OFFSET

A new member value for `D3D12_SHADER_RESOURCE_VIEW_DESC::ViewDimension`. When specified, `D3D12_SHADER_RESOURCE_VIEW_DESC::BufferByteOffset` is used for determining the dimension of the view.

```c++
typedef 
enum D3D12_SRV_DIMENSION
{
    D3D12_SRV_DIMENSION_UNKNOWN = 0,
    D3D12_SRV_DIMENSION_BUFFER = 1,
    D3D12_SRV_DIMENSION_TEXTURE1D = 2,
    D3D12_SRV_DIMENSION_TEXTURE1DARRAY = 3,
    D3D12_SRV_DIMENSION_TEXTURE2D = 4,
    D3D12_SRV_DIMENSION_TEXTURE2DARRAY = 5,
    D3D12_SRV_DIMENSION_TEXTURE2DMS = 6,
    D3D12_SRV_DIMENSION_TEXTURE2DMSARRAY = 7,
    D3D12_SRV_DIMENSION_TEXTURE3D = 8,
    D3D12_SRV_DIMENSION_TEXTURECUBE = 9,
    D3D12_SRV_DIMENSION_TEXTURECUBEARRAY = 10,
    D3D12_SRV_DIMENSION_RAYTRACING_ACCELERATION_STRUCTURE = 11,
    D3D12_SRV_DIMENSION_BUFFER_BYTE_OFFSET = 12 // <--- New field
} D3D12_SRV_DIMENSION;
```

---

#### D3D12_BUFFER_SRV_BYTE_OFFSET

Used by `D3D12_SHADER_RESOURCE_VIEW_DESC` in conjunction with the new enum member `D3D12_SRV_DIMENSION_BUFFER_BYTE_OFFSET`.

```c++
typedef struct D3D12_BUFFER_SRV_BYTE_OFFSET
{
  UINT64 Offset;
  UINT64 Size;
  UINT StructureByteStride;
  D3D12_BUFFER_SRV_FLAGS Flags;
} D3D12_BUFFER_SRV_BYTE_OFFSET;
```

**Members:**

- `Offset` (UINT64): The offset, in bytes, from the parent resource's memory where the created view begins. See [Validation](#validation) for alignment and bounds requirements.
- `Size` (UINT64): The size, in bytes, of the buffer view. This defines how much of the resource is accessible through this view, starting from the specified `Offset`. When 0 is specified, the range from `Offset` to the end of the buffer is used.
- `StructureByteStride` (UINT): The size, in bytes, of each structure element in the buffer. Used when the buffer is viewed as a structured buffer. If not structured, set to 0. This value follows the rules set out by [HLSL](https://github.com/microsoft/DirectXShaderCompiler/wiki/16-Bit-Scalar-Types#structure-alignment)
- `Flags` (D3D12_BUFFER_SRV_FLAGS): Flags specifying additional options for the buffer view, such as whether the buffer is to be interpreted as raw or structured data.

---

#### D3D12_SHADER_RESOURCE_VIEW_DESC

This remains the same as the [MSDN documentation](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_shader_resource_view_desc), with a newly added member in the union, `BufferByteOffset`.

```c++
typedef struct D3D12_SHADER_RESOURCE_VIEW_DESC
{
  DXGI_FORMAT Format;
  D3D12_SRV_DIMENSION ViewDimension;
  UINT Shader4ComponentMapping;
  union 
    {
        D3D12_BUFFER_SRV Buffer;
        D3D12_TEX1D_SRV Texture1D;
        D3D12_TEX1D_ARRAY_SRV Texture1DArray;
        D3D12_TEX2D_SRV Texture2D;
        D3D12_TEX2D_ARRAY_SRV Texture2DArray;
        D3D12_TEX2DMS_SRV Texture2DMS;
        D3D12_TEX2DMS_ARRAY_SRV Texture2DMSArray;
        D3D12_TEX3D_SRV Texture3D;
        D3D12_TEXCUBE_SRV TextureCube;
        D3D12_TEXCUBE_ARRAY_SRV TextureCubeArray;
        D3D12_RAYTRACING_ACCELERATION_STRUCTURE_SRV RaytracingAccelerationStructure;
        D3D12_BUFFER_SRV_BYTE_OFFSET BufferByteOffset; // <--- New Field
    };
} D3D12_SHADER_RESOURCE_VIEW_DESC;
```

---

#### TryCreateShaderResourceView

```c++
HRESULT ID3D12DeviceExtended::TryCreateShaderResourceView(
  ID3D12Resource                        *pResource,
  const D3D12_SHADER_RESOURCE_VIEW_DESC *pDesc,
  D3D12_CPU_DESCRIPTOR_HANDLE           DestDescriptor
);
```
A revved version of [CreateShaderResourceView](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12device-createshaderresourceview) that returns an `HRESULT` for improved error reporting and validation. The parameters and descriptor structure remain unchanged.

**Supported return values:**
- `S_OK` – Success, no errors
- `E_INVALIDARG` – Invalid descriptor handle or out of range

---

#### D3D12_UAV_DIMENSION_BUFFER_BYTE_OFFSET

A new member value for `D3D12_UNORDERED_ACCESS_VIEW_DESC::ViewDimension`. When specified, `D3D12_UNORDERED_ACCESS_VIEW_DESC::BufferByteOffset` is used for determining the dimension of the view.

```c++
typedef 
enum D3D12_UAV_DIMENSION
{
    D3D12_UAV_DIMENSION_UNKNOWN = 0,
    D3D12_UAV_DIMENSION_BUFFER = 1,
    D3D12_UAV_DIMENSION_TEXTURE1D = 2,
    D3D12_UAV_DIMENSION_TEXTURE1DARRAY = 3,
    D3D12_UAV_DIMENSION_TEXTURE2D = 4,
    D3D12_UAV_DIMENSION_TEXTURE2DARRAY = 5,
    D3D12_UAV_DIMENSION_TEXTURE2DMS = 6,
    D3D12_UAV_DIMENSION_TEXTURE2DMSARRAY = 7,
    D3D12_UAV_DIMENSION_TEXTURE3D = 8,
    D3D12_UAV_DIMENSION_BUFFER_BYTE_OFFSET = 9 // <--- New field
} D3D12_UAV_DIMENSION;
```

---

#### D3D12_BUFFER_UAV_BYTE_OFFSET

Used by `D3D12_UNORDERED_ACCESS_VIEW_DESC` in conjunction with the new enum member `D3D12_UAV_DIMENSION_BUFFER_BYTE_OFFSET`.

```c++
typedef struct D3D12_BUFFER_UAV_BYTE_OFFSET
{
  UINT64 Offset;
  UINT64 Size;
  UINT StructureByteStride;
  UINT64 CounterOffsetInBytes;
  D3D12_BUFFER_UAV_FLAGS Flags;
} D3D12_BUFFER_UAV_BYTE_OFFSET;
```

**Members:**

- `Offset` (UINT64): The offset, in bytes, from the parent resource's memory where the created view begins. See [Validation](#validation) for alignment and bounds requirements.
- `Size` (UINT64): The size, in bytes, of the buffer view. This defines how much of the resource is accessible through this view, starting from the specified `Offset`. When 0 is specified, the range from `Offset` to the end of the buffer is used.
- `StructureByteStride` (UINT): The size, in bytes, of each structure element in the buffer. Used when the buffer is viewed as a structured buffer. If not structured, set to 0. This value follows the rules set out by [HLSL](https://github.com/microsoft/DirectXShaderCompiler/wiki/16-Bit-Scalar-Types#structure-alignment)
- `CounterOffsetInBytes` (UINT64): The offset, in bytes, to the counter resource if the buffer is using a counter (for append/consume buffers). If not used, set to 0.
- `Flags` (D3D12_BUFFER_UAV_FLAGS): Flags specifying additional options for the buffer view.

---

#### D3D12_UNORDERED_ACCESS_VIEW_DESC

This remains the same as the [MSDN documentation](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_unordered_access_view_desc), with a newly added member in the union, `BufferByteOffset`.

```c++
typedef struct D3D12_UNORDERED_ACCESS_VIEW_DESC
{
  DXGI_FORMAT Format;
  D3D12_UAV_DIMENSION ViewDimension;
  union 
    {
      D3D12_BUFFER_UAV Buffer;
      D3D12_TEX1D_UAV Texture1D;
      D3D12_TEX1D_ARRAY_UAV Texture1DArray;
      D3D12_TEX2D_UAV Texture2D;
      D3D12_TEX2D_ARRAY_UAV Texture2DArray;
      D3D12_TEX3D_UAV Texture3D;
      D3D12_BUFFER_UAV_BYTE_OFFSET BufferByteOffset; // <--- New Field
    };
} D3D12_UNORDERED_ACCESS_VIEW_DESC;
```

---

#### TryCreateUnorderedAccessView

```c++
HRESULT ID3D12DeviceExtended::TryCreateUnorderedAccessView(
  ID3D12Resource                        *pResource,
  ID3D12Resource                        *pCounterResource,
  const D3D12_UNORDERED_ACCESS_VIEW_DESC *pDesc,
  D3D12_CPU_DESCRIPTOR_HANDLE           DestDescriptor
);
```
A revved version of [CreateUnorderedAccessView](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12device-createunorderedaccessview) that returns an `HRESULT` for improved error reporting and validation. The parameters and descriptor structure remain unchanged.

**Supported return values:**
- `S_OK` – Success, no errors
- `E_INVALIDARG` – Invalid descriptor handle or out of range
---

#### TryCreateConstantBufferView

```c++
HRESULT ID3D12DeviceExtended::TryCreateConstantBufferView(
  const D3D12_CONSTANT_BUFFER_VIEW_DESC* pDesc,
  D3D12_CPU_DESCRIPTOR_HANDLE            DestDescriptor
);
```
A revved version of [CreateConstantBufferView](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12device-createconstantbufferview) that returns an `HRESULT` for improved error reporting and validation. The parameters and descriptor structure remain unchanged.

**Supported return values:**
- `S_OK` – Success, no errors
- `E_INVALIDARG` – Invalid descriptor handle or out of range

---

#### TryCreateSampler2

```c++
HRESULT ID3D12DeviceExtended::TryCreateSampler2(
  const D3D12_SAMPLER_DESC2*   pDesc,
  D3D12_CPU_DESCRIPTOR_HANDLE  DestDescriptor
);
```
A revved version of [CreateSampler2](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/ResourceBinding.md#sampler) that returns an `HRESULT` for improved error reporting and validation. The parameters and descriptor structure remain unchanged.

**Supported return values:**
- `S_OK` – Success, no errors
- `E_INVALIDARG` – Invalid descriptor handle or out of range

---

#### TryCreateRenderTargetView

```c++
HRESULT ID3D12DeviceExtended::TryCreateRenderTargetView(
  ID3D12Resource*                      pResource,
  const D3D12_RENDER_TARGET_VIEW_DESC* pDesc,
  D3D12_CPU_DESCRIPTOR_HANDLE          DestDescriptor
);
```
A revved version of [CreateRenderTargetView](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12device-createrendertargetview) that returns an `HRESULT` for improved error reporting and validation. The parameters and descriptor structure remain unchanged.

**Supported return values:**
- `S_OK` – Success, no errors
- `E_INVALIDARG` – Invalid descriptor handle or out of range

---

#### TryCreateDepthStencilView

```c++
HRESULT ID3D12DeviceExtended::TryCreateDepthStencilView(
  ID3D12Resource*                      pResource,
  const D3D12_DEPTH_STENCIL_VIEW_DESC* pDesc,
  D3D12_CPU_DESCRIPTOR_HANDLE          DestDescriptor
);
```
A revved version of [CreateDepthStencilView](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12device-createdepthstencilview) that returns an `HRESULT` for improved error reporting and validation. The parameters and descriptor structure remain unchanged.

**Supported return values:**
- `S_OK` – Success, no errors
- `E_INVALIDARG` – Invalid descriptor handle or out of range

---

#### TryCreateSamplerFeedbackUnorderedAccessView

```c++
HRESULT ID3D12DeviceExtended::TryCreateSamplerFeedbackUnorderedAccessView(
  ID3D12Resource              *pTargetedResource,
  ID3D12Resource              *pFeedbackResource,
  D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor
);
```
A revved version of [CreateSamplerFeedbackUnorderedAccessView](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12device8-createsamplerfeedbackunorderedaccessview) that returns an `HRESULT` for improved error reporting and validation. The parameters and descriptor structure remain unchanged.

**Supported return values:**
- `S_OK` – Success, no errors
- `E_INVALIDARG` – Invalid descriptor handle or out of range

---

#### D3D12.h Changes
This lists all the changes to `d3d12.h`
```c++
// d3d12.h

//
// SRV changes
//

// New struct
typedef struct D3D12_BUFFER_SRV_BYTE_OFFSET
{
  UINT64 Offset;
  UINT64 Size;
  UINT StructureByteStride;
  D3D12_BUFFER_SRV_FLAGS Flags;
} D3D12_BUFFER_SRV_BYTE_OFFSET;

// Added a new element to enum
typedef 
enum D3D12_SRV_DIMENSION
{
    D3D12_SRV_DIMENSION_UNKNOWN = 0,
    D3D12_SRV_DIMENSION_BUFFER = 1,
    // ... removed for brevity
    D3D12_SRV_DIMENSION_BUFFER_BYTE_OFFSET = 12 // <--- New field
} D3D12_SRV_DIMENSION;

// New union member BufferByteOffset
typedef struct D3D12_SHADER_RESOURCE_VIEW_DESC
{
  DXGI_FORMAT Format;
  D3D12_SRV_DIMENSION ViewDimension; // Set this to D3D12_SRV_DIMENSION_BUFFER_BYTE_OFFSET for using bytes
  UINT Shader4ComponentMapping;
  union 
    {
      // ... Removed for brevity
      D3D12_BUFFER_SRV_BYTE_OFFSET BufferByteOffset; // <--- New Field
    };
} D3D12_SHADER_RESOURCE_VIEW_DESC;

//
// UAV changes
//

// New struct
typedef struct D3D12_BUFFER_UAV_BYTE_OFFSET
{
  UINT64 Offset;
  UINT64 Size;
  UINT StructureByteStride;
  UINT64 CounterOffsetInBytes;
  D3D12_BUFFER_UAV_FLAGS Flags;
} D3D12_BUFFER_UAV_BYTE_OFFSET;

// Added a new element to enum
typedef 
enum D3D12_UAV_DIMENSION
{
    D3D12_UAV_DIMENSION_UNKNOWN = 0,
    D3D12_UAV_DIMENSION_BUFFER = 1,
    // ... removed for brevity
    D3D12_UAV_DIMENSION_BUFFER_BYTE_OFFSET = 9 // <--- New field
} D3D12_UAV_DIMENSION;

typedef struct D3D12_UNORDERED_ACCESS_VIEW_DESC
{
  DXGI_FORMAT Format;
  D3D12_UAV_DIMENSION ViewDimension;
  union 
    {
      // ... Removed for brevity
      D3D12_BUFFER_UAV_BYTE_OFFSET BufferByteOffset; // <--- New Field
    };
};

// New ID3D12Device with newly revved methods
class ID3D12DeviceExtended : public ID3D12Device14
{
public:
  HRESULT TryCreateShaderResourceView(
    ID3D12Resource* pResource,
    const D3D12_SHADER_RESOURCE_VIEW_DESC* pDesc,
    D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor
  );

  HRESULT TryCreateUnorderedAccessView(
    ID3D12Resource* pResource,
    ID3D12Resource* pCounterResource,
    const D3D12_UNORDERED_ACCESS_VIEW_DESC* pDesc,
    D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor
  );

  HRESULT TryCreateConstantBufferView(
    const D3D12_CONSTANT_BUFFER_VIEW_DESC* pDesc,
    D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor
  );

  HRESULT TryCreateSampler2(
    const D3D12_SAMPLER_DESC2* pDesc,
    D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor
  );

  HRESULT TryCreateRenderTargetView(
    ID3D12Resource* pResource,
    const D3D12_RENDER_TARGET_VIEW_DESC* pDesc,
    D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor
  );

  HRESULT TryCreateDepthStencilView(
    ID3D12Resource* pResource,
    const D3D12_DEPTH_STENCIL_VIEW_DESC* pDesc,
    D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor
  );

  HRESULT TryCreateSamplerFeedbackUnorderedAccessView(
        ID3D12Resource* pTargetedResource,
        ID3D12Resource* pFeedbackResource,
        D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor
  );
};
```

---

## DDI Design

The DDI design closely mirrors the API design, but there are no changes for allowing driver error reporting. Given that most of the `D3D12DDIARG_CREATE_thing_VIEW` struct sizes are not changing, only UAV creation methods will be revved. Drivers report support via the newly revved `D3D12DDI_D3D12_OPTIONS_DATA_0121::ViewCreationByteOffsetSupported`.

If the driver DDI version is greater than or equal to 121, the runtime will call the new DDI method instead of the old one.

---

### DDI Changes

```c++
//
// Common changes
//

// d3d12umddi.h

typedef enum D3D12DDI_RESOURCE_DIMENSION
{
    D3D12DDI_RD_BUFFER      = 1,
    D3D12DDI_RD_TEXTURE1D   = 2,
    D3D12DDI_RD_TEXTURE2D   = 3,
    D3D12DDI_RD_TEXTURE3D   = 4,
    D3D12DDI_RD_TEXTURECUBE = 5,
    D3D12DDI_RD_RAYTRACING_ACCELERATION_STRUCTURE_0042 = 6,
    D3D12DDI_RD_BUFFER_BYTE_OFFSET_0121 = 7, // --- New field
} D3D12DDI_RESOURCE_DIMENSION;

//
//  Changes for SRV creation
//

// New struct
typedef struct D3D12DDIARG_BUFFER_BYTE_OFFSET_SHADER_RESOURCE_VIEW_0121
{
    UINT64 Offset;
    UINT64 Size;
    UINT StructureByteStride; 
    D3D12DDI_BUFFER_SRV_FLAGS Flags;
} D3D12DDIARG_BUFFER_BYTE_OFFSET_SHADER_RESOURCE_VIEW_0121;

// Add a new member to this struct (size of struct stays the same)
typedef struct D3D12DDIARG_CREATE_SHADER_RESOURCE_VIEW_0002
{
    D3D12DDI_HRESOURCE    hDrvResource;
    DXGI_FORMAT           Format;
    D3D12DDI_RESOURCE_DIMENSION ResourceDimension; // Allows new usage of D3D12DDI_RD_BUFFER_BYTE_OFFSET_0121
    UINT                  Shader4ComponentMapping;

    union
    {
        D3D12DDIARG_BUFFER_SHADER_RESOURCE_VIEW                                 Buffer;
        D3D12DDIARG_TEX1D_SHADER_RESOURCE_VIEW                                  Tex1D;
        D3D12DDIARG_TEX2D_SHADER_RESOURCE_VIEW_0002                             Tex2D;
        D3D12DDIARG_TEX3D_SHADER_RESOURCE_VIEW                                  Tex3D;
        D3D12DDIARG_TEXCUBE_SHADER_RESOURCE_VIEW                                TexCube;
        D3D12DDIARG_RAYTRACING_ACCELERATION_STRUCTURE_SHADER_RESOURCE_VIEW_0042 RaytracingAccelerationStructure;
        D3D12DDIARG_BUFFER_BYTE_OFFSET_SHADER_RESOURCE_VIEW_0121                     BufferByteOffset; // --- New field
    };
} D3D12DDIARG_CREATE_SHADER_RESOURCE_VIEW_0002;

//
//  Changes for UAV creation
//

// New struct
typedef struct D3D12DDIARG_BUFFER_OFFSET_BYTE_UNORDERED_ACCESS_VIEW_0121
{
    D3D12DDI_HRESOURCE        hDrvCounterResource; 
    UINT64                    Offset;
    UINT64                    Size;
    UINT64                    CounterOffsetInBytes;
    UINT                      StructureByteStride; 
    D3D12DDI_BUFFER_UAV_FLAGS Flags;
} D3D12DDIARG_BUFFER_OFFSET_BYTE_UNORDERED_ACCESS_VIEW_0121;

// Revved from D3D12DDIARG_CREATE_UNORDERED_ACCESS_VIEW_0002
typedef struct D3D12DDIARG_CREATE_UNORDERED_ACCESS_VIEW_0121
{
    D3D12DDI_HRESOURCE    hDrvResource;
    DXGI_FORMAT           Format;                 
    D3D12DDI_RESOURCE_DIMENSION ResourceDimension; // Allows new usage of D3D12DDI_RD_BUFFER_BYTE_OFFSET_0121
    union
    {
        D3D12DDIARG_BUFFER_UNORDERED_ACCESS_VIEW            Buffer;
        D3D12DDIARG_TEX1D_UNORDERED_ACCESS_VIEW             Tex1D;
        D3D12DDIARG_TEX2D_UNORDERED_ACCESS_VIEW_0002        Tex2D;
        D3D12DDIARG_TEX3D_UNORDERED_ACCESS_VIEW             Tex3D;
        D3D12DDIARG_BUFFER_OFFSET_BYTE_UNORDERED_ACCESS_VIEW_0121 BufferByteOffset; // --- New field
    };
} D3D12DDIARG_CREATE_UNORDERED_ACCESS_VIEW_0121;

// Revved from PFND3D12DDI_CREATE_UNORDERED_ACCESS_VIEW_0002
typedef void ( APIENTRY* PFND3D12DDI_CREATE_UNORDERED_ACCESS_VIEW_0121 )( D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATE_UNORDERED_ACCESS_VIEW_0121 *, _In_ D3D12DDI_CPU_DESCRIPTOR_HANDLE DestDescriptor );

//
// Core functionality revs
//

// Revved from D3D12DDI_DEVICE_FUNCS_CORE_0116
typedef struct D3D12DDI_DEVICE_FUNCS_CORE_0121
{
  // ... Removed for brevity
  PFND3D12DDI_CREATE_UNORDERED_ACCESS_VIEW_0121   pfnCreateUnorderedAccessView; // Only the create UAV needs to be revved
} D3D12DDI_DEVICE_FUNCS_CORE_0121;

// Revved from D3D12DDI_D3D12_OPTIONS_DATA_0089, used to report support
typedef struct D3D12DDI_D3D12_OPTIONS_DATA_0121
{
    // Same as D3D12DDI_D3D12_OPTIONS_DATA_0089
    BOOL ViewCreationByteOffsetSupported;
} D3D12DDI_D3D12_OPTIONS_DATA_0121;
```

---

## Runtime validation

The following validation will be performed by the runtime:

- Ensure no out-of-bounds access:
  - `ViewOffset + Size` must be less than resource size.
  - In the case of structured buffers, `Size` must be wholly dividable by `StructureByteStride`
  - In the case of non-structured buffers, `Size` must be aligned to the format size.
- With the new change, offset may not be aligned to element size (which is intended), but for correctness and potential performance gains:
  - The final memory address, obtained from heap offset + view offset, must have the correct alginments below
  - Potential alignment with HLSL [ByteAddressBuffer Alignment Proposal](https://github.com/microsoft/hlsl-specs/pull/557)
  - For buffers:
    - Formats with a size that is a power of 2 should have `Offset` aligned to format size (e.g., R32G32B32A32_FLOAT is 16 bytes, so it requires 16-byte alignment).
    - Formats that is not a power of 2 should have `Offset` aligned to the channel size of the format (e.g., R32G32B32_FLOAT is 12 bytes, but requires a 4-byte alignment).
  - For structured buffers:
    - Offset must be aligned to the highest divisible alignment of the following bytes [2,4,8,16].
      - This works out to be min(1 << ffs(stride),16)
      - A 12 byte structure would need a 4 byte alignment final memory offset
      - A 24 byte structure would need an 8 byte alignment final memory offset
      - A 14 byte structure would need a 2 byte alignment final memory offset
- When `D3D12_BUFFER_SRV_FLAG_RAW` is specified, offset must be 16 byte aligned
  - Aligned to `D3D12_RAW_UAV_SRV_BYTE_ALIGNMENT`
- To ensure that the new byte offset is only used when drivers support this
  - Validate against driver reported value if feature is supported

The example below demonstrates the relationship between the offset alignment rules with a given HLSL structured buffer 
```c++
// In the HLSL file...
struct A { uint16_t x, y; }; // Size of 4 bytes, aligned by 2
StructuredBuffer<A> mySB;

struct B { uint64_t x; uint16_t y; }; // size of 16 bytes, aligned by 8

  // Somewhere in C++ code when creating views
  // Creating a view of Struct A
  D3D12_SHADER_RESOURCE_VIEW_DESC srvDescA = {};
  srvDescA.Format = DXGI_FORMAT_UNKNOWN; // Specify structured buffer 
  srvDescA.ViewDimension = D3D12_SRV_DIMENSION_BUFFER_BYTE_OFFSET;
  srvDescA.BufferByteOffset.Offset = 4; // Since size is 4, this offset must be aligned by 4 based on the Validation rules above for structured buffers
  srvDescA.BufferByteOffset.Size = 4 * 16; // Size must be a multiple of StructureByteStride
  srvDescA.BufferByteOffset.StructureByteStride = 4;

  ID3D12DeviceExtended* extendedDevice;
  pDevice->QueryInterface(&extendedDevice); // Convert ID3D12Device to ID3D12DeviceExtended
  if(extendedDevice->TryCreateShaderViewResource(pResource, nullptr, &srvDescA, heap->GetCPUDescriptorHandleForHeapStart()) != S_OK)
  {
    // Error
  }
  if(extendedDevice->TryCreateShaderViewResource(pResource, nullptr, &srvDescB, heap->GetCPUDescriptorHandleForHeapStart()) != S_OK)
  {
    // Error
  }

  ---

## Example Usage

Below is a complete example demonstrating how to create a shader resource view with byte offset using the new API:

```cpp
// Assume pDevice is a valid ID3D12Device pointer
ID3D12DeviceExtended* pDeviceExtended = nullptr;
HRESULT hr = pDevice->QueryInterface(IID_PPV_ARGS(&pDeviceExtended));
if (SUCCEEDED(hr))
{
  D3D12_SHADER_RESOURCE_VIEW_DESC srvDesc = {};
  srvDesc.Format = DXGI_FORMAT_UNKNOWN;
  srvDesc.ViewDimension = D3D12_SRV_DIMENSION_BUFFER_BYTE_OFFSET;
  srvDesc.BufferByteOffset.Offset = 64; // 64-byte offset
  srvDesc.BufferByteOffset.Size = 256;  // 256 bytes
  srvDesc.BufferByteOffset.StructureByteStride = 16; // Structured buffer, 16 bytes per element
  srvDesc.BufferByteOffset.Flags = D3D12_BUFFER_SRV_FLAG_NONE;

  D3D12_CPU_DESCRIPTOR_HANDLE handle = heap->GetCPUDescriptorHandleForHeapStart();
  hr = pDeviceExtended->TryCreateShaderResourceView(pResource, &srvDesc, handle);
  if (FAILED(hr))
  {
    // Handle error
  }
  pDeviceExtended->Release();
}
```

---

## Debug layer validation

- The debug layer runs the same validation as the runtime. However, in debug mode developers can enable GBV.
- GPU Based Validation (GBV) provides a more comprehensive validation by running it against the DXIL bytecode.
- Debug layer validation will be updated at a later time.

---

## Changelog

- 7/22/2025 - Initial spec written with multiple proposed solutions
- 7/24/2025 - Proposed solution chosen and expanded into the first draft of the spec
- 7/24/2025 - Added a new interface, ID3D12DeviceExtended, to host new methods
- 8/8/2025 - Revised structured buffer offset alignment to 2,4,8, and 16 bytes.
- 8/14/2025 - Added HLSL example, expanded on raw buffer.
- 8/18/2025 - Removed DXGI_ERROR_UNSUPPORTED from return calls to TryCreate*
- 10/13/2025 - Moved to DDI 121. Added feature check. Renamed TryCreateSampler to TryCreateSampler2. Moved from ID3D12DeviceExtended to ID3D12Device16 because of naming confusion.