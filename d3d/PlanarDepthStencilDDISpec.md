- [Planar Depth Stencil](#planar-depth-stencil)
- [Detailed Design](#detailed-design)
  - [Depth and Stencil Formats Are Planar Texture Formats](#depth-and-stencil-formats-are-planar-texture-formats)
    - [DXGI_FORMAT](#dxgi_format)
    - [Texture Memory Layout Remains Undefined](#texture-memory-layout-remains-undefined)
  - [Planar Layout for Staging From Buffer](#planar-layout-for-staging-from-buffer)
    - [DXGI_FORMAT_R24G8_TYPELESS](#dxgi_format_r24g8_typeless)
      - [Depth Plane](#depth-plane)
      - [Stencil Plane](#stencil-plane)
    - [DXGI_FORMAT_R32G8X24_TYPELESS](#dxgi_format_r32g8x24_typeless)
      - [Depth Plane](#depth-plane-1)
      - [Stencil Plane](#stencil-plane-1)
  - [View Creation](#view-creation)
    - [Shader Resource View](#shader-resource-view)
    - [Depth Stencil View](#depth-stencil-view)
  - [Resource Barrier Transitions](#resource-barrier-transitions)

Planar Depth Stencil
====================

This feature redefines the depth and stencil format families of DXGI_FORMAT_R32G8X24_TYPELESS and DXGI_FORMAT_R24G8_TYPELESS as planar resources in D3D12. Previously these formats were defined as interleaved. This change addresses a regression from D3D11 by enabling resource barrier transitions to different states for depth and stencil by targeting a plane with subresource index.

This change has no effect on the D3D11 definition of DXGI_FORMAT_R32G8X24_TYPELESS and DXGI_FORMAT_R24G8_TYPELESS. For D3D11, these formats remain interleaved.

Detailed Design
===============

Depth and Stencil Formats Are Planar Texture Formats
----------------------------------------------------

### DXGI_FORMAT

The DXGI_FORMAT_R24G8_TYPELESS and DXGI_FORMAT_R32G8X24_TYPELESS family of resource/view formats are defined to be planar in D3D12. D3D11 and earlier definitions remain interleaved at the API/DDI and are unchanged
by this specification.

Each format has a depth plane as plane 0, and a stencil plane as plane 1. For details for using planar resources with subresource index, see the D3D12 Subresource Refactor spec.

### Texture Memory Layout Remains Undefined

This specification is not yet adding features that reveal the actual memory representation used by Depth and Stencil textures. They are indexed as planar where subresource index is used, but it is still
possible to emulate planar. We do define a memory layout in buffer for planar and interleaved data to enable staging, see below.

Planar Layout for Staging From Buffer
-------------------------------------

Staging to depth and stencil formats now has a planar placed texture data layout. The CopyTextureRegion API and CopySubresourceRegion DDI use subresource index to identify which plane of the texture (either depth or stencil) that the operation applies to.

### DXGI_FORMAT_R24G8_TYPELESS

#### Depth Plane

The depth plane placed texture data for this format is 32 bits per element, but only 24 bits are used to express a 24 bit normalized unsigned integer. A format from the DXGI_FORMAT_R32_TYPELESS family is used to specify planar depth placed texture data when copying to or from the depth plane of a DXGI_FORMAT_R24G8_TYPELESS texture.

( ElementAddress + 0 ) : D24X8

Using a least significant bit/most significant bit definition of the entire element:

D24: bits 0-23

X8: bits 24-31 (unused\*)

> Applications must initialize the X8 bits to zero when providing source planar depth placed texture data. Drivers must initialize X8 bits to zero when copying to planar depth placed texture data.

#### Stencil Plane

The stencil plane placed texture data for this format is 8 bits per
element used to express an 8 bit unsigned integer. A format from the
DXGI_FORMAT_R8_TYPELESS family is used to specify planar stencil placed
texture data when copying to or from the stencil plane of a
DXGI_FORMAT_R24G8_TYPELESS texture.

( ElementAddress + 0 ) : S8

  | S8                       | MSB                                 LSB |
  | ------------------------ | --------------------------------------- |
  | ( ComponentAddress + 0 ) | 07 : 06 : 05 : 04 : 03 : 02 : 01 : 00   |

### DXGI_FORMAT_R32G8X24_TYPELESS

#### Depth Plane

The depth plane plane placed texture data for this format is 32 bits per
element used to express a 32 bit floating point value. A format from the
DXGI_FORMAT_R32_TYPELESS family is used to specify depth plane placed
texture data when copying to or from the depth plane of an
DXGI_FORMAT_R32G8X24_TYPELESS texture.

( ElementAddress + 0 ) : D32

  | Little Endian D32        | MSB                                  LSB |
  | ------------------------ | ---------------------------------------- |
  | ( ComponentAddress + 0 ) | 07 : 06 : 05 : 04 : 03 : 02 : 01 : 00    |
  | ( ComponentAddress + 1 ) | 15 : 14 : 13 : 12 : 11 : 10 : 09 : 08    |
  | ( ComponentAddress + 2 ) | 23 : 22 : 21 : 20 : 19 : 18 : 17 : 16    |
  | ( ComponentAddress + 3 ) | 31 : 30 : 29 : 28 : 27 : 26 : 25 : 24    |

  | Big Endian D32           | MSB                                 LSB |
  | ------------------------ | --------------------------------------- |
  | ( ComponentAddress + 0 ) | 31 : 30 : 29 : 28 : 27 : 26 : 25 : 24   |
  | ( ComponentAddress + 1 ) | 23 : 22 : 21 : 20 : 19 : 18 : 17 : 16   |
  | ( ComponentAddress + 2 ) | 15 : 14 : 13 : 12 : 11 : 10 : 09 : 08   |
  | ( ComponentAddress + 3 ) | 07 : 06 : 05 : 04 : 03 : 02 : 01 : 00   |

#### Stencil Plane

The stencil plane plane placed texture data for this format is 8 bits per element used to express an 8 bit unsigned integer. A format from the DXGI_FORMAT_R8_TYPELESS family is used to specify stencil plane placed
texture data when copying to or from the stencil plane of a DXGI_FORMAT_R32G8X24_TYPELESS texture.

( ElementAddress + 0 ) : S8

  | S8                       | MSB                                 LSB |
  | ------------------------ | --------------------------------------- |
  | ( ComponentAddress + 0 ) | 07 : 06 : 05 : 04 : 03 : 02 : 01 : 00   |

View Creation
-------------

PlaneSlice parameters are not added to the view creation for depth and
stencil formats as existing DXGI formats are sufficient to disambiguate
which plane or planes view is created form.

### Shader Resource View

| Planar Format                     | PlaneSlice | SRV Format                           |
| --------------------------------- | ---------- | ------------------------------------ |
| **DXGI_FORMAT_R24G8_TYPELESS**    | 0          | DXGI_FORMAT_R24_UNORM_X8_TYPELESS    |
| **DXGI_FORMAT_R24G8_TYPELESS**    | 1          | DXGI_FORMAT_X24_TYPELESS_G8_UINT     |
| **DXGI_FORMAT_R32G8X24_TYPELESS** | 0          | DXGI_FORMAT_R32_FLOAT_X8X24_TYPELESS |
| **DXGI_FORMAT_R32G8X24_TYPELESS** | 1          | DXGI_FORMAT_X32_TYPELESS_G8X24_UINT  |

### Depth Stencil View

  | Planar Format                     | PlaneSlice | DSV Format                       |
  | --------------------------------- | ---------- | -------------------------------- |
  | **DXGI_FORMAT_R24G8_TYPELESS**    | 0          | DXGI_FORMAT_D24_UNORM_S8_UINT    |
  | **DXGI_FORMAT_R24G8_TYPELESS**    | 1          | DXGI_FORMAT_D24_UNORM_S8_UINT    |
  | **DXGI_FORMAT_R32G8X24_TYPELESS** | 0          | DXGI_FORMAT_D32_FLOAT_S8X24_UINT |
  | **DXGI_FORMAT_R32G8X24_TYPELESS** | 1          | DXGI_FORMAT_D32_FLOAT_S8X24_UINT |

Resource Barrier Transitions
----------------------------

As a planar texture, depth and stencil now support transitioning to states separately by specifying the subresource index that targets the depth plane or the subresource index that targets the stencil plane.
This change deprecates the D3D12DDI_RESOURCE_TRANSITION_BARRIER_DEPTH_ONLY and D3D12DDI_RESOURCE_TRANSITION_BARRIER_STENCIL_ONLY flags of resource transition barrier and those flags are removed from the API and DDI.

Additionally, the D3D12DDI_RESOURCE_USAGE_DEPTH flag is removed and the new flags D3D12DDI_RESOURCE_USAGE_DEPTH_STENCIL_READ and D3D12DDI_RESOURCE_USAGE_DEPTH_STENCIL_READ_WRITE take its place.
D3D12DDI_RESOURCE_USAGE_DEPTH_STENCIL_READ may be combined with D3D12DDI_RESOURCE_USAGE_PIXEL_SHADER_RESOURCE.
D3D12DDI_RESOURCE_USAGE_DEPTH_STENCIL_READ_WRITE is mutually exclusive from other usages which is consistency with all other write flags.
