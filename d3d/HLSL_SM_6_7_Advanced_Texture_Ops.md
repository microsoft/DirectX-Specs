# HLSL Advanced Texture Operations

v1.0 2022-08-01

Shader Model 6.7 introduces
support for a collection of advanced texture operations

---

## Contents

- [Notation](#notation)
- [Integer Sampling](#integer-sampling)
- [Raw Gather](#raw-gather)
  - [Resource Integer Aliasing](#resource-integer-aliasing)
  - [Raw Gather Methods](#raw-gather-methods)
- [Programmable Offsets](#programmable-offsets)
- [SampleCmpLevel](#samplecmplevel)
- [Writable MSAA Textures](#writable-msaa-textures)
- [Device Capability](#device-capability)
- [Capability Queries](#capability-queries)
- [Issues](#issues)
- [Change Log](#change-log)

---

## Notation

In HLSL code below, these notation conventions are used for non-native HLSL code:

- `<TexObject>`: one of the following texture objects
  - Texture1D
  - Texture1DArray
  - Texture2D
  - Texture2DArray
  - Texture3D
- `<TexObject2D>`: one of the following texture objects
  - Texture2D
  - Texture2DArray
- `Format`: the format of the values in the texture object.
- `N`: used in `int<N>` or `float<N>` to represent
   the dimensionality of the texture object.
   Where array textures are concerned,
   N will be one greater than the base texture dimension.
- `[]` braces: optional parameters

## Integer Sampling

Values from unsigned integer formats can now
 be used by texture retrieval intrinsics
 with certain restrictions on filtering.
Integer samples may not use any `LINEAR` or `ANISOTROPIC` filtering modes.
These D3D12_FILTER options are allowed:

- `D3D12_FILTER_MIN_MAG_MIP_POINT`
- `D3D12_FILTER_MINIMUM_MIN_MAG_MIP_POINT`
- `D3D12_FILTER_MAXIMUM_MIN_MAG_MIP_POINT`

To fully enable integer sampling requires a way
to specify integer border colors that were
previously only float values.
This adds a new `D3D12_SAMPLER_DESC` variant
that can specify float or integer border values.

```c++
typedef struct D3D12_SAMPLER_DESC2 {
  D3D12_FILTER               Filter;
  D3D12_TEXTURE_ADDRESS_MODE AddressU;
  D3D12_TEXTURE_ADDRESS_MODE AddressV;
  D3D12_TEXTURE_ADDRESS_MODE AddressW;
  FLOAT                      MipLODBias;
  UINT                       MaxAnisotropy;
  D3D12_COMPARISON_FUNC      ComparisonFunc;
  union {
    FLOAT                    FloatBorderColor[4];
    UINT                     UintBorderColor[4];
  }
  FLOAT                      MinLOD;
  FLOAT                      MaxLOD;
  D3D12_SAMPLER_FLAGS        Flags;
} D3D12_SAMPLER_DESC2;
```

Where `Flags` is the enum:

```c++
enum D3D12_SAMPLER_FLAGS {
  D3D12_SAMPLER_FLAG_NONE = 0
  D3D12_SAMPLER_FLAG_UINT_BORDER_COLOR = 0x1
}
```

Setting the `D3D12_SAMPLER_FLAG_UINT_BORDER_COLOR` bit
 in the `Flags` field indicates that the sampler should be
 treated as having integer border color values
 and the `UintBorderColor` field should
 contain valid integer values representing those border colors.
Otherwise, the sampler has float border color values
and the `FloatBorderColor` field should be used.

Additional changes are made to the `D3D12_STATIC_BORDER_COLOR`
 enum used by the `D3D12_STATIC_SAMPLER_DESC` struct
 to include integer border color variants:

```c++
typedef enum D3D12_STATIC_BORDER_COLOR {
  D3D12_STATIC_BORDER_COLOR_TRANSPARENT_BLACK,
  D3D12_STATIC_BORDER_COLOR_OPAQUE_BLACK,
  D3D12_STATIC_BORDER_COLOR_OPAQUE_WHITE,
  D3D12_STATIC_BORDER_COLOR_OPAQUE_BLACK_UINT,
  D3D12_STATIC_BORDER_COLOR_OPAQUE_WHITE_UINT
};
```

Static samplers used with unsigned integer formats must use
 either `D3D12_STATIC_BORDER_COLOR_OPAQUE_BLACK_UINT` for black borders
 or `D3D12_STATIC_BORDER_COLOR_OPAQUE_WHITE_UINT` for white borders.

Support for non-normalized coordinate samplers added
`D3D12_STATIC_SAMPLER_DESC1` with a `D3D12_SAMPLER_FLAGS` member. In 
the context of static samplers, `D3D12_SAMPLER_FLAG_UINT_BORDER_COLOR` 
is shadowed by the static border color, and not applicable. However, root 
signature creation will fail if this flag is used with a floating-point 
border color; with a uint border color it is redundant, but not an error.

## Raw Gather

To enable access to four appropriately-sized elements
 that would be used for bilinear interpolation when sampling
 in the form of the indicated appropriately-sized unsigned integer values
 requires resource aliasing and new HLSL gather methods.

### Resource Integer Aliasing

To enable retrieval of elements into raw integers,
single-channel unsigned integer resource views can now be created
by `ID3D12Device::CreateShaderResourceView`
for resources with identical element bit widths
that have been appropriately flagged at creation.
For example,
a resource view of type `DXGI_FORMAT_R32_UINT`
can be created for a resource of type `DXGI_FORMAT_R8G8B8A8_UINT`
and a resource view of type `DXGI_FORMAT_R16_UINT`
can be created for a resource of type `DXGI_FORMAT_R8G8_UINT`.
Additionally, same-size and same-channel aliasing can be performed
 as with a resource view of type DXGI_FORMAT_R16_UINT
 created for a resource of type of DXGI_FORMAT_R16_FLOAT.

In order to be able to create an single-channel integer resource view,
a resource must be created using the
[CreateCommittedResource3](D3D12EnhancedBarriers.md#id3d12device10-createcommittedresource3),
[CreatePlacedResource2](D3D12EnhancedBarriers.md#id3d12device10-createplacedresource2),
or [CreateReservedResource2](D3D12EnhancedBarriers.md#id3d12device10-createreservedresource2)
using the new API fields, `NumCastableFormats` and `pCastableFormats`
to specify the list of acceptable casts.

### Raw Gather Methods

To access single-channel integer values from
 formats representing multichannel texture elements,
 a new gather method is introduced:

```c++
uint<bits>_t4 <TexObject2D>.GatherRaw(SamplerState S, float<N> Location, [int2 Offset], [out uint Status]);
```

These are distinct from existing `Gather` methods
 because rather than retrieving a single channel
 of however many the format element contains,
 they retrieve a single value that represents
 a raw, bitwise copy of all of the element's channels
 without any conversion of texture contents.
The <bits> variable represents the number of bits corresponding to the
type of <TexObject2D>.
Note that `<TexObject>` does not include cube textures.
 Given that cube texture sampling does not always involve four elements,
 they are not usable with raw gather.

The unsigned integer formats (`DXGI_FORMAT_`* values)
 usable by GatherRaw:

- `DXGI_FORMAT_R16_UINT`
- `DXGI_FORMAT_R32_UINT`
- `DXGI_FORMAT_R32G32_UINT`

No other formats may be used with `GatherRaw`.
To perform a raw gather on another format,
 resource aliasing to an integer format must be used
 as described above.

The `uint16_t GatherRaw` overload is only available on platforms with native 16-bit shader op support.

The `uint64_t GatherRaw` overload is only available on platforms with 64-bit shader op support.

## Programmable Offsets

These HLSL texture access methods have an optional Offset parameter
representing integer offsets to the loaded or sampled location.
Earlier shader models required that this offset be an immediate value.

```c++
Format <TexObject>::Load( int<N> Location, int<N> Offset, [out uint Status] );
Format <TexObject>::Sample( SamplerState S, float<N> Location, int<N> Offset,
                          [float Clamp], [out uint Status] );
Format <TexObject>::SampleBias( SamplerState S, float<N> Location, float Bias,
                              int<N> Offset, [float Clamp], [out uint Status] );
Format <TexObject>::SampleCmp( SamplerComparisonState S, float<N> Location,
                             float CompareValue, int<N> Offset,
                             [float Clamp], [out uint Status] );
Format <TexObject>::SampleCmpLevelZero( SamplerComparisonState S, float<N> Location,
                                      float CompareValue, int<N> Offset, [out uint Status] );
Format <TexObject>::SampleGrad( SamplerState S, float<N> Location, float DDX, float DDY,
                              int<N> Offset, [float Clamp], [out uint<N> Status]);
Format <TexObject>::SampleLevel( SamplerState S, float<N> Location, float LOD, int<N> Offset,
                               [out uint Status]);
```

In Shader Model 6.7, the `Offset` parameters can be variables
 where the 4 least significant bits are honored as a signed value,
 yielding a [-8..7] range

Note: no DXIL changes are needed as the operations already take i32 values for offsets.

## SampleCmpLevel

Shader Model 6.7 introduces a new SampleCmp texture method
 to perform the existing Sample/Compare operation
 with an explicitly specified MIP level of detail(LOD)
 where a default or implicit level was previously used.
This intrinsic is available in all shader stages.

```c++
Format <TexObject>::SampleCmpLevel( SamplerComparisonState S, float<N> Location,
                                  float CompareValue, float LOD, [int<N> Offset],
                                  [out uint Status]);
Format TextureCube::SampleCmpLevel( SamplerComparisonState S, float<N> Location,
                                  float CompareValue, float LOD,
                                  [out uint Status]);
Format TextureCubeArray::SampleCmpLevel( SamplerComparisonState S, float<N> Location,
                                  float CompareValue, float LOD,
                                  [out uint Status]);
```

Note that `<TexObject>::SampleCmpLevel` has programmable offsets as described above.

## Writable MSAA Textures

Shader Model 6.7 introduces writable multi-sampled texture resources:

- `RWTexture2DMS<Type, Samples>`.
- `RWTexture2DMSArray<Type, Samples>`.

The `Type` and `Samples` template variables represent
 the HLSL type of the resource and the number of samples.
Unlike existing texture resource types, they are required.

These texture resources share the existing methods of the
 `Texture2DMS` and `Texture2DMSArray` resource types with two exceptions:
 the `Operator[]` and `sample.Operator[][]` methods return writable resource variables.
The first references the location in sample index 0.
The second references the location in the provided sample index.

```c++
R RWTexture2DMS::Operator[](uint2 pos);
R RWTexture2DMS::sample.Operator[][](uint sampleIndex, uint2 pos);
R RWTexture2DMSArray::Operator[](uint3 pos);
R RWTexture2DMSArray::sample.Operator[][](uint sampleIndex, uint3 pos);
```

Support for writable MSAA textures is determined by
the `WritableMSAATexturesSupported` field of `D3D12_FEATURE_DATA_D3D12_OPTIONS14`.

## Device Capability

Devices that support `D3D_SHADER_MODEL_6_7`
 may optionally support these new intrinsics and types
 as indicated by a capability bit
 for writable MSAA textures
 and another indicating support for the other
 advanced texture operations documented here.
<!-- see issue 2-->

16-bit `GatherRaw` overload is available on devices that support `D3D_SHADER_MODEL_6_7`
and support 16-bit integer shader operations as indicated by
the `Native16BitShaderOpsSupported` member
of `D3D12_FEATURE_D3D12_OPTIONS4`.

64-bit `GatherRaw` overload is available on devices that support `D3D_SHADER_MODEL_6_7`
and support 64-bit integer shader operations as indicated by
the `Int64ShaderOps` member
of `D3D12_FEATURE_D3D12_OPTIONS1`.

## Capability Queries

Applications can query the availability
 of these features by
 passing `D3D12_FEATURE_D3D12_OPTIONS14`
 as the `Feature` parameter
 and retrieving the `pFeatureSupportData` parameter
 as a struct of type `D3D12_FEATURE_DATA_D3D12_OPTIONS14`.
The relevant parts of these structs are defined below.

```C++
typedef enum D3D12_FEATURE {
    ...
    D3D12_FEATURE_D3D12_OPTIONS14
} D3D12_FEATURE;

typedef struct D3D12_FEATURE_DATA_D3D12_OPTIONS14 {
    ...
    BOOL AdvancedTextureOpsSupported;
    BOOL WritableMSAATexturesSupported;
} D3D12_FEATURE_DATA_D3D12_OPTIONS14;
```

`WritableMSAATexturesSupported` is a boolean that specifies
 whether writable MSAA textures
 and their methods, particularly `sample.Operator[][]`,
 are supported with a given hardware and runtime.

`AdvancedTextureOpsSupported` is a boolean that specifies
 whether the features described here are supported
 with a given hardware and runtime.

Note that `D3D12_FEATURE_DATA_D3D12_OPTIONS12::RelaxedFormatCastingSupported`
would technically be used to indicate support for the functionality that
enables integer aliasing,
but it is being considered a prerequisite for enabling `AdvancedTextureOpsSupported`.

## Issues

1. What should Raw Gather be called?
   GatherRaw is a bit ambiguous, but acceptable with sufficient explanation.

2. Which DXGI formats should be castable to uint views?
   No Planar formats due to their complexity and limited usage.

3. How can we represent elements greater than 32 bits in a uint resource view?
   We will be reusing the approach where the resource is R32G32_UINT,
   but it is declared as uint64_t in the shader.
   This approach has worked before and adding a new format would be too disruptive.

4. What textures should be raw gatherable?
   2D textures and 2Darray textures. Gather isn't compatible with 3d textures.
   Cube textures are possible, but there are complications and they are less interesting.

## Change Log
Version|Date|Description
-|-|-
1.01|30 Sep 2022|Add note about D3D12_STATIC_SAMPLER_DESC1 having sampler flags and interaction with border colors
1.00|01 Aug 2022|Minor edits for publication
0.10|08 Mar 2022|Rename integer sampler identifiers
0.9|07 Mar 2022|Clarify pre-requisite for advanced texture ops, Update integer aliasing in keeping with other specs. Correct type, function, and struct details.
0.8|02 Nov 2021|Remove bitsize SampleRaw variants. Correct bitwidth of return and args
0.7|02 Nov 2021|Add MSAA cap bit as separate from other features
0.6|22 Oct 2021|Move DXIL components out. Document static integer samplers. Clarify restrictions
0.5|30 Sep 2021|remove clamp from samplecmplevel, clarify texture type support, drop writable mip, add global advanced texops cap bit
0.4|16 Sep 2021|remove comparison filter, add cap bits, clarify integer borders, separate integer sampling from raw gather, add GatherRaw* methods
0.3|14 Aug 2021|Clarify details about unsigned integer resource aliasing and a few other clarifications
0.02|11 Aug 2021|Convert Raw Gather to a resource aliasing capability. Fix typos
0.01|03 Aug 2021|Initial version
