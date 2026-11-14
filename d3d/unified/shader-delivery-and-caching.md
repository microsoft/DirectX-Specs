<a id="shader-delivery-and-caching"></a>

# Shader delivery and caching

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

<ins><!-- d3d12-review-inline:begin:shader-cache:framing:0:authored:migration-0e7d8601ca6c4b9f-0 -->Ordinary offline frontend compilation translates source into DXBC or DXIL bytecode.
[Offline driver/pipeline compilation](offline-compilation.md#compiler-runtime-design)
produces vendor-dependent pipeline state and state object output from that bytecode.<!-- d3d12-review-inline:end:shader-cache:framing:0:authored:migration-0e7d8601ca6c4b9f-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:framing:1:authored:migration-96d71e0bd11851b5-0 -->Cached pipeline state blobs and pipeline libraries are supported legacy mechanisms.
Legacy classification does not make their methods removed, deprecated or no-ops.
Their complete storage, lifetime, matching and compatibility contracts apply.<!-- d3d12-review-inline:end:shader-cache:framing:1:authored:migration-96d71e0bd11851b5-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:framing:2:authored:migration-bbfd74208e4cc5d2-0 -->Application cache sessions store application-selected opaque key/value data.
They are distinct from the caches used for driver compilations or runtime shader
conversions. A cache operation does not compile, validate or sign its values.<!-- d3d12-review-inline:end:shader-cache:framing:2:authored:migration-bbfd74208e4cc5d2-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:owners:0:authored:migration-3df9dcd91ec9ad88-0 -->Pipeline state defines [aggregate PSO descriptions](pipeline-state.md#aggregate-descriptions),
[stream descriptions](pipeline-state.md#streams), [PSO creation APIs](pipeline-state.md#apis)
and [cached PSO input consumption](pipeline-state.md#cached-data).
[Shader hash-bypass capability](devices-and-capabilities.md#d3d12_feature_data_bytecode_bypass_hash_supported)
and [bytecode validation policy](diagnostics.md#d3d12-debug-device-bytecode-validation-mode)
qualify shader acceptance; cache storage does not add an unconditional signed-shader
requirement. [Feature queries](devices-and-capabilities.md#id3d12device-checkfeaturesupport)
own payload layout and query validation. [CPU threading](execution.md#threading)
and [submitted-object lifetime](execution.md#lifetime) remain execution
contracts.<!-- d3d12-review-inline:end:shader-cache:owners:0:authored:migration-3df9dcd91ec9ad88-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:D147-ASD-reference:0:authored:migration-a735b683289156cf-0 -->[Advanced Shader Delivery](advanced-shader-delivery.md) groups SODB inputs, offline compiler interfaces and registered precompiled shader database (PSDB) delivery. [Compiler cache sessions](compiler-invocation-and-cache-output.md#output-storage) store typed compilation results and group mappings, distinct from the application-selected opaque values and supported legacy pipeline caches below. [Runtime discovery](runtime-cache-discovery.md#runtime-cache-discovery) defines read-only PSDB eligibility and [retained initialization state](runtime-cache-discovery.md#failure-and-lifetime). It is not a cache-hit guarantee or a promise that cache controls rediscover a different registered component.<!-- d3d12-review-inline:end:shader-cache:D147-ASD-reference:0:authored:migration-a735b683289156cf-0 --></ins>

<a id="cache-support"></a>

## Cache support and availability

<ins><!-- d3d12-review-inline:begin:shader-cache:capability-owner:0:authored:migration-13431584d701115a-0 -->The `SupportFlags` output of
[`D3D12_FEATURE_DATA_SHADER_CACHE`](devices-and-capabilities.md#d3d12_feature_data_shader_cache)
uses the following bits. [`D3D12_FEATURE_DATA_SHADERCACHE_ABI_SUPPORT`](devices-and-capabilities.md#d3d12_feature_data_shadercache_abi_support)
is a distinct query. Its ABI range is not a portability guarantee for a legacy
serialized library or cached PSO.<!-- d3d12-review-inline:end:shader-cache:capability-owner:0:authored:migration-13431584d701115a-0 --></ins>

<a id="d3d12-shader-cache-support-flags"></a>

### D3D12_SHADER_CACHE_SUPPORT_FLAGS

```cpp
typedef enum D3D12_SHADER_CACHE_SUPPORT_FLAGS
{
    D3D12_SHADER_CACHE_SUPPORT_NONE                     = 0x0,
    D3D12_SHADER_CACHE_SUPPORT_SINGLE_PSO               = 0x1, // Always supported
    D3D12_SHADER_CACHE_SUPPORT_LIBRARY                  = 0x2,
    D3D12_SHADER_CACHE_SUPPORT_AUTOMATIC_INPROC_CACHE   = 0x4,
    D3D12_SHADER_CACHE_SUPPORT_AUTOMATIC_DISK_CACHE     = 0x8,
    D3D12_SHADER_CACHE_SUPPORT_DRIVER_MANAGED_CACHE     = 0x10,
    D3D12_SHADER_CACHE_SUPPORT_SHADER_CONTROL_CLEAR     = 0x20,
    D3D12_SHADER_CACHE_SUPPORT_SHADER_SESSION_DELETE    = 0x40
} D3D12_SHADER_CACHE_SUPPORT_FLAGS;
```

<!-- d3d12-review-alert:begin:shader-cache:support-meaning:0:authored:migration-8e1e610157f9a7c2-0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Flag | Meaning |
> | --- | --- |
> | `NONE` | No shader cache support bits. |
> | `SINGLE_PSO` | Supports the `CachedPSO` member of graphics and compute PSO descriptions. This is always supported. |
> | `LIBRARY` | Supports application-controlled PSO grouping/caching through `ID3D12PipelineLibrary`. |
> | `AUTOMATIC_INPROC_CACHE` | OS-managed compiled-shader cache in memory during the application's current run. |
> | `AUTOMATIC_DISK_CACHE` | OS-managed compiled-shader cache on disk for future application runs. |
> | `DRIVER_MANAGED_CACHE` | Reports the presence of a cache managed by the driver. |
> | `SHADER_CONTROL_CLEAR` | Reports support for `CLEAR` without developer mode. `ENABLE` and `DISABLE` still require developer mode, including when combined with `CLEAR`. |
> | `SHADER_SESSION_DELETE` | Reports support for deleting shader cache sessions. |

<!-- d3d12-review-alert:end:shader-cache:support-meaning:0:authored:migration-8e1e610157f9a7c2-0 -->

<ins><!-- d3d12-review-inline:begin:shader-cache:support-meaning:1:authored:migration-6394dad8901abc31-0 -->The shortened flag names in this table have prefix `D3D12_SHADER_CACHE_SUPPORT_`.
Support bits describe capabilities, not the presence of a particular cache entry.
An implicit cache kind may not exist even when a control request names it.
Application session availability, clear capability and developer mode permission
for enabling/disabling caches are separate conditions; driver compilation cache support is not application value validation.<!-- d3d12-review-inline:end:shader-cache:support-meaning:1:authored:migration-6394dad8901abc31-0 --></ins>

<a id="cache-sessions"></a>

## Application-owned cache sessions

<ins><!-- d3d12-review-inline:begin:shader-cache:session-type-owners:0:authored:migration-886f53bc9dbb1a70-0 -->Sessions use the [session descriptor](#d3d12-shader-cache-session-desc),
[storage modes](#d3d12-shader-cache-mode) and [session flags](#d3d12-shader-cache-flags).
Cache control uses the separate [kind mask](#d3d12-shader-cache-kind-flags)
and [control mask](#d3d12-shader-cache-control-flags). These types are not PSO
descriptions or shader bytecode containers.<!-- d3d12-review-inline:end:shader-cache:session-type-owners:0:authored:migration-886f53bc9dbb1a70-0 --></ins>

<!-- d3d12-review-alert:begin:shader-cache:session-background:0:modified:migration-7fd3131cc06cdc1e-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> Windows includes a component called D3DSCache, which is a DirectX Shader Cache. This component manages caches of key/value pairs which are:
> * Process-local: the cache is tied to the executable that created it.
> * UWP friendly
> * Integrated with disk cleanup and other OS policy
> * Versioned
> * Accessible to applications through cache sessions
>
> D3DSCache also serves these runtime and driver purposes:
> 1. As an alternative to IHV-provided custom-built shader caches for driver shader compilations or other transient data
> 2. For D3D12 applications which provide DXBC shaders, but drivers want DXIL, D3D12 will perform this conversion and cache the result

<!-- d3d12-review-alert:end:shader-cache:session-background:0:modified:migration-7fd3131cc06cdc1e-0 -->

<ins><!-- d3d12-review-inline:begin:shader-cache:session-background:1:modified:source-187e99be2a54f6cb-0-0 -->Application cache sessions<!-- d3d12-review-inline:end:shader-cache:session-background:1:modified:source-187e99be2a54f6cb-0-0 --></ins> enable applications to cache DXBC, DXIL, or other intermediate shader code representations, tied to some opaque key. For example, an app might have an input pre-compiled shader, combined with some set of constants, which map to a specialized variation of that shader. The first time the app sees a specific combination of (shader + constants), i.e. the key, they would perform the specialization and cache the result. The next time they see it, they can look it up from the cache.

<a id="d3d12-shader-cache-mode"></a>

### D3D12_SHADER_CACHE_MODE

```cpp
typedef enum D3D12_SHADER_CACHE_MODE
{
    D3D12_SHADER_CACHE_MODE_MEMORY,
    D3D12_SHADER_CACHE_MODE_DISK,
} D3D12_SHADER_CACHE_MODE;
```

<!-- d3d12-review-alert:begin:shader-cache:semantics-D3D12_SHADER_CACHE_MODE:0:modified:migration-2eb22a19ae76fb73-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Value | Meaning |
> | --- | --- |
> | `D3D12_SHADER_CACHE_MODE_MEMORY` | There is no backing file for this cache. All stores are discarded when the last session for that underlying cache is destroyed. |
> | `D3D12_SHADER_CACHE_MODE_DISK` | The session is backed by files on disk, that will persist from run to run, unless cleared. |
>
> Disk caches can be cleared in one of these ways:
> 1. Explicitly, by calling `SetDeleteOnDestroy()` on the session object, and then releasing all corresponding sessions.
> 2. Explicitly, by calling `ShaderCacheControl()` with `D3D12_SHADER_CACHE_KIND_FLAG_APPLICATION_MANAGED` and `CLEAR`. Outside developer mode, clear-only control requires `D3D12_SHADER_CACHE_SUPPORT_SHADER_CONTROL_CLEAR`; any combined `ENABLE` or `DISABLE` operation still requires developer mode.
> 3. Implicitly, by opening a cache with a different `Version` when no corresponding sessions remain open. With active corresponding sessions, creation instead returns `DXGI_ERROR_ALREADY_EXISTS`.
> 4. Externally, by the disk cleanup utility enumerating it and clearing it. This will not happen for caches created with the `D3D12_SHADER_CACHE_FLAG_USE_WORKING_DIR` flag.
> 5. Manually, by deleting the working-directory cache files stored on disk for `D3D12_SHADER_CACHE_FLAG_USE_WORKING_DIR` caches. The application should not attempt to do this for caches stored outside of the working directory.

<!-- d3d12-review-alert:end:shader-cache:semantics-D3D12_SHADER_CACHE_MODE:0:modified:migration-2eb22a19ae76fb73-0 -->

<ins><!-- d3d12-review-inline:begin:shader-cache:semantics-D3D12_SHADER_CACHE_MODE:1 -->Manual working-directory cleanup is not permission to delete an active cache's
backing files. The application must first release all corresponding sessions
that can access those files and obey operating-system ownership, access and
file sharing constraints. This permission does not extend to cache files
managed outside the working directory. Physical filename suffixes are not a
portable serialization contract.<!-- d3d12-review-inline:end:shader-cache:semantics-D3D12_SHADER_CACHE_MODE:1 --></ins>

<a id="d3d12-shader-cache-flags"></a>

### D3D12_SHADER_CACHE_FLAGS

```cpp
typedef enum D3D12_SHADER_CACHE_FLAGS
{
    D3D12_SHADER_CACHE_FLAG_NONE = 0x0,
    D3D12_SHADER_CACHE_FLAG_DRIVER_VERSIONED = 0x1,
    D3D12_SHADER_CACHE_FLAG_USE_WORKING_DIR = 0x2,
} D3D12_SHADER_CACHE_FLAGS;
```

<!-- d3d12-review-alert:begin:shader-cache:semantics-D3D12_SHADER_CACHE_FLAGS:0:modified:migration-73f0b97a609fdb9f-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Value | Meaning |
> | --- | --- |
> | `D3D12_SHADER_CACHE_FLAG_NONE` | No flags. |
> | `D3D12_SHADER_CACHE_FLAG_DRIVER_VERSIONED` | The cache is implicitly versioned by the driver being used. Caches created this way are stored side-by-side for each adapter on which the application runs for multi-GPU systems. The `Version` field in the cache description is used as an additional constraint. |
> | `D3D12_SHADER_CACHE_FLAG_USE_WORKING_DIR` | By default, caches are stored in temporary storage, and can be cleared by disk cleanup. When this flag is used (not valid for UWP apps), the cache is instead stored in the current working directory. |

<!-- d3d12-review-alert:end:shader-cache:semantics-D3D12_SHADER_CACHE_FLAGS:0:modified:migration-73f0b97a609fdb9f-0 -->

<a id="d3d12-shader-cache-session-desc"></a>

### D3D12_SHADER_CACHE_SESSION_DESC

```cpp
typedef struct D3D12_SHADER_CACHE_SESSION_DESC
{
    GUID Identifier;
    D3D12_SHADER_CACHE_MODE Mode;
    D3D12_SHADER_CACHE_FLAGS Flags;

    UINT MaximumInMemoryCacheSizeBytes;
    UINT MaximumInMemoryCacheEntries;

    UINT MaximumValueFileSizeBytes;

    UINT64 Version;
} D3D12_SHADER_CACHE_SESSION_DESC;
```

<!-- d3d12-review-alert:begin:shader-cache:semantics-D3D12_SHADER_CACHE_SESSION_DESC:0:modified:migration-f2baa65949e0c57e-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Field | Description |
> | --- | --- |
> | `Identifier` | A unique identifier for this specific cache. Caches with different identifiers are stored side-by-side. Caches with the same identifier are shared across all sessions in the same process. Creating a disk cache with the same identifier as an already-existing cache will open that cache, unless the `Version` mismatches. In that case, if there are no other sessions open to that cache, it is cleared and re-created. If there are existing sessions, CreateShaderCacheSession returns `DXGI_ERROR_ALREADY_EXISTS`. |
> | `Mode` | Determines what kind of cache to create/open. |
> | `Flags` | Modifies behavior of the cache. |
> | `MaximumInMemoryCacheSizeBytes` | In `MEMORY` mode, controls the byte size policy for the in-memory cache. It does not impose a separate temporary entry cache limit in `DISK` mode. |
> | `MaximumInMemoryCacheEntries` | Legacy ABI field. It is ignored for capacity and eviction; it does not enforce an entry count limit. `GetDesc` echoes this input field. |
> | `MaximumValueFileSizeBytes` | In `DISK` mode, controls the byte size policy for the backing cache. It is not the `MEMORY` mode byte quota. |
> | `Version` | Additional application version constraint. A mismatch clears and re-creates the cache only when no corresponding sessions remain open; otherwise creation returns `DXGI_ERROR_ALREADY_EXISTS`, as specified for `Identifier`. |

<!-- d3d12-review-alert:end:shader-cache:semantics-D3D12_SHADER_CACHE_SESSION_DESC:0:modified:migration-f2baa65949e0c57e-0 -->

<ins><!-- d3d12-review-inline:begin:shader-cache:semantics-D3D12_SHADER_CACHE_SESSION_DESC:1 -->No fixed default limits are specified. Inputs open to dynamic reinterpretation,
including zero-valued size controls, are resolved by the applicable cache policy.
A zero field does not promise a particular fixed byte quota or unlimited storage.
[GetDesc](#id3d12shadercachesession-getdesc) reports the resolved descriptor;
the ignored entry count field is not a dynamically enforced default.<!-- d3d12-review-inline:end:shader-cache:semantics-D3D12_SHADER_CACHE_SESSION_DESC:1 --></ins>

<a id="d3d12-shader-cache-kind-flags"></a>

### D3D12_SHADER_CACHE_KIND_FLAGS

```cpp
typedef enum D3D12_SHADER_CACHE_KIND_FLAGS
{
    D3D12_SHADER_CACHE_KIND_FLAG_IMPLICIT_D3D_CACHE_FOR_DRIVER = 0x1,
    D3D12_SHADER_CACHE_KIND_FLAG_IMPLICIT_D3D_CONVERSIONS = 0x2,
    D3D12_SHADER_CACHE_KIND_FLAG_IMPLICIT_DRIVER_MANAGED = 0x4,
    D3D12_SHADER_CACHE_KIND_FLAG_APPLICATION_MANAGED = 0x8,
} D3D12_SHADER_CACHE_KIND_FLAGS;
```

<!-- d3d12-review-alert:begin:shader-cache:semantics-D3D12_SHADER_CACHE_KIND_FLAGS:0:modified:migration-7940808c962de036-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Value | Meaning |
> | --- | --- |
> | `D3D12_SHADER_CACHE_KIND_FLAG_IMPLICIT_D3D_CACHE_FOR_DRIVER` | Refers to the cache which is managed by D3D12 to store driver compilations of application shaders. |
> | `D3D12_SHADER_CACHE_KIND_FLAG_IMPLICIT_D3D_CONVERSIONS` | Refers to the cache which is used to store D3D12's conversions of one shader type to another (e.g. DXBC shaders to DXIL shaders). |
> | `D3D12_SHADER_CACHE_KIND_FLAG_IMPLICIT_DRIVER_MANAGED` | Refers to the cache which is managed by the driver. Operations for this cache are hints. |
> | `D3D12_SHADER_CACHE_KIND_FLAG_APPLICATION_MANAGED` | Refers to all shader cache sessions created by the `CreateShaderCacheSession` API. Requests to `CLEAR` apply to active application cache sessions belonging to the current device, as well as ordinary on-disk application caches created without `D3D12_SHADER_CACHE_FLAG_USE_WORKING_DIR`. [Control scope and failure ordering](#cache-control-scope) distinguish shared backing data from per-device enable/disable state. |

<!-- d3d12-review-alert:end:shader-cache:semantics-D3D12_SHADER_CACHE_KIND_FLAGS:0:modified:migration-7940808c962de036-0 -->

Any one of these caches may or may not exist.

<a id="d3d12-shader-cache-control-flags"></a>

### D3D12_SHADER_CACHE_CONTROL_FLAGS

```cpp
typedef enum D3D12_SHADER_CACHE_CONTROL_FLAGS
{
    D3D12_SHADER_CACHE_CONTROL_FLAG_DISABLE = 0x1,
    D3D12_SHADER_CACHE_CONTROL_FLAG_ENABLE = 0x2,
    D3D12_SHADER_CACHE_CONTROL_FLAG_CLEAR = 0x4,
} D3D12_SHADER_CACHE_CONTROL_FLAGS;
```

<!-- d3d12-review-alert:begin:shader-cache:semantics-D3D12_SHADER_CACHE_CONTROL_FLAGS:0:modified:migration-72dfe6400df809bb-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Value | Meaning |
> | --- | --- |
> | `D3D12_SHADER_CACHE_CONTROL_FLAG_DISABLE` | The cache should not be used to look up data, and should not have new data stored in it. Attempts to use/create a cache while disabled will return `DXGI_ERROR_NOT_CURRENTLY_AVAILABLE`. |
> | `D3D12_SHADER_CACHE_CONTROL_FLAG_ENABLE` | Resumes use of the cache. |
> | `D3D12_SHADER_CACHE_CONTROL_FLAG_CLEAR` | Any existing contents of the cache should be deleted. |

<!-- d3d12-review-alert:end:shader-cache:semantics-D3D12_SHADER_CACHE_CONTROL_FLAGS:0:modified:migration-72dfe6400df809bb-0 -->

<ins><!-- d3d12-review-inline:begin:shader-cache:semantics-D3D12_SHADER_CACHE_CONTROL_FLAGS:1 -->The app cannot pass both `DISABLE` and `ENABLE` at the same time, and must pass at least one flag.<!-- d3d12-review-inline:end:shader-cache:semantics-D3D12_SHADER_CACHE_CONTROL_FLAGS:1 --></ins>

<a id="session-identity"></a>

### Session identity, limits and concurrency

<ins><!-- d3d12-review-inline:begin:shader-cache:session-identity:0:authored:migration-9c438063af99f586-0 -->The executable owns the application cache namespace; equal `Identifier` values
do not make caches a cross-application interchange format. Sessions in one process
with the same effective cache identity share storage. `DRIVER_VERSIONED` adds
adapter/driver identity, while `Version` remains an additional application constraint.
The active-session version mismatch rule prevents silently clearing a cache still
opened by another session.<!-- d3d12-review-inline:end:shader-cache:session-identity:0:authored:migration-9c438063af99f586-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:session-identity:1:authored:migration-a4ba106d5584bc20-0 -->An additional session is not a descriptor update operation. Reopening a live cache
does not resize it or turn an existing memory cache into a disk cache. Applications
do not obtain independent storage merely by changing capacity fields while
reusing its identity. The documented `DXGI_ERROR_ALREADY_EXISTS` version mismatch
rule is not a blanket error rule for every descriptor difference.
A different `Identifier` selects independent storage.<!-- d3d12-review-inline:end:shader-cache:session-identity:1:authored:migration-a4ba106d5584bc20-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:session-identity:2:authored:migration-96642cf79f6d7c9d-0 -->Session methods follow the [CPU threading contract](execution.md#threading).
Individual operations on shared cache storage can synchronize internally, but
a size query followed by a data retrieval is not one atomic operation.<!-- d3d12-review-inline:end:shader-cache:session-identity:2:authored:migration-96642cf79f6d7c9d-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:session-identity:3:authored:migration-e36f64d7860d742b-0 -->Memory mode eviction concerns the in-memory cache's applicable byte size policy.
Disk mode capacity is governed by the backing cache byte size policy. A store
that cannot fit can return `DXGI_ERROR_CACHE_FULL`. The disk cache does not
promise a separate application-controlled temporary key/value cache or LRU
coverage of all values through `MaximumInMemoryCacheSizeBytes` or the ignored
entry count field. Deletion or clearing can invalidate an entry between a size
query and the subsequent data lookup.<!-- d3d12-review-inline:end:shader-cache:session-identity:3:authored:migration-e36f64d7860d742b-0 --></ins>

<a id="id3d12device9-createshadercachesession"></a>

### ID3D12Device9::CreateShaderCacheSession

#### Declaration

```cpp
HRESULT CreateShaderCacheSession(const D3D12_SHADER_CACHE_SESSION_DESC* pDesc, REFIID riid, void** ppvSession);
```

#### Behavior

Creates an object that grants access to a shader cache, potentially opening an existing cache or creating a new one.

#### Parameters

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device9-CreateShaderCacheSession-parameters:1 -->`pDesc` (input)<!-- d3d12-review-inline:end:shader-cache:ID3D12Device9-CreateShaderCacheSession-parameters:1 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device9-CreateShaderCacheSession-parameters:2 -->A `D3D12_SHADER_CACHE_SESSION_DESC` structure describing the shader cache session to create.<!-- d3d12-review-inline:end:shader-cache:ID3D12Device9-CreateShaderCacheSession-parameters:2 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device9-CreateShaderCacheSession-parameters:3 -->`riid` (input)<!-- d3d12-review-inline:end:shader-cache:ID3D12Device9-CreateShaderCacheSession-parameters:3 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device9-CreateShaderCacheSession-parameters:4 -->The globally unique identifier (`GUID`) for the shader cache session interface.<!-- d3d12-review-inline:end:shader-cache:ID3D12Device9-CreateShaderCacheSession-parameters:4 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device9-CreateShaderCacheSession-parameters:5 -->`ppvSession` (output, optional)<!-- d3d12-review-inline:end:shader-cache:ID3D12Device9-CreateShaderCacheSession-parameters:5 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device9-CreateShaderCacheSession-parameters:6 -->A pointer to a memory block that receives a pointer to the [`ID3D12ShaderCacheSession`](#cache-sessions) interface for the shader cache session.<!-- d3d12-review-inline:end:shader-cache:ID3D12Device9-CreateShaderCacheSession-parameters:6 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device9-CreateShaderCacheSession-returns:1 -->If the function succeeds, it returns `S_OK`. Otherwise, it returns an [`HRESULT`](devices-and-capabilities.md#api-result-codes) [error code](devices-and-capabilities.md#api-result-codes).<!-- d3d12-review-inline:end:shader-cache:ID3D12Device9-CreateShaderCacheSession-returns:1 --></ins>

<!-- d3d12-review-alert:begin:shader-cache:ID3D12Device9-CreateShaderCacheSession-returns:2:modified:migration-f0f8f35927869912-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> |Return value|Description|
> | --- | --- |
> | `DXGI_ERROR_ALREADY_EXISTS` | An existing cache with this identifier has an incompatible version while sessions remain open. See [`D3D12_SHADER_CACHE_SESSION_DESC::Identifier`](#d3d12-shader-cache-session-desc). |

<!-- d3d12-review-alert:end:shader-cache:ID3D12Device9-CreateShaderCacheSession-returns:2:modified:migration-f0f8f35927869912-0 -->

#### Runtime validation and lifetime

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-CreateShaderCacheSession:0:authored:migration-6697bc2841f63807-0 -->`pDesc` is required. `Mode` is `MEMORY` or `DISK`; flags are the defined
`DRIVER_VERSIONED` and `USE_WORKING_DIR` bits or `NONE`. A null/reserved
identifier or invalid mode/flags returns `E_INVALIDARG`. Disabled
application-managed caching returns `DXGI_ERROR_NOT_CURRENTLY_AVAILABLE`.
The descriptor is consumed by the call. The returned COM interface owns a session.<!-- d3d12-review-inline:end:shader-cache:contract-CreateShaderCacheSession:0:authored:migration-6697bc2841f63807-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-CreateShaderCacheSession:1:authored:migration-156be7a3281b009b-0 -->A null `ppvSession` performs descriptor validation and returns `S_FALSE` on success,
without opening a session. It is not a disk access, version-compatibility or allocation
test: an actual open may still fail. A supplied output receives the requested
`riid` interface on successful creation. This method does not specify blanket
zeroing of that output on every validation failure.<!-- d3d12-review-inline:end:shader-cache:contract-CreateShaderCacheSession:1:authored:migration-156be7a3281b009b-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-CreateShaderCacheSession:2:authored:migration-fce3beaf75793a4c-0 -->The null output probe stops before querying the returned object for `riid`.
Its success does not establish that the requested interface is supported.<!-- d3d12-review-inline:end:shader-cache:contract-CreateShaderCacheSession:2:authored:migration-fce3beaf75793a4c-0 --></ins>

<a id="id3d12shadercachesession-findvalue"></a>

### ID3D12ShaderCacheSession::FindValue

#### Declaration

```cpp
HRESULT FindValue(const void* pKey, UINT KeySize, void* pValue, UINT* pValueSize);
```

#### Behavior

Looks up an entry in the cache whose key exactly matches the provided key.

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12ShaderCacheSession-FindValue-description:2 -->A size query call can retrieve the required value size before a second call retrieves the data. These are separate lookups, not an atomic operation or a guarantee that the value is retained in a temporary memory entry cache.<!-- d3d12-review-inline:end:shader-cache:ID3D12ShaderCacheSession-FindValue-description:2 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12ShaderCacheSession-FindValue-parameters:1 -->`pKey` (input)<!-- d3d12-review-inline:end:shader-cache:ID3D12ShaderCacheSession-FindValue-parameters:1 --></ins>

The key of the entry to look up.

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12ShaderCacheSession-FindValue-parameters:3 -->`KeySize` (input)<!-- d3d12-review-inline:end:shader-cache:ID3D12ShaderCacheSession-FindValue-parameters:3 --></ins>

The size of the key, in bytes.

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12ShaderCacheSession-FindValue-parameters:5 -->`pValue` (output, optional)<!-- d3d12-review-inline:end:shader-cache:ID3D12ShaderCacheSession-FindValue-parameters:5 --></ins>

A pointer to a memory block that receives the cached entry.

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12ShaderCacheSession-FindValue-parameters:7 -->`pValueSize` (input, output)<!-- d3d12-review-inline:end:shader-cache:ID3D12ShaderCacheSession-FindValue-parameters:7 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12ShaderCacheSession-FindValue-parameters:8 -->A pointer to a `UINT` that receives the size of the cached entry, in bytes.<!-- d3d12-review-inline:end:shader-cache:ID3D12ShaderCacheSession-FindValue-parameters:8 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12ShaderCacheSession-FindValue-returns:1 -->If the function succeeds, it returns `S_OK`. Otherwise, it returns an [`HRESULT`](devices-and-capabilities.md#api-result-codes) [error code](devices-and-capabilities.md#api-result-codes).<!-- d3d12-review-inline:end:shader-cache:ID3D12ShaderCacheSession-FindValue-returns:1 --></ins>

<!-- d3d12-review-alert:begin:shader-cache:ID3D12ShaderCacheSession-FindValue-returns:2:modified:migration-2a522fe0a5939025-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> |Return value|Description|
> | --- | --- |
> | `DXGI_ERROR_CACHE_HASH_COLLISION` | There's an entry with the same hash as the provided key, but the key doesn't exactly match. |
> | `DXGI_ERROR_NOT_FOUND` | The entry isn't present. |

<!-- d3d12-review-alert:end:shader-cache:ID3D12ShaderCacheSession-FindValue-returns:2:modified:migration-2a522fe0a5939025-0 -->

#### Buffer and lookup contract

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-FindValue:0:authored:migration-d8476c3ca9f20db5-0 -->`pKey` and `pValueSize` must be non-null, and `KeySize` must be nonzero;
invalid arguments return `E_INVALIDARG`. `KeySize` counts bytes, not characters.
The caller owns the key and output buffers.<!-- d3d12-review-inline:end:shader-cache:contract-FindValue:0:authored:migration-d8476c3ca9f20db5-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-FindValue:1:authored:migration-a055b451bd8831ee-0 -->On a successful lookup, null `pValue` queries the required size and returns
`S_OK`; initialize `*pValueSize` before the call. With non-null `pValue`,
the input `*pValueSize` is the writable capacity in bytes. The method writes
the required size to `*pValueSize`. If capacity is too small it returns
`DXGI_ERROR_MORE_DATA` without copying the value. With adequate capacity it
copies the complete value and returns `S_OK`.<!-- d3d12-review-inline:end:shader-cache:contract-FindValue:1:authored:migration-a055b451bd8831ee-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-FindValue:2:authored:migration-65064df651f520c0-0 -->For lookup failure before a value is obtained, the size and output buffer are
not success outputs and must not be interpreted as returned cache data.
The method does not promise to zero them. Disabled caching returns
`DXGI_ERROR_NOT_CURRENTLY_AVAILABLE`; allocation or corrupt-cache failures
can also occur. A successful size query does not pin the entry or make a
subsequent lookup atomic with it.<!-- d3d12-review-inline:end:shader-cache:contract-FindValue:2:authored:migration-65064df651f520c0-0 --></ins>

<a id="id3d12shadercachesession-storevalue"></a>

### ID3D12ShaderCacheSession::StoreValue

#### Declaration

```cpp
HRESULT StoreValue(const void* pKey, UINT KeySize, const void* pValue, UINT ValueSize);
```

#### Behavior

Adds an entry to the cache.

#### Parameters

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12ShaderCacheSession-StoreValue-parameters:1 -->`pKey` (input)<!-- d3d12-review-inline:end:shader-cache:ID3D12ShaderCacheSession-StoreValue-parameters:1 --></ins>

The key of the entry to add.

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12ShaderCacheSession-StoreValue-parameters:3 -->`KeySize` (input)<!-- d3d12-review-inline:end:shader-cache:ID3D12ShaderCacheSession-StoreValue-parameters:3 --></ins>

The size of the key, in bytes.

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12ShaderCacheSession-StoreValue-parameters:5 -->`pValue` (input)<!-- d3d12-review-inline:end:shader-cache:ID3D12ShaderCacheSession-StoreValue-parameters:5 --></ins>

A pointer to a memory block containing the entry to add.

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12ShaderCacheSession-StoreValue-parameters:7 -->`ValueSize` (input)<!-- d3d12-review-inline:end:shader-cache:ID3D12ShaderCacheSession-StoreValue-parameters:7 --></ins>

The size of the entry to add, in bytes.

#### Return values

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12ShaderCacheSession-StoreValue-returns:1 -->If the function succeeds, it returns `S_OK`. Otherwise, it returns an [`HRESULT`](devices-and-capabilities.md#api-result-codes) [error code](devices-and-capabilities.md#api-result-codes).<!-- d3d12-review-inline:end:shader-cache:ID3D12ShaderCacheSession-StoreValue-returns:1 --></ins>

<!-- d3d12-review-alert:begin:shader-cache:ID3D12ShaderCacheSession-StoreValue-returns:2:modified:migration-81f7c8ba22e2e901-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> |Return value|Description|
> | --- | --- |
> | `DXGI_ERROR_ALREADY_EXISTS` | There's an entry with the same key. |
> | `DXGI_ERROR_CACHE_HASH_COLLISION` | There's an entry with the same hash as the provided key, but the key doesn't match. |
> | `DXGI_ERROR_CACHE_FULL` | Adding this entry would cause the cache to become larger than its maximum size. |

<!-- d3d12-review-alert:end:shader-cache:ID3D12ShaderCacheSession-StoreValue-returns:2:modified:migration-81f7c8ba22e2e901-0 -->

#### Buffer ownership and bounds

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-StoreValue:0:authored:migration-86199426e5daa787-0 -->`pKey` and `pValue` must be non-null; `KeySize` and `ValueSize` must be
nonzero. These invalid arguments return `E_INVALIDARG`. Both sizes are
`UINT` byte counts; application arithmetic must not overflow or truncate them.
Cache storage and metadata limits may reject an entry before either count reaches
`UINT_MAX`. These counts are not a minimum opaque shader/blob format size.<!-- d3d12-review-inline:end:shader-cache:contract-StoreValue:0:authored:migration-86199426e5daa787-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-StoreValue:1:authored:migration-628f4fe4e127c9d6-0 -->The cache consumes the key and value bytes during the call. The application may
reuse its input buffers after the call returns. This does not transfer ownership
of application memory to the cache. Stores do not replace an existing key's value.
Disabled caching returns `DXGI_ERROR_NOT_CURRENTLY_AVAILABLE`; allocation failure
can return `E_OUTOFMEMORY`.<!-- d3d12-review-inline:end:shader-cache:contract-StoreValue:1:authored:migration-628f4fe4e127c9d6-0 --></ins>

<a id="id3d12shadercachesession-setdeleteondestroy"></a>

### ID3D12ShaderCacheSession::SetDeleteOnDestroy

#### Declaration

```cpp
void SetDeleteOnDestroy();
```

#### Behavior

When all cache session objects corresponding to a given cache are destroyed, the cache is cleared.

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12ShaderCacheSession-SetDeleteOnDestroy-description:2 -->The [cache mode contract](#d3d12-shader-cache-mode) lists the ways in which a disk cache can be cleared.<!-- d3d12-review-inline:end:shader-cache:ID3D12ShaderCacheSession-SetDeleteOnDestroy-description:2 --></ins>

#### Shared lifetime

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-SetDeleteOnDestroy:0:authored:migration-656b360c730f5f15-0 -->The request applies to the underlying cache, not merely this interface pointer.
Releasing the requesting session does not clear a cache while another session
for that cache is alive. The last corresponding session's destruction performs
the deferred clear.<!-- d3d12-review-inline:end:shader-cache:contract-SetDeleteOnDestroy:0:authored:migration-656b360c730f5f15-0 --></ins>

<a id="id3d12shadercachesession-getdesc"></a>

### ID3D12ShaderCacheSession::GetDesc

#### Declaration

```cpp
D3D12_SHADER_CACHE_SESSION_DESC GetDesc();
```

#### Behavior

Retrieves the <ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12ShaderCacheSession-GetDesc-description:1:modified:source-59ab152e9329bbfd-0-0 -->resolved description of<!-- d3d12-review-inline:end:shader-cache:ID3D12ShaderCacheSession-GetDesc-description:1:modified:source-59ab152e9329bbfd-0-0 --></ins> the cache session.

#### Return values

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12ShaderCacheSession-GetDesc-returns:1 -->A [`D3D12_SHADER_CACHE_SESSION_DESC`](#d3d12-shader-cache-session-desc) structure representing the resolved description of the cache session.<!-- d3d12-review-inline:end:shader-cache:ID3D12ShaderCacheSession-GetDesc-returns:1 --></ins>

#### Descriptor reflection

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-GetDesc:1:authored:migration-826f5461c195abae-0 -->The returned description resolves inputs that are open to dynamic
reinterpretation, including cache size policy. It is not a blanket literal
echo of the creation description. The byte size fields report resolved values.
When a resolved byte size exceeds the range of the legacy `UINT` field,
`GetDesc` returns `UINT_MAX` for that field. This representational saturation
does not change the underlying effective policy to that numeric bound.
`MaximumInMemoryCacheEntries` echoes the supplied value for ABI compatibility,
but that legacy field is ignored and is not an enforced entry limit.
Mode-specific controls retain their meaning: the reflected memory byte field
does not create a separate `DISK`-mode temporary entry cache quota.<!-- d3d12-review-inline:end:shader-cache:contract-GetDesc:1:authored:migration-826f5461c195abae-0 --></ins>

<a id="id3d12device9-shadercachecontrol"></a>

### ID3D12Device9::ShaderCacheControl

#### Declaration

```cpp
HRESULT ShaderCacheControl(D3D12_SHADER_CACHE_KIND_FLAGS Kinds, D3D12_SHADER_CACHE_CONTROL_FLAGS Control);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device9-ShaderCacheControl-description:1 -->Modifies the behavior of caches used internally by Direct3D or by the driver.
`CLEAR` alone is permitted without developer mode when
`D3D12_SHADER_CACHE_SUPPORT_SHADER_CONTROL_CLEAR` is reported.
`ENABLE` and `DISABLE` require developer mode, including when combined with
`CLEAR`. The [control scope and failure ordering](#cache-control-scope) apply.<!-- d3d12-review-inline:end:shader-cache:ID3D12Device9-ShaderCacheControl-description:1 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device9-ShaderCacheControl-parameters:1 -->`Kinds` (input)<!-- d3d12-review-inline:end:shader-cache:ID3D12Device9-ShaderCacheControl-parameters:1 --></ins>

The caches to modify. Any one of these caches may or may not exist.

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device9-ShaderCacheControl-parameters:3 -->`Control` (input)<!-- d3d12-review-inline:end:shader-cache:ID3D12Device9-ShaderCacheControl-parameters:3 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device9-ShaderCacheControl-parameters:4 -->The way in which to modify the caches. You can't pass both `DISABLE` and `ENABLE` at the same time; and you must pass at least one flag.<!-- d3d12-review-inline:end:shader-cache:ID3D12Device9-ShaderCacheControl-parameters:4 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-ShaderCacheControl:0:authored:migration-3f71e9e08706f3eb-0 -->`Kinds` must contain at least one defined kind bit. `Control` must contain at
least one defined control bit and must not combine `ENABLE` with `DISABLE`.
`CLEAR` may accompany either `ENABLE` or `DISABLE`, or be used by itself.
Unrecognized bits, empty masks, enabling an already-enabled selected kind or
disabling an already-disabled selected kind return `E_INVALIDARG`.
Successful processing returns `S_OK`; operating-system failures can propagate.
Enabling/disabling caches without developer mode returns
`DXGI_ERROR_SDK_COMPONENT_MISSING`.<!-- d3d12-review-inline:end:shader-cache:contract-ShaderCacheControl:0:authored:migration-3f71e9e08706f3eb-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-ShaderCacheControl:1:authored:migration-42fcd63ecba5acce-0 -->Outside developer mode, a clear-only request requires
`D3D12_SHADER_CACHE_SUPPORT_SHADER_CONTROL_CLEAR`. The capability does not
remove the developer mode requirement from `CLEAR | ENABLE` or
`CLEAR | DISABLE`. It does not guarantee that a selected cache exists or that
a driver-managed cache obeys a control hint.<!-- d3d12-review-inline:end:shader-cache:contract-ShaderCacheControl:1:authored:migration-42fcd63ecba5acce-0 --></ins>

<a id="cache-control-scope"></a>

#### Scope and failure ordering

<ins><!-- d3d12-review-inline:begin:shader-cache:control-scope-and-failures:0:authored:migration-f039600a538dc362-0 -->Enable/disable state belongs to the device on which `ShaderCacheControl` is
called. It is not a process-global disable switch. The call does not change
another device's enable/disable mask. Active application session clearing covers
sessions belonging to the current device. On-disk cleanup can additionally reach
ordinary caches in the application's cache namespace. A clear can therefore
affect backing data shared with other sessions or devices without changing
those devices' enable/disable state. Driver-managed control is a hint supplied
through the current device, not an all-device or all-adapter control guarantee.<!-- d3d12-review-inline:end:shader-cache:control-scope-and-failures:0:authored:migration-f039600a538dc362-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:control-scope-and-failures:1:authored:migration-be93c1d45203d1bf-0 -->A combined control request is not transactional. After successful validation,
`ENABLE` or `DISABLE` changes the current device's selected state before any
requested clear. A later clear failure can return an error after that state
change or after some caches have been cleared. There is no rollback or
all-kinds-atomic clearing guarantee; later selected caches or the driver hint
need not have been processed when an earlier clear fails. An error from a
combined operation does not imply that enable/disable state is unchanged.<!-- d3d12-review-inline:end:shader-cache:control-scope-and-failures:1:authored:migration-be93c1d45203d1bf-0 --></ins>

<a id="pipeline-libraries"></a>

## Supported legacy pipeline libraries

<ins><!-- d3d12-review-inline:begin:shader-cache:library-model:0:authored:migration-83af036ca1550e7b-0 -->A pipeline library groups compatible PSOs and serializes their cache data.
It does not replace the complete PSO description needed by the load methods.
Sharing identical subcomponents can reduce metadata and duplicated data compared
with separately serialized single-PSO caches. This is not a guarantee of a
particular performance improvement.<!-- d3d12-review-inline:end:shader-cache:library-model:0:authored:migration-83af036ca1550e7b-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:library-model:1:authored:migration-bf1de0821c000614-0 -->The [library thread safety contract](#library-thread-safety) governs access.<!-- d3d12-review-inline:end:shader-cache:library-model:1:authored:migration-bf1de0821c000614-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:library-model:2:authored:migration-cb27ae3ff0432a39-0 -->**History:** Pipeline library caching was recommended to reduce driver PSO
creation overhead. Driver/runtime updates,
adapter or machine changes can invalidate stored data, and applications still
incur matching, validation, storage and loading costs.<!-- d3d12-review-inline:end:shader-cache:library-model:2:authored:migration-cb27ae3ff0432a39-0 --></ins>

<a id="library-thread-safety"></a>

### Library thread safety

<ins><!-- d3d12-review-inline:begin:shader-cache:primary-library-thread-safety:0:modified:migration-b63a49240d137ba4-0 -->The pipeline library is thread-safe to use, and will internally synchronize as necessary, with one exception: multiple threads loading the same PSO (via [**LoadComputePipeline**](#id3d12pipelinelibrary-loadcomputepipeline),
[**LoadGraphicsPipeline**](#id3d12pipelinelibrary-loadgraphicspipeline), or [**LoadPipeline**](#id3d12pipelinelibrary1-loadpipeline)) should synchronize themselves, as this act may modify the state of that pipeline within the library in a non-thread-safe manner.<!-- d3d12-review-inline:end:shader-cache:primary-library-thread-safety:0:modified:migration-b63a49240d137ba4-0 --></ins>

<a id="id3d12device1-createpipelinelibrary"></a>

### ID3D12Device1::CreatePipelineLibrary

#### Declaration

```cpp
HRESULT CreatePipelineLibrary(const void *pLibraryBlob, SIZE_T BlobLength, REFIID riid, void** ppPipelineLibrary);
```

#### Behavior

Creates a cached pipeline library. For pipeline state objects (PSOs) that are expected to share data together, grouping them into a library before serializing them means that there's less overhead due to metadata, as well as the opportunity to avoid redundant or duplicated data being written to disk.

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device1-CreatePipelineLibrary-description:2 -->You can query for `ID3D12PipelineLibrary` support with **[`ID3D12Device::CheckFeatureSupport`](devices-and-capabilities.md#id3d12device-checkfeaturesupport)**, with **[`D3D12_FEATURE_SHADER_CACHE`](devices-and-capabilities.md#d3d12_feature_data_shader_cache)** and **[`D3D12_FEATURE_DATA_SHADER_CACHE`](devices-and-capabilities.md#d3d12_feature_data_shader_cache)**. If the `SupportFlags` member of **[`D3D12_FEATURE_DATA_SHADER_CACHE`](devices-and-capabilities.md#d3d12_feature_data_shader_cache)** contains the flag **[`D3D12_SHADER_CACHE_SUPPORT_LIBRARY`](#d3d12-shader-cache-support-flags)**, the `ID3D12PipelineLibrary` interface is supported. If not, then `DXGI_ERROR_UNSUPPORTED` will always be returned when this function is called.<!-- d3d12-review-inline:end:shader-cache:ID3D12Device1-CreatePipelineLibrary-description:2 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device1-CreatePipelineLibrary-parameters:1 -->`pLibraryBlob` (input)<!-- d3d12-review-inline:end:shader-cache:ID3D12Device1-CreatePipelineLibrary-parameters:1 --></ins>

If the input library blob is empty, then the initial content of the library is empty. If the input library blob is not empty, then it is validated for integrity, parsed, and the pointer is stored. The pointer provided as input to this method must remain valid for the lifetime of the object returned. For efficiency reasons, the data is not copied.

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-CreatePipelineLibrary:0:authored:migration-270fa54fdc9d8411-0 -->With `BlobLength == 0`, no input bytes are consumed. For nonzero length,
`pLibraryBlob` must point to that many readable, unchanging bytes.<!-- d3d12-review-inline:end:shader-cache:contract-CreatePipelineLibrary:0:authored:migration-270fa54fdc9d8411-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-CreatePipelineLibrary:2:authored:migration-5daca4e7085387be-0 -->The serialized format is opaque, runtime/driver/hardware-specific and not a
portable shader or standalone PSO description. The library interface is a COM
reference. Its input storage lifetime is an additional application obligation.<!-- d3d12-review-inline:end:shader-cache:contract-CreatePipelineLibrary:2:authored:migration-5daca4e7085387be-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device1-CreatePipelineLibrary-parameters:3 -->`BlobLength` (input)<!-- d3d12-review-inline:end:shader-cache:ID3D12Device1-CreatePipelineLibrary-parameters:3 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device1-CreatePipelineLibrary-parameters:4 -->Specifies the length of `pLibraryBlob` in bytes.<!-- d3d12-review-inline:end:shader-cache:ID3D12Device1-CreatePipelineLibrary-parameters:4 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device1-CreatePipelineLibrary-parameters:5 -->`riid` (input)<!-- d3d12-review-inline:end:shader-cache:ID3D12Device1-CreatePipelineLibrary-parameters:5 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device1-CreatePipelineLibrary-parameters:6 -->Specifies a unique `REFIID` for the [`ID3D12PipelineLibrary`](#pipeline-libraries) object. Typically set this and the following parameter with the macro `IID_PPV_ARGS(&Library)`, where **Library** is the name of the object.<!-- d3d12-review-inline:end:shader-cache:ID3D12Device1-CreatePipelineLibrary-parameters:6 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device1-CreatePipelineLibrary-parameters:7 -->`ppPipelineLibrary` (output, optional)<!-- d3d12-review-inline:end:shader-cache:ID3D12Device1-CreatePipelineLibrary-parameters:7 --></ins>

Returns a pointer to the created library.

#### Return values

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device1-CreatePipelineLibrary-returns:1 -->If the function succeeds, it returns `S_OK`. Otherwise, it returns an [`HRESULT`](devices-and-capabilities.md#api-result-codes) [error code](devices-and-capabilities.md#api-result-codes), including `E_INVALIDARG` if the blob is corrupted or unrecognized, `D3D12_ERROR_DRIVER_VERSION_MISMATCH` if the provided data came from an old driver or runtime, and `D3D12_ERROR_ADAPTER_NOT_FOUND` if the data came from different hardware.<!-- d3d12-review-inline:end:shader-cache:ID3D12Device1-CreatePipelineLibrary-returns:1 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device1-CreatePipelineLibrary-returns:2 -->If you pass `nullptr` for `ppPipelineLibrary` then the runtime still performs the validation of the blob but avoids creating the actual library and returns `S_FALSE` if the library would have been created.<!-- d3d12-review-inline:end:shader-cache:ID3D12Device1-CreatePipelineLibrary-returns:2 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-CreatePipelineLibrary:1:authored:migration-b1b2918e5e1e732c-0 -->Malformed or truncated blobs also return `E_INVALIDARG`. No public fixed
minimum valid blob length is exposed. Machine incompatibility can return
`D3D12_ERROR_DRIVER_VERSION_MISMATCH`.<!-- d3d12-review-inline:end:shader-cache:contract-CreatePipelineLibrary:1:authored:migration-b1b2918e5e1e732c-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-CreatePipelineLibrary:3:authored:migration-7fa57f4d29e999f6-0 -->The null output probe stops before querying the returned object for `riid`.
Its success does not establish that the requested interface is supported.<!-- d3d12-review-inline:end:shader-cache:contract-CreatePipelineLibrary:3:authored:migration-7fa57f4d29e999f6-0 --></ins>

#### Remarks

A pipeline library enables the following operations.

- <ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device1-CreatePipelineLibrary-remarks:2 -->Adding pipeline state objects (PSOs) to an existing library object (refer to [StorePipeline](#id3d12pipelinelibrary-storepipeline)).<!-- d3d12-review-inline:end:shader-cache:ID3D12Device1-CreatePipelineLibrary-remarks:2 --></ins>
- <ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device1-CreatePipelineLibrary-remarks:2 -->Serializing a PSO library into a contiguous block of memory for disk storage (refer to [Serialize](#id3d12pipelinelibrary-serialize)).<!-- d3d12-review-inline:end:shader-cache:ID3D12Device1-CreatePipelineLibrary-remarks:2 --></ins>
- <ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device1-CreatePipelineLibrary-remarks:2 -->De-serializing a PSO library from persistent storage (this is handled by **CreatePipelineLibrary**).<!-- d3d12-review-inline:end:shader-cache:ID3D12Device1-CreatePipelineLibrary-remarks:2 --></ins>
- <ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device1-CreatePipelineLibrary-remarks:2 -->Retrieving individual PSOs from the library (refer to [LoadComputePipeline](#id3d12pipelinelibrary-loadcomputepipeline) and [LoadGraphicsPipeline](#id3d12pipelinelibrary-loadgraphicspipeline)).<!-- d3d12-review-inline:end:shader-cache:ID3D12Device1-CreatePipelineLibrary-remarks:2 --></ins>

At no point in the lifecycle of a pipeline library is there duplication between PSOs with identical sub-components.

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device1-CreatePipelineLibrary-remarks:4 -->A recommended solution for managing the lifetime of the provided pointer while only having to ref-count the returned interface is to leverage [`ID3D12Object::SetPrivateDataInterface`](devices-and-capabilities.md#id3d12object-setprivatedatainterface), and use an object which implements `IUnknown`, and frees the memory when the ref-count reaches 0.<!-- d3d12-review-inline:end:shader-cache:ID3D12Device1-CreatePipelineLibrary-remarks:4 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12Device1-CreatePipelineLibrary-remarks:5 -->The [library thread safety contract](#library-thread-safety) applies.<!-- d3d12-review-inline:end:shader-cache:ID3D12Device1-CreatePipelineLibrary-remarks:5 --></ins>

##### Examples

See the [Direct3D 12 pipeline state cache sample](https://github.com/microsoft/DirectX-Graphics-Samples/tree/master/Samples/Desktop/D3D12PipelineStateCache).

<a id="id3d12pipelinelibrary-storepipeline"></a>

### ID3D12PipelineLibrary::StorePipeline

#### Declaration

```cpp
HRESULT StorePipeline(LPCWSTR pName, ID3D12PipelineState *pPipeline);
```

#### Behavior

Adds the input PSO to an internal database with the corresponding name.

#### Parameters

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary-StorePipeline-parameters:1 -->`pName` (input, optional)<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary-StorePipeline-parameters:1 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary-StorePipeline-parameters:2 -->Specifies a unique name for the PSO in the library. Overwriting is not supported.<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary-StorePipeline-parameters:2 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary-StorePipeline-parameters:3 -->`pPipeline` (input)<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary-StorePipeline-parameters:3 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary-StorePipeline-parameters:4 -->Specifies the [`ID3D12PipelineState`](pipeline-state.md#ordinary-pipeline-state) to add.<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary-StorePipeline-parameters:4 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary-StorePipeline-returns:1 -->This method returns an `HRESULT` success or error code, including `E_INVALIDARG` if the name already exists, `E_OUTOFMEMORY` if unable to allocate storage in the library.<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary-StorePipeline-returns:1 --></ins>

#### Names and object lifetime

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-StorePipeline:0:authored:migration-2e3ae540dcf3da06-0 -->`pName` names the PSO entry, not the library object. Names are null-terminated
wide strings, case-sensitive and unique within the library. An empty string is
a name. Null `pName` uses the PSO's previously assigned object name. If no name
exists, the call returns `E_INVALIDARG`. This is distinct from the required
non-null lookup names of the load methods. [`ID3D12Object::SetName`](diagnostics.md#id3d12object-setname)
defines assignment of the object's name.<!-- d3d12-review-inline:end:shader-cache:contract-StorePipeline:0:authored:migration-2e3ae540dcf3da06-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-StorePipeline:1:authored:migration-7f32b2fe7f694a64-0 -->`pPipeline` must be a valid PSO belonging to the library's device. The name is
consumed by the call. The application need not retain the name string afterward.
The library retains the stored PSO information/reference, so releasing the
application's PSO reference does not invalidate the library entry. Renaming the
PSO afterward does not rename an existing library entry.<!-- d3d12-review-inline:end:shader-cache:contract-StorePipeline:1:authored:migration-7f32b2fe7f694a64-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:PL-failed-store-mapping:0:authored:migration-862ec2921c2c865c-0 -->A failed `StorePipeline` must leave the library's application-visible
name/entry mapping unchanged. Failure is not permission to publish the
requested name as a successful stored entry. This requirement concerns
that mapping, not rollback of every private driver allocation or cache
side effect.<!-- d3d12-review-inline:end:shader-cache:PL-failed-store-mapping:0:authored:migration-862ec2921c2c865c-0 --></ins>

<a id="id3d12pipelinelibrary-loadgraphicspipeline"></a>

### ID3D12PipelineLibrary::LoadGraphicsPipeline

#### Declaration

```cpp
HRESULT LoadGraphicsPipeline(LPCWSTR pName, const D3D12_GRAPHICS_PIPELINE_STATE_DESC* pDesc, REFIID riid, void** ppPipelineState);
```

#### Behavior

Retrieves the requested PSO from the library.

#### Parameters

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary-LoadGraphicsPipeline-parameters:1 -->`pName` (input)<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary-LoadGraphicsPipeline-parameters:1 --></ins>

The unique name of the PSO.

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary-LoadGraphicsPipeline-parameters:3 -->`pDesc` (input)<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary-LoadGraphicsPipeline-parameters:3 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary-LoadGraphicsPipeline-parameters:4 -->Specifies a description of the required PSO in a [`D3D12_GRAPHICS_PIPELINE_STATE_DESC`](pipeline-state.md#graphics-description) structure. This input description is matched against the data in the current library database, and stored in order to prevent duplication of PSO contents.<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary-LoadGraphicsPipeline-parameters:4 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary-LoadGraphicsPipeline-parameters:5 -->`riid` (input)<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary-LoadGraphicsPipeline-parameters:5 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary-LoadGraphicsPipeline-parameters:6 -->Specifies a `REFIID` for the [`ID3D12PipelineState`](pipeline-state.md#ordinary-pipeline-state) object. Typically set this, and the following parameter, with the macro `IID_PPV_ARGS(&PSO1)`, where `PSO1` is the name of the object.<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary-LoadGraphicsPipeline-parameters:6 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary-LoadGraphicsPipeline-parameters:7 -->`ppPipelineState` (output)<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary-LoadGraphicsPipeline-parameters:7 --></ins>

Specifies a pointer that will reference the returned PSO.

#### Return values

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary-LoadGraphicsPipeline-returns:1 -->This method returns an `HRESULT` success or error code, which can include `E_INVALIDARG` if the name doesn’t exist, or if the input description doesn’t match the data in the library, and `E_OUTOFMEMORY` if unable to allocate the return PSO.<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary-LoadGraphicsPipeline-returns:1 --></ins>

#### Description, references and concurrency

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-LoadGraphicsPipeline:0:authored:migration-435b108482f8421c-0 -->`pName` and `pDesc` are required. Names are case-sensitive.
A same-name entry of another pipeline kind does not satisfy a graphics load.
The [graphics description](pipeline-state.md#graphics-description) and
[creation validation](pipeline-state.md#creation-validation) remain required.<!-- d3d12-review-inline:end:shader-cache:contract-LoadGraphicsPipeline:0:authored:migration-435b108482f8421c-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-LoadGraphicsPipeline:1:authored:migration-b575809912170db1-0 -->`ppPipelineState` is a required output for the requested `riid` interface.
Successful load returns a COM reference owned by the caller. It may refer to a
PSO already retained by the library. The caller must release its reference.
This method has no specified null output validation-only probe.
The [library thread safety contract](#library-thread-safety) applies.<!-- d3d12-review-inline:end:shader-cache:contract-LoadGraphicsPipeline:1:authored:migration-b575809912170db1-0 --></ins>

<a id="id3d12pipelinelibrary-loadcomputepipeline"></a>

### ID3D12PipelineLibrary::LoadComputePipeline

#### Declaration

```cpp
HRESULT LoadComputePipeline(LPCWSTR pName, const D3D12_COMPUTE_PIPELINE_STATE_DESC* pDesc, REFIID riid, void** ppPipelineState);
```

#### Behavior

Retrieves the requested PSO from the library.

#### Parameters

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary-LoadComputePipeline-parameters:1 -->`pName` (input)<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary-LoadComputePipeline-parameters:1 --></ins>

The unique name of the PSO.

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary-LoadComputePipeline-parameters:3 -->`pDesc` (input)<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary-LoadComputePipeline-parameters:3 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary-LoadComputePipeline-parameters:4 -->Specifies a description of the required PSO in a [`D3D12_COMPUTE_PIPELINE_STATE_DESC`](pipeline-state.md#compute-description) structure. This input description is matched against the data in the current library database, and stored in order to prevent duplication of PSO contents.<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary-LoadComputePipeline-parameters:4 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary-LoadComputePipeline-parameters:5 -->`riid` (input)<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary-LoadComputePipeline-parameters:5 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary-LoadComputePipeline-parameters:6 -->Specifies a `REFIID` for the [`ID3D12PipelineState`](pipeline-state.md#ordinary-pipeline-state) object. Typically set this, and the following parameter, with the macro `IID_PPV_ARGS(&PSO1)`, where `PSO1` is the name of the object.<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary-LoadComputePipeline-parameters:6 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary-LoadComputePipeline-parameters:7 -->`ppPipelineState` (output)<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary-LoadComputePipeline-parameters:7 --></ins>

Specifies a pointer that will reference the returned PSO.

#### Return values

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary-LoadComputePipeline-returns:1 -->This method returns an `HRESULT` success or error code, which can include `E_INVALIDARG` if the name doesn’t exist, or if the input description doesn’t match the data in the library, and `E_OUTOFMEMORY` if unable to allocate the return PSO.<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary-LoadComputePipeline-returns:1 --></ins>

#### Description, references and concurrency

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-LoadComputePipeline:0:authored:migration-877c7dc95a8e1fb2-0 -->`pName` and `pDesc` are required. Names are case-sensitive. A same-name
entry of another pipeline kind does not satisfy a compute load.
The [compute description](pipeline-state.md#compute-description) and
[creation validation](pipeline-state.md#creation-validation) remain required.<!-- d3d12-review-inline:end:shader-cache:contract-LoadComputePipeline:0:authored:migration-877c7dc95a8e1fb2-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-LoadComputePipeline:1:authored:migration-b85b61b6be268a7a-0 -->`ppPipelineState` is a required output for the requested `riid` interface.
Successful load returns a COM reference owned by the caller. It may refer to a
PSO already retained by the library. The caller must release its reference.
This method has no specified null output validation-only probe.
The [library thread safety contract](#library-thread-safety) applies.<!-- d3d12-review-inline:end:shader-cache:contract-LoadComputePipeline:1:authored:migration-b85b61b6be268a7a-0 --></ins>

<a id="id3d12pipelinelibrary1-loadpipeline"></a>

### ID3D12PipelineLibrary1::LoadPipeline

#### Declaration

```cpp
HRESULT LoadPipeline(LPCWSTR pName, const D3D12_PIPELINE_STATE_STREAM_DESC* pDesc, REFIID riid, void** ppPipelineState);
```

#### Behavior

Retrieves the requested PSO from the library.

#### Parameters

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary1-LoadPipeline-parameters:1 -->`pName` (input)<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary1-LoadPipeline-parameters:1 --></ins>

The unique name of the PSO.

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary1-LoadPipeline-parameters:3 -->`pDesc` (input)<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary1-LoadPipeline-parameters:3 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary1-LoadPipeline-parameters:4 -->Describes the required PSO using a [`D3D12_PIPELINE_STATE_STREAM_DESC`](pipeline-state.md#streams) structure. This description is matched against the library database, and stored in order to prevent duplication of PSO contents.<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary1-LoadPipeline-parameters:4 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary1-LoadPipeline-parameters:5 -->`riid` (input)<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary1-LoadPipeline-parameters:5 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary1-LoadPipeline-parameters:6 -->Specifies a `REFIID` for the [`ID3D12PipelineState`](pipeline-state.md#ordinary-pipeline-state) object.<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary1-LoadPipeline-parameters:6 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary1-LoadPipeline-parameters:7 -->Your app should typically set this argument and the following argument, `ppPipelineState`, by using the macro `IID_PPV_ARGS(&PSO1)`, where PSO1 is the name of the object.<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary1-LoadPipeline-parameters:7 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary1-LoadPipeline-parameters:8 -->`ppPipelineState` (output)<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary1-LoadPipeline-parameters:8 --></ins>

Specifies the pointer that will reference the PSO after the function successfully returns.

#### Return values

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary1-LoadPipeline-returns:1 -->This method returns an `HRESULT` success or error code, which can include `E_INVALIDARG` if the name doesn't exist or the stream description doesn't match the data in the library, and `E_OUTOFMEMORY` if the function is unable to allocate the resulting PSO.<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary1-LoadPipeline-returns:1 --></ins>

#### Stream dependencies and references

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-LoadPipeline:0:authored:migration-778e056c3264fb6c-0 -->`pName`, `pDesc` and `ppPipelineState` are required. Matching includes the
pipeline kind. The
[stream layout and subobjects](pipeline-state.md#streams) and
[creation validation](pipeline-state.md#creation-validation) remain required.
A malformed stream or incompatible description can return `E_INVALIDARG`.<!-- d3d12-review-inline:end:shader-cache:contract-LoadPipeline:0:authored:migration-778e056c3264fb6c-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-LoadPipeline:1:authored:migration-86cd254fb50a8aef-0 -->Successful load returns the requested `riid` COM reference to the caller,
which must release it. This method has no specified null output validation-only
probe. The [library thread safety contract](#library-thread-safety) applies.<!-- d3d12-review-inline:end:shader-cache:contract-LoadPipeline:1:authored:migration-86cd254fb50a8aef-0 --></ins>

<a id="id3d12pipelinelibrary-getserializedsize"></a>

### ID3D12PipelineLibrary::GetSerializedSize

#### Declaration

```cpp
SIZE_T GetSerializedSize();
```

#### Behavior

Returns the amount of memory required to serialize the current contents of the database.

#### Return values

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary-GetSerializedSize-returns:1 -->This method returns a `SIZE_T` object, containing the size required in bytes.<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary-GetSerializedSize-returns:1 --></ins>

#### Snapshot scope

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-GetSerializedSize:0:authored:migration-18d4a8f250a00dd8-0 -->The application must
synchronize modifications across a size query/serialization pair if it relies
on that pair describing the same contents. An empty library can still require
nonzero serialization metadata; no fixed minimum byte size is exposed.<!-- d3d12-review-inline:end:shader-cache:contract-GetSerializedSize:0:authored:migration-18d4a8f250a00dd8-0 --></ins>

<a id="id3d12pipelinelibrary-serialize"></a>

### ID3D12PipelineLibrary::Serialize

#### Declaration

```cpp
HRESULT Serialize(void* pData, SIZE_T DataSizeInBytes);
```

#### Behavior

Writes the contents of the library to the provided memory, to be provided back to the runtime at a later time.

#### Parameters

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary-Serialize-parameters:1 -->`pData` (output)<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary-Serialize-parameters:1 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary-Serialize-parameters:2 -->Specifies a pointer to the data. This memory must be readable and writable up to the input size. This data can be saved and provided to [CreatePipelineLibrary](#id3d12device1-createpipelinelibrary) at a later time, including future instances of this or other processes. The data becomes invalidated if the runtime or driver is updated, and is not portable to other hardware or devices.<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary-Serialize-parameters:2 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary-Serialize-parameters:3 -->`DataSizeInBytes` (input)<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary-Serialize-parameters:3 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary-Serialize-parameters:4 -->The size provided must be at least the size returned from [GetSerializedSize](#id3d12pipelinelibrary-getserializedsize).<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary-Serialize-parameters:4 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:shader-cache:ID3D12PipelineLibrary-Serialize-returns:1 -->This method returns an `HRESULT` success or error code, including `E_INVALIDARG` if the buffer provided isn’t big enough.<!-- d3d12-review-inline:end:shader-cache:ID3D12PipelineLibrary-Serialize-returns:1 --></ins>

#### Output storage and races

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-Serialize:0:authored:migration-3eb85226d8a51d37-0 -->`pData` must point to application-owned readable and writable storage of
`DataSizeInBytes` bytes. Null `pData` is not a size query idiom. Use
`GetSerializedSize`. A size equal to the current requirement is sufficient,
and a larger buffer is permitted. An undersized buffer returns `E_INVALIDARG`;
it does not report a replacement size through an output parameter.<!-- d3d12-review-inline:end:shader-cache:contract-Serialize:0:authored:migration-3eb85226d8a51d37-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:contract-Serialize:1:authored:migration-06621a3070261297-0 -->The application owns the serialized bytes after successful return and may save
them. Serialization does not transfer ownership or extend the lifetime of the
destination allocation. A future `CreatePipelineLibrary` that uses those bytes
introduces its own input storage lifetime. Do not treat a failed serialization
as a valid persisted library or assume that all destination bytes were zeroed.<!-- d3d12-review-inline:end:shader-cache:contract-Serialize:1:authored:migration-06621a3070261297-0 --></ins>

<a id="cached-pso-blobs"></a>

## Supported legacy cached PSO blobs

<ins><!-- d3d12-review-inline:begin:shader-cache:blob-model:0:authored:migration-85b2c97d3aa67d87-0 -->A cached PSO blob is an opaque optimization input for later pipeline creation,
not a portable shader binary and not a replacement for a complete PSO description.
[Cached input compatibility and consumption](pipeline-state.md#cached-data)
remain at Pipeline state. In particular, the description and cached data must
match, and the bytes can be specific to hardware, driver and machine.<!-- d3d12-review-inline:end:shader-cache:blob-model:0:authored:migration-85b2c97d3aa67d87-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:blob-model:1:authored:migration-563f778f6a9dd396-0 -->The ordinary `CachedPSO` creation input must remain readable for the duration of
that creation call. It does not impose `CreatePipelineLibrary`'s retained-input
lifetime. Conversely, passing a serialized library to `CreatePipelineLibrary`
must not be treated as a temporary creation-only input.<!-- d3d12-review-inline:end:shader-cache:blob-model:1:authored:migration-563f778f6a9dd396-0 --></ins>

<a id="id3d12pipelinestate-getcachedblob"></a>

### ID3D12PipelineState::GetCachedBlob

#### Declaration

```cpp
HRESULT GetCachedBlob(ID3DBlob** ppBlob);
```

#### Behavior

Gets the cached blob representing the pipeline state.

<ins><!-- d3d12-review-inline:begin:shader-cache:N-id3d12pipelinestate-getcachedblob:0:authored:migration-40b4a80d9f34b9ef-0 -->The [cached data contract](pipeline-state.md#cached-data) defines the output's scope and reuse requirements.<!-- d3d12-review-inline:end:shader-cache:N-id3d12pipelinestate-getcachedblob:0:authored:migration-40b4a80d9f34b9ef-0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:shader-cache:Q-id3d12pipelinestate-getcachedblob:1 -->`ppBlob` (output)<!-- d3d12-review-inline:end:shader-cache:Q-id3d12pipelinestate-getcachedblob:1 --></ins>

After this method returns, points to the cached blob representing the pipeline state.

#### Return values

This method returns one of the [Direct3D 12 Return Codes](devices-and-capabilities.md#api-result-codes).

#### Ownership and legacy behavior

<ins><!-- d3d12-review-inline:begin:shader-cache:blob-ownership:0:authored:migration-ec159af06e306ff0-0 -->`ppBlob` is a required output pointer to an `ID3DBlob` COM interface.
On success, the caller owns the returned reference and must release it.
`ID3DBlob::GetBufferPointer` and `GetBufferSize` expose the blob's bytes and
byte length. The pointer is valid only while the blob's storage remains alive.
Copying or persisting bytes does not serialize the COM interface itself.<!-- d3d12-review-inline:end:shader-cache:blob-ownership:0:authored:migration-ec159af06e306ff0-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:blob-ownership:1:authored:migration-b1c46bf4f466c16a-0 -->This supported legacy method retrieves cache data. It does not compile source
offline. Allocation failure can return `E_OUTOFMEMORY`. No `S_FALSE` null output
probe or generic minimum valid blob size is specified for this method.
Cached data remains subject to the
[creation and compatibility contract](pipeline-state.md#cached-data).<!-- d3d12-review-inline:end:shader-cache:blob-ownership:1:authored:migration-b1c46bf4f466c16a-0 --></ins>

<a id="driver-cache-contract"></a>

## Runtime and driver cache responsibilities

<ins><!-- d3d12-review-inline:begin:shader-cache:ddi-contract:0:authored:migration-8b5265f29836416b-0 -->Application cache sessions are runtime-managed. Driver-managed cache control is a separate hint interface.<!-- d3d12-review-inline:end:shader-cache:ddi-contract:0:authored:migration-8b5265f29836416b-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ddi-contract:1:authored:migration-367d69e11ae4d235-0 -->`D3D12DDI_D3D12_OPTIONS_DATA_0080::DriverManagedShaderCachePresent` reports the driver-managed cache. Its control entry is `D3D12DDI_DEVICE_FUNCS_CORE_0119::pfnImplicitShaderCacheControl`.<!-- d3d12-review-inline:end:shader-cache:ddi-contract:1:authored:migration-367d69e11ae4d235-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:ddi-contract:2:authored:migration-153d25e4a4a371f8-0 -->The driver pipeline library byte stream is distinct from the runtime-wrapped API serialization format.<!-- d3d12-review-inline:end:shader-cache:ddi-contract:2:authored:migration-153d25e4a4a371f8-0 --></ins>

<a id="cache-ddi-declarations"></a>

<a id="published-cache-control-and-pipeline-library-callback-declarations"></a>

### Published cache control and pipeline library DDI declarations

```cpp
typedef enum D3D12DDI_IMPLICIT_SHADER_CACHE_CONTROL_FLAGS_0080
{
    D3D12DDI_IMPLICIT_SHADER_CACHE_CONTROL_FLAG_0080_DISABLE = 1,
    D3D12DDI_IMPLICIT_SHADER_CACHE_CONTROL_FLAG_0080_ENABLE  = 2,
    D3D12DDI_IMPLICIT_SHADER_CACHE_CONTROL_FLAG_0080_CLEAR   = 4,
} D3D12DDI_IMPLICIT_SHADER_CACHE_CONTROL_FLAGS_0080;

typedef void ( APIENTRY* PFND3D12DDI_IMPLICITSHADERCACHECONTROL_0080 )(
    D3D12DDI_HDEVICE, D3D12DDI_IMPLICIT_SHADER_CACHE_CONTROL_FLAGS_0080 );
```

```cpp
typedef struct D3D12DDIARG_CREATE_PIPELINE_LIBRARY_0010
{
    SIZE_T InitialDataSize;
    CONST VOID* pInitialData;
} D3D12DDIARG_CREATE_PIPELINE_LIBRARY_0010;

typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALC_PRIVATE_PIPELINE_LIBRARY_SIZE_0010 )( D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATE_PIPELINE_LIBRARY_0010* );
typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATE_PIPELINE_LIBRARY_0010 )( D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATE_PIPELINE_LIBRARY_0010*, D3D12DDI_HPIPELINELIBRARY );
typedef VOID ( APIENTRY* PFND3D12DDI_DESTROY_PIPELINE_LIBRARY_0010 )( D3D12DDI_HDEVICE, D3D12DDI_HPIPELINELIBRARY );

typedef HRESULT ( APIENTRY* PFND3D12DDI_ADD_PIPELINE_STATE_TO_LIBRARY_0010 )(
    D3D12DDI_HDEVICE hDevice,
    D3D12DDI_HPIPELINELIBRARY hLibrary,
    D3D12DDI_HPIPELINESTATE hPipelineState,
    UINT PipelineIndex);
typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALC_SERIALIZED_LIBRARY_SIZE_0010 )(
    D3D12DDI_HDEVICE hDevice,
    D3D12DDI_HPIPELINELIBRARY hLibrary );
typedef HRESULT ( APIENTRY* PFND3D12DDI_SERIALIZE_LIBRARY_0010 )(
    D3D12DDI_HDEVICE hDevice,
    D3D12DDI_HPIPELINELIBRARY hLibrary,
    _Out_ VOID *pBlob );
```

<a id="driver-implicit-cache-control"></a>

### PFND3D12DDI_IMPLICITSHADERCACHECONTROL_0080

The **pfnImplicitShaderCacheControl** function can optionally perform an application-requested action on the driver-managed shader cache.

If the driver reports true for `DriverManagedShaderCachePresent`, then the driver should also provide a non-null <ins><!-- d3d12-review-inline:begin:shader-cache:RC-control-presence:0:modified:migration-0247d3169bd8473c-0 -->function for `D3D12DDI_DEVICE_FUNCS_CORE_0119::pfnImplicitShaderCacheControl`.<!-- d3d12-review-inline:end:shader-cache:RC-control-presence:0:modified:migration-0247d3169bd8473c-0 --></ins>

The runtime calls **pfnImplicitShaderCacheControl** in response to an application request for cache control. These application requests are considered as hints to the driver.

<ins><!-- d3d12-review-inline:begin:shader-cache:RC-implicit-control:1:authored:migration-614abb6111ec0254-0 -->Device initialization can convey an already configured disabled cache state.<!-- d3d12-review-inline:end:shader-cache:RC-implicit-control:1:authored:migration-614abb6111ec0254-0 --></ins>

<a id="ddi-pfnd3d12ddi-calc-private-pipeline-library-size-0010"></a>
<a id="ddi-pfnd3d12ddi-create-pipeline-library-0010"></a>
<a id="ddi-pfnd3d12ddi-destroy-pipeline-library-0010"></a>
<a id="pipeline-library-driver"></a>

### Pipeline library driver objects and initial bytes

<ins><!-- d3d12-review-inline:begin:shader-cache:PL-storage:0:authored:migration-26abb64ee17d1b4f-0 -->The `_0010` entries below remain the current pipeline library DDIs.<!-- d3d12-review-inline:end:shader-cache:PL-storage:0:authored:migration-26abb64ee17d1b4f-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:PL-storage:1:authored:migration-7394b5f4fea389a5-0 -->The runtime supplies the private storage reported by the size query. The driver initializes that region and must not free it. Failed creation must unwind partial initialization without relying on a Destroy call.<!-- d3d12-review-inline:end:shader-cache:PL-storage:1:authored:migration-7394b5f4fea389a5-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:PL-initial-data:0:authored:migration-fe48fa85476660e5-0 -->The size query and Create receive the same driver-private initial bytes, not the runtime-wrapped API blob. Fresh driver-library creation uses a zero byte count and null pointer.<!-- d3d12-review-inline:end:shader-cache:PL-initial-data:0:authored:migration-fe48fa85476660e5-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:PL-initial-data:1:authored:migration-4504a6d05f2ada8a-0 -->After successful creation, the driver may retain the immutable initial bytes for the library's lifetime. The create header itself is borrowed for the call. The backing storage remains caller-owned and is covered by the [API retained-input lifetime](#id3d12device1-createpipelinelibrary).<!-- d3d12-review-inline:end:shader-cache:PL-initial-data:1:authored:migration-4504a6d05f2ada8a-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:PL-initial-data:2:authored:migration-04f4a8986fe131e8-0 -->Creation, not the private size query, validates the driver's serialized format.<!-- d3d12-review-inline:end:shader-cache:PL-initial-data:2:authored:migration-04f4a8986fe131e8-0 --></ins>

<a id="ddi-pfnd3d12ddi-add-pipeline-state-to-library-0010"></a>
<a id="pipeline-library-driver-indices"></a>

### Names, indices, PSOs and load references

<ins><!-- d3d12-review-inline:begin:shader-cache:PL-indices:0:authored:migration-534f07be3358ed29-0 -->The runtime maps [StorePipeline](#id3d12pipelinelibrary-storepipeline)'s name to a library-local `UINT PipelineIndex`. The add DDI receives that index and no name string.<!-- d3d12-review-inline:end:shader-cache:PL-indices:0:authored:migration-534f07be3358ed29-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:PL-indices:1:authored:migration-f7867774d99028e0-0 -->Multiple indices may refer to the same PSO information. Successful add makes the PSO's cache information available through that index.<!-- d3d12-review-inline:end:shader-cache:PL-indices:1:authored:migration-f7867774d99028e0-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:PL-indices:2:authored:migration-5f18135090fa3ea8-0 -->Later component/PSO creation carries the association in `D3D12DDI_LIBRARY_REFERENCE_0010`. It must survive driver serialization/recreation. There is no separate library load DDI. Loads may reuse a retained PSO or create one with the library reference and complete creation description.<!-- d3d12-review-inline:end:shader-cache:PL-indices:2:authored:migration-5f18135090fa3ea8-0 --></ins>

<a id="ddi-pfnd3d12ddi-calc-serialized-library-size-0010"></a>
<a id="ddi-pfnd3d12ddi-serialize-library-0010"></a>
<a id="pipeline-library-driver-serialization"></a>

### Private object size, serialized size and output storage

<ins><!-- d3d12-review-inline:begin:shader-cache:PL-serialization:0:authored:migration-838c07ae516bf772-0 -->CalcSerializedLibrarySize reports driver bytes. API GetSerializedSize also includes runtime metadata.<!-- d3d12-review-inline:end:shader-cache:PL-serialization:0:authored:migration-838c07ae516bf772-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:PL-serialization:1:authored:migration-5fd0f66830cce737-0 -->SerializeLibrary receives no capacity argument. The runtime supplies storage of the size reported for the same library contents. The driver writes only its private byte stream.<!-- d3d12-review-inline:end:shader-cache:PL-serialization:1:authored:migration-5fd0f66830cce737-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:PL-serialization:2:authored:migration-b101deb88ce0e307-0 -->The output buffer is borrowed for the call. A failed serialization does not guarantee that the buffer is unchanged or zeroed.<!-- d3d12-review-inline:end:shader-cache:PL-serialization:2:authored:migration-b101deb88ce0e307-0 --></ins>

<a id="pipeline-library-driver-errors"></a>

### Per-call library results and failures

<ins><!-- d3d12-review-inline:begin:shader-cache:PL-errors:0:authored:migration-91cca719fd9594ea-0 -->Size queries and destruction have no recoverable result channel. Creation, add and serialization use the call-specific results below.<!-- d3d12-review-inline:end:shader-cache:PL-errors:0:authored:migration-91cca719fd9594ea-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:PL-errors:1:authored:migration-267a549e01867964-0 -->CreatePipelineLibrary may return `E_OUTOFMEMORY`. For loading initial data, driver `E_INVALIDARG` maps to API `D3D12_ERROR_DRIVER_VERSION_MISMATCH`. `E_INVALIDARG` is not a valid recoverable result for fresh driver-library creation.<!-- d3d12-review-inline:end:shader-cache:PL-errors:1:authored:migration-267a549e01867964-0 --></ins>

<ins><!-- d3d12-review-inline:begin:shader-cache:PL-errors:2:authored:migration-aab3638e39f2e0ce-0 -->AddPipelineStateToLibrary and SerializeLibrary permit recoverable `E_OUTOFMEMORY`, not `E_INVALIDARG`. Undersized API serialization buffers are rejected before the driver call. Other failures follow [device error normalization](pipeline-state.md#driver-creation-errors).<!-- d3d12-review-inline:end:shader-cache:PL-errors:2:authored:migration-aab3638e39f2e0ce-0 --></ins>

<a id="pipeline-library-driver-slots"></a>

### Exact current slot associations

<!-- d3d12-review-alert:begin:shader-cache:PL-slots:0:authored:migration-51ee512e81506a9f-0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> These entries use the [published declarations](#cache-ddi-declarations).
>
> | Current core device slot | Published signature/contract |
> |---|---|
> | `pfnCalcPrivatePipelineLibrarySize` | [PFND3D12DDI_CALC_PRIVATE_PIPELINE_LIBRARY_SIZE_0010](#ddi-pfnd3d12ddi-calc-private-pipeline-library-size-0010) |
> | `pfnCreatePipelineLibrary` | [PFND3D12DDI_CREATE_PIPELINE_LIBRARY_0010](#ddi-pfnd3d12ddi-create-pipeline-library-0010) |
> | `pfnDestroyPipelineLibrary` | [PFND3D12DDI_DESTROY_PIPELINE_LIBRARY_0010](#ddi-pfnd3d12ddi-destroy-pipeline-library-0010) |
> | `pfnAddPipelineStateToLibrary` | [PFND3D12DDI_ADD_PIPELINE_STATE_TO_LIBRARY_0010](#ddi-pfnd3d12ddi-add-pipeline-state-to-library-0010) |
> | `pfnCalcSerializedLibrarySize` | [PFND3D12DDI_CALC_SERIALIZED_LIBRARY_SIZE_0010](#ddi-pfnd3d12ddi-calc-serialized-library-size-0010) |
> | `pfnSerializeLibrary` | [PFND3D12DDI_SERIALIZE_LIBRARY_0010](#ddi-pfnd3d12ddi-serialize-library-0010) |

<!-- d3d12-review-alert:end:shader-cache:PL-slots:0:authored:migration-51ee512e81506a9f-0 -->
