<h1>VulkanOn12 Spec(s)</h1>

v1.0

---


<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [Intro](#intro)
- [Format List Casting](#format-list-casting)
  - [Definition](#definition)
  - [DDI](#ddi)
  - [Tests: HLK Conformance](#tests-hlk-conformance)
    - [`D3DConf_12_RelaxedFormatCasting::FormatListCasting`](#d3dconf_12_relaxedformatcastingformatlistcasting)
- [Unrestricted Buffer Texture Copy Row Pitch and Offset](#unrestricted-buffer-texture-copy-row-pitch-and-offset)
  - [Definition](#definition-1)
  - [DDI](#ddi-1)
  - [Tests: HLK Conformance](#tests-hlk-conformance-1)
    - [`D3DConf_12_UnrestrictedAlignmentOffsetCopy::CopyWithoutRowPitchAlignment`](#d3dconf_12_unrestrictedalignmentoffsetcopycopywithoutrowpitchalignment)
    - [`D3DConf_12_UnrestrictedAlignmentOffsetCopy::CopyWithoutOffsetAlignment`](#d3dconf_12_unrestrictedalignmentoffsetcopycopywithoutoffsetalignment)
    - [`D3DConf_12_UnrestrictedAlignmentOffsetCopy::CopyWithoutRowPitchAndOffsetAlignment`](#d3dconf_12_unrestrictedalignmentoffsetcopycopywithoutrowpitchandoffsetalignment)
- [Texture Copy Between Inequal Dimension Textures](#texture-copy-between-inequal-dimension-textures)
  - [Definition](#definition-2)
  - [DDI](#ddi-2)
  - [Tests: HLK Conformance](#tests-hlk-conformance-2)
    - [`Copy3Dto2D`](#copy3dto2d)
    - [`Copy3Dto1D`](#copy3dto1d)
    - [`Copy2Dto1D`](#copy2dto1d)
- [Unrestricted Vertex Element Alignment](#unrestricted-vertex-element-alignment)
  - [Definition](#definition-3)
  - [DDI](#ddi-3)
  - [Tests: HLK Conformance](#tests-hlk-conformance-3)
    - [`D3DConf_12_UnrestrictedVertexAlignment::UnalignedVertexBuffer`](#d3dconf_12_unrestrictedvertexalignmentunalignedvertexbuffer)
- [Inverted viewports](#inverted-viewports)
  - [Definition](#definition-4)
  - [DDI](#ddi-4)
  - [Tests: HLK Conformance](#tests-hlk-conformance-4)
    - [`D3DConf_12_InvertedViewports::InvertedHeight`](#d3dconf_12_invertedviewportsinvertedheight)
    - [`D3DConf_12_InvertedViewports::InvertedDepth`](#d3dconf_12_invertedviewportsinverteddepth)
- [Alpha blend factor](#alpha-blend-factor)
  - [Definition](#definition-5)
  - [DDI](#ddi-5)
  - [Tests: HLK Conformance](#tests-hlk-conformance-5)
    - [`D3DConf_12_Blend::AlphaBlendFactor`](#d3dconf_12_blendalphablendfactor)
- [Independent Front/Back Stencil Refs and Masks](#independent-frontback-stencil-refs-and-masks)
  - [Definition](#definition-6)
  - [DDI](#ddi-6)
  - [Tests: HLK Conformance](#tests-hlk-conformance-6)
    - [`D3DConf_12_Stencil::FrontAndBackStencil`](#d3dconf_12_stencilfrontandbackstencil)
- [Triangle fan](#triangle-fan)
  - [Definition](#definition-7)
  - [DDI](#ddi-7)
  - [Tests: HLK Conformance](#tests-hlk-conformance-7)
    - [`D3DConf_12_DDI0097::TriangleFan`](#d3dconf_12_ddi0097trianglefan)
- [Dynamic Pipeline State: Depth Bias, IB Strip Cut](#dynamic-pipeline-state-depth-bias-ib-strip-cut)
  - [Definition](#definition-8)
    - [Depth bias state](#depth-bias-state)
    - [Index buffer strip cut](#index-buffer-strip-cut)
  - [DDI](#ddi-8)
  - [API](#api)
  - [Tests: HLK Conformance](#tests-hlk-conformance-8)
    - [`D3DConf_12_DynamicDepthBias::SingleDynamic`](#d3dconf_12_dynamicdepthbiassingledynamic)
    - [`D3DConf_12_DynamicDepthBias::MultipleDynamic`](#d3dconf_12_dynamicdepthbiasmultipledynamic)
    - [`D3DConf_12_DynamicDepthBias::PSOReset`](#d3dconf_12_dynamicdepthbiaspsoreset)
    - [`D3DConf_12_DynamicIBStripCut::SingleDynamic`](#d3dconf_12_dynamicibstripcutsingledynamic)
    - [`D3DConf_12_DynamicIBStripCut::PSOReset`](#d3dconf_12_dynamicibstripcutpsoreset)
- [Non-normalized texture sampling coordinates](#non-normalized-texture-sampling-coordinates)
  - [Definition](#definition-9)
  - [Flags](#flags)
    - [DDI](#ddi-9)
    - [API](#api-1)
  - [Dynamic Samplers](#dynamic-samplers)
  - [Static Samplers](#static-samplers)
    - [DDI](#ddi-10)
    - [API](#api-2)
- [Mixed Render Target Resolutions](#mixed-render-target-resolutions)
  - [Definition](#definition-10)
    - [Trivia](#trivia)
  - [API](#api-3)
  - [DDI](#ddi-11)
  - [Tests: Functional](#tests-functional)
  - [Tests: Conformance](#tests-conformance)
- [Sample-frequency MSAA with no render targets bound](#sample-frequency-msaa-with-no-render-targets-bound)
  - [Description](#description)
  - [API](#api-4)
  - [DDI](#ddi-12)
  - [Tests: Functional](#tests-functional-1)
  - [Tests: Conformance](#tests-conformance-1)
- [`DXGI_FORMAT_A4B4G4R4_UNORM`](#dxgi_format_a4b4g4r4_unorm)
  - [Description](#description-1)
  - [API](#api-5)
  - [DDI](#ddi-13)
  - [Tests: Conformance](#tests-conformance-2)
- [Changing the spec for point sampling address computations](#changing-the-spec-for-point-sampling-address-computations)
  - [Description](#description-2)
  - [API](#api-6)
  - [DDI](#ddi-14)
  - [Test: Conformance](#test-conformance)
- [Line rasterization updates](#line-rasterization-updates)
  - [Description](#description-3)
  - [API](#api-7)
  - [DDI](#ddi-15)
  - [Tests: Functional](#tests-functional-2)
  - [Tests: Conformance](#tests-conformance-3)
- [Anisotropic sampler with mip point](#anisotropic-sampler-with-mip-point)
  - [Description](#description-4)
  - [API](#api-8)
  - [DDI](#ddi-16)
  - [Tests: Conformance](#tests-conformance-4)
- [Sampler descriptor heap size increase](#sampler-descriptor-heap-size-increase)
  - [Description](#description-5)
  - [API](#api-9)
  - [DDI](#ddi-17)
  - [Tests: Functional](#tests-functional-3)
  - [Tests: Conformance](#tests-conformance-5)

<!-- /code_chunk_output -->


## Intro

This document tracks the multiple features necessary to support a performant implementation of Vulkan on D3D12. Where possible, the goal is to relax constraints and provide additional APIs to reduce the amount of emulation required to translate Vulkan API calls to D3D12 calls.

---

## Format List Casting

### Definition
Vulkan allows reinterpretation-casting of resource formats by supplying a target list of castable formats during resource creation. With the exception of planar and compressed formats, the target formats in Vulkan can be any format whose block size and texels per block matches the resource's format's. Prior to this feature, even with relaxed format casting rules, D3D12 only allowed casting between formats within their respective format families and only if the original format was typeless.

With this feature, D3D12 provides an API at resource creation to specify a list of castable formats for the resource.

The list
* MAY be empty
* MAY contain uncompressed formats whose unit size matches the resource's format's unit size.
* MAY NOT contain planar formats.
* If the resource's format is non-compressed, then the list may ONLY contain non-compressed formats.

Additionally, if the resource's format is compressed, then a view that casts to a non-compressed format must have `MipLevels` and `ArraySize` equal to 1.



Formats not specified in the list during creation MAY NOT be used as view target formats for the resource.

Formats "casted" in this way are _reinterpreted_ as the target format for consumption in shaders.

Refer to [CreateCommittedResource3](D3D12EnhancedBarriers.md#id3d12device10-createcommittedresource3), [CreatePlacedResource2](D3D12EnhancedBarriers.md#id3d12device10-createplacedresource2), and [CreateReservedResource2](D3D12EnhancedBarriers.md#id3d12device10-createreservedresource2) in Enhanced Barriers for documentation on the new API fields, `NumCastableFormats` and `pCastableFormats` used to specify the list.

### DDI
Driver support for format list casting is reported via `RelaxedFormatCastingSupported` in `D3D12DDI_OPTIONS_DATA_0090` when `GetCaps` is called with `D3D12DDICAPS_TYPE_OPTIONS_0090`; available starting with DDI version `e_DDI_12_8_0090`.

### Tests: HLK Conformance
#### `D3DConf_12_RelaxedFormatCasting::FormatListCasting`
Creates resources using the `CreateCommittedResource3` API and tests a variety of compatible target cast formats, including unsigned integers, signed integers, floats, and compressed formats. Each view is attached as an SRV to a shader and the invoked read must succeed and the result must match the source data.

---

## Unrestricted Buffer Texture Copy Row Pitch and Offset
[Nickel:WDDM3.1]

### Definition
Vulkan specifies "optimal" row-pitch and offset alignments for copy operations between buffers and images, but only _requires_ alignments according to the texel size of the image. Prior to this feature, D3D12 required that offsets be aligned to `D3D12_TEXTURE_DATA_PLACEMENT_ALIGNMENT` (512 bytes) and row-pitch be aligned to `D3D12_TEXTURE_DATA_PITCH_ALIGNMENT` (256 bytes).

With this feature, both offset and row-pitch MUST be aligned only to the whole unit size of the texture's format. For example, copy operations targeting a texture with format `DXGI_FORMAT_R32B32G32A32_FLOAT` must have offset and row-pitch aligned to 16 bytes, i.e, entire texels.

### DDI
Driver support for unrestricted copy alignments is reported via `UnrestrictedBufferTextureCopyPitchSupported` in `D3D12DDI_OPTIONS_DATA_0091` when `GetCaps` is called with `D3D12DDICAPS_TYPE_OPTIONS_0091`; available starting with DDI version `e_DDI_12_8_0091`.

### Tests: HLK Conformance
Each test follows the same steps:

For 1D, 2D, and 3D textures with both uncompressed and compressed formats,
1. Upload non-zero data to the entire texture
2. Copy to a read-back buffer
    * For all textures, copy entire texture
    * For 3D textures, copy individual slices, inner boxes
    * For 2D textures, copy individual rows, inner rectangles
    * For 1D textures, copy inner section
3. Inspect the contents of the read-back buffer, must match the source data

#### `D3DConf_12_UnrestrictedAlignmentOffsetCopy::CopyWithoutRowPitchAlignment`
Copies data without the row-pitch alignment, but at offset 0 (respecting the placement alignment).

#### `D3DConf_12_UnrestrictedAlignmentOffsetCopy::CopyWithoutOffsetAlignment`
Copies data at various odd offsets, but with row-pitch aligned to `D3D12_TEXTURE_DATA_PITCH_ALIGNMENT`.

#### `D3DConf_12_UnrestrictedAlignmentOffsetCopy::CopyWithoutRowPitchAndOffsetAlignment`
Copies data at various odd offsets, packing the result tightly into the destination buffer.

---

## Texture Copy Between Inequal Dimension Textures
[Nickel:WDDM3.1]

### Definition
Vulkan explicitly allows copying data between resources whose dimensionality does not match. For example, a slice of a 3D resource to a 2D resource or a row of a 3D or 2D resource to a 1D resource. While D3D12 did not validate (and still won't) against these types of copy operations prior to this feature, this feature formalizes support for them.

### DDI
Support for copying between textures whose dimensionality does not match will be implied by, and must be supported on, drivers that report their DDI version to be `e_DDI_12_8_0091` or greater.

### Tests: HLK Conformance
In each case, the destination is copied into a readback buffer and the result is verified against what was uploaded.
#### `Copy3Dto2D`
Copies entire slices from a 3D texture into a 2D texture, then back into the 3D texture; copies different quandrants from different slices in a 3D texture into different quadrants of a 2D texture.
#### `Copy3Dto1D`
Copies different rows from different slices in a 3D texture into a 1D texture, then back into the 3D texture.
#### `Copy2Dto1D`
Copies different rows from a 2D texture into a 1D texture, then back into the 2D texture.

---

## Unrestricted Vertex Element Alignment
[Nickel:WDDM3.1]

### Definition
Vulkan requires the final computed GPU VA of a vertex or element buffer be aligned to the component size of the vertex or element. While D3D12 has the same requirement, it is validated as part of the input layout creation, before the buffer's binding location is considered.

With this feature, D3D12 will no longer consider it an error to specify a *potentially* misaligned input layout on a pipeline state object; instead, it will validate in two steps:
1. At input layout creation, iff it is determined to be impossible to correctly align all elements of an input layout at any offset, the retail layer will throw an exception and the debug layer will report an error.
2. At draw, the debug layer will then validate that the address provided in the vertex buffer description is compatible with the input layout, i.e, will result in each element of the layout being aligned correctly.

### DDI
Driver support for unrestricted vertex element alignment (potentially unaligned input element layouts) is reported via `UnrestrictedVertexElementAlignmentSupported` in `D3D12DDI_OPTIONS_DATA_0091` when `GetCaps` is called with `D3D12DDICAPS_TYPE_OPTIONS_0091`; available starting with DDI version `e_DDI_12_8_0091`.

### Tests: HLK Conformance

#### `D3DConf_12_UnrestrictedVertexAlignment::UnalignedVertexBuffer`
The test constructs a vertex buffer with a simple top-left half-viewport triangle and zero-padding in front for space to fabricate an offset. The `D3D12_INPUT_ELEMENT_DESC`'s `AlignedByteOffset` and the `D3D12_VERTEX_BUFFER_VIEW`'s `BufferLocation` are then specified with matching odd values such that their sum results in the aligned offset for the beginning of the triangle data.

The triangle is rendered. The rasterized coordinates are recorded by the pixel shader, read back, and validated against a list of expected coordinates. The rendering should execute, and the top-left half-viewport should produce a specific set of rasterized coordinates.

---

## Inverted viewports
[Nickel:WDDM3.1]

### Definition
Vulkan allows specifying a viewport with a negative height and/or minimum depth less than the maximum depth. Specifying a negative height flips the interpretation of the axis, and is primarily used for backwards compatibility with OpenGL. With this feature, D3D allows the same specification for the viewport.

Given a screen height`H`, then setting the viewport with `TopLeftY = H` and `Height = -H` would put the origin at the _bottom_ left corner of the screen, with _up_ being in the negative Y direction.

Additionally, setting `MinDepth = 1`, `MaxDepth = 0` is valid. The interpretation remains the same, and `MinDepth` must still be in the range `[0, 1]`, but it is not required that `MaxDepth > MinDepth`.

### DDI
Driver support for inverted viewports is reported via `InvertedViewportHeightFlipsYSupported` and `InvertedViewportDepthFlipsZSupported` in `D3D12DDI_OPTIONS_DATA_0091` when `GetCaps` is called with `D3D12DDICAPS_TYPE_OPTIONS_0091`; available starting with DDI version `e_DDI_12_8_0091`.

### Tests: HLK Conformance

#### `D3DConf_12_InvertedViewports::InvertedHeight`

The test constructs a vertex buffer with a simple top-left half-viewport triangle and renders it into a viewport as described above with `TopLeftY = H` and `Height = -H`, where `H` is arbitrarily chosen. The rasterized coordinates are recorded by the pixel shader, read back, and validated against a list of expected coordinates. The rendering should execute, and the top-left half-viewport should produce a specific set of rasterized coordinates representing a _bottom-left_ half-viewport triangle.

#### `D3DConf_12_InvertedViewports::InvertedDepth`

The test constructs a vertex buffer with a simple top-left half-viewport triangle at `Z = .5f` and renders it into a viewport with `MinDepth = 1` and `MaxDepth = 0`. The rasterized coordinates are recorded by the pixel shader, read back, and validated against a list of expected coordinates. The rendering should execute, and the top-left half-viewport should _not_ be culled, producing a specific set of rasterized coordinates.

---

## Alpha blend factor
[Nickel:WDDM3.1]

### Definition
Vulkan supports two constant, single-floating-point-value blend factors, `VK_BLEND_FACTOR_CONSTANT_ALPHA` and `VK_BLEND_FACTOR_ONE_MINUS_CONSTANT_ALPHA`. With this feature, D3D12 will also support two single-floating-point-value blend factors via the `D3D12DDI_BLEND` types `D3D12DDI_BLEND_ALPHA_FACTOR` and `D3D12DDI_BLEND_INV_ALPHA_FACTOR`.

For both of the new blend types, the command list level constant used as the factor during blend is the alpha component of the constant blend factor set with `OMSetBlendFactor`. When the command list is reset, the alpha component is reset to its default value, `1.0f`.

*__Note:__ a previous version of this spec referred to `pfnOmSetAlphaBlendFactor` to assign the alpha blend factor. This function is no longer valid, but its entry has been retained and is marked as unused in D3D.*

### DDI
Support for the alpha blend factor will be implied by, and must be supported on, drivers that report their DDI version to be `e_DDI_12_8_0092` or greater.

Additions to the `D3D12DDI_BLEND` enumeration are linear:
```c++
typedef enum D3D12DDI_BLEND
{
    ...
    D3D12DDI_BLEND_ALPHA_FACTOR = 20,
    D3D12DDI_BLEND_INV_ALPHA_FACTOR = 21
} D3D12DDI_BLEND;
```

### Tests: HLK Conformance

#### `D3DConf_12_Blend::AlphaBlendFactor`

The test constructs a vertex buffer with a simple top-left half-viewport triangle and renders it into a 4x4 Texture2D render target with a variety of blend state configurations. The rendering will need to produce 6 correctly rasterized pixels in the top left corner of the texture resource, according to the blend state parameters. The render target is read back and the pixels are compared against the reference "correct" values. For example, if SrcBlend is `D3D12_BLEND::D3D12_BLEND_ALPHA_FACTOR`, DestBlend is `D3D12_BLEND::D3D12_BLEND_ZERO`, and the alpha blend factor is set to `.8f`, then `std::round(10 * pixel_color.R)` must be `8`, `std::round(10 * pixel_color.G)` must be `8`, and `std::round(10 * pixel_color.B)` must be `8`.

---

[End Nickel:WDDM3.1]

---

## Independent Front/Back Stencil Refs and Masks

### Definition
Vulkan supports assigning reference and mask values independently for front-face and back-face stencil operations. With this feature, D3D12 adds additional fields for back-face read and write masks to the stencil description, as well as a CommandList function for setting the reference values independently.


### DDI
Support for independent front-face and back-face reference and masks will be implied by, and must be supported on, drivers that report their DDI version to be `e_DDI_12_8_0095` or greater.

During PSO creation, `D3D12DDI_DEPTH_STENCIL_DESC_0095` provides fields for back-face read and write masks, as well as renaming `0025` mask values to be specific to front-face stencil operations.

```c++
struct D3D12DDI_DEPTH_STENCIL_DESC_0095
{
    BOOL DepthEnable;
    D3D12DDI_DEPTH_WRITE_MASK DepthWriteMask;
    D3D12DDI_COMPARISON_FUNC DepthFunc;
    BOOL StencilEnable;
    BOOL FrontEnable;
    BOOL BackEnable;
    --> UINT8 FrontFaceStencilReadMask;
    --> UINT8 FrontFaceStencilWriteMask;
    D3D12DDI_DEPTH_STENCILOP_DESC FrontFace;
    D3D12DDI_DEPTH_STENCILOP_DESC BackFace;
    D3D12DDI_LIBRARY_REFERENCE_0010 LibraryReference;
    BOOL DepthBoundsTestEnable;
    --> UINT8 BackFaceStencilReadMask;
    --> UINT8 BackFaceStencilWriteMask;
}
```

DDI `D3D12DDI_DEVICE_FUNCS_CORE_0095` updates `0025` entry points for creating the stencil state.

```c++
typedef SIZE_T(APIENTRY* PFND3D12DDI_CALCPRIVATEDEPTHSTENCILSTATESIZE_0095)(
    D3D12DDI_HDEVICE, _In_ CONST D3D12DDI_DEPTH_STENCIL_DESC_0095*);

typedef VOID(APIENTRY* PFND3D12DDI_CREATEDEPTHSTENCILSTATE_0095)(
    D3D12DDI_HDEVICE, _In_ CONST D3D12DDI_DEPTH_STENCIL_DESC_0095*,
    D3D12DDI_HDEPTHSTENCILSTATE);

typedef struct D3D12DDI_DEVICE_FUNCS_CORE_0095
{
    ...
    PFND3D12DDI_CALCPRIVATEDEPTHSTENCILSTATESIZE_0095  pfnCalcPrivateDepthStencilStateSize;
    PFND3D12DDI_CREATEDEPTHSTENCILSTATE_0095           pfnCreateDepthStencilState;
    ...
} D3D12DDI_DEVICE_FUNCS_CORE_0095;
```

DDI `D3D12DDI_COMMAND_LIST_FUNCS_3D_0095` provides an entry point for setting the reference values independently.

```c++
typedef VOID ( APIENTRY* PFND3D12DDI_OM_SETFRONTANDBACKSTENCILREF_0095 )(
      D3D12DDI_HCOMMANDLIST, /*FrontStencilRef*/ UINT, /*BackStencilRef*/ UINT );

typedef struct D3D12DDI_COMMAND_LIST_FUNCS_3D_0095
{
    ...
    PFND3D12DDI_OM_SETFRONTANDBACKSTENCILREF_0095           pfnOmSetFrontAndBackStencilRef;
} D3D12DDI_COMMAND_LIST_FUNCS_3D_0095;
```

### Tests: HLK Conformance

#### `D3DConf_12_Stencil::FrontAndBackStencil`

The test constructs a vertex buffer with a simple _front-face_ top-left half-viewport triangle and a _back-face_ bottom-right viewport triangle. A series of individual test cases will, with back-face culling off,
1. Render to the front and back faces with separate masks and reference value settings
2. Read back both the render target and the stencil target and verify that the faces are rendered to and that the stencil buffer is correct
3. Render _again_ with updated stencil parameters dependent on the result of (2)
4. Read back both the render target and the stencil target and verify that the faces are correctly rendered or not rendered, and that the resulting stencil buffer is correct

These steps are repeated for various combinations of stencil operations, reference values, and masks.

---

## Triangle fan

### Definition
Vulkan supports the triangle fan primitive topology and software emulation for it is expensive, so D3D will bring back support for it natively.

### DDI
DDI version 0097 will revive `D3D12DDI_PRIMITIVE_TOPOLOGY_TRIANGLEFAN` in the slot reserved for it in `D3D12DDI_PRIMITIVE_TOPOLOGY`, 6. Triangle fans are sufficiently described on msdn: [Triangle Fans (Direct3D 9)](https://docs.microsoft.com/en-us/windows/win32/direct3d9/triangle-fans). Support for the triangle fan primitive topology will be implied by, and must be supported on, drivers that report their DDI version to be `e_DDI_12_8_0097` or greater.

```c++
typedef enum D3D12DDI_PRIMITIVE_TOPOLOGY
{
    D3D12DDI_PRIMITIVE_TOPOLOGY_UNDEFINED = 0,
    D3D12DDI_PRIMITIVE_TOPOLOGY_POINTLIST = 1,
    D3D12DDI_PRIMITIVE_TOPOLOGY_LINELIST = 2,
    D3D12DDI_PRIMITIVE_TOPOLOGY_LINESTRIP = 3,
    D3D12DDI_PRIMITIVE_TOPOLOGY_TRIANGLELIST = 4,
    D3D12DDI_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP = 5,

    D3D12DDI_PRIMITIVE_TOPOLOGY_TRIANGLEFAN = 6,
    ...
```

### Tests: HLK Conformance

#### `D3DConf_12_DDI0097::TriangleFan`

The test will render various shapes into a 5x5 viewport using `D3D_PRIMITIVE_TOPOLOGY_TRIANGLEFAN` with back-face culling on, ensuring the result is correct by comparing to a golden reference.

---

## Dynamic Pipeline State: Depth Bias, IB Strip Cut

### Definition

#### Depth bias state
In Vulkan, the depth bias state of a pipeline can be specified as dynamic, allowing it to be changed without recreating/reassigning the entire pipeline state. Given that depth bias state contains highly variable floating point fields, it would be prohibitive for performance to recreate and reassign D3D's pipeline state every time a Vulkan depth bias state is dynamically changed. To facilitate the translation and address developer requests, DDI 0099 allows the depth bias state in D3D to be specified as possibly-dynamic during pipeline state creation, as well as changing `DepthBias` from `INT` to `FLOAT`.

#### Index buffer strip cut
Vulkan's index buffer primitive restart functionality does not require or allow specifying the restart sentinel, or "strip cut value". Instead, it is always the maximum value of the index buffer's underlying type. To avoid PSO recompilation when switching index buffer views, DDI 0099 allows the buffer strip cut value to be specified as possibly-dynamic during pipeline state creation.

### DDI
To legally dynamically update the depth bias state after pipeline assignment, the assigned pipeline MUST have been created with `D3D12DDI_PIPELINE_STATE_FLAG_DYNAMIC_DEPTH_BIAS`. Likewise, to legally dynamically update the IB strip cut value, the assigned pipeline MUST have been created with `D3D12DDI_PIPELINE_STATE_FLAG_DYNAMIC_INDEX_BUFFER_STRIP_CUT`.

```c++
typedef enum D3D12DDI_PIPELINE_STATE_FLAGS
{
    D3D12DDI_PIPELINE_STATE_FLAG_NONE = 0x0,
    D3D12DDI_PIPELINE_STATE_FLAG_DYNAMIC_DEPTH_BIAS = 0x4,
    D3D12DDI_PIPELINE_STATE_FLAG_DYNAMIC_INDEX_BUFFER_STRIP_CUT = 0x8
} D3D12DDI_PIPELINE_STATE_FLAGS;
DEFINE_ENUM_FLAG_OPERATORS(D3D12DDI_PIPELINE_STATE_FLAGS);
```
**Note:** These will be validated by the runtime; attempting to update the depth bias or IB strip cut of a current pipeline that was _not_ created with the appropriate flag is undefined.

These flags may be set for DDI 0099 pipeline creation:
```c++
typedef struct D3D12DDIARG_CREATE_PIPELINE_STATE_0099
{
    D3D12DDI_HSHADER hComputeShader;
    D3D12DDI_HSHADER hVertexShader;
    D3D12DDI_HSHADER hPixelShader;
    D3D12DDI_HSHADER hDomainShader;
    D3D12DDI_HSHADER hHullShader;
    D3D12DDI_HSHADER hGeometryShader;
    D3D12DDI_HROOTSIGNATURE hRootSignature;
    D3D12DDI_HBLENDSTATE hBlendState;
    UINT SampleMask;
    D3D12DDI_HRASTERIZERSTATE hRasterizerState;
    D3D12DDI_HDEPTHSTENCILSTATE hDepthStencilState;
    D3D12DDI_HELEMENTLAYOUT hElementLayout;
    D3D12DDI_INDEX_BUFFER_STRIP_CUT_VALUE IBStripCutValue;
    D3D12DDI_PRIMITIVE_TOPOLOGY_TYPE PrimitiveTopologyType;
    UINT NumRenderTargets;
    DXGI_FORMAT RTVFormats[8];
    DXGI_FORMAT DSVFormat;
    DXGI_SAMPLE_DESC SampleDesc;
    UINT NodeMask;
    D3D12DDI_LIBRARY_REFERENCE_0010 LibraryReference;
    D3D12DDI_VIEW_INSTANCING_DESC ViewInstancingDesc;
    D3D12DDI_HSHADER hMeshShader;
    D3D12DDI_HSHADER hAmplificationShader;

    /// Pipeline state flags
    D3D12DDI_PIPELINE_STATE_FLAGS Flags;

} D3D12DDIARG_CREATE_PIPELINE_STATE_0099;

typedef HRESULT(APIENTRY* PFND3D12DDI_CREATE_PIPELINE_STATE_0099) (D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATE_PIPELINE_STATE_0099*, D3D12DDI_HPIPELINESTATE, D3D12DDI_HRTPIPELINESTATE);
typedef SIZE_T(APIENTRY* PFND3D12DDI_CALC_PRIVATE_PIPELINE_STATE_SIZE_0099)(D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATE_PIPELINE_STATE_0099*);

typedef struct D3D12DDI_DEVICE_FUNCS_CORE_0099
{
    ...
    PFND3D12DDI_CALC_PRIVATE_PIPELINE_STATE_SIZE_0099  pfnCalcPrivatePipelineStateSize;
    PFND3D12DDI_CREATE_PIPELINE_STATE_0099             pfnCreatePipelineState;
    ...
} D3D12DDI_DEVICE_FUNCS_CORE_0099;

```

For drivers, these flags are only _hints_ about whether or not state is allowed to be changed; it does not alter the behavior of calls to `pfnSetPipelineState`. When setting the pipeline state, the depth bias state and IB strip cut must still be set according to their descriptions in the pipeline state object, regardless of the presence of their corresponding dynamic flags.

For pipelines created with this flag, the _current_ depth bias state may be changed via the command list function, `pfnRSSetDepthBias`, and the _current_ IB strip cut value may be changed via the command list function, `pfnIASetIndexBufferStripCutValue`.

```c++
typedef VOID(APIENTRY* PFND3D12DDI_SET_DEPTH_BIAS_STATE_0099)(
    D3D12DDI_HCOMMANDLIST, FLOAT DepthBias, FLOAT DepthBiasClamp, FLOAT SlopeScaledDepthBias);

typedef VOID(APIENTRY* PFND3D12DDI_SET_INDEX_BUFFER_STRIP_CUT_VALUE_0099)(
    D3D12DDI_HCOMMANDLIST, D3D12DDI_INDEX_BUFFER_STRIP_CUT_VALUE IBStripCutValue);

typedef struct D3D12DDI_COMMAND_LIST_FUNCS_3D_0099
{
    ...
    PFND3D12DDI_SET_DEPTH_BIAS_STATE_0099 pfnRSSetDepthBias;
    PFND3D12DDI_SET_INDEX_BUFFER_STRIP_CUT_VALUE_0099 pfnIASetIndexBufferStripCutValue;
} D3D12DDI_COMMAND_LIST_FUNCS_3D_0099;
```

Calling these functions _does not_ change the pipeline state object's description. For example, if an application sets the pipeline state with depth bias state _**A**_, calls `RSSetDepthBias` with depth bias state _**B**_, and then sets the same pipeline state again, the depth bias state must then be _**A**_.
`RSSetDepthBias` and `IASetIndexBufferStripCutValue` are both valid calls inside a bundle, and the respective state changes must be preserved upon exiting bundle execution.

DDI 0099 revs the rasterizer description to change `DepthBias` from `INT` to `FLOAT`. The calculation of `DepthBias` is not changed, as it was previously casting to a `FLOAT` first anyway (refer to [D3D11 spec 15.10 on Depth Bias](https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm#15.10%20Depth%20Bias)).

```c++
typedef struct D3D12DDI_RASTERIZER_DESC_0099
{
    D3D12DDI_FILL_MODE FillMode;
    D3D12DDI_CULL_MODE CullMode;
    BOOL FrontCounterClockwise;

    // Changed type to FLOAT
    FLOAT DepthBias;

    FLOAT DepthBiasClamp;
    FLOAT SlopeScaledDepthBias;
    BOOL DepthClipEnable;
    BOOL ScissorEnable;
    BOOL MultisampleEnable;
    BOOL AntialiasedLineEnable;
    UINT ForcedSampleCount;
    D3D12DDI_CONSERVATIVE_RASTERIZATION_MODE ConservativeRasterizationMode;
    D3D12DDI_LIBRARY_REFERENCE_0010 LibraryReference;
} D3D12DDI_RASTERIZER_DESC_0099;

typedef SIZE_T(APIENTRY* PFND3D12DDI_CALCPRIVATERASTERIZERSTATESIZE_0099)(
    D3D12DDI_HDEVICE, _In_ CONST D3D12DDI_RASTERIZER_DESC_0099*);
typedef VOID(APIENTRY* PFND3D12DDI_CREATERASTERIZERSTATE_0099)(
    D3D12DDI_HDEVICE, _In_ CONST D3D12DDI_RASTERIZER_DESC_0099*, D3D12DDI_HRASTERIZERSTATE);

typedef struct D3D12DDI_DEVICE_FUNCS_CORE_0099
{
    ...
    PFND3D12DDI_CALCPRIVATERASTERIZERSTATESIZE_0099   pfnCalcPrivateRasterizerStateSize;
    PFND3D12DDI_CREATERASTERIZERSTATE_0099            pfnCreateRasterizerState;
    ...
} D3D12DDI_DEVICE_FUNCS_CORE_0099;

```

**Note** `D3D12DDI_DEVICE_FUNCS_CORE_0099` has two updates that mentioned individually in separate sections.

Support for dynamic depth bias and index buffer strip cut is implied by, and must be supported on, drivers that report their DDI version to be 0099 or greater.

### API

For apps, corresponding pipeline state flags are valid to specify for DDI 0099 pipeline states.

```c++
typedef enum D3D12_PIPELINE_STATE_FLAGS
{
    D3D12_PIPELINE_STATE_FLAG_NONE = 0x0,
    D3D12_PIPELINE_STATE_FLAG_TOOL_DEBUG = 0x1,
    D3D12_PIPELINE_STATE_FLAG_DYNAMIC_DEPTH_BIAS = 0x4,
    D3D12_PIPELINE_STATE_FLAG_DYNAMIC_INDEX_BUFFER_STRIP_CUT = 0x8,
    ...
} D3D12_PIPELINE_STATE_FLAGS;
```

When present, the corresponding command list functions are valid to call.

```c++
    void ID3D12GraphicsCommandList9::RSSetDepthBias(
        FLOAT DepthBias,
        FLOAT DepthBiasClamp,
        FLOAT SlopeScaledDepthBias
    );

    void ID3D12GraphicsCommandList9::IASetIndexBufferStripCutValue(
        D3D12_INDEX_BUFFER_STRIP_CUT_VALUE IBStripCutValue
    );
```

To set the initial dynamic depth bias state, `D3D12_RASTERIZER_DESC1` has a `FLOAT` declared `DepthBias`. This is accessible by calling `SetPipelineState` with the associated helper, `CD3DX12_PIPELINE_STATE_STREAM4::RasterizerState`. Providing a non-integral value on unsupported hardware will result in a debug layer warning, as those values will be cast to `INT` before being submitted to the driver.

```c++
typedef struct D3D12_RASTERIZER_DESC1
{
    D3D12_FILL_MODE FillMode;
    D3D12_CULL_MODE CullMode;
    BOOL FrontCounterClockwise;

    // Changed type to FLOAT
    FLOAT DepthBias;

    FLOAT DepthBiasClamp;
    FLOAT SlopeScaledDepthBias;
    BOOL DepthClipEnable;
    BOOL MultisampleEnable;
    BOOL AntialiasedLineEnable;
    UINT ForcedSampleCount;
    D3D12_CONSERVATIVE_RASTERIZATION_MODE ConservativeRaster;
} D3D12_RASTERIZER_DESC1;
```

### Tests: HLK Conformance

#### `D3DConf_12_DynamicDepthBias::SingleDynamic`

The test renders a full-viewport quad with a pipeline-set depth bias, resets the pipeline with 0 depth bias, then re-renders the quad using `RSSetDepthBias` and compares the results, which should match.

#### `D3DConf_12_DynamicDepthBias::MultipleDynamic`

Same as `SingleDynamic`, but calls `RSSetDepthBias` and renders multiple times without re-setting the pipeline state, comparing to pipeline-set depth bias reference renders, which should match.

#### `D3DConf_12_DynamicDepthBias::PSOReset`

The test renders a full-viewport quad with a pipeline-set depth bias as a reference. It then calls `RSSetDepthBias` to change the depth bias, then _re-sets_ the pipeline, which should overwrite the `RSSetDepthBias` value and renders again. The final render and the original reference should match.




#### `D3DConf_12_DynamicIBStripCut::SingleDynamic`

The test renders a full-viewport quad with a pipeline-set IB strip cut, resets the pipeline with DISABLED strip cut, then re-renders the quad using `IASetIndexBufferStripCutValue` and compares the results, which should match.

#### `D3DConf_12_DynamicIBStripCut::PSOReset`

The test renders a full-viewport quad with a pipeline-set IB strip cut as a reference. It then calls `IASetIndexBufferStripCutValue` to change the strip cut value, then _re-sets_ the pipeline, which should overwrite the `IASetIndexBufferStripCutValue` value and renders again. The final render and the original reference should match.


---


## Non-normalized texture sampling coordinates

### Definition

Vulkan allows sampling from textures using non-normalized coordinates, as specified during sampler creation. To enable this in D3D12, DDI 0100 adds a sampler flag indicating to use non-normalized coordinates.

Samplers with `D3D12_SAMPLER_FLAG_NON_NORMALIZED_COORDINATES` set must sample from the target texture at the coordinates specified, unscaled by the texture's dimensions.

When non-normalized coordinates are used, the following restrictions apply:
* The SRV being sampled must be `D3D12_SRV_DIMENSION_TEXTURE1D` or `D3D12_SRV_DIMENSION_TEXTURE2D`
* The SRV's mip-count must be 1.
* The sampling coordinate valid range is `x:[0, width)` and `y:[0, height)`
* The `Offset` parameter in `Sample*` functions must not be used
* The `D3D12_FILTER` must be one of
  * `D3D12_FILTER_MIN_MAG_MIP_POINT`
  * `D3D12_FILTER_MIN_MAG_LINEAR_MIP_POINT`
  * `D3D12_FILTER_MINIMUM_MIN_MAG_MIP_POINT`
  * `D3D12_FILTER_MINIMUM_MIN_MAG_LINEAR_MIP_POINT`
  * `D3D12_FILTER_MAXIMUM_MIN_MAG_MIP_POINT`
  * `D3D12_FILTER_MAXIMUM_MIN_MAG_LINEAR_MIP_POINT`

  Where the `min` and `mag` filters are equal, `mip` is `POINT`, and comparison and anisotropy are disabled.
* `MinLOD` and `MaxLOD` must be 0
* `AddressU` and `AddressV` must be `D3D12_TEXTURE_ADDRESS_MODE_CLAMP` or `D3D12_TEXTURE_ADDRESS_MODE_BORDER`

The result of sampling outside of the valid range is generally undefined in terms of what value may be returned, but additionally undefined in terms of what state the device is left in if `AddressU` or `AddressV` are not appropriately set.

Support for non-normalized texture sampling is implied by, and must be supported on, drivers that report their DDI version to be 0100 or greater.

### Flags

#### DDI
```c++
typedef enum D3D12DDI_SAMPLER_FLAGS_0096
{
    D3D12DDI_SAMPLER_FLAG_NONE = 0x0,
    D3D12DDI_SAMPLER_FLAG_UINT_BORDER_COLOR = 0x01,

    // New flag
    D3D12DDI_SAMPLER_FLAG_NON_NORMALIZED_COORDINATES = 0x02,

} D3D12DDI_SAMPLER_FLAGS_0096;
```

#### API
```c++
typedef enum D3D12_SAMPLER_FLAGS
{
    D3D12_SAMPLER_FLAG_NONE = 0x0,
    D3D12_SAMPLER_FLAG_UINT_BORDER_COLOR = 0x01,

    // New flag
    D3D12_SAMPLER_FLAG_NON_NORMALIZED_COORDINATES = 0x02,

} D3D12_SAMPLER_FLAGS;
```

### Dynamic Samplers

Dynamic samplers already have a sampler flag field, so it is sufficient to have added the new flag and declared support.

### Static Samplers

#### DDI

To support static samplers, `D3D12DDI_STATIC_SAMPLER_0100` includes a flags field.

```c++
typedef struct D3D12DDI_STATIC_SAMPLER_0100
{
    D3D12DDI_FILTER Filter;
    D3D12DDI_TEXTURE_ADDRESS_MODE AddressU;
    D3D12DDI_TEXTURE_ADDRESS_MODE AddressV;
    D3D12DDI_TEXTURE_ADDRESS_MODE AddressW;
    FLOAT MipLODBias;
    UINT MaxAnisotropy;
    D3D12DDI_COMPARISON_FUNC ComparisonFunc;
    D3D12DDI_STATIC_BORDER_COLOR BorderColor;
    FLOAT MinLOD;
    FLOAT MaxLOD;
    UINT ShaderRegister;
    UINT RegisterSpace;
    D3D12DDI_SHADER_VISIBILITY ShaderVisibility;

    // Sampler flags
    D3D12DDI_SAMPLER_FLAGS_0096 Flags;
} D3D12DDI_STATIC_SAMPLER_0100;
```

New root signature DDIs enable the use of `D3D12DDI_STATIC_SAMPLER_0100`.

```c++
typedef struct D3D12DDI_ROOT_SIGNATURE_0100
{
    UINT NumParameters;
    CONST D3D12DDI_ROOT_PARAMETER_0013* pRootParameters;
    UINT NumStaticSamplers;

    // 0100 static samplers
    CONST D3D12DDI_STATIC_SAMPLER_0100* pStaticSamplers;

    D3D12DDI_ROOT_SIGNATURE_FLAGS Flags;
} D3D12DDI_ROOT_SIGNATURE_0100;


typedef struct D3D12DDIARG_CREATE_ROOT_SIGNATURE_0100
{
    D3D12DDI_ROOT_SIGNATURE_VERSION Version;
    union
    {
        CONST D3D12DDI_ROOT_SIGNATURE_0100* pRootSignature_1_2;
    };
    UINT NodeMask;
} D3D12DDIARG_CREATE_ROOT_SIGNATURE_0100;
```

And corresponding core funcs enable the creation of the new root signature.

```c++

typedef SIZE_T(APIENTRY* PFND3D12DDI_CALC_PRIVATE_ROOT_SIGNATURE_SIZE_0100)(D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATE_ROOT_SIGNATURE_0100*);
typedef HRESULT(APIENTRY* PFND3D12DDI_CREATE_ROOT_SIGNATURE_0100) (D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATE_ROOT_SIGNATURE_0100*, D3D12DDI_HROOTSIGNATURE);

typedef struct D3D12DDI_DEVICE_FUNCS_CORE_0100
{
    ...
    PFND3D12DDI_CALC_PRIVATE_ROOT_SIGNATURE_SIZE_0100    pfnCalcPrivateRootSignatureSize;
    PFND3D12DDI_CREATE_ROOT_SIGNATURE_0100               pfnCreateRootSignature;

    ...
} D3D12DDI_DEVICE_FUNCS_CORE_0100;
```

#### API

From the API, `D3D12_STATIC_SAMPLER_DESC1` contains the flags field, which will be validated against containing bits that are not present in `D3D12_SAMPLER_FLAGS`.

```c++
typedef struct D3D12_STATIC_SAMPLER_DESC1
{
    D3D12_FILTER Filter;
    D3D12_TEXTURE_ADDRESS_MODE AddressU;
    D3D12_TEXTURE_ADDRESS_MODE AddressV;
    D3D12_TEXTURE_ADDRESS_MODE AddressW;
    FLOAT MipLODBias;
    UINT MaxAnisotropy;
    D3D12_COMPARISON_FUNC ComparisonFunc;
    D3D12_STATIC_BORDER_COLOR BorderColor;
    FLOAT MinLOD;
    FLOAT MaxLOD;
    UINT ShaderRegister;
    UINT RegisterSpace;
    D3D12_SHADER_VISIBILITY ShaderVisibility;

    // API flags
    D3D12_SAMPLER_FLAGS Flags;
} D3D12_STATIC_SAMPLER_DESC1;
```

And `D3D12_ROOT_SIGNATURE_DESC2` enables use of `D3D12_STATIC_SAMPLER_DESC1`.

```c++
typedef enum D3D_ROOT_SIGNATURE_VERSION
{
    D3D_ROOT_SIGNATURE_VERSION_1 = 0x1,
    D3D_ROOT_SIGNATURE_VERSION_1_0 = 0x1,
    D3D_ROOT_SIGNATURE_VERSION_1_1 = 0x2,

    // New version
    D3D_ROOT_SIGNATURE_VERSION_1_2 = 0x3,
} D3D_ROOT_SIGNATURE_VERSION;

...

typedef struct D3D12_ROOT_SIGNATURE_DESC2
{
    UINT NumParameters;
    [annotation("_Field_size_full_(NumParameters)")] const D3D12_ROOT_PARAMETER1* pParameters;
    UINT NumStaticSamplers;
    [annotation("_Field_size_full_(NumStaticSamplers)")] const D3D12_STATIC_SAMPLER_DESC1* pStaticSamplers;
    D3D12_ROOT_SIGNATURE_FLAGS Flags;
} D3D12_ROOT_SIGNATURE_DESC2;

...

typedef struct D3D12_VERSIONED_ROOT_SIGNATURE_DESC
{
    D3D_ROOT_SIGNATURE_VERSION Version;
    union
    {
        D3D12_ROOT_SIGNATURE_DESC   Desc_1_0;
        D3D12_ROOT_SIGNATURE_DESC1  Desc_1_1;
        D3D12_ROOT_SIGNATURE_DESC2  Desc_1_2;
    };
} D3D12_VERSIONED_ROOT_SIGNATURE_DESC;
```

**Note:** Since adding the flags field to the static sampler desc exposes the ability to specify `D3D12_SAMPLER_FLAG_UINT_BORDER_COLOR` for a static sampler, validation will disallow setting `D3D12_SAMPLER_FLAG_UINT_BORDER_COLOR` and also specifying a floating-point static border color. When using any of the `*_UINT` border colors, setting `D3D12_SAMPLER_FLAG_UINT_BORDER_COLOR` is redunant, but not an error.


---

## Mixed Render Target Resolutions

### Definition

The D3D11 spec says in [section 17.14](https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm#17.14%20Multiple%20RenderTargets):

> All of these RenderTargets must be the same type of resource: Buffer, Texture1D[Array], Texture2D[Array], Texture3D, or TextureCube. All RenderTargets must have the same size in all dimensions (width and height, and depth for 3D or array size for *Array types).

*Note*: The reference to a resource of type `TextureCube` is stale from D3D10; texture cubes are simply 2D arrays in D3D11 and D3D12.

[Section 17.16](https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm#17.16%20Interaction%20of%20Depth/Stencil%20with%20MRT%20and%20TextureArrays) continues:

> Should Resource Views of TextureArray(s) be set as RenderTarget(s), the Resource View of Depth/Stencil (if bound) must also be the same dimensions and array size.

[Section 15.7](https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm#15.7%20Scissor%20Test) describes the interaction of viewport/scissor with render target dimensions:

> Scissor extents are specified in unsigned integer, with no limits on the magnitudes of the extents. If the Scissor rectangle falls off the currently set RenderTargets, then simply nothing will get drawn. If the Scissor rectangle is larger than the currently set RenderTarget(s) or straddles an edge, then the only pixels that can be drawn are the ones in the covered area of the RenderTarget(s).

Lastly, [section 15.15](https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm#15.15%20Per-Primitive%20RenderTarget%20Array%20Slice%20Selection) describes render target array index behavior:

> If the value written to "renderTargetArrayIndex" is out of range of the particular resource array that is set as a RenderTarget, the 0-th RenderTarget is used. If the renderTargetArrayIndex value is input to the Pixel Shader, it arrives unmodified, not incorporating any clamping that occurred in selecting which of the available Array slices as the RenderTarget.

For compatibility with Vulkan, the following changes will be made:

* When rendering to buffers, no change to the D3D11 spec wording is applied. Rendering to buffers cannot be mixed with 1D/2D/3D render targets, nor depth buffers which are inherently 2D, nor buffer views of differing sizes.
* When rendering to 1D textures, the effective render target dimensionality should be treated as 2D with a height of 1.
* When rendering to 3D textures, the effective render target dimensionality should be treated as 2D. The `WSize` field of `D3D12_TEX3D_RTV` is used to determine the equivalent `ArraySize` for interpretation as a 2D render target.
* When all render target and depth buffer dimensions (width/height) are the same, the scissor definition remains the same: there is an implicit intersection that occurs with the region of {0, 0, width, height}.
* When the width and height of the render targets and/or depth buffers mismatch, this implicit intersection no longer applies. The application is responsible for ensuring that the region defined by the combination of viewport and scissor does not exceed the dimensions of the *smallest* output view. Behavior is undefined if it exceeds this size.
  * Possible results include intersecting with the smallest output, intersecting with the largest, or GPU hangs/faults.
* Array size for render targets and depth stencil is allowed to be different. The above spec wording for out-of-bounds index values only applies when array size dimensionality matches for all outputs. When they are different, a value that is out-of-bounds for any of them will produce undefined results.

#### Trivia

Going all the way back to D3D10.0, the above rules were validated by the debug layer. In D3D10.1, validation was added into the core runtime in addition to the debug layer. However, the validation in the D3D10.1 core runtime allows depth buffers to be *smaller* than the render targets. The validation looked this way since it was first merged into the D3D10.1 codebase, and I can't find any reference as to why it was this way. Tribal knowledge that's survived this long guesses that there was an app which did 3D rendering to a top-left-anchored sub-region of the screen, and drew UI on the bottom/right with no depth.

### API

No new API methods, just a new boolean feature option: `MismatchingOutputDimensionsSupported`.

### DDI

This feature is required and is assumed to be enabled when DDI version is set to 0102 or greater.

### Tests: Functional

Functional tests will validate debug layer behavior when `MismatchingOutputDimensionsSupported` is both true and false. Cases should include:
* Viewport/scissor that exceed smallest render target dimensions for top mips
* Using smaller mips to effectively shrink the renderable region
* Cases where the depth buffer is smaller

### Tests: Conformance

Conformance tests will validate rendering results with mismatching sizes bound. All cases will bind 2 render targets and one depth buffer, cycling on which is smallest (RTV0, RTV1, DSV). Overlapping rendering will be used for depth/stencil validation rather than readback. At least one test case will use non-zero mip level for each output. Tests should use large viewports + small scissor, as well as viewports not starting at (0, 0).

---

## Sample-frequency MSAA with no render targets bound

### Description

D3D11 only provides one way to declare [UAV-only rendering with MSAA](https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm#3.5.6.4%20UAV-Only%20Rasterization%20with%20Multisampling), is to use TIR (target-independent rasterization) `ForcedSampleCount` > 1. This same option can also be used for doing multi-sampled rasterization and then writing the result to a single-sampled render target. However, the D3D11 spec notes this restriction:

> Shaders can request pixel-frequency invocation with UAV-only rendering, but requesting sample-frequency invocation is invalid (produces undefined shading results).

This is also noted in the [context](https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm#3.5.6.2%20Rasterizer%20Behavior%20with%20Forced%20Rasterizer%20Sample%20Count) of the broader TIR feature:

> Sample-frequency shader invocation cannot be requested, otherwise rendering results are undefined.

D3D12's pipeline state object has 2 locations where sample count is specified:
1. In the dedicated `DXGI_SAMPLE_DESC` field (`SampleDesc` in the v1 desc, `D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_SAMPLE_DESC` for stream-based descs).
2. In the rasterizer state's `ForcedSampleCount`.

D3D12 currently requires/validates that `DXGI_SAMPLE_DESC::Count` matches the sample count of the bound render target(s) and depth stencil, if any. If no render targets or depth stencil will be bound, as indicated in the PSO desc by 0 for `NumRenderTargets` and `DXGI_FORMAT_UNKNOWN` for depth format, then `DXGI_SAMPLE_DESC::Count` must be 0 or 1, indicating no multisampling. It's still valid to use `ForcedSampleCount` to do MSAA rasterization, but this carries forward the restrictions around sample-frequency execution.

Going forward, D3D12 will allow `DXGI_SAMPLE_DESC::Count` to be > 1 when no render targets or depth stencil are bound. When this is the case, behavior is expected to be basically identical to setting `ForcedSampleCount` > 1, except that sample-frequency pixel shader execution is allowed and well-defined. `DXGI_SAMPLE_DESC::Quality` must be 0 or `D3D12_STANDARD_MULTISAMPLE_PATTERN`. When programmable sample positions are set on the command list, those sample positions are used by this type of rendering as well.

Existing interactions with `ForcedSampleCount` remain:
* If `DXGI_SAMPLE_DESC::Count` > 1, `ForcedSampleCount` must be 0 or 1. 0 indicates multisample rasterization, while 1 indicates single-sample rasterization. If there are render targets or depth stencil bound, the results of rasterization and pixel shading are broadcast to all samples for the pixel.
* If `DXGI_SAMPLE_DESC::Count` == 1, `ForcedSampleCount` may be larger, but all existing rules around TIR remain.

Since there is no format for which to use `CheckFeatureSupport(D3D12_FEATURE_MULTISAMPLE_QUALITY_LEVELS, ...)` to query valid multisample counts, we will provide a bitmask to apps indicating which sample counts are valid. Since only powers of two are possible, and no driver-specific quality levels are exposed, a single 32-bit `UINT` should be sufficient.

### API

This is only semantic changes, except for a new `UINT` feature option: `SupportedSampleCountsWithNoOutputs`. This will report a value of 1, indicating simple-sampled only, for drivers that do not support the feature.

### DDI

Same as above, this is only semantic changes except for a new driver-provided cap indicating allowed sample counts. This feature is required for FL11.1 hardware when DDI version is 0102 or greater, meaning the driver must provide a supported sample count bitmask with at least the following bits set: `0b11101`, corresponding to the existing TIR requirements to support 1, 4, 8, and 16 samples.

### Tests: Functional

Trivially validate core runtime validation for interaction with `SupportedSampleCountsWithNoOutputs` and PSO's sample count. Validate interaction with PSO sample count and TIR setting when no outputs are bound.

### Tests: Conformance

The tests for programmable sample positions are extended to include coverage of:
1. UAV-only rasterization with the standard sample positions.
2. UAV-only rasterization with programmable MSAA tier 1 (per-pixel sample positions)
3. UAV-only rasterization with programmable MSAA tier 2 (per-quad sample positions)

All of these tests iterate over `ForcedSampleCount` at pixel frequency, `DXGI_SAMPLE_DESC::Count` at pixel frequency, and `DXGI_SAMPLE_DESC::Count` at sample frequency. Note that test 1 runs for all existing drivers (filling missing coverage), and test 2 runs for existing drivers that support programmable MSAA tier 1 (filling missing coverage). Test 3 only supports running with `DXGI_SAMPLE_DESC::Count` since it requires a sample count of 2, which is not a valid TIR sample count.

---

## `DXGI_FORMAT_A4B4G4R4_UNORM`

### Description

DXGI has one similar format: `DXGI_FORMAT_B4G4R4A4_UNORM`. This new format, like the existing one, will be all alone in its cast set with no `_TYPELESS` format. Thanks to the new format cast list functionality, it is possible to explicitly request that they be castable to each other during resource creation, but if that is not done, casting is disallowed.

The only required capability for this new format is texture sampling (including load/gather). No render target or UAV support is required. Similar to the existing format, RTV and UAV support will be optional.

### API

```c++
typedef enum DXGI_FORMAT
{
...
    DXGI_FORMAT_A4B4G4R4_UNORM = 191,
...
} DXGI_FORMAT;
```

### DDI

This format will be required for drivers with DDI version 0102 or greater. No new DDIs are added. The driver can expect to see this format showing up in resource/view creation, `CopyTextureRegion` buffer descriptions, and `CheckFormatSupport` calls for RTV/UAV related features.

### Tests: Conformance

Existing test content that hits `DXGI_FORMAT_B4G4R4A4_UNORM` is largely going to be based around D3D11On12, therefore support will be added to D3D11 so that this feature is available when running through D3D11On12 on a new driver.

---

## Changing the spec for point sampling address computations

### Description

The D3D11 spec for texture point sampling has unexpected consequences. [Section 7.18.7](https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm#7.18.7%20Point%20Sample%20Addressing) says:

> Given a 1D texture coordinate in normalized space `U`, assumed to be any float32 value.
> `U` is scaled by the Texture1D size. Call this `scaledU`
> `scaledU` is converted to at least 16.8 Fixed Point[(3.2.4.1)](https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm#FLOATtoFIXED). Call this `fxpScaledU`.
> The integer part of `fxpScaledU` is the chosen texel. Call this `t`. Note that the conversion to Fixed Point[(3.2.4.1)](https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm#FLOATtoFIXED) basically accomplished: `t = floor(scaledU)`.

The conversion to fixed point in 3.2.4.1 says:
> The diagram below depicts the ideal/reference float to fixed conversion (including round-to-nearest-even)

The choice of round-to-nearest-even for this conversion can result in surprising behavior, where a coordinate that's close to the right edge of a texel can end up snapping to the next texel, despite the intention that the calculation here should "basically accomplish" a `floor()`.

Going forward, this conversion to fixed point should use round-toward-negative-infinity as the ideal rounding mode, with an allowance for truncate / round-towards-zero. Essentially, for non-negative coordinates, this snapping should never occur.

### API

A new feature option `PointSamplingAddressesNeverRoundUp` will be reported indicating that the driver complies with the new expected behavior.

### DDI

This feature is required for drivers with DDI version 0102 and newer.

### Test: Conformance

WGF11Filter.exe will be updated to change its reference implementation based on this new API feature option when running through D3D11On12.

---

## Line rasterization updates

### Description

D3D11 specs 3 algorithms for lines:
1. Aliased (using the Bresenham algorithm)
2. Alpha antialiased (using an undefined algorithm)
3. Quadrilateral (drawing line as 2 triangles)

The mode for selecting which algorithm to use is... [bad](https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm#StateInteractionWithRasterization). The rasterizer desc `MultisampleEnable` bit chooses quadrilateral lines, and if that's not set, then `AntialiasedLineEnable` toggles between alpha-antialiased or aliased. Let's fix this, and replace these 2 separate BOOLs with a proper enum.

Additionally, the spec for [quadrilateral lines](https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm#3.4.5%20Quadrilateral%20Line%20Rasterization%20Rules) says that the width needs to be 1.4, as an arbitrary choice.

To be conformant for Vulkan, we need to be able to draw quadrilateral lines with a width of 1.0. An additional line mode will be added to explicitly select that.

### API

The rasterizer desc will be updated:

```c++
typedef enum D3D12_LINE_RASTERIZATION_MODE
{
    D3D12_LINE_RASTERIZATION_MODE_ALIASED,
    D3D12_LINE_RASTERIZATION_MODE_ALPHA_ANTIALIASED,
    D3D12_LINE_RASTERIZATION_MODE_QUADRILATERAL_WIDE,
    D3D12_LINE_RASTERIZATION_MODE_QUADRILATERAL_NARROW,
} D3D12_LINE_RASTERIZATION_MODE;

typedef struct D3D12_RASTERIZER_DESC2
{
    D3D12_FILL_MODE FillMode;
    D3D12_CULL_MODE CullMode;
    BOOL FrontCounterClockwise;
    FLOAT DepthBias;
    FLOAT DepthBiasClamp;
    FLOAT SlopeScaledDepthBias;
    BOOL DepthClipEnable;
    D3D12_LINE_RASTERIZATION_MODE LineRasterizationMode;
    UINT ForcedSampleCount;
    D3D12_CONSERVATIVE_RASTERIZATION_MODE ConservativeRaster;
} D3D12_RASTERIZER_DESC2;
```

This desc will be available on all new versions of D3D12. Two feature bits are added: `RasterizerDesc2Supported` indicating that the struct itself is supported, and `NarrowQuadrilateralLinesSupported` indicating that `D3D12_LINE_RASTERIZATION_MODE_QUADRILATERAL_NARROW` can be used.

*Note*: It seems in-market drivers sometimes use widths of 1.0 today. Going forward, the plan is for the originally specced width of 1.4 to be required, as validated by the test content described below, unless content is discovered where that is problematic. If such a case does arise, the D3D spec will be relaxed such that `QUADRILATERAL_WIDE` is allowed to indicate a width in the range [1.0, 1.4], while `QUADRILATERAL_NARROW` retains its strictly-specified 1.0.

### DDI

Identical changes will be made to the DDI rasterizer desc structs. For older drivers, when `D3D12_RASTERIZER_DESC2` is used, the `LineRasterizationMode` will be decomposed back to the two bits, with `D3D12_LINE_RASTERIZATION_MODE_QUADRILATERAL_WIDE` translating to `MultisampleEnable` = true and `AntialiasedLineEnable` = false.

This feature is required for drivers supporting DDI version 0102 or newer.

### Tests: Functional

A test will be added to ensure `D3D12_RASTERIZER_DESC2` works on old drivers and that `D3D12_LINE_RASTERIZATION_MODE_QUADRILATERAL_NARROW` is appropriately disallowed.

### Tests: Conformance

Targeted tests will be authored to validate pixel/sample coverage from drawing quadrilateral lines of 1.4 and 1.0 widths. These tests will not be exhaustive and will not cover diagonals.

---

## Anisotropic sampler with mip point

### Description

D3D's filter enum puts anisotropic as a separate bit, independent from the point/linear selection on min/mag/mip:

```c++
    // Bits used in defining enumeration of valid filters:
    // bits [1:0] - mip: 0 == point, 1 == linear, 2,3 unused
    // bits [3:2] - mag: 0 == point, 1 == linear, 2,3 unused
    // bits [5:4] - min: 0 == point, 1 == linear, 2,3 unused
    // bit  [6]   - aniso
```

However, it's invalid to specify a filter that's not explicitly enumerated in the API enum, and the only option for aniso sets all 3 of these to linear. This feature adds a new valid variation where mip is set to point.

### API

A new feature bit is added: `AnisoFilterWithPointMipSupported`. When this is true, the following enum values in the filter enum become valid:

```c++
typedef enum D3D12_FILTER
{
    // Bits used in defining enumeration of valid filters:
    // bits [1:0] - mip: 0 == point, 1 == linear, 2,3 unused
    // bits [3:2] - mag: 0 == point, 1 == linear, 2,3 unused
    // bits [5:4] - min: 0 == point, 1 == linear, 2,3 unused
    // bit  [6]   - aniso
    // bits [8:7] - reduction type:
    //                0 == standard filtering
    //                1 == comparison
    //                2 == min
    //                3 == max

...
    D3D12_FILTER_MIN_MAG_ANISOTROPIC_MIP_POINT                  = 0x00000054,
    D3D12_FILTER_ANISOTROPIC                                    = 0x00000055,
...
    D3D12_FILTER_COMPARISON_MIN_MAG_ANISOTROPIC_MIP_POINT       = 0x000000d4,
    D3D12_FILTER_COMPARISON_ANISOTROPIC                         = 0x000000d5,
...
    D3D12_FILTER_MINIMUM_MIN_MAG_ANISOTROPIC_MIP_POINT          = 0x00000154,
    D3D12_FILTER_MINIMUM_ANISOTROPIC                            = 0x00000155,
...
    D3D12_FILTER_MAXIMUM_MIN_MAG_ANISOTROPIC_MIP_POINT          = 0x000001d4,
    D3D12_FILTER_MAXIMUM_ANISOTROPIC                            = 0x000001d5
} D3D12_FILTER;
```

### DDI

This feature is required for drivers supporting DDI version 0102 or newer. Matching DDI filter enum values will be added.

### Tests: Conformance

D3D9 conformance tests exist for the standard filtering variation of this filter mode. These will be tested through D3D9On12.

Targeted tests will need to be built for comparison and min/max filtering. These will be added to our backlog of test debt.

---

## Sampler descriptor heap size increase

### Description

To properly support the `VK_EXT_descriptor_indexing` extension, we need the ability to create shader-visible sampler descriptor heaps larger than the current limit of 2048.

### API

Three new feature options will be added:
| Option | Description |
|--|--|
| `MaxSamplerDescriptorHeapSize` | For new drivers, this will come from the driver, and must be at least 4000. For old drivers, D3D will set this to 2048. Attempting to create a shader-visible sampler descriptor heap with more than this many descriptors will fail. |
| `MaxSamplerDescriptorHeapSizeWithStaticSamplers` | For new drivers, this will come from the driver, and must be at least 2048. For old drivers, D3D will set this to 2048. Attempting to draw/dispatch (compute, mesh, rays) with a root signature bound that includes static samplers, and with a sampler descriptor heap bound with more than this many descriptors, is undefined behavior and will produce a debug layer error. |
| `MaxViewDescriptorHeapSize` | For new drivers, this will come from the driver, and must be at least 1,000,000. For old drivers, D3D will set this to 1,000,000. Attempting to create a shader-visible view descriptor heap with more than this many descriptors will fail for new drivers. For old drivers reporting `D3D12_BINDING_TIER_3`, requests for heaps larger than 1,000,000 will still be sent to the driver, with the expectation that they may fail. |

### DDI

This is a required feature for drivers with DDI version 0102 or newer. The driver must set the new caps to appropriate values, and handle shader-visible descriptor heap creation up to the new limits.

### Tests: Functional

* Ensure the appropriate debug layer error is output when mixing static samplers with large sampler heaps.
* Ensure appropriate failures + messages when exceeding the sampler/view descriptor heap limits.

### Tests: Conformance

The existing test which exercises max-size sampler heaps is updated to target the new dynamic maximum size.
