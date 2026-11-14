<a id="video-extension-commands"></a>

# Video extension commands

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

<ins><!-- d3d12-review-inline:begin:video-extension:N-route:0:authored:migration-2a0e5003d0a0d664-0 -->This subordinate [Video](video.md) reference describes opaque extension
commands identified by a command GUID. Discovery and parameter reflection
describe command-defined structures for [creation and CPU execution](#extension-objects)
and [GPU recording](#extension-recording).<!-- d3d12-review-inline:end:video-extension:N-route:0:authored:migration-2a0e5003d0a0d664-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-extension:N-route:1:authored:migration-dc8a84c7085e8f5a-0 -->This is a **qualified draft**. Published behavioral requirements remain
source-only except for the explicitly scoped source inspection corroboration.
Qualifications do not establish expert or hardware approval.<!-- d3d12-review-inline:end:video-extension:N-route:1:authored:migration-dc8a84c7085e8f5a-0 --></ins>

<a id="extension-discovery"></a>

## Discovery and parameter structures

<ins><!-- d3d12-review-inline:begin:video-extension:N-query:0:authored:migration-8d146d5d1e4fe2d6-0 -->[`ID3D12VideoDevice::CheckFeatureSupport`](video-decode.md#video-check-feature-support)
owns the fixed-payload size and HRESULT protocol.
Initialize inputs. Interpret outputs only after success. `NodeIndex` is a zero-based node index,
not the single-node creation `NodeMask`.<!-- d3d12-review-inline:end:video-extension:N-query:0:authored:migration-8d146d5d1e4fe2d6-0 --></ins>

<!-- d3d12-review-alert:begin:video-extension:N-query:1:authored:migration-94b8a86e9a855955-0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | `D3D12_FEATURE_VIDEO` case | Value | Payload suffix after `D3D12_FEATURE_DATA_VIDEO_` | Input fields | Output fields |
> |---|---|---|---|---|
> | `EXTENSION_COMMAND_COUNT` | 22 | `EXTENSION_COMMAND_COUNT` | `NodeIndex` | `CommandCount` |
> | `EXTENSION_COMMANDS` | 23 | `EXTENSION_COMMANDS` | `NodeIndex`, `CommandCount`, caller array | `pCommandInfos` elements |
> | `EXTENSION_COMMAND_PARAMETER_COUNT` | 24 | `EXTENSION_COMMAND_PARAMETER_COUNT` | `CommandId`, `Stage` | `ParameterCount`, `ParameterPacking` |
> | `EXTENSION_COMMAND_PARAMETERS` | 25 | `EXTENSION_COMMAND_PARAMETERS` | `CommandId`, `Stage`, `ParameterCount`, caller array | `pParameterInfos` elements |
> | `EXTENSION_COMMAND_SUPPORT` | 26 | `EXTENSION_COMMAND_SUPPORT` | `NodeIndex`, `CommandId`, input blob and both sizes | output blob |
> | `EXTENSION_COMMAND_SIZE` | 27 | `EXTENSION_COMMAND_SIZE` | `NodeIndex`, `CommandId`, creation blob and size | `MemoryPoolL0Size`, `MemoryPoolL1Size` |

<!-- d3d12-review-alert:end:video-extension:N-query:1:authored:migration-94b8a86e9a855955-0 -->

<ins><!-- d3d12-review-inline:begin:video-extension:N-query:2:authored:migration-1f1aa24c5073f251-0 -->Query the command count for a node before filling the command info array.
`CommandCount` must equal the returned count, not merely an available capacity.
For each command GUID and stage, query parameter count and packing before
filling the parameter info array. `ParameterCount` must equal that stage's
returned count. No capacity/truncation or `MORE_DATA` protocol is specified.
Caller arrays and blobs must accommodate their declared counts or byte sizes.
The support query uses `CAPS_INPUT` and `CAPS_OUTPUT`; successful HRESULT
transport is not itself a command-defined support result. The size query
describes residency allocations, not allocation of an extension object.<!-- d3d12-review-inline:end:video-extension:N-query:2:authored:migration-1f1aa24c5073f251-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-extension:N-query:3:authored:migration-b4154af9a045e1bf-0 -->The command info `Name` and parameter info `Name` are wide string pointers.
The owning published DDI contracts require the driver to allocate and retain
both names for the device lifetime. This is a Video-specific published
requirement. It does not transfer ownership of either string to the caller.
The arrays themselves are allocated by the caller at the API boundary and
by the runtime at the driver boundary.<!-- d3d12-review-inline:end:video-extension:N-query:3:authored:migration-b4154af9a045e1bf-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-extension:N-query:4:authored:migration-a834523b39123c07-0 -->**Scoped query validation:** an out-of-range query node returns `E_INVALIDARG`
in the inspected count, enumeration, support and size paths. Command and
parameter enumeration use exact counts. Invalid driver packing or metadata,
or a driver failure for an asserted supported parameter set, can produce
`DXGI_ERROR_DRIVER_INTERNAL_ERROR`. On a negotiated video DDI older than
`_0076_0`, the inspected CPU stage parameter count path returns zero count
and packing. This does not establish a callable CPU execution path.<!-- d3d12-review-inline:end:video-extension:N-query:4:authored:migration-a834523b39123c07-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-extension:N-packing:0:authored:migration-cef0f80916ef2b62-0 -->Each stage has its own ordered parameter list and packing. The stages are
`CREATION` (0), `INITIALIZATION` (1), GPU `EXECUTION` (2), `CAPS_INPUT` (3),
`CAPS_OUTPUT` (4), `DEVICE_EXECUTE_INPUT` (5) and `DEVICE_EXECUTE_OUTPUT` (6).
CPU device execution does not use GPU `EXECUTION` parameters.
Integer types are unsigned/signed 8, 16, 32 or 64 bits; `FLOAT` and `DOUBLE`
are IEEE 32-bit and 64-bit values. `RESOURCE` is an `ID3D12Resource*` at the
API boundary, translated to `D3D12DDI_HRESOURCE` at the driver boundary.<!-- d3d12-review-inline:end:video-extension:N-packing:0:authored:migration-cef0f80916ef2b62-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-extension:N-packing:1:authored:migration-bf2786b46148f377-0 -->**Scoped packing corroboration:** the inspected runtime accepts packing
values 1, 2, 4 or 8 from the driver. Starting at byte offset zero, each member
is aligned to `min(natural_alignment(type), ParameterPacking)`, then occupies
its scalar size (or pointer size for `RESOURCE`). In notation,
`offset[i] = align_up(end[i-1], min(alignment[i], packing))` and
`end[i] = offset[i] + size[i]`, with `end[-1] = 0`.
The helper copies the supplied byte range, zeroes inter-member and remaining
padding, and translates resource members. This establishes the inspected
packing/translation route, not a universal rule that arbitrary extra bytes,
undersized blobs, null pointers or unknown layouts are valid.
No independent per-extension structure size or trailing padding requirement
is inferred from that helper.<!-- d3d12-review-inline:end:video-extension:N-packing:1:authored:migration-bf2786b46148f377-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-extension:N-packing:2:authored:migration-39b2520d0ad9568b-0 -->Simple data parameters use `FLAG_NONE`; resource flags describe read/write
usage. The inspected metadata validation requires a nonzero read/write flag
for a resource and rejects resource types in `CAPS_INPUT`, `CAPS_OUTPUT` and
`DEVICE_EXECUTE_OUTPUT`. Non-resource parameters with nonzero flags are
rejected. These are scoped runtime checks, not a complete per-extension
semantic validator.<!-- d3d12-review-inline:end:video-extension:N-packing:2:authored:migration-39b2520d0ad9568b-0 --></ins>

<a id="extension-resources"></a>

### Resource parameters and execution context

<ins><!-- d3d12-review-inline:begin:video-extension:N-resources:0:authored:migration-93b711bd524b4412-0 -->GPU recording uses a video family compatible with the command's reported
`CommandListSupportFlags`. Use that family's command list, allocator and
queue on a compatible device/node. The published command info contract says
only one family flag may be set. That upper bound does not establish an
unconditional nonzero-mask requirement or GPU recording support for a zero
mask. The creation description selects one node; enumeration on another
node is not a support guarantee.
[List/queue types](execution.md#command-list-types),
[creation](execution.md#creation) and [submission validation](execution.md#validation)
own the common compatibility requirements.<!-- d3d12-review-inline:end:video-extension:N-resources:0:authored:migration-93b711bd524b4412-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-extension:N-resources:1:authored:migration-2cfba9a4dc7789dd-0 -->CPU device execution is a separate route. A GPU family flag does not by
itself establish CPU execution support. The selected sources do not settle
zero-mask or CPU-only command validity; no such validity rule is inferred.
The three API video family flag contributions are:<!-- d3d12-review-inline:end:video-extension:N-resources:1:authored:migration-2cfba9a4dc7789dd-0 --></ins>

<!-- d3d12-review-alert:begin:video-extension:F-video-support-flags:0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | API support flag | Released expression | Value |
> |---|---|---|
> | `D3D12_COMMAND_LIST_SUPPORT_FLAG_VIDEO_DECODE` | `1 << D3D12_COMMAND_LIST_TYPE_VIDEO_DECODE` | `0x10` |
> | `D3D12_COMMAND_LIST_SUPPORT_FLAG_VIDEO_PROCESS` | `1 << D3D12_COMMAND_LIST_TYPE_VIDEO_PROCESS` | `0x20` |
> | `D3D12_COMMAND_LIST_SUPPORT_FLAG_VIDEO_ENCODE` | `1 << D3D12_COMMAND_LIST_TYPE_VIDEO_ENCODE` | `0x40` |

<!-- d3d12-review-alert:end:video-extension:F-video-support-flags:0 -->

<ins><!-- d3d12-review-inline:begin:video-extension:N-resource-states:0:authored:migration-6e8cc83ae27487fd-0 -->The published resource parameter contract requires the caller to transition
resources to the appropriate video read/write states:<!-- d3d12-review-inline:end:video-extension:N-resource-states:0:authored:migration-6e8cc83ae27487fd-0 --></ins>

<!-- d3d12-review-alert:begin:video-extension:N-resource-states:1:authored:migration-5496685880f9f8a4-0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Command family | Resource read state | Resource write state |
> |---|---|---|
> | VIDEO_DECODE | `D3D12_RESOURCE_STATE_VIDEO_DECODE_READ` | `D3D12_RESOURCE_STATE_VIDEO_DECODE_WRITE` |
> | VIDEO_PROCESS | `D3D12_RESOURCE_STATE_VIDEO_PROCESS_READ` | `D3D12_RESOURCE_STATE_VIDEO_PROCESS_WRITE` |
> | VIDEO_ENCODE | `D3D12_RESOURCE_STATE_VIDEO_ENCODE_READ` | `D3D12_RESOURCE_STATE_VIDEO_ENCODE_WRITE` |

<!-- d3d12-review-alert:end:video-extension:N-resource-states:1:authored:migration-5496685880f9f8a4-0 -->

<ins><!-- d3d12-review-inline:begin:video-extension:N-resource-states:2:authored:migration-0e7f26544c3d5123-0 -->The [video resource contract](video.md#video-resource-contract),
[enhanced decode](synchronization.md#decode-enhanced-barrier),
[enhanced process](synchronization.md#process-enhanced-barrier),
[enhanced encode](synchronization.md#encode-enhanced-barrier),
[access scopes](synchronization.md#barrier-access),
[synchronization scopes](synchronization.md#barrier-sync), and
[barrier model interoperation](synchronization.md#model-interoperation)
own the corresponding shared barrier rules. Resource dimensions, formats,
subresources, read/write aliasing and any simultaneous read/write use must
be established by the particular command contract. This table does not
permit incompatible state combinations. GPU state names do not establish
CPU execution's resource access/synchronization semantics.<!-- d3d12-review-inline:end:video-extension:N-resource-states:2:authored:migration-0e7f26544c3d5123-0 --></ins>

<a id="extension-objects"></a>

## Objects and CPU execution

<ins><!-- d3d12-review-inline:begin:video-extension:N-lifetime:0:authored:migration-d2afa609d9e2d24b-0 -->`ID3D12VideoExtensionCommand` derives from `ID3D12Pageable`.
On successful creation, `ppVideoExtensionCommand` receives a caller-owned
reference to the requested interface identified by `riid`. The caller
releases it under the [object lifetime rules](execution.md#lifetime).
The creation description is copied. `GetDesc` returns a value copy of the
immutable description. Modifying the returned value does not reconfigure
the command.<!-- d3d12-review-inline:end:video-extension:N-lifetime:0:authored:migration-d2afa609d9e2d24b-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-extension:N-lifetime:1:authored:migration-d701616049471c95-0 -->`pProtectedResourceSession` can be null for unprotected operation. A non-null
session associates the command with that protected session. The getter
retrieves the association, not a new session. On success it returns a
caller-owned reference to the requested session interface through
`ppProtectedSession`. The caller releases it under the same lifetime rules.
The selected sources do not establish a precise no-session HRESULT/null output
postcondition. No additional protection lifecycle is implied.
The existing [shared protected resource flags](video-motion-estimation.md#d3d12-video-protected-resource-support-flags)
retain their canonical definition; no extension-specific support payload is
invented from those flags.<!-- d3d12-review-inline:end:video-extension:N-lifetime:1:authored:migration-d701616049471c95-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-extension:N-lifetime:2:authored:migration-798e4f55ea36c090-0 -->**Scoped creation validation:** the inspected creation validator checks the
single-node selection and that the GUID appears in the selected node's command
enumeration; invalid selection or unsupported GUID produces `E_INVALIDARG`.
Creation propagates validation/driver HRESULT failures. A null result pointer
takes a validation-only path returning `S_FALSE` after successful description
validation and creates no object. That path is not a complete creation blob
validation guarantee and does not change the required output annotation in
the released declaration. The inspected CPU device execution path rejects
a negotiated video DDI older than `_0076_0` with `E_INVALIDARG`.
The inspected creation parameter translation rejects swap chain resources
in the creation blob with `E_INVALIDARG`. CPU device execution propagates
driver/conversion HRESULT failures. Its local allocation failure handler
returns `E_INVALIDARG`, not a promise of `E_OUTOFMEMORY`.<!-- d3d12-review-inline:end:video-extension:N-lifetime:2:authored:migration-798e4f55ea36c090-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-extension:N-lifetime:3:authored:migration-cdd6be3e5a8edec2-0 -->**Scoped CPU storage corroboration:** creation translates a temporary copy
of a nonempty creation blob before calling the driver. The CPU device method
copies/translates its input, calls the driver, then copies the output on
success. Published CPU execution completes before return. The inspected GPU
recording route copies nonempty parameter blobs into command list temporary
storage and translates resource pointers before the recording DDI.
Those source-inspected copies do not establish a driver-wide borrowing rule
for embedded resources, private payload semantics or every implementation's
creation data retention. Scalar/blob storage and the resources named in it
are distinct lifetime obligations.<!-- d3d12-review-inline:end:video-extension:N-lifetime:3:authored:migration-cdd6be3e5a8edec2-0 --></ins>

<a id="videodevice2-createvideoextensioncommand"></a>

### ID3D12VideoDevice2::CreateVideoExtensionCommand

#### Declaration

```cpp
HRESULT CreateVideoExtensionCommand(
  const D3D12_VIDEO_EXTENSION_COMMAND_DESC *pDesc,
  const void                               *pCreationParameters,
  SIZE_T                                   CreationParametersDataSizeInBytes,
  ID3D12ProtectedResourceSession           *pProtectedResourceSession,
  REFIID                                   riid,
  void                                     **ppVideoExtensionCommand
);
```

#### Behavior

Creates a video extension command.

#### Parameters

`pDesc`

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoDevice2-CreateVideoExtensionCommand:5 -->The [D3D12_VIDEO_EXTENSION_COMMAND_DESC](#d3d12-video-extension-command-desc) describing the command to be created.<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoDevice2-CreateVideoExtensionCommand:5 --></ins>

`pCreationParameters`

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoDevice2-CreateVideoExtensionCommand:7 -->A pointer to the creation parameters structure, which is defined by the command. The parameters structure must match the parameters enumerated by a call to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) with the feature value of [D3D12_FEATURE_VIDEO_EXTENSION_COMMAND_PARAMETERS](#d3d12-feature-data-video-extension-command-parameters) and a parameter stage value of [D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_CREATION](#d3d12-video-extension-command-parameter-stage).<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoDevice2-CreateVideoExtensionCommand:7 --></ins>

`CreationParametersDataSizeInBytes`

The size of the *pCreationParameters* parameter structure, in bytes.

`pProtectedResourceSession`

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoDevice2-CreateVideoExtensionCommand:11 -->A [ID3D12ProtectedResourceSession](resources.md#protected-resource-sessions) for managing access to protected resources.<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoDevice2-CreateVideoExtensionCommand:11 --></ins>

`riid`

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoDevice2-CreateVideoExtensionCommand:13 -->The globally unique identifier (GUID) for the [ID3D12VideoExtensionCommand](#extension-objects) interface.<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoDevice2-CreateVideoExtensionCommand:13 --></ins>

`ppVideoExtensionCommand`

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoDevice2-CreateVideoExtensionCommand:15 -->A pointer to a memory block that receives a pointer to the [ID3D12VideoExtensionCommand](#extension-objects) interface.<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoDevice2-CreateVideoExtensionCommand:15 --></ins>

#### Return values

This method returns an HRESULT.

<a id="videodevice2-executeextensioncommand"></a>

### ID3D12VideoDevice2::ExecuteExtensionCommand

#### Declaration

```cpp
HRESULT ExecuteExtensionCommand(
  ID3D12VideoExtensionCommand *pExtensionCommand,
  const void                  *pExecutionParameters,
  SIZE_T                      ExecutionParametersSizeInBytes,
  void                        *pOutputData,
  SIZE_T                      OutputDataSizeInBytes
);
```

#### Behavior

Executes a video extension command.

Video extension commands executed through this method must complete before this method returns. For efficiency, extension implementations should schedule work in command lists instead of using this method, whenever possible. Each video command list type provides an **ExecuteExtensionCommand** for scheduled work. These include:

- <ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoDevice2-ExecuteExtensionCommand:4 -->[ID3D12VideoDecodeCommandList2::ExecuteExtensionCommand](#videodecodecommandlist2-executeextensioncommand)<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoDevice2-ExecuteExtensionCommand:4 --></ins>
- <ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoDevice2-ExecuteExtensionCommand:4 -->[ID3D12VideoEncodeCommandList1::ExecuteExtensionCommand](#videoencodecommandlist1-executeextensioncommand)<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoDevice2-ExecuteExtensionCommand:4 --></ins>
- <ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoDevice2-ExecuteExtensionCommand:4 -->[ID3D12VideoProcessCommandList2::ExecuteExtensionCommand](#videoprocesscommandlist2-executeextensioncommand)<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoDevice2-ExecuteExtensionCommand:4 --></ins>

#### Parameters

`pExtensionCommand`

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoDevice2-ExecuteExtensionCommand:7 -->Pointer to an [ID3D12VideoExtensionCommand](#extension-objects) representing the video extension command to execute. The caller is responsible for maintaining object lifetime until command execution is complete.<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoDevice2-ExecuteExtensionCommand:7 --></ins>

`pExecutionParameters`

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoDevice2-ExecuteExtensionCommand:9 -->A pointer to the execution input parameters structure, which is defined by the command. The parameters structure must match the parameters enumerated by a call to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) with the feature value of [D3D12_FEATURE_VIDEO_EXTENSION_COMMAND_PARAMETERS](#d3d12-feature-data-video-extension-command-parameters) and a parameter stage value of [D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_DEVICE_EXECUTE_INPUT](#d3d12-video-extension-command-parameter-stage).<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoDevice2-ExecuteExtensionCommand:9 --></ins>

`ExecutionParametersSizeInBytes`

The size of the *pExecutionParameters* parameter structure, in bytes.

`pOutputData`

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoDevice2-ExecuteExtensionCommand:13 -->A pointer to the execution output parameters structure, which is defined by the command and matches the `DEVICE_EXECUTE_OUTPUT` parameter stage.<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoDevice2-ExecuteExtensionCommand:13 --></ins>

`OutputDataSizeInBytes`

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoDevice2-ExecuteExtensionCommand:15:modified:source-e944d9c8dbb49e22-0-0 -->The size of the *pOutputData* output allocation<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoDevice2-ExecuteExtensionCommand:15:modified:source-e944d9c8dbb49e22-0-0 --></ins>, in bytes.

#### Return values

This method returns HRESULT.

<a id="videoextensioncommand-getdesc"></a>

### ID3D12VideoExtensionCommand::GetDesc

#### Declaration

```cpp
D3D12_VIDEO_EXTENSION_COMMAND_DESC GetDesc();
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoExtensionCommand-GetDesc:2:authored:migration-35ca021f2e695b7d-0 -->Gets the [D3D12_VIDEO_EXTENSION_COMMAND_DESC](#d3d12-video-extension-command-desc) provided when the interface was created.<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoExtensionCommand-GetDesc:2:authored:migration-35ca021f2e695b7d-0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoExtensionCommand-GetDesc:4:authored:migration-7a6c183ba6f0a0b9-0 -->None.<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoExtensionCommand-GetDesc:4:authored:migration-7a6c183ba6f0a0b9-0 --></ins>

#### Return values

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoExtensionCommand-GetDesc:6 -->The [D3D12_VIDEO_EXTENSION_COMMAND_DESC](#d3d12-video-extension-command-desc) provided when the interface was created.<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoExtensionCommand-GetDesc:6 --></ins>

<a id="videoextensioncommand-getprotectedresourcesession"></a>

### ID3D12VideoExtensionCommand::GetProtectedResourceSession

#### Declaration

```cpp
HRESULT GetProtectedResourceSession(
  REFIID riid,
  void   **ppProtectedSession
);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoExtensionCommand-GetProtectedResourceSession:2 -->Gets the [ID3D12ProtectedResourceSession](resources.md#protected-resource-sessions) that was passed into [ID3D12VideoDevice2::CreateVideoExtensionCommand](#videodevice2-createvideoextensioncommand) when the [ID3D12VideoExtensionCommand](#extension-objects) was created.<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoExtensionCommand-GetProtectedResourceSession:2 --></ins>

#### Parameters

`riid`

The globally unique identifier (GUID) for the **ID3D12ProtectedResourceSession** interface.

`ppProtectedSession`

Receives a void pointer representing the **ID3D12ProtectedResourceSession** interface.

#### Return values

This method returns HRESULT.

<a id="extension-recording"></a>

## GPU initialization and execution

<ins><!-- d3d12-review-inline:begin:video-extension:N-record:0:authored:migration-a9d3fce11329a0e5-0 -->Initialization records initialization or re-initialization; execution records
the command's work. These are not CPU completion calls. The extension's
contract must establish when initialization is required, reusable state,
re-initialization ordering and any concurrent-use restriction. There is no
generic per-extension algorithm or decoder-derived serialization rule for
processor/encoder extensions.<!-- d3d12-review-inline:end:video-extension:N-record:0:authored:migration-a9d3fce11329a0e5-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-extension:N-record:1:authored:migration-dc1ccfddfb8f574a-0 -->All six GPU methods retain the [extension-defined predication policy](counters-queries-and-predication.md#predication-operation-matrix).
Initialization is not specified to ignore predication. No generic dirty state
mask or automatic ClearState policy is imposed by these methods.
[Recording storage](execution.md#command-storage),
[object/resource lifetime](execution.md#lifetime),
[completion and lifetime](execution.md#completion-lifetime),
[submission and ordering](execution.md#submission),
[CPU threading](execution.md#threading) and
[submission threading](execution.md#submission-threading) remain shared.
The command and all resources needed by recorded uses that will execute
must remain alive while recorded but unsubmitted, and through completion of
those GPU uses. Recording is not an automatic `AddRef` guarantee.
Reset does not complete previously submitted GPU work.<!-- d3d12-review-inline:end:video-extension:N-record:1:authored:migration-dc1ccfddfb8f574a-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-extension:N-record:2:authored:migration-fc7c70caf3b68d41-0 -->The public GPU methods return void; recording/initialization errors are
reported through debug layers and the list's `Close` return value.
**Scoped retail validation:** the inspected shared three-family recording
implementation puts an unsupported-family call into command list error with
`E_INVALIDARG`; translation storage exhaustion uses `E_OUTOFMEMORY`.
The inspected debug layer translates resource pointers to the next layer.
Its presence or absence of additional diagnostics is not a validity oracle.
The complete command-defined argument/error contract is not established by
these checks.<!-- d3d12-review-inline:end:video-extension:N-record:2:authored:migration-fc7c70caf3b68d41-0 --></ins>

<a id="videodecodecommandlist2-initializeextensioncommand"></a>

### ID3D12VideoDecodeCommandList2::InitializeExtensionCommand

#### Declaration

```cpp
void InitializeExtensionCommand(
  ID3D12VideoExtensionCommand *pExtensionCommand,
  const void                  *pInitializationParameters,
  SIZE_T                      InitializationParametersSizeInBytes
);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoDecodeCommandList2-InitializeExtensionCommand:2 -->Records a command to initialize or re-initialize a video extension command into a video decode command list.<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoDecodeCommandList2-InitializeExtensionCommand:2 --></ins>

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoDecodeCommandList2-InitializeExtensionCommand:3 -->Errors initializing the extension command are reported via debug layers and the return value of the command list's [Close](video-decode.md#decode-close) method.<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoDecodeCommandList2-InitializeExtensionCommand:3 --></ins>

#### Parameters

`pExtensionCommand`

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoDecodeCommandList2-InitializeExtensionCommand:6 -->Pointer to an [ID3D12VideoExtensionCommand](#extension-objects) representing the video extension command to initialize. The caller is responsible for maintaining object lifetime until command execution is complete.<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoDecodeCommandList2-InitializeExtensionCommand:6 --></ins>

`pInitializationParameters`

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoDecodeCommandList2-InitializeExtensionCommand:8 -->A pointer to the initialization parameters structure, which is defined by the command. The parameters structure must match the parameters enumerated by a call to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) with the feature value of [D3D12_FEATURE_VIDEO_EXTENSION_COMMAND_PARAMETERS](#d3d12-feature-data-video-extension-command-parameters) and a parameter stage value of [D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_INITIALIZATION](#d3d12-video-extension-command-parameter-stage).<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoDecodeCommandList2-InitializeExtensionCommand:8 --></ins>

`InitializationParametersSizeInBytes`

The size of the *pInitializationParameters* parameter structure, in bytes.

#### Return values

None

<a id="videodecodecommandlist2-executeextensioncommand"></a>

### ID3D12VideoDecodeCommandList2::ExecuteExtensionCommand

#### Declaration

```cpp
void ExecuteExtensionCommand(
  ID3D12VideoExtensionCommand *pExtensionCommand,
  const void                  *pExecutionParameters,
  SIZE_T                      ExecutionParametersSizeInBytes
);
```

#### Behavior

Records a command to execute a video extension command into a decode command list.

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoDecodeCommandList2-ExecuteExtensionCommand:3 -->Errors executing the extension command are reported via debug layers and the return value of the command list's [Close](video-decode.md#decode-close) method.<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoDecodeCommandList2-ExecuteExtensionCommand:3 --></ins>

#### Parameters

`pExtensionCommand`

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoDecodeCommandList2-ExecuteExtensionCommand:6 -->Pointer to an [ID3D12VideoExtensionCommand](#extension-objects) representing the video extension command to execute. The caller is responsible for maintaining object lifetime until command execution is complete.<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoDecodeCommandList2-ExecuteExtensionCommand:6 --></ins>

`pExecutionParameters`

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoDecodeCommandList2-ExecuteExtensionCommand:8 -->A pointer to the execution parameters structure, which is defined by the command. The parameters structure must match the parameters enumerated by a call to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) with the feature value of [D3D12_FEATURE_VIDEO_EXTENSION_COMMAND_PARAMETERS](#d3d12-feature-data-video-extension-command-parameters) and a parameter stage value of [D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_EXECUTION](#d3d12-video-extension-command-parameter-stage).<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoDecodeCommandList2-ExecuteExtensionCommand:8 --></ins>

`ExecutionParametersSizeInBytes`

The size of the *pExecutionParameters* parameter structure, in bytes.

#### Return values

None

<a id="videoprocesscommandlist2-initializeextensioncommand"></a>

### ID3D12VideoProcessCommandList2::InitializeExtensionCommand

#### Declaration

```cpp
void InitializeExtensionCommand(
  ID3D12VideoExtensionCommand *pExtensionCommand,
  const void                  *pInitializationParameters,
  SIZE_T                      InitializationParametersSizeInBytes
);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoProcessCommandList2-InitializeExtensionCommand:2 -->Records a command to initialize or re-initialize a video extension command into a video processor command list.<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoProcessCommandList2-InitializeExtensionCommand:2 --></ins>

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoProcessCommandList2-InitializeExtensionCommand:3 -->Errors initializing the extension command are reported via debug layers and the return value of the command list's [Close](video-processing.md#process-close) method.<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoProcessCommandList2-InitializeExtensionCommand:3 --></ins>

#### Parameters

`pExtensionCommand`

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoProcessCommandList2-InitializeExtensionCommand:6 -->Pointer to an [ID3D12VideoExtensionCommand](#extension-objects) representing the video extension command to initialize. The caller is responsible for maintaining object lifetime until command execution is complete.<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoProcessCommandList2-InitializeExtensionCommand:6 --></ins>

`pInitializationParameters`

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoProcessCommandList2-InitializeExtensionCommand:8 -->A pointer to the initialization parameters structure, which is defined by the command. The parameters structure must match the parameters enumerated by a call to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) with the feature value of [D3D12_FEATURE_VIDEO_EXTENSION_COMMAND_PARAMETERS](#d3d12-feature-data-video-extension-command-parameters) and a parameter stage value of [D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_INITIALIZATION](#d3d12-video-extension-command-parameter-stage).<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoProcessCommandList2-InitializeExtensionCommand:8 --></ins>

`InitializationParametersSizeInBytes`

The size of the *pInitializationParameters* parameter structure, in bytes.

#### Return values

None

<a id="videoprocesscommandlist2-executeextensioncommand"></a>

### ID3D12VideoProcessCommandList2::ExecuteExtensionCommand

#### Declaration

```cpp
void ExecuteExtensionCommand(
  ID3D12VideoExtensionCommand *pExtensionCommand,
  const void                  *pExecutionParameters,
  SIZE_T                      ExecutionParametersSizeInBytes
);
```

#### Behavior

Records a command to execute a video extension command into a video process command list.

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoProcessCommandList2-ExecuteExtensionCommand:3 -->Errors executing the extension command are reported via debug layers and the return value of the command list's [Close](video-processing.md#process-close) method.<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoProcessCommandList2-ExecuteExtensionCommand:3 --></ins>

#### Parameters

`pExtensionCommand`

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoProcessCommandList2-ExecuteExtensionCommand:6 -->Pointer to an [ID3D12VideoExtensionCommand](#extension-objects) representing the video extension command to execute. The caller is responsible for maintaining object lifetime until command execution is complete.<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoProcessCommandList2-ExecuteExtensionCommand:6 --></ins>

`pExecutionParameters`

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoProcessCommandList2-ExecuteExtensionCommand:8 -->A pointer to the execution parameters structure, which is defined by the command. The parameters structure must match the parameters enumerated by a call to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) with the feature value of [D3D12_FEATURE_VIDEO_EXTENSION_COMMAND_PARAMETERS](#d3d12-feature-data-video-extension-command-parameters) and a parameter stage value of [D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_EXECUTION](#d3d12-video-extension-command-parameter-stage).<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoProcessCommandList2-ExecuteExtensionCommand:8 --></ins>

`ExecutionParametersSizeInBytes`

The size of the *pExecutionParameters* parameter structure, in bytes.

#### Return values

None

<a id="videoencodecommandlist1-initializeextensioncommand"></a>

### ID3D12VideoEncodeCommandList1::InitializeExtensionCommand

#### Declaration

```cpp
void InitializeExtensionCommand(
  ID3D12VideoExtensionCommand *pExtensionCommand,
  const void                  *pInitializationParameters,
  SIZE_T                      InitializationParametersSizeInBytes
);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoEncodeCommandList1-InitializeExtensionCommand:2 -->Records a command to initialize or re-initialize a video extension command into a video encode command list.<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoEncodeCommandList1-InitializeExtensionCommand:2 --></ins>

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoEncodeCommandList1-InitializeExtensionCommand:3 -->Errors initializing the extension command are reported via debug layers and the return value of the command list's [Close](video-motion-estimation.md#encode-close) method.<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoEncodeCommandList1-InitializeExtensionCommand:3 --></ins>

#### Parameters

`pExtensionCommand`

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoEncodeCommandList1-InitializeExtensionCommand:6 -->Pointer to an [ID3D12VideoExtensionCommand](#extension-objects) representing the video extension command to initialize. The caller is responsible for maintaining object lifetime until command execution is complete.<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoEncodeCommandList1-InitializeExtensionCommand:6 --></ins>

`pInitializationParameters`

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoEncodeCommandList1-InitializeExtensionCommand:8 -->A pointer to the initialization parameters structure, which is defined by the command. The parameters structure must match the parameters enumerated by a call to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) with the feature value of [D3D12_FEATURE_VIDEO_EXTENSION_COMMAND_PARAMETERS](#d3d12-feature-data-video-extension-command-parameters) and a parameter stage value of [D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_INITIALIZATION](#d3d12-video-extension-command-parameter-stage).<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoEncodeCommandList1-InitializeExtensionCommand:8 --></ins>

`InitializationParametersSizeInBytes`

The size of the *pInitializationParameters* parameter structure, in bytes.

#### Return values

None

<a id="videoencodecommandlist1-executeextensioncommand"></a>

### ID3D12VideoEncodeCommandList1::ExecuteExtensionCommand

#### Declaration

```cpp
void ExecuteExtensionCommand(
  ID3D12VideoExtensionCommand *pExtensionCommand,
  const void                  *pExecutionParameters,
  SIZE_T                      ExecutionParametersSizeInBytes
);
```

#### Behavior

Records a command to execute a video extension command into an encode command list.

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoEncodeCommandList1-ExecuteExtensionCommand:3 -->Errors executing the extension command are reported via debug layers and the return value of the command list's [Close](video-motion-estimation.md#encode-close) method.<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoEncodeCommandList1-ExecuteExtensionCommand:3 --></ins>

#### Parameters

`pExtensionCommand`

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoEncodeCommandList1-ExecuteExtensionCommand:6 -->Pointer to an [ID3D12VideoExtensionCommand](#extension-objects) representing the video extension command to execute. The caller is responsible for maintaining object lifetime until command execution is complete.<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoEncodeCommandList1-ExecuteExtensionCommand:6 --></ins>

`pExecutionParameters`

<ins><!-- d3d12-review-inline:begin:video-extension:A-ID3D12VideoEncodeCommandList1-ExecuteExtensionCommand:8 -->A pointer to the execution parameters structure, which is defined by the command. The parameters structure must match the parameters enumerated by a call to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) with the feature value of [D3D12_FEATURE_VIDEO_EXTENSION_COMMAND_PARAMETERS](#d3d12-feature-data-video-extension-command-parameters) and a parameter stage value of [D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_EXECUTION](#d3d12-video-extension-command-parameter-stage).<!-- d3d12-review-inline:end:video-extension:A-ID3D12VideoEncodeCommandList1-ExecuteExtensionCommand:8 --></ins>

`ExecutionParametersSizeInBytes`

The size of the *pExecutionParameters* parameter structure, in bytes.

#### Return values

None

<a id="extension-types"></a>

## API type reference

<a id="d3d12-feature-data-video-extension-command-count"></a>

### D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_COUNT

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_COUNT:0 -->Provides data for calls to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) when the feature specified is [D3D12_FEATURE_VIDEO_EXTENSION_COMMAND_COUNT](#d3d12-feature-data-video-extension-command-count). Retrieves the supported number of video extension commands.<!-- d3d12-review-inline:end:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_COUNT:0 --></ins>

#### Declaration

```cpp
typedef struct D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_COUNT {
  UINT NodeIndex;
  UINT CommandCount;
} D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_COUNT;
```

#### Members

`NodeIndex`

In multi-adapter operation, this indicates which physical adapter of the device this operation applies to.

`CommandCount`

The supported number of video extension commands.

<a id="d3d12-video-extension-command-info"></a>

### D3D12_VIDEO_EXTENSION_COMMAND_INFO

Describes a video extension command.

#### Declaration

```cpp
typedef struct D3D12_VIDEO_EXTENSION_COMMAND_INFO {
  GUID                             CommandId;
  LPCWSTR                          Name;
  D3D12_COMMAND_LIST_SUPPORT_FLAGS CommandListSupportFlags;
} D3D12_VIDEO_EXTENSION_COMMAND_INFO;
```

#### Members

`CommandId`

The unique identifier for the video extension command.

`Name`

A pointer to a wide string containing the name of the command.

`CommandListSupportFlags`

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_INFO:9 -->A member of the [D3D12_COMMAND_LIST_SUPPORT_FLAGS](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_command_list_support_flags) enumeration. Indicates the video command queue that the video extension targets. Only one value from the enumeration can be set.<!-- d3d12-review-inline:end:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_INFO:9 --></ins>

#### Behavior

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_INFO:11 -->An array of this structure is provided in a [D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMANDS](#d3d12-feature-data-video-extension-commands) structure returned from a call to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) when the feature specified is [D3D12_FEATURE_VIDEO_EXTENSION_COMMANDS](#d3d12-feature-data-video-extension-commands).<!-- d3d12-review-inline:end:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_INFO:11 --></ins>

<a id="d3d12-feature-data-video-extension-commands"></a>

### D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMANDS

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMANDS:0 -->Provides data for calls to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) when the feature specified is [D3D12_FEATURE_VIDEO_EXTENSION_COMMANDS](#d3d12-feature-data-video-extension-commands). Retrieves the list of video extension commands from the driver.<!-- d3d12-review-inline:end:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMANDS:0 --></ins>

#### Declaration

```cpp
typedef struct D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMANDS {
  UINT                               NodeIndex;
  UINT                               CommandCount;
  D3D12_VIDEO_EXTENSION_COMMAND_INFO *pCommandInfos;
} D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMANDS;
```

#### Members

`NodeIndex`

In multi-adapter operation, this indicates which physical adapter of the device this operation applies to.

`CommandCount`

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMANDS:7 -->The supported number of video extension commands. This value must be the count returned by a call to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) with [D3D12_FEATURE_VIDEO_EXTENSION_COMMAND_COUNT](#d3d12-feature-data-video-extension-command-count) specified as the feature.<!-- d3d12-review-inline:end:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMANDS:7 --></ins>

`pCommandInfos`

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMANDS:9 -->Receives a list of [D3D12_VIDEO_EXTENSION_COMMAND_INFO](#d3d12-video-extension-command-info) structures describing video extension commands.<!-- d3d12-review-inline:end:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMANDS:9 --></ins>

<a id="d3d12-feature-data-video-extension-command-parameter-count"></a>

### D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_PARAMETER_COUNT

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_PARAMETER_COUNT:0 -->Provides data for calls to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) when the feature specified is [D3D12_FEATURE_VIDEO_EXTENSION_COMMAND_PARAMETER_COUNT](#d3d12-feature-data-video-extension-command-parameter-count). Retrieves the number of video extension command parameters for the specified parameter stage.<!-- d3d12-review-inline:end:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_PARAMETER_COUNT:0 --></ins>

#### Declaration

```cpp
typedef struct D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_PARAMETER_COUNT {
  GUID                                          CommandId;
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE Stage;
  UINT                                          ParameterCount;
  UINT                                          ParameterPacking;
} D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_PARAMETER_COUNT;
```

#### Members

`CommandId`

The unique identifier for the video extension command for which the parameter count is queried.

`Stage`

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_PARAMETER_COUNT:7 -->A member of the [D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE](#d3d12-video-extension-command-parameter-stage) enumeration specifying the parameter stage for which the parameter count is retrieved.<!-- d3d12-review-inline:end:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_PARAMETER_COUNT:7 --></ins>

`ParameterCount`

Receives the number of parameters in the parameter stage.

`ParameterPacking`

Receives the parameter packing for the parameter stage.

<a id="d3d12-video-extension-command-parameter-info"></a>

### D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_INFO

Describes a video extension command parameter.

#### Declaration

```cpp
typedef struct D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_INFO {
  LPCWSTR                                       Name;
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE  Type;
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAGS Flags;
} D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_INFO;
```

#### Members

`Name`

A pointer to a wide string containing the name of the <ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_INFO:5:modified:source-ba31dd4e92ef31e7-0-0 -->parameter<!-- d3d12-review-inline:end:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_INFO:5:modified:source-ba31dd4e92ef31e7-0-0 --></ins>.

`Type`

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_INFO:7 -->A member of the [D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE](#d3d12-video-extension-command-parameter-type) specifying the type of the parameter.<!-- d3d12-review-inline:end:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_INFO:7 --></ins>

`Flags`

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_INFO:9 -->A member of the [D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAGS](#d3d12-video-extension-command-parameter-flags) enumeration specifying the usage of the parameter.<!-- d3d12-review-inline:end:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_INFO:9 --></ins>

#### Behavior

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_INFO:11 -->An array of this structure is provided in a [D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_PARAMETERS](#d3d12-feature-data-video-extension-command-parameters) structure returned from a call to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) when the feature specified is [D3D12_FEATURE_VIDEO_EXTENSION_COMMAND_PARAMETERS](#d3d12-feature-data-video-extension-command-parameters).<!-- d3d12-review-inline:end:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_INFO:11 --></ins>

<a id="d3d12-feature-data-video-extension-command-parameters"></a>

### D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_PARAMETERS

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_PARAMETERS:0 -->Provides data for calls to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) when the feature specified is [D3D12_FEATURE_VIDEO_EXTENSION_COMMAND_PARAMETERS](#d3d12-feature-data-video-extension-command-parameters). Retrieves the list of video extension command parameters for the specified parameter stage.<!-- d3d12-review-inline:end:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_PARAMETERS:0 --></ins>

#### Declaration

```cpp
typedef struct D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_PARAMETERS {
  GUID                                          CommandId;
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE Stage;
  UINT                                          ParameterCount;
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_INFO  *pParameterInfos;
} D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_PARAMETERS;
```

#### Members

`CommandId`

The unique identifier for the video extension command for which parameters are retrieved.

`Stage`

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_PARAMETERS:7 -->A member of the [D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE](#d3d12-video-extension-command-parameter-stage) enumeration specifying the parameter stage for which the parameters are retrieved.<!-- d3d12-review-inline:end:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_PARAMETERS:7 --></ins>

`ParameterCount`

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_PARAMETERS:9 -->The supported number of video extension command parameters. This value must be the count returned by a call to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) with [D3D12_FEATURE_VIDEO_EXTENSION_COMMAND_PARAMETER_COUNT](#d3d12-feature-data-video-extension-command-parameter-count) specified as the feature.<!-- d3d12-review-inline:end:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_PARAMETERS:9 --></ins>

`pParameterInfos`

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_PARAMETERS:11 -->Receives a list of [D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_INFO](#d3d12-video-extension-command-parameter-info) structures describing video extension command parameters.<!-- d3d12-review-inline:end:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_PARAMETERS:11 --></ins>

<a id="d3d12-feature-data-video-extension-command-support"></a>

### D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_SUPPORT

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_SUPPORT:0 -->Provides data for calls to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) when the feature specified is [D3D12_FEATURE_VIDEO_EXTENSION_COMMAND_SUPPORT](#d3d12-feature-data-video-extension-command-support). Retrieves video extension command support using command-defined input and output structures.<!-- d3d12-review-inline:end:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_SUPPORT:0 --></ins>

#### Declaration

```cpp
typedef struct D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_SUPPORT {
  UINT       NodeIndex;
  GUID       CommandId;
  const void *pInputData;
  SIZE_T     InputDataSizeInBytes;
  void       *pOutputData;
  SIZE_T     OutputDataSizeInBytes;
} D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_SUPPORT;
```

#### Members

`NodeIndex`

In multi-adapter operation, this indicates which physical adapter of the device this operation applies to.

`CommandId`

The unique identifier for the video extension command for which support is queried.

`pInputData`

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_SUPPORT:9 -->Input data for the capability query allocated by the caller with a size of *InputDataSizeInBytes*. This struct is enumerable as the [D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_CAPS_INPUT](#d3d12-video-extension-command-parameter-stage) parameter stage.<!-- d3d12-review-inline:end:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_SUPPORT:9 --></ins>

`InputDataSizeInBytes`

The byte size of the input data allocation.

`pOutputData`

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_SUPPORT:13 -->Output data for the capability query allocated by the caller with a size of *OutputDataSizeInBytes*. This struct is enumerable as the [D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_CAPS_OUTPUT](#d3d12-video-extension-command-parameter-stage) parameter stage.<!-- d3d12-review-inline:end:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_SUPPORT:13 --></ins>

`OutputDataSizeInBytes`

The byte size of the output data allocation.

<a id="d3d12-feature-data-video-extension-command-size"></a>

### D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_SIZE

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_SIZE:0 -->Provides data for calls to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) when the feature specified is [D3D12_FEATURE_VIDEO_EXTENSION_COMMAND_SIZE](#d3d12-feature-data-video-extension-command-size). Checks the allocation size of a video extension command.<!-- d3d12-review-inline:end:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_SIZE:0 --></ins>

#### Declaration

```cpp
typedef struct D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_SIZE {
  UINT       NodeIndex;
  GUID       CommandId;
  const void *pCreationParameters;
  SIZE_T     CreationParametersSizeInBytes;
  UINT64     MemoryPoolL0Size;
  UINT64     MemoryPoolL1Size;
} D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_SIZE;
```

#### Members

`NodeIndex`

In multi-adapter operation, this indicates which physical adapter of the device this operation applies to.

`CommandId`

The unique identifier for the video extension command for which size is queried.

`pCreationParameters`

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_SIZE:9 -->A pointer to the creation parameters structure, which is defined by the command. The parameters structure must match the parameters enumerated by a call to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) with the feature value of [D3D12_FEATURE_VIDEO_EXTENSION_COMMAND_PARAMETERS](#d3d12-feature-data-video-extension-command-parameters) and a parameter stage value of [D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_CREATION](#d3d12-video-extension-command-parameter-stage).<!-- d3d12-review-inline:end:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_SIZE:9 --></ins>

`CreationParametersSizeInBytes`

The size of the *pCreationParameters* parameter structure, in bytes.

`MemoryPoolL0Size`

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_SIZE:13 -->The allocation size of the video extension command in the L0 memory pool. L0 is the physical system memory pool. When the adapter is discrete/NUMA, this pool has greater bandwidth for the CPU and less bandwidth for the GPU. When the adapter is UMA, this pool is the only one which is valid. For more information, see [Residency](resources.md#residency).<!-- d3d12-review-inline:end:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_SIZE:13 --></ins>

`MemoryPoolL1Size`

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_SIZE:15 -->The allocation size of the video extension command heap in the L1 memory pool. L1 is typically known as the physical video memory pool. L1 is only available when the adapter is discrete/NUMA, and has greater bandwidth for the GPU and cannot even be accessed by the CPU. When the adapter is UMA, this pool is not available. For more information, see [Residency](resources.md#residency).<!-- d3d12-review-inline:end:video-extension:T-D3D12_FEATURE_DATA_VIDEO_EXTENSION_COMMAND_SIZE:15 --></ins>

<a id="d3d12-video-extension-command-desc"></a>

### D3D12_VIDEO_EXTENSION_COMMAND_DESC

Describes a video extension command.

#### Declaration

```cpp
typedef struct D3D12_VIDEO_EXTENSION_COMMAND_DESC {
  UINT NodeMask;
  GUID CommandId;
} D3D12_VIDEO_EXTENSION_COMMAND_DESC;
```

#### Members

`NodeMask`

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_DESC:5 -->For single GPU operation, set this to zero. If there are multiple GPU nodes, set a bit to identify the node (the device's physical adapter) to which the video extension command object applies. Each bit in the mask corresponds to a single node. Only 1 bit may be set.<!-- d3d12-review-inline:end:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_DESC:5 --></ins>

`CommandId`

The unique identifier for the video extension command.

#### Behavior

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_DESC:9 -->Pass this structure to [ID3D12VideoDevice2::CreateVideoExtensionCommand](#videodevice2-createvideoextensioncommand) to create an instance of [ID3D12VideoExtensionCommand](#extension-objects).<!-- d3d12-review-inline:end:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_DESC:9 --></ins>

<a id="d3d12-video-extension-command-parameter-stage"></a>

### D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE

Specifies the parameter stages for video extension commands.

#### Declaration

```cpp
typedef enum D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE {
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_CREATION = 0,
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_INITIALIZATION = 1,
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_EXECUTION = 2,
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_CAPS_INPUT = 3,
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_CAPS_OUTPUT = 4,
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_DEVICE_EXECUTE_INPUT = 5,
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_DEVICE_EXECUTE_OUTPUT = 6
} D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE;
```

#### Constants

<!-- d3d12-review-alert:begin:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE:4:modified:migration-be154fbb125a1e14-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Constant | Value | Meaning |
> |---|---|---|
> | `D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_CREATION` | 0 | The parameter stage is in video extension command creation. |
> | `D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_INITIALIZATION` | 1 | The parameter stage is in video extension command initialization. |
> | `D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_EXECUTION` | 2 | The parameter stage is in video extension command execution. |
> | `D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_CAPS_INPUT` | 3 | The parameter stage is input parameters passed to capabilities queries. |
> | `D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_CAPS_OUTPUT` | 4 | The parameter stage is output parameters passed to capabilities queries. |
> | `D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_DEVICE_EXECUTE_INPUT` | 5 | The parameter stage is device execution input. |
> | `D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_DEVICE_EXECUTE_OUTPUT` | 6 | The parameter stage is device execution output. |

<!-- d3d12-review-alert:end:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE:4:modified:migration-be154fbb125a1e14-0 -->

#### Behavior

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE:6 -->Values from this enumeration are used when querying for video extension parameter information with calls to [ID3D12VideoDevice::CheckFeatureSupport](video-decode.md#video-check-feature-support) with the feature specified as [D3D12_FEATURE_VIDEO_EXTENSION_COMMAND_PARAMETERS](#d3d12-feature-data-video-extension-command-parameters) or [D3D12_FEATURE_VIDEO_EXTENSION_COMMAND_PARAMETER_COUNT](#d3d12-feature-data-video-extension-command-parameter-count). The results of these parameter queries may be different for different parameter stages.<!-- d3d12-review-inline:end:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE:6 --></ins>

<a id="d3d12-video-extension-command-parameter-type"></a>

### D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE

Specifies the types of parameters for video extension commands.

#### Declaration

```cpp
typedef enum D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE {
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_UINT8 = 0,
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_UINT16 = 1,
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_UINT32 = 2,
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_UINT64 = 3,
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_SINT8 = 4,
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_SINT16 = 5,
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_SINT32 = 6,
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_SINT64 = 7,
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_FLOAT = 8,
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_DOUBLE = 9,
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_RESOURCE = 10
} D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE;
```

#### Constants

<!-- d3d12-review-alert:begin:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE:4:modified:migration-13f4ae63bcc81cd3-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Constant | Value | Meaning |
> |---|---|---|
> | `D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_UINT8` | 0 | Unsigned 8-bit integer. |
> | `D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_UINT16` | 1 | Unsigned 16-bit integer. |
> | `D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_UINT32` | 2 | Unsigned 32-bit integer. |
> | `D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_UINT64` | 3 | Unsigned 64-bit integer. |
> | `D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_SINT8` | 4 | Signed 8-bit integer. |
> | `D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_SINT16` | 5 | Signed 16-bit integer. |
> | `D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_SINT32` | 6 | Signed 32-bit integer. |
> | `D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_SINT64` | 7 | Signed 64-bit integer. |
> | `D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_FLOAT` | 8 | IEEE 32-bit floating point number |
> | `D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_DOUBLE` | 9 | IEEE 64-bit floating point number |
> | `D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_RESOURCE` | 10 | An `ID3D12Resource*` at the API boundary; see [resource parameters and states](#extension-resources). |

<!-- d3d12-review-alert:end:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE:4:modified:migration-13f4ae63bcc81cd3-0 -->

#### Behavior

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE:6 -->Values from this enumeration are used by the [D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_INFO](#d3d12-video-extension-command-parameter-info) structure.<!-- d3d12-review-inline:end:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE:6 --></ins>

<a id="d3d12-video-extension-command-parameter-flags"></a>

### D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAGS

Specifies the usage of the associated video extension command parameter.

#### Declaration

```cpp
typedef enum D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAGS {
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAG_NONE = 0,
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAG_READ = 0x1,
  D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAG_WRITE = 0x2
} D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAGS;
```

#### Constants

<!-- d3d12-review-alert:begin:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAGS:4:modified:migration-3cffbb694ebb37dd-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Constant | Value | Meaning |
> |---|---|---|
> | `D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAG_NONE` | 0 | None. Set for simple data type parameters. |
> | `D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAG_READ` | 0x1 | The resource parameter is read. This flag is for **ID3D12Resource** only and is not valid for simple data type parameters. |
> | `D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAG_WRITE` | 0x2 | The resource parameter is written. This flag is for **ID3D12Resource** only and is not valid for simple data type parameters. |

<!-- d3d12-review-alert:end:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAGS:4:modified:migration-3cffbb694ebb37dd-0 -->

#### Behavior

<ins><!-- d3d12-review-inline:begin:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAGS:6 -->Values from this enumeration are used by the [D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_INFO](#d3d12-video-extension-command-parameter-info) structure.<!-- d3d12-review-inline:end:video-extension:T-D3D12_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAGS:6 --></ins>

<a id="extension-driver"></a>

## Driver reference

<ins><!-- d3d12-review-inline:begin:video-extension:N-ddi:0:authored:migration-ca82eaa8e2d6b100-0 -->The GPU extension DDIs return HRESULT even though their API recording methods return void.<!-- d3d12-review-inline:end:video-extension:N-ddi:0:authored:migration-ca82eaa8e2d6b100-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-extension:N-ddi:1:authored:migration-018e299b1f2d1061-0 -->Video feature `_0063_0` (15) supplies discovery, object lifecycle and GPU initialization/execution. `_0076_0` (17) adds device CPU execution. Both require at least `D3D12DDI_SUPPORTED_0043`.<!-- d3d12-review-inline:end:video-extension:N-ddi:1:authored:migration-018e299b1f2d1061-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-extension:N-ddi:2:authored:migration-d43dfb77e39aa43a-0 -->`D3D12DDI_TABLE_TYPE_0020_DEVICE_VIDEO` selects the device-video function
table. `_0063` provides private size/create/destroy slots. `_0076` adds
`pfnExecuteDeviceVideoExtensionCommand`. The DECODE, PROCESS and ENCODE
`_0063` command list tables each provide both
`pfnInitializeVideoExtensionCommand` and `pfnExecuteVideoExtensionCommand`.
Their table types are `D3D12DDI_TABLE_TYPE_0022_COMMAND_LIST_VIDEO_DECODE`
(12), `D3D12DDI_TABLE_TYPE_0022_COMMAND_LIST_VIDEO_PROCESS` (14) and
`D3D12DDI_TABLE_TYPE_0053_COMMAND_LIST_VIDEO_ENCODE` (21), respectively.
The extension's handle type is `D3D12DDI_HT_0061_VIDEO_EXTENSION_COMMAND`
(47).
Queue flags use `_0022_VIDEO_DECODE = 0x10`, `_0022_VIDEO_PROCESS = 0x20`
and `_0053_VIDEO_ENCODE = 0x40` in `D3D12DDI_COMMAND_QUEUE_FLAGS`.<!-- d3d12-review-inline:end:video-extension:N-ddi:2:authored:migration-d43dfb77e39aa43a-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-extension:N-ddi:3:authored:migration-a05c9684d281d2cf-0 -->Drivers must support MakeResident/Evict for extension command handles. Significant internal allocations should be made at creation, but later allocations are not forbidden.<!-- d3d12-review-inline:end:video-extension:N-ddi:3:authored:migration-a05c9684d281d2cf-0 --></ins>

<a id="extension-ddi-capabilities"></a>

### Driver capability requests

<ins><!-- d3d12-review-inline:begin:video-extension:N-ddi-capabilities:0:authored:migration-899086e5c63045f1-0 -->For the six extension queries, `pData` points to the listed payload and `DataSize` is its `sizeof`, not a nested array or blob size.<!-- d3d12-review-inline:end:video-extension:N-ddi-capabilities:0:authored:migration-899086e5c63045f1-0 --></ins>

<!-- d3d12-review-alert:begin:video-extension:N-ddi-capabilities:1:authored:migration-f35b86df53b0a961-0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | API feature suffix after `D3D12_FEATURE_VIDEO_` | Driver case suffix after `D3D12DDICAPS_TYPE_VIDEO_0063_` | Value | `pData` payload (`DataSize = sizeof(payload)`) | Input fields | Output fields |
> |---|---|---|---|---|---|
> | `EXTENSION_COMMAND_COUNT` | `EXTENSION_COMMAND_COUNT` | 22 | `D3D12DDI_VIDEO_EXTENSION_COMMAND_COUNT_DATA_0063` | `NodeIndex` | `CommandCount` |
> | `EXTENSION_COMMANDS` | `EXTENSION_COMMANDS` | 23 | `D3D12DDI_VIDEO_EXTENSION_COMMANDS_DATA_0063` | `NodeIndex`, `CommandCount`, `pCommandInfos` storage | `pCommandInfos` elements |
> | `EXTENSION_COMMAND_PARAMETER_COUNT` | `EXTENSION_COMMAND_PARAMETER_COUNT` | 24 | `D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_COUNT_DATA_0063` | `CommandId`, `Stage` | `ParameterCount`, `ParameterPacking` |
> | `EXTENSION_COMMAND_PARAMETERS` | `EXTENSION_COMMAND_PARAMETERS` | 25 | `D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETERS_DATA_0063` | `CommandId`, `Stage`, `ParameterCount`, `pParameterInfos` storage | `pParameterInfos` elements |
> | `EXTENSION_COMMAND_SUPPORT` | `EXTENSION_COMMAND_CAPS` | 26 | `D3D12DDI_VIDEO_EXTENSION_COMMAND_CAPS_DATA_0063` | `NodeIndex`, `CommandId`, `pInputData`, `InputDataSizeInBytes`, output allocation and `OutputDataSizeInBytes` | `pOutputData` bytes |
> | `EXTENSION_COMMAND_SIZE` | `EXTENSION_COMMAND_SIZE` | 27 | `D3D12DDI_VIDEO_EXTENSION_COMMAND_SIZE_DATA_0063` | `NodeIndex`, `CommandId`, `pCreationParameters`, `CreationParametersSizeInBytes` | `MemoryPoolL0Size`, `MemoryPoolL1Size` |

<!-- d3d12-review-alert:end:video-extension:N-ddi-capabilities:1:authored:migration-f35b86df53b0a961-0 -->

<ins><!-- d3d12-review-inline:begin:video-extension:N-ddi-capabilities:2:authored:migration-a173bedf12be6c73-0 -->API SUPPORT maps to the DDI CAPS case. These requests do not share a universal null-`pInfo` convention.<!-- d3d12-review-inline:end:video-extension:N-ddi-capabilities:2:authored:migration-a173bedf12be6c73-0 --></ins>

<a id="extension-ddi-declarations"></a>

### Published declarations

<a id="extension-ddi-stages"></a>

#### Feature version, handle and stages

<a id="d3d12ddi-video-extension-command-parameter-stage-0063"></a>

```cpp
// Version: D3D12DDI_FEATURE_VERSION_VIDEO_0063
// Usermode DDI Min Version: D3D12DDI_SUPPORTED_0043

#define D3D12DDI_FEATURE_VERSION_VIDEO_0063_0 15u

// UMD handle types
D3D10DDI_H( D3D12DDI_HVIDEOEXTENSIONCOMMAND_0063 )

typedef enum D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_0063
{
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_0063_CREATION = 0,
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_0063_INITIALIZATION = 1,
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_0063_EXECUTION = 2,
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_0063_CAPS_INPUT = 3,
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_0063_CAPS_OUTPUT = 4,
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_0076_DEVICE_EXECUTE_INPUT = 5,
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_0076_DEVICE_EXECUTE_OUTPUT = 6,
} D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_0063;
```

<a id="extension-ddi-parameter-types"></a>

#### Parameter types and usage flags

<a id="d3d12ddi-video-extension-command-parameter-flags-0063"></a>
<a id="d3d12ddi-video-extension-command-parameter-type-0063"></a>

```cpp
typedef enum D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063
{
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063_UINT8 = 0,
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063_UINT16 = 1,
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063_UINT32 = 2,
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063_UINT64 = 3,
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063_SINT8 = 4,
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063_SINT16 = 5,
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063_SINT32 = 6,
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063_SINT64 = 7,
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063_FLOAT = 8,
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063_DOUBLE = 9,
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063_RESOURCE = 10,
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063_MAX_VALID,
} D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063;

typedef enum D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAGS_0063
{
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAG_0063_NONE = 0x00000000,
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAG_0063_READ = 0x00000001,
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAG_0063_WRITE = 0x00000002,
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAG_0063_MASK = D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAG_0063_READ | D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAG_0063_WRITE,
} D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAGS_0063;
DEFINE_ENUM_FLAG_OPERATORS( D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAGS_0063 )
```

<a id="extension-ddi-command-enumeration"></a>

#### Command enumeration

<a id="d3d12ddi-video-extension-command-count-data-0063"></a>

```cpp
// D3D12DDICAPS_TYPE_VIDEO_0063_EXTENSION_COMMAND_COUNT
typedef struct D3D12DDI_VIDEO_EXTENSION_COMMAND_COUNT_DATA_0063
{
    UINT NodeIndex;        // in
    UINT CommandCount;    // out
} D3D12DDI_VIDEO_EXTENSION_COMMAND_COUNT_DATA_0063;

typedef struct D3D12DDI_VIDEO_EXTENSION_COMMAND_INFO_0063
{
    GUID CommandId;
    LPCWSTR Name;
    D3D12DDI_COMMAND_QUEUE_FLAGS CommandQueueFlags;
} D3D12DDI_VIDEO_EXTENSION_COMMAND_INFO_0063;


// D3D12DDICAPS_TYPE_VIDEO_0063_EXTENSION_COMMANDS
typedef struct D3D12DDI_VIDEO_EXTENSION_COMMANDS_DATA_0063
{
    UINT NodeIndex; // input
    UINT CommandCount; // input
    _Field_size_full_(CommandCount) D3D12DDI_VIDEO_EXTENSION_COMMAND_INFO_0063* pCommandInfos; // Output, allocated by runtime.
} D3D12DDI_VIDEO_EXTENSION_COMMANDS_DATA_0063;
```

<a id="extension-ddi-parameter-enumeration"></a>

#### Parameter enumeration

```cpp
typedef struct D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_INFO_0063
{
    LPCWSTR Name;
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063 Type;
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAGS_0063 Flags;
} D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_INFO_0063;
```

<a id="d3d12ddi-video-extension-command-parameter-count-data-0063"></a>

```cpp
// D3D12DDICAPS_TYPE_VIDEO_0063_EXTENSION_COMMAND_PARAMETER_COUNT
typedef struct D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_COUNT_DATA_0063
{
    GUID CommandId;                                                 // input
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_0063 Stage;    // input
    UINT ParameterCount;                                            // output
    UINT ParameterPacking;                                          // output
} D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_COUNT_DATA_0063;

// D3D12DDICAPS_TYPE_VIDEO_0063_EXTENSION_COMMAND_PARAMETERS
typedef struct D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETERS_DATA_0063
{
    GUID CommandId;                                                                                             // input
    D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_0063 Stage;                                                // input
    UINT ParameterCount;                                                                                        // input
    _Field_size_full_(ParameterCount) D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_INFO_0063* pParameterInfos;    // output
} D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETERS_DATA_0063;
```

<a id="extension-ddi-support-size"></a>

#### Support and residency size payloads

```cpp
// D3D12DDICAPS_TYPE_VIDEO_0063_EXTENSION_COMMAND_CAPS
typedef struct D3D12DDI_VIDEO_EXTENSION_COMMAND_CAPS_DATA_0063
{
    UINT NodeIndex;
    GUID CommandId;
    _Field_size_bytes_full_opt_(InputDataSizeInBytes) const void *pInputData;
    SIZE_T InputDataSizeInBytes;
    _Field_size_bytes_full_(OutputDataSizeInBytes) void *pOutputData;
    SIZE_T OutputDataSizeInBytes;
} D3D12DDI_VIDEO_EXTENSION_COMMAND_CAPS_DATA_0063;

// D3D12DDICAPS_TYPE_VIDEO_0063_EXTENSION_COMMAND_SIZE
typedef struct D3D12DDI_VIDEO_EXTENSION_COMMAND_SIZE_DATA_0063
{
    UINT NodeIndex;                                                                                     // input
    GUID CommandId;                                                                                     // input
    _Field_size_bytes_full_(CreationParametersDataSizeInBytes) CONST void *pCreationParameters;         // input
    SIZE_T CreationParametersSizeInBytes;                                                               // input
    UINT64 MemoryPoolL0Size;                                                                            // output
    UINT64 MemoryPoolL1Size;                                                                            // output
} D3D12DDI_VIDEO_EXTENSION_COMMAND_SIZE_DATA_0063;
```

<a id="extension-ddi-object-callbacks"></a>

#### Object creation and destruction

<a id="d3d12ddiarg-create-video-extension-command-0063"></a>

```cpp
typedef struct D3D12DDIARG_CREATE_VIDEO_EXTENSION_COMMAND_0063
{
    UINT NodeMask;
    GUID CommandId;
    CONST void* pCreationParameters;
    SIZE_T CreationParametersDataSizeInBytes;
    D3D12DDI_HPROTECTEDRESOURCESESSION_0030 hDrvProtectedResourceSession;
} D3D12DDIARG_CREATE_VIDEO_EXTENSION_COMMAND_0063;

typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALCPRIVATEVIDEOEXTENSIONCOMMANDSIZE_0061 )(
    D3D12DDI_HDEVICE hDrvDevice,
    _In_ CONST D3D12DDIARG_CREATE_VIDEO_EXTENSION_COMMAND_0063* pArgs);

typedef HRESULT(APIENTRY* PFND3D12DDI_CREATEVIDEOEXTENSIONCOMMAND_0063) (
    D3D12DDI_HDEVICE hDrvDevice,
    _In_ CONST D3D12DDIARG_CREATE_VIDEO_EXTENSION_COMMAND_0063* pArgs,
    D3D12DDI_HVIDEOEXTENSIONCOMMAND_0063 hDrvVideoExtensionCommand);

typedef VOID(APIENTRY* PFND3D12DDI_DESTROYVIDEOEXTENSIONCOMMAND_0063) (
    D3D12DDI_HDEVICE hDrvDevice,
    D3D12DDI_HVIDEOEXTENSIONCOMMAND_0063 hDrvVideoExtensionCommand);
```

<a id="extension-ddi-gpu-callbacks"></a>

<a id="gpu-recording-callbacks"></a>

#### GPU recording DDIs

```cpp
typedef HRESULT(APIENTRY* PFND3D12DDI_INITIALIZE_VIDEO_EXTENSION_COMMAND_0063)(
    D3D12DDI_HCOMMANDLIST hDrvCommandList,
    D3D12DDI_HVIDEOEXTENSIONCOMMAND_0063 hDrvVideoExtensionCommand,
    _In_reads_bytes_(InitializationParametersSizeInBytes) CONST void *pInitializationParameters,
    _In_ SIZE_T InitializationParametersSizeInBytes);

typedef HRESULT(APIENTRY* PFND3D12DDI_EXECUTE_VIDEO_EXTENSION_COMMAND_0063)(
    D3D12DDI_HCOMMANDLIST hDrvCommandList,
    D3D12DDI_HVIDEOEXTENSIONCOMMAND_0063 hDrvVideoExtensionCommand,
    _In_reads_bytes_ (ExecutionParametersSizeInBytes) CONST void *pExecutionParameters,
    _In_ SIZE_T ExecutionParametersSizeInBytes);
```

<a id="extension-ddi-cpu-callback"></a>

<a id="cpu-execution-callback"></a>

#### CPU execution DDI

```cpp
// D3D12 Extended Feature Video
// Version: D3D12DDI_FEATURE_VERSION_VIDEO_0076_0
// Usermode DDI Min Version: D3D12DDI_SUPPORTED_0043

#define D3D12DDI_FEATURE_VERSION_VIDEO_0076_0 17u

typedef HRESULT(APIENTRY* PFND3D12DDI_EXECUTEDEVICEVIDEOEXTENSIONCOMMAND_0076)(
    D3D12DDI_HDEVICE hDrvDevice,
    D3D12DDI_HVIDEOEXTENSIONCOMMAND_0063 hDrvVideoExtensionCommand,
    _In_reads_bytes_ (ExecutionParametersSizeInBytes) CONST void *pExecutionParameters,
    _In_ SIZE_T ExecutionParametersSizeInBytes,
    _Out_writes_bytes_(OutputDataSizeInBytes) void *pOutputData,
    SIZE_T OutputDataSizeInBytes);
```

<a id="extension-ddi-associations"></a>

<a id="extension-callback-associations"></a>

### Extension DDI associations

<!-- d3d12-review-alert:begin:video-extension:D229-current-extension-members:0:authored:migration-2d14df600936771c-0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Current table | Extension member | DDI typedef |
> |---|---|---|
> | `D3D12DDI_COMMAND_LIST_FUNCS_VIDEO_DECODE_0094` | `pfnInitializeVideoExtensionCommand` | `PFND3D12DDI_INITIALIZE_VIDEO_EXTENSION_COMMAND_0063` |
> | `D3D12DDI_COMMAND_LIST_FUNCS_VIDEO_DECODE_0094` | `pfnExecuteVideoExtensionCommand` | `PFND3D12DDI_EXECUTE_VIDEO_EXTENSION_COMMAND_0063` |
> | `D3D12DDI_COMMAND_LIST_FUNCS_VIDEO_ENCODE_0103` | `pfnInitializeVideoExtensionCommand` | `PFND3D12DDI_INITIALIZE_VIDEO_EXTENSION_COMMAND_0063` |
> | `D3D12DDI_COMMAND_LIST_FUNCS_VIDEO_ENCODE_0103` | `pfnExecuteVideoExtensionCommand` | `PFND3D12DDI_EXECUTE_VIDEO_EXTENSION_COMMAND_0063` |
> | `D3D12DDI_COMMAND_LIST_FUNCS_VIDEO_PROCESS_0106` | `pfnInitializeVideoExtensionCommand` | `PFND3D12DDI_INITIALIZE_VIDEO_EXTENSION_COMMAND_0063` |
> | `D3D12DDI_COMMAND_LIST_FUNCS_VIDEO_PROCESS_0106` | `pfnExecuteVideoExtensionCommand` | `PFND3D12DDI_EXECUTE_VIDEO_EXTENSION_COMMAND_0063` |
> | `D3D12DDI_DEVICE_FUNCS_VIDEO_0110` | `pfnCalcPrivateVideoExtensionCommandSize` | `PFND3D12DDI_CALCPRIVATEVIDEOEXTENSIONCOMMANDSIZE_0061` |
> | `D3D12DDI_DEVICE_FUNCS_VIDEO_0110` | `pfnCreateVideoExtensionCommand` | `PFND3D12DDI_CREATEVIDEOEXTENSIONCOMMAND_0063` |
> | `D3D12DDI_DEVICE_FUNCS_VIDEO_0110` | `pfnDestroyVideoExtensionCommand` | `PFND3D12DDI_DESTROYVIDEOEXTENSIONCOMMAND_0063` |
> | `D3D12DDI_DEVICE_FUNCS_VIDEO_0110` | `pfnExecuteDeviceVideoExtensionCommand` | `PFND3D12DDI_EXECUTEDEVICEVIDEOEXTENSIONCOMMAND_0076` |

<!-- d3d12-review-alert:end:video-extension:D229-current-extension-members:0:authored:migration-2d14df600936771c-0 -->

<a id="extension-ddi-behavior"></a>

### Driver behavior and payload responsibilities

#### D3D12DDI_VIDEO_EXTENSION_COMMAND_COUNT_DATA_0063

Retrieves the number of supported video extension commands.

##### Members

`[in] NodeIndex`

<ins><!-- d3d12-review-inline:begin:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_count_data_0063:3 -->Zero-based physical node index, not a bit mask.<!-- d3d12-review-inline:end:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_count_data_0063:3 --></ins>

`[out] CommandCount`

The number of video extension commands supported.

#### D3D12DDI_VIDEO_EXTENSION_COMMAND_INFO_0063

Describes an extension.

##### Members

`CommandId`

The unique identifier for the video extension command.

`Name`

Pointer to a wide string<ins><!-- d3d12-review-inline:begin:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_info_0063:5:modified:source-d1184def547dbcaf-0-0 --> that the<!-- d3d12-review-inline:end:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_info_0063:5:modified:source-d1184def547dbcaf-0-0 --></ins> driver allocates and <ins><!-- d3d12-review-inline:begin:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_info_0063:5:modified:source-d1184def547dbcaf-0-1 -->keeps<!-- d3d12-review-inline:end:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_info_0063:5:modified:source-d1184def547dbcaf-0-1 --></ins> for the lifetime of the device.

`CommandQueueFlags`

Indicates the Video Command Queue that the video extension targets. Only one of the following bits may be set:

- D3D12DDI\_COMMAND\_QUEUE\_FLAG\_0022\_VIDEO\_DECODE
- D3D12DDI\_COMMAND\_QUEUE\_FLAG\_0022\_VIDEO\_PROCESS
- D3D12DDI\_COMMAND\_QUEUE\_FLAG\_0053\_VIDEO\_ENCODE

#### D3D12DDI_VIDEO_EXTENSION_COMMANDS_DATA_0063

<ins><!-- d3d12-review-inline:begin:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_commands_data_0063:0 -->Retrieves the array of video extension command info for a node.<!-- d3d12-review-inline:end:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_commands_data_0063:0 --></ins>

##### Members

`[in] NodeIndex`

<ins><!-- d3d12-review-inline:begin:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_commands_data_0063:3 -->Zero-based physical node index, not a bit mask.<!-- d3d12-review-inline:end:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_commands_data_0063:3 --></ins>

`[in] CommandCount`

<ins><!-- d3d12-review-inline:begin:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_commands_data_0063:5 -->The number of video extension commands supported. This count must match the **CommandCount** returned by [D3D12DDI_VIDEO_EXTENSION_COMMAND_COUNT_DATA_0063](#d3d12ddi-video-extension-command-count-data-0063).<!-- d3d12-review-inline:end:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_commands_data_0063:5 --></ins>

`[out] pCommandInfos`

An array allocated by the runtime for the driver to fill with command info. **CommandCount** indicates the number of array elements.

#### D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_COUNT_DATA_0063

Retrieves the number of parameters for a parameter stage.

##### Members

`[in] CommandId`

The unique identifier for the video extension command.

`[in] Stage`

The parameter stage to query.

`[out] ParameterCount`

The number of parameters in the stage parameter structure.

`[out] ParameterPacking`

Indicates struct member packing.

#### D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_INFO_0063

<ins><!-- d3d12-review-inline:begin:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_parameter_info_0063:0 -->Describes a video extension command parameter.<!-- d3d12-review-inline:end:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_parameter_info_0063:0 --></ins>

##### Members

`Name`

Pointer to a wide string name of the parameter. The driver allocates <ins><!-- d3d12-review-inline:begin:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_parameter_info_0063:3:modified:source-43ae22ccdea4b98e-0-0 -->the string and keeps it<!-- d3d12-review-inline:end:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_parameter_info_0063:3:modified:source-43ae22ccdea4b98e-0-0 --></ins> for the lifetime of the device.

`Type`

<ins><!-- d3d12-review-inline:begin:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_parameter_info_0063:5 -->The parameter type. See [D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE](#d3d12ddi-video-extension-command-parameter-type-0063).<!-- d3d12-review-inline:end:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_parameter_info_0063:5 --></ins>

`Flags`

<ins><!-- d3d12-review-inline:begin:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_parameter_info_0063:7 -->Parameter flags. See [D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAGS](#d3d12ddi-video-extension-command-parameter-flags-0063).<!-- d3d12-review-inline:end:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_parameter_info_0063:7 --></ins>

#### D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETERS_DATA_0063

Retrieves the array of parameter info for a parameter stage.

##### Members

`[in] CommandId`

The unique identifier for the video extension command.

`[in] Stage`

The parameter stage to query.

`[in] ParameterCount`

<ins><!-- d3d12-review-inline:begin:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_parameters_data_0063:7 -->This must match the **ParameterCount** returned by the [D3D12DDICAPS_TYPE_VIDEO_0063_EXTENSION_COMMAND_PARAMETER_COUNT](#d3d12ddi-video-extension-command-parameter-count-data-0063) query.<!-- d3d12-review-inline:end:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_parameters_data_0063:7 --></ins>

`[out] pParameterInfos`

An array allocated by the runtime for the driver to fill with parameter info. **ParameterCount** indicates the number of array elements.

#### D3D12DDI_VIDEO_EXTENSION_COMMAND_CAPS_DATA_0063

<ins><!-- d3d12-review-inline:begin:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_caps_data_0063:0 -->D3D12DDI\_VIDEO\_EXTENSION\_COMMAND\_CAPS\_DATA is the data structure used in the query for video extension command capabilities. Input and output structures are defined by the particular video command extension. These structures may only be used for querying capabilities and only support plain old data (POD) data types.<!-- d3d12-review-inline:end:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_caps_data_0063:0 --></ins>

##### Members

`[in] NodeIndex`

<ins><!-- d3d12-review-inline:begin:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_caps_data_0063:3 -->Zero-based physical node index, not a bit mask.<!-- d3d12-review-inline:end:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_caps_data_0063:3 --></ins>

`[in] CommandId`

The unique identifier for the video extension command.

`[in] pInputData`

<ins><!-- d3d12-review-inline:begin:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_caps_data_0063:7 -->Input data for the capability query allocated by the caller with a size of **InputDataSizeInBytes**. This struct is enumerable as the **D3D12DDI\_VIDEO\_EXTENSION\_COMMAND\_PARAMETER\_STAGE\_0063\_CAPS\_INPUT** parameter stage of the [D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_0063](#d3d12ddi-video-extension-command-parameter-stage-0063) enumeration.<!-- d3d12-review-inline:end:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_caps_data_0063:7 --></ins>

`[in] InputDataSizeInBytes`

The byte size of the input data allocation.

`[out] pOutputData`

<ins><!-- d3d12-review-inline:begin:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_caps_data_0063:11 -->Output data for the capability query allocated by the caller with a size of OutputDataSizeInBytes. This struct is enumerable as the **D3D12DDI\_VIDEO\_EXTENSION\_COMMAND\_PARAMETER\_STAGE\_0063\_CAPS\_OUTPUT** parameter stage of the [D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_0063](#d3d12ddi-video-extension-command-parameter-stage-0063) enumeration.<!-- d3d12-review-inline:end:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_caps_data_0063:11 --></ins>

<ins><!-- d3d12-review-inline:begin:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_caps_data_0063:12:modified:source-cdc5a61cc29aa1d2-0-0 -->`OutputDataSizeInBytes` (input)<!-- d3d12-review-inline:end:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_caps_data_0063:12:modified:source-cdc5a61cc29aa1d2-0-0 --></ins>

The byte size of the output data allocation.

#### D3D12DDI_VIDEO_EXTENSION_COMMAND_SIZE_DATA_0063

Queries the residency size information for a video extension command.

##### Members

`[in] NodeIndex`

<ins><!-- d3d12-review-inline:begin:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_size_data_0063:3 -->Zero-based physical node index, not a bit mask.<!-- d3d12-review-inline:end:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_size_data_0063:3 --></ins>

`[in] CommandId`

The unique identifier for the video extension command.

`[in] pCreationParameters`

Pointer to the <ins><!-- d3d12-review-inline:begin:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_size_data_0063:7:modified:source-c56519914730273f-0-0 -->creation parameters structure, matching the CREATION stage<!-- d3d12-review-inline:end:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_size_data_0063:7:modified:source-c56519914730273f-0-0 --></ins>.

`[in] CreationParametersSizeInBytes`

<ins><!-- d3d12-review-inline:begin:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_size_data_0063:9 -->The size of the creation parameters structure in bytes.<!-- d3d12-review-inline:end:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_size_data_0063:9 --></ins>

`[out] MemoryPoolL0Size`

<ins><!-- d3d12-review-inline:begin:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_size_data_0063:11 -->Allocation size in L0; see the [API size payload](#d3d12-feature-data-video-extension-command-size) and [residency size qualification](#extension-qualifications).<!-- d3d12-review-inline:end:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_size_data_0063:11 --></ins>

`[out] MemoryPoolL1Size`

<ins><!-- d3d12-review-inline:begin:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_size_data_0063:13 -->Allocation size in L1; see the [API size payload](#d3d12-feature-data-video-extension-command-size) and [residency size qualification](#extension-qualifications).<!-- d3d12-review-inline:end:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_size_data_0063:13 --></ins>

##### Behavior

<ins><!-- d3d12-review-inline:begin:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_size_data_0063:15 -->Drivers must support `pfnMakeResident` and `pfnEvict` with `D3D12DDI_HVIDEOEXTENSIONCOMMAND_0063`.<!-- d3d12-review-inline:end:video-extension:D-ns-d3d12umddi-d3d12ddi_video_extension_command_size_data_0063:15 --></ins>

#### D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_0063

**D3D12DDI\_VIDEO\_EXTENSION\_COMMAND\_PARAMETER\_STAGE\_0063** specifies the parameter stages for video extension commands.

##### Constants

<!-- d3d12-review-alert:begin:video-extension:D-ne-d3d12umddi-d3d12ddi_video_extension_command_parameter_stage_0063:2 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Constant | Value | Meaning |
> |---|---|---|
> | `D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_0063_CREATION` | 0 | The parameter stage is in video extension command creation. |
> | `D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_0063_INITIALIZATION` | 1 | The parameter stage is in video extension command initialization. |
> | `D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_0063_EXECUTION` | 2 | The parameter stage is in video extension command execution. |
> | `D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_0063_CAPS_INPUT` | 3 | The parameter stage is input parameters passed to capabilities queries. |
> | `D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_0063_CAPS_OUTPUT` | 4 | The parameter stage is output parameters passed to capabilities queries. |
> | `D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_0076_DEVICE_EXECUTE_INPUT` | 5 | The parameter stage is device execution input. |
> | `D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_0076_DEVICE_EXECUTE_OUTPUT` | 6 | The parameter stage is device execution output. |

<!-- d3d12-review-alert:end:video-extension:D-ne-d3d12umddi-d3d12ddi_video_extension_command_parameter_stage_0063:2 -->

##### Behavior

Video Extensions support different parameterization at creation, initialization, and execution. Values from this enumeration are used when querying for video extension parameter information.

#### D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063

Parameter types are used to enumerate the members of each parameter stage parameter structure. The types supported are fixed, and additional parameter types require changes in order to be supported.

##### Constants

<!-- d3d12-review-alert:begin:video-extension:D-ne-d3d12umddi-d3d12ddi_video_extension_command_parameter_type_0063:2 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Constant | Meaning |
> |---|---|
> | `D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063_UINT8` | Unsigned 8-bit integer. |
> | `D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063_UINT16` | Unsigned 16-bit integer. |
> | `D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063_UINT32` | Unsigned 32-bit integer. |
> | `D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063_UINT64` | Unsigned 64-bit integer. |
> | `D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063_SINT8` | Signed 8-bit integer. |
> | `D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063_SINT16` | Signed 16-bit integer. |
> | `D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063_SINT32` | Signed 32-bit integer. |
> | `D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063_SINT64` | Signed 64-bit integer. |
> | `D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063_FLOAT` | IEEE 32-bit floating point number. |
> | `D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063_DOUBLE` | IEEE 64-bit floating point number. |
> | `D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063_RESOURCE` | A D3D12DDI\_HRESOURCE handle. See the resource state table below. |
> | `D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_TYPE_0063_MAX_VALID` | One past the last supported parameter type; a sentinel, not a parameter type. |

<!-- d3d12-review-alert:end:video-extension:D-ne-d3d12umddi-d3d12ddi_video_extension_command_parameter_type_0063:2 -->

##### Behavior

When the **D3D12DDI\_VIDEO\_EXTENSION\_COMMAND\_PARAMETER\_TYPE\_0063\_RESOURCE** value is specified, the caller must use resource barriers to transition to the state appropriate for the parameter:

<!-- d3d12-review-alert:begin:video-extension:D-ne-d3d12umddi-d3d12ddi_video_extension_command_parameter_type_0063:5:modified:migration-0031e511e07daa28-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Command queue family | Read | Write |
> | --- | --- | --- |
> | `D3D12DDI_COMMAND_QUEUE_FLAG_0022_VIDEO_DECODE` | `D3D12DDI_RESOURCE_STATE_0020_VIDEO_DECODE_READ` | `D3D12DDI_RESOURCE_STATE_0020_VIDEO_DECODE_WRITE` |
> | `D3D12DDI_COMMAND_QUEUE_FLAG_0022_VIDEO_PROCESS` | `D3D12DDI_RESOURCE_STATE_0020_VIDEO_PROCESS_READ` | `D3D12DDI_RESOURCE_STATE_0020_VIDEO_PROCESS_WRITE` |
> | `D3D12DDI_COMMAND_QUEUE_FLAG_0053_VIDEO_ENCODE` | `D3D12DDI_RESOURCE_STATE_0060_VIDEO_ENCODE_READ` | `D3D12DDI_RESOURCE_STATE_0060_VIDEO_ENCODE_WRITE` |

<!-- d3d12-review-alert:end:video-extension:D-ne-d3d12umddi-d3d12ddi_video_extension_command_parameter_type_0063:5:modified:migration-0031e511e07daa28-0 -->

#### D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAGS_0063

Video Extensions must specify a command parameter flag.

##### Constants

<!-- d3d12-review-alert:begin:video-extension:D-ne-d3d12umddi-d3d12ddi_video_extension_command_parameter_flags_0063:2:modified:migration-e776ed6faba6121e-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Constant | Meaning |
> |---|---|
> | `D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAG_0063_NONE` | Set for plain old data (POD) parameters. |
> | `D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAG_0063_READ` | Indicates that a GPU resource is read. Not valid for POD parameters. |
> | `D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAG_0063_WRITE` | Indicates that a GPU resource is written. Not valid for POD parameters. |
> | `D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_FLAG_0063_MASK` | Indicates read/write. |

<!-- d3d12-review-alert:end:video-extension:D-ne-d3d12umddi-d3d12ddi_video_extension_command_parameter_flags_0063:2:modified:migration-e776ed6faba6121e-0 -->

#### PFND3D12DDI_CALCPRIVATEVIDEOEXTENSIONCOMMANDSIZE_0061

<ins><!-- d3d12-review-inline:begin:video-extension:D-nc-d3d12umddi-pfnd3d12ddi_calcprivatevideoextensioncommandsize_0061:0 -->Returns the driver object size for the video extension command. Direct3D runtime allocates space for this driver object. On creation, the driver places the object into the allocation that was provided by the runtime.<!-- d3d12-review-inline:end:video-extension:D-nc-d3d12umddi-pfnd3d12ddi_calcprivatevideoextensioncommandsize_0061:0 --></ins>

##### Parameters

`hDrvDevice`

Handle for the D3D12 device.

`pArgs`

<ins><!-- d3d12-review-inline:begin:video-extension:D-nc-d3d12umddi-pfnd3d12ddi_calcprivatevideoextensioncommandsize_0061:5 -->Pointer to a [D3D12DDIARG_CREATE_VIDEO_EXTENSION_COMMAND_0063](#d3d12ddiarg-create-video-extension-command-0063) structure.<!-- d3d12-review-inline:end:video-extension:D-nc-d3d12umddi-pfnd3d12ddi_calcprivatevideoextensioncommandsize_0061:5 --></ins>

##### Return values

Returns SIZE\_T.

#### PFND3D12DDI_CREATEVIDEOEXTENSIONCOMMAND_0063

Creates a video extension command. All significant internal resource allocations used by the extension command should be created during video extension creation.

##### Parameters

`hDrvDevice`

Handle for the Direct3D 12 device.

`pArgs`

<ins><!-- d3d12-review-inline:begin:video-extension:D-nc-d3d12umddi-pfnd3d12ddi_createvideoextensioncommand_0063:5 -->Pointer to a [D3D12DDIARG_CREATE_VIDEO_EXTENSION_COMMAND_0063](#d3d12ddiarg-create-video-extension-command-0063) structure that contains arguments.<!-- d3d12-review-inline:end:video-extension:D-nc-d3d12umddi-pfnd3d12ddi_createvideoextensioncommand_0063:5 --></ins>

`hDrvVideoExtensionCommand`

A handle to a video extension command D3D12DDI\_HVIDEOEXTENSIONCOMMAND\_0063.

##### Return values

Returns HRESULT.

#### PFND3D12DDI_DESTROYVIDEOEXTENSIONCOMMAND_0063

Destroys the video extension command.

##### Parameters

`hDrvDevice`

Handle for the Direct3D 12 device.

`hDrvVideoExtensionCommand`

Handle to the D3D12DDI\_HVIDEOEXTENSIONCOMMAND\_0063 to be destroyed.

##### Return values

None

#### PFND3D12DDI_INITIALIZE_VIDEO_EXTENSION_COMMAND_0063

Records a command to initialize or re-initialize a Video Extension Command into a command list.

##### Parameters

`hDrvCommandList`

Handle for the command list.

`hDrvVideoExtensionCommand`

Handle to the video extension command to initialize.

`pInitializationParameters`

<ins><!-- d3d12-review-inline:begin:video-extension:D-nc-d3d12umddi-pfnd3d12ddi_initialize_video_extension_command_0063:7 -->Pointer to the initialization parameters structure. Parameters for this structure must match the parameter enumeration for [D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_0063_INITIALIZATION](#d3d12ddi-video-extension-command-parameter-stage-0063).<!-- d3d12-review-inline:end:video-extension:D-nc-d3d12umddi-pfnd3d12ddi_initialize_video_extension_command_0063:7 --></ins>

`InitializationParametersSizeInBytes`

The size of the initialization parameters structure in bytes.

##### Return values

The following error codes are allowed:

| Return value | Description |
| --- | --- |
| S\_OK | Initialization succeeded. |
| D3DDDIERR\_APPLICATIONERROR | The caller has attempted to initialize the command incorrectly. For example, provided an invalid argument. This error puts the command list in error and an error code is returned from the Close method on the API command list. |
| D3DDDIERR\_DEVICEREMOVED | Cannot initialize the command because the device is in a device removed state. If the runtime has not already realized that the device was removed, this will set the device and command list in error. |

#### PFND3D12DDI_EXECUTE_VIDEO_EXTENSION_COMMAND_0063

Records a command to execute a video extension command into a command list.

##### Parameters

`hDrvCommandList`

Handle for the command list.

`hDrvVideoExtensionCommand`

Handle to the video extension command to <ins><!-- d3d12-review-inline:begin:video-extension:D-nc-d3d12umddi-pfnd3d12ddi_execute_video_extension_command_0063:5:modified:source-774d3c5ca63b2afa-0-0 -->execute<!-- d3d12-review-inline:end:video-extension:D-nc-d3d12umddi-pfnd3d12ddi_execute_video_extension_command_0063:5:modified:source-774d3c5ca63b2afa-0-0 --></ins>.

`pExecutionParameters`

<ins><!-- d3d12-review-inline:begin:video-extension:D-nc-d3d12umddi-pfnd3d12ddi_execute_video_extension_command_0063:7 -->Pointer to the execution parameters structure. Parameters for this structure must match the parameter enumeration for [D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_0063_EXECUTION](#d3d12ddi-video-extension-command-parameter-stage-0063).<!-- d3d12-review-inline:end:video-extension:D-nc-d3d12umddi-pfnd3d12ddi_execute_video_extension_command_0063:7 --></ins>

`ExecutionParametersSizeInBytes`

The size of the <ins><!-- d3d12-review-inline:begin:video-extension:D-nc-d3d12umddi-pfnd3d12ddi_execute_video_extension_command_0063:9:modified:source-1a19353059e3da3e-0-0 -->execution<!-- d3d12-review-inline:end:video-extension:D-nc-d3d12umddi-pfnd3d12ddi_execute_video_extension_command_0063:9:modified:source-1a19353059e3da3e-0-0 --></ins> parameters structure in bytes.

##### Return values

The following error codes are allowed:

<!-- d3d12-review-alert:begin:video-extension:D-nc-d3d12umddi-pfnd3d12ddi_execute_video_extension_command_0063:12:modified:migration-990275c41bef8569-0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Return value | Description |
> | --- | --- |
> | S\_OK | Execution succeeded. |
> | D3DDDIERR\_APPLICATIONERROR | The caller has attempted to execute the command incorrectly. For example, provided an invalid argument. This error puts the command list in error and an error code is returned from the Close method on the API command list. |
> | D3DDDIERR\_DEVICEREMOVED | Cannot execute the command because the device is in a device removed state. If the runtime has not already realized that the device was removed, this will set the device and command list in error. |

<!-- d3d12-review-alert:end:video-extension:D-nc-d3d12umddi-pfnd3d12ddi_execute_video_extension_command_0063:12:modified:migration-990275c41bef8569-0 -->

#### D3D12DDIARG_CREATE_VIDEO_EXTENSION_COMMAND_0063

Contains arguments used to create a video extension command.

##### Members

`[in] NodeMask`

<ins><!-- d3d12-review-inline:begin:video-extension:D-ns-d3d12umddi-d3d12ddiarg_create_video_extension_command_0063:3 -->For single GPU operation, set this to zero. If there are multiple GPU nodes, set a bit to identify the node (the device's physical adapter) to which the video extension command object applies. Each bit in the mask corresponds to a single node. Only 1 bit may be set.<!-- d3d12-review-inline:end:video-extension:D-ns-d3d12umddi-d3d12ddiarg_create_video_extension_command_0063:3 --></ins>

`[in] CommandId`

The unique identifier for the video extension command.

`[in] pCreationParameters`

<ins><!-- d3d12-review-inline:begin:video-extension:D-ns-d3d12umddi-d3d12ddiarg_create_video_extension_command_0063:7 -->Pointer to the creation parameters structure. Parameters for this structure must match the parameter enumeration for [D3D12DDI_VIDEO_EXTENSION_COMMAND_PARAMETER_STAGE_0063_CREATION](#d3d12ddi-video-extension-command-parameter-stage-0063).<!-- d3d12-review-inline:end:video-extension:D-ns-d3d12umddi-d3d12ddiarg_create_video_extension_command_0063:7 --></ins>

`CreationParametersDataSizeInBytes`

The size of the creation parameters structure in bytes.

`hDrvProtectedResourceSession`

<ins><!-- d3d12-review-inline:begin:video-extension:D-ns-d3d12umddi-d3d12ddiarg_create_video_extension_command_0063:11 -->Handle to the D3D12DDI\_HPROTECTEDRESOURCESESSION\_0030. The extension object's driver storage is allocated according to `PFND3D12DDI_CALCPRIVATEVIDEOEXTENSIONCOMMANDSIZE_0061`; this is not allocation of the session handle.<!-- d3d12-review-inline:end:video-extension:D-ns-d3d12umddi-d3d12ddiarg_create_video_extension_command_0063:11 --></ins>

<a id="extension-qualifications"></a>

<a id="qualifications-and-validation-limits"></a>

### API/DDI description corrections

<ins><!-- d3d12-review-inline:begin:video-extension:N-qualifications:0:authored:migration-a28fba275d569ae2-0 -->Device CPU execution consumes DEVICE_EXECUTE_INPUT and produces DEVICE_EXECUTE_OUTPUT. `OutputDataSizeInBytes` is the input capacity of the output allocation. CPU execution completes before returning.<!-- d3d12-review-inline:end:video-extension:N-qualifications:0:authored:migration-a28fba275d569ae2-0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-extension:N-qualifications:1:authored:migration-5696bdaa7089d0d8-0 -->The residency size query takes creation parameters and reports L0 system memory and L1 discrete video memory. The published DDI prose that names initialization parameters and reverses the pools is incorrect.<!-- d3d12-review-inline:end:video-extension:N-qualifications:1:authored:migration-5696bdaa7089d0d8-0 --></ins>
