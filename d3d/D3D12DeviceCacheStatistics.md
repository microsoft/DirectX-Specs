# D3D12 Device Cache Statistics

- [D3D12 Device Cache Statistics](#d3d12-device-cache-statistics)
  - [Introduction](#introduction)
  - [API](#api)
    - [Struct: D3D12\_CREATE\_STATE\_OBJECT\_STATISTICS](#struct-d3d12_create_state_object_statistics)
    - [Struct: D3D12\_STATE\_OBJECT\_STATISTICS](#struct-d3d12_state_object_statistics)
    - [Interface: ID3D12DeviceStatistics](#interface-id3d12devicestatistics)
      - [Method: ID3D12DeviceStatistics::GetStateObjectStatistics](#method-id3d12devicestatisticsgetstateobjectstatistics)

## Introduction

This spec details a ID3D12DeviceStatistics interface for retrieving creation statistics for Pipeline State Objects and State Objects.  

## API

### Struct: D3D12_CREATE_STATE_OBJECT_STATISTICS

```c++
typedef struct D3D12_CREATE_STATE_OBJECT_STATISTICS
{
    UINT NumCreated;
    UINT NumPSDBCacheMissed;
    UINT NumTotalCacheMissed;
    UINT NumCacheUnknown;
} D3D12_CREATE_STATE_OBJECT_STATISTICS;

```

**Members**

*NumCreated*

The total number of objects successfully created.

*NumPSDBCacheMissed*

The subset of objects that were successfully created, but the object was not found in a Precompile Shader Database (PSDB).  A PSDB miss may still be locally cached by driver from a previous creation. Note that a miss is still counted even if there was a partial lookup success, e.g. one shader in a PSO was found in the PSDB because it was compiled identically as part of another PSO.

*NumTotalCacheMissed*

The subset of objects that were successfully created, but the object was not found in any type of cache, either precompiled or cached by driver from a previous creation. Note that a miss is still counted even if there was a partial lookup success.

*NumPSDBCacheUnknown*

The subset of Pipeline State Objects successfully created where PSDB cache hit status is unknown, see remarks.

**Remarks**

The number of PSDB cache hits in the PSDB can be determined by:

NumPSDBCacheHits = NumCreated - NumPSDBCacheMissed - NumPSDBCacheUnknown;

The number of cache hits from any cache, including PSDB and local caches:

NumConfirmedHitsInAnyCache = NumCreated - NumTotalCacheMissed - NumCacheUnknown;

CacheUnknown indicates that the driver did not try to lookup the created object in the D3D12 runtimes caches.  This is expected on driver versions that do not support Advanced Shader Delivery related DDI.  Those drivers have internal cache mechanisms.  CacheUnknown does not indicate that the object being created was cached or not.  Use ID3D12Device::CheckFeatureSupport for the D3D12_FEATURE_SHADER_CACHE_ABI_SUPPORT to understand driver support.  CheckFeatureSupport returns E_FAIL when the feature is not supported by the driver.

Future revisions will enable the driver to inform the runtime of in-memory object re-use, as well as use of driver internal caches that the runtime doesn't otherwise observe.

When no default PSDB is registered, All creations are counted as NumPSDBCacheMissed or NumPSDBCacheUnknown depending on driver support.

### Struct: D3D12_STATE_OBJECT_STATISTICS

```c++
typedef struct D3D12_STATE_OBJECT_STATISTICS
{
    BOOL DefaultPSDBRegistered;
    D3D12_CREATE_STATE_OBJECT_STATISTICS PipelineStateObjectStatistics;
    D3D12_CREATE_STATE_OBJECT_STATISTICS StateObjectStatistics;
} D3D12_STATE_OBJECT_STATISTICS;

```

**Members**

*DefaultPSDBRegistered*

Indicates whether a default Precompile Shader Database (PSDB) is registered with the device. When set to TRUE, it means that the device has a default PSDB available.  See Remarks.

*PipelineStateObjectStatistics*

 Statistics for Pipeline State Objects created by the device through API like ID3D12Device::CreateGraphicsPipelineState, ID3D12Device::CreateComputePipelineState, and ID3D12Device2::CreatePipelineState.

*StateObjectStatistics*

Statistics for State Objects created by the device through API like ID3D12Device5::CreateStateObject and  ID3D12Device7::AddToStateObject.

**Remarks**

When DefaultPSDBRegistered is TRUE, a "default" component is registered for the application through the D3DShaderCacheRegistration API.  Additionally, the driver supports Advanced Shader Delivery, and the PSDB matches the adapter family and the supported ABI range of the driver.

### Interface: ID3D12DeviceStatistics

```c++
interface ID3D12DeviceStatistics
    : IUnknown
{
    HRESULT GetStateObjectStatistics(_Out_ D3D12_STATE_OBJECT_STATISTICS* pStatistics);
};
```

Used to retrieve State Object creation statistics.  Use QueryInterface on a device interface to retrieve this interface.

#### Method: ID3D12DeviceStatistics::GetStateObjectStatistics

Retrieve both Pipeline State Object creation statistics and State Object creation statistics.

**Arguments**

*pStatistics*

GetStateObjectStatistics initializes pStatistics members with the current statistics, see Remarks.

**Remarks**

Individual statistic counters are atomically updated, but each group of statistics is not synchronized with the API they represent.  For example, if calling ID3D12Device2::CreatePipelineState simultaneously with this API, you may retrieve statistics in between updating the PipelineStateObjectStatistics object creation counter and the miss counter.  If simultaneous statistics retrieval is required, it must be externally synchronized.
