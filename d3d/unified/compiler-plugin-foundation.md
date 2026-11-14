<a id="compiler-plugin-foundation"></a>

# Compiler plugin foundation

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

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:plugin-scope:0:authored:migration-8462ac43ea4d2c45-0 -->This implementer-facing reference accompanies the
[compiler factory and target API](offline-compilation.md).<!-- d3d12-review-inline:end:compiler-plugin-foundation:plugin-scope:0:authored:migration-8462ac43ea4d2c45-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:plugin-scope:1:authored:migration-275aea87a429034d-0 -->The published ABI is `d3d12compilerddi.h` in [WDK 10.0.28000.2526](https://www.nuget.org/packages/Microsoft.Windows.WDK.x64/10.0.28000.2526). It uses shared `d3d12umddi.h` definitions and the declared calling conventions.<!-- d3d12-review-inline:end:compiler-plugin-foundation:plugin-scope:1:authored:migration-275aea87a429034d-0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:handle-dependencies:0:authored:migration-39033cda3d05abd7-0 -->`D3D10DDI_H` and `D3D10DDI_HRT` are the driver-private and runtime-private
handle declaration macros supplied by `d3d12umddi.h` and its dependencies.
They are distinct handle types, not interchangeable raw API object pointers.
`D3D12DDI_HCOMPILERSTATEOBJECT` is the published alias of
`D3D12DDI_HSTATEOBJECT_0054`.<!-- d3d12-review-inline:end:compiler-plugin-foundation:handle-dependencies:0:authored:migration-39033cda3d05abd7-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:handle-dependencies:1:authored:migration-5a9b1c7ea18a950d-0 -->The [plugin DDI version](offline-compilation.md#plugin-ddi-version) is distinct
from compiler package, adapter family ABI and application versions.<!-- d3d12-review-inline:end:compiler-plugin-foundation:handle-dependencies:1:authored:migration-5a9b1c7ea18a950d-0 --></ins>

<a id="compiler-ddi-handle"></a>

### D3D12DDI_HCOMPILERDDI

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:handle-life:0:modified:migration-2867754e99d453b3-0 -->`D3D12DDI_HCOMPILERDDI` is a handle to the compiler plugin object<!-- d3d12-review-inline:end:compiler-plugin-foundation:handle-life:0:modified:migration-2867754e99d453b3-0 --></ins> created when opening the plugin DDI.  This object negotiates the DDI version.  <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:handle-life:0:modified:migration-c9e9ff4aae524113-1 -->When this object is destroyed<!-- d3d12-review-inline:end:compiler-plugin-foundation:handle-life:0:modified:migration-c9e9ff4aae524113-1 --></ins>, any objects or function tables retrieved from the plugin are no longer used.

<a id="runtime-ddi-handle"></a>

### D3D12DDI_HRTCOMPILERDDI

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:runtime-handle:0:modified:migration-aaa852d189548cef-0 -->`D3D12DDI_HRTCOMPILERDDI` identifies the compiler runtime's object for the DDI.<!-- d3d12-review-inline:end:compiler-plugin-foundation:runtime-handle:0:modified:migration-aaa852d189548cef-0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:DEL-I03-open-entry:0:modified:complete-sentence -->IHVs export the compiler plugin's initial entry point as `D3D12OpenCompilerDDI`.<!-- d3d12-review-inline:end:compiler-plugin-foundation:DEL-I03-open-entry:0:modified:complete-sentence --></ins>

Opens the compiler DDI and retrieves the initial DDI table for version negotiation and further DDI table retrieval.

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:open-parameters:0:authored:migration-e91ebb72fc8b3088-0 -->`pOpenDDIArg` is required in/out storage. The runtime supplies
`hRTCompilerDDI` and writable `pDDIFuncs` storage. On success the plugin supplies
its allocated `hCompilerDDI` object and fills the initial negotiation table.
The plugin handle is owned by the plugin. The runtime returns it to
`pfnDestroyCompilerDDI` when finished. Destroying it invalidates retrieved
function tables and ends use of all dependent plugin objects.<!-- d3d12-review-inline:end:compiler-plugin-foundation:open-parameters:0:authored:migration-e91ebb72fc8b3088-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:open-parameters:1:authored:migration-bb89099be6b8113b-0 -->The runtime calls these pointers only while the plugin module and DDI object
are alive. The COM factory's [ownership contract](offline-compilation.md#factory-child)
keeps its plugin DDI alive while children retain the factory.<!-- d3d12-review-inline:end:compiler-plugin-foundation:open-parameters:1:authored:migration-bb89099be6b8113b-0 --></ins>

<a id="destroy"></a>

### PFND3D12DDI_COMPILER_DESTROY_DDI

Destroys the compiler DDI object.  Any function tables retrieved from the DDI are now invalid to use.

**Parameters**

*hCompilerDDI*

The handle to the plugin compiler DDI object.

<a id="negotiation"></a>

## Version enumeration and selection

<a id="supported-versions"></a>

### PFND3D12DDI_COMPILER_GET_SUPPORTED_VERSIONS

Retrieves the list of State Object <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:supported-version-behavior:0:modified:migration-3dc3795140d898c3-0 -->Compiler DDI versions supported<!-- d3d12-review-inline:end:compiler-plugin-foundation:supported-version-behavior:0:modified:migration-3dc3795140d898c3-0 --></ins> by the compiler plugin.  It is only necessary to expose a new DDI version from the compiler plugin when caps or definitions related to state objects change (i.e. it does not need to rev every time <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:supported-version-behavior:0:modified:migration-536b621160a1917f-1 -->driver version does, but<!-- d3d12-review-inline:end:compiler-plugin-foundation:supported-version-behavior:0:modified:migration-536b621160a1917f-1 --></ins> it can)

NOTE: This is not the same series of version numbers as the D3D12 runtime Usermode DDI, it is a version series dedicated to the State Object Compiler so it may be versioned independently.  However, each State Object Compiler version is assigned a single D3D12 Usermode DDI version at design time to make it clear which version of shared concepts such as PSO Descs, SO Descs, and shared caps are in use.  For clarity, this Usermode DDI version is set at runtime during <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:supported-version-behavior:1:preserved-repair:source-2d0a31c4aa0e4507-0-0 -->[PFND3D12DDI_COMPILER_SET_SELECTED_VERSION](#negotiation)<!-- d3d12-review-inline:end:compiler-plugin-foundation:supported-version-behavior:1:preserved-repair:source-2d0a31c4aa0e4507-0-0 --></ins>.

The plugin runtime calls the plugin to retrieve a list of the supported DDI versions.

Upon return, assign the size of the supported versions array to <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:supported-version-remarks:1:modified:migration-f14b345a86556462-0 -->`*puEntries`.<!-- d3d12-review-inline:end:compiler-plugin-foundation:supported-version-remarks:1:modified:migration-f14b345a86556462-0 --></ins>

When checking size of the array, the runtime will call the plugin <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:supported-version-remarks:2:modified:migration-de7e4661f6446ab7-0 -->with<!-- d3d12-review-inline:end:compiler-plugin-foundation:supported-version-remarks:2:modified:migration-de7e4661f6446ab7-0 --></ins> <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:supported-version-remarks:2:modified:migration-966b8f5a6c547127-1 -->`*puEntries` initially<!-- d3d12-review-inline:end:compiler-plugin-foundation:supported-version-remarks:2:modified:migration-966b8f5a6c547127-1 --></ins> set to zero and <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:supported-version-remarks:2 -->pSupportedPluginDDIVersions<!-- d3d12-review-inline:end:compiler-plugin-foundation:supported-version-remarks:2 --></ins> set to nullptr.

When requesting the array, <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:supported-version-remarks:3:modified:migration-b2a7cb26b88e5d7a-0 -->`*puEntries` will<!-- d3d12-review-inline:end:compiler-plugin-foundation:supported-version-remarks:3:modified:migration-b2a7cb26b88e5d7a-0 --></ins> be the size of the <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:supported-version-remarks:3 -->pSupportedPluginDDIVersions<!-- d3d12-review-inline:end:compiler-plugin-foundation:supported-version-remarks:3 --></ins>.  Plugin copies the version list into this array.

<a id="selected-version"></a>

### PFND3D12DDI_COMPILER_SET_SELECTED_VERSION

Sets the DDI version that the State Object Compiler runtime selects from the list the compiler plugin provides to PFND3D12DDI_COMPILER_GET_SUPPORTED_VERSIONS.  The runtime typically picks the latest version supported by both the plugin and the compiler runtime.

#### Selected-version parameters

*hCompilerDDI*

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:selected-version-behavior:3:authored:migration-e949145f7cdb95ab-0 -->The handle to the live plugin compiler DDI object.<!-- d3d12-review-inline:end:compiler-plugin-foundation:selected-version-behavior:3:authored:migration-e949145f7cdb95ab-0 --></ins>

*PluginDDIVersion*

The <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:selected-version-behavior:5:modified:source-d5767a242c478597-0-0 -->plugin DDI version selected from the list reported by the plugin during [PFND3D12DDI_COMPILER_GET_SUPPORTED_VERSIONS](#negotiation).  This version number dictates which version of function<!-- d3d12-review-inline:end:compiler-plugin-foundation:selected-version-behavior:5:modified:source-d5767a242c478597-0-0 --></ins> tables and behaviors<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:selected-version-behavior:5:modified:source-d5767a242c478597-0-1 --> are<!-- d3d12-review-inline:end:compiler-plugin-foundation:selected-version-behavior:5:modified:source-d5767a242c478597-0-1 --></ins> used.

*UsermodeDDIVersion*

The D3D12 runtime usermode DDI version associated with PluginDDIVersion.

#### Selection ordering

This function must be called before any calls to PFND3D12DDI_COMPILER_FILL_DDI_TABLE.

When a new PluginDDIVersion is introduced, it is assigned a UsermodeDDIVersion at design time.  The UsermodeDDIVersion may not change for a given PluginDDIVersion.  The compiler plugin must only report PluginDDIVersions that it also supports with the corresponding UsermodeDDIVersion.  UsermodeDDIVersion is provided for clarity to indicate which version of concepts shared with the D3D12 runtime are in use, such as PSO Descs, SO Descs, and some shared caps.  This version may be relied upon when sharing implementation with the D3D12 Usermode Driver.  See <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:selected-version-behavior:10:modified:source-38a8746ee66daaff-0-0 -->[Compiler independence](offline-compilation.md#availability)<!-- d3d12-review-inline:end:compiler-plugin-foundation:selected-version-behavior:10:modified:source-38a8746ee66daaff-0-0 --></ins>.

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:negotiation-results:1:authored:migration-d41ea219884fae61-0 -->An empty intersection causes compiler factory creation to fail with
`DXGI_ERROR_UNSUPPORTED`. The runtime selects the greatest exact
intersection member. It does not negotiate an unreported compatible version.
Failures from plugin opening and version retrieval/selection fail factory
creation.<!-- d3d12-review-inline:end:compiler-plugin-foundation:negotiation-results:1:authored:migration-d41ea219884fae61-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:published-pairs:0:authored:migration-185a1683092e4d86-0 -->The runtime associates the following published compiler DDI values with their
usermode DDI definition:<!-- d3d12-review-inline:end:compiler-plugin-foundation:published-pairs:0:authored:migration-185a1683092e4d86-0 --></ins>

<!-- d3d12-review-alert:begin:compiler-plugin-foundation:published-pairs:1:authored:migration-4798d9df15e90cda-0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Compiler plugin DDI | Associated usermode DDI |
> | --- | --- |
> | `D3D12DDI_COMPILER_SUPPORTED_0001` | `D3D12DDI_SUPPORTED_0115` |
> | `D3D12DDI_COMPILER_SUPPORTED_0002` | `D3D12DDI_SUPPORTED_0115` |

<!-- d3d12-review-alert:end:compiler-plugin-foundation:published-pairs:1:authored:migration-4798d9df15e90cda-0 -->

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:published-pairs:2:authored:migration-237fb054d7b77f11-0 -->The second column is the version passed to `pfnSetSelectedVersion` together
with the selected first-column value. It is not the installed display driver's
version and is not selected from the plugin's adapter family ABI list.<!-- d3d12-review-inline:end:compiler-plugin-foundation:published-pairs:2:authored:migration-237fb054d7b77f11-0 --></ins>

<a id="tables"></a>

## Table retrieval and callback registration

<a id="fill-table"></a>

### PFND3D12DDI_COMPILER_FILL_DDI_TABLE

Request additional function tables from the compiler plugin.

#### Retrieval parameters

*hCompilerDDI*

The handle to the plugin compiler DDI object.

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:fill-table:4 -->*TableType*<!-- d3d12-review-inline:end:compiler-plugin-foundation:fill-table:4 --></ins>

Determines the type of pTable.  See <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:fill-table:5:preserved-repair:source-47d78389caa3e14e-0-0 -->[D3D12DDI_COMPILER_TABLE_TYPE](#open)<!-- d3d12-review-inline:end:compiler-plugin-foundation:fill-table:5:preserved-repair:source-47d78389caa3e14e-0-0 --></ins>.

*pTable*

Buffer pointer that the plugin must copy the function table <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:fill-table:7:modified:source-c5637e872afb372a-0-0 -->to<!-- d3d12-review-inline:end:compiler-plugin-foundation:fill-table:7:modified:source-c5637e872afb372a-0-0 --></ins>.

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:fill-table:8 -->*TableSize*<!-- d3d12-review-inline:end:compiler-plugin-foundation:fill-table:8 --></ins>

The size in bytes of the pTable buffer.

#### Retrieval ordering

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:fill-table:11:preserved-repair:source-18ac091a85e63207-0-0 -->[PFND3D12DDI_COMPILER_SET_SELECTED_VERSION](#negotiation)<!-- d3d12-review-inline:end:compiler-plugin-foundation:fill-table:11:preserved-repair:source-18ac091a85e63207-0-0 --></ins> must be called by the plugin runtime before calling this function.  This enables function table versioning based on the selected version.

<a id="callback-table-type"></a>

### D3D12DDI_COMPILER_CALLBACK_TABLE_TYPE

Specifies which table is being set during PFND3D12DDI_COMPILER_SET_CALLBACK_DDI_TABLE.

**Constants**

*D3D12DDI_COMPILER_CALLBACK_TABLE_TYPE_CACHE*

Sets the D3D12DDI_COMPILER_CACHE_CALLBACKS table that allows for finding and storing cached values.  This table is always set before any compiler objects are created.

<a id="set-callback-table"></a>

### PFND3D12DDI_COMPILER_SET_CALLBACK_DDI_TABLE

Sets function tables that the driver uses to callback into the State Object Compiler runtime.

#### Registration parameters

*hCompilerDDI*

The handle to the plugin compiler DDI object.

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:set-callback:4 -->*TableType*<!-- d3d12-review-inline:end:compiler-plugin-foundation:set-callback:4 --></ins>

Determines the type of pTable.  See <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:set-callback:5:preserved-repair:source-0cbb6ef8cfe16d54-0-0 -->[D3D12DDI_COMPILER_CALLBACK_TABLE_TYPE](#open)<!-- d3d12-review-inline:end:compiler-plugin-foundation:set-callback:5:preserved-repair:source-0cbb6ef8cfe16d54-0-0 --></ins>.

*pTable*

Buffer pointer that contains the State Object Compiler runtime callback table.

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:set-callback:8 -->*TableSize*<!-- d3d12-review-inline:end:compiler-plugin-foundation:set-callback:8 --></ins>

The size in bytes of the pTable buffer.

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:table-rules:0:authored:migration-62761e883364a025-0 -->Both table calls use a byte count (`SIZE_T TableSize`), not a function count.
`pfnFillDDITable` writes the selected table to runtime-provided writable storage;
`pfnSetCallbackDDITable` reads a runtime-provided callback table.
`D3D12DDI_COMPILER_TABLE_TYPE_CAPABILITIES` selects the complete capabilities
table below. `D3D12DDI_COMPILER_TABLE_TYPE_COMPILER` selects the dependent compiler
function table declared in the ABI dependency section.<!-- d3d12-review-inline:end:compiler-plugin-foundation:table-rules:0:authored:migration-62761e883364a025-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:table-rules:1:authored:migration-b9227e485c18a1a7-0 -->The cache callback table is installed before compiler objects are created.
The factory retrieves both capability and compiler tables during creation and
installs the cache callbacks. Failure in any of those steps prevents successful
factory creation. Selecting a DDI version precedes table retrieval. The selected
version determines the table layout.<!-- d3d12-review-inline:end:compiler-plugin-foundation:table-rules:1:authored:migration-b9227e485c18a1a7-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:plugin-synchronization:0:authored:migration-9e6e4acfb8eb3593-0 -->The compiler plugin must synchronize its internal state as necessary.
Concurrent compiler API calls do not require external application
synchronization. See [Threading and call lifetime](offline-compilation.md#threading).<!-- d3d12-review-inline:end:compiler-plugin-foundation:plugin-synchronization:0:authored:migration-9e6e4acfb8eb3593-0 --></ins>

<a id="descriptions"></a>

## Shared and target descriptions

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:shared-types:0:authored:migration-16dac5958c72fbe7-0 -->Shared application/version metadata is defined under [application metadata](state-object-databases-and-identity.md#application-metadata). The compiler receives the supplied offline identity rather than detecting its host process as the title.<!-- d3d12-review-inline:end:compiler-plugin-foundation:shared-types:0:authored:migration-16dac5958c72fbe7-0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:family-ddi:0 -->`szAdapterFamily` uniquely identifies an adapter family for a hardware vendor.<!-- d3d12-review-inline:end:compiler-plugin-foundation:family-ddi:0 --></ins>

An adapter family is a set of adapters that all share the same compiled output for a given ABI version.

The runtime validates the ABIVersion is one returned from <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:target-ddi-remarks:0:modified:source-ed914748bb74daf2-0-0 -->[PFND3D12DDI_COMPILER_ENUMERATE_ADAPTER_FAMILY_ABI_VERSIONS](#abi-enumeration)<!-- d3d12-review-inline:end:compiler-plugin-foundation:target-ddi-remarks:0:modified:source-ed914748bb74daf2-0-0 --></ins>.

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:ddi-target-members:0:authored:migration-9edc6247ce0c74fd-0 -->`AdapterFamilyIndex` is the enumerated family index. `ABIVersion` is the selected
target ABI. The API resolves its zero-ABI request before passing a target to
the plugin. `szAdapterFamily` is an inline 128-element `WCHAR` string buffer;
it is not an allocation or an input capacity parameter.<!-- d3d12-review-inline:end:compiler-plugin-foundation:ddi-target-members:0:authored:migration-9edc6247ce0c74fd-0 --></ins>

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

**Parameters**

*hCompilerDDI*

The handle to the plugin compiler DDI object.

*pTarget*

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:getcaps-behavior:5 -->Contains the adapter family and ABI version.  See [D3D12DDI_COMPILER_TARGET](#descriptions).<!-- d3d12-review-inline:end:compiler-plugin-foundation:getcaps-behavior:5 --></ins>

*pApplicationDesc*

Describes the target application and version.  Not typically used, see Remarks.  See <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:getcaps-behavior:7:preserved-repair:source-ac4102b8144a191a-0-0 -->[D3D12DDI_APPLICATION_DESC](#descriptions)<!-- d3d12-review-inline:end:compiler-plugin-foundation:getcaps-behavior:7:preserved-repair:source-ac4102b8144a191a-0-0 --></ins>.

*pCaps*

Cap type, inputs and outputs.  See [D3D12DDICAPS_TYPE](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/d3d12umddi/ne-d3d12umddi-d3d12ddicaps_type)

**Remarks**

This is expected to match UMD implementation for adapter drivers in the same adapter family.

The following caps may be queried:

- <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:getcaps-behavior:13 -->`D3D12DDICAPS_TYPE_SHADER`<!-- d3d12-review-inline:end:compiler-plugin-foundation:getcaps-behavior:13 --></ins>
- <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:getcaps-behavior:13 -->`D3D12DDICAPS_TYPE_D3D12_OPTIONS`<!-- d3d12-review-inline:end:compiler-plugin-foundation:getcaps-behavior:13 --></ins>
- <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:getcaps-behavior:13 -->`D3D12DDICAPS_TYPE_OPTIONS_*`<!-- d3d12-review-inline:end:compiler-plugin-foundation:getcaps-behavior:13 --></ins>
- <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:getcaps-behavior:13 -->`D3D12DDICAPS_TYPE_SHADER_MODEL_6_8_OPTIONS_0110`<!-- d3d12-review-inline:end:compiler-plugin-foundation:getcaps-behavior:13 --></ins>
- <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:getcaps-behavior:13 -->`D3D12DDICAPS_TYPE_0011_SHADER_MODELS`<!-- d3d12-review-inline:end:compiler-plugin-foundation:getcaps-behavior:13 --></ins>
- <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:getcaps-behavior:13 -->`D3D12DDICAPS_TYPE_0081_3DPIPELINESUPPORT1`<!-- d3d12-review-inline:end:compiler-plugin-foundation:getcaps-behavior:13 --></ins>

The Application Desc parameter pApplicationDesc should not typically <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:getcaps-behavior:14:authored:source-86f1feb98080b4fd-0-0 -->be <!-- d3d12-review-inline:end:compiler-plugin-foundation:getcaps-behavior:14:authored:source-86f1feb98080b4fd-0-0 --></ins>used.  On occasion, drivers have changed capability reporting for a specific application with known issues to work around those problems.

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:caps-storage:0:authored:migration-2376b70268f9071a-0 -->`pCaps` supplies `D3D12DDIARG_GETCAPS`. The selected usermode DDI version determines the capability payload layout.<!-- d3d12-review-inline:end:compiler-plugin-foundation:caps-storage:0:authored:migration-2376b70268f9071a-0 --></ins>

<a id="family-enumeration"></a>

### Adapter family enumeration

Retrieve a list of all adapter families supported by the plugin.

**Parameters**

*hCompilerDDI*

The handle to the plugin compiler DDI object.

*AdapterFamilyIndex*

The index of the adapter family to enumerate.

*pAdapterFamily*

Describes the adapter family for the given AdapterFamilyIndex.  See <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:family-ddi-contract:7:preserved-repair:source-47a1a5a419a011d4-0-0 -->[D3D12DDI_COMPILER_ADAPTER_FAMILY](#descriptions)<!-- d3d12-review-inline:end:compiler-plugin-foundation:family-ddi-contract:7:preserved-repair:source-47a1a5a419a011d4-0-0 --></ins>.

**Remarks**

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

**Parameters**

*hCompilerDDI*

The handle to the plugin compiler DDI object.

*AdapterFamilyIndex*

The index of the target adapter family.  See <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:abi-ddi-contract:5 -->[D3D12DDI_COMPILER_ADAPTER_FAMILY](#descriptions)<!-- d3d12-review-inline:end:compiler-plugin-foundation:abi-ddi-contract:5 --></ins> and <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:abi-ddi-contract:5:modified:migration-2ec355bc888b4598-1 -->[PFND3D12DDI_COMPILER_ENUMERATE_ADAPTER_FAMILIES](#family-enumeration)<!-- d3d12-review-inline:end:compiler-plugin-foundation:abi-ddi-contract:5:modified:migration-2ec355bc888b4598-1 --></ins>.

*pNumABIVersions*

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:abi-ddi-contract:7 -->On input, describes the capacity of pABIVersions in UINT64 elements.  `*pNumABIVersions` is zero when pABIVersions is nullptr.  This may be used to retrieve a partial list, see remarks.  On output, returns the number of ABI Versions for the adapter family.<!-- d3d12-review-inline:end:compiler-plugin-foundation:abi-ddi-contract:7 --></ins>

*pABIVersions*

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:abi-ddi-contract:9:modified:source-a0da1480336a72b6-0-0 -->Receives<!-- d3d12-review-inline:end:compiler-plugin-foundation:abi-ddi-contract:9:modified:source-a0da1480336a72b6-0-0 --></ins> the list of ABI Versions for <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:abi-ddi-contract:9:modified:source-a0da1480336a72b6-0-1 -->the adapter family<!-- d3d12-review-inline:end:compiler-plugin-foundation:abi-ddi-contract:9:modified:source-a0da1480336a72b6-0-1 --></ins>.  May be nullptr when performing a size check.

**Remarks**

Returns the <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:abi-ddi-contract:11:modified:source-37d13a88208f5788-0-0 -->compiler ABI version supported by the compiled binaries produced by this compiler.  This is compared with the supported ABI range of a driver to understand if precompiled binaries are supported.  See the [driver ABI compatibility payload](devices-and-capabilities.md#d3d12_feature_data_shadercache_abi_support)<!-- d3d12-review-inline:end:compiler-plugin-foundation:abi-ddi-contract:11:modified:source-37d13a88208f5788-0-0 --></ins> capability check. A range of ABI versions is supported for an adapter family to allow targeting adapters that may not be receiving driver updates.

Compiled objects produced by this compiler may not be used with drivers that do not report this ABI version in their supported ABI version range.

ABI version is used to check for precompiled cache updates and understand cache compatibility with drivers on the client, see <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:abi-ddi-contract:13:modified:source-7552bc485e2029ef-0-0 -->[version domains](offline-compilation.md#version-domains)<!-- d3d12-review-inline:end:compiler-plugin-foundation:abi-ddi-contract:13:modified:source-7552bc485e2029ef-0-0 --></ins>.

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:abi-ddi-contract:14:modified:migration-42bf0d4602484e16-0 -->If the adapter family is not one of the families returned by [PFND3D12DDI_COMPILER_ENUMERATE_ADAPTER_FAMILIES](#family-enumeration) and pNumABIVersions is valid, the plugin must set `*pNumABIVersions` to zero and return `DXGI_ERROR_NOT_FOUND`.<!-- d3d12-review-inline:end:compiler-plugin-foundation:abi-ddi-contract:14:modified:migration-42bf0d4602484e16-0 --></ins>

If pNumABIVersions is nullptr, return E_INVALIDARG.

If the adapter family is valid and pNumABIVersions is non-nullptr, always set \*<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:abi-ddi-contract:16:modified:source-e307c34f96af8961-0-0 -->pNumABIVersions<!-- d3d12-review-inline:end:compiler-plugin-foundation:abi-ddi-contract:16:modified:source-e307c34f96af8961-0-0 --></ins> to the correct number of ABI versions for the family on return, regardless of other success/failure. Otherwise, set it to zero.

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:abi-ddi-contract:17:modified:source-58596d42c122fb81-0-0 -->pABIVersions<!-- d3d12-review-inline:end:compiler-plugin-foundation:abi-ddi-contract:17:modified:source-58596d42c122fb81-0-0 --></ins> may be nullptr when performing a size check.  In that case, set \*pNumABIVersions to the number of ABI versions for the adapter family and return S_OK.

ABIVersion 0x0 and UINT64_MAX(0xffffffffffffffffui64) are reserved and must not be returned.  Compilers report version 1 for the initial version of an adapter <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:abi-ddi-contract:18:modified:source-c673d854f19252b9-0-0 -->family's<!-- d3d12-review-inline:end:compiler-plugin-foundation:abi-ddi-contract:18:modified:source-c673d854f19252b9-0-0 --></ins> ABI, and then <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:abi-ddi-contract:18:modified:source-c673d854f19252b9-0-1 -->increment<!-- d3d12-review-inline:end:compiler-plugin-foundation:abi-ddi-contract:18:modified:source-c673d854f19252b9-0-1 --></ins> this counter every time the ABI version changes.

ABI Versions must be reported in <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:abi-ddi-contract:19:modified:source-ca555f3569b4cc63-0-0 -->descending<!-- d3d12-review-inline:end:compiler-plugin-foundation:abi-ddi-contract:19:modified:source-ca555f3569b4cc63-0-0 --></ins> order, so the latest ABI version appears at `pABIVersions[0]` and the oldest ABI version is at the highest index.  If the buffer size is insufficient, driver must fill out as many ABI versions as there is room for and report DXGI_ERROR_MORE_DATA.  For example, this may be used to only retrieve the latest ABI version supported.

If \*pNumABIVersions is equal to the number of ABI version or larger, copy the complete list and set \*pNumABIVersions to the correct number of entries.  Return S_OK.

<a id="versions-and-profiles"></a>

### Compiler version and profile version

<a id="ddi-compiler-version"></a>

#### PFND3D12DDI_COMPILER_ENUMERATE_ADAPTER_FAMILY_COMPILER_VERSION

Describes the version of a compiler for an adapter family.

**Parameters**

*hCompilerDDI*

The handle to the plugin compiler DDI object.

*AdapterFamilyIndex*

The index specifies adapter family.  See <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:compiler-ddi-contract:5 -->[D3D12DDI_COMPILER_ADAPTER_FAMILY](#descriptions)<!-- d3d12-review-inline:end:compiler-plugin-foundation:compiler-ddi-contract:5 --></ins> and <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:compiler-ddi-contract:5 -->[PFND3D12DDI_COMPILER_ENUMERATE_ADAPTER_FAMILIES](#family-enumeration)<!-- d3d12-review-inline:end:compiler-plugin-foundation:compiler-ddi-contract:5 --></ins>.

*pCompilerVersion*

Compiler version changes signify changes in code generation that potentially impact all applications for an adapter family.  See <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:compiler-ddi-contract:7 -->[D3D12DDI_VERSION_NUMBER](state-object-databases-and-identity.md#d3d12_version_number)<!-- d3d12-review-inline:end:compiler-plugin-foundation:compiler-ddi-contract:7 --></ins>.

**Remarks**

Major/Minor version change for "must" recompile such as security or major fixes.  Build for "should" recompile such as performance.  Revision for less consequential changes that shouldn't invalidate caches.

<a id="ddi-profile-version"></a>

#### PFND3D12DDI_COMPILER_GET_APPLICATION_PROFILE_VERSION

Return the application profile version number.  An application profile is any application dependent profile or settings that do not impact compilation for other applications.  Any time those settings change for a given application, update the version number.

**Parameters**

*hCompilerDDI*

The handle to the plugin compiler DDI object.

*pTarget*

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:profile-ddi-contract:5 -->Contains the adapter family and ABI version.  See [D3D12DDI_COMPILER_TARGET](#descriptions).<!-- d3d12-review-inline:end:compiler-plugin-foundation:profile-ddi-contract:5 --></ins>

*pApplicationDesc*

Describes the target application and version.  See <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:profile-ddi-contract:7:preserved-repair:source-442ca694f6548bb7-0-0 -->[D3D12DDI_APPLICATION_DESC](#descriptions)<!-- d3d12-review-inline:end:compiler-plugin-foundation:profile-ddi-contract:7:preserved-repair:source-442ca694f6548bb7-0-0 --></ins>.

*pApplicationProfileVersion*

Describes the version of the compiler profile that targets a specific application.  Applications are specified by application identifier and application version.  Compilers may revise this number to indicate application specific changes to compiler output.  See <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:profile-ddi-contract:9 -->[D3D12DDI_VERSION_NUMBER](state-object-databases-and-identity.md#d3d12_version_number)<!-- d3d12-review-inline:end:compiler-plugin-foundation:profile-ddi-contract:9 --></ins>.

**Remarks**

The compiler profile can be versioned when there <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:profile-ddi-contract:11:authored:source-8900ceb37ac6d557-0-0 -->are <!-- d3d12-review-inline:end:compiler-plugin-foundation:profile-ddi-contract:11:authored:source-8900ceb37ac6d557-0-0 --></ins>application specific changes to these profiles that do not impact other applications.  This prevents invalidating caches for all applications when a change is application specific.

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:ddi-version-results:1:authored:migration-bf1e5887087a9d4f-0 -->All capabilities calls take the live `hCompilerDDI`. Version and profile
results use caller-provided output structures. Family-version absence returns
`DXGI_ERROR_NOT_FOUND`. A profile query with no applicable application or engine
profile succeeds with version zero. The profile query's API level target
validation is specified [with the API](offline-compilation.md#id3d12compilerfactory-getapplicationprofileversion),
not delegated to an implicit physical adapter lookup. Failed compiler version
output must not be consumed as a result. Failure does not guarantee a zero
version.<!-- d3d12-review-inline:end:compiler-plugin-foundation:ddi-version-results:1:authored:migration-bf1e5887087a9d4f-0 --></ins>

<a id="formats"></a>

### Format and multisample queries

<a id="ddi-format-support"></a>

#### PFND3D12DDI_COMPILER_CHECK_FORMAT_SUPPORT

Check support for features that are optional on some formats.

**Parameters**

*hCompilerDDI*

The handle to the plugin compiler DDI object.

*pTarget*

Contains the adapter family and ABI version.  See <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:format-ddi-contract:5 -->[D3D12DDI_COMPILER_TARGET](#descriptions)<!-- d3d12-review-inline:end:compiler-plugin-foundation:format-ddi-contract:5 --></ins>.

*Format*

A [DXGI_FORMAT](formats.md#dxgi-format) value for the format to return info about.

*pFormatSupport*

A D3D12DDI_FORMAT_SUPPORT bitfield for features that are optional on some formats.

**Remarks**

This is expected to match UMD implementation for adapter drivers in the same adapter family.

<a id="ddi-multisample"></a>

#### PFND3D12DDI_COMPILER_CHECK_MULTISAMPLE_QUALITY_LEVELS

Queries if the image quality level is supported for a given format and sample count.

**Parameters**

*hCompilerDDI*

The handle to the plugin compiler DDI object.

*pTarget*

Contains the adapter family and ABI version.  See <ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:msaa-ddi-contract:5 -->[D3D12DDI_COMPILER_TARGET](#descriptions)<!-- d3d12-review-inline:end:compiler-plugin-foundation:msaa-ddi-contract:5 --></ins>.

*Format*

A [DXGI_FORMAT](formats.md#dxgi-format) value for the format to check.

*SampleCount*

The number of multi-samples per pixel to check.

*QualityLevel*

The quality level to check.

**Remarks**

Returns TRUE if supported, FALSE otherwise.  This is expected to be consistent with the UMD implementation for adapter drivers in the same adapter family.

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:format-results:0:authored:migration-667765c9d1371ce9-0 -->The multisample query checks a particular quality level rather than enumerating
a quality level count. These target-specific compiler host checks retain the
corresponding format/multisample meanings in
[format query cases](formats.md#format-query-cases) and
[multisampling](rasterization.md#multisampling).<!-- d3d12-review-inline:end:compiler-plugin-foundation:format-results:0:authored:migration-667765c9d1371ce9-0 --></ins>

<a id="callback-dependencies"></a>

## Callback table ABI dependencies

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:dependency-boundary:0:authored:migration-2cff0a22de79ed81-0 -->The following types support the installed compiler cache callback table.<!-- d3d12-review-inline:end:compiler-plugin-foundation:dependency-boundary:0:authored:migration-2cff0a22de79ed81-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:D131-cache-callback-behavior:0:authored:migration-0faa5ce05325caf8-0 -->The invoked behavior of [value lookup](compiler-invocation-and-cache-output.md#pfnd3d12ddi_compiler_cache_find_value_cb), [value storage](compiler-invocation-and-cache-output.md#pfnd3d12ddi_compiler_cache_store_value_cb) and [object value key registration](compiler-invocation-and-cache-output.md#pfnd3d12ddi_compiler_cache_set_object_value_keys_cb) is defined with compiler invocation. The complete ABI declarations remain here.<!-- d3d12-review-inline:end:compiler-plugin-foundation:D131-cache-callback-behavior:0:authored:migration-0faa5ce05325caf8-0 --></ins>

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

## Compiler table ABI dependencies

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:compiler-dependency-boundary:0:authored:migration-d828e8addb2c2aaa-0 -->The declarations below use compiler DDI build 2. Negotiation selects the actual layout. Shared root signature, state object and pipeline types come from the selected usermode DDI version.<!-- d3d12-review-inline:end:compiler-plugin-foundation:compiler-dependency-boundary:0:authored:migration-d828e8addb2c2aaa-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-plugin-foundation:D131-compile-behavior:0:authored:migration-d590ef211875b1a3-0 -->[Compiler creation](compiler-invocation-and-cache-output.md#pfnd3d12ddi_compiler_create_compiler), [pipeline compilation](compiler-invocation-and-cache-output.md#pfnd3d12ddi_compiler_compile_pipeline_state), [state object compilation](compiler-invocation-and-cache-output.md#pfnd3d12ddi_compiler_compile_create_state_object) and [incremental additions](compiler-invocation-and-cache-output.md#pfnd3d12ddi_compiler_compile_add_to_state_object) define the invoked behavior, output completion and dependency lifetimes for these declarations.<!-- d3d12-review-inline:end:compiler-plugin-foundation:D131-compile-behavior:0:authored:migration-d590ef211875b1a3-0 --></ins>

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
