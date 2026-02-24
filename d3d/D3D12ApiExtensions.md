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
- **name**: (string) The name of the extension.
- **id**: (string) Identifier GUID

### Enums
- **enums**: (array) A list of enumeration definitions.
    - **name**: (string) The name of the enumeration.
    - **value**: (integer) The integer value of the enumeration.

### Creation Arguments
- **creation_args**: (array) A list of arguments required for creating the extension.
    - **name**: (string) The name of the argument.
    - **type**: (string) The type of the argument (e.g., "enumeration").
    - **blob_byte_offset**: (integer) The byte offset of the argument in the creation argument blob.
    - **byte_size**: (integer) The size of the argument in bytes.
    - **enum_type**: (string, optional) The name of the enumeration type if the argument is an enumeration.

### Extension APIs
- **extension_apis**: (array) A list of extension API definitions.
    - **name**: (string) The name of the extension API.
    - **ExtensionOrdinal**: (integer) The ordinal value representing the extension function.
    - **PixPluginAnalysisOridinal**: (integer) The ordinal value for PIX plugin analysis.
    - **d3d_object_args**: (array) A list of D3D object arguments.
        - **name**: (string) The name of the D3D object argument.
        - **type**: (string) The type of the D3D object (e.g., "ID3D12GraphicsCommandList").
        - **required**: (boolean) Whether the argument is required.
        - **array_index**: (integer) The index of the argument in the array of D3D objects.
    - **private_args**: (array) A list of private arguments.
        - **name**: (string) The name of the private argument.
        - **type**: (string) The type of the private argument (e.g., "uint", "enumeration").
        - **blob_byte_offset**: (integer) The byte offset of the argument in the private argument blob.
        - **byte_size**: (integer) The size of the argument in bytes.
        - **enum_type**: (string, optional) The name of the enumeration type if the argument is an enumeration.

## Interface Changes

### Interface Definition: `ID3D12Extension`

```c++
    MIDL_INTERFACE("b5db626a-4411-41ec-9168-385a358ba2d6")
    ID3D12Extension : public ID3D12DeviceChild
    {
    public:
        virtual void STDMETHODCALLTYPE Execute( 
            UINT32 ordinal,
            ID3D12DeviceChild **ppD3DObjects,
            UINT numD3DObjects,
            void *pPrivateArgs,
            SIZE_T privateArgSize) = 0;
    };
```
#### Methods

`Execute`
- <b>Description</b>: Executes an extension function.

- <b>Parameters</b>:
    - `UINT32 ordinal`: Numeric value representing the extension sub-function to execute.
    - `ID3D12DeviceChild **`ppD3DObjects: Array of D3D objects.
    - `UINT numD3DObjects`: Number of D3D objects.
    - `void *pPrivateArgs`: Pointer to a linear blob of private argument data. Must match the schema provided by the extension implementation.
    - `SIZE_T privateArgSize`: Size of the private data in bytes.
- <b>Return Type</b>: `void`

- <b>Remarks</b>:

    Executes an extension function based on the provided function ordinal, D3D objects, and private argument data. D3D Objects are separated into their own array as an argument to allow the D3D runtime to efficiently
    convert from the application facing interface to the driver's DDI handle for the each object. Additionally this also enables PIX to efficiently track and capture extension parameter usage. After unwrapping the API objects and
    executing basic argument validation using the provided schema, the runtime will forward the arguments onto the driver to handle the implementation.

#### Usage
The `ID3D12Extension` interface allows for rapid iteration and prototyping between ISVs and IHVs, enabling the exposure of hardware features 
while maintaining the stability and portability of the D3D API. This interface is designed to be compatible with PIX, ensuring that extension 
usage can be captured, replayed, and analyzed effectively.

A key design requirement to enable PIX interactions with extensions is that the private arguments are a 'flat' buffer i.e. they do not contain pointers to other locations
in memory. This restriction allows PIX to capture and replay extension API calls.

### Interface Definition: `ID3D12Device16`

#### Overview
The `ID3D12Device16` interface extends the `ID3D12Device15` interface to provide support for creating API extensions in Direct3D 12.

```c++
    MIDL_INTERFACE("a8924708-ed60-4f78-93dd-91198c82402f")
    ID3D12Device16 : public ID3D12Device15
    {
    public:
        virtual LPCSTR STDMETHODCALLTYPE GetExtensionSchema(_In_ REFIID ExtensionID) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE CreateExtension( 
            _In_ REFIID ExtensionID,
            _In_ const void *pCreationArgs,
            _In_ SIZE_T CreationArgsSizeBytes,
            _In_ ID3D12DeviceChild **ppD3DObjects,
            _In_ UINT numD3DObjects,
            _In_ REFIID riid,
            _COM_Outptr_  void **ppvExtension) = 0;
    };
```
#### Methods
`GetExtensionSchema`
- <b>Description</b>: Returns a JSON string that describes the extension methods, their arguments, and how they should be interpreted.
- <b>Parameters</b>:
    - `REFIID ExtensionID`: The unique identifier of the extension to create. Provided by the extension author.
- <b>Return Type</b>: `LPCSTR`

- <b>Remarks</b>:

    Returns a structured JSON string that communicates the extension methods available on the interface, along with their arguments and how they should be interpreted. This is mostly uninteresting for application 
    developers as the extension schema should be detailed in an official C/C++ header file or library provided by the extension author; however, the schema is essential for PIX compatibility and Debug Layer usage.

`CreateExtension`

- <b>Description</b>: Creates an extension object based on the provided extension ID and creation arguments.
- <b>Parameters</b>:
    - `REFIID ExtensionID`: The unique identifier of the extension to create. Provided by the extension author.
    - `const void *pCreationArgs`: Pointer to the creation arguments for the extension.
    - `SIZE_T CreationArgsSizeBytes`: Size of the creation arguments in bytes.
    - `ID3D12DeviceChild **`ppD3DObjects: Array of D3D objects.
    - `UINT numD3DObjects`: Number of D3D objects.
    - `REFIID riid`: The interface ID of the extension to retrieve.
    - `void **ppvExtension`: Address of a pointer to the extension object.
- <b>Return Type</b>: HRESULT
    - `S_OK`: The extension was successfully created.
    - `E_NO_INTERFACE`: The extension ID is unknown or not supported.
    - Other error codes as appropriate.

- <b>Remarks</b>:

    The `CreateExtension` method allows applications to create API extensions provided by the driver. The description of the extension i.e. it's definition, I.D., arguments and functionality should
    be provided by the extension author to the application developer directly and to the D3D Runtime and PIX via the schema.

    As with the `Execute` method on the `ID3D12Extension` interface, the private creation arguments should be a flat buffer and any referenced D3D objects should be split out and passed via the `ppD3DObjects`function argument.

## Syntactic Sugar
To provide a more natural interface for the developer to access a given extension it is recommended that the extension developers provide helper functions which wrap the D3D12 extension interfaces and 
take care of some of the implementation details.

For example:
```c++
    static void WarpExtension0(_In_ ID3D12Extension* pExtension,
        _In_ ID3D12GraphicsCommandList* pCommandList,
        _In_ ID3D12Resource* pRsrc,
        _In_ UINT Arg0,
        _In_ UINT64 Arg1,
        _In_ UINT Arg2)
    {
        ID3D12DeviceChild* ppObjects[] = { pCommandList, pRsrc };

        D3D12_WARP_EXTENSION_0_ARGS Args = { Arg0, Arg1, Arg2, WARP_EXTENSION_ENUM_0 };

        pExtension->Execute(D3D12_WARP_EXTENSION_0, ppObjects, ARRAYSIZE(ppObjects), &Args, sizeof(Args));
    }
```

## Extension Example

``` c++
struct __declspec(uuid("1a6389b8-d0d9-4dca-bcee-55979fb90274")) Warp12Extension
{
    enum EXTENSION_ORDINALS
    {
        D3D12_WARP_EXTENSION_0 = 0,
    };

    enum WARP_EXTENSION_ENUM
    {
        WARP_EXTENSION_ENUM_0 = 0,
        WARP_EXTENSION_ENUM_1 = 1,
        WARP_EXTENSION_ENUM_2 = 2,
    };

    struct D3D12_WARP_EXTENSION_0_ARGS
    {
        UINT Arg0;
        UINT64 Arg1;
        UINT Arg2;
        WARP_EXTENSION_ENUM EnumArg;
    };

    static void WarpExtension0(_In_ ID3D12Extension* pExtension,
        _In_ ID3D12GraphicsCommandList* pCommandList,
        _In_ ID3D12Resource* pRsrc,
        _In_ UINT Arg0,
        _In_ UINT64 Arg1,
        _In_ UINT Arg2)
    {
        ID3D12DeviceChild* ppObjects[] = { pCommandList, pRsrc };

        D3D12_WARP_EXTENSION_0_ARGS Args = { Arg0, Arg1, Arg2, WARP_EXTENSION_ENUM_0 };

        pExtension->Execute(D3D12_WARP_EXTENSION_0, ppObjects, ARRAYSIZE(ppObjects), &Args, sizeof(Args));
    }
};
```

#### Schema Example:
```JSON
{
    "name" : "Warp12Extension",
    "id" : "1a6389b8-d0d9-4dca-bcee-55979fb90274",
    "enums" : [
        {
            "name" : "WARP_EXTENSION_ENUM",
            "values" : [
                {
                    "name" : "WARP_EXTENSION_ENUM_0",
                    "value" : 0
                },
                {
                    "name" : "WARP_EXTENSION_ENUM_1",
                    "value" : 1
                },
                {
                    "name" : "WARP_EXTENSION_ENUM_2",
                    "value" : 2
                }
            ]
        }
    ],

    "creation_args" : [
        {
            "name" : "Mode",
            "type" : "enumeration",
            "blob_byte_offset" : 0,
            "byte_size" : 4,
            "enum_type" : "WARP_EXTENSION_ENUM"
        }
    ],

    "extension_apis" : [
        {
            "name" : "WarpExtension0",
            "ExtensionOrdinal" : 0,
            "PixPluginAnalysisOridinal" : -1,
            "d3d_object_args" : [
                {
                    "name" : "pCommandList",
                    "type" : "ID3D12GraphicsCommandList",
                    "required" : true,
                    "array_index" : 0,
                },
                {
                    "name" : "pRsrc",
                    "type" : "ID3D12Resource",
                    "required" : true,
                    "array_index" : 1,
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
                    "blob_byte_offset" : 12,
                    "byte_size" : 4,
                },
                {
                    "name" : "EnumArg",
                    "type" : "enumeration",
                    "blob_byte_offset" : 16,
                    "byte_size" : 4,
                    "enum_type" : "WARP_EXTENSION_ENUM"
                }
            ]
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

To enable driver side support of extensions the following DDIs will be added to the D3D12 device DDI table:

``` c++
D3D10DDI_H( D3D12DDI_HEXTENSION )

typedef struct D3D12DDI_CREATE_EXTENSION_0117
{
    REFIID ExtensionID;
    const void* pPrivateData;
    SIZE_T PrivateDataSize;
} D3D12DDI_CREATE_EXTENSION_0117;

typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALCPRIVATEEXTENSIONSIZE_0117 )(
    D3D12DDI_HDEVICE, _In_ CONST D3D12DDI_CREATE_EXTENSION_0117* );
    
typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATEEXTENSION_0117 )(
    D3D12DDI_HDEVICE, _In_ CONST D3D12DDI_CREATE_EXTENSION_0117*, D3D12DDI_HEXTENSION );

typedef HRESULT ( APIENTRY* PFND3D12DDI_GETEXTENSIONSCHEMA_0117 )(
    D3D12DDI_HDEVICE, _In_ REFIID, _Inout_ UINT* pSchemaLength, _Inout_ LPWSTR pSchema);

typedef VOID ( APIENTRY* PFND3D12DDI_DESTROYEXTENSION_0117 )(
    D3D12DDI_HDEVICE, D3D12DDI_HEXTENSION );

typedef VOID ( APIENTRY* PFND3D12DDI_EXECUTEEXTENSION_0117 )(
    D3D12DDI_HDEVICE, D3D12DDI_HEXTENSION, UINT32 ordinal, HANDLE* pDriverHandles, UINT NumDriverHandles, void* pPrivateArgs, SIZE_T privateArgSize );
```


## Function Definitions

### `PFND3D12DDI_CALCPRIVATEEXTENSIONSIZE_0117`
- **Description**: Calculates the size of the driver private data required for an extension object.
- **Parameters**:
    - `D3D12DDI_HDEVICE`: Handle to the device.
    - `CONST D3D12DDI_CREATE_EXTENSION_0117*`: Pointer to the extension creation structure.
- **Return Type**: `SIZE_T`
    - The size in bytes of the private data required for the extension.

### `PFND3D12DDI_CREATEEXTENSION_0117`
- **Description**: Creates an extension.
- **Parameters**:
    - `D3D12DDI_HDEVICE`: Handle to the device.
    - `CONST D3D12DDI_CREATE_EXTENSION_0117*`: Pointer to the extension creation structure.
    - `D3D12DDI_HEXTENSION`: Handle to the created extension.
- **Return Type**: `HRESULT`
    - `S_OK`: The extension was successfully created.
    - `E_NO_INTERFACE`: The extension ID is unknown or not supported.
    - Other error codes as appropriate.

### `PFND3D12DDI_GETEXTENSIONSCHEMA_0117`
- **Description**: Retrieves the schema for an extension.
- **Parameters**:
    - `D3D12DDI_HDEVICE hDevice`: Handle to the device.
    - `REFIID ExtensionID`: Extension Identifier. 
    - `UINT* pSchemaLength`: Pointer to the length of the schema.
    - `LPCSTR pSchema`: Pointer to the schema string.
- **Return Type**: `HRESULT`
    - `S_OK`: The schema was successfully retrieved.
    - Other error codes as appropriate.
- **Usage**: This DDI will be called twice, the first time `pSchema` will be NULL and it is expected that the driver will return the length in characters of the schema string, storing it in the `pSchemaLength` argument. The runtime will proceed
to allocate storage space and will call this DDI a second time at which point the driver should perform a string copy of it's schema into the `pSchema` buffer.

### `PFND3D12DDI_DESTROYEXTENSION_0117`
- **Description**: Destroys an extension.
- **Parameters**:
    - `D3D12DDI_HDEVICE`: Handle to the device.
    - `D3D12DDI_HEXTENSION`: Handle to the extension.
- **Return Type**: `VOID`

### `PFND3D12DDI_EXECUTEEXTENSION_0117`
- **Description**: Executes an extension function.
- **Parameters**:
    - `D3D12DDI_HDEVICE`: Handle to the device.
    - `D3D12DDI_HEXTENSION`: Handle to the extension.
    - `UINT32 ordinal`: Numeric value representing the extension function to execute.
    - `HANDLE* pDriverHandles`: Array of driver handles.
    - `UINT NumDriverHandles`: Number of driver handles.
    - `void* pPrivateArgs`: Pointer to a linear blob of private argument data.
    - `SIZE_T privateArgSize`: Size of the private data in bytes.
- **Return Type**: `VOID`

## Structure Updates
In addition to the new API interfaces, several D3D12 structures will be revised to enable interop. with extensions, primarily to enable driver specific modifications to D3D objects or concepts at their creation time.
For example an IHV may provide an extension which an application can use to manually determine a swizzle pattern or compression scheme to use for a specific resource based on insight derived from
tooling, experimentation or consultation with IHV developer relations teams. 


### `D3D12_RESOURCE_DESC_NEXT`
```c++
typedef struct D3D12_RESOURCE_DESC_NEXT
{
    D3D12_RESOURCE_DIMENSION Dimension;
    UINT64 Alignment;
    UINT64 Width;
    UINT Height;
    UINT16 DepthOrArraySize;
    UINT16 MipLevels;
    DXGI_FORMAT Format;
    DXGI_SAMPLE_DESC SampleDesc;
    D3D12_TEXTURE_LAYOUT Layout;
    D3D12_RESOURCE_FLAGS Flags;
    D3D12_MIP_REGION SamplerFeedbackMipRegion;
    GUID LayoutGuid;
    UINT NumExtensions; // NEW
    ID3D12Extension **ppExtensions; // NEW
} 	D3D12_RESOURCE_DESC_NEXT;
```

Resource creation and layout queries will now be able to provide and optional array of extensions which can tweak behavior based on the hardware available at execution.

<b><<TODO>TODO:> List all structures that will be updated.</b>

<b><<TODO>TODO:> Should there be a type of extension which is defined to only be a 'mutation' of a D3D object?</b>


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


