# D3D12 : Driver Reported Messages

v0.3 9/2/2026

---

# Contents

- [D3D12: Driver Reported Messages](#d3d12--driver-reported-messages)
- [Contents](#contents)
- [Summary](#summary)
- [Proposed API](#proposed-api)
  - [ID3D12Debug7](#id3d12debug7)
    - [Forcing the feature on externally (registry and DXCPL)](#forcing-the-feature-on-externally-registry-and-dxcpl)
  - [D3D12_MESSAGE_CATEGORY and D3D12_MESSAGE_ID](#d3d12_message_category-and-d3d12_message_id)
- [Proposed DDI](#proposed-ddi)
  - [Device Function DDIs](#device-function-ddis)
    - [Enabling the feature](#enabling-the-feature)
  - [Correlating Messages to CPU-Side API Calls](#correlating-messages-to-cpu-side-api-calls)
    - [pfnSetCommandListStateIndex](#pfnsetcommandliststateindex)
    - [CommandListStateIndex validity window](#commandliststateindex-validity-window)
  - [Message Reporting](#message-reporting)
    - [PFND3D12DDI_REPORTMESSAGE_CB_0126](#pfnd3d12ddi_reportmessage_cb_0126)
      - [Message validation](#message-validation)
      - [Threading and synchronization](#threading-and-synchronization)
    - [PFND3D12DDI_QUERYOBJECTIDENTITY_CB_0126](#pfnd3d12ddi_queryobjectidentity_cb_0126)
  - [Message content and delivery expectations](#message-content-and-delivery-expectations)
  - [Flush and Message Processing](#flush-and-message-processing)
  - [Device removed behavior](#device-removed-behavior)
- [Test Plan](#test-plan)
  - [Functional tests](#functional-tests)
  - [Conformance tests](#conformance-tests)
    - [Mandatory initialization message](#mandatory-initialization-message)
- [Usage Example](#usage-example)
- [Open Questions](#open-questions)
- [Spec History](#spec-history)

---

# Summary

The D3D12 debug layer is weak when it comes to GPU-based validation. GPU-Based Validation (GBV) and DRED breadcrumbs exist, but both rely on diagnostic GPU workload that the runtime injects on the application's behalf.

GPU drivers perform their own internal validations, e.g. shader binding table checks, acceleration structure integrity, but have no standard mechanism to surface these messages in D3D12.

This spec proposes a new D3D12 feature that provides a standard channel through which drivers may surface their validation messages to applications. Drivers own their validation logic. D3D12 owns the message channel routing driver-emitted messages through the existing `ID3D12InfoQueue` surface.

# Proposed API

## ID3D12Debug7

Driver-reported messages are a global, pre-device-creation toggle modeled after `ID3D12Debug3::SetEnableGPUBasedValidation`. The toggle is exposed on a new iteration of the `ID3D12Debug` interface:

```c++
interface ID3D12Debug7 : ID3D12Debug6
{
    void SetEnableDriverReportedMessages(BOOL Enable);
};
```

`SetEnableDriverReportedMessages` opts in (`Enable = TRUE`) or out (`Enable = FALSE`, the default) of the driver-reported-messages channel.

The D3D12 debug layer must also be enabled (`ID3D12Debug::EnableDebugLayer`) before device creation for the toggle to take effect on that device. If the debug layer is not enabled, the toggle has no effect on that device.

If the app calls `SetEnableDriverReportedMessages` multiple times prior to `D3D12CreateDevice` returning, the most recent value wins. The setting is then fixed for the lifetime of that device; toggle changes made after `D3D12CreateDevice` returns have no effect on already-created devices.

If the driver does not implement the driver-reported-messages DDI, the toggle has no observable effect on that device's `ID3D12InfoQueue`. The call itself is fire-and-forget — no error is returned to the app, matching the behavior of `SetEnableGPUBasedValidation` on adapters without GBV support.

### Forcing the feature on externally (registry and DXCPL)

Driver-reported messages can be forced on or off for an application without modifying that application, via the per-application registry configuration that the DirectX Control Panel (DXCPL / `d3dconfig`) writes.

The toggle follows the same AND/OR mask convention that `EnableGPUBasedValidationFlagsAnd` / `EnableGPUBasedValidationFlagsOr` already use, allowing the feature to be left under application control, forced on, or forced off. Two `REG_DWORD` values are read from the per-application subkey under `HKCU\Software\Microsoft\Direct3D\Direct3D12\<AppName>` (with an `HKLM` fallback):

| Value name | Type |
|-|-|
| `EnableDriverReportedMessagesAnd` | `REG_DWORD`, default `1` |
| `EnableDriverReportedMessagesOr` | `REG_DWORD`, default `0` |

This overlay is applied at device creation, after the application's `SetEnableDriverReportedMessages` calls have been latched, so the registry value wins over the application's choice.

Because the feature requires the debug layer (see above), forcing driver-reported messages on is only effective when the debug layer is also active for that application — either because the application called `ID3D12Debug::EnableDebugLayer`, or because the debug layer is itself forced on through the existing `RequireSDKLayers` / `D3D12SDKLayerFlagsAnd` / `D3D12SDKLayerFlagsOr` settings. DXCPL sets those as part of its "Force On" debug-layer option.

There is no generic mechanism by which a new debug toggle automatically acquires a registry or DXCPL override; each one is plumbed individually. Enabling this for driver-reported messages therefore requires the toggle to be read alongside the existing debug-layer options at device-configuration time, and to be written and read back by `d3dconfig` so DXCPL can present and persist it.


## D3D12_MESSAGE_CATEGORY and D3D12_MESSAGE_ID

Driver-reported messages reuse the existing `D3D12_MESSAGE_CATEGORY` enum. No new category values are introduced. Category describes what kind of operation the driver was performing when the issue was detected (for example `D3D12_MESSAGE_CATEGORY_EXECUTION`, `_STATE_CREATION`, `_RESOURCE_MANIPULATION`), matching the convention already used by the runtime emitted messages. The driver supplies the category per message; see [Message Reporting](#message-reporting).

To let apps identify driver reported messages, `D3D12_MESSAGE_ID_DRIVER_REPORTED_MESSAGE` is introduced. All driver originated messages should use this ID:

```c++
typedef enum D3D12_MESSAGE_ID
{
    // ... existing entries ...
    D3D12_MESSAGE_ID_DRIVER_REPORTED_MESSAGE    = 1506,
} D3D12_MESSAGE_ID;
```

Apps filter or suppress driver-sourced messages as a class by the sentinel ID (`D3D12_MESSAGE_ID_DRIVER_REPORTED_MESSAGE`) through the normal `ID3D12InfoQueue::PushStorageFilter` path. The driver-authored `pDescription` flows verbatim into `D3D12_MESSAGE::pDescription` (see [Message Reporting](#message-reporting)); the runtime does not parse or modify it. Filtering an individual driver message rather than the whole class would require a new InfoQueue surface carrying per-message identity, which this feature does not introduce; see [Open Questions](#open-questions).

# Proposed DDI

## Device Function DDIs

### Enabling the feature

At adapter init, the runtime queries the driver's supported extended features via `pfnGetSupportedExtendedFeatures`. If the driver reports `D3D12DDI_FEATURE_0126_DRIVER_REPORTED_MESSAGES`, the runtime enables the feature per device by calling `pfnEnableExtendedFeature(hDevice, D3D12DDI_FEATURE_0126_DRIVER_REPORTED_MESSAGES, Version)` when the application opted in via `ID3D12Debug7::SetEnableDriverReportedMessages(TRUE)` and the debug layer is enabled.

If the runtime does not enable the extended feature on a device, the driver must not generate driver-reported messages on that device.

`D3D12DDI_FEATURE_0126_DRIVER_REPORTED_MESSAGES` is a new value added to the existing extended-feature enum that `pfnGetSupportedExtendedFeatures` and `pfnEnableExtendedFeature` operate on:

```c++
typedef enum D3D12DDI_FEATURE_0020
{
    // ... existing entries (SHADERCACHING, RENDER_PASS, PIN_RESOURCES, ...) ...
    D3D12DDI_FEATURE_0126_DRIVER_REPORTED_MESSAGES = 32,  // new
} D3D12DDI_FEATURE_0020;
```

The feature is versioned so it can be revised without a new feature value. The runtime negotiates the highest version both sides understand:

```c++
#define D3D12DDI_FEATURE_VERSION_DRIVER_REPORTED_MESSAGES_NONE  0u
#define D3D12DDI_FEATURE_VERSION_DRIVER_REPORTED_MESSAGES_0     1u
```

```c++
typedef enum D3D12DDI_TABLE_TYPE
{
    // ... existing entries ...
    D3D12DDI_TABLE_TYPE_0126_DRIVER_REPORTED_MESSAGES = 47,  // new
} D3D12DDI_TABLE_TYPE;

typedef VOID (APIENTRY *PFND3D12DDI_FLUSH_DRIVER_REPORTED_MESSAGES_0126)(
    D3D12DDI_HDEVICE                                hDevice);

typedef VOID (APIENTRY *PFND3D12DDI_SET_COMMAND_LIST_STATE_INDEX_0126)(
    D3D12DDI_HCOMMANDLIST                           hCommandList,
    UINT32                                          CommandListStateIndex);

typedef struct D3D12DDI_DEVICE_FUNCS_DRIVER_REPORTED_MESSAGES_0126
{
    PFND3D12DDI_FLUSH_DRIVER_REPORTED_MESSAGES_0126         pfnFlushDriverReportedMessages;
    PFND3D12DDI_SET_COMMAND_LIST_STATE_INDEX_0126           pfnSetCommandListStateIndex;
} D3D12DDI_DEVICE_FUNCS_DRIVER_REPORTED_MESSAGES_0126;
```

`pfnFlushDriverReportedMessages` is invoked by the runtime to give the driver a synchronous opportunity to flush any pending messages. The runtime calls it only when the driver-reported-messages feature has been enabled on the device (see [Enabling the feature](#enabling-the-feature)). If the driver does not support the feature (does not report `D3D12DDI_FEATURE_0126_DRIVER_REPORTED_MESSAGES`) or the runtime did not enable it, the runtime does not call `pfnFlushDriverReportedMessages`. See [Device removed behavior](#device-removed-behavior).

`pfnFlushDriverReportedMessages` lives in the `D3D12DDI_DEVICE_FUNCS_DRIVER_REPORTED_MESSAGES_0126` DDI table, which is mapped to the `D3D12DDI_FEATURE_0126_DRIVER_REPORTED_MESSAGES` extended feature and exchanged when the feature is enabled. A driver that does not support the feature omits it from `pfnGetSupportedExtendedFeatures`; the runtime then never enables the feature for devices created against that driver and never invokes `pfnFlushDriverReportedMessages`.

## Correlating Messages to CPU-Side API Calls

To allow drivers to correlate their validation messages with specific CPU-side API calls, the runtime provides a **command list state index** to the driver via a new DDI call. This index identifies a snapshot of the command list state at the time of the GPU-work generating command list API call. This is the same command list state snapshot used internally by GPU-Based Validation (GBV) to correlate its shader-emitted messages with specific draw/dispatch calls, so when both are enabled a driver-reported message and a GBV message correlate back to the same draw or dispatch.

When a message carries an index the runtime can still resolve, the runtime prefixes the driver's description with the identity of the command list that recorded the work, and the kind and ordinal of that work within the command list — for example, `[Draw #12]` — before surfacing the message through the InfoQueue. Drivers should not duplicate this information in their own description text. Messages whose index is `0xFFFFFFFF`, unknown, or no longer resolvable are surfaced unmodified.

### pfnSetCommandListStateIndex

```c++
typedef VOID (APIENTRY *PFND3D12DDI_SET_COMMAND_LIST_STATE_INDEX_0126)(
    D3D12DDI_HCOMMANDLIST                           hCommandList,
    UINT32                                          CommandListStateIndex);
```

The runtime calls `pfnSetCommandListStateIndex` on the driver before each draw, dispatch, or other GPU-work generating command list API call. The `CommandListStateIndex` is an opaque token that the runtime can later resolve back to the full command list state.

The driver must cache the most recent `CommandListStateIndex` received for a given command list and include it in the `CommandListStateIndex` field of any `D3D12DDI_DRIVER_REPORTED_MESSAGE_0126` that the driver attributes to that command list operation.

If the driver cannot attribute a message to a specific command list operation, it must set `CommandListStateIndex` to `0xFFFFFFFF` in the message. The runtime treats `0xFFFFFFFF` as "no correlation available" and will not attempt to resolve it to a command list state snapshot.

The runtime only calls `pfnSetCommandListStateIndex` when the driver-reported-messages feature has been enabled on the device. `pfnSetCommandListStateIndex` is part of the `D3D12DDI_DEVICE_FUNCS_DRIVER_REPORTED_MESSAGES_0126` table (see [Device Function DDIs](#device-function-ddis)).

### CommandListStateIndex validity window

The `CommandListStateIndex` is valid from the time it is issued until the flush for the submission that carried it has completed. State is retained **per submission**: the runtime references the command list's state table at `ExecuteCommandLists` time and releases it only once that submission's messages have been processed. A command list that is recorded but never submitted has no such flush; its indices stay resolvable until the command list is reset or destroyed.

Indices are **not** invalidated by resubmission. Submitting the same command list again without an intervening `Reset` reuses the same state table, so every submission resolves. `Reset` installs a fresh table for the new recording while any in-flight submission keeps a reference to the old one, so an earlier submission still resolves against the recording that produced it. Retention is bounded, however: if the application outruns the runtime's limit on live state indices, the oldest are dropped even while their submissions are outstanding, and a message referencing one is still delivered but without command list annotation.

Not all driver validation happens at execution time, so not every message waits for a flush. A driver that detects a problem while recording — an invalid state combination, a malformed shader binding table — may report it immediately via `pfnReportMessageCb`. The flush exists for the messages a driver *cannot* produce until the GPU has run the work.

The driver must report any messages referencing a `CommandListStateIndex` either:
- During the `pfnFlushDriverReportedMessages` call for that submission, or
- Before that flush call (e.g., asynchronously via `pfnReportMessageCb` at any earlier point)

Messages reported after the flush with stale `CommandListStateIndex` values will be delivered to the InfoQueue but the runtime will not be able to annotate them with command list state context.

## Message Reporting

```c++
typedef enum D3D12DDI_MESSAGE_SEVERITY_0126
{
    D3D12DDI_MESSAGE_SEVERITY_0126_CORRUPTION = 0,
    D3D12DDI_MESSAGE_SEVERITY_0126_ERROR      = 1,
    D3D12DDI_MESSAGE_SEVERITY_0126_WARNING    = 2,
    D3D12DDI_MESSAGE_SEVERITY_0126_INFO       = 3,
    D3D12DDI_MESSAGE_SEVERITY_0126_MESSAGE    = 4,
} D3D12DDI_MESSAGE_SEVERITY_0126;

typedef enum D3D12DDI_MESSAGE_CATEGORY_0126
{
    D3D12DDI_MESSAGE_CATEGORY_0126_APPLICATION_DEFINED   = 0,
    D3D12DDI_MESSAGE_CATEGORY_0126_MISCELLANEOUS         = 1,
    D3D12DDI_MESSAGE_CATEGORY_0126_INITIALIZATION        = 2,
    D3D12DDI_MESSAGE_CATEGORY_0126_CLEANUP               = 3,
    D3D12DDI_MESSAGE_CATEGORY_0126_COMPILATION           = 4,
    D3D12DDI_MESSAGE_CATEGORY_0126_STATE_CREATION        = 5,
    D3D12DDI_MESSAGE_CATEGORY_0126_STATE_SETTING         = 6,
    D3D12DDI_MESSAGE_CATEGORY_0126_STATE_GETTING         = 7,
    D3D12DDI_MESSAGE_CATEGORY_0126_RESOURCE_MANIPULATION = 8,
    D3D12DDI_MESSAGE_CATEGORY_0126_EXECUTION             = 9,
    D3D12DDI_MESSAGE_CATEGORY_0126_SHADER                = 10,
    D3D12DDI_MESSAGE_CATEGORY_0126_STATE_OBJECT_DATABASE = 11,
} D3D12DDI_MESSAGE_CATEGORY_0126;

// Driver-authored message payload passed to pfnReportMessageCb.
typedef struct D3D12DDI_DRIVER_REPORTED_MESSAGE_0126
{
    UINT64                                         VendorMessageId;        // opaque, IHV-defined message identifier
    D3D12DDI_MESSAGE_SEVERITY_0126                 Severity;
    D3D12DDI_MESSAGE_CATEGORY_0126                 Category;
    LPCSTR                                         pDescription;           // driver-authored message text
    UINT32                                         CommandListStateIndex;  // state index received via pfnSetCommandListStateIndex; 0xFFFFFFFF if not applicable
} D3D12DDI_DRIVER_REPORTED_MESSAGE_0126;

typedef HRESULT (APIENTRY CALLBACK *PFND3D12DDI_REPORTMESSAGE_CB_0126)(
    D3D12DDI_HRTDEVICE                              hDevice,
    _In_ CONST D3D12DDI_DRIVER_REPORTED_MESSAGE_0126* pMessage);

typedef HRESULT (APIENTRY CALLBACK *PFND3D12DDI_QUERYOBJECTIDENTITY_CB_0126)(
    D3D12DDI_HRTDEVICE                           hRTDevice,
    D3D12DDI_HANDLE_AND_TYPE                     hRTObject,
    _Inout_ SIZE_T*                              pIdentityStringSize,
    _Out_writes_opt_(*pIdentityStringSize) CHAR* pIdentityString);

typedef struct D3D12DDI_CORELAYER_DEVICECALLBACKS_0126
{
    PFND3D12DDI_SETERROR_CB                       pfnSetErrorCb;
    PFND3D12DDI_SETCOMMANDLISTERROR_CB            pfnSetCommandListErrorCb;
    // ... existing fields ...
    PFND3D12DDI_REPORTMESSAGE_CB_0126             pfnReportMessageCb;        // new
    PFND3D12DDI_QUERYOBJECTIDENTITY_CB_0126       pfnQueryObjectIdentityCb;  // new
} D3D12DDI_CORELAYER_DEVICECALLBACKS_0126;
```

The driver is responsible for pumping messages out to the runtime via `pfnReportMessageCb`. The runtime prompts the driver to deliver messages at two points: (1) via `pfnFlushDriverReportedMessages` once submitted work has completed (see [Flush and Message Processing](#flush-and-message-processing)), and (2) on device removal (see [Device removed behavior](#device-removed-behavior)). The driver may also call `pfnReportMessageCb` at any other time (e.g., during command list recording or command allocator reset).

IHVs own their validation messages. If a driver-reported message is disputed and the usage is determined to be valid, the IHV is responsible for suppressing or correcting that message in their driver. The runtime and debug layer do not parse, modify, or suppress driver-reported messages on the IHV's behalf.

### PFND3D12DDI_REPORTMESSAGE_CB_0126
`PFND3D12DDI_REPORTMESSAGE_CB_0126` is the runtime-supplied callback the driver invokes to surface a message. The driver fills a `D3D12DDI_DRIVER_REPORTED_MESSAGE_0126` and passes it by pointer. The runtime stamps the resulting `D3D12_MESSAGE` with `ID = D3D12_MESSAGE_ID_DRIVER_REPORTED_MESSAGE` and forwards `pMessage->pDescription` verbatim into `D3D12_MESSAGE::pDescription`; the runtime does not parse or modify the description text. The runtime copies the contents of `pMessage` (including the `pDescription` string) before `pfnReportMessageCb` returns; the driver retains ownership of all storage referenced by `pMessage`.

The callback returns an `HRESULT`. The runtime validates the message against the delivery contract (see [Message validation](#message-validation)) before it is surfaced. A message that complies returns `S_OK` (or another success code); a message that violates the contract is **dropped** — it never reaches the `ID3D12InfoQueue` — and the callback returns a failure `HRESULT` so the driver can detect and correct the defect. A dropped message produces no InfoQueue entry and no registered-callback invocation. The return value is diagnostic only; the driver retains ownership of `pMessage` regardless of the result, and whether or not the driver inspects the `HRESULT` is up to the driver.

#### Message validation

Because the runtime surfaces the driver's fields verbatim, it validates them before forwarding so that a driver defect cannot corrupt the InfoQueue or an application reading it. The runtime enforces:

| Field | Requirement | `HRESULT` on violation |
|-|-|-|
| `pMessage` | non-NULL | `E_INVALIDARG` |
| `pDescription` | non-NULL | `E_INVALIDARG` |
| `Severity` | within `[D3D12DDI_MESSAGE_SEVERITY_0126_CORRUPTION, D3D12DDI_MESSAGE_SEVERITY_0126_MESSAGE]` | `E_INVALIDARG` |
| `Category` | within `[D3D12DDI_MESSAGE_CATEGORY_0126_APPLICATION_DEFINED, D3D12DDI_MESSAGE_CATEGORY_0126_STATE_OBJECT_DATABASE]` | `E_INVALIDARG` |

`VendorMessageId` and `CommandListStateIndex` are not validated: any `VendorMessageId` is legal, and an unknown or unresolvable `CommandListStateIndex` (including `0xFFFFFFFF`) is already handled by surfacing the message without correlation. Calls on a device where the feature was not enabled return `E_INVALIDARG` and are dropped.

The runtime does not validate that `pDescription` is NUL-terminated, nor does it bound the description's length: a non-NULL but unterminated string cannot be safely inspected — scanning it is itself the over-read such a check would exist to prevent — so the runtime forwards the description like any other driver-supplied DDI string and relies on the driver to terminate it. `pDescription` being NUL-terminated is a driver contract, caught in driver bring-up and HLK, not something the runtime can defend against at report time.

`pMessage->CommandListStateIndex` is the command list state index for the command list operation that induced the message. If the driver cannot associate the message with a specific operation, it must set this field to `0xFFFFFFFF`.

`pMessage->VendorMessageId` is an opaque 8-byte identifier the IHV is free to populate however it likes. The runtime treats it as an opaque token: it neither defines nor interprets the value, and only requires that the same logical message use a stable `VendorMessageId` across reports. The pair `(VendorId, VendorMessageId)` is what uniquely identifies a message class across vendors; `VendorMessageId` is only guaranteed unique within a given `VendorId`. The runtime does not currently surface these values to the application: the DDI carries them so drivers report a stable identity from the outset, but no API surface exposes them yet; see [Open Questions](#open-questions).

The driver must only invoke `pfnReportMessageCb` on devices for which the runtime enabled the driver-reported-messages extended feature (see [Enabling the feature](#enabling-the-feature)). Calls on devices where the feature was not enabled are dropped by the runtime.

#### Threading and synchronization

`pfnReportMessageCb` is **thread-safe and reentrant**. Specifically:

**No DDI context is required.** The callback may be invoked from any thread at any time, including from a driver-owned background thread with no D3D12 API or DDI call in progress. Nothing in the payload's interpretation depends on the calling context — this is why `CommandListStateIndex` is carried explicitly in the message rather than inferred by the runtime from a "current" command list.

**Concurrent calls on the same `hDevice` are permitted.** The runtime serializes reports internally on the InfoQueue lock. Concurrent callers block; they do not corrupt state and no external synchronization is required of the driver.

**Reentrancy from within `pfnFlushDriverReportedMessages` is expected.** The runtime releases its internal locks before invoking the flush DDI precisely so the driver can call `pfnReportMessageCb` from inside it.

The driver must honour the following:

1. **Device lifetime.** `pfnReportMessageCb` is valid only between device creation and device destruction. Calling it on a destroyed device — for example from a detached driver background thread that outlives the device — is a use-after-free.

2. **Do not call while holding a driver lock that a DDI entry point also takes.** The callback acquires the runtime's InfoQueue lock and, while holding it, calls into DXGI to add the message — which invokes any `ID3D12InfoQueue1::RegisterMessageCallback` handler the application registered, inline and still under that lock. If that handler calls back into D3D12 and reaches a driver entry point that takes a driver lock, while another driver thread holds the same lock and is blocked reporting, the result is a deadlock. Report outside the driver's own locks.

3. **Keep the callback short.** Because reports serialize as described above, high-frequency reporting from many threads is correct but will contend.

4. **Description encoding.** `pDescription` must be a non-NULL, NUL-terminated string. The runtime rejects a NULL `pDescription` — dropping the message and returning `E_INVALIDARG` — but does not attempt to validate the string's termination or length; it forwards the description like any other driver-supplied DDI string, trusting the driver to NUL-terminate it (see [Message validation](#message-validation)).

### PFND3D12DDI_QUERYOBJECTIDENTITY_CB_0126
Drivers may enrich `pMessage` with the API-side object identifier (the canonical `0x<COM-pointer>:'<name>'` string the existing debug layer uses) by calling `pfnQueryObjectIdentityCb` for each runtime handle they want to reference before composing the string.

The callback takes a runtime-side handle (e.g. `D3D12DDI_HRTCOMMANDLIST`) paired with its `D3D12DDI_HANDLETYPE`, bundled into a single `D3D12DDI_HANDLE_AND_TYPE`:

```c++
typedef struct D3D12DDI_HANDLE_AND_TYPE
{
    VOID*               Handle;
    D3D12DDI_HANDLETYPE Type;
} D3D12DDI_HANDLE_AND_TYPE;
```

The runtime uses the handle to map to the corresponding API object.

The driver owns the buffer for the identity string and queries it with a two-call pattern. The identity string is encoded as null-terminated **UTF-8**, and all sizes are expressed in bytes (including the null terminator). UTF-8 is used so that object names set via `ID3D12Object::SetName` (which takes `LPCWSTR`) survive losslessly for non-ASCII characters.

1. **Size query.** The driver calls with `pIdentityString = nullptr`. The runtime writes the required buffer size in bytes (including the null terminator) into `*pIdentityStringSize` and returns `S_OK`.
2. **Fill.** The driver allocates a buffer of at least `*pIdentityStringSize` bytes and calls again with `pIdentityString` pointing at that buffer and `*pIdentityStringSize` set to its capacity. The runtime writes the null-terminated UTF-8 identity string into the buffer.

If the buffer supplied in the fill call is too small, the runtime returns `DXGI_ERROR_MORE_DATA` and updates `*pIdentityStringSize` with the required size so the driver can retry.

On invalid inputs — `pIdentityStringSize` is NULL, `hRTObject.Handle` is NULL, `hRTObject.Type` is not a recognized `D3D12DDI_HANDLETYPE`, or the handle does not correspond to an object of the specified type — the runtime returns `E_INVALIDARG` and writes no output.

Examples of the identity string returned in `pIdentityString`:
- `"0x000001D4A0E50A40:'MyVertexBuffer'"` -- when the app called `ID3D12Object::SetName(L"MyVertexBuffer")`.
- `"0x000001D4A0E50A40:'Unnamed ID3D12Resource Object'"` -- when no name has been set.

## Message content and delivery expectations

**Localization**: There is no expectation that driver-reported messages be localized. The existing debug layer messages are not localized, and driver-reported messages follow the same precedent. Drivers may emit messages in a single language (English is expected).

**Formatting**: The runtime forwards `pMessage->pDescription` into `D3D12_MESSAGE::pDescription` as a single InfoQueue message. If the message carries a valid `CommandListStateIndex` (not `0xFFFFFFFF`), the runtime adds the resolved command list state context to the description. If `pDescription` contains embedded `'\n'` characters, they are preserved; the runtime does not split the message into multiple InfoQueue entries on `'\n'`.

**Timeliness**: The runtime calls `pfnFlushDriverReportedMessages` on an application thread from within `ExecuteCommandLists`, `Wait`, or queue destruction. The first two flush only for work the runtime has already observed to be complete. An application that submits work and then stops calling into that queue therefore may not observe its messages until another queue on the same device flushes, or until the queue is destroyed. This is the primary delivery point for messages that carry `CommandListStateIndex` correlation. The driver may also deliver messages at any other time via `pfnReportMessageCb`, but messages delivered after the flush for a given submission cannot be correlated with command list state (see [Flush and Message Processing](#flush-and-message-processing)). On device removal, the runtime performs an additional synchronous flush (see [Device removed behavior](#device-removed-behavior)).

**Object identity timing**: `ID3D12Object::SetName` operates on the CPU timeline, so an identity string resolved via `pfnQueryObjectIdentityCb` reflects the object's name at the time of the query, which may be "from the future" relative to the GPU work the message describes. This is acceptable and considered an inherent property of CPU-timeline naming.

## Flush and Message Processing

`pfnFlushDriverReportedMessages` is always issued on an application thread, from inside an API call the application made; the runtime does not own a background thread for driver-reported messages. The runtime issues it for a command queue during `ID3D12CommandQueue::ExecuteCommandLists`, `ID3D12CommandQueue::Wait`, and destruction of the queue. Device removal is a separate, unconditional flush; see [Device removed behavior](#device-removed-behavior). The runtime guarantees nothing about how many flushes a given batch of completed work produces.

A flush carries work that has *already* completed — never the submission being made, and the runtime never waits for work to complete in order to flush. Completion is observed by polling a fence the runtime maintains on the queue. That fence advances only as the application signals the queue, so an application that submits work but never calls `ID3D12CommandQueue::Signal` may see no flush from that queue until it is destroyed.

The flush itself is device-wide rather than scoped to the queue that triggered it, so a flush issued from one queue is an opportunity for the driver to report messages for work on any queue, and an idle queue's messages can still reach the application through a different, active queue. Queue destruction flushes unconditionally, including for submissions the GPU has not finished; the driver may have nothing to report for those yet, and no further flush follows for that queue.

The driver must treat every flush as "report everything you currently hold" and must tolerate a flush with nothing to report. It reports by calling `pfnReportMessageCb` one or more times from within the flush, before returning from it; re-entering the runtime this way is expected and supported.

The driver may also call `pfnReportMessageCb` outside a flush at any time (see [Threading and synchronization](#threading-and-synchronization)), and such messages are still correlated: a `CommandListStateIndex` stays resolvable from the moment it is issued until the flush for its submission returns, so anything reported before that flush resolves normally. Only messages reported after that flush lose correlation. See [CommandListStateIndex validity window](#commandliststateindex-validity-window).

## Device removed behavior

When the device is removed, the runtime calls `pfnFlushDriverReportedMessages` synchronously the first time it surfaces `DXGI_ERROR_DEVICE_REMOVED` (or related error) to the app. The driver delivers, on the calling thread via `pfnReportMessageCb`, any messages already captured for GPU work submitted prior to the removal event.

This device-removal flush is **in addition to** the regular flush points described in [Flush and Message Processing](#flush-and-message-processing). It is invoked at most once per device, and only after a removal has been detected. The driver must return promptly. Any messages that become available only after this flush call are not surfaced through this feature.

# Test Plan

WARP implements the feature and acts as the reference implementation for both suites — it advertises the extended feature and emits the mandated initialization message, so the conformance suite runs end to end against it rather than skipping.

## Functional tests

- A driver-emitted message surfaces on `ID3D12InfoQueue` with `D3D12_MESSAGE_ID_DRIVER_REPORTED_MESSAGE`.
- Object identity resolves to the canonical identity string, including the two-call size/fill pattern.
- The opt-in is honoured and latched per device at creation time; messages are absent entirely when opted out, and two devices created with different settings stay isolated while both are alive.
- The registry AND/OR overlay forces the feature on for an application that never called `SetEnableDriverReportedMessages`, and forces it off for one that requested it.
- Driver-reported messages participate in the normal InfoQueue storage-filter model and can be suppressed as a class by the sentinel ID.
- Every DDI severity and category round-trips to the correct API enum value, and description text survives verbatim, including an oversized payload.

## Conformance tests

Apart from the [mandatory initialization message](#mandatory-initialization-message), message content is vendor-defined and HLK cannot compel a driver to emit a diagnostic, so conformance validates the **delivery contract**, not the payload. Every test asserts only what is decidable on any implementing driver; a driver that reports nothing beyond the mandated message is therefore a pass, not a skip.

- The mandatory initialization message is reported during device creation, with the exact mandated description. This is the only assertion that can fail a driver for reporting nothing.
- Every message that does arrive is well formed: a valid severity and category, a non-null description, and the sentinel message ID.
- Concurrent flushes issued from several threads against one device neither hang nor crash the driver. Watchdog-backed, since the failure mode is a hang.
- A clear and a dispatch still produce their defined results with the feature enabled, guarding against a driver taking a different code path when instrumented.

### Mandatory initialization message

A driver that implements driver-reported messages **must** report exactly one message when the runtime enables the feature on a device during device creation — immediately after the feature has been enabled, and before `EnableExtendedFeature` returns:

| Field | Required value |
|-|-|
| `Severity` | `D3D12DDI_MESSAGE_SEVERITY_0126_MESSAGE` |
| `Category` | `D3D12DDI_MESSAGE_CATEGORY_0126_INITIALIZATION` |
| `CommandListStateIndex` | `0xFFFFFFFF` — no command list is in scope during device creation |
| `VendorMessageId` | Vendor-defined |
| `pDescription` | The exact ASCII string below |

```
D3D12 Driver Reported Messages Enabled
```

# Usage Example

```c++
// 1. Enable the debug layer AND driver-reported messages BEFORE device creation.
ComPtr<ID3D12Debug> debug;
D3D12GetDebugInterface(IID_PPV_ARGS(&debug));
debug->EnableDebugLayer();

ComPtr<ID3D12Debug7> debug7;
debug.As(&debug7);
debug7->SetEnableDriverReportedMessages(TRUE);

// 2. Create the device. The driver-reported-messages channel is on for
//    this device if the driver advertises the driver-reported-messages
//    extended feature; otherwise the setting is silently inactive (no
//    error, no messages).
ComPtr<ID3D12Device> device;
D3D12CreateDevice(adapter.Get(), D3D_FEATURE_LEVEL_12_0, IID_PPV_ARGS(&device));

// 3. Get the InfoQueue1 surface and subscribe to messages.
ComPtr<ID3D12InfoQueue1> iq;
device.As(&iq);

DWORD cookie = 0;
iq->RegisterMessageCallback(
    [](D3D12_MESSAGE_CATEGORY category,
       D3D12_MESSAGE_SEVERITY severity,
       D3D12_MESSAGE_ID       id,
       LPCSTR                 description,
       void*                  /*ctx*/)
    {
        if (id == D3D12_MESSAGE_ID_DRIVER_REPORTED_MESSAGE)
        {
            // category is one of the existing D3D12_MESSAGE_CATEGORY values
            // (e.g. EXECUTION, STATE_CREATION) describing the operation the
            // driver was performing when it surfaced the message.
            printf("[driver][cat=%d][sev=%d] %s\n", category, severity, description);
        }
    },
    D3D12_MESSAGE_CALLBACK_FLAG_NONE, nullptr, &cookie);

// 3a. To suppress driver-reported messages as a class, deny the sentinel ID.
D3D12_MESSAGE_ID denyIds[] = { D3D12_MESSAGE_ID_DRIVER_REPORTED_MESSAGE };
D3D12_INFO_QUEUE_FILTER filter = {};
filter.DenyList.NumIDs  = _countof(denyIds);
filter.DenyList.pIDList = denyIds;
iq->PushStorageFilter(&filter);   // PopStorageFilter() to undo

// 4. ... submit GPU work ...

// 5. Read InfoQueue normally -- driver-reported messages arrive through the
//    registered callback above without any explicit drain. (Apps that pull
//    instead of subscribe call ID3D12InfoQueue::GetMessage and check for the
//    sentinel ID on the returned D3D12_MESSAGE.)
```

# Open Questions

- **~~Should `pfnQueryObjectIdentityCb` take a driver-side `H*` handle instead of runtime-side `HRT*` handle?~~** *(Resolved: runtime-side.)*

  The implemented design takes a runtime-side handle, bundled with its type into a single `D3D12DDI_HANDLE_AND_TYPE`, to match the convention used by every other runtime callback and avoid a runtime-side reverse lookup table. The alternative — taking a driver-side handle and having the runtime do the reverse lookup — would have extended more naturally to handle types without `HRT*` companions (descriptor heaps, heaps, etc.), and can be revisited via the feature's version macro if that becomes necessary.

- **Should the runtime surface per-message driver identity to applications?**

  The DDI carries `(VendorId, VendorMessageId)` for every driver-reported message, but no API surface exposes it. Apps can therefore only filter driver-reported messages as a single class via the sentinel `D3D12_MESSAGE_ID_DRIVER_REPORTED_MESSAGE`, not suppress one specific noisy message. Exposing the pair would require a new InfoQueue interface with widened message, callback, and filter types, which is out of scope for this feature and deferred to a follow-up.

- **Should this feature include naming support for GPU VA ranges?**

  Many driver validation scenarios reference a GPU virtual address (e.g. fault VA, dangling pointer in a shader argument) rather than a DDI handle. Resolving that GPUVA range back to an owning resource/heap and its `SetName` string would make messages like `"page fault at GPUVA 0x...: 'MyVertexBuffer' + 0x80"` directly actionable. Open questions remain around range invalidation and naming of GPUVA ranges generated on the GPU timeline.

- **Should the opt-in be per-device with category granularity instead of a single process-global boolean?**

  The current spec exposes a single `SetEnableDriverReportedMessages(BOOL)` modeled after `SetEnableGPUBasedValidation`: process-global, pre-device-creation, all-or-nothing. A richer alternative would define a `D3D12_DRIVER_REPORTED_MESSAGE_FLAGS` bitmask (e.g. `GENERAL`, `RAYTRACING`, `WORK_GRAPHS`), let the driver advertise its supported set via a `CheckFeatureSupport` caps query, and let the app opt in to a per-device subset via a debug-device interface call. The richer surface gives apps the ability to (a) only pay for validation in feature areas they actually use, and (b) enable different category sets on different devices in the same process (e.g. RT-only on the discrete adapter, `GENERAL` on the integrated).

# Spec History

| Version | Date | Details | Author |
|-|-|-|-|
| v0.3 | 2 September 2026 | Mandatory initialization message is `MESSAGE` severity; `pfnReportMessageCb` returns `HRESULT` with runtime message validation; registry/DXCPL force-on override; `CommandListStateIndex` retention for resubmitted command lists; WARP reference implementation | Henchhing Limbu (PIX) |
| v0.2 | 24 August 2026 | Mandatory initialization message with fixed description, conformance test validation, threading and flush clarifications | Henchhing Limbu (PIX) |
| v0.1 | 26 June 2026 | Add command list state correlation (`pfnSetCommandListStateIndex`), background-thread flush model, GBV interleaving, `pfnQueryObjectIdentityCb`, per-message `(VendorId, MessageId)` filtering, extended feature enablement | Henchhing Limbu (PIX) |
| v0.0 | 1 June 2026 | Initial draft spec | Henchhing Limbu (PIX) |
