<a id="offline-compilation"></a>

# Offline compilation

<ins><!-- d3d12-review-inline:begin:compiler-foundation:scope:0:authored:migration-69efd42596151750-0 -->Offline driver/pipeline compilation produces vendor-dependent pipeline state
and state object output from creation descriptions and shader bytecode. It is
distinct from HLSL frontend compilation.<!-- d3d12-review-inline:end:compiler-foundation:scope:0:authored:migration-69efd42596151750-0 --></ins>

<a id="motivation"></a>

<a id="compiler-runtime-design"></a>

## Compiler runtime design

GPU hardware vendors expose compilers in an [IHV Compiler Plugin](compiler-plugin-foundation.md) dll via a [Plugin DDI](compiler-plugin-foundation.md#compiler-plugin-foundation).

The <ins><!-- d3d12-review-inline:begin:compiler-foundation:design-foundation:1:modified:section-pass-runtime -->[Microsoft Compiler Runtime](#availability)<!-- d3d12-review-inline:end:compiler-foundation:design-foundation:1:modified:section-pass-runtime --></ins> <ins><!-- d3d12-review-inline:begin:compiler-foundation:design-foundation:1:modified:migration-730f3f5afa53a4df-1 -->wraps<!-- d3d12-review-inline:end:compiler-foundation:design-foundation:1:modified:migration-730f3f5afa53a4df-1 --></ins> these plugins with an <ins><!-- d3d12-review-inline:begin:compiler-foundation:design-foundation:1:modified:section-pass-api -->[API](#exports)<!-- d3d12-review-inline:end:compiler-foundation:design-foundation:1:modified:section-pass-api --></ins> <ins><!-- d3d12-review-inline:begin:compiler-foundation:design-foundation:1:modified:migration-d88b32c4a7a4b92f-3 -->in D3D12StateObjectCompiler.dll<!-- d3d12-review-inline:end:compiler-foundation:design-foundation:1:modified:migration-d88b32c4a7a4b92f-3 --></ins> to expose functionality to Independent Software Vendors(ISVs).

<a id="availability"></a>

## Compiler availability and independence

IHVs should ship their compilers via their websites in a fashion similar to how drivers are shipped so it can be publicly downloaded by ISVs.  Plugins are also direct submitted to the compiler service.  Submitting compilers before driver release allows time for compilation before they are needed on client systems.
Microsoft makes the compiler API and command line tool available in a fashion similar to how the DirectX Agility SDK is shipped so it can be publicly downloaded.

The Plugin DDI is separate from the D3D12 Usermode DDI to support factoring compilers out of drivers into separate components:

- Compiler plugins must be usable without a hardware adapter present to support cloud compilation

<ins><!-- d3d12-review-inline:begin:compiler-foundation:independence:2:modified:source-3e38830b19db5ea6-0-0 -->The plugin DDI may be implemented with the usermode DDI, but it must not require the usermode driver to be installed or an adapter to be<!-- d3d12-review-inline:end:compiler-foundation:independence:2:modified:source-3e38830b19db5ea6-0-0 --></ins> present.

The Microsoft API is nano-COM and exposes compiling and caching functionality to end users like ISVs and the cloud compilation service.  It allows callers to enumerate and create compilers.

<ins><!-- d3d12-review-inline:begin:compiler-foundation:factory-identity:0:authored:migration-3a04c61c1584bc22-0 -->`D3D12CompilerCreateFactory` is an export of `D3D12StateObjectCompiler.dll`.<!-- d3d12-review-inline:end:compiler-foundation:factory-identity:0:authored:migration-3a04c61c1584bc22-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-foundation:factory-identity:1:authored:migration-6c80eee38960cfc4-0 -->`ID3D12CompilerFactory` and `ID3D12CompilerFactoryChild` derive from `IUnknown`.
Returned interface references are owned
references that the caller releases. Each factory child retains its factory;
releasing the caller's original factory reference does not invalidate a living
child. The plugin module remains loaded while the factory that owns its DDI
object is alive. The compiler runtime module must remain available while its
objects or returned blob implementations are in use.<!-- d3d12-review-inline:end:compiler-foundation:factory-identity:1:authored:migration-6c80eee38960cfc4-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-foundation:factory-identity:2:authored:migration-8568ccef7d89c2ab-0 -->Compiler host capabilities describe the selected target. See
[Pipeline state](pipeline-state.md) and
[State object creation](state-objects.md#createstateobject) for device
capability requirements.<!-- d3d12-review-inline:end:compiler-foundation:factory-identity:2:authored:migration-8568ccef7d89c2ab-0 --></ins>

<a id="version-domains"></a>

## Version domains

<a id="plugin-ddi-version"></a>

### Plugin DDI version

The compiler plugin DDI is independently versioned from the D3D12 Usermode DDI, but with a similar scheme.  This allows for compiler specific changes to not impact the D3D12 Runtime development.  It <ins><!-- d3d12-review-inline:begin:compiler-foundation:versioning:0:modified:source-2f094e4ac176b60b-0-0 -->consists<!-- d3d12-review-inline:end:compiler-foundation:versioning:0:modified:source-2f094e4ac176b60b-0-0 --></ins> of 4 16bit parts packed into a UINT64 number:

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

New changes to these concepts must be first introduced in the D3D12 runtime.  Each Compiler DDI version has exactly one usermode DDI version associated with it at design time to define which version of these common concepts apply.  For clarity, the compiler runtime will set this version to the driver along with the plugin version chosen.  Plugins must only report plugin DDI versions when they can support the associated Usermode DDI version.  The compiler plugin must introduce a new plugin DDI version associated <ins><!-- d3d12-review-inline:begin:compiler-foundation:shared-concepts:2:authored:source-85ce16c449610ef5-0-0 -->with <!-- d3d12-review-inline:end:compiler-foundation:shared-concepts:2:authored:source-85ce16c449610ef5-0-0 --></ins>the Usermode DDI to expose it.

<a id="package-version"></a>

### Package version

<ins><!-- d3d12-review-inline:begin:compiler-foundation:package:0:modified:source-39d5b8a5607a61af-0-0 -->The package version<!-- d3d12-review-inline:end:compiler-foundation:package:0:modified:source-39d5b8a5607a61af-0-0 --></ins> updates anytime anything in the compiler package changes, including when compiler versions, adapter families, ABI or application profile version changes.  This concept <ins><!-- d3d12-review-inline:begin:compiler-foundation:package:0:modified:source-39d5b8a5607a61af-1-0 -->is<!-- d3d12-review-inline:end:compiler-foundation:package:0:modified:source-39d5b8a5607a61af-1-0 --></ins> also used by any services <ins><!-- d3d12-review-inline:begin:compiler-foundation:package:0:modified:source-39d5b8a5607a61af-2-0 -->performing compilation<!-- d3d12-review-inline:end:compiler-foundation:package:0:modified:source-39d5b8a5607a61af-2-0 --></ins> and is not represented in API.

<a id="adapter-families"></a>

### Adapter families

IHVs define Adapter Families with a string identifier to indicate a grouping of adapters that can share precompiled shaders.  A plugin indicates a [compiler version](#adapter-family-compiler-version) per adapter family that's rev'd with changes impacting that adapter family such as bug fixes, performance optimizations, etc.  The plugin can also support a range of ABI versions to indicate compatibility with drivers.  A newer compiler version can target an older ABI.

<a id="adapter-family-compiler-version"></a>

### Adapter family compiler version

A plugin reports a single compiler version per adapter family that revises with plugin changes that impact that adapter family, such as bug fixes, code generation changes, etc.  The version is a 64 bit encoding of four 16bit values to define a four part version as Major.Minor.Build.Revision.  Application <ins><!-- d3d12-review-inline:begin:compiler-foundation:compiler-version:0:modified:source-7aef27cff0410a9a-0-0 -->specific<!-- d3d12-review-inline:end:compiler-foundation:compiler-version:0:modified:source-7aef27cff0410a9a-0-0 --></ins> profile settings or application targeted changes should rev the [Application Profile Version](#application-profile-version) instead.

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

### Version comparisons and ABI sets

<ins><!-- d3d12-review-inline:begin:compiler-foundation:distinct-domains:0:authored:migration-70df1600d01df977-0 -->Package version, plugin DDI version, associated usermode DDI version, adapter
family compiler version, compiler target ABI version, application version and
application profile version are distinct domains. Equality or numerical ordering
between different domains has no compatibility meaning.<!-- d3d12-review-inline:end:compiler-foundation:distinct-domains:0:authored:migration-70df1600d01df977-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-foundation:distinct-domains:1:authored:migration-8aa129d47b883267-0 -->The canonical [D3D12_VERSION_NUMBER encoding](state-object-databases-and-identity.md#d3d12_version_number)
defines compiler/profile/application four-part numbers. It also defines the
little-endian `VersionParts` overlay. An adapter family ABI is instead a `UINT64`
counter, not a packed application or compiler version.<!-- d3d12-review-inline:end:compiler-foundation:distinct-domains:1:authored:migration-8aa129d47b883267-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-foundation:distinct-domains:2:authored:migration-abe4a362ee6eac7d-0 -->The plugin's enumerated set of target ABIs can be sparse.
The device's [SHADERCACHE_ABI_SUPPORT query](devices-and-capabilities.md#d3d12_feature_data_shadercache_abi_support)
reports an inclusive minimum/maximum range for the installed driver. A family index
identifies an entry within this factory's plugin enumeration, not a DXGI adapter
ordinal or a persistent cross-plugin identifier.<!-- d3d12-review-inline:end:compiler-foundation:distinct-domains:2:authored:migration-abe4a362ee6eac7d-0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:compiler-foundation:family-type:1:authored:migration-fa390f6707b763df-0 -->`szAdapterFamily` has capacity for 128 `WCHAR` elements,
including string termination.<!-- d3d12-review-inline:end:compiler-foundation:family-type:1:authored:migration-fa390f6707b763df-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-foundation:family-semantics:0:modified:migration-14f8b46baefe172e-0 -->`szAdapterFamily` uniquely identifies an adapter family<!-- d3d12-review-inline:end:compiler-foundation:family-semantics:0:modified:migration-14f8b46baefe172e-0 --></ins> for a hardware vendor.

An adapter family is a set of adapters that all share the same compiled output<ins><!-- d3d12-review-inline:begin:compiler-foundation:family-output:0:modified:source-dfd2f8875b46557d-0-0 --> for a given ABI version<!-- d3d12-review-inline:end:compiler-foundation:family-output:0:modified:source-dfd2f8875b46557d-0-0 --></ins>.

<a id="d3d12_compiler_target"></a>

### D3D12_COMPILER_TARGET

```cpp
typedef struct D3D12_COMPILER_TARGET
{
    UINT AdapterFamilyIndex;
    UINT64 ABIVersion;
} D3D12_COMPILER_TARGET;
```

#### Members

`AdapterFamilyIndex`

The index of the adapter family to target.  See [D3D12_ADAPTER_FAMILY](#d3d12_adapter_family) and [ID3D12CompilerFactory::EnumerateAdapterFamilies](#id3d12compilerfactory-enumerateadapterfamilies).

`ABIVersion`

The target <ins><!-- d3d12-review-inline:begin:compiler-foundation:target:5:modified:source-e9b8f4cfd6bbb69e-0-0 -->ABI version for the adapter family<!-- d3d12-review-inline:end:compiler-foundation:target:5:modified:source-e9b8f4cfd6bbb69e-0-0 --></ins>.  See Remarks.

#### Remarks

An ABIVersion of zero targets the latest ABIVersion available.

<ins><!-- d3d12-review-inline:begin:compiler-foundation:target-resolution:0:authored:migration-b86f620777a76a2f-0 -->For `GetApplicationProfileVersion`, zero requests the greatest supported ABI
value for that adapter family, resolved from the enumerated set. The runtime
does not pass zero to the plugin as an actual target ABI. A nonzero ABI must be
a member of that set. It is not rounded or replaced with a nearby version.<!-- d3d12-review-inline:end:compiler-foundation:target-resolution:0:authored:migration-b86f620777a76a2f-0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:compiler-foundation:factory-summary:0:modified:source-f2f563a911c283a5-0-0 -->Creates the compiler<!-- d3d12-review-inline:end:compiler-foundation:factory-summary:0:modified:source-f2f563a911c283a5-0-0 --></ins> factory with interfaces for creating compilers and checking capabilities.

#### Parameters

`pPluginCompilerDllPath`

[in] The path to the plugin compiler dll used for this instance of the factory.

`riid`

[in] The globally unique identifier (GUID) for the compiler factory interface.

`ppFactory`

[out] On <ins><!-- d3d12-review-inline:begin:compiler-foundation:factory-params:5:modified:source-374b15872d06b5d9-0-0 -->success, an owned pointer to<!-- d3d12-review-inline:end:compiler-foundation:factory-params:5:modified:source-374b15872d06b5d9-0-0 --></ins> the compiler factory interface specified by riid.

<ins><!-- d3d12-review-inline:begin:compiler-foundation:factory-loading:0:authored:migration-01830daf83d1a6cd-0 -->`pPluginCompilerDllPath` must identify the plugin DLL with a readable,
null-terminated wide string. Loading the module, locating its
`D3D12OpenCompilerDDI` export, opening it and negotiating a common plugin DDI
version occur as part of factory creation. Loader and plugin open/negotiation
failures can therefore fail the factory export before an interface is returned.
No matching adapter installation is required.<!-- d3d12-review-inline:end:compiler-foundation:factory-loading:0:authored:migration-01830daf83d1a6cd-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-foundation:factory-loading:1:authored:migration-c0c46ace72ef9c9e-0 -->The caller must supply writable interface pointer storage in
`ppFactory`. A null `ppFactory` is not a successful availability probe.
A failure before the interface query does not guarantee that `*ppFactory` has
been cleared. The caller must not consume an interface from `*ppFactory` after
a failure.<!-- d3d12-review-inline:end:compiler-foundation:factory-loading:1:authored:migration-c0c46ace72ef9c9e-0 --></ins>

#### Return values

Expected return codes (not exhaustive):

<!-- d3d12-review-alert:begin:compiler-foundation:factory-results:1:modified:migration-2a1a1d04d901fcfa-0 -->

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

<!-- d3d12-review-alert:end:compiler-foundation:factory-results:1:modified:migration-2a1a1d04d901fcfa-0 -->

<ins><!-- d3d12-review-inline:begin:compiler-foundation:factory-more-results:0:authored:migration-f059dc8ac0f3d42d-0 -->If there is no common plugin DDI version, factory creation returns
`DXGI_ERROR_UNSUPPORTED`.
Windows module-loading and missing-export failures return the corresponding
failure `HRESULT`. Plugin opening, version negotiation and table registration failures
are propagated. If the final interface query is reached, a null `ppFactory`
returns `E_POINTER`; earlier loading/negotiation can fail first.<!-- d3d12-review-inline:end:compiler-foundation:factory-more-results:0:authored:migration-f059dc8ac0f3d42d-0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:compiler-foundation:serializer:0:authored:migration-0e1e6a217df097d4-0 -->Serializes a versioned root signature description into an `ID3DBlob` for
compiler host inputs. See [Root signatures](binding.md#root-signatures) for
root signature structures, contents and root binding.<!-- d3d12-review-inline:end:compiler-foundation:serializer:0:authored:migration-0e1e6a217df097d4-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-foundation:serializer:1:authored:migration-88fae3d5de600d0d-0 -->Serialization does not create an `ID3D12RootSignature`, require an IHV compiler
plugin or establish that a particular device supports the serialized contents.
The compiler host serializer accepts the reserved register space forms used
by tools. That acceptance does not grant ordinary device creation permission.
Local root signatures, mesh-related flags, descriptor heap 64-bit atomics,
static sampler flags and non-normalized sampling are validated in the
compiler host context rather than against an instantiated physical device.<!-- d3d12-review-inline:end:compiler-foundation:serializer:1:authored:migration-88fae3d5de600d0d-0 --></ins>

#### Parameters

`pRootSignature`

[in] <ins><!-- d3d12-review-inline:begin:compiler-foundation:serializer-params:1:authored:migration-5a87945cc2c4b67d-0 -->A required pointer to `D3D12_VERSIONED_ROOT_SIGNATURE_DESC`. Its version selects
the corresponding description; versions 1.0, 1.1 and 1.2 are supported. Its
referenced arrays and strings must be readable for the call.<!-- d3d12-review-inline:end:compiler-foundation:serializer-params:1:authored:migration-5a87945cc2c4b67d-0 --></ins>

`ppBlob`

[out] <ins><!-- d3d12-review-inline:begin:compiler-foundation:serializer-params:3:authored:migration-6d60e193d75cdd2c-0 -->Required writable storage for the returned serialized blob interface.
On success the caller owns the reference and releases it when no longer
needed. Blob data is accessed with `GetBufferPointer` and `GetBufferSize`;
the size is in bytes and the storage is valid while the blob remains alive.<!-- d3d12-review-inline:end:compiler-foundation:serializer-params:3:authored:migration-6d60e193d75cdd2c-0 --></ins>

`ppErrorBlob`

[out, optional] <ins><!-- d3d12-review-inline:begin:compiler-foundation:serializer-params:5:authored:migration-c9207c690112a009-0 -->Optional writable storage for an error message blob. When supplied for a valid
serialization call, it receives an owned blob containing diagnostics or
`nullptr` if there are none. Release any returned error blob even when
serialization fails. `nullptr` suppresses this returned diagnostic object;
it does not suppress validation.<!-- d3d12-review-inline:end:compiler-foundation:serializer-params:5:authored:migration-c9207c690112a009-0 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:compiler-foundation:serializer-results:0:authored:migration-dfa521aee4085084-0 -->On success, the function returns `S_OK` and stores the serialized blob interface
pointer in `*ppBlob`. The function returns `E_INVALIDARG` if `pRootSignature` or
`ppBlob` is null. It rejects invalid descriptions, including unsupported root
signature versions. The compiler host wrapper maps the serializer's `E_FAIL`
validation result to `E_INVALIDARG`. If allocation fails, the function can return
`E_OUTOFMEMORY`.<!-- d3d12-review-inline:end:compiler-foundation:serializer-results:0:authored:migration-dfa521aee4085084-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-foundation:serializer-results:1:authored:migration-59a7dae7acbe34ee-0 -->After valid required pointers have been checked, `*ppBlob` and, when supplied,
`*ppErrorBlob` are initialized to `nullptr` before validation. Invalid required
pointers do not establish initialized outputs. A diagnostic blob is not
guaranteed for every failure.<!-- d3d12-review-inline:end:compiler-foundation:serializer-results:1:authored:migration-59a7dae7acbe34ee-0 --></ins>

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

Retrieve <ins><!-- d3d12-review-inline:begin:compiler-foundation:enumerate-family-summary:0:modified:source-6c02d5e807da4642-0-0 -->an adapter family<!-- d3d12-review-inline:end:compiler-foundation:enumerate-family-summary:0:modified:source-6c02d5e807da4642-0-0 --></ins> supported by the plugin.

#### Parameters

`AdapterFamilyIndex`

[in] The index of the adapter family to enumerate.

`pAdapterFamily`

[out] The adapter family at Index.  See [D3D12_ADAPTER_FAMILY](#d3d12_adapter_family).

<ins><!-- d3d12-review-inline:begin:compiler-foundation:enumerate-family-contract:0:authored:migration-bcfb6db8b453e977-0 -->Indices are contiguous starting at zero. `pAdapterFamily` must point to writable
storage for the complete fixed-size structure. A null output returns
`E_INVALIDARG` and is not a count query.<!-- d3d12-review-inline:end:compiler-foundation:enumerate-family-contract:0:authored:migration-bcfb6db8b453e977-0 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:compiler-foundation:enumerate-family-results:0:authored:migration-eb14d04975b7d7a4-0 -->A successful query returns the family at the index. An index beyond the
available families returns `DXGI_ERROR_NOT_FOUND`. The name storage is cleared
before the plugin query and is filled on success. Other plugin failures are
returned as failures, not treated as end-of-list.<!-- d3d12-review-inline:end:compiler-foundation:enumerate-family-results:0:authored:migration-eb14d04975b7d7a4-0 --></ins>

#### Example

<ins><!-- d3d12-review-inline:begin:compiler-foundation:enumeration-example-context:0:authored:migration-1d79729e6f7c3587-0 -->`pFactory` in the following enumeration example is an `ID3D12CompilerFactory*` returned by `D3D12CompilerCreateFactory`.<!-- d3d12-review-inline:end:compiler-foundation:enumeration-example-context:0:authored:migration-1d79729e6f7c3587-0 --></ins>

Example <ins><!-- d3d12-review-inline:begin:compiler-foundation:family-example:0:modified:source-47db720a57a895ac-0-0 -->of enumerating all adapter families<!-- d3d12-review-inline:end:compiler-foundation:family-example:0:modified:source-47db720a57a895ac-0-0 --></ins>:

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

`AdapterFamilyIndex`

[in] <ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-params:1 -->The index of the adapter family to query for supported ABI versions.  See [D3D12_ADAPTER_FAMILY](#d3d12_adapter_family) and [ID3D12CompilerFactory::EnumerateAdapterFamilies](#id3d12compilerfactory-enumerateadapterfamilies).<!-- d3d12-review-inline:end:compiler-foundation:abi-params:1 --></ins>

`pNumABIVersions`

[in, out] On input, <ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-params:3:modified:migration-93da7da73706d9f6-0 -->describes the capacity of pABIVersions in UINT64 elements<!-- d3d12-review-inline:end:compiler-foundation:abi-params:3:modified:migration-93da7da73706d9f6-0 --></ins>.  <ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-params:3:modified:migration-02e7a934c7ebd17a-1 -->`*pNumABIVersions` is zero<!-- d3d12-review-inline:end:compiler-foundation:abi-params:3:modified:migration-02e7a934c7ebd17a-1 --></ins> when pABIVersions is nullptr.  This may be used to retrieve a partial list, <ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-params:3:modified:migration-8c9e44232bc261dc-2 -->see the buffer rules below<!-- d3d12-review-inline:end:compiler-foundation:abi-params:3:modified:migration-8c9e44232bc261dc-2 --></ins>.  On output, returns the number of ABI Versions <ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-params:3:modified:migration-7e8d9107a77658b8-3 -->for the adapter family<!-- d3d12-review-inline:end:compiler-foundation:abi-params:3:modified:migration-7e8d9107a77658b8-3 --></ins>.

`pABIVersions`

[out, optional] <ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-params:5:modified:source-a0da1480336a72b6-0-0 -->Receives<!-- d3d12-review-inline:end:compiler-foundation:abi-params:5:modified:source-a0da1480336a72b6-0-0 --></ins> the list of ABI Versions for <ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-params:5:modified:source-a0da1480336a72b6-1-0 -->the adapter family<!-- d3d12-review-inline:end:compiler-foundation:abi-params:5:modified:source-a0da1480336a72b6-1-0 --></ins>.  May be nullptr when performing a size check.

<ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-remarks:0:modified:migration-46c426343b556067-0 -->Returns the<!-- d3d12-review-inline:end:compiler-foundation:abi-remarks:0:modified:migration-46c426343b556067-0 --></ins> compiler ABI version supported by the compiled binaries produced by this compiler.  This is compared with the supported ABI range of a driver to understand if precompiled binaries are supported.

Compiled objects produced by this compiler at a target ABI version may not be used with drivers that do not report this ABI version in their supported ABI version range.

ABI version is used to check for precompiled cache updates and understand cache compatibility with drivers on the client, see <ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-remarks:2:modified:source-7552bc485e2029ef-0-0 -->[Version domains](#version-domains)<!-- d3d12-review-inline:end:compiler-foundation:abi-remarks:2:modified:source-7552bc485e2029ef-0-0 --></ins>.

#### Return values and buffer rules

<ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-results:0:authored:migration-ee0f85ad05a8b9ee-0 -->`pNumABIVersions` is required. A null pointer returns `E_INVALIDARG`.
For a size query, pass `*pNumABIVersions == 0` and
`pABIVersions == nullptr`. For a valid family the query returns `S_OK` and the
required element count. A valid family must provide at least one ABI.<!-- d3d12-review-inline:end:compiler-foundation:abi-results:0:authored:migration-ee0f85ad05a8b9ee-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-results:1:authored:migration-7181471fcf3a750d-0 -->For an array query, the input count is the writable capacity in `UINT64`
elements, not bytes. With sufficient capacity, the plugin copies the complete
list, updates the count to the number of supported versions and returns `S_OK`.
With insufficient capacity, it copies as many elements as fit, reports the full
required count and returns `DXGI_ERROR_MORE_DATA`. The returned count is then
greater than the number of valid copied elements. A nonnull zero-capacity buffer
does not request a successful size-only query. A null array with nonzero input
capacity is invalid.<!-- d3d12-review-inline:end:compiler-foundation:abi-results:1:authored:migration-7181471fcf3a750d-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-results:2:authored:migration-4b3cd5dd599430be-0 -->Zero and `UINT64_MAX` are reserved and must not be enumerated. The initial
ABI is 1. A breaking ABI change increments the counter. The set need not include
all values between the smallest and largest returned ABI.<!-- d3d12-review-inline:end:compiler-foundation:abi-results:2:authored:migration-4b3cd5dd599430be-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-results:3:authored:migration-6b4c6e300abae816-0 -->ABI versions must be returned in descending order, newest first. The latest
supported ABI is at `pABIVersions[0]`. A one-element array query retrieves that
latest ABI. When more than one ABI is supported, it returns
`DXGI_ERROR_MORE_DATA` and the full count while providing that first element.<!-- d3d12-review-inline:end:compiler-foundation:abi-results:3:authored:migration-6b4c6e300abae816-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-foundation:abi-results:4:authored:migration-795c370c6c6d3f94-0 -->If the adapter family is invalid and `pNumABIVersions` is valid, the operation
must return `DXGI_ERROR_NOT_FOUND` and set `*pNumABIVersions` to zero.
For a valid family and valid count pointer, the count reports the family's
correct number of ABI versions on return, regardless of other success/failure.
Only the documented copied prefix of a short-buffer result may be consumed;
other failure outputs must not be consumed as ABI results.<!-- d3d12-review-inline:end:compiler-foundation:abi-results:4:authored:migration-795c370c6c6d3f94-0 --></ins>

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

`AdapterFamilyIndex`

[in] The index of the adapter family <ins><!-- d3d12-review-inline:begin:compiler-foundation:compiler-version-params:1:modified:migration-ce60e4055f2bbdfc-0 -->to query for its compiler version<!-- d3d12-review-inline:end:compiler-foundation:compiler-version-params:1:modified:migration-ce60e4055f2bbdfc-0 --></ins>.  See <ins><!-- d3d12-review-inline:begin:compiler-foundation:compiler-version-params:1:modified:section-pass-family -->[D3D12_ADAPTER_FAMILY](#d3d12_adapter_family)<!-- d3d12-review-inline:end:compiler-foundation:compiler-version-params:1:modified:section-pass-family --></ins> and <ins><!-- d3d12-review-inline:begin:compiler-foundation:compiler-version-params:1:modified:section-pass-enumeration -->[ID3D12CompilerFactory::EnumerateAdapterFamilies](#id3d12compilerfactory-enumerateadapterfamilies)<!-- d3d12-review-inline:end:compiler-foundation:compiler-version-params:1:modified:section-pass-enumeration --></ins>.

`pCompilerVersion`

[out] Compiler version changes signify changes in code generation that potentially impact all applications for an adapter family.  See [D3D12_VERSION_NUMBER](state-object-databases-and-identity.md#d3d12_version_number).

#### Versioning guidance

Version Hints: Major/Minor version change for "must" recompile such as security or major fixes.  Build for "should" recompile such as performance.  Revision for less consequential changes that shouldn't invalidate caches.

#### Return values

<ins><!-- d3d12-review-inline:begin:compiler-foundation:compiler-version-results:0:authored:migration-48765762ebd6af49-0 -->`pCompilerVersion` is required writable storage; null returns `E_INVALIDARG`.
Success returns the plugin's single compiler version for the family. An
unavailable family is reported as `DXGI_ERROR_NOT_FOUND`. Other plugin failures
are returned as failures.<!-- d3d12-review-inline:end:compiler-foundation:compiler-version-results:0:authored:migration-48765762ebd6af49-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-foundation:compiler-version-results:1:authored:migration-8499afabcb39d368-0 -->After a failure, the caller must not consume `*pCompilerVersion`. Its value
is not necessarily zero.<!-- d3d12-review-inline:end:compiler-foundation:compiler-version-results:1:authored:migration-8499afabcb39d368-0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:compiler-foundation:profile-behavior:0:authored:migration-30528a77c5f412c6-0 -->Returns the version of the compiler profile applicable to the specified target and application description.<!-- d3d12-review-inline:end:compiler-foundation:profile-behavior:0:authored:migration-30528a77c5f412c6-0 --></ins>

#### Parameters

`pTarget`

[in] Describes the adapter family and ABI version to target.  Specify zero for ABIVersion to default to the latest supported ABI Version.  See [D3D12_COMPILER_TARGET](#d3d12_compiler_target).

`pApplicationDesc`

[in] Describes the target application and version.  See [D3D12_APPLICATION_DESC](state-object-databases-and-identity.md#d3d12_application_desc).

<ins><!-- d3d12-review-inline:begin:compiler-foundation:target-resolution:1:authored:migration-96bd5ad07fd031b3-0 -->Supply the target application's required null-terminated
executable filename and title, application version, optional null-terminated
engine name (`nullptr` when not applicable), and engine version when an engine
name is supplied. The process hosting the offline compiler does not supply an
implicit executable name fallback. These inputs and all referenced strings must
remain readable during the call. This query does not transfer their ownership.<!-- d3d12-review-inline:end:compiler-foundation:target-resolution:1:authored:migration-96bd5ad07fd031b3-0 --></ins>

`pApplicationProfileVersion`

[out] Returns the profile version which describes the version of the compiler profile that targets a specific application.  See [D3D12_VERSION_NUMBER](state-object-databases-and-identity.md#d3d12_version_number).

#### Profile changes

The compiler application profile can be versioned when there <ins><!-- d3d12-review-inline:begin:compiler-foundation:profile-params:7:authored:source-7558eb136d23b392-0-0 -->are <!-- d3d12-review-inline:end:compiler-foundation:profile-params:7:authored:source-7558eb136d23b392-0-0 --></ins>application specific changes to these profiles that do not impact other applications.  This prevents invalidating caches for all applications when a change is application specific.

#### Return values and validation

<ins><!-- d3d12-review-inline:begin:compiler-foundation:profile-results:0:authored:migration-3b13788584a9eece-0 -->All three pointers are required. A null pointer returns `E_INVALIDARG`.
Once the required pointers are valid, the output version is initialized to zero.
The runtime validates the family and target ABI before asking the plugin for
the profile version. Zero ABI uses the greatest supported member as described
under [target resolution](#d3d12_compiler_target). An unsupported nonzero ABI
returns `E_INVALIDARG` rather than falling back. Family discovery failures
propagate.<!-- d3d12-review-inline:end:compiler-foundation:profile-results:0:authored:migration-3b13788584a9eece-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-foundation:profile-results:1:authored:migration-f64b4091dd12b8f6-0 -->Success returns `S_OK` and the applicable profile version. When no application
or engine profile applies, the version is zero. The runtime does not prescribe a vendor's profile matching
algorithm or an application-versus-engine fallback precedence.<!-- d3d12-review-inline:end:compiler-foundation:profile-results:1:authored:migration-f64b4091dd12b8f6-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-foundation:profile-results:2:authored:migration-c82699f5a76a089d-0 -->Failures after pointer validation leave the initialized zero output, but a
zero version alone does not indicate success:
the caller must check the `HRESULT`. Null pointer failure does not establish
initialized output.<!-- d3d12-review-inline:end:compiler-foundation:profile-results:2:authored:migration-c82699f5a76a089d-0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:compiler-foundation:get-factory:0:authored:migration-a9b26f330f62f34f-0 -->Returns the compiler factory that owns this child, queried for `riid`.
The returned reference is independent of the child's retained factory
reference; releasing it does not detach the child from its owner.<!-- d3d12-review-inline:end:compiler-foundation:get-factory:0:authored:migration-a9b26f330f62f34f-0 --></ins>

#### Parameters

`riid`

[in] <ins><!-- d3d12-review-inline:begin:compiler-foundation:get-factory-params:1:authored:migration-bd034505d4b0bf85-0 -->The requested compiler factory interface identifier, normally
`IID_ID3D12CompilerFactory`.<!-- d3d12-review-inline:end:compiler-foundation:get-factory-params:1:authored:migration-bd034505d4b0bf85-0 --></ins>

`ppCompilerFactory`

[out] <ins><!-- d3d12-review-inline:begin:compiler-foundation:get-factory-params:3:authored:migration-7b8497acde34c314-0 -->Required writable storage for an owned interface reference. On success the
caller releases the returned reference.<!-- d3d12-review-inline:end:compiler-foundation:get-factory-params:3:authored:migration-7b8497acde34c314-0 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:compiler-foundation:get-factory-results:0:authored:migration-14af07e2e32376f9-0 -->Returns `S_OK` when the requested interface is returned, or `E_NOINTERFACE`
when the factory does not expose `riid`. For valid output storage, a failed
interface query returns no interface. A null `ppCompilerFactory` returns
`E_POINTER`, following the owning factory's `IUnknown::QueryInterface` result.<!-- d3d12-review-inline:end:compiler-foundation:get-factory-results:0:authored:migration-14af07e2e32376f9-0 --></ins>

<a id="threading"></a>

## Threading

<ins><!-- d3d12-review-inline:begin:compiler-foundation:threading-contract:0:authored:migration-af3b4119fd18f857-0 -->Concurrent compiler API calls, including calls to
`D3D12CompilerSerializeVersionedRootSignature`, do not require external
application synchronization. The compiler plugin must synchronize its internal
state as necessary.<!-- d3d12-review-inline:end:compiler-foundation:threading-contract:0:authored:migration-af3b4119fd18f857-0 --></ins>

<a id="foundation-example"></a>

## Example: creating a factory and querying a profile version

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
