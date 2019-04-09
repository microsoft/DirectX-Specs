<h1>UAV Typed Load</h1>

Version: 1.5

Date: 8/18/14

---

<h1>Contents</h1>

- [Summary](#summary)
- [Document Terms](#document-terms)
- [Architecture Decisions](#architecture-decisions)
- [Detailed Design](#detailed-design)
  - [Check Feature Support](#check-feature-support)
    - [Cap](#cap)
  - [Per Format](#per-format)
  - [API Changes](#api-changes)
  - [Runtime Logic Changes](#runtime-logic-changes)
    - [Format Requirements Table](#format-requirements-table)
    - [Validation](#validation)
      - [D3D11](#d3d11)
      - [D3D12](#d3d12)
  - [HLSL](#hlsl)
- [DDI Design](#ddi-design)
  - [GetCaps](#getcaps)
  - [CheckFormatSupport](#checkformatsupport)
- [Test Plan](#test-plan)
  - [Functional / Unit Tests](#functional--unit-tests)
  - [Conformance Testing](#conformance-testing)
    - [IHV Bring-up Test](#ihv-bring-up-test)
    - [Additional HLK Tests](#additional-hlk-tests)
- [Questions](#questions)

---

# Summary

Expose hardware support for UAV Typed Load on additional formats.

Currently, there are many formats that support UAV Typed Store
operations on FL11+, but only 3 that support UAV Typed Load. We will
expose hardware support for performing loads on additional formats. This
will require a new pfnCheckFormatSupport support bit.

---

# Document Terms

Term|   Definition
------| -----------------------
UAV|    Unordered Access View

---

# Architecture Decisions

WDDM 2.0+, D3D FL11.0+ is required to support this feature.

Support for this new format feature will fit into the existing format
support structures, data, and logic.

---

# Detailed Design

---

## Check Feature Support

We need to support both an individual feature cap, as well as per-format
UAV Typed Load support (i.e. CheckFeatureSupport and
CheckFormatSupport). CheckFeatureSupport cap added mostly because
runtime CreateShader validation requires some sort of Shader Feature
cap, so why not expose this via the API. While per-format
CheckFormatSupport is definitely required.

### Cap

ID3D11DeviceCheckFeatureSupport API will be used to determine support.
This will be implemented much like the design of Buffer Map Default, so
the implementation of that and CheckFeatureSupport() for
D3D11_FEATURE_D3D11_OPTIONS1 can be referenced.

This feature support information should be grouped with the other
features being added to the runtimes (e.g. ASTC Profile) into something
like D3D11_FEATURE_D3D11_OPTIONS2.

Only FL11.1+ WDDM 2.0+ drivers will have the ability to return support,
and must return support via a new Shader Feature cap. Drivers that don't
meet the FL and WDDM requirement will default to no support.

The relevant new D3D11_FEATURE:

```C++
D3D11_FEATURE_D3D11_OPTIONS2 = ( D3D11_FEATURE_MARKER_SUPPORT + 1)
```

Associated Structure and Capability member:

```C++
typedef struct D3D11_FEATURE_DATA_D3D11_OPTIONS2 {
    // other caps...
    BOOL TypedUAVLoadAdditionalFormats;
} D3D11_FEATURE_DATA_D3D11_OPTIONS2;
```

This BOOL will only be set when the driver specifies support via the
D3D11DDI_SHADER_CAPS, much like shader double support is set
currently. To be more specific, TypedUAVLoadAdditionalFormats defaults
to FALSE, and is only set to TRUE when:

- UMD version \>= WDDM 2.0
- Feature Level \>= FL11.0
- UMD sets the appropriate cap in D3D11DDI_SHADER_CAPS

---

## Per Format

The ID3D11Device::CheckFeatureSupport API reports UAV Typed Load support
per format via the D3D11_FEATURE_FORMAT_SUPPORT2 query: UAV Typed
Load is supported if the D3D11_FORMAT_SUPPORT2_UAV_TYPED_LOAD bit
is set.

Currently, this bit is only set when
CD3D11FormatHelper::UAVTypedLoadSupport returns D3D11R_REQ. This method
returns D3D11R_REQ when the Device Feature Level is 11.0 or newer and
the format is one of the following: DXGI_FORMAT_R32_UINT,
DXGI_FORMAT_R32_SINT, DXGI_FORMAT_R32_FLOAT. We will add the
ability for UAVTypedLoadSupport to return D3D11R_OPT, and in that case,
query the driver for support.

First, UAVTypedLoadSupport will need to return D3D11R_OPT when:

- the driver is newer than WDDM 1.3
- Feature Level is 11.0+
- the driver set the appropriate shader support cap
- the format doesn't already return D3D11R_REQ
- the format supports UAV Typed Stores (i.e. symmetric support
    required)

Then in CDevice::CheckFormatSupportImpl2, we will add a check for
UAVTypedLoadSupport == D3D11R_OPT, exactly like the
UAVTypedStoreSupport optional check. If the load support is marked as
optional, then we will query the driver for support. This code will be
structured like the CheckFormatSupportImpl's optional code (i.e. check
for any optional, query DDI once, then check each individually).

After talking with stakeholders, we have decided to not report Typed UAV
Load support for Video formats. This is for two reasons: the precedent
that video formats like _AYUV did not report Typed UAV Load support
even when R32_UINT was supported, and that there is work by Scott
MacDonald to deprecate video formats in the DXGI_FORMAT enum and
express that idea in a new way.

Once caveat to the driver query logic specified are the video formats:
we will not query the driver directly for these. Support for these will
be determined by support for their associated 3D-pipeline types. We will
calculate support for the following formats in a separate utility
function that doesn't query the driver directly, but queries
CheckFormatSupportImpl2 to determine UAV Typed Load support for each
video format's associated 3D formats (note that all associated 3D
formats must be supported for this function to return support for a
video format):

- DXGI_FORMAT_AYUV requires:
  - R8G8B8A8_UNORM
  - R8G8B8A8_UINT
  - R32_UINT
- DXGI_FORMAT_Y410 requires:
  - R10G10B10A2_UNORM
  - R10G10B10A2_UINT
  - R32_UINT
- DXGI_FORMAT_Y416 requires:
  - R16G16B16A16_UNORM
  - R16G16B16A16_UINT
- DXGI_FORMAT_NV12 requires:
  - Lum:
    - R8_UNORM
    - R8_UINT
  - Chrom:
    - R8G8_UNORM
    - R8G8_UINT
- DXGI_FORMAT_P010 requires:
  - Lum:
    - R16_UNORM
    - R16_UINT
  - Chrom:
    - R16G16_UNORM
    - R16G16_UINT
    - R32_UINT
- DXGI_FORMAT_P016 requires:
  - Lum:
    - R16_UNORM
    - R16_UINT
  - Chrom:
    - R16G16_UNORM
    - R16G16_UINT
    - R32_UINT
- DXGI_FORMAT_YUY2 requires:
  - R8G8B8A8_UNORM
  - R8G8B8A8_UINT
  - R32_UINT
- DXGI_FORMAT_Y210 requires:
  - R16G16B16A16_UNORM
  - R16G16B16A16_UINT
- DXGI_FORMAT_Y216 requires:
  - R16G16B16A16_UNORM
  - R16G16B16A16_UINT
- DXGI_FORMAT_NV11 requires:
  - Lum:
    - R8_UNORM
    - R8_UINT
  - Chrom:
    - R8G8_UNORM
    - R8G8_UINT

---

## API Changes

None.

---

## Runtime Logic Changes

---

### Format Requirements Table

This feature doesn't require a new Format Requirements Table since old
drivers will never be able to report UAV Typed Load support via
pfnCheckFormatSupport. However, because other new rendering features
(e.g. ASTC) require a new table, we will add one as well as a new
eExtendedFormatFeatures enum, which will be used by this feature to
restrict calling pfnCheckFormatSupport for UAV Typed Loads on older
drivers.

---

### Validation

---

#### D3D11

Draw/Dispatch-time validation in CContext::ValidateDraw/ValidateDispatch
handles this seamlessly using SUAVDeclEntry in
CContext::ValidateShaderBindings.

Create*Shader() validation will mimic
SHADER_FEATURE_DOUBLES/m_bDoublePrecisionFloatShaderOpsSupported
validation. A new Shader Feature flag must be added to the
SShaderFeatureInfo FeatureFlags in order for runtime to properly
validate. If that new Shader Feature flag is set, then the driver must
have set support for
D3D11DDICAPS_SHADER_TYPED_UAV_LOAD_ADDITIONAL_FORMATS.

---

#### D3D12

Draw/Dispatch-time validation in
CCommandList12::ValidateDraw/ValidateDispatch will need to support UAV
Typed Load validation in CCommandList12::ValidateShaderBindings the same
way that D3D11 does. Currently, this logic does not exist in D3D12.
TODO: determine who is adding all the same validation to D3D12.

Create*Shader() validation will be very similar D3D11's.

---

## HLSL

Support for this feature must be in D3D11 and D3D12.

Compiler issues the following warning:

error X3676: typed UAV loads are only allowed for single-component
32-bit element types

This will need to be modified to support the full range of Typed UAV
Load format components.

We must disable the validation in the HLSL compiler, and at Shader
Create time the runtime will validate the driver supports Typed UAV Load
on non-"single-component 32-bit element types." This requires a new
Shader Feature flag in SShaderFeatureInfo FeatureFlags, this is
typically performed as part of the HLSL compiler work, see
SHADER_FEATURE_TILED_RESOURCES as an example.

---

# DDI Design

Typed UAV Load will be supported by D3D11 and D3D12, therefore D3D11 DDI
may use types prefixed with D3D12 to reduce duplication.

D3D Feature Level 11.1+ hardware and WDDM 2.0+ UMD is required.

---

## GetCaps

A new cap for this feature will be added to the existing shader caps
query for the GetCaps DDI:

`D3D12DDICAPS_SHADER_TYPED_UAV_LOAD_ADDITIONAL_FORMATS`

Setting this flag means that the driver/hardware supports additional
formats (as specified in CheckFormatSupport) for Typed UAV Loads.

---

## CheckFormatSupport

A new CheckFormatSupport bit will be added to support this feature:

D3D12DDI_FORMAT_SUPPORT_UAV_READS

This should be returned by the driver when it supports UAV Typed Loads
on the format specified.

The following formats are the only formats allowed to report support
(the ones that are marked as required or optional for Typed UAV in the
Excel format requirements tables), all others should never set the
_UAV_READS bit:

```C++
DXGI_FORMAT_R32G32B32A32_FLOAT
DXGI_FORMAT_R32G32B32A32_UINT
DXGI_FORMAT_R32G32B32A32_SINT
DXGI_FORMAT_R16G16B16A16_FLOAT
DXGI_FORMAT_R16G16B16A16_UNORM
DXGI_FORMAT_R16G16B16A16_UINT
DXGI_FORMAT_R16G16B16A16_SNORM
DXGI_FORMAT_R16G16B16A16_SINT
DXGI_FORMAT_R32G32_FLOAT
DXGI_FORMAT_R32G32_UINT
DXGI_FORMAT_R32G32_SINT
DXGI_FORMAT_R10G10B10A2_UNORM
DXGI_FORMAT_R10G10B10A2_UINT
DXGI_FORMAT_R11G11B10_FLOAT
DXGI_FORMAT_R8G8B8A8_UNORM
DXGI_FORMAT_R8G8B8A8_UINT
DXGI_FORMAT_R8G8B8A8_SNORM
DXGI_FORMAT_R8G8B8A8_SINT
DXGI_FORMAT_R16G16_FLOAT
DXGI_FORMAT_R16G16_UNORM
DXGI_FORMAT_R16G16_UINT
DXGI_FORMAT_R16G16_SNORM
DXGI_FORMAT_R16G16_SINT
DXGI_FORMAT_R32_FLOAT (already required)
DXGI_FORMAT_R32_UINT (already required)
DXGI_FORMAT_R32_SINT (already required)
DXGI_FORMAT_R8G8_UNORM
DXGI_FORMAT_R8G8_UINT
DXGI_FORMAT_R8G8_SNORM
DXGI_FORMAT_R8G8_SINT
DXGI_FORMAT_R16_FLOAT
DXGI_FORMAT_R16_UNORM
DXGI_FORMAT_R16_UINT
DXGI_FORMAT_R16_SNORM
DXGI_FORMAT_R16_SINT
DXGI_FORMAT_R8_UNORM
DXGI_FORMAT_R8_UINT
DXGI_FORMAT_R8_SNORM
DXGI_FORMAT_R8_SINT
DXGI_FORMAT_A8_UNORM
DXGI_FORMAT_B5G6R5_UNORM
DXGI_FORMAT_B5G5R5A1_UNORM
DXGI_FORMAT_B4G4R4A4_UNORM
```

Note that (as specified above) there is an all-or-nothing subset of
formats where if one reports Typed UAV load support, then all must
report support. Typed UAV load support for the all-or-nothing subset is
required before any other new Typed UAV load formats can report support.

Also note that formats that report _UAV_READS support must also report _UAV_WRITES support.

---

# Test Plan

Functional unit tests will be designed to verify all runtime validation
and expected DDI calling behavior. These will need to fully cover the
feature surface area because there will be no D3DTest-provided
functional testing. D3D11 API should be used and run on D3D11on12 to
test D3D12 functionality, but D3D12 tests for failures will need to be
written as well. These tests will be integrated into CIS automatically
based on their directory location.

The D3D Proxy Driver will be used as the underlying driver for unit
testing. It will only mock support this feature since the driver
conformance testing will cover the actual shader execution behavior. We
only need to verify caps reporting and create (vs/gs/ps/etc.) shader
validation.

Ref will not be updated to support this feature.

New HCK test will be implemented to validate driver and hardware
conformance.

---

## Functional / Unit Tests

The functional unit tests will be written in TAEF. Because negatives
must be tested, we need D3D11 and D3D12 API tests. We must also ensure
D3D11on12 works for positives. D3DDriver will be used for D3D11 DDI call
verification, DDIFilter and WARP will be used for D3D12 and D3D11on12.

Functional unit tests will cover CheckFeatureSupport (incl. format
support), CreateShader, and Draw/Dispatch-time validation:

- CheckFeatureSupport testing will:

  - Check positives (and ensure symmetric support) by querying
        feature cap and all new UAV Typed Load formats to verify
        expected UAV Typed Load support (and UAV Typed Store), as well
        as expected pfnGetCaps and pfnCheckFormatSupport DDI calls.

  - Check negatives caused by lack of feature level and/or WDDM
        version requirements and verify pfnCheckFormatSupport DDI is not
        called.

  - Check negatives caused by lack of driver support and verify
        pfnCheckFormatSupport DDI is not called.

  - Check negatives caused by lack of symmetric support. This can
        only be accomplished by returning UAV Typed Load support but not
        UAV Typed Store support from the pfnCheckFormatSupport DDI for
        UAV Typed Store optional formats: DXGI_FORMAT_B5G6R5_UNORM,
        DXGI_FORMAT_B5G5R5A1_UNORM and DXGI_FORMAT_B4G4R4A4_UNORM.

- CreateShader testing will attempt to create each shader type and:

  - Check positives on a driver that supports the feature.

  - Check negatives caused by lack of feature level and/or WDDM
        version requirements and verify getsize and create DDIs are not
        called.

  - Check negatives caused by lack of driver support and verify
        getsize and create DDIs are not called.

- Draw/Dispatch-time testing will cycle all DXGI_FORMAT values and
    verify expected success and expected failure (debug layer error). A
    "IA + VS + No PS + Writes to Depth/Stencil Enabled" minimal pipeline
    configuration will be used (as specified in section 4.1.3 of the D3D
    Functional Spec), where the VS calls ld_uav_typed on a UAV that
    will have a rotating format.

---

## Conformance Testing

---

### IHV Bring-up Test

The TAEF unit test to unblock IHV development will cycle through all DXGI_FORMAT values in the all-or-nothing subset. For a given format, it will bind a source UAV to slot 0 and a destination UAV in slot 1, and copy between them in a shader. A "IA + VS + No PS + Writes to Depth/Stencil Enabled" minimal pipeline configuration will be used (as specified in section 4.1.3 of the D3D Functional Spec), where the VS uses ld_uav_typed to read the data from the source UAV. It must run via D3D11 and D3D11on12 to cover both D3D11 and D3D12.

---

### Additional HLK Tests

Test cases for the following behavior will be implemented:

- New TAEF Test: If any format in the all-or-nothing subset is
    supported, then all formats in the all-or-nothing subset are
    supported.

- New TAEF Test: All-or-nothing subset is supported before any other
    new format supports UAV Typed Load.

- Existing WGF Test: WGF11Compute's CUAVTypedTest and
    CUAVTypedPixelShaderTest will be modified to add support for all new
    UAV Typed Load formats.

All HCK Tests will cover D3D12 via D3D11on12.

---

# Questions

- Why is there an all-or-nothing subset? Why not just leave it at: all formats optional?

Promoting consistency of features across hardware is a high priority for
Direct3D. By enforcing an all-or-nothing subset for new hardware, as
well as enforcing full symmetric support in the future, we can guarantee
that API users will be able to write code with this new feature that
will run on a wide set of hardware, instead of worrying about the
specific support offered by each hardware vendor.

- Why isn't UAV Typed load support required for the full set of required formats that support UAV Typed store right now? Why only future hardware?

Not all of the 2015 hardware supports all of these formats.
