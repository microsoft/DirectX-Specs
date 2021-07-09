This repository publishes the engineering specs for a number of DirectX features.
It supplements the [official API documentation](https://docs.microsoft.com/en-us/windows/desktop/directx)
with an extra level of detail that can be useful to expert developers.

Note that some of this material (especially in older specs) may not have been kept up to 
date with changes that occurred since the spec was written.

These specs are presented with different interfaces at two different URLs:
* To read the specs, use [https://microsoft.github.io/DirectX-Specs](https://microsoft.github.io/DirectX-Specs)
* To view history, clone, file an issue or prepare a pull request, use [https://github.com/Microsoft/DirectX-Specs](https://github.com/Microsoft/DirectX-Specs)

Make sure that you visit the [DirectX Landing Page](https://devblogs.microsoft.com/directx/landing-page/) for more resources for DirectX developers.

## Direct3D 12

* Rendering Pipeline
    * [Mesh Shader](d3d/MeshShader.md)
    * [Sampler Feedback](d3d/SamplerFeedback.md)
    * [DirectX Raytracing (DXR)](d3d/Raytracing.md)
    * [Variable Rate Shading](d3d/VariableRateShading.md)
    * [Feature Level 12_2](d3d/D3D12_FeatureLevel12_2.md)
    * [View Instancing](d3d/ViewInstancing.md)
    * [Conservative Rasterization](d3d/ConservativeRasterization.md)
    * [Rasterizer Ordered Views](d3d/RasterOrderViews.md)
    * [Programmable Sample Positions](d3d/ProgrammableSamplePositions.md)
    * [Depth Bounds Test](d3d/DepthBoundsTest.md)

* Structure of D3D
    * [Resource Binding](d3d/ResourceBinding.md)
    * [Indirect Drawing](d3d/IndirectDrawing.md)
    * [Counters & Queries](d3d/CountersAndQueries.md)
    * [Relaxed Format Casting Rules](d3d/RelaxedCasting.md)
    * [UAV Typed Load](d3d/UAVTypedLoad.md)
    * [Planar Depth Stencil](d3d/PlanarDepthStencilDDISpec.md)

* Performance
    * [CPU Efficiency](d3d/CPUEfficiency.md)
    * [Render Passes](d3d/RenderPasses.md)
    * [Background Processing](d3d/BackgroundProcessing.md)
    * [Shader Cache](d3d/ShaderCache.md)

* Video
    * [Motion Estimation](d3d/D3D12_Video_Motion_Estimation.md)
    * [Protected Resources](d3d/ProtectedResources.md)
    * [Video Protected Resource Support](d3d/D3D12_Video_ProtectedResourceSupport.md)

* HLSL
    * [Shader Model 6.0](https://github.com/microsoft/DirectXShaderCompiler/wiki/Shader-Model-6.0)
    * [Shader Model 6.1](https://github.com/microsoft/DirectXShaderCompiler/wiki/Shader-Model-6.1)
    * [Shader Model 6.2](https://github.com/microsoft/DirectXShaderCompiler/wiki/Shader-Model-6.2)
    * [Shader Model 6.3](https://github.com/microsoft/DirectXShaderCompiler/wiki/Shader-Model-6.3)
    * [Shader Model 6.4](https://github.com/microsoft/DirectXShaderCompiler/wiki/Shader-Model-6.4)
    * [Shader Model 6.5](d3d/HLSL_ShaderModel6_5.md)
    * [Shader Model 6.6](d3d/HLSL_ShaderModel6_6.md)
    * [SV_Barycentrics](https://github.com/microsoft/DirectXShaderCompiler/wiki/SV_Barycentrics)
    * [SV_ViewID](https://github.com/microsoft/DirectXShaderCompiler/wiki/SV_ViewID)

* Developer Features
    * [Agility SDK](d3d/D3D12Redistributable.md)
    * [Device Removed Extended Data](d3d/DeviceRemovedExtendedData.md)
    * [Debug Object Auto Name](d3d/DebugObjectAutoName.md)
    * [Debug Layer Message Callbacks](d3d/MessageCallback.md)
    * [WriteBufferImmediate](d3d/D3D12WriteBufferImmediate.md)

* Misc
    * [D3D12 on Windows 7](d3d/D3D12onWin7.md)
    * [Translation Layer Resource Interoperability](d3d/TranslationLayerResourceInterop.md) (9on12 and 11on12)

_These D3D12 specs were written as incremental deltas, with a separate spec per feature area.
Baseline information about rendering pipeline behaviors that are common between D3D11 and D3D12
was inherited from the D3D11 spec rather than being duplicated into the 12 documentation.
We have an ambition of refactoring this material to present more of a unified how-things-are-now
view, rather than a historical what-changed-to-get-here, and to merge in foundational
information from the D3D11 spec. Contributions welcome if you'd like to help with that!_

_This is not yet a complete set of D3D12 specs: we'll be adding more as time permits.
Please let us know if there are particular areas you'd like to see prioritized._

## Direct3D 11

[Direct3D 11.3 Functional Specification](d3d/archive/D3D11_3_FunctionalSpec.htm)

_This is a single combined spec, covering all functionality of D3D versions from 10 to 11.3._

## Related links

* [DirectX API documentation ](https://docs.microsoft.com/en-us/windows/desktop/directx)
* [DirectX Developer Blog](https://devblogs.microsoft.com/directx)
* [DirectX team on Twitter](https://twitter.com/DirectX12)
* [DirectX Discord server](https://discord.gg/directx)
* [PIX on Windows](https://devblogs.microsoft.com/pix/documentation)
* [DirectX Graphics Samples](https://github.com/Microsoft/DirectX-Graphics-Samples)
* [D3DX12 (the D3D12 Helper Library)](https://github.com/Microsoft/DirectX-Graphics-Samples/tree/master/Libraries/D3DX12)
* [D3D12 Raytracing Fallback Layer](https://github.com/Microsoft/DirectX-Graphics-Samples/tree/master/Libraries/D3D12RaytracingFallback)
* [D3D12 Residency Starter Library](https://github.com/Microsoft/DirectX-Graphics-Samples/tree/master/Libraries/D3DX12Residency)
* [D3D12 MultiGPU Starter Library](https://github.com/Microsoft/DirectX-Graphics-Samples/tree/master/Libraries/D3DX12AffinityLayer)
* [DirectX Tool Kit](https://github.com/Microsoft/DirectXTK12)
* [D3DDred debugger extension](https://github.com/Microsoft/DirectX-Debugging-Tools)

# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

# Legal Notices

Microsoft and any contributors grant you a license to the Microsoft documentation and other content
in this repository under the [Creative Commons Attribution 4.0 International Public License](https://creativecommons.org/licenses/by/4.0/legalcode),
see the [LICENSE](LICENSE) file, and grant you a license to any code in the repository under the [MIT License](https://opensource.org/licenses/MIT), see the
[LICENSE-CODE](LICENSE-CODE) file.

Microsoft, Windows, Microsoft Azure and/or other Microsoft products and services referenced in the documentation
may be either trademarks or registered trademarks of Microsoft in the United States and/or other countries.
The licenses for this project do not grant you rights to use any Microsoft names, logos, or trademarks.
Microsoft's general trademark guidelines can be found at http://go.microsoft.com/fwlink/?LinkID=254653.

Privacy information can be found at https://privacy.microsoft.com/en-us/

Microsoft and any contributors reserve all other rights, whether under their respective copyrights, patents,
or trademarks, whether by implication, estoppel or otherwise.
