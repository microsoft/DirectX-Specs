<a id="memory-model"></a>

# Memory model

> **Provisional:** This chapter requires substantial reworking and revision. The material below preserves the previously integrated, primarily compute-scoped rules; it is not a complete or reconciled D3D12 memory model. Existing stage, shader-model and capability qualifications remain in force.

This initial material covers thread-group shared memory (TGSM), unordered-access views (UAVs), atomics, coherency and shader barriers. The [compute stage](compute.md#thread-groups) defines its thread/group organization and [per-group storage allocation and lifetime](compute.md#thread-group-shared-memory). Command/resource barriers and queue synchronization retain their [separate owner](synchronization.md#barrier-operations). Compute-scoped statements here do not establish the complete behavior of other shader stages.

<a id="memory-consistency"></a>

## Memory consistency, races and atomics

The D3D12 shader memory consistency model is weak/relaxed, as generally understood in existing architectures and literature. Loosely, this means the program author and/or compiler are responsible for identifying all memory and thread synchronization points via some appropriately expressive labeling.

If multiple atomic operations from different threads target the same address, the operations are serialized in an undefined order.

Atomic operations do not imply a memory or thread fence. If the program author/compiler does not make appropriate use of fences, it is not guaranteed that all threads see the result of any given memory operation at the same time, or in any particular order with respect to updates to other memory addresses.

The baseline 32-bit model provides atomicity per 32-bit component, not for a whole vector load or store. Assignment of a scalar is not an atomic read-modify-write such as `InterlockedAdd`; computing a value and then storing it does not make the computation indivisible. Independently enabled 64-bit atomic operations provide an indivisible operation on their 64-bit target, not a whole vector/aggregate transaction. Native 16-bit storage must not be treated as an extension of the baseline 32-bit whole-component guarantee.

The following atomic-versus-store guarantees describe the baseline 32-bit operations.

Limitation: Atomic operations on Thread Group Shared Memory are atomic with respect to other atomic operations, as well as operations that only perform reads ("load"s). However atomic operations on Thread Group Shared Memory are NOT atomic with respect to operations that perform only writes ("store"s) to memory. Mixing of atomics and stores on the same Thread Group Shared Memory address without thread synchronization and memory fencing between them produces undefined results at the address involved. This limitation arises because some implementations of loads and stores do not honor the locking semantics for implementing atomics. It turns out this has no impact on loads, since they are guaranteed to retrieve a value either before or after an atomic (they will not retrieve partially updated values, given they are all defined at 32-bit quanta). However store operations could find their way into the middle of an atomic operation and thus have their effect possibly lost.

There is no such limitation on atomics to UAV memory; atomic operations on UAV memory are atomic both with respect to other atomic operations as well as loads and stores.

Without the required synchronization, conflicting accesses can produce order-dependent or undefined results. Even serialized atomic operations can return different original values depending on their unspecified serialization order; an atomic reduction is not a promise of deterministic thread ordering. Compiler validation is not a guarantee that all data races, divergent barriers or deadlocks are detected. The application must provide a valid algorithm even when a compiler accepts the program.

<a id="uav-coherency"></a>

### UAV coherency

If a Compute Shader thread in a given thread group needs to perform loads of data that was written by atomics or stores in another thread group, the UAV where the data resides must be tagged upon declaration in the shader as `globallycoherent`. Otherwise, this form of cross-thread group data sharing will produce undefined results.

Atomic read-modify-write operations do not have this constraint (even though a part of the operation is a read/load), because a byproduct of the hardware honoring atomicity is that the entire system sees the operation, whereas simple loads on some implementations may only go to a local cache that has no knowledge of external updates.

`globallycoherent` is a visibility scope, not an execution barrier or an ordering operation. Appropriate memory fences are still required to order the producer's data and the consumer's observation. Conversely, a device-scope fence on a non-`globallycoherent` UAV does not make its ordinary loads globally coherent. Atomic operations do not require this declaration merely to be globally atomic, but they still do not order other addresses by themselves.

<a id="atomic-capabilities"></a>

### Atomic operations and capabilities

Baseline compute atomic read-modify-write operations include integer add, bitwise AND/OR/XOR, signed and unsigned minimum/maximum, exchange and compare-exchange/compare-store on supported 32-bit integer UAV/TGSM targets. The original-value overload returns the target's value before the operation, not the value calculated after it. [Structured UAV counters](formats.md#buffer-uav-fields-and-counters) use the counter-resource/offset and view restrictions of [UAV creation](formats.md#id3d12device-createunorderedaccessview), not a hidden D3D11 counter. Their counter operations do not order the associated record data or impose a deterministic order on records; the [root-UAV restrictions](binding.md#root-descriptors) remain separate.

Shader Model 6.6 adds scalar 64-bit integer atomic operations. With `D3D12_FEATURE_DATA_D3D12_OPTIONS1::Int64ShaderOps`, support is required for raw/structured resources declared as root descriptors. Other targets have independent capabilities:

| Target | Additional capability |
|---|---|
| Typed resources | `D3D12_FEATURE_DATA_D3D12_OPTIONS9::AtomicInt64OnTypedResourceSupported` |
| TGSM | `D3D12_FEATURE_DATA_D3D12_OPTIONS9::AtomicInt64OnGroupSharedSupported` |
| Resources obtained from descriptor heaps | `D3D12_FEATURE_DATA_D3D12_OPTIONS11::AtomicInt64OnDescriptorHeapResourceSupported` |

The root-descriptor requirement does not imply those optional forms. Shader Model 6.9 makes `Int64ShaderOps` required, not every optional atomic target. Typed 64-bit atomics use the operation/type/format requirements of the [owning atomic definitions](../HLSL_SM_6_6_Int64_and_Float_Atomics.md#new-atomic-functions), rather than permitting arbitrary UAV formats.

The SM6.6 floating-point additions include float exchange and bitwise compare-exchange/compare-store, not arithmetic float add/min/max. The compare operations compare the bit representation, so they are not floating-point numeric equality tests. An existing float exchange spelling is not evidence of arithmetic floating-point atomic support.

<a id="shader-barriers"></a>

## Shader memory and execution barriers

A memory fence orders specified accesses by the calling thread and provides the selected visibility scope. A group execution barrier additionally waits for the other threads in that group. These are distinct: a memory-only intrinsic does not require the rest of the group to have arrived.

| HLSL intrinsic | Memory affected | Visibility scope | Group execution rendezvous |
|---|---|---|---|
| `GroupMemoryBarrier()` | TGSM | Group | No |
| `GroupMemoryBarrierWithGroupSync()` | TGSM | Group | Yes |
| `DeviceMemoryBarrier()` | UAVs | Device for `globallycoherent` UAVs; otherwise group | No |
| `DeviceMemoryBarrierWithGroupSync()` | UAVs | Device for `globallycoherent` UAVs; otherwise group | Yes |
| `AllMemoryBarrier()` | TGSM and UAVs | As above for each memory kind | No |
| `AllMemoryBarrierWithGroupSync()` | TGSM and UAVs | As above for each memory kind | Yes |

Prior accesses of the affected kind in the calling thread's program order are made visible at the applicable scope before subsequent affected accesses. Compiler and hardware reordering must respect the fence. A group-sync variant must occur in group-uniform flow control: all threads in a group must reach the same rendezvous before any can continue. Calling one from divergent control flow has undefined behavior; returning early on only part of the group must not bypass a rendezvous required by the remaining threads. A valid barrier inside a loop requires matching participation across the group at each rendezvous.

DXBC expresses the selected fences with `sync` modifiers `_g` (TGSM), `_ugroup` (group-scope UAV), `_uglobal` (device-scope UAV, subject to the declaration) and `_t` (group execution sync). DXIL expresses the corresponding behavior through barrier operations. The opcode names do not turn a group rendezvous into a rendezvous among dispatch groups.

Multiple reads from the same address by a shader invocation that are not separated by memory barriers or writes to the address can be collapsed together. Likewise for writes. But accesses separated by a barrier cannot be merged or moved across the barrier.

<a id="barrier-flags"></a>

### Flag-based barriers (Shader Model 6.8)

The `Barrier()` intrinsic is available in all shader stages. This is a superset of existing intrinsics (which are still supported): `AllMemoryBarrier{WithGroupSync}()`, `GroupMemoryBarrier{WithGroupSync}()`, `DeviceMemoryBarrier{WithGroupSync}()`.

`Barrier()` takes flags to control its behavior, encompassing everything the existing barriers could do while being extensible. The flags selections must be static / resolvable at compile time.

The memory-kind form is `void Barrier(uint MemoryTypeFlags, uint SemanticFlags)`. In ordinary compute, `UAV_MEMORY` (`0x1`) selects all shader-accessed UAVs and `GROUP_SHARED_MEMORY` (`0x2`) selects the current group's TGSM. `ALL_MEMORY` (`0xf`) selects all applicable kinds; kinds not present in the stage are masked off only for this special value. Any other mask must contain only kinds applicable to the stage. Node input/output memory bits are not ordinary compute memory kinds.

| Semantic flag | Value | Effect |
|---|---|---|
| `GROUP_SYNC` | `0x1` | Group execution rendezvous; requires group-uniform control flow |
| `GROUP_SCOPE` | `0x2` | Group-scoped memory visibility |
| `DEVICE_SCOPE` | `0x4` | Device-scoped visibility; does not override a UAV's coherence declaration |

`GROUP_SCOPE` requires a nonzero memory-kind mask. `DEVICE_SCOPE` requires memory that can have device scope: in ordinary compute, UAV memory or a UAV object. If both scope bits are specified, device scope subsumes group scope. `GROUP_SYNC` supplies execution synchronization independently of the memory-scope flags.

The resource-object overload, `Barrier(UAVResource object, uint SemanticFlags)`, restricts the affected memory to that UAV resource rather than every UAV. It does not change the coherence and execution-scope rules. These HLSL forms require SM6.8; representability of a flag combination by an older DXIL barrier does not enable the intrinsic on earlier target profiles.

The minimal call `Barrier(0,0)` technically accomplishes nothing, as no memory type or sync has been requested.  Regardless, the DXC compiler may, in its DXIL code generation, prevent any memory access of *any* memory type from moving in either direction over any `Barrier()` call, regardless of flags in the call that might indicate specific memory types.  The underlying driver compilation, however, is free to take advantage of the specific flags.  As such, without any flags, this minimal call `Barrier(0,0)` accomplishes nothing at the level of machine code generation - it is not a barrier to anything.

The minimal calls `Barrier(UAV_MEMORY,0)` or `Barrier(myUAV,0)` signal to the driver compilation to machine code that accesses to all UAV memory, or `myUAV` in the latter case, in thread program order cannot be migrated in either direction across the barrier.  The driver compiler can freely move other memory accesses across the barrier.  There is no action at execution to ensure data visibility outside the thread, since no related `*_SCOPE` is specified in the semantic flags.  In practice some memory scope flag will be needed as well, assuming the shader invocation using the barrier wants to enforce the memory operations are seen outside it in the code order.  So the only utility in using a barrier with a memory type specified but without a memory scope is if there was a performance implication for maintaining a particular order/grouping of memory transactions local to a shader, which compiler code reordering would lose.

<a id="inter-group-ordering"></a>

### Inter-group communication and command synchronization

No automatic mechanism for synchronizing between or enforcing ordering between thread groups is specified. Synchronization across thread groups is up to the application.

Neither global coherency nor a device-scope shader fence guarantees that another group has executed or can make progress while the current group waits. A shader must not rely on all dispatch groups being resident simultaneously or implement a grid-wide execution barrier by spinning for groups that might not yet run. Wave operations likewise do not order separate groups.

To order separate dispatches or later graphics accesses, use the appropriate [command/resource synchronization](synchronization.md#barrier-operations) and [submission dependencies](execution.md#submission). A shader fence is not a command-list barrier, a queue fence, or a CPU-completion notification. Separate dispatches alone do not replace the required UAV/resource dependency.

<a id="shared-memory-initialization"></a>

## Shared-memory initialization

Uninitialized shared contents are undefined; a declaration is not an initialization to zero. A group can cooperatively initialize an array and then call `GroupMemoryBarrierWithGroupSync` before other threads consume it. Atomic updates do not initialize unrelated locations or replace the required synchronization between initialization stores and later accesses.

<a id="shared-memory-bounds"></a>

## Resource and shared-memory access bounds

Access bounds belong to the particular operation and view, not one universal compute rule. In particular, structured-resource element-index bounds are not interchangeable with an invalid byte offset inside a structure; the latter can produce undefined results or make UAV contents undefined. The [TGSM bounds](#shared-memory-bounds) are different again. Full load/store/sampling and counter algorithms remain the shader instruction/shared-operation references.

Shared-memory bounds are not the zero-read/discard-write bounds of a resource view. For DXBC `ld_raw` and `ld_structured`, an out-of-bounds component in the particular `g#` declaration returns an undefined value. For `store_raw` and `store_structured`, an out-of-bounds component in that declaration makes the entire contents of all shared memory undefined; the bound is that `g#`, not the group's combined allocation. Out-of-bounds TGSM atomics likewise make all shared memory contents undefined; returning atomics also return an undefined value.

DXIL typed shared-memory accesses must stay within their declared allocation. No zero-read, ignored-write or cross-declaration aliasing guarantee is created by its typed representation.

<a id="shared-memory-alignment"></a>

## DXBC access alignment

For DXBC raw memory views, the address is a single component unsigned 32-bit integer byte offset from the beginning of the view. The addresses must be 32-bit aligned. If an unaligned address is specified for an operation involving a write, the entire contents of the UAV being written, or all of Thread Group Shared Memory - whichever is being accessed - becomes undefined. If an unaligned address is specified for an operation involving a read, an undefined result is returned to the shader. It is invalid for implementations to perform the access as if there were no 32-bit alignment constraints.

For DXBC structured memory views, the address is two unsigned 32-bit integer values. The first value is the struct index, and the second value is a byte offset into the struct. The byte offset must be aligned to 32 bits, otherwise the same behavior described for misaligned raw memory access above applies.
