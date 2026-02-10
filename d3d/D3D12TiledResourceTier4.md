# D3D12 Tiled Resource Tier 4

## Background

D3D12 has defined tiled resource tiers to support `64KB_UNDEFINED_SWIZZLE` layout. The 3 existing tiled resource tiers have some limitations that prevent apps from utilizing this layout in some scenarios. For example, we have received many requests from game developers to use 64KB_UNDEFINED_SWIZZLE texture arrays with packed mips. Please note that tiled resource tier 4 supports everything that has already been supported in tiled resource tier 3.

### Summary of tiled resource tiers

|Tier|Summary|
|---|---|
|Tier 1| Support 64KB_UNDEFINED_SWIZZLE and CreateReservedResource. |
|Tier 2| Better define mipmap organization, Define read from / write to NULL-mapped tiles, etc. |
|Tier 3| Support 3D Textures. |
|Tier 4| 64KB_UNDEFINED_SWIZZLE texture arrays can be created with a full mip chain. |

## Arrayed Tiled Resources With Full Mip Chain

Tiled resources tier 2 and 3 already support arrayed, mipped tiled resources. However, D3D12 has a restriction that tiled resources cannot be created with both more than one array slice and any mipmap that has a dimension less than a tile in extent. For tiled resource tier 2 and 3, when the size of a texture mipmap level is at least one standard tile shape for its format, the mipmap level is guaranteed to be non-packed. This essentially means packed mip levels are not supported when a tiled resource is both arrayed and mipped. This restriction exists due to historical reliance on disjoint TBWC (Texture Bandwidth Compression), where metadata is stored separately from texture data. Disjoint TBWC makes it impossible to guarantee a continuous, packed layout when array slices are involved. As a result, hardware support in this area was not able to be standardized in time to be included in D3D. Since seamless TBWC are widely supported, it makes sense for D3D to relax this restriction and support packed mips for arrayed tiled resources.

## 64KB_STANDARD_SWIZZLE

Since 64KB_STANDARD_SWIZZLE is not widely adopted, tiled resource tier 4 does not apply to this layout, we are only interested in 64KB_UNDEFINED_SWIZZLE here.

## API

There is no API change. D3D12_TILED_RESOURCES_TIER_4 is already available.

Existing D3D12 resource creation APIs can already be used to create 64KB_UNDEFINED_SWIZZLE texture arrays with a full mip chain. Other D3D12 tiled resource APIs (GetResourceTiling, UpdateTileMappings, etc.) do not need to change for the same reason. 

## DDI

```c++
typedef enum D3D12DDI_TILED_RESOURCES_TIER
{
    D3D12DDI_TILED_RESOURCES_TIER_NOT_SUPPORTED = 0,
    D3D12DDI_TILED_RESOURCES_TIER_1 = 1,
    D3D12DDI_TILED_RESOURCES_TIER_2 = 2,
    D3D12DDI_TILED_RESOURCES_TIER_3 = 3,
    D3D12DDI_TILED_RESOURCES_TIER_0117_4 = 4,
} D3D12DDI_TILED_RESOURCES_TIER;
```

Non-experimental version of this feature can only be supported starting from DDI version 0117. By restricting tiled resource tier 4 to the lastest DDI version, we do not accidentally light this up on old drivers that predated there being any actual tests for this feature.

For drivers that report tiled resource tier 4 DDI support after DDI version 0117 (0117 included), please note that this is no longer an experimental feature and games can ship with this feature with a retail D3D12 Agility SDK. Please make sure tier 4 is supported and tested before reporting this tier. Drivers need to pass D3D12 tiled resource tier 4 comformance tests (D3DConf_12_0_ReservedResource::Tier4Test*).

## Feature Release Dates

End of May 2025.

## Runtime / Debug Layer Validation

Relax runtime and debug layer validation when arrayed tiled resources are created with a full mip chain. We are already doing this for experimental tiled resource tier 4.

## Test

D3D12 adds new conformance tests D3DConf_12_0_ReservedResource::Tier4Test*, which test that tiled texture array can be created with full mip chain and make sure existing D3D tiled resource APIs work properly on this resource.  
