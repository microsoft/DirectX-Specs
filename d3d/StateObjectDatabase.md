# D3D12 Advanced Shader Delivery - State Object Database

- [D3D12 Advanced Shader Delivery - State Object Database](#d3d12-advanced-shader-delivery---state-object-database)
  - [Overview](#overview)
  - [Terms and Acronyms](#terms-and-acronyms)
  - [D3D12 State Object Database API](#d3d12-state-object-database-api)
    - [GUID: CLSID\_D3D12StateObjectFactory](#guid-clsid_d3d12stateobjectfactory)
    - [Struct: D3D12\_APPLICATION\_DESC](#struct-d3d12_application_desc)
    - [Callback: D3D12ApplicationDescFunc](#callback-d3d12applicationdescfunc)
    - [Callback: D3D12PipelineStateFunc](#callback-d3d12pipelinestatefunc)
    - [Callback: D3D12StateObjectFunc](#callback-d3d12stateobjectfunc)
    - [Interface: ID3D12StateObjectDatabaseFactory](#interface-id3d12stateobjectdatabasefactory)
      - [Method: ID3D12StateObjectDatabaseFactory::CreateStateObjectDatabaseFromFile](#method-id3d12stateobjectdatabasefactorycreatestateobjectdatabasefromfile)
    - [Interface: ID3D12StateObjectDatabase](#interface-id3d12stateobjectdatabase)
      - [Method: ID3D12StateObjectDatabase::SetApplicationDesc](#method-id3d12stateobjectdatabasesetapplicationdesc)
      - [Method: ID3D12StateObjectDatabase::GetApplicationDesc](#method-id3d12stateobjectdatabasegetapplicationdesc)
      - [Method: ID3D12StateObjectDatabase::StorePipelineStateDesc](#method-id3d12stateobjectdatabasestorepipelinestatedesc)
      - [Method: ID3D12StateObjectDatabase::FindPipelineStateDesc](#method-id3d12stateobjectdatabasefindpipelinestatedesc)
      - [Method: ID3D12StateObjectDatabase::StoreStateObjectDesc](#method-id3d12stateobjectdatabasestorestateobjectdesc)
      - [Method: ID3D12StateObjectDatabase::FindStateObjectDesc](#method-id3d12stateobjectdatabasefindstateobjectdesc)
      - [Method: ID3D12StateObjectDatabase::FindObjectVersion](#method-id3d12stateobjectdatabasefindobjectversion)
  - [D3D12 Existing Collection By Key API](#d3d12-existing-collection-by-key-api)
    - [Enum: D3D12\_STATE\_SUBOBJECT\_TYPE](#enum-d3d12_state_subobject_type)
    - [Struct: D3D12\_EXISTING\_COLLECTION\_BY\_KEY\_DESC](#struct-d3d12_existing_collection_by_key_desc)
  - [D3D12 State Object Database API Example](#d3d12-state-object-database-api-example)
  - [SQL Database Schema](#sql-database-schema)

## Overview

The state object database describes a list of the State Objects and Pipeline State Objects used in the app. These inputs are used to create the precompiled cache and for the fallback scenario when the precompiled object is not found in the cache.

Supported creation/addition APIs:

- State object:
  - CreateStateObject
  - AddToStateObject
- Pipeline state object:
  - CreateGraphicsPipelineState
  - CreateComputePipelineState
  - CreatePipelineState

The state object database includes all the pipeline object types. The following is stored for each pipeline object type:

| Pipeline object type | Notes |
|--------|-------|
|Raytracing and work graph|Serialize full state object desc including DXIL shaders|
|Graphics and compute programs|Serialize each program including DXIL shaders|
|Pipeline State Object|Serialize full pipeline state desc including DXIL shaders|

## Terms and Acronyms

| Term | Definition |
| -- | -- |
| SO | State Object. A state object representing raytracing, work graphs, compute programs or graphics program components like the input assembler, rasterizer, pixel shader, and output merger, etc. |
| PSO | Pipeline State Object. A unified state object representing components like the input assembler, rasterizer, pixel shader, and output merger, etc. |
| Shader | A user-defined program that runs on some stage of the graphics processor.  Subset of PSO. |
| SODB | State object database. The serialized SO/PSO description objects and the shader DXIL needed to reconstruct any create SO/PSO API calls.|
| WG | Work graphs |
| DXR | Raytracing |

## D3D12 State Object Database API

### GUID: CLSID_D3D12StateObjectFactory

Use CLSID_D3D12StateObjectFactory with D3D12GetInterface to create the state object factory.

```c++
DEFINE_GUID(CLSID_D3D12StateObjectFactory,           0x54e1c9f3, 0x1303, 0x4112, 0xbf, 0x8e, 0x7b, 0xf2, 0xbb, 0x60, 0x6a, 0x73);
```

**Remarks**

Include initguid.h before d3d12.h to instantiate the CLSID_D3D12StateObjectFactory GUID.

```c++
#include <initguid.h>
#include <d3d12.h>
```

### Struct: D3D12_APPLICATION_DESC

```c++
typedef struct D3D12_APPLICATION_DESC
{
    LPCWSTR pExeFilename;
    LPCWSTR pName;
    D3D12_VERSION_NUMBER Version;
    LPCWSTR pEngineName;
    D3D12_VERSION_NUMBER EngineVersion;
} D3D12_APPLICATION_DESC;
```

Metadata to identify an application.  Information may be used to select an application specific compiler profile when compiling.

**Members**

*pExeFilename*

Main application executable name.  Includes the file extension, i.e "Code.exe".  This parameter is required and must be null terminated.  See Remarks.

*pName*

The title of the application.  Example: "Microsoft Visual Studio Code".  This parameter is required and must be null terminated.

*Version*

The version of the application.  For example, for Visual Studio Code 1.93.1, the version would be:

0x0001005D00010000

This parameter is required.  See [D3D12_VERSION_NUMBER](#union-d3d12_version_number).

*pEngineName*

The name of the game engine used  This parameter is optional, but should be provided whenever possible and must be null terminated.  Use nullptr to indicate not applicable.

*EngineVersion*

The version of the engine.  For example, for4.3, the version would be:

0x0004000300000000

This parameter is requires if pEngineName is non-nullptr.  See [D3D12_VERSION_NUMBER](#union-d3d12_version_number).

**Remarks**

The member pExeFilename is used to help uniquely identify an application, but SODBs and PSDBs generated with this value may be used from other executables within the same application. For usermode drivers and the D3D12 runtime, this value is not guaranteed to match the host executable.

### Callback: D3D12ApplicationDescFunc

A callback to read an application desc from a State Object Database.

```idl
typedef void(__stdcall* D3D12ApplicationDescFunc) (
    [annotation("_In_")] const D3D12_APPLICATION_DESC* pApplicationDesc,
    [annotation("_Inout_opt_")] void* pContext
    );
```

**Parameters**

*pApplicationDesc*

Describes the target application and version.  See [D3D12_APPLICATION_DESC](#struct-d3d12_application_desc).

*pContext*

An application specified context pointer that is passed to the callback.  Use this to pass parameters to the callback function.

**Remarks**

Pointers passed to this callback are only valid until the callback returns.  See [ID3D12StateObjectDatabase::GetApplicationDesc](#method-id3d12stateobjectdatabasegetapplicationdesc).

### Callback: D3D12PipelineStateFunc

A callback to read a D3D12_PIPELINE_STATE_STREAM_DESC from a State Object Database.

```idl
typedef void(__stdcall* D3D12PipelineStateFunc) (
    [annotation("_In_reads_bytes_(KeySize)")] const void* pKey,
    UINT KeySize,
    UINT Version,
    const D3D12_PIPELINE_STATE_STREAM_DESC* pDesc,
    [annotation("_Inout_opt_")] void* pContext
    );
```

**Parameters**

*pKey*

A unique sequence of bytes that uniquely identifies an object in the database.

*KeySize*

The size in bytes of pKey.

*Version*

The version of the Pipeline State Object.  See Remarks.

*pDesc*

The D3D12_PIPELINE_STATE_STREAM_DESC desc that describes the PSO.  See Remarks.

*pContext*

An application specified context pointer that is passed to the callback.  Use this to pass parameters to the callback function.

**Remarks**

Pointers passed to this callback are only valid until the callback returns.  See [ID3D12StateObjectDatabase::FindPipelineStateDesc](#method-id3d12stateobjectdatabasefindpipelinestatedesc).

Only one Version of a PSO may be stored in an SODB/PSDB at a time.  This value is present to allow an object to be versioned without code changes for the lookup.

The pDesc parameter is not validated against any driver reported capabilities when stored.  

### Callback: D3D12StateObjectFunc

A callback to read a D3D12_STATE_OBJECT_DESC and a state object parent key from a State Object Database.

```idl
typedef void(__stdcall* D3D12StateObjectFunc) (
    [annotation("_In_reads_bytes_(KeySize)")] const void* pKey,
    UINT KeySize,
    UINT Version,
    const D3D12_STATE_OBJECT_DESC* pDesc,
    [annotation("_In_reads_bytes_(ParentKeySize)")] const void* pParentKey,
    UINT ParentKeySize,
    [annotation("_Inout_opt_")] void* pContext
    );
```

**Parameters**

*pKey*

A unique sequence of bytes that uniquely identifies an object in the database.

*KeySize*

The size in bytes of pKey.

*Version*

The version of the State Object.  See Remarks.

*pDesc*

The D3D12_STATE_OBJECT_DESC that defines the state object.  See Remarks.

*pParentKey*

A unique sequence of bytes that uniquely identifies the parent object in the database.

*ParentKeySize*

The size in bytes of pParentKey.

*pContext*

An application specified context pointer that is passed to the callback.  Use this to pass parameters to the callback function.

**Remarks**

Pointers passed to this callback are only valid until the callback returns.  See [ID3D12StateObjectDatabase::FindStateObjectDesc](#method-id3d12stateobjectdatabasefindstateobjectdesc).

Only one Version of a State Object may be stored in an SODB/PSDB at a time.  This value is present to allow an object to be versioned without code changes for the lookup.

The pDesc parameter is not validated against any driver reported capabilities when stored.  

### Interface: ID3D12StateObjectDatabaseFactory

```idl
interface ID3D12StateObjectDatabaseFactory
    : IUnknown
{
    HRESULT CreateStateObjectDatabaseFromFile(
        LPCWSTR pDatabaseFile,
        D3D12_STATE_OBJECT_DATABASE_FLAGS flags,
        REFIID riid,
        [out, iid_is(riid), annotation("_COM_Outptr_")] void** ppvStateObjectDatabase
    );
};
```

#### Method: ID3D12StateObjectDatabaseFactory::CreateStateObjectDatabaseFromFile

### Interface: ID3D12StateObjectDatabase

```idl
interface ID3D12StateObjectDatabase
    : IUnknown
{
    HRESULT SetApplicationDesc(
        [annotation("_In_")] const D3D12_APPLICATION_DESC* pApplicationDesc);

    HRESULT GetApplicationDesc(
        [annotation("_In_")] D3D12ApplicationDescFunc CallbackFunc,
        [annotation("_Inout_opt_")] void* pContext);

    HRESULT StorePipelineStateDesc(
        [annotation("_In_reads_(KeySize)")] const void* pKey,
        UINT KeySize,
        UINT Version,
        [annotation("_In_")] const D3D12_PIPELINE_STATE_STREAM_DESC* pDesc);

    HRESULT FindPipelineStateDesc(
        [annotation("_In_reads_(KeySize)")] const void* pKey,
        UINT KeySize,
        [annotation("_In_")] D3D12PipelineStateFunc CallbackFunc,
        [annotation("_Inout_opt_")] void* pContext);

    HRESULT StoreStateObjectDesc(
        [annotation("_In_reads_(KeySize)")] const void* pKey,
        UINT KeySize,
        UINT Version,
        [annotation("_In_")] const D3D12_STATE_OBJECT_DESC* pDesc,
        [annotation("_In_reads_opt_(StateObjectToGrowFromKeySize)")] const void* pStateObjectToGrowFromKey,
        UINT StateObjectToGrowFromKeySize);

    HRESULT FindStateObjectDesc(
        [annotation("_In_reads_(keySize)")] const void* pKey,
        UINT KeySize,
        D3D12StateObjectFunc CallbackFunc,
        [annotation("_Inout_opt_")] void* pContext);

    HRESULT FindObjectVersion(
        [annotation("_In_reads_(keySize)")] const void* pKey,
        UINT KeySize,
        [annotation("_Out_")] UINT* pVersion);
};
```

#### Method: ID3D12StateObjectDatabase::SetApplicationDesc

Set or update the Application Desc stored in the database.  This should be updated whenever the application version or engine version changes.

**Parameters**

*pApplicationDesc*

The application desc to store in the database.  See [D3D12_APPLICATION_DESC](#struct-d3d12_application_desc).

**Remarks**

#### Method: ID3D12StateObjectDatabase::GetApplicationDesc

Retrieves the D3D12_APPLICATION_DESC from the database.

**Parameters**

*CallbackFunc*

A [D3D12ApplicationDescFunc](#callback-d3d12applicationdescfunc) callback function pointer that receives the stored application desc. 

*pContext*

An application specified context pointer that is passed to the callback.  Use this to pass parameters to the callback function.

**Remarks**

If no application desc was previously stored, this function returns DXGI_ERROR_NOT_FOUND.

#### Method: ID3D12StateObjectDatabase::StorePipelineStateDesc

Stores a Pipeline State Desc in the database by key.

**Parameters**

*pKey*

A unique sequence of bytes that uniquely identifies an object in the database.

*KeySize*

The size in bytes of pKey.

*Version*

The version of the object being stored.  The database author is expected to rev this version number anytime the object pointed to by pKey is modified.  See Remarks.

*pDesc*

The D3D12_PIPELINE_STATE_STREAM_DESC describing the pipeline state object.

**Remarks**

The key must be unique in the database for all objects regardless of object type or version.  It does not necessarily need to be derived from the pipeline state desc. It can be some application specific scheme.  Objects are versioned to allow the contents of the desc to change without necessarily changing the key.  For example, this could enable modifying a shader without modifying the calling code that references it by key.  This version number is used to match with precompiled binaries in a separate database.  Only one version of an object may be stored in the database.

Pipeline State Stream descs cannot refer to API objects during storage, so the following types must be substituted for storage:

- Root signatures: ID3D12RootSignature pointers must be replaced by D3D12_SERIALIZED_ROOT_SIGNATURE_DESC

These types do not have driver dependencies.

#### Method: ID3D12StateObjectDatabase::FindPipelineStateDesc

**Parameters**

*pContext*

An application specified context pointer that is passed to the callback.  Use this to pass parameters to the callback function.

**Remarks**

DXGI_ERROR_NOT_FOUND is returned if an object with pKey is not found.

This method returns a compatible desc to what was stored, but may not be a bit exact match.  For example, Most structs in a pipeline stream have defaults implied by there absence.  These structs may be present in the find with their default values.

#### Method: ID3D12StateObjectDatabase::StoreStateObjectDesc

Stores a State Object Desc in the database by key.

**Parameters**

*pKey*

A unique sequence of bytes that uniquely identifies an object in the database. See Remarks.

*KeySize*

The size in bytes of pKey.

*Version*

The version of the object being stored.  The database author is expected to rev this version number anytime the object pointed to by pKey is modified.  See Remarks.

*pDesc*

The D3D12_STATE_OBJECT_DESC describing the state object or state object additions.

*pStateObjectToGrowFromKey*

A unique sequence of bytes that uniquely identifies the base object that this object description adds to in the database.  This parameter may be nullptr to indicate no base object to derive from.  If non-nullptr, the object indicated by this key must already be in the database.

*StateObjectToGrowFromKeySize*

The size in bytes of pStateObjectToGrowFromKey.

**Remarks**

The key must be unique in the database for all objects regardless of object type or version.  It does not necessarily need to be derived from the state object desc. It can be some application specific scheme.  Objects are versioned to allow the contents of the desc to change without necessarily changing the key.  For example, this could enable modifying a shader without modifying the calling code that references it by key.  This version number is used to match with precompiled binaries in a separate database.  Only one version of an object may be stored in the database.

State Object descs cannot refer to API objects during storage, so the following types must be substituted for storage:

- Root signatures: ID3D12RootSignature pointers must be replaced by D3D12_SERIALIZED_ROOT_SIGNATURE_DESC
- Existing Collections: ID3D12StateObject pointers embedded in the desc must be replaced by D3D12_EXISTING_COLLECTION_BY_KEY_DESC.
- Parents are referred to by key instead of by ID3D12StateObject pointer.

These types do not have driver dependencies.

#### Method: ID3D12StateObjectDatabase::FindStateObjectDesc

Calls a supplied callback function with the state object description for a specified key.

**Parameters**

*pKey*

A unique sequence of bytes that uniquely identifies an object in the database.

*KeySize*

The size in bytes of pKey.

*CallbackFunc*

A [D3D12StateObjectFunc](#callback-d3d12stateobjectfunc) callback function pointer that receives the state object desc pointed to by pKey if it exists.

*pContext*

An application specified context pointer that is passed to the callback.  Use this to pass parameters to the callback function that receives the state object desc.

**Remarks**

DXGI_ERROR_NOT_FOUND is returned if an object with pKey is not found.

This method returns a compatible desc to what was stored, but may not be a bit exact match.  For example, Most structs in a State Object Desc have defaults implied by there absence.  These structs may be present in the find results with their default values. Also, objects such as arrays or subobjects may not appear in the same order as they were stored where the order has no meaning.

#### Method: ID3D12StateObjectDatabase::FindObjectVersion

Retrieve the version number of stored object. This can be queried for any object type stored.

**Arguments**

*pKey*

A unique sequence of bytes that uniquely identifies an object in the database.

*KeySize*

The size in bytes of pKey.

*pVersion*

Upon successful return, contains the version number of the object.  The database author is expected to rev this version number anytime the unique object pointed to by pKey is modified.  

**Remarks**

DXGI_ERROR_NOT_FOUND is returned if an object with pKey is not found.

Keys must be unique in the database, but are not required to be derived from the object contents.  Whenever object contents change for a given key, rev the version number.

This method can be used to determine if an entry is in the database.

## D3D12 Existing Collection By Key API

A new D3D12_STATE_SUBOBJECT_TYPE is defined so that D3D12_STATE_OBJECT_DESC can refer to existing collections by key rather than by driver-dependent ID3D12StateObject pointers.  This is used for storing D3D12_STATE_OBJECT_DESC in an SODB, but cannot be used with API that create API state objects such as ID3D12Device5::CreateStateObject or ID3D12Compiler::CompileStateObject.

### Enum: D3D12_STATE_SUBOBJECT_TYPE

```idl
typedef enum D3D12_STATE_SUBOBJECT_TYPE
{
    ... // Existing values omitted
    D3D12_STATE_SUBOBJECT_TYPE_EXISTING_COLLECTION_BY_KEY = 36, // D3D12_EXISTING_COLLECTION_BY_KEY_DESC
} D3D12_STATE_SUBOBJECT_TYPE;
```

**Constants**

*D3D12_STATE_SUBOBJECT_TYPE_EXISTING_COLLECTION_BY_KEY*

Specifies a subobject that references an existing collection by key rather than by an API pointer.  See [D3D12_EXISTING_COLLECTION_BY_KEY_DESC](#struct-d3d12_existing_collection_by_key_desc).

### Struct: D3D12_EXISTING_COLLECTION_BY_KEY_DESC

A Subobject desc of a state object desc that refers to an existing collection in a state object database by key rather than by API pointer. 

```idl
typedef struct D3D12_EXISTING_COLLECTION_BY_KEY_DESC
{
    [annotation("_Field_size_bytes_full_(KeySize)")] const void* pKey;
    UINT KeySize;
    UINT NumExports; // Optional, if 0 all exports in the library/collection will be surfaced
    [annotation("_In_reads_(NumExports)")] const D3D12_EXPORT_DESC* pExports;
} D3D12_EXISTING_COLLECTION_BY_KEY_DESC;
```

**Members**

*pKey*

A unique sequence of bytes that uniquely identifies an object in the database. See Remarks.

*KeySize*

The size in bytes of pKey.

*NumExports*

Size of the pExports array. If 0, all of the collection’s exports get exported.

*pExports*

Optional exports array.

## D3D12 State Object Database API Example

```c++
#include <initguid.h>
#include <d3d12.h>

int main()
{
    // Retrieve the factory.
    CComPtr<ID3D12StateObjectDatabaseFactory> spStateObjectDatabaseFactory;
    VERIFY_SUCCEEDED(D3D12GetInterface(CLSID_D3D12StateObjectFactory, IID_PPV_ARGS(&spStateObjectDatabaseFactory)));

    // Create a state object database.
    std::wstring tempFilePath = GetSODBPath();
    Microsoft::WRL::ComPtr<ID3D12StateObjectDatabase> spStateObjectDatabase;
    VERIFY_SUCCEEDED(spStateObjectDatabaseFactory->CreateStateObjectDatabaseFromFile(
        tempFilePath.c_str(), 
        D3D12_STATE_OBJECT_DATABASE_FLAG_NONE, 
        IID_PPV_ARGS(&spStateObjectDatabase)));

    // Store the Application Description
    {
        D3D12_APPLICATION_DESC appDesc = {};
        appDesc.pExeFilename = L"ExampleApp.exe";
        appDesc.pName = L"Example App";
        appDesc.Version.Version = 0x0001000000000000; // 1.0.0.0
        appDesc.pEngineName = L"Example Engine";
        appDesc.EngineVersion.Version = 0x14004800090000; //2.72.9.0
        VERIFY_SUCCEEDED(spStateObjectDatabase->SetApplicationDesc(&appDesc));
    }

    // Store an example Pipeline State Object (PSO)
    const char psoKey[] = "StateObjectDatabase_Dxil_VSPS";
    const UINT psoKeySize = sizeof(psoKey);
    UINT psoVersion = 1u;

    {
        Microsoft::WRL::ComPtr<IDxcBlob> spRootSignatureVS = m_DXILHelper.CompileHLSL(RootSignatureVS, L"VS", m_vsTargetProfile);
        Microsoft::WRL::ComPtr<IDxcBlob> spRootSignaturePS1 = m_DXILHelper.CompileHLSL(RootSignaturePS1, L"PS", m_psTargetProfile);

        struct PSO_STREAM
        {
            CD3DX12_PIPELINE_STATE_STREAM_PRIMITIVE_TOPOLOGY PrimitiveTopologyType;
            CD3DX12_PIPELINE_STATE_STREAM_INPUT_LAYOUT InputLayout;
            CD3DX12_PIPELINE_STATE_STREAM_VS VS;
            CD3DX12_PIPELINE_STATE_STREAM_PS PS;
        }
        PSOStream = 
        { 
            D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE, 
            DefaultIL, 
            AssignShaderBytecode(spRootSignatureVS.Get()), 
            AssignShaderBytecode(spRootSignaturePS1.Get()) 
        };

        D3D12_PIPELINE_STATE_STREAM_DESC StreamDesc{ sizeof(PSOStream), &PSOStream };
        VERIFY_SUCCEEDED(spStateObjectDatabase->StorePipelineStateDesc(psoKey, psoKeySize, psoVersion, &StreamDesc));
    }

    // Store an example State Object (SO) Generic Programs
    const char soKey[] = "SODB_SimpleSO";
    UINT soKeySize = sizeof(soKey);
    UINT soVersion = 1u;

    {
        D3D12_INPUT_ELEMENT_DESC inputElementDescs[] =
        {
            { "POSITION", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 0, D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 },
            { "COLOR", 0, DXGI_FORMAT_R32G32B32A32_FLOAT, 0, 12, D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 }
        };

        CD3DX12_STATE_OBJECT_DESC executableStateObjectDesc(D3D12_STATE_OBJECT_TYPE_EXECUTABLE);

        auto pRTFormats = executableStateObjectDesc.CreateSubobject<CD3DX12_RENDER_TARGET_FORMATS_SUBOBJECT>();
        pRTFormats->SetNumRenderTargets(1);
        pRTFormats->SetRenderTargetFormat(0, DXGI_FORMAT_R8G8B8A8_UNORM);

        auto pBlendState = executableStateObjectDesc.CreateSubobject<CD3DX12_BLEND_SUBOBJECT>();
        pBlendState->SetAlphaToCoverageEnable(true);

        auto pPrimitiveTopology = executableStateObjectDesc.CreateSubobject<CD3DX12_PRIMITIVE_TOPOLOGY_SUBOBJECT>();
        pPrimitiveTopology->SetPrimitiveTopologyType(D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE);

        auto pIL = executableStateObjectDesc.CreateSubobject<CD3DX12_INPUT_LAYOUT_SUBOBJECT>();

        for (UINT i = 0; i < _countof(inputElementDescs); i++)
        {
            pIL->AddInputLayoutElementDesc(inputElementDescs[i]);
        }

        auto vsBytecode = AssignShaderBytecode(vs.Get());
        auto pVS = executableStateObjectDesc.CreateSubobject<CD3DX12_DXIL_LIBRARY_SUBOBJECT>();
        pVS->SetDXILLibrary(&vsBytecode);
        pVS->DefineExport(L"VSMain", L"*");

        auto psBytecode = AssignShaderBytecode(ps.Get());
        auto pPS = executableStateObjectDesc.CreateSubobject<CD3DX12_DXIL_LIBRARY_SUBOBJECT>();
        pPS->SetDXILLibrary(&psBytecode);
        pPS->DefineExport(L"PSMain", L"*");

        auto pGenericProgram = executableStateObjectDesc.CreateSubobject<CD3DX12_GENERIC_PROGRAM_SUBOBJECT>();
        pGenericProgram->SetProgramName(L"testProgram");
        pGenericProgram->AddExport(L"VSMain");
        pGenericProgram->AddExport(L"PSMain");
        pGenericProgram->AddSubobject(*pIL);
        pGenericProgram->AddSubobject(*pRTFormats);
        pGenericProgram->AddSubobject(*pBlendState);
        pGenericProgram->AddSubobject(*pPrimitiveTopology);

        VERIFY_SUCCEEDED(spStateObjectDatabase->StoreStateObjectDesc(
            soKe,
            soKeySize,
            soVersion,
            executableStateObjectDesc,
            nullptr,  // No Parent
            0u));
    }

    // State object with generic program using a collection to keep all the shaders
    // Shaders use root signatures specified in the shader code.
    {
        // Compile shaders
        Microsoft::WRL::ComPtr < IDxcBlob > vs = m_DXILHelper.CompileHLSL(PositionColorVS, L"VSMain", L"vs_6_7");
        Microsoft::WRL::ComPtr < IDxcBlob > ps = m_DXILHelper.CompileHLSL(PositionColorPS, L"PSMain", L"ps_6_7");

        // Define vertex input layout
        D3D12_INPUT_ELEMENT_DESC inputElementDescs[] =
        {
            { "POSITION", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 0, D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 },
            { "COLOR", 0, DXGI_FORMAT_R32G32B32A32_FLOAT, 0, 12, D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 }
        };

        // Create collection
        CD3DX12_STATE_OBJECT_DESC collectionStateObjectDesc(D3D12_STATE_OBJECT_TYPE_COLLECTION);

        auto vsBytecode = AssignShaderBytecode(vs.Get());
        auto pVS = collectionStateObjectDesc.CreateSubobject<CD3DX12_DXIL_LIBRARY_SUBOBJECT>();
        pVS->SetDXILLibrary(&vsBytecode);
        pVS->DefineExport(L"VSMain", L"*");

        auto psBytecode = AssignShaderBytecode(ps.Get());
        auto pPS = collectionStateObjectDesc.CreateSubobject<CD3DX12_DXIL_LIBRARY_SUBOBJECT>();
        pPS->SetDXILLibrary(&psBytecode);
        pPS->DefineExport(L"PSMain", L"*");

        const char collectionKeyStr[] = "SODB_TestKeyVerifyCreateStateObjectCollection";
        UINT collectionKeyStrSize = sizeof(collectionKeyStr);
        UINT collectionGroupVersion = 1u;

        VERIFY_SUCCEEDED(spStateObjectDatabase->StoreStateObjectDesc(
            collectionKeyStr,
            collectionKeyStrSize,
            collectionGroupVersion,
            collectionStateObjectDesc,
            nullptr,  // No Parent
            0u));

        CD3DX12_STATE_OBJECT_DESC executableStateObjectDesc(D3D12_STATE_OBJECT_TYPE_EXECUTABLE);

        auto pPrimitiveTopology = executableStateObjectDesc.CreateSubobject<CD3DX12_PRIMITIVE_TOPOLOGY_SUBOBJECT>();
        pPrimitiveTopology->SetPrimitiveTopologyType(D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE);

        auto pIL = executableStateObjectDesc.CreateSubobject<CD3DX12_INPUT_LAYOUT_SUBOBJECT>();

        for (UINT i = 0; i < _countof(inputElementDescs); i++)
        {
            pIL->AddInputLayoutElementDesc(inputElementDescs[i]);
        }

        auto pBlendState = executableStateObjectDesc.CreateSubobject<CD3DX12_BLEND_SUBOBJECT>();
        pBlendState->SetAlphaToCoverageEnable(true);

        auto pRTFormats = executableStateObjectDesc.CreateSubobject<CD3DX12_RENDER_TARGET_FORMATS_SUBOBJECT>();
        pRTFormats->SetNumRenderTargets(1);
        pRTFormats->SetRenderTargetFormat(0, DXGI_FORMAT_R8G8B8A8_UNORM);;

        auto pCollection = executableStateObjectDesc.CreateSubobject<CD3DX12_EXISTING_COLLECTION_BY_KEY_SUBOBJECT>();
        pCollection->SetExistingCollection(collectionKeyStr, collectionKeyStrSize);

        auto pGenericProgram = executableStateObjectDesc.CreateSubobject<CD3DX12_GENERIC_PROGRAM_SUBOBJECT>();
        pGenericProgram->SetProgramName(L"testProgram1");
        pGenericProgram->AddExport(L"VSMain");
        pGenericProgram->AddExport(L"PSMain");
        pGenericProgram->AddSubobject(*pPrimitiveTopology);
        pGenericProgram->AddSubobject(*pBlendState);
        pGenericProgram->AddSubobject(*pIL);
        pGenericProgram->AddSubobject(*pRTFormats);

        const char objectName[] = "SODB_TestKeyVerifyCreateStateObjectGP";
        UINT keySize = sizeof(objectName);
        UINT Version = 2u;

        VERIFY_SUCCEEDED(spStateObjectDatabase->StoreStateObjectDesc(
            objectName,
            keySize,
            version,
            executableStateObjectDesc,
            nullptr,  // No Parent
            0u));
    }

    struct Context
    {
        uint32_t psoCount = 0;
        uint32_t soCount = 0;
        bool hasAppDesc = false;
    } context;

    // Retrieve the application desc.
    {
        auto pfnApplicationDesc = [](const D3D12_APPLICATION_DESC* pDesc, void* pContext)
            {
                auto& context = *static_cast<Context*>(pContext);
                context.hasAppDesc = true;

                // Use pDesc
            };

        VERIFY_SUCCEEDED(spStateObjectDatabase->GetApplicationDesc(pfnApplicationDesc, &context));
    }

    // Find a Pipeline State Object
    {
        auto pfnPipelineState = [](const void* pKey, UINT KeySize, UINT Version, const D3D12_PIPELINE_STATE_STREAM_DESC* pDesc, void* pContext)
            {
                auto& context = *static_cast<Context*>(pContext);
                context.psoCount++;

                // Use pDesc
                // Note: May contain CD3DX12_GLOBAL_SERIALIZED_ROOT_SIGNATURE_SUBOBJECT or CD3DX12_LOCAL_SERIALIZED_ROOT_SIGNATURE_SUBOBJECT
                // which cannot currently be consumed by the compiler or runtime.
            };

        VERIFY_SUCCEEDED(spStateObjectDatabase->FindPipelineStateDesc(psoKey, psoKeySize, pfnPipelineState, &context));
    }

    // Find a State Object
    {
        auto pfnStateObject = [](const void* pKey, UINT KeySize, UINT Version, const D3D12_STATE_OBJECT_DESC* pDesc, const void* pParentKey, UINT ParentKeySize, void* pContext)
        {
            auto& context = *static_cast<Context*>(pContext);
            context.soCount++;

            // Use pDesc
            // Note: May contain CD3DX12_GLOBAL_SERIALIZED_ROOT_SIGNATURE_SUBOBJECT, CD3DX12_LOCAL_SERIALIZED_ROOT_SIGNATURE_SUBOBJECT, or
            // CD3DX12_EXISTING_COLLECTION_BY_KEY_SUBOBJECT which cannot currently be consumed by the compiler or runtime.
        };

        VERIFY_SUCCEEDED(spStateObjectDatabase->FindStateObjectDesc(soKey, soKeySize, pfnStateObject, &context));
    }
}

```

## SQL Database Schema

The State Object Database is a [SQLite](https://sqlite.org/) database with the following schema.  The schema is versioned to facilitate future additions and bug fixes.

```sql
PRAGMA user_version = 2;
PRAGMA application_id = 0xD3D50DB;

CREATE TABLE root_signatures (Key BLOB NOT NULL PRIMARY KEY , value BLOB NOT NULL );
CREATE TABLE input_element_descs (Key BLOB NOT NULL PRIMARY KEY , SemanticName TEXT NOT NULL ,SemanticIndex INTEGER NOT NULL ,Format INTEGER NOT NULL ,InputSlot INTEGER NOT NULL ,AlignedByteOffset INTEGER NOT NULL ,InputSlotClass INTEGER NOT NULL ,InstanceDataStepRate INTEGER NOT NULL );
CREATE TABLE state_objects (Key BLOB NOT NULL PRIMARY KEY , Type INTEGER  ,NodeMask INTEGER  ,Flags INTEGER  ,AddToStateObjectParent BLOB  ,FOREIGN KEY(AddToStateObjectParent) REFERENCES state_objects(Key));
CREATE TABLE shader_bytecode (Key BLOB NOT NULL PRIMARY KEY , Type TEXT  ,Bytecode BLOB  );
CREATE TABLE exports (Key BLOB NOT NULL PRIMARY KEY , Name TEXT NOT NULL ,ExportToRename TEXT  ,Flags INTEGER NOT NULL );
CREATE TABLE depth_stencil_op_descs (Key BLOB NOT NULL PRIMARY KEY , StencilFailOp INTEGER NOT NULL ,StencilDepthFailOp INTEGER NOT NULL ,StencilPassOp INTEGER NOT NULL ,StencilFunc INTEGER NOT NULL ,StencilReadMask INTEGER NOT NULL ,StencilWriteMask INTEGER NOT NULL );
CREATE TABLE depth_stencil_descs (Key BLOB NOT NULL PRIMARY KEY , DepthEnable INTEGER NOT NULL ,DepthWriteMask INTEGER NOT NULL ,DepthFunc INTEGER NOT NULL ,StencilEnable INTEGER NOT NULL ,FrontFace BLOB NOT NULL ,BackFace BLOB NOT NULL ,DepthBoundsTestEnable INTEGER NOT NULL ,FOREIGN KEY(FrontFace) REFERENCES depth_stencil_op_descs(Key),FOREIGN KEY(BackFace) REFERENCES depth_stencil_op_descs(Key));
CREATE TABLE render_target_formats (Key BLOB NOT NULL PRIMARY KEY , RTFormat0 INTEGER NOT NULL ,RTFormat1 INTEGER NOT NULL ,RTFormat2 INTEGER NOT NULL ,RTFormat3 INTEGER NOT NULL ,RTFormat4 INTEGER NOT NULL ,RTFormat5 INTEGER NOT NULL ,RTFormat6 INTEGER NOT NULL ,RTFormat7 INTEGER NOT NULL ,NumRenderTargets INTEGER NOT NULL );
CREATE TABLE render_target_blend_descs (Key BLOB NOT NULL PRIMARY KEY , BlendEnable INTEGER NOT NULL ,LogicOpEnable INTEGER NOT NULL ,SrcBlend INTEGER NOT NULL ,DestBlend INTEGER NOT NULL ,BlendOp INTEGER NOT NULL ,SrcBlendAlpha INTEGER NOT NULL ,DestBlendAlpha INTEGER NOT NULL ,BlendOpAlpha INTEGER NOT NULL ,LogicOp INTEGER NOT NULL ,RenderTargetWriteMask INTEGER NOT NULL );
CREATE TABLE blend_descs (Key BLOB NOT NULL PRIMARY KEY , AlphaToCoverageEnable INTEGER NOT NULL ,IndependentBlendEnable INTEGER NOT NULL ,RenderTarget0 BLOB  ,RenderTarget1 BLOB  ,RenderTarget2 BLOB  ,RenderTarget3 BLOB  ,RenderTarget4 BLOB  ,RenderTarget5 BLOB  ,RenderTarget6 BLOB  ,RenderTarget7 BLOB  ,FOREIGN KEY(RenderTarget0) REFERENCES render_target_blend_descs(Key),FOREIGN KEY(RenderTarget1) REFERENCES render_target_blend_descs(Key),FOREIGN KEY(RenderTarget2) REFERENCES render_target_blend_descs(Key),FOREIGN KEY(RenderTarget3) REFERENCES render_target_blend_descs(Key),FOREIGN KEY(RenderTarget4) REFERENCES render_target_blend_descs(Key),FOREIGN KEY(RenderTarget5) REFERENCES render_target_blend_descs(Key),FOREIGN KEY(RenderTarget6) REFERENCES render_target_blend_descs(Key),FOREIGN KEY(RenderTarget7) REFERENCES render_target_blend_descs(Key));
CREATE TABLE rasterizer_descs (Key BLOB NOT NULL PRIMARY KEY , FillMode INTEGER NOT NULL ,CullMode INTEGER NOT NULL ,FrontCounterClockwise INTEGER NOT NULL ,DepthBias REAL NOT NULL ,DepthBiasClamp REAL NOT NULL ,SlopeScaledDepthBias REAL NOT NULL ,DepthClipEnable INTEGER NOT NULL ,LineRasterizationMode INTEGER NOT NULL ,ForcedSampleCount INTEGER NOT NULL ,ConservativeRaster INTEGER NOT NULL );
CREATE TABLE view_instancing_descs (Key BLOB NOT NULL PRIMARY KEY , ViewInstanceCount INTEGER NOT NULL ,RenderFlags INTEGER NOT NULL ,ViewportArrayIndex0 INTEGER  ,RenderTargetArrayIndex0 INTEGER  ,ViewportArrayIndex1 INTEGER  ,RenderTargetArrayIndex1 INTEGER  ,ViewportArrayIndex2 INTEGER  ,RenderTargetArrayIndex2 INTEGER  ,ViewportArrayIndex3 INTEGER  ,RenderTargetArrayIndex3 INTEGER  );
CREATE TABLE so_declarations (Key BLOB NOT NULL PRIMARY KEY , Stream INTEGER NOT NULL ,SemanticName TEXT NOT NULL ,SemanticIndex INTEGER NOT NULL ,StartComponent INTEGER NOT NULL ,ComponentCount INTEGER NOT NULL ,OutputSlot INTEGER NOT NULL );
CREATE TABLE stream_out_descs (Key BLOB NOT NULL PRIMARY KEY , BufferStride0 INTEGER NOT NULL ,BufferStride1 INTEGER NOT NULL ,BufferStride2 INTEGER NOT NULL ,BufferStride3 INTEGER NOT NULL ,NumStrides INTEGER NOT NULL ,RasterizedStream INTEGER NOT NULL );
CREATE TABLE rt_hit_groups (Key BLOB NOT NULL PRIMARY KEY , HitGroupExport TEXT NOT NULL ,Type INTEGER NOT NULL ,AnyHitShaderImport TEXT  ,ClosestHitShaderImport TEXT  ,IntersectionShaderImport TEXT  );
CREATE TABLE rt_shader_config (Key BLOB NOT NULL PRIMARY KEY , MaxPayloadSizeInBytes INTEGER NOT NULL ,MaxAttributeSizeInBytes INTEGER NOT NULL );
CREATE TABLE rt_pipeline_config (Key BLOB NOT NULL PRIMARY KEY , MaxTraceRecursionDepth INTEGER NOT NULL ,Flags INTEGER NOT NULL );
CREATE TABLE dxil_subobject_to_exports_associations (Key BLOB NOT NULL PRIMARY KEY , SubobjectToAssociate TEXT NOT NULL );
CREATE TABLE subobject_to_exports_associations (Key BLOB NOT NULL PRIMARY KEY , SubobjectType INTEGER NOT NULL ,SubobjectKey BLOB NOT NULL );
CREATE TABLE generic_programs (Key BLOB NOT NULL PRIMARY KEY , ProgramName TEXT  ,InputLayout BLOB  ,DepthStencilDesc BLOB  ,RenderTargetFormats BLOB  ,BlendDesc BLOB  ,RasterizerDesc BLOB  ,ViewInstancingDesc BLOB  ,StreamOutDesc BLOB  ,SampleDesc_Count INTEGER  ,SampleDesc_Quality INTEGER  ,SampleMask INTEGER  ,IBStripCutValue INTEGER  ,PrimitiveTopology INTEGER  ,DSVFormat INTEGER  ,NodeMask INTEGER  ,Flags INTEGER  ,FOREIGN KEY(DepthStencilDesc) REFERENCES depth_stencil_descs(Key),FOREIGN KEY(RenderTargetFormats) REFERENCES render_target_formats(Key),FOREIGN KEY(BlendDesc) REFERENCES blend_descs(Key),FOREIGN KEY(RasterizerDesc) REFERENCES rasterizer_descs(Key),FOREIGN KEY(ViewInstancingDesc) REFERENCES view_instancing_descs(Key),FOREIGN KEY(StreamOutDesc) REFERENCES stream_out_descs(Key));
CREATE TABLE pipeline_states (Key BLOB NOT NULL PRIMARY KEY , RootSignature BLOB  ,InputLayout BLOB  ,ByteCode_VS BLOB  ,ByteCode_PS BLOB  ,ByteCode_HS BLOB  ,ByteCode_DS BLOB  ,ByteCode_GS BLOB  ,ByteCode_AS BLOB  ,ByteCode_MS BLOB  ,ByteCode_CS BLOB  ,DepthStencilDesc BLOB  ,RenderTargetFormats BLOB  ,BlendDesc BLOB  ,RasterizerDesc BLOB  ,ViewInstancingDesc BLOB  ,StreamOutDesc BLOB  ,SampleDesc_Count INTEGER  ,SampleDesc_Quality INTEGER  ,SampleMask INTEGER  ,IBStripCutValue INTEGER  ,PrimitiveTopology INTEGER  ,DSVFormat INTEGER  ,NodeMask INTEGER  ,Flags INTEGER  ,FOREIGN KEY(RootSignature) REFERENCES root_signatures(Key),FOREIGN KEY(ByteCode_VS) REFERENCES shader_bytecode(Key),FOREIGN KEY(ByteCode_PS) REFERENCES shader_bytecode(Key),FOREIGN KEY(ByteCode_HS) REFERENCES shader_bytecode(Key),FOREIGN KEY(ByteCode_DS) REFERENCES shader_bytecode(Key),FOREIGN KEY(ByteCode_GS) REFERENCES shader_bytecode(Key),FOREIGN KEY(ByteCode_AS) REFERENCES shader_bytecode(Key),FOREIGN KEY(ByteCode_MS) REFERENCES shader_bytecode(Key),FOREIGN KEY(ByteCode_CS) REFERENCES shader_bytecode(Key),FOREIGN KEY(DepthStencilDesc) REFERENCES depth_stencil_descs(Key),FOREIGN KEY(RenderTargetFormats) REFERENCES render_target_formats(Key),FOREIGN KEY(BlendDesc) REFERENCES blend_descs(Key),FOREIGN KEY(RasterizerDesc) REFERENCES rasterizer_descs(Key),FOREIGN KEY(ViewInstancingDesc) REFERENCES view_instancing_descs(Key),FOREIGN KEY(StreamOutDesc) REFERENCES stream_out_descs(Key));
CREATE TABLE work_graphs (Key BLOB NOT NULL PRIMARY KEY , ProgramName TEXT NOT NULL ,Flags INTEGER NOT NULL );
CREATE TABLE node_ids (Key BLOB NOT NULL PRIMARY KEY , Name TEXT NOT NULL ,ArrayIndex INTEGER NOT NULL );
CREATE TABLE node_output_overrides (Key BLOB NOT NULL PRIMARY KEY , OutputIndex INTEGER NOT NULL ,NewName BLOB  ,AllowSparseNodes INTEGER  ,MaxRecords INTEGER  ,MaxRecordsSharedWithOutputIndex INTEGER  ,FOREIGN KEY(NewName) REFERENCES node_ids(Key));
CREATE TABLE shader_nodes (Key BLOB NOT NULL PRIMARY KEY , ShaderOrProgram TEXT NOT NULL ,NodeType INTEGER NOT NULL ,OverridesType INTEGER NOT NULL ,LocalRootArgumentsTableIndex INTEGER  ,ProgramEntry INTEGER  ,NewName BLOB  ,ShareInputOf BLOB  ,DispatchGridX INTEGER  ,DispatchGridY INTEGER  ,DispatchGridZ INTEGER  ,MaxDispatchGridX INTEGER  ,MaxDispatchGridY INTEGER  ,MaxDispatchGridZ INTEGER  ,MaxInputRecordsPerGraphEntryRecord_RecordCount INTEGER  ,MaxInputRecordsPerGraphEntryRecord_bCountSharedAcrossNodeArray INTEGER  ,FOREIGN KEY(NewName) REFERENCES node_ids(Key),FOREIGN KEY(ShareInputOf) REFERENCES node_ids(Key));
CREATE TABLE input_layout_to_input_element_associations (InputLayoutKey BLOB NOT NULL ,InputElementKey BLOB NOT NULL ,FOREIGN KEY(InputElementKey) REFERENCES input_element_descs(Key),UNIQUE(InputLayoutKey, InputElementKey));
CREATE TABLE stream_output_desc_to_stream_output_decl_associations (StreamOutDescKey BLOB NOT NULL ,StreamOutDeclKey BLOB NOT NULL ,FOREIGN KEY(StreamOutDescKey) REFERENCES stream_out_descs(Key),FOREIGN KEY(StreamOutDeclKey) REFERENCES so_declarations(Key),UNIQUE(StreamOutDescKey, StreamOutDeclKey));
CREATE TABLE so_to_global_rs_associations (StateObjectKey BLOB NOT NULL ,RootSignatureKey BLOB NOT NULL ,FOREIGN KEY(StateObjectKey) REFERENCES state_objects(Key),FOREIGN KEY(RootSignatureKey) REFERENCES root_signatures(Key),UNIQUE(StateObjectKey, RootSignatureKey));
CREATE TABLE so_to_local_rs_associations (StateObjectKey BLOB NOT NULL ,RootSignatureKey BLOB NOT NULL ,FOREIGN KEY(StateObjectKey) REFERENCES state_objects(Key),FOREIGN KEY(RootSignatureKey) REFERENCES root_signatures(Key),UNIQUE(StateObjectKey, RootSignatureKey));
CREATE TABLE so_to_dxil_lib_associations (StateObjectKey BLOB NOT NULL ,DxilLibKey BLOB NOT NULL ,ExportKey BLOB  ,FOREIGN KEY(StateObjectKey) REFERENCES state_objects(Key),FOREIGN KEY(DxilLibKey) REFERENCES shader_bytecode(Key),FOREIGN KEY(ExportKey) REFERENCES exports(Key),UNIQUE(StateObjectKey, DxilLibKey, ExportKey));
CREATE UNIQUE INDEX so_to_dxil_lib_associations_partial_index ON so_to_dxil_lib_associations(StateObjectKey,DxilLibKey) WHERE ExportKey IS NULL;
CREATE TABLE so_to_existing_so_associations (StateObjectKey BLOB NOT NULL ,ExistingStateObjectKey BLOB NOT NULL ,ExportKey BLOB  ,FOREIGN KEY(StateObjectKey) REFERENCES state_objects(Key),FOREIGN KEY(ExistingStateObjectKey) REFERENCES state_objects(Key),FOREIGN KEY(ExportKey) REFERENCES exports(Key),UNIQUE(StateObjectKey, ExistingStateObjectKey, ExportKey));
CREATE UNIQUE INDEX so_to_existing_so_associations_partial_index ON so_to_existing_so_associations(StateObjectKey,ExistingStateObjectKey) WHERE ExportKey IS NULL;
CREATE TABLE so_to_hit_group_associations (StateObjectKey BLOB NOT NULL ,HitGroupKey BLOB NOT NULL ,FOREIGN KEY(StateObjectKey) REFERENCES state_objects(Key),FOREIGN KEY(HitGroupKey) REFERENCES rt_hit_groups(Key),UNIQUE(StateObjectKey, HitGroupKey));
CREATE TABLE so_to_rt_shader_config_associations (StateObjectKey BLOB NOT NULL ,ShaderConfigKey BLOB NOT NULL ,FOREIGN KEY(StateObjectKey) REFERENCES state_objects(Key),FOREIGN KEY(ShaderConfigKey) REFERENCES rt_shader_config(Key),UNIQUE(StateObjectKey, ShaderConfigKey));
CREATE TABLE so_to_rt_pipeline_config_associations (StateObjectKey BLOB NOT NULL ,PipelineConfigKey BLOB NOT NULL ,FOREIGN KEY(StateObjectKey) REFERENCES state_objects(Key),FOREIGN KEY(PipelineConfigKey) REFERENCES rt_pipeline_config(Key),UNIQUE(StateObjectKey, PipelineConfigKey));
CREATE TABLE so_to_dxil_subobject_to_exports_associations (StateObjectKey BLOB NOT NULL ,DxilSubobjectToExportsAssociationKey BLOB NOT NULL ,FOREIGN KEY(StateObjectKey) REFERENCES state_objects(Key),FOREIGN KEY(DxilSubobjectToExportsAssociationKey) REFERENCES dxil_subobject_to_exports_associations(Key),UNIQUE(StateObjectKey, DxilSubobjectToExportsAssociationKey));
CREATE TABLE so_to_subobject_to_exports_associations (StateObjectKey BLOB NOT NULL ,SubobjectToExportsAssociationKey BLOB NOT NULL ,FOREIGN KEY(StateObjectKey) REFERENCES state_objects(Key),FOREIGN KEY(SubobjectToExportsAssociationKey) REFERENCES subobject_to_exports_associations(Key),UNIQUE(StateObjectKey, SubobjectToExportsAssociationKey));
CREATE TABLE so_to_generic_program_associations (StateObjectKey BLOB NOT NULL ,GenericProgramKey BLOB NOT NULL ,FOREIGN KEY(StateObjectKey) REFERENCES state_objects(Key),FOREIGN KEY(GenericProgramKey) REFERENCES generic_programs(Key),UNIQUE(StateObjectKey, GenericProgramKey));
CREATE TABLE so_to_work_graph_associations (StateObjectKey BLOB NOT NULL ,WorkGraphKey BLOB NOT NULL ,FOREIGN KEY(StateObjectKey) REFERENCES state_objects(Key),FOREIGN KEY(WorkGraphKey) REFERENCES work_graphs(Key),UNIQUE(StateObjectKey, WorkGraphKey));
CREATE TABLE work_graph_to_entrypoint_node_id_associations (WorkGraphKey BLOB NOT NULL ,NodeIDKey BLOB NOT NULL ,FOREIGN KEY(WorkGraphKey) REFERENCES work_graphs(Key),FOREIGN KEY(NodeIDKey) REFERENCES node_ids(Key),UNIQUE(WorkGraphKey, NodeIDKey));
CREATE TABLE workgraph_node_to_node_output_overrides_associations (WorkGraphNodeKey BLOB NOT NULL ,NodeOutputOverridesKey BLOB NOT NULL ,FOREIGN KEY(WorkGraphNodeKey) REFERENCES shader_nodes(Key),FOREIGN KEY(NodeOutputOverridesKey) REFERENCES node_output_overrides(Key),UNIQUE(WorkGraphNodeKey, NodeOutputOverridesKey));
CREATE TABLE work_graph_to_work_graph_node_associations (WorkGraphKey BLOB NOT NULL ,WorkGraphNodeKey BLOB NOT NULL ,FOREIGN KEY(WorkGraphKey) REFERENCES work_graphs(Key),FOREIGN KEY(WorkGraphNodeKey) REFERENCES shader_nodes(Key),UNIQUE(WorkGraphKey, WorkGraphNodeKey));
CREATE TABLE string_associations (OwningTableKey BLOB  ,Value TEXT NOT NULL ,UNIQUE(OwningTableKey, Value));
CREATE UNIQUE INDEX string_associations_partial_index ON string_associations(Value) WHERE OwningTableKey IS NULL;
CREATE TABLE groups (Key BLOB NOT NULL PRIMARY KEY , Version INTEGER NOT NULL ,PSOKey BLOB  ,SOKey BLOB  ,FOREIGN KEY(PSOKey) REFERENCES pipeline_states(Key),FOREIGN KEY(SOKey) REFERENCES state_objects(Key));
CREATE TABLE app_id (id INTEGER NOT NULL PRIMARY KEY , exe TEXT NOT NULL ,app_name TEXT NOT NULL ,engine_name TEXT  ,app_version INTEGER NOT NULL ,engine_version INTEGER NOT NULL )
```