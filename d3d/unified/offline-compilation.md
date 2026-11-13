<a id="offline-compilation"></a>

# Offline compilation

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

<!-- d3d12-review-alert:begin:compiler-foundation:scope:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Offline driver/pipeline compilation produces vendor-dependent pipeline state
> and state object output from creation descriptions and shader bytecode. It is
> distinct from HLSL frontend compilation.

<!-- d3d12-review-alert:end:compiler-foundation:scope:0 -->

<!-- d3d12-review-alert:begin:compiler-foundation:scope:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The compiler API reference proceeds from factory and target queries below to
> [invocation and cache output](compiler-invocation-and-cache-output.md).
> The [plugin DDI](compiler-plugin-foundation.md) is the implementer-facing reference.

<!-- d3d12-review-alert:end:compiler-foundation:scope:1 -->

<a id="motivation"></a>

<a id="compiler-runtime-design"></a>

## Compiler runtime design

<ins><!-- d3d12-review-inline:begin:compiler-foundation:design-foundation:0 -->GPU hardware vendors expose compilers in an [IHV Compiler Plugin](compiler-plugin-foundation.md) dll via a [Plugin DDI](compiler-plugin-foundation.md#compiler-plugin-foundation).<!-- d3d12-review-inline:end:compiler-foundation:design-foundation:0 --></ins>

The <ins><!-- d3d12-review-inline:begin:compiler-foundation:design-foundation:1 -->[Microsoft Compiler Runtime](#availability)<!-- d3d12-review-inline:end:compiler-foundation:design-foundation:1 --></ins> <ins><!-- d3d12-review-inline:begin:compiler-foundation:design-foundation:1 -->wraps<!-- d3d12-review-inline:end:compiler-foundation:design-foundation:1 --></ins> these plugins with an <ins><!-- d3d12-review-inline:begin:compiler-foundation:design-foundation:1 -->[API](#exports)<!-- d3d12-review-inline:end:compiler-foundation:design-foundation:1 --></ins> <ins><!-- d3d12-review-inline:begin:compiler-foundation:design-foundation:1 -->in D3D12StateObjectCompiler.dll<!-- d3d12-review-inline:end:compiler-foundation:design-foundation:1 --></ins> to expose functionality to Independent Software Vendors(ISVs).

<a id="availability"></a>

## Compiler availability and independence

IHVs should ship their compilers via their websites in a fashion similar to how drivers are shipped so it can be publicly downloaded by ISVs.  Plugins are also direct submitted to the compiler service.  Submitting compilers before driver release allows time for compilation before they are needed on client systems.
Microsoft makes the compiler API and command line tool available in a fashion similar to how the DirectX Agility SDK is shipped so it can be publicly downloaded.

The Plugin DDI is separate from the D3D12 Usermode DDI to support factoring compilers out of drivers into separate components:

- Compiler plugins must be usable without a hardware adapter present to support cloud compilation
- Compilers have historically been tightly coupled with D3D Usermode drivers and may not currently have a firm versioning boundary between the two.  It hasn't been necessary to understand if a driver change specifically impacts compiled State Objects.  As a result, any driver revision results in invalidated shader caches.  Drivers can be updated as frequently as every 2-3 weeks which can represent a lot of cost in a cloud delivered shader cache solution. The intent is to evolve compilers toward being an independent versioned component where compiled output changes are understood and decouple driver update cadence from compiler cadence to avoid invalidating shaders at this rate.

<ins><!-- d3d12-review-inline:begin:compiler-foundation:independence:2 -->The plugin DDI may be implemented with the usermode DDI, but it must not require the usermode driver to be installed or an adapter to be present.<!-- d3d12-review-inline:end:compiler-foundation:independence:2 --></ins>

The Microsoft API is nano-COM and exposes compiling and caching functionality to end users like ISVs and the cloud compilation service.  It allows callers to enumerate and create compilers.

<!-- d3d12-review-alert:begin:compiler-foundation:factory-identity:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12CompilerCreateFactory` is an export of `D3D12StateObjectCompiler.dll`.
> It creates an `ID3D12CompilerFactory` for the compiler plugin DLL named by the
> caller. That COM factory is not an `ID3D12DeviceFactory`, a physical adapter,
> or an HLSL frontend compiler. Factory creation loads executable plugin code;
> the DLL path is not a data-only input or an authenticity credential.

<!-- d3d12-review-alert:end:compiler-foundation:factory-identity:0 -->

<!-- d3d12-review-alert:begin:compiler-foundation:factory-identity:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `ID3D12CompilerFactory` and `ID3D12CompilerFactoryChild` derive from `IUnknown`.
> Returned interface references are owned
> references that the caller releases. Each factory child retains its factory;
> releasing the caller's original factory reference does not invalidate a living
> child. The plugin module remains loaded while the factory that owns its DDI
> object is alive. The compiler runtime module must remain available while its
> objects or returned blob implementations are in use.

<!-- d3d12-review-alert:end:compiler-foundation:factory-identity:1 -->

<!-- d3d12-review-alert:begin:compiler-foundation:factory-identity:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Factory/target discovery does not establish the presence of a matching physical
> adapter or device support for a pipeline. Compiler host capabilities describe
> the selected target; actual runtime construction retains the capability rules
> of [pipeline state creation](pipeline-state.md) and
> [state object creation](state-objects.md#createstateobject).

<!-- d3d12-review-alert:end:compiler-foundation:factory-identity:2 -->

<a id="version-domains"></a>

## Version domains

<a id="plugin-ddi-version"></a>

### Plugin DDI version

The compiler plugin DDI is independently versioned from the D3D12 Usermode DDI, but with a similar scheme.  This allows for compiler specific changes to not impact the D3D12 Runtime development.  <ins><!-- d3d12-review-inline:begin:compiler-foundation:versioning:0 -->It consists of<!-- d3d12-review-inline:end:compiler-foundation:versioning:0 --></ins> 4 16bit parts packed into a UINT64 number:

MAJOR.MINOR.BUILD.REVISION

```cpp
PLUGIN_INTERFACE_VERSION = (MAJOR << 16) | MINOR
PLUGIN_DDI_VERSION = (((UINT64)PLUGIN_INTERFACE_VERSION) << 32) | ((UINT64)((BUILD << 16) | REVISION))
```

The plugin reports the list of compiler plugin versions it supports.  The compiler runtime selects one of these and reports that version to the driver as the version that is used.

<a id="associated-usermode-ddi"></a>

### Associated usermode DDI version

The State Object Compiler shares the following concepts with the D3D12 runtime:

- Pipeline State Object Descriptions
- State Object Descriptions
- Some capability checks impacting the above.

New changes to these concepts must be first introduced in the D3D12 runtime.  Each Compiler DDI version has exactly one usermode DDI version associated with it at design time to define which version of these shared concepts apply.  For clarity, the compiler runtime will set this version to the driver along with the plugin version chosen.  Plugins must only report plugin DDI versions when they can support the associated Usermode DDI version.  The compiler plugin must introduce a new plugin DDI version <ins><!-- d3d12-review-inline:begin:compiler-foundation:shared-concepts:2 -->associated with the Usermode DDI<!-- d3d12-review-inline:end:compiler-foundation:shared-concepts:2 --></ins> to expose it.

<a id="package-version"></a>

### Package version

<ins><!-- d3d12-review-inline:begin:compiler-foundation:package:0 -->The package version updates<!-- d3d12-review-inline:end:compiler-foundation:package:0 --></ins> anytime anything in the compiler package changes, including when compiler versions, adapter families, ABI or application profile version changes.  <ins><!-- d3d12-review-inline:begin:compiler-foundation:package:0 -->This concept is shared<!-- d3d12-review-inline:end:compiler-foundation:package:0 --></ins> with any <ins><!-- d3d12-review-inline:begin:compiler-foundation:package:0 -->services performing compilation<!-- d3d12-review-inline:end:compiler-foundation:package:0 --></ins> and is not represented in API.

<a id="adapter-families"></a>

### Adapter families

IHVs define Adapter Families with a string identifier to indicate a grouping of adapters that can share precompiled shaders.  A plugin indicates a [compiler version](#adapter-family-compiler-version) per adapter family that's rev'd with changes impacting that adapter family such as bug fixes, performance optimizations, etc.  The plugin can also support a range of ABI versions to indicate compatibility with drivers.  A newer compiler version can target an older ABI.

<a id="adapter-family-compiler-version"></a>

### Adapter family compiler version

A plugin reports a single compiler version per adapter family that revises with plugin changes that impact that adapter family, such as bug fixes, code generation changes, etc.  The version is a 64 bit encoding of four 16bit values to define a four part version as Major.Minor.Build.Revision.  <ins><!-- d3d12-review-inline:begin:compiler-foundation:compiler-version:0 -->Application specific<!-- d3d12-review-inline:end:compiler-foundation:compiler-version:0 --></ins> profile settings or application targeted changes should rev the [Application Profile Version](#application-profile-version) instead.

A version change for an adapter family is an indication that compiled output may change.  If it changes in an incompatible way, the ABI version should also be rev'd. The version scheme should indicate the severity of the change.

Major/Minor version change for "must" recompile such as security or major fixes.  Build for "should" recompile such as performance.  Revision for less consequential changes that shouldn't invalidate caches.

<a id="adapter-family-abi-version"></a>

### Adapter family ABI version

Adapter families have an ABI version that can rev when there are breaking changes.  IHVs assign each adapter to a family and report which family an adapter belongs to with a supported ABI range from the Usermode DDI.  IHVs also enumerate which ABI Versions are supported by an adapter family.

This scheme also allows for deprecating support for some of the adapters in an adapter family by rev'ing the ABI version and changing the adapter family association.

<a id="application-profile-version"></a>

### Application profile version

Drivers often have application specific profiles for optimization or targeted bug fixes.  If settings for a specific app or a few apps are changed, that can be communicated without versioning the compiler and impacting the cache for all applications.

<a id="capability-queries"></a>

### Capability queries

The State Object Compiler queries certain caps to facilitate processing API state object descriptions to DDI descriptions.  State object arguments and other parameters re-use DDI structures to support common implementation between compilers and drivers.  The Usermode DDI version associated with the State Object Plugin DDI version dictates which version of these structures and behavior to use.

<!-- d3d12-review-alert:begin:compiler-foundation:distinct-domains:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Package version, plugin DDI version, associated usermode DDI version, adapter
> family compiler version, compiler target ABI version, application version and
> application profile version are distinct domains. Equality or numerical ordering
> between different domains has no compatibility meaning.

<!-- d3d12-review-alert:end:compiler-foundation:distinct-domains:0 -->

<!-- d3d12-review-alert:begin:compiler-foundation:distinct-domains:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The canonical [D3D12_VERSION_NUMBER encoding](state-object-databases-and-identity.md#d3d12_version_number)
> defines compiler/profile/application four-part numbers. It also defines the
> little-endian `VersionParts` overlay. An adapter family ABI is instead a `UINT64`
> counter, not a packed application or compiler version.

<!-- d3d12-review-alert:end:compiler-foundation:distinct-domains:1 -->

<!-- d3d12-review-alert:begin:compiler-foundation:distinct-domains:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The plugin's enumerated set of target ABIs can be sparse.
> The device's [SHADERCACHE_ABI_SUPPORT query](devices-and-capabilities.md#d3d12_feature_data_shadercache_abi_support)
> reports an inclusive minimum/maximum range for the installed driver. It does
> not turn a compiler's enumerated set into an inclusive range. A family index
> identifies an entry within this factory's plugin enumeration, not a DXGI adapter
> ordinal or a persistent cross-plugin identifier.

<!-- d3d12-review-alert:end:compiler-foundation:distinct-domains:2 -->

<a id="targets"></a>

## Target and application descriptors

<a id="d3d12_adapter_family"></a>

### D3D12_ADAPTER_FAMILY

```cpp
typedef struct D3D12_ADAPTER_FAMILY
{
    WCHAR szAdapterFamily[128];
} D3D12_ADAPTER_FAMILY;
```

<!-- d3d12-review-alert:begin:compiler-foundation:family-type:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The structure contains only the inline adapter family name.
> There is no `CompilerVersion` member. The compiler version query below returns
> that version separately. `szAdapterFamily` has capacity for 128 `WCHAR` elements,
> including string termination. It is not a pointer to separately allocated
> storage and has no input length parameter.

<!-- d3d12-review-alert:end:compiler-foundation:family-type:1 -->

<ins><!-- d3d12-review-inline:begin:compiler-foundation:family-semantics:0 -->`szAdapterFamily` uniquely identifies an adapter family<!-- d3d12-review-inline:end:compiler-foundation:family-semantics:0 --></ins> for a hardware vendor.

<ins><!-- d3d12-review-inline:begin:compiler-foundation:family-output:0 -->An adapter family is a set of adapters that all share the same compiled output for a given ABI version.<!-- d3d12-review-inline:end:compiler-foundation:family-output:0 --></ins>

<a id="d3d12_compiler_target"></a>

### D3D12_COMPILER_TARGET

```cpp
typedef struct D3D12_COMPILER_TARGET
{
    UINT AdapterFamilyIndex;
    UINT64 ABIVersion;
} D3D12_COMPILER_TARGET;
```

**Members**

*AdapterFamilyIndex*

The index of the adapter family to target.  See <ins><!-- d3d12-review-inline:begin:compiler-foundation:target:3 -->[D3D12_ADAPTER_FAMILY](#d3d12_adapter_family)<!-- d3d12-review-inline:end:compiler-foundation:target:3 --></ins> and <ins><!-- d3d12-review-inline:begin:compiler-foundation:target:3 -->[ID3D12CompilerFactory::EnumerateAdapterFamilies](#id3d12compilerfactory-enumerateadapterfamilies)<!-- d3d12-review-inline:end:compiler-foundation:target:3 --></ins>.

*ABIVersion*

<ins><!-- d3d12-review-inline:begin:compiler-foundation:target:5 -->The target ABI version for the adapter family.<!-- d3d12-review-inline:end:compiler-foundation:target:5 --></ins>  See Remarks.

**Remarks**

An ABIVersion of zero targets the latest ABIVersion available.

<!-- d3d12-review-alert:begin:compiler-foundation:target-resolution:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> For `GetApplicationProfileVersion`, zero requests the greatest supported ABI
> value for that adapter family, resolved from the enumerated set. The runtime
> does not pass zero to the plugin as an actual target ABI. A nonzero ABI must be
> a member of that set. It is not rounded or replaced with a nearby version.
> The caller's descriptor is an input and is not rewritten.

<!-- d3d12-review-alert:end:compiler-foundation:target-resolution:0 -->

<!-- d3d12-review-alert:begin:compiler-foundation:target-resolution:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The application description and version types have their canonical definitions
> in [D3D12_APPLICATION_DESC](state-object-databases-and-identity.md#d3d12_application_desc)
> and [D3D12_VERSION_NUMBER](state-object-databases-and-identity.md#d3d12_version_number).
> For the profile query, supply the target application's required null-terminated
> executable filename and title, application version, optional null-terminated
> engine name (`nullptr` when not applicable), and engine version when an engine
> name is supplied. The process hosting the offline compiler does not supply an
> implicit executable name fallback. These inputs and all referenced strings must
> remain readable during the call. This query does not transfer their ownership.

<!-- d3d12-review-alert:end:compiler-foundation:target-resolution:1 -->

<!-- d3d12-review-alert:begin:compiler-foundation:D138-discovered-target-context:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> [Registration target discovery](shader-cache-registration.md#target-discovery) supplies adapter-side ABI intervals and compiler/profile information for installation planning. Its application-dependent preference rules and device/adapter explorer context are defined there. The compiler factory's family indices, supported ABI enumeration and explicit target selection below remain distinct.

<!-- d3d12-review-alert:end:compiler-foundation:D138-discovered-target-context:0 -->

<!-- d3d12-review-alert:begin:compiler-foundation:D144-runtime-version-roles:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> [Runtime PSDB compatibility](runtime-cache-discovery.md#compatibility) applies the driver's inclusive ABI interval and high-32-bit application profile comparison to stored content. This is distinct from enumerating compiler-supported ABIs or resolving an explicit zero-ABI compiler target.

<!-- d3d12-review-alert:end:compiler-foundation:D144-runtime-version-roles:0 -->

<a id="exports"></a>

## Factory export and root signature helper

<a id="d3d12compilercreatefactory"></a>

### D3D12CompilerCreateFactory

#### Declaration

```cpp
HRESULT D3D12CompilerCreateFactory(
    LPCWSTR pPluginCompilerDllPath,
    REFIID riid,
    void** ppFactory);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:compiler-foundation:factory-summary:0 -->Creates the compiler factory<!-- d3d12-review-inline:end:compiler-foundation:factory-summary:0 --></ins> with interfaces for creating compilers and checking capabilities.

#### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-foundation:factory-params:0 -->`[in] pPluginCompilerDllPath`<!-- d3d12-review-inline:end:compiler-foundation:factory-params:0 --></ins>

The path to the plugin compiler dll used for this instance of the factory.

<ins><!-- d3d12-review-inline:begin:compiler-foundation:factory-params:2 -->`[in] riid`<!-- d3d12-review-inline:end:compiler-foundation:factory-params:2 --></ins>

The globally unique identifier (GUID) for the compiler factory interface.

<ins><!-- d3d12-review-inline:begin:compiler-foundation:factory-params:4 -->`[out] ppFactory`<!-- d3d12-review-inline:end:compiler-foundation:factory-params:4 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-foundation:factory-params:5 -->On success, an owned pointer to the compiler factory interface specified by riid.<!-- d3d12-review-inline:end:compiler-foundation:factory-params:5 --></ins>

<!-- d3d12-review-alert:begin:compiler-foundation:factory-loading:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pPluginCompilerDllPath` must identify the plugin DLL with a readable,
> null-terminated wide string. Loading the module, locating its
> `D3D12OpenCompilerDDI` export, opening it and negotiating a common plugin DDI
> version occur as part of factory creation. Loader and plugin open/negotiation
> failures can therefore fail the factory export before an interface is returned.
> No matching adapter installation is required.

<!-- d3d12-review-alert:end:compiler-foundation:factory-loading:0 -->

<!-- d3d12-review-alert:begin:compiler-foundation:factory-loading:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `ppFactory` is not a successful null output availability probe. A caller
> requesting a factory must supply writable interface pointer storage. A failure
> before the interface query does not guarantee that this storage has been
> cleared; no returned interface may be consumed after failure.

<!-- d3d12-review-alert:end:compiler-foundation:factory-loading:1 -->

#### Return values

Expected return codes (not exhaustive):

<!-- d3d12-review-alert:begin:compiler-foundation:factory-results:1 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Error Code | Description|
> | :----------| :----------|
> | S_OK | Success. |
> | E_NOINTERFACE | The specified riid is not recognized. |
> | E_INVALIDARG | Invalid arguments specified. |
> | E_OUTOFMEMORY | Unable to create compiler factory due to memory allocation failure. |
> | HRESULT_FROM_WIN32(ERROR_FILE_NOT_FOUND) | pPluginCompilerDllPath does not point to a file. |

<!-- d3d12-review-alert:end:compiler-foundation:factory-results:1 -->

<!-- d3d12-review-alert:begin:compiler-foundation:factory-more-results:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> If there is no common plugin DDI version, factory creation returns
> `DXGI_ERROR_UNSUPPORTED`.
> Windows module-loading and missing-export failures return the corresponding
> failure `HRESULT`. The file-not-found row is not an exhaustive loader error
> contract. Plugin opening, version negotiation and table registration failures
> are propagated. If the final interface query is reached, a null `ppFactory`
> returns `E_POINTER`; earlier loading/negotiation can fail first.
> `S_OK` means that the requested interface was returned, not that a physical
> adapter or a future compilation is available.

<!-- d3d12-review-alert:end:compiler-foundation:factory-more-results:0 -->

<a id="d3d12compilerserializeversionedrootsignature"></a>

### D3D12CompilerSerializeVersionedRootSignature

#### Declaration

```cpp
HRESULT D3D12CompilerSerializeVersionedRootSignature(
    const D3D12_VERSIONED_ROOT_SIGNATURE_DESC* pRootSignature,
    ID3DBlob** ppBlob,
    ID3DBlob** ppErrorBlob);
```

#### Behavior

<!-- d3d12-review-alert:begin:compiler-foundation:serializer:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Serializes a versioned root signature description into an `ID3DBlob` for
> compiler host inputs. This is the compiler runtime export
> `D3D12CompilerSerializeVersionedRootSignature`, not an alias or renamed
> declaration of the ordinary runtime's
> [D3D12SerializeVersionedRootSignature](binding.md#d3d12serializeversionedrootsignature).
> Root signature structures, contents and root binding retain their
> [canonical contract](binding.md#root-signatures).

<!-- d3d12-review-alert:end:compiler-foundation:serializer:0 -->

<!-- d3d12-review-alert:begin:compiler-foundation:serializer:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Serialization does not create an `ID3D12RootSignature`, require an IHV compiler
> plugin or establish that a particular device supports the serialized contents.
> The compiler host serializer accepts the reserved register space forms used
> by tools. That acceptance does not grant ordinary device creation permission.
> Local root signatures, mesh-related flags, descriptor heap 64-bit atomics,
> static sampler flags and non-normalized sampling are validated in the
> compiler host context rather than against an instantiated physical device.

<!-- d3d12-review-alert:end:compiler-foundation:serializer:1 -->

#### Parameters

<!-- d3d12-review-alert:begin:compiler-foundation:serializer-params:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `[in] pRootSignature`

<!-- d3d12-review-alert:end:compiler-foundation:serializer-params:0 -->

<!-- d3d12-review-alert:begin:compiler-foundation:serializer-params:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A required pointer to `D3D12_VERSIONED_ROOT_SIGNATURE_DESC`. Its version selects
> the corresponding description; versions 1.0, 1.1 and 1.2 are supported. Its
> referenced arrays and strings must be readable for the call.

<!-- d3d12-review-alert:end:compiler-foundation:serializer-params:1 -->

<!-- d3d12-review-alert:begin:compiler-foundation:serializer-params:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `[out] ppBlob`

<!-- d3d12-review-alert:end:compiler-foundation:serializer-params:2 -->

<!-- d3d12-review-alert:begin:compiler-foundation:serializer-params:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Required writable storage for the returned serialized blob interface.
> On success the caller owns the reference and releases it when no longer
> needed. Blob data is accessed with `GetBufferPointer` and `GetBufferSize`;
> the size is in bytes and the storage is valid while the blob remains alive.
> Passing `nullptr` is invalid. It is not a size query.

<!-- d3d12-review-alert:end:compiler-foundation:serializer-params:3 -->

<!-- d3d12-review-alert:begin:compiler-foundation:serializer-params:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `[out, optional] ppErrorBlob`

<!-- d3d12-review-alert:end:compiler-foundation:serializer-params:4 -->

<!-- d3d12-review-alert:begin:compiler-foundation:serializer-params:5 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Optional writable storage for an error message blob. When supplied for a valid
> serialization call, it receives an owned blob containing diagnostics or
> `nullptr` if there are none. Release any returned error blob even when
> serialization fails. `nullptr` suppresses this returned diagnostic object;
> it does not suppress validation.

<!-- d3d12-review-alert:end:compiler-foundation:serializer-params:5 -->

#### Return values

<!-- d3d12-review-alert:begin:compiler-foundation:serializer-results:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` returns the serialized blob. A null description or null `ppBlob` returns
> `E_INVALIDARG`. Invalid descriptions, including unsupported root signature
> versions, fail. The compiler host wrapper maps the serializer's `E_FAIL`
> validation result to `E_INVALIDARG`. Allocation failures can return
> `E_OUTOFMEMORY`.

<!-- d3d12-review-alert:end:compiler-foundation:serializer-results:0 -->

<!-- d3d12-review-alert:begin:compiler-foundation:serializer-results:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> After valid required pointers have been checked, `*ppBlob` and, when supplied,
> `*ppErrorBlob` are initialized to `nullptr` before validation. Invalid required
> pointers do not establish initialized outputs. A diagnostic blob is not
> guaranteed for every failure. Output blob size is not available through a
> null output probe.

<!-- d3d12-review-alert:end:compiler-foundation:serializer-results:1 -->

<a id="queries"></a>

## Family, ABI and profile queries

<a id="id3d12compilerfactory-enumerateadapterfamilies"></a>

### ID3D12CompilerFactory::EnumerateAdapterFamilies

#### Declaration

```cpp
HRESULT EnumerateAdapterFamilies(
    UINT AdapterFamilyIndex,
    D3D12_ADAPTER_FAMILY* pAdapterFamily);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:compiler-foundation:enumerate-family-summary:0 -->Retrieve an adapter family supported by the plugin.<!-- d3d12-review-inline:end:compiler-foundation:enumerate-family-summary:0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-foundation:enumerate-family-params:0 -->`[in] AdapterFamilyIndex`<!-- d3d12-review-inline:end:compiler-foundation:enumerate-family-params:0 --></ins>

The index of the adapter family to enumerate.

<ins><!-- d3d12-review-inline:begin:compiler-foundation:enumerate-family-params:2 -->`[out] pAdapterFamily`<!-- d3d12-review-inline:end:compiler-foundation:enumerate-family-params:2 --></ins>

The adapter family at Index.  See <ins><!-- d3d12-review-inline:begin:compiler-foundation:enumerate-family-params:3 -->[D3D12_ADAPTER_FAMILY](#d3d12_adapter_family)<!-- d3d12-review-inline:end:compiler-foundation:enumerate-family-params:3 --></ins>.

<!-- d3d12-review-alert:begin:compiler-foundation:enumerate-family-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Indices are contiguous starting at zero. `pAdapterFamily` must point to writable
> storage for the complete fixed-size structure. The caller neither supplies a
> name capacity nor frees separate string storage. A null output returns
> `E_INVALIDARG` and is not a count query.

<!-- d3d12-review-alert:end:compiler-foundation:enumerate-family-contract:0 -->

#### Return values

<!-- d3d12-review-alert:begin:compiler-foundation:enumerate-family-results:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A successful query returns the family at the index. An index beyond the
> available families returns `DXGI_ERROR_NOT_FOUND`. The name storage is cleared
> before the plugin query and is filled on success. Other plugin failures are
> returned as failures, not treated as end-of-list.

<!-- d3d12-review-alert:end:compiler-foundation:enumerate-family-results:0 -->

#### Example

<!-- d3d12-review-alert:begin:compiler-foundation:enumeration-example-context:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pFactory` in the following enumeration example is an `ID3D12CompilerFactory*` returned by `D3D12CompilerCreateFactory`.

<!-- d3d12-review-alert:end:compiler-foundation:enumeration-example-context:0 -->

<ins><!-- d3d12-review-inline:begin:compiler-foundation:family-example:0 -->Example of enumerating all adapter families:<!-- d3d12-review-inline:end:compiler-foundation:family-example:0 --></ins>

```cpp
D3D12_ADAPTER_FAMILY adapterFamily = {};
for (UINT i = 0; ; ++i)
{
    const HRESULT hr = pFactory->EnumerateAdapterFamilies(i, &adapterFamily);
    if (hr == DXGI_ERROR_NOT_FOUND) break;
    if (FAILED(hr)) { /* Handle the failure; do not consume adapterFamily. */ break; }
    // Consume adapterFamily.
}
```

<a id="id3d12compilerfactory-enumerateadapterfamilyabiversions"></a>

### ID3D12CompilerFactory::EnumerateAdapterFamilyABIVersions

#### Declaration

```cpp
HRESULT EnumerateAdapterFamilyABIVersions(
    UINT AdapterFamilyIndex,
    UINT32* pNumABIVersions,
    UINT64* pABIVersions);
```

#### Behavior

Retrieve the list of ABI versions supported for an adapter family.

#### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-params:0 -->`[in] AdapterFamilyIndex`<!-- d3d12-review-inline:end:compiler-foundation:abi-params:0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-params:1 -->The index of the adapter family to query for supported ABI versions.  See [D3D12_ADAPTER_FAMILY](#d3d12_adapter_family) and [ID3D12CompilerFactory::EnumerateAdapterFamilies](#id3d12compilerfactory-enumerateadapterfamilies).<!-- d3d12-review-inline:end:compiler-foundation:abi-params:1 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-params:2 -->`[in, out] pNumABIVersions`<!-- d3d12-review-inline:end:compiler-foundation:abi-params:2 --></ins>

On input, <ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-params:3 -->describes the capacity of pABIVersions in UINT64 elements<!-- d3d12-review-inline:end:compiler-foundation:abi-params:3 --></ins>.  <ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-params:3 -->`*pNumABIVersions` is zero<!-- d3d12-review-inline:end:compiler-foundation:abi-params:3 --></ins> when pABIVersions is nullptr.  This may be used to retrieve a partial list, <ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-params:3 -->see the buffer rules below<!-- d3d12-review-inline:end:compiler-foundation:abi-params:3 --></ins>.  On output, returns the number of ABI Versions <ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-params:3 -->for the adapter family<!-- d3d12-review-inline:end:compiler-foundation:abi-params:3 --></ins>.

<ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-params:4 -->`[out, optional] pABIVersions`<!-- d3d12-review-inline:end:compiler-foundation:abi-params:4 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-params:5 -->Receives<!-- d3d12-review-inline:end:compiler-foundation:abi-params:5 --></ins> the list of ABI Versions <ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-params:5 -->for the adapter family<!-- d3d12-review-inline:end:compiler-foundation:abi-params:5 --></ins>.  May be nullptr when performing a size check.

<ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-remarks:0 -->Returns the<!-- d3d12-review-inline:end:compiler-foundation:abi-remarks:0 --></ins> compiler ABI version supported by the compiled binaries produced by this compiler.  This is compared with the supported ABI range of a driver to understand if precompiled binaries are supported.

Compiled objects produced by this compiler at a target ABI version may not be used with drivers that do not report this ABI version in their supported ABI version range.

ABI version is used to check for precompiled cache updates and understand cache compatibility with drivers on the client, see <ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-remarks:2 -->[Version domains](#version-domains)<!-- d3d12-review-inline:end:compiler-foundation:abi-remarks:2 --></ins>.

#### Return values and buffer rules

<!-- d3d12-review-alert:begin:compiler-foundation:abi-results:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pNumABIVersions` is required. A null pointer returns `E_INVALIDARG`.
> For a size query, pass `*pNumABIVersions == 0` and
> `pABIVersions == nullptr`. For a valid family the query returns `S_OK` and the
> required element count. A valid family must provide at least one ABI.

<!-- d3d12-review-alert:end:compiler-foundation:abi-results:0 -->

<!-- d3d12-review-alert:begin:compiler-foundation:abi-results:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> For an array query, the input count is the writable capacity in `UINT64`
> elements, not bytes. With sufficient capacity, the plugin copies the complete
> list, updates the count to the number of supported versions and returns `S_OK`.
> With insufficient capacity, it copies as many elements as fit, reports the full
> required count and returns `DXGI_ERROR_MORE_DATA`. The returned count is then
> greater than the number of valid copied elements. A nonnull zero-capacity buffer
> does not request a successful size-only query. A null array with nonzero input
> capacity is invalid.

<!-- d3d12-review-alert:end:compiler-foundation:abi-results:1 -->

<!-- d3d12-review-alert:begin:compiler-foundation:abi-results:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Zero and `UINT64_MAX` are reserved and must not be enumerated. The initial
> ABI is 1. A breaking ABI change increments the counter. The set need not include
> all values between the smallest and largest returned ABI.

<!-- d3d12-review-alert:end:compiler-foundation:abi-results:2 -->

<!-- d3d12-review-alert:begin:compiler-foundation:abi-results:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> ABI versions must be returned in descending order, newest first. The latest
> supported ABI is at `pABIVersions[0]`. A one-element array query retrieves that
> latest ABI. When more than one ABI is supported, it returns
> `DXGI_ERROR_MORE_DATA` and the full count while providing that first element.

<!-- d3d12-review-alert:end:compiler-foundation:abi-results:3 -->

<!-- d3d12-review-alert:begin:compiler-foundation:abi-results:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> If the adapter family is invalid and `pNumABIVersions` is valid, the operation
> must return `DXGI_ERROR_NOT_FOUND` and set `*pNumABIVersions` to zero.
> For a valid family and valid count pointer, the count reports the family's
> correct number of ABI versions on return, regardless of other success/failure.
> Only the documented copied prefix of a short-buffer result may be consumed;
> other failure outputs must not be consumed as ABI results.

<!-- d3d12-review-alert:end:compiler-foundation:abi-results:4 -->

<a id="id3d12compilerfactory-enumerateadapterfamilycompilerversion"></a>

### ID3D12CompilerFactory::EnumerateAdapterFamilyCompilerVersion

#### Declaration

```cpp
HRESULT EnumerateAdapterFamilyCompilerVersion(
    UINT AdapterFamilyIndex,
    D3D12_VERSION_NUMBER* pCompilerVersion);
```

#### Behavior

Describes the version of a compiler for an adapter family.

#### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-foundation:compiler-version-params:0 -->`[in] AdapterFamilyIndex`<!-- d3d12-review-inline:end:compiler-foundation:compiler-version-params:0 --></ins>

The index of the adapter family <ins><!-- d3d12-review-inline:begin:compiler-foundation:compiler-version-params:1 -->to query for its compiler version<!-- d3d12-review-inline:end:compiler-foundation:compiler-version-params:1 --></ins>.  See <ins><!-- d3d12-review-inline:begin:compiler-foundation:compiler-version-params:1 -->[D3D12_ADAPTER_FAMILY](#d3d12_adapter_family)<!-- d3d12-review-inline:end:compiler-foundation:compiler-version-params:1 --></ins> and <ins><!-- d3d12-review-inline:begin:compiler-foundation:compiler-version-params:1 -->[ID3D12CompilerFactory::EnumerateAdapterFamilies](#id3d12compilerfactory-enumerateadapterfamilies)<!-- d3d12-review-inline:end:compiler-foundation:compiler-version-params:1 --></ins>.

<ins><!-- d3d12-review-inline:begin:compiler-foundation:compiler-version-params:2 -->`[out] pCompilerVersion`<!-- d3d12-review-inline:end:compiler-foundation:compiler-version-params:2 --></ins>

Compiler version changes signify changes in code generation that potentially impact all applications for an adapter family.  See <ins><!-- d3d12-review-inline:begin:compiler-foundation:compiler-version-params:3 -->[D3D12_VERSION_NUMBER](state-object-databases-and-identity.md#d3d12_version_number)<!-- d3d12-review-inline:end:compiler-foundation:compiler-version-params:3 --></ins>.

#### Versioning guidance

Version Hints: Major/Minor version change for "must" recompile such as security or major fixes.  Build for "should" recompile such as performance.  Revision for less consequential changes that shouldn't invalidate caches.

#### Return values

<!-- d3d12-review-alert:begin:compiler-foundation:compiler-version-results:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pCompilerVersion` is required writable storage; null returns `E_INVALIDARG`.
> Success returns the plugin's single compiler version for the family. An
> unavailable family is reported as `DXGI_ERROR_NOT_FOUND`. Other plugin failures
> remain failures. This method is not an array enumeration or null output probe.

<!-- d3d12-review-alert:end:compiler-foundation:compiler-version-results:0 -->

<!-- d3d12-review-alert:begin:compiler-foundation:compiler-version-results:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The caller must not consume `*pCompilerVersion` after failure. Failure does not
> guarantee a usable result or a zero version.

<!-- d3d12-review-alert:end:compiler-foundation:compiler-version-results:1 -->

<a id="id3d12compilerfactory-getapplicationprofileversion"></a>

### ID3D12CompilerFactory::GetApplicationProfileVersion

#### Declaration

```cpp
HRESULT GetApplicationProfileVersion(
    const D3D12_COMPILER_TARGET* pTarget,
    const D3D12_APPLICATION_DESC* pApplicationDesc,
    D3D12_VERSION_NUMBER* pApplicationProfileVersion);
```

#### Behavior

Compilers may have an application dependent profile or settings.

<!-- d3d12-review-alert:begin:compiler-foundation:profile-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns the version of the compiler profile applicable to the specified target and application description.

<!-- d3d12-review-alert:end:compiler-foundation:profile-behavior:0 -->

#### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-foundation:profile-params:0 -->`[in] pTarget`<!-- d3d12-review-inline:end:compiler-foundation:profile-params:0 --></ins>

Describes the adapter family and ABI version to target.  Specify zero for ABIVersion to default to the latest supported ABI Version.  See <ins><!-- d3d12-review-inline:begin:compiler-foundation:profile-params:1 -->[D3D12_COMPILER_TARGET](#d3d12_compiler_target)<!-- d3d12-review-inline:end:compiler-foundation:profile-params:1 --></ins>.

<ins><!-- d3d12-review-inline:begin:compiler-foundation:profile-params:2 -->`[in] pApplicationDesc`<!-- d3d12-review-inline:end:compiler-foundation:profile-params:2 --></ins>

Describes the target application and version.  See <ins><!-- d3d12-review-inline:begin:compiler-foundation:profile-params:3 -->[D3D12_APPLICATION_DESC](state-object-databases-and-identity.md#d3d12_application_desc)<!-- d3d12-review-inline:end:compiler-foundation:profile-params:3 --></ins>.

<ins><!-- d3d12-review-inline:begin:compiler-foundation:profile-params:4 -->`[out] pApplicationProfileVersion`<!-- d3d12-review-inline:end:compiler-foundation:profile-params:4 --></ins>

Returns the profile version which describes the version of the compiler profile that targets a specific application.  See <ins><!-- d3d12-review-inline:begin:compiler-foundation:profile-params:5 -->[D3D12_VERSION_NUMBER](state-object-databases-and-identity.md#d3d12_version_number)<!-- d3d12-review-inline:end:compiler-foundation:profile-params:5 --></ins>.

#### Profile changes

The compiler application profile can be versioned <ins><!-- d3d12-review-inline:begin:compiler-foundation:profile-params:7 -->when there are application specific changes<!-- d3d12-review-inline:end:compiler-foundation:profile-params:7 --></ins> to these profiles that do not impact other applications.  This prevents invalidating caches for all applications when a change is application specific.

#### Return values and validation

<!-- d3d12-review-alert:begin:compiler-foundation:profile-results:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> All three pointers are required. A null pointer returns `E_INVALIDARG`.
> Once the required pointers are valid, the output version is initialized to zero.
> The runtime validates the family and target ABI before asking the plugin for
> the profile version. Zero ABI uses the greatest supported member as described
> under [target resolution](#d3d12_compiler_target). An unsupported nonzero ABI
> returns `E_INVALIDARG` rather than falling back. Family discovery failures
> propagate.

<!-- d3d12-review-alert:end:compiler-foundation:profile-results:0 -->

<!-- d3d12-review-alert:begin:compiler-foundation:profile-results:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Success returns `S_OK` and the applicable profile version. When no application
> or engine profile applies, the version is zero. A profile revision can change
> compiler output for this application without revising every application's
> compiler version. The runtime does not prescribe a vendor's profile matching
> algorithm or an application-versus-engine fallback precedence.

<!-- d3d12-review-alert:end:compiler-foundation:profile-results:1 -->

<!-- d3d12-review-alert:begin:compiler-foundation:profile-results:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Failures after pointer validation leave the initialized zero output, but a
> zero version alone does not indicate success:
> the caller must check the `HRESULT`. Null pointer failure does not establish
> initialized output. There is no null output profile presence probe.

<!-- d3d12-review-alert:end:compiler-foundation:profile-results:2 -->

<a id="factory-child"></a>

## Factory child ownership

<a id="id3d12compilerfactorychild-getfactory"></a>

### ID3D12CompilerFactoryChild::GetFactory

#### Declaration

```cpp
HRESULT GetFactory(
    REFIID riid,
    void** ppCompilerFactory);
```

#### Behavior

<!-- d3d12-review-alert:begin:compiler-foundation:get-factory:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns the compiler factory that owns this child, queried for `riid`.
> The returned reference is independent of the child's retained factory
> reference; releasing it does not detach the child from its owner.

<!-- d3d12-review-alert:end:compiler-foundation:get-factory:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:compiler-foundation:get-factory-params:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `[in] riid`

<!-- d3d12-review-alert:end:compiler-foundation:get-factory-params:0 -->

<!-- d3d12-review-alert:begin:compiler-foundation:get-factory-params:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The requested compiler factory interface identifier, normally
> `IID_ID3D12CompilerFactory`.

<!-- d3d12-review-alert:end:compiler-foundation:get-factory-params:1 -->

<!-- d3d12-review-alert:begin:compiler-foundation:get-factory-params:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `[out] ppCompilerFactory`

<!-- d3d12-review-alert:end:compiler-foundation:get-factory-params:2 -->

<!-- d3d12-review-alert:begin:compiler-foundation:get-factory-params:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Required writable storage for an owned interface reference. On success the
> caller releases the returned reference. A null pointer is not an availability
> probe or a request to release the retained factory.

<!-- d3d12-review-alert:end:compiler-foundation:get-factory-params:3 -->

#### Return values

<!-- d3d12-review-alert:begin:compiler-foundation:get-factory-results:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns `S_OK` when the requested interface is returned, or `E_NOINTERFACE`
> when the factory does not expose `riid`. For valid output storage, a failed
> interface query returns no interface. A null `ppCompilerFactory` returns
> `E_POINTER`, following the owning factory's `IUnknown::QueryInterface` result.
> This query does not open or load a second plugin and does not create a device.

<!-- d3d12-review-alert:end:compiler-foundation:get-factory-results:0 -->

<a id="threading"></a>

## Threading and call lifetime

<!-- d3d12-review-alert:begin:compiler-foundation:threading-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Concurrent compiler API calls do not require external application
> synchronization. The compiler plugin must synchronize its internal state as
> necessary. This application API concurrency contract includes
> `D3D12CompilerSerializeVersionedRootSignature`, which does not require a plugin.

<!-- d3d12-review-alert:end:compiler-foundation:threading-contract:0 -->

<!-- d3d12-review-alert:begin:compiler-foundation:threading-contract:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Input and output pointers must remain valid for their calls, and interface
> references must remain alive while used.

<!-- d3d12-review-alert:end:compiler-foundation:threading-contract:1 -->

<a id="foundation-example"></a>

## Foundation example

```cpp
//
    // Create the factory
    //

    Microsoft::WRL::ComPtr<ID3D12CompilerFactory> spFactory;
    VERIFY_SUCCEEDED(D3D12CompilerCreateFactory(CompilerPluginDll, IID_PPV_ARGS(&spFactory)));
```

```cpp
//
    // Target adapter family and ABI
    //

    // Use the first available adapter family.
    UINT AdapterFamilyIndex = 0;

    // Zero targets the latest available ABI version for this adapter family.
    UINT64 ABIVersion = 0;

    const D3D12_COMPILER_TARGET target =
    {
        AdapterFamilyIndex,
        ABIVersion
    };

    //
    //  Application metadata
    //

    constexpr D3D12_APPLICATION_DESC applicationDesc =
    {
        L"Sample.exe",                                  // pExeFilename
        L"Sample Application Title",                    // pName
        {1},                                            // Version
        L"Sample Engine Name",                          // pEngineName
        {7}                                             // EngineVersion
    };
```

```cpp
    D3D12_VERSION_NUMBER applicationProfileVersion = {};
    VERIFY_SUCCEEDED(spFactory->GetApplicationProfileVersion(
        &target, &applicationDesc, &applicationProfileVersion));
```
