# Diagnostics

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

<!-- d3d12-review-alert:begin:diagnostics:chapter-introduction:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Device-removal status, Device Removed Extended Data (DRED), debug-controller configuration, object names and debug messages provide complementary diagnostic information. A removal reason is an observed status, not proof that a particular application operation caused the GPU fault.

<!-- d3d12-review-alert:end:diagnostics:chapter-introduction:0 -->

<!-- d3d12-review-alert:begin:diagnostics:chapter-introduction:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> [Execution](execution.md#completion-lifetime) defines completion, removal notification and the lifetime of submitted work. [Devices and capabilities](devices-and-capabilities.md#d3d12createdevice) defines singleton recovery and independent creation; its [factory configuration](devices-and-capabilities.md#id3d12devicefactory-getconfigurationinterface) contract defines SDK selection and configuration snapshots.

<!-- d3d12-review-alert:end:diagnostics:chapter-introduction:1 -->

<a id="device-removal"></a>

## Device-removal status

<a id="id3d12device-getdeviceremovedreason"></a>

### ID3D12Device::GetDeviceRemovedReason

#### Declaration

```cpp
HRESULT GetDeviceRemovedReason();
```

#### Behavior

<!-- d3d12-review-alert:begin:diagnostics:ID3D12Device-GetDeviceRemovedReason-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Gets the reason that the device was removed, or `S_OK` if the device isn't removed.

<!-- d3d12-review-alert:end:diagnostics:ID3D12Device-GetDeviceRemovedReason-behavior:0 -->

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

This method returns the reason that the device was removed.

#### Context

<!-- d3d12-review-alert:begin:diagnostics:removed-reason-context:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The return value is the device's removal status, not a new command-submission result. A failure does not identify the exact offending GPU operation. DRED's breadcrumbs and allocation matches provide diagnostic correlations, not causal proof.

<!-- d3d12-review-alert:end:diagnostics:removed-reason-context:0 -->

<!-- d3d12-review-alert:begin:diagnostics:removed-reason-context:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Removal notification, CPU fence observations and the distinction between notification and successful completion remain defined by [Execution](execution.md#completion-lifetime). A removed device and its dependent objects are not made usable by querying this method; [device creation and recovery](devices-and-capabilities.md#d3d12createdevice) govern replacement.

<!-- d3d12-review-alert:end:diagnostics:removed-reason-context:1 -->

<a id="id3d12device5-removedevice"></a>

### ID3D12Device5::RemoveDevice

#### Declaration

```cpp
void RemoveDevice();
```

#### Behavior

<!-- d3d12-review-alert:begin:diagnostics:ID3D12Device5-RemoveDevice-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Indicates to the Direct3D 12 runtime that this device encountered a problem and can no longer be used. The method forces removal of this device; it does not intentionally remove unrelated devices on the adapter or select a new adapter. It returns no `HRESULT`.

<!-- d3d12-review-alert:end:diagnostics:ID3D12Device5-RemoveDevice-behavior:0 -->

#### Return values

None

#### Context

<!-- d3d12-review-alert:begin:diagnostics:remove-scope:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Removal wakes the removed device's monitored fence waiters. This is notification of removal, not proof that pending GPU work completed successfully. The [common removal-notification contract](execution.md#completion-lifetime) owns the `UINT64_MAX` event mechanism. The application typically does not need to call `RemoveDevice` explicitly. This method neither diagnoses the original fault nor performs recovery.

<!-- d3d12-review-alert:end:diagnostics:remove-scope:0 -->

<a id="debug-configuration"></a>

## Debug configuration

<!-- d3d12-review-alert:begin:diagnostics:configuration-scope:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The debug controller and DRED settings obtained through the global entry points configure subsequent device creation. A configuration interface obtained from a device factory belongs to that factory's configuration, not automatically to process-global state. The [factory configuration and snapshot rules](devices-and-capabilities.md#id3d12devicefactory-getconfigurationinterface) define when configuration is copied or applied. A device retains its creation snapshot.

<!-- d3d12-review-alert:end:diagnostics:configuration-scope:0 -->

<!-- d3d12-review-alert:begin:diagnostics:configuration-scope:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Interface availability does not itself establish that debug components are installed, or that the debug layer or GPU-based validation is enabled.

<!-- d3d12-review-alert:end:diagnostics:configuration-scope:1 -->

<!-- d3d12-review-alert:begin:diagnostics:configuration-scope:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A debug-controller startup-option change through a global configuration interface has the global singleton-removal scope described below. A factory-local controller change affects subsequent creation from that factory; it does not remove or retrofit already-created independent devices. Applying factory state globally is the separate [ApplyToGlobalState operation](devices-and-capabilities.md#id3d12devicefactory-applytoglobalstate).

<!-- d3d12-review-alert:end:diagnostics:configuration-scope:2 -->

<!-- d3d12-review-alert:begin:diagnostics:debug-startup-defaults:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The debug layer is disabled by default. GPU-based validation is disabled by default, synchronized-queue validation is enabled by default when using the debug layer, GPU-based-validation flags default to `D3D12_GPU_BASED_VALIDATION_FLAGS_NONE`, automatic naming is disabled by default, and forcing legacy barrier validation is disabled by default. System/tool overrides can affect the effective creation configuration.

<!-- d3d12-review-alert:end:diagnostics:debug-startup-defaults:0 -->

<!-- d3d12-review-alert:begin:diagnostics:debug-startup-defaults:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Configure these startup options before device creation; they do not retrofit a different validation mode into a device's creation snapshot. The individual enable/disable methods below specify removal and release requirements. Debug-controller retrieval can fail with `DXGI_ERROR_SDK_COMPONENT_MISSING` if the matching debug-layer component is unavailable; DRED settings and DRED data do not require the debug layer to be enabled.

<!-- d3d12-review-alert:end:diagnostics:debug-startup-defaults:1 -->

<a id="d3d12getdebuginterface"></a>

### D3D12GetDebugInterface

#### Declaration

```cpp
HRESULT D3D12GetDebugInterface(REFIID riid, void** ppvDebug);
```

#### Behavior

Gets a debug interface.

<ins><!-- d3d12-review-inline:begin:diagnostics:D3D12GetDebugInterface-summary:1 -->The [D3D12GetInterface contract](devices-and-capabilities.md#d3d12getinterface) defines direct retrieval and SDK compatibility.<!-- d3d12-review-inline:end:diagnostics:D3D12GetDebugInterface-summary:1 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:diagnostics:D3D12GetDebugInterface-Parameters:1 -->`riid` (input)<!-- d3d12-review-inline:end:diagnostics:D3D12GetDebugInterface-Parameters:1 --></ins>

Type: **REFIID**

The globally unique identifier (**GUID**) for the debug interface. The **REFIID**, or **GUID**, of the debug interface can be obtained by using the \_\_uuidof() macro. For example, \_\_uuidof([ID3D12Debug](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/nn-d3d12sdklayers-id3d12debug)) will get the **GUID** of the debug interface.

<ins><!-- d3d12-review-inline:begin:diagnostics:D3D12GetDebugInterface-Parameters:4 -->`ppvDebug` (optional output)<!-- d3d12-review-inline:end:diagnostics:D3D12GetDebugInterface-Parameters:4 --></ins>

Type: **void\*\***

The debug interface, as a pointer to pointer to void. See [ID3D12Debug](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/nn-d3d12sdklayers-id3d12debug) and [ID3D12DebugDevice](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/nn-d3d12sdklayers-id3d12debugdevice).

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

#### Context

The function signature PFN\_D3D12\_GET\_DEBUG\_INTERFACE is provided as a typedef, so that you can use dynamic linking techniques ([GetProcAddress](https://learn.microsoft.com/en-us/windows/desktop/api/libloaderapi/nf-libloaderapi-getprocaddress)) instead of statically linking.

#### Examples

Enable the D3D12 debug layer.

```cpp
// Enable the D3D12 debug layer.
{

    ComPtr<ID3D12Debug> debugController;
    if (SUCCEEDED(D3D12GetDebugInterface(IID_PPV_ARGS(&debugController))))
    {
        debugController->EnableDebugLayer();
    }
}

```

Refer to the [Example Code in the D3D12 Reference](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/notes-on-example-code).

<a id="id3d12debug-enabledebuglayer"></a>

### ID3D12Debug::EnableDebugLayer

#### Declaration

```cpp
void EnableDebugLayer();
```

#### Behavior

Enables the debug layer.

#### Return values

None

#### Context

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12Debug-EnableDebugLayer-Remarks:1 -->Configure the debug layer before creating the device that will use it. Changing a global controller's debug-layer startup setting after creation removes the affected global singleton devices. Changing a factory-local controller configures subsequent factory creation and does not remove existing independent devices or attach the layer to those devices.<!-- d3d12-review-inline:end:diagnostics:ID3D12Debug-EnableDebugLayer-Remarks:1 --></ins>

#### Examples

Enable the D3D12 debug layer.

```cpp
// Enable the D3D12 debug layer.
{
    ComPtr<ID3D12Debug> debugController;
    if (SUCCEEDED(D3D12GetDebugInterface(IID_PPV_ARGS(&debugController))))
    {
        debugController->EnableDebugLayer();
    }
}
```

Refer to the [Example Code in the D3D12 Reference](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/notes-on-example-code).

<a id="id3d12debug1-enabledebuglayer"></a>

### ID3D12Debug1::EnableDebugLayer

#### Declaration

```cpp
void EnableDebugLayer();
```

#### Behavior

Enables the debug layer.

#### Return values

None

#### Context

This method is identical to [ID3D12Debug::EnableDebugLayer](#id3d12debug-enabledebuglayer).

<a id="id3d12debug1-setenablegpubasedvalidation"></a>

### ID3D12Debug1::SetEnableGPUBasedValidation

#### Declaration

```cpp
void SetEnableGPUBasedValidation(BOOL Enable);
```

#### Behavior

This method enables or disables GPU-Based Validation (GBV) before creating a device with the debug layer enabled.

#### Parameters

`Enable`

Type: **BOOL**

TRUE to enable GPU-Based Validation, otherwise FALSE.

#### Return values

None

#### Context

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12Debug1-SetEnableGPUBasedValidation-Remarks:1 -->GPU-based validation is a device-creation option and is disabled by default. An existing device keeps its creation-time validation mode; using a different mode requires a device created with that mode. Changing the global GPU-based-validation startup setting removes affected global singleton devices. A factory-local controller change affects subsequent factory creation and does not remove or reconfigure existing independent devices.<!-- d3d12-review-inline:end:diagnostics:ID3D12Debug1-SetEnableGPUBasedValidation-Remarks:1 --></ins>

For more information, see [Using D3D12 Debug Layer GPU-Based Validation](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/using-d3d12-debug-layer-gpu-based-validation).

<a id="id3d12debug1-setenablesynchronizedcommandqueuevalidation"></a>

### ID3D12Debug1::SetEnableSynchronizedCommandQueueValidation

#### Declaration

```cpp
void SetEnableSynchronizedCommandQueueValidation(BOOL Enable);
```

#### Behavior

Enables or disables dependent command queue synchronization when using a D3D12 device with the debug layer enabled.

#### Parameters

`Enable`

Type: **BOOL**

TRUE to enable Dependent Command Queue Synchronization, otherwise FALSE.

#### Return values

None

#### Context

Dependent Command Queue Synchronization is a D3D12 Debug Layer feature that gives the debug layer the ability to track resource states more accurately when enabled. Dependent Command Queue Synchronization is enabled by default.

When Dependent Command Queue Synchronization is enabled, the debug layer holds back actual submission of GPU work until all outstanding fence [Wait](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nf-d3d12-id3d12commandqueue-wait) conditions are met. This gives the debug layer the ability to make reasonable assumptions about GPU state (such as resource states) on the CPU-timeline when multiple command queues are potentially doing concurrent work.

With Dependent Command Queue Synchronization disabled, all resource states tracked by the debug layer are cleared each time [ID3D12CommandQueue::Signal](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nf-d3d12-id3d12commandqueue-signal) is called. This results in significantly less useful resource state validation.

Disabling Dependent Command Queue Synchronization may reduce some debug layer performance overhead when using multiple command queues. However, it is suggested to leave it enabled unless this overhead is problematic. Note that applications that use only a single command queue will see no performance changes with Dependent Command Queue Synchronization disabled.

<a id="id3d12debug2-setgpubasedvalidationflags"></a>

### ID3D12Debug2::SetGPUBasedValidationFlags

#### Declaration

```cpp
void SetGPUBasedValidationFlags(D3D12_GPU_BASED_VALIDATION_FLAGS Flags);
```

#### Behavior

This method configures the level of GPU-based validation that the debug device is to perform at runtime.

#### Parameters

`Flags`

Type: **[D3D12_GPU_BASED_VALIDATION_FLAGS](https://learn.microsoft.com/en-us/windows/win32/api/d3d12sdklayers/ne-d3d12sdklayers-d3d12_gpu_based_validation_flags)**

Specifies the level of GPU-based validation to perform at runtime.

#### Return values

None

#### Context

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12Debug2-SetGPUBasedValidationFlags-Remarks:1 -->This method overrides the default behavior of GPU-based validation for devices subsequently created from the controller's configuration. These settings do not change the creation snapshot of an existing device. To use different validation flags, create a device with those flags; a factory-local change does not remove previously created independent devices. Global startup-option changes retain the global singleton-removal scope.<!-- d3d12-review-inline:end:diagnostics:ID3D12Debug2-SetGPUBasedValidationFlags-Remarks:1 --></ins>

<a id="id3d12debug3-setenablegpubasedvalidation"></a>

### ID3D12Debug3::SetEnableGPUBasedValidation

#### Declaration

```cpp
void SetEnableGPUBasedValidation(BOOL Enable);
```

#### Behavior

This method enables or disables GPU-based validation (GBV) before creating a device with the debug layer enabled.

#### Parameters

`Enable`

Type: **BOOL**

TRUE to enable GPU-based validation, otherwise FALSE.

#### Return values

None

#### Context

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12Debug3-SetEnableGPUBasedValidation-Remarks:1 -->GPU-based validation is a device-creation option and is disabled by default. An existing device keeps its creation-time validation mode; using a different mode requires a device created with that mode. Changing the global GPU-based-validation startup setting removes affected global singleton devices. A factory-local controller change affects subsequent factory creation and does not remove or reconfigure existing independent devices.<!-- d3d12-review-inline:end:diagnostics:ID3D12Debug3-SetEnableGPUBasedValidation-Remarks:1 --></ins>

For more information, see [Using D3D12 Debug Layer GPU-based validation](https://learn.microsoft.com/en-us/windows/win32/direct3d12/using-d3d12-debug-layer-gpu-based-validation).

<a id="id3d12debug3-setenablesynchronizedcommandqueuevalidation"></a>

### ID3D12Debug3::SetEnableSynchronizedCommandQueueValidation

#### Declaration

```cpp
void SetEnableSynchronizedCommandQueueValidation(BOOL Enable);
```

#### Behavior

Enables or disables dependent command queue synchronization when using a Direct3D 12 device with the debug layer enabled.

#### Parameters

`Enable`

Type: **BOOL**

TRUE to enable Dependent Command Queue Synchronization, otherwise FALSE.

#### Return values

None

#### Context

Dependent Command Queue Synchronization is a D3D12 Debug Layer feature that gives the debug layer the ability to track resource states more accurately when enabled. Dependent Command Queue Synchronization is enabled by default.

When Dependent Command Queue Synchronization is enabled, the debug layer holds back actual submission of GPU work until all outstanding fence [Wait](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nf-d3d12-id3d12commandqueue-wait) conditions are met. This gives the debug layer the ability to make reasonable assumptions about GPU state (such as resource states) on the CPU-timeline when multiple command queues are potentially doing concurrent work.

With Dependent Command Queue Synchronization disabled, all resource states tracked by the debug layer are cleared each time [ID3D12CommandQueue::Signal](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nf-d3d12-id3d12commandqueue-signal) is called. This results in significantly less useful resource state validation.

Disabling Dependent Command Queue Synchronization may reduce some debug layer performance overhead when using multiple command queues. However, it is suggested to leave it enabled unless this overhead is problematic. Note that applications that use only a single command queue will see no performance changes with Dependent Command Queue Synchronization disabled.

<a id="id3d12debug3-setgpubasedvalidationflags"></a>

### ID3D12Debug3::SetGPUBasedValidationFlags

#### Declaration

```cpp
void SetGPUBasedValidationFlags(D3D12_GPU_BASED_VALIDATION_FLAGS Flags);
```

#### Behavior

This method configures the level of GPU-based validation that the debug device is to perform at runtime.

#### Parameters

`Flags`

Type: **[D3D12_GPU_BASED_VALIDATION_FLAGS](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/ne-d3d12sdklayers-d3d12_gpu_based_validation_flags)**

Specifies the level of GPU-based validation to perform at runtime.

#### Return values

None

#### Context

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12Debug3-SetGPUBasedValidationFlags-Remarks:1 -->This method overrides the default behavior of GPU-based validation for devices subsequently created from the controller's configuration. These settings do not change the creation snapshot of an existing device. To use different validation flags, create a device with those flags; a factory-local change does not remove previously created independent devices. Global startup-option changes retain the global singleton-removal scope.<!-- d3d12-review-inline:end:diagnostics:ID3D12Debug3-SetGPUBasedValidationFlags-Remarks:1 --></ins>

<a id="id3d12debug4-disabledebuglayer"></a>

### ID3D12Debug4::DisableDebugLayer

#### Declaration

```cpp
void DisableDebugLayer();
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12Debug4-DisableDebugLayer-summary:0 -->Disables the debug layer in the controller's device-creation configuration. An existing device's debug layer is not detached by changing the setting. Global creation follows the affected singleton-removal and release/recreation rules of [D3D12CreateDevice](devices-and-capabilities.md#d3d12createdevice). A factory-local change affects subsequent factory creation and does not remove already-created independent devices.<!-- d3d12-review-inline:end:diagnostics:ID3D12Debug4-DisableDebugLayer-summary:0 --></ins>

#### Return values

None

<a id="id3d12debug5-setenableautoname"></a>

### ID3D12Debug5::SetEnableAutoName

#### Declaration

```cpp
void SetEnableAutoName(BOOL Enable);
```

#### Behavior

<!-- d3d12-review-alert:begin:diagnostics:auto-name-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Enables or disables Debug Object Auto-Naming.

<!-- d3d12-review-alert:end:diagnostics:auto-name-behavior:0 -->

#### Parameters

| Parameter   | Description                                         |
|-------------|-----------------------------------------------------|
| BOOL Enable | Set to TRUE to enable auto-naming, FALSE to disable |

#### Return values

void

#### Context

When Auto-Naming is enabled, the D3D12 runtime composes a descriptive name for many D3D object types that are reported in debug and DRED output.  These names are only reported in debug output when the object is unnamed at the time the debug output is generated.

Auto-Naming is disabled by default.

It is still strongly recommended that developers assign meaningful debug object names to API objects whenever possible.  Auto-names are not guaranteed to be unique identifiers.

Note that an auto-name is generated for every nameable D3D12 object when auto-naming is enabled.  Therefore, it may not be ideal to enable Auto-Naming in some retail applications.

The auto-name is internal-only.  By design, there is no programmatic way to get the auto-generated name.  This allows auto-names to evolve over time without risking regressions in apps that would otherwise depend on the name string.

<ins><!-- d3d12-review-inline:begin:diagnostics:auto-name-context:6 -->Auto-Naming can be controlled using [d3dconfig.exe](https://devblogs.microsoft.com/directx/d3dconfig-a-new-tool-to-manage-directx-control-panel-settings/).<!-- d3d12-review-inline:end:diagnostics:auto-name-context:6 --></ins>

<a id="id3d12debug6-setforcelegacybarriervalidation"></a>

### ID3D12Debug6::SetForceLegacyBarrierValidation

#### Declaration

```cpp
void SetForceLegacyBarrierValidation(BOOL Enable);
```

#### Behavior

<!-- d3d12-review-alert:begin:diagnostics:ID3D12Debug6-SetForceLegacyBarrierValidation-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Controls whether the debug layer uses legacy resource-state validation for legacy barriers. `Enable` is `TRUE` to force the legacy validation path, or `FALSE` to use the default path.

<!-- d3d12-review-alert:end:diagnostics:ID3D12Debug6-SetForceLegacyBarrierValidation-behavior:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:legacy-validation-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `Enable` is an input `BOOL`. The default is `FALSE`; configure this startup option before creating the device. It changes diagnostic validation, not the [legacy or enhanced barrier execution contract](synchronization.md).

<!-- d3d12-review-alert:end:diagnostics:legacy-validation-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:legacy-validation-return:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> None.

<!-- d3d12-review-alert:end:diagnostics:legacy-validation-return:0 -->

#### Context

<!-- d3d12-review-alert:begin:diagnostics:legacy-validation-interface-availability:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method is declared by `ID3D12Debug6`. Obtaining the debug controller requires the matching SDK Layers component; interface availability does not itself enable the debug layer.

<!-- d3d12-review-alert:end:diagnostics:legacy-validation-interface-availability:0 -->

<a id="d3d12-gpu-based-validation-flags"></a>

### D3D12_GPU_BASED_VALIDATION_FLAGS

Describes the level of GPU-based validation to perform at runtime.

#### Syntax

```cpp
typedef enum D3D12_GPU_BASED_VALIDATION_FLAGS {
  D3D12_GPU_BASED_VALIDATION_FLAGS_NONE = 0,
  D3D12_GPU_BASED_VALIDATION_FLAGS_DISABLE_STATE_TRACKING = 0x1
} D3D12_GPU_BASED_VALIDATION_FLAGS;
```

#### Constants

<!-- d3d12-review-alert:begin:diagnostics:D3D12-GPU-BASED-VALIDATION-FLAGS-Constants:1 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Constant and meaning |
> | --- |
> | `D3D12_GPU_BASED_VALIDATION_FLAGS_NONE` Value: *0* Default behavior; resource states, descriptors, and descriptor tables are all validated. |
> | `D3D12_GPU_BASED_VALIDATION_FLAGS_DISABLE_STATE_TRACKING` Value: *0x1* When set, GPU-based validation does not perform resource state validation which greatly reduces the performance cost of GPU-based validation. Descriptors and descriptor heaps are still validated. |

<!-- d3d12-review-alert:end:diagnostics:D3D12-GPU-BASED-VALIDATION-FLAGS-Constants:1 -->

<a id="gpu-based-validation"></a>

### GPU-based validation execution and output

#### Purpose of GPU-based validation

GPU-based validation helps to identify the following errors:

- Use of uninitialized or incompatible descriptors in a shader.
- Use of descriptors referencing deleted Resources in a shader.
- Validation of promoted resource states and resource state decay.
- Indexing beyond the end of the descriptor heap in a shader.
- Shader accesses of resources in incompatible state.
- Use of uninitialized or incompatible Samplers in a shader.

GBV works by creating patched shaders that have validation added directly to the shader. The patched shaders inspect root arguments and resources accessed during shader execution and report errors to a log buffer. GBV also injects extra operations and Dispatch calls into the application command lists to validate and track changes to resource state imposed by the command list on the GPU-timeline.

Because GBV requires the ability to execute shaders, COPY command lists are emulated by a COMPUTE command list. This may potentially change how hardware performs copies though the end result should not be changed. The application will still perceive these are COPY command lists and the debug layer will validate them as such.

#### Debug output

GBV produces debug output after a call to [**ExecuteCommandLists**](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nf-d3d12-id3d12commandqueue-executecommandlists) completes execution on the GPU. Since this is on the GPU-timeline the debug output may be asynchronous with other CPU-timeline validation. Application developers may want to inject their own wait-after-execute to synchronize debug output.

GBV output identifies where in a shader an error occurred, along with the current draw/dispatch count and identities of related objects (e.g. command list, queue, PSO, etc).

<a id="object-names"></a>

## Object names

<a id="id3d12object-setname"></a>

### ID3D12Object::SetName

#### Declaration

```cpp
HRESULT SetName(LPCWSTR Name);
```

#### Behavior

Associates a name with the device object. This name is for use in debug diagnostics and tools.

#### Parameters

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12Object-SetName-Parameters:1 -->`Name` (input)<!-- d3d12-review-inline:end:diagnostics:ID3D12Object-SetName-Parameters:1 --></ins>

Type: **LPCWSTR**

A **NULL**-terminated **UNICODE** string that contains the name to associate with the device object.

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

#### Context

This method takes UNICODE names.

Note that this is simply a convenience wrapper around [ID3D12Object::SetPrivateData](devices-and-capabilities.md#id3d12object-setprivatedata) with **WKPDID\_D3DDebugObjectNameW**. Therefore names which are set with `SetName` can be retrieved with [ID3D12Object::GetPrivateData](devices-and-capabilities.md#id3d12object-getprivatedata) with the same GUID. Additionally, D3D12 supports narrow strings for names, using the **WKPDID\_D3DDebugObjectName** GUID directly instead.

#### Ownership

<!-- d3d12-review-alert:begin:diagnostics:name-ownership:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The name is copied as object private data; the application retains ownership of the input string and does not need to keep it alive after the call. A later name replaces the prior wide name. The name does not confer ownership of the object, extend its lifetime, or uniquely identify it. The automatic diagnostic name is distinct from this application-supplied name.

<!-- d3d12-review-alert:end:diagnostics:name-ownership:0 -->

<!-- d3d12-review-alert:begin:diagnostics:name-input-validity:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `Name` must point to a readable, null-terminated UTF-16 string. A null pointer is not an empty name; an empty string consists of its terminating wide null character. The string is copied, including its terminator. Allocation of the copied name can fail with `E_OUTOFMEMORY`; the method does not return a borrowed pointer to the input.

<!-- d3d12-review-alert:end:diagnostics:name-input-validity:0 -->

<a id="command-list-annotations"></a>

## Command-list instrumentation annotations

<!-- d3d12-review-alert:begin:diagnostics:LA-context:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The declaring graphics and video interfaces below expose annotation
> support methods, not pipeline bindings or new work-dispatch commands.
> All require an open recording under the
> [common list lifecycle/error contract](execution.md#recording-lifecycle).
> Metadata remains internal; these entries do not define a public packet
> encoding or arbitrary malformed-input behavior.

<!-- d3d12-review-alert:end:diagnostics:LA-context:0 -->

<!-- d3d12-review-alert:begin:diagnostics:LA-context:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Graphics clients use the PIX event-runtime helpers. The video methods
> are internal-only support interfaces; they do not define a direct
> application encoding or a matching PIX helper overload for every
> video interface.

<!-- d3d12-review-alert:end:diagnostics:LA-context:1 -->

<!-- d3d12-review-alert:begin:diagnostics:LA-lifetime:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Metadata/payload storage is consumed or captured during the API call.
> Caller ownership is not transferred. Runtime-owned list marker data
> follows the [allocator/recording annotation lifetime](command-list-state.md#annotations):
> a fresh recording does not inherit an earlier open event region,
> device annotation mode is not reset, and resetting the list is not
> reclaiming allocator-backed annotation storage.

<!-- d3d12-review-alert:end:diagnostics:LA-lifetime:0 -->

<!-- d3d12-review-alert:begin:diagnostics:LA-lifetime:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Recording annotations does not create a fence, transition resource
> access, guarantee DRED collection or GPU completion, or select the
> memory-write ordering modes of WriteBufferImmediate.

<!-- d3d12-review-alert:end:diagnostics:LA-lifetime:1 -->

<a id="list-annotation-payload"></a>

### Internal list annotation parameters

<!-- d3d12-review-alert:begin:diagnostics:LA-payload:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `Metadata`, optional input `pData` and `Size` are internal support arguments.
> When supplied, `pData` identifies the payload bytes described by `Size`.
> `Size` describes the payload byte span, not a string or element count;
> no text terminator or ownership transfer follows. The producing
> instrumentation runtime defines the valid encoding; this reference
> does not assign application-controlled metadata tags or a new
> recoverable HRESULT protocol.

<!-- d3d12-review-alert:end:diagnostics:LA-payload:0 -->

<a id="id3d12graphicscommandlist-setmarker"></a>

### ID3D12GraphicsCommandList::SetMarker

#### Declaration

```cpp
void SetMarker(UINT Metadata, const void* pData, UINT Size);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:diagnostics:LA-ID3D12GraphicsCommandList-SetMarker-behavior:0 -->To insert instrumentation markers at the current location within a D3D12 command list, use the `PIXSetMarker` function.  This is provided by the [WinPixEventRuntime](https://devblogs.microsoft.com/pix/winpixeventruntime/) NuGet package.<!-- d3d12-review-inline:end:diagnostics:LA-ID3D12GraphicsCommandList-SetMarker-behavior:0 --></ins>

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12GraphicsCommandList-SetMarker-shared:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [shared command-list annotation context](#command-list-annotations)
> and recording/allocator ownership rules apply. This is the entry declared
> by `ID3D12GraphicsCommandList`, not a separate inherited method on each derived interface.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12GraphicsCommandList-SetMarker-shared:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12GraphicsCommandList-SetMarker-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `Metadata`, `pData` and `Size` use the
> [internal list annotation parameter contract](#list-annotation-payload).
> These parameters are internal, not an application-defined public format.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12GraphicsCommandList-SetMarker-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12GraphicsCommandList-SetMarker-return:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12GraphicsCommandList-SetMarker-return:0 -->

<a id="id3d12graphicscommandlist-beginevent"></a>

### ID3D12GraphicsCommandList::BeginEvent

#### Declaration

```cpp
void BeginEvent(UINT Metadata, const void* pData, UINT Size);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:diagnostics:LA-ID3D12GraphicsCommandList-BeginEvent-behavior:0 -->To mark the start of an instrumentation region at the current location within a D3D12 command list, use the `PIXBeginEvent` function or `PIXScopedEvent` macro.  These are provided by the [WinPixEventRuntime](https://devblogs.microsoft.com/pix/winpixeventruntime/) NuGet package.<!-- d3d12-review-inline:end:diagnostics:LA-ID3D12GraphicsCommandList-BeginEvent-behavior:0 --></ins>

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12GraphicsCommandList-BeginEvent-shared:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [shared command-list annotation context](#command-list-annotations)
> and recording/allocator ownership rules apply. This is the entry declared
> by `ID3D12GraphicsCommandList`, not a separate inherited method on each derived interface.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12GraphicsCommandList-BeginEvent-shared:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12GraphicsCommandList-BeginEvent-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `Metadata`, `pData` and `Size` use the
> [internal list annotation parameter contract](#list-annotation-payload).
> These parameters are internal, not an application-defined public format.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12GraphicsCommandList-BeginEvent-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12GraphicsCommandList-BeginEvent-return:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12GraphicsCommandList-BeginEvent-return:0 -->

<a id="id3d12graphicscommandlist-endevent"></a>

### ID3D12GraphicsCommandList::EndEvent

#### Declaration

```cpp
void EndEvent();
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:diagnostics:LA-ID3D12GraphicsCommandList-EndEvent-behavior:0 -->To mark the end of an instrumentation region at the current location within a D3D12 command list, use the `PIXEndEvent` function or `PIXScopedEvent` macro.  These are provided by the [WinPixEventRuntime](https://devblogs.microsoft.com/pix/winpixeventruntime/) NuGet package.<!-- d3d12-review-inline:end:diagnostics:LA-ID3D12GraphicsCommandList-EndEvent-behavior:0 --></ins>

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12GraphicsCommandList-EndEvent-shared:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [shared command-list annotation context](#command-list-annotations)
> and recording/allocator ownership rules apply. This is the entry declared
> by `ID3D12GraphicsCommandList`, not a separate inherited method on each derived interface.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12GraphicsCommandList-EndEvent-shared:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12GraphicsCommandList-EndEvent-return:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12GraphicsCommandList-EndEvent-return:0 -->

<a id="id3d12videodecodecommandlist-setmarker"></a>

### ID3D12VideoDecodeCommandList::SetMarker

#### Declaration

```cpp
void SetMarker( UINT Metadata, const void* pData, UINT Size);
```

#### Behavior

For internal use only. Not intended to be called directly.

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12VideoDecodeCommandList-SetMarker-shared:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [shared command-list annotation context](#command-list-annotations)
> and recording/allocator ownership rules apply. This is the entry declared
> by `ID3D12VideoDecodeCommandList`, not a separate inherited method on each derived interface.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12VideoDecodeCommandList-SetMarker-shared:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12VideoDecodeCommandList-SetMarker-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `Metadata`, `pData` and `Size` use the
> [internal list annotation parameter contract](#list-annotation-payload).
> These parameters are internal, not an application-defined public format.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12VideoDecodeCommandList-SetMarker-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12VideoDecodeCommandList-SetMarker-return:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12VideoDecodeCommandList-SetMarker-return:0 -->

<a id="id3d12videodecodecommandlist-beginevent"></a>

### ID3D12VideoDecodeCommandList::BeginEvent

#### Declaration

```cpp
void BeginEvent( UINT Metadata, const void* pData, UINT Size);
```

#### Behavior

For internal use only. Not intended to be called directly.

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12VideoDecodeCommandList-BeginEvent-shared:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [shared command-list annotation context](#command-list-annotations)
> and recording/allocator ownership rules apply. This is the entry declared
> by `ID3D12VideoDecodeCommandList`, not a separate inherited method on each derived interface.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12VideoDecodeCommandList-BeginEvent-shared:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12VideoDecodeCommandList-BeginEvent-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `Metadata`, `pData` and `Size` use the
> [internal list annotation parameter contract](#list-annotation-payload).
> These parameters are internal, not an application-defined public format.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12VideoDecodeCommandList-BeginEvent-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12VideoDecodeCommandList-BeginEvent-return:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12VideoDecodeCommandList-BeginEvent-return:0 -->

<a id="id3d12videodecodecommandlist-endevent"></a>

### ID3D12VideoDecodeCommandList::EndEvent

#### Declaration

```cpp
void EndEvent();
```

#### Behavior

For internal use only. Not intended to be called directly.

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12VideoDecodeCommandList-EndEvent-shared:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [shared command-list annotation context](#command-list-annotations)
> and recording/allocator ownership rules apply. This is the entry declared
> by `ID3D12VideoDecodeCommandList`, not a separate inherited method on each derived interface.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12VideoDecodeCommandList-EndEvent-shared:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12VideoDecodeCommandList-EndEvent-return:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12VideoDecodeCommandList-EndEvent-return:0 -->

<a id="id3d12videoprocesscommandlist-setmarker"></a>

### ID3D12VideoProcessCommandList::SetMarker

#### Declaration

```cpp
void SetMarker( UINT Metadata, const void* pData, UINT Size);
```

#### Behavior

For internal use only. Not intended to be called directly.

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12VideoProcessCommandList-SetMarker-shared:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [shared command-list annotation context](#command-list-annotations)
> and recording/allocator ownership rules apply. This is the entry declared
> by `ID3D12VideoProcessCommandList`, not a separate inherited method on each derived interface.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12VideoProcessCommandList-SetMarker-shared:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12VideoProcessCommandList-SetMarker-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `Metadata`, `pData` and `Size` use the
> [internal list annotation parameter contract](#list-annotation-payload).
> These parameters are internal, not an application-defined public format.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12VideoProcessCommandList-SetMarker-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12VideoProcessCommandList-SetMarker-return:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12VideoProcessCommandList-SetMarker-return:0 -->

<a id="id3d12videoprocesscommandlist-beginevent"></a>

### ID3D12VideoProcessCommandList::BeginEvent

#### Declaration

```cpp
void BeginEvent( UINT Metadata, const void* pData, UINT Size);
```

#### Behavior

For internal use only. Not intended to be called directly.

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12VideoProcessCommandList-BeginEvent-shared:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [shared command-list annotation context](#command-list-annotations)
> and recording/allocator ownership rules apply. This is the entry declared
> by `ID3D12VideoProcessCommandList`, not a separate inherited method on each derived interface.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12VideoProcessCommandList-BeginEvent-shared:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12VideoProcessCommandList-BeginEvent-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `Metadata`, `pData` and `Size` use the
> [internal list annotation parameter contract](#list-annotation-payload).
> These parameters are internal, not an application-defined public format.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12VideoProcessCommandList-BeginEvent-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12VideoProcessCommandList-BeginEvent-return:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12VideoProcessCommandList-BeginEvent-return:0 -->

<a id="id3d12videoprocesscommandlist-endevent"></a>

### ID3D12VideoProcessCommandList::EndEvent

#### Declaration

```cpp
void EndEvent();
```

#### Behavior

For internal use only. Not intended to be called directly.

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12VideoProcessCommandList-EndEvent-shared:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [shared command-list annotation context](#command-list-annotations)
> and recording/allocator ownership rules apply. This is the entry declared
> by `ID3D12VideoProcessCommandList`, not a separate inherited method on each derived interface.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12VideoProcessCommandList-EndEvent-shared:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12VideoProcessCommandList-EndEvent-return:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12VideoProcessCommandList-EndEvent-return:0 -->

<a id="id3d12videoencodecommandlist-setmarker"></a>

### ID3D12VideoEncodeCommandList::SetMarker

#### Declaration

```cpp
void SetMarker( UINT Metadata, const void* pData, UINT Size);
```

#### Behavior

For internal use only. Not intended to be called directly.

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12VideoEncodeCommandList-SetMarker-shared:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [shared command-list annotation context](#command-list-annotations)
> and recording/allocator ownership rules apply. This is the entry declared
> by `ID3D12VideoEncodeCommandList`, not a separate inherited method on each derived interface.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12VideoEncodeCommandList-SetMarker-shared:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12VideoEncodeCommandList-SetMarker-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `Metadata`, `pData` and `Size` use the
> [internal list annotation parameter contract](#list-annotation-payload).
> These parameters are internal, not an application-defined public format.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12VideoEncodeCommandList-SetMarker-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12VideoEncodeCommandList-SetMarker-return:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12VideoEncodeCommandList-SetMarker-return:0 -->

<a id="id3d12videoencodecommandlist-beginevent"></a>

### ID3D12VideoEncodeCommandList::BeginEvent

#### Declaration

```cpp
void BeginEvent( UINT Metadata, const void* pData, UINT Size);
```

#### Behavior

For internal use only. Not intended to be called directly.

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12VideoEncodeCommandList-BeginEvent-shared:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [shared command-list annotation context](#command-list-annotations)
> and recording/allocator ownership rules apply. This is the entry declared
> by `ID3D12VideoEncodeCommandList`, not a separate inherited method on each derived interface.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12VideoEncodeCommandList-BeginEvent-shared:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12VideoEncodeCommandList-BeginEvent-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `Metadata`, `pData` and `Size` use the
> [internal list annotation parameter contract](#list-annotation-payload).
> These parameters are internal, not an application-defined public format.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12VideoEncodeCommandList-BeginEvent-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12VideoEncodeCommandList-BeginEvent-return:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12VideoEncodeCommandList-BeginEvent-return:0 -->

<a id="id3d12videoencodecommandlist-endevent"></a>

### ID3D12VideoEncodeCommandList::EndEvent

#### Declaration

```cpp
void EndEvent();
```

#### Behavior

For internal use only. Not intended to be called directly.

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12VideoEncodeCommandList-EndEvent-shared:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [shared command-list annotation context](#command-list-annotations)
> and recording/allocator ownership rules apply. This is the entry declared
> by `ID3D12VideoEncodeCommandList`, not a separate inherited method on each derived interface.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12VideoEncodeCommandList-EndEvent-shared:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:LA-ID3D12VideoEncodeCommandList-EndEvent-return:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:diagnostics:LA-ID3D12VideoEncodeCommandList-EndEvent-return:0 -->

<a id="queue-annotations"></a>

## Queue instrumentation annotations

<ins><!-- d3d12-review-inline:begin:diagnostics:QA-purpose:0 -->Not intended to be called directly.  Use the
[PIX event runtime](https://devblogs.microsoft.com/pix/winpixeventruntime/) to insert events into a command queue.<!-- d3d12-review-inline:end:diagnostics:QA-purpose:0 --></ins>

<!-- d3d12-review-alert:begin:diagnostics:QA-context:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> These methods annotate a command queue for instrumentation; they are
> distinct from command-list BeginEvent/EndEvent/SetMarker recordings.
> They do not define a GPU fence, residency operation, resource barrier or
> the memory-write modes of WriteBufferImmediate. Their VOID return is
> not a completion or capture-delivery guarantee.

<!-- d3d12-review-alert:end:diagnostics:QA-context:0 -->

<!-- d3d12-review-alert:begin:diagnostics:QA-context:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> [Synchronization-only queues](execution.md#synchronization-only-queues)
> support synchronization rather than these annotation methods; an
> unsupported annotation call is invalid usage and can invalidate the
> device. Ordinary core/video queue annotation support must not be
> inferred from a command-list DRED breadcrumb rule.

<!-- d3d12-review-alert:end:diagnostics:QA-context:1 -->

<a id="queue-annotation-payload"></a>

### Internal annotation arguments

<!-- d3d12-review-alert:begin:diagnostics:QA-payload:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `Metadata`, `pData` and `Size` are internal support arguments, not an
> application-defined public serialization format. The event runtime
> supplies the compatible metadata tag and optional input payload;
> `Size` is its byte count, not a string or element count.

<!-- d3d12-review-alert:end:diagnostics:QA-payload:0 -->

<!-- d3d12-review-alert:begin:diagnostics:QA-payload:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Payload bytes are consumed or captured during the API call; caller
> storage ownership is not transferred and need not extend to later GPU
> completion. These parameters provide no output buffer or HRESULT
> channel. No particular encoding, terminator or arbitrary malformed
> metadata behavior is defined here; use the supported event-runtime
> helpers rather than constructing raw internal packets.

<!-- d3d12-review-alert:end:diagnostics:QA-payload:1 -->

<a id="id3d12commandqueue-setmarker"></a>

### ID3D12CommandQueue::SetMarker

#### Declaration

```cpp
void SetMarker(UINT Metadata, const void* pData, UINT Size);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:diagnostics:QA-SetMarker-behavior:0 -->To insert instrumentation markers at the current location within a D3D12 command queue, use the `PIXSetMarker` function.  This is provided by the [WinPixEventRuntime](https://devblogs.microsoft.com/pix/winpixeventruntime/) NuGet package.<!-- d3d12-review-inline:end:diagnostics:QA-SetMarker-behavior:0 --></ins>

<!-- d3d12-review-alert:begin:diagnostics:QA-SetMarker-shared:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [shared queue annotation context](#queue-annotations) applies; this is
> a support method for the event runtime, not a direct application
> instrumentation interface.

<!-- d3d12-review-alert:end:diagnostics:QA-SetMarker-shared:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:QA-SetMarker-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `Metadata`, optional input `pData`, and `Size` use the
> [internal annotation argument contract](#queue-annotation-payload).
> They are all internal parameters; the helper/runtime defines their encoding.

<!-- d3d12-review-alert:end:diagnostics:QA-SetMarker-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:QA-SetMarker-return:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:diagnostics:QA-SetMarker-return:0 -->

<a id="id3d12commandqueue-beginevent"></a>

### ID3D12CommandQueue::BeginEvent

#### Declaration

```cpp
void BeginEvent(UINT Metadata, const void* pData, UINT Size);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:diagnostics:QA-BeginEvent-behavior:0 -->To mark the start of an instrumentation region at the current location within a D3D12 command queue, use the `PIXBeginEvent` function or `PIXScopedEvent` macro.  These are provided by the [WinPixEventRuntime](https://devblogs.microsoft.com/pix/winpixeventruntime/) NuGet package.<!-- d3d12-review-inline:end:diagnostics:QA-BeginEvent-behavior:0 --></ins>

<!-- d3d12-review-alert:begin:diagnostics:QA-BeginEvent-shared:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [shared queue annotation context](#queue-annotations) applies; this is
> a support method for the event runtime, not a direct application
> instrumentation interface.

<!-- d3d12-review-alert:end:diagnostics:QA-BeginEvent-shared:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:QA-BeginEvent-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `Metadata`, optional input `pData`, and `Size` use the
> [internal annotation argument contract](#queue-annotation-payload).
> They are all internal parameters; the helper/runtime defines their encoding.

<!-- d3d12-review-alert:end:diagnostics:QA-BeginEvent-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:QA-BeginEvent-return:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:diagnostics:QA-BeginEvent-return:0 -->

<a id="id3d12commandqueue-endevent"></a>

### ID3D12CommandQueue::EndEvent

#### Declaration

```cpp
void EndEvent();
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:diagnostics:QA-EndEvent-behavior:0 -->To mark the end of an instrumentation region at the current location within a D3D12 command queue, use the `PIXEndEvent` function or `PIXScopedEvent` macro.  These are provided by the [WinPixEventRuntime](https://devblogs.microsoft.com/pix/winpixeventruntime/) NuGet package.<!-- d3d12-review-inline:end:diagnostics:QA-EndEvent-behavior:0 --></ins>

<!-- d3d12-review-alert:begin:diagnostics:QA-EndEvent-shared:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [shared queue annotation context](#queue-annotations) applies; this is
> a support method for the event runtime, not a direct application
> instrumentation interface.

<!-- d3d12-review-alert:end:diagnostics:QA-EndEvent-shared:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:QA-EndEvent-return:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:diagnostics:QA-EndEvent-return:0 -->

<a id="dred"></a>

## Device Removed Extended Data

<!-- d3d12-review-alert:begin:diagnostics:diagnostics-responsibilities:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The runtime controls DRED collection and assembles its diagnostic records. Automatic breadcrumbs use GPU progress writes backed by system memory that survives device removal; the driver must support the [existing system-memory diagnostic heap facility](resources.md#existing-memory-heaps). GPU page-fault reporting depends on the GPU and driver. Diagnostic support is not a requirement that every invalid access produces a page fault or identifies one faulting operation. DRED allocation kinds correspond numerically to the published `D3D12DDI_HANDLETYPE` values; these output records are not new driver entry points.

<!-- d3d12-review-alert:end:diagnostics:diagnostics-responsibilities:0 -->

<ins><!-- d3d12-review-inline:begin:diagnostics:dred-introduction:0 -->DRED extends the debugging toolset by providing additional data about the state of GPU workload execution at (or near) the time of the GPU error.  DRED data includes automatic breadcrumbs (with optional PIX event/marker context) and GPU Page Fault analysis. DRED data can be examined in a user-mode debugger or with the use of the DRED interface APIs.<!-- d3d12-review-inline:end:diagnostics:dred-introduction:0 --></ins>

### Automatic breadcrumbs
<ins><!-- d3d12-review-inline:begin:diagnostics:dred-auto-breadcrumbs:1 -->In Windows 10 version 1803 (April 2018 Update / Redstone 4) Microsoft introduced the ID3D12GraphicsCommandList2::WriteBufferImmediate API and encouraged developers to use this to place "breadcrumbs" in the GPU command stream to track GPU progress before a timeout detection and recovery (TDR).  This is still a good approach if a developer wishes to create a custom, low-overhead breadcrumb implementation, but may lack some of the versatility of a standardized solution, such as debugger extensions, PIX event/marker support, or Windows Error Reporting (Watson).<!-- d3d12-review-inline:end:diagnostics:dred-auto-breadcrumbs:1 --></ins>

<ins><!-- d3d12-review-inline:begin:diagnostics:dred-auto-breadcrumbs:2 -->DRED Auto-Breadcrumbs also uses WriteBufferImmediate to place progress counters in the GPU command stream.  DRED inserts a breadcrumb after each "render op" - meaning, after every operation that results in GPU work (e.g. Draw, Dispatch, Copy, Resolve, etc...).  If the device is removed in the middle of a GPU workload, the reported breadcrumb completion count is rebased to the retained history window described below.<!-- d3d12-review-inline:end:diagnostics:dred-auto-breadcrumbs:2 --></ins>

<ins><!-- d3d12-review-inline:begin:diagnostics:dred-auto-breadcrumbs:3 -->Returned breadcrumb history is normalized into chronological retained-window order. `BreadcrumbCount` is the number of retained operations. When `BreadcrumbCount` is nonzero, `pCommandHistory[0]` is the oldest retained operation. `pLastBreadcrumbValue` points to the completed-operation count rebased to that window. If GPU completion has not reached the retained window, that count is pinned to zero. Thus zero means no completed operation is represented **in the retained window**, not that no GPU work has completed overall.<!-- d3d12-review-inline:end:diagnostics:dred-auto-breadcrumbs:3 --></ins>

<ins><!-- d3d12-review-inline:begin:diagnostics:dred-auto-breadcrumbs:4 -->Use the returned counts as array bounds. For a completed count satisfying `0 < completedCount <= BreadcrumbCount`, its last completed retained operation is at index `completedCount - 1`; a zero completed count has no last-completed retained index. A count equal to `BreadcrumbCount` means all represented operations completed. A value outside the stated index bounds does not supply a valid retained-array index. No modulo by a fixed ring size applies to these returned indices. These positions remain diagnostic observations, not proof of which operation caused a fault.<!-- d3d12-review-inline:end:diagnostics:dred-auto-breadcrumbs:4 --></ins>

<ins><!-- d3d12-review-inline:begin:diagnostics:dred-auto-breadcrumbs:5 -->Context records for dropped operations are removed. Surviving `BreadcrumbIndex` values are rebased to the retained history, and `BreadcrumbContextsCount` bounds the returned context array. A surviving `BreadcrumbIndex` addresses history and is bounded by `BreadcrumbCount`, not by the number of context records. Their recorded ordering remains sorted by associated retained-operation index.<!-- d3d12-review-inline:end:diagnostics:dred-auto-breadcrumbs:5 --></ins>

<!-- d3d12-review-context:begin:diagnostics:dred-auto-breadcrumbs:6 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**

> **Historical raw-ring representation:** The source describes a 65,536-operation ring (operations, not 65,536 bytes), an absolute counter counting up to `UINT_MAX`, and `LastOpIndex = (BreadcrumbCount - 1) % 65536` for a nonzero historical recording count. This describes the raw-ring representation, not indexing of the normalized returned array. It establishes neither a current fixed retention capacity nor counter saturation/wrapping behavior or a runtime-version boundary.

<!-- d3d12-review-context:end:diagnostics:dred-auto-breadcrumbs:6 -->

<ins><!-- d3d12-review-inline:begin:diagnostics:dred-auto-breadcrumbs:7 -->**Performance**
Although Auto-Breadcrumbs are designed to be low-overhead, they are far from free. The enablement default is system-controlled; the system can enable collection.<!-- d3d12-review-inline:end:diagnostics:dred-auto-breadcrumbs:7 --></ins>

<!-- d3d12-review-context:begin:diagnostics:dred-auto-breadcrumbs:8 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**

> **Historical measurement (nonbinding):** The source reported between 2-5% performance loss on its typical "AAA" D3D12 graphics game engines. This is not a current performance bound.

<!-- d3d12-review-context:end:diagnostics:dred-auto-breadcrumbs:8 -->

<ins><!-- d3d12-review-inline:begin:diagnostics:dred-auto-breadcrumbs:9 -->**Hardware Requirements**
Because the breadcrumb counter values must be preserved after device removal, the resource containing breadcrumbs must exist in system memory and must persist in the event of device removal.  This means the driver must support D3D12_FEATURE_EXISTING_HEAPS.<!-- d3d12-review-inline:end:diagnostics:dred-auto-breadcrumbs:9 --></ins>

<!-- d3d12-review-context:begin:diagnostics:dred-auto-breadcrumbs:10 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**

> **Historical observation (nonbinding):** The source reported existing-heaps support in most 19H1 D3D12 drivers. This observation does not replace the existing-heaps capability requirement.

<!-- d3d12-review-context:end:diagnostics:dred-auto-breadcrumbs:10 -->

<!-- d3d12-review-alert:begin:diagnostics:dred-auto-breadcrumbs:11 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> **Caveats**
> * Because GPUs are heavily pipelined, there is no guarantee that the breadcrumb counter will indicate the exact operation that failed.  In fact on some tile-based deferred render devices, it is possible for the breadcrumb counter to be a full resource or uav barrier behind the actual GPU progress.
> * Drivers can reorder commands, pre-fetch from resource memory well before executing a command, or flush cached memory well-after completion of a command.  Any of these can produce GPU errors.  In such cases the autobreadcrumb counters may be less helpful or misleading.

<!-- d3d12-review-alert:end:diagnostics:dred-auto-breadcrumbs:11 -->

### GPU page-fault data
<!-- d3d12-review-alert:begin:diagnostics:dred-pagefault:1 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> DRED v1.1, released in Windows 10 19H1, provides GPU Page Fault Reporting.  GPU page faults commonly occur when:
> * An application mistakenly executes work on the GPU that references a deleted object.
> * An application mistakenly executes work on the GPU that accesses an evicted resource or non-resident tile.
> * A shader references an uninitialized or stale descriptor.
> * A shader indexes beyond the end of a root binding.

<!-- d3d12-review-alert:end:diagnostics:dred-pagefault:1 -->

<ins><!-- d3d12-review-inline:begin:diagnostics:dred-pagefault:2 -->DRED attempts to address some of these scenarios by reporting the names and types of existing or recently freed API objects that match the GPU virtual address (VA) of the GPU-reported page fault.<!-- d3d12-review-inline:end:diagnostics:dred-pagefault:2 --></ins>

<ins><!-- d3d12-review-inline:begin:diagnostics:dred-pagefault:3 -->Premature release of objects in-flight is one of the top causes for unexpected device removals.  DRED retains a bounded history of recently freed objects. The historical source's 65,000-object figure is not established as a universal retention limit.  DRED reports when any of these objects correlate to the faulting VA.<!-- d3d12-review-inline:end:diagnostics:dred-pagefault:3 --></ins>

<ins><!-- d3d12-review-inline:begin:diagnostics:dred-pagefault:4 -->**Performance**
The D3D12 runtime must actively curate a collection of existing and recently-deleted API objects indexable by VA.  This increases the system memory overhead and introduces a small performance hit to object creation and destruction.  The enablement default is system-controlled; the system can enable collection.<!-- d3d12-review-inline:end:diagnostics:dred-pagefault:4 --></ins>

<ins><!-- d3d12-review-inline:begin:diagnostics:dred-pagefault:5 -->**Hardware Requirements**
Many, but not all, GPUs currently support GPU page faults.  Hardware that doesn't support page faulting can still benefit from Auto-Breadcrumbs.<!-- d3d12-review-inline:end:diagnostics:dred-pagefault:5 --></ins>

<ins><!-- d3d12-review-inline:begin:diagnostics:dred-pagefault:6 -->**Caveat**
Not all GPUs support page faults.  Some GPUs respond to memory faults by bit-bucket writes, reading simulated data (e.g. zeros), or simply hanging. Unfortunately, in cases where the GPU doesn't immediately hang, TDRs can happen later in the pipe, making it even harder to locate the root cause.<!-- d3d12-review-inline:end:diagnostics:dred-pagefault:6 --></ins>

### Breadcrumb context strings
During command list recording, operations that support breadcrumb context data append both the command index and context string to the end of an array.  The array is naturally sorted, making it trivial to use a binary search utility such as std::equal_range.  Keeping the breadcrumb context strings separate from the auto-breadcrumb table reduces memory overhead over storing a string pointer for every breadcrumb.

The following is an example of DRED auto-breadcrumb data with context strings:

**Breadcrumbs**
| Index | Op                                          |
|-------|---------------------------------------------|
| 00    | D3D12_AUTO_BREADCRUMB_OP_SETMARKER          |
| 01    | D3D12_AUTO_BREADCRUMB_OP_COPYRESOURCE       |
| 02    | D3D12_AUTO_BREADCRUMB_OP_COPYRESOURCE       |
| 03    | D3D12_AUTO_BREADCRUMB_OP_RESOURCEBARRIER    |
| 04    | D3D12_AUTO_BREADCRUMB_OP_SETMARKER          |
| 05    | D3D12_AUTO_BREADCRUMB_OP_DRAWINSTANCED      |
| 06    | D3D12_AUTO_BREADCRUMB_OP_RESOURCEBARRIER    |
| 07    | D3D12_AUTO_BREADCRUMB_OP_SETMARKER          |
| 08    | D3D12_AUTO_BREADCRUMB_OP_RESOLVESUBRESOURCE |
| 09    | D3D12_AUTO_BREADCRUMB_OP_RESOURCEBARRIER    |
| 10    | D3D12_AUTO_BREADCRUMB_OP_SETMARKER          |
| 11    | D3D12_AUTO_BREADCRUMB_OP_COPYRESOURCE       |

**Breadcrumb Contexts**
| Op Index | Context String                           |
|----------|------------------------------------------|
| 00       | "Copying TexA and TexB to TexC and TexD" |
| 04       | "Drawing object X"                       |
| 07       | "Resolving diffuse texture"              |
| 10       | "Copying diffuse texture"                |

<a id="dred-settings"></a>

### Settings and collection lifetime

<!-- d3d12-review-alert:begin:diagnostics:dred-settings-snapshot:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Configure DRED settings before creating a device. Changes do not affect devices already created. Global entry-point settings affect subsequent global creation; a factory's settings affect devices created from that factory's configuration snapshot. [Devices and capabilities](devices-and-capabilities.md#id3d12devicefactory-getconfigurationinterface) defines retrieval, compatibility and snapshot transfer.

<!-- d3d12-review-alert:end:diagnostics:dred-settings-snapshot:0 -->

<!-- d3d12-review-alert:begin:diagnostics:dred-settings-snapshot:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Each `D3D12_DRED_ENABLEMENT` setting defaults to `D3D12_DRED_ENABLEMENT_SYSTEM_CONTROLLED`: the system policy determines whether collection is enabled. `FORCED_OFF` disables the selected feature regardless of system state; `FORCED_ON` enables it regardless of system state. These controls do not supply absent hardware capabilities. Context collection and markers-only selection do not themselves enable automatic breadcrumbs.

<!-- d3d12-review-alert:end:diagnostics:dred-settings-snapshot:1 -->

<a id="id3d12deviceremovedextendeddatasettings-setautobreadcrumbsenablement"></a>

### ID3D12DeviceRemovedExtendedDataSettings::SetAutoBreadcrumbsEnablement

#### Declaration

```cpp
void SetAutoBreadcrumbsEnablement(D3D12_DRED_ENABLEMENT Enablement);
```

#### Behavior

Configures the enablement settings for Device Removed Extended Data (DRED) auto-breadcrumbs.

#### Parameters

`Enablement`

A [D3D12_DRED_ENABLEMENT](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_dred_enablement) value. The default is **D3D12\_DRED\_ENABLEMENT\_SYSTEM\_CONTROLLED**.

#### Return values

None

<a id="id3d12deviceremovedextendeddatasettings-setpagefaultenablement"></a>

### ID3D12DeviceRemovedExtendedDataSettings::SetPageFaultEnablement

#### Declaration

```cpp
void SetPageFaultEnablement(D3D12_DRED_ENABLEMENT Enablement);
```

#### Behavior

Configures the enablement settings for Device Removed Extended Data (DRED) page fault reporting.

#### Parameters

`Enablement`

A [D3D12_DRED_ENABLEMENT](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_dred_enablement) value. The default is **D3D12\_DRED\_ENABLEMENT\_SYSTEM\_CONTROLLED**.

#### Return values

None

<a id="id3d12deviceremovedextendeddatasettings-setwatsondumpenablement"></a>

### ID3D12DeviceRemovedExtendedDataSettings::SetWatsonDumpEnablement

#### Declaration

```cpp
void SetWatsonDumpEnablement(D3D12_DRED_ENABLEMENT Enablement);
```

#### Behavior

Configures the enablement settings for Device Removed Extended Data (DRED) dump creation for [Windows Error Reporting (WER)](https://learn.microsoft.com/en-us/windows/desktop/wer/windows-error-reporting), also known as Watson.

#### Parameters

`Enablement`

A [D3D12_DRED_ENABLEMENT](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_dred_enablement) value. The default is **D3D12\_DRED\_ENABLEMENT\_SYSTEM\_CONTROLLED**.

#### Return values

None

<a id="id3d12deviceremovedextendeddatasettings1-setbreadcrumbcontextenablement"></a>

### ID3D12DeviceRemovedExtendedDataSettings1::SetBreadcrumbContextEnablement

#### Declaration

```cpp
void SetBreadcrumbContextEnablement(D3D12_DRED_ENABLEMENT Enablement);
```

#### Behavior

<!-- d3d12-review-alert:begin:diagnostics:breadcrumb-context-setting:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Configures the enablement settings for DRED auto-breadcrumbs context data.

<!-- d3d12-review-alert:end:diagnostics:breadcrumb-context-setting:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:breadcrumb-context-setting:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `Enablement` is a `D3D12_DRED_ENABLEMENT` value and defaults to `D3D12_DRED_ENABLEMENT_SYSTEM_CONTROLLED`.

<!-- d3d12-review-alert:end:diagnostics:breadcrumb-context-setting:2 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:breadcrumb-context-setting:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> None.

<!-- d3d12-review-alert:end:diagnostics:breadcrumb-context-setting:4 -->

<a id="id3d12deviceremovedextendeddatasettings2-usemarkersonlyautobreadcrumbs"></a>

### ID3D12DeviceRemovedExtendedDataSettings2::UseMarkersOnlyAutoBreadcrumbs

#### Declaration

```cpp
void UseMarkersOnlyAutoBreadcrumbs(BOOL MarkersOnly);
```

#### Behavior

<!-- d3d12-review-alert:begin:diagnostics:markers-only:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Suppresses DRED auto-breadcrumbs for all operations except `ID3D12GraphicsCommandList::SetMarker`, `BeginEvent` and `EndEvent`.

<!-- d3d12-review-alert:end:diagnostics:markers-only:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:markers-only:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `MarkersOnly` is an input `BOOL`: `TRUE` selects markers-only recording; `FALSE` records the normal operation history. The default is `FALSE`.

<!-- d3d12-review-alert:end:diagnostics:markers-only:2 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:markers-only:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> None.

<!-- d3d12-review-alert:end:diagnostics:markers-only:4 -->

<a id="dred-output-lifetime"></a>

### Access and ownership of output

<!-- d3d12-review-alert:begin:diagnostics:dred-output-lifetime:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The DRED output interface is obtained from the device using `QueryInterface`. The output structures are caller-provided value containers; the runtime owns the nodes, arrays and strings to which they point. The application must not free or modify those referenced records. Their validity is tied to the device; retain the device while reading the output, and copy diagnostic data needed after device destruction.

<!-- d3d12-review-alert:end:diagnostics:dred-output-lifetime:0 -->

<!-- d3d12-review-alert:begin:diagnostics:dred-output-lifetime:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A node's `pCommandList`, `pCommandQueue` or allocation `pObject` records an object address. It is not an owning COM reference and does not make a destroyed object callable. Names can be absent, and the ANSI and wide-name pointers are independent. Non-null name pointers denote null-terminated strings: narrow/ANSI for `A`, UTF-16 for `W`. A null list head denotes no records; a null `pNext` terminates a list. A successful output call can contain no breadcrumbs or no matching allocations.

<!-- d3d12-review-alert:end:diagnostics:dred-output-lifetime:1 -->

<!-- d3d12-review-alert:begin:diagnostics:dred-output-lifetime:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> For each breadcrumb node, `BreadcrumbCount` is the number of chronological retained operation entries in `pCommandHistory`. `pLastBreadcrumbValue` points to a completed-operation count rebased to this retained window, not an operation identifier or the total amount of GPU work ever completed. Zero means no completed operation is represented in this retained window, including when completion precedes its oldest operation. Use `BreadcrumbCount` to bound history accesses and `BreadcrumbContextsCount` to bound `pBreadcrumbContexts`; zero elements require no array access. Only nonnull pointers provide data to dereference: an absent completed-value pointer provides no completed count, and an absent history pointer provides no operation array. Contexts for dropped history are absent; each surviving `BreadcrumbIndex` is a zero-based index into retained `pCommandHistory`, and `pContextString` is a null-terminated UTF-16 string. Multiple surviving context records may identify the same retained operation.

<!-- d3d12-review-alert:end:diagnostics:dred-output-lifetime:2 -->

<!-- d3d12-review-alert:begin:diagnostics:dred-output-lifetime:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Allocation lists contain existing and recently freed objects whose tracked VA ranges match the fault address. Multiple matches are possible; a matching name/address is not proof of fault responsibility. Finite retention and incomplete tracking can omit a relevant allocation. A missing match does not establish that the memory access was valid.

<!-- d3d12-review-alert:end:diagnostics:dred-output-lifetime:3 -->

<a id="id3d12deviceremovedextendeddata1-getautobreadcrumbsoutput1"></a>

### ID3D12DeviceRemovedExtendedData1::GetAutoBreadcrumbsOutput1

#### Declaration

```cpp
HRESULT GetAutoBreadcrumbsOutput1(D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT1 *pOutput);
```

#### Behavior

Gets the DRED v1.2 auto-breadcrumbs output.

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:ID3D12DeviceRemovedExtendedData1-GetAutoBreadcrumbsOutput1-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pOutput` points to a caller-provided `D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT1` output structure. This is not a byte-buffer size-query interface. On success the structure receives runtime-owned data pointers governed by [output lifetime](#dred-output-lifetime).

<!-- d3d12-review-alert:end:diagnostics:ID3D12DeviceRemovedExtendedData1-GetAutoBreadcrumbsOutput1-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:ID3D12DeviceRemovedExtendedData1-GetAutoBreadcrumbsOutput1-results:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` on success. `DXGI_ERROR_UNSUPPORTED` if the corresponding DRED collection feature was not enabled for the device; `DXGI_ERROR_NOT_CURRENTLY_AVAILABLE` if that feature is enabled but the device is not removed. Do not read an output structure as successful data after a failing call.

<!-- d3d12-review-alert:end:diagnostics:ID3D12DeviceRemovedExtendedData1-GetAutoBreadcrumbsOutput1-results:0 -->

<a id="id3d12deviceremovedextendeddata1-getpagefaultallocationoutput1"></a>

### ID3D12DeviceRemovedExtendedData1::GetPageFaultAllocationOutput1

#### Declaration

```cpp
HRESULT GetPageFaultAllocationOutput1(D3D12_DRED_PAGE_FAULT_OUTPUT1 *pOutput);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12DeviceRemovedExtendedData1-GetPageFaultAllocationOutput1-behavior:0 -->Gets the DRED page fault data, including matching allocation for both living and recently-deleted runtime objects.<!-- d3d12-review-inline:end:diagnostics:ID3D12DeviceRemovedExtendedData1-GetPageFaultAllocationOutput1-behavior:0 --></ins>

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:ID3D12DeviceRemovedExtendedData1-GetPageFaultAllocationOutput1-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pOutput` points to a caller-provided `D3D12_DRED_PAGE_FAULT_OUTPUT1` output structure. This is not a byte-buffer size-query interface. On success the structure receives runtime-owned data pointers governed by [output lifetime](#dred-output-lifetime).

<!-- d3d12-review-alert:end:diagnostics:ID3D12DeviceRemovedExtendedData1-GetPageFaultAllocationOutput1-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:ID3D12DeviceRemovedExtendedData1-GetPageFaultAllocationOutput1-results:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` on success. `DXGI_ERROR_UNSUPPORTED` if the corresponding DRED collection feature was not enabled for the device; `DXGI_ERROR_NOT_CURRENTLY_AVAILABLE` if that feature is enabled but the device is not removed. Do not read an output structure as successful data after a failing call.

<!-- d3d12-review-alert:end:diagnostics:ID3D12DeviceRemovedExtendedData1-GetPageFaultAllocationOutput1-results:0 -->

<a id="id3d12deviceremovedextendeddata2-getdevicestate"></a>

### ID3D12DeviceRemovedExtendedData2::GetDeviceState

#### Declaration

```cpp
D3D12_DRED_DEVICE_STATE GetDeviceState();
```

#### Behavior

<!-- d3d12-review-alert:begin:diagnostics:ID3D12DeviceRemovedExtendedData2-GetDeviceState-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns the DRED device-state classification as a `D3D12_DRED_DEVICE_STATE`, not an `HRESULT`.

<!-- d3d12-review-alert:end:diagnostics:ID3D12DeviceRemovedExtendedData2-GetDeviceState-behavior:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:device-state-result:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `UNKNOWN` means that DRED has no known device-state classification; it is not proof that the device is healthy. `HUNG`, `FAULT` and `PAGEFAULT` distinguish the recorded device states. `GetDeviceRemovedReason` supplies the separate removal `HRESULT`.

<!-- d3d12-review-alert:end:diagnostics:device-state-result:0 -->

#### Context

<!-- d3d12-review-alert:begin:diagnostics:device-state-access:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `GetDeviceState` can be called before device removal; it has no `DXGI_ERROR_NOT_CURRENTLY_AVAILABLE` return path. An unknown recorded state can remain `D3D12_DRED_DEVICE_STATE_UNKNOWN` after removal as well. The breadcrumb/page-fault output getters have their separate collection enablement and removed-state requirements.

<!-- d3d12-review-alert:end:diagnostics:device-state-access:0 -->

<a id="id3d12deviceremovedextendeddata2-getpagefaultallocationoutput2"></a>

### ID3D12DeviceRemovedExtendedData2::GetPageFaultAllocationOutput2

#### Declaration

```cpp
HRESULT GetPageFaultAllocationOutput2(D3D12_DRED_PAGE_FAULT_OUTPUT2 *pOutput);
```

#### Behavior

<!-- d3d12-review-alert:begin:diagnostics:ID3D12DeviceRemovedExtendedData2-GetPageFaultAllocationOutput2-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Retrieves page-fault allocation output in a `D3D12_DRED_PAGE_FAULT_OUTPUT2` structure. The versioned record layout is defined below.

<!-- d3d12-review-alert:end:diagnostics:ID3D12DeviceRemovedExtendedData2-GetPageFaultAllocationOutput2-behavior:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:ID3D12DeviceRemovedExtendedData2-GetPageFaultAllocationOutput2-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pOutput` points to a caller-provided `D3D12_DRED_PAGE_FAULT_OUTPUT2` output structure. This is not a byte-buffer size-query interface. On success the structure receives runtime-owned data pointers governed by [output lifetime](#dred-output-lifetime).

<!-- d3d12-review-alert:end:diagnostics:ID3D12DeviceRemovedExtendedData2-GetPageFaultAllocationOutput2-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:ID3D12DeviceRemovedExtendedData2-GetPageFaultAllocationOutput2-results:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK` on success. `DXGI_ERROR_UNSUPPORTED` if the corresponding DRED collection feature was not enabled for the device; `DXGI_ERROR_NOT_CURRENTLY_AVAILABLE` if that feature is enabled but the device is not removed. Do not read an output structure as successful data after a failing call.

<!-- d3d12-review-alert:end:diagnostics:ID3D12DeviceRemovedExtendedData2-GetPageFaultAllocationOutput2-results:0 -->

<a id="id3d12deviceremovedextendeddata-getautobreadcrumbsoutput"></a>

### ID3D12DeviceRemovedExtendedData::GetAutoBreadcrumbsOutput

#### Declaration

```cpp
HRESULT GetAutoBreadcrumbsOutput(D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT *pOutput);
```

#### Behavior

Retrieves the Device Removed Extended Data (DRED) auto-breadcrumbs output after device removal.

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:ID3D12DeviceRemovedExtendedData-GetAutoBreadcrumbsOutput-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pOutput` points to a caller-provided `D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT` output structure. This is not a byte-buffer size-query interface. On success the structure receives runtime-owned data pointers governed by [output lifetime](#dred-output-lifetime).

<!-- d3d12-review-alert:end:diagnostics:ID3D12DeviceRemovedExtendedData-GetAutoBreadcrumbsOutput-parameters:0 -->

#### Return values

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12DeviceRemovedExtendedData-GetAutoBreadcrumbsOutput-Return-value:1 -->If the function succeeds, it returns **S\_OK**. Otherwise, it returns an [HRESULT](https://learn.microsoft.com/en-us/windows/desktop/com/structure-of-com-error-codes) [error code](https://learn.microsoft.com/en-us/windows/desktop/com/com-error-codes-10). Returns **DXGI\_ERROR\_NOT\_CURRENTLY\_AVAILABLE** if the device is *not* in a removed state. Returns **DXGI\_ERROR\_UNSUPPORTED** if auto-breadcrumbs have not been enabled with [ID3D12DeviceRemovedExtendedDataSettings::SetAutoBreadcrumbsEnablement](#id3d12deviceremovedextendeddatasettings-setautobreadcrumbsenablement).<!-- d3d12-review-inline:end:diagnostics:ID3D12DeviceRemovedExtendedData-GetAutoBreadcrumbsOutput-Return-value:1 --></ins>

<a id="id3d12deviceremovedextendeddata-getpagefaultallocationoutput"></a>

### ID3D12DeviceRemovedExtendedData::GetPageFaultAllocationOutput

#### Declaration

```cpp
HRESULT GetPageFaultAllocationOutput(D3D12_DRED_PAGE_FAULT_OUTPUT *pOutput);
```

#### Behavior

Retrieves the Device Removed Extended Data (DRED) page fault data, including matching allocation for both living and recently-deleted runtime objects. The object whose address is passed receives the data.

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:ID3D12DeviceRemovedExtendedData-GetPageFaultAllocationOutput-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pOutput` points to a caller-provided `D3D12_DRED_PAGE_FAULT_OUTPUT` output structure. This is not a byte-buffer size-query interface. On success the structure receives runtime-owned data pointers governed by [output lifetime](#dred-output-lifetime).

<!-- d3d12-review-alert:end:diagnostics:ID3D12DeviceRemovedExtendedData-GetPageFaultAllocationOutput-parameters:0 -->

#### Return values

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12DeviceRemovedExtendedData-GetPageFaultAllocationOutput-Return-value:1 -->If the function succeeds, it returns **S\_OK**. Otherwise, it returns an [HRESULT](https://learn.microsoft.com/en-us/windows/desktop/com/structure-of-com-error-codes) [error code](https://learn.microsoft.com/en-us/windows/desktop/com/com-error-codes-10). Returns **DXGI\_ERROR\_NOT\_CURRENTLY\_AVAILABLE** if the device is *not* in a removed state. Returns **DXGI\_ERROR\_UNSUPPORTED** if page fault reporting has not been enabled with [ID3D12DeviceRemovedExtendedDataSettings::SetPageFaultEnablement](#id3d12deviceremovedextendeddatasettings-setpagefaultenablement).<!-- d3d12-review-inline:end:diagnostics:ID3D12DeviceRemovedExtendedData-GetPageFaultAllocationOutput-Return-value:1 --></ins>

<a id="dred-examples"></a>

### DRED examples

#### Configure before device creation
<ins><!-- d3d12-review-inline:begin:diagnostics:dred-setup-example:1 -->DRED settings must be configured prior to creating a D3D12 Device.  Use D3D12GetDebugInterface to get an interface to the ID3D12DeviceRemovedExtendedDataSettings object.<!-- d3d12-review-inline:end:diagnostics:dred-setup-example:1 --></ins>

Example:
```cpp
CComPtr<ID3D12DeviceRemovedExtendedDataSettings1> pDredSettings;
VERIFY_SUCCEEDED(D3D12GetDebugInterface(IID_PPV_ARGS(&pDredSettings)));

// Turn on AutoBreadcrumbs and Page Fault reporting
pDredSettings->SetAutoBreadcrumbsEnablement(D3D12_DRED_ENABLEMENT_FORCED_ON);
pDredSettings->SetPageFaultEnablement(D3D12_DRED_ENABLEMENT_FORCED_ON);
```

#### Retrieve after removal
After device removal has been detected (e.g. Present returns DXGI_ERROR_DEVICE_REMOVED), use ID3D12DeviceRemovedExtendedData methods to access the DRED data for the removed device.

The ID3D12DeviceRemovedExtendedData interface can be QI'd from an ID3D12Device object.

Example:
```cpp
void MyDeviceRemovedHandler(ID3D12Device *pDevice)
{
    CComPtr<ID3D12DeviceRemovedExtendedData1> pDred;
    VERIFY_SUCCEEDED(pDevice->QueryInterface(IID_PPV_ARGS(&pDred)));

    D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT1 DredAutoBreadcrumbsOutput;
    D3D12_DRED_PAGE_FAULT_OUTPUT1 DredPageFaultOutput;
    VERIFY_SUCCEEDED(pDred->GetAutoBreadcrumbsOutput1(&DredAutoBreadcrumbsOutput));
    VERIFY_SUCCEEDED(pDred->GetPageFaultAllocationOutput1(&DredPageFaultOutput));

    // Custom processing of DRED data can be done here.
    // Produce telemetry...
    // Log information to console...
    // break into a debugger...
}
```

<a id="dred-types"></a>

### DRED data types

#### D3D12_DRED_VERSION
Version used by D3D12_VERSIONED_DEVICE_REMOVED_EXTENDED_DATA.

```cpp
enum D3D12_DRED_VERSION
{
    D3D12_DRED_VERSION_1_0	= 0x1,
    D3D12_DRED_VERSION_1_1	= 0x2,
    D3D12_DRED_VERSION_1_2	= 0x3,
    D3D12_DRED_VERSION_1_3 = 0x4
};

```
<!-- d3d12-review-alert:begin:diagnostics:dred-primary-types:3 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Constants              | Meaning          |
> |------------------------|:-----------------|
> | D3D12_DRED_VERSION_1_0 | Dred version 1.0 |
> | D3D12_DRED_VERSION_1_1 | Dred version 1.1 |
> | D3D12_DRED_VERSION_1_2 | Dred version 1.2 |
> | D3D12_DRED_VERSION_1_3 | Dred version 1.3 |

<!-- d3d12-review-alert:end:diagnostics:dred-primary-types:3 -->

#### D3D12_AUTO_BREADCRUMB_OP
<ins><!-- d3d12-review-inline:begin:diagnostics:dred-primary-types:5 -->Enum values corresponding to GPU operations<!-- d3d12-review-inline:end:diagnostics:dred-primary-types:5 --></ins>

```cpp
enum D3D12_AUTO_BREADCRUMB_OP
{
    D3D12_AUTO_BREADCRUMB_OP_SETMARKER	= 0,
    D3D12_AUTO_BREADCRUMB_OP_BEGINEVENT	= 1,
    D3D12_AUTO_BREADCRUMB_OP_ENDEVENT	= 2,
    D3D12_AUTO_BREADCRUMB_OP_DRAWINSTANCED	= 3,
    D3D12_AUTO_BREADCRUMB_OP_DRAWINDEXEDINSTANCED	= 4,
    D3D12_AUTO_BREADCRUMB_OP_EXECUTEINDIRECT	= 5,
    D3D12_AUTO_BREADCRUMB_OP_DISPATCH	= 6,
    D3D12_AUTO_BREADCRUMB_OP_COPYBUFFERREGION	= 7,
    D3D12_AUTO_BREADCRUMB_OP_COPYTEXTUREREGION	= 8,
    D3D12_AUTO_BREADCRUMB_OP_COPYRESOURCE	= 9,
    D3D12_AUTO_BREADCRUMB_OP_COPYTILES	= 10,
    D3D12_AUTO_BREADCRUMB_OP_RESOLVESUBRESOURCE	= 11,
    D3D12_AUTO_BREADCRUMB_OP_CLEARRENDERTARGETVIEW	= 12,
    D3D12_AUTO_BREADCRUMB_OP_CLEARUNORDEREDACCESSVIEW	= 13,
    D3D12_AUTO_BREADCRUMB_OP_CLEARDEPTHSTENCILVIEW	= 14,
    D3D12_AUTO_BREADCRUMB_OP_RESOURCEBARRIER	= 15,
    D3D12_AUTO_BREADCRUMB_OP_EXECUTEBUNDLE	= 16,
    D3D12_AUTO_BREADCRUMB_OP_PRESENT	= 17,
    D3D12_AUTO_BREADCRUMB_OP_RESOLVEQUERYDATA	= 18,
    D3D12_AUTO_BREADCRUMB_OP_BEGINSUBMISSION	= 19,
    D3D12_AUTO_BREADCRUMB_OP_ENDSUBMISSION	= 20,
    D3D12_AUTO_BREADCRUMB_OP_DECODEFRAME	= 21,
    D3D12_AUTO_BREADCRUMB_OP_PROCESSFRAMES	= 22,
    D3D12_AUTO_BREADCRUMB_OP_ATOMICCOPYBUFFERUINT	= 23,
    D3D12_AUTO_BREADCRUMB_OP_ATOMICCOPYBUFFERUINT64	= 24,
    D3D12_AUTO_BREADCRUMB_OP_RESOLVESUBRESOURCEREGION	= 25,
    D3D12_AUTO_BREADCRUMB_OP_WRITEBUFFERIMMEDIATE	= 26,
    D3D12_AUTO_BREADCRUMB_OP_DECODEFRAME1	= 27,
    D3D12_AUTO_BREADCRUMB_OP_SETPROTECTEDRESOURCESESSION	= 28,
    D3D12_AUTO_BREADCRUMB_OP_DECODEFRAME2	= 29,
    D3D12_AUTO_BREADCRUMB_OP_PROCESSFRAMES1	= 30,
    D3D12_AUTO_BREADCRUMB_OP_BUILDRAYTRACINGACCELERATIONSTRUCTURE	= 31,
    D3D12_AUTO_BREADCRUMB_OP_EMITRAYTRACINGACCELERATIONSTRUCTUREPOSTBUILDINFO	= 32,
    D3D12_AUTO_BREADCRUMB_OP_COPYRAYTRACINGACCELERATIONSTRUCTURE	= 33,
    D3D12_AUTO_BREADCRUMB_OP_DISPATCHRAYS	= 34,
    D3D12_AUTO_BREADCRUMB_OP_INITIALIZEMETACOMMAND	= 35,
    D3D12_AUTO_BREADCRUMB_OP_EXECUTEMETACOMMAND	= 36,
    D3D12_AUTO_BREADCRUMB_OP_ESTIMATEMOTION	= 37,
    D3D12_AUTO_BREADCRUMB_OP_RESOLVEMOTIONVECTORHEAP	= 38,
    D3D12_AUTO_BREADCRUMB_OP_SETPIPELINESTATE1	= 39,
    D3D12_AUTO_BREADCRUMB_OP_INITIALIZEEXTENSIONCOMMAND	= 40,
    D3D12_AUTO_BREADCRUMB_OP_EXECUTEEXTENSIONCOMMAND	= 41,
    D3D12_AUTO_BREADCRUMB_OP_DISPATCHMESH	= 42,
    D3D12_AUTO_BREADCRUMB_OP_ENCODEFRAME	= 43,
    D3D12_AUTO_BREADCRUMB_OP_RESOLVEENCODEROUTPUTMETADATA	= 44,
    D3D12_AUTO_BREADCRUMB_OP_BARRIER	= 45,
    D3D12_AUTO_BREADCRUMB_OP_BEGIN_COMMAND_LIST	= 46,
    D3D12_AUTO_BREADCRUMB_OP_DISPATCHGRAPH = 47,
    D3D12_AUTO_BREADCRUMB_OP_SETPROGRAM = 48,
};
```

#### D3D12_DRED_ALLOCATION_TYPE
Congruent with and numerically equivalent to D3D12DDI_HANDLETYPE enum values.

```cpp
enum D3D12_DRED_ALLOCATION_TYPE
{
    D3D12_DRED_ALLOCATION_TYPE_COMMAND_QUEUE	= 19,
    D3D12_DRED_ALLOCATION_TYPE_COMMAND_ALLOCATOR	= 20,
    D3D12_DRED_ALLOCATION_TYPE_PIPELINE_STATE	= 21,
    D3D12_DRED_ALLOCATION_TYPE_COMMAND_LIST	= 22,
    D3D12_DRED_ALLOCATION_TYPE_FENCE	= 23,
    D3D12_DRED_ALLOCATION_TYPE_DESCRIPTOR_HEAP	= 24,
    D3D12_DRED_ALLOCATION_TYPE_HEAP	= 25,
    D3D12_DRED_ALLOCATION_TYPE_QUERY_HEAP	= 27,
    D3D12_DRED_ALLOCATION_TYPE_COMMAND_SIGNATURE	= 28,
    D3D12_DRED_ALLOCATION_TYPE_PIPELINE_LIBRARY	= 29,
    D3D12_DRED_ALLOCATION_TYPE_VIDEO_DECODER	= 30,
    D3D12_DRED_ALLOCATION_TYPE_VIDEO_PROCESSOR	= 32,
    D3D12_DRED_ALLOCATION_TYPE_RESOURCE	= 34,
    D3D12_DRED_ALLOCATION_TYPE_PASS	= 35,
    D3D12_DRED_ALLOCATION_TYPE_CRYPTOSESSION	= 36,
    D3D12_DRED_ALLOCATION_TYPE_CRYPTOSESSIONPOLICY	= 37,
    D3D12_DRED_ALLOCATION_TYPE_PROTECTEDRESOURCESESSION	= 38,
    D3D12_DRED_ALLOCATION_TYPE_VIDEO_DECODER_HEAP	= 39,
    D3D12_DRED_ALLOCATION_TYPE_COMMAND_POOL	= 40,
    D3D12_DRED_ALLOCATION_TYPE_COMMAND_RECORDER	= 41,
    D3D12_DRED_ALLOCATION_TYPE_STATE_OBJECT	= 42,
    D3D12_DRED_ALLOCATION_TYPE_METACOMMAND	= 43,
    D3D12_DRED_ALLOCATION_TYPE_SCHEDULINGGROUP	= 44,
    D3D12_DRED_ALLOCATION_TYPE_VIDEO_MOTION_ESTIMATOR	= 45,
    D3D12_DRED_ALLOCATION_TYPE_VIDEO_MOTION_VECTOR_HEAP	= 46,
    D3D12_DRED_ALLOCATION_TYPE_VIDEO_EXTENSION_COMMAND	= 47,
    D3D12_DRED_ALLOCATION_TYPE_VIDEO_ENCODER	= 48,
    D3D12_DRED_ALLOCATION_TYPE_VIDEO_ENCODER_HEAP	= 49,
    D3D12_DRED_ALLOCATION_TYPE_INVALID	= 0xffffffff
};
```

#### D3D12_DRED_ENABLEMENT
Used by ID3D12DeviceRemovedExtendedDataSettings to specify how individual DRED features are enabled.  As of DRED v1.1, the default value for all settings is D3D12_DRED_ENABLEMENT_SYSTEM_CONTROLLED.

```cpp
typedef enum D3D12_DRED_ENABLEMENT
{
    D3D12_DRED_ENABLEMENT_SYSTEM_CONTROLLED = 0,
    D3D12_DRED_ENABLEMENT_FORCED_OFF = 1,
    D3D12_DRED_ENABLEMENT_FORCED_ON = 2,
} D3D12_DRED_ENABLEMENT;
```

<!-- d3d12-review-alert:begin:diagnostics:dred-primary-types:13 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Constants                               | Description                                                                                                                                     |
> |-----------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------|
> | D3D12_DRED_ENABLEMENT_SYSTEM_CONTROLLED | The DRED feature is enabled only when DRED is turned on by the system automatically (e.g. when a user is reproducing a problem via FeedbackHub) |
> | D3D12_DRED_ENABLEMENT_FORCED_ON                | Forces a DRED feature on, regardless of system state.                                                                                           |
> | D3D12_DRED_ENABLEMENT_FORCED_OFF | Disables a DRED feature, regardless of system state.                                                                                            |

<!-- d3d12-review-alert:end:diagnostics:dred-primary-types:13 -->

#### D3D12_AUTO_BREADCRUMB_NODE (DRED version 1.1)
D3D12_AUTO_BREADCRUMB_NODE objects are singly linked to each other via the pNext member.  The last node in the list will have a null pNext.

```cpp
typedef struct D3D12_AUTO_BREADCRUMB_NODE
{
    const char *pCommandListDebugNameA;
    const wchar_t *pCommandListDebugNameW;
    const char *pCommandQueueDebugNameA;
    const wchar_t *pCommandQueueDebugNameW;
    ID3D12GraphicsCommandList *pCommandList;
    ID3D12CommandQueue *pCommandQueue;
    UINT32 BreadcrumbCount;
    const UINT32 *pLastBreadcrumbValue;
    const D3D12_AUTO_BREADCRUMB_OP *pCommandHistory;
    const struct D3D12_AUTO_BREADCRUMB_NODE *pNext;
} D3D12_AUTO_BREADCRUMB_NODE;
```

<!-- d3d12-review-alert:begin:diagnostics:dred-primary-types:17 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Members                 | Description                                                              |
> |-------------------------|--------------------------------------------------------------------------|
> | pCommandListDebugNameA  | Pointer to the ANSI debug name of the command list (if any)              |
> | pCommandListDebugNameW  | Pointer to the wide debug name of the command list (if any)              |
> | pCommandQueueDebugNameA | Pointer to the ANSI debug name of the command queue (if any)             |
> | pCommandQueueDebugNameW | Pointer to the wide debug name of the command queue (if any)             |
> | pCommandList            | Address of the command list at the time of execution                     |
> | pCommandQueue           | Address of the command queue                                             |
> | BreadcrumbCount         | Number of retained operation entries in pCommandHistory, in chronological order           |
> | pLastBreadcrumbValue    | Pointer to the completed-operation count rebased to the retained window; zero means none represented in that window                 |
> | pCommandHistory         | Pointer to BreadcrumbCount retained operations, ordered oldest to newest             |
> | pNext                   | Pointer to the next node in the list or nullptr if this is the last node |

<!-- d3d12-review-alert:end:diagnostics:dred-primary-types:17 -->

#### D3D12_DRED_BREADCRUMB_CONTEXT (DRED version 1.2)
Context string data associated with a DRED auto-breadcrumb.

```cpp
typedef struct D3D12_DRED_BREADCRUMB_CONTEXT
{
    UINT BreadcrumbIndex;
    const wchar_t *pContextString;
} D3D12_DRED_BREADCRUMB_CONTEXT;
```

<!-- d3d12-review-alert:begin:diagnostics:dred-primary-types:21 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Members         | Description                                                           |
> |-----------------|-----------------------------------------------------------------------|
> | BreadcrumbIndex | Zero-based index of the associated operation in retained pCommandHistory |
> | pContextString  | Points to the breadcrumb context string                               |

<!-- d3d12-review-alert:end:diagnostics:dred-primary-types:21 -->

#### D3D12_AUTO_BREADCRUMB_NODE1 (DRED version 1.2)
An extended version of struct D3D12_AUTO_BREADCRUMB_NODE that includes breadcrumb context data.

```cpp
typedef struct D3D12_AUTO_BREADCRUMB_NODE1
{
    const char *pCommandListDebugNameA;
    const wchar_t *pCommandListDebugNameW;
    const char *pCommandQueueDebugNameA;
    const wchar_t *pCommandQueueDebugNameW;
    ID3D12GraphicsCommandList *pCommandList;
    ID3D12CommandQueue *pCommandQueue;
    UINT BreadcrumbCount;
    const UINT *pLastBreadcrumbValue;
    const D3D12_AUTO_BREADCRUMB_OP *pCommandHistory;
    const struct D3D12_AUTO_BREADCRUMB_NODE1 *pNext;
    UINT BreadcrumbContextsCount;
    D3D12_DRED_BREADCRUMB_CONTEXT *pBreadcrumbContexts;
} D3D12_AUTO_BREADCRUMB_NODE1;
```

<!-- d3d12-review-alert:begin:diagnostics:dred-primary-types:25 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Members                 | Description                                                                 |
> |-------------------------|-----------------------------------------------------------------------------|
> | pCommandListDebugNameA  | Pointer to the ANSI debug name of the command list (if any)                 |
> | pCommandListDebugNameW  | Pointer to the wide debug name of the command list (if any)                 |
> | pCommandQueueDebugNameA | Pointer to the ANSI debug name of the command queue (if any)                |
> | pCommandQueueDebugNameW | Pointer to the wide debug name of the command queue (if any)                |
> | pCommandList            | Address of the command list at the time of execution                        |
> | pCommandQueue           | Address of the command queue                                                |
> | BreadcrumbCount         | Number of retained operation entries in pCommandHistory, in chronological order              |
> | pLastBreadcrumbValue    | Pointer to the completed-operation count rebased to the retained window; zero means none represented in that window                    |
> | pCommandHistory         | Pointer to BreadcrumbCount retained operations, ordered oldest to newest                |
> | pNext                   | Pointer to the next node in the list or nullptr if this is the last node    |
> | BreadcrumbContextsCount | Number of surviving context elements after dropped-operation contexts are removed |
> | pBreadcrumbContexts     | Pointer to BreadcrumbContextsCount surviving contexts with retained-window indices                         |

<!-- d3d12-review-alert:end:diagnostics:dred-primary-types:25 -->

#### D3D12_DRED_ALLOCATION_NODE (DRED version 1.1)
Describes allocation data for a DRED-tracked allocation.  If device removal is caused by a GPU page fault, DRED reports all matching allocation nodes for active and recently-freed runtime objects.

D3D12_DRED_ALLOCATION_NODE objects are singly linked to each other via the pNext member.  The last node in the list will have a null pNext.

```cpp
struct D3D12_DRED_ALLOCATION_NODE
{
    const char *ObjectNameA;
    const wchar_t *ObjectNameW;
    D3D12_DRED_ALLOCATION_TYPE AllocationType;
    const struct D3D12_DRED_ALLOCATION_NODE *pNext;
};
```

<!-- d3d12-review-alert:begin:diagnostics:dred-primary-types:30 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Members        | Description                                                                          |
> |----------------|--------------------------------------------------------------------------------------|
> | ObjectNameA    | ANSI name of the API object or nullptr if no ANSI name exists.                       |
> | ObjectNameW    | UTF-16 name of the API object or nullptr if no UTF-16 name exists.                   |
> | AllocationType | Type of allocation                                                                   |
> | pNext          | Pointer to next allocation node in linked list, or nullptr if this is the last node. |

<!-- d3d12-review-alert:end:diagnostics:dred-primary-types:30 -->

#### D3D12_DRED_ALLOCATION_NODE1 (DRED version 1.2)
Describes allocation data for a DRED-tracked allocation.  If device removal is caused by a GPU page fault, DRED reports all matching allocation nodes for active and recently-freed runtime objects.

D3D12_DRED_ALLOCATION_NODE1 objects are singly linked to each other via the pNext member.  The last node in the list will have a null pNext.

```cpp
struct D3D12_DRED_ALLOCATION_NODE1
{
    const char *ObjectNameA;
    const wchar_t *ObjectNameW;
    D3D12_DRED_ALLOCATION_TYPE AllocationType;
    const struct D3D12_DRED_ALLOCATION_NODE1 *pNext;
    const IUnknown *pObject;
};
```

<!-- d3d12-review-alert:begin:diagnostics:dred-primary-types:35 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Members        | Description                                                                          |
> |----------------|--------------------------------------------------------------------------------------|
> | ObjectNameA    | ANSI name of the API object or nullptr if no ANSI name exists.                       |
> | ObjectNameW    | UTF-16 name of the API object or nullptr if no UTF-16 name exists.                   |
> | AllocationType | Type of allocation                                                                   |
> | pNext          | Pointer to next allocation node in linked list, or nullptr if this is the last node. |
> | pObject        | Address of the IUnknown object associated with the allocation.                       |

<!-- d3d12-review-alert:end:diagnostics:dred-primary-types:35 -->


#### D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT (DRED version 1.1)
Contains pointer to the head of a linked list of D3D12_AUTO_BREADCRUMB_NODE structures.

```cpp
struct D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT
{
    const D3D12_AUTO_BREADCRUMB_NODE *pHeadAutoBreadcrumbNode;
};
```

| Members                 | Description                                                                |
|-------------------------|----------------------------------------------------------------------------|
| pHeadAutoBreadcrumbNode | Pointer to the head of a linked list of D3D12_AUTO_BREADCRUMB_NODE objects |

#### D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT1 (DRED version 1.2)
Contains pointer to the head of a linked list of D3D12_AUTO_BREADCRUMB_NODE1 structures.  The last member node in the list has a null pNext member.  The value of pHeadAutoBreadcrumbNode will be null if there are no auto-breadcrumbs.

```cpp
typedef struct D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT1
{
    const D3D12_AUTO_BREADCRUMB_NODE1 *pHeadAutoBreadcrumbNode;
} D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT1;
```

| Members                 | Description                                                                         |
|-------------------------|-------------------------------------------------------------------------------------|
| pHeadAutoBreadcrumbNode | Pointer to the head of a linked list of D3D12_AUTO_BREADCRUMB_NODE1 objects or NULL |

#### D3D12_DRED_PAGE_FAULT_OUTPUT (DRED version 1.1)
Provides the VA of a GPU page fault and contains a list of matching allocation nodes for active objects and a list of allocation nodes for recently deleted objects.

```cpp
struct D3D12_DRED_PAGE_FAULT_OUTPUT
{
    D3D12_GPU_VIRTUAL_ADDRESS PageFaultVA;
    const D3D12_DRED_ALLOCATION_NODE *pHeadExistingAllocationNode;
    const D3D12_DRED_ALLOCATION_NODE *pHeadRecentFreedAllocationNode;
};
```

| Members                        | Description                                                                                                   |
|--------------------------------|--------------------------------------------------------------------------------------------------------------|
| PageFaultVA                    | GPU Virtual Address of GPU page fault                                                                        |
| pHeadExistingAllocationNode    | Pointer to head allocation node for existing runtime objects with VA ranges that match the faulting VA       |
| pHeadRecentFreedAllocationNode | Pointer to head allocation node for recently freed runtime objects with VA ranges that match the faulting VA |

#### D3D12_DRED_PAGE_FAULT_OUTPUT1 (DRED version 1.2)
Provides the VA of a GPU page fault and contains a list of matching allocation nodes for active objects and a list of allocation nodes for recently deleted objects.

```cpp
struct D3D12_DRED_PAGE_FAULT_OUTPUT1
{
    D3D12_GPU_VIRTUAL_ADDRESS PageFaultVA;
    const D3D12_DRED_ALLOCATION_NODE1 *pHeadExistingAllocationNode;
    const D3D12_DRED_ALLOCATION_NODE1 *pHeadRecentFreedAllocationNode;
};
```

| Members                        | Description                                                                                                   |
|--------------------------------|--------------------------------------------------------------------------------------------------------------|
| PageFaultVA                    | GPU Virtual Address of GPU page fault                                                                        |
| pHeadExistingAllocationNode    | Pointer to head allocation node for existing runtime objects with VA ranges that match the faulting VA       |
| pHeadRecentFreedAllocationNode | Pointer to head allocation node for recently freed runtime objects with VA ranges that match the faulting VA |

#### D3D12_DEVICE_REMOVED_EXTENDED_DATA1 (DRED version 1.1)
DRED V1.1 data structure.

```cpp
struct D3D12_DEVICE_REMOVED_EXTENDED_DATA1
{
    HRESULT DeviceRemovedReason;
    D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT AutoBreadcrumbsOutput;
    D3D12_DRED_PAGE_FAULT_OUTPUT PageFaultOutput;
};
```

| Members               | Description                                                                   |
|-----------------------|-------------------------------------------------------------------------------|
| DeviceRemovedReason   | The device removed reason matching the return value of GetDeviceRemovedReason |
| AutoBreadcrumbsOutput | Contained D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT member                           |
| PageFaultOutput       | Contained D3D12_DRED_PAGE_FAULT_OUTPUT member                                 |

#### D3D12_DEVICE_REMOVED_EXTENDED_DATA2 (DRED version 1.2)
DRED V1.2 data structure.

```cpp
typedef struct D3D12_DEVICE_REMOVED_EXTENDED_DATA2
{
    HRESULT DeviceRemovedReason;
    D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT1 AutoBreadcrumbsOutput;
    D3D12_DRED_PAGE_FAULT_OUTPUT1 PageFaultOutput;
} D3D12_DEVICE_REMOVED_EXTENDED_DATA2;
```

| Members               | Description                                                                   |
|-----------------------|-------------------------------------------------------------------------------|
| DeviceRemovedReason   | The device removed reason matching the return value of GetDeviceRemovedReason |
| AutoBreadcrumbsOutput | D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT1 data                                       |
| PageFaultOutput       | D3D12_DRED_PAGE_FAULT_OUTPUT1 data                                             |

#### D3D12_DRED_FLAGS

```cpp
typedef enum D3D12_DRED_FLAGS
{
    D3D12_DRED_FLAG_NONE                    = 0,
    D3D12_DRED_FLAG_FORCE_ENABLE            = 1,
    D3D12_DRED_FLAG_DISABLE_AUTOBREADCRUMBS = 2,
} D3D12_DRED_FLAGS;
```

##### Constants

<!-- d3d12-review-alert:begin:diagnostics:D3D12-DRED-FLAGS-Constants:1 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Constant and meaning |
> | --- |
> | `D3D12_DRED_FLAG_NONE` Value: *(0x0)* Typically specifies that Device Removed Extended Data (DRED) is disabled, except for when user-initiated feedback is used to produce a repro, or when otherwise enabled by Windows via automatic detection of process-instability issues. This is the default value. |
> | `D3D12_DRED_FLAG_FORCE_ENABLE` Value: *(0x1)* Forces DRED to be enabled, regardless of the system state. |
> | `D3D12_DRED_FLAG_DISABLE_AUTOBREADCRUMBS` Value: *(0x2)* Disables DRED auto breadcrumbs. |

<!-- d3d12-review-alert:end:diagnostics:D3D12-DRED-FLAGS-Constants:1 -->

<!-- d3d12-review-alert:begin:diagnostics:legacy-dred-flags-history:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> These flags belong to the legacy DRED 1.0 data layout. They were deprecated starting with Windows 10, version 1903. The versioned settings methods use the distinct `D3D12_DRED_ENABLEMENT` enumeration.

<!-- d3d12-review-alert:end:diagnostics:legacy-dred-flags-history:0 -->

#### D3D12_DEVICE_REMOVED_EXTENDED_DATA

```cpp
typedef struct D3D12_DEVICE_REMOVED_EXTENDED_DATA
{
    D3D12_DRED_FLAGS Flags; // Dred flags
    D3D12_AUTO_BREADCRUMB_NODE *pHeadAutoBreadcrumbNode; // Pointer to head of a linked list of auto-breadcrumb data
} D3D12_DEVICE_REMOVED_EXTENDED_DATA;
```

#### D3D12_DRED_PAGE_FAULT_FLAGS

```cpp
typedef enum D3D12_DRED_PAGE_FAULT_FLAGS
{
    D3D12_DRED_PAGE_FAULT_FLAGS_NONE = 0,
} D3D12_DRED_PAGE_FAULT_FLAGS;
```

#### D3D12_DRED_DEVICE_STATE

```cpp
typedef enum D3D12_DRED_DEVICE_STATE
{
    D3D12_DRED_DEVICE_STATE_UNKNOWN             = 0, // Only known if DRED event occurred
    D3D12_DRED_DEVICE_STATE_HUNG                = 3,
    D3D12_DRED_DEVICE_STATE_FAULT               = 6,
    D3D12_DRED_DEVICE_STATE_PAGEFAULT           = 7,
} D3D12_DRED_DEVICE_STATE;
```

#### D3D12_DRED_PAGE_FAULT_OUTPUT2

```cpp
typedef struct D3D12_DRED_PAGE_FAULT_OUTPUT2
{
    D3D12_GPU_VIRTUAL_ADDRESS PageFaultVA; //If the device removal was due to GPU Fault, this contains the VA of the faulting op
    const D3D12_DRED_ALLOCATION_NODE1 *pHeadExistingAllocationNode;
    const D3D12_DRED_ALLOCATION_NODE1 *pHeadRecentFreedAllocationNode;
    D3D12_DRED_PAGE_FAULT_FLAGS PageFaultFlags;

} D3D12_DRED_PAGE_FAULT_OUTPUT2;
```

#### D3D12_DEVICE_REMOVED_EXTENDED_DATA3

```cpp
typedef struct D3D12_DEVICE_REMOVED_EXTENDED_DATA3
{
    HRESULT DeviceRemovedReason;
    D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT1 AutoBreadcrumbsOutput;
    D3D12_DRED_PAGE_FAULT_OUTPUT2 PageFaultOutput;
    D3D12_DRED_DEVICE_STATE DeviceState;
} D3D12_DEVICE_REMOVED_EXTENDED_DATA3;
```

#### D3D12_VERSIONED_DEVICE_REMOVED_EXTENDED_DATA
Encapsulates the versioned DRED data.  The appropriate unioned Dred_* member must match the value of Version.

```cpp
struct D3D12_VERSIONED_DEVICE_REMOVED_EXTENDED_DATA
{
    D3D12_DRED_VERSION Version;
    union
    {
        D3D12_DEVICE_REMOVED_EXTENDED_DATA Dred_1_0;
        D3D12_DEVICE_REMOVED_EXTENDED_DATA1 Dred_1_1;
        D3D12_DEVICE_REMOVED_EXTENDED_DATA2 Dred_1_2;
        D3D12_DEVICE_REMOVED_EXTENDED_DATA3 Dred_1_3;
    };
};
```

<!-- d3d12-review-alert:begin:diagnostics:dred-versioned-type:3 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Members  | Description                                                                                |
> |----------|--------------------------------------------------------------------------------------------|
> | Dred_1_0 | DRED data as of Windows 10 version 1809.  Valid only if Version is D3D12_DRED_VERSION_1_0. |
> | Dred_1_1 | DRED data as of Windows 10 19H1.  Valid only if Version is D3D12_DRED_VERSION_1_1.         |
> | Dred_1_2 | DRED version 1.2. Valid only if Version is D3D12_DRED_VERSION_1_2. |
> | Dred_1_3 | DRED version 1.3. Valid only if Version is D3D12_DRED_VERSION_1_3. |

<!-- d3d12-review-alert:end:diagnostics:dred-versioned-type:3 -->

<!-- d3d12-review-alert:begin:diagnostics:dred-v13-fields:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12_DRED_PAGE_FAULT_OUTPUT2` retains the fault VA and both allocation lists from output version 1, and adds `PageFaultFlags`. The declared flags value is `D3D12_DRED_PAGE_FAULT_FLAGS_NONE` (0); no additional flag behavior is defined here. `PageFaultVA` describes a reported GPU page fault, not a valid fault address for every kind of removal.

<!-- d3d12-review-alert:end:diagnostics:dred-v13-fields:0 -->

<!-- d3d12-review-alert:begin:diagnostics:dred-v13-fields:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12_DEVICE_REMOVED_EXTENDED_DATA3` combines the removal reason, breadcrumb output version 1, page-fault output version 2 and device state. `D3D12_VERSIONED_DEVICE_REMOVED_EXTENDED_DATA::Version` selects the matching union member; the members are not interchangeable. The legacy `D3D12_DEVICE_REMOVED_EXTENDED_DATA` stores the legacy flags and breadcrumb head. None of these layouts transfers ownership of its pointed-to data to the caller.

<!-- d3d12-review-alert:end:diagnostics:dred-v13-fields:1 -->

<a id="debug-messages"></a>

## Debug message handling

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-summary:0 -->An information-queue interface stores, retrieves, and filters debug messages. The queue consists of a message queue, an optional storage filter stack, and an optional retrieval filter stack.<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-summary:0 --></ins>

### Context

This interface is obtained by querying it from the [ID3D12Device](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nn-d3d12-id3d12device) using `IUnknown::QueryInterface`. The `ID3D12Debug` layer must be enabled through `ID3D12Debug::EnableDebugLayer` for that operation to succeed.

<a id="infoqueue-scope"></a>

### Scope of the information queue

<!-- d3d12-review-alert:begin:diagnostics:infoqueue-scope:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The device's `ID3D12InfoQueue` controls messages associated with that device/producer. Storage, counters, filter stacks and callback delivery must not be assumed to be one process-global setting merely because infrastructure is shared. The callback mechanism supports multiple registrations without replacing another component's callback. A callback cookie identifies a registered callback; it is not a device or SDK-selection identifier.

<!-- d3d12-review-alert:end:diagnostics:infoqueue-scope:0 -->

<a id="infoqueue-filtering"></a>

### Storage, retrieval and debug output

<!-- d3d12-review-alert:begin:diagnostics:filtering-rules:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A storage filter is applied when a message is produced. A message denied by it is not stored. A retrieval filter selects among already stored messages; changing it does not delete them and does not retroactively change storage-filter counters. Debug text and break processing follow the storage/debug-output path, not the retrieval view.

<!-- d3d12-review-alert:end:diagnostics:filtering-rules:0 -->

<!-- d3d12-review-alert:begin:diagnostics:filtering-rules:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> For a filter descriptor, an empty allow list accepts all messages. A nonempty allow list accepts a message matching any listed category, severity or ID (OR, not AND). A match in any deny list rejects the message even if an allow entry matches. Thus an entirely empty filter permits all messages. Each nonzero `NumCategories`, `NumSeverities` or `NumIDs` requires an array of at least that many elements. Zero-count arrays are not read.

<!-- d3d12-review-alert:end:diagnostics:filtering-rules:1 -->

<!-- d3d12-review-alert:begin:diagnostics:filtering-rules:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `AddStorageFilterEntries` and `AddRetrievalFilterEntries` merge entries into the top filter; they do not push a new stack element when a top already exists. If the stack is empty, adding entries first creates a top filter. Push-empty creates a new permissive top; push-copy duplicates the current top; push-filter copies the supplied descriptor and arrays. The caller retains its input storage. Clear empties the top filter without popping it; pop restores the preceding top. Popping an empty stack has no effect. An empty stack has no filtering restriction of its own. Stack-size getters count filters, not bytes. The ordinary debug-layer default suppresses `INFO` messages; preexisting system/tool filters can change the effective initial filtering. Without such preexisting filters, storage starts with that one default filter and retrieval starts with an empty stack. Break conditions start disabled and debug output starts unmuted; tool/system overrides can alter effective diagnostic behavior.

<!-- d3d12-review-alert:end:diagnostics:filtering-rules:2 -->

<!-- d3d12-review-alert:begin:diagnostics:filtering-rules:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A filter-update call takes one `D3D12_INFO_QUEUE_FILTER`, not an array of filter structures. The update's descriptor pointer is required; a null descriptor, or a null list pointer with a nonzero list count, is invalid and returns `E_INVALIDARG`. A failed push does not establish a new top filter.

<!-- d3d12-review-alert:end:diagnostics:filtering-rules:3 -->

<!-- d3d12-review-alert:begin:diagnostics:filtering-rules:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Debug-output muting suppresses debug text, not configured breaks or storage/retrieval, nor callbacks registered with `IGNORE_FILTERS`. A callback registered with `NONE` is filtered like debug text, including this output-path suppression.

<!-- d3d12-review-alert:end:diagnostics:filtering-rules:4 -->

<!-- d3d12-review-alert:begin:diagnostics:injected-message-text:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `AddMessage` and `AddApplicationMessage` take a readable null-terminated narrow description. The queue copies the message text; the application retains ownership of its input string. These messages follow storage filtering, count limits, break settings and output muting just as messages produced by the debug layer do. Injection does not force a filtered-out message into storage or the retrieval view.

<!-- d3d12-review-alert:end:diagnostics:injected-message-text:0 -->

<a id="infoqueue-counts-and-buffers"></a>

### Counts, limits and caller buffers

<!-- d3d12-review-alert:begin:diagnostics:count-buffer-rules:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `GetNumStoredMessages` is the current stored count. `GetNumStoredMessagesAllowedByRetrievalFilter` is the current filtered count. `GetNumMessagesAllowedByStorageFilter` and `GetNumMessagesDeniedByStorageFilter` are cumulative processing counters, not current queue sizes. `GetNumMessagesDiscardedByMessageCountLimit` counts messages lost to the configured limit, including old messages evicted when a new allowed message arrives at capacity and messages removed when the limit is reduced. A storage-denied message increments the denied counter but neither the allowed nor the limit-discard counter. At capacity, an allowed message increments the allowed counter, evicts the oldest stored message for that producer and increments the limit-discard counter; the stored count stays at the limit. Clearing stored messages resets the current stored and retrieval-visible counts to zero, but does not reset those cumulative counters. The counters belong to the owning queue/producer lifetime, not to a retrieval-filter snapshot.

<!-- d3d12-review-alert:end:diagnostics:count-buffer-rules:0 -->

<!-- d3d12-review-alert:begin:diagnostics:count-buffer-rules:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The default count limit is `D3D12_INFO_QUEUE_DEFAULT_MESSAGE_COUNT_LIMIT` (1024). `UINT64(-1)` means unlimited. Zero is invalid and returns `E_INVALIDARG`, leaving the limit unchanged. Lowering a finite limit below the current count discards the oldest excess messages.

<!-- d3d12-review-alert:end:diagnostics:count-buffer-rules:1 -->

<!-- d3d12-review-alert:begin:diagnostics:count-buffer-rules:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `GetMessage` indexes the retrieval-filtered sequence: valid indices satisfy `0 <= MessageIndex < GetNumStoredMessagesAllowedByRetrievalFilter()`. A count of zero has no valid index. It does not remove a message. `pMessageByteLength` is required; its input is the caller buffer capacity in bytes, including the `D3D12_MESSAGE` structure and description. With `pMessage == nullptr`, the method reports the required size without writing a message. On success, `pDescription` points into the caller's returned buffer, not separately allocated runtime storage; `DescriptionByteLength` includes the terminating null byte. The description is narrow text. Keep the buffer alive while using that pointer.

<!-- d3d12-review-alert:end:diagnostics:count-buffer-rules:2 -->

<!-- d3d12-review-alert:begin:diagnostics:count-buffer-rules:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `GetStorageFilter` and `GetRetrievalFilter` similarly accept a null `pFilter` to report the required byte size through `pFilterByteLength`. A nonnull destination must hold both `D3D12_INFO_QUEUE_FILTER` and all returned arrays; its list pointers refer inside that caller-owned buffer. The byte-length pointer is required. A size query is not a transaction with the later read: messages or filters can change between calls. Invalid message indices or insufficient buffers fail rather than supplying a complete result; a size-query success is not a stored-message removal. The individual methods define their exact `HRESULT` and length-update rules: a short GetMessage read leaves the caller's length unchanged, whereas a short filter read reports its required byte size. No failed call generally clears output fields.

<!-- d3d12-review-alert:end:diagnostics:count-buffer-rules:3 -->

<a id="id3d12infoqueue-addapplicationmessage"></a>

### ID3D12InfoQueue::AddApplicationMessage

#### Declaration

```cpp
HRESULT AddApplicationMessage(D3D12_MESSAGE_SEVERITY Severity, LPCSTR pDescription);
```

#### Behavior

Adds a user-defined message to the message queue and sends that message to debug output.

#### Parameters

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-AddApplicationMessage-Parameters:1 -->`Severity` (input)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-AddApplicationMessage-Parameters:1 --></ins>

Type: **[D3D12_MESSAGE_SEVERITY](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/ne-d3d12sdklayers-d3d12_message_severity)**

Severity of a message.

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-AddApplicationMessage-Parameters:4 -->`pDescription` (input)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-AddApplicationMessage-Parameters:4 --></ins>

Type: **LPCSTR**

Specifies the message string.

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

<a id="id3d12infoqueue-addmessage"></a>

### ID3D12InfoQueue::AddMessage

#### Declaration

```cpp
HRESULT AddMessage(D3D12_MESSAGE_CATEGORY Category, D3D12_MESSAGE_SEVERITY Severity, D3D12_MESSAGE_ID ID, LPCSTR pDescription);
```

#### Behavior

Adds a debug message to the message queue and sends that message to debug output.

#### Parameters

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-AddMessage-Parameters:1 -->`Category` (input)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-AddMessage-Parameters:1 --></ins>

Type: **[D3D12_MESSAGE_CATEGORY](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/ne-d3d12sdklayers-d3d12_message_category)**

Category of a message.

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-AddMessage-Parameters:4 -->`Severity` (input)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-AddMessage-Parameters:4 --></ins>

Type: **[D3D12_MESSAGE_SEVERITY](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/ne-d3d12sdklayers-d3d12_message_severity)**

Severity of a message.

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-AddMessage-Parameters:7 -->`ID` (input)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-AddMessage-Parameters:7 --></ins>

Type: **[D3D12_MESSAGE_ID](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/ne-d3d12sdklayers-d3d12_message_id)**

Unique identifier of a message.

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-AddMessage-Parameters:10 -->`pDescription` (input)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-AddMessage-Parameters:10 --></ins>

Type: **LPCSTR**

User-defined message.

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

#### Context

This method is used by the runtime's internal mechanisms to add debug messages to the message queue and send them to debug output. For applications to add their own custom messages to the message queue and send them to debug output, call [ID3D12InfoQueue::AddApplicationMessage](#id3d12infoqueue-addapplicationmessage).

<a id="id3d12infoqueue-addretrievalfilterentries"></a>

### ID3D12InfoQueue::AddRetrievalFilterEntries

#### Declaration

```cpp
HRESULT AddRetrievalFilterEntries(D3D12_INFO_QUEUE_FILTER* pFilter);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-AddRetrievalFilterEntries-summary:0 -->Add retrieval-filter entries to the top of the retrieval-filter stack.<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-AddRetrievalFilterEntries-summary:0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-AddRetrievalFilterEntries-Parameters:1 -->`pFilter` (input)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-AddRetrievalFilterEntries-Parameters:1 --></ins>

Type: **[D3D12_INFO_QUEUE_FILTER](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/ns-d3d12sdklayers-d3d12_info_queue_filter)\***

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-AddRetrievalFilterEntries-Parameters:3 -->Pointer to one filter descriptor; its counted member arrays specify the entries to add.<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-AddRetrievalFilterEntries-Parameters:3 --></ins>

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

#### Context

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-AddRetrievalFilterEntries-Remarks:1 -->The following schematic fragment shows how to use this method. The ellipses stand for application-selected enum values, not literal C++ initializers; the fragment appears in an `HRESULT`-returning function:<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-AddRetrievalFilterEntries-Remarks:1 --></ins>

```cpp

D3D12_MESSAGE_CATEGORY cats[] = { ..., ..., ... };
D3D12_MESSAGE_SEVERITY sevs[] = { ..., ..., ... };
D3D12_MESSAGE_ID ids[] = { ..., ..., ... };

D3D12_INFO_QUEUE_FILTER filter;
memset( &filter, 0, sizeof(filter) );

// To set the type of messages to allow,
// set filter.AllowList as follows:
filter.AllowList.NumCategories = _countof(cats);
filter.AllowList.pCategoryList = cats;
filter.AllowList.NumSeverities = _countof(sevs);
filter.AllowList.pSeverityList = sevs;
filter.AllowList.NumIDs = _countof(ids);
filter.AllowList.pIDList = ids;

// To set the type of messages to deny, set filter.DenyList
// similarly to the preceding filter.AllowList.

// The following single call sets all of the preceding information.
HRESULT hr = infoQueue->AddRetrievalFilterEntries( &filter );
if (FAILED(hr))
    return hr;

```

<a id="id3d12infoqueue-addstoragefilterentries"></a>

### ID3D12InfoQueue::AddStorageFilterEntries

#### Declaration

```cpp
HRESULT AddStorageFilterEntries(D3D12_INFO_QUEUE_FILTER* pFilter);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-AddStorageFilterEntries-summary:0 -->Add storage-filter entries to the top of the storage-filter stack.<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-AddStorageFilterEntries-summary:0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-AddStorageFilterEntries-Parameters:1 -->`pFilter` (input)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-AddStorageFilterEntries-Parameters:1 --></ins>

Type: **[D3D12_INFO_QUEUE_FILTER](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/ns-d3d12sdklayers-d3d12_info_queue_filter)\***

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-AddStorageFilterEntries-Parameters:3 -->Pointer to one filter descriptor; its counted member arrays specify the entries to add.<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-AddStorageFilterEntries-Parameters:3 --></ins>

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

<a id="id3d12infoqueue-clearretrievalfilter"></a>

### ID3D12InfoQueue::ClearRetrievalFilter

#### Declaration

```cpp
void ClearRetrievalFilter();
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-ClearRetrievalFilter-summary:0 -->Clear the retrieval filter at the top of the retrieval-filter stack.<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-ClearRetrievalFilter-summary:0 --></ins>

#### Return values

None

<a id="id3d12infoqueue-clearstoragefilter"></a>

### ID3D12InfoQueue::ClearStorageFilter

#### Declaration

```cpp
void ClearStorageFilter();
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-ClearStorageFilter-summary:0 -->Clear the storage filter at the top of the storage-filter stack.<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-ClearStorageFilter-summary:0 --></ins>

#### Return values

None

<a id="id3d12infoqueue-clearstoredmessages"></a>

### ID3D12InfoQueue::ClearStoredMessages

#### Declaration

```cpp
void ClearStoredMessages();
```

#### Behavior

Clear all messages from the message queue.

#### Return values

None

<a id="id3d12infoqueue-getbreakoncategory"></a>

### ID3D12InfoQueue::GetBreakOnCategory

#### Declaration

```cpp
BOOL GetBreakOnCategory(D3D12_MESSAGE_CATEGORY Category);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetBreakOnCategory-summary:0 -->Gets whether breaking is enabled for a message category when a message with that category passes through the storage filter.<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetBreakOnCategory-summary:0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetBreakOnCategory-Parameters:1 -->`Category` (input)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetBreakOnCategory-Parameters:1 --></ins>

Type: **[D3D12_MESSAGE_CATEGORY](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/ne-d3d12sdklayers-d3d12_message_category)**

Message category to break on.

#### Return values

Type: **BOOL**

Whether this breaking condition is turned on or off (true for on, false for off).

<a id="id3d12infoqueue-getbreakonid"></a>

### ID3D12InfoQueue::GetBreakOnID

#### Declaration

```cpp
BOOL GetBreakOnID(D3D12_MESSAGE_ID ID);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetBreakOnID-summary:0 -->Gets whether breaking is enabled for a message identifier when a message with that identifier passes through the storage filter.<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetBreakOnID-summary:0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetBreakOnID-Parameters:1 -->`ID` (input)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetBreakOnID-Parameters:1 --></ins>

Type: **[D3D12_MESSAGE_ID](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/ne-d3d12sdklayers-d3d12_message_id)**

Message identifier to break on.

#### Return values

Type: **BOOL**

Whether this breaking condition is turned on or off (true for on, false for off).

<a id="id3d12infoqueue-getbreakonseverity"></a>

### ID3D12InfoQueue::GetBreakOnSeverity

#### Declaration

```cpp
BOOL GetBreakOnSeverity(D3D12_MESSAGE_SEVERITY Severity);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetBreakOnSeverity-summary:0 -->Gets whether breaking is enabled for a message severity when a message with that severity passes through the storage filter.<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetBreakOnSeverity-summary:0 --></ins>

#### Parameters

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetBreakOnSeverity-Parameters:1 -->`Severity` (input)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetBreakOnSeverity-Parameters:1 --></ins>

Type: **[D3D12_MESSAGE_SEVERITY](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/ne-d3d12sdklayers-d3d12_message_severity)**

Message severity level to break on.

#### Return values

Type: **BOOL**

Whether this breaking condition is turned on or off (true for on, false for off).

<a id="id3d12infoqueue-getmessage"></a>

### ID3D12InfoQueue::GetMessage

#### Declaration

```cpp
HRESULT GetMessage(UINT64 MessageIndex, D3D12_MESSAGE* pMessage, SIZE_T* pMessageByteLength);
```

#### Behavior

Get a message from the message queue.

#### Parameters

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetMessage-Parameters:1 -->`MessageIndex` (input)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetMessage-Parameters:1 --></ins>

Type: **UINT64**

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetMessage-Parameters:3 -->Index into message queue after an optional retrieval filter has been applied. This can be between 0 (inclusive) and the number of messages in the message queue that pass through the retrieval filter (exclusive) (which can be obtained with [GetNumStoredMessagesAllowedByRetrievalFilter](#id3d12infoqueue-getnumstoredmessagesallowedbyretrievalfilter)). 0 is the first message in the retrieval-filtered sequence.<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetMessage-Parameters:3 --></ins>

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetMessage-Parameters:4 -->`pMessage` (optional output)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetMessage-Parameters:4 --></ins>

Type: **[D3D12_MESSAGE](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/ns-d3d12sdklayers-d3d12_message)\***

Returned message.

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetMessage-Parameters:7 -->`pMessageByteLength` (input/output)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetMessage-Parameters:7 --></ins>

Type: **SIZE\_T\***

Size of *pMessage* in bytes.

#### Return values

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetMessage-Return-value:1 -->`pMessageByteLength` is a required readable/writable length pointer. The message-buffer paths require it even when the supplied capacity is zero.<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetMessage-Return-value:1 --></ins>

<!-- d3d12-review-alert:begin:diagnostics:ID3D12InfoQueue-GetMessage-Return-value:2 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Result | Condition | Length/output effect |
> | --- | --- | --- |
> | `S_FALSE` | Valid `MessageIndex`, `pMessage == nullptr`, valid length pointer | Reports the required total D3D12 message-buffer size through `*pMessageByteLength`; no message is copied. |
> | `S_OK` | Valid index and nonnull message buffer with sufficient capacity | Copies the message and its description into the caller buffer. `*pMessageByteLength` remains the input capacity; `DescriptionByteLength` describes the returned string. |
> | `E_INVALIDARG` | Index is outside the retrieval-filtered sequence, including index zero when no messages pass | Does not return a message or update the caller's length. |
> | `E_INVALIDARG` | Nonnull message buffer is too small | Does not return a complete message. The caller's length remains unchanged; this is not a required-size update on failure. |
> | `E_INVALIDARG` | Both `pMessage` and the required length pointer are null | No size or message can be returned. |
> | `E_OUTOFMEMORY` | Memory required to provide the result cannot be allocated | No complete message is returned; no general output-initialization guarantee is established. |

<!-- d3d12-review-alert:end:diagnostics:ID3D12InfoQueue-GetMessage-Return-value:2 -->

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetMessage-Return-value:3 -->With a nonnull `pMessage`, a null length pointer violates the required-pointer precondition and is not covered by a guaranteed error-`HRESULT` path. No failing call establishes a valid message or guarantees zeroed output fields. A prior size query does not reserve a message or its size: the later read can fail, and the caller must check its result independently.<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetMessage-Return-value:3 --></ins>

#### Context

This method does not remove any messages from the message queue.

This method gets messages from the message queue after an optional retrieval filter has been applied.

Applications should call this method twice to retrieve a message - first to obtain the size of the message and second to get the message. Here is a typical example:

```cpp
#include <cstdlib>
#include <memory>

HRESULT ReadFirstMessage(ID3D12InfoQueue* pInfoQueue)
{
    SIZE_T messageLength = 0;
    HRESULT hr = pInfoQueue->GetMessage(0, nullptr, &messageLength);
    if (FAILED(hr))
        return hr;

    std::unique_ptr<void, decltype(&std::free)> storage(
        std::malloc(messageLength), &std::free);
    if (!storage)
        return E_OUTOFMEMORY;

    auto* pMessage = static_cast<D3D12_MESSAGE*>(storage.get());
    hr = pInfoQueue->GetMessage(0, pMessage, &messageLength);
    if (FAILED(hr))
        return hr;

    // Inspect pMessage and its description while storage is alive.
    return hr;
}
```

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetMessage-Remarks:5 -->The example requires a valid `pInfoQueue`. If the retrieval view is empty or a subsequent change makes the read invalid or its buffer too small, the corresponding failure is returned, not hidden by an automatic retry. A changed message that still fits the buffer can be read successfully. `S_FALSE` from the size query is a successful size-only result. The allocation is released on both success and every later failure, and the returned description pointer must not outlive that allocation.<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetMessage-Remarks:5 --></ins>

<a id="id3d12infoqueue-getmessagecountlimit"></a>

### ID3D12InfoQueue::GetMessageCountLimit

#### Declaration

```cpp
UINT64 GetMessageCountLimit();
```

#### Behavior

Get the maximum number of messages that can be added to the message queue.

#### Return values

Type: **UINT64**

Maximum number of messages that can be added to the queue. -1 means no limit.

When the number of messages in the message queue has reached the maximum limit, new messages coming in will push old messages out.

<a id="id3d12infoqueue-getmutedebugoutput"></a>

### ID3D12InfoQueue::GetMuteDebugOutput

#### Declaration

```cpp
BOOL GetMuteDebugOutput();
```

#### Behavior

Get a boolean that determines if debug output is on or off.

#### Return values

Type: **BOOL**

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetMuteDebugOutput-Return-value:2 -->Whether debug output is muted (`TRUE` for muted, `FALSE` for unmuted).<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetMuteDebugOutput-Return-value:2 --></ins>

<a id="id3d12infoqueue-getnummessagesallowedbystoragefilter"></a>

### ID3D12InfoQueue::GetNumMessagesAllowedByStorageFilter

#### Declaration

```cpp
UINT64 GetNumMessagesAllowedByStorageFilter();
```

#### Behavior

Get the number of messages that were allowed to pass through a storage filter.

#### Return values

Type: **UINT64**

Number of messages allowed by a storage filter.

<a id="id3d12infoqueue-getnummessagesdeniedbystoragefilter"></a>

### ID3D12InfoQueue::GetNumMessagesDeniedByStorageFilter

#### Declaration

```cpp
UINT64 GetNumMessagesDeniedByStorageFilter();
```

#### Behavior

Get the number of messages that were denied passage through a storage filter.

#### Return values

Type: **UINT64**

Number of messages denied by a storage filter.

<a id="id3d12infoqueue-getnummessagesdiscardedbymessagecountlimit"></a>

### ID3D12InfoQueue::GetNumMessagesDiscardedByMessageCountLimit

#### Declaration

```cpp
UINT64 GetNumMessagesDiscardedByMessageCountLimit();
```

#### Behavior

Get the number of messages that were discarded due to the message count limit.

#### Return values

Type: **UINT64**

Number of messages discarded.

#### Context

Get and set the message count limit with [GetMessageCountLimit](#id3d12infoqueue-getmessagecountlimit) and [SetMessageCountLimit](#id3d12infoqueue-setmessagecountlimit), respectively.

<a id="id3d12infoqueue-getnumstoredmessages"></a>

### ID3D12InfoQueue::GetNumStoredMessages

#### Declaration

```cpp
UINT64 GetNumStoredMessages();
```

#### Behavior

Get the number of messages currently stored in the message queue.

#### Return values

Type: **UINT64**

Number of messages currently stored in the message queue.

<a id="id3d12infoqueue-getnumstoredmessagesallowedbyretrievalfilter"></a>

### ID3D12InfoQueue::GetNumStoredMessagesAllowedByRetrievalFilter

#### Declaration

```cpp
UINT64 GetNumStoredMessagesAllowedByRetrievalFilter();
```

#### Behavior

Get the number of messages that are able to pass through a retrieval filter.

#### Return values

Type: **UINT64**

Number of messages allowed by a retrieval filter.

<a id="id3d12infoqueue-getretrievalfilter"></a>

### ID3D12InfoQueue::GetRetrievalFilter

#### Declaration

```cpp
HRESULT GetRetrievalFilter(D3D12_INFO_QUEUE_FILTER* pFilter, SIZE_T* pFilterByteLength);
```

#### Behavior

Get the retrieval filter at the top of the retrieval-filter stack.

#### Parameters

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetRetrievalFilter-Parameters:1 -->`pFilter` (optional output)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetRetrievalFilter-Parameters:1 --></ins>

Type: **[D3D12_INFO_QUEUE_FILTER](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/ns-d3d12sdklayers-d3d12_info_queue_filter)\***

Retrieval filter at the top of the retrieval-filter stack.

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetRetrievalFilter-Parameters:4 -->`pFilterByteLength` (input/output)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetRetrievalFilter-Parameters:4 --></ins>

Type: **SIZE\_T\***

Size of the retrieval filter in bytes. If *pFilter* is NULL, the size of the retrieval filter will be output to this parameter.

#### Return values

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetRetrievalFilter-Return-value:1 -->`pFilterByteLength` is a required readable/writable length pointer.<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetRetrievalFilter-Return-value:1 --></ins>

<!-- d3d12-review-alert:begin:diagnostics:ID3D12InfoQueue-GetRetrievalFilter-Return-value:2 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Result | Condition | Length/output effect |
> | --- | --- | --- |
> | `S_FALSE` | `pFilter == nullptr` with a valid length pointer | Writes the total required bytes for the filter structure and all counted arrays to `*pFilterByteLength`; no filter is copied. |
> | `S_OK` | Nonnull filter buffer with sufficient capacity | Copies the structure and arrays, points the returned lists into that caller-owned buffer, and writes the required/used byte count to `*pFilterByteLength`. |
> | `E_INVALIDARG` | Nonnull filter buffer is too small | Updates `*pFilterByteLength` with the required size; does not supply a complete filter. |
> | `E_INVALIDARG` | `pFilterByteLength == nullptr` | No size can be written. |
> | `E_OUTOFMEMORY` | Memory required to provide the result cannot be allocated | No complete filter is returned; no general output-initialization guarantee is established. |

<!-- d3d12-review-alert:end:diagnostics:ID3D12InfoQueue-GetRetrievalFilter-Return-value:2 -->

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetRetrievalFilter-Return-value:3 -->An empty top filter, including an empty stack viewed as an empty filter, still requires the filter structure's bytes, but has zero counted list elements. A size query does not freeze the filter before the later read. Do not read failed output as a valid filter or assume failed output fields are zero.<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetRetrievalFilter-Return-value:3 --></ins>

<a id="id3d12infoqueue-getretrievalfilterstacksize"></a>

### ID3D12InfoQueue::GetRetrievalFilterStackSize

#### Declaration

```cpp
UINT GetRetrievalFilterStackSize();
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetRetrievalFilterStackSize-summary:0 -->Get the number of filters in the retrieval-filter stack.<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetRetrievalFilterStackSize-summary:0 --></ins>

#### Return values

Type: **UINT**

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetRetrievalFilterStackSize-Return-value:2 -->Number of filters in the retrieval-filter stack.<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetRetrievalFilterStackSize-Return-value:2 --></ins>

<a id="id3d12infoqueue-getstoragefilter"></a>

### ID3D12InfoQueue::GetStorageFilter

#### Declaration

```cpp
HRESULT GetStorageFilter(D3D12_INFO_QUEUE_FILTER* pFilter, SIZE_T* pFilterByteLength);
```

#### Behavior

Get the storage filter at the top of the storage-filter stack.

#### Parameters

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetStorageFilter-Parameters:1 -->`pFilter` (optional output)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetStorageFilter-Parameters:1 --></ins>

Type: **[D3D12_INFO_QUEUE_FILTER](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/ns-d3d12sdklayers-d3d12_info_queue_filter)\***

Storage filter at the top of the storage-filter stack.

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetStorageFilter-Parameters:4 -->`pFilterByteLength` (input/output)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetStorageFilter-Parameters:4 --></ins>

Type: **SIZE\_T\***

Size of the storage filter in bytes. If *pFilter* is NULL, the size of the storage filter will be output to this parameter.

#### Return values

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetStorageFilter-Return-value:1 -->`pFilterByteLength` is a required readable/writable length pointer.<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetStorageFilter-Return-value:1 --></ins>

<!-- d3d12-review-alert:begin:diagnostics:ID3D12InfoQueue-GetStorageFilter-Return-value:2 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Result | Condition | Length/output effect |
> | --- | --- | --- |
> | `S_FALSE` | `pFilter == nullptr` with a valid length pointer | Writes the total required bytes for the filter structure and all counted arrays to `*pFilterByteLength`; no filter is copied. |
> | `S_OK` | Nonnull filter buffer with sufficient capacity | Copies the structure and arrays, points the returned lists into that caller-owned buffer, and writes the required/used byte count to `*pFilterByteLength`. |
> | `E_INVALIDARG` | Nonnull filter buffer is too small | Updates `*pFilterByteLength` with the required size; does not supply a complete filter. |
> | `E_INVALIDARG` | `pFilterByteLength == nullptr` | No size can be written. |
> | `E_OUTOFMEMORY` | Memory required to provide the result cannot be allocated | No complete filter is returned; no general output-initialization guarantee is established. |

<!-- d3d12-review-alert:end:diagnostics:ID3D12InfoQueue-GetStorageFilter-Return-value:2 -->

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetStorageFilter-Return-value:3 -->An empty top filter, including an empty stack viewed as an empty filter, still requires the filter structure's bytes, but has zero counted list elements. A size query does not freeze the filter before the later read. Do not read failed output as a valid filter or assume failed output fields are zero.<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetStorageFilter-Return-value:3 --></ins>

<a id="id3d12infoqueue-getstoragefilterstacksize"></a>

### ID3D12InfoQueue::GetStorageFilterStackSize

#### Declaration

```cpp
UINT GetStorageFilterStackSize();
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetStorageFilterStackSize-summary:0 -->Get the number of filters in the storage-filter stack.<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetStorageFilterStackSize-summary:0 --></ins>

#### Return values

Type: **UINT**

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-GetStorageFilterStackSize-Return-value:2 -->Number of filters in the storage-filter stack.<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-GetStorageFilterStackSize-Return-value:2 --></ins>

<a id="id3d12infoqueue-popretrievalfilter"></a>

### ID3D12InfoQueue::PopRetrievalFilter

#### Declaration

```cpp
void PopRetrievalFilter();
```

#### Behavior

Pop a retrieval filter from the top of the retrieval-filter stack.

#### Return values

None

<a id="id3d12infoqueue-popstoragefilter"></a>

### ID3D12InfoQueue::PopStorageFilter

#### Declaration

```cpp
void PopStorageFilter();
```

#### Behavior

Pop a storage filter from the top of the storage-filter stack.

#### Return values

None

<a id="id3d12infoqueue-pushcopyofretrievalfilter"></a>

### ID3D12InfoQueue::PushCopyOfRetrievalFilter

#### Declaration

```cpp
HRESULT PushCopyOfRetrievalFilter();
```

#### Behavior

Push a copy of retrieval filter currently on the top of the retrieval-filter stack onto the retrieval-filter stack.

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

<a id="id3d12infoqueue-pushcopyofstoragefilter"></a>

### ID3D12InfoQueue::PushCopyOfStorageFilter

#### Declaration

```cpp
HRESULT PushCopyOfStorageFilter();
```

#### Behavior

Push a copy of storage filter currently on the top of the storage-filter stack onto the storage-filter stack.

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

<a id="id3d12infoqueue-pushemptyretrievalfilter"></a>

### ID3D12InfoQueue::PushEmptyRetrievalFilter

#### Declaration

```cpp
HRESULT PushEmptyRetrievalFilter();
```

#### Behavior

Push an empty retrieval filter onto the retrieval-filter stack.

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

#### Context

An empty retrieval filter allows all messages to pass through.

<a id="id3d12infoqueue-pushemptystoragefilter"></a>

### ID3D12InfoQueue::PushEmptyStorageFilter

#### Declaration

```cpp
HRESULT PushEmptyStorageFilter();
```

#### Behavior

Push an empty storage filter onto the storage-filter stack.

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

#### Context

An empty storage filter allows all messages to pass through.

<a id="id3d12infoqueue-pushretrievalfilter"></a>

### ID3D12InfoQueue::PushRetrievalFilter

#### Declaration

```cpp
HRESULT PushRetrievalFilter(D3D12_INFO_QUEUE_FILTER* pFilter);
```

#### Behavior

Push a retrieval filter onto the retrieval-filter stack.

#### Parameters

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-PushRetrievalFilter-Parameters:1 -->`pFilter` (input)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-PushRetrievalFilter-Parameters:1 --></ins>

Type: **[D3D12_INFO_QUEUE_FILTER](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/ns-d3d12sdklayers-d3d12_info_queue_filter)\***

Pointer to a retrieval filter.

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

<a id="id3d12infoqueue-pushstoragefilter"></a>

### ID3D12InfoQueue::PushStorageFilter

#### Declaration

```cpp
HRESULT PushStorageFilter(D3D12_INFO_QUEUE_FILTER* pFilter);
```

#### Behavior

Push a storage filter onto the storage-filter stack.

#### Parameters

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-PushStorageFilter-Parameters:1 -->`pFilter` (input)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-PushStorageFilter-Parameters:1 --></ins>

Type: **[D3D12_INFO_QUEUE_FILTER](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/ns-d3d12sdklayers-d3d12_info_queue_filter)\***

Pointer to a storage filter.

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

<a id="id3d12infoqueue-setbreakoncategory"></a>

### ID3D12InfoQueue::SetBreakOnCategory

#### Declaration

```cpp
HRESULT SetBreakOnCategory(D3D12_MESSAGE_CATEGORY Category, BOOL bEnable);
```

#### Behavior

Set a message category to break on when a message with that category passes through the storage filter.

#### Parameters

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-SetBreakOnCategory-Parameters:1 -->`Category` (input)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-SetBreakOnCategory-Parameters:1 --></ins>

Type: **[D3D12_MESSAGE_CATEGORY](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/ne-d3d12sdklayers-d3d12_message_category)**

Message category to break on.

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-SetBreakOnCategory-Parameters:4 -->`bEnable` (input)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-SetBreakOnCategory-Parameters:4 --></ins>

Type: **BOOL**

Turns this breaking condition on or off (true for on, false for off).

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

<a id="id3d12infoqueue-setbreakonid"></a>

### ID3D12InfoQueue::SetBreakOnID

#### Declaration

```cpp
HRESULT SetBreakOnID(D3D12_MESSAGE_ID ID, BOOL bEnable);
```

#### Behavior

Set a message identifier to break on when a message with that identifier passes through the storage filter.

#### Parameters

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-SetBreakOnID-Parameters:1 -->`ID` (input)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-SetBreakOnID-Parameters:1 --></ins>

Type: **[D3D12_MESSAGE_ID](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/ne-d3d12sdklayers-d3d12_message_id)**

Message identifier to break on.

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-SetBreakOnID-Parameters:4 -->`bEnable` (input)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-SetBreakOnID-Parameters:4 --></ins>

Type: **BOOL**

Turns this breaking condition on or off (true for on, false for off).

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

<a id="id3d12infoqueue-setbreakonseverity"></a>

### ID3D12InfoQueue::SetBreakOnSeverity

#### Declaration

```cpp
HRESULT SetBreakOnSeverity(D3D12_MESSAGE_SEVERITY Severity, BOOL bEnable);
```

#### Behavior

Set a message severity level to break on when a message with that severity level passes through the storage filter.

#### Parameters

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-SetBreakOnSeverity-Parameters:1 -->`Severity` (input)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-SetBreakOnSeverity-Parameters:1 --></ins>

Type: **[D3D12_MESSAGE_SEVERITY](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/ne-d3d12sdklayers-d3d12_message_severity)**

A message severity level to break on.

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-SetBreakOnSeverity-Parameters:4 -->`bEnable` (input)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-SetBreakOnSeverity-Parameters:4 --></ins>

Type: **BOOL**

Turns this breaking condition on or off (true for on, false for off).

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

<a id="id3d12infoqueue-setmessagecountlimit"></a>

### ID3D12InfoQueue::SetMessageCountLimit

#### Declaration

```cpp
HRESULT SetMessageCountLimit(UINT64 MessageCountLimit);
```

#### Behavior

Set the maximum number of messages that can be added to the message queue.

#### Parameters

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-SetMessageCountLimit-Parameters:1 -->`MessageCountLimit` (input)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-SetMessageCountLimit-Parameters:1 --></ins>

Type: **UINT64**

Maximum number of messages that can be added to the message queue. -1 means no limit.

When the number of messages in the message queue has reached the maximum limit, new messages coming in will push old messages out.

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

<a id="id3d12infoqueue-setmutedebugoutput"></a>

### ID3D12InfoQueue::SetMuteDebugOutput

#### Declaration

```cpp
void SetMuteDebugOutput(BOOL bMute);
```

#### Behavior

Set a boolean that turns the debug output on or off.

#### Parameters

<ins><!-- d3d12-review-inline:begin:diagnostics:ID3D12InfoQueue-SetMuteDebugOutput-Parameters:1 -->`bMute` (input)<!-- d3d12-review-inline:end:diagnostics:ID3D12InfoQueue-SetMuteDebugOutput-Parameters:1 --></ins>

Type: **BOOL**

Disable/Enable the debug output (true to disable or mute the output, false to enable the output).

#### Return values

None

#### Context

This will stop messages that pass the storage filter from being printed out in the debug output, however those messages will still be added to the message queue.

<a id="infoqueue-types"></a>

### Message and filter types

#### D3D12_MESSAGE

A debug message in the Information Queue.

##### Syntax

```cpp
typedef struct D3D12_MESSAGE {
  D3D12_MESSAGE_CATEGORY Category;
  D3D12_MESSAGE_SEVERITY Severity;
  D3D12_MESSAGE_ID       ID;
  const char             *pDescription;
  SIZE_T                 DescriptionByteLength;
} D3D12_MESSAGE;
```

##### Members

`Category`

The category of the message. See [D3D12_MESSAGE_CATEGORY](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/ne-d3d12sdklayers-d3d12_message_category).

`Severity`

The severity of the message. See [D3D12_MESSAGE_SEVERITY](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/ne-d3d12sdklayers-d3d12_message_severity).

`ID`

The ID of the message. See [D3D12_MESSAGE_ID](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/ne-d3d12sdklayers-d3d12_message_id).

`pDescription`

The message string.

`DescriptionByteLength`

The length of *pDescription*, in bytes.

#### D3D12_INFO_QUEUE_FILTER

<ins><!-- d3d12-review-inline:begin:diagnostics:D3D12-INFO-QUEUE-FILTER-summary:0 -->Debug message filter; contains lists of message types to allow or deny.<!-- d3d12-review-inline:end:diagnostics:D3D12-INFO-QUEUE-FILTER-summary:0 --></ins>

##### Syntax

```cpp
typedef struct D3D12_INFO_QUEUE_FILTER {
  D3D12_INFO_QUEUE_FILTER_DESC AllowList;
  D3D12_INFO_QUEUE_FILTER_DESC DenyList;
} D3D12_INFO_QUEUE_FILTER;
```

##### Members

`AllowList`

Specifies types of messages that you want to allow. See [D3D12_INFO_QUEUE_FILTER_DESC](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/ns-d3d12sdklayers-d3d12_info_queue_filter_desc).

`DenyList`

Specifies types of messages that you want to deny.

#### D3D12_INFO_QUEUE_FILTER_DESC

Allow or deny certain types of messages to pass through a filter.

##### Syntax

```cpp
typedef struct D3D12_INFO_QUEUE_FILTER_DESC {
  UINT                   NumCategories;
  D3D12_MESSAGE_CATEGORY *pCategoryList;
  UINT                   NumSeverities;
  D3D12_MESSAGE_SEVERITY *pSeverityList;
  UINT                   NumIDs;
  D3D12_MESSAGE_ID       *pIDList;
} D3D12_INFO_QUEUE_FILTER_DESC;
```

##### Members

`NumCategories`

Number of message categories to allow or deny.

`pCategoryList`

Array of message categories to allow or deny. Array must have at least *NumCategories* members (see [D3D12_MESSAGE_CATEGORY](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/ne-d3d12sdklayers-d3d12_message_category)).

`NumSeverities`

Number of message severity levels to allow or deny.

`pSeverityList`

Array of message severity levels to allow or deny. Array must have at least *NumSeverities* members (see [D3D12_MESSAGE_SEVERITY](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/ne-d3d12sdklayers-d3d12_message_severity)).

`NumIDs`

Number of message IDs to allow or deny.

`pIDList`

Array of message IDs to allow or deny. Array must have at least *NumIDs* members (see [D3D12_MESSAGE_ID](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12sdklayers/ne-d3d12sdklayers-d3d12_message_id)).

#### D3D12_MESSAGE_CATEGORY

Specifies categories of debug messages. This will identify the category of a message when retrieving a message with [ID3D12InfoQueue::GetMessage](#id3d12infoqueue-getmessage) and when adding a message with [ID3D12InfoQueue::AddMessage](#id3d12infoqueue-addmessage). When creating an info queue filter, these values can be used to allow or deny any categories of messages to pass through the storage and retrieval filters.

##### Syntax

```cpp
typedef enum D3D12_MESSAGE_CATEGORY {
  D3D12_MESSAGE_CATEGORY_APPLICATION_DEFINED = 0,
  D3D12_MESSAGE_CATEGORY_MISCELLANEOUS,
  D3D12_MESSAGE_CATEGORY_INITIALIZATION,
  D3D12_MESSAGE_CATEGORY_CLEANUP,
  D3D12_MESSAGE_CATEGORY_COMPILATION,
  D3D12_MESSAGE_CATEGORY_STATE_CREATION,
  D3D12_MESSAGE_CATEGORY_STATE_SETTING,
  D3D12_MESSAGE_CATEGORY_STATE_GETTING,
  D3D12_MESSAGE_CATEGORY_RESOURCE_MANIPULATION,
  D3D12_MESSAGE_CATEGORY_EXECUTION,
  D3D12_MESSAGE_CATEGORY_SHADER
} D3D12_MESSAGE_CATEGORY;
```

##### Constants

<!-- d3d12-review-alert:begin:diagnostics:D3D12-MESSAGE-CATEGORY-Constants:1 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Constant and meaning |
> | --- |
> | `D3D12_MESSAGE_CATEGORY_APPLICATION_DEFINED` Value: *0* Indicates a user defined message, see [ID3D12InfoQueue::AddMessage](#id3d12infoqueue-addmessage). |
> | `D3D12_MESSAGE_CATEGORY_MISCELLANEOUS` |
> | `D3D12_MESSAGE_CATEGORY_INITIALIZATION` |
> | `D3D12_MESSAGE_CATEGORY_CLEANUP` |
> | `D3D12_MESSAGE_CATEGORY_COMPILATION` |
> | `D3D12_MESSAGE_CATEGORY_STATE_CREATION` |
> | `D3D12_MESSAGE_CATEGORY_STATE_SETTING` |
> | `D3D12_MESSAGE_CATEGORY_STATE_GETTING` |
> | `D3D12_MESSAGE_CATEGORY_RESOURCE_MANIPULATION` |
> | `D3D12_MESSAGE_CATEGORY_EXECUTION` |
> | `D3D12_MESSAGE_CATEGORY_SHADER` |

<!-- d3d12-review-alert:end:diagnostics:D3D12-MESSAGE-CATEGORY-Constants:1 -->

#### D3D12_MESSAGE_SEVERITY

Debug message severity levels for an information queue.

##### Syntax

```cpp
typedef enum D3D12_MESSAGE_SEVERITY {
  D3D12_MESSAGE_SEVERITY_CORRUPTION = 0,
  D3D12_MESSAGE_SEVERITY_ERROR,
  D3D12_MESSAGE_SEVERITY_WARNING,
  D3D12_MESSAGE_SEVERITY_INFO,
  D3D12_MESSAGE_SEVERITY_MESSAGE
} D3D12_MESSAGE_SEVERITY;
```

##### Constants

<!-- d3d12-review-alert:begin:diagnostics:D3D12-MESSAGE-SEVERITY-Constants:1 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Constant and meaning |
> | --- |
> | `D3D12_MESSAGE_SEVERITY_CORRUPTION` Value: *0* Indicates a corruption error. |
> | `D3D12_MESSAGE_SEVERITY_ERROR` Indicates an error. |
> | `D3D12_MESSAGE_SEVERITY_WARNING` Indicates a warning. |
> | `D3D12_MESSAGE_SEVERITY_INFO` Indicates an information message. |
> | `D3D12_MESSAGE_SEVERITY_MESSAGE` Indicates a message other than corruption, error, warning or information. |

<!-- d3d12-review-alert:end:diagnostics:D3D12-MESSAGE-SEVERITY-Constants:1 -->

<a id="d3d12-message-id"></a>

#### D3D12_MESSAGE_ID

<!-- d3d12-review-alert:begin:diagnostics:message-id:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12_MESSAGE_ID` is the typed numeric identifier namespace declared in [d3d12sdklayers.idl](https://raw.githubusercontent.com/microsoft/DirectX-Headers/461ef5138bd30922b44fbad77c4e47662812d2d5/include/directx/d3d12sdklayers.idl). IDs distinguish individual debug diagnostics. `D3D12_MESSAGE_ID_UNKNOWN` is 0 and `D3D12_MESSAGE_ID_STRING_FROM_APPLICATION` is 1. The enumeration is not a guarantee that every declared message is emitted, or that a diagnostic is produced without the applicable validation enabled. `AddApplicationMessage` uses category `APPLICATION_DEFINED` and `STRING_FROM_APPLICATION`; `AddMessage` accepts the supplied category, severity and ID.

<!-- d3d12-review-alert:end:diagnostics:message-id:0 -->

<a id="message-callbacks"></a>

## Message callbacks

<!-- d3d12-review-alert:begin:diagnostics:callback-overview:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `ID3D12InfoQueue1` inherits `ID3D12InfoQueue` and adds callback registration and unregistration. A callback is invoked at the time a debug message is produced.

<!-- d3d12-review-alert:end:diagnostics:callback-overview:0 -->

<a id="id3d12infoqueue1-registermessagecallback"></a>

### ID3D12InfoQueue1::RegisterMessageCallback

#### Declaration

```cpp
HRESULT RegisterMessageCallback(D3D12MessageFunc CallbackFunc, D3D12_MESSAGE_CALLBACK_FLAGS CallbackFilterFlags, void* pContext, DWORD *pCallbackCookie);
```

#### Behavior

RegisterMessageCallback registers a callback that is called at the time a debug message is produced.

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:callback-RegisterMessageCallback:3 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Parameter | Description |
> |--------|-------------|
> | `CallbackFunc` | A callback function pointer which allows users to register a callback that is called at the time a debug message is produced. |
> | `pContext` | Can be set to point to anything users want. They can access pContext they specified here in D3D12MessageFunc. This allows users to attach their own additional data to the callback. |
> | `CallbackFilterFlags` | If this value is set to D3D12_MESSAGE_CALLBACK_IGNORE_FILTERS, current callback is unfiltered. If this value is set to D3D12_MESSAGE_CALLBACK_FLAG_NONE, current callback is filtered in the exact same way as what gets logged as debug text. |
> | `pCallbackCookie` | An output parameter that uniquely identifies the registered callback, the value pointed to by a valid pCallbackCookie is set to zero if registration fails. |

<!-- d3d12-review-alert:end:diagnostics:callback-RegisterMessageCallback:3 -->

#### Return values

| Return Type | Description |
|--------|-------------|
| `HRESULT` | Returns E_OUTOFMEMORY if there is insufficient memory to register the callback. [See Direct3D 12 Return Codes for other possible return values.](https://docs.microsoft.com/en-us/windows/win32/direct3d12/d3d12-graphics-reference-returnvalues) |

#### Context

<ins><!-- d3d12-review-inline:begin:diagnostics:callback-RegisterMessageCallback:7 -->Apps should not rely on callbacks being invoked on the same thread that the API call was made. In particular callbacks could be invoked from internal debug layer threads related to queue virtualization and GPU-Based Validation. Callback implementations must not make any D3D API calls. If multiple callbacks are active, they will be called sequentially in the same order that the callbacks were registered.<!-- d3d12-review-inline:end:diagnostics:callback-RegisterMessageCallback:7 --></ins>

#### Validation and results

<!-- d3d12-review-alert:begin:diagnostics:callback-registration-validation:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `CallbackFunc` and `pCallbackCookie` are required nonnull pointers. `pContext` may be null; it is passed through unchanged. `CallbackFilterFlags` must use only the declared bits (0 or 1). A null required pointer or an unknown flag bit is invalid and returns `E_INVALIDARG`. `S_OK` establishes the registration and its output cookie; `E_OUTOFMEMORY` reports allocation failure.

<!-- d3d12-review-alert:end:diagnostics:callback-registration-validation:1 -->

<!-- d3d12-review-alert:begin:diagnostics:cookie-dispute:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `RegisterMessageCallback` must write zero through a valid `pCallbackCookie` output on any registration failure. An invalid output pointer cannot be written. The cookie is usable only after a successful registration `HRESULT`; its value alone does not establish success.

<!-- d3d12-review-alert:end:diagnostics:cookie-dispute:0 -->

<a id="id3d12infoqueue1-unregistermessagecallback"></a>

### ID3D12InfoQueue1::UnregisterMessageCallback

#### Declaration

```cpp
HRESULT UnregisterMessageCallback(DWORD CallbackCookie);
```

#### Behavior

UnregisterMessageCallback unregisters a previously registered callback.

#### Parameters

| Parameter | Description |
|--------|-------------|
| `CallbackCookie` | The cookie that identifies the callback to unregister. |

#### Return values

| Return Type | Description |
|--------|-------------|
| `HRESULT` | Returns E_INVALIDARG if the provided cookie is not associated with any registered callbacks. [See Direct3D 12 Return Codes for other possible return values.](https://docs.microsoft.com/en-us/windows/win32/direct3d12/d3d12-graphics-reference-returnvalues) |

#### Context

It is guaranteed that UnregisterMessageCallback won’t return until any outstanding callbacks have completed.

<a id="callback-types"></a>

### Callback function and flags

```cpp
typedef void (__stdcall *D3D12MessageFunc)(
    D3D12_MESSAGE_CATEGORY Category,
    D3D12_MESSAGE_SEVERITY Severity,
    D3D12_MESSAGE_ID ID,
    LPCSTR pDescription,
    void* pContext);


typedef enum D3D12_MESSAGE_CALLBACK_FLAGS
{
    D3D12_MESSAGE_CALLBACK_FLAG_NONE = 0x00,
    D3D12_MESSAGE_CALLBACK_IGNORE_FILTERS = 0x01,
} D3D12_MESSAGE_CALLBACK_FLAGS;
```

#### Parameters

| Parameter | Description |
|--------|-------------|
| `Category` | Category of the debug message produced. |
| `Severity` | Severity of the debug message produced. |
| `ID` | ID of the debug message produced. |
| `pDescription` | Debug message description. |
| `pContext` | Pointer to user-supplied data that will be passed into each callback invocation. The memory pointed to by pContext must remain valid until the callback has been unregistered. |

### Reentrancy restrictions

Callbacks may be invoked with the internal runtimes in states which are unsafe to make other D3D calls. Any D3D API calls from a callback implementation could result in deadlocks and crashes.

<!-- d3d12-review-alert:begin:diagnostics:callback-flags-and-lifetime:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12_MESSAGE_CALLBACK_FLAG_NONE` (0) filters the callback in the same way as debug text. `D3D12_MESSAGE_CALLBACK_IGNORE_FILTERS` (1) bypasses that filtering. These are not reentrancy flags and do not relax the prohibition on all D3D API calls from a callback.

<!-- d3d12-review-alert:end:diagnostics:callback-flags-and-lifetime:0 -->

<!-- d3d12-review-alert:begin:diagnostics:callback-flags-and-lifetime:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The callback receives the category, severity, ID and a narrow message description, and the application-supplied `pContext`. The application must not retain the description pointer beyond that invocation without copying its contents. `pContext` memory must remain valid until the callback is successfully unregistered. `UnregisterMessageCallback` waits for outstanding invocations; the application must call it outside callbacks before freeing the context or unloading callback code.

<!-- d3d12-review-alert:end:diagnostics:callback-flags-and-lifetime:1 -->

<!-- d3d12-review-alert:begin:diagnostics:callback-flags-and-lifetime:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> For a message delivered to multiple active callbacks, those callbacks are invoked sequentially in registration order. This does not establish a global ordering of messages from all application and internal validation threads. Internal threads, including GPU-based-validation and queue-virtualization threads, can deliver callbacks.

<!-- d3d12-review-alert:end:diagnostics:callback-flags-and-lifetime:2 -->

<a id="object-scoped-validation"></a>

## Object-scoped validation and live-object reporting

<!-- d3d12-review-alert:begin:diagnostics:D107-object-scope:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Debug-device, debug-command-list and debug-command-queue interfaces configure or inspect the debug layer associated with the corresponding D3D12 object. These controls are distinct from the [debug-controller startup options](#debug-configuration). They do not enable GPU-based validation on a device that was created without it.

<!-- d3d12-review-alert:end:diagnostics:D107-object-scope:0 -->

<!-- d3d12-review-alert:begin:diagnostics:D107-object-scope:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `ID3D12DebugDevice1` and `ID3D12DebugCommandList1` derive directly from `IUnknown`, rather than from the unnumbered debug interfaces. `ID3D12DebugDevice2` derives from `ID3D12DebugDevice`; `ID3D12DebugCommandList2` derives from `ID3D12DebugCommandList`, and `ID3D12DebugCommandList3` derives from `ID3D12DebugCommandList2`. `ID3D12DebugCommandQueue1` derives from `ID3D12DebugCommandQueue`. Directly redeclared methods below are separate declaring contracts; inherited methods are not repeated.

<!-- d3d12-review-alert:end:diagnostics:D107-object-scope:1 -->

<!-- d3d12-review-alert:begin:diagnostics:D107-object-scope:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> These interfaces provide diagnostics, not resource barriers, GPU completion queries or permission to use resources in an otherwise-invalid state. [Synchronization](synchronization.md) owns resource states, barrier access and texture-layout semantics.

<!-- d3d12-review-alert:end:diagnostics:D107-object-scope:2 -->

<a id="live-object-report-options"></a>

### Live-object report options

<a id="d3d12-rldo-flags"></a>

```cpp
typedef enum D3D12_RLDO_FLAGS
{
    D3D12_RLDO_NONE = 0x0,
    D3D12_RLDO_SUMMARY = 0x1,
    D3D12_RLDO_DETAIL = 0x2,
    D3D12_RLDO_IGNORE_INTERNAL = 0x4,

} D3D12_RLDO_FLAGS;
```

<!-- d3d12-review-alert:begin:diagnostics:D107-D3D12_RLDO_FLAGS-meanings:0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Flag | Meaning |
> |---|---|
> | `D3D12_RLDO_NONE` | `0`. No report. |
> | `D3D12_RLDO_SUMMARY` | `0x1`. Obtain a summary about a live device object's lifetime. |
> | `D3D12_RLDO_DETAIL` | `0x2`. Obtain detailed information about a live device object's lifetime. |
> | `D3D12_RLDO_IGNORE_INTERNAL` | `0x4`. This flag indicates to ignore objects which have no external refcounts keeping them alive. D3D objects are printed using an external refcount and an internal refcount. Typically, all objects are printed. This flag means ignore the objects whose external refcount is 0, because the application is not responsible for keeping them alive. |

<!-- d3d12-review-alert:end:diagnostics:D107-D3D12_RLDO_FLAGS-meanings:0 -->

<!-- d3d12-review-alert:begin:diagnostics:D107-report-results:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `SUMMARY` and `DETAIL` can be combined; `IGNORE_INTERNAL` filters objects with zero external references rather than releasing them. Objects retained internally by pending work are not, solely for that reason, application leaks. The report concerns objects belonging to the device on which the method is called; it is not an adapter-wide or process-wide leak report.

<!-- d3d12-review-alert:end:diagnostics:D107-report-results:0 -->

<!-- d3d12-review-alert:begin:diagnostics:D107-report-results:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12_RLDO_NONE` requests no report and succeeds. Bits outside `0x07` are invalid and return `E_INVALIDARG`; accepted flag combinations return `S_OK`. `S_OK` describes the reporting operation, not the absence of live objects. Reporting neither releases objects nor waits for their GPU use to complete. Application-held references, including references held by the reporting code, affect the report.

<!-- d3d12-review-alert:end:diagnostics:D107-report-results:1 -->

<a id="object-debug-features"></a>

### Optional debug features

<a id="d3d12-debug-feature"></a>

```cpp
typedef enum D3D12_DEBUG_FEATURE
{
    D3D12_DEBUG_FEATURE_NONE = 0x00,
    D3D12_DEBUG_FEATURE_ALLOW_BEHAVIOR_CHANGING_DEBUG_AIDS = 0x01,
    D3D12_DEBUG_FEATURE_CONSERVATIVE_RESOURCE_STATE_TRACKING = 0x02,
    D3D12_DEBUG_FEATURE_DISABLE_VIRTUALIZED_BUNDLES_VALIDATION = 0x04,
    D3D12_DEBUG_FEATURE_EMULATE_WINDOWS7 = 0x08,
} D3D12_DEBUG_FEATURE;
```

<!-- d3d12-review-alert:begin:diagnostics:D107-D3D12_DEBUG_FEATURE-meanings:0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Flag | Meaning |
> |---|---|
> | `D3D12_DEBUG_FEATURE_NONE` | `0`. The default. No optional Debug Layer features. |
> | `D3D12_DEBUG_FEATURE_ALLOW_BEHAVIOR_CHANGING_DEBUG_AIDS` | `0x1`. The Debug Layer is allowed to deliberately change functional behavior of an application in order to help identify potential errors. By default, the Debug Layer allows most invalid API usage to run the natural course. |
> | `D3D12_DEBUG_FEATURE_CONSERVATIVE_RESOURCE_STATE_TRACKING` | `0x2`. Performs additional resource state validation of resources set in descriptors at the time [ID3D12CommandQueue::ExecuteCommandLists](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nf-d3d12-id3d12commandqueue-executecommandlists) is called. By design descriptors can be changed even after submitting command lists assuming proper synchronization. Conservative resource state tracking ignores this allowance and validates all resources used in descriptor tables when **ExecuteCommandLists** is called. The result may be false validation errors. |
> | `D3D12_DEBUG_FEATURE_DISABLE_VIRTUALIZED_BUNDLES_VALIDATION` | `0x4`. Disables validation of bundle commands by virtually injecting checks into the calling command list validation paths. |
> | `D3D12_DEBUG_FEATURE_EMULATE_WINDOWS7` | `0x08`. Historical Windows 7 emulation feature bit. |

<!-- d3d12-review-alert:end:diagnostics:D107-D3D12_DEBUG_FEATURE-meanings:0 -->

<!-- d3d12-review-alert:begin:diagnostics:D107-feature-mask-boundaries:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The ordinary device feature-mask default is `D3D12_DEBUG_FEATURE_NONE`. The active optional flags occupy bits `0x01`, `0x02` and `0x04`. The historical `EMULATE_WINDOWS7` bit remains declared, but setting it through the device feature-flags parameter is rejected with `E_INVALIDARG`. Bits outside the active mask are discarded by that parameter setter rather than enabling additional features.

<!-- d3d12-review-alert:end:diagnostics:D107-feature-mask-boundaries:0 -->

<!-- d3d12-review-alert:begin:diagnostics:D107-feature-mask-boundaries:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> GPU-based validation requires virtualized-bundle validation: attempting to set `DISABLE_VIRTUALIZED_BUNDLES_VALIDATION` while GPU-based validation is enabled produces a diagnostic and leaves that bit clear. Read back the effective mask with the feature-flags parameter getter. Conservative descriptor validation may report false errors for descriptor changes that are properly synchronized; it does not change the underlying binding or synchronization contract.

<!-- d3d12-review-alert:end:diagnostics:D107-feature-mask-boundaries:1 -->

<!-- d3d12-review-alert:begin:diagnostics:D107-feature-mask-boundaries:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The deprecated device/list feature-mask methods below do not set or query these typed settings. Their current behavior is a no-op setter and a `NONE` getter; earlier mutating descriptions are retained only as history.

<!-- d3d12-review-alert:end:diagnostics:D107-feature-mask-boundaries:2 -->

<a id="object-debug-parameters"></a>

### Fixed-size debug parameters

<a id="d3d12-debug-device-parameter-type"></a>

```cpp
typedef enum D3D12_DEBUG_DEVICE_PARAMETER_TYPE
{
    D3D12_DEBUG_DEVICE_PARAMETER_FEATURE_FLAGS,
    D3D12_DEBUG_DEVICE_PARAMETER_GPU_BASED_VALIDATION_SETTINGS,
    D3D12_DEBUG_DEVICE_PARAMETER_GPU_SLOWDOWN_PERFORMANCE_FACTOR,
    D3D12_DEBUG_DEVICE_PARAMETER_BYTECODE_VALIDATION_MODE
} D3D12_DEBUG_DEVICE_PARAMETER_TYPE;
```

<!-- d3d12-review-alert:begin:diagnostics:D107-D3D12_DEBUG_DEVICE_PARAMETER_TYPE-selector-meanings:0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Selector | Meaning |
> |---|---|
> | `D3D12_DEBUG_DEVICE_PARAMETER_FEATURE_FLAGS` | `0`. Indicates *pData* points to a [D3D12_DEBUG_FEATURE](#d3d12-debug-feature) value. |
> | `D3D12_DEBUG_DEVICE_PARAMETER_GPU_BASED_VALIDATION_SETTINGS` | Indicates *pData* points to a [D3D12_DEBUG_DEVICE_GPU_BASED_VALIDATION_SETTINGS](#d3d12-debug-device-gpu-based-validation-settings) structure. |
> | `D3D12_DEBUG_DEVICE_PARAMETER_GPU_SLOWDOWN_PERFORMANCE_FACTOR` | Indicates *pData* points to a [D3D12_DEBUG_DEVICE_GPU_SLOWDOWN_PERFORMANCE_FACTOR](#d3d12-debug-device-gpu-slowdown-performance-factor) structure. |
> | `D3D12_DEBUG_DEVICE_PARAMETER_BYTECODE_VALIDATION_MODE` | `3`. Indicates *pData* points to a [D3D12_DEBUG_DEVICE_BYTECODE_VALIDATION_MODE](#d3d12-debug-device-bytecode-validation-mode) value. |

<!-- d3d12-review-alert:end:diagnostics:D107-D3D12_DEBUG_DEVICE_PARAMETER_TYPE-selector-meanings:0 -->

<a id="d3d12-debug-command-list-parameter-type"></a>

```cpp
typedef enum D3D12_DEBUG_COMMAND_LIST_PARAMETER_TYPE
{
    D3D12_DEBUG_COMMAND_LIST_PARAMETER_GPU_BASED_VALIDATION_SETTINGS,
} D3D12_DEBUG_COMMAND_LIST_PARAMETER_TYPE;
```

<!-- d3d12-review-alert:begin:diagnostics:D107-D3D12_DEBUG_COMMAND_LIST_PARAMETER_TYPE-selector-meanings:0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Selector | Meaning |
> |---|---|
> | `D3D12_DEBUG_COMMAND_LIST_PARAMETER_GPU_BASED_VALIDATION_SETTINGS` | `0`. Indicates the parameter is type [D3D12_DEBUG_COMMAND_LIST_GPU_BASED_VALIDATION_SETTINGS](#d3d12-debug-command-list-gpu-based-validation-settings). |

<!-- d3d12-review-alert:end:diagnostics:D107-D3D12_DEBUG_COMMAND_LIST_PARAMETER_TYPE-selector-meanings:0 -->

<!-- d3d12-review-alert:begin:diagnostics:D107-parameter-selector-table:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Scope and selector | Numeric value | Payload and exact `DataSize` |
> |---|---|---|
> | Device: `D3D12_DEBUG_DEVICE_PARAMETER_FEATURE_FLAGS` | `0` | `D3D12_DEBUG_FEATURE`, `sizeof(D3D12_DEBUG_FEATURE)` (4 bytes) |
> | Device: `D3D12_DEBUG_DEVICE_PARAMETER_GPU_BASED_VALIDATION_SETTINGS` | `1` | `D3D12_DEBUG_DEVICE_GPU_BASED_VALIDATION_SETTINGS`, `sizeof(D3D12_DEBUG_DEVICE_GPU_BASED_VALIDATION_SETTINGS)` (12 bytes) |
> | Device: `D3D12_DEBUG_DEVICE_PARAMETER_GPU_SLOWDOWN_PERFORMANCE_FACTOR` | `2` | `D3D12_DEBUG_DEVICE_GPU_SLOWDOWN_PERFORMANCE_FACTOR`, `sizeof(D3D12_DEBUG_DEVICE_GPU_SLOWDOWN_PERFORMANCE_FACTOR)` (4 bytes) |
> | Device: `D3D12_DEBUG_DEVICE_PARAMETER_BYTECODE_VALIDATION_MODE` | `3` | `D3D12_DEBUG_DEVICE_BYTECODE_VALIDATION_MODE`, `sizeof(D3D12_DEBUG_DEVICE_BYTECODE_VALIDATION_MODE)` (4 bytes) |
> | Command list: `D3D12_DEBUG_COMMAND_LIST_PARAMETER_GPU_BASED_VALIDATION_SETTINGS` | `0` | `D3D12_DEBUG_COMMAND_LIST_GPU_BASED_VALIDATION_SETTINGS`, `sizeof(D3D12_DEBUG_COMMAND_LIST_GPU_BASED_VALIDATION_SETTINGS)` (4 bytes) |

<!-- d3d12-review-alert:end:diagnostics:D107-parameter-selector-table:0 -->

<!-- d3d12-review-alert:begin:diagnostics:D107-parameter-selector-table:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> All four device selectors and the command-list selector support both setting and getting: the setter copies the complete input payload and the getter must copy the complete current payload to application memory. In particular, the device bytecode-validation-mode getter must return the current `D3D12_DEBUG_DEVICE_BYTECODE_VALIDATION_MODE` value. `pData` must point to readable input storage for a setter or writable output storage for a getter, for the duration of the call. The layer does not retain the application's payload pointer. `DataSize` must equal the selected payload size, not merely be large enough.

<!-- d3d12-review-alert:end:diagnostics:D107-parameter-selector-table:1 -->

<!-- d3d12-review-alert:begin:diagnostics:D107-parameter-selector-table:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> These are fixed-size operations, not variable-buffer sizing queries. A null-output/zero-size call is not a supported size query. An unrecognized selector or an incorrect `DataSize`, whether too small or too large, returns `E_INVALIDARG`; a successful operation returns `S_OK`. No failure-output initialization is promised. Device settings affect the associated device, not other devices or process-global startup configuration. Command-list settings affect the associated recording and are restored to defaults by `Reset`.

<!-- d3d12-review-alert:end:diagnostics:D107-parameter-selector-table:2 -->

<a id="object-gbv-settings"></a>

### Validation payloads and patch settings

#### D3D12_DEBUG_DEVICE_BYTECODE_VALIDATION_MODE

<a id="d3d12-debug-device-bytecode-validation-mode"></a>

```cpp
typedef enum D3D12_DEBUG_DEVICE_BYTECODE_VALIDATION_MODE
{
    D3D12_DEBUG_DEVICE_BYTECODE_VALIDATION_DISABLED,
    D3D12_DEBUG_DEVICE_BYTECODE_VALIDATION_WHEN_HASH_BYPASSED,
    D3D12_DEBUG_DEVICE_BYTECODE_VALIDATION_ALL_BYTECODE,
    D3D12_DEBUG_DEVICE_BYTECODE_VALIDATION_MODE_DEFAULT =
        D3D12_DEBUG_DEVICE_BYTECODE_VALIDATION_WHEN_HASH_BYPASSED
} D3D12_DEBUG_DEVICE_BYTECODE_VALIDATION_MODE;
```

<!-- d3d12-review-alert:begin:diagnostics:D107-bytecode-validation-policy:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12_DEBUG_DEVICE_BYTECODE_VALIDATION_MODE` is a 4-byte enum payload. `DISABLED` (0) disables the layer's bytecode-validation policy; `WHEN_HASH_BYPASSED` (1) selects validation when the normal bytecode hash check is bypassed; `ALL_BYTECODE` (2) requests validation for all bytecode reaching that policy. `MODE_DEFAULT` aliases `WHEN_HASH_BYPASSED`. The device default is `MODE_DEFAULT`.

<!-- d3d12-review-alert:end:diagnostics:D107-bytecode-validation-policy:0 -->

<!-- d3d12-review-alert:begin:diagnostics:D107-bytecode-validation-policy:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The setter accepts those three mode values; other mode values return `E_INVALIDARG`. This changes the associated device's validation policy for subsequent validation calls, not previously created shader objects or the underlying shader-format/acceptance contract. The getter must return the current mode using the same exact 4-byte enum payload. An incorrect size returns `E_INVALIDARG`; a successful getter returns `S_OK`. This typed control does not enable GPU-based validation.

<!-- d3d12-review-alert:end:diagnostics:D107-bytecode-validation-policy:1 -->

#### D3D12_DEBUG_DEVICE_GPU_BASED_VALIDATION_SETTINGS

<a id="d3d12-debug-device-gpu-based-validation-settings"></a>

```cpp
typedef struct D3D12_DEBUG_DEVICE_GPU_BASED_VALIDATION_SETTINGS
{
    UINT MaxMessagesPerCommandList;
    D3D12_GPU_BASED_VALIDATION_SHADER_PATCH_MODE DefaultShaderPatchMode;
    D3D12_GPU_BASED_VALIDATION_PIPELINE_STATE_CREATE_FLAGS PipelineStateCreateFlags;
} D3D12_DEBUG_DEVICE_GPU_BASED_VALIDATION_SETTINGS;
```

`MaxMessagesPerCommandList`

<ins><!-- d3d12-review-inline:begin:diagnostics:D107-D3D12_DEBUG_DEVICE_GPU_BASED_VALIDATION_SETTINGS-members:1 -->Specifies a UINT that limits the number of messages that can be stored in the GPU-Based Validation message log. The default value is 1024. Since many identical errors can be produced in a single Draw/Dispatch call it may be useful to increase this number. Note this can become a memory burden if a large number of command lists are used as there is a committed message log per command list.<!-- d3d12-review-inline:end:diagnostics:D107-D3D12_DEBUG_DEVICE_GPU_BASED_VALIDATION_SETTINGS-members:1 --></ins>

`DefaultShaderPatchMode`

Specifies the [D3D12_GPU_BASED_VALIDATION_SHADER_PATCH_MODE](#d3d12-gpu-based-validation-shader-patch-mode) that GPU-Based Validation uses when injecting validation code into shaders, except when overridden by per-command-list GPU-Based Validation settings (see [D3D12_DEBUG_COMMAND_LIST_GPU_BASED_VALIDATION_SETTINGS](#d3d12-debug-command-list-gpu-based-validation-settings)). The default value is D3D12\_GPU\_BASED\_VALIDATION\_SHADER\_PATCH\_MODE\_UNGUARDED\_VALIDATION.

`PipelineStateCreateFlags`

Specifies one of the [D3D12_GPU_BASED_VALIDATION_PIPELINE_STATE_CREATE_FLAGS](#d3d12-gpu-based-validation-pipeline-state-create-flags) that indicates how GPU-Based Validation handles patching pipeline states. The default value is D3D12\_GPU\_BASED\_VALIDATION\_PIPELINE\_STATE\_CREATE\_FLAG\_NONE.

Point to an object using this structure with the *pData* member of [ID3D12DebugDevice1::SetDebugParameter](#id3d12debugdevice1-setdebugparameter) to configure device-wide GPU-Based Validation settings.

Individual command lists can override the default shader patch mode using [ID3D12DebugCommandList1::SetDebugParameter](#id3d12debugcommandlist1-setdebugparameter).

<!-- d3d12-review-alert:begin:diagnostics:D107-gbv-default-dispute:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **History — earlier documentation:** The public member reference previously described a default of 256 messages per command list. The current default is 1024 messages per command list. This setting limits the per-command-list GPU-based-validation log, not the independent [InfoQueue message-count limit](#id3d12infoqueue-setmessagecountlimit).

<!-- d3d12-review-alert:end:diagnostics:D107-gbv-default-dispute:0 -->

#### D3D12_DEBUG_COMMAND_LIST_GPU_BASED_VALIDATION_SETTINGS

<a id="d3d12-debug-command-list-gpu-based-validation-settings"></a>

```cpp
typedef struct D3D12_DEBUG_COMMAND_LIST_GPU_BASED_VALIDATION_SETTINGS
{
    D3D12_GPU_BASED_VALIDATION_SHADER_PATCH_MODE ShaderPatchMode;
} D3D12_DEBUG_COMMAND_LIST_GPU_BASED_VALIDATION_SETTINGS;
```

`ShaderPatchMode`

<ins><!-- d3d12-review-inline:begin:diagnostics:D107-D3D12_DEBUG_COMMAND_LIST_GPU_BASED_VALIDATION_SETTINGS-members:1 -->Specifies a [D3D12_GPU_BASED_VALIDATION_SHADER_PATCH_MODE](#d3d12-gpu-based-validation-shader-patch-mode) that overrides the default device-level shader patch mode (see [ID3D12DebugDevice1::SetDebugParameter](#id3d12debugdevice1-setdebugparameter)). By default this value is initialized to the *DefaultShaderPatchMode* assigned to the device (see [D3D12_DEBUG_DEVICE_GPU_BASED_VALIDATION_SETTINGS](#d3d12-debug-device-gpu-based-validation-settings)).<!-- d3d12-review-inline:end:diagnostics:D107-D3D12_DEBUG_COMMAND_LIST_GPU_BASED_VALIDATION_SETTINGS-members:1 --></ins>

Point to an object using this structure with the *pData* member of [ID3D12DebugCommandList1::SetDebugParameter](#id3d12debugcommandlist1-setdebugparameter) to configure per-command-list GPU-Based Validation settings.

#### D3D12_DEBUG_DEVICE_GPU_SLOWDOWN_PERFORMANCE_FACTOR

<a id="d3d12-debug-device-gpu-slowdown-performance-factor"></a>

```cpp
typedef struct D3D12_DEBUG_DEVICE_GPU_SLOWDOWN_PERFORMANCE_FACTOR
{
    FLOAT SlowdownFactor;
} D3D12_DEBUG_DEVICE_GPU_SLOWDOWN_PERFORMANCE_FACTOR;
```

`SlowdownFactor`

Specifies the amount of slowdown artificially applied, as a factor of the nominal time for the fence to signal. The default value is 0.

The SlowdownFactor is applied by artificially delaying the time it takes for a fence to signal. When SlowdownFactor is non-zero, the time taken for a fence to signal is approximately 1.0 + SlowdownFactor times the length of the nominal timing.

<!-- d3d12-review-alert:begin:diagnostics:D107-slowdown-validation:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `SlowdownFactor` is a dimensionless factor, not a number of milliseconds. Negative values, including negative infinity, are invalid and return `E_INVALIDARG`. Zero, including negative zero, disables artificial slowdown; one requests approximately twice the nominal fence-signal time. This does not establish a precise timer, GPU clock rate, completion deadline or ordering guarantee. The contract does not specify the result for NaN or positive infinity.

<!-- d3d12-review-alert:end:diagnostics:D107-slowdown-validation:0 -->

<!-- d3d12-review-alert:begin:diagnostics:D107-payload-layout-and-timing:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The device GPU-based-validation structure contains three consecutive 4-byte members at offsets 0, 4 and 8, in declaration order. The list GPU-based-validation structure contains its 4-byte mode at offset 0. The slowdown structure contains its 4-byte `FLOAT` at offset 0. These structures contain no pointers or variable-length data.

<!-- d3d12-review-alert:end:diagnostics:D107-payload-layout-and-timing:0 -->

<!-- d3d12-review-alert:begin:diagnostics:D107-payload-layout-and-timing:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Device GPU-based-validation settings supply the default shader-patch mode for command-list creation and reset. A list override changes that list's patch mode; it does not replace the device default or change other lists. A reset resamples the device default. Set a per-list override before recording the draw or dispatch operations to which it is intended to apply; a setting change does not retroactively patch previously recorded operations.

<!-- d3d12-review-alert:end:diagnostics:D107-payload-layout-and-timing:1 -->

<!-- d3d12-review-alert:begin:diagnostics:D107-payload-layout-and-timing:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `PipelineStateCreateFlags` control work performed when pipeline-state objects are created, rather than retroactively recreating existing objects. The per-list mode selects the corresponding patched variant used for subsequent recording. When GPU-based-validation state tracking is disabled, a device request for `STATE_TRACKING_ONLY` is diagnosed and normalized to `NONE`. Changing these payloads does not turn on the startup GPU-based-validation infrastructure.

<!-- d3d12-review-alert:end:diagnostics:D107-payload-layout-and-timing:2 -->

#### D3D12_GPU_BASED_VALIDATION_SHADER_PATCH_MODE

<a id="d3d12-gpu-based-validation-shader-patch-mode"></a>

```cpp
typedef enum D3D12_GPU_BASED_VALIDATION_SHADER_PATCH_MODE
{
    D3D12_GPU_BASED_VALIDATION_SHADER_PATCH_MODE_NONE,
    D3D12_GPU_BASED_VALIDATION_SHADER_PATCH_MODE_STATE_TRACKING_ONLY,
    D3D12_GPU_BASED_VALIDATION_SHADER_PATCH_MODE_UNGUARDED_VALIDATION,
    D3D12_GPU_BASED_VALIDATION_SHADER_PATCH_MODE_GUARDED_VALIDATION,
    NUM_D3D12_GPU_BASED_VALIDATION_SHADER_PATCH_MODES
} D3D12_GPU_BASED_VALIDATION_SHADER_PATCH_MODE;
```

<!-- d3d12-review-alert:begin:diagnostics:D107-D3D12_GPU_BASED_VALIDATION_SHADER_PATCH_MODE-meanings:0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Value | Meaning |
> |---|---|
> | `D3D12_GPU_BASED_VALIDATION_SHADER_PATCH_MODE_NONE` | `0`. No shader patching is to be done. This will retain the original shader bytecode. Can lead to errors in some of the GPU-Based Validation state tracking as the unpatched shader may still change resource state (see [Common state promotion](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/using-resource-barriers-to-synchronize-resource-states-in-direct3d-12)) but the promotion will be untracked without patching the shader. This can improve performance but no validation will be performed and may also lead to misleading GPU-Based Validation errors. Use this mode very carefully. |
> | `D3D12_GPU_BASED_VALIDATION_SHADER_PATCH_MODE_STATE_TRACKING_ONLY` | Shaders can be patched with resource state tracking code but no validation. This may improve performance but no validation will be performed. |
> | `D3D12_GPU_BASED_VALIDATION_SHADER_PATCH_MODE_UNGUARDED_VALIDATION` | The default. Shaders are patched with validation code but erroneous instructions will still be executed. |
> | `D3D12_GPU_BASED_VALIDATION_SHADER_PATCH_MODE_GUARDED_VALIDATION` | Shaders are patched with validation code and erroneous instructions are skipped in execution. This can help avoid crashes or device removal. |
> | `NUM_D3D12_GPU_BASED_VALIDATION_SHADER_PATCH_MODES` | Unused, simply the count of the number of modes. |

<!-- d3d12-review-alert:end:diagnostics:D107-D3D12_GPU_BASED_VALIDATION_SHADER_PATCH_MODE-meanings:0 -->

This enum is used by the [D3D12_DEBUG_DEVICE_GPU_BASED_VALIDATION_SETTINGS](#d3d12-debug-device-gpu-based-validation-settings) structure.

#### D3D12_GPU_BASED_VALIDATION_PIPELINE_STATE_CREATE_FLAGS

<a id="d3d12-gpu-based-validation-pipeline-state-create-flags"></a>

```cpp
typedef enum D3D12_GPU_BASED_VALIDATION_PIPELINE_STATE_CREATE_FLAGS
{
    D3D12_GPU_BASED_VALIDATION_PIPELINE_STATE_CREATE_FLAG_NONE = 0x00,
    D3D12_GPU_BASED_VALIDATION_PIPELINE_STATE_CREATE_FLAG_FRONT_LOAD_CREATE_TRACKING_ONLY_SHADERS = 0x01,
    D3D12_GPU_BASED_VALIDATION_PIPELINE_STATE_CREATE_FLAG_FRONT_LOAD_CREATE_UNGUARDED_VALIDATION_SHADERS = 0x02,
    D3D12_GPU_BASED_VALIDATION_PIPELINE_STATE_CREATE_FLAG_FRONT_LOAD_CREATE_GUARDED_VALIDATION_SHADERS = 0x04,
    D3D12_GPU_BASED_VALIDATION_PIPELINE_STATE_CREATE_FLAGS_VALID_MASK = 0x07
} D3D12_GPU_BASED_VALIDATION_PIPELINE_STATE_CREATE_FLAGS;
```

<!-- d3d12-review-alert:begin:diagnostics:D107-D3D12_GPU_BASED_VALIDATION_PIPELINE_STATE_CREATE_FLAGS-meanings:0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Value | Meaning |
> |---|---|
> | `D3D12_GPU_BASED_VALIDATION_PIPELINE_STATE_CREATE_FLAG_NONE` | `0`. This is the default value. Indicates no patching of pipeline states should be done during PSO creation. Instead PSOs are patched on first use in a command list. This can help to reduce the up-front cost of PSO creation but may instead slow down command list recording until a steady-state is reached. |
> | `D3D12_GPU_BASED_VALIDATION_PIPELINE_STATE_CREATE_FLAG_FRONT_LOAD_CREATE_TRACKING_ONLY_SHADERS` | `0x1`. Indicates that state-tracking GPU-Based Validation PSOs should be created along with the original PSO at create time. |
> | `D3D12_GPU_BASED_VALIDATION_PIPELINE_STATE_CREATE_FLAG_FRONT_LOAD_CREATE_UNGUARDED_VALIDATION_SHADERS` | `0x2`. Indicates that unguarded GPU-Based Validation PSOs should be created along with the original PSO at create time. |
> | `D3D12_GPU_BASED_VALIDATION_PIPELINE_STATE_CREATE_FLAG_FRONT_LOAD_CREATE_GUARDED_VALIDATION_SHADERS` | `0x4`. Indicates that guarded GPU-Based Validation PSOs should be created along with the original PSO at create time. |
> | `D3D12_GPU_BASED_VALIDATION_PIPELINE_STATE_CREATE_FLAGS_VALID_MASK` | `0x7`. Internal use only. |

<!-- d3d12-review-alert:end:diagnostics:D107-D3D12_GPU_BASED_VALIDATION_PIPELINE_STATE_CREATE_FLAGS-meanings:0 -->

This enum is used by the [D3D12_DEBUG_DEVICE_GPU_BASED_VALIDATION_SETTINGS](#d3d12-debug-device-gpu-based-validation-settings) structure.

Generally speaking most application developers are likely to leave this parameter unchanged. However, if the overhead of deferring patched PSO creation is suspected to be too much of a performance problem, then developers should consider changing this setting.

<!-- d3d12-review-alert:begin:diagnostics:D107-patch-validity:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Shader-patch mode values 0 through 3 select `NONE`, `STATE_TRACKING_ONLY`, `UNGUARDED_VALIDATION` and `GUARDED_VALIDATION`, respectively. `NUM_D3D12_GPU_BASED_VALIDATION_SHADER_PATCH_MODES` is the count (4), not another mode. The front-load flags can be combined; `VALID_MASK` is `0x07` and is not a fourth independent option. Applications must not use undeclared patch modes or reserved pipeline-create bits. The parameter entry points do not promise rejection of every invalid payload field merely because the selector and payload size are checked.

<!-- d3d12-review-alert:end:diagnostics:D107-patch-validity:0 -->

<!-- d3d12-review-alert:begin:diagnostics:D107-patch-validity:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Guarded validation changes execution of erroneous instructions; it is not a guarantee that invalid work cannot remove the device. `NONE` and `STATE_TRACKING_ONLY` reduce or omit shader validation, and do not establish correctness of unreported work.

<!-- d3d12-review-alert:end:diagnostics:D107-patch-validity:1 -->

<a id="object-device-controls"></a>

### Object debug-control methods

<a id="id3d12debugdevice-getfeaturemask"></a>

### ID3D12DebugDevice::GetFeatureMask

#### Declaration

```cpp
D3D12_DEBUG_FEATURE GetFeatureMask();
```

#### Behavior

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugDevice-GetFeatureMask-mask-qualification:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Deprecated. This method returns `D3D12_DEBUG_FEATURE_NONE`, not a readback of the typed parameter settings. The debug layer emits a deprecated-API diagnostic. The [typed debug-parameter control](#id3d12debugdevice2-getdebugparameter) is a distinct operation.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugDevice-GetFeatureMask-mask-qualification:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugDevice-GetFeatureMask-current-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12_DEBUG_FEATURE_NONE`.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugDevice-GetFeatureMask-current-returns:0 -->

#### History

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugDevice-GetFeatureMask-history-context:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Earlier public documentation** described a mutating feature mask and corresponding readback as follows. These paragraphs are retained only as history; they do not describe the current deprecated method. No release transition is established here.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugDevice-GetFeatureMask-history-context:0 -->

Gets a bit field of flags that indicates which debug features are on or off.

##### Historical return description

Type: **[D3D12_DEBUG_FEATURE](#d3d12-debug-feature)**

Mask of feature-mask flags, as a bitwise OR'ed combination of [D3D12_DEBUG_FEATURE](#d3d12-debug-feature) enumeration constants. If a flag is present, then that feature will be set to on, otherwise the feature will be set to off.

<a id="id3d12debugdevice-reportlivedeviceobjects"></a>

### ID3D12DebugDevice::ReportLiveDeviceObjects

#### Declaration

```cpp
HRESULT ReportLiveDeviceObjects(D3D12_RLDO_FLAGS Flags);
```

#### Behavior

Reports information about a device object's lifetime.

#### Parameters

`Flags`

Type: **[D3D12_RLDO_FLAGS](#d3d12-rldo-flags)**

A value from the [D3D12_RLDO_FLAGS](#d3d12-rldo-flags) enumeration. This method uses the value in *Flags* to determine the amount of information to report about a device object's lifetime.

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

<ins><!-- d3d12-review-inline:begin:diagnostics:D107-ID3D12DebugDevice-ReportLiveDeviceObjects-Return-value:1 -->This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).<!-- d3d12-review-inline:end:diagnostics:D107-ID3D12DebugDevice-ReportLiveDeviceObjects-Return-value:1 --></ins>

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugDevice-ReportLiveDeviceObjects-report-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> [Live-object report options](#live-object-report-options) define flag combinations, internal/external reference filtering, invalid bits, result meaning and ownership. This entry point reports the associated device's live objects and does not release them.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugDevice-ReportLiveDeviceObjects-report-contract:0 -->

<a id="id3d12debugdevice-setfeaturemask"></a>

### ID3D12DebugDevice::SetFeatureMask

#### Declaration

```cpp
HRESULT SetFeatureMask(D3D12_DEBUG_FEATURE Mask);
```

#### Behavior

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugDevice-SetFeatureMask-mask-qualification:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Deprecated. This method ignores `Mask`, changes no settings and returns `S_OK`. The debug layer emits a deprecated-API diagnostic. The [typed debug-parameter control](#id3d12debugdevice2-setdebugparameter) is a distinct operation.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugDevice-SetFeatureMask-mask-qualification:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugDevice-SetFeatureMask-current-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `Mask` is ignored; it does not enable or disable any feature.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugDevice-SetFeatureMask-current-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugDevice-SetFeatureMask-current-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK`.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugDevice-SetFeatureMask-current-returns:0 -->

#### History

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugDevice-SetFeatureMask-history-context:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Earlier public documentation** described a mutating feature mask and corresponding readback as follows. These paragraphs are retained only as history; they do not describe the current deprecated method. No release transition is established here.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugDevice-SetFeatureMask-history-context:0 -->

<ins><!-- d3d12-review-inline:begin:diagnostics:D107-ID3D12DebugDevice-SetFeatureMask-behavior:0 -->Sets a bit field of flags that will turn debug features on and off.<!-- d3d12-review-inline:end:diagnostics:D107-ID3D12DebugDevice-SetFeatureMask-behavior:0 --></ins>

##### Historical parameter description

`Mask`

Type: **[D3D12_DEBUG_FEATURE](#d3d12-debug-feature)**

Feature-mask flags, as a bitwise-OR'd combination of [D3D12_DEBUG_FEATURE](#d3d12-debug-feature) enumeration constants. If a flag is present, that feature will be set to on; otherwise, the feature will be set to off.

##### Historical return description

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

<ins><!-- d3d12-review-inline:begin:diagnostics:D107-ID3D12DebugDevice-SetFeatureMask-Return-value:1 -->This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).<!-- d3d12-review-inline:end:diagnostics:D107-ID3D12DebugDevice-SetFeatureMask-Return-value:1 --></ins>

<a id="id3d12debugdevice1-getdebugparameter"></a>

### ID3D12DebugDevice1::GetDebugParameter

#### Declaration

```cpp
HRESULT GetDebugParameter(D3D12_DEBUG_DEVICE_PARAMETER_TYPE Type, void *pData, UINT DataSize);
```

#### Behavior

Gets optional device-wide Debug Layer settings.

#### Parameters

`Type`

Type: **[D3D12_DEBUG_DEVICE_PARAMETER_TYPE](#d3d12-debug-device-parameter-type)**

<ins><!-- d3d12-review-inline:begin:diagnostics:D107-ID3D12DebugDevice1-GetDebugParameter-Parameters:2 -->Specifies a [D3D12_DEBUG_DEVICE_PARAMETER_TYPE](#d3d12-debug-device-parameter-type) value that indicates which debug parameter data to get.<!-- d3d12-review-inline:end:diagnostics:D107-ID3D12DebugDevice1-GetDebugParameter-Parameters:2 --></ins>

<ins><!-- d3d12-review-inline:begin:diagnostics:D107-ID3D12DebugDevice1-GetDebugParameter-Parameters:3 -->`pData` (output)<!-- d3d12-review-inline:end:diagnostics:D107-ID3D12DebugDevice1-GetDebugParameter-Parameters:3 --></ins>

Type: **void\***

Points to the memory that will be filled with a copy of the debug parameter data. The interpretation of this data depends on the [D3D12_DEBUG_DEVICE_PARAMETER_TYPE](#d3d12-debug-device-parameter-type) given in the *Type* parameter.

`DataSize`

Type: **UINT**

Size in bytes of the memory buffer pointed to by *pData*.

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugDevice1-GetDebugParameter-typed-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [fixed-size selector and payload contract](#object-debug-parameters) defines the exact accepted sizes, copy behavior, results and object scope. The getter returns the current effective payload, not a required-buffer size; it does not promise a zeroed output on failure.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugDevice1-GetDebugParameter-typed-contract:0 -->

<a id="id3d12debugdevice1-reportlivedeviceobjects"></a>

### ID3D12DebugDevice1::ReportLiveDeviceObjects

#### Declaration

```cpp
HRESULT ReportLiveDeviceObjects(D3D12_RLDO_FLAGS Flags);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:diagnostics:D107-ID3D12DebugDevice1-ReportLiveDeviceObjects-behavior:0 -->Reports information about live objects belonging to the associated device.<!-- d3d12-review-inline:end:diagnostics:D107-ID3D12DebugDevice1-ReportLiveDeviceObjects-behavior:0 --></ins>

#### Parameters

`Flags`

Type: **[D3D12_RLDO_FLAGS](#d3d12-rldo-flags)**

A value from the [D3D12_RLDO_FLAGS](#d3d12-rldo-flags) enumeration. This method uses the value in *Flags* to determine the amount of information to report about a device object's lifetime.

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugDevice1-ReportLiveDeviceObjects-report-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> [Live-object report options](#live-object-report-options) define flag combinations, internal/external reference filtering, invalid bits, result meaning and ownership. This entry point reports the associated device's live objects and does not release them.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugDevice1-ReportLiveDeviceObjects-report-contract:0 -->

<a id="id3d12debugdevice1-setdebugparameter"></a>

### ID3D12DebugDevice1::SetDebugParameter

#### Declaration

```cpp
HRESULT SetDebugParameter(D3D12_DEBUG_DEVICE_PARAMETER_TYPE Type, const void *pData, UINT DataSize);
```

#### Behavior

Modifies the D3D12 optional device-wide Debug Layer settings.

#### Parameters

`Type`

Type: **[D3D12_DEBUG_DEVICE_PARAMETER_TYPE](#d3d12-debug-device-parameter-type)**

<ins><!-- d3d12-review-inline:begin:diagnostics:D107-ID3D12DebugDevice1-SetDebugParameter-Parameters:2 -->Specifies a [D3D12_DEBUG_DEVICE_PARAMETER_TYPE](#d3d12-debug-device-parameter-type) value that indicates which debug parameter data to set.<!-- d3d12-review-inline:end:diagnostics:D107-ID3D12DebugDevice1-SetDebugParameter-Parameters:2 --></ins>

<ins><!-- d3d12-review-inline:begin:diagnostics:D107-ID3D12DebugDevice1-SetDebugParameter-Parameters:3 -->`pData` (input)<!-- d3d12-review-inline:end:diagnostics:D107-ID3D12DebugDevice1-SetDebugParameter-Parameters:3 --></ins>

Type: **const void\***

Debug parameter data to set.

`DataSize`

Type: **UINT**

Size in bytes of the data pointed to by *pData*.

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugDevice1-SetDebugParameter-typed-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [fixed-size selector and payload contract](#object-debug-parameters) defines the exact accepted sizes, copy behavior, results and object scope. [GPU-based-validation payloads](#object-gbv-settings) define defaults, layouts, units and recording/creation timing.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugDevice1-SetDebugParameter-typed-contract:0 -->

<a id="id3d12debugdevice2-getdebugparameter"></a>

### ID3D12DebugDevice2::GetDebugParameter

#### Declaration

```cpp
HRESULT GetDebugParameter(D3D12_DEBUG_DEVICE_PARAMETER_TYPE Type, void *pData, UINT DataSize);
```

#### Behavior

Gets optional device-wide Debug Layer settings.

#### Parameters

`Type`

Type: **[D3D12_DEBUG_DEVICE_PARAMETER_TYPE](#d3d12-debug-device-parameter-type)**

<ins><!-- d3d12-review-inline:begin:diagnostics:D107-ID3D12DebugDevice2-GetDebugParameter-Parameters:2 -->Specifies a [D3D12_DEBUG_DEVICE_PARAMETER_TYPE](#d3d12-debug-device-parameter-type) value that indicates which debug parameter data to get.<!-- d3d12-review-inline:end:diagnostics:D107-ID3D12DebugDevice2-GetDebugParameter-Parameters:2 --></ins>

<ins><!-- d3d12-review-inline:begin:diagnostics:D107-ID3D12DebugDevice2-GetDebugParameter-Parameters:3 -->`pData` (output)<!-- d3d12-review-inline:end:diagnostics:D107-ID3D12DebugDevice2-GetDebugParameter-Parameters:3 --></ins>

Type: **void\***

Points to the memory that will be filled with a copy of the debug parameter data. The interpretation of this data depends on the [D3D12_DEBUG_DEVICE_PARAMETER_TYPE](#d3d12-debug-device-parameter-type) given in the *Type* parameter.

`DataSize`

Type: **UINT**

Size in bytes of the memory buffer pointed to by *pData*.

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugDevice2-GetDebugParameter-typed-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [fixed-size selector and payload contract](#object-debug-parameters) defines the exact accepted sizes, copy behavior, results and object scope. The getter returns the current effective payload, not a required-buffer size; it does not promise a zeroed output on failure.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugDevice2-GetDebugParameter-typed-contract:0 -->

<a id="id3d12debugdevice2-setdebugparameter"></a>

### ID3D12DebugDevice2::SetDebugParameter

#### Declaration

```cpp
HRESULT SetDebugParameter(D3D12_DEBUG_DEVICE_PARAMETER_TYPE Type, const void *pData, UINT DataSize);
```

#### Behavior

Modifies the D3D12 optional device-wide Debug Layer settings.

#### Parameters

`Type`

Type: **[D3D12_DEBUG_DEVICE_PARAMETER_TYPE](#d3d12-debug-device-parameter-type)**

<ins><!-- d3d12-review-inline:begin:diagnostics:D107-ID3D12DebugDevice2-SetDebugParameter-Parameters:2 -->Specifies a [D3D12_DEBUG_DEVICE_PARAMETER_TYPE](#d3d12-debug-device-parameter-type) value that indicates which debug parameter data to set.<!-- d3d12-review-inline:end:diagnostics:D107-ID3D12DebugDevice2-SetDebugParameter-Parameters:2 --></ins>

<ins><!-- d3d12-review-inline:begin:diagnostics:D107-ID3D12DebugDevice2-SetDebugParameter-Parameters:3 -->`pData` (input)<!-- d3d12-review-inline:end:diagnostics:D107-ID3D12DebugDevice2-SetDebugParameter-Parameters:3 --></ins>

Type: **const void\***

Debug parameter data to set.

`DataSize`

Type: **UINT**

Size in bytes of the data pointed to by *pData*.

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugDevice2-SetDebugParameter-typed-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [fixed-size selector and payload contract](#object-debug-parameters) defines the exact accepted sizes, copy behavior, results and object scope. [GPU-based-validation payloads](#object-gbv-settings) define defaults, layouts, units and recording/creation timing.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugDevice2-SetDebugParameter-typed-contract:0 -->

<a id="id3d12debugcommandlist1-getdebugparameter"></a>

### ID3D12DebugCommandList1::GetDebugParameter

#### Declaration

```cpp
HRESULT GetDebugParameter(D3D12_DEBUG_COMMAND_LIST_PARAMETER_TYPE Type, void *pData, UINT DataSize);
```

#### Behavior

Gets optional Command List Debug Layer settings.

#### Parameters

`Type`

Type: **[D3D12_DEBUG_COMMAND_LIST_PARAMETER_TYPE](#d3d12-debug-command-list-parameter-type)**

Specifies a [D3D12_DEBUG_COMMAND_LIST_PARAMETER_TYPE](#d3d12-debug-command-list-parameter-type) value that determines which debug parameter data to copy to the memory pointed to by *pData*.

<ins><!-- d3d12-review-inline:begin:diagnostics:D107-ID3D12DebugCommandList1-GetDebugParameter-Parameters:3 -->`pData` (output)<!-- d3d12-review-inline:end:diagnostics:D107-ID3D12DebugCommandList1-GetDebugParameter-Parameters:3 --></ins>

Type: **void\***

Points to the memory that will be filled with a copy of the debug parameter data. The interpretation of this data depends on the [D3D12_DEBUG_COMMAND_LIST_PARAMETER_TYPE](#d3d12-debug-command-list-parameter-type) given in the *Type* parameter.

`DataSize`

Type: **UINT**

Size in bytes of the memory buffer pointed to by *pData*.

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

<ins><!-- d3d12-review-inline:begin:diagnostics:D107-ID3D12DebugCommandList1-GetDebugParameter-Return-value:1 -->Returns `S_OK` if successful, otherwise `E_INVALIDARG`.<!-- d3d12-review-inline:end:diagnostics:D107-ID3D12DebugCommandList1-GetDebugParameter-Return-value:1 --></ins>

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandList1-GetDebugParameter-typed-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [fixed-size selector and payload contract](#object-debug-parameters) defines the exact accepted sizes, copy behavior, results and object scope. The getter returns the current effective payload, not a required-buffer size; it does not promise a zeroed output on failure.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandList1-GetDebugParameter-typed-contract:0 -->

<a id="id3d12debugcommandlist1-setdebugparameter"></a>

### ID3D12DebugCommandList1::SetDebugParameter

#### Declaration

```cpp
HRESULT SetDebugParameter(D3D12_DEBUG_COMMAND_LIST_PARAMETER_TYPE Type, const void *pData, UINT DataSize);
```

#### Behavior

Modifies optional Debug Layer settings of a command list.

#### Parameters

`Type`

Type: **[D3D12_DEBUG_COMMAND_LIST_PARAMETER_TYPE](#d3d12-debug-command-list-parameter-type)**

Specifies a [D3D12_DEBUG_COMMAND_LIST_PARAMETER_TYPE](#d3d12-debug-command-list-parameter-type) value that indicates which debug parameter data to set.

<ins><!-- d3d12-review-inline:begin:diagnostics:D107-ID3D12DebugCommandList1-SetDebugParameter-Parameters:3 -->`pData` (input)<!-- d3d12-review-inline:end:diagnostics:D107-ID3D12DebugCommandList1-SetDebugParameter-Parameters:3 --></ins>

Type: **const void\***

Pointer to debug parameter data to set. The interpretation of this data depends on the [D3D12_DEBUG_COMMAND_LIST_PARAMETER_TYPE](#d3d12-debug-command-list-parameter-type) given in the *Type* parameter.

`DataSize`

Type: **UINT**

Specifies the size in bytes of the debug parameter *pData*.

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

#### Debug layer

<ins><!-- d3d12-review-inline:begin:diagnostics:D107-ID3D12DebugCommandList1-SetDebugParameter-Remarks:0 -->Certain debug behaviors of D3D12 Debug Layer can be modified by setting debug parameters.<!-- d3d12-review-inline:end:diagnostics:D107-ID3D12DebugCommandList1-SetDebugParameter-Remarks:0 --></ins>

**ID3D12DebugCommandList1::SetDebugParameter** only impacts debug settings for the associated command list. For device-wide debug parameters see the [ID3D12DebugDevice1::SetDebugParameter](#id3d12debugdevice1-setdebugparameter) method.

Resetting a command list restores the debug parameters to the default values. This is because a command list reset is treated as equivalent to creating a new command list.

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandList1-SetDebugParameter-typed-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [fixed-size selector and payload contract](#object-debug-parameters) defines the exact accepted sizes, copy behavior, results and object scope. [GPU-based-validation payloads](#object-gbv-settings) define defaults, layouts, units and recording/creation timing.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandList1-SetDebugParameter-typed-contract:0 -->

<a id="id3d12debugcommandlist2-getdebugparameter"></a>

### ID3D12DebugCommandList2::GetDebugParameter

#### Declaration

```cpp
HRESULT GetDebugParameter(D3D12_DEBUG_COMMAND_LIST_PARAMETER_TYPE Type, void *pData, UINT DataSize);
```

#### Behavior

Gets optional Command List Debug Layer settings.

#### Parameters

`Type`

Type: **[D3D12_DEBUG_COMMAND_LIST_PARAMETER_TYPE](#d3d12-debug-command-list-parameter-type)**

Specifies a [D3D12_DEBUG_COMMAND_LIST_PARAMETER_TYPE](#d3d12-debug-command-list-parameter-type) value that determines which debug parameter data to copy to the memory pointed to by *pData*.

<ins><!-- d3d12-review-inline:begin:diagnostics:D107-ID3D12DebugCommandList2-GetDebugParameter-Parameters:3 -->`pData` (output)<!-- d3d12-review-inline:end:diagnostics:D107-ID3D12DebugCommandList2-GetDebugParameter-Parameters:3 --></ins>

Type: **void\***

Points to the memory that will be filled with a copy of the debug parameter data. The interpretation of this data depends on the [D3D12_DEBUG_COMMAND_LIST_PARAMETER_TYPE](#d3d12-debug-command-list-parameter-type) given in the *Type* parameter.

`DataSize`

Type: **UINT**

Size in bytes of the memory buffer pointed to by *pData*.

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

<ins><!-- d3d12-review-inline:begin:diagnostics:D107-ID3D12DebugCommandList2-GetDebugParameter-Return-value:1 -->Returns `S_OK` if successful, otherwise `E_INVALIDARG`.<!-- d3d12-review-inline:end:diagnostics:D107-ID3D12DebugCommandList2-GetDebugParameter-Return-value:1 --></ins>

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandList2-GetDebugParameter-typed-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [fixed-size selector and payload contract](#object-debug-parameters) defines the exact accepted sizes, copy behavior, results and object scope. The getter returns the current effective payload, not a required-buffer size; it does not promise a zeroed output on failure.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandList2-GetDebugParameter-typed-contract:0 -->

<a id="id3d12debugcommandlist2-setdebugparameter"></a>

### ID3D12DebugCommandList2::SetDebugParameter

#### Declaration

```cpp
HRESULT SetDebugParameter(D3D12_DEBUG_COMMAND_LIST_PARAMETER_TYPE Type, const void *pData, UINT DataSize);
```

#### Behavior

Modifies optional Debug Layer settings of a command list.

#### Parameters

`Type`

Type: **[D3D12_DEBUG_COMMAND_LIST_PARAMETER_TYPE](#d3d12-debug-command-list-parameter-type)**

Specifies a [D3D12_DEBUG_COMMAND_LIST_PARAMETER_TYPE](#d3d12-debug-command-list-parameter-type) value that indicates which debug parameter data to set.

<ins><!-- d3d12-review-inline:begin:diagnostics:D107-ID3D12DebugCommandList2-SetDebugParameter-Parameters:3 -->`pData` (input)<!-- d3d12-review-inline:end:diagnostics:D107-ID3D12DebugCommandList2-SetDebugParameter-Parameters:3 --></ins>

Type: **const void\***

Pointer to debug parameter data to set. The interpretation of this data depends on the [D3D12_DEBUG_COMMAND_LIST_PARAMETER_TYPE](#d3d12-debug-command-list-parameter-type) given in the *Type* parameter.

`DataSize`

Type: **UINT**

Specifies the size in bytes of the debug parameter *pData*.

#### Return values

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

#### Debug layer

Certain debug behaviors of D3D12 Debug Layer can be modified by setting debug parameters.

<ins><!-- d3d12-review-inline:begin:diagnostics:D107-ID3D12DebugCommandList2-SetDebugParameter-Remarks:1 -->**ID3D12DebugCommandList2::SetDebugParameter** only impacts debug settings for the associated command list. For device-wide debug parameters see the [ID3D12DebugDevice1::SetDebugParameter](#id3d12debugdevice1-setdebugparameter) method.<!-- d3d12-review-inline:end:diagnostics:D107-ID3D12DebugCommandList2-SetDebugParameter-Remarks:1 --></ins>

Resetting a command list restores the debug parameters to the default values. This is because a command list reset is treated as equivalent to creating a new command list.

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandList2-SetDebugParameter-typed-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [fixed-size selector and payload contract](#object-debug-parameters) defines the exact accepted sizes, copy behavior, results and object scope. [GPU-based-validation payloads](#object-gbv-settings) define defaults, layouts, units and recording/creation timing.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandList2-SetDebugParameter-typed-contract:0 -->

<a id="id3d12debugcommandlist-getfeaturemask"></a>

### ID3D12DebugCommandList::GetFeatureMask

#### Declaration

```cpp
D3D12_DEBUG_FEATURE GetFeatureMask();
```

#### Behavior

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandList-GetFeatureMask-mask-qualification:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Deprecated. This method returns `D3D12_DEBUG_FEATURE_NONE`, not a readback of the typed parameter settings. The debug layer emits a deprecated-API diagnostic. The [typed debug-parameter control](#id3d12debugcommandlist2-getdebugparameter) is a distinct operation.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandList-GetFeatureMask-mask-qualification:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandList-GetFeatureMask-current-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12_DEBUG_FEATURE_NONE`.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandList-GetFeatureMask-current-returns:0 -->

#### History

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandList-GetFeatureMask-history-context:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Earlier public documentation** described a mutating feature mask and corresponding readback as follows. These paragraphs are retained only as history; they do not describe the current deprecated method. No release transition is established here.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandList-GetFeatureMask-history-context:0 -->

Returns the debug feature flags that have been set on a command list.

##### Historical return description

Type: **[D3D12_DEBUG_FEATURE](#d3d12-debug-feature)**

A bit mask containing the set debug features.

<a id="id3d12debugcommandlist-setfeaturemask"></a>

### ID3D12DebugCommandList::SetFeatureMask

#### Declaration

```cpp
HRESULT SetFeatureMask(D3D12_DEBUG_FEATURE Mask);
```

#### Behavior

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandList-SetFeatureMask-mask-qualification:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Deprecated. This method ignores `Mask`, changes no settings and returns `S_OK`. The debug layer emits a deprecated-API diagnostic. The [typed debug-parameter control](#id3d12debugcommandlist2-setdebugparameter) is a distinct operation.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandList-SetFeatureMask-mask-qualification:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandList-SetFeatureMask-current-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `Mask` is ignored; it does not enable or disable any feature.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandList-SetFeatureMask-current-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandList-SetFeatureMask-current-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `S_OK`.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandList-SetFeatureMask-current-returns:0 -->

#### History

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandList-SetFeatureMask-history-context:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Earlier public documentation** described a mutating feature mask and corresponding readback as follows. These paragraphs are retained only as history; they do not describe the current deprecated method. No release transition is established here.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandList-SetFeatureMask-history-context:0 -->

Turns the debug features for a command list on or off.

##### Historical parameter description

`Mask`

Type: **[D3D12_DEBUG_FEATURE](#d3d12-debug-feature)**

A combination of feature-mask flags that are combined by using a bitwise OR operation. If a flag is present, that feature will be set to on, otherwise the feature will be set to off.

##### Historical return description

Type: **[HRESULT](https://learn.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)**

This method returns one of the [Direct3D 12 Return Codes](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

<a id="object-resource-assertions"></a>

### Resource assertions

<!-- d3d12-review-alert:begin:diagnostics:D107-assertion-common:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Resource assertions inspect the debug layer's tracked or assumed model. They do not read GPU memory to discover an actual state, insert a transition, flush a cache, or prove successful GPU completion. An assertion may establish a previously unknown validation assumption for later checks.

<!-- d3d12-review-alert:end:diagnostics:D107-assertion-common:0 -->

<!-- d3d12-review-alert:begin:diagnostics:D107-assertion-common:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pResource` must identify a live resource belonging to the associated device. `Subresource` is a valid subresource index or `D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES` (`0xffffffff`) to assert all subresources. The application remains responsible for resource lifetime and required barriers. A null resource or out-of-range subresource is invalid. A successful assertion is not permission to destroy an in-use object.

<!-- d3d12-review-alert:end:diagnostics:D107-assertion-common:1 -->

<!-- d3d12-review-alert:begin:diagnostics:D107-assertion-common:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> List assertions occur at a recording position; queue assertions are ordered in the queue's diagnostic timeline. Their CPU call return does not wait for GPU completion. The exact state/access/layout expectations and limitations remain in the named Synchronization sections linked by each entry.

<!-- d3d12-review-alert:end:diagnostics:D107-assertion-common:2 -->

<a id="id3d12debugcommandlist-assertresourcestate"></a>

### ID3D12DebugCommandList::AssertResourceState

#### Declaration

```cpp
BOOL AssertResourceState(ID3D12Resource* pResource, UINT Subresource, UINT State);
```

#### Behavior

Checks whether a resource, or subresource, is in a specified state, or not.

#### Parameters

<ins><!-- d3d12-review-inline:begin:diagnostics:D107-ID3D12DebugCommandList-AssertResourceState-Parameters:0 -->`pResource` (input)<!-- d3d12-review-inline:end:diagnostics:D107-ID3D12DebugCommandList-AssertResourceState-Parameters:0 --></ins>

Type: **ID3D12Resource\***

Specifies the [ID3D12Resource](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nn-d3d12-id3d12resource) to check.

`Subresource`

Type: **UINT**

The index of the subresource to check. This can be set to an index, or D3D12\_RESOURCE\_BARRIER\_ALL\_SUBRESOURCES.

`State`

Type: **UINT**

Specifies the state to check for. This can be one or more D3D12\_RESOURCE\_STATES flags Or'ed together.

#### Return values

Type: **BOOL**

This method returns true if the resource or subresource is in the specified state, false otherwise.

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandList-AssertResourceState-model-qualification:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The result describes validation of the tracked or assumed state, not observation of physical GPU state. For an unknown state, the layer can establish the asserted state for subsequent validation; a successful result in that case does not prove earlier work completed. `FALSE` also covers a null resource, invalid subresource index or unrecognized state bits. The assertion does not perform a resource transition.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandList-AssertResourceState-model-qualification:0 -->

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandList-AssertResourceState-model-qualification:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The command-list recording-point and assumed-state behavior described for [`ID3D12DebugCommandList1::AssertResourceState`](#id3d12debugcommandlist1-assertresourcestate) also applies to this declaring entry point. [Legacy resource states](synchronization.md#legacy-resource-states) define the legal state combinations; [Resource assertions](#object-resource-assertions) defines common resource/subresource and lifetime requirements.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandList-AssertResourceState-model-qualification:1 -->

<a id="id3d12debugcommandlist1-assertresourcestate"></a>

### ID3D12DebugCommandList1::AssertResourceState

#### Declaration

```cpp
BOOL AssertResourceState(ID3D12Resource* pResource, UINT Subresource, UINT State);
```

#### Behavior

Validates that the given state matches the state of the subresource, assuming the state of the given subresource is known during recording of a command list (e.g. the resource was transitioned earlier in the same command list recording). If the state is not yet known this method sets the known state for further validation later in the same command list recording.

#### Parameters

<ins><!-- d3d12-review-inline:begin:diagnostics:D107-ID3D12DebugCommandList1-AssertResourceState-Parameters:0 -->`pResource` (input)<!-- d3d12-review-inline:end:diagnostics:D107-ID3D12DebugCommandList1-AssertResourceState-Parameters:0 --></ins>

Type: **ID3D12Resource\***

Specifies the [ID3D12Resource](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nn-d3d12-id3d12resource) to check.

`Subresource`

Type: **UINT**

The index of the subresource to check. This can be set to an index, or D3D12\_RESOURCE\_BARRIER\_ALL\_SUBRESOURCES.

`State`

Type: **UINT**

Specifies the state to check for. This can be one or more [D3D12_RESOURCE_STATES](synchronization.md#legacy-resource-states) flags Or'ed together.

#### Return values

Type: **BOOL**

This method returns **true** if the tracked state of the resource or subresource matches the specified state, **false** otherwise.

#### Debug layer

Since execution of command lists occurs sometime after recording, the state of a resource often cannot be known during command list recording. **AssertResourceState** gives an application developer the ability to impose an assumed state on a resource or subresource at a fixed recording point in a command list.

Often the state of a resource or subresource can either be known due to a previous barrier or inferred-by-use (for example, was used in an earlier call to [CopyBufferRegion](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nf-d3d12-id3d12graphicscommandlist-copybufferregion)) during command list recording. In such cases **AssertResourceState** can produce a debug message if the given state does not match the known or assumed state.

This API is for debug validation only and does not affect the actual runtime or GPU state of the resource.

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandList1-AssertResourceState-model-qualification:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The result describes validation of the tracked or assumed state, not observation of physical GPU state. For an unknown state, the layer can establish the asserted state for subsequent validation; a successful result in that case does not prove earlier work completed. `FALSE` also covers a null resource, invalid subresource index or unrecognized state bits. The assertion does not perform a resource transition.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandList1-AssertResourceState-model-qualification:0 -->

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandList1-AssertResourceState-model-qualification:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> [Legacy resource states](synchronization.md#legacy-resource-states) define the legal state combinations; [Resource assertions](#object-resource-assertions) defines common resource/subresource and lifetime requirements.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandList1-AssertResourceState-model-qualification:1 -->

<a id="id3d12debugcommandlist3-assertresourceaccess"></a>

### ID3D12DebugCommandList3::AssertResourceAccess

#### Declaration

```cpp
void AssertResourceAccess(ID3D12Resource* pResource, UINT Subresource, D3D12_BARRIER_ACCESS Access);
```

#### Behavior

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandList3-AssertResourceAccess-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Asserts the specified resource access in the command list validation model. [Synchronization's list access assertion contract](synchronization.md#debug-list-assert-access) defines the precise expectation, queue-timeline/resource-use scope and validation limitations. This method reports diagnostics and does not change the resource's actual access or layout.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandList3-AssertResourceAccess-behavior:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandList3-AssertResourceAccess-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pResource` identifies the live resource to assert; `Subresource` selects one subresource or `D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES` as defined in [Resource assertions](#object-resource-assertions). `Access` specifies the asserted `D3D12_BARRIER_ACCESS` value or valid combination. [Barrier access](synchronization.md#barrier-access) defines the access bits and their compatibility.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandList3-AssertResourceAccess-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandList3-AssertResourceAccess-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> None. This is a `void` diagnostic operation, not a `BOOL` or `HRESULT` completion query.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandList3-AssertResourceAccess-returns:0 -->

<a id="id3d12debugcommandlist3-asserttexturelayout"></a>

### ID3D12DebugCommandList3::AssertTextureLayout

#### Declaration

```cpp
void AssertTextureLayout(ID3D12Resource* pResource, UINT Subresource, D3D12_BARRIER_LAYOUT Layout);
```

#### Behavior

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandList3-AssertTextureLayout-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Asserts the specified texture layout in the command list validation model. [Synchronization's list layout assertion contract](synchronization.md#debug-list-assert-layout) defines the precise expectation, queue-timeline/resource-use scope and validation limitations. This method reports diagnostics and does not change the resource's actual access or layout.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandList3-AssertTextureLayout-behavior:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandList3-AssertTextureLayout-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pResource` identifies the live resource to assert; `Subresource` selects one subresource or `D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES` as defined in [Resource assertions](#object-resource-assertions). `Layout` specifies the asserted `D3D12_BARRIER_LAYOUT`. Buffers have no texture layout; a layout assertion on a buffer performs no layout check. [Barrier layouts](synchronization.md#barrier-layout) defines layout applicability.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandList3-AssertTextureLayout-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandList3-AssertTextureLayout-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> None. This is a `void` diagnostic operation, not a `BOOL` or `HRESULT` completion query.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandList3-AssertTextureLayout-returns:0 -->

<a id="id3d12debugcommandqueue-assertresourcestate"></a>

### ID3D12DebugCommandQueue::AssertResourceState

#### Declaration

```cpp
BOOL AssertResourceState(ID3D12Resource* pResource, UINT Subresource, UINT State);
```

#### Behavior

Checks whether a resource, or subresource, is in a specified state, or not.

#### Parameters

<ins><!-- d3d12-review-inline:begin:diagnostics:D107-ID3D12DebugCommandQueue-AssertResourceState-Parameters:0 -->`pResource` (input)<!-- d3d12-review-inline:end:diagnostics:D107-ID3D12DebugCommandQueue-AssertResourceState-Parameters:0 --></ins>

Type: **ID3D12Resource\***

Specifies the [ID3D12Resource](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nn-d3d12-id3d12resource) to check.

`Subresource`

Type: **UINT**

The index of the subresource to check. This can be set to an index, or D3D12\_RESOURCE\_BARRIER\_ALL\_SUBRESOURCES.

`State`

Type: **UINT**

Specifies the state to check for. This can be one or more D3D12\_RESOURCE\_STATES flags Or'ed together.

#### Return values

Type: **BOOL**

This method returns true if the resource or subresource is in the specified state, false otherwise.

#### Debug layer

This method is very similar to [ID3D12DebugCommandList::AssertResourceState](#id3d12debugcommandlist-assertresourcestate), however there are methods on the command queue that work directly with resources that might need to be monitored (for example [ID3D12CommandQueue::CopyTileMappings](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nf-d3d12-id3d12commandqueue-copytilemappings)).

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandQueue-AssertResourceState-model-qualification:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The result describes validation of the tracked or assumed state, not observation of physical GPU state. For an unknown state, the layer can establish the asserted state for subsequent validation; a successful result in that case does not prove earlier work completed. `FALSE` also covers a null resource, invalid subresource index or unrecognized state bits. The assertion does not perform a resource transition.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandQueue-AssertResourceState-model-qualification:0 -->

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandQueue-AssertResourceState-model-qualification:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The assertion is ordered with queue operations in the queue's validation model, including resource uses performed directly by queue methods. [Legacy resource states](synchronization.md#legacy-resource-states) define the legal state combinations; [Resource assertions](#object-resource-assertions) defines common resource/subresource and lifetime requirements.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandQueue-AssertResourceState-model-qualification:1 -->

<a id="id3d12debugcommandqueue1-assertresourceaccess"></a>

### ID3D12DebugCommandQueue1::AssertResourceAccess

#### Declaration

```cpp
void AssertResourceAccess(ID3D12Resource* pResource, UINT Subresource, D3D12_BARRIER_ACCESS Access);
```

#### Behavior

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandQueue1-AssertResourceAccess-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Asserts the specified resource access in the command queue validation model. [Synchronization's queue access assertion contract](synchronization.md#debug-queue-assert-access) defines the precise expectation, queue-timeline/resource-use scope and validation limitations. This method reports diagnostics and does not change the resource's actual access or layout.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandQueue1-AssertResourceAccess-behavior:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandQueue1-AssertResourceAccess-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pResource` identifies the live resource to assert; `Subresource` selects one subresource or `D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES` as defined in [Resource assertions](#object-resource-assertions). `Access` specifies the asserted `D3D12_BARRIER_ACCESS` value or valid combination. [Barrier access](synchronization.md#barrier-access) defines the access bits and their compatibility.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandQueue1-AssertResourceAccess-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandQueue1-AssertResourceAccess-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> None. This is a `void` diagnostic operation, not a `BOOL` or `HRESULT` completion query.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandQueue1-AssertResourceAccess-returns:0 -->

<a id="id3d12debugcommandqueue1-asserttexturelayout"></a>

### ID3D12DebugCommandQueue1::AssertTextureLayout

#### Declaration

```cpp
void AssertTextureLayout(ID3D12Resource* pResource, UINT Subresource, D3D12_BARRIER_LAYOUT Layout);
```

#### Behavior

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandQueue1-AssertTextureLayout-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Asserts the specified texture layout in the command queue validation model. [Synchronization's queue layout assertion contract](synchronization.md#debug-queue-assert-layout) defines the precise expectation, queue-timeline/resource-use scope and validation limitations. This method reports diagnostics and does not change the resource's actual access or layout.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandQueue1-AssertTextureLayout-behavior:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandQueue1-AssertTextureLayout-parameters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pResource` identifies the live resource to assert; `Subresource` selects one subresource or `D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES` as defined in [Resource assertions](#object-resource-assertions). `Layout` specifies the asserted `D3D12_BARRIER_LAYOUT`. Buffers have no texture layout; a layout assertion on a buffer performs no layout check. [Barrier layouts](synchronization.md#barrier-layout) defines layout applicability.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandQueue1-AssertTextureLayout-parameters:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:D107-ID3D12DebugCommandQueue1-AssertTextureLayout-returns:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> None. This is a `void` diagnostic operation, not a `BOOL` or `HRESULT` completion query.

<!-- d3d12-review-alert:end:diagnostics:D107-ID3D12DebugCommandQueue1-AssertTextureLayout-returns:0 -->

<a id="driver-marker-allocation-comment"></a>

## Driver marker, allocation and shader-comment queries

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_SET_MARKER )( D3D12DDI_HCOMMANDLIST, UINT64 );

typedef VOID ( APIENTRY* PFND3D12DDI_GET_DEBUG_ALLOCATION_INFO_0014 )(
    D3D12DDI_HDEVICE hDevice,
    D3D12DDI_HANDLE_AND_TYPE Object,
    _Inout_ UINT* pNumVirtualAddressInfos,
    _Out_writes_to_opt_(*pNumVirtualAddressInfos, *pNumVirtualAddressInfos) D3D12DDI_DEBUG_VIRTUAL_ADDRESS_ALLOCATION_INFO_0012* pVirtualAddressInfos,
    _Inout_ UINT* pNumKMTInfos,
    _Out_writes_to_opt_(*pNumKMTInfos, *pNumKMTInfos) D3D12DDI_DEBUG_KMT_ALLOCATION_INFO_0014* pKMTInfos
    );

typedef struct D3D12DDI_DEBUG_VIRTUAL_ADDRESS_ALLOCATION_INFO_0012
{
    UINT32 PhysicalAdapterIndex;
    D3D12DDI_GPU_VIRTUAL_ADDRESS StartAddress;
    D3D12DDI_GPU_VIRTUAL_ADDRESS EndAddress;
} D3D12DDI_DEBUG_VIRTUAL_ADDRESS_ALLOCATION_INFO_0012;

typedef struct D3D12DDI_DEBUG_KMT_ALLOCATION_INFO_0014
{
    UINT32 PhysicalAdapterIndex;
    D3DKMT_HANDLE hAllocation;
    UINT64 Offset;
    UINT64 Size;
} D3D12DDI_DEBUG_KMT_ALLOCATION_INFO_0014;

typedef HRESULT ( APIENTRY* PFND3D12DDI_RETRIEVE_SHADER_COMMENT_0003 )(
    D3D12DDI_HDEVICE, D3D12DDI_HPIPELINESTATE, _Out_writes_z_(*CharacterCountIncludingNullTerminator) WCHAR * pBuffer, _Inout_ SIZE_T * CharacterCountIncludingNullTerminator );
```

<!-- d3d12-review-alert:begin:diagnostics:CS-diagnostic-services:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> SetMarker receives a `UINT64` runtime marker sequence number, not the application's metadata/pointer/byte-count tuple. Its ordinary-handle signature is retained in both 3D layouts and the selected video tables.

<!-- d3d12-review-alert:end:diagnostics:CS-diagnostic-services:0 -->

<!-- d3d12-review-alert:begin:diagnostics:CS-diagnostic-services:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> GetDebugAllocationInfo reports per-physical-adapter GPU ranges and kernel allocation records through independent count/array pairs. Null arrays query sizes. The driver reports current counts even if they changed since an earlier query and must not exceed supplied capacities.

<!-- d3d12-review-alert:end:diagnostics:CS-diagnostic-services:1 -->

<!-- d3d12-review-alert:begin:diagnostics:CS-diagnostic-services:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> RetrieveShaderComment counts `WCHAR` elements including the terminator. The runtime converts the byte count used by `WKPDID_CommentStringW`.

<!-- d3d12-review-alert:end:diagnostics:CS-diagnostic-services:2 -->

<a id="gbv-diagnostic-snapshots"></a>

## GPU-based-validation diagnostic snapshots

<!-- d3d12-review-alert:begin:diagnostics:AB-gbv-model:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> These diagnostic queries require an available GBV diagnostic interface and
> enabled, non-bypassed GPU-based validation. The three state queries also
> require state tracking. They can perform GPU readback and wait for that
> readback, but do not quiesce unrelated application producers automatically.
> Applications must establish the completion/synchronization needed for the
> data they intend to inspect.

<!-- d3d12-review-alert:end:diagnostics:AB-gbv-model:0 -->

<!-- d3d12-review-alert:begin:diagnostics:AB-gbv-model:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returned state words are GBV diagnostic observations, not permission to
> ignore normative resource-state/access/lifetime requirements. Internal hashes
> and database offsets are not persistent application identifiers or GPU
> virtual addresses. Reserved neighboring vtable slots establish no operation.

<!-- d3d12-review-alert:end:diagnostics:AB-gbv-model:1 -->

<a id="api-id3d12gbvdiagnostics-getgbventiresubresourcestatesdata"></a>

### ID3D12GBVDiagnostics::GetGBVEntireSubresourceStatesData

#### Declaration

```cpp
HRESULT GetGBVEntireSubresourceStatesData(
    ID3D12Resource* pResource,
    int *pData,
    UINT DataSize);
```

#### Behavior

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12gbvdiagnostics-getgbventiresubresourcestatesdata-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Copies the tracked state-word block to CPU storage. Buffer resources use their subresource words; textures have a leading uniform-state word followed by subresource words.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12gbvdiagnostics-getgbventiresubresourcestatesdata-contract:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12gbvdiagnostics-getgbventiresubresourcestatesdata-contract:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pResource` is the queried resource. `pData` is the output buffer and `DataSize` is bytes, not an int-element count. Capacity must cover the selected word layout; insufficient capacity fails.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12gbvdiagnostics-getgbventiresubresourcestatesdata-contract:2 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12gbvdiagnostics-getgbventiresubresourcestatesdata-contract:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns `S_OK` or a failure. Unavailable/bypassed GBV, unavailable state tracking for a state query, invalid required inputs/subresource/capacity, and readback failures do not return a fabricated valid snapshot.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12gbvdiagnostics-getgbventiresubresourcestatesdata-contract:4 -->

<a id="api-id3d12gbvdiagnostics-getgbvsubresourcestate"></a>

### ID3D12GBVDiagnostics::GetGBVSubresourceState

#### Declaration

```cpp
HRESULT GetGBVSubresourceState(
    ID3D12Resource* pResource,
    UINT Subresource,
    int *pData);
```

#### Behavior

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12gbvdiagnostics-getgbvsubresourcestate-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Copies the GBV state word for the selected subresource, skipping the texture's leading uniform word.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12gbvdiagnostics-getgbvsubresourcestate-contract:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12gbvdiagnostics-getgbvsubresourcestate-contract:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pResource` selects the resource; `Subresource` must be in range; `pData` receives one state word.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12gbvdiagnostics-getgbvsubresourcestate-contract:2 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12gbvdiagnostics-getgbvsubresourcestate-contract:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns `S_OK` or a failure. Unavailable/bypassed GBV, unavailable state tracking for a state query, invalid required inputs/subresource/capacity, and readback failures do not return a fabricated valid snapshot.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12gbvdiagnostics-getgbvsubresourcestate-contract:4 -->

<a id="api-id3d12gbvdiagnostics-getgbvresourceuniformstate"></a>

### ID3D12GBVDiagnostics::GetGBVResourceUniformState

#### Declaration

```cpp
HRESULT GetGBVResourceUniformState(
    ID3D12Resource* pResource,
    int *pData);
```

#### Behavior

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12gbvdiagnostics-getgbvresourceuniformstate-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Copies the leading tracked uniform-state word; for a buffer its sole state word occupies that position.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12gbvdiagnostics-getgbvresourceuniformstate-contract:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12gbvdiagnostics-getgbvresourceuniformstate-contract:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pResource` identifies the resource; `pData` receives one diagnostic state word.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12gbvdiagnostics-getgbvresourceuniformstate-contract:2 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12gbvdiagnostics-getgbvresourceuniformstate-contract:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns `S_OK` or a failure. Unavailable/bypassed GBV, unavailable state tracking for a state query, invalid required inputs/subresource/capacity, and readback failures do not return a fabricated valid snapshot.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12gbvdiagnostics-getgbvresourceuniformstate-contract:4 -->

<a id="api-id3d12gbvdiagnostics-getgbvresourceinfo"></a>

### ID3D12GBVDiagnostics::GetGBVResourceInfo

#### Declaration

```cpp
HRESULT GetGBVResourceInfo(
    ID3D12Resource* pResource,
    D3D12_RESOURCE_DESC* pResourceDesc,
    UINT32* pResourceHash,
    UINT32* pSubresourceStatesByteOffset);
```

#### Behavior

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12gbvdiagnostics-getgbvresourceinfo-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Retrieves the diagnostic resource hash and state-database byte offset. The returned description is the GBV projection (array/depth and mip information and its simultaneous-access flag), not a full replacement for ID3D12Resource::GetDesc.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12gbvdiagnostics-getgbvresourceinfo-contract:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12gbvdiagnostics-getgbvresourceinfo-contract:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pResource` is required. Each of pResourceDesc, pResourceHash and pSubresourceStatesByteOffset is optional output storage. The offset is into the diagnostic state database, not the resource's allocation.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12gbvdiagnostics-getgbvresourceinfo-contract:2 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12gbvdiagnostics-getgbvresourceinfo-contract:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns `S_OK` or a failure. Unavailable/bypassed GBV, unavailable state tracking for a state query, invalid required inputs/subresource/capacity, and readback failures do not return a fabricated valid snapshot.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12gbvdiagnostics-getgbvresourceinfo-contract:4 -->

<a id="instrumentation-validation-controls"></a>

## Tool instrumentation and runtime-validation controls

<a id="api-id3d12tools-enableshaderinstrumentation"></a>

### ID3D12Tools::EnableShaderInstrumentation

#### Declaration

```cpp
void EnableShaderInstrumentation(
    BOOL bEnable);
```

#### Behavior

This method enables tools such as PIX to instrument shaders.

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12tools-enableshaderinstrumentation-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Configures shader instrumentation for the associated tool/runtime
> configuration. It is not GPU-based validation, a promise that every shader
> has already been recompiled, or a change to resource bindings. Device
> creation consumes the relevant startup configuration.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12tools-enableshaderinstrumentation-contract:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12tools-enableshaderinstrumentation-contract:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `bEnable` selects enabled/disabled. The tools-only and developer-mode restrictions remain required; this is not an ordinary application's optimization switch.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12tools-enableshaderinstrumentation-contract:2 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12tools-enableshaderinstrumentation-contract:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns no value. It does not synchronize running GPU work or report compilation completion.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12tools-enableshaderinstrumentation-contract:4 -->

<a id="api-id3d12tools-shaderinstrumentationenabled"></a>

### ID3D12Tools::ShaderInstrumentationEnabled

#### Declaration

```cpp
BOOL ShaderInstrumentationEnabled();
```

#### Behavior

Determines whether shader instrumentation is enabled.

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12tools-shaderinstrumentationenabled-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns the associated configuration's shader-instrumentation setting, not proof that existing work has completed or every current shader was instrumented.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12tools-shaderinstrumentationenabled-contract:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12tools-shaderinstrumentationenabled-contract:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns BOOL enabled/disabled under the documented tool/developer-mode contract.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12tools-shaderinstrumentationenabled-contract:2 -->

<a id="api-id3d12runtimevalidationcontrol-disablefailuresfromstrictervalidationinapplocalruntime"></a>

### ID3D12RuntimeValidationControl::DisableFailuresFromStricterValidationInAppLocalRuntime

#### Declaration

```cpp
void DisableFailuresFromStricterValidationInAppLocalRuntime(
    BOOL bDisable);
```

#### Behavior

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12runtimevalidationcontrol-disablefailuresfromstrictervalidationinapplocalruntime-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Sets the configuration's compatibility control for newly stricter app-local
> runtime validation failures. It does not disable all validation, authorize
> arbitrary invalid input, or change hardware resource/access requirements.
> Existing device state is not retroactively rewritten by changing the setting.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12runtimevalidationcontrol-disablefailuresfromstrictervalidationinapplocalruntime-contract:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12runtimevalidationcontrol-disablefailuresfromstrictervalidationinapplocalruntime-contract:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `bDisable` enables/disables this scoped suppression setting. Apply configuration before the device creations intended to consume it.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12runtimevalidationcontrol-disablefailuresfromstrictervalidationinapplocalruntime-contract:2 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12runtimevalidationcontrol-disablefailuresfromstrictervalidationinapplocalruntime-contract:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns no value. This is startup/configuration state, not a command-list operation or GPU fence.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12runtimevalidationcontrol-disablefailuresfromstrictervalidationinapplocalruntime-contract:4 -->

<a id="api-id3d12runtimevalidationcontrol-failuresfromstrictervalidationinapplocalruntimedisabled"></a>

### ID3D12RuntimeValidationControl::FailuresFromStricterValidationInAppLocalRuntimeDisabled

#### Declaration

```cpp
BOOL FailuresFromStricterValidationInAppLocalRuntimeDisabled();
```

#### Behavior

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12runtimevalidationcontrol-failuresfromstrictervalidationinapplocalruntimedisabled-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Queries that configuration's stricter-validation compatibility setting; it is not the result of validating a particular program or device.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12runtimevalidationcontrol-failuresfromstrictervalidationinapplocalruntimedisabled-contract:0 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12runtimevalidationcontrol-failuresfromstrictervalidationinapplocalruntimedisabled-contract:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns BOOL for the configured setting.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12runtimevalidationcontrol-failuresfromstrictervalidationinapplocalruntimedisabled-contract:2 -->

<a id="sharing-contract-notifications"></a>

## Sharing-contract diagnostic notifications

<a id="api-id3d12sharingcontract-present"></a>

### ID3D12SharingContract::Present

#### Declaration

```cpp
void Present(
    ID3D12Resource* pResource,
    UINT Subresource,
    HWND window);
```

#### Behavior

Notifies diagnostic tools about an end-of-frame operation without the use of a swap chain. Calling this API enables usage of tools like PIX with applications that either don't render to a window, or that do so in non-traditional ways.

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12sharingcontract-present-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This diagnostic end-of-frame notification is not IDXGISwapChain::Present,
> does not create a swap chain and does not imply a display flip or GPU-completion
> wait. It enables tooling for offscreen or nontraditional presentation.
> The selected subresource retains its COMMON/PRESENT access requirements;
> notification does not insert a transition or replace the applicable barrier model.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12sharingcontract-present-contract:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12sharingcontract-present-contract:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pResource` identifies the final-frame resource; `Subresource` selects its subresource. `window` optionally identifies a tool UI target. The resource retains required access/lifetime constraints.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12sharingcontract-present-contract:2 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12sharingcontract-present-contract:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns no value; diagnostic notification is not a presentation-status HRESULT.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12sharingcontract-present-contract:4 -->

<a id="api-id3d12sharingcontract-sharedfencesignal"></a>

### ID3D12SharingContract::SharedFenceSignal

#### Declaration

```cpp
void SharedFenceSignal(
    ID3D12Fence* pFence,
    UINT64 FenceValue);
```

#### Behavior

Signals a shared fence between the D3D layers and diagnostics tools.

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12sharingcontract-sharedfencesignal-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Communicates the shared-fence/value signal through the layer/tooling sharing
> contract. It does not by its void CPU return establish that GPU work completed;
> ordinary queue/fence/resource synchronization requirements remain.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12sharingcontract-sharedfencesignal-contract:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12sharingcontract-sharedfencesignal-contract:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pFence` is a shared fence; `FenceValue` is its 64-bit signal value, not a resource offset.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12sharingcontract-sharedfencesignal-contract:2 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12sharingcontract-sharedfencesignal-contract:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns no value. The selected wrapper diagnoses a non-shared fence; tooling observation is distinct from a successful queue Signal HRESULT.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12sharingcontract-sharedfencesignal-contract:4 -->

<a id="api-id3d12sharingcontract-begincapturablework"></a>

### ID3D12SharingContract::BeginCapturableWork

#### Declaration

```cpp
void BeginCapturableWork(
    REFGUID guid);
```

#### Behavior

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12sharingcontract-begincapturablework-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Delineates logical work for capture tools. The GUID differentiates categories
> of delineation; it is not a resource identity or hardware command. With no
> interested tool the selected runtime/layer can ignore the notification.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12sharingcontract-begincapturablework-contract:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12sharingcontract-begincapturablework-contract:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `guid` identifies the capture-work category; begin/end delimit that logical region.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12sharingcontract-begincapturablework-contract:2 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12sharingcontract-begincapturablework-contract:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns no value. This notification does not reset pipeline state, add barriers or complete GPU work.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12sharingcontract-begincapturablework-contract:4 -->

<a id="api-id3d12sharingcontract-endcapturablework"></a>

### ID3D12SharingContract::EndCapturableWork

#### Declaration

```cpp
void EndCapturableWork(
    REFGUID guid);
```

#### Behavior

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12sharingcontract-endcapturablework-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Delineates logical work for capture tools. The GUID differentiates categories
> of delineation; it is not a resource identity or hardware command. With no
> interested tool the selected runtime/layer can ignore the notification.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12sharingcontract-endcapturablework-contract:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12sharingcontract-endcapturablework-contract:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `guid` identifies the capture-work category; begin/end delimit that logical region.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12sharingcontract-endcapturablework-contract:2 -->

#### Return values

<!-- d3d12-review-alert:begin:diagnostics:AB-id3d12sharingcontract-endcapturablework-contract:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns no value. This notification does not reset pipeline state, add barriers or complete GPU work.

<!-- d3d12-review-alert:end:diagnostics:AB-id3d12sharingcontract-endcapturablework-contract:4 -->
