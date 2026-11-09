<a id="compiler-invocation-and-cache-output"></a>

# Compiler invocation and cache output

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

<!-- d3d12-review-alert:begin:compiler-output:scope:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [factory and target API](offline-compilation.md) continues here with compiler
> invocation and cache output.

<!-- d3d12-review-alert:end:compiler-output:scope:0 -->

<!-- d3d12-review-alert:begin:compiler-output:scope:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A compiler cache session maps application group keys to vendor-generated value
> keys and stores the typed results of offline pipeline-state and state-object
> compilation. A compiler state object retains compilation state for collections
> and subsequent additions; it is not an `ID3D12StateObject` created by a device
> and cannot be submitted for GPU execution.

<!-- d3d12-review-alert:end:compiler-output:scope:1 -->

<a id="output-storage"></a>

## Output storage and object subdivision

Each compiler exposes API to compile a PSO or SO that take arguments that are similar to the object creation counterparts in the D3D12 runtime.  The implementation validates API state objects and translates them into DDI representations for calling the IHV plugin.  The implementation for performing this validation and translation is shared with the D3D12 runtime.  The runtime calls the plugin with DDI arguments similar to the runtime to compile.  The plugin is expected to decompose this object, compile, and store each compiled object as a value via callbacks to the runtime.  The plugin finally sets the list of values associated with the input object via a callback to the runtime.  The runtime stores this list of values as a value group in the cache session using the group key supplied by the caller during the compile operation.

<!-- d3d12-review-alert:begin:compiler-output:collection-output-overview:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A collection compilation that produces no compiled output may omit the
> output-key callback and have no output group. This exception is specific to
> [`CompileStateObject`](#id3d12compiler-compilestateobject); it does not apply
> to PSO/executable compilation or additions.

<!-- d3d12-review-alert:end:compiler-output:collection-output-overview:0 -->

The Precompiled Shader Database(PSDB) is implemented as Sqlite3 databases for storage.  The compiler runtime API wraps the database as an ID3D12CompilerCacheSession.

The PSDB Stores:

- Metadata about the target application and adapter family.
- <ins><!-- d3d12-review-inline:begin:compiler-output:storage-concepts:2 -->Compiled objects produced by the IHV compiler plugin are stored as values.  A single PSO or SO compilation may produce multiple values.<!-- d3d12-review-inline:end:compiler-output:storage-concepts:2 --></ins>
- <ins><!-- d3d12-review-inline:begin:compiler-output:storage-concepts:2 -->A value group.  Each PSO compilation and each SO compilation that produces output has a single value group that maps its associated values.  Values may appear in more than one group (For example, if the same shader was part of another PSO or SO).<!-- d3d12-review-inline:end:compiler-output:storage-concepts:2 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:subdivision-producer:0 -->The compiler plugin may sub-divide DDI objects (PSOs, SOs, and Partial SOs) in an IHV dependent way to support deduplication and multiple values may be stored per compile operation.  The IHV plugin is responsible for generating value keys from the inputs that contribute to the compiled output and other internal data. The compiler may also check for previously compiled duplicates.<!-- d3d12-review-inline:end:compiler-output:subdivision-producer:0 --></ins>

Stored values in cache sessions may be directly compared with previous compiler version output, adapter families considered to be similar in some fashion, etc. for further deduplication.  Compilers should refrain from storing additional data in the same value buffer that causes comparison failure when compiled binaries are otherwise identical.  Compilers can instead store compiler metadata for each compiler output for this type of data instead.  For example, storing compiler version or application version information that produced a binary with the value will cause comparison to fail even if they are otherwise identical.

<!-- d3d12-review-alert:begin:compiler-output:version-domains:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Application group keys and group versions identify source-object revisions.
> Vendor-generated value keys identify reusable compiled parts; a group can
> reference several keys, and a value can belong to several groups. The
> `GroupVersion` argument is not a member of
> `D3D12_COMPILER_CACHE_GROUP_KEY`. A change to a source-object definition
> requires the corresponding group version to be revised.

<!-- d3d12-review-alert:end:compiler-output:version-domains:0 -->

<!-- d3d12-review-alert:begin:compiler-output:version-domains:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The target's adapter-family index is local to its factory; the stored identity
> uses the family identifier, ABI and compiler version. The
> [compiler, ABI and application-profile version domains](offline-compilation.md#version-domains)
> are distinct from application and engine versions in the
> [application descriptor](state-object-databases-and-identity.md#d3d12_application_desc),
> group versions, value-type flags and database-format versions.

<!-- d3d12-review-alert:end:compiler-output:version-domains:1 -->

<!-- d3d12-review-alert:begin:compiler-output:D144-readonly-consumer:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> [Read-only runtime PSDB eligibility](runtime-cache-discovery.md#compatibility) and [implicit open/failure policy](runtime-cache-discovery.md#failure-and-lifetime) define consumption of registered output. Passing those checks is not a group/value hit and does not authorize writable cache maintenance, metadata replacement or the [producer's full-identity reopening rules](#id3d12compilerfactory-createcompilercachesession).

<!-- d3d12-review-alert:end:compiler-output:D144-readonly-consumer:0 -->

<a id="output-types"></a>

## Public output types

<a id="d3d12_compiler_value_type"></a>

### D3D12_COMPILER_VALUE_TYPE

```cpp
typedef enum D3D12_COMPILER_VALUE_TYPE
{
    D3D12_COMPILER_VALUE_TYPE_OBJECT_CODE       = 0,
    D3D12_COMPILER_VALUE_TYPE_METADATA          = 1,
    D3D12_COMPILER_VALUE_TYPE_DEBUG_PDB         = 2,
    D3D12_COMPILER_VALUE_TYPE_PERFORMANCE_DATA  = 3,

} D3D12_COMPILER_VALUE_TYPE;
```

A type enumeration used when only a single value type may be selected.

**Constants**

*D3D12_COMPILER_VALUE_TYPE_OBJECT_CODE*

Specifies object code.  The compiled executable code that is run on GPU.

*D3D12_COMPILER_VALUE_TYPE_METADATA*

Metadata that the compiler may provide about the compile.  For example it may store a compiler version number used for validation.  Such a thing should not be put inside of the object code as users of this system expect to be able to do memcmp diffing between compiler versions.

*D3D12_COMPILER_VALUE_TYPE_DEBUG_PDB*

<ins><!-- d3d12-review-inline:begin:compiler-output:type-prose-d3d12_compiler_value_type:7 -->The Debug PDB for the object code.  Used in pix and other debug scenarios.  An opaque blob that still requires IHV interpretation to be used with PIX.<!-- d3d12-review-inline:end:compiler-output:type-prose-d3d12_compiler_value_type:7 --></ins>

*D3D12_COMPILER_VALUE_TYPE_PERFORMANCE_DATA*

<ins><!-- d3d12-review-inline:begin:compiler-output:type-prose-d3d12_compiler_value_type:9 -->Performance data about the compile or produced object code.  An opaque blob that still requires IHV interpretation to be used with PIX.<!-- d3d12-review-inline:end:compiler-output:type-prose-d3d12_compiler_value_type:9 --></ins>

**Remarks**

Used when defining a typed value, see [D3D12_COMPILER_CACHE_TYPED_VALUE](#d3d12_compiler_cache_typed_value).

<a id="d3d12_compiler_value_type_flags"></a>

### D3D12_COMPILER_VALUE_TYPE_FLAGS

```cpp
typedef enum D3D12_COMPILER_VALUE_TYPE_FLAGS
{
    D3D12_COMPILER_VALUE_TYPE_FLAGS_NONE                = 0x00000000,
    D3D12_COMPILER_VALUE_TYPE_FLAGS_OBJECT_CODE         = (1 << D3D12_COMPILER_VALUE_TYPE_OBJECT_CODE),
    D3D12_COMPILER_VALUE_TYPE_FLAGS_METADATA            = (1 << D3D12_COMPILER_VALUE_TYPE_METADATA),
    D3D12_COMPILER_VALUE_TYPE_FLAGS_DEBUG_PDB           = (1 << D3D12_COMPILER_VALUE_TYPE_DEBUG_PDB),
    D3D12_COMPILER_VALUE_TYPE_FLAGS_PERFORMANCE_DATA    = (1 << D3D12_COMPILER_VALUE_TYPE_PERFORMANCE_DATA),

} D3D12_COMPILER_VALUE_TYPE_FLAGS;
```

```cpp
DEFINE_ENUM_FLAG_OPERATORS( D3D12_COMPILER_VALUE_TYPE_FLAGS )
```

A flags enumeration used where multiple values may be selected.

**Constants**

*D3D12_COMPILER_VALUE_TYPE_FLAGS_NONE*

No selected value types.

*D3D12_COMPILER_VALUE_TYPE_FLAGS_OBJECT_CODE*

<ins><!-- d3d12-review-inline:begin:compiler-output:type-prose-d3d12_compiler_value_type_flags:5 -->Specifies that the operation applies to object code.<!-- d3d12-review-inline:end:compiler-output:type-prose-d3d12_compiler_value_type_flags:5 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:type-prose-d3d12_compiler_value_type_flags:6 -->*D3D12_COMPILER_VALUE_TYPE_FLAGS_METADATA*<!-- d3d12-review-inline:end:compiler-output:type-prose-d3d12_compiler_value_type_flags:6 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:type-prose-d3d12_compiler_value_type_flags:7 -->Selects compiler metadata.<!-- d3d12-review-inline:end:compiler-output:type-prose-d3d12_compiler_value_type_flags:7 --></ins>

*D3D12_COMPILER_VALUE_TYPE_FLAGS_DEBUG_PDB*

<ins><!-- d3d12-review-inline:begin:compiler-output:type-prose-d3d12_compiler_value_type_flags:9 -->Specifies that the operation applies to the debug PDB.<!-- d3d12-review-inline:end:compiler-output:type-prose-d3d12_compiler_value_type_flags:9 --></ins>

*D3D12_COMPILER_VALUE_TYPE_FLAGS_PERFORMANCE_DATA*

<ins><!-- d3d12-review-inline:begin:compiler-output:type-prose-d3d12_compiler_value_type_flags:11 -->Specifies that the operation applies to performance data.<!-- d3d12-review-inline:end:compiler-output:type-prose-d3d12_compiler_value_type_flags:11 --></ins>

**Remarks**

Used during compilation to indicate if object code or metadata should be stored or if debug pdb and performance data need to be produced and stored.

<a id="d3d12_compiler_database_path"></a>

### D3D12_COMPILER_DATABASE_PATH

```cpp
typedef struct D3D12_COMPILER_DATABASE_PATH
{
    D3D12_COMPILER_VALUE_TYPE_FLAGS Types;
    LPCWSTR pPath;
} D3D12_COMPILER_DATABASE_PATH;
```

Specifies a database path and the value types it stores.

**Members**

*Types*

The types stored in pPath.  See [D3D12_COMPILER_VALUE_TYPE_FLAGS](#d3d12_compiler_value_type_flags).

*pPath*

A file path specifying the location of a database file.

**Remarks**

Databases store one or more value types.  The types member specifies which value types are stored in pPath.

<a id="d3d12_compiler_cache_group_key"></a>

### D3D12_COMPILER_CACHE_GROUP_KEY

```cpp
typedef struct D3D12_COMPILER_CACHE_GROUP_KEY
{
    const void* pKey;
    UINT KeySize;
} D3D12_COMPILER_CACHE_GROUP_KEY;
```

<ins><!-- d3d12-review-inline:begin:compiler-output:type-prose-d3d12_compiler_cache_group_key:0 -->A structure representing a shader cache group key.<!-- d3d12-review-inline:end:compiler-output:type-prose-d3d12_compiler_cache_group_key:0 --></ins>

**Members**

*pKey*

A unique sequence of bytes that uniquely identifies the group in the database.

*KeySize*

The size in bytes of pKey.

**Remarks**

This key is used to match state object definitions in the state object database with the group of cached binaries in the shader cache session.  The database author is expected to rev the version number of a source object anytime its definition changes in a state object database.

<a id="d3d12_compiler_cache_value_key"></a>

### D3D12_COMPILER_CACHE_VALUE_KEY

```cpp
typedef struct D3D12_COMPILER_CACHE_VALUE_KEY
{
    const void* pKey;
    UINT KeySize;
} D3D12_COMPILER_CACHE_VALUE_KEY;
```

**Members**

*pKey*

A unique sequence of bytes that uniquely identifies an object in the database.

*KeySize*

The size in bytes of pKey.

**Remarks**

Used during cache operations like find and store value to identify a value.

<!-- d3d12-review-alert:begin:compiler-output:opaque-key-buffers:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Group keys and value keys are opaque byte sequences, not necessarily text
> or null-terminated strings. `KeySize` counts bytes. Each `pKey` must address
> the bytes described by that count while the receiving call uses it. Application
> group keys and vendor-generated value keys occupy different roles even when
> their byte sequences happen to match.

<!-- d3d12-review-alert:end:compiler-output:opaque-key-buffers:0 -->

<a id="d3d12_compiler_cache_value"></a>

### D3D12_COMPILER_CACHE_VALUE

```cpp
typedef struct D3D12_COMPILER_CACHE_VALUE
{
    void* pValue;
    UINT ValueSize;
} D3D12_COMPILER_CACHE_VALUE;
```

A non-const value buffer and buffer size structure for cached values.

**Members**

*pValue*

<ins><!-- d3d12-review-inline:begin:compiler-output:type-prose-d3d12_compiler_cache_value:3 -->A pointer to a memory buffer containing the value.<!-- d3d12-review-inline:end:compiler-output:type-prose-d3d12_compiler_cache_value:3 --></ins>

*ValueSize*

The size of the pValue buffer in bytes.

**Remarks**

Used for object code, compiler metadata, debug PDB, and performance data.

<a id="d3d12_compiler_cache_typed_value"></a>

### D3D12_COMPILER_CACHE_TYPED_VALUE

```cpp
typedef struct D3D12_COMPILER_CACHE_TYPED_VALUE
{
    D3D12_COMPILER_VALUE_TYPE Type;
    D3D12_COMPILER_CACHE_VALUE Value;
} D3D12_COMPILER_CACHE_TYPED_VALUE;
```

Specifies a value and its type, such as object code, metadata etc.

**Members**

*Type*

<ins><!-- d3d12-review-inline:begin:compiler-output:type-prose-d3d12_compiler_cache_typed_value:3 -->The type of the value, such as object code, metadata, etc.  See [D3D12_COMPILER_VALUE_TYPE](#d3d12_compiler_value_type) for more information on types.<!-- d3d12-review-inline:end:compiler-output:type-prose-d3d12_compiler_cache_typed_value:3 --></ins>

*Value*

The buffer and size for the value.  See [D3D12_COMPILER_CACHE_VALUE](#d3d12_compiler_cache_value).

**Remarks**

Used in API where the compiler may modify the value buffer, such as [ID3D12CompilerCacheSession::FindValue](#id3d12compilercachesession-findvalue).

<a id="d3d12_compiler_cache_const_value"></a>

### D3D12_COMPILER_CACHE_CONST_VALUE

```cpp
typedef struct D3D12_COMPILER_CACHE_CONST_VALUE
{
    const void* pValue;
    UINT ValueSize;
} D3D12_COMPILER_CACHE_CONST_VALUE;
```

<ins><!-- d3d12-review-inline:begin:compiler-output:type-prose-d3d12_compiler_cache_const_value:0 -->Specifies a const value buffer and buffer size.<!-- d3d12-review-inline:end:compiler-output:type-prose-d3d12_compiler_cache_const_value:0 --></ins>

**Members**

*pValue*

<ins><!-- d3d12-review-inline:begin:compiler-output:type-prose-d3d12_compiler_cache_const_value:3 -->A const pointer to a memory buffer containing the value.<!-- d3d12-review-inline:end:compiler-output:type-prose-d3d12_compiler_cache_const_value:3 --></ins>

*ValueSize*

The size of the pValue buffer in bytes.

**Remarks**

See also [D3D12_COMPILER_CACHE_TYPED_CONST_VALUE](#d3d12_compiler_cache_typed_const_value).

<a id="d3d12_compiler_cache_typed_const_value"></a>

### D3D12_COMPILER_CACHE_TYPED_CONST_VALUE

```cpp
typedef struct D3D12_COMPILER_CACHE_TYPED_CONST_VALUE
{
    D3D12_COMPILER_VALUE_TYPE Type;
    D3D12_COMPILER_CACHE_CONST_VALUE Value;
} D3D12_COMPILER_CACHE_TYPED_CONST_VALUE;
```

**Members**

*Type*

<ins><!-- d3d12-review-inline:begin:compiler-output:type-prose-d3d12_compiler_cache_typed_const_value:2 -->The type of the value, such as object code, metadata, etc.  See [D3D12_COMPILER_VALUE_TYPE](#d3d12_compiler_value_type) for more information on types.<!-- d3d12-review-inline:end:compiler-output:type-prose-d3d12_compiler_cache_typed_const_value:2 --></ins>

*Value*

<ins><!-- d3d12-review-inline:begin:compiler-output:type-prose-d3d12_compiler_cache_typed_const_value:4 -->The const buffer and size for the value.  See [D3D12_COMPILER_CACHE_CONST_VALUE](#d3d12_compiler_cache_const_value).<!-- d3d12-review-inline:end:compiler-output:type-prose-d3d12_compiler_cache_typed_const_value:4 --></ins>

**Remarks**

Used in API where the compiler may not modify the value buffer, such as [ID3D12CompilerCacheSession::StoreValue](#id3d12compilercachesession-storevalue).

<a id="d3d12_compiler_existing_collection_desc"></a>

### D3D12_COMPILER_EXISTING_COLLECTION_DESC

```cpp
typedef struct D3D12_COMPILER_EXISTING_COLLECTION_DESC
{
    ID3D12CompilerStateObject* pExistingCollection;
    UINT NumExports;
    const D3D12_EXPORT_DESC* pExports;
} D3D12_COMPILER_EXISTING_COLLECTION_DESC;
```

```cpp
D3D12_STATE_SUBOBJECT_TYPE_COMPILER_EXISTING_COLLECTION = 33, // D3D12_COMPILER_EXISTING_COLLECTION_DESC
```

<!-- d3d12-review-alert:begin:compiler-output:compiler-existing-collection:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Use `D3D12_STATE_SUBOBJECT_TYPE_COMPILER_EXISTING_COLLECTION` with this
> descriptor. `pExistingCollection` is a live compiler state-object collection,
> not an `ID3D12StateObject` from a device or a database key.
> `NumExports` counts `D3D12_EXPORT_DESC` entries; when zero, all collection
> exports are surfaced. Otherwise `pExports` points to that many readable export
> descriptors, with the export selection/renaming semantics of
> [existing collections](state-objects.md#d3d12_existing_collection_desc).
> The referenced collection must come from the compiler receiving the description. The application must
> retain it while its dependents need it; compilation does not automatically
> retain a collection API reference.

<!-- d3d12-review-alert:end:compiler-output:compiler-existing-collection:0 -->

<a id="public-callbacks"></a>

## Public callbacks

<a id="d3d12compilercachesessionallocationfunc"></a>

### D3D12CompilerCacheSessionAllocationFunc

```cpp
typedef void* (__stdcall* D3D12CompilerCacheSessionAllocationFunc) (
    SIZE_T SizeInBytes,
    _Inout_opt_ void* pContext
    );
```

An allocation callback to enable a single call to get size and buffer contents.

**Parameters**

*SizeInBytes*

 The size in bytes of the requested allocation.

*pContext*

An application defined context pointer.

**Remarks**

Returns a non-nullptr value on success which points to buffer allocation meeting the size requirements.  Allocations must meet the fundamental alignment requirements and be suitably aligned for any object, see std::max_align_t.

Returns nullptr on allocation failure.

This function must not throw uncaught exceptions.

<a id="d3d12compilercachesessiongroupvaluekeysfunc"></a>

### D3D12CompilerCacheSessionGroupValueKeysFunc

```cpp
typedef void(__stdcall* D3D12CompilerCacheSessionGroupValueKeysFunc) (
    _In_ const D3D12_COMPILER_CACHE_VALUE_KEY* pValueKey,
    _Inout_opt_ void* pContext
    );
```

<ins><!-- d3d12-review-inline:begin:compiler-output:callback-prose-d3d12compilercachesessiongroupvaluekeysfunc:0 -->A callback function for retrieving one or more shader cache value keys for use with the [ID3D12CompilerCacheSession::FindGroupValueKeys](#id3d12compilercachesession-findgroupvaluekeys) method.<!-- d3d12-review-inline:end:compiler-output:callback-prose-d3d12compilercachesessiongroupvaluekeysfunc:0 --></ins>

**Arguments**

*pValueKey*

A value key for a value that is part of the specified group.  The allocations backing these keys are de-allocated and should no longer be accessed once D3D12CompilerCacheSessionGroupValueKeysFunc returns.

*pContext*

An application defined context pointer.

**Remarks**

This function is called once for each value that is part of the group.

This function must not throw uncaught exceptions.  The allocations backing pValueKey and pValueKey->pKey are valid until this function returns.

<a id="d3d12compilercachesessiongroupvaluesfunc"></a>

### D3D12CompilerCacheSessionGroupValuesFunc

```cpp
typedef void(__stdcall* D3D12CompilerCacheSessionGroupValuesFunc) (
    UINT ValueKeyIndex,
    _In_ const D3D12_COMPILER_CACHE_TYPED_CONST_VALUE* pTypedValue,
    _Inout_opt_ void* pContext
    );
```

<ins><!-- d3d12-review-inline:begin:compiler-output:callback-prose-d3d12compilercachesessiongroupvaluesfunc:0 -->A callback function for retrieving the binary values of each value in a group.<!-- d3d12-review-inline:end:compiler-output:callback-prose-d3d12compilercachesessiongroupvaluesfunc:0 --></ins>

**Arguments**

*ValueKeyIndex*

<ins><!-- d3d12-review-inline:begin:compiler-output:callback-prose-d3d12compilercachesessiongroupvaluesfunc:3 -->An index grouping the typed values for one value key within the filtered backing-database query.  For example, if both OBJECT_CODE and METADATA are requested and stored for a value key in the same backing database, this function is called twice with ValueKeyIndex 0 before incrementing for the next set of values.<!-- d3d12-review-inline:end:compiler-output:callback-prose-d3d12compilercachesessiongroupvaluesfunc:3 --></ins>

*pTypedValue*

Indicates a single value type and value for the callback.  See [D3D12_COMPILER_CACHE_TYPED_CONST_VALUE](#d3d12_compiler_cache_typed_const_value).

*pContext*

An application defined context pointer.

**Remarks**

<ins><!-- d3d12-review-inline:begin:compiler-output:callback-prose-d3d12compilercachesessiongroupvaluesfunc:9 -->This function is called once for each selected stored value type that is part of the group.  Use ValueKeyIndex to associate value types to the same value key.<!-- d3d12-review-inline:end:compiler-output:callback-prose-d3d12compilercachesessiongroupvaluesfunc:9 --></ins>

This function must not throw uncaught exceptions.

<!-- d3d12-review-alert:begin:compiler-output:callback-borrowing:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pTypedValue` and its value buffer passed to a group-value callback are borrowed
> for that callback invocation. Copy any data needed afterward; do not free the
> borrowed storage. The application owns `pContext`; the lookup passes it through.
> The callbacks execute as part of the lookup before that lookup returns.

<!-- d3d12-review-alert:end:compiler-output:callback-borrowing:0 -->

<!-- d3d12-review-alert:begin:compiler-output:callback-borrowing:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The allocation callback instead supplies application-owned storage. The caller
> must release successful allocations with the matching deallocator, including
> allocations returned before a later failure. The cache session does not take
> ownership of those allocations.

<!-- d3d12-review-alert:end:compiler-output:callback-borrowing:1 -->

<a id="id3d12compilerfactory-createcompilercachesession"></a>

## ID3D12CompilerFactory::CreateCompilerCacheSession

### Declaration

```cpp
HRESULT CreateCompilerCacheSession(
    const D3D12_COMPILER_DATABASE_PATH* pPaths,
    UINT NumPaths,
    const D3D12_COMPILER_TARGET* pTarget,
    const D3D12_APPLICATION_DESC* pApplicationDesc,
    REFIID riid,
    void** ppCompilerCacheSession
);
```

### Behavior

Database Files:

- If a specified file does not exist, it is created.  If it exists, it is opened for modification.
- <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerfactory-createcompilercachesession-source:1 -->Value types may be stored in separate databases.  For example, PDBs may be stored in a separate database file than object code.<!-- d3d12-review-inline:end:compiler-output:id3d12compilerfactory-createcompilercachesession-source:1 --></ins>

<!-- d3d12-review-alert:begin:compiler-output:session-routing-and-files:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pPaths` is required and `NumPaths` must be nonzero. Each `Types` mask must
> select at least one of the four declared value types and no undeclared bits.
> The masks must be pairwise disjoint: each type is assigned to exactly one
> database entry. `GetValueTypes` returns their union. Object code and metadata
> must either both be in this union or both be absent; they may be assigned to
> different entries. Debug PDB and performance-data storage can be selected
> independently.

<!-- d3d12-review-alert:end:compiler-output:session-routing-and-files:0 -->

<!-- d3d12-review-alert:begin:compiler-output:session-routing-and-files:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Each `pPath` names a Windows file, using a filename, local path or UNC path;
> the containing directory must exist. A null path selects a session-local
> in-memory database. It is not the filename `:memory:`; SQLite URI filenames
> and that special filename are not accepted by this API. The path descriptor
> contains no filename-extension inference and no access-mode flag.
> Existing files are opened for modification and missing files are created;
> this is not a read-only open API. Read-only files or inaccessible paths can
> fail to open. SODB's
> [read-only flag](state-object-databases-and-identity.md#d3d12_state_object_database_flags)
> does not apply to this call.

<!-- d3d12-review-alert:end:compiler-output:session-routing-and-files:1 -->

<!-- d3d12-review-alert:begin:compiler-output:session-routing-and-files:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Disjoint masks route types; distinct path strings can still identify the
> same physical file. Group writes are made to every database entry. Physical-file
> deduplication and an all-files transaction are not guaranteed, so aliased
> entries must not be treated as independent storage.

<!-- d3d12-review-alert:end:compiler-output:session-routing-and-files:2 -->

<!-- d3d12-review-alert:begin:compiler-output:session-metadata:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pTarget` and `pApplicationDesc` are optional only when the database metadata
> supplies the corresponding identity. If no opened database supplies an
> identity, that descriptor must be provided; otherwise creation returns
> `E_INVALIDARG`. New databases receive the resolved identities. Missing metadata
> in one file may be filled from consistent metadata in another file or from the
> supplied descriptors.

<!-- d3d12-review-alert:end:compiler-output:session-metadata:0 -->

<!-- d3d12-review-alert:begin:compiler-output:session-metadata:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> All existing compiler identities must agree on family identifier, ABI and
> compiler version. All application identities must agree on executable
> filename, application name/version, engine name/version and application-profile
> version. Supplied descriptors must agree with stored identities. Null
> application string members compare as empty strings; application string
> comparisons are case-sensitive. Inconsistent identities
> return `E_INVALIDARG`, rather than silently changing the identity of a populated
> database.

<!-- d3d12-review-alert:end:compiler-output:session-metadata:1 -->

<!-- d3d12-review-alert:begin:compiler-output:session-metadata:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The factory resolves a stored family identifier to its own local family index.
> An explicit target's ABI zero resolves to the newest supported ABI under
> [target resolution](offline-compilation.md#d3d12_compiler_target); an explicit
> nonzero ABI must be supported. The resolved family, ABI and compiler version
> must match stored metadata. The application-profile version must match the
> version reported by this compiler for the resolved target and application.
> An unsupported stored family can fail lookup with `DXGI_ERROR_NOT_FOUND`;
> identity/version mismatches return `E_INVALIDARG`.

<!-- d3d12-review-alert:end:compiler-output:session-metadata:2 -->

<!-- d3d12-review-alert:begin:compiler-output:session-metadata:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Path strings and application strings are consumed or copied during creation;
> the caller retains their ownership. `ppCompilerCacheSession` is required
> writable interface-pointer storage, not a null-output availability probe.
> On success it receives an owned reference selected by `riid`. Failures before
> the interface query do not promise to clear an existing output value. Opening
> and initializing earlier files may already have happened when a later file or
> metadata check fails; no all-files rollback is guaranteed.

<!-- d3d12-review-alert:end:compiler-output:session-metadata:3 -->

<!-- d3d12-review-alert:begin:compiler-output:explicit-application-input:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> When `pApplicationDesc` is explicitly supplied, `pExeFilename` and `pName`
> are required non-null, null-terminated strings identifying the target
> application's executable filename and title. `Version` supplies its application
> version. `pEngineName` is optional; if supplied it must be null-terminated and
> `EngineVersion` must be provided. These are the
> [application metadata requirements](state-object-databases-and-identity.md#d3d12_application_desc),
> not a fallback to the compiler-hosting process's identity.

<!-- d3d12-review-alert:end:compiler-output:explicit-application-input:0 -->

<!-- d3d12-review-alert:begin:compiler-output:explicit-application-input:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The optional descriptor pointer used to resolve existing database metadata is
> a separate condition. Comparison or copying of null string members as empty
> strings does not waive the required fields of an explicitly supplied
> descriptor.

<!-- d3d12-review-alert:end:compiler-output:explicit-application-input:1 -->

### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerfactory-createcompilercachesession-parameter-source:0 -->`[in] pPaths`<!-- d3d12-review-inline:end:compiler-output:id3d12compilerfactory-createcompilercachesession-parameter-source:0 --></ins>

A list of paths that specify which types of values are stored by this cache session, and which database they should be stored in.  See [D3D12_COMPILER_DATABASE_PATH](#d3d12_compiler_database_path).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerfactory-createcompilercachesession-parameter-source:2 -->`[in] NumPaths`<!-- d3d12-review-inline:end:compiler-output:id3d12compilerfactory-createcompilercachesession-parameter-source:2 --></ins>

The number of paths specified in pPaths.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerfactory-createcompilercachesession-parameter-source:4 -->`[in, optional] pTarget`<!-- d3d12-review-inline:end:compiler-output:id3d12compilerfactory-createcompilercachesession-parameter-source:4 --></ins>

Describes the adapter family and ABI version to target.  Specify zero for ABIVersion to default to the latest supported ABI Version.  See [D3D12_COMPILER_TARGET](offline-compilation.md#d3d12_compiler_target).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerfactory-createcompilercachesession-parameter-source:6 -->`[in, optional] pApplicationDesc`<!-- d3d12-review-inline:end:compiler-output:id3d12compilerfactory-createcompilercachesession-parameter-source:6 --></ins>

Describes the target application and version.  See [D3D12_APPLICATION_DESC](state-object-databases-and-identity.md#d3d12_application_desc).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerfactory-createcompilercachesession-parameter-source:8 -->`[in] riid`<!-- d3d12-review-inline:end:compiler-output:id3d12compilerfactory-createcompilercachesession-parameter-source:8 --></ins>

The globally unique identifier (GUID) for the compiler cache session interface. See [ID3D12CompilerCacheSession](#id3d12compilerfactory-createcompilercachesession).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerfactory-createcompilercachesession-parameter-source:10 -->`[out] ppCompilerCacheSession`<!-- d3d12-review-inline:end:compiler-output:id3d12compilerfactory-createcompilercachesession-parameter-source:10 --></ins>

On return, <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerfactory-createcompilercachesession-parameter-source:11 -->a pointer to the compiler cache-session interface specified by riid.<!-- d3d12-review-inline:end:compiler-output:id3d12compilerfactory-createcompilercachesession-parameter-source:11 --></ins>

### Return values

<!-- d3d12-review-alert:begin:compiler-output:id3d12compilerfactory-createcompilercachesession-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` returns the requested cache-session interface. Invalid routing masks, a missing path array, zero path count, and the
> documented missing or mismatched identities return `E_INVALIDARG`; an unsupported requested interface
> returns `E_NOINTERFACE`. Allocation, file-open/database and plugin query
> failures propagate as failing `HRESULT`s. There is no universal filesystem-error
> mapping or all-files rollback guarantee.

<!-- d3d12-review-alert:end:compiler-output:id3d12compilerfactory-createcompilercachesession-returns:0 -->

<a id="id3d12compilerfactory-createcompiler"></a>

## ID3D12CompilerFactory::CreateCompiler

### Declaration

```cpp
HRESULT CreateCompiler(
    ID3D12CompilerCacheSession* pCompilerCacheSession,
    REFIID riid,
    void** ppCompiler
);
```

### Behavior

Create an instance of a compiler.

Use [D3D12_APPLICATION_DESC](state-object-databases-and-identity.md#d3d12_application_desc) to query the profile version from the compiler plugin with [ID3D12CompilerFactory::GetApplicationProfileVersion](offline-compilation.md#id3d12compilerfactory-getapplicationprofileversion).  Compilers may revise this number to indicate application specific changes to compiler output.

<!-- d3d12-review-alert:begin:compiler-output:compiler-creation-lifetime:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pCompilerCacheSession` and `ppCompiler` are required; null returns
> `E_INVALIDARG`. The compiler retains a reference to its cache session and
> inherits its target, application descriptor and selected value types.
> The caller owns the returned compiler reference and releases it when no
> longer needed. The retained session keeps its application strings alive.

<!-- d3d12-review-alert:end:compiler-output:compiler-creation-lifetime:0 -->

<!-- d3d12-review-alert:begin:compiler-output:compiler-creation-lifetime:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The cache session need not have been created by this factory, but its target
> index and metadata must be meaningful to this factory. No cross-factory index
> translation is performed; see [input ownership](#input-ownership).
> `ppCompiler` is not a null-output validation probe. Failure before the final
> interface query need not initialize it. Plugin creation and allocation failures
> fail this call.

<!-- d3d12-review-alert:end:compiler-output:compiler-creation-lifetime:1 -->

### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerfactory-createcompiler-parameter-source:0 -->`[in] pCompilerCacheSession`<!-- d3d12-review-inline:end:compiler-output:id3d12compilerfactory-createcompiler-parameter-source:0 --></ins>

The cache session where compiled results are stored.  The compiler plugin may also check if objects were previously compiled.  See [ID3D12CompilerCacheSession](#id3d12compilerfactory-createcompilercachesession).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerfactory-createcompiler-parameter-source:2 -->`[in] riid`<!-- d3d12-review-inline:end:compiler-output:id3d12compilerfactory-createcompiler-parameter-source:2 --></ins>

The globally unique identifier (GUID) for the compiler interface. See [ID3D12Compiler](#id3d12compilerfactory-createcompiler).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerfactory-createcompiler-parameter-source:4 -->`[out] ppCompiler`<!-- d3d12-review-inline:end:compiler-output:id3d12compilerfactory-createcompiler-parameter-source:4 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerfactory-createcompiler-parameter-source:5 -->On return, a pointer to the compiler interface specified by riid.<!-- d3d12-review-inline:end:compiler-output:id3d12compilerfactory-createcompiler-parameter-source:5 --></ins>

### Return values

<!-- d3d12-review-alert:begin:compiler-output:id3d12compilerfactory-createcompiler-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` returns the requested compiler interface; null required arguments
> return `E_INVALIDARG`, and an unsupported interface returns `E_NOINTERFACE`.
> Allocation and plugin compiler-creation failures propagate. A returned
> compiler does not certify that every later description is compilable.

<!-- d3d12-review-alert:end:compiler-output:id3d12compilerfactory-createcompiler-returns:0 -->

<a id="input-ownership"></a>

## Compilation inputs and ownership

<!-- d3d12-review-alert:begin:compiler-output:synchronization-and-lifetime:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `ID3D12Compiler` and `ID3D12CompilerCacheSession` derive from
> `ID3D12CompilerFactoryChild`; their inherited
> [`GetFactory`](offline-compilation.md#id3d12compilerfactorychild-getfactory)
> contract is not a new operation on either interface. `ID3D12CompilerStateObject`
> derives from `IUnknown` and exposes
> [`GetCompiler`](#id3d12compilerstateobject-getcompiler).

<!-- d3d12-review-alert:end:compiler-output:synchronization-and-lifetime:0 -->

<!-- d3d12-review-alert:begin:compiler-output:synchronization-and-lifetime:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The compiler plugin is responsible for synchronization as necessary,
> applications do not need to add external synchronization. Caller-owned
> descriptions, arrays, keys, strings, callback functions and context storage must
> remain valid while the receiving call uses them. That synchronization contract
> does not remove the object-reference or structural-dependency requirements
> below.

<!-- d3d12-review-alert:end:compiler-output:synchronization-and-lifetime:1 -->

<!-- d3d12-review-alert:begin:compiler-output:compilation-inputs:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Pipeline descriptions use
> [`D3D12_PIPELINE_STATE_STREAM_DESC`](pipeline-state.md#streams).
> For explicit roots, use
> `D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_SERIALIZED_ROOT_SIGNATURE` carrying
> [`D3D12_SERIALIZED_ROOT_SIGNATURE_DESC`](state-object-databases-and-identity.md#d3d12_serialized_root_signature_desc),
> not a device root-signature pointer. Roots embedded in shaders can be resolved
> and validated by the compiler. Legacy cached PSO blobs and pipeline-library
> inputs are not compiler-host inputs.

<!-- d3d12-review-alert:end:compiler-output:compilation-inputs:0 -->

<!-- d3d12-review-alert:begin:compiler-output:compilation-inputs:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> State-object descriptions use
> [`D3D12_STATE_OBJECT_DESC`](state-objects.md#d3d12_state_object_desc).
> Explicit roots use
> [`D3D12_GLOBAL_SERIALIZED_ROOT_SIGNATURE`](state-object-databases-and-identity.md#d3d12_global_serialized_root_signature)
> or
> [`D3D12_LOCAL_SERIALIZED_ROOT_SIGNATURE`](state-object-databases-and-identity.md#d3d12_local_serialized_root_signature)
> with their corresponding serialized-root subobject tags. An existing
> compiler collection uses
> [`D3D12_COMPILER_EXISTING_COLLECTION_DESC`](#d3d12_compiler_existing_collection_desc)
> and `D3D12_STATE_SUBOBJECT_TYPE_COMPILER_EXISTING_COLLECTION`.
> The database's
> [`D3D12_EXISTING_COLLECTION_BY_KEY_DESC`](state-object-databases-and-identity.md#d3d12_existing_collection_by_key_desc)
> is a storage reference, not a directly accepted compile input. Reconstruct the
> dependency as a live compiler collection; a parent key from an SODB similarly
> identifies a dependency to supply as a live parent to the addition call.

<!-- d3d12-review-alert:end:compiler-output:compilation-inputs:1 -->

<!-- d3d12-review-alert:begin:compiler-output:compilation-inputs:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The compiler runtime validates descriptions and translates them to DDI
> representations using shared runtime validation. Pipeline stream parsing,
> stage composition, input/stream-output layouts, render-target and
> depth/stencil formats, samples, rasterization and linkage retain the
> [pipeline construction rules](pipeline-state.md#id3d12device2-createpipelinestate).
> Root contents and shader compatibility retain
> [Binding](binding.md#root-signatures).
> State-object type/payload, exports, associations, defaults, collection linking
> and construction retain
> [State objects](state-objects.md#createstateobject),
> [association requirements](state-objects.md#subobject-association-requirements)
> and [default resolution](state-objects.md#default-resolution).
> Incremental additions retain the
> [addition restrictions](state-objects.md#addtostateobject).

<!-- d3d12-review-alert:end:compiler-output:compilation-inputs:2 -->

<!-- d3d12-review-alert:begin:compiler-output:compilation-inputs:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Capability checks are made against the compiler's target using the
> [negotiated plugin capabilities](compiler-plugin-foundation.md#get-caps),
> including applicable feature level, shader model, shader features, formats,
> multisampling, raytracing/state-object or work-graph requirements. Serializing
> or storing a description does not establish that the target can compile it.
> Invalid descriptions and unsupported target capabilities are distinct from
> an IHV compiler failure.

<!-- d3d12-review-alert:end:compiler-output:compilation-inputs:3 -->

<!-- d3d12-review-alert:begin:compiler-output:compilation-inputs:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Descriptions, their reachable arrays, bytecode and serialized roots must be
> readable for the call. The compiler retains the internal descriptions and
> dependency state needed by later additions; callers need not keep the
> original top-level description allocation alive after a successful call.

<!-- d3d12-review-alert:end:compiler-output:compilation-inputs:4 -->

<!-- d3d12-review-alert:begin:compiler-output:factory-and-parent-consistency:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Every referenced compiler collection and addition parent must have been created
> by the same `ID3D12Compiler` that receives the dependent compile call. These
> are caller preconditions; no particular mismatch `HRESULT` is guaranteed.

<!-- d3d12-review-alert:end:compiler-output:factory-and-parent-consistency:0 -->

<!-- d3d12-review-alert:begin:compiler-output:factory-and-parent-consistency:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A cache session need not come from the compiler's factory. Its target,
> application descriptor and selected value types must be meaningful to the
> receiving factory. The target's family index is interpreted in that factory's
> enumeration; the compiler does not remap an index from another factory.
> The compiler retains its cache session, and a compiler state object retains
> the compiler that created it.

<!-- d3d12-review-alert:end:compiler-output:factory-and-parent-consistency:1 -->

<!-- d3d12-review-alert:begin:compiler-output:factory-and-parent-consistency:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Applications must retain compiler collections while their dependents need them.
> Compilation does not automatically retain a collection API reference.
> Retaining a compiler or copying description data is not a substitute for
> keeping the referenced collection alive.

<!-- d3d12-review-alert:end:compiler-output:factory-and-parent-consistency:2 -->

<!-- d3d12-review-alert:begin:compiler-output:factory-and-parent-consistency:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> An addition retains the parent's description data, not the parent's API
> reference or plugin handle. After the addition succeeds, the application need
> not retain the addition-parent API reference for the child's lifetime.
> Releasing the last parent reference destroys the parent's plugin handle;
> the plugin must retain whatever dependency state it needs for the child.
> This is the description/handle distinction in
> [state-object driver lifetime](state-objects.md#driver-lifetime), not the
> collection-retention rule above. Original caller-owned description allocations
> can be released after successful compilation.

<!-- d3d12-review-alert:end:compiler-output:factory-and-parent-consistency:3 -->

<a id="id3d12compiler-compilepipelinestate"></a>

## ID3D12Compiler::CompilePipelineState

### Declaration

```cpp
HRESULT CompilePipelineState(
    const D3D12_COMPILER_CACHE_GROUP_KEY* pGroupKey,
    UINT GroupVersion,
    const D3D12_PIPELINE_STATE_STREAM_DESC* pDesc
);
```

### Behavior

Compile a graphics or compute pipeline state.

Compiled output is stored via [ID3D12CompilerCacheSession::StoreValue](#id3d12compilercachesession-storevalue).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilepipelinestate-source:2 -->Compiler may sub-divide objects in an IHV dependent way to support deduplication.  Therefore, multiple values may be stored per compile operation. The compiler may also check for previously compiled values.<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilepipelinestate-source:2 --></ins>

The Group Key and Group Version are used to store a group that associates all the values stored for this compilation via [ID3D12CompilerCacheSession::StoreGroupValueKeys](#id3d12compilercachesession-storegroupvaluekeys).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilepipelinestate-source:4 -->On success, this method will not return until all compiled output is stored.<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilepipelinestate-source:4 --></ins>

<!-- d3d12-review-alert:begin:compiler-output:compilepipelinestate-completion:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The cache session's `GetValueTypes()` mask selects the output types; there is
> no value-type-flags argument on this API. The group key is required; the
> description and all required referenced data must be valid.
> Compilation completes synchronously, including the plugin's cache callbacks.
> This is not an asynchronous job handle and does not create a GPU-executable
> device object. Completion does not imply a cross-file atomic commit, crash
> durability, or rollback of values stored before an error.

<!-- d3d12-review-alert:end:compiler-output:compilepipelinestate-completion:0 -->

<!-- d3d12-review-alert:begin:compiler-output:compilepipelinestate-validation-input:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A null `pGroupKey` returns `E_INVALIDARG`. The
> [compilation input and target-validation contract](#input-ownership)
> defines the required description forms and shared construction rules.

<!-- d3d12-review-alert:end:compiler-output:compilepipelinestate-validation-input:0 -->

### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilepipelinestate-parameter-source:0 -->`[in] pGroupKey`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilepipelinestate-parameter-source:0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilepipelinestate-parameter-source:1 -->A unique key that identifies the group. This key is used to store a group with the values produced by this compiled operation.  This group must not already be present in the cache session.<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilepipelinestate-parameter-source:1 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilepipelinestate-parameter-source:2 -->`[in] GroupVersion`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilepipelinestate-parameter-source:2 --></ins>

The version number of the cached group.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilepipelinestate-parameter-source:4 -->`[in] pDesc`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilepipelinestate-parameter-source:4 --></ins>

The pipeline state desc describing the PSO.  See [D3D12_PIPELINE_STATE_STREAM_DESC](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_pipeline_state_stream_desc).

### Return values

<!-- d3d12-review-alert:begin:compiler-output:id3d12compiler-compilepipelinestate-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` indicates successful validation and plugin completion. Description
> validation failures return `E_INVALIDARG`; unsupported target capabilities can return
> `DXGI_ERROR_UNSUPPORTED`. Allocation failures return `E_OUTOFMEMORY`.

<!-- d3d12-review-alert:end:compiler-output:id3d12compiler-compilepipelinestate-returns:0 -->

<!-- d3d12-review-alert:begin:compiler-output:id3d12compiler-compilepipelinestate-returns:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Plugin compile failures preserve `E_OUTOFMEMORY`; other failing plugin compile
> results are translated to `DXGI_ERROR_DRIVER_INTERNAL_ERROR`. This is distinct
> from the cache callbacks' own results, which are returned to the plugin.
> The plugin must handle or propagate callback failures; a callback result is
> not necessarily the public compile call's final `HRESULT`. Missing required
> group-key registration also fails compilation with
> `DXGI_ERROR_DRIVER_INTERNAL_ERROR`.
> Stored values can survive a failing compile.

<!-- d3d12-review-alert:end:compiler-output:id3d12compiler-compilepipelinestate-returns:1 -->

<a id="id3d12compiler-compilestateobject"></a>

## ID3D12Compiler::CompileStateObject

### Declaration

```cpp
HRESULT CompileStateObject(
    const D3D12_COMPILER_CACHE_GROUP_KEY* pGroupKey,
    UINT GroupVersion,
    const D3D12_STATE_OBJECT_DESC* pDesc,
    REFIID riid,
    void** ppCompilerStateObject
);
```

### Behavior

Compiled output is stored via [ID3D12CompilerCacheSession::StoreValue](#id3d12compilercachesession-storevalue).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilestateobject-source:1 -->Compiler may sub-divide<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilestateobject-source:1 --></ins> objects in an IHV dependent way to support deduplication.  Therefore, multiple values may be stored per compile. <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilestateobject-source:1 -->The compiler may also check<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilestateobject-source:1 --></ins> for previously compiled duplicates.

The Group Key and Group Version are used to store a group that associates all the values stored for this compilation via [ID3D12CompilerCacheSession::StoreGroupValueKeys](#id3d12compilercachesession-storegroupvaluekeys).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilestateobject-source:3 -->On success, this method will not return until all compiled output is stored.<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilestateobject-source:3 --></ins>

This method creates an object that implements [ID3D12CompilerStateObject](#id3d12compiler-compilestateobject) to support using it as a base object when deriving new state objects with [ID3D12Compiler::CompileAddToStateObject](#id3d12compiler-compileaddtostateobject).

<!-- d3d12-review-alert:begin:compiler-output:compilestateobject-completion:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The cache session's `GetValueTypes()` mask selects the output types; there is
> no value-type-flags argument on this API. The group key is required; the
> description and all required referenced data must be valid.
> Compilation completes synchronously, including the plugin's cache callbacks.
> This is not an asynchronous job handle and does not create a GPU-executable
> device object. Completion does not imply a cross-file atomic commit, crash
> durability, or rollback of values stored before an error.

<!-- d3d12-review-alert:end:compiler-output:compilestateobject-completion:0 -->

<!-- d3d12-review-alert:begin:compiler-output:compilestateobject-completion:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `riid` selects `ID3D12CompilerStateObject` or a supported base interface.
> The output pointer is required writable storage, not a validation-only probe.
> The returned interface is an owned reference; release it when finished.
> An error before the final interface query need not clear the caller's output.
> The handle retains the compiler and internal construction data needed by
> dependent compilations. State-object compilation and addition require the
> negotiated build-2 compiler DDI support; otherwise they return `E_NOTIMPL`.

<!-- d3d12-review-alert:end:compiler-output:compilestateobject-completion:1 -->

<!-- d3d12-review-alert:begin:compiler-output:compilestateobject-completion:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A collection that produces no compiled output can return its compiler state
> object without registering output keys or creating a group. The input group
> key remains required. This exception does not apply to executable state-object
> compilation or incremental additions.

<!-- d3d12-review-alert:end:compiler-output:compilestateobject-completion:2 -->

<!-- d3d12-review-alert:begin:compiler-output:compilestateobject-validation-input:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A null `pGroupKey`, `pDesc` or `ppCompilerStateObject` returns `E_INVALIDARG`. The
> [compilation input and target-validation contract](#input-ownership)
> defines the required description forms and shared construction rules.

<!-- d3d12-review-alert:end:compiler-output:compilestateobject-validation-input:0 -->

### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilestateobject-parameter-source:0 -->`[in] pGroupKey`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilestateobject-parameter-source:0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilestateobject-parameter-source:1 -->A unique key that identifies the group.<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilestateobject-parameter-source:1 --></ins> This key is used to store a group with the values produced by this compiled operation.  This group must not already be present in the cache session.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilestateobject-parameter-source:2 -->`[in] GroupVersion`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilestateobject-parameter-source:2 --></ins>

The version number of the cached group.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilestateobject-parameter-source:4 -->`[in] pDesc`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilestateobject-parameter-source:4 --></ins>

Creation arguments for the state object.  See [D3D12_STATE_OBJECT_DESC](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_state_object_desc).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilestateobject-parameter-source:6 -->`[in] riid`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilestateobject-parameter-source:6 --></ins>

The globally unique identifier (GUID) for the new state object interface. See [ID3D12CompilerStateObject](#id3d12compiler-compilestateobject).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilestateobject-parameter-source:8 -->`[out] ppCompilerStateObject`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilestateobject-parameter-source:8 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilestateobject-parameter-source:9 -->On return, a pointer to the compiler state object interface specified by riid.<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilestateobject-parameter-source:9 --></ins>

### Return values

<!-- d3d12-review-alert:begin:compiler-output:id3d12compiler-compilestateobject-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` indicates successful validation and plugin completion. Description
> validation failures return `E_INVALIDARG`; unsupported target capabilities can return
> `DXGI_ERROR_UNSUPPORTED`. Allocation failures return `E_OUTOFMEMORY`.

<!-- d3d12-review-alert:end:compiler-output:id3d12compiler-compilestateobject-returns:0 -->

<!-- d3d12-review-alert:begin:compiler-output:id3d12compiler-compilestateobject-returns:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> An unsupported requested interface returns `E_NOINTERFACE`; the output pointer
> is required. That interface failure can occur after compilation and storage.

<!-- d3d12-review-alert:end:compiler-output:id3d12compiler-compilestateobject-returns:1 -->

<!-- d3d12-review-alert:begin:compiler-output:id3d12compiler-compilestateobject-returns:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Plugin compile failures preserve `E_OUTOFMEMORY`; other failing plugin compile
> results are translated to `DXGI_ERROR_DRIVER_INTERNAL_ERROR`. This is distinct
> from the cache callbacks' own results, which are returned to the plugin.
> The plugin must handle or propagate callback failures; a callback result is
> not necessarily the public compile call's final `HRESULT`. Missing required
> group-key registration also fails compilation with
> `DXGI_ERROR_DRIVER_INTERNAL_ERROR`. A collection with no compiled output may omit registration and have no group.
> Stored values can survive a failing compile.

<!-- d3d12-review-alert:end:compiler-output:id3d12compiler-compilestateobject-returns:2 -->

<a id="id3d12compiler-compileaddtostateobject"></a>

## ID3D12Compiler::CompileAddToStateObject

### Declaration

```cpp
HRESULT CompileAddToStateObject(
    const D3D12_COMPILER_CACHE_GROUP_KEY* pGroupKey,
    UINT GroupVersion,
    const D3D12_STATE_OBJECT_DESC* pAddition,
    ID3D12CompilerStateObject* pCompilerStateObjectToGrowFrom,
    REFIID riid,
    void** ppNewCompilerStateObject
);
```

### Behavior

Compiled output is stored via [ID3D12CompilerCacheSession::StoreValue](#id3d12compilercachesession-storevalue).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compileaddtostateobject-source:1 -->Compiler may sub-divide<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compileaddtostateobject-source:1 --></ins> objects in an IHV dependent way to support deduplication.  Therefore, multiple values may be stored per compile. <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compileaddtostateobject-source:1 -->The compiler may also check<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compileaddtostateobject-source:1 --></ins> for previously compiled duplicates.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compileaddtostateobject-source:2 -->On success, this method will not return until all compiled output is stored.<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compileaddtostateobject-source:2 --></ins>

The Group Key and Group Version are used to store a group that associates all the values stored for this compilation via [ID3D12CompilerCacheSession::StoreGroupValueKeys](#id3d12compilercachesession-storegroupvaluekeys).

This method creates an object that implements [ID3D12CompilerStateObject](#id3d12compiler-compilestateobject) to support using it as a base object when deriving new state objects with [ID3D12Compiler::CompileAddToStateObject](#id3d12compiler-compileaddtostateobject).

<!-- d3d12-review-alert:begin:compiler-output:compileaddtostateobject-completion:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The cache session's `GetValueTypes()` mask selects the output types; there is
> no value-type-flags argument on this API. The group key is required; the
> description and all required referenced data must be valid.
> Compilation completes synchronously, including the plugin's cache callbacks.
> This is not an asynchronous job handle and does not create a GPU-executable
> device object. Completion does not imply a cross-file atomic commit, crash
> durability, or rollback of values stored before an error.

<!-- d3d12-review-alert:end:compiler-output:compileaddtostateobject-completion:0 -->

<!-- d3d12-review-alert:begin:compiler-output:compileaddtostateobject-completion:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `riid` selects `ID3D12CompilerStateObject` or a supported base interface.
> The output pointer is required writable storage, not a validation-only probe.
> The returned interface is an owned reference; release it when finished.
> An error before the final interface query need not clear the caller's output.
> The handle retains the compiler and internal construction data needed by
> dependent compilations. State-object compilation and addition require the
> negotiated build-2 compiler DDI support; otherwise they return `E_NOTIMPL`.

<!-- d3d12-review-alert:end:compiler-output:compileaddtostateobject-completion:1 -->

<!-- d3d12-review-alert:begin:compiler-output:compileaddtostateobject-validation-input:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A null `pGroupKey`, `pAddition`, `pCompilerStateObjectToGrowFrom` or `ppNewCompilerStateObject` returns `E_INVALIDARG`. The
> [compilation input and target-validation contract](#input-ownership)
> defines the required description forms and shared construction rules.

<!-- d3d12-review-alert:end:compiler-output:compileaddtostateobject-validation-input:0 -->

<!-- d3d12-review-alert:begin:compiler-output:addition-parent:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pCompilerStateObjectToGrowFrom` is required and must have been created by this
> compiler. The result is a new compiler state object, not a replacement of the
> parent. Its description storage retains the parent description data. It does
> not retain the parent's API reference or guarantee the parent's plugin handle
> remains alive; the plugin retains the dependency state it needs.
> The application need not hold an addition-parent reference until the child is
> destroyed. Collections remain subject to their distinct application-retention
> rule.

<!-- d3d12-review-alert:end:compiler-output:addition-parent:0 -->

<!-- d3d12-review-alert:begin:compiler-output:addition-parent:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The base must permit additions under
> [`ALLOW_STATE_OBJECT_ADDITIONS`](state-objects.md#d3d12_state_object_flags),
> and the new description must satisfy the
> [growth and addition rules](state-objects.md#addtostateobject).

<!-- d3d12-review-alert:end:compiler-output:addition-parent:1 -->

ID3D12Device7::AddToStateObject allows an application developer to incrementally add to an existing state object during game runtime.

During offline compilation, <ins><!-- d3d12-review-inline:begin:compiler-output:offline-addition-rationale:1 -->CPU overhead<!-- d3d12-review-inline:end:compiler-output:offline-addition-rationale:1 --></ins> during compile is much less of an issue, so these incremental additions to a base state object instead could be factored as independent state objects.  However, this may result in higher runtime memory usage than the original extended state objects that may share state, so the compiler API and state object <ins><!-- d3d12-review-inline:begin:compiler-output:offline-addition-rationale:1 -->database continue<!-- d3d12-review-inline:end:compiler-output:offline-addition-rationale:1 --></ins> to support both.

### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:0 -->`[in] pGroupKey`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:1 -->A unique key that identifies the group.<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:1 --></ins> This key is used to store a group with the values produced by this compiled operation.  This group must not already be present in the cache session.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:2 -->`[in] GroupVersion`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:2 --></ins>

The version number of the cached group.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:4 -->`[in] pAddition`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:4 --></ins>

Addition arguments to add to pCompilerStateObjectToGrowFrom and create a new state object. See [D3D12_STATE_OBJECT_DESC](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_state_object_desc).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:6 -->`[in] pCompilerStateObjectToGrowFrom`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:6 --></ins>

The base state object to build from.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:8 -->`[in] riid`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:8 --></ins>

The globally unique identifier (GUID) for the new state object interface. See [ID3D12CompilerStateObject](#id3d12compiler-compilestateobject).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:10 -->`[out] ppNewCompilerStateObject`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:10 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:11 -->On return, a pointer to the compiler state object interface specified by riid.<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:11 --></ins>

### Return values

<!-- d3d12-review-alert:begin:compiler-output:id3d12compiler-compileaddtostateobject-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` indicates successful validation and plugin completion. Description
> validation failures return `E_INVALIDARG`; unsupported target capabilities can return
> `DXGI_ERROR_UNSUPPORTED`. Allocation failures return `E_OUTOFMEMORY`.

<!-- d3d12-review-alert:end:compiler-output:id3d12compiler-compileaddtostateobject-returns:0 -->

<!-- d3d12-review-alert:begin:compiler-output:id3d12compiler-compileaddtostateobject-returns:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> An unsupported requested interface returns `E_NOINTERFACE`; the output pointer
> is required. That interface failure can occur after compilation and storage.

<!-- d3d12-review-alert:end:compiler-output:id3d12compiler-compileaddtostateobject-returns:1 -->

<!-- d3d12-review-alert:begin:compiler-output:id3d12compiler-compileaddtostateobject-returns:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Plugin compile failures preserve `E_OUTOFMEMORY`; other failing plugin compile
> results are translated to `DXGI_ERROR_DRIVER_INTERNAL_ERROR`. This is distinct
> from the cache callbacks' own results, which are returned to the plugin.
> The plugin must handle or propagate callback failures; a callback result is
> not necessarily the public compile call's final `HRESULT`. Missing required
> group-key registration also fails compilation with
> `DXGI_ERROR_DRIVER_INTERNAL_ERROR`.
> Stored values can survive a failing compile.

<!-- d3d12-review-alert:end:compiler-output:id3d12compiler-compileaddtostateobject-returns:2 -->

<a id="id3d12compiler-getcachesession"></a>

## ID3D12Compiler::GetCacheSession

### Declaration

```cpp
HRESULT GetCacheSession(
    REFIID riid,
    void** ppCompilerCacheSession
);
```

### Behavior

<!-- d3d12-review-alert:begin:compiler-output:id3d12compiler-getcachesession-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns the cache session used to create this compiler.

<!-- d3d12-review-alert:end:compiler-output:id3d12compiler-getcachesession-behavior:0 -->

### Parameters

<!-- d3d12-review-alert:begin:compiler-output:id3d12compiler-getcachesession-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `[in] riid`

<!-- d3d12-review-alert:end:compiler-output:id3d12compiler-getcachesession-parameters:0 -->

<!-- d3d12-review-alert:begin:compiler-output:id3d12compiler-getcachesession-parameters:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Selects the requested interface.

<!-- d3d12-review-alert:end:compiler-output:id3d12compiler-getcachesession-parameters:1 -->

<!-- d3d12-review-alert:begin:compiler-output:id3d12compiler-getcachesession-parameters:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `[out] ppCompilerCacheSession`

<!-- d3d12-review-alert:end:compiler-output:id3d12compiler-getcachesession-parameters:2 -->

<!-- d3d12-review-alert:begin:compiler-output:id3d12compiler-getcachesession-parameters:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Required writable storage for the owned interface reference returned on success.

<!-- d3d12-review-alert:end:compiler-output:id3d12compiler-getcachesession-parameters:3 -->

### Return values

<!-- d3d12-review-alert:begin:compiler-output:id3d12compiler-getcachesession-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` returns an owned reference to the requested session interface;
> `E_NOINTERFACE` reports an unsupported `riid`. A null output pointer is not a
> probe and returns `E_POINTER` at the interface query. That query clears a
> valid output slot on unsupported-interface failure.

<!-- d3d12-review-alert:end:compiler-output:id3d12compiler-getcachesession-returns:0 -->

<a id="id3d12compilerstateobject-getcompiler"></a>

## ID3D12CompilerStateObject::GetCompiler

### Declaration

```cpp
HRESULT GetCompiler(
    REFIID riid,
    void** ppCompiler
);
```

### Behavior

<!-- d3d12-review-alert:begin:compiler-output:id3d12compilerstateobject-getcompiler-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns the compiler that created this compiler state object.

<!-- d3d12-review-alert:end:compiler-output:id3d12compilerstateobject-getcompiler-behavior:0 -->

### Parameters

<!-- d3d12-review-alert:begin:compiler-output:id3d12compilerstateobject-getcompiler-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `[in] riid`

<!-- d3d12-review-alert:end:compiler-output:id3d12compilerstateobject-getcompiler-parameters:0 -->

<!-- d3d12-review-alert:begin:compiler-output:id3d12compilerstateobject-getcompiler-parameters:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Selects the requested interface.

<!-- d3d12-review-alert:end:compiler-output:id3d12compilerstateobject-getcompiler-parameters:1 -->

<!-- d3d12-review-alert:begin:compiler-output:id3d12compilerstateobject-getcompiler-parameters:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `[out] ppCompiler`

<!-- d3d12-review-alert:end:compiler-output:id3d12compilerstateobject-getcompiler-parameters:2 -->

<!-- d3d12-review-alert:begin:compiler-output:id3d12compilerstateobject-getcompiler-parameters:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Required writable storage for the owned interface reference returned on success.

<!-- d3d12-review-alert:end:compiler-output:id3d12compilerstateobject-getcompiler-parameters:3 -->

### Return values

<!-- d3d12-review-alert:begin:compiler-output:id3d12compilerstateobject-getcompiler-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` returns an owned reference to the compiler selected by `riid`;
> `E_NOINTERFACE` reports an unsupported interface. A null output pointer is not
> a probe and returns `E_POINTER` at the interface query. That query clears a
> valid output slot on unsupported-interface failure.

<!-- d3d12-review-alert:end:compiler-output:id3d12compilerstateobject-getcompiler-returns:0 -->

<a id="id3d12compilercachesession-findgroup"></a>

## ID3D12CompilerCacheSession::FindGroup

### Declaration

```cpp
HRESULT FindGroup(
    const D3D12_COMPILER_CACHE_GROUP_KEY* pGroupKey,
    UINT* pGroupVersion
);
```

### Behavior

Check if a group with pGroupKey is in the database.  Optionally retrieve the version number of the group.

Returns S_OK when the group exists and DXGI_ERROR_NOT_FOUND if it does not.

GroupVersion is used to match State Object definitions in an SODB with a group of compiled binaries in a PSDB.  Only one version of a group with a given key may be stored in a PSDB at a time.

<!-- d3d12-review-alert:begin:compiler-output:findgroup-output:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pGroupKey` is required. A null `pGroupVersion` is a valid existence-only
> query. On a successful version query the output receives the stored group
> version. Failure does not promise a zero-initialized version output.
> Finding the group entry does not prove its referenced typed values exist.
> The group lookup uses the common mapping represented by the session's first
> database; callers combining existing files must supply consistent mappings.

<!-- d3d12-review-alert:end:compiler-output:findgroup-output:0 -->

### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroup-parameter-source:0 -->`[in] pGroupKey`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroup-parameter-source:0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroup-parameter-source:1 -->A unique key that identifies the group.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroup-parameter-source:1 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroup-parameter-source:2 -->`[out, optional] pGroupVersion`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroup-parameter-source:2 --></ins>

Specify a non-null pointer to receive the version number of the group.  <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroup-parameter-source:3 -->See Behavior.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroup-parameter-source:3 --></ins>

### Return values

<!-- d3d12-review-alert:begin:compiler-output:id3d12compilercachesession-findgroup-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` means the group entry exists. `DXGI_ERROR_NOT_FOUND` means it was not
> found. Database failures can also be returned; a failure does not initialize
> `pGroupVersion` to zero.

<!-- d3d12-review-alert:end:compiler-output:id3d12compilercachesession-findgroup-returns:0 -->

<a id="id3d12compilercachesession-findgroupvaluekeys"></a>

## ID3D12CompilerCacheSession::FindGroupValueKeys

### Declaration

```cpp
HRESULT FindGroupValueKeys(
    const D3D12_COMPILER_CACHE_GROUP_KEY* pGroupKey,
    const UINT* pExpectedGroupVersion,
    D3D12CompilerCacheSessionGroupValueKeysFunc CallbackFunc,
    void* pContext
);
```

### Behavior

Looks up a group entry in the cache whose key exactly matches the provided key and version and provides the list of value keys in the group to a callback.

DXGI_ERROR_NOT_FOUND is returned if <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvaluekeys-source:1 -->a group with pGroupKey<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvaluekeys-source:1 --></ins> and the appropriate version is not found.

Use a nullptr callback to determine if the group is present in the cache without actually retrieving the group keys.  This does not guarantee that the value keys are present in the cache, see [ID3D12CompilerCacheSession::FindGroupValues](#id3d12compilercachesession-findgroupvalues).

<!-- d3d12-review-alert:begin:compiler-output:group-key-probe-frontier:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `CallbackFunc` may be null to probe the group without retrieving its keys.
> The optional expected version is checked in either mode. A missing group or
> version mismatch returns `DXGI_ERROR_NOT_FOUND`; the probe does not certify
> that the referenced values exist.

<!-- d3d12-review-alert:end:compiler-output:group-key-probe-frontier:0 -->

<!-- d3d12-review-alert:begin:compiler-output:group-key-probe-frontier:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> With a callback, each key is borrowed only until that invocation returns.
> No stable enumeration order across separate calls is specified.
> `pExpectedGroupVersion` may be null to omit the version test; otherwise it
> supplies the expected `UINT` version, not a field embedded in `pGroupKey`.

<!-- d3d12-review-alert:end:compiler-output:group-key-probe-frontier:1 -->

### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvaluekeys-parameter-source:0 -->`[in] pGroupKey`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvaluekeys-parameter-source:0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvaluekeys-parameter-source:1 -->A unique key that identifies the group.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvaluekeys-parameter-source:1 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvaluekeys-parameter-source:2 -->`[in, optional] pExpectedGroupVersion`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvaluekeys-parameter-source:2 --></ins>

Optionally specify the version of the Group specified by pGroupKey expected in the database.  Used to fail early without reading the value keys when the version is not the expected version.  In this case of a version mismatch, DXGI_ERROR_NOT_FOUND is returned.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvaluekeys-parameter-source:4 -->`[in, optional] CallbackFunc`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvaluekeys-parameter-source:4 --></ins>

A D3D12CompilerCacheSessionGroupValueKeysFunc that is called once for each value key in the group.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvaluekeys-parameter-source:6 -->`[in, out, optional] pContext`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvaluekeys-parameter-source:6 --></ins>

An application specified context pointer that is passed to the callback.  Use this to pass parameters to the callback function that receives the value keys.

### Return values

<!-- d3d12-review-alert:begin:compiler-output:id3d12compilercachesession-findgroupvaluekeys-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` reports a matching group/key enumeration or null-callback probe;
> `DXGI_ERROR_NOT_FOUND` reports a missing group or version mismatch.
> Database failures can propagate. A successful key probe does not prove
> referenced values exist.

<!-- d3d12-review-alert:end:compiler-output:id3d12compilercachesession-findgroupvaluekeys-returns:0 -->

<a id="id3d12compilercachesession-findgroupvalues"></a>

## ID3D12CompilerCacheSession::FindGroupValues

### Declaration

```cpp
HRESULT FindGroupValues(
    const D3D12_COMPILER_CACHE_GROUP_KEY* pGroupKey,
    const UINT* pExpectedGroupVersion,
    D3D12_COMPILER_VALUE_TYPE_FLAGS ValueTypeFlags,
    D3D12CompilerCacheSessionGroupValuesFunc CallbackFunc,
    void* pContext
);
```

### Behavior

Looks up a group entry in the cache whose key exactly matches the provided key and version and provides the list of values in the group to a callback.

DXGI_ERROR_NOT_FOUND is returned if <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvalues-source:1 -->a group with pGroupKey<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvalues-source:1 --></ins> and the appropriate version is not found.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvalues-source:2 -->This method directly retrieves stored matching typed values from the backing databases. It is not equivalent to requiring a successful FindValue for every key returned by FindGroupValueKeys; keys without selected stored values are omitted.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvalues-source:2 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvalues-source:3 -->Use a nullptr callback to determine whether matching selected stored values of the group are present without retrieving their buffers.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvalues-source:3 --></ins>

<!-- d3d12-review-alert:begin:compiler-output:group-values-frontier:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `ValueTypeFlags` must be nonzero, contain only declared value-type bits, and
> select only types assigned to this session. Invalid masks return
> `E_INVALIDARG`. `CallbackFunc` may be null to probe without retrieving value
> buffers; the same group/version and selected-row tests apply.

<!-- d3d12-review-alert:end:compiler-output:group-values-frontier:0 -->

<!-- d3d12-review-alert:begin:compiler-output:group-values-frontier:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This is a sparse enumeration of stored selected typed values. A group can
> reference keys A and B while only A has selected stored values. A query of
> that backing database can return `S_OK` and enumerate A without reporting B.
> An absent selected type does not receive a synthetic callback. Neither a null
> callback probe nor `S_OK` certifies every group key or every requested type.

<!-- d3d12-review-alert:end:compiler-output:group-values-frontier:1 -->

<!-- d3d12-review-alert:begin:compiler-output:group-values-frontier:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The lookup queries each backing database assigned at least one selected type.
> Each backing query returns `S_OK` when it finds at least one matching selected
> row, or `DXGI_ERROR_NOT_FOUND` when it finds none, including when the group or
> expected version does not match. The overall call fails if any queried backing
> database fails. Other backing queries can already have delivered callbacks.
> Success in one database does not override a failure in another, and no generic
> error-priority or rollback guarantee is established.

<!-- d3d12-review-alert:end:compiler-output:group-values-frontier:2 -->

<!-- d3d12-review-alert:begin:compiler-output:group-values-frontier:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `ValueKeyIndex` is a dense rank over the value keys represented by the filtered
> selected rows of that backing query, starting at zero. A key with no selected
> rows is absent from that rank; changing the type filter or stored rows can
> renumber later keys. The index groups typed values within that enumeration.
> It does not identify a key across queries, databases or a separate
> `FindGroupValueKeys` enumeration.

<!-- d3d12-review-alert:end:compiler-output:group-values-frontier:3 -->

### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:0 -->`[in] pGroupKey`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:1 -->A unique key that identifies the group.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:1 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:2 -->`[in, optional] pExpectedGroupVersion`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:2 --></ins>

Optionally specify the version of the Group specified by pGroupKey expected in the database.  Used to fail early without reading the values when the version is not the expected version.  In this case of a version mismatch, DXGI_ERROR_NOT_FOUND is returned.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:4 -->`[in] ValueTypeFlags`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:4 --></ins>

Specify which values are retrieved from the cache session and passed to the D3D12CompilerCacheSessionGroupValuesFunc callback.  <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:5 -->Types not included in this flags parameter are not retrieved.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:5 --></ins>  Used as a performance optimization to prevent retrieval of unused values.  See [D3D12_COMPILER_VALUE_TYPE_FLAGS](#d3d12_compiler_value_type_flags).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:6 -->`[in, optional] CallbackFunc`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:6 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:7 -->A D3D12CompilerCacheSessionGroupValuesFunc that is called once for each selected stored typed value in the group.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:7 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:8 -->`[in, out, optional] pContext`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:8 --></ins>

An application specified context pointer that is passed to the callback.  Use this to pass parameters to the callback function that receives the values.

### Return values

<!-- d3d12-review-alert:begin:compiler-output:id3d12compilercachesession-findgroupvalues-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Each queried backing database returns `S_OK` if it has matching selected rows,
> or `DXGI_ERROR_NOT_FOUND` if it has none. The overall call succeeds only if
> all queried databases succeed; a failing query does not undo callbacks from
> other databases. Invalid masks return `E_INVALIDARG`. Other database failures
> can propagate. `S_OK` is sparse-enumeration success, not complete-group
> certification; a null callback is a legal probe with the same result rules.

<!-- d3d12-review-alert:end:compiler-output:id3d12compilercachesession-findgroupvalues-returns:0 -->

<a id="id3d12compilercachesession-findvalue"></a>

## ID3D12CompilerCacheSession::FindValue

### Declaration

```cpp
HRESULT FindValue(
    const D3D12_COMPILER_CACHE_VALUE_KEY* pValueKey,
    D3D12_COMPILER_CACHE_TYPED_VALUE* pTypedValues,
    UINT NumTypedValues,
    D3D12CompilerCacheSessionAllocationFunc pCallbackFunc,
    void* pContext
);
```

### Behavior

Find a previously stored value in the cache.

Each D3D12_COMPILER_CACHE_TYPED_VALUE has a D3D12_COMPILER_CACHE_VALUE.  On input, each D3D12_COMPILER_CACHE_VALUE ValueSize member specifies the size in bytes of the buffer pointed to by pValue. Use zero when querying size or using the allocation callback. On output, the ValueSize member is assigned the size of the value.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findvalue-source:2 -->When a value is found, for each requested D3D12_COMPILER_CACHE_VALUE:<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findvalue-source:2 --></ins>

- If the ValueSize member is a non-zero value, the pValue member must point to a buffer of that size.  If ValueSize is greater than or equal to the value's actual size, the value is copied to pValue and the ValueSize member is assigned the actual size of the value.  If the caller specified ValueSize is insufficient, DXGI_ERROR_MORE_DATA is returned and the required size is assigned to the ValueSize member.
- <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findvalue-source:3 -->If the ValueSize member is zero and pCallbackFunc is non-nullptr, pCallbackFunc is called to allocate a buffer and the value is copied into it.  The allocated buffer pointer returned by pCallbackFunc is assigned to the pValue member on return. If pCallbackFunc returns nullptr, the call fails and returns E_OUTOFMEMORY.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findvalue-source:3 --></ins>
- The ValueSize member is assigned the value's actual size before returning.

To determine if a particular value type is stored without retrieving the value, use a size check for the value. To perform a size check, use a nullptr pValue with a zero ValueSize for the types to query and a nullptr pCallbackFunc.  <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findvalue-source:4 -->Within one backing-database query, S_OK indicates that at least one requested value type is cached. DXGI_ERROR_NOT_FOUND indicates that none of that query's requested types is cached. The overall call fails if any queried backing database fails; successful output from another database can still be returned.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findvalue-source:4 --></ins>  ValueSize is non-zero for a cached value type.

Example using D3D12CompilerCacheSessionAllocationFunc to retrieve values:

```cpp

const char testKey[] = "TestKey";

const D3D12_COMPILER_CACHE_VALUE_KEY valueKey = { testKey, sizeof(testKey) };
D3D12_COMPILER_CACHE_TYPED_VALUE values[] = { {D3D12_COMPILER_VALUE_TYPE_OBJECT_CODE, {} }, {D3D12_COMPILER_VALUE_TYPE_METADATA, {} } };

HRESULT hr = pCompilerCacheSession->FindValue(
    &valueKey,
    values,
    ARRAYSIZE(values),
    [](size_t SizeInBytes, _Inout_opt_ void* /*pContext*/){return malloc(SizeInBytes);},
    nullptr // No calling context needed
    );

if (SUCCEEDED(hr))
{
    // Each nonzero returned size identifies a corresponding cached typed value.
}

// Use the deallocator that corresponds with allocation even when FindValue does not succeed.  For example, the first
// allocation may have succeeded, but a subsequent call to the allocation function may have failed resulting
// in FindValue returning E_OUTOFMEMORY.
free(values[0].Value.pValue);
free(values[1].Value.pValue);
```

<!-- d3d12-review-alert:begin:compiler-output:typed-value-results:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pValueKey` and the typed-value array must be valid for the call;
> `NumTypedValues` counts entries, not bytes. Each requested type must be a
> declared type assigned to a database in this session and may occur only once.
> Invalid, duplicate or unmapped types return `E_INVALIDARG`. Public API value
> sizes are byte counts of type `UINT`. An empty typed list is not a key-existence
> probe; request at least one named type to determine whether it is stored.

<!-- d3d12-review-alert:end:compiler-output:typed-value-results:0 -->

<!-- d3d12-review-alert:begin:compiler-output:typed-value-results:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A nonzero input capacity requires a non-null writable `pValue`. Zero capacity
> with no allocator requests only the size. Zero capacity with an allocator
> requests allocation even when the input `pValue` is null. The allocator receives
> the actual byte count and the caller's `pContext`; the returned pointer and
> actual size are assigned to that typed value.

<!-- d3d12-review-alert:end:compiler-output:typed-value-results:1 -->

<!-- d3d12-review-alert:begin:compiler-output:typed-value-results:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Results are per requested type. A missing type receives size zero. Within one
> backing-database query, finding at least one requested type gives `S_OK` if no
> capacity, allocation or storage error occurs, even if another requested type
> is absent. Finding none of that query's requested types gives
> `DXGI_ERROR_NOT_FOUND`; this does not imply that the key has no other types.

<!-- d3d12-review-alert:end:compiler-output:typed-value-results:2 -->

<!-- d3d12-review-alert:begin:compiler-output:typed-value-results:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The session queries only databases assigned requested types. The overall call
> fails if any queried database fails, including a database with none of its
> requested types. Other databases can still supply sizes, copied bytes or
> allocations. An overall failure does not discard those outputs. There is no
> global any-type-anywhere success rule, generic error-priority rule or atomic
> all-types output guarantee.

<!-- d3d12-review-alert:end:compiler-output:typed-value-results:3 -->

<!-- d3d12-review-alert:begin:compiler-output:typed-value-results:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> An undersized nonzero buffer returns `DXGI_ERROR_MORE_DATA` for that lookup and
> receives the required size without copying that value. Other typed values can
> still be copied or allocated. A null allocation result returns `E_OUTOFMEMORY`
> but does not reclaim earlier allocations. The caller must free every
> allocation it owns, including on failure.

<!-- d3d12-review-alert:end:compiler-output:typed-value-results:4 -->

### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findvalue-parameter-source:0 -->`[in] pValueKey`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findvalue-parameter-source:0 --></ins>

A unique sequence of bytes that uniquely identifies an object in the database.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findvalue-parameter-source:2 -->`[in, out] pTypedValues`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findvalue-parameter-source:2 --></ins>

An array of typed values to retrieve the size or values of during the operation.  The array size is specified by NumTypedValues.  See [D3D12_COMPILER_CACHE_TYPED_VALUE](#d3d12_compiler_cache_typed_value).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findvalue-parameter-source:4 -->`[in] NumTypedValues`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findvalue-parameter-source:4 --></ins>

The number of typed values in the pTypedValues array.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findvalue-parameter-source:6 -->`[in, optional] pCallbackFunc`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findvalue-parameter-source:6 --></ins>

An optional callback function for allocating value buffers.  <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findvalue-parameter-source:7 -->See Behavior.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findvalue-parameter-source:7 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findvalue-parameter-source:8 -->`[in, out, optional] pContext`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findvalue-parameter-source:8 --></ins>

An application specified context pointer that is passed to the callback.  Use this to pass parameters to the allocation callback function.

### Return values

<!-- d3d12-review-alert:begin:compiler-output:id3d12compilercachesession-findvalue-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK`, `DXGI_ERROR_NOT_FOUND`, `DXGI_ERROR_MORE_DATA`, `E_OUTOFMEMORY` and
> `E_INVALIDARG` have the per-type meanings above. Other database failures can
> propagate. A failing result does not imply untouched buffers, zero sizes or
> no successful allocations.

<!-- d3d12-review-alert:end:compiler-output:id3d12compilercachesession-findvalue-returns:0 -->

<a id="id3d12compilercachesession-getapplicationdesc"></a>

## ID3D12CompilerCacheSession::GetApplicationDesc

### Declaration

```cpp
const D3D12_APPLICATION_DESC* GetApplicationDesc();
```

### Behavior

Gets the application desc for this cache session.

This information is stored in the database.

The returned value (and contained strings) have the same lifetime as the ID3D12CompilerCacheSession cache session object.

### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-getapplicationdesc-parameter-source:0 -->None.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-getapplicationdesc-parameter-source:0 --></ins>

### Return values

<!-- d3d12-review-alert:begin:compiler-output:id3d12compilercachesession-getapplicationdesc-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns a borrowed, read-only pointer to the resolved application descriptor.
> The descriptor and its strings remain valid for the cache session's lifetime.
> This method has no `HRESULT` or allocation-transfer result.

<!-- d3d12-review-alert:end:compiler-output:id3d12compilercachesession-getapplicationdesc-returns:0 -->

<a id="id3d12compilercachesession-getcompilertarget"></a>

## ID3D12CompilerCacheSession::GetCompilerTarget

### Declaration

```cpp
D3D12_COMPILER_TARGET GetCompilerTarget();
```

### Behavior

Gets the Compiler Target used with this cache session.

This information is stored in the database.

### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-getcompilertarget-parameter-source:0 -->None.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-getcompilertarget-parameter-source:0 --></ins>

### Return values

<!-- d3d12-review-alert:begin:compiler-output:id3d12compilercachesession-getcompilertarget-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns the resolved target by value, including the nonzero resolved ABI and
> this factory's local family index. It has no `HRESULT` or caller-owned output
> buffer.

<!-- d3d12-review-alert:end:compiler-output:id3d12compilercachesession-getcompilertarget-returns:0 -->

<a id="id3d12compilercachesession-getvaluetypes"></a>

## ID3D12CompilerCacheSession::GetValueTypes

### Declaration

```cpp
D3D12_COMPILER_VALUE_TYPE_FLAGS GetValueTypes();
```

### Behavior

Reflects the value types used to create the cache session.

### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-getvaluetypes-parameter-source:0 -->None.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-getvaluetypes-parameter-source:0 --></ins>

### Return values

<!-- d3d12-review-alert:begin:compiler-output:id3d12compilercachesession-getvaluetypes-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns the union of value-type masks assigned to the session's database
> paths. It does not enumerate which individual values have already been stored
> and has no `HRESULT` result.

<!-- d3d12-review-alert:end:compiler-output:id3d12compilercachesession-getvaluetypes-returns:0 -->

<a id="id3d12compilercachesession-storevalue"></a>

## ID3D12CompilerCacheSession::StoreValue

### Declaration

```cpp
HRESULT StoreValue(
    const D3D12_COMPILER_CACHE_VALUE_KEY* pValueKey,
    const D3D12_COMPILER_CACHE_TYPED_CONST_VALUE* pTypedValues,
    UINT NumTypedValues
);
```

### Behavior

Add a key/value pair to the compiler cache.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storevalue-source:1 -->At least one value must be stored in the store operation, so the function returns E_INVALIDARG if pTypedValues is nullptr or NumTypedValues is zero. Each value must have a non-zero size.  Only one value per type may be stored at a time.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storevalue-source:1 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storevalue-source:2 -->This API returns<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storevalue-source:2 --></ins> DXGI_ERROR_ALREADY_EXISTS if one of the non-nullptr values <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storevalue-source:2 -->with pValueKey already exists<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storevalue-source:2 --></ins>.

<!-- d3d12-review-alert:begin:compiler-output:storevalue-routing-failure:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pValueKey` identifies a byte sequence; `KeySize` is its byte count, not a
> string-character count. The same key can have different typed values.
> `NumTypedValues` is an entry count. Each entry must select a declared, mapped
> type without duplicates and supply a non-null readable buffer of nonzero byte
> size. Invalid typed entries return `E_INVALIDARG`. A null `pTypedValues` or zero
> `NumTypedValues` must return `E_INVALIDARG`; neither is a legal empty store.
> The buffers remain caller-owned and are borrowed during the call.

<!-- d3d12-review-alert:end:compiler-output:storevalue-routing-failure:0 -->

<!-- d3d12-review-alert:begin:compiler-output:storevalue-routing-failure:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> An existing key with a previously absent type can receive that type. An
> already stored `(key, type)` conflicts with a repeated store even when its
> bytes match; this is not an overwrite or success-by-equality operation.
> Typed entries are routed to their assigned databases. Failure or duplication
> in one database does not roll back stores completed in another.

<!-- d3d12-review-alert:end:compiler-output:storevalue-routing-failure:1 -->

### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storevalue-parameter-source:0 -->`[in] pValueKey`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storevalue-parameter-source:0 --></ins>

A unique sequence of bytes that uniquely identifies an object in the database.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storevalue-parameter-source:2 -->`[in] pTypedValues`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storevalue-parameter-source:2 --></ins>

An array of typed values to store.  The array size is specified by NumTypedValues.  See [D3D12_COMPILER_CACHE_TYPED_CONST_VALUE](#d3d12_compiler_cache_typed_const_value).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storevalue-parameter-source:4 -->`[in] NumTypedValues`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storevalue-parameter-source:4 --></ins>

The number of values in the pTypedValues array.

### Return values

<!-- d3d12-review-alert:begin:compiler-output:id3d12compilercachesession-storevalue-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` reports a successful store. `DXGI_ERROR_ALREADY_EXISTS` reports an
> existing typed value; invalid typed arguments return `E_INVALIDARG`.
> Storage/allocation failures can propagate. Multi-file partial persistence is
> possible on failure; no universal rollback is promised.

<!-- d3d12-review-alert:end:compiler-output:id3d12compilercachesession-storevalue-returns:0 -->

<a id="id3d12compilercachesession-storegroupvaluekeys"></a>

## ID3D12CompilerCacheSession::StoreGroupValueKeys

### Declaration

```cpp
HRESULT StoreGroupValueKeys(
    const D3D12_COMPILER_CACHE_GROUP_KEY* pGroupKey,
    UINT GroupVersion,
    const D3D12_COMPILER_CACHE_VALUE_KEY* pValueKeys,
    UINT NumValueKeys
);
```

### Behavior

Stores a group of value keys in the cache.

This method does not check if the value keys in the group are present in the database.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storegroupvaluekeys-source:2 -->Group keys are application local.  It is only required that each state object's group key is unique to the application.  Each group has a Group Version that is revised to indicate the corresponding state object with this key has changed.  When PSDBs are generated, this version number is stored with the group of cached binaries for this group.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storegroupvaluekeys-source:2 --></ins>

Only one group with this key may be stored.  You cannot store multiple versions of a group in a single PSDB.

<!-- d3d12-review-alert:begin:compiler-output:storegroup-mapping:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pGroupKey` is required and supplies the application's group-key bytes.
> `GroupVersion` is a separate `UINT`. `pValueKeys` supplies `NumValueKeys`
> entries, each with its own key byte count; a valid group store requires a
> nonempty key list. The buffers remain caller-owned and readable for the call.
> The same group key cannot be inserted again with a new version or a different
> list; a duplicate returns `DXGI_ERROR_ALREADY_EXISTS`. This call does not
> replace existing mappings.

<!-- d3d12-review-alert:end:compiler-output:storegroup-mapping:0 -->

<!-- d3d12-review-alert:begin:compiler-output:storegroup-mapping:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The group mapping is stored in each database entry, including entries storing
> different value types. Mapping existence does not validate referenced values.
> Failure after writing one database can leave other mappings unchanged;
> the call does not establish an all-files transaction or repair mismatched
> mappings across existing files.

<!-- d3d12-review-alert:end:compiler-output:storegroup-mapping:1 -->

### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storegroupvaluekeys-parameter-source:0 -->`[in] pGroupKey`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storegroupvaluekeys-parameter-source:0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storegroupvaluekeys-parameter-source:1 -->A unique key that identifies the group.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storegroupvaluekeys-parameter-source:1 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storegroupvaluekeys-parameter-source:2 -->`[in] GroupVersion`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storegroupvaluekeys-parameter-source:2 --></ins>

The version number of the cached group.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storegroupvaluekeys-parameter-source:4 -->`[in] pValueKeys`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storegroupvaluekeys-parameter-source:4 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storegroupvaluekeys-parameter-source:5 -->An array of variable size keys in the group.  Each D3D12_COMPILER_CACHE_VALUE_KEY contains its own KeySize.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storegroupvaluekeys-parameter-source:5 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storegroupvaluekeys-parameter-source:6 -->`[in] NumValueKeys`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storegroupvaluekeys-parameter-source:6 --></ins>

The number of value keys in the group.

### Return values

<!-- d3d12-review-alert:begin:compiler-output:id3d12compilercachesession-storegroupvaluekeys-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` reports successful mapping storage. An existing group key returns
> `DXGI_ERROR_ALREADY_EXISTS`, irrespective of the proposed new version.
> Invalid lists or database failures can fail the call. Values need not exist,
> and failure does not imply a rollback of other databases.

<!-- d3d12-review-alert:end:compiler-output:id3d12compilercachesession-storegroupvaluekeys-returns:0 -->

<a id="invoked-ddi"></a>

## Compiler and cache DDI behavior

<!-- d3d12-review-alert:begin:compiler-output:ddi-ownership:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [compiler table](compiler-plugin-foundation.md#compiler-table-dependencies) and [cache callbacks](compiler-plugin-foundation.md#callback-dependencies) are declared in the plugin foundation. Build 2 additions use `D3D12DDIARG_ADD_TO_STATE_OBJECT_0072`, without an extra parent-handle parameter.

<!-- d3d12-review-alert:end:compiler-output:ddi-ownership:0 -->

<!-- d3d12-review-alert:begin:compiler-output:ddi-cache-session-handle:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12DDI_HRTCOMPILERCACHESESSION` is valid only during one compile call. `D3D12DDI_HCOMPILERSTATEOBJECT` instead retains plugin state for later additions.

<!-- d3d12-review-alert:end:compiler-output:ddi-cache-session-handle:0 -->

<!-- d3d12-review-alert:begin:compiler-output:ddi-cache-session-handle:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> DDI value kinds have the [API output meanings](#d3d12_compiler_value_type), with the declared DDI field widths.

<!-- d3d12-review-alert:end:compiler-output:ddi-cache-session-handle:2 -->

<a id="d3d12ddi_compiler_cache_value_type"></a>

### D3D12DDI_COMPILER_CACHE_VALUE_TYPE

<!-- d3d12-review-alert:begin:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_value_type:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Declaration:** [D3D12DDI_COMPILER_CACHE_VALUE_TYPE](compiler-plugin-foundation.md#callback-dependencies).

<!-- d3d12-review-alert:end:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_value_type:0 -->

A type enumeration used when only a single value type may be selected.

**Constants**

*D3D12DDI_COMPILER_CACHE_VALUE_TYPE_OBJECT_CODE*

Specifies object code.  The compiled executable code that is run on GPU.

*D3D12DDI_COMPILER_CACHE_VALUE_TYPE_METADATA*

Metadata that the compiler may provide about the compile.  For example it may store a compiler version number used for validation.  Such a thing should not be put inside of the object code as users of this system expect to be able to do memcmp diffing between compiler versions.

*D3D12DDI_COMPILER_CACHE_VALUE_TYPE_DEBUG_PDB*

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-type-prose-d3d12ddi_compiler_cache_value_type:7 -->The Debug PDB for the object code.  Used in pix and other debug scenarios.  An opaque blob that still requires IHV interpretation to be used with PIX.<!-- d3d12-review-inline:end:compiler-output:ddi-type-prose-d3d12ddi_compiler_cache_value_type:7 --></ins>

*D3D12DDI_COMPILER_CACHE_VALUE_TYPE_PERFORMANCE_DATA*

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-type-prose-d3d12ddi_compiler_cache_value_type:9 -->Performance data about the compile or produced object code.  An opaque blob that still requires IHV interpretation to be used with PIX.<!-- d3d12-review-inline:end:compiler-output:ddi-type-prose-d3d12ddi_compiler_cache_value_type:9 --></ins>

**Remarks**

Used when defining a typed value, see [D3D12DDI_COMPILER_CACHE_TYPED_VALUE](compiler-plugin-foundation.md#callback-dependencies).

<a id="d3d12ddi_compiler_value_type_flags"></a>

### D3D12DDI_COMPILER_VALUE_TYPE_FLAGS

<!-- d3d12-review-alert:begin:compiler-output:ddi-type-link-d3d12ddi_compiler_value_type_flags:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Declaration:** [D3D12DDI_COMPILER_VALUE_TYPE_FLAGS](compiler-plugin-foundation.md#callback-dependencies).

<!-- d3d12-review-alert:end:compiler-output:ddi-type-link-d3d12ddi_compiler_value_type_flags:0 -->

A flags enumeration used where multiple values may be selected.

**Constants**

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-type-prose-d3d12ddi_compiler_value_type_flags:2 -->*D3D12DDI_COMPILER_CACHE_VALUE_TYPE_FLAG_NONE*<!-- d3d12-review-inline:end:compiler-output:ddi-type-prose-d3d12ddi_compiler_value_type_flags:2 --></ins>

No selected value types.

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-type-prose-d3d12ddi_compiler_value_type_flags:4 -->*D3D12DDI_COMPILER_CACHE_VALUE_TYPE_FLAG_OBJECT_CODE*<!-- d3d12-review-inline:end:compiler-output:ddi-type-prose-d3d12ddi_compiler_value_type_flags:4 --></ins>

Indicates object code, see D3D12DDI_COMPILER_CACHE_VALUE_TYPE_OBJECT_CODE.

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-type-prose-d3d12ddi_compiler_value_type_flags:6 -->*D3D12DDI_COMPILER_CACHE_VALUE_TYPE_FLAG_METADATA*<!-- d3d12-review-inline:end:compiler-output:ddi-type-prose-d3d12ddi_compiler_value_type_flags:6 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-type-prose-d3d12ddi_compiler_value_type_flags:7 -->Selects compiler metadata.<!-- d3d12-review-inline:end:compiler-output:ddi-type-prose-d3d12ddi_compiler_value_type_flags:7 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-type-prose-d3d12ddi_compiler_value_type_flags:8 -->*D3D12DDI_COMPILER_CACHE_VALUE_TYPE_FLAG_DEBUG_PDB*<!-- d3d12-review-inline:end:compiler-output:ddi-type-prose-d3d12ddi_compiler_value_type_flags:8 --></ins>

Indicates Debug PDB, see D3D12DDI_COMPILER_CACHE_VALUE_TYPE_DEBUG_PDB.

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-type-prose-d3d12ddi_compiler_value_type_flags:10 -->*D3D12DDI_COMPILER_CACHE_VALUE_TYPE_FLAG_PERFORMANCE_DATA*<!-- d3d12-review-inline:end:compiler-output:ddi-type-prose-d3d12ddi_compiler_value_type_flags:10 --></ins>

Indicates Performance Data, see D3D12DDI_COMPILER_CACHE_VALUE_TYPE_PERFORMANCE_DATA.

**Remarks**

Example uses:

- <ins><!-- d3d12-review-inline:begin:compiler-output:ddi-type-prose-d3d12ddi_compiler_value_type_flags:14 -->Used for selecting which value types must be loaded/stored during [PFND3D12DDI_COMPILER_COMPILE_PIPELINE_STATE](#pfnd3d12ddi_compiler_compile_pipeline_state) and other compile operations.<!-- d3d12-review-inline:end:compiler-output:ddi-type-prose-d3d12ddi_compiler_value_type_flags:14 --></ins>

<a id="d3d12ddi_compiler_cache_value_key"></a>

### D3D12DDI_COMPILER_CACHE_VALUE_KEY

<!-- d3d12-review-alert:begin:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_value_key:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Declaration:** [D3D12DDI_COMPILER_CACHE_VALUE_KEY](compiler-plugin-foundation.md#callback-dependencies).

<!-- d3d12-review-alert:end:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_value_key:0 -->

**Members**

*pKey*

A unique sequence of bytes that uniquely identifies an object in the database.

*KeySize*

The size in bytes of pKey.

**Remarks**

Used during cache operations like find and store value to identify a value.

<a id="d3d12ddi_compiler_cache_value"></a>

### D3D12DDI_COMPILER_CACHE_VALUE

<!-- d3d12-review-alert:begin:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_value:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Declaration:** [D3D12DDI_COMPILER_CACHE_VALUE](compiler-plugin-foundation.md#callback-dependencies).

<!-- d3d12-review-alert:end:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_value:0 -->

Specifies a non-const value buffer and buffer size.

**Members**

*pValue*

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-type-prose-d3d12ddi_compiler_cache_value:3 -->A pointer to a memory buffer containing the value.<!-- d3d12-review-inline:end:compiler-output:ddi-type-prose-d3d12ddi_compiler_cache_value:3 --></ins>

*ValueSize*

The size of the pValue buffer in bytes.

**Remarks**

See also [D3D12DDI_COMPILER_CACHE_TYPED_VALUE](compiler-plugin-foundation.md#callback-dependencies).

<a id="d3d12ddi_compiler_cache_typed_value"></a>

### D3D12DDI_COMPILER_CACHE_TYPED_VALUE

<!-- d3d12-review-alert:begin:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_typed_value:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Declaration:** [D3D12DDI_COMPILER_CACHE_TYPED_VALUE](compiler-plugin-foundation.md#callback-dependencies).

<!-- d3d12-review-alert:end:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_typed_value:0 -->

Specifies a value and its type, such as object code, metadata etc.

**Members**

*Type*

The type of the value, such as object code, metadata, etc.  See [D3D12DDI_COMPILER_CACHE_VALUE_TYPE](#d3d12ddi_compiler_cache_value_type) for more information on types.

*Value*

The buffer and size for the value.  See [D3D12DDI_COMPILER_CACHE_VALUE](#d3d12ddi_compiler_cache_value).

**Remarks**

Used in DDI where the compiler may modify the value buffer, such as [PFND3D12DDI_COMPILER_CACHE_FIND_VALUE_CB](#pfnd3d12ddi_compiler_cache_find_value_cb).

<a id="d3d12ddi_compiler_cache_const_value"></a>

### D3D12DDI_COMPILER_CACHE_CONST_VALUE

<!-- d3d12-review-alert:begin:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_const_value:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Declaration:** [D3D12DDI_COMPILER_CACHE_CONST_VALUE](compiler-plugin-foundation.md#callback-dependencies).

<!-- d3d12-review-alert:end:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_const_value:0 -->

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-type-prose-d3d12ddi_compiler_cache_const_value:0 -->Specifies a const value buffer and buffer size.<!-- d3d12-review-inline:end:compiler-output:ddi-type-prose-d3d12ddi_compiler_cache_const_value:0 --></ins>

**Members**

*pValue*

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-type-prose-d3d12ddi_compiler_cache_const_value:3 -->A const pointer to a memory buffer containing the value.<!-- d3d12-review-inline:end:compiler-output:ddi-type-prose-d3d12ddi_compiler_cache_const_value:3 --></ins>

*ValueSize*

The size of the pValue buffer in bytes.

**Remarks**

See also [D3D12DDI_COMPILER_CACHE_TYPED_CONST_VALUE](compiler-plugin-foundation.md#callback-dependencies).

<a id="d3d12ddi_compiler_cache_typed_const_value"></a>

### D3D12DDI_COMPILER_CACHE_TYPED_CONST_VALUE

<!-- d3d12-review-alert:begin:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_typed_const_value:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Declaration:** [D3D12DDI_COMPILER_CACHE_TYPED_CONST_VALUE](compiler-plugin-foundation.md#callback-dependencies).

<!-- d3d12-review-alert:end:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_typed_const_value:0 -->

**Members**

*Type*

The type of the value, such as object code, metadata, etc.  See [D3D12DDI_COMPILER_CACHE_VALUE_TYPE](#d3d12ddi_compiler_cache_value_type) for more information on types.

*Value*

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-type-prose-d3d12ddi_compiler_cache_typed_const_value:4 -->The const buffer and size for the value.  See [D3D12DDI_COMPILER_CACHE_CONST_VALUE](#d3d12ddi_compiler_cache_const_value).<!-- d3d12-review-inline:end:compiler-output:ddi-type-prose-d3d12ddi_compiler_cache_typed_const_value:4 --></ins>

**Remarks**

Used in DDI where the compiler may not modify the value buffer, such as [PFND3D12DDI_COMPILER_CACHE_STORE_VALUE_CB](#pfnd3d12ddi_compiler_cache_store_value_cb).

<a id="d3d12ddi_compiler_cache_callbacks"></a>

### D3D12DDI_COMPILER_CACHE_CALLBACKS

<!-- d3d12-review-alert:begin:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_callbacks:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Declaration:** [D3D12DDI_COMPILER_CACHE_CALLBACKS](compiler-plugin-foundation.md#callback-dependencies).

<!-- d3d12-review-alert:end:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_callbacks:0 -->

**Members**

*pfnCompilerCacheFindValue*

See [PFND3D12DDI_COMPILER_CACHE_FIND_VALUE_CB](#pfnd3d12ddi_compiler_cache_find_value_cb).

*pfnCompilerCacheStoreValue*

See [PFND3D12DDI_COMPILER_CACHE_STORE_VALUE_CB](#pfnd3d12ddi_compiler_cache_store_value_cb).

*pfnCompilerCacheSetObjectValueKeys*

See [PFND3D12DDI_COMPILER_CACHE_SET_OBJECT_VALUE_KEYS_CB](#pfnd3d12ddi_compiler_cache_set_object_value_keys_cb).

<a id="d3d12ddi_hrtcompilercachesession"></a>

### D3D12DDI_HRTCOMPILERCACHESESSION

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-handle-cache-prose:0 -->The runtime's compiler cache session object.<!-- d3d12-review-inline:end:compiler-output:ddi-handle-cache-prose:0 --></ins>

**Remarks**

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-handle-cache-prose:2 -->This object is supplied during a compilation operation and must be used to call D3D12DDI_COMPILER_CACHE_CALLBACKS.  A given cache session handle is only valid and has the lifetime of a single compile DDI call.<!-- d3d12-review-inline:end:compiler-output:ddi-handle-cache-prose:2 --></ins>

<a id="d3d12ddi_hcompiler"></a>

### D3D12DDI_HCOMPILER

A compiler object is instanced <ins><!-- d3d12-review-inline:begin:compiler-output:ddi-compiler-object-concept:0 -->from an adapter<!-- d3d12-review-inline:end:compiler-output:ddi-compiler-object-concept:0 --></ins> family and application <ins><!-- d3d12-review-inline:begin:compiler-output:ddi-compiler-object-concept:0 -->identity.  It is used to<!-- d3d12-review-inline:end:compiler-output:ddi-compiler-object-concept:0 --></ins> compile state objects and store them in a cache session.

A handle type representing the plugin's compiler object.

<a id="d3d12ddi_hrtcompiler"></a>

### D3D12DDI_HRTCOMPILER

A handle type representing the runtime compiler object.  <ins><!-- d3d12-review-inline:begin:compiler-output:ddi-handle-runtime-prose:0 -->Allows compiler plugins<!-- d3d12-review-inline:end:compiler-output:ddi-handle-runtime-prose:0 --></ins> to call back into runtime.

<a id="d3d12ddi_hcompilerstateobject"></a>

### D3D12DDI_HCOMPILERSTATEOBJECT

A handle type representing the <ins><!-- d3d12-review-inline:begin:compiler-output:ddi-handle-state-object-prose:0 -->compiler plugin's state object<!-- d3d12-review-inline:end:compiler-output:ddi-handle-state-object-prose:0 --></ins>.  This object type allows compiler plugins to store state between Create and AddTo state object calls.

<a id="pfnd3d12ddi_compiler_calc_private_compiler_size"></a>

### PFND3D12DDI_COMPILER_CALC_PRIVATE_COMPILER_SIZE

<!-- d3d12-review-alert:begin:compiler-output:declaration-link-pfnd3d12ddi_compiler_calc_private_compiler_size:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Declaration:** [PFND3D12DDI_COMPILER_CALC_PRIVATE_COMPILER_SIZE](compiler-plugin-foundation.md#compiler-table-dependencies); [published header lines 356–360](../../spec-maintenance/d3d12/references/compiler-foundation-wdk-10.0.28000.2526.h#L356-L360).

<!-- d3d12-review-alert:end:compiler-output:declaration-link-pfnd3d12ddi_compiler_calc_private_compiler_size:0 -->

Determine the size of the driver compiler object.

**Parameters**

*pTarget*

Contains the adapter family and ABI version.  See [D3D12DDI_COMPILER_TARGET](compiler-plugin-foundation.md#ddi-target-descriptions).

*pApplicationDesc*

Describes the target application and version.  See [D3D12DDI_APPLICATION_DESC](compiler-plugin-foundation.md#d3d12ddi_application_desc).

**Remarks**

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_compiler_size:7 -->The memory for storing the plugin's CPU object representing the compiler is allocated by the caller. This method is used to calculate the plugin's object size.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_compiler_size:7 --></ins>

<a id="pfnd3d12ddi_compiler_create_compiler"></a>

### PFND3D12DDI_COMPILER_CREATE_COMPILER

<!-- d3d12-review-alert:begin:compiler-output:declaration-link-pfnd3d12ddi_compiler_create_compiler:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Declaration:** [PFND3D12DDI_COMPILER_CREATE_COMPILER](compiler-plugin-foundation.md#compiler-table-dependencies); [published header lines 362–368](../../spec-maintenance/d3d12/references/compiler-foundation-wdk-10.0.28000.2526.h#L362-L368).

<!-- d3d12-review-alert:end:compiler-output:declaration-link-pfnd3d12ddi_compiler_create_compiler:0 -->

Create the driver compiler object.

**Parameters**

*pTarget*

Contains the adapter family and ABI version.  See [D3D12DDI_COMPILER_TARGET](compiler-plugin-foundation.md#ddi-target-descriptions).

*pApplicationDesc*

Describes the target application and version.  See [D3D12DDI_APPLICATION_DESC](compiler-plugin-foundation.md#d3d12ddi_application_desc).

*hCompiler*

Handle for plugin compiler object.  Memory is allocated by the caller, and plugin places compiler object.

<!-- d3d12-review-alert:begin:compiler-output:ddi-create-runtime-handle:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `hRTCompiler` is the runtime compiler handle supplied to the plugin.
> The size query and create/destroy entries also receive the owning
> `hCompilerDDI` in the published ABI. The runtime allocates private object
> storage using the reported byte size; destruction ends the placed plugin
> object before that storage is reclaimed. The DDI create operation returns
> an `HRESULT`; a failed plugin creation fails compiler creation.

<!-- d3d12-review-alert:end:compiler-output:ddi-create-runtime-handle:0 -->

<a id="pfnd3d12ddi_compiler_destroy_compiler"></a>

### PFND3D12DDI_COMPILER_DESTROY_COMPILER

<!-- d3d12-review-alert:begin:compiler-output:declaration-link-pfnd3d12ddi_compiler_destroy_compiler:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Declaration:** [PFND3D12DDI_COMPILER_DESTROY_COMPILER](compiler-plugin-foundation.md#compiler-table-dependencies); [published header lines 370–373](../../spec-maintenance/d3d12/references/compiler-foundation-wdk-10.0.28000.2526.h#L370-L373).

<!-- d3d12-review-alert:end:compiler-output:declaration-link-pfnd3d12ddi_compiler_destroy_compiler:0 -->

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_destroy_compiler:0 -->Destroy the plugin object placed in the caller-provided private allocation. The caller reclaims that allocation after placement destruction.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_destroy_compiler:0 --></ins>

**Parameters**

*hCompiler*

Handle for plugin compiler object.

<a id="pfnd3d12ddi_compiler_compile_pipeline_state"></a>

### PFND3D12DDI_COMPILER_COMPILE_PIPELINE_STATE

<!-- d3d12-review-alert:begin:compiler-output:declaration-link-pfnd3d12ddi_compiler_compile_pipeline_state:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Declaration:** [PFND3D12DDI_COMPILER_COMPILE_PIPELINE_STATE](compiler-plugin-foundation.md#compiler-table-dependencies); [published header lines 375–380](../../spec-maintenance/d3d12/references/compiler-foundation-wdk-10.0.28000.2526.h#L375-L380).

<!-- d3d12-review-alert:end:compiler-output:declaration-link-pfnd3d12ddi_compiler_compile_pipeline_state:0 -->

Compile a graphics or compute pipeline state.

**Parameters**

*hCompiler*

Handle for plugin compiler object.

*hrtCompilerCacheSession*

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_pipeline_state:5 -->The compiler cache session callback handle.  Used with cache operations to find/store values and set the values associated with the object being compiled.  See [Cache Session Callbacks](#pfnd3d12ddi_compiler_cache_find_value_cb).<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_pipeline_state:5 --></ins>

*ValueTypeFlags*

Specify which values types to store in the cache session after compilation succeeds.  See [D3D12DDI_COMPILER_VALUE_TYPE_FLAGS](compiler-plugin-foundation.md#callback-dependencies).

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_pipeline_state:8 -->*pPipelineStateArg*<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_pipeline_state:8 --></ins>

Creation arguments for the pipeline state object to compile.

**Remarks**

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_pipeline_state:11 -->Compiled output is stored via the [PFND3D12DDI_COMPILER_CACHE_STORE_VALUE_CB](#pfnd3d12ddi_compiler_cache_store_value_cb) callback.  Check for previously compiled duplicates via the [PFND3D12DDI_COMPILER_CACHE_FIND_VALUE_CB](#pfnd3d12ddi_compiler_cache_find_value_cb) callback.  D3D12DDI_COMPILER_CACHE_CALLBACKS are installed before compiler creation through PFND3D12DDI_COMPILER_SET_CALLBACK_DDI_TABLE.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_pipeline_state:11 --></ins>

Compiler is expected to sub-divide objects in an IHV dependent way to support deduplication.  Multiple values may be stored per compile.

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_pipeline_state:13 -->On success, this method must not return until all compiled output is stored.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_pipeline_state:13 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_pipeline_state:14 -->The driver must call [PFND3D12DDI_COMPILER_CACHE_SET_OBJECT_VALUE_KEYS_CB](#pfnd3d12ddi_compiler_cache_set_object_value_keys_cb) once before returning success to set the values associated with this pipeline state object definition.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_pipeline_state:14 --></ins>

<a id="pfnd3d12ddi_compiler_calc_private_state_object_size"></a>

### PFND3D12DDI_COMPILER_CALC_PRIVATE_STATE_OBJECT_SIZE

<!-- d3d12-review-alert:begin:compiler-output:declaration-link-pfnd3d12ddi_compiler_calc_private_state_object_size:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Declaration:** [PFND3D12DDI_COMPILER_CALC_PRIVATE_STATE_OBJECT_SIZE](compiler-plugin-foundation.md#compiler-table-dependencies); [published header lines 382–385](../../spec-maintenance/d3d12/references/compiler-foundation-wdk-10.0.28000.2526.h#L382-L385).

<!-- d3d12-review-alert:end:compiler-output:declaration-link-pfnd3d12ddi_compiler_calc_private_state_object_size:0 -->

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_state_object_size:0 -->Calculate the size needed for compiler's state object implementation.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_state_object_size:0 --></ins>

**Parameters**

*hCompiler*

Handle for plugin compiler object.

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_state_object_size:4 -->*pCreateStateObject*<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_state_object_size:4 --></ins>

Creation arguments for the state object.

<a id="pfnd3d12ddi_compiler_compile_create_state_object"></a>

### PFND3D12DDI_COMPILER_COMPILE_CREATE_STATE_OBJECT

<!-- d3d12-review-alert:begin:compiler-output:declaration-link-pfnd3d12ddi_compiler_compile_create_state_object:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Declaration:** [PFND3D12DDI_COMPILER_COMPILE_CREATE_STATE_OBJECT](compiler-plugin-foundation.md#compiler-table-dependencies); [published header lines 387–393](../../spec-maintenance/d3d12/references/compiler-foundation-wdk-10.0.28000.2526.h#L387-L393).

<!-- d3d12-review-alert:end:compiler-output:declaration-link-pfnd3d12ddi_compiler_compile_create_state_object:0 -->

**Parameters**

*hCompiler*

Handle for plugin compiler object.

*hrtCompilerCacheSession*

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_create_state_object:4 -->The compiler cache session callback handle.  Used with cache operations to find/store values and set the values associated with the object being compiled.  See [Cache Session Callbacks](#pfnd3d12ddi_compiler_cache_find_value_cb).<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_create_state_object:4 --></ins>

*ValueTypeFlags*

Specify which values types to store in the cache session after compilation succeeds.  See [D3D12DDI_COMPILER_VALUE_TYPE_FLAGS](compiler-plugin-foundation.md#callback-dependencies).

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_create_state_object:7 -->*pCreateStateObject*<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_create_state_object:7 --></ins>

Creation arguments for the state object.

*hStateObject*

A handle pointing to the pre-allocated space for the compiler object.  Compiler places the object in this allocation and uses it to store state to support future calls to [PFND3D12DDI_COMPILER_COMPILE_ADD_TO_STATE_OBJECT](#pfnd3d12ddi_compiler_compile_add_to_state_object) calls.

**Remarks**

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_create_state_object:12 -->The lifetime of pCreateStateObject is guaranteed until hStateObject is destroyed; therefore, compiler only needs to store a pointer to this structure to support future AddToStateObject calls.  Compiler must store other state needed for future compilation with hStateObject, such as keys to lookup stored values.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_create_state_object:12 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_create_state_object:13 -->Compiled output is stored via the [PFND3D12DDI_COMPILER_CACHE_STORE_VALUE_CB](#pfnd3d12ddi_compiler_cache_store_value_cb) callback.  Check for previously compiled duplicates via the [PFND3D12DDI_COMPILER_CACHE_FIND_VALUE_CB](#pfnd3d12ddi_compiler_cache_find_value_cb) callback.  D3D12DDI_COMPILER_CACHE_CALLBACKS are installed before compiler creation through PFND3D12DDI_COMPILER_SET_CALLBACK_DDI_TABLE.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_create_state_object:13 --></ins>

Compiler is expected to sub-divide objects in an IHV dependent way to support deduplication.  Multiple values may be stored per compile.

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_create_state_object:15 -->On success, this method must not return until all compiled output is stored.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_create_state_object:15 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_create_state_object:16 -->The driver must call [PFND3D12DDI_COMPILER_CACHE_SET_OBJECT_VALUE_KEYS_CB](#pfnd3d12ddi_compiler_cache_set_object_value_keys_cb) once before returning success to set the values associated with this state object definition. A collection CompileStateObject that produces no compiled output may omit this callback and have no group.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_create_state_object:16 --></ins>

<!-- d3d12-review-alert:begin:compiler-output:ddi-collection-frontier:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A no-output collection may consequently have no output group. The exception
> does not apply to pipeline-state compilation, executable state-object
> compilation or additions.

<!-- d3d12-review-alert:end:compiler-output:ddi-collection-frontier:0 -->

<a id="pfnd3d12ddi_compiler_calc_private_add_to_state_object_size"></a>

### PFND3D12DDI_COMPILER_CALC_PRIVATE_ADD_TO_STATE_OBJECT_SIZE

<!-- d3d12-review-alert:begin:compiler-output:declaration-link-pfnd3d12ddi_compiler_calc_private_add_to_state_object_size:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Declaration:** [PFND3D12DDI_COMPILER_CALC_PRIVATE_ADD_TO_STATE_OBJECT_SIZE](compiler-plugin-foundation.md#compiler-table-dependencies); [published header lines 395–398](../../spec-maintenance/d3d12/references/compiler-foundation-wdk-10.0.28000.2526.h#L395-L398).

<!-- d3d12-review-alert:end:compiler-output:declaration-link-pfnd3d12ddi_compiler_calc_private_add_to_state_object_size:0 -->

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_add_to_state_object_size:0 -->Calculate the size needed for compiler's state object implementation when adding to an existing state object.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_add_to_state_object_size:0 --></ins>

**Parameters**

*hCompiler*

Handle for plugin compiler object.

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_add_to_state_object_size:4 -->*pAddToStateObject*<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_add_to_state_object_size:4 --></ins>

Creation arguments for the add operation.

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_add_to_state_object_size:6 -->The parent handle is carried in pAddToStateObject->StateObjectToGrowFrom.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_add_to_state_object_size:6 --></ins>

<a id="pfnd3d12ddi_compiler_compile_add_to_state_object"></a>

### PFND3D12DDI_COMPILER_COMPILE_ADD_TO_STATE_OBJECT

<!-- d3d12-review-alert:begin:compiler-output:declaration-link-pfnd3d12ddi_compiler_compile_add_to_state_object:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Declaration:** [PFND3D12DDI_COMPILER_COMPILE_ADD_TO_STATE_OBJECT](compiler-plugin-foundation.md#compiler-table-dependencies); [published header lines 400–406](../../spec-maintenance/d3d12/references/compiler-foundation-wdk-10.0.28000.2526.h#L400-L406).

<!-- d3d12-review-alert:end:compiler-output:declaration-link-pfnd3d12ddi_compiler_compile_add_to_state_object:0 -->

**Parameters**

*hCompiler*

Handle for plugin compiler object.

*hrtCompilerCacheSession*

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:4 -->The compiler cache session callback handle.  Used with cache operations to find/store values and set the values associated with the object being compiled.  See [Cache Session Callbacks](#pfnd3d12ddi_compiler_cache_find_value_cb).<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:4 --></ins>

*ValueTypeFlags*

Specify which values types to store in the cache session after compilation succeeds.  See [D3D12DDI_COMPILER_VALUE_TYPE_FLAGS](compiler-plugin-foundation.md#callback-dependencies).

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:7 -->*pAddToStateObject*<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:7 --></ins>

Creation arguments for the add operation.

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:9 -->The parent handle is carried in pAddToStateObject->StateObjectToGrowFrom.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:9 --></ins>

*hStateObject*

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:11 -->A handle pointing to the pre-allocated space for the compiler object.  Compiler places the object in this allocation and uses it to store state to support future AddToStateObject calls.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:11 --></ins>

**Remarks**

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:13 -->The pAddToStateObject description remains valid until hStateObject is destroyed, so the compiler can retain a pointer to that description for later additions. The StateObjectToGrowFrom plugin handle need not remain alive with the child; the plugin must retain the dependency state it needs.  Compiler must store other state needed for future compilation with hStateObject, such as keys to lookup stored values.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:13 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:14 -->Compiled output is stored via PFND3D12DDI_COMPILER_CACHE_STORE_VALUE_CB.  Check for previously compiled duplicates via PFND3D12DDI_COMPILER_CACHE_FIND_VALUE_CB.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:14 --></ins>

Compiler is expected to sub-divide objects in an IHV dependent way to support deduplication.  Multiple values may be stored per compile.

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:16 -->On success, this method must not return until all compiled output is stored.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:16 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:17 -->The driver must call [PFND3D12DDI_COMPILER_CACHE_SET_OBJECT_VALUE_KEYS_CB](#pfnd3d12ddi_compiler_cache_set_object_value_keys_cb) once before returning success to set the values associated with this state object definition.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:17 --></ins>

<a id="pfnd3d12ddi_compiler_destroy_state_object"></a>

### PFND3D12DDI_COMPILER_DESTROY_STATE_OBJECT

<!-- d3d12-review-alert:begin:compiler-output:declaration-link-pfnd3d12ddi_compiler_destroy_state_object:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Declaration:** [PFND3D12DDI_COMPILER_DESTROY_STATE_OBJECT](compiler-plugin-foundation.md#compiler-table-dependencies); [published header lines 408–411](../../spec-maintenance/d3d12/references/compiler-foundation-wdk-10.0.28000.2526.h#L408-L411).

<!-- d3d12-review-alert:end:compiler-output:declaration-link-pfnd3d12ddi_compiler_destroy_state_object:0 -->

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_destroy_state_object:0 -->Destroys the compiler state object placed in the caller-provided private allocation. The caller reclaims the allocation after the plugin destroys its placed object.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_destroy_state_object:0 --></ins>

**Parameters**

*hCompiler*

Handle for plugin compiler object.

*hStateObject*

The state object to destroy.

<a id="pfnd3d12ddi_compiler_cache_find_value_cb"></a>

### PFND3D12DDI_COMPILER_CACHE_FIND_VALUE_CB

<!-- d3d12-review-alert:begin:compiler-output:declaration-link-pfnd3d12ddi_compiler_cache_find_value_cb:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Declaration:** [PFND3D12DDI_COMPILER_CACHE_FIND_VALUE_CB](compiler-plugin-foundation.md#callback-dependencies); [published header lines 236–243](../../spec-maintenance/d3d12/references/compiler-foundation-wdk-10.0.28000.2526.h#L236-L243).

<!-- d3d12-review-alert:end:compiler-output:declaration-link-pfnd3d12ddi_compiler_cache_find_value_cb:0 -->

Find a previously stored value in the cache.

**Parameters**

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_cache_find_value_cb:2 -->*hrtCompilerCache*<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_cache_find_value_cb:2 --></ins>

The compiler cache session  callback handle received during a compilation operation.

*pValueKey*

The unique identifier for the value.  See [D3D12DDI_COMPILER_CACHE_VALUE_KEY](compiler-plugin-foundation.md#callback-dependencies).

*pValues*

An array of typed values to retrieve the size or values of during the operation.  The array size is specified by NumValues.  See [D3D12DDI_COMPILER_CACHE_TYPED_VALUE](compiler-plugin-foundation.md#callback-dependencies).

*NumValues*

The number of values in the pValues array.

*pCallbackFunc*

An optional callback function for allocating value buffers.  See Remarks.

*pContext*

A compiler plugin specified context pointer that is passed to the callback.  Use this to pass parameters to the allocation callback function.

**Remarks**

Each D3D12DDI_COMPILER_CACHE_TYPED_VALUE has a D3D12DDI_COMPILER_CACHE_VALUE.  On input, each D3D12DDI_COMPILER_CACHE_VALUE ValueSize member specifies the size in bytes of the buffer pointed to by pValue. Use zero when querying size or using the allocation callback. On output, the ValueSize member is assigned the size of the value.

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_cache_find_value_cb:16 -->When a value is found, for each requested D3D12DDI_COMPILER_CACHE_VALUE:<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_cache_find_value_cb:16 --></ins>

- If the ValueSize member is a non-zero value, the pValue member must point to a buffer of that size.  If ValueSize is greater than or equal to the value's actual size, the value is copied to pValue and the ValueSize member is assigned the actual size of the value.  If the caller specified ValueSize is insufficient, DXGI_ERROR_MORE_DATA is returned and the required size is assigned to the ValueSize member.
- <ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_cache_find_value_cb:17 -->If the ValueSize member is zero and pCallbackFunc is non-nullptr, pCallbackFunc is called to allocate a buffer and the value is copied into it.  The allocated buffer pointer returned by pCallbackFunc is assigned to the pValue member on return. If pCallbackFunc returns nullptr, the call fails and returns E_OUTOFMEMORY.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_cache_find_value_cb:17 --></ins>
- The ValueSize member is assigned the value's actual size before returning.

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_cache_find_value_cb:18 -->To determine if a particular value type is stored without retrieving the value, use a size check for the value. To perform a size check, use a nullptr pValue with a zero ValueSize for the types to query and a nullptr pCallbackFunc.  Within one backing-database query, S_OK indicates that at least one requested value type is cached. DXGI_ERROR_NOT_FOUND indicates that none of that query's requested types is cached. The overall call fails if any queried backing database fails; successful output from another database can still be returned.  ValueSize is non-zero for a cached value type.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_cache_find_value_cb:18 --></ins>

<!-- d3d12-review-alert:begin:compiler-output:ddi-find-results:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The callback uses the [FindValue result and buffer protocol](#id3d12compilercachesession-findvalue). Its allocator must return suitably aligned storage or null and must not let exceptions escape. The plugin frees successful allocations, including those made before a later lookup failure.

<!-- d3d12-review-alert:end:compiler-output:ddi-find-results:0 -->

<a id="pfnd3d12ddi_compiler_cache_store_value_cb"></a>

### PFND3D12DDI_COMPILER_CACHE_STORE_VALUE_CB

<!-- d3d12-review-alert:begin:compiler-output:declaration-link-pfnd3d12ddi_compiler_cache_store_value_cb:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Declaration:** [PFND3D12DDI_COMPILER_CACHE_STORE_VALUE_CB](compiler-plugin-foundation.md#callback-dependencies); [published header lines 245–250](../../spec-maintenance/d3d12/references/compiler-foundation-wdk-10.0.28000.2526.h#L245-L250).

<!-- d3d12-review-alert:end:compiler-output:declaration-link-pfnd3d12ddi_compiler_cache_store_value_cb:0 -->

Add a key/value pair to the compiler cache.

**Parameters**

*hrtCompilerCacheSession*

The compiler cache session  callback handle received during a compilation operation.

*pValueKey*

The unique identifier for the value.  See [D3D12DDI_COMPILER_CACHE_VALUE_KEY](compiler-plugin-foundation.md#callback-dependencies).

*pValues*

An array of typed values to store.  The array size is specified by NumValues.  See [D3D12DDI_COMPILER_CACHE_TYPED_CONST_VALUE](compiler-plugin-foundation.md#callback-dependencies).

*NumValues*

The number of values in the pValues array.

**Remarks**

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_cache_store_value_cb:11 -->At least one value must be stored in the store operation, so the function returns E_INVALIDARG if pValues is nullptr or NumValues is zero.  Each value must have a non-zero size.  Only one value per type may be stored at a time.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_cache_store_value_cb:11 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_cache_store_value_cb:12 -->This callback returns DXGI_ERROR_ALREADY_EXISTS if one of the non-nullptr values with pValueKey already exists.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_cache_store_value_cb:12 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_cache_store_value_cb:13 -->Flags during the compile operation indicate which values must be stored.  See [D3D12DDI_COMPILER_VALUE_TYPE_FLAGS](compiler-plugin-foundation.md#callback-dependencies).  Values are optionally stored to accommodate various scenarios such as generating PDB for existing object code with a matching compiler and source or Shader Explorer only needing the performance data output.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_cache_store_value_cb:13 --></ins>

<!-- d3d12-review-alert:begin:compiler-output:ddi-store-results:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Before successful compilation, requested value kinds must be available through the cache callbacks. The plugin may store types separately or reuse stored values. It handles store failures and need not undo earlier successful stores.

<!-- d3d12-review-alert:end:compiler-output:ddi-store-results:0 -->

<a id="pfnd3d12ddi_compiler_cache_set_object_value_keys_cb"></a>

### PFND3D12DDI_COMPILER_CACHE_SET_OBJECT_VALUE_KEYS_CB

<!-- d3d12-review-alert:begin:compiler-output:declaration-link-pfnd3d12ddi_compiler_cache_set_object_value_keys_cb:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Declaration:** [PFND3D12DDI_COMPILER_CACHE_SET_OBJECT_VALUE_KEYS_CB](compiler-plugin-foundation.md#callback-dependencies); [published header lines 252–256](../../spec-maintenance/d3d12/references/compiler-foundation-wdk-10.0.28000.2526.h#L252-L256).

<!-- d3d12-review-alert:end:compiler-output:declaration-link-pfnd3d12ddi_compiler_cache_set_object_value_keys_cb:0 -->

A callback to set the list of value keys associated with an object.

**Parameters**

*hrtCompilerCacheSession*

The compiler cache session  callback handle received during a compilation operation.

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_cache_set_object_value_keys_cb:4 -->*pValueKeys*<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_cache_set_object_value_keys_cb:4 --></ins>

The unique identifiers for the values.  See [D3D12DDI_COMPILER_CACHE_VALUE_KEY](compiler-plugin-foundation.md#callback-dependencies).

*NumValueKeys*

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_cache_set_object_value_keys_cb:7 -->The number of keys specified by pValueKeys.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_cache_set_object_value_keys_cb:7 --></ins>

**Remarks**

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_cache_set_object_value_keys_cb:9 -->This stored list specifies the values that the driver receives during title cooperative scenarios.  It may also be used for other database management operations to map values back to state object definitions.  The compiler plugin must call this function once before returning success from a compile operation. A collection CompileStateObject that produces no compiled output may omit this callback and have no group.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_cache_set_object_value_keys_cb:9 --></ins>

<!-- d3d12-review-alert:begin:compiler-output:ddi-group-completion:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The callback associates vendor-generated `pValueKeys` with the API application key and GroupVersion. Registration does not verify that all requested value kinds exist.

<!-- d3d12-review-alert:end:compiler-output:ddi-group-completion:0 -->

<!-- d3d12-review-alert:begin:compiler-output:ddi-group-completion:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The host accepts an already-existing-group result from this callback and returns other group-store failures to the plugin.

<!-- d3d12-review-alert:end:compiler-output:ddi-group-completion:1 -->

<a id="compilation-example"></a>

## Compilation example

This example demonstrates how to compile a Pipeline State Object (PSO) and store it in a Precompiled Shader Database (PSDB) using the State Object Compiler API.

```cpp
    //
    // Create the factory
    //

    Microsoft::WRL::ComPtr<ID3D12CompilerFactory> spFactory;
    VERIFY_SUCCEEDED(D3D12CompilerCreateFactory(CompilerPluginDll, IID_PPV_ARGS(&spFactory)));

    //
    // Cache output path and type
    //

    D3D12_COMPILER_VALUE_TYPE_FLAGS compileValues =
        D3D12_COMPILER_VALUE_TYPE_FLAGS_OBJECT_CODE | D3D12_COMPILER_VALUE_TYPE_FLAGS_METADATA;

    D3D12_COMPILER_DATABASE_PATH databasePath = { compileValues, L"out.psdb" };

    //
    // Target adapter family and ABI
    //

    // Use the first available adapter family.
    UINT AdapterFamilyIndex = 0;

    // Zero targets the latest available ABI version for this adapter family.
    UINT64 ABIVersion = 0;

    const D3D12_COMPILER_TARGET target =
    {
        AdapterFamilyIndex,
        ABIVersion
    };

    //
    //  Application metadata
    //

    constexpr D3D12_APPLICATION_DESC applicationDesc =
    {
        L"Sample.exe",                                  // pExeFilename
        L"Sample Application Title",                    // pName
        {1},                                            // Version
        L"Sample Engine Name",                          // pEngineName
        {7}                                             // EngineVersion
    };

    //
    // Create the Cache Session and Compiler
    //

    Microsoft::WRL::ComPtr<ID3D12CompilerCacheSession> spCompilerCacheSession;
    VERIFY_SUCCEEDED(spFactory->CreateCompilerCacheSession(
        &databasePath,
        1u, // NumPaths
        &target,
        &applicationDesc,
        IID_PPV_ARGS(&spCompilerCacheSession)
    ));

    Microsoft::WRL::ComPtr<ID3D12Compiler> spCompiler;
    VERIFY_SUCCEEDED(spFactory->CreateCompiler(
        spCompilerCacheSession.Get(),
        IID_PPV_ARGS(&spCompiler)));

    //
    // Prepare the PSO arguments.
    //

    const D3D12_INPUT_ELEMENT_DESC DefaultILDescs[1] =
    {
        { "POS", 0, DXGI_FORMAT_R32G32B32A32_FLOAT, 0, 0, D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 }
    };

    const D3D12_INPUT_LAYOUT_DESC DefaultIL = { DefaultILDescs, _countof(DefaultILDescs) };

    CD3DX12_DESCRIPTOR_RANGE1 DescRange[] =
    {
        {D3D12_DESCRIPTOR_RANGE_TYPE_SRV, 1, 0},    // t0
        {D3D12_DESCRIPTOR_RANGE_TYPE_UAV, 2, 0},    // u0-u1
        {D3D12_DESCRIPTOR_RANGE_TYPE_SAMPLER, 2, 0} // s0-s1
    };

    CD3DX12_ROOT_PARAMETER1 rootParameters[_countof(DescRange)];

    for (UINT i = 0; i < _countof(rootParameters); ++i)
    {
        rootParameters[i].InitAsDescriptorTable(1u, &DescRange[i], D3D12_SHADER_VISIBILITY_ALL);
    }

    CD3DX12_VERSIONED_ROOT_SIGNATURE_DESC rootSignatureDesc(_countof(rootParameters), rootParameters, 0, nullptr,
        D3D12_ROOT_SIGNATURE_FLAG_ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT | D3D12_ROOT_SIGNATURE_FLAG_ALLOW_STREAM_OUTPUT);

    Microsoft::WRL::ComPtr <ID3DBlob> signature;
    Microsoft::WRL::ComPtr <ID3DBlob> error;
    VERIFY_SUCCEEDED(D3D12CompilerSerializeVersionedRootSignature(&rootSignatureDesc, &signature, &error));

    D3D12_SERIALIZED_ROOT_SIGNATURE_DESC serializedRootSignatureDesc = {};
    serializedRootSignatureDesc.pSerializedBlob = signature->GetBufferPointer();
    serializedRootSignatureDesc.SerializedBlobSizeInBytes = signature->GetBufferSize();

    struct PSO_STREAM
    {
        CD3DX12_PIPELINE_STATE_STREAM_PRIMITIVE_TOPOLOGY PrimitiveTopologyType;
        CD3DX12_PIPELINE_STATE_STREAM_INPUT_LAYOUT InputLayout;
        CD3DX12_PIPELINE_STATE_STREAM_VS VS;
        CD3DX12_PIPELINE_STATE_STREAM_PS PS;
        CD3DX12_PIPELINE_STATE_STREAM_SERIALIZED_ROOT_SIGNATURE RootSigDesc;
    } PSOStream =
    {
        D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE,
        DefaultIL,
        AssignShaderBytecode(pVS),
        AssignShaderBytecode(pPS),
        CD3DX12_SERIALIZED_ROOT_SIGNATURE_DESC{signature->GetBufferPointer(), signature->GetBufferSize()}
    };

    D3D12_PIPELINE_STATE_STREAM_DESC StreamDesc{ sizeof(PSOStream), &PSOStream };

    //
    //  Compile the PSO and store the results with the cache session.
    //

    const UINT groupVersion = 1u;
    const UINT keySize = static_cast<UINT>(strlen(pGroupName) + 1u);
    D3D12_COMPILER_CACHE_GROUP_KEY groupKey = { pGroupName, keySize };
    VERIFY_SUCCEEDED(spCompiler->CompilePipelineState(&groupKey, groupVersion, &StreamDesc));
```
