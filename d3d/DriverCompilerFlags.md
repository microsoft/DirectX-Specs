# D3D12 Advanced Shader Delivery Driver Compiler Flags

- [D3D12 Advanced Shader Delivery Driver Compiler Flags](#d3d12-advanced-shader-delivery-driver-compiler-flags)
  - [Overview](#overview)
    - [Open questions](#open-questions)
  - [Design](#design)
    - [Runtime and state object compiler support](#runtime-and-state-object-compiler-support)
      - [Driver compiler flag storage in the SODB](#driver-compiler-flag-storage-in-the-sodb)
      - [Compiler identity filter matching](#compiler-identity-filter-matching)
        - [Family and vendor filter example](#family-and-vendor-filter-example)
      - [Runtime support](#runtime-support)
      - [State object compiler support](#state-object-compiler-support)
    - [Versioning and compatibility of driver compiler flags](#versioning-and-compatibility-of-driver-compiler-flags)
      - [How are compiler flags applied on a PSO/SO level when read from the SODB?](#how-are-compiler-flags-applied-on-a-psoso-level-when-read-from-the-sodb)
    - [Validation and error reporting](#validation-and-error-reporting)
      - [Runtime validation](#runtime-validation)
      - [Driver and compiler plugin validation](#driver-and-compiler-plugin-validation)
      - [Reporting problems](#reporting-problems)
    - [Compiler flags in SODB capture scenarios](#compiler-flags-in-sodb-capture-scenarios)
      - [SODB app programmatic capture](#sodb-app-programmatic-capture)
      - [SODB gameplay capture](#sodb-gameplay-capture)
        - [Note regarding IHV-specific extension API handling](#note-regarding-ihv-specific-extension-api-handling)
    - [SODB merge](#sodb-merge)
  - [API](#api)
    - [D3D12_PIPELINE_STATE_SUBOBJECT_TYPE](#d3d12_pipeline_state_subobject_type)
    - [D3D12_STATE_SUBOBJECT_TYPE](#d3d12_state_subobject_type)
    - [D3D12_PREDEFINED_COMPILER_FLAGS](#d3d12_predefined_compiler_flags)
      - [Note](#note)
    - [D3D12_DRIVER_COMPILER_FLAGS_DESC](#d3d12_driver_compiler_flags_desc)
    - [SetDriverCompilerFlags](#setdrivercompilerflags)
    - [Capability reporting](#capability-reporting)
      - [D3D12_FEATURE_COMPILER_OPTIONS](#d3d12_feature_compiler_options)
      - [D3D12_FEATURE_IHV_COMPILER_FLAGS](#d3d12_feature_ihv_compiler_flags)
      - [How support is determined](#how-support-is-determined)
      - [Behavior when not supported](#behavior-when-not-supported)
      - [Offline compilation](#offline-compilation)
    - [D3DX12 helpers](#d3dx12-helpers)
  - [SODB storage](#sodb-storage)
    - [ID3D12StateObjectDatabase2](#id3d12stateobjectdatabase2)
      - [Method: ID3D12StateObjectDatabase2::StoreDriverCompilerFlagOverride](#method-id3d12stateobjectdatabase2storedrivercompilerflagoverride)
      - [Method: ID3D12StateObjectDatabase2::DeleteDriverCompilerFlagOverride](#method-id3d12stateobjectdatabase2deletedrivercompilerflagoverride)
      - [Method: ID3D12StateObjectDatabase2::FindDriverCompilerFlagOverride](#method-id3d12stateobjectdatabase2finddrivercompilerflagoverride)
      - [Method: ID3D12StateObjectDatabase2::EnumerateDriverCompilerFlagOverrides](#method-id3d12stateobjectdatabase2enumeratedrivercompilerflagoverrides)
    - [D3D12_ADAPTER_FAMILY_COMPILER_FILTER_DESC](#d3d12_adapter_family_compiler_filter_desc)
    - [D3D12_ADAPTER_FAMILY_COMPILER_FILTER_LOOKUP_DESC](#d3d12_adapter_family_compiler_filter_lookup_desc)
    - [D3D12_DRIVER_COMPILER_FLAGS_OVERRIDE_DESC](#d3d12_driver_compiler_flags_override_desc)
    - [D3D12EnumerateDriverCompilerFlagOverrideFunc](#d3d12enumeratedrivercompilerflagoverridefunc)
    - [D3D12DriverCompilerFlagOverrideFunc](#d3d12drivercompilerflagoverridefunc)
  - [DDI](#ddi)
    - [Summary of driver changes](#summary-of-driver-changes)
    - [Runtime user-mode DDI](#runtime-user-mode-ddi)
      - [DDI version](#ddi-version)
      - [D3D12DDI_PREDEFINED_COMPILER_FLAGS](#d3d12ddi_predefined_compiler_flags)
      - [D3D12DDI_DRIVER_COMPILER_FLAGS_DESC_0132](#d3d12ddi_driver_compiler_flags_desc_0132)
      - [DDI pipeline state objects](#ddi-pipeline-state-objects)
      - [DDI state objects](#ddi-state-objects)
      - [Payload rules](#payload-rules)
      - [Reporting supported IHV compiler flags](#reporting-supported-ihv-compiler-flags)
    - [Compiler plugin DDI](#compiler-plugin-ddi)
      - [Compiler plugin DDI version](#compiler-plugin-ddi-version)
      - [D3D12DDIARG_COMPILER_COMPILE_PIPELINE_STATE_0004](#d3d12ddiarg_compiler_compile_pipeline_state_0004)
      - [D3D12DDI_COMPILER_FUNCS_0004](#d3d12ddi_compiler_funcs_0004)
      - [State object compilation](#state-object-compilation)
      - [Compiler plugin that does not support compiler flags](#compiler-plugin-that-does-not-support-compiler-flags)
      - [Reporting supported IHV compiler flags from the compiler plugin](#reporting-supported-ihv-compiler-flags-from-the-compiler-plugin)
    - [IHV action checklist](#ihv-action-checklist)
  - [Conformance testing](#conformance-testing)
  - [Telemetry](#telemetry)
  - [Samples](#samples)
  - [History](#history)

## Overview

Driver compiler flags add a way for developers and game stores to have more knobs for the compilation process. These compiler flags include two types: D3D12 predefined flags and opaque IHV-specific flags.

The compiler flags can be applied in the runtime or when invoking offline compilation to provide consistency between the runtime and offline compiled results. They can be specified for an individual PSO/SO through a `D3D12_DRIVER_COMPILER_FLAGS_DESC` subobject. The SODB also supports database-wide overrides that replace the object's compiler flags when a descriptor is read. Each override is one complete descriptor with an optional compiler identity filter.

The flags used for a specific PSDB are traceable. Each PSDB stores the driver compiler flags in its per-group `metadata` blob as described in the Passing Explicit Cache Values spec.

### Open questions
- As a nice-to-have (not a core requirement), a new DDI could ask the driver to print "help" text describing the available IHV compiler flags. This stops short of argument parsing or validating a known list of arguments in `D3D12StateObjectCompiler.exe`. The IHVs provide the compiler flag details to developers. This approach is helpful to PIX. If the flags remain an opaque blob, PIX relies on the IHV PIX plugin to decode the blob. Is the new help text DDI something that should be included? A proposal for optional `{ name, syntax, description }` flag enumeration through `CheckFeatureSupport`, the driver, and the compiler plugin is in [D3D12_FEATURE_IHV_COMPILER_FLAGS](#d3d12_feature_ihv_compiler_flags).

## Design

### Runtime and state object compiler support

Runtime support includes two ways to set the driver compiler flags:
  - D3D12 device level using [SetDriverCompilerFlags](#setdrivercompilerflags) API
  - PSO/SO level using a [compiler flags subobject](#d3d12_driver_compiler_flags_desc)

For SODB collection, a PSO/SO compiler flags subobject is stored as part of the object definition. Database-wide overrides are stored separately so that flags can also be changed for compilation without rewriting the stored objects.

#### Driver compiler flag storage in the SODB

A [D3D12_DRIVER_COMPILER_FLAGS_DESC](#d3d12_driver_compiler_flags_desc) subobject is stored with its PSO/SO and contributes to the object's content-derived key. Both the predefined flag and the IHV-specific string can be specified in the same subobject. A subobject containing `D3D12_PREDEFINED_COMPILER_FLAG_NONE` and a `NULL` string is valid. For PSOs, this default-valued subobject is omitted on storage and produces the same object key as having no compiler flags subobject. For SOs, the explicit empty subobject is preserved and produces a different object key from having no compiler flags subobject. Objects without compiler flags retain their existing key calculation.

There can be at most one compiler flags subobject per PSO/SO. It applies to the whole object, cannot be associated with exports, and cannot be placed inside a generic or partial program. The predefined value must be a valid combination of `D3D12_PREDEFINED_COMPILER_FLAGS` flags, and a non-`NULL` IHV-specific string must be nonempty.

Database-wide overrides are stored separately from objects. There can be one unfiltered default and multiple filtered overrides. Each override contains a predefined value and an optional IHV-specific string. A filter is required whenever an IHV-specific string is present. Predefined-only and empty descriptors may be filtered or unfiltered. These overrides apply when PSO or SO descriptors are read, without changing stored object keys, group versions, or state object dependency keys.

The SODB stores the exact contents of the IHV-specific compiler flags argument, `IHVCompilerFlagString`. Callers can store compiler flags with a compiler identity filter, either as a database-wide override or as part of an object with a [filtered group binding](StateObjectDatabase.md). A compiler identity filter is required for any database-wide override that specifies `IHVCompilerFlagString`. When reading PSO or SO descriptors, callers specify the compilation target to select the applicable object and compiler flag override.

The storage layout is defined by [SODB schema version 4](StateObjectDatabase.md). The [SODB storage APIs](#sodb-storage) expose flag values and filters rather than internal table keys.

#### Compiler identity filter matching

`D3D12_ADAPTER_FAMILY_COMPILER_FILTER_LOOKUP_DESC` describes one concrete driver compiler identity. A stored `D3D12_ADAPTER_FAMILY_COMPILER_FILTER_DESC` completely matches the lookup identity when all of the following conditions are true:

- The stored `szAdapterFamily` matches the lookup's full `VENDOR_FAMILY` identity or its `VENDOR` component, ignoring case.
- `MinimumABISupportVersion <= ABISupportVersion`.
- `ABISupportVersion <= MaximumABISupportVersion`.
- `MinimumCompilerVersion <= CompilerVersion.Version`.
- `CompilerVersion.Version <= MaximumCompilerVersion`.

All minimum and maximum bounds are inclusive and must be in the range `0` through `INT64_MAX`. A range from `0` through `INT64_MAX` matches every valid lookup value for that version. `UINT64_MAX` is not a valid bound. A vendor-only filter must use the full range in both version dimensions.

Identities have the form `VENDOR` or `VENDOR_FAMILY`. The first underscore separates the nonempty vendor and family names. The family name may contain additional underscores. Matching is not an arbitrary string-prefix comparison. Filter identity is case-insensitive, and stored identities are canonical uppercase.

An adapter-family match takes precedence over a vendor match, which takes precedence over the unfiltered default. These rules select one complete descriptor and apply equally to both flag members. Filters for the same normalized identity cannot have overlapping ABI support version and compiler version ranges. `StoreDriverCompilerFlagOverride` returns `DXGI_ERROR_ALREADY_EXISTS` for such a conflict, even if the supplied descriptor is identical to the stored descriptor. Vendor and family filters may coexist to provide a fallback.

##### Family and vendor filter example

For example, the following database-wide overrides target one adapter family and provide vendor and unfiltered fallbacks:

| `szAdapterFamily` | ABI range | Compiler range | Predefined flag | IHV-specific flags |
| --- | --- | --- | --- | --- |
| `IHVName_FamilyName` | 10-20 | 100-200 | `NONE` | `AdapterFamilyFlags` |
| `IHVName` | 0 through `INT64_MAX` | 0 through `INT64_MAX` | `O3` | `IHVFlags` |
| No filter | Not applicable | Not applicable | `O2` | `NULL` |

The overrides produce the following results:

| Lookup identity | Result |
| --- | --- |
| `IHVName_FamilyName`, ABI 15, compiler 150 | `{ NONE, AdapterFamilyFlags }`, because the family filter completely matches. Neither `O3` nor `O2` is inherited. |
| `IHVName_FamilyName`, ABI 25, compiler 150 | `{ O3, IHVFlags }`, because the family ABI range does not match and the vendor filter matches. |
| `IHVName_OtherFamilyName`, ABI 15, compiler 150 | `{ O3, IHVFlags }`, because only the vendor filter matches. |
| `OtherIHVName_FamilyName`, ABI 15, compiler 150 | `{ O2, NULL }`, because neither identity matches. |

If the family override is instead `{ O1, NULL }`, a matching family receives `O1` without the vendor string. If it is `{ NONE, NULL }`, the matching family receives an explicit empty descriptor that clears both components.

#### Runtime support

Compiler flags can be set globally for all PSOs/SOs created through the [D3D12 device-level](#setdrivercompilerflags) API or set for a specific PSO/SO through a [compiler flags subobject](#d3d12_driver_compiler_flags_desc).

When compiler flags are specified at both the global and PSO/SO levels, only the PSO/SO override applies. This keeps one [compiler flags subobject](#d3d12_driver_compiler_flags_desc) per PSO/SO containing all compiler flags needed for compilation. The PSO/SO override is complete and includes any global behavior the application intends to preserve.

**No new device DDI is added for device-level flags.** The runtime keeps track of the device-level flags and resolves them when each object is created:

- If the object has no compiler flags subobject, the runtime sends the current device-level flags as the object's effective descriptor.
- Device-level flags never change objects that already exist.

So the driver receives at most one effective descriptor per object and doesn't need to know where the flags came from. For a PSO, the descriptor is always present in `DriverCompilerFlags` and holds default values when no flags apply. For a state object, it is passed as a subobject only when flags apply or the application supplied an explicit empty subobject. A driver that doesn't support compiler flags receives none (see [Behavior when not supported](#behavior-when-not-supported) and [Runtime user-mode DDI](#runtime-user-mode-ddi)).

#### State object compiler support
The `D3D12StateObjectCompiler` plugin and EXE support the driver compiler flags. The EXE includes new input arguments:
  - `--ihv-compiler-flags`, this argument accepts a string
  - `--d3d12-compiler-flags`, this argument only accepts the predefined D3D12 compiler flags

When compiler flags are specified both in the SODB and on the `D3D12StateObjectCompiler.exe` command line, the command-line flags take precedence and overwrite the SODB-stored flags for that compilation.

Internally the `D3D12StateObjectCompiler` adds the command line specified compiler flags as a [compiler flags subobject](#d3d12_driver_compiler_flags_desc) for every PSO/SO.

### Versioning and compatibility of driver compiler flags

Versioning and compatibility of IHV-specific compiler flags are owned by the IHV. D3D12 predefined flags are compatible with every driver compiler.

The compiler flags used in compilation must affect the PSO/SO PSDB value keys and the driver compiler flags are stored in the PSDB `metadata` field. This prevents compiled values produced with different compiler flags from being treated as interchangeable.

Drivers and compiler plugins must also follow these rules:

- **Drivers and compiler plugins that derive their own value keys or cache identities** (for example, through `PFND3D12DDI_COMPILER_CACHE_SET_OBJECT_VALUE_KEYS_CB` or the runtime shader cache callbacks) must include the effective flags descriptor: the predefined level and the exact IHV string. Two objects that differ only in their flags must not produce the same value key.
- When the flags, adapter family, ABI version, and compiler version are the same, the runtime driver and the compiler plugin must produce compatible output for the same object, so that a PSDB compiled offline with flags can be used at runtime when the same flags are applied. The existing compatibility checks still apply: application identity and the Application Profile Version must also match, as defined in Compiler Versioning. Compiler flags don't replace any of these checks.
- If the meaning of an IHV-specific flag or of a predefined level changes in a way that affects output, the IHV must update the compiler version (and the ABI version, if compatibility is affected), as described in Compiler Versioning.

Compiler flags stored with an object are part of its identity. Database-wide overrides are not: changing an override changes the returned descriptor without changing the object key.

Overrides can be qualified by compiler target through a [compiler identity filter](#d3d12_adapter_family_compiler_filter_desc). The filter can target a specific `VENDOR_FAMILY` identity or all adapter families of a `VENDOR`. It selects the complete descriptor, including the predefined value. An override containing an IHV-specific string must have a filter.

#### How are compiler flags applied on a PSO/SO level when read from the SODB?
`FindPipelineStateDesc2` and `FindStateObjectDesc2` first select the object, then apply database-wide compiler flag overrides using the supplied lookup identity. Reads by object key and reads by group key apply the same compiler flag rules. Group binding selection and compiler flag override selection are independent.

The reader selects one complete override using family, vendor, then unfiltered default precedence. The selected [D3D12_DRIVER_COMPILER_FLAGS_DESC](#d3d12_driver_compiler_flags_desc) replaces the entire compiler flags subobject in the returned descriptor. It does not merge members from different overrides or retain missing members from the stored subobject.

| Selected override | Effective predefined flag | Effective IHV-specific string |
| --- | --- | --- |
| None | Stored value | Stored value |
| `{ O2, NULL }` | `O2` | `NULL` |
| `{ NONE, "Flags" }` | `NONE` | `"Flags"` |
| `{ O2, "Flags" }` | `O2` | `"Flags"` |
| `{ NONE, NULL }` | `NONE` | `NULL` |

When no override applies, the stored compiler flags subobject is preserved, including an explicit empty SO subobject. Default-valued PSO compiler flags subobjects are omitted on storage. If an override applies to an object that has no compiler flags subobject, the reader adds one to the returned descriptor. An explicit `{ NONE, NULL }` override clears both members and suppresses lower-precedence overrides as well as the object's stored flags. Empty overrides remain distinct from absence for both PSOs and SOs.

A `NULL` lookup selects only the unfiltered default. The inherited find methods have no lookup argument and therefore do not select filtered overrides. `NO_GROUPS` suppresses group metadata, not compiler flag overrides. `NO_DESERIALIZE` does not reconstruct a descriptor or add a compiler flags subobject.

### Validation and error reporting

#### Runtime validation

Before calling the driver or compiler plugin, the runtime and the State Object Compiler validate only the structure of the descriptor:

- `D3D12PredefinedCompilerFlag` is a valid combination of `D3D12_PREDEFINED_COMPILER_FLAGS` flags.
- `IHVCompilerFlagString` is either `NULL` or a nonempty, null-terminated string.
- There is at most one compiler flags subobject per object, and its placement follows the [state object rules](#ddi-state-objects).

When this validation fails, object creation fails with `E_INVALIDARG` and the debug layer reports an error. The driver isn't called.

#### Driver and compiler plugin validation

Only the driver and its compiler plugin know what the contents of `IHVCompilerFlagString` mean. Drivers and plugins must:

- Parse the string defensively. Malformed, unknown, duplicated, or contradictory flags, unexpected characters, and very long strings must never cause a crash, hang, memory corruption, or device removal.
- Parse and apply flags the same way in the runtime driver and the compiler plugin.
- Treat flags as compilation controls only. Flags must not enable unsafe behavior or bypass driver security or robustness checks.

What happens after a flag isn't recognized or is invalid is a policy decision. **Proposed:**

- **Unrecognized or invalid IHV-specific flags:** the driver *ignores* the flags it doesn't understand, reports a warning, and continues compiling with the flags it does understand. Object creation succeeds.
- **Flags that are valid but can't be honored for this object** (for example, a flag that doesn't apply to a shader stage): the driver ignores the flag and may report an informational message.

The proposed "warn and proceed" behavior is meant to ensure that a stale or wrong flag string, for example one captured on an older driver or authored for another adapter family, never causes a content-breaking failure. IHVs that need a "fail on invalid flags" mode can provide it as an IHV-specific flag that the developer opts in to.

#### Reporting problems

In the runtime, drivers report flag problems through `pfnReportMessageCb`, as defined in [Driver Reported Messages](D3D12DriverReportedMessages.md):

- Use `D3D12DDI_MESSAGE_CATEGORY_0126_STATE_CREATION` (or `D3D12DDI_MESSAGE_CATEGORY_0126_COMPILATION`) for flag-parsing messages.
- Use `WARNING` severity for ignored or invalid flags and `INFO` severity for flags that don't apply to the object.
- Use a stable `VendorMessageId` for each message class, and set `CommandListStateIndex` to `0xFFFFFFFF`.
- Include the specific flag that caused the problem in `pDescription`, so that developers can correct it.
- Call `pfnReportMessageCb` only when the driver-reported messages feature is enabled on the device. When it isn't, the driver still applies the same policy but doesn't report anything.

In the compiler plugin, compile functions return an `HRESULT`. The plugin DDI doesn't currently define a message callback for warnings. Microsoft is evaluating a matching plugin message callback, so that the plugin can surface warnings during offline compilation.

### Compiler flags in SODB capture scenarios

An SODB is generated in one of two ways, and driver compiler flags reach the database differently in each. Driver compiler flags enter an SODB either through the [SODB storage](#sodb-storage) API during programmatic generation or by capturing flags set through the [device-level API](#setdrivercompilerflags) or PSO/SO subobject during gameplay capture.

#### SODB app programmatic capture

The SODB is generated directly by the application or its build tooling. This is the preferred path. The ISV authors a compiler flags subobject in each relevant PSO/SO definition, or adds database-wide overrides through the [SODB storage](#sodb-storage) API. Because the flags are added deliberately rather than inferred from a running driver, this path supports:

- Per-object compiler flags containing a predefined value, an IHV-specific string, or both.
- A database-wide unfiltered default with a predefined value and a `NULL` string, including an explicit empty descriptor.
- Database-wide complete overrides qualified by a `D3D12_ADAPTER_FAMILY_COMPILER_FILTER_DESC` for a single adapter family or an entire IHV. They can contain predefined flags, IHV-specific flags, both, or neither. Family filters can constrain ABI and compiler versions. This includes adapter families and IHVs that are not the hardware performing the capture.

As a result, a programmatically generated SODB can carry a complete, multi-IHV set of compiler flags even though none of them were exercised on the capturing machine.

#### SODB gameplay capture

The SODB is captured by recording a representative game playthrough: the runtime records the PSOs and SOs created by the D3D12 API during gameplay. Any driver compiler flags the application sets at runtime during that session, whether through the [device-level API](#setdrivercompilerflags) or a PSO/SO subobject, are used for the in-process compilation on the capturing adapter. Capture records the effective compiler flags as a single subobject in the object definition. Both members are retained when both flag types apply.

IHV-specific flags recorded from a live session describe a single driver compiler target. Target-specific object definitions can use a filtered group binding whose adapter family is reported by the capturing driver and whose minimum and maximum version bounds are set to the concrete versions reported by that driver. This binding selects the object; it is not a compiler flag override.

##### Note regarding IHV-specific extension API handling
If the game uses any IHV-specific extension APIs in a gameplay capture scenario, any compiler flags added using those APIs are not captured. To include those in the SODB, the flags need to be added to the SODB using the [SODB storage](#sodb-storage) API. ISVs need to communicate with the IHV to understand how to capture the effect of the extension APIs on SODB compilation.

### SODB merge
SODBs are not always captured in one operation; they might be captured across multiple processes and then merged together. When SODBs have no conflicts, merges are additive. Compiler flags merge with their object definitions. Database-wide overrides need separate conflict handling when both databases specify an unfiltered default, overrides for the same filter, or overlapping filters for the same normalized identity. A merge can be performed using the `D3D12StateObjectDatabase.exe` command line tool, and the override conflict resolution policy is defined below.
The command line accepts multiple input SODBs and one destination SODB. The input SODBs are processed one at a time, from left to right, into the destination:
```text
 D3D12StateObjectDatabase.exe merge-sodb <input1> <input2> ... <destination>
```

For identical filters, the following options choose the members of one replacement descriptor, which is stored as a complete override. They do not create independent override components. For overlapping but different filters, the policies must agree on keeping or overwriting the complete override; `append` is invalid.

 When a conflict in the IHV compiler flag strings is encountered, `--merge-ihv-compiler-flags-resolution` selects how it is resolved:
  - `keep` (default) keep the options already in the destination SODB
  - `overwrite` overwrite with the options from the incoming SODB
  - `append` append the conflicting compiler flag strings in the merged SODB when the conflicting overrides use the same normalized filter. The merge fails with `E_INVALIDARG` when `append` is selected for overlapping filters that use different normalized filters. This is a merge-tool policy, not string concatenation during SODB reads.

When a conflict in the D3D12 predefined compiler flag values is encountered, `--merge-d3d12-compiler-flags-resolution` selects how it is resolved:
  - `keep` (default) keep the options already in the destination SODB
  - `overwrite` overwrite with the options from the incoming SODB

## API
The API supports setting driver compiler flags at:
  - the D3D12 device level using the [SetDriverCompilerFlags](#setdrivercompilerflags) API
  - the PSO/SO level using a [compiler flags subobject](#d3d12_driver_compiler_flags_desc)

### D3D12_PIPELINE_STATE_SUBOBJECT_TYPE
```cpp
typedef enum D3D12_PIPELINE_STATE_SUBOBJECT_TYPE {
  ....
  D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_DRIVER_COMPILER_FLAGS = 31, // D3D12_DRIVER_COMPILER_FLAGS_DESC
} D3D12_PIPELINE_STATE_SUBOBJECT_TYPE;
```

Value | Definition
--- | ---
`D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_DRIVER_COMPILER_FLAGS` | Driver compiler flags subobject in a pipeline state stream. The associated data is a [D3D12_DRIVER_COMPILER_FLAGS_DESC](#d3d12_driver_compiler_flags_desc).

### D3D12_STATE_SUBOBJECT_TYPE
```cpp
typedef enum D3D12_STATE_SUBOBJECT_TYPE {
  ....
  D3D12_STATE_SUBOBJECT_TYPE_DRIVER_COMPILER_FLAGS = 44, // D3D12_DRIVER_COMPILER_FLAGS_DESC
} D3D12_STATE_SUBOBJECT_TYPE;
```

Value | Definition
--- | ---
`D3D12_STATE_SUBOBJECT_TYPE_DRIVER_COMPILER_FLAGS` | Driver compiler flags subobject in a state object. The associated data is a [D3D12_DRIVER_COMPILER_FLAGS_DESC](#d3d12_driver_compiler_flags_desc).

### D3D12_PREDEFINED_COMPILER_FLAGS

```cpp
typedef enum D3D12_PREDEFINED_COMPILER_FLAGS{
  D3D12_PREDEFINED_COMPILER_FLAG_NONE = 0,
  D3D12_PREDEFINED_COMPILER_FLAG_O1 = 1,
  D3D12_PREDEFINED_COMPILER_FLAG_O2 = 2,
  D3D12_PREDEFINED_COMPILER_FLAG_O3 = 3
} D3D12_PREDEFINED_COMPILER_FLAGS;
```

Value                                 | Definition
---------                             | ----------
`D3D12_PREDEFINED_COMPILER_FLAG_NONE` | No predefined optimization level specified. The driver compiler applies its default behavior.
`D3D12_PREDEFINED_COMPILER_FLAG_O1`   | Basic optimizations with minimal impact on compile time.
`D3D12_PREDEFINED_COMPILER_FLAG_O2`   | Full optimizations that balance runtime performance against code size and compile time. This is the optimization level that traditional runtime shader compilation targets, and the recommended choice for most shipping shaders.
`D3D12_PREDEFINED_COMPILER_FLAG_O3`   | Aggressive optimizations that favor runtime performance and may increase compile time and code size.

The currently defined optimization levels (`D3D12_PREDEFINED_COMPILER_FLAG_O1`, `D3D12_PREDEFINED_COMPILER_FLAG_O2`, and `D3D12_PREDEFINED_COMPILER_FLAG_O3`) are mutually exclusive and must not be combined.

#### Note
---------------
`D3D12_PREDEFINED_COMPILER_FLAG_NONE` specifies that no predefined optimization level applies. It is valid in a compiler flags subobject or a database-wide override, with or without an IHV-specific string. An override containing `NONE` and a `NULL` string is an explicit empty descriptor.

### D3D12_DRIVER_COMPILER_FLAGS_DESC

```cpp
typedef struct D3D12_DRIVER_COMPILER_FLAGS_DESC {
  D3D12_PREDEFINED_COMPILER_FLAGS D3D12PredefinedCompilerFlag;
  LPCWSTR IHVCompilerFlagString;
} D3D12_DRIVER_COMPILER_FLAGS_DESC;
```

Parameter                                              | Definition
---------                                              | ----------
`D3D12_PREDEFINED_COMPILER_FLAGS D3D12PredefinedCompilerFlag`  | The D3D12 predefined compiler flags passed through to the driver compiler. Must be a valid combination of `D3D12_PREDEFINED_COMPILER_FLAGS` flags.
`LPCWSTR IHVCompilerFlagString`                           | A null-terminated, nonempty, comma-delimited IHV compiler flag string passed through to the driver compiler for the object. Set to `NULL` when no IHV-specific compiler flags apply. An empty string is invalid.

PSO/SO subobjects and database-wide overrides can specify both members together. The override store and delete APIs operate on the complete descriptor and optional filter in one call. An override with an IHV-specific string requires a filter; predefined-only and empty overrides may also have a filter. `FindDriverCompilerFlagOverride` selects one complete override without looking up an object.

### SetDriverCompilerFlags
A D3D12 device API that sets the current hardware adapter compiler flags.

```cpp
HRESULT SetDriverCompilerFlags(
  const D3D12_DRIVER_COMPILER_FLAGS_DESC* pDriverCompilerFlagsDesc);
```

Parameter | Definition
--- | ---
`const D3D12_DRIVER_COMPILER_FLAGS_DESC* pDriverCompilerFlagsDesc` | The compiler flags to apply to the current hardware adapter for subsequently created PSOs/SOs. See [D3D12_DRIVER_COMPILER_FLAGS_DESC](#d3d12_driver_compiler_flags_desc).

### Capability reporting

Applications need to know whether the runtime and driver honor compiler flags before they rely on them. **Proposed:** a new [CheckFeatureSupport](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12device-checkfeaturesupport) feature, `D3D12_FEATURE_COMPILER_OPTIONS`, reports this support.

#### D3D12_FEATURE_COMPILER_OPTIONS

```cpp
typedef enum D3D12_FEATURE
{
    ...
    D3D12_FEATURE_COMPILER_OPTIONS, // D3D12_FEATURE_DATA_COMPILER_OPTIONS
} D3D12_FEATURE;

typedef struct D3D12_FEATURE_DATA_COMPILER_OPTIONS
{
    _Out_ BOOL DriverCompilerFlagsSupported;
    _Out_ UINT NumIHVCompilerFlags;
} D3D12_FEATURE_DATA_COMPILER_OPTIONS;
```

An application passes a `D3D12_FEATURE_DATA_COMPILER_OPTIONS` structure as `pFeatureSupportData` when it queries `D3D12_FEATURE_COMPILER_OPTIONS`.

Member | Description
--- | ---
`DriverCompilerFlagsSupported` | `TRUE` when the runtime passes driver compiler flags to the driver for both PSOs and state objects. This covers the pipeline state stream subobject, the state object subobject, and the device-level `SetDriverCompilerFlags` API. Otherwise `FALSE`.
`NumIHVCompilerFlags` | The number of IHV-specific compiler flags that the driver describes, which can be enumerated through [D3D12_FEATURE_IHV_COMPILER_FLAGS](#d3d12_feature_ihv_compiler_flags). The value is `0` when `DriverCompilerFlagsSupported` is `FALSE` or when the driver doesn't describe its flags. A value of `0` doesn't mean the driver accepts no IHV-specific flags.

The feature is called "compiler options" rather than something specific to driver compiler flags so that future compiler-related capabilities can be added to it. Following the usual D3D12 pattern, those capabilities would be added in new versioned structures (`D3D12_FEATURE_COMPILER_OPTIONS1` and so on) rather than by changing this structure.

#### D3D12_FEATURE_IHV_COMPILER_FLAGS

**Proposed:** applications and tools can enumerate the IHV-specific compiler flags that the driver describes. Each flag is described by a simple set of strings: name, syntax, and description. The list is informational only. It helps developers write `IHVCompilerFlagString` values, and it isn't structured enough for validation.

```cpp
typedef enum D3D12_FEATURE
{
    ...
    D3D12_FEATURE_IHV_COMPILER_FLAGS, // D3D12_FEATURE_DATA_IHV_COMPILER_FLAGS
} D3D12_FEATURE;

typedef struct D3D12_IHV_COMPILER_FLAG_DESC
{
    LPCWSTR Name;
    LPCWSTR Syntax;
    LPCWSTR Description;
} D3D12_IHV_COMPILER_FLAG_DESC;

typedef struct D3D12_FEATURE_DATA_IHV_COMPILER_FLAGS
{
    _In_ UINT NumFlags;
    _Out_writes_(NumFlags) D3D12_IHV_COMPILER_FLAG_DESC* pFlags;
} D3D12_FEATURE_DATA_IHV_COMPILER_FLAGS;
```

Member | Description
--- | ---
`NumFlags` | The number of entries in `pFlags`. Must equal `NumIHVCompilerFlags` from [D3D12_FEATURE_COMPILER_OPTIONS](#d3d12_feature_compiler_options).
`pFlags` | An application-allocated array that receives one `D3D12_IHV_COMPILER_FLAG_DESC` for each flag. `Name` is always non-`NULL`. `Syntax` and `Description` can be `NULL`.

Usage follows the usual two-call pattern:

1. Query `D3D12_FEATURE_COMPILER_OPTIONS` to get `NumIHVCompilerFlags`.
2. Allocate an array of that size and query `D3D12_FEATURE_IHV_COMPILER_FLAGS`.

`CheckFeatureSupport` returns `E_INVALIDARG` when `NumFlags` doesn't equal `NumIHVCompilerFlags`, or when `pFlags` is `NULL` and `NumFlags` is not `0`. The strings are owned by the device and stay valid until it is destroyed. The runtime never validates `IHVCompilerFlagString` against this list, and drivers keep accepting flags they don't list.

#### How support is determined

- **The runtime derives the capability.** `DriverCompilerFlagsSupported` is `TRUE` only when both of these are true:
  - the driver negotiates runtime DDI 0132 or later;
  - the feature is enabled on the device. While the feature is in preview, that means the Experimental feature gate.
- **No new driver capability query for support.** A driver that implements DDI 0132 is expected to accept and apply the compiler flags payload for both PSOs and state objects, so its support follows from the DDI version it negotiates. The only new driver caps are the optional ones for [describing supported IHV flags](#reporting-supported-ihv-compiler-flags).
- **Hardware independence.** The result doesn't depend on the adapter family or the compiler version. Which IHV-specific flags a driver understands is defined by the IHV. A driver can optionally describe them through [D3D12_FEATURE_IHV_COMPILER_FLAGS](#d3d12_feature_ihv_compiler_flags).
- **Return values.**
  - On a runtime that recognizes the feature, `CheckFeatureSupport` returns `S_OK` and fills in the structure, including when support is `FALSE`.
  - On an older runtime that doesn't recognize `D3D12_FEATURE_COMPILER_OPTIONS`, `CheckFeatureSupport` returns `E_INVALIDARG`. Applications must treat that as "not supported".

#### Behavior when not supported

When `DriverCompilerFlagsSupported` is `FALSE`, the runtime doesn't send compiler flags to the driver. That applies to the `DriverCompilerFlags` member and to the state object subobject. **Proposed:** the runtime drops the flags and reports a debug-layer warning, and object creation continues without them. This matches the [compiler plugin policy](#compiler-plugin-that-does-not-support-compiler-flags). Objects created this way are compiled without compiler flags, and they are identified that way for caching.

#### Offline compilation

`CheckFeatureSupport` describes only the runtime device. The State Object Compiler determines offline support from the compiler plugin DDI version that it negotiates with the plugin. Revision 4 or later supports compiler flags (see [Compiler plugin DDI version](#compiler-plugin-ddi-version)). A runtime device and an offline compiler plugin from the same IHV can therefore report different levels of support, for example when the installed driver is older than the compiler plugin.

### D3DX12 helpers

The public D3DX12 helpers (DirectX-Headers and the Agility SDK) gain support for the new subobjects behind a preview define.

- `CD3DX12_PIPELINE_STATE_STREAM_DRIVER_COMPILER_FLAGS`: pipeline state stream subobject that wraps `D3D12_DRIVER_COMPILER_FLAGS_DESC`.
- `CD3DX12_PIPELINE_STATE_STREAM8` and `CD3DX12_PIPELINE_STATE_STREAM8_PARSE_HELPER`: a stream and parse helper that include the compiler flags subobject. The parser recognizes `D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_DRIVER_COMPILER_FLAGS`.
- `CD3DX12_DRIVER_COMPILER_FLAGS_SUBOBJECT`: state object subobject helper that holds its own copy of the IHV string.

## SODB storage

### ID3D12StateObjectDatabase2
Compiler flags are stored with objects through the normal PSO/SO store methods as part of the supplied descriptor. Database-wide overrides are managed through the following methods on `ID3D12StateObjectDatabase2`. They do not take a group key. The complete interface, including filtered group operations, is documented in the [State Object Database specification](StateObjectDatabase.md).

```cpp
interface ID3D12StateObjectDatabase2
    : ID3D12StateObjectDatabase1
{
  HRESULT StoreDriverCompilerFlagOverride(
    [annotation("_In_")] const D3D12_DRIVER_COMPILER_FLAGS_DESC* pDriverCompilerFlagsDesc,
    [annotation("_In_opt_")] const D3D12_ADAPTER_FAMILY_COMPILER_FILTER_DESC* pFilterDesc);

  HRESULT DeleteDriverCompilerFlagOverride(
    [annotation("_In_")] const D3D12_DRIVER_COMPILER_FLAGS_DESC* pDriverCompilerFlagsDesc,
    [annotation("_In_opt_")] const D3D12_ADAPTER_FAMILY_COMPILER_FILTER_DESC* pFilterDesc);

  HRESULT FindDriverCompilerFlagOverride(
    [annotation("_In_opt_")] const D3D12_ADAPTER_FAMILY_COMPILER_FILTER_LOOKUP_DESC* pLookupDesc,
    [annotation("_In_")] D3D12DriverCompilerFlagOverrideFunc CallbackFunc,
    [annotation("_Inout_opt_")] void* pContext);

  HRESULT EnumerateDriverCompilerFlagOverrides(
    [annotation("_In_")] D3D12EnumerateDriverCompilerFlagOverrideFunc CallbackFunc,
    [annotation("_Inout_opt_")] void* pContext);
};
```

Override mutations are atomic. To replace an existing override, enumerate it, delete its exact stored value and filter, then store the replacement. These operations can be enclosed in a database transaction. An overlapping filter alone is not an exact deletion match. Shared filters remain available while referenced by other overrides or group bindings.

#### Method: ID3D12StateObjectDatabase2::StoreDriverCompilerFlagOverride

Stores one complete database-wide override. Both descriptor members can be populated. A filter is required whenever an IHV-specific string is present; predefined-only and empty descriptors may be filtered or unfiltered.

Parameter | Definition
--- | ---
`const D3D12_DRIVER_COMPILER_FLAGS_DESC* pDriverCompilerFlagsDesc` | The complete override to store. The predefined value may be any defined enum value, including `NONE`, and the optional string must be nonempty. Cannot be `NULL`. See [D3D12_DRIVER_COMPILER_FLAGS_DESC](#d3d12_driver_compiler_flags_desc).
`const D3D12_ADAPTER_FAMILY_COMPILER_FILTER_DESC* pFilterDesc` | The compiler target for the complete descriptor, or `NULL` for the unfiltered default. Required when `IHVCompilerFlagString` is non-`NULL`. The SODB implementation generates the internal filter key from this description. See [D3D12_ADAPTER_FAMILY_COMPILER_FILTER_DESC](#d3d12_adapter_family_compiler_filter_desc).

Filter | Existing override | `D3D12PredefinedCompilerFlag` | `IHVCompilerFlagString` | Result
--- | --- | --- | --- | ---
`NULL` | No default | Defined value, including `NONE` | `NULL` | `S_OK`
`NULL` | Default present | Defined value, including `NONE` | `NULL` | `DXGI_ERROR_ALREADY_EXISTS`
Valid filter | No conflicting filter | Defined value, including `NONE` | `NULL` or nonempty string | `S_OK`
Valid filter | Same filter, or same normalized identity with overlapping ABI and compiler ranges | Defined value, including `NONE` | `NULL` or nonempty string | `DXGI_ERROR_ALREADY_EXISTS`
`NULL` | Any | Defined value, including `NONE` | Nonempty string | `E_INVALIDARG`

The method returns `DXGI_ERROR_ALREADY_EXISTS` for an existing unfiltered default or a conflicting filter, regardless of which members are populated and even when the stored descriptor is identical. The same descriptor can be stored under multiple nonconflicting filters. The existing override remains unchanged. It returns `DXGI_ERROR_ACCESS_DENIED` when the database is read-only.

An explicit empty override is stored when `D3D12PredefinedCompilerFlag` is `NONE` and `IHVCompilerFlagString` is `NULL`, with or without a filter. It does not delete an override and is distinct from the absence of an override.

The method returns `E_INVALIDARG` when:

- `pDriverCompilerFlagsDesc` is `NULL`.
- `D3D12PredefinedCompilerFlag` is not a defined enum value.
- `IHVCompilerFlagString` is empty.
- The filter identity is empty, unterminated, or does not have the form `VENDOR` or `VENDOR_FAMILY`.
- A minimum version bound is greater than its corresponding maximum.
- Any version bound exceeds `INT64_MAX`.
- A vendor-only filter does not use `0` through `INT64_MAX` in both version dimensions.
- `IHVCompilerFlagString` is non-`NULL` and `pFilterDesc` is `NULL`.

#### Method: ID3D12StateObjectDatabase2::DeleteDriverCompilerFlagOverride

Deletes the complete override identified by both descriptor members and the optional filter description. The predefined value, presence and exact contents of the string, normalized filter identity, and exact bounds must all match. A mismatched member does not delete any part of the override.

Deleting an override exposes the object's stored compiler flags again when no remaining override applies. It never removes or rewrites those flags.

Parameter | Definition
--- | ---
`const D3D12_DRIVER_COMPILER_FLAGS_DESC* pDriverCompilerFlagsDesc` | The exact complete descriptor to delete, using the same flag rules as the store method. Cannot be `NULL`. See [D3D12_DRIVER_COMPILER_FLAGS_DESC](#d3d12_driver_compiler_flags_desc).
`const D3D12_ADAPTER_FAMILY_COMPILER_FILTER_DESC* pFilterDesc` | The exact stored filter, or `NULL` for the default. Required when `IHVCompilerFlagString` is non-`NULL`. See [D3D12_ADAPTER_FAMILY_COMPILER_FILTER_DESC](#d3d12_adapter_family_compiler_filter_desc).

The method returns `S_OK` when the exact override is deleted, `DXGI_ERROR_NOT_FOUND` when no override matches, or `DXGI_ERROR_ACCESS_DENIED` when the database is read-only. Overlap matching is not used for deletion. Invalid descriptors, a string without a filter, unterminated or empty filter identities, reversed ranges, and bounds above `INT64_MAX` return `E_INVALIDARG`.

#### Method: ID3D12StateObjectDatabase2::FindDriverCompilerFlagOverride

Selects one complete database-wide override for an optional concrete compiler identity without looking up a group or object. A matching family overrides a matching vendor, which overrides the unfiltered default, according to the [compiler identity filter matching](#compiler-identity-filter-matching) rules. Members from different rows are never combined.

A `NULL` `pLookupDesc` selects only the unfiltered default. If an override applies, including an explicit `{ NONE, NULL }`, the method returns `S_OK` and invokes the callback exactly once. If no override applies, it returns `DXGI_ERROR_NOT_FOUND` without invoking the callback.

Parameter | Definition
--- | ---
`const D3D12_ADAPTER_FAMILY_COMPILER_FILTER_LOOKUP_DESC* pLookupDesc` | The concrete driver compiler identity used to select a matching complete override, or `NULL` to consider only the unfiltered default. See [D3D12_ADAPTER_FAMILY_COMPILER_FILTER_LOOKUP_DESC](#d3d12_adapter_family_compiler_filter_lookup_desc).
`D3D12DriverCompilerFlagOverrideFunc CallbackFunc` | The required callback invoked with the selected complete descriptor. See [D3D12DriverCompilerFlagOverrideFunc](#d3d12drivercompilerflagoverridefunc).
`void* pContext` | An application context pointer passed through to `CallbackFunc`.

The method returns `E_INVALIDARG` when the callback is `NULL`, or when a supplied lookup has an empty, unterminated, or malformed identity, an `ABISupportVersion` above `INT64_MAX`, or a compiler version whose most-significant 16-bit component exceeds `INT16_MAX`. Valid reads do not modify or upgrade older database schemas.

#### Method: ID3D12StateObjectDatabase2::EnumerateDriverCompilerFlagOverrides

Enumerates all stored complete database-wide overrides, including the unfiltered default when present and every filtered override. This includes predefined-only, combined, IHV-only, and empty descriptors. This is a storage enumeration, not a lookup for a particular compiler identity, and does not enumerate compiler flags subobjects stored with objects.

The callback is invoked once per override until it returns `FALSE`. Order is unspecified. The method returns `S_OK` without invoking the callback when no overrides are stored, and returns `E_INVALIDARG` for a `NULL` callback.

Parameter | Definition
--- | ---
`D3D12EnumerateDriverCompilerFlagOverrideFunc CallbackFunc` | The required callback invoked once for each override. See [D3D12EnumerateDriverCompilerFlagOverrideFunc](#d3d12enumeratedrivercompilerflagoverridefunc).
`void* pContext` | An application context pointer passed through to `CallbackFunc`.

### D3D12_ADAPTER_FAMILY_COMPILER_FILTER_DESC

```cpp
typedef struct D3D12_ADAPTER_FAMILY_COMPILER_FILTER_DESC {
  WCHAR szAdapterFamily[128];
  UINT64 MinimumABISupportVersion;
  UINT64 MaximumABISupportVersion;
  UINT64 MinimumCompilerVersion;
  UINT64 MaximumCompilerVersion;
} D3D12_ADAPTER_FAMILY_COMPILER_FILTER_DESC;
```

Parameter | Definition
--- | ---
`WCHAR szAdapterFamily[128]` | A nonempty, null-terminated `VENDOR` or `VENDOR_FAMILY` identity. The first underscore separates the nonempty vendor and family names. The family name may contain additional underscores. Matching is case-insensitive. A vendor-only filter targets every family of that vendor and must use the full version ranges.
`UINT64 MinimumABISupportVersion` | The lowest driver compiler ABI version the flags apply to. Set to `0` to leave the lower bound unconstrained for the adapter family. Cannot exceed `INT64_MAX`.
`UINT64 MaximumABISupportVersion` | The highest driver compiler ABI version the flags apply to. Set to `INT64_MAX` to include every supported version at or above the minimum. Cannot exceed `INT64_MAX` or be less than the minimum.
`UINT64 MinimumCompilerVersion` | The lowest driver compiler version the flags apply to. Set to `0` to leave the lower bound unconstrained for the adapter family. Cannot exceed `INT64_MAX`.
`UINT64 MaximumCompilerVersion` | The highest encoded driver compiler version the flags apply to. Set to `INT64_MAX` to include every supported version at or above the minimum. Cannot exceed `INT64_MAX` or be less than the minimum.

### D3D12_ADAPTER_FAMILY_COMPILER_FILTER_LOOKUP_DESC

Describes one concrete driver compiler identity used to find matching compiler identity filters.

```cpp
typedef struct D3D12_ADAPTER_FAMILY_COMPILER_FILTER_LOOKUP_DESC {
  WCHAR szAdapterFamily[128];
  UINT64 ABISupportVersion;
  D3D12_VERSION_NUMBER CompilerVersion;
} D3D12_ADAPTER_FAMILY_COMPILER_FILTER_LOOKUP_DESC;
```

Parameter | Definition
--- | ---
`WCHAR szAdapterFamily[128]` | The nonempty, null-terminated driver compiler identity, in the same `VENDOR` or `VENDOR_FAMILY` form as the filter. Matching is case-insensitive.
`UINT64 ABISupportVersion` | The concrete driver compiler ABI version matched against the stored minimum and maximum ABI support version bounds. Cannot exceed `INT64_MAX`.
`D3D12_VERSION_NUMBER CompilerVersion` | The concrete driver compiler version. Its `Version` member is compared with the stored compiler version bounds. Its most-significant 16-bit component cannot exceed `INT16_MAX`.

### D3D12_DRIVER_COMPILER_FLAGS_OVERRIDE_DESC

Describes one database-wide driver compiler flag override stored in the SODB.

```cpp
typedef struct D3D12_DRIVER_COMPILER_FLAGS_OVERRIDE_DESC {
  D3D12_DRIVER_COMPILER_FLAGS_DESC DriverCompilerFlags;
  const D3D12_ADAPTER_FAMILY_COMPILER_FILTER_DESC* pFilterDesc;
} D3D12_DRIVER_COMPILER_FLAGS_OVERRIDE_DESC;
```

Parameter | Definition
--- | ---
`D3D12_DRIVER_COMPILER_FLAGS_DESC DriverCompilerFlags` | The stored complete descriptor. The predefined value is a defined enum value, including `NONE`. The optional string is nonempty. `{ NONE, NULL }` is an explicit empty override.
`const D3D12_ADAPTER_FAMILY_COMPILER_FILTER_DESC* pFilterDesc` | The compiler target of the complete descriptor, or `NULL` for the unfiltered default. Required when the descriptor contains an IHV-specific string.

### D3D12EnumerateDriverCompilerFlagOverrideFunc

A callback invoked once for each stored override by `ID3D12StateObjectDatabase2::EnumerateDriverCompilerFlagOverrides`.

```idl
typedef BOOL(__stdcall* D3D12EnumerateDriverCompilerFlagOverrideFunc) (
    [annotation("_In_")] const D3D12_DRIVER_COMPILER_FLAGS_OVERRIDE_DESC* pOverrideDesc,
    [annotation("_Inout_opt_")] void* pContext
    );
```

Parameter | Definition
--- | ---
`const D3D12_DRIVER_COMPILER_FLAGS_OVERRIDE_DESC* pOverrideDesc` | The stored override. The descriptor, filter, and string are valid only for the duration of the callback, including if the callback modifies the database.
`void* pContext` | The application context pointer passed to the enumeration method.

Return `TRUE` to continue enumeration or `FALSE` to stop.

### D3D12DriverCompilerFlagOverrideFunc
A callback that receives the complete database-wide override selected by `ID3D12StateObjectDatabase2::FindDriverCompilerFlagOverride`. The descriptor and string are valid only for the duration of the callback, including if the callback modifies the database.

```idl
typedef void(__stdcall* D3D12DriverCompilerFlagOverrideFunc) (
    [annotation("_In_")] const D3D12_DRIVER_COMPILER_FLAGS_DESC* pDriverCompilerFlagsDesc,
    [annotation("_Inout_opt_")] void* pContext
    );
```

Parameter | Definition
--- | ---
`const D3D12_DRIVER_COMPILER_FLAGS_DESC* pDriverCompilerFlagsDesc` | The selected complete override, not compiler flags stored with an object. Both members are returned unchanged; neither is inherited from another override. An explicit `{ NONE, NULL }` override still causes the callback to be invoked. See [D3D12_DRIVER_COMPILER_FLAGS_DESC](#d3d12_driver_compiler_flags_desc).
`void* pContext` | The application context pointer passed to the calling method.

To record overrides for multiple IHVs, including IHVs that are not the currently running hardware, an ISV calls `StoreDriverCompilerFlagOverride` with a complete descriptor and filter for each applicable target. For example, vendor-only filters can specify `L"IHVName"` and `L"OtherIHVName"`, with both version ranges set to `0` through `INT64_MAX`. Each descriptor includes any predefined behavior needed for that target. An optional unfiltered default is stored with a `NULL` string and `pFilterDesc`. These overrides apply database-wide; there is no group-specific compiler flag override API.


## DDI

This section describes the driver-facing changes for driver compiler flags in the D3D12 user-mode driver DDI and the State Object Compiler plugin DDI.

### Summary of driver changes

| Area | Change | IHV action |
| --- | --- | --- |
| Runtime UMD DDI | A new DDI build version adds a driver compiler flags payload to pipeline state creation and a new state object subobject type. | Implement the new revision of the pipeline state creation functions and accept the new state object subobject. |
| Compiler plugin DDI | A new compiler plugin DDI revision, tied to the new runtime DDI version, adds the same payload to offline pipeline state and state object compilation. | Report the new plugin DDI version, and consume the payload the same way the runtime driver does. |
| Device-level flags | Applications can set default flags for a device. The runtime resolves them, so no new device DDI is required. | No new entry points. The driver receives one effective descriptor per object. |
| Validation and reporting | The runtime validates the structure. The driver interprets the IHV string and reports problems. | Parse the IHV string safely, never crash on bad input, and report problems through `pfnReportMessageCb`. |
| Capability reporting | **Proposed:** a new `D3D12_FEATURE_COMPILER_OPTIONS` `CheckFeatureSupport` feature tells applications whether compiler flags are supported. A second feature, `D3D12_FEATURE_IHV_COMPILER_FLAGS`, lets applications and tools enumerate the IHV-specific flags a driver supports. | None for support, which the runtime derives from the negotiated DDI version. Optionally, report the supported IHV-specific flags through new caps from the driver and the compiler plugin. |
| Caching | Compiler flags take part in cache value identity. | Include the effective flags in any value key or cache identity the driver or plugin derives. |
| D3DX12 | New helpers for the PSO stream and the state object subobject. | None. Useful for driver test code. |
| Conformance | **Proposed:** a new HLK negative test that sends unrecognized flag strings. | Make sure the driver handles unknown or malformed flags robustly. |

### Runtime user-mode DDI

#### DDI version

The payload is introduced in a new D3D12 Release 8 DDI build version. The runtime forwards compiler flags only to drivers that negotiate this version or later.

```cpp
// D3D12 Release 8, Build rev 132.
#define D3D12DDI_BUILD_VERSION_0132 132
#define D3D12DDI_SUPPORTED_0132 ((((UINT64)D3D12DDI_INTERFACE_VERSION_R8) << 32) | (((UINT64)D3D12DDI_BUILD_VERSION_0132) << 16))
```

#### D3D12DDI_PREDEFINED_COMPILER_FLAGS

```cpp
typedef enum D3D12DDI_PREDEFINED_COMPILER_FLAGS
{
    D3D12DDI_PREDEFINED_COMPILER_FLAG_NONE = 0,
    D3D12DDI_PREDEFINED_COMPILER_FLAG_O1 = 1,
    D3D12DDI_PREDEFINED_COMPILER_FLAG_O2 = 2,
    D3D12DDI_PREDEFINED_COMPILER_FLAG_O3 = 3,
} D3D12DDI_PREDEFINED_COMPILER_FLAGS;
```

Value | Definition
--- | ---
`D3D12DDI_PREDEFINED_COMPILER_FLAG_NONE` | No predefined optimization level is specified. The driver compiler uses its default behavior.
`D3D12DDI_PREDEFINED_COMPILER_FLAG_O1` | Basic optimizations with minimal impact on compile time.
`D3D12DDI_PREDEFINED_COMPILER_FLAG_O2` | Full optimizations that balance runtime performance against code size and compile time. This is the level that traditional runtime shader compilation targets, and the recommended choice for most shipping shaders.
`D3D12DDI_PREDEFINED_COMPILER_FLAG_O3` | Aggressive optimizations that favor runtime performance and may increase compile time and code size.

`D3D12PredefinedCompilerFlag` is a valid combination of `D3D12DDI_PREDEFINED_COMPILER_FLAGS` flags. The currently defined optimization levels are mutually exclusive. The runtime rejects invalid combinations before calling the driver. Each IHV maps the predefined levels to its own compiler settings. That mapping should be stable, and if it changes, the change should be reflected in the compiler version (see [Versioning and compatibility of driver compiler flags](#versioning-and-compatibility-of-driver-compiler-flags)).

#### D3D12DDI_DRIVER_COMPILER_FLAGS_DESC_0132

```cpp
typedef struct D3D12DDI_DRIVER_COMPILER_FLAGS_DESC_0132
{
    D3D12DDI_PREDEFINED_COMPILER_FLAGS D3D12PredefinedCompilerFlag;
    LPCWSTR IHVCompilerFlagString;
} D3D12DDI_DRIVER_COMPILER_FLAGS_DESC_0132;
```

Member | Definition
--- | ---
`D3D12PredefinedCompilerFlag` | The D3D12 predefined optimization level to apply. `D3D12DDI_PREDEFINED_COMPILER_FLAG_NONE` means none was specified.
`IHVCompilerFlagString` | A null-terminated, nonempty, comma-delimited IHV compiler flag string, or `NULL` when no IHV-specific flags apply. The runtime passes the application's string through exactly as supplied. It never trims, normalizes, or reorders the string.

When both members are present, the driver applies both. How the predefined level and the IHV-specific flags interact (for example, when an IHV-specific flag also sets an optimization level) is defined by the IHV. Microsoft recommends that IHV-specific flags take precedence over the predefined level, and that IHVs document their behavior for developers.

#### DDI pipeline state objects

The pipeline state creation argument structure and its functions are revised to carry the payload. `D3D12DDIARG_CREATE_PIPELINE_STATE_0132` is identical to the latest revision, `D3D12DDIARG_CREATE_PIPELINE_STATE_0119`, except for the new `DriverCompilerFlags` member at the end.

```cpp
typedef struct D3D12DDIARG_CREATE_PIPELINE_STATE_0132
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
    D3D12DDI_PIPELINE_STATE_FLAGS Flags;
    CONST UINT* pComputeShaderCode;
    CONST UINT* pVertexShaderCode;
    CONST UINT* pPixelShaderCode;
    CONST UINT* pDomainShaderCode;
    CONST UINT* pHullShaderCode;
    CONST UINT* pGeometryShaderCode;
    CONST UINT* pMeshShaderCode;
    CONST UINT* pAmplificationShaderCode;
    D3D12DDI_DRIVER_COMPILER_FLAGS_DESC_0132 DriverCompilerFlags; // New
} D3D12DDIARG_CREATE_PIPELINE_STATE_0132;

typedef HRESULT(APIENTRY* PFND3D12DDI_CREATE_PIPELINE_STATE_0132)(
    D3D12DDI_HDEVICE,
    _In_ CONST D3D12DDIARG_CREATE_PIPELINE_STATE_0132*,
    D3D12DDI_HPIPELINESTATE,
    D3D12DDI_HRTPIPELINESTATE);

typedef SIZE_T(APIENTRY* PFND3D12DDI_CALC_PRIVATE_PIPELINE_STATE_SIZE_0132)(
    D3D12DDI_HDEVICE,
    _In_ CONST D3D12DDIARG_CREATE_PIPELINE_STATE_0132*);
```

The core device function table is revised to `D3D12DDI_DEVICE_FUNCS_CORE_0132`. Its layout is the same as `D3D12DDI_DEVICE_FUNCS_CORE_0131`, the latest core table, except that `pfnCalcPrivatePipelineStateSize` and `pfnCreatePipelineState` use the `_0132` function types above.

Member | Definition
--- | ---
`DriverCompilerFlags` | The effective driver compiler flags for this PSO. When no compiler flags apply, the runtime sets `D3D12PredefinedCompilerFlag` to `D3D12DDI_PREDEFINED_COMPILER_FLAG_NONE` and `IHVCompilerFlagString` to `NULL`. A descriptor that holds only these default values is equivalent to an omitted subobject.

The API-level `D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_DRIVER_COMPILER_FLAGS` subobject in the pipeline state stream (see [D3D12_PIPELINE_STATE_SUBOBJECT_TYPE](#d3d12_pipeline_state_subobject_type)) is translated into `DriverCompilerFlags`. The driver never sees the API stream subobject itself.

#### DDI state objects

The state object DDI subobject enum gains a new type. The existing `CreateStateObject` and `AddToStateObject` DDIs carry it the same way as other subobjects.

```cpp
typedef enum D3D12DDI_STATE_SUBOBJECT_TYPE
{
    ...
    D3D12DDI_STATE_SUBOBJECT_TYPE_DRIVER_COMPILER_FLAGS = 44, // D3D12DDI_DRIVER_COMPILER_FLAGS_DESC_0132
} D3D12DDI_STATE_SUBOBJECT_TYPE;
```

Value | Definition
--- | ---
`D3D12DDI_STATE_SUBOBJECT_TYPE_DRIVER_COMPILER_FLAGS` | Driver compiler flags for the state object. The associated data is a [D3D12DDI_DRIVER_COMPILER_FLAGS_DESC_0132](#d3d12ddi_driver_compiler_flags_desc_0132).

The runtime guarantees the following about this subobject before the driver sees it:

- A state object has at most one driver compiler flags subobject.
- The subobject applies to the whole state object. It is never associated with individual exports.
- It is never inside a generic program or a partial program.
- The runtime sends this subobject type only to drivers that negotiate DDI 0132 or later.

An explicitly empty descriptor (`NONE` and a `NULL` string) is valid for both PSOs and state objects. For a PSO, it is indistinguishable from an omitted subobject: `DriverCompilerFlags` holds the default values. For a state object, the runtime keeps the subobject, because it is part of the state object's identity in the SODB, so the driver can receive it. The driver must treat an explicitly empty descriptor exactly like an absent subobject.

#### Payload rules

These rules apply to both PSOs and state objects:

- **Lifetime.** The descriptor and the `IHVCompilerFlagString` it points to are valid only for the duration of the DDI call. If the driver needs the flags later (for example, for deferred or background compilation, or recompilation), it must copy them.
- **Consistency.** The runtime passes the same descriptor to `pfnCalcPrivatePipelineStateSize` and `pfnCreatePipelineState` (and to the matching state object size and creation calls). The driver must interpret both calls the same way.
- **Opaqueness.** The runtime doesn't parse, normalize, or validate the contents of `IHVCompilerFlagString` beyond the structural checks in [Runtime validation](#runtime-validation).
- **Character set.** The string is UTF-16 (`LPCWSTR`). Microsoft recommends that IHVs limit their flag syntax to printable ASCII. Commas separate flags; the driver defines any further structure, such as `name=value`.
- **No side effects on other objects.** Flags apply only to the object being created. They must not change the driver's global state or affect other objects.

#### Reporting supported IHV compiler flags

**Proposed (optional for IHVs):** a driver can describe the IHV-specific flags it supports, so that applications and tools can discover them through [D3D12_FEATURE_IHV_COMPILER_FLAGS](#d3d12_feature_ihv_compiler_flags). The description is informational only. It is help text for developers and tools, not a schema: the runtime never validates `IHVCompilerFlagString` against it.

The driver reports the list through the existing `pfnGetCaps` DDI with two new caps types, following the same count-then-array pattern as other enumerated caps:

```cpp
typedef enum D3D12DDICAPS_TYPE
{
    ...
    D3D12DDICAPS_TYPE_0132_IHV_COMPILER_FLAG_COUNT, // UINT
    D3D12DDICAPS_TYPE_0132_IHV_COMPILER_FLAGS,      // D3D12DDI_IHV_COMPILER_FLAG_DESC_0132[Count]
} D3D12DDICAPS_TYPE;

typedef struct D3D12DDI_IHV_COMPILER_FLAG_DESC_0132
{
    LPCWSTR Name;
    LPCWSTR Syntax;
    LPCWSTR Description;
} D3D12DDI_IHV_COMPILER_FLAG_DESC_0132;
```

Member | Definition
--- | ---
`Name` | The flag name as it appears in `IHVCompilerFlagString`, for example `unroll-limit`. Required; cannot be `NULL` or empty.
`Syntax` | How to write the flag, including any value, for example `unroll-limit=<n>`. Can be `NULL` if the flag takes no value.
`Description` | Human-readable help text that describes what the flag does and any valid values or ranges. Can be `NULL`.

- For `D3D12DDICAPS_TYPE_0132_IHV_COMPILER_FLAG_COUNT`, the driver writes the number of flags it describes. A driver that doesn't describe its flags reports `0`.
- For `D3D12DDICAPS_TYPE_0132_IHV_COMPILER_FLAGS`, the runtime supplies an array sized from the count, and the driver fills in one entry per flag.
- The driver owns the strings. They must stay valid until the device is destroyed. The runtime queries the list once per device and caches it.
- The list may omit flags, for example internal or diagnostic flags. The driver keeps accepting flags it doesn't list.
- The list should match what the compiler plugin reports for the same adapter family (see [Reporting supported IHV compiler flags from the compiler plugin](#reporting-supported-ihv-compiler-flags-from-the-compiler-plugin)).

### Compiler plugin DDI

The State Object Compiler plugin DDI exposes the same payload for offline compilation, so that offline results match runtime results for the same flags.

#### Compiler plugin DDI version

As described in [Plugin DDI Versioning](ShaderCompilerPlugin.md#plugin-ddi-versioning), each compiler plugin DDI version is tied to exactly one runtime user-mode DDI version. The new plugin revision is tied to runtime DDI 0132.

```cpp
// D3D12 Compiler Plugin DDI Release 0, Build rev 4.
// Adds driver compiler flags for PSO/SO compilation using runtime DDI 0132.
#define D3D12DDI_COMPILER_BUILD_VERSION_0004 4
#define D3D12DDI_COMPILER_SUPPORTED_0004 ((((UINT64)D3D12DDI_COMPILER_INTERFACE_VERSION) << 32) | (((UINT64)D3D12DDI_COMPILER_BUILD_VERSION_0004) << 16))
```

A plugin reports `D3D12DDI_COMPILER_SUPPORTED_0004` from `PFND3D12DDI_COMPILER_GET_SUPPORTED_VERSIONS` only if it supports driver compiler flags.

#### D3D12DDIARG_COMPILER_COMPILE_PIPELINE_STATE_0004

```cpp
typedef struct D3D12DDIARG_COMPILER_COMPILE_PIPELINE_STATE_0004
{
    D3D12DDI_COMPILER_SHADER_DESC *pComputeShader;
    D3D12DDI_COMPILER_SHADER_DESC *pVertexShader;
    D3D12DDI_COMPILER_SHADER_DESC *pPixelShader;
    D3D12DDI_COMPILER_SHADER_DESC *pDomainShader;
    D3D12DDI_COMPILER_SHADER_DESC *pHullShader;
    D3D12DDI_COMPILER_GEOMETRY_SHADER *pGeometryShader;
    D3D12DDI_COMPILER_ROOT_SIGNATURE_DESC *pRootSignature;
    D3D12DDI_COMPILER_BLEND_DESC *pBlendState;
    UINT SampleMask;
    D3D12DDI_COMPILER_RASTERIZER_DESC *pRasterizerState;
    D3D12DDI_COMPILER_DEPTH_STENCIL_DESC *pDepthStencilState;
    D3D12DDI_COMPILER_ELEMENTLAYOUT_DESC *pElementLayout;
    D3D12DDI_INDEX_BUFFER_STRIP_CUT_VALUE IBStripCutValue;
    D3D12DDI_PRIMITIVE_TOPOLOGY_TYPE PrimitiveTopologyType;
    UINT NumRenderTargets;
    DXGI_FORMAT RTVFormats[8];
    DXGI_FORMAT DSVFormat;
    DXGI_SAMPLE_DESC SampleDesc;
    D3D12DDI_COMPILER_VIEW_INSTANCING_DESC ViewInstancingDesc;
    D3D12DDI_COMPILER_SHADER_DESC *pMeshShader;
    D3D12DDI_COMPILER_SHADER_DESC *pAmplificationShader;
    D3D12DDI_DRIVER_COMPILER_FLAGS_DESC_0132 DriverCompilerFlags; // New
} D3D12DDIARG_COMPILER_COMPILE_PIPELINE_STATE_0004;

typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_COMPILE_PIPELINE_STATE_0004)(
    D3D12DDI_HCOMPILER hCompiler,
    D3D12DDI_HRTCOMPILERCACHESESSION hrtCompilerCacheSession,
    D3D12DDI_COMPILER_VALUE_TYPE_FLAGS ValueTypeFlags,
    CONST D3D12DDIARG_COMPILER_COMPILE_PIPELINE_STATE_0004* pPipelineStateArg
    );
```

`DriverCompilerFlags` uses the same descriptor type and follows the same [payload rules](#payload-rules) as the runtime DDI. When no compiler flags apply, it holds `D3D12DDI_PREDEFINED_COMPILER_FLAG_NONE` and a `NULL` string.

#### D3D12DDI_COMPILER_FUNCS_0004

```cpp
typedef struct D3D12DDI_COMPILER_FUNCS_0004
{
    PFND3D12DDI_COMPILER_CALC_PRIVATE_COMPILER_SIZE             pfnCalcPrivateCompilerSize;
    PFND3D12DDI_COMPILER_CREATE_COMPILER                        pfnCreateCompiler;
    PFND3D12DDI_COMPILER_DESTROY_COMPILER                       pfnDestroyCompiler;
    PFND3D12DDI_COMPILER_COMPILE_PIPELINE_STATE_0004            pfnCompilePipelineState;
    PFND3D12DDI_COMPILER_CALC_PRIVATE_STATE_OBJECT_SIZE         pfnCalcPrivateStateObjectSize;
    PFND3D12DDI_COMPILER_COMPILE_CREATE_STATE_OBJECT            pfnCompileCreateStateObject;
    PFND3D12DDI_COMPILER_CALC_PRIVATE_ADD_TO_STATE_OBJECT_SIZE  pfnCalcPrivateAddToStateObjectSize;
    PFND3D12DDI_COMPILER_COMPILE_ADD_TO_STATE_OBJECT            pfnCompileAddToStateObject;
    PFND3D12DDI_COMPILER_DESTROY_STATE_OBJECT                   pfnDestroyStateObject;
} D3D12DDI_COMPILER_FUNCS_0004;
```

This table is the same as `D3D12DDI_COMPILER_FUNCS` except that `pfnCompilePipelineState` uses the `_0004` argument structure. The earlier compile arguments and function table are unchanged for plugins that don't negotiate revision 4.

#### State object compilation

State object descriptions are shared between the runtime and the compiler plugin. When revision 4 is negotiated, the existing state object compile callbacks (`pfnCalcPrivateStateObjectSize`, `pfnCompileCreateStateObject`, `pfnCalcPrivateAddToStateObjectSize`, `pfnCompileAddToStateObject`) can receive a `D3D12DDI_STATE_SUBOBJECT_TYPE_DRIVER_COMPILER_FLAGS` subobject, under the same rules as in [State objects](#ddi-state-objects).

#### Compiler plugin that does not support compiler flags

A plugin that doesn't report revision 4 or later can't receive compiler flags. If effective flags exist for an object but the selected plugin version doesn't support them, then (**Proposed**):

- The State Object Compiler drops the flags and compiles the object without them.
- The State Object Compiler reports a warning that identifies the plugin, adapter family, and object, so that the dropped flags are visible to developers and in telemetry.
- The compiled output is recorded as compiled *without* compiler flags, so that it isn't mistaken for output compiled with them (see [Versioning and compatibility of driver compiler flags](#versioning-and-compatibility-of-driver-compiler-flags)).

The alternative is to fail compilation of the object.

#### Reporting supported IHV compiler flags from the compiler plugin

**Proposed (optional for IHVs):** a compiler plugin that negotiates revision 4 or later can answer the same `D3D12DDICAPS_TYPE_0132_IHV_COMPILER_FLAG_COUNT` and `D3D12DDICAPS_TYPE_0132_IHV_COMPILER_FLAGS` caps through the existing [PFND3D12DDI_COMPILER_GET_CAPS](ShaderCompilerPlugin.md#function-pfnd3d12ddi_compiler_get_caps). No new plugin entry point is needed. Because `PFND3D12DDI_COMPILER_GET_CAPS` takes a `D3D12DDI_COMPILER_TARGET`, the plugin can report a different list for each adapter family and ABI version.

- The plugin owns the strings, and they must stay valid until the plugin DDI object is destroyed.
- For the same adapter family, the list should match what the runtime driver reports.
- A plugin that doesn't describe its flags reports a count of `0`.

The State Object Compiler exposes the list to tools and developers through:

- `ID3D12CompilerFactory1::EnumerateIHVCompilerFlags`, an API that takes a compiler target and invokes a callback once for each flag.
- `D3D12StateObjectCompiler.exe list-ihv-compiler-flags --adapter-family <name>`, a command that prints each flag's name, syntax, and description.

This lets developers and tools such as PIX discover the IHV-specific flags offline, without an adapter from that IHV.

### IHV action checklist

Runtime user-mode driver:

- [ ] Negotiate DDI 0132 and implement `PFND3D12DDI_CALC_PRIVATE_PIPELINE_STATE_SIZE_0132` and `PFND3D12DDI_CREATE_PIPELINE_STATE_0132`.
- [ ] Accept `D3D12DDI_STATE_SUBOBJECT_TYPE_DRIVER_COMPILER_FLAGS` in state object creation and `AddToStateObject`.
- [ ] Map the predefined optimization levels to IHV compiler settings.
- [ ] Parse IHV flag strings defensively, apply the agreed validation policy, and report problems through `pfnReportMessageCb`.
- [ ] Copy flags that are needed after a DDI call returns.
- [ ] Include the effective flags in any value key or cache identity that the driver derives.
- [ ] Optional: describe the supported IHV-specific flags through `D3D12DDICAPS_TYPE_0132_IHV_COMPILER_FLAG_COUNT` and `D3D12DDICAPS_TYPE_0132_IHV_COMPILER_FLAGS`.

Compiler plugin:

- [ ] Report `D3D12DDI_COMPILER_SUPPORTED_0004` and implement `PFND3D12DDI_COMPILER_COMPILE_PIPELINE_STATE_0004`.
- [ ] Accept the compiler flags subobject in the state object compile callbacks.
- [ ] Interpret flags the same way as the runtime driver.
- [ ] Include the effective flags in any value keys set through the cache session callbacks.
- [ ] Optional: describe the supported IHV-specific flags for each adapter family through the same caps in `PFND3D12DDI_COMPILER_GET_CAPS`, matching the runtime driver.

Documentation:

- [ ] Publish the IHV-specific flag syntax and the supported flags for developers, including how they interact with the predefined levels.

## Conformance testing

**Proposed:** an HLK conformance test for driver compiler flags robustness, with the following coverage:

- The test creates PSOs and state objects with unrecognized, malformed, and very long IHV flag strings, together with each predefined level.
- It checks that the driver doesn't crash, hang, or cause device removal, and that object creation follows the agreed [validation policy](#driver-and-compiler-plugin-validation).
- When the driver-reported messages feature is enabled, it checks that the driver reports a message for invalid flags.
- The test runs only on drivers that negotiate DDI 0132 or later.
- **Proposed:** the test starts as **optional** and **negative-only**. Microsoft will agree with IHVs before it becomes required.

## Telemetry

Telemetry records how the effective driver compiler flags are selected and whether compilation and PSDB lookup succeed. The telemetry supports diagnosing cases where an expected compiler identity filter does not match, an override changes the effective flags, or flags cause a PSDB value to be unavailable.

Telemetry records the following information:

- The source of the effective flags: device-level API, PSO/SO subobject, database-wide override, compiler command line, or no compiler flags.
- Whether the effective descriptor contains a predefined flag, an IHV-specific flag string, both, or neither.
- The IHV-specific filter lookup result: adapter-family filter matched, vendor fallback matched, or no filter matched.
- The override that determined the effective flags: PSO/SO flags replaced device-level flags, database-wide overrides replaced the object's compiler flags subobject, compiler command-line flags replaced SODB flags, or no override occurred.
- Validation and compilation results, including an invalid descriptor, invalid filter bounds, a duplicate or overlapping filter, driver compiler rejection, and compilation failure while flags are applied.
- The PSDB cache result when compiler flags apply, including a cache hit, cache miss, compiler-flag metadata mismatch, or local compilation.

Telemetry events include fields equivalent to:

| Field | Description |
| --- | --- |
| `FlagSource` | Identifies the source of the effective compiler flags. |
| `HasPredefinedFlag` | Indicates whether a predefined compiler flag applies. |
| `HasIHVCompilerFlags` | Indicates whether an IHV-specific compiler flag string applies. |
| `FilterMatchScope` | Identifies whether an adapter-family filter, vendor filter, or no filter matched. |
| `OverrideSource` | Identifies the source that replaced lower-precedence compiler flags. |
| `LookupResult` | Identifies the filter-selection or validation result. |
| `CompilationResult` | Identifies whether compilation succeeded, failed, or was rejected by the driver compiler. |
| `PSDBCacheResult` | Identifies whether compilation used a PSDB cache value or required local compilation. |

Telemetry does not record the contents of `IHVCompilerFlagString`. The string is IHV-defined and opaque to the runtime. Existing ASD cache hit and miss telemetry includes objects that use driver compiler flags so developers can determine whether those objects use precompiled values or require local compilation. `D3D12CacheListener` reports the compiler flag source, filter match scope, override source, and PSDB cache result.

## Samples

[TODO: add sample code]

## History

| Date | Notes |
| ---- | ----- |
| **7/15/2026** | Initial version. |
| **9/2/2026** | Expands the runtime, offline compiler, SODB, PSDB, capture, merge, and DDI behavior for predefined and IHV-specific compiler flags. Defines device-level and PSO/SO-level flags, override precedence, compiler command-line inputs, compiler identity filtering, separate predefined and IHV-specific associations, direct predefined value storage, internal content-derived IHV flag and filter keys, storage and deletion APIs, effective group lookup with global fallback, maintainer enumeration, validation requirements, PSDB value-key and metadata participation, and merge conflict policies. |
| **9/25/2026** | Clarifies compiler identity filter ranges, case-insensitive adapter-family prefix matching, normalized filter identity, group and global lookup precedence, most-specific filter selection, overlapping-filter rejection, association uniqueness and deletion, orphan cleanup, and telemetry. Adds a concrete lookup descriptor, group-scoped deletion API, and a worked group and global filter example. Makes filter bounds required values, defines `0` and `UINT64_MAX` as unbounded range sentinels, constrains concrete versions for signed SQLite comparison, clarifies optional filter and lookup validation, explicitly applies case-insensitive adapter-family comparison to equal-specificity filters, and defines the enumeration and exact-deletion workflow for replacing an overlapping association. |
| **11/18/2026** | Adds the driver and compiler plugin DDI: runtime DDI build 132 with the pipeline state argument, state object subobject, and payload rules; compiler plugin DDI revision 4; driver validation and `pfnReportMessageCb` reporting; `D3D12_FEATURE_COMPILER_OPTIONS` capability reporting and optional IHV compiler flag enumeration; device-level flag resolution for drivers; caching requirements for drivers and plugins; D3DX12 helpers; conformance testing; and an IHV action checklist. |
