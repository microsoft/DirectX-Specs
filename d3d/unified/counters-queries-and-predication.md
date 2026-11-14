<a id="counters-queries-predication"></a>

# Counters, queries, and predication

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

<ins><!-- d3d12-review-inline:begin:queries:N-overview:0:authored:migration-0d3a2220c5cb6256-0 -->Queries measure GPU work and expose typed results through query heaps. Predication consumes an application-selected 64-bit buffer value to condition eligible GPU operations. It is not a query object binding. Application-managed SO/UAV counters, query results and predicate values have different storage, widths and lifetime contracts.<!-- d3d12-review-inline:end:queries:N-overview:0:authored:migration-0d3a2220c5cb6256-0 --></ins>

<a id="application-counters"></a>

## Application-managed counters

<ins><!-- d3d12-review-inline:begin:queries:N-resource-operations-counter-consumer:0:authored:migration-a04cc6b70bc49917-0 -->Ordinary [counter backing byte copy/clear interactions](resource-operations.md#counter-interactions) do not implicitly operate on a separately associated counter resource. Query/counter/predicate distinctions and each operation's policy remain canonical in this chapter.<!-- d3d12-review-inline:end:queries:N-resource-operations-counter-consumer:0:authored:migration-a04cc6b70bc49917-0 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:CQ-so-counter-concept:0 -->The application is responsible for allocating storage for a 32-bit
quantity called the BufferFilledSize. This contains the number of bytes
of data in the <!-- d3d12-review-inline:end:queries:CQ-so-counter-concept:0 --></ins><ins><!-- d3d12-review-inline:begin:queries:STYLE-O3:0:preserved-repair:buffer-stage-name -->stream output<!-- d3d12-review-inline:end:queries:STYLE-O3:0:preserved-repair:buffer-stage-name --></ins><ins><!-- d3d12-review-inline:begin:queries:CQ-so-counter-concept:1 --> buffer. This storage may be placed in the resource containing the <!-- d3d12-review-inline:end:queries:CQ-so-counter-concept:1 --></ins><ins><!-- d3d12-review-inline:begin:queries:STYLE-O3:1:preserved-repair:data-stage-name -->stream output<!-- d3d12-review-inline:end:queries:STYLE-O3:1:preserved-repair:data-stage-name --></ins><ins><!-- d3d12-review-inline:begin:queries:CQ-so-counter-concept:2 --> data or in a different resource. This
value is accessed by the GPU in the <!-- d3d12-review-inline:end:queries:CQ-so-counter-concept:2 --></ins><ins><!-- d3d12-review-inline:begin:queries:STYLE-O3:2:preserved-repair:stage-name -->stream output<!-- d3d12-review-inline:end:queries:STYLE-O3:2:preserved-repair:stage-name --></ins><ins><!-- d3d12-review-inline:begin:queries:CQ-so-counter-concept:3 --> stage to determine
where to append new vertex data in the buffer. Additionally, this value
is accessed by the GPU to determine when overflow has occurred.<!-- d3d12-review-inline:end:queries:CQ-so-counter-concept:3 --></ins>

The application is responsible for allocating 32-bits of storage for UAV
counters. This storage can be allocated in a different resource <ins><!-- d3d12-review-inline:begin:queries:CQ-uav-counter-concept:0:modified:source-39cedf7afe362e11-0-0 -->from<!-- d3d12-review-inline:end:queries:CQ-uav-counter-concept:0:modified:source-39cedf7afe362e11-0-0 --></ins> the
one that contains data accessible via the UAV.

<ins><!-- d3d12-review-inline:begin:queries:N-counter-owners:0:authored:migration-e2ece0e54a6dc33e-0 -->[SO filled size storage and append](geometry-shaders-and-stream-output.md#filled-size) define capture progress. [Counter-bearing UAV creation](binding.md#buffer-uav) defines UAV counter association and access. Neither query heap creation nor command list reset initializes those application buffers. A 32-bit counter is not automatically a valid zero-extended 64-bit predicate: the predicate consumes all eight selected bytes.<!-- d3d12-review-inline:end:queries:N-counter-owners:0:authored:migration-e2ece0e54a6dc33e-0 --></ins>

<a id="query-heaps"></a>

## Query heaps and result types

In D3D 12, queries are grouped into arrays of queries called a query
heap. A query heap has a type which defines the valid types of queries
that can be used with that heap.

<a id="d3d12_query_heap_type"></a>

### D3D12_QUERY_HEAP_TYPE

```cpp
typedef enum D3D12_QUERY_HEAP_TYPE
{
    D3D12_QUERY_HEAP_TYPE_OCCLUSION                            = 0,
    D3D12_QUERY_HEAP_TYPE_TIMESTAMP                            = 1,
    D3D12_QUERY_HEAP_TYPE_PIPELINE_STATISTICS                  = 2,
    D3D12_QUERY_HEAP_TYPE_SO_STATISTICS                        = 3,
    D3D12_QUERY_HEAP_TYPE_VIDEO_DECODE_STATISTICS              = 4,
    D3D12_QUERY_HEAP_TYPE_COPY_QUEUE_TIMESTAMP                 = 5,
    D3D12_QUERY_HEAP_TYPE_PIPELINE_STATISTICS1                 = 7,
} D3D12_QUERY_HEAP_TYPE;
```

<a id="d3d12_query_heap_desc"></a>

### D3D12_QUERY_HEAP_DESC

```cpp
typedef struct D3D12_QUERY_HEAP_DESC
{
    D3D12_QUERY_HEAP_TYPE Type;
    UINT Count;
    UINT NodeMask;
} D3D12_QUERY_HEAP_DESC;
```

`Type`

Specifies one member of [D3D12_QUERY_HEAP_TYPE](#d3d12_query_heap_type).

`Count`

Specifies the number of queries the heap should contain.

`NodeMask`

For single GPU operation, set this to zero. If there are multiple GPU nodes, set a bit to identify the node (the device's physical adapter) to which the query heap applies. Each bit in the mask corresponds to a single node. Only 1 bit must be set. Refer to [Multi-adapter systems](devices-and-capabilities.md#identity).

<a id="d3d12_query_type"></a>

### D3D12_QUERY_TYPE

```cpp
typedef enum D3D12_QUERY_TYPE
{
    D3D12_QUERY_TYPE_OCCLUSION                      = 0,
    D3D12_QUERY_TYPE_BINARY_OCCLUSION               = 1,
    D3D12_QUERY_TYPE_TIMESTAMP                      = 2,
    D3D12_QUERY_TYPE_PIPELINE_STATISTICS            = 3,
    D3D12_QUERY_TYPE_SO_STATISTICS_STREAM0          = 4,
    D3D12_QUERY_TYPE_SO_STATISTICS_STREAM1          = 5,
    D3D12_QUERY_TYPE_SO_STATISTICS_STREAM2          = 6,
    D3D12_QUERY_TYPE_SO_STATISTICS_STREAM3          = 7,
    D3D12_QUERY_TYPE_VIDEO_DECODE_STATISTICS        = 8,
    D3D12_QUERY_TYPE_PIPELINE_STATISTICS1           = 10,
} D3D12_QUERY_TYPE;
```

<a id="d3d12_query_heap_flags"></a>

### D3D12_QUERY_HEAP_FLAGS

```cpp
typedef enum D3D12_QUERY_HEAP_FLAGS
{
    D3D12_QUERY_HEAP_FLAG_NONE = 0,
    D3D12_QUERY_HEAP_FLAG_CPU_RESOLVE = 1,

} D3D12_QUERY_HEAP_FLAGS;
```

<ins><!-- d3d12-review-inline:begin:queries:N-heap-model:0:authored:migration-7f676cb5cb90607d-0 -->The query type/node selection must be valid and `Count` must be positive. `ID3D12QueryHeap` is opaque pageable storage, not a resource exposing application-readable raw query bytes. Creating a heap does not perform its queries. A query element must have been produced before it is resolved. The [CPU-resolve flag](#cpu-resolution) chooses the CPU result retrieval path. An ordinary heap uses command list resolution.<!-- d3d12-review-inline:end:queries:N-heap-model:0:authored:migration-7f676cb5cb90607d-0 --></ins>

<a id="query-support"></a>

### Query issuance and completion

<!-- d3d12-review-alert:begin:queries:N-support-table:0:authored:migration-b0e5d81287117c91-0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Query | Heap | Issuing command list types | Completion |
> |---|---|---|---|
> | `OCCLUSION`, `BINARY_OCCLUSION` | `OCCLUSION` | DIRECT | Begin/End interval |
> | `TIMESTAMP` | `TIMESTAMP` | DIRECT, COMPUTE, VIDEO_DECODE, VIDEO_PROCESS, VIDEO_ENCODE | End only |
> | `TIMESTAMP` | `COPY_QUEUE_TIMESTAMP` | COPY, with `OPTIONS3.CopyQueueTimestampQueriesSupported` | End only |
> | `PIPELINE_STATISTICS` | `PIPELINE_STATISTICS` | DIRECT | Begin/End interval |
> | `PIPELINE_STATISTICS1` | `PIPELINE_STATISTICS1` | DIRECT, with `OPTIONS9.MeshShaderPipelineStatsSupported` | Begin/End interval |
> | `SO_STATISTICS_STREAM0` through `STREAM3` | `SO_STATISTICS` | DIRECT | Begin/End interval |
> | `VIDEO_DECODE_STATISTICS` | `VIDEO_DECODE_STATISTICS` | VIDEO_DECODE | End only; latest decode in the same list |

<!-- d3d12-review-alert:end:queries:N-support-table:0:authored:migration-b0e5d81287117c91-0 -->

<ins><!-- d3d12-review-inline:begin:queries:N-support-table:1:authored:migration-e41ea359c8fde806-0 -->No query type is supported in BUNDLE recordings. Timestamp and video decode statistics are both End-only. Video BeginQuery declarations do not introduce a supported interval query type.<!-- d3d12-review-inline:end:queries:N-support-table:1:authored:migration-e41ea359c8fde806-0 --></ins>

<a id="result-layout"></a>

### Result layout

<!-- d3d12-review-alert:begin:queries:N-result-layout:0:authored:migration-3baca98cb04c2786-0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Query | Result per element | Record size |
> |---|---|---|
> | Occlusion | `UINT64` sample count | 8 bytes |
> | Binary occlusion | `UINT64`, exactly 0 or 1 | 8 bytes |
> | Timestamp | `UINT64` GPU ticks | 8 bytes |
> | Pipeline statistics | `D3D12_QUERY_DATA_PIPELINE_STATISTICS` | 88 bytes |
> | Extended pipeline statistics | `D3D12_QUERY_DATA_PIPELINE_STATISTICS1` | 112 bytes |
> | Each SO stream | `D3D12_QUERY_DATA_SO_STATISTICS` | 16 bytes |
> | Video decode statistics | `D3D12_QUERY_DATA_VIDEO_DECODE_STATISTICS` | 32 bytes, including structure padding |

<!-- d3d12-review-alert:end:queries:N-result-layout:0:authored:migration-3baca98cb04c2786-0 -->

<ins><!-- d3d12-review-inline:begin:queries:N-result-layout:1:authored:migration-2c445b75e2fd8bdf-0 -->GPU resolution writes consecutive records beginning at an eight-byte-aligned destination offset. The destination range must contain every record without overflow. CPU resolution requires a correctly sized CPU output range for the same typed records.<!-- d3d12-review-inline:end:queries:N-result-layout:1:authored:migration-2c445b75e2fd8bdf-0 --></ins>

<a id="gpu-resolve-support"></a>

### GPU resolution support

<!-- d3d12-review-alert:begin:queries:N-resolve-support:0:authored:migration-cef3b3b791746ba4-0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Resolving list type | Permitted query heaps |
> |---|---|
> | DIRECT | OCCLUSION, TIMESTAMP, PIPELINE_STATISTICS, SO_STATISTICS, PIPELINE_STATISTICS1 |
> | COMPUTE | TIMESTAMP |
> | COPY | COPY_QUEUE_TIMESTAMP, with copy-timestamp support |
> | VIDEO_DECODE | TIMESTAMP, VIDEO_DECODE_STATISTICS |
> | VIDEO_PROCESS, VIDEO_ENCODE | TIMESTAMP |

<!-- d3d12-review-alert:end:queries:N-resolve-support:0:authored:migration-cef3b3b791746ba4-0 -->

<ins><!-- d3d12-review-inline:begin:queries:N-resolve-support:1:authored:migration-832b613c9efbb4ff-0 -->Issuance and resolution support are separate checks. A declaration alone does not authorize other query families on a list. A CPU-resolve heap cannot use this GPU operation.<!-- d3d12-review-inline:end:queries:N-resolve-support:1:authored:migration-832b613c9efbb4ff-0 --></ins>

<a id="query-lifecycle"></a>

## Query lifecycle and access

<!-- d3d12-review-alert:begin:queries:OI1-query-validation:0:authored:index-range-and-errors -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `BeginQuery` and `EndQuery` require an index within the query heap. For GPU `ResolveQueryData`, the complete range selected by `StartIndex` and `NumQueries` must lie within that heap. The core runtime validates the index/range, query type/heap/list compatibility, buffer destination, eight-byte destination alignment and output bounds. Recording failures follow the [command list error contract](execution.md#close).

<!-- d3d12-review-alert:end:queries:OI1-query-validation:0:authored:index-range-and-errors -->

Each individual element within a query heap can be start/stopped
separately.

<ins><!-- d3d12-review-inline:begin:queries:N-lifecycle:0:authored:migration-53a80be2a779f109-0 -->An interval query begins and ends at the same heap/index with the same query type. Its result is the measured interval, not a pair of already-resolved cumulative samples for the application to subtract. An active element cannot be begun again; different elements may be active concurrently without a global LIFO nesting requirement. Intervals do not span command list boundaries or Reset, and outstanding intervals must end before Close or a protected session change. End-only queries do not use BeginQuery.<!-- d3d12-review-inline:end:queries:N-lifecycle:0:authored:migration-53a80be2a779f109-0 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:N-lifecycle:1:authored:migration-21284217300583e1-0 -->The corresponding EndQuery must execute before a GPU resolve consumes that element. Resolving an incomplete or never-performed element is undefined and may hang or remove the device. An application must order reuse and resolution so it consumes the intended result rather than a later overwrite. Cross-queue dependencies and CPU consumption require the normal [fence/completion contract](execution.md#fence-operations). Heap and result buffer [lifetime](execution.md#lifetime) and [residency](resources.md#residency) remain application obligations.<!-- d3d12-review-inline:end:queries:N-lifecycle:1:authored:migration-21284217300583e1-0 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:N-query-access:0:authored:migration-b4eb9dfec2f8c6cb-0 -->With legacy resource states, GPU query result destinations require `D3D12_RESOURCE_STATE_COPY_DEST`; predicate reads require `D3D12_RESOURCE_STATE_PREDICATION`, an alias of `D3D12_RESOURCE_STATE_INDIRECT_ARGUMENT`. Enhanced barriers use the corresponding [COPY_DEST and PREDICATION access scopes](synchronization.md#barrier-access) and [synchronization scopes](synchronization.md#barrier-sync). Normal heap restrictions still apply. An UPLOAD heap is not a valid GPU resolve destination. Opaque query production followed by resolution on the same queue is ordered by the query commands themselves; no application resource barrier on the opaque query heap is required.<!-- d3d12-review-inline:end:queries:N-query-access:0:authored:migration-b4eb9dfec2f8c6cb-0 --></ins>

<a id="occlusion"></a>

## Occlusion results

<ins><!-- d3d12-review-inline:begin:queries:N-om-depth-bounds-owner:0:authored:migration-19bafa3b31e2fd1c-0 -->The [depth bounds algorithm and early/late side effect interface](output-merger.md#depth-bounds) are defined by Output merger and PS. The query result/counting definitions here remain canonical. [Render pass recording/access behavior](output-merger.md#render-pass-recording) does not redefine the predication operation matrix.<!-- d3d12-review-inline:end:queries:N-om-depth-bounds-owner:0:authored:migration-19bafa3b31e2fd1c-0 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:A-occlusion:0 -->The data associated with this Query Type is a UINT64. This value contains the number of multisamples which passed depth and stencil testing, also known as "visible" multisamples, for primitives in the measured query interval. If the rendertarget is not multisampled, then the counter, naturally is incremented by the number of whole pixels that are "visible". The counter should wrap around when it overflows.<!-- d3d12-review-inline:end:queries:A-occlusion:0 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:A-occlusion:1 -->For the purposes of calculating visible multisamples, disabled depth tests or stencil tests should behave as if the multisamples "passes" the disabled test. This produces equivalent results as if the test units were enabled with the test function set to "always". In addition, these values should be tabulated as normal even if there are no render targets bound. Since the Depth and Stencil tests logically occur in the Output Merger stage of the pipeline, pixels which are discarded during Pixel Shader execution, naturally, do not increment this counter. Discarded pixels, logically, do not even reach the Output Merger. There are pipeline configurations where the only effective results that are produced from the pipeline is the tabulation of the occlusion counter. This is intentional.<!-- d3d12-review-inline:end:queries:A-occlusion:1 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:A-occlusion:2 -->If [ForcedSampleCount](../archive/D3D11_3_FunctionalSpec.htm#ForcedSampleCount) is used (> 0) recall that the pass count reflects how many rasterizer samples are covered (independent of the output sample count). If SampleMask (which applies to the output) is configured to turn off output writes (or pixel discard, output coverage mask or alpha-to-coverage turns off all output samples), the count of samples recorded into the query may be either 0 or the number of rasterizer samples covered, as the specific behavior was never tightly specified. It is recommended for implementations to count 0 in this case for consistency with known implementations.<!-- d3d12-review-inline:end:queries:A-occlusion:2 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:N-occlusion-interval:0:authored:migration-232904a5bd2e0556-0 -->The returned occlusion value is the Begin/End interval result. Binary occlusion returns zero if no sample passed and one if any sample passed. Its upper 63 bits are zero. It does not encode a query readiness status or a 32-bit D3D11 predicate object.<!-- d3d12-review-inline:end:queries:N-occlusion-interval:0:authored:migration-232904a5bd2e0556-0 --></ins>

<a id="pipeline-statistics"></a>

## Pipeline statistics

<ins><!-- d3d12-review-inline:begin:queries:A-statistics-mechanism:0:modified:migration-d80279f569656cfa-0 -->Well-defined statistics for the Pipeline stages will be continuously calculated throughout the usage of the graphics accelerator. This typically indicates the need for hardware counters for each stage of the Pipeline. Such counters would be associated with the graphics context, so they require the ability to be context switched. Typically, drivers use the standard graphics Pipeline available on the graphics accelerator in order to implement some sort of functionality. For example, a Blt may actually be implemented as a textured quad rendering. In such a case, the graphics accelerator should not calculate statistics for such an operation. For example, such an emulated Blt operation should not appear to draw 2 triangles. This indicates the graphics accelerator needs to be able to toggle actual statistics calculation in an efficient manner. Most important, the graphics Pipeline should run at the same speed regardless of whether statistics are calculated or not; as the hardware counters will be expected to always be tabulating (except as previously mentioned, where the tabulation should be muted when performing emulation). The Pipeline statistics will be collected through the query interval and resolution mechanism. **Note that D3D12_QUERY_TYPE_OCCLUSION and the per-stream SO statistics queries are considered to be well-defined Pipeline statistics, even though they are kept separate from D3D12_QUERY_DATA_PIPELINE_STATISTICS.**<!-- d3d12-review-inline:end:queries:A-statistics-mechanism:0:modified:migration-d80279f569656cfa-0 --></ins>

```cpp
typedef struct D3D12_QUERY_DATA_PIPELINE_STATISTICS
{
    UINT64 IAVertices;
    UINT64 IAPrimitives;
    UINT64 VSInvocations;
    UINT64 GSInvocations;
    UINT64 GSPrimitives;
    UINT64 CInvocations;
    UINT64 CPrimitives;
    UINT64 PSInvocations;
    UINT64 HSInvocations;
    UINT64 DSInvocations;
    UINT64 CSInvocations;
} D3D12_QUERY_DATA_PIPELINE_STATISTICS;
```

<ins><!-- d3d12-review-inline:begin:queries:A-pipeline-statistics:0 -->The data associated with this Query Type is D3D12_QUERY_DATA_PIPELINE_STATISTICS. This structure contains statistics for each stage of the graphics Pipeline. For each stage, the value for number of invocations must fall between two numbers: infinite cache & no cache. The clipper will appear to behave as the GS. The clipper will execute for each triangle. For each invocation, 0 primitives will be generated if the original triangle is fully clipped, 1 primitive will be generated if the original triangle is not clipped at all (or the clipping results in only 1 triangle), 2 primitives will be generated if the original triangle were clipped and resulted in 2 triangles, etc. In typical configurations of the pipeline, GSPrimitives would be equal to CInvocations. If [rasterization is disabled](geometry-shaders-and-stream-output.md#so-rasterization) and the pipeline is configured to only send primitives to Stream Output, GSPrimitives would naturally deviate from CInvocations, since CInvocations would not increment.<!-- d3d12-review-inline:end:queries:A-pipeline-statistics:0 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:A-pipeline-statistics:1 -->The clipping stats will be flexible with regards to guard band implementations. So, when rendering triangles that extend beyond the viewport, clipping counts may fall within a range of values (numbers assuming an infinite guard band; and numbers assuming a tight clipping rect around the viewport).<!-- d3d12-review-inline:end:queries:A-pipeline-statistics:1 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:A-pipeline-statistics:2 -->The following examples illustrate the interaction between the IAVertices, IAPrimitives, and VSInvocations with respect to Post-VS caching<!-- d3d12-review-inline:end:queries:A-pipeline-statistics:2 --></ins>

- <ins><!-- d3d12-review-inline:begin:queries:A-pipeline-statistics:3 -->Draw Indexed Tri Strip of 4 prims (with all indices the same value): valid IAVertices only 6, valid IAPrimitives only 4, valid VSInvocations 1 - 12.<!-- d3d12-review-inline:end:queries:A-pipeline-statistics:3 --></ins>
- <ins><!-- d3d12-review-inline:begin:queries:A-pipeline-statistics:3 -->Draw Indexed Tri List of 4 prims (with all indices the same value): valid IAVertices only 12, valid IAPrimitives only 4, valid VSInvocations 1 - 12.<!-- d3d12-review-inline:end:queries:A-pipeline-statistics:3 --></ins>
- <ins><!-- d3d12-review-inline:begin:queries:A-pipeline-statistics:3 -->Draw Tri Strip of 4 prims: valid IAVertices only 6, valid IAPrimitives only 4, valid VSInvocations 6 - 12<!-- d3d12-review-inline:end:queries:A-pipeline-statistics:3 --></ins>
- <ins><!-- d3d12-review-inline:begin:queries:A-pipeline-statistics:3 -->Draw Tri List of 4 prims: valid IAVertices only 12, valid IAPrimitives only 4, valid VSInvocations only 12<!-- d3d12-review-inline:end:queries:A-pipeline-statistics:3 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:A-pipeline-statistics:4 -->Partial primitives will be allowed to fall within range of values, similar to the way vertex caching behaves. So, when partial primitives are possible, statistics should fall between a pipeline that clips them as soon as possible (before even the IA counts them), or as late as possible (post clipper/ pre-PS). Stream Output and a NULL GS is flexible as to whether it actually causes GS invocations to occur or not.<!-- d3d12-review-inline:end:queries:A-pipeline-statistics:4 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:A-pipeline-statistics:5 -->The value of PSInvocations may include or exclude [helper pixels](../archive/D3D11_3_FunctionalSpec.htm#PixelShaderDerivatives) for 2x2 stamps.<!-- d3d12-review-inline:end:queries:A-pipeline-statistics:5 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:A-pipeline-statistics:6 -->With respect to PSInvocations, early Depth/ Stencil optimizations may or may not prevent the work from the pixel shader from being realized. So, when pixels fail the depth tests, PSInvocations may or may not be incremented depending on where the Depth test is actually occurring in the pipeline. If the Pixel Shader outputs depth, then PSInvocations must increment as expected, even if the output depth fails.<!-- d3d12-review-inline:end:queries:A-pipeline-statistics:6 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:A-pipeline-statistics:7:authored:migration-35b2898e166c71a2-0 -->With respect to IAVertices and VSInvocations, adjacent vertex processing may be optimized out if the GS does not declare the adjacency vertices as inputs to the GS. So, when the GS does not declare adjacent vertices as inputs, IAVertices and VSInvocations may or may not reflect the work implied by the adjacent vertices. If the GS declares adjacent vertices, then the IAVertices should include the adjacent vertices (with no regard to any post-VS caching); and VSInvocations should include the adjacent vertices (along with any effects of post-VS caching).<!-- d3d12-review-inline:end:queries:A-pipeline-statistics:7:authored:migration-35b2898e166c71a2-0 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:A-pipeline-statistics:8:authored:migration-6cd14866ed2138b9-0 -->HSInvocations increments once per patch that causes the Hull Shader to run.<!-- d3d12-review-inline:end:queries:A-pipeline-statistics:8:authored:migration-6cd14866ed2138b9-0 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:A-pipeline-statistics:9 -->For the DSInvocations statistic, note that hardware may generate identical points in a patch multiple times in the course of tessellating the domain, and each repeated point counts as an additional DSInvocation. If the Tessellator's output primitive is points (as opposed to triangles or lines), that scenario requires only unique points within a patch to be generated, so the DSInvocations count will increment by exactly the number of unique points tessellated for the patch. The one exception is points that are on the threshold of merging, if TessFactors were to incrementally decrease, may appear in the system as duplicated points (with the same U/V coords) in an implementation dependent way.<!-- d3d12-review-inline:end:queries:A-pipeline-statistics:9 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:A-pipeline-statistics:10 -->CSInvocations: For example, if a Compute Shader is declared with a thread group size of (3,4,5), a Dispatch(2,1,1) call would increment the CSInvocations value by 3*4*5*2*1*1=120.<!-- d3d12-review-inline:end:queries:A-pipeline-statistics:10 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:A-pipeline-statistics:11 -->CSInvocations must honor Compute Shader invocations from Dispatch and from compute dispatch actions executed by ExecuteIndirect.<!-- d3d12-review-inline:end:queries:A-pipeline-statistics:11 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:A-pipeline-statistics:12 -->Since the Compute Shader honors predicated rendering, if a Dispatch call or an ExecuteIndirect compute dispatch action is predicated off, then CSInvocations will not increment, given the Compute Shader will not be invoked.<!-- d3d12-review-inline:end:queries:A-pipeline-statistics:12 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:N-pipeline-field-units:1:authored:migration-55472c86cfa5f4ad-0 -->Pixel shader invocation counts are not counts of visible depth samples or unique output pixels. Helper invocations, early depth/stencil, per-sample shading and coarse shading affect that relationship. A historical per-pixel test inequality is not a universal modern pipeline contract.<!-- d3d12-review-inline:end:queries:N-pipeline-field-units:1:authored:migration-55472c86cfa5f4ad-0 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:W-graph-statistics:0 -->Pipeline statistics report invocations of nodes against the corresponding shader type.  So compute-based node shader invocations increment `CSInvocations`.<!-- d3d12-review-inline:end:queries:W-graph-statistics:0 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:G-gs-invocation-statistics:0:modified:migration-636f2fd8ec06886c-0 -->The GSInvocations [Pipeline Statistics counter](#pipeline-statistics) reports the number of primitives input to the GS multiplied by the instance count per primitive. That is, each "instance" counts as a GSInvocation.<!-- d3d12-review-inline:end:queries:G-gs-invocation-statistics:0:modified:migration-636f2fd8ec06886c-0 --></ins>

<a id="mesh-statistics"></a>

### Mesh and amplification statistics

In order to track the number of invocations of Mesh Shaders and Amplification shaders in a given program, as well as the number of primitives output by a mesh shader,
applications can use the Pipeline Statistics feature.

```cpp
typedef struct D3D12_QUERY_DATA_PIPELINE_STATISTICS1
{
    UINT64 IAVertices;
    UINT64 IAPrimitives;
    UINT64 VSInvocations;
    UINT64 GSInvocations;
    UINT64 GSPrimitives;
    UINT64 CInvocations;
    UINT64 CPrimitives;
    UINT64 PSInvocations;
    UINT64 HSInvocations;
    UINT64 DSInvocations;
    UINT64 CSInvocations;
    UINT64 ASInvocations;
    UINT64 MSInvocations;
    UINT64 MSPrimitives;
} D3D12_QUERY_DATA_PIPELINE_STATISTICS1;
```

<ins><!-- d3d12-review-inline:begin:queries:M-statistics-contract:0:authored:migration-bdb1d826752d0817-0 -->`D3D12_QUERY_HEAP_TYPE_PIPELINE_STATISTICS1` and `D3D12_QUERY_TYPE_PIPELINE_STATISTICS1` select this result. `ASInvocations` and `MSInvocations` count individual shader thread invocations, not thread groups. `MSPrimitives` counts mesh output primitives with the view/culling qualifications below. Query begin/end and result resolution retain the [query contract](#query-lifecycle). Creating this statistics heap requires `OPTIONS9.MeshShaderPipelineStatsSupported`. The older fields retain their existing meanings. Driver reporting uses the corresponding `D3D12DDI_QUERY_DATA_PIPELINE_STATISTICS1`, query heap and query type contracts.<!-- d3d12-review-inline:end:queries:M-statistics-contract:0:authored:migration-bdb1d826752d0817-0 --></ins>

<a id="msprimitives-and-view-instancing"></a>

#### MSPrimitives and view instancing

<ins><!-- d3d12-review-inline:begin:queries:M-msprimitives-view:0 -->The interaction between the MSPrimitives pipeline statistic and [view instancing](vertex-processing.md#geometry-view-instancing) depends on the view instancing tier (D3D12_VIEW_INSTANCING_TIER) of the device.<!-- d3d12-review-inline:end:queries:M-msprimitives-view:0 --></ins>

On D3D12_VIEW_INSTANCING_TIER_NOT_SUPPORTED devices, view instancing doesn't affect MSPrimitives.

On D3D12_VIEW_INSTANCING_TIER_1 devices, view instances increment MSPrimitives.

On D3D12_VIEW_INSTANCING_TIER_2 devices,
  * If SV_ViewID is referenced from MS, view instances increment MSPrimitives.
  * If SV_ViewID is referenced from a later stage like PS, view instances might or might not increment MSPrimitives.

On D3D12_VIEW_INSTANCING_TIER_3 devices,
  * If SV_ViewID is referenced from MS, view instances increment MSPrimitives.
  * If SV_ViewID is referenced from a later stage like PS, then view instances don't increment MSPrimitives.

<a id="culled-primitives"></a>

#### Culled primitives and MSPrimitives

<a id="d3d12_tri_state"></a>

##### D3D12_TRI_STATE

```cpp
typedef enum D3D12_TRI_STATE {
    D3D12_TRI_STATE_UNKNOWN = -1,
    D3D12_TRI_STATE_FALSE = 0,
    D3D12_TRI_STATE_TRUE = 1,
} D3D12_TRI_STATE;
```

Culled primitives might or might not be included in MSPrimitives, depending on the GPU implementation.

Applications can find out whether the GPU implementation includes culled primitives in the MSPrimitives count, using a <ins><!-- d3d12-review-inline:begin:queries:M-culled-statistics:1:modified:source-341424b746f10797-0-0 -->queryable<!-- d3d12-review-inline:end:queries:M-culled-statistics:1:modified:source-341424b746f10797-0-0 --></ins> capability called MSPrimitivesPipelineStatisticIncludesCulledPrimitives.

If the capability value is FALSE, then culled primitives are not included in the MSPrimitives count.

If the capability value is TRUE, then <ins><!-- d3d12-review-inline:begin:queries:M-culled-statistics:3:modified:source-15fd568b9fa8141c-0-0 -->culled<!-- d3d12-review-inline:end:queries:M-culled-statistics:3:modified:source-15fd568b9fa8141c-0-0 --></ins> primitives are included in the MSPrimitives count.

If the capability value is UNKNOWN, then the culled primitives might or might not be included in the count.

> ### Remark
>
> At the DDI level, drivers do not return UNKNOWN. At the application level, a capability value of UNKNOWN
> may be returned if the capability can not be queried from the driver. This could be relevant when, for example,
> using a driver which supports the mesh shader feature but has not been updated to support the 0086 DDI
> version.

<a id="stream-output-statistics"></a>

## Stream output statistics

<ins><!-- d3d12-review-inline:begin:queries:A-so-statistics:0:modified:migration-c1b937b726d2d45f-0 -->`D3D12_QUERY_DATA_SO_STATISTICS` contains statistics for monitoring the amount of data streamed out to the given Stream at the [Stream Output](geometry-shaders-and-stream-output.md#stream-output) stage of the Pipeline. Only complete primitives (e.g. points, lines or triangles) are Streamed Out, as counted by these stats. Should the primitive type change (e.g. lines to triangles), the counting is not adjusted in any way; the count is always total primitives, regardless of type.<!-- d3d12-review-inline:end:queries:A-so-statistics:0:modified:migration-c1b937b726d2d45f-0 --></ins>

```cpp
typedef struct D3D12_QUERY_DATA_SO_STATISTICS
{
    UINT64 NumPrimitivesWritten;
    UINT64 PrimitivesStorageNeeded;
} D3D12_QUERY_DATA_SO_STATISTICS;
```

`NumPrimitivesWritten`

The number of primitives (that is, points, lines, and triangles) that were actually written to the stream output resource.

`PrimitivesStorageNeeded`

If the stream output resource is large enough, then *PrimitivesStorageNeeded* represents the total number of primitives written to the stream output resource. Otherwise, it represents the total number of primitives that *would* have been written to the <ins><!-- d3d12-review-inline:begin:queries:STYLE-O3:3:preserved-repair:statistics-resource-name -->stream output<!-- d3d12-review-inline:end:queries:STYLE-O3:3:preserved-repair:statistics-resource-name --></ins> resource had there been enough space for them all.

<ins><!-- d3d12-review-inline:begin:queries:G-so-statistics-contract:0:authored:migration-777df26a537db373-0 -->`D3D12_QUERY_TYPE_SO_STATISTICS_STREAM0` through `D3D12_QUERY_TYPE_SO_STATISTICS_STREAM3` select per-stream statistics from a `D3D12_QUERY_HEAP_TYPE_SO_STATISTICS` heap. These primitive counts are distinct from the filled size byte value and GS emission limits. `BeginQuery` and `EndQuery` define the measured interval; `ResolveQueryData` makes its result available. Unequal written and storage-needed results indicate insufficient capture storage. Predicate and [indirect execution](indirect-execution.md#argument-initialization) use their own buffer/operation contracts.<!-- d3d12-review-inline:end:queries:G-so-statistics-contract:0:authored:migration-777df26a537db373-0 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:N-so-owner:0:authored:migration-8a9521525d9e8e5a-0 -->These counters measure complete primitives per stream, not filled size bytes. Stream overflow, whole-primitive write suppression and independence between streams are defined by [SO capture behavior](geometry-shaders-and-stream-output.md#overflow-and-statistics). A comparison of the two interval results can detect insufficient storage. There is no separate D3D12 SO overflow predicate query object.<!-- d3d12-review-inline:end:queries:N-so-owner:0:authored:migration-8a9521525d9e8e5a-0 --></ins>

<a id="video-decode-statistics"></a>

## Video decode statistics

```cpp
typedef struct D3D12_QUERY_DATA_VIDEO_DECODE_STATISTICS
{
    UINT64 Status;                      // see D3D12_VIDEO_DECODE_STATUS
    UINT64 NumMacroblocksAffected;
    DXGI_RATIONAL FrameRate;
    UINT BitRate;
} D3D12_QUERY_DATA_VIDEO_DECODE_STATISTICS;
```

<a id="d3d12-video-decode-status"></a>

```cpp
typedef enum D3D12_VIDEO_DECODE_STATUS
{
    D3D12_VIDEO_DECODE_STATUS_OK = 0,
    D3D12_VIDEO_DECODE_STATUS_CONTINUE = 1,
    D3D12_VIDEO_DECODE_STATUS_CONTINUE_SKIP_DISPLAY = 2,
    D3D12_VIDEO_DECODE_STATUS_RESTART = 3,
    D3D12_VIDEO_DECODE_STATUS_RATE_EXCEEDED = 4,
} D3D12_VIDEO_DECODE_STATUS;
```

`Status`

A member of the [D3D12_VIDEO_DECODE_STATUS](#d3d12-video-decode-status) enumeration indicating the video decoding status.

`NumMacroblocksAffected`

If **Status** is not 0, this member contains the accelerator's estimate of the number of super-blocks in the decoded frame that were adversely affected by the reported problem. If the accelerator does not provide an estimate, the value is **D3D12\_VIDEO\_DECODE\_MACROBLOCKS\_AFFECTED\_UNKNOWN** (0xFFFFFFFFFFFFFFFF).

`FrameRate`

The decode frame rate.

`BitRate`

When the **Status** returned is [D3D12_VIDEO_DECODE_STATUS_RATE_EXCEEDED](#d3d12-video-decode-status), this field reports the bitrate that would succeed. This value may be used to recreate the decoder and try again. A value of zero here is valid to indicate that the worst case bit rate should be assumed.

For all other **Status** values, **BitRate** is set to zero.

<ins><!-- d3d12-review-inline:begin:queries:P-video-statistics-use:0 -->Use this query type to determine if a video was successfully decoded. If decoding fails due to insufficient BitRate or FrameRate parameters set during creation of the decode heap, then the status field of the query is set to [D3D12_VIDEO_DECODE_STATUS_RATE_EXCEEDED](#d3d12-video-decode-status) and the query also contains new BitRate and FrameRate values that would succeed. This query type can only be performed on video decode command lists [(D3D12_COMMAND_LIST_TYPE_VIDEO_DECODE)](execution.md#command-list-types). This query type does not use [ID3D12VideoDecodeCommandList::BeginQuery](#videodecode-beginquery), only [ID3D12VideoDecodeCommandList::EndQuery](#videodecode-endquery). Statistics are recorded only for the most recent [ID3D12VideoDecodeCommandList::DecodeFrame](video-decode.md#decode-frame) call in the same command list. Decode status structures are defined by the codec specification.<!-- d3d12-review-inline:end:queries:P-video-statistics-use:0 --></ins>

<a id="query-apis"></a>

## Query creation and GPU operations

<a id="createqueryheap"></a>

### ID3D12Device::CreateQueryHeap

#### Declaration

```cpp
HRESULT CreateQueryHeap(
    const D3D12_QUERY_HEAP_DESC* pDesc,
    REFIID riid,
    void** ppvHeap
    );
```

#### Behavior

Creates a query heap. A query heap contains an array of queries.

#### Parameters

`[in] pDesc`

Type: **const [D3D12_QUERY_HEAP_DESC](#d3d12_query_heap_desc)\***

Specifies the query heap in a [D3D12_QUERY_HEAP_DESC](#d3d12_query_heap_desc) structure.

`riid`

Type: **REFIID**

<ins><!-- d3d12-review-inline:begin:queries:P-ID3D12Device%3A%3ACreateQueryHeap:5:modified:style-o2-query-heap -->Identifies the requested query heap interface, not an individual heap instance.<!-- d3d12-review-inline:end:queries:P-ID3D12Device%3A%3ACreateQueryHeap:5:modified:style-o2-query-heap --></ins>

`[out, optional] ppvHeap`

Type: **void\*\***

Specifies a pointer to the heap, that will be returned on successful completion of the method. *ppvHeap* can be NULL, to enable capability testing. When *ppvHeap* is NULL, no object will be created and S\_FALSE will be returned when *pDesc* is valid.

#### Return values

Type: **[HRESULT](devices-and-capabilities.md#api-result-codes)**

This method returns one of the [Direct3D 12 Return Codes](devices-and-capabilities.md#api-result-codes).

#### Constraints

<ins><!-- d3d12-review-inline:begin:queries:C-ID3D12Device%3A%3ACreateQueryHeap:0:authored:migration-92e17a93e00f7dc0-0 -->The heap type/count/node and relevant capability must be valid under [query support](#query-support).<!-- d3d12-review-inline:end:queries:C-ID3D12Device%3A%3ACreateQueryHeap:0:authored:migration-92e17a93e00f7dc0-0 --></ins>

<a id="graphics-beginquery"></a>

### ID3D12GraphicsCommandList::BeginQuery

#### Declaration

```cpp
void BeginQuery(
    ID3D12QueryHeap* pQueryHeap,
    D3D12_QUERY_TYPE Type,
    UINT Index
    );
```

#### Behavior

Starts a query running.

#### Parameters

`[in] pQueryHeap`

Type: **[ID3D12QueryHeap](#query-heaps)\***

Specifies the [ID3D12QueryHeap](#query-heaps) containing the query.

`[in] Type`

Type: **[D3D12_QUERY_TYPE](#d3d12_query_type)**

Specifies one member of [D3D12_QUERY_TYPE](#d3d12_query_type).

`[in] Index`

Type: **UINT**

Specifies the index of the query within the query heap.

#### Return values

None

#### Constraints

<ins><!-- d3d12-review-inline:begin:queries:C-ID3D12GraphicsCommandList%3A%3ABeginQuery:0:authored:migration-48813c0694b480f2-0 -->The [type/heap/list support](#query-support), [lifecycle](#query-lifecycle), [result layout](#result-layout), [resource access](#query-lifecycle) and [operation predication](#predication-operation-matrix) contracts apply.<!-- d3d12-review-inline:end:queries:C-ID3D12GraphicsCommandList%3A%3ABeginQuery:0:authored:migration-48813c0694b480f2-0 --></ins>

<a id="graphics-endquery"></a>

### ID3D12GraphicsCommandList::EndQuery

#### Declaration

```cpp
void EndQuery(
    ID3D12QueryHeap* pQueryHeap,
    D3D12_QUERY_TYPE Type,
    UINT Index
    );
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:queries:B-ID3D12GraphicsCommandList%3A%3AEndQuery:0 -->Completes an interval query or performs an End-only query according to `Type`.<!-- d3d12-review-inline:end:queries:B-ID3D12GraphicsCommandList%3A%3AEndQuery:0 --></ins>

#### Parameters

`[in] pQueryHeap`

Type: **[ID3D12QueryHeap](#query-heaps)\***

Specifies the [ID3D12QueryHeap](#query-heaps) containing the query.

`[in] Type`

Type: **[D3D12_QUERY_TYPE](#d3d12_query_type)**

Specifies one member of [D3D12_QUERY_TYPE](#d3d12_query_type).

`[in] Index`

Type: **UINT**

Specifies the index of the query in the query heap.

#### Return values

None

#### Constraints

<ins><!-- d3d12-review-inline:begin:queries:C-ID3D12GraphicsCommandList%3A%3AEndQuery:0:authored:migration-c99216ceef5259fe-0 -->The [type/heap/list support](#query-support), [lifecycle](#query-lifecycle), [result layout](#result-layout), [resource access](#query-lifecycle) and [operation predication](#predication-operation-matrix) contracts apply.<!-- d3d12-review-inline:end:queries:C-ID3D12GraphicsCommandList%3A%3AEndQuery:0:authored:migration-c99216ceef5259fe-0 --></ins>

<a id="graphics-resolvequerydata"></a>

### ID3D12GraphicsCommandList::ResolveQueryData

#### Declaration

```cpp
void ResolveQueryData(
    ID3D12QueryHeap* pQueryHeap,
    D3D12_QUERY_TYPE Type,
    UINT StartIndex,
    UINT NumQueries,
    ID3D12Resource* pDestinationBuffer,
    UINT64 AlignedDestinationBufferOffset
    );
```

#### Behavior

Extracts data from a query.

#### Parameters

`[in] pQueryHeap`

Type: **[ID3D12QueryHeap](#query-heaps)\***

Specifies the [ID3D12QueryHeap](#query-heaps) containing the queries to resolve.

`[in] Type`

Type: **[D3D12_QUERY_TYPE](#d3d12_query_type)**

Specifies the type of query, one member of [D3D12_QUERY_TYPE](#d3d12_query_type).

`[in] StartIndex`

Type: **UINT**

Specifies an index of the first query to resolve.

`[in] NumQueries`

Type: **UINT**

Specifies the number of queries to resolve.

`[in] pDestinationBuffer`

Type: **[ID3D12Resource](resources.md#resource-storage)\***

Specifies an [ID3D12Resource](resources.md#resource-storage) destination buffer, which must be in the state [D3D12_RESOURCE_STATE_COPY_DEST](synchronization.md#d3d12-resource-states).

`[in] AlignedDestinationBufferOffset`

Type: **UINT64**

Specifies an alignment offset into the destination buffer. Must be a multiple of 8 bytes.

#### Return values

None

#### Constraints

<ins><!-- d3d12-review-inline:begin:queries:C-ID3D12GraphicsCommandList%3A%3AResolveQueryData:0:authored:migration-46dea6c5b7e213c1-0 -->The [type/heap/list support](#query-support), [lifecycle](#query-lifecycle), [result layout](#result-layout), [resource access](#query-lifecycle) and [operation predication](#predication-operation-matrix) contracts apply.<!-- d3d12-review-inline:end:queries:C-ID3D12GraphicsCommandList%3A%3AResolveQueryData:0:authored:migration-46dea6c5b7e213c1-0 --></ins>

<a id="videodecode-beginquery"></a>

### ID3D12VideoDecodeCommandList::BeginQuery

#### Declaration

```cpp
void BeginQuery(
    ID3D12QueryHeap* pQueryHeap,
    D3D12_QUERY_TYPE Type,
    UINT Index
    );
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:queries:B-ID3D12VideoDecodeCommandList%3A%3ABeginQuery:0 -->No currently supported video query type uses this interval-query entry point.<!-- d3d12-review-inline:end:queries:B-ID3D12VideoDecodeCommandList%3A%3ABeginQuery:0 --></ins>

#### Parameters

`pQueryHeap`

A pointer to an [ID3D12QueryHeap](#query-heaps) specifying the storage for this query.

`Type`

A member of the [D3D12_QUERY_TYPE](#d3d12_query_type) enumeration specifying the type of the query.

`Index`

The index of the query within the query heap.

#### Return values

None

#### Constraints

<ins><!-- d3d12-review-inline:begin:queries:C-ID3D12VideoDecodeCommandList%3A%3ABeginQuery:0:authored:migration-095be059288d7e45-0 -->The [type/heap/list support](#query-support), [lifecycle](#query-lifecycle), [result layout](#result-layout), [resource access](#query-lifecycle) and [operation predication](#predication-operation-matrix) contracts apply. No currently supported video query type uses BeginQuery. This declaration does not permit beginning a timestamp or decode statistics query.<!-- d3d12-review-inline:end:queries:C-ID3D12VideoDecodeCommandList%3A%3ABeginQuery:0:authored:migration-095be059288d7e45-0 --></ins>

<a id="videodecode-endquery"></a>

### ID3D12VideoDecodeCommandList::EndQuery

#### Declaration

```cpp
void EndQuery(
    ID3D12QueryHeap* pQueryHeap,
    D3D12_QUERY_TYPE Type,
    UINT Index
    );
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:queries:B-ID3D12VideoDecodeCommandList%3A%3AEndQuery:0 -->Completes an interval query or performs an End-only query according to `Type`.<!-- d3d12-review-inline:end:queries:B-ID3D12VideoDecodeCommandList%3A%3AEndQuery:0 --></ins>

#### Parameters

`pQueryHeap`

A pointer to an [ID3D12QueryHeap](#query-heaps) specifying the storage for this query.

`Type`

A member of the [D3D12_QUERY_TYPE](#d3d12_query_type) enumeration specifying the type of the query.

`Index`

The index of the query within the query heap.

#### Return values

None

#### Constraints

<ins><!-- d3d12-review-inline:begin:queries:C-ID3D12VideoDecodeCommandList%3A%3AEndQuery:0:authored:migration-1ec2a29ea3c2656d-0 -->The [type/heap/list support](#query-support), [lifecycle](#query-lifecycle), [result layout](#result-layout), [resource access](#query-lifecycle) and [operation predication](#predication-operation-matrix) contracts apply. Decode statistics samples only the latest decode operation in this same command list, not an interval.<!-- d3d12-review-inline:end:queries:C-ID3D12VideoDecodeCommandList%3A%3AEndQuery:0:authored:migration-1ec2a29ea3c2656d-0 --></ins>

<a id="videodecode-resolvequerydata"></a>

### ID3D12VideoDecodeCommandList::ResolveQueryData

#### Declaration

```cpp
void ResolveQueryData(
    ID3D12QueryHeap* pQueryHeap,
    D3D12_QUERY_TYPE Type,
    UINT StartIndex,
    UINT NumQueries,
    ID3D12Resource* pDestinationBuffer,
    UINT64 AlignedDestinationBufferOffset
    );
```

#### Behavior

Extracts data from a query.

#### Parameters

`pQueryHeap`

A pointer to an [ID3D12QueryHeap](#query-heaps) specifying the storage containing the queries to resolve.

`Type`

A member of the [D3D12_QUERY_TYPE](#d3d12_query_type) enumeration specifying the type of the query.

`StartIndex`

The index of the first query to resolve.

`NumQueries`

The number of queries to resolve.

`pDestinationBuffer`

A pointer to an [ID3D12Resource](resources.md#resource-storage) representing the destination buffer. The resource must be in the state [D3D12_RESOURCE_STATE_COPY_DEST](synchronization.md#d3d12-resource-states).

`AlignedDestinationBufferOffset`

The alignment offset into the destination buffer. This must be a multiple of 8 bytes.

#### Return values

None

#### Constraints

<ins><!-- d3d12-review-inline:begin:queries:C-ID3D12VideoDecodeCommandList%3A%3AResolveQueryData:0:authored:migration-f8dcf66a6a31ca36-0 -->The [type/heap/list support](#query-support), [lifecycle](#query-lifecycle), [result layout](#result-layout), [resource access](#query-lifecycle) and [operation predication](#predication-operation-matrix) contracts apply.<!-- d3d12-review-inline:end:queries:C-ID3D12VideoDecodeCommandList%3A%3AResolveQueryData:0:authored:migration-f8dcf66a6a31ca36-0 --></ins>

<a id="videoprocess-beginquery"></a>

### ID3D12VideoProcessCommandList::BeginQuery

#### Declaration

```cpp
void BeginQuery(
    ID3D12QueryHeap* pQueryHeap,
    D3D12_QUERY_TYPE Type,
    UINT Index
    );
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:queries:B-ID3D12VideoProcessCommandList%3A%3ABeginQuery:0 -->No currently supported video query type uses this interval-query entry point.<!-- d3d12-review-inline:end:queries:B-ID3D12VideoProcessCommandList%3A%3ABeginQuery:0 --></ins>

#### Parameters

`pQueryHeap`

A pointer to an [ID3D12QueryHeap](#query-heaps) specifying the storage for this query.

`Type`

A member of the [D3D12_QUERY_TYPE](#d3d12_query_type) enumeration specifying the type of the query.

`Index`

The index of the query within the query heap.

#### Return values

None

#### Constraints

<ins><!-- d3d12-review-inline:begin:queries:C-ID3D12VideoProcessCommandList%3A%3ABeginQuery:0:authored:migration-3e2c5288d596bfa1-0 -->The [type/heap/list support](#query-support), [lifecycle](#query-lifecycle), [result layout](#result-layout), [resource access](#query-lifecycle) and [operation predication](#predication-operation-matrix) contracts apply. No currently supported video query type uses BeginQuery. This declaration does not permit beginning a timestamp or decode statistics query.<!-- d3d12-review-inline:end:queries:C-ID3D12VideoProcessCommandList%3A%3ABeginQuery:0:authored:migration-3e2c5288d596bfa1-0 --></ins>

<a id="videoprocess-endquery"></a>

### ID3D12VideoProcessCommandList::EndQuery

#### Declaration

```cpp
void EndQuery(
    ID3D12QueryHeap* pQueryHeap,
    D3D12_QUERY_TYPE Type,
    UINT Index
    );
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:queries:B-ID3D12VideoProcessCommandList%3A%3AEndQuery:0 -->Completes an interval query or performs an End-only query according to `Type`.<!-- d3d12-review-inline:end:queries:B-ID3D12VideoProcessCommandList%3A%3AEndQuery:0 --></ins>

#### Parameters

`pQueryHeap`

A pointer to an [ID3D12QueryHeap](#query-heaps) specifying the storage for this query.

`Type`

A member of the [D3D12_QUERY_TYPE](#d3d12_query_type) enumeration specifying the type of the query.

`Index`

The index of the query within the query heap.

#### Return values

None

#### Constraints

<ins><!-- d3d12-review-inline:begin:queries:C-ID3D12VideoProcessCommandList%3A%3AEndQuery:0:authored:migration-94e49df235bda670-0 -->The [type/heap/list support](#query-support), [lifecycle](#query-lifecycle), [result layout](#result-layout), [resource access](#query-lifecycle) and [operation predication](#predication-operation-matrix) contracts apply.<!-- d3d12-review-inline:end:queries:C-ID3D12VideoProcessCommandList%3A%3AEndQuery:0:authored:migration-94e49df235bda670-0 --></ins>

<a id="videoprocess-resolvequerydata"></a>

### ID3D12VideoProcessCommandList::ResolveQueryData

#### Declaration

```cpp
void ResolveQueryData(
    ID3D12QueryHeap* pQueryHeap,
    D3D12_QUERY_TYPE Type,
    UINT StartIndex,
    UINT NumQueries,
    ID3D12Resource* pDestinationBuffer,
    UINT64 AlignedDestinationBufferOffset
    );
```

#### Behavior

Extracts data from a query.

#### Parameters

`pQueryHeap`

A pointer to an [ID3D12QueryHeap](#query-heaps) specifying the storage containing the queries to resolve.

`Type`

A member of the [D3D12_QUERY_TYPE](#d3d12_query_type) enumeration specifying the type of the query.

`StartIndex`

The index of the first query to resolve.

`NumQueries`

The number of queries to resolve.

`pDestinationBuffer`

A pointer to an [ID3D12Resource](resources.md#resource-storage) representing the destination buffer. The resource must be in the state [D3D12_RESOURCE_STATE_COPY_DEST](synchronization.md#d3d12-resource-states).

`AlignedDestinationBufferOffset`

The alignment offset into the destination buffer. This must be a multiple of 8 bytes.

#### Return values

None

#### Constraints

<ins><!-- d3d12-review-inline:begin:queries:C-ID3D12VideoProcessCommandList%3A%3AResolveQueryData:0:authored:migration-1a3c8c915eeab6e5-0 -->The [type/heap/list support](#query-support), [lifecycle](#query-lifecycle), [result layout](#result-layout), [resource access](#query-lifecycle) and [operation predication](#predication-operation-matrix) contracts apply.<!-- d3d12-review-inline:end:queries:C-ID3D12VideoProcessCommandList%3A%3AResolveQueryData:0:authored:migration-1a3c8c915eeab6e5-0 --></ins>

<a id="videoencode-beginquery"></a>

### ID3D12VideoEncodeCommandList::BeginQuery

#### Declaration

```cpp
void BeginQuery(
    ID3D12QueryHeap* pQueryHeap,
    D3D12_QUERY_TYPE Type,
    UINT Index
    );
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:queries:B-ID3D12VideoEncodeCommandList%3A%3ABeginQuery:0 -->No currently supported video query type uses this interval-query entry point.<!-- d3d12-review-inline:end:queries:B-ID3D12VideoEncodeCommandList%3A%3ABeginQuery:0 --></ins>

#### Parameters

`pQueryHeap`

A pointer to an [ID3D12QueryHeap](#query-heaps) specifying the storage for this query.

`Type`

A member of the [D3D12_QUERY_TYPE](#d3d12_query_type) enumeration specifying the type of the query.

`Index`

The index of the query within the query heap.

#### Return values

None

#### Constraints

<ins><!-- d3d12-review-inline:begin:queries:C-ID3D12VideoEncodeCommandList%3A%3ABeginQuery:0:authored:migration-f505595db496f01e-0 -->The [type/heap/list support](#query-support), [lifecycle](#query-lifecycle), [result layout](#result-layout), [resource access](#query-lifecycle) and [operation predication](#predication-operation-matrix) contracts apply. No currently supported video query type uses BeginQuery. This declaration does not permit beginning a timestamp or decode statistics query.<!-- d3d12-review-inline:end:queries:C-ID3D12VideoEncodeCommandList%3A%3ABeginQuery:0:authored:migration-f505595db496f01e-0 --></ins>

<a id="videoencode-endquery"></a>

### ID3D12VideoEncodeCommandList::EndQuery

#### Declaration

```cpp
void EndQuery(
    ID3D12QueryHeap* pQueryHeap,
    D3D12_QUERY_TYPE Type,
    UINT Index
    );
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:queries:B-ID3D12VideoEncodeCommandList%3A%3AEndQuery:0 -->Completes an interval query or performs an End-only query according to `Type`.<!-- d3d12-review-inline:end:queries:B-ID3D12VideoEncodeCommandList%3A%3AEndQuery:0 --></ins>

#### Parameters

`pQueryHeap`

A pointer to an [ID3D12QueryHeap](#query-heaps) specifying the storage for this query.

`Type`

A member of the [D3D12_QUERY_TYPE](#d3d12_query_type) enumeration specifying the type of the query.

`Index`

The index of the query within the query heap.

#### Return values

None

#### Constraints

<ins><!-- d3d12-review-inline:begin:queries:C-ID3D12VideoEncodeCommandList%3A%3AEndQuery:0:authored:migration-36f6bdca2a592a36-0 -->The [type/heap/list support](#query-support), [lifecycle](#query-lifecycle), [result layout](#result-layout), [resource access](#query-lifecycle) and [operation predication](#predication-operation-matrix) contracts apply.<!-- d3d12-review-inline:end:queries:C-ID3D12VideoEncodeCommandList%3A%3AEndQuery:0:authored:migration-36f6bdca2a592a36-0 --></ins>

<a id="videoencode-resolvequerydata"></a>

### ID3D12VideoEncodeCommandList::ResolveQueryData

#### Declaration

```cpp
void ResolveQueryData(
    ID3D12QueryHeap* pQueryHeap,
    D3D12_QUERY_TYPE Type,
    UINT StartIndex,
    UINT NumQueries,
    ID3D12Resource* pDestinationBuffer,
    UINT64 AlignedDestinationBufferOffset
    );
```

#### Behavior

Extracts data from a query.

#### Parameters

`pQueryHeap`

A pointer to an [ID3D12QueryHeap](#query-heaps) specifying the storage containing the queries to resolve.

`Type`

A member of the [D3D12_QUERY_TYPE](#d3d12_query_type) enumeration specifying the type of the query.

`StartIndex`

The index of the first query to resolve.

`NumQueries`

The number of queries to resolve.

`pDestinationBuffer`

A pointer to an [ID3D12Resource](resources.md#resource-storage) representing the destination buffer. The resource must be in the state [D3D12_RESOURCE_STATE_COPY_DEST](synchronization.md#d3d12-resource-states).

`AlignedDestinationBufferOffset`

The alignment offset into the destination buffer. This must be a multiple of 8 bytes.

#### Return values

None

#### Constraints

<ins><!-- d3d12-review-inline:begin:queries:C-ID3D12VideoEncodeCommandList%3A%3AResolveQueryData:0:authored:migration-c019269ea90a7076-0 -->The [type/heap/list support](#query-support), [lifecycle](#query-lifecycle), [result layout](#result-layout), [resource access](#query-lifecycle) and [operation predication](#predication-operation-matrix) contracts apply.<!-- d3d12-review-inline:end:queries:C-ID3D12VideoEncodeCommandList%3A%3AResolveQueryData:0:authored:migration-c019269ea90a7076-0 --></ins>

<a id="cpu-resolution"></a>

## CPU timeline query resolution

<a id="cpu-query-flags"></a>

### CPU flag and path selection

**Members:**

- <ins><!-- d3d12-review-inline:begin:queries:CPU-flag-contract:1 -->**D3D12_QUERY_HEAP_FLAG_NONE** - No special flags. The query heap can only be resolved using the [appropriate command list GPU `ResolveQueryData` method](#gpu-resolve-support).<!-- d3d12-review-inline:end:queries:CPU-flag-contract:1 --></ins>

- <ins><!-- d3d12-review-inline:begin:queries:CPU-flag-contract:1 -->**D3D12_QUERY_HEAP_FLAG_CPU_RESOLVE** - Enables CPU-based query resolution for this query heap. When this flag is set, applications can use the `ID3D12Device15::ResolveQueryData()` method to resolve query data directly on the CPU timeline after GPU execution completes.<!-- d3d12-review-inline:end:queries:CPU-flag-contract:1 --></ins>

**Remarks:**

Query heaps created without the `D3D12_QUERY_HEAP_FLAG_CPU_RESOLVE` flag cannot be used with the <ins><!-- d3d12-review-inline:begin:queries:CPU-flag-contract:3:modified:source-f886e74fc4692b85-0-0 -->`ID3D12Device15::ResolveQueryData()`<!-- d3d12-review-inline:end:queries:CPU-flag-contract:3:modified:source-f886e74fc4692b85-0-0 --></ins> method and will return `E_INVALIDARG` if attempted. Conversely, heaps created with the CPU resolve flag cannot be used with the Command List resolve API.

<a id="createqueryheap1"></a>

### ID3D12Device15::CreateQueryHeap1

#### Declaration

```cpp
HRESULT CreateQueryHeap1(
    const D3D12_QUERY_HEAP_DESC* pDesc,
    D3D12_QUERY_HEAP_FLAGS Flags,
    REFIID riid,
    void** ppvHeap);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:queries:B-ID3D12Device15%3A%3ACreateQueryHeap1:0:authored:migration-0a2e607d211450a6-0 -->Creates a query heap with explicit CPU/GPU result retrieval selection.<!-- d3d12-review-inline:end:queries:B-ID3D12Device15%3A%3ACreateQueryHeap1:0:authored:migration-0a2e607d211450a6-0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:queries:P-ID3D12Device15%3A%3ACreateQueryHeap1:0:authored:migration-ca7848830bd5637e-0 -->`pDesc` supplies [Type, Count and NodeMask](#query-heaps). `Flags` is `D3D12_QUERY_HEAP_FLAG_NONE` for ordinary GPU resolution or `D3D12_QUERY_HEAP_FLAG_CPU_RESOLVE` for CPU resolution. `riid` identifies the requested heap interface. `ppvHeap` receives the created object. As with CreateQueryHeap, a null `ppvHeap` requests validation without returning an object.<!-- d3d12-review-inline:end:queries:P-ID3D12Device15%3A%3ACreateQueryHeap1:0:authored:migration-ca7848830bd5637e-0 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:queries:R-ID3D12Device15%3A%3ACreateQueryHeap1:0:authored:migration-78827e42d80b47b9-0 -->Successful object creation returns `S_OK`; successful null output validation returns `S_FALSE`. Invalid parameters return `E_INVALIDARG`, with allocation and device errors reported by the standard HRESULT contract.<!-- d3d12-review-inline:end:queries:R-ID3D12Device15%3A%3ACreateQueryHeap1:0:authored:migration-78827e42d80b47b9-0 --></ins>

#### Constraints

<ins><!-- d3d12-review-inline:begin:queries:C-ID3D12Device15%3A%3ACreateQueryHeap1:0:authored:migration-bf6fc9f3145a4c51-0 -->With flags NONE, the heap is equivalent to the ordinary creation path. CPU-resolve heaps cannot be passed to command list ResolveQueryData, and ordinary heaps cannot be passed to the CPU method.<!-- d3d12-review-inline:end:queries:C-ID3D12Device15%3A%3ACreateQueryHeap1:0:authored:migration-bf6fc9f3145a4c51-0 --></ins>

<a id="cpu-resolvequerydata"></a>

### ID3D12Device15::ResolveQueryData

#### Declaration

```cpp
HRESULT ResolveQueryData(
    ID3D12QueryHeap* pQueryHeap,
    D3D12_QUERY_TYPE Type,
    UINT StartIndex,
    UINT NumQueries,
    void* pResolvedQueryData);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:queries:B-ID3D12Device15%3A%3AResolveQueryData:0:authored:migration-82c5a3b29c052f24-0 -->Resolves the selected completed query records into CPU memory on the CPU timeline.<!-- d3d12-review-inline:end:queries:B-ID3D12Device15%3A%3AResolveQueryData:0:authored:migration-82c5a3b29c052f24-0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:queries:P-ID3D12Device15%3A%3AResolveQueryData:0:authored:migration-b69cd5eea68ee556-0 -->`pQueryHeap` identifies a heap created with CPU_RESOLVE. `Type` selects compatible result records. `StartIndex` and nonzero `NumQueries` select the consecutive query range. The range must fit and the output must be non-null and correctly sized. `pResolvedQueryData` receives the [typed records](#result-layout).<!-- d3d12-review-inline:end:queries:P-ID3D12Device15%3A%3AResolveQueryData:0:authored:migration-b69cd5eea68ee556-0 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:queries:R-ID3D12Device15%3A%3AResolveQueryData:0:authored:migration-8d879a91673a34a8-0 -->`S_OK` reports successful resolution; invalid parameters return `E_INVALIDARG`. This is not a readiness-polling API.<!-- d3d12-review-inline:end:queries:R-ID3D12Device15%3A%3AResolveQueryData:0:authored:migration-8d879a91673a34a8-0 --></ins>

#### Constraints

This method resolves query data on the CPU timeline. Any required post-processing of the raw query data generated on the GPU timeline is performed on the CPU immediately by the runtime and/or driver before this method returns.

**This method does not block on the GPU and performs no implicit synchronization.** It does not wait for, flush, or otherwise track the GPU work that writes the queries being resolved. The runtime associates no implicit fence with the query heap and does not track which queue(s) may write to it.

It is the **application's responsibility** to ensure that all GPU work which writes the queries in the range `[StartIndex, StartIndex + NumQueries)` has completed execution on the GPU *before* calling this method — for example, by waiting on an `ID3D12Fence` that the application signals on the command queue after submitting the command list(s) containing the corresponding `EndQuery` operations. If this method is called before that GPU work has completed, the data written to `pResolvedQueryData` is undefined.

Note that this differs from the GPU-timeline `ID3D12GraphicsCommandList::ResolveQueryData`. On the GPU timeline, a resolve recorded after the corresponding `EndQuery` is implicitly ordered after it within the same command queue — no application synchronization or resource barrier is required between the query and the resolve (for example, `BeginQuery` → `EndQuery` → `ResolveQueryData` recorded in order is well-defined as-is). The CPU-timeline resolve performed by this method is **not** implicitly ordered against the GPU work that writes the queries; the application must perform the explicit CPU/GPU synchronization described above (for example, waiting on a fence) before calling it.

For drivers or hardware that do not support native CPU-based query resolution, the D3D12 runtime provides transparent fallback behavior to ensure the feature works universally across all D3D12-capable hardware.

<ins><!-- d3d12-review-inline:begin:queries:CPU-fallback:1 -->**Fallback mechanism**<!-- d3d12-review-inline:end:queries:CPU-fallback:1 --></ins>

When a query heap is created with the `D3D12_QUERY_HEAP_FLAG_CPU_RESOLVE` flag on hardware or drivers that lack native support:

1. **Automatic GPU Resolution Injection**: The runtime automatically injects GPU-based `ResolveQueryData` operations into command lists at `Close()` time for any query heaps that have been used and marked for CPU resolution.

2. **Internal Buffer Management**: The runtime creates and manages internal GPU-visible destination buffers to store the resolved query results. These buffers are sized appropriately for the query types and counts used.

3. **Transparent Operation**: Applications using <ins><!-- d3d12-review-inline:begin:queries:CPU-fallback:3:modified:source-9f32acad5cf93b30-0-0 -->`ID3D12Device15::ResolveQueryData()`<!-- d3d12-review-inline:end:queries:CPU-fallback:3:modified:source-9f32acad5cf93b30-0-0 --></ins> are unaware of the fallback - the method behaves identically whether using native support or runtime emulation.

<a id="timestamps"></a>

## Queue timestamps and clock calibration

<a id="gettimestampfrequency"></a>

### ID3D12CommandQueue::GetTimestampFrequency

#### Declaration

```cpp
HRESULT GetTimestampFrequency(
    UINT64* pFrequency
    );
```

#### Behavior

This method is used to determine the rate at which the GPU timestamp counter increments.

#### Parameters

`[out] pFrequency`

Type: **UINT64\***

The GPU timestamp counter frequency (in ticks/second).

#### Return values

Type: **[HRESULT](devices-and-capabilities.md#api-result-codes)**

This method returns one of the [Direct3D 12 Return Codes](devices-and-capabilities.md#api-result-codes).

#### Constraints

<ins><!-- d3d12-review-inline:begin:queries:C-ID3D12CommandQueue%3A%3AGetTimestampFrequency:0:authored:migration-e4fc630790ba3478-0 -->Timestamp support, clock domains, units and idle/calibration qualifications are defined below; unsupported queues return `E_FAIL`.<!-- d3d12-review-inline:end:queries:C-ID3D12CommandQueue%3A%3AGetTimestampFrequency:0:authored:migration-e4fc630790ba3478-0 --></ins>

<a id="getclockcalibration"></a>

### ID3D12CommandQueue::GetClockCalibration

#### Declaration

```cpp
HRESULT GetClockCalibration(
    UINT64* pGpuTimestamp,
    UINT64* pCpuTimestamp
    );
```

#### Behavior

This method samples the CPU and GPU timestamp counters <ins><!-- d3d12-review-inline:begin:queries:OI3-clock-calibration:0:modified:sampling-qualification -->at nearly the same time<!-- d3d12-review-inline:end:queries:OI3-clock-calibration:0:modified:sampling-qualification --></ins>.

#### Parameters

`[out] pGpuTimestamp`

Type: **UINT64\***

The value of the GPU timestamp counter.

`[out] pCpuTimestamp`

Type: **UINT64\***

The value of the CPU timestamp counter.

#### Return values

Type: **[HRESULT](devices-and-capabilities.md#api-result-codes)**

This method returns one of the [Direct3D 12 Return Codes](devices-and-capabilities.md#api-result-codes).

#### Constraints

<ins><!-- d3d12-review-inline:begin:queries:C-ID3D12CommandQueue%3A%3AGetClockCalibration:0:authored:migration-6b22155052f37629-0 -->Timestamp support, clock domains, units and idle/calibration qualifications are defined below; unsupported queues return `E_FAIL`.<!-- d3d12-review-inline:end:queries:C-ID3D12CommandQueue%3A%3AGetClockCalibration:0:authored:migration-6b22155052f37629-0 --></ins>

A timestamp is sampled by the GPU at the moment that the GPU is finished with all of the preceding workload. It's the same behavior adopted by Direct3D 11 (see [D3D11_QUERY_TIMESTAMP](https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm#20.4.3%20D3D11_QUERY_TIMESTAMP) in the Direct3D 11.3 Functional Specification on GitHub). That means that timestamp queries are a bottom-of-pipe (BOP) operation in Direct3D 12.

[**GetClockCalibration**](#getclockcalibration) samples the GPU timestamp counter for a given command queue and samples the CPU counter via `QueryPerformanceCounter` at nearly the same time. Again this API fails (returning E\_FAIL) if the specified command queue does not support timestamps (see the table in the [Queries](#query-heaps) topic).

Note that GPU and CPU timestamp counters are not necessarily directly related to the clock speed of these processors, but instead work from timestamp ticks.

<ins><!-- d3d12-review-inline:begin:queries:P-timestamp-calibration:3 -->**Idle clock qualification.**<!-- d3d12-review-inline:end:queries:P-timestamp-calibration:3 --></ins>

GPU timestamp clocks can stop ticking on some hardware when the GPU is idle, so the correlation can drift. To prevent this, call [**ID3D12Device::SetStablePowerState**](#setstablepowerstate) during development (requires Developer Mode enabled).

Timestamp frequencies do not change, even if other clock frequencies
on the GPU change.

<ins><!-- d3d12-review-inline:begin:queries:N-timestamp-units:0:authored:migration-316c7b0b742b6eb4-0 -->A timestamp is a 64-bit tick value with unspecified origin. Differences quantify elapsed GPU clock ticks within the supported comparison domain; divide by the corresponding queue frequency for seconds, using floating-point arithmetic when fractional time is needed. CPU calibration values are QueryPerformanceCounter ticks and use that counter's frequency, not the GPU queue frequency. A timestamp is not a fence signal and does not by itself establish CPU visibility or resource synchronization.<!-- d3d12-review-inline:end:queries:N-timestamp-units:0:authored:migration-316c7b0b742b6eb4-0 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:N-timestamp-comparison:0:authored:migration-65aeff99a3925f0d-0 -->Two timestamp queries issued in the same command list are reliably comparable. Comparisons across command lists must account for GPU idle intervals and clock domain/calibration behavior; stable power is a development-time aid for stable correlation. Do not compare raw ticks from different queue clock domains as if they necessarily had a common origin and frequency.<!-- d3d12-review-inline:end:queries:N-timestamp-comparison:0:authored:migration-65aeff99a3925f0d-0 --></ins>

<a id="ddi-clock-calibration"></a>

### Driver clock calibration

```cpp
typedef void (APIENTRY* PFND3D12DDI_QUERY_CLOCK_CALIBRATION_0054)(
    D3D12DDI_HDEVICE, D3D12DDI_HCOMMANDQUEUE, _Out_ D3D12DDI_GPUCLOCKDATA_0054* pClockData);

typedef struct D3D12DDI_GPUCLOCKDATA_0054
{
    ULONGLONG               GpuFrequency;
    ULONGLONG               GpuClockCounter;
    ULONGLONG               CpuClockCounter;
} D3D12DDI_GPUCLOCKDATA_0054;
```

<ins><!-- d3d12-review-inline:begin:execution:CS-presentation-services:3:authored:migration-30f25e84526e45a8-0 -->The downlevel QueryClockCalibration entry writes GPU frequency and correlated GPU/CPU counters for the specified driver queue.<!-- d3d12-review-inline:end:execution:CS-presentation-services:3:authored:migration-30f25e84526e45a8-0 --></ins>

<ins><!-- d3d12-review-inline:begin:execution:IF06-clock-owner-route:0:authored:migration-1006458d20ae03c0-0 -->[Clock calibration](counters-queries-and-predication.md#getclockcalibration)
defines the API's timestamp support, clock domains and idle-clock qualifications.<!-- d3d12-review-inline:end:execution:IF06-clock-owner-route:0:authored:migration-1006458d20ae03c0-0 --></ins>

<a id="setstablepowerstate"></a>

### ID3D12Device::SetStablePowerState

#### Declaration

```cpp
HRESULT SetStablePowerState(BOOL Enable);
```

#### Behavior

A development-time aid for certain types of profiling and experimental prototyping.

#### Parameters

`Enable`

Type: **BOOL**

Specifies a BOOL that turns the stable power state on or off.

#### Return values

Type: **[HRESULT](devices-and-capabilities.md#api-result-codes)**

This method returns one of the [Direct3D 12 Return Codes](devices-and-capabilities.md#api-result-codes).

#### Constraints

<ins><!-- d3d12-review-inline:begin:queries:C-ID3D12Device%3A%3ASetStablePowerState:0:authored:migration-714c80ab46eae359-0 -->This is a development-time profiling control, not a requirement to issue timestamp queries. Developer Mode is required.<!-- d3d12-review-inline:end:queries:C-ID3D12Device%3A%3ASetStablePowerState:0:authored:migration-714c80ab46eae359-0 --></ins>

This method is only useful during the development of applications. It enables developers to profile GPU usage of multiple algorithms without experiencing artifacts from [dynamic frequency scaling](https://en.wikipedia.org/wiki/Dynamic_frequency_scaling).

<ins><!-- d3d12-review-inline:begin:queries:P-stable-power-mode:1 -->Do not call this method in normal execution for a shipped application. This method only works while the machine is in [developer mode](https://learn.microsoft.com/en-us/windows/uwp/get-started/enable-your-device-for-development). If developer mode is not enabled, then device removal will occur.<!-- d3d12-review-inline:end:queries:P-stable-power-mode:1 --></ins>

A stable power state typically fixes GPU clock rates at a slower setting that is significantly lower than that experienced by users under normal application load. This reduction in clock rate affects the entire system. Slow clock rates are required to ensure processors don’t exhaust power, current, and thermal limits. Normal usage scenarios commonly leverage a <ins><!-- d3d12-review-inline:begin:queries:P-stable-power-effects:0:modified:source-c107397fef1d7d79-0-0 -->processor's<!-- d3d12-review-inline:end:queries:P-stable-power-effects:0:modified:source-c107397fef1d7d79-0-0 --></ins> ability to dynamically over-clock. Any conclusions made by comparing two designs under a stable power state should be double-checked with supporting results from real usage scenarios.

<a id="predication"></a>

## Predication

Predication is decoupled from queries. Predication can be set based on
the value of 64-bits within a buffer.

<a id="d3d12-predication-op"></a>

```cpp
typedef enum D3D12_PREDICATION_OP
{
    D3D12_PREDICATION_OP_EQUAL_ZERO     = 0,
    D3D12_PREDICATION_OP_NOT_EQUAL_ZERO = 1,
} D3D12_PREDICATION_OP;
```

<!-- d3d12-review-alert:begin:queries:N-predicate-truth:0:authored:migration-ba36dd99e42930c5-0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Operation | Sampled 64-bit value | Eligible work |
> |---|---|---|
> | `EQUAL_ZERO` | Zero | SKIP |
> | `EQUAL_ZERO` | Nonzero | EXECUTE |
> | `NOT_EQUAL_ZERO` | Zero | EXECUTE |
> | `NOT_EQUAL_ZERO` | Nonzero | SKIP |

<!-- d3d12-review-alert:end:queries:N-predicate-truth:0:authored:migration-ba36dd99e42930c5-0 -->

<ins><!-- d3d12-review-inline:begin:queries:N-predicate-truth:1:authored:migration-0482004606c39daf-0 -->These names select the condition for suppressing work, not a condition for executing it. A null predicate buffer disables predication. The GPU samples the selected value when SetPredication executes; recording does not read it, and subsequent writes do not retroactively change that sampled predicate.<!-- d3d12-review-inline:end:queries:N-predicate-truth:1:authored:migration-0482004606c39daf-0 --></ins>

<a id="predicate-state"></a>

### Predicate state, access and protected resources

<ins><!-- d3d12-review-inline:begin:queries:N-predicate-state:0:authored:migration-d937382b167d7279-0 -->Predication is supported by DIRECT, COMPUTE and the video command list types, not COPY or BUNDLE setters. Direct/compute/video recordings begin with predication disabled; Reset/ClearState restore disabled state. Bundles inherit the direct list predicate but cannot set it; executing the bundle is not itself skipped, and its state changes still occur. [Canonical graphics initial/reset/bundle state](command-list-state.md#queries) remains the owner of graphics recording boundaries. The video predicate defaults are specified here.<!-- d3d12-review-inline:end:queries:N-predicate-state:0:authored:migration-d937382b167d7279-0 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:N-predicate-state:1:authored:migration-b4f6a516ad159992-0 -->When `pBuffer` is null, `AlignedBufferOffset` must be zero and `Operation` must be `D3D12_PREDICATION_OP_EQUAL_ZERO`. A non-null predicate source is an unprotected buffer with an eight-byte-aligned, in-bounds eight-byte range. All 64 bits participate. Its production and subsequent sampling require the normal [resource access and synchronization contract](synchronization.md#barrier-access), with lifetime and residency preserved through execution. Predication does not legalize invalid commands or skip CPU-side recording/state validation. [Protected resource operations](../ProtectedResources.md#predication-not-supported) have their additional restriction.<!-- d3d12-review-inline:end:queries:N-predicate-state:1:authored:migration-b4f6a516ad159992-0 --></ins>

<a id="graphics-setpredication"></a>

### ID3D12GraphicsCommandList::SetPredication

#### Declaration

```cpp
void SetPredication(
    ID3D12Resource* pBuffer,
    UINT64 AlignedBufferOffset,
    D3D12_PREDICATION_OP Operation
    );
```

#### Behavior

Sets a rendering predicate.

#### Parameters

`[in, optional] pBuffer`

Type: **[ID3D12Resource](resources.md#resource-storage)\***

<ins><!-- d3d12-review-inline:begin:queries:P-ID3D12GraphicsCommandList%3A%3ASetPredication:2 -->The buffer, as an [ID3D12Resource](resources.md#resource-storage), which must be in the [**D3D12\_RESOURCE\_STATE\_PREDICATION**](synchronization.md#d3d12-resource-states) or [**D3D12\_RESOURCE\_STATE\_INDIRECT\_ARGUMENT**](synchronization.md#d3d12-resource-states) state (both values are identical, and provided as aliases for clarity), or **NULL** to disable predication.<!-- d3d12-review-inline:end:queries:P-ID3D12GraphicsCommandList%3A%3ASetPredication:2 --></ins>

`[in] AlignedBufferOffset`

Type: **UINT64**

The aligned buffer offset, as a UINT64.

`[in] Operation`

Type: **[D3D12_PREDICATION_OP](#d3d12-predication-op)**

Specifies a [D3D12_PREDICATION_OP](#d3d12-predication-op), such as D3D12\_PREDICATION\_OP\_EQUAL\_ZERO or D3D12\_PREDICATION\_OP\_NOT\_EQUAL\_ZERO.

#### Return values

None

#### Constraints

<ins><!-- d3d12-review-inline:begin:queries:C-ID3D12GraphicsCommandList%3A%3ASetPredication:0:authored:migration-3bdd8a178ee86b94-0 -->The [truth table](#predication), [state/access restrictions](#predicate-state) and [operation matrix](#predication-operation-matrix) define its current behavior. Predication state changes themselves are not suppressed by the old predicate.<!-- d3d12-review-inline:end:queries:C-ID3D12GraphicsCommandList%3A%3ASetPredication:0:authored:migration-3bdd8a178ee86b94-0 --></ins>

<a id="videodecode-setpredication"></a>

### ID3D12VideoDecodeCommandList::SetPredication

#### Declaration

```cpp
void SetPredication(
    ID3D12Resource* pBuffer,
    UINT64 AlignedBufferOffset,
    D3D12_PREDICATION_OP Operation
    );
```

#### Behavior

Specifies that subsequent commands should not be performed if the predicate value passes the specified operation.

#### Parameters

`pBuffer`

A pointer to an [ID3D12Resource](resources.md#resource-storage) representing the buffer from which to read the 64-bit predication value.

`AlignedBufferOffset`

The UINT64-aligned buffer offset.

`Operation`

A member of the [D3D12_PREDICATION_OP](#d3d12-predication-op) enumeration specifying the predicate operation.

#### Return values

None

#### Constraints

<ins><!-- d3d12-review-inline:begin:queries:C-ID3D12VideoDecodeCommandList%3A%3ASetPredication:0:authored:migration-c4739982861a6e42-0 -->The [truth table](#predication), [state/access restrictions](#predicate-state) and [operation matrix](#predication-operation-matrix) define its current behavior. Predication state changes themselves are not suppressed by the old predicate.<!-- d3d12-review-inline:end:queries:C-ID3D12VideoDecodeCommandList%3A%3ASetPredication:0:authored:migration-c4739982861a6e42-0 --></ins>

<a id="videoprocess-setpredication"></a>

### ID3D12VideoProcessCommandList::SetPredication

#### Declaration

```cpp
void SetPredication(
    ID3D12Resource* pBuffer,
    UINT64 AlignedBufferOffset,
    D3D12_PREDICATION_OP Operation
    );
```

#### Behavior

Specifies that subsequent commands should not be performed if the predicate value passes the specified operation.

#### Parameters

`pBuffer`

A pointer to an [ID3D12Resource](resources.md#resource-storage) representing the buffer from which to read the 64-bit predication value.

`AlignedBufferOffset`

The UINT64-aligned buffer offset.

`Operation`

A member of the [D3D12_PREDICATION_OP](#d3d12-predication-op) enumeration specifying the predicate operation.

#### Return values

None

#### Constraints

<ins><!-- d3d12-review-inline:begin:queries:C-ID3D12VideoProcessCommandList%3A%3ASetPredication:0:authored:migration-c598699ffd15bac8-0 -->The [truth table](#predication), [state/access restrictions](#predicate-state) and [operation matrix](#predication-operation-matrix) define its current behavior. Predication state changes themselves are not suppressed by the old predicate.<!-- d3d12-review-inline:end:queries:C-ID3D12VideoProcessCommandList%3A%3ASetPredication:0:authored:migration-c598699ffd15bac8-0 --></ins>

<a id="videoencode-setpredication"></a>

### ID3D12VideoEncodeCommandList::SetPredication

#### Declaration

```cpp
void SetPredication(
    ID3D12Resource* pBuffer,
    UINT64 AlignedBufferOffset,
    D3D12_PREDICATION_OP Operation
    );
```

#### Behavior

Specifies that subsequent commands should not be performed if the predicate value passes the specified operation.

#### Parameters

`pBuffer`

A pointer to an [ID3D12Resource](resources.md#resource-storage) representing the buffer from which to read the 64-bit predication value.

`AlignedBufferOffset`

The UINT64-aligned buffer offset.

`Operation`

A member of the [D3D12_PREDICATION_OP](#d3d12-predication-op) enumeration specifying the predicate operation.

#### Return values

None

#### Constraints

<ins><!-- d3d12-review-inline:begin:queries:C-ID3D12VideoEncodeCommandList%3A%3ASetPredication:0:authored:migration-cf7aa165c7b9bf10-0 -->The [truth table](#predication), [state/access restrictions](#predicate-state) and [operation matrix](#predication-operation-matrix) define its current behavior. Predication state changes themselves are not suppressed by the old predicate.<!-- d3d12-review-inline:end:queries:C-ID3D12VideoEncodeCommandList%3A%3ASetPredication:0:authored:migration-cf7aa165c7b9bf10-0 --></ins>

<a id="predication-operation-matrix"></a>

### Operation matrix

<!-- d3d12-review-alert:begin:queries:N-operation-matrix:0:authored:migration-cdd0ec395055d67c-0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Declaring method | Predicate effect | Qualification |
> |---|---|---|
> | `ID3D12CommandListFenceBarriers::SignalBarrier` | unpredicated | On the independently supported list types. |
> | `ID3D12CommandListFenceBarriers::WaitBarrier` | unpredicated | On the independently supported list types. |
> | `ID3D12GraphicsCommandList10::DispatchGraph` | predicated | DIRECT/COMPUTE; not BUNDLE. |
> | [`ID3D12GraphicsCommandList10::SetProgram`](state-objects.md#setprogram) | unpredicated | Program selection and optional work graph backing memory initialization. |
> | `ID3D12GraphicsCommandList1::AtomicCopyBufferUINT` | predicated | Predication applies on DIRECT/COMPUTE. COPY does not support predicate selection. |
> | `ID3D12GraphicsCommandList1::AtomicCopyBufferUINT64` | predicated | Predication applies on DIRECT/COMPUTE. COPY does not support predicate selection. |
> | `ID3D12GraphicsCommandList1::ResolveSubresourceRegion` | predicated | DIRECT. |
> | `ID3D12GraphicsCommandList2::WriteBufferImmediate` | predicated | On permitted list types. COPY has no supported predicate selection. |
> | `ID3D12GraphicsCommandList4::BeginRenderPass` | wrapper | DIRECT. Translated beginning access CLEAR work honors the predicate; binding/barrier/boundary effects remain independent. |
> | [`ID3D12GraphicsCommandList4::BuildRaytracingAccelerationStructure`](acceleration-structures.md#buildraytracingaccelerationstructure) | unpredicated | DIRECT/COMPUTE; not BUNDLE; normal acceleration structure validity rules apply. |
> | [`ID3D12GraphicsCommandList4::CopyRaytracingAccelerationStructure`](acceleration-structures.md#copyraytracingaccelerationstructure) | unpredicated | DIRECT/COMPUTE; not BUNDLE; normal acceleration structure validity rules apply. |
> | [`ID3D12GraphicsCommandList4::DispatchRays`](raytracing-pipelines.md#id3d12graphicscommandlist4dispatchrays) | predicated | DIRECT/COMPUTE. BUNDLE only when that operation independently permits it. |
> | [`ID3D12GraphicsCommandList4::EmitRaytracingAccelerationStructurePostbuildInfo`](acceleration-structures.md#emitraytracingaccelerationstructurepostbuildinfo) | unpredicated | DIRECT/COMPUTE; not BUNDLE; normal acceleration structure validity rules apply. |
> | `ID3D12GraphicsCommandList4::EndRenderPass` | wrapper | DIRECT. Translated ending access RESOLVE work honors the predicate; boundary/synchronization effects remain independent. |
> | [`ID3D12GraphicsCommandList4::ExecuteMetaCommand`](meta-commands.md#executemetacommand) | conditional | DIRECT/COMPUTE; not BUNDLE. Execution predicate behavior is defined by the selected algorithm; state-damage flags do not specify it. |
> | [`ID3D12GraphicsCommandList4::InitializeMetaCommand`](meta-commands.md#initializemetacommand) | unpredicated | DIRECT/COMPUTE; not BUNDLE. Initialization ignores predication; operation/resource legality remains separate. |
> | `ID3D12GraphicsCommandList6::DispatchMesh` | predicated | DIRECT; permitted BUNDLE operations use the inherited predicate. |
> | `ID3D12GraphicsCommandList7::Barrier` | unpredicated | On the independently supported list types. |
> | `ID3D12GraphicsCommandList::BeginQuery` | unpredicated | Only the query/list/heap combinations in the support tables. |
> | `ID3D12GraphicsCommandList::ClearDepthStencilView` | predicated | DIRECT. |
> | `ID3D12GraphicsCommandList::ClearRenderTargetView` | predicated | DIRECT. |
> | `ID3D12GraphicsCommandList::ClearUnorderedAccessViewFloat` | predicated | DIRECT or COMPUTE; not BUNDLE. |
> | `ID3D12GraphicsCommandList::ClearUnorderedAccessViewUint` | predicated | DIRECT or COMPUTE; not BUNDLE. |
> | `ID3D12GraphicsCommandList::Close` | wrapper | recording; CPU query fallback flush when applicable. |
> | `ID3D12GraphicsCommandList::CopyBufferRegion` | predicated | Predication applies on DIRECT/COMPUTE. COPY does not support predicate selection. |
> | `ID3D12GraphicsCommandList::CopyResource` | predicated | Predication applies on DIRECT/COMPUTE. COPY does not support predicate selection. |
> | `ID3D12GraphicsCommandList::CopyTextureRegion` | predicated | Predication applies on DIRECT/COMPUTE. COPY does not support predicate selection. |
> | `ID3D12GraphicsCommandList::CopyTiles` | predicated | Permitted copy operation contexts; predicate state availability separate. |
> | `ID3D12GraphicsCommandList::DiscardResource` | unpredicated | Discard is a hint; no conditional preservation of resource contents is guaranteed. An implementation may ignore the hint. |
> | `ID3D12GraphicsCommandList::Dispatch` | predicated | DIRECT/COMPUTE. BUNDLE only when that operation independently permits it. |
> | `ID3D12GraphicsCommandList::DrawIndexedInstanced` | predicated | DIRECT; permitted BUNDLE operations use the inherited predicate. |
> | `ID3D12GraphicsCommandList::DrawInstanced` | predicated | DIRECT; permitted BUNDLE operations use the inherited predicate. |
> | `ID3D12GraphicsCommandList::EndQuery` | unpredicated | Only the query/list/heap combinations in the support tables. |
> | `ID3D12GraphicsCommandList::ExecuteBundle` | wrapper | DIRECT executes BUNDLE. |
> | [`ID3D12GraphicsCommandList::ExecuteIndirect`](indirect-execution.md#recording-contexts) | wrapper | DIRECT/COMPUTE; restricted BUNDLE; signature-dependent. Eligible generated GPU work honors the predicate; required post-call state cleanup still occurs. |
> | `ID3D12GraphicsCommandList::ResolveQueryData` | unpredicated | Only the query/list/heap combinations in the GPU resolution support table. |
> | `ID3D12GraphicsCommandList::ResolveSubresource` | predicated | DIRECT. |
> | `ID3D12GraphicsCommandList::ResourceBarrier` | unpredicated | On the independently supported list types. |
> | [`ID3D12VideoDecodeCommandList1::DecodeFrame1`](video-decode.md#decode-frame1) | predicated | VIDEO_DECODE; versioned shared decode operation. |
> | [`ID3D12VideoDecodeCommandList2::ExecuteExtensionCommand`](video-extension-commands.md#videodecodecommandlist2-executeextensioncommand) | conditional | VIDEO_DECODE. Predicate behavior is defined by the extension; no API-wide guarantee. |
> | [`ID3D12VideoDecodeCommandList2::InitializeExtensionCommand`](video-extension-commands.md#videodecodecommandlist2-initializeextensioncommand) | conditional | VIDEO_DECODE. Predicate behavior is defined by the extension; no API-wide guarantee. |
> | `ID3D12VideoDecodeCommandList3::Barrier` | unpredicated | video decode. |
> | `ID3D12VideoDecodeCommandList::BeginQuery` | unsupported | VIDEO_DECODE supports only end-only timestamp/decode statistics query types. |
> | `ID3D12VideoDecodeCommandList::Close` | wrapper | recording; CPU query fallback flush when applicable. |
> | [`ID3D12VideoDecodeCommandList::DecodeFrame`](video-decode.md#decode-frame) | predicated | VIDEO_DECODE. |
> | `ID3D12VideoDecodeCommandList::DiscardResource` | unpredicated | Discard is a hint; no conditional preservation of resource contents is guaranteed. An implementation may ignore the hint. |
> | `ID3D12VideoDecodeCommandList::EndQuery` | unpredicated | VIDEO_DECODE timestamp or decode statistics. |
> | `ID3D12VideoDecodeCommandList::ResolveQueryData` | unpredicated | Only the query/list/heap combinations in the GPU resolution support table. |
> | `ID3D12VideoDecodeCommandList::ResourceBarrier` | unpredicated | video decode. |
> | `ID3D12VideoDecodeCommandList::WriteBufferImmediate` | predicated | On permitted list types. COPY has no supported predicate selection. |
> | [`ID3D12VideoEncodeCommandList1::ExecuteExtensionCommand`](video-extension-commands.md#videoencodecommandlist1-executeextensioncommand) | conditional | VIDEO_ENCODE. Predicate behavior is defined by the extension; no API-wide guarantee. |
> | [`ID3D12VideoEncodeCommandList1::InitializeExtensionCommand`](video-extension-commands.md#videoencodecommandlist1-initializeextensioncommand) | conditional | VIDEO_ENCODE. Predicate behavior is defined by the extension; no API-wide guarantee. |
> | [`ID3D12VideoEncodeCommandList2::EncodeFrame`](video-encoding.md#id3d12videoencodecommandlist2--encodeframe) | predicated | VIDEO_ENCODE; codec/support requirements separate. |
> | [`ID3D12VideoEncodeCommandList2::ResolveEncoderOutputMetadata`](video-encoding.md#id3d12videoencodecommandlist2--resolveencoderoutputmetadata) | predicated | VIDEO_ENCODE; metadata resolution operation. |
> | `ID3D12VideoEncodeCommandList3::Barrier` | unpredicated | video encode. |
> | [`ID3D12VideoEncodeCommandList4::EncodeFrame1`](video-encoding.md#id3d12videoencodecommandlist4--encodeframe1) | predicated | VIDEO_ENCODE; supported codec/argument/conversion paths only. |
> | [`ID3D12VideoEncodeCommandList4::ResolveEncoderOutputMetadata1`](video-encoding.md#id3d12videoencodecommandlist4--resolveencoderoutputmetadata1) | predicated | VIDEO_ENCODE; supported codec/argument/conversion paths only. |
> | [`ID3D12VideoEncodeCommandList4::ResolveInputParamLayout`](video-encoding.md#id3d12videoencodecommandlist4--resolveinputparamlayout) | predicated | VIDEO_ENCODE; supported codec/argument/conversion paths only. |
> | `ID3D12VideoEncodeCommandList::BeginQuery` | unsupported | VIDEO_ENCODE supports timestamp only. |
> | `ID3D12VideoEncodeCommandList::Close` | wrapper | recording; CPU query fallback flush when applicable. |
> | `ID3D12VideoEncodeCommandList::DiscardResource` | unpredicated | Discard is a hint; no conditional preservation of resource contents is guaranteed. An implementation may ignore the hint. |
> | `ID3D12VideoEncodeCommandList::EndQuery` | unpredicated | VIDEO_ENCODE timestamp. |
> | [`ID3D12VideoEncodeCommandList::EstimateMotion`](video-motion-estimation.md#motion-estimate) | predicated | VIDEO_ENCODE; motion estimation support. |
> | [`ID3D12VideoEncodeCommandList::ResolveMotionVectorHeap`](video-motion-estimation.md#motion-resolve) | predicated | VIDEO_ENCODE; motion estimation support. |
> | `ID3D12VideoEncodeCommandList::ResolveQueryData` | unpredicated | Only the query/list/heap combinations in the GPU resolution support table. |
> | `ID3D12VideoEncodeCommandList::ResourceBarrier` | unpredicated | video encode. |
> | `ID3D12VideoEncodeCommandList::WriteBufferImmediate` | predicated | On permitted list types. COPY has no supported predicate selection. |
> | [`ID3D12VideoProcessCommandList1::ProcessFrames1`](video-processing.md#process-frames1) | predicated | VIDEO_PROCESS; versioned shared process operation. |
> | [`ID3D12VideoProcessCommandList2::ExecuteExtensionCommand`](video-extension-commands.md#videoprocesscommandlist2-executeextensioncommand) | conditional | VIDEO_PROCESS. Predicate behavior is defined by the extension; no API-wide guarantee. |
> | [`ID3D12VideoProcessCommandList2::InitializeExtensionCommand`](video-extension-commands.md#videoprocesscommandlist2-initializeextensioncommand) | conditional | VIDEO_PROCESS. Predicate behavior is defined by the extension; no API-wide guarantee. |
> | `ID3D12VideoProcessCommandList3::Barrier` | unpredicated | video process. |
> | `ID3D12VideoProcessCommandList::BeginQuery` | unsupported | VIDEO_PROCESS supports timestamp only. |
> | `ID3D12VideoProcessCommandList::Close` | wrapper | recording; CPU query fallback flush when applicable. |
> | `ID3D12VideoProcessCommandList::DiscardResource` | unpredicated | Discard is a hint; no conditional preservation of resource contents is guaranteed. An implementation may ignore the hint. |
> | `ID3D12VideoProcessCommandList::EndQuery` | unpredicated | VIDEO_PROCESS timestamp. |
> | [`ID3D12VideoProcessCommandList::ProcessFrames`](video-processing.md#process-frames) | predicated | VIDEO_PROCESS. |
> | `ID3D12VideoProcessCommandList::ResolveQueryData` | unpredicated | Only the query/list/heap combinations in the GPU resolution support table. |
> | `ID3D12VideoProcessCommandList::ResourceBarrier` | unpredicated | video process. |
> | `ID3D12VideoProcessCommandList::WriteBufferImmediate` | predicated | On permitted list types. COPY has no supported predicate selection. |

<!-- d3d12-review-alert:end:queries:N-operation-matrix:0:authored:migration-cdd0ec395055d67c-0 -->

<ins><!-- d3d12-review-inline:begin:queries:N-operation-boundaries:0:authored:migration-778aaabdb5d7e944-0 -->State/recording/annotation methods do not acquire a blanket skip condition from an active predicate. Some state methods also schedule maintenance work, which is separately qualified above. Query Begin/End and result resolution are not predicated. Wrappers and their generated work must be distinguished: ExecuteBundle preserves state execution while eligible bundle work uses the inherited predicate. ExecuteIndirect-generated eligible actions honor predication while required state cleanup remains independent.<!-- d3d12-review-inline:end:queries:N-operation-boundaries:0:authored:migration-778aaabdb5d7e944-0 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:N-operation-boundaries:1:authored:migration-2118a710cf143e18-0 -->For render passes translated into ordinary clear/resolve operations, beginning access CLEAR and ending access RESOLVE honor the predicate through those operations. Bindings, barriers and pass boundaries are not themselves skipped. Resuming does not repeat the beginning clear; suspending does not perform ending resolves. Native pass execution retains the [render pass access contract](output-merger.md#render-pass-access). The CLEAR/RESOLVE rule does not assign a blanket conditional behavior to every implicit load, store or discard. Each work operation retains its independent command type, capability, access and validity restrictions.<!-- d3d12-review-inline:end:queries:N-operation-boundaries:1:authored:migration-2118a710cf143e18-0 --></ins>

<a id="query-driver"></a>

## Driver and hardware responsibilities

<a id="ddi-query-lifetime"></a>

### Query heap types and lifetime

<a id="d3d12ddi-predication-op"></a>

```cpp
typedef enum D3D12DDI_QUERY_HEAP_TYPE
{
    D3D12DDI_QUERY_HEAP_TYPE_OCCLUSION                      = 0,
    D3D12DDI_QUERY_HEAP_TYPE_TIMESTAMP                      = 1,
    D3D12DDI_QUERY_HEAP_TYPE_PIPELINE_STATISTICS            = 2,
    D3D12DDI_QUERY_HEAP_TYPE_SO_STATISTICS                  = 3,
    D3D12DDI_QUERY_HEAP_TYPE_0020_VIDEO_DECODE_STATISTICS   = 4,
    D3D12DDI_QUERY_HEAP_TYPE_0032_COPY_QUEUE_TIMESTAMP      = 5,
    D3D12DDI_QUERY_HEAP_TYPE_PIPELINE_STATISTICS1           = 7,
} D3D12DDI_QUERY_HEAP_TYPE;

typedef enum D3D12DDI_QUERY_TYPE
{
    D3D12DDI_QUERY_TYPE_OCCLUSION                       = 0,
    D3D12DDI_QUERY_TYPE_BINARY_OCCLUSION                = 1,
    D3D12DDI_QUERY_TYPE_TIMESTAMP                       = 2,
    D3D12DDI_QUERY_TYPE_PIPELINE_STATISTICS             = 3,
    D3D12DDI_QUERY_TYPE_SO_STATISTICS_STREAM0           = 4,
    D3D12DDI_QUERY_TYPE_SO_STATISTICS_STREAM1           = 5,
    D3D12DDI_QUERY_TYPE_SO_STATISTICS_STREAM2           = 6,
    D3D12DDI_QUERY_TYPE_SO_STATISTICS_STREAM3           = 7,
    D3D12DDI_QUERY_TYPE_0020_VIDEO_DECODE_STATISTICS    = 8,
    D3D12DDI_QUERY_TYPE_PIPELINE_STATISTICS1            = 10,

} D3D12DDI_QUERY_TYPE;

typedef enum D3D12DDI_PREDICATION_OP
{
    D3D12DDI_PREDICATION_OP_EQUAL_ZERO     = 0,
    D3D12DDI_PREDICATION_OP_NOT_EQUAL_ZERO = 1,
} D3D12DDI_PREDICATION_OP;

typedef struct D3D12DDIARG_CREATE_QUERY_HEAP_0001
{
    D3D12DDI_QUERY_HEAP_TYPE    Type;
    UINT                        Count;
    UINT                        NodeMask;
} D3D12DDIARG_CREATE_QUERY_HEAP_0001;
```

```cpp
typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALC_PRIVATE_QUERY_HEAP_SIZE_0001 )( D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATE_QUERY_HEAP_0001* );

typedef VOID ( APIENTRY* PFND3D12DDI_DESTROY_QUERY_HEAP ) ( D3D12DDI_HDEVICE, D3D12DDI_HQUERYHEAP );
```

<ins><!-- d3d12-review-inline:begin:queries:QD-lifecycle-roles:0:authored:migration-47c90330667661a2-0 -->The runtime allocates the private bytes reported by the sizing DDI and passes that storage through `D3D12DDI_HQUERYHEAP` to Create. The driver owns any additional allocations it makes, but must not free the runtime-supplied private region.<!-- d3d12-review-inline:end:queries:QD-lifecycle-roles:0:authored:migration-47c90330667661a2-0 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:QD-lifecycle-roles:1:authored:migration-d886989b9aeaa74c-0 -->A failed Create must unwind partial driver state and allocations. The runtime calls DestroyQueryHeap only after successful driver creation, including when later API initialization fails. Destroy releases driver-owned state without freeing the runtime-supplied private region.<!-- d3d12-review-inline:end:queries:QD-lifecycle-roles:1:authored:migration-d886989b9aeaa74c-0 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:QD-lifecycle-roles:2:authored:migration-6b745576bc6a71eb-0 -->Query heap creation receives the driver `Type`, element `Count` and resolved `NodeMask`. CPU resolution path selection is specified separately under [CPU query flags](#cpu-query-flags).<!-- d3d12-review-inline:end:queries:QD-lifecycle-roles:2:authored:migration-6b745576bc6a71eb-0 --></ins>

#### Driver handle storage

`D3D12DDI_HQUERYHEAP`

<ins><!-- d3d12-review-inline:begin:queries:OI6-storage:0:preserved-repair:opaque-heap-relocation -->The handle of a query heap, which represents an array of query results. The underlying data representation of a query result is IHV dependent in query heaps and opaque to applications. Query results are stored in a query heap until they are later “resolved” into the API defined format.<!-- d3d12-review-inline:end:queries:OI6-storage:0:preserved-repair:opaque-heap-relocation --></ins>

`D3D12DDI_HCOMMANDLIST`

<ins><!-- d3d12-review-inline:begin:queries:OI6-storage:1:preserved-repair:command-list-relocation -->A handle to the driver's data for the command list. The driver uses this region of memory to store internal data structures that are related to its command list.<!-- d3d12-review-inline:end:queries:OI6-storage:1:preserved-repair:command-list-relocation --></ins>

<a id="ddi-create-query-heap"></a>

### PFND3D12DDI_CREATE_QUERY_HEAP_0001

```cpp
typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATE_QUERY_HEAP_0001 ) ( D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATE_QUERY_HEAP_0001*, D3D12DDI_HQUERYHEAP );
```

#### Parameters

`unnamedParam1`

A handle to the display device (graphics context).

`unnamedParam2`

Pointer to a D3D12DDIARG\_CREATE\_QUERY\_HEAP\_0001 structure.

`unnamedParam3`

A query heap handle.

<a id="ddi-recording-contracts"></a>

### Recording API associations and shared rules

<!-- d3d12-review-alert:begin:queries:N-ddi-parameter-bridge:0:authored:oi6-association-relocation -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Driver slot / operation | Precise API contracts |
> |---|---|
> | `pfnBeginQuery` using `PFND3D12DDI_BEGIN_END_QUERY_0003` | [Graphics](#graphics-beginquery), [decode](#videodecode-beginquery), [process](#videoprocess-beginquery), [encode](#videoencode-beginquery), subject to the issuance table |
> | `pfnEndQuery` using `PFND3D12DDI_BEGIN_END_QUERY_0003` | [Graphics](#graphics-endquery), [decode](#videodecode-endquery), [process](#videoprocess-endquery), [encode](#videoencode-endquery) |
> | `PFND3D12DDI_RESOLVE_QUERY_DATA` | [Graphics](#graphics-resolvequerydata), [decode](#videodecode-resolvequerydata), [process](#videoprocess-resolvequerydata), [encode](#videoencode-resolvequerydata) |
> | `PFND3D12DDI_SET_PREDICATION` | [Graphics](#graphics-setpredication), [decode](#videodecode-setpredication), [process](#videoprocess-setpredication), [encode](#videoencode-setpredication) |

<!-- d3d12-review-alert:end:queries:N-ddi-parameter-bridge:0:authored:oi6-association-relocation -->

<ins><!-- d3d12-review-inline:begin:queries:QD-recording-boundaries:0:authored:migration-06099e3aa49cd543-0 -->The DDIs implement the query and predication operations identified in the table above.<!-- d3d12-review-inline:end:queries:QD-recording-boundaries:0:authored:migration-06099e3aa49cd543-0 --></ins>

<a id="ddi-begin-end-query"></a>

### PFND3D12DDI_BEGIN_END_QUERY_0003

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_BEGIN_END_QUERY_0003 )( D3D12DDI_HCOMMANDLIST, D3D12DDI_HQUERYHEAP, D3D12DDI_QUERY_TYPE, UINT );
```

#### Parameters

`unnamedParam4`

*<ins><!-- d3d12-review-inline:begin:queries:DDI-ddi-begin-end-query:12:modified:source-60adfd547931ad76-0-0 -->Index<!-- d3d12-review-inline:end:queries:DDI-ddi-begin-end-query:12:modified:source-60adfd547931ad76-0-0 --></ins>*

The <ins><!-- d3d12-review-inline:begin:queries:DDI-ddi-begin-end-query:13:modified:source-2d3222c9b8327950-0-0 -->zero-based index of the single query<!-- d3d12-review-inline:end:queries:DDI-ddi-begin-end-query:13:modified:source-2d3222c9b8327950-0-0 --></ins> element.

#### Driver behavior

<ins><!-- d3d12-review-inline:begin:queries:QD-begin-end-roles:0:authored:migration-e5ed925ed6ea35c4-0 -->`pfnBeginQuery` and `pfnEndQuery` share `PFND3D12DDI_BEGIN_END_QUERY_0003`. The selected slot identifies the phase.<!-- d3d12-review-inline:end:queries:QD-begin-end-roles:0:authored:migration-e5ed925ed6ea35c4-0 --></ins>

<a id="ddi-resolve-query"></a>

### PFND3D12DDI_RESOLVE_QUERY_DATA

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_RESOLVE_QUERY_DATA )(
    D3D12DDI_HCOMMANDLIST,
    D3D12DDI_HQUERYHEAP,
    D3D12DDI_QUERY_TYPE,
    UINT StartElement,
    UINT ElementCount,
    D3D12DDI_HRESOURCE hDrvDestinationBuffer,
    UINT64 DestinationOffset
    );
```

#### Driver behavior

<ins><!-- d3d12-review-inline:begin:queries:QD-resolve-roles:0:authored:migration-1a6eb90c07b79696-0 -->The driver converts opaque query storage into the [API result layout](#result-layout) in the supplied destination resource. The opaque heap's internal representation need not match that layout.<!-- d3d12-review-inline:end:queries:QD-resolve-roles:0:authored:migration-1a6eb90c07b79696-0 --></ins>

<ins><!-- d3d12-review-inline:begin:queries:QD-resolve-roles:1:authored:migration-4c5385fcd8388add-0 -->The `CPU_RESOLVE` restriction on application GPU resolution calls does not prohibit the runtime's internal use of this DDI for [CPU resolution fallback](#cpu-resolution).<!-- d3d12-review-inline:end:queries:QD-resolve-roles:1:authored:migration-4c5385fcd8388add-0 --></ins>

<a id="ddi-set-predication"></a>

### PFND3D12DDI_SET_PREDICATION

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_SET_PREDICATION )( D3D12DDI_HCOMMANDLIST, D3D12DDI_HRESOURCE, UINT64, D3D12DDI_PREDICATION_OP );
```

#### Parameters

`unnamedParam3`

<ins><!-- d3d12-review-inline:begin:queries:DDI-ddi-set-predication:9:authored:migration-4a45b1c8d60661cc-0 -->The byte offset of the 64-bit predicate source.<!-- d3d12-review-inline:end:queries:DDI-ddi-set-predication:9:authored:migration-4a45b1c8d60661cc-0 --></ins>

#### Driver behavior

<ins><!-- d3d12-review-inline:begin:queries:QD-predicate-roles:1:authored:migration-8f5413eb6da793d8-0 -->The driver comparison enum names specify when to skip work. Use the [predicate truth table](#predication) when translating the API operation.<!-- d3d12-review-inline:end:queries:QD-predicate-roles:1:authored:migration-8f5413eb6da793d8-0 --></ins>

<a id="ddi-cpu-resolution"></a>

### CPU timeline driver resolution

<ins><!-- d3d12-review-inline:begin:queries:N-cpu-ddi:0:authored:migration-d291ef3ff57a809c-0 -->The CPU resolution path and its runtime fallback are specified under [CPU query resolution](#cpu-resolution).<!-- d3d12-review-inline:end:queries:N-cpu-ddi:0:authored:migration-d291ef3ff57a809c-0 --></ins>
