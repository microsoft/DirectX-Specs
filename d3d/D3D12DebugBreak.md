# D3D12: Debug Break
v0.01 12 Mar 2026

# Contents
- [D3D12: Debug Break](#d3d12-debug-break)
- [Contents](#contents)
  - [Terms and Acronyms](#terms-and-acronyms)
- [Summary](#summary)
- [Motivation](#motivation)
- [Proposed API](#proposed-api)
  - [Pipeline State Flags](#pipeline-state-flags)
  - [State Object Flags](#state-object-flags)
  - [D3D12\_FEATURE\_DEBUG\_BREAK](#d3d12_feature_debug_break)
- [Proposed DDI](#proposed-ddi)
  - [D3D12DDI\_PIPELINE\_STATE\_FLAGS](#d3d12ddi_pipeline_state_flags)
  - [D3D12DDI\_STATE\_OBJECT\_FLAGS](#d3d12ddi_state_object_flags)
- [Postmortem Debugging with DebugBreak()](#postmortem-debugging-with-debugbreak)
- [Open Questions](#open-questions)
- [Test Plan](#test-plan)
    - [Test App](#test-app)
    - [Functional test](#functional-test)
    - [Driver Conformance test](#driver-conformance-test)
- [Spec History](#spec-history)

---
## Terms and Acronyms

| **Term/Acronym** | **Definition**                                                                                     |
|------------------|----------------------------------------------------------------------------------------------------|
| **TDR**          | Timeout Detection and Recovery, a Windows feature that resets the GPU if it takes too long to respond, preventing system unresponsiveness. |
| **ISV**          | Independent Software Vendor, a developer using D3D12 for their application.                       |
| **IHV**          | Independent Hardware Vendor, a GPU manufacturer.                                                  |
| **Dxgkrnl**      | Port driver in the WDDM driver model, OS component written by Microsoft.                          |
| **KMD**          | Kernel Mode Driver, an IHV-supplied miniport driver in the WDDM driver model.                     |
| **Backend/Driver Compiler**          | IHV-supplied compiler responsible for compiling IL into hardware specific ISA.                     |

# Summary

This proposal introduces new pipeline state object and state object flags to control the behavior of the proposed [HLSL `DebugBreak()`](https://github.com/microsoft/hlsl-specs/blob/main/proposals/0039-debugbreak.md) intrinsic in shaders. The flags will enable the following three scenarios:

1. Default behavior; registered debuggers will be notified if a `DebugBreak()` is encountered or the instruction will be ignored if no debugger is registered. The decision to notify the debugger or ignore the `DebugBreak()` will be made at instruction execution time, not at backend compilation time.
2. Halt on `DebugBreak()` such that regardless of if any debuggers are registered, shader execution will halt and dxgkrnl will be notified either by the KMD via interrupt, or dxgkrnl's TDR mechanism will trigger and a crash dump will be generated.
3. Disable all `DebugBreak()` calls such that regardless of if any debuggers are attached, all debug breaks are backend compiled into no-ops.

By adding a way to control `DebugBreak()` behavior per pipeline state object or state object, HLSL shaders can be compiled with `DebugBreak()` into DXIL bytecode once, then enabled or disabled at PSO creation time without developers needing to re-run frontend compilation to generate new DXIL bytecode.

# Motivation
As shaders become more complex, it becomes increasingly challenging to debug rare shader issues. Some games may ship with a minimal number of shader asserts that check for issues that would lead to catastrophic failures or corruptions if execution continued, and generate a crash dump for offline debugging if the assertion fails. However, there isn't a reliable way to trigger a GPU crash from a shader to generate a crash dump. The most common approach that game developers use today is to enter an infinite loop, however this is reliant on the TDR mechanism triggering, which may not trigger if the user's machine has modified TDR registry settings, and the compiler/driver crashing reliably.

To support debugging these shader issues, the HLSL team has a [proposal](https://github.com/microsoft/hlsl-specs/blob/main/proposals/0039-debugbreak.md) for a new `DebugBreak()` intrinsic that can be used to conditionally break-in like so:

```hlsl
[numthreads(8,1,1)]
void main(uint GI : SV_GroupIndex) {
    ... 
    // Manual breakpoint for debugging specific conditions
    if (someRareCondition) {
        DebugBreak();
    }
}
```

This should works well for [live shader debugging](D3D12GpuDumps.md) where if a shader debugger is attached and a shader hits a `DebugBreak()` instruction, a new shader debugging session can be started.

To support retail scenarios where a live shader debugger may not exist, this proposal introduces new pipeline state object and state object flags to control the behavior of `DebugBreak()` functions in shaders. Game developers can compile their HLSL shaders with debug breaks into DXIL bytecode, and depending on the debug break behavior, the backend compiler will compile the DXIL debug break operation into an instruction that invokes a different handler depending on whether or not a shader debugger was registered for the process or remove the instruction entirely. In normal user scenarios, the game may choose to disable all `DebugBreak()` functions to reduce the performance overhead of executing the conditional checks. If a shader issue arises that is difficult to reproduce locally, but users are encountering in the wild, the game can enable halt on `DebugBreak()` functionality for shaders in a specific state object for a small proportion of users to generate DirectX dump files for offline debugging.

# Proposed API

## Pipeline State Flags
```c++
typedef enum D3D12_PIPELINE_STATE_FLAGS {
    ...
    D3D12_PIPELINE_STATE_FLAG_HALT_ON_DEBUG_BREAK = 0x20,
    D3D12_PIPELINE_STATE_FLAG_DISABLE_DEBUG_BREAK = 0x40,
} D3D12_PIPELINE_STATE_FLAGS;
```

## State Object Flags
```c++
typedef enum D3D12_STATE_OBJECT_FLAGS
{
    ...
    D3D12_STATE_OBJECT_FLAG_HALT_ON_DEBUG_BREAK = 0x200,
    D3D12_STATE_OBJECT_FLAG_DISABLE_DEBUG_BREAK = 0x400,
} D3D12_STATE_OBJECT_FLAGS;

typedef struct D3D12_STATE_OBJECT_CONFIG
{
    D3D12_STATE_OBJECT_FLAGS Flags;
} D3D12_STATE_OBJECT_CONFIG;
```

Flag                           | Definition
---------                      | ----------
`*_HALT_ON_DEBUG_BREAK`  | If enabled, the backend compiler will promote all `DebugBreak()` functions in the set of shaders in the pipeline state object or state object to halt shader execution regardless of if a debugger is attached or not when the `DebugBreak()` is hit. It is only available if the IHV driver/compiler supports Shader Model 6.10.
`*_DISABLE_DEBUG_BREAK`  | If enabled, the backend compiler will compile all `DebugBreak()` functions in the set of shaders in the pipeline state object or state object to no-ops. This flag is only available if the IHV driver/compiler supports Shader Model 6.10.

---

`*_HALT_ON_DEBUG_BREAK` and `*_DISABLE_DEBUG_BREAK` cannot be specified at the same time. If neither `*_HALT_ON_DEBUG_BREAK` nor `*_DISABLE_DEBUG_BREAK` are specified, the default behavior is that if a debugger is registered and a `DebugBreak()` is hit, the registered shader debugger will be notified. The backend compiler should not compile `DebugBreak()` functions to no-ops at compilation time, that decision should be made at shader execution time so that a debugger can be attached or detached at any point prior to hitting the `DebugBreak()`

Compute and graphics pipeline state objects created via `CreateGraphicsPipelineState`, `CreateComputePipelineState`, and `CreatePipelineState` will support the new `D3D12_PIPELINE_STATE_FLAGS` enums.

For state objects such as RTPSOs, collections, or executables with programs like work graphs or generic programs (with one modification stated further below): If the [state object config](https://microsoft.github.io/DirectX-Specs/d3d/Raytracing.html#d3d12_state_object_config) subobject is not present, the default debug break behavior will apply. If the state object config subobject is present, all exports in the state object must be associated with the same subobject (or one with a matching definition). This consistency requirement for the `*_HALT_ON_DEBUG_BREAK` and `*_DISABLE_DEBUG_BREAK` flags also applies across existing collections that are included in a larger state object.

Generic programs and pre-rasterization shaders and pixel shader partial programs will first use the debug break flags defined in the `D3D12_STATE_SUBOBJECT_TYPE_FLAGS` subobject if specified. Otherwise, the default behavior for state objects mentioned above applies.

When [Advanced Shader Delivery](ShaderCompilerPlugin.md) is used, if either of the debug break flags are enabled, the driver/backend compiler will need to just-in-time compile the set of shaders in a pipeline state object or state object, or the shaders must be offline compiled with the matching debug break flag enabled.

## D3D12_FEATURE_DEBUG_BREAK
A new `D3D12_FEATURE` enum value will be added to represent which debug break capabilities the driver supports.

```c++
typedef struct D3D12_FEATURE_DATA_DEBUG_BREAK
{
    [annotation("_Out_")] BOOL HaltSupported; // Enabled if the driver supports halting shader execution on the GPU when a DebugBreak() is hit and `*_HALT_ON_DEBUG_BREAK` is enabled
    [annotation("_Out_")] BOOL LiveDebuggingSupported; // Enabled if the driver supports notifying registered GPU debuggers when a DebugBreak() is hit when *_HALT_ON_DEBUG_BREAK or default behavior is enabled
    [annotation("_Out_")] BOOL CpuSupported; // Enabled if the driver supports triggering a CPU debug break when a DebugBreak() is hit.
} D3D12_FEATURE_DATA_DEBUG_BREAK;

typedef enum D3D12_FEATURE
{
    D3D12_FEATURE_D3D12_OPTIONS =  0,
    D3D12_FEATURE_ARCHITECTURE  =  1, // Deprecated by D3D12_FEATURE_ARCHITECTURE1
    ...
    D3D12_FEATURE_DEBUG_BREAK    = 72,
```

If neither `HaltSupported` nor `LiveDebuggingSupported` are enabled for the GPU driver, the driver doesn't support generating postmortem hang dumps or live debugging on `DebugBreak()` and all `DebugBreak()` functions will be disabled.

# Proposed DDI

## D3D12DDI_PIPELINE_STATE_FLAGS
```c++
typedef enum D3D12DDI_PIPELINE_STATE_FLAGS
{
    ...
    D3D12DDI_PIPELINE_STATE_FLAG_HALT_ON_DEBUG_BREAK = 0x20,
    D3D12DDI_PIPELINE_STATE_FLAG_DISABLE_DEBUG_BREAK = 0x40,
} D3D12DDI_PIPELINE_STATE_FLAGS;
```

## D3D12DDI_STATE_OBJECT_FLAGS
```c++
typedef enum D3D12DDI_STATE_OBJECT_FLAGS
{
    ...
    D3D12DDI_STATE_OBJECT_FLAG_HALT_ON_DEBUG_BREAK = 0x200,
    D3D12DDI_STATE_OBJECT_FLAG_DISABLE_DEBUG_BREAK = 0x400,
} D3D12DDI_STATE_OBJECT_FLAGS;
```

# Postmortem Debugging with DebugBreak()

If `D3D12_PIPELINE_STATE_FLAG_HALT_ON_DEBUG_BREAK/D3D12_STATE_OBJECT_FLAG_HALT_ON_DEBUG_BREAK` is enabled, a `DebugBreak()` function is hit in a shader in the pipeline state object or state object, and no shader debuggers are registered for the process, shader execution will halt and dxgkrnl will detect an engine timeout after the machine's [TdrDelay](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/tdr-registry-keys#tdrdelay) registry setting, and call the new `pfnCollectProcessDebugBlob` DDI to collect application specific GPU debug blob and generate a crash dump in the same workflow as a [normal timeout](D3D12GpuDumps.md#system-workflow).

If `*_DISABLE_DEBUG_BREAK` is enabled, all `DebugBreak()` functions in the shaders in the state object will be ignored and no crash dumps will be generated.

# Open Questions

1. [dxgkrnl/IHVs] Do we need to wait for dxgkrnl to detect a timeout for the postmortem debugging with promoted `DebugBreak()` calls? Can the IHV KMDs recognize that shader execution has been halted because of a promoted `DebugBreak()` and call the new `DXGK_INTERRUPT_TYPE` to notify dxgkrnl before the TDR delay? Can the new `DXGK_INTERRUPT_TYPE` interrupt be modified so that if a debugger is not registered, dxgkrnl will proceed with the normal timeout workflow? 
2. [IHVs] For the promoted debug break with a registered debugger, can IHVs support single stepping past the promoted debug break instruction without aborting?

# Test Plan

### Test App
A test D3D application will be added that includes shaders that use the new `DebugBreak()` intrinsic.

### Functional test
Functional tests will be written using the TAEF framework.

The important behaviors to test are: 
- Postmortem Crash Dump Creation
  - Verify that promoted `DebugBreak()`s trigger a dump file to be generated
  - Verify that disabling or default `DebugBreak()`s do not trigger a dump file to be generated

- Live Debugging
  - Verify that default and promoted `DebugBreak()`s trigger the debugger to be notified of a potential live debugging session and we can continue shader debugging without aborting
  - Verify that disabling `DebugBreak()`s do not trigger the debugger to be notified

### Driver Conformance test
Verify drivers work correctly with the new pipeline state object and state object flags (TBD need to get familiar with existing driver tests)

_TODO: Update test plan with more details_

# Spec History

| Version | Date | Details | Author |
|-|-|-|-|
| v0.01 | 12 Mar 2026 | Initial draft spec | Grace Zhang (PIX) | 