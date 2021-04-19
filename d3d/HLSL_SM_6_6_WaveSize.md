# HLSL Wave Size

v1.00 2021-04-20

Shader Model 6.6 introduces a new option
that allows the shader author to specify
a wave size that the shader is compatible with.

Wave aware HLSL code is becoming increasingly common,
along with operations that operate at the level of the wave,
instead of independently per thread.
While HLSL is designed to abstract away
the wave size being used on the hardware,
there are currently some scenarios that require the shader author
to write shader code dependent on a particular wave size.
WaveMMA (wave_matrix) operations are one example.
Other static dependencies on wave size may also be required
for optimized shaders, such as threadgroup size
and groupshared or local array sizes.

Without this feature,
if the driver reports a range of supported wave sizes,
the application still cannot guarantee
that a shader will be run at the desired wave size.
Without this guarantee,
shaders may simply fail to produce the expected results at runtime.

With this option,
D3D12 runtime validation will fail if
shaders in a pipeline state object have a required wave size
that is not in the range reported by the driver.
This also enables additional compile-time validation
for cases such as wave_matrix,
where the thread group size must be a multiple of the wave size.

## Contents

- [Allowed Wave Sizes](#allowed-wave-sizes)
- [HLSL Attribute](#hlsl-attribute)
- [Compiler Warning](#compiler-warning)
- [DXIL Metadata](#dxil-metadata)
- [Runtime Validation](#runtime-validation)
- [Device Behavior](#device-behavior)
- [Device Capability](#device-capability)
- [Issues](#Issues)
- [Change Log](#change-log)

## Allowed Wave Sizes

The allowed wave sizes that an HLSL shader may specify are
the powers of 2 between 4 and 128, inclusive.
In other words, the set: `[4, 8, 16, 32, 64, 128]`.

## HLSL Attribute

A new attribute may be specified on
compute shader entry points,
to indicate that the function is only compatible with
a specific wave size.

```HLSL
[WaveSize(<numLanes>)]
void main() ...
```

`<numLanes>` must be an immediate integer value of
an [allowed wave size](#allowed-wave-sizes).

Shader types this attribute may be used with are:
compute, amplification, mesh,
vertex, hull, domain, geometry, and pixel.

Shader entries of the supported types using this attribute
will keep track of this attribute when compiled into a library
for use when linking to a final shader target.

## Compiler Warning

Since HLSL is normally designed to be wave-size agnostic,
use of this feature will result in a compiler warning.
This warning can be turned off with a compiler option or a pragma.
Warning details and option name TBD.  See [Issue #6](#issues).

## DXIL Metadata

The wave size will be captured in DXIL metadata,
as a new extended property from the entry point metadata list,
so that the driver can select an appropriate wave size for the shader.

In DxilMetadataHelper.h, assuming kDxilWaveSizeTag is assigned the next available value of 11:

```C++
class DxilMDHelper {
  ...
  static const unsigned kDxilWaveSizeTag = 11;
```

```DXIL
; DXIL Example
!dx.entryPoints = !{!1}
!1 = !{..., !2}
!2 = !{i32 11, !3}      ; kDxilWaveSizeTag = 11
!3 = !{i32 <numLanes>}
```

`<numLanes>` must be an immediate integer value of
an [allowed wave size](#allowed-wave-sizes).

## Runtime Validation

The D3D12 runtime will validate shaders with wave size specified
against the device reported range of wave sizes
to ensure the desired size is within the range of sizes
supported by the device.

## Device Behavior

The device must run the shader at the wave size
specified in the DXIL metadata, if any.

All power of 2 sizes in the range reported by the driver
must be supported for selection by the shader,
and wave ops must be supported at each size.
Wave sizes supported by a device under some conditions,
but not compatible with wave intrinsics and
shader selected wave sizes *for all shader types*,
should not be included in the range of wave size support
reported by the driver.

## Device Capability

A device that reports support for Shader Model 6.6,
and reports support for the WaveOps optional feature,
must support this feature.
See [Issue 2](#issues)

---

## Issues

1. Some dithering has occurred on whether this should be a shader attribute
    or a global setting set via a pragma or command line argument.
    - Current approach is to use an attribute,
    and support all shader types other than DXR shader types.

2. How about devices that don't report support for the optional WaveOps feature?
    - What are the requirements on the wave size min/max reported by the driver in this case?
    - Should the these devices not be required to support this feature?
    - Should use of the wave size by the shader set the WaveOps feature requirement for the shader,
        even if the shader does not use wave intrinsics?

3. Should some flexibility be allowed for wave size
    when shaders cannot be directly dependent on the wave size?
    Such as for DXR shaders, and vertex, hull, domain, geometry, and pixel shaders
    that do not use wave intrinsics.

4. Should support for DXR libraries be included?

5. Should support for a single global setting for a library be considered?
    This would be potentially useful for DXR,
    but also if libraries are accepted in regular graphics pipelines in the future,
    and a consistent wave size is necessary for driver compilation of library functions
    and fast/efficient runtime linking.

6. Need to message to developers that this is not a normal path that should be used,
    but one that may be used when it is really necessary.
    - Proposed: Add warning message when compiling shader with feature.
        Warning message can be disabled with pragma or option.

## Change Log

Version|Date|Description
-|-|-
1.00|20 Apr 2021|Minor Edits for Publication
0.1|2020-04-16|First Draft
0.2|2020-04-21|Switch to using attribute only, exclude DXR
0.3|2020-05-11|Add warning, update justification
