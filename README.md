This repository publishes raw copies of the engineering specs that were created during 
the development of DirectX features. It supplements the official API documentation on 
[docs.microsoft.com](https://docs.microsoft.com/en-us/windows/desktop/directx) with a 
detailed look at how each feature was described during the design process between 
Microsoft and our IHV partners. These specs are not the best place to start if you 
are new to DirectX and wanting to learn the API, but can be useful for expert users 
who want to see the same level of detail that was described while implementing each 
feature.

Note that some of this material (especially in older specs) may not have been kept up to 
date with changes that occurred since the spec was written.

This material is presented with different interfaces at two different URLs:
* To read the specs, use [https://microsoft.github.io/DirectX-Specs](https://microsoft.github.io/DirectX-Specs)
* To view history, clone, file an issue or prepare a pull request, use [https://github.com/Microsoft/DirectX-Specs](https://github.com/Microsoft/DirectX-Specs)

## Direct3D 12

* Rendering Pipeline
    * [DirectX Raytracing (DXR)](d3d/Raytracing.md)
    * [Variable Rate Shading](d3d/VariableRateShading.md)
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

* Performance
    * [CPU Efficiency](d3d/CPUEfficiency.md)
    * [Render Passes](d3d/RenderPasses.md)
    * [Background Processing](d3d/BackgroundProcessing.md)

* Developer Features
    * [Device Removed Extended Data](d3d/DeviceRemovedExtendedData.md)

_These D3D12 specs were written as incremental deltas, with a separate spec per feature area.
Baseline information about rendering pipeline behaviors that are common between D3D11 and D3D12
was inherited from the D3D11 spec rather than being duplicated into the 12 documentation.
We have an ambition of refactoring this material to present more of a unified how-things-are-now
view, rather than a historical what-changed-to-get-here, and to merge in more foundational
information from the D3D11 spec. Contributions welcome if you'd like to help with this!_

_This is not yet the full set of D3D12 specs: we will be adding more as time permits.
Please let us know if there are particular areas you would  like to see prioritized._

## Direct3D 11

[Direct3D 11.3 Functional Specification](d3d/archive/D3D11_3_FunctionalSpec.htm)

_This is a single combined spec, covering all functionality of D3D versions from 10 to 11.3._

## Related links

* [Official DirectX API documentation ](https://docs.microsoft.com/en-us/windows/desktop/directx)
* [DirectX Developer Blog](https://devblogs.microsoft.com/directx)
* [PIX on Windows](https://devblogs.microsoft.com/pix/documentation)
* [DirectX Graphics Samples](https://github.com/Microsoft/DirectX-Graphics-Samples)
* [D3DX12 (the D3D12 Helper Library)](https://github.com/Microsoft/DirectX-Graphics-Samples/tree/master/Libraries/D3DX12)
* [D3D12 Raytracing Fallback Layer](https://github.com/Microsoft/DirectX-Graphics-Samples/tree/master/Libraries/D3D12RaytracingFallback)
* [D3D12 Residency Starter Library](https://github.com/Microsoft/DirectX-Graphics-Samples/tree/master/Libraries/D3DX12Residency)
* [D3D12 MultiGPU Starter Library](https://github.com/Microsoft/DirectX-Graphics-Samples/tree/master/Libraries/D3DX12AffinityLayer)
* [D3DDred debugger extension](https://github.com/Microsoft/DirectX-Debugging-Tools)
* [DirectX team on Twitter](https://twitter.com/DirectX12)

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
