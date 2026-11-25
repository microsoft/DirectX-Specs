<a id="dxil"></a>

# DXIL reference

<a id="entry-point-properties"></a>

## Entry point properties

<a id="native-low-precision"></a>

### Native low precision

<ins><!-- d3d12-review-inline:begin:dxil:minimum-precision-mode:0:authored:shader-flags -->The `i64` shader-flags value carried by entry-function property tag `kDxilShaderFlagsTag` (0) uses bit 23 for `UseNativeLowPrecision` (SM6.2 and later). This flag selects [native rather than minimum-precision semantics](common-shader-internals.md#dxil-minimum-precision) for `half` and `i16`. Bit 5 records the presence of low-precision types; it does not select native execution.<!-- d3d12-review-inline:end:dxil:minimum-precision-mode:0:authored:shader-flags --></ins>

<a id="wave-size-properties"></a>

### Wave size

See [Requested wave size](compute.md#wave-size) for shader and device selection requirements.

<ins><!-- d3d12-review-inline:begin:compute:N-fixed-wave:3:authored:migration-1ee0f14b4e64a74e-0 -->DXIL before SM6.8 uses `kDxilWaveSizeTag` (11) for a fixed-size request. SM6.8 and later use `kDxilRangedWaveSizeTag` (23), with three integers `(minimum,maximum,preferred)`: absent optional values are zero, and `(size,0,0)` encodes the single-size form. The old tag is invalid for SM6.8 and later. The ranged tag is invalid for earlier shader models.<!-- d3d12-review-inline:end:compute:N-fixed-wave:3:authored:migration-1ee0f14b4e64a74e-0 --></ins>

<a id="helper-feature"></a>

## Shader feature flags

### Helper lane participation

<ins><!-- d3d12-review-inline:begin:dxil:helper-feature:0:modified:attribute-context -->For non-library shaders, the [`WaveOpsIncludeHelperLanes`](pixel-shaders.md#helper-attribute) attribute is captured in the compiled shader object as a shader feature flag, set in the blob part DFCC_FeatureInfo (FourCC SFI0).<!-- d3d12-review-inline:end:dxil:helper-feature:0:modified:attribute-context --></ins>

```
#define D3D_SHADER_FEATURE_WAVE_OPS_INCLUDE_HELPER_LANES  0x20000000
```

See [Wave helper participation](pixel-shaders.md#wave-helper-participation) for pixel shader execution requirements.

<a id="special-float-classifications"></a>

## Floating-point classification

These opcodes select the floating-point classification predicates of the `IsSpecialFloat` class.

| Opcode | Instruction | `f16` overload |
|---|---|---|
| 8 | `IsNaN` | [SM6.9 and later](#special-float-fp16-availability) |
| 9 | `IsInf` | [SM6.9 and later](#special-float-fp16-availability) |
| 10 | `IsFinite` | [SM6.9 and later](#special-float-fp16-availability) |
| 11 | `IsNormal` | [SM6.9 and later](#special-float-fp16-availability) |

<a id="special-float-fp16-availability"></a>

<ins><!-- d3d12-review-inline:begin:common-shader-internals:F-sm69-special-float:0 -->The `f16` overloads of `IsNaN`, `IsInf`, `IsFinite` and `IsNormal` require Shader Model 6.9 or later.<!-- d3d12-review-inline:end:common-shader-internals:F-sm69-special-float:0 --></ins>

<a id="quad-vote"></a>

## Quad vote instruction

<!-- d3d12-review-context:begin:dxil:quad-vote:0:authored:instruction-contract -->

> [!WARNING]
> **Authored synthesis - human review pending.**

`QuadVote` (opcode 222) implements the [common quad vote operations](common-shader-internals.md#quad-votes). Native support was introduced in Shader Model 6.7. Earlier Shader Model 6.0–6.6 profiles support [quad read lowering](common-shader-internals.md#quad-vote-lowering).

```llvm
declare i1 @dx.op.quadVote.i1(i32 %opcode, i1 %cond, i8 %op)
```

`opcode` is 222, and `cond` is the lane's Boolean predicate. The constant `op` operand selects `QuadVoteOpKind`:

| `op` | Operation |
| --- | --- |
| 0 | `Any`, corresponding to `QuadAny` |
| 1 | `All`, corresponding to `QuadAll` |

Use of `QuadVote` sets bit 19 (wave level operations) of the `i64` shader-flags value carried by entry-function property tag `kDxilShaderFlagsTag` (0).

<!-- d3d12-review-context:end:dxil:quad-vote:0:authored:instruction-contract -->

<a id="sampler-feedback-instructions"></a>

## Sampler feedback instructions

<ins><!-- d3d12-review-inline:begin:dxil:sf-instructions:0:authored:common-contract -->The [common sampler feedback contract](common-shader-internals.md#sampler-feedback) defines map updates, stage and capability requirements, paired-resource identity and the zero-offset footprint.<!-- d3d12-review-inline:end:dxil:sf-instructions:0:authored:common-contract --></ins>

<ins><!-- d3d12-review-inline:begin:dxil:sf-instructions:0:authored:opcodes -->`WriteSamplerFeedback`, `WriteSamplerFeedbackBias`, `WriteSamplerFeedbackLevel` and `WriteSamplerFeedbackGrad` have opcodes 174, 175, 176 and 177, respectively.<!-- d3d12-review-inline:end:dxil:sf-instructions:0:authored:opcodes --></ins>

<ins><!-- d3d12-review-inline:begin:dxil:sf-instructions:0:authored:coordinates -->For `Texture2D`, the active coordinates are `c0` and `c1`. For `Texture2DArray`, `c2` additionally selects the array slice. These resource kinds and active components apply to all four instructions.<!-- d3d12-review-inline:end:dxil:sf-instructions:0:authored:coordinates --></ins>

<ins><!-- d3d12-review-inline:begin:dxil:sf-instructions:0:authored:shader-flags -->Use of any sampler feedback instruction sets bit 26 of the `i64` shader-flags value carried by entry-function property tag `kDxilShaderFlagsTag` (0).<!-- d3d12-review-inline:end:dxil:sf-instructions:0:authored:shader-flags --></ins>

### WriteSamplerFeedback

```llvm
declare void @dx.op.writeSamplerFeedback(
    i32,                  ; opcode
    %dx.types.Handle,     ; feedback map texture handle (output)
    %dx.types.Handle,     ; sampled texture handle
    %dx.types.Handle,     ; sampler handle
    float,                ; coordinate c0
    float,                ; coordinate c1
    float,                ; coordinate c2
    float,                ; coordinate c3
    float)                ; clamp
```

### WriteSamplerFeedbackBias

```llvm
declare void @dx.op.writeSamplerFeedbackBias(
    i32,                  ; opcode
    %dx.types.Handle,     ; feedback map texture handle (output)
    %dx.types.Handle,     ; sampled texture handle
    %dx.types.Handle,     ; sampler handle
    float,                ; coordinate c0
    float,                ; coordinate c1
    float,                ; coordinate c2
    float,                ; coordinate c3
    float,                ; bias: in [-16.f,15.99f]
    float)                ; clamp
```

### WriteSamplerFeedbackLevel

```llvm
declare void @dx.op.writeSamplerFeedbackLevel(
    i32,                  ; opcode
    %dx.types.Handle,     ; feedback map texture handle (output)
    %dx.types.Handle,     ; sampled texture handle
    %dx.types.Handle,     ; sampler handle
    float,                ; coordinate c0
    float,                ; coordinate c1
    float,                ; coordinate c2
    float,                ; coordinate c3
    float)                ; mip level
```

### WriteSamplerFeedbackGrad

```llvm
declare void @dx.op.writeSamplerFeedbackGrad(
    i32,                  ; opcode
    %dx.types.Handle,     ; feedback map texture handle (output)
    %dx.types.Handle,     ; sampled texture handle
    %dx.types.Handle,     ; sampler handle
    float,                ; coordinate c0
    float,                ; coordinate c1
    float,                ; coordinate c2
    float,                ; coordinate c3
    float,                ; ddx0
    float,                ; ddx1
    float,                ; ddx2
    float,                ; ddy0
    float,                ; ddy1
    float,                ; ddy2
    float)                ; clamp
```

<a id="native-vectors"></a>

## Native vector intrinsics

Vector representation, storage, indexing and availability are defined in [Common shader internals](common-shader-internals.md#dxil-vectors).

<a id="dxil-vector-buffer-access"></a>

### Raw and structured buffer access

<ins><!-- d3d12-review-inline:begin:common-shader-internals:V-native-vectors:3:authored:buffer-operations -->`dx.op.rawBufferVectorLoad` (opcode 303) loads a vector from a raw or structured SRV or UAV buffer. `dx.op.rawBufferVectorStore` (opcode 304) stores a vector to a raw or structured UAV buffer. Their supported element types are `half`, `float`, `double`, `i16`, `i32` and `i64`, subject to the support conditions in [Primitive types](common-shader-internals.md#primitive-types).<!-- d3d12-review-inline:end:common-shader-internals:V-native-vectors:3:authored:buffer-operations --></ins>

<ins><!-- d3d12-review-inline:begin:common-shader-internals:V-native-vectors:4:authored:buffer-coordinates -->For a raw buffer, `index` is a byte offset and `elementOffset` is `undef`. For a structured buffer, `index` selects an element and `elementOffset` is the byte offset within that element. The `alignment` operand is a constant specifying the relative access alignment. The store's value operand must not be `undef`.<!-- d3d12-review-inline:end:common-shader-internals:V-native-vectors:4:authored:buffer-coordinates --></ins>

<ins><!-- d3d12-review-inline:begin:common-shader-internals:V-native-vectors:5:authored:declaration-notation -->In the declarations below, `N` is the number of vector elements, `T` is the scalar element type, and `TY` is its overload suffix, such as `f16` for `half` or `f32` for `float`. These symbols stand for the corresponding concrete types and overload names.<!-- d3d12-review-inline:end:common-shader-internals:V-native-vectors:5:authored:declaration-notation --></ins>

<!-- d3d12-review-context:begin:common-shader-internals:V-native-vectors:6:modified:buffer-declarations -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**

```llvm
%dx.types.ResRet.vNTY = type { <N x T>, i32 }

declare %dx.types.ResRet.vNTY @dx.op.rawBufferVectorLoad.vNTY(
    i32 %opcode,
    %dx.types.Handle %resource,
    i32 %index,
    i32 %elementOffset,
    i32 %alignment)

declare void @dx.op.rawBufferVectorStore.vNTY(
    i32 %opcode,
    %dx.types.Handle %resource,
    i32 %index,
    i32 %elementOffset,
    <N x T> %value,
    i32 %alignment)
```

<!-- d3d12-review-context:end:common-shader-internals:V-native-vectors:6:modified:buffer-declarations -->

<ins><!-- d3d12-review-inline:begin:common-shader-internals:V-native-vectors:7:authored:buffer-return-status -->The load result contains the vector followed by an `i32` [mapping status](common-shader-internals.md#dxil-mapping-status), consumed by `dx.op.checkAccessFullyMapped`.<!-- d3d12-review-inline:end:common-shader-internals:V-native-vectors:7:authored:buffer-return-status --></ins>

<a id="dxil-vector-elementwise"></a>

### Native vector intrinsic overloads

The generic unary, binary and tertiary native vector forms are:

```llvm
declare <N x T> @dx.op.unary.vNTY(i32 %opcode, <N x T> %operand1)
declare <N x T> @dx.op.binary.vNTY(i32 %opcode, <N x T> %operand1, <N x T> %operand2)
declare <N x T> @dx.op.tertiary.vNTY(i32 %opcode, <N x T> %operand1, <N x T> %operand2, <N x T> %operand3)
```

<ins><!-- d3d12-review-inline:begin:common-shader-internals:V-native-vectors:9:modified:overload-inventory-introduction -->The following operations have native vector overloads:<!-- d3d12-review-inline:end:common-shader-internals:V-native-vectors:9:modified:overload-inventory-introduction --></ins>

| Opcode | Name | Class |
|---|---|---|
| 6 | FAbs | Unary |
| 7 | Saturate | Unary |
| 8 | [IsNaN](#special-float-classifications) | IsSpecialFloat |
| 9 | [IsInf](#special-float-classifications) | IsSpecialFloat |
| 10 | [IsFinite](#special-float-classifications) | IsSpecialFloat |
| 11 | [IsNormal](#special-float-classifications) | IsSpecialFloat |
| 12 | Cos | Unary |
| 13 | Sin | Unary |
| 14 | Tan | Unary |
| 15 | Acos | Unary |
| 16 | Asin | Unary |
| 17 | Atan | Unary |
| 18 | Hcos | Unary |
| 19 | Hsin | Unary |
| 20 | Htan | Unary |
| 21 | Exp | Unary |
| 22 | Frc | Unary |
| 23 | Log | Unary |
| 24 | Sqrt | Unary |
| 25 | Rsqrt | Unary |
| 26 | Round_ne | Unary |
| 27 | Round_ni | Unary |
| 28 | Round_pi | Unary |
| 29 | Round_z | Unary |
| 30 | Bfrev | Unary |
| 31 | Countbits | UnaryBits |
| 32 | <ins><!-- d3d12-review-inline:begin:common-shader-internals:V-native-vectors:14:modified:firstbitlo-identifier -->FirstbitLo<!-- d3d12-review-inline:end:common-shader-internals:V-native-vectors:14:modified:firstbitlo-identifier --></ins> | UnaryBits |
| 33 | <ins><!-- d3d12-review-inline:begin:common-shader-internals:V-native-vectors:15:modified:firstbithi-identifier -->FirstbitHi<!-- d3d12-review-inline:end:common-shader-internals:V-native-vectors:15:modified:firstbithi-identifier --></ins> | UnaryBits |
| 34 | <ins><!-- d3d12-review-inline:begin:common-shader-internals:V-native-vectors:16:modified:firstbitshi-identifier -->FirstbitSHi<!-- d3d12-review-inline:end:common-shader-internals:V-native-vectors:16:modified:firstbitshi-identifier --></ins> | UnaryBits |
| 35 | FMax | Binary |
| 36 | FMin | Binary |
| 37 | IMax | Binary |
| 38 | IMin | Binary |
| 39 | UMax | Binary |
| 40 | UMin | Binary |
| 46 | FMad | Tertiary |
| 47 | Fma | Tertiary |
| 48 | IMad | Tertiary |
| 49 | UMad | Tertiary |
| 83 | DerivCoarseX | Unary |
| 84 | DerivCoarseY | Unary |
| 85 | DerivFineX | Unary |
| 86 | DerivFineY | Unary |
| 115 | WaveActiveAllEqual | WaveActiveAllEqual |
| 117 | WaveReadLaneAt | WaveReadLaneAt |
| 118 | WaveReadLaneFirst | WaveReadLaneFirst |
| 119 | WaveActiveOp | WaveActiveOp |
| 120 | WaveActiveBit | WaveActiveBit |
| 121 | WavePrefixOp | WavePrefixOp |
| 122 | QuadReadLaneAt | QuadReadLaneAt |
| 123 | QuadOp | QuadOp |
| 165 | WaveMatch | WaveMatch |
| 166 | WaveMultiPrefixOp | WaveMultiPrefixOp |

<a id="dxil-vector-reductions"></a>

### Vector reductions and dot product

<ins><!-- d3d12-review-inline:begin:common-shader-internals:V-native-vectors:11:modified:vector-reduce-class -->`VectorReduce` combines a vector of elements into a single element with the same type as the vector element type. The opcode parameter specifies the combining operation.<!-- d3d12-review-inline:end:common-shader-internals:V-native-vectors:11:modified:vector-reduce-class --></ins>

<!-- d3d12-review-context:begin:common-shader-internals:V-native-vectors:12:modified:reduction-operation-contracts -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**

| Opcode | Name | Element types | Result |
|---|---|---|---|
| 309 | `VectorReduceAnd` | `i1`, `i8`, `i16`, `i32`, `i64` | Bitwise AND of all vector elements. |
| 310 | `VectorReduceOr` | `i1`, `i8`, `i16`, `i32`, `i64` | Bitwise OR of all vector elements. |
| 311 | `FDot` | `half`, `float` | `a[0] * b[0] + a[1] * b[1] + ... + a[N - 1] * b[N - 1]`. Both operands have the same element count and type; the scalar result has that element type. |

<!-- d3d12-review-context:end:common-shader-internals:V-native-vectors:12:modified:reduction-operation-contracts -->

```llvm
declare T @dx.op.vectorReduce.vNTY(i32 %opcode, <N x T> %operand)
declare T @dx.op.dot.vNTY(i32 %opcode, <N x T> %operand1, <N x T> %operand2)
```

<a id="dxil-vector-validation"></a>

### Native vector validation

<ins><!-- d3d12-review-inline:begin:common-shader-internals:V-native-vectors:13:modified:recursive-validation -->Validation checks operation and intrinsic arguments for disallowed native vector uses and recursively examines aggregate types for native vector components.<!-- d3d12-review-inline:end:common-shader-internals:V-native-vectors:13:modified:recursive-validation --></ins>
