# Recreate at GPUVA <!-- omit in TOC -->

---

# Contents <!-- omit in TOC -->

- [Recreate at GPUVA ](#recreate-at-gpuva-)
- [Contents ](#contents-)
- [Summary](#summary)
- [API/DDI](#apiddi)
  - [RecreateAt for Resources (Buffers) and Heaps](#recreateat-for-resources-buffers-and-heaps)
  - [DDI](#ddi)
    - [Record](#record)
    - [Replay](#replay)
  - [D3D12 API](#d3d12-api)
    - [Check for support](#check-for-support)
    - [Record](#record-1)
      - [`ID3D12PageableTools::GetAllocation` Getting the GPUVA of a given object](#id3d12pageabletoolsgetallocation-getting-the-gpuva-of-a-given-object)
    - [Replay](#replay-1)
      - [`ID3D12DeviceTools::SetNextAllocationAddress` Setting the next GPUVA](#id3d12devicetoolssetnextallocationaddress-setting-the-next-gpuva)
      - [`ID3D12Tools1::ReserveGPUVARangesAtCreate` Reserving GPUVAs on device creation](#id3d12tools1reservegpuvarangesatcreate-reserving-gpuvas-on-device-creation)
  - [Sample code](#sample-code)
- [Spec History](#spec-history)

---

# Summary

This document documents D3D12 functionality that would allow capture/replay tools such as PIX on Windows to capture D3D objects at certain GPU virtual addresses (GPUVAs) in one process and then create (“recreate”) functionally equivalent D3D objects at the same GPUVAs in a different process.

D3D12 is only able to recreate heaps and buffers.

# API/DDI

## RecreateAt for Resources (Buffers) and Heaps

## DDI
### Record
Existing DDI `CheckExistingResourceAllocation` will be used to retrieve heap and resource size during capture. `ResourceDataSize` will be recorded as the allocation size and provided as part of the Reserved GPUVA Ranges at startup (see [D3D12ReserveGpuvaRanges](#d3d12reservegpuvaranges)).
### Replay
DDI rev 0109 adds `CreateAtVirtualAddress` to resource creation. If `CreateAtVirtualAddress` is 0, behavior is unchanged from resource creation DDI 0088. 
**Note: While the DDI rev is on 109, RecreateAt functionality is gated behind DDI 0111. **

A non-zero value for `CreateAtVirtualAddress` is only valid only for heaps and buffer resources. The debug layer will validate against providing a value for `CreateAtVirtualAddress` for any non-buffer resources. 

For placed resources, the underlying heap needs to be created with a specified virtual addresss. `HeapOffset` will match the original value passed during recording, and if `CreateAtVirtualAddress` is non-zero, the resource's GPUVA must be `CreateAtVirtualAddress`.

If `CreateAtVirtualAddress` is non-zero, the resource *must* be created at the specified address. If the resource cannot be created at `CreateAtVirtualAddress`, then `CreateHeapAndResource_0107` *must* return an error code and not fault or trigger a TDR.

The expected required address range must be reserved by the application before resource creation.

```c++
typedef struct D3D12DDIARG_CREATERESOURCE_0109
{
  // D3D12DDIARG_CREATERESOURCE_0088
    D3D12DDIARG_BUFFER_PLACEMENT    ReuseBufferGPUVA;
    D3D12DDI_RESOURCE_TYPE          ResourceType;
    UINT64                          Width;
    UINT                            Height;
    UINT16                          DepthOrArraySize; 
    UINT16                          MipLevels;
    DXGI_FORMAT                     Format; 
    DXGI_SAMPLE_DESC                SampleDesc;
    D3D12DDI_TEXTURE_LAYOUT         Layout;
    D3D12DDI_RESOURCE_FLAGS_0003    Flags;
    D3D12DDI_BARRIER_LAYOUT         InitialBarrierLayout;
    CONST D3D12DDIARG_ROW_MAJOR_RESOURCE_LAYOUT* pRowMajorLayout;
    D3D12DDI_MIP_REGION_0075        SamplerFeedbackMipRegion;
    UINT32                          NumCastableFormats;
    const DXGI_FORMAT *             pCastableFormats;

  // D3D12DDIARG_CREATERESOURCE_0107
    D3D12DDI_GPU_VIRTUAL_ADDRESS    CreateAtVirtualAddress;
} D3D12DDIARG_CREATERESOURCE_0109;

typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATEHEAPANDRESOURCE_0107)( 
    D3D12DDI_HDEVICE, _In_opt_ CONST D3D12DDIARG_CREATEHEAP_0001*, D3D12DDI_HHEAP, D3D12DDI_HRTRESOURCE,
    _In_opt_ CONST D3D12DDIARG_CREATERESOURCE_0107*, _In_opt_ CONST D3D12DDI_CLEAR_VALUES*, 
    D3D12DDI_HPROTECTEDRESOURCESESSION_0030, D3D12DDI_HRESOURCE );
    
typedef D3D12DDI_HEAP_AND_RESOURCE_SIZES ( APIENTRY* PFND3D12DDI_CALCPRIVATEHEAPANDRESOURCESIZES_0107)(
     D3D12DDI_HDEVICE, _In_opt_ CONST D3D12DDIARG_CREATEHEAP_0001*, _In_opt_ CONST D3D12DDIARG_CREATERESOURCE_0107*,
     D3D12DDI_HPROTECTEDRESOURCESESSION_0030 );

typedef VOID ( APIENTRY* PFND3D12DDI_CHECKRESOURCEALLOCATIONINFO_0107)(
    D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATERESOURCE_0107*, D3D12DDI_RESOURCE_OPTIMIZATION_FLAGS,
    UINT32 AlignmentRestriction, UINT VisibleNodeMask, _Out_ D3D12DDI_RESOURCE_ALLOCATION_INFO_0022* );

```


DDI rev 109 also changes the create device DDI, by adding an array of `D3D12DDI_GPU_VIRTUAL_ADDRESS_RANGE` that is meant to be reserved on device creation.
```c++
typedef struct D3D12DDIARG_CREATEDEVICE_0109
{
// ---> D3D12DDIARG_CREATEDEVICE_0003
    D3D12DDI_HRTDEVICE              hRTDevice;              // in:  Runtime handle
    UINT                            Interface;              // in:  Interface version
    UINT                            Version;                // in:  Runtime Version
    CONST D3DDDI_DEVICECALLBACKS*   pKTCallbacks;           // in:  Pointer to runtime callbacks that invoke kernel
    D3D12DDI_HDEVICE                hDrvDevice;             // in:  Driver private handle/ storage.
    union
    {
        CONST D3D12DDI_CORELAYER_DEVICECALLBACKS_0003* p12UMCallbacks; // in:  callbacks that stay in usermode
        CONST struct D3D12DDI_CORELAYER_DEVICECALLBACKS_0022* p12UMCallbacks_0022; // in:  callbacks that stay in usermode
        CONST struct D3D12DDI_CORELAYER_DEVICECALLBACKS_0050* p12UMCallbacks_0050; // in:  callbacks that stay in usermode
        CONST struct D3D12DDI_CORELAYER_DEVICECALLBACKS_0062* p12UMCallbacks_0062; // in:  callbacks that stay in usermode
    };
    D3D12DDI_CREATE_DEVICE_FLAGS    Flags; // in:  

// ---> D3D12DDIARG_CREATEDEVICE_0107
    D3D12DDI_GPU_VIRTUAL_ADDRESS_RANGE* pReserveRanges;
    UINT NumReserveRanges;

} D3D12DDIARG_CREATEDEVICE_0109;

```

## D3D12 API

### Check for support
As not all graphic cards or drivers suppport this feature, a feature support check is highly recommended before using Recreate At GPUVA. 

```c++

enum D3D12_RECREATE_AT_TIER
    {
        D3D12_RECREATE_AT_TIER_NOT_SUPPORTED	= 0,
        D3D12_RECREATE_AT_TIER_1	= 1
    } 	D3D12_RECREATE_AT_TIER;

typedef struct D3D12_FEATURE_DATA_D3D12_OPTIONS20
    {
    _Out_  BOOL ComputeOnlyWriteWatchSupported;
    D3D12_RECREATE_AT_TIER RecreateAtTier;
    } 	D3D12_FEATURE_DATA_D3D12_OPTIONS20;
```

### Record
#### `ID3D12PageableTools::GetAllocation` Getting the GPUVA of a given object
Queryable from resources and heaps, `ID3D12PageableTools` provides `GetAllocation` to retrieve the associated `D3D12_GPU_VIRTUAL_ADDRESS_RANGE`.
```c++
    class ID3D12PageableTools : public IUnknown
    {
    public:
        virtual HRESULT STDMETHODCALLTYPE GetAllocation( 
            _Inout_  D3D12_GPU_VIRTUAL_ADDRESS_RANGE *pAllocation) = 0;
        
    };
```

### Replay
#### `ID3D12DeviceTools::SetNextAllocationAddress` Setting the next GPUVA

Queryable from a device object, `ID3D12DeviceTools` provides `SetNextAllocationAddress` to set the virtual address of the next resource or heap created on the caller's thread. Called right before creating a heap or resource, `ID3D12DeviceTools::SetNextAllocationAddress` will assign the VA for that object.

```c++
    class ID3D12DeviceTools : public IUnknown
    {
    public:
        virtual void STDMETHODCALLTYPE SetNextAllocationAddress( 
            UINT64 pVirtualAddress) = 0;
        
    };
```
The assignment is per-thread and is cleared after the object is created. To assign another allocation on the same thread, call `SetNextAllocationAddress` again.

#### `ID3D12Tools1::ReserveGPUVARangesAtCreate` Reserving GPUVAs on device creation

GPUVA ranges used during replay must be reserved immediately after KM device creation and before D3D device initialization, for them to be available for the replay process to place resources at. To specify reserved ranges during create, use `ID3D12Tools1` queried as a configuration interface from an `ID3D12DeviceFactory`

```c++
  // d3d12.h
    class ID3D12Tools1 : public ID3D12Tools
    {
    public:
        virtual void ReserveGPUVARangesAtCreate( 
            _In_reads_(uiNumRanges)  D3D12_GPU_VIRTUAL_ADDRESS_RANGE *pRanges,
            _In_  UINT uiNumRanges) = 0;
    };
```

Each call to `ReserveGPUVARangesAtCreate` will _append_ the set of given ranges to the internal start-up configuration. When calling `CreateDevice` from the parent `ID3D12DeviceFactory`, these ranges will be passed into the driver during creation via `PFND3D12DDI_CREATEDEVICE_0109` which must immediately reserve them.

Ranges provided to `CreateDevice` are not processed in any way and may or may not be aligned in offset or size and may or may not overlap, depending on driver behavior during record. 

```c++
    // d3d12.h
    class ID3D12DeviceTools
    {
    public:
        virtual void STDMETHODCALLTYPE SetNextAllocationAddress( 
            UINT64 pVirtualAddress) = 0;
        
    };
```

## Sample code
Here is a shortened code to show how the APIs come together (code is truncated to show functionality and is not intended to run).

```c++

  // Assuming this is the capture run
  // This will capture the GPUVAs
  std::vector<D3D12_GPU_VIRTUAL_ADDRESS_RANGE> m_recordedAddressRange; 
  // Create Device
  pDeviceFactory->CreateDevice( 
      nullptr,
      D3D_FEATURE_LEVEL_11_0,
      IID_PPV_ARGS(&pDevice)
  );

  // Check for feature support
  D3D12_FEATURE_DATA_D3D12_OPTIONS20 options20 = {};
  if (pDevice->CheckFeatureSupport(D3D12_FEATURE_D3D12_OPTIONS20, &options20, sizeof(D3D12_FEATURE_DATA_D3D12_OPTIONS20)) != S_OK)
  {
      // Driver does not support recreate at.
      return;
  }

  if (options20.RecreateAtTier != D3D12_RECREATE_AT_TIER_1)
  {
      // Driver does not support recreate at.
      return;
  }


  // Describe the heap and resource on which to place the buffer
  const CD3DX12_RESOURCE_DESC BufDesc = CD3DX12_RESOURCE_DESC::Buffer(2048);
  const CD3DX12_HEAP_PROPERTIES HeapProp(D3D12_HEAP_TYPE_DEFAULT);
  ID3D12Resource* pBufferResource;

  // Create a resource
  pDevice->CreateCommittedResource2(
    &HeapProp,
    D3D12_HEAP_FLAG_NONE,
    &BufDesc1,
    D3D12_RESOURCE_STATE_COMMON,
    nullptr,
    nullptr,
    IID_PPV_ARGS(&pBufferResource));

  // Get resource's GPUVA
  D3D12_GPU_VIRTUAL_ADDRESS_RANGE addressRange;
  ID3D12PageableTools* pPageableTools;
  pBufferResource->QueryInterface(&pPageableTools);
  pPageableTools->GetAllocation(&addressRange);

  // Record GPUVA for next run
  m_recordedAddressRange.push_back(addressRange); 

  // Assume capture run ends, and device is out of scope. Now we're running replay mode

  // Get the device factory so that we can have access to Tools and create our own device, note needs developer mode
  ID3D12DeviceFactory* pDeviceFactory;
  D3D12GetInterface(CLSID_D3D12DeviceFactory, IID_PPV_ARGS(&pDeviceFactory));
  ID3D12Tools1* pD3D12Tools;
  pDeviceFactory->GetConfigurationInterface(CLSID_D3D12Tools, IID_PPV_ARGS(&pD3D12Tools));

  // Reserve GPUVAs before device creation
  pD3D12Tools->ReserveGPUVARangesAtCreate(
    m_recordedAddressRange.data(),
    static_cast<UINT>(m_recordedAddressRange.size())
  );
  // Create device with GPU ranges reserved
  pDeviceFactory->CreateDevice( 
    nullptr,
    D3D_FEATURE_LEVEL_11_0,
    IID_PPV_ARGS(&pDevice)
  );

  // Create a device tool (for setting the allocation in capture mode)
  CComPtr<ID3D12DeviceTools> pDeviceTools;
  pDevice->QueryInterface(&pDeviceTools);

  // Set the GPUVA before allocating the resource
  pDeviceTools->SetNextAllocationAddress(m_recordedAddressRange[0].StartAddress);

  // Create resource at the given GPUVA
  pDevice->CreateCommittedResource2(
    &HeapProp,
    D3D12_HEAP_FLAG_NONE,
    &BufDesc1,
    D3D12_RESOURCE_STATE_COMMON,
    nullptr,
    nullptr,
    IID_PPV_ARGS(&pBufferResource));
```

# Spec History

| Version | Date | Details | Author |
|-|-|-|-|
| v0.01 | 5 Oct 2022 | Initial draft spec, mostly background + challenges | Austin Kinross (PIX) |
| v0.02 | 30 Dec 2022 | Minor updates in response to internal MS feedback | Austin Kinross (PIX) |
| v0.03 | 1 May 2023 | Updates based on initial discussions | Austin Kinross (PIX) |
| v0.04 | 7 June 2023 | Split into non-DDI / DDI portions, spec'd some functionality | Giancarlo Devich |
| v0.05 | 19 June 2023 | Removed non-DDI version, spec'd DDIs for heaps and resources, updated API naming | Giancarlo Devich |
| v0.06 | 14 Aug 2023 | Formalize recreate for resources is specific to buffers. Update proposed DDI version to 0107 | Giancarlo Devich
| v0.06 | 16 Aug 2023 | Rev CreateDevice to pass in reserved ranges; no longer reserving ranges with DXGI | Giancarlo Devich
| v0.07 | 06 Jun 2024 | Fixed wrongly documented structs with 0107 to 0109. Added gate that prevents recreate at from running at a lower DDI then 0111. | Roland Shum
| v0.07 | 22 Jan 2025 | Trimmed documentation for public viewing, while updating the document to reflect progress. Added sample code | Roland Shum 