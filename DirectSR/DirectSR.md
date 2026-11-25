# DirectSR

## Table Of Contents

- [Table Of Contents](#table-of-contents)
- [Introduction](#introduction)
- [SR Engines](#sr-engines)
- [SR Variants](#sr-variants)
- [Native GPU Super Resolution](#native-gpu-super-resolution)
  - [Internal Native SR Resources](#internal-native-sr-resources)
- [DirectSR Extensions](#directsr-extensions)
- [Cross-Device Performance Risks](#cross-device-performance-risks)
  - [Cross-Device Image Layout Compatibility](#cross-device-image-layout-compatibility)
  - [Image Memory Latency](#image-memory-latency)
  - [Mitigation Strategies](#mitigation-strategies)
- [SR Engine Inputs](#sr-engine-inputs)
  - [Target Color Image](#target-color-image)
  - [Source Color Image](#source-color-image)
  - [Source Depth](#source-depth)
  - [Source Image Region](#source-image-region)
  - [Motion Vectors](#motion-vectors)
  - [Motion Vector Scale](#motion-vector-scale)
  - [Camera Jitter](#camera-jitter)
  - [Exposure and Pre-Exposure](#exposure-and-pre-exposure)
  - [Exposure Scale Texture](#exposure-scale-texture)
  - [Ignore History Mask](#ignore-history-mask)
  - [Reactive Mask](#reactive-mask)
  - [Sharpness](#sharpness)
  - [Image Regions](#image-regions)
- [Super Resolution Variants](#super-resolution-variants)
  - [Native variants](#native-variants)
  - [Extension variants](#extension-variants)
- [API Design](#api-design)
  - [`DSR_OPTIMIZATION_TYPE` enum](#dsr_optimization_type-enum)
  - [`DSR_SUPERRES_VARIANT_FLAGS` enum](#dsr_superres_variant_flags-enum)
  - [`DSR_SUPERRES_CREATE_ENGINE_FLAGS` enum](#dsr_superres_create_engine_flags-enum)
  - [`DSR_SUPERRES_UPSCALER_EXECUTE_FLAGS` enum](#dsr_superres_upscaler_execute_flags-enum)
  - [`DSR_FLOAT2` struct](#dsr_float2-struct)
  - [`DSR_SIZE`](#dsr_size)
  - [`DSR_SUPERRES_CREATE_ENGINE_PARAMETERS` struct](#dsr_superres_create_engine_parameters-struct)
  - [`DSR_SUPERRES_VARIANT_DESC` struct](#dsr_superres_variant_desc-struct)
  - [`DSR_SUPERRES_SOURCE_SETTINGS`](#dsr_superres_source_settings)
  - [`DSR_SUPERRES_UPSCALER_EXECUTE_PARAMETERS` struct](#dsr_superres_upscaler_execute_parameters-struct)
  - [`IDSRDevice` interface](#idsrdevice-interface)
  - [`IDSRSuperResEngine` interface](#idsrsuperresengine-interface)
  - [`IDSRSuperResUpscaler` interface](#idsrsuperresupscaler-interface)
  - [`ID3D12DSRDeviceFactory` interface](#id3d12dsrdevicefactory-interface)
- [Examples](#examples)
  - [Creating an IDSRDevice](#creating-an-idsrdevice)
  - [Enumerating super resolution variants](#enumerating-super-resolution-variants)
  - [Creating an IDSRSuperResEngine and IDSRSuperResUpscaler](#creating-an-idsrsuperresengine-and-idsrsuperresupscaler)
  - [Executing super resolution upscale](#executing-super-resolution-upscale)
- [Agility SDK](#agility-sdk)
- [DirectSR Meta-Commands](#directsr-meta-commands)
  - [Native DirectSR Availability](#native-directsr-availability)
  - [Native DirectSR Variant Queries](#native-directsr-variant-queries)
  - [Native DirectSR Meta-Command Initialization](#native-directsr-meta-command-initialization)
  - [Native DirectSR Engine Creation](#native-directsr-engine-creation)
  - [Native DirectSR SuperRes Execution](#native-directsr-superres-execution)
  - [Meta-Command Parameters](#meta-command-parameters)
  - [Metacommand parameter flags](#metacommand-parameter-flags)
- [SR Extension Functions](#sr-extension-functions)
  - [`DSR_EX_VERSION` enum](#dsr_ex_version-enum)
  - [`DSRExSuperResEngineHandle` typedef](#dsrexsuperresenginehandle-typedef)
  - [`DSRExSuperResUpscalerHandle` typedef](#dsrexsuperresupscalerhandle-typedef)
  - [`DSRExGetVersionedFunctionTable` export](#dsrexgetversionedfunctiontable-export)
  - [`FNDSRExSuperResGetNumVariants` function](#fndsrexsuperresgetnumvariants-function)
  - [`FNDSRExSuperResEnumVariant` function](#fndsrexsuperresenumvariant-function)
  - [`FNDSRExSuperResQuerySourceSettings` function](#fndsrexsuperresquerysourcesettings-function)
  - [`FNDSRExSuperResCreateEngine` function](#fndsrexsuperrescreateengine-function)
  - [`FNDSRExSuperResDestroyUpscaler` function](#fndsrexsuperresdestroyupscaler-function)
  - [`FNDSRExSuperResGetOptimalJitterPattern` function](#fndsrexsuperresgetoptimaljitterpattern-function)
  - [`FNDSRExSuperResExecuteUpscaler` function](#fndsrexsuperresexecuteupscaler-function)
  - [`FNDSRExSuperResDestroyUpscaler` function](#fndsrexsuperresdestroyupscaler-function-1)
  - [`FNDSRExSuperResExecuteUpscaler` function](#fndsrexsuperresexecuteupscaler-function-1)
  - [`FNDSRExSuperResUpscalerEvict` function](#fndsrexsuperresupscalerevict-function)
  - [`FNDSRExSuperResUpscalerMakeResident` function](#fndsrexsuperresupscalermakeresident-function)
  - [`DSR_EX_FUNCTION_TABLE_0001` struct](#dsr_ex_function_table_0001-struct)
- [Debug Validation](#debug-validation)

## Introduction

DirectSR provides a Direct3D-compatible API surface for performing super resolution (SR) image scaling and enhancement. Super resolution can be used to upscale low resolution images to high resolutions images with better quality than standard filtering methods (e.g. bilinear or bicubic filtering).

There are already a handful of vendor-specific super resolution APIs with similar (but not identical) designs. DirectSR can help to unify SR code paths during app development. In addition, apps written using DirectSR can take advantage of new super resolution topologies as they evolve such as ML coprocessors (e.g. NPUs).

An `IDSRDevice` object is initialized using an `ID3D12Device` pointer provided by the application. Super resolution engine initialization is performed by using the `IDSRSuperResEngine` interface.

In addition to running super resolution natively on a D3D12 device GPU, DirectSR can also be used to perform super resolution on ML coprocessors, such as NPUs, using the same API surface. This offers flexibility for apps to free up GPU resources, or even take advantage of hardware-accelerated super resolution on available ML coprocessors when the GPU doesn't natively support super resolution.

---

## SR Engines

A super resolution engine is a simplified abstraction of a fixed-function SR pipeline. An SR engine may include one or more built-in pre-processing stages, neural-network model execution, and post-processing filters. From a DirectSR perspective, an SR model is a "black box" with a well-defined set of inputs and outputs.

Not all SR engines are the same, varying in input requirements and output quality. On output, engines may perform post-SR image sharpening or noise reduction while others may leave this up to the application.

---

## SR Variants

More than one super resolution variant may be available on a `IDSRDevice` instance. Each variant can be enumerated and queried for unique properties, including source/target settings or optional features. "Native variants" are variants natively supported on the application-supplied `ID3D12Device`. "Extension Variants" are variants supported using DirectSR extensions.

---

## Native GPU Super Resolution

Some in-market GPU devices natively support super resolution. However, apps must implement highly-divergent custom code paths to take advantage of this on different vendor GPUs. In most cases, the vendor-specific APIs do not enable optimal SR on other SR-capable devices. DirectSR provides a flexible interface allowing apps to exploit SR on any device that supports native SR.

Native fixed-function D3D12 device support for super resolution is exposed using metacommands. Meta-commands expose custom hardware functionality, and are carefully curated by Microsoft with well-defined inputs and outputs.

### Internal Native SR Resources

Many native SR engine implementations use internal resources for keeping track of temporal state between frames. This is fine as long as API capture tools like PIX can keep track of these internal resources. As such, DirectSR is responsible for allocating Native SR resources and managing SRVs and UAVs of these resources. In addition, there is a limit of 256 internal resources per temporal state. Again, this is limitation is necessary for tools like PIX to be able to properly capture and replay frames.

The resources and views are created and initialized once for each `IDSRSuperResUpscaler` at creation time.

SR engines themselves must not be stateful. Any state must be managed using `IDSRSuperResUpscaler`.

Queries are issued for enumerating internal resource and view creation parameters at Engine creation time. DirectSR creates the resources and views during `IDSRSuperResUpscaler` creation. One UAV and one SRV for each resource. Each resource has three descriptor handles, an SRV descriptor (GPU handle only), and a UAV descriptor (both a GPU handle and a CPU handle). SRVs and UAVs are created on these descriptor handles at engine create time and remain static for the lifetime of the engine.

---

## DirectSR Extensions

DirectSR extension libraries are used to drive additional super resolution variants that may not be natively supported by the app-provided device. Extension libraries are needed to support SR on ML coprocessors. ML coprocessors, such as neural processing units (NPU), are highly-specialized for running neural network models. ML coprocessors may be used to efficiently perform SR upscaling, potentially freeing up the GPU to focus on graphics and compute workloads in parallel.

Like super resolution metacommands, DirectSR extensions are curated by Microsoft and have well-defined interfaces.

---

## Cross-Device Performance Risks

One of the primary benefits of enabling SR on ML devices is to free up the GPU to focus on other workloads. However, data transfers and synchronization costs can introduce latency. Also, data layouts may be incompatible, requiring additional time to transcode the data between device accesses. Such latency must be minimized by an engine for ML devices to be useful for super resolution.

### Cross-Device Image Layout Compatibility

In general, image memory in textures cannot be directly shared between two different devices because they may not use the same data layout. GPU images typically order pixels in memory by localized region or "tile" rather than linear scan line order. In addition, some lossless compression techniques (e.g. RLE) may be used to maximize data throughput. This pattern is sometimes referred to as "swizzled layout". Swizzled layouts maximize cache efficiency given that sequential accesses tend to be nearby in two-dimensional space, and are typically vendor-proprietary, opaque to other vendor devices and drivers.

### Image Memory Latency

The benefits of SR must be weighed against the latency costs in cross-device SR implementations. Depending on the devices involved, image data must either reside in system memory or must be copied to/through system memory. This can introduce latency between various SR pipeline stages. If the latency costs are too high, it may be better to simply render at a high resolution with a lower framerate.

For example, consider a worst-case SR pipeline using a discrete GPU device and a discrete NPU device.

- The GPU renders to an image in device-local VRAM (including SR preprocessing).
- The rendered color and depth images are copied/blitted to system memory (possibly transcoded to row-major layout).
- The system memory images are copied to NPU memory (possibly transcoded to ideal NPU swizzle layout).
- The NPU performs image up-scaling.
- The upscaled image is copied back to system memory (possibly transcoded to row-major layout).
- The upscaled system memory image is copied back to discrete GPU memory (possibly transcoded to ideal GPU swizzle layout).
- The GPU performs additional post-processing.

In some scenarios, a delay of even 17 milliseconds could drop the framerate from 60 FPS to 30 FPS or less if the application does not have a sufficient number swap chain back buffers to absorb the latency.

### Mitigation Strategies

In order to minimize the costs of transferring image data between devices, there are a few options to consider. One or more of the following methods may be needed:

#### Method 1: Swizzle GUID

Ideally, the devices can efficiently access the same image data with zero-copies and zero-transcode.

In theory, [D3D12 Standard Swizzle](https://docs.microsoft.com/en-us/windows/win32/direct3d12/default-texture-mapping#overview-of-standard-swizzle) could help with this. However, standard swizzle was never broadly adopted by GPU vendors and is unlikely to gain renewed interest.

Instead of prescribing a constrained set of "standard" layouts, it may be reasonable to ask vendors their swizzle layouts be made public, identified by a globally-unique identifier (GUID). Drivers can be queried whether a given swizzle GUID is supported - along with some "performance quality" measure (possibly a normalized weight or a simple PREFERRED vs SUPPORTED designation).

If two devices "optimally" support the same swizzle, then an application may be able to avoid less efficient data sharing options. This is especially useful if both of these devices share the same physical memory.

#### Method 2: Parameterized Swizzle

Historically, swizzled layout topologies been opaque to the application. However, D3D12 internally uses DDIs that report device swizzling parameters to help with presentation on hybrid systems. Exposing swizzle parameters to an application could give developers a tool for authoring shaders that can read or write to a non-native layout. However, reading from an arbitrary swizzle in a shader could negatively affect performance due to cache misses. Additionally, decoding swizzle logic could be computationally expensive, especially if there are compression aspects.

Alternatively, a cross-device, swizzle-converting copy could potentially be implemented by the D3D12 runtime without exposing swizzle parameter APIs. However, it is not clear whether this would be better than an app armed with swizzle data.

#### Method 3: Shared Heap Resources

In D3D12, resources created using [cross-adapter shared heaps](https://docs.microsoft.com/en-us/windows/win32/direct3d12/shared-heaps#sharing-heaps-across-adapters) can be accessed by any device. Cross-adapter shared resources use linear row-major layout and can be significantly less efficient than non-shared heap resources. In particular, discrete GPUs typically operate much slower on cross-adapter shared heap resources due to the lack of swizzling and the much longer memory access latency.

Depending on the devices involved, it may be acceptable for both devices to directly access the shared heap memory. In others, devices may need to "blit" linear data to a cross-adapter shared heap texture, which can either be accessed directly by the other device or require an additional "blit" to a more optimal layout/location for that device.

---

## SR Engine Inputs

Not all SR engines are identical. As such, some SR engines may have unique inputs or different constraints on input values. Such limitations and constraints need to be reported by the SR engine provider.

All texture resources are assumed to be non-array textures with only one mip level.

The SR execution inputs depend on the model design and how much pre-processing must be done by the application.

### Target Color Image

Target textures are assumed to be non-array textures with only one mip level. All operations are performed using subresource 0.

Target textures must be castable to one of the following formats:  

- `DXGI_FORMAT_R32G32B32A32_FLOAT`
- `DXGI_FORMAT_R16G16B16A16_FLOAT`
- `DXGI_FORMAT_R16G16B16A16_UNORM`
- `DXGI_FORMAT_R16G16B16A16_SNORM`
- `DXGI_FORMAT_R10G10B10A2_UNORM`
- `DXGI_FORMAT_R11G11B10_FLOAT`
- `DXGI_FORMAT_R8G8B8A8_UNORM`
- `DXGI_FORMAT_R8G8B8A8_SNORM`
- `DXGI_FORMAT_B8G8R8A8_UNORM`

The following target formats must also be supported if the underlying D3D12 device supports Typed UAV Loads:

- `DXGI_FORMAT_R32G32B32_FLOAT`
- `DXGI_FORMAT_B5G6R5_UNORM`
- `DXGI_FORMAT_R9G9B9E5_SHAREDEXP`

One of these formats must be declared as the Target format at engine create time.

The primary output is the upscaled super resolution target image. The output may be produced directly on one of the swap chain back buffers or some other color buffer that is subsequently used for additional post-processing.

Target alpha values must always be 1.0, regardless of the alpha values of the input color source.


### Source Color Image

Required: Yes  

Source Color textures must be castable to one of the following formats:  

- `DXGI_FORMAT_R32G32B32A32_FLOAT`
- `DXGI_FORMAT_R16G16B16A16_FLOAT`
- `DXGI_FORMAT_R16G16B16A16_UNORM`
- `DXGI_FORMAT_R16G16B16A16_SNORM`
- `DXGI_FORMAT_R10G10B10A2_UNORM`
- `DXGI_FORMAT_R11G11B10_FLOAT`
- `DXGI_FORMAT_R8G8B8A8_UNORM`
- `DXGI_FORMAT_R8G8B8A8_UNORM_SRGB`
- `DXGI_FORMAT_R8G8B8A8_SNORM`
- `DXGI_FORMAT_B5G6R5_UNORM`
- `DXGI_FORMAT_B8G8R8A8_UNORM`
- `DXGI_FORMAT_B8G8R8X8_UNORM`
- `DXGI_FORMAT_B8G8R8A8_UNORM_SRGB`
- `DXGI_FORMAT_B8G8R8X8_UNORM_SRGB`

It is assumed that the color image inputs are frequently initialized as a render target. Therefore, the following source color formats must also be supported if the underlying device supports RTV access:

- `DXGI_FORMAT_R32G32B32_FLOAT`
- `DXGI_FORMAT_R9G9B9E5_SHAREDEXP`

One of these formats must be declared as the Source Color format at engine create time.

Source color input texture subresource. Typically, this is a lower resolution than the target. However, it may occasionally be useful to use a source image of the same size as the target. One reason for this is to provide consistent results when using dynamic resolution scaling (DRS), where raw full-resolution rendered output would otherwise look inconsistent with SR upscaled output.

### Source Depth

Required: Yes  

Source Depth textures must be castable to one of the following formats:

- `DXGI_FORMAT_R24_UNORM_X8_TYPELESS`
- `DXGI_FORMAT_R32_FLOAT_X8X24_TYPELESS`
- `DXGI_FORMAT_R32_FLOAT`
- `DXGI_FORMAT_R16_UNORM`

One of these formats must be declared as the Source Depth format at engine create time.

Source depth texture subresource. Must use the same image region size as the source color image. Stencil data is ignored.

Upscaler execution is expected to read from the source depth texture as an SRV. Therefore, the source depth texture must be in a shader resource layout (`D3D12_BARRIER_LAYOUT_SHADER_RESOURCE` or `D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE`) during upscale execution.

### Source Image Region

Type: Rect

Rectangular region used by the source color and depth. Supports Dynamic Resolution Scaling (DRS).

### Motion Vectors

Required: Yes  

Supported Resource Format: `DXGI_FORMAT_R16G16_FLOAT`  

Must use the same region size as either the source image or the target image.

If the motion vector data is high resolution then they must be dilated. Specific dilation techniques are beyond the scope of this spec.

### Motion Vector Scale

Type: Float[2]  

Horizontal and vertical scale factors to translate motion vector input into source image texel space. Default value is 1.0.

### Camera Jitter

Type: Float[2]  

The jitter offset represents a translation of the camera in source pixel space that is expected to vary stochastically from one frame to the next. Jitter offset values must be in the range (-0.5, 0.5). Applications are expected to use the jitter value when projecting geometry into clip space. A modified projection matrix can be composed as the product of the original camera projection matrix and a pixel space jitter translation matrix. Since this jitter translation is applied to scene geometry, the jitter translation values are negated with respect to the camera jitter offset.

For example:

``` text
Jx -> Horizontal jitter value
Jy -> Vertical jitter value
Tx -> Horizontal pixel space jitter translation
Ty -> Vertical pixel space jitter translation
P  -> Typical row major projection matrix
J  -> Row major jitter translation matrix
P' -> Modified projection matrix

Tx = 2 * Jx / SourceColorWidth
Ty = -2 * Jy / SourceColorHeight (negated due to inverted Y in viewport pixel space)

J = | 1    0    0    0 |
    | 0    1    0    0 |
    | 0    0    1    0 |
    |-Tx  -Ty   0    1 |

P = | A    0    0    0 |
    | 0    B    0    0 |
    | 0    0    Q1  -1 |
    | 0    0    Q2   0 |

P'= P * J

P'= | A    0    0    0 |
    | 0    B    0    0 |
    | Tx   Ty   Q1  -1 |
    | 0    0    Q2   0 |
```

A careful observer may note that the modified projection matrix in this example is the same as the original projection matrix with `P'[2][0] = Tx` and `P'[2][1] = Ty`. Obviously, the results are transposed if using column vectors. This also assumes the topology of the original projection matrix matches this example.

Apps are strongly encouraged to use the jitter pattern reported by `IDSRSuperResEngine::GetOptimalJitterPattern` for optimal upscaling quality.  A low-quality jitter pattern (e.g. always passing in a jitter offset of 0,0) may produce very poor quality upscaling results.

### Exposure and Pre-Exposure

Type: Float  

Floating point scalar used to adjust exposure. These values are ignored if not using HDR or if `DSR_SUPERRES_CREATE_ENGINE_FLAG_AUTO_EXPOSURE` was set for engine creation.

The exposure value is provided in both the `ExposureScale` and `pExposureScaleTexture` members of `DSR_SUPERRES_UPSCALER_EXECUTE_PARAMETERS`.

The upscaler uses these values to transform the source color data before upscaling, and the target color data after upscaling.

Pre-Exposure is used by some engines that use a previous frame's exposure value to estimate the exposure level during the lighting pass. Providing both exposure and pre-exposure allows the SR upscaler to make better adjustments before and after upscaling.

The following exposure logic is used during SR upscaling:

- Source color is multiplied by `ExposureScale / PreExposure`.
- SR upscaling is performed using the exposure scaled color.
- Output of SR upscaling is multiplied by `PreExposure / ExposureScale` and result is written to the target color.

### Exposure Scale Texture

Required: No (Yes if using HDR)  

Exposure Scale textures must be castable to one of the following formats:

- `DXGI_FORMAT_R32_FLOAT`
- `DXGI_FORMAT_R16_FLOAT`
- `DXGI_FORMAT_R16_UNORM`
- `DXGI_FORMAT_R16_SNORM`
- `DXGI_FORMAT_R8_UNORM`
- `DXGI_FORMAT_R8_SNORM`

If using exposure scale, one of these formats must be declared as the Exposure Scale format at engine create time. If not, apps should indicate `DXGI_FORMAT_UNKNOWN`.

The texture pointed to by `pExposureScaleTexture` is a 1x1 texture containing the exposure scale value in the red channel. This value is expected to match the `ExposureScale` value in the corresponding `DSR_SUPERRES_UPSCALER_EXECUTE_PARAMETERS` parameter passed into `IDSRSuperResUpscaler::Execute`.

This is needed because there may be both CPU and GPU operations done by the SR upscaler that need the exposure scale value.

Although 2, 3 and 4 channel formats are supported. Only the red channel is used.

### Ignore History Mask

Required: No  

Supported Resource Formats:

- `DXGI_FORMAT_R8_UINT`

Ignores temporal history for corresponding source pixel if R value is non-zero. This can be useful for some engines where a pixel has no historical upscaler in the previous frame. For example, a visible section of roadway that was occluded by a moving car in the previous frame.

### Reactive Mask

Required: No  

Supported Resource Formats:

- `DXGI_FORMAT_R8_UNORM`

The term "reactivity" means how much influence the samples rendered for the current frame have over the production of the final upscaled image. Samples rendered for the current frame often contribute a relatively modest amount to the result computed by SR engines; however, there are exceptions. To produce the best results for fast moving, alpha-blended objects, SR engines should become more reactive to such pixels. As there is no robust way to determine from traditional upscaling input data (e.g.: color, depth, or motion vectors) which pixels have been rendered using alpha blending, SR engines may perform better when applications explicitly mark such areas.

Therefore, it is strongly encouraged that applications provide a reactivity mask to DirectSR engines that support them (as indicated by `DSR_SUPERRES_VARIANT_FLAG_SUPPORTS_REACTIVE_MASK`). The reactivity mask guides DirectSR implementations on where they should reduce their reliance on historical information when compositing the current pixel, and instead allow the current frame's samples to contribute more to the result. The reactivity mask allows the application to provide a value from [0.0..1.0] where 0.0 indicates that the pixel is not at all reactive (and should use the DirectSR engine’s default composition strategy), and a value of 1.0 indicates the pixel should be fully reactive.

While there are other applications for the reactivity mask, the primary application for the reactivity mask is producing better results of upscaling images which include alpha-blended objects. Therefore, a good proxy for reactiveness is the alpha value used when compositing an alpha-blended object into the scene. Applications may begin by writing alpha to the reactivity mask. It should be noted that it is unlikely that a reactive value of close to 1 will ever produce good results. Therefore, apps may choose to clamp the maximum reactive value to around 0.9.

If a reactive mask is not provided to a supporting engine, then a default value of 0 will be assumed for every pixel on execution.

Reactive masks are ignored by engine variants that do not explicitly support them. It may be best for apps to to predicate generation of reactive masks by checking the variant desc for `DSR_SUPERRES_VARIANT_FLAG_SUPPORTS_REACTIVE_MASK`.

Although 2, 3 and 4 channel formats are supported. Only the red channel is used.

### Sharpness

Type: Float  
Required: No  

Variants supporting sharpness must set the `DSR_SUPERRES_VARIANT_FLAG_SUPPORTS_SHARPNESS`. Sharpness values must be between 0.0 and 1.0, with 1 being maximum sharpness, and 0 being no sharpening. Values provided outside this range are clamped by the DirectSR runtime. Sharpening is essential for producing quality output on some variants.

This spec does not prescribe any specific sharpening algorithm. Therefore, a given sharpness could produce different visual results on different SR solutions. However, this is consistent with the fact that there is also no prescribed SR upscaling algorithm. So differences in visual output between various vendors is already an accepted risk.

Sharpness values are ignored if the variant does not set the `DSR_SUPERRES_VARIANT_FLAG_SUPPORTS_SHARPNESS` flag or if the engine is created without the `DSR_SUPERRES_CREATE_ENGINE_FLAG_ENABLE_SHARPENING` bit set.

### Image Regions

A `D3D12_RECT` region parameter is used to define the location and size of source and target images for upscaler execution. This can be useful for some dynamic resolution scaling scenarios by allowing applications to provide different sized input from the same set of source textures. 

Upscaling targets must use a constant image region size declared during engine creation.

---

## Super Resolution Variants

More than one super resolution engine may be available for a given DirectSR device.

A given device or SR extension may support more than one variant with different performance characteristics, optimization techniques, or other quality trade-offs. Vendors must implement metacommand queries to report the number of native SR variants for the variant attributes.

The DirectSR runtime enumerates these SR variants using the `IDSRDevice::EnumSuperResolutionVariant` which initializes an `D3D12_SUPER_RESOLUTION_VARIANT_DESC` struct. The DirectSR runtime may expose additional variants to the application in cases where SR variants are available on separate hardware from the rendering GPU. It is possible that some systems with an NPU or other compute-only devices can provide one or more SR options separate from native GPU SR variants. In some cases, the native device GPU driver may not super resolution, but another GPU or compute device does.

### Native variants

Native super resolution variants are supported by the GPU driver for a given D3D12 device. Native variants are specific to a given GPU/driver combination.

### Extension variants

Extension super resolution variants are required to support non-native Super Resolution techniques. Extensions can support cross-vendor super resolution variants and may even run on ML coprocessors such as NPUs. Examples of extension variants include Auto SR and DirectSR built-in variants.

Extension super resolution variants are provided by Microsoft. There are currently no plans to support app-provided super resolution extensions.

---

## API Design

### `DSR_OPTIMIZATION_TYPE` enum

``` C++
typedef enum DSR_OPTIMIZATION_TYPE
{
    DSR_OPTIMIZATION_TYPE_BALANCED,
    DSR_OPTIMIZATION_TYPE_HIGH_QUALITY,
    DSR_OPTIMIZATION_TYPE_MAX_QUALITY,
    DSR_OPTIMIZATION_TYPE_HIGH_PERFORMANCE,
    DSR_OPTIMIZATION_TYPE_MAX_PERFORMANCE,
    DSR_OPTIMIZATION_TYPE_POWER_SAVING,
    DSR_OPTIMIZATION_TYPE_MAX_POWER_SAVING,
    DSR_NUM_OPTIMIZATION_TYPES,
} DSR_OPTIMIZATION_TYPE;
```

| Constant                                 | Description                                                            |
|------------------------------------------|------------------------------------------------------------------------|
| `DSR_OPTIMIZATION_TYPE_BALANCED`         | Balanced optimization with no preference for quality over performance. |
| `DSR_OPTIMIZATION_TYPE_HIGH_QUALITY`     | Prefers quality over performance.                                      |
| `DSR_OPTIMIZATION_TYPE_MAX_QUALITY`      | Maximum quality setting.                                               |
| `DSR_OPTIMIZATION_TYPE_HIGH_PERFORMANCE` | Prefers performance over quality.                                      |
| `DSR_OPTIMIZATION_TYPE_MAX_PERFORMANCE`  | Maximum performance setting.                                           |
| `DSR_OPTIMIZATION_TYPE_POWER_SAVING`     | Prefer power saving over performance or quality.                       |
| `DSR_OPTIMIZATION_TYPE_MAX_POWER_SAVING` | Maximum power saving.                                                  |

### `DSR_SUPERRES_VARIANT_FLAGS` enum

Bitfield flags indicating boolean attributes of a super resolution variant.

``` C++
typedef enum DSR_SUPERRES_VARIANT_FLAGS
{
    DSR_SUPERRES_VARIANT_FLAG_NONE                                = 0x0,
    DSR_SUPERRES_VARIANT_FLAG_SUPPORTS_EXPOSURE_SCALE_TEXTURE     = 0x1,
    DSR_SUPERRES_VARIANT_FLAG_SUPPORTS_IGNORE_HISTORY_MASK        = 0x2,
    DSR_SUPERRES_VARIANT_FLAG_NATIVE                              = 0x4,
    DSR_SUPERRES_VARIANT_FLAG_SUPPORTS_REACTIVE_MASK              = 0x8,
    DSR_SUPERRES_VARIANT_FLAG_SUPPORTS_SHARPNESS                  = 0x10,
    DSR_SUPERRES_VARIANT_FLAG_DISALLOWS_REGION_OFFSETS            = 0x20,
} DSR_SUPERRES_VARIANT_FLAGS;
```

| Bit                                                         | Description                                                                              |
|-------------------------------------------------------------|------------------------------------------------------------------------------------------|
| `DSR_SUPERRES_VARIANT_FLAG_SUPPORTS_EXPOSURE_SCALE_TEXTURE` | Variant uses exposure scale texture during execution.                                    |
| `DSR_SUPERRES_VARIANT_FLAG_SUPPORTS_IGNORE_HISTORY_MASK`    | Variant supports a mask texture marking pixels that do not have contextual history.      |
| `DSR_SUPERRES_VARIANT_FLAG_NATIVE`                          | Set if the variant is provided by the app-provided D3D12 device.                         |
| `DSR_SUPERRES_VARIANT_FLAG_SUPPORTS_REACTIVE_MASK`          | Variant supports reactive mask.                                                          |
| `DSR_SUPERRES_VARIANT_FLAG_SUPPORTS_SHARPNESS`              | Variant supports the `Sharpness` value in `DSR_SUPERRES_UPSCALER_EXECUTE_PARAMETERS`.    |
| `DSR_SUPERRES_VARIANT_FLAG_DISALLOWS_REGION_OFFSETS`        | If this flag is set, all `top` and `left` region values must be set to zero by the app.  |

### `DSR_SUPERRES_CREATE_ENGINE_FLAGS` enum

Bitfield flags provided at SR engine creation time controlling boolean attributes. Can be combined using bitwise OR.

``` C++
typedef enum DSR_SUPERRES_CREATE_ENGINE_FLAGS
{
    DSR_SUPERRES_CREATE_ENGINE_FLAG_NONE = 0x0,
    DSR_SUPERRES_CREATE_ENGINE_FLAG_MOTION_VECTORS_USE_TARGET_DIMENSIONS = 0x1,
    DSR_SUPERRES_CREATE_ENGINE_FLAG_AUTO_EXPOSURE = 0x2,
    DSR_SUPERRES_CREATE_ENGINE_FLAG_ALLOW_DRS = 0x4,
    DSR_SUPERRES_CREATE_ENGINE_FLAG_MOTION_VECTORS_USE_JITTER_OFFSETS = 0x8,
    DSR_SUPERRES_CREATE_ENGINE_FLAG_ALLOW_SUBRECT_OUTPUT = 0x10,
    DSR_SUPERRES_CREATE_ENGINE_FLAG_LINEAR_DEPTH = 0x20,
    DSR_SUPERRES_CREATE_ENGINE_FLAG_ENABLE_SHARPENING = 0x40,
    DSR_SUPERRES_CREATE_ENGINE_FLAG_FORCE_LDR_COLORS = 0x80,
} DSR_SUPERRES_CREATE_ENGINE_FLAGS;
```

| Bit                                                                    | Description                                                                                                                  |
|------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------|
| `DSR_SUPERRES_CREATE_ENGINE_FLAG_MOTION_VECTORS_USE_TARGET_DIMENSIONS` | Motion vectors can be provided at either source or target dimensions.                                                        |
| `DSR_SUPERRES_CREATE_ENGINE_FLAG_AUTO_EXPOSURE`                        | Automatically apply exposure during SR execution.                                                                            |
| `DSR_SUPERRES_CREATE_ENGINE_FLAG_ALLOW_DRS`                            | Indicates source images may use dynamic resolution scaling (DRS).                                                            |
| `DSR_SUPERRES_CREATE_ENGINE_FLAG_MOTION_VECTORS_USE_JITTER_OFFSETS`    | Indicates that the motion vectors are rendered using the camera jitter offsets.                                              |
| `DSR_SUPERRES_CREATE_ENGINE_FLAG_ALLOW_SUBRECT_OUTPUT`                 | Indicates that SR output can be written to a subrect of the target image.                                                    |
| `DSR_SUPERRES_CREATE_ENGINE_FLAG_LINEAR_DEPTH`                         | Indicates that the depth buffer contains linear (*1/z*) depth values.                                                        |
| `DSR_SUPERRES_CREATE_ENGINE_FLAG_ENABLE_SHARPENING`                    | If this bit is not set then the `Sharpness` execution parameter is ignored.                                                  |
| `DSR_SUPERRES_CREATE_ENGINE_FLAG_FORCE_LDR_COLORS`                     | Input and output resources using HDR-capable formats are assumed to contain only LDR color data (values between 0.0 and 1.0) |

### `DSR_SUPERRES_UPSCALER_EXECUTE_FLAGS` enum

``` C++
typedef enum DSR_SUPERRES_UPSCALER_EXECUTE_FLAGS
{
    DSR_SUPERRES_UPSCALER_EXECUTE_FLAG_NONE =             0,
    DSR_SUPERRES_UPSCALER_EXECUTE_FLAG_RESET_HISTORY =    0x1,
} DSR_SUPERRES_UPSCALER_EXECUTE_FLAGS;
```

| Bit                                              | Description                                                                                  |
|--------------------------------------------------|----------------------------------------------------------------------------------------------|
| DSR_SUPERRES_UPSCALER_EXECUTE_FLAG_RESET_HISTORY | Resets any state dependencies on preceding frames. Typically used to indicate a scene "cut". |

### `DSR_FLOAT2` struct

Represents a pair of floating point values, typically representing a 2D coordinate, scale or offset.

``` C++
typedef struct DSR_FLOAT2
{
    float X;
    float Y;
} DSR_FLOAT2;
```

| Member | Description  |
|--------|--------------|
| `X`    | X coordinate |
| `Y`    | Y coordinate |

### `DSR_SIZE`

Represents a discrete, two-dimensional size. Typically used in DirectSR to describe source and target image sizes.

``` C++
typedef struct DSR_SIZE
{
    UINT Width;
    UINT Height;
} DSR_SIZE;
```

### `DSR_SUPERRES_CREATE_ENGINE_PARAMETERS` struct

Describes create-time attributes for an `IDSRSuperResEngine` interface object. Used by `IDSRDevice::CreateSuperResEngine`.

``` C++
typedef struct DSR_SUPERRES_CREATE_ENGINE_PARAMETERS
{
    GUID VariantId;
    DXGI_FORMAT TargetFormat;
    DXGI_FORMAT SourceColorFormat;
    DXGI_FORMAT SourceDepthFormat;
    DXGI_FORMAT ExposureScaleFormat;
    DSR_SUPERRES_CREATE_ENGINE_FLAGS Flags;
    DSR_SIZE MaxSourceSize;
    DSR_SIZE TargetSize;
} DSR_SUPERRES_CREATE_ENGINE_PARAMETERS;
```

| Member                | Description                                                                     |
|-----------------------|---------------------------------------------------------------------------------|
| `VariantId`           | Id of super resolution variant.                                                 |
| `TargetFormat`        | Target color texture format.                                                    |
| `SourceColorFormat`   | Source color texture format.                                                    |
| `SourceDepthFormat`   | Source depth texture SRV format.                                                |
| `ExposureScaleFormat` | Exposure scale texture format (DXGI_FORMAT_UNKNOWN if exposure scale not used). |
| `Flags`               | Boolean create flags.                                                           |
| `MaxSourceSize`       | Maximum source size the application will use.                                   |
| `TargetSize`          | Target size the application will use.                                           |

`MaxSourceSize` and `TargetSize` represent image sizes rather than physical texture dimensions. The location and size of an image is defined as a region within a texture. It is acceptable to use source textures (color, depth, etc) with physical dimensions larger than `MaxSourceSize`, as long as the upscaling source image regions are no larger than `MaxSourceSize`. Likewise, it is acceptable to use a target texture larger than `TargetSize` as long as the target image region size matches `TargetSize`.

### `DSR_SUPERRES_VARIANT_DESC` struct

Describes an SR variant in terms of optional inputs, execution characteristics, and name string.

``` C++
typedef struct DSR_SUPERRES_VARIANT_DESC
{
    GUID VariantId;
    CHAR VariantName[128];
    DSR_SUPERRES_VARIANT_FLAGS Flags;
    DSR_OPTIMIZATION_TYPE OptimizationRankings[DSR_NUM_OPTIMIZATION_TYPES];
    DXGI_FORMAT OptimalTargetFormat;
} DSR_SUPERRES_VARIANT_DESC;
```

| Member                 | Description                                                                                                                                                                     |
|------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `VariantId`            | Unique identifier of variant.                                                                                                                                                   |
| `VariantName`          | NULL-terminated UTF-8 variant name string.                                                                                                                                      |
| `Flags`                | Flag attributes of variant.                                                                                                                                                     |
| `OptimizationRankings` | Contains array of optimization types sorted by relevance to the variant algorithm.                                                                                              |
| `OptimalTargetFormat`  | Optimal format for target resource. May be a TYPELESS format if all formats in a given "typeless family" are optimal. May be DXGI_FORMAT_UNKNOWN if there is no optimal format. |

Some variants may be designed to maximize performance while others may prefer image quality or power savings. The `OptimizationRankings` can be used by an application to determine which variants best match a desired optimization type. For example, an application preferring `DSR_OPTIMIZATION_TYPE_HIGH_QUALITY` can sort all of the variants by the index of `DSR_OPTIMIZATION_TYPE_HIGH_QUALITY` in the `OptimizationRankings`, selecting the first variant matching other desired characteristics.

All of the `DSR_OPTIMIZATION_TYPE` values (except `DSR_NUM_OPTIMIZATION_TYPES`) must be listed in the `OptimizationRankings` array, and each value may only be listed once.

### `DSR_SUPERRES_SOURCE_SETTINGS`

Used by `IDSRDevice::QuerySuperResSourceSettings` for querying source settings.

``` C++
typedef struct DSR_SUPERRES_SOURCE_SETTINGS
{
    DSR_SIZE OptimalSize;
    DSR_SIZE MinDynamicSize;
    DSR_SIZE MaxDynamicSize;
    DXGI_FORMAT OptimalColorFormat;
    DXGI_FORMAT OptimalDepthFormat;
} DSR_SUPERRES_SOURCE_SETTINGS;
```

| Member               | Description                                                                                                                                                                          |
|----------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `OptimalSize`        | Optimal size for source input.                                                                                                                                                       |
| `MinDynamicSize`     | Minimum size for source input.                                                                                                                                                       |
| `MaxDynamicSize`     | Maximum size for source input.                                                                                                                                                       |
| `OptimalColorFormat` | Optimal format for color source input. May be a TYPELESS format if all formats in a given "typeless family" are optimal. May be DXGI_FORMAT_UNKNOWN if there are no optimal formats. |
| `OptimalDepthFormat` | Optimal format for depth source input. May be a TYPELESS format if all formats in a given "typeless family" are optimal. May be DXGI_FORMAT_UNKNOWN if there are no optimal formats. |

### `DSR_SUPERRES_UPSCALER_EXECUTE_PARAMETERS` struct

Parameters for super resolution execution.

``` C++
typedef struct DSR_SUPERRES_UPSCALER_EXECUTE_PARAMETERS
{
    ID3D12Resource *pTargetTexture;
    D3D12_RECT TargetRegion;

    // Required inputs

    ID3D12Resource *pSourceColorTexture;
    D3D12_RECT SourceColorRegion;

    ID3D12Resource *pSourceDepthTexture;
    D3D12_RECT SourceDepthRegion;

    ID3D12Resource *pMotionVectorsTexture;
    D3D12_RECT MotionVectorsRegion;

    DSR_FLOAT2 MotionVectorScale;
    DSR_FLOAT2 CameraJitter;
    float ExposureScale;
    float PreExposure;
    float Sharpness;
    float CameraNear;
    float CameraFar;
    float CameraFovAngleVert;

    // Optional inputs

    ID3D12Resource *pExposureScaleTexture;

    ID3D12Resource *pIgnoreHistoryMaskTexture;
    D3D12_RECT IgnoreHistoryMaskRegion;

    ID3D12Resource *pReactiveMaskTexture;
    D3D12_RECT ReactiveMaskRegion;
} DSR_SUPERRES_UPSCALER_EXECUTE_PARAMETERS;
```

| Member                      | Description                                                                                                                                         |
|-----------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| `pTargetTexture`            | Pointer to target color texture.                                                                                                                    |
| `TargetRegion`              | Target image region.                                                                                                                                |
| `pSourceColorTexture`       | Pointer to source color texture.                                                                                                                    |
| `SourceColorRegion`         | Source color image region.                                                                                                                          |
| `pSourceDepthTexture`       | Pointer to source depth texture.                                                                                                                    |
| `SourceDepthRegion`         | Source depth image region.                                                                                                                          |
| `pMotionVectorsTexture`     | Pointer to texture containing motion vectors data. Can be high-res or low-res (see notes).                                                          |
| `MotionVectorsRegion`       | Motion vectors image region.                                                                                                                        |
| `MotionVectorScale`         | Multipliers to transform motion vectors into texel space. Set to (1,1) if motion vectors are already in texel space.                                |
| `CameraJitter`              | Camera jitter values. Optimal jitter values can be fetched using `IDSRSuperResEngine::GetOptimalJitterPattern`                                      |
| `ExposureScale`             | Exposure scale value.                                                                                                                               |
| `PreExposure`               | A value the input color is divided by to get back to the original color produced by the app before any packing into lower precision render targets. |
| `Sharpness`                 | Amount to sharpen the SR color output. Ignored if sharpening is not enabled or supported.                                                           |
| `CameraNear`                | Distance to the camera near plane (See notes).                                                                                                      |
| `CameraFar`                 | Distance to the far camera plane (See notes).                                                                                                       |
| `CameraFovAngleVert`        | Vertical camera field of view angle in radians.                                                                                                     |
| `pExposureScaleTexture`     | Optional pointer to an 1x1 texture with the exposure value in the R channel.                                                                        |
| `pIgnoreHistoryMaskTexture` | Optional pointer to ignore history mask texture. Corresponding source color texels with non-zero R values do not have temporal history.             |
| `IgnoreHistoryMaskRegion`   | Ignore history mask image region region.                                                                                                            |
| `pReactiveMaskTexture`      | Optional pointer to reactive mask texture.                                                                                                          |
| `ReactiveMaskRegion`        | Reactive mask image region region.                                                                                                                  |

Source and target image regions represent the full source and target images. Pixels within the source image region are upscaled to the target image region. Source color, source depth, and any mask image regions must all be the same size. Likewise, the motion vectors image region must either match the source color image region size or the target image region size. Image regions extending beyond the boundaries of the physical texture are clipped to the texture dimensions before upscaling. This can be useful for trivially specifying a rect that uses an entire texture without having to query or track texture sizes (e.g. `Top=0, Left=0, Bottom=INT_MAX, Right=INT_MAX`).

The `pExposureScaleTexture` does not require region size since it is required to be a 1x1 texture.

The `Sharpness` parameter is ignored if the engine variant doesn't support sharpening or the engine was created without the `DSR_SUPERRES_CREATE_ENGINE_FLAG_ENABLE_SHARPENING` bit set.

The `CameraNear` and `CameraFar` values assume depth *Z* values are 0 at the near clip plane and 1 at the far plane. Some applications choose to use reverse *Z* to even out the distribution of *Z* values. If using reverse *Z*, the values of `CameraNear` and `CameraFar` should be swapped such that `CameraNear` is actually the distance to the far clip plan and `CameraFar` is actually the distance to the near clip plane.

Apps may also choose a projection matrix that uses infinite depth (*Z* values approach 1 as *d* approaches infinity). Apps using infinite depth should set `CameraFar` to `INFINITY` (or `CameraNear` if also using reverse *Z*).

#### Required Resource Layout/state

Resources must be in a layout/state that is compatible with the engine usage of the resource. All Input resources are accessed as non-pixel-shader resources and all output resources are accessed as unordered access views.

Input resource (Source Color, Source Depth, etc) compatible barrier layouts:

- `D3D12_BARRIER_LAYOUT_SHADER_RESOURCE`
- `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_SHADER_RESOURCE` (if using DIRECT queue)
- `D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_SHADER_RESOURCE` (if using COMPUTE queue)
- `D3D12_BARRIER_LAYOUT_GENERIC_READ`
- `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_GENERIC_READ` (if using DIRECT queue)
- `D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_GENERIC_READ` (if using COMPUTE queue)
- `D3D12_BARRIER_LAYOUT_COMMON`
- `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COMMON` (if using DIRECT queue)
- `D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_COMMON` (if using COMPUTE queue)

Input resource compatible legacy states:

- `D3D12_RESOURCE_STATE_COMMON`
- `D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE`

Output (Target) resource compatible barrier layouts:

- `D3D12_BARRIER_LAYOUT_UNORDERED_ACCESS`
- `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_UNORDERED_ACCESS`
- `D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_UNORDERED_ACCESS`
- `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COMMON` (if using DIRECT queue)
- `D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_COMMON` (if using COMPUTE queue)

Output resource compatible legacy states:

- `D3D12_RESOURCE_STATE_UNORDERED_ACCESS`

### `IDSRDevice` interface

Interface that is used to query support for super resolution and creating SR engines.

#### `IDSRDevice::GetNumSuperResVariants` method

Returns the number of SR variants supported by the device.

``` C++
UINT IDSRDevice::GetNumSuperResVariants();
```

Returns zero if there are no SR variants available on the device.

#### `IDSRDevice::GetSuperResVariantDesc` method

Fills in a `DSR_SUPERRES_VARIANT_DESC` for the given `VariantIndex`.

``` C++
HRESULT IDSRDevice::GetSuperResVariantDesc(
    UINT VariantIndex,
    _Out_ DSR_SUPERRES_VARIANT_DESC *pVariantDesc);
```

If successful, sets `*pVariantDesc` with a description of the SR variant at index `VariantIndex`. If no variant with the given index exists then `GetSuperResVariantDesc` returns `DXGI_ERROR_NOT_FOUND`.

#### `IDSRDevice::QuerySuperResSourceSettings` method

Queries for the source settings of a given variant based on the desired target dimensions, execution mode and create flags.

``` C++
HRESULT IDSRDevice::QuerySuperResSourceSettings(
    UINT VariantIndex,
    DSR_SIZE TargetSize,
    DXGI_FORMAT TargetFormat,
    DSR_OPTIMIZATION_TYPE OptimizationType,
    DSR_SUPERRES_CREATE_ENGINE_FLAGS CreateFlags,
    _Out_ DSR_SUPERRES_SOURCE_SETTINGS *pSourceSettings);
```

| Parameter          | Description                                                                                                    |
|--------------------|----------------------------------------------------------------------------------------------------------------|
| `VariantIndex`     | Index of the associated SR variant.                                                                            |
| `TargetSize`       | The region size of the output target.                                                                          |
| `TargetFormat`     | The format of the target texture. Must be a known, non-typeless format.                                        |
| `OptimizationType` | Preferred optimization characteristics (only influences `Optimal*` members of `DSR_SUPERRES_SOURCE_SETTINGS`). |
| `CreateFlags`      | The create flags expected to be used for engine creation.                                                      |
| `pSourceSettings`  | A pointer to a DSR_SUPERRES_SOURCE_SETTINGS struct that contains source settings.                              |

Some super resolution variants may use ML models that work best with a specific range of source sizes or formats. In addition, the optimal source settings may depend on other create-time parameters such as create flags.

The output values of `pSourceSettings->MinDynamicSize.Width` and `pSourceSettings->MinDynamicSize.Height` must be at least 1.

Maximum source size is assumed to be the same as `TargetSize`.

Only `pSourceSettings->OptimalSourceSize`, `pSourceSettings->OptimalColorFormat` and `pSourceSettings->OptimalDepthFormat` depend on `OptimizationType`. All other `DSR_SUPERRES_SOURCE_SETTINGS` output are independent of `OptimizationType`.

#### `IDSRDevice::CreateSuperResEngine` method

Creates an IDSRSuperResEngine interface.

``` C++
HRESULT IDSRDevice::CreateSuperResEngine(
  _In_ const DSR_SUPERRES_CREATE_ENGINE_PARAMETERS *pDesc,
  _In_ REFIID iid,
  _COM_Outptr_ void **ppEngine);
```

| Parameter | Description                                   |
|-----------|-----------------------------------------------|
| pDesc     | Creation parameters.                          |
| iid       | UUID of super resolution engine interface.    |
| ppEngine  | Output pointer to super resolution interface. |

### `IDSRSuperResEngine` interface

A `IDSRSuperResEngine` object is an instance of a Super Resolution engine. Creation of an `IDSRSuperResEngine` initializes the SR engine back end.

#### `IDSRSuperResEngine::CreateUpscaler` method

Creates and initializes an `IDSRSuperResUpscaler` object.

``` C++
HRESULT WINAPI IDSRSuperResEngine::CreateUpscaler(
    _In_ ID3D12CommandQueue *pCommandQueue,
    _In_ REFIID iid,
    _COM_Outptr_ void **ppUpscaler);
```

| Parameter  | Description                                 |
|------------|---------------------------------------------|
| iid        | IID of the `IDSRSuperResUpscaler` interface |
| ppUpscaler | Address of upscaler interface pointer       |

Returns S_OK on success.

The `pCommandQueue` is the queue used for upscaler initialization and all subsequent executions. This queue must either be type `D3D12_COMMAND_LIST_TYPE_DIRECT` or `D3D12_COMMAND_LIST_TYPE_COMPUTE`. Upscaler creation may use this queue to initialize resources used for internal state. All initialization work must be fully queued before `CreateUpscaler` returns, however queue execution happens asynchronously. Apps can detect completion of upscaler initialization by signaling a fence on this queue.

#### `IDSRSuperResEngine::GetOptimalJitterPattern` method

Returns the optimal camera jitter pattern (if available) used by the SR engine.

``` C++
HRESULT IDSRSuperResEngine::GetOptimalJitterPattern(
    DSR_SIZE SourceSize,
    DSR_SIZE TargetSize,
    _Inout_ UINT *pPatternArraySize,
    _Out_opt_ DSR_FLOAT2 *pPattern)
```

| Parameter           | Description                                                                                                                                    |
|---------------------|------------------------------------------------------------------------------------------------------------------------------------------------|
| `SourceSize`        | Size of source region.                                                                                                                         |
| `TargetSize`        | Size of the target region.                                                                                                                     |
| `pPatternArraySize` | On input, points to the size in elements of the array pointed to by `pPattern`. On output, points to the length of the optimal jitter pattern. |
| `pPattern`          | Pointer to a `DSR_FLOAT2` array. May be NULL.                                                                                                  |

Returns `S_OK` on success. The caller provides the size of the `pPattern` array on input. This must point to a valid address, though the value at that address may initially be 0 if pPattern is `NULL`. On output, the `UINT` value pointed to by `pPatternArraySize` contains the actual length of the optimal jitter pattern, which may be larger than the provided array size of `pPattern`.

The optimal jitter pattern may depend on the dimensions of the source image.

If `pPattern` is not NULL, then the optimal camera jitter pattern offset values are written to the array of DSR_FLOAT2 values pointed to by `pPattern`. If `PatternArraySize` is less than the optimal pattern length, then only `PatternArraySize` elements are written.

Example:

``` C++
// Query pattern length
std::vector<DSR_FLOAT2> pattern;
UINT length = pSREngine->GetOptimalJitterPattern(nullptr, 0, 1024, 768, 3840, 1644);
if(length > 0)
{
    // Allocate and initialize the array
    pattern.resize(length);
    pSREngine->GetOptimalJitterPattern(pattern.data(), length, 1024, 768, 3840, 1644);
}
else
{
    pattern = MyCustomJitterPattern();
}
```

It is not required to use the optimal jitter pattern. However, the optimal pattern is expected to provide the "best quality" results. Any jitter pattern should be evenly distributed over the pixel surface.

### `IDSRSuperResUpscaler` interface

The `IDSRSuperResUpscaler` performs upscaling operations using input state and internally-tracked historical context.

SR upscalers may use state from previous executions as input for subsequent frames.

An `IDSRSuperResUpscaler` instance is created using `IDSRSuperResEngine::CreateUpscaler`. Multiple `IDSRSuperResUpscaler` objects can be created on the same `IDSRSuperResEngine` instance.

On Native SR engines, the `IDSRSuperResUpscaler` manages internal resources requested by the engine. In addition, each `IDSRSuperResUpscaler` instance manages its own descriptor heap, containing descriptors for all input, output, and internal resources.

Extension variant engines provide a handle to an upscaler, which is implemented by the extension.

#### `IDSRSuperResUpscaler::Execute` method

Queues up an execution of the super resolution upscaling engine.

``` C++
HRESULT IDSRSuperResUpscaler::Execute(
    _In_ const DSR_SUPERRES_UPSCALER_EXECUTE_PARAMETERS *pParams,
    float TimeDeltaInSeconds,
    DSR_SUPERRES_UPSCALER_EXECUTE_FLAGS Flags);
```

| Parameter            | Description                                                                                                                                               |
|----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| `pParams`            | Execution input parameters.                                                                                                                               |
| `TimeDeltaInSeconds` | Time elapsed in seconds since previous `Execute` on the same upscaler. Ignored if `Flags` has `DSR_SUPERRES_UPSCALER_EXECUTE_FLAG_RESET_HISTORY` bit set. |
| `Flags`              | Execution flags.                                                                                                                                          |

SR execution effectively occurs on the command queue specified during upscaler creation. `Execute` is thread-safe and asynchronous. The SR execution is complete when the command queue starts processing subsequent operations. Applications should wait for the queue to signal a subsequent fence signal before destroying or modifying resources used in `pParams`.

Multiple concurrent SR workloads can be scheduled on the same engine using different input and output values.

The `TimeDeltaInSeconds` value is useful for some SR algorithms for reducing temporal artifacts.

`IDSRSuperResUpscaler::Execute` is thread-safe.

#### `IDSRSuperResUpscaler::Evict`

Evicts internal graphics memory resources and heaps (see https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12device-evict). Also makes the upscaler inaccessible until the application uses a corresponding `IDSRSuperResUpscaler::MakeResident`.

``` C++
HRESULT IDSRSuperResUpscaler::Evict();
```

`IDSRSuperResUpscaler::Evict` and `IDSRSuperResUpscaler::MakeResident` are reference-counted, meaning for each `Evict` there must be a corresponding `MakeResident` before the upscaler is accessible.

Note, the upscaler is placed in an inaccessible state even if it does not use graphics memory. This allows some extension variant upscalers to perform custom eviction tasks (such as freeing up ML coprocessor resources).

#### `IDSRSuperResUpscaler::MakeResident`

Makes internal graphics memory resources and heaps resident.

``` C++
HRESULT IDSRSuperResUpscaler::MakeResident();
```

`IDSRSuperResUpscaler::Evict` and `IDSRSuperResUpscaler::MakeResident` are reference-counted, meaning for each `Evict` there must be a corresponding `MakeResident` before the upscaler is accessible.

### `ID3D12DSRDeviceFactory` interface

Factory interface used to create an `IDSRDevice`. Declared in `D3D12.h` and implemented in the core D3D12 runtime.

Applications create an `ID3D12DSRDeviceFactory` using `D3D12GetInterface`:

``` C++
CComPtr<ID3D12DSRDeviceFactory> pDSRDeviceFactory;
CComPtr<IDSRDevice> pDSRDevice;
ThrowFailure(D3D12GetInterface(CLSID_D3D12DSRDeviceFactory, IID_PPV_ARGS(&pDSRDeviceFactory)));
ThrowFailure(pDSRDeviceFactory->CreateDSRDevice(pD3D12Device, IID_PPV_ARGS(&pDSRDevice)));
```

The purpose of using the D3D12 runtime for `ID3D12DSRDeviceFactory` creation is to support DirectSR as an Agility SDK redistributable component. `D3D12GetInterface` loads `directsr.dll` from the same location as `d3d12core.dll`.

#### `CreateDSRDevice` method

Creates an `IDSRDevice` object.

```C++
HRESULT ID3D12DSRDeviceFactory::CreateDSRDevice(
    _In_ ID3D12Device* pD3D12Device,
    _In_ REFIID riid,
    _COM_Outptr_ void **ppDSRDevice));
```

---

## Examples

### Creating an IDSRDevice

``` C++
    ATL::CComPtr<ID3D12DSRDeviceFactory> pDSRDeviceFactory;
    THROW_HRESULT_FAILURE(D3D12GetInterface(CLSID_D3D12DSRDeviceFactory, IID_PPV_ARGS(&pDSRDeviceFactory)));

    ATL::CComPtr<IDSRDevice> pDSRDevice;
    THROW_HRESULT_FAILURE(pDSRDeviceFactory->CreateDSRDevice(pD3D12Device, IID_PPV_ARGS(&pDSRDevice)));
```

### Enumerating super resolution variants

The example code snippet below enumerates DirectSR super resolution variants available on a given `IDSRDevice` and maps them based on variant GUID.

``` C++
    UINT numDsrVariants = pDSRDevice->GetNumSuperResVariants();

    for(UINT index = 0; index < numDsrVariants; index++)
    {
        DSR_SUPERRES_VARIANT_DESC variantDesc;
        THROW_HRESULT_FAILURE(pDSRDevice->GetSuperResVariantDesc(Count, &variantDesc));
        g_myDsrDescMap.emplace(variantDesc.VariantId, variantDesc);
    }
```

### Creating an IDSRSuperResEngine and IDSRSuperResUpscaler

The following sample code creates a DirectSR super resolution engine. In this example, the maximum source size is set to the target size and sets the `DSR_SUPERRES_CREATE_ENGINE_FLAG_ALLOW_DRS` flag to indicate that the app intends to use dynamic resolution scaling.

``` C++
    ATL::CComPtr<IDSRSuperResEngine> pSREngine;
    DSR_SUPERRES_CREATE_ENGINE_PARAMETERS createParams = {};
    createParams.VariantId = VariantId;
    createParams.SourceColorFormat = DXGI_FORMAT_R10G10B10A2_UNORM;
    createParams.SourceDepthFormat = DXGI_FORMAT_R32_FLOAT;
    createParams.TargetFormat = DXGI_FORMAT_R10G10B10A2_UNORM;
    createParams.Flags = DSR_SUPERRES_CREATE_ENGINE_FLAG_ALLOW_DRS;
    createParams.TargetSize = DSR_SIZE{MY_TARGET_WIDTH, MY_TARGET_HEIGHT};
    createParams.MaxSourceSize = CreateParams.TargetSize;

    // Create the super resolution engine
    THROW_HRESULT_FAILURE(pSRDevice->CreateSuperResEngine(&createParams, IID_PPV_ARGS(&pSREngine)));

    // Create super resolution upscaler
    ATL::CComPtr<IDSRSuperResUpscaler> pSRUpscaler;
    THROW_HRESULT_FAILURE( pSREngine->CreateUpscaler(pCommandQueue, IID_PPV_ARGS(&pSRUpscaler)));
```

### Executing super resolution upscale

The example below executes a DirectSR super resolution upscale operation on the command queue used to create the upscaler. This example indicates the app is using infinite depth by setting `CameraNear` to zero and `CameraFar` to `INFINITY`. The example also sets the `DSR_SUPERRES_UPSCALER_EXECUTE_FLAG_RESET_HISTORY` if a supplied `sceneCut` value is `true`.

``` C++
    DSR_SUPERRES_UPSCALER_EXECUTE_PARAMETERS executeParams;
    executeParams.pTargetTexture = pTargetTex;
    executeParams.TargetRegion = D3D12_RECT{0, 0, MY_TARGET_WIDTH, MY_TARGET_HEIGHT};
    executeParams.pSourceColorTexture = pSourceColorTex;
    executeParams.SourceColorRegion = D3D12_RECT{0, 0, MY_SOURCE_WIDTH, MY_SOURCE_HEIGHT};
    executeParams.pSourceDepthTexture = pSourceDepthTex;
    executeParams.SourceDepthRegion = D3D12_RECT{0, 0, MY_SOURCE_WIDTH, MY_SOURCE_HEIGHT};
    executeParams.pMotionVectorsTexture = pMotionVecTex;
    executeParams.MotionVectorsRegion = D3D12_RECT{0, 0, MY_SOURCE_WIDTH, MY_SOURCE_HEIGHT};
    executeParams.MotionVectorScale = DSR_FLOAT2{1.0f, 1.0f};
    executeParams.CameraJitter = DSR_FLOAT2{g_CameraJitterX, g_CameraJitterY};
    executeParams.ExposureScale = 1.0f;
    executeParams.PreExposure = 1.0f;
    executeParams.Sharpness = 1.0f;
    executeParams.CameraNear = 0.f;
    executeParams.CameraFar = INFINITY;
    executeParams.CameraFovAngleVert = 1.0f;
    executeParams.pExposureScaleTexture = nullptr;
    executeParams.pIgnoreHistoryMaskTexture = nullptr;
    executeParams.IgnoreHistoryMaskRegion = D3D12_RECT{0, 0, MY_SOURCE_WIDTH, MY_SOURCE_HEIGHT};
    executeParams.pReactiveMaskTexture = pReactiveMask;
    executeParams.ReactiveMaskRegion = D3D12_RECT{0, 0, MY_SOURCE_WIDTH, MY_SOURCE_HEIGHT};
    DSR_SUPERRES_UPSCALER_EXECUTE_FLAGS executeFlags = sceneCut
        ? DSR_SUPERRES_UPSCALER_EXECUTE_FLAG_RESET_HISTORY
        : DSR_SUPERRES_UPSCALER_EXECUTE_FLAG_NONE;
    THROW_HRESULT_FAILURE(pSRUpscaler->Execute(&executeParams, deltaTimeInSeconds, executeFlags));
```

---

## Agility SDK

In addition to being part of the Windows Operating System, `directsr.dll` is included in the Agility SDK. Despite the fact that DirectSR is a layer built on top of D3D12 APIs, the core D3D12 runtime is responsible for loading `directsr.dll`. This guarantees that the `directsr.dll` runtime binary is in the same directory location as `d3d12core.dll`, and therefore benefits from the same Agility SDK redist enablement behavior as `d3d12core.dll` (https://microsoft.github.io/DirectX-Specs/d3d/D3D12Redistributable.html#application-and-games).

---

## DirectSR Meta-Commands

Drivers natively supporting DirectSR must support metacommand ID `DSR_SUPERRES_METACOMMAND` {936f7f01-203f-44d3-9e18-4198d243b4ea}. The name of the metacommand must be "DSR_SUPERRES_METACOMMAND"

### Native DirectSR Availability

DirectSR uses `ID3D12Device5::EnumerateMetaCommands` to enumerate all available metacommands, then iterates over the list searching for the required `DSR_SUPERRES_METACOMMAND` metacommand.

### Native DirectSR Variant Queries

DirectSR uses `ID3D12Device::CheckFeatureSupport` of type `D3D12_FEATURE_QUERY_META_COMMAND` to query for variants and variant properties. The `DSR_SUPERRES_QUERY_INPUT` struct is used as query input data, and the `DSR_SUPERRES_QUERY_OUTPUT` struct is used as query output.

#### `DSR_SUPERRES_META_COMMAND_QUERY_TYPE` enum

``` C++
typedef enum DSR_SUPERRES_META_COMMAND_QUERY_TYPE
{
    DSR_SUPERRES_META_COMMAND_QUERY_TYPE_GET_NUM_VARIANTS,
    DSR_SUPERRES_META_COMMAND_QUERY_TYPE_GET_VARIANT_DESC,
    DSR_SUPERRES_META_COMMAND_QUERY_TYPE_GET_SOURCE_PROPERTIES,
    DSR_SUPERRES_META_COMMAND_QUERY_TYPE_GET_OPTIMAL_JITTER_PATTERN,
    DSR_SUPERRES_META_COMMAND_QUERY_TYPE_GET_NUM_INTERNAL_RESOURCES,
    DSR_SUPERRES_META_COMMAND_QUERY_TYPE_GET_INTERNAL_RESOURCE_PARAMS,
    DSR_SUPERRES_META_COMMAND_QUERY_TYPE_GET_BUFFER_SIZES,
};
```

#### `DSR_SUPERRES_META_COMMAND_GET_INTERNAL_RESOURCE_PARAMS` struct

``` C++
typedef struct DSR_SUPERRES_META_COMMAND_GET_INTERNAL_RESOURCE_PARAMS
{
    D3D12_HEAP_PROPERTIES HeapProperties;
    D3D12_HEAP_FLAGS HeapFlags;
    D3D12_RESOURCE_DESC1 ResourceDesc;
    D3D12_BARRIER_LAYOUT InitialLayout;
    D3D12_SHADER_RESOURCE_VIEW_DESC SRVDesc;
    D3D12_UNORDERED_ACCESS_VIEW_DESC UAVDesc;
} DSR_SUPERRES_META_COMMAND_GET_INTERNAL_RESOURCE_PARAMS;
```

#### `DSR_SUPERRES_META_COMMAND_QUERY_INPUT` struct

Used as input for `D3D12_FEATURE_QUERY_DATA_META_COMMAND` when querying for variant properties.

``` C++
typedef struct DSR_SUPERRES_META_COMMAND_QUERY_INPUT
{
    DSR_SUPERRES_META_COMMAND_QUERY_TYPE Type;

    union
    {
        // Type: DSR_SUPERRES_META_COMMAND_QUERY_TYPE_GET_VARIANT_DESC
        struct
        {
            UINT VariantIndex;
        } GetVariantDesc;

        // Type: DSR_SUPERRES_META_COMMAND_QUERY_TYPE_GET_SOURCE_SETTINGS
        struct
        {
            UINT VariantIndex;
            DSR_SIZE TargetSize;
            DXGI_FORMAT TargetFormat;
            DSR_OPTIMIZATION_TYPE OptimizationType;
            DSR_SUPERRES_CREATE_ENGINE_FLAGS CreateEngineFlags;
        } GetSourceSettings;

        // Type: DSR_SUPERRES_META_COMMAND_QUERY_TYPE_GET_OPTIMAL_JITTER_PATTERN
        struct
        {
            UINT64 UniqueEngineId;
            UINT PatternArraySize;
            DSR_SIZE SourceSize;
            DSR_SIZE TargetSize;
            DSR_FLOAT2 *pPattern;
        } GetOptimalJitterPattern;

        // DSR_SUPERRES_META_COMMAND_QUERY_TYPE_GET_NUM_INTERNAL_RESOURCES
        struct
        {
            UINT64 UniqueEngineId;
        } GetNumInternalResources;

        // Type: DSR_SUPERRES_META_COMMAND_QUERY_TYPE_GET_INTERNAL_RESOURCE_PARAMS
        struct
        {
            UINT64 UniqueEngineId;
            UINT InternalResourceIndex;
        } GetInternalResourceParams;

        // Type: DSR_SUPERRES_META_COMMAND_QUERY_TYPE_GET_BUFFER_SIZES
        struct
        {
            UINT64 UniqueEngineId;
        } GetInternalBufferSizes;

        // Pad for future query types
        UINT Pad[256];
    };
} DSR_SUPERRES_META_COMMAND_QUERY_INPUT;
```

When `Type` is `DSR_SUPERRES_META_COMMAND_QUERY_TYPE_GET_NUM_VARIANTS` no other input parameters are used.

Some query data use a `UniqueEngineId`. This value uniquely identifies a single metacommand instance.

#### `DSR_SUPERRES_META_COMMAND_QUERY_OUTPUT` struct

Used as output for `D3D12_FEATURE_QUERY_DATA_META_COMMAND` when querying for variant properties.

``` C++
typedef struct DSR_SUPERRES_META_COMMAND_QUERY_OUTPUT
{
    union
    {
        // Type: DSR_SUPERRES_META_COMMAND_QUERY_TYPE_GET_NUM_VARIANTS
        struct
        {
            UINT NumVariants;
        } GetNumSuperResVariants;

        // Type: DSR_SUPERRES_META_COMMAND_QUERY_TYPE_GET_VARIANT_DESC
        struct
        {
            DSR_SUPERRES_VARIANT_DESC VariantDesc;
        } GetVariantDesc;

        // Type: DSR_SUPERRES_META_COMMAND_QUERY_TYPE_GET_SOURCE_SETTINGS
        DSR_SUPERRES_SOURCE_SETTINGS GetSourceSettings;

        // Type: DSR_SUPERRES_META_COMMAND_QUERY_TYPE_GET_OPTIMAL_JITTER_PATTERN
        struct
        {
            UINT PatternLength;
        } GetOptimalJitterPattern;

        // DSR_SUPERRES_META_COMMAND_QUERY_TYPE_GET_NUM_INTERNAL_RESOURCES
        struct
        {
            UINT NumResources;
        } GetNumInternalResources;

        // Type: DSR_SUPERRES_META_COMMAND_QUERY_TYPE_GET_INTERNAL_RESOURCE_PARAMS
        DSR_SUPERRES_META_COMMAND_GET_INTERNAL_RESOURCE_PARAMS GetInternalResourceParams;

        // Type: DSR_SUPERRES_META_COMMAND_QUERY_TYPE_GET_BUFFER_SIZES
        struct
        {
            UINT64 UploadHeapBufferSize;
            UINT64 DefaultHeapBufferSize;
        } GetInternalBufferSizes;

        // Pad for future query types
        UINT Pad[256];
    };
} DSR_SUPERRES_META_COMMAND_QUERY_OUTPUT;
```

### Native DirectSR Meta-Command Initialization

DirectSR calls `ID3D12GraphicsCommandList4::InitializeMetaCommand` for each SR upscaler at upscaler creation time. Drivers must use `InitializeMetaCommand` to setup internal structures and data to support metacommand usage. The application provides a `DSR_SUPERRES_META_COMMAND_INIT_PARAMS` struct to `InitializeMetaCommand`.

Note that drivers must avoid creating or using internal resources as part of metacommand initialization. Doing so would block PIX captures. Any internal resources must be declared using `DSR_SUPERRES_META_COMMAND_GET_INTERNAL_RESOURCE_PARAMS` so that resources and descriptors can be tracked by PIX.

### Native DirectSR Engine Creation

Native DirectSR engines use ID3D12MetaCommand to perform SR upscaling. The ID3D12Device5::CreateMetaCommand takes a pointer to a `DSR_SUPERRES_META_COMMAND_CREATE_PARAMS` struct to provide the create params, including a unique "engine id". The engine id can be used to query for state/properties unique to a metacommand instance (e.g. `GetOptimalJitterPattern`). The engine id is guaranteed to be unique system wide across all processes.

#### `DSR_SUPERRES_META_COMMAND_CREATE_PARAMS`

Used as input during metacommand engine creation.

``` C++
typedef struct DSR_SUPERRES_META_COMMAND_CREATE_PARAMS
{
    UINT VariantIndex;
    UINT64 UniqueEngineId;
    UINT64 TargetFormat;
    UINT64 SourceColorFormat;
    UINT64 SourceDepthFormat;
    UINT64 ExposureScaleFormat;
    UINT64 Flags;
    UINT64 MaxSourceSizeWidth;
    UINT64 MaxSourceSizeHeight;
    UINT64 TargetSizeWidth;
    UINT64 TargetSizeHeight;
} DSR_SUPERRES_META_COMMAND_CREATE_PARAMS;
```

| Parameter             | Description                                                                                          |
|-----------------------|------------------------------------------------------------------------------------------------------|
| `VariantIndex`        | Ordinal index of the variant as enumerated by DSR_SUPERRES_META_COMMAND_QUERY_TYPE_GET_VARIANT_DESC. |
| `UniqueEngineId`      | Unique id assigned by the DirectSR runtime to the engine instance.                                   |
| `TargetFormat`        | Target color texture format (DXGI_FORMAT cast to UINT64).                                            |
| `SourceColorFormat`   | Source color texture format (DXGI_FORMAT cast to UINT64).                                            |
| `SourceDepthFormat`   | Source depth texture SRV format (DXGI_FORMAT cast to UINT64).                                        |
| `ExposureScaleFormat` | Exposure scale texture format (DXGI_FORMAT_UNKNOWN if exposure scale not used).                      |
| `Flags`               | Boolean create flags (DSR_SUPERRES_CREATE_ENGINE_FLAGS cast to UINT64).                              |
| `MaxSourceSizeWidth`  | Maximum source size width the application will use.                                                  |
| `MaxSourceSizeHeight` | Maximum source size height the application will use.                                                 |
| `TargetSizeWidth`     | Target size width the application will use.                                                          |
| `TargetSizeHeight`    | Target size height the application will use.                                                         |

### Native DirectSR SuperRes Execution

The native DirectSR super resolution engine uses an app-provided Compute queue to execute DirectSR metacommands. However, DirectSR manages allocation of its own descriptor heaps, command lists and command allocators, and driver-internal resources.

#### Execution Descriptor Heaps Layout

The descriptor heaps used for SuperRes execution have the following predefined layout:

| Index     | GPU Descriptor          |
|-----------|-------------------------|
| 0         | Target UAV              |
| 1         | Source Color SRV        |
| 2         | Source Depth SRV        |
| 3         | Motion Vectors SRV      |
| 4         | Exposure Scale SRV      |
| 5         | Ignore History Mask SRV |
| 6         | Reactive Mask SRV       |
| 256 - 511 | Internal Resources UAVs |
| 512 - 519 | Internal Resources SRVs |

A non-shader-visible descriptor heap contains CPU UAV descriptors with the following layout:

| Index     | CPU Descriptor          |
|-----------|-------------------------|
| 0         | Target UAV              |
| 256 - 511 | Internal Resources UAVs |

#### VA Referenced Buffers

A single internal upload heap buffer and a single default heap buffer may be allocated if the metacommand engine requires them. These buffers are referenced only by GPU virtual address, so UAV and SRV access are not available with these resources. Given there is only a single buffer of each heap type, drivers must use suballocation instead of multiple buffers of a given heap type.

typedef struct DSR_SUPERRES_META_COMMAND_UPSCALER_EXECUTE_PARAMETERS
These buffers are only created if the driver reports non-zero size values during `DSR_SUPERRES_META_COMMAND_QUERY_TYPE_GET_BUFFER_SIZES` query. If no buffers are allocated, the runtime passes NULL VAs for in `DSR_SUPERRES_META_COMMAND_INIT_PARAMS` and `DSR_SUPERRES_META_COMMAND_UPSCALER_EXECUTE_PARAMETERS`.

### Meta-Command Parameters

#### `DSR_SUPERRES_META_COMMAND_INIT_PARAMS` struct

``` C++
typedef struct DSR_SUPERRES_META_COMMAND_INIT_PARAMS
{
    D3D12_CPU_DESCRIPTOR_HANDLE InternalBaseCPUDescriptorUAV;
    D3D12_GPU_DESCRIPTOR_HANDLE InternalBaseGPUDescriptorUAV;
    D3D12_GPU_DESCRIPTOR_HANDLE InternalBaseGPUDescriptorSRV;
    D3D12_GPU_VIRTUAL_ADDRESS InternalUploadHeapBufferVA;
    D3D12_GPU_VIRTUAL_ADDRESS InternalDefaultHeapBufferVA;
} DSR_SUPERRES_META_COMMAND_INIT_PARAMS;
```

Used in `ID3D12GraphicsCommandList4::InitializeMetaCommand` during upscaler creation.

For the `Base[CPU|GPU]Descriptor[UAV|SRV]` members, there can be at most 256 of each descriptor. Descriptors are in the same order in which internal resources are enumerated using DSR_SUPERRES_META_COMMAND_QUERY_INPUT::GetInternalResourceParams::InternalResourceIndex.

All internal VA and UAV descriptor parameters must enumerate with both `D3D12_META_COMMAND_PARAMETER_FLAG_INPUT` and `D3D12_META_COMMAND_PARAMETER_FLAG_OUTPUT` flags set. The `InternalBaseGPUDescriptorSRV` parameter must enumerate with only `D3D12_META_COMMAND_PARAMETER_FLAG_INPUT` set.

#### `DSR_SUPERRES_META_COMMAND_UPSCALER_EXECUTE_PARAMETERS` struct

Used as input for `ID3D12GraphicsCommandList4::ExecuteMetaCommand`.

``` C++
typedef struct DSR_SUPERRES_META_COMMAND_UPSCALER_EXECUTE_PARAMETERS
{
    // Execute method parameters
    float TimeDeltaInSeconds;
    UINT64 ExecuteFlags; // cast from DSR_SUPERRES_UPSCALER_EXECUTE_FLAGS

    // Required parameters
    D3D12_CPU_DESCRIPTOR_HANDLE TargetTextureCPUDescriptor; // Single subresource Tex2D UAV
    D3D12_GPU_DESCRIPTOR_HANDLE TargetTextureGPUDescriptor; // Single subresource Tex2D UAV
    UINT64 TargetRegionTop;
    UINT64 TargetRegionLeft;
    UINT64 TargetRegionBottom;
    UINT64 TargetRegionRight;

    D3D12_GPU_DESCRIPTOR_HANDLE SourceColorDescriptor; // Single subresource Tex2D SRV
    UINT64 SourceColorRegionTop;
    UINT64 SourceColorRegionLeft;
    UINT64 SourceColorRegionBottom;
    UINT64 SourceColorRegionRight;

    D3D12_GPU_DESCRIPTOR_HANDLE SourceDepthDescriptor; // Single subresource Tex2D SRV
    UINT64 SourceDepthRegionTop;
    UINT64 SourceDepthRegionLeft;
    UINT64 SourceDepthRegionBottom;
    UINT64 SourceDepthRegionRight;

    D3D12_GPU_DESCRIPTOR_HANDLE MotionVectorsDescriptor; // Single subresource Tex2D SRV
    UINT64 MotionVectorsRegionTop;
    UINT64 MotionVectorsRegionLeft;
    UINT64 MotionVectorsRegionBottom;
    UINT64 MotionVectorsRegionRight;
    
    float MotionVectorScaleHoriz;
    float MotionVectorScaleVert;
    float CameraJitterHoriz;
    float CameraJitterVert;
    float ExposureScale;
    float PreExposure;
    float Sharpness;
    float CameraNear;
    float CameraFar;
    float CameraFovAngleVert;

    // Optional parameters
    D3D12_GPU_DESCRIPTOR_HANDLE ExposureScaleDescriptor; // Single subresource Tex2D SRV

    D3D12_GPU_DESCRIPTOR_HANDLE IgnoreHistoryMaskDescriptor; // Single subresource Tex2D SRV
    UINT64 IgnoreHistoryMaskRegionTop;
    UINT64 IgnoreHistoryMaskRegionLeft;
    UINT64 IgnoreHistoryMaskRegionBottom;
    UINT64 IgnoreHistoryMaskRegionRight;

    D3D12_GPU_DESCRIPTOR_HANDLE ReactiveMaskDescriptor; // Single subresource Tex2D SRV
    UINT64 ReactiveMaskRegionTop;
    UINT64 ReactiveMaskRegionLeft;
    UINT64 ReactiveMaskRegionBottom;
    UINT64 ReactiveMaskRegionRight;

    // Internal resource parameters
    D3D12_CPU_DESCRIPTOR_HANDLE InternalBaseCPUDescriptorUAV;
    D3D12_GPU_DESCRIPTOR_HANDLE InternalBaseGPUDescriptorUAV;
    D3D12_GPU_DESCRIPTOR_HANDLE InternalBaseGPUDescriptorSRV;
    D3D12_GPU_VIRTUAL_ADDRESS InternalUploadHeapBufferVA;
    D3D12_GPU_VIRTUAL_ADDRESS InternalDefaultHeapBufferVA;
} DSR_SUPERRES_META_COMMAND_UPSCALER_EXECUTE_PARAMETERS;
```

### Metacommand parameter flags

Drivers must implement `ID3D12Device5::EnumerateMetaCommandParameters` for this structure. Name strings must match the parameter names from this spec. `TargetTextureDescriptor` resource must be in `D3D12_RESOURCE_STATE_UNORDERED_ACCESS`, and `D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE` for all other non-internal resources. All UAV descriptor metacommand parameters must enumerate with both `D3D12_META_COMMAND_PARAMETER_FLAG_INPUT` and `D3D12_META_COMMAND_PARAMETER_FLAG_OUTPUT` bit set, including the target and all internal UAV descriptors. All SRV descriptor parameters must enumerate with `D3D12_META_COMMAND_PARAMETER_FLAG_INPUT` set exclusively. All internal VA parameters must enumerate with both `D3D12_META_COMMAND_PARAMETER_FLAG_INPUT` and `D3D12_META_COMMAND_PARAMETER_FLAG_OUTPUT` flags set.

Internal resource states/barriers are managed by the driver during metacommand initialization and execution.

Regions with areas outside the physical extents of a texture are internally clamped to the texture bounds.

## SR Extension Functions

SR extensions are used for driving non-native SR on devices such as NPUs. As with native super resolution variant providers, A given SR extension can support multiple SR variants. SR extension variants are responsible for loading, initializing, and executing an SR extension engine.

### `DSR_EX_VERSION` enum

Enumerated DSR extension version values. DirectSR uses the highest version supported by a loaded extension.

``` C
typedef enum DSR_EX_VERSION
{
    DSR_EX_VERSION_0001 = 1,
} DSR_EX_VERSION;
```
### `DSRExSuperResEngineHandle` typedef

Represents a unique handle to an SR extension engine instance.

``` C
typedef void *DSRExSuperResEngineHandle;
```

### `DSRExSuperResUpscalerHandle` typedef

Represents a unique handle to an SR upscaler instance.

``` C
typedef void *DSRExSuperResUpscalerHandle;
```

### `DSRExGetVersionedFunctionTable` export

Fetches the function table entries for the given DSR Extension Version.

``` C
HRESULT DSRExGetVersionedFunctionTable(UINT Version, void *pFunctionTable, UINT TableSizeInBytes);
```

Returns `E_NOTIML` if the supplied version is not supported by the extension.

The table entries are determined using the `Version` parameter. Functions or function signatures may change as DSR extension designs evolve.

The DirectSR runtime calls this function for each DSR extension version it supports. Typically, DirectSR uses the table for the largest supported version number.

### `FNDSRExSuperResGetNumVariants` function

Returns the number of super resolution variants supported by the SR extension.

``` C
typedef UINT (WINAPI *FNDSRExSuperResGetNumVariants)(ID3D12Device *pDevice);
```

The extension should only count variants that are actually available on the current system. For example, if a variant-required NPU or compute device is not installed the variant should not be included in the count. Likewise, that variant must not be enumerated by `DSRExEnumSuperResolutionVariant`.

### `FNDSRExSuperResEnumVariant` function

Fills out a `DSR_SUPERRES_VARIANT_DESC` struct with information about a specific variant.

``` C
typedef HRESULT (WINAPI *FNDSRExSuperResEnumVariant)(
    UINT VariantIndex,
    ID3D12Device *pDevice,
    DSR_SUPERRES_VARIANT_DESC *pVariantDesc);
```

Returns `S_OK` on success, `DXGI_ERROR_NOT_FOUND` if Index is equal to or greater than the number of supported variants.

### `FNDSRExSuperResQuerySourceSettings` function

Queries the optimal and minimum source settings based on the desired target dimensions, execution mode and create flags.

``` C
HRESULT (WINAPI *FNDSRExSuperResQuerySourceSettings)(
    UINT VariantIndex,
    ID3D12Device *pDevice,
    const DSR_SIZE &TargetSize,
    DSR_OPTIMIZATION_TYPE OptimizationType,
    DSR_SUPERRES_CREATE_ENGINE_FLAGS CreateFlags,
    DSR_SUPERRES_SOURCE_SETTINGS *pSourceSettings);
```

If there is no optimal source size, then the output values of `pSourceSettings->OptimalSize.Width` and `pSourceSettings->OptimalSize.Height` must be set to zero.

The output values of `pSourceSettings->MinDynamicSize.Width` and `pSourceSettings->MinDynamic.Height` must be at least 1.

Maximum source size is assumed to be the same as `TargetSize`.

Returns `S_OK` on success.

### `FNDSRExSuperResCreateEngine` function

Creates a super resolution extension engine instance.

``` C++
HRESULT (WINAPI *FNDSRExSuperResCreateEngine)(
    UINT VariantIndex,
    ID3D12Device* pDevice,
    const struct DSR_SUPERRES_CREATE_ENGINE_PARAMETERS* pCreateParams,
    DSRExSuperResEngineHandle* pSREngineHandle);
```

On success, sets `*pSREngineHandle` with a handle to created engine and returns `S_OK`. Otherwise, returns failure code.

### `FNDSRExSuperResDestroyUpscaler` function

Destroys a super resolution extension engine instance.

``` C++
typedef HRESULT (WINAPI *FNDSRExSuperResDestroyUpscaler)(DSRExSuperResEngineHandle SREngineHandle);
```

Returns `E_INVALIDARG` if `SREngineHandle` is not a valid handle.

### `FNDSRExSuperResGetOptimalJitterPattern` function

Gets the optimal jitter pattern for the provided existing engine.

``` C++
typedef HRESULT (WINAPI *FNDSRExSuperResGetOptimalJitterPattern)(
    DSRExSuperResEngineHandle SREngineHandle,
    const DSR_SIZE &SourceSize,
    const DSR_SIZE &TargetSize,
    UINT *pPatternArraySize,
    DSR_FLOAT2 *pPattern);
```

### `FNDSRExSuperResExecuteUpscaler` function

Creates a SuperRes upscaler.

``` C++
typedef HRESULT (WINAPI *FNDSRExSuperResExecuteUpscaler)(
    DSRExSuperResEngineHandle EngineHandle,
    ID3D12CommandQueue *pCommandQueue,
    DSRExSuperResUpscalerHandle* pSRUpscalerHandle);
```

On success, sets `*pSRUpscalerHandle` with a handle to created upscaler and returns `S_OK`. Otherwise, returns failure code.

### `FNDSRExSuperResDestroyUpscaler` function

Destroys a super resolution extension upscaler intance.

``` C++
typedef HRESULT (WINAPI *FNDSRExSuperResDestroyUpscaler)(DSRExSuperResUpscalerHandle SRUpscaler);
```

Returns `E_INVALIDARG` if `SRUpscaler` is not a valid handle.

### `FNDSRExSuperResExecuteUpscaler` function

Executes a super resolution extension engine instance.

``` C++
typedef HRESULT (WINAPI *FNDSRExSuperResExecuteUpscaler)(
    DSRExSuperResUpscalerHandle SRUpscalerHandle,
    DSR_SUPERRES_UPSCALER_EXECUTE_PARAMETERS *pParams);
```

### `FNDSRExSuperResUpscalerEvict` function

Attempts to evict any graphics memory used by the upscaler.

``` C++
typedef HRESULT (WINAPI *FNDSRExSuperResUpscalerEvict)(
    DSRExSuperResEngineHandle SRUpscalerHandle);
```

upscaler graphics memory residency is reference-counted. The `FNDSRExSuperResUpscalerEvict` function is called during `IDSRSuperResUpscaler::Evict` only when an internal residency counter reaches zero.

If the extension is not using graphics memory or cannot support eviction on the back end then the extension is free to implement this as a no-op (do nothing and return `S_OK`).

### `FNDSRExSuperResUpscalerMakeResident` function

Restores graphics memory previously evicted using `FNDSRExSuperResUpscalerEvict`.

``` C++
typedef HRESULT (WINAPI *FNDSRExSuperResUpscalerMakeResident)(
    DSRExSuperResEngineHandle SRUpscalerHandle);
```

Upscaler graphics memory residency is reference-counted. The `FNDSRExSuperResUpscalerMakeResident` function is called during `IDSRSuperResUpscaler::MakeResident` only when an internal residency counter ticks up from zero to one.

### `DSR_EX_FUNCTION_TABLE_0001` struct

Version 0001 DSR extension function table.

``` C
typedef struct DSR_EX_FUNCTION_TABLE_0001
{
    FNDSRExSuperResGetNumVariants pfnDSRExSuperResGetNumVariants;
    FNDSRExSuperResEnumVariant pfnDSRExSuperResEnumVariant;
    FNDSRExSuperResQueryOptimalSourceSettings pfnDSRExSuperResQueryOptimalSourceSettings;
    FNDSRExSuperResCreateEngine pfnDSRExSuperResCreateEngine;
    FNDSRExSuperResDestroyEngine pfnDSRExSuperResDestroyEngine;
    FNDSRExSuperResCreateUpscaler pfnDSRExSuperResCreateUpscaler;
    FNDSRExSuperResDestroyUpscaler pfnDSRExSuperResDestroyUpscaler;
    FNDSRExSuperResGetOptimalJitterPattern pfnDSRExSuperResGetOptimalJitterPattern;
    FNDSRExSuperResExecuteUpscaler pfnDSRExSuperResExecuteUpscaler;
    FNDSRExSuperResUpscalerEvict pfnDSRExSuperResUpscalerEvict;
    FNDSRExSuperResUpscalerMakeResident pfnDSRExSuperResUpscalerMakeResident;
} DSR_EX_FUNCTION_TABLE_0001;
```

Filled in by calling `DSRExGetVersionedFunctionTable` with `Version` = `DSR_EX_VERSION_0001`.

---

## Debug Validation

If the debug layer is enabled on the D3D12Device, then DirectSR performs more detailed validation and DirectSR debug spew is generated.
