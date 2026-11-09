# Unified Direct3D 12 specification

**Status: incomplete.** The chapters are bounded, source-preserving drafts.
Existing specifications remain the reference material for functionality not
yet consolidated.

This specification describes the Direct3D 12 API, device driver interface
(DDI), and hardware contract in chapterized Markdown. It incorporates
applicable hardware behavior from the
[Direct3D 11.3 functional specification](../archive/D3D11_3_FunctionalSpec.htm)
and integrates incremental feature specifications into an explicit description
of supported behavior.

## Scope

The specification describes shipped D3D12 functionality, including supported older
paths, capability-dependent behavior, and relevant compatibility history.

The supporting shader appendices will specify the complete DXBC shader-model 4.0, 4.1,
5.0, and 5.1 contract, not merely their incremental additions. Shader-model
availability and D3D12 applicability are distinct.

The DXIL specification and its shader-model 6.x contracts are also in scope as
a supporting appendix. Shared API, DDI, and hardware requirements have canonical
definitions in the main chapters, referenced by the shader appendices.
Main stage chapters describe overall behavior for both shader representations;
the DXIL appendix supplies the complete behavior reference for every intrinsic.

## Chapters

| Chapter | Current coverage |
|---|---|
| [Devices, feature levels and capabilities](devices-and-capabilities.md) | Adapter/device/node identity; ordinary and independent creation/configuration; runtime selection and SDK lifetime; feature queries, capability catalog and driver reporting; integrated [runtime and driver initialization](devices-and-capabilities.md#runtime-driver-initialization) |
| [Diagnostics](diagnostics.md) | Device-removal reporting/recovery and DRED settings/records; debug-controller configuration, object names, InfoQueue/messages; object-scoped feature/parameter controls, live-object reports and resource assertions |
| [Command recording and execution](execution.md) | Application and driver recording/storage lifecycle, submission transport and fence contracts, completion/lifetime and barrier interactions; [command queues](command-queues.md) and [meta commands](meta-commands.md) retain their conceptual references |
| [Command-list state initialization](command-list-state.md) | Canonical creation/Reset state, bundle entry/exit, and explicit feature/operation contributions for the pinned graphics interfaces |
| [Resources and memory](resources.md) | Resource/heap ownership, creation/allocation and residency; reserved/tiled resource shapes, packed mips, tier access, tiling queries and queue mappings; CPU mapping and current driver sizing/create/open/destroy contracts |
| [Synchronization and barriers](synchronization.md) | Common foundations; enhanced barriers first; legacy states/barriers and promotion/decay; model interoperation and driver translation |
| [Fence barriers](fence-barriers.md) | Barrier signals, scoped waits, capability and cache-coherency requirements, with common fence kinds defined in execution |
| [Resource binding and root signatures](binding.md) | Descriptor heaps/tables/handles, root arguments and signature versions, static/data promises, direct indexing, sampler extensions, ordinary APIs and selected driver contracts |
| [Formats and views](formats.md) | Format interpretation/casting; complete selected view descriptions; ordinary and feedback view creation; plane, support-query and selected driver contracts |
| [Numeric and data rules](numeric-and-data-rules.md) | Inherited floating-point representations/arithmetic, ULP/tolerances, normalized/integer/fixed-point/sRGB and packed-float conversions; native FP16 and scoped shader FP32 denormal control |
| [Pipeline state and shader linkage](pipeline-state.md) | Ordinary graphics/compute PSO descriptions and streams, supporting state, shader/root compatibility, cache blobs, selection and selected driver contracts |
| [Shader delivery and caching](shader-delivery-and-caching.md) | Application cache sessions and driver-cache control; supported legacy pipeline libraries and cached-blob retrieval, with storage/lifetime/compatibility and published driver contracts |
| [Advanced Shader Delivery](advanced-shader-delivery.md) | SODB inputs, offline compilation, cache delivery/registration and runtime consumption, with subordinate API, compiler-plugin DDI and database-format references |
| [Input assembly and vertex processing](vertex-processing.md) | IA/direct draws, fetching and primitive assembly, generated IDs, VS, shared interface capacities and view-instancing rules, and selected driver responsibilities |
| [Tessellation: hull and domain processing](tessellation.md) | DXIL/DXBC HS models, fixed-function patterns and factor processing, precision/watertightness, patch routing, DS and selected driver responsibilities |
| [Geometry shaders and stream output](geometry-shaders-and-stream-output.md) | Invocation/streams/emission and output budgets, DXBC/DXIL models, PSO capture declarations, SO target/counter binding, whole-primitive overflow, canonical query links and selected driver responsibilities |
| [Amplification and mesh shaders](amplification-and-mesh-shaders.md) | AS/MS groups, payloads, output/connectivity/attribute/storage rules, DXIL model, DispatchMesh, view/culling/order, canonical statistics links and selected driver responsibilities |
| [Rasterization](rasterization.md) | Clipping/transforms and view selection, snapping/culling/depth bias, primitive/sample coverage, conservative rasterization and programmable sample patterns; four full setters and selected driver contracts |
| [Pixel shaders](pixel-shaders.md) | Invocation/input/interpolation and barycentric models, derivatives/quads, outputs/early tests/helpers, ROV ordering and VRS; two full setters and selected driver DDIs |
| [Output merger](output-merger.md) | Depth/stencil/bounds tests and updates, blending/logic/output masks, seven attachment/dynamic/render-pass APIs, complete selected pass access/flow and published driver contracts |
| [Counters, queries, and predication](counters-queries-and-predication.md) | Query heaps/types/lifecycle and graphics/video APIs, canonical pipeline/SO statistics, GPU/CPU result resolution, queue clocks, buffer predicates and explicit current operation policies |
| [Compute execution](compute.md) | Thread groups and IDs, DXBC/DXIL models, per-group TGSM allocation/lifetime, waves and quad derivatives; full Dispatch API and shared grid limits |
| [Memory model](memory-model.md) | **Provisional; substantial revision required.** Relocated shader memory consistency, atomics/coherency, shader barriers and shared-access rules; not a complete general model |
| [Common shader internals](common-shader-internals.md) | Shared execution and DXBC/DXIL program/storage/resource models; texture addressing/filtering/LOD/anisotropy/comparison/gather, precision and shader-visible feedback; stage-specific groups/quads/helpers retain their owners |
| [Resource operations](resource-operations.md) | Buffer/texture/tile copies, immediate buffer writes, view clears, whole/regional resolves and graphics/video discard; eighteen API entries, formatted transfer regions, marker timing and clear/feedback conversion, with selected driver contracts |
| [Sharing and interoperability](sharing-and-interoperability.md) | Shared backing and NT handles; process/device/adapter and cross-API compatibility; shared resource/heap metadata creation and reflection; canonical resource/fence/state forwards and published open ABI |
| [Indirect execution](indirect-execution.md) | Command signatures and ExecuteIndirect, inherited draw/indexed/dispatch argument behavior, tightly packed records/counts, root and typed-work constraints, incrementing constants, argument producers, state/context links and published driver contracts |
| [Acceleration structures](acceleration-structures.md) | BLAS/TLAS geometry and instances, representation/determinism, build/update/sizing, opaque storage and specialized copy/postbuild/serialization/matching; opacity-micromap construction/encoding/linkage, five APIs and published driver contracts |
| [State objects](state-objects.md) | Shared collections/libraries/exports, subobjects and association/link rules; raytracing, work-graph and generic-program construction, incremental addition, selected properties/program identifiers, selection and published driver contracts |
| [Ray traversal and inline raytracing](ray-traversal.md) | Ray descriptions/extents, fixed-function intersection/watertightness, mask/flag/opacity/OMM behavior, complete RayQuery state/operation model and shared stored-result concepts |
| [Raytracing shader pipelines, tables and execution reordering](raytracing-pipelines.md) | Six shader stages, dynamic calls/payload qualifiers, identifiers/records/table indexing, DispatchRays, recursion/stack properties and full shipped HitObject/SER behavior, with published driver responsibilities |
| [Work-graph execution](work-graphs.md) | Compute-node launch modes, typed/empty records, allocation/completion/sharing, graph budgets, CPU/GPU dispatch inputs, node/entrypoint reflection, published handoff and driver scheduling |
| [Video](video.md) | Video device/query model; decode, processing, motion estimation, opaque extensions and H.264/HEVC/AV1 encoding; subordinate API/control/codec/type/DDI references with specialist qualifications |
