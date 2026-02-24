# D3D12 CPU Timeline Query Resolution<!-- omit in toc -->

This document proposes a new D3D12 feature that allows developers to resolve query data on the CPU timeline rather than requiring GPU-based resolution, improving convenience and performance for common query scenarios.

## Contents <!-- omit in toc -->

- [Introduction](#introduction)
- [Problem Statement](#problem-statement)
- [Goals](#goals)
- [Non-Goals](#non-goals)
- [Overall Design](#overall-design)
- [API](#api)
  - [D3D12_QUERY_HEAP_FLAGS](#d3d12_query_heap_flags)
  - [ID3D12Device::CreateQueryHeap1](#id3d12devicecreatequeryheap1)
  - [ID3D12Device::ResolveQueryData](#id3d12commandqueueresolvequerydata)
- [DDI](#ddi)
  - [D3D12DDI_QUERY_HEAP_FLAGS](#d3d12ddi_query_heap_flags)
  - [PFND3D12DDI_CREATE_QUERY_HEAP_0119](#pfnd3d12ddi_create_query_heap_0119)
  - [PFND3D12DDI_RESOLVE_QUERY_DATA](#pfnd3d12ddi_resolve_query_data)
- [Runtime Fallback](#runtime-fallback)  
- [Test Plan](#test-plan)
- [Change Log](#change-log)

---

## Introduction

D3D12's current query system requires developers to explicitly resolve query data on the GPU timeline using `ResolveQueryData()` Command List operations. This approach, while providing fine-grained control, introduces several inconveniences:

- Developers must manage additional command list operations for query resolution
- GPU bandwidth is consumed for what is often a simple data transformation
- Synchronization between query completion and resolution becomes more complex
- Reading resolved data requires additional CPU/GPU synchronization

This proposal introduces CPU-based query resolution APIs that allow the runtime/driver to resolve query data using the CPU after GPU execution completes, providing a more convenient and often more efficient alternative for common query scenarios. 

---

## Problem Statement

Current D3D12 query workflow requires several steps:

1. Begin query operation
2. Perform GPU work
3. End query operation
4. Submit command list
5. Issue ResolveQueryData operation in the same or subsequent command list
6. Wait for GPU completion
7. Read resolved data from destination buffer

This workflow is cumbersome for scenarios where developers simply want to read query results on the CPU after GPU work completes. Common use cases that would benefit from CPU resolution include:

- Performance profiling and telemetry collection
- Simple occlusion culling decisions
- Basic GPU timing measurements
- Debug and diagnostic information gathering

---

## Goals

- Provide a more convenient API for CPU-based query result consumption
- Reduce GPU bandwidth usage for simple query resolution scenarios
- Simplify synchronization between query completion and result consumption
- Maintain as much of the existing query API infrastructure as possible (enums, structs etc.)
- Support runtime emulation on older drivers or hardware that cannot support the feature natively

---

## Non-Goals

- Replace the existing GPU-based query resolution system
- Support streaming or partial query resolution
- Provide real-time query results before GPU completion

---

## Overall Design

The CPU Timeline Query Resolution feature introduces one new API:

- **ResolveQueryData()** - CPU-based query resolution on ID3D12Device Object

The design allows developers to resolve the query data on the CPU timeline after GPU execution completes. Any post processing of the query data is abstracted by the runtime and driver.

For drivers or hardware that do not support native CPU resolution, the runtime provides transparent fallback by automatically generating the necessary GPU-based resolution operations.

---

## API

### D3D12_QUERY_HEAP_FLAGS

```c++
typedef enum D3D12_QUERY_HEAP_FLAGS
{
    D3D12_QUERY_HEAP_FLAG_NONE = 0,
    D3D12_QUERY_HEAP_FLAG_CPU_RESOLVE = 1,
};
```

**Members:**

- **D3D12_QUERY_HEAP_FLAG_NONE** - No special flags. The query heap can only be resolved using the traditional GPU-based `ID3D12GraphicsCommandList::ResolveQueryData()` method.

- **D3D12_QUERY_HEAP_FLAG_CPU_RESOLVE** - Enables CPU-based query resolution for this query heap. When this flag is set, applications can use the `ID3D12Device::ResolveQueryData()` method to resolve query data directly on the CPU timeline after GPU execution completes.

**Remarks:**

Query heaps created without the `D3D12_QUERY_HEAP_FLAG_CPU_RESOLVE` flag cannot be used with the `ID3D12Device::ResolveQueryData()` method and will return `E_INVALIDARG` if attempted. Conversely, heaps created with the CPU resolve flag cannot be used with the Command List resolve API.

### ID3D12Device::CreateQueryHeap1

Create a Query Heap with the option for CPU based resolves.

```c++
HRESULT CreateQueryHeap1( 
  [in] const D3D12_QUERY_HEAP_DESC *pDesc,
  [in] D3D12_QUERY_HEAP_FLAGS Flags,
  [in] REFIID riid,
  [inout] void **ppvHeap);
```

**Parameters:**

- **pDesc** - A pointer to a `D3D12_QUERY_HEAP_DESC` structure that describes the query heap. This structure contains the query heap type, number of queries, and node mask for multi-adapter scenarios.

- **Flags** - A `D3D12_QUERY_HEAP_FLAGS` value that specifies additional options for the query heap. Use `D3D12_QUERY_HEAP_FLAG_CPU_RESOLVE` to enable CPU-based query resolution with the `ID3D12Device::ResolveQueryData()` method.

- **riid** - The globally unique identifier (GUID) for the query heap interface. This parameter is typically `IID_ID3D12QueryHeap`.

- **ppvHeap** - A pointer to a memory block that receives a pointer to the query heap object. The type of interface returned depends on the `riid` parameter.

**Return Value:**

- **S_OK** - The query heap was created successfully.
- **E_INVALIDARG** - One or more parameters are invalid.
- **E_OUTOFMEMORY** - Insufficient memory to create the query heap.
- **E_FAIL** - An unspecified error occurred.

**Remarks:**

This method extends the original `CreateQueryHeap()` method by adding support for query heap creation flags. Query heaps created with this method are functionally identical to those created with `CreateQueryHeap()` when using `D3D12_QUERY_HEAP_FLAG_NONE`.

When the `D3D12_QUERY_HEAP_FLAG_CPU_RESOLVE` flag is specified, the runtime and driver may optimize the query heap allocation for CPU access. This can enable more efficient CPU-based query resolution but may have different memory characteristics compared to standard query heaps.

### ID3D12Device::ResolveQueryData

CPU-based query resolution method on a Device.

```cpp
HRESULT ResolveQueryData(
    [in]  ID3D12QueryHeap *pQueryHeap,
    [in]  D3D12_QUERY_TYPE Type,
    [in]  UINT StartIndex,
    [in]  UINT NumQueries,
    [inout] void* pResolvedQueryData);
```

**Parameters:**
- `pQueryHeap` - Query heap containing the queries to resolve
- `Type` - Type of queries to resolve
- `StartIndex` - Index of first query to resolve
- `NumQueries` - Number of consecutive queries to resolve
- `pResolvedQueryData` - A pointer to CPU memory to receive the resolved query data

**Return Value:**
- `S_OK` - Resolution completed successfully
- `E_INVALIDARG` - Invalid parameters

**Remarks:**
This method resolves query data on the CPU timeline after Command List which initiated the queries has completed execution on the GPU. Any required post-processing of the raw query data generated on the GPU timeline will be performed on the CPU immediately by the runtime and/or driver. 

The output buffer must be sized correctly for the query type and number of queries to resolve.

- **Occlusion queries**: 8 bytes per query (UINT64)
- **Binary occlusion queries**: 8 bytes per query (UINT64, 0 or 1)
- **Timestamp queries**: 8 bytes per query (UINT64)
- **Pipeline statistics queries**: size of D3D12_QUERY_DATA_PIPELINE_STATISTICS
- **Stream output statistics queries**: size of D3D12_QUERY_DATA_SO_STATISTICS

The query heap must have been created with the `D3D12_QUERY_HEAP_FLAG_CPU_RESOLVE` flag for this method to succeed.

---

## DDI

### D3D12DDI_QUERY_HEAP_FLAGS

```c++
typedef enum D3D12DDI_QUERY_HEAP_FLAGS
{
    D3D12DDI_QUERY_HEAP_FLAG_NONE = 0,
    D3D12DDI_QUERY_HEAP_FLAG_CPU_RESOLVE = 1,
};
```

### PFND3D12DDI_CREATE_QUERY_HEAP_0119

DDI for CreateQueryHeap1

```cpp
typedef HRESULT (APIENTRY* PFND3D12DDI_CREATE_QUERY_HEAP_0119)(
  D3D12DDI_HDEVICE hDevice,
  _In_ CONST D3D12DDIARG_CREATE_QUERY_HEAP_0001* pCreate,
  D3D12DDI_QUERY_HEAP_FLAGS Flags,
  D3D12DDI_HQUERYHEAP hQueryHeap
);
```

### PFND3D12DDI_RESOLVE_QUERY_DATA

DDI for CPU-based query resolution.

```cpp
typedef HRESULT (APIENTRY* PFND3D12DDI_RESOLVE_QUERY_DATA)(
    D3D12DDI_HDEVICE hDevice,
    D3D12DDI_HQUERYHEAP hQueryHeap,
    D3D12_QUERY_TYPE Type,
    UINT StartIndex,
    UINT NumQueries,
    void* pResolvedQueryData
);
```
---

## Runtime Fallback
For drivers or hardware that do not support native CPU-based query resolution, the D3D12 runtime provides transparent fallback behavior to ensure the feature works universally across all D3D12-capable hardware.

### Fallback Mechanism

When a query heap is created with the `D3D12_QUERY_HEAP_FLAG_CPU_RESOLVE` flag on hardware or drivers that lack native support:

1. **Automatic GPU Resolution Injection**: The runtime automatically injects GPU-based `ResolveQueryData` operations into command lists at `Close()` time for any query heaps that have been used and marked for CPU resolution.

2. **Internal Buffer Management**: The runtime creates and manages internal GPU-visible destination buffers to store the resolved query results. These buffers are sized appropriately for the query types and counts used.

3. **Transparent Operation**: Applications using `ID3D12Device::ResolveQueryData()` are unaware of the fallback - the method behaves identically whether using native support or runtime emulation.


## Test Plan

### Conformance Tests
- Augment existing Query testing to ensure that the new APIs perform identically except on the CPU timeline.

### Functional Tests
- Conformance tests running on WARP will be used in place of functional tests outside of very basic API exercising.

---

## Change Log

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | August 2025 | Initial version | 
| 1.1 | September 2025 | Remove TOP/BOP Timestamps from proposal | 

