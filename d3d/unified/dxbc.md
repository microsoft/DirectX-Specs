<a id="dxbc"></a>

# DXBC reference

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

<a id="rounding-instructions"></a>

## Floating-point rounding instructions

See [Integral rounding](common-shader-internals.md#float-rounding) for the common operation.

The DXBC floating point instructions are listed in the [Floating Point Instructions](https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm#FloatingPointInstructions) sub-section of the full instruction listing.

[round_ne](https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm#inst_ROUND_NE) (nearest-even)
[round_ni](https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm#inst_ROUND_NI) (negative-infinity)
[round_pi](https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm#inst_ROUND_PI) (positive-infinity)
[round_z](https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm#inst_ROUND_Z) (towards zero)

<a id="sampling-operands"></a>

## Sampling operands

See [array coordinates](common-shader-internals.md#array-coordinates), [texel offsets](common-shader-internals.md#texel-offsets) and [explicit gradients](common-shader-internals.md#sample-gradients) for the common behavior.

### Array sampling coordinates

For the DXBC sample operation, `srcAddress` is the floating-point texture coordinate operand.

<ins><!-- d3d12-review-inline:begin:dxbc:sampling-array-operands:0:authored:component-map -->For Texture1D arrays, the post-swizzle `g` component of `srcAddress` selects the array slice. For Texture2D arrays, the post-swizzle `b` component selects the array slice.<!-- d3d12-review-inline:end:dxbc:sampling-array-operands:0:authored:component-map --></ins>

### Literal texel offsets

DXBC's `_aoffimmi(u,v,w)` supplies immediate signed four-bit texel-space offsets. It is not permitted for cube sampling.

_aoffimmi v,w components are ignored for Texture1Ds.

_aoffimmi w component is ignored for Texture2Ds.

### Multisample loads

The DXBC instruction is `ld2dms`. DXIL uses `dx.op.textureLoad` with a sample index for multisampled textures.

### Explicit-gradient sampling: sample_d

<ins><!-- d3d12-review-inline:begin:common-shader-internals:B-22-4-17-sample-gradients:1 -->The r, g and b components of srcXDerivatives (after operand swizzling)
provide du/dx, dv/dx and dw/dx.  The 'a' component
(after operand swizzling) is ignored.<!-- d3d12-review-inline:end:common-shader-internals:B-22-4-17-sample-gradients:1 --></ins>

<ins><!-- d3d12-review-inline:begin:common-shader-internals:B-22-4-17-sample-gradients:2 -->The r, g and b components of srcYDerivatives (after operand swizzling)
provide du/dy, dv/dy and dw/dy.  The 'a' component
(after operand swizzling) is ignored.<!-- d3d12-review-inline:end:common-shader-internals:B-22-4-17-sample-gradients:2 --></ins>

<a id="lod-control-forms"></a>

## LOD control forms

See [LOD selection](common-shader-internals.md#lod-operation-controls) for the common operation inputs and [bias and clamping](common-shader-internals.md#sampler-lod-bias-and-clamping) for the arithmetic.

<ins><!-- d3d12-review-inline:begin:dxbc:lod-control-forms:0:authored:bias-and-clamp -->DXBC `sample_l` and `sample_c_lz` apply sampler bias and LOD clamps. `sample_c_lz` applies the bias to LOD zero.<!-- d3d12-review-inline:end:dxbc:lod-control-forms:0:authored:bias-and-clamp --></ins>

<ins><!-- d3d12-review-inline:begin:common-shader-internals:B-22-5-6-lod-query-boundaries:2 -->The inherited DXBC lod operation is valid for the following texture types:  Texture1D,
Texture2D, Texture3D and TextureCube.<!-- d3d12-review-inline:end:common-shader-internals:B-22-5-6-lod-query-boundaries:2 --></ins>

<ins><!-- d3d12-review-inline:begin:common-shader-internals:B-22-5-6-lod-query-boundaries:3 -->The lod instruction is not defined when used with a sampler that
specifies point mip filtering, specifically, any D3D12_FILTER enum
that ends in MIP_POINT.
(An example of this would be D3D12_FILTER_MIN_MAG_MIP_POINT.)<!-- d3d12-review-inline:end:common-shader-internals:B-22-5-6-lod-query-boundaries:3 --></ins>

<a id="mapping-feedback-instructions"></a>

## DXBC mapping status and clamp instruction forms

<ins><!-- d3d12-review-inline:begin:common-shader-internals:TILED-shader-instructions:0 -->The following shader instructions include combinations of feedback and/or clamp in addition to their basic operation, followed by instructions that examine the feedback return.
If the clamp is used, it is an additional scalar float32 register or immediate operand. If feedback is requested, it comes out in an additional 32 bit scalar register operand that
needs to be fed into instruction(s) that interpret feedback.<!-- d3d12-review-inline:end:common-shader-internals:TILED-shader-instructions:0 --></ins>

These instructions can be used on Tiled or non-Tiled Resources for all applicable resource dimensions (Buffer, Texture1D/2D/3D). Non-Tiled Resources always appear to be fully mapped.

The suffix `_s` indicates mapping status, and `_cl` indicates LOD clamp.

The following instructions have a mapping status return option [_s] (but no clamp option):

* [`gather4[_s]`](../archive/D3D11_3_FunctionalSpec.htm#inst_GATHER4)
* [`gather4_c[_s]`](../archive/D3D11_3_FunctionalSpec.htm#inst_GATHER4_C)
* [`gather4_po[_s]`](../archive/D3D11_3_FunctionalSpec.htm#inst_GATHER4_PO)
* [`gather4_po_c[_s]`](../archive/D3D11_3_FunctionalSpec.htm#inst_GATHER4_PO_C)
* [`ld[_s]`](../archive/D3D11_3_FunctionalSpec.htm#inst_LD)
* [`ld2dms[_s]`](../archive/D3D11_3_FunctionalSpec.htm#inst_LD2DMS)
* [`ld_uav_typed[_s]`](../archive/D3D11_3_FunctionalSpec.htm#inst_LD_UAV_TYPED)
* [`ld_raw[_s]`](../archive/D3D11_3_FunctionalSpec.htm#inst_LD_RAW)
* [`ld_structured[_s]`](../archive/D3D11_3_FunctionalSpec.htm#inst_LD_STRUCTURED)
* [`sample_l[_s]`](../archive/D3D11_3_FunctionalSpec.htm#inst_SAMPLE_L)
* [`sample_c_lz[_s]`](../archive/D3D11_3_FunctionalSpec.htm#inst_SAMPLE_C_LZ)

The following instructions have both mapping status [_s] and clamp [_cl] options:

* [`sample[_cl][_s]`](../archive/D3D11_3_FunctionalSpec.htm#inst_SAMPLE)
* [`sample_b[_cl][_s]`](../archive/D3D11_3_FunctionalSpec.htm#inst_SAMPLE_B)
* [`sample_d[_cl][_s]`](../archive/D3D11_3_FunctionalSpec.htm#inst_SAMPLE_D)
* [`sample_c[_cl][_s]`](../archive/D3D11_3_FunctionalSpec.htm#inst_SAMPLE_C)

The following instruction examines the status return from any of the above instructions:

* `check_access_mapped`

<ins><!-- d3d12-review-inline:begin:common-shader-internals:TILED-shader-instructions:9 -->There is no mapping status feedback for memory write instructions such as `store_uav_*`.<!-- d3d12-review-inline:end:common-shader-internals:TILED-shader-instructions:9 --></ins>



The <ins><!-- d3d12-review-inline:begin:common-shader-internals:A-5-9-4-5-3:0:authored:dxbc-check-form -->DXBC <!-- d3d12-review-inline:end:common-shader-internals:A-5-9-4-5-3:0:authored:dxbc-check-form --></ins>[check_access_mapped](https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm#inst_CHECKACCESSMAPPED) instruction interprets the status return from a memory access and
indicates whether all data being accessed was mapped in the resource - true (0xFFFFFFFF) or false (0x00000000).

### HLSL lowering to DXBC

<ins><!-- d3d12-review-inline:begin:common-shader-internals:TILED-hlsl-mapping-feedback:9 -->In DXBC compilation, if either clamp
or feedback parameter is present, the
compiler emits a variant of the basic instruction. For example, the DXBC lowering of Sample with these options generates the `sample_cl_s` instruction. If neither
clamp nor
feedback is specified, the compiler
emits the basic instruction, so that there is no change from the current
behavior. The clamp value of 0.0f
indicates that no clamp is performed; thus, the driver compiler can further
tailor the instruction to the target hardware. If
feedback is a NULL register in an
instruction, the feedback is unused;
thus, the driver compiler can further tailor the instruction to the target
architecture.<!-- d3d12-review-inline:end:common-shader-internals:TILED-hlsl-mapping-feedback:9 --></ins>

<ins><!-- d3d12-review-inline:begin:common-shader-internals:TILED-hlsl-mapping-feedback:10 -->If the HLSL compiler infers that
clamp is 0.0f and feedback
is unused, the compiler emits the corresponding basic instruction (e.g., sample
rather than sample_cl_s).<!-- d3d12-review-inline:end:common-shader-internals:TILED-hlsl-mapping-feedback:10 --></ins>

<ins><!-- d3d12-review-inline:begin:common-shader-internals:TILED-hlsl-mapping-feedback:11 -->In DXBC, if a tiled resource access consists of several constituent
byte code instructions, e.g., for structured resources, the compiler aggregates
individual feedback values via the OR operation to produce the final feedback
value. Therefore, programmers see a single feedback value for such a complex
access.<!-- d3d12-review-inline:end:common-shader-internals:TILED-hlsl-mapping-feedback:11 --></ins>

<a id="gather-encoding"></a>

## Gather operands

See [Gather footprint and ordering](common-shader-internals.md#gather) for the common operation behavior.

<a id="gather-result-swizzle"></a>

<ins><!-- d3d12-review-inline:begin:common-shader-internals:B-22-4-2-gather-details:2 -->In DXBC, the swizzle on srcResource allows the returned values to be swizzled arbitrarily
before they are written to the destination.<!-- d3d12-review-inline:end:common-shader-internals:B-22-4-2-gather-details:2 --></ins>

<ins><!-- d3d12-review-inline:begin:common-shader-internals:B-22-4-2-gather-details:3 -->The DXBC .select_component on srcSampler chooses which component of the source texture
(r/g/b/a) to read 4 texels from.<!-- d3d12-review-inline:end:common-shader-internals:B-22-4-2-gather-details:3 --></ins>

<a id="programmable-gather-offsets"></a>

### <ins><!-- d3d12-review-inline:begin:common-shader-internals:Q-model-scope:0:authored:gather-offset-heading -->DXBC programmable gather offsets<!-- d3d12-review-inline:end:common-shader-internals:Q-model-scope:0:authored:gather-offset-heading --></ins>

<ins><!-- d3d12-review-inline:begin:common-shader-internals:B-22-4-4-gather-programmable-offsets:0 -->The first 2 components of the 4-vector offset parameter supply
32-bit integer offsets.  The other components of this
parameter are ignored.<!-- d3d12-review-inline:end:common-shader-internals:B-22-4-4-gather-programmable-offsets:0 --></ins>

<ins><!-- d3d12-review-inline:begin:dxbc:gather-offset-range:0:authored:common-rule -->See [programmable gather offsets](common-shader-internals.md#gather-programmable-offsets) for the common effective offset range and interpretation.<!-- d3d12-review-inline:end:dxbc:gather-offset-range:0:authored:common-rule --></ins>

<ins><!-- d3d12-review-inline:begin:common-shader-internals:B-22-4-4-gather-programmable-offsets:2 -->gather4po only works with 2D textures (unlike gather4,
which also works with TextureCubes).<!-- d3d12-review-inline:end:common-shader-internals:B-22-4-4-gather-programmable-offsets:2 --></ins>

<ins><!-- d3d12-review-inline:begin:common-shader-internals:B-22-4-4-gather-programmable-offsets:3 -->The only modes honored in the sampler are the addressing modes.
Only the most detailed mip in the resource view is used.<!-- d3d12-review-inline:end:common-shader-internals:B-22-4-4-gather-programmable-offsets:3 --></ins>

<ins><!-- d3d12-review-inline:begin:common-shader-internals:B-22-4-4-gather-programmable-offsets:4 -->Note that if the address falls on a texel center, this does not
mean the other texels can be zeroed out.<!-- d3d12-review-inline:end:common-shader-internals:B-22-4-4-gather-programmable-offsets:4 --></ins>

<ins><!-- d3d12-review-inline:begin:common-shader-internals:B-22-4-4-gather-programmable-offsets:5 -->The srcSampler parameter includes [.select_component],
allowing any single component of a texture to be retrieved
(including returning defaults for missing components).<!-- d3d12-review-inline:end:common-shader-internals:B-22-4-4-gather-programmable-offsets:5 --></ins>

<ins><!-- d3d12-review-inline:begin:common-shader-internals:B-22-4-4-gather-programmable-offsets:6 -->The comparison form `gather4_po_c` has the same two-dimensional restriction and six-bit signed offset range; it returns individual comparisons rather than a filtered average. Its float32 comparison inputs flush denormals to zero, as in the comparison-gather rules.<!-- d3d12-review-inline:end:common-shader-internals:B-22-4-4-gather-programmable-offsets:6 --></ins>
