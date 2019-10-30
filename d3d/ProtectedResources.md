# D3D12 Protected Resources


## Change History
---
+ Moved to markdown, removed prototype license management and video bitstream decoding.

## Open Issues
---
  |Issue Number | Description |
  |--|--|
  |||
  ---
  

# Overview

This feature introduces protected resources to D3D12 to allow cross API sharing of HW-DRM protected resources.  D3D12 adds Protected Resource Session object that is used when creating heaps, resources, and other objects to indicate they are HWDRM protected or may internally allocate or operate on protected resources.  

The D3D11 flag D3D11_RESOURCE_MISC_HW_PROTECTED on a resource indicates the same protection requirements as a heap/resource created with a protected resource session.  When these objects are cross-api shared, the equivalent exchange between the D3D11 flag and D3D12 protected resource is made.  Hardware must protect these resources from being read by cpu code either through protected memory or encrypted memory.  An operation may read from a combination of protected and unprotected resources, but when it reads from any protected resource the output must be a protected resource.  

The D3D12 protected resource session has a status fence whose fence value is incremented whenever protected content becomes invalid.  Status may be pulled from the protected session.  This typically happens when the system enters a sleep state and wakes back up, but could also be triggered by tamper protection from driver or hardware.

Commandlist interfaces add a SetProtectedResourceSession API that must be set to a non-null protected resource session whenever the output of a subsequent operation would write protected resources.  This enables hardware that may have to generate commands differently to produce correct results with protected resources.  This method mainly enables protected resource support for bindless operations where scanning the bind space for protected resources is prohibitive, but it's usage is required for all command list APIs to support uniform calling patterns.

This spec does not define license negotiation or bitstream decryption for protected video streams.  Microsoft plans to define this at a later date, so this remains a D3D11 scenario for now.  However, protected content decoded in D3D11 may be cross API shared with D3D12 using the formats that support it.  Starting with WDDM 2.4 a driver must report protected resource support in both D3D11 and D3D12 and support cross API sharing, or it must support protected resources in neither API.  D3D12 support required in this way includes all graphics, compute, and copy command list operations.  Video operations are not required.

Beginning with D3D12DDI_FEATURE_VERSION_VIDEO_0072_0 D3D12 video decode, video processing, and Video Encode operations may optionally support protected resources.  Prior versions do not support protected resources with these operations.  Additionally, CreateProtectedResources now accepts a GUID parameter to enable IHV extensions.  A GUID is defined to be equivalent to the original CreateProtectedResourceSession.  Additional guids are controlled by Microsoft via an allow list and require Microsoft approval.  Developer mode disables the allow list to allow extension development or experimentation, but retail scenarios require approval. 

# Test Requirement

Protected resources must be created as hardware protected regardless of the initialization of a DRM scenario.  The D3D11 design originally allowed the D3D11_RESOURCE_MISC_HW_PROTECTED flag to be ignored if a DRM system wasn't initialized.  MSDN has the following note to that effect:

```
Note:
Creating a texture using this flag does not automatically guarantee that hardware protection will be enabled for the underlying allocation. Some implementations require that the DRM components are first initialized prior to any guarantees of protection. 
```

This is no longer valid for D3D11 or D3D12 starting with WDDM 2.4.  Resources must support hardware protection regardless to enable componentized testing.

# Predication Not Supported
Predication is not supported with operations operating on protected resources.

# Protection Type GUID

Starting with D3D12DDI_FEATURE_VERSION_CONTENT_PROTECTION_RESOURCES_0074_0, a ProtectionType GUID is added as a creation parameter for protected resource sessions.  The GUID D3D12_PROTECTED_RESOURCES_SESSION_HARDWARE_PROTECTED is defined to the the equivalent of V1 protected resource sessions.  Cross API sharing of resources and heaps created with this GUID maps to D3D11_RESOURCE_MISC_HW_PROTECTED in D3D11.

Other extensions may be defined for this GUID.  GUIDs are controlled via an allow list and adding additional GUIDS requires Microsoft approval for retail scenarios.  Developer mode may be used to disable this check for private IHV bring-up, testing, and prototypes.

# API

## Protected Sessions

ID3D12ProtectedSession offers base functionality that allows for a consistent way to monitor the validity of a sessions across the different types of sessions. Currently, this is only the ID3D12ProtectedResourceSession.  

### Enum: D3D12_PROTECTED_SESSION_STATUS

```C++
typedef enum D3D12_PROTECTED_SESSION_STATUS
{
    D3D12_PROTECTED_SESSION_STATUS_OK,
    D3D12_PROTECTED_SESSION_STATUS_INVALID,
} D3D12_PROTECTED_SESSION_STATUS;
```

**Constants**

*D3D12_PROTECTED_SESSION_STATUS_OK*  
The protected session is ok.

*D3D12_PROTECTED_SESSION_STATUS_INVALID*  
Protected session status is invalid.


### Interface: ID3D12ProtectedSession
```C++
interface ID3D12ProtectedSession
    : ID3D12DeviceChild
```

#### Method: ID3D12ProtectedSession::GetStatusFence

```c++
HRESULT GetStatusFence(
    [in] REFIID riid,
    [out, iid_is(riid), annotation("_COM_Outptr_opt_")] void** ppFence);
```

Returns the fence for the protected session. From the fence, we can get
the current uniqueness validity value (using GetCompletedValue), and add
monitors for change of its value. This is a read-only fence.

**Parameters**

riid

The GUID of the interface to a fence. Most commonly, ID3D12Fence,
although it may be any GUID for any interface. If the protected session
object doesn't support the interface for this GUID, the getter returns
E_NOINTERFACE.

ppFence

A pointer to a memory block that receives a pointer to the fence for the
given protected session.

#### Method: ID3D12ProtectedSession::GetSessionStatus
```c++
D3D12_PROTECTED_SESSION_STATUS GetSessionStatus();
```

Gets the current status of the protected session.

**Return value**

The status the protected session. If
D3D12_PROTECTED_SESSION_STATUS_INVALID, the user needs to wait for a
status fence value bump to reuse the resource if the session is an
ID3D12ProtectedResourceSession. 

## Protected Resource Sessions

### Enum: D3D12_PROTECTED_RESOURCE_SESSION_FLAGS
```c++
typedef enum D3D12_PROTECTED_RESOURCE_SESSION_FLAGS
{
    D3D12_PROTECTED_RESOURCE_SESSION_FLAG_NONE = 0x0
} D3D12_PROTECTED_RESOURCE_SESSION_FLAGS;
```

Specifies the options for working with protected sessions.

**Constants**

*D3D12_PROTECTED_RESOURCE_SESSION_FLAG_NONE*  
No options are specified.

### Struct: D3D12_PROTECTED_RESOURCE_SESSION_DESC
```c++
typedef struct D3D12_PROTECTED_RESOURCE_SESSION_DESC
{
    UINT NodeMask;
    D3D12_PROTECTED_RESOURCE_SESSION_FLAGS Flags;
} D3D12_PROTECTED_RESOURCE_SESSION_DESC;
```
**Members**

*NodeMask*  
For single GPU operation, set this to zero. If there are multiple GPU nodes, set a bit to identify the node (the device\'s physical adapter) to which the protected session applies. Each bit in the mask corresponds to a single node. Only 1 bit may be set.

*Flags*  
Specifies the supported crypto sessions options.

### Method: ID3D12Device4::CreateProtectedResourceSession

```c++
interface ID3D12Device4 : ID3D12Device3
{
    HRESULT CreateProtectedResourceSession(
        [annotation("_In_")] const D3D12_PROTECTED_RESOURCE_SESSION_DESC* pDesc,
        [annotation("_In_")] REFIID riid, // Expected: ID3D12ProtectedResourceSession, 
        [out, iid_is(riid), annotation("_COM_Outptr_")] void** ppSession
        );
}
```
Creates a protected session for the given parameters. If a non-independent protected session is created, returns a common session for the given node. This session may be used with ID3D12Device::CreateSharedHandle when we need to flow information to other processes, such as the compositor.

**Parameters**

*pDesc*  
A pointer to a D3D12_PROTECTED_RESOURCE_SESSION_DESC structure that describes the session.

*riid*  
The GUID of the interface to a protected session. Most commonly, ID3D12ProtectedResourceSession, although it may be any GUID for any interface. If the protected session object doesn't support the interface for this GUID, the getter will return E_NOINTERFACE.

*ppSession*  
A pointer to a memory block that receives a pointer to the session for
the given protected session.

### Interface: ID3D12ProtectedResourceSession
```c++
interface ID3D12ProtectedResourceSession
    : ID3D12ProtectedSession
```
A protected resource session.  Use an instance when creating heaps, resources, etc. to create protected versions of those objects. 

#### Method: ID3D12ProtectedResourceSession::GetDesc
```c++
D3D12_PROTECTED_RESOURCE_SESSION_DESC GetDesc1();
```
Retrieves the creation properties for the protected resource session. See D3D12_PROTECTED_RESOURCE_SESSION_DESC.

### GUID: D3D12_PROTECTED_RESOURCES_SESSION_HARDWARE_PROTECTED
```c++
DEFINE_GUID(D3D12_PROTECTED_RESOURCES_SESSION_HARDWARE_PROTECTED, ...);
```

Defines a guid equivalent to D3D11_RESOURCE_MISC_HW_PROTECTED.

### Struct: D3D12_PROTECTED_RESOURCE_SESSION_DESC1
```c++
typedef struct D3D12_PROTECTED_RESOURCE_SESSION_DESC1
{
    UINT NodeMask;
    D3D12_PROTECTED_RESOURCE_SESSION_FLAGS Flags;
    GUID ProtectionType;
} D3D12_PROTECTED_RESOURCE_SESSION_DESC1;
```
**Members**

NodeMask

For single GPU operation, set this to zero. If there are multiple GPU nodes, set a bit to identify the node (the device\'s physical adapter) to which the protected session applies. Each bit in the mask corresponds to a single node. Only 1 bit may be set.

*Flags* 
Specifies the supported crypto sessions options.

*ProtectionType* 
The GUID that represents the protection type.  Microsoft defines D3D12_PROTECTED_RESOURCES_SESSION_HARDWARE_PROTECTED.


### Method: ID3D12Device7::CreateProtectedResourceSession1

```c++
interface ID3D12Device7 : ID3D12Device6
{
    HRESULT CreateProtectedResourceSession1(
        [annotation("_In_")] const D3D12_PROTECTED_RESOURCE_SESSION_DESC1* pDesc,
        [annotation("_In_")] REFIID riid, // Expected: ID3D12ProtectedResourceSession, 
        [out, iid_is(riid), annotation("_COM_Outptr_")] void** ppSession
        );
}
```
Creates a protected session for the given parameters. If a non-independent protected session is created, returns a common session for the given node. This session may be used with ID3D12Device::CreateSharedHandle when we need to flow information to other processes, such as the compositor.

**Parameters**

*pDesc*  
A pointer to a D3D12_PROTECTED_RESOURCE_SESSION_DESC1 structure that describes the session.

*riid*  
The GUID of the interface to a protected session. Most commonly, ID3D12ProtectedResourceSession1, although it may be any GUID for any interface. If the protected session object doesn't support the interface for this GUID, the getter will return E_NOINTERFACE.

*ppSession*  
A pointer to a memory block that receives a pointer to the session for
the given protected session.

### Interface: ID3D12ProtectedResourceSession1
```c++
interface ID3D12ProtectedResourceSession1
    : ID3D12ProtectedResourceSession
```
A revision of the protected resource session that allows retrieving the ProtectionType

#### Method: ID3D12ProtectedResourceSession1::GetDesc1
```c++
D3D12_PROTECTED_RESOURCE_SESSION_DESC1 GetDesc1();
```
Retrieves the creation properties for the protected resource session. See D3D12_PROTECTED_RESOURCE_SESSION_DESC1.


## Resources & Heap Additions

The creation of heaps, committed resources, and reserved resources are modified to receive the protected session.  Placed resources infer their protection from the heap they are placed on.

### Interface: ID3D12Device4
```c++
interface ID3D12Device4
    : ID3D12Device3
```
Adds new creation methods for heaps and resources and protected resource sessions to support protected resources.

#### Method: ID3D12Device4::CreateCommittedResource1

```c++
HRESULT CreateCommittedResource1(
    [annotation("_In_")] const D3D12_HEAP_PROPERTIES* pHeapProperties,
    D3D12_HEAP_FLAGS HeapFlags,
    [annotation("_In_")] const D3D12_RESOURCE_DESC* pDesc,
    D3D12_RESOURCE_STATES InitialResourceState,
    [annotation("_In_opt_")] const D3D12_CLEAR_VALUE* pOptimizedClearValue,
    [annotation("_In_opt_")] ID3D12ProtectedResourceSession *pProtectedSession,
    [in] REFIID riidResource, // Expected: ID3D12Resource1*
    [out, iid_is(riidResource), annotation("_COM_Outptr_opt_")] void** ppvResource
    );
```

**Parameters**

*pProtectedSession*  
The protected session for the protected resource that is to be created.
If the resource is not protected, set to NULL.

*riid*  
The GUID of the interface to a resource. Most commonly, ID3D12Resource1,
although it may be any GUID for any interface. If the protected session
object doesn't support the interface for this GUID, the getter will
return E\_NOINTERFACE.

*ppvResource*  
A pointer to a memory block that receives a pointer to the created resource.

#### Method: ID3D12Device4::CreateReservedResource1
```C+++
HRESULT CreateReservedResource1(
    [annotation("_In_")] const D3D12_RESOURCE_DESC* pDesc,
    D3D12_RESOURCE_STATES InitialState,
    [annotation("_In_opt_")] const D3D12_CLEAR_VALUE* pOptimizedClearValue,
    [annotation("_In_opt_")] ID3D12ProtectedResourceSession *pProtectedSession,
    [in] REFIID riid, // Expected: ID3D12Resource1*
    [out, iid_is(riid), annotation("_COM_Outptr_opt_")] void** ppvResource
    );
```

**Parameters**

*pProtectedSession*  
The protected session for the protected resource that is to be created.  If the resource is not protected, set to NULL.

*riid*  
The GUID of the interface to a resource. Most commonly, ID3D12Resource1, although it may be any GUID for any interface. If the protected session object doesn't support the interface for this GUID, the getter will return E_NOINTERFACE.

*ppvResource*  
A pointer to a memory block that receives a pointer to the created resource.


#### Method: ID3D12Device4::CreateHeap1

```c++
HRESULT CreateHeap1(
    [annotation("_In_")] const D3D12_HEAP_DESC* pDesc,
    [annotation("_In_opt_")] ID3D12ProtectedResourceSession *pProtectedSession,
    [in] REFIID riid, // Expected: ID3D12Heap1*
    [out, iid_is(riid), annotation("_COM_Outptr_opt_")] void** ppvHeap
    );
```

**Parameters**

*pProtectedSession*  
The protected session for the heap that is to be created. If the heap is not protected, set to NULL.

*riid*  
The GUID of the interface to a heap. Most commonly, ID3D12Heap1, although it may be any GUID for any interface. If the protected session object doesn't support the interface for this GUID, the getter will return E_NOINTERFACE.

*ppvHeap*  
A pointer to a memory block that receives a pointer to the created heap.


### Interface: ID3D12Resource1

```c++
interface ID3D12Resource1: ID3D12Resource
```
Adds a method to get the protected resource session associated with the resource.  May be nullptr.

#### Method: ID3D12Resource1::GetProtectedResourceSession

```c++
HRESULT GetProtectedResourceSession(
    [in] REFIID riid, // Expected: ID3D12ProtectedResourceSession
    [out, iid_is(riid), annotation("_COM_Outptr_opt_")] void** ppProtectedSession);
```
Gets the protected session used to create the resource.

**Parameters**

*riid*  
The GUID of the interface to a protected session. Most commonly, ID3D12ProtectedResourceSession, although it may be any GUID for any interface. If the protected session object doesn't support the interface for this GUID, the getter will return E_NOINTERFACE.

*ppProtectedSession*  
A pointer to a memory block that receives a pointer to the protected session.

### Interface: ID3D12Heap1

```c++
interface ID3D12Heap1: ID3D12**Heap**
```

#### Method: ID3D12Heap1::GetProtectedResourceSession
```c++

HRESULT GetProtectedResourceSession(
    [in] REFIID riid, // Expected: ID3D12ProtectedResourceSession
    [out, iid_is(riid), annotation("_COM_Outptr_opt_")] void** ppProtectedSession);
```

Gets the protected session used to create the heap.

**Parameters**

*riid*  
The GUID of the interface to a protected session. Most commonly, ID3D12ProtectedResourceSession, although it may be any GUID for any interface. If the protected session object doesn't support the interface for this GUID, the getter will return E_NOINTERFACE.

*ppProtectedSession* 
A pointer to a memory block that receives a pointer to the protected session.

## Command list additions

The drivers may need to know if a command list contains protected
resources or not, so that they

* can prepare their command buffers appropriately, and split them if necessary, on a protection boundary.

* can scan the command list for any protected resources and submit appropriate commands for the protected resources.

In DX12, we are adding a method for command lists that indicates the
presence of a protected session. Protected resources should just be
accessed in the command list after the SetProtectedResourceSession
method is called with a valid session. This is the replacement for
SetHardwareProtectionState() in DX11.

### Interface: ID3D12GraphicsCommandList3
```c++
interface ID3D12GraphicsCommandList3 : ID3D12GraphicsCommandList2
```

#### Method: ID3D12GraphicsCommandList3::SetProtectedResourceSession
```c++
void SetProtectedResourceSession(
    [annotation("_In_opt_")]ID3D12ProtectedResourceSession *pProtectedResourceSession
    );
```

Defines if protected resources can be access or not by subsequent
commands in the command list. By default, no protected resources are
enabled. After calling SetProtectedResourceSession with a valid session,
protected resources of the same type can refer to that session. After
calling SetProtectedResourceSession with NULL, no protected resources
can be accessed.

**Parameters**

*pProtectedSession*
If set, indicates that protected resources can be accessed with the given session. All access to protected resources can only happen after SetProtectedResourceSession is called with a valid session. The command list state is cleared when calling this method. If NULL, no protected resources can be accessed.

### Interface: ID3D12VideoDecodeCommandList2
```c++
interface ID3D12VideoDecodeCommandList2 : ID3D12VideoDecodeCommandList1
```

#### Method: ID3D12VideoDecodeCommandList2::SetProtectedResourceSession
```c++
void SetProtectedResourceSession(
    [annotation("_In_opt_")]ID3D12ProtectedResourceSession *pProtectedResourceSession
    );
```

Defines if protected resources can be access or not by subsequent commands in the command list. By default, no protected resources are enabled. After calling SetProtectedResourceSession with a valid session, protected resources of the same type can refer to that session. After calling SetProtectedResourceSession with NULL, no protected resources can be accessed.

**Parameters**

*pProtectedSession*  
If set, indicates that protected resources can be accessed with the given session. All access to protected resources can only happen after SetProtectedResourceSession is called with a valid session. The command list state is cleared when calling this method. If NULL, no protected resources can be accessed.

### Interface: ID3D12VideoProcessCommandList2
```c++
interface ID3D12VideoProcessCommandList2 : ID3D12VideoDecodeCommandList1
```

#### Method: ID3D12VideoProcessCommandList2::SetProtectedResourceSession
```c++
void SetProtectedResourceSession(
    [annotation("_In_opt_")]ID3D12ProtectedResourceSession *pProtectedResourceSession
    );
```

Defines if protected resources can be access or not by subsequent commands in the command list. By default, no protected resources are enabled. After calling SetProtectedResourceSession with a valid session, protected resources of the same type can refer to that session. After calling SetProtectedResourceSession with NULL, no protected resources can be accessed.

**Parameters**

*pProtectedSession*  
If set, indicates that protected resources can be accessed with the given session. All access to protected resources can only happen after SetProtectedResourceSession is called with a valid session. The command list state is cleared when calling this method. If NULL, no protected resources can be accessed.

### Interface: ID3D12VideoEncodeCommandList
```c++
interface ID3D12VideoEncodeCommandList : ID3D12CommandList
```

#### Method: ID3D12VideoEncodeCommandList::SetProtectedResourceSession
```c++
void SetProtectedResourceSession(
    [annotation("_In_opt_")]ID3D12ProtectedResourceSession *pProtectedResourceSession
    );
```
Defines if protected resources can be access or not by subsequent commands in the command list. By default, no protected resources are enabled. After calling SetProtectedResourceSession with a valid session, protected resources of the same type can refer to that session. After calling SetProtectedResourceSession with NULL, no protected resources can be accessed.

**Parameters**

*pProtectedSession*
If set, indicates that protected resources can be accessed with the given session. All access to protected resources can only happen after SetProtectedResourceSession is called with a valid session. The command list state is cleared when calling this method. If NULL, no protected resources can be accessed.

## Checking for Protected Resource Support

### Enum: D3D12_FEATURE
```c++
typedef enum D3D12_FEATURE
{
...
D3D12_FEATURE_PROTECTED_RESOURCE_SESSION_SUPPORT,
... 
D3D12_FEATURE_PROTECTED_RESOURCE_SESSION_TYPE_COUNT,
D3D12_FEATURE_PROTECTED_RESOURCE_SESSION_TYPES,
...
} D3D12_FEATURE;
```

**Constants**

*D3D12_FEATURE_PROTECTED_RESOURCE_SESSION_SUPPORT*
Check if protected resource operations are supported.  Support here indicates that graphics, compute, and copy operations support protected resources.  Video operations may support protected resources.  Check the feature support for the individual operations.

*D3D12_FEATURE_PROTECTED_RESOURCE_SESSION_TYPE_COUNT*
Retrieves the count of protected resource session types.

*D3D12_FEATURE_PROTECTED_RESOURCE_SESSION_TYPES*
Retrieves the list of protected resource session types.

### Enum: D3D12_PROTECTED_RESOURCE_SESSION_SUPPORT_FLAGS
```c++
typedef enum D3D12_PROTECTED_RESOURCE_SESSION_SUPPORT_FLAGS
{
    D3D12_PROTECTED_RESOURCE_SESSION_SUPPORT_FLAG_NONE = 0x0,
    D3D12_PROTECTED_RESOURCE_SESSION_SUPPORT_FLAG_SUPPORTED = 0x1,
} D3D12_PROTECTED_RESOURCE_SESSION_SUPPORT_FLAGS;
```
**Constants**

*D3D12_PROTECTED_RESOURCE_SESSION_SUPPORT_FLAG_NONE*  
Protected resources are not supported with any operation.

*D3D12_PROTECTED_RESOURCE_SESSION_SUPPORT_FLAG_SUPPORTED*  
Graphics, compute, and copy operations support protected resources.  Video operations may support protected resources.  Check the feature support for the individual operations.

### Struct: D3D12_FEATURE_DATA_PROTECTED_RESOURCE_SESSION_SUPPORT
```c++
typedef struct D3D12_FEATURE_DATA_PROTECTED_RESOURCE_SESSION_SUPPORT
{
    UINT                                            NodeIndex;  // input
    D3D12_PROTECTED_RESOURCE_SESSION_SUPPORT_FLAGS  Support;    // output
} D3D12_FEATURE_DATA_PROTECTED_RESOURCE_SESSION_SUPPORT;
```
**Members**  

*NodeIndex*  
In multi-adapter operation, this indicates which physical adapter of the device this operation applies to.

*Support*  
Support flags for protected resource sessions.  Seee D3D12_PROTECTED_RESOURCE_SESSION_SUPPORT_FLAGS.

### Struct: D3D12_FEATURE_DATA_PROTECTED_RESOURCE_SESSION_TYPE_COUNT
```c++
typedef struct D3D12_FEATURE_DATA_PROTECTED_RESOURCE_SESSION_TYPE_COUNT
{
    UINT                                        NodeIndex;              // input
    UINT                                        Count;                  // output
} D3D12_FEATURE_DATA_PROTECTED_RESOURCE_SESSION_TYPE_COUNT;
```
The feature data structure for D3D12_FEATURE_PROTECTED_RESOURCE_SESSION_TYPE_COUNT.
**Members**  

*NodeIndex*  
In multi-adapter operation, this indicates which physical adapter of the device this operation applies to.

*Count*  
The number of protected resource session types supported by driver.

### Struct: D3D12_FEATURE_DATA_PROTECTED_RESOURCE_SESSION_TYPES
```c++
typedef struct D3D12_FEATURE_DATA_PROTECTED_RESOURCE_SESSION_TYPES
{
    UINT                                        NodeIndex;              // input
    UINT                                        Count;                  // input
    GUID*                                       pTypes;                 // output
} D3D12_FEATURE_DATA_PROTECTED_RESOURCE_SESSION_TYPES;
```
The feature data structure for D3D12_FEATURE_PROTECTED_RESOURCE_SESSION_TYPES.

**Members**  

*NodeIndex*  
In multi-adapter operation, this indicates which physical adapter of the device this operation applies to.

*Count*  
Indicates the size of the pTypes array.  Must match the count returned through the D3D12_FEATURE_PROTECTED_RESOURCE_SESSION_TYPE_COUNT check.

*pTypes*  
On return this array is populated with the supported protected resource session types.

# DDI

## Creating Protected Sessions

Creating a ProtectedResourceSession, kernel creation, and providing status.

### Struct: D3D12DDICB_CREATE_PROTECTED_SESSION
```c++
typedef struct D3D12DDICB_CREATE_PROTECTED_SESSION
{    
    CONST VOID*                                 pPrivateDriverData;
    UINT                                        PrivateDriverDataSize;
} D3D12DDICB_CREATE_PROTECTED_SESSION;
```

Callback creation arguments for creating a protected resource session

**Members**

*pPrivateDriverData*  
Driver private data that is passed through graphics kernel to the KMD.

*PrivateDriverDataSize*  
Size of driver private data.

### Callback: PFND3D12DDI_CREATE_PROTECTED_SESSION_CB
```c++
typedef HRESULT(APIENTRY CALLBACK* PFND3D12DDI_CREATE_PROTECTED_SESSION_CB)(
    D3D12DDI_HRTDEVICE hRTDevice,
    D3D12DDI_HRTPROTECTEDSESSION_0030 hRTProtectedSession,
    _In_ D3D12DDICB_CREATE_PROTECTED_SESSION_0030* pArgs );
```

Callback to create graphics kernel protected resource session. This
function is added to the D3D12DDI_CORELAYER\_DEVICECALLBACKS function
table. This callback must be called during a call to
PFND3D12DDI_CREATEPROTECTEDRESOURCESESSION.

**Parameters**

*hRTProtectedSession*  
Runtime callback

*pArgs*  
Creation arguments for the protected resource session. See D3D12DDICB_CREATE_PROTECTED_RESOURCE_SESSION for more information.

### Struct: DXGKARG_CREATEPROTECTEDSESSION
```c++
typedef struct _DXGKARG_CREATEPROTECTEDSESSION
{
    HANDLE     hProtectedSession;       // in: DXG assigned value for the protected session that was passed to
                                        //     DxgkDdiCreateProtectedSession.
                                        // out: Driver generated handle.
    PVOID      pPrivateDriverData;
    UINT       PrivateDriverDataSize;
} DXGKARG_CREATEPROTECTEDSESSION;
```
The creation arg structure for the kernel mode DDI DXGKDDI_CREATEPROTECTEDRESOURCE.

**Parameters**

*hProtectedSession*  
When calling DXGKDDI_CREATEPROTECTEDSESSION, graphics kernel sets this value to the runtimes handle that can be used to call DXGKCB_SETPROTECTEDSESSIONSTATUS. Kernel mode Driver should store this value if it needs to call DXGKCB_SETPROTECTEDSESSIONSTATUS. Before returning, the kernel mode driver should overwrite this value with its own handle that refers to the corresponding kernel mode driver object. When graphics kernel calls the kernel mode driver, such as in DXGKDDI_DESTROYPROTECTEDSESSION, graphics kernel passes in this handle to refer to the corresponding driver object.

*pPrivateDriverData*  
The marshaled private driver data that specified during usermode callback  PFND3D12DDI_CREATE_PROTECTED_RESOURCE_SESSION_CB. All protected session types are created shared. This data should contain data necessary to open the session with each types Open method after returning from the create.

*PrivateDataDriverSize*  
The size of the buffer pointed to by pPrivateDriverData

### Function: DXGKDDI_CREATEPROTECTEDSESSION
```c++
typedef
    _Check_return_
    _Function_class_DXGK_(DXGKDDI_CREATEPROTECTEDSESSION)
    _IRQL_requires_(PASSIVE_LEVEL)
NTSTATUS
APIENTRY
DXGKDDI_CREATEPROTECTEDSESSION(
    IN_CONST_HANDLE                       hAdapter,
    INOUT_PDXGKARG_CREATEPROTECTEDSESSION pCreateProtectedSession
    );

typedef DXGKDDI_CREATEPROTECTEDSESSION *PDXGKDDI_CREATEPROTECTEDSESSION;
```
The kernel mode DDI for creating a protected session. This is called in
response to usermode driver calling PFND3D12DDI_CREATE_PROTECTED_RESOURCE_SESSION_CB. This function is added to the DXGK_INTERFACE function table.

**Parameters**

*hAdapter*  
The driver adapter handle.

*pCreateProtectedSession*  
Creation arguments. See DXGKARG_CREATEPROTECTEDSESSION for more details.

## Destroying Protected Sessions

### Function: DXGKDDI_DESTROYPROTECTEDSESSION  
```c++
typedef
    _Check_return_
    _Function_class_DXGK_(DXGKDDI_DESTROYPROTECTEDSESSION)
    _IRQL_requires_(PASSIVE_LEVEL)
NTSTATUS
APIENTRY
DXGKDDI_DESTROYPROTECTEDSESSION(
    IN_CONST_HANDLE                       hAdapter,
    IN_CONST_HANDLE                       hProtectedSession // in: Driver generated handle driver returned at DxgkDdiCreateProtectedSession.
    );

typedef DXGKDDI_DESTROYPROTECTEDSESSION *PDXGKDDI_DESTROYROTECTEDSESSION;
```

The kernel mode DDI for destroying a protected session. This function is
added to the DXGK\_INTERFACE function table.

**Parameters**

*hAdapter*  
The driver adapter handle.

*hProtectedSession*  
The driver handle to the session to destroy. This is the driver handle value returned from DXGKDDI\_CREATEPROTECTEDSESSION. See DXGKARG_CREATEPROTECTEDSESSION for more details.

## Setting Session Status

Kernel mode driver may callback into graphics kernel to modify the
status of a protected resource session. For example, tamper detection
may invalidate the session.

### Enum: DXGK_PROTECTED_SESSION_STATUS
```c++
typedef enum _DXGK_PROTECTED_SESSION_STATUS
{
    DXGK_PROTECTED_SESSION_STATUS_OK         = 0,
    DXGK_PROTECTED_SESSION_STATUS_INVALID    = 1,
} DXGK_PROTECTED_SESSION_STATUS;
```
**Constants**

*DXGK_PROTECTED_SESSION_STATUS_OK*  
The protected session is ok.

*DXGK_PROTECTED_SESSION_STATUS_INVALID*  
The protected status is invalid.

### Struct: DXGKARG_PROTECTEDSESSIONSTATUS
```c++
typedef struct _DXGKARGCB_PROTECTEDSESSIONSTATUS
{
    HANDLE                                hProtectedSession; // in: DXG handle
                                                             // in: DXG assigned value for the protected session that was passed to
                                                             //     DxgkDdiCreateProtectedSession.
    DXGK_PROTECTED_SESSION_STATUS         Status;
} DXGKARGCB_PROTECTEDSESSIONSTATUS;

typedef _In_ CONST DXGKARGCB_PROTECTEDSESSIONSTATUS* IN_CONST_PDXGKARGCB_PROTECTEDSESSIONSTATUS;
```
Data structure for the kernel mode driver callback DXGKCB_SETPROTECTEDSESSIONSTATUS.

**Members**

*hProtectedSession*  
The graphics kernel protected resource handle that driver captured from DXGKARG_CREATEPROTECTEDSESSION.

*Status*  
The new status for the protected resource session.

### Callback: DXGKCB_SETPROTECTEDSESSIONSTATUS
```c++
typedef
    _Check_return_
    _Function_class_DXGK_(DXGKCB_SETPROTECTEDSESSIONSTATUS)
    _IRQL_requires_(PASSIVE_LEVEL)
NTSTATUS
(APIENTRY CALLBACK *DXGKCB_SETPROTECTEDSESSIONSTATUS)(
    IN_CONST_PDXGKARGCB_PROTECTEDSESSIONSTATUS pProtectedSessionStatus
    );
```

This kernel mode callback is used to allow driver to set status of a
protected resource session. This is then used to notify applications in
usermode of a status change in the session, either it becoming invalid
or becoming valid again. This callback is added to the
DXGKRNL_INTERFACE.

Driver is required to synchronize use of DXGKDDI_DESTROYPROTECTEDSESSION so that it does not call DXGKCB_SETPROTECTEDSESSIONSTATUS during or after the resource session is destroyed.

**Paramaters**

*pProtectedSessionStatus*  
The new session status. See DXGKARG_PROTECTEDSESSIONSTATUS for more details.

## Checking for Protected Resource Support

Defines capability checks for Protected Resource Supported

### Enum: D3D12DDICAPS_TYPE

The D3D12DDICAPS_TYPE enum is updated to add a new value for checking for protected resource session support.
```c++
typedef enum D3D12DDICAPS_TYPE
{
...
D3D12DDICAPS_TYPE_0030_PROTECTED_RESOURCE_SESSION_SUPPORT
...
D3D12DDICAPS_TYPE_0074_PROTECTED_RESOURCE_SESSION_TYPE_COUNT,
D3D12DDICAPS_TYPE_0074_PROTECTED_RESOURCE_SESSION_TYPES,
...
} D3D12DDICAPS_TYPE;
```

**Constants**

*D3D12DDICAPS_TYPE_PROTECTED_RESOURCE_SESSION_SUPPORT*  
Retrieves the hardware content protection capabilities. The associated data structure is D3D12DDI_PROTECTED_RESOURCE_SESSION_SUPPORT_DATA.

*D3D12DDICAPS_TYPE_0074_PROTECTED_RESOURCE_SESSION_TYPE_COUNT*  
Starting with D3D12DDI_FEATURE_VERSION_CONTENT_PROTECTION_RESOURCES_0074_0 this query is made if the driver reports D3D12DDI_PROTECTED_RESOURCE_SESSION_SUPPORT_FLAG_SUPPORTED via D3D12DDICAPS_TYPE_PROTECTED_RESOURCE_SESSION_SUPPORT.  The driver must report at least 1 GUID for D3D12DDI_PROTECTED_RESOURCES_SESSION_HARDWARE_PROTECTED.

*D3D12DDICAPS_TYPE_0074_PROTECTED_RESOURCE_SESSION_TYPES*  
Starting with D3D12DDI_FEATURE_VERSION_CONTENT_PROTECTION_RESOURCES_0074_0 this query is made if the driver reports D3D12DDI_PROTECTED_RESOURCE_SESSION_SUPPORT_FLAG_SUPPORTED via D3D12DDICAPS_TYPE_PROTECTED_RESOURCE_SESSION_SUPPORT.  The driver must report D3D12DDI_PROTECTED_RESOURCES_SESSION_HARDWARE_PROTECTED.  Allowed GUIDS are controlled via an allow list and additional GUIDS require approval from Microsoft.  


### Enum: D3D12_PROTECTED_RESOURCE_SESSION_SUPPORT_FLAGS
```c++
typedef enum D3D12DDI_PROTECTED_RESOURCE_SESSION_SUPPORT_FLAGS
{
    D3D12DDI_PROTECTED_RESOURCE_SESSION_SUPPORT_FLAG_0030_NONE = 0x0,
    D3D12DDI_PROTECTED_RESOURCE_SESSION_SUPPORT_FLAG_0030_SUPPORTED = 0x1,
} D3D12DDI_PROTECTED_RESOURCE_SESSION_SUPPORT_FLAGS;
```

Specifies the supported protected sessions options.

**Constants**

*D3D12DDI_PROTECTED_RESOURCE_SESSION_SUPPORT_FLAG_NONE*  
Protected session for the given parameters is unsupported.

*D3D12DDI_PROTECTED_RESOURCE_SESSION_SUPPORT_FLAG_SUPPORTED*  
Set if the device supports protected sessions. If that is true, it means that:

+ The contents of a protected allocation can never be read by the CPU.

+ The hardware can ensure that a protected resource cannot be copied to an unprotected resource.

This flag indicates that protected resources may be used with all graphics, compute, and copy operations.  This flag indicates that video operations may support protected resources, see each operations individual caps.

### Struct: D3D12DDI_PROTECTED_RESOURCE_SESSION_SUPPORT_DATA
```c++
// D3D12DDICAPS_TYPE_PROTECTED_RESOURCE_SESSION_SUPPORT
typedef struct D3D12DDI_PROTECTED_RESOURCE_SESSION_SUPPORT_DATA
{
    UINT                                                    NodeIndex;      // input
    D3D12DDI_PROTECTED_RESOURCE_SESSION_SUPPORT_FLAGS       Support;        // output
} D3D12DDI_PROTECTED_RESOURCE_SESSION_SUPPORT_DATA;
```
**Members**

*NodeIndex*  
In multi-adapter operation, this indicates which physical adapter of the device this operation applies to.

*Support*  
Indicates the level of support for protected sessions. D3D12DDI_PROTECTED_RESOURCE_SESSION_SUPPORT_FLAGS

### Struct: D3D12_FEATURE_DATA_PROTECTED_RESOURCE_SESSION_TYPE_COUNT
```c++
typedef struct D3D12DDI_PROTECTED_RESOURCE_SESSION_TYPES_DATA_0074
{
    UINT                                        NodeIndex;              // input
    UINT                                        Count;                  // output
} D3D12DDI_PROTECTED_RESOURCE_SESSION_TYPES_DATA_0074;
```
The caps data structure for D3D12DDICAPS_TYPE_0074_PROTECTED_RESOURCE_SESSION_TYPES.  The driver must report at least 1 GUID for D3D12DDI_PROTECTED_RESOURCES_SESSION_HARDWARE_PROTECTED if protected resources are supported.
**Members**  

*NodeIndex*  
In multi-adapter operation, this indicates which physical adapter of the device this operation applies to.

*Count*  
The number of protected resource session types supported by driver.

### Struct: D3D12_FEATURE_DATA_PROTECTED_RESOURCE_SESSION_TYPES
```c++
typedef struct D3D12_FEATURE_DATA_PROTECTED_RESOURCE_SESSION_TYPES
{
    UINT                                        NodeIndex;              // input
    UINT                                        Count;                  // input
    GUID*                                       pTypes;                 // output
} D3D12_FEATURE_DATA_PROTECTED_RESOURCE_SESSION_TYPES;
```
The feature data structure for D3D12_FEATURE_PROTECTED_RESOURCE_SESSION_TYPES.

**Members**  

*NodeIndex*  
In multi-adapter operation, this indicates which physical adapter of the device this operation applies to.

*Count*  
Indicates the size of the pTypes array.  Must match the count returned through the D3D12_FEATURE_PROTECTED_RESOURCE_SESSION_TYPE_COUNT check.

*pTypes*  
On return this array is populated with the supported protected resource session types. The driver must report D3D12DDI_PROTECTED_RESOURCES_SESSION_HARDWARE_PROTECTED if protected resources are supported.  Allowed GUIDS are controlled via an allow list and additional GUIDS require approval from Microsoft.  

## Creating Protected Resource Sessions - D3D12DDI_FEATURE_VERSION_CONTENT_PROTECTION_RESOURCES_0040_0

### Struct: D3D12DDIARG_CREATE_PROTECTED_RESOURCE_SESSION
```c++
typedef struct D3D12DDIARG_CREATE_PROTECTED_RESOURCE_SESSION
{
    UINT                                        NodeMask;
} D3D12DDIARG_CREATE_PROTECTED_RESOURCE_SESSION;
```
Creation arguments for a protected resource session

**Members**

*NodeMask*  
For single GPU operation, set this to zero. If there are multiple GPU nodes, set a bit to identify the node (the device\'s physical adapter) to which the crypto session applies. Each bit in the mask corresponds to a single node. Only 1 bit may be set.

### Function: PFND3D12DDI_CALCPRIVATEPROTECTEDRESOURCESESSIONSIZE
```c++
typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALCPRIVATEPROTECTEDRESOURCESESSIONSIZE )( 
    D3D12DDI_HDEVICE hDrvDevice, 
    _In_ CONST D3D12DDIARG_CREATE_PROTECTED_RESOURCE_SESSION* pArgs 
    );
```

The D3D runtime allocates memory for storing the drivers CPU object representing the protected resource session. This method is used to calculate the driver object size.

**Paramters**

*hDrvDevice*  
A handle to the device.

*pArgs*  
Creation arguments, see D3D12DDIARG_CREATE_PROTECTED_RESOURCE_SESSION.

### Function: PFND3D12DDI_CREATEPROTECTEDRESOURCESESSION
```c++
typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATEPROTECTEDRESOURCESESSION )( 
    D3D12DDI_HDEVICE hDrvDevice, 
    _In_ CONST D3D12DDIARG_CREATE_PROTECTED_RESOURCE_SESSION* pArgs,
    D3D12DDI_HPROTECTEDRESOURCESESSION hDrvProtectedResourceSession,
    D3D12DDI_HRTPROTECTEDSESSION hRtProtectedSession
    );
```
The D3D runtime allocates memory for storing the drivers CPU object
representing the protected resource session. Creates the protected
resource session.

**Parameters**

*hDrvDevice*  
A handle to the device.

*pArgs*  
Creation arguments, see D3D12DDIARG_CREATE_PROTECTED_RESOURCE_SESSION.

*hDrvProtectedResourceSession*
Handle for driver to place its object representing the protected resource session.

*hRtProtectedSession*  
Handle used to call PFND3D12DDI\_CREATE\_PROTECTED\_SESSION\_CB during protected session resource creation.

## Creating Protected Resource Sessions - D3D12DDI_FEATURE_VERSION_CONTENT_PROTECTION_RESOURCES_0074_0

Starting with D3D12DDI_FEATURE_VERSION_CONTENT_PROTECTION_RESOURCES_0074_0 a new CalcPrivateSize and Create are used.

### Struct: D3D12DDIARG_CREATE_PROTECTED_RESOURCE_SESSION_0070
```c++
typedef struct D3D12DDIARG_CREATE_PROTECTED_RESOURCE_SESSION_0070
{
    UINT                                        NodeMask;
    GUID                                        ProtectionType;
} D3D12DDIARG_CREATE_PROTECTED_RESOURCE_SESSION_0070;
```
Creation arguments for a protected resource session

**Members**

*NodeMask*  
For single GPU operation, set this to zero. If there are multiple GPU nodes, set a bit to identify the node (the device\'s physical adapter) to which the crypto session applies. Each bit in the mask corresponds to a single node. Only 1 bit may be set.

*ProtectionType* 
The GUID that represents the protection type.  Microsoft defines D3D12DDI_PROTECTED_RESOURCES_SESSION_HARDWARE_PROTECTED.  This DDI and corresponding API may be extended by IHV's, but requires Microsoft approval.  Allowed guids are controlled by an allow list.  Developer mode disables the check to allow for private IHV development.

### Function: PFND3D12DDI_CALCPRIVATEPROTECTEDRESOURCESESSIONSIZE_0070
```c++
typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALCPRIVATEPROTECTEDRESOURCESESSIONSIZE_0070 )( 
    D3D12DDI_HDEVICE hDrvDevice, 
    _In_ CONST D3D12DDIARG_CREATE_PROTECTED_RESOURCE_SESSION_0070* pArgs 
    );
```

The D3D runtime allocates memory for storing the drivers CPU object representing the protected resource session. This method is used to calculate the driver object size.

**Paramters**

*hDrvDevice*  
A handle to the device.

*pArgs*  
Creation arguments, see D3D12DDIARG_CREATE_PROTECTED_RESOURCE_SESSION_0070.

### Function: PFND3D12DDI_CREATEPROTECTEDRESOURCESESSION
```c++
typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATEPROTECTEDRESOURCESESSION_0070 )( 
    D3D12DDI_HDEVICE hDrvDevice, 
    _In_ CONST D3D12DDIARG_CREATE_PROTECTED_RESOURCE_SESSION_0070* pArgs,
    D3D12DDI_HPROTECTEDRESOURCESESSION hDrvProtectedResourceSession,
    D3D12DDI_HRTPROTECTEDSESSION hRtProtectedSession
    );
```
The D3D runtime allocates memory for storing the drivers CPU object
representing the protected resource session. Creates the protected
resource session.

**Parameters**

*hDrvDevice*  
A handle to the device.

*pArgs*  
Creation arguments, see D3D12DDIARG_CREATE_PROTECTED_RESOURCE_SESSION_0070.

*hDrvProtectedResourceSession*
Handle for driver to place its object representing the protected resource session.

*hRtProtectedSession*  
Handle used to call PFND3D12DDI_CREATE_PROTECTED_SESSION_CB during protected session resource creation.

## Opening Protected Resource Sessions

Protected resource sessions are always shared and support open. PFND3D12DDI_CALCPRIVATEPROTECTEDRESOURCESESSIONSIZE is used to calculate object size, but a separate open entry point is added to pass driver private data.

### Struct: D3D12DDIARG_OPEN_PROTECTED_RESOURCE_SESSION
```c++
typedef struct D3D12DDIARG_OPEN_PROTECTED_RESOURCE_SESSION
{
    CONST VOID*                                 pPrivateDriverData;
    UINT                                        PrivateDriverDataSize;    
} D3D12DDIARG_OPEN_PROTECTED_RESOURCE_SESSION;
```

Open arguments for a shared protected resource session

**Members**

*pPrivateDriverData*  
Driver private data that is passed through graphics kernel to the KMD.

*PrivateDriverDataSize*  
Size of driver private data.

### Function: PFND3D12DDI_CALCPRIVATEOPENPROTECTEDRESOURCESESSIONSIZE
```c++
typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALCPRIVATEOPENEDPROTECTEDRESOURCESESSIONSIZE)(
    D3D12DDI_HDEVICE hDrvDevice,
    _In_ CONST D3D12DDIARG_OPEN_PROTECTED_RESOURCE_SESSION* pArgs
    );
```

The D3D runtime allocates memory for storing the drivers CPU object representing the protected resource session. This method is used to calculate the driver object size when opening a shared protected resource session.

**Paramters**

*hDrvDevice*  
A handle to the device.

*pArgs*  
Creation arguments, see D3D12DDIARG_OPEN_PROTECTED_RESOURCE_SESSION.

### Function: PFND3D12DDI_OPENPROTECTEDRESOURCESESSION
```c++
typedef HRESULT ( APIENTRY* PFND3D12DDI_OPENPROTECTEDRESOURCESESSION )( 
    D3D12DDI_HDEVICE hDrvDevice, 
    _In_ CONST D3D12DDIARG_OPEN_PROTECTED_RESOURCE_SESSION* pArgs,
    D3D12DDI_HPROTECTEDRESOURCESESSION hDrvProtectedResourceSession
    );
```
The D3D runtime allocates memory for storing the drivers CPU object representing the protected resource session. Opens the protected resource session.

**Parameters**

*hDrvDevice*  
A handle to the device.

*pArgs*  
Creation arguments, see D3D12DDIARG_OPEN_PROTECTED_RESOURCE_SESSION.

*hDrvProtectedResourceSession*  

Handle for driver to place its object representing the protected resource session.

## Destroying Protected Resource Sessions

### Function: PFND3D12DDI_DESTROYPROTECTEDRESOURCESESSION
```c++
typedef VOID ( APIENTRY* PFND3D12DDI_DESTROYPROTECTEDRESOURCESESSION )( 
    D3D12DDI_HDEVICE hDrvDevice, 
    D3D12DDI_HPROTECTEDRESOURCESESSION hDrvProtectedResourceSession 
    );
```

Destroys a protected resource session

**Parameters**

*hDrvDevice*  
The driver device handle.

*hDrvProtectedResourceSession*  
The driver protected resource session handle to destroy.

## Creating Heaps And Resources

#### Function: PFND3D12DDI_CALCPRIVATEHEAPANDRESOURCESIZES_0030
```c++
typedef D3D12DDI_HEAP_AND_RESOURCE_SIZES ( APIENTRY* PFND3D12DDI_CALCPRIVATEHEAPANDRESOURCESIZES_0030 )(
     D3D12DDI_HDEVICE, _In_opt_ CONST D3D12DDIARG_CREATEHEAP_0001*, _In_opt_ CONST D3D12DDIARG_CREATERESOURCE_0003*,
     D3D12DDI_HPROTECTEDRESOURCESESSION_0030 );
```

The usermode DDI for calculating heap and resource sizes is revised to
include a protected resource handle.

**New Parameters**

*hDrvProtectedResourceSession*  
The protected resource session to use for the heap/resource being created. Zero indicates unprotected resources.

#### Function: PFND3D12DDI_CREATEHEAPANDRESOURCE_0030
```c++
typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATEHEAPANDRESOURCE_0030 )( 
    D3D12DDI_HDEVICE, _In_opt_ CONST D3D12DDIARG_CREATEHEAP_0001*, D3D12DDI_HHEAP, D3D12DDI_HRTRESOURCE,
    _In_opt_ CONST D3D12DDIARG_CREATERESOURCE_0003*, _In_opt_ CONST D3D12DDI_CLEAR_VALUES*, 
    D3D12DDI_HPROTECTEDRESOURCESESSION_0030, D3D12DDI_HRESOURCE );
```

The usermode DDI for creating heap and resource is revised to include a
protected resource handle.

**New Parameters**

*hDrvProtectedResourceSession*  
The protected resource session to use for the heap/resource being created. Zero indicates unprotected resources.

## Command List Additions

A new function is added to D3D12DDI_COMMAND_LIST_FUNCS_3D,
D3D12DDI_COMMAND_LIST_FUNCS_VIDEO_DECODE, D3D12DDI_COMMAND_LIST_FUNCS_VIDEO_PROCESS, D3D12DDI_COMMAND_LIST_FUNCS_VIDEO_ENCODE to set the protected resource session.

### Function: PFND3D12DDI_SETPROTECTEDRESOURCESESSION
```c++
typedef VOID ( APIENTRY* PFND3D12DDI_SETPROTECTEDRESOURCESESSION_0030 )( 
    D3D12DDI_HCOMMANDLIST hDrvCommandList, 
    D3D12DDI_HPROTECTEDRESOURCESESSION_0030 hDrvProtectedResourceSession);
```
Sets/Unsets the protected resource session that is used for all subsequent commands until another call to PFND3D12DDI_SETPROTECTEDRESOURCESESSION.

**Parameters:**

*hDrvCommandList*  
The drivers command list handle.

*hDrvProtectedResourceSession*  
The drivers protected resource session used with any subsequent commands that reference protected resources.

