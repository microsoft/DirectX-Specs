# D3D12 Translation Layer Resource Interoperability

## Change History

| Date           | Change        |
| -------------- | ------------- |
| **05/13/2018** | Initial draft |
| **10/31/2019** | Clarify UnwrapUnderlyingResource in 11on12 does not Flush  |
| **11/11/2019** | Add 9on12 Device Creation |
| **11/12/2019** | Update Direct3DCreate9On12* Override Description |

## Open Issues

  | Issue Number | Description |
  | ------------ | ----------- |
  |              |             |


## Overview 
Windows provides implementations of the D3D9 and D3D11 DDI that map those DDI calls to the D3D12 API.  This spec describes API for these translation layers to enable efficient interop of resources created by the layer and with D3D12 usage.

## Synchronizing Resource Access
The translation layers internally track resource usage and synchronize access using the standard D3D12 API.  The Unwrap and Return API allow callers to synchronize with translation layer usage.  

The UnwrapUnderlyingResource API takes an ID3D12Queue instance as an input parameter.  Any pending work accessing the resource causes fence waits to be scheduled on this queue.  Callers can then queue further work on this queue, including a signal on a caller owned fence.

The ReturnUnderlyingResource API takes a list of ID3D12Fence instances and a parallel list of signal values.  This must include any pending work against the resource submitted by the caller.  The translation layer defers the waits for these resources until work is scheduled against the resource.

Additionally, the UnwrapUnderlyingResource checks out the resource from the translation layer.  No translation layer usage through either the D3D9 or D3D11 API may be scheduled while the resource is checked out.  The resource remains checked out until it is returned via ReturnUnderlyingResource.

## D3D11 Resource Interop
```c++
interface ID3D11On12Device2
```

The D3D 11on12 Device interface is rev'd to add methods for unwrapping and returning a translation layer resource.  The ID3D11on12Device1 already exposed a GetD3D12Device.

### ID3D11on12Device2::UnwrapUnderlyingResource

```c++
HRESULT UnwrapUnderlyingResource(
    [annotation("_In_")] ID3D11Resource* pResource11, 
    [annotation("_In_")] ID3D12CommandQueue* pCommandQueue,
    REFIID riid,
    [annotation("_COM_Outptr_")] void** ppvResource12 );
```

Checks out the underlying D3D12 resource from the translation layer.  This method does not Flush and may schedule GPU work.  The caller should Flush after calling this method if the caller exteranlly waits for completion.

**Paramters**  
*pResource11*  
The D3D11 resource to unwrap.  This resource must not have D3D12_RESOURCE_DIMENSION_BUFFER, D3D11_RESOURCE_MISC_GDI_COMPATIBLE, or D3D11_RESOURCE_MISC_SHARED_KEYEDMUTEX. 

*pCommandQueue*  
This queue has waits scheduled for any pending work on the resource being unwrapped.

*riid*  
The interface id for a D3D12 resource, such as __uuidof(ID3D12Resource).

*ppvResource12*  
On return, the D3D12 resource pointer.

### ID3D11on12Device2::ReturnUnderlyingResource
```c++
HRESULT ReturnUnderlyingResource(
    [annotation("_In_")] ID3D11Resource* pResource11, 
    UINT NumSync,
    [annotation("_In_reads_(NumSync) ")] UINT64* pSignalValues,
    [annotation("_In_reads_(NumSync) ")] ID3D12Fence** ppFences );
```

Returns the underlying D3D12 resource from the translation layer.

**Parameters**  

*pResource11*  
The D3D11 resource to return.

*NumSync*  
The count of the pSignalValues and ppFences parallel arrays.

*pSignalValues*  
The list of values that will be signaled once any caller scheduled work is completed.

*ppFences*  
The list of fences that will be signaled once any caller schedule work is completed.

## D3D9 Device Creation

### Struct: 
```c++
#define MAX_D3D9ON12_QUEUES        2

typedef struct _D3D9ON12_ARGS
{
    BOOL Enable9On12;
    IUnknown *pD3D12Device;
    IUnknown *ppD3D12Queues[MAX_D3D9ON12_QUEUES];
    UINT NumQueues;
    UINT NodeMask;
} D3D9ON12_ARGS;
```
**Members**

*Enable9On12*
Set TRUE to use 9On12 with the corresponding adapter.

*pD3D12Device*
Optional pointer to the D3D12 Device to use.  If this pointer is specified, this override applies to the display adapter with the same adapter LUID as the D3D12 Device.  If nullptr is specified and Enable9On12 is TRUE, this override applies to any adapter that doesn't match another override in the list.

*ppD3D12Queues*
Optionally specify the Direct graphics command queue instance to use.  If nullptr and Enable9on12 is TRUE, 9On12 will internally create the graphics queue.  The second entry of this array is reserved.

*NumQueues*
Specifies the number of Queues in ppD3D12Queues array.  Must be 0 or 1.  See ppD3D12Queues.

*NodeMask*
Specifies the nodes to use in linked display adapter.  Zero specifies the default node 1. 

## Function: Direct3DCreate9On12Ex
```c++
HRESULT WINAPI Direct3DCreate9On12Ex(UINT SDKVersion, D3D9ON12_ARGS *pOverrideList, UINT NumOverrideEntries, IDirect3D9Ex** ppOutputInterface);
```
Creates the Direct3D9Ex active display adapter enumerator with optional overrides to use D3D9On12.

**Parameters**

*SDKVersion*
The value of this parameter should be D3D_SDK_VERSION.

*pOverrideList*
The list of per-active adapter overrides indicating if a 9On12 device should be created.

*NumOverrideEntries*
The count of override entries specified in pOverrideList.  NumOverrideEntries may be zero see remarks.

*ppOutputInterface*
Returns a pointer to the IDirect3D9Ex enumerator.

**Return Value**

*D3DERR_NOTAVAILABLE*
If Direct3DEx features are not supported (no WDDM driver is installed) or if the SDKVersion does not match the version of the DLL.

*D3DERR_OUTOFMEMORY* 
If out-of-memory conditions are detected when creating the enumerator object.

*S_OK*
If the creation of the enumerator object is successful.

**Remarks**

Override entries overried settings for an enumerated display adapter with 9On12 settings.  If zero is specified for NumOverrideEntries, this method behaves like Direct3DCreate9Ex.

The IDirect3D9Ex object is the first object that the application creates and the last object that the application releases. Functions for enumerating and retrieving capabilities of a device are accessible through the IDirect3D9Ex object. This enables applications to select devices without creating them.

The IDirect3D9Ex interface supports enumeration of active display adapters and allows the creation of IDirect3D9Ex objects. If the user dynamically adds adapters (either by adding devices to the desktop, or by hot-docking a laptop), these devices are not included in the enumeration. Creating a new IDirect3D9Exinterface will expose the new devices.

Pass the D3D_SDK_VERSION flag to this function to ensure that header files used in the compiled application match the version of the installed runtime DLLs. D3D_SDK_VERSION is changed in the runtime only when a header or another code change would require rebuilding the application. If this function fails, it indicates that the versions of the header file and the runtime DLL do not match.

See Direct3DCreate9Ex for additional remarks.

## Function: Direct3DCreate9On12
```c++
IDirect3D9* WINAPI Direct3DCreate9On12(UINT SDKVersion, D3D9ON12_ARGS *pOverrideList, UINT NumOverrideEntries);
```

Creates the Direct3D9 active display adapter enumerator with optional overrides to use D3D9On12.

**Parameters**

*SDKVersion*
The value of this parameter should be D3D_SDK_VERSION.

*pOverrideList*
The list of per-active adapter overrides indicating if a 9On12 device should be created.

*NumOverrideEntries*
The count of override entries specified in pOverrideList.  NumOverrideEntries may be zero see remarks.

**Remarks**

Override entries overried settings for an enumerated display adapter with 9On12 settings.  If zero is specified for NumOverrideEntries, this method behaves like Direct3DCreate9.

The IDirect3D9 interface supports enumeration of active display adapters and allows the creation of IDirect3DDevice9 objects. If the user dynamically adds adapters (either by adding devices to the desktop, or by hot-docking a laptop), those devices will not be included in the enumeration. Creating a new IDirect3D9 interface will expose the new devices.

D3D_SDK_VERSION is passed to this function to ensure that the header files against which an application is compiled match the version of the runtime DLL's that are installed on the machine. D3D_SDK_VERSION is only changed in the runtime when a header change (or other code change) would require an application to be rebuilt. If this function fails, it indicates that the header file version does not match the runtime DLL version.

See Direct3DCreate9 for additional remarks.

**Return Value**
If successful, this function returns a pointer to an IDirect3D9 interface; otherwise, a NULL pointer is returned.

## D3D9 Resource Interop
```c++
interface IDirect3DDevice9On12
```

The D3D 9on12 Device interface is exposed with methods for unwrapping and returning a translation layer resource.  Call QueryInterface on the D3D9 device to retrieve this interface.  If the D3D9 device is not a 9on12 device, QueryInterface will fail with E_NOINTERFACE.

### IDirect3DDevice9On12::GetD3D12Device
```c++
HRESULT GetD3D12Device(
    REFIID riid, 
    [annotation("_COM_Outptr_")] void** ppvDevice);
```

**Paramters**  

*riid*  
The interface ID of the D3D12 device.  Example: __uuidof(ID3D12Device)

*ppvDevice*  
On return, the underlying D3D12 device pointer.


### IDirect3DDevice9On12::UnwrapUnderlyingResource

```c++
HRESULT UnwrapUnderlyingResource(
    [annotation("_In_")] IDirect3DResource9* pResource9, 
    [annotation("_In_")] ID3D12CommandQueue* pCommandQueue,
    REFIID riid,
    [annotation("_COM_Outptr_")] void** ppvResource12 );
```

Checks out the underlying D3D12 resource from the translation layer.

**Paramters**  

*pResource9*  
The D3D9 resource to unwrap.

*pCommandQueue*  
This queue has waits scheduled for any pending work on the resource being unwrapped.

*riid*  
The interface id for a D3D12 resource, such as __uuidof(ID3D12Resource).

*ppvResource12*  
On return, the D3D12 resource pointer.

### IDirect3DDevice9On12::ReturnUnderlyingResource
```c++
HRESULT ReturnUnderlyingResource(
    [annotation("_In_")] IDirect3DResource9* pResource9, 
    UINT NumSync,
    [annotation("_In_reads_(NumSync) ")] UINT64* pSignalValues,
    [annotation("_In_reads_(NumSync) ")] ID3D12Fence** ppFences );

```

Returns the underlying D3D12 resource from the translation layer.

**Parameters**  

*pResource9*  
The D3D9 resource to return.

*NumSync*  
The count of the pSignalValues and ppFences parallel arrays.

*pSignalValues*  
The list of values that will be signaled once any caller scheduled work is completed.

*ppFences*  
The list of fences that will be signaled once any caller schedule work is completed.
