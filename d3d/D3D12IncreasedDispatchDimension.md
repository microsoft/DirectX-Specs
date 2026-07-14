# D3D12 Increased 1D Dispatch Dimensions <!-- omit in toc -->

This document specifies a new D3D12 feature that relaxes the maximum 1D dispatch size for compute shaders, allowing hardware to expose larger X-dimension dispatch capabilities beyond the traditional 65,535 thread group limit.

Version 1.1

---

## Contents <!-- omit in toc -->

- [Introduction](#introduction)
- [Problem Statement](#problem-statement)
- [Goals](#goals)
- [Non-Goals](#non-goals)
- [Overall Design](#overall-design)
- [API](#api)
  - [D3D12\_FEATURE](#d3d12_feature)
  - [D3D12\_FEATURE\_DATA\_D3D12\_OPTIONS25](#d3d12_feature_data_d3d12_options25)
  - [Capability Query](#capability-query)
- [Runtime Behavior](#runtime-behavior)
  - [Dispatch Validation](#dispatch-validation)
  - [Backwards Compatibility](#backwards-compatibility)
- [DDI](#ddi)
  - [DDI Capability Structure](#ddi-capability-structure)
  - [Driver Requirements](#driver-requirements)
- [Test Plan](#test-plan)
  - [Conformance Tests](#conformance-tests)
- [Change Log](#change-log)

---

## Introduction

Modern GPU architectures can support significantly larger dispatch dimensions than the D3D12 specification's current maximum of 65,535 thread groups per dimension (as defined by `D3D12_CS_DISPATCH_MAX_THREAD_GROUPS_PER_DIMENSION`). This limitation constrains workloads that would benefit from expressing large 1D parallelism directly, forcing developers to implement workarounds using multi-dimensional dispatches or multiple dispatch calls.

This feature allows hardware to expose increased maximum dispatch dimensions specifically for 1D dispatches, where the X dimension can exceed the traditional limit while Y and Z dimensions remain 1. Separate limits are provided for Compute Shader dispatches and Mesh Shader dispatches.


---

## Overall Design

The Increased 1D Dispatch Dimensions feature introduces a device capability query that returns the maximum supported X dimension for 1D dispatches. Key design principles:

1. **Capability Query**: Applications query `Max1DDispatchSize` and `Max1DDispatchMeshSize` to determine the maximum X dimension supported by the device
2. **1D Dispatch Restriction**: The increased limit applies only when Y = 1 and Z = 1
3. **Guaranteed Minimum**: All devices must support at least the original limit of 65,535
4. **Validation**: Runtime validates that dispatches exceeding 65,535 in X have Y = 1 and Z = 1
5. **Compatibility**: Existing dispatches within traditional limits work unchanged

---

## API

### D3D12_FEATURE

Add new feature enumeration value for querying increased dispatch dimensions:

```cpp
typedef enum D3D12_FEATURE
{
    // ... existing values ...
    D3D12_FEATURE_D3D12_OPTIONS25 = 68,
} D3D12_FEATURE;
```

### D3D12_FEATURE_DATA_D3D12_OPTIONS25

New feature data structure containing the maximum 1D dispatch dimension:

```cpp
typedef struct D3D12_FEATURE_DATA_D3D12_OPTIONS25
{
    UINT Max1DDispatchSize;
    UINT Max1DDispatchMeshSize;
} D3D12_FEATURE_DATA_D3D12_OPTIONS25;
```

**Members:**

- **Max1DDispatchSize** - The maximum number of thread groups that can be dispatched in the X dimension for Compute Shaders when Y = 1 and Z = 1. Must be at least 65,535 (the value of `D3D12_CS_DISPATCH_MAX_THREAD_GROUPS_PER_DIMENSION`). This limit also applies to grids launched in Work Graphs, however Work Graphs are additionally constrained by the maximum total number of thread groups as defined by `D3D12_WORK_GRAPHS_DISPATCH_MAX_THREAD_GROUPS_PER_GRID` (16,777,215). This means that while `Max1DDispatchSize` may be larger than 16,777,215, Work Graph dispatches cannot exceed this total thread group limit.

- **Max1DDispatchMeshSize** - The maximum number of thread groups that can be dispatched in the X dimension for Mesh Shaders (via `DispatchMesh`) when Y = 1 and Z = 1. Must be at least 65,535 (the value of `D3D12_CS_DISPATCH_MAX_THREAD_GROUPS_PER_DIMENSION`). This value must not exceed 4,194,303 (the value of `D3D12_MS_DISPATCH_MAX_THREAD_GROUPS_PER_GRID`), which is the maximum total number of thread groups allowed for Mesh Shader dispatches.

### Capability Query

Applications query for the maximum 1D dispatch size using the standard `CheckFeatureSupport` API:

```cpp
D3D12_FEATURE_DATA_D3D12_OPTIONS25 options = {};
HRESULT hr = device->CheckFeatureSupport(
    D3D12_FEATURE_D3D12_OPTIONS25,
    &options,
    sizeof(options));

if (SUCCEEDED(hr))
{
    printf("Maximum 1D dispatch size (Compute): %u thread groups\n", 
           options.Max1DDispatchSize);
    printf("Maximum 1D dispatch size (Mesh): %u thread groups\n", 
           options.Max1DDispatchMeshSize);
    
    if (options.Max1DDispatchSize > D3D12_CS_DISPATCH_MAX_THREAD_GROUPS_PER_DIMENSION)
    {
        // Device supports increased 1D dispatch dimensions for Compute
    }
    if (options.Max1DDispatchMeshSize > D3D12_CS_DISPATCH_MAX_THREAD_GROUPS_PER_DIMENSION)
    {
        // Device supports increased 1D dispatch dimensions for Mesh
    }
}
```

**Guaranteed Minimum:**

All D3D12 devices must report:
- `Max1DDispatchSize >= 65535` (D3D12_CS_DISPATCH_MAX_THREAD_GROUPS_PER_DIMENSION)
- `Max1DDispatchMeshSize >= 65535` (D3D12_CS_DISPATCH_MAX_THREAD_GROUPS_PER_DIMENSION)

**Maximum Constraints:**
- `Max1DDispatchMeshSize <= 4194303` (D3D12_MS_DISPATCH_MAX_THREAD_GROUPS_PER_GRID)
- For Work Graphs: Total thread groups <= 16777215 (D3D12_WORK_GRAPHS_DISPATCH_MAX_THREAD_GROUPS_PER_GRID), even if `Max1DDispatchSize` is larger
---

## Runtime Behavior

### Dispatch Validation

The D3D12 debug layer performs the following checks for compute dispatches (see the **Runtime enforcement** note below for how violations are handled):

**For Direct Compute Dispatches (`Dispatch`) and Dispatch Graph (CPU_INPUT):**
- If `ThreadGroupCountX > D3D12_CS_DISPATCH_MAX_THREAD_GROUPS_PER_DIMENSION` (65,535):
  - Validate that `ThreadGroupCountY == 1`
  - Validate that `ThreadGroupCountZ == 1`
  - Validate that `ThreadGroupCountX <= Max1DDispatchSize`
  - If is Dispatch Graph, validate that `ThreadGroupCountX <= D3D12_WORK_GRAPHS_DISPATCH_MAX_THREAD_GROUPS_PER_GRID (16,777,215)`
  - If any of these conditions is not met, the debug layer issues an **error**; the dispatch is **not** dropped and is still passed to the driver unchanged
- If `ThreadGroupCountX <= 65535`:
  - Apply standard validation (all dimensions must be <= 65,535)

**For Mesh Shader Dispatches (`DispatchMesh`):**
- If `ThreadGroupCountX > D3D12_CS_DISPATCH_MAX_THREAD_GROUPS_PER_DIMENSION` (65,535):
  - Validate that `ThreadGroupCountY == 1`
  - Validate that `ThreadGroupCountZ == 1`
  - Validate that `ThreadGroupCountX <= Max1DDispatchMeshSize`
  - Validate that `ThreadGroupCountX <= D3D12_MS_DISPATCH_MAX_THREAD_GROUPS_PER_GRID (4,194,303)`
  - If any of these conditions is not met, the debug layer issues an **error**; the dispatch is **not** dropped and is still passed to the driver unchanged
- If `ThreadGroupCountX <= 65535`:
  - Apply standard validation (all dimensions must be <= 65,535)

### Runtime enforcement

The runtime does not drop, clamp, or otherwise modify an oversized dispatch. When the conditions above are not met, the debug layer reports an **error**, but the dispatch is still passed to the driver unchanged — issuing a debug-layer error does not, by itself, alter runtime behaviour. This is intentional: dropping the dispatch would be a compatibility risk for existing applications.

In addition, when a command list is recorded through the runtime-bypass path, the debug layer validation above does not run at all, so no error is produced and the driver receives the dispatch regardless. Drivers must therefore not rely on the runtime to reject dispatches that exceed the reported `Max1DDispatchSize` / `Max1DDispatchMeshSize` — validating and correctly handling such dispatches is the driver's responsibility.

### Backwards Compatibility

When queried on an existing driver which doesn't support OPTIONS25 the D3D runtime will automatically return 65535 for both `Max1DDispatchSize` and `Max1DDispatchMeshSize` as defined by `D3D12_CS_DISPATCH_MAX_THREAD_GROUPS_PER_DIMENSION`

---

## DDI

### DDI Capability Structure

The DDI exposes the new capability field to drivers:

```cpp
typedef struct D3D12DDI_D3D12_OPTIONS_DATA_0XXX
{
    // ... existing fields ...
    
    UINT Max1DDispatchSize;
    UINT Max1DDispatchMeshSize;
} D3D12DDI_D3D12_OPTIONS_DATA_0XXX;
```

### Driver Requirements

**Capability Reporting:**
- Reported values must be at least 65,535 (D3D12_CS_DISPATCH_MAX_THREAD_GROUPS_PER_DIMENSION)
- `Max1DDispatchMeshSize` must not exceed 4,194,303 (D3D12_MS_DISPATCH_MAX_THREAD_GROUPS_PER_GRID)
- Drivers may report different values for Compute and Mesh dispatches based on hardware capabilities

**Dispatch Handling:**
- Drivers must correctly handle Compute dispatches with X dimension up to the reported `Max1DDispatchSize`
- Drivers must correctly handle Mesh dispatches with X dimension up to the reported `Max1DDispatchMeshSize`
- When X > 65,535, drivers can assume Y = 1 and Z = 1 (validated by runtime)

---

## Test Plan

### Conformance Tests

1. **Capability Query:**
   - Verify minimum values are met (>= 65,535 for both fields)
   - Validate fallback behavior for devices not supporting OPTIONS25

2. **Compute Dispatch Validation (Also Work Graphs with CPU Node Input):**
   - Successful dispatch with X = 65,535, Y = 1, Z = 1 (baseline)
   - Successful dispatch with X = Max1DDispatchSize, Y = 1, Z = 1 (if supported)
   - The following each produce a debug-layer error (the dispatch is still executed, not dropped):
     - X > 65,535, Y > 1, Z = 1
     - X > 65,535, Y = 1, Z > 1
     - X > Max1DDispatchSize, Y = 1, Z = 1
     - (Work Graphs) X > D3D12_WORK_GRAPHS_DISPATCH_MAX_THREAD_GROUPS_PER_GRID, if Max1DDispatchSize greater

3. **Mesh Dispatch Validation:**
   - Successful DispatchMesh with X = 65,535, Y = 1, Z = 1 (baseline)
   - Successful DispatchMesh with X = Max1DDispatchMeshSize, Y = 1, Z = 1 (if supported)
   - The following each produce a debug-layer error (the dispatch is still executed, not dropped):
     - X > 65,535, Y > 1, Z = 1
     - X > 65,535, Y = 1, Z > 1
     - X > Max1DDispatchMeshSize, Y = 1, Z = 1

5. **Indirect Dispatch:**
   - Valid indirect dispatch arguments with extended X dimension for Compute
   - Valid indirect dispatch arguments with extended X dimension for Mesh
   - Invalid indirect dispatch arguments with Y or Z > 1 for both dispatch types
   - Multiple indirect dispatches with varying dimensions
---

## Change Log

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | November 2025 | Initial specification for increased 1D dispatch dimensions |
| 1.1 | July 2026 | Clarified runtime enforcement: oversized 1D dispatches produce a debug-layer error but are still passed to the driver unchanged (not dropped); noted that the runtime-bypass path skips this validation entirely |
