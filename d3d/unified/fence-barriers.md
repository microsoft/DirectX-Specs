# Fence barriers

Fence barriers allow app developers to perform GPU command execution timeline synchronization between command queues or with the CPU. This improves both GPU/CPU and GPU/GPU concurrency, and gives developers an alternative to split barriers.

<a id="availability"></a>

## Availability

```cpp
typedef enum D3D12_FENCE_BARRIERS_TIER
{
    D3D12_FENCE_BARRIERS_TIER_NOT_SUPPORTED = 0,
    D3D12_FENCE_BARRIERS_TIER_1 = 1,
} D3D12_FENCE_BARRIERS_TIER;
```

```cpp
typedef struct D3D12_FEATURE_DATA_FENCE_BARRIERS
{
    UINT NodeIndex;
    D3D12_COMMAND_LIST_TYPE CommandListType;
    D3D12_FENCE_BARRIERS_TIER FenceBarriersTier;
} D3D12_FEATURE_DATA_FENCE_BARRIERS;
```

<ins><!-- d3d12-review-inline:begin:fence-barriers:FB-query:0:authored:migration-029703127f31025e-0 -->`CheckFeatureSupport` with `D3D12_FEATURE_FENCE_BARRIERS` reports support for the selected `NodeIndex` and `CommandListType`. The interface `ID3D12CommandListFenceBarriers` is obtained from the owning command list object. Direct, compute, copy, and supported video command lists can record fence barriers. Bundles cannot.<!-- d3d12-review-inline:end:fence-barriers:FB-query:0:authored:migration-029703127f31025e-0 --></ins>

<!-- d3d12-review-alert:begin:fence-barriers:FB-tier-one:0:modified:migration-381fa7117bf35d44-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> `D3D12_FENCE_BARRIERS_TIER_1`:
> - Supports command list `SignalBarrier` methods using fences created with `D3D12_FENCE_FLAG_ALLOW_COMMAND_LIST_BARRIERS` bit set.
> - Supports command list `WaitBarrier` methods using fences created with `D3D12_FENCE_FLAG_ALLOW_COMMAND_LIST_BARRIERS` bit set, except for fences created with `D3D12_FENCE_FLAG_ALLOW_QUEUE_AND_CPU_SYNC` bit also set (see [Command List Scoped Fences](execution.md#command-list-scoped-fences)).
> - Requires driver support for fence barriers
> - Requires device support for 64-bit atomic ops. Must be able to write 64-bit fence values atomically to avoid torn values

<!-- d3d12-review-alert:end:fence-barriers:FB-tier-one:0:modified:migration-381fa7117bf35d44-0 -->

<a id="barrier-operations"></a>

## Barrier structures and synchronization

<a id="barrier-groups"></a>
<a id="sync-access"></a>

<ins><!-- d3d12-review-inline:begin:fence-barriers:FB-canonical-access:0:authored:migration-1787283390edf420-0 -->`SignalBarrier` and `WaitBarrier` use the enhanced [barrier types](synchronization.md#barrier-operations) and [structures and groups](synchronization.md#barrier-groups). See [texture layouts](synchronization.md#barrier-layout), [synchronization scopes](synchronization.md#barrier-sync), [access masks](synchronization.md#barrier-access), and [access/synchronization compatibility](synchronization.md#access-sync-compatibility) for the common barrier definitions.<!-- d3d12-review-inline:end:fence-barriers:FB-canonical-access:0:authored:migration-1787283390edf420-0 --></ins>

<a id="fence-kinds"></a>

## Fence kinds and dependency scope

<ins><!-- d3d12-review-inline:begin:fence-barriers:FB-kinds-links:0:authored:migration-9237cb8bd1750a08-0 -->Fence barriers use fences created with `D3D12_FENCE_FLAG_ALLOW_COMMAND_LIST_BARRIERS`. Sharing a fence does not enable command list barriers. The [barrier flag](execution.md#allow-command-list-barriers) must be requested explicitly. [Command list scoped fences](execution.md#command-list-scoped-fences) manage barrier dependencies within a command list or a set of command lists in the same `ExecuteCommandLists` scope, including [local split dependencies](#split-dependencies). A fence that also has [`D3D12_FENCE_FLAG_ALLOW_QUEUE_AND_CPU_SYNC`](execution.md#allow-queue-and-cpu-sync) can carry [external dependencies](#external-dependencies) to the CPU or other queues.<!-- d3d12-review-inline:end:fence-barriers:FB-kinds-links:0:authored:migration-9237cb8bd1750a08-0 --></ins>

<a id="access-and-producer-order"></a>

### Subsequent accesses and producer ordering

`SignalBarrier` is still a normal barrier operation, and the transitioning subresource can still be accessed in the `ExecuteCommandLists` scope based on the `AccessAfter` bits used in the barrier. <ins><!-- d3d12-review-inline:begin:fence-barriers:FB-signal-access:0:preserved-repair:opus-sentence-break -->This includes write operations so long as the resource is simultaneous-access and no external dependent accesses write to the resource.<!-- d3d12-review-inline:end:fence-barriers:FB-signal-access:0:preserved-repair:opus-sentence-break --></ins> However, consecutive layout transitioning `SignalBarrier` operations with no intervening `WaitBarrier` on a given texture subresource in a single `ExecuteCommandLists` scope is invalid since it risks racing with external dependent accesses.

Consecutive layout transitioning `WaitBarrier` operations with no intervening `SignalBarrier` on a given texture subresource in a single `ExecuteCommandLists` scope is invalid. Such a scenario would imply concurrent write operations to the same subresource, which is not supported.

<ins><!-- d3d12-review-inline:begin:fence-barriers:FB-producer-order:0:authored:migration-e8126a1aab902af8-0 -->`SignalBarrier` operations on the same fence require an ordered dependency chain: barrier synchronization must ensure the preceding signal completes before the next signal is reached. The application must resolve the preceding signal's outstanding synchronization scopes with the next signal barrier or an intervening barrier. An unresolved split signal requires its dependent wait. A scoped wait must be satisfied by its most recent applicable producer, as defined in the [scoped fence rules](execution.md#command-list-scoped-fences).<!-- d3d12-review-inline:end:fence-barriers:FB-producer-order:0:authored:migration-e8126a1aab902af8-0 --></ins>

<a id="split-dependencies"></a>

### Local split dependencies

To initiate a split barrier using a Command List Scoped fence, a `SignalBarrier` operation specifies any layout transition and access after bits, setting `SyncAfter` to `D3D12_BARRIER_SYNC_NONE` since the barrier is not expected to block subsequent command processing other than a dependent `WaitBarrier`. The values of `AccessBefore` and `AccessAfter` reflect the before and after accesses upon completion of the dependent `WaitBarrier`.

The split barrier is terminated by a dependent `WaitBarrier`, satisfied when the initiating `SignalBarrier` completes texture layout transition and cache flush. The terminating `WaitBarrier` typically sets `SyncBefore` to `D3D12_BARRIER_SYNC_NONE` since it only needs to sync with the fence condition. For texture barriers, `LayoutBefore` and `LayoutAfter` are set to `D3D12_BARRIER_LAYOUT_UNDEFINED` since all the layout transitions are completed by the time the fence is signaled. The values of `AccessBefore` and `AccessAfter` must match those of the initiating `SignalBarrier` to properly invalidate any relevant caches.

Fence barriers using Command List Scoped fence are the only way to split global barriers. Classic split barriers require drivers to set aside storage in resource memory to track completion state. Thus, global barriers cannot be split using `D3D12_BARRIER_SYNC_SPLIT` since no resource is provided.

<a id="external-dependencies"></a>

### External dependencies

Resource caches on the GPU are required to be coherent at the start of `ExecuteCommandLists` workloads, and completion of `ExecuteCommandLists` guarantees that all caches are flushed to main memory. However, with fence barriers it is possible to represent dependencies that do not benefit from this coherency guarantee.

It is expected that all caches are coherent across all COMPUTE and DIRECT queues on the same device. However, CPU/GPU dependencies or cross-queue dependencies involving other queue types such as COPY and VIDEO queues may require full cache flush or invalidation. As such, apps must use the `D3D12_BARRIER_ACCESS_GLOBAL` access bit in fence barriers to manage cache coherency for these external dependencies.

Unnecessary cache flushes and cache invalidation can be costly. Cross-queue dependencies specifically between COMPUTE and DIRECT queues on the same device should avoid using the `D3D12_BARRIER_ACCESS_GLOBAL` bit to avoid unneeded overhead.

A `SignalBarrier` with [external dependencies](#external-dependencies) must set the `D3D12_BARRIER_ACCESS_GLOBAL` bit in `AccessAfter` to guarantee data coherency.

A `WaitBarrier` with [external dependencies](#external-dependencies) must set the `D3D12_BARRIER_ACCESS_GLOBAL` bit in `AccessBefore` to guarantee data coherency.

<ins><!-- d3d12-review-inline:begin:fence-barriers:FB-external-tier:0:authored:migration-a2f2455b563f3790-0 -->With `D3D12_FENCE_BARRIERS_TIER_1`, a `SignalBarrier` may signal a fence that also has `D3D12_FENCE_FLAG_ALLOW_QUEUE_AND_CPU_SYNC`, so the CPU or another queue can wait for the completed barrier work. That consumer waits through ordinary CPU fence notification or a queue `Wait`, because Tier 1 `WaitBarrier` accepts only command list scoped fences.<!-- d3d12-review-inline:end:fence-barriers:FB-external-tier:0:authored:migration-a2f2455b563f3790-0 --></ins>

<a id="global-access-legality"></a>

#### GLOBAL access legality

`D3D12_BARRIER_ACCESS_GLOBAL` may be combined with other access bits.

`D3D12_BARRIER_ACCESS_GLOBAL` cannot be used in non-fence barriers, nor can `D3D12_BARRIER_ACCESS_GLOBAL` be used in `AccessBefore` in a `SignalBarrier` barrier or in `AccessAfter` in a `WaitBarrier` barrier.

<a id="no-access-exception"></a>

#### NO_ACCESS exception

<ins><!-- d3d12-review-inline:begin:fence-barriers:FB-no-access-exclusive:0:modified:opus-no-access-subject -->`D3D12_BARRIER_ACCESS_NO_ACCESS` indicates that the resource is either not accessed before/after the barrier in the same `ExecuteCommandLists` context, or that the data is no longer needed.<!-- d3d12-review-inline:end:fence-barriers:FB-no-access-exclusive:0:modified:opus-no-access-subject --></ins> `D3D12_BARRIER_ACCESS_NO_ACCESS` may not be combined with other access bits.

`D3D12_BARRIER_ACCESS_NO_ACCESS` may be used when synchronizing between CPU and GPU access if there are no writes to flush or caches do not need invalidating. This is typically the case with write-after-read barriers.

<a id="commands"></a>

## Commands

<a id="signal-barrier"></a>

### ID3D12CommandListFenceBarriers::SignalBarrier

#### Declaration

```cpp
void SignalBarrier(
    UINT NumBarrierGroups,
    const D3D12_BARRIER_GROUP *pBarrierGroups,
    ID3D12Fence *pFence,
    UINT64 FenceValue
);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:fence-barriers:FB-SignalBarrier-behavior:0 -->`SignalBarrier` executes the provided barriers, signalling a fence after all barrier transactions have fully completed. An outstanding local split barrier dependency must be completed by a `WaitBarrier` with matching fence/value pairs before its dependent operations.<!-- d3d12-review-inline:end:fence-barriers:FB-SignalBarrier-behavior:0 --></ins>

#### Parameters

| Parameter          |                                                         |
|--------------------|---------------------------------------------------------|
| `NumBarrierGroups` | Number of barrier groups pointed to by `pBarrierGroups` |
| `pBarrierGroups`   | Pointer to an array of `D3D12_BARRIER_GROUP` objects    |
| `pFence`           | Fence to signal upon completion of barriers             |
| `FenceValue`       | Fence value to signal                                   |

#### Requirements

<ins><!-- d3d12-review-inline:begin:fence-barriers:FB-signal-kind:0:authored:migration-fc08b498c90e5134-0 -->The target must be a writable fence explicitly enabled with `D3D12_FENCE_FLAG_ALLOW_COMMAND_LIST_BARRIERS`. [Read-only status fences](execution.md#status-fences) cannot be signaled. For CPU or other-queue dependencies, the fence also requires `D3D12_FENCE_FLAG_ALLOW_QUEUE_AND_CPU_SYNC` and the [external dependency coherency rules](#external-dependencies).<!-- d3d12-review-inline:end:fence-barriers:FB-signal-kind:0:authored:migration-fc08b498c90e5134-0 --></ins>

#### Return values and validation

<ins><!-- d3d12-review-inline:begin:fence-barriers:FB-SignalBarrier-results:0:authored:migration-587a8a2088b22d71-0 -->Recording failures are reported through `Close` on the owning graphics or video command list interface, following [deferred recording error rules](execution.md#lifecycle-driver-errors).<!-- d3d12-review-inline:end:fence-barriers:FB-SignalBarrier-results:0:authored:migration-587a8a2088b22d71-0 --></ins>

<a id="wait-barrier"></a>

### ID3D12CommandListFenceBarriers::WaitBarrier

#### Declaration

```cpp
void WaitBarrier(
    UINT NumBarrierGroups,
    const D3D12_BARRIER_GROUP *pBarrierGroups,
    UINT NumFences,
    ID3D12Fence * const *ppFences,
    const UINT64 *pFenceValues
);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:fence-barriers:FB-WaitBarrier-behavior:0 -->`WaitBarrier` waits for the full set of fence/value pairs to be satisfied then executes the provided barrier operations.<!-- d3d12-review-inline:end:fence-barriers:FB-WaitBarrier-behavior:0 --></ins>

If a wait barrier on a texture subresource corresponds to a preceding signal barrier, the `LayoutBefore` on the wait barrier must match the `LayoutAfter` from the signal barrier or be set to `D3D12_BARRIER_LAYOUT_UNDEFINED`, which avoids a layout transition. This effectively matches split barrier behavior where a barrier transaction is started by the split-begin barrier, and completed by the split-end barrier.

#### Parameters

| Parameter          |                                                                   |
|--------------------|-------------------------------------------------------------------|
| `NumBarrierGroups` | Number of barrier groups pointed to by `pBarrierGroups`           |
| `pBarrierGroups`   | Pointer to an array of `D3D12_BARRIER_GROUP` objects              |
| `NumFences`        | Number of fence/value pairs                                       |
| `ppFences`         | Pointer to an array of `ID3D12Fence` pointers of size `NumFences` |
| `pFenceValues`     | Pointer to an array of fence values of size `NumFences`           |

#### Requirements

<ins><!-- d3d12-review-inline:begin:fence-barriers:FB-wait-kind:0:authored:migration-132caa5f4122c792-0 -->For `D3D12_FENCE_BARRIERS_TIER_1`, every input fence must be [command list scoped](execution.md#command-list-scoped-fences). `pFenceValues[i]` is the threshold for `ppFences[i]`. See [command list scoped fences](execution.md#command-list-scoped-fences) for the signal that must already satisfy each value. A producing `SignalBarrier` can be in an earlier command list of the same `ExecuteCommandLists` group.<!-- d3d12-review-inline:end:fence-barriers:FB-wait-kind:0:authored:migration-132caa5f4122c792-0 --></ins>

#### Return values and validation

<ins><!-- d3d12-review-inline:begin:fence-barriers:FB-WaitBarrier-results:0:authored:migration-6d3a4590f2a928bd-0 -->Recording failures are reported through `Close` on the owning graphics or video command list interface, following [deferred recording error rules](execution.md#lifecycle-driver-errors).<!-- d3d12-review-inline:end:fence-barriers:FB-WaitBarrier-results:0:authored:migration-6d3a4590f2a928bd-0 --></ins>

<a id="lifetime"></a>

## Lifetime and completion

<ins><!-- d3d12-review-inline:begin:fence-barriers:FB-lifetime:0:authored:migration-4762e5e9299a37eb-0 -->A fence barrier signal establishes completion only of the work and cache operations covered by its barrier scopes. It does not establish that the whole command list has completed or that its command allocator is idle. Before the application reuses a resource or other storage, every remaining use of that storage must have completed. Fence storage must remain valid while GPU work references it.<!-- d3d12-review-inline:end:fence-barriers:FB-lifetime:0:authored:migration-4762e5e9299a37eb-0 --></ins>
