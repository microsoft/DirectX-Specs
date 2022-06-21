# D3D12 Independent Devices

## Background

Currently all calls to `D3D12CreateDevice` for the same adapter (based on LUID) will return the same `ID3D12Device*` object, until that object's refcount reaches 0 and then a new device can be created. We commonly refer to this behavior as a "singleton" device, or "singleton per-adapter."

### Why did we do this?

D3D12's singleton device behavior was borne out of problems seen with D3D11, attempting to make them non-issues. For the most part, this was not really successful.

#### Cross-device usage

A common bug in D3D11 apps that have multiple devices is taking an object (typically a resource, or resource view) created on one device, and using it with another device. When these two devices are on the same GPU, which is the common case, this often mostly works, but sometimes can break in fantastic ways, which can be difficult to debug since they don't often reproduce on a developer's PC. In theory this could be mitigated by a more thorough debug layer, but even then that relies on developers running the reproducing scenario with the debug layer enabled - which wouldn't necessarily happen if the bug is in a plugin or some type of overlay/hook component.

By forcing all D3D12 devices for a given adapter to actually *be* the same device, it becomes impossible to accidentally make this mistake.

Out of all of the motivations, this is the only one I see where it actually has panned out to become useful. Since apps can rely on this singleton behavior, you don't need to pass around a D3D12 device, and can instead just `D3D12CreateDevice()` wherever you would need one, with the knowledge that it'll either create one if there isn't one, or return an existing one (cheaply) if there is one. However, this design runs into problems when you try to recover from device removal...

#### Recovery from driver upgrade

Recovering from device removal is tricky. In the D3D9 era, everyone had to do it because you got "device lost" anytime there was a monitor mode change. In D3D11, it was more optional, because it happened less frequently - games often wouldn't even try, but system software would do their best. Some of this system software uses multiple independent components that would use D3D11 under the covers, e.g. D2D or XAML. When an adapter-wide device removal event happens, each of these component would then need to recover from it on their own independent device. And for the most part, this works, until driver upgrade.

When a driver gets upgraded, all devices in the process become removed. But in order to properly recover from driver upgrade, *all* of those devices need to be fully released, or else the usermode driver (UMD) DLLs would remain loaded in the process. If one component attempted to recover *only* its device, it would often fail, because the UMD, or some sub-component DLL of the UMD, was still loaded. Attempting to `LoadLibrary("filename")` or `GetProcAddress("function")` could end up retrieving the wrong file, resulting in bad HRESULTs (since the old UMD mismatches with the new KMD) or crashes. The only way to properly recover from driver upgrade is for *all* components to release all devices in the process, before any one of them recovers - and if any component leaks a reference on one of their devices or device children, then it becomes impossible to recover. And since driver upgrade is such an uncommon scenario, it often went untested, so this scenario was commonly broken.

D3D12 wanted to ensure that we didn't end up in this mismatched UMD/KMD scenario anymore, by forcing *all* device removed recovery scenarios to look like the driver upgrade scenario. If there were multiple components sharing a device, they all had to release it before any component could re-created.

In practice, this actually just means that many D3D12 apps can't recover from device removal, because those components don't have recovery APIs that work like this.

#### Simplifying memory management

In the CPU world, the domain of memory management is a process. Looking at things like memory commit in task manager, you don't have any kind of hierarchy underneath a process. But when you look at graphics memory usage, the domain there is a device - and a process can have multiple devices. If a process only had one device per adapter, then for any given adapter, you could manage that process's graphics memory at the same granularity as its CPU memory.

At least, this is what I remember being one of the reasons when the singleton idea was proposed and implemented. But I haven't seen any benefits from this in practice, either in code complexity or reporting.

The one benefit here is somewhat more abstract - since you don't need to use shared resources to use the same memory on multiple devices (since there aren't multiple devices), you are able to avoid double-counting the same memory towards the overall process commit. However if you *still* end up using shared resources, e.g. because you didn't know about or didn't want to depend on the singleton behavior, you can still double-count the same memory if you open the shared resource multiple times on the same device.

#### Heterogeneous computing

Similar to the above, in the CPU world, you don't need to explicitly assign your functions to run on particular cores, you can just call a function and it'll execute. There's been a rise in heterogeneous programming models, like C++ AMP, CUDA, OpenMP, DPC++, etc, which often see GPU acceleration of portions of a program occur "seamlessly." That is to say, the GPU-accelerated portions need to be annotated, but you don't need to initialize a D3D/VK/CL device and explicitly dispatch it - the device and dispatch happens magically.

By providing a global device construct, we were anticipating that we'd help pave the way for these heterogeneous computing frameworks to easily leverage D3D12 without needing to have the code authors explicitly initialize a device or pass around the specific device to be used. It also meant that you could get simpler interop with other users of D3D - you could take your GPU-computed data that was dispatched on your behalf, and interop with a component that's explicitly using D3D, using the same device, because it's a global device.

### What problems are we seeing?

The rise of mapping layers to D3D12 is particularly highlighting some issues with this design. Now that we have components which use D3D12 under the covers, since the app doesn't know about them, the app isn't able to coordinate things. Two particular categories of things come to mind:

#### Global configuration

In D3D11, things like debug layer usage were controlled by flags during device creation. In D3D12, these things moved to global state that needed to be set before a device was created. The idea was to keep `D3D12CreateDevice()` as a simple entrypoint, and anything off the beaten path, like debug layer enablement, would be a separate API to invoke. Some properties, like the debug layer, are dynamic. Others, like the Agility SDK version selection, are required to be static, properties exported from the main .exe.

Now imagine an app that uses D3D12 and Vulkan. The app initializes D3D12 first, and Vulkan second. What happens if that Vulkan implementation is a mapping layer (VkOn12) and wants to control some property of the device, e.g. debug layer, or Agility SDK, or experimental shader models? There's two options:
1. Attempt to apply whatever configuration is needed by the mapping layer. This will trigger device removal for the app's D3D12 device. Now, the mapping layer can't actually initialize D3D12 with the new configuration until the app gets around to releasing / re-creating its device... which it most likely won't do because most D3D12 apps don't recover from device removed.
2. Realize that the app already created a device (how??) and opt not to change the configuration, even if it means that the layer might not work correctly.

#### Agility SDK with components

Above, I mentioned that the Agility SDK configuration is one of the things that components in a process might fight over. Well, it *would* be, if it was even an option. Today there exists `ID3D12SDKConfiguration` interface, which allows you to `SetSDKVersion` for selecting a redistributable version. However, this interface is only available in developer mode, making it unusable for components like a graphics mapping layer. Additionally, it requires a relative path from the .exe to the Agility SDK DLL. If the Agility SDK DLL resides on a different drive from the .exe, constructing a relative path is impossible - and even in the case where it is possible, it's cumbersome.

#### Device removed recovery

Similar to above, if there's a device removal, the D3D12 design was to require there to be an orchestrator who would be responsible for coordinating the teardown of all devices, before any device could be re-created. The intention here was to force a design requirement on middleware to expose some interface so that they could be coordinated. But now we want to implement some of the components in the process using D3D12 *without* the app's knowledge, along existing well-defined API boundaries, so how can the app coordinate them?

### Conclusion

Putting this all together, it seems that the decision for D3D to use singleton devices was premature - it makes sense in some scenarios for there to be a single global device that can be used by all of the components in a process, but *forcing* all components in a process to use a single device *without* also providing infrastructure to allow those components to coordinate their usage and requirements ends up causing more problems than it solves. To that end, we've concluded that we need to enable components to use separate D3D devices.

The design goals above could have been addressed by adding more APIs to D3D12 itself to allow coordination of components, or they could have been addressed by adding additional infrastructure on top of D3D12 - e.g. DXCore could have APIs for interacting with process/thread state to retrieve a "current" device, and could have registration APIs for laying out pre-device-creation requirements, and callbacks for device removed recovery coordination. At this point, this infrastructure does not exist in either D3D12 itself, or in another component, and so existing apps will have extreme difficulty with new D3D12 users dynamically entering their process without their knowledge - as will happen when D3D11 devices become D3D11On12, or similar with Vulkan devices becoming VulkanOn12.

Once we accept the fact that new APIs are required to enable proper singleton use, and that apps and components must be authored to take advantage of these new APIs, the only question that remains is where do these APIs live? Do they need to be a part of D3D? Or can they live in an external framework? It seems that either would be acceptable, but until they exist, components need to be able to uncouple their devices from each other.

## Proposal

This spec proposes two key things:
1. Allow multiple D3D12 devices to be created on the same adapter using a new API.
2. Allow control of the Agility SDK to be dynamic, on retail (non-developer-mode) systems, for devices created using this API.

### API

```c++
enum D3D12_DEVICE_FACTORY_FLAGS
{
    D3D12_DEVICE_FACTORY_FLAG_NONE = 0,
    D3D12_DEVICE_FACTORY_FLAG_ALLOW_RETURNING_EXISTING_DEVICE = 1,
    D3D12_DEVICE_FACTORY_FLAG_ALLOW_RETURNING_INCOMPATIBLE_EXISTING_DEVICE = 2,
    D3D12_DEVICE_FACTORY_FLAG_DISALLOW_STORING_NEW_DEVICE_AS_SINGLETON = 4,
};

interface ID3D12DeviceFactory : IUnknown
{
    HRESULT InitializeFromGlobalState();
    void ApplyToGlobalState();

    HRESULT SetFlags(D3D12_DEVICE_FACTORY_FLAGS flags);
    D3D12_DEVICE_FACTORY_FLAGS GetFlags();

    HRESULT GetConfigurationInterface(
        REFCLSID clsid,
        REFIID   riid,
        void   **ppv);
    HRESULT EnableExperimentalFeatures(
       UINT      NumFeatures,
       const IID *pIIDs,
       void      *pConfigurationStructs,
       UINT      *pConfigurationStructSizes);

    HRESULT CreateDevice(IUnknown *adapter, REFIID riid, void **ppvDevice);
};

interface ID3D12SDKConfiguration1 : ID3D12SDKConfiguration
{
    HRESULT CreateDeviceFactory(
        UINT SDKVersion,
        LPCSTR SDKPath,
        REFIID riid, // Expected: ID3D12DeviceFactory
        void** ppvFactory
        );
    void FreeUnusedSDKs();
};

enum D3D12_DEVICE_FLAGS
{
    D3D12_DEVICE_FLAG_NONE = 0,
    D3D12_DEVICE_FLAG_DEBUG_LAYER_ENABLED = 0x1,
    D3D12_DEVICE_FLAG_GPU_BASED_VALIDATION_ENABLED = 0x2,
    D3D12_DEVICE_FLAG_SYNCHRONIZED_COMMAND_QUEUE_VALIDATION_DISABLED = 0x4,
    D3D12_DEVICE_FLAG_DRED_AUTO_BREADCRUMBS_ENABLED = 0x8,
    D3D12_DEVICE_FLAG_DRED_PAGE_FAULT_REPORTING_ENABLED = 0x10,
    D3D12_DEVICE_FLAG_DRED_WATSON_REPORTING_ENABLED = 0x20,
    D3D12_DEVICE_FLAG_DRED_BREADCRUMB_CONTEXT_ENABLED = 0x40,
    D3D12_DEVICE_FLAG_DRED_USE_MARKERS_ONLY_BREADCRUMBS = 0x80,
    D3D12_DEVICE_FLAG_SHADER_INSTRUMENTATION_ENABLED = 0x100,
    D3D12_DEVICE_FLAG_AUTO_DEBUG_NAME_ENABLED = 0x200,
    D3D12_DEVICE_FLAG_FORCE_LEGACY_STATE_VALIDATION = 0x400,
};
struct D3D12_DEVICE_CONFIGURATION_DESC
{
    D3D12_DEVICE_FLAGS Flags;
    UINT GpuBasedValidationFlags; // D3D12_GPU_BASED_VALIDATION_FLAGS from d3d12sdklayers.h
    UINT SDKVersion;
    UINT NumEnabledExperimentalFeatures;
};

interface ID3D12DeviceConfiguration : IUnknown
{
    D3D12_DEVICE_CONFIGURATION_DESC GetDesc();
    HRESULT GetEnabledExperimentalFeatures(GUID *pGuids, UINT NumGuids);

    HRESULT SerializeVersionedRootSignature(const D3D12_VERSIONED_ROOT_SIGNATURE_DESC *pDesc, ID3DBlob **ppResult, ID3DBlob **ppError);

    HRESULT CreateVersionedRootSignatureDeserializer(const void* pBlob, SIZE_T Size, REFIID riid, void **ppvDeserializer);
};
```

#### API details

**`D3D12_DEVICE_FACTORY_FLAGS`**

|Flag|Meaning|
|----|-------|
|`D3D12_DEVICE_FACTORY_FLAG_NONE`|The default behavior is for this new device to be completely independent of existing devices. `CreateDevice` will fail with `DXGI_ERROR_ALREADY_EXISTS` if a device exists and the driver for that device is not capable of supporting independent devices. If no device already exists, and `CreateDevice` succeeds, if the driver does not support independent devices, then the new device will be installed as the new singleton for that adapter.|
|`D3D12_DEVICE_FACTORY_FLAG_ALLOW_RETURNING_EXISTING_DEVICE`|Modifies the behavior of `CreateDevice`: If a device exists for the given adapter, and its configuration is compatible with the requested configuration, that device may be returned instead. If the configuration is incompatible, `DXGI_ERROR_ALREADY_EXISTS` will be returned.|
|`D3D12_DEVICE_FACTORY_FLAG_ALLOW_RETURNING_INCOMPATIBLE_EXISTING_DEVICE`|Can only be specified with `D3D12_DEVICE_FACTORY_FLAG_ALLOW_RETURNING_EXISTING_DEVICE`. Further modifies the behavior of `CreateDevice`, indicating that the requested configuration is merely a preference, and any existing device may be returned. In the case that an incompatible device is returned, and the debug layer is on, the debug layer record a message indicating as such, and what incompatibilities are present.|
|`D3D12_DEVICE_FACTORY_FLAG_DISALLOW_STORING_NEW_DEVICE_AS_SINGLETON`|Modifies the behavior of `CreateDevice`: If a new device is created, and the driver does not support independent devices, the device will be destroyed and the call failed with `DXGI_ERROR_UNSUPPORTED` rather than storing a new global device.|

**`ID3D12DeviceFactory`**

This interface can be retrieved from `ID3D12SDKConfiguration1::CreateDeviceFactory` (where `ID3D12SDKConfiguration1` is created from `D3D12GetInterface` with `CLSID_D3D12SDKConfiguration`). The returned object can retrieve further configuration settings using `ID3D12DeviceFactory::GetConfigInterface` with `CLSID_D3D12Debug`, `CLSID_D3D12Tools`, and `CLSID_D3D12DeviceRemovedExtendedData`.

Any settings applied using any of these interfaces, when that interface was queried from a D3D12 device factory object, will apply only to that factory object and not globally, unless/until `ApplyToGlobalState` is set. If the `InitializeFromGlobalState` API is not called, the device factory object will begin in a well-defined state, which matches the state if no API is invoked on any of the above-mentioned interfaces, nor the `D3D12EnableExperimentalFeatures` export. The `InitializeFromGlobalState` API may not always be available. It requires that the globally-configured `D3D12Core.dll` be updated to support device factories, or else some of the global state is not queryable.

After calling `CreateDevice`, the state of this object is copied into the newly returned device. If the device is installed as the singleton, then the state is also copied into the global configuration state.

A device factory can be modified after a device is created, and then used to create additional devices. If a blank slate is desired, the factory can be discarded and a new one created.

|API|Description|
|---|-----------|
|`InitializeFromGlobalState`|Retrieve the current global configuration state and stores it in this object. This allows future modifications to be incremental on top of the global state. If the global state is owned by an older version of `D3D12Core.dll`, this API will return `D3D12_ERROR_INVALID_REDIST`.|
|`ApplyToGlobalState`|Equivalent to replaying the various configuration API calls to the equivalent global configuration objects/exports. This includes `ID3D12SDKConfiguration::SetSDKVersion`, meaning the global state cannot be modified if a singleton exists from a different `D3D12Core.dll`, however this method bypasses the developer mode and relative path requirements. The global SDK version also cannot be downgraded via this method. Failures here will return `D3D12_ERROR_INVALID_REDIST`. If any change occurs in global state, any existing singleton D3D12 device will become removed.|
|`SetFlags`|Sets the flags that will affect the behavior of a future call to `CreateDevice`.|
|`GetFlags`|Gets the currently set flags.|
|`GetConfigurationInterface`|Retrieves an interface with further configuration properties - equivalent to the `D3D12GetInterface` export for one of (at the time of writing) `CLSID_D3D12Debug`, `CLSID_D3D12Tools`, or `CLSID_D3D12DeviceRemovedExtendedData`|
|`EnableExperimentalFeatures`|Stores the requested experimental feature data to be applied to the next `CreateDevice` call - equivalent to the `D3D12EnableExperimentalFeatures` export, but applying to this object rather than global.|
|`CreateDevice`|Creates a new, independent device, unless the driver does not support independent devices, in which case singleton interactions are defined by the `D3D12_DEVICE_FACTORY_FLAGS` flags set on this object.|

**`ID3D12SDKConfiguration1`**

Can be queried from an SDK configuration object, retrieved from `D3D12GetInterface` with the `CLSID_D3D12SDKConfiguration`. Allows apps to access `ID3D12DeviceFactory` objects from D3D12Core modules that are not globally-configured (via exports from the .exe file or from `ID3D12SDKConfiguration::SetSDKVersion`). This allows creating an independent device from an independent D3D12Core.

|API|Description|
|---|-----------|
|`CreateDeviceFactory`|Equivalent to calling `D3D12GetInterface` with the `CLSID_D3D12DeviceFactory` CLSID, with one major difference - it allows loading a side-by-side D3D12Core to provide this device factory. This API does not require developer mode.|
|`FreeUnusedSDKs`|Similar to `CoFreeUnusedLibraries` for traditional COM. Since the code which marks a D3D12Core module as "unused" is running inside that module, it is not possible for that code to unload itself without a race. For example, `ID3D12SDKConfiguration1::CreateDeviceFactory` may load a D3D12Core module and retrieve an interface from it. If `CreateDevice` is never called on that factory, then when the factory object is `Release`d, the D3D12Core module becomes unused. But since the code for `Release` is on the stack when the module becomes unused, it cannot be unloaded here, and instead sticks around until `FreeUnusedSDKs` is invoked to unload the module. Similarly for independent devices created from this module, `Release` cannot unload the module.|

**`ID3D12DeviceConfiguration`**

Can be queried from a created `ID3D12Device` or from an `ID3D12DeviceFactory` object. Enables apps to call functions that are exports from D3D12, and would normally redirect to a globally-configured D3D12Core.dll. Instead, these functions redirect to the created device's D3D12Core.dll, which may be different from the global one. This also allows apps to reflect the properties from a factory for an about-to-be-created device, or from an already-created device.

#### Device compatibility

The `D3D12_DEVICE_FACTORY_FLAGS` flags mention "compatibility" between an existing singleton device and a new device configuration. A device is said to be compatible if:
* The existing device's Agility SDK version is >= the new device's requested version.
* The existing device's debug layer state exactly matches the new device's requested debug layer state, including GPU-based validation settings.
* The existing device's shader tracing enablement exactly matches the new device's requested shader tracing state.
* The existing device's DRED enablement is at least at a level requested by the new device.
* The existing device enables all experimental features requested by the new device.

To ensure maximum likelihood of compatibility with an existing device, use `InitializeFromGlobalState` before applying incremental changes.
