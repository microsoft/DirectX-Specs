# D3D12: Structured Driver Errors

Zichuan Gong (alexgong@microsoft.com)

> **Proposal status:** This document is open for public feedback and is not an approved or shipping contract.

## Contents

- [Summary](#summary)
- [Proposed DDI](#proposed-ddi)
- [Adding error domains and data versions](#adding-error-domains-and-data-versions)
- [ExecuteTileMappings example](#executetilemappings-example)
- [Spec History](#spec-history)

## Summary

Structured driver errors report runtime-defined failures from the UMD to the D3D12 runtime. They are not driver-authored debug messages and are not gated by debug-layer enablement. The runtime may use them for error handling, DRED, telemetry, or a D3D12 debug message.

## Proposed DDI

```c++
typedef enum D3D12DDI_DRIVER_ERROR_DOMAIN_0127
{
    D3D12DDI_DRIVER_ERROR_DOMAIN_EXECUTE_TILE_MAPPINGS_0127 = 1,
} D3D12DDI_DRIVER_ERROR_DOMAIN_0127;

typedef struct D3D12DDI_DRIVER_ERROR_0127
{
    D3D12DDI_DRIVER_ERROR_DOMAIN_0127 ErrorDomain;
    UINT                              ErrorDataVersion;
    UINT                              ErrorDataSize;
    CONST VOID*                       pErrorData;
} D3D12DDI_DRIVER_ERROR_0127;

typedef HRESULT (APIENTRY CALLBACK*
    PFND3D12DDI_REPORT_STRUCTURED_ERROR_CB_0127)(
        D3D12DDI_HRTDEVICE hRTDevice,
        _In_ CONST D3D12DDI_DRIVER_ERROR_0127* pError);

typedef HRESULT (APIENTRY CALLBACK*
    PFND3D12DDI_REPORT_COMMAND_LIST_STRUCTURED_ERROR_CB_0127)(
        D3D12DDI_HRTCOMMANDLIST hRTCommandList,
        _In_ CONST D3D12DDI_DRIVER_ERROR_0127* pError);

typedef struct D3D12DDI_CORELAYER_DEVICECALLBACKS_0127
{
    // ... existing fields ...
    PFND3D12DDI_REPORT_STRUCTURED_ERROR_CB_0127              pfnReportStructuredErrorCb;
    PFND3D12DDI_REPORT_COMMAND_LIST_STRUCTURED_ERROR_CB_0127 pfnReportCommandListStructuredErrorCb;
} D3D12DDI_CORELAYER_DEVICECALLBACKS_0127;
```

The runtime validates the error domain, data version, and exact data size before interpreting and copying the data. Device-level errors use `pfnReportStructuredErrorCb` before `pfnSetErrorCb`. Command-list recording errors use `pfnReportCommandListStructuredErrorCb` before `pfnSetCommandListErrorCb`.

The reporting callbacks return `S_OK` after accepting and copying the error data. An invalid pointer, domain, version, or data size is rejected with `E_INVALIDARG`; any failure means the error data was not retained. The return value is diagnostic only, and the UMD must call the corresponding error callback regardless of the result.

## Adding error domains and data versions

To add a new feature, add an `ErrorDomain` value in the next DDI revision and define the feature's error-code enum, initial error-data version value and structure, and runtime behavior.

Error-code values are scoped by `ErrorDomain` and do not need to be globally unique. A new domain may define its own numbering, typically beginning at 1 with 0 reserved for no or unknown error.

To change an existing domain's error data, keep the old structure valid and define a new DDI-suffixed structure and version value. The UMD uses only error codes and data versions available in the current runtime DDI version. Adding an error code that uses an existing data layout does not require a new `ErrorDataVersion`.

Peer-to-peer native fences are a candidate future domain:

```c++
D3D12DDI_DRIVER_ERROR_DOMAIN_PEER_TO_PEER_NATIVE_FENCE_<DDI_VERSION> = ...,
```

The owning feature specification defines its error codes, data versions and payloads, required reporting paths, runtime behavior, domain value, and DDI revision.

## ExecuteTileMappings example

ExecuteTileMappings defines a domain-specific error-code enum and includes that typed code in its error data:

```c++
#define D3D12DDI_EXECUTE_TILE_MAPPINGS_ERROR_DATA_VERSION_NONE 0u
#define D3D12DDI_EXECUTE_TILE_MAPPINGS_ERROR_DATA_VERSION_0127 1u

typedef enum D3D12DDI_EXECUTE_TILE_MAPPINGS_ERROR_CODE_0127
{
    D3D12DDI_EXECUTE_TILE_MAPPINGS_ERROR_OUT_OF_RESOURCE_BOUNDS_0127   = 1,
    D3D12DDI_EXECUTE_TILE_MAPPINGS_ERROR_OUT_OF_TILEPOOL_BOUNDS_0127   = 2,
    D3D12DDI_EXECUTE_TILE_MAPPINGS_ERROR_UNEXPECTED_END_OF_BUFFER_0127 = 3,
    D3D12DDI_EXECUTE_TILE_MAPPINGS_ERROR_INVALID_TOKEN_0127            = 4,
    D3D12DDI_EXECUTE_TILE_MAPPINGS_ERROR_INVALID_TILEPOOL_0127         = 5,
    D3D12DDI_EXECUTE_TILE_MAPPINGS_ERROR_INVALID_RESOURCE_0127         = 6,
    D3D12DDI_EXECUTE_TILE_MAPPINGS_ERROR_INCOMPATIBLE_BOX_MAPPING_0127 = 7,
} D3D12DDI_EXECUTE_TILE_MAPPINGS_ERROR_CODE_0127;

typedef struct D3D12DDI_EXECUTE_TILE_MAPPINGS_ERROR_DATA_0127
{
    D3D12DDI_EXECUTE_TILE_MAPPINGS_ERROR_CODE_0127 ErrorCode;
    UINT64                                         TokenByteOffset;
} D3D12DDI_EXECUTE_TILE_MAPPINGS_ERROR_DATA_0127;
```

The driver reports `D3D12DDI_EXECUTE_TILE_MAPPINGS_ERROR_DATA_VERSION_0127` and `sizeof(D3D12DDI_EXECUTE_TILE_MAPPINGS_ERROR_DATA_0127)`. `ErrorCode` is not a `D3D12_MESSAGE_ID`. The runtime maps ETM's domain-local codes 1–7 to the existing `DXGK_GENERAL_ERROR_CODE` values 128–134 so kernel-backed and UMD-only implementations produce the same D3D12 error. `TokenByteOffset` is relative to `ArgumentBufferOffset`.

If ETM later adds error data, it preserves the original structure and defines a new version:

```c++
#define D3D12DDI_EXECUTE_TILE_MAPPINGS_ERROR_DATA_VERSION_01XX 2u

typedef struct D3D12DDI_EXECUTE_TILE_MAPPINGS_ERROR_DATA_01XX
{
    D3D12DDI_EXECUTE_TILE_MAPPINGS_ERROR_CODE_0127 ErrorCode;
    UINT64                                         TokenByteOffset;
    UINT64                                         AdditionalInformation;
} D3D12DDI_EXECUTE_TILE_MAPPINGS_ERROR_DATA_01XX;
```

## Spec History

| Version | Date | Details | Author |
|-|-|-|-|
| v0.2 | 3 November 2026 | Added peer-to-peer native-fence as a candidate feature domain | Zichuan Gong |
| v0.1 | 15 October 2026 | Initial structured driver-error reporting proposal with ExecuteTileMappings as the first domain | Zichuan Gong |
