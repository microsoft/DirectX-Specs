# D3D12 WriteBufferImmediate Hardware Spec <!-- omit in toc -->

## Contents <!-- omit in toc -->

- [1. Introduction](#1-introduction)
- [2. Hardware Requirements](#2-hardware-requirements)
- [3. D3D12 DDI's](#3-d3d12-ddis)
  - [3.1 PFND3D12DDI_WRITEBUFFERIMMEDIATE](#31-pfnd3d12ddiwritebufferimmediate)
    - [Parameters](#parameters)
    - [Remarks](#remarks)
  - [3.2 D3D12DDI_WRITEBUFFERIMMEDIATE_PARAMETER](#32-d3d12ddiwritebufferimmediateparameter)
    - [Members](#members)
  - [3.3 D3D12DDI_WRITEBUFFERIMMEDIATE_MODE](#33-d3d12ddiwritebufferimmediatemode)
- [4. HLK Testing](#4-hlk-testing)
  - [4.1 Basic WriteBufferImmediate Test](#41-basic-writebufferimmediate-test)
  - [4.2 WriteBufferImmediate Marker Mode Test](#42-writebufferimmediate-marker-mode-test)
  - [4.3 WriteBufferImmediate TDR Scenario Test](#43-writebufferimmediate-tdr-scenario-test)
- [5. Special Design Considerations](#5-special-design-considerations)
  - [5.1 Tile-based deferred renderers](#51-tile-based-deferred-renderers)
  - [5.2 Implicit Multi-Context](#52-implicit-multi-context)

## 1. Introduction

Analysis of GPU faults can be very difficult with existing tools, especially post-mortem investigation of device-removal on end-user systems. Unlike system crashes which can produce detailed debugging

information such as system heap dumps can call stacks, GPU faults occur on the GPU timeline and there is little actionable information provided to developers. There is some driver-specific data provided via OCA/Watson when a GPU fault occurs, however this data presently seems to be of little value.

Ideally, a GPU fault would be handled in Windows by gathering data describing the fault reason (e.g. non-resident-write), the pipeline stage where the fault occurred, and the location of the fault in the command stream, traceable back to a specific D3D12 command list and command queue invocation. Such data would be visible to application developers for debugging. The data could even be captured and reported to MS and IHV partners via OCA.

One step in this direction involves the use of markers in the command stream used as GPU-timeline markers written to system memory as the GPU processes commands. These markers indicate which commands are currently in the GPU pipeline at the time a fault occurs.

The GPU-timeline marker value writes are implemented using a new PFND3D12DDI_WRITEBUFFERIMMEDIATE DDI. This DDI works in much the same way as a CopyBufferRegion except that the source data is taken directly from the command stream rather than from another buffer. There are also several modes that affect the timing of the write operation:

* MARKER_IN – The write only occurs only after all previous command have begun execution on the GPU. The Write operation cannot be reordered ahead of any previous commands. Later commands can be reordered ahead of the MARKER_IN Write operations.
* MARKER_OUT – The write only occurs after ALL previous commands have completed on the GPU (not including cache flushes or global visibility of data). The Write operation cannot be reordered ahead of any previous commands though later commands can be reordered ahead of the Write operation.
* DEFAULT – Scheduled the same as a CopyBufferRegion. No additional ordering restrictions.

## 2. Hardware Requirements

Immediate write operations use 4-byte aligned GPU virtual addresses to designate write destinations.

Immediate writes are not intended to force cache flushing and are not expected to introduce significant performance losses. Drivers should avoid stalling the GPU pipeline, regardless of write mode.

To reduce DDI overhead the WRITEBUFFERIMMEDIATE DDI is a batching DDI, taking multiple value/destination pairs.

GPU schedulers must not move WRITEBUFFERIMMEDIATE operations using MARKER_IN or MARKER_OUT ahead of previous commands. However, subsequent commands can be moved ahead of these WRITEBUFFERIMMEDIATE operations. This may help tile-based deferred renderers with batching commands in tiles.

Immediate writes require destination buffers to be in the D3D12DDI_RESOURCE_STATE_COPY_DEST state.

Immediate writes can be optionally supported on video command queues. All other command queues must support WriteBufferImmediate. Immediate writes must be supported on both direct and bundle command lists.

## 3. D3D12 DDI's

### 3.1 PFND3D12DDI_WRITEBUFFERIMMEDIATE

DDI for directly copying 32-bit values to a specified buffer location without the need for a source resource.

``` c++
typedef VOID ( APIENTRY* PFND3D12DDI_WRITEBUFFERIMMEDIATE )(
    D3D12DDI_HCOMMANDLIST,
    UINT Count,
    _In_reads_(Count) CONST D3D12DDI_WRITEBUFFERIMMEDIATE_PARAMETER *pParams,
    _In_reads_opt_(Count) CONST D3D12DDI_WRITEBUFFERIMMEDIATE_MODE *pModes
    );
```

#### Parameters

*Count* – Number of elements in array pointed to by pDescs and by optional parameter pModes.

*pParams* – Pointer to array of Count D3D12DDI_WRITEBUFFERIMMEDIATE_PARAMETER elements

*pModes* – Optional pointer to array of Count D3D12DDI_WRITEBUFFERIMMEDIATE_MODE elements

#### Remarks

For each element in pParams, where Count is the number of elements, the immediate 32-bit integer value Value is written to buffer location Dst.

Parameter pModes points to an array of copy modes of length Count (or NULL). If this parameter is NULL then all copies use the DEFAULT mode. D3D12DDI_WRITEBUFFERIMMEDIATE_MODE_DEFAULT indicates the immediate write behaves similarly to a normal CopyBufferRegion operation.

The WRITEBUFFERIMMEDIATE DDI must be supported on all command list types, including video, bundle, and copy command lists.

Resources must be in the D3D12DDI_RESOURCE_STATE_COPY_DEST state to be a destination for WriteBufferImmediate.

### 3.2 D3D12DDI_WRITEBUFFERIMMEDIATE_PARAMETER

```c++
typedef struct D3D12DDI_WRITEBUFFERIMMEDIATE_PARAMETER
{
    D3D12_GPU_VIRTUAL_ADDRESS Dst;
    UINT32 Value;
} D3D12DDI_WRITEBUFFERIMMEDIATE_PARAMETER;
```

#### Members

*Dst* – Location *Value* is written to

*Value* – 32-bit value to write

### 3.3 D3D12DDI_WRITEBUFFERIMMEDIATE_MODE

```c++
typedef enum D3D12DDI_WRITEBUFFERIMMEDIATE_MODE
{
    D3D12DDI_WRITEBUFFERIMMEDIATE_MODE_DEFAULT = 0x0,
    D3D12DDI_WRITEBUFFERIMMEDIATE_MODE_MARKER_IN = 0x1,
    D3D12DDI_WRITEBUFFERIMMEDIATE_MODE_MARKER_OUT = 0x2,
} D3D12DDI_WRITEBUFFERIMMEDIATE_MODE;
```

*D3D12DDI_WRITEBUFFERIMMEDIATE_MODE_DEFAULT*  
The write operation behaves the same as normal copy write operations.

*D3D12DDI_WRITEBUFFERIMMEDIATE_MODE_MARKER_IN*  
The write operation is guaranteed to occur after any preceding commands in the stream have started, including previous WRITEBUFFERIMMEDIATE operations.

*D3D12DDI_WRITEBUFFERIMMEDIATE_MODE_MARKER_OUT*  
The write operation is deferred until ALL previous commands in the stream have completed execution in the GPU pipeline, including previous WRITEBUFFERIMMEDIATE MARKER_IN operations. However, the MARKER_OUT write operation may occur before any other caches are flushed meaning data from previous commands is not guaranteed to be globally visible. MARKER_OUT copies do NOT block subsequent operations from starting execution. If there are no previous operations in the stream the operation behaves like a MARKER_IN copy.

MARKER_OUT Operations can be reordered in the command stream after subsequent operations except other MARKER_OUT WRITEBUFFERIMMEDIATE operations.

## 4. HLK Testing

### 4.1 Basic WriteBufferImmediate Test

Verifies that WriteBufferImmediate is supported in each command list type and each mode. Verifies that immediate values are written to expected target locations. Verifies that MARKER mode values are written in-order.

This test verifies that multiple marker writes with different VA destinations are supported.

This test verifies that bundles are supported.

This test verifies that multiple simultaneous buffers are supported across a single WriteBufferImmediate invocation.

### 4.2 WriteBufferImmediate Marker Mode Test

Attempts to verify that commands preceding MARKER_IN writes are completed before marker values are written using high-performance timestamps. Likewise, timestamps are used to determine that MARKER_OUT writes are delayed until after all preceding commands are completed.

The test runs repeated executions of varying command list recordings with multiple WriteBufferImmediate calls injected between Draw and Dispatch calls of varying cost. CPU-accessible buffers used for WriteBufferImmediate output. The test uses an independent thread polls the values written to the output buffer and validates that all writes occur in order. The test also validates that coincident MARKER_IN and MARKER_OUT operations do not result in the MARKER_OUT write occurring before MARKER_IN writes.

### 4.3 WriteBufferImmediate TDR Scenario Test

Executes shaders with varying possible GPU fault conditions, including infinite loops, writes to discarded resources, and dereferencing uninitialized root descriptors. If a GPU fault is triggered, the test verifies that MARKER_OUT writes recorded after the timeout Draw/Dispatch are not executed and that MARKER_IN writes are consistent with the location of the fault. It is known that different hardware handles some of these conditions without faulting. Test cases will pass if no fault is triggered.

TDRWatch needs to be disabled as this test is expected to cause TDR’s.

## 5. Special Design Considerations

### 5.1 Tile-based deferred renderers

Tile-based renderers may repeatedly run commands or ranges of commands on multiple tiles, potentially resulting in “later” commands being completed on one tile while “earlier” commands are started on the next tile. If a GPU-fault occurs during this period, coinciding MARKER_IN and MARKER_OUT writes may appear to be written out-of-sequence. To address this TBDR drivers can keep the marker writes in sync by reporting marker writes as they complete on a given tile. If a GPU fault occurs, the marker writes must reflect the status of the commands being executed for the faulting tile. If no fault occurs, then the last executed tile markers are expected to be written.

### 5.2 Implicit Multi-Context

There are cases (such as implicit LDA) where command lists distribute some operations across multiple GPU’s concurrently. Like TBDR, the marker writes must reflect the status of the commands being executed for the faulting context. If no fault occurs, then the order of WriteBufferImmediate writes is undetermined until completion of ExecuteCommandLists.
