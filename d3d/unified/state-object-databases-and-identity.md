<a id="state-object-databases-and-identity"></a>

# State object databases and application identity

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

<!-- d3d12-review-alert:begin:sodb-input:scope:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A state object database (SODB) stores pipeline state and state object creation
> inputs, including their shader bytecode. It is not a driver-compiled cache.

<!-- d3d12-review-alert:end:sodb-input:scope:0 -->

<a id="database-inputs"></a>

## Database inputs and reconstruction

The state object database describes a list of the State Objects and Pipeline State Objects used in the app. These inputs are used to create the precompiled cache and for the fallback scenario when the precompiled object is not found in the cache.

Supported creation/addition APIs:

- State object:
  - CreateStateObject
  - AddToStateObject
- Pipeline state object:
  - CreateGraphicsPipelineState
  - CreateComputePipelineState
  - CreatePipelineState

<ins><!-- d3d12-review-inline:begin:sodb-input:overview:3 -->The state object database stores creation inputs for the pipeline object types below. The following is stored for each pipeline object type:<!-- d3d12-review-inline:end:sodb-input:overview:3 --></ins>

| Pipeline object type | Notes |
|--------|-------|
|Raytracing and work graph|Serialize full state object desc including DXIL shaders|
|Graphics and compute programs|Serialize each program including DXIL shaders|
|Pipeline State Object|Serialize full pipeline state desc including DXIL shaders|

<!-- d3d12-review-alert:begin:sodb-input:creation-owners:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Storing a description does not create an API pipeline state object or state object
> and does not validate the stored input against driver-reported capabilities.
> The following creation and dependency contracts retain their canonical owners:

<!-- d3d12-review-alert:end:sodb-input:creation-owners:0 -->

<!-- d3d12-review-alert:begin:sodb-input:creation-owners:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Input being restored | Creation contract |
> | --- | --- |
> | Graphics, compute and stream PSOs | [Pipeline state creation](pipeline-state.md#id3d12device-creategraphicspipelinestate), [compute creation](pipeline-state.md#id3d12device-createcomputepipelinestate), and [pipeline state streams](pipeline-state.md#streams) |
> | State objects, collections and associations | [State object creation](state-objects.md#createstateobject) and [existing collections](state-objects.md#d3d12_existing_collection_desc) |
> | State object additions and growth parent | [AddToStateObject](state-objects.md#addtostateobject) |
> | Serialized root signature contents, creation and association | [Root signatures](binding.md#root-signatures), [serialization](binding.md#d3d12serializeversionedrootsignature), [root signature creation](binding.md#id3d12device-createrootsignature), and [state object root binding](state-objects.md#root-binding) |

<!-- d3d12-review-alert:end:sodb-input:creation-owners:1 -->

<!-- d3d12-review-alert:begin:sodb-input:creation-owners:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The bytecode and serialized root signature blobs remain opaque to this storage
> contract. Their presence does not establish support for a shader, state object
> configuration, driver capability, or workload at object creation time.
> The graphics/compute program row describes stored inputs within the
> [existing executable program contract](state-objects.md#createstateobject);
> it does not extend that contract to additional program forms.

<!-- d3d12-review-alert:end:sodb-input:creation-owners:2 -->

<a id="keys-and-versions"></a>

### Keys, object versions and dependency graphs

<ins><!-- d3d12-review-inline:begin:sodb-input:shared-key-contract:0 -->The key must be unique in the database for all objects regardless of object type
or version. It does not necessarily need to be derived from the pipeline state
desc. It can be some application specific scheme. Objects are versioned to allow
the contents of the desc to change without necessarily changing the key across
revised databases, not by overwriting an entry in the same database. For example,
this could enable modifying a shader without modifying the calling code that
references it by key. This version number is used to match with precompiled
binaries in a separate database. Only one version of an object may be stored in
the database.<!-- d3d12-review-inline:end:sodb-input:shared-key-contract:0 --></ins>

<!-- d3d12-review-alert:begin:sodb-input:identity-separation:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> An object key is an opaque byte sequence plus its byte count. It is not an
> application GUID, an executable filename, or the 64-bit application version.
> `Version` on the store methods, `Version` in the reconstruction callbacks, and
> `pVersion` on `FindObjectVersion` describe the same 32-bit object version domain.
> The database format version is separate again.

<!-- d3d12-review-alert:end:sodb-input:identity-separation:0 -->

<!-- d3d12-review-alert:begin:sodb-input:identity-separation:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Storing the same key, object version and description is idempotent and returns
> `S_OK`. Storing a different version, description or object kind under an
> existing key returns `DXGI_ERROR_ALREADY_EXISTS`. There is no in-place overwrite.
> Description identity is the stored canonical input identity, not equality of
> transient CPU pointer values or a requirement for bit-identical input buffers.
> The existing entry remains unchanged on this conflict. This is not a guarantee
> of whole-database atomicity for every allocation, operating-system or storage
> failure.

<!-- d3d12-review-alert:end:sodb-input:identity-separation:1 -->

<!-- d3d12-review-alert:begin:sodb-input:identity-separation:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The application must supply a nonnull `pKey` and a nonzero `KeySize` to
> `StorePipelineStateDesc`, `FindPipelineStateDesc`, `StoreStateObjectDesc`,
> `FindStateObjectDesc` and `FindObjectVersion`. The same requirement applies to
> the key in `D3D12_EXISTING_COLLECTION_BY_KEY_DESC`. Null or zero-size object keys
> are invalid and do not request enumeration. Key bytes must be readable for the
> specified count during the call.

<!-- d3d12-review-alert:end:sodb-input:identity-separation:2 -->

<!-- d3d12-review-alert:begin:sodb-input:identity-separation:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A stored state object addition is a graph node: its description contains the
> additions and its parent key identifies the already stored base. Existing
> collections referenced by key are other dependencies, with their export
> selection retained. Reconstructing only the addition's subobject array is not
> equivalent to reconstructing the resulting grown object. The optional no-parent
> case is separate from object key validity: pass `nullptr` with size zero for
> `pStateObjectToGrowFromKey` when there is no parent. Otherwise supply a nonnull,
> nonempty key identifying the already stored parent.

<!-- d3d12-review-alert:end:sodb-input:identity-separation:3 -->

<a id="published-database-format"></a>

### Published database format

<!-- d3d12-review-alert:begin:sodb-input:format-forward:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The complete [published SQLite format](state-object-database-format.md)
> defines the schema, object groups, dependency relationships and application
> metadata row. Its format version is not an object or application version.

<!-- d3d12-review-alert:end:sodb-input:format-forward:0 -->

<a id="application-metadata"></a>

## Application metadata and identity

<a id="d3d12_version_number"></a>

### D3D12_VERSION_NUMBER

```cpp
typedef union D3D12_VERSION_NUMBER
{
    UINT64 Version;
    UINT16 VersionParts[4];
} D3D12_VERSION_NUMBER;
```

<ins><!-- d3d12-review-inline:begin:sodb-input:version-purpose:0 -->`D3D12_VERSION_NUMBER` describes a version number. It is used to describe the version of the compiler, application profiles, application versions, and engine versions.<!-- d3d12-review-inline:end:sodb-input:version-purpose:0 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:version-meaning:0 -->`Version`<!-- d3d12-review-inline:end:sodb-input:version-meaning:0 --></ins>

A 64 bit encoding of four 16bit values to define a four part version as X.X.X.X.  The most significant 16bits are the first number, the next most significant bits are the second, etc.

<ins><!-- d3d12-review-inline:begin:sodb-input:version-meaning:2 -->`VersionParts`<!-- d3d12-review-inline:end:sodb-input:version-meaning:2 --></ins>

A 16 bit array representation of the version number.

<!-- d3d12-review-alert:begin:sodb-input:version-abi-order:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `VersionParts` overlays `Version`. It is not a separate most-significant-part
> array. On the Windows little-endian ABI, `VersionParts[0]` is the least
> significant 16 bits (revision), `[1]` is build, `[2]` is minor and `[3]` is
> major. Thus version 1.93.1.0 has `Version == 0x0001005D00010000` and array
> elements `{0, 1, 93, 1}`. Version 4.3.0.0 has
> `Version == 0x0004000300000000` and elements `{0, 0, 3, 4}`.
> Each component is a `UINT16`; shifting and combining four parts must be done
> in a 64-bit unsigned value.

<!-- d3d12-review-alert:end:sodb-input:version-abi-order:0 -->

<!-- d3d12-review-alert:begin:sodb-input:version-abi-order:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [shader cache ABI query](devices-and-capabilities.md#d3d12_feature_data_shadercache_abi_support)
> uses this same type for compiler and application profile versions. That query's
> inclusive minimum/maximum ABI range is not an application version or an object
> version.

<!-- d3d12-review-alert:end:sodb-input:version-abi-order:1 -->

<!-- d3d12-review-alert:begin:sodb-input:D126-compiler-version-forward:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The offline compiler uses this same encoding for its [adapter family compiler and application profile versions](offline-compilation.md#version-domains). Its [target ABI](offline-compilation.md#d3d12_compiler_target) and negotiated plugin/usermode DDI versions retain their separate meanings.

<!-- d3d12-review-alert:end:sodb-input:D126-compiler-version-forward:0 -->

<a id="d3d12_application_desc"></a>

### D3D12_APPLICATION_DESC

```cpp
typedef struct D3D12_APPLICATION_DESC
{
    LPCWSTR pExeFilename;
    LPCWSTR pName;
    D3D12_VERSION_NUMBER Version;
    LPCWSTR pEngineName;
    D3D12_VERSION_NUMBER EngineVersion;
} D3D12_APPLICATION_DESC;
```

Metadata to identify an application.  Information may be used to select an application specific compiler profile when compiling.

<!-- d3d12-review-alert:begin:sodb-input:metadata-members:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Member | Meaning and owning-API conditions |
> | --- | --- |
> | `pExeFilename` | Main application executable name including its extension, for example `Code.exe`. Database `SetApplicationDesc` requires a nonnull, nonempty, null-terminated filename. `SetApplicationIdentity` permits a null pointer and supplies the executable filename as described below. |
> | `pName` | Application title, for example `Microsoft Visual Studio Code`. Both APIs require a nonnull, nonempty, null-terminated application name when supplying a description. |
> | `Version` | Required 64-bit application version, represented by `D3D12_VERSION_NUMBER`; for example 1.93.1.0 is `0x0001005D00010000`. |
> | `pEngineName` | Optional null-terminated engine name. Use `nullptr` when not applicable. |
> | `EngineVersion` | Engine version. `SetApplicationDesc` requires an engine version when `pEngineName` is nonnull. `SetApplicationIdentity` requires zero when `pEngineName` is null. |

<!-- d3d12-review-alert:end:sodb-input:metadata-members:0 -->

<!-- d3d12-review-alert:begin:sodb-input:metadata-members:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Nullability of `pExeFilename` is API-specific. The identity API's executable
> filename fallback does not supply missing database metadata.

<!-- d3d12-review-alert:end:sodb-input:metadata-members:1 -->

<!-- d3d12-review-alert:begin:sodb-input:D131-cache-metadata-forward:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> [Compiler cache session creation](compiler-invocation-and-cache-output.md#id3d12compilerfactory-createcompilercachesession) defines supplied versus stored application metadata, target resolution and consistency across PSDB files. [GetApplicationDesc](compiler-invocation-and-cache-output.md#id3d12compilercachesession-getapplicationdesc) defines the resolved descriptor's borrowed lifetime. These consumers retain their API-specific input conditions.

<!-- d3d12-review-alert:end:sodb-input:D131-cache-metadata-forward:0 -->

<!-- d3d12-review-alert:begin:sodb-input:D138-registration-metadata:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The separate registration [D3D_SHADER_CACHE_APPLICATION_DESC and D3D_VERSION_NUMBER](shader-cache-registration.md#registration-abi) retain their own ABI declarations. [RegisterApplication](shader-cache-registration.md#id3dshadercacheinstaller-registerapplication) distinguishes its full executable lookup path from the stable identifying filename in its metadata. Those catalog inputs are not this chapter's version-4 configuration `AppId`.

<!-- d3d12-review-alert:end:sodb-input:D138-registration-metadata:0 -->

<!-- d3d12-review-alert:begin:sodb-input:D126-compiler-profile-metadata-forward:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> [ID3D12CompilerFactory::GetApplicationProfileVersion](offline-compilation.md#id3d12compilerfactory-getapplicationprofileversion) also consumes this description. Its parameters define the explicit executable/title and engine metadata for an offline profile query. The identity method's process name fallback does not apply to that query.

<!-- d3d12-review-alert:end:sodb-input:D126-compiler-profile-metadata-forward:0 -->

<ins><!-- d3d12-review-inline:begin:sodb-input:metadata-exe-context:0 -->The member `pExeFilename` is used to help uniquely identify an application, but SODBs and PSDBs generated with this value may be used from other executables within the same application. For usermode drivers and the D3D12 runtime, this value is not guaranteed to match the host executable.<!-- d3d12-review-inline:end:sodb-input:metadata-exe-context:0 --></ins>

An application may have multiple SODBs, but the application information must be identical between them.

<!-- d3d12-review-alert:begin:sodb-input:app-guid-separation:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `AppId` on `SetApplicationIdentity` is a version-4 application UUID. It is not
> derived here from executable names, title strings, engine names, object keys
> or version fields. Identity metadata is not an authentication or permissions
> mechanism. `SetApplicationDesc` stores the application description, not an
> `AppId` argument. The published [format](state-object-database-format.md#published-sql-schema)
> has no application-GUID column.

<!-- d3d12-review-alert:end:sodb-input:app-guid-separation:0 -->

<a id="storage-only-forms"></a>

## Driver-independent description forms

<!-- d3d12-review-alert:begin:sodb-input:substitution-context:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Live `ID3D12RootSignature` and `ID3D12StateObject` pointers are not portable
> serialized data. Storage uses the following driver-independent forms; finding
> descriptions can return these forms again. A returned form is not implicitly
> converted to a live object. Acceptance is specific to the consuming API:
> the existing-collection-by-key form below is database-only, while the
> serialized root forms must not be treated as universally database-only.

<!-- d3d12-review-alert:end:sodb-input:substitution-context:0 -->

<!-- d3d12-review-alert:begin:sodb-input:root-signature-versioned-input:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The storage substitutions below define the portable representation. The released
> 1.619.1 database setters also accept root signature API objects. The 1.619.3
> correction obtains the serialized container through
> `ID3D12RootSignature1::GetSerializedData`. This convenience does not serialize
> the COM pointer itself. Serialized input remains the explicit driver-independent
> form. It does not similarly make an existing-collection key a legal input to
> device or compiler state object creation.

<!-- d3d12-review-alert:end:sodb-input:root-signature-versioned-input:0 -->

<a id="d3d12_serialized_root_signature_desc"></a>

### D3D12_SERIALIZED_ROOT_SIGNATURE_DESC

```cpp
typedef struct D3D12_SERIALIZED_ROOT_SIGNATURE_DESC
{
    const void* pSerializedBlob;
    SIZE_T SerializedBlobSizeInBytes;
} D3D12_SERIALIZED_ROOT_SIGNATURE_DESC;
```

<a id="d3d12_global_serialized_root_signature"></a>

### D3D12_GLOBAL_SERIALIZED_ROOT_SIGNATURE

```cpp
typedef struct D3D12_GLOBAL_SERIALIZED_ROOT_SIGNATURE
{
    D3D12_SERIALIZED_ROOT_SIGNATURE_DESC Desc;
} D3D12_GLOBAL_SERIALIZED_ROOT_SIGNATURE;
```

<a id="d3d12_local_serialized_root_signature"></a>

### D3D12_LOCAL_SERIALIZED_ROOT_SIGNATURE

```cpp
typedef struct D3D12_LOCAL_SERIALIZED_ROOT_SIGNATURE
{
    D3D12_SERIALIZED_ROOT_SIGNATURE_DESC Desc;
} D3D12_LOCAL_SERIALIZED_ROOT_SIGNATURE;
```

<a id="d3d12_existing_collection_by_key_desc"></a>

### D3D12_EXISTING_COLLECTION_BY_KEY_DESC

```cpp
typedef struct D3D12_EXISTING_COLLECTION_BY_KEY_DESC
{
    const void* pKey;
    UINT KeySize;
    UINT NumExports; // Optional, if 0 all exports in the library/collection will be surfaced
    const D3D12_EXPORT_DESC* pExports;
} D3D12_EXISTING_COLLECTION_BY_KEY_DESC;
```

<!-- d3d12-review-alert:begin:sodb-input:serialized-root-members:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12_SERIALIZED_ROOT_SIGNATURE_DESC::pSerializedBlob` points to
> `SerializedBlobSizeInBytes` bytes. Each global/local wrapper contains that
> description in `Desc`. The root signature binary format and root signature
> creation/association semantics remain at the linked Binding and State objects
> owners.

<!-- d3d12-review-alert:end:sodb-input:serialized-root-members:0 -->

<!-- d3d12-review-alert:begin:sodb-input:serialized-root-members:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Storage location | Tag | Payload |
> | --- | --- | --- |
> | Pipeline state stream | `D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_SERIALIZED_ROOT_SIGNATURE = 29` | `D3D12_SERIALIZED_ROOT_SIGNATURE_DESC` |
> | State object global root signature | `D3D12_STATE_SUBOBJECT_TYPE_GLOBAL_SERIALIZED_ROOT_SIGNATURE = 31` | `D3D12_GLOBAL_SERIALIZED_ROOT_SIGNATURE` |
> | State object local root signature | `D3D12_STATE_SUBOBJECT_TYPE_LOCAL_SERIALIZED_ROOT_SIGNATURE = 32` | `D3D12_LOCAL_SERIALIZED_ROOT_SIGNATURE` |
> | State object existing collection | `D3D12_STATE_SUBOBJECT_TYPE_EXISTING_COLLECTION_BY_KEY = 36` | `D3D12_EXISTING_COLLECTION_BY_KEY_DESC` |

<!-- d3d12-review-alert:end:sodb-input:serialized-root-members:1 -->

<!-- d3d12-review-alert:begin:sodb-input:serialized-root-members:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Stream records retain the [pipeline stream layout and alignment](pipeline-state.md#streams).
> State object records retain the `D3D12_STATE_SUBOBJECT` type/payload layout and
> [subobject associations](state-objects.md#createstateobject). The table lists
> selected storage tags, not a replacement definition of either entire enum.

<!-- d3d12-review-alert:end:sodb-input:serialized-root-members:2 -->

<!-- d3d12-review-alert:begin:sodb-input:D126-compiler-root-helper-forward:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The compiler host [D3D12CompilerSerializeVersionedRootSignature](offline-compilation.md#d3d12compilerserializeversionedrootsignature) defines root signature blob production for offline inputs. Root signature contents and actual creation remain at the Binding owner linked above.

<!-- d3d12-review-alert:end:sodb-input:D126-compiler-root-helper-forward:0 -->

<ins><!-- d3d12-review-inline:begin:sodb-input:existing-members:0 -->`pKey` (`const void*`, input field)<!-- d3d12-review-inline:end:sodb-input:existing-members:0 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:existing-members:1 -->A nonnull pointer to a unique sequence of bytes that identifies an already
stored collection in the database.<!-- d3d12-review-inline:end:sodb-input:existing-members:1 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:existing-members:2 -->`KeySize` (`UINT`, input field)<!-- d3d12-review-inline:end:sodb-input:existing-members:2 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:existing-members:3 -->The nonzero size in bytes of `pKey`. Null or zero-size keys are invalid and
do not enumerate objects.<!-- d3d12-review-inline:end:sodb-input:existing-members:3 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:existing-members:4 -->`NumExports` (`UINT`, input field)<!-- d3d12-review-inline:end:sodb-input:existing-members:4 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:existing-members:5 -->Size of the `pExports` array. If 0, all of the collection's exports get exported.<!-- d3d12-review-inline:end:sodb-input:existing-members:5 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:existing-members:6 -->`pExports` (`const D3D12_EXPORT_DESC*`, optional input field)<!-- d3d12-review-inline:end:sodb-input:existing-members:6 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:existing-members:7 -->Optional exports array. When `NumExports` is nonzero, it must identify that many
readable export descriptions for the duration of the store call.<!-- d3d12-review-inline:end:sodb-input:existing-members:7 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:existing-applicability:0 -->`D3D12_STATE_SUBOBJECT_TYPE_EXISTING_COLLECTION_BY_KEY` is defined so that `D3D12_STATE_OBJECT_DESC` can refer to existing collections by key rather than by driver-dependent `ID3D12StateObject` pointers.  This is used for storing `D3D12_STATE_OBJECT_DESC` in an SODB, but cannot be used with API that create API state objects such as `ID3D12Device5::CreateStateObject` or `ID3D12Compiler::CompileStateObject`.<!-- d3d12-review-inline:end:sodb-input:existing-applicability:0 --></ins>

<a id="restoring-stored-input-graphs"></a>

## Restoring stored input graphs

<!-- d3d12-review-alert:begin:sodb-input:restore-graph:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> To restore a stored input graph for actual object creation:

<!-- d3d12-review-alert:end:sodb-input:restore-graph:0 -->

1. <ins><!-- d3d12-review-inline:begin:sodb-input:restore-graph:1 -->Find the requested description by its application-selected key. Preserve the<!-- d3d12-review-inline:end:sodb-input:restore-graph:1 --></ins>
   returned object version in the caller's bookkeeping.
2. <ins><!-- d3d12-review-inline:begin:sodb-input:restore-graph:1 -->For a PSO stream, when the consuming creation API requires root signature<!-- d3d12-review-inline:end:sodb-input:restore-graph:1 --></ins>
   API objects, construct them from serialized blobs and substitute ordinary
   root signature stream records.
3. <ins><!-- d3d12-review-inline:begin:sodb-input:restore-graph:1 -->For a state object, restore each referenced existing collection before<!-- d3d12-review-inline:end:sodb-input:restore-graph:1 --></ins>
   replacing its key descriptor with an ordinary existing-collection descriptor.
   Retain `NumExports` and `pExports` semantics. Convert serialized global and
   local root signatures to ordinary root signature subobjects when the
   consuming creation API requires that form.
4. <ins><!-- d3d12-review-inline:begin:sodb-input:restore-graph:1 -->Repair pointers in association records to the reconstructed subobjects.<!-- d3d12-review-inline:end:sodb-input:restore-graph:1 --></ins>
   For an addition, restore its parent graph first and use the resulting parent
   API object with `AddToStateObject`. Otherwise use `CreateStateObject`.
5. <ins><!-- d3d12-review-inline:begin:sodb-input:restore-graph:1 -->Keep all caller-created buffers and referenced API objects alive for their<!-- d3d12-review-inline:end:sodb-input:restore-graph:1 --></ins>
   creation calls under the owning creation contracts. Borrowed reconstruction buffers
   cannot be retained after the callback returns; deep-copy a description and
   its reachable data if creation is deferred.

<!-- d3d12-review-alert:begin:sodb-input:restore-graph:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Creation can occur during a reconstruction callback after these substitutions.
> A successful database lookup is not successful device creation; creation has
> its own `HRESULT`, validation and capability requirements. Failure in a
> `void` callback has no callback return value through which to report that
> creation failure: record it in caller-owned context and check it separately
> from the lookup result. No database callback rule here prohibits all D3D calls.

<!-- d3d12-review-alert:end:sodb-input:restore-graph:2 -->

<!-- d3d12-review-alert:begin:sodb-input:D131-compiler-reconstruction-forward:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> For offline compilation, the [compiler input and ownership contract](compiler-invocation-and-cache-output.md#input-ownership) defines serialized roots, live compiler collections and live addition parents after restoring database key dependencies. [Compiler output groups](compiler-invocation-and-cache-output.md#id3d12compilercachesession-storegroupvaluekeys) have their own mapping/version rules. An SODB object mapping is not a PSDB group or compiled value.

<!-- d3d12-review-alert:end:sodb-input:D131-compiler-reconstruction-forward:0 -->

<a id="reconstruction-callbacks"></a>

## Reconstruction callbacks

<a id="d3d12applicationdescfunc"></a>

### D3D12ApplicationDescFunc

A callback to read an application desc from a State Object Database.

```cpp
typedef void(__stdcall* D3D12ApplicationDescFunc) (
    const D3D12_APPLICATION_DESC* pApplicationDesc,
    void* pContext
    );
```

**Parameters**

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12ApplicationDescFunc:3 -->`pApplicationDesc` (`const D3D12_APPLICATION_DESC*`, input)<!-- d3d12-review-inline:end:sodb-input:callback-D3D12ApplicationDescFunc:3 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12ApplicationDescFunc:4 -->Describes the target application and version.  See [`D3D12_APPLICATION_DESC`](#d3d12_application_desc).<!-- d3d12-review-inline:end:sodb-input:callback-D3D12ApplicationDescFunc:4 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12ApplicationDescFunc:5 -->`pContext` (`void*`, optional input/output, caller-owned)<!-- d3d12-review-inline:end:sodb-input:callback-D3D12ApplicationDescFunc:5 --></ins>

An application specified context pointer that is passed to the callback.  Use this to pass parameters to the callback function.

**Remarks**

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12ApplicationDescFunc:8 -->Borrowed reconstruction data passed to this callback remains valid until the callback returns. Caller-owned key/context storage retains its own lifetime rules.  See [`ID3D12StateObjectDatabase::GetApplicationDesc`](#id3d12stateobjectdatabase-getapplicationdesc).<!-- d3d12-review-inline:end:sodb-input:callback-D3D12ApplicationDescFunc:8 --></ins>

<a id="d3d12pipelinestatefunc"></a>

### D3D12PipelineStateFunc

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12PipelineStateFunc:0 -->A callback to read a `D3D12_PIPELINE_STATE_STREAM_DESC` from a State Object Database.<!-- d3d12-review-inline:end:sodb-input:callback-D3D12PipelineStateFunc:0 --></ins>

```cpp
typedef void(__stdcall* D3D12PipelineStateFunc) (
    const void* pKey,
    UINT KeySize,
    UINT Version,
    const D3D12_PIPELINE_STATE_STREAM_DESC* pDesc,
    void* pContext
    );
```

**Parameters**

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12PipelineStateFunc:3 -->`pKey` (`const void*`, input)<!-- d3d12-review-inline:end:sodb-input:callback-D3D12PipelineStateFunc:3 --></ins>

A unique sequence of bytes that uniquely identifies an object in the database.

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12PipelineStateFunc:5 -->`KeySize` (`UINT`, input)<!-- d3d12-review-inline:end:sodb-input:callback-D3D12PipelineStateFunc:5 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12PipelineStateFunc:6 -->The size in bytes of `pKey`.<!-- d3d12-review-inline:end:sodb-input:callback-D3D12PipelineStateFunc:6 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12PipelineStateFunc:7 -->`Version` (`UINT`, input)<!-- d3d12-review-inline:end:sodb-input:callback-D3D12PipelineStateFunc:7 --></ins>

The version of the Pipeline State Object.  See Remarks.

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12PipelineStateFunc:9 -->`pDesc` (`const D3D12_PIPELINE_STATE_STREAM_DESC*`, input)<!-- d3d12-review-inline:end:sodb-input:callback-D3D12PipelineStateFunc:9 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12PipelineStateFunc:10 -->The `D3D12_PIPELINE_STATE_STREAM_DESC` desc that describes the PSO.  See Remarks.<!-- d3d12-review-inline:end:sodb-input:callback-D3D12PipelineStateFunc:10 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12PipelineStateFunc:11 -->`pContext` (`void*`, optional input/output, caller-owned)<!-- d3d12-review-inline:end:sodb-input:callback-D3D12PipelineStateFunc:11 --></ins>

An application specified context pointer that is passed to the callback.  Use this to pass parameters to the callback function.

**Remarks**

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12PipelineStateFunc:14 -->Borrowed reconstruction data passed to this callback remains valid until the callback returns. Caller-owned key/context storage retains its own lifetime rules.  See [`ID3D12StateObjectDatabase::FindPipelineStateDesc`](#id3d12stateobjectdatabase-findpipelinestatedesc).<!-- d3d12-review-inline:end:sodb-input:callback-D3D12PipelineStateFunc:14 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12PipelineStateFunc:15 -->Only one `Version` of a PSO may be stored in an SODB/PSDB at a time.  This value is present to allow an object to be versioned across revised databases without code changes for the lookup.<!-- d3d12-review-inline:end:sodb-input:callback-D3D12PipelineStateFunc:15 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12PipelineStateFunc:16 -->The `pDesc` parameter is not validated against any driver reported capabilities when stored.<!-- d3d12-review-inline:end:sodb-input:callback-D3D12PipelineStateFunc:16 --></ins>

<a id="d3d12stateobjectfunc"></a>

### D3D12StateObjectFunc

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12StateObjectFunc:0 -->A callback to read a `D3D12_STATE_OBJECT_DESC` and a state object parent key from a State Object Database.<!-- d3d12-review-inline:end:sodb-input:callback-D3D12StateObjectFunc:0 --></ins>

```cpp
typedef void(__stdcall* D3D12StateObjectFunc) (
    const void* pKey,
    UINT KeySize,
    UINT Version,
    const D3D12_STATE_OBJECT_DESC* pDesc,
    const void* pParentKey,
    UINT ParentKeySize,
    void* pContext
    );
```

**Parameters**

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12StateObjectFunc:3 -->`pKey` (`const void*`, input)<!-- d3d12-review-inline:end:sodb-input:callback-D3D12StateObjectFunc:3 --></ins>

A unique sequence of bytes that uniquely identifies an object in the database.

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12StateObjectFunc:5 -->`KeySize` (`UINT`, input)<!-- d3d12-review-inline:end:sodb-input:callback-D3D12StateObjectFunc:5 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12StateObjectFunc:6 -->The size in bytes of `pKey`.<!-- d3d12-review-inline:end:sodb-input:callback-D3D12StateObjectFunc:6 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12StateObjectFunc:7 -->`Version` (`UINT`, input)<!-- d3d12-review-inline:end:sodb-input:callback-D3D12StateObjectFunc:7 --></ins>

The version of the State Object.  See Remarks.

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12StateObjectFunc:9 -->`pDesc` (`const D3D12_STATE_OBJECT_DESC*`, input)<!-- d3d12-review-inline:end:sodb-input:callback-D3D12StateObjectFunc:9 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12StateObjectFunc:10 -->The `D3D12_STATE_OBJECT_DESC` that defines the state object.  See Remarks.<!-- d3d12-review-inline:end:sodb-input:callback-D3D12StateObjectFunc:10 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12StateObjectFunc:11 -->`pParentKey` (`const void*`, optional input)<!-- d3d12-review-inline:end:sodb-input:callback-D3D12StateObjectFunc:11 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12StateObjectFunc:12 -->A unique sequence of bytes that uniquely identifies the parent object in the database. For an ordinary creation description with no parent, `pParentKey` is null and `ParentKeySize` is zero.<!-- d3d12-review-inline:end:sodb-input:callback-D3D12StateObjectFunc:12 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12StateObjectFunc:13 -->`ParentKeySize` (`UINT`, input)<!-- d3d12-review-inline:end:sodb-input:callback-D3D12StateObjectFunc:13 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12StateObjectFunc:14 -->The size in bytes of `pParentKey`.<!-- d3d12-review-inline:end:sodb-input:callback-D3D12StateObjectFunc:14 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12StateObjectFunc:15 -->`pContext` (`void*`, optional input/output, caller-owned)<!-- d3d12-review-inline:end:sodb-input:callback-D3D12StateObjectFunc:15 --></ins>

An application specified context pointer that is passed to the callback.  Use this to pass parameters to the callback function.

**Remarks**

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12StateObjectFunc:18 -->Borrowed reconstruction data passed to this callback remains valid until the callback returns. Caller-owned key/context storage retains its own lifetime rules.  See [`ID3D12StateObjectDatabase::FindStateObjectDesc`](#id3d12stateobjectdatabase-findstateobjectdesc).<!-- d3d12-review-inline:end:sodb-input:callback-D3D12StateObjectFunc:18 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12StateObjectFunc:19 -->Only one `Version` of a State Object may be stored in an SODB/PSDB at a time.  This value is present to allow an object to be versioned across revised databases without code changes for the lookup.<!-- d3d12-review-inline:end:sodb-input:callback-D3D12StateObjectFunc:19 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:callback-D3D12StateObjectFunc:20 -->The `pDesc` parameter is not validated against any driver reported capabilities when stored.<!-- d3d12-review-inline:end:sodb-input:callback-D3D12StateObjectFunc:20 --></ins>

<!-- d3d12-review-alert:begin:sodb-input:callback-context:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The caller supplies the callback and optional `pContext`. The database passes
> that context through and does not take ownership of it. The callback and
> caller-owned key/context storage must remain valid until the calling method
> returns. A callback key can refer to the caller's original input key. Neither
> that key nor `pContext` becomes runtime-owned.

<!-- d3d12-review-alert:end:sodb-input:callback-context:0 -->

<!-- d3d12-review-alert:begin:sodb-input:callback-context:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Reconstruction and callback invocation are synchronous within the calling
> method. Reconstructed descriptions and all reachable borrowed data, including
> any returned parent key data, remain valid until the callback returns. Consume
> or copy them during that interval. The application must not free
> runtime-provided reconstruction buffers. Caller-owned COM references and
> caller-created copies retain their own ownership and lifetime rules.

<!-- d3d12-review-alert:end:sodb-input:callback-context:1 -->

<!-- d3d12-review-alert:begin:sodb-input:callback-context:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> These call lifetime guarantees do not establish a general cross-thread
> execution, same-database reentrancy or exception transport guarantee. They do not
> import a prohibition on D3D calls from unrelated debug message callbacks.

<!-- d3d12-review-alert:end:sodb-input:callback-context:2 -->

<a id="application-identity-configuration"></a>

## Application identity configuration

<a id="id3d12applicationidentity-setapplicationidentity"></a>

### ID3D12ApplicationIdentity::SetApplicationIdentity

#### Declaration

```cpp
HRESULT SetApplicationIdentity(const D3D12_APPLICATION_DESC* pDesc, REFGUID AppId);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:sodb-input:identity-behavior:0 -->Sets or resets application identity in the global or factory configuration from
which this interface was retrieved. The configured identity applies to subsequent
device creation in that configuration's scope.<!-- d3d12-review-inline:end:sodb-input:identity-behavior:0 --></ins>

<!-- d3d12-review-alert:begin:sodb-input:identity-scope:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Use `CLSID_D3D12ApplicationIdentity`
> (`08d8e1e8-75a6-42a7-bf3a-d05fe529c47c`) with
> [`D3D12GetInterface`](devices-and-capabilities.md#d3d12getinterface) for the
> global default identity used in subsequent device creation. Use
> [`ID3D12DeviceFactory::GetConfigurationInterface`](devices-and-capabilities.md#id3d12devicefactory-getconfigurationinterface)
> with the same class identifier for a factory's identity configuration.
> Both expose `ID3D12ApplicationIdentity`, derived from `IUnknown`.

<!-- d3d12-review-alert:end:sodb-input:identity-scope:0 -->

<!-- d3d12-review-alert:begin:sodb-input:identity-scope:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [factory snapshot rules](devices-and-capabilities.md#id3d12devicefactory-initializefromglobalstate)
> and [ApplyToGlobalState](devices-and-capabilities.md#id3d12devicefactory-applytoglobalstate)
> govern copying configuration between global and factory state. Changing the
> global identity does not mutate a previously taken factory snapshot. Changing
> configuration does not retroactively change identity already used for an
> existing device. Set the intended configuration before the corresponding
> device creation. The input strings and values are copied into configuration;
> the caller need not keep their buffers alive after the call returns.

<!-- d3d12-review-alert:end:sodb-input:identity-scope:1 -->

<!-- d3d12-review-alert:begin:sodb-input:D144-effective-identity:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> [Effective runtime identity](runtime-cache-discovery.md#effective-identity) defines the precedence of explicit configuration, registered metadata and available process filename fallback, and distinguishes initialization from reuse of an existing device. The [PSDB eligibility guard](runtime-cache-discovery.md#compatibility) is separate from setting this configuration or validating a stored SODB object.

<!-- d3d12-review-alert:end:sodb-input:D144-effective-identity:0 -->

#### Parameters

<ins><!-- d3d12-review-inline:begin:sodb-input:identity-parameters:0 -->`pDesc` (`const D3D12_APPLICATION_DESC*`, input)<!-- d3d12-review-inline:end:sodb-input:identity-parameters:0 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:identity-parameters:1 -->The application description to set. For a non-reset call this pointer and its
referenced strings must be valid and readable for the duration of the call.
The application must supply a nonempty application name. See
[`D3D12_APPLICATION_DESC`](#d3d12_application_desc) for filename fallback and
engine/version requirements. The configuration copies the input data.<!-- d3d12-review-inline:end:sodb-input:identity-parameters:1 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:identity-parameters:2 -->`AppId` (`REFGUID`, input)<!-- d3d12-review-inline:end:sodb-input:identity-parameters:2 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:identity-parameters:3 -->A version 4 universally unique identifier generated for the app that is
self-identifying. It must not be `GUID_NULL` when `pDesc` is nonnull.<!-- d3d12-review-inline:end:sodb-input:identity-parameters:3 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:identity-parameters:4 -->To reset the configured identity, pass null `pDesc` together with `GUID_NULL`.
The reset removes the configured identity from this global or factory
configuration for future device creation; it does not alter existing devices
or previously copied configuration snapshots. A null description with a nonnull
GUID, or a nonnull description with `GUID_NULL`, is an invalid pair.<!-- d3d12-review-inline:end:sodb-input:identity-parameters:4 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:identity-fallback:0 -->When `ID3D12ApplicationIdentity::SetApplicationIdentity` is called with a nonnull
description whose `D3D12_APPLICATION_DESC::pExeFilename` is null, the executable
filename is determined by calling `GetModuleFileName` with a NULL handle.<!-- d3d12-review-inline:end:sodb-input:identity-fallback:0 --></ins>

#### Return values

<!-- d3d12-review-alert:begin:sodb-input:identity-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Successful configuration, including reset, returns `S_OK`. A mismatched
> null description/`GUID_NULL` pair returns `E_INVALIDARG`; allocation failure can
> return `E_OUTOFMEMORY`. The nonempty application name requirement applies
> independently of implementation validation. No general rollback of configuration
> changes is guaranteed after an allocation failure.

<!-- d3d12-review-alert:end:sodb-input:identity-returns:0 -->

<a id="database-factory"></a>

## Database factory and files

<!-- d3d12-review-alert:begin:sodb-input:factory-retrieval:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `ID3D12StateObjectDatabaseFactory` and `ID3D12StateObjectDatabase` derive from
> `IUnknown`. Retrieve the factory with
> [`D3D12GetInterface`](devices-and-capabilities.md#d3d12getinterface), passing
> `CLSID_D3D12StateObjectFactory`
> (`54e1c9f3-1303-4112-bf8e-7bf2bb606a73`) and the
> `ID3D12StateObjectDatabaseFactory` interface identifier. The class identifier
> and the interface name differ. Include `initguid.h` before `d3d12.h` when
> instantiating this GUID in a translation unit.

<!-- d3d12-review-alert:end:sodb-input:factory-retrieval:0 -->

<a id="d3d12_state_object_database_flags"></a>

### D3D12_STATE_OBJECT_DATABASE_FLAGS

```cpp
typedef enum D3D12_STATE_OBJECT_DATABASE_FLAGS
{
    D3D12_STATE_OBJECT_DATABASE_FLAG_NONE = 0x0,
    D3D12_STATE_OBJECT_DATABASE_FLAG_READ_ONLY = 0x1,
} D3D12_STATE_OBJECT_DATABASE_FLAGS;
```

<!-- d3d12-review-alert:begin:sodb-input:file-mode-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12_STATE_OBJECT_DATABASE_FLAG_NONE` requests a writable database: create a
> new database file or open an existing valid database.
> `D3D12_STATE_OBJECT_DATABASE_FLAG_READ_ONLY` opens an existing valid database
> for reading. It must not create or update the database. Unsupported flag bits
> are invalid.

<!-- d3d12-review-alert:end:sodb-input:file-mode-contract:0 -->

<!-- d3d12-review-alert:begin:sodb-input:file-mode-contract:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Database COM lifetime owns the open database state; releasing the caller's
> factory reference does not invalidate a returned database. Callers retain
> ownership of the filename buffer and can release it after creation returns.
> `SetApplicationDesc`, `StorePipelineStateDesc` and `StoreStateObjectDesc` on a
> read-only database return `DXGI_ERROR_ACCESS_DENIED`.

<!-- d3d12-review-alert:end:sodb-input:file-mode-contract:1 -->

<!-- d3d12-review-alert:begin:sodb-input:file-mode-contract:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Opening can fail because a required existing file is missing, file access is
> denied, the database is corrupt or its format is unsupported, the flags are
> invalid, the requested interface is unsupported, or allocation fails. These
> conditions produce a failing `HRESULT`. They do not share a guaranteed single
> filesystem error mapping.

<!-- d3d12-review-alert:end:sodb-input:file-mode-contract:2 -->

<a id="id3d12stateobjectdatabasefactory-createstateobjectdatabasefromfile"></a>

### ID3D12StateObjectDatabaseFactory::CreateStateObjectDatabaseFromFile

#### Declaration

```cpp
HRESULT CreateStateObjectDatabaseFromFile( LPCWSTR pDatabaseFile, D3D12_STATE_OBJECT_DATABASE_FLAGS flags, REFIID riid, void** ppvStateObjectDatabase );
```

#### Behavior

<!-- d3d12-review-alert:begin:sodb-input:behavior-CreateStateObjectDatabaseFromFile:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Creates or opens a state object database file in the selected access mode.

<!-- d3d12-review-alert:end:sodb-input:behavior-CreateStateObjectDatabaseFromFile:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:sodb-input:parameters-CreateStateObjectDatabaseFromFile:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pDatabaseFile` (`LPCWSTR`, input)

<!-- d3d12-review-alert:end:sodb-input:parameters-CreateStateObjectDatabaseFromFile:0 -->

<!-- d3d12-review-alert:begin:sodb-input:parameters-CreateStateObjectDatabaseFromFile:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Required pointer to a valid null-terminated wide character database filename.
> The filename buffer must remain readable for the duration of the call.

<!-- d3d12-review-alert:end:sodb-input:parameters-CreateStateObjectDatabaseFromFile:1 -->

<!-- d3d12-review-alert:begin:sodb-input:parameters-CreateStateObjectDatabaseFromFile:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `flags` (`D3D12_STATE_OBJECT_DATABASE_FLAGS`, input)

<!-- d3d12-review-alert:end:sodb-input:parameters-CreateStateObjectDatabaseFromFile:2 -->

<!-- d3d12-review-alert:begin:sodb-input:parameters-CreateStateObjectDatabaseFromFile:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Selects the [file access mode](#d3d12_state_object_database_flags). A read-only
> open requires an existing valid database. It does not create one.

<!-- d3d12-review-alert:end:sodb-input:parameters-CreateStateObjectDatabaseFromFile:3 -->

<!-- d3d12-review-alert:begin:sodb-input:parameters-CreateStateObjectDatabaseFromFile:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `riid` (`REFIID`, input)

<!-- d3d12-review-alert:end:sodb-input:parameters-CreateStateObjectDatabaseFromFile:4 -->

<!-- d3d12-review-alert:begin:sodb-input:parameters-CreateStateObjectDatabaseFromFile:5 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Identifies the requested supported interface on the returned database.

<!-- d3d12-review-alert:end:sodb-input:parameters-CreateStateObjectDatabaseFromFile:5 -->

<!-- d3d12-review-alert:begin:sodb-input:parameters-CreateStateObjectDatabaseFromFile:6 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `ppvStateObjectDatabase` (`void**`, output)

<!-- d3d12-review-alert:end:sodb-input:parameters-CreateStateObjectDatabaseFromFile:6 -->

<!-- d3d12-review-alert:begin:sodb-input:parameters-CreateStateObjectDatabaseFromFile:7 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Required writable pointer to receive the requested COM interface. On success,
> the caller owns that interface reference and releases it under the usual COM
> rules. This is not an optional null output probing parameter.

<!-- d3d12-review-alert:end:sodb-input:parameters-CreateStateObjectDatabaseFromFile:7 -->

#### Return values

<!-- d3d12-review-alert:begin:sodb-input:returns-CreateStateObjectDatabaseFromFile:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Successful creation or opening returns `S_OK`. An unsupported requested
> interface returns `E_NOINTERFACE`. File, format, access, flag and allocation
> failures return a failing `HRESULT` as described in the
> [file contract](#d3d12_state_object_database_flags). Only a successful call
> conveys a usable returned database reference. No `S_FALSE` null output probe or
> universal failure-time output initialization is specified.

<!-- d3d12-review-alert:end:sodb-input:returns-CreateStateObjectDatabaseFromFile:0 -->

<a id="database-metadata-methods"></a>

## Database metadata methods

<a id="id3d12stateobjectdatabase-setapplicationdesc"></a>

### ID3D12StateObjectDatabase::SetApplicationDesc

#### Declaration

```cpp
HRESULT SetApplicationDesc( const D3D12_APPLICATION_DESC* pApplicationDesc);
```

#### Behavior

Set or update the Application Desc stored in the database.  This should be updated whenever the application version or engine version changes.

#### Parameters

<ins><!-- d3d12-review-inline:begin:sodb-input:SetApplicationDesc-parameters:0 -->`pApplicationDesc` (`const D3D12_APPLICATION_DESC*`, input)<!-- d3d12-review-inline:end:sodb-input:SetApplicationDesc-parameters:0 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:SetApplicationDesc-parameters:1 -->Required readable pointer to the application description to store in the
database. Its referenced strings must remain readable for the duration of the
call. See [`D3D12_APPLICATION_DESC`](#d3d12_application_desc) for the required
nonempty filename/application name and optional engine fields. This method
does not take an `AppId` argument.<!-- d3d12-review-inline:end:sodb-input:SetApplicationDesc-parameters:1 --></ins>

#### Return values

<!-- d3d12-review-alert:begin:sodb-input:returns-SetApplicationDesc:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Successful storage returns `S_OK`. The database copies the description's string
> and value data into storage; caller buffers need only remain valid during the
> call. Null `pApplicationDesc`, null/empty `pExeFilename`, or null/empty `pName`
> returns `E_INVALIDARG`. Read-only storage returns `DXGI_ERROR_ACCESS_DENIED`.

<!-- d3d12-review-alert:end:sodb-input:returns-SetApplicationDesc:0 -->

<a id="id3d12stateobjectdatabase-getapplicationdesc"></a>

### ID3D12StateObjectDatabase::GetApplicationDesc

#### Declaration

```cpp
HRESULT GetApplicationDesc( D3D12ApplicationDescFunc CallbackFunc, void* pContext);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:sodb-input:behavior-GetApplicationDesc:0 -->Retrieves the `D3D12_APPLICATION_DESC` from the database.<!-- d3d12-review-inline:end:sodb-input:behavior-GetApplicationDesc:0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:sodb-input:GetApplicationDesc-parameters:0 -->`CallbackFunc` (`D3D12ApplicationDescFunc`, input)<!-- d3d12-review-inline:end:sodb-input:GetApplicationDesc-parameters:0 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:GetApplicationDesc-parameters:1 -->Required nonnull callback function pointer that receives the stored application
description. The callback must remain callable until this method returns.<!-- d3d12-review-inline:end:sodb-input:GetApplicationDesc-parameters:1 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:GetApplicationDesc-parameters:2 -->`pContext` (`void*`, optional input/output)<!-- d3d12-review-inline:end:sodb-input:GetApplicationDesc-parameters:2 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:GetApplicationDesc-parameters:3 -->An application specified context pointer passed unchanged to the callback.
The caller retains ownership and must keep any context used by the callback
valid until this method returns.<!-- d3d12-review-inline:end:sodb-input:GetApplicationDesc-parameters:3 --></ins>

#### Remarks

<ins><!-- d3d12-review-inline:begin:sodb-input:GetApplicationDesc-remarks:0 -->If no application desc was previously stored, this function returns `DXGI_ERROR_NOT_FOUND`.<!-- d3d12-review-inline:end:sodb-input:GetApplicationDesc-remarks:0 --></ins>

#### Return values

<!-- d3d12-review-alert:begin:sodb-input:returns-GetApplicationDesc:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Successful retrieval returns `S_OK` after invoking `CallbackFunc` with the
> stored metadata and caller-supplied `pContext`. No stored metadata returns
> `DXGI_ERROR_NOT_FOUND`. A null callback returns `E_INVALIDARG`.

<!-- d3d12-review-alert:end:sodb-input:returns-GetApplicationDesc:0 -->

<a id="pipeline-input-methods"></a>

## Pipeline state input methods

<a id="id3d12stateobjectdatabase-storepipelinestatedesc"></a>

### ID3D12StateObjectDatabase::StorePipelineStateDesc

#### Declaration

```cpp
HRESULT StorePipelineStateDesc( const void* pKey, UINT KeySize, UINT Version, const D3D12_PIPELINE_STATE_STREAM_DESC* pDesc);
```

#### Behavior

Stores a Pipeline State Desc in the database by key.

#### Parameters

<ins><!-- d3d12-review-inline:begin:sodb-input:StorePipelineStateDesc-parameters:0 -->`pKey` (`const void*`, input)<!-- d3d12-review-inline:end:sodb-input:StorePipelineStateDesc-parameters:0 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:StorePipelineStateDesc-parameters:1 -->A required nonnull pointer to the object key bytes, readable for `KeySize` bytes during the call.<!-- d3d12-review-inline:end:sodb-input:StorePipelineStateDesc-parameters:1 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:StorePipelineStateDesc-parameters:2 -->`KeySize` (`UINT`, input)<!-- d3d12-review-inline:end:sodb-input:StorePipelineStateDesc-parameters:2 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:StorePipelineStateDesc-parameters:3 -->The nonzero size in bytes of `pKey`. Null or zero-size keys are invalid and do not enumerate objects.<!-- d3d12-review-inline:end:sodb-input:StorePipelineStateDesc-parameters:3 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:StorePipelineStateDesc-parameters:4 -->`Version` (`UINT`, input)<!-- d3d12-review-inline:end:sodb-input:StorePipelineStateDesc-parameters:4 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:StorePipelineStateDesc-parameters:5 -->The 32-bit version of the object being stored. The database author is expected to rev this version whenever the object description changes across revised databases. A different version cannot overwrite an entry in the same database; see the [key and version contract](#keys-and-versions).<!-- d3d12-review-inline:end:sodb-input:StorePipelineStateDesc-parameters:5 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:StorePipelineStateDesc-parameters:6 -->`pDesc` (`const D3D12_PIPELINE_STATE_STREAM_DESC*`, input)<!-- d3d12-review-inline:end:sodb-input:StorePipelineStateDesc-parameters:6 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:StorePipelineStateDesc-parameters:7 -->Required readable pointer to the pipeline state stream description. The description and all referenced bytecode, strings, arrays, subobjects and serialized data must remain valid for the duration of the call.<!-- d3d12-review-inline:end:sodb-input:StorePipelineStateDesc-parameters:7 --></ins>

#### Remarks

<ins><!-- d3d12-review-inline:begin:sodb-input:StorePipelineStateDesc-remarks:0 -->The [shared key and object version contract](#keys-and-versions) applies.<!-- d3d12-review-inline:end:sodb-input:StorePipelineStateDesc-remarks:0 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:StorePipelineStateDesc-remarks:1 -->For the explicit driver-independent storage form, substitute the following pipeline stream input:<!-- d3d12-review-inline:end:sodb-input:StorePipelineStateDesc-remarks:1 --></ins>

- <ins><!-- d3d12-review-inline:begin:sodb-input:StorePipelineStateDesc-remarks:2 -->Root signatures: `ID3D12RootSignature` pointers must be replaced by `D3D12_SERIALIZED_ROOT_SIGNATURE_DESC`<!-- d3d12-review-inline:end:sodb-input:StorePipelineStateDesc-remarks:2 --></ins>

These types do not have driver dependencies.

<ins><!-- d3d12-review-inline:begin:sodb-input:StorePipelineStateDesc-remarks:4 -->The [versioned root signature input support](#storage-only-forms) also applies.<!-- d3d12-review-inline:end:sodb-input:StorePipelineStateDesc-remarks:4 --></ins>

#### Return values

<!-- d3d12-review-alert:begin:sodb-input:store-pso-completion:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Successful storage, including an identical insertion under the same key/version,
> returns `S_OK`. A different object version, canonical input description or object
> kind under an existing key returns `DXGI_ERROR_ALREADY_EXISTS`, leaving the
> existing entry unchanged. Read-only storage returns `DXGI_ERROR_ACCESS_DENIED`.
> The stream and its referenced data are consumed during the call, not retained
> as caller pointers. Parsing/storage failures are reported by `HRESULT`;
> successful storage is not GPU or driver capability validation. The
> [key and version contract](#keys-and-versions) applies.

<!-- d3d12-review-alert:end:sodb-input:store-pso-completion:0 -->

<a id="id3d12stateobjectdatabase-findpipelinestatedesc"></a>

### ID3D12StateObjectDatabase::FindPipelineStateDesc

#### Declaration

```cpp
HRESULT FindPipelineStateDesc( const void* pKey, UINT KeySize, D3D12PipelineStateFunc CallbackFunc, void* pContext);
```

#### Behavior

<!-- d3d12-review-alert:begin:sodb-input:behavior-FindPipelineStateDesc:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Calls `CallbackFunc` with the reconstructed PSO input for the specified key.

<!-- d3d12-review-alert:end:sodb-input:behavior-FindPipelineStateDesc:0 -->

#### Parameters

<ins><!-- d3d12-review-inline:begin:sodb-input:FindPipelineStateDesc-parameters:0 -->`pKey` (`const void*`, input)<!-- d3d12-review-inline:end:sodb-input:FindPipelineStateDesc-parameters:0 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:FindPipelineStateDesc-parameters:1 -->A required nonnull pointer to the object key bytes, readable for `KeySize` bytes during the call.<!-- d3d12-review-inline:end:sodb-input:FindPipelineStateDesc-parameters:1 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:FindPipelineStateDesc-parameters:2 -->`KeySize` (`UINT`, input)<!-- d3d12-review-inline:end:sodb-input:FindPipelineStateDesc-parameters:2 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:FindPipelineStateDesc-parameters:3 -->The nonzero size in bytes of `pKey`. Null or zero-size keys are invalid and do not enumerate objects.<!-- d3d12-review-inline:end:sodb-input:FindPipelineStateDesc-parameters:3 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:FindPipelineStateDesc-parameters:4 -->`CallbackFunc` (`D3D12PipelineStateFunc`, input)<!-- d3d12-review-inline:end:sodb-input:FindPipelineStateDesc-parameters:4 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:FindPipelineStateDesc-parameters:5 -->Required nonnull callback function pointer that receives the reconstructed description, key and stored object version. It must remain callable until this method returns.<!-- d3d12-review-inline:end:sodb-input:FindPipelineStateDesc-parameters:5 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:FindPipelineStateDesc-parameters:6 -->`pContext` (`void*`, optional input/output)<!-- d3d12-review-inline:end:sodb-input:FindPipelineStateDesc-parameters:6 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:FindPipelineStateDesc-parameters:7 -->An application specified context pointer passed unchanged to the callback. The caller retains ownership and must keep any context used by the callback valid until this method returns.<!-- d3d12-review-inline:end:sodb-input:FindPipelineStateDesc-parameters:7 --></ins>

#### Remarks

<ins><!-- d3d12-review-inline:begin:sodb-input:FindPipelineStateDesc-remarks:0 -->`DXGI_ERROR_NOT_FOUND` is returned if an object with `pKey` is not found.<!-- d3d12-review-inline:end:sodb-input:FindPipelineStateDesc-remarks:0 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:FindPipelineStateDesc-remarks:1 -->This method returns a compatible desc to what was stored, but may not be a bit exact match.  For example, most structs in a pipeline stream have defaults implied by their absence.  These structs may be present in the find with their default values.<!-- d3d12-review-inline:end:sodb-input:FindPipelineStateDesc-remarks:1 --></ins>

#### Return values

<!-- d3d12-review-alert:begin:sodb-input:find-pso-completion:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The key must identify a PSO:
> the PSO finder does not reinterpret a state object entry as a pipeline stream.
> Successful retrieval returns `S_OK`. A missing PSO returns
> `DXGI_ERROR_NOT_FOUND`. The [callback storage rules](#reconstruction-callbacks)
> and [storage-form substitutions](#storage-only-forms) apply.

<!-- d3d12-review-alert:end:sodb-input:find-pso-completion:0 -->

<a id="state-object-input-methods"></a>

## State object input methods

<a id="id3d12stateobjectdatabase-storestateobjectdesc"></a>

### ID3D12StateObjectDatabase::StoreStateObjectDesc

#### Declaration

```cpp
HRESULT StoreStateObjectDesc( const void* pKey, UINT KeySize, UINT Version, const D3D12_STATE_OBJECT_DESC* pDesc, const void* pStateObjectToGrowFromKey, UINT StateObjectToGrowFromKeySize);
```

#### Behavior

Stores a State Object Desc in the database by key.

#### Parameters

<ins><!-- d3d12-review-inline:begin:sodb-input:StoreStateObjectDesc-parameters:0 -->`pKey` (`const void*`, input)<!-- d3d12-review-inline:end:sodb-input:StoreStateObjectDesc-parameters:0 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:StoreStateObjectDesc-parameters:1 -->A required nonnull pointer to the object key bytes, readable for `KeySize` bytes during the call.<!-- d3d12-review-inline:end:sodb-input:StoreStateObjectDesc-parameters:1 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:StoreStateObjectDesc-parameters:2 -->`KeySize` (`UINT`, input)<!-- d3d12-review-inline:end:sodb-input:StoreStateObjectDesc-parameters:2 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:StoreStateObjectDesc-parameters:3 -->The nonzero size in bytes of `pKey`. Null or zero-size keys are invalid and do not enumerate objects.<!-- d3d12-review-inline:end:sodb-input:StoreStateObjectDesc-parameters:3 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:StoreStateObjectDesc-parameters:4 -->`Version` (`UINT`, input)<!-- d3d12-review-inline:end:sodb-input:StoreStateObjectDesc-parameters:4 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:StoreStateObjectDesc-parameters:5 -->The 32-bit version of the object being stored. The database author is expected to rev this version whenever the object description changes across revised databases. A different version cannot overwrite an entry in the same database; see the [key and version contract](#keys-and-versions).<!-- d3d12-review-inline:end:sodb-input:StoreStateObjectDesc-parameters:5 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:StoreStateObjectDesc-parameters:6 -->`pDesc` (`const D3D12_STATE_OBJECT_DESC*`, input)<!-- d3d12-review-inline:end:sodb-input:StoreStateObjectDesc-parameters:6 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:StoreStateObjectDesc-parameters:7 -->Required readable pointer to the state object description or state object additions. The description and all referenced bytecode, strings, arrays, subobjects and serialized data must remain valid for the duration of the call.<!-- d3d12-review-inline:end:sodb-input:StoreStateObjectDesc-parameters:7 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:StoreStateObjectDesc-parameters:8 -->`pStateObjectToGrowFromKey` (`const void*`, optional input)<!-- d3d12-review-inline:end:sodb-input:StoreStateObjectDesc-parameters:8 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:StoreStateObjectDesc-parameters:9 -->A key identifying the already stored base state object to which this description adds. Pass `nullptr` with size zero when there is no base object. Otherwise the key must be nonnull, nonempty and readable for the specified size during the call.<!-- d3d12-review-inline:end:sodb-input:StoreStateObjectDesc-parameters:9 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:StoreStateObjectDesc-parameters:10 -->`StateObjectToGrowFromKeySize` (`UINT`, input)<!-- d3d12-review-inline:end:sodb-input:StoreStateObjectDesc-parameters:10 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:StoreStateObjectDesc-parameters:11 -->The size in bytes of `pStateObjectToGrowFromKey`; zero for the no-parent case.<!-- d3d12-review-inline:end:sodb-input:StoreStateObjectDesc-parameters:11 --></ins>

#### Remarks

<ins><!-- d3d12-review-inline:begin:sodb-input:StoreStateObjectDesc-remarks:0 -->The [shared key and object version contract](#keys-and-versions) applies.<!-- d3d12-review-inline:end:sodb-input:StoreStateObjectDesc-remarks:0 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:StoreStateObjectDesc-remarks:1 -->For the explicit driver-independent storage form, substitute the following state object inputs:<!-- d3d12-review-inline:end:sodb-input:StoreStateObjectDesc-remarks:1 --></ins>

- <ins><!-- d3d12-review-inline:begin:sodb-input:StoreStateObjectDesc-remarks:2 -->Root signatures: `ID3D12RootSignature` pointers must be replaced by `D3D12_SERIALIZED_ROOT_SIGNATURE_DESC`<!-- d3d12-review-inline:end:sodb-input:StoreStateObjectDesc-remarks:2 --></ins>
- <ins><!-- d3d12-review-inline:begin:sodb-input:StoreStateObjectDesc-remarks:2 -->Existing Collections: `ID3D12StateObject` pointers embedded in the desc must be replaced by `D3D12_EXISTING_COLLECTION_BY_KEY_DESC`.<!-- d3d12-review-inline:end:sodb-input:StoreStateObjectDesc-remarks:2 --></ins>
- <ins><!-- d3d12-review-inline:begin:sodb-input:StoreStateObjectDesc-remarks:2 -->Parents are referred to by key instead of by `ID3D12StateObject` pointer.<!-- d3d12-review-inline:end:sodb-input:StoreStateObjectDesc-remarks:2 --></ins>

These types do not have driver dependencies.

<ins><!-- d3d12-review-inline:begin:sodb-input:StoreStateObjectDesc-remarks:4 -->The [versioned root signature input support](#storage-only-forms) also applies.<!-- d3d12-review-inline:end:sodb-input:StoreStateObjectDesc-remarks:4 --></ins>

#### Return values

<!-- d3d12-review-alert:begin:sodb-input:completion-StoreStateObjectDesc:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Successful storage, including an identical insertion under the same key/version,
> returns `S_OK`. A different object version, canonical input description or object
> kind under an existing key returns `DXGI_ERROR_ALREADY_EXISTS`, leaving the
> existing entry unchanged. Read-only storage returns `DXGI_ERROR_ACCESS_DENIED`.
> The description and all reachable input data are consumed during the call.
> Parent and existing-collection keys identify already stored state object inputs,
> not live COM pointers. An unrelated PSO cannot satisfy those dependencies.
> The [graph restoration contract](#storage-only-forms) explains the required
> substitutions. The [key and version contract](#keys-and-versions) applies.

<!-- d3d12-review-alert:end:sodb-input:completion-StoreStateObjectDesc:0 -->

<a id="id3d12stateobjectdatabase-findstateobjectdesc"></a>

### ID3D12StateObjectDatabase::FindStateObjectDesc

#### Declaration

```cpp
HRESULT FindStateObjectDesc( const void* pKey, UINT KeySize, D3D12StateObjectFunc CallbackFunc, void* pContext);
```

#### Behavior

Calls a supplied callback function with the state object description for a specified key.

#### Parameters

<ins><!-- d3d12-review-inline:begin:sodb-input:FindStateObjectDesc-parameters:0 -->`pKey` (`const void*`, input)<!-- d3d12-review-inline:end:sodb-input:FindStateObjectDesc-parameters:0 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:FindStateObjectDesc-parameters:1 -->A required nonnull pointer to the object key bytes, readable for `KeySize` bytes during the call.<!-- d3d12-review-inline:end:sodb-input:FindStateObjectDesc-parameters:1 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:FindStateObjectDesc-parameters:2 -->`KeySize` (`UINT`, input)<!-- d3d12-review-inline:end:sodb-input:FindStateObjectDesc-parameters:2 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:FindStateObjectDesc-parameters:3 -->The nonzero size in bytes of `pKey`. Null or zero-size keys are invalid and do not enumerate objects.<!-- d3d12-review-inline:end:sodb-input:FindStateObjectDesc-parameters:3 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:FindStateObjectDesc-parameters:4 -->`CallbackFunc` (`D3D12StateObjectFunc`, input)<!-- d3d12-review-inline:end:sodb-input:FindStateObjectDesc-parameters:4 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:FindStateObjectDesc-parameters:5 -->Required nonnull callback function pointer that receives the reconstructed description, key and stored object version. It must remain callable until this method returns.<!-- d3d12-review-inline:end:sodb-input:FindStateObjectDesc-parameters:5 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:FindStateObjectDesc-parameters:6 -->`pContext` (`void*`, optional input/output)<!-- d3d12-review-inline:end:sodb-input:FindStateObjectDesc-parameters:6 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:FindStateObjectDesc-parameters:7 -->An application specified context pointer passed unchanged to the callback. The caller retains ownership and must keep any context used by the callback valid until this method returns.<!-- d3d12-review-inline:end:sodb-input:FindStateObjectDesc-parameters:7 --></ins>

#### Remarks

<ins><!-- d3d12-review-inline:begin:sodb-input:FindStateObjectDesc-remarks:0 -->`DXGI_ERROR_NOT_FOUND` is returned if an object with `pKey` is not found.<!-- d3d12-review-inline:end:sodb-input:FindStateObjectDesc-remarks:0 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:FindStateObjectDesc-remarks:1 -->This method returns a compatible desc to what was stored, but may not be a bit exact match.  For example, most structs in a State Object Desc have defaults implied by their absence.  These structs may be present in the find results with their default values. Also, objects such as arrays or subobjects may not appear in the same order as they were stored where the order has no meaning.<!-- d3d12-review-inline:end:sodb-input:FindStateObjectDesc-remarks:1 --></ins>

#### Return values

<!-- d3d12-review-alert:begin:sodb-input:completion-FindStateObjectDesc:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Successful retrieval returns `S_OK` after invoking `CallbackFunc`. A missing
> state object returns `DXGI_ERROR_NOT_FOUND`. A PSO key is not reinterpreted as a
> state object description. The callback receives the stored object version and
> the growth parent key/size, or no parent for an ordinary creation description.
> The callback's description can contain driver-independent root signature and
> existing-collection-by-key forms; [restore dependencies and substitute API objects](#storage-only-forms)
> before actual creation. Borrowed reconstruction buffers are transient.

<!-- d3d12-review-alert:end:sodb-input:completion-FindStateObjectDesc:0 -->

<a id="id3d12stateobjectdatabase-findobjectversion"></a>

### ID3D12StateObjectDatabase::FindObjectVersion

#### Declaration

```cpp
HRESULT FindObjectVersion( const void* pKey, UINT KeySize, UINT* pVersion);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:sodb-input:behavior-FindObjectVersion:0 -->Retrieves the version number of a stored object. This can be queried for any
object type stored.<!-- d3d12-review-inline:end:sodb-input:behavior-FindObjectVersion:0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:sodb-input:FindObjectVersion-arguments:0 -->`pKey` (`const void*`, input)<!-- d3d12-review-inline:end:sodb-input:FindObjectVersion-arguments:0 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:FindObjectVersion-arguments:1 -->A required nonnull pointer to the object key bytes, readable for `KeySize` bytes during the call.<!-- d3d12-review-inline:end:sodb-input:FindObjectVersion-arguments:1 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:FindObjectVersion-arguments:2 -->`KeySize` (`UINT`, input)<!-- d3d12-review-inline:end:sodb-input:FindObjectVersion-arguments:2 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:FindObjectVersion-arguments:3 -->The nonzero size in bytes of `pKey`. Null or zero-size keys are invalid and do not enumerate objects.<!-- d3d12-review-inline:end:sodb-input:FindObjectVersion-arguments:3 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:FindObjectVersion-arguments:4 -->`pVersion` (`UINT*`, output)<!-- d3d12-review-inline:end:sodb-input:FindObjectVersion-arguments:4 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:FindObjectVersion-arguments:5 -->Required writable pointer to caller-owned storage, valid for the duration of the call. On success it receives the stored object's 32-bit version. No value is specified on failure.<!-- d3d12-review-inline:end:sodb-input:FindObjectVersion-arguments:5 --></ins>

#### Remarks

<ins><!-- d3d12-review-inline:begin:sodb-input:FindObjectVersion-remarks:0 -->`DXGI_ERROR_NOT_FOUND` is returned if an object with `pKey` is not found.<!-- d3d12-review-inline:end:sodb-input:FindObjectVersion-remarks:0 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:FindObjectVersion-remarks:1 -->Keys must be unique in the database, but are not required to be derived from the
object contents. Whenever object contents change for a given key across revised
databases, rev the version number; this does not overwrite the existing
database entry. This method can be used to determine if an entry is in the
database.<!-- d3d12-review-inline:end:sodb-input:FindObjectVersion-remarks:1 --></ins>

#### Return values

<!-- d3d12-review-alert:begin:sodb-input:completion-FindObjectVersion:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Successful lookup returns `S_OK` and writes the 32-bit stored object version
> to caller-owned `pVersion`, for either a PSO or a state object. Missing entries
> return `DXGI_ERROR_NOT_FOUND`. No version value is specified on failure. This is
> not a size query or null output probe API.

<!-- d3d12-review-alert:end:sodb-input:completion-FindObjectVersion:0 -->

<a id="database-examples"></a>

## Examples

<!-- d3d12-review-alert:begin:sodb-input:example-context:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The following source example is illustrative application code, not a standalone
> program. It assumes the application's `VERIFY_SUCCEEDED`, `GetSODBPath`,
> `DefaultIL`, DXC helper `m_DXILHelper`, shader/profile inputs
> (`RootSignatureVS`, `RootSignaturePS1`, `PositionColorVS`, `PositionColorPS`,
> `m_vsTargetProfile`, `m_psTargetProfile`), D3DX12 helpers and preexisting `vs`/`ps`
> shader blobs used by the first generic program fragment. Its HLSL
> frontend calls produce bytecode; none of these storage calls invokes an offline
> driver compiler. Callback bodies may consume/copy their inputs but must not
> retain the displayed description pointers after returning.

<!-- d3d12-review-alert:end:sodb-input:example-context:0 -->

```c++
#include <initguid.h>
#include <d3d12.h>

int main()
{
    // Retrieve the factory.
    CComPtr<ID3D12StateObjectDatabaseFactory> spStateObjectDatabaseFactory;
    VERIFY_SUCCEEDED(D3D12GetInterface(CLSID_D3D12StateObjectFactory, IID_PPV_ARGS(&spStateObjectDatabaseFactory)));

    // Create a state object database.
    std::wstring tempFilePath = GetSODBPath();
    Microsoft::WRL::ComPtr<ID3D12StateObjectDatabase> spStateObjectDatabase;
    VERIFY_SUCCEEDED(spStateObjectDatabaseFactory->CreateStateObjectDatabaseFromFile(
        tempFilePath.c_str(),
        D3D12_STATE_OBJECT_DATABASE_FLAG_NONE,
        IID_PPV_ARGS(&spStateObjectDatabase)));

    // Store the Application Description
    {
        D3D12_APPLICATION_DESC appDesc = {};
        appDesc.pExeFilename = L"ExampleApp.exe";
        appDesc.pName = L"Example App";
        appDesc.Version.Version = 0x0001000000000000; // 1.0.0.0
        appDesc.pEngineName = L"Example Engine";
        appDesc.EngineVersion.Version = 0x0002004800090000; // 2.72.9.0
        VERIFY_SUCCEEDED(spStateObjectDatabase->SetApplicationDesc(&appDesc));
    }

    // Store an example Pipeline State Object (PSO)
    const char psoKey[] = "StateObjectDatabase_Dxil_VSPS";
    const UINT psoKeySize = sizeof(psoKey);
    UINT psoVersion = 1u;

    {
        Microsoft::WRL::ComPtr<IDxcBlob> spRootSignatureVS = m_DXILHelper.CompileHLSL(RootSignatureVS, L"VS", m_vsTargetProfile);
        Microsoft::WRL::ComPtr<IDxcBlob> spRootSignaturePS1 = m_DXILHelper.CompileHLSL(RootSignaturePS1, L"PS", m_psTargetProfile);

        struct PSO_STREAM
        {
            CD3DX12_PIPELINE_STATE_STREAM_PRIMITIVE_TOPOLOGY PrimitiveTopologyType;
            CD3DX12_PIPELINE_STATE_STREAM_INPUT_LAYOUT InputLayout;
            CD3DX12_PIPELINE_STATE_STREAM_VS VS;
            CD3DX12_PIPELINE_STATE_STREAM_PS PS;
        }
        PSOStream =
        {
            D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE,
            DefaultIL,
            AssignShaderBytecode(spRootSignatureVS.Get()),
            AssignShaderBytecode(spRootSignaturePS1.Get())
        };

        D3D12_PIPELINE_STATE_STREAM_DESC StreamDesc{ sizeof(PSOStream), &PSOStream };
        VERIFY_SUCCEEDED(spStateObjectDatabase->StorePipelineStateDesc(psoKey, psoKeySize, psoVersion, &StreamDesc));
    }

    // Store an example State Object (SO) Generic Programs
    const char soKey[] = "SODB_SimpleSO";
    UINT soKeySize = sizeof(soKey);
    UINT soVersion = 1u;

    {
        D3D12_INPUT_ELEMENT_DESC inputElementDescs[] =
        {
            { "POSITION", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 0, D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 },
            { "COLOR", 0, DXGI_FORMAT_R32G32B32A32_FLOAT, 0, 12, D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 }
        };

        CD3DX12_STATE_OBJECT_DESC executableStateObjectDesc(D3D12_STATE_OBJECT_TYPE_EXECUTABLE);

        auto pRTFormats = executableStateObjectDesc.CreateSubobject<CD3DX12_RENDER_TARGET_FORMATS_SUBOBJECT>();
        pRTFormats->SetNumRenderTargets(1);
        pRTFormats->SetRenderTargetFormat(0, DXGI_FORMAT_R8G8B8A8_UNORM);

        auto pBlendState = executableStateObjectDesc.CreateSubobject<CD3DX12_BLEND_SUBOBJECT>();
        pBlendState->SetAlphaToCoverageEnable(true);

        auto pPrimitiveTopology = executableStateObjectDesc.CreateSubobject<CD3DX12_PRIMITIVE_TOPOLOGY_SUBOBJECT>();
        pPrimitiveTopology->SetPrimitiveTopologyType(D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE);

        auto pIL = executableStateObjectDesc.CreateSubobject<CD3DX12_INPUT_LAYOUT_SUBOBJECT>();

        for (UINT i = 0; i < _countof(inputElementDescs); i++)
        {
            pIL->AddInputLayoutElementDesc(inputElementDescs[i]);
        }

        auto vsBytecode = AssignShaderBytecode(vs.Get());
        auto pVS = executableStateObjectDesc.CreateSubobject<CD3DX12_DXIL_LIBRARY_SUBOBJECT>();
        pVS->SetDXILLibrary(&vsBytecode);
        pVS->DefineExport(L"VSMain", L"*");

        auto psBytecode = AssignShaderBytecode(ps.Get());
        auto pPS = executableStateObjectDesc.CreateSubobject<CD3DX12_DXIL_LIBRARY_SUBOBJECT>();
        pPS->SetDXILLibrary(&psBytecode);
        pPS->DefineExport(L"PSMain", L"*");

        auto pGenericProgram = executableStateObjectDesc.CreateSubobject<CD3DX12_GENERIC_PROGRAM_SUBOBJECT>();
        pGenericProgram->SetProgramName(L"testProgram");
        pGenericProgram->AddExport(L"VSMain");
        pGenericProgram->AddExport(L"PSMain");
        pGenericProgram->AddSubobject(*pIL);
        pGenericProgram->AddSubobject(*pRTFormats);
        pGenericProgram->AddSubobject(*pBlendState);
        pGenericProgram->AddSubobject(*pPrimitiveTopology);

        VERIFY_SUCCEEDED(spStateObjectDatabase->StoreStateObjectDesc(
            soKey,
            soKeySize,
            soVersion,
            executableStateObjectDesc,
            nullptr,  // No Parent
            0u));
    }

    // State object with generic program using a collection to keep all the shaders
    // Shaders use root signatures specified in the shader code.
    {
        // Compile shaders
        Microsoft::WRL::ComPtr < IDxcBlob > vs = m_DXILHelper.CompileHLSL(PositionColorVS, L"VSMain", L"vs_6_7");
        Microsoft::WRL::ComPtr < IDxcBlob > ps = m_DXILHelper.CompileHLSL(PositionColorPS, L"PSMain", L"ps_6_7");

        // Define vertex input layout
        D3D12_INPUT_ELEMENT_DESC inputElementDescs[] =
        {
            { "POSITION", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 0, D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 },
            { "COLOR", 0, DXGI_FORMAT_R32G32B32A32_FLOAT, 0, 12, D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 }
        };

        // Create collection
        CD3DX12_STATE_OBJECT_DESC collectionStateObjectDesc(D3D12_STATE_OBJECT_TYPE_COLLECTION);

        auto vsBytecode = AssignShaderBytecode(vs.Get());
        auto pVS = collectionStateObjectDesc.CreateSubobject<CD3DX12_DXIL_LIBRARY_SUBOBJECT>();
        pVS->SetDXILLibrary(&vsBytecode);
        pVS->DefineExport(L"VSMain", L"*");

        auto psBytecode = AssignShaderBytecode(ps.Get());
        auto pPS = collectionStateObjectDesc.CreateSubobject<CD3DX12_DXIL_LIBRARY_SUBOBJECT>();
        pPS->SetDXILLibrary(&psBytecode);
        pPS->DefineExport(L"PSMain", L"*");

        const char collectionKeyStr[] = "SODB_TestKeyVerifyCreateStateObjectCollection";
        UINT collectionKeyStrSize = sizeof(collectionKeyStr);
        UINT collectionGroupVersion = 1u;

        VERIFY_SUCCEEDED(spStateObjectDatabase->StoreStateObjectDesc(
            collectionKeyStr,
            collectionKeyStrSize,
            collectionGroupVersion,
            collectionStateObjectDesc,
            nullptr,  // No Parent
            0u));

        CD3DX12_STATE_OBJECT_DESC executableStateObjectDesc(D3D12_STATE_OBJECT_TYPE_EXECUTABLE);

        auto pPrimitiveTopology = executableStateObjectDesc.CreateSubobject<CD3DX12_PRIMITIVE_TOPOLOGY_SUBOBJECT>();
        pPrimitiveTopology->SetPrimitiveTopologyType(D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE);

        auto pIL = executableStateObjectDesc.CreateSubobject<CD3DX12_INPUT_LAYOUT_SUBOBJECT>();

        for (UINT i = 0; i < _countof(inputElementDescs); i++)
        {
            pIL->AddInputLayoutElementDesc(inputElementDescs[i]);
        }

        auto pBlendState = executableStateObjectDesc.CreateSubobject<CD3DX12_BLEND_SUBOBJECT>();
        pBlendState->SetAlphaToCoverageEnable(true);

        auto pRTFormats = executableStateObjectDesc.CreateSubobject<CD3DX12_RENDER_TARGET_FORMATS_SUBOBJECT>();
        pRTFormats->SetNumRenderTargets(1);
        pRTFormats->SetRenderTargetFormat(0, DXGI_FORMAT_R8G8B8A8_UNORM);

        auto pCollection = executableStateObjectDesc.CreateSubobject<CD3DX12_EXISTING_COLLECTION_BY_KEY_SUBOBJECT>();
        pCollection->SetExistingCollection(collectionKeyStr, collectionKeyStrSize);

        auto pGenericProgram = executableStateObjectDesc.CreateSubobject<CD3DX12_GENERIC_PROGRAM_SUBOBJECT>();
        pGenericProgram->SetProgramName(L"testProgram1");
        pGenericProgram->AddExport(L"VSMain");
        pGenericProgram->AddExport(L"PSMain");
        pGenericProgram->AddSubobject(*pPrimitiveTopology);
        pGenericProgram->AddSubobject(*pBlendState);
        pGenericProgram->AddSubobject(*pIL);
        pGenericProgram->AddSubobject(*pRTFormats);

        const char objectName[] = "SODB_TestKeyVerifyCreateStateObjectGP";
        UINT keySize = sizeof(objectName);
        UINT Version = 2u;

        VERIFY_SUCCEEDED(spStateObjectDatabase->StoreStateObjectDesc(
            objectName,
            keySize,
            Version,
            executableStateObjectDesc,
            nullptr,  // No Parent
            0u));
    }

    struct Context
    {
        uint32_t psoCount = 0;
        uint32_t soCount = 0;
        bool hasAppDesc = false;
    } context;

    // Retrieve the application desc.
    {
        auto pfnApplicationDesc = [](const D3D12_APPLICATION_DESC* pDesc, void* pContext)
            {
                auto& context = *static_cast<Context*>(pContext);
                context.hasAppDesc = true;

                // Use pDesc
            };

        VERIFY_SUCCEEDED(spStateObjectDatabase->GetApplicationDesc(pfnApplicationDesc, &context));
    }

    // Find a Pipeline State Object
    {
        auto pfnPipelineState = [](const void* pKey, UINT KeySize, UINT Version, const D3D12_PIPELINE_STATE_STREAM_DESC* pDesc, void* pContext)
            {
                auto& context = *static_cast<Context*>(pContext);
                context.psoCount++;

                // Use pDesc
                // The stream may contain a serialized root-signature record.
                // Convert it if the consuming creation API requires a root-signature API object.
            };

        VERIFY_SUCCEEDED(spStateObjectDatabase->FindPipelineStateDesc(psoKey, psoKeySize, pfnPipelineState, &context));
    }

    // Find a State Object
    {
        auto pfnStateObject = [](const void* pKey, UINT KeySize, UINT Version, const D3D12_STATE_OBJECT_DESC* pDesc, const void* pParentKey, UINT ParentKeySize, void* pContext)
        {
            auto& context = *static_cast<Context*>(pContext);
            context.soCount++;

            // Use pDesc
            // Restore parent/collection dependencies and, where required, root-signature
            // API objects before CreateStateObject or AddToStateObject.
        };

        VERIFY_SUCCEEDED(spStateObjectDatabase->FindStateObjectDesc(soKey, soKeySize, pfnStateObject, &context));
    }
}

```

<a id="released-storage-corrections"></a>

## Released storage corrections

<ins><!-- d3d12-review-inline:begin:sodb-input:released-identical-insertion:0 -->**1.619.6:** `D3D12StateObjectCompiler.exe` `merge-sodb` and SODB writer do not treat identical insertion as an error, unless an existing group key is being replaced to point to a different PSO/SO.<!-- d3d12-review-inline:end:sodb-input:released-identical-insertion:0 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:released-root-objects:0 -->**1.619.1:** Handle root signature objects in `ID3D12StateObjectDatabase` setters.<!-- d3d12-review-inline:end:sodb-input:released-root-objects:0 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input:released-root-container:0 -->**1.619.3:** Fix `ID3D12StateObjectDatabase` store with `ID3D12RootSignature1::GetSerializedData`. It previously returned the root signature chunk instead of the container.<!-- d3d12-review-inline:end:sodb-input:released-root-container:0 --></ins>
