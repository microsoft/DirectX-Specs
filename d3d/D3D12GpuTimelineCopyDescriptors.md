# D3D12 GPU Timeline Descriptor Copying

## Contents

- [Overview](#overview)
- [Capability query](#capability-query)
- [GPU timeline CopyDescriptors](#gpu-timeline-copydescriptors)
  - [Descriptor heap requirements](#descriptor-heap-requirements)
  - [Predication](#predication)
  - [Descriptor range volatility](#descriptor-range-volatility)
- [Descriptor heap barriers](#descriptor-heap-barriers)
  - [Barrier access and synchronization](#barrier-access-and-synchronization)
  - [Barrier examples](#barrier-examples)
  - [CPU and cross-queue synchronization](#cpu-and-cross-queue-synchronization)
- [DDI](#ddi)

## Overview

Resource Binding Tier 4 adds support for copying descriptors on the GPU
timeline. The operation is a command-list version of the CPU timeline
`ID3D12Device::CopyDescriptors` method.

The GPU timeline version uses one size for each source/destination range pair
rather than supporting scatter/gather operations within a pair. Applications
can express scatter/gather copies as multiple ranges or multiple calls.

GPU timeline descriptor copying is supported on DIRECT, COMPUTE, and COPY
command lists. It is not supported on BUNDLE or video command lists.

## Capability query

Tier 4 is reported through the existing `ResourceBindingTier` capability.
Drivers explicitly opt in by reporting `D3D12DDI_RESOURCE_BINDING_TIER_4`;
the runtime exposes the corresponding `D3D12_RESOURCE_BINDING_TIER_4` API
value.

```c++
typedef enum D3D12_RESOURCE_BINDING_TIER
{
    D3D12_RESOURCE_BINDING_TIER_1 = 1,
    D3D12_RESOURCE_BINDING_TIER_2 = 2,
    D3D12_RESOURCE_BINDING_TIER_3 = 3,
    D3D12_RESOURCE_BINDING_TIER_4 = 4,
} D3D12_RESOURCE_BINDING_TIER;
```

Tier 4 is a superset of the lower resource binding tiers.

## GPU timeline CopyDescriptors

```c++
typedef struct D3D12_COPY_DESCRIPTORS_RANGE
{
    UINT                         NumDescriptors;
    D3D12_GPU_DESCRIPTOR_HANDLE DestRangeStart;
    D3D12_GPU_DESCRIPTOR_HANDLE SrcRangeStart;
} D3D12_COPY_DESCRIPTORS_RANGE;

// Command list types: DIRECT, COMPUTE, COPY
interface ID3D12CommandListN
{
    ...
    void CopyDescriptors(
        _In_ UINT NumRanges,
        _In_reads_opt_(NumRanges)
            const D3D12_COPY_DESCRIPTORS_RANGE* pRanges,
        _In_ D3D12_DESCRIPTOR_HEAP_TYPE DescriptorHeapsType);
}
```

### Descriptor heap requirements

Source and destination handles are `D3D12_GPU_DESCRIPTOR_HANDLE` values, so
they must refer to shader-visible descriptor heaps. RTV/DSV heaps and
non-shader-visible heaps cannot be used.

Different ranges in a call can refer to the same descriptor heap or to
different descriptor heaps. All heaps in a call must have the type specified
by `DescriptorHeapsType`.

Reading or writing outside a valid descriptor heap location produces undefined
behavior. The debug layer reports an error for this condition.

Any overlap between a written range and a read or written range in the same
call is invalid.

Descriptor heaps and resources referenced by descriptors remain subject to the
application-managed lifetime rules in the
[Resource Binding specification](ResourceBinding.md#object-lifetime-management-separated-from-binding).
They must remain valid for outstanding GPU work that can access them.

### Predication

GPU timeline `CopyDescriptors` honors D3D12 predication. When predication is
active through `SetPredication`, the descriptor copy is skipped if the
predicate indicates that the operation should not execute, consistent with
other predicated command-list operations.

### Descriptor range volatility

If descriptors updated by GPU timeline `CopyDescriptors` are subsequently
accessed through a root-signature descriptor table in the same command list,
the affected descriptor range must specify
`D3D12_DESCRIPTOR_RANGE_FLAG_DESCRIPTORS_VOLATILE`. Appropriate descriptor
heap barriers are also required.

See
[Descriptor Range Flags](ResourceBinding.md#descriptor-range-flags)
for the complete root-signature rules.

## Descriptor heap barriers

Within a command list, synchronization between GPU timeline
`CopyDescriptors` and shader execution requires descriptor heap barriers. This
is a new enhanced barrier type, `D3D12_BARRIER_TYPE_DESCRIPTOR_HEAP`.
Command lists that do not use GPU timeline `CopyDescriptors` do not require
descriptor heap barriers.

Descriptor heap barriers identify the specific descriptor range involved in a
hazard. This allows synchronization and cache operations to be scoped to the
affected descriptors. Applications can instead specify a null base descriptor
to apply the barrier to all shader-visible descriptor heaps.

```c++
typedef struct D3D12_DESCRIPTOR_HEAP_BARRIER
{
    D3D12_BARRIER_SYNC SyncBefore;
    D3D12_BARRIER_SYNC SyncAfter;
    D3D12_BARRIER_ACCESS AccessBefore;
    D3D12_BARRIER_ACCESS AccessAfter;
    D3D12_GPU_DESCRIPTOR_HANDLE BaseDescriptor;
    UINT NumDescriptors;
} D3D12_DESCRIPTOR_HEAP_BARRIER;
```

`BaseDescriptor` and `NumDescriptors` identify the range being synchronized.
Because `BaseDescriptor` is a `D3D12_GPU_DESCRIPTOR_HANDLE`, the range must be
in a shader-visible descriptor heap.

If `BaseDescriptor.ptr` is zero, the barrier applies to all shader-visible
descriptor heaps and `NumDescriptors` is ignored.

Subrange barriers allow different regions of the same descriptor heap to be
accessed differently at the same time. For example, one range can be a copy
destination while another nonoverlapping range is a copy source.

The barrier type enumeration and barrier group are extended as follows:

```c++
enum D3D12_BARRIER_TYPE
{
    D3D12_BARRIER_TYPE_GLOBAL,
    D3D12_BARRIER_TYPE_TEXTURE,
    D3D12_BARRIER_TYPE_BUFFER,
    D3D12_BARRIER_TYPE_DESCRIPTOR_HEAP = 3,
};

struct D3D12_BARRIER_GROUP
{
    D3D12_BARRIER_TYPE Type;
    UINT32 NumBarriers;
    union
    {
        const D3D12_GLOBAL_BARRIER* pGlobalBarriers;
        const D3D12_TEXTURE_BARRIER* pTextureBarriers;
        const D3D12_BUFFER_BARRIER* pBufferBarriers;
        const D3D12_DESCRIPTOR_HEAP_BARRIER* pDescriptorHeapBarriers;
    };
};
```

Descriptor heap barriers are valid only when Resource Binding Tier 4 is
supported. Otherwise,
`D3D12_MESSAGE_ID_GPU_COPY_DESCRIPTORS_NOT_SUPPORTED` is reported and the
command list is removed.

Legacy barriers cannot identify descriptor heap updates and cannot synchronize
GPU timeline `CopyDescriptors`.

### Barrier access and synchronization

Only the following access values are valid for descriptor heap barriers. Any
other access bit is invalid; the debug layer reports
`D3D12_MESSAGE_ID_INCOMPATIBLE_BARRIER_VALUES` and removes the command list.

| Access | Meaning |
|---|---|
| `D3D12_BARRIER_ACCESS_COMMON` | Shader reads during draw or dispatch |
| `D3D12_BARRIER_ACCESS_COPY_DEST` | GPU `CopyDescriptors` destination writes |
| `D3D12_BARRIER_ACCESS_COPY_SOURCE` | GPU `CopyDescriptors` source reads |
| `D3D12_BARRIER_ACCESS_COPY_DEST \| D3D12_BARRIER_ACCESS_COPY_SOURCE` | Simultaneous source and destination access to nonoverlapping ranges |
| `D3D12_BARRIER_ACCESS_NO_ACCESS` | No prior or subsequent access, such as the first descriptor heap barrier in a command list |

The corresponding synchronization values are:

| Operation | Access | Sync |
|---|---|---|
| GPU `CopyDescriptors` destination write | `D3D12_BARRIER_ACCESS_COPY_DEST` | `D3D12_BARRIER_SYNC_COPY` |
| GPU `CopyDescriptors` source read | `D3D12_BARRIER_ACCESS_COPY_SOURCE` | `D3D12_BARRIER_SYNC_COPY` |
| Shader descriptor read during draw or dispatch | `D3D12_BARRIER_ACCESS_COMMON` | `D3D12_BARRIER_SYNC_DRAW` or `D3D12_BARRIER_SYNC_COMPUTE_SHADING` |

### Barrier examples

The following barrier synchronizes all shader-visible descriptor heaps after
GPU timeline descriptor copies and before a draw:

```c++
D3D12_DESCRIPTOR_HEAP_BARRIER barrier = {};
barrier.SyncBefore = D3D12_BARRIER_SYNC_COPY;
barrier.AccessBefore =
    D3D12_BARRIER_ACCESS_COPY_DEST | D3D12_BARRIER_ACCESS_COPY_SOURCE;
barrier.SyncAfter = D3D12_BARRIER_SYNC_DRAW;
barrier.AccessAfter = D3D12_BARRIER_ACCESS_COMMON;
barrier.BaseDescriptor.ptr = 0;

D3D12_BARRIER_GROUP group = {};
group.Type = D3D12_BARRIER_TYPE_DESCRIPTOR_HEAP;
group.NumBarriers = 1;
group.pDescriptorHeapBarriers = &barrier;
pCommandList->Barrier(1, &group);
```

The following example transitions descriptors 0 through 99 from copy
destination to copy source, while transitioning descriptors 100 through 199
from shader-readable to copy destination:

```c++
D3D12_GPU_DESCRIPTOR_HANDLE heapStart =
    pMyDescriptorHeap->GetGPUDescriptorHandleForHeapStart();

D3D12_DESCRIPTOR_HEAP_BARRIER barriers[2] = {};

barriers[0].SyncBefore = D3D12_BARRIER_SYNC_COPY;
barriers[0].AccessBefore = D3D12_BARRIER_ACCESS_COPY_DEST;
barriers[0].SyncAfter = D3D12_BARRIER_SYNC_COPY;
barriers[0].AccessAfter = D3D12_BARRIER_ACCESS_COPY_SOURCE;
barriers[0].BaseDescriptor = heapStart;
barriers[0].NumDescriptors = 100;

barriers[1].SyncBefore = D3D12_BARRIER_SYNC_DRAW;
barriers[1].AccessBefore = D3D12_BARRIER_ACCESS_COMMON;
barriers[1].SyncAfter = D3D12_BARRIER_SYNC_COPY;
barriers[1].AccessAfter = D3D12_BARRIER_ACCESS_COPY_DEST;
barriers[1].BaseDescriptor.ptr =
    heapStart.ptr + 100 * DescriptorIncrementSize;
barriers[1].NumDescriptors = 100;
```

Applications should batch descriptor heap copies and avoid small copies
interleaved with rendering. When multiple descriptor heap barriers are needed,
submit them in one `Barrier` call so implementations can coalesce cache
maintenance.

No barrier is required before the first descriptor heap access in a command
list, whether the access is a shader read or a GPU `CopyDescriptors` read or
write.

### CPU and cross-queue synchronization

Descriptor heaps are CPU accessible, so completed GPU timeline descriptor
copies are visible to the CPU, and CPU descriptor updates are visible to the
GPU.

[Fence barriers](D3D12EnhancedBarriers.md#fence-barriers-preview) are required
for [cross-queue synchronization](D3D12EnhancedBarriers.md#cross-queue-synchronization)
and for synchronizing CPU descriptor heap updates with in-flight command lists
that access the same descriptor heap locations. Use
`D3D12_BARRIER_ACCESS_GLOBAL` for the CPU or other queue being synchronized.

One CPU or GPU entity can write to a descriptor heap while other entities read
nonoverlapping locations. Concurrent writes to the same descriptor heap are
not allowed across queues or between a queue and the CPU, even when the writes
target different locations. Fence barriers can provide fine-grained write
serialization.

## DDI

Tier 4 is reported by the DDI resource binding capability:

```c++
typedef enum D3D12DDI_RESOURCE_BINDING_TIER
{
    D3D12DDI_RESOURCE_BINDING_TIER_1 = 1,
    D3D12DDI_RESOURCE_BINDING_TIER_2 = 2,
    D3D12DDI_RESOURCE_BINDING_TIER_3 = 3,
    D3D12DDI_RESOURCE_BINDING_TIER_4 = 4,
} D3D12DDI_RESOURCE_BINDING_TIER;
```

GPU timeline `CopyDescriptors` is a predicated operation. Drivers must honor
the current predication state set through `SetPredication`.

```c++
typedef struct D3D12DDI_COPY_DESCRIPTORS_RANGE
{
    UINT NumDescriptors;
    D3D12DDI_GPU_DESCRIPTOR_HANDLE DestRangeStart;
    D3D12DDI_GPU_DESCRIPTOR_HANDLE SrcRangeStart;
} D3D12DDI_COPY_DESCRIPTORS_RANGE;

typedef VOID (APIENTRY* PFND3D12DDI_COPY_DESCRIPTORS_NNNN)(
    D3D12DDI_HCOMMANDLIST,
    _In_ UINT NumRanges,
    _In_reads_opt_(NumRanges)
        const D3D12DDI_COPY_DESCRIPTORS_RANGE* pRanges,
    _In_ D3D12DDI_DESCRIPTOR_HEAP_TYPE DescriptorHeapsType);
```

The DDI enhanced barrier types are extended as follows:

```c++
typedef enum D3D12DDI_BARRIER_TYPE
{
    ...
    D3D12DDI_BARRIER_TYPE_DESCRIPTOR_HEAP = 4,
} D3D12DDI_BARRIER_TYPE;

typedef struct D3D12DDI_DESCRIPTOR_HEAP_BARRIER_0122
{
    D3D12DDI_BARRIER_SYNC SyncBefore;
    D3D12DDI_BARRIER_SYNC SyncAfter;
    D3D12DDI_BARRIER_ACCESS AccessBefore;
    D3D12DDI_BARRIER_ACCESS AccessAfter;
    D3D12DDI_GPU_DESCRIPTOR_HANDLE BaseDescriptor;
    UINT NumDescriptors;
} D3D12DDI_DESCRIPTOR_HEAP_BARRIER_0122;
```

A null DDI `BaseDescriptor` applies the barrier to all shader-visible
descriptor heaps.
