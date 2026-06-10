# D3D12: Debug Break <!-- omit in toc -->
v0.04 13 May 2026

# Contents <!-- omit in toc -->

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
  - [D3D12DDI\_FEATURE\_DATA\_DEBUG\_BREAK](#d3d12ddi_feature_data_debug_break)
- [Postmortem Debugging with DebugBreak()](#postmortem-debugging-with-debugbreak)
- [Open Questions](#open-questions)
- [WARP Support](#warp-support)
- [Test Plan](#test-plan)
    - [Test App](#test-app)
    - [Functional test](#functional-test)
    - [Driver Conformance test](#driver-conformance-test)
- [Spec History](#spec-history)

---
# Terms and Acronyms

| **Term/Acronym** | **Definition**                                                                                     |
|------------------|----------------------------------------------------------------------------------------------------|
| **TDR**          | Timeout Detection and Recovery, a Windows feature that resets the GPU if it takes too long to respond, preventing system unresponsiveness. |
| **ISV**          | Independent Software Vendor, a developer using D3D12 for their application.                       |
| **IHV**          | Independent Hardware Vendor, a GPU manufacturer.                                                  |
| **Dxgkrnl**      | Port driver in the WDDM driver model, OS component written by Microsoft.                          |
| **KMD**          | Kernel Mode Driver, an IHV-supplied miniport driver in the WDDM driver model.                     |
| **Backend/Driver Compiler**          | IHV-supplied compiler responsible for compiling IL into hardware specific ISA.                     |
| **Registered Live Debugger** | A live GPU debugger that has been registered with the OS for the current process (e.g. PIX live debugger). This explicitly does not include postmortem debugging tools such as the DX Dump Files feature, or driver-internal monitoring/exception handlers, none of which are considered live debuggers for the purposes of `DebugBreak()` behavior. |

# Summary

This proposal introduces new pipeline state object and state object flags to control the behavior of the proposed [HLSL `DebugBreak()`](https://github.com/microsoft/hlsl-specs/blob/main/proposals/0039-debugbreak.md) intrinsic in shaders. The flags will enable the following three scenarios:

1. Default behavior; registered live debugger will be notified if a `DebugBreak()` is encountered or the instruction will be ignored if no live debugger is registered. The decision to notify the live debugger or ignore the `DebugBreak()` will be made at instruction execution time, not at backend compilation time. See [Terms and Acronyms](#terms-and-acronyms) for what qualifies as a registered live debugger.
2. Always halt on `DebugBreak()` such that regardless of if any live debugger is registered, shader execution will halt and dxgkrnl will be notified either by the KMD via interrupt, or dxgkrnl's TDR mechanism will trigger and a crash dump will be generated.
3. Force all `DebugBreak()` calls to no-ops such that regardless of if any live debugger is attached, all debug breaks are backend compiled into no-ops.

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

This works well for the new [live debugging workflow](D3D12GpuDumps.md) where if a live debugger is attached and a shader hits a `DebugBreak()` instruction, a new shader debugging session can be started.

To support retail scenarios where a live debugger may not exist, this proposal introduces new pipeline state object and state object flags to control the behavior of `DebugBreak()` functions in shaders. Game developers can compile their HLSL shaders with debug breaks into DXIL bytecode, and depending on the debug break behavior, the backend compiler will compile the DXIL debug break operation into an instruction that invokes a different handler depending on whether or not a live debugger was registered for the process or remove the instruction entirely. In normal user scenarios, the game may choose to disable all `DebugBreak()` functions to reduce the performance overhead of executing the conditional checks. If a shader issue arises that is difficult to reproduce locally, but users are encountering in the wild, the game can enable halt on `DebugBreak()` functionality for shaders in a specific state object for a small proportion of users to generate postmortem crash dumps for offline debugging.

# Proposed API

## Pipeline State Flags
```c++
typedef enum D3D12_PIPELINE_STATE_FLAGS {
    ...
    D3D12_PIPELINE_STATE_FLAG_DEBUG_BREAK_ALWAYS_HALT = 0x20,
    D3D12_PIPELINE_STATE_FLAG_DEBUG_BREAK_FORCE_NOP   = 0x40,
} D3D12_PIPELINE_STATE_FLAGS;
```

## State Object Flags
```c++
typedef enum D3D12_STATE_OBJECT_FLAGS
{
    ...
    D3D12_STATE_OBJECT_FLAG_DEBUG_BREAK_ALWAYS_HALT = 0x200,
    D3D12_STATE_OBJECT_FLAG_DEBUG_BREAK_FORCE_NOP   = 0x400,
} D3D12_STATE_OBJECT_FLAGS;

typedef struct D3D12_STATE_OBJECT_CONFIG
{
    D3D12_STATE_OBJECT_FLAGS Flags;
} D3D12_STATE_OBJECT_CONFIG;
```

Flag                           | Definition
---------                      | ----------
`*_DEBUG_BREAK_ALWAYS_HALT`  | If enabled, the backend compiler will promote all `DebugBreak()` functions in the set of shaders in the pipeline state object or state object to halt shader execution regardless of if a live debugger is registered or not when the `DebugBreak()` is hit. It is only available if the IHV driver/compiler supports Shader Model 6.10.
`*_DEBUG_BREAK_FORCE_NOP`  | If enabled, the backend compiler will compile all `DebugBreak()` functions in the set of shaders in the pipeline state object or state object to no-ops. This flag is only available if the IHV driver/compiler supports Shader Model 6.10.

---

`*_DEBUG_BREAK_ALWAYS_HALT` and `*_DEBUG_BREAK_FORCE_NOP` cannot be specified at the same time. If neither `*_DEBUG_BREAK_ALWAYS_HALT` nor `*_DEBUG_BREAK_FORCE_NOP` are specified, the default behavior applies: if a [registered live debugger](#terms-and-acronyms) is attached when a `DebugBreak()` is hit, the registered live debugger will be notified; otherwise the `DebugBreak()` is ignored. The backend compiler should not compile `DebugBreak()` functions to no-ops at compilation time, that decision should be made at shader execution time so that a live debugger can be attached or detached at any point prior to hitting the `DebugBreak()`. Note that only *live* GPU debugger registered through `ID3D12Tools3::RegisterLiveGpuDebugger` participate in this default behavior — postmortem tools (e.g. DX Dump Files) and driver-internal monitoring do not cause `DebugBreak()` to break in under the default behavior.

Compute and graphics pipeline state objects created via `CreateGraphicsPipelineState`, `CreateComputePipelineState`, and `CreatePipelineState` will support the new `D3D12_PIPELINE_STATE_FLAGS` enums.

For state objects such as RTPSOs, collections, or executables with programs like work graphs or generic programs (with one modification stated further below): If the [state object config](https://microsoft.github.io/DirectX-Specs/d3d/Raytracing.html#d3d12_state_object_config) subobject is not present, the default debug break behavior will apply. If the state object config subobject is present, all exports in the state object must be associated with the same subobject (or one with a matching definition). This consistency requirement for the `*_DEBUG_BREAK_ALWAYS_HALT` and `*_DEBUG_BREAK_FORCE_NOP` flags also applies across existing collections that are included in a larger state object.

Generic programs and pre-rasterization shaders and pixel shader partial programs will first use the debug break flags defined in the `D3D12_STATE_SUBOBJECT_TYPE_FLAGS` subobject if specified. Otherwise, the default behavior for state objects mentioned above applies.

When [Advanced Shader Delivery](ShaderCompilerPlugin.md) is used, if either of the debug break flags are enabled, the driver/backend compiler will need to just-in-time compile the set of shaders in a pipeline state object or state object, or the shaders must be offline compiled with the matching debug break flag enabled.

## D3D12_FEATURE_DEBUG_BREAK
A new `D3D12_FEATURE` enum value will be added to represent which debug break capabilities the driver supports.

```c++
typedef struct D3D12_FEATURE_DATA_DEBUG_BREAK
{
    [annotation("_Out_")] BOOL HaltSupported; // Enabled if the driver supports halting shader execution on the GPU when a DebugBreak() is hit and `*_DEBUG_BREAK_ALWAYS_HALT` is enabled
    [annotation("_Out_")] BOOL LiveDebuggingSupported; // Enabled if the driver supports notifying registered live debugger when a DebugBreak() is hit when *_DEBUG_BREAK_ALWAYS_HALT or default behavior is enabled
    [annotation("_Out_")] BOOL CpuSupported; // Enabled if the driver supports triggering a CPU debug break when a DebugBreak() is hit (eg. WARP).
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
    D3D12DDI_PIPELINE_STATE_FLAG_DEBUG_BREAK_ALWAYS_HALT = 0x20,
    D3D12DDI_PIPELINE_STATE_FLAG_DEBUG_BREAK_FORCE_NOP   = 0x40,
} D3D12DDI_PIPELINE_STATE_FLAGS;
```

## D3D12DDI_STATE_OBJECT_FLAGS
```c++
typedef enum D3D12DDI_STATE_OBJECT_FLAGS
{
    ...
    D3D12DDI_STATE_OBJECT_FLAG_DEBUG_BREAK_ALWAYS_HALT = 0x200,
    D3D12DDI_STATE_OBJECT_FLAG_DEBUG_BREAK_FORCE_NOP   = 0x400,
} D3D12DDI_STATE_OBJECT_FLAGS;
```

## D3D12DDI_FEATURE_DATA_DEBUG_BREAK
```c++
typedef struct D3D12DDI_FEATURE_DATA_DEBUG_BREAK
{
    BOOL HaltSupported; // Enabled if the driver supports halting shader execution on the GPU when a DebugBreak() is hit and `*_DEBUG_BREAK_ALWAYS_HALT` is enabled
    BOOL LiveDebuggingSupported; // Enabled if the driver supports notifying registered live debugger when a DebugBreak() is hit when *_DEBUG_BREAK_ALWAYS_HALT or default behavior is enabled
    BOOL CpuSupported; // Enabled if the driver supports triggering a CPU debug break when a DebugBreak() is hit (eg. WARP)
} D3D12DDI_FEATURE_DATA_DEBUG_BREAK;
```

# Postmortem Debugging with DebugBreak()

If `D3D12_PIPELINE_STATE_FLAG_DEBUG_BREAK_ALWAYS_HALT/D3D12_STATE_OBJECT_FLAG_DEBUG_BREAK_ALWAYS_HALT` is enabled, a `DebugBreak()` function is hit in a shader in the pipeline state object or state object, and no live debugger is registered for the process, shader execution will halt and dxgkrnl will detect an engine timeout after the machine's [TdrDelay](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/tdr-registry-keys#tdrdelay) registry setting, and call the new `pfnCollectProcessDebugBlob` DDI to collect application specific GPU debug blob and generate a crash dump in the same workflow as a [normal timeout](D3D12GpuDumps.md#system-workflow). Note that postmortem tools such as the DX Dump Files feature being enabled does not change this behavior — they are not live debuggers and therefore do not suppress the halt.

If `*_DEBUG_BREAK_FORCE_NOP` is enabled, all `DebugBreak()` functions in the shaders in the state object will be ignored and no crash dumps will be generated.

# Open Questions

1. [dxgkrnl/IHVs] Do we need to wait for dxgkrnl to detect a timeout for the postmortem debugging with promoted `DebugBreak()` calls? Can the IHV KMDs recognize that shader execution has been halted because of a promoted `DebugBreak()` and call the new `DXGK_INTERRUPT_TYPE` to notify dxgkrnl before the TDR delay? Can the new `DXGK_INTERRUPT_TYPE` interrupt be modified so that if a live debugger is not registered, dxgkrnl will proceed with the normal timeout workflow? 
2. [IHVs] For the promoted debug break with a registered live debugger, can IHVs support single stepping past the promoted debug break instruction without aborting?

# WARP Support
WARP's `DebugBreak()` behavior depends on whether it's using BasicRender or SoftGPU. If BasicRender is used and `D3D12_FEATURE_DATA_DEBUG_BREAK.CpuSupported` is enabled, a `DebugBreak()` will trigger a CPU debug break and not a GPU TDR and the debugger check will use `IsDebuggerPresent()` instead of checking for if a GPU debugger is attached. No DX dump file will be generated with BasicRender. If SoftGPU is used and `D3D12_FEATURE_DATA_DEBUG_BREAK.LiveDebuggingSupported` is enabled, the debugger check will check for if a GPU debugger is attached and will notify dxgkrnl about the debug break. If `D3D12_FEATURE_DATA_DEBUG_BREAK.HaltSupported` is enabled with SoftGPU, `*_DEBUG_BREAK_ALWAYS_HALT` is set, and no debugger is attached, a `DebugBreak()` will generate a DX dump file.

# Test Plan

### Test App
A test D3D application will be added that includes shaders that use the new `DebugBreak()` intrinsic.

### Functional test
Functional tests will be written using the TAEF framework.

The important behaviors to test are: 
- DirectX Dump File Creation
  - Verify that promoted `DebugBreak()`s trigger a dump file to be generated
  - Verify that disabling or default `DebugBreak()`s do not trigger a dump file to be generated

### Driver Conformance test
The HLK driver conformance suite for this feature (`D3DConf_12_DebugBreak.cpp`) exercises the new debug break flags on both compute pipeline state objects and state objects. The suite validates that:

- `CheckFeatureSupport(D3D12_FEATURE_DEBUG_BREAK)` succeeds and reports capability bits (`HaltSupported`, `LiveDebuggingSupported`, `CpuSupported`) consistent with the driver's actual behavior. Tests skip cleanly when the relevant capability, Shader Model 6.10, or DirectX Dump File support is unavailable.
- `*_DEBUG_BREAK_FORCE_NOP` causes the driver/backend compiler to compile `DebugBreak()` to a no-op so shader execution continues past the break and produces the expected UAV side effect.
- `*_DEBUG_BREAK_ALWAYS_HALT` halts shader execution at `DebugBreak()` when no live debugger is registered, leading to device removal and a GPU crash dump being produced through the DirectX Dump File callbacks with a valid dump file path.
- Default behavior (neither flag set) with no live debugger registered skips `DebugBreak()` at instruction execution time and lets the shader complete normally.
- For state objects, flags supplied via `D3D12_STATE_OBJECT_CONFIG`, per-program flag subobjects (which must override state-object-level flags), and `COLLECTION` → `EXECUTABLE` composition all honor the debug break flags consistently and enforce the cross-collection consistency requirement.

# Spec History

| Version | Date | Details | Author |
|-|-|-|-|
| v0.04 | 13 May 2026 | Rename `*_HALT_ON_DEBUG_BREAK`/`*_DISABLE_DEBUG_BREAK` to `*_DEBUG_BREAK_ALWAYS_HALT`/`*_DEBUG_BREAK_FORCE_NOP`; clarify definition of "registered live debugger"; describe HLK driver conformance suite | Henchhing Limbu (PIX) |
| v0.03 | 15 Jan 2026 | Add caps bits | Grace Zhang (PIX) | 
| v0.02 | 06 Jan 2026 | Change default and add WARP behavior | Grace Zhang (PIX) | 
| v0.01 | 05 Nov 2025 | Initial draft spec | Grace Zhang (PIX) | 