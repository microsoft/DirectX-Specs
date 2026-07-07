# Direct3D 12 Tight Placed Resource Alignment
> Released under AgilitySDK [1.618.1](https://www.nuget.org/packages/Microsoft.Direct3D.D3D12/1.618.1) and [1.716.1-preview](https://www.nuget.org/packages/Microsoft.Direct3D.D3D12/1.716.1-preview)

> Updated in AgilitySDK [1.619.4](https://www.nuget.org/packages/Microsoft.Direct3D.D3D12/1.619.4) and [1.721.2-preview](https://www.nuget.org/packages/Microsoft.Direct3D.D3D12/1.721.2-preview)

## Background
When placed resources were introduced in D3D12, there was an intentional decision to simplify alignment restrictions and take the greatest common denominator across the IHVs.
This resulted in the following alignment requirements:

|  Type  | MIN                                               | MAX       |
|--------|---------------------------------------------------|-----------|
|Buffers | 64 KiB (aligned to page table size)               | 64 KiB    |
|Textures| 4 KiB (must match definition of "Small resource") | 64 KiB    |
|  MSAA  | 64 Kib (must match definition of "Small resource")| 4 MiB     |

A "Small resource" is defined as:
1. MUST have UNKNOWN layout.
1. MUST NOT be RENDER_TARGET or DEPTH_STENCIL.
1. The estimated size of the most-detailed mip level MUST be a total of the larger alignment restriction or less.
The runtime will use an architecture-independent mechanism of size-estimation, that mimics the way standard swizzle and D3D11 tiled resources are sized.
However, the tile sizes will be of the smaller alignment restriction for such calculations. Additional data associated with resources, which is typically associated with compression, will not be added into this size.
So for a normal texture, when this calculated size is <= 64 KiB, you can use the alignment of 4 KiB.
For an MSAA texture, when this calculated size is <= 4 MiB, you can use the alignment of 64 KiB.

There were a number of reasons for these choices, such as:
* Improved memory bandwidth with 64KiB alignments
* How compressed data works with MMU page table design
* (potentially, need to confirm) allocation granularity of VidMM (4 KiB) and WDDM2.0 (64 KiB)
* (likely other hardware restrictions, but these were the ones I found noted for posterity)

There was an intention to migrate to tighter alignment across the ecosystem over time, but this hasn't happened yet.
Developers have noticed that it is actually pretty common to have numerous tiny resources (meaningfully smaller than the alignment requirements), and they must now make a tradeoff:
* Eat the memory cost required to allocate tiny resources and end up with an underutilized heap, but still have tooling support
* Allocate a large parent resource and then sub-allocate their tiny resources without having the ability to track things like resource name, out-of-bounds accesses, etc

Even in the second case, developers are further limited by the fact that creation of SRVs can't take an offset, so all elements within a placed resource need to have the same stride.
This is particularly annoying for the "bag of bits" Buffer resources, and texture data will have a rough time attempting this approach anyway since all of the formats will also need to match the original parent resource allocation.

So simply adding an offset to SRV creation probably isn't the solution that we need...


## Proposed Solution
We already have the [ID3D12Device::GetResourceAllocationInfo](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12device-getresourceallocationinfo(uint_uint_constd3d12_resource_desc))[ [1](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12device4-getresourceallocationinfo1(uint_uint_constd3d12_resource_desc_d3d12_resource_allocation_info1)), [2](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12device8-getresourceallocationinfo2(uint_uint_constd3d12_resource_desc1_d3d12_resource_allocation_info1)), 3] API for developers to get allocation info based on resource desc(s).
Under the hood this calls the [CheckResourceAllocationInfo](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/d3d12umddi/nc-d3d12umddi-pfnd3d12ddi_checkresourceallocationinfo_0088) DDI which gets alignment, size, etc. from the driver.
`CheckResourceAllocationInfo` contains a UINT32 field for `AlignmentRestriction` as well as a `D3D12DDIARG_CREATERESOURCE_0088` struct parameter that has a bitfield of flags. 
IHVs agree that they can all align buffers at 256B or less, we just need to allow them to report this capability rather than forcing 64KiB alignment.

We will update `D3D12DDI_RESOURCE_FLAGS_0003` to include `D3D12DDI_RESOURCE_FLAG_0111_USE_TIGHT_ALIGNMENT` to indicate to drivers that they should handle allocations for this resource in tight alignment mode.
The `AlignmentRestriction` parameter of the DDI will be set to the minimum acceptable alignment value based on the tables below during resource creation (varies based on placed vs committed resource requirements, which can't be inferred in the `CheckResourceAllocationInfo` call the way it can in `CreateHeapAndResource`).
Drivers must return an alignment between the `AlignmentRestriction` and the max alignment value in the tables below.

In the runtime, we will update `D3D12_RESOURCE_FLAGS` to include `D3D12_RESOURCE_FLAG_USE_TIGHT_ALIGNMENT`.
We will also add an API cap (`D3D12_FEATURE_TIGHT_ALIGNMENT`) that developers can check to know that a driver claims support for Tight Alignment.
The flag is only valid when the driver reports support.

The expected tight alignment ranges are as follows and will be validated via HLK:

### Placed Resources

|       Type        | MIN | MAX                                                            |
|-------------------|-----|----------------------------------------------------------------|
|      Buffers      | 8B  | 256B                                                           |
|      Textures     | 8B  | 64KiB (4KiB when it meets the definition of a Small Resource)  |
|        MSAA       | 8B  | 4MiB (64KiB when it meets the definition of a Small Resource)  |

The minimum of 8B is to ensure safety of 64bit atomics.
Buffer max alignment has been reduced to 256B as this seems to cover the worst case alignment needs of in market hardware.

Textures and multisample resources were deemed less likely to benefit from tighter alignment and aren't the biggest pain points for ISVs at this time, so while drivers may opt to align them more tightly when possible it isn't a requirement at this time.

### Committed Resources
Committed resources can also benefit from having their minimum alignment reduced, specifically committed buffers.
There is some nuance here though due to the fact that a heap is implicitly created for each committed resource, and VidMM's minimum alignment and size granularity for managing memory is 4KiB.
Per the original User Mode Heaps spec that laid out the resource creation flow, the spirit of the DDI requires that each committed resource creation call result in 1 allocation. 
This means that we don't want drivers to need to manage suballocations, which limits minimum alignment for committed resources to 4KiB or larger.

**Note: For drivers that report LargePageSupport for VidMM allocations, it is acceptable and optimal for allocations that are a multiple of the LargePage size to be aligned to the large page size instead of using the 4KiB alignment.**



|      Type        | MIN  | MAX                                                            |
|------------------|------|----------------------------------------------------------------|
|     Buffers      | 4KiB | 4KiB                                                           |
|     Textures     | 4KiB | 64KiB (4KiB when it meets the definition of a Small Resource)  |
|       MSAA       | 4KiB | 4MiB (64KiB when it meets the definition of a Small Resource)  |

### Runtime changes
Calls to `GetResourceAllocationInfo` will continue to function as they do today, except that when the flag bit for `D3D12_RESOURCE_FLAG_USE_TIGHT_ALIGNMENT` is set, the alignment for that element is allowed to be aligned as tightly as possible.
That said, we still follow the C++ algorithm for calculating a structure's size and alignment when multiple descriptors are passed in: alignment is always based on the largest alignment required, and size depends on the order of the elements.
For a contrived example, consider a three-element array with two tiny 256B-aligned resources and a tiny 2MiB-aligned resource.
The API will report differing sizes based on the order of the array:
* If the 2MiB aligned resource is in the middle, then the resulting Size is 6MiB. 
* Otherwise, the resulting Size is 4MiB. 

The Alignment returned would always be 2MiB, because it's the superset of all alignments in the resource array.
Note that in the real world you probably wouldn't do this since there would be so much space wasted on padding.
A more realistic scenario would be to have 8192 256B resources (or the equivalent total size) followed by the 2MiB resource.
In this case, you are no longer wasting memory on padding and are benefitting from only making a single allocation.

The d3d12.h header will be updated as shown below:

```cpp
typedef enum D3D12_FEATURE
{
  ... // existing features
  D3D12_FEATURE_D3D12_TIGHT_ALIGNMENT = 54
} D3D12_FEATURE;

typedef enum D3D12_TIGHT_ALIGNMENT_TIER
{
  D3D12_TIGHT_ALIGNMENT_TIER_NOT_SUPPORTED,
  D3D12_TIGHT_ALIGNMENT_TIER_1  // Tight alignment of buffers supported 
} D3D12_TIGHT_ALIGNMENT_TIER;

typedef struct D3D12_FEATURE_DATA_TIGHT_ALIGNMENT
{
  D3D12_TIGHT_ALIGNMENT_TIER SupportTier;
}

typedef enum D3D12_RESOURCE_FLAGS
{
    D3D12_RESOURCE_FLAG_NONE	= 0,
    ... // existing flags
    D3D12_RESOURCE_FLAG_USE_TIGHT_ALIGNMENT = 0x400,
    ... // masks
} 	D3D12_RESOURCE_FLAGS;
```

#### Validation
* Cases where a warning will be issued via debug layer when `D3D12_RESOURCE_FLAG_USE_TIGHT_ALIGNMENT` is set:
  * Used along-side `D3D12_RESOURCE_FLAG_ALLOW_CROSS_ADAPTER`, as alignment MUST be 64 KiB, or 4MiB for MSAA
* Cases where E_INVALIDARG will be returned when `D3D12_RESOURCE_FLAG_USE_TIGHT_ALIGNMENT` is set:
  * Used with `D3D12_TEXTURE_LAYOUT_64KB_UNDEFINED_SWIZZLE` or `D3D12_TEXTURE_LAYOUT_64KB_STANDARD_SWIZZLE` resource formats, as alignment must be 64KiB. **Note that this means that Reserved Resources are not supported**.
  * Used when `D3D12_FEATURE_D3D12_TIGHT_ALIGNMENT` is reported as `D3D12_TIGHT_ALIGNMENT_TIER_NOT_SUPPORTED`
  * The app-supplied `Alignment` is non-zero and not a power of two
  * The app-supplied `Alignment` exceeds the per-type spec maximum (see the placed / committed resource tables above)

#### Non-zero `Alignment` as a target floor
When `USE_TIGHT_ALIGNMENT` is set and `Alignment` in the resource desc is non-zero, the runtime treats the value as a *target floor* rather than a hard requirement.
The runtime honors the app-supplied floor when it is a valid value (i.e. a power of two and within the per-type spec maximum) and clamps up to its own required minimum when the floor is too small.

When the runtime has to clamp up, a debug-layer INFO message `D3D12_MESSAGE_ID_CREATERESOURCE_ALIGNMENT_OVERRIDDEN` is emitted so the override is discoverable without the app having to compare `Alignment` against `GetDesc()` afterwards.

Because a non-zero `Alignment` is now legal, applications can round-trip a desc through `ID3D12Resource::GetDesc` and pass it back into `CreateCommittedResource*`, `CreatePlacedResource*`, `GetResourceAllocationInfo`, or `GetCopyableFootprints` without needing to reset `Alignment` to `0` first.

> Available as of AgilitySDK [1.619.4](https://www.nuget.org/packages/Microsoft.Direct3D.D3D12/1.619.4) and [1.721.2-preview](https://www.nuget.org/packages/Microsoft.Direct3D.D3D12/1.721.2-preview)

##### Choosing an `Alignment` floor for buffer use cases
When a tight-alignment buffer will be used for a purpose that carries its own hardware alignment requirement, apps can pass that requirement as `Alignment` in the resource desc so the runtime clamps up front.

Without an explicit floor, tight-alignment buffers may end up aligned as tightly as 8 bytes (`D3D12_TIGHT_ALIGNMENT_MIN_PLACED_RESOURCE_ALIGNMENT`).
That is legal for the buffer allocation itself but produces a debug-layer error -- and, on some drivers, device removal -- once the buffer is later bound in a way that requires stricter alignment.
Passing the appropriate floor up front avoids the error without giving up tight-alignment savings for the rest of the resource.

The following buffer use cases each carry their own set of publicly-defined `d3d12.h` alignment constants.
For each use case, pass the group's floor (its largest applicable constant, shown in **bold**) as `Alignment` when creating the buffer.
Use cases are listed in ascending order of floor.

| Use case | Floor | Alignment constant | Bytes |
|---|---|---|---|
| **Raw UAV / SRV** | 16 B | **`D3D12_RAW_UAV_SRV_BYTE_ALIGNMENT`** | 16 |
| **Raytracing acceleration-structure build inputs** | 16 B | `D3D12_RAYTRACING_AABB_BYTE_ALIGNMENT` | 8 |
| | | `D3D12_RAYTRACING_INSTANCE_DESCS_BYTE_ALIGNMENT` | 16 |
| | | **`D3D12_RAYTRACING_TRANSFORM3X4_BYTE_ALIGNMENT`** | 16 |
| **`DispatchRays` shader tables** | 64 B | `D3D12_RAYTRACING_SHADER_RECORD_BYTE_ALIGNMENT` | 32 |
| | | **`D3D12_RAYTRACING_SHADER_TABLE_BYTE_ALIGNMENT`** | 64 |
| **Raytracing 2 CLAS / opacity micromaps** | 128 B | `D3D12_RAYTRACING_CLUSTER_TEMPLATE_BYTE_ALIGNMENT` | 32 |
| | | **`D3D12_RAYTRACING_CLAS_BYTE_ALIGNMENT`** | 128 |
| | | **`D3D12_RAYTRACING_OPACITY_MICROMAP_ARRAY_BYTE_ALIGNMENT`** | 128 |
| **Constant Buffer View target** | 256 B | `D3D12_COMMONSHADER_CONSTANT_BUFFER_PARTIAL_UPDATE_EXTENTS_BYTE_ALIGNMENT` | 16 |
| | | **`D3D12_CONSTANT_BUFFER_DATA_PLACEMENT_ALIGNMENT`** | 256 |
| **Video decode bitstream / histogram buffers** | 256 B | **`D3D12_VIDEO_DECODE_MIN_BITSTREAM_OFFSET_ALIGNMENT`** | 256 |
| | | **`D3D12_VIDEO_DECODE_MIN_HISTOGRAM_OFFSET_ALIGNMENT`** | 256 |

A buffer that will be used for multiple purposes should use the max of all applicable floors.


### DDI
The new `D3D12_RESOURCE_FLAG_USE_TIGHT_ALIGNMENT` will be forwarded to the driver via the `D3D12DDI_RESOURCE_FLAGS_0003` bitfield.
To ensure there is no impact to existing drivers, the flag will not be forwarded to the driver until it reports support for a new DDI cap: 

```cpp
typedef enum D3D12DDI_RESOURCE_FLAGS_0003 
{
    D3D12DDI_RESOURCE_FLAG_0003_NONE 	= 0,
    ... // existing flags
    D3D12DDI_RESOURCE_FLAG_0111_USE_TIGHT_ALIGNMENT = 0x8000,
    ... // masks
};

typedef enum D3D12DDI_TIGHT_ALIGNMENT_TIER
{
    D3D12DDI_TIGHT_ALIGNMENT_TIER_NOT_SUPPORTED = 0,
    D3D12DDI_TIGHT_ALIGNMENT_TIER_1 = 1,
} D3D12DDI_TIGHT_ALIGNMENT_TIER;

// A new caps type is defined
typedef enum D3D12DDICAPS_TYPE
{
    //existing caps types
    D3D12DDICAPS_TYPE_TIGHT_ALIGNMENT_TIER_0111 = 1089,
} D3D12DDICAPS_TYPE;

// The corresponding data struct for the cap
typedef struct D3D12DDI_TIGHT_ALIGNMENT_TIER_DATA_0111
{
    D3D12DDI_TIGHT_ALIGNMENT_TIER SupportTier;
} D3D12DDI_TIGHT_ALIGNMENT_TIER_DATA_0111;
```

As a reminder, this bitfield is passed to the `CheckResourceAllocationInfo` DDI as a member of the `D3D12DDIARG_CREATERESOURCE_0088` parameter.

IMPORTANT: Drivers should size buffers appropriately (`desc.width`) rather than assume 64KiB size when `D3D12DDI_RESOURCE_FLAG_0111_USE_TIGHT_ALIGNMENT` is set.
`CheckExistingResourceAllocationInfo_*` should also return appropriate values for resources that were created with tight alignment.

### HLK tests
These tests will not be a part of the Germanium HLK playlist, but will be in the future playlists.

* When the tight alignment flag is used with the cross adapter flag, the alignment MUST be 64KiB (or 4MiB for MSAA)
* Alignment should never be worse than if not using the tight alignment flag (including the small resources special case)
* Starting with DDI version 0111 (post Germanium), we will verify that buffers of various sizes with the tight alignment flag (and no conflicting flags or formats) are given an alignment <= 256B
  * We will also verify that the size returned from `CheckResourceAllocationInfo` in these cases matches the width of the buffer
  * Idempotency of `CheckResourceAllocationInfo` will also be verified

### Addendum - New Heap flag to indicate that a heap is implicitly created for committed resources
A long standing pain point for drivers has been that committed buffers and heaps for placed resources look the same when created.
Today IHVs use fragile heuristics to determine whether a CreateHeapAndResource call is for creating a heap or committed buffer, which isn't ideal. 
This is a relatively small change to make and in the spirit of the tight alignment feature, so it will be bundled in.
The DDI version will be 0115 though since it was added later in the timeline.

#### DDI
Starting in DDI 0115, the runtime will set the new `D3D12DDI_HEAP_FLAG_0115_IMPLICIT` bit to true in the `D3D12DDIARG_CREATEHEAP_0001::Flags` parameter of `CreateHeapAndResource` calls for committed resources. 

```cpp
typedef enum D3D12DDI_HEAP_FLAGS
{
    // existing heap flags
    D3D12DDI_HEAP_FLAG_0115_IMPLICIT = 0x80,
} D3D12DDI_HEAP_FLAGS;
```

---

# FAQ
## Why a Flag instead of a new API?
* Can apply the change to other APIs that internally call `GetResourceAllocationInfo`, such as `CreateCommittedResource`.
  * As an interesting note, we have seen some IHVs creating more tightly aligned resources in this case even though the runtime is technically requesting something else.
  We would prefer to move away from that and towards a solution where they just perform the requested allocation without trying to do anything sneaky behind the scenes.
* It makes sense for this to be a property of the resource, and it could be useful to have this context available when debugging

## How does this affect Heap alignment and offsets?
* Heap alignment is unaffected for explicit heaps - it must still be 64KiB aligned, unless it will contain MSAA resources, in which case it must be 4MiB aligned. Implicit heaps are allowed to use VidMM's 4KiB granularity.
* HeapOffset isn't really affected, but since the alignment of resources (particularly buffers) can be smaller, the offsets into the heap are also allowed to be smaller (though still integer multiples of the resource's alignment)

## Can this be the default behavior? That is, don't require applications to opt in for each resource?
* Unfortunately, this isn't possible since the docs previously informed developers that it was safe to assume buffers have 64KiB alignment and sized to be the smallest multiple of 64KiB that would fit the specified width.