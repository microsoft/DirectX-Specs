# D3D12 Resource Heaps

This document is the consolidated D3D12 resource-heaps spec — the API and
DDI surface for application-managed heaps (`ID3D12Heap`) and the resources
placed into them (committed, placed, reserved). It covers four conceptual
feature areas: the core heap design, Parameterized Swizzle, Peer-to-Peer
LDA Atomics, and Memory Management. Where an adjacent feature supersedes
earlier content (for example, the heap-flag and heap-property
declarations), the body is updated in place and an HTML comment records
the supersession. Adjacent-feature material that does not override existing
content is presented in its own top-level section.

Translation is intentionally near-verbatim from the contributing
iterations; the appendix records the design's evolution over time.

---

## Contents

* [Resource vs Heap](#resource-vs-heap)
* [Heaps](#heaps)
  * [Shared Resources and Heaps](#shared-resources-and-heaps)
* [Resources](#resources)
  * [Create Resource](#create-resource)
  * [Common Resource Interface and Description](#common-resource-interface-and-description)
  * [Resource Size Reflection](#resource-size-reflection)
  * [Map and Unmap](#map-and-unmap)
* [Copy Operations](#copy-operations)
* [Strip-mine CPU copy operations](#strip-mine-cpu-copy-operations)
* [Caps](#caps)
* [DDI Surface](#ddi-surface)
* [Parameterized Swizzle](#parameterized-swizzle)
* [Peer-to-Peer LDA Atomics](#peer-to-peer-lda-atomics)
* [Memory Management](#memory-management)
* [Appendix A - Design History](#appendix-a---design-history)

---

## Resource vs Heap

Resources are associated with virtual memory functionality, while heaps are associated with physical memory functionality. These associations are honored more at the DDI, to encourage driver simplification and ease DDI evolution. But, the associations are more loosely honored at the API, to simplify application concepts and avoid leveraging the available orthogonality implied by the DDI design. The following obstacles exist to fully leveraging the functionality implied by a full separation of resource & heap at the DDI:

- Randomized swizzle patterns are leveraged to maximize memory bandwidth during G-buffer rendering to multiple render targets of the same size. This is planned to be fixed with GPUs that support standard swizzle.
- An earlier GPU revision only has 31-bits of VA space globally, which tempers use of virtual address reservation features on systems with greater amounts of physical memory. This has already been addressed in later GPU revisions.
    - A later GPU revision still suffers from 31-bits of GPU VA when being read as a texture.
    - A further GPU revision brings along 64KB pages; but not standard layout.
- Compression data design is tightly integrated into the MMU page table design. Buffers and textures are represented vastly different, and there are many compression data techniques when render targets and depth stencil are involved.
    - Buffers cannot alias to physical memory to understand a particular texture's tile contents on TR tier 1. The swizzling reaches outside the texture tile until TR tier 2, when uniform address swizzling was introduced in a later GPU revision.
    - But, the compression data storage technique has been unified into 3 buckets: buffers (no compression data), textures (single compression page-kind), RT & DS textures (multiple compression page-kinds that have a unified usage of compression data chunk).
- The global swizzling table was redesigned on older hardware to increase 64KB alignment efficiency. However, it wasn't perfect; and some regressions will be noticed when switching from one driver version to another. The regressions affect all APIs on the system, so D3D12 isn't disadvantaged.
- Tile-based deferred rasterizer (TBDR).
- Hardware that can use the same page table from CPU & GPU (aka. SVM); but sparse resource mapping & reservation requires an additional page table translation. That translation hardware is relatively new and there is concern about requiring it for all resources until it is proven out. Additional latency of address translation and the additional memory usage of the table are concerns, and media engines cannot yet leverage that translation hardware. These issues are recognized and are anticipated to be fixed in the next significant hardware redesigns.
- Parameterized swizzle patterns change at a particular mip level.
- "Transparent" migration between memory segments cannot be supported, due to quirks in the compression data design. Resolving compression data puts the design at a significant disadvantage when applications explicitly page in & out content.
    - System memory textures use a different swizzle pattern than video memory.
    - 6 parameterized swizzle patterns are necessary per texture, as the pattern varies at certain mip level transitions.
- IOMMU (aka. SVM) suffers from the 32-bit page-table size in WOW64 processes. Hardware that implements tiled / reserved resources via a virtual-to-virtual page-table indirection can avoid that limit for sparse resources: the indirection itself still has the 32-bit problem when used for basic residency, but NULL mappings within the indirection do not, so the sparse case sidesteps the 32-bit PTE issue.
- Depth stencil compression has two variants, one where texturing is supported and one where the data must be resolved for texturing support.
- The 64K undefined swizzle pattern is implemented with remapped 4K pages outside the 64K region. This workaround is no longer needed once the GPU supports the full standardized layout along with 64K pages, but that isn't the same hardware which supports standard swizzle.
- 32-bit GPU VA on some skus.
- Lossy resource data initialization concerns when compression data is uninitialized.
- The sampler pre-fetcher reads quite far ahead to optimize for common sampling scenarios. There are two resulting issues that can occur: unexpectedly stale GPU cache and GPU access violations when the VA is not mapped. Bloating VA ranges and mapping NULL pages is used to stop faults. Bloating GPU cache flushes operations on Copy operations is used to avoid stale caches. But, simultaneous UAV access cannot be worked around. So, the cross-adapter design may need to resort to padded height techniques.
- A dedicated copy engine functional unit is used that seamless leverages the deep MMU integration, which hides swizzle, compression, and memory synchronization.
- Compression data is likely located on heaps by bloating resources, except standard swizzle.
- Compute can't yet consume swizzled textures on earlier skus.
- Uninitialized compression data concerns.
- Prefers to use 3D/ Compute for copy operations to access all swizzle patterns.

## Heaps

```cpp
typedef enum D3D12_HEAP_TYPE
{
    // Heap type abstractions:
    D3D12_HEAP_TYPE_DEFAULT,
    D3D12_HEAP_TYPE_UPLOAD,
    D3D12_HEAP_TYPE_READBACK,

    // Custom enables more control in exceptional cases, like cross-adapter
    D3D12_HEAP_TYPE_CUSTOM,
} D3D12_HEAP_TYPE;

typedef enum D3D12_CPU_PAGE_PROPERTIES
{
    D3D12_CPU_PAGE_UNKNOWN,
    D3D12_CPU_PAGE_NOT_AVAILABLE,
    D3D12_CPU_PAGE_WRITE_BACK,
    D3D12_CPU_PAGE_WRITE_COMBINE,
} D3D12_CPU_PAGE_PROPERTIES;

typedef enum D3D12_MEMORY_POOL
{
    D3D12_MEMORY_POOL_UNKNOWN,
    D3D12_MEMORY_POOL_L0, // Maximum bandwidth for CPU
    D3D12_MEMORY_POOL_L1, // More bandwidth for GPU, less for CPU
} D3D12_MEMORY_POOL;

typedef struct D3D12_HEAP_PROPERTIES
{
    D3D12_HEAP_TYPE Type;
    D3D12_CPU_PAGE_PROPERTIES CPUPageProperties;
    D3D12_MEMORY_POOL MemoryPoolPreference;
    UINT CreationNodeMask;
    UINT VisibleNodeMask;
} D3D12_HEAP_PROPERTIES;

typedef enum D3D12_HEAP_FLAGS
{
    D3D12_HEAP_FLAG_NONE,
    D3D12_HEAP_FLAG_DENY_BUFFERS,
    D3D12_HEAP_FLAG_DENY_RT_DS_TEXTURES,
    D3D12_HEAP_FLAG_DENY_NON_RT_DS_TEXTURES,
    D3D12_HEAP_FLAG_SHARED,
    D3D12_HEAP_FLAG_SHARED_CROSS_ADAPTER,
    D3D12_HEAP_FLAG_HARDWARE_PROTECTED,
    D3D12_HEAP_FLAG_ALLOW_WRITE_WATCH,
    D3D12_HEAP_FLAG_ALLOW_SHADER_ATOMICS,
} D3D12_HEAP_FLAGS;

typedef struct D3D12_HEAP_DESC
{
    UINT64 Size;
    D3D12_HEAP_PROPERTIES Properties;
    UINT64 Alignment;
    D3D12_HEAP_FLAGS Flags;
} D3D12_HEAP_DESC;

HRESULT ID3D12Device::CreateHeap(
    _In_ const D3D12_HEAP_DESC* pHeapDesc,
    REFIID riid, // Expected: ID3D12Heap
    _COM_Outptr_opt_ void** ppvHeap );

interface ID3D12Heap
    : ID3D12Pageable
{
    D3D12_HEAP_DESC GetDesc();
};

HRESULT ID3D12Resource::GetHeapProperties(
    _Out_opt_ D3D12_HEAP_PROPERTIES*,
    _Out_opt_ D3D12_HEAP_FLAGS* );
```

<!-- Supersession: D3D12_HEAP_FLAGS replaces the older D3D12_HEAP_MISC_FLAG (which
     had only DENY_TEXTURES, DENY_BUFFERS, SHARED). CreationNodeMask, VisibleNodeMask,
     the renamed D3D12_HEAP_DESC.Flags field, ID3D12Heap::GetDesc(), and
     ID3D12Resource::GetHeapProperties() are all defined by Peer-to-Peer LDA
     Atomics, which supersedes the earlier heap-flag form. See the "Peer-to-Peer LDA
     Atomics" section below for the design rationale, validation rules, and per-flag
     semantics, especially for ALLOW_SHADER_ATOMICS and the cross-node visibility model. -->

The heap misc flags are renamed for better consistency across the whole API, using `DENY` and `ALLOW` nomenclature.

Applications already had to declare whether heaps contain textures vs. buffers, while on tiled resource tier 1 hardware. Since declaring either flag is expected to be very short-lived, we chose the `DENY` syntax. Over time, application will not need to set any flags when creating heaps. The debug layer will investigate how to mimic less capable hardware for the tier 1 validation to kick in.

### Shared Resources and Heaps

```cpp
HRESULT ID3D12Device::CreateSharedHandle(
    _In_ ID3D12DeviceChild* pObject, // Supported: Heap, Resource, Fence
    _In_opt_ const SECURITY_ATTRIBUTES *pAttributes,
    DWORD Access,
    _In_opt_ LPCWSTR Name,
    _Out_ HANDLE* pHandle );

HRESULT ID3D12Device::OpenSharedHandle(
    _In_ HANDLE NTHandle,
    REFIID riid, // Expected: ID3D12Heap, ID3D12Resource, or ID3D12Fence
    _COM_Outptr_opt_ void** ppvObj );

HRESULT ID3D12Device::OpenSharedHandleByName(
    _In_ LPCWSTR Name,
    DWORD Access,
    _Out_ HANDLE* pNTHandle );
```

The interface exposed to applications works for all the objects currently shared by D3D12. Fences are covered in the multi-engine documents.

Both heaps and committed resources can be shared. Sharing a committed resource actually shares the implicit heap along with the committed resource description, such that a compatible resource description can be mapped to the heap from another device. These code paths internally integrate with methods that create both heap and resources at the same time, to support shared resource interop cases and likely future swapchain needs.

All methods are free-threaded and inherit the existing D3D11 semantics of the NT handle sharing design. GDI handle sharing is only available through D3D11 interop, as there is no known advantage to using a GDI handle.

The runtime will fail when the wrong object types are passed to this method. All existing D3D11 validation will carry over, unless we successfully achieve the desired design & test plan for D3D12: all resources and heaps can be shared. In such a case, the D3D11 validation related to limited shared resource capabilities will be relaxed.

#### Sharing with other runtimes

Only committed resources and certain heaps can be shared with earlier runtimes; and D3D12 shared resources can only be opened in D3D11, if D3D11 supported sharing with a D3D11 resource description that converts to the shared D3D12 resource description.

When thinking of shared resources, two limiting factors impact support:

- Hardware doesn't support sharing page tables between multiple processes.
- The runtime and driver private data must be known at kernel resource creation time.

Since page tables are not shared between processes, shared resources are equivalent to sharing the implicit heap with a resource description to setup the VA mapping appropriately.

Default shared heaps (and the underlying custom heap equivalents) can be opened in D3D11 as a shared tile pool. Therefore, only `L1` heaps on discrete with no CPU access and `L0` heaps on UMA with no CPU access heap can be shared.

The necessary requirements to support all these scenarios are also imposed on the driver. The driver must construct private data that is consumable by their D3D11 driver and will be interpreted as a shared tile pool. If the heap does not match these properties, it will only be openable by D3D12. It is the app's responsibility to communicate information about expected resource locations via another channel.

Similarly, any resource that can be created as shared in previous runtimes can be opened in D3D12.

##### Deprecate D3D11 Shared Tile Pools

In D3D12, the `DENY_TEXTURES` and `DENY_BUFFERS` heap flags exist due to limitations of some tiled resource tier 1 GPUs. The security of shared heaps suffers without this flag. A client process could map buffers where the server process expects to map textures, and the result would cause the server process to trigger device-removed.

Because of this, D3D11 shared tile pools will be deprecated. It is not expected that any application yet uses this functionality. Telemetry will be used to verify that.

Fallback plans for application compatibility are to either continue using the D3D11 driver, while it is available; OR recognize the app and advertise no tiled resource support instead of tiled resource tier 1 support.

## Resources

Resources are the D3D concept which abstracts the usage of GPU physical memory. Resources require GPU virtual address space to access physical memory. They are acquiring more virtual address space capabilities over time.

### Create Resource

```cpp
typedef enum D3D12_RESOURCE_DIMENSION
{
    D3D12_RESOURCE_DIMENSION_UNKNOWN,
    D3D12_RESOURCE_DIMENSION_BUFFER,
    D3D12_RESOURCE_DIMENSION_TEXTURE_1D,
    D3D12_RESOURCE_DIMENSION_TEXTURE_2D,
    D3D12_RESOURCE_DIMENSION_TEXTURE_3D,
} D3D12_RESOURCE_DIMENSION;

typedef enum D3D12_TEXTURE_LAYOUT
{
    D3D12_TEXTURE_LAYOUT_UNKNOWN,
    D3D12_TEXTURE_LAYOUT_ROW_MAJOR,
    D3D12_TEXTURE_LAYOUT_64KB_UNDEFINED_SWIZZLE,
    D3D12_TEXTURE_LAYOUT_64KB_STANDARD_SWIZZLE,
} D3D12_TEXTURE_LAYOUT;

typedef enum D3D12_RESOURCE_FLAGS
{
    D3D12_RESOURCE_FLAG_ALLOW_RENDER_TARGET,
    D3D12_RESOURCE_FLAG_ALLOW_DEPTH_STENCIL,
    D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS,
    D3D12_RESOURCE_FLAG_DENY_SHADER_RESOURCE, // Only used with DEPTH_STENCIL
} D3D12_RESOURCE_FLAGS;

typedef struct D3D12_RESOURCE_DESC
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
} D3D12_RESOURCE_DESC;

typedef struct D3D12_DEPTH_STENCIL_VALUE
{
    FLOAT Depth;
    UINT8 Stencil;
} D3D12_DEPTH_STENCIL_VALUE;

typedef struct D3D12_CLEAR_VALUE
{
    DXGI_FORMAT Format;
    union
    {
        FLOAT Color[4];
        D3D12_DEPTH_STENCIL_VALUE DepthStencil;
    };
} D3D12_CLEAR_VALUE;

HRESULT ID3D12Device::CreateCommittedResource(
    _In_ const D3D12_HEAP_PROPERTIES* pHeapProperties,
    D3D12_HEAP_FLAGS HeapFlags,
    _In_ const D3D12_RESOURCE_DESC* pResourceDesc,
    D3D12_RESOURCE_STATES InitialResourceState,
    _In_opt_ D3D12_CLEAR_VALUE* pOptimizedClearValue,
    REFIID riid, // Expected: ID3D12Resource
    _COM_Outptr_opt_ void** ppvResource );

HRESULT ID3D12Device::CreateReservedResource(
    _In_ const D3D12_RESOURCE_DESC* pDesc,
    D3D12_RESOURCE_STATES InitialState,
    _In_opt_ D3D12_CLEAR_VALUE* pOptimizedClearValue,
    REFIID riid, // Expected: ID3D12Resource
    _COM_Outptr_opt_ void** ppvResource );

HRESULT ID3D12Device::CreatePlacedResource(
    _In_ ID3D12Heap* pHeap,
    UINT64 HeapOffset,
    _In_ const D3D12_RESOURCE_DESC* pDesc,
    D3D12_RESOURCE_STATES InitialState,
    _In_opt_ D3D12_CLEAR_VALUE* pOptimizedClearValue,
    REFIID riid, // Expected: ID3D12Resource
    _COM_Outptr_opt_ void** ppvResource );

interface ID3D12Resource
    : ID3D12Pageable
{
    // Map, Unmap, GetDesc, GetGPUVirtualAddress, WriteToSubresource,
    // ReadFromSubresource
};
```

There are three types of resources with respect to virtual address creation and flexibility in D3D12:

#### Committed Resources

Committed resources are the most common idea of D3D resources over the generations. Creating such a resource allocates virtual address range, an implicit heap large enough to fit the whole resource, and commits the virtual address range to the physical memory encapsulated by the heap. The implicit heap properties must be passed to match functional parity with previous D3D versions.

#### Reserved Resources

Reserved resources are equivalent to D3D11 tiled resources. On their creation, only a virtual address range is allocated and not mapped to any heap. The application will map such resources to heaps later. The capabilities of such resources are currently unchanged over D3D11, as they can be mapped to a heap at a 64KB tile granularity with `UpdateTileMappings`.

Reserved textures can only be created with `D3D12_TEXTURE_LAYOUT_64KB_UNDEFINED_SWIZZLE`, matching D3D11 capabilities.

#### Placed Resources

New for D3D12, applications may create heaps separate from resources. Afterward, the application may locate multiple resources within a single heap. This can be done without creating tiled or reserved resources, enabling the capabilities for all resource types able to be created directly by applications. Multiple resources may overlap, and the application must use the `TiledResourceBarrier` to re-use physical memory correctly.

#### Common Design

Resource creation is free-threaded. The initial resource state must be valid for the resource type, or `E_INVALIDARG` occurs.

All created resources accept commonly cleared color optimizations to help benefit some GPU architectures that store a clear color in their resource descriptors. Debug layer warnings will be issued when the Clear operation doesn't leverage the color declared on resource creation. The format of the commonly cleared color follows the same validation rules as a view/ descriptor creation. In general, the format of the clear color can be any format in the same typeless group that the resource format belongs to.

This optimization will not immediately be extended to swapchains and opened shared resources.

### Common Resource Interface and Description

D3D12 has a single resource interface, since no significant value was recognized in the multiple interfaces of D3D11.

D3D12 has a common resource descriptor for all these resource types, which is a superset of buffers and textures. This simplifies internal and external code that deals with resources as a whole. D3D12 unifies all existing and still useful D3D11 and DXGI resource concepts into a single D3D12 descriptor.

Reflecting the desc information from `ID3D12Resource` helps middleware and applications verify the resources are being used optimally and as expected.

`Width` is 64-bit to support evolve into supporting the full capabilities of systems available in the marketplace.

`RENDER_TARGET` and `DEPTH_STENCIL` denote whether the driver can allocate compression data that significantly increase the bandwidth to those parts of the pipeline. `RENDER_TARGET` compression is not constrained to multiple sample compression. It supports fast clear and lossless color compression techniques. `DEPTH_STENCIL` also supports fast clear and early depth optimizations, instead of exclusively supporting multiple sample compression.

`DENY_SHADER_RESOURCE` allow optimizations for resource with `DEPTH_STENCIL`. Some GPUs cannot orthogonally seamlessly support reading in all depth compression techniques as a texture.

#### Deprecated Resource Properties

Deprecation typically does not mean that the functionality is no longer available, especially internally. Externally, the functionality usually exists. Either a better piece of functionality supersedes the old functionality, or the flag is no longer needed. Only flags related to video are left as open issues.

**Bind Flags**

`VERTEX_BUFFER`, `INDEX_BUFFER`, `STREAM_OUTPUT`, and `CONSTANT_BUFFER` bind flags are no longer declared at resource creation in D3D12. These flags used to have value to support legacy hardware; but no current value is known. Instead, D3D12 buffers can be used by the GPU for all these purposes without declaration.

The remaining Bind Flags are re-evaluated and valuable ones are merged into D3D12 Misc Flags: `SHADER_RESOURCE`, `RENDER_TARGET`, `UNORDERED_ACCESS`, and `DEPTH_STENCIL`.

`VIDEO_ENCODER` and `DECODER` are under evaluation by the image engine introduction. It's possible that an image engine heap flag is necessary to support some GPUs; and such a flag would be used for both the video & image engine. It is an open-issue if video engines need these flags for other reasons; but the goal and expectation is that such D3D11 flags are replaced by only a heap-engine flag.

**Misc Flags**

`DRAWINDIRECT_ARGS` is no longer required to be declared during resource creation in D3D12. No tangible value is known to ever have existed by its presence. Instead, D3D12 buffers can be used by the GPU for this purpose without declaration.

`ALLOW_RAW_VIEWS` and `BUFFER_STRUCTURED` are no longer required to be declared in D3D12. It prevents flexibility with `CONSTANT_BUFFER`. Instead, D3D12 buffers can be used as RAW Buffer SRVs without such up-front declaration. The structured buffer stride and the flags related to these features are relocated to the resource descriptor.

D3D11 `SHARED` has been deprecated in D3D12 surface area, since it really means GDI handle sharing. GDI handle sharing has been superseded by NT handle sharing. `SHARED_NTHANDLE` has been relocated to heap flags and renamed to `SHARED` for D3D12. The whole heap must be shared atomically. The D3D11 interop API, though, exposes ways to use such resources with D3D12.

`SHARED_KEYEDMUTEX` is also deprecated in D3D12 surface area, since barely any components used it. The D3D11 interop API, though, exposes ways to use such resources with D3D12. The underlying components of a keyed mutex object are exposed more directly in D3D12.

`GDI_COMPATIBLE` is deprecated in D3D12. The application can still achieve the same results. This is done by creating a shared resource of the appropriate type that GDI can operate on; and the interop API enables sharing with GDI.

`TILE_POOL` is deprecated, as heaps provide a super-set of functionality for tile pools.

`GUARDED` is deprecated in D3D12, since the bind model and low CPU overhead requirements preclude tracking everything the GPU is reading from. No perfect replacement hardware solution exists yet; but multiple new options can be leveraged to iterate on D3D11's solution. Placed resources, texture data in buffers, linear textures, standardized swizzle, and tiled resources all provide multiple options for a more efficient option. However, many efficiency options must be evaluated.

`GENERATE_MIPS` is deprecated, since it requires significant implicit memory usage, such as an implicit descriptor heap, pipeline state object, etc. Such implicit memory usage and driver complexity is less desirable than explicit application understanding of memory consumption and lifetime. No IHVs recognized unique value they were adding by keeping this functionality within the driver.

`TEXTURECUBE` is deprecated, since we deprecated the need to declare texture cube during resource creation in D3D10.1. The flag has existed for driver-compat reasons ever since.

`RESTRICTED_CONTENT` is deprecated, since it is impractical to have the D3D12 runtime and driver enforce restricted content semantics. The bind model and low CPU overhead requirements preclude tracking everything the GPU is reading from. This functionality isn't required until video comes back online, and it is an open issue how it comes back. Ideally, `HW_PROTECTED` will completely replace the need for it.

`RESTRICT_SHARED_RESOURCE`, and `RESTRICT_SHARED_RESOURCE_DRIVER` are all currently deprecated externally. This functionality isn't required by applications until video comes back online, and it is an open issue how it comes back.

`RESOURCE_CLAMP` is deprecated in D3D12, since no driver is known to support the functionality originally intended by the design. LOD clamping has been relocated to the resource descriptor. Some exploration has been done on a real design to enable de-committing physical memory for mip-levels. Some applications may use tiled resource to get at the functionality in the interim; but with a more complex API design than needed & without ubiquitous hardware support.

#### Deprecated Resource Types and Operations

D3D11 Dynamic & Staging Textures are currently replaced with the ability to locate texture data in buffers and the ability to copy data back and forth between Buffers and Textures on the GPU. The application must use the memory in Buffers with certain restrictions, like alignment, while doing so.

11on12 is required to convert the D3D11 `GenerateMips` operation to using shaders on top of D3D12.

#### Smaller Alignments

The runtime supports smaller alignment options, as long as the textures are small enough, and the layout doesn't require larger alignment.

The D3D runtime will only allow applications to create such resources when the estimated size of the most-detailed mip level is a total of the larger alignment restriction or less. The runtime will use an architecture-independent mechanism of size-estimation, that mimics the way standard swizzle and D3D11 tiled resources are sized. However, the tile sizes will be of the smaller alignment restriction for such calculations. Additional data associated with resources, which is typically associated with compression, will not be added into this size.

Using the non-RT & non-DS texture as an example, the runtime will assume near-equilateral tile shapes of 4KB, and calculate the number of tiles needed for the most-detailed mip level. If the number of tiles is equal or less than 16, then the application can leverage a 4KB aligned resource. So, a mipped tex2d array of any array size and any number of mip levels can be 4KB, as long as the width and height are small enough for the particular format & MSAA.

### Resource Size Reflection

```cpp
typedef struct D3D12_RESOURCE_ALLOCATION_INFO
{
    UINT64 Size;
    UINT64 Alignment;
} D3D12_RESOURCE_ALLOCATION_INFO;


D3D12_RESOURCE_ALLOCATION_INFO GetResourceAllocationInfo(
    UINT visibleMask,
    UINT numResourceDescs,
    _In_reads_(numResourceDescs) const D3D12_RESOURCE_DESC* pResourceDescs
    );
```

Applications must use resource size reflection to understand how much room textures with unknown texture layouts require in heaps. Buffers are also supported, but mostly as a convenience.

This routine calculates the size of the needed heap using the C++ algorithm for structure sizes and alignment, as if the array of resource descs defined a C++ structure with resource as member variables. Applications should be aware of major alignment discrepancies, to help pack resources more densely. Examples:

A single-element array with a one-byte-buffer returns a `Size` of 64KB and an `Alignment` of 64KB, as buffers currently can only be 64KB aligned.

A three element array with two single-texel 64KB aligned textures and a single-texel 4MB aligned texture reports differing sizes based on the order of the array. If the 4MB aligned textures is in the middle, the resulting `Size` is 12MB. Otherwise, the resulting `Size` is 8MB. The `Alignment` returned would always be 4MB, the super-set of all alignments in the resource array.

### Map and Unmap

```cpp
typedef struct D3D12_RANGE
{
    SIZE_T Begin;
    SIZE_T End; // One past end, so (End – Begin) = Size
} D3D12_RANGE;

HRESULT ID3D12Resource::Map(
    UINT Subresource,
    _In_opt_ D3D12_RANGE* pReadRange,
    _Out_opt_ VOID** ppData
    );

void ID3D12Resource::Unmap(
    UINT Subresource,
    _In_opt_ D3D12_RANGE* pWrittenRange
    );
```

Persistent Map is supported on `L0` heaps with `WRITE_COMBINE` properties or `UPLOAD` heaps, which allows the GPU to use memory without the CPU un-mapping and re-mapping it. Persistent Map should not be used on `L1` heaps due to Win7 behavior that keeps such heaps in system memory due to lack of atomic promotion to BAR.

`Map` will only succeed on opaque resource layouts, if `ppData` is NULL. This is useful to cache information for the [Strip-mine CPU copy operations](#strip-mine-cpu-copy-operations) across multiple copy operations. However, opaque resources have quite a few restrictions regarding the strip-mine copy support, which all fail:

- No MSAA resources
- No depth-stencil resources
- Formats must have a power-of-two element size
- Volume textures must have only a single mip-level

Ranges must be NULL or empty when the layout is opaque.

It is possible for apps to still be exposed to undefined data layouts due to relying on pre-existing undefined tile mapping behavior that is inherited by resource placement.

The runtime ref-counts the driver's `pfnMapHeap` / `pfnUnmapHeap` (DDI) calls internally and serializes them across multiple application threads. This avoids redundant calls into the driver. (No equivalent `Map` exists on `ID3D12Heap` at the API level — only on `ID3D12Resource`.)

Ranges are useful for mobile systems, to denote which addresses must be invalidated or flushed from the CPU last-level cache. But, ranges have a high likelihood to not be trusted. So, tools will assume they are not valid. Such ranges are only useful for write-back heaps on non-cache-coherent architectures.

DXGK does not yet support atomic ARM CPU cache flush & invalidate for this feature; but expects they can.

The debug layer will warn when ranges aren't used, and describe how they are useful for mobile.

Applications cannot rely on standard swizzle resource layouts, so they cannot offset from subresource 0 into subresource 1. Standardized layout is not yet available, so base texture GPU VA & base texture CPU VA are not exposed. Instead, the application must pass in a subresource index, which most apps probably want for convenience anyway.

## Copy Operations

```cpp
const UINT D3D12_TEXTURE_DATA_PITCH_ALIGNMENT = 256;
const UINT D3D12_TEXTURE_DATA_PLACEMENT_ALIGNMENT = 512;

typedef struct D3D12_PITCHED_SUBRESOURCE_DESC
{
    DXGI_FORMAT Format;
    UINT        Width;
    UINT        Height;
    UINT        Depth;
    // Must be a multiple of D3D12_TEXTURE_DATA_PITCH_ALIGNMENT:
    UINT        RowPitch;
} D3D12_PITCHED_SUBRESOURCE_DESC;

typedef struct D3D12_PLACED_PITCHED_SUBRESOURCE_DESC
{
    // Must be a multiple of D3D12_TEXTURE_DATA_PLACEMENT_ALIGNMENT:
    UINT64                         Offset;
    D3D12_PITCHED_SUBRESOURCE_DESC Placement;
} D3D12_PLACED_PITCHED_SUBRESOURCE_DESC;

typedef enum D3D12_SUBRESOURCE_VIEW_TYPE
{
    D3D12_SUBRESOURCE_VIEW_SELECT_SUBRESOURCE,
    D3D12_SUBRESOURCE_VIEW_PLACED_PITCHED_SUBRESOURCE,
} D3D12_SUBRESOURCE_VIEW_TYPE;

typedef struct D3D12_TEXTURE_COPY_LOCATION
{
    ID3D12Resource *pResource;
    D3D12_SUBRESOURCE_VIEW_TYPE Type;
    union
    {
        D3D12_PLACED_PITCHED_SUBRESOURCE_DESC PlacedTexture;
        UINT Subresource;
    };
} D3D12_TEXTURE_COPY_LOCATION;

ID3D12CommandList::CopyTextureRegion(
    _In_ CONST D3D12_TEXTURE_COPY_LOCATION *pDst,
    UINT DstX,
    UINT DstY,
    UINT DstZ,
    _In_ CONST D3D12_TEXTURE_COPY_LOCATION *pSrc,
    _In_opt_ CONST D3D12_BOX *pSrcBox,
    D3D12_COPY_FLAG CopyFlags );

ID3D12CommandList::CopyBufferRegion(
    _In_ ID3D12Resource* pDstBuffer,
    UINT64 DstOffset,
    _In_ ID3D12Resource* pSrcBuffer,
    UINT64 SrcOffset,
    UINT64 NumBytes,
    D3D12_COPY_FLAG CopyFlags );
```

These methods enable applications to replace D3D11 `UpdateSubresource`, `CopySubresourceRegion`, and resource initial data. A single 3D subresource worth of row-major texture data may be located in buffer resources. `CopyTextureRegion` can copy that texture data from the buffer to a texture resource with an unknown texture layout, and vice versa. Applications should prefer this type of technique to populate frequently accessed GPU resources, by create large buffers in a `UPLOAD` heap while creating the frequently accessed GPU resource in a `DEFAULT` heap that has no CPU access. Such a technique efficiently supports discrete GPUs and their large amounts of CPU-inaccessible memory, without commonly impairing UMA architectures.

## Strip-mine CPU copy operations

```cpp
HRESULT ID3D12Resource::WriteToSubresource(
    UINT DstSubresource,
    _In_opt_ const D3D12_BOX* pDstBox,
    _In_ const void* pSrcData,
    UINT SrcRowPitch,
    UINT SrcDepthPitch
    );


HRESULT ID3D12Resource::ReadFromSubresource(
    _Out_ void* pDstData,
    UINT DstRowPitch,
    UINT DstDepthPitch,
    UINT SrcSubresource,
    _In_opt_ const D3D12_BOX* pSrcBox
    );
```

These routines will rearrange texture data between a row-major layout and an undefined resource layout. The operation is synchronous, as in the memory is copied by the time the function calls. So, the application should keep CPU scheduling in mind. The application can always break up the copying into smaller regions or schedule this operation in another task.

This routine can be used by all resources where `Map` will succeed with a NULL `ppData` parameter, except buffers. If the application will call these routines multiple times in a tight loop, the application may call `Map` with a NULL `ppData` parameter to cache information needed to perform the operations.

MSAA resources and depth-stencil resources with opaque resource layouts are not supported for strip-mine CPU copy operations, and will cause a failure. Formats which don't have a power-of-two element size are also not supported and will cause a failure.

See D3D11 Default Texture Map Unified Spec for more details, like efficiency recommendations.

Out of memory return codes can occur.

Device removed error codes will return when `ReadFromSubresource` is passed a non-empty box or a NULL box pointer.

## Caps

```cpp
HRESULT ID3D12Device::CheckFeatureSupport(
    D3D12_FEATURE Feature,
    _Out_writes_bytes_(FeatureSupportDataSize) void *pFeatureSupportData,
    UINT FeatureSupportDataSize );
```

The following caps are reported through the `CheckFeatureSupport` API.

#### Standard Swizzle

```cpp
typedef enum D3D12_FEATURE
{
    ...
    D3D12_FEATURE_D3D12_OPTIONS,
    ...
} D3D12_FEATURE;

typedef struct D3D12_FEATURE_DATA_D3D12_OPTIONS
{
    ...
    _Out_ BOOL StandardSwizzle64KBSupported;
    ...
} D3D12_FEATURE_DATA_D3D12_OPTIONS;
```

When the driver indicates support for standard swizzle, the runtime will advertise out that standard swizzle is supported. Packed mips still apply, though. The application can then create resources with the standard swizzle layout.

Standard swizzle layouts are most beneficial for resources created on CPU accessible heaps; but are supported on non-CPU accessible heaps to enable orthogonal efficiency experiments. The same design was adopted for D3D11. Applications likely want to use standard swizzle resources on UMA designs, as described in the next caps.

#### Architectural Details

```cpp
typedef enum D3D12_FEATURE
{
    ...
    D3D12_FEATURE_ARCHITECTURE,
    ...
} D3D12_FEATURE;

typedef struct D3D12_FEATURE_DATA_ARCHITECTURE
{
    _In_  UINT NodeIndex;
    _Out_ BOOL TileBasedRenderer;
    _Out_ BOOL UMA;
    _Out_ BOOL CacheCoherentUMA;
} D3D12_FEATURE_DATA_ARCHITECTURE;
```

UMA GPU designs use the same physical memory as the CPU does. With such adapters, locating textures in CPU accessible heaps may increase the efficiency of data exchange between CPU & GPU. The types of scenarios which benefit the most is where the resource data changes once per-frame or less. The closer the scenario matches CPU-produce-once & GPU-consume-once (or vice versa), the more likely CPU-accessible heap usage can improve efficiency. However, applications must not infer that CPU accessible heaps are free on UMA systems, because the CPU & GPU memory is all "system memory". UMA systems can still significantly benefit from the usage of write-combine memory, to improve bandwidth between the two processors. CPU addresses to `UPLOAD` heaps are commonly attributed with write-combine cache behavior. Care must be taken to only use CPU accessible heaps where commonly beneficial across many UMA adapters.

`CacheCoherentUMA` is a special type of GPU UMA design, where large caches are tightly integrated between CPU & GPU. `CacheCoherentUMA` designs do not significantly benefit from the usage of write-combine cache techniques. CPU addresses to `UPLOAD` heaps are attributed with write-back cache behavior. Such designs are much more likely to benefit from locating textures in CPU accessible heaps than normal UMA GPU designs, even when such resources don't fit the mold of "CPU-produce-once & GPU-consume-once".


---

## DDI Surface

### Overview

We introduce additional flexibility for apps to reuse graphics memory more efficiently, in conjunction with the deprecation of dynamic resource renaming (aka. Map-Discard) in D3D12. Dynamic resource renaming is known to add significant CPU overhead associated with mutable virtual CPU and GPU addresses. There are two main ways techniques in which apps can reuse video memory: heap objects and large buffers.

Heap objects align with the concept of a section object, and use abstracted tiled resource operations to place resources on a heap. Heaps must be made resident in physical memory for the GPU to access it. The alignment requirements are quite large, and preclude sub-page allocation and placement for resource. Heaps must not require any attribution to determine which engine can use the memory or which resources can reside in the heap.

Buffers achieved a significant increase in flexibility by removing unnecessary attribution, and even gained the ability to place row-major/ pitch-linear multi-dimensional texture data. The alignment requirements are small; but not tiny. And, the texture data only allows copying.

#### Scenario: Pipe Buffers

Pipe buffers are memory regions written to by one processing unit and read from by another parallel processing unit. These memory regions typically grow to support the maximum amount of parallelism between such processing units, behave similar to a segmented ring buffer, and are allocated from both frequently and on-demand. Pipe buffers can be implemented with either heaps and/ or large buffers.

Dynamic resources have existed in D3D for many generations to optimize the marshalling of data from the CPU to the GPU. However, the renaming functionality associated with dynamic resources is onerous to support along with command lists, especially when command lists can be re-used. Dynamic resource renaming requires patching of command lists, which increases the complexity of drivers along with the amount of CPU overhead.

Applications must take on more responsibility to multi-buffer resources and cache memory allocations in D3D12. And, we will introduce more flexibility for heaps & buffers to do so.

##### Scenario: Bulk Loading

Games need to load a lot of resources at once, very quickly. We expect them to allocate a large heap and large buffers to manage the demand during this period. The scenario doesn't add much more unique on top of pipe buffers, except for the idea that the application may desire and can achieve zero-copy for some of the data being loaded. The standard swizzle feature certainly helps enable this for UMA systems.

#### Scenario: Background Streaming

It is popular for some games to load low mips first, then larger mips later. Conceptually, such games will reserve virtual address space for the whole texture; but only load the smaller ones first. The LOD level will be clamped to just those levels available. The game will load more detailed mips in the background, and raise the mip level clamp.

This scenario can be accomplished with D3D11 tiled resources; but we would like to investigate enabling this with all textures after heaps are bootstrapped.

#### Resources in D3D12

Resources are aligned closer to the notion of a GPU virtual address range than physical video memory; but there is some flexibility for the driver. It can choose whether each resource typically reuses both virtual address range and physical memory, or if each resource has its own virtual address range mapped to the same physical memory.

D3D12 has a common resource descriptor for all these resource types, which is a superset of buffers and textures. D3D12 will unify all existing D3D11 resource concepts into a single D3D12 descriptor, and we intend to expose only the resource flags which provide long-term value for GPUs.

#### Finalize Swapchain Support

Primaries are created through the new D3D12 heap and resource DDIs. Primaries created by the D3D12 DDI can be scanned out by DWM with Independent Flip. Previously, primaries were created through the legacy D3D11 resource creation DDIs in D3D12; and we suspected the present DDI would no longer exist.

The deprecation of the present DDI is postponed until after the initial D3D12 release. For Windows 10, DWM will be still be running on a driver created through the D3D11 DDI, so cross-driver sharing on the same adapter must be fully supported.

#### Heap Tiers

<!-- Supersession: the May 2015 "Heap Tiers (clarified)" supersedes the March 2015 "Heap Tiers" — same content with minor wording tightening; the March 2015 body was dropped -->

Consider the following three types of resources:

1. Buffers
2. Non-render target & non-depth stencil textures
3. Render target or depth stencil textures

There is a heap flag associated with each category of resource, which divulges the types of resources that may be used on the heap. There are two tiers of hardware support:

At the lowest end of hardware support, heaps can only support resources from a single type above. A, B, and C are all mutually exclusive. This is heap tier 1. Heap tier 1 is not required to support parameterized swizzle on textures in cpu-accessible video memory.

At the greatest level of hardware support, resource types of A, B, & C can mix within the same heap; and there is no hardware benefit to preclude mixing. This is heap tier 2.

There is a new caps DDI for reporting the heap tier support, and new heap DDI flags to divulge all the heap types during heap creation.

#### Misc. Tweaks

<!-- Merge: combined Overview "Misc. Tweaks" from the March 2015 DDI revision (tiled resource DDI tweaks) and the May 2015 DDI revision (parameterized swizzle DDI tweaks) -->

DDI tweaks are necessary to support the tiled resource functionality, as originally desired.

Additional DDI cleanup tweaks are added as well.

DDI tweaks were done for parameterized swizzle to match changes in the D3D11 design.

Microsoft intends to add HLK tests to ensure these design aspects.

#### Concurrent Resource Access & CPU Access

D3D11 shared resource & presentation scenarios require concurrent resource access to avoid a regression in capabilities. DComp has applications render to some parts of a shared texture atlas, while DWM is composing from adjacent texels in the same atlas.

Defining when CPU access is or isn't allowed was an open item as part of bringing the Map Default Texture design into D3D12.

#### Placed Resource Physical Memory Aliasing and Data Inheritance

The capabilities and rules associated with physical memory aliasing and data inheritance for D3D11 tiled resources were carried over into D3D12 for reserved resources. The same capabilities and rules were initially used as the foundation to support placed resources in D3D12. However, placed resources enable more capabilities by locating the compression metadata within the heap.

Many of these details fall out of continual tweaks to many designs for D3D12 and continual discussions. They are summarized here to better clarify a common understanding.

These design details make shared resources as efficient as possible, when the necessary application mechanisms are available. There are two types of shared resources that exist in D3D11, which must stay compatible with D3D12's usage model:

- Raw shared resources, where the application indicates no transition between GPU reading and writing data. These shared resource types are being phased out.
- Keyed mutex & presentation shared resources, where the application transitions the resource between GPU read & write access.

#### GPU VA Capability Reflection

The D3D11 and D3D12 tiled resource designs have been changed to support more GPUs. Applications can query to understand two new GPU adapter capabilities: how large the per-process GPU VA space is and how large each resource GPU VA space can be. The latter property may be smaller or larger than the per-process capability, because capabilities for mostly-sparse resources are different for some types of GPU designs in certain environments.

We anticipate applications are interested in these GPU capabilities to help tease apart two tiled resource usage scenarios.

- Mostly-sparse resources: This is the original D3D11 tiled resource scenario, where the more-detailed mip levels are commonly never fully resident.
- Rarely-sparse resources: Some D3D12 applications will likely use tiled resources to manage partial mip-level residency, but the entire resource will likely be fully resident at some point in the game execution.

The application will use these metrics as litmus tests before using certain features. The per-process capability divulges whether MakeResident and Evict are viable options. The per-resource capability divulges whether the mostly-sparse scenario is viable for the application's target resource sizes.

The D3D runtime gets the per-process GPU VA capability from kernel, when the driver is WDDM2.0. But the per-resource GPU VA capability must be reported by the driver. A new caps query is added to D3D11 and D3D12 to support retrieve the per-resource GPU VA information.

### Hardware Requirements

Unless otherwise called out, the requirements below apply to both heap tiers.

1. The GPU must read and write data to and from memory pages. When such pages are accessible by the CPU, they must be able to be marked as write-back or write-combine for the CPU.
    1. The GPU must be able to read and write single-dimensional buffer data & multi-dimensional texture data to and from such pages for all GPU operations, like copying, constant reads, vertex reads, index reads, indirect draw reads, buffer & texture loading and sampling, buffer & texture rendering, UAV processing, and even depth-stencil. However, restrictions and undefined behavior exists, as detailed later.
    2. It is okay for resources and heaps to be mapped for CPU access while the GPU is actively reading or writing from such pages.
        1. The GPU can read from such memory, even while the CPU and/or other GPU engines are doing writes to such memory, even on the same bytes. The worst that can happen is that a structurally torn value is observed during the memory read. The multi-engine & synchronization spec details cases where atomic reads and writes are required.
        2. The following GPU write operations are well-defined, such that the CPU and/ or other GPU engines can guarantee writes to heaps without losing memory write operations. Bytes within row padding must not be modified.
            1. Copy, resolve, stream output, decoder, encoder, and capture GPU-write operations modify only the bytes in the destination resource where each copied texel data resides, as specified by the operation.
            2. UAV write operations modify only the bytes in the destination resource that the modified UAV element resides.
            3. Rendering and depth-stencil GPU-writes modify only the 4KiB, 64KiB, or 4MiB aligned regions in which the destination resource reside
    3. GPUs capable of I/O coherence must use it when write-back is required or chosen for pages that reside in physical system memory. See the WDDM2.0 spec for more on I/O coherence.
2. Data typically associated with buffers and pitch-linear texture data operations are required to be aligned properly for consumption by the GPU. Both buffer and pitch-linear data may reside next to each other and even overlap.
    1. Pitch-linear requirements & restrictions are as follows. Capabilities diverge based on whether the data is only copied; or if it can be sampled and rendered to. Sampling & rendering requirements are to avoid regressing backward compatibility.

        For copying:

        1. Only a single 3D subresource, at a time, is required of pitch-linear/ row-major copying.
        2. The base address/ offset of pitch-linear texture data must be 512-byte aligned.
        3. The width stride must be 256-byte aligned for all texel element sizes. The width stride is 32-bit and can be much greater than the tightest stride that is correctly aligned for a particular texture width.
        4. Arbitrary height, up to the D3D maximum, is supported orthogonally.
        5. For volume textures, the depth stride is height times width stride.

        For sampling and rendering, see the cross-adapter and LDA spec for more details. A summary is listed below, which may be stale.

        1. A non-mipped array of subresources, is required of pitch-linear/ row-major sampling & rendering. MS-Hybrid cross-adapter stereo presentation requires an array size of 2. BC formats are not required to be sampled from row-major textures created by D3D11 drivers.
        2. The width stride must be 256-byte aligned for all texel element sizes. The width stride is 32-bit and can be much greater than the tightest stride that is correctly aligned for a particular texture width.
        3. Height must be a multiple of 4 for volumes, and a multiple of 16 for arrayed resources. Heights up to the D3D maximum are supported.
        4. For volume and arrayed textures, the depth stride is height times width stride.
        5. Compressed render targets must be able to be resolved to enable the CPU and other adapters to read/ write the texels; or non-compressed resources may be able to be used.

    2. Buffer alignment restrictions are not changed over D3D11:
        1. Constant data reads must be a multiple of 256 bytes from the beginning of the heap (i.e. only from addresses that are 256-byte aligned).
        2. Index data reads must be a multiple of the index data type size (i.e. only from addresses that are naturally aligned for the data).
        3. `Draw*Indirect` data must be from offsets that are multiples of 4 (i.e. only from addresses that are DWORD aligned).
        4. Etc.

3. When the GPU supports standard swizzle, the GPU must support all multi-dimensional operations as orthogonally as other textures, such as texture from, render to, copy to & from, re-swizzle to & from, etc.
    1. Standard swizzle defines how a multi-dimensional arrangement of texels are located within a 64KB tile. A resource is made up of a tile-row-major arrangement of tiles, as defined by the tiled resource layout. See the Map Default Texture/ Standard Swizzle Spec for additional requirements and details.
    2. Compressed render targets & depth-stencil must be able to be resolved to enable the CPU to read/ write the texels.
    3. When supporting standard swizzle, drivers cannot use non-deterministic swizzle pattern choices. Hardware must efficiently support fixed swizzle patterns at all parts of the pipeline, including multiple render target scenarios associated with deferred rendering.
    4. When supporting standard swizzle primaries, hardware must support clear optimizations that don't require coordination between the software component which clears the resource and the software component that renders or samples with the resource. This impedes middleware scenarios.
    5. When supporting standard swizzle, the GPU can write data to a buffer in the standard swizzle pattern, and re-interpret that data through a standard swizzle texture and vice versa. The application must follow the rules to inherit data through physical memory aliasing.
4. The GPU must not require texture alignment greater than 4KiB when rendering or depth-stencil operations are not supported on the texture. The GPU must not require texture alignment greater than 64KiB for all other resources; but these minimums are not the default choice applications will use.
5. Compression data and its artifacts must be confined to texture resources.
    1. Compression data must be able to be located in separate pages than the rest of the resource data, so therefore must be page-aligned.
    2. Any compression data on non-RT/DS textures must not require the application to initialize texture contents via whole subresource copies.
6. GPUs cannot support more than six swizzle patterns per texture. When supporting multiple swizzle patterns per texture, the transition must occur at particular mip levels across the whole texture.
7. Support page-based virtual addressing of physical memory from all engines on the GPU exposed in the multi-engine design, or risk using the least common denominator capabilities of the available engines.
8. Hardware that supports heap tier 2 must not require heap attribution based on resource type & properties. And, the hardware must use the same CPU-visible swizzle pattern in all memory segments. This is relied upon when WDDM2.0 functionality transparently evicts heaps to system memory in the face of significant system video memory pressure.
9. Hardware must have modes to support tighter memory consistency models required by concurrent resource access.

**Hardware Goals**

- **Support standard swizzle & compressed textures from all engines**

The number and type of GPU engines is detailed in the D3D12 multi-engine design. The lack of orthogonal multi-engine support risks using the least common denominator capabilities of all the supported engines and orthogonal integration with 3D engine features.

A major benefit of establishing a standardized swizzle pattern is to gain industry-wide support for all engines and all graphics vendors. This enables data to be passed from engine to engine, adapter to adapter without extra copying, saving power while keeping multi-dimensional data efficient for repeated composition or manipulation.

Similarly, the benefit of compressed textures shouldn't be limited to just the 3D engine or be lost during shared heap, sparsely mapped tiled resource, transparent eviction to system memory, nor physical memory aliasing scenarios.

- **Support a minimum of 4KB alignment requirements for ALL resources**

We would like to continue investigating a 4KiB option for all non-MSAA resources for the final D3D12 release. So, resource placement offset alignments may tighten up a bit more before D3D12 release.

4KB page sizes and 4KB standardized swizzle support can likely wait until after D3D12 is released. Mainstream applications tend to manipulate a lot of small textures, such that 64KB alignment restrictions prevent simple adoption of standard swizzle into mainstream applications. Glyph runs of text are typically only a few pixels high and high-quality text tends to be rendered instead of bitmap-copied. Many websites are made up of many small images that are decoded JPEGs.

- **Support GPU Resizable BAR and CPU Guard Page Faulting when discrete**

These features will likely assist when applications design for integrated and don't test on discrete, in the presence of persistent Map. Such features will likely also help our tool efforts.

- **Investigate GPU designs to completely hide data compression techniques**

The plans for exposing applications to compression data management are currently very immature, so the scope of compression data is conservatively being constrained. The current plans for D3D12 are to design around the presence of such data when absolutely required and investigate the feasibility of changing hardware.

With the transition to extremely low-level APIs, hardware would ideally be redesigned to hide compression data from impacting application residency management, CPU & GPU engine memory accesses and reuse, and sparse tile mapping. Yet, the application could recycle data through the pipeline with familiar memory barrier and fence primitives.

As D3D supports more features that give the impression of complete control over memory, the risks of application misunderstanding go up. Standard swizzle, tiled resources, and CPU accessible textures will lead developers to mistakenly believe they can hardcode render target heap sizes and residency impact. The lack of application awareness at the API currently makes this worse. And, we hope to address awareness with some further D3D12 designs before final release.

It is suspected that this hardware goal is even more challenging for low power devices; but would like to understand if it is so.

- **Evolve toward standard layout**

Microsoft intends to evolve GPU texture memory layout to have a standard layout option, in order to expose GPU VA for textures as part of the bind-less design. This is similar to, and complements the standard swizzle design. This will be realized after Windows 10 release; but the direction is established due to long hardware design lead times.

The D3D12 API and DDI have a defined ordering of subresources, which was recently tweaked to better represent planar resources. The canonical resource data for a subresource index all comes before the canonical resource data for the next larger subresource index. D3D12 currently defines this ordering as such:

```cpp
UINT D3D12CalcSubresource(
    UINT MipSlice, UINT ArraySlice, UINT PlaneSlice, UINT MipLevels, UINT ArraySize
    )
{ return MipSlice + ArraySlice * MipLevels + PlaneSlice * MipLevels * ArraySize; }
```

Textures are built up of chunks of data that are sized to a power-of-2, that are typically near-equilateral in the texture's dimensionality. These chunks are commonly referred to as tiles. The tiled resource design matches the tile size to a page size, enabling sparsely mapped resource scenarios. To build off of the straight-forward tiled resource and standard swizzle designs, the first standardized texture layouts will use uniform tile shapes.

Subsequent subresource data begins on the next tile boundary in GPU VA space. This results in noticeable waste for smaller detailed mip levels, but such waste seems acceptable when considering the whole resource. While tiled resources currently allows for packing the smallest mip levels into one or more tiles, the first standardized layout that supports mips will require tile-alignment into all the mip levels.

Like the D3D12 resource estimation DDI currently implies, un-hidden compression data must be located after all the normal resource data, preferably tile or page-aligned, in GPU VA space. This design direction is preferred, to minimize the odds of applications reaching into it. No "gaps" in GPU VA space currently exist on the roadmap to standard layout. This applies to all types of auxiliary compression data, like render target, depth-stencil, MSAA, clear optimizations, media encode, and media decode.

### Driver Requirements and DDI Reference

#### Support Map Default Texture/ Standard Swizzle Spec

See Map Default Texture/ Standard Swizzle Spec.

#### Divulge heap tier support

```cpp
typedef enum D3D12DDICAPS_TYPE
{
    ...
    D3D12DDICAPS_TYPE_D3D12_OPTIONS,
    ...
} D3D12DDICAPS_TYPE;

// D3D12DDICAPS_TYPE_D3D12_OPTIONS
typedef enum D3D12DDI_RESOURCE_HEAP_TIER
{
    D3D12DDI_RESOURCE_HEAP_TIER_1 = 1,
    D3D12DDI_RESOURCE_HEAP_TIER_2 = 2,
} D3D12DDI_RESOURCE_HEAP_TIER;

typedef struct D3D12DDI_D3D12_OPTIONS_DATA_XXXX
{
    ...
    D3D12DDI_RESOURCE_HEAP_TIER ResourceHeapTier;
} D3D12DDI_D3D12_OPTIONS_DATA_XXXX;
```

<!-- Net-new: D3D12DDI_RESOURCE_HEAP_TIER, D3D12DDI_D3D12_OPTIONS_DATA_XXXX, and the D3D12DDICAPS_TYPE_D3D12_OPTIONS cap variant added in March 2015 -->

<!-- Supersession: the March 2015 "Support D3D12 tiers" requirement folded into base "Divulge heap tier support"; the cap-reporting requirement was already present -->

The driver must indicate which heap tier the adapter supports. The UMD must also pay attention to the new heap flags when useful during heap creation.

#### Support heap creation in D3D12

```cpp
////////////////////////////////////
// Heap Focused:
////////////////////////////////////

typedef enum D3D12DDI_CPU_PAGE_PROPERTIES
{
    D3D12DDI_CPU_PAGE_NOT_AVAILABLE = 0,
    D3D12DDI_CPU_PAGE_WRITE_COMBINE = 1,
    D3D12DDI_CPU_PAGE_WRITE_BACK    = 2,
} D3D12DDI_CPU_PAGE_PROPERTIES;

typedef enum D3D12DDI_MEMORY_POOL
{
    D3D12DDI_MEMORY_POOL_L0 = 0, // Always system memory
    D3D12DDI_MEMORY_POOL_L1 = 1, // Typically local video memory
} D3D12DDI_MEMORY_POOL;

typedef enum D3D12DDI_HEAP_MISC_FLAG
{
    D3D12DDI_HEAP_MISC_NONE                                    = 0x0, // Constant for no flags
    D3D12DDI_HEAP_MISC_TEXTURES                                = 0x2,
    D3D12DDI_HEAP_MISC_BUFFERS                                 = 0x4,
    D3D12DDI_HEAP_MISC_COHERENT_SYSTEMWIDE                     = 0x8,
    D3D12DDI_HEAP_MISC_PRIMARY                                 = 0x10,
    D3D12DDI_HEAP_MISC_RENDER_TARGET_AND_DEPTH_STENCIL_TEXTURES = 0x20,
} D3D12DDI_HEAP_MISC_FLAG;
DEFINE_ENUM_FLAG_OPERATORS( D3D12DDI_HEAP_MISC_FLAG );

typedef struct D3D12DDIARG_CREATEHEAP
{
    UINT64 ByteSize;
    UINT64 Alignment;
    D3D12DDI_MEMORY_POOL MemoryPool;
    D3D12DDI_CPU_PAGE_PROPERTIES CPUPageProperties;
    D3D12DDI_HEAP_MISC_FLAG MiscFlags;
} D3D12DDIARG_CREATEHEAP;
```

<!-- Supersession: D3D12DDI_CPU_PAGE_PROPERTIES, D3D12DDI_MEMORY_POOL, D3D12DDI_HEAP_MISC_FLAG, and D3D12DDIARG_CREATEHEAP updated in March 2015 (explicit numeric values assigned to CPU_PAGE_PROPERTIES and MEMORY_POOL; HEAP_MISC_FLAG gains NONE/TEXTURES/BUFFERS/COHERENT_SYSTEMWIDE/PRIMARY/RENDER_TARGET_AND_DEPTH_STENCIL_TEXTURES with explicit bit values and DEFINE_ENUM_FLAG_OPERATORS; CREATE_HEAP renamed to CREATEHEAP) -->

The `PRIMARY` heap bit is only set on non-mipped, non-MSAA 2D arrays (for stereo) with formats that support scan-out, and precludes depth-stencil support. This support is for Flip Model presentation requirements that also supports direct flip.

Whenever a heap is created with the `PRIMARY` flag, a resource will simultaneously be created along with the heap. No primary desc is passed to the driver any longer.

The Render Target and Depth Stencil heap flag is added to denote which resource types the heap allows. Just like the heap tiers specify, there are the following types of resources.

1. Buffers
2. Non-render target & non-depth stencil textures
3. Render target or depth stencil textures

The DDI will continue to express heap scenarios that don't perfectly match up to the factoring of the heap tier 1, in order to exercise UMD behavior that was allowed in previous D3D12 distributions. Most specifically, the UMD must continue to handle cases where the flags for b & c are both set.

All these methods can be called by multiple threads concurrently.

These DDIs may be refactored to avoid a callback model. This will simplify the runtime, driver, test, and tool design, for features such as: shared heaps, user mode heap recycling, heap sub-allocation, cross-adapter resources, command list back-buffer patching, and integrated vs. discrete design, etc.

**`CPU_PAGE_PROPERTIES` & `MEMORY_SEGMENT`**

The runtime will choose CPU access characteristics and location preference of the memory segment. The driver must honor the page & segment request exactly. The runtime understands when a UMA design is available, so will not request `_L1` on UMA designs. The runtime also understands when a cache-coherent UMA design is available, so requests for write-combine will be rare. The runtime will never request `WRITE_BACK` with `_L1`. The runtime will own any policy related to the functional disparity between integrated and discrete GPU designs.

`_L0` is required to be in system memory segments.

`_L1` is required to be in video memory segments for discrete GPUs, but is generalized to potentially support alternate memory hierarchies like explicit caches for UMA systems.

**`MISC_FLAG`**

All heaps are required to be used as tile pools, and be shared without explicit driver knowledge.

`PHYSICALLY_CONTIGUOUS` is a heap property that may need to be set for supporting other engines. It is only supported for hardware that has already shipped.

**`CreateHeap`**

Creating a heap is equivalent to creating backing store, just like a section does. The driver is required to call `AllocateCB` with the `HRTRESOURCE` handle within the call to create the heap, just like shared resources were required to. See resource creation for more details, as the calls are merged.

**`DestroyHeap`**

The driver is required to call `DestroyCB` with the `HRTRESOURCE` handle within the call to destroy the heap, just like shared resources were required to. See resource creation for more details, as the calls are merged.

**Note, heaps will likely need to be supported on WDDM1.3. Feedback to make this easier is welcome.**

#### Make Heaps & Other Objects Resident

```cpp
typedef struct D3D12DDI_HANDLE_AND_TYPE
{
    VOID* Handle;
    D3D12DDI_HANDLETYPE Type;
} D3D12DDI_HANDLE_AND_TYPE;

typedef struct D3D12DDIARG_MAKERESIDENT
{
    D3D12DDI_HRTPAGINGQUEUE hRTPagingQueue;
    UINT NumObjects;
    _Field_size_(NumObjects) CONST D3D12DDI_HANDLE_AND_TYPE* pObjects;
    D3DDDI_MAKERESIDENT_FLAGS Flags;
    UINT64 PagingFenceValue;                                // out: Fence to wait on
} D3D12DDIARG_MAKERESIDENT;

typedef struct D3D12DDIARG_EVICT
{
    D3D12DDI_HRTPAGINGQUEUE hRTPagingQueue;
    UINT NumObjects;
    _Field_size_(NumObjects) CONST D3D12DDI_HANDLE_AND_TYPE* pObjects;
    D3DDDI_EVICT_FLAGS Flags;
} D3D12DDIARG_EVICT;

typedef HRESULT ( APIENTRY* PFND3D12DDI_MAKERESIDENT2 )(
     D3D10DDI_HDEVICE, D3D12DDIARG_MAKERESIDENT* );

typedef HRESULT ( APIENTRY* PFND3D12DDI_EVICT2 )(
     D3D10DDI_HDEVICE, CONST D3D12DDIARG_EVICT* );

typedef struct D3D12DDI_DEVICE_FUNCS_CORE
{
...
    PFND3D12DDI_MAKERESIDENT2  pfnMakeResident;
    PFND3D12DDI_EVICT2         pfnEvict;
...
};
```

These DDIs support multiple threads calling into them simultaneously, so the driver must use fine-grained synchronization when appropriate. The driver must forward the flags passed in to both `MakeResident` and `Evict` to the callback routines, and copy the resulting fence value from the callback as an output to these calls.

The `MakeResident` DDI call will specify an array of handles that must be translated to an array of `D3DKMT_HANDLE`s. Because the driver may group multiple allocations in a resource, it is possible that multiple calls to `MakeResidentCb` may be required to satisfy the request. It is imperative that drivers that need to do this are able to return the proper fence value to user mode. If VidMm detects that an array of allocations is already made resident, it may return `STATUS_PENDING` while also providing a fence value that is older than the current batch. The driver must detect this condition, and return not the "newest" fence, but instead must use the "max" fence across all calls that return `STATUS_PENDING` (accounting for 32-bit wraparound).

For example, imagine the application has 2 resources – A, and B:

A consists of 2 allocations, 1 and 2.

B consists of a single allocation, 3.

The application calls `MakeResident` on A. The driver translates this into an array of 2 handles, and receives a fence of 42 in return.

The application then calls `MakeResident` on an array of resources, {B, A}. The driver may only have enough scratch space on the stack to satisfy 2 allocations at a time. As a result, the driver calls kernel with allocations {3,1} in batch 1 and receive fence 43, then {2} in batch 2, but get back fence 42, since allocation 2 is already made resident. The driver must then return 43 (the "max" fence value returned) to the runtime, instead of 42 (the "most recent" fence value returned).

Drivers must obey the "all or nothing" policy with `MakeResident` in D3D12. That is, a call to `MakeResident` must fully succeed, or fully fail, and cannot return to the caller with a partially resident state. The runtime manages return values from kernel in the callback routine, as well as cleanup involved with batching during the runtime's `MakeResident` call. When the driver translates the driver objects to the appropriate `D3DKMT_HANDLE` array for the callback routine, it may process resources that contain more than one allocation per resource. Therefore the driver is required to do one of two things:

- Ensure that the array used to hold the `D3DKMT_HANDLE`s is large enough to accommodate all allocations in one batch. All failure cases will then be handled in the callback routine in the runtime.
- The other option is to batch calls internally to the callback routine. While this is discouraged if the previous method can be done, it may be unavoidable to achieve optimal performance requirements. In this case it is absolutely critical that the driver cleanup all failure cases. This means that if the array is translated to two batches, and the callback routine returns an error on the second batch, the driver must manually call `EvictCb` on the first batch.

In D3D12, applications must tightly understand all GPU-accessible memory lifespans, including residency. The resource binding model enables applications to build large descriptor heaps for resources. Some entries can refer to resources/ heaps that are no longer alive or resident. The application must ensure such entries are not referenced to keep the application running normally.

D3D12 will likely only support one paging queue in the short-term, which is the default paging queue.

The application or runtime must make the following objects resident, and ensure the GPU is no longer using them before eviction:

- Heaps
- Descriptor Heaps
- CommandAllocator
- PipelineState
- Queries & UnorderedAccessViewCounter
- CommandQueues (except default paging queue)
- Resource (page-table entries, due to tiled resource design)

When the driver has non-NULL entry points for these DDI entry points, the driver must no longer create allocations associated with any d3d12 driver handle creation DDIs as resident during creation. Additionally, the driver must also set the `DXGK_CONTEXTINFO_CAPS::DriverManagesResidency` flag on context creation.

All allocated GPU-accessible memory must be associated directly or indirectly with one of the previously listed objects that supports residency manipulation. Given time, we'll evolve heap concepts to all features to avoid design that indirectly associated GPU-accessible memory with the previously listed objects. As an example, generate-mips resources are deprecated; and we intend to evolve queries to support placement on heaps.

In an ideal residency design, there would be no need for a trim DDI. The application would batch objects into heaps, understand how heaps translate to memory segment usage, and just use eviction to respond to memory pressure notifications.

The runtime will manage an implicit paging queue object that is tied to the device. Currently there is no plan to associate a UMD DDI object with the paging queue, and thus we will pass a `D3D12DDI_HRTPAGINGQUEUE` handle to call to `MakeResident` and `Evict`, and the driver must provide the handle back to the callback routines, as is. The driver must not attempt to use these values. Then, when `pfnMakeResident` is called the driver must make the appropriate calls to `MakeResidentCb`. The callbacks must be called using the `pKTQueueCallbacks` table provided in `D3D12DDIARG_CREATEDEVICE` and passing the runtime handle (`D3D12DDI_HRTCOMMANDQUEUE`) corresponding to the user-mode paging queue.

#### Map and Unmap is on Heap

```cpp
typedef HRESULT ( APIENTRY* PFND3D12DDI_MAPHEAP )( D3D10DDI_HDEVICE,
     D3D12DDI_HHEAP, _Out_ VOID** );

typedef VOID ( APIENTRY* PFND3D12DDI_UNMAPHEAP )( D3D10DDI_HDEVICE,
     D3D12DDI_HHEAP );

typedef struct D3D12DDI_DEVICE_FUNCS_CORE
{
...
    PFND3D12DDI_MAPHEAP   pfnMapHeap;
    PFND3D12DDI_UNMAPHEAP pfnUnmapHeap;
...
};
```

1. Map(DISCARD) is not supported by D3D12. Applications must implement resource renaming themselves.
2. All Map calls now are implicitly `NO_OVERWRITE` and multi-threaded. And `DO_NOT_WAIT` is deprecated.
    1. The driver no longer implicitly flush any command buffers when map is called. It is the application's responsibility to ensure that any relevant work contained in command lists is submitted to the appropriate command queue before map is called.
    2. Map no longer blocks waiting for the GPU to finish work. It is the application's responsibility to ensure that the GPU has finished any relevant work before calling Map.
3. When the GPU does not support I/O coherence, the runtime will use the appropriate thunks to invalidate and flush CPU caches. This cap is introduced in the standard swizzle spec.

Heaps can always be mapped at the DDI level, even while the GPU is busy reading or writing to the resource. The runtime will understand how to handle the lack of I/O coherence.

In order to avoid HCK performance testing, we intend to strongly validate the page permissions, page modifiers, caching properties associated with the CPU virtual addresses.

#### Support Resource Creation

```cpp
typedef enum D3D12DDI_TEXTURE_LAYOUT
{
    D3D12DDI_TL_UNDEFINED                   = 0,
    D3D12DDI_TL_ROW_MAJOR                   = 1,
    D3D12DDI_TL_64KB_TILE_UNDEFINED_SWIZZLE = 2,
    D3D12DDI_TL_64KB_TILE_STANDARD_SWIZZLE  = 3,
    D3D12DDI_TL_DEVICE_DEPENDENT_SWIZZLE_0  = 0x100,
} D3D12DDI_TEXTURE_LAYOUT;

typedef enum D3D12DDI_RESOURCE_MISC_FLAG
{
    D3D12DDI_RESOURCE_MISC_RENDER_TARGET,
    D3D12DDI_RESOURCE_MISC_DEPTH_STENCIL,
} D3D12DDI_RESOURCE_MISC_FLAG;

typedef enum D3D12DDI_RESOURCE_TYPE
{
    D3D12DDI_RT_BUFFER     = 1,
    D3D12DDI_RT_TEXTURE_1D = 2,
    D3D12DDI_RT_TEXTURE_2D = 3,
    D3D12DDI_RT_TEXTURE_3D = 4,
} D3D12DDI_RESOURCE_TYPE;

typedef struct D3D12DDIARG_ROW_MAJOR_RESOURCE_LAYOUT
{
    UINT RowPitch;
    UINT SlicePitch;
} D3D12DDIARG_ROW_MAJOR_RESOURCE_LAYOUT;

typedef struct D3D12DDIARG_CREATERESOURCE
{
    // Member Cleanup:
    D3D12DDIARG_BUFFER_PLACEMENT  ParentResource;
    D3D12DDI_RESOURCE_TYPE         ResourceType;
    UINT64                        Width; // Virtual coords
    UINT                          Height; // Virtual coords
    UINT16                        DepthOrArraySize;
    UINT16                        MipLevels;
    DXGI_FORMAT                   Format;
    DXGI_SAMPLE_DESC              SampleDesc;
    D3D12DDI_TEXTURE_LAYOUT       Layout; // See standard swizzle spec
    D3D12DDI_RESOURCE_MISC_FLAG   MiscFlags;
    D3D12DDI_RESOURCE_USAGE       InitialResourceState;

    // Member Cleanup:
    CONST D3D12DDIARG_ROW_MAJOR_RESOURCE_LAYOUT* pRowMajorLayout;
} D3D12DDIARG_CREATERESOURCE;

typedef struct D3D12DDI_DEPTH_STENCIL_VALUES
{
    FLOAT Depth;
    UINT8 Stencil;
} D3D12DDI_DEPTH_STENCIL_VALUES;

typedef struct D3D12DDI_CLEAR_VALUES
{
    DXGI_FORMAT Format;
    union
    {
        FLOAT Color[4];
        D3D12DDI_DEPTH_STENCIL_VALUES DepthStencil;
    };
} D3D12DDI_CLEAR_VALUES;

typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATEHEAPANDRESOURCE )(
    D3D12DDI_HDEVICE,
    _In_opt_ CONST D3D12DDIARG_CREATEHEAP*,
    D3D12DDI_HHEAP,
    D3D12DDI_HRTRESOURCE, // Cleanup
    _In_opt_ CONST D3D12DDIARG_CREATERESOURCE*,
    _In_opt_ CONST D3D12DDI_CLEAR_VALUES* pOptimizedClearValue,
    D3D12DDI_HRESOURCE );
```

<!-- Supersession: D3D12DDIARG_CREATERESOURCE refactored in March 2015 (ParentResource replaces hReuseBufferGPUVA/BufferOffset; pRowMajorLayout member added; member set reorganized) -->
<!-- Supersession: PFND3D12DDI_CREATEHEAPANDRESOURCE updated in March 2015 (gains pOptimizedClearValue parameter of type D3D12DDI_CLEAR_VALUES*) -->
<!-- Net-new: D3D12DDI_TEXTURE_LAYOUT enum (TL_UNDEFINED/ROW_MAJOR/64KB_UNDEFINED_SWIZZLE/64KB_STANDARD_SWIZZLE/DEVICE_DEPENDENT_SWIZZLE_0) added in March 2015 -->
<!-- Net-new: D3D12DDI_RESOURCE_TYPE, D3D12DDIARG_ROW_MAJOR_RESOURCE_LAYOUT, D3D12DDI_DEPTH_STENCIL_VALUES, and D3D12DDI_CLEAR_VALUES added in March 2015 -->

```cpp
typedef struct D3D12DDI_HEAP_AND_RESOURCE_SIZES
{
    SIZE_T Heap;
    SIZE_T Resource;
} D3D12DDI_HEAP_AND_RESOURCE_SIZES;

typedef D3D12DDI_HEAP_AND_RESOURCE_SIZES
    ( APIENTRY* PFND3D12DDI_CALCPRIVATEHEAPANDRESOURCESIZES )(
        D3D10DDI_HDEVICE,
        _In_opt_ CONST D3D12DDIARG_CREATEHEAP*,
        _In_opt_ CONST D3D12DDIARG_CREATERESOURCE* );

typedef VOID ( APIENTRY* PFND3D12DDI_DESTROYHEAPANDRESOURCE )(
    D3D10DDI_HDEVICE, D3D10DDI_HHEAP, D3D10DDI_HRESOURCE );

// Sharing:
typedef struct D3D12DDIARG_OPENHEAP2
{
    UINT                        NumAllocations;
    D3DDDI_OPENALLOCATIONINFO*  pOpenAllocationInfo;
    D3D10DDI_HKMRESOURCE        hKMResource;
    VOID*                       pPrivateDriverData;
    UINT                        PrivateDriverDataSize;
    D3D12DDI_RESOURCE_USAGE     InitialResourceState;
} D3D12DDIARG_OPENHEAP2;

typedef D3D12DDI_HEAP_AND_RESOURCE_SIZES
    ( APIENTRY* PFND3D12DDI_CALCPRIVATEOPENEDHEAPANDRESOURCESIZES2 )(
    D3D10DDI_HDEVICE, _In_ CONST D3D12DDIARG_OPENHEAP2* );

typedef HRESULT ( APIENTRY* PFND3D12DDI_OPENHEAPANDRESOURCE2 )(
    D3D10DDI_HDEVICE,
    _In_opt_ CONST D3D12DDIARG_OPENHEAP2*, D3D12DDI_HHEAP,
        D3D10DDI_HRTRESOURCE,
    D3D12DDI_HRESOURCE );

typedef struct D3D12DDI_DEVICE_FUNCS_CORE
{
...
    PFND3D12DDI_CALCPRIVATEHEAPANDRESOURCESIZES    pfnCalcPrivateHeapAndResourceSize;
    PFND3D12DDI_CREATEHEAPANDRESOURCE      pfnCreateHeapAndResource;
    PFND3D12DDI_DESTROYHEAPANDRESOURCE     pfnDestroyHeapAndResource;
    PFND3D12DDI_CALCPRIVATEOPENEDHEAPANDRESOURCESIZES2
        pfnCalcPrivateOpenedHeapAndResourceSizes2;
    PFND3D12DDI_OPENHEAPANDRESOURCE2       pfnOpenHeapAndResource2;
...
};
```


The one heap and resource creation method can be used to create:

- A heap, by itself. This technique creates backing store for GPU accessible memory, known in D3D11 as a tile pool. In D3D12, such backing store is support in many more cases than just tile pool was.
- A resource, by itself. There are two techniques associated with creating resources:
    - Reserve New GPU VA: This technique leverages the same behavior as creating a tiled resource in D3D11. In D3D12, it can be leveraged for all resources, not just those with 64KB square/ cube layouts. Common application usage scenarios will map these resources to a heap later.
    - Capture Resource GPU VA: This technique is new for D3D12. New resources must be able to be created at a particular aligned offset within a previously created buffer.
- Both a heap and a resource, together. This technique allocates GPU VA and commits it to physical backing store at the same time. This enables the optimization of a single VA commit, instead of requiring two operations: reserve and then commit.

The resource and heap creation & destruction methods are able to be called by multiple threads concurrently.

**Commit New GPU VA**

Applications can create a resource and heap at the same time. This is the traditional resource creation scenario applications have used throughout many D3D versions. The heap will typically be sized to locate the resource within it; but a larger heap is supported as well in D3D12.

Applications are suspected to commonly create contiguous GPU VA for the entire heap by creating a buffer at the same time as creating a heap. This allows significant flexibility with the following techniques of resource creation.

While many applications will likely opt to create a buffer across the whole heap, other resources can work as well. The resource can be unmapped or re-mapped to another heap, after creation. And, another resource can be mapped or unmapped to the heap after creation. Overlapping cases are allowed, just like tiled resources allowed.

The application may leverage well-defined aliasing for resource with known layouts, as long as the D3D11 tiled resource tier allowed it as well. However, the resource transition barrier must be switched to `generic_read` for render target & depth stencil textures, and the aliasing barrier must be used in conjunction, to enable such aliasing cases. `Generic_read` includes `default_read`, `copy_source`, `non_pixel_shader_resource`, `pixel_shader_resource`, and `indirect_argument`.

A significant exception is for BAR1, for tiled resource tiers that don't support 64KB tiled layouts for volumes. Heaps created against L1 with `WRITE_COMBINE` must create both a heap and resource together. Such a pairing is less flexible than normal. The heap can only support resource mapping changes, if the resource created with it is a buffer. And, the changes must be for other buffers. The same restrictions apply to the resource created with it. The Capture Resource GPU VA technique is similarly restricted, such that only buffers can be created on top of a buffer created against a BAR1 heap.

**Reserve New GPU VA**

Applications can create a resource without a heap. When the `hReuseBufferGPUVA` field in the `CREATERESOURCE` structure is NULL, this reserves GPU virtual memory just like D3D11 tiled resources do. D3D12 extends such functionality to all resources, not just those with 64KB tile resources.

Such resources will typically be mapped to one or more heaps, later, before they are used with the graphics pipeline. When resources are used while not mapped to any heap, the tiled resource tier defines what happens.

This functionality is useful for applications to defrag heaps or seamlessly move resources between multiple memory pools, without perturbing a render thread. Command lists can also be more heavily re-used, while relocating a resource. It also has unique value for tools after GPU VA page protection support becomes available.

**Capture Resource GPU VA**

The last technique of video memory re-use is to not use multiple, unique GPU virtual addresses; but re-use memory through the same GPU virtual address. When the `hReuseBufferGPUVA` field in the `CREATERESOURCE` structure is non-NULL, an aligned offset is passed in `BufferOffset` to the resource creation API. A heap will not be created at the same time as creating such a resource.

The driver must capture the effective GPU virtual address of the underlying `hReuseBufferGPUVA`, modified by the `BufferOffset`; and re-use it for the newly created resource. Such a resource cannot be used with methods that change the page table: `UpdateResourceMappings` and `UpdateTileMappings`.

Remapping the underlying resource's GPU virtual address to another heap, remaps all resources created with this technique. Such functionality will be used by application which cannot predict the make-up of their heaps. A common scenario would be a producer/ consumer pipe in video memory. The pipe would typically be made up of a few large buffers. The producer will quickly characterize the memory of such a heap, by creating these type of resources at a steadily increasing offset within the buffer. The entire package will then be consumed by another parallel processing unit.

Each resource has its own unique resource transition state. This allows the application to create multiple smaller buffers on a large buffer, and avoid transitioning the whole buffer for sub-allocations.

Aliasing is allowed when the resource layouts are defined. To do so, the resource transition barrier must be switched to `generic_read` (which includes `default_read`, `copy_source`, `non_pixel_shader_resource`, `pixel_shader_resource`, and `indirect_argument`) for render target & depth stencil textures, and then the aliasing barrier must be used. Other tiled resource restrictions apply.

**Adjust to the effective deprecation of the following DDI parameters.**

The following flags are effectively deprecated, as all resources support these capabilities.

BindFlags: `_VERTEX_BUFFER`, `_INDEX_BUFFER`, `_CONSTANT_BUFFER`

MiscFlags: `_DRAWINDIRECT_ARGS`, `_BUFFER_ALLOW_RAW_VIEWS`,

`_MISC_BUFFER_ALLOW_RAW_VIEWS` must now be supported in conjunction with `_BIND_CONSTANT_BUFFER`.

The following resource properties & flags are effectively deprecated for resources, as they now more directly apply to heaps:

`D3D10_DDI_RESOURCE_USAGE { _DEFAULT, _IMMUTABLE, _DYNAMIC, _STAGING }`

`D3D10_DDI_CPU_ACCESS { _WRITE, _READ }`

MiscFlags: `_SHARED`, `_TILE_POOL`

The CPU access flag no longer defines `row_major` or swizzled. The layout does.

The following flags are deprecated for the following reasons:

Supporting `GENERATE_MIPS` is suspected to cause more issues than its convenience is worth. The driver likely has to store an implicit descriptor heap, constant buffer, and pipeline state objects for the operation. Such implicit memory usage and driver complexity is less desirable than explicit application understanding of memory consumption and lifetime.

`UNORDERED_ACCESS` is deprecated because there is no known behavior changes required during resource creation.

`SHADER_RESOURCE` is deprecated from a resource flag, because multi-dimensional texture data must be able to be consumed from all engines and from all bind points in the pipeline from all devices. Instead, this flag is converted to an optimization flag which allows the driver to tailor swizzle patterns based on its presence.

**Notice the absence of many other flags and resource properties. Please indicate which pre-existing DDI flags and properties are required and why. We suspect most of them are not useful.**

**Shared physical memory, including cross-DDI**

Shared resources created in D3D11 must be able to be opened in D3D12. This behavior must be supported until all previous D3Ds can be hoisted on top of D3D12.

Similar scenarios must be supported in reverse, as well. D3D12-created resources must be able to be opened by DWM, using D3D11 and the 11 DDI. Such resources will be created as both resource & heap with compatible D3D11 descriptions.

There is no plan to denote when a resource being created is being shared between devices or between processes. Such support is expected to seamlessly evolve into supporting sharing memory between adapters.

#### CheckResourceAllocationInfo

```cpp
typedef enum D3D12DDI_RESOURCE_OPTIMIZATION
{
    D3D12DDI_RESOURCE_OPTIMIZATION_SHADER_RESOURCE,
    D3D12DDI_RESOURCE_OPTIMIZATION_PRIMARY,
    D3D12DDI_RESOURCE_OPTIMIZATION_UNORDERED_ACCESS,
    D3D12DDI_RESOURCE_OPTIMIZATION_DETERMINISTIC,
} D3D12DDI_RESOURCE_OPTIMIZATION;

typedef enum D3D12DDI_RESOURCE_DATA_REQUIREMENT
{
    D3D12DDI_RESOURCE_DATA_REQUIREMENT_PHYSICALLY_CONTIGUOUS_HEAP,
} D3D12DDI_RESOURCE_DATA_REQUIREMENT;

// Note: D3D12DDI_RESOURCE_DATA_REQUIREMENT was referenced by the original
// February 2015 form of D3D12DDI_RESOURCE_ALLOCATION_INFO (via ResourceDataRequirements
// and AdditionalDataRequirements fields). The March 2015 revision supersedes that struct
// and drops those fields, leaving this enum without an in-corpus consumer.
// Preserved here for faithfulness to the original declaration.

typedef struct D3D12DDI_RESOURCE_ALLOCATION_INFO
{
    UINT64 ResourceDataSize;
    UINT64 AdditionalDataHeaderSize;
    UINT64 AdditionalDataSize;
    UINT64 ResourceDataAlignment;
    union
    {
        UINT64 AdditionalDataHeaderAlignment;
        struct
        {
            UINT32 AdditionalDataHeaderAlignment1;
            UINT8 AdditionalMipLevelSwizzleTransitionsArray[4];
        };
    };
    UINT64 AdditionalDataAlignment;
    D3D12DDI_TEXTURE_LAYOUT Layout;
    UINT8 MipLevelSwizzleTransition;
} D3D12DDI_RESOURCE_ALLOCATION_INFO;

typedef VOID ( APIENTRY* PFND3D12DDI_CHECKRESOURCEALLOCATIONINFO )(
    D3D12DDI_HDEVICE,
    _In_ CONST D3D12DDIARG_CREATERESOURCE*,
    D3D12DDI_RESOURCE_OPTIMIZATION,
    UINT64 AlignmentRestriction,
    _Out_ D3D12DDI_RESOURCE_ALLOCATION_INFO* pInfo );

typedef struct D3D12DDI_DEVICE_FUNCS_CORE
{
...
    PFND3D12DDI_ CHECKRESOURCEALLOCATIONINFO
        pfnCheckResourceAllocationInfo;
...
};
```

<!-- Supersession: D3D12DDI_RESOURCE_OPTIMIZATION updated in March 2015 (adds UNORDERED_ACCESS and DETERMINISTIC) -->
<!-- Supersession: D3D12DDI_RESOURCE_ALLOCATION_INFO updated in March 2015 (adds AdditionalDataHeaderSize, AdditionalDataHeaderAlignment, MipLevelSwizzleTransition; removes ResourceDataRequirements/AdditionalDataRequirements) -->
<!-- Supersession: D3D12DDI_RESOURCE_ALLOCATION_INFO further updated in May 2015 (anonymous union wraps AdditionalDataHeaderAlignment with AdditionalMipLevelSwizzleTransitionsArray[4]) -->
<!-- Supersession: PFND3D12DDI_CHECKRESOURCEALLOCATIONINFO updated in March 2015 (return type becomes VOID; gains UINT64 AlignmentRestriction in-param and D3D12DDI_RESOURCE_ALLOCATION_INFO* out-param) -->

Creation of a resource still goes through two steps in D3D12. These steps are most obviously needed for textures, but buffers must be supported for orthogonality.

1. First, the sizes and alignments of the resource data, additional data header, and additional data is determined along with the parameterized swizzle patterns, using `CheckResourceAllocationInfo`. When the resource description is passed into `CheckResourceAllocationInfo`, the `Layout` of the resource description may be set to `_UNDEFINED`. When the `Layout` of the resource description is `STANDARD_SWIZZLE`, the driver must return out `STANDARD_SWIZZLE` as well.
2. Second, the resource is created using the properties derived from this method. During resource creation, the `Layout` will never be set to `_UNDEFINED`, since the driver will have returned a resolved swizzle pattern.

This DDI is also used by applications to calculate the size of resources to create appropriately sized heaps, before actually creating any resources.

###### Resource alignment restrictions and optimization flags

These parameters are intentionally separated from resource creation flags to highlight how they are intended to be used by the driver. They should only influence the driver's choice of device-dependent swizzle pattern. These parameters cannot choose a resource layout which would preclude orthogonally supporting such other resource properties, like resource misc flags, in general.

As an example, both the presence and absence of `SHADER_RESOURCE` are supported as orthogonally as other resource properties and other resource optimizations. New resource optimization flags are expected to follow such behavior.

Exceptions are listed below, and they should be equivalent to existing D3D11 rules:

The `PRIMARY` resource optimization bit is only set on non-mipped, non-MSAA 2D arrays (for stereo) with formats that support scan-out, and precludes depth-stencil support. This support is for Flip Model presentation requirements that also support direct-flip.

Previous specs elaborated more on the details of other flags.

This method enables applications to calculate the size of resources and understand alignment requirements. The size of a resource needs to include any additional data necessary that the application may not expect. For example, depth stencil textures may need additional data for early depth fail optimizations.

This method can be called from multiple threads and must return the same result when the same input resource and flag parameters are passed.

Sizes must be strictly increasing with respect to dimensions. A resource descriptor with the same parameters but greater or equal dimensions must return a size that is greater or equal to the other resource descriptor.

Some resources, like those which support render target and depth stencil usage, have additional data associated with them during their usage. This method also retrieves the size of that region as well. The region may be mapped on a heap of different properties than the pixel data. Mapping such a region to a shared heap enables the data to be shared cross-process.

The alignment fields must be a power of two, and the alignment requirements must not be larger than 64KiB, unless the number of MSAA samples is greater than 1.

The driver may list additional requirements for each sub-section of a resource.

**`RESOURCE_OPTIMIZATION`**

These flags are intended to potentially optimize device-dependent swizzle pattern choices. This flag cannot choose a resource layout which would preclude orthogonally supporting other resource properties, like resource misc flags, in general. Exceptions are listed below, and they should be very close to existing D3D11 rules:

`PRIMARY` only supports single-subresource non-MSAA 2D arrays (for stereo), without depth-stencil, and with formats that support scan-out. Support aligns to Flip Model presentation requirements.

Both the presence and absence of `SHADER_RESOURCE` are supported as orthogonally as other resource properties and other resource optimizations. New resource optimization flags are expected to follow such behavior.

**`PHYSICALLY_CONTIGUOUS_HEAP`**

This sub-section of a resource must be placed in a heap that will use physically contiguous addresses when resident. Only resources with misc flags for primaries can use this flag. These flags on resources and these heap requirement flags are being phased out, since new hardware engines will support virtual addressing.

Are additional segments/ sizes required to handle even more additional, opaque data?

**Layout**

The driver must return which layout it will chose to the runtime. This will save creation costs during scenarios where the heap and resource are created simultaneously, and the applications wants the heap sized and aligned to the resource properties. It will also allow tools to understand the data layout within the resource.

#### UpdateResourceMappings (Abandoned — not shipped)

This DDI was declared in the September 2014 DDI revision, deleted in the December 2014 revision, re-introduced in the February 2015 revision (apparent oversight), and silently absent from the March 2015 and May 2015 revisions. It never shipped. The declaration is preserved here for historical record.

```cpp
typedef enum D3D12DDI_RESOURCE_MAPPING_FLAG
{
    D3D12DDI_RESOURCE_MAPPING_RESOURCE_DATA,
    D3D12DDI_RESOURCE_MAPPING_ADDITIONAL_DATA,
} D3D12DDI_RESOURCE_MAPPING_FLAG;

typedef VOID ( APIENTRY* PFND3D12DDI_UPDATERESOURCEMAPPINGS )(
    D3D12DDI_HCOMMANDQUEUE, D3D10DDI_HRESOURCE, D3D12DDI_HHEAP,
    UINT64 HeapOffset, D3D12DDI_RESOURCE_MAPPING_FLAG );

typedef struct D3D12DDI_COMMAND_QUEUE_FUNCS_CORE
{
...
    PFND3D12DDI_UPDATERESOURCEMAPPINGS pfnUpdateResourceMappings;
...
};
```

This method is similar to `UpdateTileMappings`, except it places an entire resource on a heap. This method can support all types of resources, including `64KB_UNDEFINED_SWIZZLE` resources. However, the method doesn't allow complex arrangements of page mappings.

The passed-in heap can be NULL, to allow the resource to no longer reside in any heap.

The `HeapOffset` must be a multiple of 64KB.

Multiple resources, including `64KB_UNDEFINED_SWIZZLE` resources, are allowed to reside in the same pages of the heap; but the data is only well-defined for certain transitory cases on top of what tiled resources allows. The application is still required to follow the rules associated with the current tiled resource tier, such as using the aliasing barrier. That rule exists even for non-`64KB_UNDEFINED_SWIZZLE` resources. The contents are only well-defined if both the previous resource and current resource both have the same layout and are either `ROW_MAJOR` or `64KB_STANDARD_SWIZZLE`. If the render-target or depth-stencil bit are set, the application must still call Clear as the first operation after the aliasing barrier.

By default, memory remains intact even if there are no resource mappings to the heap. As long as the application uses well-defined ways of interpreting the memory, it can continue to use the data later.

**`RESOURCE_DATA`**

This flag indicates to place the resource data into a heap.

**`ADDITIONAL_DATA`**

This flag indicate to place the additional data into a heap. If it is set together with `RESOURCE_DATA`, then additional data is placed after the resource data.

#### CheckSubresourceInfo

```cpp
typedef struct D3D12DDI_SUBRESOURCE_INFO
{
    UINT64 Offset;
    UINT RowStride;
    UINT DepthStride;
} D3D12DDI_SUBRESOURCE_INFO;

typedef D3D12DDI_SUBRESOURCE_INFO
    ( APIENTRY* PFND3D12DDI_CHECKSUBRESOURCEINFO )(
        D3D10DDI_HDEVICE hDevice,
        D3D10DDI_HRESOURCE hResource,
        UINT Subresource );

typedef struct D3D12DDI_DEVICE_FUNCS_CORE
{
...
    PFND3D12DDI_CHECKSUBRESOURCEINFO pfnCheckSubresourceInfo;
...
};
```

Since Map is on heap, the subresource characteristics must be retrieved separately from Map. This method can be called from multiple threads and must return the same result when the same input resource parameters are passed.

#### Relocate UpdateTileMappings & CopyTileMappings

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_UPDATETILEMAPPINGS2 )(
    D3D12DDI_HCOMMANDQUEUE hCommandQueue,
    D3D10DDI_HRESOURCE hTiledResource,
    UINT NumTiledResourceRegions,
    _In_reads_(NumTiledResourceRegions) const
        D3D12DDI_TILED_RESOURCE_COORDINATE* pTiledResourceRegionStartCoords,
    _In_reads_opt_(NumTiledResourceRegions) const
        D3D12DDI_TILE_REGION_SIZE* pTiledResourceRegionSizes,
    D3D12DDI_HHEAP hHeap,
    UINT NumRanges,
    _In_reads_opt_(NumRanges) const D3D12DDI_TILE_RANGE_FLAG* pRangeFlags,
    _In_reads_opt_(NumRanges) const UINT* pTilePoolStartOffsets,
    _In_reads_opt_(NumRanges) const UINT* pRangeTileCounts,
    D3D12DDI_TILE_MAPPING_FLAG );

typedef VOID ( APIENTRY* PFND3D12DDI_COPYTILEMAPPINGS2 )(
    D3D12DDI_HCOMMANDQUEUE hCommandQueue,
    D3D10DDI_HRESOURCE hDestTiledResource,
    _In_ const D3D12DDI_TILED_RESOURCE_COORDINATE* pDestRegionStartCoord,
    D3D10DDI_HRESOURCE hSourceTiledResource,
    _In_ const D3D12DDI_TILED_RESOURCE_COORDINATE* pSourceRegionStartCoord,
    _In_ const D3D12DDI_TILE_REGION_SIZE* pTileRegionSize,
    D3D12DDI_TILE_MAPPING_FLAG );

typedef struct D3D12DDI_COMMAND_QUEUE_FUNCS_CORE
{
...
    PFND3D12DDI_UPDATETILEMAPPINGS2 pfnUpdateTileMappings2;
    PFND3D12DDI_COPYTILEMAPPINGS2 pfnCopyTileMappings2;
...
};
```

These operations will eventually be recorded and replayed just like other command list operations, as WDDM2.0 support of page-tables fully evolves. For now, they are located on the same queue as 3D & Compute. The multi-engine spec is the authority on this subject.

Multiple `UpdateTileMappings` calls can now result in a tiled resource having tiles mapped from multiple heaps/ tile pools.

#### Update CopyTiles for D3D12

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_COPYTILES2 )(
    D3D12DDI_HCOMMANDLIST,
    D3D10DDI_HRESOURCE hResource,
    _In_ const D3D12DDI_TILED_RESOURCE_COORDINATE* pRegionStartCoord,
    _In_ const D3D12DDI_TILE_REGION_SIZE* pRegionSize,
    D3D10DDI_HRESOURCE hBuffer, // buffer
    UINT64 BufferStartOffsetInBytes,
    D3D12DDI_TILE_COPY_FLAG );

typedef struct D3D12DDI_COMMAND_LIST_FUNCS_3D
{
...
    PFND3D12DDI_COPYTILES2 pfnCopyTiles2;
...
};
```

This method is trivially updated to use the properly versioned structures, enabling a standalone D3D12 DDI header.

#### Deprecate ResizeTilePool

This operation is deprecated and replaced with the ability of tiled resource to use multiple tile pools. Our 11on12 conversion layer will use multiple heaps to implement the size-changing aspect of D3D11 tile pools.

#### Support D3D12 buffer features

Buffers, can be used everywhere D3D11 dynamic, staging, and default resources could be used, and more. They can be used orthogonally and concurrently from multiple parts of the graphics pipeline, gaining more flexibility:

- SetVertexBuffers
- SetIndexBuffer
- SetConstantBuffers
- Map/ Unmap
- ResourceCopy & ResourceCopyRegion
    - Both as source and destination.
- Draw*Indirect
- DispatchIndirect
- CopyStructureCount
- CopyTiles
    - Both as source and destination buffer.
- Shader buffer loads and buffer writes

ResourceCopy operations must still be performed on the GPU and must not incur a significant CPU workload linearly dependent on the size of the data to copy.

#### Support multi-dimensional content in buffers for copying between memory segments & memory layouts.

```cpp
typedef struct D3D12DDIARG_HRESOURCE_PLACEMENT
{
    D3D10DDI_HRESOURCE hResource;
    UINT64             Offset;
} D3D12DDIARG_HRESOURCE_PLACEMENT;

typedef struct D3D12DDIARG_BUFFER_PLACEMENT
{
    union
    {
        D3D12DDIARG_HRESOURCE_PLACEMENT UMD;
    } BaseAddress;
} D3D12DDIARG_BUFFER_PLACEMENT;

typedef enum D3D12DDI_RESOURCE_LAYOUT
{
    D3D12DDI_RL_UNDEFINED,
    D3D12DDI_RL_PLACED_PHYSICAL_SUBRESOURCE_PITCHED,
    ...
} D3D12DDI_RESOURCE_LAYOUT;
```

Buffer Placement

In general, placement in buffers is supported by a handle structure and a standardized, multi-dimensional placement syntax. The `ARG_BUFFER_PLACEMENT` and `_RESOURCE_LAYOUT` enum build the foundation for this.

For copy operations on the GPU, the `ARG_BUFFER_PLACEMENT` structure must accept `D3D10DDI_HRESOURCE` along with the `Offset` to place something within that buffer. The `Offset` must be correctly aligned during placement.

The `ARG_BUFFER_PLACEMENT` structure is expected to evolve and support more fundamental ways to represent a pointer to memory. If the GPU engine supports constant virtual addresses, then such a concept will eventually be supported by a raw `D3DGPU_VIRTUAL_ADDRESS`.

The `_RESOURCE_LAYOUT` enum is used in conjunction with a `VOID*` to describe the multidimensional layout of memory.

Multiple placements may all overlap the same region of memory. It is well-defined for the GPU to read from the same heap region concurrently through multiple placements. It is not-defined for the GPU to ever concurrently read and write to the same heap region, since the resource barrier semantics currently don't allow it.

```cpp
// D3D12DDI_RL_PLACED_PHYSICAL_SUBRESOURCE_PITCHED
// Use D3D12DDIARG_BUFFER_PLACEMENT::BaseAddress::UMD
typedef struct D3D12DDIARG_PHYSICAL_SUBRESOURCE_PITCHED_LAYOUT
{
    DXGI_FORMAT Format;
    UINT        PhysicalWidth;  // Block dimensions
    UINT        PhysicalHeight; // Block dimensions
    UINT        PhysicalDepth;  // Block dimensions
    UINT        Pitch;
    UINT        SlicePitch;
} D3D12DDIARG_PHYSICAL_SUBRESOURCE_PITCHED_LAYOUT;
```

Subresource Pitched Layout

Only a single-subresource pitched layout placement on a buffer is supported. The structure covers from a buffer representation to a volume representation.

The `Pitch` field will be aligned according to the caps advertised by the driver. The pitch will be larger than or equal to the physical row size of the resource defined by the resource dimensions. The pitch does not have to be tight, as the application can have more padding between columns, necessary to align the pitch.

The `SlicePitch` must be tight. Therefore, it will be equal to the `Pitch` times `PhysicalHeight` of the resource.

Subresource pitched placement is required to be orthogonal for all formats, except for the YUV and opaque formats. We would like to add support for such formats, and are investigating representing each plane as a subresource index in D3D12. As long as the format table requires resource support or the driver indicates such optional support, subresource pitched placement must be supported.

The `PHYSICAL` structure is useful for operations that deal in physical coordinates, like `CopySubresourceRegion`.

```cpp
typedef struct D3D12DDIARG_PLACED_RESOURCE
{
    D3D12DDI_RESOURCE_LAYOUT Layout; // Cannot be D3D12DDI_RL_UNDEFINED.
    CONST VOID*              pLayout;
} D3D12DDIARG_PLACED_RESOURCE;

typedef VOID ( APIENTRY* PFND3D12DDI_COPYSUBRESOURCEREGION )(
    D3D12DDI_HCOMMANDLIST,
    _In_ CONST D3D12DDIARG_BUFFER_PLACEMENT* pDst,
    D3D12DDIARG_PLACED_RESOURCE DstDesc,
    UINT, UINT, UINT,
    _In_ CONST D3D12DDIARG_BUFFER_PLACEMENT* pSrc,
    D3D12DDIARG_PLACED_RESOURCE SrcDesc,
    _In_opt_ CONST D3D10_DDI_BOX*
    UINT CopyFlags );

typedef struct D3D12DDI_COMMAND_LIST_FUNCS_3D
{
...
    PFND3D12DDI_COPYSUBRESOURCEREGION pfnCopySubresourceRegion;
...
};
```

CopySubresourceRegion

`CopySubresourceRegion` must support multi-dimensional placement in both dynamic and staging buffers. Such placement is supported with the `_PHYSICAL_SUBRESOURCE_PITCHED_LAYOUT`. However, `CopySubresourceRegion` will actually support two layouts. The `_RL_SELECT_` structure is detailed next.

The `DstDesc::Layout` will be either `_RL_PLACED_PHYSICAL_SUBRESOURCE_PITCHED` or `_RL_SELECT_SUBRESOURCE`.

The `SrcDesc::Layout` will be either `_RL_PLACED_PHYSICAL_SUBRESOURCE_PITCHED` or `_RL_SELECT_SUBRESOURCE`.

```cpp
typedef enum D3D12DDI_RESOURCE_LAYOUT
{
    ...
    D3D12DDI_RL_SELECT_SUBRESOURCE = 0x40,
    ...
} D3D12DDI_RESOURCE_LAYOUT;

// D3D12DDI_RL_SELECT_SUBRESOURCE
// Use D3D12DDIARG_BUFFER_PLACEMENT::BaseAddress::UMD
//   D3D10DDI_HRESOURCE denotes resource
//   Offset specifies subresource
```

Subresource CopySubresourceRegion Syntax

The placement DDI also supports some D3D11 syntax by re-using the Resource Layout enum. This design is useful, since the heaps feature will not be fully realized in the short-term. However, the subresource syntax layouts may be deprecated later, if the efforts to parameterize device-dependent layouts are successful.

When this enum is chosen, the `D3D10DDI_HRESOURCE` member of `ARG_BUFFER_PLACEMENT` will be always used to denote the resource handle. The `Offset` associated with it denotes which subresource to use.

#### Support primary creation through the new D3D12 Heap DDIs without existing primary description

The existing `DXGI_DDI_PRIMARY_DESC` is no longer passed to the UMD during heap & resource creation. Instead, two primary flags are told to the user mode driver at two different points in time. These two flags are a resource optimization flag and a heap flag.

The primary resource optimization flag has been in the D3D12 plan for quite a while. It influences the driver's choice of swizzle pattern.

The primary heap flag is added, as both discrete and integrated GPUs must translate the flag to certain DXGK allocation properties. DXGK allocations must be created during heap creation.

There is no resource flag to denote primary. And, the driver still cannot tell if the heap is being shared or not. But, as detailed later, the driver can infer resource properties from the heap flag passed to the driver at creation.

The removal of the primary description enables flexibility for VidPnSourceId. A primary created for a particular adapter LUID may be used on any VidPnSourceId associated with that LUID.

During a primary heap creation, a texture resource will be created along with the heap to conform to the cross-DDI shared resource design. As a reminder, the cross-DDI shared resource design requires the D3D11 driver must open a shared resource of equivalent D3D11 resource properties that the D3D12 driver created. By conforming to the cross-DDI shared resource design, the D3D12 UMD can embed resource properties into its own private data, and the KMD can reasonably still support invocations from DXGK for `DescribeAllocation`.

The KMD should fill out `DXGKARG_DESCRIBEALLOCATION::Rotation` with `D3DDDI_ROTATION_IDENTITY`, when `DescribeAllocation` is called for D3D12-created managed primaries. This mimics what the driver is already doing with `DXGKARG_DESCRIBEALLOCATION::RefreshRate` when supporting IndependentFlip, as the value is essentially unused. The OS goal is to evolve out of relying on the KMD for such information, but that will likely occur in later OS releases.

`AllocateCB` must continue to be invoked within the call to create heap and resources, by the same thread that entered the user mode DDI. The driver must continue to pass `D3DDDI_ALLOCATIONINFO` fields, as it is doing for D3D11 DDIs, such as `Primary` and `Stereo` flags. However, the driver must now pass `D3DDDI_ID_UNINITIALIZED` as the `VidPnSourceId` field for allocations that contain runtime primaries.

During the `AllocateCB` invocation associated with runtime primary creation, the runtime will overwrite each `D3DDDI_ALLOCATIONINFO::VidPnSourceId` field with `D3DDDI_ID_UNINITIALIZED` for all `D3DDDI_ALLOCATIONINFO` structures that have `Flags.Primary` set. This shelters the UMD from the current OS design, which is expected to change.

The driver is encouraged to store a sentinel value to denote D3D12 primaries in its existing `VidPnSourceId` private data. The usage of this is detailed later.

The UMD is allowed to create primaries without being first requested by the D3D runtime, in order to support custom workstation or end-to-end solutions that require such functionality.

#### Support D3D11 CheckDirectFlipSupport

The UMD continues to have an option to reject DirectFlip and force DWM composition during `CheckDirectFlipSupport`. Both the application and DWM backbuffer will be passed into the DDI invocation. The UMD may also coordinate with the KMD to ensure compatibility. Supporting DirectFlip and IndependentFlip for fullscreen D3D12 applications is the prioirity, so please work with Microsoft to ensure it can be enabled for the hardware that supports it. Microsoft is also interested educating the OS about the hardware details that cause the UMD to opt-out of DirectFlip; but Microsoft likely won't be able to immediately react to this information.

To support Direct Flip and Independent Flip, the D3D11 UMD must adjust to lighter weight versions of mode changes to support Direct & Independent Flip on different display formats than DWM is using. The driver must also adjust to supporting all the VidPnSourceIds on the same adapter LUID.

All the display formats supported by flip model can be used by D3D12 applications. So, transitions between all the following display mode formats can occur: `R16G16B16A16_FLOAT`, `B8G8R8A8_UNORM`, `R8G8B8A8_UNORM`, and `R10G10B10A2_UNORM`. This design has already been ongoing with many IHVs for D3D11, and more recently, with DXGK.

#### SubmitCommandCB cannot pass more than 8 handles in WrittenPrimaries

The runtime will track all allocations associated with presentable resources for front-buffer validation and back-buffer synchronization. The runtime passes the allocation handles in the `WrittenPrimaries` field for back-buffer synchronization, on behalf of the driver. Therefore, the driver should not have to pass any handles in this field to support the OS and HLK tests on common configurations. But, exceptions exist, and the implicit LDA plan may make further exceptions here.

The runtime allows the driver to create primaries on its own for custom end-to-end solutions. To be useful, the driver must be able to pass such primaries in the `WrittenPrimaries` field. If the driver passes more than 8, the callback fails.

The driver must call `SubmitCommandCB` during the call to `pfnExecuteCommandLists` from the same thread that entered the DDI. The driver must only pass DXGK context handles that were created during the command queue creation.

The driver also cannot merge command lists, such that more than 8 `WrittenPrimaries` handles would be passed during `SubmitCommandCB`.

#### A single presentable resource must commonly refer to a single DXGK allocation

A single presentable resource must occupy only a single DXGK allocation. The number of allocation handles must be constrained to provide the application with a guaranteed capability in the presence of the previously detailed limitations of the DXGK SubmitCommand method.

Applications are allowed to manipulate up to eight swapchains per command list and command queue, to have some options for rendering into multiple swapchain scenarios and multiple monitor configurations. The DXGK allocation handles are retrieved from the `CheckExistingResourceAllocationInfo` DDI immediately after resource creation, and are immutably associated in the common case. But, the LDA plan is investigating an ability to allow the allocation to change over time.

Only presentable resources require this behavior, but are not denoted with a DDI flag. Ideally, all resources would conform to this restriction. But, only committed resources (where DDI heap and DDI resource are created together) that are Texture2D, have a single mip-level, do not enable MSAA, have the flip model present formats, and have array sizes of 2 or less must immediately follow this restriction.

#### Support new D3D12 UpdateTileMapping semantics

Tiled resources have undergone some minor revisions for D3D12. In D3D11, a tiled resource could only have tiles mapped in from one tile pool at a time. In D3D12, a reserved (tiled) resource can have pages (tiles) mapped in from multiple heaps (tile pools), but heaps are not resizable.

In order to avoid application functional regressions for D3D11 running on D3D12, mapping packed mips must be enabled across multiple heaps and with more than one DDI invocation. The existing DDI semantics are tweaked to enable this.

#### Port DXGI and D3D11 DDIs to D3D12 DDIs

Many existing D3D10 and D3D11 DDIs in the D3D12 tables will be merely renamed as part of officially bringing them to D3D12. The device and resource handles are all renamed.

#### The following DDIs aren't ported

The following DXGI DDIs are not coming forward, and the entire table is deprecated.

- `pfnPresent` & `pfnPresent1`: `pfnPresent` was already ported to D3D12 command lists. The GPU may write to both source and destination parameters when this DDI is invoked.
- `pfnRotateResourceIdentities`: resource identity rotation is no longer supported in D3D12, ignoring the LDA design.
- `pfnBlt` & `pfnBlt1`: `pfnBlt` was already ported to D3D12 command lists.
- `pfnOfferResources` & `pfnReclaimResources`: these were already ported to D3D12.
- `pfnTrimResidencySet`: applications now control residency, not the driver.
- `pfnPresentMultiplaneOverlay` & `pfnPresentMultiplaneOverlay1`: DWM APIs aren't currently needed for D3D12
- `pfnSetDisplayMode`: the runtime uses DirectFlip instead of fullscreen exclusive support, in order to leverage other OS features, like Game-DVR.
- `pfnSetResourcePriority` & `pfnQueryResourceResidency`: These are not necessary. The application responsibility is to stay under-budget, while these DDIs pertain to what DXGK does when applications are over-budget. `QueryResourceResidency` is intentionally not exposed, as applications must never depend on where DXGK locates something due to memory pressure.
- `pfnCheckPresentDurationSupport`: Media & DWM have not yet come to D3D12.
- `pfnCheckMultiplaneOverlayColorSpaceSupport`: Multiple plane information is of no use to non-DWM applications, since they can't reasonably control their usage.
- `pfnGetMultiplaneOverlayCaps` & `pfnGetMultiplaneOverlayGroupCaps`: Multiple plane information is of no use to non-DWM applications, since they can't reasonably control their usage.
- `pfnGetGammaCaps`: The capabilities exposed by this query are not needed by typical game applications.

The following DDIs in existing D3D12 tables are not coming forward:

- `pfnCheckDirectFlipSupport`: The whole D3D12 device must support direct flip, eeven though a driver can satisfy that by having the D3D11 UMD opt-out of direct flip within the DWM process.
- `pfnCalcPrivateResourceSize`, `pfnCreateResource`, `pfnDestroyResource`, `pfnCalcPrivateOpenedResourceSize`, `pfnOpenResource`, `pfnResourceMap`, and `pfnResourceUnmap`: D3D12 Resource Heaps are finished. And, `pfnHeapMap` and `pfnHeapUnmap` still exist.
- `pfnCopySubresourceRegion`: `pfnCopyBufferRegion` and `pfnCopyTextureRegion` replace this.
- `pfnMakeResident` and `pfnEvict` on the CommandQueue are replaced by the DDIs on the device.

#### Resident Object Destruction Requirements

<!-- Supersession: the May 2015 revision supersedes the March 2015 Resource Destruction Requirements with this Resident Object Destruction form (adds AssumeNotInUse and SynchronousDestroy flag requirements for DeallocateCB) -->

The driver must set the `AssumeNotInUse` and `SynchronousDestroy` flags when calling `DeallocateCB` for any DXGK allocations associated with the DDI handles that support residency operations. Heaps and resources are the DDI handle types most commonly associated with residency operations.

The driver should be able to set these flags for all DXGK allocations; but it's possible a few internal UMD allocations may still require different flag settings.

The application is responsible to synchronize the CPU and GPU for many aspects of D3D12: cpu-manipulation of persistently mapped resources, residency management, and all residency object destruction. These flags will destroy resident objects in the most efficient way on D3D12.

The application expects the residency budget to be immediately affected by the destruction of heaps & resources, and keeps tighter control of CPU work with these flags always set. If the flags are not used, a two-second compute task can cause large heap destructions to be wastefully deferred when that compute task is known to not use those heaps. And, DXGK asynchronous processing for deallocation can cause glitches on the render thread.

#### CPU access interactions with resource barrier

<!-- Supersession: the May 2015 revision supersedes the March 2015 CPU Access Interactions with Resource Barrier placeholder with this concrete COMMON-state requirement for CPU access to textures, plus the promotion exemption -->

CPU accessible *textures* must be in the `D3D12DDI_RESOURCE_STATE_COMMON` state in order to be accessed for read or write from the CPU.

A resource in the COMMON state can be filled by the CPU but would then have to transition to `PIXEL_SHADER_RESOURCE` *e.g.* before being read by the GPU. Note that the barrier from COMMON to `PIXEL_SHADER_RESOURCE` can be skipped using promotion (see the *Command List API/DDI* spec.) Note that this does not apply to *buffers* which can be accessed by the CPU and the GPU simultaneously regardless of the barrier state.

#### Restrictions on initial states.

The special initial state `D3D12_RESOURCE_USAGE_INITIAL` is removed, but each resource is still created with a designated initial state. The following table shows which of the resource flags are allowed for initial states. The COPY flags (`COPY_DEST` and `COPY_SOURCE`) used as initial states represent states in the 3D/Compute type class.

To use a resource initially on a Copy queue it should start in the COMMON state. The COMMON state can be used for all usages on a Copy queue using the implicit state transitions previously mentioned.

| State flag | Initializable | Promotable |
| --- | --- | --- |
| `VERTEX_AND_CONSTANT_BUFFER` |  |  |
| `INDEX_BUFFER` |  |  |
| `RENDER_TARGET` |  |  |
| `UNORDERED_ACCESS` |  |  |
| `DEPTH_WRITE` |  |  |
| `DEPTH_READ` |  |  |
| `NON_PIXEL_SHADER_RESOURCE` |  |  |
| `PIXEL_SHADER_RESOURCE` |  |  |
| `STREAM_OUT` |  |  |
| `INDIRECT_ARGUMENT` |  |  |
| `COPY_DEST` |  |  |
| `COPY_SOURCE` |  |  |
| `RESOLVE_DEST` |  |  |
| `RESOLVE_SOURCE` |  |  |

#### Report the GPU Max Per-Resource VA caps

The driver must report the GPU's maximum per-resource VA capabilities, in order to enable application litmus tests for VA-related feature feasibility. The driver does not need to report per-process metrics, since the runtime gets those from DXGK.

It is known that odd cases exist, where different VA ranges could be used based on certain resource properties. Thus, different VA capabilities actually apply to different resource types. But, the driver should report the constraint that applies most commonly across all resource types.

Each successive hardware revision should strive to use the same VA mapping techniques across as many resources as possible, increasing memory design orthogonality and simplifying the drivers.

An IHV bootstrap test has been added to `d3d12test` in order to ensure reasonable GPU VA numbers are being reported.

```cpp
typedef enum D3D10_2DDICAPS_TYPE
{
    ...
    D3DWDDM2_0DDICAPS_GPUVA_CAPS,
    ...
} D3D10_2DDICAPS_TYPE;


// D3D12DDICAPS_TYPE_GPUVA_CAPS
    // pInfo = NULL
    // pData = D3DWDDM2_0DDI_GPUVA_CAPS_DATA*
    // DataSize = sizeof(D3DWDDM2_0DDI_GPUVA_CAPS_DATA)
typedef struct D3DWDDM2_0DDI_GPUVA_CAPS_DATA
{
    UINT MaxGPUVirtualAddressBitsPerResource;
} D3DWDDM2_0DDI_GPUVA_CAPS_DATA;

typedef enum D3D12DDICAPS_TYPE
{
    ...
    D3D12DDICAPS_TYPE_GPUVA_CAPS
    ...
} D3D12DDICAPS_TYPE;

// D3D12DDICAPS_TYPE_GPUVA_CAPS
    // *pInfo == UINT : NodeOrdinal
    // pData = D3D12DDI_GPUVA_CAPS_0004*
    // DataSize = sizeof(D3D12DDI_GPUVA_CAPS_0004)
typedef struct D3D12DDI_GPUVA_CAPS_0004
{
    UINT MaxGPUVirtualAddressBitsPerResource;
} D3D12DDI_GPUVA_CAPS_0004;
```

<!-- Net-new: D3D10_2DDICAPS_TYPE gains D3DWDDM2_0DDICAPS_GPUVA_CAPS; D3DWDDM2_0DDI_GPUVA_CAPS_DATA, D3D12DDICAPS_TYPE_GPUVA_CAPS, and D3D12DDI_GPUVA_CAPS_0004 added in May 2015 -->

The driver must tell the runtime the maximum amount of bits that can be supported for tiled resources in D3D11 and reserved resources in D3D12. Applications use this value as a litmus test for whether their application can use tiled resources in the way they expect. Some applications may be interested in using tiled resources, even when the number of bits is near 31. But, applications will likely need to have a general ballpark figure to reasonably target GPU capabilities.

The value returned by the driver is standalone and is not required to be either greater or less than values passed to DXGK for per-process capabilities.

<!-- Supersession: a later standalone "pfnGetGammaCaps" sub-section dropped — already listed in the deprecated DXGI DDI bullets -->

### Shared-resource synchronization and concurrent access

<!-- Merge: synchronization/well-defined-writes (originally March 2015) co-located with the simultaneous-access and read-only-shared-access sub-sections (originally May 2015) -->

#### Synchronization and well-defined resource GPU writes

The runtime will use the typical GPU and CPU synchronization techniques to synchronize application rendering with DWM composition and scan-out. The runtime will prefer to use techniques available to all applications, when possible, in order to simplify the special cases exposed to the driver. The runtime relies on a tight specification for command list operations to detect GPU write-operations to back-buffer resources, the tight specification for memory coherence on command list execution which enables multi-device resource sharing, and the association between driver allocated DXGK contexts and command queues to achieve proper presentation synchronization. This is similar to how D3D11 presentation works. But, notable exceptions exist, e.g. the Present DDI still exists and an implicit LDA plan in in the works.

The runtime not only does back-buffer synchronization, but enforces applications cannot render to the front-buffer. Like the D3D11 shared resource design relied upon, the driver cannot use the GPU to write to a resource when the DDI operations do allow it. In D3D12, all heaps are implicitly shared, so the driver must extend the tighter D3D11 shared restrictions to include all resources.

The driver should also be aware that a command list may record GPU write operations to a resource which is the current front-buffer. The front-buffer validation and necessary synchronization will be taken on a command queue before the command list is executed on that command queue.

#### Support simultaneous access resources, which allow a single writer in the presence of multiple readers

The resource DDI includes a new flag to denote resources with this special behavior.

```cpp
typedef enum D3D12DDI_RESOURCE_FLAGS_0003
{
    D3D12DDI_RESOURCE_FLAG_0003_NONE                 = 0x0,
    D3D12DDI_RESOURCE_FLAG_0003_RENDER_TARGET        = 0x1,
    D3D12DDI_RESOURCE_FLAG_0003_DEPTH_STENCIL        = 0x2,
    D3D12DDI_RESOURCE_FLAG_0003_CROSS_ADAPTER        = 0x4,
    D3D12DDI_RESOURCE_FLAG_0003_SIMULTANEOUS_ACCESS  = 0x8,
} D3D12DDI_RESOURCE_FLAGS_0003;
DEFINE_ENUM_FLAG_OPERATORS( D3D12DDI_RESOURCE_FLAGS_0003 );
```

<!-- Net-new: D3D12DDI_RESOURCE_FLAGS_0003 added in May 2015 (SIMULTANEOUS_ACCESS = 0x8 is the new bit; RENDER_TARGET, DEPTH_STENCIL, and CROSS_ADAPTER pre-existed) -->

Resources with the `SIMULTANEOUS_ACCESS` flag can be accessed simultaneously by multiple arbitrary queues (possibly cross-process) as long as there is only 1 writer at a time, but there can be multiple readers. The write accesses must be accompanied by the appropriate usage of transition barriers and synchronization techniques before read accesses to the same bytes reliably reflect the write.

The resource transition barrier state for simultaneous access resources must be updated by the application as though each queue was accessing a private copy of the resource. This makes resource state effectively per-queue for resources with this flag.

A bootstrap test is available in the HLK tests to verify correctness of this implementation. The test is named `D3DConf_12_0_Multiengine::SimultaneousAccessResource` and is available as part of `D3D12Conf_12_0_Multiengine.dll`

The D3D11 driver must treat all shared resources as D3D12 `simultaneous_access`. These resources can be opened and used within D3D12, using all the rules associated with D3D12 `simultaneous_access`.

`Cross_adapter` resources share all the same application capabilities that `simultaneous_access` resources have. Note that the capabilities described here likely come with a sacrifice in efficiency, especially for some current GPU designs.

#### Support simultaneous read-only resource access for all resources in the common resource transition barrier state

Once a resource enters the COMMON state it can be read by multiple readers at the same time, including cross-process and using any queues. The most common case of this is presentation where:

- the resource will generally be read as an SRV by the DWM but might also be used as a source to a COPY operation, *while*
- the resource can simultaneously be used as a read-only source by the application in parallel.

This is distinct from resources with the `D3D12DDI_RESOURCE_FLAG_0003_SIMULTANEOUS_ACCESS` flag (defined above) because this is a read-only case rather than a single-writer-multiple-reader case. Supporting simultaneous unsynchronized read-only access should be simpler than the writeable case. An example of problematic behavior would be if the driver attempted to re-compress the resource on a transition from `D3D12DDI_RESOURCE_STATE_COMMON` to `D3D12DDI_RESOURCE_STATE_PIXEL_SHADER_RESOURCE` and did so in a fashion that could affect other unsynchronized readers.

This notion of simultaneous read-only access requires that resource barriers between two read states cannot incur non-atomic GPU writes to memory, after the common state has been entered. This characteristic persists until the resource barrier state transitions into a state that allows GPU-write. Currently, GPU writes can occur, as long as they are atomic and do not affect any other (potentially unsynchronized or cross-process) read access to the resource.

After Windows 10 release, Microsoft will investigate opportunities to tighten up the definition of GPU-write and define it with respect to triggering GPU virtual memory exceptions. Of course, this is only for those GPUs that support virtual page protection.

### Placed resource memory aliasing and initialization

<!-- Merge: placed-resource aliasing rules (originally March 2015) and metadata initialization rules (originally May 2015) co-located here -->

#### Placed Resource Memory Aliasing Requirements

<!-- Supersession: the May 2015 revision supersedes the March 2015 Physical Memory Aliasing Requirements with this Placed Resource Memory Aliasing form (adds resource-equivalence-and-per-tile-inheritance details + transition-state compatibility table) -->

Placed resources inherit the same basic physical memory aliasing rules that tiled resources defined for D3D11; but placed resources enable more data inheritance scenarios, since unhidden compression metadata must be located in the heap, at consistent locations relative to the resource data. First, the pre-existing D3D11 rules are repeated for clarity:

- An aliasing barrier must be issued between the usage of two resources that share the same physical memory. The aliasing barrier does not have to denote the resources involved in such an operation.
- Textures with render-target or depth-stencil flags cannot inherit data through aliasing. After issuing the aliasing barrier, any subresources of such resources must be fully cleared or fully copied-to.

Due to the D3D11 aliasing rules above, textures without render-target or depth-stencil flags can participate in the most data inheritance scenarios. But, again, D3D12 enables more data inheritance with the placed resource design and a more refined representation of the metadata compress and decompress operations in the resource transition barrier evolution.

Placed resources enable the most data inheritance for textures, even with undefined memory layouts and compression metadata. To mimic the capabilities that shared committed resources enable, the application may locate two textures with identical resource properties at the same offset in a shared heap. The entire resource description must be identical, including the optimized clear value and type of resource creation method (placed vs. reserved). But, both resources may have had different initial transition barrier states.

Per-tile inheritance is now possible; but the opportunities are much more limited due to an inability to inherit compression metadata.

To inherit data, both resources must be in a compatible resource transition barrier state:

1. For buffers, simultaneous access textures, and cross-adapter textures, the resource transition state is not important and they are all "compatible".
2. For reserved textures, the resource transition barrier state must be in the common state.
3. For per-tile inheritance through `64KB_UNDEFINED_SWIZZLE` or `64KB_STANDARD_SWIZZLE`, the resource transition barrier state for the tile must be in the common state.
4. For all other textures, where the resource descriptions match exactly, the resource transition barrier state must either
    1. Be in the common state
    2. Be equal when the state has the same GPU-write flag in them

When supporting standard swizzle, buffers and textures may be aliased to the same memory and inherit data between them. The application can manipulate texels from the buffer representation, because the standard swizzle pattern describes how texels are laid out in memory. In other words, the CPU-visible swizzle pattern must also be GPU-visible from buffers, as well.

For D3D12, the synchronization definition of `ExecuteCommandLists` is equivalent to an aliasing barrier. Therefore, applications may either insert an aliasing barrier between reusing physical memory, or ensure the two aliased usages of physical memory occurs in two separate calls to `ExecuteCommandLists`.

#### Metadata initialization and resource invalidation for placed textures

When data inheritance through physical memory aliasing is not being leveraged, the D3D11 tiled resource rules are still in effect. Renderable textures (with the `D3D12DDI_RESOURCE_FLAG_RENDER_TARGET` or `D3D12DDI_RESOURCE_FLAG_DEPTH_STENCIL` flags) can have metadata that requires initialization into a known-good state. When the application is not using data inheritance on shared heaps, these texture subresources must be initialized with a full clear or copy operation before they can be used for any other operations. However, further refinements exist in D3D12.

As an example, consider two placed resources as equivalent if the resources are at the same heap offset and have identical resource properties. Equivalent placed resources allow inheritance of the compression data when on a shared heap. Conversely, placed resource ***A*** is invalidated (and requires re-initialization) when a write occurs to a resource ***B*** that is *non-equivalent* and *overlaps* with ***A***. This example is valid, when **A** and **B** are textures with undefined layouts.

However, resources with more transparent layouts have more refined rules regarding initialization and invalidation.

1. Rather than requiring a full-resource clear or copy, resources with `64KB_UNDEFINED_SWIZZLE` and `64KB_STANDARD_SWIZZLE` may initialized each tile, individually, using a single copy or clear operation that covers the tile.

2. Rather than experiencing an invalidation to the entire resource, resources with transparent layouts experience invalidations at 64KB tile granularities within their "resource data" regions. Transparent layouts include `64KB_UNDEFINED_SWIZZLE`, `64KB_STANDARD_SWIZZLE`, and `ROW_MAJOR`. Invalidations to a texture's metadata region, though, continues to invalidate the whole texture.

Example: An application can create a 2D render target texture array with 2 array slices, a single mip level, and the `64KB_UNDEFINED_SWIZZLE` layout. Assume the application understands each array slice occupies 100 64KB tiles. The application can forgo using array slice 0, and re-use that memory for either a ~6MB buffer, a ~6MB texture with undefined layout, etc. Going further, assume the application knew it no longer required the first tile of array slice 1. Then, the application could also locate a 64KB buffer there until rendering would again require the first tile of array slice 1. The application would have to do a full tile clear or copy in order to re-use the first tile with the texture array again.

Committed resources do not require any special initialization or handling.

D3D12 allows metadata on all textures, not just those with `RENDER_TARGET` or `DEPTH_STENCIL` flags. However, any metadata on non-RT/DS textures must not require full subresource copies for initialization. Instead, the metadata must be robust enough to honor the app initializing each texel, discretely, from all possible initial physical memory values.

---

## Parameterized Swizzle

### About

Parameterized swizzle is being revised while hardware is still evolving to support standard swizzle efficiently. Some resources types weren't accurately understood, and some patterns are less efficient than expected. The end result is inefficiency in either bandwidth of texture access, as parameterized-swizzle patterns are anticipated to be used by graphics debugging and perf tools very soon.

**Drivers must not choose swizzle patterns based on whether a resource will be located on CPU-visible heaps or not. The goal of parameterized swizzle is to describe the pattern observed by the CPU, regardless of how the CPU comes by the data. Video memory can be made visible to the CPU through paging or similar raw-copy operations. The only exceptions are for adapters that must support heap tier 1, and adapters which cannot decompress textures in-place.**

### Parameterized swizzle pattern description updates

```cpp
typedef enum D3D12DDICAPS_TYPE
{
    ...
    D3D12DDICAPS_TYPE_TEXTURE_LAYOUT1
    ...
} D3D12DDICAPS_TYPE;

// D3D12DDICAPS_TYPE_TEXTURE_LAYOUT
    // *pInfo == UINT : (0 through DeviceDependentLayoutCount - 1)
    // pData = D3D12DDI_SWIZZLE_PATTERN*
    // DataSize = sizeof(D3D12DDI_SWIZZLE_PATTERN) * 2

// D3D12DDICAPS_TYPE_TEXTURE_LAYOUT1
    // *pInfo == UINT : (0 through DeviceDependentLayoutCount - 1)
    // pData = D3D12DDI_SWIZZLE_PATTERN*
    // DataSize = sizeof(D3D12DDI_SWIZZLE_PATTERN) * 6

...

typedef struct D3D12DDI_SWIZZLE_PATTERN_DESC
{
    D3D12DDI_SWIZZLE_BIT_ENTRY InterleavePatternSourceBits[ 32 ];
    D3D12DDI_SWIZZLE_BIT_ENTRY InterleavePatternXORSourceBits[ 32 ];
    D3D12DDI_SWIZZLE_BIT_ENTRY InterleavePatternXOR2SourceBits[ 32 ];
    UINT InterleavePatternXOR3;
    UINT Flags;
} D3D12DDI_SWIZZLE_PATTERN_DESC;

typedef struct D3D12DDI_RESOURCE_ALLOCATION_INFO
{
    UINT64 ResourceDataSize;
    UINT64 AdditionalDataHeaderSize;
    UINT64 AdditionalDataSize;
    UINT64 ResourceDataAlignment;
    union
    {
        UINT64 AdditionalDataHeaderAlignment;
        struct
        {
            UINT32 AdditionalDataHeaderAlignment1;
            UINT8 AdditionalMipLevelSwizzleTransitionsArray[4];
        };
    };
    UINT64 AdditionalDataAlignment;
    D3D12DDI_TEXTURE_LAYOUT Layout;
    UINT8 MipLevelSwizzleTransition;
} D3D12DDI_RESOURCE_ALLOCATION_INFO;
```

<!-- Net-new: D3D12DDICAPS_TYPE_TEXTURE_LAYOUT1 cap added in May 2015 (allows up to 6 swizzle patterns per texture; older TEXTURE_LAYOUT cap kept for backward compatibility) -->
<!-- Supersession: D3D12DDI_SWIZZLE_PATTERN_DESC introduced in March 2015 (with InterleavePatternXOR2SourceBits, InterleavePatternXOR3, StackDepthSlices); re-declared in May 2015 (StackDepthSlices field replaced by Flags field) -->

These updates are also found in equivalent D3D11 DDIs:

The new `Flags` field controls how the pattern is applied to 3D textures. If set to `D3D12DDI_SWIZZLE_PATTERN_FLAGS_STACK_DEPTH_SLICES`, depth slices are treated as being stacked vertically prior to swizzling, with each slice being separated by a number of rows specified by `DepthStride` from the `GetResourceLayout` DDI. In this case, the interleave patterns must not contain any bits from the Z dimension, and the pre-swizzle Z offset must be zero.

`InterleavePatternXOR3` contains a constant value XOR'd to the destination address. This was introduced in the DDI build version of the related name: `D3D12DDI_BUILD_VERSION_PARAMETERIZED_SWIZZLE_XOR3`.

The maximum swizzle patterns supported per texture is raised to 6 and the mip-level transitions are similarly raised to 5. This is achieved in the DDI via a non-breaking mechanism, but not supported on DDI versions before `D3D12DDI_BUILD_VERSION_PARAMETERIZED_SWIZZLE_XOR3`.

**Non-breaking DDI addition for 6 swizzle pattern per texture layout capabilities**

A new cap is introduced: `D3D12DDICAPS_TYPE_TEXTURE_LAYOUT1`. This cap is similar to `D3D12DDICAPS_TYPE_TEXTURE_LAYOUT`, but it denotes whether the driver needs 6 swizzle patterns per texture. Drivers which do not need to report more than 2 swizzle patterns per texture should not recognize the introduction of this cap, and will return a failure whenever `GetCaps` is called for it.

In order to report more than 6 swizzle patterns, drivers must succeed the new cap request. The runtime and driver switch modes when the new cap request is succeeded. When the driver succeeds the new cap, the driver must fill out 6 swizzle patterns associated with each texture layout, and fill out 5 mip level transitions associated with each resource.

If the driver does not receive the new cap request, it must take care to operate via the old runtime design. For those drivers that require the new capabilities, it is preferred to lie about the parameterized swizzle patterns being used. Parameterized swizzle is not a commonly used feature yet, but it would be worse to corrupt the runtime memory provided through older DDI semantics or resort to texture layouts that significantly impair bandwidth.

**Semantics of DDI capable of 6 swizzle patterns per texture layout**

The existing semantics apply to swizzle patterns associated with texture layouts. The driver must pass back the `D3D12DDI_SWIZZLE_PATTERN`s in decreasing mip-detail order for the new `TEXTURE_LAYOUT` `GetCaps` call.

With respect to mip level swizzle transitions, the driver must now pass back an array of `MipLevelSwizzleTransition` per-resource. The indices in this array must be in non-decreasing order. The indices still do not need to indirectly reference every swizzle pattern associated with the resource's texture layout.

Examples:

Suppose a resource is using a texture layout that supports two swizzle patterns, and only has three mip levels. If the most-detailed mip uses the first swizzle pattern associated with the texture layout, and the next less-detailed mip level uses the second swizzle pattern, the driver should set 1 for `MipLevelSwizzleTransition[ 0 ]` and 2 or greater for `MipLevelSwizzleTransition[ 1 ]`.

The driver can use both repeating values and out-of-range values in the `MipLevelSwizzleTransition` array. This is assumed to be quite useful for:

1. When the resource is too small to leverage swizzle patterns meant for larger mip level dimensions. The driver is expected to fill out the first few array entries with 0. The runtime will accumulate multiple transitions with the same value.

2. When a texture has certain characteristics that could turn off transitions across the board, `UINT8_MAX` can set in `MipLevelSwizzleTransition[ 0 ]` to achieve the same effect. Only the swizzle pattern 0 associated with the texture layout will be used.

### Parameterized Swizzle R1 Overview

More sequential XORs are being added.

Planes can now have different swizzle patterns.

A new mode is available to more flexibly associate swizzle patterns with subresources. Instead of the swizzle patterns being arranged in an order to enable transition optimizations, the 18 swizzle patterns associated with a texture layout can now be indexed arbitrarily along the mip level and plane subresource axis.

A longer-term goal for hardware designs is to avoid leveraging per-subresource properties, like `PreSwizzleOffsets` and indexable swizzle patterns. In order to enable texture debugging at any arbitrary point in time, the software components want to archive only a small amount of per-resource information. Looping over subresources or storing per-subresource information is less ideal.

#### Texture Layouts Caps DDI

```cpp
typedef enum D3D12DDICAPS_TYPE
{
    ...
    D3D12DDICAPS_TYPE_0022_TEXTURE_LAYOUT,
    ...
} D3D12DDICAPS_TYPE;

// D3D12DDICAPS_TYPE_0022_TEXTURE_LAYOUT
    // *pInfo = NULL
    // pData = D3D12DDI_TEXTURE_LAYOUT_CAPS_0026
    // DataSize = sizeof(D3D12DDI_TEXTURE_LAYOUT_CAPS_0026)

typedef struct D3D12DDI_TEXTURE_LAYOUT_CAPS_0026
{
    UINT DeviceDependentLayoutCount; // D3D12DDI_TEXTURE_LAYOUT
    UINT DeviceDependentSwizzleCount; // D3D12DDI_SWIZZLE_PATTERN
    BOOL Supports64KStandardSwizzle;
    BOOL SupportsRowMajorTexture;
    BOOL IndexableSwizzlePatterns;
} D3D12DDI_TEXTURE_LAYOUT_CAPS_0026;

typedef enum D3D12DDI_TEXTURE_LAYOUT
{
    D3D12DDI_TL_UNDEFINED = 0,
    D3D12DDI_TL_ROW_MAJOR = 1,
    D3D12DDI_TL_64KB_TILE_UNDEFINED_SWIZZLE = 2,
    D3D12DDI_TL_64KB_TILE_STANDARD_SWIZZLE = 3,
    D3D12DDI_TL_DEVICE_DEPENDENT_SWIZZLE_0 = 0x100,
} D3D12DDI_TEXTURE_LAYOUT;

typedef enum D3D12DDI_SWIZZLE_PATTERN
{
    D3D12DDI_SP_ROW_MAJOR = 0,
    D3D12DDI_SP_64KB_STANDARD_SWIZZLE = 3,
    D3D12DDI_SP_DEVICE_DEPENDENT_0 = 0x100,
} D3D12DDI_SWIZZLE_PATTERN;
```

During the caps request for `0022_TEXTURE_LAYOUT` with NULL `pInfo`, the driver must set `DeviceDependentLayoutCount` and `DeviceDependentSwizzleCount` to the number of device-dependent layouts and swizzle patterns supported by the adapter. This information enables the runtime to build acceleration data structures for each parameterized swizzle pattern. The driver must not return duplicate layout or swizzle patterns, as they reduce the efficiency of acceleration data structures.

The driver must also indicate whether the adapter supports standard swizzle. When the driver indicates standard swizzle is supported, the driver must also correctly create textures in the standard swizzle pattern.

##### Texture Layout Swizzle Patterns

A texture layout may support up to 18 different swizzle patterns. Texture layout and swizzle patterns are synonymous on GPU designs that only support a single swizzle pattern across the whole texture.

The driver has a choice how these swizzle patterns relate to texture layouts, and denotes the choice through `D3D12DDI_TEXTURE_LAYOUT_CAPS_0026::IndexableSwizzlePatterns`. When `IndexableSwizzlePatterns` is TRUE, the driver may flexibly choose any of the 18 swizzle patterns for each subresource along either the mip and plane axis. The per-subresource `PreSwizzleOffsets` cannot be used by the swizzle pattern, as they are repurposed to specify which swizzle pattern to use.

When `IndexableSwizzlePatterns` is FALSE, the 18 swizzle patterns must be arranged in a particular order, optimized for swizzle pattern transitions. In particular, a texture can only use 6 swizzle patterns within a particular plane-slice, and still not arbitrarily. The swizzle patterns transition on particular mip level slices and particular plane slices.

See later sections for more details.

#### Texture Layout Caps DDI

```cpp
typedef enum D3D12DDICAPS_TYPE
{
    ...
    D3D12DDICAPS_TYPE_0022_TEXTURE_LAYOUT
    ...
} D3D12DDICAPS_TYPE;

// D3D12DDICAPS_TYPE_0022_TEXTURE_LAYOUT
    // *pInfo == UINT : (0 through DeviceDependentLayoutCount - 1)
    // pData = D3D12DDI_SWIZZLE_PATTERN*
    // DataSize = (sizeof(D3D12DDI_SWIZZLE_PATTERN) * 6) * 3
```

During the caps request for `0022_TEXTURE_LAYOUT` with non-NULL `pInfo`, the driver must pass back 18 swizzle pattern id values for a particular texture layout id. `pInfo` points to a UINT that contains the 0-based device-dependent texture layout id being queried.

When `IndexableSwizzlePatterns` is TRUE, the driver can pass back an arbitrary collection of 18 swizzle patterns. The driver specifies which swizzle pattern applies to which subresource by passing an index through `D3D12DDI_SUBRESOURCE_INFO::ColumnPreSwizzleOffset` when `CheckSubresourceInfo` is called for a particular subresource. As an example, the swizzle pattern id in `pData[3]` would be used when `ColumnPreSwizzleOffset` is set to 3. The `SimpleSwizzle` algorithm will use 0 for `ColumnPreSwizzleOffset`.

When `IndexableSwizzlePatterns` is FALSE, the driver must pass back the `SWIZZLE_PATTERN` enum values in decreasing mip-detail order and increasing plane slice order. The 3-by-6 array is in plane-major order, where all 6 pattern values for the same plane slice come before all patterns for the next plane slice.

See comments in `GetResourceLayout` describing subresource indices at which the swizzle patterns transitions.

#### Swizzle Pattern Caps DDI

```cpp
typedef enum D3D12DDICAPS_TYPE
{
    ...
    D3D12DDICAPS_TYPE_0022_SWIZZLE_PATTERN,
    ...
} D3D12DDICAPS_TYPE;

// D3D12DDICAPS_TYPE_0022_SWIZZLE_PATTERN
    // *pInfo == UINT : (0 through DeviceDependentSwizzleCount - 1)
    // pData = D3D12DDI_SWIZZLE_PATTERN_DESC_0022*
    // DataSize = sizeof(D3D12DDI_SWIZZLE_PATTERN_DESC_0022)

typedef struct D3D12DDI_SWIZZLE_BIT_ENTRY
{
    UINT8 Valid : 1;
    UINT8 ChannelIndex : 2; // 0 for X, 1 for Y, 2 for Z, 3 for SS
    UINT8 SourceBitIndex : 5; // Index of source bit address
} D3D12DDI_SWIZZLE_BIT_ENTRY;

typedef enum D3D12DDI_SWIZZLE_PATTERN_FLAGS
{
    D3D12DDI_SWIZZLE_PATTERN_FLAGS_NONE = 0,
    D3D12DDI_SWIZZLE_PATTERN_FLAGS_STACK_DEPTH_SLICES = 0x1,
} D3D12DDI_SWIZZLE_PATTERN_FLAGS;

typedef struct D3D12DDI_SWIZZLE_PATTERN_DESC_0022
{
    D3D12DDI_SWIZZLE_BIT_ENTRY InterleavePatternSourceBits[ 32 ];
    D3D12DDI_SWIZZLE_BIT_ENTRY InterleavePatternXORSourceBits[ 32 ];
    D3D12DDI_SWIZZLE_BIT_ENTRY InterleavePatternXOR2SourceBits[ 32 ];
    D3D12DDI_SWIZZLE_BIT_ENTRY InterleavePatternXOR3SourceBits[ 32 ];
    D3D12DDI_SWIZZLE_BIT_ENTRY InterleavePatternXOR4SourceBits[ 32 ];
    D3D12DDI_SWIZZLE_BIT_ENTRY PostambleXORSourceBits[ 32 ];
    D3D12DDI_SWIZZLE_BIT_ENTRY PostambleXOR2SourceBits[ 32 ];
    UINT PostambleXORImmediate;
    UINT Flags;
} D3D12DDI_SWIZZLE_PATTERN_DESC_0022;
```

During the caps request for `0022_SWIZZLE_PATTERN`, the driver must describe each device-dependent swizzle pattern. This description is commonly referred to as a parameterized swizzle description.

`pInfo` points to a UINT value, which is the 0-based device-dependent swizzle pattern id.

Swizzle patterns can be used with multiple texel bit depths. As the texel bit depth increases, the least significant address bits are reallocated from addressing texel location to addressing bytes within a texel. The swizzle no longer applies when addressing bytes within a texel. Texel formats are already well-defined as to how they are laid out in memory.

Below is a demonstration representing the 2D non-MSAA standard swizzle layout in parameterized form:

```cpp
// 16bpp XYXY XYXY XYYY XXX-
// 32bpp XYXY XYXY XYYY XX--

D3D12DDI_SWIZZLE_PATTERN_0022 StandardSwizzle_2d_NonMSAA_16_32bpp =
{
  {
    {1,0,0},{1,0,1},{1,0,2},{1,0,3}, {1,1,0},{1,1,1},{1,1,2},{1,0,4},
    {1,1,3},{1,0,5},{1,1,4},{1,0,6}, {1,1,5},{1,0,7},{1,1,6},{1,0,8},
    {0,0,0}, ... ,{0,0,0} // Remaining unused
  },
  { {0,0,0}, ... ,{0,0,0} }, // All unused
  { {0,0,0}, ... ,{0,0,0} }, // All unused
  { {0,0,0}, ... ,{0,0,0} }, // All unused
  { {0,0,0}, ... ,{0,0,0} }, // All unused
  { {0,0,0}, ... ,{0,0,0} }, // All unused
  { {0,0,0}, ... ,{0,0,0} }, // All unused
  0,
  FALSE
};
```

Note that a given bit in the interleave pattern may map to a source bit, and also up to four bits which are sequentially XOR'd to it. The valid bit within both values is set to 0 beyond the end of the pattern.

The swizzle pattern is allowed to exhaust above and below 64K. Blocks of the resulting size are laid out in a row-major/ linear fashion. They are adjacent in memory, although a pitch (returned from the `ResourceMap` DDI) determine the offset from one row of tiles to the next row.

The same layout is applied to each mipmap level.  Each mipmap level has a different base pointer, which is added to the swizzled offset.

The `Flags` field controls how the pattern is applied to 3D textures.  If set to `D3D12DDI_SWIZZLE_PATTERN_FLAGS_STACK_DEPTH_SLICES`, depth slices are treated as being stacked vertically prior to swizzling, with each slice being separated by a number of rows specified by `DepthStride` from the `GetResourceLayout` DDI.  In this case, the interleave patterns must not contain any bits from the Z dimension, and the pre-swizzle Z offset must be zero.

The `PostambleXOR`s apply to the address offset calculated from the `InterleavePattern`, `InterleavePatternXOR`s, including tile-row calculations. But, the Postamble XORs apply before the base address is added. See the demonstration for more details.

The following example demonstrates row-major (linear) layout can also be represented in parameterized form. Other DDIs enable the driver to return the stride between each row and depth.

```cpp
// 32bpp ----

D3D12DDI_0022_SWIZZLE_PATTERN RowMajor_2d_NonMSAA_32bpp =
{
  {
    {1,0,1},{1,0,1}
    {0,0,0}, ... ,{0,0,0} // Remaining unused
  },
  { {0,0,0}, ... ,{0,0,0} }, // All unused
  { {0,0,0}, ... ,{0,0,0} }, // All unused
  { {0,0,0}, ... ,{0,0,0} }, // All unused
  { {0,0,0}, ... ,{0,0,0} }, // All unused
  { {0,0,0}, ... ,{0,0,0} }, // All unused
  0,
  FALSE
};
```

The following example demonstrates how a generic swizzle layout may be used to convert from a source to destination offset within a resource.

```cpp
//
// Sample routine to convert a source address to a swizzled address.
// Note that swizzling-copy routines can take advantage of simplifying
// characteristics of typical swizzle patterns to copy blocks of data
// much more efficiently. This routine is intended to demonstrate
// the swizzle layout.
//
UINT CMapDefaultResourceLayoutTest::SimpleSwizzle(
    UINT sourceAddress[3],     // {X Bytes, Y, Z}
    UINT preSwizzleOffsets[3], // {X Bytes, Y, Z}
    UINT stride, // Applied between each horizontal row of blocks
    UINT depthStride,
    __in const D3D12DDI_0022_SWIZZLE_PATTERN &swizzlePattern,
    __in SwizzleInfo &swizzleInfo
    )
{
    // Determine the row-major block index of the source address, and the offset
    // within that block (that must subsequently be swizzled).
    UINT offsetSourceAddress[3];
    UINT offsetsWithinBlocks[3];
    UINT blockIndices[3];

    for (UINT i = 0; i < 3; ++i)
    {
        offsetSourceAddress[i] = sourceAddress[i];
        offsetSourceAddress[i] += preSwizzleOffsets[i];
        blockIndices[i] = offsetSourceAddress[i] / swizzleInfo.elementsPerBlock[i];
        offsetsWithinBlocks[i] = offsetSourceAddress[i] % swizzleInfo.elementsPerBlock[i];
        if (swizzlePattern.StackDepthSlices)
        {
            if (i == 1)
            {
                offsetSourceAddress[i] += depthStride * sourceAddress[2];
            }
            else if (i == 2)
            {
                offsetSourceAddress[i] = 0;
            }
        }
    }

    // Determine the destination offset of the first element in the relevant block
    UINT destBlockOffset =
            swizzleInfo.blockSizeInBytes * blockIndices[0] +
            blockIndices[1] * stride +
            blockIndices[2] * depthStride;

    // Compute the swizzled offset within the block
    UINT swizzledOffsetWithinBlock = 0;
    for (UINT i = 0; i < swizzleInfo.blockBitCount; ++i)
    {
        UINT sourceChannelIndex = swizzlePattern.InterleavePatternSourceBits[i].ChannelIndex;
        UINT sourceBitIndex     = swizzlePattern.InterleavePatternSourceBits[i].SourceBitIndex;
        UINT bit = (offsetSourceAddress[sourceChannelIndex] & (1 << sourceBitIndex)) >>
            sourceBitIndex;

        // Apply XORs if necessary.  Note that XOR bits may come from channel bits that are
        // higher-order than contained within swizzlePattern.InterleavePatternSourceBits.
        if (swizzlePattern.InterleavePatternXORSourceBits[i].Valid)
        {
            UINT xOrChannelIndex =
                swizzlePattern.InterleavePatternXORSourceBits[i].ChannelIndex;
            UINT xOrBitIndex     =
                swizzlePattern.InterleavePatternXORSourceBits[i].SourceBitIndex;
            UINT xOrBit =
                (offsetSourceAddress[xOrChannelIndex] & (1 << xOrBitIndex)) >> xOrBitIndex;

            bit = bit ^ xOrBit;
        }

        if (swizzlePattern.InterleavePatternXOR2SourceBits[i].Valid)
        {
            UINT xOrChannelIndex =
                swizzlePattern.InterleavePatternXOR2SourceBits[i].ChannelIndex;
            UINT xOrBitIndex     =
                swizzlePattern.InterleavePatternXOR2SourceBits[i].SourceBitIndex;
            UINT xOrBit =
                (offsetSourceAddress[xOrChannelIndex] & (1 << xOrBitIndex)) >> xOrBitIndex;

            bit = bit ^ xOrBit;
        }

        if (swizzlePattern.InterleavePatternXOR3SourceBits[i].Valid)
        {
            UINT xOrChannelIndex =
                swizzlePattern.InterleavePatternXOR3SourceBits[i].ChannelIndex;
            UINT xOrBitIndex     =
                swizzlePattern.InterleavePatternXOR3SourceBits[i].SourceBitIndex;
            UINT xOrBit =
                (offsetSourceAddress[xOrChannelIndex] & (1 << xOrBitIndex)) >> xOrBitIndex;

            bit = bit ^ xOrBit;
        }
        if (swizzlePattern.InterleavePatternXOR4SourceBits[i].Valid)
        {
            UINT xOrChannelIndex =
                swizzlePattern.InterleavePatternXOR4SourceBits[i].ChannelIndex;
            UINT xOrBitIndex     =
                swizzlePattern.InterleavePatternXOR4SourceBits[i].SourceBitIndex;
            UINT xOrBit =
                (offsetSourceAddress[xOrChannelIndex] & (1 << xOrBitIndex)) >> xOrBitIndex;

            bit = bit ^ xOrBit;
        }
        swizzledOffsetWithinBlock |= (bit << i);
    }
    swizzledOffsetWithinBlock ^= swizzlePattern.PostambleXORImmediate;
    UINT TotalOffset = destBlockOffset + swizzledOffsetWithinBlock;
    for (UINT sourceBitIndex = 8; sourceBitIndex < 24; ++sourceBitIndex)
    {
        UINT bit = (TotalOffset  >> sourceBitIndex) & 1;
        if (swizzlePattern.PostambleXORSourceBits[sourceBitIndex].Valid)
        {
            UINT xOrChannelIndex =
                swizzlePattern.PostambleXORSourceBits[sourceBitIndex].ChannelIndex;
            UINT xOrBitIndex     =
                swizzlePattern.PostambleXORSourceBits[sourceBitIndex].SourceBitIndex;
            UINT xOrBit =
                (offsetSourceAddress[xOrChannelIndex] & (1 << xOrBitIndex)) >> xOrBitIndex;

            bit = bit ^ xOrBit;
        }

        if (swizzlePattern.PostambleXOR2SourceBits[sourceBitIndex].Valid)
        {
            UINT xOrChannelIndex =
                swizzlePattern.PostambleXOR2SourceBits[sourceBitIndex].ChannelIndex;
            UINT xOrBitIndex     =
                swizzlePattern.PostambleXOR2SourceBits[sourceBitIndex].SourceBitIndex;
            UINT xOrBit =
                (offsetSourceAddress[xOrChannelIndex] & (1 << xOrBitIndex)) >> xOrBitIndex;

            bit = bit ^ xOrBit;
        }
        TotalOffset  &= ~(1 << sourceBitIndex);
        TotalOffset  |= (bit << sourceBitIndex);
    }
    return TotalOffset;
}
```

#### CheckResourceAllocationInfo and CheckExistingResourceAllocationInfo DDIs

```cpp
typedef struct D3D12DDI_RESOURCE_ALLOCATION_INFO_0022
{
    UINT64 ResourceDataSize;
    UINT64 AdditionalDataHeaderSize;
    UINT64 AdditionalDataSize;
    UINT32 ResourceDataAlignment;
    UINT32 AdditionalDataHeaderAlignment;
    UINT32 AdditionalDataAlignment;
    D3D12DDI_TEXTURE_LAYOUT Layout;
    UINT8 MipLevelSwizzleTransition[5];
    UINT8 PlaneSliceSwizzleTransition[2];
} D3D12DDI_RESOURCE_ALLOCATION_INFO_0022;

typedef VOID ( APIENTRY* PFND3D12DDI_CHECKRESOURCEALLOCATIONINFO_0022 )(
    D3D12DDI_HDEVICE,
    _In_ CONST D3D12DDIARG_CREATERESOURCE_0003*,
    D3D12DDI_RESOURCE_OPTIMIZATION_FLAGS,
    UINT32 AlignmentRestriction,
    UINT VisibleNodeMask,
    _Out_ D3D12DDI_RESOURCE_ALLOCATION_INFO_0022* pInfo );

typedef VOID
  ( APIENTRY* PFND3D12DDI_CHECKEXISTINGRESOURCEALLOCATIONINFO_0022 )(
    D3D10DDI_HDEVICE,
    D3D10DDI_HRESOURCE,
    _Out_ D3D12DDI_RESOURCE_ALLOCATION_INFO_0022* pInfo,
    _Out_ D3DKMT_HANDLE* phAllocation );
```

Creation of a resource still goes through two steps in D3D12: size estimation & then actual creation. These steps are most obviously needed for textures, but buffers must be supported for orthogonality.

1. First, the sizes and alignments of the resource data, additional data header, and additional data is determined along with the texture layout, using `CheckResourceAllocationInfo`. When the resource description is passed into `CheckResourceAllocationInfo`, the `Layout` of the resource description may be set to `_UNDEFINED`, allowing the driver to choose any texture layout. When the `Layout` of the resource description is `STANDARD_SWIZZLE` or `ROW_MAJOR`, the driver must return out the corresponding `STANDARD_SWIZZLE` or `ROW_MAJOR` value as its "choice".
2. Second, the resource is created using the properties derived from the previous step. During resource creation, the `Layout` will never be set to `_UNDEFINED`, since the driver will have returned a resolved texture layout. When given the option, the driver will typically have returned a device-dependent texture layout id. So, that is what is commonly passed into resource creation.

While the driver is reporting the texture layout, the `MipLevelSwizzleTransition` and `PlaneSliceSwizzleTransition` arrays must be reported as well. When `IndexableSwizzlePatterns` is TRUE, these two transition arrays are unused; but the driver is encouraged to fill them out with `UINT8_MAX`.

When `IndexableSwizzlePatterns` is FALSE, the indices in each array must be in non-decreasing order. The indices do not need to indirectly reference every swizzle pattern associated with the resource's texture layout.

Examples when `IndexableSwizzlePatterns` is FALSE:

Suppose a resource is using a texture layout that supports two swizzle patterns, and only has three mip levels. If the most-detailed mip uses the first swizzle pattern associated with the texture layout, and the next less-detailed mip level uses the second swizzle pattern, the driver should set 1 for `MipLevelSwizzleTransition[ 0 ]` and 2 or greater for `MipLevelSwizzleTransition[ 1 ]`.

The driver can use both repeating values and out-of-range values for both arrays. This is assumed to be quite useful for:

1)	When the resource is too small to leverage swizzle patterns meant for larger mip level dimensions. The driver is expected to fill out the first few array entries with 0. The runtime will accumulate multiple transitions with the same value.

2)	When a texture has certain characteristics that could turn off transitions across the board, `UINT8_MAX` can be set in `MipLevelSwizzleTransition[ 0 ]` to achieve the same effect. Only the swizzle pattern 0 associated with the texture layout will be used.

Additionally, D3D12 no longer bundles the `phAllocation` with `CheckExistingResourceAllocationInfo`. That `phAllocation` is now snooped from within `AllocateCb`. That handle is used with CPU-accessible and presentable heaps. The first `HALLOCATION` in the array of `D3D12DDI_ALLOCATIONINFO` will be used instead, avoiding the need to call `CheckExistingResourceAllocationInfo` for many cases.

#### D3D11 DDI Support

All the parameterized swizzle DDIs in D3D11 will be changed to keep capabilities equivalent between D3D versions:

##### Caps

```cpp
typedef enum D3D10_2DDICAPS_TYPE
{
...
    D3DWDDM2_2DDICAPS_TEXTURE_LAYOUT = 156,
    D3DWDDM2_2DDICAPS_SWIZZLE_PATTERN = 157,
...
} D3D10_2DDICAPS_TYPE;

//  D3DWDDM2_2DDICAPS_TEXTURE_LAYOUT
    // *pInfo = NULL
    // pData =  D3DWDDM2_2DDI_TEXTURE_LAYOUT_CAPS*
    // DataSize = sizeof( D3DWDDM2_2DDI_TEXTURE_LAYOUT_CAPS)

typedef struct D3DWDDM2_2DDI_TEXTURE_LAYOUT_CAPS
{
    UINT DeviceDependentLayoutCount; //  D3DWDDM2_0DDI_TEXTURE_LAYOUT
    UINT DeviceDependentSwizzleCount; //  D3DWDDM2_0DDI_SWIZZLE_PATTERN
    BOOL Supports64KStandardSwizzle;
    BOOL IndexableSwizzlePatterns;
} D3DWDDM2_2DDI_TEXTURE_LAYOUT_CAPS;

//  D3DWDDM2_2DDICAPS_TEXTURE_LAYOUT
    // *pInfo == UINT : (0 through DeviceDependentLayoutCount - 1)
    // pData =  D3DWDDM2_0DDI_SWIZZLE_PATTERN*
    // DataSize = (6 * sizeof(D3DWDDM2_0DDI_SWIZZLE_PATTERN)) * 3

//  D3DWDDM2_2DDICAPS_SWIZZLE_PATTERN
    // *pInfo == UINT : (0 through DeviceDependentSwizzleCount - 1)
    // pData =  D3DWDDM2_2DDI_SWIZZLE_PATTERN_DESC*
    // DataSize = sizeof( D3DWDDM2_2DDI_SWIZZLE_PATTERN_DESC)

typedef enum D3DWDDM2_0DDI_SWIZZLE_PATTERN_FLAGS
{
    D3DWDDM2_0DDI_SWIZZLE_PATTERN_FLAGS_NONE = 0,
    D3DWDDM2_0DDI_SWIZZLE_PATTERN_FLAGS_STACK_DEPTH_SLICES = 1,
    D3DWDDM2_2DDI_SWIZZLE_PATTERN_FLAGS_CONDITIONAL_POSTAMBLE_XORS = 0x2,
} D3DWDDM2_0DDI_SWIZZLE_PATTERN_FLAGS;

typedef struct D3DWDDM2_2DDI_SWIZZLE_PATTERN_DESC
{
    D3DWDDM2_0DDI_SWIZZLE_BIT_ENTRY InterleavePatternSourceBits[ 32 ];
    D3DWDDM2_0DDI_SWIZZLE_BIT_ENTRY InterleavePatternXORSourceBits[ 32 ];
    D3DWDDM2_0DDI_SWIZZLE_BIT_ENTRY InterleavePatternXOR2SourceBits[ 32 ];
    D3DWDDM2_0DDI_SWIZZLE_BIT_ENTRY InterleavePatternXOR3SourceBits[ 32 ];
    D3DWDDM2_0DDI_SWIZZLE_BIT_ENTRY InterleavePatternXOR4SourceBits[ 32 ];
    D3DWDDM2_0DDI_SWIZZLE_BIT_ENTRY PostambleXORSourceBits[ 32 ];
    D3DWDDM2_0DDI_SWIZZLE_BIT_ENTRY PostambleXOR2SourceBits[ 32 ];
    UINT PostambleXORImmediate;
    UINT Flags; // D3DWDDM2_0DDI_SWIZZLE_PATTERN_FLAGS
} D3DWDDM2_2DDI_SWIZZLE_PATTERN_DESC;
```

##### pfnGetResourceLayout

```cpp
typedef VOID ( APIENTRY* PFND3DWDDM2_0DDI_GETRESOURCELAYOUT )(
    D3D10DDI_HDEVICE, D3D10DDI_HRESOURCE, UINT SubresourceCount,
    _Out_ D3DKMT_HANDLE *, _Out_ D3DWDDM2_0DDI_TEXTURE_LAYOUT *,
    _Out_ UINT *pMipLevelSwizzleTransition,
    _Out_writes_opt_(SubresourceCount) D3DWDDM2_0DDI_SUBRESOURCE_LAYOUT * );
```

When the driver supports the latest DDI build version, the `MipLevelSwizzleTransition` array size is repurposed. The driver can now write up to 7 UINTs. The first 5 UINTs specify mip level transitions, and the last 2 UINTs specify plane slice transitions. See the changes to `D3D12DDI_RESOURCE_ALLOCATION_INFO` for more details.

---

## Peer-to-Peer LDA Atomics

### Scenario Description

#### The Why

This feature enables more applications scenarios to take more advantage of the capabilities of customer's PCs. It simplifies how applications can leverage hardware configurations that commonly have trouble justifying the return on focused investment. Linked adapter hardware typically resides at the most exclusively priced market segment region, and has notoriously been difficult for graphics developers to adopt into their applications. The current result is that the most powerful PCs with multiple GPUs perform as-if only a single GPU existed; and users can experience regressions while transitioning to the D3D12 version of a game. When the multiple GPU system supports UAV atomics peer memory segments, single GPU algorithms can more easily be ported to multiple GPU implementations, and multiple GPU adoption by D3D12 applications should noticeably increase.

### Detailed Feature Description

#### Goals and Requirements

- Simplify porting graphics engines to multiple GPUs.
- Improve functional memory orthogonality of NUMA architectures.

#### Architecture Decisions

A graphics hardware partner has first-hand experience with the problems supporting multiple GPUs, and added a hardware feature to simply the porting. Multi-GPU support gravitates to one of two main techniques: Alternate Frame Rendering vs Split Frame Rendering. Ever since shader atomic instructions were introduced, the absence of peer-to-peer atomic shader instruction support broke shaders running with the latter technique (SFR).

##### Immutable Heap Property to Require Physical Video Memory Segments

Unfortunately, the hardware cannot support peer-to-peer UAV atomic operations through physical system memory. These atomic operations must occur to physical video memory segments on one of the peer adapters. Not only must applications know to avoid explicitly using physical system memory, they must also have a way to guarantee physical video memory usage. We introduce a way to disable VidMM's transparent relocation of data to mitigate over-committed video memory scenarios.

An immutable heap property is used to require physical video memory for the following reasons:

- Application explicit usage of this type of memory should be strongly encouraged toward budgeting treatment, instead of mis-advertising frequent dynamic transitions is a viable option.
- The graphics kernel team recommends it, since they don't fully support transitioning that property. Where they do support the transition, it is as heavy-weight as a re-creation.
- Generalizing the capability integrates well with the existing heap type abstractions, as it helps dissuade them from using UAV atomics with CPU interlocked operations.
    - The graphics tools team wants to hold off officially supporting these types of use-cases as long as possible, because there's no currently known way to capture these use-cases.
    - The D3D team also prefers to hold off official support, until discrete adapter can provide the same features for UMA app-compat shims.

The alternative considered was a dynamic heap property to avoid an additional heap flag. Both maximum residency priority and dynamically restricting segment support were explored. The design would be similar to MakeResident functionality; but as heavy-weight as transparent eviction due to existing GPU references.

###### Mitigate Abuse with Limited Allocation Size

The runtime will take several steps to mitigate application abuse. The most significant is that applications are restricted to allocating heaps with this property much more than the residency budgets would. Our fallback is to restrict the application to only allocating 32MB of this type of memory. The graphics kernel team agreed to this amount; but decent evidence was eventually provided to counter that. A proportional-sized limitation was always desired; but the graphics kernel team couldn't recommend one quickly. They have previously helped us with metrics used for testing, and we can derive one from that. Evidence suggests 64MB on a 2GB adapter would help game scenarios more. That's only 3% committed per-process.

##### API Surface: Tier vs. Cap

Late feedback was received to avoid a tier for these reasons:

- One vendor plans to off the feature only for workstation class skus.
- One vendor plans to support the feature ubiquitously across all skus; but won't be there for initial release
- The cross node sharing tier focuses more on buffer and texture sharing capabilities.

A cap ensures the tiering stays reasonably aligned with the industry, after having sufficient time to see where our partners trend.

### Detailed Design

#### D3D12 API

A new cross node cap adds support for atomic shader instructions working across linked adapter (LDA) nodes. An on-by-default coin velocity feature is added to provide a rip-cord.

##### New Cross Node Caps

```cpp
enum D3D12_FEATURE
{
    D3D12_FEATURE_CROSS_NODE,
...
};

struct D3D12_FEATURE_DATA_CROSS_NODE
{
    D3D12_CROSS_NODE_SHARING_TIER SharingTier;
    BOOL AtomicShaderInstructions;
};

HRESULT ID3D12Device::CheckFeatureSupport( ... );
```

The new `AtomicShaderInstructions` BOOL advertises that the following shader atomics will work when accessing memory on a peer adapter:

- `atomic_and`
- `atomic_cmp_store`
- `atomic_iadd`
- `atomic_imax`
- `atomic_imin`
- `atomic_or`
- `atomic_umax`
- `atomic_umin`
- `atomic_xor`
- `imm_atomic_and`
- `imm_atomic_or`
- `imm_atomic_xor`
- `imm_atomic_iadd`
- `imm_atomic_imax`
- `imm_atomic_imin`
- `imm_atomic_umax`
- `imm_atomic_umin`
- `imm_atomic_exch`
- `imm_atomic_cmp_exch`

The following instructions were intentionally left out, because they are no longer available in D3D12:

- `imm_atomic_alloc`
- `imm_atomic_consume`

The new cap is available when the driver supports the corresponding DDI tier; and future DDI changes are expected to re-use cross-node-sharing-tier 3.

##### New Heap Flag

```cpp
enum D3D12_HEAP_FLAGS
{
    D3D12_HEAP_FLAG_NONE,
    D3D12_HEAP_FLAG_DENY_BUFFERS,
    D3D12_HEAP_FLAG_DENY_RT_DS_TEXTURES,
    D3D12_HEAP_FLAG_DENY_NON_RT_DS_TEXTURES,
    D3D12_HEAP_FLAG_SHARED,
    D3D12_HEAP_FLAG_SHARED_CROSS_ADAPTER,
    D3D12_HEAP_FLAG_HARDWARE_PROTECTED,
    D3D12_HEAP_FLAG_ALLOW_WRITE_WATCH,
    D3D12_HEAP_FLAG_ALLOW_SHADER_ATOMICS,
};

struct D3D12_HEAP_PROPERTIES
{
    D3D12_HEAP_TYPE Type;
    D3D12_CPU_PAGE_PROPERTIES CPUPageProperty;
    D3D12_MEMORY_POOL MemoryPoolPreference;
    UINT CreationNodeMask;
    UINT VisibleNodeMask;
};

struct D3D12_HEAP_DESC
{
    UINT64 SizeInBytes;
    D3D12_HEAP_PROPERTIES Properties;
    UINT64 Alignment;
    D3D12_HEAP_FLAGS Flags;
};

HRESULT ID3D12Device::CreateHeap( ... );
HRESULT ID3D12Device::CreateCommittedResource( ... );
D3D12_HEAP_DESC ID3D12Heap::GetDesc();
HRESULT ID3D12Resource::GetHeapProperties(
  _Out_opt_ D3D12_HEAP_PROPERTIES*, _Out_opt_ D3D12_HEAP_FLAGS* );
```

The meaning of `ALLOW_SHADER_ATOMICS` subtly shifts between usage with heap abstractions, and usage with custom heaps. Custom heaps focus more on converting `ALLOW_SHADER_ATOMICS` to a new DDI flag for disabling transparent demotion to system memory, while heap abstractions focus more on using `ALLOW_SHADER_ATOMICS` for safe validation.

The most common heaps with the new `ALLOW_SHADER_ATOMICS` flag will succeed even when the new cap isn't supported. This is because the API precludes CPU access and peer-to-peer visibility when applications use default parameters. `HEAP_TYPE_DEFAULT` precludes CPU access and `VisibleNodeMask` of 0 is converted to `0x1`. The driver won't see the new DDI heap flag in this case, since peer-to-peer is disabled & transparent eviction is supported.

Apps that explicitly create peer-to-peer visible `DEFAULT` heaps with the `ALLOW_SHADER_ATOMICS` flag will only succeed when the new tier is supported. Successfully created heaps of this type experience the confined budget limitations. Driver sees the new DDI heap flag, since peer-to-peer visibility is enabled. Peer-to-peer visibility is denoted by a `VisibleNodeMask` with bits that aren't in the `CreationNodeMask`.

Apps that create the cpu-visible, sys-mem heap abstractions with the `ALLOW_SHADER_ATOMICS` flag will fail. The two cpu-visible heap abstractions are `UPLOAD` and `READBACK`.

Apps that create the custom heaps with the `ALLOW_SHADER_ATOMICS` flag on will succeed. Apps may do normal CPU reads & writes or normal UAV reads & writes after using the appropriate fences. Shader atomics do work between shader execution groups in system memory and peer-to-peer visible memory, as long as no cpu atomic manipulation or peer atomic manipulation is required. The driver only sees the new DDI flag when `L1` & peer-to-peer visibility are used.

Cross-adapter heaps with the `ALLOW_SHADER_ATOMICS` flag will succeed, as we don't have the perfect safe vs. dangerous abstractions for this case. And, existing sys-mem heaps will advertise the new flag.

Committed resources must have the `UNORDERED_ACCESS` flag to be paired with `ALLOW_SHADER_ATOMICS`.

##### Constrained Memory

The constrained memory validation occurs during heap creation & destruction. The validation does not honor residency eviction, as the usage scenarios don't obviously justify adding the complex logic.

#### HLK Tests

- New test: Journal the values returned from atomic instruction usage over a short duration. Verify no torn bytes are observed.
- Driver verifier test: ensure driver doesn't allow system memory segment in the preferences.

---

## Memory Management

### Abstract

Video memory is a finite resource and therefore demands careful management.

With DirectX 12 (DX12), games can explicitly control what is in memory at any point in time. Unlike DirectX 11, a game's budget is known during runtime and with direct control over memory, DirectX 12 games can make intelligent memory management decisions based on game-specific knowledge.

This section describes the serious performance pitfalls that arise should a title fail to respect the current VRAM budget, and how to dynamically scale memory use without impacting rendering performance.

### Problem Space

#### No game has infinite memory

Every game must work within a limited budget of memory regardless of platform. Some platforms have variable budgets that a game has to dynamically work within; others have fixed budgets. However, in every case, a game must be aware of how much memory it has available, how much it is currently using, and have a way of scaling to match usage and budget.

#### Impact of memory management on rendering

Memory management operations can affect rendering in various ways. Consuming bandwidth to the GPU, improper synchronization, serialized CPU operations (e.g. loading resources from disk) on the rendering thread; all of these can impact rendering performance.

If a game does not ensure memory management operates independently of rendering, the game might suffer from rendering issues such as dropped frames, ultimately leading to a bad end user experience.

### Goals

From the above, we can define our goals in a generic way for every game:

- Know your budget.
- Move resources in and out of memory to stay within your budget.
- Do this in a way that does not impact rendering.

The existence of a budget is true for every game no matter the platform.

### How to determine your budget

#### Windows 10 driver model

Windows 10 introduces a new graphics driver model, known as WDDMv2. In WDDMv2, the graphics kernel moved the responsibility of memory management from the kernel itself to the user-mode process/application (game or otherwise).

Not every application can get full access to all of video memory without some contention. Unlike with DX11, DX12+WDDMv2 applications have a greatly enhanced ability to control their own memory footprint.

To prevent applications from using too much memory which can cause the system to thrash, the graphics kernel provides a per-process budget, representing what it thinks is a fair amount of video memory for that application to use. Under low memory pressure, this value is generally large for all processes. Once memory starts becoming constrained, the graphics kernel will start restricting the budget of various processes. The graphics kernel will prioritize memory to DWM (the desktop compositor that composites rendertargets from multiple apps among other things) and the foreground application above applications running in the background. This helps ensure that the application the user is currently using remains smooth and responsive.

Users expect to be able to multi-task applications. For example, it is well within reason to see a gamer playing a game with a walkthrough video playing on a second screen. In this case, the two applications (game and video player) need to share resources. Windows 10 and WDDMv2 empower these applications with the knowledge to make sure everything on the system runs smoothly.

It's also important for developers to know that many systems contain separated system memory and video memory (i.e. unlike systems such as the XBOX which have a Unified Memory Architecture: UMA). On such a system (e.g. a system that has a discrete GPU plugged in via PCI-E), the system memory is "slower" than video memory from the perspective of the GPU since any operations between the GPU and system memory must happen over the (relatively) slow PCI-E bus.

Using more memory than your process is budgeted is not recommended for any application. In addition to creating extra memory pressure on the system as a whole, the over-budget application may be subject to more restrictive constraints as the graphics kernel tries to resolve memory pressure. In particular, if the game exceeds its budget, its video memory usage may be more likely to be placed in slower memory (e.g. system memory in cases where system and video memory are separate). The application may also be chosen sooner as a candidate to be suspended completely under extreme pressure. This behavior is beneficial for a user to ensure the applications they care about at any moment have the resources they need to run smoothly.

That being said, suppose your application is the foreground application and it is severely over budget (to the point where it cannot even be placed in system memory on a discrete GPU configuration). It can still get suspended. Suspension occurs under heavy memory pressure when even slow (system) memory is completely consumed, and will result in the application being temporarily suspended for fixed periods of time where the graphics kernel will reclaim its memory and give it to another app. The application will be resumed after a period of time, and will make forward progress, but at the cost of the user experience. In the case of a game, this would be catastrophic for the experience.

When all applications behave well and remain under the provided budgets, the graphics kernel can ensure that all games remain in high-speed memory, and achieve the best performance. To achieve this goal, applications should monitor their usage at runtime and ensure that it never exceeds their budget.

#### Querying your budget

Windows' DirectX Graphics Infrastructure (DXGI) provides two means of allowing applications to monitor their memory usage: `QueryVideoMemoryInfo` and `RegisterVideoMemoryBudgetChangeNotificationEvent`.

`QueryVideoMemoryInfo` is a way for the application to poll the graphics kernel for information about how much memory they are using, how much video memory their process is budgeted, and information about video memory reservation.

In contrast to the polling method, `RegisterVideoMemoryBudgetChangeNotificationEvent` allows the application to map an event object to budget changes, allowing the graphics kernel to inform the application when their budget changes. This notification should be combined with the use of `QueryVideoMemoryInfo` (after the event is signaled) to refresh the application's view of video memory.

Some applications may find one of the above methods preferable over the other, but in general, either is acceptable. Both are exposed on `IDXGIAdapter3`.

```cpp
typedef enum DXGI_MEMORY_SEGMENT_GROUP
{
    // Local to the video adapter; fastest available memory to the GPU.
    // Applications should target this group as their working-set size.
    DXGI_MEMORY_SEGMENT_GROUP_LOCAL     = 0,
    // Non-local to the video adapter; may have slower performance than LOCAL.
    DXGI_MEMORY_SEGMENT_GROUP_NON_LOCAL = 1
} DXGI_MEMORY_SEGMENT_GROUP;

typedef struct DXGI_QUERY_VIDEO_MEMORY_INFO
{
    // OS-provided video-memory budget, in bytes, that the application
    // should target. Exceeding Budget may incur stuttering or performance
    // penalties as the OS gives other applications fair use of video memory.
    UINT64 Budget;
    // Application's current video-memory usage, in bytes.
    UINT64 CurrentUsage;
    // Bytes the application has available to reserve via
    // IDXGIAdapter3::SetVideoMemoryReservation.
    UINT64 AvailableForReservation;
    // Bytes reserved by the application. The OS uses this as a hint for
    // the application's minimum working set; the application should ensure
    // its usage can be trimmed to this amount.
    UINT64 CurrentReservation;
} DXGI_QUERY_VIDEO_MEMORY_INFO;

// Reports the current budget and process usage for a memory segment group.
HRESULT IDXGIAdapter3::QueryVideoMemoryInfo(
    UINT                              NodeIndex,
    DXGI_MEMORY_SEGMENT_GROUP         MemorySegmentGroup,
    _Out_ DXGI_QUERY_VIDEO_MEMORY_INFO *pVideoMemoryInfo );

// Registers an OS event handle to be signaled when the application's
// budget changes. The returned cookie is passed to
// UnregisterVideoMemoryBudgetChangeNotification to deregister.
HRESULT IDXGIAdapter3::RegisterVideoMemoryBudgetChangeNotificationEvent(
    _In_  HANDLE hEvent,
    _Out_ DWORD *pdwCookie );

void IDXGIAdapter3::UnregisterVideoMemoryBudgetChangeNotification(
    DWORD dwCookie );
```

### Acquiring/freeing memory in DX12

In DX12, games have greater control over their virtual address (VA) and physical address (PA) footprint when compared to DX11. VA is manipulated through "Resources" and PA is manipulated through "Heaps". The combined feature is called "Resource Heaps". Unlike DX11 style games, DX12 games can create/destroy VA and PA independently of each other by creating/destroying resources/heaps respectively.

Note, however, that when we say PA, it does not mean that a game can reference actual physical addresses directly. For the most part, it refers to the fact that the game has control over how much physical memory is available (assuming it is under budget) and how it has the ability to explicitly map GPU VA (in the form of DX12 resources) to it.

The concept of "Heaps" in "Resource Heaps" is not to be confused with the other DX12 concepts of "Heaps" in the "Descriptor Heaps" or "Query Heaps" features.

In DX12, the only way to allocate physical video memory is by creating a heap. This can be done in one of two ways: implicitly by using `CreateCommittedResource`, or explicitly using `CreateHeap`.

At this point, it is important to note that creating a committed resource will create both a resource and a heap. The heap will be created behind the application's back in a manner similar to DX11. This API was provided primarily to closer match DX11 resource creation behavior. Ideally, a game would use techniques that take advantage of the VA/PA separation.

`CreateHeap` will make PA available to use without creating a valid D3D resource. In order to use that newly created heap memory, an application is then expected to create a placed resource within that heap or map a reserved resource to that heap.

For typical scenarios, in order to make a resource available to the GPU for rendering, both a resource and heap memory backing that resource need to exist; the resource for binding to the GPU and the heap to contain the actual data.

Here is a table that outlines the methods used to create resources and heaps:

| Method | Creates resource | Creates heap |
| --- | --- | --- |
| `CreateHeap` | No | Yes |
| `CreatePlacedResource` | Yes | No |
| `CreateReservedResource`\* | Yes | No |
| `CreateCommittedResource` | Yes | Yes |

Table: Basic resource/heap creation method comparison.
\*While reserved resources are similar to placed resources, they can be created stand-alone without a pre-created heap and do not automatically get mapped to heap memory upon creation.

Conversely, the only way to release physical memory is to destroy the heap. By extension, it's critical for developers to understand that destroying resources (whether they are backed by actual heap memory or not) will only release VA. In the case of a committed resource, destroying the resource will also destroy the heap that was created behind the application's back, thereby releasing physical memory (and lowering your budget usage).

As an example, if a game were to create a heap (PA) and then create a placed resource (VA) within that heap, simply destroying the placed resource will not lower a game's overall memory footprint; the heap itself must be destroyed to return memory back to the system.

Signatures for `ID3D12Device::CreateHeap`, `CreateCommittedResource`, `CreatePlacedResource`, and `CreateReservedResource` appear in the [Heaps](#heaps) and [Resources](#resources) sections above.

#### Reserved Resources

For the purposes of intelligent memory management in DX12, reserved resources are particularly interesting.

Reserved resources allow the game to allocate virtual address (VA) space without the need to pre-create any heaps. Once created, DX12 provides APIs to map the reserved resource (VA) to a heap (PA). This mapping operation can be done dynamically at runtime. DX12 also provides synchronization primitives to synchronize mapping operations with rendering. Reserved resources are related to Tiled Resources, a concept introduced in the DX11 timeframe. However, hardware support had not been as widespread for Tiled Resources until recently.

Now, with near ubiquitous hardware support, reserved resources open up many new performance techniques beneficial for both performance and memory efficiency.

A reserved resource describes a region of VA — for example, a texture mip chain — while heaps describe regions of PA. Multiple heaps can back different regions of the same reserved resource, and any region of the reserved resource may be unmapped (i.e. not backed by any heap) at any given time. This many-to-many relationship between resources (VA) and heaps (PA) is the basis for fine-grained, runtime memory management.

### Separating memory management operations from rendering

Separating memory management from rendering is critical in providing the best end-user experience. Without considering the effects of memory management on rendering, a game might drop frames, etc.

DX12 is designed specifically around giving developers this independent control both on the CPU side and the GPU side. The result should be a game that has great, stable, rendering performance while still being able to dynamically scale its memory usage at runtime.

#### CPU

DX12 allows free-threaded recording of commands. This is especially powerful when we want to separate memory management CPU operations (i.e. load from disk) from rendering CPU operations (i.e. recording draw commands). This is sometimes called "separation of concerns". It is both beneficial for creating modular code and for performance in cases where parallelism is possible.

Many memory management operations can be thought of as conceptually independent of rendering operations: allocating memory, copying things around, destroying things, etc. In reality, the rendering portions of a game only really need to know what resource is available, when it's available, and where to access it from. The rendering portions of the game don't need to be concerned with how these resources became available.

Suppose some large texture mips need to be loaded from disk at runtime to improve the overall visual quality of the game. Doing this often involves calling a CPU blocking call where the thread will wait until the file IO operation moves these textures from disk and into memory. Doing this serially on the thread recording/submitting the rendering workload would be catastrophic; the game would stop rendering until the load operation is done.

Many games move this to a different CPU thread, and while that is a good start, on many platforms you still need to record GPU commands to copy these assets into video memory. Pre-DX12, recording and submitting these GPU commands generally had to be on the render thread and still had a CPU cost associated with it.

DX12's free-threaded nature allows games to very easily separate all of this. Games can now do all of their memory management in an independent way, going so far as to even record/submit GPU commands (e.g. copies, tile mapping, etc.) on a completely different CPU thread.

Once video memory is allocated and the required game assets are copied into that video memory, all the memory management thread(s) need to do is indicate to the game's rendering components that the resources they needed are now available for use.

With this CPU separation of concerns a game should be able to move game assets in and out of video memory independent of rendering and do so without ever dropping a frame.

#### GPU

Many modern GPUs have the capability to execute different types of workloads in parallel. DX12 exposes this parallelism in the form of "engines". This feature is referred to as Multiengine. In order to utilize these engines, a game can submit work to "command queues".

For instance, a copy workload may run in parallel with a 3D rendering workload; in some special cases, some hardware may even be able to execute copies in parallel with 3D work without lengthening the 3D workload time cost at all. This is possible since different workloads may use different parts of the GPU.

From the perspective of memory management, the ability to parallelize copies and 3D rendering is a powerful capability. Games gain the ability to flexibly manage video memory independent of rendering and in some cases even get performance benefits.

Most importantly, with this parallelism, memory management operations (e.g. GPU copies, memory mapping operations, etc.) can make forward progress without introducing rendering glitches (e.g. dropped frames).

#### GPU/CPU/Resource synchronization

In order to resolve execution dependencies, DX12 introduces the concept of fences and resource barriers. DX12 provides these APIs as an extremely flexible way of synchronizing any combination of CPU threads, GPU engines, and resources. They are even capable of synchronizing across multiple GPUs (e.g. in a multiadapter scenario where two GPUs are used simultaneously).

### Heap management considerations

#### Heap size and fragmentation

Reserved resources permit a one-mip-per-heap style mapping, but in reality, depending on the complexity of the game, the developer may not want to create so many small heaps due to things like heap creation time (especially at game load time).

Another consideration is that with current WDDMv2 limitations, creating very large heaps is also not recommended (e.g. a heap that can contain a 16k×16k mip). The game should consider the impact of creating large surfaces with respect to potential fragmentation of underlying video memory. Even if the graphics kernel reports that the amount of free memory is larger than the block of memory the game is trying to create, it may still fail if it cannot find a contiguous region in video memory of that size. If large allocations are required (e.g. atlas textures), it may be beneficial to allocate these large allocations up front, when there is less fragmentation in the segment.

Memory fragmentation can ultimately lead to poor performance if an allocation needs to be demoted to system memory due to a memory placement failure (due to fragmentation or out-of-memory conditions). On integrated systems with no fallback memory pools, or under extreme pressure on discrete systems (i.e. when system memory is also unavailable), the D3D device will be placed in a device-removed state; the device and all resources will need to be recreated.

The current recommended size of a heap is 32MB; however, there is no technical restriction on this size, and the game may create larger heaps if necessary.

#### Heap pooling and reuse

A heap backing a resource (or sub-resource) that is no longer needed doesn't necessarily need to be destroyed; it could, for example, be reused for a higher-priority allocation instead, to remove the cost of recreating the heap later on.

Another possible optimization includes pooling heaps of equal size. A game may even opt to group sub-allocations of equal size into one heap. The game might, for instance, put all of the foliage 256×256 mips into one heap with the assumption that if the game needs to reclaim memory, it's acceptable to lower all foliage mips simultaneously.

As for sub-allocations that are particularly large (e.g. a 16k×16k mip that is likely much larger than the recommended 32MB heap size), recall the many-to-many property of heaps and reserved resources. A game can actually split up the mip texture data into several heaps and map them all to the reserved resource. If a game had visibility information on which parts of a mip needed to be accessed, this could be used as a way for a game to implement sub-mip level management of memory, increasing memory efficiency even more.

Things to take into account when making these decisions include:

- The heap creation time cost.
- Having an unwieldy number of small heaps to manage.
- Not creating heaps that are too much larger than the recommended 32MB size.

Some optimizations that an app might make include:

- Pooling/reusing heaps.
- Grouping smaller sub-allocations (or sub-allocations of the same size) into one heap.
- Splitting large sub-allocations across several heaps (that can also be pooled).

The above is by no means a complete list of decision factors/optimizations as many of these decisions are workload/implementation specific, but they should give a developer an idea of the available options.

#### Suballocating from a single large heap

On platforms with a fixed budget, a game may opt to allocate one large heap up front and suballocate within it. This is typically infeasible on certain platforms (e.g. PC) due to inflexibility with a potentially variable runtime budget as well as a potentially high chance of failure when trying to place a contiguous block of physical memory.

That being said, it's understandable that a game may want to make this optimization when possible to remove certain costs (e.g. heap creation time). A game may choose to abstract "heap creation" as acquiring suballocated space from one large, pre-allocated heap, leaving the rest of the streaming algorithm the same.

### Using placed resources

#### For statically sized, long-lifetime resources

A heap can contain multiple placed resources. However, they do not provide the flexibility for the converse. Unlike reserved resources, placed resources cannot be used to access data in multiple heaps. Meaning, placed resources represent a one-heap-to-many-resources relationship, unlike the reserved resource's many-to-many relationship.

That being said, an application can use the one-to-many relationship to minimize the cost of creating heaps. From a practical standpoint, all games will have a minimum set of resources required to run. Placed resources can provide an optimal way to put statically sized, very-long-lifetime resources into a few (or perhaps even one) large heap(s). Note that on some hardware, buffer and texture resources cannot be mixed in the same heap. That being said, a game can still group all minimally required buffer resources into one heap and all minimally required textures into a different heap using placed resources, greatly simplifying initial resource loading.

Of course, a game will need to determine whether this single/few large heap(s) alone stay under the budget. In the simple case, a game may choose to show a pause screen until such time as the budget increases again (e.g. when the game goes into the background and the budget gets cut). If the minimum set of resources really cannot fit in the budget, it is still recommended that an application free heap space except for the resources required to render the pause screen (which should definitely fit in a small budget).

As a general statement, games may choose to use placed resources for static-size/long-lifetime assets and reserved resources for dynamically sized/dynamic-lifetime assets.

### Tiled/Reserved resources

#### Sub-mip residency

The benefits of using the very flexible reserved resources feature in DX12 do not end with mip-level memory management. Beyond mip-level management, a game might go even further and manage memory at a sub-mip-level granularity. This level of control can allow a game to have only a small percentage of a large mip in memory at a point in time, producing an even higher level of memory efficiency (especially important on low-memory configurations).

#### Resource compression metadata on reserved resources

Compression metadata is used by some hardware to provide performance benefits when accessing certain resources (e.g. fast clears, etc.). This typically comes at the cost of using slightly more memory. The amount of memory required is dependent on the hardware and implementation of specific optimizations.

Without going into too much detail, when using committed and placed resources, the amount of compression metadata required is known when the resource is created. A committed resource will create a heap behind the app's back with the requested size plus the amount of space required for the metadata. For placed resources, the game has the ability to determine how much space it needs including the compression metadata before the game needs to place it into an actual heap.

In the case of reserved resources however, since there is no heap space actually associated with the resource during resource creation, a driver may decide to allocate space elsewhere for the compression metadata. Although the space required for this metadata is not directly known by the game, the developer can use the budget querying APIs to check their before and after memory footprint.

It is ultimately up to the developer to account for this in their (dynamic runtime) budget calculations. It should be expected that on most hardware the memory cost here is small, especially for non-render targets, although the developer can always use the budget APIs discussed in this document to determine how much memory is being allocated on the side after reserved resource creation.

#### VA-constrained systems

On the vast majority of systems, VA is abundant, but on certain systems, VA is limited (e.g. 2GiB).

It's also important to note that currently, in DX12, creating a new heap (even if it does not contain a resource) can allocate VA. This means that, for example, creating a reserved resource of 32MiB and a heap of 32MiB will in fact consume 64MiB of virtual address space. This is usually not an issue since nearly all modern gaming hardware supports a large amount of VA. Only on systems where that is limited to 2GiB can this be an issue.

### Windows 10 WDDM2 eviction vs heap destruction

As we already know, games should trim their usage by reducing the physical memory consumed by DX12 heaps. Typically, this is done by destroying the heap. There is, however, added functionality that allows an application (not necessarily a game) to mark the heap for what's called "eviction". This functionality is exposed through the DX12 API and is referred to as managing residency.

D3D12's heap eviction interface gives applications the ability to reduce their memory footprint by evicting without actually destroying the heap. The application can then "make the heap resident" again to make it available for rendering.

```cpp
// Marker base interface for objects that encapsulate GPU-accessible memory.
// Most core D3D12 objects inherit from ID3D12Pageable, but residency changes
// are only supported on the following: Descriptor Heaps, Heaps, Committed
// Resources, and Query Heaps.
interface ID3D12Pageable : ID3D12DeviceChild
{
};

// Loads the data associated with an object from disk and re-allocates its
// memory from the appropriate memory pool. Call on the object that owns the
// physical memory (a committed resource or a heap; reserved resources have no
// physical memory and placed resources borrow from a heap).
HRESULT ID3D12Device::MakeResident(
                                  UINT             NumObjects,
    _In_reads_(NumObjects) ID3D12Pageable* const* ppObjects );

// Persists the object's data to disk and removes it from its memory pool.
// Call on the object that owns the physical memory.
HRESULT ID3D12Device::Evict(
                                  UINT             NumObjects,
    _In_reads_(NumObjects) ID3D12Pageable* const* ppObjects );
```

---

## Appendix A - Design History

This appendix records the design's evolution over time, taken from the
change-logs of the contributing iterations, plus brief summaries of the
pre-milestone proposal documents that preceded them.

> **Note on symbol naming and source corrections.** A small number of symbol names and identifiers in the body of this spec have been corrected in place where the contributing iterations contained stale names or source typos, so that the body reads as a single internally-consistent reference. All corrections are mechanical — no behavior changes:
>
> **API-level renames** (older flag-naming conventions superseded by the shipped form):
>
> | Old (source) | New (body) |
> |---|---|
> | `D3D12_HEAP_MISC_FLAG` (type) | `D3D12_HEAP_FLAGS` |
> | `D3D12_HEAP_MISC_*` (enumerators) | `D3D12_HEAP_FLAG_*` |
> | `D3D12_RESOURCE_MISC_FLAG` (type) | `D3D12_RESOURCE_FLAGS` |
> | `D3D12_RESOURCE_MISC_*` (enumerators) | `D3D12_RESOURCE_FLAG_*` |
> | `HeapMiscFlags` / `MiscFlags` (struct fields) | `HeapFlags` / `Flags` |
> | `D3D12_RESOURCE_USAGE` (type for resource state) | `D3D12_RESOURCE_STATES` |
> | `D3D12_TEXTURE_LAYOUT_64KB_TILE_UNDEFINED_SWIZZLE` | `D3D12_TEXTURE_LAYOUT_64KB_UNDEFINED_SWIZZLE` (and same for `_STANDARD_SWIZZLE` — the `_TILE_` segment was dropped) |
>
> **Source-typo corrections** (identifier or keyword errors carried over from the contributing iterations):
>
> | Source | Correction |
> |---|---|
> | `typedef D3D12_TEXTURE_COPY_LOCATION { ... }` (missing keyword) | `typedef struct D3D12_TEXTURE_COPY_LOCATION { ... }` |
> | `D3D12_PITCHED_PLACED_SUBRESOURCE_DESC` (word order in one union-member reference) | `D3D12_PLACED_PITCHED_SUBRESOURCE_DESC` (matches the struct's declared name) |
> | `D3D12DDIRESOURCE_TYPE` (missing underscore) | `D3D12DDI_RESOURCE_TYPE` |
> | `UD3D12DDI_TILE_MAPPING_FLAG` (stray `U` prefix) | `D3D12DDI_TILE_MAPPING_FLAG` |
> | `PFND3D12DDI_CALCPRIVATERESOURCESIZE` (stale typedef name in a dispatch-table field) | `PFND3D12DDI_CALCPRIVATEHEAPANDRESOURCESIZES` (matches the actual typedef declaration) |
> | `PFND3D12DDI_CHECKEXISITINGRESOURCEALLOCATIONINFO_0022` (transposed letters) | `PFND3D12DDI_CHECKEXISTINGRESOURCEALLOCATIONINFO_0022` |
> | `paginq queue` | `paging queue` |
> | `specifiy` | `specify` |
> | `Committed resouces` | `Committed resources` |
> | `typedef struct D3D12_HEAP_TYPE` (wrong keyword) | `typedef enum D3D12_HEAP_TYPE` |
> | `as efficient as efficient as possible` | `as efficient as possible` |
> | `MakesResident` (in the MakeResident batching example) | `MakeResident` |
> | Alignment sub-bullets in Hardware Requirements previously ended with a confusing `", or less"` qualifier (source shorthand for "or less-aligned"; readers commonly misread it as "or a stricter multiple") | `", or less"` phrase dropped from all six sites; the alignment values stated are the driver's required upper bound |
> | Hardware Requirements preamble previously read `"New content is in bold. The rest is carried over and summarized for context."` (a merging artifact from the milestone-restatement source convention that no longer applies to this consolidated form) | preamble rewritten to `"Unless otherwise called out, the requirements below apply to both heap tiers."`; bold formatting stripped from the numbered requirements list, which is now a uniform list rather than a diff-against-prior-milestone |
>
> **Back-filled API declarations** (the contributing iterations name these APIs in prose but do not declare their signatures; declarations sourced from Microsoft Learn / shipped headers):
>
> | API | Source header |
> |---|---|
> | `IDXGIAdapter3::QueryVideoMemoryInfo`, `RegisterVideoMemoryBudgetChangeNotificationEvent`, `UnregisterVideoMemoryBudgetChangeNotification`, `DXGI_QUERY_VIDEO_MEMORY_INFO`, `DXGI_MEMORY_SEGMENT_GROUP` | `dxgi1_4.h` |
> | `ID3D12Pageable`, `ID3D12Device::MakeResident`, `ID3D12Device::Evict` | `d3d12.h` |
>
> **Completed sentence** (one source sentence in the GPU VA Capability Reflection sub-section was truncated mid-clause; the completion preserves the parallelism with the preceding per-process sentence and is consistent with the surrounding scenario discussion):
>
> | Source | Completed form |
> |---|---|
> | "The per-resource capability divulges if" | "The per-resource capability divulges whether the mostly-sparse scenario is viable for the application's target resource sizes." |
>
> DDI-side symbol names (`D3D12DDI_*`) other than the typos above are preserved in their original source form. References to the *old* names in historical context (the Appendix below, the design rationale for removed features like `D3D12_RESOURCE_USAGE_INITIAL`, and the D3D11-deprecation discussions) are intentional and left as-is.

### Pre-milestone proposals

#### Initial Resource Heaps proposal

- States the overall goal: "The goal of Resource Heaps in D3D12 is to improve memory usage by enabling better packing efficiency and reducing allocation overhead."
- Notes that the GDC release of the D3D12 preview shipped Dynamic Heaps (CPU-write or CPU-read linear buffer data for vertex/index/constant buffers and texture staging) but not the other half — "a type of heap that can store data for all other resources, such as textures that can be sampled and rendered efficiently."
- Sketches two design directions for the remaining heap kind: an Automatic Default Heap (scratch surface, all potential views declared up-front with only one active at a time, enabling aliasing) and an Automatic Static Heap (all views declared up-front, all active simultaneously, improving packing and reducing allocation overhead).

#### IHV/ISV drafts and 1-pager

- The IHV draft (Version 0.2) introduces app-controllable heaps "for apps to reuse graphics memory more efficiently in conjunction with the deprecation of dynamic resource renaming (aka. Map-Discard) in D3D12," and divides heaps into Dynamic Heaps, Default Heaps (with a "union" of resources where only one is alive at a time), and Static Heaps (atomic creation of an array of resources sharing lifespan and residency).
- The ISV draft frames the problems as "Expensive Resource Create and Destruction" and "Underutilized Graphics Memory," and proposes "app-controllable graphics memory heaps, so that expensive video memory allocation can be teased out from resource creation and will be done during heap creation."
- The GAB 1-pager summarizes: "The Direct3D API currently entangles the allocation of video memory with the creation of most graphics pipeline resources," and proposes that "creating a Heap will incur the majority of today's resource creation cost. Creating a resource associated with a pre-existing heap will be much cheaper, as video memory is re-used instead of allocated."

#### Resource Heaps ISV draft

- Recaps the three GAB scenarios (Dynamic Heap, Static Heap, Default Heap) and reports that "In the latest release of D3D12 ("v2 SDK and later") we provide a formal separation of resources and memory allocation, along with full support for pipeline-accessible "default" heaps."
- Defines `D3D12_HEAP_DESC` with `D3D12_HEAP_PROPERTIES` (Type: UPLOAD, READBACK, DEFAULT, CUSTOM; CPUPageProperties: NOT_AVAILABLE, WRITE_COMBINE, WRITE_BACK; MemoryPoolPreference: L0, L1), Alignment, and MiscFlags (SHARED, NO_TEXTURES, NO_BUFFERS).
- Notes that "minor changes to the design, indicated by red text, … should be included in the next major update to the DX12 SDK (planned for December)."

#### Later ISV draft

- Carries forward the earlier ISV-draft framing from February 2014: small-resource creation is a bottleneck, small resources underutilize video memory due to "fixed partitioning and hardware restrictions, such as alignment, stride, and page padding requirements," and "API design in this spec might evolve after GDC when we further investigate how to better handle static heaps and default heaps, and how D3D12 buffers interact with other D3D12 features."
- Lays out the GDC solution: "D3D12 supports dynamic heaps for apps to efficiently transfer dynamic resource data between CPU and GPU," with Buffer as a new D3D12 resource type, deprecation of dynamic resource renaming and `UpdateSubresource`, and `CopySubresourceRegion` between buffers and textures.

#### Archived dev-design draft

- Marked archived, with a note that further edits should be made in the then-new unified spec; this dev-design draft was archived for reference only.
- Frames the value proposition: "We introduce additional flexibility for app heaps to reuse graphics memory more efficiently, in conjunction with the deprecation of dynamic resource renaming (aka. Map-Discard) in D3D12," with app heaps implemented as large D3D resources (typically buffers) the CPU usually writes into and may also read back from.
- Enumerates problems: decreased video memory utilization (transient resources can't be reused flexibly, alignment/padding waste, small pages increase TLB pressure, locality/residency not optimal) and increased execution time (create/destroy overhead, set/render overhead).

### September 2014 (DDI)

- 5/5/2014 — 1.5 — Proposal for final heap design, aligned to tile pool & tiled resources.
- 5/23/2014 — 1.6 — Updates based on IHV feedback (see markup for complete changes):
  1. Added requirement regarding RTV and DSV compression data placement within heaps – compression data must be locatable in separate pages from the resource.
  2. Requirements now allow for MSAA surfaces to have page sizes larger than 64KB.
  3. Added goal for supporting 4KB page size and alignment for mainstream scenarios.
  4. Merged CreateHeap and CreateResource DDIs to enable optimizations.
  5. Added alignment parameter to heap/resource creation DDI to enable placement of resources with >64KB alignment requirements.
  6. DDI now allows hardware to request physically contiguous heap memory for cross-engine scenarios on legacy hardware.
  7. Added background and scenarios for application use of GPU VA; added new mechanism to allow GPU VA reuse by creating resources at offsets within pre-allocated buffers.
  8. Miscellaneous DDI changes reflecting the above design changes.
- 6/18/2014 — 1.7 —
  1. Removed 1D and MSAA standard swizzle specifications.
  2. Significant detail expansion of residency management and GPU VA requirements and DDIs.
  3. Updated heap creation DDI to allow simultaneous heap + resource creation to enable optimizations.
  4. Minor DDI naming revisions and spec clarifications.
- 9/5/2014 — 1.8 —
  1. Deleted dynamic heap topics for features completed near GDC to better focus spec.
  2. Postpone tiled resource heap design option until after September due to feedback from GAB. Scope back tiled resource capabilities to D3D11 level; but preserve existing DDI that evolves tile pool into a heap and refactors resource creation. Instead, the GPU reuse/placement technique is the preferred alternative; and now is coined a child resource.
  3. Provide significantly more spec detail how callflow and DDI parameters are equivalent between D3D11 and D3D12. Add additional spec details to reinforce what can and cannot happen, and better detail delivery timeframe of related features.
  4. Scope back residency support to only heaps & descriptor heaps to avoid more complex designs without confirmed value.
  5. Summarize driver work and requirements at a higher level, to improve understanding.
  6. Added more testing expectations.
- 10/13/2014 — 1.85 —
  1. Add one more resource misc flags (PRIMARY) and 2 more optimization flags (UNORDERED_ACCESS and DETERMINISTIC).
  2. Tighten up placed resource requirements on a heap to allow 4KB non-RT and non-DS, and a 64KB MSAA option. Revise the `CheckResourceAllocationInfo` DDI to support specification of this.
  3. Tiled Buffer orthogonality.
  4. Clarify needed linear texture support now vs. future.
  5. Other misc. clarifications.

### December 2014 (DDI)

- 5/5/2014 — 1.5 — Proposal for final heap design, aligned to tile pool & tiled resources.
- 5/23/2014 — 1.6 — Updates based on IHV feedback (see markup for complete changes):
  1. Added requirement regarding RTV and DSV compression data placement within heaps – compression data must be locatable in separate pages from the resource.
  2. Requirements now allow for MSAA surfaces to have page sizes larger than 64KB.
  3. Added goal for supporting 4KB page size and alignment for mainstream scenarios.
  4. Merged CreateHeap and CreateResource DDIs to enable optimizations.
  5. Added alignment parameter to heap/resource creation DDI to enable placement of resources with >64KB alignment requirements.
  6. DDI now allows hardware to request physically contiguous heap memory for cross-engine scenarios on legacy hardware.
  7. Added background and scenarios for application use of GPU VA; added new mechanism to allow GPU VA reuse by creating resources at offsets within pre-allocated buffers.
  8. Miscellaneous DDI changes reflecting the above design changes.
- 6/18/2014 — 1.7 —
  1. Removed 1D and MSAA standard swizzle specifications.
  2. Significant detail expansion of residency management and GPU VA requirements and DDIs.
  3. Updated heap creation DDI to allow simultaneous heap + resource creation to enable optimizations.
  4. Minor DDI naming revisions and spec clarifications.
- 9/5/2014 — 1.8 —
  1. Deleted dynamic heap topics for features completed near GDC to better focus spec.
  2. Postpone tiled resource heap design option until after September due to feedback from GAB. Scope back tiled resource capabilities to D3D11 level; but preserve existing DDI that evolves tile pool into a heap and refactors resource creation. Instead, the GPU reuse/placement technique is the preferred alternative; and now is coined a child resource.
  3. Provide significantly more spec detail how callflow and DDI parameters are equivalent between D3D11 and D3D12. Add additional spec details to reinforce what can and cannot happen, and better detail delivery timeframe of related features.
  4. Scope back residency support to only heaps & descriptor heaps to avoid more complex designs without confirmed value.
  5. Summarize driver work and requirements at a higher level, to improve understanding.
  6. Added more testing expectations.
- 10/27/2014 — 1.85 —
  1. Tighten up placed resource requirements on a heap to allow a 4KB option for non-RT and non-DS, and a 64KB MSAA option for everything else.
  2. Added 2 more optimization flags (UNORDERED_ACCESS and DETERMINISTIC).
  3. Support standard and parameterized swizzle with the new D3D12 DDIs, along with resource and subresource information reflection.
  4. Support previously spec'ed caps related to alignment.
  5. Any shared resource's heap created by non-D3D12 APIs must be, at least, 4K aligned. This impacts the capabilities available to D3D12 when opening such shared heaps; and should require no driver changes.
  6. No compression data is supported unless the texture is render target or depth-stencil.
  7. Clarify linear texture support needed for backward compatibility later.
  8. Other misc. DDI tweaks and clarifications.
- 11/01/2014 — 1.86 —
  1. More strongly teased apart layout and swizzle pattern enum space, to avoid overhead generating a unique swizzle pattern enum space.
  2. Added hardware requirement: When multiple swizzle patterns are used on a particular texture, usage must transition at a particular mip level for that texture.
  3. Realigned deprecation of DETERMINISTIC flag with standard swizzle.
  4. Clear values are passed during resource creation, to enable certain optimizations; but disallowed once standard swizzle primaries are supported.
  5. Corrected details about when DETERMINISTIC and UNORDERED_ACCESS would be set.
  6. Miscellaneous clarity improvements.
- 11/10/2014 — 1.87 —
  1. Relax row-major pitch alignment requirement to 256 bytes.
  2. Refinements of row-major/linear texture requirements.
  3. Rename the DDIs, as part of deprecating older & unused DDIs.

### February 2015 (unified spec, first)

- 12/16/2013 — 1.0 — First partner release.
- 1/24/2014 — 1.1 — Minor updates based on IHV feedback (please turn on All Markup in WORD to highlight those changes since last version):
  1. Require width stride for texture data on hardware to be 128-byte aligned for all texel element sizes;
  2. Punt `D3D12DDI_RL_PLACED_VIRTUAL_SUBRESOURCE_PITCHED` support to post-GDC;
  3. Punt Optimizing `CopySubresourceRegion` to post-GDC;
  4. Punt `PlaceShaderResourceView` DDI support to post-GDC.
- 5/5/2014 — 1.5 — Proposal for final heap design, aligned to tile pool & tiled resources.
- 5/23/2014 — 1.6 — Updates based on IHV feedback (see markup for complete changes):
  1. Added requirement regarding RTV and DSV compression data placement within heaps – compression data must be locatable in separate pages from the resource.
  2. Requirements now allow for MSAA surfaces to have page sizes larger than 64KB.
  3. Added goal for supporting 4KB page size and alignment for mainstream scenarios.
  4. Merged CreateHeap and CreateResource DDIs to enable optimizations.
  5. Added alignment parameter to heap/resource creation DDI to enable placement of resources with >64KB alignment requirements.
  6. DDI now allows hardware to request physically contiguous heap memory for cross-engine scenarios on legacy hardware.
  7. Added background and scenarios for application use of GPU VA; added new mechanism to allow GPU VA reuse by creating resources at offsets within pre-allocated buffers.
  8. Miscellaneous DDI changes reflecting the above design changes.
- 6/18/2014 — 1.7 —
  1. Removed 1D and MSAA standard swizzle specifications.
  2. Significant detail expansion of residency management and GPU VA requirements and DDIs.
  3. Updated heap creation DDI to allow simultaneous heap + resource creation to enable optimizations.
  4. Minor DDI naming revisions and spec clarifications.

### March 2015 (DDI)

- 5/5/2014 — 1.5 — Proposal for final heap design, aligned to tile pool & tiled resources.
- 5/23/2014 — 1.6 — Updates based on IHV feedback (see markup for complete changes):
  1. Added requirement regarding RTV and DSV compression data placement within heaps – compression data must be locatable in separate pages from the resource.
  2. Requirements now allow for MSAA surfaces to have page sizes larger than 64KB.
  3. Added goal for supporting 4KB page size and alignment for mainstream scenarios.
  4. Merged CreateHeap and CreateResource DDIs to enable optimizations.
  5. Added alignment parameter to heap/resource creation DDI to enable placement of resources with >64KB alignment requirements.
  6. DDI now allows hardware to request physically contiguous heap memory for cross-engine scenarios on legacy hardware.
  7. Added background and scenarios for application use of GPU VA; added new mechanism to allow GPU VA reuse by creating resources at offsets within pre-allocated buffers.
  8. Miscellaneous DDI changes reflecting the above design changes.
- 6/18/2014 — 1.7 —
  1. Removed 1D and MSAA standard swizzle specifications.
  2. Significant detail expansion of residency management and GPU VA requirements and DDIs.
  3. Updated heap creation DDI to allow simultaneous heap + resource creation to enable optimizations.
  4. Minor DDI naming revisions and spec clarifications.
- 9/5/2014 — 1.8 —
  1. Deleted dynamic heap topics for features completed near GDC to better focus spec.
  2. Postpone tiled resource heap design option until after September due to feedback from GAB. Scope back tiled resource capabilities to D3D11 level; but preserve existing DDI that evolves tile pool into a heap and refactors resource creation. Instead, the GPU reuse/placement technique is the preferred alternative; and now is coined a child resource.
  3. Provide significantly more spec detail how callflow and DDI parameters are equivalent between D3D11 and D3D12. Add additional spec details to reinforce what can and cannot happen, and better detail delivery timeframe of related features.
  4. Scope back residency support to only heaps & descriptor heaps to avoid more complex designs without confirmed value.
  5. Summarize driver work and requirements at a higher level, to improve understanding.
  6. Added more testing expectations.
- 10/27/2014 — 1.85 —
  1. Tighten up placed resource requirements on a heap to allow a 4KB option for non-RT and non-DS, and a 64KB MSAA option for everything else.
  2. Added 2 more optimization flags (UNORDERED_ACCESS and DETERMINISTIC).
  3. Support standard and parameterized swizzle with the new D3D12 DDIs, along with resource and subresource information reflection.
  4. Support previously spec'ed caps related to alignment.
  5. Any shared resource's heap created by non-D3D12 APIs must be, at least, 4K aligned. This impacts the capabilities available to D3D12 when opening such shared heaps; and should require no driver changes.
  6. No compression data is supported unless the texture is render target or depth-stencil.
  7. Clarify linear texture support needed for backward compatibility later.
  8. Other misc. DDI tweaks and clarifications.
- 11/01/2014 — 1.86 —
  1. More strongly teased apart layout and swizzle pattern enum space, to avoid overhead generating a unique swizzle pattern enum space.
  2. Added hardware requirement: When multiple swizzle patterns are used on a particular texture, usage must transition at a particular mip level for that texture.
  3. Realigned deprecation of DETERMINISTIC flag with standard swizzle.
  4. Clear values are passed during resource creation, to enable certain optimizations; but disallowed once standard swizzle primaries are supported.
  5. Corrected details about when DETERMINISTIC and UNORDERED_ACCESS would be set.
  6. Miscellaneous clarity improvements.
- 11/10/2014 — 1.87 —
  1. Relax row-major pitch alignment requirement to 256 bytes.
  2. Refinements of row-major/linear texture requirements.
  3. Rename the DDIs, as part of deprecating older & unused DDIs.
- 3/12/2014 — 1.95 —
  1. Support primaries through the latest D3D12 DDIs.
  2. Add Heap Tiers.
  3. Define incremental mapping for tiles in packed maps during `UpdateTileMappings`.
  4. Other misc. DDI tweaks.
- 3/20/2014 — 1.96 —
  1. Cut planned porting of the `GetGammaCaps` DDI.

### May 2015 (DDI)

- 5/5/2014 — 1.5 — Proposal for final heap design, aligned to tile pool & tiled resources.
- 5/23/2014 — 1.6 — Updates based on IHV feedback (see markup for complete changes):
  1. Added requirement regarding RTV and DSV compression data placement within heaps – compression data must be locatable in separate pages from the resource.
  2. Requirements now allow for MSAA surfaces to have page sizes larger than 64KB.
  3. Added goal for supporting 4KB page size and alignment for mainstream scenarios.
  4. Merged CreateHeap and CreateResource DDIs to enable optimizations.
  5. Added alignment parameter to heap/resource creation DDI to enable placement of resources with >64KB alignment requirements.
  6. DDI now allows hardware to request physically contiguous heap memory for cross-engine scenarios on legacy hardware.
  7. Added background and scenarios for application use of GPU VA; added new mechanism to allow GPU VA reuse by creating resources at offsets within pre-allocated buffers.
  8. Miscellaneous DDI changes reflecting the above design changes.
- 6/18/2014 — 1.7 —
  1. Removed 1D and MSAA standard swizzle specifications.
  2. Significant detail expansion of residency management and GPU VA requirements and DDIs.
  3. Updated heap creation DDI to allow simultaneous heap + resource creation to enable optimizations.
  4. Minor DDI naming revisions and spec clarifications.
- 9/5/2014 — 1.8 —
  1. Deleted dynamic heap topics for features completed near GDC to better focus spec.
  2. Postpone tiled resource heap design option until after September due to feedback from GAB. Scope back tiled resource capabilities to D3D11 level; but preserve existing DDI that evolves tile pool into a heap and refactors resource creation. Instead, the GPU reuse/placement technique is the preferred alternative; and now is coined a child resource.
  3. Provide significantly more spec detail how callflow and DDI parameters are equivalent between D3D11 and D3D12. Add additional spec details to reinforce what can and cannot happen, and better detail delivery timeframe of related features.
  4. Scope back residency support to only heaps & descriptor heaps to avoid more complex designs without confirmed value.
  5. Summarize driver work and requirements at a higher level, to improve understanding.
  6. Added more testing expectations.
- 10/27/2014 — 1.85 —
  1. Tighten up placed resource requirements on a heap to allow a 4KB option for non-RT and non-DS, and a 64KB MSAA option for everything else.
  2. Added 2 more optimization flags (UNORDERED_ACCESS and DETERMINISTIC).
  3. Support standard and parameterized swizzle with the new D3D12 DDIs, along with resource and subresource information reflection.
  4. Support previously spec'ed caps related to alignment.
  5. Any shared resource's heap created by non-D3D12 APIs must be, at least, 4K aligned. This impacts the capabilities available to D3D12 when opening such shared heaps; and should require no driver changes.
  6. No compression data is supported unless the texture is render target or depth-stencil.
  7. Clarify linear texture support needed for backward compatibility later.
  8. Other misc. DDI tweaks and clarifications.
- 11/01/2014 — 1.86 —
  1. More strongly teased apart layout and swizzle pattern enum space, to avoid overhead generating a unique swizzle pattern enum space.
  2. Added hardware requirement: When multiple swizzle patterns are used on a particular texture, usage must transition at a particular mip level for that texture.
  3. Realigned deprecation of DETERMINISTIC flag with standard swizzle.
  4. Clear values are passed during resource creation, to enable certain optimizations; but disallowed once standard swizzle primaries are supported.
  5. Corrected details about when DETERMINISTIC and UNORDERED_ACCESS would be set.
  6. Miscellaneous clarity improvements.
- 11/10/2014 — 1.87 —
  1. Relax row-major pitch alignment requirement to 256 bytes.
  2. Refinements of row-major/linear texture requirements.
  3. Rename the DDIs, as part of deprecating older & unused DDIs.
- 3/12/2014 — 1.95 —
  1. Support primaries through the latest D3D12 DDIs.
  2. Add Heap Tiers.
  3. Define incremental mapping for tiles in packed maps during `UpdateTileMappings`.
  4. Other misc. DDI tweaks.
- 3/20/2014 — 1.96 —
  1. Cut planned porting of the `GetGammaCaps` DDI.
- 3/27/2015 — 1.97 —
  1. Added `StackDepthSlices` field to `D3D12DDI_SWIZZLE_PATTERN_DESC` DDI structure.
- 4/16/2015 — 1.98 —
  1. Added `InterleavePatternXOR3` field to `D3D12DDI_SWIZZLE_PATTERN_DESC` and converted `StackDepthSlices` field to flags.
  2. Cut parameterized swizzle support for textures in cpu-accessible video memory for heap tier 1.
  3. Better clarified hardware requirements related to heap tier 1.
  4. Add new hardware goal and reasoning for where to locate compression metadata, which has been implied by the DDI design. The reasoning includes details about eventually evolving to a standardized texture layout, and elaborates how that'll likely work.
  5. Clarify destruction requirements for all objects which may be resident.
  6. Clarify physical memory aliasing and data inheritance requirements for placed resources.
- 5/28/2015 — 1.99 —
  1. Clarify driver requirements to support simultaneous read-only access to resources.
  2. Add `D3D12DDI_RESOURCE_FLAG_0003_SIMULTANEOUS_ACCESS` flag for simultaneous read with 1 writer.
  3. Require `D3D12DDI_RESOURCE_STATE_COMMON` resource state for CPU access to textures.
  4. Some states disallowed for initial state of resources.
  5. Expand (clear/copy) metadata initialization rules for placed resources and clarify existing rules for reserved and committed resources.
  6. Add GPU VA caps.
  7. Added support for 6 swizzle patterns per texture, but the pattern cannot vary within a single mip level slice.
  8. Clarify row-major texturing of BC is not required.

### Mid-2014 unified spec

This mid-2014 unified spec revision does not contain an explicit change-log section. Its Feature Summary frames the iteration: "Applications must manage physical video memory explicitly due to the lack of GPUs with page-faulting capabilities. Heaps are introduced and teased apart from resources, adding additional flexibility to reuse physical video memory quickly." The body notes that "With the significant churn of introducing heap objects, a lot of miscellaneous changes also occur: residency APIs, size estimation APIs, GPU architecture caps, and the resource descriptions and DDI are refactored while updating them for D3D12." Dated deliverable target is 2014/5/5.

### Late-2014 unified spec

This late-2014 unified spec revision does not contain an explicit change-log section. Its Feature Summary frames the iteration: "there's only small tweaks to D3D12's heap and resource support, to finish off a good design across all IHVs. Standard & parameterized swizzle is also brought to D3D12. Smaller alignment options are now available for smaller textures that don't support RT & DS. And, the API is polished in many areas." The Summary adds: "The rest of the changes are minor cleanups and tweaks to the existing designs."

### Final consolidated unified spec

The final consolidated unified spec does not contain an explicit change-log section. It is the consolidated form covering all prior milestones, with references back to the per-milestone DDI revisions (December 2014, March 2015, May 2015) in its IHV Spec section. Its Summary frames the consolidated design: "D3D12 enables applications to reuse physical video memory significantly better to mitigate the lack of GPU page-faulting. That reuse is largely achieved through application placement of resources and/or placement of resource data. However, the entire resource design was refactored for D3D12 with an emphasis on maximizing resource flexibility, creating opportunities for application residency management, and simplifying D3D architecture." The most significant API change is described as "the introduction of a heap API object, which allows resources to be created at a particular offset within the heap … referred to as resource placement on a heap."
