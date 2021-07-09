# Debug Object Auto Name

It remains very common for unnamed objects to show up in debug layer error messages or Dred output.  In some cases, it simply isn't feasible to assign meaningful names to objects (e.g. Mapping Layers).

When available, D3D12 Debug Layer messages and DRED take advantage of debug names to help focus error investigations on the relevant elements.  When objects are unnamed, the debug layer simply reports 'Unnamed {interface type} Object'.  DRED is even less helpful, reporting only 'Unnamed Object'.

Debug Object Auto-Naming takes advantage of the unique create-time properties of the various D3D12 objects to automatically produce a name string that can be used when a debug name is not found.

For example: A committed 256 x 512 2D texture could be auto-named: 
"Unnamed Committed ID3D12Resource: Format=R8G8B8A8_UNORM, Dimension=Texture2D, Width=256, Height=512, ArraySize=1, MipLevels=3"

By default, auto-naming is disabled.  To enable auto-naming the ID3D12Debug5 interface provides a SetEnableAutoName method.

To prevent application compatibility issues, auto-names are not accessible using public ID3D12Object::GetPrivateData() keys.  Auto-names will only appear in DRED output and Debug Layer messages.  As such, auto-names can be improved over time should the need arise.

## d3dconfig.exe
Users can use d3dconfig.exe to override application control of auto-naming by setting the 'device auto-debug-name' variable to 'app-controlled', 'forced-off', or 'forced-on'.

## API's

### ID3D12Debug5::SetEnableAutoDebugName

Enables or disables Debug Object Auto-Naming.

#### Parameters

| Parameter   | Description                                         |
|-------------|-----------------------------------------------------|
| BOOL Enable | Set to TRUE to enable auto-naming, FALSE to disable |

#### Return Value

void

#### Remarks

When Auto-Naming is enabled, the D3D12 runtime composes a descriptive name for many D3D object types that are reported in debug and DRED output.  These names are only reported in debug output when the object is unnamed at the time the debug output is generated.

Auto-Naming is disabled by default.

It is still strongly recommended that developers assign meaningful debug object names to API objects whenever possible.  Auto-names are not guaranteed to be unique identifiers.

Note that an auto-name is generated for every nameable D3D12 object when auto-naming is enabled.  Therefore, it may not be ideal to enable Auto-Naming in some retail applications.

The auto-name is internal-only.  By design, there is no programmatic way to get the auto-generated name.  This allows auto-names to evolve over time without risking regressions in apps that would otherwise depend on the name string.

Auto-Naming can be controlled on using [d3dconfig.exe](https://devblogs.microsoft.com/directx/d3dconfig-a-new-tool-to-manage-directx-control-panel-settings/).
