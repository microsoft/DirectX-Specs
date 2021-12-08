# Enhanced Barriers

This document proposes an enhanced D3D12 Barrier API/DDI design that is capable of fully replacing the legacy D3D12 Resource Barrier API's.

- [Introduction](#introduction)
- [D3D12 Legacy Resource Barrier Shortcomings](#d3d12-legacy-resource-barrier-shortcomings)
  - [Excessive sync latency](#excessive-sync-latency)
  - [Excessive flush operations](#excessive-flush-operations)
  - [Aliasing Barriers Are Very Expensive](#aliasing-barriers-are-very-expensive)
  - [Asymmetric Aliasing is Even More Expensive](#asymmetric-aliasing-is-even-more-expensive)
  - [Resource State Promotion and Decay](#resource-state-promotion-and-decay)
  - [Compute Queues and D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE](#compute-queues-and-d3d12_resource_state_pixel_shader_resource)
  - [Full-Resource Clear, Copy or Discard](#full-resource-clear-copy-or-discard)
  - [Simultaneous Access - But Only Across Queues](#simultaneous-access---but-only-across-queues)
  - [Inefficient Batching of Subresource Range Transitions](#inefficient-batching-of-subresource-range-transitions)
  - [Synchronous Copy, Discard and Resolve](#synchronous-copy-discard-and-resolve)
  - [No Self Copy](#no-self-copy)
- [Goals](#goals)
- [Non-Goals](#non-goals)
- [Overall Design Details](#overall-design-details)
  - [Barrier Types](#barrier-types)
  - [Synchronization](#synchronization)
  - [Layout Transitions](#layout-transitions)
  - [Access Transitions](#access-transitions)
  - [Single-Queue Simultaneous Access](#single-queue-simultaneous-access)
  - [Subresource Ranges](#subresource-ranges)
  - [Compute and Direct Queue Layouts](#compute-and-direct-queue-layouts)
  - [Barrier-Free Access](#barrier-free-access)
  - [Copy, Discard and Resolve Command Synchronization](#copy-discard-and-resolve-command-synchronization)
  - [Self Resource Copy](#self-resource-copy)
  - [Placed Resource Metadata Initialization](#placed-resource-metadata-initialization)
  - [Barrier Ordering](#barrier-ordering)
  - [New Resource Creation API's](#new-resource-creation-apis)
  - [Hardware Requirements](#hardware-requirements)
- [Compatibility with legacy D3D12_RESOURCE_STATES](#compatibility-with-legacy-d3d12_resource_states)
  - [Interop with legacy ResourceBarrier](#interop-with-legacy-resourcebarrier)
  - [Legacy layouts](#legacy-layouts)
  - [Equivalent D3D12_BARRIER_LAYOUT for each D3D12_RESOURCE_STATES bit](#equivalent-d3d12_barrier_layout-for-each-d3d12_resource_states-bit)
  - [Equivalent D3D12_BARRIER_ACCESS bit for each D3D12_RESOURCE_STATES bit](#equivalent-d3d12_barrier_access-bit-for-each-d3d12_resource_states-bit)
  - [Equivalent D3D12_BARRIER_SYNC bit for each D3D12_RESOURCE_STATES bit](#equivalent-d3d12_barrier_sync-bit-for-each-d3d12_resource_states-bit)
  - [UAV Barriers](#uav-barriers)
  - [Resource Aliasing](#resource-aliasing)
  - [Initial Resource State](#initial-resource-state)
  - [Split Barriers](#split-barriers)
  - [COMMON Layout and Access](#common-layout-and-access)
  - [Upload Heap Resources](#upload-heap-resources)
  - [Readback Heap Resources](#readback-heap-resources)
  - [Command Queue Layout Compatibility](#command-queue-layout-compatibility)
  - [Command Queue Access Compatibility](#command-queue-access-compatibility)
  - [Command Queue Sync Compatibility](#command-queue-sync-compatibility)
  - [Copy Queues](#copy-queues)
  - [Layout Access Compatibility](#layout-access-compatibility)
  - [Access Bits Barrier Sync Compatibility](#access-bits-barrier-sync-compatibility)
- [API](#api)
  - [D3D12_BARRIER_LAYOUT](#d3d12_barrier_layout)
  - [D3D12_BARRIER_SYNC](#d3d12_barrier_sync)
  - [D3D12_BARRIER_ACCESS](#d3d12_barrier_access)
  - [D3D12_BARRIER_SUBRESOURCE_RANGE](#d3d12_barrier_subresource_range)
  - [D3D12_BARRIER_TYPE](#d3d12_barrier_type)
  - [D3D12_GLOBAL_BARRIER](#d3d12_global_barrier)
  - [D3D12_TEXTURE_BARRIER_FLAGS](#d3d12_texture_barrier_flags)
  - [D3D12_TEXTURE_BARRIER](#d3d12_texture_barrier)
  - [D3D12_BUFFER_BARRIER](#d3d12_buffer_barrier)
  - [D3D12_BARRIER_GROUP](#d3d12_barrier_group)
  - [ID3D12GraphicsCommandList7::Barrier](#id3d12graphicscommandlist7barrier)
  - [ID3D12VideoDecodeCommandList3::Barrier](#id3d12videodecodecommandlist3barrier)
  - [ID3D12VideoProcessCommandList3::Barrier](#id3d12videoprocesscommandlist3barrier)
  - [ID3D12VideoEncodeCommandList3::Barrier](#id3d12videoencodecommandlist3barrier)
  - [ID3D12Device10::CreateCommittedResource3](#id3d12device10createcommittedresource3)
  - [ID3D12Device10::CreatePlacedResource2](#id3d12device10createplacedresource2)
  - [ID3D12Device10::CreateReservedResource2](#id3d12device10createreservedresource2)
- [Barrier Examples](#barrier-examples)
- [DDI](#ddi)
  - [D3D12DDI_BARRIER_LAYOUT](#d3d12ddi_barrier_layout)
  - [D3D12DDI_BARRIER_SYNC](#d3d12ddi_barrier_sync)
  - [D3D12DDI_BARRIER_ACCESS](#d3d12ddi_barrier_access)
  - [D3D12DDI_BARRIER_SUBRESOURCE_RANGE_0088](#d3d12ddi_barrier_subresource_range_0088)
  - [D3D12DDI_GLOBAL_BARRIER_0088](#d3d12ddi_global_barrier_0088)
  - [D3D12DDI_TEXTURE_BARRIER_0088_FLAGS_0088](#d3d12ddi_texture_barrier_0088_flags_0088)
  - [D3D12DDI_TEXTURE_BARRIER_0088](#d3d12ddi_texture_barrier_0088)
  - [D3D12DDI_BUFFER_BARRIER_0088](#d3d12ddi_buffer_barrier_0088)
  - [D3D12DDI_RANGED_BARRIER_FLAGS](#d3d12ddi_ranged_barrier_flags)
  - [D3D12DDI_RANGED_BARRIER_0088](#d3d12ddi_ranged_barrier_0088)
  - [D3D12DDI_BARRIER_TYPE](#d3d12ddi_barrier_type)
  - [D3D12DDIARG_BARRIER_0088](#d3d12ddiarg_barrier_0088)
  - [PFND3D12DDI_BARRIER](#pfnd3d12ddi_barrier)
  - [D3D12DDIARG_CREATERESOURCE_0088](#d3d12ddiarg_createresource_0088)
  - [PFND3D12DDI_CREATEHEAPANDRESOURCE_0088](#pfnd3d12ddi_createheapandresource_0088)
  - [PFND3D12DDI_CALCPRIVATEHEAPANDRESOURCESIZES_0088](#pfnd3d12ddi_calcprivateheapandresourcesizes_0088)
  - [PFND3D12DDI_CHECKRESOURCEALLOCATIONINFO_0088](#pfnd3d12ddi_checkresourceallocationinfo_0088)
  - [D3D12DDI_D3D12_OPTIONS_DATA_0089](#d3d12ddi_d3d12_options_data_0089)
- [Open Issues](#open-issues)
  - [Compression metadata init for LAYOUT_UNORDERED_ACCESS](#compression-metadata-init-for-layout_unordered_access)
- [Testing](#testing)
  - [Functional Testing](#functional-testing)
  - [Unit Testing](#unit-testing)
  - [HLK Testing](#hlk-testing)
- [Debug Layers](#debug-layers)
  - [Validation Phases](#validation-phases)
  - [Barrier API Call Validation](#barrier-api-call-validation)
  - [Layout Validation](#layout-validation)
  - [Access Bits Validation](#access-bits-validation)
  - [Sync Validation](#sync-validation)
  - [Global Barrier Validation](#global-barrier-validation)
  - [Legacy vs Enhanced State Validation](#legacy-vs-enhanced-state-validation)
  - [GPU-Based Validation](#gpu-based-validation)

------------------------------------------------

## Introduction

The legacy Resource Barrier design has been a source of endless app developer frustration since the beginning of D3D12.  Microsoft's documentation falls short of making sense of concepts such as resource state promotion and decay, split barriers, aliasing barriers, Copy queue states vs Direct queue states, and so on.  The debug layer helps, but validation of the convoluted barrier rules has been buggy at times.  Even when used correctly, a lot of GPU cycles are wasted in ResourceBarrier transitions due to excessive sync latency and frequent. unnecessary cache flushes.  The legacy ResourceBarrier API design itself can sometimes require otherwise-unnecessary transitions, causing additional performance loss.  These are significant pain points that have been the source of frequent customer complaints.

Now, as Microsoft looks toward leveraging D3D12 for more layering solutions similar to OpenGLOn12 and OpenCLOn12, the legacy Resource Barrier model is becoming even more burdensome as compatibility issues arise.

Enhanced Barriers are designed to address these issues while remaining compatible with legacy Resource Barrier API's.  As a bonus, enhanced Barriers expose latent hardware capabilities that legacy ResourceBarrier API's could not.

Enhanced Barriers features include:

- Reduce sync latency and excessive cache flushes.
- No mysterious Promotion and Decay rules.
- Fast, flexible resource aliasing.
- Discard during barrier transition.
- Concurrent read/write and self-copy.
- Asynchronous Discard, Copy, Resolve, and Clear commands.

------------------------------------------------

## D3D12 Legacy Resource Barrier Shortcomings

A Resource State encapsulates both the Layout of a subresource and the ways the GPU can access a subresource (e.g. UAV write, SRV read, Render Target, etc).  Resource State Transitions do the following:

1) GPU work Synchronization
   - Any in-flight GPU work accessing the transitioning subresource must be completed before a layout change or cache flush can occur
2) Subresource Layout changes
3) Memory visibility (i.e. cache flushing)

Resource States are high-level abstractions over what hardware and drivers are actually doing.  This works ok... sort of.  In reality, the only stateful property of a resource is layout.  Access to resource memory and required synchronization are transient properties that may depend on the current state of the GPU command stream rather than the resource.

### Excessive sync latency

App developers must assume that a State Transition Barrier will flush all preceding GPU work potentially-using StateBefore, and block all subsequent GPU work potentially-using StateAfter until the barrier is completed.  However, this is often performed using naive, worst-case synchronization, resulting in longer-than-necessary latency.

For example, a transition from STATE_UNORDERED_ACCESS to STATE_NON_PIXEL_SHADER_RESOURCE|STATE_PIXEL_SHADER_RESOURCE will wait for ALL preceding Graphics and Compute shader execution to complete, and block ALL subsequent Graphics and Compute shader execution.  This could be a problem if the preceding access was only in a Compute shader and subsequent access is only in a pixel shader.

### Excessive flush operations

D3D12 requires a full finish and flush of all GPU work at ExecuteCommandLists completion. Therefore, any writes to a resource during a preceding ExecuteCommandLists scope will be fully completed when that resource is needed in a subsequent ExecuteCommandLists scope.  However, drivers are not expected to keep track of when a resource was last written to.  So in addition to sync, a transition from a WRITE state may force a cache flush, even if the resource is already up-to-date from an earlier cache flush.

Assume a texture was used as a render target during a previous frame.  Now the app wants to read from that texture in a pixel shader.  Obviously a layout change may be required, but there is no need to flush any preceding Draw calls in the current ExecuteCommandLists scope. Unfortunately, a subresource state transition from D3D12_RESOURCE_STATE_RENDER_TARGET to D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE will unnecessarily force all preceding Draw commands to finish and flush before transitioning the texture layout.

### Aliasing Barriers Are Very Expensive

The Legacy Aliasing Barrier design provides no way to indicate the state of the AFTER subresource as part of the barrier.  Therefore, an additional ResourceBarrier may be needed to transition the resource to the desired state.  Not only does this further stall execution on the GPU, but a state transition always requires a BEFORE state.  As far as the D3D12 API's are concerned, the AFTER resource is still in the state was in at last use/barrier/create.  However, the contents of this memory may not match this stale state.  Transitioning this memory is wasteful at least, and could even be unstable if the driver attempts to decompress garbage memory.

Under the covers, an Aliasing Barrier typically blocks all GPU execution until all preceding work is finished and writes are flushed.  This is quite expensive, especially if resource aliasing is being used to improve application efficiency.

### Asymmetric Aliasing is Even More Expensive

The Legacy Aliasing Barrier API assumes that only a single subresource is atomically activated with only one other subresource being deactivated.  However, there are many scenarios where there are multiple overlapping subresources on the 'before' and/or 'after' side of the aliasing barrier (see *Figure 1*).

![Figure 1](images/D3D12PipelineBarriers/AsymAliasing.png)
*Figure 1*

In *Figure 1*, NewTex1 partially overlaps OldTex1 and OldBuf2, which are also partially aliased with other after-resources.  The only way to accomplish this using Legacy Aliasing Barriers is to use a "null/null" aliasing barrier, which is guaranteed to produces a full GPU execution stall.  This is especially unfortunate if all commands accessing OldTex1, OldBuf1, and OldBuf2 have already completed.

### Resource State Promotion and Decay

[Implicit State Transitions (promotion and decay)](https://docs.microsoft.com/en-us/windows/win32/direct3d12/using-resource-barriers-to-synchronize-resource-states-in-direct3d-12#implicit-state-transitions) was invented to help support such scenarios.  Unfortunately, Implicit state promotion and decay is a major source of confusion for developers.  There are complex - and evolving - rules about when promotion and decay occur.

Some of the promotion/decay rules include:

- Non-simultaneous-access textures can only be promoted to COPY_SOURCE, COPY_DEST, or *_SHADER_RESOURCE.
- Buffers and simultaneous-access textures can be promoted to ANY state.
  - Except DEPTH_STENCIL.
- Resources promoted to a READ state will decay to STATE_COMMON when ExecuteCommandLists completes.
  - But not resources promoted to a write state.
- Resources can be cumulatively promoted to multiple read-states but only a single write-state.
- All resources used in Copy queues must begin in the COMMON state and always decay back to COMMON when ExecuteCommandLists completes.
- Resources promoted to STATE_COPY_DEST are left in STATE_COPY_DEST
  - Except for resources used in Copy queues, which decay back to STATE_COMMON.

Promotion and decay reflect the natural consequences of ExecuteCommandLists boundaries.  However, some developers incorrectly assume that hidden barriers are being inserted behind the scenes.  As such, it is common for promotion and decay to be ignored, resulting in excessive use of unnecessary barriers with noticeable performance impact.

### Compute Queues and D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE

The D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE state is only usable in Direct command lists.  Therefore, a Compute queue cannot use or transition a resource in state D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE|D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE.  However, Compute queues DO support D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE, which has an identical layout in both Direct and Compute queues.  This design oversight is a common source of d3d12 app developer frustration.  The primary reason for the separate states is to provide precise execution sync and memory flush for a Direct queue.  However, when passing resources between Direct and Compute queues, sync and flush are handled using fences.

### Full-Resource Clear, Copy or Discard

According to earlier D3D12 specifications, Clear, Copy or Discard commands require destination resources be in a specific resource state.  Typically, this involves a state transition from a prior state.  This makes sense when only a portion of the resource is being written to or discarded.  However, when performing a full-resource Clear, Copy or Discard, the old resource data is being completely replaced.  Therefore, a layout transition seems unnecessary.

This is particularly interesting when it comes to resource aliasing or updated tile mapping, as these operations require full-resource Clear, Copy or Discard when the target resource is either RENDER_TARGET or DEPTH_STENCIL.  In such cases, there may not even be a previous "state" to transition from.  In fact, it is conceivable that a memory-decompressing state transition could trigger device removal.

### Simultaneous Access - But Only Across Queues

Buffers and simultaneous-access resources can be written to in one queue while concurrently being read-from one or more OTHER queues.  However, this pattern is not supported in a single queue because legacy Resource Barrier design prevents subresources from being in both READ and WRITE states at the same time.  However, hardware can support same-queue simultaneous-access; Layout is always COMMON and there is no sync or flush needed since the reads are non-dependent.

### Inefficient Batching of Subresource Range Transitions

Resource State Transition Barriers provide a choice of transitioning either ALL subresources (subresource index set to 0xFFFFFFFF) or a single subresource.  This may be inefficient when transitioning a large range of logically-adjacent subresources, such as a range of array slices or a full mip-level chain in a single array slice.  It can be costly to build the array of individual transition elements and the translation from [mip-level, array-slice, plane-slice] to subresource-index is a common source of app bugs.

### Synchronous Copy, Discard and Resolve

With the exception of UAV barriers, legacy ResourceBarrier API's have no way to express dependent writes to the same resource.  For example, a Copy from resource A->B along with a Copy from resource C->B could produce different results if copies actually complete in different orders.  As a result, all Copy, Discard and Resolve commands execute synchronously, with an implicit sync and flush after each command.

### No Self Copy

According to the D3D12 specifications, a subresource cannot be in a state that combines *read-only* bits and *write* bits.  Therefore a resource cannot be in the D3D12_RESOURCE_STATE_COPY_SOURCE|D3D12_RESOURCE_STATE_COPY_DEST state.  This rule applies for promoted states as well, so a resource in a COMMON state cannot be implicitly promoted to both COPY_SOURCE and COPY_DEST at the same time.

------------------------------------------------

## Goals

- Legacy Resource Barriers can be fully implemented using D3D12 Barrier DDI's with NO noticeable performance loss.
- App developers can independently express synchronization, memory access, and layout of all subresources used in the GPU command stream.
- The enhanced Barrier API's match actual hardware and driver behaviors better than legacy Resource Barriers.

------------------------------------------------

## Non-Goals

- Deprecate legacy Resource Barrier API's
  - Legacy Resource Barrier API's must remain available with no functional changes in behavior.

------------------------------------------------

## Overall Design Details

Drivers typically handle legacy Resource Barriers using three separate operations:

1) Synchronize GPU work
2) Perform any necessary cache flush operations
3) Perform any necessary layout changes

The enhanced Barrier API's give developers the ability to control each of these operations separately.

### Barrier Types

Enhanced Barrier API's provide three barrier types:

- Texture Barriers
- Buffer Barriers
- Global Barriers

#### Texture Barriers

Texture Barriers control cache flush, memory layout and synchronization for texture subresources.  Texture Barriers must only be used with texture resources.  Texture barriers allow selection of a single subresource, all subresources, or a coherent range of subresources (i.e. mip range and array range).  Texture barriers must provide a valid, non-NULL resource pointer.

#### Buffer Barriers

Buffer Barriers control cache flush and synchronization for buffer resources.  Buffer Barriers must only be used with buffer resources.  Unlike textures, buffers have only a single subresource and do not have a transitionable layout.  Buffer barriers must provide a valid, non-NULL resource pointer.

Buffer subregion barriers are supported in other low-level graphics API's.  However how these barriers work with various memory, caches or whether they guarantee multi-writer support is unclear.  The D3D12_BUFFER_BARRIER structure does include UINT64 Offset and UINT64 Size members to facilitate future buffer subregion barriers.  For now, Offset must be zero and Size must be either the buffer size in bytes or UINT64_MAX.  Note that enhanced barriers already supports concurrent read and write on buffers without the need for intervening barriers (see [Single-Queue Simultaneous Access](#single-queue-simultaneous-access)).

The current enhanced buffer barrier DDI's do not use Offset or Size, avoiding any need for drivers to handle this no-yet-required feature.

#### Global Barriers

Global barriers control cache flush and synchronization for all indicated resource access types in a single command queue.  Global Barriers have no effect on texture layout.  Global Barriers are needed to provide functionality similar to legacy NULL UAV barriers and NULL/NULL aliasing barriers.

Since global barriers do not transition texture layout, global barriers may not be used in transitions that otherwise would require a layout change. For example, a global barrier cannot be used to transition a non-simultaneous-access texture from ACCESS_RENDER_TARGET to ACCESS_SHADER_RESOURCE, since that would also require a change from LAYOUT_RENDER_TARGET to LAYOUT_SHADER_RESOURCE.

### Synchronization

Graphics processors are designed to execute as much work in parallel as possible.  Any GPU work that depends on previous GPU work must be synchronized before accessing dependent data.

With legacy Resource Barriers, drivers must infer which work to synchronize.  Often this is a best-guess since the driver may not be able to determine when a subresource was last accessed.  Typically, the driver must assume the worst-case: any previous work that *could* have accessed a resource in StateBefore must be synchronized with any work that *could* access the resource in StateAfter.

The enhanced Barrier API's use explicit SyncBefore and SyncAfter values as logical bitfield masks.  A Barrier must wait for all preceding command SyncBefore scopes to complete before executing the barrier.  Similarly, a Barrier must block all subsequent SyncAfter scopes until the barrier completes.

D3D12_BARRIER_SYNC_NONE indicates synchronization is not needed either before or after barrier.  A SYNC_NONE SyncBefore value implies that the corresponding subresources are not accessed before the barrier in the same ExecuteCommandLists scope.  Likewise, a SYNC_NONE SyncAfter value implies that the corresponding subresources are not accessed after the barrier in the same ExecuteCommandLists scope.  Therefore, Sync[Before|After] D3D12_BARRIER_SYNC_NONE must be paired with Access[Before|After] D3D12_BARRIER_ACCESS_NO_ACCESS.

If a barrier SyncBefore is D3D12_BARRIER_SYNC_NONE, then AccessBefore MUST be D3D12_BARRIER_ACCESS_NO_ACCESS.  In this case, there MUST have been no preceding barriers or accesses made to that resource in the same ExecuteCommandLists scope.

If a barrier SyncAfter is D3D12_BARRIER_SYNC_NONE, then AccessAfter MUST be D3D12_BARRIER_ACCESS_NO_ACCESS.  Afterward, there MUST be no subsequent barriers or accesses made to the associated resource in the same ExecuteCommandLists scope.

When used, D3D12_BARRIER_SYNC_NONE must be the only bit set.

#### Umbrella Synchronization Scopes

Umbrella synchronization scopes supersede one or more other synchronization scopes, and can effectively be treated as though all of the superseded scope bits are set.  For example, the SYNC_DRAW scope supersedes SYNC_INPUT_ASSEMBLER, SYNC_VERTEX_SHADING, SYNC_PIXEL_SHADING, SYNC_DEPTH_STENCIL, and SYNC_RENDER_TARGET (see Figure 2).

![Figure 2](images/D3D12PipelineBarriers/OverlappingScopes.png)
*Figure 2*

The following tables list superseded synchronization scope bits for each umbrella synchronization scope bit.

| D3D12_BARRIER_SYNC_ALL               |
|--------------------------------------|
| D3D12_BARRIER_SYNC_DRAW              |
| D3D12_BARRIER_SYNC_INPUT_ASSEMBLER   |
| D3D12_BARRIER_SYNC_VERTEX_SHADING    |
| D3D12_BARRIER_SYNC_PIXEL_SHADING     |
| D3D12_BARRIER_SYNC_DEPTH_STENCIL     |
| D3D12_BARRIER_SYNC_RENDER_TARGET     |
| D3D12_BARRIER_SYNC_COMPUTE_SHADING   |
| D3D12_BARRIER_SYNC_RAYTRACING        |
| D3D12_BARRIER_SYNC_COPY              |
| D3D12_BARRIER_SYNC_RESOLVE           |
| D3D12_BARRIER_SYNC_EXECUTE_INDIRECT  |
| D3D12_BARRIER_SYNC_PREDICATION       |
| D3D12_BARRIER_SYNC_VIDEO_DECODE      |
| D3D12_BARRIER_SYNC_VIDEO_PROCESS     |
| D3D12_BARRIER_SYNC_VIDEO_ENCODE      |

| D3D12_BARRIER_SYNC_DRAW            |
|------------------------------------|
| D3D12_BARRIER_SYNC_INPUT_ASSEMBLER |
| D3D12_BARRIER_SYNC_VERTEX_SHADING  |
| D3D12_BARRIER_SYNC_PIXEL_SHADING   |
| D3D12_BARRIER_SYNC_DEPTH_STENCIL   |
| D3D12_BARRIER_SYNC_RENDER_TARGET   |

| D3D12_BARRIER_SYNC_ALL_SHADING     |
|------------------------------------|
| D3D12_BARRIER_SYNC_VERTEX_SHADING  |
| D3D12_BARRIER_SYNC_PIXEL_SHADING   |
| D3D12_BARRIER_SYNC_COMPUTE_SHADING |

| D3D12_BARRIER_SYNC_NON_PIXEL_SHADING |
|--------------------------------------|
| D3D12_BARRIER_SYNC_VERTEX_SHADING    |
| D3D12_BARRIER_SYNC_COMPUTE_SHADING   |

#### Sequential Barriers

Any barrier subsequent to another barrier on the same subresource in the same ExecuteCommandLists scope must use a SyncBefore value that fully-contains the preceding barrier SyncAfter scopes.

To provide well-defined barrier ordering, sequential, adjacent barriers on the same subresource with no intervening commands behave as though all SyncBefore and SyncAfter bits are logically combined.

#### Barrier Sync Examples

| SyncBefore             | SyncAfter              |
|------------------------|------------------------|
| D3D12_BARRIER_SYNC_ALL | D3D12_BARRIER_SYNC_ALL |

Execute barrier **after** all preceding GPU work has completed and block **all subsequent work** until barrier has completed.

| SyncBefore             | SyncAfter            |
|------------------------|----------------------|
| D3D12_BARRIER_SYNC_ALL | *specific sync bits* |

Execute barrier **after** all preceding GPU work has completed and block *specific sync bits* GPU work until barrier has completed.

| SyncBefore           | SyncAfter              |
|----------------------|------------------------|
| *specific sync bits* | D3D12_BARRIER_SYNC_ALL |

Execute barrier **after** *specific sync bits* GPU work has completed and block **all subsequent work** until barrier has completed.

| SyncBefore              | SyncAfter            |
|-------------------------|----------------------|
| D3D12_BARRIER_SYNC_NONE | *specific sync bits* |

Execute barrier **before** *specific sync bits* GPU work, but do not wait for any preceding work.

| SyncBefore           | SyncAfter               |
|----------------------|-------------------------|
| *specific sync bits* | D3D12_BARRIER_SYNC_NONE |

Execute barrier **after** *specific sync bits* GPU work but do not block any subsequent work.

| SyncBefore                        | SyncAfter                          |
|-----------------------------------|------------------------------------|
| D3D12_BARRIER_SYNC_VERTEX_SHADING | D3D12_BARRIER_SYNC_COMPUTE_SHADING |

Execute barrier **after** all vertex stages have completed and block subsequent compute shading work until barrier has completed.

| SyncBefore              | SyncAfter               |
|-------------------------|-------------------------|
| D3D12_BARRIER_SYNC_NONE | D3D12_BARRIER_SYNC_NONE |

Execute barrier without waiting for preceding work or blocking subsequent work.  This is something an app might do in a ExecuteCommandLists call that only performs Barriers

### Layout Transitions

Texture subresources may use different layouts for various access methods.  For example, textures are often compressed when used as a render target or depth stencil and are often uncompressed for shader read or copy commands.  Texture Barriers use LayoutBefore and LayoutAfter D3D12_BARRIER_LAYOUT values to describe layout transitions.

Layout transitions are only needed for textures, therefore they are expressed only in the D3D12_TEXTURE_BARRIER data structure.

Both LayoutBefore and LayoutAfter must be compatible with the type of queue performing the Barrier.  For example, a compute queue cannot transition a subresource into or out of D3D12_BARRIER_LAYOUT_RENDER_TARGET.

To provide well-defined barrier ordering, the layout of a subresource after completing a sequence of barriers is the final LayoutAfter in the sequence.

### Access Transitions

Since many GPU-write operations are cached, any Barrier from a write access to another write access or a read-only access may require a cache flush.  The enhanced Barrier API's use access transitions to indicate that a subresource's memory needs to be made visible for a specific new access type.  Like the layout transitions, some access transitions may not be needed if it is known that the memory of the associated subresource is already accessible for the desired use.

Access transitions for textures are expressed as part of the D3D12_TEXTURE_BARRIER structure data.  Access transitions for buffers are expressed using the D3D12_BUFFER_BARRIER structure.

Access transitions do not perform synchronization.  It is expected that synchronization between dependent accesses is handled using appropriate SyncBefore and SyncAfter values in the barrier.

An AccessBefore made visible to a specified AccessAfter DOES NOT guarantee that the resource memory is also visible for a *different* access type.  For example:

```C++
MyTexBarrier.AccessBefore=UNORDERED_ACCESS;
MyTexBarrier.AccessAfter=SHADER_RESOURCE;
```

This access transition indicates that a subsequent shader-read access depends on a preceding unordered-access-write.  However, this may not actually flush the UAV cache if the hardware is capable of reading shader resources directly from the UAV cache.

To provide well-defined barrier ordering, the access status of a subresource after completing a sequence of barriers is the final AccessAfter in the sequence.

Subresources with BARRIER_ACCESS_COMMON status can be used in a barrier with non-ACCESS_COMMON AccessBefore bits, so long as those bits are compatible with the subresource layout and create flags.

### Single-Queue Simultaneous Access

The enhanced Barrier API allows concurrent read write operations on the same buffer or simultaneous-access texture in the same command queue.

Buffers and SIMULTANEOUS_ACCESS resources have always supported write access from one queue with concurrent, non-dependent read accesses from one or more other queues.  This is because such resources always use the COMMON layout and have no read/write hazards since reads must not depend on concurrent writes.  Unfortunately, legacy Resource Barrier rules disallow combining write state bits with any other state bits.  As such, resources cannot be concurrently read-from and written-to in the same queue using legacy ResourceBarrier API's.

Note that the one-writer-at-a-time policy still applies since two seemingly non-intersecting write operations may still have overlapping cache lines.

### Subresource Ranges

It is common for developers to want to transition a range of subresources such as a full mip-chain for a given texture array or a single mip-level for all array slices.  Legacy Resource State Transition barriers only provide developers the option of transitioning ALL subresource states or single subresource state atomically.  The enhanced Barrier API's allow developers to transition logically-adjacent ranges of subresources using the [D3D12_BARRIER_SUBRESOURCE_RANGE](#D3D12_BARRIER_SUBRESOURCE_RANGE) structure.

### Compute and Direct Queue Layouts

The following enhanced Barrier layouts are guaranteed to be the same for both Direct and Compute queues:

- D3D12_BARRIER_LAYOUT_GENERIC_READ
- D3D12_BARRIER_LAYOUT_UNORDERED_ACCESS
- D3D12_BARRIER_LAYOUT_SHADER_RESOURCE
- D3D12_BARRIER_LAYOUT_COPY_SOURCE
- D3D12_BARRIER_LAYOUT_COPY_DEST

A subresource in one of these layouts can be used in either Direct queues or Compute queues without a layout transition.

On some hardware, layout transition barriers on Direct queues can be significantly faster if both preceding or subsequent accesses are also on Direct queues.  It is strongly recommended that app developers predominantly accessing resources on Direct queues use the following layouts:

- D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_GENERIC_READ
- D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_UNORDERED_ACCESS
- D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_SHADER_RESOURCE
- D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COPY_SOURCE
- D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COPY_DEST

The DIRECT_QUEUE layout variants are not compatible with Compute queues and cannot be used in Compute command list barriers.  However, they are compatible with Compute operations in Direct queues.

### Barrier-Free Access

Since there must be no pending commands or cache flush operations between ExecuteCommandLists boundaries, buffers MAY be initially accessed in an ExecuteCommandLists scope without a Barrier.  Likewise, texture subresources may also be initially accessed without a barrier under the following conditions:

- The subresource layout is compatible with the access type
- Any necessary compression metadata has been initialized

D3D12_BARRIER_ACCESS status bits are not propagated between ExecuteCommandLists boundaries, and are always considered to be D3D12_BARRIER_ACCESS_COMMON (0) at the start of ExecuteCommandLists scope.

Texture subresources in layout D3D12_BARRIER_LAYOUT_COMMON, with no potentially outstanding read or write operations, MAY be accessed in an ExecuteCommandLists command stream without a Barrier using any of the following access types:

- D3D12_BARRIER_ACCESS_SHADER_RESOURCE
- D3D12_BARRIER_ACCESS_COPY_SOURCE
- D3D12_BARRIER_ACCESS_COPY_DEST

Buffers and Simultaneous-Access Textures (Textures created with the D3D12_RESOURCE_FLAG_ALLOW_SIMULTANEOUS_ACCESS flag) MAY be initially accessed in an ExecuteCommandLists command stream without a Barrier using any of the following access types:

- D3D12_BARRIER_ACCESS_VERTEX_BUFFER
- D3D12_BARRIER_ACCESS_CONSTANT_BUFFER
- D3D12_BARRIER_ACCESS_INDEX_BUFFER
- D3D12_BARRIER_ACCESS_RENDER_TARGET
- D3D12_BARRIER_ACCESS_UNORDERED_ACCESS
- D3D12_BARRIER_ACCESS_SHADER_RESOURCE
- D3D12_BARRIER_ACCESS_STREAM_OUTPUT
- D3D12_BARRIER_ACCESS_INDIRECT_ARGUMENT
- D3D12_BARRIER_ACCESS_COPY_DEST
- D3D12_BARRIER_ACCESS_COPY_SOURCE
- D3D12_BARRIER_ACCESS_RESOLVE_DEST
- D3D12_BARRIER_ACCESS_RESOLVE_SOURCE
- D3D12_BARRIER_ACCESS_PREDICATION

Subsequent accesses MAY also be made without a barrier with no more than one write access type.  However, with the exception of ACCESS_RENDER_TARGET, barriers MUST be used to flush sequential writes to the same resource.

### Copy, Discard and Resolve Command Synchronization

A new set of Copy, Discard and Resolve ID3D12GraphicsCommandList methods support asynchronous execution:

AsyncCopyBufferRegion
AsyncCopyResource
AsyncCopyTextureRegion
AsyncDiscardResource
AsyncResolveSubresource

Resource accesses depending on Async writes must be synchronized using barriers.  Note, ALL writes to a given subresource are treated as dependent on any previous writes to the same subresource.  This is due to opaque hardware cache flushing behaviors, which may result in destructive memory writes even if the writes happen in non-overlapping memory ranges.  The debug layer reports all detectable read-after-write and write-after-write hazards involving these new methods.

Existing Copy, Discard and Resolve commands remain synchronous.

### Self Resource Copy

Though not exclusively related to the enhanced Barrier API's, the ability to allow copies from one region of a subresource to another non-intersecting region is a highly-requested feature.  According to the legacy Resource Barrier design, a subresource cannot be in both the COPY_SOURCE and COPY_DEST state at the same time, and thus cannot copy to itself.

With Enhanced Barriers, a subresource with a layout of D3D12_BARRIER_LAYOUT_COMMON and both the D3D12_BARRIER_ACCESS_COPY_DEST and D3D12_BARRIER_ACCESS_COPY_SOURCE access bits set can be used as both a source and destination in the same CopyBufferRegion or CopyTextureRegion call.  Copies between intersecting source and dest memory regions produce undefined results.  The Debug Layer MUST validate against this.

### Placed Resource Metadata Initialization

The legacy Resource Barrier design requires newly-placed and activated aliased texture resources to be initialized by Clear, Copy, or Discard before using as a Render Target or Depth Stencil resource.  This is because Render Target and Depth Stencil resources typically use compression metadata that must be initialized for the data to be valid.  The same goes for reserved textures with newly updated tile mapping.

Enhanced Barriers support an option to Discard as part of a barrier.  Barrier layout transitions from D3D12_BARRIER_LAYOUT_UNDEFINED to any potentially-compressed layout (e.g. D3D12_BARRIER_LAYOUT_RENDER_TARGET, D3D12_BARRIER_LAYOUT_DEPTH_STENCIL, D3D12_BARRIER_LAYOUT_UNORDERED_ACCESS) MUST initialize compression metadata when D3D12_TEXTURE_BARRIER_FLAG_DISCARD is present in the D3D12_TEXTURE_BARRIER::Flags member.

In addition to render target and depth/stencil resources, there are similar UAV texture compression optimizations that the legacy Barrier model did not support.

### Barrier Ordering

Barriers are queued in forward order (API-call order, barrier-group-index, barrier-array-index).  Multiple barriers on the same subresource must function as though the barriers complete in queued order.

Queued Barriers with matching SyncAfter scopes that potentially write to the same memory must complete all writes in queued order.  This is necessary to avoid data races on barriers that support resource aliasing.  For example a barrier that 'deactivates' a resource must flush any caches before another barrier that 'activates a different resource on the same memory, possible clearing metadata.

### New Resource Creation API's

To fully support enhanced barriers, developers need to be able to create resources with InitialLayout rather than InitialState.  This is especially true given the fact that there exist some layouts that do not deterministically map to a legacy D3D12_RESOURCE_STATE (e.g. D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_COPY_DEST).

Buffers may only use D3D12_BARRIER_LAYOUT_UNDEFINED as an initial layout.

### Hardware Requirements

Enhanced Barriers is not currently a hardware or driver requirement.  Developers must check for optional driver support before using command list  Barrier API's or resource Create methods using InitialLayout.

```c++
    D3D12_FEATURE_DATA_D3D12_OPTIONS12 options12 = {};
    bool EnhancedBarriersSupported = false;
    if(SUCCEEDED(pDevice->CheckFeatureSupport(D3D12_FEATURE_D3D12_OPTIONS12, &options12, sizeof(options12))))
    {
        EnhancedBarriersSupported = options12.EnhancedBarriersSupported;
    }
```

#### D3D12_RESOURCE_FLAG_RAYTRACING_ACCELERATION_STRUCTURE

Since resources are created with InitialLayout instead of InitialState, and buffer resources have no layout, a new D3D12_RESOURCE_FLAGS enum value is needed to indicate that a buffer is to be used as a raytracing accelleration structure:

------------------------------------------------

## Compatibility with legacy D3D12_RESOURCE_STATES

The D3D12 runtime internally translates all ResourceBarrier calls to equivalent enhanced Barriers at the driver interface.  Legacy barrier DDI's are never invoked on a driver supporting enhanced barriers.

### Interop with legacy ResourceBarrier

Interop between enhanced Barrier API's and existing D3D12_RESOURCE_STATES is supported.  However, subresources in any legacy state other than D3D12_RESOURCE_STATE_COMMON must be transitioned to D3D12_RESOURCE_STATE_COMMON before being referenced using an enhanced Barrier.  Likewise, subresources that do not have a legacy state must be transitioned to D3D12_BARRIER_ACCESS_COMMON and (if applicable) D3D12_BARRIER_LAYOUT_COMMON before being referenced using a legacy ResourceBarrier.

### Legacy layouts

Legacy resource state rules allow textures in the state D3D12_RESOURCE_STATE_COMMON to be "promoted" to one of the following:

- D3D12_RESOURCE_STATE_COPY_DEST
- D3D12_RESOURCE_STATE_COPY_SOURCE
- D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE
- D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE

This promotion can occur during state transformation ResourceBarrier, where the StateBefore value is one of these states, but the actual subresource state is D3D12_RESOURCE_STATE_COMMON.  From an enhanced barriers perspective the LayoutBefore may be either D3D12_BARRIER_LAYOUT_COMMON or D3D12_BARRIER_LAYOUT_<SOMETHING_SPECIFIC>.  Therefore, four internal-only layouts are used to to support legacy ResourceBarrier to enhanced Barrier calls by the D3D12 runtime:

- D3D12_BARRIER_LAYOUT_LEGACY_COPY_DEST
- D3D12_BARRIER_LAYOUT_LEGACY_COPY_SOURCE
- D3D12_BARRIER_LAYOUT_LEGACY_PIXEL_SHADER_RESOURCE
- D3D12_BARRIER_LAYOUT_LEGACY_SHADER_RESOURCE

It is the driver's responsibility to determine the actual memory layout of a resource using one of these legacy layouts.  This is not new behavior since drivers needed to do this for legacy barriers.  These layouts are not exposed in the public API and may not be used in enhanced Barrier API calls.  Invalid layout values in Barrier API calls, including these, result in removal of command list.

### Equivalent D3D12_BARRIER_LAYOUT for each D3D12_RESOURCE_STATES bit

Layouts enums starting with 'D3D12_BARRIER_LAYOUT_LEGACY_' are internal-only and not exposed in public headers.  These exist only for internal translation of legacy ResourceBarrier API's. See [Legacy layouts](#legacy-layouts).

State bit                                              | Layout
-------------------------------------------------------|-----------------------------------------
D3D12_RESOURCE_STATE_COMMON                            | D3D12_BARRIER_LAYOUT_COMMON
D3D12_RESOURCE_STATE_VERTEX_BUFFER                     | N/A
D3D12_RESOURCE_STATE_CONSTANT_BUFFER                   | N/A
D3D12_RESOURCE_STATE_INDEX_BUFFER                      | N/A
D3D12_RESOURCE_STATE_RENDER_TARGET                     | D3D12_BARRIER_LAYOUT_RENDER_TARGET
D3D12_RESOURCE_STATE_UNORDERED_ACCESS                  | D3D12_BARRIER_LAYOUT_UNORDERED_ACCESS
D3D12_RESOURCE_STATE_DEPTH_WRITE                       | D3D12_BARRIER_LAYOUT_DEPTH_STENCIL_WRITE
D3D12_RESOURCE_STATE_DEPTH_READ                        | D3D12_BARRIER_LAYOUT_DEPTH_STENCIL_READ
D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE         | D3D12_BARRIER_LAYOUT_LEGACY_SHADER_RESOURCE*
D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE             | D3D12_BARRIER_LAYOUT_LEGACY_SHADER_RESOURCE*
D3D12_RESOURCE_STATE_STREAM_OUT                        | N/A
D3D12_RESOURCE_STATE_INDIRECT_ARGUMENT                 | N/A
D3D12_RESOURCE_STATE_PREDICATION                       | N/A
D3D12_RESOURCE_STATE_COPY_DEST                         | D3D12_BARRIER_LAYOUT_LEGACY_COPY_DEST*
D3D12_RESOURCE_STATE_COPY_SOURCE                       | D3D12_BARRIER_LAYOUT_LEGACY_COPY_SOURCE*
D3D12_RESOURCE_STATE_RESOLVE_DEST                      | D3D12_BARRIER_LAYOUT_RESOLVE_DEST
D3D12_RESOURCE_STATE_RESOLVE_SOURCE                    | D3D12_BARRIER_LAYOUT_RESOLVE_SOURCE
D3D12_RESOURCE_STATE_RAYTRACING_ACCELERATION_STRUCTURE | N/A
D3D12_RESOURCE_STATE_SHADING_RATE_SOURCE               | D3D12_BARRIER_LAYOUT_SHADING_RATE_SOURCE

### Equivalent D3D12_BARRIER_ACCESS bit for each D3D12_RESOURCE_STATES bit

State bit                                              | Access bit
-------------------------------------------------------|------------------------------------------------------------------------
D3D12_RESOURCE_STATE_COMMON                            | D3D12_BARRIER_ACCESS_COMMON
D3D12_RESOURCE_STATE_VERTEX_BUFFER                     | D3D12_BARRIER_ACCESS_VERTEX_BUFFER+D3D12_BARRIER_ACCESS_CONSTANT_BUFFER
D3D12_RESOURCE_STATE_CONSTANT_BUFFER                   | D3D12_BARRIER_ACCESS_VERTEX_BUFFER+D3D12_BARRIER_ACCESS_CONSTANT_BUFFER
D3D12_RESOURCE_STATE_INDEX_BUFFER                      | D3D12_BARRIER_ACCESS_INDEX_BUFFER
D3D12_RESOURCE_STATE_RENDER_TARGET                     | D3D12_BARRIER_ACCESS_RENDER_TARGET
D3D12_RESOURCE_STATE_UNORDERED_ACCESS                  | D3D12_BARRIER_ACCESS_UNORDERED_ACCESS
D3D12_RESOURCE_STATE_DEPTH_WRITE                       | D3D12_BARRIER_ACCESS_DEPTH_STENCIL_WRITE
D3D12_RESOURCE_STATE_DEPTH_READ                        | D3D12_BARRIER_ACCESS_DEPTH_STENCIL_READ
D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE         | D3D12_BARRIER_ACCESS_SHADER_RESOURCE
D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE             | D3D12_BARRIER_ACCESS_SHADER_RESOURCE
D3D12_RESOURCE_STATE_STREAM_OUT                        | D3D12_BARRIER_ACCESS_STREAM_OUTPUT
D3D12_RESOURCE_STATE_INDIRECT_ARGUMENT                 | D3D12_BARRIER_ACCESS_INDIRECT_ARGUMENT
D3D12_RESOURCE_STATE_PREDICATION                       | D3D12_BARRIER_ACCESS_PREDICATION
D3D12_RESOURCE_STATE_COPY_DEST                         | D3D12_BARRIER_ACCESS_COPY_DEST
D3D12_RESOURCE_STATE_COPY_SOURCE                       | D3D12_BARRIER_ACCESS_COPY_SOURCE
D3D12_RESOURCE_STATE_RESOLVE_DEST                      | D3D12_BARRIER_ACCESS_RESOLVE_DEST
D3D12_RESOURCE_STATE_RESOLVE_SOURCE                    | D3D12_BARRIER_ACCESS_RESOLVE_SOURCE
D3D12_RESOURCE_STATE_RAYTRACING_ACCELERATION_STRUCTURE | D3D12_BARRIER_ACCESS_RAYTRACING_ACCELERATION_STRUCTURE
D3D12_RESOURCE_STATE_SHADING_RATE_SOURCE               | D3D12_BARRIER_ACCESS_SHADING_RATE_SOURCE

Non-simultaneous-access textures using a COMMON layout can be accessed as D3D12_BARRIER_ACCESS_COPY_DEST | D3D12_BARRIER_ACCESS_COPY_SOURCE | D3D12_BARRIER_ACCESS_SHADER_RESOURCE.  Buffers and simultaneous-access textures can be freely accessed as all-but D3D12_BARRIER_ACCESS_DEPTH_STENCIL_WRITE | D3D12_BARRIER_ACCESS_DEPTH_STENCIL_READ | D3D12_RESOURCE_STATE_RAYTRACING_ACCELERATION_STRUCTURE.

### Equivalent D3D12_BARRIER_SYNC bit for each D3D12_RESOURCE_STATES bit

State bit                                              | Sync bit
-------------------------------------------------------|-------------------------------------
D3D12_RESOURCE_STATE_COMMON                            | D3D12_BARRIER_SYNC_ALL
D3D12_RESOURCE_STATE_VERTEX_AND_CONSTANT_BUFFER        | D3D12_BARRIER_SYNC_ALL_SHADING
D3D12_RESOURCE_STATE_INDEX_BUFFER                      | D3D12_BARRIER_SYNC_INPUT_ASSEMBLER
D3D12_RESOURCE_STATE_RENDER_TARGET                     | D3D12_BARRIER_SYNC_RENDER_TARGET
D3D12_RESOURCE_STATE_UNORDERED_ACCESS                  | D3D12_BARRIER_SYNC_ALL_SHADING
D3D12_RESOURCE_STATE_DEPTH_WRITE                       | D3D12_BARRIER_SYNC_DEPTH_STENCIL
D3D12_RESOURCE_STATE_DEPTH_READ                        | D3D12_BARRIER_SYNC_DEPTH_STENCIL
D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE         | D3D12_BARRIER_SYNC_NON_PIXEL_SHADING
D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE             | D3D12_BARRIER_SYNC_PIXEL_SHADING
D3D12_RESOURCE_STATE_STREAM_OUT                        | D3D12_BARRIER_SYNC_VERTEX_SHADING
D3D12_RESOURCE_STATE_INDIRECT_ARGUMENT                 | D3D12_BARRIER_SYNC_EXECUTE_INDIRECT
D3D12_RESOURCE_STATE_PREDICATION                       | D3D12_BARRIER_SYNC_PREDICATION
D3D12_RESOURCE_STATE_COPY_DEST                         | D3D12_BARRIER_SYNC_COPY
D3D12_RESOURCE_STATE_COPY_SOURCE                       | D3D12_BARRIER_SYNC_COPY
D3D12_RESOURCE_STATE_RESOLVE_DEST                      | D3D12_BARRIER_SYNC_RESOLVE
D3D12_RESOURCE_STATE_RESOLVE_SOURCE                    | D3D12_BARRIER_SYNC_RESOLVE
D3D12_RESOURCE_STATE_RAYTRACING_ACCELERATION_STRUCTURE | D3D12_BARRIER_SYNC_RAYTRACING
D3D12_RESOURCE_STATE_SHADING_RATE_SOURCE               | D3D12_BARRIER_SYNC_PIXEL_SHADING

### UAV Barriers

UAV Barriers are simply synchronization barriers between preceding and subsequent shader execution scopes, with possible UAV cache flush.  A UAV barrier can be achieved using enhanced Barrier API's by setting SyncBefore to the scope where the preceding UAV access occurred, and a SyncAfter to the scope where the subsequent UAV access is to be made.  AccessBefore and AccessAfter must both be ACCESS_UNORDERED_ACCESS.  Additionally for textures, LayoutBefore and LayoutAfter must both be LAYOUT_UNORDERED_ACCESS.

UAV Barriers are used for both shader UAV accesses and raytracing acceleration structure accesses.  Therefore, the Enhanced Barrier equivalent for a legacy UAV barrier in a graphics command list is:

``` C++
UAVBarrier.SyncBefore =
UAVBarrier.SyncAfter =
    D3D12_BARRIER_SYNC_ALL_SHADERS |
    D3D12_BARRIER_SYNC_BUILD_RAYTRACING_ACCELERATION_STRUCTURE |
    D3D12_BARRIER_SYNC_COPY_RAYTRACING_ACCELERATION_STRUCTURE |
    D3D12_BARRIER_SYNC_EMIT_RAYTRACING_ACCELERATION_STRUCTURE_POSTBUILD_INFO;

UAVBarrier.AccessBefore =
UAVBarrier.AccessAfter =
    D3D12_BARRIER_ACCESS_UNORDERED_ACCESS |
    D3D12_BARRIER_ACCESS_RAYTRACING_ACCELERATION_STRUCTURE_WRITE |
    D3D12_BARRIER_ACCESS_RAYTRACING_ACCELERATION_STRUCTURE_READ;
```

Applications using Enhanced Barriers natively can leave out the acceleration structure bits if they are not needed.

Legacy Resource Barriers support "NULL" UAV barriers.  These are equivalent to enhanced Barrier global barriers.

### Resource Aliasing

Enhanced Barrier API's do not explicitly provide native Aliasing Barrier transitions at the API-level.  Instead, enhanced Barrier API's support the necessary synchronization, layout transitions and memory access needed to match the functionality of legacy Aliasing Barriers.  In addition, there are many aliasing scenarios that the legacy Aliasing Barriers did not support that can be accomplished using enhanced Barriers.

Using the enhanced Barrier API's, aliased resource management is an organic concept.  For example:

For each "before resource":

- If needed: Wait for all accesses to complete.
  - Not needed if the access occurred in a different ExecuteCommandLists scope.
- If needed: Flush writes.
- If needed: Transition to layout compatible with subsequent use of the resource memory.
  - This spec does not define compatible layouts between aliased resources.
- Barriers may include the D3D12_BARRIER_ACCESS_NO_ACCESS bit in AccessAfter to indicate the subresource is being 'deactivated'
  - On some drivers, this may reduce cache burden.
  - The subresource is inaccessible until 'activated' using a barrier with D3D12_BARRIER_ACCESS_NO_ACCESS set in AccessBefore.

For each "after resource":

- If needed: Wait for all "before resource" accesses to complete.
- If needed: Specify desired layout.
  - Use LayoutBefore of D3D12_BARRIER_LAYOUT_UNDEFINED to avoid modifying memory as part of the barrier.
- If needed: Perform a full-resource discard using D3D2_TEXTURE_BARRIER_FLAG_DISCARD.
  - Must not use this flag if any of the "before resource" barriers transition layout or flush memory writes.
- If needed: Use the D3D12_BARRIER_ACCESS_NO_ACCESS bit in AccessBefore to 'activate' a subresource previously 'deactivated' in the same ExecuteCommandLists scope.

Note that each of these is tagged as 'If needed'.  There are aliasing scenarios where resource aliasing can be accomplished without any barriers at all.  For example: all "before" and "after" resources are buffers (thus no layout), and accesses to all "before" resources occurred in a separate ExecuteCommandLists scope than all "after" resources.

Since barriers on different subresources have no guaranteed order, care must be taken to avoid combining barriers that potentially modify the same memory. This includes Layout transitions and barriers using D3D2_TEXTURE_BARRIER_FLAG_DISCARD.

Possible but not expected to be common: If aliased memory write flushes were needed on any "before resources", then use a separate Discard/Clear/Copy to initialize "after resource" memory rather than using the D3D2_TEXTURE_BARRIER_FLAG_DISCARD flag.

### Initial Resource State

Legacy D3D12 resource creation API's require an initial state.  For texture resources, this initial state implies an initial layout according to the table in [Equivalent D3D12_BARRIER_LAYOUT for each D3D12_RESOURCE_STATES bit](#equivalent-d3d12_barrier_layout-for-each-d3d12_resource_states-bit).

Despite the fact that legacy resource creation API's have an Initial State, buffers do not have a layout, and thus are treated as though they have an initial state of STATE_COMMON.  This includes Upload Heap and Readback Heap buffers, despite being documented as requiring STATE_GENERIC_READ and STATE_COPY_DEST respectively.  The exception to this is buffers intended to be used as raytracing acceleration structures.  The D3D12_RESOURCE_STATE_RAYTRACING_ACCELERATION_STRUCTURE state is a hint to the runtime, driver and PIX that the resource may only be used as a raytracing acceleration structure.

### Split Barriers

A split barrier provides a hint to a driver that a state transition must occur between two points in a command stream, even cross ExecuteCommandLists boundaries.  Drivers may complete the required layout transitions and cache flushes any time between the start and end of a split barrier.

Enhanced Barrier API's allow SPLIT synchronization.  Split barriers are represented by a pair of barriers where the initial barrier uses a D3D12_BARRIER_SYNC_SPLIT SyncAfter value, and the final barrier uses a D3D12_BARRIER_SYNC_SPLIT SyncBefore value.

Split barrier pairs must use identical LayoutBefore, LayoutAfter values for both the initial and final barriers.  In addition, AccessBefore and AccessAfter bits must match except that the initial split barrier must include the D3D12_BARRIER_ACCESS_NO_ACCESS bit in AccessAfter, and the final split barrier must include the D3D12_BARRIER_ACCESS_NO_ACCESS bit in AccessBefore.  This makes the resource inaccessible between the initial and final split barriers.  Split barrier pairs must be sequential with no other intervening barriers on the same resource.

```c++
// BEGIN split from compute shader UAV to pixel shader SRV
splitBarrierBegin.SyncBefore = D3D12_BARRIER_SYNC_COMPUTE
splitBarrierBegin.SyncAfter = D3D12_BARRIER_SYNC_SPLIT
splitBarrierBegin.AccessBefore = D3D12_BARRIER_ACCESS_UNORDERED_ACCESS
splitBarrierBegin.AccessAfter = D3D12_BARRIER_ACCESS_DIRECT_QUEUE_SHADER_RESOURCE|D3D12_BARRIER_ACCESS_NO_ACCESS
splitBarrierBegin.LayoutBefore = D3D12_BARRIER_LAYOUT_UNORDERED_ACCESS
splitBarrierBegin.LayoutAfter = D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_SHADER_RESOURCE

// END split from compute shader UAV to pixel shader SRV
splitBarrierEnd.SyncBefore = D3D12_BARRIER_SYNC_SPLIT
splitBarrierEnd.SyncAfter = D3D12_BARRIER_SYNC_PIXEL_SHADING
splitBarrierEnd.AccessBefore = D3D12_BARRIER_ACCESS_UNORDERED_ACCESS|D3D12_BARRIER_ACCESS_NO_ACCESS
splitBarrierEnd.AccessAfter = D3D12_BARRIER_ACCESS_DIRECT_QUEUE_SHADER_RESOURCE
splitBarrierEnd.LayoutBefore = D3D12_BARRIER_LAYOUT_UNORDERED_ACCESS
splitBarrierEnd.LayoutAfter = D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_SHADER_RESOURCE
```

Split barriers across ExecuteCommandLists boundaries are allowed.  In this case all AccessBefore and AccessAfter values are effectively ignored since the ExecuteCommandLists boundaries takes care of any cache flushing.  Essentially, cross-ExecuteCommandLists split barriers are layout-only barriers.  Therefore, splitting a buffer barrier or a simultaneous-access texture barrier across ExecuteCommandLists boundaries serves no purpose.  An unmatched BEGIN or END split barrier on a buffer or simultaneous-access texture in a given ExecuteCommandLists scope is effectively unused and the Debug Layer produces a warning.

### COMMON Layout and Access

The D3D12_BARRIER_LAYOUT_COMMON matches the layout of legacy ResourceBarrier state D3D12_RESOURCE_STATE_COMMON.  Any texture subresource in LAYOUT_COMMON can be used without a layout transition for any combination of the following access bits:

- D3D12_BARRIER_ACCESS_SHADER_RESOURCE
- D3D12_BARRIER_ACCESS_COPY_DEST
- D3D12_BARRIER_ACCESS_COPY_SOURCE

Subresources using a COMMON layout and buffers require only synchronization and access transitions.  Furthermore, all resources initially have access status of ACCESS_COMMON at the start of ExecuteCommandLists scope.  As such, these resources can be accessed without a Barrier.

In addition, textures created using the D3D12_RESOURCE_FLAG_ALLOW_SIMULTANEOUS_ACCESS flag can be used without barrier for the following access types:

- D3D12_BARRIER_ACCESS_SHADER_RESOURCE
- D3D12_BARRIER_ACCESS_COPY_DEST
- D3D12_BARRIER_ACCESS_COPY_SOURCE
- D3D12_BARRIER_ACCESS_RENDER_TARGET
- D3D12_BARRIER_ACCESS_UNORDERED_ACCESS
- D3D12_BARRIER_ACCESS_RESOLVE_DEST
- D3D12_BARRIER_ACCESS_RESOLVE_SOURCE

### Upload Heap Resources

Upload Heap resources are buffers and thus have no layout.  Upload Heap resources effectively have the following access bits immutably set:

- D3D12_BARRIER_ACCESS_VERTEX_BUFFER
- D3D12_BARRIER_ACCESS_CONSTANT_BUFFER
- D3D12_BARRIER_ACCESS_INDEX_BUFFER
- D3D12_BARRIER_ACCESS_SHADER_RESOURCE
- D3D12_BARRIER_ACCESS_INDIRECT_ARGUMENT
- D3D12_BARRIER_ACCESS_COPY_SOURCE
- D3D12_BARRIER_ACCESS_RESOLVE_SOURCE (*)

(*) RESOLVE_SOURCE is available only on devices that support Sampler Feedback.

### Readback Heap Resources

Readback and Upload Heap resources are buffers, and thus have no layout.

Readback Heap resources can be written to either by Copy or Resolve operations (Resolve only supported on devices that also support Sampler Feedback).  As such, Readback Heap resources may require barriers to manage write-after-write hazards.

Readback Heap resources support the following access bits:

- D3D12_BARRIER_ACCESS_COPY_DEST
- D3D12_BARRIER_ACCESS_RESOLVE_DEST (*)

(*) RESOLVE_DEST MUST be available on hardware that supports Sampler Feedback.

### Command Queue Layout Compatibility

As with D3D12_RESOURCE_STATES, Resource Layouts MUST be compatible with the type of Queue performing the layout transition:

D3D12_COMMAND_LIST_TYPE_DIRECT

- D3D12_BARRIER_LAYOUT_COMMON
- D3D12_BARRIER_LAYOUT_GENERIC_READ
- D3D12_BARRIER_LAYOUT_RENDER_TARGET
- D3D12_BARRIER_LAYOUT_UNORDERED_ACCESS
- D3D12_BARRIER_LAYOUT_DEPTH_STENCIL_WRITE
- D3D12_BARRIER_LAYOUT_DEPTH_STENCIL_READ
- D3D12_BARRIER_LAYOUT_SHADER_RESOURCE
- D3D12_BARRIER_LAYOUT_COPY_SOURCE
- D3D12_BARRIER_LAYOUT_COPY_DEST
- D3D12_BARRIER_LAYOUT_RESOLVE_SOURCE
- D3D12_BARRIER_LAYOUT_RESOLVE_DEST
- D3D12_BARRIER_LAYOUT_SHADING_RATE_SOURCE
- D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_GENERIC_READ
- D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_UNORDERED_ACCESS
- D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_SHADER_RESOURCE
- D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COPY_SOURCE
- D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COPY_DEST

D3D12_COMMAND_LIST_TYPE_COMPUTE

- D3D12_BARRIER_LAYOUT_COMMON
- D3D12_BARRIER_LAYOUT_GENERIC_READ
- D3D12_BARRIER_LAYOUT_UNORDERED_ACCESS
- D3D12_BARRIER_LAYOUT_SHADER_RESOURCE
- D3D12_BARRIER_LAYOUT_COPY_SOURCE
- D3D12_BARRIER_LAYOUT_COPY_DEST

D3D12_COMMAND_LIST_TYPE_COPY

- D3D12_BARRIER_LAYOUT_COMMON

D3D12_COMMAND_LIST_TYPE_VIDEO_DECODE

- D3D12_BARRIER_LAYOUT_COMMON
- D3D12_BARRIER_LAYOUT_VIDEO_DECODE_READ
- D3D12_BARRIER_LAYOUT_VIDEO_DECODE_WRITE

D3D12_COMMAND_LIST_TYPE_VIDEO_PROCESS

- D3D12_BARRIER_LAYOUT_COMMON
- D3D12_BARRIER_LAYOUT_VIDEO_PROCESS_READ
- D3D12_BARRIER_LAYOUT_VIDEO_PROCESS_WRITE

D3D12_COMMAND_LIST_TYPE_VIDEO_ENCODE

- D3D12_BARRIER_LAYOUT_COMMON
- D3D12_BARRIER_LAYOUT_VIDEO_ENCODE_READ
- D3D12_BARRIER_LAYOUT_VIDEO_ENCODE_WRITE

### Command Queue Access Compatibility

As with D3D12_RESOURCE_STATES, Resource Accesses MUST be compatible with the type of Queue accessing the resource:

D3D12_COMMAND_LIST_TYPE_DIRECT

- D3D12_BARRIER_ACCESS_VERTEX_BUFFER
- D3D12_BARRIER_ACCESS_CONSTANT_BUFFER
- D3D12_BARRIER_ACCESS_INDEX_BUFFER
- D3D12_BARRIER_ACCESS_RENDER_TARGET
- D3D12_BARRIER_ACCESS_UNORDERED_ACCESS
- D3D12_BARRIER_ACCESS_DEPTH_STENCIL_WRITE
- D3D12_BARRIER_ACCESS_DEPTH_STENCIL_READ
- D3D12_BARRIER_ACCESS_SHADER_RESOURCE
- D3D12_BARRIER_ACCESS_STREAM_OUTPUT
- D3D12_BARRIER_ACCESS_INDIRECT_ARGUMENT
- D3D12_BARRIER_ACCESS_COPY_DEST
- D3D12_BARRIER_ACCESS_COPY_SOURCE
- D3D12_BARRIER_ACCESS_RESOLVE_DEST
- D3D12_BARRIER_ACCESS_RESOLVE_SOURCE
- D3D12_BARRIER_ACCESS_RAYTRACING_ACCELERATION_STRUCTURE_READ
- D3D12_BARRIER_ACCESS_RAYTRACING_ACCELERATION_STRUCTURE_WRITE
- D3D12_BARRIER_ACCESS_SHADING_RATE_SOURCE
- D3D12_BARRIER_ACCESS_PREDICATION

D3D12_COMMAND_LIST_TYPE_COMPUTE

- D3D12_BARRIER_ACCESS_VERTEX_BUFFER
- D3D12_BARRIER_ACCESS_CONSTANT_BUFFER
- D3D12_BARRIER_ACCESS_UNORDERED_ACCESS
- D3D12_BARRIER_ACCESS_SHADER_RESOURCE
- D3D12_BARRIER_ACCESS_INDIRECT_ARGUMENT
- D3D12_BARRIER_ACCESS_COPY_DEST
- D3D12_BARRIER_ACCESS_COPY_SOURCE
- D3D12_BARRIER_ACCESS_RAYTRACING_ACCELERATION_STRUCTURE_READ
- D3D12_BARRIER_ACCESS_RAYTRACING_ACCELERATION_STRUCTURE_WRITE
- D3D12_BARRIER_ACCESS_PREDICATION

D3D12_COMMAND_LIST_TYPE_COPY

- D3D12_BARRIER_ACCESS_COPY_DEST
- D3D12_BARRIER_ACCESS_COPY_SOURCE

D3D12_COMMAND_LIST_TYPE_VIDEO_DECODE

- D3D12_BARRIER_ACCESS_VIDEO_DECODE_READ
- D3D12_BARRIER_ACCESS_VIDEO_DECODE_WRITE

D3D12_COMMAND_LIST_TYPE_VIDEO_PROCESS

- D3D12_BARRIER_ACCESS_VIDEO_PROCESS_READ
- D3D12_BARRIER_ACCESS_VIDEO_PROCESS_WRITE

D3D12_COMMAND_LIST_TYPE_VIDEO_ENCODE

- D3D12_BARRIER_ACCESS_VIDEO_ENCODE_READ
- D3D12_BARRIER_ACCESS_VIDEO_ENCODE_WRITE

### Command Queue Sync Compatibility

D3D12_COMMAND_LIST_TYPE_DIRECT

- D3D12_BARRIER_SYNC_ALL
- D3D12_BARRIER_SYNC_DRAW
- D3D12_BARRIER_SYNC_INPUT_ASSEMBLER
- D3D12_BARRIER_SYNC_VERTEX_SHADING
- D3D12_BARRIER_SYNC_PIXEL_SHADING
- D3D12_BARRIER_SYNC_DEPTH_STENCIL
- D3D12_BARRIER_SYNC_RENDER_TARGET
- D3D12_BARRIER_SYNC_COMPUTE_SHADING
- D3D12_BARRIER_SYNC_RAYTRACING
- D3D12_BARRIER_SYNC_COPY
- D3D12_BARRIER_SYNC_RESOLVE
- D3D12_BARRIER_SYNC_EXECUTE_INDIRECT
- D3D12_BARRIER_SYNC_PREDICATION
- D3D12_BARRIER_SYNC_ALL_SHADING
- D3D12_BARRIER_SYNC_NON_PIXEL_SHADING
- D3D12_BARRIER_SYNC_BUILD_RAYTRACING_ACCELERATION_STRUCTURE
- D3D12_BARRIER_SYNC_COPY_RAYTRACING_ACCELERATION_STRUCTURE
- D3D12_BARRIER_SYNC_EMIT_RAYTRACING_ACCELERATION_STRUCTURE_POSTBUILD_INFO
- D3D12_BARRIER_SYNC_SPLIT

D3D12_COMMAND_LIST_TYPE_COMPUTE

- D3D12_BARRIER_SYNC_ALL
- D3D12_BARRIER_SYNC_COMPUTE_SHADING
- D3D12_BARRIER_SYNC_RAYTRACING
- D3D12_BARRIER_SYNC_COPY
- D3D12_BARRIER_SYNC_EXECUTE_INDIRECT
- D3D12_BARRIER_SYNC_ALL_SHADING
- D3D12_BARRIER_SYNC_NON_PIXEL_SHADING
- D3D12_BARRIER_SYNC_BUILD_RAYTRACING_ACCELERATION_STRUCTURE
- D3D12_BARRIER_SYNC_COPY_RAYTRACING_ACCELERATION_STRUCTURE
- D3D12_BARRIER_SYNC_EMIT_RAYTRACING_ACCELERATION_STRUCTURE_POSTBUILD_INFO
- D3D12_BARRIER_SYNC_SPLIT

D3D12_COMMAND_LIST_TYPE_COPY

- D3D12_BARRIER_SYNC_ALL
- D3D12_BARRIER_SYNC_COPY
- D3D12_BARRIER_SYNC_SPLIT

D3D12_COMMAND_LIST_TYPE_VIDEO_DECODE

- D3D12_BARRIER_SYNC_ALL
- D3D12_BARRIER_SYNC_VIDEO_DECODE
- D3D12_BARRIER_SYNC_SPLIT

D3D12_COMMAND_LIST_TYPE_VIDEO_PROCESS

- D3D12_BARRIER_SYNC_ALL
- D3D12_BARRIER_SYNC_VIDEO_PROCESS
- D3D12_BARRIER_SYNC_SPLIT

D3D12_COMMAND_LIST_TYPE_VIDEO_ENCODE

- D3D12_BARRIER_SYNC_ALL
- D3D12_BARRIER_SYNC_VIDEO_ENCODE
- D3D12_BARRIER_SYNC_SPLIT

### Copy Queues

According to legacy D3D12 Resource Barriers requirements, subresources used in Copy queues MUST be in the state D3D12_RESOURCE_STATE_COMMON.  This is equivalent to a subresource with a layout of D3D12_BARRIER_LAYOUT_COMMON.

Copy queues do not support layout transition Barriers, thus any subresources accessed in a Copy queue remain in the COMMON layout at completion of the Copy queue ExecuteCommandLists scope.

### Layout Access Compatibility

The following tables describe the Access types compatible with a given layout:

| D3D12_BARRIER_LAYOUT_UNDEFINED |
|--------------------------------|
| None                           |

| D3D12_BARRIER_LAYOUT_COMMON            |
|----------------------------------------|
| D3D12_BARRIER_ACCESS_SHADER_RESOURCE   |
| D3D12_BARRIER_ACCESS_COPY_DEST         |
| D3D12_BARRIER_ACCESS_COPY_SOURCE       |

| D3D12_BARRIER_LAYOUT_GENERIC_READ      |
|----------------------------------------|
| D3D12_BARRIER_ACCESS_SHADER_RESOURCE   |
| D3D12_BARRIER_ACCESS_COPY_SOURCE       |

| D3D12_BARRIER_LAYOUT_RENDER_TARGET |
|------------------------------------|
| D3D12_BARRIER_ACCESS_RENDER_TARGET |

| D3D12_BARRIER_LAYOUT_UNORDERED_ACCESS |
|---------------------------------------|
| D3D12_BARRIER_ACCESS_UNORDERED_ACCESS |

| D3D12_BARRIER_LAYOUT_DEPTH_STENCIL_WRITE |
|------------------------------------------|
| D3D12_BARRIER_ACCESS_DEPTH_STENCIL_READ  |
| D3D12_BARRIER_ACCESS_DEPTH_STENCIL_WRITE |

| D3D12_BARRIER_LAYOUT_DEPTH_STENCIL_READ |
|-----------------------------------------|
| D3D12_BARRIER_ACCESS_DEPTH_STENCIL_READ |

| D3D12_BARRIER_LAYOUT_SHADER_RESOURCE |
|--------------------------------------|
| D3D12_BARRIER_ACCESS_SHADER_RESOURCE |

| D3D12_BARRIER_LAYOUT_COPY_SOURCE |
|----------------------------------|
| D3D12_BARRIER_ACCESS_COPY_SOURCE |

| D3D12_BARRIER_LAYOUT_COPY_DEST                                                    |
|-----------------------------------------------------------------------------------|
| D3D12_BARRIER_ACCESS_COPY_DEST                                                    |
| D3D12_BARRIER_ACCESS_COPY_SOURCE* (see [Self Resource Copy](#self-resource-copy)) |

| D3D12_BARRIER_LAYOUT_RESOLVE_SOURCE |
|-------------------------------------|
| D3D12_BARRIER_ACCESS_RESOLVE_SOURCE |

| D3D12_BARRIER_LAYOUT_RESOLVE_DEST |
|-----------------------------------|
| D3D12_BARRIER_ACCESS_RESOLVE_DEST |

| D3D12_BARRIER_LAYOUT_SHADING_RATE_SOURCE |
|------------------------------------------|
| D3D12_BARRIER_ACCESS_SHADING_RATE_SOURCE |

| D3D12_BARRIER_LAYOUT_VIDEO_DECODE_READ |
|----------------------------------------|
| D3D12_BARRIER_ACCESS_VIDEO_DECODE_READ |

| D3D12_BARRIER_LAYOUT_VIDEO_DECODE_WRITE |
|-----------------------------------------|
| D3D12_BARRIER_ACCESS_VIDEO_DECODE_WRITE |

| D3D12_BARRIER_LAYOUT_VIDEO_PROCESS_READ |
|-----------------------------------------|
| D3D12_BARRIER_ACCESS_VIDEO_PROCESS_READ |

| D3D12_BARRIER_LAYOUT_VIDEO_PROCESS_WRITE |
|------------------------------------------|
| D3D12_BARRIER_ACCESS_VIDEO_PROCESS_WRITE |

| D3D12_BARRIER_LAYOUT_VIDEO_ENCODE_READ |
|----------------------------------------|
| D3D12_BARRIER_ACCESS_VIDEO_ENCODE_READ |

| D3D12_BARRIER_LAYOUT_VIDEO_ENCODE_WRITE |
|-----------------------------------------|
| D3D12_BARRIER_ACCESS_VIDEO_ENCODE_WRITE |

| D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_GENERIC_READ |
|------------------------------------------------|
| D3D12_BARRIER_ACCESS_SHADER_RESOURCE           |
| D3D12_BARRIER_ACCESS_COPY_SOURCE               |

| D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_SHADER_RESOURCE |
|---------------------------------------------------|
| D3D12_BARRIER_ACCESS_SHADER_RESOURCE              |

| D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_UNORDERED_ACCESS |
|----------------------------------------------------|
| D3D12_BARRIER_ACCESS_UNORDERED_ACCESS              |

| D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COPY_SOURCE |
|-----------------------------------------------|
| D3D12_BARRIER_ACCESS_COPY_SOURCE              |

| D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COPY_DEST                                       |
|-----------------------------------------------------------------------------------|
| D3D12_BARRIER_ACCESS_COPY_DEST                                                    |
| D3D12_BARRIER_ACCESS_COPY_SOURCE* (see [Self Resource Copy](#self-resource-copy)) |

### Access Bits Barrier Sync Compatibility

Some Access types require matching Sync.  For the following access bits, at least one of the listed sync bits must also be provided in a barrier.

| D3D12_BARRIER_ACCESS_COMMON          |
|--------------------------------------|
| D3D12_BARRIER_SYNC_NONE              |
| D3D12_BARRIER_SYNC_ALL               |
| D3D12_BARRIER_SYNC_DRAW              |
| D3D12_BARRIER_SYNC_INPUT_ASSEMBLER   |
| D3D12_BARRIER_SYNC_VERTEX_SHADING    |
| D3D12_BARRIER_SYNC_PIXEL_SHADING     |
| D3D12_BARRIER_SYNC_DEPTH_STENCIL     |
| D3D12_BARRIER_SYNC_RENDER_TARGET     |
| D3D12_BARRIER_SYNC_COMPUTE_SHADING   |
| D3D12_BARRIER_SYNC_RAYTRACING        |
| D3D12_BARRIER_SYNC_COPY              |
| D3D12_BARRIER_SYNC_RESOLVE           |
| D3D12_BARRIER_SYNC_EXECUTE_INDIRECT  |
| D3D12_BARRIER_SYNC_PREDICATION       |
| D3D12_BARRIER_SYNC_ALL_SHADING       |
| D3D12_BARRIER_SYNC_NON_PIXEL_SHADING |
| D3D12_BARRIER_SYNC_VIDEO_DECODE      |
| D3D12_BARRIER_SYNC_VIDEO_PROCESS     |
| D3D12_BARRIER_SYNC_VIDEO_ENCODE      |
| D3D12_BARRIER_SYNC_SPLIT             |

| D3D12_BARRIER_ACCESS_VERTEX_BUFFER |
|------------------------------------|
| D3D12_BARRIER_SYNC_ALL             |
| D3D12_BARRIER_SYNC_VERTEX_SHADING  |
| D3D12_BARRIER_SYNC_DRAW            |
| D3D12_BARRIER_SYNC_ALL_SHADING     |

| D3D12_BARRIER_ACCESS_CONSTANT_BUFFER |
|--------------------------------------|
| D3D12_BARRIER_SYNC_ALL               |
| D3D12_BARRIER_SYNC_VERTEX_SHADING    |
| D3D12_BARRIER_SYNC_PIXEL_SHADING     |
| D3D12_BARRIER_SYNC_COMPUTE_SHADING   |
| D3D12_BARRIER_SYNC_DRAW              |
| D3D12_BARRIER_SYNC_ALL_SHADING       |

| D3D12_BARRIER_ACCESS_INDEX_BUFFER  |
|------------------------------------|
| D3D12_BARRIER_SYNC_ALL             |
| D3D12_BARRIER_SYNC_INPUT_ASSEMBLER |
| D3D12_BARRIER_SYNC_DRAW            |

| D3D12_BARRIER_ACCESS_RENDER_TARGET |
|------------------------------------|
| D3D12_BARRIER_SYNC_ALL             |
| D3D12_BARRIER_SYNC_DRAW            |
| D3D12_BARRIER_SYNC_RENDER_TARGET   |

| D3D12_BARRIER_ACCESS_UNORDERED_ACCESS |
|---------------------------------------|
| D3D12_BARRIER_SYNC_ALL                |
| D3D12_BARRIER_SYNC_VERTEX_SHADING     |
| D3D12_BARRIER_SYNC_PIXEL_SHADING      |
| D3D12_BARRIER_SYNC_COMPUTE_SHADING    |
| D3D12_BARRIER_SYNC_VERTEX_SHADING     |
| D3D12_BARRIER_SYNC_DRAW               |
| D3D12_BARRIER_SYNC_ALL_SHADING        |

| D3D12_BARRIER_ACCESS_DEPTH_STENCIL_WRITE |
|------------------------------------------|
| D3D12_BARRIER_SYNC_ALL                   |
| D3D12_BARRIER_SYNC_DRAW                  |
| D3D12_BARRIER_SYNC_DEPTH_STENCIL         |

| D3D12_BARRIER_ACCESS_DEPTH_STENCIL_READ |
|-----------------------------------------|
| D3D12_BARRIER_SYNC_ALL                  |
| D3D12_BARRIER_SYNC_DRAW                 |
| D3D12_BARRIER_SYNC_DEPTH_STENCIL        |

| D3D12_BARRIER_ACCESS_SHADER_RESOURCE |
|--------------------------------------|
| D3D12_BARRIER_SYNC_ALL               |
| D3D12_BARRIER_SYNC_VERTEX_SHADING    |
| D3D12_BARRIER_SYNC_PIXEL_SHADING     |
| D3D12_BARRIER_SYNC_COMPUTE_SHADING   |
| D3D12_BARRIER_SYNC_DRAW              |
| D3D12_BARRIER_SYNC_ALL_SHADING       |

| D3D12_BARRIER_ACCESS_STREAM_OUTPUT |
|------------------------------------|
| D3D12_BARRIER_SYNC_ALL             |
| D3D12_BARRIER_SYNC_VERTEX_SHADING  |
| D3D12_BARRIER_SYNC_DRAW            |
| D3D12_BARRIER_SYNC_ALL_SHADING     |

| D3D12_BARRIER_ACCESS_INDIRECT_ARGUMENT |
|----------------------------------------|
| D3D12_BARRIER_SYNC_ALL                 |
| D3D12_BARRIER_SYNC_EXECUTE_INDIRECT    |

| D3D12_BARRIER_ACCESS_PREDICATION |
|----------------------------------|
| D3D12_BARRIER_SYNC_ALL           |
| D3D12_BARRIER_SYNC_PREDICATION   |

| D3D12_BARRIER_ACCESS_COPY_DEST |
|--------------------------------|
| D3D12_BARRIER_SYNC_ALL         |
| D3D12_BARRIER_SYNC_COPY        |

| D3D12_BARRIER_ACCESS_COPY_SOURCE |
|----------------------------------|
| D3D12_BARRIER_SYNC_ALL           |
| D3D12_BARRIER_SYNC_COPY          |

| D3D12_BARRIER_ACCESS_RESOLVE_DEST |
|-----------------------------------|
| D3D12_BARRIER_SYNC_ALL            |
| D3D12_BARRIER_SYNC_RESOLVE        |

| D3D12_BARRIER_ACCESS_RESOLVE_SOURCE |
|-------------------------------------|
| D3D12_BARRIER_SYNC_ALL              |
| D3D12_BARRIER_SYNC_RESOLVE          |

| D3D12_BARRIER_ACCESS_RAYTRACING_ACCELERATION_STRUCTURE_READ              |
|--------------------------------------------------------------------------|
| D3D12_BARRIER_SYNC_ALL                                                   |
| D3D12_BARRIER_SYNC_COMPUTE_SHADING                                       |
| D3D12_BARRIER_SYNC_RAYTRACING                                            |
| D3D12_BARRIER_SYNC_ALL_SHADING                                           |
| D3D12_BARRIER_SYNC_BUILD_RAYTRACING_ACCELERATION_STRUCTURE               |
| D3D12_BARRIER_SYNC_COPY_RAYTRACING_ACCELERATION_STRUCTURE                |
| D3D12_BARRIER_SYNC_EMIT_RAYTRACING_ACCELERATION_STRUCTURE_POSTBUILD_INFO |

| D3D12_BARRIER_ACCESS_RAYTRACING_ACCELERATION_STRUCTURE_WRITE |
|--------------------------------------------------------------|
| D3D12_BARRIER_SYNC_ALL                                       |
| D3D12_BARRIER_SYNC_COMPUTE_SHADING                           |
| D3D12_BARRIER_SYNC_RAYTRACING                                |
| D3D12_BARRIER_SYNC_ALL_SHADING                               |
| D3D12_BARRIER_SYNC_RAYTRACING_ACCELERATION_STRUCTURE_BUILD   |
| D3D12_BARRIER_SYNC_RAYTRACING_ACCELERATION_STRUCTURE_COPY    |

| D3D12_BARRIER_ACCESS_SHADING_RATE_SOURCE |
|------------------------------------------|
| D3D12_BARRIER_SYNC_ALL                   |
| D3D12_BARRIER_SYNC_PIXEL_SHADING         |
| D3D12_BARRIER_SYNC_ALL_SHADING           |

| D3D12_BARRIER_ACCESS_VIDEO_DECODE_READ |
|----------------------------------------|
| D3D12_BARRIER_SYNC_ALL                 |
| D3D12_BARRIER_SYNC_VIDEO_DECODE        |

| D3D12_BARRIER_ACCESS_VIDEO_DECODE_WRITE |
|-----------------------------------------|
| D3D12_BARRIER_SYNC_ALL                  |
| D3D12_BARRIER_SYNC_VIDEO_DECODE         |

| D3D12_BARRIER_ACCESS_VIDEO_PROCESS_READ |
|-----------------------------------------|
| D3D12_BARRIER_SYNC_ALL                  |
| D3D12_BARRIER_SYNC_VIDEO_PROCESS        |

| D3D12_BARRIER_ACCESS_VIDEO_PROCESS_WRITE |
|------------------------------------------|
| D3D12_BARRIER_SYNC_ALL                   |
| D3D12_BARRIER_SYNC_VIDEO_PROCESS         |

| D3D12_BARRIER_ACCESS_VIDEO_ENCODE_READ |
|----------------------------------------|
| D3D12_BARRIER_SYNC_ALL                 |
| D3D12_BARRIER_SYNC_VIDEO_ENCODE        |

| D3D12_BARRIER_ACCESS_VIDEO_ENCODE_WRITE |
|-----------------------------------------|
| D3D12_BARRIER_SYNC_ALL                  |
| D3D12_BARRIER_SYNC_VIDEO_ENCODE         |

| D3D12_BARRIER_ACCESS_NO_ACCESS            |
|-------------------------------------------|
| D3D12_BARRIER_SYNC_NONE                   |

------------------------------------------------

------------------------------------------------

## API

### D3D12_BARRIER_LAYOUT

Describes any of the possible layouts used by D3D12 subresources.  Individual resource layouts may not be the same across all queue types.  For example the COPY_SOURCE layout on a Copy Queue may be a different physical layout than COPY_SOURCE on a Direct Queue.  Layouts apply only to texture resources.  Buffer resources have only a linear layout, regardless of access type.

```c++
typedef enum D3D12_BARRIER_LAYOUT
{
    D3D12_BARRIER_LAYOUT_UNDEFINED = 0xffffffff,
    D3D12_BARRIER_LAYOUT_COMMON = 0,
    D3D12_BARRIER_LAYOUT_PRESENT = 0,
    D3D12_BARRIER_LAYOUT_GENERIC_READ,
    D3D12_BARRIER_LAYOUT_RENDER_TARGET,
    D3D12_BARRIER_LAYOUT_UNORDERED_ACCESS,
    D3D12_BARRIER_LAYOUT_DEPTH_STENCIL_WRITE,
    D3D12_BARRIER_LAYOUT_DEPTH_STENCIL_READ,
    D3D12_BARRIER_LAYOUT_SHADER_RESOURCE,
    D3D12_BARRIER_LAYOUT_COPY_SOURCE,
    D3D12_BARRIER_LAYOUT_COPY_DEST,
    D3D12_BARRIER_LAYOUT_RESOLVE_SOURCE,
    D3D12_BARRIER_LAYOUT_RESOLVE_DEST,
    D3D12_BARRIER_LAYOUT_SHADING_RATE_SOURCE,
    D3D12_BARRIER_LAYOUT_VIDEO_DECODE_READ,
    D3D12_BARRIER_LAYOUT_VIDEO_DECODE_WRITE,
    D3D12_BARRIER_LAYOUT_VIDEO_PROCESS_READ,
    D3D12_BARRIER_LAYOUT_VIDEO_PROCESS_WRITE,
    D3D12_BARRIER_LAYOUT_VIDEO_ENCODE_READ,
    D3D12_BARRIER_LAYOUT_VIDEO_ENCODE_WRITE,
    D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COMMON,
    D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_GENERIC_READ,
    D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_UNORDERED_ACCESS,
    D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_SHADER_RESOURCE,
    D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COPY_SOURCE,
    D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COPY_DEST,
    D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_COMMON,
    D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_GENERIC_READ,
    D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_UNORDERED_ACCESS,
    D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_SHADER_RESOURCE,
    D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_COPY_SOURCE,
    D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_COPY_DEST,
    D3D12_BARRIER_LAYOUT_VIDEO_QUEUE_COMMON,
} D3D12_BARRIER_LAYOUT;
```

#### D3D12_BARRIER_LAYOUT_UNDEFINED

Provides support for subresource layout changes where the previous layout is irrelevant or undefined.  Typically, this is used for full-subresource or full-resource Clear, Discard, and Copy commands.

A layout transition with BOTH LayoutBefore and LayoutAfter set to D3D12_BARRIER_LAYOUT_UNDEFINED indicates a memory-access-only barrier.  Many read/write operations support LAYOUT_COMMON.  In particular, Copy commands may write to textures using either the LAYOUT_COMMON or LAYOUT_COPY.  A memory-access-only barrier can be used to flush copy writes to a texture without changing the texture layout.

#### D3D12_BARRIER_LAYOUT_COMMON

This is the layout used by D3D12_RESOURCE_STATE_COMMON.  Subresources with this layout are readable in any queue type without requiring a layout change.  They are also writable as a copy dest in any queue type.

Swap Chain presentation requires the back buffer is using D3D12_BARRIER_LAYOUT_COMMON.

#### D3D12_BARRIER_LAYOUT_PRESENT

Alias for D3D12_BARRIER_LAYOUT_COMMON.

#### D3D12_BARRIER_LAYOUT_GENERIC_READ

Provides support for any read-only access (e.g. SHADER_RESOURCE, COPY_SOURCE).  Should only be used for textures that require multiple, concurrent read accesses since this may not be as optimal as a more specific read layout.

#### D3D12_BARRIER_LAYOUT_RENDER_TARGET

Matches the layout used by D3D12_RESOURCE_STATE_RENDER_TARGET.

#### D3D12_BARRIER_LAYOUT_UNORDERED_ACCESS

Matches the layout used by D3D12_RESOURCE_STATE_UNORDERED_ACCESS.

#### D3D12_BARRIER_LAYOUT_DEPTH_STENCIL_WRITE

Matches the layout used by D3D12_RESOURCE_STATE_DEPTH_WRITE.

#### D3D12_BARRIER_LAYOUT_DEPTH_STENCIL_READ

Matches the layout used by D3D12_RESOURCE_STATE_DEPTH_READ.

#### D3D12_BARRIER_LAYOUT_SHADER_RESOURCE

Matches the layout used by D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE, and D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE.

#### D3D12_BARRIER_LAYOUT_COPY_SOURCE

Matches the layout used by D3D12_RESOURCE_STATE_COPY_SOURCE.

#### D3D12_BARRIER_LAYOUT_COPY_DEST

Matches the layout used by D3D12_RESOURCE_STATE_COPY_DEST.

Same as D3D12_BARRIER_LAYOUT_COPY_DEST except compatible only with Direct queues.  Can prevent costly, and unnecessary decompression on some layout transitions on resources with next access in a Direct queue.

#### D3D12_BARRIER_LAYOUT_VIDEO_DECODE_READ

Matches the layout used by D3D12_RESOURCE_STATE_VIDEO_DECODE_READ.

#### D3D12_BARRIER_LAYOUT_VIDEO_DECODE_WRITE

Matches the layout used by D3D12_RESOURCE_STATE_VIDEO_DECODE_WRITE.

#### D3D12_BARRIER_LAYOUT_VIDEO_PROCESS_READ

Matches the layout used by D3D12_RESOURCE_STATE_VIDEO_PROCESS_READ.

#### D3D12_BARRIER_LAYOUT_VIDEO_PROCESS_WRITE

Matches the layout used by D3D12_RESOURCE_STATE_VIDEO_PROCESS_WRITE.

#### D3D12_BARRIER_LAYOUT_VIDEO_ENCODE_READ

Matches the layout used by D3D12_RESOURCE_STATE_VIDEO_ENCODE_READ.

#### D3D12_BARRIER_LAYOUT_VIDEO_ENCODE_WRITE

Matches the layout used by D3D12_RESOURCE_STATE_VIDEO_ENCODE_WRITE.

#### D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COMMON

Supports common (barrier free) usage on direct queues only. May be more optimal than the more general D3D12_BARRIER_LAYOUT_COMMON. Can only be used in barriers on direct queues.

Note that this cannot be used for Present.  D3D12_BARRIER_LAYOUT_COMMON (a.k.a D3D12_BARRIER_LAYOUT_PRESENT) is still the required layout for Presentation.

#### D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_GENERIC_READ

Same as D3D12_BARRIER_LAYOUT_GENERIC_READ except with optimizations specific for direct queues. Can only be used in barriers on direct queues.

#### D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_UNORDERED_ACCESS

Same as D3D12_BARRIER_LAYOUT_UNORDERED_ACCESS except with optimizations specific for direct queues. Can only be used in barriers on direct queues.

#### D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_SHADER_RESOURCE

Same as D3D12_BARRIER_LAYOUT_SHADER_RESOURCE except with optimizations specific for direct queues. Can only be used in barriers on direct queues.

#### D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COPY_SOURCE

Same as D3D12_BARRIER_LAYOUT_COPY_SOURCE except with optimizations specific for direct queues. Can only be used in barriers on direct queues.

#### D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COPY_DEST

Same as D3D12_BARRIER_LAYOUT_COPY_DEST except with optimizations specific for direct queues. Can only be used in barriers on direct queues.

#### D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_COMMON

Supports common (barrier free) usage on compute queues only. May be more optimal than the more general D3D12_BARRIER_LAYOUT_COMMON. Can only be used in barriers on compute queues.

#### D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_GENERIC_READ

Same as D3D12_BARRIER_LAYOUT_GENERIC_READ except with optimizations specific for compute queues. Can only be used in barriers on compute queues.

#### D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_UNORDERED_ACCESS

Same as D3D12_BARRIER_LAYOUT_UNORDERED_ACCESS except with optimizations specific for compute queues. Can only be used in barriers on compute queues.

#### D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_SHADER_RESOURCE

Same as D3D12_BARRIER_LAYOUT_SHADER_RESOURCE except with optimizations specific for compute queues. Can only be used in barriers on compute queues.

#### D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_COPY_SOURCE

Same as D3D12_BARRIER_LAYOUT_COPY_SOURCE except with optimizations specific for compute queues. Can only be used in barriers on compute queues.

#### D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_COPY_DEST

Same as D3D12_BARRIER_LAYOUT_COPY_DEST except with optimizations specific for compute queues. Can only be used in barriers on compute queues.

#### D3D12_BARRIER_LAYOUT_VIDEO_QUEUE_COMMON

Supports common (barrier free) usage on video queues only. May be more optimal than the more general D3D12_BARRIER_LAYOUT_COMMON. Can only be used in barriers on video queues.

### D3D12_BARRIER_SYNC

```c++
enum D3D12_BARRIER_SYNC
{
    D3D12_BARRIER_SYNC_NONE                                                     = 0x0,
    D3D12_BARRIER_SYNC_ALL                                                      = 0x1,
    D3D12_BARRIER_SYNC_DRAW                                                     = 0x2,
    D3D12_BARRIER_SYNC_INPUT_ASSEMBLER                                          = 0x4,
    D3D12_BARRIER_SYNC_VERTEX_SHADING                                           = 0x8,
    D3D12_BARRIER_SYNC_PIXEL_SHADING                                            = 0x10,
    D3D12_BARRIER_SYNC_DEPTH_STENCIL                                            = 0x20,
    D3D12_BARRIER_SYNC_RENDER_TARGET                                            = 0x40,
    D3D12_BARRIER_SYNC_COMPUTE_SHADING                                          = 0x80,
    D3D12_BARRIER_SYNC_RAYTRACING                                               = 0x100,
    D3D12_BARRIER_SYNC_COPY                                                     = 0x200,
    D3D12_BARRIER_SYNC_RESOLVE                                                  = 0x400,
    D3D12_BARRIER_SYNC_EXECUTE_INDIRECT                                         = 0x800,
    D3D12_BARRIER_SYNC_PREDICATION                                              = 0x800, // Aliased with SYNC_EXECUTE_INDIRECT
    D3D12_BARRIER_SYNC_ALL_SHADING                                              = 0x1000,
    D3D12_BARRIER_SYNC_NON_PIXEL_SHADING                                        = 0x2000,
    D3D12_BARRIER_SYNC_BUILD_RAYTRACING_ACCELERATION_STRUCTURE                  = 0x4000,
    D3D12_BARRIER_SYNC_COPY_RAYTRACING_ACCELERATION_STRUCTURE                   = 0x8000,
    D3D12_BARRIER_SYNC_EMIT_RAYTRACING_ACCELERATION_STRUCTURE_POSTBUILD_INFO    = 0x10000,
    D3D12_BARRIER_SYNC_VIDEO_DECODE                                             = 0x100000,
    D3D12_BARRIER_SYNC_VIDEO_PROCESS                                            = 0x200000,
    D3D12_BARRIER_SYNC_VIDEO_ENCODE                                             = 0x400000,
    D3D12_BARRIER_SYNC_SPLIT                                                    = 0x80000000,
};
```

#### D3D12_BARRIER_SYNC_NONE

A SyncBefore value of D3D12_BARRIER_SYNC_NONE indicates NO PRECEDING work must complete before executing the barrier.  This MUST be paired with an AccessBefore value of D3D12_BARRIER_ACCESS_NO_ACCESS.  Additionally, no preceding barriers or accesses to the related subresource are permitted in the same ExecuteCommandLists scope.

A SyncAfter value of D3D12_BARRIER_SYNC_NONE indicates NO SUBSEQUENT work must wait for the barrier to complete, and MUST be paired with an AccessAfter value of D3D12_BARRIER_ACCESS_NO_ACCESS.  Additionally, no subsequent barriers or accesses to the related subresource are permitted in the same ExecuteCommandLists scope.

#### D3D12_BARRIER_SYNC_ALL

A SyncBefore value of D3D12_BARRIER_SYNC_ALL indicates ALL PRECEDING work must complete before executing the barrier.  A SyncAfter value of D3D12_BARRIER_SYNC_ALL indicates ALL SUBSEQUENT work must wait for the barrier to complete.

#### D3D12_BARRIER_SYNC_DRAW

A SyncBefore value of D3D12_BARRIER_SYNC_DRAW indicates ALL PRECEDING Draw work must complete before executing the barrier.  A SyncAfter value of D3D12_BARRIER_SYNC_DRAW indicates ALL SUBSEQUENT Draw work must wait for the barrier to complete.  This is a containing scope for all Draw pipeline stages.

#### D3D12_BARRIER_SYNC_INPUT_ASSEMBLER

Synchronize against Input Assembler stage execution.

#### D3D12_BARRIER_SYNC_VERTEX_SHADING

Synchronize against all vertex shading stages, including vertex, domain, hull, tessellation, geometry, amplification and mesh shading.

#### D3D12_BARRIER_SYNC_PIXEL_SHADING

Synchronize against pixel shader execution.

#### D3D12_BARRIER_SYNC_DEPTH_STENCIL

Synchronize against depth/stencil read/write operations.

#### D3D12_BARRIER_SYNC_RENDER_TARGET

Synchronize against render target read/write operations.

#### D3D12_BARRIER_SYNC_COMPUTE_SHADING

Synchronize against compute shader execution.

#### D3D12_BARRIER_SYNC_RAYTRACING

Synchronize against raytracing execution.

#### D3D12_BARRIER_SYNC_COPY

Synchronize against Copy commands.

#### D3D12_BARRIER_SYNC_RESOLVE

Synchronize against Resolve commands.

#### D3D12_BARRIER_SYNC_EXECUTE_INDIRECT

Synchronize against ExecuteIndirect execution.

#### D3D12_BARRIER_SYNC_ALL_SHADING

Synchronize against ALL shader execution.

#### D3D12_BARRIER_SYNC_NON_PIXEL_SHADING

Synchronize against shader execution EXCEPT pixel shading.  Exists for compatibility with legacy ResourceBarrier API.

#### D3D12_BARRIER_SYNC_VIDEO_DECODE

Synchronize against Video Decode execution.

#### D3D12_BARRIER_SYNC_VIDEO_PROCESS

Synchronize against Video Process execution.

#### D3D12_BARRIER_SYNC_VIDEO_ENCODE

Synchronize against Video Encode execution.

#### D3D12_BARRIER_SYNC_BUILD_RAYTRACING_ACCELERATION_STRUCTURE

Synchronize against ID3D12GraphicsCommandList4::BuildAccelerationStructure work.

Corresponding barrier Access[Before|After] must have the D3D12_BARRIER_ACCESS_RAYTRACING_ACCELERATION_STRUCTURE_WRITE bit set.

#### D3D12_BARRIER_SYNC_COPY_RAYTRACING_ACCELERATION_STRUCTURE

Synchronize against ID3D12GraphicsCommandList4::CopyRaytracingAccelerationStructure work.

Corresponding barrier Access[Before|After] must have the D3D12_BARRIER_ACCESS_RAYTRACING_ACCELERATION_STRUCTURE_WRITE bit set.

#### D3D12_BARRIER_SYNC_SPLIT

Special sync bit indicating a [split barrier](#split-barriers).  Used as a SyncAfter to indicates the start of a split barrier.  The application must provide a matching barrier with SyncBefore set to D3D12_BARRIER_SYNC_SPLIT.

### D3D12_BARRIER_ACCESS

```c++
enum D3D12_BARRIER_ACCESS
{
    D3D12_BARRIER_ACCESS_COMMON                                     = 0,
    D3D12_BARRIER_ACCESS_VERTEX_BUFFER                              = 0x1,
    D3D12_BARRIER_ACCESS_CONSTANT_BUFFER                            = 0x2,
    D3D12_BARRIER_ACCESS_INDEX_BUFFER                               = 0x4,
    D3D12_BARRIER_ACCESS_RENDER_TARGET                              = 0x8,
    D3D12_BARRIER_ACCESS_UNORDERED_ACCESS                           = 0x10,
    D3D12_BARRIER_ACCESS_DEPTH_STENCIL_WRITE                        = 0x20,
    D3D12_BARRIER_ACCESS_DEPTH_STENCIL_READ                         = 0x40,
    D3D12_BARRIER_ACCESS_SHADER_RESOURCE                            = 0x80,
    D3D12_BARRIER_ACCESS_STREAM_OUTPUT                              = 0x100,
    D3D12_BARRIER_ACCESS_INDIRECT_ARGUMENT                          = 0x200,
    D3D12_BARRIER_ACCESS_PREDICATION                                = 0x200, // Aliased with ACCESS_INDIRECT_ARGUMENT
    D3D12_BARRIER_ACCESS_COPY_DEST                                  = 0x400,
    D3D12_BARRIER_ACCESS_COPY_SOURCE                                = 0x800,
    D3D12_BARRIER_ACCESS_RESOLVE_DEST                               = 0x1000,
    D3D12_BARRIER_ACCESS_RESOLVE_SOURCE                             = 0x2000,
    D3D12_BARRIER_ACCESS_RAYTRACING_ACCELERATION_STRUCTURE_READ     = 0x4000,
    D3D12_BARRIER_ACCESS_RAYTRACING_ACCELERATION_STRUCTURE_WRITE    = 0x8000,
    D3D12_BARRIER_ACCESS_SHADING_RATE_SOURCE                        = 0x10000,
    D3D12_BARRIER_ACCESS_VIDEO_DECODE_READ                          = 0x20000,
    D3D12_BARRIER_ACCESS_VIDEO_DECODE_WRITE                         = 0x40000,
    D3D12_BARRIER_ACCESS_VIDEO_PROCESS_READ                         = 0x80000,
    D3D12_BARRIER_ACCESS_VIDEO_PROCESS_WRITE                        = 0x100000,
    D3D12_BARRIER_ACCESS_VIDEO_ENCODE_READ                          = 0x200000,
    D3D12_BARRIER_ACCESS_VIDEO_ENCODE_WRITE                         = 0x400000,
    D3D12_BARRIER_ACCESS_NO_ACCESS                                  = 0x80000000
};
```

#### D3D12_BARRIER_ACCESS_COMMON

Default initial access for all resources in a given ExecuteCommandLists scope.  Supports any type of access compatible with current layout and resource properties, including no-more than one write access.  For buffers and textures using LAYOUT_COMMON, BARRIER_ACCESS_COMMON supports concurrent read and write accesses.

When used as AccessBefore, BARRIER_ACCESS_COMMON DOES NOT guarantee preceding writes are visible to subsequent accesses.  If a resource has been written to with ACCESS_COMMON access, subsequent barriers MUST include the appropriate write access bit in AccessBefore.

When used as AccessAfter, BARRIER_ACCESS_COMMON may be used to return a resource back to common accessibility.  Note, this may force unnecessary cache flushes if used incorrectly.  When possible, AccessAfter should be limited to explicit access bits.

#### D3D12_BARRIER_ACCESS_VERTEX_BUFFER

Indicates a buffer resource is accessible as a vertex buffer in the current execution queue.

#### D3D12_BARRIER_ACCESS_CONSTANT_BUFFER

Indicates a buffer resource is accessible as a constant buffer in the current execution queue.

#### D3D12_BARRIER_ACCESS_INDEX_BUFFER

Indicates a buffer resource is accessible as an index buffer in the current execution queue.

#### D3D12_BARRIER_ACCESS_RENDER_TARGET

Indicates a resource is accessible as a render target.

#### D3D12_BARRIER_ACCESS_UNORDERED_ACCESS

Indicates a resource is accessible as an unordered access resource.

#### D3D12_BARRIER_ACCESS_DEPTH_STENCIL_WRITE

Indicates a resource is accessible as a writable depth/stencil resource.

#### D3D12_BARRIER_ACCESS_DEPTH_STENCIL_READ

Indicates a resource is accessible as a read-only depth/stencil resource.

#### D3D12_BARRIER_ACCESS_SHADER_RESOURCE

Indicates a resource is accessible as a shader resource.

#### D3D12_BARRIER_ACCESS_STREAM_OUTPUT

Indicates a buffer is accessible as a stream output target.

#### D3D12_BARRIER_ACCESS_INDIRECT_ARGUMENT

Indicates a buffer is accessible as an indirect argument buffer.

#### D3D12_BARRIER_ACCESS_PREDICATION

Indicates a buffer is accessible as a predication buffer.

#### D3D12_BARRIER_ACCESS_COPY_DEST

Indicates a resource is accessible as a copy destination.

#### D3D12_BARRIER_ACCESS_COPY_SOURCE

Indicates a resource is accessible as a copy source.

#### D3D12_BARRIER_ACCESS_RESOLVE_DEST

Indicates a resource is accessible as a resolve destination.

#### D3D12_BARRIER_ACCESS_RESOLVE_SOURCE

Indicates a resource is accessible as a resolve source.

#### D3D12_BARRIER_ACCESS_RAYTRACING_ACCELERATION_STRUCTURE_READ

Indicates a resource is accessible for read as a raytracing acceleration structure.  The resource MUST have been created using an initial state of D3D12_RESOURCE_STATE_RAYTRACING_ACCELERATION_STRUCTURE.

#### D3D12_BARRIER_ACCESS_RAYTRACING_ACCELERATION_STRUCTURE_WRITE

Indicates a resource is accessible for write as a raytracing acceleration structure.  The resource MUST have been created using an initial state of D3D12_RESOURCE_STATE_RAYTRACING_ACCELERATION_STRUCTURE.  This access bit must be set when writing to a raytracing acceleration structure using ID3D12GraphicsCommandList4::CopyRaytracingAccelerationStructure or ID3D12GraphicsCommandList4::BuildAccelerationStructure.

#### D3D12_BARRIER_ACCESS_SHADING_RATE_SOURCE

Indicates a resource is accessible as a shading rate source.

#### D3D12_BARRIER_ACCESS_VIDEO_DECODE_READ

Indicates a resource is accessible for read-only access in a video decode queue.

#### D3D12_BARRIER_ACCESS_VIDEO_DECODE_WRITE

Indicates a resource is accessible for write access in a video decode queue.

#### D3D12_BARRIER_ACCESS_VIDEO_PROCESS_READ

Indicates a resource is accessible for read-only access in a video process queue.

#### D3D12_BARRIER_ACCESS_VIDEO_PROCESS_WRITE

Indicates a resource is accessible for read-only access in a video process queue.

#### D3D12_BARRIER_ACCESS_VIDEO_ENCODE_READ

Indicates a resource is accessible for read-only access in a video encode queue.

#### D3D12_BARRIER_ACCESS_VIDEO_ENCODE_WRITE

Indicates a resource is accessible for read-only access in a video encode queue.

#### D3D12_BARRIER_ACCESS_NO_ACCESS

Resource is inaccessible for read or write.  Once a subresource access as been transitioned to BARRIER_ACCESS_NO_ACCESS, it must be be reactivated by a barrier with AccessBefore set to BARRIER_ACCESS_NO_ACCESS before using in the same ExecuteCommandLists scope.

Required in split barriers to mark the resource as inaccessible between initial and final split barrier pairs.

Useful in aliasing barriers when subresource is not needed for a sufficiently long time that it makes sense to purge the subresource from any read cache.

Also useful for initiating a layout transition as the final act on a resource before the end of an ExecuteCommandLists scope.  If SyncAfter is D3D12_BARRIER_SYNC_NONE, then AccessAfter MUST be D3D12_BARRIER_ACCESS_NO_ACCESS.

### D3D12_BARRIER_SUBRESOURCE_RANGE

```C++
struct D3D12_BARRIER_SUBRESOURCE_RANGE
{
    UINT IndexOrFirstMipLevel;
    UINT NumMipLevels;
    UINT FirstArraySlice;
    UINT NumArraySlices;
    UINT FirstPlane;
    UINT NumPlanes;
};
```

| Members              |                                                                                                                                                            |
|----------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------|
| IndexOrFirstMipLevel | Subresource Index (If NumMipLevels is zero) or index of first mip level in the range. If subresource index, may be 0xffffffff to specify all subresources. |
| NumMipLevels         | Number of mip levels in the range, or zero to indicate IndexOrFirstMipLevel is a subresource index.                                                        |
| FirstArraySlice      | Index of first array slice in the range. Ignored if NumMipLevels is zero.                                                                                  |
| NumArraySlices       | Number of array slices in the range. Ignored if NumMipLevels is zero.                                                                                      |
| FirstPlane           | First plane slice in the range.  Ignored if NumMipLevels is zero.                                                                                          |
| NumPlanes            | Number of plane slices in the range.  Ignored if NumMipLevels is zero.                                                                                     |

### D3D12_BARRIER_TYPE

```C++
enum D3D12_BARRIER_TYPE
{
    D3D12_BARRIER_TYPE_GLOBAL,
    D3D12_BARRIER_TYPE_TEXTURE,
    D3D12_BARRIER_TYPE_BUFFER,
};
```

| D3D12_BARRIER_TYPE         |                                                                                                                                                                          |
|----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| D3D12_BARRIER_TYPE_GLOBAL  | Indicates a barrier type of GLOBAL. A global barrier applies to ALL resource memory.  Global barriers DO NOT transition texture layouts or force any data decompression. |
| D3D12_BARRIER_TYPE_BUFFER  | Indicates a barrier of type BUFFER. A buffer barrier applies to a specific buffer resource.                                                                              |
| D3D12_BARRIER_TYPE_TEXTURE | Indicates a barrier of type TEXTURE. A texture barrier applies to a specific range of texture subresources.                                                              |

Note: Global barriers CAN NOT be split.

### D3D12_GLOBAL_BARRIER

Describes a resource memory access barrier.  Used by GLOBAL, TEXTURE, and BUFFER barriers to indicate when resource memory must be made visible for a specific access type.

```C++
struct D3D12_GLOBAL_BARRIER
{
    D3D12_BARRIER_SYNC SyncBefore;
    D3D12_BARRIER_SYNC SyncAfter;
    D3D12_BARRIER_ACCESS AccessBefore;
    D3D12_BARRIER_ACCESS AccessAfter;
}
```

| Member       |                                                                                                          |
|--------------|----------------------------------------------------------------------------------------------------------|
| SyncBefore   | Synchronization scope of all preceding GPU work that must be completed before executing the barrier.     |
| SyncAfter    | Synchronization scope of all subsequent GPU work that must wait until the barrier execution is finished. |
| AccessBefore | Write accesses that must be flushed and finished before the barrier is executed.                         |
| AccessAfter  | Accesses that must be available for data written via AccessBefore after the barrier is executed.         |

### D3D12_TEXTURE_BARRIER_FLAGS

```C++
enum D3D12_TEXTURE_BARRIER_FLAGS
{
    D3D12_TEXTURE_BARRIER_FLAG_NONE = 0x0,
    D3D12_TEXTURE_BARRIER_FLAG_DISCARD = 0x1,
}
```

#### D3D12_TEXTURE_BARRIER_FLAG_DISCARD

Can only be used when LayoutBefore is D3D12_BARRIER_LAYOUT_UNDEFINED.  Typically, this is used to initialize compression metadata as part of a barrier that activates an aliased resource.  The Subresource member must indicate all subresources.  Without this flag, a full resource Clear, Copy or Discard is required before use.

### D3D12_TEXTURE_BARRIER

```C++
struct D3D12_TEXTURE_BARRIER
{
    D3D12_BARRIER_SYNC SyncBefore;
    D3D12_BARRIER_SYNC SyncAfter;
    D3D12_BARRIER_ACCESS AccessBefore;
    D3D12_BARRIER_ACCESS AccessAfter;
    D3D12_BARRIER_LAYOUT LayoutBefore;
    D3D12_BARRIER_LAYOUT LayoutAfter;
    ID3D12Resource *pResource;
    D3D12_BARRIER_SUBRESOURCE_RANGE Subresources;
    D3D12_TEXTURE_BARRIER_FLAGS Flags;
};
```

| Member       |                                                                                                          |
|--------------|----------------------------------------------------------------------------------------------------------|
| SyncBefore   | Synchronization scope of all preceding GPU work that must be completed before executing the barrier.     |
| SyncAfter    | Synchronization scope of all subsequent GPU work that must wait until the barrier execution is finished. |
| AccessBefore | Access state of texture preceding the barrier execution.                                                 |
| AccessAfter  | Access state of texture upon completion of barrier execution.                                            |
| LayoutBefore | Layout of texture preceding the barrier execution.                                                       |
| LayoutAfter  | Layout of texture upon completion of barrier execution.                                                  |
| pResource    | Pointer to the buffer resource being using the barrier.                                                  |
| Subresources | Range of texture subresources being barriered.                                                           |
| Flags        | Optional flags values.                                                                                   |

### D3D12_BUFFER_BARRIER

```C++
struct D3D12_BUFFER_BARRIER
{
    D3D12_BARRIER_SYNC SyncBefore;
    D3D12_BARRIER_SYNC SyncAfter;
    D3D12_BARRIER_ACCESS AccessBefore;
    D3D12_BARRIER_ACCESS AccessAfter;
    ID3D12Resource *pResource;
    UINT64 Offset; // Must be 0
    UINT64 Size; // Must be UINT64_MAX or buffer size in bytes
};
```

| Member       |                                                                                                          |
|--------------|----------------------------------------------------------------------------------------------------------|
| SyncBefore   | Synchronization scope of all preceding GPU work that must be completed before executing the barrier.     |
| SyncAfter    | Synchronization scope of all subsequent GPU work that must wait until the barrier execution is finished. |
| AccessBefore | Access state of buffer preceding the barrier execution.                                                  |
| AccessAfter  | Access state of buffer upon completion of barrier execution.                                             |
| pResource    | Pointer to the buffer resource being using the barrier.                                                  |
| Offset       | Offset value must be 0.                                                                                  |
| Size         | Size must either be UINT64_MAX or the size of the buffer in bytes.                                       |

### D3D12_BARRIER_GROUP

Describes a group of barrier of a given type

```C++
struct D3D12_BARRIER_GROUP
{
    D3D12_BARRIER_TYPE Type;
    UINT32 NumBarriers;
    union
    {
        D3D12_GLOBAL_BARRIER *pGlobalBarriers;
        D3D12_TEXTURE_BARRIER *pTextureBarriers;
        D3D12_BUFFER_BARRIER *pBufferBarriers;
    };
};
```

| Member           |                                                                                     |
|------------------|-------------------------------------------------------------------------------------|
| Type             | Type of barriers in the group                                                       |
| NumBarriers      | Number of barriers in the group                                                     |
| pGlobalBarriers  | Pointer to an array of D3D12_GLOBAL_BARRIERS if Type is D3D12_BARRIER_TYPE_GLOBAL   |
| pTextureBarriers | Pointer to an array of D3D12_TEXTURE_BARRIERS if Type is D3D12_BARRIER_TYPE_TEXTURE |
| pBufferBarriers  | Pointer to an array of D3D12_BUFFER_BARRIERS if Type is D3D12_BARRIER_TYPE_BUFFER   |

### ID3D12GraphicsCommandList7::Barrier

Adds a collection of barriers into a graphics command list recording.

```c++
void ID3D12GraphicsCommandList7::Barrier(
        UINT32 NumBarrierGroups,
        D3D12_BARRIER_GROUP *pBarrierGroups
        );
```

| Parameter        |                                                       |
|------------------|-------------------------------------------------------|
| NumBarrierGroups | Number of barrier groups pointed to by pBarrierGroups |
| pBarrierGroups   | Pointer to an array of D3D12_BARRIER_GROUP objects    |

### ID3D12VideoDecodeCommandList3::Barrier

Adds a collection of barriers into a video decode command list recording.

```c++
void ID3D12VideoDecodeCommandList3::Barrier(
        UINT32 NumBarrierGroups,
        D3D12_BARRIER_GROUP *pBarrierGroups,
        );
```

| Parameter        |                                                       |
|------------------|-------------------------------------------------------|
| NumBarrierGroups | Number of barrier groups pointed to by pBarrierGroups |
| pBarrierGroups   | Pointer to an array of D3D12_BARRIER_GROUP objects    |

### ID3D12VideoProcessCommandList3::Barrier

Adds a collection of barriers into a video process command list recording.

```c++
void ID3D12VideoProcessCommandList3::Barrier(
        UINT32 NumBarrierGroups,
        D3D12_BARRIER_GROUP *pBarrierGroups,
        );
```

| Parameter        |                                                       |
|------------------|-------------------------------------------------------|
| NumBarrierGroups | Number of barrier groups pointed to by pBarrierGroups |
| pBarrierGroups   | Pointer to an array of D3D12_BARRIER_GROUP objects    |

### ID3D12VideoEncodeCommandList3::Barrier

Adds a collection of barriers into a video encode command list recording.

```c++
void ID3D12VideoEncodeCommandList3::Barrier(
        UINT32 NumBarrierGroups,
        D3D12_BARRIER_GROUP *pBarrierGroups,
        );
```

| Parameter        |                                                       |
|------------------|-------------------------------------------------------|
| NumBarrierGroups | Number of barrier groups pointed to by pBarrierGroups |
| pBarrierGroups   | Pointer to an array of D3D12_BARRIER_GROUP objects    |

### ID3D12Device10::CreateCommittedResource3

Creates a committed resource with an initial layout rather than an initial state.

```c++
HRESULT ID3D12Device10::CreateCommittedResource3(
    const D3D12_HEAP_PROPERTIES* pHeapProperties,
    D3D12_HEAP_FLAGS HeapFlags,
    const D3D12_RESOURCE_DESC1* pDesc,
    D3D12_BARRIER_LAYOUT InitialLayout,
    const D3D12_CLEAR_VALUE* pOptimizedClearValue,
    ID3D12ProtectedResourceSession* pProtectedSession,
    UINT32 NumCastableFormats,
    DXGI_FORMAT *pCastableFormats,
    REFIID riidResource, // Expected: ID3D12Resource1*
    void** ppvResource);
```

| Parameter          |                                                                                |
|--------------------|--------------------------------------------------------------------------------|
| InitialLayout      | Initial layout of texture resource, D3D12_BARRIER_LAYOUT_UNDEFINED for buffers |
| NumCastableFormats | Reserved for future use.  Must be 0                                            |
| pCastableFormats   | Reserved for future use.  Must be NULL                                         |

### ID3D12Device10::CreatePlacedResource2

```c++
HRESULT ID3D12Device10::CreatePlacedResource2(
    ID3D12Heap* pHeap,
    UINT64 HeapOffset,
    const D3D12_RESOURCE_DESC1* pDesc,
    D3D12_BARRIER_LAYOUT InitialLayout,
    const D3D12_CLEAR_VALUE* pOptimizedClearValue,
    UINT32 NumCastableFormats,
    DXGI_FORMAT *pCastableFormats,
    REFIID riid, // Expected: ID3D12Resource*
    void** ppvResource);
```

| Parameter          |                                                                                |
|--------------------|--------------------------------------------------------------------------------|
| InitialLayout      | Initial layout of texture resource, D3D12_BARRIER_LAYOUT_UNDEFINED for buffers |
| NumCastableFormats | Reserved for future use.  Must be 0                                            |
| pCastableFormats   | Reserved for future use.  Must be NULL                                         |

### ID3D12Device10::CreateReservedResource2

```c++
HRESULT ID3D12Device10::CreateReservedResource2(
    const D3D12_RESOURCE_DESC* pDesc,
    D3D12_BARRIER_LAYOUT InitialLayout,
    const D3D12_CLEAR_VALUE* pOptimizedClearValue,
    ID3D12ProtectedResourceSession *pProtectedSession,
    UINT32 NumCastableFormats,
    DXGI_FORMAT *pCastableFormats,
    REFIID riid, // Expected: ID3D12Resource1*
    void** ppvResource
);
```

| Parameter          |                                                                                |
|--------------------|--------------------------------------------------------------------------------|
| InitialLayout      | Initial layout of texture resource, D3D12_BARRIER_LAYOUT_UNDEFINED for buffers |
| NumCastableFormats | Reserved for future use.  Must be 0                                            |
| pCastableFormats   | Reserved for future use.  Must be NULL                                         |

## Barrier Examples

```C++
void BarrierSamples()
{
    ID3D12CommandListN *pCommandList;
    ID3D12Resource *pTexture;
    ID3D12Resource *pBuffer;

    // Simple state transition barrier:
    // RENDER_TARGET -> PIXEL_SHADER_RESOURCE
    D3D12_TEXTURE_BARRIER TexBarriers[] =
    {
        {
            D3D12_BARRIER_ACCESS_RENDER_TARGET,
            D3D12_BARRIER_ACCESS_SHADER_RESOURCE,
            D3D12_BARRIER_LAYOUT_RENDER_TARGET,
            D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_SHADER_RESOURCE,
            pTexture
        }
    };

    D3D12_BARRIER_GROUP TexBarrierGroup[] =
    {
        {
            D3D12_BARRIER_TYPE_TEXTURE,
            1,
            TexBarriers
        },
    };

    pCommandList->Barrier(
        D3D12_BARRIER_SYNC_RENDER_TARGET,
        D3D12_BARRIER_SYNC_PIXEL_SHADING,
        1,
        TexBarrierGroup
        );

    // Buffer state transition barrier:
    // D3D12_RESOURCE_STATE_STREAM_OUTPUT -> D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE
    D3D12_BUFFER_BARRIER BufBarriers[] =
    {
        {
            D3D12_BARRIER_ACCESS_STREAM_OUTPUT,
            D3D12_BARRIER_ACCESS_SHADER_RESOURCE,
            pBuffer
        }
    };

    D3D12_BARRIER_GROUP BufBarrierGroup[] =
    {
        {
            D3D12_BARRIER_TYPE_BUFFER,
            1,
            BufBarriers
        },
    };

    pCommandList->Barrier(
        D3D12_BARRIER_SYNC_STREAM_OUTPUT,
        D3D12_BARRIER_SYNC_VERTEX_SHADING,
        1,
        BufBarrierGroup
        );

    // Compute Texture UAV barrier
    D3D12_TEXTURE_BARRIER TexBarriersUAV[] =
    {
        {
            D3D12_BARRIER_ACCESS_UNORDERED_ACCESS,
            D3D12_BARRIER_ACCESS_UNORDERED_ACCESS,
            D3D12_BARRIER_LAYOUT_UNORDERED_ACCESS,
            D3D12_BARRIER_LAYOUT_UNORDERED_ACCESS,
            pTexture
        }
    };

    D3D12_BARRIER_GROUP UAVBarrierGroup[] =
    {
        {
            D3D12_BARRIER_TYPE_TEXTURE,
            1,
            TexBarriersUAV
        },
    };

    pCommandList->Barrier(
        D3D12_BARRIER_SYNC_COMPUTE_SHADING,
        D3D12_BARRIER_SYNC_COMPUTE_SHADING,
        1,
        UAVBarrierGroup
        );


    // Compute Global UAV barrier
    // This is what is called a NULL-UAV barrier in ResourceBarrier
    // vernacular.
    D3D12_BUFFER_BARRIER GlobalBarriersUAV[] =
    {
        {
            D3D12_BARRIER_ACCESS_UNORDERED_ACCESS,
            D3D12_BARRIER_ACCESS_UNORDERED_ACCESS,
            nullptr
        }
    };

    D3D12_BARRIER_GROUP GlobalBarrierGroup[] =
    {
        {
            D3D12_BARRIER_TYPE_BUFFER,
            1,
            GlobalBarriersUAV
        },
    };

    pCommandList->Barrier(
        D3D12_BARRIER_SYNC_COMPUTE_SHADING,
        D3D12_BARRIER_SYNC_COMPUTE_SHADING,
        1,
        &GlobalBarrierGroup
        );

    // Aliasing barrier index buffer -> srv texture
    D3D12_BUFFER_BARRIER BufBarrierAlias[] =
    {
        {
            D3D12_BARRIER_ACCESS_INDEX_BUFFER,
            D3D12_BARRIER_ACCESS_COMMON,
            pBuffer,
        }
    };

    D3D12_TEXTURE_BARRIER TexBarrierAlias[] =
    {
        D3D12_BARRIER_ACCESS_COMMON,
        D3D12_BARRIER_ACCESS_SHADER_RESOURCE,
        D3D12_BARRIER_LAYOUT_UNDEFINED,
        D3D12_BARRIER_LAYOUT_SHADER_RESOURCE, // Either Compute or Direct queue shader resource
        pTexture
    };

    D3D12_BARRIER_GROUP AliasBarrierGroup[] =
    {
        {
            D3D12_BARRIER_TYPE_BUFFER,
            1,
            BufBarrierAlias
        },
        {
            D3D12_BARRIER_TYPE_TEXTURE,
            1,
            TexBarrierAlias
        },
    };

    pCommandList->Barrier(
        D3D12_BARRIER_SYNC_INPUT_ASSEMBLER,
        D3D12_BARRIER_SYNC_VERTEX_SHADING,
        2,
        AliasBarrierGroup
        );
}
```

------------------------------------------------

## DDI

### D3D12DDI_BARRIER_LAYOUT

```c++
enum D3D12DDI_BARRIER_LAYOUT
{
    D3D12DDI_BARRIER_LAYOUT_UNDEFINED = 0xffffffff,
    D3D12DDI_BARRIER_LAYOUT_COMMON = 0,
    D3D12DDI_BARRIER_LAYOUT_PRESENT = 0,
    D3D12DDI_BARRIER_LAYOUT_GENERIC_READ,
    D3D12DDI_BARRIER_LAYOUT_RENDER_TARGET,
    D3D12DDI_BARRIER_LAYOUT_UNORDERED_ACCESS,
    D3D12DDI_BARRIER_LAYOUT_DEPTH_STENCIL_WRITE,
    D3D12DDI_BARRIER_LAYOUT_DEPTH_STENCIL_READ,
    D3D12DDI_BARRIER_LAYOUT_SHADER_RESOURCE,
    D3D12DDI_BARRIER_LAYOUT_COPY_SOURCE,
    D3D12DDI_BARRIER_LAYOUT_COPY_DEST,
    D3D12DDI_BARRIER_LAYOUT_RESOLVE_SOURCE,
    D3D12DDI_BARRIER_LAYOUT_RESOLVE_DEST,
    D3D12DDI_BARRIER_LAYOUT_SHADING_RATE_SOURCE,
    D3D12DDI_BARRIER_LAYOUT_VIDEO_DECODE_READ,
    D3D12DDI_BARRIER_LAYOUT_VIDEO_DECODE_WRITE,
    D3D12DDI_BARRIER_LAYOUT_VIDEO_PROCESS_READ,
    D3D12DDI_BARRIER_LAYOUT_VIDEO_PROCESS_WRITE,
    D3D12DDI_BARRIER_LAYOUT_VIDEO_ENCODE_READ,
    D3D12DDI_BARRIER_LAYOUT_VIDEO_ENCODE_WRITE,
    D3D12DDI_BARRIER_LAYOUT_DIRECT_QUEUE_COMMON,
    D3D12DDI_BARRIER_LAYOUT_DIRECT_QUEUE_GENERIC_READ,
    D3D12DDI_BARRIER_LAYOUT_DIRECT_QUEUE_UNORDERED_ACCESS,
    D3D12DDI_BARRIER_LAYOUT_DIRECT_QUEUE_SHADER_RESOURCE,
    D3D12DDI_BARRIER_LAYOUT_DIRECT_QUEUE_COPY_SOURCE,
    D3D12DDI_BARRIER_LAYOUT_DIRECT_QUEUE_COPY_DEST,
    D3D12DDI_BARRIER_LAYOUT_COMPUTE_QUEUE_COMMON,
    D3D12DDI_BARRIER_LAYOUT_COMPUTE_QUEUE_GENERIC_READ,
    D3D12DDI_BARRIER_LAYOUT_COMPUTE_QUEUE_UNORDERED_ACCESS,
    D3D12DDI_BARRIER_LAYOUT_COMPUTE_QUEUE_SHADER_RESOURCE,
    D3D12DDI_BARRIER_LAYOUT_COMPUTE_QUEUE_COPY_SOURCE,
    D3D12DDI_BARRIER_LAYOUT_COMPUTE_QUEUE_COPY_DEST,
    D3D12DDI_BARRIER_LAYOUT_VIDEO_QUEUE_COMMON,
    D3D12DDI_BARRIER_LAYOUT_LEGACY_COPY_SOURCE = 0x80000000, // Special layouts start here
    D3D12DDI_BARRIER_LAYOUT_LEGACY_COPY_DEST,
    D3D12DDI_BARRIER_LAYOUT_LEGACY_SHADER_RESOURCE,
    D3D12DDI_BARRIER_LAYOUT_LEGACY_PIXEL_SHADER_RESOURCE,
} D3D12DDI_BARRIER_LAYOUT;
```

### D3D12DDI_BARRIER_SYNC

```c++
typedef enum D3D12DDI_BARRIER_SYNC
{
    D3D12DDI_BARRIER_SYNC_NONE                                                     = 0x0,
    D3D12DDI_BARRIER_SYNC_ALL                                                      = 0x1,
    D3D12DDI_BARRIER_SYNC_DRAW                                                     = 0x2,
    D3D12DDI_BARRIER_SYNC_INPUT_ASSEMBLER                                          = 0x4,
    D3D12DDI_BARRIER_SYNC_VERTEX_SHADING                                           = 0x8,
    D3D12DDI_BARRIER_SYNC_PIXEL_SHADING                                            = 0x10,
    D3D12DDI_BARRIER_SYNC_DEPTH_STENCIL                                            = 0x20,
    D3D12DDI_BARRIER_SYNC_RENDER_TARGET                                            = 0x40,
    D3D12DDI_BARRIER_SYNC_COMPUTE_SHADING                                          = 0x80,
    D3D12DDI_BARRIER_SYNC_RAYTRACING                                               = 0x100,
    D3D12DDI_BARRIER_SYNC_COPY                                                     = 0x200,
    D3D12DDI_BARRIER_SYNC_RESOLVE                                                  = 0x400,
    D3D12DDI_BARRIER_SYNC_EXECUTE_INDIRECT                                         = 0x800,
    D3D12DDI_BARRIER_SYNC_PREDICATION                                              = 0x800,
    D3D12DDI_BARRIER_SYNC_ALL_SHADING                                              = 0x1000,
    D3D12DDI_BARRIER_SYNC_NON_PIXEL_SHADING                                        = 0x2000,
    D3D12DDI_BARRIER_SYNC_EMIT_RAYTRACING_ACCELERATION_STRUCTURE_POSTBUILD_INFO    = 0x4000,
    D3D12DDI_BARRIER_SYNC_VIDEO_DECODE                                             = 0x100000,
    D3D12DDI_BARRIER_SYNC_VIDEO_PROCESS                                            = 0x200000,
    D3D12DDI_BARRIER_SYNC_VIDEO_ENCODE                                             = 0x400000,
    D3D12DDI_BARRIER_SYNC_BUILD_RAYTRACING_ACCELERATION_STRUCTURE                  = 0x800000,
    D3D12DDI_BARRIER_SYNC_COPY_RAYTRACING_ACCELERATION_STRUCTURE                   = 0x1000000,
    D3D12DDI_BARRIER_SYNC_SPLIT                                                    = 0x80000000,
} D3D12DDI_BARRIER_SYNC;
```

### D3D12DDI_BARRIER_ACCESS

```c++
typedef enum D3D12DDI_BARRIER_ACCESS
{
    D3D12DDI_BARRIER_ACCESS_COMMON                                     = 0,
    D3D12DDI_BARRIER_ACCESS_VERTEX_BUFFER                              = 0x1,
    D3D12DDI_BARRIER_ACCESS_CONSTANT_BUFFER                            = 0x2,
    D3D12DDI_BARRIER_ACCESS_INDEX_BUFFER                               = 0x4,
    D3D12DDI_BARRIER_ACCESS_RENDER_TARGET                              = 0x8,
    D3D12DDI_BARRIER_ACCESS_UNORDERED_ACCESS                           = 0x10,
    D3D12DDI_BARRIER_ACCESS_DEPTH_STENCIL_WRITE                        = 0x20,
    D3D12DDI_BARRIER_ACCESS_DEPTH_STENCIL_READ                         = 0x40,
    D3D12DDI_BARRIER_ACCESS_SHADER_RESOURCE                            = 0x80,
    D3D12DDI_BARRIER_ACCESS_STREAM_OUTPUT                              = 0x100,
    D3D12DDI_BARRIER_ACCESS_INDIRECT_ARGUMENT                          = 0x200,
    D3D12DDI_BARRIER_ACCESS_PREDICATION                                = 0x200,
    D3D12DDI_BARRIER_ACCESS_COPY_DEST                                  = 0x400,
    D3D12DDI_BARRIER_ACCESS_COPY_SOURCE                                = 0x800,
    D3D12DDI_BARRIER_ACCESS_RESOLVE_DEST                               = 0x1000,
    D3D12DDI_BARRIER_ACCESS_RESOLVE_SOURCE                             = 0x2000,
    D3D12DDI_BARRIER_ACCESS_RAYTRACING_ACCELERATION_STRUCTURE_READ     = 0x4000,
    D3D12DDI_BARRIER_ACCESS_RAYTRACING_ACCELERATION_STRUCTURE_WRITE    = 0x8000,
    D3D12DDI_BARRIER_ACCESS_SHADING_RATE_SOURCE                        = 0x10000,
    D3D12DDI_BARRIER_ACCESS_VIDEO_DECODE_READ                          = 0x20000,
    D3D12DDI_BARRIER_ACCESS_VIDEO_DECODE_WRITE                         = 0x40000,
    D3D12DDI_BARRIER_ACCESS_VIDEO_PROCESS_READ                         = 0x80000,
    D3D12DDI_BARRIER_ACCESS_VIDEO_PROCESS_WRITE                        = 0x100000,
    D3D12DDI_BARRIER_ACCESS_VIDEO_ENCODE_READ                          = 0x200000,
    D3D12DDI_BARRIER_ACCESS_VIDEO_ENCODE_WRITE                         = 0x400000,
    D3D12DDI_BARRIER_ACCESS_NO_ACCESS                                  = 0x80000000
} D3D12DDI_BARRIER_ACCESS;
```

### D3D12DDI_BARRIER_SUBRESOURCE_RANGE_0088

```C++
typedef struct D3D12DDI_BARRIER_SUBRESOURCE_RANGE_0088
{
    UINT32 IndexOrFirstMipLevel;
    UINT32 NumMipLevels;
    UINT32 FirstArraySlice;
    UINT32 NumArraySlices;
    UINT32 FirstPlane;
    UINT32 NumPlanes;
};
```

### D3D12DDI_GLOBAL_BARRIER_0088

```C++
typedef struct D3D12DDI_GLOBAL_BARRIER_0088
{
    D3D12DDI_BARRIER_SYNC SyncBefore;
    D3D12DDI_BARRIER_SYNC SyncAfter;
    D3D12DDI_BARRIER_ACCESS AccessBefore;
    D3D12DDI_BARRIER_ACCESS AccessAfter;
} D3D12DDI_GLOBAL_BARRIER_0088;
```

### D3D12DDI_TEXTURE_BARRIER_0088_FLAGS_0088

```C++
enum D3D12DDI_TEXTURE_BARRIER_0088_FLAGS_0088
{
    D3D12DDI_TEXTURE_BARRIER_0088_FLAG_NONE = 0x0,
    D3D12DDI_TEXTURE_BARRIER_0088_FLAG_DISCARD = 0x1,
}
```

### D3D12DDI_TEXTURE_BARRIER_0088

```C++
typedef struct D3D12DDI_TEXTURE_BARRIER_0088
{
    D3D12DDI_BARRIER_SYNC SyncBefore;
    D3D12DDI_BARRIER_SYNC SyncAfter;
    D3D12DDI_BARRIER_ACCESS AccessBefore;
    D3D12DDI_BARRIER_ACCESS AccessAfter;
    D3D12DDI_BARRIER_LAYOUT LayoutBefore;
    D3D12DDI_BARRIER_LAYOUT LayoutAfter;
    D3D12DDI_HRESOURCE hResource;
    D3D12DDI_BARRIER_SUBRESOURCE_RANGE_0088 Subresources;
    D3D12DDI_TEXTURE_BARRIER_0088_FLAGS_0088 Flags;
} D3D12DDI_TEXTURE_BARRIER_0088;
```

### D3D12DDI_BUFFER_BARRIER_0088

```C++
typedef struct D3D12DDI_BUFFER_BARRIER_0088
{
    D3D12DDI_BARRIER_SYNC SyncBefore;
    D3D12DDI_BARRIER_SYNC SyncAfter;
    D3D12DDI_BARRIER_ACCESS AccessBefore;
    D3D12DDI_BARRIER_ACCESS AccessAfter;
    D3D12DDI_HRESOURCE hResource;
} D3D12DDI_BUFFER_BARRIER_0088;
```

### D3D12DDI_RANGED_BARRIER_FLAGS

```C++
typedef enum D3D12DDI_RANGED_BARRIER_FLAGS
{
    D3D12DDI_RANGED_BARRIER_0088_FLAG_NONE           = 0,
    D3D12DDI_RANGED_BARRIER_0088_FLAG_ATOMIC_COPY    = 0x1,
} D3D12DDI_RANGED_BARRIER_FLAGS;
```

### D3D12DDI_RANGED_BARRIER_0088

Replaces legacy D3D12DDI_RESOURCE_RANGED_BARRIER_0022.  Enhanced Barriers are designed to fully deprecate the legacy ResourceBarrier DDI's.  This includes the ranged barriers used internally by AtomicCopy commands.

```C++
typedef struct D3D12DDI_RANGED_BARRIER_0088
{
    D3D12DDI_BARRIER_SYNC SyncBefore;
    D3D12DDI_BARRIER_SYNC SyncAfter;
    D3D12DDI_BARRIER_ACCESS AccessBefore;
    D3D12DDI_BARRIER_ACCESS AccessAfter;
    D3D12DDI_RANGED_BARRIER_FLAGS Flags;
    D3D12DDI_HRESOURCE hResource;
    D3D12DDI_BARRIER_SUBRESOURCE_RANGE_0088 Subresources;
    D3D12DDI_RANGE Range;
} D3D12DDI_RANGED_BARRIER_0088;
```

### D3D12DDI_BARRIER_TYPE

```C++
typedef enum D3D12DDI_BARRIER_TYPE
{
    D3D12DDI_BARRIER_TYPE_GLOBAL,
    D3D12DDI_BARRIER_TYPE_TEXTURE,
    D3D12DDI_BARRIER_TYPE_BUFFER,
    D3D12DDI_BARRIER_TYPE_RANGED,
} D3D12DDI_BARRIER_TYPE;

```

### D3D12DDIARG_BARRIER_0088

```C++
typedef struct D3D12DDIARG_BARRIER_0088
{
    D3D12DDI_BARRIER_TYPE Type;
    union
    {
        D3D12DDI_GLOBAL_BARRIER_0088 GlobalBarrier;
        D3D12DDI_TEXTURE_BARRIER_0088 TextureBarrier;
        D3D12DDI_BUFFER_BARRIER_0088 BufferBarrier;
        D3D12DDI_RANGED_BARRIER_0088 RangedBarrier;
    };
} D3D12DDIARG_BARRIER_0088;
```

### PFND3D12DDI_BARRIER

```C++
typedef VOID ( APIENTRY* PFND3D12DDI_BARRIER )(
    UINT32 NumBarriers,
    _In_reads(NumBarriers) CONST D3D12DDIARG_BARRIER_0088 *pBarriers );

```

### D3D12DDIARG_CREATERESOURCE_0088

```C++
typedef struct D3D12DDIARG_CREATERESOURCE_0088
{
    D3D12DDIARG_BUFFER_PLACEMENT    ReuseBufferGPUVA;
    D3D12DDI_RESOURCE_TYPE          ResourceType;
    UINT64                          Width; // Virtual coords
    UINT                            Height; // Virtual coords
    UINT16                          DepthOrArraySize;
    UINT16                          MipLevels;
    DXGI_FORMAT                     Format;
    DXGI_SAMPLE_DESC                SampleDesc;
    D3D12DDI_TEXTURE_LAYOUT         Layout; // See standard swizzle spec
    D3D12DDI_RESOURCE_FLAGS_0003    Flags;
    D3D12DDI_BARRIER_LAYOUT         InitialBarrierLayout;

    // When Layout = D3D12DDI_TL_ROW_MAJOR and pRowMajorLayout is non-null
    // then *pRowMajorLayout specifies the layout of the resource
    CONST D3D12DDIARG_ROW_MAJOR_RESOURCE_LAYOUT* pRowMajorLayout;

    D3D12DDI_MIP_REGION_0075       SamplerFeedbackMipRegion;
    UINT32                          NumCastableFormats;
    DXGI_FORMAT *                   pCastableFormats;
} D3D12DDIARG_CREATERESOURCE_0088;
```

### PFND3D12DDI_CREATEHEAPANDRESOURCE_0088

```C++
typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATEHEAPANDRESOURCE_0088)(
    D3D12DDI_HDEVICE, _In_opt_ CONST D3D12DDIARG_CREATEHEAP_0001*, D3D12DDI_HHEAP, D3D12DDI_HRTRESOURCE,
    _In_opt_ CONST D3D12DDIARG_CREATERESOURCE_0088*, _In_opt_ CONST D3D12DDI_CLEAR_VALUES*,
    D3D12DDI_HPROTECTEDRESOURCESESSION_0030, D3D12DDI_HRESOURCE );
```

### PFND3D12DDI_CALCPRIVATEHEAPANDRESOURCESIZES_0088

```C++
typedef D3D12DDI_HEAP_AND_RESOURCE_SIZES ( APIENTRY* PFND3D12DDI_CALCPRIVATEHEAPANDRESOURCESIZES_0088)(
     D3D12DDI_HDEVICE, _In_opt_ CONST D3D12DDIARG_CREATEHEAP_0001*, _In_opt_ CONST D3D12DDIARG_CREATERESOURCE_0088*,
     D3D12DDI_HPROTECTEDRESOURCESESSION_0030 );
```

### PFND3D12DDI_CHECKRESOURCEALLOCATIONINFO_0088

```C++
typedef VOID ( APIENTRY* PFND3D12DDI_CHECKRESOURCEALLOCATIONINFO_0088)(
    D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATERESOURCE_0088*, D3D12DDI_RESOURCE_OPTIMIZATION_FLAGS,
    UINT32 AlignmentRestriction, UINT VisibleNodeMask, _Out_ D3D12DDI_RESOURCE_ALLOCATION_INFO_0022* );
```

### D3D12DDI_D3D12_OPTIONS_DATA_0089

Includes a boolean member indicating whether the driver supports EnhancedBarriers.

```C++
typedef struct D3D12DDI_D3D12_OPTIONS_DATA_0089
{
    D3D12DDI_RESOURCE_BINDING_TIER ResourceBindingTier;
    D3D12DDI_CONSERVATIVE_RASTERIZATION_TIER ConservativeRasterizationTier;
    D3D12DDI_TILED_RESOURCES_TIER TiledResourcesTier;
    D3D12DDI_CROSS_NODE_SHARING_TIER CrossNodeSharingTier;
    BOOL VPAndRTArrayIndexFromAnyShaderFeedingRasterizerSupportedWithoutGSEmulation;
    BOOL OutputMergerLogicOp;
    D3D12DDI_RESOURCE_HEAP_TIER ResourceHeapTier;
    BOOL DepthBoundsTestSupported;
    D3D12DDI_PROGRAMMABLE_SAMPLE_POSITIONS_TIER ProgrammableSamplePositionsTier;
    BOOL CopyQueueTimestampQueriesSupported;
    D3D12DDI_COMMAND_QUEUE_FLAGS WriteBufferImmediateQueueFlags;
    D3D12DDI_VIEW_INSTANCING_TIER ViewInstancingTier;
    BOOL BarycentricsSupported;
    BOOL ReservedBufferPlacementSupported; // Actually just 64KB aligned MSAA support
    BOOL Deterministic64KBUndefinedSwizzle;
    BOOL SRVOnlyTiledResourceTier3;
    D3D12DDI_RENDER_PASS_TIER RenderPassTier;
    D3D12DDI_RAYTRACING_TIER RaytracingTier;
    D3D12DDI_VARIABLE_SHADING_RATE_TIER VariableShadingRateTier;
    BOOL PerPrimitiveShadingRateSupportedWithViewportIndexing;
    BOOL AdditionalShadingRatesSupported;
    UINT ShadingRateImageTileSize;
    BOOL BackgroundProcessingSupported;
    D3D12DDI_MESH_SHADER_TIER MeshShaderTier;
    D3D12DDI_SAMPLER_FEEDBACK_TIER SamplerFeedbackTier;
    BOOL DriverManagedShaderCachePresent;
    BOOL MeshShaderSupportsFullRangeRenderTargetArrayIndex;
    BOOL VariableRateShadingSumCombinerSupported;
    BOOL MeshShaderPerPrimitiveShadingRateSupported;
    BOOL MSPrimitivesPipelineStatisticIncludesCulledPrimitives;
    BOOL EnhancedBarriersSupported;
} D3D12DDI_D3D12_OPTIONS_DATA_0089;

```

------------------------------------------------

## Open Issues

### Compression metadata init for LAYOUT_UNORDERED_ACCESS

Some IHV's have indicated there may be a need for Clear/Copy/Discard for unordered access metadata init.  Thus far this has only ever been required for RENDER_TARGET and DEPTH_STENCIL.

If this is added to the enhanced barriers spec, a BARRIER_LAYOUT_LEGACY_UNORDERED_ACCESS is likely needed to support legacy barriers, which can be used without Clear/Copy/Discard.

------------------------------------------------

## Testing

### Functional Testing

Functional tests primarily cover debug layer validation scenarios.  All other functional testing is covered by additional HLK tests.

### Unit Testing

No target unit tests.  Leverages existing ResourceBarrier unit tests.

### HLK Testing

Given that existing ResourceBarriers are implemented on-top of the enhanced Barrier DDI's, much of the conformance testing is naturally handled by existing HLK tests.  However, since the enhanced Barriers expose previously inaccessible hardware functionality, the following test scenarios need new HLK testing:

- Asynchronous Copy, Discard and Resolve
- Self-resource copy
- Single-Queue simultaneous access
- Subresource Ranges
- Enhanced resource aliasing support

------------------------------------------------

## Debug Layers

Supporting both legacy resource state validation and the enhanced Barrier API validation is not a reasonable option.  The enhanced Barrier API's are a superset of the legacy Resource Barrier capabilities, meaning there is no parity between legacy resource states and the "state" of a resource in the enhanced Barrier API model.  Therefore, given that existing ResourceBarrier API's are implemented on-top of enhanced Barrier DDI's, all Barrier validation is based on the enhanced Barrier design.

There may be an option to retain some of the existing resource state validation when the state of a resource is "known".  For example, an application that only uses legacy ResourceBarrier API's is guaranteed to keep resources in a known-state.  Retaining and segregating legacy state validation from enhanced Barrier API validation requires significant additional work beyond simply adding enhanced Barrier validation.

### Validation Phases

Validation of barrier layout, sync and access is accomplished in two separate phases.

#### Command List Record Validation Phase

During command list record, the initial layout, sync scope, and accessibility of a resource is indeterminate.  As such, the debug layer sets these to a assumed values and reconciles these assumptions at the ExecuteCommandLists call-site phase.  Subsequent record-time validation builds on that initial assumption.

#### ExecuteCommandLists Call-Site Validation Phase

All resources initially have access status of ACCESS_COMMON at the start of an ExecuteCommandLists scope.  The debug layer uses this to reconcile access and sync validation when ExecuteCommandLists is called.

Texture layout is the only transient property of resources that propagate from one ExecuteCommandLists call to the next.  When Synchronized Command Queue Execution is enabled, texture layout can be accurately resolved to enable validation of record-time layout assumptions.  This applies only to non-simultaneous-access texture resources.  Simultaneous-access textures always have a COMMON layout, and buffers have no layout.

Since layout can only be changed using the Barrier API, the debug layer only needs to keep track of Layout Barriers to track texture layout.  This is in contrast to Legacy Resource Barriers, which needed to account for resource state promotion and decay.

### Barrier API Call Validation

The debug layer validates the following during Barrier calls:

- Underlying device supports enhanced barriers
- Not bundle command list
- Warn if any count (group or per-group-barriers) is zero
- Verify texture barrier Subresources match texture subresource bounds
- Barrier type matches resource type
- LayoutBefore and AccessBefore match known or assumed resource layout and access.
- SyncBefore, AccessBefore and LayoutBefore are compatible.
- SyncAfter, AccessAfter and LayoutAfter are compatible.
- End-split barriers match preceding Begin-split barriers.
- Buffer and LAYOUT_COMMON split barriers do not cross ExecuteCommandListsBoundaries
  - Probably a warning rather than an error due to legacy allowances

### Layout Validation

Only texture resources have layout.  Therefore, buffers are effectively in RESOURCE_STATE_COMMON between ExecuteCommandLists boundaries.  Legacy resource state validation handles buffer state by "decaying" buffer state to RESOURCE_STATE_COMMON upon completion of ExecuteCommandLists.  In fact, the complex rules surrounding resource state promotion and decay are a significant portion of the debug validation source.

Validation for Layout Barriers is partially validated during command list record using an assumed initial layout. The assumed layout is later validated during the ExecuteCommandLists call.  Synchronized command queue execution must be enabled to validate texture layout between ExecuteCommandLists calls.  In some cases, more than one assumed layout is possible (e.g. LAYOUT_SHADER_RESOURCE and LAYOUT_COMMON both support use as a shader resource). The debug layer resolves the assumed layout against the actual layout during command list execution (again, only when command queue sync is enabled).

### Access Bits Validation

During command list record, the first access of a resource is assumed to be valid and is tracked as such.  This assumption is later verified during ExecuteCommandLists, command queue sync is not required since access bits to not carry across ExecuteCommandLists boundaries.  Note, it is not possible to track initial use of a resource as CBV, UAV or SRV unless they are bound to using data-static descriptors.  Validation of such accesses requires GPU-Based Validation.

The debug layer only reports errors when a known access is incompatible with the most recently tracked allowed access and/or layout.  Any resource accesses made must match the previous AccessAfter barrier.

If the current accessibility of a resource is ACCESS_COMMON (0), then any layout-compatible access type is allowed without a barrier (unless the access depends on a preceding write).  If the layout supports it, multiple access types can be made without a barrier, with no more than one write access type.

Only texture subresources in BARRIER_LAYOUT_COMMON and buffers support concurrent read and write access types.

Barrier AccessBefore bits must include bits for any accesses made since the previous barrier.

Only one write access type is allowed at a time.

For concurrent read/write accesses, the debug layer DOES NOT track whether written regions intersect with concurrent read regions.

### Sync Validation

The Debug Layer attempts to validate barriers are correctly mitigating hazards.  In most cases, hazards are detected as a result of incompatible access types, including most read-after-write and write-after-read hazards.  However, there are some write-after-write operations need sync-only barriers:

- Raytracing Acceleration Structure Writes
- Unordered Access (requires GBV to detect unless using DATA_STATIC descriptors)
- Copy (when using D3D12_COMMAND_LIST_FLAG_ALLOW_ALLOW_EXTENDED_ASYNC)
- Resolve (when using D3D12_COMMAND_LIST_FLAG_ALLOW_ALLOW_EXTENDED_ASYNC)

Note that there is no sync validation resources supporting concurrent read and write.  It is up to the app developer to know when to synchronize dependent accesses.

### Global Barrier Validation

Global barriers effectively apply to all resource accesses in the same command queue ExecuteCommandLists scope. Since the debug layer keeps track of all resource accesses during command list record, a global barrier is treated as a no-layout-changing barrier for every tracked resource with a compatible layout and a last-access matching the global barrier AccessBefore bits.

Global barriers are greedy. All compatible subresources with access bits matching the global barrier AccessBefore value are transitioned to AccessAfter. This may have unintended side-effects so global barriers should be used sparingly. In almost all cases it is better to use a Buffer or Texture barrier. A subresource is considered 'compatible' with a global barrier when the current layout is compatible with both AccessBefore and AccessAfter bits. Likewise, a subresource is only compatible with a global barrier when the resource creation flags allow for both AccessBefore and AccessAfter. For example, a buffer created without the D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS bit set is not affected by a global barrier using D3D12_BARRIER_ACCESS_UNORDERED_ACCESS.

If AccessBefore is ACCESS_COMMON then AccessAfter MUST also be ACCESS_COMMON. Otherwise global barriers could constrain accesses to subresources not intended to be affected by the barrier. A global barrier using ACCESS_COMMON could be used to perform a full flush-and-finish of outstanding resource writes.

Global barriers are only useful for ensuring write operations are finished before subsequent read or write operations in the same ExecuteCommandLists scope. As such, global barriers with read-only AccessBefore bits provide no value and are ignored, producing a warning when debug layer is enabled.

### Legacy vs Enhanced State Validation

During command list record, the actual legacy state or layout of the resource will have at execution time cannot be known.  Therefore, the first command referencing the resource assigns an "assumed legacy state or access state".  Subsequent non-barrier accesses are validated against the assumed state or access, updating the assumed bits or producing an error if the accesses are incompatible.

Until the first barrier call, the record-time layout of any texture remains LAYOUT_UNDEFINED, meaning no record-time validation of layout is performed.

Debug layer validation of legacy states is used only if the resource currently has an assigned legacy state, either through a legacy resource Create or having been transitioned with a legacy barrier in a previously completed command list execution.  All other barrier validation uses enhanced barriers.

### GPU-Based Validation

GPU-Based Validation (GBV) is built around the legacy resource state model.  GBV already greatly bloats shaders and saps performance by several orders of magnitude.  Adding D3D12 Barrier validation to GBV is only going to greatly increase that cost. Therefore, maintaining compatibility with both legacy Resource Barriers and the enhanced Barrier API's are impractical.  Therefore, all GBV validation must be based on the enhanced Barriers API's.

Without resource state promotion, GBV may be able to reduce much of the overhead introduced by supporting promotion and decay.  In addition, GBV can take advantage of the fact that buffers have no layout, and thus only access bits must be validated.  Note that ACCESS_COMMON is a special case that allows any type of access compatible with resource layout (and create-time attributes), which is similar to promotion.  GBV must also handle ensuring only one write access type is performed without a barrier.

GBV uses a sparse buffer to keep track of texture layouts globally.  This is only necessary for texture resources since buffers have no layout.  The buffer must be logically large enough to contain they layout of all application resources (or risk loss of validation).  Since GBV requires synchronized queue execution, GBV reads form and writes to the global data directly during shader execution.  GBV writes only occur during Barrier operations since layout is not "promotable".  This could be a big performance win over legacy ResourceBarrier validation.

GBV uses a separate sparsly-resident buffer to keep track of local resource access state (state local to a given ExecuteCommandLists context).  This buffer must be logically large enough to store the transient access bits for all application resources (or risk loss of validation).  Patched shaders require write access to this buffer to keep track of UAV write operations on resources with ACCESS_COMMON access bit set.  This allows GBV to validate against disparate write access types missing a barrier.

Legacy GBV validation used a similar system, except that both buffers and textures were tracked only using "state", therefore the local buffer is a temporary copy of the global buffer.  At the start of ExecuteCommandLists, GBV copied the state of all resources to the local subresource-states buffer as an initial state.  At the end of ExecuteCommandLists, resource states that changed were copied back to the global buffer.

With enhanced barriers, the "global buffer" tracks only texture layout and the "local buffer" tracks only resource access bits.  Therefore, no copy between the buffers is needed.  The local access-bits buffer gets initialized to ACCESS_COMMON (0) for all existing resources at the start of an ExecuteCommandLists scope, and is discarded upon completion of an ExecuteCommandLists scope.  The global subresource-layout buffer is accessed directly by GBV operations (since GBV GPU-work is serialized, there is no contention for this data).

This does require an extra binding since subresource layout is tracked in a different buffer than subresource access bits.  Legacy GBV only bound the local subresource states buffer, copying promoted results to the global subresource states buffer.  GBV for enhanced barriers must bind the local access bits buffer and the global subresource layout buffer in separate UAV locations.  Changes to Layout or access bits only occur as a result of Barrier calls.  All other accesses to this data is read-only.

Unlike legacy resource states, layout and access bits can only ever be changed using a barrier.  There is no promotion of layout or access bits as a result of a read or write.  Therefore, GBV doesn't have to modify state during shader patching.  Instead GBV does the following:

- Validates the access being made is compatible with the subresource access bits (if COMMON, then any layout-compatible access is allowed).
- If the resource is a texture, the access being made is compatible with the subresource layout.

Similarly, most non-Draw or Dispatch commands do not require a special GBV-Dispatch to validate or promote state.
