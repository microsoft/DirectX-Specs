# Feature Level 12_2

## Objectives
Feature level 12_2 exists as a means by which to standardize a set of features across the GPU ecosystem in a way that improves customers' experience with graphical games and applications on the Windows platform.

## Querying and API
The runtime queries the graphics driver for the 12_2 feature level in the same manner it queries for other feature levels.

> Remark
> 
>While feature level 12_2 could be inferred based on the right set of caps being at the right values, the runtime does not do this because inferring feature levels goes against pre-existing designs. Feature level 12_2 is something explicitly reported by the driver.

The enumeration value for 12_2 is expressed as follows:
```
typedef
enum D3D_FEATURE_LEVEL
{
    // ...
	D3D_FEATURE_LEVEL_12_2 = 0xc200

} 	D3D_FEATURE_LEVEL;
```

Feature level 12_2 is requested in the same manner as other feature levels, e.g., when creating a device:
```
    ComPtr<ID3D12Device> device;
    D3D_FEATURE_LEVEL featureLevel = D3D_FEATURE_LEVEL_12_2;
    HRESULT hr = D3D12CreateDevice(nullptr, featureLevel, IID_PPV_ARGS(&m_spDevice));
    if (SUCCEEDED(hr))
    {
        // feature level is supported by default adapter
    } 
```

## Capabilities

Feature level 12_2 is expressed in terms of capabilities and feature tiers directly queryable through CheckFeatureSupport.

If a device is feature level 12_2, it has

| Feature                                                                 | 12_2 proposed minimum         | Public spec
|:-                                                                       |-                              |- 
|Required driver model                                                    | WDDM 2.0	                  |
|Shader Model	                                                          | 6.5                           |[Link](https://microsoft.github.io/DirectX-Specs/d3d/HLSL_ShaderModel6_5.html)
|Raytracing tier	                                                      | Tier 1.1                      |[Link](https://microsoft.github.io/DirectX-Specs/d3d/Raytracing.html)
|Variable shading rate                                                    | Tier 2                        |[Link](https://microsoft.github.io/DirectX-Specs/d3d/VariableRateShading.html)
|Mesh shader tier	                                                      | Tier 1                        |[Link](https://microsoft.github.io/DirectX-Specs/d3d/MeshShader.html)
|Sampler feedback	                                                      | Tier 0.9                      |[Link](https://microsoft.github.io/DirectX-Specs/d3d/SamplerFeedback.html)
|Resource Binding Tier	                                                  | Tier 3                        |[Link](https://microsoft.github.io/DirectX-Specs/d3d/ResourceBinding.html#root-signature-version-11)
|Tiled Resources	                                                      | Tier 3
|Conservative Rasterization                                               | Tier 3                        |[Link](https://microsoft.github.io/DirectX-Specs/d3d/ConservativeRasterization.html)
|RootSignatureTier	                                                      | 1.1                           |[Link](https://microsoft.github.io/DirectX-Specs/d3d/ResourceBinding.html)
|DepthBoundsTestSupported	                                              | TRUE                          |[Link](https://microsoft.github.io/DirectX-Specs/d3d/DepthBoundsTest.html)
|WriteBufferImmediateSupportFlags	                                      | Direct, Compute, Bundle
|MaxGPUVirtualAddressBitsPerResource                                      | 40, on 64-bit processes
|MaxGPUVirtualAddressBitsPerProcess                                       | 40, on 64-bit processes

On feature level 12_2 devices, the two capabilities MaxGPUVirtualAddressBitsPerResource and MaxGPUVirtualAddressBitsPerProcess are guaranteed to be at least 40 for programs running in 64-bit processes (for example, x64-based processes are considered 64-bit processes). This idea pertains to process architecture which is not necessarily the same as CPU or operating system architecture. 

There are no guarantees in particular regarding MaxGPUVirtualAddressBitsPerResource and MaxGPUVirtualAddressBitsPerProcess for 32-bit processes.

Additionally, it has the following flags set

| Feature                                                                 | 12_2 proposed value 
|:-                                                                       |-                   
|WaveOps	                                                              | TRUE
|OutputMergerLogicOp	                                                  | TRUE
|VPAndRTArrayIndexFromAnyShaderFeedingRasterizerSupportWithoutGSEmulation | TRUE
|CopyQueueTimestampQueriesSupported	                                      | TRUE
|CastingFullyTypedFormatSupported	                                      | TRUE
|UnalignedBlockTexturesSuported	                                          | TRUE
|Int64ShaderOps	                                                          | TRUE

> Remark
>
> Some specifications, especially those from before the May 2019 Update, are not migrated to the DirectX-Specs repo.

## DDI
The Direct3D 12 UMD DDI has an enumeration, D3D12DDI_3DPIPELINELEVEL, for describing feature levels. This enumeration has a value for feature level 12.2:

```
typedef enum D3D12DDI_3DPIPELINELEVEL
{
    // ...
    D3D12DDI_3DPIPELINELEVEL_12_2 = 14,
} D3D12DDI_3DPIPELINELEVEL;
```

To find out which feature levels a driver supports, the runtime calls PFND3D12DDI_GETCAPS with 
* D3D12DDICAPS_TYPE_3DPIPELINESUPPORT, or
* D3D12DDICAPS_TYPE_3DPIPELINESUPPORT1

The difference between these two usages of GetCaps is as follows

| Selector            | Data interpretation                                                              | Valid returnable feature levels
|:-                   |-                                                                                 |- 
|3DPIPELINESUPPORT    | D3D12DDI_3DPIPELINELEVEL, simple output value                                    | 12.1 and earlier
|3DPIPELINESUPPORT1   | D3D12DDI_3DPIPELINESUPPORT1_DATA_0081, structure with an input and output field  | any, including 12.2 and later


The definition of D3D12DDI_3DPIPELINESUPPORT1_DATA_0081 is as follows

```
typedef struct D3D12DDI_3DPIPELINESUPPORT1_DATA_0081
{
    D3D12DDI_3DPIPELINELEVEL HighestRuntimeSupportedFeatureLevel; // input
    D3D12DDI_3DPIPELINELEVEL MaximumDriverSupportedFeatureLevel;  // output
} D3D12DDI_3DPIPELINESUPPORT1_DATA_0081;
```

For 3DPIPELINESUPPORT1, the runtime sets the value of HighestRuntimeSupportedFeatureLevel. 
The driver returns a value for MaximumDriverSupportedFeatureLevel which does not exceed HighestRuntimeSupportedFeatureLevel.

>#### Remark
> In practice:
> * Versions of Direct3D built into the operating system at or before Manganese (20H2) use 3DPIPELINESUPPORT.
> * Versions of Direct3D built into Iron operating system, or organized as a re-distributable use 3DPIPELINESUPPORT1, and fall back to 3DPIPELINESUPPORT if it fails.

### Discrepency in API-level and DDI-level reported capabilities
The WriteBufferImmediateSupportFlags capability D3D12_COMMAND_LIST_SUPPORT_FLAG_BUNDLE is switched on at the API level for drivers which report D3D12DDI_COMMAND_QUEUE_FLAG_3D at the DDI level.

## Validation

There is a Direct3D 12 conformance test to validate that a Direct3D 12 device created with feature level 12_2 capability satisfies at least the capabilities outlined in the Capabilities section of this document. This is a conformance test, not an HLK test because it exercises behaviors of the runtime not the driver. Other tests, external to the specific test for feature level 12_2, are in place to ensure that CheckFeatureSupport capabilities properly match with device behavior.
