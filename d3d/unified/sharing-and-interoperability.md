# Sharing and interoperability

<!-- d3d12-review-legend:begin -->

> [!NOTE]
> **Draft provenance annotations.**
> Underlining marks pending replacement wording or authored list items. Warning boxes
> mark authored, mixed or reopened passages awaiting editorial review.
> Editorial adoption does not establish factual or hardware verification. Exact approved factual
> corrections do not trigger a marker. Unmarked text elsewhere, declarations
> and structural Markdown are not assertions of approval.
> [Annotation scope and approvals](../../spec-maintenance/d3d12/prose-annotations.md).

<!-- d3d12-review-legend:end -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-introduction:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Sharing exposes the same resource or heap backing, fence, or protected-resource session to more than one device or process. A shared NT handle identifies the shared kernel object; opening it obtains an interface associated with the opening D3D12 device. It does not transfer the exporting device's COM object or GPU virtual address.

<!-- d3d12-review-alert:end:sharing-interop:SH-introduction:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-introduction:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [resource and heap storage models](resources.md#storage-models) distinguish committed resources, placed resources, and reserved resources. [Device identity and linked nodes](devices-and-capabilities.md#identity) distinguish an adapter LUID, a device, and a node. [Independent devices](devices-and-capabilities.md#independent-devices) can use the same adapter without being the same device. Sharing storage is not permission to pass one device's resource object or descriptors directly to another device.

<!-- d3d12-review-alert:end:sharing-interop:SH-introduction:1 -->

<a id="shared-backing"></a>

## Shared backing and resource descriptions

Shared heaps enable two things: sharing data in a heap across one or more processes, and precluding a non-deterministic choice of undefined texture layout for resources placed within the heap. Sharing heaps across adapters also removes the need for CPU marshaling of the data.

Both heaps and committed resources can be shared. Sharing a committed resource actually shares the implicit heap along with the committed resource description, such that a compatible resource description can be mapped to the heap from another device.

When thinking of shared resources, two limiting factors impact support:

- <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-page-tables:1 -->D3D12 sharing does not share page tables between multiple processes.<!-- d3d12-review-inline:end:sharing-interop:SH-page-tables:1 --></ins>
- The runtime and driver private data must be known at kernel resource creation time.

Since page tables are not shared between processes, shared resources are equivalent to sharing the implicit heap with a resource description to setup the VA mapping appropriately.

<!-- d3d12-review-alert:begin:sharing-interop:SH-local-identity:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The shared backing can have different GPU virtual-address mappings on different devices and in different processes. An application must use the opening device's resource object and that object's GPU virtual address, where the resource has one; it must not exchange GPU virtual addresses as a substitute for sharing the backing.

<!-- d3d12-review-alert:end:sharing-interop:SH-local-identity:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-local-identity:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A raw shared heap carries storage, not an application's placed-resource arrangement. Each participating device creates its own placed resources on the opened heap. The application must communicate heap offsets and compatible resource descriptions separately. For data inheritance between equivalent placed textures, the [complete resource description, optimized clear value, placement, creation-kind, and initialization requirements](synchronization.md#legacy-aliasing) apply; [enhanced aliasing](synchronization.md#enhanced-aliasing) defines the enhanced-barrier path. Sharing does not make arbitrary descriptions equivalent. [Shared tiles and compatible data inheritance](resources.md#tiled-data-compatibility) defines reserved-resource mapping compatibility.

<!-- d3d12-review-alert:end:sharing-interop:SH-local-identity:1 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-object-kinds:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The supported shared-object kinds are:

<!-- d3d12-review-alert:end:sharing-interop:SH-object-kinds:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-object-kinds:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Object | Creation requirement | What is shared or opened |
> |---|---|---|
> | `ID3D12Heap` | `D3D12_HEAP_FLAG_SHARED` | Heap backing; placed-resource descriptions and offsets are communicated separately. |
> | Committed `ID3D12Resource` | Its implicit heap has `D3D12_HEAP_FLAG_SHARED` | Implicit heap and committed-resource description; open as a resource, not as a raw heap. |
> | `ID3D12Fence` | `D3D12_FENCE_FLAG_SHARED` | The fence, with its existing value and creation properties; opening does not create a new initial value. |
> | `ID3D12ProtectedResourceSession` | Protected-resource sessions are always shared; heap and fence `SHARED` flags do not apply to the session. | The protected-resource session, not an ordinary shared-fence export of its status timeline. |

<!-- d3d12-review-alert:end:sharing-interop:SH-object-kinds:1 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-object-kinds:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> An application must not export a placed or reserved resource object with `CreateSharedHandle`. A placed resource uses its explicitly created heap's sharing path. Separate devices or processes can create their own reserved resources and map them to a shared heap, subject to [tiled-resource compatibility](resources.md#tiled-data-compatibility); this does not share the reserved resource's mappings or allow cross-adapter reserved-resource sharing.

<!-- d3d12-review-alert:end:sharing-interop:SH-object-kinds:2 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-object-kinds:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The full [heap creation](resources.md#create-heap), [committed-resource creation](resources.md#create-committed-resource), [placed-resource creation](resources.md#create-placed-resource), [reserved-resource creation](resources.md#create-reserved-resource), and [fence creation](execution.md#create-fence) contracts remain applicable. The [heap flags](resources.md#heap-flags), [resource flags](resources.md#resource-flags), and [fence flags](execution.md#fence-flags) define the underlying flag values and other interactions.

<!-- d3d12-review-alert:end:sharing-interop:SH-object-kinds:3 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-protected-session-sharing:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A protected-resource session can be exported with [CreateSharedHandle](#id3d12device-createsharedhandle), opened on another compatible device with [OpenSharedHandle](#id3d12device-opensharedhandle), and looked up by its shared NT name with [OpenSharedHandleByName](#id3d12device-opensharedhandlebyname). The session's handle follows the common NT-handle name, access, security, inheritance, duplication, and close requirements in this chapter. Its interface remains a separately owned COM reference.

<!-- d3d12-review-alert:end:sharing-interop:SH-protected-session-sharing:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-protected-session-sharing:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Protected-resource sessions are always shared. The application does not add `D3D12_HEAP_FLAG_SHARED` or `D3D12_FENCE_FLAG_SHARED` to a session to make it exportable. Session sharing does not turn the session's status timeline into an ordinary application-signaled shared fence. The [protected-resource session interface and creation contract](../ProtectedResources.md#interface-id3d12protectedresourcesession) and [protected-session status-fence contract](execution.md#status-fences) define those distinct objects and their roles.

<!-- d3d12-review-alert:end:sharing-interop:SH-protected-session-sharing:1 -->

<a id="shared-heaps"></a>

## Sharing heaps across processes

Shared heaps are specified with the <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-process-flag:0 -->`D3D12_HEAP_FLAG_SHARED`<!-- d3d12-review-inline:end:sharing-interop:SH-process-flag:0 --></ins> member of the <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-process-flag:0 -->[**`D3D12_HEAP_FLAGS`**](resources.md#heap-flags)<!-- d3d12-review-inline:end:sharing-interop:SH-process-flag:0 --></ins> enum.

<ins><!-- d3d12-review-inline:begin:sharing-interop:SH-process-cpu:0 -->Creating shared heaps with `D3D12_HEAP_FLAG_SHARED` is not supported on CPU-accessible heaps:<!-- d3d12-review-inline:end:sharing-interop:SH-process-cpu:0 --></ins> <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-process-cpu:0 -->`D3D12_HEAP_TYPE_UPLOAD`<!-- d3d12-review-inline:end:sharing-interop:SH-process-cpu:0 --></ins>, <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-process-cpu:0 -->`D3D12_HEAP_TYPE_READBACK`<!-- d3d12-review-inline:end:sharing-interop:SH-process-cpu:0 --></ins>, and <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-process-cpu:0 -->`D3D12_HEAP_TYPE_CUSTOM`<!-- d3d12-review-inline:end:sharing-interop:SH-process-cpu:0 --></ins> without <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-process-cpu:0 -->`D3D12_CPU_PAGE_PROPERTY_NOT_AVAILABLE`<!-- d3d12-review-inline:end:sharing-interop:SH-process-cpu:0 --></ins>.

<!-- d3d12-review-alert:begin:sharing-interop:SH-gpu-upload-forward:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The CPU-accessible [GPU upload heap](resources.md#gpu-upload) likewise does not support creation with shared heap flags.

<!-- d3d12-review-alert:end:sharing-interop:SH-gpu-upload-forward:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-shared-creation-scope:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> These CPU-access restrictions apply when creating heaps with shared flags. They are not a blanket prohibition on opening compatible existing or imported CPU-accessible backing. The [existing-memory heap imports](resources.md#existing-memory-heaps) have distinct requirements; their availability does not make CPU-accessible shared-flag creation legal. The [heap-property](resources.md#heap-properties) and [CPU-access](resources.md#cpu-access) contracts remain applicable to the backing being used.

<!-- d3d12-review-alert:end:sharing-interop:SH-shared-creation-scope:0 -->

Precluding a non-deterministic choice of undefined texture layout can significantly impair deferred rendering scenarios on some GPUs, so it is not the default behavior for placed and committed resources. Deferred rendering is impaired on some GPU architectures because deterministic texture layouts decrease the effective memory bandwidth achieved when rendering simultaneously to multiple render target textures of the same format and size. GPU architectures are evolving away from leveraging non-deterministic texture layouts in order to support standardized swizzle patterns and standardized layouts efficiently for deferred rendering.

Shared heaps come with other minor costs as well:

- Shared heap data can't be recycled as flexibly as in-process heaps due to information disclosure concerns, so physical memory is zero'ed more often.
- There is a minor additional CPU overhead and increased system memory usage during creation and destruction of shared heaps.

<a id="adapter-domains"></a>

## Same adapter, linked nodes, and different adapters

<!-- d3d12-review-alert:begin:sharing-interop:SH-domain-distinction:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Same-adapter sharing between devices is distinct from visibility between linked nodes of a device and from sharing between separate adapters. An adapter's linked nodes are enumerated by [GetNodeCount](devices-and-capabilities.md#id3d12device-getnodecount); the heap's [creation and visible node masks](resources.md#heap-properties) determine node placement and visibility.

<!-- d3d12-review-alert:end:sharing-interop:SH-domain-distinction:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-domain-distinction:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12_CROSS_NODE_SHARING_TIER` describes sharing across linked nodes of an adapter. Its values are reported by [D3D12_FEATURE_DATA_D3D12_OPTIONS::CrossNodeSharingTier](devices-and-capabilities.md#d3d12_feature_data_d3d12_options) and [D3D12_FEATURE_DATA_CROSS_NODE::SharingTier](devices-and-capabilities.md#d3d12_feature_data_cross_node). It is not a tier for arbitrary unlinked adapters. [D3D12_FEATURE_DATA_CROSS_NODE::AtomicShaderInstructions](devices-and-capabilities.md#d3d12_feature_data_cross_node) and [D3D12_HEAP_FLAG_ALLOW_SHADER_ATOMICS](resources.md#heap-flags) define the additional linked-node atomic capability and heap requirements.

<!-- d3d12-review-alert:end:sharing-interop:SH-domain-distinction:1 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-domain-distinction:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Cross-adapter sharing instead uses the [cross-adapter heap and resource flags](#cross-adapter-heaps), compatible layouts, and shared cross-adapter fences. The [cross-API compatibility tier](#cross-api-compatibility) is a third, independent capability: it governs resource formats shared between D3D API versions, not linked-node visibility or unlinked-adapter support.

<!-- d3d12-review-alert:end:sharing-interop:SH-domain-distinction:2 -->

<a id="cross-node-sharing-tier"></a>

### D3D12_CROSS_NODE_SHARING_TIER

```cpp
typedef enum D3D12_CROSS_NODE_SHARING_TIER {
  D3D12_CROSS_NODE_SHARING_TIER_NOT_SUPPORTED = 0,
  D3D12_CROSS_NODE_SHARING_TIER_1_EMULATED = 1,
  D3D12_CROSS_NODE_SHARING_TIER_1 = 2,
  D3D12_CROSS_NODE_SHARING_TIER_2 = 3,
  D3D12_CROSS_NODE_SHARING_TIER_3 = 4
} D3D12_CROSS_NODE_SHARING_TIER;
```

<!-- d3d12-review-alert:begin:sharing-interop:SH-cross-node-tier-values:0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Tier | Linked-node support |
> |---|---|
> | `D3D12_CROSS_NODE_SHARING_TIER_NOT_SUPPORTED` | Value: *0*. If an adapter has only 1 node, then cross-node sharing doesn't apply, so the **CrossNodeSharingTier** member of the [D3D12_FEATURE_DATA_D3D12_OPTIONS](devices-and-capabilities.md#d3d12_feature_data_d3d12_options) structure is set to `D3D12_CROSS_NODE_SHARING_TIER_NOT_SUPPORTED`. |
> | `D3D12_CROSS_NODE_SHARING_TIER_1_EMULATED` | Value: *1*. Tier 1 Emulated. Devices that set the **CrossNodeSharingTier** member of the [D3D12_FEATURE_DATA_D3D12_OPTIONS](devices-and-capabilities.md#d3d12_feature_data_d3d12_options) structure to `D3D12_CROSS_NODE_SHARING_TIER_1_EMULATED` have Tier 1 support. However, drivers stage these copy operations through a driver-internal system memory allocation. This will cause these copy operations to consume time on the destination GPU as well as the source. |
> | `D3D12_CROSS_NODE_SHARING_TIER_1` | Value: *2*. Tier 1. Devices that set the **CrossNodeSharingTier** member of the [D3D12_FEATURE_DATA_D3D12_OPTIONS](devices-and-capabilities.md#d3d12_feature_data_d3d12_options) structure to `D3D12_CROSS_NODE_SHARING_TIER_1` only support the following cross-node copy operations:<br>- [ID3D12GraphicsCommandList::CopyBufferRegion](resource-operations.md#copybufferregion)<br>- [ID3D12GraphicsCommandList::CopyTextureRegion](resource-operations.md#copytextureregion)<br>- [ID3D12GraphicsCommandList::CopyResource](resource-operations.md#copyresource)<br><br>Additionally, the cross-node resource must be the destination of the copy operation. |
> | `D3D12_CROSS_NODE_SHARING_TIER_2` | Value: *3*. Tier 2. Devices that set the **CrossNodeSharingTier** member of the [D3D12_FEATURE_DATA_D3D12_OPTIONS](devices-and-capabilities.md#d3d12_feature_data_d3d12_options) structure to `D3D12_CROSS_NODE_SHARING_TIER_2` support all operations across nodes, except for the following:<br>- Render target views.<br>- Depth stencil views.<br>- UAV atomic operations. Similar to CPU/GPU interop, shaders may perform UAV atomic operations; however, no atomicity across linked nodes is guaranteed.<br><br>Applications can retrieve the node where a resource/heap exists from the [D3D12_HEAP_DESC](resources.md#heap-description) structure. These values are retrievable for opened resources. The runtime performs the appropriate re-mapping in case the 2 devices are using different user-mode-driver-specified node re-mappings. |
> | `D3D12_CROSS_NODE_SHARING_TIER_3` | Value: *4*. Indicates support for [**`D3D12_HEAP_FLAG_ALLOW_SHADER_ATOMICS`**](resources.md#heap-flags) on heaps that are visible to multiple nodes. |

<!-- d3d12-review-alert:end:sharing-interop:SH-cross-node-tier-values:0 -->

<a id="cross-adapter-heaps"></a>

## Sharing heaps across adapters

<ins><!-- d3d12-review-inline:begin:sharing-interop:SH-cross-flag:0 -->Sharing heaps across adapters is specified<!-- d3d12-review-inline:end:sharing-interop:SH-cross-flag:0 --></ins> with the <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-cross-flag:0 -->`D3D12_HEAP_FLAG_SHARED_CROSS_ADAPTER`<!-- d3d12-review-inline:end:sharing-interop:SH-cross-flag:0 --></ins> member of the <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-cross-flag:0 -->[**`D3D12_HEAP_FLAGS`**](resources.md#heap-flags)<!-- d3d12-review-inline:end:sharing-interop:SH-cross-flag:0 --></ins> enum.

Cross adapter shared heaps enable multiple adapters to share data without the CPU marshaling the data between them. While varying adapter capabilities determine how efficient adapters can pass data between them, merely enabling GPU copies increases the effective bandwidth achieved. Some texture layouts are allowed on cross adapter heaps to support an interchange of texture data, even if such texture layouts are not otherwise supported. Certain restrictions may apply to such textures, such as only supporting copying.

Cross-adapter sharing works with heaps created by calling [**ID3D12Device::CreateHeap**](resources.md#create-heap). Your application can then create resources via [**CreatePlacedResource**](resources.md#create-placed-resource). It is also allowed by resources/heaps created by [**CreateCommittedResource**](resources.md#create-committed-resource) but only for row-major <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-cross-creation:0 -->`D3D12_RESOURCE_DIMENSION_TEXTURE2D`<!-- d3d12-review-inline:end:sharing-interop:SH-cross-creation:0 --></ins> resources (refer to <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-cross-creation:0 -->[**`D3D12_RESOURCE_DIMENSION`**](resources.md#resource-dimensions)<!-- d3d12-review-inline:end:sharing-interop:SH-cross-creation:0 --></ins>). Cross-adapter sharing does not work with [**CreateReservedResource**](resources.md#create-reserved-resource).

For cross-adapter sharing, all of the usual cross-queue resource sharing rules still apply. Your application must issue the appropriate barriers to ensure proper synchronization and coherence between the two adapters. Your application should use cross-adapter fences to coordinate the scheduling of command lists submitted to multiple adapters. There is no mechanism to share cross-adapter resources across D3D API versions. Cross-adapter shared resources are only supported in system memory. Cross-adapter shared heaps/resources are supported in <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-cross-coherence:0 -->`D3D12_HEAP_TYPE_DEFAULT`<!-- d3d12-review-inline:end:sharing-interop:SH-cross-coherence:0 --></ins> heaps and <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-cross-coherence:0 -->`D3D12_HEAP_TYPE_CUSTOM`<!-- d3d12-review-inline:end:sharing-interop:SH-cross-coherence:0 --></ins> heaps (with the L0 memory pool, and <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-cross-coherence:0 -->`D3D12_CPU_PAGE_PROPERTY_NOT_AVAILABLE` CPU page properties<!-- d3d12-review-inline:end:sharing-interop:SH-cross-coherence:0 --></ins>). Drivers must be sure that GPU read/write operations to cross-adapter shared heaps are coherent with other GPUs on the system. For example, the driver may need to exclude the heap data from residing in GPU caches that typically don’t need to be flushed when the CPU can't directly access the heap data.

Your application should confine the usage of cross adapter heaps to only those scenarios which require the functionality they provide. Cross-adapter heaps are located in <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-cross-cost:0 -->`D3D12_MEMORY_POOL_L0`<!-- d3d12-review-inline:end:sharing-interop:SH-cross-cost:0 --></ins>, which is not always what [**GetCustomHeapProperties**](resources.md#heap-properties) suggests. That memory pool is not efficient for discrete/ NUMA adapter architectures. And, the most efficient texture layouts are not always available.

The following limitations also apply:

- <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-cross-limitations:1 -->The heap flags related to heap tiers must be `D3D12_HEAP_FLAG_ALLOW_ALL_BUFFERS_AND_TEXTURES`.<!-- d3d12-review-inline:end:sharing-interop:SH-cross-limitations:1 --></ins>
- <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-cross-limitations:1 -->`D3D12_HEAP_FLAG_SHARED` must also be set.<!-- d3d12-review-inline:end:sharing-interop:SH-cross-limitations:1 --></ins>
- <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-cross-limitations:1 -->Either `D3D12_HEAP_TYPE_DEFAULT` must be set or `D3D12_HEAP_TYPE_CUSTOM` with `D3D12_MEMORY_POOL_L0` and `D3D12_CPU_PAGE_PROPERTY_NOT_AVAILABLE` must be set.<!-- d3d12-review-inline:end:sharing-interop:SH-cross-limitations:1 --></ins>
- <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-cross-limitations:1 -->Only resources with `D3D12_RESOURCE_FLAG_ALLOW_CROSS_ADAPTER` may be placed on cross-adapter heaps.<!-- d3d12-review-inline:end:sharing-interop:SH-cross-limitations:1 --></ins>
- <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-cross-limitations:1 -->A protected session can't be passed into the creation of the heap when `D3D12_HEAP_FLAG_SHARED_CROSS_ADAPTER` is specified<!-- d3d12-review-inline:end:sharing-interop:SH-cross-limitations:1 --></ins>

<!-- d3d12-review-alert:begin:sharing-interop:SH-cross-layouts:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The complete [texture-layout restrictions](resources.md#texture-layout) apply. A row-major cross-adapter texture is a non-MSAA `Texture2D` with one mip level and one array slice, 64-KiB alignment, no depth-stencil flag, and no YUV format. Padding and row/slice strides are part of the layout; equal logical dimensions alone do not define a byte layout. Buffers use row-major layout.

<!-- d3d12-review-alert:end:sharing-interop:SH-cross-layouts:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-cross-layouts:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Cross-adapter placed resources can also use `D3D12_TEXTURE_LAYOUT_64KB_STANDARD_SWIZZLE`. The [standard-swizzle support and cross-adapter exception](resources.md#texture-layout) govern allowed operations: the exception does not turn a copy-only layout into a render-target, depth-stencil, or UAV layout. Cross-adapter resources require one mip level and do not use YUV or planar formats in these layouts. `D3D12_RESOURCE_FLAG_ALLOW_CROSS_ADAPTER` is required if and only if the heap has `D3D12_HEAP_FLAG_SHARED_CROSS_ADAPTER`. The resource flag also enables the simultaneous-access behavior defined in [resource flags](resources.md#resource-flags) and [simultaneous access](synchronization.md#simultaneous-access).

<!-- d3d12-review-alert:end:sharing-interop:SH-cross-layouts:1 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-cross-layouts:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> [CrossAdapterRowMajorTextureSupported](devices-and-capabilities.md#d3d12_feature_data_d3d12_options) distinguishes shader-resource, unordered-access, and render-target views of cross-adapter row-major textures from copy-only support. An application must not infer those view capabilities from successful creation or from `CrossNodeSharingTier`.

<!-- d3d12-review-alert:end:sharing-interop:SH-cross-layouts:2 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-cross-layouts:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The full [committed cross-adapter creation restrictions](resources.md#shared-cross-adapter-creation) govern the resource's row-major `Texture2D` shape and format-and-layout display support. They do not define the operational domain of the separate [DISPLAYABLE query](devices-and-capabilities.md#d3d12_feature_data_displayable).

<!-- d3d12-review-alert:end:sharing-interop:SH-cross-layouts:3 -->

<a id="cross-api-compatibility"></a>

## Sharing between D3D API versions

Only committed resources and certain heaps can be shared with earlier runtimes; and D3D12 shared resources can only be opened in D3D11, if D3D11 supported sharing with a D3D11 resource description that converts to the shared D3D12 resource description.

<!-- d3d12-review-alert:begin:sharing-interop:SH-cross-api-shape:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A D3D11 resource description must convert to the shared D3D12 description; a compatible format alone is not sufficient. The D3D11 resource-kind, dimensions, sample count, mip/array constraints, bind flags, usage, and sharing mode must also be supported by the consuming API. Cross-adapter shared resources do not provide cross-D3D-version sharing.

<!-- d3d12-review-alert:end:sharing-interop:SH-cross-api-shape:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-cross-api-shape:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12_SHARED_RESOURCE_COMPATIBILITY_TIER` specifies the following cumulative cross-API format sets. The [D3D12_FEATURE_DATA_D3D12_OPTIONS4](devices-and-capabilities.md#d3d12_feature_data_d3d12_options4) payload reports cross-API resource sharing support. The separate [D3D12_FEATURE_DATA_DISPLAYABLE](devices-and-capabilities.md#d3d12_feature_data_displayable) payload uses the same enum, but that does not make its capability domain interchangeable with `OPTIONS4` or establish presentation support.

<!-- d3d12-review-alert:end:sharing-interop:SH-cross-api-shape:1 -->

<ins><!-- d3d12-review-inline:begin:sharing-interop:SH-cross-api-tier-definition:0 -->`D3D12_SHARED_RESOURCE_COMPATIBILITY_TIER` defines constants<!-- d3d12-review-inline:end:sharing-interop:SH-cross-api-tier-definition:0 --></ins> that specify a cross-API sharing support tier.

The resource data formats mentioned are members of the [DXGI_FORMAT enumeration](https://learn.microsoft.com/en-us/windows/win32/api/dxgiformat/ne-dxgiformat-dxgi_format).

```cpp
typedef enum D3D12_SHARED_RESOURCE_COMPATIBILITY_TIER {
  D3D12_SHARED_RESOURCE_COMPATIBILITY_TIER_0 = 0,
  D3D12_SHARED_RESOURCE_COMPATIBILITY_TIER_1,
  D3D12_SHARED_RESOURCE_COMPATIBILITY_TIER_2
} D3D12_SHARED_RESOURCE_COMPATIBILITY_TIER;
```

<!-- d3d12-review-context:begin:sharing-interop:SH-tier-dispute:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**

> **Draft qualification — format-tier reconciliation:** The following table remains qualified pending feature-owner clarification. It preserves the owning D3D12 public reference, with its nonexistent format identifier corrected. Its tier-1 format-family coverage and tier-2 addition require reconciliation: the owning D3D11 tier-3 reference identifies `DXGI_FORMAT_R11G11B10_FLOAT`, whereas this D3D12 table names `NV12`. The table is not a verified exhaustive acceptance matrix. Resource shape, format support, and the consuming API's creation restrictions remain required.

<!-- d3d12-review-context:end:sharing-interop:SH-tier-dispute:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-cross-api-tier-values:0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Tier | Format support and qualifications |
> |---|---|
> | `D3D12_SHARED_RESOURCE_COMPATIBILITY_TIER_0` | Value: *0*. Related to [D3D11_SHARED_RESOURCE_TIER::D3D11_SHARED_RESOURCE_TIER_1](https://learn.microsoft.com/en-us/windows/win32/api/d3d11/ne-d3d11-d3d11_shared_resource_tier). Specifies that the most basic level of cross-API sharing is supported, including the following resource data formats.<br>• `DXGI_FORMAT_R8G8B8A8_UNORM`<br>• `DXGI_FORMAT_R8G8B8A8_UNORM_SRGB`<br>• `DXGI_FORMAT_B8G8R8A8_UNORM`<br>• `DXGI_FORMAT_B8G8R8A8_UNORM_SRGB`<br>• `DXGI_FORMAT_B8G8R8X8_UNORM`<br>• `DXGI_FORMAT_B8G8R8X8_UNORM_SRGB`<br>• `DXGI_FORMAT_R10G10B10A2_UNORM`<br>• `DXGI_FORMAT_R16G16B16A16_FLOAT` |
> | `D3D12_SHARED_RESOURCE_COMPATIBILITY_TIER_1` | Related to [D3D11_SHARED_RESOURCE_TIER::D3D11_SHARED_RESOURCE_TIER_2](https://learn.microsoft.com/en-us/windows/win32/api/d3d11/ne-d3d11-d3d11_shared_resource_tier). Specifies that cross-API sharing functionality of **`D3D12_SHARED_RESOURCE_COMPATIBILITY_TIER_0`** is supported, plus the following formats.<br>• `DXGI_FORMAT_R16G16B16A16_TYPELESS`<br>• `DXGI_FORMAT_R10G10B10A2_TYPELESS`<br>• `DXGI_FORMAT_R8G8B8A8_TYPELESS`<br>• `DXGI_FORMAT_B8G8R8X8_TYPELESS`<br>• `DXGI_FORMAT_R16G16_TYPELESS`<br>• `DXGI_FORMAT_R8G8_TYPELESS`<br>• `DXGI_FORMAT_R32_TYPELESS`<br>• `DXGI_FORMAT_R16_TYPELESS`<br>• `DXGI_FORMAT_R8_TYPELESS`<br>This level of support is built into WDDM 2.4. Also see [Extended support for shared Texture2D resources](https://learn.microsoft.com/en-us/windows/win32/direct3d11/direct3d-11-1-features#extended-support-for-shared-texture2d-resources). |
> | `D3D12_SHARED_RESOURCE_COMPATIBILITY_TIER_2` | Related to [D3D11_SHARED_RESOURCE_TIER::D3D11_SHARED_RESOURCE_TIER_3](https://learn.microsoft.com/en-us/windows/win32/api/d3d11/ne-d3d11-d3d11_shared_resource_tier). Specifies that cross-API sharing functionality of **`D3D12_SHARED_RESOURCE_COMPATIBILITY_TIER_1`** is supported, plus the following formats.<br>• `DXGI_FORMAT_NV12` (also see [Extended NV12 texture support](https://learn.microsoft.com/en-us/windows/win32/direct3d11/direct3d-11-4-features#extended-nv12-texture-support)) |

<!-- d3d12-review-alert:end:sharing-interop:SH-cross-api-tier-values:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-cross-api-tier-qualification:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The table's D3D11 tiers are related capability reports, not numeric aliases for the D3D12 tier values. In particular, the D3D11 tier's own definition has additional NT-handle format qualifications. This table does not replace the consuming API's resource-creation and format-support requirements.

<!-- d3d12-review-alert:end:sharing-interop:SH-cross-api-tier-qualification:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-cross-api-tier-qualification:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> For NT-handle interoperation, D3D11 opens a shared resource through [ID3D11Device1::OpenSharedResource1](https://learn.microsoft.com/en-us/windows/win32/api/d3d11_1/nf-d3d11_1-id3d11device1-opensharedresource1) and a shared fence through [ID3D11Device5::OpenSharedFence](https://learn.microsoft.com/en-us/windows/win32/api/d3d11_4/nf-d3d11_4-id3d11device5-opensharedfence). Those D3D11 methods and their D3D11 capability requirements are not D3D12 methods.

<!-- d3d12-review-alert:end:sharing-interop:SH-cross-api-tier-qualification:1 -->

<a id="d3d11-description-baseline"></a>

### D3D11 description baseline

<ins><!-- d3d12-review-inline:begin:sharing-interop:SH-d3d11-description-guarantee:0 -->Direct3D 11.1 guarantees<!-- d3d12-review-inline:end:sharing-interop:SH-d3d11-description-guarantee:0 --></ins> that you can share Texture2D resources that you created with a mipmap level of 1, array size of 1, bind flags of <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-d3d11-description-guarantee:0 -->[**`D3D11_BIND_SHADER_RESOURCE`**](https://learn.microsoft.com/en-us/windows/desktop/api/D3D11/ne-d3d11-d3d11_bind_flag)<!-- d3d12-review-inline:end:sharing-interop:SH-d3d11-description-guarantee:0 --></ins> and <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-d3d11-description-guarantee:0 -->[**`D3D11_BIND_RENDER_TARGET`**](https://learn.microsoft.com/en-us/windows/desktop/api/D3D11/ne-d3d11-d3d11_bind_flag)<!-- d3d12-review-inline:end:sharing-interop:SH-d3d11-description-guarantee:0 --></ins> combined, usage default (<ins><!-- d3d12-review-inline:begin:sharing-interop:SH-d3d11-description-guarantee:0 -->[**`D3D11_USAGE_DEFAULT`**](https://learn.microsoft.com/en-us/windows/desktop/api/D3D11/ne-d3d11-d3d11_usage)<!-- d3d12-review-inline:end:sharing-interop:SH-d3d11-description-guarantee:0 --></ins>), and only these <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-d3d11-description-guarantee:0 -->[**`D3D11_RESOURCE_MISC_FLAG`**](https://learn.microsoft.com/en-us/windows/desktop/api/D3D11/ne-d3d11-d3d11_resource_misc_flag)<!-- d3d12-review-inline:end:sharing-interop:SH-d3d11-description-guarantee:0 --></ins> values:

- <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-d3d11-description-guarantee:1 -->[**`D3D11_RESOURCE_MISC_SHARED`**](https://learn.microsoft.com/en-us/windows/desktop/api/D3D11/ne-d3d11-d3d11_resource_misc_flag)<!-- d3d12-review-inline:end:sharing-interop:SH-d3d11-description-guarantee:1 --></ins>
- <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-d3d11-description-guarantee:1 -->[**`D3D11_RESOURCE_MISC_SHARED_KEYEDMUTEX`**](https://learn.microsoft.com/en-us/windows/desktop/api/D3D11/ne-d3d11-d3d11_resource_misc_flag)<!-- d3d12-review-inline:end:sharing-interop:SH-d3d11-description-guarantee:1 --></ins>
- <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-d3d11-description-guarantee:1 -->[**`D3D11_RESOURCE_MISC_SHARED_NTHANDLE`**](https://learn.microsoft.com/en-us/windows/desktop/api/D3D11/ne-d3d11-d3d11_resource_misc_flag)<!-- d3d12-review-inline:end:sharing-interop:SH-d3d11-description-guarantee:1 --></ins>
- <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-d3d11-description-guarantee:1 -->[**`D3D11_RESOURCE_MISC_GDI_COMPATIBLE`**](https://learn.microsoft.com/en-us/windows/desktop/api/D3D11/ne-d3d11-d3d11_resource_misc_flag)<!-- d3d12-review-inline:end:sharing-interop:SH-d3d11-description-guarantee:1 --></ins>

<!-- d3d12-review-alert:begin:sharing-interop:SH-d3d11-guarantee-scope:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This is a baseline guaranteed sharing shape, not an exhaustive list of legal descriptions for every sharing tier. The applicable extended-sharing capabilities and consuming API's creation rules can permit additional shapes; the guarantee does not override the [qualified cross-API tier table](#cross-api-compatibility).

<!-- d3d12-review-alert:end:sharing-interop:SH-d3d11-guarantee-scope:0 -->

<a id="nt-handles"></a>

## NT handles, names, security, and lifetime

<!-- d3d12-review-alert:begin:sharing-interop:SH-handle-lifetime:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> An NT handle and a COM interface reference are separate references. `CreateSharedHandle` exports an existing shared object; `OpenSharedHandleByName` obtains another NT handle; `OpenSharedHandle` obtains an interface on the opening device. Neither export nor open copies resource contents.

<!-- d3d12-review-alert:end:sharing-interop:SH-handle-lifetime:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-handle-lifetime:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The application owns each successfully returned NT handle and must close it with [CloseHandle](https://learn.microsoft.com/en-us/windows/win32/api/handleapi/nf-handleapi-closehandle) when it no longer needs that handle. The application must release each returned COM interface reference separately. Closing a handle does not release an independently opened interface, and releasing an interface does not close an exported NT handle. A live shared handle can retain shared backing after the exporting interface is released. Backing lifetime, device-local object lifetime, and completion of GPU uses are separate; [execution lifetime](execution.md#lifetime) still requires the application to keep referenced objects and storage valid until GPU use completes.

<!-- d3d12-review-alert:end:sharing-interop:SH-handle-lifetime:1 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-handle-lifetime:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> An NT handle value is process-local. To give another process a handle, an application must use an applicable Windows transfer mechanism, such as [DuplicateHandle](https://learn.microsoft.com/en-us/windows/win32/api/handleapi/nf-handleapi-duplicatehandle), permitted handle inheritance, or reopening the object's name with the required access. Copying the numeric value to another process is not duplication. A duplicated or inherited handle refers to the same shared object, not a snapshot of its data.

<!-- d3d12-review-alert:end:sharing-interop:SH-handle-lifetime:2 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-handle-lifetime:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `SECURITY_ATTRIBUTES` separates the object's security descriptor from the returned handle's inheritance attribute. Handle inheritance also depends on the child-process creation rules. The object's access-control policy is not bypassed by knowing its name, and a COM pointer is not a cross-process handle. The [Windows handle and security contracts](https://learn.microsoft.com/en-us/windows/win32/api/wtypesbase/ns-wtypesbase-security_attributes) define duplication, inheritance, and access checks.

<!-- d3d12-review-alert:end:sharing-interop:SH-handle-lifetime:3 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-names:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A name denotes an object in a Windows object namespace; it is not a COM identity or a synchronization primitive. The name and security descriptor must remain valid for the duration of the API call; the returned handle does not borrow the caller's string or security-descriptor storage. Use of a name can conflict with a name already created by another participant; a name alone does not authenticate its creator.

<!-- d3d12-review-alert:end:sharing-interop:SH-names:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-names:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `Global\` and `Local\` select the global and session namespaces respectively, with case-sensitive prefixes. An unprefixed name uses the applicable Windows default namespace. The [kernel object namespace contract](https://learn.microsoft.com/en-us/windows/win32/termserv/kernel-object-namespaces) defines session and global namespace behavior; it does not grant D3D12 handles privileges merely because another kind of kernel object has different global-creation requirements. The D3D12 method's name length, case sensitivity, conflict result, and access requirements are specified under [CreateSharedHandle](#id3d12device-createsharedhandle).

<!-- d3d12-review-alert:end:sharing-interop:SH-names:1 -->

<a id="sharing-synchronization"></a>

## Synchronization is separate from sharing

<!-- d3d12-review-alert:begin:sharing-interop:SH-sync:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Exporting, opening, duplicating, naming, or closing a shared handle does not signal or wait for a fence, submit work, transfer resource ownership, perform a resource barrier, or acquire or release a keyed mutex.

<!-- d3d12-review-alert:end:sharing-interop:SH-sync:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-sync:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Applications must coordinate conflicting accesses using the [queue signal](execution.md#queue-signal), [queue wait](execution.md#queue-waits), [completed-value observation](execution.md#id3d12fencegetcompletedvalue), and [event notification](execution.md#id3d12fenceseteventoncompletion) contracts, together with the applicable [enhanced barriers](synchronization.md#enhanced-barriers), [legacy barriers](synchronization.md#legacy-barriers), and [aliasing](synchronization.md#enhanced-aliasing) requirements. A fence value orders only the work established by its signal and wait; sharing a fence does not associate it automatically with a particular resource or make an unrelated signal proof that a resource is no longer in use.

<!-- d3d12-review-alert:end:sharing-interop:SH-sync:1 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-sync:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> These common queue/fence requirements apply to direct, compute, and copy queues and to video decode, video process, and video encode queues where they use the common command-queue contract. The full [fence flag and observation requirements](execution.md#fence-observation-requirements) include cross-adapter, non-monitored, and command-list-barrier fence combinations; exporting a fence does not remove those requirements. The [queue/layout/access compatibility rules](synchronization.md#queue-compatibility) still determine which resource accesses each queue can perform.

<!-- d3d12-review-alert:end:sharing-interop:SH-sync:2 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-sync:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> When the application uses a fence to synchronize work across adapters, the fence must be created for cross-adapter sharing under the [full fence-creation flag requirements](execution.md#fence-observation-requirements). Before a consumer uses shared bytes, the producer's writes must be made available using the applicable barrier and queue-ordering rules; after consumption, a separate return signal can make reuse safe. Opening a handle is not that handoff.

<!-- d3d12-review-alert:end:sharing-interop:SH-sync:3 -->

<a id="id3d12device-createsharedhandle"></a>

## ID3D12Device::CreateSharedHandle

### Declaration

```cpp
HRESULT CreateSharedHandle(
    ID3D12DeviceChild* pObject,
    const SECURITY_ATTRIBUTES* pAttributes,
    DWORD Access,
    LPCWSTR Name,
    HANDLE* pHandle);
```

### Behavior

Creates a shared handle to <ins><!-- d3d12-review-inline:begin:sharing-interop:API-CreateSharedHandle-behavior:0 -->a heap, resource, fence, or protected-resource session object.<!-- d3d12-review-inline:end:sharing-interop:API-CreateSharedHandle-behavior:0 --></ins>

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedHandle-context:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pObject` must be a valid object of a shareable kind described in [shared backing](#shared-backing), with the corresponding shared creation flag for a heap, committed resource, or fence. Protected-resource sessions are always shared and do not use those flags. `pHandle` must point to writable `HANDLE` storage. A placed or reserved resource is not a valid export object. A null `Name` requests an unnamed handle.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedHandle-context:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedHandle-context:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The method is free-threaded. It does not acquire a keyed mutex or initialize a fence value. [NT-handle lifetime and transfer](#nt-handles) apply to the returned handle.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedHandle-context:1 -->

### Parameters

#### pObject (input)

<ins><!-- d3d12-review-inline:begin:sharing-interop:API-CreateSharedHandle-parameters:1 -->Type: [`ID3D12DeviceChild*`](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nn-d3d12-id3d12devicechild)<!-- d3d12-review-inline:end:sharing-interop:API-CreateSharedHandle-parameters:1 --></ins>

A pointer to the [ID3D12DeviceChild](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nn-d3d12-id3d12devicechild) interface that represents <ins><!-- d3d12-review-inline:begin:sharing-interop:API-CreateSharedHandle-parameters:2 -->the heap, resource, fence, or protected-resource session object for which to create a shared handle<!-- d3d12-review-inline:end:sharing-interop:API-CreateSharedHandle-parameters:2 --></ins>. The following interfaces (derived from **ID3D12DeviceChild**) are supported:

- [ID3D12Heap](resources.md#heap-description)
- [ID3D12Resource](resources.md#resource-storage)
- [ID3D12Fence](execution.md#fence-operations)
- <ins><!-- d3d12-review-inline:begin:sharing-interop:API-CreateSharedHandle-parameters:3 -->[ID3D12ProtectedResourceSession](../ProtectedResources.md#interface-id3d12protectedresourcesession)<!-- d3d12-review-inline:end:sharing-interop:API-CreateSharedHandle-parameters:3 --></ins>

#### pAttributes (input, optional)

<ins><!-- d3d12-review-inline:begin:sharing-interop:API-CreateSharedHandle-parameters:5 -->Type: [`const SECURITY_ATTRIBUTES*`](https://learn.microsoft.com/en-us/windows/win32/api/wtypesbase/ns-wtypesbase-security_attributes)<!-- d3d12-review-inline:end:sharing-interop:API-CreateSharedHandle-parameters:5 --></ins>

A pointer to a [SECURITY_ATTRIBUTES](https://learn.microsoft.com/en-us/windows/win32/api/wtypesbase/ns-wtypesbase-security_attributes) structure that contains two separate but related data members: an optional security descriptor, and a **Boolean** value that determines whether child processes can inherit the returned handle.

Set this parameter to **NULL** if you want child processes that the application might create to not inherit the handle returned by **CreateSharedHandle**, and if you want the resource that is associated with the returned handle to get a default security descriptor.

The **lpSecurityDescriptor** member of the structure specifies a [SECURITY_DESCRIPTOR](https://learn.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-security_descriptor) for the resource. Set this member to **NULL** if you want the runtime to assign a default security descriptor to the resource that is associated with the returned handle. The ACLs in the default security descriptor for the resource come from the primary or impersonation token of the creator. For more info, see [Synchronization Object Security and Access Rights](https://learn.microsoft.com/en-us/windows/desktop/Sync/synchronization-object-security-and-access-rights).

#### Access (input)

<ins><!-- d3d12-review-inline:begin:sharing-interop:API-CreateSharedHandle-parameters:10 -->Type: [`DWORD`](https://learn.microsoft.com/en-us/windows/desktop/WinProg/windows-data-types)<!-- d3d12-review-inline:end:sharing-interop:API-CreateSharedHandle-parameters:10 --></ins>

Currently the only value this parameter accepts is <ins><!-- d3d12-review-inline:begin:sharing-interop:API-CreateSharedHandle-parameters:11 -->`GENERIC_ALL`<!-- d3d12-review-inline:end:sharing-interop:API-CreateSharedHandle-parameters:11 --></ins>.

#### Name (input, optional)

<ins><!-- d3d12-review-inline:begin:sharing-interop:API-CreateSharedHandle-parameters:13 -->Type: `LPCWSTR`<!-- d3d12-review-inline:end:sharing-interop:API-CreateSharedHandle-parameters:13 --></ins>

A **NULL**-terminated **UNICODE** string that contains the name to associate with the <ins><!-- d3d12-review-inline:begin:sharing-interop:API-CreateSharedHandle-parameters:14 -->shared object<!-- d3d12-review-inline:end:sharing-interop:API-CreateSharedHandle-parameters:14 --></ins>. The name is limited to <ins><!-- d3d12-review-inline:begin:sharing-interop:API-CreateSharedHandle-parameters:14 -->`MAX_PATH`<!-- d3d12-review-inline:end:sharing-interop:API-CreateSharedHandle-parameters:14 --></ins> characters. Name comparison is case-sensitive.

If *Name* matches the name of an existing resource, **CreateSharedHandle** fails with [DXGI_ERROR_NAME_ALREADY_EXISTS](https://learn.microsoft.com/en-us/windows/desktop/direct3ddxgi/dxgi-error). This occurs because these objects share the same namespace.

The name can have a "Global" or "Local" prefix to explicitly create the object in the global or session namespace. The remainder of the name can contain any character except the backslash character (\). For more information, see [Kernel Object Namespaces](https://learn.microsoft.com/en-us/windows/desktop/TermServ/kernel-object-namespaces). Fast user switching is implemented using Terminal Services sessions. Kernel object names must follow the guidelines outlined for Terminal Services so that applications can support multiple users.

The object can be created in a private namespace. For more information, see [Object Namespaces](https://learn.microsoft.com/en-us/windows/desktop/Sync/object-namespaces).

#### pHandle (output)

<ins><!-- d3d12-review-inline:begin:sharing-interop:API-CreateSharedHandle-parameters:19 -->Type: [`HANDLE*`](https://learn.microsoft.com/en-us/windows/desktop/WinProg/windows-data-types)<!-- d3d12-review-inline:end:sharing-interop:API-CreateSharedHandle-parameters:19 --></ins>

A pointer to a variable that receives <ins><!-- d3d12-review-inline:begin:sharing-interop:API-CreateSharedHandle-parameters:20 -->the NT HANDLE value to the object to share<!-- d3d12-review-inline:end:sharing-interop:API-CreateSharedHandle-parameters:20 --></ins>. <ins><!-- d3d12-review-inline:begin:sharing-interop:API-CreateSharedHandle-parameters:20 -->You can use this handle in calls to access the object.<!-- d3d12-review-inline:end:sharing-interop:API-CreateSharedHandle-parameters:20 --></ins>

### Return values

<ins><!-- d3d12-review-inline:begin:sharing-interop:API-CreateSharedHandle-returns:0 -->Type: [`HRESULT`](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)<!-- d3d12-review-inline:end:sharing-interop:API-CreateSharedHandle-returns:0 --></ins>

Returns <ins><!-- d3d12-review-inline:begin:sharing-interop:API-CreateSharedHandle-returns:1 -->`S_OK`<!-- d3d12-review-inline:end:sharing-interop:API-CreateSharedHandle-returns:1 --></ins> if successful; otherwise, returns one of the following values:

- <ins><!-- d3d12-review-inline:begin:sharing-interop:API-CreateSharedHandle-returns:2 -->`E_INVALIDARG` for null required object/output pointers, unsupported object kinds, missing shared creation flags, or an unsupported access value. Other invalid calls can fail with [DXGI_ERROR_INVALID_CALL](https://learn.microsoft.com/en-us/windows/desktop/direct3ddxgi/dxgi-error).<!-- d3d12-review-inline:end:sharing-interop:API-CreateSharedHandle-returns:2 --></ins>
- [DXGI_ERROR_NAME_ALREADY_EXISTS](https://learn.microsoft.com/en-us/windows/desktop/direct3ddxgi/dxgi-error) if the supplied name of the resource to share is already associated with another resource.
- <ins><!-- d3d12-review-inline:begin:sharing-interop:API-CreateSharedHandle-returns:2 -->`E_ACCESSDENIED` if the object is being created in a protected namespace.<!-- d3d12-review-inline:end:sharing-interop:API-CreateSharedHandle-returns:2 --></ins>
- <ins><!-- d3d12-review-inline:begin:sharing-interop:API-CreateSharedHandle-returns:2 -->`E_OUTOFMEMORY` if sufficient memory is not available to create the handle.<!-- d3d12-review-inline:end:sharing-interop:API-CreateSharedHandle-returns:2 --></ins>
- Possibly other error codes that are described in the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues) topic.

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedHandle-result-context:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A failure does not guarantee that `*pHandle` has been set to null. No handle has been returned to the application unless the call succeeds.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedHandle-result-context:0 -->

<a id="id3d12device-opensharedhandle"></a>

## ID3D12Device::OpenSharedHandle

### Declaration

```cpp
HRESULT OpenSharedHandle(
    HANDLE NTHandle,
    REFIID riid,
    void** ppvObj);
```

### Behavior

Opens a handle for <ins><!-- d3d12-review-inline:begin:sharing-interop:API-OpenSharedHandle-behavior:0 -->shared resources, shared heaps, shared fences, and protected-resource sessions<!-- d3d12-review-inline:end:sharing-interop:API-OpenSharedHandle-behavior:0 --></ins>, <ins><!-- d3d12-review-inline:begin:sharing-interop:API-OpenSharedHandle-behavior:0 -->by using `HANDLE` and `REFIID`.<!-- d3d12-review-inline:end:sharing-interop:API-OpenSharedHandle-behavior:0 --></ins>

<!-- d3d12-review-alert:begin:sharing-interop:API-OpenSharedHandle-context:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The runtime opens the shared object on this device. `riid` must be supported by the kind of object represented by `NTHandle`; requesting a heap interface from a committed-resource handle does not expose its implicit heap. The four supported kinds in [shared backing](#shared-backing) are not interchangeable.

<!-- d3d12-review-alert:end:sharing-interop:API-OpenSharedHandle-context:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:API-OpenSharedHandle-context:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The handle remains owned by the caller; this method does not consume or close it. The application owns the returned interface reference. Opening an existing shared fence preserves the fence's value and properties. Opening a resource or heap does not import another process's virtual address or copy its contents.

<!-- d3d12-review-alert:end:sharing-interop:API-OpenSharedHandle-context:1 -->

<!-- d3d12-review-alert:begin:sharing-interop:API-OpenSharedHandle-context:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `NTHandle` must be valid in the caller's process. It can be an exported, duplicated, inherited, or name-opened compatible NT handle, including an NT resource or fence handle exported by a compatible D3D11 sharing path. It is not a numeric handle copied from another process without Windows handle transfer.

<!-- d3d12-review-alert:end:sharing-interop:API-OpenSharedHandle-context:2 -->

<!-- d3d12-review-alert:begin:sharing-interop:API-OpenSharedHandle-context:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> For linked-node resources and heaps, node masks are inherited from the shared objects, with the runtime translating driver node remappings as needed; the method has no new node-mask parameter. The full [heap-node properties](resources.md#heap-properties) and [device-node identity](devices-and-capabilities.md#identity) contracts apply.

<!-- d3d12-review-alert:end:sharing-interop:API-OpenSharedHandle-context:3 -->

### Parameters

#### NTHandle (input)

<ins><!-- d3d12-review-inline:begin:sharing-interop:API-OpenSharedHandle-parameters:1 -->Type: `HANDLE`<!-- d3d12-review-inline:end:sharing-interop:API-OpenSharedHandle-parameters:1 --></ins>

<ins><!-- d3d12-review-inline:begin:sharing-interop:API-OpenSharedHandle-parameters:2 -->A compatible NT handle, such as one output by the call to<!-- d3d12-review-inline:end:sharing-interop:API-OpenSharedHandle-parameters:2 --></ins> [ID3D12Device::CreateSharedHandle](#id3d12device-createsharedhandle).

#### riid (input)

<ins><!-- d3d12-review-inline:begin:sharing-interop:API-OpenSharedHandle-parameters:4 -->Type: `REFIID`<!-- d3d12-review-inline:end:sharing-interop:API-OpenSharedHandle-parameters:4 --></ins>

The globally unique identifier (**GUID**) for one of the following interfaces:

- [ID3D12Heap](resources.md#heap-description)
- [ID3D12Resource](resources.md#resource-storage)
- [ID3D12Fence](execution.md#fence-operations)
- <ins><!-- d3d12-review-inline:begin:sharing-interop:API-OpenSharedHandle-parameters:6 -->[ID3D12ProtectedResourceSession](../ProtectedResources.md#interface-id3d12protectedresourcesession)<!-- d3d12-review-inline:end:sharing-interop:API-OpenSharedHandle-parameters:6 --></ins>

 The **REFIID**, or **GUID**, of the interface can be obtained by using the \_\_uuidof() macro. For example, \_\_uuidof(ID3D12Heap) will get the **GUID** of the interface to a heap.

#### ppvObj (output, optional)

<ins><!-- d3d12-review-inline:begin:sharing-interop:API-OpenSharedHandle-parameters:8 -->Type: `void**`<!-- d3d12-review-inline:end:sharing-interop:API-OpenSharedHandle-parameters:8 --></ins>

A pointer to a memory block that receives a pointer to one of the following interfaces:

- [ID3D12Heap](resources.md#heap-description)
- [ID3D12Resource](resources.md#resource-storage)
- [ID3D12Fence](execution.md#fence-operations)
- <ins><!-- d3d12-review-inline:begin:sharing-interop:API-OpenSharedHandle-parameters:10 -->[ID3D12ProtectedResourceSession](../ProtectedResources.md#interface-id3d12protectedresourcesession)<!-- d3d12-review-inline:end:sharing-interop:API-OpenSharedHandle-parameters:10 --></ins>

### Return values

<ins><!-- d3d12-review-inline:begin:sharing-interop:API-OpenSharedHandle-returns:0 -->Type: [`HRESULT`](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)<!-- d3d12-review-inline:end:sharing-interop:API-OpenSharedHandle-returns:0 --></ins>

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/win32/direct3d12/d3d12-graphics-reference-returnvalues).

<!-- d3d12-review-alert:begin:sharing-interop:API-OpenSharedHandle-result-context:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A valid shared object that does not support `riid` fails with `E_NOINTERFACE`. Other failures include an invalid or inaccessible shared handle and an incompatible opening device or description. Failure need not clear `*ppvObj` on every path.

<!-- d3d12-review-alert:end:sharing-interop:API-OpenSharedHandle-result-context:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:API-OpenSharedHandle-result-context:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `ppvObj` may be null to request validation only. For every supported shared-object kind, the runtime must validate the applicable handle, object kind, requested `riid`, opening-device compatibility, and other opening conditions. Successful validation must return `S_FALSE` without returning a COM interface reference to the application; failed validation returns the appropriate failure code. A non-null output must point to writable interface-pointer storage.

<!-- d3d12-review-alert:end:sharing-interop:API-OpenSharedHandle-result-context:1 -->

<!-- d3d12-review-alert:begin:sharing-interop:API-OpenSharedHandle-result-context:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Successful validation is not a guarantee of success for a later call with a non-null output: allocation, driver, or changed conditions can still cause failure. The validation-only result does not promise that the runtime or driver performs no internal work.

<!-- d3d12-review-alert:end:sharing-interop:API-OpenSharedHandle-result-context:2 -->

<a id="id3d12device-opensharedhandlebyname"></a>

## ID3D12Device::OpenSharedHandleByName

### Declaration

```cpp
HRESULT OpenSharedHandleByName(
    LPCWSTR Name,
    DWORD Access,
    HANDLE* pNTHandle);
```

### Behavior

Opens a handle for <ins><!-- d3d12-review-inline:begin:sharing-interop:API-OpenSharedHandleByName-behavior:0 -->shared resources, shared heaps, shared fences, and protected-resource sessions<!-- d3d12-review-inline:end:sharing-interop:API-OpenSharedHandleByName-behavior:0 --></ins>, <ins><!-- d3d12-review-inline:begin:sharing-interop:API-OpenSharedHandleByName-behavior:0 -->by using `Name` and `Access`.<!-- d3d12-review-inline:end:sharing-interop:API-OpenSharedHandleByName-behavior:0 --></ins>

<!-- d3d12-review-alert:begin:sharing-interop:API-OpenSharedHandleByName-context:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `Name` must point to the null-terminated Unicode name of an existing shared object, using the [same namespace and case-sensitive naming rules](#id3d12device-createsharedhandle) as creation. `Access` is `GENERIC_ALL`; the caller must have the required access. `pNTHandle` must point to writable `HANDLE` storage.

<!-- d3d12-review-alert:end:sharing-interop:API-OpenSharedHandleByName-context:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:API-OpenSharedHandleByName-context:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method returns an NT handle, not an `ID3D12Resource`, `ID3D12Heap`, `ID3D12Fence`, or `ID3D12ProtectedResourceSession` pointer. [OpenSharedHandle](#id3d12device-opensharedhandle) obtains the corresponding interface. The returned handle is not inheritable; Windows duplication can create an inheritable handle when permitted. The application must close the returned handle separately from releasing an opened interface.

<!-- d3d12-review-alert:end:sharing-interop:API-OpenSharedHandleByName-context:1 -->

### Parameters

#### Name (input)

<ins><!-- d3d12-review-inline:begin:sharing-interop:API-OpenSharedHandleByName-parameters:1 -->Type: `LPCWSTR`<!-- d3d12-review-inline:end:sharing-interop:API-OpenSharedHandleByName-parameters:1 --></ins>

The name that was optionally passed as the *Name* parameter in the call to [ID3D12Device::CreateSharedHandle](#id3d12device-createsharedhandle).

#### Access (input)

<ins><!-- d3d12-review-inline:begin:sharing-interop:API-OpenSharedHandleByName-parameters:4 -->Type: `DWORD`<!-- d3d12-review-inline:end:sharing-interop:API-OpenSharedHandleByName-parameters:4 --></ins>

The access level that was specified in the *Access* parameter in the call to [ID3D12Device::CreateSharedHandle](#id3d12device-createsharedhandle).

#### pNTHandle (output)

<ins><!-- d3d12-review-inline:begin:sharing-interop:API-OpenSharedHandleByName-parameters:7 -->Type: `HANDLE*`<!-- d3d12-review-inline:end:sharing-interop:API-OpenSharedHandleByName-parameters:7 --></ins>

Pointer to the shared handle.

### Return values

<ins><!-- d3d12-review-inline:begin:sharing-interop:API-OpenSharedHandleByName-returns:0 -->Type: [`HRESULT`](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)<!-- d3d12-review-inline:end:sharing-interop:API-OpenSharedHandleByName-returns:0 --></ins>

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

<!-- d3d12-review-alert:begin:sharing-interop:API-OpenSharedHandleByName-result-context:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A successful call returns `S_OK`. A missing name, access denial, or invalid access request fails rather than creating a new object. On failure the Windows implementation sets `*pNTHandle` to null. The output pointer itself is required; a null output pointer is not a validation-only probe.

<!-- d3d12-review-alert:end:sharing-interop:API-OpenSharedHandleByName-result-context:0 -->

<a id="compatibility-creation"></a>

## Compatibility creation and stored properties

<!-- d3d12-review-alert:begin:sharing-interop:SH-compatibility-purpose:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `ID3D12CompatibilityDevice` is obtained from a D3D12 device using `QueryInterface`. It creates shared resources or heaps with compatibility metadata and reflects properties retained with shared backing. It is an `IUnknown`-derived compatibility interface; the methods below are declared on it, not inherited methods of `ID3D12Device`.

<!-- d3d12-review-alert:end:sharing-interop:SH-compatibility-purpose:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-compatibility-purpose:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Compatibility creation records the requested sharing mode when the backing is created. It is not a way to add a keyed mutex, change NT versus non-NT sharing, or retrofit D3D11 creation flags onto an already-created resource. These methods are used by API implementations layered on D3D12, and their compatibility flags must agree with the resource's actual capabilities. Ordinary D3D12 sharing uses the [NT-handle methods](#id3d12device-createsharedhandle) and does not implicitly acquire keyed-mutex behavior.

<!-- d3d12-review-alert:end:sharing-interop:SH-compatibility-purpose:1 -->

<a id="compatibility-flags"></a>

### D3D12_COMPATIBILITY_SHARED_FLAGS

```cpp
typedef enum D3D12_COMPATIBILITY_SHARED_FLAGS
{
    D3D12_COMPATIBILITY_SHARED_FLAG_NONE          = 0,
    D3D12_COMPATIBILITY_SHARED_FLAG_NON_NT_HANDLE = 0x1,
    D3D12_COMPATIBILITY_SHARED_FLAG_KEYED_MUTEX = 0x2,
    D3D12_COMPATIBILITY_SHARED_FLAG_9_ON_12 = 0x4,

} D3D12_COMPATIBILITY_SHARED_FLAGS;
```

<!-- d3d12-review-alert:begin:sharing-interop:SH-compat-flags:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Flag | Meaning |
> |---|---|
> | `D3D12_COMPATIBILITY_SHARED_FLAG_NONE` (`0`) | Default NT-handle sharing mode; no keyed mutex or 9-on-12 allocation attribution is requested. |
> | `D3D12_COMPATIBILITY_SHARED_FLAG_NON_NT_HANDLE` (`0x1`) | Requests legacy non-NT shared-handle compatibility rather than NT-handle export. |
> | `D3D12_COMPATIBILITY_SHARED_FLAG_KEYED_MUTEX` (`0x2`) | Requests keyed-mutex compatibility metadata and backing synchronization objects. This flag does not itself acquire or release the mutex. |
> | `D3D12_COMPATIBILITY_SHARED_FLAG_9_ON_12` (`0x4`) | Identifies allocation compatibility for a resource created by 9-on-12; it is not permission to treat a D3D11 format restriction as a D3D9 restriction. |

<!-- d3d12-review-alert:end:sharing-interop:SH-compat-flags:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-compat-flags:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> An application must not set undeclared flag bits. `CreateSharedResource` and `CreateSharedHeap` have different cross-adapter restrictions, specified below. Non-NT shared handles are not NT handles: the application must not call `CloseHandle` or `DuplicateHandle` on a reflected non-NT handle. Its validity is tied to the backing's lifetime; the creator must keep the shared resource alive until intended consumers have opened it.

<!-- d3d12-review-alert:end:sharing-interop:SH-compat-flags:1 -->

<a id="d3d11-resource-flags"></a>

### D3D11_RESOURCE_FLAGS metadata

```cpp
typedef struct D3D11_RESOURCE_FLAGS {
  UINT BindFlags;
  UINT MiscFlags;
  UINT CPUAccessFlags;
  UINT StructureByteStride;
} D3D11_RESOURCE_FLAGS;
```

<!-- d3d12-review-alert:begin:sharing-interop:SH-flags11-fields:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> For compatibility creation, these four fields store D3D11 creation metadata:

<!-- d3d12-review-alert:end:sharing-interop:SH-flags11-fields:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-flags11-fields:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Field | Stored meaning and compatibility constraint |
> |---|---|
> | `BindFlags` | A `D3D11_BIND_FLAG` mask. Requested binds must be supported by the D3D12 resource, not merely by the D3D11 enum. Buffers can carry vertex, index, constant-buffer, and stream-output attribution. Shader-resource binding requires that `D3D12_RESOURCE_FLAG_DENY_SHADER_RESOURCE` is clear; render-target, depth-stencil, and UAV binds require `D3D12_RESOURCE_FLAG_ALLOW_RENDER_TARGET`, `D3D12_RESOURCE_FLAG_ALLOW_DEPTH_STENCIL`, and `D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS`, respectively. Decoder and video-encoder attribution is permitted for a shared `Texture2D` with `D3D12_HEAP_FLAG_ALLOW_DISPLAY`; otherwise it requires that `ALLOW_DISPLAY` is absent and the format is cross-D3D-API-shareable. This metadata check does not define the operational scope of `D3D12_FEATURE_DISPLAYABLE` or make a resource usable by a video operation that rejects its description. |
> | `MiscFlags` | A `D3D11_RESOURCE_MISC_FLAG` mask retained with the resource. Shared and keyed-mutex/NT-handle declarations must agree with `CompatibilityFlags`; the exact checks are specified under `CreateSharedResource`. This field is not an instruction to invoke a D3D11 operation on a D3D12 object. |
> | `CPUAccessFlags` | A `D3D11_CPU_ACCESS_FLAG` mask constrained by the D3D12 heap's CPU access. Ordinary shared creation uses CPU-inaccessible heaps, so it cannot gain CPU access through this metadata. |
> | `StructureByteStride` | Size in bytes of each element when the buffer is a D3D11 structured buffer. It is stored metadata, not the D3D12 GPU virtual address, a heap offset, or a texture row pitch. |

<!-- d3d12-review-alert:end:sharing-interop:SH-flags11-fields:1 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-flags11-fields:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [D3D11 bind flags](https://learn.microsoft.com/en-us/windows/win32/api/d3d11/ne-d3d11-d3d11_bind_flag), [miscellaneous flags](https://learn.microsoft.com/en-us/windows/win32/api/d3d11/ne-d3d11-d3d11_resource_misc_flag), and [CPU-access flags](https://learn.microsoft.com/en-us/windows/win32/api/d3d11/ne-d3d11-d3d11_cpu_access_flag) retain their D3D11 meanings. The similarly named `D3D11_RESOURCE_FLAGS` wrapping contract's flag-inference and `Map` behavior must not be applied to `CreateSharedResource` as though the two methods were the same operation.

<!-- d3d12-review-alert:end:sharing-interop:SH-flags11-fields:2 -->

<a id="creator-identity"></a>

### Creator identity

<!-- d3d12-review-alert:begin:sharing-interop:SH-creator-purpose:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Creator identifiers in `d3d12compatibility.h` identify components that implement APIs on D3D12. They are GUID identities, not resource descriptions, shared handles, access rights, or reflection selectors. [ID3D12Device9::CreateCommandQueue1](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12device9-createcommandqueue1) accepts a `CreatorID` independently of the `riid` for the returned queue.

<!-- d3d12-review-alert:end:sharing-interop:SH-creator-purpose:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-creator-purpose:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The reserved identifiers are:

<!-- d3d12-review-alert:end:sharing-interop:SH-creator-purpose:1 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-creator-purpose:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Identifier | GUID |
> |---|---|
> | `D3D11On12CreatorID` | `edbf5678-2960-4e81-8429-99d4b2630c4e` |
> | `D3D9On12CreatorID` | `fffcbb7f-15d3-42a2-841e-9d8d32f37ddd` |
> | `OpenGLOn12CreatorID` | `6bb3cd34-0d19-45ab-97ed-d720ba3dfc80` |
> | `OpenCLOn12CreatorID` | `3f76bb74-91b5-4a88-b126-20ca0331cd60` |
> | `VulkanOn12CreatorID` | `bc806e01-3052-406c-a3e8-9fc07f048f98` |
> | `DirectMLTensorFlowCreatorID` | `cb7490ac-8a0f-44ec-9b7b-6f4cafe8e9ab` |
> | `DirectMLPyTorchCreatorID` | `af029192-fba1-4b05-9116-235e06560354` |
> | `DirectMLWebNNCreatorID` | `fdf01a76-1e11-450f-902b-74f04ea08094` |

<!-- d3d12-review-alert:end:sharing-interop:SH-creator-purpose:2 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-creator-purpose:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The three compatibility methods in this chapter have no `CreatorID` parameter. A creator identifier does not waive description, format, security, or synchronization requirements.

<!-- d3d12-review-alert:end:sharing-interop:SH-creator-purpose:3 -->

<a id="reflection-selectors"></a>

### D3D12_REFLECT_SHARED_PROPERTY

```cpp
typedef enum D3D12_REFLECT_SHARED_PROPERTY
{
    D3D12_REFLECT_SHARED_PROPERTY_D3D11_RESOURCE_FLAGS,       // D3D11_RESOURCE_FLAGS
    D3D12_REFELCT_SHARED_PROPERTY_COMPATIBILITY_SHARED_FLAGS, // D3D12_COMPATIBILITY_SHARED_FLAGS
    D3D12_REFLECT_SHARED_PROPERTY_NON_NT_SHARED_HANDLE,       // HANDLE
} D3D12_REFLECT_SHARED_PROPERTY;
```

<!-- d3d12-review-alert:begin:sharing-interop:SH-reflect-selector-types:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The published spelling `D3D12_REFELCT_SHARED_PROPERTY_COMPATIBILITY_SHARED_FLAGS` is part of the API identifier and is not corrected to `REFLECT`.

<!-- d3d12-review-alert:end:sharing-interop:SH-reflect-selector-types:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-reflect-selector-types:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Selector | Value | Payload and exact `DataSize` | Applicable object and result ownership |
> |---|---|---|---|
> | `D3D12_REFLECT_SHARED_PROPERTY_D3D11_RESOURCE_FLAGS` | `0` | `D3D11_RESOURCE_FLAGS`; `sizeof(D3D11_RESOURCE_FLAGS)` (four `UINT` fields, 16 bytes) | Resource created/opened with retained D3D11 creation metadata. Returns a value copy, not an inferred flags structure or a pointer to runtime storage. |
> | `D3D12_REFELCT_SHARED_PROPERTY_COMPATIBILITY_SHARED_FLAGS` | `1` | `D3D12_COMPATIBILITY_SHARED_FLAGS`; `sizeof(D3D12_COMPATIBILITY_SHARED_FLAGS)` | Shared heap or committed resource's shared implicit heap. Returns the retained compatibility bit mask by value. |
> | `D3D12_REFLECT_SHARED_PROPERTY_NON_NT_SHARED_HANDLE` | `2` | `HANDLE`; `sizeof(HANDLE)` in the caller's ABI | Shared heap or committed resource with non-NT handle compatibility. Returns a borrowed non-NT shared-handle value; it is not a newly owned NT handle and must not be closed or duplicated with Windows NT-handle functions. |

<!-- d3d12-review-alert:end:sharing-interop:SH-reflect-selector-types:1 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-reflect-selector-types:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The caller must provide a valid object of the indicated kind and writable, suitably aligned storage for the selected payload. An application must use the exact payload size, not a maximum-sized union or a zero-size discovery call. `sizeof(HANDLE)` varies with the process ABI; it must not be hardcoded as four bytes in a 64-bit process. An explicit heap can supply heap-sharing properties, but it does not have resource-specific D3D11 creation metadata. A placed resource is not its heap and does not acquire heap reflection properties merely by residing in shared storage.

<!-- d3d12-review-alert:end:sharing-interop:SH-reflect-selector-types:2 -->

<a id="id3d12compatibilitydevice-createsharedresource"></a>

## ID3D12CompatibilityDevice::CreateSharedResource

### Declaration

```cpp
HRESULT CreateSharedResource(
    const D3D12_HEAP_PROPERTIES* pHeapProperties,
    D3D12_HEAP_FLAGS HeapFlags,
    const D3D12_RESOURCE_DESC* pDesc,
    D3D12_RESOURCE_STATES InitialResourceState,
    const D3D12_CLEAR_VALUE* pOptimizedClearValue,
    const D3D11_RESOURCE_FLAGS* pFlags11,
    D3D12_COMPATIBILITY_SHARED_FLAGS CompatibilityFlags,
    ID3D12LifetimeTracker* pLifetimeTracker,
    ID3D12SwapChainAssistant* pOwningSwapchain,
    REFIID riid,
    void** ppResource);
```

### Behavior

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedResource-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Creates a committed resource and its implicit heap, with compatibility sharing properties and optional D3D11 creation metadata. The full [committed-resource creation contract](resources.md#create-committed-resource), [shared creation validation](resources.md#creation-contracts), [optimized-clear-value requirements](resources.md#optimized-clear-value), and [initial resource-state rules](synchronization.md#legacy-initial-state) apply.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedResource-behavior:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedResource-behavior:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `HeapFlags` must contain `D3D12_HEAP_FLAG_SHARED`. If it contains `D3D12_HEAP_FLAG_SHARED_CROSS_ADAPTER`, `CompatibilityFlags` must be `D3D12_COMPATIBILITY_SHARED_FLAG_NONE`; the [cross-adapter committed-resource restrictions](#cross-adapter-heaps) still apply. Undeclared compatibility flag bits are invalid.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedResource-behavior:1 -->

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedResource-behavior:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> When `pFlags11` is non-null:

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedResource-behavior:2 -->

- <ins><!-- d3d12-review-inline:begin:sharing-interop:API-CreateSharedResource-behavior:3 -->`D3D11_RESOURCE_MISC_SHARED_KEYEDMUTEX` must be present if and only if `D3D12_COMPATIBILITY_SHARED_FLAG_KEYED_MUTEX` is present.<!-- d3d12-review-inline:end:sharing-interop:API-CreateSharedResource-behavior:3 --></ins>
- <ins><!-- d3d12-review-inline:begin:sharing-interop:API-CreateSharedResource-behavior:3 -->`D3D11_RESOURCE_MISC_SHARED_NTHANDLE` must be present if and only if `D3D12_COMPATIBILITY_SHARED_FLAG_NON_NT_HANDLE` is absent.<!-- d3d12-review-inline:end:sharing-interop:API-CreateSharedResource-behavior:3 --></ins>
- <ins><!-- d3d12-review-inline:begin:sharing-interop:API-CreateSharedResource-behavior:3 -->At least one of `D3D11_RESOURCE_MISC_SHARED` and `D3D11_RESOURCE_MISC_SHARED_KEYEDMUTEX` must be present.<!-- d3d12-review-inline:end:sharing-interop:API-CreateSharedResource-behavior:3 --></ins>
- <ins><!-- d3d12-review-inline:begin:sharing-interop:API-CreateSharedResource-behavior:3 -->Requested bind flags and CPU-access flags must be supported by the D3D12 resource and heap, as defined by [the metadata fields](#d3d11-resource-flags).<!-- d3d12-review-inline:end:sharing-interop:API-CreateSharedResource-behavior:3 --></ins>
- <ins><!-- d3d12-review-inline:begin:sharing-interop:API-CreateSharedResource-behavior:3 -->A non-buffer resource must have a D3D11-shareable format for the applicable D3D11 feature/capability set, unless `D3D12_COMPATIBILITY_SHARED_FLAG_9_ON_12` is set. That compatibility flag changes the applicable D3D11-format validation, not the D3D12 resource-creation rules or the consuming API's actual format support.<!-- d3d12-review-inline:end:sharing-interop:API-CreateSharedResource-behavior:3 --></ins>

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedResource-behavior:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The metadata is retained with the shared resource for [ReflectSharedProperties](#id3d12compatibilitydevice-reflectsharedproperties). Passing `pFlags11 = nullptr` does not promise that D3D11 creation flags can later be reflected from an arbitrary resource.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedResource-behavior:4 -->

### Parameters

#### pHeapProperties (input)

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedResource-parameters:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Required pointer to [D3D12_HEAP_PROPERTIES](resources.md#heap-properties) for the implicit heap, including its heap type, CPU-page properties, memory pool, and node masks. The shared-heap CPU-access restrictions apply.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedResource-parameters:1 -->

#### HeapFlags (input)

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedResource-parameters:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [D3D12_HEAP_FLAGS](resources.md#heap-flags) for the implicit heap. Sharing and compatibility requirements are specified under Behavior.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedResource-parameters:3 -->

#### pDesc (input)

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedResource-parameters:5 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Required pointer to the complete [D3D12_RESOURCE_DESC](resources.md#resource-description). The resource must satisfy its dimension, size, format, sample, layout, mip, and resource-flag constraints; metadata cannot add a capability absent from this description.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedResource-parameters:5 -->

#### InitialResourceState (input)

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedResource-parameters:7 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The resource's initial [D3D12_RESOURCE_STATES](synchronization.md#legacy-states) value, subject to the ordinary committed-resource and heap-type requirements. Creating or opening a shared object is not a synchronization operation.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedResource-parameters:7 -->

#### pOptimizedClearValue (input, optional)

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedResource-parameters:9 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Optional pointer to [D3D12_CLEAR_VALUE](resources.md#optimized-clear-value), subject to the format, resource-flag, and depth-range requirements of committed-resource creation. This value is a creation-time optimization, not an operation that clears the shared resource.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedResource-parameters:9 -->

#### pFlags11 (input, optional)

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedResource-parameters:11 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Optional pointer to [D3D11_RESOURCE_FLAGS](#d3d11-resource-flags) to retain as D3D11 creation metadata. The non-null metadata must satisfy the consistency checks under Behavior. The caller owns this input storage; the resource retains the metadata value, not the caller's pointer.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedResource-parameters:11 -->

#### CompatibilityFlags (input)

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedResource-parameters:13 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [D3D12_COMPATIBILITY_SHARED_FLAGS](#compatibility-flags) specifying NT versus non-NT sharing, keyed-mutex compatibility, and 9-on-12 allocation compatibility.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedResource-parameters:13 -->

#### pLifetimeTracker (input, optional)

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedResource-parameters:15 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Null, or a valid [ID3D12LifetimeTracker](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nn-d3d12-id3d12lifetimetracker) to associate with the resource's tracked lifetime. The tracker is an `ID3D12DeviceChild` with an owning D3D12 device; it is an interface object, not a device identifier or a transferable shared handle.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedResource-parameters:15 -->

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedResource-parameters:16 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The tracker connects the resource to an application-defined [ID3D12LifetimeOwner](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nn-d3d12-id3d12lifetimeowner) callback. [LifetimeStateUpdated](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12lifetimeowner-lifetimestateupdated) reports the tracked object's `D3D12_LIFETIME_STATE_IN_USE` or `D3D12_LIFETIME_STATE_NOT_IN_USE` state, and [DestroyOwnedObject](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12lifetimetracker-destroyownedobject) provides the tracker's object-destruction operation. These lifetime notifications are not GPU-completion fence observations.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedResource-parameters:16 -->

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedResource-parameters:17 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The supplied interface must be valid during the call. Passing it does not transfer the caller's COM reference; the caller remains responsible for references it owns. Tracking ownership and destroying the tracked resource are distinct from closing a shared NT handle. A null tracker supplies no explicit lifetime-tracker association.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedResource-parameters:17 -->

#### pOwningSwapchain (input, optional)

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedResource-parameters:19 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Null, or a valid [ID3D12SwapChainAssistant](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nn-d3d12-id3d12swapchainassistant) providing the resource's owning-swap-chain association. This `IUnknown`-derived interface supplies swap-chain identity and operations; it is not the resource interface, an adapter identifier, or a shared handle.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedResource-parameters:19 -->

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedResource-parameters:20 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The association allows the runtime to track writes to the resource for presentation/scan-out synchronization. The assistant interface exposes [GetLUID](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12swapchainassistant-getluid), [GetSwapChainObject](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12swapchainassistant-getswapchainobject), [GetCurrentResourceAndCommandQueue](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12swapchainassistant-getcurrentresourceandcommandqueue), and [InsertImplicitSync](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12swapchainassistant-insertimplicitsync). Supplying the association is not itself a request to present, export, or wait for the resource.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedResource-parameters:20 -->

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedResource-parameters:21 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The supplied interface must be valid during the call, and its implementation must keep any state used by its callbacks valid for those uses. Passing the assistant does not transfer the caller's COM reference; the caller releases references it owns separately from releasing the created resource. A null assistant supplies no explicit owning-swap-chain association.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedResource-parameters:21 -->

#### riid (input)

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedResource-parameters:23 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The requested resource interface IID. This is not a creator identifier.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedResource-parameters:23 -->

#### ppResource (output, optional)

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedResource-parameters:25 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Pointer to writable storage for the requested resource interface. On successful creation, the application owns the returned COM reference. A null pointer requests validation only; it does not create a resource. All required input pointers and descriptions must still be valid.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedResource-parameters:25 -->

### Return values

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedResource-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Successful creation returns `S_OK`. With `ppResource = nullptr`, successful validation returns `S_FALSE`; failed validation returns its failure code. Invalid sharing/compatibility-flag combinations, inconsistent D3D11 metadata, and incompatible descriptions fail, including with `E_INVALIDARG`. Interface and allocation failures are also possible.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedResource-returns:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedResource-returns:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> For a non-null output, validation-failure cleanup sets `*ppResource` to null. Downstream creation is governed by the [committed-resource creation contract](resources.md#create-committed-resource). This scoped cleanup behavior must not be generalized to `CreateSharedHandle` or `OpenSharedHandle`.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedResource-returns:1 -->

<a id="id3d12compatibilitydevice-createsharedheap"></a>

## ID3D12CompatibilityDevice::CreateSharedHeap

### Declaration

```cpp
HRESULT CreateSharedHeap(
    const D3D12_HEAP_DESC* pHeapDesc,
    D3D12_COMPATIBILITY_SHARED_FLAGS CompatibilityFlags,
    REFIID riid,
    void** ppHeap);
```

### Behavior

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedHeap-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Creates a shared heap with compatibility sharing properties. The full [CreateHeap contract](resources.md#create-heap), [heap description](resources.md#heap-description), [heap types](resources.md#heap-types), [heap flags](resources.md#heap-flags), and [node-mask requirements](resources.md#heap-properties) apply. It does not create a resource description or establish placed-resource contents.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedHeap-behavior:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedHeap-behavior:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pHeapDesc->Flags` must contain `D3D12_HEAP_FLAG_SHARED` and must not contain `D3D12_HEAP_FLAG_SHARED_CROSS_ADAPTER`. Undeclared compatibility flag bits are invalid. Unlike `CreateSharedResource`, this method does not accept a D3D11 resource-flags structure, a lifetime tracker, or an owning-swap-chain assistant.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedHeap-behavior:1 -->

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedHeap-behavior:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> An opened raw heap still requires each consumer to create compatible resource mappings and to coordinate offsets, descriptions, lifetime, and synchronization as specified in [shared backing](#shared-backing).

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedHeap-behavior:2 -->

### Parameters

#### pHeapDesc (input)

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedHeap-parameters:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Required pointer to [D3D12_HEAP_DESC](resources.md#heap-description), including size, alignment, heap properties, and flags. The descriptor must satisfy ordinary heap creation and the sharing restrictions under Behavior.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedHeap-parameters:1 -->

#### CompatibilityFlags (input)

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedHeap-parameters:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [D3D12_COMPATIBILITY_SHARED_FLAGS](#compatibility-flags) to retain with the heap.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedHeap-parameters:3 -->

#### riid (input)

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedHeap-parameters:5 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> IID of the requested heap interface.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedHeap-parameters:5 -->

#### ppHeap (output, optional)

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedHeap-parameters:7 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Pointer to writable storage for the returned heap interface. The application owns the returned COM reference. A null pointer requests validation only and does not create a heap; it does not relax the required descriptor-pointer or input requirements.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedHeap-parameters:7 -->

### Return values

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedHeap-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Successful creation returns `S_OK`. With `ppHeap = nullptr`, successful validation returns `S_FALSE`; failed validation returns its failure code. Missing `SHARED`, present `SHARED_CROSS_ADAPTER`, undeclared compatibility flag bits, or an invalid heap description fail with `E_INVALIDARG`. Interface and allocation failures are also possible.

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedHeap-returns:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:API-CreateSharedHeap-returns:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> For a non-null output, validation-failure cleanup sets `*ppHeap` to null. Downstream creation is governed by the [CreateHeap contract](resources.md#create-heap).

<!-- d3d12-review-alert:end:sharing-interop:API-CreateSharedHeap-returns:1 -->

<a id="id3d12compatibilitydevice-reflectsharedproperties"></a>

## ID3D12CompatibilityDevice::ReflectSharedProperties

### Declaration

```cpp
HRESULT ReflectSharedProperties(
    ID3D12Object* pHeapOrResource,
    D3D12_REFLECT_SHARED_PROPERTY ReflectType,
    void* pData,
    UINT DataSize);
```

### Behavior

<!-- d3d12-review-alert:begin:sharing-interop:API-ReflectSharedProperties-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Copies the selected retained property into caller-owned storage. It does not create or open an object, perform a resource copy, export an NT handle, or synchronize resource use. The [selector table](#reflection-selectors) defines the complete payload, exact size, valid object kinds, and result ownership.

<!-- d3d12-review-alert:end:sharing-interop:API-ReflectSharedProperties-behavior:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:API-ReflectSharedProperties-behavior:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The D3D11-flags selector requires a resource with stored D3D11 creation metadata; a shared D3D12 resource is not by itself proof that such metadata exists. Compatibility-flags reflection requires shared backing; non-NT handle reflection additionally requires non-NT sharing mode. A selector must not be used to reinterpret a resource or heap as an unrelated object kind.

<!-- d3d12-review-alert:end:sharing-interop:API-ReflectSharedProperties-behavior:1 -->

### Parameters

#### pHeapOrResource (input)

<!-- d3d12-review-alert:begin:sharing-interop:API-ReflectSharedProperties-parameters:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Required pointer to a resource or heap that supports the selected property. The required object kinds are specified in the [selector table](#reflection-selectors); passing an arbitrary `ID3D12Object` is not sufficient.

<!-- d3d12-review-alert:end:sharing-interop:API-ReflectSharedProperties-parameters:1 -->

#### ReflectType (input)

<!-- d3d12-review-alert:begin:sharing-interop:API-ReflectSharedProperties-parameters:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> One declared [D3D12_REFLECT_SHARED_PROPERTY](#reflection-selectors) selector.

<!-- d3d12-review-alert:end:sharing-interop:API-ReflectSharedProperties-parameters:3 -->

#### pData (output)

<!-- d3d12-review-alert:begin:sharing-interop:API-ReflectSharedProperties-parameters:5 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Required pointer to writable, suitably aligned caller-owned storage for that selector's payload. The caller must keep the buffer valid until the call returns. The runtime copies the property value into this storage; it does not return an allocation or retain the buffer.

<!-- d3d12-review-alert:end:sharing-interop:API-ReflectSharedProperties-parameters:5 -->

#### DataSize (input)

<!-- d3d12-review-alert:begin:sharing-interop:API-ReflectSharedProperties-parameters:7 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The exact byte size of the selected payload. This is the input capacity/size requirement, not an output byte count or an in/out size negotiation.

<!-- d3d12-review-alert:end:sharing-interop:API-ReflectSharedProperties-parameters:7 -->

### Return values

<!-- d3d12-review-alert:begin:sharing-interop:API-ReflectSharedProperties-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns `S_OK` when the selected property is copied. An undeclared selector or a `DataSize` different from the selected payload's exact size returns `E_INVALIDARG`. An incompatible object kind or sharing mode fails; resource-flags reflection also fails if the resource has no retained D3D11 creation metadata.

<!-- d3d12-review-alert:end:sharing-interop:API-ReflectSharedProperties-returns:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:API-ReflectSharedProperties-returns:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The method does not initialize a generic result on failure and does not return a newly allocated payload. Required input/output pointers must be valid even though the method returns an `HRESULT`.

<!-- d3d12-review-alert:end:sharing-interop:API-ReflectSharedProperties-returns:1 -->

<a id="sharing-driver"></a>

## Driver responsibilities and shared private data

Default shared heaps (and the underlying custom heap equivalents) can be opened in D3D11 as a shared tile pool. <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-driver-default-heap-context:0 -->For this D3D11 tile-pool path, only<!-- d3d12-review-inline:end:sharing-interop:SH-driver-default-heap-context:0 --></ins> `L1` heaps on discrete with no CPU access and `L0` heaps on UMA with <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-driver-default-heap-context:0 -->no CPU access can be shared.<!-- d3d12-review-inline:end:sharing-interop:SH-driver-default-heap-context:0 --></ins>

The necessary requirements to support <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-driver-private-data:0 -->opening compatible shared default heaps in D3D11<!-- d3d12-review-inline:end:sharing-interop:SH-driver-private-data:0 --></ins> are also imposed on the driver. The driver must construct private data that is consumable by their D3D11 driver and will be interpreted as a shared tile pool. <ins><!-- d3d12-review-inline:begin:sharing-interop:SH-driver-private-data:0 -->If the heap does not match the D3D11-compatible default-heap properties<!-- d3d12-review-inline:end:sharing-interop:SH-driver-private-data:0 --></ins>, it will only be openable by D3D12. It is the app's responsibility to communicate information about expected resource locations via another channel.

<!-- d3d12-review-alert:begin:sharing-interop:SH-driver-boundary:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Cross-DDI opening requires compatible resource properties and allocation/private-data representations.

<!-- d3d12-review-alert:end:sharing-interop:SH-driver-boundary:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-driver-boundary:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Heap/resource opening receives kernel allocation information and driver-private metadata. Fence opening is specified in the [execution driver contract](execution.md#driver-responsibilities).

<!-- d3d12-review-alert:end:sharing-interop:SH-driver-boundary:1 -->

<!-- d3d12-review-alert:begin:sharing-interop:SH-driver-boundary:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The driver must make shared writes coherent with other adapters under the [cross-adapter coherence requirements](#cross-adapter-heaps).

<!-- d3d12-review-alert:end:sharing-interop:SH-driver-boundary:2 -->

<a id="published-open-ddi"></a>

### Published heap/resource open ABI

<!-- d3d12-review-alert:begin:sharing-interop:SH-open-ddi-payload:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Heap/resource opening uses the [common open lifecycle](resources.md#open-heap-resource-ddi) and [private-storage sizing](resources.md#heap-resource-private-sizing).

<!-- d3d12-review-alert:end:sharing-interop:SH-open-ddi-payload:0 -->

<a id="canonical-contributors"></a>

## Canonical contract contributors

<!-- d3d12-review-alert:begin:sharing-interop:SH-contributors:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Contract | Complete owner and selected sharing contribution |
> |---|---|
> | Resource/heap backing and creation | [Storage models](resources.md#storage-models), [heap creation](resources.md#create-heap), [committed creation](resources.md#create-committed-resource), [placed creation](resources.md#create-placed-resource), [reserved creation](resources.md#create-reserved-resource), and [versioned creation](resources.md#versioned-creation); this chapter defines which objects and metadata can be shared. |
> | Descriptions and formats | [Resource description](resources.md#resource-description), [resource flags](resources.md#resource-flags), [texture layouts](resources.md#texture-layout), [optimized clear values](resources.md#optimized-clear-value), [heap properties](resources.md#heap-properties), [heap flags](resources.md#heap-flags), and [tight alignment](resources.md#tight-alignment); this chapter defines sharing-specific combinations and cross-API format sets. |
> | Physical memory and reuse | [Allocation information](resources.md#allocation-info), [residency](resources.md#residency), [CPU mapping](resources.md#cpu-access), and [shared-tile compatibility](resources.md#tiled-data-compatibility); sharing does not create independent copies or make incompatible mappings safe. |
> | Fence creation and observation | [CreateFence](execution.md#create-fence), [fence flags](execution.md#fence-flags), [fence observation requirements](execution.md#fence-observation-requirements), [queue signals](execution.md#queue-signal), [queue waits](execution.md#queue-waits), [CPU signal](execution.md#fence-signal), [completed value](execution.md#id3d12fencegetcompletedvalue), [events](execution.md#id3d12fenceseteventoncompletion), and [multiple-fence completion](execution.md#multiple-fence-completion); this chapter owns exporting/opening the fence. |
> | Barriers and aliasing | [Enhanced layouts](synchronization.md#barrier-layout), [simultaneous access](synchronization.md#simultaneous-access), [enhanced aliasing](synchronization.md#enhanced-aliasing), [legacy states](synchronization.md#legacy-states), [legacy aliasing](synchronization.md#legacy-aliasing), [barrier-model interoperation](synchronization.md#model-interoperation), and [queue compatibility](synchronization.md#queue-compatibility); handle operations do not perform these operations. |
> | Device identity and capability queries | [Adapter/nodes](devices-and-capabilities.md#identity), [independent devices](devices-and-capabilities.md#independent-devices), [CheckFeatureSupport](devices-and-capabilities.md#id3d12device-checkfeaturesupport), [OPTIONS](devices-and-capabilities.md#d3d12_feature_data_d3d12_options), [OPTIONS4](devices-and-capabilities.md#d3d12_feature_data_d3d12_options4), [CROSS_NODE](devices-and-capabilities.md#d3d12_feature_data_cross_node), and [DISPLAYABLE](devices-and-capabilities.md#d3d12_feature_data_displayable); this chapter distinguishes their sharing domains, not their complete payload definitions. |
> | Lifetime and common queue families | [Submission](execution.md#submission), [completion](execution.md#completion), [object/resource lifetime](execution.md#lifetime), [threading](execution.md#threading), and [queue types](execution.md#command-list-types); sharing has no implicit handoff for graphics, compute, copy, or video work. |

<!-- d3d12-review-alert:end:sharing-interop:SH-contributors:0 -->

<a id="external-api-boundaries"></a>

## Adjacent-system interface boundaries

<!-- d3d12-review-alert:begin:sharing-interop:AB-external-boundaries:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Some catalogued interface identities are hand-offs to neighboring systems.
> The DirectSR factory passes a D3D12 device, node selection and requested
> interface to the DirectSR provider; provider algorithm/availability contracts
> belong to DirectSR. Virtualization-guest sharing and fence-file-descriptor
> helpers belong to the guest/host integration and are not ordinary Win32
> shared-handle or universal fence-export contracts.

<!-- d3d12-review-alert:end:sharing-interop:AB-external-boundaries:0 -->

<!-- d3d12-review-alert:begin:sharing-interop:AB-external-boundaries:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The swap-chain assistant supplied for compatibility resources is a
> DXGI-owned identity/current-resource/queue/implicit-synchronization boundary.
> It is not the resource itself, an application-owned swap chain implementation
> or a generic adapter identifier. Full DirectSR, guest-host and DXGI behavior
> is external to this selected baseline (D274); those inventory methods do not
> gain local callable-coverage claims from this boundary description.

<!-- d3d12-review-alert:end:sharing-interop:AB-external-boundaries:1 -->
