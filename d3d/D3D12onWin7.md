<h1>Porting D3D12 games to Windows 7 – Development Guidance</h1>

This is a guidance document to help game developers port their existing D3D12 games from Windows 10 to Windows 7. The current draft is based on the latest D3D12 runtime bits (“Microsoft.Direct3D.D3D12On7.1.0.7.nupkg”). Please read through this guidance document before your planning.

---

<h1>Contents</h1>

- [Overview](#overview)
- [Before You Start](#before-you-start)
  - [Have your D3D12 game up and running on Windows 10](#have-your-d3d12-game-up-and-running-on-windows-10)
  - [Collect files from Microsoft](#collect-files-from-microsoft)
  - [Collect drivers from GPU vendors](#collect-drivers-from-gpu-vendors)
  - [Set up dev/test machines](#set-up-devtest-machines)
- [Get D3D12 Games Up and Running on Windows 7](#get-d3d12-games-up-and-running-on-windows-7)
  - [Set up your project](#set-up-your-project)
  - [Load DLLs properly](#load-dlls-properly)
  - [Fork code paths for Windows 7](#fork-code-paths-for-windows-7)
  - [Add new Present code path for Windows 7](#add-new-present-code-path-for-windows-7)
  - [Remove unsupported fence usage patterns](#remove-unsupported-fence-usage-patterns)
  - [Update residency management](#update-residency-management)
  - [Disable features not supported on Windows 7](#disable-features-not-supported-on-windows-7)
  - [Run Windows 10 SDK Layer in Windows 7 emulation mode](#run-windows-10-sdk-layer-in-windows-7-emulation-mode)
  - [Add support to D3D11On12](#add-support-to-d3d11on12)
  - [Other things to watch out](#other-things-to-watch-out)
- [Optimize D3D12 Games Performance on Windows 7](#optimize-d3d12-games-performance-on-windows-7)
  - [Use `ID3D12PipelineLibrary` to cache PSO](#use-id3d12pipelinelibrary-to-cache-pso)
  - [Reduce number of resident resources](#reduce-number-of-resident-resources)
- [Release D3D12 Games on Windows 7](#release-d3d12-games-on-windows-7)
  - [Package and release Windows 7 version of D3D12 binaries as part of your game](#package-and-release-windows-7-version-of-d3d12-binaries-as-part-of-your-game)
  - [D3D12 games must continue to run after gamers upgrade from Windows 7 to Windows 10](#d3d12-games-must-continue-to-run-after-gamers-upgrade-from-windows-7-to-windows-10)
- [FAQ](#faq)
  - [Q: Can I build one single executable that works for both Windows 10 and Windows 7? And how?](#q-can-i-build-one-single-executable-that-works-for-both-windows-10-and-windows-7-and-how)
  - [Q: Do you support all D3D12 features on Windows 7?](#q-do-you-support-all-d3d12-features-on-windows-7)
  - [Q: What limitations should I expect when porting D3D12 games to Windows 7?](#q-what-limitations-should-i-expect-when-porting-d3d12-games-to-windows-7)
  - [Q: How about HDR support?](#q-how-about-hdr-support)
  - [Q: Do I need to update SDK to build D3D12 games for Windows 7?](#q-do-i-need-to-update-sdk-to-build-d3d12-games-for-windows-7)
  - [Q: How does D3D12 on Windows 7 handle hardware with Feature Level 11_1?](#q-how-does-d3d12-on-windows-7-handle-hardware-with-feature-level-11_1)
  - [Q: Can I execute the Windows 7 version of D3D12.DLL on a Windows 10 machine?](#q-can-i-execute-the-windows-7-version-of-d3d12dll-on-a-windows-10-machine)
  - [Q: Who should I contact for any questions related to D3D12 on Windows 7?](#q-who-should-i-contact-for-any-questions-related-to-d3d12-on-windows-7)

---

# Overview

If game developers have D3D12 games already running on Windows 10, they can port those games to Windows 7 with expectation of small code churn, mostly feature parity, reasonable performance, and a short list of limitations.

# Before You Start

## Have your D3D12 game up and running on Windows 10

… with SDK Layer clean of errors or warnings.

## Collect files from Microsoft

Most of the files below will be included and distributed in a single nupkg.

* (required) D3D12Downlevel.h – header file to expose D3D12 on Windows 7. The interfaces will only be supported by the supplied d3d12.dll, not the one built into Windows 10, so you can use a QueryInterface for those as an indication of which system you are running on.
* (required) d3d12.dll
* (required) dxilconv7.dll
* (required only when using D3D11on12) D3D11On12On7.h and d3d11on12.dll
* (required for game releases using D3D12 on Windows 7) LICENSE.txt
* (optional) this dev guidance doc and other accompanying documents.

## Collect drivers from GPU vendors

Download recent Windows 7 drivers from GPU vendors.

## Set up dev/test machines

Dev machines: You can continue to develop and build your Windows 7 SKU on your Windows 10 dev machine using matching Windows 10 SDK. Optionally, you can set up a dev machine to enable the Windows 7 emulation mode using the Windows 10 debug layer (see “Run Windows 10 SDK Layer in Windows 7 emulation mode” below);

Test machines: Set up a PC with Windows 7 SP1 (Windows version number 7601) for local testing.

# Get D3D12 Games Up and Running on Windows 7

We only ported the D3D12 runtime to Windows 7. Therefore, the difference of Graphics Kernel found on Windows 7 still requires some game code changes, mainly around the presentation code path, use of monitored fences, and memory residency management (all of which will be detailed below). Early adopters reported from a few days to two weeks of work to have their D3D12 games up and running on Windows 7, though the actual engineering work required for your game may vary.

## Set up your project

You can continue to use the Windows 10 dev machines to build the Windows 7 EXE.

1. Copy header files to the path alongside existing D3D headers;
2. Copy DLL files in the following recommended locations:

```C++
…\MyGame.exe
…\dxilconv7.dll
…\12on7\d3d12.dll
…\12on7\d3d11on12.dll
```

3. Regenerated VS project files so it picks up the new header;
4. Install Windows 7 driver you receive from GPU vendors.

## Load DLLs properly

To reduce confusion about various DLLs that might reside on a gamer’s machine, developers should load D3D12.dll in the following way.

* Load D3D12.dll from the sub folder alongside game EXE
  * If it succeeds, the app is running on Windows 7 with D3D12 downlevel;
  * If it fails, load D3D12.dll from system folder;
    * If it succeeds, the app is running on Windows 10;
    * If it fails again, no D3D12 support is available (either running on Windows 7 with D3D12.DLL removed or running on other Windows system with no D3D12 support).

Example code:

```C++
HMODULE hD3D12 = LoadLibraryA("12on7\\d3d12.dll");
if (!hD3D12)
{
    hD3D12 = LoadLibraryA("d3d12.dll");
}
```

Once D3D12.dll is loaded, you can either use `GetProcAddress` or `DelayLoad` linking to retrieve functions from the DLL. Note that you cannot use static linking against d3d12.lib. Apps do not need to explicitly load dxilconv7.dll, and should only load d3d11on12.dll when running on Windows 7 (loading 12on7\\d3d12.dll succeeded).

## Fork code paths for Windows 7

We recommend runtime checking in your code as follows.

```C++
#include "d3d12downlevel.h"

ID3D12Device* d3d12Device;
ID3D12DeviceDownlevel* d3d12DeviceDownlevel;

if (SUCCEEDED(
    d3d12Device->QueryInterface(
        IID_PPV_ARGS(&d3d12DeviceDownlevel)
    )))
{
    // For Windows 7
    // ...
}
else
{
    // For Windows 10
    // ...
}
```

## Add new Present code path for Windows 7

D3D12 on Windows 7 requires different Present APIs. Specifically, attempting to create a DXGI swapchain on a D3D12 device or queue will fail on Windows 7, because DXGI is not updated as part of this package.

As an alternative, you should use `ID3D12CommandQueueDownlevel::Present`. Note that this API only supports windowed blt presents, not fullscreen exclusive or any other mode. The application is responsible for window management, this API will not send messages nor manipulate window properties in any way. The resource that the application provides should not be multisampled, must be committed, and must be in a “displayable” format, one of the following:

```C++
• DXGI_FORMAT_R16G16B16A16_FLOAT
• DXGI_FORMAT_R10G10B10A2_UNORM
• DXGI_FORMAT_R8G8B8A8_UNORM
• DXGI_FORMAT_R8G8B8A8_UNORM_SRGB
• DXGI_FORMAT_B8G8R8X8_UNORM
• DXGI_FORMAT_R10G10B10_XR_BIAS_A2_UNORM
• DXGI_FORMAT_B8G8R8A8_UNORM
• DXGI_FORMAT_B8G8R8A8_UNORM_SRGB
```

## Remove unsupported fence usage patterns

The same D3D12 fence APIs behave mostly the same as on Windows 7, except no support for fence rewinding (signaling to a lower value, after a higher value signal has been queued) or out-of-order fence waits (waiting for a value whose signal has not yet been queued).

Please follow the instructions in “Run Windows 10 SDK Layer in Windows 7 emulation mode” to identify usage of unsupported fence usage patterns. Then you can refer to the updated public residency helper library ([d3dx12residency.h](https://github.com/microsoft/DirectX-Graphics-Samples/blob/master/Libraries/D3DX12Residency/d3dx12Residency.h)) and see how you can remove those patterns. This also helps for ongoing QA testing to catch issues specific to Windows 7.

## Update residency management

Since DXGI is not updated, `IDXGIAdapter3::QueryVideoMemoryInfo` is not available. Instead, the application should use `ID3D12DeviceDownlevel::QueryVideoMemoryInfo`. Also, be aware that the existing public residency helper library ([d3dx12residency.h](https://github.com/microsoft/DirectX-Graphics-Samples/blob/master/Libraries/D3DX12Residency/d3dx12Residency.h)) has been updated to use this new API and to remove monitored fence usages when running on Windows 7.

Additionally, while `ID3D12Device::Evict` and resource destruction are synchronous operations on Windows 10, meaning that all work referencing that resource must be complete, these are queued operations on Windows 7. The app may want to take advantage of this to reduce the number of resident resources at work submission time, to improve performance. See below.

## Disable features not supported on Windows 7

Please refer to “Q: Do you support all D3D12 features on Windows 7?” and “Q: What limitations should I expect when porting D3D12 games to Windows 7?” for unsupported features and add fallback solutions properly.

## Run Windows 10 SDK Layer in Windows 7 emulation mode

We added a new flag in Windows 10 SDK Layer to detect features not supported on Windows 7, primarily invalid fence usage patterns (e.g. fence rewinding, out-of-order fence waits).

To utilize this extra checking, developers need to set up a dev machine using [Windows 10 May 2019 Update](https://blogs.windows.com/windowsexperience/2019/05/21/how-to-get-the-windows-10-may-2019-update/#9XBlUqa2qd5juTJq.97) and the [matching SDK](https://developer.microsoft.com/en-US/windows/downloads/windows-10-sdk) (both with version number 18362), then call `ID3D12DebugDevice1::SetDebugParameter`, with type `D3D12_DEBUG_DEVICE_PARAMETER_FEATURE_FLAGS`, and value of `D3D12_DEBUG_FEATURE_EMULATE_WINDOWS7`, available in the new “d3d12sdklayers.h” file. Note that there are some "false positive" errors with this validation in the May 2019 build, which are fixed in more recent Windows Insider builds.

Note that, you can continue to use your current SDK on Windows 10 machines to build the executable as long as you include the extra header file while compiling and you copy the down-level DLLs next to the output executable for use when it is run on Windows 7.

## Add support to D3D11On12

If your game is using [D3D11On12](https://docs.microsoft.com/en-us/windows/win32/direct3d12/direct3d-11-on-12), you need the files of D3D11On12On7.h and d3d11on12.dll, plus all the following code changes in the Windows 7 code path of your game.

If you plan to ship your D3D12 games on Windows 7 via Steam but your game does not directly use D3D11On12, you should perform step 1 only, because the Steam client uses D3D11on12 to render its overlay, and requires the DLL to be loaded by the application in order to work.

1. `LoadLibrary` on d3d11on12.dll.
2. `GetProcAddress` for `GetD3D11On12On7Interface` and call it to get `ID3D11On12On7`.
3. Call `SetThreadDeviceCreationParams` with your device and queue that you will be using, just as you would call `D3D11On12CreateDevice` for Windows 10 usage.
4. Call `D3D11CreateDevice` with `D3D_DRIVER_TYPE_SOFTWARE`, and pass the `HMODULE` to d3d11on12.dll. This will return a D3D11On12 device that will submit work to your D3D12 device and queue you provided. If you did not call the `SetThreadDeviceCreationParams`, this will attempt to create a new D3D12 device on the default adapter. This object does not expose `ID3D11On12Device` like it does on Windows 10: that is implemented by d3d11.dll, which is not changing as part of D3D12 on Windows 7.
5. Call `ID3D11On12On7::GetThreadLastCreatedDevice()` to get an interface that you can use for interop.
6. Rather than calling `ID3D11On12Device::CreateWrappedResource`, you will call `ID3D11On12On7::SetThreadResourceCreationParams` with your D3D12 resource, and then call the appropriate D3D11 create method (i.e. `ID3D11Device::CreateTexture2D`). There will not be validation in place that your D3D11 and D3D12 creation parameters match, so make sure they do, or you will probably get some weird problems. Then you can call `ID3D11On12On7::GetThreadLastCreatedResource()` to get an interface you can use for interop on that resource.
7. Rather than calling `ID3D11On12Device::Acquire/ReleaseWrappedResources`, you will call `ID3D11On127Device::Acquire/ReleaseResource`. These have similar semantics, but it’s important to be aware that on Windows 10, the acquire/release APIs will prevent you from using the resource in D3D11 while it is released, but on Windows 7 the D3D11 runtime is oblivious to these “extensions” and will not help you out there.
8. The device/resource interfaces are not refcounted, and will be destroyed when the equivalent D3D11 object goes away, so make sure you do not try to use them outside of the lifespan of that object.

## Other things to watch out

If you are using middleware for rendering and find it broken on Windows 7, please let us know.

# Optimize D3D12 Games Performance on Windows 7

We encourage game developers to collect CPU performance data (using profiling tools) and GPU performance data (using timestamp) from D3D12 games running on Windows 7 and share those data with us and with GPU vendors. Doing so will allow all parties to better collaborate on identifying and addressing performance issues.

## Use `ID3D12PipelineLibrary` to cache PSO

The story around automatic caching of shaders and PSOs is different on Windows 7. Specifically, the only caches present are those implemented within the IHV driver, and those explicitly done by the app using `ID3D12PipelineLibrary`; there is no OS affordances for automatically caching. That means that if the driver does not have a cache present, or if the app provides DXBC shader code (i.e. shader model 5.1 or less, not 6) to the runtime, there will be overhead during PSO creation that can be removed by utilizing `ID3D12PipelineLibrary`. Therefore, we highly recommend utilizing the `ID3D12PipelineLibrary` APIs to make sure you are not getting unnecessary overhead.

## Reduce number of resident resources

If you find `ExecuteCommandLists` substantially more expensive compared to Windows 10, it has to do with how many resources you have resident at the time of the call: On WDDM1.x (as found on Windows 7), the driver is responsible for submitting allocation lists with ever command buffer submission, which the kernel will iterate over and make sure they are resident before allowing that work to execute. In D3D12 on Windows 7, the driver generates this allocation list based on the set of resources that are currently resident at the time of submission. The cost you are seeing is a per-allocation cost, which can be quite high; the size of the allocation is irrelevant here.

To get that cost down, you have several options to reduce the number of resident resources,

* Use placed resources instead of committed resources.
* Use fewer heaps: heaps are in the allocation list, but resources placed in those heaps are not.
* Call `Evict()` to remove resources from residency when they are no longer in used. Games on Windows 7 can also call `Evict()` or to destroy resources without waiting for resource usage to be finished (though the game does still need to wait before re-using those resources). Doing so will help cut down on how much is resident at any given time, because the WDDM1.x memory manager / scheduler on Windows 7 will ensure that those resources do not get evicted or destroyed before the last command buffer where they were referenced in the allocation list has finished. Note that, this is only an option on Windows 7; on Windows 10, game still need to wait for resource usage to be finished before calling `Evict()` or destroying those resources.

# Release D3D12 Games on Windows 7

## Package and release Windows 7 version of D3D12 binaries as part of your game

To release your D3D12 games on Windows 7, you must package and release the Windows 7 version of D3D12 binaries as part of your game – gamers will not receive those binaries from Microsoft. Any update of those binaries (e.g. with bug fixes) will also be released to gamers as part of your game update, not from Microsoft.

## D3D12 games must continue to run after gamers upgrade from Windows 7 to Windows 10

The app should not have two different EXEs *and* decide which EXE to install during installation time. The app must either (1) have one executable for both Windows 7 and Windows 10 (preferred), or (2) have two different EXEs but also have a single launcher to choose the right EXE at launch time.

See “Q: Can I build one single executable that works for both Windows 10 and Windows 7? And how?” below on how to build a single executable for both Windows 7 and Windows 10.

# FAQ

## Q: Can I build one single executable that works for both Windows 10 and Windows 7? And how?

A: Yes. Game developers need to pay attention to the following,

* “Load DLLs properly”;
* “Fork code paths for Windows 7” properly around API or behavioral differences listed above, such as Present, monitored fences, memory management;

When properly forked, the executable running on Windows 10 should not suffer from any feature limitation or performance loss.

## Q: Do you support all D3D12 features on Windows 7?

A: The current runtime supports D3D12 features as released in [Windows 10 October 2018 Update](https://blogs.windows.com/windowsexperience/2018/10/02/empowering-a-new-era-of-personal-productivity-with-new-surface-devices/#0486rqfRRghVeHuM.97) (notably, DX Raytracing but not DirectML) on Windows 7.

## Q: What limitations should I expect when porting D3D12 games to Windows 7?

To focus our support on key scenarios that most game developers care about, our current support for D3D12 on Windows 7 has the following limitations. Please review during your planning and have fallback plans in place.

* Windows 7 SP1 only
* X64 only
* No PIX or D3D12 debug layer on Windows 7
* No shared surfaces or cross-API interop
  * `D3D12_HEAP_FLAG_SHARED` and `CreateSharedHandle` do not work
* No SLI / LDA support
* No D3D12 video support
* No WARP support

## Q: How about HDR support?

A: HDR support is orthogonal to D3D12 and requires DXGI/Kernel/DWM functionalities on Windows 10 but not on Windows 7.

## Q: Do I need to update SDK to build D3D12 games for Windows 7?

A: You can continue to use your current SDK on Windows 10 machines to build the executable as long as you include the extra header file when compiling and you copy the down-level DLLs next to your Windows 7 executable (see “Set up your project” above).

If you want to run the SDK Layer to detect (1) unsupported flags like sharing, and (2) invalid fence usage patterns (e.g. fence rewinding, out-of-order fence waits), you will need to move up to the latest Windows 10 and matching SDK. See “Run Windows 10 SDK Layer in Windows 7 emulation mode” for details.

## Q: How does D3D12 on Windows 7 handle hardware with Feature Level 11_1?

A: D3D12 on Windows 7 will work the same way as on Windows 10: a simple query of feature level + tier is enough. D3D12 on Windows 7 does not introduce new tiers.

## Q: Can I execute the Windows 7 version of D3D12.DLL on a Windows 10 machine?

A: No. We explicitly fail the case where developers trying to load the Windows 7 version of D3D12.DLL on a Windows 10 machine. It will also fail even if one forces the game to run in Windows 7 Compatibility Mode.
The Windows 7 version of D3D12.DLL can only be loaded and executed on Windows 7 SP1.

## Q: Who should I contact for any questions related to D3D12 on Windows 7?

A: Please post your questions at [DirectX Discord](https://discord.gg/directx).
