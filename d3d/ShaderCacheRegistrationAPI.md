# Advanced Shader Delivery: D3D Shader Cache Registration (D3DSCR) API 

D3DSCR API is a new nano-com based API for managing the registration of and enumeration of Shader Object Databases (SODBs) and Pre-Compiled Shader Databases (PSDBs) on the end-user system. This API is intended to be used by game installers such as the Xbox Store, Steam etc. during their game installation and update process. Additionally, this API will also be used by the D3D12 Runtime in the game process to locate and create state objects using PSDBs and SODBs.

This API will be distributed with the D3D12 Agility SDK; however, a compatible D3D12 runtime will be made available in-box for Windows 11 machines.

## Install/Update Workflow:

![Diagram representing the workflow of how the Shader Cache registration API should be used for the game store Install/Update scenario](.\Images\AdvancedShaderDelivery\D3DShaderCacheRegistrationAPI_Install.png "Install / Update Scenario")

This diagram demonstrates the interactions between the Game Store/Installer and the D3DSCR API during the game install and update process. A typical process is as follow:

1. The game's files are installed to the end user's machine, the SODBs are included with that step as they should be considered part of the game's content.
2. The installer will instantiate the D3DSCR API and proceed to register the game that was just installed, providing it's executable path on disk along with the paths of it's SODBs.
3. The installer uses D3DSCR to query which graphics adapter families and compiler ABI versions the installed game should target.
4. With the adapter and compiler information in hand the installer will fetch a PSDB which matches the application and compiler combination from a compilation service.
5. The PSDB is installed by the installer to a disk location of it's choice.
6. The installer will use D3DSCR to register the newly installed PSDB for the game.

## Runtime Workflow (Non-Title Cooperative):
![Diagram representing the workflow of how the Shader Cache registration API should be used during runtime](.\Images\ClientShaderCacheAPI\D3DShaderCacheRegistrationAPI_Runtime.png "Runtime Scenario")

This diagram demonstrates the interaction between the D3D12 runtime and D3DSCR API during game execution time for the 'Non-Title Cooperative' case. In this case the title was either shipped before Advanced Shader Delivery (ASD) was released or was shipped after and chose not to use the new ASD APIs. The game can still benefit from pre-compiled shaders if an SODB can be collected via playthrough. A typical process in this scenario is as follows:

1. The game installer launches the game (after first running through the install/update workflow if applicable).
2. The game runs, loads the D3D12 runtime and proceeds to create Pipeline State Objects (PSOs) or State Objects (SOs).
3. The D3D12 runtime will interact with the D3DSCR API to enumerated installed SODBs and PSDBs for the current process. The process executable path will be used as a key for D3DSCR.
4. The D3D12 runtime will check for a matching pre-compiled shader in the PSDB to avoid runtime compilation.

## Public API

### GUID Definitions:
- **CLSID_D3DShaderCacheInstallerFactory**: 

    GUID used to bootstrap and initialize an instance of the D3DSCR API. This is expected to be passed to the `D3D12GetInterface` in order to instantiate an instance of `ID3DShaderCacheInstallerFactory`.

### Enumerations:
- **D3D_SHADER_CACHE_APP_REGISTRATION_SCOPE**: 
``` C++
typedef enum D3D_SHADER_CACHE_APP_REGISTRATION_SCOPE
{ 
    D3D_SHADER_CACHE_APP_REGISTRATION_SCOPE_USER, 
    D3D_SHADER_CACHE_APP_REGISTRATION_SCOPE_SYSTEM
} D3D_SHADER_CACHE_APP_REGISTRATION_SCOPE;

```

Defines the user account scope of shader cache application registration. In practice this will determine the root path in the Windows registry where data will be stored. For example, if the installer is run with Windows Administrator privilege level then `D3D_SHADER_CACHE_APP_REGISTRATION_SCOPE_SYSTEM` should be used.

- **D3D_SHADER_CACHE_TARGET_FLAGS**:
``` C++
typedef enum D3D_SHADER_CACHE_TARGET_FLAGS
{
    D3D_SHADER_CACHE_TARGET_FLAG_NONE = 0,
}D3D_SHADER_CACHE_TARGET_FLAGS;
cpp_quote("DEFINE_ENUM_FLAG_OPERATORS( D3D_SHADER_CACHE_TARGET_FLAGS )")
```

Flags to modify target lookup behavior.  Currently reserved.

### Interface Definition: `ID3DShaderCacheInstallerClient`

```C++
// This interface is implemented by the game installer
interface ID3DShaderCacheInstallerClient
{
  HRESULT GetInstallerName(
      [annotation("_Inout_")] SIZE_T* pNameLength,
      [annotation("_Out_writes_opt_(*pNameLength)")] wchar_t* pName);

  D3D_SHADER_CACHE_APP_REGISTRATION_SCOPE GetInstallerScope();

  HRESULT HandleDriverUpdate(
      [annotation("_In_")] ID3DShaderCacheInstaller* pInstaller);
};

```
#### Methods
`GetInstallerName`

- **Description**: Returns the name of the installer application.

- **Parameters**:
    - `SIZE_T* pNameLength`: A pointer to `SIZE_T` variable to contain the length in characters of the name.
    - `wchar_t* pName`: A pointer to a wide character buffer to receive the name.

- **Return Type**: `HRESULT`

- **Remarks**:

    Used by an instance of `ID3DShaderCacheInstaller` to retrieve the name of store/installer application so that applications registered can be organized internally. This method should be called twice. Once with `pName` equal to `nullptr` in which case the method will return the length in characters (including null-terminator) in the memory pointed to by `pNameLength`. If `pName` is non-null than `pNameLength` must also be non-null and the value pointed to it bust be greater than or equal to the length of the name.

`GetInstallerScope`

- **Description**: Returns the what scope the installer will operate in.

- **Return Type**: `D3D_SHADER_CACHE_APP_REGISTRATION_SCOPE`

`HandleDriverUpdate`

- **Description**: Callback handler called after a graphics driver update has occurred.

- **Parameters**: `ID3DShaderCacheInstaller* pInstaller`: A pointer to an `ID3DShaderCacheInstaller` object that was listening for the driver update.

- **Remarks**:

This is a callback function that will be called by the system when a graphics driver update occurs. See 
`ID3DShaderCacheInstaller::RegisterDriverUpdateListener` for more information.

#### Usage

The user should instantiate their own final implementation of this interface and passing it to the D3DSCR API during `ID3DShaderCacheInstaller` creation. This object must persist for the lifetime of the `ID3DShaderCacheInstaller` object it is used with.

### Interface Definition: `ID3DShaderCacheComponent`

```c++
interface ID3DShaderCacheComponent : IUnknown
{
  HRESULT GetComponentName(
      [annotation("_Out_")] const wchar_t** pName);

  HRESULT GetStateObjectDatabasePath(
      [annotation("_Out_")] const wchar_t** pPath);

  HRESULT GetPrecompiledCachePath(
      [annotation("_In_")] const wchar_t* pAdapterFamily,
      [annotation("_Inout_")] const wchar_t** pPath);

  UINT GetPrecompiledShaderDatabaseCount();

  HRESULT GetPrecompiledShaderDatabases(
      UINT ArraySize,
      [annotation("_Out_writes_(ArraySize)")] D3D_SHADER_CACHE_PSDB_PROPERTIES* pPSDBs);
};
```
A shader component represents the pairing of one State Object Database (SODB) to one or more Pre-Compiled Shader Databases (PSDB) i.e. one for each supported GPU adapter installed in the system. A shader component has an identifying name as well as a file system path to the installed SODB file and associated PSDB files.

#### Methods

`GetComponentName`

- **Description**: Retrieves the name of the component.
- **Parameters**:
    - `const wchar_t** pName`: A pointer to receive the component name.
- **Return Type**: `HRESULT`

`GetStateObjectDatabasePath`

- **Description**: Retrieves the path to the state object database.
- **Parameters**:
    - `const wchar_t** pPath`: A pointer to receive the path.
- **Return Type**: `HRESULT`

`GetPrecompiledCachePath`

- **Description**: Retrieves the path to the precompiled cache.
- **Parameters**:
    - `const wchar_t* pAdapterFamily`: A pointer to a wide character string containing the adapter family name.
    - `const wchar_t** pPath`: A pointer to receive the path.
- **Return Type**: `HRESULT`

`GetPrecompiledShaderDatabaseCount`

- **Description**: Retrieves the number of precompiled shader databases.
- **Return Type**: `UINT`

`GetPrecompiledShaderDatabases`

- **Description**: Retrieves the precompiled shader databases.
- **Parameters**:
    - `UINT ArraySize`: The size of the array to receive the databases.
    - `D3D_SHADER_CACHE_PSDB_PROPERTIES* pPSDBs`: A pointer to an array to receive the database properties.
- **Return Type**: `HRESULT`

### Interface Definition: `ID3DShaderCacheApplication`
```C++
interface ID3DShaderCacheApplication : IUnknown
{
  HRESULT GetExePath(
      [annotation("_Out_")] const wchar_t** pExePath);

  HRESULT GetDesc(
      [annotation("_Out_")] D3D_SHADER_CACHE_APPLICATION_DESC* pApplicationDesc);

  HRESULT RegisterComponent(
      [annotation("_In_")] const wchar_t* pName,
      [annotation("_In_")] const wchar_t* pStateObjectDBPath,
      [annotation("_In_")] UINT NumPSDB,
      [annotation("_In_reads_(NumPSDB)")] const D3D_SHADER_CACHE_PSDB_PROPERTIES* pPSDBs,
      REFIID riid,
      [annotation("_COM_Outptr_")] void** ppvComponent);

  HRESULT RemoveComponent(
      [annotation("_In_")] ID3DShaderCacheComponent* pComponent);

  UINT GetComponentCount();

  HRESULT GetComponent(
      [annotation("_In_")] UINT index,
      REFIID riid,
      [annotation("_COM_Outptr_")] void** ppvComponent);

  UINT GetPrecompileTargetCount(D3D_SHADER_CACHE_TARGET_FLAGS flags);

  HRESULT GetPrecompileTargets(
      [annotation("_In_")] UINT ArraySize,
      [annotation("_In_reads_(ArraySize)")] D3D_SHADER_CACHE_COMPILER_PROPERTIES* pArray,
      D3D_SHADER_CACHE_TARGET_FLAGS flags);
};
```
Represents an application or game installed on a system. Each application can have one or more Components which represent cached shader objects.

#### Methods

`GetExePath`

- **Description**: Retrieves the full path to the exe.
- **Parameters**:
    - `const wchar_t** pExePath`: An out parameter that receives a pointer to the exe path.  The string's lifetime is controlled by the ID3DShaderCacheApplication and must not be used if the application is released.
- **Return Type**: `HRESULT`

`GetDesc`

- **Description**: Retrieves the application description.
- **Parameters**:
    - `D3D_SHADER_CACHE_APPLICATION_DESC* pApplicationDesc`: A pointer to a structure to receive the application desc.  The desc contains strings whose lifetime is controlled by the ID3DShaderCacheApplication and must not be used if the application is released.
- **Return Type**: `HRESULT`

`RegisterComponent`

- **Description**: Registers a component with the application.
- **Parameters**:
    - `const wchar_t* pName`: A pointer to a wide character string containing the name of the component.
    - `const wchar_t* pStateObjectDBPath`: A pointer to a wide character string containing the path to the state object database.
    - `UINT NumPSDB`: The number of precompiled shader databases.
    - `const D3D_SHADER_CACHE_PSDB_PROPERTIES* pPSDBs`: A pointer to an array of PSDB properties.
    - `REFIID riid`: The reference ID of the interface to retrieve.
    - `void** ppvComponent`: A pointer to receive the component interface.
- **Return Type**: `HRESULT`

`RemoveComponent`

- **Description**: Removes a component from the application.
- **Parameters**:
    - `ID3DShaderCacheComponent* pComponent`: A pointer to the component to remove.
- **Return Type**: `HRESULT`

- **Remarks**:

    After successful removal the `pComponent` will be in an invalid state and should be destroyed by the caller. Further operations on that object will return error results. Additionally any cached indicies of `ID3DShaderCacheComponent` objects should be considered invalidated after this operation.

`GetComponentCount`

- **Description**: Retrieves the number of components.
- **Return Type**: `UINT`

`GetComponent`

- **Description**: Retrieves a specific component by index.
- **Parameters**:
    - `UINT index`: The index of the component to retrieve.
    - `REFIID riid`: The reference ID of the interface to retrieve.
    - `void** ppvComponent`: A pointer to receive the component interface.
- **Return Type**: `HRESULT`

`GetPrecompileTargetCount`

- **Description**: Retrieves the number of precompile targets.
- **Parameters**:
    - `D3D_SHADER_CACHE_TARGET_FLAGS flags`: Modifiers for target lookup behavior.
- **Return Type**: `UINT`

`GetPrecompileTargets`

- **Description**: Retrieves the precompile targets.
- **Parameters**:
    - `UINT ArraySize`: The size of the array to receive the targets.
    - `D3D_SHADER_CACHE_COMPILER_PROPERTIES* pArray`: A pointer to an array to receive the targets.
    - `D3D_SHADER_CACHE_TARGET_FLAGS flags`: Modifiers for target lookup behavior.
- **Return Type**: `HRESULT`



### Interface Definition: `ID3DShaderCacheInstaller`
```C++
interface ID3DShaderCacheInstaller : IUnknown
{
  HRESULT RegisterDriverUpdateListener();

  HRESULT UnregisterDriverUpdateListener();

  HRESULT RegisterServiceDriverUpdateTrigger(
      SC_HANDLE hServiceHandle);

  HRESULT UnregisterServiceDriverUpdateTrigger(
      SC_HANDLE hServiceHandle);

  HRESULT RegisterApplication(
      [annotation("_In_")] const wchar_t* pExePath,
      [annotation("_In_")] const D3D_SHADER_CACHE_APPLICATION_DESC* pApplicationDesc,
      REFIID riid,
      [annotation("_COM_Outptr_")] void** ppvApp);

  HRESULT RemoveApplication(
      [annotation("_In_")] ID3DShaderCacheApplication* pApplication);

  UINT GetApplicationCount();

  HRESULT GetApplication(
      [annotation("_In_")] UINT index,
      REFIID riid,
      [annotation("_COM_Outptr_")] void** ppvApp);

  HRESULT ClearAllState();

  UINT GetMaxPrecompileTargetCount();

  HRESULT GetPrecompileTargets(
      [annotation("_In_opt_")] const D3D_SHADER_CACHE_APPLICATION_DESC* pApplicationDesc,
      [annotation("_In_")] UINT ArraySize,
      [annotation("_In_reads_(ArraySize)")] D3D_SHADER_CACHE_COMPILER_PROPERTIES* pArray,
      D3D_SHADER_CACHE_TARGET_FLAGS flags);
};
```

Manages the registration of applications and their associated SODBs and PSDBs.

#### Methods

`RegisterDriverUpdateListener`

- **Description**: Registers a listener for driver updates.
- **Return Type**: `HRESULT`

- **Remarks**: 

This API is used to indicated that the installer is interested in receiving notifications from the system whenever
a graphics driver is installed or updated. The callback function `HandleDriverUpdate` on the
`ID3DShaderCacheInstallerClient` interface will be called during a driver update.

When a new driver is available on the system the installer will need to review applications it has registered to determine if the PSDBs associated with the device have been invalidated.

`UnregisterDriverUpdateListener`

- **Description**: Unregisters a listener for driver updates.
- **Return Type**: `HRESULT`

`RegisterServiceDriverUpdateTrigger`

- **Description**: Registers a service driver update trigger.
- **Parameters**:
    - `SC_HANDLE hServiceHandle`: The service handle.
- **Return Type**: `HRESULT`

- **Remarks**: 

This function registers a Windows service trigger that will automatically start a service when a driver is installed or updated. This service trigger should be used to review registered applications to determine if the PSDBs associated with the device have been invalidated.

`ChangeServiceConfig2W` and related Win32 APIs can be used to modify the returned service's `SERVICE_CONFIG_TRIGGER_INFO` if required.

`UnregisterServiceDriverUpdateTrigger`

- **Description**: Unregisters a service driver update trigger.
- **Parameters**:
    - `SC_HANDLE hServiceHandle`: The service handle.
- **Return Type**: `HRESULT`

`RegisterApplication`

- **Description**: Registers a shader cache application.
- **Parameters**:
    - `const wchar_t* pExePath`: The fully qualified path to the main game executable.  This is used as a key to lookup the application in-process, so consider any hard-links.
    - `const D3D_SHADER_CACHE_APPLICATION_DESC* pApplicationDesc`: A pointer to a structure containing the application info.
    - `REFIID riid`: The reference ID of the interface to retrieve.
    - `void** ppvApp`: A pointer to receive the application interface.
- **Return Type**: `HRESULT`

`RemoveApplication`

- **Description**: Removes a shader cache application.
- **Parameters**:
    - `ID3DShaderCacheApplication* pApplication`: A pointer to the application to remove.
- **Return Type**: `HRESULT`

- **Remarks**: 

    After successful removal the `pApplication` will be in an invalid state and should be destroyed by the caller. Further operations on that object will return error results. Additionally any cached indicies of `ID3DShaderCacheApplication` objects should be considered invalidated after this operation.

`GetApplicationCount`

- **Description**: Retrieves the number of applications.
- **Return Type**: `UINT`

`GetApplication`

- **Description**: Retrieves a specific application by index.
- **Parameters**:
    - `UINT index`: The index of the application to retrieve.
    - `REFIID riid`: The reference ID of the interface to retrieve.
    - `void** ppvApp`: A pointer to receive the application interface.
- **Return Type**: `HRESULT`

`ClearAllState`

- **Description**: Clears all registered state.
- **Return Type**: `HRESULT`

`GetMaxPrecompileTargetCount`

- **Description**: Retrieves the maximum number of precompile targets installed on in the system.
- **Return Type**: `UINT`

`GetPrecompileTargets`

- **Description**: Retrieves the precompile targets.
- **Parameters**:
    - `const D3D_SHADER_CACHE_APPLICATION_DESC* pApplicationDesc`: An optional pointer to a structure containing the application info.  See Remarks.
    - `UINT ArraySize`: The size of the array to receive the targets.
    - `D3D_SHADER_CACHE_COMPILER_PROPERTIES* pArray`: A pointer to an array to receive the targets.
    - `D3D_SHADER_CACHE_TARGET_FLAGS flags`: Modifiers for target lookup behavior.
- **Return Type**: `HRESULT`

- **Remarks**:

    This API returns compiler compatibility information for each GPU adapter that supports using Precompiled Shader Databases(PSDB).  

    D3D_SHADER_CACHE_COMPILER_PROPERTIES are used to determine compatibility with the compiler parameters used to produce a PSDB:

    ```c++
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

    Within the supported range of compatible version numbers, a larger ABI version should be preferred, followed by a larger application profile version.

    D3D_SHADER_CACHE_COMPILER_PROPERTIES also indicates the version information that the drivers compiler uses if compiling at application runtime.  It compiles at MaximumABISupportVersion with the indicated CompilerVersion and ApplicationProfileVersion.

    CompilerVersion is provided for informational purposes.  It indicates the version of the compiler itself, and may not rev when application profiles do.

    When the D3D_SHADER_CACHE_APPLICATION_DESC is provided, it is used to filter the adapter list to the adapters preferred for use with the application.  In the future, the results may take into account GPU preference settings from the Windows Control panel and other GPU preference mechanisms.  The D3D_SHADER_CACHE_APPLICATION_DESC also informs the ApplicationProfileVersion, which is necessary to determine PSDB compatibility for a given application.

    D3D_SHADER_CACHE_APPLICATION_DESC is optional.  If not supplied, the ApplicationProfileVersion is not determined and is set to zero on output.  It may be useful to initially obtain version information that is not dependent on application identity when negotiating with services, but ApplicationProfileVersion should still be checked for compatibility before downloading PSDBs.  Additionally, the list of preferred adapters is not filtered when application identity is not known, so a check with application identity is needed to only download psdbs for preferred adapters.

### Interface Definition: `ID3DShaderCacheExplorer`
```c++
interface ID3DShaderCacheExplorer : IUnknown
{
    HRESULT GetApplicationFromExePath(
        [annotation("_In_")] const wchar_t* pFullExePath,
        [in] REFIID riid,
        [out, iid_is(riid), annotation("_COM_Outptr_")] void** ppvApp); // Expected: ID3DShaderCacheApplication
};
```
Creates a read-only view of the current state of the shader cache registration on the system. Any mutable operations on `ID3DShaderCacheApplication` or `ID3DShaderCacheComponent` objects obtained through this interface will fail and no state will be updated.

#### Methods

`GetApplicationFromExePath`

- **Description**: Retrieves an application based on its executable path.
- **Parameters**:
    - `const wchar_t* pFullExePath`: A pointer to a wide character string containing the full executable path.
    - `REFIID riid`: The reference ID of the interface to retrieve.
    - `void** ppvApp`: A pointer to receive the application interface.
- **Return Type**: `HRESULT`

### Interface Definition: `ID3DShaderCacheInstallerFactory`
```C++
interface ID3DShaderCacheInstallerFactory : IUnknown
{
    HRESULT CreateInstaller(
        [annotation("_In_")] ID3DShaderCacheInstallerClient* pClient,
        [in] REFIID riid,
        [out, iid_is(riid), annotation("_COM_Outptr_")] void** ppvInstaller);

    HRESULT CreateExplorer(
        [in] IUnknown* pUnknown,                                             // Expected: ID3D12Device, IDXCoreAdapter, IDXGIAdapter
        [in] REFIID riid,
        [out, iid_is(riid), annotation("_COM_Outptr_")] void** ppvExplorer); // Expected: ID3DShaderCacheExplorer
};
```
Factory interface for creating shader cache installers and explorers. `ID3DShaderCacheInstallerFactory` Objects are created using the `D3D12GetInterface` function by passing the `CLSID_D3DShaderCacheInstallerFactory` GUID.

#### Methods

`CreateInstaller`

- **Description**: Creates a shader cache installer.
- **Parameters**:
    - `ID3DShaderCacheInstallerClient* pClient`: A pointer to the client interface.
    - `REFIID riid`: The reference ID of the interface to retrieve.
    - `void** ppvInstaller`: A pointer to receive the installer interface.
- **Return Type**: `HRESULT`

- **Remarks**: Only a single instance of a given installer will be allowed be instantiated on a system at a given time. Installers are identified by the name returned by the `ID3DShaderCacheInstallerClient` interface at creation time.

`CreateExplorer`

- **Description**: Creates a shader cache explorer.
- **Parameters**:
    - `IUnknown* pUnknown`: A pointer to an unknown interface.
    - `REFIID riid`: The reference ID of the interface to retrieve.
    - `void** ppvExplorer`: A pointer to receive the explorer interface.
- **Return Type**: `HRESULT`

### Structure Definition: `D3D_SHADER_CACHE_PSDB_PROPERTIES`
```C++
typedef struct D3D_SHADER_CACHE_PSDB_PROPERTIES
{
    const wchar_t* pAdapterFamily;
    const wchar_t* pPsdbPath;
} D3D_SHADER_CACHE_PSDB_PROPERTIES;
```

Defines properties for precompiled shader database.

#### Fields

- `const wchar_t* pAdapterFamily`: Pointer to adapter family name.
- `const wchar_t* pPsdbPath`: Pointer to PSDB path.

### Structure Definition: `D3D_VERSION_NUMBER`
```C++
typedef union D3D_VERSION_NUMBER
{
    UINT64 Version;
    UINT16 VersionParts[4];
} D3D_VERSION_NUMBER;
```

Defines a version number as either a 64-bit integer or an array of 4 16-bit parts.

#### Fields

- `UINT64 Version`: Version as a 64-bit integer.
- `UINT16 VersionParts[4]`: Version as an array of 4 16-bit parts.

### Structure Definition: `D3D_SHADER_CACHE_COMPILER_PROPERTIES`
```C++
typedef struct D3D_SHADER_CACHE_COMPILER_PROPERTIES
{
    wchar_t szAdapterFamily[128];
    UINT64 MinimumABISupportVersion;
    UINT64 MaximumABISupportVersion;
    D3D_VERSION_NUMBER CompilerVersion;
    D3D_VERSION_NUMBER ApplicationProfileVersion;
} D3D_SHADER_CACHE_COMPILER_PROPERTIES;
```

Defines properties for shader cache compiler.

#### Fields

- `wchar_t szAdapterFamily[128]`: Adapter family name.
- `UINT64 MinimumABISupportVersion`: Minimum ABI support version.
- `UINT64 MaximumABISupportVersion`: Maximum ABI support version.
- `D3D_VERSION_NUMBER CompilerVersion`: Compiler version.
- `D3D_VERSION_NUMBER ApplicationProfileVersion`: Application profile version.

### Structure Definition: `D3D_SHADER_CACHE_APPLICATION_INFO`
```C++
typedef struct D3D_SHADER_CACHE_APPLICATION_INFO
{
    const wchar_t* pName;
    const wchar_t* pExeFilename;
    D3D_VERSION_NUMBER Version;
    const wchar_t* pEngineName;
    D3D_VERSION_NUMBER EngineVersion;
} D3D_SHADER_CACHE_APPLICATION_INFO;

```

The application desc is metadata used for drivers, compilers, and the D3D runtime to uniquely identify an application.

#### Fields

- `const wchar_t* pName`: Pointer to application name.
- `const wchar_t* pExeFilename`: Pointer to the exe filename.
- `UINT64 Version`: Application version.
- `const wchar_t* pEngineName`: Pointer to engine name.
- `UINT64 EngineVersion`: Engine version.

Notes:

- The pExeFilename should be the the filename for the main game exe, not any storefront or other game launchers.  The filename should be the game's typical filename, and does not have to match the exe filename on disk.  For example, if the game exe were simply renamed, the pExeFilename passed to this API does not change.

## Example Usage:
``` C++
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
        const std::wstring psdbName = L"AGame_warp.psdb";
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
            appDesc.Version = appVersion;
            appDesc.EngineVersion = engineVersion;

            CComPtr<ID3DShaderCacheApplication> pApp;
            VERIFY_SUCCEEDED(pInstaller->RegisterApplication(fullExePath.c_str(), &appDesc, IID_PPV_ARGS(&pApp)));

            UINT numPrecompileTargets = pApp->GetPrecompileTargetCount(D3D_SHADER_CACHE_TARGET_FLAG_NONE);

            std::vector<D3D_SHADER_CACHE_COMPILER_PROPERTIES> compileParams(numPrecompileTargets);
            VERIFY_SUCCEEDED(pApp->GetPrecompileTargets(numPrecompileTargets, compileParams.data(), D3D_SHADER_CACHE_TARGET_FLAG_NONE));

            std::vector<D3D_SHADER_CACHE_PSDB_PROPERTIES> psdbParams;
            for (auto& target : compileParams)
            {
                // < fetch the psdb for this app and device combo from the interwebs>
                // A compatible psdb is:
                //   - Compiled for the same adapter family
                //   - Targets an ABI compatible with the inclusive MinimumABISupportVersion and MaximumABISupportVersion.
                //   - The top 32bits of the ApplicationProfileVersion match.

                psdbParams.push_back({ params.szAdapterFamily, psdPath.c_str() });
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
                D3D_SHADER_CACHE_APPLICATION_INFO info = {};

                VERIFY_SUCCEEDED(pApp->GetInfo(&info));

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
                    VERIFY_IS_GREATER_THAN_OR_EQUAL(numPrecompileTargets, 1u);

                    D3D_SHADER_CACHE_COMPILER_PROPERTIES compileParams;

                    VERIFY_SUCCEEDED(pApp->GetPrecompileTargets(1, &compileParams, D3D_SHADER_CACHE_TARGET_FLAG_NONE));

                    const wchar_t* psdPathReadback = nullptr;
                    VERIFY_SUCCEEDED(component->GetPrecompiledCachePath(compileParams.szAdapterFamily, &psdPathReadback));

                    D3D_SHADER_CACHE_PSDB_PROPERTIES psdb = {};
                    VERIFY_SUCCEEDED(component->GetPrecompiledShaderDatabases(1u, &psdb));
                }
            }
        }
    }

```

## Windows Down Level Support:

While a D3D12 Runtime which supports interacting with this new API will be made available in-box for Windows 11 machines support will not be back ported to Windows 10 machines. While this means that already shipped applications running on Windows 10 won't be able to benefit from platform level SODB/PSDB injection it won't prevent new applications compiled against the latest D3D12 Agility SDK from using the shader caching APIs directly through D3D12. i.e. the lack of in-box support on Windows 10 should not be a concern for developers when they consider addressable market. 