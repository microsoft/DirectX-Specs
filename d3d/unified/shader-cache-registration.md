<a id="shader-cache-registration"></a>

# Shader cache registration lifecycle and target discovery

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

<ins><!-- d3d12-review-inline:begin:cache-registration:introduction:0 -->The D3D Shader Cache Registration (D3DSCR) API is a nano-COM-based API for managing the registration of and enumeration of State Object Databases (SODBs) and Pre-Compiled Shader Databases (PSDBs) on the end-user system. This API is intended to be used by game installers such as the Xbox Store, Steam etc. during their game installation and update process.<!-- d3d12-review-inline:end:cache-registration:introduction:0 --></ins>

<!-- d3d12-review-alert:begin:cache-registration:registration-type-forward:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [registration ABI](#registration-abi) defines the scope, application description
> and compiler property types used below.

<!-- d3d12-review-alert:end:cache-registration:registration-type-forward:0 -->

<a id="installation-and-updates"></a>

## Installation and updates

<ins><!-- d3d12-review-inline:begin:cache-registration:install-workflow:0 -->![Diagram representing the workflow of how the Shader Cache registration API should be used for the game store Install/Update scenario](../images/AdvancedShaderDelivery/D3DShaderCacheRegistrationAPI_Install.png "Install / Update Scenario")<!-- d3d12-review-inline:end:cache-registration:install-workflow:0 --></ins>

This diagram demonstrates the interactions between the Game Store/Installer and the D3DSCR API during the game install and update process. <ins><!-- d3d12-review-inline:begin:cache-registration:install-workflow:1 -->A typical process is as follows:<!-- d3d12-review-inline:end:cache-registration:install-workflow:1 --></ins>

1. The game's files are installed to the end user's machine, the SODBs are included with that step as they should be considered part of the game's content.
2. <ins><!-- d3d12-review-inline:begin:cache-registration:install-workflow:2 -->The installer will instantiate the D3DSCR API and proceed to register the game that was just installed, providing its executable path on disk and application description to `RegisterApplication`, then registering each SODB and its component with `RegisterComponent`.<!-- d3d12-review-inline:end:cache-registration:install-workflow:2 --></ins>
3. The installer uses D3DSCR to query which graphics adapter families and compiler ABI versions the installed game should target.
4. With the adapter and compiler information in hand the installer will fetch a PSDB which matches the application and compiler combination from a compilation service.
5. <ins><!-- d3d12-review-inline:begin:cache-registration:install-workflow:2 -->The PSDB is installed by the installer to a disk location of its choice.<!-- d3d12-review-inline:end:cache-registration:install-workflow:2 --></ins>
6. <ins><!-- d3d12-review-inline:begin:cache-registration:install-workflow:2 -->The installer will use D3DSCR to register the newly installed PSDB for the game's component with `RegisterComponent`.<!-- d3d12-review-inline:end:cache-registration:install-workflow:2 --></ins>

<!-- d3d12-review-alert:begin:cache-registration:figure-qualification:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The installation figure is schematic: step 2 is application registration followed by component registration, not a single call that accepts SODB paths. PSDB paths are supplied as component properties; application registration alone does not register an SODB or a PSDB.

<!-- d3d12-review-alert:end:cache-registration:figure-qualification:0 -->

<a id="catalog-identity"></a>

## Catalog identity and persistence

<ins><!-- d3d12-review-inline:begin:cache-registration:scope-meaning:0 -->`D3D_SHADER_CACHE_APP_REGISTRATION_SCOPE` defines the user account scope<!-- d3d12-review-inline:end:cache-registration:scope-meaning:0 --></ins> of shader cache application registration. In practice this will determine the root path in the Windows registry where data will be stored. For example, if the installer is run with Windows Administrator privilege level then `D3D_SHADER_CACHE_APP_REGISTRATION_SCOPE_SYSTEM` should be used.

A shader component represents the pairing of one State Object Database (SODB) to <ins><!-- d3d12-review-inline:begin:cache-registration:component-concept:0 -->zero or more Pre-Compiled Shader Databases (PSDB), identified by adapter family mappings.<!-- d3d12-review-inline:end:cache-registration:component-concept:0 --></ins> A shader component has an identifying name as well as a file system path to the installed SODB file and associated PSDB files.

<ins><!-- d3d12-review-inline:begin:cache-registration:application-concept:0 -->`ID3DShaderCacheApplication` represents an application<!-- d3d12-review-inline:end:cache-registration:application-concept:0 --></ins> or game installed on a system. Each application can have <ins><!-- d3d12-review-inline:begin:cache-registration:application-concept:0 -->zero or more Components<!-- d3d12-review-inline:end:cache-registration:application-concept:0 --></ins> which represent cached shader objects.

<!-- d3d12-review-alert:begin:cache-registration:catalog-lifecycle:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Registration state is persistent catalog state, not the lifetime of a returned interface. User registrations are associated with the current user and system registrations are machine-wide. Write access is required for the selected scope. Explorer lookup considers system and current-user state. Scope selection does not grant elevation, and the API does not define a general conflict-precedence policy among scopes or installers.

<!-- d3d12-review-alert:end:cache-registration:catalog-lifecycle:0 -->

<!-- d3d12-review-alert:begin:cache-registration:catalog-lifecycle:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Within an installer and its scope, application name registration is an upsert: reusing a registered application name updates its description and executable path while retaining its components. The full executable path is the explorer lookup key, not proof of a unique catalog entry across names or installers. `pExeFilename` instead supplies the game's stable identifying filename even when the on-disk file is renamed. No path canonicalization, hard-link equivalence, unique-executable ownership or case-distinct-name isolation guarantee is added by this description.

<!-- d3d12-review-alert:end:cache-registration:catalog-lifecycle:1 -->

<!-- d3d12-review-alert:begin:cache-registration:catalog-lifecycle:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Component registration updates the named SODB association and supplied adapter family mappings. Families not supplied by an update are retained; remove the component registration when the entire association must be removed. Registration removal and file deletion are different operations. Registering a path does not validate file contents or transfer file ownership.

<!-- d3d12-review-alert:end:cache-registration:catalog-lifecycle:2 -->

<!-- d3d12-review-alert:begin:cache-registration:catalog-lifecycle:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Application/component objects own the metadata returned by their pointer getters. Updating or removing catalog entries does not define a global coherent snapshot or force all previously acquired objects to refresh simultaneously. The specific object supplied to removal is invalidated; count and enumeration results can also be affected by catalog access failures and changes. Counts are not stable identifiers.

<!-- d3d12-review-alert:end:cache-registration:catalog-lifecycle:3 -->

<!-- d3d12-review-alert:begin:cache-registration:D144-runtime-catalog-consumer:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> [Automatic runtime discovery](runtime-cache-discovery.md#default-discovery) defines the process path lookup, exact `default` component and current-family path used during device initialization. Its [retained-state rules](runtime-cache-discovery.md#failure-and-lifetime) do not turn these catalog objects into live views or make registration updates refresh an existing device automatically.

<!-- d3d12-review-alert:end:cache-registration:D144-runtime-catalog-consumer:0 -->

<!-- d3d12-review-alert:begin:cache-registration:installer-name-identity:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Active installer exclusion uses the installer name and scope. For `D3D_SHADER_CACHE_APP_REGISTRATION_SCOPE_USER`, a name can have only one active installer within a Windows session. This does not exclude another session. For `D3D_SHADER_CACHE_APP_REGISTRATION_SCOPE_SYSTEM`, the exclusion applies across the machine. Active installer names are compared case-sensitively.

<!-- d3d12-review-alert:end:cache-registration:installer-name-identity:0 -->

<!-- d3d12-review-alert:begin:cache-registration:installer-name-identity:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Persistent installer, application, component and adapter family catalog keys are case-insensitive. Case-variant active installer names therefore do not establish independent catalogs or safe identity-isolated writes. The client must return a consistent installer name throughout its installer object's lifetime. Catalog identity and active-instance exclusion are distinct rules.

<!-- d3d12-review-alert:end:cache-registration:installer-name-identity:1 -->

<ins><!-- d3d12-review-inline:begin:cache-registration:explorer-concept:0 -->`ID3DShaderCacheExplorer` creates a read-only view<!-- d3d12-review-inline:end:cache-registration:explorer-concept:0 --></ins> of the current state of the shader cache registration on the system. Any mutable operations on `ID3DShaderCacheApplication` or `ID3DShaderCacheComponent` objects obtained through this interface will fail and no state will be updated.

<a id="target-discovery"></a>

## Target discovery

<ins><!-- d3d12-review-inline:begin:cache-registration:target-purpose:0 -->Installer target discovery<!-- d3d12-review-inline:end:cache-registration:target-purpose:0 --></ins> returns compiler compatibility information for each GPU adapter that supports using Precompiled Shader Databases(PSDB).

CompilerVersion is provided for informational purposes.  It indicates the version of the compiler itself, and may not rev when application profiles do.

<ins><!-- d3d12-review-inline:begin:cache-registration:application-target-filter:0 -->For installer system target discovery, when the D3D_SHADER_CACHE_APPLICATION_DESC is provided, it is used to filter the adapter list to the adapters preferred for use with the application.  The D3D_SHADER_CACHE_APPLICATION_DESC also informs the ApplicationProfileVersion, which is necessary to determine PSDB compatibility for a given application.<!-- d3d12-review-inline:end:cache-registration:application-target-filter:0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-registration:application-target-optional:0 -->For installer target enumeration, D3D_SHADER_CACHE_APPLICATION_DESC is optional.<!-- d3d12-review-inline:end:cache-registration:application-target-optional:0 --></ins>  If not supplied, the ApplicationProfileVersion is not determined and is set to zero on output.  It may be useful to initially obtain version information that is not dependent on application identity when negotiating with services, but ApplicationProfileVersion should still be checked for compatibility before downloading PSDBs.  Additionally, the list of preferred adapters is not filtered when application identity is not known, so a check with application identity is needed to only download psdbs for preferred adapters.

<!-- d3d12-review-alert:begin:cache-registration:application-target-ordering:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> When application metadata is supplied, system target discovery must filter eligible adapter records to the adapters preferred for that application and sort the results by application preference. Installer-derived application targets follow this application-dependent discovery contract. Eligibility and application preference determine the candidate records. They are distinct from compiler family support, ABI intersection and application profile queries. No particular Windows settings algorithm, order among equally preferred adapters, or stability across updates is specified.

<!-- d3d12-review-alert:end:cache-registration:application-target-ordering:0 -->

<!-- d3d12-review-alert:begin:cache-registration:application-target-ordering:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> An explorer's explicit device or adapter context is caller-selected and scopes discovery to that context. A system application preference list must not silently discard that explicitly selected context. A catalog-only explorer has no adapter targets.

<!-- d3d12-review-alert:end:cache-registration:application-target-ordering:1 -->

<!-- d3d12-review-alert:begin:cache-registration:target-context-rules:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The installer captures its adapter records during installer creation. Records without offline cache ABI metadata or without a present adapter at that time do not contribute. `GetMaxPrecompileTargetCount` is the resulting snapshot's upper bound, not a new physical-hardware query. Later driver or compiler changes can affect profile queries and can cause adapter omission or discovery failure without automatically refreshing that bound. An application object retains its discovered target records; callbacks do not automatically refresh those records.

<!-- d3d12-review-alert:end:cache-registration:target-context-rules:0 -->

<!-- d3d12-review-alert:begin:cache-registration:target-context-rules:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The driver-supported interval is inclusive. An adapter family identifier, supported ABI interval, compiler version and application profile are not interchangeable identifiers. See [Version domains](offline-compilation.md#version-domains) and the device's [shader cache ABI support payload](devices-and-capabilities.md#d3d12_feature_data_shadercache_abi_support). Discovery reports driver-side target information. It does not expand the compiler factory's potentially sparse supported ABI set or make every ABI in a driver interval available from every registered compiler.

<!-- d3d12-review-alert:end:cache-registration:target-context-rules:1 -->

<!-- d3d12-review-alert:begin:cache-registration:target-context-rules:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The installer upper bound query, installer in/out-capacity enumeration, application count/fixed-capacity prefix copy, and component exact-size PSDB map copy are four distinct protocols. Returned records need not be unique by adapter family. Application preference sorting does not establish a stable tie order, a cross-call race-free snapshot or automatic callback-driven refresh.

<!-- d3d12-review-alert:end:cache-registration:target-context-rules:2 -->

<!-- d3d12-review-alert:begin:cache-registration:D144-compatibility-selection:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> [PSDB recognition and compatibility](runtime-cache-discovery.md#compatibility) define runtime eligibility independently of these target array protocols. [Compatible-output preference and driver reporting](runtime-cache-discovery.md#preference-and-reporting) distinguish installer/service recommendations from the runtime's one-path default lookup and from application-preferred adapter filtering.

<!-- d3d12-review-alert:end:cache-registration:D144-compatibility-selection:0 -->

<!-- d3d12-review-alert:begin:cache-registration:registration-profile-query:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> For an application-dependent profile query, registration resolves the adapter's family in its registered compiler, enumerates that compiler's [supported family ABI set](offline-compilation.md#id3d12compilerfactory-enumerateadapterfamilyabiversions), and chooses the greatest member within the driver's inclusive minimum/maximum ABI interval. It queries the [application profile](offline-compilation.md#id3d12compilerfactory-getapplicationprofileversion) for that compiler target and the supplied application metadata.

<!-- d3d12-review-alert:end:cache-registration:registration-profile-query:0 -->

<!-- d3d12-review-alert:begin:cache-registration:registration-profile-query:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> An incompatible compiler family or an empty intersection with the driver's interval fails discovery with `DXGI_ERROR_DRIVER_INTERNAL_ERROR`. A missing registered compiler path can omit the adapter. Other compiler/adapter query failures can fail discovery. The returned record still reports the driver's ABI interval and compiler version, not a contiguous expansion of the compiler's supported ABI set and not necessarily the ABI chosen to query the profile. Without application metadata no application profile is queried and `ApplicationProfileVersion` is zero.

<!-- d3d12-review-alert:end:cache-registration:registration-profile-query:1 -->

<a id="registration-abi"></a>

## Public registration ABI

<!-- d3d12-review-alert:begin:cache-registration:abi-context:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The declarations below are the registration ABI, not aliases of similarly named compiler or D3D12 structures. `ID3DShaderCacheInstallerFactory`, `ID3DShaderCacheInstaller`, `ID3DShaderCacheApplication`, `ID3DShaderCacheComponent` and `ID3DShaderCacheExplorer` derive from `IUnknown`. The caller-implemented `ID3DShaderCacheInstallerClient` has exactly the three methods shown below and does not derive from `IUnknown`.

<!-- d3d12-review-alert:end:cache-registration:abi-context:0 -->

```cpp
typedef enum D3D_SHADER_CACHE_APP_REGISTRATION_SCOPE
{
    D3D_SHADER_CACHE_APP_REGISTRATION_SCOPE_USER,
    D3D_SHADER_CACHE_APP_REGISTRATION_SCOPE_SYSTEM
} D3D_SHADER_CACHE_APP_REGISTRATION_SCOPE;

typedef struct D3D_SHADER_CACHE_PSDB_PROPERTIES
{
    const wchar_t* pAdapterFamily;
    const wchar_t* pPsdbPath;
} D3D_SHADER_CACHE_PSDB_PROPERTIES;

typedef enum D3D_SHADER_CACHE_TARGET_FLAGS
{
    D3D_SHADER_CACHE_TARGET_FLAG_NONE = 0,
}D3D_SHADER_CACHE_TARGET_FLAGS;

typedef union D3D_VERSION_NUMBER
{
    UINT64 Version;
    UINT16 VersionParts[4];
} D3D_VERSION_NUMBER;

typedef struct D3D_SHADER_CACHE_COMPILER_PROPERTIES
{
    wchar_t szAdapterFamily[128];
    UINT64 MinimumABISupportVersion;
    UINT64 MaximumABISupportVersion;
    D3D_VERSION_NUMBER CompilerVersion;
    D3D_VERSION_NUMBER ApplicationProfileVersion;
} D3D_SHADER_CACHE_COMPILER_PROPERTIES;

typedef struct D3D_SHADER_CACHE_APPLICATION_DESC
{
    const wchar_t* pExeFilename;
    const wchar_t* pName;
    D3D_VERSION_NUMBER Version;
    const wchar_t* pEngineName;
    D3D_VERSION_NUMBER EngineVersion;
} D3D_SHADER_CACHE_APPLICATION_DESC;

DEFINE_ENUM_FLAG_OPERATORS(D3D_SHADER_CACHE_TARGET_FLAGS)

typedef struct SC_HANDLE__ *SC_HANDLE;
```

<!-- d3d12-review-alert:begin:cache-registration:abi-guids:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Public identifier | GUID |
> |---|---|
> | `CLSID_D3DShaderCacheInstallerFactory` | `16195a0b-607c-41f1-bf03-c7694d60a8d4` |
> | `IID_ID3DShaderCacheInstallerClient` | `a16ee930-d9f6-4222-a514-244473e5d266` |
> | `IID_ID3DShaderCacheComponent` | `eed1bf00-f5c7-4cf7-885c-d0f9c0cb4828` |
> | `IID_ID3DShaderCacheApplication` | `fc688ee2-1b35-4913-93be-1ca3fa7df39e` |
> | `IID_ID3DShaderCacheInstaller` | `bbe30de1-6318-4526-ae17-776693191bb4` |
> | `IID_ID3DShaderCacheExplorer` | `90432322-32f5-487f-9264-e9390fa58b2a` |
> | `IID_ID3DShaderCacheInstallerFactory` | `09b2dfe4-840f-401a-804c-0dd8aadc9e9f` |

<!-- d3d12-review-alert:end:cache-registration:abi-guids:0 -->

<!-- d3d12-review-alert:begin:cache-registration:field-semantics:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D_SHADER_CACHE_APP_REGISTRATION_SCOPE_USER` is 0. `D3D_SHADER_CACHE_APP_REGISTRATION_SCOPE_SYSTEM` is 1. `D3D_SHADER_CACHE_TARGET_FLAG_NONE` is 0 and all other target flags are reserved. `D3D_VERSION_NUMBER` overlays `UINT64 Version` and four 16-bit parts. Its shared version meaning is defined in [Version numbers](state-object-databases-and-identity.md#d3d12_version_number). The application description field order is `pExeFilename`, `pName`, `Version`, `pEngineName`, `EngineVersion`.

<!-- d3d12-review-alert:end:cache-registration:field-semantics:0 -->

<ins><!-- d3d12-review-inline:begin:cache-registration:target-flags-meaning:0 -->`D3D_SHADER_CACHE_TARGET_FLAGS` contains flags to modify target lookup behavior. The flags are currently reserved.<!-- d3d12-review-inline:end:cache-registration:target-flags-meaning:0 --></ins>

<a id="d3d_shader_cache_psdb_properties"></a>

### D3D_SHADER_CACHE_PSDB_PROPERTIES

<ins><!-- d3d12-review-inline:begin:cache-registration:psdb-fields:0 -->`D3D_SHADER_CACHE_PSDB_PROPERTIES` defines <!-- d3d12-review-inline:end:cache-registration:psdb-fields:0 --></ins>properties <ins><!-- d3d12-review-inline:begin:cache-registration:psdb-fields:0 -->for a precompiled shader database<!-- d3d12-review-inline:end:cache-registration:psdb-fields:0 --></ins>.

#### Fields

- `const wchar_t* pAdapterFamily`: Pointer to adapter family name.
- `const wchar_t* pPsdbPath`: Pointer to PSDB path.

<a id="d3d_version_number"></a>

### D3D_VERSION_NUMBER

<ins><!-- d3d12-review-inline:begin:cache-registration:version-fields:0 -->`D3D_VERSION_NUMBER` defines <!-- d3d12-review-inline:end:cache-registration:version-fields:0 --></ins>a version number as either a 64-bit integer or an array of 4 16-bit parts.

#### Fields

- `UINT64 Version`: Version as a 64-bit integer.
- `UINT16 VersionParts[4]`: Version as an array of 4 16-bit parts.

<a id="d3d_shader_cache_compiler_properties"></a>

### D3D_SHADER_CACHE_COMPILER_PROPERTIES

<ins><!-- d3d12-review-inline:begin:cache-registration:compiler-fields:0 -->`D3D_SHADER_CACHE_COMPILER_PROPERTIES` defines <!-- d3d12-review-inline:end:cache-registration:compiler-fields:0 --></ins>properties <ins><!-- d3d12-review-inline:begin:cache-registration:compiler-fields:0 -->for a shader cache compiler<!-- d3d12-review-inline:end:cache-registration:compiler-fields:0 --></ins>.

#### Fields

- `wchar_t szAdapterFamily[128]`: Adapter family name.
- `UINT64 MinimumABISupportVersion`: Minimum ABI support version.
- `UINT64 MaximumABISupportVersion`: Maximum ABI support version.
- `D3D_VERSION_NUMBER CompilerVersion`: Compiler version.
- `D3D_VERSION_NUMBER ApplicationProfileVersion`: Application profile version.

<a id="d3d_shader_cache_application_desc"></a>

### D3D_SHADER_CACHE_APPLICATION_DESC

The application desc is metadata used for drivers, compilers, and the D3D runtime to uniquely identify an application.

#### Fields

- `const wchar_t* pExeFilename`: Pointer to the exe filename.
- <ins><!-- d3d12-review-inline:begin:cache-registration:application-fields:2 -->`const wchar_t* pName`: Pointer to application name.<!-- d3d12-review-inline:end:cache-registration:application-fields:2 --></ins>
- <ins><!-- d3d12-review-inline:begin:cache-registration:application-fields:2 -->`D3D_VERSION_NUMBER Version`: Application version.<!-- d3d12-review-inline:end:cache-registration:application-fields:2 --></ins>
- `const wchar_t* pEngineName`: Pointer to engine name.
- <ins><!-- d3d12-review-inline:begin:cache-registration:application-fields:2 -->`D3D_VERSION_NUMBER EngineVersion`: Engine version.<!-- d3d12-review-inline:end:cache-registration:application-fields:2 --></ins>

Notes:

- <ins><!-- d3d12-review-inline:begin:cache-registration:application-fields:4 -->The pExeFilename should be the filename for the main game exe, not any storefront or other game launchers.  The filename should be the game's typical filename, and does not have to match the exe filename on disk.  For example, if the game exe were simply renamed, the pExeFilename passed to this API does not change.<!-- d3d12-review-inline:end:cache-registration:application-fields:4 --></ins>

<!-- d3d12-review-alert:begin:cache-registration:target-field-details:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D_SHADER_CACHE_PSDB_PROPERTIES` pairs a NUL-terminated adapter family identifier with a NUL-terminated PSDB file path. The compiler properties contain an inline `wchar_t[128]` family string, inclusive minimum/maximum driver-supported ABI values, the compiler version, and an application-dependent profile version. The inline family storage is 128 wide characters including any terminating NUL, not a pointer or a byte length. Compiler versions, ABI versions, application/engine versions and application profile versions are different domains. Target identity and ABI/profile meaning are defined by [Offline compilation](offline-compilation.md#offline-compilation). This registration structure does not change newest-first compiler ABI enumeration or the compiler's zero-as-maximum target convention.

<!-- d3d12-review-alert:end:cache-registration:target-field-details:0 -->

<a id="factory-bootstrap"></a>

## Factory bootstrap and ownership

<!-- d3d12-review-alert:begin:cache-registration:factory-bootstrap:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The factory is retrieved through [D3D12GetInterface](devices-and-capabilities.md#d3d12getinterface), using `CLSID_D3DShaderCacheInstallerFactory` and `IID_ID3DShaderCacheInstallerFactory`. There is no separate registration factory export. The returned runtime interfaces use `IUnknown` reference ownership. The client is caller-owned and must persist for the installer lifetime. Its pointer is retained, not an `IUnknown` reference. Releasing a factory does not release independently held installer/explorer references. Application and component interfaces likewise own their retained metadata; releasing a parent interface is not catalog unregistration or a transfer of ownership of a child's borrowed strings.

<!-- d3d12-review-alert:end:cache-registration:factory-bootstrap:0 -->

<ins><!-- d3d12-review-inline:begin:cache-registration:factory-source:0 -->This is the factory interface for<!-- d3d12-review-inline:end:cache-registration:factory-source:0 --></ins> creating shader cache installers and explorers. <ins><!-- d3d12-review-inline:begin:cache-registration:factory-source:0 -->`ID3DShaderCacheInstallerFactory` objects<!-- d3d12-review-inline:end:cache-registration:factory-source:0 --></ins> are created using the `D3D12GetInterface` function by passing the `CLSID_D3DShaderCacheInstallerFactory` GUID.

<a id="id3dshadercacheinstallerfactory"></a>

## ID3DShaderCacheInstallerFactory

<a id="id3dshadercacheinstallerfactory-createinstaller"></a>

### ID3DShaderCacheInstallerFactory::CreateInstaller

#### Declaration

```cpp
HRESULT CreateInstaller( ID3DShaderCacheInstallerClient* pClient, REFIID riid, void** ppvInstaller);
```

#### Behavior

Creates a shader cache installer.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstallerfactory-createinstaller-source-remarks:0 -->For USER scope, only a single instance of a given installer name may be active within a Windows session. For SYSTEM scope, only a single instance of a given installer name may be active across the machine. Active installer names are compared case-sensitively. Installers are identified by the name returned by the `ID3DShaderCacheInstallerClient` interface at creation time.<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstallerfactory-createinstaller-source-remarks:0 --></ins>

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstallerfactory-createinstaller-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The installer obtains its identity from the client's `GetInstallerName` and its registration scope from `GetInstallerScope` at creation. It retains the client pointer for later notifications. Registration persists independently of the installer object; releasing an installer is not application unregistration. Creation may fail because another instance with that installer identity is active or because the caller cannot access the selected registration scope.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstallerfactory-createinstaller-behavior:0 -->

#### Parameters

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstallerfactory-createinstaller-source-parameters:0 -->`[in] pClient`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstallerfactory-createinstaller-source-parameters:0 --></ins>

A pointer to the client interface.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstallerfactory-createinstaller-source-parameters:2 -->`[in] riid`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstallerfactory-createinstaller-source-parameters:2 --></ins>

The reference ID of the interface to retrieve.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstallerfactory-createinstaller-source-parameters:4 -->`[out] ppvInstaller`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstallerfactory-createinstaller-source-parameters:4 --></ins>

A pointer to receive the installer interface.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstallerfactory-createinstaller-parameter-rules:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pClient` and `ppvInstaller` are required. A null output is not a creation probe. `riid` selects the requested interface, normally `IID_ID3DShaderCacheInstaller`. On success the caller owns the returned interface reference and must release it. The client must remain alive until the installer and any notification teardown have completed. The client has no `AddRef`/`Release` protocol. A caller must not unload a DLL that supplies a still-live client implementation or runtime interface.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstallerfactory-createinstaller-parameter-rules:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstallerfactory-createinstaller-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` on success; `E_INVALIDARG` for a null client or output; `E_NOINTERFACE` for an unsupported requested interface; `E_OUTOFMEMORY` for allocation failure. A duplicate active identity can fail with `HRESULT_FROM_WIN32(ERROR_ALREADY_EXISTS)`. Access and other initialization errors propagate. There is no general promise that an early construction failure clears the caller's output. If interface negotiation is reached and rejects `riid`, the corresponding interface output is set to null. This does not extend to earlier failures.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstallerfactory-createinstaller-returns:0 -->

<a id="id3dshadercacheinstallerfactory-createexplorer"></a>

### ID3DShaderCacheInstallerFactory::CreateExplorer

#### Declaration

```cpp
HRESULT CreateExplorer( IUnknown* pUnknown, REFIID riid, void** ppvExplorer);
```

#### Behavior

Creates a shader cache explorer.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstallerfactory-createexplorer-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The explorer provides catalog lookup without a mutable installer. `pUnknown` can supply an `ID3D12Device`, an `IDXCoreAdapter`, or a DXGI adapter object that exposes `IDXGIAdapter4`. A base `IDXGIAdapter` pointer is acceptable when its underlying object supports querying `IDXGIAdapter4`; no older DXGI fallback is provided. The device and DXCore adapter paths are separate accepted paths. A device or adapter supplies caller-selected context for application target discovery. It does not change the full-executable-path catalog key or make returned objects writable. Application preferences do not discard this explicitly selected context. A null context permits catalog-only exploration, with no adapter targets supplied by that explorer. The returned objects do not depend on the caller retaining the original device/adapter merely to keep copied registration metadata alive.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstallerfactory-createexplorer-behavior:0 -->

#### Parameters

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstallerfactory-createexplorer-source-parameters:0 -->`[in, optional] pUnknown`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstallerfactory-createexplorer-source-parameters:0 --></ins>

A pointer to an unknown interface.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstallerfactory-createexplorer-source-parameters:2 -->`[in] riid`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstallerfactory-createexplorer-source-parameters:2 --></ins>

The reference ID of the interface to retrieve.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstallerfactory-createexplorer-source-parameters:4 -->`[out] ppvExplorer`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstallerfactory-createexplorer-source-parameters:4 --></ins>

A pointer to receive the explorer interface.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstallerfactory-createexplorer-parameter-rules:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pUnknown` is the context object, not the application's executable or a compiler factory. A non-null object must expose one of the supported device/adapter interfaces, including `IDXGIAdapter4` for the DXGI path. `riid` normally requests `IID_ID3DShaderCacheExplorer`. `ppvExplorer` is required and receives a caller-owned reference. Null output is not a probe.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstallerfactory-createexplorer-parameter-rules:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstallerfactory-createexplorer-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` on success; `E_INVALIDARG` for a null output or unsupported non-null context; `E_NOINTERFACE` for an unsupported requested output interface; `E_OUTOFMEMORY` for allocation failure. Device feature query and adapter/context discovery failures propagate. Factory availability does not guarantee usable target metadata, and early failures do not uniformly initialize the output. If interface negotiation is reached and rejects `riid`, the corresponding interface output is set to null. This does not extend to earlier failures.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstallerfactory-createexplorer-returns:0 -->

<a id="id3dshadercacheinstallerclient"></a>

## ID3DShaderCacheInstallerClient

The user should instantiate their own final implementation of this interface <ins><!-- d3d12-review-inline:begin:cache-registration:client-usage:0 -->and pass it<!-- d3d12-review-inline:end:cache-registration:client-usage:0 --></ins> to the D3DSCR API during `ID3DShaderCacheInstaller` creation. This object must persist for the lifetime of the `ID3DShaderCacheInstaller` object it is used with.

<a id="id3dshadercacheinstallerclient-getinstallername"></a>

### ID3DShaderCacheInstallerClient::GetInstallerName

#### Declaration

```cpp
HRESULT GetInstallerName( SIZE_T* pNameLength, wchar_t* pName);
```

#### Behavior

Returns the name of the installer application.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstallerclient-getinstallername-source-remarks:0 -->Used by an instance of `ID3DShaderCacheInstaller` to retrieve the name of store/installer application so that applications registered can be organized internally. This method should be called twice. Once with `pName` equal to `nullptr` in which case the method will return the length in characters (including null-terminator) in the memory pointed to by `pNameLength`. If `pName` is non-null then `pNameLength` must also be non-null and the value pointed to by it must be greater than or equal to the length of the name.<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstallerclient-getinstallername-source-remarks:0 --></ins>

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstallerclient-getinstallername-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method is implemented by the installer, not by the runtime. The runtime uses its result to identify the store/installer and organize that installer's registered applications. Return a consistent name for the installer identity used by one installer object.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstallerclient-getinstallername-behavior:0 -->

#### Parameters

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstallerclient-getinstallername-source-parameters:0 -->`[in,out] pNameLength`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstallerclient-getinstallername-source-parameters:0 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstallerclient-getinstallername-source-parameters:1 -->A pointer to a `SIZE_T` variable<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstallerclient-getinstallername-source-parameters:1 --></ins> to contain the length in characters of the name.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstallerclient-getinstallername-source-parameters:2 -->`[out, optional] pName`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstallerclient-getinstallername-source-parameters:2 --></ins>

A pointer to a wide character buffer to receive the name.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstallerclient-getinstallername-parameter-rules:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pNameLength` is required and is an in/out count of `wchar_t` characters, not bytes. With `pName == nullptr`, return the required character count including the terminating NUL. With a non-null buffer, the input count is its character capacity and must be at least the required count. Write the NUL-terminated name within that capacity. This is the caller buffer protocol. It must not be substituted for the pointer-returning application `GetInstallerName`. The runtime first queries the count, then supplies storage. An implementation must not write beyond an undersized buffer.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstallerclient-getinstallername-parameter-rules:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstallerclient-getinstallername-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The caller implementation returns `S_OK` when it supplies the requested length or name, and a failure `HRESULT` when it cannot do so. The primary example returns `E_INVALIDARG` for null `pNameLength` or insufficient capacity. That example does not establish a unique required short-buffer HRESULT for every client implementation. Creation propagates a failed client result.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstallerclient-getinstallername-returns:0 -->

<a id="id3dshadercacheinstallerclient-getinstallerscope"></a>

### ID3DShaderCacheInstallerClient::GetInstallerScope

#### Declaration

```cpp
D3D_SHADER_CACHE_APP_REGISTRATION_SCOPE GetInstallerScope();
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstallerclient-getinstallerscope-source-behavior:0 -->Returns the scope<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstallerclient-getinstallerscope-source-behavior:0 --></ins> the installer will operate in.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstallerclient-getinstallerscope-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This caller implementation selects the installer registration scope. User scope registers for the current user; system scope registers machine-wide and requires permission to write system registration state. Selecting system scope does not elevate the caller.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstallerclient-getinstallerscope-behavior:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstallerclient-getinstallerscope-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> None.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstallerclient-getinstallerscope-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstallerclient-getinstallerscope-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D_SHADER_CACHE_APP_REGISTRATION_SCOPE_USER` or `D3D_SHADER_CACHE_APP_REGISTRATION_SCOPE_SYSTEM`, not an `HRESULT`.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstallerclient-getinstallerscope-returns:0 -->

<a id="id3dshadercacheinstallerclient-handledriverupdate"></a>

### ID3DShaderCacheInstallerClient::HandleDriverUpdate

#### Declaration

```cpp
HRESULT HandleDriverUpdate( ID3DShaderCacheInstaller* pInstaller);
```

#### Behavior

Callback handler called after a graphics driver update has occurred.

This is a callback function that will be called by the system when a graphics driver update occurs. See
`ID3DShaderCacheInstaller::RegisterDriverUpdateListener` for more information.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstallerclient-handledriverupdate-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The system calls this client method for driver update notification after listener registration. The installer can review the applications it has registered and determine which PSDB registrations need updating. Notification is not an automatic download, recompilation, cache replacement or catalog update. The callback is asynchronous to the installer's ordinary call flow; no compiler-style application-wide thread safety guarantee, ordering guarantee, or generic reentrancy prohibition is specified here.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstallerclient-handledriverupdate-behavior:0 -->

#### Parameters

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstallerclient-handledriverupdate-source-parameters:0 -->`[in] pInstaller`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstallerclient-handledriverupdate-source-parameters:0 --></ins>

A pointer to an `ID3DShaderCacheInstaller` object that was listening for the driver update.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstallerclient-handledriverupdate-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pInstaller` identifies the notifying installer. The callback does not transfer an interface reference to the client. The retained client must remain valid during callbacks and teardown. Listener removal and installer destruction wait for notification completion; self-teardown from a callback is not established as safe by that fact.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstallerclient-handledriverupdate-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstallerclient-handledriverupdate-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The client returns an `HRESULT` describing its handling. Failure does not establish catalog rollback, retry scheduling, callback re-delivery, or unregistration. The example returns `E_NOTIMPL`. It does not register a listener.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstallerclient-handledriverupdate-returns:0 -->

<a id="id3dshadercacheinstaller"></a>

## ID3DShaderCacheInstaller

<ins><!-- d3d12-review-inline:begin:cache-registration:installer-purpose:0 -->`ID3DShaderCacheInstaller` manages<!-- d3d12-review-inline:end:cache-registration:installer-purpose:0 --></ins> the registration of applications and their associated SODBs and PSDBs.

<a id="id3dshadercacheinstaller-registerapplication"></a>

### ID3DShaderCacheInstaller::RegisterApplication

#### Declaration

```cpp
HRESULT RegisterApplication( const wchar_t* pExePath, const D3D_SHADER_CACHE_APPLICATION_DESC* pApplicationDesc, REFIID riid, void** ppvApp);
```

#### Behavior

Registers a shader cache application.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-registerapplication-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Registers or updates application metadata within this installer and scope. The fully qualified executable path is the lookup key exposed to the explorer. `pExeFilename` is stable application-identification metadata, not that path. Registration does not install application files, create SODBs or PSDBs, or register their paths. Components are registered separately. Registration updates do not imply that all previously returned application objects refresh their retained descriptions.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-registerapplication-behavior:0 -->

#### Parameters

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstaller-registerapplication-source-parameters:0 -->`[in] pExePath`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstaller-registerapplication-source-parameters:0 --></ins>

The fully qualified path to the main game executable.  This is used as a key to lookup the application in-process, so consider any hard-links.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstaller-registerapplication-source-parameters:2 -->`[in] pApplicationDesc`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstaller-registerapplication-source-parameters:2 --></ins>

A pointer to a structure containing the application info.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstaller-registerapplication-source-parameters:4 -->`[in] riid`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstaller-registerapplication-source-parameters:4 --></ins>

The reference ID of the interface to retrieve.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstaller-registerapplication-source-parameters:6 -->`[out, optional] ppvApp`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstaller-registerapplication-source-parameters:6 --></ins>

A pointer to receive the application interface.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-registerapplication-parameter-rules:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pExePath`, `pApplicationDesc`, the description's `pName` and `pExeFilename` are required and the strings must be nonempty and NUL-terminated. `pEngineName` may be null and is represented as an empty engine name on readback. Input strings are copied. The caller need not retain them after the call. `riid` selects the returned application interface. A null `ppvApp` requests registration without returning an object. It is not a no-side-effect validation probe. A non-null output receives a caller-owned reference on success. With a null interface output pointer, `riid` is not negotiated.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-registerapplication-parameter-rules:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-registerapplication-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` on success; `E_INVALIDARG` for the described missing/empty required values; `E_NOINTERFACE` for an unsupported requested interface when an object is requested; allocation, permission and persistent-catalog errors can propagate. Persistent registration can complete before output object creation or interface negotiation fails. Failure is not a universal rollback guarantee. Application name upsert and executable path lookup retain the distinct identity rules in [Catalog identity and persistence](#catalog-identity). If interface negotiation is reached and rejects `riid`, the corresponding interface output is set to null. This does not extend to earlier failures.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-registerapplication-returns:0 -->

<a id="id3dshadercacheinstaller-removeapplication"></a>

### ID3DShaderCacheInstaller::RemoveApplication

#### Declaration

```cpp
HRESULT RemoveApplication( ID3DShaderCacheApplication* pApplication);
```

#### Behavior

Removes a shader cache application.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstaller-removeapplication-source-remarks:0 -->After successful removal the `pApplication` will be in an invalid state and should be destroyed by the caller. Further operations on that object will return error results. Additionally any cached indices of `ID3DShaderCacheApplication` objects should be considered invalidated after this operation.<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstaller-removeapplication-source-remarks:0 --></ins>

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-removeapplication-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Removes the application's registration and associated component registrations from this installer's catalog, not the application's files or the SODB/PSDB files named by those registrations. After successful removal the supplied application object must not be used for further application operations. Release its reference. Cached application indices are invalidated. This does not promise that every separately acquired object becomes stale simultaneously.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-removeapplication-behavior:0 -->

#### Parameters

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstaller-removeapplication-source-parameters:0 -->`[in] pApplication`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstaller-removeapplication-source-parameters:0 --></ins>

A pointer to the application to remove.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-removeapplication-parameter-rules:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pApplication` is required and must be a runtime-provided application object identifying a registration belonging to this installer and scope, not a fabricated interface implementation or an unrelated application's object. The call does not consume the caller's COM reference. Holding a read-only application view neither grants nor revokes the authority of a separately held mutable installer. This removal operation remains subject to that installer's ownership and provenance preconditions.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-removeapplication-parameter-rules:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-removeapplication-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` on success; `E_INVALIDARG` for a null object or an object whose installer identity does not match; allocation, permission and catalog failures can propagate. The supplied object can be invalidated before a persistent deletion later fails, so failure does not guarantee its continued usability.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-removeapplication-returns:0 -->

<a id="id3dshadercacheinstaller-getapplicationcount"></a>

### ID3DShaderCacheInstaller::GetApplicationCount

#### Declaration

```cpp
UINT GetApplicationCount();
```

#### Behavior

Retrieves the number of applications.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-getapplicationcount-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Counts this installer's registered applications in its selected scope. It is not a whole-machine count across all installers or users. A count does not lock the catalog or establish a stable enumeration order.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-getapplicationcount-behavior:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-getapplicationcount-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> None.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-getapplicationcount-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-getapplicationcount-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The application count. A catalog read failure can yield zero; zero is not an `HRESULT` and does not distinguish an empty catalog from every read failure.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-getapplicationcount-returns:0 -->

<a id="id3dshadercacheinstaller-getapplication"></a>

### ID3DShaderCacheInstaller::GetApplication

#### Declaration

```cpp
HRESULT GetApplication( UINT index, REFIID riid, void** ppvApp);
```

#### Behavior

Retrieves a specific application by index.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-getapplication-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Retrieves an application from this installer's catalog by zero-based index. Indices are enumeration positions, not persistent identities; removals and other catalog changes can invalidate cached positions.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-getapplication-behavior:0 -->

#### Parameters

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstaller-getapplication-source-parameters:0 -->`[in] index`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstaller-getapplication-source-parameters:0 --></ins>

The index of the application to retrieve.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstaller-getapplication-source-parameters:2 -->`[in] riid`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstaller-getapplication-source-parameters:2 --></ins>

The reference ID of the interface to retrieve.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstaller-getapplication-source-parameters:4 -->`[out] ppvApp`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstaller-getapplication-source-parameters:4 --></ins>

A pointer to receive the application interface.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-getapplication-parameter-rules:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `index` selects an existing entry. `riid` normally requests `IID_ID3DShaderCacheApplication`. The required `ppvApp` receives a caller-owned reference. A null output is not a documented enumeration or validation probe.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-getapplication-parameter-rules:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-getapplication-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` on success. An index at or beyond the currently counted entries returns `E_INVALIDARG`, not an end-of-enumeration `S_FALSE`. Unsupported requested interfaces return `E_NOINTERFACE`; catalog/allocation failures can propagate. No uniform early failure output clearing is promised. If interface negotiation is reached and rejects `riid`, the corresponding interface output is set to null. This does not extend to earlier failures.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-getapplication-returns:0 -->

<a id="id3dshadercacheinstaller-clearallstate"></a>

### ID3DShaderCacheInstaller::ClearAllState

#### Declaration

```cpp
HRESULT ClearAllState();
```

#### Behavior

Clears all registered state.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-clearallstate-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Clears registered application/component state belonging to this installer in its selected scope. It is not a whole-machine purge, does not remove another installer's registrations and does not delete application, SODB or PSDB files. It is not listener unregistration or service-trigger removal. The call does not define an atomic refresh or invalidation protocol for all outstanding application/component objects.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-clearallstate-behavior:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-clearallstate-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> None.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-clearallstate-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-clearallstate-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` on success; permission, catalog and allocation errors can propagate. No general transaction, rollback or all-or-nothing guarantee is established.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-clearallstate-returns:0 -->

<a id="id3dshadercacheinstaller-getmaxprecompiletargetcount"></a>

### ID3DShaderCacheInstaller::GetMaxPrecompileTargetCount

#### Declaration

```cpp
UINT GetMaxPrecompileTargetCount();
```

#### Behavior

Retrieves the maximum number of precompile targets <ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstaller-getmaxprecompiletargetcount-source-behavior:0 -->installed in the system<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstaller-getmaxprecompiletargetcount-source-behavior:0 --></ins>.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-getmaxprecompiletargetcount-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Provides the upper bound from adapter records captured during installer creation for allocating the installer target array. The initial capture excludes records without offline cache ABI metadata or a present adapter at that time. This call is not a fresh physical-hardware query, does not automatically remove an adapter from the captured bound after later removal, and is not a count of installed offline compiler plugins. Multiple physical adapters can contribute the same family, so this count is not a distinct-family count.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-getmaxprecompiletargetcount-behavior:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-getmaxprecompiletargetcount-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> None.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-getmaxprecompiletargetcount-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-getmaxprecompiletargetcount-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A `UINT` target count upper bound from this installer's captured adapter records. Application preference filtering and later profile query omission can produce fewer entries; later query failures can fail discovery. The bound does not promise current hardware state or automatic callback-driven refresh.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-getmaxprecompiletargetcount-returns:0 -->

<a id="id3dshadercacheinstaller-getprecompiletargets"></a>

### ID3DShaderCacheInstaller::GetPrecompileTargets

#### Declaration

```cpp
HRESULT GetPrecompileTargets( const D3D_SHADER_CACHE_APPLICATION_DESC* pApplicationDesc, UINT* pArraySize, D3D_SHADER_CACHE_COMPILER_PROPERTIES* pArray, D3D_SHADER_CACHE_TARGET_FLAGS flags);
```

#### Behavior

Retrieves the precompile targets.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-getprecompiletargets-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns driver/compiler properties from the installer's captured adapter records. With application metadata, discovery must filter eligible adapters by application preference, sort the preferred results, and determine their application profile versions as described in [Target discovery](#target-discovery). A missing registered compiler path can omit an adapter; incompatible compiler family or ABI sets and other query failures can fail discovery. Without an application description there is no application preference filter, and the profile version is zero. This is installed-adapter discovery, not enumeration of every compiler registered with the offline compiler factory. It does not deduplicate identical family records into a promised distinct-family set.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-getprecompiletargets-behavior:0 -->

#### Parameters

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstaller-getprecompiletargets-source-parameters:0 -->`[in, optional] pApplicationDesc`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstaller-getprecompiletargets-source-parameters:0 --></ins>

An optional pointer to a structure containing the application info.  <ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstaller-getprecompiletargets-source-parameters:1 -->See [Target discovery](#target-discovery).<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstaller-getprecompiletargets-source-parameters:1 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstaller-getprecompiletargets-source-parameters:2 -->`[in,out] pArraySize`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstaller-getprecompiletargets-source-parameters:2 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstaller-getprecompiletargets-source-parameters:3 -->The in/out element capacity and available count of the array to receive the targets.<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstaller-getprecompiletargets-source-parameters:3 --></ins>

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstaller-getprecompiletargets-source-parameters:4 -->`[out, optional] pArray`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstaller-getprecompiletargets-source-parameters:4 --></ins>

A pointer to an array to receive the targets.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstaller-getprecompiletargets-source-parameters:6 -->`[in] flags`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstaller-getprecompiletargets-source-parameters:6 --></ins>

Modifiers for target lookup behavior.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-getprecompiletargets-parameter-rules:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pApplicationDesc` is optional. When supplied, it must provide valid readable NUL-terminated `pExeFilename` and application-title `pName` strings. `pEngineName` is optional and must be readable and NUL-terminated when non-null. The description and its input strings must remain valid for the call. The method does not retain caller storage. A null descriptor requests profile-independent discovery, rather than supplying fallback values for missing required members of a non-null descriptor. `pArraySize` is required: on input it is the number of array elements available; on successful discovery it receives the available element count, which can exceed input capacity. `pArray` supplies caller-owned `D3D_SHADER_CACHE_COMPILER_PROPERTIES` storage for the input capacity. Returned family strings are inline in those structures and need no separate allocator or release. A zero-capacity query does not write an element. A null array is usable only with zero capacity, not as a positive-capacity probe. Counts are structures, not bytes. The method writes the prefix that fits and zero-initializes excess capacity beyond available records. Use `D3D_SHADER_CACHE_TARGET_FLAG_NONE`. Other flags are invalid.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-getprecompiletargets-parameter-rules:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-getprecompiletargets-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` when the available count fits the supplied capacity, including an empty result. `DXGI_ERROR_MORE_DATA` when the count exceeds capacity. The updated count describes available entries and a prefix may already have been written. `E_INVALIDARG` for nonzero reserved flags. `DXGI_ERROR_DRIVER_INTERNAL_ERROR` for an incompatible compiler family or no supported compiler ABI in the inclusive driver interval. Allocation and other discovery failures propagate. On such failure there is no general count reset or zeroing guarantee. A count query and a later fill are separate calls, not a transaction.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-getprecompiletargets-returns:0 -->

<a id="id3dshadercacheinstaller-registerdriverupdatelistener"></a>

### ID3DShaderCacheInstaller::RegisterDriverUpdateListener

#### Declaration

```cpp
HRESULT RegisterDriverUpdateListener();
```

#### Behavior

Registers a listener for driver updates.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstaller-registerdriverupdatelistener-source-remarks:0 -->This API is used to indicate that the installer is interested in receiving notifications from the system whenever
a graphics driver is installed or updated. The callback function `HandleDriverUpdate` on the
`ID3DShaderCacheInstallerClient` interface will be called during a driver update.<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstaller-registerdriverupdatelistener-source-remarks:0 --></ins>

When a new driver is available on the system the installer will need to review applications it has registered to determine if the PSDBs associated with the device have been invalidated.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-registerdriverupdatelistener-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Registers this installer for driver update notifications delivered through its retained client's `HandleDriverUpdate`. It does not retain the client through `IUnknown`, nor does it automatically refresh catalog registrations or compiler target objects. There is one active listener subscription per installer object.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-registerdriverupdatelistener-behavior:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-registerdriverupdatelistener-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> None.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-registerdriverupdatelistener-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-registerdriverupdatelistener-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` on successful subscription; `DXGI_ERROR_ALREADY_EXISTS` for a repeated registration on an already subscribed installer; `E_FAIL` when notification query/subscription fails.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-registerdriverupdatelistener-returns:0 -->

<a id="id3dshadercacheinstaller-unregisterdriverupdatelistener"></a>

### ID3DShaderCacheInstaller::UnregisterDriverUpdateListener

#### Declaration

```cpp
HRESULT UnregisterDriverUpdateListener();
```

#### Behavior

Unregisters a listener for driver updates.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-unregisterdriverupdatelistener-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Removes this installer's listener subscription. Successful teardown waits for outstanding notification completion. Installer destruction also tears down its subscription. Neither operation removes a separately configured service trigger. The contract does not establish that invoking teardown from inside the callback is safe.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-unregisterdriverupdatelistener-behavior:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-unregisterdriverupdatelistener-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> None.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-unregisterdriverupdatelistener-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-unregisterdriverupdatelistener-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` on successful removal; `E_INVALIDARG` when there is no registered listener; `E_FAIL` on notification teardown failure. A failed removal must not be treated as proof that callbacks can no longer occur.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-unregisterdriverupdatelistener-returns:0 -->

<a id="id3dshadercacheinstaller-registerservicedriverupdatetrigger"></a>

### ID3DShaderCacheInstaller::RegisterServiceDriverUpdateTrigger

#### Declaration

```cpp
HRESULT RegisterServiceDriverUpdateTrigger(SC_HANDLE hServiceHandle);
```

#### Behavior

Registers a service driver update trigger.

This function registers a Windows service trigger that will automatically start a service when a driver is installed or updated. This service trigger should be used to review registered applications to determine if the PSDBs associated with the device have been invalidated.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstaller-registerservicedriverupdatetrigger-source-remarks:1 -->`ChangeServiceConfig2W` and related Win32 APIs can be used to modify the supplied service's `SERVICE_CONFIG_TRIGGER_INFO` if required.<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstaller-registerservicedriverupdatetrigger-source-remarks:1 --></ins>

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-registerservicedriverupdatetrigger-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Adds the driver update service start trigger to the specified service configuration, preserving unrelated triggers. This persistent service configuration is distinct from an in-process listener subscription and is not owned by the installer object's lifetime. Triggering starts the configured service. It does not itself repair application registrations or fetch PSDBs.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-registerservicedriverupdatetrigger-behavior:0 -->

#### Parameters

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstaller-registerservicedriverupdatetrigger-source-parameters:0 -->`[in] hServiceHandle`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstaller-registerservicedriverupdatetrigger-source-parameters:0 --></ins>

The service handle.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-registerservicedriverupdatetrigger-parameter-rules:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `hServiceHandle` is a caller-owned, borrowed Windows service handle, not an output handle. It must permit querying and changing service configuration (`SERVICE_QUERY_CONFIG` and `SERVICE_CHANGE_CONFIG`). The caller keeps it valid for this call and closes its own handle using the service API. This method does not transfer ownership or require retaining the handle for the trigger's persistence. Windows service configuration and service startup remain external Win32 contracts.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-registerservicedriverupdatetrigger-parameter-rules:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-registerservicedriverupdatetrigger-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` on success; `DXGI_ERROR_ALREADY_EXISTS` if the matching trigger already exists; `E_ACCESSDENIED` for denied service configuration access; `E_INVALIDARG` for an invalid service handle detected during query; `E_FAIL` for other query/change failures. A failed call is not evidence that a service started or that a trigger was installed.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-registerservicedriverupdatetrigger-returns:0 -->

<a id="id3dshadercacheinstaller-unregisterservicedriverupdatetrigger"></a>

### ID3DShaderCacheInstaller::UnregisterServiceDriverUpdateTrigger

#### Declaration

```cpp
HRESULT UnregisterServiceDriverUpdateTrigger(SC_HANDLE hServiceHandle);
```

#### Behavior

Unregisters a service driver update trigger.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-unregisterservicedriverupdatetrigger-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Removes matching driver update trigger data from the specified service, retaining unrelated trigger data and triggers. It is not a blanket removal of all service triggers, does not stop the service and does not remove a live installer listener. Releasing the installer is not a substitute for this operation.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-unregisterservicedriverupdatetrigger-behavior:0 -->

#### Parameters

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheinstaller-unregisterservicedriverupdatetrigger-source-parameters:0 -->`[in] hServiceHandle`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheinstaller-unregisterservicedriverupdatetrigger-source-parameters:0 --></ins>

The service handle.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-unregisterservicedriverupdatetrigger-parameter-rules:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `hServiceHandle` is borrowed and requires `SERVICE_QUERY_CONFIG` and `SERVICE_CHANGE_CONFIG`. The caller owns and closes it. No output or service handle ownership transfer occurs.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-unregisterservicedriverupdatetrigger-parameter-rules:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheinstaller-unregisterservicedriverupdatetrigger-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` on success; `DXGI_ERROR_NOT_FOUND` if no matching trigger is present; `E_ACCESSDENIED` for denied access; `E_INVALIDARG` for an invalid service handle detected during query; `E_FAIL` for other query/change failures. There is no generic catalog rollback or service state guarantee.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheinstaller-unregisterservicedriverupdatetrigger-returns:0 -->

<a id="id3dshadercacheapplication"></a>

## ID3DShaderCacheApplication

<a id="id3dshadercacheapplication-getexepath"></a>

### ID3DShaderCacheApplication::GetExePath

#### Declaration

```cpp
HRESULT GetExePath( const wchar_t** pExePath);
```

#### Behavior

Retrieves the full path to the exe.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-getexepath-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns the object's stored full executable path. This is the registration lookup path, not the canonical application `pExeFilename` metadata.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-getexepath-behavior:0 -->

#### Parameters

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheapplication-getexepath-source-parameters:0 -->`[out] pExePath`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheapplication-getexepath-source-parameters:0 --></ins>

An out parameter that receives a pointer to the exe path.  The string's lifetime is controlled by the ID3DShaderCacheApplication and must not be used if the application is released.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-getexepath-parameter-rules:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pExePath` is required. On success it receives a borrowed NUL-terminated wide string pointer owned by the application object. It is not a caller buffer, has no character capacity input and requires no caller allocator or free operation. Keep the application alive while using the string.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-getexepath-parameter-rules:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-getexepath-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` on success; `E_INVALIDARG` for a null output; `DXGI_ERROR_NOT_CURRENT` for an explicitly invalidated application. Failure does not clear an otherwise valid output variable.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-getexepath-returns:0 -->

<a id="id3dshadercacheapplication-getdesc"></a>

### ID3DShaderCacheApplication::GetDesc

#### Declaration

```cpp
HRESULT GetDesc( D3D_SHADER_CACHE_APPLICATION_DESC* pApplicationDesc);
```

#### Behavior

Retrieves the application description.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-getdesc-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns the object's retained application description, with registration's exact `D3D_SHADER_CACHE_APPLICATION_DESC` layout. Previously acquired descriptions are not a promised live view of later registrations.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-getdesc-behavior:0 -->

#### Parameters

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheapplication-getdesc-source-parameters:0 -->`[out] pApplicationDesc`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheapplication-getdesc-source-parameters:0 --></ins>

A pointer to a structure to receive the application desc.  The desc contains strings whose lifetime is controlled by the ID3DShaderCacheApplication and must not be used if the application is released.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-getdesc-parameter-rules:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pApplicationDesc` is required and points to caller-owned structure storage. The returned string pointers are borrowed from the application object and must not be freed or used after it is released. The version values are copied. This method is not a two-call size query and does not allocate a caller-owned description/string block.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-getdesc-parameter-rules:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-getdesc-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` on success; `E_INVALIDARG` for null output; `DXGI_ERROR_NOT_CURRENT` for an explicitly invalidated application. Failure does not promise to zero the structure or initialize its pointers.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-getdesc-returns:0 -->

<a id="id3dshadercacheapplication-getinstallername"></a>

### ID3DShaderCacheApplication::GetInstallerName

#### Declaration

```cpp
HRESULT GetInstallerName( const wchar_t** pInstallerName);
```

#### Behavior

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-getinstallername-source-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Retrieves the installer's name.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-getinstallername-source-behavior:0 -->

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-getinstallername-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns the name of the installer owning this application registration.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-getinstallername-behavior:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-getinstallername-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `[out] pInstallerName`

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-getinstallername-parameters:0 -->

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-getinstallername-parameters:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pInstallerName` is required. It receives a borrowed NUL-terminated wide string pointer with application object lifetime. There is no `SIZE_T` count, caller-provided character buffer, allocation or caller free operation. This is distinct from the caller-implemented client's `GetInstallerName`.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-getinstallername-parameters:1 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-getinstallername-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` on success; `E_INVALIDARG` for a null output; `DXGI_ERROR_NOT_CURRENT` for an explicitly invalidated application. Failure does not promise output clearing.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-getinstallername-returns:0 -->

<a id="id3dshadercacheapplication-registercomponent"></a>

### ID3DShaderCacheApplication::RegisterComponent

#### Declaration

```cpp
HRESULT RegisterComponent( const wchar_t* pName, const wchar_t* pStateObjectDBPath, UINT NumPSDB, const D3D_SHADER_CACHE_PSDB_PROPERTIES* pPSDBs, REFIID riid, void** ppvComponent);
```

#### Behavior

Registers a component with the application.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheapplication-registercomponent-source-remarks:0 -->**Component naming:** There is a special component name, "default" (case-sensitive) that should be used when the application is not explicitly expecting to find a component by a different name.<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheapplication-registercomponent-source-remarks:0 --></ins>

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-registercomponent-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Registers or updates a named component's SODB path and the supplied family-to-PSDB path mappings. Updating a family replaces that family's path; omitting a previously registered family is not a request to remove that mapping. Persistent family keys are case-insensitive, so case variants do not provide independent PSDB slots. The operation records paths, not PSDB compatibility proof or cache contents. Component registration is separate from file installation. On an explorer-derived read-only application this mutable operation must fail without updating persistent catalog state.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-registercomponent-behavior:0 -->

#### Parameters

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheapplication-registercomponent-source-parameters:0 -->`[in] pName`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheapplication-registercomponent-source-parameters:0 --></ins>

A pointer to a wide character string containing the name of the component.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheapplication-registercomponent-source-parameters:2 -->`[in] pStateObjectDBPath`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheapplication-registercomponent-source-parameters:2 --></ins>

A pointer to a wide character string containing the path to the state object database.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheapplication-registercomponent-source-parameters:4 -->`[in] NumPSDB`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheapplication-registercomponent-source-parameters:4 --></ins>

The number of precompiled shader databases.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheapplication-registercomponent-source-parameters:6 -->`[in, optional] pPSDBs`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheapplication-registercomponent-source-parameters:6 --></ins>

A pointer to an array of PSDB properties.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheapplication-registercomponent-source-parameters:8 -->`[in] riid`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheapplication-registercomponent-source-parameters:8 --></ins>

The reference ID of the interface to retrieve.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheapplication-registercomponent-source-parameters:10 -->`[out, optional] ppvComponent`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheapplication-registercomponent-source-parameters:10 --></ins>

A pointer to receive the component interface.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-registercomponent-parameter-rules:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pName` is a required nonempty NUL-terminated component name. `pStateObjectDBPath` is a required NUL-terminated SODB path. `NumPSDB` is an element count and `pPSDBs` supplies that many structures with required NUL-terminated family/path strings; zero entries do not dereference the array. Input strings are copied. `riid` normally requests `IID_ID3DShaderCacheComponent`. A null `ppvComponent` requests catalog mutation without returning an object. It is not a no-side-effect probe. A returned interface is caller-owned. Explorer-derived objects are subject to the read-only requirement. With a null interface output pointer, `riid` is not negotiated.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-registercomponent-parameter-rules:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-registercomponent-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` on success; `E_INVALIDARG` for a missing/empty name; `DXGI_ERROR_NOT_CURRENT` for an explicitly invalidated application; `E_NOINTERFACE` for an unsupported requested output interface; permission, allocation and catalog failures can propagate. Registration may precede output object/interface failure, so failure does not establish rollback. Null malformed path/array inputs are not defined legal probes. If interface negotiation is reached and rejects `riid`, the corresponding interface output is set to null. This does not extend to earlier failures.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-registercomponent-returns:0 -->

<a id="id3dshadercacheapplication-removecomponent"></a>

### ID3DShaderCacheApplication::RemoveComponent

#### Declaration

```cpp
HRESULT RemoveComponent( ID3DShaderCacheComponent* pComponent);
```

#### Behavior

Removes a component from the application.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheapplication-removecomponent-source-remarks:0 -->After successful removal the `pComponent` will be in an invalid state and should be destroyed by the caller. Further operations on that object will return error results. Additionally any cached indices of `ID3DShaderCacheComponent` objects should be considered invalidated after this operation.<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheapplication-removecomponent-source-remarks:0 --></ins>

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-removecomponent-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Removes a component registration and its family-to-PSDB mappings, not the SODB or PSDB files. After successful removal release the supplied object and discard cached component indices. Do not infer simultaneous invalidation of every independently acquired view. On an explorer-derived read-only application this mutable operation must fail without updating persistent catalog state.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-removecomponent-behavior:0 -->

#### Parameters

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheapplication-removecomponent-source-parameters:0 -->`[in] pComponent`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheapplication-removecomponent-source-parameters:0 --></ins>

A pointer to the component to remove.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-removecomponent-parameter-rules:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pComponent` is required and must identify a component of this application. The call does not consume its COM reference. Read-only explorer-derived objects do not authorize mutation.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-removecomponent-parameter-rules:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-removecomponent-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` on success; `E_INVALIDARG` for a null component; permission, allocation and catalog errors can propagate. The supplied object can be invalidated before later deletion failure. The post-removal invalid-object rule does not imply that all methods have identical failure outputs.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-removecomponent-returns:0 -->

<a id="id3dshadercacheapplication-getcomponentcount"></a>

### ID3DShaderCacheApplication::GetComponentCount

#### Declaration

```cpp
UINT GetComponentCount();
```

#### Behavior

Retrieves the number of components.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-getcomponentcount-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Counts registered components of this application, not PSDBs or target adapters. It does not define a stable index ordering or a catalog lock.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-getcomponentcount-behavior:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-getcomponentcount-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> None.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-getcomponentcount-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-getcomponentcount-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The component count. Missing component state or a catalog read failure can produce zero; zero is not an `HRESULT` distinguishing all failure cases.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-getcomponentcount-returns:0 -->

<a id="id3dshadercacheapplication-getcomponent"></a>

### ID3DShaderCacheApplication::GetComponent

#### Declaration

```cpp
HRESULT GetComponent( UINT index, REFIID riid, void** ppvComponent);
```

#### Behavior

Retrieves a specific component by index.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-getcomponent-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Retrieves a component by its current zero-based enumeration position. Returned component metadata has the component object's lifetime rather than the caller's input array lifetime. Explorer-derived components remain read-only.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-getcomponent-behavior:0 -->

#### Parameters

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheapplication-getcomponent-source-parameters:0 -->`[in] index`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheapplication-getcomponent-source-parameters:0 --></ins>

The index of the component to retrieve.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheapplication-getcomponent-source-parameters:2 -->`[in] riid`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheapplication-getcomponent-source-parameters:2 --></ins>

The reference ID of the interface to retrieve.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheapplication-getcomponent-source-parameters:4 -->`[out] ppvComponent`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheapplication-getcomponent-source-parameters:4 --></ins>

A pointer to receive the component interface.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-getcomponent-parameter-rules:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `index` identifies an existing component. `riid` normally requests `IID_ID3DShaderCacheComponent`. `ppvComponent` is required and receives a caller-owned interface reference; null output is not a documented probe.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-getcomponent-parameter-rules:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-getcomponent-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` only when acquisition succeeds and returns the requested component interface; `E_INVALIDARG` for an index outside the currently enumerated components; `E_NOINTERFACE` for an unsupported requested interface. Enumeration, read and open failures, including a change between enumeration and opening, must be propagated as a failure `HRESULT`. No single error code is required for every catalog change race, and no `S_FALSE` end marker, stable snapshot or universal early output clearing is specified. If interface negotiation is reached and rejects `riid`, the corresponding interface output is set to null. This does not extend to earlier failures.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-getcomponent-returns:0 -->

<a id="id3dshadercacheapplication-getprecompiletargetcount"></a>

### ID3DShaderCacheApplication::GetPrecompileTargetCount

#### Declaration

```cpp
UINT GetPrecompileTargetCount(D3D_SHADER_CACHE_TARGET_FLAGS flags);
```

#### Behavior

Retrieves the number of precompile targets.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-getprecompiletargetcount-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns the number of application-dependent target records retained by this application object. Installer-derived applications use the installer's captured adapter context and the application preference filtering/sorting and profile query contract in [Target discovery](#target-discovery). Explorer-derived applications use the caller-selected device/adapter context without discarding it based on a system preference list, or no targets for catalog-only exploration. It is not a count of registered components, PSDBs, compiler plugins or unique adapter families. The retained results are not automatically refreshed by driver update callbacks.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-getprecompiletargetcount-behavior:0 -->

#### Parameters

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheapplication-getprecompiletargetcount-source-parameters:0 -->`[in] flags`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheapplication-getprecompiletargetcount-source-parameters:0 --></ins>

Modifiers for target lookup behavior.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-getprecompiletargetcount-parameter-rules:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `flags` must be `D3D_SHADER_CACHE_TARGET_FLAG_NONE`; no other flag value is defined.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-getprecompiletargetcount-parameter-rules:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-getprecompiletargetcount-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The target count, or zero for nonzero reserved flags or an explicitly invalidated application. This value cannot communicate an `HRESULT`. A count on an object is not a guarantee that current drivers or a later independently acquired object have unchanged targets.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-getprecompiletargetcount-returns:0 -->

<a id="id3dshadercacheapplication-getprecompiletargets"></a>

### ID3DShaderCacheApplication::GetPrecompileTargets

#### Declaration

```cpp
HRESULT GetPrecompileTargets( UINT ArraySize, D3D_SHADER_CACHE_COMPILER_PROPERTIES* pArray, D3D_SHADER_CACHE_TARGET_FLAGS flags);
```

#### Behavior

Retrieves the precompile targets.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-getprecompiletargets-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Copies the prefix of this application's retained target records that fits `ArraySize`. A short array is not an installer-style count query and does not report the number omitted. Capacity larger than the count does not define values for the unused tail.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-getprecompiletargets-behavior:0 -->

#### Parameters

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheapplication-getprecompiletargets-source-parameters:0 -->`[in] ArraySize`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheapplication-getprecompiletargets-source-parameters:0 --></ins>

The size of the array to receive the targets.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheapplication-getprecompiletargets-source-parameters:2 -->`[out, optional] pArray`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheapplication-getprecompiletargets-source-parameters:2 --></ins>

A pointer to an array to receive the targets.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheapplication-getprecompiletargets-source-parameters:4 -->`[in] flags`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheapplication-getprecompiletargets-source-parameters:4 --></ins>

Modifiers for target lookup behavior.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-getprecompiletargets-parameter-rules:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `ArraySize` is the caller array capacity in structures. `pArray` supplies caller-owned writable storage for the copied elements; family strings are inline arrays, not separately allocated borrowed pointers. Zero capacity copies none. Use the application's `GetPrecompileTargetCount` to allocate its complete array. There is no in/out size pointer. `flags` must be `D3D_SHADER_CACHE_TARGET_FLAG_NONE`. A null positive-capacity array is not a legal output probe.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-getprecompiletargets-parameter-rules:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheapplication-getprecompiletargets-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` for a valid prefix copy, including zero capacity. It does not mean the supplied capacity held every target. `E_INVALIDARG` for nonzero reserved flags; `DXGI_ERROR_NOT_CURRENT` for an explicitly invalidated application. It does not use the installer's `DXGI_ERROR_MORE_DATA` sizing protocol or promise failure initialization.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheapplication-getprecompiletargets-returns:0 -->

<a id="id3dshadercachecomponent"></a>

## ID3DShaderCacheComponent

<a id="id3dshadercachecomponent-getcomponentname"></a>

### ID3DShaderCacheComponent::GetComponentName

#### Declaration

```cpp
HRESULT GetComponentName( const wchar_t** pName);
```

#### Behavior

Retrieves the name of the component.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercachecomponent-getcomponentname-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns the component object's retained identifying name.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercachecomponent-getcomponentname-behavior:0 -->

#### Parameters

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercachecomponent-getcomponentname-source-parameters:0 -->`[out] pName`<!-- d3d12-review-inline:end:cache-registration:id3dshadercachecomponent-getcomponentname-source-parameters:0 --></ins>

A pointer to receive the component name.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercachecomponent-getcomponentname-parameter-rules:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pName` is required. On success it receives a borrowed NUL-terminated wide string owned by the component. Keep the component alive. Do not modify or free the string. There is no caller character buffer or size query.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercachecomponent-getcomponentname-parameter-rules:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercachecomponent-getcomponentname-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` on success; `E_INVALIDARG` for a null output; `DXGI_ERROR_NOT_CURRENT` after explicit invalidation. On that invalidated-object path this getter sets a valid `*pName` to null. This output rule must not be generalized to the other pointer getters.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercachecomponent-getcomponentname-returns:0 -->

<a id="id3dshadercachecomponent-getstateobjectdatabasepath"></a>

### ID3DShaderCacheComponent::GetStateObjectDatabasePath

#### Declaration

```cpp
HRESULT GetStateObjectDatabasePath( const wchar_t** pPath);
```

#### Behavior

Retrieves the path to the state object database.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercachecomponent-getstateobjectdatabasepath-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns the component object's retained SODB path. It does not open or validate the SODB.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercachecomponent-getstateobjectdatabasepath-behavior:0 -->

#### Parameters

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercachecomponent-getstateobjectdatabasepath-source-parameters:0 -->`[out] pPath`<!-- d3d12-review-inline:end:cache-registration:id3dshadercachecomponent-getstateobjectdatabasepath-source-parameters:0 --></ins>

A pointer to receive the path.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercachecomponent-getstateobjectdatabasepath-parameter-rules:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pPath` is required and receives a borrowed NUL-terminated wide string owned by the component. There is no caller buffer, length parameter or caller free operation. Keep the component alive.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercachecomponent-getstateobjectdatabasepath-parameter-rules:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercachecomponent-getstateobjectdatabasepath-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` on success; `E_INVALIDARG` for a null output; `DXGI_ERROR_NOT_CURRENT` after explicit invalidation. Unlike `GetComponentName`, this getter does not promise to null the output on invalidation.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercachecomponent-getstateobjectdatabasepath-returns:0 -->

<a id="id3dshadercachecomponent-getprecompiledcachepath"></a>

### ID3DShaderCacheComponent::GetPrecompiledCachePath

#### Declaration

```cpp
HRESULT GetPrecompiledCachePath( const wchar_t* pAdapterFamily, const wchar_t** pPath);
```

#### Behavior

Retrieves the path to the precompiled cache.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercachecomponent-getprecompiledcachepath-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Looks up the component object's retained PSDB path by exact, case-sensitive adapter family name comparison. This retained-map lookup does not establish independent persistent catalog slots for case variants; persistent family keys are case-insensitive. It is a registration mapping lookup, not a cache opening, compatibility test or runtime selection operation.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercachecomponent-getprecompiledcachepath-behavior:0 -->

#### Parameters

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercachecomponent-getprecompiledcachepath-source-parameters:0 -->`[in] pAdapterFamily`<!-- d3d12-review-inline:end:cache-registration:id3dshadercachecomponent-getprecompiledcachepath-source-parameters:0 --></ins>

A pointer to a wide character string containing the adapter family name.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercachecomponent-getprecompiledcachepath-source-parameters:2 -->`[out] pPath`<!-- d3d12-review-inline:end:cache-registration:id3dshadercachecomponent-getprecompiledcachepath-source-parameters:2 --></ins>

A pointer to receive the path.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercachecomponent-getprecompiledcachepath-parameter-rules:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pAdapterFamily` is a required NUL-terminated family identifier. `pPath` is a required pointer output location, not a character buffer. On success it receives a borrowed NUL-terminated string owned by the component. The IDL's in/out pointer annotation does not establish a buffer capacity protocol or transfer allocator ownership.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercachecomponent-getprecompiledcachepath-parameter-rules:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercachecomponent-getprecompiledcachepath-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` on a matching family; `DXGI_ERROR_NOT_FOUND` if the retained mapping has no such family; `E_INVALIDARG` for null family/output pointers; `DXGI_ERROR_NOT_CURRENT` for an explicitly invalidated component. No output reset is guaranteed on failure.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercachecomponent-getprecompiledcachepath-returns:0 -->

<a id="id3dshadercachecomponent-getprecompiledshaderdatabasecount"></a>

### ID3DShaderCacheComponent::GetPrecompiledShaderDatabaseCount

#### Declaration

```cpp
UINT GetPrecompiledShaderDatabaseCount();
```

#### Behavior

Retrieves the number of precompiled shader databases.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercachecomponent-getprecompiledshaderdatabasecount-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Counts retained nonempty PSDB path mappings by family in this component object. It is not the adapter target count or a count of records in a PSDB. An update does not promise to refresh every previously acquired component object.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercachecomponent-getprecompiledshaderdatabasecount-behavior:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercachecomponent-getprecompiledshaderdatabasecount-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> None.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercachecomponent-getprecompiledshaderdatabasecount-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercachecomponent-getprecompiledshaderdatabasecount-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The number of retained family mappings, or zero for an explicitly invalidated component.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercachecomponent-getprecompiledshaderdatabasecount-returns:0 -->

<a id="id3dshadercachecomponent-getprecompiledshaderdatabases"></a>

### ID3DShaderCacheComponent::GetPrecompiledShaderDatabases

#### Declaration

```cpp
HRESULT GetPrecompiledShaderDatabases( UINT ArraySize, D3D_SHADER_CACHE_PSDB_PROPERTIES * pPSDBs);
```

#### Behavior

Retrieves the precompiled shader databases.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercachecomponent-getprecompiledshaderdatabases-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns the component object's retained family/path mappings. This exact-size protocol differs from both target enumeration protocols.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercachecomponent-getprecompiledshaderdatabases-behavior:0 -->

#### Parameters

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercachecomponent-getprecompiledshaderdatabases-source-parameters:0 -->`[in] ArraySize`<!-- d3d12-review-inline:end:cache-registration:id3dshadercachecomponent-getprecompiledshaderdatabases-source-parameters:0 --></ins>

The size of the array to receive the databases.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercachecomponent-getprecompiledshaderdatabases-source-parameters:2 -->`[out] pPSDBs`<!-- d3d12-review-inline:end:cache-registration:id3dshadercachecomponent-getprecompiledshaderdatabases-source-parameters:2 --></ins>

A pointer to an array to receive the database properties.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercachecomponent-getprecompiledshaderdatabases-parameter-rules:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `ArraySize` must equal `GetPrecompiledShaderDatabaseCount()` for this component object. `pPSDBs` is required even when that count is zero. It points to caller-owned structure storage. Each returned family/path pointer is borrowed from the component and must not be modified, freed or used after its lifetime. Counts are elements, not bytes. No caller-allocated strings or two-call null output probe is defined.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercachecomponent-getprecompiledshaderdatabases-parameter-rules:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercachecomponent-getprecompiledshaderdatabases-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` when the array size exactly matches and the output is non-null; `E_INVALIDARG` for mismatched size or null array, including a null array with zero size; `DXGI_ERROR_NOT_CURRENT` after explicit invalidation. Failure does not promise to initialize the array.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercachecomponent-getprecompiledshaderdatabases-returns:0 -->

<a id="id3dshadercacheexplorer"></a>

## ID3DShaderCacheExplorer

<a id="id3dshadercacheexplorer-getapplicationfromexepath"></a>

### ID3DShaderCacheExplorer::GetApplicationFromExePath

#### Declaration

```cpp
HRESULT GetApplicationFromExePath( const wchar_t* pFullExePath, REFIID riid, void** ppvApp);
```

#### Behavior

Retrieves an application based on its executable path.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheexplorer-getapplicationfromexepath-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Looks up a catalog registration by full executable path and returns a read-only application object. It searches system and current-user registration visibility. It is not limited to the applications of a mutable installer created by this caller. The lookup itself belongs to the catalog contract and does not select, open or consume a PSDB. Returned application and component mutation operations are subject to the read-only requirement.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheexplorer-getapplicationfromexepath-behavior:0 -->

#### Parameters

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheexplorer-getapplicationfromexepath-source-parameters:0 -->`[in] pFullExePath`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheexplorer-getapplicationfromexepath-source-parameters:0 --></ins>

A pointer to a wide character string containing the full executable path.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheexplorer-getapplicationfromexepath-source-parameters:2 -->`[in] riid`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheexplorer-getapplicationfromexepath-source-parameters:2 --></ins>

The reference ID of the interface to retrieve.

<ins><!-- d3d12-review-inline:begin:cache-registration:id3dshadercacheexplorer-getapplicationfromexepath-source-parameters:4 -->`[out] ppvApp`<!-- d3d12-review-inline:end:cache-registration:id3dshadercacheexplorer-getapplicationfromexepath-source-parameters:4 --></ins>

A pointer to receive the application interface.

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheexplorer-getapplicationfromexepath-parameter-rules:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pFullExePath` is a required NUL-terminated full executable path, not the application's `pExeFilename` metadata. `riid` normally requests `IID_ID3DShaderCacheApplication`. `ppvApp` is required and receives a caller-owned reference. A null output is not a lookup probe. No generic user/system or installer precedence policy follows from the lookup description.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheexplorer-getapplicationfromexepath-parameter-rules:0 -->

#### Return values

<!-- d3d12-review-alert:begin:cache-registration:id3dshadercacheexplorer-getapplicationfromexepath-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` on success; `E_INVALIDARG` for a null path or output; `E_NOINTERFACE` for an unsupported requested interface. A catalog search that completes without a matching application returns `E_FAIL`, not an `S_FALSE` enumeration marker. Catalog/allocation/context-dependent discovery errors can propagate. Early failure does not guarantee null output. If interface negotiation is reached and rejects `riid`, the corresponding interface output is set to null. This does not extend to earlier failures.

<!-- d3d12-review-alert:end:cache-registration:id3dshadercacheexplorer-getapplicationfromexepath-returns:0 -->

<a id="registration-example"></a>

## Example

<!-- d3d12-review-alert:begin:cache-registration:example-context:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This illustrative registration example uses store-owned paths and a placeholder PSDB download. A real installation supplies the PSDB selected for each target. The example does not verify PSDB contents or require every system to expose a precompile target. `VERIFY_SUCCEEDED`, the COM smart pointer and standard C++ library types are assumed by the example. It is not an instruction to perform a registration as part of reading this specification.

<!-- d3d12-review-alert:end:cache-registration:example-context:0 -->

```cpp
    struct BasicClient : public ID3DShaderCacheInstallerClient
    {
        BasicClient(const wchar_t* pName) : m_name(pName) {}

        HRESULT __stdcall GetInstallerName(SIZE_T* pNameLength,wchar_t* pName) override
        {
            if (pNameLength == nullptr)
            {
                return E_INVALIDARG;
            }

            if (pName == nullptr)
            {
                *pNameLength = m_name.length() + 1;
                return S_OK;
            }

            if (*pNameLength < m_name.length() + 1)
            {
                return E_INVALIDARG;
            }

            wcscpy_s(pName, *pNameLength, m_name.c_str());

            return S_OK;
        }

        D3D_SHADER_CACHE_APP_REGISTRATION_SCOPE __stdcall GetInstallerScope(void) override
        {
            return D3D_SHADER_CACHE_APP_REGISTRATION_SCOPE_USER;
        }
        HRESULT __stdcall HandleDriverUpdate(ID3DShaderCacheInstaller* pInstaller) override
        {
            UNREFERENCED_PARAMETER(pInstaller);
            return E_NOTIMPL;
        }

        const std::wstring m_name;
    };

    void RegisterApplications()
    {
        BasicClient Client(L"AGameStore");

        CComPtr<ID3DShaderCacheInstallerFactory> pInstallerFactory;

        VERIFY_SUCCEEDED(D3D12GetInterface(CLSID_D3DShaderCacheInstallerFactory, IID_PPV_ARGS(&pInstallerFactory)));

        CComPtr<ID3DShaderCacheInstaller> pInstaller;
        VERIFY_SUCCEEDED(pInstallerFactory->CreateInstaller(&Client, IID_PPV_ARGS(&pInstaller)));

        VERIFY_SUCCEEDED(pInstaller->ClearAllState());

        const std::wstring appIntsallPath = LR"(C:\Program Files\AGame\)";
        const std::wstring appName = L"AGame";
        const std::wstring appExe = L"AGame.exe";
        const std::wstring engineName = L"TaefEngine";
        const std::wstring fullExePath = appIntsallPath + appExe;
        const std::wstring sodbName = L"AGame.sodb";
        const std::wstring sodbPath = appIntsallPath + sodbName;
        const std::wstring psdbName = L"AGame_target.psdb";
        const std::wstring psdPath = appIntsallPath + psdbName;
        const std::wstring componentName = L"PsoLib";

        const UINT64 appVersion = 101101;
        const UINT64 engineVersion = 122122;

        // 'Install' an application
        {
            D3D_SHADER_CACHE_APPLICATION_DESC appDesc = {};
            appDesc.pName = appName.c_str();
            appDesc.pExeFilename = appExe.c_str();
            appDesc.pEngineName = engineName.c_str();
            appDesc.Version.Version = appVersion;
            appDesc.EngineVersion.Version = engineVersion;

            CComPtr<ID3DShaderCacheApplication> pApp;
            VERIFY_SUCCEEDED(pInstaller->RegisterApplication(fullExePath.c_str(), &appDesc, IID_PPV_ARGS(&pApp)));

            UINT numPrecompileTargets = pApp->GetPrecompileTargetCount(D3D_SHADER_CACHE_TARGET_FLAG_NONE);

            std::vector<D3D_SHADER_CACHE_COMPILER_PROPERTIES> compileParams(numPrecompileTargets);
            VERIFY_SUCCEEDED(pApp->GetPrecompileTargets(numPrecompileTargets, compileParams.data(), D3D_SHADER_CACHE_TARGET_FLAG_NONE));

            std::vector<D3D_SHADER_CACHE_PSDB_PROPERTIES> psdbParams;
            for (auto& target : compileParams)
            {
                // < select the appropriate PSDB for this application and reported target >
                // < fetch the psdb for this app and device combo from the interwebs>

                psdbParams.push_back({ target.szAdapterFamily, psdPath.c_str() });
            }

            CComPtr<ID3DShaderCacheComponent> component;
            VERIFY_SUCCEEDED(pApp->RegisterComponent(componentName.c_str(),
                sodbPath.c_str(),
                UINT(psdbParams.size()),
                psdbParams.data(),
                IID_PPV_ARGS(&component)));
        }

        // Read back info about the app
        {
            UINT numApps = pInstaller->GetApplicationCount();

            CComPtr<ID3DShaderCacheApplication> pApp;
            VERIFY_SUCCEEDED(pInstaller->GetApplication(0, IID_PPV_ARGS(&pApp)));

            // Verify
            {
                D3D_SHADER_CACHE_APPLICATION_DESC info = {};

                VERIFY_SUCCEEDED(pApp->GetDesc(&info));

                UINT numComponents = pApp->GetComponentCount();
                for (UINT i = 0; i < numComponents; i++)
                {
                    CComPtr<ID3DShaderCacheComponent> component;
                    VERIFY_SUCCEEDED(pApp->GetComponent(i, IID_PPV_ARGS(&component)));

                    // Component name
                    const wchar_t* componentNameReadback = nullptr;
                    VERIFY_SUCCEEDED(component->GetComponentName(&componentNameReadback));

                    // SODB path
                    const wchar_t* sodbPathReadback = nullptr;
                    VERIFY_SUCCEEDED(component->GetStateObjectDatabasePath(&sodbPathReadback));

                    UINT numPrecompileTargets = pApp->GetPrecompileTargetCount(D3D_SHADER_CACHE_TARGET_FLAG_NONE);
                    if (numPrecompileTargets == 0) { continue; }

                    D3D_SHADER_CACHE_COMPILER_PROPERTIES compileParams;

                    VERIFY_SUCCEEDED(pApp->GetPrecompileTargets(1, &compileParams, D3D_SHADER_CACHE_TARGET_FLAG_NONE));

                    const wchar_t* psdPathReadback = nullptr;
                    VERIFY_SUCCEEDED(component->GetPrecompiledCachePath(compileParams.szAdapterFamily, &psdPathReadback));

                    UINT numPSDBs = component->GetPrecompiledShaderDatabaseCount();
                    std::vector<D3D_SHADER_CACHE_PSDB_PROPERTIES> psdbs(numPSDBs ? numPSDBs : 1u);
                    VERIFY_SUCCEEDED(component->GetPrecompiledShaderDatabases(numPSDBs, psdbs.data()));
                }
            }
        }
    }

```

<a id="availability"></a>

## Availability

<!-- d3d12-review-alert:begin:cache-registration:availability:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The registration surface is part of the released D3D12 Agility SDK 1.619.5 package and its non-prerelease DirectX-Headers release. Runtime deployment and global interface retrieval are defined in [Devices and capabilities](devices-and-capabilities.md#d3d12getinterface). The catalog, listener and service-trigger operations also depend on the corresponding Windows facilities and caller permissions; API publication does not establish universal OS deployment or usable hardware/cache contents.

<!-- d3d12-review-alert:end:cache-registration:availability:0 -->
