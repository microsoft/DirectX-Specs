# Async Commands

This spec proposes `ID3D12GraphicsCommandList` Copy, Resolve, and Clear methods with improved concurrency over functionally similar Copy, Resolve and Clear.

- [Introduction](#introduction)
- [Copy and Resolve Serialization](#copy-and-resolve-serialization)
- [Clear Serialization](#clear-serialization)
- [Interop with synchronous legacy commands](#interop-with-synchronous-legacy-commands)
- [API Design](#api-design)
  - [D3D12\_CLEAR\_DATA struct](#d3d12_clear_data-struct)
  - [CopyBufferRegions method](#copybufferregions-method)
  - [D3D12\_TEXTURE\_COPY\_DESC\_TYPE enum](#d3d12_texture_copy_desc_type-enum)
  - [D3D12\_TEXTURE\_COPY\_REGION struct](#d3d12_texture_copy_region-struct)
  - [D3D12\_TEXTURE\_TEXTURE\_COPY\_DESC struct](#d3d12_texture_texture_copy_desc-struct)
  - [D3D12\_BUFFER\_TEXTURE\_COPY\_DESC struct](#d3d12_buffer_texture_copy_desc-struct)
  - [D3D12\_TEXTURE\_COPY\_DESC struct](#d3d12_texture_copy_desc-struct)
  - [CopyTextureRegions](#copytextureregions)
  - [CopyResources](#copyresources)
  - [CopyTilesAsync](#copytilesasync)
  - [ResolveSubresourceRegionAsync](#resolvesubresourceregionasync)
  - [ResolveQueryDataAsync](#resolvequerydataasync)
  - [ClearBoundDepthStencilView](#clearbounddepthstencilview)
  - [ClearBoundRenderTargetViews](#clearboundrendertargetviews)
  - [D3D12\_CLEAR\_TEXTURE\_DESC struct](#d3d12_clear_texture_desc-struct)
  - [ClearTextureSubresources](#cleartexturesubresources)
  - [D3D12\_FILL\_BUFFER\_DESC struct](#d3d12_fill_buffer_desc-struct)
  - [FillBuffers method](#fillbuffers-method)
- [DDI Design](#ddi-design)
  - [D3D12DDI\_CLEAR\_FLAGS enum](#d3d12ddi_clear_flags-enum)
  - [D3D12DDI\_CLEAR\_DATA struct](#d3d12ddi_clear_data-struct)
  - [PFND3D12DDI\_COPY\_BUFFER\_REGIONS function](#pfnd3d12ddi_copy_buffer_regions-function)
  - [D3D12DDI\_TEXTURE\_COPY\_REGION struct](#d3d12ddi_texture_copy_region-struct)
  - [D3D12DDI\_TEXTURE\_COPY\_DESC struct](#d3d12ddi_texture_copy_desc-struct)
  - [PFND3D12DDI\_COPY\_TEXTURE\_REGIONS function](#pfnd3d12ddi_copy_texture_regions-function)
  - [PFND3D12DDI\_COPY\_RESOURCES function](#pfnd3d12ddi_copy_resources-function)
  - [PFND3D12DDI\_COPY\_TILES\_ASYNC function](#pfnd3d12ddi_copy_tiles_async-function)
  - [PFND3D12DDI\_RESOLVE\_SUBRESOURCE\_REGION\_ASYNC function](#pfnd3d12ddi_resolve_subresource_region_async-function)
  - [PFND3D12DDI\_RESOLVE\_QUERY\_DATA\_ASYNC function](#pfnd3d12ddi_resolve_query_data_async-function)
  - [PFND3D12DDI\_CLEAR\_BOUND\_DEPTH\_STENCIL\_VIEW function](#pfnd3d12ddi_clear_bound_depth_stencil_view-function)
  - [PFND3D12DDI\_CLEAR\_BOUND\_RENDER\_TARGET\_VIEWS function](#pfnd3d12ddi_clear_bound_render_target_views-function)
  - [D3D12DDI\_CLEAR\_TEXTURE\_DESC struct](#d3d12ddi_clear_texture_desc-struct)
  - [PFND3D12DDI\_CLEAR\_TEXTURE\_SUBRESOURCES function](#pfnd3d12ddi_clear_texture_subresources-function)
  - [D3D12DDI\_FILL\_BUFFER\_DESC struct](#d3d12ddi_fill_buffer_desc-struct)
  - [PFND3D12DDI\_FILL\_BUFFERS function](#pfnd3d12ddi_fill_buffers-function)

---

## Introduction

Sequential `Copy*`, `Clear*`, and `Resolve*` commands tend to execute in series because legacy `ResourceBarrier` cannot express synchronization between copies, clears or resolves. However, proper synchronization is possible using [enhanced barriers](D3D12EnhancedBarriers.md).

---

## Copy and Resolve Serialization

In the following example, Buffer C is written to by two overlapping `CopyBufferRegion` operations while Buffer D is independently written to with no obvious dependency on preceding work:

``` C++
    /*[1]*/ pCL->CopyBufferRegion(pBufferC, 0, pBufferA, 0, 16);
    /*[2]*/ pCL->CopyBufferRegion(pBufferD, 0, pBufferA, 16, 16);
    /*[3]*/ pCL->CopyBufferRegion(pBufferC, 8, pBufferB, 8, 8);
```

The final contents of Buffer C depend on the order of completion of [1] and [3]. However, there is no way to express a `STATE_COPY_DEST` -> `STATE_COPY_DEST` transition using legacy resource state barriers. Therefore, all three of these Copy operations must execute serially to guarantee deterministic results.

The following example uses `CopyBufferRegions` so that [1] and [2] can safely execute concurrently, while only [3] must wait until preceding Copy operations have completed.

``` C++
    ID3D12Resource *ppDestBufs12[] = { pBufferC, pBufferD };
    UINT64 DestOffsets12[] = { 0, 0 };
    ID3D12Resource *ppSourceBufs12[] = { pBufferA, pBufferA };
    UINT64 SourceOffsets12[] = { 0, 16 };
    UINT64 CopySizes12[] = { 16, 16 };

    // [1] and [2]
    pCL->CopyBufferRegions(
        2,
        ppDestBufs12,
        DestOffsets12,
        ppSourceBufs12,
        SourceOffsets12,
        CopySizes12);

    D3D12_BUFFER_BARRIER bb = {};
    bb.SyncBefore = D3D12_BARRIER_SYNC_COPY;
    bb.SyncAfter = D3D12_BARRIER_SYNC_COPY;
    bb.AccessBefore = D3D12_BARRIER_ACCESS_COPY_DEST;
    bb.AccessAfter = D3D12_BARRIER_ACCESS_COPY_DEST;
    bb.pResource = pBufferC;

    D3D12_BARRIER_GROUP bg;
    bg.Type = D3D12_BARRIER_TYPE_BUFFER;
    bg.NumBarriers = 1;
    bg.pBufferBarriers = &bb;
    pCL->Barrier(1, &bg);

    ID3D12Resource *ppDestBufs3[] = { pBufferC };
    UINT64 DestOffsets3[] = { 8 };
    ID3D12Resource *ppSourceBufs3[] = { pBufferB };
    UINT64 SourceOffsets3[] = { 8 };
    UINT64 CopySizes3[] = { 8 };

    /*[3]*/
    pCL->CopyBufferRegions(
        ppDestBufs3,
        DestOffsets3,
        ppSourceBufs3,
        SourceOffsets3,
        CopySizes3);
```

---

## Clear Serialization

Despite the fact that UAV barriers are capable of guarding against `ClearUnorderedAccessView[Uint|Float]` hazards, some drivers have historically implemented these as serialized operations. Consequently, many retail D3D12 applications also expect UAV clear operations to be serialized.

Separately, `ClearUnorderedAccessViewUint` and `ClearUnorderedAccessViewFloat` have complex initialization requirements, expecting a CPU descriptor handle from a CPU-visible descriptor heap, an identical GPU descriptor handle from a GPU-visible descriptor heap, and a `ID3D12Resource` pointer to the UAV resource. Originally, this was necessary to support diverse vendor-specific methods of clearing UAVs that is no longer the case for more recent GPUs.

---

## Interop with synchronous legacy commands

The legacy `Copy*`, `Clear*`, and `Resolve*` commands must not be assumed to be synchronous with `Copy*Async`, `Clear*`, or `Resolve*Async`.

---

## API Design

### D3D12_CLEAR_DATA struct

Used by the `ID3D12GraphicsCommandListNext` clear methods to provide explicit 4-component clear values.

``` C++
typedef struct D3D12_CLEAR_DATA
{
    union
    {
        FLOAT Floats[4];
        UINT Uints[4];
        INT Sints[4];
        BYTE Bytes[16];
    };
} D3D12_CLEAR_DATA;
```

**Members:**

`Floats`
Type: `FLOAT`
Values to clear floating point resource components. Conversion rules apply as specified in [D3D11 Floating Point Conversion](https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm#3.2.2%20Floating%20Point%20Conversion).

`Uints`
Type: `UINT`
Values to clear unsigned integer resource components. Clears resource UINT components with bit-precise values, copying the lower `ni` bits from each array element `i` to the corresponding channel, where `ni` is the number of bits in the `i`th channel of the resource Format (for example, `DXGI_FORMAT_R16G16_FLOAT` has 16 bits for 2 channels). This works on any resource with no format conversion.

`Sints`
Type: `INT`
Values to clear signed integer resource components. This is functionally identical to `Uints`, clearing resources with bit-precise values, except that the clear value is semantically expressed as an array of signed integers rather than unsigned integers.

`Bytes`
Array of 16 bytes used for clearing to raw values.

**Remarks:**

Floating point components are cleared per the [D3D Data Conversion Rules](https://learn.microsoft.com/en-us/windows/win32/direct3d10/d3d10-graphics-programming-guide-resources-data-conversion).

The interpretation of clear values depends on the associated `DXGI_FORMAT` of the resource being cleared. The following tables represent the component mapping to a given `D3D12_CLEAR_DATA` member and index.

**Color Formats:**

| DXGI_FORMAT                            | R           | G           | B           | A           |
|----------------------------------------|-------------|-------------|-------------|-------------|
| `DXGI_FORMAT_R32G32B32A32_FLOAT`       | `Floats[0]` | `Floats[1]` | `Floats[2]` | `Floats[3]` |
| `DXGI_FORMAT_R32G32B32A32_UINT`        | `Uints[0]`  | `Uints[1]`  | `Uints[2]`  | `Uints[3]`  |
| `DXGI_FORMAT_R32G32B32A32_SINT`        | `Sints[0]`  | `Sints[1]`  | `Sints[2]`  | `Sints[3]`  |
| `DXGI_FORMAT_R32G32B32_FLOAT`          | `Floats[0]` | `Floats[1]` | `Floats[2]` | N/A         |
| `DXGI_FORMAT_R32G32B32_UINT`           | `Uints[0]`  | `Uints[1]`  | `Uints[2]`  | N/A         |
| `DXGI_FORMAT_R32G32B32_SINT`           | `Sints[0]`  | `Sints[1]`  | `Sints[2]`  | N/A         |
| `DXGI_FORMAT_R16G16B16A16_FLOAT`       | `Floats[0]` | `Floats[1]` | `Floats[2]` | `Floats[3]` |
| `DXGI_FORMAT_R16G16B16A16_UNORM`       | `Floats[0]` | `Floats[1]` | `Floats[2]` | `Floats[3]` |
| `DXGI_FORMAT_R16G16B16A16_UINT`        | `Uints[0]`  | `Uints[1]`  | `Uints[2]`  | `Uints[3]`  |
| `DXGI_FORMAT_R16G16B16A16_SNORM`       | `Floats[0]` | `Floats[1]` | `Floats[2]` | `Floats[3]` |
| `DXGI_FORMAT_R16G16B16A16_SINT`        | `Sints[0]`  | `Sints[1]`  | `Sints[2]`  | `Sints[3]`  |
| `DXGI_FORMAT_R32G32_FLOAT`             | `Floats[0]` | `Floats[1]` | N/A         | N/A         |
| `DXGI_FORMAT_R32G32_UINT`              | `Uints[0]`  | `Uints[1]`  | N/A         | N/A         |
| `DXGI_FORMAT_R32G32_SINT`              | `Sints[0]`  | `Sints[1]`  | N/A         | N/A         |
| `DXGI_FORMAT_R32_FLOAT_X8X24_TYPELESS` | `Floats[0]` | N/A         | N/A         | N/A         |
| `DXGI_FORMAT_X32_TYPELESS_G8X24_UINT`  | N/A         | `Uints[1]`  | N/A         | N/A         |
| `DXGI_FORMAT_R10G10B10A2_UNORM`        | `Floats[0]` | `Floats[1]` | `Floats[2]` | `Floats[3]` |
| `DXGI_FORMAT_R10G10B10A2_UINT`         | `Uints[0]`  | `Uints[1]`  | `Uints[2]`  | `Uints[3]`  |
| `DXGI_FORMAT_R11G11B10_FLOAT`          | `Floats[0]` | `Floats[1]` | `Floats[2]` | N/A         |
| `DXGI_FORMAT_R8G8B8A8_UNORM`           | `Floats[0]` | `Floats[1]` | `Floats[2]` | `Floats[3]` |
| `DXGI_FORMAT_R8G8B8A8_UNORM_SRGB`      | `Floats[0]` | `Floats[1]` | `Floats[2]` | `Floats[3]` |
| `DXGI_FORMAT_R8G8B8A8_UINT`            | `Uints[0]`  | `Uints[1]`  | `Uints[2]`  | `Uints[3]`  |
| `DXGI_FORMAT_R8G8B8A8_SNORM`           | `Floats[0]` | `Floats[1]` | `Floats[2]` | `Floats[3]` |
| `DXGI_FORMAT_R8G8B8A8_SINT`            | `Sints[0]`  | `Sints[1]`  | `Sints[2]`  | `Sints[3]`  |
| `DXGI_FORMAT_R16G16_FLOAT`             | `Floats[0]` | `Floats[1]` | N/A         | N/A         |
| `DXGI_FORMAT_R16G16_UNORM`             | `Floats[0]` | `Floats[1]` | N/A         | N/A         |
| `DXGI_FORMAT_R16G16_UINT`              | `Uints[0]`  | `Uints[1]`  | N/A         | N/A         |
| `DXGI_FORMAT_R16G16_SNORM`             | `Floats[0]` | `Floats[1]` | N/A         | N/A         |
| `DXGI_FORMAT_R16G16_SINT`              | `Sints[0]`  | `Sints[1]`  | N/A         | N/A         |
| `DXGI_FORMAT_R32_FLOAT`                | `Floats[0]` | N/A         | N/A         | N/A         |
| `DXGI_FORMAT_R32_UINT`                 | `Uints[0]`  | N/A         | N/A         | N/A         |
| `DXGI_FORMAT_R32_SINT`                 | `Sints[0]`  | N/A         | N/A         | N/A         |
| `DXGI_FORMAT_R24_UNORM_X8_TYPELESS`    | `Floats[0]` | N/A         | N/A         | N/A         |
| `DXGI_FORMAT_X24_TYPELESS_G8_UINT`     | N/A         | `Uints[1]`  | N/A         | N/A         |
| `DXGI_FORMAT_R8G8_UNORM`               | `Floats[0]` | `Floats[1]` | N/A         | N/A         |
| `DXGI_FORMAT_R8G8_UINT`                | `Uints[0]`  | `Uints[1]`  | N/A         | N/A         |
| `DXGI_FORMAT_R8G8_SNORM`               | `Floats[0]` | `Floats[1]` | N/A         | N/A         |
| `DXGI_FORMAT_R8G8_SINT`                | `Sints[0]`  | `Sints[1]`  | N/A         | N/A         |
| `DXGI_FORMAT_R16_FLOAT`                | `Floats[0]` | N/A         | N/A         | N/A         |
| `DXGI_FORMAT_R16_UNORM`                | `Floats[0]` | N/A         | N/A         | N/A         |
| `DXGI_FORMAT_R16_UINT`                 | `Uints[0]`  | N/A         | N/A         | N/A         |
| `DXGI_FORMAT_R16_SNORM`                | `Floats[0]` | N/A         | N/A         | N/A         |
| `DXGI_FORMAT_R16_SINT`                 | `Sints[0]`  | N/A         | N/A         | N/A         |
| `DXGI_FORMAT_R8_UNORM`                 | `Floats[0]` | N/A         | N/A         | N/A         |
| `DXGI_FORMAT_R8_UINT`                  | `Uints[0]`  | N/A         | N/A         | N/A         |
| `DXGI_FORMAT_R8_SNORM`                 | `Floats[0]` | N/A         | N/A         | N/A         |
| `DXGI_FORMAT_R8_SINT`                  | `Sints[0]`  | N/A         | N/A         | N/A         |
| `DXGI_FORMAT_A8_UNORM`                 | N/A         | N/A         | N/A         | `Floats[3]` |
| `DXGI_FORMAT_R1_UNORM`                 | `Floats[0]` | N/A         | N/A         | N/A         |
| `DXGI_FORMAT_R9G9B9E5_SHAREDEXP`       | `Floats[0]` | `Floats[1]` | `Floats[2]` | N/A         |
| `DXGI_FORMAT_R8G8_B8G8_UNORM`          | `Floats[0]` | `Floats[1]` | `Floats[2]` | N/A         |
| `DXGI_FORMAT_G8R8_G8B8_UNORM`          | `Floats[0]` | `Floats[1]` | `Floats[2]` | N/A         |
| `DXGI_FORMAT_B5G6R5_UNORM`             | `Floats[0]` | `Floats[1]` | `Floats[2]` | N/A         |
| `DXGI_FORMAT_B5G5R5A1_UNORM`           | `Floats[0]` | `Floats[1]` | `Floats[2]` | `Floats[3]` |
| `DXGI_FORMAT_B8G8R8A8_UNORM`           | `Floats[0]` | `Floats[1]` | `Floats[2]` | `Floats[3]` |
| `DXGI_FORMAT_B8G8R8X8_UNORM`           | `Floats[0]` | `Floats[1]` | `Floats[2]` | N/A         |
| `DXGI_FORMAT_B8G8R8A8_UNORM_SRGB`      | `Floats[0]` | `Floats[1]` | `Floats[2]` | `Floats[3]` |
| `DXGI_FORMAT_B8G8R8X8_UNORM_SRGB`      | `Floats[0]` | `Floats[1]` | `Floats[2]` | N/A         |
| `DXGI_FORMAT_B4G4R4A4_UNORM`           | `Floats[0]` | `Floats[1]` | `Floats[2]` | `Floats[3]` |

Floating point values for `DXGI_FORMAT_R9G9B9E5_SHAREDEXP` must be converted per specified [FLOAT -> RGBE Conversion rules](https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm#19.3.2.2%20FLOAT%20-%3E%20RGBE%20Conversion).

Depth stencil formats use the same `D3D12_CLEAR_DATA` members and indices as the corresponding RGBA format in the same typeless families.

**Depth Stencil Formats:**

| DXGI_FORMAT                        | D           | S          |
|------------------------------------|-------------|------------|
| `DXGI_FORMAT_D32_FLOAT_S8X24_UINT` | `Floats[0]` | `Uints[1]` |
| `DXGI_FORMAT_D32_FLOAT`            | `Floats[0]` | N/A        |
| `DXGI_FORMAT_D24_UNORM_S8_UINT`    | `Floats[0]` | `Uints[1]` |
| `DXGI_FORMAT_D16_UNORM`            | `Floats[0]` | N/A        |

**YUV Video Formats:**

Since there is no color space provided in the texture clear, `D3D12_CLEAR_DATA` for all YUV formats must use the Uint values. This means the caller must handle conversion from float to normalized space, represented as raw Uint bits truncated to the size of the stored component.

Only a single `Y`, `U`, `V`, and `A` value are needed for clear operations since they are shared by all cleared pixels, regardless of interleaving.


| YUV DXGI_FORMATS   | Y          | U          | V          | A          |
|--------------------|------------|------------|------------|------------|
| `DXGI_FORMAT_AYUV` | `Uints[0]` | `Uints[1]` | `Uints[2]` | `Uints[3]` |
| `DXGI_FORMAT_Y410` | `Uints[0]` | `Uints[1]` | `Uints[2]` | `Uints[3]` |
| `DXGI_FORMAT_Y416` | `Uints[0]` | `Uints[1]` | `Uints[2]` | `Uints[3]` |
| `DXGI_FORMAT_NV12` | `Uints[0]` | `Uints[1]` | `Uints[2]` | N/A        |
| `DXGI_FORMAT_P010` | `Uints[0]` | `Uints[1]` | `Uints[2]` | N/A        |
| `DXGI_FORMAT_P016` | `Uints[0]` | `Uints[1]` | `Uints[2]` | N/A        |
| `DXGI_FORMAT_YUY2` | `Uints[0]` | `Uints[1]` | `Uints[2]` | N/A        |
| `DXGI_FORMAT_Y210` | `Uints[0]` | `Uints[1]` | `Uints[2]` | N/A        |
| `DXGI_FORMAT_Y216` | `Uints[0]` | `Uints[1]` | `Uints[2]` | N/A        |

**Block Compressed Formats:**

Clear operations for block-compressed texels (e.g., BC1–BC7) use the least significant `Bytes[16]` bytes truncated to the size of the block.

Formats such as palettized formats, video-decode-output-only and `DXGI_FORMAT_SAMPLER_FEEDBACK_MIN*` are not supported.

### CopyBufferRegions method

Copies a set of buffer regions from source buffers to destination buffers.

``` C++
void ID3D12GraphicsCommandListNext::CopyBufferRegions(
    [in] UINT NumRegions,
    [in] ID3D12Resource * const *ppDestBuffers,
    [in] const UINT64 *pDestOffsets,
    [in] ID3D12Resource * const *ppSourceBuffers,
    [in] const UINT64 *pSourceOffsets,
    [in] const UINT64 *pSizes
    );
```

**Parameters:**

`[in] NumRegions`  
Type: `UINT`  
The number of regions to copy.

`[in] ppDestBuffers`  
Type: `ID3D12Resource * const *`  
Pointer to an array of `NumRegions` destination `ID3D12Resource` pointers.

`[in] pDestOffsets`  
Type: `const UINT64 *`  
Pointer to an array of `NumRegions` byte offsets into the destination buffers.

`[in] ppSourceBuffers`  
Type: `ID3D12Resource * const *`  
Pointer to an array of `NumRegions` source `ID3D12Resource` pointers.

`[in] pSourceOffsets`  
Type: `const UINT64 *`  
Pointer to an array of `NumRegions` byte offsets into the source buffers.

`[in] pSizes`  
Type: `const UINT64 *`  
Pointer to an array of `NumRegions` sizes in bytes.

**Return Value:**

None

**Remarks:**

Unlike `ID3D12GraphicsCommandList::CopyBufferRegion`, synchronization with interdependent commands requires enhanced barriers using `D3D12_BARRIER_SYNC_COPY` and `D3D12_BARRIER_ACCESS_COPY_[SOURCE|DEST]` (or equivalent aggregate sync and access bits).

The order of individual region copies is not guaranteed. Therefore, overlapping destination regions result in non-deterministic data. The debug layer reports when destination regions overlap.

**Open Issues:**

- Can batched writes to the same destination buffer be supported at all, even if the regions do not overlap?
  - If it is at all possible that batch entries use separate caches, then out of order flushes could seemingly corrupt data that otherwise appears non-overlapping. However, it seems highly likely that most hardware would share caches for the batched destination buffers.
  - It would be ideal if hardware could support non-overlapping writes to the same subresource within a batch.

### D3D12_TEXTURE_COPY_DESC_TYPE enum

Describes a copy operation type used by [D3D12_TEXTURE_COPY_DESC](#d3d12_texture_copy_desc-struct).

``` C++
typedef enum D3D12_TEXTURE_COPY_DESC_TYPE
{
    D3D12_TEXTURE_COPY_DESC_TYPE_TEXTURE_TO_TEXTURE,
    D3D12_TEXTURE_COPY_DESC_TYPE_BUFFER_TO_TEXTURE,
    D3D12_TEXTURE_COPY_DESC_TYPE_TEXTURE_TO_BUFFER
} D3D12_TEXTURE_COPY_DESC_TYPE;
```

### D3D12_TEXTURE_COPY_REGION struct

Used in [D3D12_TEXTURE_COPY_DESC](#d3d12_texture_copy_desc-struct) to describe source/dest copy region.

``` C++
typedef struct D3D12_TEXTURE_COPY_REGION
{
    [in] UINT DestX;
    [in] UINT DestY;
    [in] UINT DestZ;
    [in] const D3D12_BOX *pSourceBox;
} D3D12_TEXTURE_COPY_REGION;
```

**Members:**

`DestX`
Type: `UINT`  
X coordinate of top-left-front corner of copy destination.

`DestY`  
Type: `UINT`  
Y coordinate of top-left-front corner of copy destination.

`DestZ`  
Type: `UINT`  
Z coordinate of top-left-front corner of copy destination.

`pSourceBox`  
Type: `const D3D12_BOX *`  
Pointer to `D3D12_BOX` representing the source region to copy. May be NULL to indicate the entire source subresource.

**Remarks:**

For block-compressed textures, `DestX` and `DestY` must be multiples of 4. The `pSourceBox` offsets (`left`, `top`) must be multiples of 4, and the region sizes (`right - left`, `bottom - top`) must either be multiples of 4 or equal to the logical width/height of the subresource.

### D3D12_TEXTURE_TEXTURE_COPY_DESC struct

Structure used by [D3D12_TEXTURE_COPY_DESC](#d3d12_texture_copy_desc-struct) to describe a copy operation between two texture subresources.

```C++
typedef struct D3D12_TEXTURE_TEXTURE_COPY_DESC
{
    [in] ID3D12Resource *pDest;
    [in] UINT DestSubresourceIndex;
    [in] ID3D12Resource *pSource;
    [in] UINT SourceSubresourceIndex;
} D3D12_TEXTURE_COPY_DESC;
```

**Members:**

`pDest`  
Type: `ID3D12Resource *`  
Pointer to the destination texture. Copy destination subresources must use one of the following layouts:

- `D3D12_BARRIER_LAYOUT_COPY_DEST`
- `D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_COPY_DEST`
- `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COPY_DEST`
- `D3D12_BARRIER_LAYOUT_COMMON`
- `D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_COMMON`
- `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COMMON`

`DestSubresourceIndex`  
Type: `UINT`  
Index of the destination subresource.

`pSource`  
Type: `ID3D12Resource *`  
Pointer to the source texture. Copy source subresources must use one of the following layouts:

- `D3D12_BARRIER_LAYOUT_COPY_SOURCE`
- `D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_COPY_SOURCE`
- `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COPY_SOURCE`
- `D3D12_BARRIER_LAYOUT_COMMON`
- `D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_COMMON`
- `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COMMON`
- `D3D12_BARRIER_LAYOUT_GENERIC_READ`
- `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_GENERIC_READ`
- `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_GENERIC_READ_COMPUTE_QUEUE_ACCESSIBLE`

`SourceSubresourceIndex`  
Type: `UINT`  
Index of the source subresource.

**Remarks:**

The order of individual region copies is not guaranteed, but are most likely performed in parallel. Therefore, overlapping regions result in non-deterministic data in the destination subresource. The debug layer reports when destination regions overlap.

Source regions may overlap to facilitate repeated copies to multiple, non-overlapping destination regions. Conveniently, the entire source subresource can be repeatedly copied to one or more, non-overlapping regions in the destination by setting `SourceRegions` to `NULL`.

**Open Issues:**

- Can batched writes to the same destination subresource be supported at all, even if the regions do not overlap?
  - If it is at all possible that batch entries use separate caches, then out of order flushes could seemingly corrupt data that otherwise appears non-overlapping. However, it seems highly likely that most hardware would share caches for the batched destination buffers.
  - It would be ideal if hardware could support non-overlapping writes to the same subresource within a batch.

### D3D12_BUFFER_TEXTURE_COPY_DESC struct

Structure used by [D3D12_TEXTURE_COPY_DESC](#d3d12_texture_copy_desc-struct) to describe a copy operation between a buffer and a texture.

``` C++
typedef struct D3D12_BUFFER_TEXTURE_COPY_DESC
{
    [in] ID3D12Resource *pBuffer;
    [in] ID3D12Resource *pTexture;
    [in] UINT SubresourceIndex;
    [in] D3D12_PLACED_SUBRESOURCE_FOOTPRINT PlacedFootprint;
} D3D12_BUFFER_TEXTURE_COPY_DESC;
```

**Members:**

`pBuffer`  
Type: `ID3D12Resource*`  
Buffer involved in the copy operation.

`pTexture`  
Type: `ID3D12Resource *`  
Pointer to the texture resource involved in the copy operation.

Destination subresources must use one of the following layouts:

- `D3D12_BARRIER_LAYOUT_COPY_DEST`
- `D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_COPY_DEST`
- `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COPY_DEST`
- `D3D12_BARRIER_LAYOUT_COMMON`
- `D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_COMMON`
- `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COMMON`

Source subresources must use one of the following layouts:

- `D3D12_BARRIER_LAYOUT_COPY_SOURCE`
- `D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_COPY_SOURCE`
- `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COPY_SOURCE`
- `D3D12_BARRIER_LAYOUT_COMMON`
- `D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_COMMON`
- `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COMMON`
- `D3D12_BARRIER_LAYOUT_GENERIC_READ`
- `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_GENERIC_READ`
- `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_GENERIC_READ_COMPUTE_QUEUE_ACCESSIBLE`

`SubresourceIndex`  
Type: `UINT`  
Index of the subresource used in the copy operation.

`PlacedFootprint`  
Type: `D3D12_PLACED_SUBRESOURCE_FOOTPRINT`  
Placed footprint for the data in the buffer resource.

**Remarks:**

The order of individual region copies is not guaranteed, but are most likely performed in parallel. Therefore, overlapping regions result in non-deterministic data in the destination. The debug layer reports when destination regions overlap.

Source regions may overlap to facilitate repeated copies to multiple, non-overlapping destination regions. Conveniently, an entire texture source subresource can be repeatedly copied to one or more, non-overlapping buffer locations by setting `SourceRegions` to `NULL`.

### D3D12_TEXTURE_COPY_DESC struct

Typed description of a batched texture copy operation used by [CopyTextureRegions](#copytextureregions)

``` C++
typedef struct D3D12_TEXTURE_COPY_DESC
{
    D3D12_TEXTURE_COPY_DESC_TYPE Type;
    UINT NumRegions;
    const D3D12_TEXTURE_COPY_REGION *pCopyRegions;
    union
    {
        D3D12_TEXTURE_TEXTURE_COPY_DESC TextureTextureCopy;
        D3D12_BUFFER_TEXTURE_COPY_DESC BufferTextureCopy;
    };

} D3D12_TEXTURE_COPY_DESC;
```

**Members:**

`Type`  
Type: `D3D12_TEXTURE_COPY_DESC_TYPE`  
Type of copy operation. See [D3D12_TEXTURE_COPY_DESC_TYPE](#d3d12_texture_copy_desc_type-enum)

`TextureTextureCopy`  
Type: `D3D12_TEXTURE_TEXTURE_COPY_DESC`  
Used when `Type` is `D3D12_TEXTURE_COPY_DESC_TYPE_TEXTURE_TO_TEXTURE`. Describes a region copy between two texture subresources.

`BufferTextureCopy`  
Type: `D3D12_BUFFER_TEXTURE_COPY_DESC`  
Used with `Type` is `D3D12_TEXTURE_COPY_DESC_TYPE_BUFFER_TO_TEXTURE` or `D3D12_TEXTURE_COPY_DESC_TYPE_TEXTURE_TO_BUFFER`. Describes a copy of a texture subresource region to or from a buffer.

### CopyTextureRegions

Performs a batched copy of texture regions.

``` C++
void ID3D12GraphicsCommandListNext::CopyTextureRegions(
    UINT NumCopyDescs,
    [in] const D3D12_TEXTURE_COPY_DESC* pCopyDescs
    );
```

**Parameters:**

`NumCopyDescs`  
Type: `UINT`  
Number of `D3D12_TEXTURE_COPY_DESC` elements pointed to by `pCopyDescs`.

`[in] pCopyDescs`  
Type: `const D3D12_TEXTURE_COPY_DESC*`  
Pointer to an array of `NumCopyDescs` `D3D12_TEXTURE_COPY_DESC` elements.

**Return Value:**

None

**Remarks:**

Similar to `ID3D12GraphicsCommandList::CopyTextureRegion` except with batched copy mechanics and without implied serialization. Synchronization with other Copy operations requires enhanced barriers using `D3D12_BARRIER_SYNC_COPY` and `D3D12_BARRIER_ACCESS_COPY_[SOURCE|DEST]` (or equivalent aggregate sync and access bits).

### CopyResources

Copies the entire contents of the source resource to the destination resource concurrently with other Copy operations.

``` C++
void ID3D12GraphicsCommandListNext::CopyResources(
    [in] UINT NumSourceDestPairs,
    [in] ID3D12Resource* const* ppDestResources,
    [in] ID3D12Resource* const* ppSourceResources
    );
```

**Parameters:**

`[in] NumSourceDestPairs`
Type: `UINT`
Number of resource pointers in `ppDestResources` and `ppSourceResources` arrays.

`[in] ppDestResources`  
Type: `ID3D12Resource* const*`  
A pointer to an array of `NumSourceDestPairs` destination `ID3D12Resource` pointers. All copy destination textures must be in one of the following layouts:

- `D3D12_BARRIER_LAYOUT_COPY_DEST`
- `D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_COPY_DEST`
- `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COPY_DEST`
- `D3D12_BARRIER_LAYOUT_COMMON`
- `D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_COMMON`
- `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COMMON`

`[in] ppSourceResources`  
Type: `ID3D12Resource* const*`  
A pointer to an array of `NumSourceDestPairs` source `ID3D12Resource` pointers. All copy source textures must be in one of the following layouts:

- `D3D12_BARRIER_LAYOUT_COPY_SOURCE`
- `D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_COPY_SOURCE`
- `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COPY_SOURCE`
- `D3D12_BARRIER_LAYOUT_COMMON`
- `D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_COMMON`
- `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COMMON`
- `D3D12_BARRIER_LAYOUT_GENERIC_READ`
- `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_GENERIC_READ`
- `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_GENERIC_READ_COMPUTE_QUEUE_ACCESSIBLE`

**Return Value:**

None

**Remarks:**

Similar to `ID3D12GraphicsCommandList::CopyResource` except with batched copy mechanics and without implied serialization with other Copy operations. Synchronization with other Copy operations requires enhanced barriers using `D3D12_BARRIER_SYNC_COPY` and `D3D12_BARRIER_ACCESS_COPY_[SOURCE|DEST]` (or equivalent aggregate sync and access bits).

### CopyTilesAsync

Copies tiles from buffer to tiled resource or vice versa asynchronously with other Copy operations.

``` C++
void ID3D12GraphicsCommandListNext::CopyTilesAsync(
    [in] ID3D12Resource* pTiledResource,
    [in] const D3D12_TILED_RESOURCE_COORDINATE* pTileRegionStartCoordinate,
    [in] const D3D12_TILE_REGION_SIZE* pTileRegionSize,
    [in] ID3D12Resource *pBuffer,
    [in] UINT64 BufferOffset,
    D3D12_TILE_COPY_FLAGS Flags
    );
```

**Parameters:**

`[in] pTiledResource`  
Type: `ID3D12Resource*`  
A pointer to a tiled resource.

`[in] pTileRegionStartCoordinate`  
Type: `const D3D12_TILED_RESOURCE_COORDINATE*`  
A pointer to a `D3D12_TILED_RESOURCE_COORDINATE` structure that describes the starting coordinates of the tiled resource.

`[in] pTileRegionSize`  
Type: `const D3D12_TILE_REGION_SIZE*`  
A pointer to a `D3D12_TILE_REGION_SIZE` structure that describes the size of the tiled region.

`[in] pBuffer`  
Type: `ID3D12Resource *`  
Default, dynamic, or staging buffer involved in the copy operation.

`[in] BufferOffset`  
Type: `UINT64`  
Offset in `pBuffer` to start the copy operation.

`Flags`  
Type: `D3D12_TILE_COPY_FLAGS`  
A combination of D3D12_TILE_COPY_FLAGS-typed values that are combined by using a bitwise OR operation and that identifies how to copy tiles.

**Return Value:**

None

**Remarks:**

Similar to `ID3D12GraphicsCommandList::CopyTiles` except with no implied serialization with other Copy operations. Synchronization with other Copy operations requires enhanced barriers using `D3D12_BARRIER_SYNC_COPY` and `D3D12_BARRIER_ACCESS_COPY_[SOURCE|DEST]` (or equivalent aggregate sync and access bits).

Note: `D3D12_TILE_COPY_FLAG_NO_HAZARD` is deprecated and has no effect on the behavior of `ID3D12GraphicsCommandListNext::CopyTilesAsync` or `ID3D12GraphicsCommandListNext::CopyTiles`.

### ResolveSubresourceRegionAsync

Copy a region of a multisampled or compressed resource into a non-multisampled or non-compressed resource asynchronously with other Resolve operations.

``` C++
void ResolveSubresourceRegionAsync(
    [in] ID3D12Resource* pDestResource,
    [in] UINT DestSubresource,
    [in] UINT DestX,
    [in] UINT DestY,
    [in] ID3D12Resource* pSourceResource,
    [in] UINT SourceSubresource,
    [in, optional] const D3D12_RECT* pSourceRect,
    [in] DXGI_FORMAT Format,
    [in] D3D12_RESOLVE_MODE ResolveMode
    );
```

**Parameters:**

`[in] pDestResource`  
Type: `ID3D12Resource*`  
Destination resource. Must be single-sampled unless its to be resolved from a compressed resource (D3D12_RESOLVE_MODE_DECOMPRESS); in this case it must have the same sample count as the compressed source.

`[in] DestSubresource`  
Type `UINT`  
A zero-based index that identifies the destination subresource. Use [D3D12CalcSubresource](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12calcsubresource) to calculate the subresource index if the parent resource is complex.

`[in] DestX`  
Type `UINT`  
The X coordinate of the left-most edge of the destination region. The width of the destination region is the same as the width of the source rect.

`[in] DestY`  
Type `UINT`  
The Y coordinate of the top-most edge of the destination region. The height of the destination region is the same as the height of the source rect.

`[in] pSourceResource`  
Type: `ID3D12Resource*`  
Source resource. Must be multisampled or compressed.

`[in] SourceSubresource`  
Type: `UINT`  
A zero-based index that identifies the source subresource.

`[in, optional] pSourceRect`  
Type: `const D3D12_RECT*`  
Specifies the rectangular region of the source resource to be resolved. Passing `NULL` for pSourceRect specifies that the entire subresource is to be resolved.

`[in] Format`  
Type: `DXGI_FORMAT`  
A DXGI_FORMAT that specifies how the source and destination resource formats are consolidated.

`[in] ResolveMode`  
Type: `D3D12_RESOLVE_MODE`  
Specifies the operation used to resolve the source samples.

When using the `D3D12_RESOLVE_MODE_DECOMPRESS` operation, the sample count can be larger than 1 as long as the source and destination have the same sample count, and source and destination may specify the same resource as long as the source rect aligns with the destination X and Y coordinates, in which case decompression occurs in place.

When using the `D3D12_RESOLVE_MODE_MIN`, `D3D12_RESOLVE_MODE_MAX`, or `D3D12_RESOLVE_MODE_AVERAGE` operation, the destination must have a sample count of 1.

`D3D12_RESOLVE_MODE_ENCODE_SAMPLER_FEEDBACK` and `D3D12_RESOLVE_MODE_DECODE_SAMPLER_FEEDBACK` are not supported by `ResolveSubresourceRegionAsync`.

**Return Value:**

None

**Remarks:**

Similar to `ID3D12GraphicsCommandList::ResolveSubresourceRegion` except with no implied serialization with other Resolve operations. Synchronization with other Resolve operations requires enhanced barriers using `D3D12_BARRIER_SYNC_RESOLVE` and `D3D12_BARRIER_ACCESS_RESOLVE_[SOURCE|DEST]` (or equivalent aggregate sync and access bits).

### ResolveQueryDataAsync

Extracts data from a query asynchronously with other Copy operations. ResolveQueryData works with all heap types (default, upload, and readback).

``` C++
void ID3D12GraphicsCommandListNext::ResolveQueryDataAsync(
    [in] ID3D12QueryHeap* pQueryHeap,
    [in] D3D12_QUERY_TYPE Type,
    [in] UINT StartIndex,
    [in] UINT NumQueries,
    [in] ID3D12Resource *pDestBuffer,
    [in] UINT64 DestOffset
    );
```

**Parameters:**

`[in] pQueryHeap`  
Type: `ID3D12QueryHeap*`  
Specifies the [ID3D12QueryHeap](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nn-d3d12-id3d12queryheap) containing the queries to resolve.

`[in] Type`  
Type: `D3D12_QUERY_TYPE`  
Specifies the type of query, one member of [D3D12_QUERY_TYPE](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_query_type).

`[in] StartIndex`  
Type: `UINT`  
Specifies an index of the first query to resolve.

`[in] NumQueries`  
Type: `UINT`  
Specifies the number of queries to resolve.

`[in] pDestBuffer`  
Type: `ID3D12Resource *`  
Pointer to the destination buffer.

`[in] DestOffset`  
Type: `UINT64`  
Offset to the start of resolve data in the destination buffer. Must be 8-byte aligned.

**Return Value:**

None

**Remarks:**

Similar to `ID3D12GraphicsCommandListNext::ResolveQueryData` except with no implied serialization with other Resolve operations. Synchronization with other Resolve operations requires enhanced barriers using `D3D12_BARRIER_SYNC_COPY` and `D3D12_BARRIER_ACCESS_COPY_[SOURCE|DEST]` (or equivalent aggregate sync and access bits).

### ClearBoundDepthStencilView

Clears the currently bound DSV subresource per the most recent [OMSetRenderTargets](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12graphicscommandlist-omsetrendertargets).

``` C++
void ID3D12GraphicsCommandListNext::ClearBoundDepthStencilView(
    [in] D3D12_CLEAR_FLAGS ClearFlags,
    [in] FLOAT Depth,
    [in] UINT8 Stencil,
    [in] UINT NumRegions,
    [in] const D3D12_BOX* pRegions
    );
```

**Parameters:**

`[in] ClearFlags`  
Type: `D3D12_CLEAR_FLAGS`  
A combination of [D3D12_CLEAR_FLAGS](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/ne-d3d12-d3d12_clear_flags) values that are combined by using a bitwise OR operation. The resulting value identifies the type of data to clear (depth buffer, stencil buffer, or both).

`[in] Depth`  
Type: `FLOAT`  
A value to clear the depth buffer with. This value will be clamped between 0 and 1.

`[in] Stencil`  
Type: `UINT8`  
A value to clear the stencil buffer with. This value is ignored if the format of view being cleared does not include stencil.

`[in] NumRegions`  
Type: `UINT`  
The number of box regions in the array that the `pRegions` parameter specifies.

`[in] pRegions`  
Type: `const D3D12_BOX*`  
An array of [D3D12_BOX](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_box) structures for the regions in the resource view to clear. The `front` and `back` members index the first and last array slices in the view respectively. If `NULL`, `ClearBoundDepthStencilView` clears the entire resource view.

**Return Value:**

None

**Remarks:**

`ClearBoundDepthStencilView` is functionally similar to `ID3D12GraphicsCommandList::ClearDepthStencilView` except that it requires the DSV to be currently bound to the pipeline by `OMSetRenderTargets`.

`ClearBoundDepthStencilView` supports clears in the middle of a render pass without requiring drivers to break up tiling or otherwise rearrange work to maintain ordering semantics. Additionally, using the currently bound DSV makes it more apparent that the clear is done as a graphics pipeline operation, in sequence with the output merger and `Draw*` operations.

`ClearBoundDepthStencilView` uses the currently bound DSV per the most recent `OMSetRenderTargets` instead of using DSV handle parameter.

Unlike `ClearDepthStencilView`, `ClearBoundDepthStencilView` can clear specific array slices to clear in an array DSV. The `pRegions->front` and `pRegions->back` members represent offsets from `FirstArraySlice` specified during DSV creation where `front` is the first array slice to clear and `back` is one-past the last array slice to clear. The d3d12 runtime clamps regions to the dimensions of the subresource.

`ClearBoundDepthStencilView` is considered a raster operation, similar to `DrawInstanced`, `DrawIndexedInstanced` and draw-type `ExecuteIndirect`. Therefore, target resources must use layout `D3D12_BARRIER_LAYOUT_DEPTH_STENCIL_WRITE` and dependent commands must synchronize with barriers using `D3D12_BARRIER_SYNC_DEPTH_STENCIL` and `D3D12_BARRIER_ACCESS_DEPTH_STENCIL_WRITE` (or equivalent aggregate sync and access bits).

Note that `ClearBoundDepthStencilView` follows the same raster-order rules as Draw commands, meaning that individual pixels are updated in the order in which raster commands are issued in the command buffer. This ensures that pixel writes by `ClearBoundDepthStencilView` are properly serialized with other `ClearBoundDepthStencilView` calls along with `Draw*` and draw-type `ExecuteIndirect` commands. This means that `ClearBoundDepthStencilView` can be combined sequentially with other raster commands barrier-free, the same way that sequential `Draw*` calls do not require barriers when updating the same render targets.

Developers must use enhanced barriers with `D3D12_TEXTURE_BARRIER_FLAG_DISCARD` to initialize depth metadata on aliased or tiled resource prior to writing to using `ClearBoundDepthStencilView`. Unlike `ClearDepthStencilView`, `ClearBoundDepthStencilView` cannot be used for tiled or placed resource initialization.

### ClearBoundRenderTargetViews

Clears currently bound RTV subresources per the most recent [OMSetRenderTargets](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12graphicscommandlist-omsetrendertargets).

``` C++
void ID3D12GraphicsCommandListNext::ClearBoundRenderTargetViews(
    [in] UINT RenderTargetMask,
    [in] const D3D12_CLEAR_DATA *pClearValues,
    [in opt] const UINT *pNumRegions,
    [in opt] const D3D12_BOX * const *ppRegions
    );
```

**Parameters:**

`[in] RenderTargetMask`  
Type: `UINT`  
Mask of render targets to clear. The render target index is implied by the bit position starting with the least-significant bit. For example: the RTV bound to slot 3 is selected by setting `(0x1 << 3)` in the `RenderTargetMask`. Only least-significant bits 0-7 may be set (i.e. Valid value range from 0x0 to 0xff).

`[in] pClearValues`  
Type: `const D3D12_CLEAR_DATA *`  
Pointer to an array of up to 8 `D3D12_CLEAR_DATA` values representing the values to clear corresponding RTV starting at `FirstRenderTargetIndex`. The clear color index in the array directly corresponds to the slot index of the bound render target being cleared. Only clear values in array indices corresponding with non-zero bits in `RenderTargetMask` are considered. The size of the array must be no less than the position of the most-significant non-zero bit in `RenderTargetMask`.

`[in] pNumRegions`  
Type: `const UINT *`  
Pointer to an array of up to 8 `UINT` values representing the number of regions pointed to in the corresponding location in the `pRegions` array. If not `NULL`, the size of the array must be no less than the position of the most-significant non-zero bit in `RenderTargetMask`. If `NULL`, then all RTVs are fully cleared to the corresponding clear values.

`[in] ppRegions`  
Type: `const D3D12_BOX * const*`  
An array of [D3D12_BOX](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_box) structures for the regions in the resource views to clear. The `front` and `back` members index the first and last array slices in the view respectively. If `pNumRegions` is `NULL`, then `ppRegions` must also be `NULL`. Otherwise, the size of the array must be no less than the position of the most-significant non-zero bit in `RenderTargetMask`. Any `NULL` entry in the `ppRegions` array indicates a full clear of the RTV corresponding to that array index.

**Return Value:**

None

**Remarks:**

The set of bound render targets to clear is indicated by the value of `RenderTargetMask`. Bits 0-7 correspond to render target slots 0-7.

| Bits               | 31-8                    | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
|--------------------|-------------------------|---|---|---|---|---|---|---|---|
| Render Target Slot | Not used. Must be zero. | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |

Example clearing render targets bound only to slot 0 and 2:

``` C++
    // Clearing render targets bound to slots 0 and 2
    D3D12_CLEAR_DATA values[3];  // Size must accommodate highest slot index + 1
    values[0].Floats = {0.0f, 0.0f, 0.0f, 1.0f};  // For slot 0
    // values[1] // unused (slot 1 not being cleared)
    values[2].Floats = {1.0f, 1.0f, 1.0f, 1.0f};  // For slot 2

    pCL->ClearBoundRenderTargetViews(
        0x5, // Bits 0 and 2 are set
        values,
        nullptr, // Clear full subresources
        nullptr // Clear full subresources
    );
```

`ClearBoundRenderTargetViews` is functionally similar to [ClearRenderTargetView](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12graphicscommandlist-clearrendertargetview) except that it requires the RTVs to be currently bound to the pipeline by `OMSetRenderTargets`.

`ClearBoundRenderTargetViews` uses the currently bound set of RTVs per the most recent [OMSetRenderTargets](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12graphicscommandlist-omsetrendertargets) instead of taking a descriptor handle, which supports clearing of multiple render targets in a single `ClearBoundRenderTargetViews`.

`ClearBoundRenderTargetViews` has several important advantages over `ClearRenderTargetView`:

- `ClearBoundRenderTargetViews` can be used in a render pass.
- Can be asynchronous with other command operations.
- Supports batch clearing multiple RTVs in a single command.
- No need for the driver to implicitly push/pop the current RTV bindings to implement the clear as a raster operation.

Unlike [ClearRenderTargetView](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12graphicscommandlist-clearrendertargetview),  `ClearBoundRenderTargetViews` can clear specific array slices in an array RTV. The `pRegions->front` and `pRegions->back` members represent offsets from `FirstArraySlice` specified during RTV creation where `front` is the first array slice to clear and `back` is one-past the last array slice to clear.

Also unlike `ClearRenderTargetView`, floating point clear values cannot be used to clear integer components. Instead, integer formats use the `Uints` and `Sints` members of `D3D12_CLEAR_DATA`.

`ClearBoundRenderTargetViews` is considered a raster operation, similar to `DrawInstanced`, `DrawIndexedInstanced` and draw-type `ExecuteIndirect`. Therefore, target resources must use layout `D3D12_BARRIER_LAYOUT_RENDER_TARGET` and dependent commands must synchronize with barriers using `D3D12_BARRIER_SYNC_RENDER_TARGET` and `D3D12_BARRIER_ACCESS_RENDER_TARGET` (or equivalent aggregate sync and access bits).

`ClearBoundRenderTargetViews` supports clears in the middle of a render pass without requiring drivers to break up tiling or otherwise rearrange work to maintain ordering semantics. Additionally, using the currently bound DSV makes it more apparent that the clear is done as a graphics pipeline operation, in sequence with the output merger and `Draw*` operations.

Note that `ClearBoundRenderTargetViews` follows the same raster-order rules as Draw commands, meaning that individual pixels are updated in the order in which raster commands are issued in the command buffer. This ensures that pixel writes by `ClearBoundRenderTargetViews` are properly serialized with other `ClearBoundRenderTargetViews` calls along with `Draw*` and draw-type `ExecuteIndirect` commands. This means that `ClearBoundRenderTargetViews` can be combined sequentially with other raster commands barrier-free, the same way that sequential `Draw*` calls do not require barriers when updating the same render targets.

Developers must use enhanced barriers with `D3D12_TEXTURE_BARRIER_FLAG_DISCARD` to initialize render target metadata on aliased or tiled resource prior to writing to using `ClearBoundRenderTargetViews`. Unlike `ClearRenderTargetView`, `ClearBoundRenderTargetViews` cannot be used for tiled or placed resource initialization.

### D3D12_CLEAR_TEXTURE_DESC struct

Used by [ClearTextureSubresources](#cleartexturesubresources) to clear

``` C++
typedef struct D3D12_CLEAR_TEXTURE_DESC
{
    [in] ID3D12Resource *pTexture;
    [in] UINT SubresourceIndex;
    [in] D3D12_CLEAR_DATA ClearValue;
    [in] DXGI_FORMAT Format;
    [in opt] const D3D12_BOX *pRegion;
} D3D12_CLEAR_TEXTURE_DESC;
```

**Members:**

`[in] pTexture`  
Type: `ID3D12Resource *`  
Pointer to the texture containing the subresource being cleared.

`[in] SubresourceIndex`  
Type: `UINT`  
Index of subresource to clear. May be `0xFFFFFFFF` to indicate all subresources.

`[in] ClearValue`  
Type: `const D3D12_CLEAR_DATA`  
Value to set in the cleared data. Interpretation of this data depends on the value of `Format`.

`[in] Format`  
Type: `DXGI_FORMAT`  
Format of the clear operation. If `Format` is set to `DXGI_FORMAT_UNKNOWN` then the format used to create the resource is assumed. Typeless formats are not supported.

`[in opt] pRegion`  
Type: `const D3D12_BOX*`  
Pointer to a `D3D12_BOX` describing the region to clear. May be `NULL` to clear full subresource. If non-`NULL` and `SubresourceIndex` is `0xFFFFFFFF`, then all texture subresources must have the same dimensions.

**Remarks:**

Individual planes of multi-planar resource formats like `DXGI_FORMAT_D24_UNORM_S8_UINT` and `DXGI_FORMAT_NV12` can be cleared in isolation by providing the subresource index of the plane to be cleared. All planes can be cleared simultaneously by assigning `0xFFFFFFFF` to `SubresourceIndex`.

Unlike `ClearBoundRenderTargetViews`, `D3D12_CLEAR_TEXTURE_DESC` cannot index across a range of array slices using `pRegion->front` and `pRegion->back`. The `D3D12_CLEAR_TEXTURE_DESC` is limited to referencing either a single subresource or ALL subresources.

When `SubresourceIndex` is `0xFFFFFFFF`, `pRegion` must be `NULL` unless all subresources have the exact same **logical** dimensions. For example, YUV formats with multiple planes with different physical widths or heights all share the same logical width and height. However, `pRegion` cannot be used when clearing multiple mip levels.

Block compressed formats, as well as some video formats, represent 2x2 or 4x4 pixel blocks per unit. The `pRegion->top`, `pRegion->bottom`, `pRegion->left` and `pRegion->right` values must be a multiple of the largest block dimension for all subresources being cleared, or equal to the logical dimension of the subresource. For block compressed, these must be a multiple of 4 or equal to the logical width/height of the subresource. For video formats, the alignment uses the plane with the largest subsampled block dimension. For example, fully clearing all planes of a YUY2 texture (`SubresourceIndex = 0xFFFFFFFF`, `Format = DXGI_FORMAT_YUY2`), the horizontal region alignment is 2 and the vertical region alignment is 1 because the UV plane represents 2x1 subsampled blocks.

| Format             | Horiz Alignment | Vert Alignment |
|--------------------|-----------------|----------------|
| `DXGI_FORMAT_AYUV` | 1               | 1              |
| `DXGI_FORMAT_Y410` | 1               | 1              |
| `DXGI_FORMAT_Y416` | 1               | 1              |
| `DXGI_FORMAT_NV12` | 2               | 2              |
| `DXGI_FORMAT_P010` | 2               | 2              |
| `DXGI_FORMAT_P016` | 2               | 2              |
| `DXGI_FORMAT_YUY2` | 2               | 1              |
| `DXGI_FORMAT_Y210` | 2               | 1              |
| `DXGI_FORMAT_Y216` | 2               | 1              |

### ClearTextureSubresources

Clears a set of texture subresource regions.

``` C++
void ID3D12GraphicsCommandListNext::ClearTextureSubresources(
    [in] UINT NumClearDescs,
    [in] const D3D12_CLEAR_TEXTURE_DESC *pClearDescs
    );
```

**Parameters:**

`[in] NumClearDescs`  
Type: `UINT`  
Number of `D3D12_CLEAR_TEXTURE_DESC` elements pointed to by `pClearDescs`.

`[in] pClearDescs`  
Type: `const D3D12_CLEAR_TEXTURE_DESC *`  
Pointer to an array of `NumClearDescs` [D3D12_CLEAR_TEXTURE_DESC](#d3d12_clear_texture_desc-struct) elements.

**Return Value:**

None

**Remarks:**

Texture subresources being cleared by `ClearTextureSubresources` must use one of the following layouts:

- `D3D12_BARRIER_LAYOUT_COMMON`
- `D3D12_BARRIER_LAYOUT_COPY_DEST`
- `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COMMON`
- `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COPY_DEST`
- `D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_COMMON`
- `D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_COPY_DEST`

Synchronization with `ClearTextureSubresources` requires `D3D12_BARRIER_SYNC_COPY` or equivalent aggregate sync bits. Likewise, access bits required for `ClearTextureSubresources` are `D3D12_BARRIER_ACCESS_COPY` or equivalent aggregate access bits.

If multiple layouts are represented in the `pClearDescs` array then related barriers must use a combination of access bits that match the set of all layouts when synchronizing with other operations in the same command buffer execution scope.

`ClearTextureSubresources` is not supported on copy queues.

Block compressed textures cannot be created with `D3D12_RESOURCE_FLAG_ALLOW_RENDER_TARGET` or `D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS`. This prevents usage of `ClearUnorderedAccessView[Uint|Float]` or `ClearRenderTargetView` to clear such texture subresources. Since `ClearTextureSubresources` does not require any particular ALLOW flags it can be used to clear textures of any format.

For block-compressed textures, clear region offsets must be multiples of 4, and sizes must either be multiples of 4 or equal to the logical width/height of the subresource.

### D3D12_FILL_BUFFER_DESC struct

``` C++
typedef struct D3D12_FILL_BUFFER_DESC
{
    [in] ID3D12Resource *pBuffer;
    [in] UINT64 Offset;
    [in] D3D12_CLEAR_DATA FillValue;
    [in] DXGI_FORMAT Format;
    [in] UINT RawPatternSizeInBytes;
    [in] UINT RepeatCount;
} D3D12_FILL_BUFFER_DESC;
```

**Members:**

`[in] pBuffer`  
Type: `ID3D12Resource *`  
Pointer to buffer memory to be filled.

`[in] Offset`  
Type: `UINT64`  
Offset to the start of the fill region.

`[in] FillValue`  
Type: `D3D12_CLEAR_DATA`  
Value to use for fill pattern. If `Format` is `DXGI_FORMAT_UNKNOWN`, the fill pattern is taken from the least significant `RawPatternSizeInBytes` bytes contained in `FillValue.Bytes`. Otherwise, the value is interpreted according to `Format`.

`[in] Format`  
Type: `DXGI_FORMAT`  
Specifies the format of the fill data. If `DXGI_FORMAT_UNKNOWN`, the fill uses the raw pattern contained in `FillValue.Bytes` as described above. Typeless formats are not supported.

`[in] RawPatternSizeInBytes`  
Type: `UINT`  
If `Format` is `DXGI_FORMAT_UNKNOWN`, specifies the size in bytes of the raw fill pattern contained in `FillValue.Bytes` (must be 1–16). Otherwise, must be zero.

`[in] RepeatCount`  
Type: `UINT`  
The number of times to contiguously repeat the fill pattern, starting at `Offset`. If a repetition would not fully fit within the buffer, it is omitted and the remaining buffer contents are left unchanged (i.e., the operation never writes a partial pattern at the end).

**Remarks:**

The fill pattern is repeated up to `RepeatCount` times, placed contiguously in the buffer starting at `Offset`.

When used with tiled buffers, `Format` must represent a texel size of 1, 2, 4, 8, or 16 bytes. This is consistent with existing tiled resource view creation constraints.

If `Format` is `DXGI_FORMAT_UNKNOWN` then `RawPatternSizeInBytes` must be 1, 2, 4, 8, 12, or 16 bytes. For tiled buffers, 12-byte patterns are not supported. Patterns larger than 16 bytes are not supported.

`Offset` must be aligned to the `RawPatternSizeInBytes` (if Format is `DXGI_FORMAT_UNKNOWN`) or to the size of the format (if a format is specified) according to the following table:

| Raw Pattern or Formatted Value Size | `Offset` alignment |
|-------------------------------------|--------------------|
| 1                                   | 1                  |
| 2                                   | 2                  |
| 4 or greater                        | 4                  |

### FillBuffers method

Fills buffer memory with repeating patterns.

``` C++
void ID3D12GraphicsCommandListNext::FillBuffers(
    [in] UINT NumFillDescs,
    [in] const D3D12_FILL_BUFFER_DESC *pFillDescs
    );
```

**Parameters:**

`[in] NumFillDescs`  
Type: `UINT`  
Number of `D3D12_FILL_BUFFER_DESC` elements pointed to by `pFillDescs`.

`[in] pFillDescs`  
Type: `const D3D12_FILL_BUFFER_DESC *`  
Pointer to an array of `NumFillDescs` `D3D12_FILL_BUFFER_DESC` elements.

**Return Value:**

None

**Remarks:**

Batch fills buffer memory ranges.

`FillBuffers` is treated as a Copy operation. Barriers using synchronization scope `D3D12_BARRIER_SYNC_COPY` and access bit `D3D12_BARRIER_ACCESS_COPY_DEST` are required to manage dependent accesses.

Although considered a copy operation, `FillBuffers` cannot be used on copy queues.

Overlapping buffer fill regions in a single `FillBuffers` operation can result in non-deterministic data. The debug layer may report overlapping regions.

---

## DDI Design

Used by [D3D12DDI_CLEAR_DATA](#d3d12ddi_clear_data-struct) to describe a 4-component value type.

### D3D12DDI_CLEAR_FLAGS enum

Correlates with the [D3D12_CLEAR_FLAGS](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_clear_flags) API. Used by [PFND3D12DDI_CLEAR_BOUND_DEPTH_STENCIL_VIEW](#pfnd3d12ddi_clear_bound_depth_stencil_view-function).

``` C++
typedef enum D3D12DDI_CLEAR_FLAGS
{
    D3D12DDI_CLEAR_FLAG_DEPTH = 0x1,
    D3D12DDI_CLEAR_FLAG_STENCIL = 0x2
};
```

### D3D12DDI_CLEAR_DATA struct

Correlates with [D3D12_CLEAR_DATA](#d3d12_clear_data-struct). Used by various resource clear DDIs.

``` C++
typedef struct D3D12DDI_CLEAR_DATA
{
    union
    {
        FLOAT Floats[4];
        UINT Uints[4];
        INT Sints[4];
        BYTE Bytes[16];
    };
} D3D12DDI_CLEAR_DATA;
```

**Members:**

`Floats`
Type: `FLOAT`
Values to clear floating point resource components. Conversion rules apply as specified in [D3D11 Floating Point Conversion](https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm#3.2.2%20Floating%20Point%20Conversion).

`Uints`
Type: `UINT`
Values to clear unsigned integer resource components. Clears resource UINT components with bit-precise values, copying the lower `ni` bits from each array element `i` to the corresponding channel, where `ni` is the number of bits in the `i`th channel of the resource Format (for example, `DXGI_FORMAT_R16G16_FLOAT` has 16 bits for 2 channels). This works on any resource with no format conversion.

`Sints`
Type: `INT`
Values to clear signed integer resource components. This is functionally identical to `Uints`, clearing resources with bit-precise values, except that the clear value is semantically expressed as an array of signed integers rather than unsigned integers.

`Bytes`
Array of 16 bytes used for clearing to raw values.

See [D3D12_CLEAR_DATA](#d3d12_clear_data-struct) for details about mapping clear values to various DXGI_FORMAT.

### PFND3D12DDI_COPY_BUFFER_REGIONS function

Copies a set of buffer regions from source buffers to destination buffers.

``` C++
typedef VOID ( APIENTRY* PFND3D12DDI_COPY_BUFFER_REGIONS )( 
    D3D12DDI_HCOMMANDLIST hDrvCommandList,
    UINT NumRegions,
    _In_reads_(NumRegions) D3D12DDI_HRESOURCE * const *phDestBuffers,
    _In_reads_(NumRegions) const UINT64 *pDestOffsets,
    _In_reads_(NumRegions) D3D12DDI_HRESOURCE * const *phSourceBuffers,
    _In_reads_(NumRegions) const UINT64 *pSourceOffsets,
    _In_reads_(NumRegions) const UINT64 *pSizes
    );
```

**Parameters:**

`hDrvCommandList`  
Type: `D3D12DDI_HCOMMANDLIST`  
Handle to the command list.

`NumRegions`  
Type: `UINT`  
The number of regions to copy.

`phDestBuffers`  
Type: `D3D12DDI_HRESOURCE * const *`  
Pointer to an array of `NumRegions` destination `D3D12DDI_HRESOURCE` handles.

`pDestOffsets`  
Type: `const UINT64 *`  
Pointer to an array of `NumRegions` byte offsets into the destination buffers.

`phSourceBuffers`  
Type: `D3D12DDI_HRESOURCE * const *`  
Pointer to an array of `NumRegions` source `D3D12DDI_HRESOURCE` handles.

`pSourceOffsets`  
Type: `const UINT64 *`  
Pointer to an array of `NumRegions` byte offsets into the source buffers.

`pSizes`  
Type: `const UINT64 *`  
Pointer to an array of `NumRegions` sizes in bytes.

**Return Value:**

None

**Remarks:**

Unlike legacy copy operations, synchronization with interdependent commands requires enhanced barriers using `D3D12DDI_BARRIER_SYNC_COPY` and `D3D12DDI_BARRIER_ACCESS_COPY_[SOURCE|DEST]` (or equivalent aggregate sync and access bits).

The order of individual region copies is not guaranteed. Therefore, overlapping destination regions result in non-deterministic data. The debug layer reports when destination regions overlap.

### D3D12DDI_TEXTURE_COPY_REGION struct

Defines a source/dest copy region.

``` C++
typedef struct D3D12DDI_TEXTURE_COPY_REGION
{
    UINT DstOffsetX;
    UINT DstOffsetY;
    UINT DstOffsetZ;
    CONST D3D12DDI_BOX* pSrcBox;
} D3D12DDI_TEXTURE_COPY_REGION;
```

**Members:**

`DstOffsetX`  
Type: `UINT`  
X coordinate of copy dest.

`DstOffsetY`  
Type: `UINT`  
Y coordinate of copy dest.

`DstOffsetZ`  
Type: `UINT`  
Z coordinate of copy dest.

`pSrcBox`  
Type: `CONST D3D12DDI_BOX*`  
Points to a `D3D12DDI_BOX`. May be NULL to indicate an entire subresource.

### D3D12DDI_TEXTURE_COPY_DESC struct

Typed description of a batched texture copy operation used by [PFND3D12DDI_COPY_TEXTURE_REGIONS](#pfnd3d12ddi_copy_texture_regions-function)

``` C++
typedef struct D3D12DDI_TEXTURE_COPY_DESC
{
    D3D12DDIARG_BUFFER_PLACEMENT DstBufferPlacement;
    D3D12DDIARG_PLACED_RESOURCE DstPlacedResource;
    D3D12DDIARG_BUFFER_PLACEMENT SrcBufferPlacement;
    D3D12DDIARG_PLACED_RESOURCE SrcPlacedResource;
    UINT NumRegions;
    const D3D12DDI_TEXTURE_COPY_REGION *pRegions;
} D3D12DDI_TEXTURE_COPY_DESC;
```

**Members:**

`DstBufferPlacement`  
Type: `D3D12DDIARG_BUFFER_PLACEMENT`  
Destination buffer placement.

`DstPlacedResource`  
Type: `D3D12DDIARG_PLACED_RESOURCE`  
Destination placed resource.

Texture destination subresources must use one of the following layouts:

- `D3D12DDI_BARRIER_LAYOUT_COPY_DEST`
- `D3D12DDI_BARRIER_LAYOUT_COMPUTE_QUEUE_COPY_DEST`
- `D3D12DDI_BARRIER_LAYOUT_DIRECT_QUEUE_COPY_DEST`
- `D3D12DDI_BARRIER_LAYOUT_COMMON`
- `D3D12DDI_BARRIER_LAYOUT_COMPUTE_QUEUE_COMMON`
- `D3D12DDI_BARRIER_LAYOUT_DIRECT_QUEUE_COMMON`

`SrcBufferPlacement`  
Type: `D3D12DDIARG_PLACED_RESOURCE`  
Source buffer placement.

`SrcPlacedResource`  
Type: `D3D12DDIARG_PLACED_RESOURCE`  
Source placed resource.

Texture source subresources must use one of the following layouts:

- `D3D12DDI_BARRIER_LAYOUT_COPY_SOURCE`
- `D3D12DDI_BARRIER_LAYOUT_COMPUTE_QUEUE_COPY_SOURCE`
- `D3D12DDI_BARRIER_LAYOUT_DIRECT_QUEUE_COPY_SOURCE`
- `D3D12DDI_BARRIER_LAYOUT_COMMON`
- `D3D12DDI_BARRIER_LAYOUT_COMPUTE_QUEUE_COMMON`
- `D3D12DDI_BARRIER_LAYOUT_DIRECT_QUEUE_COMMON`
- `D3D12DDI_BARRIER_LAYOUT_GENERIC_READ`
- `D3D12DDI_BARRIER_LAYOUT_DIRECT_QUEUE_GENERIC_READ`
- `D3D12DDI_BARRIER_LAYOUT_DIRECT_QUEUE_GENERIC_READ_COMPUTE_QUEUE_ACCESSIBLE`

`NumRegions`  
Type: `UINT`  
Number of regions to copy.

`pRegions`
Type: `const D3D12DDI_TEXTURE_COPY_REGION *`
Pointer to an array of `D3D12DDI_TEXTURE_COPY_REGION` structs that defined the source and dest locations.

### PFND3D12DDI_COPY_TEXTURE_REGIONS function

Performs a batched copy of texture regions.

``` C++
typedef VOID ( APIENTRY* PFND3D12DDI_COPY_TEXTURE_REGIONS )( 
    D3D12DDI_HCOMMANDLIST hDrvCommandList,
    UINT NumCopyDescs,
    _In_reads_(NumCopyDescs) const D3D12DDI_TEXTURE_COPY_DESC* pCopyDescs
    );
```

**Parameters:**

`hDrvCommandList`  
Type: `D3D12DDI_HCOMMANDLIST`  
Handle to the command list.

`NumCopyDescs`  
Type: `UINT`  
Number of `D3D12DDI_TEXTURE_COPY_DESC` elements pointed to by `pCopyDescs`.

`pCopyDescs`  
Type: `const D3D12DDI_TEXTURE_COPY_DESC*`  
Pointer to an array of `NumCopyDescs` `D3D12DDI_TEXTURE_COPY_DESC` elements.

**Return Value:**

None

**Remarks:**

Synchronization with other Copy operations requires enhanced barriers using `D3D12DDI_BARRIER_SYNC_COPY` and `D3D12DDI_BARRIER_ACCESS_COPY_[SOURCE|DEST]` (or equivalent aggregate sync and access bits).

### PFND3D12DDI_COPY_RESOURCES function

Copies the entire contents of the source resource to the destination resource concurrently with other Copy operations.

``` C++
typedef VOID ( APIENTRY* PFND3D12DDI_COPY_RESOURCES )( 
    D3D12DDI_HCOMMANDLIST hDrvCommandList,
    UINT NumSourceDestPairs,
    _In_reads_(NumSourceDestPairs) D3D12DDI_HRESOURCE* phDestResources,
    _In_reads_(NumSourceDestPairs) D3D12DDI_HRESOURCE* phSourceResources
    );
```

**Parameters:**

`hDrvCommandList`  
Type: `D3D12DDI_HCOMMANDLIST`  
Handle to the command list.

`NumSourceDestPairs`
Type: `UINT`
Number of resource pointers in `phDestResources` and `phSourceResources` arrays.

`phDestResources`  
Type: `D3D12DDI_HRESOURCE*`  
A pointer to an array of `NumSourceDestPairs` destination `D3D12DDI_HRESOURCE` handles. All copy destination textures must be in one of the following layouts:

- `D3D12DDI_BARRIER_LAYOUT_COPY_DEST`
- `D3D12DDI_BARRIER_LAYOUT_COMPUTE_QUEUE_COPY_DEST`
- `D3D12DDI_BARRIER_LAYOUT_DIRECT_QUEUE_COPY_DEST`
- `D3D12DDI_BARRIER_LAYOUT_COMMON`
- `D3D12DDI_BARRIER_LAYOUT_COMPUTE_QUEUE_COMMON`
- `D3D12DDI_BARRIER_LAYOUT_DIRECT_QUEUE_COMMON`

`phSourceResources`  
Type: `D3D12DDI_HRESOURCE*`  
A pointer to an array of `NumSourceDestPairs` source `D3D12DDI_HRESOURCE` handles. All copy source textures must be in one of the following layouts:

- `D3D12DDI_BARRIER_LAYOUT_COPY_SOURCE`
- `D3D12DDI_BARRIER_LAYOUT_COMPUTE_QUEUE_COPY_SOURCE`
- `D3D12DDI_BARRIER_LAYOUT_DIRECT_QUEUE_COPY_SOURCE`
- `D3D12DDI_BARRIER_LAYOUT_COMMON`
- `D3D12DDI_BARRIER_LAYOUT_COMPUTE_QUEUE_COMMON`
- `D3D12DDI_BARRIER_LAYOUT_DIRECT_QUEUE_COMMON`
- `D3D12DDI_BARRIER_LAYOUT_GENERIC_READ`
- `D3D12DDI_BARRIER_LAYOUT_DIRECT_QUEUE_GENERIC_READ`
- `D3D12DDI_BARRIER_LAYOUT_DIRECT_QUEUE_GENERIC_READ_COMPUTE_QUEUE_ACCESSIBLE`

**Return Value:**

None

**Remarks:**

Synchronization with other Copy operations requires enhanced barriers using `D3D12DDI_BARRIER_SYNC_COPY` and `D3D12DDI_BARRIER_ACCESS_COPY_[SOURCE|DEST]` (or equivalent aggregate sync and access bits).

### PFND3D12DDI_COPY_TILES_ASYNC function

Copies tiles from buffer to tiled resource or vice versa asynchronously with other Copy operations.

``` C++
typedef VOID ( APIENTRY* PFND3D12DDI_COPY_TILES_ASYNC )( 
    D3D12DDI_HCOMMANDLIST hDrvCommandList,
    D3D12DDI_HRESOURCE hTiledResource,
    const D3D12DDI_TILED_RESOURCE_COORDINATE* pTileRegionStartCoordinate,
    const D3D12DDI_TILE_REGION_SIZE* pTileRegionSize,
    D3D12DDI_HRESOURCE hBuffer,
    UINT64 BufferOffset,
    D3D12DDI_TILE_COPY_FLAGS Flags
    );
```

**Parameters:**

`hDrvCommandList`  
Type: `D3D12DDI_HCOMMANDLIST`  
Handle to the command list.

`hTiledResource`  
Type: `D3D12DDI_HRESOURCE`  
Handle to the tiled resource.

`pTileRegionStartCoordinate`  
Type: `const D3D12DDI_TILED_RESOURCE_COORDINATE*`  
A pointer to a `D3D12DDI_TILED_RESOURCE_COORDINATE` structure that describes the starting coordinates of the tiled resource.

`pTileRegionSize`  
Type: `const D3D12DDI_TILE_REGION_SIZE*`  
A pointer to a `D3D12DDI_TILE_REGION_SIZE` structure that describes the size of the tiled region.

`hBuffer`  
Type: `D3D12DDI_HRESOURCE`  
Default, dynamic, or staging buffer involved in the copy operation.

`BufferOffset`  
Type: `UINT64`  
Offset in `hBuffer` to start the copy operation.

`Flags`  
Type: `D3D12DDI_TILE_COPY_FLAGS`  
A combination of D3D12DDI_TILE_COPY_FLAGS-typed values that are combined by using a bitwise OR operation and that identifies how to copy tiles.

**Return Value:**

None

**Remarks:**

Synchronization with other Copy operations requires enhanced barriers using `D3D12DDI_BARRIER_SYNC_COPY` and `D3D12DDI_BARRIER_ACCESS_COPY_[SOURCE|DEST]` (or equivalent aggregate sync and access bits).

### PFND3D12DDI_RESOLVE_SUBRESOURCE_REGION_ASYNC function

Copy a region of a multisampled or compressed resource into a non-multisampled or non-compressed resource asynchronously with other Resolve operations.

``` C++
typedef VOID ( APIENTRY* PFND3D12DDI_RESOLVE_SUBRESOURCE_REGION_ASYNC )( 
    D3D12DDI_HCOMMANDLIST hDrvCommandList,
    D3D12DDI_HRESOURCE hDestResource,
    UINT DestSubresource,
    UINT DestX,
    UINT DestY,
    D3D12DDI_HRESOURCE hSourceResource,
    UINT SourceSubresource,
    const D3D12DDI_RECT* pSourceRect,
    DXGI_FORMAT Format,
    D3D12DDI_RESOLVE_MODE ResolveMode
    );
```

**Parameters:**

`hDrvCommandList`  
Type: `D3D12DDI_HCOMMANDLIST`  
Handle to the command list.

`hDestResource`  
Type: `D3D12DDI_HRESOURCE`  
Destination resource. Must be single-sampled unless its to be resolved from a compressed resource (`D3D12DDI_RESOLVE_MODE_DECOMPRESS`); in this case it must have the same sample count as the compressed source.

`DestSubresource`  
Type `UINT`  
A zero-based index that identifies the destination subresource. Use [D3D12CalcSubresource](https://learn.microsoft.com/en-us/windows/desktop/direct3d12/d3d12calcsubresource) to calculate the subresource index if the parent resource is complex.

`DestX`  
Type `UINT`  
The X coordinate of the left-most edge of the destination region. The width of the destination region is the same as the width of the source rect.

`DestY`  
Type `UINT`  
The Y coordinate of the top-most edge of the destination region. The height of the destination region is the same as the height of the source rect.

`hSourceResource`  
Type: `D3D12DDI_HRESOURCE`  
Handle to the source resource. Must be multisampled or compressed.

`SourceSubresource`  
Type: `UINT`  
A zero-based index that identifies the source subresource.

`pSourceRect`  
Type: `const D3D12DDI_RECT*`  
Specifies the rectangular region of the source resource to be resolved. Passing `NULL` for pSourceRect specifies that the entire subresource is to be resolved.

`Format`  
Type: `DXGI_FORMAT`  
A DXGI_FORMAT that specifies how the source and destination resource formats are consolidated.

`ResolveMode`  
Type: `D3D12DDI_RESOLVE_MODE`  
Specifies the operation used to resolve the source samples.

When using the `D3D12DDI_RESOLVE_MODE_DECOMPRESS` operation, the sample count can be larger than 1 as long as the source and destination have the same sample count, and source and destination may specify the same resource as long as the source rect aligns with the destination X and Y coordinates, in which case decompression occurs in place.

When using the `D3D12DDI_RESOLVE_MODE_MIN`, `D3D12DDI_RESOLVE_MODE_MAX`, or `D3D12DDI_RESOLVE_MODE_AVERAGE` operation, the destination must have a sample count of 1.

`D3D12DDI_RESOLVE_MODE_ENCODE_SAMPLER_FEEDBACK` and `D3D12DDI_RESOLVE_MODE_DECODE_SAMPLER_FEEDBACK` are not supported by `PFND3D12DDI_RESOLVE_SUBRESOURCE_REGION_ASYNC`.

**Return Value:**

None

**Remarks:**

Synchronization with other Resolve operations requires enhanced barriers using `D3D12DDI_BARRIER_SYNC_RESOLVE` and `D3D12DDI_BARRIER_ACCESS_RESOLVE_[SOURCE|DEST]` (or equivalent aggregate sync and access bits).

### PFND3D12DDI_RESOLVE_QUERY_DATA_ASYNC function

Extracts data from a query asynchronously with other Copy operations. ResolveQueryData works with all heap types (default, upload, and readback).

``` C++
typedef VOID ( APIENTRY* PFND3D12DDI_RESOLVE_QUERY_DATA_ASYNC )( 
    D3D12DDI_HCOMMANDLIST hDrvCommandList,
    D3D12DDI_HQUERYHEAP hQueryHeap,
    D3D12DDI_QUERY_TYPE Type,
    UINT StartIndex,
    UINT NumQueries,
    D3D12DDI_HRESOURCE hDestBuffer,
    UINT64 DestOffset
    );
```

**Parameters:**

`hDrvCommandList`  
Type: `D3D12DDI_HCOMMANDLIST`  
Handle to the command list.

`hQueryHeap`  
Type: `D3D12DDI_HQUERYHEAP`  
Specifies the query heap containing the queries to resolve.

`Type`  
Type: `D3D12DDI_QUERY_TYPE`  
Specifies the type of query.

`StartIndex`  
Type: `UINT`  
Specifies an index of the first query to resolve.

`NumQueries`  
Type: `UINT`  
Specifies the number of queries to resolve.

`hDestBuffer`  
Type: `D3D12DDI_HRESOURCE`  
Handle to the destination buffer.

`DestOffset`  
Type: `UINT64`  
Offset to the start of resolve data in the destination buffer. Must be 8-byte aligned.

**Return Value:**

None

**Remarks:**

Synchronization with other Resolve operations requires enhanced barriers using `D3D12DDI_BARRIER_SYNC_COPY` and `D3D12DDI_BARRIER_ACCESS_COPY_[SOURCE|DEST]` (or equivalent aggregate sync and access bits).

### PFND3D12DDI_CLEAR_BOUND_DEPTH_STENCIL_VIEW function

Clears the currently bound DSV subresource per the most recent `PFND3D12DDI_OM_SET_RENDER_TARGETS_0003`.

``` C++
typedef VOID ( APIENTRY* PFND3D12DDI_CLEAR_BOUND_DEPTH_STENCIL_VIEW )( 
    D3D12DDI_HCOMMANDLIST hDrvCommandList,
    D3D12DDI_CLEAR_FLAGS ClearFlags,
    FLOAT Depth,
    UINT8 Stencil,
    UINT NumRegions,
    const D3D12DDI_BOX* pRegions
    );
```

**Parameters:**

`hDrvCommandList`  
Type: `D3D12DDI_HCOMMANDLIST`  
Handle to the command list.

`ClearFlags`  
Type: `D3D12DDI_CLEAR_FLAGS`  
A combination of [D3D12DDI_CLEAR_FLAGS](#d3d12ddi_clear_flags-enum) values that are combined by using a bitwise OR operation. The resulting value identifies the type of data to clear (depth buffer, stencil buffer, or both).

`Depth`  
Type: `FLOAT`  
A value to clear the depth buffer with. This value will be clamped between 0 and 1.

`Stencil`  
Type: `UINT8`  
A value to clear the stencil buffer with. This value is ignored if the format of view being cleared does not include stencil.

`NumRegions`  
Type: `UINT`  
The number of box regions in the array that the `pRegions` parameter specifies.

`pRegions`  
Type: `const D3D12DDI_BOX*`  
An array of `D3D12DDI_BOX` structures for the regions in the resource view to clear. The `front` and `back` members index the first and last array slices in the view respectively. If `NULL`, `PFND3D12DDI_CLEAR_BOUND_DEPTH_STENCIL_VIEW` clears the entire resource view.

**Return Value:**

None

**Remarks:**

`PFND3D12DDI_CLEAR_BOUND_DEPTH_STENCIL_VIEW` is functionally similar to `PFND3D12DDI_CLEAR_DEPTH_STENCIL_VIEW_0003` except that it requires the DSV to be currently bound to the pipeline by `PFND3D12DDI_OM_SET_RENDER_TARGETS_0003`.

`PFND3D12DDI_CLEAR_BOUND_DEPTH_STENCIL_VIEW` supports clears in the middle of a render pass without requiring drivers to break up tiling or otherwise rearrange work to maintain ordering semantics. Additionally, using the currently bound DSV makes it more apparent that the clear is done as a graphics pipeline operation, in sequence with the output merger and `PFND3D12DDI_DRAW_*` operations.

`PFND3D12DDI_CLEAR_BOUND_DEPTH_STENCIL_VIEW` uses the currently bound DSV per the most recent `PFND3D12DDI_OM_SET_RENDER_TARGETS_0003` instead of using DSV handle parameter.

Unlike `PFND3D12DDI_CLEAR_DEPTH_STENCIL_VIEW_0003`, `PFND3D12DDI_CLEAR_BOUND_DEPTH_STENCIL_VIEW` can clear specific array slices to clear in an array DSV. The `pRegions->front` and `pRegions->back` members represent offsets from `FirstArraySlice` specified during DSV creation where `front` is the first array slice to clear and `back` is one-past the last array slice to clear. The driver clamps regions to the dimensions of the subresource.

`PFND3D12DDI_CLEAR_BOUND_DEPTH_STENCIL_VIEW` is considered a raster operation, similar to `PFND3D12DDI_DRAW_INSTANCED`, `PFND3D12DDI_DRAW_INDEXED_INSTANCED` and draw-type `PFND3D12DDI_EXECUTE_INDIRECT`. Therefore, target resources must use layout `D3D12DDI_BARRIER_LAYOUT_DEPTH_STENCIL_WRITE` and dependent commands must synchronize with barriers using `D3D12DDI_BARRIER_SYNC_DEPTH_STENCIL` and `D3D12DDI_BARRIER_ACCESS_DEPTH_STENCIL_WRITE` (or equivalent aggregate sync and access bits).

Note that `PFND3D12DDI_CLEAR_BOUND_DEPTH_STENCIL_VIEW` follows the same raster-order rules as Draw commands, meaning that individual pixels are updated in the order in which raster commands are issued in the command buffer. This ensures that pixel writes by `PFND3D12DDI_CLEAR_BOUND_DEPTH_STENCIL_VIEW` are properly serialized with other `PFND3D12DDI_CLEAR_BOUND_DEPTH_STENCIL_VIEW` calls along with `PFND3D12DDI_DRAW_*` and draw-type `PFND3D12DDI_EXECUTE_INDIRECT` commands. This means that `PFND3D12DDI_CLEAR_BOUND_DEPTH_STENCIL_VIEW` can be combined sequentially with other raster commands barrier-free, the same way that sequential `PFND3D12DDI_DRAW_*` calls do not require barriers when updating the same render targets.

### PFND3D12DDI_CLEAR_BOUND_RENDER_TARGET_VIEWS function

Clears currently bound RTV subresources per the most recent `PFND3D12DDI_OM_SET_RENDER_TARGETS_0003`.

``` C++
typedef VOID ( APIENTRY* PFND3D12DDI_CLEAR_BOUND_RENDER_TARGET_VIEWS )( 
    D3D12DDI_HCOMMANDLIST hDrvCommandList,
    UINT RenderTargetMask,
    const D3D12DDI_CLEAR_DATA *pClearValues,
    const UINT *pNumRegions,
    const D3D12DDI_BOX **ppRegions
    );
```

**Parameters:**

`hDrvCommandList`  
Type: `D3D12DDI_HCOMMANDLIST`  
Handle to the command list.

`RenderTargetMask`  
Type: `UINT`  
Mask of render targets to clear. The render target index is implied by the bit position starting with the least-significant bit. For example: the RTV bound to slot 3 is selected by setting `(0x1 << 3)` in the `RenderTargetMask`.

`pClearValues`  
Type: `const D3D12DDI_CLEAR_DATA *`  
Pointer to an array of up to 8 `D3D12DDI_CLEAR_DATA` values representing the values to clear corresponding RTV starting at `FirstRenderTargetIndex`. Only clear values in array indices corresponding to non-zero bits in `RenderTargetMask` are considered. The size of the array must be no less than the position of the most-significant non-zero bit in `RenderTargetMask`.

`pNumRegions`  
Type: `const UINT *`  
Pointer to an array of up to 8 `UINT` values representing the number of regions pointed to in the corresponding location in the `pRegions` array. If not `NULL`, the size of the array must be no less than the position of the most-significant non-zero bit in `RenderTargetMask`. If `NULL`, then all RTVs are fully cleared to the corresponding clear values.

`ppRegions`  
Type: `const D3D12DDI_BOX **`  
An array of `D3D12DDI_BOX` pointers to the regions in the resource views to clear. The `front` and `back` members index the first and last array slices in the view respectively. If `pNumRegions` is `NULL`, then `ppRegions` must also be `NULL`. Otherwise, the size of the array must be no less than the position of the most-significant non-zero bit in `RenderTargetMask`. Any `NULL` entry in the `ppRegions` array indicates a full clear of the RTV corresponding to that array index.

**Return Value:**

None

**Remarks:**

`PFND3D12DDI_CLEAR_BOUND_RENDER_TARGET_VIEWS` uses the currently bound set of RTVs per the most recent `PFND3D12DDI_OM_SET_RENDER_TARGETS_0003` instead of taking a descriptor handle, which supports clearing of multiple render targets in a single operation.

`PFND3D12DDI_CLEAR_BOUND_RENDER_TARGET_VIEWS` can be used to clear specific array slices in an array RTV. The `pRegions->front` and `pRegions->back` members represent offsets from `FirstArraySlice` specified during RTV creation where `front` is the first array slice to clear and `back` is one-past the last array slice to clear.

`PFND3D12DDI_CLEAR_BOUND_RENDER_TARGET_VIEWS` must adhere to the same raster ordering as `Draw*` calls. This means that pixels writes by `PFND3D12DDI_CLEAR_BOUND_RENDER_TARGET_VIEWS` are serialized with other `PFND3D12DDI_CLEAR_BOUND_RENDER_TARGET_VIEWS` and with `Draw*` commands. Synchronization with other commands requires enhanced barriers using `D3D12DDI_BARRIER_SYNC_RENDER_TARGET` and `D3D12DDI_BARRIER_ACCESS_RENDER_TARGET_[READ|WRITE]` (or equivalent aggregate sync and access bits).

`PFND3D12DDI_CLEAR_BOUND_RENDER_TARGET_VIEWS` supports clears in the middle of a render pass without requiring drivers to break up tiling or otherwise rearrange work to maintain ordering semantics. Additionally, using the currently bound DSV makes it more apparent that the clear is done as a graphics pipeline operation, in sequence with the output merger and `Draw*` operations.

### D3D12DDI_CLEAR_TEXTURE_DESC struct

Used by [PFND3D12DDI_CLEAR_TEXTURE_SUBRESOURCES](#pfnd3d12ddi_clear_texture_subresources-function) to clear texture subresources.

``` C++
typedef struct D3D12DDI_CLEAR_TEXTURE_DESC
{
    D3D12DDI_HRESOURCE hTexture;
    UINT SubresourceIndex;
    D3D12DDI_CLEAR_DATA ClearValue;
    DXGI_FORMAT Format;
    const D3D12DDI_BOX *pRegion;
} D3D12DDI_CLEAR_TEXTURE_DESC;
```

**Members:**

`hTexture`  
Type: `D3D12DDI_HRESOURCE`  
Handle to the texture containing the subresource being cleared.

`SubresourceIndex`  
Type: `UINT`  
Index of subresource to clear. May be `0xFFFFFFFF` to indicate all subresources.

`ClearValue`  
Type: `const D3D12DDI_CLEAR_DATA`  
Value to set in the cleared data.

`Format`  
Type: `DXGI_FORMAT`  
Format of the clear operation. If `Format` is set to `DXGI_FORMAT_UNKNOWN` then the format used to create the resource is assumed. Typeless formats are not supported.

`pRegion`  
Type: `const D3D12DDI_BOX*`  
Pointer to a `D3D12DDI_BOX` describing the region to clear. May be `NULL` to clear full subresource. If non-`NULL` and `SubresourceIndex` is `0xFFFFFFFF`, then all texture subresources must have the same dimensions.

### PFND3D12DDI_CLEAR_TEXTURE_SUBRESOURCES function

Clears a set of texture subresource regions.

``` C++
typedef VOID ( APIENTRY* PFND3D12DDI_CLEAR_TEXTURE_SUBRESOURCES )( 
    D3D12DDI_HCOMMANDLIST hDrvCommandList,
    UINT NumClearDescs,
    const D3D12DDI_CLEAR_TEXTURE_DESC *pClearDescs
    );
```

**Parameters:**

`hDrvCommandList`  
Type: `D3D12DDI_HCOMMANDLIST`  
Handle to the command list.

`NumClearDescs`  
Type: `UINT`  
Number of `D3D12DDI_CLEAR_TEXTURE_DESC` elements pointed to by `pClearDescs`.

`pClearDescs`  
Type: `const D3D12DDI_CLEAR_TEXTURE_DESC *`  
Pointer to an array of `NumClearDescs` [D3D12DDI_CLEAR_TEXTURE_DESC](#d3d12ddi_clear_texture_desc-struct) elements.

**Return Value:**

None

**Remarks:**

Resources cleared using `PFND3D12DDI_CLEAR_TEXTURE_SUBRESOURCES` must be in one of the following layouts:

- `D3D12DDI_BARRIER_LAYOUT_COMMON`
- `D3D12DDI_BARRIER_LAYOUT_COPY_DEST`
- `D3D12DDI_BARRIER_LAYOUT_DIRECT_QUEUE_COMMON`
- `D3D12DDI_BARRIER_LAYOUT_DIRECT_QUEUE_COPY_DEST`
- `D3D12DDI_BARRIER_LAYOUT_COMPUTE_QUEUE_COMMON`
- `D3D12DDI_BARRIER_LAYOUT_COMPUTE_QUEUE_COPY_DEST`

Subresource layout must be compatible with the queue type. For example, compute queues cannot clear subresources using layouts `D3D12DDI_BARRIER_LAYOUT_DIRECT_QUEUE_*`.

Barriers using synchronization scope `D3D12DDI_BARRIER_SYNC_COPY` and access bit `D3D12DDI_BARRIER_ACCESS_COPY_DEST` are required to manage dependent accesses.

### D3D12DDI_FILL_BUFFER_DESC struct

``` C++
typedef struct D3D12DDI_FILL_BUFFER_DESC
{
    D3D12DDI_HRESOURCE hBuffer;
    UINT64 Offset;
    D3D12DDI_CLEAR_DATA FillValue;
    DXGI_FORMAT Format;
    UINT RawPatternSizeInBytes;
    UINT RepeatCount;
} D3D12DDI_FILL_BUFFER_DESC;
```

**Members:**

`hBuffer`  
Type: `D3D12DDI_HRESOURCE`  
Handle to the buffer to be filled.

`Offset`  
Type: `UINT64`  
Offset to the start of the fill region.

`FillValue`  
Type: `D3D12DDI_CLEAR_DATA`  
Value to use for fill pattern. If `Format` is `DXGI_FORMAT_UNKNOWN`, the fill pattern is taken from the least significant `RawPatternSizeInBytes` bytes contained in `FillValue.Bytes`. Otherwise, the value is interpreted according to `Format`.

`Format`  
Type: `DXGI_FORMAT`  
Specifies the format of the fill data. If `DXGI_FORMAT_UNKNOWN`, the fill uses the raw pattern contained in `FillValue.Bytes` as described above.

`RawPatternSizeInBytes`  
Type: `UINT`  
If `Format` is `DXGI_FORMAT_UNKNOWN`, specifies the size in bytes of the raw fill pattern contained in `FillValue.Bytes` (must be 1–16). Otherwise, must be zero.

`RepeatCount`  
Type: `UINT`  
The number of times to contiguously repeat the fill pattern, starting at Offset. If a repetition would not fully fit within the buffer, it is omitted and the remaining buffer contents are left unchanged (i.e., the operation never writes a partial pattern at the end).

**Remarks:**

The fill pattern is repeated up to `RepeatCount` times, placed contiguously in the buffer starting at `Offset`.

If `Format` is `DXGI_FORMAT_UNKNOWN` then `RawPatternSizeInBytes` must be 1, 2, 4, 8, 12 or 16 bytes. Patterns larger than 16 bytes are not supported.

`Offset` must be aligned to the `RawPatternSizeInBytes` (if Format is `DXGI_FORMAT_UNKNOWN`) or to the size of the format (if a format is specified) according to the following table:

| Raw Pattern or Formatted Value Size | `Offset` alignment |
|-------------------------------------|--------------------|
| 1                                   | 1                  |
| 2                                   | 2                  |
| 4 or greater                        | 4                  |

### PFND3D12DDI_FILL_BUFFERS function

Fills buffer memory with repeating patterns.

``` C++
typedef VOID ( APIENTRY* PFND3D12DDI_FILL_BUFFERS )(
    D3D12DDI_HCOMMANDLIST hDrvCommandList,
    UINT NumFillDescs,
    const D3D12DDI_FILL_BUFFER_DESC *pFillDescs
    );
```

**Parameters:**

`hDrvCommandList`  
Type: `D3D12DDI_HCOMMANDLIST`  
Handle to the command list.

`NumFillDescs`  
Type: `UINT`  
Number of `D3D12DDI_FILL_BUFFER_DESC` elements pointed to by `pFillDescs`.

`pFillDescs`  
Type: `const D3D12DDI_FILL_BUFFER_DESC *`  
Pointer to an array of `NumFillDescs` `D3D12DDI_FILL_BUFFER_DESC` elements.

**Return Value:**

None

**Remarks:**

Batch fills buffer memory ranges.

`PFND3D12DDI_FILL_BUFFERS` is treated as a Copy operation. Barriers using synchronization scope `D3D12DDI_BARRIER_SYNC_COPY` and access bit `D3D12DDI_BARRIER_ACCESS_COPY_DEST` are required to manage dependent accesses.

Although considered a copy operation, `PFND3D12DDI_FILL_BUFFERS` cannot be used on copy queues.
