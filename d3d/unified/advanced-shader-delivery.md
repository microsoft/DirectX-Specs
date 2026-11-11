<a id="advanced-shader-delivery"></a>

# Advanced Shader Delivery

Advanced Shader Delivery (ASD) connects stored pipeline state object (PSO) and state object (SO)
inputs with offline driver compilation and delivery of precompiled output.
A state object database (SODB) contains creation inputs and shader bytecode.
Offline compilation produces target-specific output in a precompiled shader
database (PSDB). Delivery registers installed database paths for runtime
discovery and use.

<a id="reference-material"></a>

## Reference material

* **Inputs:** [SODB storage, keys, versions, dependencies and reconstruction](state-object-databases-and-identity.md),
  with the complete [published SODB format](state-object-database-format.md) as its schema reference.
* **Offline compilation:** the compiler API reference starts with
  [factory discovery, targets and version/profile queries](offline-compilation.md)
  and continues with [invocation and cache output](compiler-invocation-and-cache-output.md).
  [Compiler plugin DDI](compiler-plugin-foundation.md) supplies the implementer-facing
  opening, negotiation and capability reference; the invocation reference also contains
  the compiler/cache DDI contracts.
* **Delivery:** the [registration reference](shader-cache-registration.md#installation-and-updates)
  follows the installation workflow through catalog identity and target discovery to the
  [registration ABI](shader-cache-registration.md#registration-abi) and method reference.
* **Consumption:** [runtime cache consumption](runtime-cache-discovery.md)
  covers discovery, compatibility and [compiled-value lookup](runtime-cache-discovery.md#compiled-value-lookup)
  during ordinary creation.

[Application caches, cache controls, cached PSO blobs and pipeline libraries](shader-delivery-and-caching.md)
are separate..
