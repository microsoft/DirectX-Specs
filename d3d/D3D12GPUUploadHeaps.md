# D3D12 GPU Upload Heaps

## Background

It used to be typical for a discrete GPU to have only a small portion of its frame buffer exposed over the PCI bus. D3D chose not to expose this because the I/O region for a frame buffer is usually only 256MB, which is not that useful. A bigger problem was that it's not a properly virtualizable resource. If app A comes in and allocates all 256MB, then app B wouldn't be able to allocate any. So we can't provide any guarantees around it, at which point it seemed like a bad idea to expose to apps.

However, now there are a lot of GPUs that support a resizable base address register(also known as Resizable BAR). With a resizable bar, Windows will renegotiate the size of a GPU's BAR in WDDM Version 2.0 and later. Another good reason for D3D12 to expose Resizable BAR is that some performance testing on some platforms has shown that games perform better with resizeable BAR enabled.

D3D now decides to support the use of CPU visible VRAM via D3D GPU upload heaps on both discrete and integrated GPUs.

One reason to use GPU upload heaps on integrated GPUs is that you can use GPU upload heaps instead of using upload + default heaps for resources, so there's no need to do a lot of copy operations just to put the resource in a different state. Alternatively this optimization can be done via [UMA Optimizations: CPU Accessible Textures and Standard Swizzle](https://docs.microsoft.com/en-us/windows/win32/direct3d12/default-texture-mapping).

## Support GPU upload heaps with D3D12_HEAP_TYPE_GPU_UPLOAD

When creating D3D12 resources, we need to specify D3D12_HEAP_PROPERTIES.

```c++
typedef struct D3D12_HEAP_PROPERTIES {
  D3D12_HEAP_TYPE         Type;
  D3D12_CPU_PAGE_PROPERTY CPUPageProperty;
  D3D12_MEMORY_POOL       MemoryPoolPreference;
  UINT                    CreationNodeMask;
  UINT                    VisibleNodeMask;
} D3D12_HEAP_PROPERTIES;
```

In addition to existing heap types, now there is D3D12_HEAP_TYPE_GPU_UPLOAD.

```c++
typedef enum D3D12_HEAP_TYPE {
  D3D12_HEAP_TYPE_DEFAULT = 1,
  D3D12_HEAP_TYPE_UPLOAD = 2,
  D3D12_HEAP_TYPE_READBACK = 3,
  D3D12_HEAP_TYPE_CUSTOM = 4,
  D3D12_HEAP_TYPE_GPU_UPLOAD = 5,
} ;
```

Like D3D12_HEAP_TYPE_DEFAULT, D3D12_HEAP_TYPE_UPLOAD, and D3D12_HEAP_TYPE_READBACK, when heap type is set to D3D12_HEAP_TYPE_GPU_UPLOAD, CPUPageProperty and MemoryPoolPreference must be ..._UNKNOWN.

On discrete GPUs, Upload heaps have D3D12_MEMORY_POOL_L0 as their memory pool while GPU upload heaps have D3D12_MEMORY_POOL_L1 as their memory pool. And the page property for GPU upload heaps is the same as upload heaps, which is D3D12_CPU_PAGE_PROPERTY_WRITE_COMBINE. We usually do not want to read any of this memory back from GPU, because such reads are inefficient.

On integrated GPUs, the memory pool is always D3D12_MEMORY_POOL_L0.

## Support GPU upload heaps with custom heaps

Just like other existing non-custom heap types, we also need to allow custom heaps to support GPU upload heaps. 

On discrete GPUs, when the heap type is D3D12_HEAP_TYPE_CUSTOM, we can specify the D3D12_CPU_PAGE_PROPERTY to be D3D12_CPU_PAGE_PROPERTY_WRITE_COMBINE and the MemoryPoolPreference to be D3D12_MEMORY_POOL_L1. Custom heaps created like this are equivalent to GPU upload heaps.

On integrated GPUs, MemoryPoolPreference needs to be D3D12_MEMORY_POOL_L0 and D3D12_CPU_PAGE_PROPERTY can be D3D12_CPU_PAGE_PROPERTY_WRITE_COMBINE/D3D12_CPU_PAGE_PROPERTY_WRITE_BACK depends on the adapter architecture.

GetCustomHeapProperties supports D3D12_HEAP_TYPE_GPU_UPLOAD and it can always be used to get the corresponding CPUPageProperty and MemoryPoolPreference for current adapter architecture.

**When D3D12_FEATURE_DATA_ARCHITECTURE::UMA is FALSE**

The returned D3D12_HEAP_PROPERTIES members convert as follows:

| Heap Type   | How the returned D3D12_HEAP_PROPERTIES members convert|
| :---        |     :--- |
| D3D12_HEAP_TYPE_UPLOAD    | CPUPageProperty = WRITE_COMBINE, MemoryPoolPreference = L0.   |
| D3D12_HEAP_TYPE_DEFAULT   | CPUPageProperty = NOT_AVAILABLE, MemoryPoolPreference = L1.   |
| D3D12_HEAP_TYPE_READBACK   | CPUPageProperty = WRITE_BACK, MemoryPoolPreference = L0.   |
| D3D12_HEAP_TYPE_GPU_UPLOAD   | CPUPageProperty = WRITE_COMBINE, MemoryPoolPreference = L1.   |

When GPU upload heaps are not supported, D3D12_HEAP_TYPE_GPU_UPLOAD still returns the same result as above but D3D12 will not allow this to be used.

Currently we don't plan to support WRITE_BACK with L1 unless there is a good reason for doing this. If we eventually need to support WRITE_BACK with L1, we can support this with custom heaps.

**When D3D12_FEATURE_DATA_ARCHITECTURE::UMA is TRUE and D3D12_FEATURE_DATA_ARCHITECTURE::CacheCoherentUMA is FALSE**

The returned D3D12_HEAP_PROPERTIES members convert as follows:

| Heap Type   | How the returned D3D12_HEAP_PROPERTIES members convert|
| :---        |     :--- |
| D3D12_HEAP_TYPE_UPLOAD    | CPUPageProperty = WRITE_COMBINE, MemoryPoolPreference = L0.   |
| D3D12_HEAP_TYPE_DEFAULT   | CPUPageProperty = NOT_AVAILABLE, MemoryPoolPreference = L0.   |
| D3D12_HEAP_TYPE_READBACK   | CPUPageProperty = WRITE_BACK, MemoryPoolPreference = L0.   |
| D3D12_HEAP_TYPE_GPU_UPLOAD   | CPUPageProperty = WRITE_COMBINE, MemoryPoolPreference = L0.   |

**When D3D12_FEATURE_DATA_ARCHITECTURE::UMA is TRUE and D3D12_FEATURE_DATA_ARCHITECTURE::CacheCoherentUMA is TRUE**

The returned D3D12_HEAP_PROPERTIES members convert as follows:

| Heap Type   | How the returned D3D12_HEAP_PROPERTIES members convert|
| :---        |     :--- |
| D3D12_HEAP_TYPE_UPLOAD    | CPUPageProperty = WRITE_BACK, MemoryPoolPreference = L0.   |
| D3D12_HEAP_TYPE_DEFAULT   | CPUPageProperty = NOT_AVAILABLE, MemoryPoolPreference = L0.   |
| D3D12_HEAP_TYPE_READBACK   | CPUPageProperty = WRITE_BACK, MemoryPoolPreference = L0.   |
| D3D12_HEAP_TYPE_GPU_UPLOAD   | CPUPageProperty = WRITE_BACK, MemoryPoolPreference = L0.   |

When the architecture is UMA, the CPUPageProperty and MemoryPoolPreference returned from D3D12_HEAP_TYPE_GPU_UPLOAD are the same as those returned from D3D12_HEAP_TYPE_UPLOAD.

## How do we detect if GPU upload heaps are supported

**Note: GPU upload heaps can only be supported with developer mode enabled.**

There is a new UMD cap to report if GPU upload heaps are supported.

We have
1. bool L1MemoryFullyCpuAccessible - indicates whether GPU upload heaps are supported on current device

On discrete GPUs, L1MemoryFullyCpuAccessible is true if the entire frame buffer is CPU visible.

On integrated GPUs, L1MemoryFullyCpuAccessible is always true.

Kernel doesn't need this information and it's very unlikely that this cap will be used by other applications or system components, so we are not making this cap a kernel cap. 

```c++
// D3D12DDICAPS_TYPE_OPTIONS_0098
typedef struct D3D12DDI_OPTIONS_0098
{
    bool L1MemoryFullyCpuAccessible;
} D3D12DDI_OPTIONS_DATA_0098;
```

## How to find if GPU upload heaps are supported as a developer

Use CheckFeatureSupport to see if GPU upload heaps are supported on current device. We'll return a struct with the following value: 

1. bool GPUUploadHeapSupported - whether GPU upload heaps are supported on current device

GPUUploadHeapSupported is in D3D12_FEATURE_D3D12_OPTIONS16.

GPU upload heaps can be used only if GPUUploadHeapSupported is true. GPU upload heaps creation will fail if they are not supported.


```c++
D3D12_FEATURE_DATA_D3D12_OPTIONS16 options16 = {};
bool GPUUploadHeapSupported = false;
if(SUCCEEDED(pDevice->CheckFeatureSupport(D3D12_FEATURE_D3D12_OPTIONS16, &options16, sizeof(options16))))
{
    GPUUploadHeapSupported = options16.GPUUploadHeapSupported;
}
```

[IDXGIAdapter3::QueryVideoMemoryInfo](https://docs.microsoft.com/en-us/windows/win32/api/dxgi1_4/nf-dxgi1_4-idxgiadapter3-queryvideomemoryinfo) can be used to query the video memory budget, available CPU visible video memory size is the same as local video memory budget when the entire VRAM is CPU visible. When querying video memory budget for GPU upload heaps, MemorySegmentGroup needs to be DXGI_MEMORY_SEGMENT_GROUP_LOCAL. Then it's developers' responsibility to decide if they want to use GPU upload heaps. If they go over budget, we may have to fall back to system memory, which can lead to performance regression.


```c++
DXGI_QUERY_VIDEO_MEMORY_INFO VMInfo;
VERIFY_SUCCEEDED(spAdapter->QueryVideoMemoryInfo(0, DXGI_MEMORY_SEGMENT_GROUP_LOCAL, &VMInfo));
```

## How to use this feature

* Make sure GPUUploadHeapSupported is true after CheckFeatureSupport.
* Create a resource with D3D12_HEAP_TYPE_GPU_UPLOAD, then set CPUPageProperty as D3D12_CPU_PAGE_PROPERTY_UNKNOWN and set MemoryPoolPreference as D3D12_MEMORY_POOL_UNKNOWN.
* (OR Create a resource with D3D12_HEAP_TYPE_CUSTOM, then get CPUPageProperty and MemoryPoolPreference from GetCustomHeapProperties.)
* Use Map to get a CPU pointer to the specified subresource in the resource.
* Upload CPU data to the resource.
* (If using Pix) Use TrackWrite to notify tools like Pix about modifications of the resource.
* Use the resource directly, you do not necessarily need to copy the resource to another resource with a default heap.

## Restrictions

Since GPU upload heaps are CPU-accessible heaps, they do not support shared heap flags such as: 
```c++
D3D12_HEAP_FLAG_SHARED
D3D12_HEAP_FLAG_SHARED_CROSS_ADAPTER
D3D12_HEAP_FLAG_ALLOW_DISPLAY
```


## Validations

* All the existing validations that check other heap types also include D3D12_HEAP_TYPE_GPU_UPLOAD.
* D3D12 emits an error message during resource creation if GPU upload heaps are not supported.
* D3D12 emits an error message during GetCustomHeapProperties if GPU upload heaps are not supported.
* We currently have runtime validations that do not allow COMBINE with L1, this validation still exists unless current device supports GPU upload heaps.

## Testing

There are both conformance test coverage and unit test coverage. 

In conformance test, we verify that GPU upload heaps can only be supported on discrete GPUs if the entire VRAM is CPU visible.

## Update d3d12x.h

We'll update d3d12x.h wrapper for CheckFeatureSupport after this feature completes.

## Support for VRAM-only lockable surfaces

For now, D3D12 GPU upload heaps do not support VRAM-only lockable surfaces. GPU upload heaps also fall back to system memory if there is not enough VRAM to use, and in WDDM 3.0 we have a requirement that all CPU visible allocations must have a fallback to system memory. Therefore, we are not supporting VRAM-only lockable surfaces because they are incompatible with WriteWatch requirements.

## Detect modifications to the GPU Upload Heaps
Write-watch does not detect some writes to GPU upload heaps anyway, so we'll need an approach to detect modifications to GPU upload heaps.

A new heap flag is added to D3D12:
```c++
D3D12_HEAP_FLAG_TOOLS_USE_MANUAL_WRITE_TRACKING
```

This heap flag can only be used when ManualWriteTrackingResourceSupported is supported. An example:

```c++
D3D12_FEATURE_DATA_D3D12_OPTIONS17 options17 = {};
bool ManualWriteTrackingResourceSupported = false;
if(SUCCEEDED(pDevice->CheckFeatureSupport(D3D12_FEATURE_D3D12_OPTIONS17, &options17, sizeof(options17))))
{
    ManualWriteTrackingResourceSupported = options17.ManualWriteTrackingResourceSupported;
}
```

D3D12 sets ManualWriteTrackingResourceSupported to false by default, and tools like Pix will override this value. If this value is false, using D3D12_HEAP_FLAG_TOOLS_USE_MANUAL_WRITE_TRACKING is treated as an error by D3D12.

When this heap flag exists, there is a new notification API that can be used to tell tools (such as PIX) when a region of a resource has been modified from the CPU.

The new notification API is an interface in D3D headers so that other tools can implement it, and QI for it will fail if such implementation is not present.

The notification interface:
```c++
interface ID3D12ManualWriteTrackingResource : IUnknown
{
    void TrackWrite(
        UINT Subresource, 
        [annotation("_In_opt_")] const D3D12_RANGE* pWrittenRange);
};
```

If an ID3D12Heap* is created with the D3D12_HEAP_FLAG_TOOLS_USE_MANUAL_WRITE_TRACKING flag, the application is expected to use ID3D12ManualWriteTrackingResource to notify tools about any CPU resource writes that occur on any placed or committed resources in the heap. Nothing needs to be done for reserved/tiled resources, because D3D12 does not allow Map() to be used on reserved/tiled resources.

When Map() is called, pointer value is not disclosed for opaque swizzled textures. For these textures, writes need to be done using WriteToSubresource(). For PIX, apps do not need to call TrackWrite() for modifications made via WriteToSubresource(), because PIX can already figure out the modifications by looking at WriteToSubresource()'s parameters. This can be different for other tools.

ID3D12ManualWriteTrackingResource can be used with any type of CPU writeable resource, not just GPU upload heaps.

### ID3D12ManualWriteTrackingResource::TrackWrite

```c++
void ID3D12ManualWriteTrackingResource::TrackWrite(
    UINT Subresource,
    const D3D12_RANGE* pWrittenRange
    );
```

| Parameter           |                          |
|---------------------|--------------------------|
| `Subresource`  | Specifies the index of the subresource.|
| `pWrittenRange` | A pointer to a D3D12_RANGE structure that describes the range of memory to track. "Begin" is inclusive while "End" is exclusive. |


ID3D12ManualWriteTrackingResource::TrackWrite notifies the tool of the region the CPU has modified, and the coordinates are subresource-relative. A null pointer indicates the entire subresource might have been modified by the CPU. It is valid to pass a range where End is less than or equal to Begin, but this would mean the CPU didn't write any data.

TrackWrite() must be called after the resource is modified on the CPU but before any call to ExecuteCommandLists() with command lists that depend on the resource modifications. It is ok to call TrackWrite() on regions of the resource that haven’t actually been modified: this will not affect capture correctness, but it may have a minor impact on capture perf.

D3D12 debug layer does not validate ID3D12ManualWriteTrackingResource::TrackWrite, tools will implement their own validations for it.