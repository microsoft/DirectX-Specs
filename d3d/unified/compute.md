<a id="compute"></a>

# Compute execution

<!-- d3d12-review-legend:begin -->

> [!NOTE]
> **Draft provenance annotations.**
> Underlining marks pending replacement wording or authored list items. Warning boxes
> mark authored, mixed or reopened passages awaiting editorial review.
> Editorial adoption does not establish factual or hardware verification. Exact approved factual
> corrections do not trigger a marker. Unmarked text elsewhere, declarations
> and structural Markdown are not assertions of approval.
> [Annotation scope and approvals](../../spec-maintenance/d3d12/prose-annotations.md).

<!-- d3d12-review-legend:end -->

<a id="stage-model"></a>

## Stage model

<ins><!-- d3d12-review-inline:begin:compute:C-overview:0:modified:migration-434aaf90957d6958-0 -->A compute shader is a separate logical shader type analogous to the graphics shaders: the vertex, geometry, and pixel shaders. However, while it uses the same classes of input and output data, it is not directly connected to other shaders in the same pipeline during use. Its purpose is to enable more general processing operations than those enabled by the graphics shaders.<!-- d3d12-review-inline:end:compute:C-overview:0:modified:migration-434aaf90957d6958-0 --></ins>

A compute shader does not necessarily have a forced 1-1 mapping to either input records (like a vertex shader does) or output records (like the pixel shader does).

<a id="device-memory"></a>
<a id="device-memory-operations-and-stage-integration"></a>

<ins><!-- d3d12-review-inline:begin:compute:N-stage-state:0:authored:migration-2c26e19a3079b78a-0 -->Compute execution selects a [compute pipeline state](pipeline-state.md#compute-description). The shader reads constants, shader resources and samplers and reads or writes resources through unordered access views (UAVs), using [compute root arguments and descriptors](binding.md#recording-state).<!-- d3d12-review-inline:end:compute:N-stage-state:0:authored:migration-2c26e19a3079b78a-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compute:N-device-operations:0:authored:corrective-C10-unbind -->Binding a descriptor does not automatically unbind conflicting SRV/UAV descriptors.<!-- d3d12-review-inline:end:compute:N-device-operations:0:authored:corrective-C10-unbind --></ins>

<ins><!-- d3d12-review-inline:begin:compute:N-stage-state:1:authored:migration-38a280ce94c8f9e5-0 -->Compute shaders are DXBC Shader Model 5.0 or 5.1 programs or DXIL Shader Model 6.x programs. The downlevel `cs_4_x` profiles are not part of this set.<!-- d3d12-review-inline:end:compute:N-stage-state:1:authored:migration-38a280ce94c8f9e5-0 --></ins>

<a id="thread-groups"></a>

## Thread groups and invocations

<ins><!-- d3d12-review-inline:begin:compute:N-group-model:0:authored:migration-32e21433413bff3b-0 -->A dispatch launches a three-dimensional grid of thread groups. Each group executes the same compute entry point and has its own thread group shared memory (TGSM). A shader's `[numthreads(X,Y,Z)]` declaration fixes the three-dimensional arrangement of threads within every group. The Dispatch arguments specify groups, not threads.<!-- d3d12-review-inline:end:compute:N-group-model:0:authored:migration-32e21433413bff3b-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compute:N-group-model:1:authored:migration-158e72e504fac99a-0 -->Groups can execute in any order. Threads within a group cooperate through TGSM, UAVs, atomics and explicit synchronization.<!-- d3d12-review-inline:end:compute:N-group-model:1:authored:migration-158e72e504fac99a-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compute:N-numthreads:0:authored:migration-430ec926547281da-0 -->`X`, `Y` and `Z` are positive compile-time integers. X and Y are each at most 1,024, Z is at most 64, and `X*Y*Z` is at most 1,024.<!-- d3d12-review-inline:end:compute:N-numthreads:0:authored:migration-430ec926547281da-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compute:N-numthreads:1:authored:migration-011be549c0a4c22c-0 -->For example, `[numthreads(10,8,3)]` declares 240 threads per group. `Dispatch(5,3,2)` launches 30 groups and therefore 7,200 shader invocations. For group `(2,1,0)`, local thread `(7,5,0)` has dispatch thread coordinates `(27,13,0)` and flattened group index 57.<!-- d3d12-review-inline:end:compute:N-numthreads:1:authored:migration-011be549c0a4c22c-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compute:N-dispatch-figure:0:authored:migration-a3639ef137f11e6d-0 -->![Compute dispatch with 30 groups of 240 threads and the IDs of one thread](../archive/images/d3d11/D3D11_3_ComputeDispatchExample.png)<!-- d3d12-review-inline:end:compute:N-dispatch-figure:0:authored:migration-a3639ef137f11e6d-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compute:N-dispatch-figure:1:authored:migration-d49f3d17bcb8a92d-0 -->The figure's ThreadGroupID, ThreadIDInGroup and ThreadID correspond to `SV_GroupID`, `SV_GroupThreadID` and `SV_DispatchThreadID`. Its implementation-specific subgroups must not be assumed to have a particular size or mapping.<!-- d3d12-review-inline:end:compute:N-dispatch-figure:1:authored:migration-d49f3d17bcb8a92d-0 --></ins>

<a id="generated-identifiers"></a>

### Generated identifiers

<ins><!-- d3d12-review-inline:begin:compute:N-identifiers:0:authored:migration-9f5c96d951af3943-0 -->Components are 32-bit unsigned integers. Let `groupSize = (X,Y,Z)` from `numthreads` and `localID = SV_GroupThreadID`.<!-- d3d12-review-inline:end:compute:N-identifiers:0:authored:migration-9f5c96d951af3943-0 --></ins>

<!-- d3d12-review-alert:begin:compute:N-identifiers:1:authored:migration-5557b1720eaa7b50-0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | HLSL semantic | DXBC input | DXIL operation | Meaning |
> |---|---|---|---|
> | `SV_GroupID` (`uint3`) | `vThreadGroupID.xyz` | `GroupId` | Group coordinates, each from zero through the corresponding dispatch count minus one |
> | `SV_GroupThreadID` (`uint3`) | `vThreadIDInGroup.xyz` | `ThreadIdInGroup` | Local coordinates, each from zero through the corresponding group size minus one |
> | `SV_DispatchThreadID` (`uint3`) | `vThreadID.xyz` | `ThreadId` | `SV_GroupID * groupSize + localID`, component-wise |
> | `SV_GroupIndex` (`uint`) | `vThreadIDInGroupFlattened` | `FlattenedThreadIdInGroup` | `localID.z*Y*X + localID.y*X + localID.x` |

<!-- d3d12-review-alert:end:compute:N-identifiers:1:authored:migration-5557b1720eaa7b50-0 -->

<ins><!-- d3d12-review-inline:begin:compute:N-identifiers:2:authored:migration-559b73c8d9c72613-0 -->The flattened local index is in `[0, X*Y*Z-1]`. X changes fastest, then Y, then Z. It is not a flattened index of the whole dispatch and is not in general a wave lane index.<!-- d3d12-review-inline:end:compute:N-identifiers:2:authored:migration-559b73c8d9c72613-0 --></ins>

<!-- d3d12-review-context:begin:compute:N-id-overflow:0:authored:migration-5c4fdf8d9a0d9583-0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**

> **Unresolved expanded-grid case:** The dispatch thread formula above defines representable coordinates. Expanded one-dimensional grids can make a mathematical component exceed `UINT32_MAX`. The selected public sources do not specify the resulting `SV_DispatchThreadID` value. No modulo-wrapping guarantee or additional group count limit is established here.

<!-- d3d12-review-context:end:compute:N-id-overflow:0:authored:migration-5c4fdf8d9a0d9583-0 -->

<a id="shader-representations"></a>

## Shader representations

<a id="dxbc-compute"></a>

### DXBC logical interface

<ins><!-- d3d12-review-inline:begin:compute:N-dxbc-table:0 -->DXBC declares its thread group dimensions with `dcl_thread_group`. A compute program has generated ID inputs and resource accesses, not vertex-style incoming records or a graphics stage output signature. `r#` and indexable `x#` storage is private to each thread. `g#` denotes shared storage for its group.<!-- d3d12-review-inline:end:compute:N-dxbc-table:0 --></ins>

<!-- d3d12-review-alert:begin:compute:N-dxbc-table:1:modified:migration-f751c54e43af5f56-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Logical storage/input | Count or bound | Access | Components | Indexable by temporary value | Default | Declaration |
> |---|---|---|---|---|---|---|
> | 32-bit temporaries `r#` | 4,096 total with `x#` | Read/write | 4 | No | None | Required |
> | 32-bit indexable temporary arrays `x#[n]` | 4,096 total with `r#` | Read/write | 4 | Yes | None | Required |
> | 32-bit TGSM `g#[n]` | 8,192 scalar DWORDs across declarations | Read/write | 1; raw/structured declaration layouts | Yes | None | Required |
> | Input resources `t#` | Shader profile and binding tiers | Read | Resource-defined | SM5.1 resource range indexing | None | Required |
> | Samplers `s#` | Shader profile and binding tiers | Read | 1 | SM5.1 resource range indexing | None | Required |
> | Constant buffers `cb#` | Shader profile and binding tiers | Read | 4 | Contents; SM5.1 resource ranges | None | Required |
> | Immediate constant buffer `icb[index]` | 1 | Read | 4 | Contents | None | Required |
> | `vThreadID.xyz` | 1 | Read | 3 | No | Generated | Required when used |
> | `vThreadGroupID.xyz` | 1 | Read | 3 | No | Generated | Required when used |
> | `vThreadIDInGroup.xyz` | 1 | Read | 3 | No | Generated | Required when used |
> | `vThreadIDInGroupFlattened` | 1 | Read | 1 | No | Generated | Required when used |
> | Null destination | Not applicable | Discard result | Not applicable | Not applicable | Not applicable | No |
> | UAVs `u#` | Shader profile and binding tiers | Read/write | Resource-defined | SM5.1 resource range indexing | None | Required |

<!-- d3d12-review-alert:end:compute:N-dxbc-table:1:modified:migration-f751c54e43af5f56-0 -->

<ins><!-- d3d12-review-inline:begin:compute:N-dxbc-table:2 -->The resource rows are logical shader declarations, subject to the shader profile and [binding tier limits](binding.md#binding-capabilities). The root signature maps SM5.0 register bindings. SM5.1 additionally supports [register spaces](binding.md#register-spaces), ranges and descriptor indexing.<!-- d3d12-review-inline:end:compute:N-dxbc-table:2 --></ins>

<ins><!-- d3d12-review-inline:begin:compute:C-register-spill:0:modified:migration-7bb92171bbe45ae8-0 -->In practice, hardware implementations may spill temp register storage to slower memory behind the scenes if the combination of number of temps per thread and number of threads in the group goes too high. Functionally, however, it will always appear to the DXBC shader as if storage for 4096 temp registers is available per Compute Shader thread independent of how many threads are in a group.<!-- d3d12-review-inline:end:compute:C-register-spill:0:modified:migration-7bb92171bbe45ae8-0 --></ins>

<a id="dxil-compute"></a>

### DXIL entry point, properties and operations

<ins><!-- d3d12-review-inline:begin:compute:N-dxil-model:0:authored:migration-c6f1e7e9c6d05980-0 -->A final DXIL compute shader has a compute entry point identified by `dx.entryPoints` and the `cs` shader model declaration. The entry point properties include the three `numthreads` dimensions (`kDxilNumThreadsTag`, tag 4), applicable shader requirement flags and any requested [wave size property](#wave-size).<!-- d3d12-review-inline:end:compute:N-dxil-model:0:authored:migration-c6f1e7e9c6d05980-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compute:N-dxil-model:1:authored:migration-f35cedd1e16c9d37-0 -->Compute system values are not packed into a graphics input signature. Ordinary compute has no graphics output signature: results are stored to resources. DXIL expresses private values through typed static single assignment (SSA) values and private allocations rather than a fixed bank of DXBC `r#` registers. The DXBC register count table is not a DXIL private allocation limit.<!-- d3d12-review-inline:end:compute:N-dxil-model:1:authored:migration-f35cedd1e16c9d37-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compute:N-dxil-model:2:authored:migration-9a785aa12591271c-0 -->TGSM is represented by typed global variables in address space 3 and accessed through the corresponding loads, stores and atomic operations. Resource operations use handles and their typed/raw/structured access instructions.<!-- d3d12-review-inline:end:compute:N-dxil-model:2:authored:migration-9a785aa12591271c-0 --></ins>

<a id="thread-group-shared-memory"></a>

## Thread group shared memory

<ins><!-- d3d12-review-inline:begin:compute:N-tgsm-storage:0:authored:migration-169cb19235334ac5-0 -->Each compute group has at most 32 KiB (32,768 bytes) of TGSM. Any thread in the group can read or write any declared shared location. Another group has separate shared storage even when it executes the same program. HLSL declares this storage with `groupshared`. The aggregate allocation, including type layout/alignment, must fit the per-group limit.<!-- d3d12-review-inline:end:compute:N-tgsm-storage:0:authored:migration-169cb19235334ac5-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compute:N-tgsm-storage:1:authored:migration-0182237ca5081582-0 -->DXBC exposes up to 8,192 32-bit scalar locations across all `g#` declarations. `dcl_tgsm_raw` declares a byte count multiple of four. `dcl_tgsm_structured` declares `structByteStride * structCount` bytes, with a four-byte-multiple stride. DXIL's typed shared globals are allocated according to their types, not by counting each typed element as one DWORD.<!-- d3d12-review-inline:end:compute:N-tgsm-storage:1:authored:migration-0182237ca5081582-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compute:N-tgsm-storage:2:authored:migration-9286f8f48d629289-0 -->[Native 16-bit types](numeric-and-data-rules.md#native16) permit two-byte shared storage. Minimum-precision types do not guarantee two-byte allocation.<!-- d3d12-review-inline:end:compute:N-tgsm-storage:2:authored:migration-9286f8f48d629289-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compute:F-long-vectors:0:authored:opus-groupshared-long-vectors -->`groupshared` variables can use [long vectors](common-shader-internals.md#dxil-vectors) in Shader Model 6.9 and later.<!-- d3d12-review-inline:end:compute:F-long-vectors:0:authored:opus-groupshared-long-vectors --></ins>

<ins><!-- d3d12-review-inline:begin:compute:C-tgsm-lifetime:0:modified:migration-31d48ecdecc64c3c-0 -->Values stored in this shared memory are not preserved between dispatches, nor between thread groups. They must be initialized by the shader before use, and any results to be persisted must be written out to resource memory.<!-- d3d12-review-inline:end:compute:C-tgsm-lifetime:0:modified:migration-31d48ecdecc64c3c-0 --></ins>

<a id="waves"></a>

## Waves and quad operations

<ins><!-- d3d12-review-inline:begin:compute:N-compute-wave-owner:0:authored:migration-0180d4dc9e8de124-0 -->A compute group can contain multiple [waves](common-shader-internals.md#waves). Their relative execution order is not specified. Do not assume a particular group-to-wave partition or equality of `SV_GroupIndex` and wave lane index except where the [compute quad contract](#compute-quads) supplies a mapping. Group cooperation across waves requires [memory/execution synchronization](memory-model.md#shader-barriers). Compute does not generate rasterization helper pixels.<!-- d3d12-review-inline:end:compute:N-compute-wave-owner:0:authored:migration-0180d4dc9e8de124-0 --></ins>

<a id="wave-size"></a>

### Requested wave size

<ins><!-- d3d12-review-inline:begin:compute:N-fixed-wave:0:authored:opus-wavesize-attribute-intro -->The `[WaveSize(numLanes)]` attribute (Shader Model 6.6) requests the wave size for a compute entry point.<!-- d3d12-review-inline:end:compute:N-fixed-wave:0:authored:opus-wavesize-attribute-intro --></ins>

The allowed wave sizes that an HLSL shader may specify are
the powers of 2 between 4 and 128, inclusive.
In other words, the set: `[4, 8, 16, 32, 64, 128]`.

<ins><!-- d3d12-review-inline:begin:compute:N-fixed-wave:0:authored:migration-860584e022f923b8-0 -->The argument is a compile-time integer from the allowed set. When shader-selected wave size is supported, the shader must execute at the requested size, and pipeline creation fails if that size is unsupported. The group may contain multiple waves or a partially filled wave.<!-- d3d12-review-inline:end:compute:N-fixed-wave:0:authored:migration-860584e022f923b8-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compute:W-device-obligation:0 -->A device that reports Shader Model 6.6 and `WaveOps` support must support shader-selected wave size. All powers of two in its reported wave size interval must be selectable, with wave operations supported at every such size. Sizes incompatible with compute wave intrinsics and shader selection must not be included in that interval.<!-- d3d12-review-inline:end:compute:W-device-obligation:0 --></ins>

<ins><!-- d3d12-review-inline:begin:compute:W-device-obligation:1 -->SM6.6 imposes no additional wave size selection requirement on a device that does not report `WaveOps`. Conversely, a shader's WaveSize property is communicated through its minimum/maximum lane requirements even if it uses no wave intrinsics; the property alone does not set a WaveOps requirement.<!-- d3d12-review-inline:end:compute:W-device-obligation:1 --></ins>

<ins><!-- d3d12-review-inline:begin:compute:N-fixed-wave:1:authored:migration-24480968a4685386-0 -->Starting with Shader Model 6.8, `[WaveSize(minWaveSize,maxWaveSize)]` accepts a range and `[WaveSize(minWaveSize,maxWaveSize,prefWaveSize)]` additionally requests a preferred size. Every supplied value is a compile-time power of two from 4 through 128, `minWaveSize < maxWaveSize`, and a supplied preferred size lies in the inclusive range. The one-argument form requests exactly one size.<!-- d3d12-review-inline:end:compute:N-fixed-wave:1:authored:migration-24480968a4685386-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compute:N-fixed-wave:2:authored:migration-19ac8577532e8cec-0 -->SM6.8 requires support for the ranged metadata's restrictions. The device and shader ranges must overlap. The driver selects a supported size within the requested range. If the preferred size is supported by the device, it must be used. An unsupported preference does not reject the shader when some other size in the allowed range is available.<!-- d3d12-review-inline:end:compute:N-fixed-wave:2:authored:migration-19ac8577532e8cec-0 --></ins>

See [DXIL wave size properties](dxil.md#wave-size-properties) for the property tags and operands.

<a id="compute-quads"></a>

### Derivatives and compute quad layout

<ins><!-- d3d12-review-inline:begin:compute:N-derivative-availability:0:authored:migration-80d6bbcf98392f10-0 -->Shader Model 6.6 supports derivatives and derivative-dependent sampling in compute. This includes `ddx`, `ddy`, their fine/coarse variants, implicit-derivative `Sample`, `SampleBias`, `SampleCmp` and `CalculateLevelOfDetail`, under their operation-specific type/format rules.<!-- d3d12-review-inline:end:compute:N-derivative-availability:0:authored:migration-80d6bbcf98392f10-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compute:N-derivative-availability:1:authored:migration-2a47f4dcd11df536-0 -->The derivative quad layout requires either X divisible by four with Y=Z=1, or X and Y both divisible by two. Other `numthreads` shapes cannot use derivatives. Amplification and mesh shaders use the same layout but have their own [optional derivative capability](amplification-and-mesh-shaders.md#derivatives).<!-- d3d12-review-inline:end:compute:N-derivative-availability:1:authored:migration-2a47f4dcd11df536-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compute:N-common-lod-algorithms:0:authored:corrective-C11-derivative-prerequisite -->These stage-specific derivatives feed the common [LOD/anisotropy calculation](common-shader-internals.md#lod-and-anisotropy) and [sampling/addressing precision rules](common-shader-internals.md#sampling-precision).<!-- d3d12-review-inline:end:compute:N-common-lod-algorithms:0:authored:corrective-C11-derivative-prerequisite --></ins>

<ins><!-- d3d12-review-inline:begin:compute:Q-associations:0 -->For both layouts:<!-- d3d12-review-inline:end:compute:Q-associations:0 --></ins>

- <ins><!-- d3d12-review-inline:begin:compute:Q-associations:1:occurrence:bf30df917e31-0 -->`quadID = WaveGetLaneIndex() / 4`<!-- d3d12-review-inline:end:compute:Q-associations:1:occurrence:bf30df917e31-0 --></ins>
- <ins><!-- d3d12-review-inline:begin:compute:Q-associations:1:occurrence:cba86ccd9bbe-1 -->`quadIndex = WaveGetLaneIndex() % 4`<!-- d3d12-review-inline:end:compute:Q-associations:1:occurrence:cba86ccd9bbe-1 --></ins>

<ins><!-- d3d12-review-inline:begin:compute:Q-associations:2 -->`quadID` identifies which lanes share a quad, not a prescribed location for that quad in the group. The quad index follows Z-order:<!-- d3d12-review-inline:end:compute:Q-associations:2 --></ins>

<!-- d3d12-review-alert:begin:compute:Q-associations:3:modified:migration-24ef89691bd440df-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Quad indices |
> |:---:|
> | (0) (1)<br>(2) (3) |

<!-- d3d12-review-alert:end:compute:Q-associations:3:modified:migration-24ef89691bd440df-0 -->

<a id="compute-quads-1d"></a>

#### One-dimensional layout

Where only the X dimension is greater than 1,
the 2x2 quad is based on the group index
as provided by the `SV_GroupIndex` parameter.

- X position in quad from left = `SV_GroupIndex & 1`
- Y position in quad from top = `(SV_GroupIndex & 2) >> 1`

The result is that lanes in the group
form a sequence of serialized quads.
Every four sequential lanes form an individual quad.
The first and second lanes in the foursome
form the upper left and upper right respectively.
The third and fourth lanes
form the lower left and lower right respectively.
The lane after the fourth, if present represents
the upper left of the next quad.
This is sometimes called Z-order.

<ins><!-- d3d12-review-inline:begin:compute:Q-1d:3 -->To provide a deterministic mapping between SV_GroupIndex
and the lanes within a quad,
1D quad ordering requires that threads are assigned lane indices
in the same order within the quad as specified by the SV_GroupIndex parameter:<!-- d3d12-review-inline:end:compute:Q-1d:3 --></ins>

For 1D quads: `SV_GroupThreadID.x % 4 == SV_GroupIndex % 4 == WaveGetLaneIndex() % 4`

For example,
a thread group defined by `[numthreads (32, 1, 1)]`
might contain a single wave containing 32 lanes that make up 8 quads.
The layout for the first quad would be as follows where <ins><!-- d3d12-review-inline:begin:compute:Q-1d:5:modified:source-815b98c57cbf065b-0-0 -->the parenthesized value<!-- d3d12-review-inline:end:compute:Q-1d:5:modified:source-815b98c57cbf065b-0-0 --></ins>
represents the group index in decimal:

|Quad 0|
|:-----------:|
|(00) (01)<br>(02) (03)|

And a later quad would be:

|**Quad _n_**|
|:-----------:|
|(16) (17)<br>(18) (19)|

<a id="compute-quads-2d"></a>

#### Two-dimensional layout

Where the X and Y dimensions are divisible by 2,
the 2x2 quad is based on the x and y components
of group thread ID
as provided by the `SV_GroupThreadID` parameter.

- X position in quad from left = `SV_GroupThreadID.x & 1`
- Y position in quad from top = `SV_GroupThreadID.y & 1`

As a result, for every even x and y value within the thread group,
a quad is made up of the values (x,y) , (x+1,y), (x, y+1), (x+1, y+1).
There is no defined assignment of any quad within any wave
and no relation between the values of SV_GroupIndex and
the return value of WaveGetLaneIndex() should be assumed.

<ins><!-- d3d12-review-inline:begin:compute:Q-2d:3 -->For shader models before 6.6,
compute `Quad*` operations use the same association between quads and lane indices,
but this mapping of quad lanes to `SV_GroupThreadID` is not required.<!-- d3d12-review-inline:end:compute:Q-2d:3 --></ins>


<ins><!-- d3d12-review-inline:begin:compute:Q-2d:4 -->For example,
a thread group defined by `[numthreads (8,4,1)]`
might contain a single wave containing 32 lanes that make up 8 quads.
The layout for the first quad would be as follows where the parenthesized pair
represents the corresponding (GroupThreadID.x, GroupThreadID.y) values:<!-- d3d12-review-inline:end:compute:Q-2d:4 --></ins>

|Quad 0|
|:-----------:|
|(0,0) (1,0)<br>(0,1) (1,1)|

|**Quad _n_**|
|:-----------:|
|(6,2) (7,2)<br>(6,3) (7,3)|

<ins><!-- d3d12-review-inline:begin:compute:N-quad-uniformity:0:authored:migration-05977228761e89df-0 -->`QuadReadLaneAt` and the across-X/Y/diagonal operations are available in compute from SM6.0 with wave operation support. For SM6.0-6.5 their thread-to-quad mapping is implementation-dependent. SM6.6 supplies the layouts above. SM6.7 adds `QuadAny` and `QuadAll`, which test all four lanes of a quad and require quad-uniform flow control. Quad-uniform control may differ between quads of the same wave.<!-- d3d12-review-inline:end:compute:N-quad-uniformity:0:authored:migration-05977228761e89df-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compute:N-quad-uniformity:1:authored:migration-2135cd5ec38d6311-0 -->Derivative calculations on shader-computed temporary values likewise need the participating quad's values to be available. Divergent flow does not make a value from an inactive lane defined. See the [quad-uniformity rules](../HLSL_SM_6_7_QuadAny_QuadAll.md#how-to-use-quadanyquadall-to-ensure-uniform-flow-control-across-the-quad) for the direct-input-versus-temporary distinction and valid restructuring examples. Quad operations do not synchronize the rest of the group.<!-- d3d12-review-inline:end:compute:N-quad-uniformity:1:authored:migration-2135cd5ec38d6311-0 --></ins>

<a id="dispatch-grids"></a>
<a id="dispatch-dimensions"></a>

## Dispatch dimensions and capabilities

<a id="shared-grid-limits"></a>

### Common grid limits

<!-- d3d12-review-alert:begin:compute:N-dimension-table:0:authored:migration-8c18cd20a601156b-0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Operation/grid | Ordinary per-axis bound | Expanded one-dimensional bound | Independent total group bound |
> |---|---|---|---|
> | Direct or indirect compute dispatch | Each axis at most 65,535 | X at most [`Max1DDispatchSize`](devices-and-capabilities.md#d3d12_feature_data_d3d12_options22), with Y=Z=1 | No mesh/work graph total is imposed by this compute grid rule |
> | API, indirect or amplification shader mesh dispatch | Each axis at most 65,535 | X at most [`Max1DDispatchMeshSize`](devices-and-capabilities.md#d3d12_feature_data_d3d12_options22), with Y=Z=1 | `X*Y*Z < 2^22` (at most 4,194,303) |
> | Work graph execution grid | Each axis at most 65,535 | X at most [`Max1DDispatchSize`](devices-and-capabilities.md#d3d12_feature_data_d3d12_options22), with Y=Z=1 | `X*Y*Z < 2^24` (at most 16,777,215) |

<!-- d3d12-review-alert:end:compute:N-dimension-table:0:authored:migration-8c18cd20a601156b-0 -->

<ins><!-- d3d12-review-inline:begin:compute:N-grid-selection:0:authored:migration-0ce7ed715091c475-0 -->Mesh dispatch uses the [amplification or mesh program and graphics root state](amplification-and-mesh-shaders.md#dispatchmesh), unlike the compute program and root state used by [Dispatch](#dispatch).<!-- d3d12-review-inline:end:compute:N-grid-selection:0:authored:migration-0ce7ed715091c475-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compute:N-mesh-grid-scope:0:authored:migration-3d138c87582b32c8-0 -->When the pipeline has an amplification shader, API DispatchMesh dimensions launch amplification shader groups. Without one, they launch mesh shader groups directly. The amplification shader's DispatchMesh intrinsic launches a separate child mesh shader grid. Both grids are subject to the mesh row above. CPU validation of the API DispatchMesh arguments does not establish that the child grid is valid.<!-- d3d12-review-inline:end:compute:N-mesh-grid-scope:0:authored:migration-3d138c87582b32c8-0 --></ins>

<a id="work-graph-grids"></a>

### Work graph grid configuration

<ins><!-- d3d12-review-inline:begin:compute:N-graph-scope:0:authored:migration-713ff8c272e13c40-0 -->The work graph grid limits apply to CPU input records, GPU input records and shader-produced records. Dynamic grids must also fit the node's configured maximum grid. See [shader grid declarations](work-graphs.md#shader-function-attributes) and [state object grid overrides](state-objects.md#d3d12_broadcasting_launch_overrides) for program configuration. The independent 24-bit total applies even when the device's compute 1D capability is larger.<!-- d3d12-review-inline:end:compute:N-graph-scope:0:authored:migration-713ff8c272e13c40-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compute:N-graph-compiler:0:authored:migration-a2cd493ad2f57516-0 -->The selected shader compiler requires directly authored `NodeDispatchGrid` and `NodeMaxDispatchGrid` attribute values to be positive, at most 65,535 per axis and at most 16,777,215 in total. State object dispatch grid or maximum grid overrides can supply expanded one-dimensional X values, subject to the configured-grid and total constraints above.<!-- d3d12-review-inline:end:compute:N-graph-compiler:0:authored:migration-a2cd493ad2f57516-0 --></ins>

<a id="dispatch-validation"></a>

### Dispatch validation

<a id="validation-and-driver-responsibilities"></a>


<ins><!-- d3d12-review-inline:begin:compute:D-validation:0 -->Valid dispatch grids meet the following requirements:<!-- d3d12-review-inline:end:compute:D-validation:0 --></ins>

**<ins><!-- d3d12-review-inline:begin:compute:D-validation:1:occurrence:4ca5d3e5cc5a-0 -->For Direct Compute Dispatches (`Dispatch`) and Dispatch Graph (CPU_INPUT):<!-- d3d12-review-inline:end:compute:D-validation:1:occurrence:4ca5d3e5cc5a-0 --></ins>**
- <ins><!-- d3d12-review-inline:begin:compute:D-validation:1:occurrence:cf8ecf8f1929-1 -->If `ThreadGroupCountX > D3D12_CS_DISPATCH_MAX_THREAD_GROUPS_PER_DIMENSION` (65,535):<!-- d3d12-review-inline:end:compute:D-validation:1:occurrence:cf8ecf8f1929-1 --></ins>
  - <ins><!-- d3d12-review-inline:begin:compute:D-validation:1:occurrence:51871b272e7d-2 -->Require that `ThreadGroupCountY == 1`<!-- d3d12-review-inline:end:compute:D-validation:1:occurrence:51871b272e7d-2 --></ins>
  - <ins><!-- d3d12-review-inline:begin:compute:D-validation:1:occurrence:0ee9b8b8a46c-3 -->Require that `ThreadGroupCountZ == 1`<!-- d3d12-review-inline:end:compute:D-validation:1:occurrence:0ee9b8b8a46c-3 --></ins>
  - <ins><!-- d3d12-review-inline:begin:compute:D-validation:1:occurrence:106ad58856eb-4 -->Require that `ThreadGroupCountX <= Max1DDispatchSize`<!-- d3d12-review-inline:end:compute:D-validation:1:occurrence:106ad58856eb-4 --></ins>
  - <ins><!-- d3d12-review-inline:begin:compute:D-validation:1:occurrence:aeebf9ab942c-5 -->For DispatchGraph, require that `ThreadGroupCountX <= D3D12_WORK_GRAPHS_DISPATCH_MAX_THREAD_GROUPS_PER_GRID (16,777,215)`<!-- d3d12-review-inline:end:compute:D-validation:1:occurrence:aeebf9ab942c-5 --></ins>
  - <ins><!-- d3d12-review-inline:begin:compute:D-validation:1:modified:BC-S02-cpu-actors -->If any of these conditions is not met, the grid is invalid.<!-- d3d12-review-inline:end:compute:D-validation:1:modified:BC-S02-cpu-actors --></ins>
- <ins><!-- d3d12-review-inline:begin:compute:D-validation:1:occurrence:ce4b340b631c-6 -->If `ThreadGroupCountX <= 65535`:<!-- d3d12-review-inline:end:compute:D-validation:1:occurrence:ce4b340b631c-6 --></ins>
  - <ins><!-- d3d12-review-inline:begin:compute:D-validation:1:occurrence:784da925ef4e-7 -->Apply standard validation (all dimensions must be <= 65,535)<!-- d3d12-review-inline:end:compute:D-validation:1:occurrence:784da925ef4e-7 --></ins>

**<ins><!-- d3d12-review-inline:begin:compute:D-validation:1:occurrence:e46166d6e533-8 -->For Mesh Shader Dispatches (`DispatchMesh`):<!-- d3d12-review-inline:end:compute:D-validation:1:occurrence:e46166d6e533-8 --></ins>**
- <ins><!-- d3d12-review-inline:begin:compute:D-validation:1:occurrence:cf8ecf8f1929-9 -->If `ThreadGroupCountX > D3D12_CS_DISPATCH_MAX_THREAD_GROUPS_PER_DIMENSION` (65,535):<!-- d3d12-review-inline:end:compute:D-validation:1:occurrence:cf8ecf8f1929-9 --></ins>
  - <ins><!-- d3d12-review-inline:begin:compute:D-validation:1:occurrence:51871b272e7d-10 -->Require that `ThreadGroupCountY == 1`<!-- d3d12-review-inline:end:compute:D-validation:1:occurrence:51871b272e7d-10 --></ins>
  - <ins><!-- d3d12-review-inline:begin:compute:D-validation:1:occurrence:0ee9b8b8a46c-11 -->Require that `ThreadGroupCountZ == 1`<!-- d3d12-review-inline:end:compute:D-validation:1:occurrence:0ee9b8b8a46c-11 --></ins>
  - <ins><!-- d3d12-review-inline:begin:compute:D-validation:1:occurrence:9999a0dbac09-12 -->Require that `ThreadGroupCountX <= Max1DDispatchMeshSize`<!-- d3d12-review-inline:end:compute:D-validation:1:occurrence:9999a0dbac09-12 --></ins>
  - <ins><!-- d3d12-review-inline:begin:compute:D-validation:1:occurrence:2613a49f8791-13 -->Require that `ThreadGroupCountX <= D3D12_MS_DISPATCH_MAX_THREAD_GROUPS_PER_GRID (4,194,303)`<!-- d3d12-review-inline:end:compute:D-validation:1:occurrence:2613a49f8791-13 --></ins>
  - <ins><!-- d3d12-review-inline:begin:compute:D-validation:1:modified:BC-S02-mesh-actors -->If any of these conditions is not met, the grid is invalid.<!-- d3d12-review-inline:end:compute:D-validation:1:modified:BC-S02-mesh-actors --></ins>
- <ins><!-- d3d12-review-inline:begin:compute:D-validation:1:occurrence:ce4b340b631c-14 -->If `ThreadGroupCountX <= 65535`:<!-- d3d12-review-inline:end:compute:D-validation:1:occurrence:ce4b340b631c-14 --></ins>
  - <ins><!-- d3d12-review-inline:begin:compute:D-validation:1:occurrence:784da925ef4e-15 -->Apply standard validation (all dimensions must be <= 65,535)<!-- d3d12-review-inline:end:compute:D-validation:1:occurrence:784da925ef4e-15 --></ins>

The <ins><!-- d3d12-review-inline:begin:compute:D-runtime-enforcement:0:modified:source-35b385676c234578-0-0 -->ordinary runtime recording path<!-- d3d12-review-inline:end:compute:D-runtime-enforcement:0:modified:source-35b385676c234578-0-0 --></ins> does not drop, clamp, or otherwise modify an oversized dispatch. When <ins><!-- d3d12-review-inline:begin:compute:D-runtime-enforcement:0:modified:opus-debug-layer-actor -->the debug layer diagnoses oversized dimensions, it<!-- d3d12-review-inline:end:compute:D-runtime-enforcement:0:modified:opus-debug-layer-actor --></ins> reports an **error**, but the dispatch is still passed to the driver unchanged — issuing a debug-layer error does not, by itself, alter runtime behaviour. This is intentional: dropping the dispatch would be a compatibility risk for existing applications.

<ins><!-- d3d12-review-inline:begin:compute:N-validation-boundary:0:authored:migration-a41b927c70f3dbe3-0 -->Configured diagnostics may interrupt execution. CPU validation of direct dispatch or CPU input records does not inspect GPU-resident indirect, GPU input or shader-produced dimensions.<!-- d3d12-review-inline:end:compute:N-validation-boundary:0:authored:migration-a41b927c70f3dbe3-0 --></ins>



<a id="dispatch"></a>

## ID3D12GraphicsCommandList::Dispatch

### Declaration

```cpp
void Dispatch(
    UINT ThreadGroupCountX,
    UINT ThreadGroupCountY,
    UINT ThreadGroupCountZ
    );
```

### Behavior

These arguments identify the x-, y-, and z- dimensions of the array of thread groups to be dispatched.

<ins><!-- d3d12-review-inline:begin:compute:A-dispatch-groups:1 -->If any of the Dispatch arguments are 0, no thread groups are launched.<!-- d3d12-review-inline:end:compute:A-dispatch-groups:1 --></ins>

The invocation process dispatches the specified number of groups in the array. (The number of threads in each group is not specified in the Dispatch() call, but is specified in the shader to allow the compiler to optimize register pressure).

### Parameters

`[in] ThreadGroupCountX`

Type: **[UINT](https://learn.microsoft.com/en-us/windows/desktop/WinProg/windows-data-types)**

The number of groups dispatched in the x direction. *ThreadGroupCountX* <ins><!-- d3d12-review-inline:begin:compute:P-Dispatch:2:modified:source-50fec85479d14101-0-0 -->follows the [common grid limits](#shared-grid-limits), including the expanded one-dimensional case<!-- d3d12-review-inline:end:compute:P-Dispatch:2:modified:source-50fec85479d14101-0-0 --></ins>.

`[in] ThreadGroupCountY`

Type: **[UINT](https://learn.microsoft.com/en-us/windows/desktop/WinProg/windows-data-types)**

The number of groups dispatched in the y direction. *ThreadGroupCountY* must be less than or equal to <ins><!-- d3d12-review-inline:begin:compute:P-Dispatch:5:modified:source-1be4b280c856422d-0-0 -->D3D12_CS_DISPATCH_MAX_THREAD_GROUPS_PER_DIMENSION<!-- d3d12-review-inline:end:compute:P-Dispatch:5:modified:source-1be4b280c856422d-0-0 --></ins> (65535).

`[in] ThreadGroupCountZ`

Type: **[UINT](https://learn.microsoft.com/en-us/windows/desktop/WinProg/windows-data-types)**

<ins><!-- d3d12-review-inline:begin:compute:P-Dispatch:8 -->The number of groups dispatched in the z direction. *ThreadGroupCountZ* must be less than or equal to D3D12_CS_DISPATCH_MAX_THREAD_GROUPS_PER_DIMENSION (65535).<!-- d3d12-review-inline:end:compute:P-Dispatch:8 --></ins>

### Return values

None

### Recording and execution constraints

<ins><!-- d3d12-review-inline:begin:compute:N-dispatch-contract:0:authored:migration-aaad45786619e917-0 -->Dispatch records work on DIRECT and COMPUTE command lists and BUNDLE recordings, not COPY lists. Dispatch must execute outside an active render pass, including when a Dispatch-containing bundle executes under its parent's [render pass context](command-list-state.md#render-pass). A zero count on any axis does not bypass these constraints. See [pipeline selection](command-list-state.md#pipeline-selection) and [resource binding inheritance](command-list-state.md#resource-binding) for the pipeline state and bindings a bundle uses. [Predication](counters-queries-and-predication.md#predication-operation-matrix) affects eligible execution, not CPU-side recording and validation.<!-- d3d12-review-inline:end:compute:N-dispatch-contract:0:authored:migration-aaad45786619e917-0 --></ins>

<a id="indirect-dispatch"></a>

## Indirect execution

<ins><!-- d3d12-review-inline:begin:compute:N-indirect:0:authored:migration-9eda654a6c711a2d-0 -->[`ExecuteIndirect`](indirect-execution.md#executeindirect) uses `D3D12_INDIRECT_ARGUMENT_TYPE_DISPATCH` to consume [`D3D12_DISPATCH_ARGUMENTS`](indirect-execution.md#dispatch-arguments). `DISPATCH_MESH` consumes the [mesh dispatch record](indirect-execution.md#argument-records). Their grids use the corresponding [common dimensions](#shared-grid-limits).<!-- d3d12-review-inline:end:compute:N-indirect:0:authored:migration-9eda654a6c711a2d-0 --></ins>

## Dispatch driver interfaces and requirements

### Expanded dispatch grid requirements

<!-- d3d12-review-alert:begin:compute:D-driver-reporting:0:modified:migration-91fb80b73031c5a8-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> **Dispatch Handling:**
> - Drivers must correctly handle Compute dispatches with X dimension up to the reported `Max1DDispatchSize`
> - Drivers must correctly handle Mesh dispatches with X dimension up to the reported `Max1DDispatchMeshSize`
> - For valid expanded 1D grids, Y = 1 and Z = 1.
> - Drivers must not rely on the runtime to reject dispatches with invalid dimensions. See [Dispatch validation](#dispatch-validation).

<!-- d3d12-review-alert:end:compute:D-driver-reporting:0:modified:migration-91fb80b73031c5a8-0 -->

<a id="driver-dispatch"></a>

### Ordinary dispatch DDI

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_DISPATCH )(
    D3D12DDI_HCOMMANDLIST, UINT, UINT, UINT );
```

<ins><!-- d3d12-review-inline:begin:compute:WE-dispatch-roles:0:authored:migration-6b353201ce61c3a9-0 -->`PFND3D12DDI_DISPATCH` implements [Dispatch](#dispatch). Its three `UINT` arguments are `ThreadGroupCountX`, `ThreadGroupCountY` and `ThreadGroupCountZ` in that order.<!-- d3d12-review-inline:end:compute:WE-dispatch-roles:0:authored:migration-6b353201ce61c3a9-0 --></ins>

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_DISPATCH_0114 )(D3D12DDI_API_HCOMMANDLIST, UINT, UINT, UINT );
```

<ins><!-- d3d12-review-inline:begin:compute:EF-api-dispatch-contract:0:authored:migration-2af737c436827a0d-0 -->The `_0114` entry participates in [runtime bypass](execution.md#work-command-handles). Its arguments otherwise match the [ordinary dispatch DDI](#driver-dispatch).<!-- d3d12-review-inline:end:compute:EF-api-dispatch-contract:0:authored:migration-2af737c436827a0d-0 --></ins>
