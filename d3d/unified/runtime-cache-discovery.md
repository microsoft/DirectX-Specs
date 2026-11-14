<a id="runtime-cache-discovery"></a>

# Runtime cache discovery and compatibility selection

<!-- d3d12-review-legend:begin -->

> [!NOTE]
> **Draft provenance annotations.**
> Underlining marks pending replacement wording or authored list items. Warning boxes
> mark authored, mixed or reopened passages awaiting editorial review.
> Editorial adoption does not establish factual or hardware verification. Exact approved factual
> corrections do not trigger a marker. Unmarked text elsewhere, declarations
> and structural Markdown are not assertions of approval.
> [Annotation scope and approvals](../../spec-maintenance/d3d12/prose-annotations.md).

<!-- d3d12-review-legend:end -->

<ins><!-- d3d12-review-inline:begin:cache-discovery:subject:0:authored:migration-882ba59c3cdaf7a0-0 -->Runtime cache discovery uses the D3D Shader Cache Registration (D3DSCR) API to associate the current application and adapter with a registered precompiled shader database (PSDB). Registration of a path, opening a recognized database, compatibility of its metadata and finding a compiled value are distinct conditions. A compatible open is not a cache hit.<!-- d3d12-review-inline:end:cache-discovery:subject:0:authored:migration-882ba59c3cdaf7a0-0 --></ins>

<a id="runtime-workflow"></a>

## Runtime workflow

![Diagram representing the workflow of how the Shader Cache registration API should be used during runtime](<ins><!-- d3d12-review-inline:begin:cache-discovery:workflow:0:modified:source-c2bbf2dac69978cc-0-0 -->../<!-- d3d12-review-inline:end:cache-discovery:workflow:0:modified:source-c2bbf2dac69978cc-0-0 --></ins>images/AdvancedShaderDelivery/D3DShaderCacheRegistrationAPI_Runtime.png "Runtime Scenario")

This diagram demonstrates the interaction between the D3D12 runtime and D3DSCR API during game execution time for <ins><!-- d3d12-review-inline:begin:cache-discovery:workflow:1:modified:source-a1915567ef3e0bbe-0-0 -->automatic discovery<!-- d3d12-review-inline:end:cache-discovery:workflow:1:modified:source-a1915567ef3e0bbe-0-0 --></ins>. The game can still benefit from pre-compiled shaders if an SODB can be collected via playthrough. A typical process in this scenario is as follows:

1. The game installer launches the game (after first running through the install/update workflow if applicable).
2. The game runs, loads the D3D12 runtime and proceeds to create Pipeline State Objects (PSOs) or State Objects (SOs).
3. The D3D12 runtime <ins><!-- d3d12-review-inline:begin:cache-discovery:workflow:2:modified:source-42de5aabdde0116e-0-0 -->uses D3DSCR to look up the current process's application registration by its executable path and discover the default component's PSDB path<!-- d3d12-review-inline:end:cache-discovery:workflow:2:modified:source-42de5aabdde0116e-0-0 --></ins> for the current <ins><!-- d3d12-review-inline:begin:cache-discovery:workflow:2:modified:source-42de5aabdde0116e-0-1 -->adapter family. See [Default component discovery](#default-discovery)<!-- d3d12-review-inline:end:cache-discovery:workflow:2:modified:source-42de5aabdde0116e-0-1 --></ins>.
4. The D3D12 runtime will check for a matching pre-compiled shader in the PSDB to avoid runtime compilation.

<a id="effective-identity"></a>

## Effective application identity and configuration

The Direct3D runtime and drivers currently match metadata about the process that has loaded their respective dlls, such as executable name, parent directory, etc. to determine which application is running.  The Direct3D runtime does this to determine default adapter preference in systems with multiple GPUs and disable features that cause compatibility issues with games.  Drivers use this information to enable targeted optimizations and fixes.  However, offline compilers are not run in the <ins><!-- d3d12-review-inline:begin:cache-discovery:identity-handoff:0:modified:source-d8c1c7eb45e3395b-0-0 -->application's<!-- d3d12-review-inline:end:cache-discovery:identity-handoff:0:modified:source-d8c1c7eb45e3395b-0-0 --></ins> process to determine this information.  To maintain this capability in an offline compiled world, game store services are expected to supply this information when submitting titles and their SODBs for compilation, and also supply this same information when registering applications.

When compiling offline, the metadata passed to the store is shared with the compiler.  When a title is run, <ins><!-- d3d12-review-inline:begin:cache-discovery:identity-handoff:1:modified:source-537142a24bd65885-0-0 -->the Direct3D runtime<!-- d3d12-review-inline:end:cache-discovery:identity-handoff:1:modified:source-537142a24bd65885-0-0 --></ins> acquires this information from the <ins><!-- d3d12-review-inline:begin:cache-discovery:identity-handoff:1:modified:source-537142a24bd65885-1-0 -->[Shader Cache Registration API](shader-cache-registration.md#shader-cache-registration)<!-- d3d12-review-inline:end:cache-discovery:identity-handoff:1:modified:source-537142a24bd65885-1-0 --></ins> and shares it with the driver.

<ins><!-- d3d12-review-inline:begin:cache-discovery:configuration:0:authored:migration-a612d44cc77988a0-0 -->The [global or factory identity configuration](state-object-databases-and-identity.md#id3d12applicationidentity-setapplicationidentity) supplies the description for subsequent device initialization in that configuration's scope. [Factory snapshots](devices-and-capabilities.md#independent-devices), [InitializeFromGlobalState](devices-and-capabilities.md#id3d12devicefactory-initializefromglobalstate) and [ApplyToGlobalState](devices-and-capabilities.md#id3d12devicefactory-applytoglobalstate) govern copying that configuration. A factory identity is not a second process-global override. Resetting the configured identity removes that explicit source for subsequent initialization.<!-- d3d12-review-inline:end:cache-discovery:configuration:0:authored:migration-a612d44cc77988a0-0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-discovery:identity-precedence:0:authored:migration-0e5f7b07d6c79d0f-0 -->During initial effective-identity resolution, the runtime uses the explicitly configured application description, otherwise a successfully read description from the current process's application registration, otherwise the current executable's filename when available. Obtaining the registration factory, explorer and registered application, and reading its initial description, are best-effort for this resolution: acquisition failure, missing registration or a failed initial `GetDesc` can leave no usable registered description and allow the filename fallback. The full process executable path is the registration lookup key even when the configured or registered identifying filename differs from the host executable. The stable identifying filename is metadata, not a replacement catalog path. The version-4 configuration `AppId` is not the executable path registration key.<!-- d3d12-review-inline:end:cache-discovery:identity-precedence:0:authored:migration-0e5f7b07d6c79d0f-0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-discovery:registration-stages:0:authored:migration-7903e3f5a74c69ce-0 -->Later device cache initialization independently obtains a registered application for cache discovery and eligibility. An explicit configured identity still wins effective-identity resolution, but does not promise that this later registration query is skipped. If a registered application is acquired at this later stage, reading its description is required and a failing `GetDesc` can propagate. Initial identity resolution and later cache initialization use separate catalog queries, not one atomic catalog snapshot. An earlier filename fallback does not convert the later required read into another best-effort read.<!-- d3d12-review-inline:end:cache-discovery:registration-stages:0:authored:migration-7903e3f5a74c69ce-0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-discovery:identity-profile:0:authored:migration-da3c6f8876778c32-0 -->The driver uses application metadata as input to its profile and application detection rules. Supplying an application description or `AppId` does not require the driver to abandon its other detection inputs. [Application-specific driver state](../D3D12ApplicationIdentity.md#tooling-interactions-with-application-specific-driver-state) remains the capture/replay mechanism for restoring the driver's applied settings, rather than a guarantee that a runtime description alone reproduces every heuristic.<!-- d3d12-review-inline:end:cache-discovery:identity-profile:0:authored:migration-da3c6f8876778c32-0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-discovery:reuse:0:authored:migration-fc262c069222bbfb-0 -->These initialization rules do not imply fresh discovery on every call to [D3D12CreateDevice](devices-and-capabilities.md#d3d12createdevice) or [factory CreateDevice](devices-and-capabilities.md#id3d12devicefactory-createdevice). The [singleton and independent-device compatibility rules](devices-and-capabilities.md#device-compatibility) can return an existing device. Returning that device does not reinitialize its effective identity or reopen its registered PSDB. Changes to a factory or global identity do not replace the configuration already used by an existing device.<!-- d3d12-review-inline:end:cache-discovery:reuse:0:authored:migration-fc262c069222bbfb-0 --></ins>

<a id="default-discovery"></a>

## Registered application and default component discovery

<ins><!-- d3d12-review-inline:begin:cache-discovery:catalog-steps:0:authored:migration-08a18d0a017b0af1-0 -->Automatic discovery uses the following catalog operations:<!-- d3d12-review-inline:end:cache-discovery:catalog-steps:0:authored:migration-08a18d0a017b0af1-0 --></ins>

1. <ins><!-- d3d12-review-inline:begin:cache-discovery:catalog-steps:1:authored:migration-d2cb4f4fd1902a23-0 -->The runtime obtains a registration explorer with no explicitly supplied device or adapter context and looks up the current process's full executable path with [GetApplicationFromExePath](shader-cache-registration.md#id3dshadercacheexplorer-getapplicationfromexepath). This internal use of [CreateExplorer](shader-cache-registration.md#id3dshadercacheinstallerfactory-createexplorer) does not change the context chosen by other callers.<!-- d3d12-review-inline:end:cache-discovery:catalog-steps:1:authored:migration-d2cb4f4fd1902a23-0 --></ins>
2. <ins><!-- d3d12-review-inline:begin:cache-discovery:catalog-steps:1:authored:migration-5c67fed510ef0434-1 -->For an application found in the catalog, [GetDesc](shader-cache-registration.md#id3dshadercacheapplication-getdesc) supplies its registered identity metadata. [GetComponentCount](shader-cache-registration.md#id3dshadercacheapplication-getcomponentcount), [GetComponent](shader-cache-registration.md#id3dshadercacheapplication-getcomponent) and [GetComponentName](shader-cache-registration.md#id3dshadercachecomponent-getcomponentname) locate the component whose name is exactly `default`.<!-- d3d12-review-inline:end:cache-discovery:catalog-steps:1:authored:migration-5c67fed510ef0434-1 --></ins>
3. <ins><!-- d3d12-review-inline:begin:cache-discovery:catalog-steps:1:authored:migration-869dff426db9d196-2 -->[GetPrecompiledCachePath](shader-cache-registration.md#id3dshadercachecomponent-getprecompiledcachepath) supplies that component's path for the current adapter family. The runtime attempts to open this path only when the adapter/runtime supports PSDB consumption. The [device shader cache ABI query](devices-and-capabilities.md#d3d12_feature_data_shadercache_abi_support) supplies the adapter's compatibility information.<!-- d3d12-review-inline:end:cache-discovery:catalog-steps:1:authored:migration-869dff426db9d196-2 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-discovery:default-name:0 -->There is a special component name, "default" (case-sensitive) that should be used when the application is not explicitly expecting to find a component by a different name. This string is the one that D3D12 will use during device initialization to find a PSDB that's used to accelerate `CreatePipelineState` and `CreateStateObject` without explicit steering to an alternate PSDB by the application.<!-- d3d12-review-inline:end:cache-discovery:default-name:0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-discovery:multiplicity:0:authored:migration-7c56cc1d9905cc77-0 -->An application can register multiple components, and a component can register PSDB paths for multiple adapter families. [GetPrecompiledShaderDatabaseCount](shader-cache-registration.md#id3dshadercachecomponent-getprecompiledshaderdatabasecount) and [GetPrecompiledShaderDatabases](shader-cache-registration.md#id3dshadercachecomponent-getprecompiledshaderdatabases) enumerate those family/path records. This is not a list of competing ABI/profile versions for one family. Automatic default discovery selects the one registered path for the current family in `default`, not the newest database found by scanning components or the filesystem. [GetStateObjectDatabasePath](shader-cache-registration.md#id3dshadercachecomponent-getstateobjectdatabasepath) returns the component's SODB input path, not another PSDB candidate.<!-- d3d12-review-inline:end:cache-discovery:multiplicity:0:authored:migration-7c56cc1d9905cc77-0 --></ins>

<a id="compatibility"></a>

## Recognized databases and compatibility

<ins><!-- d3d12-review-inline:begin:cache-discovery:eligibility:0:authored:migration-798b3389d6fefd8b-0 -->A registered path is only a candidate. The file must be readable as a recognized PSDB, contain the required identity metadata and satisfy the application and target compatibility checks. A missing file, unsupported format or incompatible metadata does not become usable merely because its path is registered. Database format recognition is separate from ABI/profile matching; no numeric PSDB format version is defined by this compatibility predicate.<!-- d3d12-review-inline:end:cache-discovery:eligibility:0:authored:migration-798b3389d6fefd8b-0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-discovery:target-predicate:0:modified:migration-99fbba549f7548d7-0 -->`D3D_SHADER_CACHE_COMPILER_PROPERTIES` are<!-- d3d12-review-inline:end:cache-discovery:target-predicate:0:modified:migration-99fbba549f7548d7-0 --></ins> used to determine compatibility with the compiler parameters used to produce a PSDB:

```cpp
// A PSDB for a title is usable by an adapter if the adapter family matches, the psdb abi version is between
// the supported min/max Abi version inclusive, and the top 32 bits of the application profile version matches.
// Incompatible psdbs are not usable by the target adapter driver, and are rejected by the runtime.
bool IsPsdbCompatible(
    const std::wstring& psdbAdapterFamily,
    UINT64 psdbAbiVersion,
    UINT64 psdbApplicationProfileVersion,
    const D3D_SHADER_CACHE_COMPILER_PROPERTIES& compilerProperties)
{
    return psdbAdapterFamily == compilerProperties.szAdapterFamily
        && psdbAbiVersion >= compilerProperties.MinimumABISupportVersion
        && psdbAbiVersion <= compilerProperties.MaximumABISupportVersion
        && HIDWORD(psdbApplicationProfileVersion) == HIDWORD(compilerProperties.ApplicationProfileVersion.Version);
}
```

<ins><!-- d3d12-review-inline:begin:cache-discovery:application-guard:0:authored:migration-1684961a49a14d0f-0 -->Application eligibility additionally checks the PSDB's stored application name against the resolved application name or the registered application name, using a case-insensitive comparison. For this read-only consumption, the application profile comparison uses the high 32 bits as shown above. A change confined to the low 32 bits does not by itself reject the PSDB. Missing identity metadata cannot establish compatibility. Exact application version, engine version and executable filename equality are not additional direct comparisons in this eligibility check, although those fields can influence the driver's selected application profile.<!-- d3d12-review-inline:end:cache-discovery:application-guard:0:authored:migration-1684961a49a14d0f-0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-discovery:version-roles:0:authored:migration-dd0a0270eeb89812-0 -->Family matching in the target predicate is exact string equality, not case folding or a match by adapter model, vendor, LUID or substring. The driver's minimum and maximum ABI bounds are inclusive. A compiler's [enumerated ABI set](offline-compilation.md#id3d12compilerfactory-enumerateadapterfamilyabiversions) can be sparse: producing a compatible PSDB requires choosing an enumerated compiler ABI inside the driver's interval, not assuming the compiler supports every integer in that interval. The compiler target's [zero-means-latest convention](offline-compilation.md#d3d12_compiler_target) is not a runtime compatibility wildcard for a stored ABI.<!-- d3d12-review-inline:end:cache-discovery:version-roles:0:authored:migration-dd0a0270eeb89812-0 --></ins>

<a id="failure-and-lifetime"></a>

## Absence, failures, controls and retained state

<ins><!-- d3d12-review-inline:begin:cache-discovery:normal-absence:0:authored:migration-659c54ccde4ea04e-0 -->No application registration, no component named `default`, or no path registered for the current family can leave the device without a default PSDB. The runtime's component search skips unsuccessful component acquisitions and name queries. This does not change the [catalog methods' own error results](shader-cache-registration.md#id3dshadercacheapplication-getcomponent). It does not select an arbitrary other component as a fallback.<!-- d3d12-review-inline:end:cache-discovery:normal-absence:0:authored:migration-659c54ccde4ea04e-0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-discovery:open-policy:0:authored:migration-6136408ec3e0c791-0 -->The automatic default PSDB open is read-only. It must not create an empty replacement for a missing registered file, clear registered content or restamp missing or incompatible identity metadata to make the database usable. A failing `HRESULT` from an attempted implicit open, including an unreadable or unrecognized file or incompatible identity metadata, leaves no opened default PSDB and is recorded diagnostically. That unsuccessful open does not by itself fail device initialization. This is not a guarantee that every discovery failure is silently ignored or that every cache error has the same result.<!-- d3d12-review-inline:end:cache-discovery:open-policy:0:authored:migration-6136408ec3e0c791-0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-discovery:discovery-errors:0:authored:migration-5bed4ce704b607ec-0 -->The [initial best-effort identity fallback](#effective-identity) is distinct from the later required work in device cache initialization. Failures obtaining required driver ABI information, or reading the description of a registered application acquired at that later stage, can propagate instead of falling back to a filename. Allocation failures outside the unsuccessful-open result handling can also fail initialization with `E_OUTOFMEMORY`. A successful device creation result is therefore neither proof that a registered PSDB opened nor a promise that catalog, metadata and allocation errors are all nonfatal. Diagnostics do not convert normal absence into a cache hit or establish successful compiled value lookup.<!-- d3d12-review-inline:end:cache-discovery:discovery-errors:0:authored:migration-5bed4ce704b607ec-0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-discovery:lifetime:0:authored:migration-0e5d7ba021aa04e5-0 -->Configuration values and identity strings are captured for initialization. They do not borrow the caller's identity buffers. Catalog-returned strings retain their [registration object lifetime](shader-cache-registration.md#id3dshadercachecomponent-getprecompiledcachepath). The runtime copies the selected path and retains its opened default session for the device's lifetime. Updating registration does not itself replace an already-open default session. Returning an existing device is not a refresh operation. No live rescan, transactional snapshot across catalog operations, or immutable snapshot of all file contents is guaranteed here. Driver updates can change compatibility information used by a later initialization. They do not rewrite the identity and compatibility data already captured by an existing device.<!-- d3d12-review-inline:end:cache-discovery:lifetime:0:authored:migration-0e5d7ba021aa04e5-0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-discovery:controls-and-legacy:0:authored:migration-6604279d6d9a5986-0 -->The [application cache and runtime control contracts](shader-delivery-and-caching.md#id3d12device9-shadercachecontrol), including [control scope and failure ordering](shader-delivery-and-caching.md#cache-control-scope), remain distinct from registering or replacing a PSDB path. Those controls do not select a different registered component or promise rediscovery of an existing device's default PSDB. [Supported legacy pipeline libraries](shader-delivery-and-caching.md#pipeline-libraries) and [cached PSO blobs](shader-delivery-and-caching.md#cached-pso-blobs) retain their own compatibility rules. The PSDB family/ABI/profile predicate does not replace them.<!-- d3d12-review-inline:end:cache-discovery:controls-and-legacy:0:authored:migration-6604279d6d9a5986-0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-discovery:availability:0:authored:migration-746ef05d97388e03-0 -->Registration API availability, successful device creation and support for PSDB consumption are separate conditions. The adapter's [shader cache ABI query](devices-and-capabilities.md#d3d12_feature_data_shadercache_abi_support) must succeed before its family/range/profile outputs can establish compatibility. SDK distribution alone does not establish universal operating-system, runtime, adapter or driver support.<!-- d3d12-review-inline:end:cache-discovery:availability:0:authored:migration-746ef05d97388e03-0 --></ins>

<a id="compiled-value-lookup"></a>

## Compiled value lookup during ordinary creation

<ins><!-- d3d12-review-inline:begin:cache-discovery:lookup-key-context:0:authored:migration-54d3aaa8bb5cf1ec-0 -->The offline producer stores [vendor-keyed compiled values](compiler-invocation-and-cache-output.md#output-storage). Ordinary object creation consumes those values through the runtime shader cache callbacks.<!-- d3d12-review-inline:end:cache-discovery:lookup-key-context:0:authored:migration-54d3aaa8bb5cf1ec-0 --></ins>

For <ins><!-- d3d12-review-inline:begin:cache-discovery:lookup-ordinary-description:0:modified:source-a2c506ebfe8c9324-0-0 -->ordinary PSO or SO creation<!-- d3d12-review-inline:end:cache-discovery:lookup-ordinary-description:0:modified:source-a2c506ebfe8c9324-0-0 --></ins>, the driver receives the full object <ins><!-- d3d12-review-inline:begin:cache-discovery:lookup-ordinary-description:0:modified:source-a2c506ebfe8c9324-1-0 -->description<!-- d3d12-review-inline:end:cache-discovery:lookup-ordinary-description:0:modified:source-a2c506ebfe8c9324-1-0 --></ins>, and derives the same keys for looking up all values via shader cache callbacks.

<ins><!-- d3d12-review-inline:begin:cache-discovery:lookup-contributors:0:authored:migration-2f12bd13a2dda840-0 -->This path contributes to [CreateGraphicsPipelineState](pipeline-state.md#id3d12device-creategraphicspipelinestate), [CreateComputePipelineState](pipeline-state.md#id3d12device-createcomputepipelinestate), [CreatePipelineState](pipeline-state.md#id3d12device2-createpipelinestate), [CreateStateObject](state-objects.md#createstateobject) and [AddToStateObject](state-objects.md#addtostateobject). Their descriptions, validation, capabilities and creation results remain defined at those owners. The driver-derived compiled value key is not the application's SODB object key or compiler value group key. [Output storage](compiler-invocation-and-cache-output.md#output-storage) defines how the producer associates those separate domains. One object can require several values, and a value can be shared by several objects.<!-- d3d12-review-inline:end:cache-discovery:lookup-contributors:0:authored:migration-2f12bd13a2dda840-0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-discovery:lookup-routing:0:authored:migration-55ea859c75ce0f81-0 -->For ordinary creation's typed runtime lookup, the precompiled slot is the device's [opened registered PSDB](#default-discovery) and the dynamic slot is the device's default writable cache for the driver. `D3D12DDI_SHADER_CACHE_GET_VALUE_FLAG_STORED_VALUES_ONLY` excludes the precompiled slot. Otherwise the callback searches the precompiled slot before the dynamic slot, advancing only after `DXGI_ERROR_NOT_FOUND` or `D3DDDIERR_NOTAVAILABLE`. Only requested value kinds participate in value retrieval: an entry containing only an unrequested kind is a miss and allows the next eligible cache to be searched. Disabled sessions report unavailability. A buffer, allocation or other error is not a miss that automatically permits searching the next slot. This is callback routing, not precedence over a driver's internal cache, legacy cached PSO input or pipeline library reuse.<!-- d3d12-review-inline:end:cache-discovery:lookup-routing:0:authored:migration-55ea859c75ce0f81-0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-discovery:lookup-store:0:authored:migration-5a7ff98460f5e8bc-0 -->For ordinary creation, the typed store callback writes to the device's default writable cache for the driver, not the registered read-only PSDB. `pObjectCode` is required. `pCompilerMetadata` is optional. A metadata-only store is invalid. Each supplied value descriptor must identify a non-null buffer containing a nonempty value. The key must identify a nonempty byte sequence, and key and value byte counts must not exceed `UINT_MAX` even though the DDI uses `SIZE_T`. With otherwise valid arguments and no selected session, get and store return `D3DDDIERR_NOTAVAILABLE`. Store can report unavailable storage before validating its inputs. These input constraints do not establish that an invalid-argument result takes precedence over unavailability. A store is not a guarantee of later residency or a replacement for the [cache controls](shader-delivery-and-caching.md#cache-control-scope).<!-- d3d12-review-inline:end:cache-discovery:lookup-store:0:authored:migration-5a7ff98460f5e8bc-0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-discovery:lookup-outcome:0:authored:migration-319424ef36a4ee2d-0 -->A value lookup is not an object creation result. A PSDB miss can still be satisfied by a local cache, and a partial hit can supply one shader while other required values are absent. If the driver never calls the runtime cache callbacks, the runtime cannot infer a PSDB hit or miss from successful creation alone. A successful lookup does not bypass creation validation or guarantee that every value needed by the driver is available. Callback failures are returned to the driver. They are not a new application-visible cache mismatch result. The ordinary creation result depends on the remaining creation work and the driver's result, not solely on the cache result.<!-- d3d12-review-inline:end:cache-discovery:lookup-outcome:0:authored:migration-319424ef36a4ee2d-0 --></ins>

<a id="runtime-shader-cache-ddi"></a>

### Runtime shader cache DDI reference

<ins><!-- d3d12-review-inline:begin:cache-discovery:lookup-ddi-intro:0:authored:migration-e0b707536f816949-0 -->Runtime shader cache callbacks run from driver to runtime. They use `D3D12DDI_FEATURE_0021_SHADERCACHING` and `D3D12DDI_TABLE_TYPE_0021_SHADERCACHE_CALLBACKS`.<!-- d3d12-review-inline:end:cache-discovery:lookup-ddi-intro:0:authored:migration-e0b707536f816949-0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-discovery:lookup-ddi-intro:1:authored:migration-2f8c2085eed29d47-0 -->The current interface uses `D3D12DDI_FEATURE_VERSION_SHADERCACHE_0118_0` (3), `D3D12DDI_SHADERCACHE_CALLBACKS_0118` and `D3D12DDI_SHADERCACHE_FUNCS_0118`. The callback table contains get/store/unused-value notification; get and store retain their `_CB_0114` signatures. The driver function table contains the runtime-to-driver `pfnShaderCacheGetCaps`. The optional allocation function remains the nested `pCallbackFunc` argument to get, not a separate current driver table slot.<!-- d3d12-review-inline:end:cache-discovery:lookup-ddi-intro:1:authored:migration-2f8c2085eed29d47-0 --></ins>

```cpp
typedef struct D3D12DDI_HANDLE_AND_TYPE
{
    VOID* Handle;
    D3D12DDI_HANDLETYPE Type;
} D3D12DDI_HANDLE_AND_TYPE;
```

```cpp
typedef struct D3D12DDI_SHADER_CACHE_VALUE
{
    _Field_size_bytes_opt_(ValueSize) void* pValue;
    SIZE_T ValueSize;
} D3D12DDI_SHADER_CACHE_VALUE;

typedef VOID* (APIENTRY *PFND3D12DDI_SHADERCACHEALLOCATIONFUNC) (
    SIZE_T SizeInBytes,
    _Inout_opt_ VOID* pContext);
```

```cpp
typedef HRESULT (APIENTRY CALLBACK *PFND3D12DDI_SHADERCACHEGETVALUE_CB_0114)(
    D3D12DDI_HRTDEVICE hRTDevice,
    D3D12DDI_HANDLE_AND_TYPE hRTObject,
    _In_reads_bytes_(KeyLen) const void* pKey,
    SIZE_T KeyLen,
    D3D12DDI_SHADER_CACHE_GET_VALUE_FLAGS Flags,
    _Inout_opt_ D3D12DDI_SHADER_CACHE_VALUE* pObjectCode,
    _Inout_opt_ D3D12DDI_SHADER_CACHE_VALUE* pCompilerMetadata,
    _In_opt_ PFND3D12DDI_SHADERCACHEALLOCATIONFUNC pCallbackFunc,
    _Inout_opt_ void* pContext);

typedef HRESULT(APIENTRY CALLBACK *PFND3D12DDI_SHADERCACHESTOREVALUE_CB_0114)(
    D3D12DDI_HRTDEVICE hRTDevice,
    D3D12DDI_HANDLE_AND_TYPE hRTObject,
    _In_reads_bytes_(KeyLen) const void* pKey,
    SIZE_T KeyLen,
    _In_ CONST D3D12DDI_SHADER_CACHE_VALUE* pObjectCode,
    _In_opt_ CONST D3D12DDI_SHADER_CACHE_VALUE* pCompilerMetadata);
```

<ins><!-- d3d12-review-inline:begin:cache-discovery:lookup-parameters:0:authored:migration-24a94695cdbaf463-0 -->`hRTDevice` identifies the runtime device. A non-null `hRTObject.Handle` for get identifies a PSO (`D3D12DDI_HT_PIPELINE_STATE`) or SO (`D3D12DDI_HT_0054_STATE_OBJECT`) through `hRTObject.Type`. Other non-null get object types return `E_INVALIDARG`. A null get object handle uses device defaults. These are runtime object handles, not per-invocation compiler cache session handles. `pKey` and `KeyLen` describe the driver's compiled value key bytes. The driver supplies valid input storage for the synchronous callback; no database-owned value pointer is handed back.<!-- d3d12-review-inline:end:cache-discovery:lookup-parameters:0:authored:migration-24a94695cdbaf463-0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-discovery:lookup-buffers:0:authored:migration-c875658f57e89b3d-0 -->`pObjectCode` and `pCompilerMetadata` are independently optional get outputs. Each supplied output requests that value kind. With both absent, get performs the legacy untyped lookup without returning value bytes, not a typed any-kind existence query. In the registered read-only PSDB, this probes for object code presence: an entry containing only compiler metadata is a miss and allows the next eligible cache to be searched. This null output probe does not request all typed kinds. For each supplied output, `ValueSize` is the input capacity in bytes and the output stored size. A missing requested type has output size zero. When retrieving values, at least one requested kind must be found for a hit. Finding only an unrequested kind does not satisfy the lookup. A hit on any requested kind does not require all requested kinds to exist and does not assemble missing types from the next cache after a successful first-cache result. A nonzero capacity requires a valid `pValue` buffer. If a found value fits, the runtime copies it into that buffer. With zero capacity and no allocation callback, get reports the required size without copying bytes. With nonzero insufficient capacity, it reports `DXGI_ERROR_MORE_DATA` and the required size. It can still process the other requested type.<!-- d3d12-review-inline:end:cache-discovery:lookup-buffers:0:authored:migration-c875658f57e89b3d-0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-discovery:lookup-allocation:0:authored:migration-0932ce527655de2f-0 -->With zero capacity and `pCallbackFunc` supplied, the runtime calls that allocator synchronously with the found value's byte size and `pContext`, copies the value into the returned storage, and returns its pointer in `pValue`. A null allocation result produces `E_OUTOFMEMORY`. Other outputs can already have been processed. The driver owns the supplied or allocator-returned storage and its deallocation. These callbacks do not expose a runtime value release operation. A failure is not an allocation rollback: the driver must account for allocations already returned by its allocator. Input key/store buffers and allocator context must remain valid for the callback's use through return. Store consumes its key/value bytes synchronously rather than borrowing those input buffers after return. This copy protocol is distinct from the device's retained default session lifetime and does not promise an atomic snapshot across separate probes, fetches or value keys.<!-- d3d12-review-inline:end:cache-discovery:lookup-allocation:0:authored:migration-0932ce527655de2f-0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-discovery:lookup-results:0:authored:migration-7e1cf421e0f0f5cd-0 -->The typed get path returns `S_OK` for a successful lookup/probe, `DXGI_ERROR_NOT_FOUND` for absence, `DXGI_ERROR_MORE_DATA` for insufficient nonzero capacity, `E_OUTOFMEMORY` for allocation failure and `E_INVALIDARG` for invalid arguments. Recognized cache-full, corruption and hash-collision errors can also propagate. Other underlying session failures are mapped to `D3DDDIERR_NOTAVAILABLE`. Store can return `DXGI_ERROR_ALREADY_EXISTS`, `DXGI_ERROR_CACHE_FULL` or `E_OUTOFMEMORY`, as well as invalid-argument and unavailable results. These distinctions matter to the [next-cache search rule](#compiled-value-lookup). They do not define a universal application creation fallback policy.<!-- d3d12-review-inline:end:cache-discovery:lookup-results:0:authored:migration-7e1cf421e0f0f5cd-0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-discovery:lookup-flags:0:authored:migration-85c0e5cc74194f57-0 -->`D3D12DDI_SHADER_CACHE_GET_VALUE_FLAG_NONE` is zero. `D3D12DDI_SHADER_CACHE_GET_VALUE_FLAG_STORED_VALUES_ONLY` is `0x1`. Version 3 additionally defines `D3D12DDI_SHADER_CACHE_GET_VALUE_FLAG_0118_PSDB_MISS_EXPECTED` (`0x2`) for lookup accounting. It does not itself change the selected cache slots. Unrecognized get flags return `E_INVALIDARG`. Cache statistics do not change the returned value's ownership or prove completion of an object from a partial value hit.<!-- d3d12-review-inline:end:cache-discovery:lookup-flags:0:authored:migration-85c0e5cc74194f57-0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-discovery:lookup-legacy:0:authored:migration-f0f959676e19d34f-0 -->[Cached PSO blobs](shader-delivery-and-caching.md#cached-pso-blobs) and [pipeline libraries](shader-delivery-and-caching.md#pipeline-libraries) retain their separate compatibility and loading behavior. A direct reuse path need not perform these cache callbacks.<!-- d3d12-review-inline:end:cache-discovery:lookup-legacy:0:authored:migration-f0f959676e19d34f-0 --></ins>

<a id="runtime-cache-current-roles"></a>

#### Current layouts and role associations

```cpp
typedef union D3D12DDI_VERSION_NUMBER
{
    UINT64 Version;
    UINT16 VersionParts[4];
} D3D12DDI_VERSION_NUMBER;

typedef enum D3D12DDICAPS_TYPE_SHADERCACHE
{
    D3D12DDICAPS_TYPE_SHADERCACHE_ABI_SUPPORT   = 0,
} D3D12DDICAPS_TYPE_SHADERCACHE;

typedef struct D3D12DDIARG_SHADERCACHE_GETCAPS
{
    D3D12DDICAPS_TYPE_SHADERCACHE Type;
    VOID* pInfo;
    VOID* pData;
    UINT DataSize;
} D3D12DDIARG_SHADERCACHE_GETCAPS;

typedef HRESULT (APIENTRY *PFND3D12DDI_SHADERCACHE_GETCAPS)(
    D3D12DDI_HDEVICE hDrvDevice,
    _In_ CONST D3D12DDIARG_SHADERCACHE_GETCAPS* pArgs
    );

typedef enum D3D12DDI_SHADER_CACHE_UNUSED_VALUE_FLAGS
{
    D3D12DDI_SHADER_CACHE_UNUSED_VALUE_FLAG_NONE                           = 0x00000000,

} D3D12DDI_SHADER_CACHE_UNUSED_VALUE_FLAGS;

typedef struct D3D12DDI_SHADERCACHE_ABI_SUPPORT_DATA_0118
{
    WCHAR szAdapterFamily[128];
    UINT64 MinimumABISupportVersion;
    UINT64 MaximumABISupportVersion;
    D3D12DDI_VERSION_NUMBER CompilerVersion;
    D3D12DDI_VERSION_NUMBER ApplicationProfileVersion;
} D3D12DDI_SHADERCACHE_ABI_SUPPORT_DATA_0118;

typedef HRESULT(APIENTRY CALLBACK *PFND3D12DDI_SHADERCACHEUNUSEDVALUE_CB)(
    D3D12DDI_HRTDEVICE hRTDevice,
    D3D12DDI_HANDLE_AND_TYPE hRTObject,
    _In_reads_bytes_(KeySize) const void* pKey,
    SIZE_T KeySize,
    D3D12DDI_SHADER_CACHE_UNUSED_VALUE_FLAGS Flags
    );

typedef struct D3D12DDI_SHADERCACHE_CALLBACKS_0118
{
    PFND3D12DDI_SHADERCACHEGETVALUE_CB_0114   pfnShaderCacheGetValueCb;
    PFND3D12DDI_SHADERCACHESTOREVALUE_CB_0114 pfnShaderCacheStoreValueCb;
    PFND3D12DDI_SHADERCACHEUNUSEDVALUE_CB     pfnShaderCacheUnusedValueCb;
} D3D12DDI_SHADERCACHE_CALLBACKS_0118;

typedef struct D3D12DDI_SHADERCACHE_FUNCS_0118
{
    PFND3D12DDI_SHADERCACHE_GETCAPS             pfnShaderCacheGetCaps;
} D3D12DDI_SHADERCACHE_FUNCS_0118;
```

<ins><!-- d3d12-review-inline:begin:cache-discovery:RC-role-map:0:authored:migration-e5ceba5429fe1ec8-0 -->The current callable roles have distinct directions and ownership:<!-- d3d12-review-inline:end:cache-discovery:RC-role-map:0:authored:migration-e5ceba5429fe1ec8-0 --></ins>

<!-- d3d12-review-alert:begin:cache-discovery:RC-role-map:1:authored:migration-3e6e83fff560476a-0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Current role | Direction | Contract |
> | --- | --- | --- |
> | `D3D12DDI_DEVICE_FUNCS_CORE_0119::pfnImplicitShaderCacheControl` | runtime-to-driver | [Responsibility](shader-delivery-and-caching.md#driver-implicit-cache-control) |
> | `D3D12DDI_SHADERCACHE_CALLBACKS_0118::pfnShaderCacheGetValueCb` | driver-to-runtime | [Responsibility](runtime-cache-discovery.md#runtime-shader-cache-ddi) |
> | `D3D12DDI_SHADERCACHE_CALLBACKS_0118::pfnShaderCacheStoreValueCb` | driver-to-runtime | [Responsibility](runtime-cache-discovery.md#compiled-value-lookup) |
> | `D3D12DDI_SHADERCACHE_CALLBACKS_0118::pfnShaderCacheUnusedValueCb` | driver-to-runtime | [Responsibility](runtime-cache-discovery.md#runtime-cache-unused-value) |
> | `D3D12DDI_SHADERCACHE_FUNCS_0118::pfnShaderCacheGetCaps` | runtime-to-driver | [Responsibility](runtime-cache-discovery.md#runtime-cache-driver-caps) |
> | `PFND3D12DDI_SHADERCACHEGETVALUE_CB_0114::pCallbackFunc` | runtime-to-driver | [Responsibility](runtime-cache-discovery.md#runtime-shader-cache-ddi) |

<!-- d3d12-review-alert:end:cache-discovery:RC-role-map:1:authored:migration-3e6e83fff560476a-0 -->

<a id="runtime-cache-driver-caps"></a>

#### PFND3D12DDI_SHADERCACHE_GETCAPS

<ins><!-- d3d12-review-inline:begin:cache-discovery:RC-driver-caps:0:authored:migration-8c85ca364d8f4f7c-0 -->For `D3D12DDICAPS_TYPE_SHADERCACHE_ABI_SUPPORT`, `pInfo` is null, `pData` addresses `D3D12DDI_SHADERCACHE_ABI_SUPPORT_DATA_0118`, and `DataSize` is its `sizeof`. The header and output storage are borrowed for the call.<!-- d3d12-review-inline:end:cache-discovery:RC-driver-caps:0:authored:migration-8c85ca364d8f4f7c-0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-discovery:RC-driver-caps:1:authored:migration-e114514654bef41f-0 -->On success, the driver fills the family, ABI, compiler and profile fields under the [reporting consistency requirements](#preference-and-reporting).<!-- d3d12-review-inline:end:cache-discovery:RC-driver-caps:1:authored:migration-e114514654bef41f-0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-discovery:RC-driver-caps:2:authored:migration-51a83c83db97ddd3-0 -->The ABI query is mandatory once the current shader caching interface is selected. Failure is reported as `DXGI_ERROR_DRIVER_INTERNAL_ERROR`, not a recoverable cache miss or unsupported-feature fallback. Existing device failure handling still applies.<!-- d3d12-review-inline:end:cache-discovery:RC-driver-caps:2:authored:migration-51a83c83db97ddd3-0 --></ins>

<a id="runtime-cache-unused-value"></a>

#### PFND3D12DDI_SHADERCACHEUNUSEDVALUE_CB

<ins><!-- d3d12-review-inline:begin:cache-discovery:RC-unused-value:0:authored:migration-c13f568af401b0c1-0 -->`pfnShaderCacheUnusedValueCb` reports an unused compiled value hit for a runtime object. The driver supplies `hRTDevice`, the runtime PSO/state object context in `hRTObject`, its key pointer and `KeySize`, and `D3D12DDI_SHADER_CACHE_UNUSED_VALUE_FLAG_NONE` (zero). A null object handle leaves the notification unassociated with an individual object. The driver must supply valid runtime handles and input storage for the synchronous call. The key byte count must fit `UINT_MAX`. Unknown flag bits or a key byte count greater than `UINT_MAX` return `E_INVALIDARG`.<!-- d3d12-review-inline:end:cache-discovery:RC-unused-value:0:authored:migration-c13f568af401b0c1-0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-discovery:RC-unused-value:1:authored:migration-c473c68ee79c71e3-0 -->An accepted unused-value notification returns `S_OK` and updates accounting only. It does not look up or evict the cache entry.<!-- d3d12-review-inline:end:cache-discovery:RC-unused-value:1:authored:migration-c473c68ee79c71e3-0 --></ins>

<a id="delivery-selection-and-reporting"></a>

## Delivery selection and reporting reference

<a id="preference-and-reporting"></a>

### Selection recommendations and driver reporting

<ins><!-- d3d12-review-inline:begin:cache-discovery:preference-scope:0:authored:migration-5f734a37cb1df290-0 -->The following preference applies when an installer or service chooses among compatible outputs to register. It does not add a multi-candidate runtime arbitration algorithm to the default component family/path lookup. Likewise, [application-preferred adapter target filtering](shader-cache-registration.md#target-discovery) is a catalog target discovery contract, not runtime sorting of PSDB files.<!-- d3d12-review-inline:end:cache-discovery:preference-scope:0:authored:migration-5f734a37cb1df290-0 --></ins>

Within the supported range of compatible version numbers, a larger ABI version should be preferred, followed by a larger application profile version.

<ins><!-- d3d12-review-inline:begin:cache-discovery:driver-versions:0 -->`D3D_SHADER_CACHE_COMPILER_PROPERTIES`<!-- d3d12-review-inline:end:cache-discovery:driver-versions:0 --></ins> also indicates the version information that the <ins><!-- d3d12-review-inline:begin:cache-discovery:driver-versions:0:modified:migration-c90242b7e537de4e-1 -->driver's compiler<!-- d3d12-review-inline:end:cache-discovery:driver-versions:0:modified:migration-c90242b7e537de4e-1 --></ins> uses if compiling at application runtime.  It compiles at MaximumABISupportVersion with the indicated CompilerVersion and ApplicationProfileVersion.

CompilerVersion is provided for informational purposes.  It indicates the version of the compiler itself, and may not rev when application profiles do.

<ins><!-- d3d12-review-inline:begin:cache-discovery:profile-reporting:0:modified:migration-4f2204c50ddb9a66-0 -->The driver's `ApplicationProfileVersion`<!-- d3d12-review-inline:end:cache-discovery:profile-reporting:0:modified:migration-4f2204c50ddb9a66-0 --></ins> is determined by inspecting the D3D12DDI_APPLICATION_DESC <ins><!-- d3d12-review-inline:begin:cache-discovery:profile-reporting:0:modified:migration-e7470637af2fa5d7-1 -->retrieved<!-- d3d12-review-inline:end:cache-discovery:profile-reporting:0:modified:migration-e7470637af2fa5d7-1 --></ins> from D3DDDI_QUERYADAPTERTYPE_APPLICATIONDESC.  When the desc is not available or does not match a profile, this value should be zero.  When D3DDDI_QUERYADAPTERTYPE_APPLICATIONSPECIFICDRIVERBLOB is used, the blob should allow returning <ins><!-- d3d12-review-inline:begin:cache-discovery:profile-reporting:0:modified:migration-e7362cacce65f899-2 -->a value<!-- d3d12-review-inline:end:cache-discovery:profile-reporting:0:modified:migration-e7362cacce65f899-2 --></ins> here that is consistent with when the blob was captured for replay scenarios.

<ins><!-- d3d12-review-inline:begin:cache-discovery:reporting-owners:0:authored:migration-d65ca9815ffce294-0 -->The API payload and its field widths remain defined by [D3D12_FEATURE_DATA_SHADERCACHE_ABI_SUPPORT](devices-and-capabilities.md#d3d12_feature_data_shadercache_abi_support). Its [driver/registered compiler reporting requirements](../ShaderCompilerPlugin.md#struct-d3d12ddi_shadercache_abi_support_data) cover family support, maximum ABI support, compiler version equality and profile agreement for the same family and application description. These reporting consistency requirements are separate from stored-PSDB acceptance: the target predicate does not require compiler version equality, and read-only consumption compares the stored and driver profile versions using their high 32 bits. The compiler-side [profile query](offline-compilation.md#id3d12compilerfactory-getapplicationprofileversion) and [published plugin ABI](compiler-plugin-foundation.md#descriptions) retain their distinct declarations.<!-- d3d12-review-inline:end:cache-discovery:reporting-owners:0:authored:migration-d65ca9815ffce294-0 --></ins>

<a id="cache-update-flow"></a>

### Example cache update flow

Below is an example of how a client could check for updates to precompiled caches.   Besides checking cache/driver compatibility on the client, the driver ABI version range is used <ins><!-- d3d12-review-inline:begin:cache-discovery:update-flow:0:authored:source-3da0abe4b046cf58-0-0 -->to <!-- d3d12-review-inline:end:cache-discovery:update-flow:0:authored:source-3da0abe4b046cf58-0-0 --></ins>check for compiler updates:

- Client constructs a url to ask "what's the compiler version of latest cache for ABI version X and Adapter Family Y?" by constructing a URL.
- Server responds compiler version Z by just serving a cached file.
- Client checks "is my cache older than Z?"
- If so, client asks "give me cache version Z for Adapter Family Y" by constructing a URL.
- Server responds with a cached file.
- Client registers with the <ins><!-- d3d12-review-inline:begin:cache-discovery:update-flow:1:preserved-repair:source-8ca5f8a4bd63e4b1-0-0 -->[Shader Cache Registration API](shader-cache-registration.md#installation-and-updates)<!-- d3d12-review-inline:end:cache-discovery:update-flow:1:preserved-repair:source-8ca5f8a4bd63e4b1-0-0 --></ins>.

<a id="device-state-object-statistics"></a>

## Device pipeline and state object creation statistics

```cpp
typedef struct D3D12_CREATE_STATE_OBJECT_STATISTICS
    {
    UINT NumCreated;
    UINT NumPSDBCacheMissed;
    UINT NumTotalCacheMissed;
    UINT NumCacheUnknown;
    } 	D3D12_CREATE_STATE_OBJECT_STATISTICS;

typedef struct D3D12_STATE_OBJECT_STATISTICS
    {
    BOOL DefaultPSDBRegistered;
    D3D12_CREATE_STATE_OBJECT_STATISTICS PipelineStateObjectStatistics;
    D3D12_CREATE_STATE_OBJECT_STATISTICS StateObjectStatistics;
    } 	D3D12_STATE_OBJECT_STATISTICS;
```

**Members**

*NumCreated*

The total number of objects successfully created.

*NumPSDBCacheMissed*

<ins><!-- d3d12-review-inline:begin:cache-discovery:N-shipped-statistics:0 -->The subset of objects successfully created where all required lookups were satisfied by caches observed by the runtime, but not all by a Precompile Shader Database (PSDB). This excludes objects counted in `NumTotalCacheMissed` or `NumCacheUnknown`. Partial PSDB lookup success, such as one shader in a PSO being found in the PSDB, counts here only if the remaining lookups were satisfied by other observed caches.<!-- d3d12-review-inline:end:cache-discovery:N-shipped-statistics:0 --></ins>

*NumTotalCacheMissed*

The subset of objects that were successfully created, but the object was not found in any type of cache, either precompiled or cached by driver from a previous creation. Note that a miss is still counted even if there was a partial lookup success.

*<ins><!-- d3d12-review-inline:begin:cache-discovery:AB-primary-statistics-fields:7:modified:source-8c32d32ea604290f-0-0 -->NumCacheUnknown<!-- d3d12-review-inline:end:cache-discovery:AB-primary-statistics-fields:7:modified:source-8c32d32ea604290f-0-0 --></ins>*

The subset of <ins><!-- d3d12-review-inline:begin:cache-discovery:AB-primary-statistics-fields:8:modified:source-73064286bf2b33ed-0-0 -->objects<!-- d3d12-review-inline:end:cache-discovery:AB-primary-statistics-fields:8:modified:source-73064286bf2b33ed-0-0 --></ins> successfully created where PSDB cache hit status is unknown, see remarks.

**Remarks**

The number of PSDB cache hits in the PSDB can be determined by:

<ins><!-- d3d12-review-inline:begin:cache-discovery:AB-primary-statistics-fields:11 -->`NumPSDBCacheHits = NumCreated - NumPSDBCacheMissed - NumTotalCacheMissed - NumCacheUnknown;`<!-- d3d12-review-inline:end:cache-discovery:AB-primary-statistics-fields:11 --></ins>

The number of cache hits from any cache, including PSDB and local caches:

<ins><!-- d3d12-review-inline:begin:cache-discovery:AB-primary-statistics-fields:13 -->`NumConfirmedHitsInAnyCache = NumCreated - NumTotalCacheMissed - NumCacheUnknown;`<!-- d3d12-review-inline:end:cache-discovery:AB-primary-statistics-fields:13 --></ins>

CacheUnknown indicates that the driver did not try to lookup the created object in the D3D12 runtimes caches.  This is expected on driver versions that do not support Advanced Shader Delivery related DDI.  Those drivers have internal cache mechanisms.  CacheUnknown does not indicate that the object being created was cached or not.

<ins><!-- d3d12-review-inline:begin:cache-discovery:AB-primary-statistics-fields:15 -->When neither a default nor an explicit PSDB is used, each successful creation is counted in `NumPSDBCacheMissed`, `NumTotalCacheMissed` or `NumCacheUnknown`, depending on the observed cache lookup results and driver support. These categories are mutually exclusive.<!-- d3d12-review-inline:end:cache-discovery:AB-primary-statistics-fields:15 --></ins>

### D3D12_STATE_OBJECT_STATISTICS members

*DefaultPSDBRegistered*

<ins><!-- d3d12-review-inline:begin:cache-discovery:DEL-I01-default-availability:0:authored:migration-c303adb94c42f324-0 -->`DefaultPSDBRegistered` indicates whether the device has a default PSDB available.
The default session's [discovery](#default-discovery),
[compatibility](#compatibility) and [opening requirements](#failure-and-lifetime)
define that availability.<!-- d3d12-review-inline:end:cache-discovery:DEL-I01-default-availability:0:authored:migration-c303adb94c42f324-0 --></ins>

*PipelineStateObjectStatistics*

<ins><!-- d3d12-review-inline:begin:cache-discovery:DEL-I01-statistics-groups:0:modified:primary-pipeline-group -->Statistics for Pipeline State Objects created by the device through API like ID3D12Device::CreateGraphicsPipelineState, ID3D12Device::CreateComputePipelineState, and ID3D12Device2::CreatePipelineState.<!-- d3d12-review-inline:end:cache-discovery:DEL-I01-statistics-groups:0:modified:primary-pipeline-group --></ins>

*StateObjectStatistics*

<ins><!-- d3d12-review-inline:begin:cache-discovery:DEL-I01-statistics-groups:1:modified:primary-state-object-group -->Statistics for State Objects created by the device through API like ID3D12Device5::CreateStateObject and ID3D12Device7::AddToStateObject.<!-- d3d12-review-inline:end:cache-discovery:DEL-I01-statistics-groups:1:modified:primary-state-object-group --></ins>

**Remarks**

When DefaultPSDBRegistered is TRUE, a "default" component is registered for the application through the D3DShaderCacheRegistration API.  Additionally, the driver supports Advanced Shader Delivery, and the PSDB matches the adapter family and the supported ABI range of the driver.

<a id="api-id3d12devicestatistics-getstateobjectstatistics"></a>

### ID3D12DeviceStatistics::GetStateObjectStatistics

<ins><!-- d3d12-review-inline:begin:cache-discovery:DEL-I01-interface-acquisition:0:authored:migration-cb906c589e442565-0 -->`ID3D12DeviceStatistics` derives from `IUnknown`. Retrieve it by querying a
device interface for `ID3D12DeviceStatistics`.<!-- d3d12-review-inline:end:cache-discovery:DEL-I01-interface-acquisition:0:authored:migration-cb906c589e442565-0 --></ins>

#### Declaration

```cpp
HRESULT GetStateObjectStatistics(
    D3D12_STATE_OBJECT_STATISTICS *pStatistics);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:cache-discovery:AB-id3d12devicestatistics-getstateobjectstatistics-contract:0:authored:migration-da449a563fda408d-0 -->Retrieves separate PSO and state object creation/cache counters and whether
a default PSDB is registered. Counters describe successfully created objects,
not the number of GPU invocations or cache files on disk.
NumCacheUnknown means the runtime did not observe the required cache lookup;
it proves neither a cache hit nor a miss in an unobserved driver cache.
Concurrent changes need not form a transactionally consistent cross-counter
snapshot.<!-- d3d12-review-inline:end:cache-discovery:AB-id3d12devicestatistics-getstateobjectstatistics-contract:0:authored:migration-da449a563fda408d-0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:cache-discovery:AB-id3d12devicestatistics-getstateobjectstatistics-contract:2:authored:migration-0a3016353db24229-0 -->`pStatistics` receives D3D12_STATE_OBJECT_STATISTICS, with DefaultPSDBRegistered and the two D3D12_CREATE_STATE_OBJECT_STATISTICS groups.<!-- d3d12-review-inline:end:cache-discovery:AB-id3d12devicestatistics-getstateobjectstatistics-contract:2:authored:migration-0a3016353db24229-0 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:cache-discovery:AB-id3d12devicestatistics-getstateobjectstatistics-contract:4:authored:migration-875d712334f74760-0 -->Returns `S_OK` on retrieval or the applicable failure.<!-- d3d12-review-inline:end:cache-discovery:AB-id3d12devicestatistics-getstateobjectstatistics-contract:4:authored:migration-875d712334f74760-0 --></ins>

#### Concurrent observations

Individual statistic counters are atomically updated, but each group of statistics is not synchronized with the API they represent.  For example, if calling ID3D12Device2::CreatePipelineState simultaneously with this API, you may retrieve statistics in between updating the PipelineStateObjectStatistics object creation counter and the miss counter.  If simultaneous statistics retrieval is required, it must be externally synchronized.
