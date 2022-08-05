# WaveOpsIncludeHelperLanes Option

v1.0 2022-08-01

Shader Model 6.7 introduces a new option that allows the shader author 
to specify whether helper lanes participate in wave intrinsics.

Helper lane is a lane in pixel shader quad that is not covered by a primitive 
(where at least one lane in the quad is covered by the primitive),  or a lane
 that has been demoted with `discard`. 
In other words, a pixel shader lane is considered a helper lane
if it is part of a scheduled quad, but masked from writes.

Helper lanes exist only in pixel shaders and are present only if the shader contains 
a quad or derivative operation (gradient/Sample) that requires all four lanes of a quad. 
After the last quad or derivative operation in the shader code the helper lanes are not
 guaranteed to exist. Consequently, there might actually be no helper lanes at all if 
 the shaders does not have any quad or derivative operations.

For shaders using the new `WaveOpsIncludeHelperLanes` option, the helper lanes will be
 guaranteed to exist until the last wave operation in the shader code, in addition to
  quad and derivate ops. The attribute will never activate any helper lanes.

The [`IsHelperLane`](../HLSL_ShaderModel6_6.md#is-helper-lane) intrinsics can be used to
 determine if a lane is a helper lane.

More information about wave intrinsics and helper lanes can be found [here](https://github.com/microsoft/DirectXShaderCompiler/wiki/Wave-Intrinsics).

## Contents

- [WaveOpsIncludeHelperLanes Attribute](#waveopsincludehelperlanes-attribute)
  - [Non-library shaders](#non-library-shaders)
  - [Library shaders](#library-shaders)
- [DXIL](#dxil)
- [Device Behavior](#device-behavior)
- [Change Log](#change-log)

##  WaveOpsIncludeHelperLanes Attribute

A new function attribute `WaveOpsIncludeHelperLanes` is introduced in HLSL for shader model 6.7 as a 
non-optional feature. The attribute  indicates that the shader code requires helper lanes to
participate in wave intrinsics. By default and when this attribute is not present only non-helper
lanes participate in wave operations.

### Non-library shaders

The attribute can be specified on the shader entry point function. It applies to the whole shader module.

```C++
[WaveOpsIncludeHelperLanes]
void func() ...
```

This attribute is valid only in pixel shaders. The compiler will issue a warning if it is present 
in any other type of shader.

### Library shaders

For shader model 6.7 the use of `WaveOpsIncludeHelperLanes` attribute in libraries is not supported.
See the shader model 6.8 experimental feature [Dynamic Shader Linking](HLSL_SM_6_8_DynamicShaderLinking.md#waveopsincludehelperlanes-attribute) 
specification for details on the `WaveOpsIncludeHelperLanes` attribute use in libraries.

## DXIL

For non-library shaders the attribute will be captured in the compiled shader object as a shader feature flag, 
set in the blob part DFCC_FeatureInfo (FourCC SFI0).

```
#define D3D_SHADER_FEATURE_WAVE_OPS_INCLUDE_HELPER_LANES  0x20000000
```

## Device Behavior

The device must include helper lanes in all wave operations in pixel shaders that have `WaveOpsIncludeHelperLanes` attribute specified.

## Change Log

Version|Date|Description
-|-|-
1.00|01 Aug 2022|Minor edits for publication
0.30|12 Jul 2021|First spec review feedback
0.20|08 Jul 2021|Renamed file and title, helper lane description, use shader flag instead of metadata
0.10|07 Jul 2021|Initial spec draft