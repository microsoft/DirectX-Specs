<a id="advanced-shader-delivery"></a>

# Advanced Shader Delivery

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

<!-- d3d12-review-alert:begin:asd-overview:overview:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Advanced Shader Delivery (ASD) connects stored pipeline-state and state-object
> inputs with offline driver compilation and delivery of precompiled output.
> A state-object database (SODB) contains creation inputs and shader bytecode;
> offline compilation produces target-specific output in a precompiled shader
> database (PSDB). Delivery registers installed database paths for runtime
> discovery and compatibility selection. Registration, a compatible database
> open and a compiled-value hit are distinct.

<!-- d3d12-review-alert:end:asd-overview:overview:0 -->

<a id="reference-material"></a>

## Reference material

* <ins><!-- d3d12-review-inline:begin:asd-overview:references:0 -->**Inputs:** [SODB storage, keys, versions, dependencies and reconstruction](state-object-databases-and-identity.md),<!-- d3d12-review-inline:end:asd-overview:references:0 --></ins>
  with the complete [published SODB format](state-object-database-format.md) as its schema reference.
* <ins><!-- d3d12-review-inline:begin:asd-overview:references:0 -->**Offline compilation:** the compiler API reference starts with<!-- d3d12-review-inline:end:asd-overview:references:0 --></ins>
  [factory discovery, targets and version/profile queries](offline-compilation.md)
  and continues with [invocation and cache output](compiler-invocation-and-cache-output.md).
  [Compiler plugin DDI](compiler-plugin-foundation.md) supplies the implementer-facing
  opening, negotiation and capability reference; the invocation reference also contains
  the compiler/cache DDI contracts.
* <ins><!-- d3d12-review-inline:begin:asd-overview:references:0 -->**Delivery:** the [registration reference](shader-cache-registration.md#installation-and-updates)<!-- d3d12-review-inline:end:asd-overview:references:0 --></ins>
  follows the installation workflow through catalog identity and target discovery to the
  [registration ABI](shader-cache-registration.md#registration-abi) and method reference.
* <ins><!-- d3d12-review-inline:begin:asd-overview:references:0 -->**Consumption:** [runtime cache consumption](runtime-cache-discovery.md)<!-- d3d12-review-inline:end:asd-overview:references:0 --></ins>
  covers discovery, compatibility and [compiled-value lookup](runtime-cache-discovery.md#compiled-value-lookup)
  during ordinary creation.

<!-- d3d12-review-alert:begin:asd-overview:references:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> [Application caches, cache controls, cached PSO blobs and pipeline libraries](shader-delivery-and-caching.md)
> retain their separate contracts.

<!-- d3d12-review-alert:end:asd-overview:references:1 -->
