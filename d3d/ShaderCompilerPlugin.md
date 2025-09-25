# Advanced Shader Delivery - Shader Compiler Plugin

- [Advanced Shader Delivery - Shader Compiler Plugin](#advanced-shader-delivery---shader-compiler-plugin)
  - [Introduction](#introduction)
  - [Design](#design)
    - [API Sample](#api-sample)
    - [Compiler Availability](#compiler-availability)
    - [IHV Compiler Plugin](#ihv-compiler-plugin)
      - [Driver Independent Plugin](#driver-independent-plugin)
      - [Plugin DDI Versioning](#plugin-ddi-versioning)
      - [Shared Concepts with Runtime](#shared-concepts-with-runtime)
      - [Package Version](#package-version)
      - [Adapter Families](#adapter-families)
      - [Adapter Family Compiler Version](#adapter-family-compiler-version)
      - [Adapter Family ABI Version](#adapter-family-abi-version)
      - [Application Profile Version](#application-profile-version)
      - [Capability Checks](#capability-checks)
      - [IHV Dependent Object Subdivision](#ihv-dependent-object-subdivision)
      - [Example Cache Update Flow](#example-cache-update-flow)
    - [Microsoft Compiler Runtime](#microsoft-compiler-runtime)
    - [Storing Compiled Objects](#storing-compiled-objects)
    - [Microsoft Command Line Tool](#microsoft-command-line-tool)
    - [Offline Compile AddToStateObject](#offline-compile-addtostateobject)
    - [Application Identity Metadata](#application-identity-metadata)
  - [Scenarios](#scenarios)
    - [Cloud Service Compilation](#cloud-service-compilation)
    - [Local Independent Software Vendor Compilation](#local-independent-software-vendor-compilation)
    - [PIX Crash/Hang Dumps](#pix-crashhang-dumps)
    - [Shader Explorer Shader Iteration](#shader-explorer-shader-iteration)
  - [Plugin DDI](#plugin-ddi)
    - [Open/Version Compiler DDI](#openversion-compiler-ddi)
      - [Handle: D3D12DDI\_HCOMPILERDDI](#handle-d3d12ddi_hcompilerddi)
      - [Callback Handle: D3D12DDI\_HRTCOMPILERDDI](#callback-handle-d3d12ddi_hrtcompilerddi)
      - [Struct: D3D12DDIARG\_COMPILER\_OPEN\_DDI](#struct-d3d12ddiarg_compiler_open_ddi)
      - [Function: PFND3D12DDI\_COMPILER\_OPEN\_DDI](#function-pfnd3d12ddi_compiler_open_ddi)
    - [Versioning and Function Retrieval](#versioning-and-function-retrieval)
      - [Struct: D3D12DDI\_COMPILER\_DDI\_FUNCS](#struct-d3d12ddi_compiler_ddi_funcs)
      - [Function: PFND3D12DDI\_COMPILER\_DESTROY\_DDI](#function-pfnd3d12ddi_compiler_destroy_ddi)
      - [Function: PFND3D12DDI\_COMPILER\_GET\_SUPPORTED\_VERSIONS](#function-pfnd3d12ddi_compiler_get_supported_versions)
      - [Function: PFND3D12DDI\_COMPILER\_SET\_SELECTED\_VERSION](#function-pfnd3d12ddi_compiler_set_selected_version)
      - [Enumeration: D3D12DDI\_COMPILER\_TABLE\_TYPE](#enumeration-d3d12ddi_compiler_table_type)
      - [Function: PFND3D12DDI\_COMPILER\_FILL\_DDI\_TABLE](#function-pfnd3d12ddi_compiler_fill_ddi_table)
      - [Enumeration: D3D12DDI\_COMPILER\_CALLBACK\_TABLE\_TYPE](#enumeration-d3d12ddi_compiler_callback_table_type)
      - [Function: PFND3D12DDI\_COMPILER\_SET\_CALLBACK\_DDI\_TABLE](#function-pfnd3d12ddi_compiler_set_callback_ddi_table)
    - [Application and Compiler Descs](#application-and-compiler-descs)
      - [Struct: D3D12DDI\_VERSION\_NUMBER](#struct-d3d12ddi_version_number)
      - [Struct: D3D12DDI\_APPLICATION\_DESC](#struct-d3d12ddi_application_desc)
      - [Struct: D3D12DDI\_SHADERCACHE\_ABI\_SUPPORT\_DATA](#struct-d3d12ddi_shadercache_abi_support_data)
      - [Struct: D3D12DDI\_COMPILER\_ADAPTER\_FAMILY](#struct-d3d12ddi_compiler_adapter_family)
      - [Struct: D3D12DDI\_COMPILER\_TARGET](#struct-d3d12ddi_compiler_target)
    - [Checking Capabilities](#checking-capabilities)
      - [Struct: D3D12DDI\_COMPILER\_CAPABILITIES\_FUNCS](#struct-d3d12ddi_compiler_capabilities_funcs)
      - [Function: PFND3D12DDI\_COMPILER\_GET\_CAPS](#function-pfnd3d12ddi_compiler_get_caps)
      - [Function: PFND3D12DDI\_COMPILER\_ENUMERATE\_ADAPTER\_FAMILIES](#function-pfnd3d12ddi_compiler_enumerate_adapter_families)
      - [Function: PFND3D12DDI\_COMPILER\_GET\_ADAPTER\_FAMILY\_ABI\_VERSIONS](#function-pfnd3d12ddi_compiler_get_adapter_family_abi_versions)
      - [Function: PFND3D12DDI\_COMPILER\_GET\_COMPILER\_VERSION](#function-pfnd3d12ddi_compiler_get_compiler_version)
      - [Function: PFND3D12DDI\_COMPILER\_GET\_APPLICATION\_PROFILE\_VERSION](#function-pfnd3d12ddi_compiler_get_application_profile_version)
      - [Function: PFND3D12DDI\_COMPILER\_CHECK\_FORMAT\_SUPPORT](#function-pfnd3d12ddi_compiler_check_format_support)
      - [Function: PFND3D12DDI\_COMPILER\_CHECK\_MULTISAMPLE\_QUALITY\_LEVELS](#function-pfnd3d12ddi_compiler_check_multisample_quality_levels)
    - [Cache Session Callbacks](#cache-session-callbacks)
      - [Callback Handle: D3D12DDI\_HRTCOMPILERCACHESESSION](#callback-handle-d3d12ddi_hrtcompilercachesession)
      - [Enumeration: D3D12DDI\_COMPILER\_CACHE\_VALUE\_TYPE](#enumeration-d3d12ddi_compiler_cache_value_type)
      - [Enumeration: D3D12DDI\_COMPILER\_VALUE\_TYPE\_FLAGS](#enumeration-d3d12ddi_compiler_value_type_flags)
      - [Struct: D3D12DDI\_COMPILER\_CACHE\_VALUE\_KEY](#struct-d3d12ddi_compiler_cache_value_key)
      - [Struct: D3D12DDI\_COMPILER\_CACHE\_VALUE](#struct-d3d12ddi_compiler_cache_value)
      - [Struct: D3D12DDI\_COMPILER\_CACHE\_TYPED\_VALUE](#struct-d3d12ddi_compiler_cache_typed_value)
      - [Struct: D3D12DDI\_COMPILER\_CACHE\_CONST\_VALUE](#struct-d3d12ddi_compiler_cache_const_value)
      - [Struct: D3D12DDI\_COMPILER\_CACHE\_TYPED\_CONST\_VALUE](#struct-d3d12ddi_compiler_cache_typed_const_value)
      - [Struct: D3D12DDI\_COMPILER\_CACHE\_CALLBACKS](#struct-d3d12ddi_compiler_cache_callbacks)
      - [Callback Function: PFND3D12DDI\_COMPILER\_CACHE\_FIND\_VALUE\_CB](#callback-function-pfnd3d12ddi_compiler_cache_find_value_cb)
      - [Callback Function: PFND3D12DDI\_COMPILER\_CACHE\_STORE\_VALUE\_CB](#callback-function-pfnd3d12ddi_compiler_cache_store_value_cb)
      - [Callback Function: PFND3D12DDI\_COMPILER\_CACHE\_SET\_OBJECT\_VALUE\_KEYS\_CB](#callback-function-pfnd3d12ddi_compiler_cache_set_object_value_keys_cb)
    - [Compiling State Objects](#compiling-state-objects)
      - [Handle: D3D12DDI\_HCOMPILER](#handle-d3d12ddi_hcompiler)
      - [Callback Handle: D3D12DDI\_HRTCOMPILER](#callback-handle-d3d12ddi_hrtcompiler)
      - [Handle: D3D12DDI\_HCOMPILERSTATEOBJECT](#handle-d3d12ddi_hcompilerstateobject)
      - [Struct: D3D12DDI\_COMPILER\_FUNCS](#struct-d3d12ddi_compiler_funcs)
      - [Function: PFND3D12DDI\_COMPILER\_CALC\_PRIVATE\_COMPILER\_SIZE](#function-pfnd3d12ddi_compiler_calc_private_compiler_size)
      - [Function: PFND3D12DDI\_COMPILER\_CREATE\_COMPILER](#function-pfnd3d12ddi_compiler_create_compiler)
      - [Function: PFND3D12DDI\_COMPILER\_DESTROY\_COMPILER](#function-pfnd3d12ddi_compiler_destroy_compiler)
      - [Function: PFND3D12DDI\_COMPILER\_COMPILE\_PIPELINE\_STATE](#function-pfnd3d12ddi_compiler_compile_pipeline_state)
      - [Function: PFND3D12DDI\_COMPILER\_CALC\_PRIVATE\_STATE\_OBJECT\_SIZE](#function-pfnd3d12ddi_compiler_calc_private_state_object_size)
      - [Function: PFND3D12DDI\_COMPILER\_COMPILE\_CREATE\_STATE\_OBJECT](#function-pfnd3d12ddi_compiler_compile_create_state_object)
      - [Function: PFND3D12DDI\_COMPILER\_CALC\_PRIVATE\_ADD\_TO\_STATE\_OBJECT\_SIZE](#function-pfnd3d12ddi_compiler_calc_private_add_to_state_object_size)
      - [Function: PFND3D12DDI\_COMPILER\_COMPILE\_ADD\_TO\_STATE\_OBJECT](#function-pfnd3d12ddi_compiler_compile_add_to_state_object)
      - [Function: PFND3D12DDI\_COMPILER\_DESTROY\_STATE\_OBJECT](#function-pfnd3d12ddi_compiler_destroy_state_object)
  - [Microsoft API](#microsoft-api)
    - [Function: D3D12CreateCompilerFactory](#function-d3d12createcompilerfactory)
    - [Application Descs and Compiler Targets](#application-descs-and-compiler-targets)
    - [Union: D3D12\_VERSION\_NUMBER](#union-d3d12_version_number)
    - [Struct: D3D12\_APPLICATION\_DESC](#struct-d3d12_application_desc)
      - [Struct: D3D12\_ADAPTER\_FAMILY](#struct-d3d12_adapter_family)
      - [Struct: D3D12\_COMPILER\_TARGET](#struct-d3d12_compiler_target)
    - [Struct: D3D12\_COMPILER\_DATABASE\_PATH](#struct-d3d12_compiler_database_path)
    - [Struct: D3D12\_COMPILER\_CACHE\_GROUP\_KEY](#struct-d3d12_compiler_cache_group_key)
    - [Struct: D3D12\_COMPILER\_CACHE\_VALUE\_KEY](#struct-d3d12_compiler_cache_value_key)
    - [Struct: D3D12\_COMPILER\_CACHE\_VALUE](#struct-d3d12_compiler_cache_value)
    - [Struct: D3D12\_COMPILER\_CACHE\_TYPED\_VALUE](#struct-d3d12_compiler_cache_typed_value)
    - [Struct: D3D12\_COMPILER\_CACHE\_CONST\_VALUE](#struct-d3d12_compiler_cache_const_value)
    - [Struct: D3D12\_COMPILER\_CACHE\_TYPED\_CONST\_VALUE](#struct-d3d12_compiler_cache_typed_const_value)
    - [Callback Function: D3D12CompilerCacheSessionAllocationFunc](#callback-function-d3d12compilercachesessionallocationfunc)
    - [Callback Function: D3D12CompilerCacheSessionGroupValueKeysFunc](#callback-function-d3d12compilercachesessiongroupvaluekeysfunc)
    - [Callback Function: D3D12CompilerCacheSessionGroupValuesFunc](#callback-function-d3d12compilercachesessiongroupvaluesfunc)
    - [Interface: ID3D12CompilerFactory](#interface-id3d12compilerfactory)
      - [Method: ID3D12CompilerFactory::EnumerateAdapterFamilies](#method-id3d12compilerfactoryenumerateadapterfamilies)
      - [Method ID3D12CompilerFactory::EnumerateAdapterFamilyABIVersions](#method-id3d12compilerfactoryenumerateadapterfamilyabiversions)
      - [Method ID3D12CompilerFactory::EnumerateAdapterFamilyCompilerVersion](#method-id3d12compilerfactoryenumerateadapterfamilycompilerversion)
      - [Method: ID3D12CompilerFactory::GetApplicationProfileVersion](#method-id3d12compilerfactorygetapplicationprofileversion)
      - [Method ID3D12CompilerFactory::CreateCompilerCacheSession](#method-id3d12compilerfactorycreatecompilercachesession)
      - [Method ID3D12CompilerFactory::CreateCompiler](#method-id3d12compilerfactorycreatecompiler)
    - [Enumeration: D3D12\_COMPILER\_VALUE\_TYPE](#enumeration-d3d12_compiler_value_type)
    - [Enumeration: D3D12\_COMPILER\_VALUE\_TYPE\_FLAGS](#enumeration-d3d12_compiler_value_type_flags)
    - [Interface: ID3D12Compiler](#interface-id3d12compiler)
      - [Method ID3D12Compiler::CompilePipelineState](#method-id3d12compilercompilepipelinestate)
      - [Method ID3D12Compiler::CompileStateObject](#method-id3d12compilercompilestateobject)
      - [Method ID3D12Compiler::CompileAddToStateObject](#method-id3d12compilercompileaddtostateobject)
    - [Interface: ID3D12CompilerCacheSession](#interface-id3d12compilercachesession)
      - [Method: ID3D12CompilerCacheSession::FindGroup](#method-id3d12compilercachesessionfindgroup)
      - [Method: ID3D12CompilerCacheSession::FindGroupValueKeys](#method-id3d12compilercachesessionfindgroupvaluekeys)
      - [Method: ID3D12CompilerCacheSession::FindGroupValues](#method-id3d12compilercachesessionfindgroupvalues)
      - [Method: ID3D12CompilerCacheSession::FindValue](#method-id3d12compilercachesessionfindvalue)
      - [Method: ID3D12CompilerCacheSession::GetApplicationDesc](#method-id3d12compilercachesessiongetapplicationdesc)
      - [Method: ID3D12CompilerCacheSession::GetCompilerTarget](#method-id3d12compilercachesessiongetcompilertarget)
      - [Method: ID3D12CompilerCacheSession::GetValueTypes](#method-id3d12compilercachesessiongetvaluetypes)
      - [Method: ID3D12CompilerCacheSession::StoreValue](#method-id3d12compilercachesessionstorevalue)
      - [ID3D12CompilerCacheSession::StoreGroupValueKeys](#id3d12compilercachesessionstoregroupvaluekeys)
    - [Interface: ID3D12CompilerStateObject](#interface-id3d12compilerstateobject)
  - [Microsoft Compiler EXE](#microsoft-compiler-exe)
    - [Compile](#compile)
    - [Replay](#replay)
    - [List](#list)

## Introduction

As part of D3D12 PC game development, a game developer authors a number of custom programs that run on the Graphics Processing Unit at different stages, known as shaders.  Several of these shaders are combined with other state in D3D12 objects known as Pipeline State Objects(PSOs) or State Objects (SOs).  Due to the variety of hardware in the GPU space, the pace of innovation, and optimization that occurs after game titles ship, these programs are compiled in an vendor and GPU dependent way.  The compilation has traditionally occurred at runtime by the Independent Hardware Vendor(IHV) driver when the game is running.  This compilation is expensive and the count of unique PSOs and SOs combinations is ever increasing as titles become more complicated and graphics rich, reaching numbers in the hundred thousands today.  Existing mitigation strategies for this cost are not sufficient causing significant performance problems for gamers.  

As part of solving this problem, we need a means to compile PSOs and SOs outside of the game runtime. Today, Independent Hardware Vendors(IHV) compilers ship with the IHVs' DirectX drivers which traditionally only install when the vendor's display adapter is present. To support cloud compilation, IHVs must factor the compiler into a separate component that can run without a vendor's display adapter.

This spec details a DDI for IHVs to supply a compiler plugin dll for compilation of D3D12 Pipeline State Objects and D3D12 State Objects without a physical adapter present.  

This spec also details a Microsoft API for using IHV compiler plugins.

## Design

GPU hardware vendors expose compilers in an [IHV Compiler Plugin](#ihv-compiler-plugin) dll via a [Plugin DDI](#plugin-ddi).

The [Microsoft Compiler Runtime](#microsoft-compiler-runtime) will wrap these plugins with an [API](#microsoft-api) in a new D3D12StateObjectCompiler.dll to expose functionality to Independent Software Vendors(ISVs).  

Microsoft will also ship a [Command Line Tool](#microsoft-command-line-tool) that that reads databases of PSOs and SOs (State Object Databases or SODBs) and leverages the compiler API to produce databases of [compiled objects](#storing-compiled-objects) (Precompiled Shader Databases or PSDBs).

The command line tool or API is used for cloud compilation and available to ISVs for private builds.

### API Sample

This example demonstrates how to compile a Pipeline State Object (PSO) and store it in a Precompiled Shader Database (PSDB) using the State Object Compiler API.

```c++
    //
    // Create the factory
    //

    Microsoft::WRL::ComPtr<ID3D12CompilerFactory> spFactory;
    VERIFY_SUCCEEDED(D3D12CreateCompilerFactory(CompilerPluginDll, IID_PPV_ARGS(&spFactory)));

    //
    // Cache output path and type
    //

    D3D12_COMPILER_VALUE_TYPE_FLAGS compileValues = 
        D3D12_COMPILER_VALUE_TYPE_FLAGS_OBJECT_CODE | D3D12_COMPILER_VALUE_TYPE_FLAGS_METADATA;

    D3D12_COMPILER_DATABASE_PATH databasePath = { compileValues, L"out.psdb" };

    //
    // Target adapter family and ABI
    //

    // Use the first available adapter family.
    UINT AdapterFamilyIndex = 0;

    // Zero targets the latest available ABI version for this adapter family.
    UINT ABIVersion = 0;

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

    //
    // Create the Cache Session and Compiler
    //

    Microsoft::WRL::ComPtr<ID3D12CompilerCacheSession> spCompilerCacheSession;
    VERIFY_SUCCEEDED(spFactory->CreateCompilerCacheSession(
        &databasePath,
        1u, // NumPaths
        &target,
        &applicationDesc,
        IID_PPV_ARGS(&spCompilerCacheSession)
    ));

    Microsoft::WRL::ComPtr<ID3D12Compiler> spCompiler;
    VERIFY_SUCCEEDED(spFactory->CreateCompiler(
        spCompilerCacheSession.Get(),
        IID_PPV_ARGS(&spCompiler)));
    
    //
    // Prepare the PSO arguments.
    //

    const D3D12_INPUT_ELEMENT_DESC DefaultILDescs[1] =
    {
        { "POS", 0, DXGI_FORMAT_R32G32B32A32_FLOAT, 0, 0, D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 }
    };

    const D3D12_INPUT_LAYOUT_DESC DefaultIL = { DefaultILDescs, _countof(DefaultILDescs) };

    CD3DX12_DESCRIPTOR_RANGE1 DescRange[] =
    {
        {D3D12_DESCRIPTOR_RANGE_TYPE_SRV, 1, 0},    // t0
        {D3D12_DESCRIPTOR_RANGE_TYPE_UAV, 2, 0},    // u0-u1
        {D3D12_DESCRIPTOR_RANGE_TYPE_SAMPLER, 2, 0} // s0-s1
    };
    
    CD3DX12_ROOT_PARAMETER1 rootParameters[_countof(DescRange)];
    
    for (UINT i = 0; i < _countof(rootParameters); ++i)
    {
        rootParameters[i].InitAsDescriptorTable(1u, &DescRange[i], D3D12_SHADER_VISIBILITY_ALL);
    }
    
    CD3DX12_VERSIONED_ROOT_SIGNATURE_DESC rootSignatureDesc(_countof(rootParameters), rootParameters, 0, nullptr,
        D3D12_ROOT_SIGNATURE_FLAG_ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT | D3D12_ROOT_SIGNATURE_FLAG_ALLOW_STREAM_OUTPUT);
    
    Microsoft::WRL::ComPtr <ID3DBlob> signature;
    Microsoft::WRL::ComPtr <ID3DBlob> error;
    VERIFY_SUCCEEDED(D3D12CompilerSerializeVersionedRootSignature(&rootSignatureDesc, &signature, &error));
    
    D3D12_SERIALIZED_ROOT_SIGNATURE_DESC serializedRootSignatureDesc = {};
    serializedRootSignatureDesc.pSerializedBlob = signature->GetBufferPointer();
    serializedRootSignatureDesc.SerializedBlobSizeInBytes = signature->GetBufferSize();
    
    struct PSO_STREAM
    {
        CD3DX12_PIPELINE_STATE_STREAM_PRIMITIVE_TOPOLOGY PrimitiveTopologyType;
        CD3DX12_PIPELINE_STATE_STREAM_INPUT_LAYOUT InputLayout;
        CD3DX12_PIPELINE_STATE_STREAM_VS VS;
        CD3DX12_PIPELINE_STATE_STREAM_PS PS;
        CD3DX12_PIPELINE_STATE_STREAM_SERIALIZED_ROOT_SIGNATURE RootSigDesc;
    } PSOStream =
    {
        D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE,
        DefaultIL,
        AssignShaderBytecode(pVS),
        AssignShaderBytecode(pPS),
        CD3DX12_SERIALIZED_ROOT_SIGNATURE_DESC{signature->GetBufferPointer(), signature->GetBufferSize()}
    };

    D3D12_PIPELINE_STATE_STREAM_DESC StreamDesc{ sizeof(PSOStream), &PSOStream };
    
    //
    //  Compile the PSO and store the results with the cache session.
    //

    const UINT groupVersion = 1u;
    const UINT keySize = static_cast<UINT>(strlen(pGroupName) + 1u);
    D3D12_COMPILER_CACHE_GROUP_KEY groupKey = { pGroupName, keySize };
    VERIFY_SUCCEEDED(spCompiler->CompilePipelineState(&groupKey, groupVersion, compileValues, &StreamDesc));
```

### Compiler Availability

IHVs should ship their compilers via their websites in a fashion similar to how drivers are shipped so it can be publicly downloaded by ISVs.  Plugins are also direct submitted to the compiler service.  Submitting compilers before driver release allows time for compilation before they are needed on client systems.
Microsoft makes the compiler API and command line tool available in a fashion similar to how the DirectX Agility SDK is shipped so it can be publicly downloaded.

### IHV Compiler Plugin

The State Object Compiler runtime supplies a Compiler Plugin DDI that IHVs implement to provide Pipeline State Object and State Object compilation.

#### Driver Independent Plugin

The Plugin DDI is separate from the D3D12 Usermode DDI to support factoring compilers out of drivers into separate components:

- Compiler plugins must be usable without a hardware adapter present to support cloud compilation
- Compilers have historically been tightly coupled with D3D Usermode drivers and may not currently have a firm versioning boundary between the two.  It hasn't been necessary to understand if a driver change specifically impacts compiled State Objects.  As a result, any driver revision results in invalidated shader caches.  Drivers can be updated as frequently as every 2-3 weeks which can represent a lot of cost in a cloud delivered shader cache solution. The intent is to evolve compilers toward being an independent versioned component where compiled output changes are understood and decouple driver update cadence from compiler cadence to avoid invalidating shaders at this rate.

To facilitate development, nothing will prevent implementing the plugin DDI with the usermode DDI, but it must not require being installed or having an adapter present.

#### Plugin DDI Versioning

The compiler plugin DDI is independently versioned from the D3D12 Usermode DDI, but with a similar scheme.  This allows for compiler specific changes to not impact the D3D12 Runtime development.  It will consist of 4 16bit parts packed into a UINT64 number:

MAJOR.MINOR.BUILD.REVISION

```c++
PLUGIN_INTERFACE_VERSION = (MAJOR << 16) | MINOR
PLUGIN_DDI_VERSION = (((UINT64)PLUGIN_INTERFACE_VERSION) << 32) | ((UINT64)((BUILD << 16) | REVISION))
```

The plugin reports the list of compiler plugin versions it supports.  The compiler runtime selects one of these and reports that version to the driver as the version that is used.

#### Shared Concepts with Runtime

The State Object Compiler shares the following concepts with the D3D12 runtime:

- Pipeline State Object Descriptions
- State Object Descriptions
- Some capability checks impacting the above.

New changes to these concepts must be first introduced in the D3D12 runtime.  Each Compiler DDI version has exactly one usermode DDI version associated with it at design time to define which version of these shared concepts apply.  For clarity, the compiler runtime will set this version to the driver along with the plugin version chosen.  Plugins must only report plugin DDI versions when they can support the associated Usermode DDI version.  The compiler plugin must introduce a new plugin DDI version associated the Usermode DDI to expose it.

#### Package Version

A version number that updates anytime anything in the compiler package changes, including when compiler versions, adapter families, ABI or application profile version changes.  This concept will be shared with any services running the compile and is not represented in API.

#### Adapter Families

IHVs define Adapter Families with a string identifier to indicate a grouping of adapters that can share precompiled shaders.  A plugin indicates a [compiler version](#adapter-family-compiler-version) per adapter family that's rev'd with changes impacting that adapter family such as bug fixes, performance optimizations, etc.  The plugin can also support a range of ABI versions to indicate compatibility with drivers.  A newer compiler version can target an older ABI.

#### Adapter Family Compiler Version

A plugin reports a single compiler version per adapter family that revises with plugin changes that impact that adapter family, such as bug fixes, code generation changes, etc.  The version is a 64 bit encoding of four 16bit values to define a four part version as Major.Minor.Build.Revision.  Application specifc profile settings or application targeted changes should rev the [Application Profile Version](#application-profile-version) instead.

A version change for an adapter family is an indication that compiled output may change.  If it changes in an incompatible way, the ABI version should also be rev'd. The version scheme should indicate the severity of the change.

Major/Minor version change for "must" recompile such as security or major fixes.  Build for "should" recompile such as performance.  Revision for less consequential changes that shouldn't invalidate caches.

#### Adapter Family ABI Version

Adapter families have an ABI version that can rev when there are breaking changes.  IHVs assign each adapter to a family and report which family an adapter belongs to with a supported ABI range from the Usermode DDI.  IHVs also enumerate which ABI Versions are supported by an adapter family.

This scheme also allows for deprecating support for some of the adapters in an adapter family by rev'ing the ABI version and changing the adapter family association.

#### Application Profile Version

 Drivers often have application specific profiles for optimization or targeted bug fixes.  If settings for a specific app or a few apps are changed, that can be communicated without versioning the compiler and impacting the cache for all applications.

#### Capability Checks

The State Object Compiler queries certain caps to facilitate processing API state object descriptions to DDI descriptions.  State object arguments and other parameters re-use DDI structures to support common implementation between compilers and drivers.  The Usermode DDI version associated with the State Object Plugin DDI version dictates which version of these structures and behavior to use.

#### IHV Dependent Object Subdivision

The compiler plugin may sub-divide DDI objects (PSOs, SOs, and Partial SOs) in an IHV dependent way to support deduplication and multiple values may be stored per compile operation.  The IHV plugin is responsible for generating value keys from the inputs that contribute to the compiled output and other internal data. The compiler may also checks for previously compiled duplicates.  For applications using existing APIs, the driver receives the full object desc as before, and derives the same keys for looking up all values via shader cache callbacks.  For applications using new precompiled cache object creation APIs, the application saves memory by not supplying the full object desc and instead supplies object identifiers.  The runtime provides the list of keys and values associated with the object to the driver during object creation.  To realize this memory savings, driver key generation is expected to reduce desc in space saving ways such as replacing DXIL blobs with a hash within the generated key.  Additionally, driver has a callback to lookup the original object desc if it is needed, but must not use this every time or it defeats this memory savings.

Stored values in cache sessions may be directly compared with previous compiler version output, adapter families considered to be similar in some fashion, etc. for further deduplication.  Compilers should refrain from storing additional data in the same value buffer that causes comparison failure when compiled binaries are otherwise identical.  Compilers can instead store compiler metadata for each compiler output for this type of data instead.  For example, storing compiler version or application version information that produced a binary with the value will cause comparison to fail even if they are otherwise identical.

#### Example Cache Update Flow

Below is an example of how a client could check for updates to precompiled caches.   Besides checking cache/driver compatibility on the client, the driver ABI version range is used check for compiler updates:

- Client constructs a url to ask "what's the compiler version of latest cache for ABI version X and Adapter Family Y?" by constructing a URL.
- Server responds compiler version Z by just serving a cached file.
- Client checks "is my cache older than Z?"
- If so, client asks "give me cache version Z for Adapter Family Y" by constructing a URL.
- Server responds with a cached file.
- Client registers with the [Shader Cache Registration API](ShaderCacheRegistrationAPI.md).

### Microsoft Compiler Runtime

The Microsoft API is nano-COM and exposes compiling and caching functionality to end users like ISVs and the cloud compilation service.  It allows callers to enumerate and create compilers.  Each compiler exposes API to compile a PSO or SO that take arguments that are similar to the object creation counterparts in the D3D12 runtime.  The implementation validates API state objects and translates them into DDI representations for calling the IHV plugin.  The implementation for performing this validation and translation is shared with the D3D12 runtime.  The runtime calls the plugin with DDI arguments similar to the runtime to compile.  The plugin is expected to decompose this object, compile, and store each compiled object as a value via callbacks to the runtime.  The plugin finally sets the list of values associated with the input object via a callback to the runtime.  The runtime stores this list of values as a value group in the cache session using the group key supplied by the caller during the compile operation.

See the [API Documentation](#microsoft-api) for more information.

### Storing Compiled Objects

The Precompiled Shader Database(PSDB) is implemented as Sqlite3 databases for storage.  The compiler runtime API wraps the database as an ID3D12CompilerCacheSession.

The PSDB Stores:

- Metadata about the target application and adapter family.
- Compiled objects produced by the IHV compiler plugin are stored as values.  A single PSO or SO compilation produces multiple values.
- A value group.  Each SO and PSO compiled has a single value group that maps all of the values associated with the object.  Values may appear in more than one group (For example, if the same shader was part of another PSO or SO).

### Microsoft Command Line Tool

The command line tool is a wrapper around the plugin API.  , exposing the same functionality via command line arguments.

### Offline Compile AddToStateObject

ID3D12Device7::AddToStateObject allows an application developer to incrementally add to an existing state object during game runtime.  

During offline compilation, cpu overhead during compile is much less of an issue, so these incremental additions to a base state object instead could be factored as independent state objects.  However, this may result in higher runtime memory usage than the original extended state objects that may share state, so the compiler API and state object database continues to support both.

### Application Identity Metadata

The Direct3D runtime and drivers currently match metadata about the process that has loaded their respective dlls, such as executable name, parent directory, etc. to determine which application is running.  The Direct3D runtime does this to determine default adapter preference in systems with multiple GPUs and disable features that cause compatibility issues with games.  Drivers use this information to enable targeted optimizations and fixes.  However, offline compilers are not run in the the applications process to determine this information.  To maintain this capability in an offline compiled world, game store services are expected to supply this information when submitting titles and their SODBs for compilation, and also supply this same information when registering applications.

When compiling offline, the metadata passed to the store is shared with the compiler.  When a title is run, it acquires this information from the [Shader Cache Registration API](ShaderCacheRegistrationAPI.md) and shares it with the driver.

Matching Application information must be stored in each of the applications SODBs.  If capturing the PSOs or SOs of an application, this information can be specified with d3dconfig when enabling API capture.  It can also be specified when explicitly generating an SODB with `ID3D12StateObjectDatabase::StoreApplicationInfo` (spec to follow).

## Scenarios

### Cloud Service Compilation

This toolchain must support compilation of state objects in a scalable way to enable a cloud service to build shaders for Direct3D12 titles.  This toolchain is part of a broader effort to enable offline compilation and distribution of shader caches.

### Local Independent Software Vendor Compilation

Independent Software Vendors (ISV) need access to the same toolchain that the cloud service uses, so they can develop and test with a subset of GPUs in their own build toolchains during title development.  The Microsoft executable and API is shipped publicly with documentation in a fashion similar to how the DirectX Agility SDK is shipped so it can be publicly downloaded.  IHVs should also make their compiler plugins publicly available.

### PIX Crash/Hang Dumps

Microsoft needs backend debugger PDBs to map crash or hangs that occur in GPU programs to interpret dumps and diagnose issues and share with relevant IHVs for similar purposes. Details of this are out-of-scope for this spec.

### Shader Explorer Shader Iteration

Shader Explorer is a tool that allows users to rapidly iterate on shaders. Users can compile shaders and see gathered performance data such as register usage, etc. and iterate to fine tune their shaders.  To enable this, the backend compiler needs to provide these statistics.  This spec provides the means of collecting that data from backend compilers in an opaque IHV dependent way and will use an IHV plugin to resolve this data into information that can be displayed in Shader Explorer. Details of this are out-of-scope for this spec.

## Plugin DDI

### Open/Version Compiler DDI

These types and functions are used to open the compiler DDI and negotiate versions and retrieve additional function tables.

#### Handle: D3D12DDI_HCOMPILERDDI

```c++
D3D10DDI_H( D3D12DDI_HCOMPILERDDI )
```

A handle to the compiler plugin object created when opening the plugin DDI.  This object negotiates the DDI version.  When this object destroyed, any objects or function tables retrieved from the plugin are no longer used.

#### Callback Handle: D3D12DDI_HRTCOMPILERDDI

```c++
D3D10DDI_HRT(D3D12DDI_HRTCOMPILERDDI)
```

The compiler runtimes object for the DDI.  May be used for future callbacks.

#### Struct: D3D12DDIARG_COMPILER_OPEN_DDI

```c++
typedef struct D3D12DDIARG_COMPILER_OPEN_DDI
{
    D3D12DDI_HRTCOMPILERDDI         hRTCompilerDDI;     // in:  Runtime handle
    D3D12DDI_HCOMPILERDDI           hCompilerDDI;       // out: Plugin handle
    D3D12DDI_COMPILER_DDI_FUNCS*    pDDIFuncs;          // out: Plugin function table
} D3D12DDIARG_COMPILER_OPEN_DDI;
```

Argument structure for opening the DDI. See [PFND3D12DDI_COMPILER_OPEN_DDI](#function-pfnd3d12ddi_compiler_open_ddi).

**Members**

*hRTCompilerDDI*

The compiler runtime object handle.

*hCompilerDDI*

The compiler plugin's object handle.  This is allocated by plugin during PFND3D12DDI_COMPILER_OPEN_DDI.

*pDDIFuncs*

Functions for version negotiation and retrieving additional tables.  See [D3D12DDI_COMPILER_DDI_FUNCS](#struct-d3d12ddiarg_compiler_open_ddi)

#### Function: PFND3D12DDI_COMPILER_OPEN_DDI

The initial entry point for a compiler plugin dll.  IHVs export this from plugin DLLs as "D3D12OpenCompilerDDI".

Opens the compiler DDI and retrieves the initial DDI table for version negotiation and further DDI table retrieval.

```c++
typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_OPEN_DDI)(
    _Inout_ D3D12DDIARG_COMPILER_OPEN_DDI* pOpenDDIArg
    );
```

**Parameters**

*pOpenDDIArg*

Open DDI Args.  See [D3D12ARG_COMPILER_OPEN_DDI](#struct-d3d12ddiarg_compiler_open_ddi).

### Versioning and Function Retrieval

A basic set of functions is retrieved during opening the compiler plugin DDI for version negotiation and retrieving further function tables.

#### Struct: D3D12DDI_COMPILER_DDI_FUNCS

```c++
typedef struct D3D12DDI_COMPILER_DDI_FUNCS
{
    PFND3D12DDI_COMPILER_DESTROY_COMPILER_DDI               pfnDestroyCompilerDDI;
    PFND3D12DDI_COMPILER_GET_SUPPORTED_VERSIONS             pfnGetSupportedVersions;
    PFND3D12DDI_COMPILER_SET_SELECTED_VERSION               pfnSetSelectedVersion;
    PFND3D12DDI_COMPILER_FILL_DDI_TABLE                     pfnFillDDITable;    
    PFND3D12DDI_COMPILER_SET_CALLBACK_DDI_TABLE             pfnSetCallbackDDITable;
} D3D12DDI_COMPILER_DDI_FUNCS;
```

The function table retrieved during plugin DDI open.  Allows for version negotiation and retrieving further DDI tables.  

#### Function: PFND3D12DDI_COMPILER_DESTROY_DDI

```c++
typedef VOID (APIENTRY *PFND3D12DDI_COMPILER_DESTROY_DDI)(
    D3D12DDI_HCOMPILERDDI hCompilerDDI
    );
```

Destroys the compiler DDI object.  Any function tables retrieved from the DDI are now invalid to use.

**Parameters**

*hCompilerDDI*

The handle to the plugin compiler DDI object.

#### Function: PFND3D12DDI_COMPILER_GET_SUPPORTED_VERSIONS

```c++
typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_GET_SUPPORTED_VERSIONS)(
    D3D12DDI_HCOMPILERDDI hCompilerDDI,
    _Inout_ UINT32* puEntries, 
    _Out_writes_opt_( *puEntries ) UINT64* pSupportedPluginDDIVersions
    );
```

Retrieves the list of State Object Compiler  DDI version supported by the compiler plugin.  It is only necessary to expose a new DDI version from the compiler plugin when caps or definitions related to state objects change (i.e. it does not need to rev every time driver version does,but it can)

NOTE: This is not the same series of version numbers as the D3D12 runtime Usermode DDI, it is a version series dedicated to the State Object Compiler so it may be versioned independently.  However, each State Object Compiler version is assigned a single D3D12 Usermode DDI version at design time to make it clear which version of shared concepts such as PSO Descs, SO Descs, and shared caps are in use.  For clarity, this Usermode DDI version is set at runtime during [PFND3D12DDI_COMPILER_SET_SELECTED_VERSION](#function-pfnd3d12ddi_compiler_set_selected_version).

**Parameters**

*hCompilerDDI*

*puEntries*

*SupportedPluginDDIVersions*

The list of supported versions.

**Remarks**

The plugin runtime calls the plugin to retrieve a list of the supported DDI versions.  

Upon return, assign the size of the supported versions array to *puEntries.

When checking size of the array, the runtime will call the plugin with with *puEntries initially set to zero and SupportedPluginDDIVersions set to nullptr.

When requesting the array, *puEntries will be the size of the SupportedPluginDDIVersions.  Plugin copies the version list into this array.

#### Function: PFND3D12DDI_COMPILER_SET_SELECTED_VERSION

```c++
typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_SET_SELECTED_VERSION)(
    D3D12DDI_HCOMPILERDDI   hCompilerDDI,
    UINT64                  PluginDDIVersion,
    UINT64                  UsermodeDDIVersion
    );
```

Sets the DDI version that the State Object Compiler runtime selects from the list the compiler plugin provides to PFND3D12DDI_COMPILER_GET_SUPPORTED_VERSIONS.  The runtime typically picks the latest version supported by both the plugin and the compiler runtime.

**Parameters**

*hCompilerDDI*

*PluginDDIVersion*

The the plugin DDI version selected from the list reported by the plugin during [PFND3D12DDI_COMPILER_GET_SUPPORTED_VERSIONS](#function-pfnd3d12ddi_compiler_get_supported_versions).  This version number dictates which version of function tables and behaviors used.

*UsermodeDDIVersion*

The D3D12 runtime usermode DDI version associated with PluginDDIVersion.

**Remarks**

This function must be called before any calls to PFND3D12DDI_COMPILER_FILL_DDI_TABLE.

When a new PluginDDIVersion is introduced, it is assigned a UsermodeDDIVersion at design time.  The UsermodeDDIVersion may not change for a given PluginDDIVersion.  The compiler plugin must only report PluginDDIVersions that it also supports with the corresponding UsermodeDDIVersion.  UsermodeDDIVersion is provided for clarity to indicate which version of concepts shared with the D3D12 runtime are in use, such as PSO Descs, SO Descs, and some shared caps.  This version may be relied upon when sharing implementation with the D3D12 Usermode Driver.  See [Driver Independent Plugin](#driver-independent-plugin).

#### Enumeration: D3D12DDI_COMPILER_TABLE_TYPE

```c++
typedef enum D3D12DDI_COMPILER_TABLE_TYPE
{
    D3D12DDI_COMPILER_TABLE_TYPE_CAPABILITIES = 0,
    D3D12DDI_COMPILER_TABLE_TYPE_COMPILER = 1,
    D3D12DDI_COMPILER_TABLE_TYPE_MAX, ;internal
} D3D12DDI_COMPILER_TABLE_TYPE;
```

**Constants**

*D3D12DDI_COMPILER_TABLE_TYPE_CAPABILITIES*

Retrieve functions for checking plugin capabilities.  See [D3D12DDI_COMPILER_CAPABILITIES_FUNCS](#struct-d3d12ddi_compiler_capabilities_funcs).

*D3D12DDI_COMPILER_TABLE_TYPE_COMPILER*

Retrieve functions for creating and invoking an adapter families compiler.  See [D3D12DDI_COMPILER_FUNCS](#struct-d3d12ddi_compiler_funcs).

#### Function: PFND3D12DDI_COMPILER_FILL_DDI_TABLE

```c++
typedef HRESULT ( APIENTRY * PFND3D12DDI_COMPILER_FILL_DDI_TABLE )(
    D3D12DDI_HCOMPILERDDI hCompilerDDI, 
    D3D12DDI_COMPILER_TABLE_TYPE tableType,
    _Inout_ VOID* pTable,
    SIZE_T tableSize
    );
```

Request additional function tables from the compiler plugin.

**Parameters**

*hCompilerDDI*

The handle to the plugin compiler DDI object.

*tableType*

Determines the type of pTable.  See [D3D12DDI_COMPILER_TABLE_TYPE](#enumeration-d3d12ddi_compiler_table_type).

*pTable*

Buffer pointer that the plugin must copy the function table too.

*tableSize*

The size in bytes of the pTable buffer.

**Remarks**

[PFND3D12DDI_COMPILER_SET_SELECTED_VERSION](#function-pfnd3d12ddi_compiler_set_selected_version) must be called by the plugin runtime before calling this function.  This enables function table versioning based on the selected version.

#### Enumeration: D3D12DDI_COMPILER_CALLBACK_TABLE_TYPE

```c++
typedef enum D3D12DDI_COMPILER_CALLBACK_TABLE_TYPE
{
    D3D12DDI_COMPILER_CALLBACK_TABLE_TYPE_CACHE = 0,
    D3D12DDI_COMPILER_CALLBACK_TABLE_TYPE_MAX, ;internal
} D3D12DDI_COMPILER_CALLBACK_TABLE_TYPE;
```

Specifies which table is being set during PFND3D12DDI_COMPILER_SET_CALLBACK_DDI_TABLE.

**Constants**

*D3D12DDI_COMPILER_CALLBACK_TABLE_TYPE_CACHE*

Sets the D3D12DDI_COMPILER_CACHE_CALLBACKS table that allows for finding and storing cached values.  This table is always set before any compiler objects are created.

#### Function: PFND3D12DDI_COMPILER_SET_CALLBACK_DDI_TABLE

Sets function tables that the driver uses to callback into the State Object Compiler runtime.

```c++
typedef HRESULT ( APIENTRY *PFND3D12DDI_COMPILER_SET_CALLBACK_DDI_TABLE)(
    D3D12DDI_HCOMPILERDDI hCompilerDDI,
    D3D12DDI_COMPILER_CALLBACK_TABLE_TYPE tableType,
    _In_reads_(TableSize) const void* pTable,
    SIZE_T TableSize
    );
```

**Parameters**

*hCompilerDDI*

The handle to the plugin compiler DDI object.

*tableType*

Determines the type of pTable.  See [D3D12DDI_COMPILER_CALLBACK_TABLE_TYPE](#enumeration-d3d12ddi_compiler_callback_table_type).

*pTable*

Buffer pointer that contains the State Object Compiler runtime callback table.

*tableSize*

The size in bytes of the pTable buffer.

### Application and Compiler Descs

Common structs for identifying and versioning applications, plugin compilers, and plugin application profiles.

#### Struct: D3D12DDI_VERSION_NUMBER

Describes a version number.  Used to describe the version of the compiler, application profiles, application versions, and minimum driver versions.

```c++
typedef union D3D12DDI_VERSION_NUMBER
{
    UINT64 Version;
    UINT16 VersionParts[4];
} D3D12DDI_VERSION_NUMBER;
```

**Members**

*Version*

A 64 bit encoding of four 16bit values to define a four part version as X.X.X.X.  The most significant 16bits are the first number, the next most significant bits are the second, etc.  

*VersionParts*

A 16 bit array representation of the version number.

#### Struct: D3D12DDI_APPLICATION_DESC

```c++
typedef struct D3D12DDI_APPLICATION_DESC
{
    PWSTR pExeFilename;
    PWSTR pName;
    D3D12DDI_VERSION_NUMBER Version;
    PWSTR pEngineName;
    D3D12DDI_VERSION_NUMBER EngineVersion;
} D3D12DDI_APPLICATION_DESC;
```

Metadata originating from the game store to allow the compiler plugin to identify an application.

Member                                  | Definition
------                                  | ----------
PCWSTR pExeFilename                     | Main application executable name.  Includes the file extension, i.e "Code.exe".  This parameter is required and must be null terminated.  The member pExeFilename is used to help uniquely identify an application, but SODBs and PSDBs generated with this value may be used from other executables within the same application. For usermode drivers and the D3D12 runtime, this value is not guaranteed to match the host executable of the respective dlls. Applications must use the same pExeFilename string for all of its SODBs, regardless of which executable(s) in the application make use of it.
PCWSTR pName                            | The title of the application.  Example: "Microsoft Visual Studio Code".  This parameter is required and must be null terminated.
D3D12DDI_VERSION_NUMBER Version         | The version of the application.  For example, for Visual Studio Code 1.93.1, the version would be: 0x0001005D00010000.  This parameter is required.
PCWSTR pEngineName                      | The name of the game engine used.  Example "Godot", "Unity", "Unreal Engine", etc.  This parameter is optional, but should be provided whenever possible and must be null terminated.  Use nullptr to indicate unspecified.
D3D12DDI_VERSION_NUMBER EngineVersion   | The version of the engine.  For example, for Godot 4.3, the version would be: 0x0004000300000000.  This parameter is required if pEngineName is non-nullptr.

Note: An application may have multiple SODBs, but the application information must be identical between them.

#### Struct: D3D12DDI_SHADERCACHE_ABI_SUPPORT_DATA

```c++
// D3D12DDICAPS_TYPE_SHADERCACHE_ABI_SUPPORT
typedef struct D3D12DDI_SHADERCACHE_ABI_SUPPORT_DATA
{
    CONST CHAR szAdapterFamily[128];
    UINT64 MinimumABISupportVersion;
    UINT64 MaximumABISupportVersion;
    D3D12DDI_VERSION_NUMBER CompilerVersion;
    D3D12DDI_VERSION_NUMBER ApplicationProfileVersion;
} D3D12DDI_SHADERCACHE_ABI_SUPPORT_DATA;
```

Used as the pData of [D3D12DDIARG_SHADERCACHE_GETCAPS](#struct:-d3d12ddiarg_shadercache_getcaps) when querying [D3D12DDICAPS_TYPE_SHADERCACHE_ABI_SUPPORT](#enum:-d3d12ddicaps_type_shadercache).  IHVs assign one or more adapters to an adapter family, and report that family in the D3D12DDI.  They then supply a compiler for that family to allow compilation targeting the set of adapters specified by the family.  The ABI version range is compared to the ABI version of the compiler that produced precompiled shaders.

See also [PFND3D12DDI_COMPILER_CHECK_ABI_VERSION](../ShaderCompilerPlugin.md#function:-pfnd3d12ddi_compiler_check_abi_version) in the compiler plugin specification.

Members                                             | Description
------                                              | ----------
CONST CHAR szAdapterFamily[128];                    | The IHV defined adapter family that this adapter belongs to.
MinimumABISupportVersion                            | The lowest compiler ABI version supported by the driver.
MaximumABISupportVersion                            | The highest compiler ABI version supported by the driver.
CompilerVersion                                     | The Compiler Version of the compiler used by driver.
ApplicationProfileVersion                           | The version of the compiler profile that targets this application.

Note: These values are expected to match the locally registered compiler:

- szAdapterFamily must be supported by the compiler plugin
- MaximumABISupportedVersion must be supported by the compiler plugin
- CompilerVersion must match the CompilerVersion of the corresponding compiler registered for this driver.
- ApplicationProfileVersion must also match the compiler given the same adapter family and application desc.

Note: ApplicationProfileVersion here is determined by inspecting the D3D12DDI_APPLICATION_DESC retreived from D3DDDI_QUERYADAPTERTYPE_APPLICATIONDESC.  When the desc is not available or does not match a profile, this value should be zero.  When D3DDDI_QUERYADAPTERTYPE_APPLICATIONSPECIFICDRIVERBLOB is used, the blob should allow returning an value here that is consistent with when the blob was captured for replay scenarios.

#### Struct: D3D12DDI_COMPILER_ADAPTER_FAMILY

Describes an adapter family by name.

```c++
typedef struct D3D12DDI_COMPILER_ADAPTER_FAMILY
{
    WCHAR szAdapterFamily[128];
} D3D12DDI_COMPILER_ADAPTER_FAMILY;
```

**Members**

*szAdapterFamily*

Uniquely identifies an adapter family for a hardware vendor.  

**Remarks**

An adapter family is a set of adapters that all share the same compiled output for a given ABI version.

#### Struct: D3D12DDI_COMPILER_TARGET

```c++
typedef struct D3D12DDI_COMPILER_TARGET
{
    UINT AdapterFamilyIndex;
    UINT64 ABIVersion;
} D3D12DDI_COMPILER_TARGET;
```

**Members**

*AdapterFamilyIndex*

The index of the target adapter family.  See [D3D12DDI_COMPILER_ADAPTER_FAMILY](#struct-d3d12ddi_compiler_adapter_family) and [PFND3D12DDI_COMPILER_ENUMERATE_ADAPTER_FAMILIES](#function-pfnd3d12ddi_compiler_enumerate_adapter_families).

*ABIVersion*

The target ABIVersion the AdapterFamily.

**Remarks**

The runtime validates the ABIVersion is one returned from [PFND3D12DDI_COMPILER_GET_ADAPTER_FAMILY_ABI_VERSIONS](#function-pfnd3d12ddi_compiler_get_adapter_family_abi_versions).

### Checking Capabilities

#### Struct: D3D12DDI_COMPILER_CAPABILITIES_FUNCS

```c++
// D3D12DDI_COMPILER_TABLE_TYPE_CAPABILITIES
typedef struct D3D12DDI_COMPILER_CAPABILITIES_FUNCS
{
    PFND3D12DDI_COMPILER_GET_CAPS                           pfnGetCaps;
    PFND3D12DDI_COMPILER_ENUMERATE_ADAPTER_FAMILIES         pfnEnumerateAdapterFamilies;
    PFND3D12DDI_COMPILER_GET_ADAPTER_FAMILY_ABI_VERSIONS    pfnGetAdapterFamilyABIVersions;
    PFND3D12DDI_COMPILER_GET_COMPILER_VERSION               pfnGetCompilerVersion;
    PFND3D12DDI_COMPILER_GET_APPLICATION_PROFILE_VERSION    pfnGetApplicationProfileVersion;
    PFND3D12DDI_COMPILER_CHECK_FORMAT_SUPPORT               pfnCheckFormatSupport;
    PFND3D12DDI_COMPILER_CHECK_MULTISAMPLE_QUALITY_LEVELS   pfnCheckMultisampleQualityLevels;

} D3D12DDI_COMPILER_CAPABILITIES_FUNCS;
```

Function table w/ various compiler plugin entrypoints for checking capabilities (CAPS).

#### Function: PFND3D12DDI_COMPILER_GET_CAPS

```c++
typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_GET_CAPS)(
    D3D12DDI_HCOMPILERDDI hCompilerDDI,
    _In_ const D3D12DDI_COMPILER_TARGET* pTarget,
    _In_ const D3D12DDI_APPLICATION_DESC* pApplicationDesc,
    _In_ const D3D12DDIARG_GETCAPS* pCaps
    );
```

Returns capabilities for D3D12 DDI Caps.

**Parameters**

*hCompilerDDI*

The handle to the plugin compiler DDI object.

*pTarget*

Contains the adapter family and ABI version.  See [D3D12DDI_COMPILER_TARGET](#struct-d3d12ddi_compiler_target).

*ABIVersion*

The ABIVersion of pAdapterFamily to retrieve caps for.

*pApplicationDesc*

Describes the target application and version.  Not typically used, see Remarks.  See [D3D12DDI_APPLICATION_DESC](struct-d3d12ddi_application_desc).

*pCaps*

Cap type, inputs and outputs.  See [D3D12DDICAPS_TYPE](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/d3d12umddi/ne-d3d12umddi-d3d12ddicaps_type)

**Remarks**

This is expected to match UMD implementation for adapter drivers in the same adapter family.

The following caps may be queried:

D3D12DDICAPS_TYPE_SHADER
D3D12DDICAPS_TYPE_D3D12_OPTIONS
D3D12DDICAPS_TYPE_OPTIONS_*
D3D12DDICAPS_TYPE_SHADER_MODEL_6_8_OPTIONS_0110
D3D12DDICAPS_TYPE_0011_SHADER_MODELS
D3D12DDICAPS_TYPE_0081_3DPIPELINESUPPORT1

The Application Desc parameter pApplicationDesc should not typically used.  On occasion, drivers have changed capability reporting for a specific application with known issues to work around those problems.

#### Function: PFND3D12DDI_COMPILER_ENUMERATE_ADAPTER_FAMILIES

```c++
typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_ENUMERATE_ADAPTER_FAMILIES)(
    D3D12DDI_HCOMPILERDDI hCompilerDDI,
    UINT AdapterFamilyIndex,
    _Out_ D3D12DDI_COMPILER_ADAPTER_FAMILY* pAdapterFamily
    );
```

Retrieve a list of all adapter families supported by the plugin.

**Parameters**

*hCompilerDDI*

The handle to the plugin compiler DDI object.

*AdapterFamilyIndex*

The index of the adapter family to enumerate.

*pAdapterFamily*

Describes the adapter family for the given AdapterFamilyIndex.  See [D3D12DDI_COMPILER_ADAPTER_FAMILY](#struct-d3d12ddi_compiler_adapter_family).

**Remarks**

Plugins must expose adapter families with contiguous indices starting at index zero.  When the index exceeds the available families, return DXGI_ERROR_NOT_FOUND.

Enumerating all adapter families can be accomplished like so:

```c++
D3D12DDI_COMPILER_ADAPTER_FAMILY adapterFamily = {};
for (UINT AdapterFamilyIndex = 0; *pfnEnumerateCompilers(AdapterFamilyIndex, &adapterFamily) != DXGI_ERROR_NOT_FOUND; 
     ++AdapterFamilyIndex) 
{ ... }
```

#### Function: PFND3D12DDI_COMPILER_GET_ADAPTER_FAMILY_ABI_VERSIONS

```c++
typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_GET_ADAPTER_FAMILY_ABI_VERSIONS)(
    D3D12DDI_HCOMPILERDDI hCompilerDDI,
    UINT AdapterFamilyIndex,
    _Inout_ UINT* pNumABIVersions, 
    _Out_writes_opt_( *pNumABIVersions ) UINT64* pABIVersions
    );
```

Retrieve the list of ABI versions supported for an adapter family.

**Parameters**

*hCompilerDDI*

The handle to the plugin compiler DDI object.

*AdapterFamilyIndex*

The index of the target adapter family.  See [D3D12DDI_COMPILER_ADAPTER_FAMILY](#struct-d3d12ddi_compiler_adapter_family) and [PFND3D12DDI_COMPILER_ENUMERATE_ADAPTER_FAMILIES](#function-pfnd3d12ddi_compiler_enumerate_adapter_families).

*pNumABIVersions*

On input, describes the size of pABIVersions.  *pNumABIVersions is zero when pABIVersions is nullptr.  This may be used to retrieve a partial list, see remarks.  On output, returns the number of ABI Versions for pAdapterFamily.

*pABIVersions*

Recieves the list of ABI Versions for pAdapterFamily.  May be nullptr when performing a size check.

**Remarks**

Returns the the compiler ABI version supported by the compiled binaries produced by this compiler.  This is compared with the supported ABI range of a driver to understand if precompiled binaries are supported.  See the [D3D12DDI_SHADERCACHE_ABI_SUPPORT_DATA](#struct-d3d12ddi_shadercache_abi_support_data) capability check. A range of ABI versions is supported for an adapter family to allow targeting adapters that may not be receiving driver updates.

Compiled objects produced by this compiler may not be used with drivers that do not report this ABI version in their supported ABI version range.

ABI version is used to check for precompiled cache updates and understand cache compatibility with drivers on the client, see [IHV Compiler Plugin](#ihv-compiler-plugin) in the design section.

If the adatper family is not one of the families returned by [PFND3D12DDI_COMPILER_ENUMERATE_ADAPTER_FAMILIES](#function-pfnd3d12ddi_compiler_enumerate_adapter_families), return DXGI_ERROR_NOT_FOUND.

If pNumABIVersions is nullptr, return E_INVALIDARG.

If the adapter family is valid and pNumABIVersions is non-nullptr, always set \*puEntries to the correct number of ABI versions for the family on return, regardless of other success/failure. Otherwise, set it to zero.

pAdapterFamily may be nullptr when performing a size check.  In that case, set \*pNumABIVersions to the number of ABI versions for the adapter family and return S_OK.

ABIVersion 0x0 and UINT64_MAX(0xffffffffffffffffui64) are reserved and must not be returned.  Compilers report version 1 for the initial version of an adapter families ABI, and then increments this counter every time the ABI version changes.

ABI Versions must be reported in ascending order, so the latest ABI version appears at pABIVersions[0] and the oldest ABI version is at the highest index.  If the buffer size is insufficient, driver must fill out as many ABI versions as there is room for and report DXGI_ERROR_MORE_DATA.  For example, this may be used to only retrieve the latest ABI version supported.

If \*pNumABIVersions is equal to the number of ABI version or larger, copy the complete list and set \*pNumABIVersions to the correct number of entries.  Return S_OK.

#### Function: PFND3D12DDI_COMPILER_GET_COMPILER_VERSION

```c++
typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_GET_COMPILER_VERSION)(
    D3D12DDI_HCOMPILERDDI                   hCompilerDDI,
    _In_ UINT                               AdapterFamilyIndex,
    _Out_ D3D12DDI_VERSION_NUMBER*          pCompilerVersion
    );
```

Describes the version of a compiler for an adapter family.

**Parameters**

*hCompilerDDI*

The handle to the plugin compiler DDI object.

*AdapterFamilyIndex*

The index specifies adapter family.  See [D3D12DDI_COMPILER_ADAPTER_FAMILY](#struct-d3d12ddi_compiler_adapter_family) and [PFND3D12DDI_COMPILER_ENUMERATE_ADAPTER_FAMILIES](#function-pfnd3d12ddi_compiler_enumerate_adapter_families).

*pCompilerVersion*

Compiler version changes signify changes in code generation that potentially impact all applications for an adapter family.  See [D3D12DDI_VERSION_NUMBER](#struct-d3d12ddi_version_number).

**Remarks**

Major/Minor version change for "must" recompile such as security or major fixes.  Build for "should" recompile such as performance.  Revision for less consequential changes that shouldn't invalidate caches.

#### Function: PFND3D12DDI_COMPILER_GET_APPLICATION_PROFILE_VERSION

```c++
typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_GET_APPLICATION_PROFILE_VERSION)(
    D3D12DDI_HCOMPILERDDI hCompilerDDI,
    _In_ const D3D12DDI_COMPILER_TARGET* pTarget,
    _In_ const D3D12DDI_APPLICATION_DESC* pApplicationDesc,
    _Out_ D3D12DDI_VERSION_NUMBER* pApplicationProfileVersion
    );
```

Return the application profile version number.  An application profile is any application dependent profile or settings that do not impact compilation for other applications.  Any time those settings change for a given application, update the version number.

**Parameters**

*hCompilerDDI*

The handle to the plugin compiler DDI object.

*pTarget*

Contains the adapter family and ABI version.  See [D3D12DDI_COMPILER_TARGET](#struct-d3d12ddi_compiler_target).

*pApplicationDesc*

Describes the target application and version.  See [D3D12DDI_APPLICATION_DESC](#struct-d3d12ddi_application_desc).

*pApplicationProfileVersion*

Describes the version of the compiler profile that targets a specific application.  Applications are specified by application identifier and application version.  Compilers may revise this number to indicate application specific changes to compiler output.  See [D3D12DDI_VERSION_NUMBER](#struct-d3d12ddi_version_number).

**Remarks**

The compiler profile can be versioned when there application specific changes to these profiles that do not impact other applications.  This prevents invalidating caches for all applications when a change is application specific.

#### Function: PFND3D12DDI_COMPILER_CHECK_FORMAT_SUPPORT

```c++
typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_CHECK_FORMAT_SUPPORT)(
    D3D12DDI_HCOMPILERDDI hCompilerDDI,
    _In_ const D3D12DDI_COMPILER_TARGET* pTarget,
    DXGI_FORMAT Format, 
    _Out_ UINT* pFormatSupport
    );
```

Check support for features that are optional on some formats.

**Parameters**

*hCompilerDDI*

The handle to the plugin compiler DDI object.

*pTarget*

Contains the adapter family and ABI version.  See [D3D12DDI_COMPILER_TARGET](#struct-d3d12ddi_compiler_target).

*Format*

A [DXGI_FORMAT](https://learn.microsoft.com/en-us/windows/desktop/api/dxgiformat/ne-dxgiformat-dxgi_format) value for the format to return info about.

*pFormatSupport*

A D3D12DDI_FORMAT_SUPPORT bitfield for features that are optional on some formats.

**Remarks**

This is expected to match UMD implementation for adapter drivers in the same adapter family.

#### Function: PFND3D12DDI_COMPILER_CHECK_MULTISAMPLE_QUALITY_LEVELS

```c++
typedef BOOL (APIENTRY *PFND3D12DDI_COMPILER_CHECK_MULTISAMPLE_QUALITY_LEVELS)(
        D3D12DDI_HCOMPILERDDI hCompilerDDI,
        _In_ const D3D12DDI_COMPILER_TARGET* pTarget,
        DXGI_FORMAT Format,
        UINT SampleCount,
        UINT QualityLevel
    );
```

Queries if the image quality level is supported for a given format and sample count.

**Parameters**

*hCompilerDDI*

The handle to the plugin compiler DDI object.

*pTarget*

Contains the adapter family and ABI version.  See [D3D12DDI_COMPILER_TARGET](#struct-d3d12ddi_compiler_target).

*Format*

A [DXGI_FORMAT](https://learn.microsoft.com/en-us/windows/desktop/api/dxgiformat/ne-dxgiformat-dxgi_format) value for the format to check.

*SampleCount*

The number of multi-samples per pixel to check.

*QualityLevel*

The quality level to check.

**Remarks**

Returns TRUE if supported, FALSE otherwise.  This is expected to be consistent with the UMD implementation for adapter drivers in the same adapter family.

### Cache Session Callbacks

Callbacks passed to compiler object creation.  Plugins use these callbacks to store compilation results and lookup previous compilation results.

#### Callback Handle: D3D12DDI_HRTCOMPILERCACHESESSION

The runtimes compiler cache session object.  

```c++
D3D10DDI_HRT(D3D12DDI_HRTCOMPILERCACHESESSION)
```

**Remarks**

This object is supplied during a compiliation operation and must be used to call D3D12DDI_COMPILER_CACHE_CALLBACKS.  A given cache session handle is only valid and has the lifetime of a single compile DDI call.

#### Enumeration: D3D12DDI_COMPILER_CACHE_VALUE_TYPE

A type enumeration used when only a single value type may be selected.

```c++
typedef enum D3D12DDI_COMPILER_CACHE_VALUE_TYPE
{
    D3D12DDI_COMPILER_CACHE_VALUE_TYPE_OBJECT_CODE        = 0,
    D3D12DDI_COMPILER_CACHE_VALUE_TYPE_METADATA           = 1,
    D3D12DDI_COMPILER_CACHE_VALUE_TYPE_DEBUG_PDB          = 2,
    D3D12DDI_COMPILER_CACHE_VALUE_TYPE_PERFORMANCE_DATA   = 3,

    D3D12DDI_COMPILER_CACHE_VALUE_TYPE_MAX_VALID, ; internal
} D3D12DDI_COMPILER_CACHE_VALUE_TYPE;
```

**Constants**

*D3D12DDI_COMPILER_CACHE_VALUE_TYPE_OBJECT_CODE*

Specifies object code.  The compiled executable code that is run on GPU.

*D3D12DDI_COMPILER_CACHE_VALUE_TYPE_METADATA*

Metadata that the compiler may provide about the compile.  For example it may store a compiler version number used for validation.  Such a thing should not be put inside of the object code as users of this system expect to be able to do memcmp diffing between compiler versions.  

*D3D12DDI_COMPILER_CACHE_VALUE_TYPE_DEBUG_PDB*

The Debug PDB for the object code.  Used in pix and other debug scenarios.  An opaque blob that still requires IHV interpretation to used with PIX.

*D3D12DDI_COMPILER_CACHE_VALUE_TYPE_PERFORMANCE_DATA*

Performance data about the compile or produced object code.  An opaque blob that still requires IHV interpretation to used with PIX.

**Remarks**

Used when defining a typed value, see [D3D12DDI_COMPILER_CACHE_TYPED_VALUE](#struct-d3d12ddi_compiler_cache_typed_value).

#### Enumeration: D3D12DDI_COMPILER_VALUE_TYPE_FLAGS

A flags enumeration used where multiple values may be selected.

```c++
typedef enum D3D12DDI_COMPILER_VALUE_TYPE_FLAGS
{
    D3D12DDI_COMPILER_CACHE_VALUE_TYPE_FLAG_NONE                = 0x00000000,
    D3D12DDI_COMPILER_CACHE_VALUE_TYPE_FLAG_OBJECT_CODE         = (1 << D3D12DDI_COMPILER_CACHE_VALUE_TYPE_OBJECT_CODE),
    D3D12DDI_COMPILER_CACHE_VALUE_TYPE_FLAG_METADATA            = (1 << D3D12DDI_COMPILER_CACHE_VALUE_TYPE_METADATA),
    D3D12DDI_COMPILER_CACHE_VALUE_TYPE_FLAG_DEBUG_PDB           = (1 << D3D12DDI_COMPILER_CACHE_VALUE_TYPE_DEBUG_PDB),
    D3D12DDI_COMPILER_CACHE_VALUE_TYPE_FLAG_PERFORMANCE_DATA    = (1 << D3D12DDI_COMPILER_CACHE_VALUE_TYPE_PERFORMANCE_DATA),

} D3D12DDI_COMPILER_CACHE_VALUE_TYPE_FLAGS;
DEFINE_ENUM_FLAG_OPERATORS( D3D12DDI_COMPILER_CACHE_VALUE_TYPE_FLAGS )
```

**Constants**

*D3D12DDI_COMPILER_VALUE_TYPE_FLAGS_NONE*

No selected value types.

*D3D12DDI_COMPILER_VALUE_TYPE_FLAGS_OBJECT_CODE*

Indicates object code, see D3D12DDI_COMPILER_CACHE_VALUE_TYPE_OBJECT_CODE.

*D3D12DDI_COMPILER_VALUE_TYPE_FLAGS_DEBUG_PDB*

Indicates Debug PDB, see D3D12DDI_COMPILER_CACHE_VALUE_TYPE_DEBUG_PDB.

*D3D12DDI_COMPILER_VALUE_TYPE_FLAGS_PERFORMANCE_DATA*

Indicates Performance Data, see D3D12DDI_COMPILER_CACHE_VALUE_TYPE_PERFORMANCE_DATA.

**Remarks**

Example uses:

-Used for selecting which value types must be loaded/stored during [PFND3D12DDI_COMPILER_COMPILE_PIPELINE_STATE](#function-pfnd3d12ddi_compiler_compile_pipeline_state) and other compile operations.

#### Struct: D3D12DDI_COMPILER_CACHE_VALUE_KEY

```c++
typedef struct D3D12DDI_COMPILER_CACHE_VALUE_KEY
{
    _Field_size_bytes_full_(KeySize) const void* pKey;
    UINT KeySize;
} D3D12DDI_COMPILER_CACHE_VALUE_KEY;
```

**Members**

*pKey*

A unique sequence of bytes that uniquely identifies an object in the database.

*KeySize*

The size in bytes of pKey.

**Remarks**

Used during cache operations like find and store value to identify a value.

#### Struct: D3D12DDI_COMPILER_CACHE_VALUE

Specifies a non-const value buffer and buffer size.

```c++
typedef struct D3D12DDI_COMPILER_CACHE_VALUE
{
    _Field_size_bytes_opt_(ValueSize) void* pValue;
    SIZE_T ValueSize;
} D3D12DDI_COMPILER_CACHE_VALUE;
```

**Members**

*pValue*

A pointer to a member buffer containing the value.

*ValueSize*

The size of the pValue buffer in bytes.

**Remarks**

See also [D3D12DDI_COMPILER_CACHE_TYPED_VALUE](#struct-d3d12ddi_compiler_cache_typed_value).

#### Struct: D3D12DDI_COMPILER_CACHE_TYPED_VALUE

Specifies a value and its type, such as object code, metadata etc.

```c++
typedef struct D3D12DDI_COMPILER_CACHE_TYPED_VALUE
{
    D3D12DDI_COMPILER_CACHE_VALUE_TYPE  Type;
    D3D12DDI_COMPILER_CACHE_VALUE       Value;
} D3D12DDI_COMPILER_CACHE_TYPED_VALUE;
```

**Members**

*Type*

The type of the value, such as object code, metadata, etc.  See [D3D12DDI_COMPILER_CACHE_VALUE_TYPE](#enumeration-d3d12ddi_compiler_cache_value_type) for more information on types.

*Value*

The buffer and size for the value.  See [D3D12DDI_COMPILER_CACHE_VALUE](#struct-d3d12ddi_compiler_cache_value).

**Remarks**

Used in DDI where the compiler may modify the value buffer, such as [PFND3D12DDI_COMPILER_CACHE_FIND_VALUE_CB](#callback-function-pfnd3d12ddi_compiler_cache_find_value_cb).

#### Struct: D3D12DDI_COMPILER_CACHE_CONST_VALUE

Specifies a non-const value buffer and buffer size.

```c++
typedef struct D3D12DDI_COMPILER_CACHE_CONST_VALUE
{
    _Field_size_bytes_opt_(ValueSize) const void* pValue;
    SIZE_T ValueSize;
} D3D12DDI_COMPILER_CACHE_CONST_VALUE;
```

**Members**

*pValue*

A const pointer to a member buffer containing the value.

*ValueSize*

The size of the pValue buffer in bytes.

**Remarks**

See also [D3D12DDI_COMPILER_CACHE_TYPED_CONST_VALUE](#struct-d3d12ddi_compiler_cache_typed_const_value).

#### Struct: D3D12DDI_COMPILER_CACHE_TYPED_CONST_VALUE

```c++
typedef struct D3D12DDI_COMPILER_CACHE_TYPED_CONST_VALUE
{
    D3D12DDI_COMPILER_CACHE_VALUE_TYPE  Type;
    D3D12DDI_COMPILER_CACHE_CONST_VALUE Value;
} D3D12DDI_COMPILER_CACHE_TYPED_CONST_VALUE;
```

**Members**

*Type*

The type of the value, such as object code, metadata, etc.  See [D3D12DDI_COMPILER_CACHE_VALUE_TYPE](#enumeration-d3d12ddi_compiler_cache_value_type) for more information on types.

*Value*

The const buffer and size for the value.  See [D3D12DDI_COMPILER_CACHE_VALUE](#struct-d3d12ddi_compiler_cache_value).

**Remarks**

Used in DDI where the compiler may not modify the value buffer, such as [PFND3D12DDI_COMPILER_CACHE_STORE_VALUE_CB](#callback-function-pfnd3d12ddi_compiler_cache_store_value_cb).

#### Struct: D3D12DDI_COMPILER_CACHE_CALLBACKS

```c++
typedef struct D3D12DDI_COMPILER_CACHE_CALLBACKS
{
    PFND3D12DDI_COMPILER_CACHE_FIND_VALUE_CB pfnCompilerCacheFindValue;
    PFND3D12DDI_COMPILER_CACHE_STORE_VALUE_CB pfnCompilerCacheStoreValue;
    PFND3D12DDI_COMPILER_CACHE_SET_OBJECT_VALUE_KEYS_CB pfnCompilerCacheSetObjectValueKeys;
} D3D12DDI_COMPILER_CACHE_CALLBACKS;
```

**Members**

*pfnCompilerCacheFindValue*

See [PFND3D12DDI_COMPILER_CACHE_FIND_VALUE_CB](#callback-function-pfnd3d12ddi_compiler_cache_find_value_cb).

*pfnCompilerCacheStoreValue*

See [PFND3D12DDI_COMPILER_CACHE_STORE_VALUE_CB](#callback-function-pfnd3d12ddi_compiler_cache_store_value_cb).

*pfnCompilerCacheSetObjectValueKeys*

See [PFND3D12DDI_COMPILER_CACHE_SET_OBJECT_VALUE_KEYS_CB](#callback-function-pfnd3d12ddi_compiler_cache_set_object_value_keys_cb).

**Remarks**

#### Callback Function: PFND3D12DDI_COMPILER_CACHE_FIND_VALUE_CB

```c++
typedef HRESULT (APIENTRY CALLBACK *PFND3D12DDI_COMPILER_CACHE_FIND_VALUE_CB)(
    D3D12DDI_HRTCOMPILERCACHESESSION hrtCompilerCacheSession,
    _In_ const D3D12DDI_COMPILER_CACHE_VALUE_KEY* pValueKey,
    _Inout_count_(NumValues) D3D12DDI_COMPILER_CACHE_TYPED_VALUE* pValues,
    UINT NumValues,
    _In_opt_ PFND3D12DDI_COMPILER_ALLOCATION pCallbackFunc,
    _Inout_opt_ void* pContext
    );
```

Find a previously stored value in the cache.

**Parameters**

*hrtCompilerCacheSession*

The compiler cache session  callback handle received during a compilation operation.

*pValueKey*

The unique identifier for the value.  See [D3D12DDI_COMPILER_CACHE_VALUE_KEY](#struct-d3d12ddi_compiler_cache_value_key).

*pValues*

An array of typed values to retrieve the size or values of during the operation.  The array size is specified by NumValues.  See [D3D12DDI_COMPILER_CACHE_TYPED_VALUE](#struct-d3d12ddi_compiler_cache_typed_value).

*NumValues*

The number of values in the pValues array.

*pCallbackFunc*

An optional callback function for allocating value buffers.  See Remarks.

*pContext*

A compiler plugin specified context pointer that is passed to the callback.  Use this to pass parameters to the allocation callback function.

**Remarks**

Each D3D12DDI_COMPILER_CACHE_TYPED_VALUE has a D3D12DDI_COMPILER_CACHE_VALUE.  On input, each D3D12DDI_COMPILER_CACHE_VALUE ValueSize member specifies the size in bytes of the buffer pointed to by pValue. Use zero when querying size or using the allocation callback. On output, the ValueSize member is assigned the size of the value.

When Value is Found, for each D3D12DDI_COMPILER_CACHE_VALUE that is not a nullptr:

- If the ValueSize member is a non-zero value, the pValue member must point to a buffer of that size.  If ValueSize is greater than or equal to the value's actual size, the value is copied to pValue and the ValueSize member is assigned the actual size of the value.  If the caller specified ValueSize is insufficient, DXGI_ERROR_MORE_DATA is returned and the required size is assigned to the ValueSize member.
- If the ValueSize member is zero and pCallbackFunc is non-nullptr and the pValue member is non-nullptr, pCallbackFunc is called to allocate a buffer and the value is copied into it.  The allocated buffer pointer returned by pCallbackFunc is assigned to the pValue member on return. If pCallbackFunc returns nullptr, the call fails and returns E_OUTOFMEMORY.
- The ValueSize member is assigned the value's actual size before returning.

To determine if a particular value type is stored without retrieving the value, use a size check for the value. To perform a size check, use a nullptr pValue with a zero ValueSize for the types to query and a nullptr pCallbackFunc.  A return value of S_OK indicates the value is cached.  A return value of DXGI_ERROR_NOT_FOUND indicates a value with that key is not cached.  ValueSize is non-zero for a cached value type.

#### Callback Function: PFND3D12DDI_COMPILER_CACHE_STORE_VALUE_CB

```c++
typedef HRESULT (APIENTRY CALLBACK *PFND3D12DDI_COMPILER_CACHE_STORE_VALUE_CB)(
    D3D12DDI_HRTCOMPILERCACHESESSION hrtCompilerCacheSession,
    _In_ const D3D12DDI_COMPILER_CACHE_VALUE_KEY* pValueKey,
    _In_reads_(NumValues) const D3D12DDI_COMPILER_CACHE_TYPED_CONST_VALUE* pValues,
    UINT NumValues
    );
```

Add a key/value pair to the compiler cache.

**Parameters**

*hrtCompilerCacheSession*

The compiler cache session  callback handle received during a compilation operation.

*pKey*

A unique sequence of bytes that uniquely identifies an object in the database.

*KeySize*

The size in bytes of pKey.

*pValueKey*

The unique identifier for the value.  See [D3D12DDI_COMPILER_CACHE_VALUE_KEY](#struct-d3d12ddi_compiler_cache_value_key).

*pValues*

An array of typed values to store.  The array size is specified by NumValues.  See [D3D12DDI_COMPILER_CACHE_TYPED_CONST_VALUE](#struct-d3d12ddi_compiler_cache_typed_const_value).

*NumValues*

The number of values in the pValues array.

**Remarks**

At least one value must be stored in the store operation, so the function returns E_INVALIDARG if pValues nullptr or NumValues is zero.  Each value must have a non-zero size.  Only one value per type may be stored at a time.

This callback returns DXGI_ERROR_ALREADY_EXISTS if one of the non-nullptr values with pKey already exists.

Flags during the compile operation indicate which values must be stored.  See [D3D12DDI_COMPILER_VALUE_TYPE_Flags](#enumeration-d3d12ddi_compiler_value_type_flags).  Values are optionally stored to accommodate various scenarios such as generating PDB for existing object code with a matching compiler and source or Shader Explorer only needing the performance data output.

#### Callback Function: PFND3D12DDI_COMPILER_CACHE_SET_OBJECT_VALUE_KEYS_CB

A callback to set the list of value keys associated with an object.  

```c++
typedef HRESULT (APIENTRY CALLBACK *PFND3D12DDI_COMPILER_CACHE_SET_OBJECT_VALUE_KEYS_CB)(
    D3D12DDI_HRTCOMPILERCACHESESSION hrtCompilerCacheSession,
    _In_reads_(NumValueKeys) const D3D12DDI_COMPILER_CACHE_VALUE_KEY* pValueKeys,
    UINT NumValueKeys
    );
```

**Parameters**

*hrtCompilerCacheSession*

The compiler cache session  callback handle received during a compilation operation.

*pValueKey*

The unique identifiers for the values.  See [D3D12DDI_COMPILER_CACHE_VALUE_KEY](#struct-d3d12ddi_compiler_cache_value_key).

*NumValueKeys*

The number of keys specified by pValueKey.

**Remarks**

This stored list specifies the values that the driver receives during title cooperative scenarios.  It may also be used for other database management operations to map values back to state object definitions.  The compiler plugin must call this function once before returning from a compile operation.

### Compiling State Objects

A compiler object is instanced from a adapter family and application identity.  Used to compile state objects and store them in a cache session.

#### Handle: D3D12DDI_HCOMPILER

```c++
D3D10DDI_H( D3D12DDI_HCOMPILER )
```

A handle type representing the plugin's compiler object.

#### Callback Handle: D3D12DDI_HRTCOMPILER

```c++
D3D10DDI_HRT(D3D12DDI_HRTCOMPILER)
```

A handle type representing the runtime compiler object.  Allows compiler  plugins to call back into runtime.

#### Handle: D3D12DDI_HCOMPILERSTATEOBJECT

```c++
D3D10DDI_H( D3D12DDI_HCOMPILERSTATEOBJECT )
```

A handle type representing the compiler plugins state object.  This object type allows compiler plugins to store state between Create and AddTo state object calls.

#### Struct: D3D12DDI_COMPILER_FUNCS

```c++
// D3D12DDI_COMPILER_TABLE_TYPE_COMPILER
typedef struct D3D12DDI_COMPILER_FUNCS
{
    PFND3D12DDI_COMPILER_CALC_PRIVATE_COMPILER_SIZE             pfnCalcPrivateCompilerSize;
    PFND3D12DDI_COMPILER_CREATE_COMPILER                        pfnCreateCompiler;
    PFND3D12DDI_COMPILER_DESTROY_COMPILER                       pfnDestroyCopiler;
    PFND3D12DDI_COMPILER_COMPILE_PIPELINE_STATE                 pfnCompilePipelineState;
    PFND3D12DDI_COMPILER_CALC_PRIVATE_STATE_OBJECT_SIZE         pfnCalcPrivateStateObjectSize;
    PFND3D12DDI_COMPILER_COMPILE_CREATE_STATE_OBJECT            pfnCompileCreateStateObject;
    PFND3D12DDI_COMPILER_CALC_PRIVATE_ADD_TO_STATE_OBJECT_SIZE  pfnCalcPrivateAddToStateObjectSize;
    PFND3D12DDI_COMPILER_COMPILE_ADD_TO_STATE_OBJECT            pfnCompileAddToStateObject;
    PFND3D12DDI_COMPILER_DESTROY_STATE_OBJECT                   pfnDestroyStateObject;
} D3D12DDI_COMPILER_FUNCS;
```

The function table for creation and destruction of compiler objects and the compilation of state objects.  See the D3D12DDI_COMPILER_TABLE_TYPE_COMPILER constant in [D3D12DDI_COMPILER_TABLE_TYPE](#enumeration-d3d12ddi_compiler_table_type).

#### Function: PFND3D12DDI_COMPILER_CALC_PRIVATE_COMPILER_SIZE

```c++
typedef SIZE_T (APIENTRY *PFND3D12DDI_COMPILER_CALC_PRIVATE_COMPILER_SIZE)(
    _In_ const D3D12DDI_COMPILER_TARGET*                        pTarget,
    _In_ const D3D12DDI_APPLICATION_DESC*                       pApplicationDesc
    );
```

Determine the size of the driver compiler object.

**Parameters**

*pTarget*

Contains the adapter family and ABI version.  See [D3D12DDI_COMPILER_TARGET](#struct-d3d12ddi_compiler_target).

*pApplicationDesc*

Describes the target application and version.  See [D3D12DDI_APPLICATION_DESC](#struct-d3d12ddi_application_desc).

**Remarks**

The memory for storing the plugins cpu object representing the compiler is allocated by the caller. This method is used to calculate the plugins object size.

#### Function: PFND3D12DDI_COMPILER_CREATE_COMPILER

```c++
typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_CREATE_COMPILER)(
        _In_ const D3D12DDI_COMPILER_TARGET*                    pTarget,
        _In_ const D3D12DDI_APPLICATION_DESC*                   pApplicationDesc,
        D3D12DDI_HCOMPILER                                      hCompiler,
        D3D12DDI_HRTCOMPILER                                    hRTCompiler
    );
```

Create the driver compiler object.

**Parameters**

*pTarget*

Contains the adapter family and ABI version.  See [D3D12DDI_COMPILER_TARGET](#struct-d3d12ddi_compiler_target).

*pApplicationDesc*

Describes the target application and version.  See [D3D12DDI_APPLICATION_DESC](#struct-d3d12ddi_application_desc).

*hCompiler*

Handle for plugin compiler object.  Memory is allocated by the caller, and plugin places compiler object.

**Remarks**

#### Function: PFND3D12DDI_COMPILER_DESTROY_COMPILER

```c++
typedef VOID (APIENTRY *PFND3D12DDI_COMPILER_DESTROY_COMPILER)(
    D3D12DDI_HCOMPILER hCompiler
    );
```

De-allocate a plugin compiler object.

**Parameters**

*hCompiler*

Handle for plugin compiler object.

#### Function: PFND3D12DDI_COMPILER_COMPILE_PIPELINE_STATE

```c++
typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_COMPILE_PIPELINE_STATE)(
    D3D12DDI_HCOMPILER hCompiler,
    D3D12DDI_HRTCOMPILERCACHESESSION hrtCompilerCacheSession,
    D3D12DDI_COMPILER_VALUE_TYPE_FLAGS ValueTypeFlags,
    const D3D12DDIARG_CREATE_PIPELINE_STATE_0099* pPipelineStateArg
    );
```

Compile a graphics or compute pipeline state.

**Parameters**

*hCompiler*

Handle for plugin compiler object.

*hrtCompilerCacheSession*

The compiler cache session callback handle.  Used with cache operations to find/store values and set the values assocated with the object being compiled.  See [Cache Session Callbacks](#cache-session-callbacks).

*ValueTypeFlags*

Specify which values types to store in the cache session after compilation succeeds.  See [D3D12DDI_COMPILER_VALUE_TYPE_FLAGS](#enumeration-d3d12ddi_compiler_value_type_flags).

*pPipelineStateArgs*

Creation arguments for the pipeline state object to compile.

**Remarks**

Compiled output is stored via the [PFND3D12DDI_COMPILER_CACHE_STORE_VALUE_CB](#callback-function-pfnd3d12ddi_compiler_cache_store_value_cb) callback.  Check for previously compiled duplicates via the [PFND3D12DDI_COMPILER_CACHE_FIND_VALUE_CB](#callback-function-pfnd3d12ddi_compiler_cache_find_value_cb) callback.  D3D12DDI_COMPILER_CACHE_CALLBACKS are supplied during creation of the plugin compiler object, see [PFND3D12DDI_COMPILER_CREATE_COMPILER](#function-pfnd3d12ddi_compiler_create_compiler)

Compiler is expected to sub-divide objects in an IHV dependent way to support deduplication.  Multiple values may be stored per compile.

This method must not return until all compiled output is stored.  

The driver must call [PFND3D12DDI_COMPILER_CACHE_SET_OBJECT_VALUE_KEYS_CB](#callback-function-pfnd3d12ddi_compiler_cache_set_object_value_keys_cb) once before returning to set the values associated with this pipeline state object definition.

#### Function: PFND3D12DDI_COMPILER_CALC_PRIVATE_STATE_OBJECT_SIZE

```c++
typedef SIZE_T (APIENTRY *PFND3D12DDI_COMPILER_CALC_PRIVATE_STATE_OBJECT_SIZE)(
    D3D12DDI_HCOMPILER hCompiler,
    _In_ const D3D12DDIARG_CREATE_STATE_OBJECT_0054* pCreateStateObject
    );
```

Calculate the size needed for compilers state object implementation.

**Parameters**

*hCompiler*

Handle for plugin compiler object.

*pCreateStateObjectArg*

Creation arguments for the state object.

#### Function: PFND3D12DDI_COMPILER_COMPILE_CREATE_STATE_OBJECT

```c++
typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_COMPILE_CREATE_STATE_OBJECT)(
    D3D12DDI_HCOMPILER hCompiler,
    D3D12DDI_HRTCOMPILERCACHESESSION hrtCompilerCacheSession,
    D3D12DDI_COMPILER_VALUE_TYPE_FLAGS ValueTypeFlags,
    _In_ const D3D12DDIARG_CREATE_STATE_OBJECT_0054* pCreateStateObject,
    D3D12DDI_HCOMPILERSTATEOBJECT hStateObject
    );
```

**Parameters**

*hCompiler*

Handle for plugin compiler object.

*hrtCompilerCacheSession*

The compiler cache session callback handle.  Used with cache operations to find/store values and set the values assocated with the object being compiled.  See [Cache Session Callbacks](#cache-session-callbacks).

*ValueTypeFlags*

Specify which values types to store in the cache session after compilation succeeds.  See [D3D12DDI_COMPILER_VALUE_TYPE_FLAGS](#enumeration-d3d12ddi_compiler_value_type_flags).

*pCreateStateObjectArg*

Creation arguments for the state object.

*hStateObject*

A handle pointing to the pre-allocated space for the compiler object.  Compiler places the object in this allocation and uses it to store state to support future calls to [PFND3D12DDI_COMPILER_COMPILE_ADD_TO_STATE_OBJECT](#function-pfnd3d12ddi_compiler_compile_add_to_state_object) calls.

**Remarks**

The lifetime of pCreateStateObjectArg is guaranteed until hStateObject is destroyed; therefore, compiler only needs to store a pointer to this structure to support future AddToStateObject calls.  Compiler must store other state needed for future compilation with hStateObject, such as keys to lookup stored values.

Compiled output is stored via the [PFND3D12DDI_COMPILER_CACHE_STORE_VALUE_CB](#callback-function-pfnd3d12ddi_compiler_cache_store_value_cb) callback.  Check for previously compiled duplicates via the [PFND3D12DDI_COMPILER_CACHE_FIND_VALUE_CB](#callback-function-pfnd3d12ddi_compiler_cache_find_value_cb) callback.  D3D12DDI_COMPILER_CACHE_CALLBACKS are supplied during creation of the plugin compiler object, see [PFND3D12DDI_COMPILER_CREATE_COMPILER](#function-pfnd3d12ddi_compiler_create_compiler)

Compiler is expected to sub-divide objects in an IHV dependent way to support deduplication.  Multiple values may be stored per compile.

This method must not return until all compiled output is stored.

The driver must call [PFND3D12DDI_COMPILER_CACHE_SET_OBJECT_VALUE_KEYS_CB](#callback-function-pfnd3d12ddi_compiler_cache_set_object_value_keys_cb) once before returning to set the values associated with this state object definition.

#### Function: PFND3D12DDI_COMPILER_CALC_PRIVATE_ADD_TO_STATE_OBJECT_SIZE

```c++
typedef SIZE_T (APIENTRY *PFND3D12DDI_COMPILER_CALC_PRIVATE_ADD_TO_STATE_OBJECT_SIZE)(
    D3D12DDI_HCOMPILER hCompiler,
    _In_ const D3D12DDIARG_CREATE_STATE_OBJECT_0054* pCreateStateObject,
    D3D12DDI_HCOMPILERSTATEOBJECT StateObjectToGrowFrom
    );
```

Calculate the size needed for compilers state object implementation when adding to an existing state object.

**Parameters**

*hCompiler*

Handle for plugin compiler object.

*ValueTypeFlags*

Specify which values types to store in the cache session after compilation succeeds.  See [D3D12DDI_COMPILER_VALUE_TYPE_FLAGS](#enumeration-d3d12ddi_compiler_value_type_flags).

*pCreateStateObject*

Creation arguments for the add operation.

*StateObjectToGrowFrom*

The state object being added to.

#### Function: PFND3D12DDI_COMPILER_COMPILE_ADD_TO_STATE_OBJECT

```c++
typedef HRESULT (APIENTRY *PFND3D12DDI_COMPILER_COMPILE_ADD_TO_STATE_OBJECT)(
    D3D12DDI_HCOMPILER hCompiler,
    D3D12DDI_HRTCOMPILERCACHESESSION hrtCompilerCacheSession,
    D3D12DDI_COMPILER_VALUE_TYPE_FLAGS ValueTypeFlags,
    _In_ const D3D12DDIARG_CREATE_STATE_OBJECT_0054* pCreateStateObject,
    D3D12DDI_HCOMPILERSTATEOBJECT StateObjectToGrowFrom,
    D3D12DDI_HCOMPILERSTATEOBJECT hStateObject
    );
```

**Parameters**

*hCompiler*

Handle for plugin compiler object.

*hrtCompilerCacheSession*

The compiler cache session callback handle.  Used with cache operations to find/store values and set the values assocated with the object being compiled.  See [Cache Session Callbacks](#cache-session-callbacks).

*ValueTypeFlags*

Specify which values types to store in the cache session after compilation succeeds.  See [D3D12DDI_COMPILER_VALUE_TYPE_FLAGS](#enumeration-d3d12ddi_compiler_value_type_flags).

*pCreateStateObject*

Creation arguments for the add operation.

*StateObjectToGrowFrom*

The state object being added to.

*hStateObject*

A handle pointing to the pre-allocated space for the compiler object.  Compiler places the object in this allocation.  Compiler places the object in this allocation and uses it to store state to support future AdddtoStateObject calls.

**Remarks**

The lifetime of pAddtoStateObjectArg and the embedded StateObjectToGrowFrom is guaranteed until hStateObject is destroyed; therefore, compiler only needs to store a pointer to this structure to support future AddToStateObject calls.  Compiler must store other state needed for future compilation with hStateObject, such as keys to lookup stored values.

Compiled output is stored via ID3D12CompilerCacheSession::StoreValue.  Check for previously compiled duplicates via ID3D12CompilerCacheSession::FindValue.

Compiler is expected to sub-divide objects in an IHV dependent way to support deduplication.  Multiple values may be stored per compile.

This method must not return until all compiled output is stored.

The driver must call [PFND3D12DDI_COMPILER_CACHE_SET_OBJECT_VALUE_KEYS_CB](#callback-function-pfnd3d12ddi_compiler_cache_set_object_value_keys_cb) once before returning to set the values associated with this state object definition.

#### Function: PFND3D12DDI_COMPILER_DESTROY_STATE_OBJECT

```c++
typedef VOID ( APIENTRY* PFND3D12DDI_COMPILER_DESTROY_STATE_OBJECT )(
    D3D12DDI_HCOMPILER hCompiler,
    D3D12DDI_HCOMPILERSTATEOBJECT hStateObject
    );
```

Destroys a compiler state object handle.

**Parameters**

*hCompiler*

Handle for plugin compiler object.

*hStateObject*

The state object to destroy.

**Remarks**

## Microsoft API

### Function: D3D12CreateCompilerFactory

The initial entry point for a compiler plugin dll.  Creates the factory with interfaces for creating compilers and checking capabilities.

```c++
HRESULT D3D12CreateCompilerFactory(
  [in] PCWSTR pPluginCompilerDllPath,
  [in] REFIID riid,
  [out] void **ppFactory
);
```

**Parameters**

*pPluginCompilerDllPath*

The path to the plugin compiler dll used for this instance of the factory.

*riid*

The globally unique identifier (GUID) for the compiler factory interface.

*ppFactory*

On return, a pointer the compiler factory interface specified by riid.

**Remarks**

Expected return codes (not exhaustive):

| Error Code | Description|
| :----------| :----------|
| S_OK | Success. |
| E_NOINTERFACE | The specified riid is not recognized. |
| E_INVALIDARG | Invalid arguments specified. |
| E_OUTOFMEMORY | Unable to create compiler factory do to memory allocation failure. |
| HRESULT_FROM_WIN32(ERROR_FILE_NOT_FOUND) | pPluginCompilerDllPath does not point to a file. |

### Application Descs and Compiler Targets

### Union: D3D12_VERSION_NUMBER

Describes a version number.  Used to describe the version of the compiler, application profiles, application versions, and engine versions.

```c++
typedef union D3D12_VERSION_NUMBER
{
    UINT64 Version;
    UINT16 VersionParts[4];
} D3D12_VERSION_NUMBER;
```

**Members**

*Version*

A 64 bit encoding of four 16bit values to define a four part version as X.X.X.X.  The most significant 16bits are the first number, the next most significant bits are the second, etc.  

*VersionParts*

A 16 bit array representation of the version number.

### Struct: D3D12_APPLICATION_DESC

```c++
typedef struct D3D12_APPLICATION_DESC
{
    PWSTR pExeFilename;
    PWSTR pName;
    D3D12_VERSION_NUMBER Version;
    PWSTR pEngineName;
    D3D12_VERSION_NUMBER EngineVersion;
} D3D12_APPLICATION_DESC;
```

Metadata to allow the compiler plugin to identify an application.  Information may be used to select an application specific compiler profile when compiling.

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

The name of the game engine used.  Example "Godot", "Unity", "Unreal Engine", etc.  This parameter is optional, but should be provided whenever possible and must be null terminated.  Use nullptr to indicate not applicable.

*EngineVersion*

The version of the engine.  For example, for Godot 4.3, the version would be:

0x0004000300000000

This parameter is requires if pEngineName is non-nullptr.  See [D3D12_VERSION_NUMBER](#union-d3d12_version_number).

**Remarks**

The member pExeFilename is used to help uniquely identify an application, but SODBs and PSDBs generated with this value may be used from other executables within the same application. For usermode drivers and the D3D12 runtime, this value is not guaranteed to match the host executable of the respective dlls.  Applications must use the same pExeFilename string for all of its SODBs, regardless of which executable(s) in the application make use of it.

An application may have multiple SODBs, but the application information must be identical between them.

#### Struct: D3D12_ADAPTER_FAMILY

Describes a compiler by the target adapter family and the adapter family's compiler version.

```c++
typedef struct D3D12_ADAPTER_FAMILY
{
    WCHAR szAdapterFamily[128];
    D3D12_VERSION_NUMBER CompilerVersion;
} D3D12_ADAPTER_FAMILY;
```

**Members**

*szAdapterFamily*

Uniquely identifies an adapter family for a hardware vendor.  

*CompilerVersion*

Compiler version changes signify changes in code generation that potentially impact all applications for an adapter family.  See [D3D12_VERSION_NUMBER](#union-d3d12_version_number).

**Remarks**

An adapter family is a set of adapters that all share the same compiled output.

Versioning Hints: Major/Minor version change for "must" recompile such as security or major fixes.  Build for "should" recompile such as performance.  Revision for less consequential changes that shouldn't invalidate caches.

#### Struct: D3D12_COMPILER_TARGET

```c++
typedef struct D3D12_COMPILER_TARGET
{
    UINT AdapterFamilyIndex;
    UINT64 ABIVersion;
} D3D12_COMPILER_TARGET;
```

**Members**

*AdapterFamilyIndex*

The index of the adapter family to target.  See [D3D12_ADAPTER_FAMILY](#struct-d3d12_adapter_family) and [ID3D12CompilerFactory::EnumerateAdapterFamilies](#method-id3d12compilerfactoryenumerateadapterfamilies).

*ABIVersion*

The target ABIVersion the AdapterFamily.  See Remarks.

**Remarks**

An ABIVersion of zero targets the latest ABIVersion available.

### Struct: D3D12_COMPILER_DATABASE_PATH

Specifies a database path and the value types it stores.

```c++
typedef struct D3D12_COMPILER_DATABASE_PATH
{
    D3D12_COMPILER_VALUE_TYPE_FLAGS Types;
    LPCWSTR pPath;
} D3D12_COMPILER_DATABASE_PATH;
```

**Members**

*Types*

The types stored in pPath.  See [D3D12_COMPILER_VALUE_TYPE_FLAGS](#enumeration-d3d12_compiler_value_type_flags).

*pPath*

A file path specifying the location of a database file.

**Remarks**

Databases store one or more value types.  The types member specifies which value types are stored in pPath.

### Struct: D3D12_COMPILER_CACHE_GROUP_KEY

```c++
typedef struct D3D12_COMPILER_CACHE_GROUP_KEY
{
    [size_is(KeySize), annotation("_Field_size_bytes_full_(KeySize)")] const void* pKey;
    UINT KeySize;
    UINT Version;
} D3D12_COMPILER_CACHE_GROUP_KEY;
```

A structure representing a versioned shader cache group key.

**Members**

*pKey*

A unique sequence of bytes that uniquely identifies the group in the database.

*KeySize*

The size in bytes of pKey.

*Version*

The version number of the cached group.  

**Remarks**

This key is used to match state object definitions in the state object database with the group of cached binaries in the shader cache session.  The database author is expected to rev the version number of a source object anytime its definition changes in a state object database.  

### Struct: D3D12_COMPILER_CACHE_VALUE_KEY

```c++
typedef struct D3D12_COMPILER_CACHE_VALUE_KEY
{
    _Field_size_bytes_full_(KeySize) const void* pKey;
    UINT KeySize;
} D3D12_COMPILER_CACHE_VALUE_KEY;
```

**Members**

*pKey*

A unique sequence of bytes that uniquely identifies an object in the database.

*KeySize*

The size in bytes of pKey.

**Remarks**

Used during cache operations like find and store value to identify a value.

### Struct: D3D12_COMPILER_CACHE_VALUE

A non-const value buffer and buffer size structure for cached values.

```c++
typedef struct D3D12_COMPILER_CACHE_VALUE
{
    [size_is(ValueSize)] void* pValue;
    UINT ValueSize;
} D3D12_COMPILER_CACHE_VALUE;
```

**Members**

*pValue*

A pointer to a member buffer containing the value.

*ValueSize*

The size of the pValue buffer in bytes.

**Remarks**

Used for object code, compiler metadata, debug PDB, and performance data.

### Struct: D3D12_COMPILER_CACHE_TYPED_VALUE

Specifies a value and its type, such as object code, metadata etc.

```c++
typedef struct D3D12_COMPILER_CACHE_TYPED_VALUE
{
    D3D12_COMPILER_CACHE_VALUE_TYPE  Type;
    D3D12_COMPILER_CACHE_VALUE       Value;
} D3D12_COMPILER_TYPED_VALUE;
```

**Members**

*Type*

The type of the value, such as object code, metadata, etc.  See [D3D12_COMPILER_VALUE_TYPE](#enumeration-d3d12_compiler_value_type) for more information on types.

*Value*

The buffer and size for the value.  See [D3D12_COMPILER_CACHE_VALUE](#struct-d3d12_compiler_cache_value).

**Remarks**

Used in API where the compiler may modify the value buffer, such as [ID3D12CompilerCacheSession::FindValue](#method-id3d12compilercachesessionfindvalue).

### Struct: D3D12_COMPILER_CACHE_CONST_VALUE

Specifies a non-const value buffer and buffer size.

```c++
typedef struct D3D12_COMPILER_CACHE_CONST_VALUE
{
    _Field_size_bytes_opt_(ValueSize) const void* pValue;
    SIZE_T ValueSize;
} D3D12_COMPILER_CACHE_CONST_VALUE;
```

**Members**

*pValue*

A const pointer to a member buffer containing the value.

*ValueSize*

The size of the pValue buffer in bytes.

**Remarks**

See also [D3D12_COMPILER_CACHE_TYPED_CONST_VALUE](#struct-d3d12_compiler_cache_typed_const_value).

### Struct: D3D12_COMPILER_CACHE_TYPED_CONST_VALUE

```c++
typedef struct D3D12_COMPILER_CACHE_TYPED_CONST_VALUE
{
    D3D12_COMPILER_CACHE_VALUE_TYPE  Type;
    D3D12_COMPILER_CACHE_CONST_VALUE Value;
} D3D12_COMPILER_CACHE_TYPED_CONST_VALUE;
```

**Members**

*Type*

The type of the value, such as object code, metadata, etc.  See [D3D12_COMPILER_CACHE_VALUE_TYPE](#enumeration-d3d12_compiler_value_type) for more information on types.

*Value*

The const buffer and size for the value.  See [D3D12_COMPILER_CACHE_VALUE](#struct-d3d12_compiler_cache_value).

**Remarks**

Used in API where the compiler may not modify the value buffer, such as [ID3D12CompilerCacheSession::StoreValue](#method-id3d12compilercachesessionstorevalue).

### Callback Function: D3D12CompilerCacheSessionAllocationFunc

An allocation callback to enable a single call to get size and buffer contents.

```c++
typedef void* (__stdcall *D3D12CompilerCacheSessionAllocationFunc  ) (
    size_t SizeInBytes,
    _Inout_Opt_ void* pContext
    );
```

**Parameters**

*SizeInBytes*

 The size in bytes of the requested allocation.

*pContext*

An application defined context pointer.

**Remarks**

Returns a non-nullptr value on success which points to buffer allocation meeting the size requirements.  Allocations must meet the fundamental alignment requirements and be suitably aligned for any object, see std::max_align_t.

Returns nullptr on allocation failure.

This function must not throw uncaught exceptions.

### Callback Function: D3D12CompilerCacheSessionGroupValueKeysFunc

A callback function to for retrieving a valkue key one or more shader cache keys for use with the [ID3D12CompilerCacheSession::FindGroupValueKeys](#method-id3d12compilercachesessionfindgroupvaluekeys) method.

```c++
typedef void (__stdcall *D3D12CompilerCacheSessionGroupValueKeysFunc ) (
    [annotation("_In_")] const D3D12_COMPILER_CACHE_VALUE_KEY* pValueKey,
    [annotation("_Inout_opt_")] void* pContext
    );
```

**Arguments**

*pValueKey*

A value key for a value that is part of the specified group.  The allocations backing these keys are de-allocated and should no longer be accessed once D3D12CompilerCacheSessionGroupValueKeysFunc returns.

*pContext*

An application defined context pointer.

**Remarks**

This function is called once for each value that is part of the group.

This function must not throw uncaught exceptions.  The allocations backing pValueKey and pValueKey->pKey are valid until this function returns.

### Callback Function: D3D12CompilerCacheSessionGroupValuesFunc

A callback function to for retrieving the binary values of each value in a group.  

```c++
typedef void (__stdcall *D3D12CompilerCacheSessionGroupValuesFunc ) (    
    UINT ValueKeyIndex,
    [annotation("_In_")] const D3D12_COMPILER_CACHE_TYPED_CONST_VALUE* pTypedValue,
    [annotation("_Inout_opt_")] void* pContext
    );
```

**Arguments**

*ValueKeyIndex*

An index to indicate the value key this typed value belongs too.  For example, if both OBJECT_CODE and METADATA are requested for each value key, this function is called twice with ValueKeyIndex 0 before incrementing for the next set of values.

*pTypedValue*

Indicates a single value type and value for the callback.  See [D3D12_COMPILER_CACHE_TYPED_CONST_VALUE](#struct-d3d12_compiler_cache_typed_const_value).

*pContext*

An application defined context pointer.

**Remarks**

This function is called once for each value type that is part of the group.  Use ValueKeyIndex to associate value types to the same value key.  

This function must not throw uncaught exceptions.

### Interface: ID3D12CompilerFactory

A factory interface for creating compilers and checking capabilities.

```c++
interface ID3D12CompilerFactory
    : IUnknown
{
    HRESULT EnumerateAdapterFamilies(
        UINT AdapterFamilyIndex,
        _Out_ D3D12_ADAPTER_FAMILY* pAdapterFamily
        );

    HRESULT EnumerateAdapterFamilyABIVersions(
        UINT AdapterFamilyIndex,
        _Inout_ UINT32* pNumABIVersions, 
        _Out_writes_opt_( *pNumABIVersions ) UINT64* pABIVersions
        );

    HRESULT EnumerateAdapterFamilyCompilerVersion(
        UINT AdapterFamilyIndex,
        _Out_ D3D12_VERSION_NUMBER* pCompilerVersion
        );

    HRESULT GetApplicationProfileVersion(
        _In_ const D3D12_COMPILER_TARGET* pTarget,
        _In_ const D3D12_APPLICATION_DESC* pApplicationDesc,
        _Out_ D3D12_VERSION_NUMBER* pApplicationProfileVersion
        );

    HRESULT CreateCompilerCacheSession(
        _In_reads_(NumPaths) const D3D12_COMPILER_DATABASE_PATH* pPaths,
        UINT NumPaths,        
        _In_opt_ const D3D12_COMPILER_TARGET* pTarget,
        _In_opt_ const D3D12_APPLICATION_DESC* pApplicationDesc,
        _In_ REFIID riid, // ID3D12CompilerCacheSession
        _COM_Outptr_ void** ppCompilerCacheSession
        );

    HRESULT CreateCompiler(
        _In_ ID3D12CompilerCacheSession* pCompilerCacheSession,
        _In_ REFIID riid, // ID3D12Compiler
        _COM_Outptr_ void** ppCompiler
        );
};
```

#### Method: ID3D12CompilerFactory::EnumerateAdapterFamilies

Retrieve a list of all adapter families and there versions that are supported by the plugin.

**Parameters**

*AdapterFamilyIndex*

The index of the adapter family to enumerate.

*pAdapterFamily*

The adapter family at Index.  See [D3D12_ADAPTER_FAMILY](#struct-d3d12_adapter_family).

**Remarks**

Example code for enumerate all compilers:

```c++
D3D12_ADAPTER_FAMILY adapterFamily = {};
for (UINT i = 0; pFactory->EnumerateCompilers(i, &adapterFamily) != DXGI_ERROR_NOT_FOUND; 
     ++i) 
{ ... }
```

#### Method ID3D12CompilerFactory::EnumerateAdapterFamilyABIVersions

Retrieve the list of ABI versions supported for an adapter family.

**Parameters**

*AdapterFamilyIndex*

The index of the adapter family to to query for supported ABI versions.  See [D3D12_ADAPTER_FAMILY](#struct-d3d12_adapter_family) and [ID3D12CompilerFactory::EnumerateAdapterFamilies](#method-id3d12compilerfactoryenumerateadapterfamilies).

*pNumABIVersions*

On input, describes the size of pABIVersions.  *pNumABIVersions is zero when pABIVersions is nullptr.  This may be used to retrieve a partial list, see remarks.  On output, returns the number of ABI Versions for pAdapterFamily.

*pABIVersions*

Recieves the list of ABI Versions for pAdapterFamily.  May be nullptr when performing a size check.

**Remarks**

Returns the the compiler ABI version supported by the compiled binaries produced by this compiler.  This is compared with the supported ABI range of a driver to understand if precompiled binaries are supported.

Compiled objects produced by this compiler at a target ABI version may not be used with drivers that do not report this ABI version in their supported ABI version range.

ABI version is used to check for precompiled cache updates and understand cache compatibility with drivers on the client, see [IHV Compiler Plugin](#ihv-compiler-plugin) in the design section.

#### Method ID3D12CompilerFactory::EnumerateAdapterFamilyCompilerVersion

Describes the version of a compiler for an adapter family.

**Parameters**

*AdapterFamilyIndex*

The index of the adapter family to to query for supported ABI versions.  See [D3D12_ADAPTER_FAMILY](#struct-d3d12_adapter_family) and [ID3D12CompilerFactory::EnumerateAdapterFamilies](#method-id3d12compilerfactoryenumerateadapterfamilies).

*pCompilerVersion*

Compiler version changes signify changes in code generation that potentially impact all applications for an adapter family.  See [D3D12_VERSION_NUMBER](#union-d3d12_version_number).

**Remarks**

Version Hints: Major/Minor version change for "must" recompile such as security or major fixes.  Build for "should" recompile such as performance.  Revision for less consequential changes that shouldn't invalidate caches.

#### Method: ID3D12CompilerFactory::GetApplicationProfileVersion

Compilers may have an application dependent profile or settings.

**Parameters**

*pTarget*

Describes the adapter family and ABI version to target.  Specify zero for ABIVersion to default to the latest supported ABI Version.  See [D3D12_COMPILER_TARGET](#struct-d3d12_compiler_target).

*pApplicationDesc*

Describes the target application and version.  See [D3D12_APPLICATION_DESC](#struct-d3d12_application_desc).

*pApplicationProfileVersion*

Returns the profile version which describes the version of the compiler profile that targets a specific application.  See [D3D12_VERSION_NUMBER](#union-d3d12_version_number).

**Remarks**

The compiler application profile can be versioned when there application specific changes to these profiles that do not impact other applications.  This prevents invalidating caches for all applications when a change is application specific.


#### Method ID3D12CompilerFactory::CreateCompilerCacheSession

**Parameters**

*pPaths*

A list of paths that specify which types of values are stored by this cache session, and which database they should be stored in.  See [D3D12_COMPILER_DATABASE_PATH](#struct-d3d12_compiler_database_path).

*NumPaths*

The number of paths specified in pPaths.

*pTarget*

Describes the adapter family and ABI version to target.  Specify zero for ABIVersion to default to the latest supported ABI Version.  See [D3D12_COMPILER_TARGET](#struct-d3d12_compiler_target).

*pApplicationDesc*

Describes the target application and version.  See [D3D12_APPLICATION_DESC](#struct-d3d12_application_desc).

*riid*

The globally unique identifier (GUID) for the compiler cache session interface. See [ID3D12CompilerCacheSession](#interface-id3d12compilercachesession).

*ppCompilerCacheSession*

On return, a pointer the compiler interface specified by riid.

**Remarks**

Database Files:

- If a specified file does not exist, it is created.  If it exists, it is opened for modification.
- Value types may be stored in seperate databases.  For example, PDBs may be stored in a seperate database file than object code.

#### Method ID3D12CompilerFactory::CreateCompiler

Create an instance of a compiler.

**Parameters**

*pCompilerCacheSession*

The cache session where compiled results are stored.  The compiler plugin may also check if objects were previously compiled.  See [ID3D12CompilerCacheSession](#interface-id3d12compilercachesession).

*riid*

The globally unique identifier (GUID) for the compiler interface. See [ID3D12Compiler](#interface-id3d12compiler).

*ppCompiler*

On return, a pointer the compiler interface specified by riid.

**Remarks**

Use [D3D12_APPLICATION_DESC](#struct-d3d12_application_desc) to query the profile version from the compiler plugin with [ID3D12CompilerFactory::GetCompilerApplicationProfileVersion](#method-id3d12compilerfactorygetcompilerapplicationprofileversion).  Compilers may revise this number to indicate application specific changes to compiler output.

### Enumeration: D3D12_COMPILER_VALUE_TYPE

A type enumeration used when only a single value type may be selected.

```c++
typedef enum D3D12_COMPILER_VALUE_TYPE
{
    D3D12_COMPILER_VALUE_TYPE_OBJECT_CODE       = 0,
    D3D12_COMPILER_VALUE_TYPE_METADATA          = 1,
    D3D12_COMPILER_VALUE_TYPE_DEBUG_PDB         = 2,
    D3D12_COMPILER_VALUE_TYPE_PERFORMANCE_DATA  = 3,
} D3D12_COMPILER_VALUE_TYPE;
```

**Constants**

*D3D12_COMPILER_VALUE_TYPE_OBJECT_CODE*

Specifies object code.  The compiled executable code that is run on GPU.

*D3D12_COMPILER_VALUE_TYPE_METADATA*

Metadata that the compiler may provide about the compile.  For example it may store a compiler version number used for validation.  Such a thing should not be put inside of the object code as users of this system expect to be able to do memcmp diffing between compiler versions.  

*D3D12_COMPILER_VALUE_TYPE_DEBUG_PDB*

The Debug PDB for the object code.  Used in pix and other debug scenarios.  An opaque blob that still requires IHV interpretation to used with PIX.

*D3D12_COMPILER_VALUE_TYPE_PERFORMANCE_DATA*

Performance data about the compile or produced object code.  An opaque blob that still requires IHV interpretation to used with PIX.

**Remarks**

Used when defining a typed value, see [D3D12_COMPILER_CACHE_TYPED_VALUE](#struct-d3d12_compiler_cache_typed_value).

### Enumeration: D3D12_COMPILER_VALUE_TYPE_FLAGS

A flags enumeration used where multiple values may be selected.

```c++
typedef enum D3D12_COMPILER_VALUE_TYPE_FLAGS
{ 
    D3D12_COMPILER_VALUE_TYPE_FLAGS_NONE                = 0x00000000,
    D3D12_COMPILER_VALUE_TYPE_FLAGS_OBJECT_CODE         = (1 << D3D12_COMPILER_VALUE_TYPE_OBJECT_CODE),
    D3D12_COMPILER_VALUE_TYPE_FLAGS_METADATA            = (1 << D3D12_COMPILER_VALUE_TYPE_METADATA),
    D3D12_COMPILER_VALUE_TYPE_FLAGS_DEBUG_PDB           = (1 << D3D12_COMPILER_VALUE_TYPE_DEBUG_PDB),
    D3D12_COMPILER_VALUE_TYPE_FLAGS_PERFORMANCE_DATA    = (1 << D3D12_COMPILER_VALUE_TYPE_PERFORMANCE_DATA),

} D3D12_COMPILER_VALUE_TYPE_FLAGS; 
cpp_quote( "DEFINE_ENUM_FLAG_OPERATORS( D3D12_COMPILER_VALUE_TYPE_FLAGS )" )
```

**Constants**

*D3D12_COMPILER_VALUE_TYPE_FLAGS_NONE*

No selected value types.

*D3D12_COMPILER_VALUE_TYPE_FLAGS_OBJECT_CODE*

Specifies that the operation apply to object code.

*D3D12_COMPILER_VALUE_TYPE_FLAGS_DEBUG_PDB*

Specifies that the operation apply to the debug PDB.

*D3D12_COMPILER_VALUE_TYPE_FLAGS_PERFORMANCE_DATA*

Specifies that the operation apply to performance data.

**Remarks**

Used during compilation to indicate if object code or metadata should be stored or if debug pdb and performance data need to be produced and stored.

### Interface: ID3D12Compiler

A compiler interface for compiling state objects into binaries ready for driver/gpu consumption.  Create a compiler with [ID3D12CompilerFactory::CreateCompiler](#method-id3d12compilerfactorycreatecompiler).

```c++
interface ID3D12Compiler
    : IUnknown
{
    HRESULT CompilePipelineState(
        [in] const D3D12_COMPILER_CACHE_GROUP_KEY* pKey,
        UINT GroupVersion,
        D3D12_COMPILER_VALUE_TYPE_FLAGS ValueTypeFlags,
        [in] const D3D12_PIPELINE_STATE_STREAM_DESC* pDesc
        );

    HRESULT CompileStateObject(
        [in] const D3D12_COMPILER_CACHE_GROUP_KEY* pKey,
        UINT GroupVersion,
        D3D12_COMPILER_VALUE_TYPE_FLAGS ValueTypeFlags,
        [in] const D3D12_STATE_OBJECT_DESC* pDesc,
        [in] REFIID riid, // ID3D12CompilerStateObject
        [out, iid_is(riid), annotation("_COM_Outptr_")] void** ppCompilerStateObject
        );

    HRESULT CompileAddToStateObject(
        [in] const D3D12_COMPILER_CACHE_GROUP_KEY* pKey,
        UINT GroupVersion,
        D3D12_COMPILER_VALUE_TYPE_FLAGS ValueTypeFlags,
        [in] const D3D12_STATE_OBJECT_DESC* pAddition,        
        [in] ID3D12CompilerStateObject* pCompilerStateObjectToGrowFrom,
        [in] REFIID riid, // ID3D12CompilerStateObject
        [out, iid_is(riid), annotation("_COM_Outptr_")] void** ppNewCompilerStateObject
        );
};
```

#### Method ID3D12Compiler::CompilePipelineState

Compile a graphics or compute pipeline state.

**Parameters**

*pKey*

A unique key and version that identifies the group. This key is used to store a group with the values produced by this compiled operation.  This group must not already be present in the cache session.

*GroupVersion*

The version number of the cached group.

*ValueTypeFlags*

Specify which values types to store in the cache session after compilation succeeds.  See [D3D12_COMPILER_VALUE_TYPE_FLAGS](#enumeration-d3d12_compiler_value_type_flags).

*pDesc*

The pipeline state desc describing the PSO.  See [D3D12_PIPELINE_STATE_STREAM_DESC](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_pipeline_state_stream_desc).

**Remarks**

Compiled output is stored via [ID3D12CompilerCacheSession::StoreValue](#method-id3d12compilercachesessionstorevalue).

Compiler may sub-divide objects in an IHV dependent way to support deduplication.  Therefore, multiple values may be stored per compile operation. The compiler may also checks for previously compiled values.

The Group Key and Group Version are used to store a group that associates all the values stored for this compilation via [ID3D12CompilerCacheSession::StoreGroupValueKeys](#id3d12compilercachesessionstoregroupvaluekeys).

This method will not return until all compiled output is stored.

Specify storage of object code, debug pdbs, and/or performance data from the compiler with ValueTypeFlags.

#### Method ID3D12Compiler::CompileStateObject

**Parameters**

*pKey*

A unique key and version that identifies the group. This key is used to store a group with the values produced by this compiled operation.  This group must not already be present in the cache session.

*GroupVersion*

The version number of the cached group.

*pDesc*

Creation arguments for the state object.  See [D3D12_STATE_OBJECT_DESC](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_state_object_desc).

*riid*

The globally unique identifier (GUID) for the new state object interface. See [ID3D12CompilerStateObject](#interface-id3d12compilerstateobject).

*ppNewCompilerStateObject*

On return, a pointer the compiler state object interface specified by riid.

**Remarks**

Compiled output is stored via [ID3D12CompilerCacheSession::StoreValue](#method-id3d12compilercachesessionstorevalue).

Compiler is may sub-divide objects in an IHV dependent way to support deduplication.  Therefore, multiple values may be stored per compile. The compiler may also checks for previously compiled duplicates.

The Group Key and Group Version are used to store a group that associates all the values stored for this compilation via [ID3D12CompilerCacheSession::StoreGroupValueKeys](#id3d12compilercachesessionstoregroupvaluekeys).

This method will not return until all compiled output is stored.

This method creates an object that implements [ID3D12CompilerStateObject](#interface-id3d12compilerstateobject) to support using it as a base object when deriving new state objects with [ID3D12Compiler::CompileAddToStateObject](#method-id3d12compilercompileaddtostateobject).

#### Method ID3D12Compiler::CompileAddToStateObject

**Parameters**

*pKey*

A unique key and version that identifies the group. This key is used to store a group with the values produced by this compiled operation.  This group must not already be present in the cache session.

*GroupVersion*

The version number of the cached group.

*pAddition*

Addition arguments to add to pCompilerStateObjectToGrowFrom and create a new state object. See [D3D12_STATE_OBJECT_DESC](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_state_object_desc).

*pCompilerStateObjectToGrowFrom*

The base state object to build from.

*riid*

The globally unique identifier (GUID) for the new state object interface. See [ID3D12CompilerStateObject](#interface-id3d12compilerstateobject).

*ppNewCompilerStateObject*

On return, a pointer the compiler state object interface specified by riid.

**Remarks**

Compiled output is stored via [ID3D12CompilerCacheSession::StoreValue](#method-id3d12compilercachesessionstorevalue).

Compiler is may sub-divide objects in an IHV dependent way to support deduplication.  Therefore, multiple values may be stored per compile. The compiler may also checks for previously compiled duplicates.

This method will not return until all compiled output is stored.

The Group Key and Group Version are used to store a group that associates all the values stored for this compilation via [ID3D12CompilerCacheSession::StoreGroupValueKeys](#id3d12compilercachesessionstoregroupvaluekeys).

This method creates an object that implements [ID3D12CompilerStateObject](#interface-id3d12compilerstateobject) to support using it as a base object when deriving new state objects with [ID3D12Compiler::CompileAddToStateObject](#method-id3d12compilercompileaddtostateobject).

### Interface: ID3D12CompilerCacheSession

A cache session interface that compilers use to store and lookup compiled results, and is the output of a compile operations.  Create a cache session with [ID3D12CompilerFactory::CreateCompilerCacheSession](#method-id3d12compilerfactorycreatecompilercachesession).

```c++
interface ID3D12CompilerCacheSession
    : IUnknown
{
    HRESULT FindGroup(
        _In_ const D3D12_COMPILER_CACHE_GROUP_KEY* pGroupKey,
        _Out_opt_ UINT* pGroupVersion
        );

    HRESULT FindGroupValueKeys(
        _In_ const D3D12_COMPILER_CACHE_GROUP_KEY* pGroupKey,
        _In_opt_ const UINT* pExpectedGroupVersion,
        _In_ D3D12CompilerCacheSessionGroupValueKeysFunc CallbackFunc,
        _Inout_opt_ void* pContext
        );

    HRESULT FindGroupValues(
        _In_ const D3D12_COMPILER_CACHE_GROUP_KEY* pGroupKey,
        _In_opt_ const UINT* pExpectedGroupVersion,
        D3D12_COMPILER_VALUE_TYPE_FLAGS ValueTypeFlags,
        _In_opt_ D3D12CompilerCacheSessionGroupValuesFunc CallbackFunc,
        _Inout_opt_ void* pContext
        );

    HRESULT FindValue(
        _In_ const D3D12_COMPILER_CACHE_VALUE_KEY* pValueKey,
        _Inout_count_(NumTypedValues) D3D12_COMPILER_CACHE_TYPED_VALUE* pTypedValues,
        UINT NumTypedValues,
        _In_opt_ D3D12CompilerCacheSessionAllocationFunc pCallbackFunc,
        _Inout_opt_ void* pContext
        );

    const D3D12_APPLICATION_DESC* GetApplicationDesc();

    D3D12_COMPILER_TARGET GetCompilerTarget();

    D3D12_COMPILER_VALUE_TYPE_FLAGS GetValueTypes();

    HRESULT StoreGroupValueKeys(
        _In_ const D3D12_COMPILER_CACHE_GROUP_KEY* pGroupKey,
        UINT GroupVersion,
        _In_reads_(NumValueKeys) const D3D12_COMPILER_CACHE_VALUE_KEY* pValueKeys,
        UINT NumValueKeys
        );

    HRESULT StoreValue(
        _In_ const D3D12_COMPILER_CACHE_VALUE_KEY* pValueKey,
        _In_reads_(NumTypedValues) const D3D12_COMPILER_CACHE_TYPED_CONST_VALUE* pTypedValues,
        UINT NumTypedValues
        );
};
```

#### Method: ID3D12CompilerCacheSession::FindGroup

Check if a group with pGroupKey is in the database.  Optionally retrieve the version number of the group.

**Arguments**

*pGroupKey*

A unique key and version that identifies the group.

*pGroupVersion*

Specify a non-null pointer to receive the version number of the group.  See remarks.

**Remarks**

Returns S_OK when the group exists and DXGI_ERROR_NOT_FOUND if it does not.

GroupVersion is used to match State Object definitions in an SODB with a group of compiled binaries in a PSDB.  Only one version of a group with a given key may be stored in a PSDB at a time.  

#### Method: ID3D12CompilerCacheSession::FindGroupValueKeys

Looks up a group entry in the cache whose key exactly matches the provided key and version and provides the list of value keys in the group to a callback.

**Arguments**

*pGroupKey*

A unique key and version that identifies the group.

*pExpectedGroupVersion*

Optionally specify the version of the Group specified by pGroupKey expected in the database.  Used to fail early without reading the value keys when the version is not the expected version.  In this case of a version mismatch, DXGI_ERROR_NOT_FOUND is returned.

*CallbackFunc*

A D3D12CompilerCacheSessionGroupValueKeysFunc that is called once for each value key in the group.

*pContext*

An application specified context pointer that is passed to the callback.  Use this to pass parameters to the callback function that receives the value keys.

**Remarks**

DXGI_ERROR_NOT_FOUND is returned if a group with pKey and the appropriate version is not found.  

Use a nullptr callback to determine if the group is present in the cache without actually retrieving the group keys.  This does not guarantee that the value keys are present in the cache, see [ID3D12CompilerCacheSession::FindGroupValues](#method-id3d12compilercachesessionfindgroupvalues).

#### Method: ID3D12CompilerCacheSession::FindGroupValues

Looks up a group entry in the cache whose key exactly matches the provided key and version and provides the list of values in the group to a callback.

**Arguments**

*pGroupKey*

A unique key and version that identifies the group.

*pExpectedGroupVersion*

Optionally specify the version of the Group specified by pGroupKey expected in the database.  Used to fail early without reading the values when the version is not the expected version.  In this case of a version mismatch, DXGI_ERROR_NOT_FOUND is returned.

*ValueTypeFlags*

Specify which values are retrieved from the cache session and passed to the D3D12CompilerCacheSessionGroupValuesFunc callback.  Types not included in this flags parameter are nullptr arguments to the callback.  Used as a performance optimization to prevent retrieval of unused values.  See [D3D12_COMPILER_VALUE_TYPE_FLAGS](#enumeration-d3d12_compiler_value_type_flags).

*CallbackFunc*

A D3D12CompilerCacheSessionGroupValuesFunc that is called once for each typed value in the group.

*pContext*

An application specified context pointer that is passed to the callback.  Use this to pass parameters to the callback function that receives the values.

**Remarks**

DXGI_ERROR_NOT_FOUND is returned if a group with pKey and the appropriate version is not found.

This method provides equivalent results to calling [ID3D12CompilerCacheSession::FindGroupValueKeys](#method-id3d12compilercachesessionfindgroupvaluekeys) and then calling [ID3D12CompilerCacheSession::FindValue](#method-id3d12compilercachesessionfindvalue) for each key.  Using this method allows for lookup optimizations to directly retrieve the values from the backing database.

Use a nullptr callback to determine if the group and it's values are present in the cache without actually retrieving the values.

#### Method: ID3D12CompilerCacheSession::FindValue

Find a previously stored value in the cache.

**Parameters**

*pValueKey*

A unique sequence of bytes that uniquely identifies an object in the database.

*pTypedValues*

An array of typed values to retrieve the size or values of during the operation.  The array size is specified by NumTypedValues.  See [D3D12_COMPILER_CACHE_TYPED_VALUE](#struct-d3d12_compiler_cache_typed_value).

*NumTypedValues*

The number of typed values in the pTypedValues array.

*pCallbackFunc*

An optional callback function for allocating value buffers.  See Remarks.

*pContext*

An application specified context pointer that is passed to the callback.  Use this to pass parameters to the allocation callback function.

**Remarks**

Each D3D12_COMPILER_CACHE_TYPED_VALUE has a D3D12_COMPILER_CACHE_VALUE.  On input, each D3D12_COMPILER_CACHE_VALUE ValueSize member specifies the size in bytes of the buffer pointed to by pValue. Use zero when querying size or using the allocation callback. On output, the ValueSize member is assigned the size of the value.

When Value is Found, for each D3D12_COMPILER_CACHE_VALUE that is not a nullptr:

- If the ValueSize member is a non-zero value, the pValue member must point to a buffer of that size.  If ValueSize is greater than or equal to the value's actual size, the value is copied to pValue and the ValueSize member is assigned the actual size of the value.  If the caller specified ValueSize is insufficient, DXGI_ERROR_MORE_DATA is returned and the required size is assigned to the ValueSize member.
- If the ValueSize member is zero and pCallbackFunc is non-nullptr and the pValue member is non-nullptr, pCallbackFunc is called to allocate a buffer and the value is copied into it.  The allocated buffer pointer returned by pCallbackFunc is assigned to the pValue member on return. If pCallbackFunc returns nullptr, the call fails and returns E_OUTOFMEMORY.
- The ValueSize member is assigned the value's actual size before returning.

To determine if a particular value type is stored without retrieving the value, use a size check for the value. To perform a size check, use a nullptr pValue with a zero ValueSize for the types to query and a nullptr pCallbackFunc.  A return value of S_OK indicates the value is cached.  A return value of DXGI_ERROR_NOT_FOUND indicates a value with that key is not cached.  ValueSize is non-zero for a cached value type.

Example using D3D12CompilerCacheSessionAllocationFunc to retrieve values:

```c++

const char testKey[] = "TestKey";

const D3D12_COMPILER_CACHE_VALUE_KEY valueKey = { testKey, sizeof(testKey) };
D3D12_COMPILER_CACHE_TYPED_VALUE values[] = { {D3D12_COMPILER_VALUE_TYPE_OBJECT_CODE, {} }, {D3D12_COMPILER_VALUE_TYPE_METADATA, {} } };

HRESULT hr = pCompilerCacheSession->FindValue(
    &valueKey, 
    &values, 
    ARRAYSIZE(values),
    [](size_t SizeInBytes, _Inout_Opt_ void* /*pContext*/){return malloc(SizeInBytes);},
    nullptr // No calling context needed
    );

if (SUCCEEDED(hr))
{
    // ObjectCode and Metadata contain pointer and size to the corresponding value.
}

// Use delete that corresponds with allocation even when FindValue does not succeed.  For example, the first 
// allocation may have succeeded, but a subsequent call to the allocation function may have failed resulting 
// in FindValue returning E_OUTOFMEMORY.
free(values[0].Value.pValue);
free(values[1].Value.pValue);
```

#### Method: ID3D12CompilerCacheSession::GetApplicationDesc

Gets the application desc for this cache session.

```c++
const D3D12_APPLICATION_DESC* GetApplicationDesc();
```

**Remarks**

This information is stored in the database.

The returned value (and contained strings) have the same lifetime as the ID3D12CompilerCacheSession cache session object.

#### Method: ID3D12CompilerCacheSession::GetCompilerTarget

Gets the Compiler Target used with this cache session.

```c++
D3D12_COMPILER_TARGET GetCompilerTarget();
```

**Remarks**

This information is stored in the database.

#### Method: ID3D12CompilerCacheSession::GetValueTypes

Reflects the value types used to create the cache session.

```c++
D3D12_COMPILER_VALUE_TYPE_FLAGS GetValueTypes();
```

#### Method: ID3D12CompilerCacheSession::StoreValue

Add a key/value pair to the compiler cache.

**Parameters**

*pValueKey*

A unique sequence of bytes that uniquely identifies an object in the database.

*pTypedValues*

An array of typed values to store.  The array size is specified by NumTypedValues.  See [D3D12_COMPILER_CACHE_TYPED_CONST_VALUE](#struct-d3d12_compiler_cache_typed_const_value).

*NumTypedValues*

The number of values in the pTypedValues array.

**Remarks**

At least one value must be stored in the store operation, so the function returns E_INVALIDARG if pValues nullptr or NumValues is zero. Each value must have a non-zero size.  Only one value per type may be stored at a time.

This api returns DXGI_ERROR_ALREADY_EXISTS if one of the non-nullptr values with pKey already exists.

#### ID3D12CompilerCacheSession::StoreGroupValueKeys

Stores a group of value keys in the cache.

**Arguments**

*pGroupKey*

A unique key and version that identifies the group.

*GroupVersion*

The version number of the cached group.

*pValueKeys*

An array of variable size keys in the group.  Individual key size is specified in the pValueKeySizes parallel array.

*NumValueKeys*

The number of value keys in the group.

**Remarks**

This method does not check if the value keys in the group are present in the database.

Group keys are application local.  It is only required that each state objects group key is unique to the application.  Each group has a Group Version that is revised to indicate the corresponding state object with this key has changed.  When PSDBs are generated, this version number is stored with the group of cached binaries for this group.  The D3D12 runtime compares these version numbers for match before using a cached binary.  Applications using explicit APIs for creating state objects from caches only need to specify the ID.  This enables applications to change state object definitions in an SODB without modifying the code creating state objects.

Only one group with this key may be stored.  You cannot store multiple versions of a group in a single PSDB.

### Interface: ID3D12CompilerStateObject

```c++
interface ID3D12CompilerStateObject
    : IUnknown
{
};
```

## Microsoft Compiler EXE

An executable host named D3D12StateObjectCompiler.exe is also available for convenience. It can load IHV plugins and drive the state object compiler COM API, iterating over entries of an SODB. Its command line interface looks like:

```
Usage: D3D12StateObjectCompiler.exe [OPTIONS] COMMAND

Options:
  -h,--help                         Print this help message and exit

Commands:
  compile                           Compile a State Object Database(SODB) into a Precompiled Shader Database(PSDB).
  replay                            Replay a State Object Database(SODB) to the D3D12 device on the target adapter.
  list                              List all adapter families from a plugin and/or installed adapters.
```

### Compile

The compile command takes an SODB and produces a PSDB using an IHV compiler plugin. The IHV plugin can come from an explicit path, with an explicit adapter family target, or these can be inferred from a compiler registered with a currently-installed GPU driver.

```
Usage: D3D12StateObjectCompiler.exe compile [OPTIONS] sodb output

Positional Arguments:
  sodb <file>                       Input State Object Database.
  output <string>                   Output Precompiled Shader Database for object code and compiler metadata.

Options:
  -h,--help                         Print this help message and exit
  --show-info-queue                 Show ID3D12InfoQueue messages.
  --key <string> [""]               Compile only a single state object by specifying the key in the SODB.
  --single-threaded                 Run single-threaded.
  --psos,--no-psos{false}           Include PSOs in compilation.
  --state-objects,--no-state-objects{false}
                                    Include state objects (collections, raytracing, executable) in compilation.
  --add-to-state-objects,--no-add-to-state-objects{false}
                                    Include state object additions in compilation.
  --pdb <new file> [""]             Output Precompiled Shader Database for shader PDBs.
  --perf <new file> [""]            Output Precompiled Shader Database for hardware-sepecific performance information.


Compiler Plugin (Choose 1):
  --plugin <file>                   Hardware-specific compiler plugin to use.
  --adapter <uint>                  Use a local adapter's compiler plugin


Compiler Target:
  --adapter-family <string>         Specify Adapter Family by name or index.
  --abi <uint> [0]                  ABI version of the adapter family to target.  Default[0]: use the latest ABI.


Application Desc:
  --name <string>                   Application Name
  --exe-filename <string>           Application Exe Filename
  --app-version <uint> [0x0]        Application Version
  --engine <string>                 Game Engine
  --engine-version <uint> [0x0]     Game Engine Version
```

### Replay

The replay command iterates over an SODB and feeds the entries to a D3D12 device.

```
Usage: D3D12StateObjectCompiler.exe replay [OPTIONS] sodb

Positional Arguments:
  sodb <file>                       Input State Object Database.

Options:
  -h,--help                         Print this help message and exit
  --show-info-queue                 Show ID3D12InfoQueue messages.
  --key <string> [""]               Compile only a single state object by specifying the key in the SODB.
  --single-threaded                 Run single-threaded.
  --psos,--no-psos{false}           Include PSOs in compilation.
  --state-objects,--no-state-objects{false}
                                    Include state objects (collections, raytracing, executable) in compilation.
  --add-to-state-objects,--no-add-to-state-objects{false}
                                    Include state object additions in compilation.
  --experimental                    Enable experimental shader models.


Adapter Selection (Required):
  --adapter <uint>                  The adapter to use with D3D12.


Application Desc:
  --name <string>                   Application Name
  --exe-filename <string>           Application Exe Filename
  --app-version <uint> [0x0]        Application Version
  --engine <string>                 Game Engine
  --engine-version <uint> [0x0]     Game Engine Version
```

### List

List can be run to either list the current adapters in the system, or to list the adapter families that can be targeted by a compiler plugin. If an application description is provided, the application profile version can be listed as well.

```
Usage: D3D12StateObjectCompiler.exe list [OPTIONS]

Options:
  -h,--help                         Print this help message and exit
  --plugin <string>                 List Adapter Families available as compile targets.
  --adapters                        List adapters installed on the system for replay targets.


Application Desc:
  --name <string>                   Application Name
  --exe-filename <string>           Application Exe Filename
  --app-version <uint> [0x0]        Application Version
  --engine <string>                 Game Engine
  --engine-version <uint> [0x0]     Game Engine Version
```
