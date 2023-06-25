<h1>HLSL Shader Model 6.8</h1>

v0.5 2023-06-21

<h2> Contents</h2>

- [Introduction](#introduction)
- [Work Graphs (experimental)](#work-graphs-experimental)
- [Wave Matrix (experimental)](#wave-matrix-experimental)
- [Change Log](#change-log)

# Introduction

This document covers the new Shader Model 6.8.  A brief summary of each new feature
is listed below along with links to detailed specifications.

# Work Graphs (experimental)

Work Graphs define a system of shader nodes that feed into each other
to enable tailored GPU work creation.

See the [Work Graphs (experimental)](WorkGraphs.md) documentation for more details.

# Wave Matrix (experimental)

Wave Matrices are type abstractions of hardware support
for higher bandwidth matrix multiplications, useful
in machine learning and image processing.

See the [Wave Matrix (experimental)](HLSL_SM_6_8_WaveMatrix.md) documentation for more details about this feature, also called Wave Matrix Multiply and Accumulate or WaveMMA for short.

# Change Log

Version|Date|Description
-|-|-
0.1| 29 Jun 2021|Initial draft outline
0.2| 20 Oct 2021|Update spec links
0.3| 24 Aug 2022|Add WaveMMA spec link
0.4| 01 May 2023|Update included elements
0.5| 21 Jun 2023|Update for preview release
