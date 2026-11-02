# Using CheckFeatureSupport1 in Direct3D 12 <!-- omit in toc -->

## Contents <!-- omit in toc -->
- [Background](#background)
- [Overview](#overview)
  - [Goals](#goals)
  - [Out of Scope](#out-of-scope)
- [Using CheckFeatureSupport1](#using-checkfeaturesupport1)
  - [New API Surface](#new-api-surface)
  - [Example Usage](#example-usage)
  - [Preview SDK Version Mapping](#preview-sdk-version-mapping)
  - [Error Handling](#error-handling)
  - [Backward Compatibility \& Breaking Changes](#backward-compatibility--breaking-changes)
  - [Logging](#logging)
- [FAQ](#faq)
  - [1. Can an application opt out of capability clamping?](#1-can-an-application-opt-out-of-capability-clamping)
  - [2. Why does CheckFeatureSupport1 take an SDK version with each query?](#2-why-does-checkfeaturesupport1-take-an-sdk-version-with-each-query)
  - [3. Can an application use CheckFeatureSupport1 without shipping an Agility SDK?](#3-can-an-application-use-checkfeaturesupport1-without-shipping-an-agility-sdk)

## Background
Direct3D 12 applications discover GPU capabilities through `CheckFeatureSupport`, which reports tiered capability values (for example `D3D12_RAYTRACING_TIER`). Some applications accidentally perform exact value checks against a specific tier value rather than testing whether the reported tier is at least the required tier. For those applications, when a higher tier is introduced, they conclude the feature is unavailable even though hardware support has actually increased. For example an application that checked "if the reported tier is not exactly Tier 1.1, ray tracing is unsupported" broke when a newer Tier 1.2 was shipped, because it only checked for Tier 1.1. The result was that a capability improvement disabled the feature in that application.

This feature exposes an SDK version parameter in the `CheckFeatureSupport1` API. When an application passes the Agility SDK version it was built against, the runtime clamps tiered capability values it reports to only those that existed at that SDK version, so an application never sees capability values newer than its SDK. The clamping affects only the reported value, and the runtime continues to operate with the true capability level. The debug layer has a warning saying that a cap was reported lower due to `SDKVersion`. Clamping applies to capabilities introduced with or after `CheckFeatureSupport1` and does not retroactively apply to earlier capabilities.

## Overview
`CheckFeatureSupport1` is a Direct3D 12 API that extends the existing `CheckFeatureSupport` with an SDK version parameter, allowing an application to tell the runtime which Agility SDK version it was built against. Using this value, the runtime clamps the tiered capability values it reports so that an application only ever sees capability values that existed at or before its SDK version. This prevents a bug in which applications perform exact value checks against a capability tier and mistakenly disable a feature when a newer, higher tier is introduced.

Clamping affects only the value reported back to the caller, and the runtime operates with the true tier. The existing `CheckFeatureSupport` API continues to work but we warn customers to move to `CheckFeatureSupport1`. The feature is designed to protect capabilities after the release of `CheckFeatureSupport1`, rather than capabilities that have already shipped.

### Goals
- Prevent the compatibility bug where applications perform exact value checks against a capability tier and disable a feature when a newer, higher tier is introduced.
- Allow IHVs to introduce new capability tiers without breaking applications that already shipped.
- Give applications a version-aware capability-query pattern for capabilities introduced in future SDK versions.
- Clamp only the value reported to the caller while the runtime continues to operate at the true capability level.
- Surface a debug layer warning whenever a capability is clamped because of the requested SDK version.
- Preserve the existing `CheckFeatureSupport` API while guiding applications toward `CheckFeatureSupport1`.

### Out of Scope
- Retroactively remapping capabilities that already shipped to older SDK versions. The feature protects new capabilities going forward.
- Changing actual runtime or hardware behavior. Only the reported capability value is affected, not the functionality the runtime provides. Clamping assumes new tiers are strict supersets of their predecessors (they add capability without changing existing behavior). If a change is behavioral rather than additive, clamping the reported value causes the report to no longer match the behavior the runtime is actually using, and clamping alone will not guarantee the safety of an app that cannot support the new behavior.
- Fixing or replacing application capability checking logic. The feature only affects runtime reporting.
- `ID3D12VideoDevice::CheckFeatureSupport` and other non-`ID3D12Device` feature query APIs. This behavior applies only to `ID3D12Device::CheckFeatureSupport` and `ID3D12Device17::CheckFeatureSupport1`.
- Input-keyed feature queries, whose output depends on caller-supplied inputs (for example `D3D12_FEATURE_DATA_FORMAT_SUPPORT` and `D3D12_FEATURE_DATA_MULTISAMPLE_QUALITY_LEVELS`).

## Using CheckFeatureSupport1

### New API Surface
The public `CheckFeatureSupport` API lives on the base `ID3D12Device` interface. `CheckFeatureSupport1` is exposed on `ID3D12Device17`. It is identical to `CheckFeatureSupport` with an additional `SDKVersion` parameter carrying the Agility SDK version the application was built against.

```cpp
HRESULT CheckFeatureSupport1(
    D3D12_FEATURE Feature,
    void* pFeatureSupportData,
    UINT FeatureSupportDataSize,
    UINT SDKVersion);
```

Applications obtain `ID3D12Device17` by calling `QueryInterface` on their device and must handle `E_NOINTERFACE` on runtimes that do not expose it.

`SDKVersion` uses the Agility SDK version number directly. Applications should pass the Agility SDK version they were built against.

### Example Usage

The application queries its existing device for `ID3D12Device17`, passes the Agility SDK version it was built against, and checks the returned `HRESULT` before reading the feature data.

```c++
HRESULT CheckRaytracingSupport(
    ID3D12Device* pDevice,
    bool* pRaytracingSupported)
{
    if (pDevice == nullptr || pRaytracingSupported == nullptr)
    {
        return E_INVALIDARG;
    }

    *pRaytracingSupported = false;

    Microsoft::WRL::ComPtr<ID3D12Device17> device17;
    HRESULT hr = pDevice->QueryInterface(IID_PPV_ARGS(&device17));
    if (FAILED(hr))
    {
        return hr;
    }

    D3D12_FEATURE_DATA_D3D12_OPTIONS5 options5 = {};
    hr = device17->CheckFeatureSupport1(
        D3D12_FEATURE_D3D12_OPTIONS5,
        &options5,
        sizeof(options5),
        D3D12_SDK_VERSION);

    if (SUCCEEDED(hr))
    {
        *pRaytracingSupported =
            options5.RaytracingTier >= D3D12_RAYTRACING_TIER_1_1;
    }

    return hr;
}
```

Unlike `CheckFeatureSupport`, `CheckFeatureSupport1` takes an `SDKVersion` argument. Pass Agility SDK version (such as `D3D12_SDK_VERSION`) application was built against, runtime uses it to avoid reporting capability tiers that were released after the application’s SDK.

If `QueryInterface` returns `E_NOINTERFACE`, the runtime does not support `CheckFeatureSupport1`. The application may use `CheckFeatureSupport` as a compatibility fallback, subject to the limitations described in [Backward Compatibility & Breaking Changes](#backward-compatibility--breaking-changes).

Applications should continue testing tiers with `>=` rather than exact equality. Version-aware clamping protects applications from capability values introduced after their SDK, but does not replace correct capability checks.

For example, if the runtime supports a newer raytracing tier but the application's SDK defines tiers only through `D3D12_RAYTRACING_TIER_1_2`, `CheckFeatureSupport1` reports no higher than `TIER_1_2`. The runtime continues to use the true hardware capability internally.

### Preview SDK Version Mapping
Retail and preview builds use separate SDK versions. On a retail runtime, the exact current `D3D12_PREVIEW_SDK_VERSION` value is treated as `D3D12_SDK_VERSION`. Other preview version numbers are not remapped.

For example, a retail runtime whose `D3D12_SDK_VERSION` is `620` and whose `D3D12_PREVIEW_SDK_VERSION` is `721` remaps a requested `SDKVersion` of `721` to `620`.

### Error Handling
The requested `SDKVersion` (after any preview remap, see [Preview SDK Version Mapping](#preview-sdk-version-mapping)) is compared against the runtime's version. A version at or below the runtime's version is accepted and drives clamping.

A version greater than the runtime's version causes `CheckFeatureSupport1` to return `E_INVALIDARG` without querying capabilities or modifying `pFeatureSupportData`. The debug layer reports an error identifying the unsupported SDK version.

### Backward Compatibility & Breaking Changes
`CheckFeatureSupport1` is additive and does not change the signature of `CheckFeatureSupport`. However, legacy `CheckFeatureSupport` callers are permanently pinned to the pre-clamping compatibility level. An app recompiled against a newer Agility SDK that keeps calling `CheckFeatureSupport` will not see tiers introduced after that cutoff, even with a correct `>=` check. To see newer tiers, a caller must move to `CheckFeatureSupport1` and pass its SDK version. This pinning is by design, and the debug layer flags the deprecated entry point (see [Logging](#logging)).

### Logging
Whenever a field is clamped, the debug layer emits a warning identifying the affected field, the requested `SDKVersion`, and the value it was clamped from and to. A too-new `SDKVersion` emits an error and causes `CheckFeatureSupport1` to return `E_INVALIDARG` (see [Error Handling](#error-handling)). The deprecated `CheckFeatureSupport` entry point also emits a warning.

## FAQ

### 1. Can an application opt out of capability clamping?

No. An opt-out would let applications see newer tier values they may not handle correctly, bringing back the compatibility problem that clamping prevents.

To query newer tiers, use `CheckFeatureSupport1` and pass the SDK version the calling code was built against. Continuing to use `CheckFeatureSupport` does not bypass clamping, and passing a version newer than the runtime supports is not a supported workaround.

### 2. Why does CheckFeatureSupport1 take an SDK version with each query?

Not every application exports `D3D12SDKVersion` or requests an Agility SDK version. Applications using the runtime included with Windows may not specify one at all, but they still need protection from newer tier values.

Using the application's version when available, with a default limit otherwise, would not solve every case. Components sharing a device may have been built against different SDK versions. An older component could receive a device from a newer application and see tiers it does not understand. Setting the version once during device creation would have the same problem.

Passing the SDK version with each `CheckFeatureSupport1` call lets the component making the query specify the version it understands.

### 3. Can an application use CheckFeatureSupport1 without shipping an Agility SDK?

Yes. An application built with the Windows SDK can call `CheckFeatureSupport1` and pass `D3D12_SDK_VERSION` from its Windows SDK headers.

The requested version must not be newer than the application's Agility SDK runtime or Windows runtime supports.
