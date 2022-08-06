# QuadAny and QuadAll Intrinsics

v1.0 2022-08-01

Two new quad intrinsics `QuadAny` and `QuadAll` are introduced in HLSL for shader model 6.7.

These intrinsics perform compare operations on local values across all lanes of the current quads. Quads are defined [here](https://github.com/microsoft/DirectXShaderCompiler/wiki/Wave-Intrinsics#quad-wide-shuffle-operations) and [here](HLSL_SM_6_6_Derivatives.md). The routines will help shader authors quickly evaluate if a certain condition is true for any or all pixels or lanes in the current quad.

The intrinsics are supported in pixel, compute, mesh and amplification shaders.
The routines always compare values from all four lanes of the current quad.

Since these routines rely on quad-level values, they assume that all lanes in the quad are active, including helper lanes (those that are masked from final writes). This means they should be treated like the existing DDX and DDY intrinsics in that sense.

Unlike for most other wave intrinsics, for these routines, reading from active helper lanes is well defined, and the return value is also well-defined on helper lanes.

These routines assume that flow control execution is uniform at least across the quad. If the routimes are called in a branch in non-quad-uniform matter the behavior is undefined.

## Contents

- [QuadAny and QuadAll Intrinsics](#quadany-and-quadall-intrinsics)
  - [Table of Contents](#table-of-contents)
  - [QuadAny](#quadany)
  - [QuadAll](#quadall)
  - [DXIL](#dxil)
  - [How to use QuadAny/QuadAll to ensure uniform flow control across the quad](#how-to-use-quadanyquadall-to-ensure-uniform-flow-control-across-the-quad)
    - [Example 1 - Valid use of direct shader input in divergent control flow](#example-1---valid-use-of-direct-shader-input-in-divergent-control-flow)
    - [Example 2 - Undefined use of shader computed value in divergent control flow](#example-2---undefined-use-of-shader-computed-value-in-divergent-control-flow)
    - [Example 3 - Fixed by hoisting Sample to uniform control flow](#example-3---fixed-by-hoisting-sample-to-uniform-control-flow)
    - [Example 4 - Fixed using QuadAny for efficiency](#example-4---fixed-using-quadany-for-efficiency)
  - [Older Shader Models](#older-shader-models)
  - [Caps Flag](#caps-flag)
  - [Issues](#issues)
    - [Issue - QuadGetLaneIndex](#issue---quadgetlaneindex)
  - [Change Log](#change-log)

## QuadAny

```C++
bool QuadAny(bool expr)
```

Returns true if &lt;expr&gt; is `true` in any lane of the current quad.

## QuadAll

```C++
bool QuadAll(bool expr)
```

Returns true if &lt;expr&gt; is `true` in all lanes of the current quad.

## DXIL

A new shared DXIL op  `quadVoteOp` is introduced for these intrinsics.  The last argument of the op call is a value of `QuadVoteOpKind` enum that determines which operation to perform.

Example:

```C++
%read1 = ...
%read2 = ...

// QuadAny
%result1 = call i1 @dx.op.quadVoteOp.i1(i32 <op>, i1 %read1, i8 0) 

// QuadAll
%result2 = call i1 @dx.op.quadVoteOp.i1(i32 <op>, i1 %read2, i8 1)
```

## How to use QuadAny/QuadAll to ensure uniform flow control across the quad

Intrinsics that calculate gradient values read texture coordinates
from all four threads in a quad to calculate the gradients.

In *divergent control flow*, inactive lanes may use the same temporary registers to store different values on other code paths.
Therefore, it is not well-defined to read a value from an inactive lane
corresponding to a temporary value in an active lane.

For well-defined gradient calculations on temporary values,
all lanes in the quad must be active.
This is a weaker requirement than *uniform control flow* called *quad-uniform control flow*.
Quad-uniform control flow may still be *divergent* across a wave,
but it satisfies the requirements for well-defined gradient calculations on each active quad,
since each gradient operation will only read from other lanes in the same quad.
`QuadAny` makes it convenient to write code that preserves quad-uniform control flow.

The following examples demonstrate the utility of `QuadAny` by using `Sample`,
which implies gradient operations on the coordinate argument,
to affect only a portion of pixels not guaranteed to align to quad boundaries.

### Example 1 - Valid use of direct shader input in divergent control flow

The coordinate used in `Sample(...)` is a direct shader input,
rather than a shader-computed temporary value.
The gradient operation is well-defined in this case,
even though is is not performed under *quad-uniform control flow*.

```HLSL
SamplerState s0 : register(s0);
Texture2D t0 : register(t0);

float4 main(float2 pos : SV_POSITION, float2 uv : TEXCOORD0) : SV_Target
{
    float4 ret = 0;
    if (pos.x > SCREEN_X)
    {
        ret = t0.Sample(s0, uv);
    }
    return ret;
}
```

### Example 2 - Undefined use of shader computed value in divergent control flow

This example is not technically well-defined because it is reading
a shader-computed value in divergent control flow that is not *quad-uniform*.

```HLSL
SamplerState s0 : register(s0);
Texture2D t0 : register(t0);

float4 main(float2 pos : SV_POSITION, float2 uv : TEXCOORD0) : SV_Target
{
    float4 ret = 0;
    float2 temp_uv = modifyuv(uv);

    if (pos.x > SCREEN_X)
    {
        ret = t0.Sample(s0, temp_uv);
    }
    return ret;
}
```

However, the above example may be simple enough to work in practice,
even though the basic rule has been broken.
This modified version illustrates why the basic rule exists.

```HLSL
SamplerState s0 : register(s0);
Texture2D t0 : register(t0);

float4 do_work() { ... }

float4 main(float2 pos : SV_POSITION, float2 uv : TEXCOORD0) : SV_Target
{
    float4 ret = 0;
    float2 temp_uv = modifyuv(uv);

    if (pos.x <= SCREEN_X)
    {
        // the code in this branch may re-use the register used to store temp_uv
        // because temp_uv is never used by a thread that takes this branch.
        ret = do_work();
    }
    else
    {
        // Reading temp_uv from inactive lanes is thus undefined here.
        // Sample uses gradient operations, which read across lanes,
        // so those gradients may be undefined.
        ret = t0.Sample(s0, temp_uv);
    }
    return ret;
}
```

Even if the quad is operating in lock-step,
the code path that takes the first branch of the `if` will never use `temp_uv`,
making that register available to store other temporary values in `do_work()`.
Once lock-step execution reaches the `Sample` operation in the second block,
reading the `temp_uv` value from lanes that took a different branch
could now result in undefined gradient values.

### Example 3 - Fixed by hoisting Sample to uniform control flow

This example demonstrates the naive way to fix the problem, by pulling (hoisting) the `Sample` operation out of the non-uniform control flow
to ensure well-defined gradients.
This is an operation FXC would have performed automatically to make the code legal.
But it is performing the `Sample` operation on every pixel,
even when it may only contribute to the result on a few of them.
This may result in extra memory bandwidth usage and worse performance.

```HLSL
SamplerState s0 : register(s0);
Texture2D t0 : register(t0);

float4 main(float2 pos : SV_POSITION, float2 uv : TEXCOORD0) : SV_Target
{
    float4 ret = 0;
    float2 temp_uv = modifyuv(uv);
    float4 sampled = t0.Sample(s0, temp_uv);

    if (pos.x > SCREEN_X)
    {
        ret = sampled;
    }
    return ret;
}
```

A more efficient approach would be to only perform the work on lanes in quads
where at least one lane in the quad will actually use the result.

### Example 4 - Fixed using QuadAny for efficiency

This example uses QuadAny to ensure quad-uniform control flow
when calculating the coordinate and performing the Sample operation,
then assigns the result on just the pixels desired.
Only lanes in quads that have at least one pixel active under the condition
will perform the `Sample` operation and call `modifyuv`.

```HLSL
SamplerState s0 : register(s0);
Texture2D t0 : register(t0);

float4 main(float2 pos : SV_POSITION, float2 uv : TEXCOORD0) : SV_Target
{
    float4 ret = 0;
    bool cond = pos.x > SCREEN_X;

    if (QuadAny(cond))
    {
        float2 temp_uv = modifyuv(uv);
        float4 sampled_result = t0.Sample(s0, temp_uv);
        if (cond)
        {
            ret = sampled_result;
        }
    }
    return ret;
}
```

## Older Shader Models

For shader models lower than 6.7 the `QuadAny` and `QuadAll` intrinsics are supported via software callback implemented using the quad intrinsics that exist on older shader models like this:

```HLSL
bool QuadAny(bool expr) {
  expr |= QuadReadAcrossX(expr);
  expr |= QuadReadAcrossY(expr);
  expr |= QuadReadAcrossDiagonal(expr)
  return expr;
}

bool QuadAll(bool expr) {
  return !QuadAny(!expr);
}
```

## Caps Flag

`BOOL WaveOps`: The driver should expose the waveOps caps flag if it can support the intrinsics in this specification. The driver must set this cap for the D3D runtime to load shaders containing these intrinsics. On implementations that do not set this bit, CreateShader() will fail on such shaders. This is consistent with other quad intrinsics that also use the waveOps cap flag.

## Issues

### Issue - QuadGetLaneIndex

- Should we also add `QuadGetLaneIndex` intrinsics that would return the index of the lane in the quad?
  - No. Quad lane index is always  `WaveGetLaneIndex() % 4` so it's already available info and not worth it

## Change Log

Version|Date|Description
-|-|-
1.00|01 Aug 2022|Minor edits for publication
0.05|15 Sep 2021|Another QuadAny/QuadAll example update
0.04|30 Aug 2021|Improve QuadAny/QuadAll example
0.03|12 Jul 2021|First spec review feedback
0.02|08 Jul 2021|Added more info on DXIL op, helper lanes, use case and links to DXIL 1.7 spec
0.01|29 Jun 2021|Initial spec draft
