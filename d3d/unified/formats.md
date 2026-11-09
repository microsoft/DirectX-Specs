# Formats and views

<!-- d3d12-review-legend:begin -->

> [!NOTE]
> **Draft provenance annotations.**
> Underlining marks pending replacement wording or authored list items. Warning boxes
> mark authored, mixed or reopened passages awaiting editorial review.
> Editorial adoption does not establish factual or hardware verification. Exact approved factual
> corrections do not trigger a marker. Unmarked text elsewhere, declarations
> and structural Markdown are not assertions of approval.
> [Annotation scope and approvals](../../spec-maintenance/d3d12/prose-annotations.md).

<!-- d3d12-review-legend:end -->

<!-- d3d12-review-alert:begin:formats:N-intro:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A resource's format describes its storage representation. A resource view selects the format interpretation and the buffer elements, mip levels, array slices, or planes exposed to a particular use. Format support, resource creation flags, view validity, binding, and synchronization impose distinct requirements.

<!-- d3d12-review-alert:end:formats:N-intro:0 -->

<a id="interpretation"></a>

## Resource formats and view interpretation

<!-- d3d12-review-alert:begin:formats:N-numeric-conversion-owner:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [shared numeric representations and conversion algorithms](numeric-and-data-rules.md#numeric-3-2) define SNORM/UNORM/sRGB, floating-point and integer-width conversions, with the [round-trip guarantee and its exceptions](numeric-and-data-rules.md#numeric-19-1-2). The [RGB9E5](numeric-and-data-rules.md#numeric-19-3-2) and [R11G11B10](numeric-and-data-rules.md#numeric-19-3-3) numeric layouts/conversions remain distinct from this chapter's format-use capabilities, casting and component-default rules.

<!-- d3d12-review-alert:end:formats:N-numeric-conversion-owner:0 -->

<ins><!-- d3d12-review-inline:begin:formats:L-format-baseline:0 -->Formats describe element data format layout and interpretations.  A large number of data
layouts and interpretations are available.  In addition, there is facility to view the same data with different interpretations (e.g. raw bits vs. normalized integer),
 or to represent data in a general way (just the bit layouts) without committing to a particular interpretation of the data (e.g. normalized) until as late as possible (e.g. a Shader using the data).<!-- d3d12-review-inline:end:formats:L-format-baseline:0 --></ins>

<ins><!-- d3d12-review-inline:begin:formats:L-format-baseline:1 -->A resource can use a partially typeless format where the number of bits per component is specified, but not the data interpretation for those bits.
An example of a partially typeless format is `DXGI_FORMAT_R8G8B8A8_TYPELESS`.  This format has several subformats (making up a second tier) which fully resolve the
interpretation of the data, including `DXGI_FORMAT_R8G8B8A8_UNORM`, `DXGI_FORMAT_R8G8B8A8_UNORM_SRGB`, among others.<!-- d3d12-review-inline:end:formats:L-format-baseline:1 --></ins>

<ins><!-- d3d12-review-inline:begin:formats:L-format-baseline:2 -->When a resource with a partially typeless format is bound to a Shader for output or input, it must be fully qualified as one of the subformats which
in ordinary within-family casting has the same bit counts for each component but now defines a specific type for each component.<!-- d3d12-review-inline:end:formats:L-format-baseline:2 --></ins>

<ins><!-- d3d12-review-inline:begin:formats:L-typeless:0 -->A texture resource may be created with a typeless format. Its format supplies component bit widths without component types, and its description supplies dimensions in format elements. This is unlike a structured-buffer view, which specifies a
structure size/stride without defining the structure's members. Before the Resource is bound to the
pipeline, Resource Views must be created which will fully qualify the
component's types. These Resource Views also allow the Resource to be
decomposed into smaller compatible subgroupings of the Subresources.
For example, a fully mipped `DXGI_FORMAT_R32G32B32A32_TYPELESS` Texture3D with
a width of four, a height of three, and a depth of five, would have
three mip levels. To use this texture, a Resource View would have
to fully qualify the format of the Resource, for example
`DXGI_FORMAT_R32G32B32A32_UINT`. In addition, the Resource View could also
regroup only the two least detailed mip levels or select only a
particular mip level. This allows the original Resource to be
manipulated as if it were a Resource made up of only a few Subresources
within the original Resource. View descriptions are defined below.<!-- d3d12-review-inline:end:formats:L-typeless:0 --></ins>

<ins><!-- d3d12-review-inline:begin:formats:L-typeless:1 -->The benefit of typeless resources is that memory may be used
as weakly typed storage, enabling limited reuse or reinterpretation of the memory,
for ordinary within-family casting, where the component bit counts remain the same.
The same typeless resource may be bound to multiple slots
in the graphics pipeline with Views of different fully qualified formats at
each location. This forces bit representations of formats to be well-defined
with respect to each other.<!-- d3d12-review-inline:end:formats:L-typeless:1 --></ins>

<ins><!-- d3d12-review-inline:begin:formats:L-typeless:2 -->For example, a Resource created with the format R32G32B32A32_TYPELESS may be
used as R32G32B32A32_FLOAT and R32G32B32A32_UINT at different locations in the
pipeline simultaneously.<!-- d3d12-review-inline:end:formats:L-typeless:2 --></ins>

<ins><!-- d3d12-review-inline:begin:formats:L-views:0 -->In order to indirectly bind a Resource to certain stages of the graphics
pipeline, Resource Views must be used. In addition, since some Resources
may be created with typeless formats, the View provides the final
opportunity to fully qualify the Resource component's types. The Resource
Views also allow the Resource to be decomposed into smaller compatible
subgroupings of the Mip Slices, Array Slices, and Subresources. This means
that the effective dimensions and array sizes of the Views will, naturally,
always be less than or equal to the original Resource. Each stage
of the pipeline requires a unique type of View, and each type of View
may have its own custom set of state parameters that are needed to
complete the process of binding a particular Resource to the graphics
pipeline stage. Resource creation flags impose the applicable view restrictions independently of descriptor binding. Views are represented by descriptors; the [binding contract](binding.md#foundations) defines their selection and lifetime.<!-- d3d12-review-inline:end:formats:L-views:0 --></ins>

<ins><!-- d3d12-review-inline:begin:formats:L-views:1 -->A resource view is distinct from the underlying resource from which the view was
created, so where views are used, the view properties (number of mipmaps, number
of array elements, type, etc.) are always used in place of the properties of the
original resource.  Thus, for example, a render target array index of zero always
indicates the first array element in the view, even if the first array element in
the view is not the first array element in the underlying resource.  Out of range
behaviors are also always with respect to the view properties where views are used.<!-- d3d12-review-inline:end:formats:L-views:1 --></ins>

<!-- d3d12-review-alert:begin:formats:N-family:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A format family fixes a compatible storage layout; typed members qualify the interpretation of accessible components. A name containing TYPELESS only for padding does not make the view's accessed components untyped: for example, `DXGI_FORMAT_R24_UNORM_X8_TYPELESS` is a depth-plane SRV format. Buffer resources use `DXGI_FORMAT_UNKNOWN`; typed, raw, and structured buffer views supply their respective interpretations.

<!-- d3d12-review-alert:end:formats:N-family:0 -->

<!-- d3d12-review-alert:begin:formats:N-cast-forward:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The ordinary component-layout restrictions above do not replace the separately defined [R32_UINT UAV casting exception](#r32-uav-casting) or [explicit castable-format lists](#cast-lists).

<!-- d3d12-review-alert:end:formats:N-cast-forward:0 -->

<a id="format-values"></a>

### DXGI format values

<!-- d3d12-review-alert:begin:formats:N-dxgi:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `DXGI_FORMAT` identifies the format namespace. An enumerated value is not by itself evidence that a resource kind, view kind, or operation supports it. The [format support queries](#support) establish the applicable capabilities; operation-specific restrictions still apply.

<!-- d3d12-review-alert:end:formats:N-dxgi:0 -->

#### DXGI_FORMAT

```cpp
typedef enum DXGI_FORMAT
{
    DXGI_FORMAT_UNKNOWN	                                = 0,
    DXGI_FORMAT_R32G32B32A32_TYPELESS                   = 1,
    DXGI_FORMAT_R32G32B32A32_FLOAT                      = 2,
    DXGI_FORMAT_R32G32B32A32_UINT                       = 3,
    DXGI_FORMAT_R32G32B32A32_SINT                       = 4,
    DXGI_FORMAT_R32G32B32_TYPELESS                      = 5,
    DXGI_FORMAT_R32G32B32_FLOAT                         = 6,
    DXGI_FORMAT_R32G32B32_UINT                          = 7,
    DXGI_FORMAT_R32G32B32_SINT                          = 8,
    DXGI_FORMAT_R16G16B16A16_TYPELESS                   = 9,
    DXGI_FORMAT_R16G16B16A16_FLOAT                      = 10,
    DXGI_FORMAT_R16G16B16A16_UNORM                      = 11,
    DXGI_FORMAT_R16G16B16A16_UINT                       = 12,
    DXGI_FORMAT_R16G16B16A16_SNORM                      = 13,
    DXGI_FORMAT_R16G16B16A16_SINT                       = 14,
    DXGI_FORMAT_R32G32_TYPELESS                         = 15,
    DXGI_FORMAT_R32G32_FLOAT                            = 16,
    DXGI_FORMAT_R32G32_UINT                             = 17,
    DXGI_FORMAT_R32G32_SINT                             = 18,
    DXGI_FORMAT_R32G8X24_TYPELESS                       = 19,
    DXGI_FORMAT_D32_FLOAT_S8X24_UINT                    = 20,
    DXGI_FORMAT_R32_FLOAT_X8X24_TYPELESS                = 21,
    DXGI_FORMAT_X32_TYPELESS_G8X24_UINT                 = 22,
    DXGI_FORMAT_R10G10B10A2_TYPELESS                    = 23,
    DXGI_FORMAT_R10G10B10A2_UNORM                       = 24,
    DXGI_FORMAT_R10G10B10A2_UINT                        = 25,
    DXGI_FORMAT_R11G11B10_FLOAT                         = 26,
    DXGI_FORMAT_R8G8B8A8_TYPELESS                       = 27,
    DXGI_FORMAT_R8G8B8A8_UNORM                          = 28,
    DXGI_FORMAT_R8G8B8A8_UNORM_SRGB                     = 29,
    DXGI_FORMAT_R8G8B8A8_UINT                           = 30,
    DXGI_FORMAT_R8G8B8A8_SNORM                          = 31,
    DXGI_FORMAT_R8G8B8A8_SINT                           = 32,
    DXGI_FORMAT_R16G16_TYPELESS                         = 33,
    DXGI_FORMAT_R16G16_FLOAT                            = 34,
    DXGI_FORMAT_R16G16_UNORM                            = 35,
    DXGI_FORMAT_R16G16_UINT                             = 36,
    DXGI_FORMAT_R16G16_SNORM                            = 37,
    DXGI_FORMAT_R16G16_SINT                             = 38,
    DXGI_FORMAT_R32_TYPELESS                            = 39,
    DXGI_FORMAT_D32_FLOAT                               = 40,
    DXGI_FORMAT_R32_FLOAT                               = 41,
    DXGI_FORMAT_R32_UINT                                = 42,
    DXGI_FORMAT_R32_SINT                                = 43,
    DXGI_FORMAT_R24G8_TYPELESS                          = 44,
    DXGI_FORMAT_D24_UNORM_S8_UINT                       = 45,
    DXGI_FORMAT_R24_UNORM_X8_TYPELESS                   = 46,
    DXGI_FORMAT_X24_TYPELESS_G8_UINT                    = 47,
    DXGI_FORMAT_R8G8_TYPELESS                           = 48,
    DXGI_FORMAT_R8G8_UNORM                              = 49,
    DXGI_FORMAT_R8G8_UINT                               = 50,
    DXGI_FORMAT_R8G8_SNORM                              = 51,
    DXGI_FORMAT_R8G8_SINT                               = 52,
    DXGI_FORMAT_R16_TYPELESS                            = 53,
    DXGI_FORMAT_R16_FLOAT                               = 54,
    DXGI_FORMAT_D16_UNORM                               = 55,
    DXGI_FORMAT_R16_UNORM                               = 56,
    DXGI_FORMAT_R16_UINT                                = 57,
    DXGI_FORMAT_R16_SNORM                               = 58,
    DXGI_FORMAT_R16_SINT                                = 59,
    DXGI_FORMAT_R8_TYPELESS                             = 60,
    DXGI_FORMAT_R8_UNORM                                = 61,
    DXGI_FORMAT_R8_UINT                                 = 62,
    DXGI_FORMAT_R8_SNORM                                = 63,
    DXGI_FORMAT_R8_SINT                                 = 64,
    DXGI_FORMAT_A8_UNORM                                = 65,
    DXGI_FORMAT_R1_UNORM                                = 66,
    DXGI_FORMAT_R9G9B9E5_SHAREDEXP                      = 67,
    DXGI_FORMAT_R8G8_B8G8_UNORM                         = 68,
    DXGI_FORMAT_G8R8_G8B8_UNORM                         = 69,
    DXGI_FORMAT_BC1_TYPELESS                            = 70,
    DXGI_FORMAT_BC1_UNORM                               = 71,
    DXGI_FORMAT_BC1_UNORM_SRGB                          = 72,
    DXGI_FORMAT_BC2_TYPELESS                            = 73,
    DXGI_FORMAT_BC2_UNORM                               = 74,
    DXGI_FORMAT_BC2_UNORM_SRGB                          = 75,
    DXGI_FORMAT_BC3_TYPELESS                            = 76,
    DXGI_FORMAT_BC3_UNORM                               = 77,
    DXGI_FORMAT_BC3_UNORM_SRGB                          = 78,
    DXGI_FORMAT_BC4_TYPELESS                            = 79,
    DXGI_FORMAT_BC4_UNORM                               = 80,
    DXGI_FORMAT_BC4_SNORM                               = 81,
    DXGI_FORMAT_BC5_TYPELESS                            = 82,
    DXGI_FORMAT_BC5_UNORM                               = 83,
    DXGI_FORMAT_BC5_SNORM                               = 84,
    DXGI_FORMAT_B5G6R5_UNORM                            = 85,
    DXGI_FORMAT_B5G5R5A1_UNORM                          = 86,
    DXGI_FORMAT_B8G8R8A8_UNORM                          = 87,
    DXGI_FORMAT_B8G8R8X8_UNORM                          = 88,
    DXGI_FORMAT_R10G10B10_XR_BIAS_A2_UNORM              = 89,
    DXGI_FORMAT_B8G8R8A8_TYPELESS                       = 90,
    DXGI_FORMAT_B8G8R8A8_UNORM_SRGB                     = 91,
    DXGI_FORMAT_B8G8R8X8_TYPELESS                       = 92,
    DXGI_FORMAT_B8G8R8X8_UNORM_SRGB                     = 93,
    DXGI_FORMAT_BC6H_TYPELESS                           = 94,
    DXGI_FORMAT_BC6H_UF16                               = 95,
    DXGI_FORMAT_BC6H_SF16                               = 96,
    DXGI_FORMAT_BC7_TYPELESS                            = 97,
    DXGI_FORMAT_BC7_UNORM                               = 98,
    DXGI_FORMAT_BC7_UNORM_SRGB                          = 99,
    DXGI_FORMAT_AYUV                                    = 100,
    DXGI_FORMAT_Y410                                    = 101,
    DXGI_FORMAT_Y416                                    = 102,
    DXGI_FORMAT_NV12                                    = 103,
    DXGI_FORMAT_P010                                    = 104,
    DXGI_FORMAT_P016                                    = 105,
    DXGI_FORMAT_420_OPAQUE                              = 106,
    DXGI_FORMAT_YUY2                                    = 107,
    DXGI_FORMAT_Y210                                    = 108,
    DXGI_FORMAT_Y216                                    = 109,
    DXGI_FORMAT_NV11                                    = 110,
    DXGI_FORMAT_AI44                                    = 111,
    DXGI_FORMAT_IA44                                    = 112,
    DXGI_FORMAT_P8                                      = 113,
    DXGI_FORMAT_A8P8                                    = 114,
    DXGI_FORMAT_B4G4R4A4_UNORM                          = 115,
    DXGI_FORMAT_P208                                    = 130,
    DXGI_FORMAT_V208                                    = 131,
    DXGI_FORMAT_V408                                    = 132,
    DXGI_FORMAT_SAMPLER_FEEDBACK_MIN_MIP_OPAQUE         = 189,
    DXGI_FORMAT_SAMPLER_FEEDBACK_MIP_REGION_USED_OPAQUE = 190,
    DXGI_FORMAT_A4B4G4R4_UNORM                          = 191,
    DXGI_FORMAT_FORCE_UINT                  = 0xffffffff
} DXGI_FORMAT;
```

<a id="components"></a>

### Component naming and storage

```text
R/G/B/A   - Refers to Shader register components (source component on write
            out from a Shader, or pre-swizzle destination component on read
            into a Shader).
D/S       - Refers to Depth/Stencil for formats that are to be used
            as such.
X         - Unused bits in format.
#         - Refers to number of bits in component.
```

Channel ordering of R/G/B/A/D/S/X in format name, read from left to right
indicates order of placement of the channel storage from "first" (left)
to "last" (right).

<ins><!-- d3d12-review-inline:begin:formats:L-components:2 -->Formats are defined to be compatible across host CPU architectures, especially
host CPU architectures that are little or big endian. In general, components
which come "first" are located at lower addresses, while "later" components are
located at higher addresses. This means that, for example, `DXGI_FORMAT_R8G8B8A8_*`
is interpreted as:<!-- d3d12-review-inline:end:formats:L-components:2 --></ins>

```text
( ElementAddress + 0 ) : R8
( ElementAddress + 1 ) : G8
( ElementAddress + 2 ) : B8
( ElementAddress + 3 ) : A8
```

<ins><!-- d3d12-review-inline:begin:formats:L-components:4 -->This means that the CPU can treat the R8G8B8A8 Element as an array of byte-sized
components, which is a memory layout that is compatible with popular programming
languages implemented on multiple host CPU architectures. When components grow
larger than a byte, like `DXGI_FORMAT_R32G32B32A32`, later components are still
located at larger addresses than earlier components. However, the component
is still specified in LSb/ MSb format, so respects the host CPU byte-endianness:<!-- d3d12-review-inline:end:formats:L-components:4 --></ins>

```text
( ElementAddress +  0 ) : R32
( ElementAddress +  4 ) : G32
( ElementAddress +  8 ) : B32
( ElementAddress + 12 ) : A32
```

```text
R32 : 32 bits, matching the CPU byte-endianness.
LE R32 =>                  MSb                 LSb
( ComponentAddress + 0 ) = 07:06:05:04:03:02:01:00
( ComponentAddress + 1 ) = 15:14:13:12:11:10:09:08
( ComponentAddress + 2 ) = 23:22:21:20:19:18:17:16
( ComponentAddress + 3 ) = 31:30:29:28:27:26:25:24
BE R32 =>                  MSb                 LSb
( ComponentAddress + 0 ) = 31:30:29:28:27:26:25:24
( ComponentAddress + 1 ) = 23:22:21:20:19:18:17:16
( ComponentAddress + 2 ) = 15:14:13:12:11:10:09:08
( ComponentAddress + 3 ) = 07:06:05:04:03:02:01:00
```

Naturally, such a specification only works well for certain formats. As long as
the format components are uniform (all have the same size), the component size
is a power of two, and the component size is a multiple of 8 bits. When such
conditions are not met, the memory layout specification must resort to a least
significant bit/ most significant bit definition of the entire element,
when the element size is a multiple of 8 bits.

```text
R10G10B10A2: 32-bit Element
R: bits  0- 9
G: bits 10-19
B: bits 20-29
A: bits 30-31
```

<ins><!-- d3d12-review-inline:begin:formats:L-components:9 -->Certain formats do not comply with these rules, because they are considered
custom formats. An example of such formats is the block compression formats.
Such custom formats have memory layout definitions of their own, separate
from the general rules. R1 formats also have their own separate definition.<!-- d3d12-review-inline:end:formats:L-components:9 --></ins>

<ins><!-- d3d12-review-inline:begin:formats:L-components:10 -->Note, this means that to first-class support multiple CPU architectures,
the implementation of the specification must adapt component endianness to
match the host CPU. For those formats which are specified in a least
significant bit/ most significant bit definition, the implementation must
adapt the overall element endianness to match the host CPU.<!-- d3d12-review-inline:end:formats:L-components:10 --></ins>

<a id="modifiers"></a>

### Format name modifiers

#### `_SNORM`

<ins><!-- d3d12-review-inline:begin:formats:L-modifiers:1 -->Data in channels appearing on the left of _SNORM in the format name are interpreted in the resource as signed integers, and in the Shader as signed normalized float values in the range [-1,1].  Conversions are defined here: [FLOAT -> SNORM](numeric-and-data-rules.md#numeric-3-2-3-4) [SNORM-> FLOAT](numeric-and-data-rules.md#numeric-3-2-3-3)<!-- d3d12-review-inline:end:formats:L-modifiers:1 --></ins>

#### `_UNORM`

<ins><!-- d3d12-review-inline:begin:formats:L-modifiers:3 -->Data in channels appearing on the left of _UNORM in the format name are interpreted in the resource as unsigned integers, and in the Shader as unsigned normalized float values, in the range [0,1]. Conversions are defined here: [FLOAT -> UNORM](numeric-and-data-rules.md#numeric-3-2-3-6) [UNORM -> FLOAT](numeric-and-data-rules.md#numeric-3-2-3-5)<!-- d3d12-review-inline:end:formats:L-modifiers:3 --></ins>

#### `_SINT`

<ins><!-- d3d12-review-inline:begin:formats:L-modifiers:5 -->Data in channels appearing to the left of _SINT in the format name are interpreted both in the resource and in the Shader as signed integers.  Conversions are defined here: [SINT -> SINT (With More Bits)](numeric-and-data-rules.md#numeric-3-2-3-9) [SINT or UINT -> SINT or UINT (With Fewer or Equal Bits)](numeric-and-data-rules.md#numeric-3-2-3-13)<!-- d3d12-review-inline:end:formats:L-modifiers:5 --></ins>

#### `_UINT`

<ins><!-- d3d12-review-inline:begin:formats:L-modifiers:7 -->Data in channels appearing to the left of _UINT in the format name are interpreted in the resource as unsigned integers, and also in the Shader as unsigned integers.  Conversions are defined here: [UINT -> UINT (With More Bits)](numeric-and-data-rules.md#numeric-3-2-3-12) [SINT or UINT -> SINT or UINT (With Fewer or Equal Bits)](numeric-and-data-rules.md#numeric-3-2-3-13)<!-- d3d12-review-inline:end:formats:L-modifiers:7 --></ins>

#### `_FLOAT`

<ins><!-- d3d12-review-inline:begin:formats:L-modifiers:9 -->Data in channels appearing to the left of _FLOAT in the format name are interpreted in the resource as floating point values (bit depth specified by format), and in the Shader as floating point values, with appropriate conversions either way.  Conversions are defined here: [Floating Point Conversion](numeric-and-data-rules.md#numeric-3-2-2)<!-- d3d12-review-inline:end:formats:L-modifiers:9 --></ins>

#### `_SRGB`

<ins><!-- d3d12-review-inline:begin:formats:L-modifiers:11 -->R, G and B channels in format store sRGB-encoded nonlinear data.  Conversion to/from linear values is required (pre-filtering) when reading/writing data to those channels.  Conversions are defined here: [SRGB -> FLOAT](numeric-and-data-rules.md#numeric-3-2-3-7) [FLOAT -> SRGB](numeric-and-data-rules.md#numeric-3-2-3-8) If a format with _SRGB has an A channel, the A channel is linear. This modifier is ignored for display scan-out (see [SRGB Display Scan-Out](../archive/D3D11_3_FunctionalSpec.htm#SRGBDisplayScanOut)).<!-- d3d12-review-inline:end:formats:L-modifiers:11 --></ins>

#### `_TYPELESS`

<ins><!-- d3d12-review-inline:begin:formats:L-modifiers:13 -->Typeless format with the component bit counts specified.  When the resource is bound to a Shader, the application's view description must resolve what format to interpret the data as (ordinary family casting preserves the component bit distribution; [named casting exceptions](#casting) are defined separately).<!-- d3d12-review-inline:end:formats:L-modifiers:13 --></ins>

<a id="missing-components"></a>

### Missing components

<ins><!-- d3d12-review-inline:begin:formats:L-missing:0 -->The default value for missing components in an Element format is "0" for any component except A, which gets "1".
The way "1" appears in the Shader depends on the Element format, in that it takes the specified data
interpretation of the first typed component that is actually present in the format (starting from the left in RGBA order).
If this interpretation is UNORM, SNORM, SRGB or FLOAT, then 1.0f is used for missing components.  If the interpretation is SINT or UINT,
then 0x1 is used.<!-- d3d12-review-inline:end:formats:L-missing:0 --></ins>

<ins><!-- d3d12-review-inline:begin:formats:L-missing:1 -->For example, when the format `DXGI_FORMAT_R24_UNORM_X8_TYPELESS` is read into a Shader, the values
for G and B are 0, and A is 1.0f.  For `DXGI_FORMAT_R16G16_UINT`, the B gets 0 and A gets 0x00000001.  `DXGI_FORMAT_R16_SINT` provides 0 for G and B, and 0x00000001 for A.<!-- d3d12-review-inline:end:formats:L-missing:1 --></ins>

<a id="casting"></a>

## Format casting

<ins><!-- d3d12-review-inline:begin:formats:C-typed:0 -->When `D3D12_FEATURE_DATA_D3D12_OPTIONS3.CastingFullyTypedFormatSupported` is true, the runtime supports creating resources
with fully typed formats and subsequently creating UAVs, SRVs, DSVs or
RTVs with any fully qualified format within the same format family. The
views just reinterpret the data in memory as if it is the type in the
view format, ignoring the resource's original format. For
example a resource created with format R8G8B8A8_UNORM can have an
R8G8B8A8_UNORM_SRGB SRV created and the SRV just interprets the data
as if it is UNORM_SRGB.<!-- d3d12-review-inline:end:formats:C-typed:0 --></ins>

<ins><!-- d3d12-review-inline:begin:formats:C-typed:1 -->Support is reported by `ID3D12Device::CheckFeatureSupport` with
`D3D12_FEATURE_D3D12_OPTIONS3`. The associated struct,
`D3D12_FEATURE_DATA_D3D12_OPTIONS3` has a member BOOL
CastingFullyTypedFormatSupported. The runtime reports this capability for drivers supporting the corresponding casting contract.<!-- d3d12-review-inline:end:formats:C-typed:1 --></ins>

Two exceptions to this relaxed casting are:

(1) Casting from _FLOAT to non-_FLOAT formats and vice versa is never
    allowed. For instance casting from R32_FLOAT to/from R32_UINT is
    not allowed.

(2) Casting from _SNORM to _UNORM and vice versa is never allowed.
    This case was missed by the time RS3 shipped, so the runtime doesn't
    validate it. The debug layer will at least print an error.

Some hardware uses different memory compression techniques and/or clear
behaviors across these that could appear as corruption as opposed to the
expected reinterpret-cast.

<ins><!-- d3d12-review-inline:begin:formats:C-clear:0 -->In the ordinary fully typed casting case described here, the fast-clear behavior follows the resource's created format. [Optimized clear values](resources.md#optimized-clear-value) retain their separately typed `Format` definition; this observation does not define a clear operation for typeless resources.
Views that do format casting will just reinterpret the data as if it is
the view format.<!-- d3d12-review-inline:end:formats:C-clear:0 --></ins>

<!-- d3d12-review-alert:begin:formats:N-legacy-cast:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> For ordinary format-family casting without the fully typed casting capability, a fully typed resource retains its own view format; a typeless resource can use compatible typed members of its family. [R32_UINT UAV casting](#r32-uav-casting) and [explicit castable-format lists](#cast-lists) are distinct paths. Casting is reinterpretation of stored bits, not numerical conversion. A view format must also support the requested view use, resource flags, dimension and sample configuration.

<!-- d3d12-review-alert:end:formats:N-legacy-cast:0 -->

<a id="r32-uav-casting"></a>

### Ordinary R32_UINT UAV casting

<!-- d3d12-review-alert:begin:formats:N-r32-casting:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> An `R32_UINT` UAV can reinterpret a UAV-eligible texture created with `R10G10B10A2_TYPELESS`, `R8G8B8A8_TYPELESS`, `B8G8R8A8_TYPELESS`, `B8G8R8X8_TYPELESS`, `R16G16_TYPELESS`, or `R32_TYPELESS`. This is a special UAV interpretation, not permission for arbitrary cross-family SRVs/RTVs or arbitrary equal-byte-size casts. A nonempty explicit cast list takes precedence.

<!-- d3d12-review-alert:end:formats:N-r32-casting:0 -->

<a id="cast-lists"></a>

### Explicit castable-format lists

<!-- d3d12-review-alert:begin:formats:N-resource-operations-format-consumer:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Bit-preserving [copy reinterpretation](resource-operations.md#reinterpret-copy), [clear conversion](resource-operations.md#clear-conversion) and [resolve/transcoding modes](resource-operations.md#resolve-commands) are distinct operation contracts. A view/resource casting permission does not by itself grant an arbitrary equal-byte-size copy or resolve.

<!-- d3d12-review-alert:end:formats:N-resource-operations-format-consumer:0 -->

<!-- d3d12-review-alert:begin:formats:N-common-raw-gather-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The permitted integer aliases are used by [raw gather](common-shader-internals.md#raw-gather) for bitwise element retrieval. That shader operation does not replace the resource/view cast-list creation and compatibility requirements here.

<!-- d3d12-review-alert:end:formats:N-common-raw-gather-behavior:0 -->

<ins><!-- d3d12-review-inline:begin:formats:C-list:0 -->D3D12 provides an API at resource creation to specify a list of castable formats for the resource.<!-- d3d12-review-inline:end:formats:C-list:0 --></ins>

The list
* MAY be empty
* MAY contain uncompressed formats whose unit size matches the resource's format's unit size.
* MAY NOT contain planar formats.
* If the resource's format is non-compressed, then the list may ONLY contain non-compressed formats.

<ins><!-- d3d12-review-inline:begin:formats:C-list:2 -->If the resource's format is compressed, a view casting to an uncompressed format selects one mip. Ordinary array views select one array slice: `MipLevels` and `ArraySize` are 1 where those members exist. Writable and non-array views have their implicit one-mip/non-array extents. Cube-array SRVs use `MipLevels == 1` and `NumCubes == 1`; cube SRVs select one cube with `MipLevels == 1`. This does not require a nonexistent `ArraySize` member on cube or non-array descriptions.<!-- d3d12-review-inline:end:formats:C-list:2 --></ins>

<ins><!-- d3d12-review-inline:begin:formats:C-list:3 -->Apart from the resource's own format, formats outside a nonempty explicit cast list MAY NOT be used as view target formats.<!-- d3d12-review-inline:end:formats:C-list:3 --></ins>

Formats "casted" in this way are _reinterpreted_ as the target format for consumption in shaders.

<ins><!-- d3d12-review-inline:begin:formats:C-list:5 -->The [resource-creation contract](resources.md#initial-layout-and-format-lists) defines `NumCastableFormats`, `pCastableFormats`, and their creation-method applicability.<!-- d3d12-review-inline:end:formats:C-list:5 --></ins>

<!-- d3d12-review-alert:begin:formats:N-list-cap:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A zero-count, null castable-format list retains ordinary format-casting rules. The resource's own format need not be repeated in a nonempty list. Explicit format-list casting requires `D3D12_FEATURE_DATA_D3D12_OPTIONS12.RelaxedFormatCastingSupported`; this is distinct from OPTIONS3's fully typed family casting capability.

<!-- d3d12-review-alert:end:formats:N-list-cap:0 -->

<ins><!-- d3d12-review-inline:begin:formats:C-integer:0 -->To enable retrieval of elements into raw integers,
single-channel unsigned integer resource views can be created
by `ID3D12Device::CreateShaderResourceView`
for resources with identical element bit widths
that have been appropriately flagged at creation.
For example,
a resource view of type `DXGI_FORMAT_R32_UINT`
can be created for a resource of type `DXGI_FORMAT_R8G8B8A8_UINT`
and a resource view of type `DXGI_FORMAT_R16_UINT`
can be created for a resource of type `DXGI_FORMAT_R8G8_UINT`.
Additionally, same-size and same-channel aliasing can be performed
 as with a resource view of type `DXGI_FORMAT_R16_UINT`
 created for a resource of type `DXGI_FORMAT_R16_FLOAT`.<!-- d3d12-review-inline:end:formats:C-integer:0 --></ins>

<ins><!-- d3d12-review-inline:begin:formats:C-integer:1 -->In order to be able to create a single-channel integer resource view,
a resource must be created using the
[CreateCommittedResource3](../D3D12EnhancedBarriers.md#id3d12device10-createcommittedresource3),
[CreatePlacedResource2](../D3D12EnhancedBarriers.md#id3d12device10-createplacedresource2),
or [CreateReservedResource2](resources.md#create-reserved-resource2)
using the API fields, `NumCastableFormats` and `pCastableFormats`
to specify the list of acceptable casts.<!-- d3d12-review-inline:end:formats:C-integer:1 --></ins>

<a id="planes"></a>

## Logical planes and view subresources

<!-- d3d12-review-alert:begin:formats:N-plane-identity:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> View selection uses the [resource's logical subresource identity](resources.md#subresources). A plane index is not a physical byte offset. Plane count, format interpretation and permitted view uses are separate queries/constraints. Depth/stencil and video formats can expose logical planes while their texture storage remains opaque.

<!-- d3d12-review-alert:end:formats:N-plane-identity:0 -->

<ins><!-- d3d12-review-inline:begin:formats:P-depth:0 -->The `DXGI_FORMAT_R24G8_TYPELESS` and `DXGI_FORMAT_R32G8X24_TYPELESS` family of resource/view formats are defined to be planar in D3D12.<!-- d3d12-review-inline:end:formats:P-depth:0 --></ins>

<ins><!-- d3d12-review-inline:begin:formats:P-depth:1 -->Each format has a depth plane as plane 0, and a stencil plane as plane 1. Logical subresource indexing is defined in [Resources and memory](resources.md#subresources).<!-- d3d12-review-inline:end:formats:P-depth:1 --></ins>

<ins><!-- d3d12-review-inline:begin:formats:P-opaque:0 -->Logical plane selection does not reveal the actual memory representation used by Depth and Stencil textures. They are indexed as planar where subresource index is used, independently of the physical representation. Buffer staging layouts are defined below.<!-- d3d12-review-inline:end:formats:P-opaque:0 --></ins>

<a id="depth-stencil-views"></a>

### Depth/stencil view selection

<ins><!-- d3d12-review-inline:begin:formats:P-selection:0 -->Depth/stencil SRV formats select the logical aspect. Non-multisampled 2D and 2D-array SRVs additionally specify the matching `PlaneSlice`; the 1D and multisampled descriptions have no such member. DSV formats identify the depth/stencil components without a `PlaneSlice` member.<!-- d3d12-review-inline:end:formats:P-selection:0 --></ins>

<!-- d3d12-review-alert:begin:formats:P-srv-table:0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Planar Format                     | Logical plane / PlaneSlice where present | SRV Format                           |
> | --------------------------------- | ---------- | ------------------------------------ |
> | **`DXGI_FORMAT_R24G8_TYPELESS`**    | 0          | `DXGI_FORMAT_R24_UNORM_X8_TYPELESS`    |
> | **`DXGI_FORMAT_R24G8_TYPELESS`**    | 1          | `DXGI_FORMAT_X24_TYPELESS_G8_UINT`     |
> | **`DXGI_FORMAT_R32G8X24_TYPELESS`** | 0          | `DXGI_FORMAT_R32_FLOAT_X8X24_TYPELESS` |
> | **`DXGI_FORMAT_R32G8X24_TYPELESS`** | 1          | `DXGI_FORMAT_X32_TYPELESS_G8X24_UINT`  |

<!-- d3d12-review-alert:end:formats:P-srv-table:0 -->

<!-- d3d12-review-alert:begin:formats:P-dsv-table:0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Planar Format                     | Plane covered | DSV Format                       |
>   | --------------------------------- | ---------- | -------------------------------- |
>   | **`DXGI_FORMAT_R24G8_TYPELESS`**    | 0          | `DXGI_FORMAT_D24_UNORM_S8_UINT`    |
>   | **`DXGI_FORMAT_R24G8_TYPELESS`**    | 1          | `DXGI_FORMAT_D24_UNORM_S8_UINT`    |
>   | **`DXGI_FORMAT_R32G8X24_TYPELESS`** | 0          | `DXGI_FORMAT_D32_FLOAT_S8X24_UINT` |
>   | **`DXGI_FORMAT_R32G8X24_TYPELESS`** | 1          | `DXGI_FORMAT_D32_FLOAT_S8X24_UINT` |

<!-- d3d12-review-alert:end:formats:P-dsv-table:0 -->

<!-- d3d12-review-alert:begin:formats:N-dsv-readonly:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12_DSV_FLAG_READ_ONLY_DEPTH` and `D3D12_DSV_FLAG_READ_ONLY_STENCIL` independently prohibit writes to their components. They do not select a different physical plane or change resource access/layout requirements. A read-only DSV can coexist with compatible SRV access to the read-only aspect when [synchronization requirements](synchronization.md#foundations) are satisfied; there is still only one output-merger DSV binding.

<!-- d3d12-review-alert:end:formats:N-dsv-readonly:0 -->

<a id="plane-buffer-layouts"></a>

### Buffer staging representations

<ins><!-- d3d12-review-inline:begin:formats:P-layouts:0 -->Staging to depth and stencil formats uses a planar placed texture data layout. The `CopyTextureRegion` API uses subresource index to identify which plane of the texture (either depth or stencil) that the operation applies to.<!-- d3d12-review-inline:end:formats:P-layouts:0 --></ins>

### `DXGI_FORMAT_R24G8_TYPELESS`

#### Depth Plane

<ins><!-- d3d12-review-inline:begin:formats:P-layouts:3 -->The depth plane placed texture data for this format is 32 bits per element, but only 24 bits are used to express a 24 bit normalized unsigned integer. A format from the `DXGI_FORMAT_R32_TYPELESS` family is used to specify planar depth placed texture data when copying to or from the depth plane of a `DXGI_FORMAT_R24G8_TYPELESS` texture.<!-- d3d12-review-inline:end:formats:P-layouts:3 --></ins>

( ElementAddress + 0 ) : D24X8

Using a least significant bit/most significant bit definition of the entire element:

D24: bits 0-23

X8: bits 24-31 (unused\*)

> Applications must initialize the X8 bits to zero when providing source planar depth placed texture data. Drivers must initialize X8 bits to zero when copying to planar depth placed texture data.

#### Stencil Plane

<ins><!-- d3d12-review-inline:begin:formats:P-layouts:10 -->The stencil plane placed texture data for this format is 8 bits per
element used to express an 8 bit unsigned integer. A format from the
`DXGI_FORMAT_R8_TYPELESS` family is used to specify planar stencil placed
texture data when copying to or from the stencil plane of a
`DXGI_FORMAT_R24G8_TYPELESS` texture.<!-- d3d12-review-inline:end:formats:P-layouts:10 --></ins>

( ElementAddress + 0 ) : S8

  | S8                       | MSB                                 LSB |
  | ------------------------ | --------------------------------------- |
  | ( ComponentAddress + 0 ) | 07 : 06 : 05 : 04 : 03 : 02 : 01 : 00   |

### `DXGI_FORMAT_R32G8X24_TYPELESS`

#### Depth Plane

<ins><!-- d3d12-review-inline:begin:formats:P-layouts:15 -->The depth plane placed texture data for this format is 32 bits per
element used to express a 32 bit floating point value. A format from the
`DXGI_FORMAT_R32_TYPELESS` family is used to specify depth plane placed
texture data when copying to or from the depth plane of a
`DXGI_FORMAT_R32G8X24_TYPELESS` texture.<!-- d3d12-review-inline:end:formats:P-layouts:15 --></ins>

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

<ins><!-- d3d12-review-inline:begin:formats:P-layouts:19 -->The stencil plane placed texture data for this format is 8 bits per element used to express an 8 bit unsigned integer. A format from the `DXGI_FORMAT_R8_TYPELESS` family is used to specify stencil plane placed
texture data when copying to or from the stencil plane of a `DXGI_FORMAT_R32G8X24_TYPELESS` texture.<!-- d3d12-review-inline:end:formats:P-layouts:19 --></ins>

( ElementAddress + 0 ) : S8

  | S8                       | MSB                                 LSB |
  | ------------------------ | --------------------------------------- |
  | ( ComponentAddress + 0 ) | 07 : 06 : 05 : 04 : 03 : 02 : 01 : 00   |

<a id="video-views"></a>

### Video-format views

<ins><!-- d3d12-review-inline:begin:formats:P-video:0 -->For the two-plane NV12/P010/P016 cases, the luma (Y) plane and chroma (UV) plane are selected separately. Developers do this by calling **CreateShaderResourceView** twice for the same texture and passing in 1-channel and 2-channel formats. Passing in a 1-channel format compatible with the Y plane maps only the Y plane. Passing in a 2-channel format compatible with the UV planes (together) maps only the U and V planes as a single resource view.
YUV 4:2:0 formats are listed in [DXGI_FORMAT](https://learn.microsoft.com/en-us/windows/desktop/api/dxgiformat/ne-dxgiformat-dxgi_format).<!-- d3d12-review-inline:end:formats:P-video:0 --></ins>

<!-- d3d12-review-alert:begin:formats:N-video-planes:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> For non-multisampled 2D/array views, `PlaneSlice` and the selected compatible view format identify the same logical plane. NV12, NV11 and P208 use R8_UNORM/R8_UINT for plane 0 and R8G8_UNORM/R8G8_UINT for plane 1. P010/P016 use R16_UNORM/R16_UINT for plane 0 and R16G16_UNORM/R16G16_UINT for plane 1, with the documented R32_UINT UAV interpretation for plane 1. V208/V408 expose three R8 planes, not a universal two-channel UV view.

<!-- d3d12-review-alert:end:formats:N-video-planes:0 -->

<!-- d3d12-review-alert:begin:formats:N-video-planes:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The format entries below define compatible interpretations and possible view kinds, not an unconditional guarantee that every view/use is supported. Resource flags and the relevant format-support bits still apply. Packed video formats have their own mappings; a logical plane does not reveal physical texture layout.

<!-- d3d12-review-alert:end:formats:N-video-planes:1 -->

#### DXGI_FORMAT_AYUV

<ins><!-- d3d12-review-inline:begin:formats:P-video-AYUV:0 -->Most common YUV 4:4:4 video resource format. Valid view formats for this video resource format are DXGI\_FORMAT\_R8G8B8A8\_UNORM and DXGI\_FORMAT\_R8G8B8A8\_UINT. For UAVs, an additional valid view format is DXGI\_FORMAT\_R32\_UINT.  Supported view types are SRV, RTV, and UAV. One view provides a straightforward mapping of the entire surface. The mapping to the view channel is V->R8, U->G8, Y->B8, and A->A8.<!-- d3d12-review-inline:end:formats:P-video-AYUV:0 --></ins>

#### DXGI_FORMAT_Y410

<ins><!-- d3d12-review-inline:begin:formats:P-video-Y410:0 -->10-bit per channel packed YUV 4:4:4 video resource format. Valid view formats for this video resource format are DXGI\_FORMAT\_R10G10B10A2\_UNORM and DXGI\_FORMAT\_R10G10B10A2\_UINT. For UAVs, an additional valid view format is DXGI\_FORMAT\_R32\_UINT.  Supported view types are SRV and UAV. One view provides a straightforward mapping of the entire surface. The mapping to the view channel is U->R10,Y->G10,V->B10,and A->A2.<!-- d3d12-review-inline:end:formats:P-video-Y410:0 --></ins>

#### DXGI_FORMAT_Y416

<ins><!-- d3d12-review-inline:begin:formats:P-video-Y416:0 -->16-bit per channel packed YUV 4:4:4 video resource format. Valid view formats for this video resource format are DXGI\_FORMAT\_R16G16B16A16\_UNORM and DXGI\_FORMAT\_R16G16B16A16\_UINT. Supported view types are SRV and UAV. One view provides a straightforward mapping of the entire surface. The mapping to the view channel is U->R16,Y->G16,V->B16,and A->A16.<!-- d3d12-review-inline:end:formats:P-video-Y416:0 --></ins>

#### DXGI_FORMAT_NV12

<ins><!-- d3d12-review-inline:begin:formats:P-video-NV12:0 -->Most common YUV 4:2:0 video resource format. Valid luminance data view formats for this video resource format are DXGI\_FORMAT\_R8\_UNORM and DXGI\_FORMAT\_R8\_UINT. Valid chrominance data view formats (width and height are each 1/2 of luminance view) for this video resource format are DXGI\_FORMAT\_R8G8\_UNORM and DXGI\_FORMAT\_R8G8\_UINT. Supported view types are SRV, RTV, and UAV. For luminance data view, the mapping to the view channel is Y->R8. For chrominance data view, the mapping to the view channel is U->R8 and V->G8. Width and height must be even.<!-- d3d12-review-inline:end:formats:P-video-NV12:0 --></ins>

#### DXGI_FORMAT_P010

<ins><!-- d3d12-review-inline:begin:formats:P-video-P010:0 -->10-bit per channel planar YUV 4:2:0 video resource format. Valid luminance data view formats for this video resource format are DXGI\_FORMAT\_R16\_UNORM and DXGI\_FORMAT\_R16\_UINT. The runtime does not enforce whether the lowest 6 bits are 0 (given that this video resource format is a 10-bit format that uses 16 bits). If required, application shader code would have to enforce this manually. From the runtime's point of view, DXGI\_FORMAT\_P010 is no different than DXGI\_FORMAT\_P016. Valid chrominance data view formats (width and height are each 1/2 of luminance view) for this video resource format are DXGI\_FORMAT\_R16G16\_UNORM and DXGI\_FORMAT\_R16G16\_UINT. For UAVs, an additional valid chrominance data view format is DXGI\_FORMAT\_R32\_UINT.  Supported view types are SRV, RTV, and UAV. For luminance data view, the mapping to the view channel is Y->R16. For chrominance data view, the mapping to the view channel is U->R16 and V->G16. Width and height must be even.<!-- d3d12-review-inline:end:formats:P-video-P010:0 --></ins>

#### DXGI_FORMAT_P016

<ins><!-- d3d12-review-inline:begin:formats:P-video-P016:0 -->16-bit per channel planar YUV 4:2:0 video resource format. Valid luminance data view formats for this video resource format are DXGI\_FORMAT\_R16\_UNORM and DXGI\_FORMAT\_R16\_UINT. Valid chrominance data view formats (width and height are each 1/2 of luminance view) for this video resource format are DXGI\_FORMAT\_R16G16\_UNORM and DXGI\_FORMAT\_R16G16\_UINT. For UAVs, an additional valid chrominance data view format is DXGI\_FORMAT\_R32\_UINT.  Supported view types are SRV, RTV, and UAV. For luminance data view, the mapping to the view channel is Y->R16. For chrominance data view, the mapping to the view channel is U->R16 and V->G16. Width and height must be even.<!-- d3d12-review-inline:end:formats:P-video-P016:0 --></ins>

#### DXGI_FORMAT_420_OPAQUE

<ins><!-- d3d12-review-inline:begin:formats:P-video-420_OPAQUE:0 -->8-bit per channel planar YUV 4:2:0 video resource format. This format is subsampled where each pixel has its own Y value, but each 2x2 pixel block shares a single U and V value. The runtime requires that the width and height of all resources that are created with this format are multiples of 2. The runtime also requires that the left, right, top, and bottom members of any RECT that are used for this format are multiples of 2. This format differs from DXGI\_FORMAT\_NV12 in that the layout of the data within the resource is completely opaque to applications. Applications cannot use the CPU to map the resource and then access the data within the resource. You cannot use shaders with this format. Because of this behavior, legacy hardware that supports a non-NV12 4:2:0 layout (for example, YV12, and so on) can be used. Also, new hardware that has a 4:2:0 implementation better than NV12 can be used when the application does not need the data to be in a standard layout.  Width and height must be even.<!-- d3d12-review-inline:end:formats:P-video-420_OPAQUE:0 --></ins>

#### DXGI_FORMAT_YUY2

<ins><!-- d3d12-review-inline:begin:formats:P-video-YUY2:0 -->Most common YUV 4:2:2 video resource format. Valid view formats for this video resource format are DXGI\_FORMAT\_R8G8B8A8\_UNORM and DXGI\_FORMAT\_R8G8B8A8\_UINT. For UAVs, an additional valid view format is DXGI\_FORMAT\_R32\_UINT.  Supported view types are SRV and UAV. One view provides a straightforward mapping of the entire surface. The mapping to the view channel is Y0->R8, U0->G8, Y1->B8, and V0->A8.A unique valid view format for this video resource format is DXGI\_FORMAT\_R8G8\_B8G8\_UNORM. With this view format, the width of the view appears to be twice what the DXGI\_FORMAT\_R8G8B8A8\_UNORM or DXGI\_FORMAT\_R8G8B8A8\_UINT view would be when hardware reconstructs RGBA automatically on read and before filtering.  With this view format, the mapping to the view channel is Y0->R8, U0->G8[0], Y1->B8, and V0->G8[1]. Width must be even.<!-- d3d12-review-inline:end:formats:P-video-YUY2:0 --></ins>

#### DXGI_FORMAT_Y210

<ins><!-- d3d12-review-inline:begin:formats:P-video-Y210:0 -->10-bit per channel packed YUV 4:2:2 video resource format. Valid view formats for this video resource format are DXGI\_FORMAT\_R16G16B16A16\_UNORM and DXGI\_FORMAT\_R16G16B16A16\_UINT. The runtime does not enforce whether the lowest 6 bits are 0 (given that this video resource format is a 10-bit format that uses 16 bits). If required, application shader code would have to enforce this manually. From the runtime's point of view, DXGI\_FORMAT\_Y210 is no different than DXGI\_FORMAT\_Y216. Supported view types are SRV and UAV. One view provides a straightforward mapping of the entire surface. The mapping to the view channel is Y0->R16,U->G16,Y1->B16,and V->A16. Width must be even.<!-- d3d12-review-inline:end:formats:P-video-Y210:0 --></ins>

#### DXGI_FORMAT_Y216

<ins><!-- d3d12-review-inline:begin:formats:P-video-Y216:0 -->16-bit per channel packed YUV 4:2:2 video resource format. Valid view formats for this video resource format are DXGI\_FORMAT\_R16G16B16A16\_UNORM and DXGI\_FORMAT\_R16G16B16A16\_UINT. Supported view types are SRV and UAV. One view provides a straightforward mapping of the entire surface. The mapping to the view channel is Y0->R16,U->G16,Y1->B16,and V->A16. Width must be even.<!-- d3d12-review-inline:end:formats:P-video-Y216:0 --></ins>

#### DXGI_FORMAT_NV11

<ins><!-- d3d12-review-inline:begin:formats:P-video-NV11:0 -->Most common planar YUV 4:1:1 video resource format. Valid luminance data view formats for this video resource format are DXGI\_FORMAT\_R8\_UNORM and DXGI\_FORMAT\_R8\_UINT. Valid chrominance data view formats (width is 1/4 of the luminance view and height is unchanged) for this video resource format are DXGI\_FORMAT\_R8G8\_UNORM and DXGI\_FORMAT\_R8G8\_UINT. Supported view types are SRV, RTV, and UAV. For luminance data view, the mapping to the view channel is Y->R8. For chrominance data view, the mapping to the view channel is U->R8 and V->G8. Width must be a multiple of 4.<!-- d3d12-review-inline:end:formats:P-video-NV11:0 --></ins>

<a id="view-descriptions"></a>

## View descriptions

<!-- d3d12-review-alert:begin:formats:N-unions:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `ViewDimension` selects the matching description union member. Texture dimensions must match the resource's kind and sample configuration; cube views use appropriate groups of faces in 2D arrays. SRVs can select a mip range; RTVs, DSVs and UAVs select a single mip, while multisampled views do not select a mip level. View ranges are relative to the selected resource subresources and must remain within their bounds.

<!-- d3d12-review-alert:end:formats:N-unions:0 -->

<!-- d3d12-review-alert:begin:formats:N-ranges-defaults:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Mip and array starts must lie within the resource's corresponding extent. Counts must be nonzero and fit the remaining extent. `UINT_MAX` in the supported `MipLevels`, `ArraySize`, `NumCubes` or `WSize` count field denotes the remaining range from its start, not a sentinel for mip/slice indices or buffer element counts. Cube-array counts consume six faces per cube. A 3D writable view's depth extent at mip `m` is `max(1, Depth >> m)`.

<!-- d3d12-review-alert:end:formats:N-ranges-defaults:0 -->

<!-- d3d12-review-alert:begin:formats:N-ranges-defaults:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> When a null description can be inferred from a texture resource, SRV defaults expose its mip chain and applicable array, with identity mapping and zero minimum-LOD clamp; array resources do not implicitly become cube SRVs. RTV/UAV/DSV defaults select mip zero and the applicable array, or all W slices of that mip for 3D RTV/UAVs. Applicable 2D defaults select plane zero, and default DSV flags are NONE. These defaults do not make otherwise unsupported formats or resource kinds valid.

<!-- d3d12-review-alert:end:formats:N-ranges-defaults:1 -->

<!-- d3d12-review-alert:begin:formats:N-resource-flags:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> SRV creation requires that the resource not deny shader-resource access. RTV, DSV and UAV creation require `D3D12_RESOURCE_FLAG_ALLOW_RENDER_TARGET`, `D3D12_RESOURCE_FLAG_ALLOW_DEPTH_STENCIL` and `D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS`, respectively. The [resource-flag constraints](resources.md#resource-flags) remain applicable. These are resource creation permissions, not descriptor heap types or guarantees of per-format support.

<!-- d3d12-review-alert:end:formats:N-resource-flags:0 -->

<a id="srv-types"></a>

### Shader-resource view types

#### D3D12_SRV_DIMENSION

```cpp
typedef enum D3D12_SRV_DIMENSION {
    D3D12_SRV_DIMENSION_UNKNOWN = 0,
    D3D12_SRV_DIMENSION_BUFFER = 1,
    D3D12_SRV_DIMENSION_TEXTURE1D = 2,
    D3D12_SRV_DIMENSION_TEXTURE1DARRAY = 3,
    D3D12_SRV_DIMENSION_TEXTURE2D = 4,
    D3D12_SRV_DIMENSION_TEXTURE2DARRAY = 5,
    D3D12_SRV_DIMENSION_TEXTURE2DMS = 6,
    D3D12_SRV_DIMENSION_TEXTURE2DMSARRAY = 7,
    D3D12_SRV_DIMENSION_TEXTURE3D = 8,
    D3D12_SRV_DIMENSION_TEXTURECUBE = 9,
    D3D12_SRV_DIMENSION_TEXTURECUBEARRAY = 10,
    D3D12_SRV_DIMENSION_RAYTRACING_ACCELERATION_STRUCTURE = 11,
} D3D12_SRV_DIMENSION;
```

#### D3D12_BUFFER_SRV_FLAGS

```cpp
typedef enum D3D12_BUFFER_SRV_FLAGS
{
    D3D12_BUFFER_SRV_FLAG_NONE = 0,
    D3D12_BUFFER_SRV_FLAG_RAW  = 0x00000001,
} D3D12_BUFFER_SRV_FLAGS;
```

#### D3D12_BUFFER_SRV

```cpp
typedef struct D3D12_BUFFER_SRV
{
    UINT64 FirstElement;
    UINT NumElements;
    UINT StructureByteStride;
    D3D12_BUFFER_SRV_FLAGS Flags;
} D3D12_BUFFER_SRV;
```

#### D3D12_TEX1D_SRV

```cpp
typedef struct D3D12_TEX1D_SRV
{
    UINT MostDetailedMip;
    UINT MipLevels;
    FLOAT ResourceMinLODClamp;
} D3D12_TEX1D_SRV;
```

#### D3D12_TEX1D_ARRAY_SRV

```cpp
typedef struct D3D12_TEX1D_ARRAY_SRV
{
    UINT MostDetailedMip;
    UINT MipLevels;
    UINT FirstArraySlice;
    UINT ArraySize;
    FLOAT ResourceMinLODClamp;
} D3D12_TEX1D_ARRAY_SRV;
```

#### D3D12_TEX2D_SRV

```cpp
typedef struct D3D12_TEX2D_SRV
{
    UINT MostDetailedMip;
    UINT MipLevels;
    UINT PlaneSlice;
    FLOAT ResourceMinLODClamp;
} D3D12_TEX2D_SRV;
```

#### D3D12_TEX2D_ARRAY_SRV

```cpp
typedef struct D3D12_TEX2D_ARRAY_SRV
{
    UINT MostDetailedMip;
    UINT MipLevels;
    UINT FirstArraySlice;
    UINT ArraySize;
    UINT PlaneSlice;
    FLOAT ResourceMinLODClamp;
} D3D12_TEX2D_ARRAY_SRV;
```

#### D3D12_TEX2DMS_SRV

```cpp
typedef struct D3D12_TEX2DMS_SRV
{
    UINT UnusedField_NothingToDefine;
} D3D12_TEX2DMS_SRV;
```

#### D3D12_TEX2DMS_ARRAY_SRV

```cpp
typedef struct D3D12_TEX2DMS_ARRAY_SRV
{
    UINT FirstArraySlice;
    UINT ArraySize;
} D3D12_TEX2DMS_ARRAY_SRV;
```

#### D3D12_TEX3D_SRV

```cpp
typedef struct D3D12_TEX3D_SRV
{
    UINT MostDetailedMip;
    UINT MipLevels;
    FLOAT ResourceMinLODClamp;
} D3D12_TEX3D_SRV;
```

#### D3D12_TEXCUBE_SRV

```cpp
typedef struct D3D12_TEXCUBE_SRV
{
    UINT MostDetailedMip;
    UINT MipLevels;
    FLOAT ResourceMinLODClamp;
} D3D12_TEXCUBE_SRV;
```

#### D3D12_TEXCUBE_ARRAY_SRV

```cpp
typedef struct D3D12_TEXCUBE_ARRAY_SRV
{
    UINT MostDetailedMip;
    UINT MipLevels;
    UINT First2DArrayFace;
    UINT NumCubes;
    FLOAT ResourceMinLODClamp;
} D3D12_TEXCUBE_ARRAY_SRV;
```

#### D3D12_RAYTRACING_ACCELERATION_STRUCTURE_SRV

```cpp
typedef struct D3D12_RAYTRACING_ACCELERATION_STRUCTURE_SRV
{
    D3D12_GPU_VIRTUAL_ADDRESS Location;
} D3D12_RAYTRACING_ACCELERATION_STRUCTURE_SRV;
```

#### D3D12_SHADER_RESOURCE_VIEW_DESC

```cpp
typedef struct D3D12_SHADER_RESOURCE_VIEW_DESC
{
    DXGI_FORMAT Format;
    D3D12_SRV_DIMENSION ViewDimension;
    UINT Shader4ComponentMapping;
    union
    {
        D3D12_BUFFER_SRV Buffer;
        D3D12_TEX1D_SRV Texture1D;
        D3D12_TEX1D_ARRAY_SRV Texture1DArray;
        D3D12_TEX2D_SRV Texture2D;
        D3D12_TEX2D_ARRAY_SRV Texture2DArray;
        D3D12_TEX2DMS_SRV Texture2DMS;
        D3D12_TEX2DMS_ARRAY_SRV Texture2DMSArray;
        D3D12_TEX3D_SRV Texture3D;
        D3D12_TEXCUBE_SRV TextureCube;
        D3D12_TEXCUBE_ARRAY_SRV TextureCubeArray;
        D3D12_RAYTRACING_ACCELERATION_STRUCTURE_SRV RaytracingAccelerationStructure;
    };
} D3D12_SHADER_RESOURCE_VIEW_DESC;
```

<a id="buffer-srv"></a>

### Buffer SRV fields

`FirstElement`

The index of the first element to be accessed by the view.

`NumElements`

<ins><!-- d3d12-review-inline:begin:formats:V-buffer-srv:3 -->The number of elements exposed by the view.<!-- d3d12-review-inline:end:formats:V-buffer-srv:3 --></ins>

`StructureByteStride`

The size of each element in the buffer structure (in bytes) when the buffer represents a structured buffer. The size must match the struct size declared in shaders that access the view.

`Flags`

<ins><!-- d3d12-review-inline:begin:formats:V-buffer-srv:7 -->A [`D3D12_BUFFER_SRV_FLAGS`](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/ne-d3d12-d3d12_buffer_srv_flags)-typed value that identifies view options for the buffer. Currently, the only option is to identify a raw view of the buffer. For more info about raw viewing of buffers, see [Raw Views of Buffers](https://learn.microsoft.com/en-us/windows/desktop/direct3d11/overviews-direct3d-11-resources-intro).<!-- d3d12-review-inline:end:formats:V-buffer-srv:7 --></ins>

<!-- d3d12-review-alert:begin:formats:N-buffer-kinds:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> For typed buffer views, `FirstElement` and `NumElements` count format elements and `StructureByteStride` is zero. Structured views use a nonzero stride and `DXGI_FORMAT_UNKNOWN`; their shader structure layout must match that stride. Raw views use the RAW flag, `DXGI_FORMAT_R32_TYPELESS`, zero structure stride, and 32-bit elements. These interpretations are view properties rather than buffer-creation bind flags. The complete selected byte range must fit the buffer.

<!-- d3d12-review-alert:end:formats:N-buffer-kinds:0 -->

<a id="texture-srv"></a>

### Texture SRV fields

<!-- d3d12-review-alert:begin:formats:N-common-texture-behavior:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The shader uses these view fields through the [common texture-access model](common-shader-internals.md#texture-loads). [Resource-relative LOD clamps](common-shader-internals.md#resource-lod-clamp) define fractional and empty-set behavior; the view description here remains the owner of field representation and validation.

<!-- d3d12-review-alert:end:formats:N-common-texture-behavior:0 -->

`MostDetailedMip`

Index of the most detailed mipmap level to use; this number is between 0 and **MipLevels** -1 (where **MipLevels** is from the original Texture2D for which [ID3D12Device::CreateShaderResourceView](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nf-d3d12-id3d12device-createshaderresourceview) creates a view).

`MipLevels`

<ins><!-- d3d12-review-inline:begin:formats:V-texture-srv:3 -->The maximum number of mipmap levels for the view of the texture. See the remarks in [`D3D12_TEX1D_SRV`](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/ns-d3d12-d3d12_tex1d_srv).<!-- d3d12-review-inline:end:formats:V-texture-srv:3 --></ins>

Set to -1 to indicate all the mipmap levels from **MostDetailedMip** on down to least detailed.

`FirstArraySlice`

The index of the first texture to use in an array of textures.

`ArraySize`

Number of textures in the array.

`PlaneSlice`

The index (plane slice number) of the plane to use in an array of textures.

`ResourceMinLODClamp`

Specifies the minimum mipmap level that you can access. Specifying 0.0f means that you can access all of the mipmap levels. Specifying 3.0f means that you can access mipmap levels from 3.0f to *MipCount - 1*.

<ins><!-- d3d12-review-inline:begin:formats:L-lod-space:0 -->The SRV's `ResourceMinLODClamp` considers the most detailed mipmap on the resource as LOD 0, so specifying a MinLOD clamp of 1 causes miplevel 0 on the resource to be ignored.
On the other hand, the Sampler’s MinLOD clamp defines most detailed mipmap in the current Shader Resource View as LOD 0.
So on a Shader Resource View that, for example, limits a mipmap chain to exclude the most detailed 3 mips from a resource, setting the Sampler MinLOD to 1
causes miplevel [3] (the fourth mip) in the resource to be ignored.<!-- d3d12-review-inline:end:formats:L-lod-space:0 --></ins>

<!-- d3d12-review-alert:begin:formats:N-srv-shapes:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The corresponding 1D, 2D, 3D and cube SRV descriptions use the same mip-window and minimum-LOD-clamp fields. Array forms add `FirstArraySlice`/`ArraySize`; cube-array views instead use `First2DArrayFace` and `NumCubes`, counting groups of six 2D faces. Multisampled array SRVs select only `FirstArraySlice` and `ArraySize`. The non-array multisample member's `UnusedField_NothingToDefine` carries no view-selection data.

<!-- d3d12-review-alert:end:formats:N-srv-shapes:0 -->

<a id="component-mapping"></a>

### Component mapping

<ins><!-- d3d12-review-inline:begin:formats:V-mapping:0 -->`Shader4ComponentMapping` allows the SRV to
choose how memory gets routed to the 4 return components in a shader
after a memory fetch. The options for each shader component [0..3]
(RGBA) are: component 0..3 from the SRV fetch result or force 0 or force 1. The value of forcing 1 is either 0x1 or 1.0f depending on the format
type for that component in the source format.<!-- d3d12-review-inline:end:formats:V-mapping:0 --></ins>

<ins><!-- d3d12-review-inline:begin:formats:V-mapping:1 -->The default 1:1 mapping can be indicated by specifying
`D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING`, otherwise an arbitrary
mapping can be specified using the macro
`D3D12_ENCODE_SHADER_4_COMPONENT_MAPPING`. The encoding macros are shown below.<!-- d3d12-review-inline:end:formats:V-mapping:1 --></ins>

#### D3D12_SHADER_COMPONENT_MAPPING

```cpp
typedef enum D3D12_SHADER_COMPONENT_MAPPING
{
    D3D12_SHADER_COMPONENT_MAPPING_FROM_MEMORY_COMPONENT_0 = 0,
    D3D12_SHADER_COMPONENT_MAPPING_FROM_MEMORY_COMPONENT_1 = 1,
    D3D12_SHADER_COMPONENT_MAPPING_FROM_MEMORY_COMPONENT_2 = 2,
    D3D12_SHADER_COMPONENT_MAPPING_FROM_MEMORY_COMPONENT_3 = 3,
    D3D12_SHADER_COMPONENT_MAPPING_FORCE_VALUE_0 = 4,
    D3D12_SHADER_COMPONENT_MAPPING_FORCE_VALUE_1 = 5,
} D3D12_SHADER_COMPONENT_MAPPING;
```

```cpp
#define D3D12_SHADER_COMPONENT_MAPPING_MASK 0x7
#define D3D12_SHADER_COMPONENT_MAPPING_SHIFT 3
#define D3D12_SHADER_COMPONENT_MAPPING_ALWAYS_SET_BIT_AVOIDING_ZEROMEM_MISTAKES (1<<(D3D12_SHADER_COMPONENT_MAPPING_SHIFT*4))
#define D3D12_ENCODE_SHADER_4_COMPONENT_MAPPING(Src0,Src1,Src2,Src3) ((((Src0)&D3D12_SHADER_COMPONENT_MAPPING_MASK)| \
                                                                (((Src1)&D3D12_SHADER_COMPONENT_MAPPING_MASK)<<D3D12_SHADER_COMPONENT_MAPPING_SHIFT)| \
                                                                (((Src2)&D3D12_SHADER_COMPONENT_MAPPING_MASK)<<(D3D12_SHADER_COMPONENT_MAPPING_SHIFT*2))| \
                                                                (((Src3)&D3D12_SHADER_COMPONENT_MAPPING_MASK)<<(D3D12_SHADER_COMPONENT_MAPPING_SHIFT*3))| \
                                                                D3D12_SHADER_COMPONENT_MAPPING_ALWAYS_SET_BIT_AVOIDING_ZEROMEM_MISTAKES))
#define D3D12_DECODE_SHADER_4_COMPONENT_MAPPING(ComponentToExtract,Mapping) ((D3D12_SHADER_COMPONENT_MAPPING)(Mapping >> (D3D12_SHADER_COMPONENT_MAPPING_SHIFT*ComponentToExtract) & D3D12_SHADER_COMPONENT_MAPPING_MASK))
#define D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING D3D12_ENCODE_SHADER_4_COMPONENT_MAPPING(0,1,2,3)
```

<!-- d3d12-review-alert:begin:formats:N-mapping-order:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The four mapping selectors choose fetched components or force zero/one; selector values must be from zero through five and the reserved always-set bit is required. Bits outside the four three-bit selectors and required marker must be zero. `D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING` encodes the identity mapping rather than zero; raw and structured buffer SRVs require that default mapping. Missing-format-component defaults are distinct from explicitly forcing a component. [Acceleration-structure SRVs](binding.md#acceleration-structure-srvs) use their GPU-address binding contract rather than ordinary texture component interpretation.

<!-- d3d12-review-alert:end:formats:N-mapping-order:0 -->

<a id="uav-types"></a>

### Unordered-access view types

#### D3D12_UAV_DIMENSION

```cpp
typedef enum D3D12_UAV_DIMENSION
{
    D3D12_UAV_DIMENSION_UNKNOWN = 0,
    D3D12_UAV_DIMENSION_BUFFER = 1,
    D3D12_UAV_DIMENSION_TEXTURE1D = 2,
    D3D12_UAV_DIMENSION_TEXTURE1DARRAY = 3,
    D3D12_UAV_DIMENSION_TEXTURE2D = 4,
    D3D12_UAV_DIMENSION_TEXTURE2DARRAY = 5,
    D3D12_UAV_DIMENSION_TEXTURE2DMS = 6,
    D3D12_UAV_DIMENSION_TEXTURE2DMSARRAY = 7,
    D3D12_UAV_DIMENSION_TEXTURE3D = 8,
} D3D12_UAV_DIMENSION;
```

#### D3D12_BUFFER_UAV_FLAGS

```cpp
typedef enum D3D12_BUFFER_UAV_FLAGS
{
    D3D12_BUFFER_UAV_FLAG_NONE =   0,
    D3D12_BUFFER_UAV_FLAG_RAW  =   0x00000001,
} D3D12_BUFFER_UAV_FLAGS;
```

#### D3D12_BUFFER_UAV

```cpp
typedef struct D3D12_BUFFER_UAV
{
    UINT64 FirstElement;
    UINT NumElements;
    UINT StructureByteStride;
    UINT64 CounterOffsetInBytes;
    D3D12_BUFFER_UAV_FLAGS Flags;
} D3D12_BUFFER_UAV;
```

#### D3D12_TEX1D_UAV

```cpp
typedef struct D3D12_TEX1D_UAV
{
    UINT MipSlice;
} D3D12_TEX1D_UAV;
```

#### D3D12_TEX1D_ARRAY_UAV

```cpp
typedef struct D3D12_TEX1D_ARRAY_UAV
{
    UINT MipSlice;
    UINT FirstArraySlice;
    UINT ArraySize;
} D3D12_TEX1D_ARRAY_UAV;
```

#### D3D12_TEX2D_UAV

```cpp
typedef struct D3D12_TEX2D_UAV
{
    UINT MipSlice;
    UINT PlaneSlice;
} D3D12_TEX2D_UAV;
```

#### D3D12_TEX2D_ARRAY_UAV

```cpp
typedef struct D3D12_TEX2D_ARRAY_UAV
{
    UINT MipSlice;
    UINT FirstArraySlice;
    UINT ArraySize;
    UINT PlaneSlice;
} D3D12_TEX2D_ARRAY_UAV;
```

#### D3D12_TEX2DMS_UAV

```cpp
typedef struct D3D12_TEX2DMS_UAV
{
    UINT UnusedField_NothingToDefine;
} D3D12_TEX2DMS_UAV;
```

#### D3D12_TEX2DMS_ARRAY_UAV

```cpp
typedef struct D3D12_TEX2DMS_ARRAY_UAV
{
    UINT FirstArraySlice;
    UINT ArraySize;
} D3D12_TEX2DMS_ARRAY_UAV;
```

#### D3D12_TEX3D_UAV

```cpp
typedef struct D3D12_TEX3D_UAV
{
    UINT MipSlice;
    UINT FirstWSlice;
    UINT WSize;
} D3D12_TEX3D_UAV;
```

#### D3D12_UNORDERED_ACCESS_VIEW_DESC

```cpp
typedef struct D3D12_UNORDERED_ACCESS_VIEW_DESC
{
    DXGI_FORMAT Format;
    D3D12_UAV_DIMENSION ViewDimension;
    union
    {
        D3D12_BUFFER_UAV Buffer;
        D3D12_TEX1D_UAV Texture1D;
        D3D12_TEX1D_ARRAY_UAV Texture1DArray;
        D3D12_TEX2D_UAV Texture2D;
        D3D12_TEX2D_ARRAY_UAV Texture2DArray;
        D3D12_TEX2DMS_UAV Texture2DMS;
        D3D12_TEX2DMS_ARRAY_UAV Texture2DMSArray;
        D3D12_TEX3D_UAV Texture3D;
    };
} D3D12_UNORDERED_ACCESS_VIEW_DESC;
```

<a id="buffer-uav"></a>

### Buffer UAV fields and counters

`FirstElement`

The zero-based index of the first element to be accessed.

`NumElements`

<ins><!-- d3d12-review-inline:begin:formats:V-buffer-uav:3 -->The number of elements exposed by the view. For structured buffers, this is the number of structures in the buffer.<!-- d3d12-review-inline:end:formats:V-buffer-uav:3 --></ins>

`StructureByteStride`

The size of each element in the buffer structure (in bytes) when the buffer represents a structured buffer.

`CounterOffsetInBytes`

The counter offset, in bytes.

`Flags`

<ins><!-- d3d12-review-inline:begin:formats:V-buffer-uav:9 -->A [`D3D12_BUFFER_UAV_FLAGS`](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/ne-d3d12-d3d12_buffer_uav_flags)-typed value that specifies the view options for the resource.<!-- d3d12-review-inline:end:formats:V-buffer-uav:9 --></ins>

<!-- d3d12-review-alert:begin:formats:N-counters:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A counter is associated by the `pCounterResource` creation parameter, not an APPEND/COUNTER bit in `D3D12_BUFFER_UAV_FLAGS`. `CounterOffsetInBytes` identifies its storage; the [creation contract](#id3d12device-createunorderedaccessview) defines the structured-view, resource, placement and bounds restrictions. Counter storage and counter values do not follow automatically from binding a UAV; [command-list state](command-list-state.md#buffer-bindings) remains independent.

<!-- d3d12-review-alert:end:formats:N-counters:0 -->

<!-- d3d12-review-alert:begin:formats:N-buffer-validity:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Buffer views require a nonzero element count and a nonoverflowing byte range within the buffer. Raw-view starting addresses must satisfy `D3D12_RAW_UAV_SRV_BYTE_ALIGNMENT` (16 bytes); element indexing is still in 32-bit units. A UAV counter offset must satisfy `D3D12_UAV_COUNTER_PLACEMENT_ALIGNMENT` (4096 bytes) and leave four bytes available in its backing buffer. Both data and counter buffers require UAV permission. With no counter resource, `CounterOffsetInBytes` is zero.

<!-- d3d12-review-alert:end:formats:N-buffer-validity:0 -->

<a id="texture-uav"></a>

### Texture UAV fields

#### Array and plane fields

`MipSlice`

The mipmap slice index.

`FirstArraySlice`

The zero-based index of the first array slice to be accessed.

`ArraySize`

The number of slices in the array.

`PlaneSlice`

The index (plane slice number) of the plane to use in an array of textures.

#### Volume depth-slice fields

`MipSlice`

The mipmap slice index.

`FirstWSlice`

The zero-based index of the first depth slice to be accessed.

`WSize`

The number of depth slices.

Set to -1 to indicate all the depth slices from **FirstWSlice** to the last slice.

<!-- d3d12-review-alert:begin:formats:N-uav-shapes:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Non-array 1D/2D UAVs select `MipSlice`; 2D forms additionally select `PlaneSlice`. Array forms select a range with `FirstArraySlice` and `ArraySize`. Multisampled UAVs use their MS or MSArray members and require `D3D12_FEATURE_DATA_D3D12_OPTIONS14.WriteableMSAATexturesSupported`; their backing resource also follows the [writable-MSAA creation requirements](resources.md#writable-msaa). A 3D UAV selects depth slices at its selected mip, not array subresources.

<!-- d3d12-review-alert:end:formats:N-uav-shapes:0 -->

<a id="rtv-types"></a>

### Render-target view types and fields

#### D3D12_RTV_DIMENSION

```cpp
typedef enum D3D12_RTV_DIMENSION
{
    D3D12_RTV_DIMENSION_UNKNOWN = 0,
    D3D12_RTV_DIMENSION_BUFFER = 1,
    D3D12_RTV_DIMENSION_TEXTURE1D = 2,
    D3D12_RTV_DIMENSION_TEXTURE1DARRAY = 3,
    D3D12_RTV_DIMENSION_TEXTURE2D = 4,
    D3D12_RTV_DIMENSION_TEXTURE2DARRAY = 5,
    D3D12_RTV_DIMENSION_TEXTURE2DMS = 6,
    D3D12_RTV_DIMENSION_TEXTURE2DMSARRAY = 7,
    D3D12_RTV_DIMENSION_TEXTURE3D = 8,
} D3D12_RTV_DIMENSION;
```

#### D3D12_BUFFER_RTV

```cpp
typedef struct D3D12_BUFFER_RTV
{
    UINT64 FirstElement;
    UINT NumElements;
} D3D12_BUFFER_RTV;
```

#### D3D12_TEX1D_RTV

```cpp
typedef struct D3D12_TEX1D_RTV
{
    UINT MipSlice;
} D3D12_TEX1D_RTV;
```

#### D3D12_TEX1D_ARRAY_RTV

```cpp
typedef struct D3D12_TEX1D_ARRAY_RTV
{
    UINT MipSlice;
    UINT FirstArraySlice;
    UINT ArraySize;
} D3D12_TEX1D_ARRAY_RTV;
```

#### D3D12_TEX2D_RTV

```cpp
typedef struct D3D12_TEX2D_RTV
{
    UINT MipSlice;
    UINT PlaneSlice;
} D3D12_TEX2D_RTV;
```

#### D3D12_TEX2D_ARRAY_RTV

```cpp
typedef struct D3D12_TEX2D_ARRAY_RTV
{
    UINT MipSlice;
    UINT FirstArraySlice;
    UINT ArraySize;
    UINT PlaneSlice;
} D3D12_TEX2D_ARRAY_RTV;
```

#### D3D12_TEX2DMS_RTV

```cpp
typedef struct D3D12_TEX2DMS_RTV
{
    UINT UnusedField_NothingToDefine;
} D3D12_TEX2DMS_RTV;
```

#### D3D12_TEX2DMS_ARRAY_RTV

```cpp
typedef struct D3D12_TEX2DMS_ARRAY_RTV
{
    UINT FirstArraySlice;
    UINT ArraySize;
} D3D12_TEX2DMS_ARRAY_RTV;
```

#### D3D12_TEX3D_RTV

```cpp
typedef struct D3D12_TEX3D_RTV
{
    UINT MipSlice;
    UINT FirstWSlice;
    UINT WSize;
} D3D12_TEX3D_RTV;
```

#### D3D12_RENDER_TARGET_VIEW_DESC

```cpp
typedef struct D3D12_RENDER_TARGET_VIEW_DESC
{
    DXGI_FORMAT Format;
    D3D12_RTV_DIMENSION ViewDimension;
    union
    {
        D3D12_BUFFER_RTV Buffer;
        D3D12_TEX1D_RTV Texture1D;
        D3D12_TEX1D_ARRAY_RTV Texture1DArray;
        D3D12_TEX2D_RTV Texture2D;
        D3D12_TEX2D_ARRAY_RTV Texture2DArray;
        D3D12_TEX2DMS_RTV Texture2DMS;
        D3D12_TEX2DMS_ARRAY_RTV Texture2DMSArray;
        D3D12_TEX3D_RTV Texture3D;
    };
} D3D12_RENDER_TARGET_VIEW_DESC;
```

#### Buffer RTV fields

`FirstElement`

Number of elements between the beginning of the buffer and the first element to access.

`NumElements`

The total number of elements in the view.

<!-- d3d12-review-alert:begin:formats:N-buffer-rtv-limit:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> A buffer RTV's `NumElements` must not exceed `D3D12_REQ_TEXTURE1D_U_DIMENSION` (16384), even when the backing buffer is larger. `FirstElement` and `NumElements` still define a valid typed-element range within that buffer.

<!-- d3d12-review-alert:end:formats:N-buffer-rtv-limit:0 -->

#### Array and plane RTV fields

`MipSlice`

<ins><!-- d3d12-review-inline:begin:formats:V-texture-rtv:1 -->The index of the mipmap level to use.<!-- d3d12-review-inline:end:formats:V-texture-rtv:1 --></ins>

`FirstArraySlice`

The index of the first texture to use in an array of textures.

`ArraySize`

Number of textures in the array to use in the render target view, starting from **FirstArraySlice**.

`PlaneSlice`

The index (plane slice number) of the plane to use in an array of textures.

#### Volume depth-slice RTV fields

`MipSlice`

<ins><!-- d3d12-review-inline:begin:formats:V-volume-rtv:1 -->The index of the mipmap level to use.<!-- d3d12-review-inline:end:formats:V-volume-rtv:1 --></ins>

`FirstWSlice`

First depth level to use.

`WSize`

Number of depth levels to use in the render-target view, starting from **FirstWSlice**. A value of -1 indicates all of the slices along the w axis, starting from **FirstWSlice**.

<!-- d3d12-review-alert:begin:formats:N-rtv-shapes:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The remaining RTV variants use the corresponding declared mip and array selectors. Multisampled RTVs select the MS/MSArray member without a mip selector. Buffer RTV elements use the selected typed format; there is no raw or structured RTV flag. 3D RTV `FirstWSlice`/`WSize` refer to depth slices of the selected mip.

<!-- d3d12-review-alert:end:formats:N-rtv-shapes:0 -->

<a id="dsv-types"></a>

### Depth-stencil view types and fields

<!-- d3d12-review-alert:begin:formats:N-om-read-only-view-consumer:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Depth/stencil view flags participate in the [output-merger read-only write controls](output-merger.md#read-only-depth-stencil). [Render-pass read-only binding](output-merger.md#read-only-depth-stencil-pass) has additional flag/access conditions; descriptor creation here does not erase the resource's access/layout requirements.

<!-- d3d12-review-alert:end:formats:N-om-read-only-view-consumer:0 -->

#### D3D12_DSV_DIMENSION

```cpp
typedef enum D3D12_DSV_DIMENSION
{
    D3D12_DSV_DIMENSION_UNKNOWN = 0,
    D3D12_DSV_DIMENSION_TEXTURE1D = 1,
    D3D12_DSV_DIMENSION_TEXTURE1DARRAY = 2,
    D3D12_DSV_DIMENSION_TEXTURE2D = 3,
    D3D12_DSV_DIMENSION_TEXTURE2DARRAY = 4,
    D3D12_DSV_DIMENSION_TEXTURE2DMS = 5,
    D3D12_DSV_DIMENSION_TEXTURE2DMSARRAY = 6,
} D3D12_DSV_DIMENSION;
```

#### D3D12_DSV_FLAGS

```cpp
typedef enum D3D12_DSV_FLAGS
{
    D3D12_DSV_FLAG_NONE              = 0x0,
    D3D12_DSV_FLAG_READ_ONLY_DEPTH   = 0x1,
    D3D12_DSV_FLAG_READ_ONLY_STENCIL = 0x2,
} D3D12_DSV_FLAGS;
```

#### D3D12_TEX1D_DSV

```cpp
typedef struct D3D12_TEX1D_DSV
{
    UINT MipSlice;
} D3D12_TEX1D_DSV;
```

#### D3D12_TEX1D_ARRAY_DSV

```cpp
typedef struct D3D12_TEX1D_ARRAY_DSV
{
    UINT MipSlice;
    UINT FirstArraySlice;
    UINT ArraySize;
} D3D12_TEX1D_ARRAY_DSV;
```

#### D3D12_TEX2D_DSV

```cpp
typedef struct D3D12_TEX2D_DSV
{
    UINT MipSlice;
} D3D12_TEX2D_DSV;
```

#### D3D12_TEX2D_ARRAY_DSV

```cpp
typedef struct D3D12_TEX2D_ARRAY_DSV
{
    UINT MipSlice;
    UINT FirstArraySlice;
    UINT ArraySize;
} D3D12_TEX2D_ARRAY_DSV;
```

#### D3D12_TEX2DMS_DSV

```cpp
typedef struct D3D12_TEX2DMS_DSV
{
    UINT UnusedField_NothingToDefine;
} D3D12_TEX2DMS_DSV;
```

#### D3D12_TEX2DMS_ARRAY_DSV

```cpp
typedef struct D3D12_TEX2DMS_ARRAY_DSV
{
    UINT FirstArraySlice;
    UINT ArraySize;
} D3D12_TEX2DMS_ARRAY_DSV;
```

#### D3D12_DEPTH_STENCIL_VIEW_DESC

```cpp
typedef struct D3D12_DEPTH_STENCIL_VIEW_DESC
{
    DXGI_FORMAT Format;
    D3D12_DSV_DIMENSION ViewDimension;
    D3D12_DSV_FLAGS Flags;
    union
    {
        D3D12_TEX1D_DSV Texture1D;
        D3D12_TEX1D_ARRAY_DSV Texture1DArray;
        D3D12_TEX2D_DSV Texture2D;
        D3D12_TEX2D_ARRAY_DSV Texture2DArray;
        D3D12_TEX2DMS_DSV Texture2DMS;
        D3D12_TEX2DMS_ARRAY_DSV Texture2DMSArray;
    };
} D3D12_DEPTH_STENCIL_VIEW_DESC;
```

`MipSlice`

The index of the first mipmap level to use.

`FirstArraySlice`

The index of the first texture to use in an array of textures.

`ArraySize`

Number of textures to use.

<!-- d3d12-review-alert:begin:formats:N-dsv-shapes:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> DSVs select 1D/2D, array, or multisampled variants; they do not expose buffer, 3D, or cube-specific dimensions. A cube resource's faces can be viewed through a compatible 2D-array description. `Flags` combines the [aspect read-only flags](#depth-stencil-views). DSVs do not have a `PlaneSlice` member.

<!-- d3d12-review-alert:end:formats:N-dsv-shapes:0 -->

<a id="support"></a>

## Format support and capability queries

<!-- d3d12-review-alert:begin:formats:N-support:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [feature-discovery contract](devices-and-capabilities.md#feature-discovery) defines `ID3D12Device::CheckFeatureSupport`. The format-specific payloads below expose independent capabilities; a plane count or a successful query does not by itself permit every view or operation. Resource flags, casting, view shape and stage/operation conditions still apply.

<!-- d3d12-review-alert:end:formats:N-support:0 -->

<a id="check-feature-support"></a>

### Feature-query dispatch and selected diagnostics

<a id="id3d12devicecheckfeaturesupport"></a>

<!-- d3d12-review-alert:begin:formats:N-device-query-owner:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The complete `ID3D12Device::CheckFeatureSupport` declaration, dispatch, payload-size and negotiation contract is defined in [Devices and capabilities](devices-and-capabilities.md#id3d12device-checkfeaturesupport). The format/MSAA-specific query cases and diagnostics remain defined here.

<!-- d3d12-review-alert:end:formats:N-device-query-owner:1 -->

#### Runtime validation for the selected query cases

<!-- d3d12-review-alert:begin:formats:N-query-errors:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> For the format-specific cases below, a payload-size mismatch returns `E_INVALIDARG`. `D3D12_FEATURE_FORMAT_INFO` rejects nonexistent API format values with `E_INVALIDARG`. `D3D12_FEATURE_FORMAT_SUPPORT` initializes its output masks to NONE and returns `E_FAIL` when format support cannot be computed or no support is reported.

<!-- d3d12-review-alert:end:formats:N-query-errors:0 -->

<!-- d3d12-review-alert:begin:formats:N-query-errors:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12_FEATURE_MULTISAMPLE_QUALITY_LEVELS` returns `E_FAIL` if its support calculation fails, including `SampleCount == 0` or counts exceeding the supported API maximum of 32. Unsupported configurations and tiled-resource restrictions can instead produce a successful query with `NumQualityLevels == 0`; that differs from an invalid-count failure. No unsupported configuration is made legal by a successful query returning zero.

<!-- d3d12-review-alert:end:formats:N-query-errors:1 -->

<a id="format-query-cases"></a>

### Selected format queries

<!-- d3d12-review-alert:begin:formats:N-query-cases:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Feature | Payload | Input/output |
> |---|---|---|
> | `D3D12_FEATURE_FORMAT_SUPPORT` | `D3D12_FEATURE_DATA_FORMAT_SUPPORT` | Input `Format`; output `Support1` and `Support2` |
> | `D3D12_FEATURE_FORMAT_INFO` | `D3D12_FEATURE_DATA_FORMAT_INFO` | Input `Format`; output logical `PlaneCount` |
> | `D3D12_FEATURE_MULTISAMPLE_QUALITY_LEVELS` | `D3D12_FEATURE_DATA_MULTISAMPLE_QUALITY_LEVELS` | Input `Format`, `SampleCount`, `Flags`; output `NumQualityLevels` |

<!-- d3d12-review-alert:end:formats:N-query-cases:0 -->

<!-- d3d12-review-alert:begin:formats:N-query-cases:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> These query cases require the corresponding exact payload size. `NumQualityLevels` describes quality indices from zero through `NumQualityLevels - 1` when nonzero; zero does not establish a supported multisample configuration.

<!-- d3d12-review-alert:end:formats:N-query-cases:1 -->

<!-- d3d12-review-alert:begin:formats:FQ-api-driver-forward:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The [current driver queries](#driver-format-queries) provide optional-format flags and multisample quality data. Their [driver-mask/API-mask relationship](#driver-format-mask) is not raw bitwise identity.

<!-- d3d12-review-alert:end:formats:FQ-api-driver-forward:0 -->

#### D3D12_FORMAT_SUPPORT1

```cpp
typedef enum D3D12_FORMAT_SUPPORT1
{
    D3D12_FORMAT_SUPPORT1_NONE                       = 0,
    D3D12_FORMAT_SUPPORT1_BUFFER                      = 0x00000001,
    D3D12_FORMAT_SUPPORT1_IA_VERTEX_BUFFER            = 0x00000002,
    D3D12_FORMAT_SUPPORT1_IA_INDEX_BUFFER             = 0x00000004,
    D3D12_FORMAT_SUPPORT1_SO_BUFFER                   = 0x00000008,
    D3D12_FORMAT_SUPPORT1_TEXTURE1D                   = 0x00000010,
    D3D12_FORMAT_SUPPORT1_TEXTURE2D                   = 0x00000020,
    D3D12_FORMAT_SUPPORT1_TEXTURE3D                   = 0x00000040,
    D3D12_FORMAT_SUPPORT1_TEXTURECUBE                 = 0x00000080,
    D3D12_FORMAT_SUPPORT1_SHADER_LOAD                 = 0x00000100,
    D3D12_FORMAT_SUPPORT1_SHADER_SAMPLE               = 0x00000200,
    D3D12_FORMAT_SUPPORT1_SHADER_SAMPLE_COMPARISON    = 0x00000400,
    D3D12_FORMAT_SUPPORT1_SHADER_SAMPLE_MONO_TEXT     = 0x00000800,
    D3D12_FORMAT_SUPPORT1_MIP                         = 0x00001000,
    D3D12_FORMAT_SUPPORT1_RENDER_TARGET               = 0x00004000,
    D3D12_FORMAT_SUPPORT1_BLENDABLE                   = 0x00008000,
    D3D12_FORMAT_SUPPORT1_DEPTH_STENCIL               = 0x00010000,
    D3D12_FORMAT_SUPPORT1_MULTISAMPLE_RESOLVE         = 0x00040000,
    D3D12_FORMAT_SUPPORT1_DISPLAY                     = 0x00080000,
    D3D12_FORMAT_SUPPORT1_CAST_WITHIN_BIT_LAYOUT      = 0x00100000,
    D3D12_FORMAT_SUPPORT1_MULTISAMPLE_RENDERTARGET    = 0x00200000,
    D3D12_FORMAT_SUPPORT1_MULTISAMPLE_LOAD            = 0x00400000,
    D3D12_FORMAT_SUPPORT1_SHADER_GATHER               = 0x00800000,
    D3D12_FORMAT_SUPPORT1_BACK_BUFFER_CAST            = 0x01000000,
    D3D12_FORMAT_SUPPORT1_TYPED_UNORDERED_ACCESS_VIEW = 0x02000000,
    D3D12_FORMAT_SUPPORT1_SHADER_GATHER_COMPARISON    = 0x04000000,
    D3D12_FORMAT_SUPPORT1_DECODER_OUTPUT              = 0x08000000,
    D3D12_FORMAT_SUPPORT1_VIDEO_PROCESSOR_OUTPUT      = 0x10000000,
    D3D12_FORMAT_SUPPORT1_VIDEO_PROCESSOR_INPUT       = 0x20000000,
    D3D12_FORMAT_SUPPORT1_VIDEO_ENCODER               = 0x40000000,
} D3D12_FORMAT_SUPPORT1;
```

#### D3D12_FORMAT_SUPPORT2

```cpp
typedef enum D3D12_FORMAT_SUPPORT2
{
    D3D12_FORMAT_SUPPORT2_NONE                                              = 0,
    D3D12_FORMAT_SUPPORT2_UAV_ATOMIC_ADD                                    = 0x00000001,
    D3D12_FORMAT_SUPPORT2_UAV_ATOMIC_BITWISE_OPS                            = 0x00000002,
    D3D12_FORMAT_SUPPORT2_UAV_ATOMIC_COMPARE_STORE_OR_COMPARE_EXCHANGE      = 0x00000004,
    D3D12_FORMAT_SUPPORT2_UAV_ATOMIC_EXCHANGE                               = 0x00000008,
    D3D12_FORMAT_SUPPORT2_UAV_ATOMIC_SIGNED_MIN_OR_MAX                      = 0x00000010,
    D3D12_FORMAT_SUPPORT2_UAV_ATOMIC_UNSIGNED_MIN_OR_MAX                    = 0x00000020,
    D3D12_FORMAT_SUPPORT2_UAV_TYPED_LOAD                                    = 0x00000040,
    D3D12_FORMAT_SUPPORT2_UAV_TYPED_STORE                                   = 0x00000080,
    D3D12_FORMAT_SUPPORT2_OUTPUT_MERGER_LOGIC_OP                            = 0x00000100,
    D3D12_FORMAT_SUPPORT2_TILED                                             = 0x00000200,
    D3D12_FORMAT_SUPPORT2_MULTIPLANE_OVERLAY                                = 0x00004000,
    D3D12_FORMAT_SUPPORT2_SAMPLER_FEEDBACK                                  = 0x00008000,
    D3D12_FORMAT_SUPPORT2_DISPLAYABLE                                       = 0x00010000,
} D3D12_FORMAT_SUPPORT2;
```

#### D3D12_FEATURE_DATA_FORMAT_SUPPORT

```cpp
typedef struct D3D12_FEATURE_DATA_FORMAT_SUPPORT
{
    DXGI_FORMAT Format;
    D3D12_FORMAT_SUPPORT1 Support1;
    D3D12_FORMAT_SUPPORT2 Support2;
} D3D12_FEATURE_DATA_FORMAT_SUPPORT;
```

#### D3D12_FEATURE_DATA_FORMAT_INFO

```cpp
typedef struct D3D12_FEATURE_DATA_FORMAT_INFO
{
    DXGI_FORMAT Format;
    UINT8 PlaneCount;
} D3D12_FEATURE_DATA_FORMAT_INFO;
```

#### D3D12_MULTISAMPLE_QUALITY_LEVEL_FLAGS

```cpp
typedef enum D3D12_MULTISAMPLE_QUALITY_LEVEL_FLAGS
{
    D3D12_MULTISAMPLE_QUALITY_LEVELS_FLAG_NONE           = 0,
    D3D12_MULTISAMPLE_QUALITY_LEVELS_FLAG_TILED_RESOURCE = 0x00000001,
} D3D12_MULTISAMPLE_QUALITY_LEVEL_FLAGS;
```

#### D3D12_FEATURE_DATA_MULTISAMPLE_QUALITY_LEVELS

```cpp
typedef struct D3D12_FEATURE_DATA_MULTISAMPLE_QUALITY_LEVELS
{
    DXGI_FORMAT Format;
    UINT SampleCount;
    D3D12_MULTISAMPLE_QUALITY_LEVEL_FLAGS Flags;
    UINT NumQualityLevels;
} D3D12_FEATURE_DATA_MULTISAMPLE_QUALITY_LEVELS;
```

<a id="d3d12-feature-data-format-support"></a>

### D3D12_FEATURE_DATA_FORMAT_SUPPORT

`Format`

A [DXGI_FORMAT](https://learn.microsoft.com/en-us/windows/desktop/api/dxgiformat/ne-dxgiformat-dxgi_format)-typed value for the format to return info about.

`Support1`

<ins><!-- d3d12-review-inline:begin:formats:S-D3D12_FEATURE_DATA_FORMAT_SUPPORT:3 -->A combination of [`D3D12_FORMAT_SUPPORT1`](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/ne-d3d12-d3d12_format_support1)-typed values that are combined by using a bitwise OR operation. The resulting value specifies which resources are supported.<!-- d3d12-review-inline:end:formats:S-D3D12_FEATURE_DATA_FORMAT_SUPPORT:3 --></ins>

`Support2`

<ins><!-- d3d12-review-inline:begin:formats:S-D3D12_FEATURE_DATA_FORMAT_SUPPORT:5 -->A combination of [`D3D12_FORMAT_SUPPORT2`](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/ne-d3d12-d3d12_format_support2)-typed values that are combined by using a bitwise OR operation. The resulting value specifies which unordered resource options are supported.<!-- d3d12-review-inline:end:formats:S-D3D12_FEATURE_DATA_FORMAT_SUPPORT:5 --></ins>

<a id="d3d12-feature-data-format-info"></a>

### D3D12_FEATURE_DATA_FORMAT_INFO

`Format`

A [DXGI_FORMAT](https://learn.microsoft.com/en-us/windows/desktop/api/dxgiformat/ne-dxgiformat-dxgi_format)-typed value for the format to return info about.

`PlaneCount`

<ins><!-- d3d12-review-inline:begin:formats:S-D3D12_FEATURE_DATA_FORMAT_INFO:3 -->The number of logical planes in the specified format.<!-- d3d12-review-inline:end:formats:S-D3D12_FEATURE_DATA_FORMAT_INFO:3 --></ins>

<a id="d3d12-feature-data-multisample-quality-levels"></a>

### D3D12_FEATURE_DATA_MULTISAMPLE_QUALITY_LEVELS

`Format`

A [DXGI_FORMAT](https://learn.microsoft.com/en-us/windows/desktop/api/dxgiformat/ne-dxgiformat-dxgi_format)-typed value for the format to return info about.

`SampleCount`

The number of multi-samples per pixel to return info about.

`Flags`

<ins><!-- d3d12-review-inline:begin:formats:S-D3D12_FEATURE_DATA_MULTISAMPLE_QUALITY_LEVELS:5 -->Flags to control quality levels, as a bitwise-OR'd combination of [`D3D12_MULTISAMPLE_QUALITY_LEVEL_FLAGS`](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/ne-d3d12-d3d12_multisample_quality_level_flags) enumeration constants. The resulting value specifies options for determining quality levels.<!-- d3d12-review-inline:end:formats:S-D3D12_FEATURE_DATA_MULTISAMPLE_QUALITY_LEVELS:5 --></ins>

`NumQualityLevels`

The number of quality levels.

<!-- d3d12-review-alert:begin:formats:N-support-bits:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12_FEATURE_FORMAT_SUPPORT` returns `Support1` and `Support2` for `Format`. The relevant combinations include resource dimension and view-kind support, shader load/sample support, depth/stencil or render-target/blend support, multisample support, and typed-UAV load/store/atomic capabilities. These bits are not interchangeable. In particular, UAV view creation, typed load, typed store and each atomic capability are separately represented.

<!-- d3d12-review-alert:end:formats:N-support-bits:0 -->

<a id="typed-uav-loads"></a>

### Typed UAV load formats

<ins><!-- d3d12-review-inline:begin:formats:S-typed-formats:0 -->The following three formats support typed UAV loads on D3D12 hardware:<!-- d3d12-review-inline:end:formats:S-typed-formats:0 --></ins>

- R32\_FLOAT
- R32\_UINT
- R32\_SINT

<ins><!-- d3d12-review-inline:begin:formats:S-typed-formats:2 -->The following formats are supported as a set on D3D12  hardware, so if any one is supported, all are supported.<!-- d3d12-review-inline:end:formats:S-typed-formats:2 --></ins>

- R32G32B32A32\_FLOAT
- R32G32B32A32\_UINT
- R32G32B32A32\_SINT
- R16G16B16A16\_FLOAT
- R16G16B16A16\_UINT
- R16G16B16A16\_SINT
- R8G8B8A8\_UNORM
- R8G8B8A8\_UINT
- R8G8B8A8\_SINT
- R16\_FLOAT
- R16\_UINT
- R16\_SINT
- R8\_UNORM
- R8\_UINT
- R8\_SINT

<ins><!-- d3d12-review-inline:begin:formats:S-typed-formats:4 -->The following formats are optionally and individually supported on D3D12  hardware, so a single query would need to be made on each format to test for support.<!-- d3d12-review-inline:end:formats:S-typed-formats:4 --></ins>

- R16G16B16A16\_UNORM
- R16G16B16A16\_SNORM
- R32G32\_FLOAT
- R32G32\_UINT
- R32G32\_SINT
- R10G10B10A2\_UNORM
- R10G10B10A2\_UINT
- R11G11B10\_FLOAT
- R8G8B8A8\_SNORM
- R16G16\_FLOAT
- R16G16\_UNORM
- R16G16\_UINT
- R16G16\_SNORM
- R16G16\_SINT
- R8G8\_UNORM
- R8G8\_UINT
- R8G8\_SNORM
- R8G8\_SINT
- R16\_UNORM
- R16\_SNORM
- R8\_SNORM
- A8\_UNORM
- B5G6R5\_UNORM
- B5G5R5A1\_UNORM
- B4G4R4A4\_UNORM

<!-- d3d12-review-alert:begin:formats:N-typed-cap:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12_FEATURE_DATA_D3D12_OPTIONS.TypedUAVLoadAdditionalFormats` identifies support for the additional all-or-nothing set. Individually optional formats require their `D3D12_FORMAT_SUPPORT2_UAV_TYPED_LOAD` result. Additional typed-load support also requires typed-store support; the reverse implication does not hold, and atomic support remains separately specified. Typed-view access uses the bound format's interpretation, not a reinterpretation inferred from the shader's integer or floating-point spelling.

<!-- d3d12-review-alert:end:formats:N-typed-cap:0 -->

<ins><!-- d3d12-review-inline:begin:formats:S-bgra:0 -->BGRA UAV support can be
exposed by drivers (including typed UAV load). This is optional. This capability is independent of format casting
(though relaxed format casting described above applies to BGRA too).<!-- d3d12-review-inline:end:formats:S-bgra:0 --></ins>

<ins><!-- d3d12-review-inline:begin:formats:S-bgra:1 -->Applications can discover support for BGRA UAV store (and separately,
load) via the usual mechanism -- CheckFeatureSupport() with
`D3D12_FEATURE_FORMAT_SUPPORT`.<!-- d3d12-review-inline:end:formats:S-bgra:1 --></ins>

<a id="shared-exponent-support"></a>

### R9G9B9E5 optional view support

<ins><!-- d3d12-review-inline:begin:formats:S-999:0 -->`DXGI_FORMAT_R9G9B9E5_SHAREDEXP` render-target/UAV support is optional. Applications can use [CheckFeatureSupport](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12device-checkfeaturesupport) with `D3D12_FEATURE_FORMAT_SUPPORT` to check the support for a format.<!-- d3d12-review-inline:end:formats:S-999:0 --></ins>

Relevant bits (from [here](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_format_support1)):

<!-- d3d12-review-alert:begin:formats:S-999:2 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | **D3D12** |
> | --------------------------------------------------- |
> | `D3D12_FORMAT_SUPPORT1_RENDER_TARGET` |
> | `D3D12_FORMAT_SUPPORT1_MULTISAMPLE_RENDERTARGET` |
> | `D3D12_FORMAT_SUPPORT1_MULTISAMPLE_RESOLVE` |
> | `D3D12_FORMAT_SUPPORT1_MULTISAMPLE_LOAD` |
> | `D3D12_FORMAT_SUPPORT1_TYPED_UNORDERED_ACCESS_VIEW` |
> | `D3D12_FORMAT_SUPPORT1_BLENDABLE` |
> | `D3D12_FORMAT_SUPPORT2_UAV_TYPED_LOAD` |
> | `D3D12_FORMAT_SUPPORT2_UAV_TYPED_STORE` |

<!-- d3d12-review-alert:end:formats:S-999:2 -->

As each support group is **all-or-nothing**, applications need only check one of these bits to assume if all the above bits are set.

<ins><!-- d3d12-review-inline:begin:formats:S-999:4 -->Multisample quality is queried separately with `D3D12_FEATURE_MULTISAMPLE_QUALITY_LEVELS`.<!-- d3d12-review-inline:end:formats:S-999:4 --></ins>

<!-- d3d12-review-alert:begin:formats:N-999-write-mask:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Render-target use of `DXGI_FORMAT_R9G9B9E5_SHAREDEXP` also has the [RenderTargetWriteMask requirement](../D3D12R9G9B9E5Format.md#interaction-with-rendertargetwritemask); format support alone does not remove that pipeline-state constraint.

<!-- d3d12-review-alert:end:formats:N-999-write-mask:0 -->

<a id="creation"></a>

## View creation APIs

<!-- d3d12-review-alert:begin:formats:N-create-shared:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> These methods create descriptors immediately on the CPU at `DestDescriptor`. The [heap type, handle, lifetime and CPU/GPU conflict requirements](binding.md#descriptor-creation) apply. Creating a view does not allocate backing storage for its resource, make it resident, or synchronize its accesses. Null-resource descriptors and null-description defaults are distinct; [null binding](binding.md#null-descriptors) and the parameter rules below define them.

<!-- d3d12-review-alert:end:formats:N-create-shared:0 -->

<!-- d3d12-review-alert:begin:formats:N-view-errors:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The ordinary SRV/UAV/RTV/DSV creators return `void`, not a status code. The runtime validates the view before driver descriptor creation; a failed creation uses device error handling rather than returning a valid substitute descriptor. Device-removal status is exposed by `ID3D12Device::GetDeviceRemovedReason`. Debug diagnostics are distinct from the runtime's validation and failure handling.

<!-- d3d12-review-alert:end:formats:N-view-errors:0 -->

<a id="id3d12device-createshaderresourceview"></a>

### ID3D12Device::CreateShaderResourceView

#### Declaration

```cpp
void CreateShaderResourceView(
    ID3D12Resource* pResource,
    const D3D12_SHADER_RESOURCE_VIEW_DESC* pDesc,
    D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor);
```

#### Behavior

Creates a shader-resource view for accessing data in a resource.

#### Parameters

`[in, optional] pResource`

A pointer to the [ID3D12Resource](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nn-d3d12-id3d12resource) object that represents the shader resource.

<ins><!-- d3d12-review-inline:begin:formats:Q-id3d12device-createshaderresourceview:3 -->At least one of *pResource* or *pDesc* must be provided. Except for acceleration-structure SRVs, a null *pResource* initializes a null descriptor with a valid *pDesc* defining its type; see [null descriptors](binding.md#null-descriptors) and [acceleration-structure SRVs](binding.md#acceleration-structure-srvs).<!-- d3d12-review-inline:end:formats:Q-id3d12device-createshaderresourceview:3 --></ins>

`[in, optional] pDesc`

<ins><!-- d3d12-review-inline:begin:formats:Q-id3d12device-createshaderresourceview:5 -->A pointer to a [`D3D12_SHADER_RESOURCE_VIEW_DESC`](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/ns-d3d12-d3d12_shader_resource_view_desc) structure that describes the shader-resource view.<!-- d3d12-review-inline:end:formats:Q-id3d12device-createshaderresourceview:5 --></ins>

<ins><!-- d3d12-review-inline:begin:formats:Q-id3d12device-createshaderresourceview:6 -->A null *pDesc* is used to initialize a default descriptor, if possible. This behavior inherits the resource format and dimension (if not typeless) and for textures SRVs target a full texture, all mips and all array slices. Buffer SRVs require an explicit description; their resource description does not supply a typed view format or structure stride. Not all texture resources support null-description initialization.<!-- d3d12-review-inline:end:formats:Q-id3d12device-createshaderresourceview:6 --></ins>

`[in] DestDescriptor`

Describes the CPU descriptor handle that represents the shader-resource view. This handle can be created in a shader-visible or non-shader-visible descriptor heap.

#### Return values

None

<a id="id3d12device-createunorderedaccessview"></a>

### ID3D12Device::CreateUnorderedAccessView

#### Declaration

```cpp
void CreateUnorderedAccessView(
    ID3D12Resource* pResource,
    ID3D12Resource* pCounterResource,
    const D3D12_UNORDERED_ACCESS_VIEW_DESC* pDesc,
    D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:formats:P-id3d12device-createunorderedaccessview:0 -->Creates an unordered-access view.<!-- d3d12-review-inline:end:formats:P-id3d12device-createunorderedaccessview:0 --></ins>

#### Parameters

`pResource`

A pointer to the [ID3D12Resource](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nn-d3d12-id3d12resource) object that represents the unordered access.

At least one of *pResource* or *pDesc* must be provided.

<ins><!-- d3d12-review-inline:begin:formats:Q-id3d12device-createunorderedaccessview:4 -->A null *pResource* is used to initialize a null descriptor, which guarantees defined null binding behavior (reading 0s, writes are discarded), but must have a valid *pDesc* in order to determine the descriptor type.<!-- d3d12-review-inline:end:formats:Q-id3d12device-createunorderedaccessview:4 --></ins>

`pCounterResource`

The [ID3D12Resource](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nn-d3d12-id3d12resource) for the counter (if any) associated with the UAV.

<ins><!-- d3d12-review-inline:begin:formats:Q-id3d12device-createunorderedaccessview:7 -->If *pCounterResource* is not specified, then the **CounterOffsetInBytes** member of the [`D3D12_BUFFER_UAV`](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_buffer_uav) structure must be 0.<!-- d3d12-review-inline:end:formats:Q-id3d12device-createunorderedaccessview:7 --></ins>

If *pCounterResource* is specified, then there is a counter associated with the UAV, and the runtime performs validation of the following requirements:

- <ins><!-- d3d12-review-inline:begin:formats:Q-id3d12device-createunorderedaccessview:9 -->The **StructureByteStride** member of the [`D3D12_BUFFER_UAV`](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_buffer_uav) structure must be greater than 0.<!-- d3d12-review-inline:end:formats:Q-id3d12device-createunorderedaccessview:9 --></ins>
- The format must be DXGI\_FORMAT\_UNKNOWN.
- <ins><!-- d3d12-review-inline:begin:formats:Q-id3d12device-createunorderedaccessview:9 -->The D3D12\_BUFFER\_UAV\_FLAG\_RAW flag (a [`D3D12_BUFFER_UAV_FLAGS`](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_buffer_uav_flags) enumeration constant) must not be set.<!-- d3d12-review-inline:end:formats:Q-id3d12device-createunorderedaccessview:9 --></ins>
- Both of the resources (*pResource* and *pCounterResource*) must be buffers.
- <ins><!-- d3d12-review-inline:begin:formats:Q-id3d12device-createunorderedaccessview:9 -->The **CounterOffsetInBytes** member of the [`D3D12_BUFFER_UAV`](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_buffer_uav) structure must be a multiple of `D3D12_UAV_COUNTER_PLACEMENT_ALIGNMENT` (4096), and must be within the range of the counter resource.<!-- d3d12-review-inline:end:formats:Q-id3d12device-createunorderedaccessview:9 --></ins>
- *pResource* cannot be NULL
- *pDesc* cannot be NULL.

`pDesc`

<ins><!-- d3d12-review-inline:begin:formats:Q-id3d12device-createunorderedaccessview:11 -->A pointer to a [`D3D12_UNORDERED_ACCESS_VIEW_DESC`](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_unordered_access_view_desc) structure that describes the unordered-access view.<!-- d3d12-review-inline:end:formats:Q-id3d12device-createunorderedaccessview:11 --></ins>

<ins><!-- d3d12-review-inline:begin:formats:Q-id3d12device-createunorderedaccessview:12 -->A null *pDesc* is used to initialize a default descriptor, if possible. This behavior inherits the resource format and dimension (if not typeless) and for textures UAVs target the first mip and all array slices. Buffer UAVs require an explicit description; their resource description does not supply a typed view format or structure stride. Not all texture resources support null-description initialization.<!-- d3d12-review-inline:end:formats:Q-id3d12device-createunorderedaccessview:12 --></ins>

`[in] DestDescriptor`

<ins><!-- d3d12-review-inline:begin:formats:Q-id3d12device-createunorderedaccessview:14 -->Describes the CPU descriptor handle that represents the descriptor slot that holds the unordered-access view.<!-- d3d12-review-inline:end:formats:Q-id3d12device-createunorderedaccessview:14 --></ins>

#### Return values

None

<a id="id3d12device-createrendertargetview"></a>

### ID3D12Device::CreateRenderTargetView

#### Declaration

```cpp
void CreateRenderTargetView(
    ID3D12Resource* pResource,
    const D3D12_RENDER_TARGET_VIEW_DESC* pDesc,
    D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor);
```

#### Behavior

Creates a render-target view for accessing resource data.

#### Parameters

`[in, optional] pResource`

A pointer to the [ID3D12Resource](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nn-d3d12-id3d12resource) object that represents the render target.

<ins><!-- d3d12-review-inline:begin:formats:Q-id3d12device-createrendertargetview:3 -->At least one of *pResource* or *pDesc* must be provided. A null *pResource* is used to initialize a null descriptor, which guarantees defined null binding behavior (reading 0s, writes are discarded), but must have a valid *pDesc* in order to determine the descriptor type.<!-- d3d12-review-inline:end:formats:Q-id3d12device-createrendertargetview:3 --></ins>

`[in, optional] pDesc`

<ins><!-- d3d12-review-inline:begin:formats:Q-id3d12device-createrendertargetview:5 -->A pointer to a [`D3D12_RENDER_TARGET_VIEW_DESC`](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/ns-d3d12-d3d12_render_target_view_desc) structure that describes the render-target view.<!-- d3d12-review-inline:end:formats:Q-id3d12device-createrendertargetview:5 --></ins>

<ins><!-- d3d12-review-inline:begin:formats:Q-id3d12device-createrendertargetview:6 -->A null *pDesc* is used to initialize a default descriptor, if possible. This behavior inherits the resource format and dimension (if not typeless) and RTVs target the first mip and all array slices. Not all resources support null descriptor initialization.<!-- d3d12-review-inline:end:formats:Q-id3d12device-createrendertargetview:6 --></ins>

`[in] DestDescriptor`

Describes the CPU descriptor handle that represents the destination where the newly-created render target view will reside.

#### Return values

None

<a id="id3d12device-createdepthstencilview"></a>

### ID3D12Device::CreateDepthStencilView

#### Declaration

```cpp
void CreateDepthStencilView(
    ID3D12Resource* pResource,
    const D3D12_DEPTH_STENCIL_VIEW_DESC* pDesc,
    D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor);
```

#### Behavior

Creates a depth-stencil view for accessing resource data.

#### Parameters

`[in, optional] pResource`

A pointer to the [ID3D12Resource](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/nn-d3d12-id3d12resource) object that represents the depth stencil.

<ins><!-- d3d12-review-inline:begin:formats:Q-id3d12device-createdepthstencilview:3 -->At least one of *pResource* or *pDesc* must be provided. A null *pResource* is used to initialize a null descriptor, which guarantees defined null binding behavior (reading 0s, writes are discarded), but must have a valid *pDesc* in order to determine the descriptor type.<!-- d3d12-review-inline:end:formats:Q-id3d12device-createdepthstencilview:3 --></ins>

`[in, optional] pDesc`

<ins><!-- d3d12-review-inline:begin:formats:Q-id3d12device-createdepthstencilview:5 -->A pointer to a [`D3D12_DEPTH_STENCIL_VIEW_DESC`](https://learn.microsoft.com/en-us/windows/desktop/api/d3d12/ns-d3d12-d3d12_depth_stencil_view_desc) structure that describes the depth-stencil view.<!-- d3d12-review-inline:end:formats:Q-id3d12device-createdepthstencilview:5 --></ins>

<ins><!-- d3d12-review-inline:begin:formats:Q-id3d12device-createdepthstencilview:6 -->A null *pDesc* is used to initialize a default descriptor, if possible. This behavior inherits the resource format and dimension (if not typeless) and DSVs target the first mip and all array slices. Not all resources support null descriptor initialization.<!-- d3d12-review-inline:end:formats:Q-id3d12device-createdepthstencilview:6 --></ins>

`[in] DestDescriptor`

<ins><!-- d3d12-review-inline:begin:formats:Q-id3d12device-createdepthstencilview:8 -->Describes the CPU descriptor handle that represents the descriptor slot that holds the depth-stencil view.<!-- d3d12-review-inline:end:formats:Q-id3d12device-createdepthstencilview:8 --></ins>

#### Return values

None

<a id="create-sampler-feedback-uav"></a>

### ID3D12Device8::CreateSamplerFeedbackUnorderedAccessView

#### Declaration

```cpp
void CreateSamplerFeedbackUnorderedAccessView(
        ID3D12Resource* pTargetedResource,
        ID3D12Resource* pFeedbackResource,
        D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor);
```

#### Behavior

For purposes of sampler feedback, creates a descriptor suitable for binding.

> #### Terminology: Paired
> For a feedback map to be called "paired" to a sampled resource, it means that the feedback map contains sampler feedback for that resource.
>
> When a feedback map is bound to a resource, the feedback map can not be used for writing feedback for other resources and the resource cannot be used with other feedback maps.
>
> Outside of bindings, however, a resource may be used for writing feedback to different feedback maps and a single feedback map may be repurposed to contain feedback for different resources. That is to say, outside of bindings the pairing need not be exclusive.

<!-- d3d12-review-alert:begin:formats:N-feedback-validity:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> At least one of `pTargetedResource` and `pFeedbackResource` must be non-null. When both are present, their logical width, height, mip count and array size must match the feedback pairing requirements. The feedback resource uses one of the opaque sampler-feedback formats; [feedback resource creation](resources.md#extended-description) still applies. `D3D12_FEATURE_DATA_D3D12_OPTIONS7.SamplerFeedbackTier` must report sampler-feedback support, as defined by the [feature capability](common-shader-internals.md#feedback-capability-tiers). A permitted null resource parameter is not an uninitialized descriptor binding.

<!-- d3d12-review-alert:end:formats:N-feedback-validity:0 -->

<ins><!-- d3d12-review-inline:begin:formats:V-feedback-null:0 -->Feedback map UAVs may be created against a NULL paired texture. Writes through a feedback UAV descriptor created with a NULL paired texture have no effect.<!-- d3d12-review-inline:end:formats:V-feedback-null:0 --></ins>

#### Parameters

`pTargetedResource`

The targeted resource, such as a texture, to create a descriptor for.

`pFeedbackResource`

The feedback resource, such as a texture, to create a descriptor for.

`DestDescriptor`

The CPU descriptor handle.

#### Return values

<!-- d3d12-review-alert:begin:formats:N-feedback-return:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:formats:N-feedback-return:0 -->

<a id="driver"></a>

## Driver contracts

<!-- d3d12-review-alert:begin:formats:N-driver:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The runtime translates API view descriptions into the negotiated driver representation. The driver writes hardware-specific descriptors into the supplied CPU descriptor handles. Descriptor creation does not allocate separately owned objects. See [descriptor ownership](binding.md#driver-descriptors).

<!-- d3d12-review-alert:end:formats:N-driver:0 -->

```cpp
typedef VOID (APIENTRY* PFND3D12DDI_CREATE_SHADER_RESOURCE_VIEW_0002)(
    D3D12DDI_HDEVICE unnamedParam1,
    const D3D12DDIARG_CREATE_SHADER_RESOURCE_VIEW_0002 *unnamedParam2,
    D3D12DDI_CPU_DESCRIPTOR_HANDLE DestDescriptor
);
```

```cpp
typedef VOID (APIENTRY* PFND3D12DDI_CREATE_UNORDERED_ACCESS_VIEW_0002)(
    D3D12DDI_HDEVICE unnamedParam1,
    const D3D12DDIARG_CREATE_UNORDERED_ACCESS_VIEW_0002 *unnamedParam2,
    D3D12DDI_CPU_DESCRIPTOR_HANDLE DestDescriptor
);
```

```cpp
typedef VOID (APIENTRY* PFND3D12DDI_CREATE_RENDER_TARGET_VIEW_0002)(
    D3D12DDI_HDEVICE unnamedParam1,
    const D3D12DDIARG_CREATE_RENDER_TARGET_VIEW_0002 *unnamedParam2,
    D3D12DDI_CPU_DESCRIPTOR_HANDLE DestDescriptor
);
```

```cpp
typedef VOID (APIENTRY* PFND3D12DDI_CREATE_DEPTH_STENCIL_VIEW)(
    D3D12DDI_HDEVICE unnamedParam1,
    const D3D12DDIARG_CREATE_DEPTH_STENCIL_VIEW *unnamedParam2,
    D3D12DDI_CPU_DESCRIPTOR_HANDLE DestDescriptor
);
```

<!-- d3d12-review-alert:begin:formats:N-driver-translation:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | API information | Driver-facing responsibility |
> |---|---|
> | Resource and view format | Resolve the driver resource handle and the permitted format interpretation; descriptor storage remains driver-specific |
> | Default descriptions and remaining-range sentinels | Expand into the appropriate selected mip/array/depth extent before descriptor creation |
> | API dimension and resource sample configuration | Select the corresponding driver view representation; API array/MS/cube variants are not an interchangeable numeric DDI enum |
> | `Shader4ComponentMapping` and `ResourceMinLODClamp` | Preserve the specified component and mip-coordinate interpretation |
> | UAV counter resource and byte offset | Carry the counter association separately from the data buffer and apply the validated storage offset |
> | Depth/stencil plane selection | Preserve logical aspect selection without exposing a physical texture layout |

<!-- d3d12-review-alert:end:formats:N-driver-translation:0 -->

<!-- d3d12-review-alert:begin:formats:DV-V01:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The following table associates descriptor-creation DDIs with their API operations.

<!-- d3d12-review-alert:end:formats:DV-V01:0 -->

<!-- d3d12-review-alert:begin:formats:DV-V02:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Driver entry | Canonical API contract |
> |---|---|
> | `PFND3D12DDI_CREATE_SHADER_RESOURCE_VIEW_0002` | [CreateShaderResourceView](#id3d12device-createshaderresourceview) |
> | `PFND3D12DDI_CREATE_UNORDERED_ACCESS_VIEW_0002` | [CreateUnorderedAccessView](#id3d12device-createunorderedaccessview) |
> | `PFND3D12DDI_CREATE_RENDER_TARGET_VIEW_0002` | [CreateRenderTargetView](#id3d12device-createrendertargetview) |
> | `PFND3D12DDI_CREATE_DEPTH_STENCIL_VIEW` | [CreateDepthStencilView](#id3d12device-createdepthstencilview) |

<!-- d3d12-review-alert:end:formats:DV-V02:0 -->

Driver support for format list casting is reported via `RelaxedFormatCastingSupported` in `D3D12DDI_OPTIONS_DATA_0090` when `GetCaps` is called with `D3D12DDICAPS_TYPE_OPTIONS_0090`; available starting with DDI version `e_DDI_12_8_0090`.

<!-- d3d12-review-alert:begin:formats:N-driver-defaults:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Before calling the driver, the runtime resolves omitted view descriptions from the resource and selects the driver-facing view kind.

<!-- d3d12-review-alert:end:formats:N-driver-defaults:0 -->

<a id="driver-sampler-feedback-view"></a>

### Paired sampler-feedback descriptor

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_CREATE_SAMPLER_FEEDBACK_UNORDERED_ACCESS_VIEW_0075 ) ( _In_ D3D12DDI_HDEVICE hDrvDevice, _In_ D3D12DDI_HRESOURCE hDrvTargetedResource, _In_ D3D12DDI_HRESOURCE hDrvFeedbackResource, _In_ D3D12DDI_CPU_DESCRIPTOR_HANDLE DestDescriptor );
```

<!-- d3d12-review-alert:begin:formats:DV-F02:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Sampler-feedback descriptor creation receives separate driver handles for the targeted and feedback resources.

<!-- d3d12-review-alert:end:formats:DV-F02:0 -->

<a id="driver-format-queries"></a>

<a id="current-driver-format-query-callbacks"></a>

### Current driver format-query DDIs

```cpp
#define D3D12DDI_FORMAT_SUPPORT_SHADER_SAMPLE            0x00000001 // format can be sampled with any filter in shaders
#define D3D12DDI_FORMAT_SUPPORT_RENDERTARGET             0x00000002 // format can be a renderTarget
#define D3D12DDI_FORMAT_SUPPORT_BLENDABLE                0x00000004 // format is blendable (can only be set if format can be renderTarget)
#define D3D12DDI_FORMAT_SUPPORT_MULTISAMPLE_RENDERTARGET 0x00000008 // format can be used as RenderTarget with some sample count > 1.
#define D3D12DDI_FORMAT_SUPPORT_MULTISAMPLE_LOAD         0x00000010 // format can be used as source for 'ld2dms'
#define D3D12DDI_FORMAT_SUPPORT_DECODER_OUTPUT           0x00000020 // format can be used as decoder output
#define D3D12DDI_FORMAT_SUPPORT_VIDEO_PROCESSOR_OUTPUT   0x00000040 // format can be used as video processor output
#define D3D12DDI_FORMAT_SUPPORT_VIDEO_PROCESSOR_INPUT    0x00000080 // format can be used as video processor input
#define D3D12DDI_FORMAT_SUPPORT_VERTEX_BUFFER            0x00000100 // format can be used as vertex buffer
#define D3D12DDI_FORMAT_SUPPORT_UAV_WRITES               0x00000200 // format can be written to through a UAV
#define D3D12DDI_FORMAT_SUPPORT_BUFFER                   0x00000400 // format can used in a typed Buffer view
#define D3D12DDI_FORMAT_SUPPORT_CAPTURE                  0x00000800 // format that can be supported as an output to the video capture engine
#define D3D12DDI_FORMAT_SUPPORT_VIDEO_ENCODER            0x00001000 // format can be supported as an input to a hardware MFT
#define D3D12DDI_FORMAT_SUPPORT_OUTPUT_MERGER_LOGIC_OP   0x00002000 // format supports logic op
#define D3D12DDI_FORMAT_SUPPORT_SHADER_GATHER            0x00004000 // format supports gather4
#define D3D12DDI_FORMAT_SUPPORT_MULTIPLANE_OVERLAY       0x00008000 // format supports multi plane overlay
#define D3D12DDI_FORMAT_SUPPORT_TILED                    0x00010000 // format supports use in a tiled Texture1D/2D/Cube/Array (not incl Texture3D)
#define D3D12DDI_FORMAT_SUPPORT_UAV_READS                0x00020000 // format supports Typed UAV Loads
#define D3D12DDI_FORMAT_SUPPORT_DISPLAY                  0x00200000 // format supports Display (0x00100000 is reserved for displayables in d3d11)
#define D3D12DDI_FORMAT_SUPPORT_NOT_SUPPORTED            0x80000000 // format is not supported at all. Currently only valid for DXGI_FORMAT_R10G10B10_XR_BIAS_A2_UNORM. (Set only this bit)

typedef enum D3D12DDI_MULTISAMPLE_QUALITY_LEVEL_FLAGS
{
    D3D12DDI_MULTISAMPLE_QUALITY_LEVEL_FLAG_NONE            = 0,
    D3D12DDI_MULTISAMPLE_QUALITY_LEVEL_FLAG_TILED_RESOURCE  = 0x1
} D3D12DDI_MULTISAMPLE_QUALITY_LEVEL_FLAGS;

typedef VOID ( APIENTRY* PFND3D12DDI_CHECKFORMATSUPPORT )(
    D3D12DDI_HDEVICE, DXGI_FORMAT, _Out_ UINT* );

typedef VOID ( APIENTRY* PFND3D12DDI_CHECKMULTISAMPLEQUALITYLEVELS )(
    D3D12DDI_HDEVICE hDevice,
    DXGI_FORMAT Format,
    UINT SampleCount,
    D3D12DDI_MULTISAMPLE_QUALITY_LEVEL_FLAGS Flags,
    _Out_ UINT* pNumQualityLevels
);
```

<!-- d3d12-review-alert:begin:formats:FQ-query-roles:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pfnCheckFormatSupport` and `pfnCheckMultisampleQualityLevels` are members of `D3D12DDI_DEVICE_FUNCS_CORE_0119`.

<!-- d3d12-review-alert:end:formats:FQ-query-roles:0 -->

<!-- d3d12-review-alert:begin:formats:FQ-query-roles:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Both queries write their results into caller-provided CPU storage before returning.

<!-- d3d12-review-alert:end:formats:FQ-query-roles:1 -->

<!-- d3d12-review-alert:begin:formats:FQ-query-roles:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> API validation or runtime initialization can answer or issue queries without a one-to-one API/DDI call mapping.

<!-- d3d12-review-alert:end:formats:FQ-query-roles:2 -->

<a id="driver-format-support"></a>

#### PFND3D12DDI_CHECKFORMATSUPPORT

Implemented by the client driver to check the format support.

<!-- d3d12-review-alert:begin:formats:FQ-format-reporting:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12DDI_FORMAT_SUPPORT_*` reports optional format capabilities. A zero mask does not remove capabilities required for the format.

<!-- d3d12-review-alert:end:formats:FQ-format-reporting:0 -->

<!-- d3d12-review-alert:begin:formats:FQ-format-reporting:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The runtime combines required format capabilities with eligible optional driver reports. The driver mask is not an API support word. For example, driver `SHADER_SAMPLE` is `0x1`, while API `D3D12_FORMAT_SUPPORT1_SHADER_SAMPLE` is `0x200`.

<!-- d3d12-review-alert:end:formats:FQ-format-reporting:1 -->

<!-- d3d12-review-alert:begin:formats:FQ-format-reporting:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12DDI_FORMAT_SUPPORT_NOT_SUPPORTED` rejects `DXGI_FORMAT_R10G10B10_XR_BIAS_A2_UNORM` as a whole. It must be returned alone and is not valid for other formats.

<!-- d3d12-review-alert:end:formats:FQ-format-reporting:2 -->

<a id="driver-format-mask"></a>

##### Optional driver bits and API reporting

<!-- d3d12-review-alert:begin:formats:FQ-driver-bit-mapping:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The table names the meanings of all published driver bits. API names shortened to `Support1.*` and `Support2.*` have prefixes `D3D12_FORMAT_SUPPORT1_` and `D3D12_FORMAT_SUPPORT2_`. An indicated optional mapping is applied only where that format is eligible; required capabilities do not need the corresponding optional driver bit.

<!-- d3d12-review-alert:end:formats:FQ-driver-bit-mapping:0 -->

<!-- d3d12-review-alert:begin:formats:FQ-driver-bit-mapping:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Driver bit suffix | API reporting relationship / meaning |
> | --- | --- |
> | `SHADER_SAMPLE` | Optional shader sampling -> `Support1.SHADER_SAMPLE`. |
> | `RENDERTARGET` | Optional render-target use -> `Support1.RENDER_TARGET`; it does not by itself establish optional scanout support under the current separate-display-bit rule. |
> | `BLENDABLE` | Optional blending -> `Support1.BLENDABLE`, only when render-target use is supported. |
> | `MULTISAMPLE_RENDERTARGET` | Optional multisampled render-target use -> `Support1.MULTISAMPLE_RENDERTARGET`; sample-count quality is queried separately. |
> | `MULTISAMPLE_LOAD` | Optional multisample loads -> `Support1.MULTISAMPLE_LOAD`. |
> | `DECODER_OUTPUT` | Decoder-output format reporting -> `Support1.DECODER_OUTPUT` when the applicable video interface and format support are exposed. |
> | `VIDEO_PROCESSOR_OUTPUT` | Video-processor output -> `Support1.VIDEO_PROCESSOR_OUTPUT` under video/format eligibility. |
> | `VIDEO_PROCESSOR_INPUT` | Video-processor input -> `Support1.VIDEO_PROCESSOR_INPUT` under video/format eligibility. |
> | `VERTEX_BUFFER` | Optional vertex input -> `Support1.IA_VERTEX_BUFFER`. |
> | `UAV_WRITES` | Optional typed-UAV view/store -> `Support1.TYPED_UNORDERED_ACCESS_VIEW` and `Support2.UAV_TYPED_STORE`; this is not typed-load or atomic support. |
> | `BUFFER` | Optional typed-buffer view support -> `Support1.BUFFER`. |
> | `CAPTURE` | Capture-engine output format reporting; this driver bit is not an extra bit in the public API support words declared above. |
> | `VIDEO_ENCODER` | Video-encoder input format reporting -> `Support1.VIDEO_ENCODER` under video/format eligibility. |
> | `OUTPUT_MERGER_LOGIC_OP` | Published per-format logic-operation report; the API result also follows format requirements and device logic-operation capability, not a raw copy of this bit. |
> | `SHADER_GATHER` | Optional gather -> `Support1.SHADER_GATHER`. |
> | `MULTIPLANE_OVERLAY` | Multiplane-overlay reporting -> `Support2.MULTIPLANE_OVERLAY`; it is not permission for every view or display configuration. |
> | `TILED` | Published tiled 1D/2D/cube/array report, excluding 3D in this bit's definition; API `Support2.TILED` is derived from format requirements and tiled-resource capability, not a raw copy. |
> | `UAV_READS` | Optional typed-UAV load -> `Support2.UAV_TYPED_LOAD`, additionally gated by the applicable typed-load capability/group and typed-UAV write eligibility. |
> | `DISPLAY` | Required for optional scanout reporting as `Support1.DISPLAY` under the current separate-display-bit interface; eligible displayable formats also use it for `Support2.DISPLAYABLE`. The two API uses remain distinct. |
> | `NOT_SUPPORTED` | Whole-format rejection under the restricted format rule above; not an API support bit. |

<!-- d3d12-review-alert:end:formats:FQ-driver-bit-mapping:1 -->

<!-- d3d12-review-alert:begin:formats:FQ-driver-bit-mapping:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Mapping `UAV_READS` also requires the applicable [typed-UAV load-format group](#typed-uav-loads) and typed-UAV store eligibility.

<!-- d3d12-review-alert:end:formats:FQ-driver-bit-mapping:2 -->

<!-- d3d12-review-alert:begin:formats:FQ-driver-bit-mapping:3 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Logic-op, tiled and sampler-feedback support are derived from their format/device requirements, not additional optional driver-mask bits.

<!-- d3d12-review-alert:end:formats:FQ-driver-bit-mapping:3 -->

<!-- d3d12-review-alert:begin:formats:FQ-driver-bit-mapping:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> From DDI revision `_0107`, optional scanout requires the driver's `DISPLAY` bit. Render-target support alone does not produce API `Support1.DISPLAY`. Displayable-format reporting retains its separate eligibility rules.

<!-- d3d12-review-alert:end:formats:FQ-driver-bit-mapping:4 -->

<!-- d3d12-review-alert:begin:formats:FQ-driver-bit-mapping:5 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Below DDI revision `_0107`, optional render-target/UAV support for `DXGI_FORMAT_R9G9B9E5_SHAREDEXP` is not reported regardless of the driver bits. Its shader-resource support is unchanged. For eligible drivers, the [shared-exponent group](#shared-exponent-support) retains its all-or-nothing and derived-resolve rules. `NV12` shader-load reporting follows shader-sample support because this DDI has no independent shader-load flag.

<!-- d3d12-review-alert:end:formats:FQ-driver-bit-mapping:5 -->

<a id="driver-multisample-quality"></a>

#### PFND3D12DDI_CHECKMULTISAMPLEQUALITYLEVELS

Implemented by the client driver to check multi-sample quality levels.

<!-- d3d12-review-alert:begin:formats:FQ-quality-reporting:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12DDI_MULTISAMPLE_QUALITY_LEVEL_FLAG_TILED_RESOURCE` requests the tiled-resource configuration.

<!-- d3d12-review-alert:end:formats:FQ-quality-reporting:0 -->

<!-- d3d12-review-alert:begin:formats:FQ-quality-reporting:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The runtime can answer sample count 1 without invoking the DDI. Counts zero or greater than 32 fail the API support calculation.

<!-- d3d12-review-alert:end:formats:FQ-quality-reporting:1 -->

<!-- d3d12-review-alert:begin:formats:FQ-quality-reporting:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Format/tiled-resource capability can reduce the exposed quality count to zero after a positive driver result. The runtime caps the exposed count at `0x80000000`, reserving the upper half of the `UINT` quality-value range for standard/custom sample-pattern values.

<!-- d3d12-review-alert:end:formats:FQ-quality-reporting:2 -->


