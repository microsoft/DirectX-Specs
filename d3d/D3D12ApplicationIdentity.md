
# D3D12 Application Identity

- [D3D12 Application Identity](#d3d12-application-identity)
  - [Introduction](#introduction)
  - [Tooling: Interactions with Application Specific Driver State](#tooling-interactions-with-application-specific-driver-state)
  - [API](#api)
    - [GUID: CLSID\_D3D12ApplicationIdentity](#guid-clsid_d3d12applicationidentity)
    - [Union: D3D12\_VERSION\_NUMBER](#union-d3d12_version_number)
    - [Struct: D3D12\_APPLICATION\_DESC](#struct-d3d12_application_desc)
    - [Interface: ID3D12ApplicationIdentity](#interface-id3d12applicationidentity)
      - [Method: ID3D12ApplicationIdentity::SetApplicationIdentity](#method-id3d12applicationidentitysetapplicationidentity)
  - [D3D12StateObjectCompiler: Get/Set SODB Application Identity](#d3d12stateobjectcompiler-getset-sodb-application-identity)
    - [Write an Application Identity to an SODB](#write-an-application-identity-to-an-sodb)
    - [Read Application Identity from an SODB](#read-application-identity-from-an-sodb)
  - [Telemetry](#telemetry)

## Introduction

This spec defines an API that enables applications to declare their own application identity to D3D12 and the underlying graphics drivers in a standardized way.

Drivers today identify applications in order to optimize performance or to work around issues.  To determine identity, drivers have extension API that allow games to declare their identity.  In lieu of this, or when it is not sufficiently unique, drivers use heuristics to identify applications.  

One of the key areas for optimization and workarounds is compilation that is performed during Pipeline State Object and State Object creation.  Application Identity is used with Advanced Shader Delivery to identify applications when compiling shaders with the D3D12StateObjectCompiler where this identity information is needed so the offline compiler can produce the same results as the driver would during gameplay.  The existing struct D3D12_APPLICATION_DESC is used for this purpose.  However, this information must be gathered from the IHVs manually because the runtime doesn't have visibility into the extension or heuristics.

This feature adds an API to allow applications to set a default D3D12_APPLICATION_DESC and GUID to self identify before a D3D12 device is created. An option exists to set the default application identity for all devices, but it can also be set per device.

This gives applications a standardized way to set this information that must be done with extensions today, and gives us visibility into it to:

- Automatically record into State Object Databases during application capture.
- Understand when Application reported identity mismatches offline compilation.

This spec also details how the D3D12StateObjectCompiler.exe can be used to read or write the identity to an existing SODB.  Attaching Application Identity to State Object Databases is expected to be a requirement for direct submission to game stores.

Future: Since the extension or our new standardized API is only one of the inputs used to determine application identity by drivers, future updates will investigate DDI for the D3D12 runtime to discover identity ultimately determined by driver.  This allows us to understand when these mismatch to help drive down ambiguity in identity.  It also allows for a source of application identity relevant for offline shader compilation when the application doesn't declare it.

## Tooling: Interactions with Application Specific Driver State

Capture/replay tools like PIX already have an existing Application Specific Driver State feature which provides a mechanism to capture applied workaround or optimizations, store them,  and then tell the driver to set them at replay time.

[Application Specific Driver State](https://microsoft.github.io/DirectX-Specs/d3d/Application_Specific_Driver_State_v0_07.html)

This mechanism should already be capturing application identity or the settings that are derived from it, and therefore would consider the drivers self-identify extension and any app identity heuristics the driver is using.  Identity supplied from the application through ID3D12ApplicationIdentity::SetApplicationIdentity should similarly be considered as input to this identity decision, and be similarly captured and applied with the Application Specific Driver State API.

The DDI requesting the drivers determination of application identity via a D3D12DDI_APPLICATION_DESC is therefore somewhat redundant with capturing the Application Driver State blob.  However, the D3D12DDI_APPLICATION_DESC is not opaque and allows for comparison with other sources so we can drive out mismatches, including cross driver vendor mismatches.

The Application Specific Driver State API should continue to be the way that capture/replay tools override app detect mechanisms and apply the settings for the app being replayed.

## API

### GUID: CLSID_D3D12ApplicationIdentity

Use CLSID_D3D12ApplicationIdentity with D3D12GetInterface to set default application identity for subsequent device creation.  Use ID3D12DeviceFactory::GetConfigurationInterface to set application identity per-device.  See ID3D12ApplicationIdentity for the relevant interface definition.

```c++
DEFINE_GUID(CLSID_D3D12ApplicationIdentity,           0x08d8e1e8, 0x75a6, 0x42a7, 0xbf, 0x3a, 0xd0, 0x5f, 0xe5, 0x29, 0xc4, 0x7c);
```

### Union: D3D12_VERSION_NUMBER

Describes a version number.  Used to describe the version of the compiler, application profiles, application versions, and engine versions.

Note: This is a pre-existing union, but is included in this spec for reference.

```c++
typedef union D3D12_VERSION_NUMBER
{
    UINT64 Version;
    UINT16 VersionParts[4];
} D3D12_VERSION_NUMBER;
```

**Members**

*Version*

A 64 bit encoding of four 16bit values to define a four part version as X.X.X.X.  The most significant 16bits are the first number, the next most significant bits are the second, etc.  

*VersionParts*

A 16 bit array representation of the version number.

### Struct: D3D12_APPLICATION_DESC

```c++
typedef struct D3D12_APPLICATION_DESC
{
    LPCWSTR pExeFilename;
    LPCWSTR pName;
    D3D12_VERSION_NUMBER Version;
    LPCWSTR pEngineName;
    D3D12_VERSION_NUMBER EngineVersion;
} D3D12_APPLICATION_DESC;
```

Metadata to allow to identify an application.  Information may be used to select an application specific compiler profile when compiling.

Note: This is a pre-existing struct, but is included in this spec for reference.

**Members**

*pExeFilename*

Main application executable name.  Includes the file extension, i.e "Code.exe".  If supplied, this parameter must be null terminated.  See Remarks.

*pName*

The title of the application.  Example: "Microsoft Visual Studio Code".  This parameter is required and must be null terminated.

*Version*

The version of the application.  For example, for Visual Studio Code 1.93.1, the version would be:

0x0001005D00010000

This parameter is required.  See [D3D12_VERSION_NUMBER](#union-d3d12_version_number).

*pEngineName*

The name of the game engine used.  Example "Godot", "Unity", "Unreal Engine", etc.  This parameter is optional, but should be provided whenever possible and must be null terminated.  Use nullptr to indicate not applicable.

*EngineVersion*

The version of the engine.  For example, for Godot 4.3, the version would be:

0x0004000300000000

If pEngineName nullptr, set EngineVersion to zero.  See [D3D12_VERSION_NUMBER](#union-d3d12_version_number).

**Remarks**

The member pExeFilename is used to help uniquely identify an application, but SODBs and PSDBs generated with this value may be used with executables whose exe files have been renamed. For usermode drivers and the D3D12 runtime, this value is not guaranteed to match the host executable of the respective dlls.

When ID3D12ApplicationIdentity::SetApplicationIdentity is called with a nullptr for D3D12_APPLICATION_DESC::pExeFilename, the exe file name is determined by calling GetModuleFileName with a NULL handle is used.

An application may have multiple SODBs, but the application information must be identical between them.

### Interface: ID3D12ApplicationIdentity

Interface used to set application identity.  See CLSID_D3D12ApplicationIdentity to access and for scope.

```c++
interface ID3D12ApplicationIdentity
    : IUnknown
{
    HRESULT SetApplicationIdentity(const D3D12_APPLICATION_DESC* pDesc, REFGUID AppId);
};
```

#### Method: ID3D12ApplicationIdentity::SetApplicationIdentity

Set the Application Identity for the current process.

**Arguments**

*pDesc*

The application desc to set.  See [D3D12_APPLICATION_DESC](#struct-d3d12_application_desc).

*AppId*

A version 4 universally unique identifier generated for the app that is self-identifying.

**Remarks**

The application must supply a name.  When ID3D12ApplicationIdentity::SetApplicationIdentity is called with a nullptr for D3D12_APPLICATION_DESC::pExeFilename, the exe file name is determined by calling GetModuleFileName with a NULL handle is used.

## D3D12StateObjectCompiler: Get/Set SODB Application Identity

D3D12StateObjectCompiler.exe provides commands for reading and writing the Application Identity from a State Object Database (SODB).

### Write an Application Identity to an SODB

This command writes an Application Identity to a State Object Database.  It overwrites any existing Application Identity in the database.

```cmd
.\D3D12StateObjectCompiler.exe set-identity --exe-filename "game.exe" --name "Application Name" --app-version 1.0 --engine "Engine Name" --engine-version 1.0 "C:\temp\game.sodb"
```

**Remarks**

Version numbers such as --app-version and --engine-version parameters that contain a period character are parsed as MAJOR.MINOR.BUILD.REVISION where each version part is a UINT16.  If fewer than four parts are provided, missing parts are assumed to be zero (e.g., "1.0" becomes "1.0.0.0").  When the version number does not contain a period, it is treated as a UINT64 encoding of the version number similar to the API, so a 0x1000000000000 argument value in hex or 281474976710656 in decimal is equivalent to "1.0.0.0".

### Read Application Identity from an SODB

Use this command to query the Application Identity of a State Object Database.

```cmd
.\D3D12StateObjectCompiler.exe get-identity "C:\temp\game.sodb"
Application Description:
        Name: Application Name
        Exe Filename: game.exe
        Version: 1.0.0.0
        Engine Name: Engine Name
        Engine Version: 1.0.0.0
```
## Telemetry

Telemetry events to understand when ID3D12ApplicationIdentity::SetApplicationIdentity or PSDB mismatch, which can lead to unused precompiled shaders.
