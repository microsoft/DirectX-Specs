<h1>HLSL Shader Model 6.8</h1>

v0.6 2024-03-11

<h2>Contents</h2>

- [Introduction](#introduction)
- [Work Graphs](#work-graphs)
- [Expanded Comparison Sampling](#expanded-comparison-sampling)
- [Extended Command Information](#extended-command-information)
- [Wave Size Range](#wave-size-range)
- [Change Log](#change-log)

## Introduction

This document covers the new Shader Model 6.8.  A brief summary of each new feature
is listed below along with links to detailed specifications.

## Work Graphs

Work Graphs define a system of shader nodes that feed into each other
to enable tailored GPU work creation.

See the [Work Graphs](WorkGraphs.md) documentation for more details.

## Expanded Comparison Sampling

Several existing operations have been expanded to support Comparison Samplers.
New methods: `SampleCmpBias`, `SampleCmpGrad`.
Added overloads: `CalculateLevelOfDetail`, `CalculateLevelOfDetailUnclamped`.

See the [Expanded Comparison Sampling](https://microsoft.github.io/hlsl-specs/proposals/0014-expanded-comparison-sampling/) documentation for more details.

## Extended Command Information

Two new system-value semantics are required to be supported in HLSL shader model 6.8:

- `SV_StartVertexLocation` - Reports `StartVertexLocation` from `DrawInstanced()` or `BaseVertexLocation` from `DrawIndexedInstanced()` to a vertex shader.
- `SV_StartInstanceLocation` - Reports `StartInstanceLocation` From `Draw*Instanced` to a vertex shader.

See the [Extended Command Information](https://microsoft.github.io/hlsl-specs/proposals/0015-extended-command-info/) documentation for more details.

## Wave Size Range

A new variant of the [WaveSize](HLSL_SM_6_6_WaveSize.md) attribute is added: `[WaveSize( min, max [, preferred] )]`.
This allows you to specify a range and optional preferred size.

See the [Wave Size Range](https://microsoft.github.io/hlsl-specs/proposals/0013-wave-size-range/) documentation for more details.

## Change Log

Version|Date|Description
-|-|-
0.1| 29 Jun 2021|Initial draft outline
0.2| 20 Oct 2021|Update spec links
0.3| 24 Aug 2022|Add WaveMMA spec link
0.4| 01 May 2023|Update included elements
0.5| 21 Jun 2023|Update for preview release
0.6| 11 Mar 2024|Remove WaveMMA; remove experimental; add Expanded Comparison Sampling, Extended Command Information, and Wave Size Range
