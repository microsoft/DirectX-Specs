<h1>D3D12 Relaxed Format Casting Rules Functional Spec</h1>

2/6/2018 v1.3

---

<h1>Contents</h1>

- [Casting Rules for RS2+ Drivers](#casting-rules-for-rs2-drivers)
  - [Fast Clear Behavior](#fast-clear-behavior)
- [Additional Minor Optional Feature](#additional-minor-optional-feature)
- [HLK Tests](#hlk-tests)
  - [For relaxed format casting](#for-relaxed-format-casting)
  - [For BGRA UAV](#for-bgra-uav)
  - [Change History](#change-history)

---

# Casting Rules for RS2+ Drivers

The D3D12 runtime expects RS2+ drivers to support creating resources
with fully typed formats and subsequently creating UAVs, SRVs, DSVs or
RTVs with any fully qualified format within the same format family. The
views just reinterpret the data in memory as if it is the type in the
view format, ignoring the format originally created for the view. For
example a resource created with format R8G8B8A8_UNORM can have an
R8G8B8A8_UNORM_SRGB SRV created and the SRV just interprets the data
as if it is UNORM_SRGB.

Applications can discover support via CheckFormatSupport with
D3D12_FEATURE_D3D12_OPTIONS3. The associated struct,
D3D12_FEATURE_DATA_D3D12_OPTIONS3 has a member BOOL
CastingFullyTypedFormatSupported. The runtime simply sets this to true
for RS2+ drivers.

Two exceptions to this relaxed casting are:

(1) Casting from _FLOAT to non-_FLOAT formats and vice versa is never
    allowed. For instance casting from R32_FLOAT to/from R32_UINT is
    not allowed.

(2) Casting from _SNORM to _UNORM and vice versa is never allowed.
    This case was missed by the time RS3 shipped, so the runtime doesn't
    validate it. The debug layer will at least print an error.

Some hardware uses different memory compression techniques and/or clear
behaviors across these that could appear as corruption as opposed to the
expected reinterpret-cast.

---

## Fast Clear Behavior

Resources can specify a fast clear color on resource creation. This
always functions based on the format the resource was created with.
Views that do format casting will just reinterpret the data as if it is
the view format.

---

# Additional Minor Optional Feature

For D3D11 drivers and D3D12 RS2+ drivers, BGRA UAV support can be
exposed by drivers now (including typed UAV load). This is optional,
though actual hardware support appears to be quite broad, assuming
drivers choose to expose it. This change isn't about format casting
(though relaxed format casting described above applies to BGRA too). It
is small enough that it doesn't warrant a separate spec so is included
here.

Applications can discover support for BGRA UAV store (and separately,
load) via the usual mechanism -- CheckFeatureSupport() with
D3D12_FEATURE_FORMAT_SUPPORT.

---

# HLK Tests

---

## For relaxed format casting

The TAEF based HLK test D3DConf_12_Core.dll has a new test:
D3DConf_12_0_ResourceBindingAdditional::RelaxedCasting

---

## For BGRA UAV

D3DConf_12_Core.dll and D3DConf_11_Core.dll have updated tests:

D3DConf_TypedUAVLoad::AllOrNothingSubsetConformance

D3DConf_TypedUAVLoad::IHVBringUpTest

---

## Change History

v1.3 2/6/2018

> Disallowed casting from _SNORM <-> _UNORM due to IHV constraint.
> This was caught too late (after RS3 shipped), so the runtime can't
> start failing. Only the debug layer can print errors for this.

v1.2 7/11/2017

> Disallowed casting from _FLOAT <-> non-FLOAT formats given some
> hardware that uses different compression across these.

v1.1 6/2/2017

> Updated to expose the features in this spec on RS2+ drivers (was RS3+
> before). After running the HLK test on all IHVs with 2.2 drivers, the
> overwhelming majority of test cases for casting worked fine on all
> hardware. There were a small number of obscure failures with casting
> of depth formats -- not severe enough to stop exposing the feature
> overall. IHVs can work to fix even these obscure failures as they
> author RS3 drivers (we would not enforce these HLK failures on 2.2
> drivers).

v1.0 5/18/2017

Initial version
