# D3D12 Shader Cache APIs

To date, D3D12 has had several iterations of shader caching APIs. However, they've all been focused around caching *driver* compilations of app-provided bytecode. This process is known to be expensive, and has to be performed at runtime, because that's the only place that the driver and hardware are known. The expectation is that the app has compiled its shaders into bytecode during some offline step, so only that last bit is the thing that needs to be cached.

As it turns out, this is not always the case. While we discourage apps from needlessly invoking the shader compiler at runtime, there are cases where apps may need to do some dynamic work that would benefit from caching:
* D3D12 will only accept signed shaders. That means that if any patching or runtime optimizations are performed, such as constant folding, the shader must be re-validated and re-signed, which is non-trivial.
* In the context of mapping layers built on top of D3D12, the application-provided input must be converted into a form that D3D12 will accept, which can be very expensive.

## Introducing D3DSCache

For several years now, Windows 10 has included a component called D3DSCache, which is a DirectX Shader Cache. This component manages caches of key/value pairs which are:
* Process-local: the cache is tied to the executable that created it.
* UWP friendly
* Integrated with disk cleanup and other OS policy
* Versioned
* And until now, transparent to applications

These caches are currently used for two purposes:
1. As an alternative to IHV-provided custom-built shader caches for driver shader compilations or other transient data
2. For D3D12 applications which provide DXBC shaders, but drivers want DXIL, D3D12 will perform this conversion and cache the result

This document outlines a new third use for this component: to enable applications to cache DXBC, DXIL, or other intermediate shader code representations, tied to some opaque key. For example, an app might have an input pre-compiled shader, combined with some set of constants, which map to a specialized variation of that shader. The first time the app sees a specific combination of (shader + constants), i.e. the key, they would perform the specialization and cache the result. The next time they see it, they can look it up from the cache.

## Control over existing caches

In addition to the ability for applications to cache their own shaders and intermediates, we've heard feedback that apps want more control over the existing caches, for profiling purposes. To that extent, we're adding APIs to enable apps to clear existing caches, as well as disable them to prevent new entries from being added. We're also going to coordinate with IHVs, and provide suggestions that they do the same for any caches which are not under OS control.

## New APIs

```c++
enum D3D12_SHADER_CACHE_MODE
{
    D3D12_SHADER_CACHE_MODE_MEMORY,
    D3D12_SHADER_CACHE_MODE_DISK,
};

enum D3D12_SHADER_CACHE_FLAGS
{
    D3D12_SHADER_CACHE_FLAG_NONE = 0x0,
    D3D12_SHADER_CACHE_FLAG_DRIVER_VERSIONED = 0x1,
    D3D12_SHADER_CACHE_FLAG_USE_WORKING_DIR = 0x2,
};

struct D3D12_SHADER_CACHE_SESSION_DESC
{
    GUID Identifier;
    D3D12_SHADER_CACHE_MODE Mode;
    D3D12_SHADER_CACHE_FLAGS Flags;

    UINT MaximumInMemoryCacheSizeBytes;
    UINT MaximumInMemoryCacheEntries;

    UINT MaximumValueFileSizeBytes;

    UINT64 Version;
};

interface ID3D12ShaderCacheSession : ID3D12DeviceChild
{
    HRESULT FindValue(
        _In_reads_bytes_(KeySize) const void* pKey,
        UINT KeySize,
        _Out_writes_bytes_(*pValueSize) void* pValue,
        _Inout_ UINT* pValueSize);
    HRESULT StoreValue(
        _In_reads_bytes_(KeySize) const void* pKey,
        UINT KeySize,
        _In_reads_bytes_(ValueSize) const void* pValue,
        UINT ValueSize);

    void SetDeleteOnDestroy();
    D3D12_SHADER_CACHE_SESSION_DESC GetDesc();
}

enum D3D12_SHADER_CACHE_KIND_FLAGS
{
    D3D12_SHADER_CACHE_KIND_FLAG_IMPLICIT_D3D_CACHE_FOR_DRIVER = 0x1,
    D3D12_SHADER_CACHE_KIND_FLAG_IMPLICIT_D3D_CONVERSIONS = 0x2,
    D3D12_SHADER_CACHE_KIND_FLAG_IMPLICIT_DRIVER_MANAGED = 0x4,
    D3D12_SHADER_CACHE_KIND_FLAG_APPLICATION_MANAGED = 0x8,
};

enum D3D12_SHADER_CACHE_CONTROL_FLAGS
{
    D3D12_SHADER_CACHE_CONTROL_FLAG_DISABLE = 0x1,
    D3D12_SHADER_CACHE_CONTROL_FLAG_ENABLE = 0x2,
    D3D12_SHADER_CACHE_CONTROL_FLAG_CLEAR = 0x4,
};

interface ID3D12Device9 : ID3D12Device8
{
    HRESULT CreateShaderCacheSession(
        _In_ const D3D12_SHADER_CACHE_SESSION_DESC* pDesc,
        REFIID riid,
        _COM_Outptr_opt_ void** ppvSession);
    
    HRESULT ShaderCacheControl(
        D3D12_SHADER_CACHE_KIND_FLAGS Kinds,
        D3D12_SHADER_CACHE_CONTROL_FLAGS Control);
}
```

### D3D12_SHADER_CACHE_MODE

| Value | Meaning |
|-------|---------|
| `D3D12_SHADER_CACHE_MODE_MEMORY` | There is no backing file for this cache. All stores are discarded when the session object is destroyed. |
| `D3D12_SHADER_CACHE_MODE_DISK` | The session is backed by files on disk, that will persist from run to run, unless cleared. |

Disk caches can be cleared in one of these ways:
1. Explicitly, by calling `SetDeleteOnDestroy()` on the session object, and then releasing the session.
2. Explicitly, in developer mode, by calling `ShaderCacheControl()` with `D3D12_SHADER_CACHE_KIND_FLAG_APPLICATION_MANAGED`.
3. Implicitly, by creating a session object with a version that doesn't match the version used to create it.
4. Externally, by the disk cleanup utility enumerating it and clearing it. This will not happen for caches created with the **D3D12_SHADER_CACHE_FLAG_USE_WORKING_DIR** flag.
5. Manually, by deleting the files (`*.idx`, `*.val`, `*.lock`) stored on disk for **D3D12_SHADER_CACHE_FLAG_USE_WORKING_DIR** caches. The application should not attempt to do this for caches stored outside of the working directory.

### D3D12_SHADER_CACHE_FLAGS

| Value | Meaning |
|-------|---------|
| `D3D12_SHADER_CACHE_FLAG_DRIVER_VERSIONED` | The cache is implicitly versioned by the driver being used. Caches created this way are stored side-by-side for each adapter on which the application runs for multi-GPU systems. The Version field in the cache description is used as an additional constraint. |
| `D3D12_SHADER_CACHE_FLAG_USE_WORKING_DIR` | By default, caches are stored in temporary storage, and can be cleared by disk cleanup. When this flag is used (not valid for UWP apps), the cache is instead stored in the current working directory. |

### D3D12_SHADER_CACHE_SESSION_DESC

| Field | Description |
|-------|-------------|
| `Identifier` | A unique identifier for this specific cache. Caches with different identifiers are stored side-by-side. Caches with the same identifier are shared across all sessions in the same process. Creating a disk cache with the same identifier as an already-existing cache will open that cache, unless the **Version** mismatches. In that case, if there are no other sessions open to that cache, it is cleared and re-created. If there are existing sessions, CreateShaderCacheSession returns `DXGI_ERROR_ALREADY_EXISTS`. |
| `Mode` | Determines what kind of cache to create/open. |
| `Flags` | Modifies behavior of the cache. |
| `MaximumInMemoryCacheSizeBytes` | For in-memory caches, this is the only storage available. For disk caches, all entries that are stored or found are temporarily stored in memory, until evicted by newer entries. This value determines the size of that temporary storage. Defaults to 1KB |
| `MaximumInMemoryCacheEntries` | Controls how many entries can be stored in memory. Defaults to 128 |
| `MaximumValueFileSizeBytes` | For disk caches, controls the maximum file size. Defaults to 128MB. |
| `Version` | This can be used to implicitly clear caches when an application or component update is done. If the version does not match the version stored in the cache, it will be wiped and re-created. |

### ID3D12ShaderCacheSession

| Method | Description |
|--------|-------------|
| `FindValue` | Looks up an entry in the cache whose key exactly matches the provided key. Intended usage is to call twice, the first time to figure out the size, and the second to retrieve the data. This is fast due to the in-memory temporary storage. If there is an entry with the same hash as the provided key, but the key does not exactly match, returns `DXGI_ERROR_CACHE_HASH_COLLISION`. If the entry is not present, returns `DXGI_ERROR_NOT_FOUND`. |
| `StoreValue` | Adds an entry to the cache. If there is an entry with the same key, returns `DXGI_ERROR_ALREADY_EXISTS`. If there an entry with the same hash as the provided key, but the key does not match, returns `DXGI_ERROR_CACHE_HASH_COLLISION`. If adding this entry would cause the cache to become larger than its maximum size, returns `DXGI_ERROR_CACHE_FULL`. |
| `SetDeleteOnDestroy` | When all cache session objects corresponding to a given cache are destroyed, the cache is cleared. |
| `GetDesc` | Returns the description used to create the cache session. |

### D3D12_SHADER_CACHE_KIND_FLAGS

| Value | Meaning |
|-------|---------|
| `D3D12_SHADER_CACHE_KIND_FLAG_IMPLICIT_D3D_CACHE_FOR_DRIVER` | Refers to the cache which is managed by D3D12 to store driver compilations of application shaders. |
| `D3D12_SHADER_CACHE_KIND_FLAG_IMPLICIT_D3D_CONVERSIONS` | Refers to the cache which is used to store D3D12's conversions of one shader type to another (e.g. DXBC shaders to DXIL shaders). |
| `D3D12_SHADER_CACHE_KIND_FLAG_IMPLICIT_DRIVER_MANAGED` | Refers to the cache which is managed by the driver. Operations for this cache are hints. |
| `D3D12_SHADER_CACHE_KIND_FLAG_APPLICATION_MANAGED` | Refers to all shader cache sessions created by the `CreateShaderCacheSession` API. Requests to `CLEAR` with this flag will apply to all currently-active application cache sessions, as well as on-disk caches created without `D3D12_SHADER_CACHE_FLAG_USE_WORKING_DIR`. |

Any one of these caches may or may not exist.

### D3D12_SHADER_CACHE_CONTROL_FLAGS

| Value | Meaning |
|-------|---------|
| `D3D12_SHADER_CACHE_CONTROL_FLAG_DISABLE` | The cache should not be used to look up data, and should not have new data stored in it. Attempts to use/create a cache while disabled will return `DXGI_ERROR_NOT_CURRENTLY_AVAILABLE`. |
| `D3D12_SHADER_CACHE_CONTROL_FLAG_ENABLE` | Resumes use of the cache. |
| `D3D12_SHADER_CACHE_CONTROL_FLAG_CLEAR` | Any existing contents of the cache should be deleted. |

The app cannot pass both DISABLE and ENABLE at the same time, and must pass at least one flag.

### ID3D12Device9 cache methods

| Method | Description |
|--------|-------------|
| `CreateShaderCacheSession` | Creates an object which grants access to a shader cache, potentially opening an existing cache or creating a new one. |
| `ShaderCacheControl` | Modifies behavior of caches used internally by D3D or the driver. This API may only be used in developer mode. |

## Driver changes

The only changes here will be to hook up the control API for `DRIVER_MANAGED` cache kinds to the driver. Additionally, it seems worth improving the existing `D3D12_SHADER_CACHE_SUPPORT_FLAGS` (queryable via `CheckFeatureSupport` for `D3D12_FEATURE_SHADER_CACHE`) to add a new flag indicating the presence of a driver cache:

```
enum D3D12_SHADER_CACHE_SUPPORT_FLAGS
{
    D3D12_SHADER_CACHE_SUPPORT_NONE                     = 0x0,
    D3D12_SHADER_CACHE_SUPPORT_SINGLE_PSO               = 0x1, // Always supported
    D3D12_SHADER_CACHE_SUPPORT_LIBRARY                  = 0x2,
    D3D12_SHADER_CACHE_SUPPORT_AUTOMATIC_INPROC_CACHE   = 0x4,
    D3D12_SHADER_CACHE_SUPPORT_AUTOMATIC_DISK_CACHE     = 0x8,
+   D3D12_SHADER_CACHE_SUPPORT_DRIVER_MANAGED_CACHE     = 0x10,
};
```

To that end, we're adding the following DDIs:

```
struct D3D12DDI_D3D12_OPTIONS_DATA_008n
{
    ...
    BOOL DriverManagedShaderCachePresent;
}
```

If the driver reports true for `DriverManagedShaderCachePresent`, then the driver should also provide a non-null function for:

```
enum D3D12DDI_IMPLICIT_SHADER_CACHE_CONTROL_FLAGS_008n
{
    D3D12DDI_IMPLICIT_SHADER_CACHE_CONTROL_FLAG_008n_DISABLE,
    D3D12DDI_IMPLICIT_SHADER_CACHE_CONTROL_FLAG_008n_ENABLE,
    D3D12DDI_IMPLICIT_SHADER_CACHE_CONTROL_FLAG_008n_CLEAR,
};

typedef HRESULT ( APIENTRY* PFND3D12DDI_IMPLICITSHADERCACHECONTROL_008n )( 
    D3D12DDI_HDEVICE, D3D12DDI_IMPLICIT_SHADER_CACHE_CONTROL_FLAGS_008n );

struct D3D12DDI_DEVICE_FUNCS_CORE_008n
{
    ...
    PFND3D12DDI_IMPLICITSHADERCACHECONTROL_008n     pfnImplicitShaderCacheControl;
};
```

The runtime will call `pfnImplicitShaderCacheControl` in response to application requests to `ID3D12Device9::ImplicitShaderCacheControl` for the `D3D12_IMPLICIT_SHADER_CACHE_KIND_FLAG_DRIVER_MANAGED` kind. As called out above, this API will only be supported in developer mode.