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

<ins><!-- d3d12-review-inline:begin:compiler-output:scope:0:authored:migration-5c4dc32624e157cc-0 -->The [factory and target API](offline-compilation.md) continues here with compiler
invocation and cache output.<!-- d3d12-review-inline:end:compiler-output:scope:0:authored:migration-5c4dc32624e157cc-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:scope:1:authored:migration-60bf325ed6d92115-0 -->A compiler cache session maps application group keys to vendor-generated value
keys and stores the typed results of offline pipeline state and state object
compilation. A compiler state object retains compilation state for collections
and subsequent additions. It is not an `ID3D12StateObject` created by a device
and cannot be submitted for GPU execution.<!-- d3d12-review-inline:end:compiler-output:scope:1:authored:migration-60bf325ed6d92115-0 --></ins>

<a id="output-storage"></a>

## Output storage and object subdivision

Each compiler exposes <ins><!-- d3d12-review-inline:begin:compiler-output:output-storage-grammar:0:modified:weekend-api-plural -->APIs<!-- d3d12-review-inline:end:compiler-output:output-storage-grammar:0:modified:weekend-api-plural --></ins> to compile a PSO or SO that take arguments that are similar to the object creation counterparts in the D3D12 runtime.  The <ins><!-- d3d12-review-inline:begin:compiler-output:output-storage-actor:0:modified:weekend-description-input -->compiler runtime validates descriptions<!-- d3d12-review-inline:end:compiler-output:output-storage-actor:0:modified:weekend-description-input --></ins> and translates them into DDI representations for calling the IHV plugin.  The implementation for performing this validation and translation is shared with the D3D12 runtime.  <ins><!-- d3d12-review-inline:begin:compiler-output:output-storage-call:0:modified:weekend-runtime-actor -->The compiler runtime calls the plugin with DDI arguments to compile.<!-- d3d12-review-inline:end:compiler-output:output-storage-call:0:modified:weekend-runtime-actor --></ins>  The plugin is expected to decompose this object, compile, and store each compiled object as a value via callbacks to the runtime.  The plugin finally sets the list of values associated with the input object via a callback to the runtime.  The runtime stores this list of values as a value group in the cache session using the group key supplied by the caller during the compile operation.

<ins><!-- d3d12-review-inline:begin:compiler-output:collection-output-overview:0:authored:migration-d8d02567a98d9e03-0 -->A collection compilation that produces no compiled output may omit the
output key callback and have no output group. This exception is specific to
[`CompileStateObject`](#id3d12compiler-compilestateobject). It does not apply
to PSO/executable compilation or additions.<!-- d3d12-review-inline:end:compiler-output:collection-output-overview:0:authored:migration-d8d02567a98d9e03-0 --></ins>

The Precompiled Shader Database(PSDB) is implemented as Sqlite3 databases for storage.  The compiler runtime API wraps the database as an ID3D12CompilerCacheSession.

The PSDB Stores:

- Metadata about the target application and adapter family.
- <ins><!-- d3d12-review-inline:begin:compiler-output:storage-concepts:2 -->Compiled objects produced by the IHV compiler plugin are stored as values.  A single PSO or SO compilation may produce multiple values.<!-- d3d12-review-inline:end:compiler-output:storage-concepts:2 --></ins>
- <ins><!-- d3d12-review-inline:begin:compiler-output:storage-concepts:2 -->A value group.  Each PSO compilation and each SO compilation that produces output has a single value group that maps its associated values.  Values may appear in more than one group (For example, if the same shader was part of another PSO or SO).<!-- d3d12-review-inline:end:compiler-output:storage-concepts:2 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:subdivision-producer:0:modified:migration-eb0d656d6325b075-0 -->The compiler plugin may sub-divide DDI objects (PSOs, SOs, and Partial SOs) in an IHV dependent way to support deduplication and multiple values may be stored per compile operation.  The IHV plugin is responsible for generating value keys from the inputs that contribute to the compiled output and other internal data. The compiler may also check for previously compiled duplicates.<!-- d3d12-review-inline:end:compiler-output:subdivision-producer:0:modified:migration-eb0d656d6325b075-0 --></ins>

Stored values in cache sessions may be directly compared with previous compiler version output, adapter families considered to be similar in some fashion, etc. for further deduplication.  Compilers should refrain from storing additional data in the same value buffer that causes comparison failure when compiled binaries are otherwise identical.  Compilers can instead store compiler metadata for each compiler output for this type of data instead.  For example, storing compiler version or application version information that produced a binary with the value will cause comparison to fail even if they are otherwise identical.

<ins><!-- d3d12-review-inline:begin:compiler-output:version-domains:0:authored:migration-d0346859057b7da7-0 -->Application group keys and group versions identify source object revisions.
Vendor-generated value keys identify reusable compiled parts. A group can
reference several keys, and a value can belong to several groups. The
`GroupVersion` argument is not a member of
`D3D12_COMPILER_CACHE_GROUP_KEY`. A change to a source object definition
requires the corresponding group version to be revised.<!-- d3d12-review-inline:end:compiler-output:version-domains:0:authored:migration-d0346859057b7da7-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:version-domains:1:authored:migration-a460098bd8a851c0-0 -->The target's adapter family index is local to its factory. The stored identity
uses the family identifier, ABI and compiler version. The
[compiler, ABI and application profile version domains](offline-compilation.md#version-domains)
are distinct from application and engine versions in the
[application descriptor](state-object-databases-and-identity.md#d3d12_application_desc),
group versions, value type flags and database format versions.<!-- d3d12-review-inline:end:compiler-output:version-domains:1:authored:migration-a460098bd8a851c0-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:D144-readonly-consumer:0:authored:migration-d3f0fbefb10c160e-0 -->[Read-only runtime PSDB eligibility](runtime-cache-discovery.md#compatibility) and [implicit open/failure policy](runtime-cache-discovery.md#failure-and-lifetime) define consumption of registered output. Passing those checks is not a group/value hit and does not authorize writable cache maintenance, metadata replacement or the [producer's full-identity reopening rules](#id3d12compilerfactory-createcompilercachesession).<!-- d3d12-review-inline:end:compiler-output:D144-readonly-consumer:0:authored:migration-d3f0fbefb10c160e-0 --></ins>

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

The Debug PDB for the object code.  Used in pix and other debug scenarios.  An opaque blob that still requires IHV interpretation to <ins><!-- d3d12-review-inline:begin:compiler-output:type-prose-d3d12_compiler_value_type:7:authored:source-1d293972b371154e-0-0 -->be <!-- d3d12-review-inline:end:compiler-output:type-prose-d3d12_compiler_value_type:7:authored:source-1d293972b371154e-0-0 --></ins>used with PIX.

*D3D12_COMPILER_VALUE_TYPE_PERFORMANCE_DATA*

Performance data about the compile or produced object code.  An opaque blob that still requires IHV interpretation to <ins><!-- d3d12-review-inline:begin:compiler-output:type-prose-d3d12_compiler_value_type:9:authored:source-f5c90bff9af76655-0-0 -->be <!-- d3d12-review-inline:end:compiler-output:type-prose-d3d12_compiler_value_type:9:authored:source-f5c90bff9af76655-0-0 --></ins>used with PIX.

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

Specifies that the operation <ins><!-- d3d12-review-inline:begin:compiler-output:type-prose-d3d12_compiler_value_type_flags:5:modified:source-b7bd68c56cbd9ac2-0-0 -->applies<!-- d3d12-review-inline:end:compiler-output:type-prose-d3d12_compiler_value_type_flags:5:modified:source-b7bd68c56cbd9ac2-0-0 --></ins> to object code.

<ins><!-- d3d12-review-inline:begin:compiler-output:type-prose-d3d12_compiler_value_type_flags:6:authored:migration-cbdad1e3eb0a96e2-0 -->*D3D12_COMPILER_VALUE_TYPE_FLAGS_METADATA*<!-- d3d12-review-inline:end:compiler-output:type-prose-d3d12_compiler_value_type_flags:6:authored:migration-cbdad1e3eb0a96e2-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:type-prose-d3d12_compiler_value_type_flags:7:authored:migration-1c0711270227a1eb-0 -->Selects compiler metadata.<!-- d3d12-review-inline:end:compiler-output:type-prose-d3d12_compiler_value_type_flags:7:authored:migration-1c0711270227a1eb-0 --></ins>

*D3D12_COMPILER_VALUE_TYPE_FLAGS_DEBUG_PDB*

Specifies that the operation <ins><!-- d3d12-review-inline:begin:compiler-output:type-prose-d3d12_compiler_value_type_flags:9:modified:source-2b028220806afb95-0-0 -->applies<!-- d3d12-review-inline:end:compiler-output:type-prose-d3d12_compiler_value_type_flags:9:modified:source-2b028220806afb95-0-0 --></ins> to the debug PDB.

*D3D12_COMPILER_VALUE_TYPE_FLAGS_PERFORMANCE_DATA*

Specifies that the operation <ins><!-- d3d12-review-inline:begin:compiler-output:type-prose-d3d12_compiler_value_type_flags:11:modified:source-689d1fa6599bd4aa-0-0 -->applies<!-- d3d12-review-inline:end:compiler-output:type-prose-d3d12_compiler_value_type_flags:11:modified:source-689d1fa6599bd4aa-0-0 --></ins> to performance data.

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

<ins><!-- d3d12-review-inline:begin:compiler-output:type-prose-d3d12_compiler_cache_group_key:0:modified:migration-3557e4ba09bca56d-0 -->A structure representing a shader cache group key.<!-- d3d12-review-inline:end:compiler-output:type-prose-d3d12_compiler_cache_group_key:0:modified:migration-3557e4ba09bca56d-0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:compiler-output:opaque-key-buffers:0:authored:migration-6192729c1df1b890-0 -->Group keys and value keys are opaque byte sequences, not necessarily text
or null-terminated strings. `KeySize` counts bytes. Each `pKey` must address
the bytes described by that count while the receiving call uses it. Application
group keys and vendor-generated value keys occupy different roles even when
their byte sequences happen to match.<!-- d3d12-review-inline:end:compiler-output:opaque-key-buffers:0:authored:migration-6192729c1df1b890-0 --></ins>

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

A pointer to a <ins><!-- d3d12-review-inline:begin:compiler-output:type-prose-d3d12_compiler_cache_value:3:modified:source-ef3f1ebc40a3f906-0-0 -->memory<!-- d3d12-review-inline:end:compiler-output:type-prose-d3d12_compiler_cache_value:3:modified:source-ef3f1ebc40a3f906-0-0 --></ins> buffer containing the value.

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

A const pointer to a <ins><!-- d3d12-review-inline:begin:compiler-output:type-prose-d3d12_compiler_cache_const_value:3:modified:source-8330f236510af94a-0-0 -->memory<!-- d3d12-review-inline:end:compiler-output:type-prose-d3d12_compiler_cache_const_value:3:modified:source-8330f236510af94a-0-0 --></ins> buffer containing the value.

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

The const buffer and size for the value.  See <ins><!-- d3d12-review-inline:begin:compiler-output:type-prose-d3d12_compiler_cache_typed_const_value:4:modified:source-bc91de41e26ccb50-0-0 -->[D3D12_COMPILER_CACHE_CONST_VALUE](#d3d12_compiler_cache_const_value)<!-- d3d12-review-inline:end:compiler-output:type-prose-d3d12_compiler_cache_typed_const_value:4:modified:source-bc91de41e26ccb50-0-0 --></ins>.

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

<ins><!-- d3d12-review-inline:begin:compiler-output:compiler-existing-collection:0:authored:migration-370da1daaa0e7672-0 -->Use `D3D12_STATE_SUBOBJECT_TYPE_COMPILER_EXISTING_COLLECTION` with this
descriptor. `pExistingCollection` is a live compiler state object collection,
not an `ID3D12StateObject` from a device or a database key.
`NumExports` counts `D3D12_EXPORT_DESC` entries. When zero, all collection
exports are surfaced. Otherwise `pExports` points to that many readable export
descriptors, with the export selection/renaming semantics of
[existing collections](state-objects.md#d3d12_existing_collection_desc).
The referenced collection must come from the compiler receiving the description. The application must
retain it while its dependents need it; compilation does not automatically
retain a collection API reference.<!-- d3d12-review-inline:end:compiler-output:compiler-existing-collection:0:authored:migration-370da1daaa0e7672-0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:compiler-output:callback-prose-d3d12compilercachesessiongroupvaluesfunc:3 -->An index grouping the typed values for one value key within the filtered backing database query.  For example, if both OBJECT_CODE and METADATA are requested and stored for a value key in the same backing database, this function is called twice with ValueKeyIndex 0 before incrementing for the next set of values.<!-- d3d12-review-inline:end:compiler-output:callback-prose-d3d12compilercachesessiongroupvaluesfunc:3 --></ins>

*pTypedValue*

Indicates a single value type and value for the callback.  See [D3D12_COMPILER_CACHE_TYPED_CONST_VALUE](#d3d12_compiler_cache_typed_const_value).

*pContext*

An application defined context pointer.

**Remarks**

<ins><!-- d3d12-review-inline:begin:compiler-output:callback-prose-d3d12compilercachesessiongroupvaluesfunc:9 -->This function is called once for each selected stored value type that is part of the group.  Use ValueKeyIndex to associate value types to the same value key.<!-- d3d12-review-inline:end:compiler-output:callback-prose-d3d12compilercachesessiongroupvaluesfunc:9 --></ins>

This function must not throw uncaught exceptions.

<ins><!-- d3d12-review-inline:begin:compiler-output:callback-borrowing:0:authored:migration-8769311dbaa7ea68-0 -->`pTypedValue` and its value buffer passed to a group value callback are borrowed
for that callback invocation. Copy any data needed afterward. Do not free the
borrowed storage. The application owns `pContext`. The lookup passes it through.
The callbacks execute as part of the lookup before that lookup returns.<!-- d3d12-review-inline:end:compiler-output:callback-borrowing:0:authored:migration-8769311dbaa7ea68-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:callback-borrowing:1:authored:migration-56b8654f369133b5-0 -->The allocation callback instead supplies application-owned storage. The caller
must release successful allocations with the matching deallocator, including
allocations returned before a later failure. The cache session does not take
ownership of those allocations.<!-- d3d12-review-inline:end:compiler-output:callback-borrowing:1:authored:migration-56b8654f369133b5-0 --></ins>

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
- Value types may be stored in <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerfactory-createcompilercachesession-source:1:modified:source-4800a83c65c8534e-0-0 -->separate<!-- d3d12-review-inline:end:compiler-output:id3d12compilerfactory-createcompilercachesession-source:1:modified:source-4800a83c65c8534e-0-0 --></ins> databases.  For example, PDBs may be stored in a <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerfactory-createcompilercachesession-source:1:modified:source-4800a83c65c8534e-0-1 -->separate<!-- d3d12-review-inline:end:compiler-output:id3d12compilerfactory-createcompilercachesession-source:1:modified:source-4800a83c65c8534e-0-1 --></ins> database file than object code.

<ins><!-- d3d12-review-inline:begin:compiler-output:session-routing-and-files:0:authored:migration-f1b3b9057a191ceb-0 -->`pPaths` is required and `NumPaths` must be nonzero. Each `Types` mask must
select at least one of the four declared value types and no undeclared bits.
The masks must be pairwise disjoint: each type is assigned to exactly one
database entry. `GetValueTypes` returns their union. Object code and metadata
must either both be in this union or both be absent. They may be assigned to
different entries. Debug PDB and performance data storage can be selected
independently.<!-- d3d12-review-inline:end:compiler-output:session-routing-and-files:0:authored:migration-f1b3b9057a191ceb-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:session-routing-and-files:1:authored:migration-c95c46183f7a963f-0 -->Each `pPath` names a Windows file, using a filename, local path or UNC path;
the containing directory must exist. A null path selects a session-local
in-memory database. It is not the filename `:memory:`; SQLite URI filenames
and that special filename are not accepted by this API. The path descriptor
contains no filename-extension inference and no access mode flag.
Existing files are opened for modification and missing files are created;
this is not a read-only open API. Read-only files or inaccessible paths can
fail to open. SODB's
[read-only flag](state-object-databases-and-identity.md#d3d12_state_object_database_flags)
does not apply to this call.<!-- d3d12-review-inline:end:compiler-output:session-routing-and-files:1:authored:migration-c95c46183f7a963f-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:session-routing-and-files:2:authored:migration-b34bd204a3e09fa3-0 -->Disjoint masks route types; distinct path strings can still identify the
same physical file. Group writes are made to every database entry. Physical file
deduplication and an all-files transaction are not guaranteed, so aliased
entries must not be treated as independent storage.<!-- d3d12-review-inline:end:compiler-output:session-routing-and-files:2:authored:migration-b34bd204a3e09fa3-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:session-metadata:0:authored:migration-eb1264c834eb85f5-0 -->`pTarget` and `pApplicationDesc` are optional only when the database metadata
supplies the corresponding identity. If no opened database supplies an
identity, that descriptor must be provided. Otherwise creation returns
`E_INVALIDARG`. New databases receive the resolved identities. Missing metadata
in one file may be filled from consistent metadata in another file or from the
supplied descriptors.<!-- d3d12-review-inline:end:compiler-output:session-metadata:0:authored:migration-eb1264c834eb85f5-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:session-metadata:1:authored:migration-d4d670e0808c76da-0 -->All existing compiler identities must agree on family identifier, ABI and
compiler version. All application identities must agree on executable
filename, application name/version, engine name/version and application profile
version. Supplied descriptors must agree with stored identities. Null
application string members compare as empty strings; application string
comparisons are case-sensitive. Inconsistent identities
return `E_INVALIDARG`, rather than silently changing the identity of a populated
database.<!-- d3d12-review-inline:end:compiler-output:session-metadata:1:authored:migration-d4d670e0808c76da-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:session-metadata:2:authored:migration-00cd34c64e3572b9-0 -->The factory resolves a stored family identifier to its own local family index.
An explicit target's ABI zero resolves to the newest supported ABI under
[target resolution](offline-compilation.md#d3d12_compiler_target). An explicit
nonzero ABI must be supported. The resolved family, ABI and compiler version
must match stored metadata. The application profile version must match the
version reported by this compiler for the resolved target and application.
An unsupported stored family can fail lookup with `DXGI_ERROR_NOT_FOUND`;
identity/version mismatches return `E_INVALIDARG`.<!-- d3d12-review-inline:end:compiler-output:session-metadata:2:authored:migration-00cd34c64e3572b9-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:session-metadata:3:authored:migration-f2952ac62deac7c3-0 -->Path strings and application strings are consumed or copied during creation;
the caller retains their ownership. `ppCompilerCacheSession` is required
writable interface pointer storage, not a null output availability probe.
On success it receives an owned reference selected by `riid`. Failures before
the interface query do not promise to clear an existing output value. Opening
and initializing earlier files may already have happened when a later file or
metadata check fails; no all-files rollback is guaranteed.<!-- d3d12-review-inline:end:compiler-output:session-metadata:3:authored:migration-f2952ac62deac7c3-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:explicit-application-input:0:authored:migration-53d6e15f1856c4d0-0 -->When `pApplicationDesc` is explicitly supplied, `pExeFilename` and `pName`
are required non-null, null-terminated strings identifying the target
application's executable filename and title. `Version` supplies its application
version. `pEngineName` is optional. If supplied it must be null-terminated and
`EngineVersion` must be provided. These are the
[application metadata requirements](state-object-databases-and-identity.md#d3d12_application_desc),
not a fallback to the compiler-hosting process's identity.<!-- d3d12-review-inline:end:compiler-output:explicit-application-input:0:authored:migration-53d6e15f1856c4d0-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:explicit-application-input:1:authored:migration-ae5c8d24f0edd174-0 -->The optional descriptor pointer used to resolve existing database metadata is
a separate condition. Comparison or copying of null string members as empty
strings does not waive the required fields of an explicitly supplied
descriptor.<!-- d3d12-review-inline:end:compiler-output:explicit-application-input:1:authored:migration-ae5c8d24f0edd174-0 --></ins>

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

On return, <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerfactory-createcompilercachesession-parameter-source:11 -->a pointer to the compiler cache session interface specified by riid.<!-- d3d12-review-inline:end:compiler-output:id3d12compilerfactory-createcompilercachesession-parameter-source:11 --></ins>

### Return values

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerfactory-createcompilercachesession-returns:0:authored:migration-295611cec6380dc3-0 -->`S_OK` returns the requested cache session interface. Invalid routing masks, a missing path array, zero path count, and the
documented missing or mismatched identities return `E_INVALIDARG`. An unsupported requested interface
returns `E_NOINTERFACE`. Allocation, file open/database and plugin query
failures propagate as failing `HRESULT`s. There is no universal filesystem error
mapping or all-files rollback guarantee.<!-- d3d12-review-inline:end:compiler-output:id3d12compilerfactory-createcompilercachesession-returns:0:authored:migration-295611cec6380dc3-0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:compiler-output:compiler-creation-lifetime:0:authored:migration-be3a1afa655bf4e1-0 -->`pCompilerCacheSession` and `ppCompiler` are required; null returns
`E_INVALIDARG`. The compiler retains a reference to its cache session and
inherits its target, application descriptor and selected value types.
The caller owns the returned compiler reference and releases it when no
longer needed. The retained session keeps its application strings alive.<!-- d3d12-review-inline:end:compiler-output:compiler-creation-lifetime:0:authored:migration-be3a1afa655bf4e1-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:compiler-creation-lifetime:1:authored:migration-dabcf08befc98421-0 -->The cache session need not have been created by this factory, but its target
index and metadata must be meaningful to this factory. No cross-factory index
translation is performed. See [input ownership](#input-ownership).
`ppCompiler` is not a null output validation probe. Failure before the final
interface query need not initialize it. Plugin creation and allocation failures
fail this call.<!-- d3d12-review-inline:end:compiler-output:compiler-creation-lifetime:1:authored:migration-dabcf08befc98421-0 --></ins>

### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerfactory-createcompiler-parameter-source:0 -->`[in] pCompilerCacheSession`<!-- d3d12-review-inline:end:compiler-output:id3d12compilerfactory-createcompiler-parameter-source:0 --></ins>

The cache session where compiled results are stored.  The compiler plugin may also check if objects were previously compiled.  See [ID3D12CompilerCacheSession](#id3d12compilerfactory-createcompilercachesession).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerfactory-createcompiler-parameter-source:2 -->`[in] riid`<!-- d3d12-review-inline:end:compiler-output:id3d12compilerfactory-createcompiler-parameter-source:2 --></ins>

The globally unique identifier (GUID) for the compiler interface. See [ID3D12Compiler](#id3d12compilerfactory-createcompiler).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerfactory-createcompiler-parameter-source:4 -->`[out] ppCompiler`<!-- d3d12-review-inline:end:compiler-output:id3d12compilerfactory-createcompiler-parameter-source:4 --></ins>

On return, a pointer <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerfactory-createcompiler-parameter-source:5:authored:source-5cfbc1ad5abe5e0a-0-0 -->to <!-- d3d12-review-inline:end:compiler-output:id3d12compilerfactory-createcompiler-parameter-source:5:authored:source-5cfbc1ad5abe5e0a-0-0 --></ins>the compiler interface specified by riid.

### Return values

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerfactory-createcompiler-returns:0:authored:migration-1653e4fdbae3e184-0 -->`S_OK` returns the requested compiler interface; null required arguments
return `E_INVALIDARG`, and an unsupported interface returns `E_NOINTERFACE`.
Allocation and plugin compiler creation failures propagate. A returned
compiler does not certify that every later description is compilable.<!-- d3d12-review-inline:end:compiler-output:id3d12compilerfactory-createcompiler-returns:0:authored:migration-1653e4fdbae3e184-0 --></ins>

<a id="input-ownership"></a>

## Compilation inputs and ownership

<ins><!-- d3d12-review-inline:begin:compiler-output:synchronization-and-lifetime:0:authored:migration-1355896c1604b200-0 -->`ID3D12Compiler` and `ID3D12CompilerCacheSession` derive from
`ID3D12CompilerFactoryChild`. Their inherited
[`GetFactory`](offline-compilation.md#id3d12compilerfactorychild-getfactory)
contract is not a new operation on either interface. `ID3D12CompilerStateObject`
derives from `IUnknown` and exposes
[`GetCompiler`](#id3d12compilerstateobject-getcompiler).<!-- d3d12-review-inline:end:compiler-output:synchronization-and-lifetime:0:authored:migration-1355896c1604b200-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:synchronization-and-lifetime:1:authored:migration-cfc942f99117f597-0 -->The compiler plugin is responsible for synchronization as necessary,
applications do not need to add external synchronization. Caller-owned
descriptions, arrays, keys, strings, callback functions and context storage must
remain valid while the receiving call uses them. That synchronization contract
does not remove the object reference or structural dependency requirements
below.<!-- d3d12-review-inline:end:compiler-output:synchronization-and-lifetime:1:authored:migration-cfc942f99117f597-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:compilation-inputs:0:authored:migration-43747a46ac297034-0 -->Pipeline descriptions use
[`D3D12_PIPELINE_STATE_STREAM_DESC`](pipeline-state.md#streams).
For explicit roots, use
`D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_SERIALIZED_ROOT_SIGNATURE` carrying
[`D3D12_SERIALIZED_ROOT_SIGNATURE_DESC`](state-object-databases-and-identity.md#d3d12_serialized_root_signature_desc),
not a device root signature pointer. Roots embedded in shaders can be resolved
and validated by the compiler. Legacy cached PSO blobs and pipeline library
inputs are not compiler host inputs.<!-- d3d12-review-inline:end:compiler-output:compilation-inputs:0:authored:migration-43747a46ac297034-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:compilation-inputs:1:authored:migration-0308a8661a98c81a-0 -->State object descriptions use
[`D3D12_STATE_OBJECT_DESC`](state-objects.md#d3d12_state_object_desc).
Explicit roots use
[`D3D12_GLOBAL_SERIALIZED_ROOT_SIGNATURE`](state-object-databases-and-identity.md#d3d12_global_serialized_root_signature)
or
[`D3D12_LOCAL_SERIALIZED_ROOT_SIGNATURE`](state-object-databases-and-identity.md#d3d12_local_serialized_root_signature)
with their corresponding serialized root subobject tags. An existing
compiler collection uses
[`D3D12_COMPILER_EXISTING_COLLECTION_DESC`](#d3d12_compiler_existing_collection_desc)
and `D3D12_STATE_SUBOBJECT_TYPE_COMPILER_EXISTING_COLLECTION`.
The database's
[`D3D12_EXISTING_COLLECTION_BY_KEY_DESC`](state-object-databases-and-identity.md#d3d12_existing_collection_by_key_desc)
is a storage reference, not a directly accepted compile input. Reconstruct the
dependency as a live compiler collection. A parent key from an SODB similarly
identifies a dependency to supply as a live parent to the addition call.<!-- d3d12-review-inline:end:compiler-output:compilation-inputs:1:authored:migration-0308a8661a98c81a-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:compilation-inputs:2:authored:migration-5bbe2adee09c15a2-0 -->The compiler runtime validates descriptions and translates them to DDI
representations using shared runtime validation. Pipeline stream parsing,
stage composition, input/stream output layouts, render target and
depth/stencil formats, samples, rasterization and linkage retain the
[pipeline construction rules](pipeline-state.md#id3d12device2-createpipelinestate).
Root contents and shader compatibility retain
[Binding](binding.md#root-signatures).
State object type/payload, exports, associations, defaults, collection linking
and construction retain
[State objects](state-objects.md#createstateobject),
[association requirements](state-objects.md#subobject-association-requirements)
and [default resolution](state-objects.md#default-resolution).
Incremental additions retain the
[addition restrictions](state-objects.md#addtostateobject).<!-- d3d12-review-inline:end:compiler-output:compilation-inputs:2:authored:migration-5bbe2adee09c15a2-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:compilation-inputs:3:authored:migration-84514c16299e9615-0 -->Capability checks are made against the compiler's target using the
[negotiated plugin capabilities](compiler-plugin-foundation.md#get-caps),
including applicable feature level, shader model, shader features, formats,
multisampling, raytracing/state object or work graph requirements. Serializing
or storing a description does not establish that the target can compile it.
Invalid descriptions and unsupported target capabilities are distinct from
an IHV compiler failure.<!-- d3d12-review-inline:end:compiler-output:compilation-inputs:3:authored:migration-84514c16299e9615-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:compilation-inputs:4:authored:migration-4af06947470dfc12-0 -->Descriptions, their reachable arrays, bytecode and serialized roots must be
readable for the call. The compiler retains the internal descriptions and
dependency state needed by later additions; callers need not keep the
original top-level description allocation alive after a successful call.<!-- d3d12-review-inline:end:compiler-output:compilation-inputs:4:authored:migration-4af06947470dfc12-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:factory-and-parent-consistency:0:authored:migration-7e618b898ef9a49c-0 -->Every referenced compiler collection and addition parent must have been created
by the same `ID3D12Compiler` that receives the dependent compile call. These
are caller preconditions; no particular mismatch `HRESULT` is guaranteed.<!-- d3d12-review-inline:end:compiler-output:factory-and-parent-consistency:0:authored:migration-7e618b898ef9a49c-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:factory-and-parent-consistency:1:authored:migration-3b766eff6002ff42-0 -->A cache session need not come from the compiler's factory. Its target,
application descriptor and selected value types must be meaningful to the
receiving factory. The target's family index is interpreted in that factory's
enumeration. The compiler does not remap an index from another factory.
The compiler retains its cache session, and a compiler state object retains
the compiler that created it.<!-- d3d12-review-inline:end:compiler-output:factory-and-parent-consistency:1:authored:migration-3b766eff6002ff42-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:factory-and-parent-consistency:2:authored:migration-53351641ea526eee-0 -->Applications must retain compiler collections while their dependents need them.
Compilation does not automatically retain a collection API reference.
Retaining a compiler or copying description data is not a substitute for
keeping the referenced collection alive.<!-- d3d12-review-inline:end:compiler-output:factory-and-parent-consistency:2:authored:migration-53351641ea526eee-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:factory-and-parent-consistency:3:authored:migration-0be680f0426a7043-0 -->An addition retains the parent's description data, not the parent's API
reference or plugin handle. After the addition succeeds, the application need
not retain the addition-parent API reference for the child's lifetime.
Releasing the last parent reference destroys the parent's plugin handle;
the plugin must retain whatever dependency state it needs for the child.
This is the description/handle distinction in
[state object driver lifetime](state-objects.md#driver-lifetime), not the
collection retention rule above. Original caller-owned description allocations
can be released after successful compilation.<!-- d3d12-review-inline:end:compiler-output:factory-and-parent-consistency:3:authored:migration-0be680f0426a7043-0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:compiler-output:DEL-I02-pipeline-output-route:0:authored:migration-37f2258d0b613971-0 -->[Output storage](#output-storage) defines subdivision into compiled values,
their storage and the group mapping for this operation.<!-- d3d12-review-inline:end:compiler-output:DEL-I02-pipeline-output-route:0:authored:migration-37f2258d0b613971-0 --></ins>

<a id="compile-completion"></a>

<ins><!-- d3d12-review-inline:begin:compiler-output:compilepipelinestate-completion:0:authored:migration-055704e76a235891-0 -->The cache session's `GetValueTypes()` mask selects the output types. There is
no value type flags argument on this API. The group key is required. The
description and all required referenced data must be valid.
On success, this method returns synchronously only after all compiled output
is stored and the plugin's cache callbacks have completed.
This is not an asynchronous job handle and does not create a GPU-executable
device object. Completion does not imply a cross-file atomic commit, crash
durability, or rollback of values stored before an error.<!-- d3d12-review-inline:end:compiler-output:compilepipelinestate-completion:0:authored:migration-055704e76a235891-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:compilepipelinestate-validation-input:0:authored:migration-4227a368f3f86204-0 -->A null `pGroupKey` returns `E_INVALIDARG`. The
[compilation input and target validation contract](#input-ownership)
defines the required description forms and shared construction rules.<!-- d3d12-review-inline:end:compiler-output:compilepipelinestate-validation-input:0:authored:migration-4227a368f3f86204-0 --></ins>

### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilepipelinestate-parameter-source:0 -->`[in] pGroupKey`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilepipelinestate-parameter-source:0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilepipelinestate-parameter-source:1 -->A unique key that identifies the group. This key is used to store a group with the values produced by this compiled operation.  This group must not already be present in the cache session.<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilepipelinestate-parameter-source:1 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilepipelinestate-parameter-source:2 -->`[in] GroupVersion`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilepipelinestate-parameter-source:2 --></ins>

The version number of the cached group.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilepipelinestate-parameter-source:4 -->`[in] pDesc`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilepipelinestate-parameter-source:4 --></ins>

The pipeline state desc describing the PSO.  See [D3D12_PIPELINE_STATE_STREAM_DESC](pipeline-state.md#d3d12-pipeline-state-stream-desc).

### Return values

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilepipelinestate-returns:0:authored:migration-17451a55ee87b0ed-0 -->`S_OK` indicates successful validation and plugin completion. Description
validation failures return `E_INVALIDARG`; unsupported target capabilities can return
`DXGI_ERROR_UNSUPPORTED`. Allocation failures return `E_OUTOFMEMORY`.<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilepipelinestate-returns:0:authored:migration-17451a55ee87b0ed-0 --></ins>

<a id="compile-error-protocol"></a>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilepipelinestate-returns:1:authored:migration-a8986a383b984bba-0 -->Plugin compile failures preserve `E_OUTOFMEMORY`. Other failing plugin compile
results are translated to `DXGI_ERROR_DRIVER_INTERNAL_ERROR`. This is distinct
from the cache callbacks' own results, which are returned to the plugin.
The plugin must handle or propagate callback failures. A callback result is
not necessarily the public compile call's final `HRESULT`. Missing required
group key registration also fails compilation with
`DXGI_ERROR_DRIVER_INTERNAL_ERROR`.
Stored values can survive a failing compile.<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilepipelinestate-returns:1:authored:migration-a8986a383b984bba-0 --></ins>

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

This method creates an object that implements [ID3D12CompilerStateObject](#id3d12compiler-compilestateobject) to support using it as a base object when deriving new state objects with [ID3D12Compiler::CompileAddToStateObject](#id3d12compiler-compileaddtostateobject).

<ins><!-- d3d12-review-inline:begin:compiler-output:compilestateobject-completion:0:authored:migration-4d6122a4ec6c7c68-0 -->[Output storage](#output-storage) defines the compiled values and group mapping.
Output selection and synchronous completion follow the
[compiler completion contract](#compile-completion).<!-- d3d12-review-inline:end:compiler-output:compilestateobject-completion:0:authored:migration-4d6122a4ec6c7c68-0 --></ins>

<a id="compiler-state-object-results"></a>

<ins><!-- d3d12-review-inline:begin:compiler-output:compilestateobject-completion:1:authored:migration-585a8ba1e2248e2c-0 -->`riid` selects `ID3D12CompilerStateObject` or a supported base interface.
The output pointer is required writable storage, not a validation-only probe.
The returned interface is an owned reference. Release it when finished.
An error before the final interface query need not clear the caller's output.
The handle retains the compiler and internal construction data needed by
dependent compilations. State object compilation and addition require the
negotiated build-2 compiler DDI support. Otherwise they return `E_NOTIMPL`.<!-- d3d12-review-inline:end:compiler-output:compilestateobject-completion:1:authored:migration-585a8ba1e2248e2c-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:compilestateobject-completion:2:authored:migration-e6b68d1cdecc4ef2-0 -->A collection that produces no compiled output can return its compiler state
object without registering output keys or creating a group. The input group
key remains required. This exception does not apply to executable state object
compilation or incremental additions.<!-- d3d12-review-inline:end:compiler-output:compilestateobject-completion:2:authored:migration-e6b68d1cdecc4ef2-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:compilestateobject-validation-input:0:authored:migration-2e53b222bf3c2aed-0 -->A null `pGroupKey`, `pDesc` or `ppCompilerStateObject` returns `E_INVALIDARG`. The
[compilation input and target validation contract](#input-ownership)
defines the required description forms and shared construction rules.<!-- d3d12-review-inline:end:compiler-output:compilestateobject-validation-input:0:authored:migration-2e53b222bf3c2aed-0 --></ins>

### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilestateobject-parameter-source:0 -->`[in] pGroupKey`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilestateobject-parameter-source:0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilestateobject-parameter-source:1 -->A unique key that identifies the group.<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilestateobject-parameter-source:1 --></ins> This key is used to store a group with the values produced by this compiled operation.  This group must not already be present in the cache session.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilestateobject-parameter-source:2 -->`[in] GroupVersion`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilestateobject-parameter-source:2 --></ins>

The version number of the cached group.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilestateobject-parameter-source:4 -->`[in] pDesc`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilestateobject-parameter-source:4 --></ins>

Creation arguments for the state object.  See [D3D12_STATE_OBJECT_DESC](state-objects.md#d3d12_state_object_desc).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilestateobject-parameter-source:6 -->`[in] riid`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilestateobject-parameter-source:6 --></ins>

The globally unique identifier (GUID) for the new state object interface. See [ID3D12CompilerStateObject](#id3d12compiler-compilestateobject).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilestateobject-parameter-source:8 -->`[out] ppCompilerStateObject`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilestateobject-parameter-source:8 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilestateobject-parameter-source:9 -->On return, a pointer to the compiler state object interface specified by riid.<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilestateobject-parameter-source:9 --></ins>

### Return values

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilestateobject-returns:0:authored:migration-1d7bd3deb196e7e6-0 -->`S_OK` indicates successful validation and plugin completion. Description
validation failures return `E_INVALIDARG`; unsupported target capabilities can return
`DXGI_ERROR_UNSUPPORTED`. Allocation failures return `E_OUTOFMEMORY`.<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilestateobject-returns:0:authored:migration-1d7bd3deb196e7e6-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilestateobject-returns:1:authored:migration-e1b98008655bdbd2-0 -->An unsupported requested interface returns `E_NOINTERFACE`. The output pointer
is required. That interface failure can occur after compilation and storage.<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilestateobject-returns:1:authored:migration-e1b98008655bdbd2-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compilestateobject-returns:2:authored:migration-cc7a8beb197bc83f-0 -->Plugin and cache callback failures follow the
[compiler error protocol](#compile-error-protocol).
A collection with no compiled output may omit registration and have no group.<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compilestateobject-returns:2:authored:migration-cc7a8beb197bc83f-0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:compiler-output:DEL-I02-addition-operation:0:modified:operation-purpose -->Compiles an addition to an existing compiler state object.<!-- d3d12-review-inline:end:compiler-output:DEL-I02-addition-operation:0:modified:operation-purpose --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:compileaddtostateobject-completion:0:authored:migration-a457f19603c0b0cb-0 -->[Output storage](#output-storage) defines the compiled values and group mapping.
Output selection and synchronous completion follow the
[compiler completion contract](#compile-completion).<!-- d3d12-review-inline:end:compiler-output:compileaddtostateobject-completion:0:authored:migration-a457f19603c0b0cb-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:compileaddtostateobject-completion:1:authored:migration-e07c0c2eed202572-0 -->The returned interface and build-2 requirements follow
[Compiler state object results](#compiler-state-object-results).<!-- d3d12-review-inline:end:compiler-output:compileaddtostateobject-completion:1:authored:migration-e07c0c2eed202572-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:compileaddtostateobject-validation-input:0:authored:migration-be4b6f0c21e5194c-0 -->A null `pGroupKey`, `pAddition`, `pCompilerStateObjectToGrowFrom` or `ppNewCompilerStateObject` returns `E_INVALIDARG`. The
[compilation input and target validation contract](#input-ownership)
defines the required description forms and shared construction rules.<!-- d3d12-review-inline:end:compiler-output:compileaddtostateobject-validation-input:0:authored:migration-be4b6f0c21e5194c-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:addition-parent:0:authored:migration-eb7112499080ad54-0 -->`pCompilerStateObjectToGrowFrom` is required and must have been created by this
compiler. The result is a new compiler state object, not a replacement of the
parent. Its description storage retains the parent description data. It does
not retain the parent's API reference or guarantee the parent's plugin handle
remains alive. The plugin retains the dependency state it needs.
The application need not hold an addition-parent reference until the child is
destroyed. Collections remain subject to their distinct application retention
rule.<!-- d3d12-review-inline:end:compiler-output:addition-parent:0:authored:migration-eb7112499080ad54-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:addition-parent:1:authored:migration-e5a2bd83817f1eaa-0 -->The base must permit additions under
[`ALLOW_STATE_OBJECT_ADDITIONS`](state-objects.md#d3d12_state_object_flags),
and the new description must satisfy the
[growth and addition rules](state-objects.md#addtostateobject).<!-- d3d12-review-inline:end:compiler-output:addition-parent:1:authored:migration-e5a2bd83817f1eaa-0 --></ins>

ID3D12Device7::AddToStateObject allows an application developer to incrementally add to an existing state object during game runtime.

During offline compilation, <ins><!-- d3d12-review-inline:begin:compiler-output:offline-addition-rationale:1:modified:source-46439b844e3e4190-0-0 -->CPU<!-- d3d12-review-inline:end:compiler-output:offline-addition-rationale:1:modified:source-46439b844e3e4190-0-0 --></ins> overhead during compile is much less of an issue, so these incremental additions to a base state object instead could be factored as independent state objects.  However, this may result in higher runtime memory usage than the original extended state objects that may share state, so the compiler API and state object database <ins><!-- d3d12-review-inline:begin:compiler-output:offline-addition-rationale:1:modified:source-46439b844e3e4190-1-0 -->continue<!-- d3d12-review-inline:end:compiler-output:offline-addition-rationale:1:modified:source-46439b844e3e4190-1-0 --></ins> to support both.

### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:0 -->`[in] pGroupKey`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:1 -->A unique key that identifies the group.<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:1 --></ins> This key is used to store a group with the values produced by this compiled operation.  This group must not already be present in the cache session.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:2 -->`[in] GroupVersion`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:2 --></ins>

The version number of the cached group.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:4 -->`[in] pAddition`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:4 --></ins>

Addition arguments to add to pCompilerStateObjectToGrowFrom and create a new state object. See [D3D12_STATE_OBJECT_DESC](state-objects.md#d3d12_state_object_desc).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:6 -->`[in] pCompilerStateObjectToGrowFrom`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:6 --></ins>

The base state object to build from.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:8 -->`[in] riid`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:8 --></ins>

The globally unique identifier (GUID) for the new state object interface. See [ID3D12CompilerStateObject](#id3d12compiler-compilestateobject).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:10 -->`[out] ppNewCompilerStateObject`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:10 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:11 -->On return, a pointer to the compiler state object interface specified by riid.<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compileaddtostateobject-parameter-source:11 --></ins>

### Return values

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compileaddtostateobject-returns:0:authored:migration-257dc9ea60f86df3-0 -->`S_OK` indicates successful validation and plugin completion. Description
validation failures return `E_INVALIDARG`; unsupported target capabilities can return
`DXGI_ERROR_UNSUPPORTED`. Allocation failures return `E_OUTOFMEMORY`.<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compileaddtostateobject-returns:0:authored:migration-257dc9ea60f86df3-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compileaddtostateobject-returns:1:authored:migration-847c821ac6d6275a-0 -->An unsupported requested interface returns `E_NOINTERFACE`. The output pointer
is required. That interface failure can occur after compilation and storage.<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compileaddtostateobject-returns:1:authored:migration-847c821ac6d6275a-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-compileaddtostateobject-returns:2:authored:migration-3782a76c1037d14d-0 -->Plugin and cache callback failures follow the
[compiler error protocol](#compile-error-protocol).<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-compileaddtostateobject-returns:2:authored:migration-3782a76c1037d14d-0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-getcachesession-behavior:0:authored:migration-2da8093f7a882e8b-0 -->Returns the cache session used to create this compiler.<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-getcachesession-behavior:0:authored:migration-2da8093f7a882e8b-0 --></ins>

### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-getcachesession-parameters:0:authored:migration-b21854d7610c5c6a-0 -->`[in] riid`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-getcachesession-parameters:0:authored:migration-b21854d7610c5c6a-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-getcachesession-parameters:1:authored:migration-287c13f28673973d-0 -->Selects the requested interface.<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-getcachesession-parameters:1:authored:migration-287c13f28673973d-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-getcachesession-parameters:2:authored:migration-51887ec764b6db38-0 -->`[out] ppCompilerCacheSession`<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-getcachesession-parameters:2:authored:migration-51887ec764b6db38-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-getcachesession-parameters:3:authored:migration-ddcd676de169d5ff-0 -->Required writable storage for the owned interface reference returned on success.<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-getcachesession-parameters:3:authored:migration-ddcd676de169d5ff-0 --></ins>

### Return values

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compiler-getcachesession-returns:0:authored:migration-903faec61fe69809-0 -->`S_OK` returns an owned reference to the requested session interface;
`E_NOINTERFACE` reports an unsupported `riid`. A null output pointer is not a
probe and returns `E_POINTER` at the interface query. That query clears a
valid output slot on unsupported-interface failure.<!-- d3d12-review-inline:end:compiler-output:id3d12compiler-getcachesession-returns:0:authored:migration-903faec61fe69809-0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerstateobject-getcompiler-behavior:0:authored:migration-b03de5fd9f359e7f-0 -->Returns the compiler that created this compiler state object.<!-- d3d12-review-inline:end:compiler-output:id3d12compilerstateobject-getcompiler-behavior:0:authored:migration-b03de5fd9f359e7f-0 --></ins>

### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerstateobject-getcompiler-parameters:0:authored:migration-715ed5c0b283163a-0 -->`[in] riid`<!-- d3d12-review-inline:end:compiler-output:id3d12compilerstateobject-getcompiler-parameters:0:authored:migration-715ed5c0b283163a-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerstateobject-getcompiler-parameters:1:authored:migration-e0eeefb30348fdd1-0 -->Selects the requested interface.<!-- d3d12-review-inline:end:compiler-output:id3d12compilerstateobject-getcompiler-parameters:1:authored:migration-e0eeefb30348fdd1-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerstateobject-getcompiler-parameters:2:authored:migration-1972c9a8f275307e-0 -->`[out] ppCompiler`<!-- d3d12-review-inline:end:compiler-output:id3d12compilerstateobject-getcompiler-parameters:2:authored:migration-1972c9a8f275307e-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerstateobject-getcompiler-parameters:3:authored:migration-7d00733e03e4c89c-0 -->Required writable storage for the owned interface reference returned on success.<!-- d3d12-review-inline:end:compiler-output:id3d12compilerstateobject-getcompiler-parameters:3:authored:migration-7d00733e03e4c89c-0 --></ins>

### Return values

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilerstateobject-getcompiler-returns:0:authored:migration-58816e22ba5ea2c5-0 -->`S_OK` returns an owned reference to the compiler selected by `riid`;
`E_NOINTERFACE` reports an unsupported interface. A null output pointer is not
a probe and returns `E_POINTER` at the interface query. That query clears a
valid output slot on unsupported-interface failure.<!-- d3d12-review-inline:end:compiler-output:id3d12compilerstateobject-getcompiler-returns:0:authored:migration-58816e22ba5ea2c5-0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:compiler-output:findgroup-output:0:authored:migration-1ec38eed2ddb5e23-0 -->`pGroupKey` is required. A null `pGroupVersion` is a valid existence-only
query. On a successful version query the output receives the stored group
version. Failure does not promise a zero-initialized version output.
Finding the group entry does not prove its referenced typed values exist.
The group lookup uses the common mapping represented by the session's first
database; callers combining existing files must supply consistent mappings.<!-- d3d12-review-inline:end:compiler-output:findgroup-output:0:authored:migration-1ec38eed2ddb5e23-0 --></ins>

### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroup-parameter-source:0 -->`[in] pGroupKey`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroup-parameter-source:0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroup-parameter-source:1 -->A unique key that identifies the group.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroup-parameter-source:1 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroup-parameter-source:2 -->`[out, optional] pGroupVersion`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroup-parameter-source:2 --></ins>

Specify a non-null pointer to receive the version number of the group.  See <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroup-parameter-source:3:modified:source-db8c299b97b2f309-0-0 -->Behavior<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroup-parameter-source:3:modified:source-db8c299b97b2f309-0-0 --></ins>.

### Return values

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroup-returns:0:authored:migration-0f91d40a2d288d1b-0 -->`S_OK` means the group entry exists. `DXGI_ERROR_NOT_FOUND` means it was not
found. Database failures can also be returned. A failure does not initialize
`pGroupVersion` to zero.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroup-returns:0:authored:migration-0f91d40a2d288d1b-0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:compiler-output:group-key-probe-frontier:0:authored:migration-626660b1f63e8525-0 -->`CallbackFunc` may be null to probe the group without retrieving its keys.
The optional expected version is checked in either mode. A missing group or
version mismatch returns `DXGI_ERROR_NOT_FOUND`. The probe does not certify
that the referenced values exist.<!-- d3d12-review-inline:end:compiler-output:group-key-probe-frontier:0:authored:migration-626660b1f63e8525-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:group-key-probe-frontier:1:authored:migration-1fe4aa2913c8269b-0 -->With a callback, each key is borrowed only until that invocation returns.
No stable enumeration order across separate calls is specified.
`pExpectedGroupVersion` may be null to omit the version test. Otherwise it
supplies the expected `UINT` version, not a field embedded in `pGroupKey`.<!-- d3d12-review-inline:end:compiler-output:group-key-probe-frontier:1:authored:migration-1fe4aa2913c8269b-0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvaluekeys-returns:0:authored:migration-82759e699213f2bd-0 -->`S_OK` reports a matching group/key enumeration or null callback probe;
`DXGI_ERROR_NOT_FOUND` reports a missing group or version mismatch.
Database failures can propagate. A successful key probe does not prove
referenced values exist.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvaluekeys-returns:0:authored:migration-82759e699213f2bd-0 --></ins>

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

This method <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvalues-source:2:modified:source-73fd30a04502dbf1-0-0 -->directly retrieves stored matching typed values from the backing databases. It is not equivalent to requiring a successful FindValue for every key returned by FindGroupValueKeys; keys without selected stored values are omitted<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvalues-source:2:modified:source-73fd30a04502dbf1-0-0 --></ins>.

Use a nullptr callback to determine <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvalues-source:3:modified:source-bba12b62c459a0c7-0-0 -->whether matching selected stored values of the group are present without retrieving their buffers<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvalues-source:3:modified:source-bba12b62c459a0c7-0-0 --></ins>.

<ins><!-- d3d12-review-inline:begin:compiler-output:group-values-frontier:0:authored:migration-0a52dc0ce9988334-0 -->`ValueTypeFlags` must be nonzero, contain only declared value type bits, and
select only types assigned to this session. Invalid masks return
`E_INVALIDARG`. `CallbackFunc` may be null to probe without retrieving value
buffers. The same group/version and selected-row tests apply.<!-- d3d12-review-inline:end:compiler-output:group-values-frontier:0:authored:migration-0a52dc0ce9988334-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:group-values-frontier:1:authored:migration-b9c520dd698f6baa-0 -->This is a sparse enumeration of stored selected typed values. A group can
reference keys A and B while only A has selected stored values. A query of
that backing database can return `S_OK` and enumerate A without reporting B.
An absent selected type does not receive a synthetic callback. Neither a null
callback probe nor `S_OK` certifies every group key or every requested type.<!-- d3d12-review-inline:end:compiler-output:group-values-frontier:1:authored:migration-b9c520dd698f6baa-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:group-values-frontier:2:authored:migration-4f9f7549bfe6cf02-0 -->The lookup queries each backing database assigned at least one selected type.
Each backing query returns `S_OK` when it finds at least one matching selected
row, or `DXGI_ERROR_NOT_FOUND` when it finds none, including when the group or
expected version does not match. The overall call fails if any queried backing
database fails. Other backing queries can already have delivered callbacks.
Success in one database does not override a failure in another, and no generic
error priority or rollback guarantee is established.<!-- d3d12-review-inline:end:compiler-output:group-values-frontier:2:authored:migration-4f9f7549bfe6cf02-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:group-values-frontier:3:authored:migration-1dfc3c64bcc8070e-0 -->`ValueKeyIndex` is a dense rank over the value keys represented by the filtered
selected rows of that backing query, starting at zero. A key with no selected
rows is absent from that rank. Changing the type filter or stored rows can
renumber later keys. The index groups typed values within that enumeration.
It does not identify a key across queries, databases or a separate
`FindGroupValueKeys` enumeration.<!-- d3d12-review-inline:end:compiler-output:group-values-frontier:3:authored:migration-1dfc3c64bcc8070e-0 --></ins>

### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:0 -->`[in] pGroupKey`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:1 -->A unique key that identifies the group.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:1 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:2 -->`[in, optional] pExpectedGroupVersion`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:2 --></ins>

Optionally specify the version of the Group specified by pGroupKey expected in the database.  Used to fail early without reading the values when the version is not the expected version.  In this case of a version mismatch, DXGI_ERROR_NOT_FOUND is returned.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:4 -->`[in] ValueTypeFlags`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:4 --></ins>

Specify which values are retrieved from the cache session and passed to the D3D12CompilerCacheSessionGroupValuesFunc callback.  <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:5 -->Types not included in this flags parameter are not retrieved.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:5 --></ins>  Used as a performance optimization to prevent retrieval of unused values.  See [D3D12_COMPILER_VALUE_TYPE_FLAGS](#d3d12_compiler_value_type_flags).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:6 -->`[in, optional] CallbackFunc`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:6 --></ins>

A D3D12CompilerCacheSessionGroupValuesFunc that is called once for each <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:7:authored:source-46c0b4cdc4d9b097-0-0 -->selected stored <!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:7:authored:source-46c0b4cdc4d9b097-0-0 --></ins>typed value in the group.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:8 -->`[in, out, optional] pContext`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvalues-parameter-source:8 --></ins>

An application specified context pointer that is passed to the callback.  Use this to pass parameters to the callback function that receives the values.

### Return values

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findgroupvalues-returns:0:authored:migration-b01f8a19a7c5cf8b-0 -->Each queried backing database returns `S_OK` if it has matching selected rows,
or `DXGI_ERROR_NOT_FOUND` if it has none. The overall call succeeds only if
all queried databases succeed. A failing query does not undo callbacks from
other databases. Invalid masks return `E_INVALIDARG`. Other database failures
can propagate. `S_OK` is sparse-enumeration success, not complete-group
certification. A null callback is a legal probe with the same result rules.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findgroupvalues-returns:0:authored:migration-b01f8a19a7c5cf8b-0 --></ins>

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

When <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findvalue-source:2:modified:source-0a47f18cfbce0b63-0-0 -->a value is found, for each requested D3D12_COMPILER_CACHE_VALUE<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findvalue-source:2:modified:source-0a47f18cfbce0b63-0-0 --></ins>:

- If the ValueSize member is a non-zero value, the pValue member must point to a buffer of that size.  If ValueSize is greater than or equal to the value's actual size, the value is copied to pValue and the ValueSize member is assigned the actual size of the value.  If the caller specified ValueSize is insufficient, DXGI_ERROR_MORE_DATA is returned and the required size is assigned to the ValueSize member.
- <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findvalue-source:3 -->If the ValueSize member is zero and pCallbackFunc is non-nullptr, pCallbackFunc is called to allocate a buffer and the value is copied into it.  The allocated buffer pointer returned by pCallbackFunc is assigned to the pValue member on return. If pCallbackFunc returns nullptr, the call fails and returns E_OUTOFMEMORY.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findvalue-source:3 --></ins>
- The ValueSize member is assigned the value's actual size before returning.

To determine if a particular value type is stored without retrieving the value, use a size check for the value. To perform a size check, use a nullptr pValue with a zero ValueSize for the types to query and a nullptr pCallbackFunc.  <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findvalue-source:4 -->Within one backing database query, S_OK indicates that at least one requested value type is cached. DXGI_ERROR_NOT_FOUND indicates that none of that query's requested types is cached. The overall call fails if any queried backing database fails; successful output from another database can still be returned.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findvalue-source:4 --></ins>  ValueSize is non-zero for a cached value type.

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

<ins><!-- d3d12-review-inline:begin:compiler-output:typed-value-results:0:authored:migration-2f118333d33bc07f-0 -->`pValueKey` and the typed value array must be valid for the call;
`NumTypedValues` counts entries, not bytes. Each requested type must be a
declared type assigned to a database in this session and may occur only once.
Invalid, duplicate or unmapped types return `E_INVALIDARG`. Public API value
sizes are byte counts of type `UINT`. An empty typed list is not a key-existence
probe; request at least one named type to determine whether it is stored.<!-- d3d12-review-inline:end:compiler-output:typed-value-results:0:authored:migration-2f118333d33bc07f-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:typed-value-results:1:authored:migration-53c97f9e69e0f345-0 -->A nonzero input capacity requires a non-null writable `pValue`. Zero capacity
with no allocator requests only the size. Zero capacity with an allocator
requests allocation even when the input `pValue` is null. The allocator receives
the actual byte count and the caller's `pContext`. The returned pointer and
actual size are assigned to that typed value.<!-- d3d12-review-inline:end:compiler-output:typed-value-results:1:authored:migration-53c97f9e69e0f345-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:typed-value-results:2:authored:migration-12c47f45c8347c68-0 -->Results are per requested type. A missing type receives size zero. Within one
backing database query, finding at least one requested type gives `S_OK` if no
capacity, allocation or storage error occurs, even if another requested type
is absent. Finding none of that query's requested types gives
`DXGI_ERROR_NOT_FOUND`. This does not imply that the key has no other types.<!-- d3d12-review-inline:end:compiler-output:typed-value-results:2:authored:migration-12c47f45c8347c68-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:typed-value-results:3:authored:migration-5a0bfb0e4024dcdb-0 -->The session queries only databases assigned requested types. The overall call
fails if any queried database fails, including a database with none of its
requested types. Other databases can still supply sizes, copied bytes or
allocations. An overall failure does not discard those outputs. There is no
global any-type-anywhere success rule, generic error priority rule or atomic
all-types output guarantee.<!-- d3d12-review-inline:end:compiler-output:typed-value-results:3:authored:migration-5a0bfb0e4024dcdb-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:typed-value-results:4:authored:migration-bfb83e04044e295a-0 -->An undersized nonzero buffer returns `DXGI_ERROR_MORE_DATA` for that lookup and
receives the required size without copying that value. Other typed values can
still be copied or allocated. A null allocation result returns `E_OUTOFMEMORY`
but does not reclaim earlier allocations. The caller must free every
allocation it owns, including on failure.<!-- d3d12-review-inline:end:compiler-output:typed-value-results:4:authored:migration-bfb83e04044e295a-0 --></ins>

### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findvalue-parameter-source:0 -->`[in] pValueKey`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findvalue-parameter-source:0 --></ins>

A unique sequence of bytes that uniquely identifies an object in the database.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findvalue-parameter-source:2 -->`[in, out] pTypedValues`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findvalue-parameter-source:2 --></ins>

An array of typed values to retrieve the size or values of during the operation.  The array size is specified by NumTypedValues.  See [D3D12_COMPILER_CACHE_TYPED_VALUE](#d3d12_compiler_cache_typed_value).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findvalue-parameter-source:4 -->`[in] NumTypedValues`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findvalue-parameter-source:4 --></ins>

The number of typed values in the pTypedValues array.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findvalue-parameter-source:6 -->`[in, optional] pCallbackFunc`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findvalue-parameter-source:6 --></ins>

An optional callback function for allocating value buffers.  See <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findvalue-parameter-source:7:modified:source-345b1b73428e1617-0-0 -->Behavior<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findvalue-parameter-source:7:modified:source-345b1b73428e1617-0-0 --></ins>.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findvalue-parameter-source:8 -->`[in, out, optional] pContext`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findvalue-parameter-source:8 --></ins>

An application specified context pointer that is passed to the callback.  Use this to pass parameters to the allocation callback function.

### Return values

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-findvalue-returns:0:authored:migration-7c90da24e2dd7d98-0 -->`S_OK`, `DXGI_ERROR_NOT_FOUND`, `DXGI_ERROR_MORE_DATA`, `E_OUTOFMEMORY` and
`E_INVALIDARG` have the per-type meanings above. Other database failures can
propagate. A failing result does not imply untouched buffers, zero sizes or
no successful allocations.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-findvalue-returns:0:authored:migration-7c90da24e2dd7d98-0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-getapplicationdesc-returns:0:authored:migration-be1789ca000dfd4a-0 -->Returns a borrowed, read-only pointer to the resolved application descriptor.
The descriptor and its strings remain valid for the cache session's lifetime.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-getapplicationdesc-returns:0:authored:migration-be1789ca000dfd4a-0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-getcompilertarget-returns:0:authored:migration-50d5ff5e5dfc6297-0 -->Returns the resolved target, including the nonzero resolved ABI and
this factory's local family index.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-getcompilertarget-returns:0:authored:migration-50d5ff5e5dfc6297-0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-getvaluetypes-returns:0:authored:migration-257b584574e11da5-0 -->Returns the union of value type masks assigned to the session's database
paths. It does not enumerate which individual values have already been stored.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-getvaluetypes-returns:0:authored:migration-257b584574e11da5-0 --></ins>

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

At least one value must be stored in the store operation, so the function returns E_INVALIDARG if <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storevalue-source:1:modified:source-4eb74642e057f2e6-0-0 -->pTypedValues is nullptr or NumTypedValues<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storevalue-source:1:modified:source-4eb74642e057f2e6-0-0 --></ins> is zero. Each value must have a non-zero size.  Only one value per type may be stored at a time.

This <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storevalue-source:2:modified:source-a79466541f27b6ce-0-0 -->API<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storevalue-source:2:modified:source-a79466541f27b6ce-0-0 --></ins> returns DXGI_ERROR_ALREADY_EXISTS if one of the non-nullptr values with <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storevalue-source:2:modified:source-a79466541f27b6ce-1-0 -->pValueKey<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storevalue-source:2:modified:source-a79466541f27b6ce-1-0 --></ins> already exists.

<ins><!-- d3d12-review-inline:begin:compiler-output:storevalue-routing-failure:0:authored:migration-7fb713d88675b21c-0 -->`pValueKey` identifies a byte sequence. `KeySize` is its byte count, not a
string character count. The same key can have different typed values.
`NumTypedValues` is an entry count. Each entry must select a declared, mapped
type without duplicates and supply a non-null readable buffer of nonzero byte
size. Invalid typed entries return `E_INVALIDARG`. A null `pTypedValues` or zero
`NumTypedValues` must return `E_INVALIDARG`. Neither is a legal empty store.
The buffers remain caller-owned and are borrowed during the call.<!-- d3d12-review-inline:end:compiler-output:storevalue-routing-failure:0:authored:migration-7fb713d88675b21c-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:storevalue-routing-failure:1:authored:migration-3430b5280ee67086-0 -->An existing key with a previously absent type can receive that type. An
already stored `(key, type)` conflicts with a repeated store even when its
bytes match. This is not an overwrite or success-by-equality operation.
Typed entries are routed to their assigned databases. Failure or duplication
in one database does not roll back stores completed in another.<!-- d3d12-review-inline:end:compiler-output:storevalue-routing-failure:1:authored:migration-3430b5280ee67086-0 --></ins>

### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storevalue-parameter-source:0 -->`[in] pValueKey`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storevalue-parameter-source:0 --></ins>

A unique sequence of bytes that uniquely identifies an object in the database.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storevalue-parameter-source:2 -->`[in] pTypedValues`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storevalue-parameter-source:2 --></ins>

An array of typed values to store.  The array size is specified by NumTypedValues.  See [D3D12_COMPILER_CACHE_TYPED_CONST_VALUE](#d3d12_compiler_cache_typed_const_value).

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storevalue-parameter-source:4 -->`[in] NumTypedValues`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storevalue-parameter-source:4 --></ins>

The number of values in the pTypedValues array.

### Return values

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storevalue-returns:0:authored:migration-a60dd3992bf34424-0 -->`S_OK` reports a successful store. `DXGI_ERROR_ALREADY_EXISTS` reports an
existing typed value; invalid typed arguments return `E_INVALIDARG`.
Storage/allocation failures can propagate. Multi-file partial persistence is
possible on failure; no universal rollback is promised.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storevalue-returns:0:authored:migration-a60dd3992bf34424-0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:compiler-output:storegroup-mapping:0:authored:migration-4a51d9ae3fee4753-0 -->`pGroupKey` is required and supplies the application's group key bytes.
`GroupVersion` is a separate `UINT`. `pValueKeys` supplies `NumValueKeys`
entries, each with its own key byte count. A valid group store requires a
nonempty key list. The buffers remain caller-owned and readable for the call.
The same group key cannot be inserted again with a new version or a different
list. A duplicate returns `DXGI_ERROR_ALREADY_EXISTS`. This call does not
replace existing mappings.<!-- d3d12-review-inline:end:compiler-output:storegroup-mapping:0:authored:migration-4a51d9ae3fee4753-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:storegroup-mapping:1:authored:migration-fb93abe2f6990301-0 -->The group mapping is stored in each database entry, including entries storing
different value types. Mapping existence does not validate referenced values.
Failure after writing one database can leave other mappings unchanged;
the call does not establish an all-files transaction or repair mismatched
mappings across existing files.<!-- d3d12-review-inline:end:compiler-output:storegroup-mapping:1:authored:migration-fb93abe2f6990301-0 --></ins>

### Parameters

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storegroupvaluekeys-parameter-source:0 -->`[in] pGroupKey`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storegroupvaluekeys-parameter-source:0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storegroupvaluekeys-parameter-source:1 -->A unique key that identifies the group.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storegroupvaluekeys-parameter-source:1 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storegroupvaluekeys-parameter-source:2 -->`[in] GroupVersion`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storegroupvaluekeys-parameter-source:2 --></ins>

The version number of the cached group.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storegroupvaluekeys-parameter-source:4 -->`[in] pValueKeys`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storegroupvaluekeys-parameter-source:4 --></ins>

An array of variable size keys in the group.  <ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storegroupvaluekeys-parameter-source:5:modified:source-8fdf4c10092886ac-0-0 -->Each D3D12_COMPILER_CACHE_VALUE_KEY contains its own KeySize<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storegroupvaluekeys-parameter-source:5:modified:source-8fdf4c10092886ac-0-0 --></ins>.

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storegroupvaluekeys-parameter-source:6 -->`[in] NumValueKeys`<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storegroupvaluekeys-parameter-source:6 --></ins>

The number of value keys in the group.

### Return values

<ins><!-- d3d12-review-inline:begin:compiler-output:id3d12compilercachesession-storegroupvaluekeys-returns:0:authored:migration-e13fa4312074065f-0 -->`S_OK` reports successful mapping storage. An existing group key returns
`DXGI_ERROR_ALREADY_EXISTS`, irrespective of the proposed new version.
Invalid lists or database failures can fail the call. Values need not exist,
and failure does not imply a rollback of other databases.<!-- d3d12-review-inline:end:compiler-output:id3d12compilercachesession-storegroupvaluekeys-returns:0:authored:migration-e13fa4312074065f-0 --></ins>

<a id="invoked-ddi"></a>

## Compiler and cache DDI behavior

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-ownership:0:authored:migration-ed0f56277556ae4d-0 -->The [compiler table](compiler-plugin-foundation.md#compiler-table-dependencies) and [cache callbacks](compiler-plugin-foundation.md#callback-dependencies) are declared in the plugin foundation. Build 2 additions use `D3D12DDIARG_ADD_TO_STATE_OBJECT_0072`, without an extra parent handle parameter.<!-- d3d12-review-inline:end:compiler-output:ddi-ownership:0:authored:migration-ed0f56277556ae4d-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-cache-session-handle:0:authored:migration-cd54f459f4941ea4-0 -->`D3D12DDI_HRTCOMPILERCACHESESSION` is valid only during one compile call. `D3D12DDI_HCOMPILERSTATEOBJECT` instead retains plugin state for later additions.<!-- d3d12-review-inline:end:compiler-output:ddi-cache-session-handle:0:authored:migration-cd54f459f4941ea4-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-cache-session-handle:2:authored:migration-8cf2b54fc87bc855-0 -->DDI value kinds have the [API output meanings](#d3d12_compiler_value_type), with the declared DDI field widths.<!-- d3d12-review-inline:end:compiler-output:ddi-cache-session-handle:2:authored:migration-8cf2b54fc87bc855-0 --></ins>

<a id="d3d12ddi_compiler_cache_value_type"></a>

### D3D12DDI_COMPILER_CACHE_VALUE_TYPE

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_value_type:0:authored:migration-52d56b02e054670e-0 -->**Declaration:** [D3D12DDI_COMPILER_CACHE_VALUE_TYPE](compiler-plugin-foundation.md#callback-dependencies).
Value meanings are defined by [D3D12_COMPILER_VALUE_TYPE](#d3d12_compiler_value_type).<!-- d3d12-review-inline:end:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_value_type:0:authored:migration-52d56b02e054670e-0 --></ins>

<a id="d3d12ddi_compiler_value_type_flags"></a>

### D3D12DDI_COMPILER_VALUE_TYPE_FLAGS

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-type-link-d3d12ddi_compiler_value_type_flags:0:authored:migration-0b79ee9920bb082e-0 -->**Declaration:** [D3D12DDI_COMPILER_VALUE_TYPE_FLAGS](compiler-plugin-foundation.md#callback-dependencies).
Output selection is defined by [D3D12_COMPILER_VALUE_TYPE_FLAGS](#d3d12_compiler_value_type_flags).<!-- d3d12-review-inline:end:compiler-output:ddi-type-link-d3d12ddi_compiler_value_type_flags:0:authored:migration-0b79ee9920bb082e-0 --></ins>

<a id="d3d12ddi_compiler_cache_value_key"></a>

### D3D12DDI_COMPILER_CACHE_VALUE_KEY

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_value_key:0:authored:migration-d50479f86e799305-0 -->**Declaration:** [D3D12DDI_COMPILER_CACHE_VALUE_KEY](compiler-plugin-foundation.md#callback-dependencies).
Key semantics are defined by [D3D12_COMPILER_CACHE_VALUE_KEY](#d3d12_compiler_cache_value_key).<!-- d3d12-review-inline:end:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_value_key:0:authored:migration-d50479f86e799305-0 --></ins>

<a id="d3d12ddi_compiler_cache_value"></a>

### D3D12DDI_COMPILER_CACHE_VALUE

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_value:0:authored:migration-b1cf59e23ae93f4f-0 -->**Declaration:** [D3D12DDI_COMPILER_CACHE_VALUE](compiler-plugin-foundation.md#callback-dependencies).
Buffer semantics are defined by [D3D12_COMPILER_CACHE_VALUE](#d3d12_compiler_cache_value).
The DDI uses `SIZE_T` for `ValueSize`, rather than the API's `UINT`.<!-- d3d12-review-inline:end:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_value:0:authored:migration-b1cf59e23ae93f4f-0 --></ins>

<a id="d3d12ddi_compiler_cache_typed_value"></a>

### D3D12DDI_COMPILER_CACHE_TYPED_VALUE

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_typed_value:0:authored:migration-055b15ca7fc010e5-0 -->**Declaration:** [D3D12DDI_COMPILER_CACHE_TYPED_VALUE](compiler-plugin-foundation.md#callback-dependencies).
The type and buffer pair follows [D3D12_COMPILER_CACHE_TYPED_VALUE](#d3d12_compiler_cache_typed_value),
using the [DDI buffer layout](#d3d12ddi_compiler_cache_value).<!-- d3d12-review-inline:end:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_typed_value:0:authored:migration-055b15ca7fc010e5-0 --></ins>

<a id="d3d12ddi_compiler_cache_const_value"></a>

### D3D12DDI_COMPILER_CACHE_CONST_VALUE

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_const_value:0:authored:migration-8a041d2543fdfae5-0 -->**Declaration:** [D3D12DDI_COMPILER_CACHE_CONST_VALUE](compiler-plugin-foundation.md#callback-dependencies).
Buffer semantics are defined by [D3D12_COMPILER_CACHE_CONST_VALUE](#d3d12_compiler_cache_const_value).
The DDI uses `SIZE_T` for `ValueSize`, rather than the API's `UINT`.<!-- d3d12-review-inline:end:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_const_value:0:authored:migration-8a041d2543fdfae5-0 --></ins>

<a id="d3d12ddi_compiler_cache_typed_const_value"></a>

### D3D12DDI_COMPILER_CACHE_TYPED_CONST_VALUE

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_typed_const_value:0:authored:migration-11157beaeb49fee6-0 -->**Declaration:** [D3D12DDI_COMPILER_CACHE_TYPED_CONST_VALUE](compiler-plugin-foundation.md#callback-dependencies).
The type and buffer pair follows [D3D12_COMPILER_CACHE_TYPED_CONST_VALUE](#d3d12_compiler_cache_typed_const_value),
using the [DDI const buffer layout](#d3d12ddi_compiler_cache_const_value).<!-- d3d12-review-inline:end:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_typed_const_value:0:authored:migration-11157beaeb49fee6-0 --></ins>

<a id="d3d12ddi_compiler_cache_callbacks"></a>

### D3D12DDI_COMPILER_CACHE_CALLBACKS

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_callbacks:0:authored:migration-d8d044191a1777f7-0 -->**Declaration:** [D3D12DDI_COMPILER_CACHE_CALLBACKS](compiler-plugin-foundation.md#callback-dependencies).<!-- d3d12-review-inline:end:compiler-output:ddi-type-link-d3d12ddi_compiler_cache_callbacks:0:authored:migration-d8d044191a1777f7-0 --></ins>

**Members**

*pfnCompilerCacheFindValue*

See [PFND3D12DDI_COMPILER_CACHE_FIND_VALUE_CB](#pfnd3d12ddi_compiler_cache_find_value_cb).

*pfnCompilerCacheStoreValue*

See [PFND3D12DDI_COMPILER_CACHE_STORE_VALUE_CB](#pfnd3d12ddi_compiler_cache_store_value_cb).

*pfnCompilerCacheSetObjectValueKeys*

See [PFND3D12DDI_COMPILER_CACHE_SET_OBJECT_VALUE_KEYS_CB](#pfnd3d12ddi_compiler_cache_set_object_value_keys_cb).

<a id="d3d12ddi_hrtcompilercachesession"></a>

### D3D12DDI_HRTCOMPILERCACHESESSION

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-handle-cache-prose:0:modified:migration-4c2a5665612233a7-0 -->The runtime's compiler cache session object.<!-- d3d12-review-inline:end:compiler-output:ddi-handle-cache-prose:0:modified:migration-4c2a5665612233a7-0 --></ins>

**Remarks**

This object is supplied during a <ins><!-- d3d12-review-inline:begin:compiler-output:ddi-handle-cache-prose:2:modified:source-9d100dcdbe3e1492-0-0 -->compilation<!-- d3d12-review-inline:end:compiler-output:ddi-handle-cache-prose:2:modified:source-9d100dcdbe3e1492-0-0 --></ins> operation and must be used to call D3D12DDI_COMPILER_CACHE_CALLBACKS.  A given cache session handle is only valid and has the lifetime of a single compile DDI call.

<a id="d3d12ddi_hcompiler"></a>

### D3D12DDI_HCOMPILER

A compiler object is instanced from <ins><!-- d3d12-review-inline:begin:compiler-output:ddi-compiler-object-concept:0:modified:source-b5afa745564d2d82-0-0 -->an<!-- d3d12-review-inline:end:compiler-output:ddi-compiler-object-concept:0:modified:source-b5afa745564d2d82-0-0 --></ins> adapter family and application identity.  <ins><!-- d3d12-review-inline:begin:compiler-output:ddi-compiler-object-concept:0:modified:source-b5afa745564d2d82-1-0 -->It is used<!-- d3d12-review-inline:end:compiler-output:ddi-compiler-object-concept:0:modified:source-b5afa745564d2d82-1-0 --></ins> to compile state objects and store them in a cache session.

A handle type representing the plugin's compiler object.

<a id="d3d12ddi_hrtcompiler"></a>

### D3D12DDI_HRTCOMPILER

A handle type representing the runtime compiler object.  <ins><!-- d3d12-review-inline:begin:compiler-output:ddi-handle-runtime-prose:0:modified:migration-2e4159a3062a2dd5-0 -->Allows compiler plugins<!-- d3d12-review-inline:end:compiler-output:ddi-handle-runtime-prose:0:modified:migration-2e4159a3062a2dd5-0 --></ins> to call back into runtime.

<a id="d3d12ddi_hcompilerstateobject"></a>

### D3D12DDI_HCOMPILERSTATEOBJECT

A handle type representing the compiler <ins><!-- d3d12-review-inline:begin:compiler-output:ddi-handle-state-object-prose:0:modified:source-4cc0d2130eb9669f-0-0 -->plugin's<!-- d3d12-review-inline:end:compiler-output:ddi-handle-state-object-prose:0:modified:source-4cc0d2130eb9669f-0-0 --></ins> state object.  This object type allows compiler plugins to store state between Create and AddTo state object calls.

<a id="pfnd3d12ddi_compiler_calc_private_compiler_size"></a>

### PFND3D12DDI_COMPILER_CALC_PRIVATE_COMPILER_SIZE

<ins><!-- d3d12-review-inline:begin:compiler-output:declaration-link-pfnd3d12ddi_compiler_calc_private_compiler_size:0:authored:migration-86fb0180250164ee-0 -->**Declaration:** [PFND3D12DDI_COMPILER_CALC_PRIVATE_COMPILER_SIZE](compiler-plugin-foundation.md#compiler-table-dependencies); [published header lines 356–360](../../spec-maintenance/d3d12/references/compiler-foundation-wdk-10.0.28000.2526.h#L356-L360).<!-- d3d12-review-inline:end:compiler-output:declaration-link-pfnd3d12ddi_compiler_calc_private_compiler_size:0:authored:migration-86fb0180250164ee-0 --></ins>

Determine the size of the driver compiler object.

**Parameters**

*pTarget*

Contains the adapter family and ABI version.  See [D3D12DDI_COMPILER_TARGET](compiler-plugin-foundation.md#ddi-target-descriptions).

*pApplicationDesc*

Describes the target application and version.  See [D3D12DDI_APPLICATION_DESC](compiler-plugin-foundation.md#d3d12ddi_application_desc).

**Remarks**

The memory for storing the <ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_compiler_size:7:modified:source-b2e230faa8970039-0-0 -->plugin's CPU<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_compiler_size:7:modified:source-b2e230faa8970039-0-0 --></ins> object representing the compiler is allocated by the caller. This method is used to calculate the <ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_compiler_size:7:modified:source-b2e230faa8970039-0-1 -->plugin's<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_compiler_size:7:modified:source-b2e230faa8970039-0-1 --></ins> object size.

<a id="pfnd3d12ddi_compiler_create_compiler"></a>

### PFND3D12DDI_COMPILER_CREATE_COMPILER

<ins><!-- d3d12-review-inline:begin:compiler-output:declaration-link-pfnd3d12ddi_compiler_create_compiler:0:authored:migration-e14032f44dbeabba-0 -->**Declaration:** [PFND3D12DDI_COMPILER_CREATE_COMPILER](compiler-plugin-foundation.md#compiler-table-dependencies); [published header lines 362–368](../../spec-maintenance/d3d12/references/compiler-foundation-wdk-10.0.28000.2526.h#L362-L368).<!-- d3d12-review-inline:end:compiler-output:declaration-link-pfnd3d12ddi_compiler_create_compiler:0:authored:migration-e14032f44dbeabba-0 --></ins>

Create the driver compiler object.

**Parameters**

*pTarget*

Contains the adapter family and ABI version.  See [D3D12DDI_COMPILER_TARGET](compiler-plugin-foundation.md#ddi-target-descriptions).

*pApplicationDesc*

Describes the target application and version.  See [D3D12DDI_APPLICATION_DESC](compiler-plugin-foundation.md#d3d12ddi_application_desc).

*hCompiler*

Handle for plugin compiler object.  Memory is allocated by the caller, and plugin places compiler object.

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-create-runtime-handle:0:authored:migration-9c093c2102dca824-0 -->`hRTCompiler` is the runtime compiler handle supplied to the plugin.
The size query and create/destroy entries also receive the owning
`hCompilerDDI` in the published ABI. The runtime allocates private object
storage using the reported byte size; destruction ends the placed plugin
object before that storage is reclaimed. The DDI create operation returns
an `HRESULT`. A failed plugin creation fails compiler creation.<!-- d3d12-review-inline:end:compiler-output:ddi-create-runtime-handle:0:authored:migration-9c093c2102dca824-0 --></ins>

<a id="pfnd3d12ddi_compiler_destroy_compiler"></a>

### PFND3D12DDI_COMPILER_DESTROY_COMPILER

<ins><!-- d3d12-review-inline:begin:compiler-output:declaration-link-pfnd3d12ddi_compiler_destroy_compiler:0:authored:migration-1f15bc7489a7429a-0 -->**Declaration:** [PFND3D12DDI_COMPILER_DESTROY_COMPILER](compiler-plugin-foundation.md#compiler-table-dependencies); [published header lines 370–373](../../spec-maintenance/d3d12/references/compiler-foundation-wdk-10.0.28000.2526.h#L370-L373).<!-- d3d12-review-inline:end:compiler-output:declaration-link-pfnd3d12ddi_compiler_destroy_compiler:0:authored:migration-1f15bc7489a7429a-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_destroy_compiler:0:modified:source-c97307ba43985d89-0-0 -->Destroy the plugin object placed in the caller-provided private allocation. The caller reclaims that allocation after placement destruction<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_destroy_compiler:0:modified:source-c97307ba43985d89-0-0 --></ins>.

**Parameters**

*hCompiler*

Handle for plugin compiler object.

<a id="compiler-ddi-operation-contract"></a>

### Shared compile DDI contract

<!-- d3d12-review-alert:begin:compiler-output:DEL-I02-ddi-operation-association:0:authored:migration-e1bddccd4c87a3f5-0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Compiler DDI | API operation |
> | --- | --- |
> | `PFND3D12DDI_COMPILER_COMPILE_PIPELINE_STATE` | [CompilePipelineState](#id3d12compiler-compilepipelinestate) |
> | `PFND3D12DDI_COMPILER_COMPILE_CREATE_STATE_OBJECT` | [CompileStateObject](#id3d12compiler-compilestateobject) |
> | `PFND3D12DDI_COMPILER_COMPILE_ADD_TO_STATE_OBJECT` | [CompileAddToStateObject](#id3d12compiler-compileaddtostateobject) |
>
> [Output storage](#output-storage), [completion](#compile-completion) and
> [the compiler error protocol](#compile-error-protocol) define their common
> operation semantics. The plugin uses [store](#pfnd3d12ddi_compiler_cache_store_value_cb)
> and [find](#pfnd3d12ddi_compiler_cache_find_value_cb) callbacks for compiled values.
> The [cache callback table](compiler-plugin-foundation.md#callback-table-type)
> is installed before compiler creation. On success, a compile DDI must not
> return until all compiled output is stored.

<!-- d3d12-review-alert:end:compiler-output:DEL-I02-ddi-operation-association:0:authored:migration-e1bddccd4c87a3f5-0 -->

<a id="pfnd3d12ddi_compiler_compile_pipeline_state"></a>

### PFND3D12DDI_COMPILER_COMPILE_PIPELINE_STATE

<ins><!-- d3d12-review-inline:begin:compiler-output:declaration-link-pfnd3d12ddi_compiler_compile_pipeline_state:0:authored:migration-61f771e62897d5b5-0 -->**Declaration:** [PFND3D12DDI_COMPILER_COMPILE_PIPELINE_STATE](compiler-plugin-foundation.md#compiler-table-dependencies); [published header lines 375–380](../../spec-maintenance/d3d12/references/compiler-foundation-wdk-10.0.28000.2526.h#L375-L380).<!-- d3d12-review-inline:end:compiler-output:declaration-link-pfnd3d12ddi_compiler_compile_pipeline_state:0:authored:migration-61f771e62897d5b5-0 --></ins>

Compile a graphics or compute pipeline state.

**Parameters**

*hCompiler*

Handle for plugin compiler object.

*hrtCompilerCacheSession*

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_pipeline_state:5 -->The compiler cache session callback handle.  Used with cache operations to find/store values and set the values associated with the object being compiled.  See [Cache Session Callbacks](#pfnd3d12ddi_compiler_cache_find_value_cb).<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_pipeline_state:5 --></ins>

*ValueTypeFlags*

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-output-timing-pipeline:0:modified:weekend-completion-order -->Specify which value types must be stored before successful return.<!-- d3d12-review-inline:end:compiler-output:ddi-output-timing-pipeline:0:modified:weekend-completion-order --></ins>  See [D3D12DDI_COMPILER_VALUE_TYPE_FLAGS](compiler-plugin-foundation.md#callback-dependencies).

*<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_pipeline_state:8:modified:source-66d01bf76f005833-0-0 -->pPipelineStateArg<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_pipeline_state:8:modified:source-66d01bf76f005833-0-0 --></ins>*

Creation arguments for the pipeline state object to compile.

**Remarks**

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_pipeline_state:14 -->The driver must call [PFND3D12DDI_COMPILER_CACHE_SET_OBJECT_VALUE_KEYS_CB](#pfnd3d12ddi_compiler_cache_set_object_value_keys_cb) once before returning success to set the values associated with this pipeline state object definition.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_pipeline_state:14 --></ins>

<a id="pfnd3d12ddi_compiler_calc_private_state_object_size"></a>

### PFND3D12DDI_COMPILER_CALC_PRIVATE_STATE_OBJECT_SIZE

<ins><!-- d3d12-review-inline:begin:compiler-output:declaration-link-pfnd3d12ddi_compiler_calc_private_state_object_size:0:authored:migration-2902e26962e4681c-0 -->**Declaration:** [PFND3D12DDI_COMPILER_CALC_PRIVATE_STATE_OBJECT_SIZE](compiler-plugin-foundation.md#compiler-table-dependencies); [published header lines 382–385](../../spec-maintenance/d3d12/references/compiler-foundation-wdk-10.0.28000.2526.h#L382-L385).<!-- d3d12-review-inline:end:compiler-output:declaration-link-pfnd3d12ddi_compiler_calc_private_state_object_size:0:authored:migration-2902e26962e4681c-0 --></ins>

Calculate the size needed for <ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_state_object_size:0:modified:source-8fd326d99b1a0626-0-0 -->compiler's<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_state_object_size:0:modified:source-8fd326d99b1a0626-0-0 --></ins> state object implementation.

**Parameters**

*hCompiler*

Handle for plugin compiler object.

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_state_object_size:4 -->*pCreateStateObject*<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_state_object_size:4 --></ins>

Creation arguments for the state object.

<a id="pfnd3d12ddi_compiler_compile_create_state_object"></a>

### PFND3D12DDI_COMPILER_COMPILE_CREATE_STATE_OBJECT

<ins><!-- d3d12-review-inline:begin:compiler-output:declaration-link-pfnd3d12ddi_compiler_compile_create_state_object:0:authored:migration-86fb950f7e08b320-0 -->**Declaration:** [PFND3D12DDI_COMPILER_COMPILE_CREATE_STATE_OBJECT](compiler-plugin-foundation.md#compiler-table-dependencies); [published header lines 387–393](../../spec-maintenance/d3d12/references/compiler-foundation-wdk-10.0.28000.2526.h#L387-L393).<!-- d3d12-review-inline:end:compiler-output:declaration-link-pfnd3d12ddi_compiler_compile_create_state_object:0:authored:migration-86fb950f7e08b320-0 --></ins>

**Parameters**

*hCompiler*

Handle for plugin compiler object.

*hrtCompilerCacheSession*

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_create_state_object:4 -->The compiler cache session callback handle.  Used with cache operations to find/store values and set the values associated with the object being compiled.  See [Cache Session Callbacks](#pfnd3d12ddi_compiler_cache_find_value_cb).<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_create_state_object:4 --></ins>

*ValueTypeFlags*

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-output-timing-state-object:0:modified:weekend-completion-order -->Specify which value types must be stored before successful return.<!-- d3d12-review-inline:end:compiler-output:ddi-output-timing-state-object:0:modified:weekend-completion-order --></ins>  See [D3D12DDI_COMPILER_VALUE_TYPE_FLAGS](compiler-plugin-foundation.md#callback-dependencies).

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_create_state_object:7 -->*pCreateStateObject*<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_create_state_object:7 --></ins>

Creation arguments for the state object.

*hStateObject*

A handle pointing to the pre-allocated space for the compiler object.  Compiler places the object in this allocation and uses it to store state to support future calls to [PFND3D12DDI_COMPILER_COMPILE_ADD_TO_STATE_OBJECT](#pfnd3d12ddi_compiler_compile_add_to_state_object) calls.

**Remarks**

The lifetime of <ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_create_state_object:12:modified:source-29e9ce5146786077-0-0 -->pCreateStateObject<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_create_state_object:12:modified:source-29e9ce5146786077-0-0 --></ins> is guaranteed until hStateObject is destroyed; therefore, compiler only needs to store a pointer to this structure to support future AddToStateObject calls.  Compiler must store other state needed for future compilation with hStateObject, such as keys to lookup stored values.

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_create_state_object:16 -->The driver must call [PFND3D12DDI_COMPILER_CACHE_SET_OBJECT_VALUE_KEYS_CB](#pfnd3d12ddi_compiler_cache_set_object_value_keys_cb) once before returning success to set the values associated with this state object definition. A collection CompileStateObject that produces no compiled output may omit this callback and have no group.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_create_state_object:16 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-collection-frontier:0:authored:migration-15ff38484203aff5-0 -->A no-output collection may consequently have no output group. The exception
does not apply to pipeline state compilation, executable state object
compilation or additions.<!-- d3d12-review-inline:end:compiler-output:ddi-collection-frontier:0:authored:migration-15ff38484203aff5-0 --></ins>

<a id="pfnd3d12ddi_compiler_calc_private_add_to_state_object_size"></a>

### PFND3D12DDI_COMPILER_CALC_PRIVATE_ADD_TO_STATE_OBJECT_SIZE

<ins><!-- d3d12-review-inline:begin:compiler-output:declaration-link-pfnd3d12ddi_compiler_calc_private_add_to_state_object_size:0:authored:migration-0e12db673735b560-0 -->**Declaration:** [PFND3D12DDI_COMPILER_CALC_PRIVATE_ADD_TO_STATE_OBJECT_SIZE](compiler-plugin-foundation.md#compiler-table-dependencies); [published header lines 395–398](../../spec-maintenance/d3d12/references/compiler-foundation-wdk-10.0.28000.2526.h#L395-L398).<!-- d3d12-review-inline:end:compiler-output:declaration-link-pfnd3d12ddi_compiler_calc_private_add_to_state_object_size:0:authored:migration-0e12db673735b560-0 --></ins>

Calculate the size needed for <ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_add_to_state_object_size:0:modified:source-5de1bc35681f4c24-0-0 -->compiler's<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_add_to_state_object_size:0:modified:source-5de1bc35681f4c24-0-0 --></ins> state object implementation when adding to an existing state object.

**Parameters**

*hCompiler*

Handle for plugin compiler object.

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_add_to_state_object_size:4 -->*pAddToStateObject*<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_add_to_state_object_size:4 --></ins>

Creation arguments for the add operation.

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_add_to_state_object_size:6 -->The parent handle is carried in pAddToStateObject->StateObjectToGrowFrom.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_calc_private_add_to_state_object_size:6 --></ins>

<a id="pfnd3d12ddi_compiler_compile_add_to_state_object"></a>

### PFND3D12DDI_COMPILER_COMPILE_ADD_TO_STATE_OBJECT

<ins><!-- d3d12-review-inline:begin:compiler-output:declaration-link-pfnd3d12ddi_compiler_compile_add_to_state_object:0:authored:migration-e6144ae56fb7298a-0 -->**Declaration:** [PFND3D12DDI_COMPILER_COMPILE_ADD_TO_STATE_OBJECT](compiler-plugin-foundation.md#compiler-table-dependencies); [published header lines 400–406](../../spec-maintenance/d3d12/references/compiler-foundation-wdk-10.0.28000.2526.h#L400-L406).<!-- d3d12-review-inline:end:compiler-output:declaration-link-pfnd3d12ddi_compiler_compile_add_to_state_object:0:authored:migration-e6144ae56fb7298a-0 --></ins>

**Parameters**

*hCompiler*

Handle for plugin compiler object.

*hrtCompilerCacheSession*

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:4 -->The compiler cache session callback handle.  Used with cache operations to find/store values and set the values associated with the object being compiled.  See [Cache Session Callbacks](#pfnd3d12ddi_compiler_cache_find_value_cb).<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:4 --></ins>

*ValueTypeFlags*

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-output-timing-addition:0:modified:weekend-completion-order -->Specify which value types must be stored before successful return.<!-- d3d12-review-inline:end:compiler-output:ddi-output-timing-addition:0:modified:weekend-completion-order --></ins>  See [D3D12DDI_COMPILER_VALUE_TYPE_FLAGS](compiler-plugin-foundation.md#callback-dependencies).

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:7 -->*pAddToStateObject*<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:7 --></ins>

Creation arguments for the add operation.

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:9 -->The parent handle is carried in pAddToStateObject->StateObjectToGrowFrom.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:9 --></ins>

*hStateObject*

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:11 -->A handle pointing to the pre-allocated space for the compiler object.  Compiler places the object in this allocation and uses it to store state to support future AddToStateObject calls.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:11 --></ins>

**Remarks**

The <ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:13:modified:source-9a70078a2c7eb806-0-0 -->pAddToStateObject description remains valid until hStateObject is destroyed, so the compiler can retain a pointer to that description for later additions. The StateObjectToGrowFrom plugin handle need not remain alive with the child; the plugin must retain the dependency state it needs<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:13:modified:source-9a70078a2c7eb806-0-0 --></ins>.  Compiler must store other state needed for future compilation with hStateObject, such as keys to lookup stored values.

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:17 -->The driver must call [PFND3D12DDI_COMPILER_CACHE_SET_OBJECT_VALUE_KEYS_CB](#pfnd3d12ddi_compiler_cache_set_object_value_keys_cb) once before returning success to set the values associated with this state object definition.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_compile_add_to_state_object:17 --></ins>

<a id="pfnd3d12ddi_compiler_destroy_state_object"></a>

### PFND3D12DDI_COMPILER_DESTROY_STATE_OBJECT

<ins><!-- d3d12-review-inline:begin:compiler-output:declaration-link-pfnd3d12ddi_compiler_destroy_state_object:0:authored:migration-fab98851c0376d57-0 -->**Declaration:** [PFND3D12DDI_COMPILER_DESTROY_STATE_OBJECT](compiler-plugin-foundation.md#compiler-table-dependencies); [published header lines 408–411](../../spec-maintenance/d3d12/references/compiler-foundation-wdk-10.0.28000.2526.h#L408-L411).<!-- d3d12-review-inline:end:compiler-output:declaration-link-pfnd3d12ddi_compiler_destroy_state_object:0:authored:migration-fab98851c0376d57-0 --></ins>

Destroys <ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_destroy_state_object:0:modified:source-05290b4ea96ede2e-0-0 -->the<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_destroy_state_object:0:modified:source-05290b4ea96ede2e-0-0 --></ins> compiler state object <ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_destroy_state_object:0:modified:source-05290b4ea96ede2e-0-1 -->placed in the caller-provided private allocation. The caller reclaims the allocation after the plugin destroys its placed object<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_destroy_state_object:0:modified:source-05290b4ea96ede2e-0-1 --></ins>.

**Parameters**

*hCompiler*

Handle for plugin compiler object.

*hStateObject*

The state object to destroy.

<a id="pfnd3d12ddi_compiler_cache_find_value_cb"></a>

### PFND3D12DDI_COMPILER_CACHE_FIND_VALUE_CB

<ins><!-- d3d12-review-inline:begin:compiler-output:declaration-link-pfnd3d12ddi_compiler_cache_find_value_cb:0:authored:migration-e24d87558763589c-0 -->**Declaration:** [PFND3D12DDI_COMPILER_CACHE_FIND_VALUE_CB](compiler-plugin-foundation.md#callback-dependencies); [published header lines 236–243](../../spec-maintenance/d3d12/references/compiler-foundation-wdk-10.0.28000.2526.h#L236-L243).<!-- d3d12-review-inline:end:compiler-output:declaration-link-pfnd3d12ddi_compiler_cache_find_value_cb:0:authored:migration-e24d87558763589c-0 --></ins>

Find a previously stored value in the cache.

**Parameters**

*<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_cache_find_value_cb:2:modified:source-9ccf69e761668106-0-0 -->hrtCompilerCache<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_cache_find_value_cb:2:modified:source-9ccf69e761668106-0-0 --></ins>*

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

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-find-results:0:authored:migration-a6d6233b9c4dacb2-0 -->The callback uses the [FindValue result and buffer protocol](#id3d12compilercachesession-findvalue). Its allocator must return suitably aligned storage or null and must not let exceptions escape. The plugin frees successful allocations, including those made before a later lookup failure.<!-- d3d12-review-inline:end:compiler-output:ddi-find-results:0:authored:migration-a6d6233b9c4dacb2-0 --></ins>

<a id="pfnd3d12ddi_compiler_cache_store_value_cb"></a>

### PFND3D12DDI_COMPILER_CACHE_STORE_VALUE_CB

<ins><!-- d3d12-review-inline:begin:compiler-output:declaration-link-pfnd3d12ddi_compiler_cache_store_value_cb:0:authored:migration-048262234171df61-0 -->**Declaration:** [PFND3D12DDI_COMPILER_CACHE_STORE_VALUE_CB](compiler-plugin-foundation.md#callback-dependencies); [published header lines 245–250](../../spec-maintenance/d3d12/references/compiler-foundation-wdk-10.0.28000.2526.h#L245-L250).<!-- d3d12-review-inline:end:compiler-output:declaration-link-pfnd3d12ddi_compiler_cache_store_value_cb:0:authored:migration-048262234171df61-0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_cache_store_value_cb:13 -->Flags during the compile operation indicate which values must be stored.  See [D3D12DDI_COMPILER_VALUE_TYPE_FLAGS](compiler-plugin-foundation.md#callback-dependencies).  Values are optionally stored to accommodate various scenarios such as generating PDB for existing object code with a matching compiler and source or Shader Explorer only needing the performance data output.<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_cache_store_value_cb:13 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-store-results:0:authored:migration-7f73583285286bb5-0 -->[StoreValue](#id3d12compilercachesession-storevalue) defines the nonempty typed
input, duplicate-store and per-database result protocol. The DDI uses its
[const value buffer layout](#d3d12ddi_compiler_cache_const_value). Input buffers
remain plugin-owned and are consumed during the callback.
Before successful compilation, requested value kinds must be available through the cache callbacks. The plugin may store types separately or reuse stored values. It handles store failures and need not undo earlier successful stores.<!-- d3d12-review-inline:end:compiler-output:ddi-store-results:0:authored:migration-7f73583285286bb5-0 --></ins>

<a id="pfnd3d12ddi_compiler_cache_set_object_value_keys_cb"></a>

### PFND3D12DDI_COMPILER_CACHE_SET_OBJECT_VALUE_KEYS_CB

<ins><!-- d3d12-review-inline:begin:compiler-output:declaration-link-pfnd3d12ddi_compiler_cache_set_object_value_keys_cb:0:authored:migration-02ab780d87ba0f6a-0 -->**Declaration:** [PFND3D12DDI_COMPILER_CACHE_SET_OBJECT_VALUE_KEYS_CB](compiler-plugin-foundation.md#callback-dependencies); [published header lines 252–256](../../spec-maintenance/d3d12/references/compiler-foundation-wdk-10.0.28000.2526.h#L252-L256).<!-- d3d12-review-inline:end:compiler-output:declaration-link-pfnd3d12ddi_compiler_cache_set_object_value_keys_cb:0:authored:migration-02ab780d87ba0f6a-0 --></ins>

A callback to set the list of value keys associated with an object.

**Parameters**

*hrtCompilerCacheSession*

The compiler cache session  callback handle received during a compilation operation.

*<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_cache_set_object_value_keys_cb:4:modified:source-fbc0ae225017a9f6-0-0 -->pValueKeys<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_cache_set_object_value_keys_cb:4:modified:source-fbc0ae225017a9f6-0-0 --></ins>*

The unique identifiers for the values.  See [D3D12DDI_COMPILER_CACHE_VALUE_KEY](compiler-plugin-foundation.md#callback-dependencies).

*NumValueKeys*

The number of keys specified by <ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_cache_set_object_value_keys_cb:7:modified:source-e36bda96edfe8249-0-0 -->pValueKeys<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_cache_set_object_value_keys_cb:7:modified:source-e36bda96edfe8249-0-0 --></ins>.

**Remarks**

This stored list specifies the values that the driver receives during title cooperative scenarios.  It may also be used for other database management operations to map values back to state object definitions.  The compiler plugin must call this function once before returning <ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_cache_set_object_value_keys_cb:9:authored:source-e97fd42548ba1ae6-0-0 -->success <!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_cache_set_object_value_keys_cb:9:authored:source-e97fd42548ba1ae6-0-0 --></ins>from a compile operation<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-pfnd3d12ddi_compiler_cache_set_object_value_keys_cb:9:modified:source-e97fd42548ba1ae6-0-1 -->. A collection CompileStateObject that produces no compiled output may omit this callback and have no group<!-- d3d12-review-inline:end:compiler-output:ddi-pfnd3d12ddi_compiler_cache_set_object_value_keys_cb:9:modified:source-e97fd42548ba1ae6-0-1 --></ins>.

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-group-completion:0:authored:migration-b8bb25b5a6e20cb7-0 -->The callback associates vendor-generated `pValueKeys` with the API application key and GroupVersion. Registration does not verify that all requested value kinds exist.<!-- d3d12-review-inline:end:compiler-output:ddi-group-completion:0:authored:migration-b8bb25b5a6e20cb7-0 --></ins>

<ins><!-- d3d12-review-inline:begin:compiler-output:ddi-group-completion:1:authored:migration-c91c85cd5c203a0e-0 -->The host accepts an already-existing-group result from this callback and returns other group store failures to the plugin.<!-- d3d12-review-inline:end:compiler-output:ddi-group-completion:1:authored:migration-c91c85cd5c203a0e-0 --></ins>

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
