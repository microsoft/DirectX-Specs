# Command-list state initialization

This chapter defines initial/reset state and bundle entry/exit state for `DIRECT`, `COMPUTE`, `COPY`, and `BUNDLE` recordings through `ID3D12GraphicsCommandList10` and its base graphics command-list interfaces. The state-family index identifies each definition.

<a id="recording-boundaries"></a>

## Recording boundaries

The initial values in this reference apply when `CreateCommandList` or a successful `Reset` begins a recording. `CreateCommandList1` creates an initially closed object; its first recording begins with `Reset`. A new direct/compute recording does not inherit the previous recording's bindings. A bundle instead combines its explicitly recorded state with the permitted incoming state of the direct list that executes it.

These are command-list binding and recording-context rules, not resource-data initialization. They do not clear descriptor heap contents, buffers, textures, counter/query data, acceleration structures, or work-graph backing memory. Resetting a list object does not reclaim allocator storage or establish GPU completion; see [recorded commands and allocator storage](execution.md#command-storage).

The base VIDEO_ENCODE [ClearState, Close and Reset](video-motion-estimation.md#motion-recording) contracts are defined separately from the graphics/compute state families below. Encode ClearState/Reset disable predication and, on protection-capable nodes, clear the protected-session binding; they do not erase motion-vector heap contents or complete earlier GPU work.

The six Video [extension initialization/execution methods](video-extension-commands.md#extension-recording) retain extension-defined predication and state/sequencing contracts. They do not inherit Meta-command's initialization policy or establish a generic dirty-state mask or automatic ClearState rule.

<a id="state-index"></a>

## State-family index

| State family | Canonical definition |
|---|---|
| PSO, raytracing pipeline, generic program, work-graph selection | [Pipeline state and program selection](#pipeline-selection) |
| Root signatures, arguments, descriptor heaps and tables | [Resource binding](#resource-binding) |
| Vertex/index buffers and stream-output bindings | [Input and output bindings](#buffer-bindings) |
| RTV/DSV bindings and render-pass outputs | [Output bindings](#output-bindings), [render-pass context](#render-pass) |
| Primitive topology, viewport/scissor, blend factor and stencil references | [Base graphics state](#base-graphics) |
| Independent front/back stencil references | [Stencil references](#stencil-references) |
| Depth bounds | [Depth-bounds range](#depth-bounds) |
| Programmable sample positions | [Sample positions](#sample-positions) |
| View-instance mask | [View-instance mask](#view-mask) |
| VRS rate, combiners and image | [Variable-rate shading](#shading-rate) |
| Dynamic depth bias and index-buffer strip cut | [Dynamic PSO-derived state](#dynamic-state) |
| Predication and active queries | [Predication/query context](#queries) |
| Protected-resource session selection | [Protection context](#protection) |
| Render-pass recording context | [Render passes](#render-pass) |
| Marker/event context | [Annotations](#annotations) |
| Indirect and meta-command state effects | [Indirect execution](#indirect), [meta commands](#meta-commands) |

<a id="support"></a>

## Support and applicability

An available command-list interface does not by itself advertise optional hardware support. [Devices and capabilities](devices-and-capabilities.md#feature-discovery) defines the shared interface, feature-level and capability-query distinctions. The relevant `CheckFeatureSupport` members are listed below; members named OPTIONSn belong to `D3D12_FEATURE_DATA_D3D12_OPTIONSn`. A supported tier/TRUE result and the applicable PSO flags describe availability of the optional functionality. This table is not an extra validation rule for no-op calls or a substitute for each method's usage constraints. Listing an initial value does not advertise support.

| Contribution | Support member |
|---|---|
| Depth bounds | `OPTIONS2.DepthBoundsTestSupported` |
| Programmable sample positions | `OPTIONS2.ProgrammableSamplePositionsTier` |
| View instancing/masking | `OPTIONS3.ViewInstancingTier` |
| Raytracing pipeline selection | `OPTIONS5.RaytracingTier` |
| Variable-rate shading | `OPTIONS6.VariableShadingRateTier`; image binding requires Tier 2 |
| Independent front/back stencil references | `OPTIONS14.IndependentFrontAndBackStencilRefMaskSupported` |
| Dynamic strip cut | `OPTIONS15.DynamicIndexBufferStripCutSupported` and the dynamic PSO flag |
| Dynamic depth bias | `OPTIONS16.DynamicDepthBiasSupported` and the dynamic PSO flag |
| Work graphs | `OPTIONS21.WorkGraphsTier` appropriate to the program |
| Generic programs | `D3D12_FEATURE_DATA_SHADER_MODEL.HighestShaderModel` at SM 6.8 or higher; see [generic-program availability](state-objects.md#generic-programs) |
| Directly indexed descriptor heaps | `D3D12_FEATURE_DATA_D3D12_OPTIONS.ResourceBindingTier` at Tier 3 and `D3D12_FEATURE_DATA_SHADER_MODEL.HighestShaderModel` at SM 6.6 or higher |
| Protected-resource session | `D3D12_FEATURE_DATA_PROTECTED_RESOURCE_SESSION_SUPPORT.Support` for the relevant `NodeIndex` |

Meta-command availability is established by enumerating/creating a supported meta command, not by assuming a vendor-specific identifier exists on all devices.

<a id="pipeline-selection"></a>

## Pipeline state and program selection

**Related APIs:** `ID3D12GraphicsCommandList10::SetProgram`, `ID3D12GraphicsCommandList4::SetPipelineState1`, `ID3D12GraphicsCommandList::SetPipelineState`.

On a direct, compute, or bundle command list that uses graphics or compute pipeline state, `pInitialState` in `CreateCommandList` or `Reset` supplies the initial pipeline state object (PSO). If it is `NULL`, the runtime selects its default graphics state for direct lists and bundles, or its default compute state for compute lists. This default does not supply an application shader program; the application must establish the pipeline state required by a draw or dispatch. Copy command lists have no pipeline state and do not use `pInitialState`. Ordinary graphics/compute PSO descriptions and creation are defined in [Pipeline state and shader linkage](pipeline-state.md#ordinary-pipeline-state).

Pipeline/program selection is one logical selection, not independent additive bindings for `SetPipelineState`, `SetPipelineState1`, and `SetProgram`. Starting a recording with the supplied/default PSO does not retain a previously selected raytracing pipeline or work graph. Select the required pipeline/program before issuing the corresponding draw, dispatch, ray dispatch, or graph dispatch.

PSO-contained fields have the values of the selected object; `Reset` changes the selection, not the PSO's description.

For a bundle, pipeline state is not inherited from the parent. State selected or changed by the bundle affects the parent afterward.

All pipeline state objects referenced by a bundle must have the same number of render targets, corresponding render-target formats, depth-stencil format, and sample count/quality descriptions.

<a id="set-pipeline-state1"></a>

### ID3D12GraphicsCommandList4::SetPipelineState1

[SetPipelineState1](state-objects.md#setpipelinestate1) defines selection of a raytracing pipeline state object. Its effect on the single logical pipeline selection, initial/reset state and bundle postconditions remains defined above.

<a id="set-program"></a>

### ID3D12GraphicsCommandList10::SetProgram

[SetProgram](state-objects.md#setprogram) defines program selection, typed descriptions and work-graph list restrictions. The selected program participates in the single logical pipeline selection defined above.

<a id="work-graph-memory"></a>

### Work-graph backing memory

Rebinding a work graph after list `Reset` is not itself a request to reinitialize its backing allocation. `D3D12_SET_WORK_GRAPH_FLAG_INITIALIZE` concerns the allocation's contents and previous use, not whether the command-list object has been reset. The [initialization flag's requirements](state-objects.md#d3d12_set_work_graph_flags) include synchronization with previous uses of that memory. `DispatchGraph`, like work-graph program selection, is not supported in bundles.

<a id="resource-binding"></a>

## Resource binding

<a id="initial-bindings"></a>

### Initial bindings

Direct and compute recordings begin with no shader-visible descriptor heaps selected and no established root arguments. Undefined initial root/table state is not a promise of zero constants, null root descriptors, or valid null tables. Establish the signature and arguments required by the work. Root-signature definitions and descriptor/data lifetime promises are specified in [Resource binding and root signatures](binding.md#root-signatures).

At the beginning of a command list, the root signature is undefined.

Graphics shaders have a separate root signature from the compute shader
each independently assigned on a command list.

The root signature set on a command list or bundle must also match the
currently set Pipeline State at Draw/Dispatch otherwise behavior is
undefined. Transient root signature mismatches before Draw/Dispatch are
fine -- such as setting an incompatible Pipeline State before switching
to a compatible root signature (as long as these are compatible by the
time Draw/Dispatch is called).

<a id="binding-changes"></a>

### Binding changes

Setting a Pipeline State does not change the root signature. The
application must call a dedicated API for setting the root signature.

If a root signature is changed on a command list, all previous root
arguments become stale and all newly expected arguments must be set
before Draw/Dispatch otherwise behavior is undefined. If the root
signature is redundantly set to the same one currently set, existing
root signature bindings do not become stale.

Once a descriptor heap is set on a command list, subsequent calls that
define descriptor tables refer to the current descriptor heap.
Descriptor table state is undefined at the beginning of a command list
and after descriptor heaps are changed on a command list. Redundantly
setting the same descriptor heap does not cause descriptor table
settings to be undefined.

<a id="bundle-bindings"></a>

### Bundle bindings

Bundles inherit the command list's root arguments. If a bundle needs to
change some of the inherited root arguments it must first set the root
signature to be the same as the calling command list (the inherited
bindings do not become stale). If the bundle sets the root signature to
be different than the calling command list, that has the same effect as
changing the root signature on the command list described above: all
previous root arguments are stale and newly expected arguments must be
set before Draw/Dispatch, otherwise behavior is undefined. If a bundle
does not need to change any root arguments it does not need to bother
setting the root signature.

In a bundle, by contrast, the descriptor heaps can only be set at most
once (redundant calls setting the same heap are ok) otherwise behavior
is undefined. The descriptor heaps that are set must match the state
when any command list calls the bundle otherwise behavior is undefined.
This allows bundles to inherit and edit the command list's descriptor
table settings.

Bundle inheritance does not waive [static-descriptor](#static-descriptors) or [static-data](#static-data) binding requirements, or the [directly indexed heap ordering constraint](#direct-heaps).

<a id="static-descriptors"></a>

#### Static-descriptor bundle bindings

For bundles using descriptor tables with static descriptors, the
descriptors have to be ready starting at the time the bundle is recorded
(as opposed to when the bundle is called), and not change until the
bundle has finished executing for the last time. Descriptor tables
pointing to static descriptors have to be set during bundle recording
and not inherited into the bundle. It is ok for a command list to use a
descriptor table with static descriptors that has been set in a bundle
and returned back to the command list.

<a id="static-data"></a>

#### Static-data bundle bindings (`DATA_STATIC`)

`DATA_STATIC` defines a [recording-to-final-execution data lifetime](binding.md#data-static). Its bundle-specific application is:

For bundles, to clarify, the static duration starts at root descriptor
or descriptor table setting during the recording of the bundle, as
opposed to recording of a calling command list. In addition, a
descriptor table pointing to static data must be set in the bundle and
not inherited in. It is ok for a command list to use a descriptor table
pointing to static data that has been set in a bundle and returned back
to the command list.

<a id="direct-heaps"></a>

### Directly indexed heap binding order

There is an ordering constraint between `SetDescriptorHeaps` and
`SetGraphicsRootSignature` or `SetComputeRootSignature`.
`SetDescriptorHeaps` must be called,
passing the corresponding heaps,
before a call to `SetGraphicsRootSignature` or `SetComputeRootSignature`
that uses either `CBV_SRV_UAV_HEAP_DIRECTLY_INDEXED` or `SAMPLER_HEAP_DIRECTLY_INDEXED` flags.
This is in order to make sure the correct heap pointers are available
when the root signature is set.
Additionally, `SetDescriptorHeaps` may not be called after
`SetGraphicsRootSignature` or `SetComputeRootSignature`
with different heap pointers before a Draw or Dispatch.

<a id="buffer-bindings"></a>

## Input and output buffer bindings

**Related APIs:** `ID3D12GraphicsCommandList::IASetIndexBuffer`, `ID3D12GraphicsCommandList::IASetVertexBuffers`, `ID3D12GraphicsCommandList::SOSetTargets`.

A direct recording starts with no vertex buffers, index buffer, or stream-output targets bound. Compute and copy lists do not acquire graphics input/output bindings by Reset. A bundle inherits the parent's applicable bindings. It may change vertex/index buffer bindings, and those changes affect the parent; it cannot call `SOSetTargets`.

The stream-output filled-size counter and UAV counters are resource data, not binding defaults. Unbinding or resetting a list does not initialize them.

<a id="output-bindings"></a>

## Output bindings

The full [OMSetRenderTargets contract](output-merger.md#omsetrendertargets) defines attachment binding; the [blend-factor](output-merger.md#omsetblendfactor), [common stencil-reference](output-merger.md#omsetstencilref), [independent stencil-reference](output-merger.md#omsetfrontandbackstencilref) and [depth-bounds](output-merger.md#omsetdepthbounds) entries define their dynamic calls. The initial/reset/bundle rules in this chapter remain canonical.

**Related APIs:** `ID3D12GraphicsCommandList::OMSetRenderTargets`.

A direct recording starts with no render targets or depth/stencil view bound. Bundles inherit the parent output bindings and cannot call `OMSetRenderTargets`. Render-pass entry/exit has its own explicit rules in [Render passes](#render-pass); it must not be treated as restoring the pre-pass outputs.

<a id="base-graphics"></a>

## Base graphics state

The base graphics defaults below apply to direct recordings. Graphics-only state is not an initialization obligation for compute or copy work. Bundles inherit viewports/scissors and cannot set them; they inherit blend factor and stencil references and may change them.

All currently bound resources are unbound. The primitive topology is set
to `D3D_PRIMITIVE_TOPOLOGY_UNDEFINED`. Viewports and scissor rects are empty, and the stencil reference value is zero.
The blend factor is (1.0, 1.0, 1.0, 1.0). Predication is disabled.

<a id="base-bundle-state"></a>

### Bundle entry and exit

The full [ExecuteBundle API and driver contract](execution.md#executebundle) defines its parameter, recording admission, selected-recording lifetime and errors. The state rules below remain canonical.

`ExecuteBundle` is defined such that the pipeline
state, primitive topology and other state set in bundle will spill back
to apply on the parent command list upon returning. Note that
`ExecuteBundle` is not a predicated operation. Note that bundles cannot
inherit pipeline state (because the `CreateCommandList` or `Reset` call defines the
initial pipeline state). Bundles also do not inherit primitive topology.

<a id="stencil-references"></a>

### Stencil references

**Related APIs:** `ID3D12GraphicsCommandList8::OMSetFrontAndBackStencilRef`, `ID3D12GraphicsCommandList::OMSetStencilRef`.

Both front-face and back-face stencil reference values start at zero on a direct recording. `OMSetStencilRef` selects one reference for both faces; `OMSetFrontAndBackStencilRef` can select them independently when `D3D12_FEATURE_DATA_D3D12_OPTIONS14::IndependentFrontAndBackStencilRefMaskSupported` is supported. A bundle inherits the references and its updates persist to the parent.

Stencil read/write masks remain PSO state; this independent-reference feature does not make those masks command-list bindings.

<a id="depth-bounds"></a>

## Depth-bounds range

**Related APIs:** `ID3D12GraphicsCommandList1::OMSetDepthBounds`.

Depth-bounds testing (DBT) is exposed as a PSO enable/disable toggle in order to
support hardware that sets depth buffer read state in the PSO, and a
Command List method in order to support dynamically changing the Depth
Bounds.

The default values are 0 and 1 for the minimum and maximum,
respectively.

The state of the DBT range will persist into and out-of Bundles. This
means that a Bundle must inherit the DBT range of the executing
Command List, and setting the DBT range in a Bundle will persist on
the executing Command List after the Bundle is executed.

When depth-bounds testing is supported, `ClearState` on a direct list restores the range to minimum 0 and maximum 1.

<a id="sample-positions"></a>

## Sample positions

**Related APIs:** `ID3D12GraphicsCommandList1::SetSamplePositions`.

In the absence of any calls to `SetSamplePositions` on a CommandList (so
far), sample positions assume the default for whatever the Pipeline
State Object used for drawing indicates, either via the `SAMPLE_DESC`
portion of the PSO if that applies, or standard sample positions if
`ForcedSampleCount` > 0 is being used in the `RASTERIZER_DESC` portion of
the PSO.

Once `SetSamplePositions` has been called, subsequent Draw* calls must
use a PSO that either specifies a matching sample count as
`SetSamplePositions` via the `SAMPLE_DESC` portion of the PSO, or a
matching `ForcedSampleCount` value in the `RASTERIZER_DESC`.

`SetSamplePositions` also impacts Resolve*() and Clear*() APIs called on
depth surfaces (does not impact stencil), as well as certain resource
state transition calls -- see [sample-position operational semantics](rasterization.md#programmable-samples).

Calling `SetSamplePositions(0,0,NULL)` reverts state back to the default.

`SetSamplePositions` can be called on direct command lists and bundles only.

Bundles inherit sample position state from the calling command list. `SetSamplePositions` is permitted in a bundle; changes persist on return to the parent.

The absence of a custom pattern, not a stored table of all-zero positions, is the initial setting for each new recording. A pattern set in an earlier recording must not be assumed to survive `Reset`. `ClearState` is not the operation for restoring this override: use `SetSamplePositions(0, 0, NULL)` explicitly.

<a id="view-mask"></a>

## View-instance mask

**Related APIs:** `ID3D12GraphicsCommandList1::SetViewInstanceMask`.

The view instance mask is only honored by PSOs that have view instancing
enabled and declare that they look at the view instance mask.

The view instance mask defaults to 0 (all views disabled). The reason
the default is 0 is if an application declares in PSO(s) that it wants
to use the view instance mask, it must actually use the mask, otherwise
nothing will be rendered to any views. If the default were the opposite,
all bits set, an application might forget to change the mask as
intended, resulting in draws wasting vertex processing by being sent to
views that will not be covered.

Bundles do not inherit the view instance mask in from the caller, and
the state starts at the default of 0. The reason for this is if the mask
setting affects how an implementation records draws, it must be known
when the bundle is recorded. View instance mask state set by a bundle
does leak back out to the caller after the bundle completes. These
inheritance semantics are similar to PSOs.

To restore the mask explicitly, call `SetViewInstanceMask(0)`.

<a id="shading-rate"></a>

## Variable-rate shading (VRS)

**Related APIs:** `ID3D12GraphicsCommandList5::RSSetShadingRate`, `ID3D12GraphicsCommandList5::RSSetShadingRateImage`.

All shading rate sources, namely the command-list-specified rate, the screen space image-specified rate, and the per-primitive attribute, have a default of `D3D12_SHADING_RATE_1X1`. The default combiners are {`PASSTHROUGH`, `PASSTHROUGH`}.

If no screen space image is specified, a shading rate of 1X1 is inferred from that source.

If no per-primitive attribute is specified, a shading rate of 1X1 is inferred from that source.

`ID3D12GraphicsCommandList::ClearState` resets the command-list-specified rate to default, and the selection of screen-space image to the default of “no screen space image”.

These defaults apply at the start of a supported direct recording. Shading-rate image binding requires Tier 2 support. Bundles inherit these states; their permitted VRS setter calls affect the parent afterward.

`ClearState` also restores both combiners to `PASSTHROUGH`. Changing pipeline state alone does not select a new shading-rate image or replace these command-list settings.

<a id="dynamic-state"></a>

## Dynamic PSO-derived state

**Related APIs:** `ID3D12GraphicsCommandList9::IASetIndexBufferStripCutValue`, `ID3D12GraphicsCommandList9::RSSetDepthBias`.

<a id="dynamic-application-state"></a>

### Application state: RSSetDepthBias and IASetIndexBufferStripCutValue

The initial depth-bias tuple and index-buffer strip-cut value come from the selected initial PSO, not from values left by the prior recording. A bundle's initial PSO likewise supplies these values, so they are not arbitrary incoming values from the parent.

The dynamic calls require the respective PSO flags, `D3D12_PIPELINE_STATE_FLAG_DYNAMIC_DEPTH_BIAS` and `D3D12_PIPELINE_STATE_FLAG_DYNAMIC_INDEX_BUFFER_STRIP_CUT`, and device support: `D3D12_FEATURE_DATA_D3D12_OPTIONS16::DynamicDepthBiasSupported` and `D3D12_FEATURE_DATA_D3D12_OPTIONS15::DynamicIndexBufferStripCutSupported`.

Calling these functions _does not_ change the pipeline state object's description. For example, if an application sets the pipeline state with depth bias state *A*, calls `RSSetDepthBias` with depth bias state *B*, and then sets the same pipeline state again, the depth bias state must then be *A*.

`RSSetDepthBias` and `IASetIndexBufferStripCutValue` are both valid calls inside a bundle, and the respective state changes must be preserved upon exiting bundle execution.

<a id="dynamic-driver-state"></a>

### Driver state

To legally dynamically update the depth bias state after pipeline assignment, the assigned pipeline MUST have been created with `D3D12DDI_PIPELINE_STATE_FLAG_DYNAMIC_DEPTH_BIAS`. Likewise, to legally dynamically update the IB strip cut value, the assigned pipeline MUST have been created with `D3D12DDI_PIPELINE_STATE_FLAG_DYNAMIC_INDEX_BUFFER_STRIP_CUT`.

For drivers, these flags are only _hints_ about whether or not state is allowed to be changed; they do not alter the behavior of calls to `pfnSetPipelineState`. When setting the pipeline state, the depth bias state and IB strip cut must still be set according to their descriptions in the pipeline state object, regardless of the presence of their corresponding dynamic flags.

For pipelines created with the corresponding flag, the _current_ depth bias state may be changed via the command list function, `pfnRSSetDepthBias`, and the _current_ IB strip cut value may be changed via the command list function, `pfnIASetIndexBufferStripCutValue`.

<a id="queries"></a>

## Predication and query context

The complete [query lifecycle and type support](counters-queries-and-predication.md#query-lifecycle) and [predicate comparison/operation matrix](counters-queries-and-predication.md#predication) are defined by the general chapter. This section retains graphics recording-context defaults and bundle boundaries.

**Related APIs:** `ID3D12GraphicsCommandList::BeginQuery`, `ID3D12GraphicsCommandList::EndQuery`, `ID3D12GraphicsCommandList::SetPredication`.

Predication is disabled at the start of a direct or compute recording. A bundle inherits the effective predicate and cannot call `SetPredication`. No queries are active in a new recording. Query Begin/End operations cannot span a `Reset`; queries begun in a recording must be ended before `Close`, and query Begin/End cannot be recorded in a bundle. Outstanding queries must also be ended before changing the protected-resource session.

Query heap results and stream-output/UAV counter values are not cleared by these CPU-side recording operations. A new recording context is not a reset of their GPU-visible contents.

<a id="protection"></a>

## Protection context

**Related APIs:** `ID3D12GraphicsCommandList3::SetProtectedResourceSession`.

`SetProtectedResourceSession` defines if protected resources can be accessed or not by subsequent
commands in the command list. By default, no protected resources are
enabled. After calling `SetProtectedResourceSession` with a valid session,
protected resources of the same type can refer to that session. After
calling `SetProtectedResourceSession` with `NULL`, no protected resources
can be accessed.

Creation/Reset and `ClearState` select no protected-resource session on command list/device combinations supporting this state. An explicit session selection is required before protected accesses. Session selection is available on supported direct/compute/copy lists, not as a bundle-side setter; a bundle executes within its parent's protection context. Session selection cannot be changed inside an active render pass. For session validity and its read-only status counter, see [protected-session status fences](execution.md#status-fences).

<a id="render-pass"></a>

## Render passes

Complete [BeginRenderPass](output-merger.md#beginrenderpass) and [EndRenderPass](output-merger.md#endrenderpass) entries, [attachment access/flow](output-merger.md#render-pass-access) and [recording restrictions](output-merger.md#render-pass-recording) are defined by Output merger. Pass entry/exit and inherited/undefined binding state remain defined here.

**Related APIs:** `ID3D12GraphicsCommandList4::BeginRenderPass`, `ID3D12GraphicsCommandList4::EndRenderPass`.

A new recording is outside a render pass. A pass must be ended before `Close`; `ClearState` and nested `BeginRenderPass` are not valid inside an active pass. A bundle does not start/end a render pass and instead executes under the parent's active pass, subject to that pass's command restrictions.

<a id="render-pass-outputs"></a>

### Output bindings

RTVs/the DSV are not inherited into the Render Pass; they must be set.
The RTVs/DSV set in `BeginRenderPass` are *not* propagated
out to the Command List; they are in an undefined state following the
Render Pass (the driver does not need to manually clear these to
something well-defined).

<a id="render-pass-resume"></a>

### Suspending and resuming

Applications can suspend/resume a sequence of render passes.  This means suspending at the end of
the last render pass in one command list and resuming with the first render pass in another command list.

These command lists can be recorded in parallel or any order, but when executed, they have to be placed in
the intended order in an execute command lists call.

A render pass can be both resuming and suspending if it is the only thing in a command list, connecting a prior command list that suspends
and a subsequent command list that resumes.

Resuming is requested by `BeginRenderPass` flags and a matched pass description, not by inheriting an open CPU recording context from another list. Resetting/reusing a list object does not cancel a previously recorded pass sequence or its surface lifetime/synchronization requirements.

<a id="indirect"></a>

## Indirect execution

**Related APIs:** `ID3D12GraphicsCommandList::ExecuteIndirect`.

`ExecuteIndirect` is defined to reset all bindings affected by the
`ExecuteIndirect` call to known values. In particular:

- If the command signature binds a VB to a particular slot, then after
    `ExecuteIndirect` is called, a `NULL` VB is bound to that slot.

- If the command signature binds an IB, then after `ExecuteIndirect`, a
    `NULL` IB is bound.

- If the command signature sets a root constant, then after
    `ExecuteIndirect` is called, the root constant value is set to 0.

- If the command signature sets a root view (CBV/SRV/UAV), then after
    `ExecuteIndirect` is called, the root view is set to a `NULL` view.

This enables drivers to easily track bindings. This is implemented by
the D3D12 runtime by making a series of DDI calls after
`ExecuteIndirect` is called.

`ID3D12GraphicsCommandList::ExecuteIndirect` is allowed inside of bundle command
lists only if all of the following are true:

1. `CountBuffer` is `NULL` (CPU-specified count only)

2. The command signature contains exactly 1 operation. This implies
    that the command signature does not contain root argument changes,
    nor contain VB/IB binding changes.

These are post-ExecuteIndirect values for the affected slots only, not the initial validity of every root argument/table in a fresh recording. Unaffected bindings do not become cleared merely because ExecuteIndirect was called.

Command-signature construction, argument/count buffers and execution are defined in [Indirect execution](indirect-execution.md#executeindirect). The [incrementing-constant argument](indirect-execution.md#incrementing-constant) sets one root constant and therefore resets that value to zero after the call. The affected-binding resets above also occur when no records execute or generated work is predicated off; unaffected bindings remain unchanged.

<a id="meta-commands"></a>

## Meta commands

**Related APIs:** `ID3D12GraphicsCommandList4::ExecuteMetaCommand`, `ID3D12GraphicsCommandList4::InitializeMetaCommand`.

[InitializeMetaCommand](meta-commands.md#initializemetacommand) defines GPU initialization ordering and the selected algorithm's resource requirements; [ExecuteMetaCommand](meta-commands.md#executemetacommand) defines invocation. Their declared state effects remain defined below.

The dirty-state fields are in [`D3D12_META_COMMAND_DESC`](meta-commands.md#d3d12_meta_command_desc) and have type [`D3D12_GRAPHICS_STATES`](meta-commands.md#d3d12_graphics_states), whose flag meanings identify the affected state families. Meta-command initialization/execution is therefore a state-affecting recorded operation even though its name is not a state setter. Reestablish the state required by later work when the declared dirty-state mask affects it. The meta command's GPU initialization and persistent resources are not automatically reinitialized by command-list Reset.

> **Draft qualification:** Whether an all-bits dirty-state mask implies the postconditions of `ClearState` remains unresolved. This draft does not assert that equivalence or assign Reset/default values from it. The affected-state restoration requirement above remains operative. The [scoped review](../../spec-maintenance/d3d12/meta-command-review.md) records the withheld claim and its evidence limits.

### InitializationDirtyState

`InitializationDirtyState` declares the command list states that are modified by the call to initialize the meta command.

### ExecutionDirtyState

`ExecutionDirtyState` declares the command list states that are modified by the call to execute the meta command.

<a id="annotations"></a>

## Annotations

**Related APIs:** [ID3D12GraphicsCommandList::BeginEvent](diagnostics.md#id3d12graphicscommandlist-beginevent), [ID3D12GraphicsCommandList::EndEvent](diagnostics.md#id3d12graphicscommandlist-endevent), [ID3D12GraphicsCommandList::SetMarker](diagnostics.md#id3d12graphicscommandlist-setmarker), [ID3D12VideoDecodeCommandList::BeginEvent](diagnostics.md#id3d12videodecodecommandlist-beginevent), [ID3D12VideoDecodeCommandList::EndEvent](diagnostics.md#id3d12videodecodecommandlist-endevent), [ID3D12VideoDecodeCommandList::SetMarker](diagnostics.md#id3d12videodecodecommandlist-setmarker), [ID3D12VideoEncodeCommandList::BeginEvent](diagnostics.md#id3d12videoencodecommandlist-beginevent), [ID3D12VideoEncodeCommandList::EndEvent](diagnostics.md#id3d12videoencodecommandlist-endevent), [ID3D12VideoEncodeCommandList::SetMarker](diagnostics.md#id3d12videoencodecommandlist-setmarker), [ID3D12VideoProcessCommandList::BeginEvent](diagnostics.md#id3d12videoprocesscommandlist-beginevent), [ID3D12VideoProcessCommandList::EndEvent](diagnostics.md#id3d12videoprocesscommandlist-endevent), [ID3D12VideoProcessCommandList::SetMarker](diagnostics.md#id3d12videoprocesscommandlist-setmarker).

The D3D12 runtime manages marker data by maintaining an internal copy whose lifetime is tied to the associated command allocator. When the command allocator is reset, all marker data linked to it is discarded. If the marker is set in the context of a command queue instead of a command list, its lifetime is instead bound to the command queue.

`SetMarker`, `BeginEvent`, and `EndEvent` record annotations rather than bindings of a graphics pipeline. A fresh recording has no open event region from an earlier recording. This does not reset the device's annotation mode, and list Reset must not be confused with reclaiming the allocator-backed marker data.

<a id="clear-state"></a>

## ClearState is not a new recording

`ClearState` is valid on direct/compute lists, not copy lists or bundles, and not inside an active render pass. It records state-setting operations in the current list; it does not erase recorded commands, reopen a closed list, repair a persistent recording error, end outstanding queries, or reclaim storage.

It installs the supplied/default PSO and restores the core direct/compute bindings and predication. On a direct list it restores the base graphics defaults, depth-bounds range when supported, and the VRS defaults/combiners/image when supported. Protection-session selection is cleared where supported. PSO-derived dynamic bias/strip cut follows the selected PSO.

Custom sample-position and view-mask restoration must not be inferred from the generic phrase 'clear state': explicitly use `SetSamplePositions(0, 0, NULL)` or `SetViewInstanceMask(0)` when those respective defaults are required.

<a id="external-state"></a>

## Resource data and synchronization

Draw/dispatch, copies, clears of resource contents, resolves, raytracing builds, resource barriers, and immediate buffer writes are recorded work, not new initial binding values. Their resource effects and synchronization are not undone by `Reset`. `SignalBarrier` and `WaitBarrier` operate on independent fence data and synchronization; see [fence-barrier commands](fence-barriers.md#commands).
