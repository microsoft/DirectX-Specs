<h1>D3D12 Background Processing - Spec</h1>

---

<h1>Contents</h1>

- [Background](#background)
- [Problem](#problem)
- [Solution](#solution)
- [Detailed Design](#detailed-design)
- [API](#api)
  - [Support Query](#support-query)
  - [Developer Mode](#developer-mode)
  - [Usage Scenarios](#usage-scenarios)
  - [App Control Over Task Dispatch](#app-control-over-task-dispatch)
- [DDI](#ddi)
  - [GPU Synchronization](#gpu-synchronization)
  - [Lifetime Management](#lifetime-management)
- [Tracing / Tooling](#tracing--tooling)

---

# Background

Direct3D 12 has succeeded in providing a reasonably deterministic, predictable API for developers to make use of. A significant part of that was putting threading and GPU synchronization control solely in developers' hands: calling an API generally results in "real", immediate processing on that particular thread, and when a function returns (e.g. ExecuteCommandLists), the operation has "really" completed.

This in contrast to D3D9/D3D11, where calling an API on the immediate context usually just (inexpensively) recorded a token, that would then be (at some opaque future point) picked up by a background thread under the runtime's/UMD's control, and actually processed/submitted to the GPU there. For the single-threaded D3D9/D3D11 models, this provided reasonable CPU throughput gains at some cost to efficiency/predictability.

There is another category of threading that IHVs found worthwhile to do in D3D9/D3D11 – background re-compilation/optimization of shaders. This work is distinguished from the previous-described D3D9/D3D11 threading in the following ways:

- The work is decoupled from particular API calls, and may happen indefinitely (or never) in the future.
- The work does not have any particular deadlines, as even minute-long compilation can pay off if the shader is useful for tens of minutes (can be common in gaming scenarios).
- The work is 'additional' work and not on the critical path, but crucially must not disrupt critical path work. 2-7% improvements in the average case is not worth even momentary stutter elsewhere.

Given these requirements, UMDs would spin up background threads and (generally) assign the threads as low a priority as possible, and rely on the NT scheduler to ensure these threads don't disrupt the critical-path threads, generally with success.

---

# Problem

There are three classes of problems with UMD-originated background processing:

(1) The nature of async background processing adds unpredictability/indeterminism to workloads, whether when benchmarking end-to-end scenarios, or when A/B testing minute changes in a workload.

- This covers in-engine profiling tools (maybe the first 10 seconds of a fly-through are missing the optimized shaders), or PIX (is PIX profiling with/without the optimized shaders?)
- Also affects CPU performance due to issue 1, particularly when benchmarking minute CPU changes.

(2) The threads, even when idle-priority, can impact the critical-path work (particularly on SMT systems, but on non-SMT systems as well).

(3) Drivers must keep the profiling 'light-weight', potentially limiting optimization scope, as they don't want to add stutter during an actual live game scenario.

---

# Solution

Solving the above problems will require three work items:

1. The right DDI design to allow UMDs to express desired threading behavior, and the right design for the runtime to control/monitor it (based partially on developer input).
2. Feature work from the NT Scheduler team to allow us to reduce the impact of these idle-priority threads on critical-path work.
3. API/DDI design to allow games to designate when: a) the current workload is representative/worth profiling, b) heavy/intrusive profiling is allowed [e.g. during a "detect settings" pass], and c) changes in response to profiling should be temporarily suspended to enable consistent A/B perf comparison.

---

# Detailed Design

The goals of this API/DDI are to:

- Increase awareness and control of background processing work in general, both for developers and for the platform/OS.
- Provide the right level of flexibility to ensure background processing isn't too rigid for UMD requirements.
- Have universal adoption by all D3D12 UMDs seeking to perform background threading.
- Allow applications to give 'permission' to UMDs to perform heavy-weight profiling/analysis, when the application knows it won't negatively affect user experience (i.e. during level load).
- Allow applications and profiling tools seeking more deterministic results to detect/wait for UMD processing to complete, such that it knows it is running with the more optimized set of shaders.

With those goals in mind we are proposing a model in which the runtime owns threads and allows the UMD to schedule work onto them, plus APIs allowing apps to adjust what amount of background processing is appropriate for their workloads and when to perform that work.

---

# API

```c
typedef enum D3D12_BACKGROUND_PROCESSING_MODE
{
    D3D12_BACKGROUND_PROCESSING_MODE_ALLOWED,
    D3D12_BACKGROUND_PROCESSING_MODE_ALLOW_INTRUSIVE_MEASUREMENTS,
    D3D12_BACKGROUND_PROCESSING_MODE_DISABLE_BACKGROUND_WORK,
    D3D12_BACKGROUND_PROCESSING_MODE_DISABLE_PROFILING_BY_SYSTEM,
} D3D12_BACKGROUND_PROCESSING_MODE;

typedef enum D3D12_MEASUREMENTS_ACTION
{
    D3D12_MEASUREMENTS_ACTION_KEEP_ALL,
    D3D12_MEASUREMENTS_ACTION_COMMIT_RESULTS,
    D3D12_MEASUREMENTS_ACTION_COMMIT_RESULTS_HIGH_PRIORITY,
    D3D12_MEASUREMENTS_ACTION_DISCARD_PREVIOUS,
} D3D12_MEASUREMENTS_ACTION;

HRESULT SetBackgroundProcessingMode(
            D3D12_BACKGROUND_PROCESSING_MODE Mode,
            D3D12_MEASUREMENTS_ACTION MeasurementsAction,
            HANDLE hEventToSignalUponCompletion,
            _Out_opt_ BOOL* FurtherMeasurementsDesired);
```

By default, the runtime will schedule at most two background compilation tasks at a time, running with idle priority so as to minimize the risk of this work introducing glitches into the foreground rendering.

Developers and profiling tools can adjust this behavior using combinations of the above enums.  The BACKGROUND_PROCESSING_MODE parameter indicates what level of dynamic profiling and shader recompilation is enabled:

**ALLOWED** is the default state, in which drivers may instrument workloads in any manner of their choosing, and may submit CPU tasks (typically PSO recompiles) to the D3D runtime for low priority execution.  The goal of this mode is to enable dynamic optimizations, but without impacting foreground rendering performance.

**ALLOW_INTRUSIVE_MEASUREMENTS** hints that the driver should prioritize richness and completeness of instrumentation over avoiding glitches, because the rendering currently taking place is being done specifically for training purposes and does not need to execute with usual smooth performance.  This kind of heavy-weight profiling will be used by analysis tools such as PIX.  It could also be used by benchmarks to warm the optimization state before taking their actual performance measurements, or directly by games at appropriate times (eg. pre-training the driver by rendering invisible content behind a menu).

**DISABLE_BACKGROUND_WORK** prevents the execution of background processing tasks.  When this flag is first turned on, all submitted tasks will be allowed to run to completion.  Any calls to QueueProcssingWorkCB while already in this state will result in the cancel callback being immediately invoked before returning.

Of course the UMD may choose to skip task submission entirely while in the disabled state, but if it does submit work, the runtime will cancel rather than just failing the submit operation, in order to avoid the UMD having to bother synchronizing between work submission and mode changes.

If the disable flag is turned on at the same time as specifying D3D12_MEASUREMENTS_ACTION_COMMIT_*, any new tasks that the UMD generates in response to the commit request will be allowed to execute before the disable takes effect.

The disable flag is only valid when developer mode is enabled.

**DISABLE_PROFILING_BY_SYSTEM** is a superset of the DISABLE_BACKGROUND_WORK mode, and requests a more complete disable of PGO.  In addition to suspending dynamic shader recompilation, this indicates that the driver should avoid making any behavioral changes that would perturb performance, such as dynamically tuning cache policies or compute dispatch patterns.  This is for use during profiling sessions, where an A/B comparison must provide stable timing results.

This flag is only valid when developer mode is enabled.

In addition to specifying a BACKGROUND_PROCESSING_MODE, which controls future PGO behavior, SetBackgroundProcessingMode takes a D3D12_MEASUREMENTS_ACTION enum describing what to do with the result of previous PGO measurements.  Options are:

**KEEP_ALL** does not request any specific change of behavior.  Previous results are still valid, and the driver may continue tracking whatever statistics are in the middle of being measured.

**COMMIT_RESULTS** hints that the workload seen so far represents the complete set of what is worth optimizing based on, for instance that a scene flythrough has finished in a benchmarking tool, or playback of the single frame being analyzed has completed in PIX. The UMD should kick off any desired background processing based on what it has seen so far, as no different work will be incoming in the near future.  After the UMD returns from a SetBackgroundProcessingMode call that specifies COMMIT_RESULTS, all currently queued background tasks will be considered part of the commit.  Once that set of tasks finishes executing, the provided hEventToSignalOnCompletion will be signaled. As indicated above, if this is combined with DISABLE_BACKGROUND_WORK, the disable state (i.e. the inability to submit more tasks) will take effect after returning from the SetBackgroundProcessingMode call.

If the UMD has been gathering statistics about eg. commonly used constant values, and is waiting for some threshold amount of data to be recorded before acting on this information, the commit flag should scale up whatever frequency histograms have been recorded so far to give the same result as if the normal act-now threshold had been reached after a longer period of data collection.  This is important to let PIX replay only one single frame capture, but then request a final set of optimized shaders matching that work, without having to waste time repeating a single frame many hundreds of times.

If the COMMIT_RESULTS or COMMIT_RESULTS_HIGH_PRIORITY modes are not used, hEventToSignalOnCompletion must be null.

**COMMIT_RESULTS_HIGH_PRIORITY** is a superset of the COMMIT_RESULTS mode which modifies the thread scheduling behavior.  This indicates that getting background compiles done fast is more important than avoiding glitches, so the D3D runtime will schedule more than one task simultaneously using multiple threads, and execute these at higher than idle priority.  This boost lasts until all tasks generated by the commit have finished executing.

The high priority mode is only valid when developer mode is enabled.

**DISCARD_PREVIOUS** hints to the UMD that the workload has changed in a significant way, so any results of previous measurements are no longer meaningful.

The **FurtherMeasurementsDesired** output value indicates whether the implementation has reached a steady state, or if it would like a chance to examine additional GPU work.  This is useful if, for instance, playback of a single frame in a tool such as PIX identifies opportunities for constant folding.  Once the resulting optimized shaders have been applied, further optimizations might be identified by profiling the workload again with that first round of optimization in place. This value will return false once the PGO implementation has reached a steady state, measuring a workload without identifying any further optimizations that can be made to it.  Analysis tools will typically replay a single frame inside a loop until this returns false, but should break out after some number of attempts in case the implementation never converges on a steady state.

---

## Support Query

Apps or tools that render explicitly for training purposes (e.g. using the ALLOW_INTRUSIVE_MEASUREMENTS mode) might want to skip that work if the driver isn't actually going to take advantage of it.  This can be queried using CheckFeatureSupport:

```c
typedef struct D3D12_FEATURE_DATA_D3D12_OPTIONS6
{
    [annotation("_Out_")] BOOL BackgroundProcessingSupported;
} D3D12_FEATURE_DATA_D3D12_OPTIONS6;
```

It is not necessary to check this capability before calling SetBackgroundProcessingMode.  Changing the mode on drivers that do not take advantage of the background processing feature is a benign no-op.

---

## Developer Mode

Use of DISABLE_BACKGROUND_WORK, DISABLE_PROFILING_BY_SYSTEM, and COMMIT_RESULTS_HIGH_PRIORITY is restricted to systems where developer mode is enabled.  This allows the use of these modes for developer profiling and by profiling tools, but prevents any games from shipping with these flags set (which could impair performance, thus creating undesirable incentives for drivers to work around this entire feature).

The ALLOW_INTRUSIVE_MEASUREMENTS, COMMIT_RESULTS, and DISCARD_PREVIOUS hints are allowed on retail systems as well as developer mode, because there is interest in the possibility of retail games using these to provide optimization hints.

---

## Usage Scenarios

We expect most games will leave background processing set to its default mode, which allows low-impact dynamic PGO.

If a developer just wants to turn this off (trading performance for determinism), they would call:

```c
SetBackgroundProcessingMode(
    D3D12_BACKGROUND_PROCESSING_MODE_DISABLE_BACKGROUND_WORK,
    D3D12_MEASUREMENTS_ACTION_KEEP_ALL,
    null, null);
```

Benchmark applications that wants to prime the optimization state before taking measurements, then execute any resulting compilations happening in the background, and leave possible further dynamic optimizations enabled, would use:

```c
SetBackgroundProcessingMode(
    D3D12_BACKGROUND_PROCESSING_MODE_ALLOW_INTRUSIVE_MEASUREMENTS,
    D3D_MEASUREMENTS_ACTION_KEEP_ALL,
    null, null);

RenderFlythroughOfScene();

SetBackgroundProcessingMode(
    D3D12_BACKGROUND_PROCESSING_MODE_ALLOWED,
    D3D12_MEASUREMENTS_ACTION_COMMIT_RESULTS,
    null, null);

RunTheRealBenchmark();
```

The workflow for PIX single frame analysis requires training the PGO state, then locking everything down before taking precise A/B measurements:

```c
BOOL wantMoreProfiling = true;
int tries = 0;

while (wantMoreProfiling && ++tries < MaxPassesInCaseDriverDoesntConverge)
{
    SetBackgroundProcessingMode(
        D3D12_BACKGROUND_PROCESSING_MODE_ALLOW_INTRUSIVE_MEASUREMENTS,
        D3D12_MEASUREMENTS_ACTION_DISCARD_PREVIOUS,
        null, null);

    PlayBackCapturedFrame();

    SetBackgroundProcessingMode(
        D3D12_BACKGROUND_PROCESSING_MODE_DISABLE_PROFILING_BY_SYSTEM,
        D3D12_MEASUREMENTS_ACTION_COMMIT_RESULTS_HIGH_PRIORITY,
        handle,
        &wantMoreProfiling);

    WaitForSingleObject(handle);
}

PlayBackFrameAgainDoingPixABComparisonStuffEtc();
```

---

## App Control Over Task Dispatch

A likely future extension would be to allow developers to control how background tasks are scheduled.  Games might wish to run this work on a specific CPU core, or to incorporate it into their own task management systems.

This could be added cleanly over the top of the current proposal, but is not necessary for a V1 of the feature.

---

# DDI

The runtime is responsible for managing threads (either directly, or possibly through a Thread Pool), and provides a callback for UMDs to register/queue work items.

```c
typedef HRESULT(APIENTRY CALLBACK *PFN_D3D12DDI_QUEUEPROCESSINGWORK_CB)(
        _In_ D3D12DDI_HRTDEVICE hRTDevice,

        // Called from thread where work is being performed.
        _In_ PFN_D3D12DDI_UMD_CALLBACK_METHOD pfnCallback,

        // Called if the device is destroyed before pfnCallback has executed.
        _In_ PFN_D3D12DDI_UMD_CALLBACK_METHOD pfnCancel,

        // Passed to pfnCallback or pfnCancel.
        _In_ void* pContext
);
```

The UMD will not have any control over which thread the work is processed on. Work will be processed in the order it was received. QueueProcessingWorkCb may be called from multiple threads concurrently/is thread safe (runtime will serialize).

If background tasks have been disabled by the application, the runtime will invoke the cancel callback (if provided) on the calling thread before returning back to the driver.

When an application changes background processing mode, the UMD is informed of the new settings via:

```c
typedef void (APIENTRY* PFND3D12DDI_SET_BACKGROUND_PROCESSING_MODE_0061)(
        _In_ D3D12DDI_HRTDEVICE hRTDevice,
        D3DDDI_BACKGROUND_PROCESSING_MODE Mode,
        D3DDDI_MEASUREMENTS_ACTION MeasurementsAction,
        _Out_ BOOL* pFurtherMeasurementsDesired
);
```

To report driver support for this feature, a new BOOL BackgroundProcessingSupported will be added to D3D12DDICAPS_TYPE_D3D12_OPTIONS.

Background processing work must only ever be used for optimization purposes.  These work items must not affect functional correctness of the implementation.

---

## GPU Synchronization

There is no synchronization between background processing mode changes and command queue work completion.  If an app (eg. PIX) wishes to change mode with completely deterministic behavior, they must drain all GPU queues and wait for idle before calling SetBackgroundProcessingMode.

We expect many callers (benchmarking tools, or game debug consoles used to commit PGO optimizations before the developer captures timing data) will let the driver record data over several seconds or even minutes, then change processing mode while GPU work is in flight.  Drivers must be robust against these settings changing at any time, but are not expected to make any PGO decisions in response to GPU work that has not yet finished executing.

---

## Lifetime Management

The runtime is responsible for cleaning up threads during device destruction. The runtime may, or may not, call any existing queued work.  If a queued work item is not completed (i.e. pfnCallback is skipped) then its pfnCancel method will be called instead.  Exactly one of pfnCallback or pfnCancel will always be called for each successfully queued work item.

A hard guarantee is that the runtime will let the UMD complete any in-progress work items (the runtime won't call TerminateThread on the thread), and will wait until all in-flight work items are completed before calling pfnDestroyDevice.

Expected usage is that each work item will compile a specialized variant of a shader program.  Once the compilation is done, the new shader will be added to the relevant PSO as an option that can be dynamically selected for GPU execution depending on what constant values are bound etc.  This introduces a lifespan management complexity, because D3D12 resource lifespans are directly controlled by the application, yet the application developer has no visibility into these background compilation tasks.  Driver implementations will need to handle the possibility that a PSO could be destroyed while a compilation is executing, while minimizing the amount of data that needs to be kept alive until the task completes.  For instance, it would be undesirable to switch the entire PSO to a reference counted deferred deletion scheme.

A suggested approach here is for the UMD PSO data to contain a shared_ptr (or moral equivalent thereof) to a small object which contains a non-owning pointer back to the PSO.  The regular PSO destruction path nulls out this backpointer within the shared object.  When a background compilation is queued, it takes a reference on the shared object (but not the main PSO).  Upon completion of the compilation, it checks the shared object to see if the PSO is still alive, and either abandons the compilation result or transfers it back to the PSO accordingly.

---

# Tracing / Tooling

The D3D runtime will emit ETW events at the start and finish of each background task execution.  This will allow GPUView and PIX to clearly display when this work is taking place.
