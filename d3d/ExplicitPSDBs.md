# D3D12: Using Multiple Explicit PSDBs

- [D3D12: Using Multiple Explicit PSDBs](#d3d12-using-multiple-explicit-psdbs)
  - [Introduction](#introduction)
  - [API](#api)
    - [Enum: D3D12\_FEATURE](#enum-d3d12_feature)
    - [Struct: D3D12\_FEATURE\_DATA\_EXPLICIT\_PSDBS](#struct-d3d12_feature_data_explicit_psdbs)
    - [Enum: D3D12\_PIPELINE\_STATE\_SUBOBJECT\_TYPE](#enum-d3d12_pipeline_state_subobject_type)
    - [Enum: D3D12\_STATE\_SUBOBJECT\_TYPE](#enum-d3d12_state_subobject_type)
    - [Enum: D3D12\_SHADER\_CACHE\_SESSION\_SUBOBJECT\_FLAGS](#enum-d3d12_shader_cache_session_subobject_flags)
    - [Struct: D3D12\_SHADER\_CACHE\_SESSION\_SUBOBJECT\_DESC](#struct-d3d12_shader_cache_session_subobject_desc)
    - [Enumeration: D3D12\_CACHE\_VALUE\_TYPE](#enumeration-d3d12_cache_value_type)
    - [Enumeration: D3D12\_CACHE\_VALUE\_TYPE\_FLAGS](#enumeration-d3d12_cache_value_type_flags)
    - [Struct: D3D12\_CACHE\_VALUE\_KEY](#struct-d3d12_cache_value_key)
    - [Struct: D3D12\_CACHE\_VALUE](#struct-d3d12_cache_value)
    - [Struct: D3D12\_CACHE\_TYPED\_VALUE](#struct-d3d12_cache_typed_value)
    - [Struct: D3D12\_CACHE\_CONST\_VALUE](#struct-d3d12_cache_const_value)
    - [Struct: D3D12\_CACHE\_TYPED\_CONST\_VALUE](#struct-d3d12_cache_typed_const_value)
    - [Enum: D3D12\_SHADER\_CACHE\_MODE](#enum-d3d12_shader_cache_mode)
    - [Enum: D3D12\_SHADER\_CACHE\_KIND\_FLAGS](#enum-d3d12_shader_cache_kind_flags)
    - [Struct: D3D12\_SHADER\_CACHE\_SESSION\_MEMORY\_DESC](#struct-d3d12_shader_cache_session_memory_desc)
    - [Struct: D3D12\_SHADER\_CACHE\_SESSION\_DISK\_DESC](#struct-d3d12_shader_cache_session_disk_desc)
    - [Enum: D3D12\_SHADER\_CACHE\_SESSION\_REGISTERED\_FLAGS](#enum-d3d12_shader_cache_session_registered_flags)
    - [Struct: D3D12\_SHADER\_CACHE\_SESSION\_REGISTERED\_DESC](#struct-d3d12_shader_cache_session_registered_desc)
    - [Struct: D3D12\_CACHE\_FILE\_DESC](#struct-d3d12_cache_file_desc)
    - [Enum: D3D12\_SHADER\_CACHE\_SESSION\_FILE\_FLAGS](#enum-d3d12_shader_cache_session_file_flags)
    - [Struct: D3D12\_SHADER\_CACHE\_SESSION\_FILE\_DESC](#struct-d3d12_shader_cache_session_file_desc)
    - [Struct: D3D12\_SHADER\_CACHE\_SESSION\_DESC1](#struct-d3d12_shader_cache_session_desc1)
    - [Interface: ID3D12Device16](#interface-id3d12device16)
      - [Method: CreateShaderCacheSession1](#method-createshadercachesession1)
    - [Enum: D3D12\_SHADER\_CACHE\_STORE\_FLAGS](#enum-d3d12_shader_cache_store_flags)
    - [Interface: ID3D12ShaderCacheSession1](#interface-id3d12shadercachesession1)
      - [Method: FindValue1](#method-findvalue1)
      - [Method: StoreValue1](#method-storevalue1)
  - [D3DX12 Inline Helpers](#d3dx12-inline-helpers)
    - [d3dx12\_pipeline\_state\_stream helper](#d3dx12_pipeline_state_stream-helper)
    - [d3dx12\_state\_object helper](#d3dx12_state_object-helper)
  - [Samples](#samples)
    - [Check for Support](#check-for-support)
    - [Using a FILE PSDB for Creating a PSO](#using-a-file-psdb-for-creating-a-pso)
    - [Using a Registered PSDB to Explicit Cache Session for Creating a PSO](#using-a-registered-psdb-to-explicit-cache-session-for-creating-a-pso)
    - [Using a FILE PSDB for Creating a SO](#using-a-file-psdb-for-creating-a-so)
    - [Using a Registered PSDB to Explicit Cache Session for Creating SO](#using-a-registered-psdb-to-explicit-cache-session-for-creating-so)
    - [Using ID3D12ShaderCacheSession1::FindValue1 with D3D12CacheSessionAllocationFunc](#using-id3d12shadercachesession1findvalue1-with-d3d12cachesessionallocationfunc)

## Introduction

Direct3D 12 Advanced Shader Delivery supports one implicit default Precompiled Shader Database (PSDB) per application.  This default PSDB is set when the application is registered with the D3D Shader Cache Registration API, and a component with the name "default" is registered for the target GPU and driver.  This default is implicitly used by the runtime for cache value lookup when creating a Pipeline State Object(PSO) or State Object (SO).

This feature allows callers to explicitly specify the PSDB to use for cache value lookups per PSO or SO creation.  An explicitly specified PSDB overrides the implicit default by redirecting any PSDB cache lookups to the explicitly specified cache session.  Using this option does not override local driver caching.  If driver does not find a cache value in the PSDB, the driver compiles that value locally and stores it in the local cache.

Cache sessions can be created from a D3D Shader Cache Registration component name.  This allows stores to accept multiple SODBs with their component name, compile each for the target GPU, and finally deliver and register them with the client.  The game can then create a cache session from the component name they specified and use them explicitly when creating objects.  Any PSO or SO created without an explicit PSDB uses the implicit default.

There is also an option to create a cache session from a filename.  Developers can use this option or the registration option above to swap out sets of cached shaders in local development.

## API

### Enum: D3D12_FEATURE

```idl
typedef enum D3D12_FEATURE
{
    // Other enum values are omitted.

    D3D12_FEATURE_EXPLICIT_PSDBS,
};
```

**Constants**

Check for feature support.  This feature check data struct contains ExplicitPsdbsSupported.  see [D3D12_FEATURE_DATA_EXPLICIT_PSDBS](#struct-d3d12_feature_data_explicit_psdbs).

### Struct: D3D12_FEATURE_DATA_EXPLICIT_PSDBS

```idl
// D3D12_FEATURE_EXPLICIT_PSDBS
typedef struct D3D12_FEATURE_DATA_EXPLICIT_PSDBS
{
    BOOL ExplicitPsdbsSupported;
} D3D12_FEATURE_DATA_EXPLICIT_PSDBS;
```

**Members**

*ExplicitPsdbsSupported*

True if the driver supports Advanced Shader Delivery and the runtime supports explicit PSDBs.  Returns FALSE on non-Win32 platforms.

### Enum: D3D12_PIPELINE_STATE_SUBOBJECT_TYPE

```c++
typedef enum D3D12_PIPELINE_STATE_SUBOBJECT_TYPE
{
    // Other enum values are omitted.

    D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_PSDB = 30, // D3D12_SHADER_CACHE_SESSION_SUBOBJECT_DESC

} D3D12_PIPELINE_STATE_SUBOBJECT_TYPE;

```

**Constants**

*D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_PSDB*

Use this subobject type to specify the Precompiled Shader Database (PSDB) cache session and lifetime behavior to use when creating this PSO.

### Enum: D3D12_STATE_SUBOBJECT_TYPE

```c++
typedef 
enum D3D12_STATE_SUBOBJECT_TYPE
{
    // Other enum values are omitted.

    D3D12_STATE_SUBOBJECT_TYPE_PSDB = 43, // D3D12_SHADER_CACHE_SESSION_SUBOBJECT_DESC
}
```

**Constants**

*D3D12_STATE_SUBOBJECT_TYPE_PSDB*

Use this subobject type to specify the Precompiled Shader Database (PSDB) cache session and lifetime behavior to use when creating this SO.

When using AddToStateObject, the grown state object does not inherit the base state object's PSDB.  Each generation must specify its own PSDB subobject if explicit PSDB lookups are desired.

### Enum: D3D12_SHADER_CACHE_SESSION_SUBOBJECT_FLAGS

```c++
typedef enum D3D12_SHADER_CACHE_SESSION_SUBOBJECT_FLAGS
{
    D3D12_SHADER_CACHE_SESSION_SUBOBJECT_FLAG_NONE = 0x0,
    D3D12_SHADER_CACHE_SESSION_SUBOBJECT_FLAG_CREATE_ONLY = 0x1,
} D3D12_SHADER_CACHE_SESSION_SUBOBJECT_FLAGS;
DEFINE_ENUM_FLAG_OPERATORS(D3D12_SHADER_CACHE_SESSION_SUBOBJECT_FLAGS)
```

**Constants**

*D3D12_SHADER_CACHE_SESSION_SUBOBJECT_FLAG_NONE*

The created PSO or SO retains a reference to the explicit PSDB session. This allows the runtime or driver to perform PSDB lookups after the creation call returns.

*D3D12_SHADER_CACHE_SESSION_SUBOBJECT_FLAG_CREATE_ONLY*

The explicit PSDB session is used only while creating the PSO or SO. The runtime releases its reference to the session when creation finishes. Subsequent PSDB lookups associated with that object use registration's implicit default PSDB, if one is available.

### Struct: D3D12_SHADER_CACHE_SESSION_SUBOBJECT_DESC

```c++
typedef struct D3D12_SHADER_CACHE_SESSION_SUBOBJECT_DESC
{
    ID3D12ShaderCacheSession1* pSession;
    D3D12_SHADER_CACHE_SESSION_SUBOBJECT_FLAGS Flags;
} D3D12_SHADER_CACHE_SESSION_SUBOBJECT_DESC;
```

**Members**

*pSession*

The explicit PSDB session. The pointer must not be nullptr when Flags is not D3D12_SHADER_CACHE_SESSION_SUBOBJECT_FLAG_NONE.

*Flags*

Controls how long the created object retains a reference to pSession.

**Remarks**

Unknown flag values are invalid. A null session with non-zero flags is also invalid.

### Enumeration: D3D12_CACHE_VALUE_TYPE

A type enumeration used when only a single value type may be selected.

```c++
typedef enum D3D12_CACHE_VALUE_TYPE
{
    D3D12_CACHE_VALUE_TYPE_OBJECT_CODE       = 0,
    D3D12_CACHE_VALUE_TYPE_METADATA          = 1,
    D3D12_CACHE_VALUE_TYPE_DEBUG_PDB         = 2,
    D3D12_CACHE_VALUE_TYPE_PERFORMANCE_DATA  = 3,
} D3D12_CACHE_VALUE_TYPE;
```

**Constants**

*D3D12_CACHE_VALUE_TYPE_OBJECT_CODE*

Specifies object code.  The compiled executable code that is run on GPU.

*D3D12_CACHE_VALUE_TYPE_METADATA*

Metadata that the compiler may provide about the compile.  For example it may store a compiler version number used for validation.  Such a thing should not be put inside of the object code as users of this system expect to be able to do memcmp diffing between compiler versions.  

*D3D12_CACHE_VALUE_TYPE_DEBUG_PDB*

The Debug PDB for the object code.  Used in pix and other debug scenarios.  An opaque blob that still requires IHV interpretation to used with PIX.

*D3D12_CACHE_VALUE_TYPE_PERFORMANCE_DATA*

Performance data about the compile or produced object code.  An opaque blob that still requires IHV interpretation to used with PIX.

**Remarks**

### Enumeration: D3D12_CACHE_VALUE_TYPE_FLAGS

A flags enumeration used where multiple values may be selected.

```c++
typedef enum D3D12_CACHE_VALUE_TYPE_FLAGS
{ 
    D3D12_CACHE_VALUE_TYPE_FLAGS_NONE                = 0x00000000,
    D3D12_CACHE_VALUE_TYPE_FLAGS_OBJECT_CODE         = (1 << D3D12_CACHE_VALUE_TYPE_OBJECT_CODE),
    D3D12_CACHE_VALUE_TYPE_FLAGS_METADATA            = (1 << D3D12_CACHE_VALUE_TYPE_METADATA),
    D3D12_CACHE_VALUE_TYPE_FLAGS_DEBUG_PDB           = (1 << D3D12_CACHE_VALUE_TYPE_DEBUG_PDB),
    D3D12_CACHE_VALUE_TYPE_FLAGS_PERFORMANCE_DATA    = (1 << D3D12_CACHE_VALUE_TYPE_PERFORMANCE_DATA),

} D3D12_CACHE_VALUE_TYPE_FLAGS; 
cpp_quote( "DEFINE_ENUM_FLAG_OPERATORS( D3D12_CACHE_VALUE_TYPE_FLAGS )" )
```

**Constants**

*D3D12_CACHE_VALUE_TYPE_FLAGS_NONE*

No selected value types.

*D3D12_CACHE_VALUE_TYPE_FLAGS_OBJECT_CODE*

Specifies that the operation apply to object code.

*D3D12_CACHE_VALUE_TYPE_FLAGS_METADATA*

Opaque metadata that the compiler may have stored about the compile.  For example it may store a compiler version number used for validation.  This data is separated from object code to allow memcmp diffing of object code between compiler versions.  

*D3D12_CACHE_VALUE_TYPE_FLAGS_DEBUG_PDB*

Specifies that the operation apply to the debug PDB.

*D3D12_CACHE_VALUE_TYPE_FLAGS_PERFORMANCE_DATA*

Specifies that the operation apply to performance data.

**Remarks**

Used during compilation to indicate if object code or metadata should be stored or if debug pdb and performance data need to be produced and stored.

### Struct: D3D12_CACHE_VALUE_KEY

```c++
typedef struct D3D12_CACHE_VALUE_KEY
{
    _Field_size_bytes_full_(KeySize) const void* pKey;
    UINT KeySize;
} D3D12_CACHE_VALUE_KEY;
```

**Members**

*pKey*

A unique sequence of bytes that uniquely identifies an object in the database.

*KeySize*

The size in bytes of pKey.

**Remarks**

Used during cache operations like find and store value to identify a value.

### Struct: D3D12_CACHE_VALUE

A non-const value buffer and buffer size structure for cached values.

```c++
typedef struct D3D12_CACHE_VALUE
{
    [size_is(ValueSize)] void* pValue;
    UINT ValueSize;
} D3D12_CACHE_VALUE;
```

**Members**

*pValue*

A pointer to a member buffer containing the value.

*ValueSize*

The size of the pValue buffer in bytes.

**Remarks**

Used for object code, compiler metadata, debug PDB, and performance data.

### Struct: D3D12_CACHE_TYPED_VALUE

Specifies a value and its type, such as object code, metadata etc.

```c++
typedef struct D3D12_CACHE_TYPED_VALUE
{
    D3D12_CACHE_VALUE_TYPE  Type;
    D3D12_CACHE_VALUE       Value;
} D3D12_CACHE_TYPED_VALUE;
```

**Members**

*Type*

The type of the value, such as object code, metadata, etc.  See [D3D12_CACHE_VALUE_TYPE](#enumeration-d3d12_cache_value_type) for more information on types.

*Value*

The buffer and size for the value.  See [D3D12_CACHE_VALUE](#struct-d3d12_cache_value).

**Remarks**

Used in API where the compiler may modify the value buffer, such as [ID3D12ShaderCacheSession1::FindValue1](#method-findvalue1).

### Struct: D3D12_CACHE_CONST_VALUE

Specifies a const value buffer and buffer size.

```c++
typedef struct D3D12_CACHE_CONST_VALUE
{
    _Field_size_bytes_opt_(ValueSize) const void* pValue;
    SIZE_T ValueSize;
} D3D12_CACHE_CONST_VALUE;
```

**Members**

*pValue*

A const pointer to a member buffer containing the value.

*ValueSize*

The size of the pValue buffer in bytes.

**Remarks**

See also [D3D12_CACHE_TYPED_CONST_VALUE](#struct-d3d12_cache_typed_const_value).

### Struct: D3D12_CACHE_TYPED_CONST_VALUE

```c++
typedef struct D3D12_CACHE_TYPED_CONST_VALUE
{
    D3D12_CACHE_VALUE_TYPE  Type;
    D3D12_CACHE_CONST_VALUE Value;
} D3D12_CACHE_TYPED_CONST_VALUE;
```

**Members**

*Type*

The type of the value, such as object code, metadata, etc.  See [D3D12_CACHE_VALUE_TYPE](#enumeration-d3d12_cache_value_type) for more information on types.

*Value*

The const buffer and size for the value.  See [D3D12_CACHE_CONST_VALUE](#struct-d3d12_cache_const_value).

**Remarks**

Used in API where the compiler may not modify the value buffer, such as [ID3D12ShaderCacheSession1::StoreValue1](#method-storevalue1).

### Enum: D3D12_SHADER_CACHE_MODE

Specifies whether a cache session uses an in-memory cache, a disk cache, a registered PSDB, or a PSDB specified by file path.

```idl
typedef enum D3D12_SHADER_CACHE_MODE 
{ 
    D3D12_SHADER_CACHE_MODE_MEMORY = 0, 
    D3D12_SHADER_CACHE_MODE_DISK, 

    // Access a Precompiled Shader Database registered with D3D Shader Cache Registration.
    D3D12_SHADER_CACHE_MODE_REGISTERED,

    // Specify a Precompiled Shader Database by file.
    D3D12_SHADER_CACHE_MODE_FILE
} D3D12_SHADER_CACHE_MODE; 
```

**Constants**

*D3D12_SHADER_CACHE_MODE_REGISTERED*

Use a cache registered with D3D Shader Cache Registration.  See Remarks.

*D3D12_SHADER_CACHE_MODE_FILE*

Specifies a Precompiled Shader Databases created from an explicit file path.  See Remarks.

**Remarks**

Use of D3D12_SHADER_CACHE_MODE_REGISTERED or D3D12_SHADER_CACHE_MODE_FILE requires ID3D12Device16::CreateShaderCacheSession1. FILE and REGISTERED sessions require that ID3D12ApplicationIdentity::SetApplicationIdentity has been called before device creation. REGISTERED sessions are read-only. FILE sessions open or create a database for read-write access by default. D3D12_SHADER_CACHE_SESSION_FILE_FLAG_READ_ONLY opens an existing database for read-only access, and D3D12_SHADER_CACHE_SESSION_FILE_FLAG_OPEN_EXISTING_ONLY prevents creation of a missing database.

### Enum: D3D12_SHADER_CACHE_KIND_FLAGS

```idl
typedef enum D3D12_SHADER_CACHE_KIND_FLAGS {
  D3D12_SHADER_CACHE_KIND_FLAG_IMPLICIT_D3D_CACHE_FOR_DRIVER = 0x1,
  D3D12_SHADER_CACHE_KIND_FLAG_IMPLICIT_D3D_CONVERSIONS = 0x2,
  D3D12_SHADER_CACHE_KIND_FLAG_IMPLICIT_DRIVER_MANAGED = 0x4,
  D3D12_SHADER_CACHE_KIND_FLAG_APPLICATION_MANAGED = 0x8,

  // Control lookups in Precompiled Shader Databases.
  D3D12_SHADER_CACHE_KIND_FLAG_PSDB = 0x10,
} ;
```

Use ID3D12Device9::ShaderCacheControl to control the system managed cache when developer mode is enabled.

**Constants**

*D3D12_SHADER_CACHE_KIND_FLAG_PSDB*

Controls the implicit default PSDB and D3D12_SHADER_CACHE_MODE_REGISTERED sessions, including sessions specified with D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_PSDB or D3D12_STATE_SUBOBJECT_TYPE_PSDB.

**Remarks**

D3D12_SHADER_CACHE_KIND_FLAG_PSDB can be used with ID3D12Device9::ShaderCacheControl to enable (D3D12_SHADER_CACHE_CONTROL_FLAG_ENABLE) or disable (D3D12_SHADER_CACHE_CONTROL_FLAG_DISABLE) cache lookups by the runtime with the implicit default PSDB and D3D12_SHADER_CACHE_MODE_REGISTERED sessions. FILE sessions are controlled by D3D12_SHADER_CACHE_KIND_FLAG_APPLICATION_MANAGED, even when used as explicit PSDBs. Enabling or disabling cache kinds requires developer mode. D3D12_SHADER_CACHE_CONTROL_FLAG_CLEAR has no effect with D3D12_SHADER_CACHE_KIND_FLAG_PSDB.

### Struct: D3D12_SHADER_CACHE_SESSION_MEMORY_DESC

```idl
typedef struct D3D12_SHADER_CACHE_SESSION_MEMORY_DESC
{
    GUID Identifier;
    D3D12_SHADER_CACHE_FLAGS Flags;
    UINT MaximumInMemoryCacheSizeBytes;
    UINT MaximumInMemoryCacheEntries;
    UINT64 Version;
} D3D12_SHADER_CACHE_SESSION_MEMORY_DESC;
```

**Members**

*Identifier*

A unique identifier to give to this specific cache. Caches with different identifiers are stored side by side. Caches with the same identifier are shared across all sessions in the same process. Creating a disk cache with the same identifier as an already-existing cache opens that cache, unless the Version doesn't matches. In that case, if there are no other sessions open to that cache, it is cleared and re-created. If there are existing sessions, then ID3D12Device9::CreateShaderCacheSession returns DXGI_ERROR_ALREADY_EXISTS.

*Flags*

Modifies the behavior of the cache.  See D3D12_SHADER_CACHE_FLAGS.

*MaximumInMemoryCacheSizeBytes*

This value determines the size of the memory cache in bytes.

*MaximumInMemoryCacheEntries*

Specifies how many entries can be stored in memory.

*Version*

Can be used to implicitly clear caches when an application or component update is done. If the version doesn't match the version stored in the cache, then it will be wiped and re-created.

### Struct: D3D12_SHADER_CACHE_SESSION_DISK_DESC

```idl
typedef struct D3D12_SHADER_CACHE_SESSION_DISK_DESC
{
    GUID Identifier;
    D3D12_SHADER_CACHE_FLAGS Flags;
    LPCWSTR pDirectory;
    UINT MaximumInMemoryCacheSizeBytes;
    UINT MaximumInMemoryCacheEntries;
    UINT64 MaximumValueFileSizeBytes;
    UINT64 Version;
} D3D12_SHADER_CACHE_SESSION_DISK_DESC;
```

**Members**

*Identifier*

A unique identifier to give to this specific cache. Caches with different identifiers are stored side by side. Caches with the same identifier are shared across all sessions in the same process. Creating a disk cache with the same identifier as an already-existing cache opens that cache, unless the Version doesn't matches. In that case, if there are no other sessions open to that cache, it is cleared and re-created. If there are existing sessions, then ID3D12Device9::CreateShaderCacheSession returns DXGI_ERROR_ALREADY_EXISTS.

*Flags*

Modifies the behavior of the cache.  See D3D12_SHADER_CACHE_FLAGS.

*pDirectory*

Optionally specifies the directory in which to store the cache. A null pointer selects the default location. A non-null pointer requires D3D12_SHADER_CACHE_SUPPORT_SESSION_DESC1 in D3D12_FEATURE_DATA_SHADER_CACHE::SupportFlags and cannot be combined with D3D12_SHADER_CACHE_FLAG_USE_WORKING_DIR.

*MaximumInMemoryCacheSizeBytes*

This value determines the size of the memory cache in bytes.

*MaximumInMemoryCacheEntries*

Specifies how many entries can be stored in memory.

*MaximumValueFileSizeBytes*

 Sets the maximum file size in bytes.

*Version*

Can be used to implicitly clear caches when an application or component update is done. If the version doesn't match the version stored in the cache, then it will be wiped and re-created.

### Enum: D3D12_SHADER_CACHE_SESSION_REGISTERED_FLAGS

```idl
typedef enum D3D12_SHADER_CACHE_SESSION_REGISTERED_FLAGS
{
    D3D12_SHADER_CACHE_SESSION_REGISTERED_FLAG_NONE = 0x0,
} D3D12_SHADER_CACHE_SESSION_REGISTERED_FLAGS;
DEFINE_ENUM_FLAG_OPERATORS( D3D12_SHADER_CACHE_SESSION_REGISTERED_FLAGS )
```

**Constants**

*D3D12_SHADER_CACHE_SESSION_REGISTERED_FLAG_NONE*

No flags.  Reserved for future use.

### Struct: D3D12_SHADER_CACHE_SESSION_REGISTERED_DESC

```idl
typedef struct D3D12_SHADER_CACHE_SESSION_REGISTERED_DESC
{
    LPCWSTR pComponentName;
    D3D12_SHADER_CACHE_SESSION_REGISTERED_FLAGS Flags;
} D3D12_SHADER_CACHE_SESSION_REGISTERED_DESC;
```

**Members**

*pComponentName*

The name of the registered component to look up.  Must not be nullptr or "default" (reserved for the system PSDB).

*Flags*

Reserved for future use.  Must be D3D12_SHADER_CACHE_SESSION_REGISTERED_FLAG_NONE.

### Struct: D3D12_CACHE_FILE_DESC

Specifies a database path, maximum size, and the value types it stores.

```idl
typedef struct D3D12_CACHE_FILE_DESC
{
    D3D12_CACHE_VALUE_TYPE_FLAGS Types;
    UINT64 MaximumSizeBytes;
    LPCWSTR pPath;
} D3D12_CACHE_FILE_DESC;
```

**Members**

*Types*

The types stored in pPath.  See [D3D12_CACHE_VALUE_TYPE_FLAGS](#enumeration-d3d12_cache_value_type_flags).

*MaximumSizeBytes*

The maximum database size requested, in bytes. Zero does not impose a new size limit. If the database has a persisted size limit, opening it preserves that limit unless a larger value is requested; zero or a smaller value does not reduce it.

A non-zero value is required when D3D12_SHADER_CACHE_SESSION_FILE_FLAG_RESERVE_MAXIMUM_SIZE is specified.

*pPath*

A file path specifying the location of a database file.

**Remarks**

Databases store one or more value types.  The types member specifies which value types are stored in pPath.

### Enum: D3D12_SHADER_CACHE_SESSION_FILE_FLAGS

```idl
typedef enum D3D12_SHADER_CACHE_SESSION_FILE_FLAGS
{
    D3D12_SHADER_CACHE_SESSION_FILE_FLAG_NONE = 0x0,
    D3D12_SHADER_CACHE_SESSION_FILE_FLAG_READ_ONLY = 0x1,
    D3D12_SHADER_CACHE_SESSION_FILE_FLAG_TRIM_WHEN_FULL = 0x2,
    D3D12_SHADER_CACHE_SESSION_FILE_FLAG_RESERVE_MAXIMUM_SIZE = 0x4,
    D3D12_SHADER_CACHE_SESSION_FILE_FLAG_OPEN_EXISTING_ONLY = 0x8,
    D3D12_SHADER_CACHE_SESSION_FILE_FLAG_ALLOW_CACHE_RESET = 0x10,
} D3D12_SHADER_CACHE_SESSION_FILE_FLAGS;
DEFINE_ENUM_FLAG_OPERATORS( D3D12_SHADER_CACHE_SESSION_FILE_FLAGS )
```

**Constants**

*D3D12_SHADER_CACHE_SESSION_FILE_FLAG_NONE*

Open or create the database for read-write access.

*D3D12_SHADER_CACHE_SESSION_FILE_FLAG_READ_ONLY*

Open an existing database for read-only access. Store operations do not modify the database. A missing database returns DXGI_ERROR_NOT_FOUND.

*D3D12_SHADER_CACHE_SESSION_FILE_FLAG_TRIM_WHEN_FULL*

Automatically evict entries to make room when the database reaches its effective maximum size. This flag does not require a non-zero D3D12_CACHE_FILE_DESC::MaximumSizeBytes. See [D3D12_CACHE_FILE_DESC](#struct-d3d12_cache_file_desc) for size-limit behavior. Requires D3D12_SHADER_CACHE_SUPPORT_TRIM_WHEN_FULL in D3D12_FEATURE_DATA_SHADER_CACHE::SupportFlags.

*D3D12_SHADER_CACHE_SESSION_FILE_FLAG_RESERVE_MAXIMUM_SIZE*

Reserve storage for the maximum size specified by D3D12_CACHE_FILE_DESC::MaximumSizeBytes. Requires a non-zero maximum size and D3D12_SHADER_CACHE_SUPPORT_RESERVE_MAXIMUM_SIZE in D3D12_FEATURE_DATA_SHADER_CACHE::SupportFlags.

*D3D12_SHADER_CACHE_SESSION_FILE_FLAG_OPEN_EXISTING_ONLY*

Open an existing database without creating a missing file. A missing database returns DXGI_ERROR_NOT_FOUND. This flag does not make the session read-only.

*D3D12_SHADER_CACHE_SESSION_FILE_FLAG_ALLOW_CACHE_RESET*

Allow an incompatible existing database to be cleared and recreated. Without this flag, an incompatible database causes session creation to fail with DXGI_ERROR_CACHE_CORRUPT.

**Remarks**

Unknown flag values are invalid. READ_ONLY cannot be combined with TRIM_WHEN_FULL, RESERVE_MAXIMUM_SIZE, or ALLOW_CACHE_RESET.

### Struct: D3D12_SHADER_CACHE_SESSION_FILE_DESC

```idl
typedef struct D3D12_SHADER_CACHE_SESSION_FILE_DESC
{
    [annotation("_Field_size_full_(NumDescs)")] const D3D12_CACHE_FILE_DESC* pDescs;
    UINT NumDescs;
    D3D12_SHADER_CACHE_SESSION_FILE_FLAGS Flags;
} D3D12_SHADER_CACHE_SESSION_FILE_DESC;
```

**Members**

*pDescs*

An array of database file descriptors. Exactly one descriptor must be specified, with Types set to D3D12_CACHE_VALUE_TYPE_FLAGS_OBJECT_CODE | D3D12_CACHE_VALUE_TYPE_FLAGS_METADATA.

*NumDescs*

The number of entries in pDescs. Must be 1.

*Flags*

Controls database access, creation, and storage behavior. See [D3D12_SHADER_CACHE_SESSION_FILE_FLAGS](#enum-d3d12_shader_cache_session_file_flags).

### Struct: D3D12_SHADER_CACHE_SESSION_DESC1

```idl
typedef struct D3D12_SHADER_CACHE_SESSION_DESC1
{
    D3D12_SHADER_CACHE_MODE Mode;

    union
    {
        D3D12_SHADER_CACHE_SESSION_MEMORY_DESC Memory;
        D3D12_SHADER_CACHE_SESSION_DISK_DESC Disk;
        D3D12_SHADER_CACHE_SESSION_REGISTERED_DESC Registered;
        D3D12_SHADER_CACHE_SESSION_FILE_DESC File;
    };
} D3D12_SHADER_CACHE_SESSION_DESC1;
```

**Members**

*Mode*

Specifies the type of cache.  See [D3D12_SHADER_CACHE_MODE](#enum-d3d12_shader_cache_mode).

*Memory*

Creation parameters for D3D12_SHADER_CACHE_MODE_MEMORY.  See [D3D12_SHADER_CACHE_SESSION_MEMORY_DESC](#struct-d3d12_shader_cache_session_memory_desc).

*Disk*

Creation parameters for D3D12_SHADER_CACHE_MODE_DISK.  See [D3D12_SHADER_CACHE_SESSION_DISK_DESC](#struct-d3d12_shader_cache_session_disk_desc).

*Registered*

Creation parameters for D3D12_SHADER_CACHE_MODE_REGISTERED.  See [D3D12_SHADER_CACHE_SESSION_REGISTERED_DESC](#struct-d3d12_shader_cache_session_registered_desc).

*File*

Creation parameters for D3D12_SHADER_CACHE_MODE_FILE.  See [D3D12_SHADER_CACHE_SESSION_FILE_DESC](#struct-d3d12_shader_cache_session_file_desc).

**Remarks**

### Interface: ID3D12Device16

Extends ID3D12Device15 with explicit PSDB cache-session creation.

```idl
[uuid(b34a50dd-e102-428f-82a0-82294a27bbe6), object, local, pointer_default(unique)]
interface ID3D12Device16
    : ID3D12Device15
{
    // Other ID3D12Device16 methods are omitted.

    HRESULT CreateShaderCacheSession1(
        [annotation("_In_")] const D3D12_SHADER_CACHE_SESSION_DESC1* pDesc,
        REFIID riid,
        [out, iid_is(riid), annotation("_COM_Outptr_opt_")] void** ppvSession
        );
};
```

#### Method: CreateShaderCacheSession1

Creates a shader cache session using the mode and parameters specified by pDesc.

**Parameters**

*pDesc*

Specifies creation parameters dependent on [D3D12_SHADER_CACHE_MODE](#enum-d3d12_shader_cache_mode).  See [D3D12_SHADER_CACHE_SESSION_DESC1](#struct-d3d12_shader_cache_session_desc1) for details.

*riid*

The globally unique identifier (GUID) for the cache session interface interface (e.g. IID_ID3D12ShaderCacheSession1)

*ppvSession*

On return, a pointer the cache session interface specified by riid.

**Remarks**

FILE and REGISTERED modes require that ID3D12ApplicationIdentity::SetApplicationIdentity has been called before creating the device. SetApplicationIdentity provides the application description used both for validating a FILE PSDB's embedded identity and for making the application description available to drivers during device creation. If a FILE PSDB's embedded identity does not match the current application, the call returns DXGI_ERROR_CACHE_CORRUPT with a debug layer message indicating the mismatch.

Applications should check D3D12_FEATURE_EXPLICIT_PSDBS before using FILE or REGISTERED modes.  If ExplicitPsdbsSupported is FALSE, these modes return E_INVALIDARG.

### Enum: D3D12_SHADER_CACHE_STORE_FLAGS

```idl
typedef enum D3D12_SHADER_CACHE_STORE_FLAGS
{
    D3D12_SHADER_CACHE_STORE_FLAG_NONE = 0x0,
    D3D12_SHADER_CACHE_STORE_FLAG_OVERWRITE = 0x1,
    D3D12_SHADER_CACHE_STORE_FLAG_DO_NOT_EVICT = 0x2,
} D3D12_SHADER_CACHE_STORE_FLAGS;
DEFINE_ENUM_FLAG_OPERATORS( D3D12_SHADER_CACHE_STORE_FLAGS )
```

**Constants**

*D3D12_SHADER_CACHE_STORE_FLAG_NONE*

Store new values without replacing existing values for the same key and type.

*D3D12_SHADER_CACHE_STORE_FLAG_OVERWRITE*

Replace existing values for the supplied key and value types. Values of types not supplied by the call are unchanged.

*D3D12_SHADER_CACHE_STORE_FLAG_DO_NOT_EVICT*

Exclude the entry from automatic eviction.

**Remarks**

Check D3D12_FEATURE_DATA_SHADER_CACHE::SupportFlags for D3D12_SHADER_CACHE_SUPPORT_STORE_OVERWRITE and D3D12_SHADER_CACHE_SUPPORT_STORE_DO_NOT_EVICT before relying on the corresponding flag's behavior. If D3D12_SHADER_CACHE_SUPPORT_STORE_OVERWRITE is not reported, OVERWRITE is ignored and the call performs an ordinary store; a value already present for the supplied key and type can cause DXGI_ERROR_ALREADY_EXISTS. DO_NOT_EVICT is ignored when the shader cache implementation does not support it.

### Interface: ID3D12ShaderCacheSession1

```idl
interface ID3D12ShaderCacheSession1
    : ID3D12ShaderCacheSession
{
    HRESULT FindValue1(
        [annotation("_In_")] const D3D12_CACHE_VALUE_KEY* pValueKey,
        [annotation("_Inout_count_(NumTypedValues)")] D3D12_CACHE_TYPED_VALUE* pTypedValues,
        UINT NumTypedValues,
        [annotation("_In_opt_")] D3D12CacheSessionAllocationFunc pCallbackFunc,
        [annotation("_Inout_opt_")] void* pContext
    );

    HRESULT StoreValue1(
        _In_ const D3D12_CACHE_VALUE_KEY* pValueKey,
        _In_reads_(NumTypedValues) const D3D12_CACHE_TYPED_CONST_VALUE* pTypedValues,
        UINT NumTypedValues,
        D3D12_SHADER_CACHE_STORE_FLAGS Flags
        );

    // Other ID3D12ShaderCacheSession1 methods are omitted.
};
```

#### Method: FindValue1

Find a previously stored value in the cache.

**Parameters**

*pValueKey*

A unique sequence of bytes that uniquely identifies an object in the database.

*pTypedValues*

An array of typed values to retrieve the size or values of during the operation.  The array size is specified by NumTypedValues.  See [D3D12_CACHE_TYPED_VALUE](#struct-d3d12_cache_typed_value).

*NumTypedValues*

The number of typed values in the pTypedValues array.

*pCallbackFunc*

An optional callback function for allocating value buffers.  See Remarks.

*pContext*

An application specified context pointer that is passed to the callback.  Use this to pass parameters to the allocation callback function.

**Remarks**

ID3D12ShaderCacheSession::FindValue returns the same value as D3D12_CACHE_VALUE_TYPE_OBJECT_CODE with ID3D12ShaderCacheSession1::FindValue1.

Each D3D12_CACHE_TYPED_VALUE has a D3D12_CACHE_VALUE.  On input, each D3D12_CACHE_VALUE ValueSize member specifies the size in bytes of the buffer pointed to by pValue. Use zero when querying size or using the allocation callback. On output, the ValueSize member is assigned the size of the value.

When a value is found, each D3D12_CACHE_VALUE is handled as follows:

- If the ValueSize member is a non-zero value, the pValue member must point to a buffer of that size.  If ValueSize is greater than or equal to the value's actual size, the value is copied to pValue and the ValueSize member is assigned the actual size of the value.  If the caller specified ValueSize is insufficient, DXGI_ERROR_MORE_DATA is returned and the required size is assigned to the ValueSize member.
- If the ValueSize member is zero and pCallbackFunc is non-nullptr and the pValue member is nullptr, pCallbackFunc is called to allocate a buffer and the value is copied into it.  The allocated buffer pointer returned by pCallbackFunc is assigned to the pValue member on return. If pCallbackFunc returns nullptr, the call fails and returns E_OUTOFMEMORY.
- The ValueSize member is assigned the value's actual size before returning.

To determine if a particular value type is stored without retrieving the value, use a size check for the value. To perform a size check, use a nullptr pValue with a zero ValueSize for the types to query and a nullptr pCallbackFunc.  A return value of S_OK indicates the value is cached.  A return value of DXGI_ERROR_NOT_FOUND indicates a value with that key is not cached.  ValueSize is non-zero for a cached value type.

To check if a key exists without retrieving any values, pass NumTypedValues as 0 with pTypedValues as nullptr.  Returns S_OK if the key exists, DXGI_ERROR_NOT_FOUND if not.

MEMORY, DISK, FILE, and REGISTERED sessions accept D3D12_CACHE_VALUE_TYPE_OBJECT_CODE and D3D12_CACHE_VALUE_TYPE_METADATA. Requesting D3D12_CACHE_VALUE_TYPE_DEBUG_PDB, D3D12_CACHE_VALUE_TYPE_PERFORMANCE_DATA, an unknown type, or a duplicate type in the same call returns E_INVALIDARG.

Unlike ID3D12ShaderCacheSession::FindValue, FindValue1 does not produce a debug layer message when the key is not found.

#### Method: StoreValue1

Add a key/value pair to the cache session.

**Parameters**

*pValueKey*

A unique sequence of bytes that uniquely identifies an object in the database.

*pTypedValues*

An array of typed values to store.  The array size is specified by NumTypedValues.  See [D3D12_CACHE_TYPED_CONST_VALUE](#struct-d3d12_cache_typed_const_value).

*NumTypedValues*

The number of values in the pTypedValues array.

*Flags*

Controls replacement and automatic eviction of stored values. See [D3D12_SHADER_CACHE_STORE_FLAGS](#enum-d3d12_shader_cache_store_flags).

**Remarks**

At least one value must be stored in the store operation, so the function returns E_INVALIDARG if pTypedValues nullptr or NumTypedValues is zero. Each value must have a non-zero size.  Only one value per type may be stored at a time.

The supported value types are the same as for FindValue1. Unknown flag values are invalid.

Unless D3D12_SHADER_CACHE_STORE_FLAG_OVERWRITE is specified and supported, this API returns DXGI_ERROR_ALREADY_EXISTS if a value with the supplied key and one of the supplied types already exists. When OVERWRITE is specified and supported, existing values for those types are replaced.

## D3DX12 Inline Helpers

### d3dx12_pipeline_state_stream helper
```c++
typedef CD3DX12_PIPELINE_STATE_STREAM_SUBOBJECT<
    D3D12_SHADER_CACHE_SESSION_SUBOBJECT_DESC,
    D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_PSDB> CD3DX12_PIPELINE_STATE_STREAM_PSDB;
```

### d3dx12_state_object helper
```c++
class CD3DX12_STATE_OBJECT_DESC
{
...

friend class CD3DX12_PSDB_SUBOBJECT;

void RemoveSubobjectsByType(D3D12_STATE_SUBOBJECT_TYPE type);
}
```

CD3DX12_PSDB_SUBOBJECT accepts either a D3D12_SHADER_CACHE_SESSION_SUBOBJECT_DESC or a session pointer with optional D3D12_SHADER_CACHE_SESSION_SUBOBJECT_FLAGS. RemoveSubobjectsByType removes matching subobjects and references to them.

## Samples

### Check for Support

```c++
bool Supported(ID3D12Device* pDevice)
{
    D3D12_FEATURE_DATA_EXPLICIT_PSDBS featureData = {};
    HRESULT hr = pDevice->CheckFeatureSupport(D3D12_FEATURE_EXPLICIT_PSDBS, &featureData, sizeof(featureData));

    return SUCCEEDED(hr) && featureData.ExplicitPsdbsSupported == TRUE;
}
```

### Using a FILE PSDB for Creating a PSO

```c++
// Compile the PSDB with matching application identity:
// D3D12CompilerHost.exe compile --plugin <DriverCompilerPlugin.dll> --adapter-family <AdapterFamily>
//     --name TestGame --exe-filename testgame.exe --engine-name TestEngine
//     MyShaders.sodb MyShaders.psdb

// Set application identity before device creation.
// This must match the identity used when compiling the PSDB.
CComPtr<ID3D12ApplicationIdentity> spAppIdentity;
ThrowFailure(D3D12GetInterface(CLSID_D3D12ApplicationIdentity, IID_PPV_ARGS(&spAppIdentity)));

D3D12_APPLICATION_DESC appDesc = {};
appDesc.pExeFilename = L"testgame.exe";
appDesc.pName = L"TestGame";
appDesc.Version.Version = 1;
appDesc.pEngineName = L"TestEngine";
appDesc.EngineVersion.Version = 1;

// {a1b2c3d4-e5f6-7890-abcd-ef1234567890}
static constexpr GUID AppId = { 0xa1b2c3d4, 0xe5f6, 0x7890, {0xab, 0xcd, 0xef, 0x12, 0x34, 0x56, 0x78, 0x90} };
ThrowFailure(spAppIdentity->SetApplicationIdentity(&appDesc, AppId));

// Create device after setting application identity
CComPtr<ID3D12Device> pDevice;
ThrowFailure(D3D12CreateDevice(pAdapter, D3D_FEATURE_LEVEL_12_0, IID_PPV_ARGS(&pDevice)));

CComPtr<ID3D12Device16> spDevicePsdbs;
ThrowFailure(pDevice->QueryInterface(IID_PPV_ARGS(&spDevicePsdbs)));

// Create a FILE mode cache session from a PSDB file path.
CD3DX12_SHADER_CACHE_SESSION_DESC1 desc(L"C:\\Games\\TestGame\\MyShaders.psdb");
desc.File.Flags = D3D12_SHADER_CACHE_SESSION_FILE_FLAG_READ_ONLY;

CComPtr<ID3D12ShaderCacheSession1> spCacheSession1;
HRESULT hr = spDevicePsdbs->CreateShaderCacheSession1(&desc, IID_PPV_ARGS(&spCacheSession1));
if (hr == DXGI_ERROR_CACHE_CORRUPT)
{
    // PSDB identity does not match the current device or application. Check debug layer output for details.
    hr = S_OK;
}
else
{
    ThrowFailure(hr);
}

// Values to be provided by caller
// D3D12_INPUT_LAYOUT_DESC IL;
// D3D12_SHADER_BYTECODE VS;
// D3D12_SHADER_BYTECODE PS;

struct PSO_STREAM
{
    CD3DX12_PIPELINE_STATE_STREAM_PRIMITIVE_TOPOLOGY PrimitiveTopologyType;
    CD3DX12_PIPELINE_STATE_STREAM_INPUT_LAYOUT InputLayout;
    CD3DX12_PIPELINE_STATE_STREAM_VS VS;
    CD3DX12_PIPELINE_STATE_STREAM_PS PS;
    CD3DX12_PIPELINE_STATE_STREAM_PSDB PSDB;

} PSOStream = 
{
    D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE,
    IL,
    VS,
    PS,
    D3D12_SHADER_CACHE_SESSION_SUBOBJECT_DESC{
        spCacheSession1,
        D3D12_SHADER_CACHE_SESSION_SUBOBJECT_FLAG_NONE
    }
};

CComPtr<ID3D12PipelineState> spPSO;
D3D12_PIPELINE_STATE_STREAM_DESC Stream{sizeof(PSOStream), &PSOStream};
ThrowFailure(spDevicePsdbs->CreatePipelineState(&Stream, IID_PPV_ARGS(&spPSO)));

```

### Using a Registered PSDB to Explicit Cache Session for Creating a PSO

```c++

CComPtr<ID3D12Device16> spDevicePsdbs;
ThrowFailure(pDevice->QueryInterface(IID_PPV_ARGS(&spDevicePsdbs)));

// Specify which cache to use by its registered component name.  The name is application determined.  Typically this means that:
// 1. Each SODB is submitted with a component name to the game store.
// 2. The game store compiles each SODB into a PSDB.
// 3. The game store delivers the SODB/PSDB to the client and registers it with the component name you specified.
// 4. The game creates a shader cache session specifying that name.  The runtime looks up which PSDB to use based on the current device and the psdb.
D3D12_SHADER_CACHE_SESSION_DESC1 desc = {D3D12_SHADER_CACHE_MODE_REGISTERED};
desc.Registered.pComponentName = L"DLC1"; 

CComPtr<ID3D12ShaderCacheSession1> spCacheSession1;
HRESULT hr = spDevicePsdbs->CreateShaderCacheSession1(&desc, IID_PPV_ARGS(&spCacheSession1));
if (hr == DXGI_ERROR_NOT_FOUND)
{
    // A PSDB is not registered for the target adapter, driver version, or component name. Log etc. if this is unexpected.
    // Continuing is OK because nullptr is treated as if no explicit PSDB was specified.
    hr = S_OK;
}
else
{
    ThrowFailure(hr);
}

// Values to be provided by caller
// D3D12_INPUT_LAYOUT_DESC IL;
// D3D12_SHADER_BYTECODE VS;
// D3D12_SHADER_BYTECODE PS;

struct PSO_STREAM
{
    CD3DX12_PIPELINE_STATE_STREAM_PRIMITIVE_TOPOLOGY PrimitiveTopologyType;
    CD3DX12_PIPELINE_STATE_STREAM_INPUT_LAYOUT InputLayout;
    CD3DX12_PIPELINE_STATE_STREAM_VS VS;
    CD3DX12_PIPELINE_STATE_STREAM_PS PS;
    CD3DX12_PIPELINE_STATE_STREAM_PSDB PSDB;

} PSOStream = 
{
    D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE,
    IL,
    VS,
    PS,
    D3D12_SHADER_CACHE_SESSION_SUBOBJECT_DESC{
        spCacheSession1,
        D3D12_SHADER_CACHE_SESSION_SUBOBJECT_FLAG_NONE
    }
};

CComPtr<ID3D12PipelineState> spPSO;
D3D12_PIPELINE_STATE_STREAM_DESC Stream{sizeof(PSOStream), &PSOStream};
ThrowFailure(spDevicePsdbs->CreatePipelineState(&Stream, IID_PPV_ARGS(&spPSO)));

```

### Using a FILE PSDB for Creating a SO

```c++
// Assumes SetApplicationIdentity and device creation from the PSO sample above.

CComPtr<ID3D12Device16> spDevicePsdbs;
ThrowFailure(pDevice->QueryInterface(IID_PPV_ARGS(&spDevicePsdbs)));

// Create a FILE mode cache session from a PSDB file path.
CD3DX12_SHADER_CACHE_SESSION_DESC1 desc(L"C:\\Games\\TestGame\\MyShaders.psdb");
desc.File.Flags = D3D12_SHADER_CACHE_SESSION_FILE_FLAG_READ_ONLY;

CComPtr<ID3D12ShaderCacheSession1> spCacheSession1;
HRESULT hr = spDevicePsdbs->CreateShaderCacheSession1(&desc, IID_PPV_ARGS(&spCacheSession1));
if (hr == DXGI_ERROR_CACHE_CORRUPT)
{
    hr = S_OK;
}
else
{
    ThrowFailure(hr);
}

// Values to be provided by caller
// D3D12_SHADER_BYTECODE vsShaderByteCode;
// D3D12_SHADER_BYTECODE psShaderByteCode;

CD3DX12_STATE_OBJECT_DESC soDesc(D3D12_STATE_OBJECT_TYPE_EXECUTABLE);

auto pPrimitiveTopology = soDesc.CreateSubobject<CD3DX12_PRIMITIVE_TOPOLOGY_SUBOBJECT>();
pPrimitiveTopology->SetPrimitiveTopologyType(D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE);

auto pVsLib = soDesc.CreateSubobject<CD3DX12_DXIL_LIBRARY_SUBOBJECT>();
pVsLib->SetDXILLibrary(&vsShaderByteCode);
pVsLib->DefineExport(L"VSMain", L"*");

auto pPsLib = soDesc.CreateSubobject<CD3DX12_DXIL_LIBRARY_SUBOBJECT>();
pPsLib->SetDXILLibrary(&psShaderByteCode);
pPsLib->DefineExport(L"PSMain", L"*");

auto pCacheSubobject = soDesc.CreateSubobject<CD3DX12_PSDB_SUBOBJECT>(spCacheSession1);

auto pProgram = soDesc.CreateSubobject<CD3DX12_GENERIC_PROGRAM_SUBOBJECT>();
pProgram->SetProgramName(L"TestProgram");
pProgram->AddExport(L"VSMain");
pProgram->AddExport(L"PSMain");
pProgram->AddSubobject(*pPrimitiveTopology);

CComPtr<ID3D12StateObject> stateObject;
ThrowFailure(spDevicePsdbs->CreateStateObject(soDesc, IID_PPV_ARGS(&stateObject)));

```

### Using a Registered PSDB to Explicit Cache Session for Creating SO

```c++
CComPtr<ID3D12Device16> spDevicePsdbs;
ThrowFailure(pDevice->QueryInterface(IID_PPV_ARGS(&spDevicePsdbs)));

// Specify which cache to use by its registered component name.  The name is application determined.  Typically this means that:
// 1. Each SODB is submitted with a component name to the game store.
// 2. The game store compiles each SODB into a PSDB.
// 3. The game store delivers the SODB/PSDB to the client and registers it with the component name you specified.
// 4. The game creates a shader cache session specifying that name.  The runtime looks up which PSDB to use based on the current device and the psdb.
D3D12_SHADER_CACHE_SESSION_DESC1 desc = {D3D12_SHADER_CACHE_MODE_REGISTERED};
desc.Registered.pComponentName = L"DLC1"; 

CComPtr<ID3D12ShaderCacheSession1> spCacheSession1;
HRESULT hr = spDevicePsdbs->CreateShaderCacheSession1(&desc, IID_PPV_ARGS(&spCacheSession1));
if (hr == DXGI_ERROR_NOT_FOUND)
{
    // A PSDB is not registered for the target adapter, driver version, or component name. Log etc. if this is unexpected.
    // Continuing is OK because nullptr is treated as if no explicit PSDB was specified.
    hr = S_OK;
}
else
{
    ThrowFailure(hr);
}

// Values to be provided by caller
// D3D12_SHADER_BYTECODE vsShaderByteCode;
// D3D12_SHADER_BYTECODE psShaderByteCode;

CD3DX12_STATE_OBJECT_DESC soDesc(D3D12_STATE_OBJECT_TYPE_EXECUTABLE);

auto pPrimitiveTopology = soDesc.CreateSubobject<CD3DX12_PRIMITIVE_TOPOLOGY_SUBOBJECT>();
pPrimitiveTopology->SetPrimitiveTopologyType(D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE);

auto pVsLib = soDesc.CreateSubobject<CD3DX12_DXIL_LIBRARY_SUBOBJECT>();
pVsLib->SetDXILLibrary(&vsShaderByteCode);
pVsLib->DefineExport(L"VSMain", L"*");

auto pPsLib = soDesc.CreateSubobject<CD3DX12_DXIL_LIBRARY_SUBOBJECT>();
pPsLib->SetDXILLibrary(&psShaderByteCode);
pPsLib->DefineExport(L"PSMain", L"*");

auto pCacheSubobject = soDesc.CreateSubobject<CD3DX12_PSDB_SUBOBJECT>(spCacheSession1);

auto pProgram = soDesc.CreateSubobject<CD3DX12_GENERIC_PROGRAM_SUBOBJECT>();
pProgram->SetProgramName(L"TestProgram");
pProgram->AddExport(L"VSMain");
pProgram->AddExport(L"PSMain");
pProgram->AddSubobject(*pPrimitiveTopology);

CComPtr<ID3D12StateObject> stateObject;
ThrowFailure(spDevicePsdbs->CreateStateObject(soDesc, IID_PPV_ARGS(&stateObject)));

```

### Using ID3D12ShaderCacheSession1::FindValue1 with D3D12CacheSessionAllocationFunc

```c++

const char testKey[] = "TestKey";

const D3D12_CACHE_VALUE_KEY valueKey = { testKey, sizeof(testKey) };
D3D12_CACHE_TYPED_VALUE values[] = { {D3D12_CACHE_VALUE_TYPE_OBJECT_CODE, {} }, {D3D12_CACHE_VALUE_TYPE_METADATA, {} } };

HRESULT hr = pCacheSession->FindValue1(
    &valueKey, 
    values,
    ARRAYSIZE(values),
    [](size_t SizeInBytes, _Inout_Opt_ void* /*pContext*/){return malloc(SizeInBytes);},
    nullptr // No calling context needed
    );

if (SUCCEEDED(hr))
{
    // ObjectCode and Metadata contain pointer and size to the corresponding value.
}

// Use delete that corresponds with allocation even when FindValue does not succeed.  For example, the first 
// allocation may have succeeded, but a subsequent call to the allocation function may have failed resulting 
// in FindValue returning E_OUTOFMEMORY.
free(values[0].Value.pValue);
free(values[1].Value.pValue);
```
