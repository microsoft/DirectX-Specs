# HLSL Shader Model 6.7

v1.0 2022-08-01

# Contents

- [Introduction](#introduction)
- [Advanced Texture Operations](#advanced-texture-operations)
  - [Raw Gather](#raw-gather)
  - [SampleCmpLevel](#samplecmplevel)
  - [Programmable Offsets](#programmable-offsets)
  - [Writable MSAA Textures](#writable-msaa-textures)
- [QuadAny and QuadAll](#quadany-and-quadall)
- [Helper Lanes in Wave Ops Mode](#helper-lanes-in-wave-ops-mode)

---

# Introduction

This document covers the new Shader Model 6.7.  A brief summary of each new feature
is listed below along with links to detailed specifications.

# Advanced Texture Operations

Shader Model 6.7 includes an optional feature called Advanced Texture Operations that contains several useful texture capabilities that grant greater ability to retrieve and set texture data in various ways.

See the Shader Model 6.7 [Advanced Texture Operations](HLSL_SM_6_7_Advanced_Texture_Ops.md) documenation for more details about all these features. Below are brief individual summaries.

## Raw Gather

Advanced Texture Operations adds the ability to retrieve complete, unprocessed texture elements including all the channels packed into appropriately sized unsigned integers using _raw gathers_.

To get the full benefit of these gather operations requires the expanded ability to cast textures of various sorts into unsigned integer resource views. This requires using the new resource creation methods introduced with [Enhanced Barriers](D3D12EnhancedBarriers.md#id3d12device10createcommittedresource3) and setting the castable formats parameters to the appropriately sized `UINT` format.

In this way, unsigned integer textures with varied backing resources can be sampled within shaders to retrieve the raw representation of the contents that you can process in any way you want.

See the [Raw Gather](HLSL_SM_6_7_Advanced_Texture_Ops.md#raw-gather) section of the Advanced Texture Ops documentation for more details.

## SampleCmpLevel

Advanced Texture Operations adds `SampleCmpLevel`, a new sample compare operation that neither uses the MIP level determined by the derivatives as with `SampleCmp` does, nor is it limited to MIP level zero as with `SampleCmpLevelZero`. The shader author can specify the level through a parameter.

See the [SampleCmpLevel](HLSL_SM_6_7_Advanced_Texture_Ops.md#samplecmplevel) section of the Advanced Texture Ops documentation for more details.

## Programmable Offsets

Advanced Texture Operations eliminates the requirement that offsets for sample and load operations be immediate values. This applies to all Sample and Load builtin functions including the newly-added `SampleCmpLevel`. Any variables can now be used for offsets, but the respected offset range remains [-8,7] corresponding to the 4 least significant bits of the value.

See the [Programmable Offsets](HLSL_SM_6_7_Advanced_Texture_Ops.md#programmable-offsets) section of the Advanced Texture Ops documentation for more details.

## Writable MSAA Textures

Advanced Texture Operations introduces writable multisample texture resource views that can be read and written using assignments to subscript (`[]`)and sample subscript `.sample[][]` operations.

See the [Writable MSAA Textures](HLSL_SM_6_7_Advanced_Texture_Ops.md#writable-msaa-textures) section of the Advanced Texture Ops documentation for more details.

# QuadAny and QuadAll

Shader Model 6.7 adds two new builtin functions to HLSL: `QuadAny` and `QuadAll`. These functions return whether the provided expression parameter is true for any lane (`QuadAny`) or all lanes (`QuadAll`) in the current quad. With these you can avoid undefined behavior by executing shader code conditional on quad-level uniformity.

See the Shader Model 6.7 [QuadAny/QuadAll](HLSL_SM_6_7_QuadAny_QuadAll.md) documentation for more details.

# Helper Lanes in Wave Ops Mode

Shader Model 6.7 adds the `WaveOpsIncludeHelperLanes` entry function attribute. By applying this attribute, any wave ops invoked by shaders compiled with that entry function will include helper lanes in their calculations. This further advances the ability to leverage and identify helper lanes in shader development.

See the Shader Model 6.7 [Helper Lanes in Wave Ops Mode](HLSL_SM_6_7_Wave_Ops_Include_Helper_Lanes.md) documenation for more details.

# Change Log

Version|Date|Description
-|-|-
1.00|01 Aug 2022| First draft

