<h1>D3D12 Counters & Queries</h1>
UAV Counters, Stream-Output Counters, Queries.

---

- [Summary](#summary)
- [Detailed Design](#detailed-design)
  - [Stream Output Counters](#stream-output-counters)
  - [UAV Counters](#uav-counters)
  - [Queries](#queries)
  - [Timestamp Frequency](#timestamp-frequency)
  - [Clock Calibration](#clock-calibration)
  - [ResolveQueryData](#resolvequerydata)
- [Test Plan](#test-plan)
  - [Runtime Functional Tests](#runtime-functional-tests)
  - [Driver Conformance Tests](#driver-conformance-tests)

---

# Summary

This document describes the Direct3D12 UAV counters, stream-output
counters, and queries.

---

# Detailed Design

---

## Stream Output Counters

The application is responsible for allocating storage for a 32-bit
quantity called the BufferFilledSize. This contains the number of bytes
of data in the stream-output buffer. This storage must be placed in the
same resource as the one that contains the stream-output data. This
value is accessed by the GPU in the stream-output stage to determine
where to append new vertex data in the buffer. Additionally, this value
is accessed by the GPU to determine when overflow has occurred.

```C++
typedef struct D3D12_STREAM_OUTPUT_VIEW_DESC
{
    UINT64 OffsetInBytes;
    UINT64 SizeInBytes;
    UINT64 BufferFilledSizeOffsetInBytes;
} D3D12_STREAM_OUTPUT_VIEW_DESC;
```

The runtime will validate the following in
ID3D12CommandList::SetStreamOutputBuffersSingleUse and
ID3D12Device::CreateStreamOutputView:

- BufferFilledSize does not fall in the range implied by
    {OffsetInBytes, SizeInBytes} (if a non-NULL resource is specified).

- BufferFilledSizeOffsetInBytes is a multiple of 4

- BufferFilledSizeOffsetInBytes is within the range of the containing
    resource

- The specified resource is a buffer

The runtime will not validate the heap type associated with the stream
output buffer. Stream output is supported in upload, default, and
readback heaps.

Root signatures must specify if stream output will be used. This enables
drivers to reserve binding space for stream output buffers and counters.

```C++
typedef enum D3D12_ROOT_SIGNATURE_FLAGS
{
  D3D12_ROOT_SIGNATURE_ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT = 0x1,
  D3D12_ROOT_SIGNATURE_ALLOW_STREAM_OUTPUT = 0x2,
  D3D12_ROOT_SIGNATURE_DISALLOW_VERTEX_SHADER_ROOT_ACCESS = 0x4,
  D3D12_ROOT_SIGNATURE_DISALLOW_HULL_SHADER_ROOT_ACCESS = 0x8,
  D3D12_ROOT_SIGNATURE_DISALLOW_DOMAIN_SHADER_ROOT_ACCESS = 0x10,
  D3D12_ROOT_SIGNATURE_DISALLOW_GEOMETRY_SHADER_ROOT_ACCESS = 0x20,
  D3D12_ROOT_SIGNATURE_DISALLOW_PIXEL_SHADER_ROOT_ACCESS = 0x40,
} D3D12_ROOT_SIGNATURE_FLAGS;
```

D3D12_ROOT_SIGNATURE_ALLOW_STREAM_OUTPUT can be specified for root
signatures authored in HLSL, in a manner similar to how the other flags
are specified.

CreateGraphicsPipelineState will fail if the geometry shader contains
stream-output but the root signature does not have the
D3D12_ROOT_SIGNATURE_ALLOW_STREAM_OUTPUT flag set.

When a resource is used as a stream-output target, the resource must be
in the D3D12_RESOURCE_USAGE_STREAM_OUT state. This naturally applies
to both the vertex data and the BufferFilledSize, because both come from
the same resource.

The ID3D12CommandList::SetStreamOutputBufferOffset API is removed
because applications can write to the BufferFilledSize with the GPU
directly.

ID3D12CommandList::DrawAuto is removed. This can be emulated via
DrawInstancedIndirect.

---

## UAV Counters

The application is responsible for allocating 32-bits of storage for UAV
counters. This storage can be allocated in a different resource as the
one that contains data accessible via the UAV.

```C++
void ID3D12Device::CreateUnorderedAccessView(
    ID3D12Resource* pResource,
    ID3D12Resource* pCounterResource,
    const D3D12_UNORDERED_ACCESS_VIEW_DESC* pDesc,
    D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor
    );

typedef enum D3D12_BUFFER_UAV_FLAG
{
    D3D12_BUFFER_UAV_FLAG_RAW = 0x00000001,
} D3D12_BUFFER_UAV_FLAG;

typedef struct D3D12_BUFFER_UAV
{
    UINT64 FirstElement;
    UINT NumElements;
    UINT StructureByteStride;
    UINT64 CounterOffsetInBytes;
    UINT Flags;
} D3D12_BUFFER_UAV;
```

Note that ID3D12CommandList::SetGraphicsRootUnorderedAccessViewSingleUse
and ID3D12CommandList::SetComputeRootUnorderedAccessViewSingleUse do
_not_ support UAV counters.

If pCounterResource is specified then there is a counter associated with
the UAV. In this case:

- StructureByteStride must be > 0
- Format must be DXGI_FORMAT_UNKNOWN
- The RAW flag must not be set
- Both of the resources must be buffers
- CounterOffsetInBytes must be a multiple of 4096
- CounterOffsetInBytes must be within the range of the counter
    resource
- pDesc cannot be NULL
- pResource cannot be NULL

If pCounterResource is not specified, then CounterOffsetInBytes must be
0.

If the RAW flag is set then

- Format must be DXGI_FORMAT_R32_TYPELESS

- The UAV resource must be a buffer.

if pCounterResource is not set, then CounterOffsetInBytes must be 0

If the RAW flag is not set and StructureByteStride = 0, then the format
must be a valid UAV format.

D3D12 removes the distinction between append and counter UAVs (although
the distinction still exists in HLSL bytecode).

The core runtime will validate these restrictions inside of:

SetComputeRootUnorderedAccessViewSingleUse,
SetGraphicsRootUnorderedAccessViewSingleUse, and
CreateUnorderedAccessView.

During Draw/Dispatch, the counter resource must be in the
D3D12_RESOURCE_USAGE_UNORDERED_ACCESS state. The debug layer will
issue errors when this is not the case.

The ID3D12CommandList::SetUnorderedAccessViewCounterValue and
ID3D12CommandList ::CopyStructureCount APIs are removed because
applications can simply copy data to/from the counter value directly.

Dynamic indexing of UAVs with counters is supported.

If a shader attempts to access the counter of a UAV that does not have
an associated counter, then the debug layer will issue a warning, and a
GPU page fault will occur, causing the application's device to be
removed.

Counter UAVS are supported in all heap types (default, upload,
readback).

Within a single Draw/Dispatch call, it is invalid for an application to
access the same 32-bit memory location via 2 separate UAV counters. The
debug layer will issue an error when this is detected.

---

## Queries

In D3D 12, queries are grouped into arrays of queries called a query
heap. A query heap has a type which defines the valid types of queries
that can be used with that heap.

```C++
typedef enum D3D12_QUERY_HEAP_TYPE
{
	D3D12_QUERY_HEAP_TYPE_OCCLUSION	= 0,
	D3D12_QUERY_HEAP_TYPE_TIMESTAMP	= 1,
	D3D12_QUERY_HEAP_TYPE_PIPELINE_STATISTICS	= 2,
	D3D12_QUERY_HEAP_TYPE_SO_STATISTICS	= 3,
	D3D12_QUERY_HEAP_TYPE_VIDEO_DECODE_STATISTICS	= 4,
	D3D12_QUERY_HEAP_TYPE_COPY_QUEUE_TIMESTAMP	= 5,
	D3D12_QUERY_HEAP_TYPE_PIPELINE_STATISTICS1	= 7
} D3D12_QUERY_HEAP_TYPE;

typedef struct D3D12_QUERY_HEAP_DESC
{
    D3D12_QUERY_HEAP_TYPE Type;
    UINT Count;
    UINT NodeMask;
} D3D12_QUERY_HEAP_DESC;

HRESULT ID3D12Device::CreateQueryHeap(
    _In_  const D3D12_QUERY_HEAP_DESC *pDesc,
    REFIID riid,
    _COM_Outptr_opt_ void **ppvHeap
);
```

Event queries are not present in D3D12; this functionally has been
subsumed by fences.

TIMESTAMP_DISJOINT queries are not present in D3D12. The GPU timestamp
clock is assumed to be stable such that 2 timestamp queries issued in
the same command list are comparable.

QUERY_SO_STATISTICS queries are not present in D3D12. Applications can
emulate this behavior by issuing multiple single-stream queries, and
then accumulating the results.

SO_STATISTICS_PREDICATE and OCCLUSION_PREDICATE queries are not
present in D3D12. They can be emulated by applications.

A new query type is added to the API.
D3D12_QUERY_TYPE_BINARY_OCCLUSION acts like
D3D12_QUERY_TYPE_OCCLUSION except that it returns a binary 0/1
result. 0 indicates that no samples passed depth and stencil testing. 1
indicates that at least 1 sample passed depth and stencil testing. This
is added to the API to enable occlusion queries to not interfere with
any GPU performance optimization associated with depth/stencil testing.
Hardware that does not support this query type natively can emulate it
via special processing in the ResolveQueryData API.

The core runtime will validate that the heap type is a valid member of
the heap_type enumeration, and that the count is greater than 0.

Each individual element within a query heap can be start/stopped
separately.

```C++
typedef enum D3D12_QUERY_TYPE
{
    D3D12_QUERY_TYPE_OCCLUSION,
    D3D12_QUERY_TYPE_BINARY_OCCLUSION,
    D3D12_QUERY_TYPE_TIMESTAMP,
    D3D12_QUERY_TYPE_PIPELINE_STATISTICS,
    D3D12_QUERY_TYPE_SO_STATISTICS_STREAM0,
    D3D12_QUERY_TYPE_SO_STATISTICS_STREAM1,
    D3D12_QUERY_TYPE_SO_STATISTICS_STREAM2,
    D3D12_QUERY_TYPE_SO_STATISTICS_STREAM3,
} D3D12_QUERY_TYPE;

void ID3D12CommandList::BeginQuery(
    ID3D12QueryHeap* Query,
    UINT ElementIndex,
    D3D12_QUERY_TYPE Type
);

void ID3D12CommandList::EndQuery(
    ID3D12QueryHeap* Query,
    UINT ElementIndex,
    D3D12_QUERY_TYPE Type
);
```

D3D12_QUERY_TYPE_TIMESTAMP is the only query that that supports
EndQuery only. All other query types require BeginQuery and EndQuery.

The debug layer will validate:

- It is illegal to begin a query twice without ending it (for a given
    element). For queries which require both begin and end, it is
    illegal to end a query before the corresponding begin (for a given
    element).

- The query type passed to BeginQuery must match the query type passed
    to EndQuery

The core runtime will validate the following:

- BeginQuery cannot be called on a timestamp query

- For the query types which support both BeginQuery and EndQuery (all
    except for timestamp), a query for a given element must not span
    command list boundaries.

- ElementIndex must be within range

- The query type is a valid member of the D3D12_QUERY enum

- The query type must be compatible with the query heap. The following
    table shows the query heap type required for each query type:

  Query Type|                                    Query Heap type
  -|-
  D3D12_QUERY_TYPE_OCCLUSION|                 D3D12_QUERY_HEAP_TYPE_OCCLUSION
  D3D12_QUERY_TYPE_BINARY_OCCLUSION|         D3D12_QUERY_HEAP_TYPE_OCCLUSION
  D3D12_QUERY_TYPE_TIMESTAMP|                 D3D12_QUERY_HEAP_TYPE_TIMESTAMP
  D3D12_QUERY_TYPE_PIPELINE_STATISTICS|      D3D12_QUERY_HEAP_TYPE_PIPELINE_STATISTICS
  D3D12_QUERY_TYPE_SO_STATISTICS_STREAM0|   D3D12_QUERY_HEAP_TYPE_SO_STATISTICS
  D3D12_QUERY_TYPE_SO_STATISTICS_STREAM1|   D3D12_QUERY_HEAP_TYPE_SO_STATISTICS
  D3D12_QUERY_TYPE_SO_STATISTICS_STREAM2|   D3D12_QUERY_HEAP_TYPE_SO_STATISTICS
  D3D12_QUERY_TYPE_SO_STATISTICS_STREAM3|   D3D12_QUERY_HEAP_TYPE_SO_STATISTICS

- The query type is supported by the command list type. The following
    table shows which queries are supported on which command list types.

  Query Type|                                    Support Command List Types
  -|-
  D3D12_QUERY_TYPE_OCCLUSION|                 Direct
  D3D12_QUERY_TYPE_BINARY_OCCLUSION|         Direct
  D3D12_QUERY_TYPE_TIMESTAMP|                 Direct/Compute
  D3D12_QUERY_TYPE_PIPELINE_STATISTICS|      Direct
  D3D12_QUERY_TYPE_SO_STATISTICS_STREAM0|   Direct
  D3D12_QUERY_TYPE_SO_STATISTICS_STREAM1|   Direct
  D3D12_QUERY_TYPE_SO_STATISTICS_STREAM2|   Direct
  D3D12_QUERY_TYPE_SO_STATISTICS_STREAM3|   Direct

---

## Timestamp Frequency

Applications can query the GPU timestamp clock frequency on a
per-command queue basis.

```C++
HRESULT ID3D12CommandQueue::GetTimestampFrequency(UINT64* pFrequency)
```

The returned frequency is measured in Hz (ticks/sec). This API fails
(E_FAIL) if the specified command queue does not support timestamps
(see the table in the previous section).

Timestamp frequencies do not change, even if other clock frequencies
on the GPU change.

## Clock Calibration

D3D12 enables applications to correlate results obtained from timestamp
queries with results obtained from calling QueryPerformanceCounter. This
is enabled by 2 API additions:

```C++
HRESULT ID3D12CommandQueue::GetClockCalibration(
  UINT64* pGpuClock,
  UINT64* pCpuClock
);
```

GetClockCalibration samples the GPU clock for a given command queue and
samples the CPU clock via QueryPerformanceCounter at nearly the same
time.

Note that this is implemented by asking the UMD to translate from
command queue to DXGKRNL context and then calling the (pre-existing)
kernel mode driver CalibrateGpuClock API.

This API fails (E_FAIL) if the specified command queue does not support
timestamps (see the table in the previous section).

Both GetTimestampFrequency and GetClockCalibration are implemented
without the involvement of the user-mode driver. D3D12 uses the first
context that the user-mode driver created on the given queue to
determine which GPU and engine to query. D3D12 then calls DXGKRNL, which
calls the kernel-mode driver to determine the timestamp frequency and
CPU/GPU calibration.

In order for the clock calibration to be useful the application must be
confident that the GPU timestamp clock will not stop ticking during idle
periods. This is enabled by a new API.

```C++
HRESULT ID3D12Device::SetStablePowerState(BOOL Enable)
```

This API is intended for development time use only. Therefore it is only
allowed when the D3D12 SDK layers are present on the machine. The API
fails with E_FAIL if the D3D12 SDK layers are not present.

The debug layer will issue a warning if the GetClockCalibration API is
used without SetStablePowerState being called first.

This API is implemented with new kernel-mode DDIs which are described
separately.

---

## ResolveQueryData

The only way to extract data from a query is to resolve the query data
from a proprietary format into the API-standard format.

```C++
void ID3D12CommandList::ResolveQueryData(
  ID3D12QueryHeap* QueryHeap,
  D3D12_QUERY_TYPE Type,
  UINT StartElement,
  UINT ElementCount,
  ID3D12Resource* DestinationBuffer,
  UINT64 AlignedDestinationBufferOffset
);
```

ResolveQueryData performs a batched operation which writes query data
into a destination buffer. Query data is written contiguously to the
destination buffer. AlignedDestinationBufferOffset must be a multiple of
8 bytes. The destination buffer must be in the
D3D12_RESOURCE_USAGE_COPY_DEST state. The size/format of the output
data matches the D3D11 API definitions. Binary occlusion queries write
64-bits per query. The least significant bit is either 0 or 1. The rest
of the bits are 0.

The core runtime will validate:

- StartElement and ElementCount are within range
- AlignedDestinationBufferOffset is a multiple of 8 bytes
- DestinationBuffer is a buffer
- The written data will not overflow the output buffer
- The query type must be supported by the command list type
- The query type must be supported by the query heap

The debug layer will issue a warning if the destination buffer is not in
the D3D12_RESOURCE_USAGE_COPY_DEST state.

ResolveQueryData works with all heap types (default, upload, readback).

Predication is decoupled from queries. Predication can be set based on
the value of 64-bits within a buffer.

```C++
typedef enum D3D12_PREDICATION_OP
{
    D3D12_PREDICATION_OP_EQUAL_ZERO, // Enable predication if all 64-bits are zero
    D3D12_PREDICATION_OP_NOT_EQUAL_ZERO, // Enable predication if at least one of the 64-bits are not zero
} D3D12_PREDICATION_OP;

void ID3D12CommandList::SetPredication(
  ID3D12Resource* Buffer,
  UINT64 AlignedBufferOffset,
  D3D12_PREDICATION_OP Operation
);
```

When the GPU executes a SetPredication command it snaps the value in the
buffer. Future changes to the data in the buffer do not retroactively
affect the predication state.

If Buffer is NULL, then predication is disabled

Predication hints are not present in the D3D12 API.

Predication is allowed on direct and compute command lists.

The core runtime will validate:

- AlignedBufferOffset is a multiple of 8 bytes

- The resource is a buffer

- The operation is a valid member of the enumeration

- SetPredication cannot be called from within a bundle

- The command list type supports predication

- The offset does not exceed the buffer size

The debug layer will issue an error if the source buffer is not in the
D3D12_RESOURCE_USAGE_DEFAULT_READ state.

The source buffer can be in any heap type (default, upload, readback).

The set of operations which can be predicated are:

- ID3D12CommandList::DrawInstanced

- ID3D12CommandList::DrawIndexedInstanced

- ID3D12CommandList::Dispatch

- ID3D12CommandList::CopySubresourceRegion

- ID3D12CommandList::CopyResource

- ID3D12CommandList::CopyTiles

- ID3D12CommandList::ResolveSubresource

- ID3D12CommandList::ClearDepthStencilView

- ID3D12CommandList::ClearRenderTargetView

- ID3D12CommandList::ClearUnorderedAccessViewUint

- ID3D12CommandList::ClearUnorderedAccessViewFloat

- ID3D12CommandList::ExecuteIndirect

ID3D12CommandList::ExecuteBundle is not predicated itself. Instead,
individual operations from the list above which are contained in side of
the bundle are predicated.

ID3D12CommandList::{ResolveQueryData,BeginQuery,EndQuery} are not
predicated.

---

# Test Plan

---

## Runtime Functional Tests

- Debug layer validation of Begin/EndQuery √

- InvalidBundleAPI validation √

- 11on12 UpdateSubresource to BufferFilledSize in SOSetTargets is not
    accidentally predicated √

- Stream-output validation BufferFilledSizeOffsetInBytes in
    ID3D12CommandList::SetStreamOutputBuffersSingleUse &
    ID3D12Device::CreateStreamOutputView √

- PSO creation fails if the AllowStreamOutput flag is not set in the
    root signature, but the GS does stream-output (for both the null GS
    and non-NULL GS cases) √

- The D3D12_ROOT_SIGNATURE_ALLOW_STREAM_OUTPUT flag can be
    specified in HLSL

- Debug layer warns if UAV counter resource is not in the UAV state

- Debug layer warning if a shader accesses a non-existent UAV counter

- Validation in SetComputeRootUnorderedAccessViewSingleUse,
    SetGraphicsRootUnorderedAccessViewSingleUse,
    CreateUnorderedAccessView √

- Validation in BeginQuery/EndQuery √

- Validation in CreateQuery √

- Validation in ResolveQueryData √

- Debug layer validation of destination buffer state for
    ResolveQueryData √

- Debug layer validation of buffer state in SetPredication √

- Runtime validation in SetPredication √

- 11on12 reports disjoint timestamps when a timestamp query spans 2
    command lists √

- GetTimestampFrequency fails for unsupported queue types √

- GetClockCalibration fails for unsupported queue types √

- SetStablePowerState is only allowed if the SDK layers are installed
    √

- A debug layer warning is issued if GetClockCalibration is used
    without setting stable clocks √

- Validation performed by CCreateUnorderedAccessViewValidator √

- New command list APIs behave correctly when a command list error is
    detected √

- 11on12 predication of CopyStructureCount, DrawAuto CS invocation,
    and copy to counter in UAV bind (cs and rtv) √

- 11on12 correctly handles queries that span command lists √

- 11on12 handling of stream-output queries (and predicates) which
    accumulate all 4 streams (predication & getdata) √

- Runtime puts command list into an error state if driver calls
    SetCommandListErrorCB in any of the new DDIs √

---

## Driver Conformance Tests

- Drivers support stream-output via both
    SetStreamOutputBuffersSingleUse & SetStreamOutputBuffers

- Drivers support root signatures with the AllowStreamOutput flag set,
    even though no stream out is done by the GS

- Stream-output works correctly with BufferFilledSize located at an
    arbitrary offset away from the stream-output data

- SetStreamOutputBuffers, GPU operation to write BufferFilledSize,
    ResourceBarrier(..->StreamOutput), Draw works correctly (if the
    driver needs it, it re-binds the SO buffers after the resource
    barrier to re-load the BufferFilledSize from memory).. similarly
    with resource barriers going the other way

- Stream output works in all heap types

- Drivers implement binary occlusion query correctly

- Drivers support multiple UAV counters associated with the same
    resource

- Dynamic indexing of UAV counters

- GPU page fault when a shader accesses a non-existing UAV counter

- Counter UAVs work with all heap types

- BINARY_OCCLUSION query type works correctly (including validating
    that all but the least significant bit are 0)

- Tiemstamp queries work on direct(3D) & compute command lists

- ResolveQueryData works with all heap types

- ResolveQueryData works for various sizes of heaps and ranges of
    queries to be resolved

- ResolveQueryData works on direct(3D) and compute command lists

- Predication set outside of a bundle

- SetPredication affects the correct set of command list operations

- Both predication operations work correctly (including various
    combinations of bits set)

- SetPredication works on compute and direct(3D) command lists

- SetPredication works with all resource heap types

- SetPredication snaps data from the source buffer

- ID3D12CommandQueue::GetTimestampFrequency returns reasonable results

- ID3D12CommandQueue::GetClockCalibration returns reasonable results

- If the STABLE_GPU_CLOCK flag is passed during device creation,
    then GetClockCalibration always returns incrementing GPU clock
    values.

- UAV Counters work with descriptor tables, root graphics views, and
    root compute views

- UAV counters can be created with arbitrary offsets

- MakeResident/Evict work for query heaps

- SetPredication(NULL) works correctly (with either operation type)

- The frequencies returned by GetTimestampFrequency are constant

- The correct context is used for getting timestamp
    frequencies/corellations

- Values returned by GetClockCalibration are reasonable

- Values returned by GetTimestampFrequency do not change

- GetClockCalibration (A), Issue Timestamp Queries,
    GetClockCalibration(B). Timestamps reported by queries are
    in-between GPU timestamps sampled at A and B

- GetClockCalibration (A), QPC, GetClockCalibration(B). QPC times are
    in between the CPU timestamps sampled at A and B

- Aliased UAV counters (multiple UAVs pointing that the same counter)
    work correctly.
