- [Partial Graphics Programs](#partial-graphics-programs)
  - [Pre-rasterization shaders partial program](#pre-rasterization-shaders-partial-program)
  - [Pixel shader partial program](#pixel-shader-partial-program)
  - [Notes](#notes)
  - [Use in generic programs](#use-in-generic-programs)
  - [Importing partial programs from collections](#importing-partial-programs-from-collections)
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
- [State Object Database schema](#state-object-database-schema)
  - [Feature attribution](#feature-attribution)
  - [Table additions](#table-additions)
  - [Lazy materialization](#lazy-materialization)
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
- [Sample](#sample)
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

Partial programs are an addition to the [state object generic programs](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#generic-programs); they can be defined in collections or in executable state objects. When a partial program is added as a part of a collection it is expected to be compiled as part of the collection state object creation. The compiled partial program is not always optimal; it depends on what is included in the partial program. App developers can give hints to the driver on how to handle the linking and potential recompilation when combining a partial program with other state subobjects/partial program by using [State Object Compilation Flags](#state-object-compilation-flags).

Partial programs can be defined as:
- Pre-rasterization shader(s) partial program
- Pixel shader partial program
- A partial program combining pre-rasterization and pixel shaders, later used with other state subobjects to form a full program. In that case, the two tables below effectively become combined (i.e. you can specify any subobject in either table), except that the output linkage subobjects, pixel shader partial primitive topology and representative mesh shader become invalid, since the driver can deduce this information. Explicit linkage description is not needed because both shader stages are present and the driver can analyze the PS inputs and pre-rasterization outputs together. All other subobjects from both tables remain valid and follow the same required/optional rules as when specified in their respective partial programs. The use case for declaring a combined partial program like this is to allow some of the other fixed-function state to vary without worrying about it impacting shader compilation.

## Pre-rasterization shaders partial program

This partial program includes:

Subobject type                                              | Is it required?           | Notes
---------                                                   | ----------                | ----------
Primitive topology                                          | Yes, excluding MS         | If specified for a mesh shader then it must match the topology specified in the shader code.
Shader(s)                                                   | Yes                       | This is used to define the pre-rasterization shader(s): <li>VS</li><li>AS and MS</li><li>mesh node shader (currently in public preview)</li>These shaders can be present in the state object directly or indirectly using an existing collection.
View instancing                                             | Optional                  | If not present [default value](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-view_instancing) is used for this subobject. If not set here it can't be overridden later in the full program.
Output linkage signature                                    | Optional                  | The [D3D12_OUTPUT_LINKAGE_SIGNATURE_DESC](#d3d12_output_linkage_signature_desc) subobject describes the PS-consumed subset of the pre-rasterization stage outputs. It is populated from the PS input signature -- only the pre-rasterization outputs that the PS actually reads should be listed. This enables the driver to eliminate unused pre-rasterization outputs during shader compilation (dead-code elimination). The listed elements include both user-defined and system-value attributes. The non-system-value elements must match the corresponding elements in the pre-rasterization output signature.
Root signature                                              | Yes, indirectly specified | This can't be added explicitly in the partial program but needs to be defined in the shader or deduced for e.g. from an association to the pre-rasterization shaders.
Pre-rasterization shaders partial program fields            | Optional                  | The [D3D12_PRERASTERIZATION_SHADERS_PARTIAL_PROGRAM_FIELDS](#d3d12_prerasterization_shaders_partial_program_fields) subobject provides a way to indicate `ExcludePS` and `LateLinkInputLayoutSubobject`.
Input layout                                                | Optional                  | This can be specified in the pre-rasterization partial program or included in the full graphics program specification. To indicate that the input layout subobject is late linked when specifying the full program, `LateLinkInputLayoutSubobject` needs to be set to true in the pre-rasterization shaders partial program fields subobject. If the `LateLinkInputLayoutSubobject` is set to false and there is no input layout subobject specified then the driver assumes [default value](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-input_layout) and can't be overridden later in the full program.
Index buffer strip cut value                                | Optional                  | This can be specified in the pre-rasterization partial program or included in the full graphics program specification. If not present in either the driver assumes [default value](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-index_buffer_strip_cut_value)

## Pixel shader partial program

This partial program includes:

Subobject type                                              | Is it required?           | Notes
---------                                                   | ----------                | ----------
Shader                                                      | Yes                       | This is used to define the pixel shader. The shader can be present in the state object directly or indirectly using an existing collection.
PS partial program fields                                   | Optional                  | The [D3D12_PIXEL_SHADER_PARTIAL_PROGRAM_FIELDS](#d3d12_pixel_shader_partial_program_fields) subobject includes fields from the rasterizer and blend subobjects. These field values are baked into the PS partial program, they can't be overridden by specifying a blend/rasterizer subobject when using the PS partial program. If this subobject is not present, and a blend/rasterizer subobject is, then the values for the fields are taken from the larger object. If neither subobject is present, then the values are set to [default](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#defaults-for-subobjects-missing-from-a-generic-program). If both subobjects are present, the values must match - this may be the case if (e.g.) a non-default value is needed for LineRasterizationMode. The full rasterizer desc is not known, and the full blend desc is provided, then there is redundant data for the field(s) coming from the blend subobject.
Rasterizer desc                                             | Optional                  | The `LineRasterizationMode` and `ForcedSampleCount` fields in the rasterizer desc have an impact on the PS partial program compilation. These two fields, if they have non-default values, can be specified using a PS partial program fields subobject or the full subobject. If the subobject is not present, and a PS partial program fields subobject is, then the values for the fields are taken from there. The rasterizer desc subobject can be included in the PS partial program or it can be specified when the PS partial program is combined with other state. To indicate that the rasterizer desc subobject is late linked when specifying the full program, `LateLinkRasterizerSubobject` needs to be set to true in the PS partial program. If `LateLinkRasterizerSubobject` is set to false and there is no rasterizer subobject specified then the driver assumes [default value](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-rasterizer).
Blend                                                       | Optional                  | The `AlphaToCoverageEnable` field in blend desc has an impact on the PS partial program compilation. This field, if it has a non-default value, can be specified using a PS partial program fields subobject or the full subobject. If this subobject is not present, and the PS partial program fields subobject is, then the value is taken from there. The blend subobject can be included in the PS partial program or it can be specified when the PS partial program is combined with other state. To indicate that the blend subobject is late linked when specifying the full program, `LateLinkBlendSubobject` needs to be set to true in the PS partial program. If `LateLinkBlendSubobject` is set to false and there is no blend subobject specified then the driver assumes [default value](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-blend) and can't be overridden later in the full program.
Root signature                                              | Yes, indirectly specified | This can't be added explicitly in the partial program but needs to be defined in the shader or deduced for e.g. from an association to the pixel shader.
Primitive topology                                          | Optional                  | MS output topology, or else the IA primitive topology -- in that priority order. This is added using the `D3D12_PRIMITIVE_TOPOLOGY_TYPE`, with these valid types: point, line, and triangle. If this subobject is not present in the PS partial program, the topology defaults to triangle regardless of which pre-rasterization stages are used. If the PS partial program topology needs to have a non-default value then a primitive topology subobject needs to be included.
Pre-rasterization output linkage                            | Conditional               | The [D3D12_PRERASTERIZATION_OUTPUT_LINKAGE_SIGNATURE_DESC](#d3d12_prerasterization_output_linkage_signature_desc) subobject describes the PS-consumed subset of the pre-rasterization stage outputs. This is required for PS partial programs that are combined with a pre-rasterization partial program (excluding MS ones) using view instancing. The listed elements include both user-defined and system-value attributes. The non-system-value elements must exactly match the PS input signature, since this subobject is on the PS partial. When the PS partial program is paired with a pre-rasterization partial program, the non-system-value elements in this subobject and in the pre-rasterization partial program's output linkage signature must be an exact match.
Representative MS                                           | Conditional               | This is required for PS partial programs that are combined with a pre-rasterization partial program using MS. This is required to be an exact match of the mesh shader output declaration for the pre-rasterization partial program mesh shader. The values that are consumed by a PS must have the same DXC-produced register and component mappings as any other mesh shader that is used with this pixel shader partial program. This is not to be compiled as a MS and is only used for linking MS output with PS inputs.
Sample mask                                                 | Optional                  | This can be specified if the subobject needs a non-default value. If this subobject is not present because it is late linked when specifying the full program, the PS partial program fields subobject field `LateLinkSampleMaskSubobject` needs to be set to true in the PS partial program. If `LateLinkSampleMaskSubobject` is set to false and there is no sample mask subobject specified then the driver assumes [default value](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-sample_mask) and can't be overridden later in the full program.
Sample desc                                                 | Optional                  | This can be specified if the subobject needs a non-default value. If this subobject is not present because it is late linked when specifying the full program, the PS partial program fields subobject field `LateLinkSampleDescSubobject` needs to be set to true in the PS partial program. If `LateLinkSampleDescSubobject` is set to false and there is no sample desc subobject specified then the driver assumes [default value](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-sample_desc) and can't be overridden later in the full program.
Depth stencil format                                        | Optional                  | This can be specified if the subobject needs a non-default value. If this subobject is not present because it is late linked when specifying the full program, the PS partial program fields subobject field `LateLinkDepthStencilFormatSubobject` needs to be set to true in the PS partial program. If `LateLinkDepthStencilFormatSubobject` is set to false and there is no depth stencil format subobject specified then the driver assumes [default value](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-depth_stencil_format) and can't be overridden later in the full program.
Render target format                                        | Optional                  | This can be specified if the subobject needs a non-default value. If this subobject is not present because it is late linked when specifying the full program, the PS partial program fields subobject field `LateLinkRenderTargetFormatSubobject` needs to be set to true in the PS partial program. If `LateLinkRenderTargetFormatSubobject` is set to false and there is no render target format subobject specified then the driver assumes [default value](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-render_target_formats) and can't be overridden later in the full program.
Depth stencil                                               | Optional                  | This can be specified if the subobject needs a non-default value. If this subobject is not present because it is late linked when specifying the full program, the PS partial program fields subobject field `LateLinkDepthStencilSubobject` needs to be set to true in the PS partial program. If `LateLinkDepthStencilSubobject` is set to false and there is no depth stencil subobject specified then the driver assumes [default value](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-depth_stencil-or-depth_stencil1-or-depth_stencil2)

## Notes
- Stream output subobject is not valid for use in partial programs.
- Any subobject not mentioned in the above partial programs can be included as part of the combined program. The exception is root signatures which are specified directly in shaders or associated directly with them rather than listed in program definitions.

## Use in generic programs

A graphics generic programs can be defined using partial graphics programs. To reference a partial graphics program in a generic program specify the partial graphics program name as an export in the 
[generic program desc](https://microsoft.github.io/DirectX-Specs/d3d/WorkGraphs.html#d3d12_generic_program_desc). A partial graphics program is only allowed to be referenced by name, it can't be added as a subobject when specifying a generic program.

## Importing partial programs from collections

When importing a partial graphics program from a collection through an explicit `D3D12_EXISTING_COLLECTION_DESC::pExports` list (`NumExports > 0`), shaders used to create that partial program but omitted from the list are not implicitly imported as shader exports into the destination state object. The partial program remains usable without separately importing those shaders.

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
}
```

To use any of the subobjects below, directly list them in a partial graphics program description. See [D3D12_PARTIAL_GRAPHICS_PROGRAM_DESC](#d3d12_partial_graphics_program_desc).

Value                                                                       | Definition
-----                                                                       | ----
`D3D12_STATE_SUBOBJECT_TYPE_OUTPUT_LINKAGE_SIGNATURE`                       | Output linkage signature subobject that can be used by a [Pre-rasterization shaders partial program](#pre-rasterization-shaders-partial-program). See [D3D12_OUTPUT_LINKAGE_SIGNATURE_DESC](#d3d12_output_linkage_element_desc) for more details.
`D3D12_STATE_SUBOBJECT_TYPE_PRERASTERIZATION_OUTPUT_LINKAGE_SIGNATURE`      | Pre-rasterization linkage signature subobject that can be used by a [Pixel shader partial program](#pixel-shader-partial-program). See [D3D12_PRERASTERIZATION_OUTPUT_LINKAGE_SIGNATURE_DESC](#d3d12_prerasterization_output_linkage_signature_desc) for more details.
`D3D12_STATE_SUBOBJECT_TYPE_PRERASTERIZATION_SHADERS_PARTIAL_PROGRAM_FIELDS`| Pre-rasterization shaders partial program fields subobject that can be used by a [Pre-rasterization shaders partial program](#pre-rasterization-shaders-partial-program). See [D3D12_PRERASTERIZATION_SHADERS_PARTIAL_PROGRAM_FIELDS](#d3d12_prerasterization_shaders_partial_program_fields) for more details.
`D3D12_STATE_SUBOBJECT_TYPE_PIXEL_SHADER_PARTIAL_PROGRAM_FIELDS`            | Pixel shader partil programs fields subobject that can be used by a [Pixel shader partial program](#pixel-shader-partial-program). See [D3D12_PIXEL_SHADER_PARTIAL_PROGRAM_FIELDS](#d3d12_pixel_shader_partial_program_fields) for more details.

## D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE

```cpp
typedef enum D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE
{
    D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE_NONE,
    D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE_PRERASTERIZATION_SHADER,
    D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE_PIXEL_SHADER,
    D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE_GENERIC,
} D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE;
```
Value                                                           | Definition
------                                                          | ----------
`D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE_NONE`                      | Default value for the enum which indicates that it wasn't initialized. It is invalid to use.
`D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE_PRERASTERIZATION_SHADER`   | Pre-rasterization shaders partial graphics program type, where only pre-rasterization shaders are allowed and the rules defined in [Pre-rasterization shaders partial program](#pre-rasterization-shaders-partial-program) are validated on the [D3D12_PARTIAL_GRAPHICS_PROGRAM_DESC](#d3d12_partial_graphics_program_desc).
`D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE_PIXEL_SHADER`              | Pixel shader partial graphics program type, where only a pixel shader is allowed and the rules defined in [Pixel shader partial program](#pixel-shader-partial-program) are validated on the [D3D12_PARTIAL_GRAPHICS_PROGRAM_DESC](#d3d12_partial_graphics_program_desc).
`D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE_GENERIC`                   | A partial generic graphics program type where all the shaders are defined and some of the subobjects. This allows for late-linking of some subobject when creating the full generic program.

## D3D12_PARTIAL_GRAPHICS_PROGRAM_DESC

```cpp
typedef
struct D3D12_PARTIAL_GRAPHICS_PROGRAM_DESC
{
    LPCWSTR ProgramName;
    UINT NumExports;
    [annotation("_In_reads_(NumExports)")] LPCWSTR* pExports;

    UINT NumSubobjects;
    [annotation("_In_reads_opt_(NumSubobjects)")] const D3D12_STATE_SUBOBJECT* const* ppSubobjects;
    D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE ProgramType;
} D3D12_PARTIAL_GRAPHICS_PROGRAM_DESC;
```

Members                                                   | Description
------                                                    | ----------
`LPCWSTR ProgramName`                                     | Name of the partial graphics program in the state object. This can be referenced in [D3D12_GENERIC_PROGRAM_DESC](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#d3d12_generic_program_desc) in the 'pExports' list. This adds a limitation on partail graphics program names, they need to be unique in the joined set of partial graphics program names and shader export names added in the same state object.
`UINT NumExports`                                         | Size of the pExports array. If 0, that array is ignored and can be null.
`LPCWSTR* pExports`                                       | Array of shader entrypoints to use in the partial graphics program. Collectively they must make sense to be used together depending on the type of partial graphics program defined by the `ProgramType`. The allowed types of shaders in each partial graphics program type are explained in `D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE`.
`UINT NumSubobjects`                                      | Size of the ppSubobjects array. If 0, that array is ignored and can be null.
`const D3D12_STATE_SUBOBJECT* const* ppSubobjects`        | Array of pointers to subobjects to include in the partial graphics program. The allowed list of subobjects is 
`D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE ProgramType`         | See [D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE](#d3d12_partial_graphics_program_type)


## D3D12_OUTPUT_LINKAGE_SIGNATURE_DESC
```cpp
typedef
struct D3D12_OUTPUT_LINKAGE_SIGNATURE_DESC
{
    [annotation("_In_reads_(NumElements)")] const D3D12_OUTPUT_LINKAGE_ELEMENT_DESC *pOutputLinkageElementDescs;
    UINT NumElements;
} D3D12_OUTPUT_LINKAGE_SIGNATURE_DESC;
```

Members                                                                 | Description
------                                                                  | ----------
`const D3D12_OUTPUT_LINKAGE_ELEMENT_DESC *pOutputLinkageElementDescs`   | Description of output linkage elements
`UINT NumElements`                                                      | Number of elements

The d3dx12_state_object.h header includes a helper class `CD3DX12_OUTPUT_LINKAGE_SIGNATURE_SUBOBJECT` that provides a 'HRESULT PopulateFromReflection(ID3D12ShaderReflection* pReflection)' function to populate the struct. The app needs to provide the reflection information of the pixel shader partial as the input to this function. Refer to [ID3D12ShaderReflection documentation](https://learn.microsoft.com/en-us/windows/win32/api/d3d12shader/nn-d3d12shader-id3d12shaderreflection) for more details.

## D3D12_OUTPUT_LINKAGE_ELEMENT_DESC

```cpp
typedef
struct D3D12_OUTPUT_LINKAGE_ELEMENT_DESC
{
    LPCSTR SemanticName;
    UINT SemanticIndex;
    BYTE StartComponent;
    BYTE ComponentCount;
} D3D12_OUTPUT_LINKAGE_ELEMENT_DESC;
```

Members                     | Description
------                      | ----------
`LPCSTR SemanticName`       | The system or user semantic associated with this element. See [HLSL Semantics](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-semantics) for system semantic info.
`UINT SemanticIndex`        | The zero-based semantic index of the element.
`BYTE StartComponent`       | The component of the entry to begin writing out to.
`BYTE ComponentCount`       | The number of components of the entry to write out to.

## D3D12_PRERASTERIZATION_OUTPUT_LINKAGE_SIGNATURE_DESC

```cpp
typedef
struct D3D12_PRERASTERIZATION_OUTPUT_LINKAGE_SIGNATURE_DESC
{
    [annotation("_In_reads_(NumElements)")] const D3D12_PRERASTERIZATION_OUTPUT_LINKAGE_ELEMENT_DESC *pOutputLinkageElementDescs;
    UINT NumElements;
} D3D12_PRERASTERIZATION_OUTPUT_LINKAGE_SIGNATURE_DESC;
```

Members                                                                 | Description
------                                                                  | ----------
`const D3D12_PRERASTERIZATION_OUTPUT_LINKAGE_ELEMENT_DESC *pOutputLinkageElementDescs`   | Description of output linkage elements
`UINT NumElements`                                                      | Number of elements

The d3dx12_state_object.h header includes a helper class `CD3DX12_PRERASTERIZATION_OUTPUT_LINKAGE_SIGNATURE_SUBOBJECT` that provides a 'HRESULT PopulateFromReflection(ID3D12ShaderReflection* pReflection)' function to populate the struct. The app needs to provide the reflection information of the output shader of the pre-rasterization partial as the input to this function. Refer to [ID3D12ShaderReflection documentation](https://learn.microsoft.com/en-us/windows/win32/api/d3d12shader/nn-d3d12shader-id3d12shaderreflection) for more details.

## D3D12_PRERASTERIZATION_OUTPUT_LINKAGE_ELEMENT_DESC

```cpp
typedef
struct D3D12_PRERASTERIZATION_OUTPUT_LINKAGE_ELEMENT_DESC
{
    LPCSTR SemanticName;
    UINT SemanticIndex;
    BYTE StartComponent;
    BYTE ComponentCount;
} D3D12_PRERASTERIZATION_OUTPUT_LINKAGE_ELEMENT_DESC;
```

Members                     | Description
------                      | ----------
`LPCSTR SemanticName`       | The system or user semantic associated with this element. See [HLSL Semantics](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-semantics) for system semantic info.
`UINT SemanticIndex`        | The zero-based semantic index of the element.
`BYTE StartComponent`       | The component of the entry to begin writing out to.
`BYTE ComponentCount`       | The number of components of the entry to write out to.

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
`ExcludePS`                     | Specifies whether the pre-rasterization shaders partial program is linked with a pixel shader or not. A partial program with `ExcludePS` can only be used in a generic program that doesn't include a pixel shader.
`LateLinkInputLayoutSubobject`  | Specifies whether the pre-rasterization shaders partial program input layout subobject is late linked. When it is set to false that means that when the subobject is not available in the pixel shader partial program then, the driver uses default values.

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
`LateLinkRasterizerSubobject`           | Specifies whether the pixel shader partial program rasterizer subobject is late linked. When it is set to false that means that when the subobject is not available in the pixel shader partial program then, the driver uses [default values](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-rasterizer).
`LateLinkBlendSubobject`                | Specifies whether the pixel shader partial program blend subobject is late linked. When it is set to false that means that when the subobject is not available in the pixel shader partial program then, the driver uses [default values](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-blend).
`LateLinkSampleMaskSubobject`           | Specifies whether the pixel shader partial program sample mask subobject is late linked. When it is set to false that means that when the subobject is not available in the pixel shader partial program then, the driver uses [default values](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-sample_mask).
`LateLinkSampleDescSubobject`           | Specifies whether the pixel shader partial program sample desc subobject is late linked. When it is set to false that means that when the subobject is not available in the pixel shader partial program then, the driver uses [default values](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-sample_desc).
`LateLinkDepthStencilFormatSubobject`   | Specifies whether the pixel shader partial program depth stencil format subobject is late linked. When it is set to false that means that when the subobject is not available in the pixel shader partial program then, the driver uses [default values](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-depth_stencil_format).
`LateLinkRenderTargetFormatSubobject`   | Specifies whether the pixel shader partial program render target format subobject is late linked. When it is set to false that means that when the subobject is not available in the pixel shader partial program then, the driver uses [default values](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-render_target_formats).
`LateLinkDepthStencilSubobject`         | Specifies whether the pixel shader partial program depth stencil subobject is late linked. When it is set to false that means that when the subobject is not available in the pixel shader partial program then, the driver uses [default values](https://github.com/microsoft/DirectX-Specs/blob/master/d3d/WorkGraphs.md#missing-depth_stencil-or-depth_stencil1-or-depth_stencil2).

---

# State Object Database schema

The [State Object Database](StateObjectDatabase.md) (SODB) records partial graphics programs as an [optional feature](StateObjectDatabase.md#optional-features) named `PartialPrograms` at version 1 with `Skip` policy.  Consumers that do not understand this feature drop attributed state objects from enumeration.

## Feature attribution

The first time a producer records a partial graphics program in a database session, the producer inserts a row into the `features` table with `name = "PartialPrograms"`, `version = 1`, and `policy = 1` (where `1` encodes the `Skip` policy), and materializes the partial-program tables described below.  Each state object that uses partial programs gets a row in `state_object_features` linking the state object to the feature row.

Attribution is collected on a state object when:

- The state object contains a subobject of one of the partial-program types: `D3D12_STATE_SUBOBJECT_TYPE_PARTIAL_GRAPHICS_PROGRAM`, `D3D12_STATE_SUBOBJECT_TYPE_OUTPUT_LINKAGE_SIGNATURE`, `D3D12_STATE_SUBOBJECT_TYPE_PRERASTERIZATION_OUTPUT_LINKAGE_SIGNATURE`, `D3D12_STATE_SUBOBJECT_TYPE_PRERASTERIZATION_SHADERS_PARTIAL_PROGRAM_FIELDS`, or `D3D12_STATE_SUBOBJECT_TYPE_PIXEL_SHADER_PARTIAL_PROGRAM_FIELDS`.
- The state object contains a `D3D12_STATE_OBJECT_CONFIG` subobject carrying any of `D3D12_STATE_OBJECT_FLAG_FULL_SPECIALIZATION`, `D3D12_STATE_OBJECT_FLAG_PREFER_MINIMAL_LINK`, or `D3D12_STATE_OBJECT_FLAG_PREFER_MINIMAL_LINK_BACKGROUND_SPECIALIZE`.
- The state object inherits the feature transitively from its `AddToStateObject` parent or from an `EXISTING_COLLECTION` / `EXISTING_COLLECTION_BY_KEY` reference whose target is itself attributed to the feature.

## Table additions

A partial graphics program is stored as a paired row in `generic_programs` and a companion row in a new `partial_graphics_programs` table, both keyed by the same primary key.  The shared key is computed from the partial program's full identity (name, exports, common subobjects, `ProgramType`, and the partial-specific subobject keys), with the `ProgramType` field hashed in unconditionally so the resulting key cannot collide with any regular generic program's key.  Reading a partial graphics program is a JOIN of the two tables on `Key`.

```sql
CREATE TABLE partial_graphics_programs (
    Key                              BLOB    NOT NULL PRIMARY KEY,
    ProgramType                      INTEGER NOT NULL,
    PrerasterizationFields           BLOB,
    PixelShaderFields                BLOB,
    OutputLinkageSignature           BLOB,
    PrerasterizationOutputLinkageSig BLOB,
    FOREIGN KEY(PrerasterizationFields)           REFERENCES partial_program_prerasterization_fields(Key),
    FOREIGN KEY(PixelShaderFields)                REFERENCES partial_program_pixel_shader_fields(Key),
    FOREIGN KEY(OutputLinkageSignature)           REFERENCES output_linkage_signatures(Key),
    FOREIGN KEY(PrerasterizationOutputLinkageSig) REFERENCES prerasterization_output_linkage_signatures(Key));

CREATE TABLE partial_program_prerasterization_fields (
    Key                          BLOB    NOT NULL PRIMARY KEY,
    ExcludePS                    INTEGER NOT NULL,
    LateLinkInputLayoutSubobject INTEGER NOT NULL);

CREATE TABLE partial_program_pixel_shader_fields (
    Key                                 BLOB    NOT NULL PRIMARY KEY,
    LineRasterizationMode               INTEGER NOT NULL,
    ForcedSampleCount                   INTEGER NOT NULL,
    AlphaToCoverageEnable               INTEGER NOT NULL,
    DualSourceBlendEnable               INTEGER NOT NULL,
    LateLinkRasterizerSubobject         INTEGER NOT NULL,
    LateLinkBlendSubobject              INTEGER NOT NULL,
    LateLinkSampleMaskSubobject         INTEGER NOT NULL,
    LateLinkSampleDescSubobject         INTEGER NOT NULL,
    LateLinkDepthStencilFormatSubobject INTEGER NOT NULL,
    LateLinkRenderTargetFormatSubobject INTEGER NOT NULL,
    LateLinkDepthStencilSubobject       INTEGER NOT NULL);

CREATE TABLE output_linkage_signatures (Key BLOB NOT NULL PRIMARY KEY);
CREATE TABLE prerasterization_output_linkage_signatures (Key BLOB NOT NULL PRIMARY KEY);

CREATE TABLE output_linkage_elements (
    Key            BLOB    NOT NULL PRIMARY KEY,
    SemanticName   TEXT    NOT NULL,
    SemanticIndex  INTEGER NOT NULL,
    StartComponent INTEGER NOT NULL,
    ComponentCount INTEGER NOT NULL);

CREATE TABLE prerasterization_output_linkage_elements (
    Key            BLOB    NOT NULL PRIMARY KEY,
    SemanticName   TEXT    NOT NULL,
    SemanticIndex  INTEGER NOT NULL,
    StartComponent INTEGER NOT NULL,
    ComponentCount INTEGER NOT NULL);

CREATE TABLE so_to_partial_graphics_program_associations (
    StateObjectKey            BLOB NOT NULL,
    PartialGraphicsProgramKey BLOB NOT NULL,
    FOREIGN KEY(StateObjectKey)            REFERENCES state_objects(Key),
    FOREIGN KEY(PartialGraphicsProgramKey) REFERENCES partial_graphics_programs(Key),
    UNIQUE(StateObjectKey, PartialGraphicsProgramKey));

CREATE TABLE output_linkage_signature_to_element_associations (
    OutputLinkageSignatureKey BLOB NOT NULL,
    ElementKey                BLOB NOT NULL,
    FOREIGN KEY(OutputLinkageSignatureKey) REFERENCES output_linkage_signatures(Key),
    FOREIGN KEY(ElementKey)                REFERENCES output_linkage_elements(Key),
    UNIQUE(OutputLinkageSignatureKey, ElementKey));

CREATE TABLE prerasterization_output_linkage_signature_to_element_associations (
    PrerasterizationOutputLinkageSignatureKey BLOB NOT NULL,
    ElementKey                                BLOB NOT NULL,
    FOREIGN KEY(PrerasterizationOutputLinkageSignatureKey) REFERENCES prerasterization_output_linkage_signatures(Key),
    FOREIGN KEY(ElementKey)                                REFERENCES prerasterization_output_linkage_elements(Key),
    UNIQUE(PrerasterizationOutputLinkageSignatureKey, ElementKey));
```

`partial_graphics_programs.ProgramType` stores the `D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE`.  The four FK columns are populated only when the corresponding subobject is present on the partial program's `ppSubobjects`; otherwise they are NULL.

Common PSO state (input layout, blend desc, rasterizer desc, depth stencil desc, render target formats, view instancing, sample mask, sample desc, depth stencil format, primitive topology, IB strip cut value, flags, node mask) is reused as-is from the existing `generic_programs` schema and its sub-tables.  The export-string list for a partial program is recorded in `string_associations` keyed by the shared `Key`, the same mechanism used for generic-program exports.

## Lazy materialization

The partial-program tables are added to the database via `CREATE TABLE IF NOT EXISTS` the first time a partial program is recorded in a session.  A database written by a producer that does not have partial graphics programs compiled in will not contain these tables.  A consumer that does have partial graphics programs compiled in tolerates their absence by leaving the corresponding read statements uncompiled, so iteration of those tables yields zero rows.

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

For state objects, when partials are introduced as part of collections there is an opportunity to ask the driver to compile the partials in the collection as part of the collection state object creation then do a quick link for these compiled partials in the generic programs that use them. In the case of executable state objects partials may also need to be compiled in a non-specialized way if they are used in multiple generic programs including ones introduced as part of AddToStateObject. The link-only flags ask the driver to initially compile partials in a non-specialized way and prioritize getting a result quickly instead of recompiling to get better performance. The link-only compilation result is used to avoid stutter and then the app/driver can request a full specialized compile in the background, switching to it when it is ready. This state object flag is set at the state object global level, not specifying a flag leaves compilation choices up to the driver.

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

`D3D12_STATE_OBJECT_FLAG_FULL_SPECIALIZATION`, `D3D12_STATE_OBJECT_FLAG_PREFER_MINIMAL_LINK`, and `D3D12_STATE_OBJECT_FLAG_PREFER_MINIMAL_LINK_BACKGROUND_SPECIALIZE` are mutually exclusive -- only one should be set on a given state object. When no flag is set, compilation behavior is driver-defined. These flags apply at the state object level, not per partial program. If a collection is created with one flag and an executable state object that references it uses a different flag, the executable's flag governs the final linking behavior -- the collection's flag only affects how shaders were initially compiled within the collection.

## How to measure if these flags work?

Flag                                                | How to measure if it works?
---------                                           | ----------
Prefer minimal link                                 | This flag should result in faster state object creation, and a higher cache hit rate. To validate that this works uses cache telemetry to compare the cache hit rate with vs without the flag when creating or adding to a state object.
Full specialization                                 | Improvement in performance such as better fps compared to link only version.
Prefer minimal link with background specialization  | This flag should provide faster state object creation first, with an indication that the cache is being used, then when a full specialized version is introduced, the performance should improve. If we need a signal from the driver to know when a full specialized version is added, we can add a call back function.

# Sample

```cpp

// Enable state object experiment
UUID Features[1] = { D3D12StateObjectsExperiment };
VERIFY_SUCCEEDED(D3D12EnableExperimentalFeatures(_countof(Features), Features, nullptr, nullptr));

// Add code to create d3d12 device
...

// Check partial graphics program support after device creation
D3D12_FEATURE_DATA_PARTIAL_GRAPHICS_PROGRAMS partialGraphicsPrograms;
VERIFY_SUCCEEDED(m_device->CheckFeatureSupport(D3D12_FEATURE_PARTIAL_GRAPHICS_PROGRAMS, &partialGraphicsPrograms, sizeof(partialGraphicsPrograms)));

if (partialGraphicsPrograms.PartialGraphicsProgramsTier < D3D12_PARTIAL_GRAPHICS_PROGRAMS_TIER_1_0)
{
    OutputDebugStringA("Device doesn't support partial graphics programs");
    ThrowIfFailed(E_FAIL);
}

/* Here is what it would have looked like as a PSO:
D3D12_GRAPHICS_PIPELINE_STATE_DESC psoDesc = {};
psoDesc.InputLayout = { inputElementDescs, _countof(inputElementDescs) };
psoDesc.pRootSignature = m_rootSignature.Get();
psoDesc.VS = CD3DX12_SHADER_BYTECODE(vertexShader.Get());
psoDesc.PS = CD3DX12_SHADER_BYTECODE(pixelShader.Get());
psoDesc.RasterizerState = CD3DX12_RASTERIZER_DESC(D3D12_DEFAULT);
psoDesc.BlendState = CD3DX12_BLEND_DESC(D3D12_DEFAULT);
psoDesc.DepthStencilState.DepthEnable = FALSE;
psoDesc.DepthStencilState.StencilEnable = FALSE;
psoDesc.SampleMask = UINT_MAX;
psoDesc.PrimitiveTopologyType = D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE;
psoDesc.NumRenderTargets = 1;
psoDesc.RTVFormats[0] = DXGI_FORMAT_R8G8B8A8_UNORM;
psoDesc.SampleDesc.Count = 1;
ThrowIfFailed(m_device->CreateGraphicsPipelineState(&psoDesc, IID_PPV_ARGS(&m_pipelineState)));
*/

CD3DX12_STATE_OBJECT_DESC SODesc;
SODesc.SetStateObjectType(D3D12_STATE_OBJECT_TYPE_EXECUTABLE);

// Define the building blocks for the program - the individual subobjects / shaders
auto pIL = SODesc.CreateSubobject<CD3DX12_INPUT_LAYOUT_SUBOBJECT>();

for (UINT i = 0; i < _countof(inputElementDescs); i++)
{
    pIL->AddInputLayoutElementDesc(inputElementDescs[i]);
}
auto pRootSig = SODesc.CreateSubobject<CD3DX12_GLOBAL_ROOT_SIGNATURE_SUBOBJECT>();
pRootSig->SetRootSignature(m_rootSignature.Get());

auto pVS = SODesc.CreateSubobject<CD3DX12_DXIL_LIBRARY_SUBOBJECT>();
CD3DX12_SHADER_BYTECODE bcVS(vertexShader.Get());
pVS->SetDXILLibrary(&bcVS);
pVS->DefineExport(L"VSMain");        

auto pPS = SODesc.CreateSubobject<CD3DX12_DXIL_LIBRARY_SUBOBJECT>();
CD3DX12_SHADER_BYTECODE bcPS(pixelShader.Get());
pPS->SetDXILLibrary(&bcPS);
psLib->DefineExport(L"PSMain");

auto pPrimitiveTopology = SODesc.CreateSubobject<CD3DX12_PRIMITIVE_TOPOLOGY_SUBOBJECT>();
pPrimitiveTopology->SetPrimitiveTopologyType(D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE);

auto pRTFormats = SODesc.CreateSubobject<CD3DX12_RENDER_TARGET_FORMATS_SUBOBJECT>();
pRTFormats->SetNumRenderTargets(1);
pRTFormats->SetRenderTargetFormat(0, DXGI_FORMAT_R8G8B8A8_UNORM);

// Define partials
auto pPrerastPartial = SODesc.CreateSubobject<CD3DX12_PARTIAL_GRAPHICS_PROGRAM_SUBOBJECT>();
pPrerastPartial->SetProgramName(L"myPreRasterizationPartial");
pPrerastPartial->SetPartialGraphicsProgramType(D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE_PRERASTERIZATION_SHADER);
pPrerastPartial->AddExport(L"VSMain");
pPrerastPartial->AddSubobject(*pPrimitiveTopology);
pPrerastPartial->AddSubobject(*pIL);

auto pPSPartial = SODesc.CreateSubobject<CD3DX12_PARTIAL_GRAPHICS_PROGRAM_SUBOBJECT>();
pPSPartial->SetProgramName(L"myPixelShaderPartial");
pPSPartial->SetPartialGraphicsProgramType(D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE_PIXEL_SHADER);
pPSPartial->AddExport(L"PSMain");
pPSPartial->AddSubobject(*pRTFormats);

 auto pGenericProgram = SODesc.CreateSubobject<CD3DX12_GENERIC_PROGRAM_SUBOBJECT>();
 pGenericProgram->SetProgramName(L"myGenericProgram");
 pGenericProgram->AddExport(L"myPreRasterizationPartial");
 pGenericProgram->AddExport(L"myPixelShaderPartial");

 ThrowIfFailed(m_device->CreateStateObject(SODesc, IID_PPV_ARGS(&m_stateObject)));

```

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
| **04/21/2026** | Added sample code showing how to use partial graphics programs to create a generic program. Fix 'D3D12_PRERASTERIZATION_OUTPUT_LINKAGE_ELEMENT_DESC' struct by removing the IsPrimitive member, since it is not needed. For mesh shaders a representative shader is passed to the pixel shader making the presence of IsPrimitive not needed. |
| **05/05/2026** | Removed `IsPrimitive` from `D3D12_OUTPUT_LINKAGE_ELEMENT_DESC` and `D3D12DDI_OUTPUT_LINKAGE_ELEMENT_DESC_0121` since it is not needed. Changed output linkage signature from conditional/required-for-MS to optional for all prerast partials. Changed representative MS from conditional/required to optional. Rewrote output linkage signature descriptions (both prerast and PS sides) to clarify their purpose as describing the PS-consumed subset of prerast outputs for dead-code elimination; non-system-value elements must match the prerast output signature (prerast side) or the PS input signature (PS side), and both include system-value attributes. Added documentation for `CD3DX12_OUTPUT_LINKAGE_SIGNATURE_SUBOBJECT` and `CD3DX12_PRERASTERIZATION_OUTPUT_LINKAGE_SIGNATURE_SUBOBJECT` helper classes with `PopulateFromReflection` usage. Fixed primitive topology priority chain to include HS tessellator output (MS > GS > HS > IA) and clarified that the default is triangle regardless of prerast stages. Clarified the combined partial program type (`D3D12_PARTIAL_GRAPHICS_PROGRAM_TYPE_GENERIC`) -- output linkage is invalid because the driver deduces linkage from both shader stages, all other subobjects remain valid. Clarified that `D3D12_STATE_OBJECT_FLAG_FULL_SPECIALIZATION`, `D3D12_STATE_OBJECT_FLAG_PREFER_MINIMAL_LINK`, and `D3D12_STATE_OBJECT_FLAG_PREFER_MINIMAL_LINK_BACKGROUND_SPECIALIZE` are mutually exclusive and apply at the state object level. General wording cleanup for consistency. |
| **05/18/2026** | Changed representative MS from optional to conditional/required, based on comments. |
| **08/6/2026**  | Remove support for HS/DS/GS from pre-rasterization partials. Remove `D3D12_STATE_OBJECT_FLAG_FULL_SPECIALIZATION` state object flag since it will be introduced in a different way through compile flags. Add minor update to how the link-only state object flags can be used. |
| **10/14/2026** | Clarify that explicitly importing a partial program does not implicitly import its excluded shader exports. Restore `D3D12_STATE_OBJECT_FLAG_FULL_SPECIALIZATION`. |
