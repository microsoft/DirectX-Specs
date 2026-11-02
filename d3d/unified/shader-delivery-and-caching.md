<a id="shader-delivery-and-caching"></a>

# Shader delivery and caching

Ordinary offline frontend compilation translates source into DXBC or DXIL bytecode.
Explicit offline **driver/pipeline compilation** and driver-cache control are the
forward-facing directions for replacing application-managed legacy driver-cache
blobs and pipeline libraries. These are different compilation stages.

Cached pipeline-state blobs and pipeline libraries are supported legacy mechanisms.
Legacy classification does not make their methods removed, deprecated or no-ops.
Their complete storage, lifetime, matching and compatibility contracts apply.

Application cache sessions store application-selected opaque key/value data.
They are distinct from the caches used for driver compilations or runtime shader
conversions. A cache operation does not compile, validate or sign its values.

[Pipeline state](pipeline-state.md#cached-data) owns complete PSO descriptions,
creation and cached-input consumption. [Shader hash-bypass capability](devices-and-capabilities.md#d3d12_feature_data_bytecode_bypass_hash_supported)
and [bytecode-validation policy](diagnostics.md#d3d12-debug-device-bytecode-validation-mode)
qualify shader acceptance; cache storage does not add an unconditional signed-shader
requirement. [Feature queries](devices-and-capabilities.md#id3d12device-checkfeaturesupport)
own payload layout and query validation. [CPU threading](execution.md#threading)
and [submitted-object lifetime](execution.md#lifetime) remain execution
contracts; a cache lookup, store, serialization or deletion is not proof of GPU completion.

[Advanced Shader Delivery](advanced-shader-delivery.md) groups SODB inputs, offline compiler interfaces and registered precompiled shader database (PSDB) delivery. [Compiler cache sessions](compiler-invocation-and-cache-output.md#output-storage) store typed compilation results and group mappings, distinct from the application-selected opaque values and supported legacy pipeline caches below. [Runtime discovery](runtime-cache-discovery.md#runtime-cache-discovery) defines read-only PSDB eligibility and [retained initialization state](runtime-cache-discovery.md#failure-and-lifetime); it is not a cache-hit guarantee or a promise that cache controls rediscover a different registered component.

<a id="cache-support"></a>

## Cache support and availability

The `SupportFlags` output of
[`D3D12_FEATURE_DATA_SHADER_CACHE`](devices-and-capabilities.md#d3d12_feature_data_shader_cache)
uses the following bits. [`D3D12_FEATURE_DATA_SHADERCACHE_ABI_SUPPORT`](devices-and-capabilities.md#d3d12_feature_data_shadercache_abi_support)
is a distinct query; its ABI range is not a portability guarantee for a legacy
serialized library or cached PSO.

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

| Flag | Meaning |
| --- | --- |
| `NONE` | No shader-cache support bits. |
| `SINGLE_PSO` | Supports the `CachedPSO` member of graphics and compute PSO descriptions. This is always supported. |
| `LIBRARY` | Supports application-controlled PSO grouping/caching through `ID3D12PipelineLibrary`. |
| `AUTOMATIC_INPROC_CACHE` | OS-managed compiled-shader cache in memory during the application's current run. |
| `AUTOMATIC_DISK_CACHE` | OS-managed compiled-shader cache on disk for future application runs. |
| `DRIVER_MANAGED_CACHE` | Reports the presence of a cache managed by the driver. |
| `SHADER_CONTROL_CLEAR` | Reports support for `CLEAR` without developer mode. `ENABLE` and `DISABLE` still require developer mode, including when combined with `CLEAR`. |
| `SHADER_SESSION_DELETE` | Reports support for deleting shader-cache sessions. |

The shortened flag names in this table have prefix `D3D12_SHADER_CACHE_SUPPORT_`.
Support bits describe capabilities, not the presence of a particular cache entry.
An implicit cache kind may not exist even when a control request names it.
Application session availability, clear capability and developer-mode permission
for enabling/disabling caches are separate conditions; driver compilation-cache support is not application-value validation.

<a id="cache-sessions"></a>

## Application-owned cache sessions

Sessions use the [session descriptor](#d3d12-shader-cache-session-desc),
[storage modes](#d3d12-shader-cache-mode) and [session flags](#d3d12-shader-cache-flags).
Cache control uses the separate [kind mask](#d3d12-shader-cache-kind-flags)
and [control mask](#d3d12-shader-cache-control-flags). These types are not PSO
descriptions or shader-bytecode containers.

Windows includes a component called D3DSCache, which is a DirectX Shader Cache. This component manages caches of key/value pairs which are:
* Process-local: the cache is tied to the executable that created it.
* UWP friendly
* Integrated with disk cleanup and other OS policy
* Versioned
* Accessible to applications through cache sessions

D3DSCache also serves these runtime and driver purposes:
1. As an alternative to IHV-provided custom-built shader caches for driver shader compilations or other transient data
2. For D3D12 applications which provide DXBC shaders, but drivers want DXIL, D3D12 will perform this conversion and cache the result

Application cache sessions enable applications to cache DXBC, DXIL, or other intermediate shader code representations, tied to some opaque key. For example, an app might have an input pre-compiled shader, combined with some set of constants, which map to a specialized variation of that shader. The first time the app sees a specific combination of (shader + constants), i.e. the key, they would perform the specialization and cache the result. The next time they see it, they can look it up from the cache.

<a id="d3d12-shader-cache-mode"></a>

### D3D12_SHADER_CACHE_MODE

```cpp
typedef enum D3D12_SHADER_CACHE_MODE
{
    D3D12_SHADER_CACHE_MODE_MEMORY,
    D3D12_SHADER_CACHE_MODE_DISK,
} D3D12_SHADER_CACHE_MODE;
```

| Value | Meaning |
| --- | --- |
| `D3D12_SHADER_CACHE_MODE_MEMORY` | There is no backing file for this cache. All stores are discarded when the last session for that underlying cache is destroyed. |
| `D3D12_SHADER_CACHE_MODE_DISK` | The session is backed by files on disk, that will persist from run to run, unless cleared. |

Disk caches can be cleared in one of these ways:
1. Explicitly, by calling `SetDeleteOnDestroy()` on the session object, and then releasing all corresponding sessions.
2. Explicitly, by calling `ShaderCacheControl()` with `D3D12_SHADER_CACHE_KIND_FLAG_APPLICATION_MANAGED` and `CLEAR`. Outside developer mode, clear-only control requires `D3D12_SHADER_CACHE_SUPPORT_SHADER_CONTROL_CLEAR`; any combined `ENABLE` or `DISABLE` operation still requires developer mode.
3. Implicitly, by opening a cache with a different `Version` when no corresponding sessions remain open. With active corresponding sessions, creation instead returns `DXGI_ERROR_ALREADY_EXISTS`.
4. Externally, by the disk cleanup utility enumerating it and clearing it. This will not happen for caches created with the `D3D12_SHADER_CACHE_FLAG_USE_WORKING_DIR` flag.
5. Manually, by deleting the working-directory cache files stored on disk for `D3D12_SHADER_CACHE_FLAG_USE_WORKING_DIR` caches. The application should not attempt to do this for caches stored outside of the working directory.

Manual working-directory cleanup is not permission to delete an active cache's
backing files. The application must first release all corresponding sessions
that can access those files and obey operating-system ownership, access and
file-sharing constraints. This permission does not extend to cache files
managed outside the working directory. Physical filename suffixes are not a
portable serialization contract.

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

| Value | Meaning |
| --- | --- |
| `D3D12_SHADER_CACHE_FLAG_NONE` | No flags. |
| `D3D12_SHADER_CACHE_FLAG_DRIVER_VERSIONED` | The cache is implicitly versioned by the driver being used. Caches created this way are stored side-by-side for each adapter on which the application runs for multi-GPU systems. The `Version` field in the cache description is used as an additional constraint. |
| `D3D12_SHADER_CACHE_FLAG_USE_WORKING_DIR` | By default, caches are stored in temporary storage, and can be cleared by disk cleanup. When this flag is used (not valid for UWP apps), the cache is instead stored in the current working directory. |

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

| Field | Description |
| --- | --- |
| `Identifier` | A unique identifier for this specific cache. Caches with different identifiers are stored side-by-side. Caches with the same identifier are shared across all sessions in the same process. Creating a disk cache with the same identifier as an already-existing cache will open that cache, unless the `Version` mismatches. In that case, if there are no other sessions open to that cache, it is cleared and re-created. If there are existing sessions, CreateShaderCacheSession returns `DXGI_ERROR_ALREADY_EXISTS`. |
| `Mode` | Determines what kind of cache to create/open. |
| `Flags` | Modifies behavior of the cache. |
| `MaximumInMemoryCacheSizeBytes` | In `MEMORY` mode, controls the byte-size policy for the in-memory cache. It does not impose a separate temporary-entry-cache limit in `DISK` mode. |
| `MaximumInMemoryCacheEntries` | Legacy ABI field. It is ignored for capacity and eviction; it does not enforce an entry-count limit. `GetDesc` echoes this input field. |
| `MaximumValueFileSizeBytes` | In `DISK` mode, controls the byte-size policy for the backing cache. It is not the `MEMORY` mode byte quota. |
| `Version` | Additional application version constraint. A mismatch clears and re-creates the cache only when no corresponding sessions remain open; otherwise creation returns `DXGI_ERROR_ALREADY_EXISTS`, as specified for `Identifier`. |

No fixed default limits are specified. Inputs open to dynamic reinterpretation,
including zero-valued size controls, are resolved by the applicable cache policy.
A zero field does not promise a particular fixed byte quota or unlimited storage.
[GetDesc](#id3d12shadercachesession-getdesc) reports the resolved descriptor;
the ignored entry-count field is not a dynamically enforced default.

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

| Value | Meaning |
| --- | --- |
| `D3D12_SHADER_CACHE_KIND_FLAG_IMPLICIT_D3D_CACHE_FOR_DRIVER` | Refers to the cache which is managed by D3D12 to store driver compilations of application shaders. |
| `D3D12_SHADER_CACHE_KIND_FLAG_IMPLICIT_D3D_CONVERSIONS` | Refers to the cache which is used to store D3D12's conversions of one shader type to another (e.g. DXBC shaders to DXIL shaders). |
| `D3D12_SHADER_CACHE_KIND_FLAG_IMPLICIT_DRIVER_MANAGED` | Refers to the cache which is managed by the driver. Operations for this cache are hints. |
| `D3D12_SHADER_CACHE_KIND_FLAG_APPLICATION_MANAGED` | Refers to all shader cache sessions created by the `CreateShaderCacheSession` API. Requests to `CLEAR` apply to active application cache sessions belonging to the current device, as well as ordinary on-disk application caches created without `D3D12_SHADER_CACHE_FLAG_USE_WORKING_DIR`. [Control scope and failure ordering](#cache-control-scope) distinguish shared backing data from per-device enable/disable state. |

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

| Value | Meaning |
| --- | --- |
| `D3D12_SHADER_CACHE_CONTROL_FLAG_DISABLE` | The cache should not be used to look up data, and should not have new data stored in it. Attempts to use/create a cache while disabled will return `DXGI_ERROR_NOT_CURRENTLY_AVAILABLE`. |
| `D3D12_SHADER_CACHE_CONTROL_FLAG_ENABLE` | Resumes use of the cache. |
| `D3D12_SHADER_CACHE_CONTROL_FLAG_CLEAR` | Any existing contents of the cache should be deleted. |

The app cannot pass both `DISABLE` and `ENABLE` at the same time, and must pass at least one flag.

<a id="session-identity"></a>

### Session identity, limits and concurrency

The executable owns the application cache namespace; equal `Identifier` values
do not make caches a cross-application interchange format. Sessions in one process
with the same effective cache identity share storage. `DRIVER_VERSIONED` adds
adapter/driver identity, while `Version` remains an additional application constraint.
The active-session version-mismatch rule prevents silently clearing a cache still
opened by another session.

An additional session is not a descriptor-update operation. Reopening a live cache
does not resize it or turn an existing memory cache into a disk cache. Applications
do not obtain independent storage merely by changing capacity fields while
reusing its identity. The documented `DXGI_ERROR_ALREADY_EXISTS` version-mismatch
rule is not a blanket error rule for every descriptor difference.
A different `Identifier` selects independent storage.

Session methods follow the [CPU threading contract](execution.md#threading).
Individual operations on shared cache storage can synchronize internally, but
a size query followed by a data retrieval is not one atomic operation.

Memory-mode eviction concerns the in-memory cache's applicable byte-size policy.
Disk-mode capacity is governed by the backing-cache byte-size policy; a store
that cannot fit can return `DXGI_ERROR_CACHE_FULL`. The disk cache does not
promise a separate application-controlled temporary key/value cache or LRU
coverage of all values through `MaximumInMemoryCacheSizeBytes` or the ignored
entry-count field. Deletion or clearing can invalidate an entry between a size
query and the subsequent data lookup.

<a id="id3d12device9-createshadercachesession"></a>

### ID3D12Device9::CreateShaderCacheSession

#### Declaration

```cpp
HRESULT CreateShaderCacheSession(const D3D12_SHADER_CACHE_SESSION_DESC* pDesc, REFIID riid, void** ppvSession);
```

#### Behavior

Creates an object that grants access to a shader cache, potentially opening an existing cache or creating a new one.

#### Parameters

`pDesc` (input)

A `D3D12_SHADER_CACHE_SESSION_DESC` structure describing the shader cache session to create.

`riid` (input)

The globally unique identifier (`GUID`) for the shader cache session interface.

`ppvSession` (output, optional)

A pointer to a memory block that receives a pointer to the [`ID3D12ShaderCacheSession`](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nn-d3d12-id3d12shadercachesession) interface for the shader cache session.

#### Return values

If the function succeeds, it returns `S_OK`. Otherwise, it returns an [`HRESULT`](https://learn.microsoft.com/en-us/windows/desktop/com/structure-of-com-error-codes) [error code](https://learn.microsoft.com/en-us/windows/win32/com/com-error-codes-10).

|Return value|Description|
| --- | --- |
| `DXGI_ERROR_ALREADY_EXISTS` | An existing cache with this identifier has an incompatible version while sessions remain open. See [`D3D12_SHADER_CACHE_SESSION_DESC::Identifier`](#d3d12-shader-cache-session-desc). |

#### Runtime validation and lifetime

`pDesc` is required. `Mode` is `MEMORY` or `DISK`; flags are the defined
`DRIVER_VERSIONED` and `USE_WORKING_DIR` bits or `NONE`. A null/reserved
identifier or invalid mode/flags returns `E_INVALIDARG`. Disabled
application-managed caching returns `DXGI_ERROR_NOT_CURRENTLY_AVAILABLE`.
The descriptor is consumed by the call; the returned COM interface owns a session.

A null `ppvSession` performs descriptor validation and returns `S_FALSE` on success,
without opening a session. It is not a disk-access, version-compatibility or allocation
test: an actual open may still fail. A supplied output receives the requested
`riid` interface on successful creation; this method does not specify blanket
zeroing of that output on every validation failure.

The null-output probe stops before querying the returned object for `riid`.
Its success does not establish that the requested interface is supported.

<a id="id3d12shadercachesession-findvalue"></a>

### ID3D12ShaderCacheSession::FindValue

#### Declaration

```cpp
HRESULT FindValue(const void* pKey, UINT KeySize, void* pValue, UINT* pValueSize);
```

#### Behavior

Looks up an entry in the cache whose key exactly matches the provided key.

A size-query call can retrieve the required value size before a second call retrieves the data. These are separate lookups, not an atomic operation or a guarantee that the value is retained in a temporary memory-entry cache.

#### Parameters

`pKey` (input)

The key of the entry to look up.

`KeySize` (input)

The size of the key, in bytes.

`pValue` (output, optional)

A pointer to a memory block that receives the cached entry.

`pValueSize` (input, output)

A pointer to a `UINT` that receives the size of the cached entry, in bytes.

#### Return values

If the function succeeds, it returns `S_OK`. Otherwise, it returns an [`HRESULT`](https://learn.microsoft.com/en-us/windows/desktop/com/structure-of-com-error-codes) [error code](https://learn.microsoft.com/en-us/windows/win32/com/com-error-codes-10).

|Return value|Description|
| --- | --- |
| `DXGI_ERROR_CACHE_HASH_COLLISION` | There's an entry with the same hash as the provided key, but the key doesn't exactly match. |
| `DXGI_ERROR_NOT_FOUND` | The entry isn't present. |

#### Buffer and lookup contract

`pKey` and `pValueSize` must be non-null, and `KeySize` must be nonzero;
invalid arguments return `E_INVALIDARG`. `KeySize` counts bytes, not characters.
The caller owns the key and output buffers.

On a successful lookup, null `pValue` queries the required size and returns
`S_OK`; initialize `*pValueSize` before the call. With non-null `pValue`,
the input `*pValueSize` is the writable capacity in bytes. The method writes
the required size to `*pValueSize`; if capacity is too small it returns
`DXGI_ERROR_MORE_DATA` without copying the value. With adequate capacity it
copies the complete value and returns `S_OK`.

For lookup failure before a value is obtained, the size and output buffer are
not success outputs and must not be interpreted as returned cache data.
The method does not promise to zero them. Disabled caching returns
`DXGI_ERROR_NOT_CURRENTLY_AVAILABLE`; allocation or corrupt-cache failures
can also occur. A successful size query does not pin the entry or make a
subsequent lookup atomic with it.

<a id="id3d12shadercachesession-storevalue"></a>

### ID3D12ShaderCacheSession::StoreValue

#### Declaration

```cpp
HRESULT StoreValue(const void* pKey, UINT KeySize, const void* pValue, UINT ValueSize);
```

#### Behavior

Adds an entry to the cache.

#### Parameters

`pKey` (input)

The key of the entry to add.

`KeySize` (input)

The size of the key, in bytes.

`pValue` (input)

A pointer to a memory block containing the entry to add.

`ValueSize` (input)

The size of the entry to add, in bytes.

#### Return values

If the function succeeds, it returns `S_OK`. Otherwise, it returns an [`HRESULT`](https://learn.microsoft.com/en-us/windows/desktop/com/structure-of-com-error-codes) [error code](https://learn.microsoft.com/en-us/windows/win32/com/com-error-codes-10).

|Return value|Description|
| --- | --- |
| `DXGI_ERROR_ALREADY_EXISTS` | There's an entry with the same key. |
| `DXGI_ERROR_CACHE_HASH_COLLISION` | There's an entry with the same hash as the provided key, but the key doesn't match. |
| `DXGI_ERROR_CACHE_FULL` | Adding this entry would cause the cache to become larger than its maximum size. |

#### Buffer ownership and bounds

`pKey` and `pValue` must be non-null; `KeySize` and `ValueSize` must be
nonzero. These invalid arguments return `E_INVALIDARG`. Both sizes are
`UINT` byte counts; application arithmetic must not overflow or truncate them.
Cache storage and metadata limits may reject an entry before either count reaches
`UINT_MAX`; these counts are not a minimum opaque shader/blob-format size.

The cache consumes the key and value bytes during the call; the application may
reuse its input buffers after the call returns. This does not transfer ownership
of application memory to the cache. Stores do not replace an existing key's value.
Disabled caching returns `DXGI_ERROR_NOT_CURRENTLY_AVAILABLE`; allocation failure
can return `E_OUTOFMEMORY`.

<a id="id3d12shadercachesession-setdeleteondestroy"></a>

### ID3D12ShaderCacheSession::SetDeleteOnDestroy

#### Declaration

```cpp
void SetDeleteOnDestroy();
```

#### Behavior

When all cache session objects corresponding to a given cache are destroyed, the cache is cleared.

The [cache-mode contract](#d3d12-shader-cache-mode) lists the ways in which a disk cache can be cleared.

#### Shared lifetime

The request applies to the underlying cache, not merely this interface pointer.
Releasing the requesting session does not clear a cache while another session
for that cache is alive. The last corresponding session's destruction performs
the deferred clear. This is a CPU cache-storage lifetime, not a submitted GPU
object lifetime or a GPU-completion operation.

<a id="id3d12shadercachesession-getdesc"></a>

### ID3D12ShaderCacheSession::GetDesc

#### Declaration

```cpp
D3D12_SHADER_CACHE_SESSION_DESC GetDesc();
```

#### Behavior

Retrieves the resolved description of the cache session.

#### Return values

A [`D3D12_SHADER_CACHE_SESSION_DESC`](#d3d12-shader-cache-session-desc) structure representing the resolved description of the cache session.

#### Descriptor reflection

The return is a structure value, not an `HRESULT` or an allocated output buffer.
No COM object or borrowed descriptor pointer is returned.

The returned description resolves inputs that are open to dynamic
reinterpretation, including cache size policy; it is not a blanket literal
echo of the creation description. The byte-size fields report resolved values.
When a resolved byte size exceeds the range of the legacy `UINT` field,
`GetDesc` returns `UINT_MAX` for that field; this representational saturation
does not change the underlying effective policy to that numeric bound.
`MaximumInMemoryCacheEntries` echoes the supplied value for ABI compatibility,
but that legacy field is ignored and is not an enforced entry limit.
Mode-specific controls retain their meaning: the reflected memory-byte field
does not create a separate `DISK`-mode temporary-entry-cache quota.

<a id="id3d12device9-shadercachecontrol"></a>

### ID3D12Device9::ShaderCacheControl

#### Declaration

```cpp
HRESULT ShaderCacheControl(D3D12_SHADER_CACHE_KIND_FLAGS Kinds, D3D12_SHADER_CACHE_CONTROL_FLAGS Control);
```

#### Behavior

Modifies the behavior of caches used internally by Direct3D or by the driver.
`CLEAR` alone is permitted without developer mode when
`D3D12_SHADER_CACHE_SUPPORT_SHADER_CONTROL_CLEAR` is reported.
`ENABLE` and `DISABLE` require developer mode, including when combined with
`CLEAR`. The [control scope and failure ordering](#cache-control-scope) apply.

#### Parameters

`Kinds` (input)

The caches to modify. Any one of these caches may or may not exist.

`Control` (input)

The way in which to modify the caches. You can't pass both `DISABLE` and `ENABLE` at the same time; and you must pass at least one flag.

#### Return values

`Kinds` must contain at least one defined kind bit. `Control` must contain at
least one defined control bit and must not combine `ENABLE` with `DISABLE`.
`CLEAR` may accompany either `ENABLE` or `DISABLE`, or be used by itself.
Unrecognized bits, empty masks, enabling an already-enabled selected kind or
disabling an already-disabled selected kind return `E_INVALIDARG`.
Successful processing returns `S_OK`; operating-system failures can propagate.
Enabling/disabling caches without developer mode returns
`DXGI_ERROR_SDK_COMPONENT_MISSING`.

Outside developer mode, a clear-only request requires
`D3D12_SHADER_CACHE_SUPPORT_SHADER_CONTROL_CLEAR`. The capability does not
remove the developer-mode requirement from `CLEAR | ENABLE` or
`CLEAR | DISABLE`. It does not guarantee that a selected cache exists or that
a driver-managed cache obeys a control hint.

<a id="cache-control-scope"></a>

#### Scope and failure ordering

Enable/disable state belongs to the device on which `ShaderCacheControl` is
called; it is not a process-global disable switch. The call does not change
another device's enable/disable mask. Active application-session clearing covers
sessions belonging to the current device. On-disk cleanup can additionally reach
ordinary caches in the application's cache namespace. A clear can therefore
affect backing data shared with other sessions or devices without changing
those devices' enable/disable state. Driver-managed control is a hint supplied
through the current device, not an all-device or all-adapter control guarantee.

A combined control request is not transactional. After successful validation,
`ENABLE` or `DISABLE` changes the current device's selected state before any
requested clear. A later clear failure can return an error after that state
change or after some caches have been cleared. There is no rollback or
all-kinds-atomic clearing guarantee; later selected caches or the driver hint
need not have been processed when an earlier clear fails. An error from a
combined operation does not imply that enable/disable state is unchanged.

<a id="pipeline-libraries"></a>

## Supported legacy pipeline libraries

A pipeline library groups compatible PSOs and serializes their cache data.
It does not replace the complete PSO description needed by the load methods.
Sharing identical subcomponents can reduce metadata and duplicated data compared
with separately serialized single-PSO caches; this is not a guarantee of a
particular performance improvement.

The [library thread-safety contract](#library-thread-safety) governs access.

**History:** Pipeline-library caching was recommended to reduce driver PSO
creation overhead. That recommendation describes the supported legacy cache
path, not the forward-facing replacement direction. Driver/runtime updates,
adapter or machine changes can invalidate stored data, and applications still
incur matching, validation, storage and loading costs.

<a id="library-thread-safety"></a>

### Library thread safety

The pipeline library is thread-safe to use, and will internally synchronize as necessary, with one exception: multiple threads loading the same PSO (via [**LoadComputePipeline**](#id3d12pipelinelibrary-loadcomputepipeline),
[**LoadGraphicsPipeline**](#id3d12pipelinelibrary-loadgraphicspipeline), or [**LoadPipeline**](#id3d12pipelinelibrary1-loadpipeline)) should synchronize themselves, as this act may modify the state of that pipeline within the library in a non-thread-safe manner.

<a id="id3d12device1-createpipelinelibrary"></a>

### ID3D12Device1::CreatePipelineLibrary

#### Declaration

```cpp
HRESULT CreatePipelineLibrary(const void *pLibraryBlob, SIZE_T BlobLength, REFIID riid, void** ppPipelineLibrary);
```

#### Behavior

Creates a cached pipeline library. For pipeline state objects (PSOs) that are expected to share data together, grouping them into a library before serializing them means that there's less overhead due to metadata, as well as the opportunity to avoid redundant or duplicated data being written to disk.

You can query for `ID3D12PipelineLibrary` support with **[`ID3D12Device::CheckFeatureSupport`](devices-and-capabilities.md#id3d12device-checkfeaturesupport)**, with **[`D3D12_FEATURE_SHADER_CACHE`](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_feature)** and **[`D3D12_FEATURE_DATA_SHADER_CACHE`](devices-and-capabilities.md#d3d12_feature_data_shader_cache)**. If the `SupportFlags` member of **[`D3D12_FEATURE_DATA_SHADER_CACHE`](devices-and-capabilities.md#d3d12_feature_data_shader_cache)** contains the flag **[`D3D12_SHADER_CACHE_SUPPORT_LIBRARY`](#d3d12-shader-cache-support-flags)**, the `ID3D12PipelineLibrary` interface is supported. If not, then `DXGI_ERROR_UNSUPPORTED` will always be returned when this function is called.

#### Parameters

`pLibraryBlob` (input)

If the input library blob is empty, then the initial content of the library is empty. If the input library blob is not empty, then it is validated for integrity, parsed, and the pointer is stored. The pointer provided as input to this method must remain valid for the lifetime of the object returned. For efficiency reasons, the data is not copied.

`BlobLength` (input)

Specifies the length of `pLibraryBlob` in bytes.

`riid` (input)

Specifies a unique `REFIID` for the [`ID3D12PipelineLibrary`](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/./nn-d3d12-id3d12pipelinelibrary) object. Typically set this and the following parameter with the macro `IID_PPV_ARGS(&Library)`, where **Library** is the name of the object.

`ppPipelineLibrary` (output, optional)

Returns a pointer to the created library.

#### Return values

If the function succeeds, it returns `S_OK`. Otherwise, it returns an [`HRESULT`](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes) [error code](https://learn.microsoft.com/en-us/windows/win32/com/com-error-codes-10), including `E_INVALIDARG` if the blob is corrupted or unrecognized, `D3D12_ERROR_DRIVER_VERSION_MISMATCH` if the provided data came from an old driver or runtime, and `D3D12_ERROR_ADAPTER_NOT_FOUND` if the data came from different hardware.

If you pass `nullptr` for `ppPipelineLibrary` then the runtime still performs the validation of the blob but avoids creating the actual library and returns `S_FALSE` if the library would have been created.

Also, the feature requires an updated driver, and attempting to use it on old drivers will return `DXGI_ERROR_UNSUPPORTED`.

#### Remarks

A pipeline library enables the following operations.

- Adding pipeline state objects (PSOs) to an existing library object (refer to [StorePipeline](#id3d12pipelinelibrary-storepipeline)).
- Serializing a PSO library into a contiguous block of memory for disk storage (refer to [Serialize](#id3d12pipelinelibrary-serialize)).
- De-serializing a PSO library from persistent storage (this is handled by **CreatePipelineLibrary**).
- Retrieving individual PSOs from the library (refer to [LoadComputePipeline](#id3d12pipelinelibrary-loadcomputepipeline) and [LoadGraphicsPipeline](#id3d12pipelinelibrary-loadgraphicspipeline)).

At no point in the lifecycle of a pipeline library is there duplication between PSOs with identical sub-components.

A recommended solution for managing the lifetime of the provided pointer while only having to ref-count the returned interface is to leverage [`ID3D12Object::SetPrivateDataInterface`](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12object-setprivatedatainterface), and use an object which implements `IUnknown`, and frees the memory when the ref-count reaches 0.

The [library thread-safety contract](#library-thread-safety) applies.

##### Examples

See the [Direct3D 12 pipeline state cache sample](https://github.com/microsoft/DirectX-Graphics-Samples/tree/master/Samples/Desktop/D3D12PipelineStateCache).

#### Validation-only probe and storage ownership

With `BlobLength == 0`, the initial library is empty and no input bytes are
consumed. For nonzero length, `pLibraryBlob` must point to that many readable,
unchanging bytes. The application must keep the entire input storage valid
until the returned library is destroyed: the implementation may retain the
input pointer rather than copy the bytes.

The null-output validation probe is `ppPipelineLibrary == nullptr` (not an
input-blob-null probe). Successful validation returns `S_FALSE`; it does not
produce a library or prove final driver object creation. A corrupt, malformed,
unrecognized or truncated blob returns `E_INVALIDARG`; there is no public fixed
minimum valid blob length. Runtime/driver or machine incompatibility can return
`D3D12_ERROR_DRIVER_VERSION_MISMATCH`; a different adapter returns
`D3D12_ERROR_ADAPTER_NOT_FOUND`. Missing library support returns
`DXGI_ERROR_UNSUPPORTED`.

The serialized format is opaque, runtime/driver/hardware-specific and not a
portable shader or standalone PSO description. The library interface is a COM
reference; its input-storage lifetime is an additional application obligation.

The null-output probe stops before querying the returned object for `riid`.
Its success does not establish that the requested interface is supported.

<a id="id3d12pipelinelibrary-storepipeline"></a>

### ID3D12PipelineLibrary::StorePipeline

#### Declaration

```cpp
HRESULT StorePipeline(LPCWSTR pName, ID3D12PipelineState *pPipeline);
```

#### Behavior

Adds the input PSO to an internal database with the corresponding name.

#### Parameters

`pName` (input, optional)

Specifies a unique name for the PSO in the library. Overwriting is not supported.

`pPipeline` (input)

Specifies the [`ID3D12PipelineState`](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nn-d3d12-id3d12pipelinestate) to add.

#### Return values

This method returns an `HRESULT` success or error code, including `E_INVALIDARG` if the name already exists, `E_OUTOFMEMORY` if unable to allocate storage in the library.

#### Names and object lifetime

`pName` names the PSO entry, not the library object. Names are null-terminated
wide strings, case-sensitive and unique within the library. An empty string is
a name. Null `pName` uses the PSO's previously assigned object name; if no name
exists, the call returns `E_INVALIDARG`. This is distinct from the required
non-null lookup names of the load methods. [`ID3D12Object::SetName`](diagnostics.md#id3d12object-setname)
defines assignment of the object's name.

`pPipeline` must be a valid PSO belonging to the library's device. The name is
consumed by the call; the application need not retain the name string afterward.
The library retains the stored PSO information/reference, so releasing the
application's PSO reference does not invalidate the library entry. Renaming the
PSO afterward does not rename an existing library entry.

A failed `StorePipeline` must leave the library's application-visible
name/entry mapping unchanged. Failure is not permission to publish the
requested name as a successful stored entry. This requirement concerns
that mapping, not rollback of every private driver allocation or cache
side effect.

<a id="id3d12pipelinelibrary-loadgraphicspipeline"></a>

### ID3D12PipelineLibrary::LoadGraphicsPipeline

#### Declaration

```cpp
HRESULT LoadGraphicsPipeline(LPCWSTR pName, const D3D12_GRAPHICS_PIPELINE_STATE_DESC* pDesc, REFIID riid, void** ppPipelineState);
```

#### Behavior

Retrieves the requested PSO from the library.

#### Parameters

`pName` (input)

The unique name of the PSO.

`pDesc` (input)

Specifies a description of the required PSO in a [`D3D12_GRAPHICS_PIPELINE_STATE_DESC`](pipeline-state.md#graphics-description) structure. This input description is matched against the data in the current library database, and stored in order to prevent duplication of PSO contents.

`riid` (input)

Specifies a `REFIID` for the [`ID3D12PipelineState`](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nn-d3d12-id3d12pipelinestate) object. Typically set this, and the following parameter, with the macro `IID_PPV_ARGS(&PSO1)`, where `PSO1` is the name of the object.

`ppPipelineState` (output)

Specifies a pointer that will reference the returned PSO.

#### Return values

This method returns an `HRESULT` success or error code, which can include `E_INVALIDARG` if the name doesn’t exist, or if the input description doesn’t match the data in the library, and `E_OUTOFMEMORY` if unable to allocate the return PSO.

#### Description, references and concurrency

`pName` and `pDesc` are required. The lookup uses the unique, case-sensitive
name plus the complete graphics PSO description, including compatible root
signature contents, shaders, fixed-function state and other creation dependencies.
A same-name entry of another pipeline kind does not satisfy a graphics load.
The [graphics description](pipeline-state.md#graphics-description) and
[creation validation](pipeline-state.md#creation-validation) remain required.

`ppPipelineState` is a required output for the requested `riid` interface.
Successful load returns a COM reference owned by the caller. It may refer to a
PSO already retained by the library; the caller must release its reference.
This method has no specified null-output validation-only probe.
The [library thread-safety contract](#library-thread-safety) applies.

<a id="id3d12pipelinelibrary-loadcomputepipeline"></a>

### ID3D12PipelineLibrary::LoadComputePipeline

#### Declaration

```cpp
HRESULT LoadComputePipeline(LPCWSTR pName, const D3D12_COMPUTE_PIPELINE_STATE_DESC* pDesc, REFIID riid, void** ppPipelineState);
```

#### Behavior

Retrieves the requested PSO from the library. The input desc is matched against the data in the current library database, and remembered in order to prevent duplication of PSO contents.

#### Parameters

`pName` (input)

The unique name of the PSO.

`pDesc` (input)

Specifies a description of the required PSO in a [`D3D12_COMPUTE_PIPELINE_STATE_DESC`](pipeline-state.md#compute-description) structure. This input description is matched against the data in the current library database, and stored in order to prevent duplication of PSO contents.

`riid` (input)

Specifies a `REFIID` for the [`ID3D12PipelineState`](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nn-d3d12-id3d12pipelinestate) object. Typically set this, and the following parameter, with the macro `IID_PPV_ARGS(&PSO1)`, where `PSO1` is the name of the object.

`ppPipelineState` (output)

Specifies a pointer that will reference the returned PSO.

#### Return values

This method returns an `HRESULT` success or error code, which can include `E_INVALIDARG` if the name doesn’t exist, or if the input description doesn’t match the data in the library, and `E_OUTOFMEMORY` if unable to allocate the return PSO.

#### Description, references and concurrency

`pName` and `pDesc` are required. The lookup uses the unique, case-sensitive
name plus the complete compute PSO description, including compatible root
signature contents, shader bytecode and other creation dependencies. A same-name
entry of another pipeline kind does not satisfy a compute load.
The [compute description](pipeline-state.md#compute-description) and
[creation validation](pipeline-state.md#creation-validation) remain required.

`ppPipelineState` is a required output for the requested `riid` interface.
Successful load returns a COM reference owned by the caller. It may refer to a
PSO already retained by the library; the caller must release its reference.
This method has no specified null-output validation-only probe.
The [library thread-safety contract](#library-thread-safety) applies.

<a id="id3d12pipelinelibrary1-loadpipeline"></a>

### ID3D12PipelineLibrary1::LoadPipeline

#### Declaration

```cpp
HRESULT LoadPipeline(LPCWSTR pName, const D3D12_PIPELINE_STATE_STREAM_DESC* pDesc, REFIID riid, void** ppPipelineState);
```

#### Behavior

Retrieves the requested PSO from the library. The pipeline stream description is matched against the library database, and remembered in order to prevent duplication of PSO contents.

#### Parameters

`pName` (input)

The unique name of the PSO.

`pDesc` (input)

Describes the required PSO using a [`D3D12_PIPELINE_STATE_STREAM_DESC`](pipeline-state.md#streams) structure. This description is matched against the library database, and stored in order to prevent duplication of PSO contents.

`riid` (input)

Specifies a `REFIID` for the [`ID3D12PipelineState`](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nn-d3d12-id3d12pipelinestate) object.

Your app should typically set this argument and the following argument, `ppPipelineState`, by using the macro `IID_PPV_ARGS(&PSO1)`, where PSO1 is the name of the object.

`ppPipelineState` (output)

Specifies the pointer that will reference the PSO after the function successfully returns.

#### Return values

This method returns an `HRESULT` success or error code, which can include `E_INVALIDARG` if the name doesn't exist or the stream description doesn't match the data in the library, and `E_OUTOFMEMORY` if the function is unable to allocate the resulting PSO.

#### Stream dependencies and references

`pName`, `pDesc` and `ppPipelineState` are required. Matching includes the
pipeline kind and the complete stream's root-signature, shader and state
dependencies; a name alone is insufficient. The
[stream layout and subobjects](pipeline-state.md#streams) and
[creation validation](pipeline-state.md#creation-validation) remain required.
A malformed stream or incompatible description can return `E_INVALIDARG`.

Successful load returns the requested `riid` COM reference to the caller,
which must release it. This method has no specified null-output validation-only
probe. The [library thread-safety contract](#library-thread-safety) applies.

<a id="id3d12pipelinelibrary-getserializedsize"></a>

### ID3D12PipelineLibrary::GetSerializedSize

#### Declaration

```cpp
SIZE_T GetSerializedSize();
```

#### Behavior

Returns the amount of memory required to serialize the current contents of the database.

#### Return values

This method returns a `SIZE_T` object, containing the size required in bytes.

#### Snapshot scope

The result is the required size in bytes for the library's current contents,
not an `HRESULT` or a promise that the library cannot grow. The application must
synchronize modifications across a size-query/serialization pair if it relies
on that pair describing the same contents. An empty library can still require
nonzero serialization metadata; no fixed minimum byte size is exposed.

<a id="id3d12pipelinelibrary-serialize"></a>

### ID3D12PipelineLibrary::Serialize

#### Declaration

```cpp
HRESULT Serialize(void* pData, SIZE_T DataSizeInBytes);
```

#### Behavior

Writes the contents of the library to the provided memory, to be provided back to the runtime at a later time.

#### Parameters

`pData` (output)

Specifies a pointer to the data. This memory must be readable and writable up to the input size. This data can be saved and provided to [CreatePipelineLibrary](#id3d12device1-createpipelinelibrary) at a later time, including future instances of this or other processes. The data becomes invalidated if the runtime or driver is updated, and is not portable to other hardware or devices.

`DataSizeInBytes` (input)

The size provided must be at least the size returned from [GetSerializedSize](#id3d12pipelinelibrary-getserializedsize).

#### Return values

This method returns an `HRESULT` success or error code, including `E_INVALIDARG` if the buffer provided isn’t big enough.

#### Output storage and races

`pData` must point to application-owned readable and writable storage of
`DataSizeInBytes` bytes. Null `pData` is not a size-query idiom; use
`GetSerializedSize`. A size equal to the current requirement is sufficient,
and a larger buffer is permitted. An undersized buffer returns `E_INVALIDARG`;
it does not report a replacement size through an output parameter.

The application owns the serialized bytes after successful return and may save
them. Serialization does not transfer ownership or extend the lifetime of the
destination allocation. A future `CreatePipelineLibrary` that uses those bytes
introduces its own input-storage lifetime. Do not treat a failed serialization
as a valid persisted library or assume that all destination bytes were zeroed.

<a id="cached-pso-blobs"></a>

## Supported legacy cached PSO blobs

A cached PSO blob is an opaque optimization input for later pipeline creation,
not a portable shader binary and not a replacement for a complete PSO description.
[Cached input compatibility and consumption](pipeline-state.md#cached-data)
remain at Pipeline state. In particular, the description and cached data must
match, and the bytes can be specific to hardware, driver and machine.

The ordinary `CachedPSO` creation input must remain readable for the duration of
that creation call; it does not impose `CreatePipelineLibrary`'s retained-input
lifetime. Conversely, passing a serialized library to `CreatePipelineLibrary`
must not be treated as a temporary creation-only input.

<a id="id3d12pipelinestate-getcachedblob"></a>

### ID3D12PipelineState::GetCachedBlob

#### Declaration

```cpp
HRESULT GetCachedBlob(ID3DBlob** ppBlob);
```

#### Behavior

Gets the cached blob representing the pipeline state.

The [cached-data contract](pipeline-state.md#cached-data) defines the output's scope and reuse requirements.

#### Parameters

`ppBlob` (output)

After this method returns, points to the cached blob representing the pipeline state.

#### Return values

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

#### Ownership and legacy behavior

`ppBlob` is a required output pointer to an `ID3DBlob` COM interface.
On success, the caller owns the returned reference and must release it.
`ID3DBlob::GetBufferPointer` and `GetBufferSize` expose the blob's bytes and
byte length; the pointer is valid only while the blob's storage remains alive.
Copying or persisting bytes does not serialize the COM interface itself.

This supported legacy method retrieves cache data; it does not compile source
offline. Allocation failure can return `E_OUTOFMEMORY`. No `S_FALSE` null-output
probe or generic minimum valid blob size is specified for this method.
Cached data remains subject to the
[creation and compatibility contract](pipeline-state.md#cached-data).

<a id="driver-cache-contract"></a>

## Runtime and driver cache responsibilities

Application-session storage and implicit driver compilation caches are distinct:
there is no one-to-one mapping from every session method to a driver callback.
The runtime owns application-facing parameter validation, namespace/session
management and dispatch of supported control requests. Driver-managed cache
control remains a hint.

The published driver capability payload
`D3D12DDI_D3D12_OPTIONS_DATA_0080::DriverManagedShaderCachePresent` reports a
driver-managed cache. Its control callback is
`PFND3D12DDI_IMPLICITSHADERCACHECONTROL_0080`, with a `void` return type.
`D3D12DDI_DEVICE_FUNCS_CORE_0119::pfnImplicitShaderCacheControl` carries that
callback. The `DISABLE`, `ENABLE` and `CLEAR` bits are 1, 2 and 4.

Pipeline libraries use the published `_0010` private-size, create, destroy,
add-pipeline-state, serialized-size and serialize callback family. The driver
library input is an opaque byte extent and the serialized output is opaque.
The application-facing runtime can include its own metadata around driver bytes;
these are not interchangeable public serialization formats. Pipeline creation's
shader, root-signature and fixed-function driver contracts remain at
[Pipeline state](pipeline-state.md#driver).

<a id="cache-ddi-declarations"></a>

### Published cache-control and pipeline-library callback declarations

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

The **pfnImplicitShaderCacheControl** callback function can optionally perform an application-requested action on the driver-managed shader cache.

If the driver reports true for `DriverManagedShaderCachePresent`, then the driver should also provide a non-null function for `D3D12DDI_DEVICE_FUNCS_CORE_0119::pfnImplicitShaderCacheControl`.

The runtime calls **pfnImplicitShaderCacheControl** in response to an application request for cache control. These application requests are considered as hints to the driver.

The runtime supplies the driver device handle and `D3D12DDI_IMPLICIT_SHADER_CACHE_CONTROL_FLAGS_0080`. The bits `DISABLE`, `ENABLE` and `CLEAR` are 1, 2 and 4 and may combine a clear with an enable or disable. The [application validation and permissions](#id3d12device9-shadercachecontrol) reject simultaneous enable/disable, zero or unknown flags before normal dispatch. Enable/disable remain developer-mode operations; clear-only control is permitted without developer mode when `SHADER_CONTROL_CLEAR` is supported.

`DriverManagedShaderCachePresent` identifies the driver-managed cache. The runtime forwards an applicable request to `D3D12DDI_DEVICE_FUNCS_CORE_0119::pfnImplicitShaderCacheControl`; device initialization can also convey an already configured disabled state. This is not a one-to-one call for every named cache kind or every rejected application request. The callback concerns the driver's implicit cache, not registration of a PSDB or the typed runtime get/store callbacks.

The callback returns `void`, with no recoverable control-result HRESULT or completion output. The driver treats the request as a hint; return does not certify deletion of every entry or an atomic transaction across all selected cache kinds. The [control scope/failure-ordering contract](#cache-control-scope) owns runtime sessions and earlier side effects. Driver failure reporting must not be used to manufacture a recoverable HRESULT for this callback.

<a id="pipeline-library-driver"></a>

### Pipeline-library driver objects and initial bytes

The current _0010 callbacks below remain the library ABI in the selected
core-device table. They construct and operate on a driver-private library,
not an application cache session, offline compiler cache or new COM object.
The [API library support/threading/lifetime rules](#pipeline-libraries)
remain canonical.

The private-size query returns `SIZE_T` bytes for the driver's CPU object,
not serialized data or video memory. The runtime reserves at least those
bytes and passes `D3D12DDI_HPIPELINELIBRARY` by value, identifying the
private region. The driver initializes that region and destroys its placed
object when requested; it does not free runtime-owned storage. The creator
has an `HRESULT` result, not an output-handle pointer or runtime-library-handle
argument. Unsuccessful initialization does not establish a matching successful
object; clean up failed partial driver initialization without relying on a
subsequent destroy call.

`D3D12DDIARG_CREATE_PIPELINE_LIBRARY_0010` supplies `InitialDataSize` bytes
through `pInitialData`. Both the private-size query and create callback must
receive the same driver-private initial byte extent, not the whole
runtime-wrapped API serialization blob. Fresh driver-library creation uses
zero size and a null pointer. A zero driver-byte count is not by itself a
statement that the whole API blob has no metadata.

The argument header is borrowed for the call. After successful creation,
the driver may retain the supplied immutable initial byte view for the
library's lifetime. Destruction ends the library's use of that view.
A size query without successful creation establishes no retained
library-input lifetime. The driver does not own/free
the backing storage; the [API retained-input obligation](#id3d12device1-createpipelinelibrary)
keeps the complete backing allocation alive. A driver may instead copy or
materialize its own data. This library-specific storage guarantee must not
be replaced by the ordinary PSO creation-only input lifetime.

Runtime wrapper bytes and driver bytes are opaque and distinct. No private
header, offsets or vendor serialization format is defined here. A size
query does not certify that the driver's initial-data format is supported;
actual creation can reject incompatible initial data.

<a id="pipeline-library-driver-indices"></a>

### Names, indices, PSOs and load references

`StorePipeline` performs the runtime's name/entry validation and supplies
the driver add callback with `hDevice`, `hLibrary`, `hPipelineState` and the
runtime-assigned `UINT` `PipelineIndex`. No name string is passed in that DDI.
An invalid or duplicate-name call can fail before the driver add operation;
there is no unconditional one-API/one-DDI call-count guarantee.

`PipelineIndex` identifies an association within the supplied library, not
a pointer, API name, physical node or globally unique object. Multiple
indices may describe the same PSO information. On successful add the driver
makes that PSO's cache information available through the association. The
runtime's names/complete-description checks remain separate. Failure does
not establish a successful stored entry; the [failed-store mapping rule](#id3d12pipelinelibrary-storepipeline)
applies without turning private cache side effects into a transaction.

Subsequent component/PSO creation carries `hLibrary` and `PipelineIndex` in
[D3D12DDI_LIBRARY_REFERENCE_0010](pipeline-state.md#driver). The association
must retain its meaning across driver serialization/recreation so the
runtime's restored entry indices resolve the corresponding driver data.
A reference is an optimization input, not a replacement for the complete
current [PSO creation arguments](pipeline-state.md#driver-pso-creation).
There is no separate pipeline-library load callback in this six-entry family.
Loads can reuse a retained PSO or create one using the library reference.

The runtime retains stored PSO information/references under the API lifetime
contract; add does not transfer ownership of the PSO's private allocation to
the driver library. A surviving PSO does not by itself extend the validity
of a destroyed library handle or its reclaimed initial bytes. The respective
object destruction/storage contracts still govern driver references.

<a id="pipeline-library-driver-serialization"></a>

### Private object size, serialized size and output storage

`CalcPrivatePipelineLibrarySize` describes the CPU private object allocation.
`CalcSerializedLibrarySize` describes the driver's current serialized byte
requirement. The API `GetSerializedSize` can include additional runtime
metadata; its total is not the driver's byte count and none of these sizes
is a shader-code size or a GPU completion value.

The runtime supplies `SerializeLibrary` with `hDevice`, `hLibrary` and writable
`pBlob` storage for the driver bytes. This callback has no capacity argument
or replacement-size output. Its writable extent is the serialized-size
requirement for the same library contents; it is not permission to write
runtime wrapper bytes or an arbitrary larger API buffer. Maintain compatible
contents across sizing/serialization and use the [API synchronization and
snapshot contract](#id3d12pipelinelibrary-getserializedsize). Zero driver
bytes do not imply zero API serialization metadata or a universal minimum
blob size.

The destination is borrowed only for the call and remains caller-owned.
A null output is not a new size-query idiom. Successful return completes
the driver-byte write; it does not persist data to disk, transfer an
allocation or certify future compatibility. Failed serialization is not a
valid saved library and does not guarantee zeroed or transactionally restored
output bytes. Later recreation has its separate retained-input lifetime.

<a id="pipeline-library-driver-errors"></a>

### Per-call library results and failures

The two size queries return `SIZE_T` byte counts, destroy returns `VOID`,
and create/add/serialize return `HRESULT`. The size/destroy entries have no
recoverable `HRESULT` error channel or defined zero/max-value error code.
Storage ownership follows the [current creation storage model](pipeline-state.md#driver-object-lifetime),
but the accepted library results remain specific to these calls.

`CreatePipelineLibrary` returns `S_OK` on success or may return `E_OUTOFMEMORY`.
`E_INVALIDARG` is permitted to reject initial library data on load; the runtime
translates that rejection to `D3D12_ERROR_DRIVER_VERSION_MISMATCH`. It is not
a valid recoverable result for fresh creation with no initial data; the
runtime treats that case as an invalid driver result. Runtime validation
of the whole API blob has its own `E_INVALIDARG`/compatibility outcomes and
can stop before any actual driver-library creation.

`AddPipelineStateToLibrary` and `SerializeLibrary` permit recoverable
`E_OUTOFMEMORY`, not arbitrary `E_INVALIDARG` passthrough. In particular an
undersized API `Serialize` buffer is rejected by the runtime before this
capacity-less driver writer, not a new driver buffer-size result. The
[current device-removal/error normalization](pipeline-state.md#driver-creation-errors)
remains: unexpected driver results invalidate the device, device/application
failure reports retain their mappings, and removal can supersede an
otherwise returned result. These are not command-list errors deferred to
Close or the native queue's different allocation-failure model.

<a id="pipeline-library-driver-slots"></a>

### Exact current slot associations

| Current core-device slot | Published signature/contract |
|---|---|
| `pfnCalcPrivatePipelineLibrarySize` | [PFND3D12DDI_CALC_PRIVATE_PIPELINE_LIBRARY_SIZE_0010](#ddi-pfnd3d12ddi-calc-private-pipeline-library-size-0010) |
| `pfnCreatePipelineLibrary` | [PFND3D12DDI_CREATE_PIPELINE_LIBRARY_0010](#ddi-pfnd3d12ddi-create-pipeline-library-0010) |
| `pfnDestroyPipelineLibrary` | [PFND3D12DDI_DESTROY_PIPELINE_LIBRARY_0010](#ddi-pfnd3d12ddi-destroy-pipeline-library-0010) |
| `pfnAddPipelineStateToLibrary` | [PFND3D12DDI_ADD_PIPELINE_STATE_TO_LIBRARY_0010](#ddi-pfnd3d12ddi-add-pipeline-state-to-library-0010) |
| `pfnCalcSerializedLibrarySize` | [PFND3D12DDI_CALC_SERIALIZED_LIBRARY_SIZE_0010](#ddi-pfnd3d12ddi-calc-serialized-library-size-0010) |
| `pfnSerializeLibrary` | [PFND3D12DDI_SERIALIZE_LIBRARY_0010](#ddi-pfnd3d12ddi-serialize-library-0010) |

<a id="ddi-pfnd3d12ddi-calc-private-pipeline-library-size-0010"></a>

#### PFND3D12DDI_CALC_PRIVATE_PIPELINE_LIBRARY_SIZE_0010

**Declaration:** [PFND3D12DDI_CALC_PRIVATE_PIPELINE_LIBRARY_SIZE_0010](#cache-ddi-declarations), in the exact published callback family above.

##### Behavior

Calculates the pipeline library size.

The inputs are the driver device and current library-create description.
Return the CPU private byte requirement under the [storage/initial-data contract](#pipeline-library-driver).
The query does not create a library or validate its serialized format.

<a id="ddi-pfnd3d12ddi-create-pipeline-library-0010"></a>

#### PFND3D12DDI_CREATE_PIPELINE_LIBRARY_0010

**Declaration:** [PFND3D12DDI_CREATE_PIPELINE_LIBRARY_0010](#cache-ddi-declarations), in the exact published callback family above.

##### Behavior

Create a pipeline library.

The inputs are the driver device, borrowed create-description header and
by-value driver library handle to caller-reserved private storage. Initial
bytes have the [retained driver-input lifetime](#pipeline-library-driver).
The [load rejection/fresh-create error distinction](#pipeline-library-driver-errors)
applies; successful creation is paired with the destroy callback.

<a id="ddi-pfnd3d12ddi-destroy-pipeline-library-0010"></a>

#### PFND3D12DDI_DESTROY_PIPELINE_LIBRARY_0010

**Declaration:** [PFND3D12DDI_DESTROY_PIPELINE_LIBRARY_0010](#cache-ddi-declarations), in the exact published callback family above.

##### Behavior

Destroys the pipeline library.

The arguments identify the driver device and successfully created driver
library. Destroy the placed object and stop using its borrowed initial
bytes before the runtime reclaims library/private backing storage. The
call does not free caller allocations or signal GPU completion.

<a id="ddi-pfnd3d12ddi-add-pipeline-state-to-library-0010"></a>

#### PFND3D12DDI_ADD_PIPELINE_STATE_TO_LIBRARY_0010

**Declaration:** [PFND3D12DDI_ADD_PIPELINE_STATE_TO_LIBRARY_0010](#cache-ddi-declarations), in the exact published callback family above.

##### Behavior

Adds the input pipeline state to the corresponding library.

The arguments identify the device, library, existing driver PSO and
library-local `PipelineIndex`. The [name/index/reference contract](#pipeline-library-driver-indices)
and [failure mapping](#pipeline-library-driver-errors) apply. Successful
association is not ownership transfer of a PSO or a new API name.

<a id="ddi-pfnd3d12ddi-calc-serialized-library-size-0010"></a>

#### PFND3D12DDI_CALC_SERIALIZED_LIBRARY_SIZE_0010

**Declaration:** [PFND3D12DDI_CALC_SERIALIZED_LIBRARY_SIZE_0010](#cache-ddi-declarations), in the exact published callback family above.

##### Behavior

Calculates serialized library size.

The device/library handles select the current driver-library contents.
Return their serialized driver-byte requirement, not the API wrapper's
total or CPU private-object size. The [same-contents size/output contract](#pipeline-library-driver-serialization)
applies.

<a id="ddi-pfnd3d12ddi-serialize-library-0010"></a>

#### PFND3D12DDI_SERIALIZE_LIBRARY_0010

**Declaration:** [PFND3D12DDI_SERIALIZE_LIBRARY_0010](#cache-ddi-declarations), in the exact published callback family above.

##### Behavior

Implemented by the client driver to serialize the library.

The device/library handles select the contents and `pBlob` supplies their
writable driver-byte output. No size argument is passed. The [exact writable
extent and borrowed-output contract](#pipeline-library-driver-serialization)
and [per-call result policy](#pipeline-library-driver-errors) apply.
