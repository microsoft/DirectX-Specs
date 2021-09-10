
# Table Of Contents

- [Table Of Contents](#table-of-contents)
- [D3D12 Undocked Redistributable](#d3d12-undocked-redistributable)
- [Rationale](#rationale)
  - [Goals](#goals)
    - [D3D12 Remains an Inbox OS Component](#d3d12-remains-an-inbox-os-component)
    - [Speed Feature Adoption](#speed-feature-adoption)
    - [Improve Quality and Reduce Risk](#improve-quality-and-reduce-risk)
    - [Improve Responsiveness](#improve-responsiveness)
    - [Support Redist in 19H2+](#support-redist-in-iron)
- [Redist Method](#redist-method)
  - [The Path Not Taken](#the-path-not-taken)
    - [Local Installer](#local-installer)
    - [Centrally Managed Update Service](#centrally-managed-update-service)
    - [Driver Upgrade](#driver-upgrade)
- [Versioning](#versioning)
  - [Using the Redist](#using-the-redist)
  - [Not Targeting a Redist](#not-targeting-a-redist)
  - [Recommended Version and Change lists](#recommended-version-and-change-lists)
  - [API Compatibility](#api-compatibility)
- [Enabling a Redist](#enabling-a-redist)
  - [Application and Games](#application-and-games)
  - [Tools and Test Harnesses](#tools-and-test-harnesses)
    - [Method: D3D12GetInterface](#method-d3d12getinterface)
    - [Interface: ID3D12SDKConfiguration](#interface-id3d12sdkconfiguration)
      - [Method: ID3D12SDKConfiguration::SetSDKVersion](#method-id3d12sdkconfigurationsetsdkversion)
- [Supported Windows Versions](#supported-windows-versions)
- [Supported Architectures](#supported-architectures)
- [Packaging](#packaging)
  - [Headers](#headers)
  - [D3DConfig](#d3dconfig)
  - [D3D12 Debug Layer](#d3d12-debug-layer)
  - [D3D12 Driver Verifier](#d3d12-driver-verifier)
- [Dependencies](#dependencies)
  - [Kernel Thunks](#kernel-thunks)
  - [DXGI](#dxgi)
  - [HLSL Compiler](#hlsl-compiler)
  - [Shader Cache](#shader-cache)
  - [DXBC to DIXL Converter](#dxbc-to-dixl-converter)
  - [D3D12 Application Local vs. Inbox OS Compatibility](#d3d12-application-local-vs-inbox-os-compatibility)
  - [Compatibility With Multiple Versions of D3D12.dll](#compatibility-with-multiple-versions-of-d3d12dll)
  - [Sharing Contract For Driver Private Data](#sharing-contract-for-driver-private-data)
- [Undocking and Branching](#undocking-and-branching)
  - [Branching](#branching)
  - [Supported Operating Systems](#supported-operating-systems)
- [Servicing and Bug Fixes](#servicing-and-bug-fixes)
  - [Windows Update](#windows-update)
  - [Application Upgrades D3D12](#application-upgrades-d3d12)

# D3D12 Undocked Redistributable

D3D12 is moving to a redistributable model to allow applications to upgrade D3D12 to access new graphics features without upgrading the OS.  The D3D team will publish a new d3d12core.dll that developers can install in the application folder to access these features on older OS with an updated driver (and hardware if required).

Some changes to the base OS are required to support the redist, which D3D team has taken downlevel to 19H2. See [Supported Windows Versions](#supported-windows-versions)

A redist upgrade only affects the applications that opt in and ship the new dll.  With this scoping, D3D team is able to ship bug fixes via redist as well.

Note that the public-facing name for the D3D12 redist and associated components is the **DirectX 12 Agility SDK**.

# Rationale

D3D12 has traditionally shipped new feature updates with new versions of Windows.  These features require new drivers and often new hardware as well.   While D3D team has been successful under this model, it has some issues.  

D3D12 features are gated on an OS upgrade.  It can take 1-2 years to get through OS upgrade sediment to make our features available to enough users for 3rd party game and application developers to target.  IHVs are successful at delivering new drivers to customers on older OS and customers can buy new hardware.  The D3D12 runtime shouldn't be holding these features back potentially depressing new hardware and OEM sales for new gaming scenarios.  D3D12 should not be the blocker accessing new graphics features for Independent Software Vendors (ISVs).

Additionally, flighting and selfhost doesn't really work for new D3D12 features, only regression testing existing features.  Our features and tests are completed during development for Windows, but new drivers that target those changes are externally developed and often are not complete until we are well into stabilization periods.  We're fairly successful at doing as much work design work as we can up front to unblock IHVs and IHVs have operated in good faith, but a serial dependency exists.  Until the driver exists, the tests can't actually run and selfhost.  This almost guarantees bugs are found late.  Slipping a feature extends our ability to reach customers out another year.  Even when OS and driver support line up, usage in flighting rings is non-existent.  Again ISVs don't bother to target our features until they are available on the end points they are targeting in market. A redistributable D3D12 enables the D3D team to ship features when drivers are ready and provide a way to have more targeted usage to enable telemetry and selfhost feedback by increasing our reach.

To resolve these issues, D3D12 is moving to a redistributable model to allow applications to upgrade D3D12 and access new features.

## Goals

### D3D12 Remains an Inbox OS Component

D3D12 remains an inbox OS component.  D3D12 redist is a way to upgrade D3D12 to include new features.  Any new features available in the redist are always in the next version of the OS.

### Speed Feature Adoption

Speed adoption of new D3D features by making a large install base instantly accessible to developers, without having to wait on the OS upgrade cycle.

- If a feature works on existing hardware, it should have broad support the moment we release it.  
- If a feature requires new hardware, accessible install base should be gated only on hardware sales.

### Improve Quality and Reduce Risk

Address the shortcomings of current flighting and release strategy.

- Enable developers to opt into new D3D12 features without impacting other processes.  These developers are seeking to use the new feature by definition and can give us data before the feature is integrated into the next release cycle.
- Do not explode test matrices.  D3D12 remains on a linear timeline.  New Features are integrated back into the next OS release and subsequent redist.  
- When OS version is newer than redist, redirect to OS version.
- Avoid significant release management overhead.  Rely on customer to opt into newer versions.
- Servicing must still be possible for all redist versions.

### Improve Responsiveness

- Redist enables us to release a bug fix in a new release quickly scoped to the customer that needs it.
- Unblocking affected customers with a new redist reduces need to make late OS fixes that impact everyone.

### Support Redist in 19H2+

This feature requires changes in inbox components to support. These changes are in Iron and are being serviced to earlier OSes (19H2 and more recent) in the 1C and 2B servicing patches.

# Redist Method

New versions of D3D12 are distributed as a dll that applications can include in their install as an application local version.  This version upgrades the process to a later version of the D3D12 SDK without impacting other applications.

This redistribution method scopes the changes to only the applications that opt in, reducing risk.  This also greatly improves our ability to flight features as they are installed by ISVs seeking them and actively planning to use them.  We have the ability to have a tight loop fixing any issues.  

Release management for redistributed D3D12 is also simple under this model.  The only time D3D12 updates are pushed to all apps is with an OS upgrade, as they are today.  We can maintain the exact same level of app compatibility and self host testing for existing features for the version of D3D12 that ships with OS builds as before.  Redistributable release timeline may not see the benefits of Windows wide selfhost, but this is okay because it is only used in applications that are actively under development.  Should an issue arise, we can issue another redist to those same apps.

This does mean a D3D12 redist can be installed per application, but this is also small relative to the footprint of games.

## The Path Not Taken

This section documents the more promising alternative redistribution methods to application local that we considered, but are not using.

### Local Installer

An installer is provided to developers to install the required version of D3D12 during installation of the application or game.  The installer checks if the the required version is installed on the system and installs it if not.

Only a single copy of a given redist version is installed.  Each installed version is registered and can be enumerated for scenarios like servicing.  Servicing can upgrade the installed redist dlls directly.

This method would add enumeration of installed versions, but adds a significant cost in maintaining multiple installers for various architectures.  

### Centrally Managed Update Service

This method would globally upgrade D3D12 for all clients through a mechanism such as the store.  

This method adds significant release management overhead.  We get a lot of value for regression testing by being part of the OS, from app compatibility testing, selfhost, etc.  Replicating that to our own release schedule and mechanism adds significant overhead.

Additionally, this method doesn't solve the goal of targeting selfhosting of features before they go broad.

### Driver Upgrade

This method would have drivers ship the D3D12.dll binary with the driver distribution.  

However, this method lacks scoping to individual applications and also makes it more difficult to ship updates that don't need a driver update.  

# Versioning

D3D12 re-introduces the idea of an SDK version.  Each release is assigned an SDK version number.  The version released with an OS is also published as a redist and is also assigned an SDK Version number.

![Version timeline](Images\D3D12Redistributable\ReleaseTimeline.png)

## Using the Redist

Applications targeting a redist ship the app local copy of D3D12core.dll and register the SDK version.  

If the requested redist version is the same or older than the OS inbox D3D12, the application uses the inbox version.

![SDK Version Selection](Images\D3D12Redistributable\SDKVersionSelection.png)

This version policy:  

- Maintains compatibility with OS entry points like Kernel Thunks.
- Ages out old versions of redists to help close the support window on older redists.  

## Not Targeting a Redist

Applications that don't target a redist continue to get the inbox OS version as before.

## Recommended Version and Change lists

Applications should only target a redist when they need a version that is not available on the OS they are targeting.  This causes applications to more quickly gravitate to a version of D3D12 that ships with an OS.

To support this, we must provide accurate change notes for both features and bug fixes in each release to developers.

## API Compatibility

In general, D3D does not deprecate APIs in order to maintain compatibility. Whenever an improvement is made in an existing area, new API is added and the old is kept working.  

This redist plan does not add any additional opportunities to deprecate APIs.  Redists are treated like OS releases were in the previous model.  Once an API ships, compatibility is maintained for that API going forward.  An attempt to deprecate the API with the new redist model is the same undertaking it is to do so with OS releases now.  

In other words, a redistributable release is not used to experiment with an API design that will later be removed etc.

# Enabling a Redist

## Application and Games

Applications and games set redist parameters by exporting constant data via well known symbols.

- D3D12SDKVersion - Declares the SDK version of the D3D12 redistributable that the Application is targeting.  
- D3D12SDKPath - The path to D3D12 binaries relative to the application exe using D3D12.

For example, the application exe can export these constants via a .def file:

``` 
EXPORTS  
    D3D12SDKVersion DATA PRIVATE 
    D3D12SDKPath DATA PRIVATE
```

And declare the constants in code:

```c++
extern "C" extern const uint32_t D3D12SDKVersion = 4;
extern "C" extern LPCSTR D3D12SDKPath = u8".\\D3D12\\";
```

Alternatively, a developer who does not want to use a .def file, can export these constants as follows:
```c++
extern "C" { _declspec(dllexport) extern const UINT D3D12SDKVersion = 4;}
extern "C" { _declspec(dllexport) extern const char* D3D12SDKPath = u8".\\D3D12\\"; }
```

In either case, this declares that the version of the D3D12SDKVersion included with the application is 4.  

D3D12SDKPath is a UTF-8 string that declares that D3D12Core.dll, D3D12SDKLayers.dll, and other D3D12 redist binaries are located in the subfolder D3D12 relative to the exe, so:

Path to exe:
c:\Game\game.exe

Path to D3D12 redist:
c:\Game\D3D12\D3D12Core.dll

Configure the application installer to install the D3D12Core.dll in the folder specified in D3D12SDKPath.  

 That's it.  Applications call D3D12CreateDevice on the OS inbox D3D12.dll as they always have.  This runtime checks if the requested version is the same or equal to the inbox version.  If it is, the inbox version of D3D12.dll, D3D12SDKLayers.dll, etc. are used.

If the requested version is newer, the runtime will load D3D12Core.dll from D3D12SDKPath, ensure that it matches the declared version, and use it instead.

The interfaces and feature checks of the requested SDK version are now available.

## Tools and Test Harnesses

Tools that playback API capture like PIX and test harnesses like the HLK require modification to support the redist.  These tools can choose to ship with the latest redist.  D3D's [API Compatibility](#api-compatibility) through updates should mean that an API capture tool can capture on an older version of the D3D12 SDK, and play it back on the newer version.
However, some scenarios require more flexibility in selecting the SDK version. To accommodate this, D3D12 supports an additional method to select the SDK version at runtime when the system is in developer mode.  

### Method: D3D12GetInterface

```c++
HRESULT D3D12GetInterface
(
    REFCLSID rclsid,
    REFIID riid,
    void   **ppvDebug
);
```

**Parameters**

*rclsid*

The CLSID associated with the data and code that will be used to create the object.

Specify `CLSID_D3D12SDKConfiguration` to retrieve the `ID3D12SDKConfiguration` interface.

*riid*

The globally unique identifier (GUID) for the sdk configuration interface. The REFIID, or GUID, of the interface can be obtained by using the `__uuidof()` macro. For example, `__uuidof(ID3D12SDKConfiguration)` will get the GUID of the debug interface.

*ppvDebug*

The outparameter that contains the requested interface on return, for example, the SDK configuration interface, as a pointer to pointer to void. See ID3D12SDKConfiguration.

**Return Value**

This method returns one of the Direct3D 12 [Return Codes](https://docs.microsoft.com/windows/desktop/direct3d12/d3d12-graphics-reference-returnvalues).

### Interface: ID3D12SDKConfiguration

```c++
interface ID3D12SDKConfiguration
    : IUnknown
```

This interface can be retrieved by calling the `D3D12GetInterface` export on D3D12.dll with the `CLSID_D3D12SDKConfiguration` CLSID.

#### Method: ID3D12SDKConfiguration::SetSDKVersion
```c++
HRESULT SetSDKVersion(
    UINT SDKVersion,
    _In_z_ LPCWSTR SDKPath
    );
```

**Parameters**

*SDKVersion*

*SDKPath*
A NULL terminated string that provides the relative path to d3d12core.dll at the specified SDKVersion.  The path is relative to the process exe of the caller.  If D3D12Core.dll is not found or is not of the specified SDKVersion, D3D12 device creation fails.

**Remarks**
This method can only be used in Windows Developer Mode.

To set the SDK version  using this API, it must be called before the D3D12 device is created. Calling this API after creating the D3D12 device will cause the D3D12 runtime to remove the device.  
Note that if the D3D12.dll installed with the OS is newer than the SDK version specified, the OS version is used instead.

The version of a particular D3D12Core.dll can be retrieved from the exported symbol `D3D12SDKVersion`, which is a variable of type UINT, just like the variables exported from applications to enable use of the Agility SDK.

# Supported Windows Versions

Some OS changes are required to support the D3D12 downloadable redist.  The D3D team is making those changes in the Iron release, but servicing these changes to earlier OSes.

Support for the redist is being serviced to every retail build of Windows Version 1909 (19H2) and more recent. Servicing patches with support for the redist has started going out on 2/9. 

More info on the specific KB patches that bring support for the redist can be found [here](https://support.microsoft.com/en-us/topic/february-9-2021-kb4601319-os-builds-19041-804-and-19042-804-87fc8417-4a81-0ebb-5baa-40cfab2fbfde) and [here](https://support.microsoft.com/en-us/topic/february-9-2021-kb4601315-os-build-18363-1377-bdd71d2f-6729-e22a-3150-64324e4ab954)


# Supported Architectures

Initially we'll support x86, x64, and arm64 architectures.  
Redist releases won't include technologies like chpe, but this will be reconsidered based on feedback.

# Packaging

[NuGet](https://docs.microsoft.com/en-us/nuget/what-is-nuget) is the packaging mechanism for D3D12 redist. The following will be published in each SDK:
- D3D12Core.dll: (Contains components needed on end user machines for applications shipping with redist)
- D3D12SDKLayers.dll (Debug Layer)
- d3dconfig.exe
- D3D12.h
- D3D12SDKLayers.h
- D3D12Video.h 
- D3D12Shader.h
- D3D12Common.h
- DXGIFormat.h

## Headers

D3D12 team will publish API headers for the runtime (d3d12.h, d3d12video.h) and Debug Layers (d3d12sdklayers.h) with the Debug Layer release which targets ISVs.

DDI Headers are packaged with Driver verifier which targets driver developers.

It is not necessary to redistribute import libs.  All exports called by applications are exported on the D3D12.dll that is inbox in with the OS.  The import lib for this is already published with the SDK.

## D3D12 Debug Layer

The [D3D12 Debug Layer](https://docs.microsoft.com/en-us/windows/win32/direct3d12/understanding-the-d3d12-debug-layer) adds important debug and diagnostic features for application developers during application development.  It should not be installed on end user machines, but instead on developer machines.  Therefore, the D3D12 Debug Layer will be provided via a separate redistributable and released in parallel with the runtime.  The Debug layer will be assigned a matching SDK version number.

The debug layers and runtime have tight integrations between them.  Developers must continue to ensure that the version of the debug layers and the version of the D3D12 runtime match.  

Also, the SDK version that the application is requesting may be older than the host OS.  In this case, the app would be redirected to the OS version.  This may mean using a version of the runtime that doesn't match their redist Debug Layer, they may need the OS version.  To avoid developer confusion, we will require that the application developer always install the OS feature on Demand for the Debug layer (Graphics Tools) as well as the redist version before Debug Layers will work.

## D3DConfig 

The D3DConfig tool provides software developers with console control over global D3D diagnostic and debugging settings.  D3DConfig is a fully-compatible replacement for the DX Control Panel (DXCPL) utility.

## D3D12 Driver Verifier

The driver verifier is another layer that can be used to provide driver validation during driver development.  This component is also not used at runtime.  

D3D12 Driver verifier is also made redistributable for driver developers to use along with the DDI.

# Dependencies

## Kernel Thunks

We support Kernel to continue its policy of making compatible non-breaking changes to the D3D thunk layer.  However, with an application local installation and a policy that when the OS contains a newer version it overrides the application local version, we can continue to support contract changes in the same way that we do before redist.  Kernel team would need to make the corresponding changes to runtime.

To ensure this continues to work, the runtime SDK version *must* be rev'd anytime we branch.  That way a newly flighted OS will generally be considered newer than any released distribution.

One thing for our kernel team to be aware of though is that servicing a contract breaking change may mean servicing multiple versions of D3D12, depending on how many redistributables have shipped since the OS in question has shipped.  See [Servicing](#servicing-and-bug-fixes).

## DXGI

DXGI has already moved to stable versioned interfaces due to an effort to support PIX.  The redistributable D3D12 effort leverages this existing support.  D3D12 will detect if new DXGI services are available via QueryInterface for the new COM interface that exposes this functionality and provide fallback mechanisms if not.

## HLSL Compiler

New D3D12 features may have dependencies on new versions of the HLSL compiler.  The HLSL compiler is already undocked and available outside of OS releases, so D3D team needs to coordinate releases and point to the correct versions for new features

## Shader Cache

This component is expected to be stable and can be left as an OS only component.  This can be revisited when needed.

## DXBC to DIXL Converter

Upconverts legacy DXBC shaders to DIXL shaders.  New features appear natively in DXIL, so this component does not require redistribution.

## D3D12 Application Local vs. Inbox OS Compatibility

Application local version of D3D12 allows multiple versions of D3D12 to exist on the system at once.  All components within a given process will be on the same version of D3D12, but separate processes are allowed to be on different versions of D3D12.

## Compatibility With Multiple Versions of D3D12.dll

The D3D12 device is implemented and documented to be a Singleton per adapter for a given process.  Moving to an application local strategy maintains this to meet existing developer expectations.  D3D12 accomplishes this by upgrading all components in the process to the redistributable version selected by the process.

Applications are required to declare the redist version by exporting data, see [Enabling a Redist](#enabling-a-redist).  This makes version selection explicitly process-wide and ensures the version is selected before any components initialize themselves.  The applications version selection is respected when D3D12CreateDevice is called and creates the singleton device instance for a given adapter.

## Sharing Contract For Driver Private Data

Out of process sharing of resources, sync objects, protected resource sessions involves sharing private d3d runtime data between processes.  Since processes may be running different versions of D3D, this private data schema must be revised to support versioning and backward compatibility with all supported releases of the runtime.

A way of validating non-backward compatible sharing must be added to the runtime.

# Undocking and Branching

D3D12, D3D12 SDK Layers, and D3D12 Tests are undocked from the OS repository to support the unlikely need to service.

## Branching

The D3D team can ship far more often than today, but this will always be from the mainline of a single development repository, where risky work is kept behind an experimental flag until it is ready to ship.

The D3D team will not release different combinations of features to different customers at the same time, because this is too complex to reason about and validate.  Whatever the D3D team ships out of band via the redist will automatically flow into the next Windows 10 release.

The exception is the unlikely event of servicing. Should that occur, Windows Update may potentially be used to patch a given SDK version with a cherry-picked fix.

## Supported Operating Systems

A D3D12 SDK version declares the oldest version of Windows that it is supported with.  This minimum supported version is informed via telemetry data on where users are, customer demand, and engineering costs.  The minimum version is enforced in device creation code with an OS version check.

Should the minimum OS version be raised above 19H2/1909, this will be advertised via our redistribution channel, the DirectX Devblogs

# Servicing and Bug Fixes

Windows Update remains the means by which we can push an update to users outside of an OS upgrade.  Servicing fixes for D3D12 has been extremely rare and that is expected to continue with a redistributable D3D12.  

However, a redistributable D3D12 opens an additional avenue to provide bug fixes out of band of OS upgrades and servicing.  The team can make a bug fix available as a new version of the redistributable D3D12 package to developers and developers can update individual affected applications.  

## Windows Update

Windows Update is used as the servicing mechanism for both the inbox D3D12 and redistributable versions of D3D12.  

A service event requires servicing the D3D12 loader component and then inbox version of D3D12.  All applications using an SDK version older than the OS version of D3D12 are already upgraded to the OS version of the dll.  This means that Windows Update also must update all versions of the redistributable with an SDK version newer than the OS.

This is accomplished by updating the loader policy to redirect to a patched SDK dll that is installed globally in System32.  To provide the patched SDK dll, the team has a spectrum of options:

- Install the latest redistributable on the system, and redirect everyone using an SDK newer than the OS to it.
- Patch each SDK version dll individually.  This requires that a version of the dll have a patched copy installed.  The loader redirects from the app local version to the patch version.  

A likely compromise of the two is to install the latest SDK version that shipped with an OS and then patch anything newer than that individually. Using the OS version to upgrade most users except the bleeding edge has the benefit of all the app compat, flighting, and other testing that goes into shipping an OS version.

**Example**

Pretend that the first D3D12 SDK version is 4 it is the version that ships on the Iron windows release.  We could have a redistributable story that looks like the table below.  6 and 9 are the SDK versions that ship on Cobalt and Nickel while 5, 7, 8, and 10 are all versions that ship only via the redistributable package.  

| OS | D3D12 SDK Version |
|------|---|---|---|---|
| Fe | 4|
| * |  5 |
| Co | 6 |
| * | 7 |
| * | 8 |
| Ni| 9 |
| * | 10 |

Now pretend that a service event happens just after we ship version 10.  In order to patch the Cobalt OS, we have to consider that all of versions 4-10 are on the OS installed by various games.  

We start by patching version 6, which is the inbox OS version.  This automatically handles version 4-6 because those versions have already been upgraded to version 6 by the OS upgrade policy.

To patch 7, 8, and 9 we decide to install a patched version 9 from Nickel on the system and upgrade 7 and 8 to use that version.  

Then, install a patched version 10 and redirect from the application local version to the patched version.

In total, we patched the loader component, the OS version, and installed two additional side-by-side versions of D3D12 on the system to fully service the system.

## Application Upgrades D3D12

When a bug is blocking a customer, but does not meet the criteria for broad servicing, the D3D team can make bug fixes available as part of a new redistributable package.  Impacted developers can then choose to upgrade individual affected applications. Bug fixes made available via this channel are optional to the developer and these updates still won't be pushed automatically to users outside of servicing or an OS upgrade by Microsoft.  The D3D team is able to quickly react to issues blocking premier D3D12 applications across all supported OS more quickly without risking unaffected applications and the OS itself.
