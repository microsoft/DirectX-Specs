# Problem definition
The state object compiler is a tool based off of the D3D codebase which provides similar affordances for feature capability querying, and API -> DDI translation for complex structures like state objects, but without the full D3D12 runtime or kernel dependencies. It does that without creating a D3D12 device, and is expected to work without a driver being available. It is meant to work with an IHV compiler plugin separate from the driver.

The current runtime API/DDI design is dependent on driver handles. To help the compiler work without those dependencies some change are needed for the way we express PSO/SO API and DDI structs.

For the PSO creation struct the root signature subobject expects type ID3D12RootSignature which is dependent on ID3D12DeviceChild as shown below:
 ```cpp
[ uuid( c54a6b66-72df-4ee8-8be5-a946a1429214 ), object, local, pointer_default( unique ) ]
interface ID3D12RootSignature
    : ID3D12DeviceChild
{
}
 ```

 Root signature creation usually looks like:

```cpp
CComPtr<ID3D12RootSignature> rootSignature;

CD3DX12_ROOT_SIGNATURE_DESC descRootSignature;
descRootSignature.Init(0, nullptr, 0, nullptr, flags);

CComPtr<ID3DBlob> signature;
CComPtr<ID3DBlob> error;
VERIFY_SUCCEEDED(D3D12SerializeRootSignature(&descRootSignature, D3D_ROOT_SIGNATURE_VERSION_1, &signature, &error));
VERIFY_SUCCEEDED(Device->CreateRootSignature(0 /*node mask*/, signature->GetBufferPointer(), signature->GetBufferSize(), IID_PPV_ARGS(&rootSignature)));
```

The compiler host doesn't create a device as a result can't use the existing ID3D12RootSignature structure that can be used with `D3D12_PIPELINE_STATE_STREAM_DESC` which is passed in to the compiler host CompilePipelineState API.

```cpp
 HRESULT CompilePipelineState(
        [in] const D3D12_COMPILER_CACHE_SESSION_GROUP_KEY* pKey,
        D3D12_COMPILER_VALUE_TYPE_FLAGS ValueTypeFlags,
        [in] const D3D12_PIPELINE_STATE_STREAM_DESC* pDesc
        );
```

What are the options to fix this issue:
- Solution 1: Create a new subobject type that can be used in D3D12_PIPELINE_STATE_STREAM_DESC which only contains the root signature desc. Since D3D12_PIPELINE_STATE_STREAM_DESC is also used in the runtime then enable the used of that new subobject by the runtime API as well.
- Solution 2: To avoid adjusting D3D12_PIPELINE_STATE_STREAM_DESC add the serialized root signature as a new input to compiler host APIs. This solution can probably work for PSO but not SO desc since for state objects setting a root signature a bit more complicated, there are a lot of layers to a state object and a root signature can be set using different types of objects.
- Solution 3: Create a new base class that an ID3D12RootSignature gets cast to in the compiler. The issue with this is we don't want the compiler to use ID3D12RootSignature interface since there is no device attached. The compiler host doesn't want to have a dependency on d3d12core.
- Solution 4: Version D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_ROOT_SIGNATURE and CD3DX12_PIPELINE_STATE_STREAM_ROOT_SIGNATURE so that it expects the root signature pointer to be an IUnknown pointer instead of an ID3D12RootSignature. Create a separate root signature interface in the compiler host that inherits from IUnknown (ID3D12CompilerRootSignature) to remove the dependency on d3d12core and adds a create method.  The runtime and the compiler host QI for their respective implementations.

For simplicity solution 1 is the choice, there is no confusion on the root signature pointer type needed to be used for runtime vs compiler host and the change is limited to the PSO/SO desc.

# Solution

For the compiler host to be able to compile PSO/SO from the SODB, we need to be able to save the root signature as a desc and then pass it in to the IHV compiler where the root signature will be used for PSO/SO compilation. A new subobject type is introduced for PSO stream which is `D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_SERIALIZED_ROOT_SIGNATURE` and for SOs it is `D3D12_STATE_SUBOBJECT_TYPE_SERIALIZED_ROOT_SIGNATURE`. The compiler host uses a new DDI struct to pass the new subobject desc to the driver which is described in the compiler host spec.

To keep things consitent for the runtime and the compiler the new subobject type will be supported in the runtime for creating a PSO/SO. The runtime will create the root signature object pointer on behalf of the app and pass it on to the driver.

## Runtime support for the new subobject type

###Changes to subobject types
```cpp
typedef enum D3D12_PIPELINE_STATE_SUBOBJECT_TYPE
{
    .....
    D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_SERIALIZED_ROOT_SIGNATURE, // D3D12_SERIALIZED_ROOT_SIGNATURE_DESC
}

```

Changes to D3D12_STATE_SUBOBJECT_TYPE
```cpp
typedef enum D3D12_STATE_SUBOBJECT_TYPE
{
    .....
    D3D12_STATE_SUBOBJECT_TYPE_SERIALIZED_ROOT_SIGNATURE, // D3D12_SERIALIZED_ROOT_SIGNATURE_DESC
}

```

### D3D12_SERIALIZED_ROOT_SIGNATURE_DESC
```cpp
typedef struct D3D12_SERIALIZED_ROOT_SIGNATURE_DESC
{
_Field_size_bytes_full_(SerializedBlobSizeInBytes)  const void *pSerializedBlob;
SIZE_T SerializedBlobSizeInBytes;
} 	D3D12_SERIALIZED_ROOT_SIGNATURE_DESC;
```

The new way to define it will be:
```cpp

CD3DX12_ROOT_SIGNATURE_DESC descRootSignature;
descRootSignature.Init(0, nullptr, 0, nullptr, flags);

 struct MyPSOStream
 {
     CD3DX12_PIPELINE_STATE_STREAM_VS VS{D3D12_SHADER_BYTECODE{g_vs_fullscreenquad, sizeof(g_vs_fullscreenquad)}};
     CD3DX12_PIPELINE_STATE_STREAM_PRIMITIVE_TOPOLOGY Topology{D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE};
     D3D12_SERIALIZED_VERSIONED_ROOT_SIGNATURE_DESC RootSigDesc;

    MyPSOStream(CD3DX12_VERSIONED_ROOT_SIGNATURE_DESC* pRS) {
        CComPtr<ID3DBlob> signature;
        CComPtr<ID3DBlob> error;
        VERIFY_SUCCEEDED(D3D12SerializeRootSignature(pRS, pRS->Version, &signature, &error));

        RootSigDesc.pSerializedBlob = signature.p;
        RootSigDesc.Version = pRS->Version;
    }
 } PSODesc(descRootSignature);
```

### How to handle having multiple root signature subobjects in the PSO/SO

If the PSO/SO definition has both an ID3D12RootSignature and a D3D12_SERIALIZED_ROOT_SIGNATURE_DESC it will be considered an error. Root signature definition using D3D12_SERIALIZED_ROOT_SIGNATURE_DESC is equivalent to using ID3D12RootSignature; which means it is treated with the same precedent when resolving which root signature is getting used for a PSO/SO.

## Root signature getters

To make the use of the new subobject make more sense, new APIs will be get the root signature for a given PSO or for a state object program or ray tracing state object.The root signature can then be used when setting the command list or when creating other PSO/SO.

**These are pending for a future revision of the API**

### Pipeline state object getter

Below is the function signature that will be added to the new d3d12 pipeline state interface:

```cpp
ID3D12PipelineState1 : public ID3D12PipelineState
{
public:
    virtual HRESULT STDMETHODCALLTYPE GetRootSignature( 
        REFIID riid,
        _COM_Outptr_  void **ppvRootSignature) = 0;
    
};
```

### State object root signature getters

Below are the function signatures that will be added to the new d3d12 state object properties interface:
```cpp
ID3D12StateObjectProperties2 : public ID3D12StateObjectProperties1
{
public:
    virtual HRESULT STDMETHODCALLTYPE GetGlobalRootSignatureForProgram( 
        LPCWSTR pProgramName,
        REFIID riid,
        _COM_Outptr_  void **ppvRootSignature) = 0;
    
    virtual HRESULT STDMETHODCALLTYPE GetGlobalRootSignatureForShader( 
        LPCWSTR pExportName,
        REFIID riid,
        _COM_Outptr_  void **ppvRootSignature) = 0;
    
};
```