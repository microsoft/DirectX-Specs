# D3D12 API Extensions

## Overview
Direct3D has a long history of coherent and stable APIs with abstractions which strike a balance between exposing hardware features efficiently and maintaining application compatibility across hardware 
and software generations. However, the stability of the API comes with two main compromises:

- <b>Agility</b>: 
    
    Care must be taken when designing features so that all hardware vendors can support them and some features must be omitted entirely as broad hardware support is not possible. 
    This care takes time as a full cycle of discussions must take place between IHVs, ISVs and Microsoft before an new API can be committed to, developed and distributed. 
    The end result is that hardware features can take years before they are addressable by developers and then there is a further delay as market penetration of new hardware takes place.
    Some D3D features can take years to go from ideation to availability for developers.
    
- <b>Performance</b>:

     The abstraction of the D3D APIs can introduce overhead as hardware concepts are not always a 100% match to API concepts and some hardware features can remain dark as it's impossible or impractical to enable them
     with a broad API.

It is clear that it would be desirable for D3D to enable a path for rapid iteration and prototyping between ISVs and IHVs as well as enabling the exposure of expensive and risky (from an IHV's point of view)
hardware features whilst maintaining the value proposition of stability and portability that D3D provides.

This document proposes a new concept of API Extensions with the aims of addressing the above.

## API Extensions in D3D12

To enable the identified scenarios a new concept will be added to the API centered around a new D3D12 interface: `ID3D12Extension`. This interface provides a standardized method for interacting with driver/device specified extensions while still enabling the D3D12 runtime to moderate these interactions so that it can maintain the coherence and predictability in that API that developers have come to expect. 

To allow the runtime to interop with API extensions it has no advance knowledge of, a schema system will be defined whereby the driver enumerates the extensions APIs it supports as well as describing their interfaces. It's not expected that application developers will use the extension schema directly as it is primarily a mechanism for the D3D runtime and tooling.

Core to the design of the extension mechanism is the ability for PIX to be fully supported and for extensions to 'just work' with PIX without the need for extensive implementation to be done by driver developers. The schema mechanism will be used for this purpose as well as careful API design and guidelines.

It's expected that extension developers will distribute their extensions to application developer partners via C\C++ header file (or equivalent if using a different language), essentially describing the same information conveyed in the schema in a more convenient form for development. Extensions will be identified via a unique GUID which should also be distributed application developers.

## Shader Extensions

IHV specific extensions to GPU shading languages such as HLSL are equally as important to prototyping and unlocking features of GPUs as API extension. This specification will only focus on the API side with the shader side of extensions being detailed in a dedicated document.

## Extension Schema Specification

To standardize extension schema definitions a JSON description will be used. This JSON will be provided by the driver to the D3D runtime during application execution via new DDI functions.

The expected JSON schema layout is as follows:

### Root Object
- **name**: (string) The name of the extension. (The extension identifier GUID is *not* duplicated in the schema — the runtime knows the ID from the `REFIID` passed to `CreateExtension` / `GetExtensionSchema`.)

### Enums
- **enums**: (array, optional) A list of enumeration definitions.
    - **name**: (string) The name of the enumeration.
    - **values**: (array) The named integer values for the enumeration. Each entry has:
        - **name**: (string) The name of the value.
        - **value**: (integer) The integer value.

### Creation Arguments
- **creation_args**: (array, optional) A list of arguments required for creating the extension. May be omitted by extensions that have no creation-time private arguments.
    - **name**: (string) The name of the argument.
    - **type**: (string) The type of the argument (e.g., "enumeration").
    - **blob_byte_offset**: (integer) The byte offset of the argument in the creation argument blob.
    - **byte_size**: (integer) The size of the argument in bytes.
    - **enum_type**: (string, optional) The name of the enumeration type if the argument is an enumeration.

### Extension APIs
- **extension_apis**: (array) A list of extension API definitions.
    - **name**: (string) The name of the extension API.
    - **ExtensionOrdinal**: (integer) The ordinal value representing the extension function (passed as `ordinal` to `ID3D12Extension::Execute`).
    - **PixPluginAnalysisOridinal**: (integer) The ordinal value for PIX plugin analysis. `-1` indicates no PIX plugin analysis is associated with this API.
    - **d3d_object_args**: (array, optional) A list of D3D object arguments passed via `D3D12_EXTENSION_ARGUMENTS::ppD3DObjects`.
        - **name**: (string) The name of the D3D object argument.
        - **type**: (string) The type of the D3D object (e.g., "ID3D12GraphicsCommandList").
        - **required**: (boolean) Whether the argument is required.
        - **array_index**: (integer) The index of the argument in the `ppD3DObjects` array.
    - **d3d_execution_object_index**: (integer, optional) Index into `d3d_object_args` identifying the "executing" object (e.g. the command list the call is recorded into). Used by PIX and the runtime to scope tracking of the call.
    - **private_args**: (array, optional) A list of private arguments packed into `D3D12_EXTENSION_ARGUMENTS::pPrivateArgs`.
        - **name**: (string) The name of the private argument.
        - **type**: (string) The type of the private argument (e.g., "uint", "enumeration").
        - **blob_byte_offset**: (integer) The byte offset of the argument in the private argument blob.
        - **byte_size**: (integer) The size of the argument in bytes.
        - **enum_type**: (string, optional) The name of the enumeration type if the argument is an enumeration.
    - **OutputBufferSize**: (integer, optional) The required size in bytes of `D3D12_EXTENSION_ARGUMENTS::pOutputBuffer` for this API. When present, the runtime / debug layer can validate the caller's output buffer size before forwarding the call.

## Interface Changes

### `D3D12_EXTENSION_ARGUMENTS`

`D3D12_EXTENSION_ARGUMENTS` packages the arguments for both extension creation (`ID3D12DeviceApiExtensions::CreateExtension`) and extension execution (`ID3D12Extension::Execute`). It deliberately separates:

* **D3D object references** (`ppD3DObjects` / `NumD3DObjects`) so that the runtime can unwrap them to driver handles and PIX can track them.
* **A flat private-argument blob** (`pPrivateArgs` / `PrivateArgSize`) whose layout is described by the extension's schema.
* **An optional output buffer** (`pOutputBuffer` / `OutputBufferSize`) so that extension APIs can return data back to the caller (e.g. an `HRESULT` or a `UINT64` result).

```c++
typedef struct D3D12_EXTENSION_ARGUMENTS
{
    ID3D12DeviceChild** ppD3DObjects;
    UINT                NumD3DObjects;
    const void*         pPrivateArgs;
    SIZE_T              PrivateArgSize;
    void*               pOutputBuffer;
    SIZE_T              OutputBufferSize;
} D3D12_EXTENSION_ARGUMENTS;
```

> **Note:** an earlier revision of this spec defined separate flat-parameter signatures for `Execute` and `CreateExtension`. Both have since been consolidated to take a `const D3D12_EXTENSION_ARGUMENTS*` so the argument set can be evolved without breaking the interface, and so that extensions can return data via the new output buffer.

### Interface Definition: `ID3D12Extension`

```c++
    MIDL_INTERFACE("b5db626a-4411-41ec-9168-385a358ba2d6")
    ID3D12Extension : public ID3D12DeviceChild
    {
    public:
        virtual HRESULT STDMETHODCALLTYPE Execute(
            _In_ UINT32 ordinal,
            _In_ const D3D12_EXTENSION_ARGUMENTS* pArguments) = 0;
    };
```
#### Methods

`Execute`
- <b>Description</b>: Executes an extension function.

- <b>Parameters</b>:
    - `UINT32 ordinal`: Numeric value representing the extension sub-function to execute.
    - `const D3D12_EXTENSION_ARGUMENTS* pArguments`: D3D objects, private argument blob, and optional output buffer for the call. The contents must match the extension's schema for the given ordinal.
- <b>Return Type</b>: `HRESULT`. `S_OK` on success; `E_INVALIDARG` if the schema-described argument layout (including output buffer size) does not match; other error codes as appropriate for the extension.

- <b>Remarks</b>:

    Executes an extension function based on the provided function ordinal and argument structure. D3D objects are separated into their own array (`D3D12_EXTENSION_ARGUMENTS::ppD3DObjects`) to allow the D3D runtime to efficiently convert from the application-facing interface to the driver's DDI handle for each object. This separation also enables PIX to efficiently track and capture extension parameter usage. After unwrapping the API objects and executing basic argument validation using the provided schema, the runtime forwards the call to the driver via `PFND3D12DDI_EXECUTEEXTENSION_0115`.

#### Usage
The `ID3D12Extension` interface allows for rapid iteration and prototyping between ISVs and IHVs, enabling the exposure of hardware features
while maintaining the stability and portability of the D3D API. This interface is designed to be compatible with PIX, ensuring that extension
usage can be captured, replayed, and analyzed effectively.

A key design requirement to enable PIX interactions with extensions is that the private arguments are a 'flat' buffer i.e. they do not contain pointers to other locations
in memory. This restriction allows PIX to capture and replay extension API calls.

### Interface Definition: `ID3D12DeviceApiExtensions`

#### Overview
`ID3D12DeviceApiExtensions` is a standalone interface obtained from an `ID3D12Device` via `QueryInterface`. It exposes the extension entry points (schema lookup, extension creation, and extended object creation) without requiring a bump of the `ID3D12DeviceN` version. Devices on drivers that do not implement extensions simply do not expose this interface.

```c++
    MIDL_INTERFACE("de178544-1537-41b9-b12e-48608896d469")
    ID3D12DeviceApiExtensions : public IUnknown
    {
    public:
        virtual HRESULT STDMETHODCALLTYPE GetExtensionSchema(
            _In_    REFIID  ExtensionID,
            _Inout_ LPSTR*  ppSchema,
            _Inout_ UINT*   pSchemaLength) = 0;

        virtual HRESULT STDMETHODCALLTYPE CreateExtension(
            _In_         REFIID                            ExtensionID,
            _In_         const D3D12_EXTENSION_ARGUMENTS*  pCreationArguments,
            _In_         REFIID                            riid,
            _COM_Outptr_ void**                            ppvExtension) = 0;

        virtual HRESULT STDMETHODCALLTYPE ExecuteExtendedObjectCreation(
            _In_ const D3D12_EXTENDED_OPERATION_DATA*      pOperationData) = 0;
    };
```

#### Methods

`GetExtensionSchema`
- <b>Description</b>: Returns the JSON schema describing the methods, arguments, output buffers, and enums of an extension.
- <b>Parameters</b>:
    - `REFIID ExtensionID`: The unique identifier of the extension.
    - `LPSTR* ppSchema`: Out parameter. On success, receives a pointer to a runtime-managed JSON string. The buffer is owned by the runtime and must not be freed by the caller.
    - `UINT* pSchemaLength`: Out parameter. On success, receives the length in characters (including the trailing NUL) of the schema string.
- <b>Return Type</b>: `HRESULT`
    - `S_OK`: The schema was successfully retrieved.
    - `E_NOINTERFACE`: The extension ID is unknown or not supported.
    - Other error codes as appropriate.

- <b>Remarks</b>:

    The returned JSON string describes the extension methods available on the interface, their arguments, and how they should be interpreted (see [Extension Schema Specification](#extension-schema-specification)). This is mostly uninteresting for application developers as the extension schema should be detailed in an official C/C++ header file or library provided by the extension author; however, the schema is essential for PIX compatibility and Debug Layer usage.

`CreateExtension`

- <b>Description</b>: Creates an extension object for the given extension ID using the supplied creation arguments.
- <b>Parameters</b>:
    - `REFIID ExtensionID`: The unique identifier of the extension to create. Provided by the extension author.
    - `const D3D12_EXTENSION_ARGUMENTS* pCreationArguments`: Creation-time D3D objects, private creation argument blob, and optional output buffer. The contents must match the extension's `creation_args` (if any) in the schema.
    - `REFIID riid`: The interface ID of the extension to retrieve (typically `__uuidof(ID3D12Extension)`).
    - `void** ppvExtension`: Address of a pointer that receives the created extension object.
- <b>Return Type</b>: `HRESULT`
    - `S_OK`: The extension was successfully created.
    - `E_NOINTERFACE`: The extension ID is unknown or not supported.
    - Other error codes as appropriate.

- <b>Remarks</b>:

    The `CreateExtension` method allows applications to create API extensions provided by the driver. The description of the extension — its definition, ID, arguments and functionality — should be provided by the extension author to the application developer directly and to the D3D Runtime and PIX via the schema.

    As with `ID3D12Extension::Execute`, the private creation arguments should be a flat buffer and any referenced D3D objects should be split out and passed via `D3D12_EXTENSION_ARGUMENTS::ppD3DObjects`.

`ExecuteExtendedObjectCreation`

- <b>Description</b>: Performs an extended D3D object creation operation that may have one or more attached `ID3D12Extension` instances participating in the creation. See [Extended Object Creation](#extended-object-creation) for the full list of supported operations and the per-operation argument structures.
- <b>Parameters</b>:
    - `const D3D12_EXTENDED_OPERATION_DATA* pOperationData`: Describes the operation, the attached extensions, and the operation-specific arguments.
- <b>Return Type</b>: `HRESULT` reflecting the underlying creation operation.

## Syntactic Sugar
To provide a more natural interface for the developer to access a given extension it is recommended that the extension developers provide helper functions which wrap the D3D12 extension interfaces and
take care of some of the implementation details (packaging D3D objects into the array, packing the private-arg blob, supplying the output buffer for return values, etc.).

For example:
```c++
    static UINT64 ExtensionTest0(_In_ ID3D12Extension* pExtension,
        _In_ ID3D12GraphicsCommandList* pCommandList,
        _In_ ID3D12Resource* pRsrc,
        _In_ UINT Arg0,
        _In_ UINT64 Arg1,
        _In_ UINT Arg2)
    {
        ID3D12DeviceChild* ppObjects[] = { pCommandList, pRsrc };
        D3D12_WARP_EXTENSION_TEST_0_ARGS Args = { Arg0, Arg1, Arg2 };

        UINT64 result = 0;

        D3D12_EXTENSION_ARGUMENTS execArgs = {
            ppObjects,
            _countof(ppObjects),
            &Args,
            sizeof(Args),
            &result,
            sizeof(result) };

        pExtension->Execute(D3D12_WARP_EXTENSION_TEST_0, &execArgs);

        return result;
    }
```

## Extension Example

The example below mirrors the canonical WARP test extension (`Warp12Extension_SmokeTest`). Note that:

- The schema's `name` field carries only the human-readable extension name. The identifier GUID comes from the C++ `__declspec(uuid(...))` on the struct and is passed to `CreateExtension` / `GetExtensionSchema` as a `REFIID`.
- The helper packs everything into a single `D3D12_EXTENSION_ARGUMENTS` and uses `pOutputBuffer` to retrieve a `UINT64` return value from `Execute`.

``` c++
struct __declspec(uuid("1a6389b8-d0d9-4dca-bcee-55979fb90274")) Warp12Extension_SmokeTest
{
    enum EXTENSION_ORDINALS
    {
        D3D12_WARP_EXTENSION_TEST_0 = 0,
    };

    enum TEST_ENUM
    {
        TEST_ENUM_0 = 0,
        TEST_ENUM_1 = 1,
        TEST_ENUM_2 = 2,
    };

    struct D3D12_WARP_EXTENSION_TEST_0_ARGS
    {
        UINT Arg0;
        UINT64 Arg1;
        UINT Arg2;
        TEST_ENUM EnumArg;
    };

    static const UINT64 cExtensionTest0HappyValue = 0x1234567890ABCDEFLL;

    static UINT64 ExtensionTest0(_In_ ID3D12Extension* pExtension,
        _In_ ID3D12GraphicsCommandList* pCommandList,
        _In_ ID3D12Resource* pRsrc,
        _In_ UINT Arg0,
        _In_ UINT64 Arg1,
        _In_ UINT Arg2)
    {
        ID3D12DeviceChild* ppObjects[] = { pCommandList, pRsrc };

        D3D12_WARP_EXTENSION_TEST_0_ARGS Args = { Arg0, Arg1, Arg2 };

        UINT64 result = 0;

        D3D12_EXTENSION_ARGUMENTS execArgs = {
            ppObjects,
            _countof(ppObjects),
            &Args,
            sizeof(Args),
            &result,
            sizeof(result) };

        pExtension->Execute(D3D12_WARP_EXTENSION_TEST_0, &execArgs);

        return result;
    }
};
```

#### Schema Example:
```JSON
{
    "name" : "Warp12Extension_SmokeTest",
    "enums" : [
        {
            "name" : "TEST_ENUM",
            "values" : [
                { "name" : "TEST_ENUM_0", "value" : 0 },
                { "name" : "TEST_ENUM_1", "value" : 1 },
                { "name" : "TEST_ENUM_2", "value" : 2 }
            ]
        }
    ],

    "extension_apis" : [
        {
            "name" : "ExtensionTest0",
            "ExtensionOrdinal" : 0,
            "PixPluginAnalysisOridinal" : -1,
            "d3d_object_args" : [
                {
                    "name" : "pCommandList",
                    "type" : "ID3D12GraphicsCommandList",
                    "required" : true,
                    "array_index" : 0
                },
                {
                    "name" : "pRsrc",
                    "type" : "ID3D12Resource",
                    "required" : true,
                    "array_index" : 1
                }
            ],
            "private_args" : [
                {
                    "name" : "Arg0",
                    "type" : "uint",
                    "blob_byte_offset" : 0,
                    "byte_size" : 4
                },
                {
                    "name" : "Arg1",
                    "type" : "uint64",
                    "blob_byte_offset" : 4,
                    "byte_size" : 8
                },
                {
                    "name" : "Arg2",
                    "type" : "uint",
                    "blob_byte_offset" : 16,
                    "byte_size" : 4
                },
                {
                    "name" : "EnumArg",
                    "type" : "enumeration",
                    "blob_byte_offset" : 20,
                    "byte_size" : 4,
                    "enum_type" : "TEST_ENUM"
                }
            ]
        }
    ]
}
```

#### Output-buffer-only extension example

An extension API may take no D3D objects and no private args at all, using only an output buffer to return data. The schema declares the required size via `OutputBufferSize` on the API entry:

``` c++
struct __declspec(uuid("2dc4931e-4c63-4d4a-b5f5-0ed75b59cdb4")) Warp12Extension_ResourceExtender
{
    enum EXTENSION_ORDINALS
    {
        GET_LAST_RESOURCE_CREATION_RESULT = 0,
    };

    static HRESULT GetLastResourceCreationResult(_In_ ID3D12Extension* pExtension)
    {
        HRESULT hr = S_OK;

        D3D12_EXTENSION_ARGUMENTS execArgs = {};
        execArgs.pOutputBuffer = &hr;
        execArgs.OutputBufferSize = sizeof(hr);

        pExtension->Execute(GET_LAST_RESOURCE_CREATION_RESULT, &execArgs);

        return hr;
    }
};
```

With the corresponding schema:

```JSON
{
    "name" : "Warp12Extension_ResourceExtender",
    "extension_apis" : [
        {
            "name" : "GetLastResourceCreationResult",
            "ExtensionOrdinal" : 0,
            "PixPluginAnalysisOridinal" : -1,
            "OutputBufferSize" : 4
        }
    ]
}
```

## Extension Enablement Policy

In order to preserve the ecosystem stability and compatibility benefits that D3D provides, not all extensions will be enabled by default on end user's hardware. The implementation of 
`CreateExtension` method in the D3D runtime will behave differently depending on if the device is in Windows Developer Mode or not. 

- If Developer mode is enabled and the application called `D3D12EnableExperimentalFeatures` prior to device creation then all extensions will be accessible 
and the runtime will simply forward the creation and execution calls to the user mode driver. 

- If Developer Mode is *not* enabled then the runtime will first check the extension ID
passed in at creation time against a list of known good and approved extensions.

<b><<TODO>TODO:> Work with the rest of SIGMA to determine what the extension policy should be, how extensions will be 'blessed' etc.</b>

## DDI Changes

To enable driver-side support of extensions, the DDIs below are added to the D3D12 device DDI table. They live under the `D3D12DDI_FEATURE_API_EXTENSIONS_EXPERIMENT` feature, gated by the `D3D12DDI_FEATURE_VERSION_API_EXTENSIONS_EXPERIMENT_0115_0` version, and require a usermode DDI of at least `D3D12DDI_SUPPORTED_0115`.

``` c++
// Feature versioning
#define D3D12DDI_FEATURE_VERSION_API_EXTENSIONS_EXPERIMENT_NONE   0u
#define D3D12DDI_FEATURE_VERSION_API_EXTENSIONS_EXPERIMENT_0115_0 1u

// Driver-side extension handle
D3D10DDI_H( D3D12DDI_HEXTENSION )

// Handle wrapper used by the runtime when associating an extension with
// other driver objects (e.g. a state object subobject).
struct D3D12DDI_API_EXTENSION_0114
{
    D3D12DDI_HEXTENSION hApiExtension;
};

// DDI-side equivalent of D3D12_EXTENSION_ARGUMENTS. D3D objects have
// already been unwrapped by the runtime to driver handles by the time
// the call reaches the driver.
typedef struct D3D12DDI_EXTENSION_ARGS_0115
{
    HANDLE*     pDriverHandles;
    UINT        NumDriverHandles;
    const void* pPrivateData;
    SIZE_T      PrivateDataSize;
    void*       pOutputBuffer;
    SIZE_T      OutputBufferSize;
} D3D12DDI_EXTENSION_ARGS_0115;

typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALCPRIVATEEXTENSIONSIZE_0115 )(
    _In_ D3D12DDI_HDEVICE,
    _In_ REFIID ExtensionID,
    _In_ CONST D3D12DDI_EXTENSION_ARGS_0115* );

typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATEEXTENSION_0115 )(
    _In_ D3D12DDI_HDEVICE,
    _In_ REFIID ExtensionID,
    _In_ CONST D3D12DDI_EXTENSION_ARGS_0115*,
    _In_ D3D12DDI_HEXTENSION );

typedef HRESULT ( APIENTRY* PFND3D12DDI_GETEXTENSIONSCHEMA_0115 )(
    _In_    REFIID ExtensionID,
    _Inout_ LPSTR* ppSchema,
    _Inout_ UINT* pSchemaLength );

typedef VOID ( APIENTRY* PFND3D12DDI_DESTROYEXTENSION_0115 )(
    _In_ D3D12DDI_HDEVICE,
    _In_ D3D12DDI_HEXTENSION );

typedef HRESULT ( APIENTRY* PFND3D12DDI_EXECUTEEXTENSION_0115 )(
    _In_ D3D12DDI_HDEVICE,
    _In_ D3D12DDI_HEXTENSION,
    _In_ UINT32 ordinal,
    _In_ CONST D3D12DDI_EXTENSION_ARGS_0115* );

typedef struct D3D12DDI_API_EXTENSIONS_EXPERIMENT_FUNCS_0115
{
    PFND3D12DDI_CALCPRIVATEEXTENSIONSIZE_0115  pfnCalcPrivateExtensionSize;
    PFND3D12DDI_CREATEEXTENSION_0115           pfnCreateExtension;
    PFND3D12DDI_GETEXTENSIONSCHEMA_0115        pfnGetExtensionSchema;
    PFND3D12DDI_DESTROYEXTENSION_0115          pfnDestroyExtension;
    PFND3D12DDI_EXECUTEEXTENSION_0115          pfnExecuteExtension;
} D3D12DDI_API_EXTENSIONS_EXPERIMENT_FUNCS_0115;

// Runtime -> driver callback the driver may use to discover the
// extensions associated with a given driver object handle (for example,
// to look up the extensions attached to a state object during state
// object creation).
typedef _Check_return_ HRESULT(APIENTRY CALLBACK *PFND3D12DDI_GETEXTENSIONSFOROBJECT_CB)(
    _In_    D3D12DDI_HRTDEVICE   hRTDevice,
    _In_    HANDLE               hDriverObject,
    _Inout_ D3D12DDI_HEXTENSION* pExtensions,
    _Inout_ UINT*                pNumExtensions );

typedef struct D3D12DDI_API_EXTENSIONS_CALLBACKS_0119
{
    PFND3D12DDI_GETEXTENSIONSFOROBJECT_CB pfnGetExtensionsForObjectCb;
} D3D12DDI_API_EXTENSIONS_CALLBACKS_0119;
```


## Function Definitions

### `PFND3D12DDI_CALCPRIVATEEXTENSIONSIZE_0115`
- **Description**: Calculates the size of the driver private data the runtime should allocate before calling `pfnCreateExtension`.
- **Parameters**:
    - `D3D12DDI_HDEVICE`: Handle to the device.
    - `REFIID ExtensionID`: Identifier of the extension being created.
    - `CONST D3D12DDI_EXTENSION_ARGS_0115*`: Creation-time arguments (driver-handle array, private creation blob, optional output buffer).
- **Return Type**: `SIZE_T` — the size in bytes of the private data required for the extension.

### `PFND3D12DDI_CREATEEXTENSION_0115`
- **Description**: Creates an extension instance.
- **Parameters**:
    - `D3D12DDI_HDEVICE`: Handle to the device.
    - `REFIID ExtensionID`: Identifier of the extension being created.
    - `CONST D3D12DDI_EXTENSION_ARGS_0115*`: Creation-time arguments.
    - `D3D12DDI_HEXTENSION`: Handle to the storage previously sized via `pfnCalcPrivateExtensionSize`. The driver constructs its per-extension state into this handle.
- **Return Type**: `HRESULT`
    - `S_OK`: The extension was successfully created.
    - `E_NOINTERFACE`: The extension ID is unknown or not supported.
    - Other error codes as appropriate.

### `PFND3D12DDI_GETEXTENSIONSCHEMA_0115`
- **Description**: Retrieves the JSON schema for an extension. The driver allocates and owns the schema string for the lifetime of the device; the runtime caches the pointer.
- **Parameters**:
    - `REFIID ExtensionID`: Extension identifier.
    - `LPSTR* ppSchema`: Out parameter. Driver sets this to a pointer to its (driver-owned) JSON schema string.
    - `UINT* pSchemaLength`: Out parameter. Driver sets this to the length in characters (including the trailing NUL) of the schema string.
- **Return Type**: `HRESULT`
    - `S_OK`: The schema was successfully retrieved.
    - `E_NOINTERFACE`: The extension ID is unknown or not supported.
    - Other error codes as appropriate.
- **Usage**: Single-call. The driver returns a pointer to its own string and its length; the runtime does not allocate a buffer. Note that there is no `D3D12DDI_HDEVICE` parameter — schema is per-extension-ID, not per-device.

### `PFND3D12DDI_DESTROYEXTENSION_0115`
- **Description**: Destroys an extension instance previously created via `pfnCreateExtension`.
- **Parameters**:
    - `D3D12DDI_HDEVICE`: Handle to the device.
    - `D3D12DDI_HEXTENSION`: Handle to the extension.
- **Return Type**: `VOID`

### `PFND3D12DDI_EXECUTEEXTENSION_0115`
- **Description**: Executes an extension sub-function.
- **Parameters**:
    - `D3D12DDI_HDEVICE`: Handle to the device.
    - `D3D12DDI_HEXTENSION`: Handle to the extension.
    - `UINT32 ordinal`: Numeric value representing the extension sub-function to execute.
    - `CONST D3D12DDI_EXTENSION_ARGS_0115*`: Driver-handle array, private argument blob, and optional output buffer for the call.
- **Return Type**: `HRESULT` reflecting the result of the extension call.

### `PFND3D12DDI_GETEXTENSIONSFOROBJECT_CB`
- **Description**: Runtime callback the driver may invoke during the creation of another driver object to discover which `ID3D12Extension` instances the application has associated with that object. The canonical use case is state object creation: when the driver processes a `D3D12_STATE_SUBOBJECT_TYPE_API_EXTENSION` subobject (or a creation operation supplied via `ExecuteExtendedObjectCreation`), it calls back to get the list of extension handles participating in that creation.
- **Parameters**:
    - `D3D12DDI_HRTDEVICE hRTDevice`: Runtime device handle.
    - `HANDLE hDriverObject`: The driver-side object handle whose attached extensions should be queried.
    - `D3D12DDI_HEXTENSION* pExtensions`: On input, points to a driver-allocated buffer that will receive the extension handles. May be `nullptr` on the size-query call.
    - `UINT* pNumExtensions`: On input, capacity of the `pExtensions` buffer; on output, the number of extensions populated (or required, on the size-query call).
- **Return Type**: `HRESULT`

## Extended Object Creation

Some D3D12 object creation APIs need to participate with extensions — for example, an IHV may provide an extension which an application can use to manually determine a swizzle pattern or compression scheme to use for a specific resource based on insight derived from tooling, experimentation or consultation with IHV developer relations teams.

Rather than threading an `ID3D12Extension**` array through every existing creation API (which would require new struct variants for each, plus matching DDIs), the API exposes a single entry point — `ID3D12DeviceApiExtensions::ExecuteExtendedObjectCreation` — that takes a tagged union of creation operations. Each variant in the union mirrors the arguments of an existing creation method, and the surrounding `D3D12_EXTENDED_OPERATION_DATA` adds the extension array that participates in the creation.

> This supersedes an earlier design which proposed adding `NumExtensions` / `ppExtensions` fields to `D3D12_RESOURCE_DESC_NEXT`. That approach is *not* used by the shipping implementation.

### `D3D12_EXTENDED_OPERATION_TYPE`

```c++
typedef enum D3D12_EXTENDED_OPERATION_TYPE
{
    D3D12_EXTENDED_OPERATION_TYPE_CREATE_COMMITTED_RESOURCE2 = 0,
    D3D12_EXTENDED_OPERATION_TYPE_CREATE_COMMITTED_RESOURCE3 = 1,
    D3D12_EXTENDED_OPERATION_TYPE_CREATE_COMMITTED_RESOURCE4 = 2,
    D3D12_EXTENDED_OPERATION_TYPE_CREATE_PLACED_RESOURCE1    = 3,
    D3D12_EXTENDED_OPERATION_TYPE_CREATE_PLACED_RESOURCE2    = 4,
    D3D12_EXTENDED_OPERATION_TYPE_CREATE_PLACED_RESOURCE3    = 5,
    D3D12_EXTENDED_OPERATION_TYPE_CREATE_RESERVED_RESOURCE1  = 6,
    D3D12_EXTENDED_OPERATION_TYPE_CREATE_RESERVED_RESOURCE2  = 7,
} D3D12_EXTENDED_OPERATION_TYPE;
```

Each value identifies which creation variant is described by the operation. Per-variant argument structs (e.g. `D3D12_EXTENDED_OPERATION_CREATE_COMMITTED_RESOURCE3 { pHeapProperties, HeapFlags, pDesc, InitialResourceLayout, pOptimizedClearValue, pProtectedSession, NumCastableFormats, pCastableFormats, iidResource, ppvResource }`) mirror the arguments of the underlying `ID3D12DeviceN::Create...Resource...` method.

### `D3D12_EXTENDED_OPERATION_DATA`

```c++
typedef struct D3D12_EXTENDED_OPERATION_DATA
{
    ID3D12Extension**             ppExtensions;
    UINT                          NumExtensions;
    D3D12_EXTENDED_OPERATION_TYPE OperationType;
    union
    {
        D3D12_EXTENDED_OPERATION_CREATE_COMMITTED_RESOURCE2 CreateCommittedResource2;
        D3D12_EXTENDED_OPERATION_CREATE_COMMITTED_RESOURCE3 CreateCommittedResource3;
        D3D12_EXTENDED_OPERATION_CREATE_COMMITTED_RESOURCE4 CreateCommittedResource4;
        D3D12_EXTENDED_OPERATION_CREATE_PLACED_RESOURCE1    CreatePlacedResource1;
        D3D12_EXTENDED_OPERATION_CREATE_PLACED_RESOURCE2    CreatePlacedResource2;
        D3D12_EXTENDED_OPERATION_CREATE_PLACED_RESOURCE3    CreatePlacedResource3;
        D3D12_EXTENDED_OPERATION_CREATE_RESERVED_RESOURCE1  CreateReservedResource1;
        D3D12_EXTENDED_OPERATION_CREATE_RESERVED_RESOURCE2  CreateReservedResource2;
    };
} D3D12_EXTENDED_OPERATION_DATA;
```

The `ppExtensions` array carries the `ID3D12Extension` instances participating in the creation (e.g. an IHV-specific compression-mode extension). When the driver processes the creation, it may use the runtime callback `PFND3D12DDI_GETEXTENSIONSFOROBJECT_CB` to retrieve the corresponding driver-side extension handles.

This addresses the earlier open question (*"should there be a type of extension which is defined to only be a 'mutation' of a D3D object?"*): the answer is that "object-mutation" extensions are first-class via this mechanism — the extension's effect on the created object is fully described by the schema and the private-arg blob carried on each `ID3D12Extension` instance attached to the operation.


## State Object Integration

In addition to the per-resource extension hooks described above, extensions can participate in state object creation. A new state subobject type, `D3D12_STATE_SUBOBJECT_TYPE_API_EXTENSION`, allows an `ID3D12Extension` instance to be attached as a subobject of a state object (e.g. a raytracing pipeline state object). This lets extensions influence or supplement state object compilation without requiring per-state-object-type plumbing for each new extension.

### `D3D12_STATE_SUBOBJECT_TYPE_API_EXTENSION`

A new entry is added to `D3D12_STATE_SUBOBJECT_TYPE`:

```c++
typedef enum D3D12_STATE_SUBOBJECT_TYPE
{
    // ... existing entries ...
    D3D12_STATE_SUBOBJECT_TYPE_API_EXTENSION = 35, // D3D12_API_EXTENSION_DESC
    // ... existing entries ...
} D3D12_STATE_SUBOBJECT_TYPE;
```

The `pDesc` field of the `D3D12_STATE_SUBOBJECT` for this type points to a `D3D12_API_EXTENSION_DESC`, which carries a reference to an `ID3D12Extension` previously created via `ID3D12DeviceApiExtensions::CreateExtension`:

```c++
typedef struct D3D12_API_EXTENSION_DESC
{
    ID3D12Extension* pExtension;
} D3D12_API_EXTENSION_DESC;
```

Like other subobjects, `D3D12_STATE_SUBOBJECT_TYPE_API_EXTENSION` may participate in `D3D12_STATE_SUBOBJECT_TYPE_SUBOBJECT_TO_EXPORTS_ASSOCIATION` / `D3D12_STATE_SUBOBJECT_TYPE_DXIL_SUBOBJECT_TO_EXPORTS_ASSOCIATION` to scope an attached extension to specific exports rather than applying call-graph-wide.

When the driver processes the state object, it can call back via `PFND3D12DDI_GETEXTENSIONSFOROBJECT_CB` to retrieve the driver-side `D3D12DDI_HEXTENSION` handles for the extensions attached to the (sub-)object being created.

### `CD3DX12_API_EXTENSION_SUBOBJECT`

To make state object construction ergonomic, a corresponding helper is added to the `d3dx12` state object helpers, following the existing pattern used by helpers such as `CD3DX12_DXIL_LIBRARY_SUBOBJECT` and `CD3DX12_HIT_GROUP_SUBOBJECT`:

```c++
class CD3DX12_API_EXTENSION_SUBOBJECT
    : public CD3DX12_STATE_OBJECT_DESC::SUBOBJECT_HELPER_BASE
{
public:
    CD3DX12_API_EXTENSION_SUBOBJECT() noexcept;
    CD3DX12_API_EXTENSION_SUBOBJECT(CD3DX12_STATE_OBJECT_DESC& ContainingStateObject);

    // Stores a reference to the extension instance that will be attached to the
    // containing state object as a D3D12_STATE_SUBOBJECT_TYPE_API_EXTENSION subobject.
    void SetApiExtension(ID3D12Extension* pExtension) noexcept;
};
```

### Example: Attaching an extension to a raytracing pipeline state object

The example below creates an `ID3D12Extension`, exercises it directly via its `Execute` method (here through a generated helper), and then attaches the same extension instance as a subobject of a raytracing pipeline state object:

```c++
CComPtr<ID3D12Extension> pWarpDummyExtension;

D3D12_EXTENSION_ARGUMENTS extensionArgs = {};

VERIFY_SUCCEEDED(pDeviceExperimental->CreateExtension(
    _uuidof(Warp12Extension_SmokeTest),
    &extensionArgs,
    IID_PPV_ARGS(&pWarpDummyExtension)));

// Call the Extension directly
UINT64 result = Warp12Extension_SmokeTest::ExtensionTest0(
    pWarpDummyExtension, pCommandList, pBuffer, 0, 1, 2);
VERIFY_IS_TRUE(result == Warp12Extension_SmokeTest::cExtensionTest0HappyValue);

// Create a basic state object and pass the extension as a sub-object
{
    // Root Sigs
    CComPtr<ID3D12RootSignature> pLocalRootSig, pGlobalRootSig;
    CreateRootSig(pDevice14, &pLocalRootSig.p, true, 0);
    CreateRootSig(pDevice14, &pGlobalRootSig.p, false, 1);

    CD3DX12_STATE_OBJECT_DESC RTPSO(D3D12_STATE_OBJECT_TYPE_RAYTRACING_PIPELINE);

    D3D12_SHADER_BYTECODE MyAppDxilLib =
        CD3DX12_SHADER_BYTECODE(g_basicRTProgram, sizeof(g_basicRTProgram));

    auto Lib0 = RTPSO.CreateSubobject<CD3DX12_DXIL_LIBRARY_SUBOBJECT>();
    Lib0->SetDXILLibrary(&MyAppDxilLib);

    auto LocalHitGroup = RTPSO.CreateSubobject<CD3DX12_HIT_GROUP_SUBOBJECT>();
    LocalHitGroup->SetHitGroupType(D3D12_HIT_GROUP_TYPE_TRIANGLES);
    LocalHitGroup->SetHitGroupExport(L"hitGroup");
    LocalHitGroup->SetClosestHitShaderImport(L"closesthit_main");
    LocalHitGroup->SetAnyHitShaderImport(L"anyhit_main");

    auto GlobalRootSig = RTPSO.CreateSubobject<CD3DX12_GLOBAL_ROOT_SIGNATURE_SUBOBJECT>();
    GlobalRootSig->SetRootSignature(pGlobalRootSig);

    auto LocalRootSig = RTPSO.CreateSubobject<CD3DX12_LOCAL_ROOT_SIGNATURE_SUBOBJECT>();
    LocalRootSig->SetRootSignature(pLocalRootSig);

    auto ShaderConfig = RTPSO.CreateSubobject<CD3DX12_RAYTRACING_SHADER_CONFIG_SUBOBJECT>();
    ShaderConfig->Config(256, 32);

    auto RaytracingConfig = RTPSO.CreateSubobject<CD3DX12_RAYTRACING_PIPELINE_CONFIG_SUBOBJECT>();
    RaytracingConfig->Config(8);

    auto ExtensionSubObject = RTPSO.CreateSubobject<CD3DX12_API_EXTENSION_SUBOBJECT>();
    ExtensionSubObject->SetApiExtension(pWarpDummyExtension);

    CComPtr<ID3D12StateObject> pRTPSO;
    VERIFY_SUCCEEDED(pDevice14->CreateStateObject(RTPSO, IID_PPV_ARGS(&pRTPSO)));
}
```

The same `ID3D12Extension` instance may be attached to multiple state objects and may also be used directly via its `Execute` method.


## PIX

The following is a list of requirements for PIX to continue to work when extensions are in usage as well as a description of how the proposed design meets those requirements:

1. PIX must be aware of API extension usage and must be able to capture their usage.
    - Funneling all calls through the `ID3D12Extension` interface which PIX is able to shim.
2. PIX must be able to replay extension APIs in the same way the original application called them.
    - Restricting private arguments to being 'flat' buffers, forbidding state mutation and and moving D3D object arguments to their own array.
3. PIX must be able to display at least some basic information about API extensions and their usage as part of it's UI.
    - Requiring the drivers to provide a standardized schema enables PIX to reason about what would otherwise be opaque data.

<b>While not all extensions will require PIX support; particularly those used for rapid prototyping, any extension which is to be considered officially sanctioned by D3D and available in retail scenarios must adhere to the PIX design guidelines and will be subject to API review by Microsoft.</B>


### Design Requirement - No Persistent State Mutation:

An important design requirement for PIX is that D3D object state should not be mutated after creation as this makes capture and playback complicated and inefficient. A better design is to have required
state available at object creation time. For example, consider a theoretical extensions to `ID3D12PipelineState` which overrides the Pixel Shader. It could be imagined that the 
extension interface had a function such as 'SetPixelShader' which mutated the Pixel Shader inside the PSO object and that mutation was inherited down stream. A better design would be to
create an extension of the command list and then provide the Pixel Shader to use as an override at PSO set time. While this setter API mutates the state of the command list during record time, it doesn't persist outside of that i.e. the existing D3D rule of an implicit `ClearState` occurring on command list reset should apply.

## D3D12 Debug Layer

A formal schema can also be used by the D3D12 Debug Layer to provide a level of basic validation for extensions automatically. For example, the schema may outline valid ranges for each private extension argument or even specify invalid interactions between two or more arguments.

TBD how extensive this will be in practice or if perhaps the driver should be more actively involved.


