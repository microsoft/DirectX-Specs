<a id="compiler-plugin-foundation"></a>

# Compiler plugin foundation

The compiler plugin DDI connects the State Object Compiler runtime to an IHV compiler plugin. The published ABI is `d3d12compilerddi.h` in the Windows Driver Kit. It uses common `d3d12umddi.h` definitions and the calling conventions in its declarations.

<a id="handles-and-versions"></a>

## Published handles and version constants

```cpp
typedef D3D12DDI_HSTATEOBJECT_0054 D3D12DDI_HCOMPILERSTATEOBJECT;

D3D10DDI_H( D3D12DDI_HCOMPILERDDI )
D3D10DDI_H( D3D12DDI_HCOMPILER )

D3D10DDI_HRT(D3D12DDI_HRTCOMPILERDDI)
D3D10DDI_HRT(D3D12DDI_HRTCOMPILER)
D3D10DDI_HRT(D3D12DDI_HRTCOMPILERCACHESESSION)

//----------------------------------------------------------------------------------------------------------------------------------
// D3D12 Compiler Plugin DDI Release 0, Build rev 1.

#define D3D12DDI_COMPILER_MINOR_VERSION 0
#define D3D12DDI_COMPILER_INTERFACE_VERSION ((D3D12DDI_MAJOR_VERSION << 16) | D3D12DDI_COMPILER_MINOR_VERSION)

#define D3D12DDI_COMPILER_BUILD_VERSION_0001 1
#define D3D12DDI_COMPILER_SUPPORTED_0001 ((((UINT64)D3D12DDI_COMPILER_INTERFACE_VERSION) << 32) | (((UINT64)D3D12DDI_COMPILER_BUILD_VERSION_0001) << 16))

//----------------------------------------------------------------------------------------------------------------------------------
// D3D12 Compiler Plugin DDI Release 0, Build rev 2.
// Change the input of PFND3D12DDI_COMPILER_COMPILE_ADD_TO_STATE_OBJECT and PFND3D12DDI_COMPILER_CALC_PRIVATE_ADD_TO_STATE_OBJECT_SIZE
// remove dup structs and add defines for the new names

#define D3D12DDI_COMPILER_BUILD_VERSION_0002 2
#define D3D12DDI_COMPILER_SUPPORTED_0002 ((((UINT64)D3D12DDI_COMPILER_INTERFACE_VERSION) << 32) | (((UINT64)D3D12DDI_COMPILER_BUILD_VERSION_0002) << 16))
```

`D3D10DDI_H` and `D3D10DDI_HRT` are the driver-private and runtime-private
handle declaration macros supplied by `d3d12umddi.h` and its dependencies.

<a id="compiler-ddi-handle"></a>

### D3D12DDI_HCOMPILERDDI

`D3D12DDI_HCOMPILERDDI` is a handle to the compiler plugin object created when opening the plugin DDI.  This object negotiates the DDI version.  When this object is destroyed, any objects or function tables retrieved from the plugin are no longer used.

<a id="runtime-ddi-handle"></a>

### D3D12DDI_HRTCOMPILERDDI

`D3D12DDI_HRTCOMPILERDDI` identifies the compiler runtime's object for the DDI.

<a id="open"></a>

## Opening and the negotiation table

```cpp
typedef VOID (APIENTRY *PFND3D12DDI_COMPILER_DESTROY_DDI)(
    D3D12DDI_HCOMPILERDDI hCompilerDDI
    );

typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_GET_SUPPORTED_VERSIONS)(
    D3D12DDI_HCOMPILERDDI hCompilerDDI,
    _Inout_ UINT32* puEntries,
    _Out_writes_opt_( *puEntries ) UINT64* pSupportedPluginDDIVersions
    );

typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_SET_SELECTED_VERSION)(
    D3D12DDI_HCOMPILERDDI   hCompilerDDI,
    UINT64                  PluginDDIVersion,
    UINT64                  UsermodeDDIVersion
    );

typedef enum D3D12DDI_COMPILER_TABLE_TYPE
{
    D3D12DDI_COMPILER_TABLE_TYPE_CAPABILITIES = 0, // D3D12DDI_COMPILER_CAPABILITIES_FUNCS
    D3D12DDI_COMPILER_TABLE_TYPE_COMPILER = 1,
} D3D12DDI_COMPILER_TABLE_TYPE;

typedef HRESULT ( APIENTRY * PFND3D12DDI_COMPILER_FILL_DDI_TABLE )(
    D3D12DDI_HCOMPILERDDI hCompilerDDI,
    D3D12DDI_COMPILER_TABLE_TYPE TableType,
    _Out_writes_bytes_(tableSize) VOID* pTable,
    SIZE_T TableSize
    );

typedef enum D3D12DDI_COMPILER_CALLBACK_TABLE_TYPE
{
    D3D12DDI_COMPILER_CALLBACK_TABLE_TYPE_CACHE = 0,
} D3D12DDI_COMPILER_CALLBACK_TABLE_TYPE;

typedef HRESULT ( APIENTRY * PFND3D12DDI_COMPILER_SET_CALLBACK_DDI_TABLE)(
    D3D12DDI_HCOMPILERDDI hCompilerDDI,
    D3D12DDI_COMPILER_CALLBACK_TABLE_TYPE TableType,
    _In_reads_bytes_(TableSize) const void* pTable,
    SIZE_T TableSize
    );

typedef struct D3D12DDI_COMPILER_DDI_FUNCS
{
    PFND3D12DDI_COMPILER_DESTROY_DDI                        pfnDestroyCompilerDDI;
    PFND3D12DDI_COMPILER_GET_SUPPORTED_VERSIONS             pfnGetSupportedVersions;
    PFND3D12DDI_COMPILER_SET_SELECTED_VERSION               pfnSetSelectedVersion;
    PFND3D12DDI_COMPILER_FILL_DDI_TABLE                     pfnFillDDITable;
    PFND3D12DDI_COMPILER_SET_CALLBACK_DDI_TABLE             pfnSetCallbackDDITable;
} D3D12DDI_COMPILER_DDI_FUNCS;

typedef struct D3D12DDIARG_COMPILER_OPEN_DDI
{
    D3D12DDI_HRTCOMPILERDDI         hRTCompilerDDI;     // in:  Runtime handle
    D3D12DDI_HCOMPILERDDI           hCompilerDDI;       // out: Plugin handle
    D3D12DDI_COMPILER_DDI_FUNCS*    pDDIFuncs;          // out: Plugin function table
} D3D12DDIARG_COMPILER_OPEN_DDI;

typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_OPEN_DDI)(
    _Inout_ D3D12DDIARG_COMPILER_OPEN_DDI* pOpenDDIArg
    );
```

IHVs export the compiler plugin's initial entry point as `D3D12OpenCompilerDDI`.

Opens the compiler DDI and retrieves the initial DDI table for version negotiation and further DDI table retrieval.

`pOpenDDIArg` is required in/out storage. The runtime supplies
`hRTCompilerDDI` and writable `pDDIFuncs` storage. On success the plugin supplies
its allocated `hCompilerDDI` object and fills the initial negotiation table.
The plugin handle is owned by the plugin. The runtime returns it to
`pfnDestroyCompilerDDI` when finished.

<a id="destroy"></a>

### PFND3D12DDI_COMPILER_DESTROY_DDI

Destroys the compiler DDI object.  Any function tables retrieved from the DDI are now invalid to use.

#### Parameters

`hCompilerDDI`

The handle to the plugin compiler DDI object.

<a id="negotiation"></a>

## Version enumeration and selection

<a id="supported-versions"></a>

### PFND3D12DDI_COMPILER_GET_SUPPORTED_VERSIONS

Retrieves the list of State Object Compiler DDI versions supported by the compiler plugin.  It is only necessary to expose a new DDI version from the compiler plugin when caps or definitions related to state objects change (i.e. it does not need to rev every time driver version does, but it can)

NOTE: This is not the same series of version numbers as the D3D12 runtime Usermode DDI, it is a version series dedicated to the State Object Compiler so it may be versioned independently.  However, each State Object Compiler version is assigned a single D3D12 Usermode DDI version at design time to make it clear which version of common concepts such as PSO Descs, SO Descs, and common caps are in use.  For clarity, this Usermode DDI version is set at runtime during [PFND3D12DDI_COMPILER_SET_SELECTED_VERSION](#negotiation).

The plugin runtime calls the plugin to retrieve a list of the supported DDI versions.

On return, the plugin sets `*puEntries` to the number of supported versions.

When checking size of the array, the runtime will call the plugin with `*puEntries` initially set to zero and pSupportedPluginDDIVersions set to nullptr.

When requesting the array, `*puEntries` is the capacity of `pSupportedPluginDDIVersions` in elements. The plugin copies the version list into this array.

<a id="selected-version"></a>

### PFND3D12DDI_COMPILER_SET_SELECTED_VERSION

Sets the DDI version that the State Object Compiler runtime selects from the list the compiler plugin provides to PFND3D12DDI_COMPILER_GET_SUPPORTED_VERSIONS.  The runtime typically picks the latest version supported by both the plugin and the compiler runtime.

#### Selected-version parameters

`hCompilerDDI`

The handle to the live plugin compiler DDI object.

`PluginDDIVersion`

The plugin DDI version selected from the list reported by the plugin during [PFND3D12DDI_COMPILER_GET_SUPPORTED_VERSIONS](#negotiation).  This version number dictates which version of function tables and behaviors are used.

`UsermodeDDIVersion`

The D3D12 runtime usermode DDI version associated with PluginDDIVersion.

#### Selection ordering

This function must be called before any calls to PFND3D12DDI_COMPILER_FILL_DDI_TABLE.

When a new PluginDDIVersion is introduced, it is assigned a UsermodeDDIVersion at design time.  The UsermodeDDIVersion may not change for a given PluginDDIVersion.  The compiler plugin must only report PluginDDIVersions that it also supports with the corresponding UsermodeDDIVersion.  UsermodeDDIVersion is provided for clarity to indicate which version of concepts used by the D3D12 runtime are in use, such as PSO Descs, SO Descs, and some common caps.  This version may be relied upon when sharing implementation with the D3D12 Usermode Driver.  See [Compiler independence](offline-compilation.md#availability).

| Compiler plugin DDI | Associated usermode DDI |
| --- | --- |
| `D3D12DDI_COMPILER_SUPPORTED_0001` | `D3D12DDI_SUPPORTED_0115` |
| `D3D12DDI_COMPILER_SUPPORTED_0002` | `D3D12DDI_SUPPORTED_0115` |

An empty intersection causes compiler factory creation to fail with
`DXGI_ERROR_UNSUPPORTED`. The runtime selects the greatest exact
intersection member. It does not negotiate an unreported compatible version.
Failures from plugin opening and version retrieval/selection fail factory
creation.

<a id="tables"></a>

## Table retrieval and callback registration

<a id="fill-table"></a>

### PFND3D12DDI_COMPILER_FILL_DDI_TABLE

Request additional function tables from the compiler plugin.

#### Retrieval parameters

`hCompilerDDI`

The handle to the plugin compiler DDI object.

`TableType`

Determines the type of pTable.  See [D3D12DDI_COMPILER_TABLE_TYPE](#open).

`pTable`

Buffer pointer that the plugin must copy the function table to.

`TableSize`

The size in bytes of the pTable buffer.

#### Retrieval ordering

[PFND3D12DDI_COMPILER_SET_SELECTED_VERSION](#negotiation) must be called by the plugin runtime before calling this function.  This enables function table versioning based on the selected version.

<a id="callback-table-type"></a>

### D3D12DDI_COMPILER_CALLBACK_TABLE_TYPE

Specifies which table is being set during PFND3D12DDI_COMPILER_SET_CALLBACK_DDI_TABLE.

#### Constants

`D3D12DDI_COMPILER_CALLBACK_TABLE_TYPE_CACHE`

Sets the D3D12DDI_COMPILER_CACHE_CALLBACKS table that allows for finding and storing cached values.  This table is always set before any compiler objects are created.

<a id="set-callback-table"></a>

### PFND3D12DDI_COMPILER_SET_CALLBACK_DDI_TABLE

Sets function tables that the driver uses to callback into the State Object Compiler runtime.

#### Registration parameters

`hCompilerDDI`

The handle to the plugin compiler DDI object.

`TableType`

Determines the type of pTable.  See [D3D12DDI_COMPILER_CALLBACK_TABLE_TYPE](#open).

`pTable`

Buffer pointer that contains the State Object Compiler runtime callback table.

`TableSize`

The size in bytes of the pTable buffer.

#### Remarks

The factory retrieves both capability and compiler tables during creation and
installs the cache callbacks. Failure in any of those steps prevents successful
factory creation.

<a id="descriptions"></a>

## Common and target descriptions

<a id="shared-and-target-descriptions"></a>

See [application metadata](state-object-databases-and-identity.md#application-metadata) for the common application and version metadata. The compiler receives the supplied offline application identity. It does not detect its host process as the application.

<a id="d3d12ddi_version_number"></a>

### D3D12DDI_VERSION_NUMBER

```cpp
typedef union D3D12DDI_VERSION_NUMBER
{
    UINT64 Version;
    UINT16 VersionParts[4];
} D3D12DDI_VERSION_NUMBER;
```

<a id="d3d12ddi_application_desc"></a>

### D3D12DDI_APPLICATION_DESC

```cpp
typedef struct D3D12DDI_APPLICATION_DESC
{
    PCWSTR pExeFilename;
    PCWSTR pName;
    D3D12DDI_VERSION_NUMBER Version;
    PCWSTR pEngineName;
    D3D12DDI_VERSION_NUMBER EngineVersion;
} D3D12DDI_APPLICATION_DESC;
```

<a id="d3d12ddiarg_getcaps"></a>

### D3D12DDIARG_GETCAPS

```cpp
typedef struct D3D12DDIARG_GETCAPS
{
    D3D12DDICAPS_TYPE Type;
    VOID* pInfo;
    VOID* pData;
    UINT DataSize;
} D3D12DDIARG_GETCAPS;
```

<a id="ddi-target-descriptions"></a>

### Compiler adapter family and target descriptions

```cpp
typedef struct D3D12DDI_COMPILER_ADAPTER_FAMILY
{
    WCHAR szAdapterFamily[128];
} D3D12DDI_COMPILER_ADAPTER_FAMILY;

typedef struct D3D12DDI_COMPILER_TARGET
{
    UINT AdapterFamilyIndex;
    UINT64 ABIVersion;
} D3D12DDI_COMPILER_TARGET;
```

`szAdapterFamily` uniquely identifies an adapter family for a hardware vendor.

An adapter family is a set of adapters that all share the same compiled output for a given ABI version.

The runtime validates the ABIVersion is one returned from [PFND3D12DDI_COMPILER_ENUMERATE_ADAPTER_FAMILY_ABI_VERSIONS](#abi-enumeration).

The runtime resolves an API `ABIVersion` of zero before passing a target to the plugin.

<a id="capabilities"></a>

## Capabilities table

```cpp
typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_GET_CAPS)(
    D3D12DDI_HCOMPILERDDI hCompilerDDI,
    _In_ CONST D3D12DDI_COMPILER_TARGET* pTarget,
    _In_ CONST D3D12DDI_APPLICATION_DESC* pApplicationDesc,
    _In_ CONST D3D12DDIARG_GETCAPS* pCaps
    );

typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_ENUMERATE_ADAPTER_FAMILIES)(
    D3D12DDI_HCOMPILERDDI hCompilerDDI,
    UINT AdapterFamilyIndex,
    _Out_ D3D12DDI_COMPILER_ADAPTER_FAMILY* pAdapterFamily
    );

typedef HRESULT(APIENTRY* PFND3D12DDI_COMPILER_ENUMERATE_ADAPTER_FAMILY_ABI_VERSIONS)(
    D3D12DDI_HCOMPILERDDI hCompilerDDI,
    UINT AdapterFamilyIndex,
    _Inout_ UINT* pNumABIVersions,
    _Out_writes_opt_(*pNumABIVersions) UINT64* pABIVersions
    );

typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_ENUMERATE_ADAPTER_FAMILY_COMPILER_VERSION)(
    D3D12DDI_HCOMPILERDDI hCompilerDDI,
    UINT AdapterFamilyIndex,
    _Out_ D3D12DDI_VERSION_NUMBER* pCompilerVersion
    );

typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_GET_APPLICATION_PROFILE_VERSION)(
    D3D12DDI_HCOMPILERDDI hCompilerDDI,
    _In_ CONST D3D12DDI_COMPILER_TARGET* pTarget,
    _In_ CONST D3D12DDI_APPLICATION_DESC* pApplicationDesc,
    _Out_ D3D12DDI_VERSION_NUMBER* pApplicationProfileVersion
    );

typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_CHECK_FORMAT_SUPPORT)(
    D3D12DDI_HCOMPILERDDI hCompilerDDI,
    _In_ CONST D3D12DDI_COMPILER_TARGET* pTarget,
    DXGI_FORMAT Format,
    _Out_ UINT* pFormatSupport
    );

typedef BOOL (APIENTRY *PFND3D12DDI_COMPILER_CHECK_MULTISAMPLE_QUALITY_LEVELS)(
    D3D12DDI_HCOMPILERDDI hCompilerDDI,
    _In_ CONST D3D12DDI_COMPILER_TARGET* pTarget,
    DXGI_FORMAT Format,
    UINT SampleCount,
    UINT QualityLevel
    );

// D3D12DDI_COMPILER_TABLE_TYPE_CAPABILITIES
typedef struct D3D12DDI_COMPILER_CAPABILITIES_FUNCS
{
    PFND3D12DDI_COMPILER_GET_CAPS                                   pfnGetCaps;
    PFND3D12DDI_COMPILER_ENUMERATE_ADAPTER_FAMILIES                 pfnEnumerateAdapterFamilies;
    PFND3D12DDI_COMPILER_ENUMERATE_ADAPTER_FAMILY_ABI_VERSIONS      pfnEnumerateAdapterFamilyABIVersions;
    PFND3D12DDI_COMPILER_ENUMERATE_ADAPTER_FAMILY_COMPILER_VERSION  pfnGetEnumerateAdapterFamilyCompilerVersion;
    PFND3D12DDI_COMPILER_GET_APPLICATION_PROFILE_VERSION            pfnGetApplicationProfileVersion;
    PFND3D12DDI_COMPILER_CHECK_FORMAT_SUPPORT                       pfnCheckFormatSupport;
    PFND3D12DDI_COMPILER_CHECK_MULTISAMPLE_QUALITY_LEVELS           pfnCheckMultisampleQualityLevels;

} D3D12DDI_COMPILER_CAPABILITIES_FUNCS;
```

<a id="get-caps"></a>

### PFND3D12DDI_COMPILER_GET_CAPS

Returns capabilities for D3D12 DDI Caps.

#### Parameters

`hCompilerDDI`

The handle to the plugin compiler DDI object.

`pTarget`

Contains the adapter family and ABI version.  See [D3D12DDI_COMPILER_TARGET](#descriptions).

`pApplicationDesc`

Describes the target application and version.  Not typically used, see Remarks.  See [D3D12DDI_APPLICATION_DESC](#descriptions).

`pCaps`

Cap type, inputs and outputs.  See [D3D12DDICAPS_TYPE](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/d3d12umddi/ne-d3d12umddi-d3d12ddicaps_type)

#### Remarks

This is expected to match UMD implementation for adapter drivers in the same adapter family.

The following caps may be queried:

- `D3D12DDICAPS_TYPE_SHADER`
- `D3D12DDICAPS_TYPE_D3D12_OPTIONS`
- `D3D12DDICAPS_TYPE_OPTIONS_*`
- `D3D12DDICAPS_TYPE_SHADER_MODEL_6_8_OPTIONS_0110`
- `D3D12DDICAPS_TYPE_0011_SHADER_MODELS`
- `D3D12DDICAPS_TYPE_0081_3DPIPELINESUPPORT1`

The Application Desc parameter pApplicationDesc should not typically be used.  On occasion, drivers have changed capability reporting for a specific application with known issues to work around those problems.

The selected usermode DDI version determines the capability payload layout.

<a id="family-enumeration"></a>

### Adapter family enumeration

Retrieve a list of all adapter families supported by the plugin.

#### Parameters

`hCompilerDDI`

The handle to the plugin compiler DDI object.

`AdapterFamilyIndex`

The index of the adapter family to enumerate.

`pAdapterFamily`

Describes the adapter family for the given AdapterFamilyIndex.  See [D3D12DDI_COMPILER_ADAPTER_FAMILY](#descriptions).

#### Remarks

Plugins must expose adapter families with contiguous indices starting at index zero.  When the index exceeds the available families, return DXGI_ERROR_NOT_FOUND.

Enumerating all adapter families can be accomplished like so:

```cpp
D3D12DDI_COMPILER_ADAPTER_FAMILY adapterFamily = {};
for (UINT AdapterFamilyIndex = 0; ; ++AdapterFamilyIndex)
{
    const HRESULT hr = pfnEnumerateAdapterFamilies(hCompilerDDI, AdapterFamilyIndex, &adapterFamily);
    if (hr == DXGI_ERROR_NOT_FOUND) break;
    if (FAILED(hr)) { /* Handle the failure. */ break; }
    // Consume adapterFamily.
}
```

<a id="abi-enumeration"></a>

### Adapter family ABI enumeration

Retrieve the list of ABI versions supported for an adapter family.

#### Parameters

`hCompilerDDI`

The handle to the plugin compiler DDI object.

`AdapterFamilyIndex`

The index of the target adapter family.  See [D3D12DDI_COMPILER_ADAPTER_FAMILY](#descriptions) and [PFND3D12DDI_COMPILER_ENUMERATE_ADAPTER_FAMILIES](#family-enumeration).

`pNumABIVersions`

On input, describes the capacity of pABIVersions in UINT64 elements.  `*pNumABIVersions` is zero when pABIVersions is nullptr.  This may be used to retrieve a partial list, see remarks.  On output, returns the number of ABI Versions for the adapter family.

`pABIVersions`

Receives the list of ABI Versions for the adapter family.  May be nullptr when performing a size check.

#### Remarks

Returns the compiler ABI version supported by the compiled binaries produced by this compiler.  This is compared with the supported ABI range of a driver to understand if precompiled binaries are supported.  See the [driver ABI compatibility payload](devices-and-capabilities.md#d3d12_feature_data_shadercache_abi_support) capability check. A range of ABI versions is supported for an adapter family to allow targeting adapters that may not be receiving driver updates.

Compiled objects produced by this compiler may not be used with drivers that do not report this ABI version in their supported ABI version range.

ABI version is used to check for precompiled cache updates and understand cache compatibility with drivers on the client, see [version domains](offline-compilation.md#version-domains).

If the adapter family is not one of the families returned by [PFND3D12DDI_COMPILER_ENUMERATE_ADAPTER_FAMILIES](#family-enumeration) and pNumABIVersions is valid, the plugin must set `*pNumABIVersions` to zero and return `DXGI_ERROR_NOT_FOUND`.

If pNumABIVersions is nullptr, return E_INVALIDARG.

If the adapter family is valid and pNumABIVersions is non-nullptr, always set \*pNumABIVersions to the correct number of ABI versions for the family on return, regardless of other success/failure. Otherwise, set it to zero.

pABIVersions may be nullptr when performing a size check.  In that case, set \*pNumABIVersions to the number of ABI versions for the adapter family and return S_OK.

ABIVersion 0x0 and UINT64_MAX(0xffffffffffffffffui64) are reserved and must not be returned.  Compilers report version 1 for the initial version of an adapter family's ABI, and then increment this counter every time the ABI version changes.

ABI Versions must be reported in descending order, so the latest ABI version appears at `pABIVersions[0]` and the oldest ABI version is at the highest index.  If the buffer size is insufficient, driver must fill out as many ABI versions as there is room for and report DXGI_ERROR_MORE_DATA.  For example, this may be used to only retrieve the latest ABI version supported.

If \*pNumABIVersions is equal to the number of ABI version or larger, copy the complete list and set \*pNumABIVersions to the correct number of entries.  Return S_OK.

<a id="versions-and-profiles"></a>

### Compiler version and profile version

<a id="ddi-compiler-version"></a>

#### PFND3D12DDI_COMPILER_ENUMERATE_ADAPTER_FAMILY_COMPILER_VERSION

Describes the version of a compiler for an adapter family.

##### Parameters

`hCompilerDDI`

The handle to the plugin compiler DDI object.

`AdapterFamilyIndex`

The index specifies adapter family.  See [D3D12DDI_COMPILER_ADAPTER_FAMILY](#ddi-target-descriptions) and [PFND3D12DDI_COMPILER_ENUMERATE_ADAPTER_FAMILIES](#family-enumeration).

`pCompilerVersion`

Compiler version changes signify changes in code generation that potentially impact all applications for an adapter family.  See [D3D12DDI_VERSION_NUMBER](#d3d12ddi_version_number).

##### Remarks

Major/Minor version change for "must" recompile such as security or major fixes.  Build for "should" recompile such as performance.  Revision for less consequential changes that shouldn't invalidate caches.

When the family version is absent, the plugin returns `DXGI_ERROR_NOT_FOUND`. The runtime must not consume failed compiler version output as a result. A failure does not guarantee a zero version.

<a id="ddi-profile-version"></a>

#### PFND3D12DDI_COMPILER_GET_APPLICATION_PROFILE_VERSION

Return the application profile version number.  An application profile is any application dependent profile or settings that do not impact compilation for other applications.  Any time those settings change for a given application, update the version number.

##### Parameters

`hCompilerDDI`

The handle to the plugin compiler DDI object.

`pTarget`

Contains the adapter family and ABI version.  See [D3D12DDI_COMPILER_TARGET](#descriptions).

`pApplicationDesc`

Describes the target application and version.  See [D3D12DDI_APPLICATION_DESC](#descriptions).

`pApplicationProfileVersion`

Describes the version of the compiler profile that targets a specific application.  Applications are specified by application identifier and application version.  Compilers may revise this number to indicate application specific changes to compiler output.  See [D3D12DDI_VERSION_NUMBER](#d3d12ddi_version_number).

##### Remarks

The compiler profile can be versioned when there are application specific changes to these profiles that do not impact other applications.  This prevents invalidating caches for all applications when a change is application specific.

A profile query with no applicable application or engine
profile succeeds with version zero. See
[GetApplicationProfileVersion](offline-compilation.md#id3d12compilerfactory-getapplicationprofileversion)
for API target validation.

<a id="formats"></a>

### Format and multisample queries

See [Format queries](formats.md#format-query-cases)
for format support bits and sample quality indices, and
[Multisampling](rasterization.md#multisampling) for sample coverage and patterns.

<a id="ddi-format-support"></a>

#### PFND3D12DDI_COMPILER_CHECK_FORMAT_SUPPORT

Check support for features that are optional on some formats.

##### Parameters

`hCompilerDDI`

The handle to the plugin compiler DDI object.

`pTarget`

Contains the adapter family and ABI version.  See [D3D12DDI_COMPILER_TARGET](#descriptions).

`Format`

A [DXGI_FORMAT](formats.md#dxgi-format) value for the format to return info about.

`pFormatSupport`

A D3D12DDI_FORMAT_SUPPORT bitfield for features that are optional on some formats.

##### Remarks

This is expected to match UMD implementation for adapter drivers in the same adapter family.

<a id="ddi-multisample"></a>

#### PFND3D12DDI_COMPILER_CHECK_MULTISAMPLE_QUALITY_LEVELS

Queries if the image quality level is supported for a given format and sample count.

##### Parameters

`hCompilerDDI`

The handle to the plugin compiler DDI object.

`pTarget`

Contains the adapter family and ABI version.  See [D3D12DDI_COMPILER_TARGET](#descriptions).

`Format`

A [DXGI_FORMAT](formats.md#dxgi-format) value for the format to check.

`SampleCount`

The number of multi-samples per pixel to check.

`QualityLevel`

The quality level to check.

##### Remarks

Returns TRUE if supported, FALSE otherwise.  This is expected to be consistent with the UMD implementation for adapter drivers in the same adapter family.

The multisample query checks a particular quality level rather than enumerating
a quality level count.

<a id="callback-dependencies"></a>

<a id="callback-table-abi-dependencies"></a>

## Cache callback table

See
[Value lookup](compiler-invocation-and-cache-output.md#pfnd3d12ddi_compiler_cache_find_value_cb)
for result and allocation handling,
[Value storage](compiler-invocation-and-cache-output.md#pfnd3d12ddi_compiler_cache_store_value_cb)
for typed input and failure handling, and
[Object value key registration](compiler-invocation-and-cache-output.md#pfnd3d12ddi_compiler_cache_set_object_value_keys_cb)
for the mapping from compiled values to the input object.

```cpp
typedef enum D3D12DDI_COMPILER_CACHE_VALUE_TYPE
{
    D3D12DDI_COMPILER_CACHE_VALUE_TYPE_OBJECT_CODE        = 0,
    D3D12DDI_COMPILER_CACHE_VALUE_TYPE_METADATA           = 1,
    D3D12DDI_COMPILER_CACHE_VALUE_TYPE_DEBUG_PDB          = 2,
    D3D12DDI_COMPILER_CACHE_VALUE_TYPE_PERFORMANCE_DATA   = 3,

} D3D12DDI_COMPILER_CACHE_VALUE_TYPE;

typedef enum D3D12DDI_COMPILER_VALUE_TYPE_FLAGS
{
    D3D12DDI_COMPILER_CACHE_VALUE_TYPE_FLAG_NONE = 0x00000000,
    D3D12DDI_COMPILER_CACHE_VALUE_TYPE_FLAG_OBJECT_CODE = (1 << D3D12DDI_COMPILER_CACHE_VALUE_TYPE_OBJECT_CODE),
    D3D12DDI_COMPILER_CACHE_VALUE_TYPE_FLAG_METADATA = (1 << D3D12DDI_COMPILER_CACHE_VALUE_TYPE_METADATA),
    D3D12DDI_COMPILER_CACHE_VALUE_TYPE_FLAG_DEBUG_PDB = (1 << D3D12DDI_COMPILER_CACHE_VALUE_TYPE_DEBUG_PDB),
    D3D12DDI_COMPILER_CACHE_VALUE_TYPE_FLAG_PERFORMANCE_DATA = (1 << D3D12DDI_COMPILER_CACHE_VALUE_TYPE_PERFORMANCE_DATA),

} D3D12DDI_COMPILER_CACHE_VALUE_TYPE_FLAGS;
DEFINE_ENUM_FLAG_OPERATORS( D3D12DDI_COMPILER_CACHE_VALUE_TYPE_FLAGS )
```

```cpp
typedef struct D3D12DDI_COMPILER_CACHE_VALUE_KEY
{
    _Field_size_bytes_full_(KeySize) const void* pKey;
    UINT KeySize;
} D3D12DDI_COMPILER_CACHE_VALUE_KEY;

typedef struct D3D12DDI_COMPILER_CACHE_VALUE
{
    _Field_size_bytes_opt_(ValueSize) void* pValue;
    SIZE_T ValueSize;
} D3D12DDI_COMPILER_CACHE_VALUE;

typedef struct D3D12DDI_COMPILER_CACHE_TYPED_VALUE
{
    D3D12DDI_COMPILER_CACHE_VALUE_TYPE  Type;
    D3D12DDI_COMPILER_CACHE_VALUE       Value;
} D3D12DDI_COMPILER_CACHE_TYPED_VALUE;

typedef struct D3D12DDI_COMPILER_CACHE_CONST_VALUE
{
    _Field_size_bytes_opt_(ValueSize) const void* pValue;
    SIZE_T ValueSize;
} D3D12DDI_COMPILER_CACHE_CONST_VALUE;

typedef struct D3D12DDI_COMPILER_CACHE_TYPED_CONST_VALUE
{
    D3D12DDI_COMPILER_CACHE_VALUE_TYPE  Type;
    D3D12DDI_COMPILER_CACHE_CONST_VALUE Value;
} D3D12DDI_COMPILER_CACHE_TYPED_CONST_VALUE;

typedef void* (__stdcall* PFND3D12DDI_COMPILER_ALLOCATION) (
    SIZE_T SizeInBytes,
    _Inout_opt_ void* pContext
    );

typedef HRESULT (APIENTRY CALLBACK *PFND3D12DDI_COMPILER_CACHE_FIND_VALUE_CB)(
    D3D12DDI_HRTCOMPILERCACHESESSION hrtCompilerCache,
    _In_ const D3D12DDI_COMPILER_CACHE_VALUE_KEY* pValueKey,
    _Inout_count_(NumValues) D3D12DDI_COMPILER_CACHE_TYPED_VALUE* pValues,
    UINT NumValues,
    _In_opt_ PFND3D12DDI_COMPILER_ALLOCATION pCallbackFunc,
    _Inout_opt_ void* pContext
    );

typedef HRESULT (APIENTRY CALLBACK *PFND3D12DDI_COMPILER_CACHE_STORE_VALUE_CB)(
    D3D12DDI_HRTCOMPILERCACHESESSION hrtCompilerCacheSession,
    _In_ const D3D12DDI_COMPILER_CACHE_VALUE_KEY* pValueKey,
    _In_reads_(NumValues) const D3D12DDI_COMPILER_CACHE_TYPED_CONST_VALUE* pValues,
    UINT NumValues
    );

typedef HRESULT (APIENTRY CALLBACK *PFND3D12DDI_COMPILER_CACHE_SET_OBJECT_VALUE_KEYS_CB)(
    D3D12DDI_HRTCOMPILERCACHESESSION hrtCompilerCacheSession,
    _In_reads_(NumValueKeys) const D3D12DDI_COMPILER_CACHE_VALUE_KEY* pValueKeys,
    UINT NumValueKeys
    );

typedef struct D3D12DDI_COMPILER_CACHE_CALLBACKS
{
    PFND3D12DDI_COMPILER_CACHE_FIND_VALUE_CB pfnCompilerCacheFindValue;
    PFND3D12DDI_COMPILER_CACHE_STORE_VALUE_CB pfnCompilerCacheStoreValue;
    PFND3D12DDI_COMPILER_CACHE_SET_OBJECT_VALUE_KEYS_CB pfnCompilerCacheSetObjectValueKeys;
} D3D12DDI_COMPILER_CACHE_CALLBACKS;
```

<a id="compiler-table-dependencies"></a>

<a id="compiler-table-abi-dependencies"></a>

## Compiler function table

The declarations below use compiler DDI build 2. Negotiation selects the actual layout. Common root signature, state object and pipeline types come from the selected usermode DDI version.

See [compiler creation](compiler-invocation-and-cache-output.md#pfnd3d12ddi_compiler_create_compiler), [pipeline compilation](compiler-invocation-and-cache-output.md#pfnd3d12ddi_compiler_compile_pipeline_state), [state object compilation](compiler-invocation-and-cache-output.md#pfnd3d12ddi_compiler_compile_create_state_object) and [incremental additions](compiler-invocation-and-cache-output.md#pfnd3d12ddi_compiler_compile_add_to_state_object) for the invoked behavior, output completion and dependency lifetimes of these declarations.

```cpp
typedef struct D3D12DDI_COMPILER_SHADER_DESC
{
    CONST UINT *pShaderCode;
    union
    {
        CONST D3D12DDIARG_STAGE_IO_SIGNATURES *Standard;
        CONST D3D12DDIARG_TESSELLATION_IO_SIGNATURES *Tessellation;
        CONST D3D12DDIARG_MESH_IO_SIGNATURES *Mesh;
    } IOSignatures;
    D3D12DDI_CREATE_SHADER_FLAGS Flags;
    D3D12DDI_SHADERCACHE_HASH ShaderCodeHash;
} D3D12DDI_COMPILER_SHADER_DESC;

typedef struct D3D12DDI_COMPILER_GEOMETRY_SHADER
{
    D3D12DDI_COMPILER_SHADER_DESC Shader;
    CONST D3D12DDIARG_STREAM_OUTPUT_DECLARATION_ENTRY *pOutputStreamDecl;
    UINT NumEntries;
    CONST UINT *BufferStridesInBytes;
    UINT NumStrides;
    UINT RasterizedStream;
} D3D12DDI_COMPILER_GEOMETRY_SHADER;

typedef D3D12DDI_BLEND_DESC D3D12DDI_COMPILER_BLEND_DESC;

typedef D3D12DDIARG_CREATEELEMENTLAYOUT D3D12DDI_COMPILER_ELEMENTLAYOUT_DESC;

typedef D3D12DDIARG_CREATE_ROOT_SIGNATURE_0100 D3D12DDI_COMPILER_ROOT_SIGNATURE_DESC;

typedef struct D3D12DDI_COMPILER_RASTERIZER_DESC
{
    D3D12DDI_FILL_MODE FillMode;
    D3D12DDI_CULL_MODE CullMode;
    BOOL FrontCounterClockwise;
    FLOAT DepthBias;
    FLOAT DepthBiasClamp;
    FLOAT SlopeScaledDepthBias;
    BOOL DepthClipEnable;
    BOOL ScissorEnable;
    D3D12DDI_LINE_RASTERIZATION_MODE LineRasterizationMode;
    UINT ForcedSampleCount;
    D3D12DDI_CONSERVATIVE_RASTERIZATION_MODE ConservativeRasterizationMode;
} D3D12DDI_COMPILER_RASTERIZER_DESC;

typedef struct D3D12DDI_COMPILER_DEPTH_STENCIL_DESC
{
    BOOL DepthEnable;
    D3D12DDI_DEPTH_WRITE_MASK DepthWriteMask;
    D3D12DDI_COMPARISON_FUNC DepthFunc;
    BOOL StencilEnable;
    BOOL FrontEnable;
    BOOL BackEnable;
    UINT8 FrontFaceStencilReadMask;
    UINT8 FrontFaceStencilWriteMask;
    D3D12DDI_DEPTH_STENCILOP_DESC FrontFace;
    D3D12DDI_DEPTH_STENCILOP_DESC BackFace;
    BOOL DepthBoundsTestEnable;
    UINT8 BackFaceStencilReadMask;
    UINT8 BackFaceStencilWriteMask;
} D3D12DDI_COMPILER_DEPTH_STENCIL_DESC;

typedef D3D12DDI_VIEW_INSTANCING_DESC D3D12DDI_COMPILER_VIEW_INSTANCING_DESC;

typedef struct D3D12DDIARG_COMPILER_COMPILE_PIPELINE_STATE
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
} D3D12DDIARG_COMPILER_COMPILE_PIPELINE_STATE;

typedef SIZE_T (APIENTRY *PFND3D12DDI_COMPILER_CALC_PRIVATE_COMPILER_SIZE)(
    D3D12DDI_HCOMPILERDDI hCompilerDDI,
    _In_ CONST D3D12DDI_COMPILER_TARGET* pTarget,
    _In_ CONST D3D12DDI_APPLICATION_DESC* pApplicationDesc
    );

typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_CREATE_COMPILER)(
    D3D12DDI_HCOMPILERDDI hCompilerDDI,
    _In_ CONST D3D12DDI_COMPILER_TARGET* pTarget,
    _In_ CONST D3D12DDI_APPLICATION_DESC* pApplicationDesc,
    D3D12DDI_HCOMPILER hCompiler,
    D3D12DDI_HRTCOMPILER hRTCompiler
    );

typedef VOID (APIENTRY *PFND3D12DDI_COMPILER_DESTROY_COMPILER)(
    D3D12DDI_HCOMPILERDDI hCompilerDDI,
    D3D12DDI_HCOMPILER hCompiler
    );

typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_COMPILE_PIPELINE_STATE)(
    D3D12DDI_HCOMPILER hCompiler,
    D3D12DDI_HRTCOMPILERCACHESESSION hrtCompilerCacheSession,
    D3D12DDI_COMPILER_VALUE_TYPE_FLAGS ValueTypeFlags,
    CONST D3D12DDIARG_COMPILER_COMPILE_PIPELINE_STATE* pPipelineStateArg
    );

typedef SIZE_T (APIENTRY *PFND3D12DDI_COMPILER_CALC_PRIVATE_STATE_OBJECT_SIZE)(
    D3D12DDI_HCOMPILER hCompiler,
    _In_ CONST D3D12DDIARG_CREATE_STATE_OBJECT_0054* pCreateStateObject
    );

typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_COMPILE_CREATE_STATE_OBJECT)(
    D3D12DDI_HCOMPILER hCompiler,
    D3D12DDI_HRTCOMPILERCACHESESSION hrtCompilerCacheSession,
    D3D12DDI_COMPILER_VALUE_TYPE_FLAGS ValueTypeFlags,
    _In_ CONST D3D12DDIARG_CREATE_STATE_OBJECT_0054* pCreateStateObject,
    D3D12DDI_HCOMPILERSTATEOBJECT hStateObject
    );

typedef SIZE_T (APIENTRY *PFND3D12DDI_COMPILER_CALC_PRIVATE_ADD_TO_STATE_OBJECT_SIZE)(
    D3D12DDI_HCOMPILER hCompiler,
    _In_ CONST D3D12DDIARG_ADD_TO_STATE_OBJECT_0072* pAddToStateObject
    );

typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_COMPILE_ADD_TO_STATE_OBJECT)(
    D3D12DDI_HCOMPILER hCompiler,
    D3D12DDI_HRTCOMPILERCACHESESSION hrtCompilerCacheSession,
    D3D12DDI_COMPILER_VALUE_TYPE_FLAGS ValueTypeFlags,
    _In_ CONST D3D12DDIARG_ADD_TO_STATE_OBJECT_0072* pAddToStateObject,
    D3D12DDI_HCOMPILERSTATEOBJECT hStateObject
    );

typedef VOID ( APIENTRY* PFND3D12DDI_COMPILER_DESTROY_STATE_OBJECT )(
    D3D12DDI_HCOMPILER hCompiler,
    D3D12DDI_HCOMPILERSTATEOBJECT hStateObject
    );

// D3D12DDI_COMPILER_TABLE_TYPE_COMPILER
typedef struct D3D12DDI_COMPILER_FUNCS
{
    PFND3D12DDI_COMPILER_CALC_PRIVATE_COMPILER_SIZE             pfnCalcPrivateCompilerSize;
    PFND3D12DDI_COMPILER_CREATE_COMPILER                        pfnCreateCompiler;
    PFND3D12DDI_COMPILER_DESTROY_COMPILER                       pfnDestroyCompiler;
    PFND3D12DDI_COMPILER_COMPILE_PIPELINE_STATE                 pfnCompilePipelineState;
    PFND3D12DDI_COMPILER_CALC_PRIVATE_STATE_OBJECT_SIZE         pfnCalcPrivateStateObjectSize;
    PFND3D12DDI_COMPILER_COMPILE_CREATE_STATE_OBJECT            pfnCompileCreateStateObject;
    PFND3D12DDI_COMPILER_CALC_PRIVATE_ADD_TO_STATE_OBJECT_SIZE  pfnCalcPrivateAddToStateObjectSize;
    PFND3D12DDI_COMPILER_COMPILE_ADD_TO_STATE_OBJECT            pfnCompileAddToStateObject;
    PFND3D12DDI_COMPILER_DESTROY_STATE_OBJECT                   pfnDestroyStateObject;
} D3D12DDI_COMPILER_FUNCS;
```
