<a id="tessellation-chapter"></a>

# Tessellation: hull and domain processing

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

<ins><!-- d3d12-review-inline:begin:tessellation:PC-stage-creation-owner:0:authored:migration-bfbeb8a6e9bac9c2-0 -->The current hull/domain driver object creation/sizing/destruction contracts
are defined with [pipeline component creation](pipeline-state.md#driver-shader-objects)
and its [exact slot associations](pipeline-state.md#driver-object-slots).<!-- d3d12-review-inline:end:tessellation:PC-stage-creation-owner:0:authored:migration-bfbeb8a6e9bac9c2-0 --></ins>

<a id="tessellation"></a>

## Tessellation pipeline

<a id="tessellation-overview"></a>

### Tessellation Introduction

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.1:0 -->The tessellation model processes a patch at a time, either a quad, tri or "isoline" domain, and does not embody any specific surface representation. It strictly generates domain locations that are fed to a programmable shader ([Domain Shader](#domain-shader)) that is responsible for generating positions and any ancillary shading information (texture coordinates, tangent frames, normals, etc.). The domain locations are water tight across a boundary if identical level of detail is used, otherwise the hardware plays no role in ensuring crack free surfaces. This specification does not cover any specific surface representation, or how to map representations to the given pipeline.<!-- d3d12-review-inline:end:tessellation:STAGES-11.1:0 --></ins>

<a id="tessellation-input"></a>

### Input Assembler and Tessellation

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.3:0 -->The [Input Assembler](vertex-processing.md#input-assembly) has "patch list" primitive topologies, which are accompanied by a vertex count per patch: [1..32]. This is also described under [Patch Topologies](vertex-processing.md#patch-topologies).<!-- d3d12-review-inline:end:tessellation:STAGES-11.3:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.3:1 -->Indexing and instancing work orthogonally with patches.<!-- d3d12-review-inline:end:tessellation:STAGES-11.3:1 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.3:2 -->Incomplete patches are discarded – for example if the vertex count is 32 per patch, and a one-instance draw specifies 63 vertices, one 32 vertex patch will be produced, and the remaining 31 vertices will be discarded.<!-- d3d12-review-inline:end:tessellation:STAGES-11.3:2 --></ins>

<a id="tessellation-stage-flow"></a>

### Tessellation stages

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.4:0 -->Here are pointers to the stages involved in Tessellation, in the order of data flow:<!-- d3d12-review-inline:end:tessellation:STAGES-11.4:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.4:1 -->[Hull Shader](#hull-shader)<!-- d3d12-review-inline:end:tessellation:STAGES-11.4:1 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.4:2 -->[Fixed Function Tessellator](#fixed-function-tessellator) (defined below)<!-- d3d12-review-inline:end:tessellation:STAGES-11.4:2 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.4:3 -->[Domain Shader](#domain-shader)<!-- d3d12-review-inline:end:tessellation:STAGES-11.4:3 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-phase-scope:0:authored:migration-af66e4c70fbbf30e-0 -->Hull shader control point computation produces output control points, and patch constant computation produces per-patch data including tessellation factors. The DXIL and DXBC subsections describe their respective program organization. DXBC fork/join mini-programs and register declarations are not additional API shader stages. The fixed-function tessellator consumes the final factors regardless of the shader representation that produced them.<!-- d3d12-review-inline:end:tessellation:STAGES-phase-scope:0:authored:migration-af66e4c70fbbf30e-0 --></ins>

<a id="tessellation-enablement"></a>

## Tessellation stage selection

<a id="tessellation-stage-selection"></a>

### Stage presence and topology

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.8.1:0 -->The presence of both a Hull Shader and Domain Shader enables tessellation. When a Hull Shader and Domain Shader are selected, the Input Assembler topology is required to be a patch type (otherwise the draw configuration is invalid). If a Hull Shader is selected and no Domain Shader is selected, or vice versa, the pipeline configuration is invalid.<!-- d3d12-review-inline:end:tessellation:STAGES-11.8.1:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.8.1:1 -->Patches can be used at the Input Assembler without tessellation (no Hull Shader or Domain Shader), as long as the Geometry Shader and/or Stream Output are being used.<!-- d3d12-review-inline:end:tessellation:STAGES-11.8.1:1 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-selection-owner:0:authored:migration-1668c258695257d6-0 -->The [PSO compatibility rules](pipeline-state.md#compatibility) require hull/domain pairing, compatible signatures, control point counts and tessellator domain. The command list topology supplies the patch's actual input control point count. Shader selection and creation validity are distinct from fixed-function factor clamping/culling during execution.<!-- d3d12-review-inline:end:tessellation:STAGES-selection-owner:0:authored:migration-1668c258695257d6-0 --></ins>

## Untessellated patch routing

<a id="untessellated-patches-gs"></a>

### Untessellated patches to the geometry shader

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.8.1.1:0 -->When tessellation is disabled (no Hull Shader and no Domain Shader bound), patches arriving at the Geometry Shader cause the GS to be invoked once per patch. Each GS invocation sees all the Control Points of the patch as an array of input vertices.<!-- d3d12-review-inline:end:tessellation:STAGES-11.8.1.1:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.8.1.1:1 -->Allowing the GS to be invoked with patches allows it to effectively input non-traditional topologies (beyond points, lines, triangles). E.g. to invoke the GS with a cube as its input primitive, one could send 8 Control Point patches.<!-- d3d12-review-inline:end:tessellation:STAGES-11.8.1.1:1 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.8.1.1:2 -->The GS does not support output of patches. The output of the GS remains one of: point list, line strips or triangle strips.<!-- d3d12-review-inline:end:tessellation:STAGES-11.8.1.1:2 --></ins>

<a id="untessellated-patches-so"></a>

### Untessellated patches to stream output

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.8.1.2:0 -->Sending un-tessellated patches to NULL GS + Stream Output is valid. This enables, for example, Control Points that have gone through the Vertex Shader to be streamed out for multi-pass or reuse scenarios. Note, however, it is not possible for Hull Shader outputs to be streamed out (or go into the GS) - the presence of the Hull Shader requires a simultaneous Domain Shader and enables Tessellation – both of which consume Hull Shader output entirely.<!-- d3d12-review-inline:end:tessellation:STAGES-11.8.1.2:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.8.1.2:1 -->When un-tessellated patches arrive at Stream Output, each Control Point in the patch appears as a single vertex for Stream Output. This definition is similar to the way NULL GS + Stream Output behaves with traditional primitive topologies such as triangle lists. As with other primitive types, only complete patches get written out; if there is not enough room to store a complete patch, it is discarded.<!-- d3d12-review-inline:end:tessellation:STAGES-11.8.1.2:1 --></ins>

<a id="untessellated-patches-rasterizer"></a>

### Untessellated patches and rasterization

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.8.1.3:0 -->It could have been defined that Control Points arriving at the rasterizer are interpreted as points and rasterized as such, but that would have required a RenderTarget-space projected "position" to be present in the control points, and the application would have to have wanted to draw them as points. This is an extremely unlikely scenario, not worth targeting. Routing an untessellated patch directly to active rasterization is an invalid pipeline configuration. If such a patch nevertheless reaches the rasterizer, its behavior is undefined.<!-- d3d12-review-inline:end:tessellation:STAGES-11.8.1.3:0 --></ins>

<a id="hull-shader"></a>

## Hull shader

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.1:0 -->The DXBC Hull Shader instruction set is listed in the [instruction reference](../archive/D3D11_3_FunctionalSpec.htm#HSInstructionSet).<!-- d3d12-review-inline:end:tessellation:STAGES-10.1:0 --></ins>

<a id="hull-invocation"></a>

### Hull Shader Invocation

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.2:0:modified:migration-51c03fc486ebdce7-0 -->The Hull Shader operates once per patch, transforming Control Points, computing Patch Constant data and defining Tessellation Factors.<!-- d3d12-review-inline:end:tessellation:STAGES-10.2:0:modified:migration-51c03fc486ebdce7-0 --></ins>

<a id="patch-constant-overview"></a>

### Patch constant computation

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.5.1:0 -->Patch constant computation produces constant data such as [Tessellation Factors](#tessellation-factor-output) (how much the fixed function Tessellator should tessellate), as well as any other Patch Constant data, beyond the patch Control Points, that the application may need in the [Domain Shader](#domain-shader) (the shader that runs once per Tessellator output point).<!-- d3d12-review-inline:end:tessellation:STAGES-10.5.1:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.5.1:1 -->Patch constant computation occurs after the Control Point phase is complete, and has read-only access to all of the input and output Control Points. So for example, Control Points could be examined to help calculate [Tessellation Factors](#tessellation-factor-output) for each patch edge.<!-- d3d12-review-inline:end:tessellation:STAGES-10.5.1:1 --></ins>

<a id="dxil-hull-processing"></a>

### DXIL hull shader processing

The hull shader is represented as two functions, related via metadata: (1) control point phase function, which is the entry point of the hull shader, and (2) patch constant phase function.

<ins><!-- d3d12-review-inline:begin:tessellation:DXIL-HS-patch-inputs:0:modified:migration-c2bfcc7f4a8eeac4-0 -->The inputs to both functions are the input control points for an entire patch, and therefore each element may be indexed by row and, in addition, is indexed by vertex.<!-- d3d12-review-inline:end:tessellation:DXIL-HS-patch-inputs:0:modified:migration-c2bfcc7f4a8eeac4-0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:DXIL-HS-execution-bridge:0:authored:migration-fa404562dc53c3fc-0 -->The control point function is the hull shader's entry point, not a separately bound shader per control point. It logically processes each output control point, identified by `SV_OutputControlPointID`. Patch constant computation can read the patch's input control points and completed output control points and produces data shared by the patch, including its tessellation factors. These are the same [control point/patch constant data dependencies](#patch-constant-overview) and [logical storage limits](vertex-processing.md#geometry-interface-capacities) used by the stage. The two functions are not two application API shader stages.<!-- d3d12-review-inline:end:tessellation:DXIL-HS-execution-bridge:0:authored:migration-fa404562dc53c3fc-0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:DXIL-HS-patch-function:0:modified:migration-aeb998f0c4fe43bf-0 -->The patch constant function represents original HLSL computation, and is not separated into fork and join phases, as is the case in DXBC. The driver compiler may perform such separation if this is profitable for the target GPU.<!-- d3d12-review-inline:end:tessellation:DXIL-HS-patch-function:0:modified:migration-aeb998f0c4fe43bf-0 --></ins>

<a id="dxil-hull-data-flow"></a>

#### Signatures and data flow

<ins><!-- d3d12-review-inline:begin:tessellation:DXIL-HS-signatures:0:authored:migration-45f91e01e12df336-0 -->The input signature describes one input control point and is used across the input patch. The output signature describes one output control point. The patch constant signature describes the per-patch data passed to the domain shader, including tessellation factors. The [HS/DS interface matching rules](pipeline-state.md#compatibility) apply to both control point and patch constant interfaces.<!-- d3d12-review-inline:end:tessellation:DXIL-HS-signatures:0:authored:migration-45f91e01e12df336-0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:DXIL-HS-system-values:0:modified:migration-22c813389645dc9b-0 -->`SV_OutputControlPointID` and `SV_PrimitiveID` input elements are system-generated values loaded through DXIL intrinsics, and are not present in the signature at all.  These have a semantic interpretation of `SemanticInterpretationKind::NotInSig`.<!-- d3d12-review-inline:end:tessellation:DXIL-HS-system-values:0:modified:migration-22c813389645dc9b-0 --></ins>

The following table summarizes the <ins><!-- d3d12-review-inline:begin:tessellation:DXIL-HS-table-intro:0:modified:source-8e361002b10db1da-0-0 -->input/output operation roles<!-- d3d12-review-inline:end:tessellation:DXIL-HS-table-intro:0:modified:source-8e361002b10db1da-0-0 --></ins> of hull and domain shaders. CP stands for Control Point, PC - for Patch Constant.

<!-- d3d12-review-alert:begin:tessellation:DXIL-HS-operations-table:0:modified:migration-a3e87d229f9e75d5-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Operation | Control point function | Patch constant function | Domain shader |
> | --- | --- | --- | --- |
> | Store Input CP | - | - | - |
> | Load Input CP | `LoadInput` | `LoadInput` | - |
> | Store Output CP | `StoreOutput` | - | - |
> | Load Output CP | - | `LoadOutputControlPoint` | `LoadInput` |
> | Store PC | - | `StorePatchConstant` | - |
> | Load PC | - | `LoadPatchConstant` ([converted DXBC](#dxil-hull-dxbc-conversion)) | `LoadPatchConstant` |
> | Store Output Vertex | - | - | `StoreOutput` |

<!-- d3d12-review-alert:end:tessellation:DXIL-HS-operations-table:0:modified:migration-a3e87d229f9e75d5-0 -->

<a id="dxil-hull-counts"></a>

#### Control point counts

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-profile-counts:0:authored:fragment-prefix -->For DXIL hull shaders, the output control point count is 1 through 32. The <!-- d3d12-review-inline:end:tessellation:STAGES-profile-counts:0:authored:fragment-prefix --></ins><ins><!-- d3d12-review-inline:begin:tessellation:SG1:0:modified:concept -->[cases with zero output or an absent control point program](#hull-control-program-presence)<!-- d3d12-review-inline:end:tessellation:SG1:0:modified:concept --></ins><ins><!-- d3d12-review-inline:begin:tessellation:STAGES-profile-counts:0:authored:fragment-middle --> describe the DXBC model, not an alternative DXIL program structure. DXIL validation permits zero input control point metadata only when the input signature is empty. These metadata distinctions do not add a <!-- d3d12-review-inline:end:tessellation:STAGES-profile-counts:0:authored:fragment-middle --></ins><ins><!-- d3d12-review-inline:begin:tessellation:GRI15:0:modified:terminology -->zero control point<!-- d3d12-review-inline:end:tessellation:GRI15:0:modified:terminology --></ins><ins><!-- d3d12-review-inline:begin:tessellation:STAGES-profile-counts:0:authored:fragment-suffix --> input assembler topology; actual IA patch topologies still contain 1 through 32 control points, and the remaining shader/PSO validity conditions apply.<!-- d3d12-review-inline:end:tessellation:STAGES-profile-counts:0:authored:fragment-suffix --></ins>

<a id="dxil-hull-properties"></a>

#### Hull shader properties

<ins><!-- d3d12-review-inline:begin:tessellation:DXIL-HS-properties:0:modified:source-854112b6038d3b13-0-0 -->The hull shader properties associate the patch constant function and specify the stage state:<!-- d3d12-review-inline:end:tessellation:DXIL-HS-properties:0:modified:source-854112b6038d3b13-0-0 --></ins>

<!-- d3d12-review-alert:begin:tessellation:DXIL-HS-properties:1:modified:migration-1fd49760aea302ec-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Property | Meaning |
> | --- | --- |
> | Patch constant function | The related function's global symbol |
> | Input control point count | The shader's input control point count |
> | Output control point count | The shader's output control point count |
> | Tessellator domain | Triangle, quad or isoline domain |
> | Tessellator partitioning | The selected partitioning mode |
> | Tessellator output primitive | The selected output topology |
> | Maximum tessellation factor | The declared maximum tessellation factor |

<!-- d3d12-review-alert:end:tessellation:DXIL-HS-properties:1:modified:migration-1fd49760aea302ec-0 -->

<ins><!-- d3d12-review-inline:begin:tessellation:DXIL-HS-properties:2 -->The [tessellator state and factor rules](#tessellator-state) define the common execution contract. A maximum factor property is not a substitute for the [shader/compiler-side enforcement obligation](#maximum-tessellation-factor).<!-- d3d12-review-inline:end:tessellation:DXIL-HS-properties:2 --></ins>

<a id="dxbc-hull-processing"></a>

### DXBC phase organization

<ins><!-- d3d12-review-inline:begin:tessellation:DXIL-HS-DXBC-organization:0 -->In the DXBC model, the Hull Shader has four phases, all defined together as one program. That is, from the API/DDI point of view, the Hull Shader is a single atomic shader, and its phases are an implementation detail within the Hull Shader program. Implementations can choose to exploit independent work within a Patch by executing work within a single patch in parallel.<!-- d3d12-review-inline:end:tessellation:DXIL-HS-DXBC-organization:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:DXIL-HS-DXBC-organization:1 -->The phases appear in the DXBC intermediate language as standalone shaders, each with individual input and output declarations tailored to what each independent program is doing. However the inputs and outputs across all of the shaders come out of a fixed pool of Hull Shader-wide input data and output storage, described later in great detail.<!-- d3d12-review-inline:end:tessellation:DXIL-HS-DXBC-organization:1 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:DXIL-HS-DXBC-organization:2 -->The Hull Shader phase structure is depicted in the following picture:<!-- d3d12-review-inline:end:tessellation:DXIL-HS-DXBC-organization:2 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:DXIL-HS-DXBC-organization:3 -->![DXBC hull shader logical phases and outputs](images/hull-shader-phases.svg)<!-- d3d12-review-inline:end:tessellation:DXIL-HS-DXBC-organization:3 --></ins>

<a id="hull-state"></a>

### DXBC state declarations

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.3:0 -->This section of the Hull Shader has no executable code. It simply declares some overall characteristics of Hull Shader operation, such as how many control points the HS inputs and outputs (an independent number). The operation of the fixed function Tessellator is also defined here – such as choosing the patch domain, partitioning etc. A tessellation pattern overview is given [here](#tessellation-pattern).<!-- d3d12-review-inline:end:tessellation:STAGES-10.3:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.3:1 -->Note that declarations that are typical in shaders, such as input and output register declarations and declarations of input Resources, Constant Buffers, Samplers etc. are part of each individual shader phase below, not part of this HS State declaration section.<!-- d3d12-review-inline:end:tessellation:STAGES-10.3:1 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.3:2 -->See [Tessellator State](#tessellator-state).<!-- d3d12-review-inline:end:tessellation:STAGES-10.3:2 --></ins>

<a id="hull-control-points"></a>

### DXBC control point phase

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.4:0 -->In the Hull Shader’s Control Point phase, a thread is invoked once per patch output control point. An input value [vOutputControlPointID](../archive/D3D11_3_FunctionalSpec.htm#generatedvalue_OUTPUT_CONTROL_POINT_ID) identifies to each thread which output control point it represents. Each of the threads sees shared input of all the input control points for the patch. The output of each thread is one of the output control points for the patch.<!-- d3d12-review-inline:end:tessellation:STAGES-10.4:0 --></ins>

<a id="dxbc-patch-constant-phases"></a>

### DXBC patch constant phases

<ins><!-- d3d12-review-inline:begin:tessellation:DXIL-HS-DXBC-PC-phases:0:modified:migration-efd399175539e65b-0 -->There are two Patch Constant phases:<!-- d3d12-review-inline:end:tessellation:DXIL-HS-DXBC-PC-phases:0:modified:migration-efd399175539e65b-0 --></ins>

<a id="hull-fork"></a>

### DXBC patch constant fork phase

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.5.2:0 -->The Patch Constant Fork Phase is a collection of an arbitrary number of independent programs. For the discussion in this section let us call these independent programs mini-shaders.<!-- d3d12-review-inline:end:tessellation:STAGES-10.5.2:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.5.2:1 -->Each mini-shader produces independent (non-overlapping) parts of the total output Patch Constant data (such as all the different [TessFactors](#tessellation-factor-output)).<!-- d3d12-review-inline:end:tessellation:STAGES-10.5.2:1 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.5.2:2 -->An implementation could choose to execute each mini-shader in parallel, since they are independent. Or, in the opposite extreme an implementation could choose to trivially concatenate all the mini-shaders together and run them serially. Such transformations of the mini-shaders are trivial to perform (in a driver’s compiler) given they all share the same inputs and perform non-overlapping writes to a unified output space.<!-- d3d12-review-inline:end:tessellation:STAGES-10.5.2:2 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.5.2:3 -->An implementation could even choose to hoist any amount of the code from the Fork Phase up into the Control Point Phase if that happened to be most efficient. This is allowable because all the parts of a Hull Shader are specified together as if it is one program – how its contents are executed does not matter as long as the output is deterministic and defined observable shader effects are preserved.<!-- d3d12-review-inline:end:tessellation:STAGES-10.5.2:3 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.5.2:4 -->The shared inputs to each mini-shader are all of the Control Point Phase’s Input and Output Control Points.<!-- d3d12-review-inline:end:tessellation:STAGES-10.5.2:4 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.5.2:5 -->The output of each mini-shader is a non overlapping subset of the output Patch Constant Data.<!-- d3d12-review-inline:end:tessellation:STAGES-10.5.2:5 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.5.2:6 -->There is no communication of data between mini-shaders, other than the fact that they share Control Point input.<!-- d3d12-review-inline:end:tessellation:STAGES-10.5.2:6 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.5.2:7 -->To further enable parallelism within a single mini-shader, any mini-shader can be declared to run in an instanced fashion, given a fixed instance count per patch. During execution, each instance of an instance mini-shader is identified by a [ForkInstanceID](../archive/D3D11_3_FunctionalSpec.htm#generatedvalue_FORK_INSTANCE_ID) and is responsible for producing a unique output, typically by indexing an array of outputs. So for example, a single mini-shader instanced 4 times could output edge TessFactors for each edge of a quad patch.<!-- d3d12-review-inline:end:tessellation:STAGES-10.5.2:7 --></ins>

<a id="hull-join"></a>

### DXBC patch constant join phase

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.5.3:0 -->The final Hull Shader phase is the Patch Constant Join Phase. This phase behaves the same way as the Fork Phase, in that there can be multiple Join programs that are independent of each other. All of them execute after all the Fork Phase programs. An example use for this phase is to derive [TessFactors](#tessellation-factor-output) for the inside of a patch given the edge TessFactors computed in the previous phase.<!-- d3d12-review-inline:end:tessellation:STAGES-10.5.3:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.5.3:1 -->The inputs to each Patch Constant Join Phase shader are all the Control Point Phase’s Input and Output Control Points as well as all the Patch Constant Fork Phase’s output.<!-- d3d12-review-inline:end:tessellation:STAGES-10.5.3:1 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.5.3:2 -->The output of each Patch Constant Join Phase shader is a subset of the output Patch Constant data that does not overlap any of the outputs of the shaders from the Patch Constant Fork Phase or other Join Phase shaders.<!-- d3d12-review-inline:end:tessellation:STAGES-10.5.3:2 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.5.3:3 -->Similar to the fork phase, to enable parallelism within a join phase mini-shader, any mini-shader can be declared to run in an instanced fashion, given a fixed instance count per patch. During execution, each instance of an instance mini-shader is identified by a [JoinInstanceID](../archive/D3D11_3_FunctionalSpec.htm#generatedvalue_JOIN_INSTANCE_ID) and is responsible for producing a unique output, typically by indexing an array of outputs. So for example, a single mini-shader instanced 2 times could output inside TessFactors for each inside direction of a quad patch.<!-- d3d12-review-inline:end:tessellation:STAGES-10.5.3:3 --></ins>

<a id="hull-control-program-presence"></a>

### DXBC control point program presence

0 or 1 Control Point Phase program can be present

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.6-control-presence:1 -->If there is no Control Point Phase program:<!-- d3d12-review-inline:end:tessellation:STAGES-10.6-control-presence:1 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.6-control-presence:1 -->If the declared input control point count matches the declared output control point count, this is like passing through all of the control points<!-- d3d12-review-inline:end:tessellation:STAGES-10.6-control-presence:1 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.6-control-presence:1 -->If the declared output control point count is 0, the HS does not output any control points, however the fork and join phases in the HS can always read the input control points<!-- d3d12-review-inline:end:tessellation:STAGES-10.6-control-presence:1 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.6-control-presence:1 -->It is invalid for the output control point count to be more than 0 but not equal to the input control point count.<!-- d3d12-review-inline:end:tessellation:STAGES-10.6-control-presence:1 --></ins>

<a id="hull-control-storage"></a>

### DXBC control point interface and storage

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.7:0 -->[hs_control_point_phase](../archive/D3D11_3_FunctionalSpec.htm#inst_HS_CONTROL_POINT_PHASE) is a shader program with the following register model. Note the footnotes which provide a detailed discussion of output storage size calculations.<!-- d3d12-review-inline:end:tessellation:STAGES-10.7:0 --></ins>

<!-- d3d12-review-alert:begin:tessellation:STAGES-10.7:1:authored:migration-1eade275602b1a7b-0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Register Type | Count | r/w | Dimension | Indexable by r# | Defaults | Requires DCL |
> | --- | --- | --- | --- | --- | --- | --- |
> | 32-bit Input (v[vertex][element]) | 32(element)*32(vert) | r | 4 | Y | None | Y |
> | 32-bit UINT Input [vOutputControlPointID](../archive/D3D11_3_FunctionalSpec.htm#generatedvalue_OUTPUT_CONTROL_POINT_ID) | 1 | r | 1 | N | None | Y |
> | 32-bit UINT Input PrimitiveID (vPrim) | 1 | r | 1 | N | n/a | Y |
> | **Output Registers:** |  |  |  |  |  |  |
> | 32-bit output Vertex Data Element (o#) | 32, see [output storage](#hull-cp-output-storage) | w | 4 | Y | None | Y |

<!-- d3d12-review-alert:end:tessellation:STAGES-10.7:1:authored:migration-1eade275602b1a7b-0 -->

<a id="hull-cp-output-storage"></a>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.7:3 -->**Output storage.** Each Hull Shader Control Point Phase output register is up to a 4-vector, of which up to 32 registers can be declared. There are also from 1 to 32 output control points declared, which scales amount of storage required. Let us refer to the maximum allowable aggregate number of scalars across all Hull Shader Control Point Phase output as `cp_output_max`.<!-- d3d12-review-inline:end:tessellation:STAGES-10.7:3 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.7:4 -->`cp_output_max` = 3968 scalars<!-- d3d12-review-inline:end:tessellation:STAGES-10.7:4 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.7:5 -->This limit happens to be based on a design point for certain hardware of 4096*32-bit storage here. The amount for Control Point output is 3968=4096-128, which is 32(control points)*4(component)*32(elements) - **4(component)*32(elements)**. The subtraction reserves 128 scalars (one control point) worth of space dedicated to the HS Fork and Join phases, discussed below. The choice of reserving 128 scalars for Patch Constants (as opposed to allowing the amount to be simply whatever of the 4096 scalars of storage is unused by output Control Points) accommodates the limits of another particular hardware design. Note the Control Point Phase can declare 32 output control points, but they just can’t be fully 32 elements with 4 components each, since the total storage would be too high.<!-- d3d12-review-inline:end:tessellation:STAGES-10.7:5 --></ins>

<a id="hull-control-system-values"></a>

### System Generated Values input to the HS Control Point Phase

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.7.1:0 -->[InstanceID](vertex-processing.md#instance-id) and [VertexID](vertex-processing.md#vertex-id) can be input as long as the previous Vertex Shader stage outputs them.<!-- d3d12-review-inline:end:tessellation:STAGES-10.7.1:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.7.1:1 -->[PrimitiveID](vertex-processing.md#primitive-id) is also available as a scalar 32-bit integer input for each Control Point. PrimitiveID indicates the current patch in the Draw*() call, starting with 0. This PrimitiveID is the same value that the Geometry Shader would see for every patch if it input PrimitiveID - that is every point/line/triangle produced by the tessellator for a given patch has a single PrimitiveID for the entire Patch.<!-- d3d12-review-inline:end:tessellation:STAGES-10.7.1:1 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.7.1:2 -->[OutputControlPointID](../archive/D3D11_3_FunctionalSpec.htm#generatedvalue_OUTPUT_CONTROL_POINT_ID) is a scalar 32-bit integer input for each Control Point identifying which one it is [0..n-1] given n declared output Control Points.<!-- d3d12-review-inline:end:tessellation:STAGES-10.7.1:2 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-hull-system-semantic:0:authored:migration-8947ff8dd2b9b97a-0 -->In the hull shader, the control point invocation identifier is exposed through `SV_OutputControlPointID`.<!-- d3d12-review-inline:end:tessellation:STAGES-hull-system-semantic:0:authored:migration-8947ff8dd2b9b97a-0 --></ins>

<a id="hull-fork-programs"></a>

### DXBC fork programs

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.8.1:0 -->There can be 0 or more Fork Phase programs present in a Hull Shader. Each of them declares its own inputs, but they come from the same pool of input data – the Control Points. Each Fork Phase program declares its own outputs as well, but out of the same output register space as all Fork Phase and Join Phase programs, and the outputs can never overlap.<!-- d3d12-review-inline:end:tessellation:STAGES-10.8.1:0 --></ins>

<a id="hull-fork-interfaces"></a>

### DXBC fork interface

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.8.2:0 -->The following registers are visible in the [hs_fork_phase](../archive/D3D11_3_FunctionalSpec.htm#inst_HS_FORK_PHASE) model.<!-- d3d12-review-inline:end:tessellation:STAGES-10.8.2:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.8.2:1 -->The input resources (t#), samplers (s#), constant buffers (cb#) and immediate constant buffer (icb) are all shared state with all other HS Phases. That is, from the API/DDI point of view, the Hull Shader has a single set of input resource state for all phases. This goes with the fact that from the API/DDI point of view, the Hull Shader is a single atomic shader; the phases within it are implementation details.<!-- d3d12-review-inline:end:tessellation:STAGES-10.8.2:1 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.8.2:2 -->Note the footnotes which provide a detailed discussion of output storage size calculations.<!-- d3d12-review-inline:end:tessellation:STAGES-10.8.2:2 --></ins>

<!-- d3d12-review-alert:begin:tessellation:STAGES-10.8.2:3:modified:migration-72dda9dcbe555f57-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Register Type | Count | r/w | Dimension | Indexable by r# | Defaults | Requires DCL |
> | --- | --- | --- | --- | --- | --- | --- |
> | 32-bit Input Control Points (vicp[vertex][element]) (pre-Control Point Phase) | 32, see [input declaration subsets](#hull-fork-input-subsets) | r | 4(component)*32(element)*32(vert) | Y | None | Y |
> | 32-bit Output Control Points (vocp[vertex][element]) (post-Control Point Phase) | 32, see [input declaration subsets](#hull-fork-input-subsets) | r | 4(component)*32(element)*32(vert) | Y | None | Y |
> | 32-bit UINT Input PrimitiveID (vPrim) | 1 | r | 1 | N | n/a | Y |
> | 32-bit UINT Input [ForkInstanceID](../archive/D3D11_3_FunctionalSpec.htm#generatedvalue_FORK_INSTANCE_ID) (vForkInstanceID) | 1 | r | 1 | N | n/a | Y |
> | **Output Registers:** |  |  |  |  |  |  |
> | 32-bit output Patch Constant Data Element (o#) | 32, see [shared patch constant output](#hull-fork-shared-output) | w | 4 | Y | None | Y |

<!-- d3d12-review-alert:end:tessellation:STAGES-10.8.2:3:modified:migration-72dda9dcbe555f57-0 -->

<a id="hull-fork-input-subsets"></a>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.8.2:5 -->**Input declaration subsets.** The HS Fork Phase’s Input Control Point register (vicp) declarations must be any subset, along the **[element]** axis, of the HS Control Point input (pre-Control Point phase). Similarly the declarations for inputting the Output Control Points (vocp) must be any subset, along the [element] axis, of the HS Output Control Points (post-Control Point Phase).<!-- d3d12-review-inline:end:tessellation:STAGES-10.8.2:5 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.8.2:6 -->Along the **[vertex]** axis, the number of control points to be read for each of the vicp and vocp must similarly be a subset of the HS Input Control Point count and HS Output Control Point count, respectively. For example, if the vertex axis of the vocp registers are declared with n vertices, that makes the Control Point Phase’s Output Control Points [0..n-1] available as read only input to the Fork Phase.<!-- d3d12-review-inline:end:tessellation:STAGES-10.8.2:6 --></ins>

<a id="hull-fork-shared-output"></a>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.8.2:8 -->**Shared patch constant output.** The HS Fork and Join phase outputs are a shared set of 32 4-vector registers. The outputs of each Fork/Join phase program cannot overlap with each other. System Interpreted values such as [TessFactors](#tessellation-factor-output) come out of this space.<!-- d3d12-review-inline:end:tessellation:STAGES-10.8.2:8 --></ins>

<a id="hull-fork-declarations"></a>

### DXBC fork input declarations

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.8.3:0 -->The declarations for inputs, outputs, temp registers, resource etc. in an HS Fork Phase program are like any standalone shader. A given HS Fork Phase program need only declare what it needs to read and write. Further, if it does not need to see all Input or Output Control Points, it can declare a subset of the counts for each, by declaring a smaller number on the [vertex] array axis than the corresponding number of Control Points actually available.<!-- d3d12-review-inline:end:tessellation:STAGES-10.8.3:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.8.3:1 -->There is not a way to declare that a sparse set of the Control Points is read. E.g. a shader that needs read Input Control Points [0],[3], [11] and [15] would just declare the Input Control Point (vicp) register’s [vertex] axis size as 16. Note that if references to the Control Points from shader code use static indexing, it will be obvious to drivers exactly what subset of Control Points is actually needed by the program anyway.<!-- d3d12-review-inline:end:tessellation:STAGES-10.8.3:1 --></ins>

<a id="hull-fork-instances"></a>

### DXBC fork instancing

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.8.4:0 -->Any individual HS Fork Phase program can be declared to execute instanced, with a declaration identifying a fixed instance count from 1 to 0xffffffff. The 128-scalar shared Patch Constant output budget and output non-overlap requirements are not expanded by this instance count. The HS Fork Phase program executes the declared number of times per patch, with each instance identified by its 32-bit UINT input register [vForkInstanceID](../archive/D3D11_3_FunctionalSpec.htm#generatedvalue_FORK_INSTANCE_ID).<!-- d3d12-review-inline:end:tessellation:STAGES-10.8.4:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.8.4:1 -->Note that if the role of an instanced Fork Phase program is for each instance to produce a [System Interpreted Value](../archive/D3D11_3_FunctionalSpec.htm#SystemInterpretedValues), say one of the edge [TessFactors](#tessellation-factor-output) for a quad patch per instance, the declarations for each of those outputs would identify the System Interpreted Value being produced, just like any other shader.<!-- d3d12-review-inline:end:tessellation:STAGES-10.8.4:1 --></ins>

<a id="hull-fork-system-values"></a>

### DXBC fork system values

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.8.5:0 -->The HS Fork Phase can input [PrimitiveID](vertex-processing.md#primitive-id) in its own register just like the HS Control Point Phase. The value in this register is the same as what the HS Control Point Phase sees. The other special input register in the HS Fork Phase is [vForkInstanceID](../archive/D3D11_3_FunctionalSpec.htm#generatedvalue_FORK_INSTANCE_ID), described previously.<!-- d3d12-review-inline:end:tessellation:STAGES-10.8.5:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.8.5:1 -->The system doesn’t go out of its way to automatically provide other [System Generated Values](../archive/D3D11_3_FunctionalSpec.htm#SystemGeneratedValues) ([VertexID](vertex-processing.md#vertex-id), [InstanceID](vertex-processing.md#instance-id)) to the HS Fork Phase. Values like these are part of the Input Control Points (if they were declared to be there) already, so the HS Fork phase can read VertexID/InstanceID by reading them out of the Input Control Points.<!-- d3d12-review-inline:end:tessellation:STAGES-10.8.5:1 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.8.5:2 -->The treatment of [InstanceID](vertex-processing.md#instance-id) does seem strange, in that InstanceID would be the same for all Control Points in a Patch (indeed, unchanging across multiple patches), yet it shows up per-Input Control Point. However, this is consistent with the behavior elsewhere in the pipeline, where the first active stage that can input a System Generated Value (for InstanceID, that is the Vertex Shader) is responsible for passing the value down to the next stage via shader output (rather than the hardware feeding the value down to subsequent stages separately). For the Geometry Shader to see InstanceID, it also shows up in each input vertex there, just like it shows up in each Input Control Point in the Hull Shader.<!-- d3d12-review-inline:end:tessellation:STAGES-10.8.5:2 --></ins>

<a id="hull-join-programs"></a>

### DXBC join programs

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.9.1:0 -->There can be 0 or more Join Phase programs present in a Hull Shader. Each of them declares its own inputs, but they come from the same pool of input data – the Control Points as well as the Patch Constant outputs of the Fork Phase programs. Each Join Phase program declares its own outputs as well, but out of the same output register space as all Fork Phase and Join Phase programs, and the outputs can never overlap.<!-- d3d12-review-inline:end:tessellation:STAGES-10.9.1:0 --></ins>

<a id="hull-join-interfaces"></a>

### DXBC join interface

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.9.2:0 -->The following registers are visible in the [hs_join_phase](../archive/D3D11_3_FunctionalSpec.htm#inst_HS_JOIN_PHASE) model. Note there are three sets of input registers: v**icp** (Control Point Phase Input Control Points), v**ocp** (Control Point Phase Output Control Points), and v**pc** (Patch Constants). v**pc** are the aggregate output of all the HS Fork Phase programs. The HS Join Phase output o# registers are in the same register space as the HS Fork Phase outputs.<!-- d3d12-review-inline:end:tessellation:STAGES-10.9.2:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.9.2:1 -->The input resources (t#), samplers (s#), constant buffers (cb#) and immediate constant buffer (icb) are all shared state with all other HS Phases. That is, from the API/DDI point of view, the Hull Shader has a single set of input resource state for all phases. This goes with the fact that from the API/DDI point of view, the Hull Shader is a single atomic shader; the phases within it are implementation details.<!-- d3d12-review-inline:end:tessellation:STAGES-10.9.2:1 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.9.2:2 -->Note the footnotes which provide a detailed discussion of output storage size calculations.<!-- d3d12-review-inline:end:tessellation:STAGES-10.9.2:2 --></ins>

<!-- d3d12-review-alert:begin:tessellation:STAGES-10.9.2:3:modified:migration-c14ebb0fd2b255e3-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Register Type | Count | r/w | Dimension | Indexable by r# | Defaults | Requires DCL |
> | --- | --- | --- | --- | --- | --- | --- |
> | 32-bit Input Control Points (vicp[vertex][element]) (pre-Control Point Phase) | 32, see [input declaration subsets](#hull-join-input-subsets) | r | 4(component)*32(element)*32(vert) | Y | None | Y |
> | 32-bit Output Control Points (vocp[vertex][element]) (post-Control Point Phase) | 32, see [input declaration subsets](#hull-join-input-subsets) | r | 4(component)*32(element)*32(vert) | Y | None | Y |
> | 32-bit Input (vpc[element]) (Patch Constant Data) | 32, see [patch constant input](#hull-join-patch-input) | r | 4 | Y | None | Y |
> | 32-bit UINT Input PrimitiveID (vPrim) | 1 | r | 1 | N | n/a | Y |
> | 32-bit UINT Input [JoinInstanceID](../archive/D3D11_3_FunctionalSpec.htm#generatedvalue_JOIN_INSTANCE_ID) (vJoinInstanceID) | 1 | r | 1 | N | n/a | Y |
> | **Output Registers:** |  |  |  |  |  |  |
> | 32-bit output Patch Constant Data Element (o#) | 32, see [shared patch constant output](#hull-join-shared-output) | w | 4 | Y | None | Y |

<!-- d3d12-review-alert:end:tessellation:STAGES-10.9.2:3:modified:migration-c14ebb0fd2b255e3-0 -->

<a id="hull-join-input-subsets"></a>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.9.2:5 -->**Input declaration subsets.** The HS Join Phase’s Input Control Point register (vicp) declarations must be any subset, along the **[element]** axis, of the HS Control Point input (pre-Control Point phase). Similarly the declarations for inputting the Output Control Points (vocp) must be any subset, along the [element] axis, of the HS Output Control Points (post-Control Point Phase).<!-- d3d12-review-inline:end:tessellation:STAGES-10.9.2:5 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.9.2:6 -->Along the **[vertex]** axis, the number of control points to be read for each of the vicp and vocp must similarly be a subset of the HS Input Control Point count and HS Output Control Point count, respectively. For example, if the vertex axis of the vocp registers are declared with n vertices, that makes the Control Point Phase’s Output Control Points [0..n-1] available as read only input to the Join Phase.<!-- d3d12-review-inline:end:tessellation:STAGES-10.9.2:6 --></ins>

<a id="hull-join-shared-output"></a>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.9.2:8 -->**Shared patch constant output.** The HS Fork and Join phase outputs are a shared set of 32 4-vector registers. The outputs of each Fork/Join phase program cannot overlap with each other. System Interpreted values such as [TessFactors](#tessellation-factor-output) come out of this space.<!-- d3d12-review-inline:end:tessellation:STAGES-10.9.2:8 --></ins>

<a id="hull-join-patch-input"></a>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.9.2:10 -->**Patch constant input.** In addition to Control Point input, the HS Join phase also sees as input the Patch Constant data computed by the HS Fork Phase program(s). This shows up at the HS Join phase as the vpc# registers. The HS Join Phase’s input vpc# registers share the same register space as the HS Fork Phase output o# registers. The declarations of the o# registers must not overlap with any HS Fork phase program o# output declaration; the HS Join Phase is adding to the aggregate Patch Constant data output for the Hull Shader.<!-- d3d12-review-inline:end:tessellation:STAGES-10.9.2:10 --></ins>

<a id="hull-join-declarations"></a>

### DXBC join input declarations

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.9.3:0 -->The declarations for inputs, outputs, temp registers, resource etc. in an HS Join Phase program function the same way as [HS Fork Phase declarations](#hull-fork-declarations).<!-- d3d12-review-inline:end:tessellation:STAGES-10.9.3:0 --></ins>

<a id="hull-join-instances"></a>

### DXBC join instancing

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.9.4:0 -->Any individual HS Join Phase program can be declared to execute instanced, with a declaration identifying a fixed instance count from 1 to 0xffffffff. The 128-scalar shared Patch Constant output budget and output non-overlap requirements are not expanded by this instance count. The HS Join Phase program executes the declared number of times per patch, with each instance identified by its 32-bit UINT input register [vJoinInstanceID](../archive/D3D11_3_FunctionalSpec.htm#generatedvalue_JOIN_INSTANCE_ID).<!-- d3d12-review-inline:end:tessellation:STAGES-10.9.4:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.9.4:1 -->Note that if the role of an instanced Join Phase program is for each instance to produce a [System Interpreted Value](../archive/D3D11_3_FunctionalSpec.htm#SystemInterpretedValues), say one of the inside [TessFactors](#tessellation-factor-output) for a quad patch per instance, the declarations for each of those outputs would identify the System Interpreted Value being produced, just like any other shader.<!-- d3d12-review-inline:end:tessellation:STAGES-10.9.4:1 --></ins>

<a id="hull-join-system-values"></a>

### DXBC join system values

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.9.5:0 -->System Generated Values are dealt with the [same](#hull-fork-system-values) way in the HS Join Phase as the HS Fork Phase. Instead of [vForkInstanceID](../archive/D3D11_3_FunctionalSpec.htm#generatedvalue_FORK_INSTANCE_ID), in the Join Phase the same thing is called [vJoinInstanceID](../archive/D3D11_3_FunctionalSpec.htm#generatedvalue_JOIN_INSTANCE_ID). [PrimitiveID](vertex-processing.md#primitive-id) is available as a standalone input register.<!-- d3d12-review-inline:end:tessellation:STAGES-10.9.5:0 --></ins>

<a id="tessellation-factor-output"></a>

### Tessellation factor output

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.10.1:0 -->[Hull Shader](#hull-shader) Fork and Join Phase code can declare up to 6 of their output scalars as System Interpreted Values that identify various Tessellation Factors, driving how much tessellation the fixed function Tessellator should perform. For example, on a Quad there are 4 TessFactors for the edges, as well as 2 for the inside. HLSL exposes alternative (helper) ways to generate the inside tessfactors automatically from the edge TessFactors, e.g. deriving them by min/max/avg on the edge values, and possibly scaling based on user-provided scale values. The hardware does not understand anything about this helper processing (it just appears as shader code)<!-- d3d12-review-inline:end:tessellation:STAGES-10.10.1:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.10.1:1 -->The optional (from the HLSL author point of view) tessellation factor processing results in HLSL compiler autogenerated shader code in either or both of the Fork and Join Phases. This standard processing can involve cleaning up of values, handling of special low TessFactor cases to prevent popping, and rounding of the values depending on the tessellation mode.<!-- d3d12-review-inline:end:tessellation:STAGES-10.10.1:1 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.10.1:2 -->The final Tessellation Factors after this processing go to the fixed function Tessellator hardware – TessFactors for each edge and explicit TessFactors for the patch inside (as opposed to TessFactorScale the user specifies).<!-- d3d12-review-inline:end:tessellation:STAGES-10.10.1:2 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.10.1:3 -->Downstream, [Domain Shader](#domain-shader) code may be interested in seeing all of the intermediate values generated during any optional TessFactor processing. For example, to be able to perform blending during Pow2 Partitioning tessellation, one might want to see the ratio between unrounded and rounded TessFactor values. To enable that, the auto-generated code in the Fork and/or Join Phases will output not only final TessFactor values for the tessellator, but also the intermediate values, so the Domain Shader can access them. There are at most 12 such additional values (in the case of a Quad Patch). Again, the hardware does not understand anything about these "helper" values, and they are not discussed in detail here.<!-- d3d12-review-inline:end:tessellation:STAGES-10.10.1:3 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.10.1:4 -->The next sections describe just the TessFactors relevant to the hardware without discussing the various optional helper routines that HLSL provides to derive them.<!-- d3d12-review-inline:end:tessellation:STAGES-10.10.1:4 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.10.1:5 -->Further information about how Tessellation Factors are interpreted is [here](#tessellation-factor-interpretation).<!-- d3d12-review-inline:end:tessellation:STAGES-10.10.1:5 --></ins>

<a id="tri-tessellation-factors"></a>

### Tri Patch TessFactors

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.10.2:0 -->**float3 [SV_TessFactor](../archive/D3D11_3_FunctionalSpec.htm#interpretedvalue_TessFactor)**<!-- d3d12-review-inline:end:tessellation:STAGES-10.10.2:0 --></ins>

The first component provides the TessFactor for the U==0 edge of the patch.

The second component provides the TessFactor for the V==0 edge of the patch.

The third component provides the TessFactor for the W==0 edge of the patch.

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.10.2:4 -->In DXBC, the above hardware/system interpreted values must be declared in the same component of 3 consecutive registers (since indexing is on that axis).<!-- d3d12-review-inline:end:tessellation:STAGES-10.10.2:4 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.10.2:5 -->**float [SV_InsideTessFactor](../archive/D3D11_3_FunctionalSpec.htm#interpretedvalue_InsideTessFactor)**<!-- d3d12-review-inline:end:tessellation:STAGES-10.10.2:5 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.10.2:6 -->This determines how much to tessellate the inside of the tri patch.<!-- d3d12-review-inline:end:tessellation:STAGES-10.10.2:6 --></ins>

<a id="quad-tessellation-factors"></a>

### Quad Patch TessFactors

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.10.3:0 -->**float4 [SV_TessFactor](../archive/D3D11_3_FunctionalSpec.htm#interpretedvalue_TessFactor)**<!-- d3d12-review-inline:end:tessellation:STAGES-10.10.3:0 --></ins>

The first component provides the TessFactor for the U==0 edge of the patch.

The second component provides the TessFactor for the V==0 edge of the patch.

The third component provides the TessFactor for the U==1 edge of the patch.

The fourth component provides the TessFactor for the V==1 edge of the patch.

The ordering of the edges is clockwise, starting from the U==0 edge (visualized as the "left" edge of the patch).

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.10.3:6 -->In DXBC, the above hardware/system interpreted values must be declared in the same component of 4 consecutive registers (since indexing is on that axis).<!-- d3d12-review-inline:end:tessellation:STAGES-10.10.3:6 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.10.3:7 -->**float2 [SV_InsideTessFactor](../archive/D3D11_3_FunctionalSpec.htm#interpretedvalue_InsideTessFactor)**<!-- d3d12-review-inline:end:tessellation:STAGES-10.10.3:7 --></ins>

The first component determines how much to tessellate along the U direction of the inside of the patch.

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.10.3:9 -->The second component determines how much to tessellate along the V direction of the inside of the patch.<!-- d3d12-review-inline:end:tessellation:STAGES-10.10.3:9 --></ins>

<a id="isoline-tessellation-factors"></a>

### Isoline TessFactors

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.10.4:0 -->**float2 [SV_TessFactor](../archive/D3D11_3_FunctionalSpec.htm#interpretedvalue_TessFactor)**<!-- d3d12-review-inline:end:tessellation:STAGES-10.10.4:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.10.4:1 -->The first component determines the line density (how many tessellated parallel lines to generate in the V direction over the patch area).<!-- d3d12-review-inline:end:tessellation:STAGES-10.10.4:1 --></ins>

The second component determines the line detail (how finely tessellated each of the parallel lines is, in the U direction over the patch area).

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.10.4:3 -->In DXBC, the above hardware/system interpreted values must be declared in the same component of 2 consecutive registers (since indexing is on that axis).<!-- d3d12-review-inline:end:tessellation:STAGES-10.10.4:3 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.10.4:4 -->IsoLines are discussed further [here](#isolines)<!-- d3d12-review-inline:end:tessellation:STAGES-10.10.4:4 --></ins>

<a id="patch-constant-storage"></a>

### DXBC patch constant layout and indexing

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.11:0 -->The Hull Shader output Patch Constant data appears as 32 vec4 elements. The placement of the Final TessFactors are constrained as described in the previous sections – each grouping of TessFactors must appear in a specific order in the same component of consecutive registers/elements in the Patch Constant Data. E.g. For Quad Patches, the four Final Edge TessFactors in a fixed order make up one grouping, and the two Final Inside TessFactors in a fixed order make up another separate grouping.<!-- d3d12-review-inline:end:tessellation:STAGES-10.11:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.11:1 -->Shader indexing of the Patch Constant data across the 32 vec4 elements is restricted, due to the limitations of a particular hardware implementation, as follows:<!-- d3d12-review-inline:end:tessellation:STAGES-10.11:1 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.11:2 -->Indexing ranges (declared via dcl_indexRange regMin, regMax) on Patch Constant registers cannot cross over the start or end of any group of hardware TessFactors.<!-- d3d12-review-inline:end:tessellation:STAGES-10.11:2 --></ins>

<a id="hull-invocation-termination"></a>

### DXBC invocation termination

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.12:0 -->Since the Hull Shader has multiple phases, each of which can be instanced (e.g. multiple Control Points in the Control Point phase, or instanced Fork or Join Phases), the "ret*" ([return](../archive/D3D11_3_FunctionalSpec.htm#inst_RET) or [conditional return](../archive/D3D11_3_FunctionalSpec.htm#inst_RET_CONDITION)) shader instruction is defined to end only the current instance of the current phase. So a "ret*" in the Control Point Phase would only finish the current Control Point invocation without affecting the others or other phases. Or a "ret*" in a Fork or Join Phase program would only end that instance of that program without affecting other instances (if it is instanced) or other Fork/Join programs.<!-- d3d12-review-inline:end:tessellation:STAGES-10.12:0 --></ins>

<a id="maximum-tessellation-factor"></a>

### Declared maximum tessellation factor

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.13:0 -->The HS State Declaration Phase can optionally include a fixed float32 [MaxTessFactor](../archive/D3D11_3_FunctionalSpec.htm#inst_DCL_MAX_TESSFACTOR) in the range {1.0...64.0}.<!-- d3d12-review-inline:end:tessellation:STAGES-10.13:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.13:1 -->This MaxTessFactor [declaration](../archive/D3D11_3_FunctionalSpec.htm#inst_DCL_MAX_TESSFACTOR) is useful when the application knows the maximum amount of tessellation it could possibly ask for through the TessFactor values it will output from the Hull Shader. Communicating this knowledge to the device allows it to optionally take advantage and perform better scheduling of resources on the GPU.<!-- d3d12-review-inline:end:tessellation:STAGES-10.13:1 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.13:2 -->If a MaxTessFactor is declared, it is enforced by HLSL autogenerated TessFactor clamping code as the last step in the calculation of all of the following hardware System Interpreted Values (whose meanings were described earlier):<!-- d3d12-review-inline:end:tessellation:STAGES-10.13:2 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.13:3 -->SV_TessFactor<!-- d3d12-review-inline:end:tessellation:STAGES-10.13:3 --></ins>

SV_InsideTessFactor

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.13:5 -->For simplicity only a single MaxTessFactor value can be declared, and when it is present, it is applied to all the TessFactors listed above.<!-- d3d12-review-inline:end:tessellation:STAGES-10.13:5 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.13:6 -->The device sees the MaxTessFactor declaration as a part of the Hull Shader. The knowledge of this declaration is what hardware can optionally take advantage of to optimize Tessellation performance for content going through that Hull Shader, versus an otherwise identical Hull Shader without the declaration.<!-- d3d12-review-inline:end:tessellation:STAGES-10.13:6 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.13:7 -->If HLSL fails to enforce the MaxTessFactor when it is declared (by clamping the HS output TessFactors), and a TessFactor larger than MaxTessFactor arrives at the Tessellator, the Tessellator’s behavior is undefined. Hitting this undefined situation is a Microsoft HLSL compiler (or driver compiler) bug, not the fault of the shader author or hardware.<!-- d3d12-review-inline:end:tessellation:STAGES-10.13:7 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-10.13:8 -->Note that independent of this optional application-defined MaxTessFactor, the Tessellator always performs some additional basic clamping and rounding of Final TessFactors as appropriate for the situation, defined in the [hardware factor-clamping rules](#edge-factor-clamping). Those manipulations guarantee the hardware behavior by limiting the range of inputs possible. The only exception to that well defined hardware interface is this MaxTessFactor declaration which must rely on HLSL to generate code to enforce it. The reason it is the responsibility of HLSL to enforce consistency in this one case is it was too late in the spec process to arrive at any consistent hardware definition here, either by defining what the hardware behavior is if MaxTessFactor was not enforced but then exceeded at runtime, or getting all hardware vendors enforce the same MaxTessFactor clamping in hardware.<!-- d3d12-review-inline:end:tessellation:STAGES-10.13:8 --></ins>

<a id="dxil-hull-dxbc-conversion"></a>

### DXBC-to-DXIL conversion

<ins><!-- d3d12-review-inline:begin:tessellation:DXIL-HS-conversion:0:modified:migration-9f93dceb0aac4ef7-0 -->In DXBC to DXIL conversion, the original patch constant function cannot be recovered during DXBC-to-DXIL conversion. Instead, instructions of each fork and join phase are 'wrapped' by a loop that iterates the corresponding number of phase-instance-count iterations. Thus, fork/join instance ID becomes the loop induction variable. The `LoadPatchConstant` operation represents load from DXBC `vpc` register.<!-- d3d12-review-inline:end:tessellation:DXIL-HS-conversion:0:modified:migration-9f93dceb0aac4ef7-0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:DXIL-HS-pc-intermediates:0 -->`LoadPatchConstant` in the patch constant function is generated only by DXBC-to-DXIL converter, to access DXBC `vpc` registers. The HLSL compiler produces IR that references LLVM IR values directly.<!-- d3d12-review-inline:end:tessellation:DXIL-HS-pc-intermediates:0 --></ins>

<a id="fixed-function-tessellator"></a>

## Fixed-function tessellator

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.5:0 -->This fixed function stage takes floating point TessFactor values as input and generates a tessellation of the domain. The domain can be tri, quad or isoLine (see next section for a definition of isoLines).<!-- d3d12-review-inline:end:tessellation:STAGES-11.5:0 --></ins>

The tessellator generates a couple of things:

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.5:2 -->(1) A set of domain points - UV for isoLine or quad domains and UVW (barycentric) for a tri domain. Each of these domain points is input to its own Domain Shader invocation. Each Domain Shader invocation also sees shared input of all the [Hull Shader](#hull-shader) output data.<!-- d3d12-review-inline:end:tessellation:STAGES-11.5:2 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.5:2 -->(2) Topology connectivity - fed downstream past the [Domain Shader](#domain-shader). For tri and quad domains, the valid output topologies are points or triangles. For isoLines, the valid output topologies are points or lines.<!-- d3d12-review-inline:end:tessellation:STAGES-11.5:2 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.5:3 -->Note the domains are defined such that for isoLines and quads, the V direction is clockwise from the U direction. For tri domain, UVW are clockwise, in that order.<!-- d3d12-review-inline:end:tessellation:STAGES-11.5:3 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.5:4 -->[Adjacency](vertex-processing.md#adjacency) information is not available when using the tessellator - only independent points, lines or triangles are generated. The order that points/lines/triangles and their vertices are produced must be invariant between similar tessellator invocations on the same device, but no explicit order is prescribed.<!-- d3d12-review-inline:end:tessellation:STAGES-11.5:4 --></ins>

<a id="isolines"></a>

### IsoLines

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.6:0 -->The isoLine domain is a specialized form of the quad domain. It is the only domain that can produce tessellated lines. For isoLines, the U direction over a quad domain is the direction tessellated lines are drawn (lines of constant V). There are two [TessFactor](#isoline-tessellation-factors) values:<!-- d3d12-review-inline:end:tessellation:STAGES-11.6:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.6:1 -->The first is the line density, which is always rounded to integer and determines how many U-parallel tessellated line segments to generate across the V direction. The spacing of these line segments across V is uniform, starting at V=0. So if the line density is 1, a single tessellated line is generated from (U=0,V=0) to (U=1,V=0). If the line density is 2, the first tessellated line is generated from (0,0) to (1,0) and the second tessellated line is generated from (0,0.5)-(1,0.5). Notice that no line is ever generated at V=1.<!-- d3d12-review-inline:end:tessellation:STAGES-11.6:1 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.6:2 -->The second TessFactor is the line detail, determining how much to tessellate each line of constant V.<!-- d3d12-review-inline:end:tessellation:STAGES-11.6:2 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.6:3 -->For more concrete info on the tessellation pattern for isolines see [IsoLine Pattern Details](#isoline-pattern).<!-- d3d12-review-inline:end:tessellation:STAGES-11.6:3 --></ins>

<a id="tessellation-pattern"></a>

### Tessellation pattern

<a id="tessellation-reference-code"></a>

#### Overview

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.1:0 -->Details of the point placement and connectivity are described in words in this section.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.1:0 --></ins>

A more concrete description can be found in the reference fixed function tessellator code, entirely encapsulated in the following C++ files:

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.1:2 -->[tessellator.hpp](../archive/images/d3d11/tessellator.hpp)<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.1:2 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.1:3 -->[tessellator.cpp](../archive/images/d3d11/tessellator.cpp)<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.1:3 --></ins>

<a id="pattern-overview"></a>

#### Tessellation Pattern Overview

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.2:0 -->The inside of a triangle/quad patch is a tessellated triangle/square based on a specified InsideTessFactor(s). For a triangle, there is a [single TessFactor](#tri-tessellation-factors) for the inside region of the patch. For a quadrilateral, there are [2 inside TessFactors](#quad-tessellation-factors).<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.2:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.2:1 -->HLSL exposes helpers that can optionally derive inside TessFactors from the edge TessFactors (these amount to shader code, so the hardware doesn't need to know about them). For example in the case of a quad patch, the helpers have a couple of options for deriving inside TessFactors – 1-axis and 2-axis. In the 1-axis mode, the inside TessFactor reduction is applied on all 4 edges producing a single inside TessFactor. In the 2-axis mode, the reduction from 4 edge TessFactors is divided into two separate parts. The V==0 and V==1 edge TessFactors are reduced to a single TessFactor for the V direction of the interior. Similarly the U==0 and U==1 TessFactors are reduced to a single TessFactor for the U direction on the interior.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.2:1 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.2:2 -->The boundaries of the patch provide transitions between the inside TessFactor(s) and each per-edge TessFactor.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.2:2 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.2:3 -->There are two basic flavors of fractional tessellation: either using an even number of segments (intervals) on an edge or an odd number. When using an even number of segments the coarsest an edge can be refined is to have two segments an edge, so it is impossible to model a level of detail with a single segment.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.2:3 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.2:4 -->For integer partitioning, TessFactors are rounded to integer. The parity (even/odd) of each edge and inside TessFactor after rounding determines how that area is tessellated: an odd integer TessFactor matches odd fractional tessellation at the same TessFactor. Similarly, an even integer TessFactor matches even fractional tessellation at the same TessFactor.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.2:4 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.2:5 -->For pow2 partitioning, TessFactors are rounded to a power of 2, and tessellation of pow2 TessFactors matches even fractional tessellation at the same TessFactor, but in addition the power of 2 mode can go down to 1 segment on any side (1 is a power of 2). From the hardware point of view there is no distinction between pow2 and integer - the hardware doesn't do the rounding of the TessFactors to pow2. That rounding is the responsibility of the HLSL compiler, given the shader being authored using the appropriate helper intrinsics in shader code (not discussed here).<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.2:5 --></ins>

<a id="fractional-partitioning"></a>

#### Fractional Partitioning

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.3:0 -->"Fractional" means geometry smoothly transitions as TessFactor increases.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.3:0 --></ins>

- Since tessellation is symmetric about edges, geometry is always introduced by splitting 2 existing mirrored points across an axis into 4

- Number of segments along an axis always increments by 2 at a time, thus:

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.3:0 -->Starting at a minimum TessFactor of either 1 or 2 produces two flavors of fractional partitioning: ODD and EVEN...<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.3:0 --></ins>

<a id="fractional-odd"></a>

#### Fractional Odd Partitioning

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.3.1:0 -->Minimum TessFactor is 1; 1 for all TFs on a patch is like no tessellation (nice)<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.3.1:0 --></ins>

- Next TFs that have uniform segment widths are 3, 5, 7, 9...

- Between odd valued TFs, geometry is in transit.

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.3.1:0 -->When TF bumps above an odd integer, the number of segments is the next odd (3.1->5)<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.3.1:0 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.3.1:0 -->1 for all TFs on a patch is like "no tessellation"<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.3.1:0 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.3.1:0 -->The amount of geometry is as minimal as you could get short of culling the patch<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.3.1:0 --></ins>

<a id="fractional-even"></a>

#### Fractional Even Partitioning

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.3.2:0 -->Minimum TessFactor is 2<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.3.2:0 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.3.2:0 -->Next TFs that have uniform segment widths are 4, 6, 8...<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.3.2:0 --></ins>

<a id="splitting-edge-vertices"></a>

#### Splitting Vertices on an Edge

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.4:0 -->For even or odd partitioning, vertex splits always at mirrored pair of inside vertices<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.4:0 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.4:0 -->Never split at patch corners<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.4:0 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.4:0 -->Avoids degenerate transition area between neighboring patches<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.4:0 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.4:0 -->Exception: fractional odd partitioning at Tessellation Factor 1 only has 2 vertices per side – the corners<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.4:0 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.4:0 -->No choice but to split the edges<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.4:0 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.4:0 -->Not a problem<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.4:0 --></ins>

<a id="ruler-function"></a>

#### Which Vertices to Split

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.5:0 -->Since vertices are symmetric about center of an edge, only need to consider **one half**<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.5:0 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.5:0 -->Let us define an "epoch" in the TessFactor number space as: Any TessFactor with a power of 2 number of vertices on **one half** of the domain (excluding corners)<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.5:0 --></ins>

- Starting at an epoch, split each vertex at that epoch one at a time from outside to inside as the TF increases, until the next epoch arrives

- This is dubbed the "Ruler Function"

 **Why Split Like This?**

- Could have always split from the center

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.5:0 -->Xbox 360 tessellator does fractional even partitioning, always splitting vertices at center of an edge<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.5:0 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.5:0 -->Choice of splitting algorithm affects triangulation of transition between edge TF and inside TF<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.5:0 --></ins>

- Ruler Function evenly distributes triangle edge directions connecting areas with different TessFactors

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.5:0 -->As opposed to having them always point towards the center of the span (yielding more extreme aspect ratios)<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.5:0 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.5:0 -->"ruler function" is a reference to the size of the tick marks on a ruler – coarser divisions have longer ticks. You enumerate the longer ticks first, then the next size smaller tick (including the larger ones) and so on indefinitely.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.5:0 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.5:0 -->Note with even partitioning, the middle point is a valid candidate in the half-TF space.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.5:0 --></ins>

- The fact that epoch splits are from outside to inside as opposed to inside to outside is somewhat arbitrary.

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.5:0 -->It turns out determining algorithmically where the split point needs to be at any given TF is very easy (see reference code)<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.5:0 --></ins>

<a id="triangulation"></a>

#### Triangulation

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6:0 -->Tri and Quad Domains are tiled with quads, each made of 2 triangles<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6:0 --></ins>

- Which way do the quad diagonals go?

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6:0 -->Quads closer to one of the patch corners than the others have diagonal pointing towards that corner<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6:0 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6:0 -->For fractional odd:<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6:0 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6:0 -->If quad is between 2 corners, diagonal is the direction a counter-clockwise spiral radiating out from center of patch would cross the quad<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6:0 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6:0 -->Center of a quad patch is a Z: The diagonal of the Z is oriented such that the top edge of the patch is V==0 and the left edge of the patch is U==0.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6:0 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6:0 -->Center of tri patch is a lone triangle<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6:0 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6:0 -->This is as rotationally symmetric as possible<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6:0 --></ins>

<a id="tessellation-transitions"></a>

#### Transitions

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6.1:0 -->How can each edge and the inside of a patch all have different Tessellation Factors from each other?<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6.1:0 --></ins>

- For a quad, imagine a picture with a frame

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6.1:0 -->Each side of the frame is a trapezoid<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6.1:0 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6.1:0 -->The "picture" is tessellated regularly<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6.1:0 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6.1:0 -->Using two inside TessFactors, one for each of U and V axes<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6.1:0 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6.1:0 -->Can also just set these inside TessFactors equally to get uniform interior tessellation<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6.1:0 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6.1:0 -->Each of the "frame" sides is a row of triangles stitching the TessFactor on the outside edge to the inside TF<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6.1:0 --></ins>

- A tri patch is just a picture+frame with only 3 sides

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6.1:0 -->single inside TessFactor<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6.1:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6.1:1 -->**Mapping Vertices to Texels 1:1 in an Application**<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6.1:1 --></ins>

- In TF Transition areas (picture frame), one could map vertices to different densities of texture map texels (such as different mipmaps) for each side

- Over a region with a fixed TessFactor, mapping vertices to texels is easy for quad domain

- For tri domain:

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6.1:2 -->Consider dividing the domain into 3 regions bounded by lines from the center to the corners<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6.1:2 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6.1:2 -->Or 6 regions, above 3 split down middle of edges<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6.1:2 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6.1:2 -->These regions have regular tessellation so the U/V/W domain can be remapped as desired<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6.1:2 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6.1:3 -->**Tri vs Quad Density Comparison**<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6.1:3 --></ins>

- Consider a square quad patch with side lengths of 1, so area is 1 unit square

- Suppose this is adjacent to an equilateral tri patch, so area is 0.433

- Given equal TF, a tri patch produces significantly higher triangle/point density than quad patch

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6.1:4 -->Note this is true even with no tessellation, e.g. TF==1<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6.1:4 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6.1:4 -->Scaling insideTFs by (empirically) around 0.74 vs edges on tri patches will make their triangle and point density roughly match quad patches, across the TF range (except at very low TF where nothing can be done)<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6.1:4 --></ins>

- The adjustment would be different for different aspect ratios

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6.1:4 -->In applications mixing tri and quad patches, tri patches tend to be rare, so this density disparity may be a don’t care<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6.1:4 --></ins>

<a id="frame-side-triangulation"></a>

#### Triangulating Picture Frame Sides

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6.2:0 -->Each trapezoid shaped picture frame side has:<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6.2:0 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6.2:0 -->an outside edge TessFactor<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6.2:0 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6.2:0 -->an inside edge TessFactor<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6.2:0 --></ins>

    - where one segment on each end of the inside is not needed since the neighboring picture frame is there - thus trapezoid shape

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6.2:0 -->Each vertex on the edge with the larger TessFactor connects to its "parent" vertex on the edge with the smaller TF, given the "ruler function" split history<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6.2:0 --></ins>

- This defines a row of quads

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6.2:0 -->Plus a triangle at each end, making a trapezoid<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6.2:0 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.6.2:0 -->The quads are triangulated using previous diagonal rules<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.6.2:0 --></ins>

<a id="integer-partitioning"></a>

#### Integer Partitioning

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.7:0 -->Given floating point edge TessFactors<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.7:0 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.7:0 -->Application can, for example, determine the inside TF based on a min/max/avg reduction similar to fractional tessellation<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.7:0 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.7:0 -->HW then rounds each edge TF and inside TF up to next integer<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.7:0 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.7:0 -->Rest of tessellation behavior same as fractional<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.7:0 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.7:0 -->Including picture frame, allowing transitions<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.7:0 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.7:0 -->Each edge and inside TF can independently be even or odd<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.7:0 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.7:0 -->Thus smaller jumps in vert/tri count vs fractional<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.7:0 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.7:0 -->But vertex positions obviously don’t move smoothly<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.7:0 --></ins>

<a id="pow2-partitioning"></a>

#### Pow2 Partitioning

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.7.1:0 -->Same as integer partitioning, except instead of rounding to integer, round to next power of 2<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.7.1:0 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.7.1:0 -->Application (or HLSL compiler) is responsible for rounding to pow2, not hardware. Hardware just treats pow2 mode exactly like integer mode.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.7.1:0 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.7.1:0 -->Pow2 isn’t just a subset of the integer mode, when the inside TessFactor reduction is "average"<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.7.1:0 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.7.1:0 -->Handy to call this mode out on its own anyway<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.7.1:0 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.7.1:0 -->As TessFactors increase, once a point shows up on the domain, it stays there permanently<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.7.1:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.7.1:1 -->**Example: Displacement Mapping**<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.7.1:1 --></ins>

- Can achieve displacement mapping with dynamically variable TessFactors per edge with no vertex swimming or popping

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.7.1:2 -->This is enabled by using Pow2 partitioning with "max" for reduction to determine single inside TessFactor.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.7.1:2 --></ins>

- Take advantage of the properties that result:

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.7.1:2 -->For quads, choosing a single inside TessFactor instead of 2 ensures that points on patch inside always show up bisecting an edge, and once they show up they don’t move. This property always holds for tri patches, which only support a single inside TessFactor.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.7.1:2 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.7.1:2 -->Water-tight dampening of displacement can be done on edges and corners of patch by not looking anywhere else on the patch or the neighboring patches<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.7.1:2 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.7.1:2 -->Transition "picture frame" can unfortunately have triangle diagonals flipping as TessFactors change, so appropriate dampening of displacements is needed to hide diagonal flips<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.7.1:2 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.7.1:2 -->Using "max" reduction for inside TF means inside TF >= edge TFs, and there are always enough vertices on the patch inside to smoothly connect to whatever choice of displacement was made on the edges<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.7.1:2 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.7.1:2 -->Not trivial shader code to be totally pop-free<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.7.1:2 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.7.1:2 -->The type of underlying surface formulation (before displacement) could make task harder/impossible<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.7.1:2 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.7.1:2 -->Could take shortcuts and live with some popping<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.7.1:2 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.7.1:2 -->Could also do this smooth geomorphing with integer partitioning, using the U/V domain coordinate in the Domain Shader to identify the current point. Then completely redistribute the points ignoring where the U/V domain coordinate said each point would be on the domain, instead lumping points at pow2 divisions. With a non-pow2 TessFactor, just start filling in points using spacing for the next power of 2, filling in the gaps between the existing points that are partitioned by the previous powers of 2. This could potentially give smoother geometry increases versus complete pow2 jumps.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.7.1:2 --></ins>

<a id="isoline-pattern"></a>

#### IsoLine Pattern Details

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.8:0 -->A way to draw tessellated lines<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.8:0 --></ins>

- 2 Tessellation Factors

- Line Detail TF

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.8:0 -->Determines how to finely tessellate a line, with same controls (fractional, integer etc) as an edge has in tri or quad domains<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.8:0 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.8:0 -->Line Density TF<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.8:0 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.8:0 -->Determines how many parallel tessellated lines to draw<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.8:0 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.8:0 -->Always rounded up to next integer<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.8:0 --></ins>

  - <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.8:0 -->Tessellated lines of constant V are drawn over a UV quad domain<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.8:0 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.8:0 -->Line Density TF == 1 means: Draw a single tessellated line, where V==0 across U [0..1]<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.8:0 --></ins>

- Lines density TF == 2 means: Draw 2 tessellated lines, one having V==0, and the other having V== 0.5

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.8:0 -->Line density TF == n means: Draws n tessellated lines<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.8:0 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.8:0 -->A tessellated line is never drawn at V==1<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.8:0 --></ins>

<a id="tessellation-ordering"></a>

#### Primitive Ordering

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.9:0 -->The order that geometry is generated for a patch must be repeatable on a device, however no particular ordering of the geometry within a patch is prescribed. A strict requirement is that all geometry for a given patch flows down the pipeline before any geometry for subsequent patches.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.9:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.9:1 -->Suppose the rasterizer is the next active stage in the pipeline after tessellation, and there are vertex attributes that are declared in the Pixel Shader with constant interpolation. The leading vertex, used to provide the constant attribute for any individual line or triangle, can be any of the vertices in the line or triangle (albeit repeatable for a given patch and tessellator configuration on a device).<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.9:1 --></ins>

<a id="tessellated-primitive-id"></a>

#### Tessellator PrimitiveID

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.9.1:0 -->When a patch topology is used, [PrimitiveID](vertex-processing.md#primitive-id) identifies which patch in the Draw*() call is being processed, starting from the Hull Shader onward. Even though tessellation may produce multiple points/lines/triangles, for a given patch, all of the primitives generated for it have the same PrimitiveID. As such, the freedom of point/line/triangle ordering within a patch is not visible to shader code. When a patch topology is used, the true "primitive" is the patch itself.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.9.1:0 --></ins>

<a id="tessellation-factor-interpretation"></a>

#### TessFactor Interpretation

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.10:0 -->The TessFactor number space roughly corresponds to how many line segments there are on the corresponding edge. This isn’t a precise definition of the number of segments because different tessellation modes snap to different numbers of segments (i.e. integer versus fractional_even versus fractional_odd).<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.10:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.10:1 -->For integer partitioning, TessFactor range is [1 ... 64] (fractions rounded up).<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.10:1 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.10:2 -->For pow2 partitioning, TessFactor range is [1,2,4,8,16,32,64]. Anything outside or in between values in this set is rounded to the next entry in the set by HLSL code... so from the hardware point of view, pow2 partitioning technically isn't different from integer partitioning.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.10:2 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.10:3 -->For fractional odd partitioning, TessFactor range is [1 ... 63]. Odd TessFactors produce uniform partitioning of the space. Other TessFactors in the range produce a segment count that is the next odd TessFactor higher, transitioning the point locations based on the distance between the nearest lower odd TessFactor and nearest greater odd TessFactor.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.10:3 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.10:4 -->For fractional even tessellation, TessFactor range is [2 ... 64]. Even TessFactors produce uniform partitioning of the space. Other TessFactors in the range produce a segment count that is the next even TessFactor higher, transitioning the point locations based on the distance between the nearest lower even TessFactor and nearest greater even TessFactor.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.10:4 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.10:5 -->For the IsoLine domain, the line detail TessFactor honors all the above modes. However the line density TessFactor always behaves as integer – [1 ... 64] (fractions rounded to next).<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.10:5 --></ins>

<a id="declared-factor-clamp"></a>

#### HS MaxTessFactor Declaration

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.11.1:0 -->This particular clamp on TessFactors is discussed [here](#maximum-tessellation-factor), and is independent of the hardware clamps defined in the rest of this section.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.11.1:0 --></ins>

<a id="edge-factor-clamping"></a>

#### Hardware Edge TessFactor Range Clamping

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.11.2:0 -->The following describes the float32 patch edge TessFactor range that the hardware Tessellator must accept from the Hull Shader.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.11.2:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.11.2:1 -->First of all, if any edge TessFactor is <= 0 or NaN, the patch is culled.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.11.2:1 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.11.2:2 -->Otherwise, hardware must clamp each edge input TessFactor to the range specified below.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.11.2:2 --></ins>

<!-- d3d12-review-alert:begin:tessellation:STAGES-11.7.11.2:3:modified:migration-a529a6e934a1dc31-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Partitioning | Min Edge TessFactor | Max Edge TessFactor | Comments |
> | --- | --- | --- | --- |
> | Even_Fractional | 2 | 64 |  |
> | Odd_Fractional | 1 | 63 |  |
> | Integer (Pow2 maps to integer in hardware) | 1 | 64 | After clamping, round result to next integer. |

<!-- d3d12-review-alert:end:tessellation:STAGES-11.7.11.2:3:modified:migration-a529a6e934a1dc31-0 -->

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.11.2:4 -->For IsoLines, the LineDensity Tessfactor (which is how many constant V iso-lines to draw) is clamped by the hardware to [1...64] and rounded to the next integer.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.11.2:4 --></ins>

<a id="inside-factor-clamping"></a>

#### Hardware Inside TessFactor Range Clamping

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.11.3:0 -->In addition to patch edge TessFactors, hardware will be given inside TessFactors from the Hull Shader. There are two inside TessFactors for quad patches (U and V axes), and one inside TessFactor for tri patches.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.11.3:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.11.3:1 -->These HS outputs may have been derived (optionally) from the edge TessFactors via some operation such as max or avg in Hull Shader code autogenerated by HLSL. This derivation may involve low TessFactor fixups to prevent popping as TessFactors transition through extreme cases. Such processing is just shader code, irrelevant to the hardware.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.11.3:1 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.11.3:2 -->For the final inside TessFactors coming out of the Hull Shader, the following is pseudocode for the hardware validation hardware must do, effectively creating safe bounds on the complexity of cases the hardware tessellation algorithm has to handle.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.11.3:2 --></ins>

```cpp
    // Compute HWInsideTessFactorU/V for quad patch (similar tri patch case has only one axis),
    // given HSOutputInsideTessFactorU/V + 4 edge TessFactors.
    // This is just the fixed function hardware processing, independent of shader pre-conditioning
    // of the TessFactors (which the hardware does not need to know about).
    float lowerBound, upperBound;
    switch(partitioning)
    {
        case integer:
        case pow2: // don’t care about pow2 distinction for validation, just treat as integer
            lowerBound = 1;
            upperBound = 64;
            break;

        case even_fractional:
            lowerBound = 2;
            upperBound = 64;
            break;

        case odd_fractional:
    #define EPSILON 0.0000152587890625 // 2^(-16), min positive fixed point fraction
            if( any TessFactor, edge or inside is greater than (1.0 + EPSILON/2) )
            {
                // If any Tessfactor will be > 1 after rounding during
                // the float to fixed point conversion that happens later
                // then make all inside TessFactors > 1.
                lowerBound = 1.0 + EPSILON;
            }
            else // all are <= 1.0f or NaN
            {
                lowerBound = 1;
            }
            upperBound = 63;
            break;
    }

    HWInsideTessFactorU = min( upperBound, max( lowerBound, HSOutputInsideTessFactorU ) );
    HWInsideTessFactorV = min( upperBound, max( lowerBound, HSOutputInsideTessFactorV ) );
    // A tri patch only has one insideTessFactor instead of U/V
    // Note the above clamps map NaN to lowerBound based on D3D/IEEE754R min/max rules

    if( integer or pow2 partitioning )
    {
         round HWInsideTessFactorU to next integer (don’t care about pow2 distinction for validation)
         round HWInsideTessFactorV to next integer
         // tri patch only has one insideTessFactor instead of U/V
    }

    // After this, all TessFactors are converted to .16 fixed point using D3D float->fixed
    // conversion rules (incl round-to-nearest-even).  Topology and domain coordinate placement
    // is done based on the fixed point TessFactors.
```

<a id="tessellation-culling"></a>

#### Culling Patches

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.12:0 -->If any of the edge TessFactors from the HS for a patch are <= 0 or NaN, the patch is culled. No Domain Shader invocations or anything later in the pipeline are produced for that patch.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.12:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.12:1 -->Routing of untessellated patches is defined by [tessellation stage selection](#tessellation-enablement).<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.12:1 --></ins>

<a id="tessellation-watertightness"></a>

#### Tessellation Parameterization and Watertightness

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.13:0 -->A shared edge has to generate identical domain locations for crack free tessellation to be possible. Domain Shader authors are responsible for achieving this, given some guarantees from the hardware. First, hardware tessellation on any given edge must always produce a distribution of domain points symmetric about the edge based on the TessFactor for that edge alone. Second, the parameterization of each domain point (U/V for quad or U/V/W for tri) must produce “clean” values in the space [0.0 ... 1.0]. “Clean” means that given a domain point on one side of the edge, with the parameter for that edge (say it is U) in [0 ... 0.5], the mirrored domain point produced on the other side, call it U' in [0.5 ... 1.0] will have a complement satisfying (1-U') == U exactly.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.13:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.13:1 -->Even if a neighboring patch sharing an edge happens to produce a complementary parameterization (U moving in the other direction, and/or U/V swapped), both side’s parameterization for each shared edge domain point will be equivalent because they are clean.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.13:1 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.13:2 -->Having clean parameterization means that DS authors can write domain point evaluation algorithms with a carefully constructed order of operations that is guaranteed to produce the same result even if the control points for the patch are traversed in reverse order and/or with the parameter space complemented.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.13:2 --></ins>

<a id="tessellation-precision"></a>

#### Tessellation Precision

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.14:0 -->Tessellator input float32 TessFactor values are immediately converted to fixed point. Note this is after float processing of TessFactors, such as Inside TessFactor derivation has been done by HLSL generated shader code in HS Patch Constant Fork or Join Phases. Once the final TessFactors have been converted to fixed point, all remaining tessellator arithmetic (computing domain locations), is performed using fixed point arithmetic with 16 bits of fraction. The last step in domain point coordinate calculation is to convert the coordinates back to float32 for input to the Domain Shader.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.14:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.14:1 -->The fact that output U/V/W [domain coordinates](../archive/D3D11_3_FunctionalSpec.htm#generatedvalue_DOMAIN) have been quantized to 16 bit fixed point means there is a uniform spacing of representable values across the [0...1] range. This uniform spacing facilitates the symmetry and watertightness issues discussed above.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.14:1 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.14:2 -->Due to the fixed point arithmetic involved, it is possible for the tessellator to produce degenerate lines or triangles, where each vertex has identical domain coordinates. This will not be visible if the primitives are sent to the rasterizer, because they will be culled. However, if the Geometry Shader and/or Stream Output are enabled, the degenerate primitives will appear, and it is the application’s responsibility to be robust to this. For example, Geometry Shader code could check for and discard degenerates if that turns out to be the only way to avoid the algorithm being used from falling over on the degenerate input.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.14:2 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.14:3 -->If the Tessellator’s output primitive is points (as opposed to triangles or lines), this scenario requires only unique points within a patch to be generated. The one exception is points that are on the threshold of merging, if TessFactors were to incrementally decrease, may appear in the system as duplicated points (with the same U/V coords) in an implementation dependent way.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.14:3 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.14:4 -->What does 16-bit fixed point math for the domain coordinate generation mean?<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.14:4 --></ins>

Suppose a single patch is drawn 64 meters wide.

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.14:6 -->There is enough precision to place points at 2 mm resolution.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.14:6 --></ins>

<a id="tessellator-state"></a>

#### Tessellator State Specified Via Hull Shader Declarations

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.15:0 -->[Input Control Point Count](../archive/D3D11_3_FunctionalSpec.htm#inst_DCL_INPUT_CONTROL_POINT_COUNT) (DXBC): {1...32}<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.15:0 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.15:0 -->[Output Control Point Count](../archive/D3D11_3_FunctionalSpec.htm#inst_DCL_OUTPUT_CONTROL_POINT_COUNT) (DXBC): {0...32}; DXIL output control point counts are 1 through 32<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.15:0 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.15:0 -->[Domain](../archive/D3D11_3_FunctionalSpec.htm#inst_DCL_TESSELLATOR_DOMAIN): {tri | quad | isoline}<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.15:0 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.15:0 -->[Partitioning](../archive/D3D11_3_FunctionalSpec.htm#inst_DCL_TESSELLATOR_PARTITIONING): {integer | pow2 | fractional_odd | fractional_even}<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.15:0 --></ins>

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.15:0 -->[Output Primitive (Topology)](../archive/D3D11_3_FunctionalSpec.htm#inst_DCL_TESSELLATOR_OUTPUT_PRIMITIVE): {point | line | triangle_cw | triangle_ccw}<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.15:0 --></ins>
 // Point can be used with any domain (IsoLine,Tri,Quad)
 // Line is only valid with the IsoLine domain
 // Triangle (CW or CCW) are only valid with Tri or Quad domains.

- <ins><!-- d3d12-review-inline:begin:tessellation:STAGES-11.7.15:0 -->[MaxTessFactor](../archive/D3D11_3_FunctionalSpec.htm#inst_DCL_MAX_TESSFACTOR): {1..64} // Clamp placed on all TessFactors coming out of the Hull Shader.<!-- d3d12-review-inline:end:tessellation:STAGES-11.7.15:0 --></ins>

<a id="domain-shader"></a>

## Domain shader

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-12.1:0 -->The DXBC Domain Shader instruction set is listed in the [instruction reference](../archive/D3D11_3_FunctionalSpec.htm#DSInstructionSet).<!-- d3d12-review-inline:end:tessellation:STAGES-12.1:0 --></ins>

<a id="domain-inputs"></a>

### Domain shader inputs

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-12.2:0 -->Inputs for this stage are the 2D or 3D [domain location](../archive/D3D11_3_FunctionalSpec.htm#generatedvalue_DOMAIN) generated by the [tessellator](#tessellation) and all of the data generated by the [Hull Shader](#hull-shader). This latter data is visible to all domain points in a patch. In all other ways this shader is effectively analogous to a [Vertex Shader](vertex-processing.md#vertex-processing).<!-- d3d12-review-inline:end:tessellation:STAGES-12.2:0 --></ins>

<a id="domain-invocation"></a>

### Domain Shader Invocation

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-12.2.1:0 -->The Domain Shader can see all the data output by the control point and patch constant computations of the Hull Shader, as well as the domain location of a particular point. The Domain Shader is invoked for every domain location generated by the Tessellator.<!-- d3d12-review-inline:end:tessellation:STAGES-12.2.1:0 --></ins>

<a id="domain-logical-interfaces"></a>

### DXBC domain stage interface

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-12.2.2:0 -->The following registers are available in the ds_5_0 model.<!-- d3d12-review-inline:end:tessellation:STAGES-12.2.2:0 --></ins>

<!-- d3d12-review-alert:begin:tessellation:STAGES-12.2.2:1:modified:migration-df36b61e2b02de2d-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Register Type | Count | r/w | Dimension | Indexable by r# | Defaults | Requires DCL |
> | --- | --- | --- | --- | --- | --- | --- |
> | 32-bit Input Control Points (v**cp**[vertex][element]) | 32, see [control point and patch constant inputs](#domain-cp-pc-inputs) | r | 4(component)*32(element)*32(vert) | Y | None | Y |
> | 32-bit Input Patch Constants (v**pc**[element]) | 32, see [control point and patch constant inputs](#domain-cp-pc-inputs) | r | 4 | Y | None | Y |
> | 32-bit input location in domain ([vDomain](../archive/D3D11_3_FunctionalSpec.htm#generatedvalue_DOMAIN).xy, [vDomain](../archive/D3D11_3_FunctionalSpec.htm#generatedvalue_DOMAIN).xyz) | 1 | r | 3 | N | n/a | Y |
> | 32-bit UINT Input PrimitiveID (vPrim) | 1 | r | 1 | N | n/a | Y |
> | **Output Registers:** |  |  |  |  |  |  |
> | 32-bit output Vertex Data Element (o#) | 32 | w | 4 | Y | None | Y |

<!-- d3d12-review-alert:end:tessellation:STAGES-12.2.2:1:modified:migration-df36b61e2b02de2d-0 -->

<a id="domain-cp-pc-inputs"></a>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-12.2.2:3 -->**Control point and patch constant inputs.** The domain shader sees the Hull Shader outputs in 2 separate sets of registers. The v**cp** registers can see all of the Hull Shader’s output **C**ontrol **P**oints. The v**pc** registers can see all of the Hull Shader’s **P**atch **C**onstant output data.<!-- d3d12-review-inline:end:tessellation:STAGES-12.2.2:3 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-12.2.2:4 -->Since code for Hull Shader Patch Constant Fork or Join Phases output TessFactors using names such as SV_TessFactor, the DS must match those declarations on the equivalent v**pc** input if it wishes to see those values.<!-- d3d12-review-inline:end:tessellation:STAGES-12.2.2:4 --></ins>

<a id="domain-system-values"></a>

### System Generated Values in the Domain Shader

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-12.2.3:0 -->[InstanceID](vertex-processing.md#instance-id) and [VertexID](vertex-processing.md#vertex-id) can be input as long as the Hull Shader outputs these values (per-Control Point).<!-- d3d12-review-inline:end:tessellation:STAGES-12.2.3:0 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-12.2.3:1 -->The domain location is another System Generated Value, appearing in its own input register ([vDomain](../archive/D3D11_3_FunctionalSpec.htm#generatedvalue_DOMAIN)).<!-- d3d12-review-inline:end:tessellation:STAGES-12.2.3:1 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-12.2.3:2 -->The final set of System Values are the various TessFactors produced by the Hull Shader, discussed [elsewhere](#tessellation-factor-output). These can be declared as input out of part of the input Patch Constant (vpc) registers.<!-- d3d12-review-inline:end:tessellation:STAGES-12.2.3:2 --></ins>

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-stage-semantics:0:authored:migration-e61f3a8db17cb7ff-0 -->In the domain shader, tessellator domain coordinates are exposed through `SV_DomainLocation`, and patch identity through `SV_PrimitiveID`. The register names in the logical-interface tables are DXBC representation, not additional API bindings.<!-- d3d12-review-inline:end:tessellation:STAGES-stage-semantics:0:authored:migration-e61f3a8db17cb7ff-0 --></ins>

<a id="programmable-geometry-driver"></a>

## Driver responsibilities

<ins><!-- d3d12-review-inline:begin:tessellation:STAGES-driver-contract:0:authored:migration-fd13d7bc6ab2b9e6-0 -->The [pipeline state driver aggregate](pipeline-state.md#driver) selects the vertex, hull and domain shaders. They are not independently bound on the command list.<!-- d3d12-review-inline:end:tessellation:STAGES-driver-contract:0:authored:migration-fd13d7bc6ab2b9e6-0 --></ins>
