# HLSL Shader Model 6.9

## Contents

- [HLSL Shader Model 6.9](#hlsl-shader-model-69)
  - [Contents](#contents)
  - [Introduction](#introduction)
  - [Required Features](#required-features)
  - [Opacity Micromaps](#opacity-micromaps)
  - [Shader Execution Reordering](#shader-execution-reordering)
  - [16-bit IsSpecialFloat](#16-bit-isspecialfloat)
  - [Long Vectors](#long-vectors)
  - [DXIL Vectors](#dxil-vectors)

## Introduction

This document covers the new Shader Model 6.9.

A brief summary of each new feature is listed below along with links to detailed proposals.

## Required Features

Shader Model 6.9 makes the following previously optional features required for all conforming implementations: native 16-bit shader operations (`Native16BitShaderOpsSupported`), wave operations (`WaveOps`), and 64-bit integer shader operations (`Int64ShaderOps`).

Details: [Proposal 0044 — SM 6.9 Required Features](https://github.com/microsoft/hlsl-specs/blob/main/proposals/0044-sm69-required-features.md)

## Opacity Micromaps

Opacity Micromaps (OMM) allow DirectX Ray Tracing developers to trivially classify ray-triangle hits as miss or hit without having to invoke an any-hit shader. Shader Model 6.9 adds a new `RAYTRACING_PIPELINE_FLAG`, `RAYTRACING_PIPELINE_FLAG_ALLOW_OPACITY_MICROMAPS`, to enable OMM in HLSL pipeline configurations, a new `RAY_FLAG_FORCE_OMM_2_STATE` for use at trace time, and a new `RAYQUERY_FLAG_ALLOW_OPACITY_MICROMAPS` template parameter for `RayQuery` objects used with inline raytracing.

Details: [Proposal 0024 — Opacity Micromaps](https://github.com/microsoft/hlsl-specs/blob/main/proposals/0024-opacity-micromaps.md)

## Shader Execution Reordering

Shader Execution Reordering (SER) introduces `MaybeReorderThread`, a built-in function for raygeneration shaders that enables application-controlled reordering of work across the GPU for improved execution and data coherence.

Additionally, `HitObject` is introduced to decouple traversal, intersection testing, and anyhit shading from closesthit and miss shading, increasing flexibility and enabling `MaybeReorderThread` to improve coherence for closesthit and miss shading as well as subsequent operations.

Details: [Proposal 0027 — Shader Execution Reordering](https://github.com/microsoft/hlsl-specs/blob/main/proposals/0027-shader-execution-reordering.md)

## 16-bit IsSpecialFloat

Due to a longstanding bug, the HLSL intrinsics `isinf`, `isnan`, and `isfinite` implicitly cast 16-bit float arguments to 32-bit float, preventing the 16-bit DXIL overloads from being used. Shader Model 6.9 fixes this by adding native 16-bit float overloads for `isinf`, `isnan`, and `isfinite`, and also introduces a new `isnormal` intrinsic. These 16-bit overloads generate the appropriate 16-bit DXIL operations in SM 6.9 and later, while emulating via LLVM IR for earlier shader models.

Details: [Proposal 0038 — 16-bit IsSpecialFloat](https://github.com/microsoft/hlsl-specs/blob/main/proposals/0038-16bit-isspecialfloat.md)

## Long Vectors

HLSL has previously supported vectors of up to four elements (e.g. `int3`, `float4`). Shader Model 6.9 extends this to support vectors with between 5 and 1024 elements using the existing `vector<T, N>` template syntax. Long vectors enable machine learning workloads expressed as vector-matrix operations to be represented directly in HLSL. Elementwise intrinsics, loads and stores through `ByteAddressBuffer` and `StructuredBuffer`, and groupshared memory are all supported for long vectors.

Details: [Proposal 0026 — HLSL Long Vectors](https://github.com/microsoft/hlsl-specs/blob/main/proposals/0026-hlsl-long-vector-type.md)

## DXIL Vectors

DXIL 1.9 enables native vector types, as supported by LLVM 3.7, in the DXIL intermediate representation. A new `rawBufferVectorLoad` opcode is added to load an entire vector in a single operation, and existing elementwise intrinsics are extended to accept vector arguments. This is the underlying DXIL representation that supports the HLSL Long Vectors feature above.

Details: [Proposal 0030 — DXIL Vectors](https://github.com/microsoft/hlsl-specs/blob/main/proposals/0030-dxil-vectors.md)

See also: [Proposal 0033 — DXIL 1.9](https://github.com/microsoft/hlsl-specs/blob/main/proposals/0033-dxil19.md) 

