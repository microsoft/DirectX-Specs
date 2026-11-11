# D3D12: Device-Wide Default Explicit PSDB

- [D3D12: Device-Wide Default Explicit PSDB](#d3d12-device-wide-default-explicit-psdb)
  - [Introduction](#introduction)
  - [API](#api)
    - [Interface: ID3D12Device17](#interface-id3d12device17)
      - [Method: SetDefaultPrecompiledShaderCacheSession](#method-setdefaultprecompiledshadercachesession)
  - [PSDB Selection](#psdb-selection)
    - [Pipeline State Creation](#pipeline-state-creation)
    - [State Object Creation and Growth](#state-object-creation-and-growth)
  - [Concurrent Creation and Default Changes](#concurrent-creation-and-default-changes)
  - [Lifetime](#lifetime)
  - [Interactions with Existing Caching](#interactions-with-existing-caching)
  - [Samples](#samples)
    - [Set and Clear the Device Default](#set-and-clear-the-device-default)
    - [Override the Device Default for One Pipeline State](#override-the-device-default-for-one-pipeline-state)

## Introduction

Advanced Shader Delivery provides an implicit default Precompiled Shader Database (PSDB) through D3D Shader Cache
Registration. The runtime uses the registered "default" component for PSDB lookups when creating Pipeline State
Objects (PSOs) and State Objects (SOs). If no suitable default PSDB is registered, the implicit default is absent.

Explicit PSDB subobjects allow an application to override this default for individual PSO or SO creation operations.
This feature adds a device-wide explicit default so that an application can select a PSDB without adding a PSDB
subobject to each creation description.

A non-null device-wide explicit default overrides the implicit default, including when the implicit default is
absent. Passing null clears the device-wide override and restores selection of the implicit default for subsequent
creation operations. A non-null per-object explicit PSDB continues to take precedence over either default.

Changing the device default does not change the PSDB selection of an operation already using the previous default.
In particular, shader creation and other work performed as part of one PSO or SO creation operation must not switch
PSDBs between cache lookups.

This feature changes PSDB selection only. It does not change local driver caching or require the driver to compile
an object again when an existing compiled object can be reused.

## API

### Interface: ID3D12Device17

Adds a method for setting the device-wide default explicit PSDB at the end of ID3D12Device17.
Existing methods are omitted from the declaration below.

```idl
interface ID3D12Device17
    : ID3D12Device16
{
    HRESULT SetDefaultPrecompiledShaderCacheSession(
        [annotation("_In_opt_")] ID3D12ShaderCacheSession1* pSession,
        D3D12_SHADER_CACHE_SESSION_SUBOBJECT_FLAGS Flags);
};
```

#### Method: SetDefaultPrecompiledShaderCacheSession

Sets or clears the default explicit PSDB for this device.

**Parameters**

*pSession*

The PSDB cache session to use as the device-wide explicit default. A non-null session must satisfy the same
requirements as a non-null pSession in D3D12_SHADER_CACHE_SESSION_SUBOBJECT_DESC used for existing explicit PSDB
subobjects. This method does not broaden the accepted cache-session types or relax their validation requirements.

Passing nullptr clears the explicit default. Subsequent creation operations that do not specify a non-null
per-object explicit PSDB select the implicit default provided by registration. If that implicit default is absent,
those operations have no selected PSDB.

*Flags*

Controls how long objects created using the device-wide explicit default retain the selected session. Uses the
existing D3D12_SHADER_CACHE_SESSION_SUBOBJECT_FLAGS:

| Value | Meaning |
|-------|---------|
| D3D12_SHADER_CACHE_SESSION_SUBOBJECT_FLAG_NONE | The created object retains the selected session for its lifetime. |
| D3D12_SHADER_CACHE_SESSION_SUBOBJECT_FLAG_CREATE_ONLY | The selected session is used only during creation. |

Flags must be NONE when pSession is nullptr. Unknown flag values are invalid.

**Return Value**

Returns S_OK when the default is successfully set or cleared.

A non-null session that does not satisfy the existing explicit PSDB requirements is invalid. Unsupported explicit
PSDB use, unknown flag values, and a null session with non-zero flags return E_INVALIDARG. If the method fails,
the previous device-wide default and its flags remain unchanged.

**Remarks**

The device initially has no explicit default.

The application should query ID3D12Device17 and check D3D12_FEATURE_EXPLICIT_PSDBS before setting a non-null default.
The existing explicit PSDB support and application identity requirements apply. This feature does not introduce
a separate driver capability requirement.

The device retains a reference to a successfully supplied non-null session. The application may release its own
reference after this method returns successfully.

Passing nullptr clears the device-wide explicit default. Subsequent creation operations without a non-null
per-object explicit PSDB use registration's implicit default, if present.

The default applies only to this device. It does not affect another device, even when both devices use the same
adapter or application identity.

Objects that use an explicit PSDB, including the device-wide default, retain the selected session according to
its flags, as described in [Lifetime](#lifetime).

## PSDB Selection

Each creation operation selects its effective PSDB before its first PSDB lookup. Selection follows this order:

| Creation description | Device-wide explicit default | Selected PSDB |
|----------------------|------------------------------|---------------|
| Non-null per-object explicit PSDB | Any | Per-object explicit PSDB |
| Omitted PSDB subobject, or null session with NONE flags | Non-null | Device-wide explicit default |
| Omitted PSDB subobject, or null session with NONE flags | Null | Registration's implicit default, if present |

A null session with D3D12_SHADER_CACHE_SESSION_SUBOBJECT_FLAG_NONE has the same selection behavior as an omitted
PSDB subobject. A null session with non-zero flags remains invalid.

The lifetime flags come from the selected explicit PSDB: a non-null per-object session uses its subobject flags,
while an operation selecting the device-wide explicit default uses that default's flags. A non-null per-object
session overrides both the device-wide default session and its flags.

Only the selected PSDB is searched for PSDB cache values. A miss or an unavailable cache in a per-object explicit
PSDB does not cause a lookup in the device-wide explicit default or the implicit default. A miss or an unavailable
cache in the device-wide explicit default does not cause a lookup in the implicit default.

If a creation operation selects no PSDB, it performs no PSDB lookups for the duration of that operation.

### Pipeline State Creation

The default applies to CreateGraphicsPipelineState, CreateComputePipelineState, and CreatePipelineState.

One selection applies to the entire creation operation, including all shader stages and other internal
objects created as part of that operation. All PSDB cache lookups attributable to the operation use that selection.
This includes separate queries for a cache value's size, its object code, and its compiler metadata.

The default also applies when a pipeline-library load creates a PSO, including creation through a cached PSO blob.
If a load returns an existing PSO, that object retains its original selection.

### State Object Creation and Growth

The default applies to CreateStateObject and AddToStateObject. One selection applies to all PSDB cache lookups
attributable to each operation, including any internal pipeline state or shader creation belonging to it.

AddToStateObject does not inherit the base state object's PSDB selection. The new generation selects its own
non-null explicit PSDB subobject, if supplied, or otherwise selects the device's effective default for that
operation. The base state object retains its original selection.

Previously created objects referenced by a creation description retain their existing PSDB. 

## Concurrent Creation and Default Changes

SetDefaultPrecompiledShaderCacheSession may be called concurrently with creation operations and with other calls
to SetDefaultPrecompiledShaderCacheSession.

Each successful setter call changes the device default session and its flags atomically with respect to PSDB
selection. Concurrent setter calls take effect in an order consistent with calls that do not overlap. A creation
operation overlapping a setter may select the session and flags from before or after that change, but does not
mix the two selections. This also applies when a setter changes only the flags for the same session.

A creation operation begun after a successful setter returns observes that change, unless another setter has
subsequently changed the default. An operation that has already selected a PSDB continues using that session
and its selected flags for the duration of creation.
These rules also apply to clearing the override with nullptr and to selecting an absent implicit default.

The setter is not a completion barrier for creation operations. It may return while operations using the previous
default remain in progress. Applications do not need to wait for those operations to finish before replacing or
clearing the default.

For example, if one thread creates a graphics PSO while another replaces default PSDB A with PSDB B, the creation
may select A or B. Once selected, that PSDB is used for all PSDB lookups belonging to the creation, including vertex
shader, pixel shader, and pipeline state lookups.

## Lifetime

The device retains its current non-null explicit default until the default is replaced, cleared, or the device
is destroyed, including when the default uses CREATE_ONLY. CREATE_ONLY controls retention by created objects,
not retention of the configured default by the device.

An operation retains its selected session while creation is in progress.

With D3D12_SHADER_CACHE_SESSION_SUBOBJECT_FLAG_NONE, an object created using the device-wide explicit default
retains that session for its lifetime, allowing later object-associated PSDB lookups to use the same selection.
Replacing or clearing the device default does not retarget that object.

With D3D12_SHADER_CACHE_SESSION_SUBOBJECT_FLAG_CREATE_ONLY, the object releases its reference to the selected
explicit session when creation finishes. Later object-associated PSDB lookups fall back to registration's
implicit default, if present, matching the existing per-object CREATE_ONLY behavior. They do not use the current
device-wide explicit default. If no implicit default is present, those lookups have no PSDB to search.

Objects created while no PSDB was selected do not acquire a PSDB association when a device-wide default is
subsequently set.

Replacing or clearing the default releases the device's reference to the previous explicit default, but does not
release references held by in-flight operations or existing objects. Consequently, a successful setter call
does not guarantee that the previous PSDB session has been destroyed or its backing files have been closed.

The existing per-object D3D12_SHADER_CACHE_SESSION_SUBOBJECT_FLAGS and their behavior remain unchanged.

## Interactions with Existing Caching

Local driver caching, local compilation on a cache miss, and storage of locally compiled values remain unchanged.
Selecting an explicit default does not redirect local cache stores into the selected PSDB.

Existing ShaderCacheControl behavior applies to the selected session. Disabling PSDB lookups does not clear the
device-wide default or change an object's selected PSDB. The existing CLEAR behavior for PSDB caches is unchanged.

The runtime or driver may reuse previously created shaders, pipeline states, or other compiled objects. Changing
the default does not require those objects to be recreated, invalidate their compiled code, or guarantee a new
PSDB lookup. Reused objects retain their existing associations; any new PSDB lookups belonging to a creation
operation use that operation's selection.

This feature does not change shader-cache callback capabilities or add new forms of shader-object association.

## Samples

### Set and Clear the Device Default

This sample assumes application identity was set before device creation, explicit PSDB support was checked, and
pSessionA and pSessionB are sessions valid for existing explicit PSDB subobjects. The pipeline description contains
no PSDB subobject.

```c++
HRESULT CreateWithDeviceDefaults(
    ID3D12Device17* pDevice,
    ID3D12ShaderCacheSession1* pSessionA,
    ID3D12ShaderCacheSession1* pSessionB,
    const D3D12_COMPUTE_PIPELINE_STATE_DESC* pDesc)
{
    HRESULT hr = pDevice->SetDefaultPrecompiledShaderCacheSession(
        pSessionA, D3D12_SHADER_CACHE_SESSION_SUBOBJECT_FLAG_NONE);
    if (FAILED(hr))
    {
        return hr;
    }

    Microsoft::WRL::ComPtr<ID3D12PipelineState> psoA;
    hr = pDevice->CreateComputePipelineState(pDesc, IID_PPV_ARGS(&psoA));
    if (FAILED(hr))
    {
        return hr;
    }

    hr = pDevice->SetDefaultPrecompiledShaderCacheSession(
        pSessionB, D3D12_SHADER_CACHE_SESSION_SUBOBJECT_FLAG_CREATE_ONLY);
    if (FAILED(hr))
    {
        return hr;
    }

    Microsoft::WRL::ComPtr<ID3D12PipelineState> psoB;
    hr = pDevice->CreateComputePipelineState(pDesc, IID_PPV_ARGS(&psoB));
    if (FAILED(hr))
    {
        return hr;
    }

    hr = pDevice->SetDefaultPrecompiledShaderCacheSession(
        nullptr, D3D12_SHADER_CACHE_SESSION_SUBOBJECT_FLAG_NONE);
    if (FAILED(hr))
    {
        return hr;
    }

    Microsoft::WRL::ComPtr<ID3D12PipelineState> psoImplicit;
    return pDevice->CreateComputePipelineState(pDesc, IID_PPV_ARGS(&psoImplicit));
}
```

With no concurrent setter calls, psoA selects session A with NONE and retains it for its lifetime. psoB selects
session B with CREATE_ONLY and uses it only during creation. Later PSDB lookups for psoB use registration's
implicit default, if present.

Clearing the override before creating psoImplicit restores registration-based selection. If registration provides
no implicit default, psoImplicit is created without a selected PSDB. Replacing or clearing the device default
does not change psoA's retained session or psoB's post-creation fallback behavior.

### Override the Device Default for One Pipeline State

This sample assumes pDevice already has a device-wide explicit default. pObjectSession is a valid explicit PSDB
session, and pRootSignature and shader describe a valid compute pipeline.

```c++
struct ComputePipelineStream
{
    CD3DX12_PIPELINE_STATE_STREAM_ROOT_SIGNATURE RootSignature;
    CD3DX12_PIPELINE_STATE_STREAM_CS CS;
    CD3DX12_PIPELINE_STATE_STREAM_PSDB PSDB;
};

ComputePipelineStream desc;
desc.RootSignature = pRootSignature;
desc.CS = shader;
desc.PSDB = D3D12_SHADER_CACHE_SESSION_SUBOBJECT_DESC{
    pObjectSession, D3D12_SHADER_CACHE_SESSION_SUBOBJECT_FLAG_NONE
};

D3D12_PIPELINE_STATE_STREAM_DESC stream = { sizeof(desc), &desc };
Microsoft::WRL::ComPtr<ID3D12PipelineState> pso;
HRESULT hr = pDevice->CreatePipelineState(&stream, IID_PPV_ARGS(&pso));
```

The non-null per-object session takes precedence over the device-wide default. Replacing pObjectSession with
nullptr while keeping Flags set to NONE would instead select the device's effective default.
