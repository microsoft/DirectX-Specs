- [Partial Graphics Programs](#partial-graphics-programs)
  - [Pre-rasterization shaders partial program](#pre-rasterization-shaders-partial-program)
  - [Pixel shader partial program](#pixel-shader-partial-program)
  - [Notes](#notes)
  - [Use in generic programs](#use-in-generic-programs)
- [API](#api)
  - [Device Methods](#device-methods)
    - [CheckFeatureSupport](#checkfeaturesupport)
    - [CheckFeatureSupport Structures](#checkfeaturesupport-structures)
      - [D3D12\_FEATURE\_DATA\_PARTIAL\_GRAPHICS\_PROGRAMS](#d3d12_feature_data_partial_graphics_programs)
      - [D3D12\_PARTIAL\_GRAPHICS\_PROGRAMS\_TIER](#d3d12_partial_graphics_programs_tier)
  - [D3D12\_STATE\_SUBOBJECT\_TYPE](#d3d12_state_subobject_type)
  - [D3D12\_PARTIAL\_GRAPHICS\_PROGRAM\_TYPE](#d3d12_partial_graphics_program_type)
  - [D3D12\_PARTIAL\_GRAPHICS\_PROGRAM\_DESC](#d3d12_partial_graphics_program_desc)
  - [D3D12\_OUTPUT\_LINKAGE\_SIGNATURE\_DESC](#d3d12_output_linkage_signature_desc)
  - [D3D12\_OUTPUT\_LINKAGE\_ELEMENT\_DESC](#d3d12_output_linkage_element_desc)
  - [D3D12\_PRERASTERIZATION\_OUTPUT\_LINKAGE\_SIGNATURE\_DESC](#d3d12_prerasterization_output_linkage_signature_desc)
  - [D3D12\_PRERASTERIZATION\_OUTPUT\_LINKAGE\_ELEMENT\_DESC](#d3d12_prerasterization_output_linkage_element_desc)
  - [D3D12\_PRERASTERIZATION\_SHADERS\_PARTIAL\_PROGRAM\_FIELDS](#d3d12_prerasterization_shaders_partial_program_fields)
  - [D3D12\_PIXEL\_SHADER\_PARTIAL\_PROGRAM\_FIELDS](#d3d12_pixel_shader_partial_program_fields)
- [DDI](#ddi)
  - [D3D12DDI\_STATE\_SUBOBJECT\_TYPE](#d3d12ddi_state_subobject_type)
  - [D3D12DDI\_PARTIAL\_GRAPHICS\_PROGRAM\_TYPE](#d3d12ddi_partial_graphics_program_type)
  - [D3D12DDI\_PARTIAL\_GRAPHICS\_PROGRAM\_DESC\_0121](#d3d12ddi_partial_graphics_program_desc_0121)
  - [D3D12DDI\_OUTPUT\_LINKAGE\_SIGNATURE\_DESC\_0121](#d3d12ddi_output_linkage_signature_desc_0121)
  - [D3D12DDI\_OUTPUT\_LINKAGE\_ELEMENT\_DESC\_0121](#d3d12ddi_output_linkage_element_desc_0121)
  - [D3D12DDI\_PRERASTERIZATION\_OUTPUT\_LINKAGE\_SIGNATURE\_DESC\_0121](#d3d12ddi_prerasterization_output_linkage_signature_desc_0121)
  - [D3D12DDI\_PRERASTERIZATION\_OUTPUT\_LINKAGE\_ELEMENT\_DESC\_0121](#d3d12ddi_prerasterization_output_linkage_element_desc_0121)
  - [D3D12DDI\_PRERASTERIZATION\_SHADERS\_PARTIAL\_PROGRAM\_FIELDS\_0121](#d3d12ddi_prerasterization_shaders_partial_program_fields_0121)
  - [D3D12DDI\_PIXEL\_SHADER\_PARTIAL\_PROGRAM\_FIELDS\_0121](#d3d12ddi_pixel_shader_partial_program_fields_0121)
- [Reporting Partial Graphics Programs Support](#reporting-partial-graphics-programs-support)
  - [D3D12DDI\_PARTIAL\_GRAPHICS\_PROGRAMS\_TIER](#d3d12ddi_partial_graphics_programs_tier)
- [State Object Compilation Flags](#state-object-compilation-flags)
  - [State Object Flag](#state-object-flag)
  - [How to measure if these flags work?](#how-to-measure-if-these-flags-work)
- [History](#history)

# Partial Graphics Programs

PSOs exist for two reasons:
- Providing some "fixed function" pipeline state to the driver during shader compilation so that parts of the pipeline can be implemented in shader code.
- Providing most "fixed function" state together so that the hardware can be programmed efficiently at SetPSO time, regardless of the actual commands that the hardware needs, instead of having to defer emitting state setting operations to draw time for cases where the API grouping mismatches hardware grouping.

The original PSO design recognized that grouping everything together solved both of these problems at once. However, by including too much state in the compilation process, minor changes between PSOs in a game can result in a lot of PSO combinations that use the same set of shaders. As a result, we see redundant compilation work and too much memory consumption. Partial programs aim to split these back apart, allowing the application to specify a minimum set of states during a compilation step, and then provide the rest of the state while linking to get an object that can be set. This link should therefore not generate any shader code and should be cheap.

A graphics pipeline state can be split into potentially four chunks of shader code:
- Input layout subobject
- Pre-rasterization shader(s)
- Pixel shader
- Blend subobject

Generating shader code for the input layout and blend portions of the pipeline, if they are implemented in shader code at all, is considered trivial and does not require pre-compilation, so they do not have their own partial program pieces. They can still be inlined in their corresponding partial program if they don't need to vary. As a result, input layout and Blend can be defined external to the partial programs, or they can be added to the pre-rasterization and pixel shader partial programs respectively.

Partial programs are an addition to the [state object generic programs](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#generic-programs); they can be defined in collections or in executable state objects. When a partial program is added as a part of a collection it is expected to be compiled as part of the collection state object creation. The compiled partial program is not always going to be optimal; it depends on what is included in the partial program. App developers can give hints to the driver on how to handle the linking and potential recompilation when combining a partial program with other state subobjects/partial program by using [State Object Compilation Flags](#state-object-compilation-flags).

Partial programs can be defined as:
- Pre-rasterization shader(s) partial program
- Pixel shader partial program
- A partial program combining pre-rasterization and pixel shaders, later used with other state subobjects to form a full program. In that case, the two tables below effectively become combined (i.e. you can specify any subobject in either table), except that the output linkage subobjects become invalid, since they can be deduced from the provided shaders. The use case for declaring a combined partial program like this is to allow some of the other fixed-function state to vary without worrying about it impacting shader compilation.

## Pre-rasterization shaders partial program

This partial program includes:

Subobject type                                              | Is it required?           | Notes
---------                                                   | ----------                | ----------
Primitive topology                                          | Yes, excluding MS         | If specified for a mesh shader then it must match the topology specified in the shader code.
Shader(s)                                                   | Yes                       | This is used to define the pre-rasterization shader(s): <li>VS, DS, HS, and GS, valid combinations</li><li>AS and MS</li><li>mesh node shader (currently in public preview)</li>These shaders can be present in the state object directly or indirectly using an existing collection.
View instancing                                             | Optional                  | If not present [default value](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-view_instancing) is used for this subobject. If not set here it can't be overridden later in the full program.
Output linkage signature                                    | Conditional               | The [D3D12_OUTPUT_LINKAGE_SIGNATURE_DESC](#d3d12_output_linkage_signature_desc) subobject describes the outputs and is used to validate that they are an exact match for the non-system-value inputs to the pixel shader. This is used to help optimize the shader compilation by eliminating unused attributes. This is required for MS partial programs.
Root signature                                              | Yes, indirectly specified | This can't be added explicitly in the partial program but needs to be defined in the shader or deduced for e.g. from an association to the pre-rasterization shaders.
Pre-rasterization shaders partial program fields            | Optional                  | The [D3D12_PRERASTERIZATION_SHADERS_PARTIAL_PROGRAM_FIELDS](#d3d12_prerasterization_shaders_partial_program_fields) subobject provides a way to indicate `ExcludePS` and `LateLinkInputLayoutSubobject`.
Input layout                                                | Optional                  | This can be specified in the pre-rasterization partial program or included in the full graphics program specification. To indicate that the input layout subobject is going to be late linked when specifying the full program, `LateLinkInputLayoutSubobject` needs to be set to true in the pre-rasterization shaders partial program fields subobject. If the `LateLinkInputLayoutSubobject` is set to false and there is no input layout subobject specified then the driver assumes [default value](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-input_layout) and can't be overridden later in the full program.
Index buffer strip cut value                                | Optional                  | This can be specified in the pre-rasterization partial program or included in the full graphics program specification. If not present in either the driver will assume [default value](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-index_buffer_strip_cut_value)

## Pixel shader partial program

This partial program includes:

Subobject type                                              | Is it required?           | Notes
---------                                                   | ----------                | ----------
Shader                                                      | Yes                       | This is used to define the pixel shader. The shader can be present in the state object directly or indirectly using an existing collection.
PS partial program fields                                   | Optional                  | The [D3D12_PIXEL_SHADER_PARTIAL_PROGRAM_FIELDS](#d3d12_pixel_shader_partial_program_fields) subobject includes fields from the rasterizer and blend subobjects. These field values are baked into the PS partial program, they can't be overridden by specifying a blend/rasterizer subobject when using the PS partial program. If this subobject is not present, and a blend/rasterizer subobject is, then the values for the fields are taken from the larger object. If neither subobject is present, then the values are set to [default](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#defaults-for-subobjects-missing-from-a-generic-program). If both subobjects are present, the values must match - this may be the case if (e.g.) a non-default value is needed for LineRasterizationMode. The full rasterizer desc is not known, and the full blend desc is provided, then there is redundant data for the field(s) coming from the blend subobject.
Rasterizer desc                                             | Optional                  | The `LineRasterizationMode` and `ForcedSampleCount` fields in the rasterizer desc have an impact on the PS partial program compilation. These two fields, if they have non-default values, can be specified using a PS partial program fields subobject or the full subobject. If the subobject is not present, and a PS partial program fields subobject is, then the values for the fields are taken from there. The rasterizer desc subobject can be included in the PS partial program or it can be specified when the PS partial program is combined with other state. To indicate that the rasterizer desc subobject is going to be late linked when specifying the full program, `LateLinkRasterizerSubobject` needs to be set to true in the PS partial program. If `LateLinkRasterizerSubobject` is set to false and there is no rasterizer subobject specified then the driver assumes [default value](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-rasterizer).
Blend                                                       | Optional                  | The `AlphaToCoverageEnable` field in blend desc has an impact on the PS partial program compilation. This field, if it has a non-default value, can be specified using a PS partial program fields subobject or the full subobject. If this subobject is not present, and the PS partial program fields subobject is, then the value is taken from there. The blend subobject can be included in the PS partial program or it can be specified when the PS partial program is combined with other state. To indicate that the blend subobject is going to be late linked when specifying the full program, `LateLinkBlendSubobject` needs to be set to true in the PS partial program. If `LateLinkBlendSubobject` is set to false and there is no blend subobject specified then the driver assumes [default value](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-blend) and can't be overridden later in the full program.
Root signature                                              | Yes, indirectly specified | This can't be added explicitly in the partial program but needs to be defined in the shader or deduced for e.g. from an association to the pixel shader.
Primitive topology                                          | Optional                  | GS, MS, or else the IA primitive topology if neither GS nor MS are present. This is added using the `D3D12_PRIMITIVE_TOPOLOGY_TYPE`, with these valid types: point, line, and triangle. If this is not specified then the default is triangle. If the PS partial program topology needs to have a non-default value then a primitive topology subobject needs to be included.
Pre-rasterization output linkage                            | Conditional               | The [D3D12_PRERASTERIZATION_OUTPUT_LINKAGE_SIGNATURE_DESC](#d3d12_prerasterization_output_linkage_signature_desc) subobject describes the outputs. This is required for PS partial programs that are combined with a pre-rasterization partial program (excluding MS ones) using view instancing. This must be an exact match for the pre-rasterization partial program output linkage signature and the non-system-value inputs to the pixel shader.
Representative MS                                           | Conditional               | This is required for PS partial programs that are combined with a pre-rasterization partial program using MS. This is required to be an exact match of the mesh shader output declaration for the pre-rasterization partial program mesh shader. The values that are consumed by a PS must have the same DXC-produced register and component mappings as any other mesh shader that will be used with this pixel shader partial program. This is not to be compiled as a MS and is only used for linking MS output with PS inputs.
Sample mask                                                 | Optional                  | This can be specified if the subobject needs a non-default value. If this subobject is not present because it is going to be late linked when specifying the full program, the PS partial program fields subobject field `LateLinkSampleMaskSubobject` needs to be set to true in the PS partial program. If `LateLinkSampleMaskSubobject` is set to false and there is no sample mask subobject specified then the driver assumes [default value](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-sample_mask) and can't be overridden later in the full program.
Sample desc                                                 | Optional                  | This can be specified if the subobject needs a non-default value. If this subobject is not present because it is going to be late linked when specifying the full program, the PS partial program fields subobject field `LateLinkSampleDescSubobject` needs to be set to true in the PS partial program. If `LateLinkSampleDescSubobject` is set to false and there is no sample desc subobject specified then the driver assumes [default value](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-sample_desc) and can't be overridden later in the full program.
Depth stencil format                                        | Optional                  | This can be specified if the subobject needs a non-default value. If this subobject is not present because it is going to be late linked when specifying the full program, the PS partial program fields subobject field `LateLinkDepthStencilFormatSubobject` needs to be set to true in the PS partial program. If `LateLinkDepthStencilFormatSubobject` is set to false and there is no depth stencil format subobject specified then the driver assumes [default value](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-depth_stencil_format) and can't be overridden later in the full program.
Render target format                                        | Optional                  | This can be specified if the subobject needs a non-default value. If this subobject is not present because it is going to be late linked when specifying the full program, the PS partial program fields subobject field `LateLinkRenderTargetFormatSubobject` needs to be set to true in the PS partial program. If `LateLinkRenderTargetFormatSubobject` is set to false and there is no render target format subobject specified then the driver assumes [default value](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-render_target_formats) and can't be overridden later in the full program.
Depth stencil                                               | Optional                  | This can be specified if the subobject needs a non-default value. If this subobject is not present because it is going to be late linked when specifying the full program, the PS partial program fields subobject field `LateLinkDepthStencilSubobject` needs to be set to true in the PS partial program. If `LateLinkDepthStencilSubobject` is set to false and there is no depth stencil subobject specified then the driver assumes [default value](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-depth_stencil-or-depth_stencil1-or-depth_stencil2)

## Notes
- Stream output subobject is not valid for use in partial programs.
- Any subobject not mentioned in the above partial programs can be included as part of the combined program. The exception is root signatures which are specified directly in shaders or associated directly with them rather than listed in program definitions.

## Use in generic programs

A graphics generic programs can be defined using partial graphics programs. To reference a partial graphics program in a generic program specify the partial graphics program name as an export in the 
[generic program desc](https://microsoft.github.io/DirectX-Specs/d3d/WorkGraphs.html#d3d12_generic_program_desc). A partial graphics program is only allowed to be referenced by name, it can't be added as a subobject when specifying a generic program.

---

# API

## Device Methods

Per D3D12 device interface semantics, these device methods can be called by multiple threads simultaneously.

### CheckFeatureSupport
```cpp
HRESULT CheckFeatureSupport(
    D3D12_FEATURE Feature,
    [annotation("_Inout_updates_bytes_(FeatureSupportDataSize)")]
    void* pFeatureSupportData,
    UINT FeatureSupportDataSize
    );
```
This isn't a partial graphics programs specific API, just the generic D3D API for querying feature support. To query for partial graphics programs support, pass D3D12_FEATURE_PARTIAL_GRAPHICS_PROGRAMS for Feature, and point pFeatureSupportData to a D3D12_FEATURE_DATA_PARTIAL_GRAPHICS_PROGRAMS variable. This has a member D3D12_PARTIAL_GRAPHICS_PROGRAMS_TIER PartialGraphicsProgramsTier.

### CheckFeatureSupport Structures

#### D3D12_FEATURE_DATA_PARTIAL_GRAPHICS_PROGRAMS
```cpp
typedef struct D3D12_FEATURE_DATA_PARTIAL_GRAPHICS_PROGRAMS
{
    [annotation("_Out_")] D3D12_PARTIAL_GRAPHICS_PROGRAMS_TIER PartialGraphicsProgramsTier;
} D3D12_FEATURE_DATA_PARTIAL_GRAPHICS_PROGRAMS;

```

#### D3D12_PARTIAL_GRAPHICS_PROGRAMS_TIER
```cpp
typedef enum D3D12_PARTIAL_GRAPHICS_PROGRAMS_TIER
{
    D3D12_PARTIAL_GRAPHICS_PROGRAMS_TIER_NOT_SUPPORTED = 0,
    D3D12_PARTIAL_GRAPHICS_PROGRAMS_TIER_1_0 = 10,
} D3D12_PARTIAL_GRAPHICS_PROGRAMS_TIER;
```

Value                                                | Definition
---------                                            | ----------
`D3D12_PARTIAL_GRAPHICS_PROGRAMS_TIER_NOT_SUPPORTED` | No support for partial graphics programs on the device. Attempts to create any state objects using partial graphics program subobjects will fail.
`D3D12_PARTIAL_GRAPHICS_PROGRAMS_TIER_1_0`           | The device supports the full partial graphics programs functionality described in this spec.

## D3D12_STATE_SUBOBJECT_TYPE

The enum struct below only shows the subobject type relevant to this spec. See [DXR](Raytracing.md) and [WG](WorkGraphs.md) specs for all the other subobject types available.

```cpp
typedef enum D3D12_STATE_SUBOBJECT_TYPE
{
    .....
    D3D12_STATE_SUBOBJECT_TYPE_PARTIAL_GRAPHICS_PROGRAM, // D3D12_PARTIAL_GRAPHICS_PROGRAM_DESC
    D3D12_STATE_SUBOBJECT_TYPE_OUTPUT_LINKAGE_SIGNATURE, // D3D12_OUTPUT_LINKAGE_SIGNATURE_DESC
    D3D12_STATE_SUBOBJECT_TYPE_PRERASTERIZATION_OUTPUT_LINKAGE_SIGNATURE, // D3D12_PRERASTERIZATION_OUTPUT_LINKAGE_SIGNATURE_DESC
    D3D12_STATE_SUBOBJECT_TYPE_PRERASTERIZATION_SHADERS_PARTIAL_PROGRAM_FIELDS, // D3D12_PRERASTERIZATION_SHADERS_PARTIAL_PROGRAM_FIELDS
    D3D12_STATE_SUBOBJECT_TYPE_PIXEL_SHADER_PARTIAL_PROGRAM_FIELDS, // D3D12_PIXEL_SHADER_PARTIAL_PROGRAM_FIELDS
    // todo: do we need a pixel shader output linkage
}
```

## D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE

```cpp
typedef enum D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE
{
    D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE_NONE,
    D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE_PRERASTERIZATION_SHADER,
    D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE_PIXEL_SHADER,
} D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE;
```

## D3D12_PARTIAL_GRAPHICS_PROGRAM_DESC

```cpp
typedef
struct D3D12_PARTIAL_GRAPHICS_PROGRAM_DESC
{
    LPCWSTR ProgramName;
    UINT NumExports;
    [annotation("_In_reads_(NumExports)")] LPCWSTR* pExports;

    UINT    NumSubobjects;
    [annotation("_In_reads_opt_(NumSubobjects)")] const D3D12_STATE_SUBOBJECT* const* ppSubobjects;
    D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE ProgramType;
} D3D12_PARTIAL_GRAPHICS_PROGRAM_DESC;
```

## D3D12_OUTPUT_LINKAGE_SIGNATURE_DESC
```cpp
typedef
struct D3D12_OUTPUT_LINKAGE_SIGNATURE_DESC
{
    const D3D12_OUTPUT_LINKAGE_ELEMENT_DESC *pOutputLinkageElementDescs;
    UINT NumElements;
} D3D12_OUTPUT_LINKAGE_SIGNATURE_DESC;
```

Members                                                                 | Description
------                                                                  | ----------
`const D3D12_OUTPUT_LINKAGE_ELEMENT_DESC *pOutputLinkageElementDescs`   | Description of output linkage elements
`UINT NumElements`                                                      | Number of elements

## D3D12_OUTPUT_LINKAGE_ELEMENT_DESC

```cpp
typedef
struct D3D12_OUTPUT_LINKAGE_ELEMENT_DESC
{
    LPCSTR SemanticName;
    UINT SemanticIndex;
    BYTE StartComponent;
    BYTE ComponentCount;
    BOOL IsPrimitive;
} D3D12_OUTPUT_LINKAGE_ELEMENT_DESC;
```

Members                     | Description
------                      | ----------
`LPCSTR SemanticName`       | The system or user semantic associated with this element. See [HLSL Semantics](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-semantics) for system semantic info.
`UINT SemanticIndex`        | The zero-based semantic index of the element.
`BYTE StartComponent`       | The component of the entry to begin writing out to.
`BYTE ComponentCount`       | The number of components of the entry to write out to.
`BOOL IsPrimitive`          | Set to `True` if this element is a primitive.

## D3D12_PRERASTERIZATION_OUTPUT_LINKAGE_SIGNATURE_DESC

```cpp
typedef
struct D3D12_PRERASTERIZATION_OUTPUT_LINKAGE_SIGNATURE_DESC
{
    const D3D12_PRERASTERIZATION_OUTPUT_LINKAGE_ELEMENT_DESC *pOutputLinkageElementDescs;
    UINT NumElements;
} D3D12_PRERASTERIZATION_OUTPUT_LINKAGE_SIGNATURE_DESC;
```

Members                                                                 | Description
------                                                                  | ----------
`const D3D12_PRERASTERIZATION_OUTPUT_LINKAGE_ELEMENT_DESC *pOutputLinkageElementDescs`   | Description of output linkage elements
`UINT NumElements`                                                      | Number of elements

## D3D12_PRERASTERIZATION_OUTPUT_LINKAGE_ELEMENT_DESC

```cpp
typedef
struct D3D12_PRERASTERIZATION_OUTPUT_LINKAGE_ELEMENT_DESC
{
    LPCSTR SemanticName;
    UINT SemanticIndex;
    BYTE StartComponent;
    BYTE ComponentCount;
    BOOL IsPrimitive;
} D3D12_PRERASTERIZATION_OUTPUT_LINKAGE_ELEMENT_DESC;
```

Members                     | Description
------                      | ----------
`LPCSTR SemanticName`       | The system or user semantic associated with this element. See [HLSL Semantics](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-semantics) for system semantic info.
`UINT SemanticIndex`        | The zero-based semantic index of the element.
`BYTE StartComponent`       | The component of the entry to begin writing out to.
`BYTE ComponentCount`       | The number of components of the entry to write out to.
`BOOL IsPrimitive`          | Set to `True` if this element is a primitive.

**TODO (Add a helper in d3dx that helps generate the linkage desc from a pair of example shaders. So apps don't have to make these by hand.)**

## D3D12_PRERASTERIZATION_SHADERS_PARTIAL_PROGRAM_FIELDS

```cpp
typedef
struct D3D12_PRERASTERIZATION_SHADERS_PARTIAL_PROGRAM_FIELDS
{
    BOOL ExcludePS;
    BOOL LateLinkInputLayoutSubobject;
} D3D12_PRERASTERIZATION_SHADERS_PARTIAL_PROGRAM_FIELDS;
```

Members                         | Description
------                          | ----------
`ExcludePS`                     | Specifies whether the pre-rasterization shaders partial program is going to be linked with a pixel shader or not. A partial program with `ExcludePS` can only be used in a generic program that doesn't include a pixel shader.
`LateLinkInputLayoutSubobject`  | Specifies whether the pre-rasterization shaders partial program input layout subobject will be late linked. When it is set to false that means that when the subobject is not available in the pixel shader partial program then, the driver will use default values.

## D3D12_PIXEL_SHADER_PARTIAL_PROGRAM_FIELDS

```cpp
typedef
struct D3D12_PIXEL_SHADER_PARTIAL_PROGRAM_FIELDS
{
    D3D12_LINE_RASTERIZATION_MODE LineRasterizationMode;
    UINT ForcedSampleCount;
    BOOL AlphaToCoverageEnable;
    BOOL DualSourceBlendEnable;
    BOOL LateLinkRasterizerSubobject;
    BOOL LateLinkBlendSubobject;
    BOOL LateLinkSampleMaskSubobject;
    BOOL LateLinkSampleDescSubobject;
    BOOL LateLinkDepthStencilFormatSubobject;
    BOOL LateLinkRenderTargetFormatSubobject;
    BOOL LateLinkDepthStencilSubobject;
} D3D12_PIXEL_SHADER_PARTIAL_PROGRAM_FIELDS;
```

Members                                 | Description
------                                  | ----------
`LineRasterizationMode`                 | Specifies the rasterization mode type.
`ForcedSampleCount`                     | Specifies the rasterizer forced sample count.
`AlphaToCoverageEnable`                 | Specifies whether to use alpha-to-coverage as a multisampling technique when setting a pixel to a render target.
`DualSourceBlendEnable`                 | Specifies whether dual source blending is enabled or not.
`LateLinkRasterizerSubobject`           | Specifies whether the pixel shader partial program rasterizer subobject will be late linked. When it is set to false that means that when the subobject is not available in the pixel shader partial program then, the driver will use [default values](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-rasterizer).
`LateLinkBlendSubobject`                | Specifies whether the pixel shader partial program blend subobject will be late linked. When it is set to false that means that when the subobject is not available in the pixel shader partial program then, the driver will use [default values](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-blend).
`LateLinkSampleMaskSubobject`           | Specifies whether the pixel shader partial program sample mask subobject will be late linked. When it is set to false that means that when the subobject is not available in the pixel shader partial program then, the driver will use [default values](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-sample_mask).
`LateLinkSampleDescSubobject`           | Specifies whether the pixel shader partial program sample desc subobject will be late linked. When it is set to false that means that when the subobject is not available in the pixel shader partial program then, the driver will use [default values](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-sample_desc).
`LateLinkDepthStencilFormatSubobject`   | Specifies whether the pixel shader partial program depth stencil format subobject will be late linked. When it is set to false that means that when the subobject is not available in the pixel shader partial program then, the driver will use [default values](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-depth_stencil_format).
`LateLinkRenderTargetFormatSubobject`   | Specifies whether the pixel shader partial program render target format subobject will be late linked. When it is set to false that means that when the subobject is not available in the pixel shader partial program then, the driver will use [default values](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-render_target_formats).
`LateLinkDepthStencilSubobject`         | Specifies whether the pixel shader partial program depth stencil subobject will be late linked. When it is set to false that means that when the subobject is not available in the pixel shader partial program then, the driver will use [default values](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-depth_stencil-or-depth_stencil1-or-depth_stencil2).

---

# DDI

## D3D12DDI_STATE_SUBOBJECT_TYPE

Below is a pruned list of the subobject types relevant to partial programs:

```cpp
typedef enum D3D12DDI_STATE_SUBOBJECT_TYPE
{
    ...
    D3D12DDI_STATE_SUBOBJECT_TYPE_PARTIAL_GRAPHICS_PROGRAM = 37,
    D3D12DDI_STATE_SUBOBJECT_TYPE_OUTPUT_LINKAGE_SIGNATURE = 38,
    D3D12DDI_STATE_SUBOBJECT_TYPE_PRERASTERIZATION_OUTPUT_LINKAGE_SIGNATURE = 39,
    D3D12DDI_STATE_SUBOBJECT_TYPE_PRERASTERIZATION_SHADERS_PARTIAL_PROGRAM_FIELDS = 40,
    D3D12DDI_STATE_SUBOBJECT_TYPE_PIXEL_SHADER_PARTIAL_PROGRAM_FIELDS = 41,
    ...
}
```

## D3D12DDI_PARTIAL_GRAPHICS_PROGRAM_TYPE

```cpp
typedef enum D3D12DDI_PARTIAL_GRAPHICS_PROGRAM_TYPE
{
    D3D12DDI_PARTIAL_GRAPHICS_PROGRAM_TYPE_NONE,
    D3D12DDI_PARTIAL_GRAPHICS_PROGRAM_TYPE_PRERASTERIZATION_SHADER,
    D3D12DDI_PARTIAL_GRAPHICS_PROGRAM_TYPE_PIXEL_SHADER,
} D3D12DDI_PARTIAL_GRAPHICS_PROGRAM_TYPE;
```

## D3D12DDI_PARTIAL_GRAPHICS_PROGRAM_DESC_0121

```cpp
typedef struct D3D12DDI_PARTIAL_GRAPHICS_PROGRAM_DESC_0121
{
    LPCWSTR ProgramName;
    UINT NumExports;
    LPCWSTR* pExports;
    UINT NumSubobjects;
    const D3D12DDI_STATE_SUBOBJECT_0054* const* pSubobjects;
    D3D12DDI_PARTIAL_GRAPHICS_PROGRAM_TYPE ProgramType;
} D3D12DDI_PARTIAL_GRAPHICS_PROGRAM_DESC_0121;
```

## D3D12DDI_OUTPUT_LINKAGE_SIGNATURE_DESC_0121

```cpp
typedef struct D3D12DDI_OUTPUT_LINKAGE_SIGNATURE_DESC_0121
{
    const D3D12DDI_OUTPUT_LINKAGE_ELEMENT_DESC_0121* pOutputLinkageElementDescs;
    UINT NumElements;
} D3D12DDI_OUTPUT_LINKAGE_SIGNATURE_DESC_0121;
```

## D3D12DDI_OUTPUT_LINKAGE_ELEMENT_DESC_0121

```cpp
typedef struct D3D12DDI_OUTPUT_LINKAGE_ELEMENT_DESC_0121
{
    LPCSTR SemanticName;
    UINT SemanticIndex;
    BYTE StartComponent;
    BYTE ComponentCount;
    BOOL IsPrimitive;
} D3D12DDI_OUTPUT_LINKAGE_ELEMENT_DESC_0121;
```

## D3D12DDI_PRERASTERIZATION_OUTPUT_LINKAGE_SIGNATURE_DESC_0121

```cpp
typedef struct D3D12DDI_PRERASTERIZATION_OUTPUT_LINKAGE_SIGNATURE_DESC_0121
{
    const D3D12DDI_PRERASTERIZATION_OUTPUT_LINKAGE_ELEMENT_DESC_0121* pOutputLinkageElementDescs;
    UINT NumElements;
} D3D12DDI_PRERASTERIZATION_OUTPUT_LINKAGE_SIGNATURE_DESC_0121;
```

## D3D12DDI_PRERASTERIZATION_OUTPUT_LINKAGE_ELEMENT_DESC_0121

```cpp
typedef struct D3D12DDI_PRERASTERIZATION_OUTPUT_LINKAGE_ELEMENT_DESC_0121
{
    UINT RegisterIndex;
    BYTE RegisterMask;
} D3D12DDI_PRERASTERIZATION_OUTPUT_LINKAGE_ELEMENT_DESC_0121;
```

## D3D12DDI_PRERASTERIZATION_SHADERS_PARTIAL_PROGRAM_FIELDS_0121

```cpp
typedef
struct D3D12DDI_PRERASTERIZATION_SHADERS_PARTIAL_PROGRAM_FIELDS_0121
{
    BOOL ExcludePS;
    BOOL LateLinkInputLayoutSubobject;
} D3D12DDI_PRERASTERIZATION_SHADERS_PARTIAL_PROGRAM_FIELDS_0121;
```

## D3D12DDI_PIXEL_SHADER_PARTIAL_PROGRAM_FIELDS_0121

```cpp
typedef
struct D3D12DDI_PIXEL_SHADER_PARTIAL_PROGRAM_FIELDS_0121
{
    D3D12DDI_LINE_RASTERIZATION_MODE LineRasterizationMode;
    UINT ForcedSampleCount;
    BOOL AlphaToCoverageEnable;
    BOOL DualSourceBlendEnable;
    BOOL LateLinkRasterizerSubobject;
    BOOL LateLinkBlendSubobject;
    BOOL LateLinkSampleMaskSubobject;
    BOOL LateLinkSampleDescSubobject;
    BOOL LateLinkDepthStencilFormatSubobject;
    BOOL LateLinkRenderTargetFormatSubobject;
    BOOL LateLinkDepthStencilSubobject;
} D3D12DDI_PIXEL_SHADER_PARTIAL_PROGRAM_FIELDS_0121;
```

# Reporting Partial Graphics Programs Support

## D3D12DDI_PARTIAL_GRAPHICS_PROGRAMS_TIER

```cpp
typedef enum D3D12DDI_PARTIAL_GRAPHICS_PROGRAMS_TIER
{
    D3D12DDI_PARTIAL_GRAPHICS_PROGRAMS_TIER_NOT_SUPPORTED = 0,
    D3D12DDI_PARTIAL_GRAPHICS_PROGRAMS_TIER_1_0 = 10,
} D3D12DDI_PARTIAL_GRAPHICS_PROGRAMS_TIER;
```

Level of partial graphics programs support. Currently all or nothing.
This is the `PartialGraphicsProgramTier` member of `D3D12DDI_OPTIONS_DATA_PARTIAL_GRAPHICS_PROGRAMS`.

# State Object Compilation Flags

For state objects, when shaders are introduced as part of collections there is an opportunity to ask the driver to compile the shaders in the collection as part of the collection state object creation then do a quick link for these compiled shaders in state objects that use them. In this case the driver is asked to prioritize getting a result quickly instead of recompiling to get better performance of the already compiled shader. The link-only compilation result is used to avoid stutter and then the app/driver requests a full specialized compile in the background, switching to it when it is ready. This state object flag is set at the state object global level, not specifying a flag leaves compilation choices up to the driver.

To support what is described above flags are added to the state object, these flags are described below.

## State Object Flag

```cpp
typedef enum D3D12_STATE_OBJECT_FLAGS
{
    ...
    D3D12_STATE_OBJECT_FLAG_FULL_SPECIALIZATION = 0x8,
    D3D12_STATE_OBJECT_FLAG_PREFER_MINIMAL_LINK = 0x80,
    D3D12_STATE_OBJECT_FLAG_PREFER_MINIMAL_LINK_BACKGROUND_SPECIALIZE = 0x100,

} D3D12_STATE_OBJECT_FLAGS;

cpp_quote("DEFINE_ENUM_FLAG_OPERATORS( D3D12_STATE_OBJECT_FLAGS );")

typedef struct D3D12_STATE_OBJECT_CONFIG
{
    D3D12_STATE_OBJECT_FLAGS Flags;
} D3D12_STATE_OBJECT_CONFIG;
```

Parameter                                                           | Definition
---------                                                           | ----------
D3D12_STATE_OBJECT_FLAG_FULL_SPECIALIZATION                         | Asks the driver compiler to provide a more optimal compilation. This is expected to take longer than when specifying prefer minimal link. This can be different from the default behavior or can match it, this is up to the driver, the intention is to allow the app to request the most optimized version if possible. This is ideal for offline compilation since the driver is expected to take longer to provide a result. This is also valid for online compilation.
D3D12_STATE_OBJECT_FLAG_PREFER_MINIMAL_LINK                         | Asks the driver compiler to reuse existing compilation if possible and avoid recompilation, an example can be importing shaders from collections and linking them into pipelines minimally. This should provide a quick result. Applies to executable and raytracing state objects.
D3D12_STATE_OBJECT_FLAG_PREFER_MINIMAL_LINK_BACKGROUND_SPECIALIZE   | Asks the driver compiler to generate a quick compilation for the state object by reusing existing compilation and in the background compile a fully specialized version then automatically swap to it when it is ready for the same state object handle. Applies to executable and raytracing state objects.

## How to measure if these flags work?

Flag                                                | How to measure if it works?
---------                                           | ----------
Prefer minimal link                                 | This flag should result in faster state object creation, and a higher cache hit rate. To validate that this works uses cache telemetry to compare the cache hit rate with vs without the flag when creating or adding to a state object.
Full specialization                                 | Improvement in performance such as better fps compared to link only version.
Prefer minimal link with background specialization  | This flag should provide faster state object creation first, with an indication that the cache is being used, then when a full specialized version is introduced, the performance should improve. If we need a signal from the driver to know when a full specialized version was added, we can add a call back function.

# History

| Date    | Notes |
| -------- | ------- |
| **04/11/2025** | Split out partial programs into its own spec. |
| **06/03/2025** | Add state object compilation flags. |
| **06/12/2025** | Rewrite and restructure partial programs section. Add a more detailed description of the problem that is being solved. Add more subobjects expected in each partial program. Added `D3D12_PIXEL_SHADER_PARTIAL_PROGRAM_FIELDS` subobject description and details on how it is used. Add 'D3D12_OUTPUT_LINKAGE_TYPE_VIEW_INSTANCING' in 'D3D12_OUTPUT_LINKAGE_TYPE'. Add which fields are required vs not in each partial program. |
| **07/15/2025** | Rewrite and restructure the partial programs section. Clarify when default values are assumed by the driver. Added `D3D12_PRERASTERIZATION_SHADERS_PARTIAL_PROGRAM_FIELDS` subobject description and details on how to use it. Added fields in `D3D12_PIXEL_SHADER_PARTIAL_PROGRAM_FIELDS` and `D3D12_PRERASTERIZATION_SHADERS_PARTIAL_PROGRAM_FIELDS` to specify app intention to late link specific subobjects and prevent the driver from assuming a default value. Add ProgramName to `D3D12_PARTIAL_GENERIC_PROGRAM_DESC` and `D3D12DDI_PARTIAL_GENERIC_PROGRAM_DESC_0XXX`.|
| **10/13/2025** | Fix naming from partial generic program to partial graphics program. Add missing DDI subobject types. Add representative MS requirement for PS partial programs that are going to be used with MS. Add D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE to be used in the D3D12_PARTIAL_GRAPHICS_PROGRAM_DESC. |
| **11/05/2025** | Added subobject `D3D12_PRERASTERIZATION_OUTPUT_LINKAGE_SIGNATURE_DESC` to differentiate the output linkage desc used in pixel shader partials from the output linkage used in prerasterization shader partials. Update `D3D12DDI_OUTPUT_LINKAGE_SIGNATURE_DESC` to pass to the driver the same parameters as the API struct for consistency between usage in the case of MS and non-MS prerasterization shader partials. Add partial graphics programs tier API and DDI structs to enable the driver to report the level of support and the app to use CheckFeatureSupport to query the tier. |
| **03/02/2026** | Added missing subobject in PS partial table, and a late link flag for it. Updated pre-rasterization partial table to include that output linkage is required for MS pre-rasterization partial programs.|
| **03/03/2026** | Added missing bool in `D3D12DDI_PIXEL_SHADER_PARTIAL_PROGRAM_FIELDS_0121`. |
