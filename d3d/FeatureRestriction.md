# FeatureRestriction for Direct3D 12

- [FeatureRestriction for Direct3D 12](#featurerestriction-for-direct3d-12)
  - [Overview](#overview)
  - [Background](#background)
  - [Goals](#goals)
  - [Usage Scenarios](#usage-scenarios)
  - [Feature Description](#feature-description)
  - [Using FeatureRestriction](#using-featurerestriction)
    - [Application Usage](#application-usage)
      - [API Changes](#api-changes)
      - [Restriction Scope](#restriction-scope)
      - [Example Usage](#example-usage)
    - [External Tool Usage](#external-tool-usage)
      - [D3DConfig Registry Settings](#d3dconfig-registry-settings)
      - [Configuration Lifetime](#configuration-lifetime)
    - [PIX Integration](#pix-integration)
    - [Responsibilities](#responsibilities)
  - [Supported Restrictions](#supported-restrictions)
  - [Implementation Details](#implementation-details)
    - [D3DConfig Library Interface](#d3dconfig-library-interface)
    - [FeatureRestrictionState Object](#featurerestrictionstate-object)
    - [Before Device Creation](#before-device-creation)
      - [Loading External Restrictions](#loading-external-restrictions)
    - [At Device Creation](#at-device-creation)
    - [After Device Creation](#after-device-creation)
    - [Applying Capability Restrictions](#applying-capability-restrictions)
      - [GetCaps()](#getcaps)
      - [CheckFeatureSupport()](#checkfeaturesupport)
      - [LLOCompleteLayerConstruction()](#llocompletelayerconstruction)
      - [CacheHeapCaps()](#cacheheapcaps)
      - [Excluded Features Details](#excluded-features-details)
    - [Error Handling](#error-handling)
  - [Testing](#testing)
  - [Telemetry](#telemetry)
  - [Appendix A: Supported Feature Data Structures](#appendix-a-supported-feature-data-structures)
    - [Supported Restriction Inputs](#supported-restriction-inputs)
    - [Excluded Fields in Supported Structures](#excluded-fields-in-supported-structures)
    - [Queries Not Accepted as Restriction Inputs](#queries-not-accepted-as-restriction-inputs)
  - [Appendix B: Capability Integration Reference](#appendix-b-capability-integration-reference)
    - [GetCaps Mapping](#getcaps-mapping)
    - [CheckFeatureSupport Mapping](#checkfeaturesupport-mapping)
    - [LLOCompleteLayerConstruction Mapping](#llocompletelayerconstruction-mapping)
    - [CacheHeapCaps Mapping](#cacheheapcaps-mapping)


## Overview
The FeatureRestriction feature allows developers to restrict feature capability reporting in Direct3D 12 without changing drivers or hardware. Without this feature, application development and fallback testing can only query the real hardware capabilities of the GPU driver and physical hardware to determine what features are available. Developers often need to validate fallback paths and ensure compatibility with older hardware. This feature simulates less capable environments to verify application stability. Without a way to reduce the capabilities reported back by the driver and Direct3D, teams are forced to rely on custom driver builds or physical hardware variations, which are costly and time consuming to set up.

FeatureRestriction solves this problem by allowing capability restrictions to be configured before device creation. Applications and tests that control device creation can configure restrictions through a runtime API. External tools can configure restrictions for applications that cannot be modified. D3DCore validates and applies the restrictions when creating the device. Restrictions can only reduce capability reporting and never enable unsupported hardware features.

## Background
Direct3D applications query GPU capabilities such as resource binding tiers, shader model versions, and advanced features like ray tracing or variable rate shading. These queries are reported by the driver and actual hardware, so developers cannot control reported results to determine if their application is able to navigate a wide range of hardware and drivers capabilities. For example, this makes it difficult to test scenarios where certain features are unavailable, such as validating fallback paths or simulating older hardware configurations.

## Goals
The primary goal of the FeatureRestriction feature is to give developers more flexibility during the testing and validation of their application. It enables developers to simulate missing or limited hardware features on a device, ensuring that fallback paths and legacy code remain functional even as new capabilities are introduced. By removing the dependency on custom drivers or hardware, FeatureRestriction reduces complexity and speeds up development.

## Usage Scenarios
FeatureRestriction supports several testing and investigation scenarios.

It can be used by developers who control the application source. It can also be used by engineers who need to test an existing application that cannot be modified.

- **Application development and testing** uses the API to test fallback paths and lower capability configurations.
- **External testing** uses a tool to restrict an existing application without modifying its source.
- **GPU profile testing** applies a saved set of capability restrictions that represents a lower capability GPU configuration.

## Feature Description
FeatureRestriction allows capability restrictions to be provided before device creation, either through the restriction APIs or through the registry if application source code is unavailable. Registry based restrictions are converted into the same internal factory state used by the APIs so both sources use the same validation and capability restriction code. During device initialization, D3DCore combines those limits with the actual capabilities of the device and computes a local effective capability set. Cached capabilities and `CheckFeatureSupport` results use that set. Unspecified capabilities retain their actual limits unless a dependency requires a further reduction.

FeatureRestriction can only reduce capabilities reported by D3D. It cannot enable unsupported features. A restriction above the hardware's native capability has no effect.

Device creation fails if the restricted capabilities do not meet the minimum feature level requested by the application.

FeatureRestriction changes capability reporting only. It does not emulate another GPU's behavior or performance, and it does not make invalid workloads valid.

## Using FeatureRestriction
This section describes how restrictions are configured through the API and external tools. There are two ways to configure restrictions before device creation. Applications and tests that control device creation use the API. External tools use application settings when the application cannot be modified.

### Application Usage
Applications and tests configure restrictions directly on a device factory.

#### API Changes
FeatureRestriction is configured through a dedicated, versioned interface associated with an `ID3D12DeviceFactory`. Applications obtain `ID3D12FeatureRestrictionConfiguration` by calling `QueryInterface` on the factory. If the runtime does not support FeatureRestriction, the query returns `E_NOINTERFACE`.

```cpp
struct D3D12_FEATURE_RESTRICTION_RESULT_DETAILS;

interface ID3D12FeatureRestrictionConfiguration : IUnknown
{
    HRESULT SetFeatureRestriction(
        D3D12_FEATURE Feature,
        const void* pRestrictionData,
        UINT RestrictionDataSize);

    HRESULT SetFeatureRestrictionField(
        D3D12_FEATURE Feature,
        PCWSTR FieldName,
        const void* pValue,
        UINT ValueSize);

    HRESULT GetLastFeatureRestrictionResultDetails(
        D3D12_FEATURE_RESTRICTION_RESULT_DETAILS* pDetails);
};
```

`SetFeatureRestriction` uses the same `D3D12_FEATURE` identifier and corresponding typed data structure as `CheckFeatureSupport`. Each successful call copies the restrictable field values and replaces all pending restrictions for that feature on the associated factory.

- **Parameters**
  - `Feature`: Feature being restricted.
  - `pRestrictionData`: Typed restriction data for the feature. Passing `nullptr` with a size of zero removes the pending restriction.
  - `RestrictionDataSize`: Size of the restriction data in bytes, or zero when removing a restriction.

Returns `S_OK` on success. A failed call leaves the existing restriction unchanged.

`SetFeatureRestrictionField` configures one field in the feature's corresponding typed data structure. Each successful call copies the field value and adds or replaces the pending restriction for that field on the associated factory. Other pending fields remain unchanged.

- **Parameters**
  - `Feature`: Feature being restricted.
  - `FieldName`: Name of the field in the feature's restriction data structure, using the same names as external settings.
  - `pValue`: Pointer to the field value, using the field's declared type. The value is copied before the call returns.
  - `ValueSize`: Size of the field value in bytes. This must match the field's declared size.

Returns `S_OK` on success. A failed call leaves the existing restrictions unchanged.

The field name must identify a supported restriction field, and `pValue` must not be `nullptr`. Unconfigured fields retain their native values unless a capability dependency requires a reduction.

`GetLastFeatureRestrictionResultDetails` retrieves extended information about the most recent restriction result for the associated factory.

- **Parameters**
  - `pDetails`: Output structure that receives the restriction result details.

Returns an `HRESULT` indicating whether the result details are retrieved successfully. See [Error Handling](#error-handling) for the result structure and restriction errors.

Applications configure all restrictions they want and then create the device through the corresponding factory. They cannot be changed on an existing device and do not automatically affect other factories or devices in the process.

#### Restriction Scope
- Restrictions belong to the configured factory. A new factory does not inherit API restrictions from another factory, but external restrictions configured for the application still apply.
- D3D copies and validates each restriction. If validation fails, existing restrictions remain unchanged.
- Apps can change restrictions on the same factory for future devices.
- The factory's restriction mutex protects updates and copying restrictions to a device. Changes made before the copy are included. Later changes do not affect that device's copy.
- Existing devices and devices created through an unconfigured factory or the legacy creation path remain unchanged.

#### Example Usage
The following example restricts shader model, root signature version, and GPU virtual address support before creating a device.

It also disables `SRVOnlyTiledResourceTier3` through the field method without changing `RenderPassesTier`.

```cpp
ComPtr<ID3D12FeatureRestrictionConfiguration> restrictionConfiguration;
ThrowIfFailed(factory->QueryInterface(IID_PPV_ARGS(&restrictionConfiguration)));

D3D12_FEATURE_DATA_SHADER_MODEL shaderModel = {};
shaderModel.HighestShaderModel = D3D_SHADER_MODEL_6_0;
ThrowIfFailed(restrictionConfiguration->SetFeatureRestriction(
    D3D12_FEATURE_SHADER_MODEL,
    &shaderModel,
    sizeof(shaderModel)));

D3D12_FEATURE_DATA_ROOT_SIGNATURE rootSignature = {};
rootSignature.HighestVersion = D3D_ROOT_SIGNATURE_VERSION_1_0;
ThrowIfFailed(restrictionConfiguration->SetFeatureRestriction(
    D3D12_FEATURE_ROOT_SIGNATURE,
    &rootSignature,
    sizeof(rootSignature)));

D3D12_FEATURE_DATA_GPU_VIRTUAL_ADDRESS_SUPPORT gpuVirtualAddress = {};
gpuVirtualAddress.MaxGPUVirtualAddressBitsPerResource = 32;
gpuVirtualAddress.MaxGPUVirtualAddressBitsPerProcess = 36;
ThrowIfFailed(restrictionConfiguration->SetFeatureRestriction(
    D3D12_FEATURE_GPU_VIRTUAL_ADDRESS_SUPPORT,
    &gpuVirtualAddress,
    sizeof(gpuVirtualAddress)));

BOOL srvOnlyTiledResourceTier3 = FALSE;
ThrowIfFailed(restrictionConfiguration->SetFeatureRestrictionField(
    D3D12_FEATURE_D3D12_OPTIONS5,
    L"SRVOnlyTiledResourceTier3",
    &srvOnlyTiledResourceTier3,
    sizeof(srvOnlyTiledResourceTier3)));

ComPtr<ID3D12Device> device;
ThrowIfFailed(factory->CreateDevice(
    adapter.Get(),
    D3D_FEATURE_LEVEL_11_0,
    IID_PPV_ARGS(&device)));
```

### External Tool Usage
External tools configure restrictions for applications that cannot call the API themselves. PIX and other tools can read a GPU profile and translate its entries into external FeatureRestriction settings. The D3DConfig library stores the settings for the target application. D3DCore reads the settings before device creation and does not read or parse the profile itself.

#### D3DConfig Registry Settings
D3DConfig already supports application specific D3D12 registry settings, and D3DCore has the ability to find the settings that match the current application.

D3DConfig provides shared library functions for reading and modifying its registry backed settings. `d3dconfig.exe` uses this library for its command-line operations, and other tools reuse individual functions where needed. FeatureRestriction settings are exposed through the shared library so PIX or another external tool can configure them without launching `d3dconfig.exe`.

FeatureRestriction uses this existing mechanism. The D3DConfig library stores FeatureRestriction values for the selected application. D3DCore reads those values and converts them into internal restriction entries.

The following example registers an application, enables GPU based validation, and disables existing heap support.

```console
d3dconfig apps --add "C:\Games\SampleGame.exe"
d3dconfig debug-layer gbv-mode=on
d3dconfig featurerestriction existing-heaps-supported=off
```

The shared functions used by external tools are described in [D3DConfig Library Interface](#d3dconfig-library-interface).

#### Configuration Lifetime
The D3DConfig library stores external restrictions as persistent application settings in the registry, until an external tool (ex. PIX or `d3dconfig.exe`) replaces or clears them. D3DCore only reads the settings and does not modify or remove them. A change applies when D3DCore loads the settings before device creation and does not affect existing factories or devices. If the external tool stops unexpectedly, the settings remain configured, so the tool should provide a user facing way to view or replace them.

### PIX Integration
PIX owns the GPU profile format, storage, and selection experience. PIX reads a GPU profile and translates its entries into FeatureRestriction settings. Before starting the target application, PIX stores the settings through the shared D3DConfig library. PIX already uses selected functions from this library, including `ResetSettingsToDefault` for its Reset D3D Settings operation. Changing the profile does not affect an existing device.

### Responsibilities

- **Application**
  - API restriction data
  - Device factory configuration
  - Device creation through the configured factory
- **External tool**
  - PIX, `d3dconfig.exe`, or another D3DConfig library consumer
  - External restriction selection
  - Persistent setting creation, replacement, and cleanup
- **PIX**
  - GPU profile format and storage
  - Profile selection experience
  - Profile translation into FeatureRestriction settings
- **D3DConfig library**
  - Target application registration
  - Registry storage and removal
- **D3DCore**
  - Application matching
  - External and API restriction validation
  - Effective capability calculation
  - Restriction application during device creation
- **Driver**
  - Native capability reporting
  - No FeatureRestriction implementation changes

## Supported Restrictions
FeatureRestriction supports the `D3D12_FEATURE` data structures and fields identified as supported restriction inputs in [Appendix A: Supported Feature Data Structures](#appendix-a-supported-feature-data-structures). API and external restrictions support the same set. Unsupported features are rejected without changing the restriction state.

Format restrictions are not supported by the current design.

## Implementation Details

FeatureRestriction is implemented in D3DCore and requires no DDI or IHV driver changes. The D3DConfig library reads and writes registry settings for external tools. It must work even with the debug layer disabled. The debug layer may add diagnostics but does not apply restrictions.

### D3DConfig Library Interface

PIX and `d3dconfig.exe` use shared D3DConfig library functions to read, write, remove, and clear FeatureRestriction values for an application.

The functions take the application's settings key and operate on its `FeatureRestriction` subkey. Writing a restriction creates the subkey if needed.

`FeatureRestrictionValues` is a struct that contains the restriction fields stored under one application's `FeatureRestriction`  registry subkey. Each entry identifies a feature, a field in its restriction data structure, and the stored DWORD value.

All currently supported restriction fields use Boolean values, 32 bit integers, or enums and flags that fit in a DWORD.

```cpp
struct FeatureRestrictionValue
{
    std::wstring FeatureName;
    std::wstring FieldName;
    DWORD Value;
};

using FeatureRestrictionValues = std::vector<FeatureRestrictionValue>;
```

- **Fields**
  - `FeatureName`: Name of the feature being restricted.
  - `FieldName`: Name of the restriction field, such as `Supported`.
  - `Value`: Stored restriction value.

For example, `D3D12_FEATURE_EXISTING_HEAPS.Supported = 0` under the `FeatureRestriction` subkey is represented by an entry with `FeatureName` set to `L"D3D12_FEATURE_EXISTING_HEAPS"`, `FieldName` set to `L"Supported"`, and `Value` set to `0`.

```cpp
void ReadFeatureRestrictionValues(HKEY hKey, FeatureRestrictionValues& values);
void WriteFeatureRestrictionValue(HKEY hKey, D3D12_FEATURE feature, PCWSTR fieldName, DWORD value);
void DeleteFeatureRestrictionValue(HKEY hKey, D3D12_FEATURE feature, PCWSTR fieldName);
void ClearFeatureRestrictionValues(HKEY hKey);
```

`ReadFeatureRestrictionValues` reads all values in the application's `FeatureRestriction` subkey.

The reader collects feature names, field names, and DWORD values without interpreting them. D3DCore resolves and validates the names afterward.

- **Parameters**
  - `hKey`: Open registry key for the target application's D3DConfig settings.
  - `values`: Output collection that receives the FeatureRestriction values.

`WriteFeatureRestrictionValue` adds or replaces one FeatureRestriction value.

- **Parameters**
  - `hKey`: Open registry key for the target application's D3DConfig settings.
  - `feature`: Feature being restricted.
  - `fieldName`: Name of the field in the feature's restriction data structure.
  - `value`: Restriction value stored for the field.

`DeleteFeatureRestrictionValue` removes one FeatureRestriction value.

- **Parameters**
  - `hKey`: Open registry key for the target application's D3DConfig settings.
  - `feature`: Feature whose restriction field is removed.
  - `fieldName`: Name of the restriction field to remove.

`ClearFeatureRestrictionValues` removes all values from the application's `FeatureRestriction` subkey.

- **Parameters**
  - `hKey`: Open registry key for the target application's D3DConfig settings.

Deleting or clearing FeatureRestriction values preserves unrelated application settings.

### FeatureRestrictionState Object

Each `ID3D12DeviceFactory` owns one internal `FeatureRestrictionState` object for its lifetime.

Each supported feature has a restriction wrapper containing its D3D12 feature data structure and a bitfield identifying which fields are configured. Values keep their declared types. An unset bit means the corresponding member is not restricted.

```cpp
// Feature Wrapper Example for D3D12_FEATURE_DATA_D3D12_OPTIONS5
struct Options5Restrictions
{
    D3D12_FEATURE_DATA_D3D12_OPTIONS5 Values{};

    enum Override : UINT
    {
        SRVOnlyTiledResourceTier3 = 1u << 0,
        RenderPassesTier = 1u << 1,
        RaytracingTier = 1u << 2
    };

    UINT OverrideMask = 0;
};

using FeatureRestriction = std::variant<
    Options5Restrictions
    // Other supported feature wrappers.
>;

struct FeatureRestrictionState
{
    std::mutex Lock;
    std::vector<FeatureRestriction> Restrictions;
};
```

The declaration above shows D3D12_FEATURE_DATA_D3D12_OPTIONS5. Define each supported feature wrapper and include it in the variant at compile time. Create entries only for configured features. Use binary search to find entries. Insert new entries in sorted order and replace existing entries without adding duplicates.

### Before Device Creation

API and external restrictions are converted into the same internal restriction entries. Both setters lock the factory's `FeatureRestrictionState`. D3DCore validates the complete input before changing the restriction entries.

`SetFeatureRestriction` validates the `D3D12_FEATURE` identifier, structure size, and restriction values. It copies the restrictable members into a new typed wrapper, sets their override bits, and replaces the feature's pending entry. Passing `nullptr` with a size of zero removes the feature's entire entry.

`SetFeatureRestrictionField` checks the feature, field name, value size, and value. It stores the value in the feature's structure and sets the field's override bit. Other fields stay unchanged.

**Note:** If the same feature is configured externally and through the API, the API restriction takes precedence.

#### Loading External Restrictions

The D3DConfig library stores the application name and settings under an `ApplicationN` registry key. The number is the next available application entry. Restrictions are stored in its `FeatureRestriction` subkey. The following abbreviated entry includes an existing GPU based validation setting and a FeatureRestriction setting.

```text
HKCU\Software\Microsoft\Direct3D\Direct3D12\Application0

Name                                                       Type         Data
Name                                                       REG_SZ       C:\Games\SampleGame.exe
EnableGPUBasedValidationFlagsOr                            REG_DWORD    1

HKCU\Software\Microsoft\Direct3D\Direct3D12\Application0\FeatureRestriction

Name                                                       Type         Data
D3D12_FEATURE_EXISTING_HEAPS.Supported                       REG_DWORD    0
```

D3DCore uses its existing application registry matching code to find the entry for the running application.

D3DCore reads the values from the matching entry's `FeatureRestriction` subkey. For example, it creates the following field value for `D3D12_FEATURE_EXISTING_HEAPS.Supported`.

```cpp
BOOL supported = FALSE;
```

D3DCore uses the following methods to load external restrictions and share restriction validation with the public API.

```cpp
HRESULT DeviceConfiguration::UpdateFromFeatureRestrictionValues();

HRESULT DeviceConfiguration::SetFeatureRestrictionInternal(
    D3D12_FEATURE Feature,
    const void* pRestrictionData,
    UINT RestrictionDataSize);

HRESULT DeviceConfiguration::SetFeatureRestrictionFieldInternal(
    D3D12_FEATURE Feature,
    PCWSTR FieldName,
    const void* pValue,
    UINT ValueSize);
```

`UpdateFromFeatureRestrictionValues` uses `OpenAppRegKey` to open the matching application key, then reads names and DWORD values from its `FeatureRestriction` subkey. A missing subkey means no external restrictions are configured. It converts feature names to `D3D12_FEATURE` values and each DWORD to the field's declared type, then calls `SetFeatureRestrictionFieldInternal` to validate and store it. Missing fields keep their override bits unset. The loader skips features already configured through the two API setters.

Returns `S_OK` when loading succeeds or no restrictions are configured. If a restriction is invalid, the loader records the result details and returns an error. Device creation fails with that error.

`SetFeatureRestrictionInternal` validates the whole restriction structure and copies its restrictable fields into the factory state. The public `SetFeatureRestriction` method uses this helper.

- **Parameters**
  - `Feature`: Feature being restricted.
  - `pRestrictionData`: Typed restriction data for the feature. Passing `nullptr` with a size of zero removes the pending restriction.
  - `RestrictionDataSize`: Size of the restriction data in bytes, or zero when removing a restriction.

Returns `S_OK` on success. A failed call leaves the existing restriction unchanged.

`SetFeatureRestrictionFieldInternal` validates and copies one field into the factory state. The public `SetFeatureRestrictionField` method and registry loader use this helper. Both internal helpers use the same field validation.

- **Parameters**
  - `Feature`: Feature being restricted.
  - `FieldName`: Name of the field in the feature's restriction data structure.
  - `pValue`: Pointer to the field value, using the field's declared type.
  - `ValueSize`: Size of the field value in bytes.

Returns `S_OK` on success. A failed call leaves the existing restrictions unchanged.

### At Device Creation

Before capability queries begin, D3DCore loads the external restrictions and combines them with the factory's API restrictions. API restrictions take precedence for the same feature. When copying the restrictions for the device, D3DCore takes the factory's restriction mutex and releases it after the copy. The device's copy contains the restrictions present at that point.

```cpp
struct DeviceFeatureRestrictionState
{
    std::vector<FeatureRestriction> Restrictions;
};

class CCreateDeviceCache
{
    DeviceFeatureRestrictionState const* m_pFeatureRestrictions;
};

class CDevice
{
    DeviceFeatureRestrictionState m_FeatureRestrictions;
};
```

The `DeviceFeatureRestrictionState` snapshot is passed to the existing `CCreateDeviceCache` while native capabilities are gathered and device capability state is initialized. When the final device object is complete, ownership of `DeviceFeatureRestrictionState` moves to the device. Later `CheckFeatureSupport` calls use the device owned restrictions, so the device never needs to access the factory after creation.

```cpp
// Copy restrictions during device creation, before capability queries.
DeviceFeatureRestrictionState deviceRestrictions;
{
    std::lock_guard lock(factoryRestrictions.Lock);
    deviceRestrictions.Restrictions = factoryRestrictions.Restrictions;
}

// During synchronous device creation.
CCreateDeviceCache createDeviceCache(..., &deviceRestrictions);
createDeviceCache.QueryAndInitializeCapabilities();

// After capability initialization, when the final device object is constructed.
auto device = CreateDeviceObject(..., std::move(deviceRestrictions));
```

If the restricted capabilities do not meet the minimum feature level requested by `CreateDevice`, device creation fails.

[`GetCaps()`](#getcaps), [`LLOCompleteLayerConstruction()`](#llocompletelayerconstruction), and [`CacheHeapCaps()`](#cacheheapcaps) produce or cache capability data during device creation. Restrictions must be applied before those values are published or cached.

### After Device Creation

After creation, [`CheckFeatureSupport()`](#checkfeaturesupport) uses the device level restriction state and effective capabilities. It does not access the factory or shared adapter restriction state.

Setters use `FeatureRestrictionState`, which has a lock. Device queries use the separate, immutable `DeviceFeatureRestrictionState`. Later factory changes do not affect the restrictions stored on existing devices.

### Applying Capability Restrictions
- Keep field name matching, type and value validation, override bits, and capability application in feature-specific code. Both setters and external loading use the same validation rules.
- Classify every field as restrictable, derived, or excluded.
- Apply only fields whose override bits are set. Unset fields are not treated as zero restrictions.
- Apply restrictions to basic capabilities first, then recalculate dependent capabilities and select the highest feature level supported by the restricted capabilities. If that level is below the minimum requested by `CreateDevice`, device creation fails.
- Lowering the feature level does not automatically disable optional features. They remain available unless explicitly restricted or affected by a capability dependency.
- Reject unsupported or inconsistent restrictions instead of silently ignoring them.
- Require new capability fields to be classified and covered by tests.
- Use the same effective capability values during initialization, caching, validation, and reporting.

The following subsections describe where D3DCore obtains or calculates capability values and where restrictions are applied. `GetCaps()` handles driver reported capabilities, while `CheckFeatureSupport()`, `LLOCompleteLayerConstruction()`, and `CacheHeapCaps()` handle values calculated or cached by the runtime.

#### GetCaps()

`GetCaps()` gets native capability values from the driver. After a successful `VersionedGetCaps` call through `CUMDAdapter::GetCaps(...)`, D3DCore compares the result with the cached device restriction snapshot and applies any valid reductions to the local result. Shared adapter capability data remains unchanged, and normal driver failures and DDI version checks are preserved.

See [GetCaps Mapping](#getcaps-mapping) for the DDI sources and restriction points.

#### CheckFeatureSupport()
Some feature values are calculated directly in `CheckFeatureSupport()` rather than obtained through `GetCaps()`, so restrictions must also be applied in this path.

`D3D12_FEATURE_FEATURE_LEVELS` reports support based on the feature level selected after restrictions are applied, rather than the driver's unrestricted feature level.

See [CheckFeatureSupport Mapping](#checkfeaturesupport-mapping) for capability values handled by this query path.

#### LLOCompleteLayerConstruction()
`LLOCompleteLayerConstruction()` calculates runtime capabilities and stores them in `m_ValidationInfo`. Apply the restrictions stored on the device and recalculate dependent values before the results are cached or copied.

See [LLOCompleteLayerConstruction Mapping](#llocompletelayerconstruction-mapping) for capabilities calculated during layer construction.

#### CacheHeapCaps()

Apply the restrictions stored on the device after heap capabilities are calculated and before the results are stored in `m_ValidationInfo`.

See [CacheHeapCaps Mapping](#cacheheapcaps-mapping) for heap capabilities calculated and cached by this function.

#### Excluded Features Details

[Appendix A](#appendix-a-supported-feature-data-structures) lists excluded features and fields with the reason for each exclusion.

### Error Handling
`SetFeatureRestriction()` and `SetFeatureRestrictionField()` return an `HRESULT` if a restriction is invalid. A failed call leaves the existing restrictions unchanged. The field setter rejects unsupported field names, null value pointers, incorrect value sizes, and invalid field values.

If an external restriction names a feature or field that is not supported for restriction, device creation fails. D3DCore treats the entry as an invalid restriction.

`GetLastFeatureRestrictionResultDetails()` returns extended information about the most recent restriction result for the associated factory. It may be called after either setter or device creation completes, including when a restriction has no effect.

`GetLastFeatureRestrictionResultDetails()` identifies which feature has a restriction problem and why. For example:

- A test checks whether a requested restriction has no effect, rather than assuming it is testing the intended configuration.
- If device creation fails because a restriction cannot be applied, the application identifies the feature involved.
- An application or tool with access to the factory shows the developer why a restriction is rejected or has no effect.

```cpp
enum FEATURE_RESTRICTION_RESULT
{
    FEATURE_RESTRICTION_RESULT_OK = 0,
    FEATURE_RESTRICTION_RESULT_ERROR_VALUE_NOT_RESTRICTION = 1,
    FEATURE_RESTRICTION_RESULT_ERROR_CONSTANT = 2,
    FEATURE_RESTRICTION_RESULT_ERROR_NOT_UPDATED = 3,
};

struct D3D12_FEATURE_RESTRICTION_RESULT_DETAILS
{
    D3D12_FEATURE Feature;
    HRESULT Result;
    FEATURE_RESTRICTION_RESULT RestrictionResult;
};
```

A restriction above the native capability leaves the native value unchanged and reports `FEATURE_RESTRICTION_RESULT_ERROR_VALUE_NOT_RESTRICTION`. It does not fail device creation.

Restrictions that require hardware validation are checked during device creation. If a restriction cannot be applied, device creation fails instead of creating an unrestricted device.

## Testing
Typed restrictions with different valid and invalid values are tested in `D3D12Func` and other locations to ensure the feature is production ready. PIX tests JSON profile parsing and translation separately. Testing scenarios cover the following:

- **Functional Tests**
  - All feature restrictions are correctly applied
  - Constant features do not change
  - A field restriction leaves unconfigured fields unchanged unless a capability dependency requires a reduction
  - Repeated field calls replace only the named field and preserve other pending fields
  - A whole structure call followed by a field call changes only the named field and preserves the other pending fields
  - A field call followed by a whole structure call replaces all pending restrictions for that feature
- **Negative and Edge Cases**
  - Invalid or incomplete restrictions do not cause unexpected behavior or crashes
  - Failed restrictions are not applied and existing restrictions remain unchanged
  - Unsupported field names, null value pointers, incorrect value sizes, and invalid field values are rejected
  - An external restriction targeting an unsupported feature or field causes device creation to fail.
  - `GetLastFeatureRestrictionResultDetails()` reports the invalid restriction after the failure.
- **Isolation**
  - Restrictions configured on one factory do not affect other factories or devices
  - `SetFeatureRestriction` and `SetFeatureRestrictionField` remain usable after device creation. Later changes do not affect restrictions already copied for a device.
- **Logging**
  - Restrictions that fail or cannot be changed are logged correctly
- **Integration**
  - The feature does not cause system instability
  - External restrictions apply without the application calling `SetFeatureRestriction`.
  - Multiple external fields for the same feature are loaded and applied without replacing one another
  - An API restriction takes precedence when the same feature is configured externally.
  - Clearing FeatureRestriction settings preserves unrelated application settings.
  - Changes to external settings do not affect existing devices.

## Telemetry

FeatureRestriction extends existing D3D12 device creation telemetry to measure usage and identify configuration failures.

The following data is collected:

- Whether FeatureRestriction was configured for the factory
- Number of restrictions configured
- Number of restrictions applied
- The `FEATURE_RESTRICTION_RESULT` returned
- Whether restricted device creation succeeded

## Appendix A: Supported Feature Data Structures
API and external restrictions support the structures listed below, except for the fields excluded later in this appendix.

This appendix is accurate as of the spec's publication date.

### Supported Restriction Inputs

- D3D12_FEATURE_DATA_D3D12_OPTIONS
- D3D12_FEATURE_DATA_GPU_VIRTUAL_ADDRESS_SUPPORT
- D3D12_FEATURE_DATA_SHADER_MODEL
- D3D12_FEATURE_DATA_ROOT_SIGNATURE
- D3D12_FEATURE_DATA_SUPPORTED_PSO_FLAGS
- D3D12_FEATURE_DATA_SHADER_CACHE
- D3D12_FEATURE_DATA_CROSS_NODE
- D3D12_FEATURE_DATA_DISPLAYABLE
- D3D12_FEATURE_DATA_PREDICATION
- D3D12_FEATURE_DATA_HARDWARE_COPY
- D3D12_FEATURE_DATA_APPLICATION_SPECIFIC_DRIVER_STATE
- D3D12_FEATURE_DATA_EXISTING_HEAPS
- D3D12_FEATURE_DATA_D3D12_OPTIONS_EXPERIMENTAL1
- D3D12_FEATURE_DATA_D3D12_OPTIONS1
- D3D12_FEATURE_DATA_D3D12_OPTIONS2
- D3D12_FEATURE_DATA_D3D12_OPTIONS3
- D3D12_FEATURE_DATA_D3D12_OPTIONS4
- D3D12_FEATURE_DATA_D3D12_OPTIONS5
- D3D12_FEATURE_DATA_D3D12_OPTIONS6
- D3D12_FEATURE_DATA_D3D12_OPTIONS7
- D3D12_FEATURE_DATA_D3D12_OPTIONS9
- D3D12_FEATURE_DATA_D3D12_OPTIONS10
- D3D12_FEATURE_DATA_D3D12_OPTIONS11
- D3D12_FEATURE_DATA_D3D12_OPTIONS12
- D3D12_FEATURE_DATA_D3D12_OPTIONS13
- D3D12_FEATURE_DATA_D3D12_OPTIONS14
- D3D12_FEATURE_DATA_D3D12_OPTIONS15
- D3D12_FEATURE_DATA_D3D12_OPTIONS16
- D3D12_FEATURE_DATA_D3D12_OPTIONS17
- D3D12_FEATURE_DATA_D3D12_OPTIONS19
- D3D12_FEATURE_DATA_D3D12_OPTIONS20
- D3D12_FEATURE_DATA_D3D12_OPTIONS21
- D3D12_FEATURE_DATA_D3D12_OPTIONS22
- D3D12_FEATURE_DATA_TIGHT_ALIGNMENT
- D3D12_FEATURE_DATA_WORK_LISTS
- D3D12_FEATURE_DATA_PARTIAL_GRAPHICS_PROGRAMS
- D3D12_FEATURE_DATA_MLIR_COMPUTE_GRAPH_SUPPORT
- D3D12_FEATURE_DATA_VARIABLE_GROUPSHARED_LIMITS
- D3D12_FEATURE_DATA_USER_DEFINED_ANNOTATION
- D3D12_FEATURE_DATA_DEBUG_BREAK
- D3D12_FEATURE_DATA_EXPLICIT_PSDBS
- D3D12_FEATURE_DATA_LINEAR_ALGEBRA_SUPPORT
- D3D12_FEATURE_DATA_D3D12_OPTIONS_RAYTRACING2
- D3D12_FEATURE_DATA_UAV_OF_DEPTH_STENCIL
- D3D12_FEATURE_DATA_DUMP_FILE
- D3D12_FEATURE_DATA_PEER_TO_PEER_NATIVE_FENCE

For the additional structures, the supported restriction fields are listed below. This describes the proposed scope, not existing FeatureRestriction implementations.

| Structure | Restrictable fields |
|---|---|
| `D3D12_FEATURE_DATA_SUPPORTED_PSO_FLAGS` | `SupportedFlags` |
| `D3D12_FEATURE_DATA_DISPLAYABLE` | `DisplayableTexture`, `SharedResourceCompatibilityTier` |
| `D3D12_FEATURE_DATA_D3D12_OPTIONS_EXPERIMENTAL1` | `DynamicShaderLinkingTier` |
| `D3D12_FEATURE_DATA_D3D12_OPTIONS22` | `CreateByteOffsetViewsSupported`, `Max1DDispatchSize`, `Max1DDispatchMeshSize` |
| `D3D12_FEATURE_DATA_TIGHT_ALIGNMENT` | `SupportTier` |
| `D3D12_FEATURE_DATA_WORK_LISTS` | `Tier`, `DispatchRaysSupported` |
| `D3D12_FEATURE_DATA_PARTIAL_GRAPHICS_PROGRAMS` | `PartialGraphicsProgramsTier` |
| `D3D12_FEATURE_DATA_MLIR_COMPUTE_GRAPH_SUPPORT` | `MultisubgraphPartitionsSupported`, `CpuBindingSupported` |
| `D3D12_FEATURE_DATA_VARIABLE_GROUPSHARED_LIMITS` | `MaxGroupSharedMemoryPerGroupCS`, `MaxGroupSharedMemoryPerGroupAS`, `MaxGroupSharedMemoryPerGroupMS` |
| `D3D12_FEATURE_DATA_USER_DEFINED_ANNOTATION` | `Supported` |
| `D3D12_FEATURE_DATA_DEBUG_BREAK` | `HaltSupported`, `LiveDebuggingSupported`, `CpuSupported` |
| `D3D12_FEATURE_DATA_EXPLICIT_PSDBS` | `ExplicitPsdbsSupported` |
| `D3D12_FEATURE_DATA_LINEAR_ALGEBRA_SUPPORT` | `LinearAlgebraTier` |
| `D3D12_FEATURE_DATA_D3D12_OPTIONS_RAYTRACING2` | `ClustersAndPTLASSupported` |
| `D3D12_FEATURE_DATA_UAV_OF_DEPTH_STENCIL` | `UAVOfDepthStencilSupported` |
| `D3D12_FEATURE_DATA_DUMP_FILE` | `DumpFileDriverTier`, `DumpFileDriverOptionsMask` |
| `D3D12_FEATURE_DATA_PEER_TO_PEER_NATIVE_FENCE` | `PeerToPeerNativeFencesSupported` |

### Excluded Fields in Supported Structures

These fields cannot be restricted directly.

| Structure | Excluded fields | Reason |
|---|---|---|
| `D3D12_FEATURE_DATA_D3D12_OPTIONS1` | `WaveLaneCountMin`, `WaveLaneCountMax`, `TotalLaneCount` | Restrictions do not change the hardware's wave or lane counts |
| `D3D12_FEATURE_DATA_D3D12_OPTIONS1` | `ExpandedComputeResourceStates` | The runtime always reports `true` |
| `D3D12_FEATURE_DATA_D3D12_OPTIONS6` | `ShadingRateImageTileSize` | Restrictions do not change the actual tile size |
| `D3D12_FEATURE_DATA_D3D12_OPTIONS12` | `MSPrimitivesPipelineStatisticIncludesCulledPrimitives` | Restrictions do not change what the counter counts |
| `D3D12_FEATURE_DATA_D3D12_OPTIONS17` | `ManualWriteTrackingResourceSupported` | The runtime currently reports `false`, and restrictions cannot enable it |
| `D3D12_FEATURE_DATA_D3D12_OPTIONS19` | `MismatchingOutputDimensionsSupported`, `PointSamplingAddressesNeverRoundUp`, `RasterizerDesc2Supported`, `NarrowQuadrilateralLinesSupported`, `AnisoFilterWithPointMipSupported` | These fields are fixed by the runtime or have no defined way to be restricted |
| `D3D12_FEATURE_DATA_D3D12_OPTIONS22` | `ShaderExecutionReorderingActuallyReorders` | Restrictions do not change whether execution is actually reordered |
| `D3D12_FEATURE_DATA_D3D12_OPTIONS_RAYTRACING2` | `TemplateInstancePrefersCOMPRESSED1` | Reports a preferred format, not a support level |
| `D3D12_FEATURE_DATA_UAV_OF_DEPTH_STENCIL` | `D32S8Interleaved` | Restrictions do not change the actual depth/stencil layout |
| `D3D12_FEATURE_DATA_DUMP_FILE` | `SupportedByOS` | Reports OS support, not a GPU capability |
| `D3D12_FEATURE_DATA_SHADER_CACHE` | `D3D12_SHADER_CACHE_SUPPORT_SINGLE_PSO` in `SupportFlags` | The runtime always supports this bit |

### Queries Not Accepted as Restriction Inputs

These queries cannot be restricted directly. Other restrictions may still change their results.

| Query or structure | Reason |
|---|---|
| `D3D12_FEATURE_DATA_ARCHITECTURE`, `D3D12_FEATURE_DATA_ARCHITECTURE1` | Restrictions do not change the hardware's memory architecture |
| `D3D12_FEATURE_DATA_FEATURE_LEVELS` | Calculated from restricted capabilities and the levels requested by the app |
| `D3D12_FEATURE_DATA_FORMAT_SUPPORT` | The design does not support separate restrictions for each format |
| `D3D12_FEATURE_DATA_MULTISAMPLE_QUALITY_LEVELS` | The design does not support separate restrictions for each format, sample count, and flag combination |
| `D3D12_FEATURE_DATA_FORMAT_INFO` | Restrictions do not change a format's plane count |
| `D3D12_FEATURE_DATA_COMMAND_QUEUE_PRIORITY` | The design does not support separate restrictions for each command list type and priority |
| `D3D12_FEATURE_DATA_SERIALIZATION` | The design does not support separate restrictions for each node |
| `D3D12_FEATURE_DATA_PROTECTED_RESOURCE_SESSION_SUPPORT` | Restrictions by node and protected-session type are not defined |
| `D3D12_FEATURE_DATA_PROTECTED_RESOURCE_SESSION_TYPE_COUNT`, `D3D12_FEATURE_DATA_PROTECTED_RESOURCE_SESSION_TYPES` | Filtering the type list and updating its count are not defined |
| `D3D12_FEATURE_DATA_QUERY_META_COMMAND` | Exchanges command-specific data, not simple capability values |
| `D3D12_FEATURE_DATA_TRACKED_WORKLOAD` | The design does not support separate restrictions for each node and command list type |
| `D3D12_FEATURE_DATA_D3D12_OPTIONS8` | The runtime always reports `UnalignedBlockTexturesSupported` as `true` |
| `D3D12_FEATURE_DATA_D3D12_OPTIONS18` | The runtime always reports `RenderPassesValid` as `true` |
| `D3D12_FEATURE_DATA_WAVE_MMA` | Restrictions for each data type and matrix size are not defined |
| `D3D12_FEATURE_DATA_PLACED_RESOURCE_SUPPORT_INFO` | Restrictions for each format, resource dimension, and heap combination are not defined |
| `D3D12_FEATURE_DATA_GUID_TEXTURE_LAYOUT` | Restrictions for each resource description and layout GUID are not defined |
| `D3D12_FEATURE_DATA_BYTECODE_BYPASS_HASH_SUPPORTED` | The runtime always reports `Supported` as `true` |
| `D3D12_FEATURE_DATA_FENCE_BARRIERS` | The design does not support separate restrictions for each node and command list type |
| `D3D12_FEATURE_DATA_HARDWARE_SCHEDULING_QUEUE_GROUPINGS` | Restrictions do not change how hardware queues are grouped |
| `D3D12_FEATURE_DATA_SHADERCACHE_ABI_SUPPORT` | Reports identities and compatible versions, not capability limits |
| `D3D12_FEATURE_DATA_ASYNC_COMMANDS` | Restrictions do not switch between native and fallback implementations |
| `D3D12_FEATURE_DATA_BARRIER_LAYOUT` | Restrictions for each command list type and layout are not defined |
| `D3D12_FEATURE_DATA_MLIR_COMPUTE_GRAPH_VERSION` | The external settings format does not support this 64-bit version value |
| `D3D12_FEATURE_DATA_MLIR_EXCHANGE` | Exchanges data, not simple capability values |
| `D3D12_FEATURE_DATA_LINEAR_ALGEBRA_MATRIX_OPERATION_SUPPORT` | Restrictions for individual operations are not defined. Results still follow the restricted `LinearAlgebraTier` |
| `D3D12_FEATURE_DATA_LINEAR_ALGEBRA_OPERATION_ENUMERATION` | Filtering the operation list is not defined. Results still follow the restricted `LinearAlgebraTier` |
| `D3D12_FEATURE_DATA_CRYPTO_SESSION_SUPPORT` | Restrictions for each node, codec, encryption, and session configuration are not defined |
| `D3D12_FEATURE_DATA_CRYPTO_SESSION_DECRYPT_TRANSFORM_SUPPORT`, `D3D12_FEATURE_DATA_CRYPTO_SESSION_ENCRYPT_TRANSFORM_SUPPORT`, `D3D12_FEATURE_DATA_CRYPTO_SESSION_TRANSCRYPT_TRANSFORM_SUPPORT` | Restrictions for each codec and encryption setup are not defined. Required buffer sizes and alignment cannot be reduced |
| `D3D12_FEATURE_DATA_CRYPTO_SESSION_KEY_EXCHANGE_SUPPORT` | Reports required buffer sizes, which cannot be reduced |
| `D3D12_FEATURE_DATA_CRYPTO_SESSION_KEY_EXCHANGE_TYPES_COUNT`, `D3D12_FEATURE_DATA_CRYPTO_SESSION_KEY_EXCHANGE_TYPES` | Filtering the key-exchange list and updating its count are not defined |
| `D3D12_FEATURE_DATA_EXECUTE_TILE_MAPPINGS` | The design does not support separate restrictions for each node |
| `D3D12_FEATURE_FORMAT_AND_GUID_SUPPORT` | Legacy entry with no current runtime query handler |

## Appendix B: Capability Integration Reference

The following tables show where D3DCore obtains or calculates capability values and where restrictions are applied. These locations must be checked against the current D3DCore source before implementation.

### GetCaps Mapping

The table shows each capability's DDI source and where its restrictions are applied.

| API enum | Corresponding DDIs | Exclusions and Notes |
|---|---|---|
| **D3D12_FEATURE_DATA_D3D12_OPTIONS** | **D3D12DDICAPS_TYPE_D3D12_OPTIONS**, **D3D12DDICAPS_TYPE_SHADER** | All features are updateable. Heap values also use the CacheHeapCaps mapping below, and GPU address limits must match GPU_VIRTUAL_ADDRESS_SUPPORT |
| **D3D12_FEATURE_DATA_D3D12_OPTIONS1** | **D3D12DDICAPS_TYPE_SHADER** | `ExpandedComputeResourceStates` is always `true`, `Int64ShaderOps` and `WaveOps` must be `true` for Shader Model >= **6.9**. Wave counts are excluded. `Native16BitShaderOpsSupported` in OPTIONS4 is also required for Shader Model >= **6.9**, so shader model support must stay consistent after restrictions |
| **D3D12_FEATURE_DATA_D3D12_OPTIONS2** | **D3D12DDICAPS_TYPE_D3D12_OPTIONS** | `DepthBoundsTestSupported` must be `false` if DDI < **25**. `ProgrammableSamplePositionsTier` is tier 0 if DDI < **0027**. |
| **D3D12_FEATURE_DATA_D3D12_OPTIONS3** | **D3D12DDICAPS_TYPE_D3D12_OPTIONS** | `CopyQueueTimestampQueriesSupported` is `false` if DDI < **32**. `ViewInstancingTier` and `BarycentricsSupported` is `false` if DDI < **33**. `CastingFullyTypedFormatSupported` is `true` if DDI >= **20**. `WriteBufferImmediateSupportFlags` is cached during `LLOCompleteLayerConstruction()` using `GetWriteBufferImmediateSupportFlags()`, so we will update the value before it is cached |
| **D3D12_FEATURE_DATA_D3D12_OPTIONS4** | **D3D12DDICAPS_TYPE_D3D12_OPTIONS**, **D3D12DDICAPS_TYPE_SHADER** | `MSAA64KBAlignedTextureSupported` mirrors `ReservedBufferPlacementSupported`, which is checked if DDI >= **41**, and `Native16BitOps` uses **D3D12DDICAPS_TYPE_SHADER**, `SharedResourceCompatibilityTier` will be updated in `CheckFeatureSupport()` |
| **D3D12_FEATURE_DATA_D3D12_OPTIONS5** | **D3D12DDICAPS_TYPE_D3D12_OPTIONS** | `SRVOnlyTiledResourceTier3` (DDI >= **52**), `RenderPassTier` (DDI >= **53**), `RaytracingTier` (DDI >= **54**). `RenderPassesTier` also has runtime checks in `LLOCompleteLayerConstruction()` |
| **D3D12_FEATURE_DATA_D3D12_OPTIONS6** | **D3D12DDICAPS_TYPE_D3D12_OPTIONS** | Checked only if DDI >= **62**. `ShadingRateImageTileSize` is excluded |
| **D3D12_FEATURE_DATA_D3D12_OPTIONS7** | **D3D12DDICAPS_TYPE_D3D12_OPTIONS** | Checked only if DDI >= **73** |
| **D3D12_FEATURE_DATA_D3D12_OPTIONS9** | **D3D12DDICAPS_TYPE_D3D12_OPTIONS**, **D3D12DDICAPS_TYPE_SHADER** | `MeshShaderSupportsFullRangeRenderTargetArrayIndex` checked if DDI >= **81**, `MeshShaderPipelineStatsSupported` is **not** changed here. The other four features, including `WaveMMATier`, are requested using **D3D12DDICAPS_TYPE_SHADER** |
| **D3D12_FEATURE_DATA_D3D12_OPTIONS10** | **D3D12DDICAPS_TYPE_D3D12_OPTIONS** | Checked only if DDI >= **83** |
| **D3D12_FEATURE_DATA_D3D12_OPTIONS11** | **D3D12DDICAPS_TYPE_SHADER** | Checked only if DDI >= **82** |
| **D3D12_FEATURE_DATA_D3D12_OPTIONS12** | **D3D12DDICAPS_TYPE_D3D12_OPTIONS**, **D3D12DDICAPS_TYPE_OPTIONS_0090** | `MSPrimitivesPipelineStatisticIncludesCulledPrimitives` checked if DDI >= **86** and `EnhancedBarriersSupported` checked if DDI >= **89**, `RelaxedFormatCastingSupported` uses **D3D12DDICAPS_TYPE_OPTIONS_0090**. `MSPrimitivesPipelineStatisticIncludesCulledPrimitives` is excluded from restrictions |
| **D3D12_FEATURE_DATA_D3D12_OPTIONS13** | **D3D12DDICAPS_TYPE_OPTIONS_0091** | `TextureCopyBetweenDimensionsSupported` and `AlphaBlendFactorSupported` are **not** checked here. `LLOCompleteLayerConstruction()` caches them, so we will update them there |
| **D3D12_FEATURE_DATA_D3D12_OPTIONS19** | **D3D12DDICAPS_TYPE_OPTIONS_0101**, **D3D12DDICAPS_TYPE_OPTIONS_0102** | `SupportedSampleCountsWithNoOutputs`, `MaxSamplerDescriptorHeapSize`,`MaxSamplerDescriptorHeapSizeWithStaticSamplers`,`MaxViewDescriptorHeapSize` have DDI backed restriction points. `ComputeOnlyCustomHeapSupported` comes from **D3D12DDICAPS_TYPE_OPTIONS_0101** and will be updated during layer construction. The excluded fields are listed in Appendix A |
| **D3D12_FEATURE_DATA_D3D12_OPTIONS20** | **D3D12DDICAPS_TYPE_OPTIONS_0109** | All features are updateable. `ComputeOnlyWriteWatchSupported` is set from WDDM 3.0 support in `LLOCompleteLayerConstruction()`, not this DDI |
| **D3D12_FEATURE_DATA_D3D12_OPTIONS21** | **D3D12DDICAPS_TYPE_OPTIONS1_0103**, **D3D12DDICAPS_TYPE_OPTIONS_0110**, **D3D12DDICAPS_TYPE_SHADER_MODEL_6_8_OPTIONS_0110** | `WorkGraphsTier` via **D3D12DDICAPS_TYPE_OPTIONS1_0103**, `ExecuteIndirectTier` via **D3D12DDICAPS_TYPE_OPTIONS_0110**, `SampleCmpGradientAndBiasSupported` and `ExtendedCommandInfoSupported` use **SHADER_MODEL_6_8_OPTIONS_0110** but `LLOCompleteLayerConstruction()` also applies additional checks so we will update the value there |
| **D3D12_FEATURE_DATA_D3D12_OPTIONS22** | **D3D12DDICAPS_TYPE_OPTIONS_0122** | **IsViewCreationByteOffsetSupportedAndImplemented** supplies `CreateByteOffsetViewsSupported`. Dispatch maxima use options 0122. Restrict these effective values in **LLOCompleteLayerConstruction**. Leave `ShaderExecutionReorderingActuallyReorders` unchanged |
| **D3D12_FEATURE_DATA_D3D12_OPTIONS_EXPERIMENTAL1** | **D3D12DDICAPS_TYPE_OPTIONS2_0103** | **LLOCompleteLayerConstruction** copies `DynamicShaderLinkingTier` and selects fallback behavior. Restrict the effective tier before that selection |
| **D3D12_FEATURE_DATA_D3D12_OPTIONS_RAYTRACING2** | **D3D12DDICAPS_TYPE_OPTIONS_RAYTRACING2** | Restrict effective `ClustersAndPTLASSupported` while preserving **Raytracing2PreviewEnabled** gating. Keep raytracing support consistent. Leave `TemplateInstancePrefersCOMPRESSED1` unchanged |
| **D3D12_FEATURE_DATA_VARIABLE_GROUPSHARED_LIMITS** | **D3D12DDICAPS_TYPE_VARIABLE_GROUPSHARED_LIMITS** | **GetOptionsVGSM** supplies `MaxGroupSharedMemoryPerGroupCS`, `MaxGroupSharedMemoryPerGroupAS` and `MaxGroupSharedMemoryPerGroupMS`. Restrict them before dependent validation and caching |
| **D3D12_FEATURE_DATA_UAV_OF_DEPTH_STENCIL** | **D3D12DDICAPS_TYPE_OPTIONS_UAV_OF_DEPTH_STENCIL** | **GetOptionsUAVOfDepthStencil** supplies cached support. Restrict `UAVOfDepthStencilSupported` and leave `D32S8Interleaved` unchanged |
| **D3D12_FEATURE_DATA_MLIR_COMPUTE_GRAPH_SUPPORT** | **D3D12DDICAPS_TYPE_MLIR_COMPUTE_GRAPH_SUPPORT_0119** | **GetMlirComputeGraphSupport** supplies `MultisubgraphPartitionsSupported` and `CpuBindingSupported`. Restrict effective support before validation state is cached |
| **D3D12_FEATURE_DATA_GPU_VIRTUAL_ADDRESS_SUPPORT** | **D3D12DDICAPS_TYPE_GPUVA_CAPS** | All features are updateable. `LLOCompleteLayerConstruction()` combines driver and OS limits, so we will update the final values before feature level checks |
| **D3D12_FEATURE_DATA_SHADER_MODEL** | **D3D12DDICAPS_TYPE_0011_SHADER_MODELS** | All features are updateable. Keep shader capability checks and dependent initialization consistent with the restricted shader model |
| **D3D12_FEATURE_DATA_PREDICATION** | **D3D12DDI_FEATURE_D3D12_PREDICATION_106** | All features are updateable. Support defaults to `true` before DDI **0106**. Keep the native driver checks and feature level requirements |
| **D3D12_FEATURE_DATA_HARDWARE_COPY** | **D3D12DDI_FEATURE_HARDWARE_COPY_106** | DDI >= **0106**, otherwise it is always **true**. Keep the native driver checks and feature level requirements |
| **D3D12_FEATURE_DATA_APPLICATION_SPECIFIC_DRIVER_STATE** | **D3D12DDI_APPLICATION_SPECIFIC_DRIVER_STATE_113** | All features are updateable |
| **D3D12_FEATURE_DATA_PEER_TO_PEER_NATIVE_FENCE** | **D3D12DDICAPS_TYPE_0129_PEER_TO_PEER_NATIVE_FENCE_SUPPORT** | Initialization requires native fences, the OS interface and DDI 0129. Restrict `m_PeerToPeerNativeFencesSupport.PeerToPeerNativeFencesSupported` so reporting and runtime validation agree |

### CheckFeatureSupport Mapping

The table shows capability values finalized through `CheckFeatureSupport()` and any input or dependency considerations.

| API enum | Corresponding Function | Exclusions and Notes |
|---|---|---|
| **D3D12_FEATURE_DATA_D3D12_OPTIONS4** | **CheckFeatureSupport**, **GetSharedResourceCompatibilityTier** | `SharedResourceCompatibilityTier` can be updated after **GetSharedResourceCompatibilityTier** sets its value. Use the same value for validation and DISPLAYABLE reporting |
| **D3D12_FEATURE_DATA_ROOT_SIGNATURE** | **CheckFeatureSupport** | `HighestVersion` will be updated |
| **D3D12_FEATURE_DATA_SUPPORTED_PSO_FLAGS** | **CheckFeatureSupport**, **GetValidPipelineStateFlags** | Native reporting validates and intersects input `SupportedFlags` with valid flags. Restrict the effective valid flags used by pipeline validation and preserve that input intersection |
| **D3D12_FEATURE_DATA_FEATURE_LEVELS** | **CheckFeatureSupport** | `MaxSupportedFeatureLevel` is selected from requested levels using recomputed effective capabilities |
| **D3D12_FEATURE_DATA_SHADER_CACHE** | **CheckFeatureSupport** | `SupportFlags` will be updated after all the existing logic. `D3D12_SHADER_CACHE_SUPPORT_SINGLE_PSO` cannot be cleared |
| **D3D12_FEATURE_DATA_CROSS_NODE** | **CheckFeatureSupport**, **CrossNodeSharingTier** | `CrossNodeSharingTier` is already set by `GetCaps()` when DDI cap type **D3D12DDICAPS_TYPE_D3D12_OPTIONS** is set, but `m_ValidationInfo.m_bCrossNodeAtomicShaderInstructions` will be updated during layer construction so validation and reporting use the same value |
| **D3D12_FEATURE_DATA_DISPLAYABLE** | **CheckFeatureSupport**, **GetSharedResourceCompatibilityTier** | `DisplayableTexture` uses `m_ValidationInfo.m_DisplayableValidationInfo.bD3D12SupportsDisplayable`. Restrict that effective support and keep `SharedResourceCompatibilityTier` consistent with OPTIONS4 |
| **D3D12_FEATURE_DATA_EXPLICIT_PSDBS** | **CheckFeatureSupport**, **ExplicitPsdbsSupported** | Native reporting and shader cache session validation use **ExplicitPsdbsSupported**. Restrict its effective support rather than only the returned field |

### LLOCompleteLayerConstruction Mapping

The table shows capabilities calculated while device validation and layer state are constructed.

| API enum (D3D12) | Corresponding Function | Notes |
|---|---|---|
| **D3D12_FEATURE_DATA_D3D12_OPTIONS9** | **LLOCompleteLayerConstruction**, **MeshShaderPipelineStatisticsSupported** | `MeshShaderPipelineStatsSupported` computed based on MeshShaderTier from Options7 so we will update it in this function |
| **D3D12_FEATURE_DATA_D3D12_OPTIONS14** | **LLOCompleteLayerConstruction**, **GetOptions0093** | First two features are in GetOptions0093! Remaining feature will be updated here |
| **D3D12_FEATURE_DATA_D3D12_OPTIONS15** | **LLOCompleteLayerConstruction** | `TriangleFanSupported` is `true` if DDI >= **97**, `DynamicIndexBufferStripCutSupported` is `true` if DDI >= **99**, so they can be updated in this function |
| **D3D12_FEATURE_DATA_D3D12_OPTIONS16** | **LLOCompleteLayerConstruction** | Both features have complex requirements so will just be updated in this function |
| **D3D12_FEATURE_DATA_D3D12_OPTIONS17** | **LLOCompleteLayerConstruction** | `ManualWriteTrackingResourceSupported` is always `false`. `NonNormalizedCoordinateSamplersSupported` is `true` if DDI >= **100**, so it will be updated here |
| **D3D12_FEATURE_DATA_D3D12_OPTIONS21** | **LLOCompleteLayerConstruction** | `SampleCmpGradientAndBiasSupported` and `ExtendedCommandInfoSupported` use **SHADER_MODEL_6_8_OPTIONS_0110** but `LLOCompleteLayerConstruction()` also applies additional checks so we will update the values after the checks. Both fields require Shader Model >= **6.8** |
| **D3D12_FEATURE_DATA_TIGHT_ALIGNMENT** | **LLOCompleteLayerConstruction**, **GetTightAlignmentTierData**, **TightAlignmentTier** | Native tier data is queried before DDI initialization and cached for validation. Restrict effective `SupportTier` before dependent initialization and preserve the reporting tier clamp |
| **D3D12_FEATURE_DATA_LINEAR_ALGEBRA_SUPPORT** | **LLOCompleteLayerConstruction**, **GetLinalgTier**, **GetLinalgQueryFormsAndEnumeration** | **GetLinalgTier** queries **D3D12DDICAPS_TYPE_LINEAR_ALGEBRA_TIER** before DDI initialization. Restrict the effective tier before DDI negotiation and operation caching. Operation queries and enumeration must follow that tier. Preserve native shader model checks and reporting clamps |
| **D3D12_FEATURE_DATA_WORK_LISTS** | **LLOCompleteLayerConstruction**, **GetOptionsWorkLists** | Native support combines **D3D12DDICAPS_TYPE_WORK_LISTS** results with CPU query negotiation and feature gating. Restrict cached `Tier` and `DispatchRaysSupported` consistently. Preserve optional dispatch rays gating and the reporting tier clamp |
| **D3D12_FEATURE_DATA_PARTIAL_GRAPHICS_PROGRAMS** | **LLOCompleteLayerConstruction** | Native initialization queries **D3D12DDICAPS_TYPE_PARTIAL_GRAPHICS_PROGRAMS** at DDI 0122 or later. Restrict cached `PartialGraphicsProgramsTier` used by validation and reporting. Preserve the reporting tier clamp |
| **D3D12_FEATURE_DATA_DUMP_FILE** | **LLOCompleteLayerConstruction**, **UpdateDumpFileFeatureData**, **ConfigureDumpFile** | Native initialization queries **D3D12DDI_CAPS_TYPE_DUMP_FILE** under architecture, DDI and feature gates. Restrict effective `DumpFileDriverTier` and `DumpFileDriverOptionsMask` in the dump manager before configuration. **GetDumpFileFeatureData** reports manager state. Leave `SupportedByOS` unchanged |
| **D3D12_FEATURE_DATA_USER_DEFINED_ANNOTATION** | **LLOCompleteLayerConstruction**, **IsUserDefinedAnnotationsFeatureVersionOrLater** | Native support requires DDI 0122 and the annotation feature version. Restrict cached `m_UserDefinedAnnotationSupport.Supported` used by validation and reporting |
| **D3D12_FEATURE_DATA_DEBUG_BREAK** | **LLOCompleteLayerConstruction** | Native initialization queries **D3D12DDICAPS_TYPE_DEBUG_BREAK** at DDI 0122 or later. Restrict `HaltSupported`, `LiveDebuggingSupported` and `CpuSupported` in cached `m_DebugBreakSupport` |

### CacheHeapCaps Mapping

The table shows heap capabilities calculated and cached during device creation.

| API enum (D3D12) | Corresponding Function | Notes |
|---|---|---|
| **D3D12_FEATURE_DATA_EXISTING_HEAPS** | **CacheHeapCaps** | `c_DefaultExistingHeapCaps.Supported` defaults to `false` but `CacheHeapCaps()` forcibly updates `m_ValidationInfo.m_ExistingHeapCaps.Supported` to `true` if DDI >= **30**, so we can modify it right after |
| **D3D12_FEATURE_DATA_D3D12_OPTIONS** | **CacheHeapCaps**, **VersionedGetMemoryArchitectureCaps** | Native texture layout and memory architecture queries contribute to standard swizzle, row major texture support and resource heap tier. Restrict effective heap support used by validation and reporting without changing architecture facts |
