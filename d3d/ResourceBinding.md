<h1>D3D12 Resource Binding Functional Spec</h1>

v1.22 2/4/2025

---

<h1>Contents</h1>

- [Reduced Overhead on Binding](#reduced-overhead-on-binding)
  - [Memory Residency Management Separated From Binding](#memory-residency-management-separated-from-binding)
  - [Object Lifetime Management Separated From Binding](#object-lifetime-management-separated-from-binding)
  - [Driver Resource State Tracking Separated From Binding](#driver-resource-state-tracking-separated-from-binding)
  - [CPU GPU Mapped Memory Synchronization Separated From Binding](#cpu-gpu-mapped-memory-synchronization-separated-from-binding)
- [Binding Model](#binding-model)
  - [Descriptors](#descriptors)
  - [Descriptor Tables](#descriptor-tables)
  - [Descriptor Heaps](#descriptor-heaps)
    - [Shader Visible Descriptor Heaps - Used During Rendering](#shader-visible-descriptor-heaps---used-during-rendering)
    - [Non Shader Visible Descriptor Heaps](#non-shader-visible-descriptor-heaps)
    - [Transparent Descriptors (Don't Need Descriptor Heaps)](#transparent-descriptors-dont-need-descriptor-heaps)
    - [Populating Descriptor Heaps with Descriptors](#populating-descriptor-heaps-with-descriptors)
    - [NULL Descriptors](#null-descriptors)
  - [Root Arguments](#root-arguments)
  - [Root Signature](#root-signature)
    - [Command List Semantics](#command-list-semantics)
    - [Bundle Semantics](#bundle-semantics)
  - [Using Descriptor Tables](#using-descriptor-tables)
    - [Indexing Descriptor Tables](#indexing-descriptor-tables)
    - [Restrictions on Changing State Pointed to by Descriptor Tables](#restrictions-on-changing-state-pointed-to-by-descriptor-tables)
    - [Out of Bounds Indexing](#out-of-bounds-indexing)
    - [Shader Derivatives and Divergent Indexing](#shader-derivatives-and-divergent-indexing)
  - [Using Constants Directly in the Root Arguments](#using-constants-directly-in-the-root-arguments)
  - [Using Descriptors Directly in the Root Arguments](#using-descriptors-directly-in-the-root-arguments)
  - [Root Argument Limits](#root-argument-limits)
    - [Additional Root Argument Capacity For System Instrumentation](#additional-root-argument-capacity-for-system-instrumentation)
  - [Static Samplers](#static-samplers)
  - [Limitations on Static Samplers](#limitations-on-static-samplers)
- [Levels of Hardware Support](#levels-of-hardware-support)
  - [Limits Invariant on Hardware](#limits-invariant-on-hardware)
- [API](#api)
  - [Capability Querying](#capability-querying)
  - [Creating Descriptor Heaps](#creating-descriptor-heaps)
    - [Descriptor Heap Properties](#descriptor-heap-properties)
      - [Descriptor Heap Configurability Summary](#descriptor-heap-configurability-summary)
      - [Shader Visible Descriptor Heap Pitfall](#shader-visible-descriptor-heap-pitfall)
    - [Descriptor Handles](#descriptor-handles)
    - [Descriptor Heap Methods](#descriptor-heap-methods)
    - [Example: Minimal descriptor heap wrapper](#example-minimal-descriptor-heap-wrapper)
  - [Setting Descriptor Heaps](#setting-descriptor-heaps)
  - [Creating Descriptors](#creating-descriptors)
    - [Shader Resource View](#shader-resource-view)
    - [Constant Buffer View](#constant-buffer-view)
    - [Sampler](#sampler)
    - [Unordered Access View](#unordered-access-view)
    - [Stream Output View](#stream-output-view)
    - [Render Target View](#render-target-view)
  - [Copying Descriptors](#copying-descriptors)
  - [Creating a Root Signature](#creating-a-root-signature)
    - [Root Signature Data Structure](#root-signature-data-structure)
      - [Descriptor Table Bind Types](#descriptor-table-bind-types)
      - [Descriptor Range](#descriptor-range)
      - [Root Descriptor Table](#root-descriptor-table)
      - [Root Constants](#root-constants)
      - [Root Descriptor](#root-descriptor)
      - [Note About Register Space](#note-about-register-space)
      - [Shader visibility](#shader-visibility)
      - [Root SIGNATURE Definition](#root-signature-definition)
    - [Root Signature Data Structure Serialization / Deserialization](#root-signature-data-structure-serialization--deserialization)
    - [Root Signature Creation API](#root-signature-creation-api)
    - [Root Signature in Pipeline State](#root-signature-in-pipeline-state)
  - [Setting a Root Signature](#setting-a-root-signature)
  - [Setting Descriptor Tables in the Root Arguments](#setting-descriptor-tables-in-the-root-arguments)
  - [Setting Constants in the Root Arguments](#setting-constants-in-the-root-arguments)
  - [Setting Descriptors in the Root Arguments](#setting-descriptors-in-the-root-arguments)
  - [Setting IB/VB/SO/RT/DS On A Command List or Bundle](#setting-ibvbsortds-on-a-command-list-or-bundle)
  - [View Manipulation APIs](#view-manipulation-apis)
  - [Root Signature Version 1.1](#root-signature-version-11)
    - [Background](#background)
    - [Optimization Opportunity](#optimization-opportunity)
    - [Flags Added in Root Signature version 1.1](#flags-added-in-root-signature-version-11)
      - [Descriptor Range Flags](#descriptor-range-flags)
      - [Root Descriptor Flags](#root-descriptor-flags)
      - [Consequences of Violating Promises From Static-ness Flags](#consequences-of-violating-promises-from-static-ness-flags)
    - [Root Signature Version 1.1 API](#root-signature-version-11-api)
    - [Versioned Root Signature Data Structure Serialization / Deserialization](#versioned-root-signature-data-structure-serialization--deserialization)
    - [Root Signature Version 1.1 Structures](#root-signature-version-11-structures)
  - [Querying Root Signature Version Support](#querying-root-signature-version-support)
- [Resource Binding In HLSL](#resource-binding-in-hlsl)
  - [Resource aliasing](#resource-aliasing)
  - [Divergence and derivatives](#divergence-and-derivatives)
  - [UAVs in pixel shaders](#uavs-in-pixel-shaders)
  - [Constant buffers](#constant-buffers)
  - [Bytecode changes in SM5.1](#bytecode-changes-in-sm51)
- [HLSL Root Signature Language](#hlsl-root-signature-language)
  - [Version Management](#version-management)
  - [Language Structure](#language-structure)
  - [RootFlags](#rootflags)
  - [RootConstants](#rootconstants)
  - [Visibility](#visibility)
  - [HLSL Root Descriptor Flags](#hlsl-root-descriptor-flags)
  - [Root-level CBV](#root-level-cbv)
  - [Root-level SRV](#root-level-srv)
  - [Root-level UAV](#root-level-uav)
  - [Descriptor Table](#descriptor-table)
    - [HLSL Descriptor Range Flags](#hlsl-descriptor-range-flags)
    - [Descriptor Table CBV](#descriptor-table-cbv)
    - [Descriptor Table SRV](#descriptor-table-srv)
    - [Descriptor Table UAV](#descriptor-table-uav)
    - [Descriptor Table Sampler](#descriptor-table-sampler)
  - [Static Sampler](#static-sampler)
    - [Filter field](#filter-field)
    - [AddressU, AddressV, AddressW field](#addressu-addressv-addressw-field)
    - [ComparisonFunc field](#comparisonfunc-field)
    - [BorderColor field](#bordercolor-field)
- [API Example](#api-example)
  - [Example HLSL Declarations](#example-hlsl-declarations)
  - [Example C++ Code for Defining a Root Signature](#example-c-code-for-defining-a-root-signature)
  - [Using a Root Signature in a Command List](#using-a-root-signature-in-a-command-list)
- [DDI](#ddi)
  - [Capability Query DDIs](#capability-query-ddis)
  - [DDI Descriptor Heaps](#ddi-descriptor-heaps)
  - [DDI Setting Descriptor Heaps](#ddi-setting-descriptor-heaps)
  - [DDI Creating Descriptors](#ddi-creating-descriptors)
    - [DDI Shader Resource View](#ddi-shader-resource-view)
    - [DDI Constant Buffer View](#ddi-constant-buffer-view)
    - [DDI Sampler](#ddi-sampler)
    - [DDI Unordered Access View](#ddi-unordered-access-view)
    - [DDI Render Target View](#ddi-render-target-view)
    - [DDI Depth Stencil View](#ddi-depth-stencil-view)
  - [DDI Copying Descriptors](#ddi-copying-descriptors)
  - [DDI Creating a Root Signature](#ddi-creating-a-root-signature)
    - [DDI Descriptor Table Bind Types](#ddi-descriptor-table-bind-types)
    - [DDI Descriptor Range Flags](#ddi-descriptor-range-flags)
    - [DDI Descriptor Range](#ddi-descriptor-range)
    - [DDI Root Descriptor Table Layout](#ddi-root-descriptor-table-layout)
    - [DDI Root Constants](#ddi-root-constants)
    - [DDI Root Descriptor Flags](#ddi-root-descriptor-flags)
    - [DDI Root Descriptor](#ddi-root-descriptor)
    - [DDI Shader visibility](#ddi-shader-visibility)
    - [DDI Root Signature Definition](#ddi-root-signature-definition)
    - [Root Signature Creation DDI](#root-signature-creation-ddi)
  - [DDI Setting a Root Signature](#ddi-setting-a-root-signature)
  - [DDI Setting Descriptor Tables in the Root Signature](#ddi-setting-descriptor-tables-in-the-root-signature)
  - [DDI Setting Constants in the Root Signature](#ddi-setting-constants-in-the-root-signature)
  - [DDI Setting Descriptors in the Root Signature (Bypassing Descriptor Heap/Tables)](#ddi-setting-descriptors-in-the-root-signature-bypassing-descriptor-heaptables)
  - [DDI Setting IA/VB/SO/RT/DS Descriptors On A Command List / Bundle](#ddi-setting-iavbsortds-descriptors-on-a-command-list--bundle)
  - [DDI View Manipulation](#ddi-view-manipulation)
  - [DDI Clearing root arguments](#ddi-clearing-root-arguments)
- [Change History](#change-history)

---

# Reduced Overhead on Binding

## Memory Residency Management Separated From Binding

Applications have explicit control over which surfaces they need to be
resident (available for the GPU to use directly) to execute. Conversely
they can apply other states on resources such as explicitly making them
not resident or letting the OS have the freedom to choose for certain
classes of applications that wish to proactively minimize their memory
footprint.

The details for the memory model are described outside this document but
the important point here is that the application's management of what is
resident is completely decoupled from how it gives access to resources
to shaders.

Decoupling of residency management from the mechanism for giving shaders
access to resources reduces the system/hardware cost for rendering since
the OS doesn't have to constantly inspect the local binding state to
know what to make resident. Furthermore, shaders no longer have to know
which exact surfaces they may need to reference, as long as the entire
set of possibly accessible resources has been made resident ahead of
time.

## Object Lifetime Management Separated From Binding

Unlike previous APIs, the system no longer tracks bindings of resources
to the pipeline. This used to enable the system to keep alive resources
that the application has released because they are still referenced by
outstanding GPU work.

Before freeing any resource, such as a texture, applications now must
make sure the GPU has completed referencing it. To be clear this means
before an application can safely free a resource that not only has the
final command list referencing a resource been submitted for execution,
but also that the GPU must have completed execution of the command list.

The extra convenience of some form of deferred destruction support is
being considered if feasible. This would provide applications the option
to avoid having to wait all the way until GPU completion before being
allowed to free a surface.

## Driver Resource State Tracking Separated From Binding

The system no longer inspects resource bindings to understand when
resource transitions have occurred which require additional driver/GPU
work. A common example for many GPUs/drivers is having to know when a
surface transitions from being used as an RTV to SRV. Applications
themselves must now identify when any resource transitions that the
system might care about are happening via dedicated APIs.

## CPU GPU Mapped Memory Synchronization Separated From Binding

The system no longer inspects resource bindings to understand if
rendering needs to be delayed because it depends on a resource that has
been mapped for CPU access and has not been unmapped yet. Applications now
have the responsibility to synchronize CPU and GPU memory accesses. To
help with this the system provides mechanisms for the application to
request sleeping of a CPU thread until work completes. Polling could
also be done, but can be wasteful.

# Binding Model

## Descriptors

Descriptors are the primary unit of binding in D3D12.

A descriptor is a relatively small block of data that fully describes an
object to the GPU, in a GPU specific format that may be opaque or
visible to the application depending on the circumstance.

There are many different types of descriptors. Shader Resource Views
(SRVs), Unordered Access Views (UAVs) and Samplers are a few examples.

The size of a descriptor varies by hardware/driver and by object type.
As of this writing, descriptors would be 64 bytes or less in size on
currently known hardware, but there is no guaranteed upper bound.
Hardware/drivers should be designed to keep the descriptor sizes as
small as possible, otherwise the overhead for the application to manage
them would become a problem (making the GPU look bad).

Applications can ask the system to translate API level definitions of
state into hardware descriptors. An SRV, for instance, selects which
underlying resource to use, what set of mipmaps / array slices to use
and the format to interpret the memory. From this API level
configuration information, the hardware descriptor that the driver
generates is device specific and opaque.

Object descriptors do not need to be "freed" or "released". Drivers are
not permitted to attach any allocations to the creation of a descriptor.
A descriptor may, however, encode references to other allocations for
which the application owns the lifetime. For instance a descriptor for
an SRV must contain the GPU virtual address of the D3D resource (e.g.
texture) that the SRV refers to. It is the application's responsibility
to make sure that it does not use an SRV descriptor when the underlying
D3D resource it depends on has been destroyed or is otherwise
inaccessible (such as being declared as nonresident).

One way to use descriptors is to place them in *descriptor heap(s)*,
which are backing memory for descriptors. In this case descriptor
*tables* must be defined -- these identify a range in a descriptor heap
to the pipeline so it knows where to look to find which descriptors to
use at Draw/Dispatch time. These concepts are described more later.

The set of descriptor tables being used at a given time, among other
things, are defined as part of the *root arguments*. The layout of the
root arguments, the *root signature,* is an application specified
definition of a binding space (with a limited maximum size for
efficiency) that identifies how resources in shaders (SRVs, UAVs, CBVs,
Samplers) map into descriptor table locations. The root signature can
also hold a small number of descriptors directly (bypassing the need to
put them into descriptor heaps / tables). Finally the root signature can
even hold inline 32-bit values that show up in the shader as a constant
buffer. The root signature defines the set of all of these (descriptor
tables, descriptors, constants) that an application wants to use with a
given Pipeline State Object, ideally for groups of Pipeline States that
share the same root signature. Once a root signature is set on the
pipeline, all the bindings (root arguments) that it defines (descriptor
tables, descriptors, constants) can each be individually set or changed
including inheritance into bundles. The application can make its own
tradeoff between how many descriptor tables it wants vs inline
descriptors (which take more space but remove an indirection) vs inline
constants (which have no indirection) they want in the root signature.
Details are provided later.

## Descriptor Tables

A descriptor table is logically an array of descriptors. Each descriptor
table stores descriptors of one or more types - SRVs, UAVs, CBs and
Samplers. The graphics and compute pipelines gain access to resources by
referencing into descriptor tables by index.

A descriptor table is actually just a subrange of a descriptor heap.
Descriptor heaps are described in detail later, but basically they
represent the underlying memory allocation for a collection of
descriptors. Since memory allocation is a property of a creating a
descriptor heap, defining a descriptor table out of one is guaranteed to
be as cheap as identifying a region in the heap to the hardware.
Descriptor tables don't need to be created or destroyed at the API or
DDI -- they are merely identified to drivers as an offset and size out
of a heap whenever referenced (the size is not strictly necessary but
useful for validation at least).

The main reason there are two concepts - descriptor *tables* carved out
of descriptor *heaps* - rather than forcing graphics pipeline to always
view the entire heap is the following. Switching descriptor tables
(subrange of a heap) is an inexpensive way to switch the set of
resources a given shader uses from the API -- the shader does not have
to understand where to find resources in a large heap space. It is
certainly possible for an app to define very large descriptor tables
when its shaders want the freedom to select from a vast set of available
textures on the fly (perhaps driven by material data).

Descriptor tables also allow representing the fact that depending on the
hardware certain object types may only have a limited number visible to
the pipeline at a given time. This may be much smaller than the overall
descriptor heap size.

Before going into more specifics about descriptor table use, the next
section covers underlying storage for descriptor tables - descriptor
heaps - in detail.

## Descriptor Heaps

A descriptor heap from the API point of view is a collection of
contiguous allocations of descriptor storage, one allocation for every
object type that the application might ever use. Descriptor heaps
contain many object types that are not part of a Pipeline State, such as
SRVs, UAVs, Constant Buffer Views (CBVs), Samplers.

The primary point of a descriptor heap is to encompass of a bulk of
memory allocation required for storing the descriptor specifications of
object types that shaders reference for as large of a window of
rendering as possible (ideally an entire frame of rendering or more). If
an application is switching which textures the pipeline sees rapidly
from the API, there has to be space in the descriptor heap to define
descriptor tables on the fly for every set of state needed. The
application can choose to reuse definitions if it wishes to keep track,
or just burn through the heap space blindly as it is switching various
object types.

Descriptor heaps also allow individual components in componentized
software to manage descriptor storage separately from each other.

Applications can request whether a descriptor heap is shader visible or
not -- reasons explored later. Applications can create as many
descriptor heaps as desired with whatever properties are desired.
Descriptor heaps that are referenced during rendering by the GPU (shader
visible) have limits on the size of the heap depending on hardware
capability. Applications always have the option to create descriptor
heaps that are purely for staging purposes (non shader visible) that are
unconstrained in size, copying to descriptor heaps that are used for
rendering as necessary.

Levels of functionality in the hardware with respect to heap
configuration is grouped into Tiers of increasing generality, described
later.

### Shader Visible Descriptor Heaps - Used During Rendering

Descriptor heaps that can be referenced by shaders through descriptor
tables come in a couple flavors:

One heap type, `D3D12_SRV_UAV_CBV_DESCRIPTOR_HEAP` can hold Shader
Resource Views, Unordered Access Views and Constant Buffer Views all
intermixed. So any given location in the heap can be any one of the
listed types of descriptors.

Another heap type, `D3D12_SAMPLER_DESCRIPTOR_HEAP` only stores
samplers, reflecting the fact that for the majority of hardware samplers
are managed separately from SRVs, UAVs, CBVs.

Descriptor heaps of these types may be requested to be shader visible or
not when the heap is created. The latter style -- non shader visible -
can be useful for staging descriptors on the CPU.

When requested to be shader visible, each of the above heap types may
have a hardware size limit for any individual descriptor heap
allocation.

Applications can create any number of descriptor heaps. If a shader
visible descriptor heap created by the application is smaller than the
hardware size limit, the driver may choose to suballocate the descriptor
heap out of a larger underlying descriptor heap so that multiple API
descriptor heaps fit within one hardware descriptor heap. The reason
this may happen is that for some hardware, switching between hardware
descriptor heaps during execution requires a GPU wait for idle (ensuring
GPU references to the previous descriptor heap are finished).
Applications must allow for the possibility, therefore, that switching
current descriptor heap may incur a GPU wait for idle.

To avoid impact by this possible wait for idle on descriptor heap
switch, applications can take advantage of breaks in rendering that
would cause the GPU to idle for other reasons as the time to do
descriptor heap switches, since a wait for idle is happening anyway.

The mechanism and semantics for identifying descriptor heaps to shaders
during command list / bundle recording are described in the API
reference.

### Non Shader Visible Descriptor Heaps

The only purpose of descriptor heaps for descriptor types that are not
shader accessible, such as RTVs, is to identify descriptors that the
driver needs to copy/interpret during command list recording (e.g.
SetRenderTargets()) to define what the GPU will later reference during
execution. RTVs and DSVs get bound to the pipeline by having their
contents recorded into / interpreted by the command list directly,
rather than being pointed to via descriptor tables which reference the
descriptor heap at command list execution on the GPU. As soon as a bind
call, like SetRenderTargets() on the command list, returns back to the
app, the source (non shader visible) descriptor heap location is free to
be immediately changed by the application in preparation for the next
call. In other words the driver doesn't hold a reference to application
provided memory.

Non shader visible descriptor heaps are not constrained in size. It is
perfectly reasonable for an application to create non shader visible
descriptor heaps of any size, tiny or huge, whatever is convenient for
how an application might wish to stage descriptors.

An application might even choose to use non shader visible descriptor
heaps to store descriptors that can be used in shaders --
SRV/UAV/CBV/Sampler. This might be convenient for having per-object
descriptor storage in a scene graph that is gathered from as needed at
command list record (rendering) time into a shader visible descriptor
heap.

### Transparent Descriptors (Don't Need Descriptor Heaps)

A few descriptor types don't need descriptor heaps. These are simple
descriptors types that the application can define and don't need driver
translation (or if needed it is trivial). The descriptor types that fall
in this category are Vertex Buffer Views, Index Buffer Views, Stream
Output Views as well as descriptors placed directly in the root
arguments, described later in more detail. Briefly, descriptors used in
root arguments are a subset/special case of full SRV/UAV/CBVs that can
be used in descriptor heaps. This special set of descriptors for root
arguments can be described using only a GPU virtual address pointer to
Buffer style memory without needing any additional data tied to the
descriptor.

These descriptors get bound to the pipeline similarly to RTVs and DSVs
described previously -- the descriptor contents recorded into /
interpreted by the command list directly, rather than being pointed to
via descriptor tables. As soon as a bind call, like SetVertexBuffers()
on the command list, returns back to the app, the source descriptor
memory is free to be immediately changed by the application in
preparation for the next call. In other words the driver doesn't hold a
reference to application provided memory.

The only difference between transparent descriptors described here
(VBV/IBV/SOV and root descriptors) and RTV/DSV descriptors described
above is RTV/DSV descriptors are more complex so their hardware
translation is stored in an opaque descriptor.

Another use for transparent descriptors is that since the definition is
visible to applications, they can generate these descriptors
procedurally, even on the GPU. In particular, a buffer of multiple sets
of {descriptor changes + draw/dispatch parameters} can be produced and
fed to ExecuteIndirect() to issue multiple draw/dispatch operations at
once. ExecuteIndirect() is described in a separate spec.

### Populating Descriptor Heaps with Descriptors

Now back to discussing opaque descriptors that live in descriptor heaps:
fully general SRV / UAV / CBV and Samplers.

When an application has created a descriptor heap it can use methods on
the heap to either generate descriptors directly into the heap or copy
descriptors from one place to another. The initial contents of
descriptor heap memory is undefined, so asking the GPU or driver to
reference such uninitialized memory for rendering produces undefined
results including device reset.

All descriptor heaps are CPU visible, however the style of access
available to the CPU depends on whether the heap is shader visible or
not.

A non shader visible descriptor heap can be read or written by the CPU
freely. The system allocates these in cacheable system memory. As an
example these heaps can be used as a source for copying descriptors,
such as copying to a shader visible descriptor heap.

With a shader visible descriptor heap, the CPU can only write to it.
Attempting to read a shader visible descriptor heap from the CPU
produces undefined behavior (including trying to use it as a copy
source). This constraint allows implementations to use write combined
memory if necessary to maximize throughput from CPU to GPU.

Methods for manipulating descriptors from the CPU can be called by the
application in an immediate, free threaded manner.

### NULL Descriptors

When creating descriptors at the API, applications pass NULL for the
resource pointer in the descriptor definition in order to achieve the
effect of an "unbound" resource. The rest of the descriptor must be
populated as much as possible, such as in the case of SRVs
distinguishing which type of view it is -> Texture2D, Texture1D etc.
Numerical parameters in the view descriptor such as number of mipmaps
must all be set to values that could have been valid for a resource.

In many cases there is a defined behavior for accessing an unbound
resource, such as SRVs which return default values (definitions out of
scope here). Those will be honored when accessing a NULL descriptor as
long as the type of shader access is compatible with the descriptor
type. E.g. if a shader expects a Texture2D SRV and accesses a NULL SRV
defined as a Texture1D, behavior is undefined and could result in device
reset.

Descriptors placed directly in the root arguments (described later)
behave differently. If the pointer value for one of these descriptors is
0 and the GPU dereferences it, behavior is undefined (including device
reset).

For Vertex Buffer Views, Index Buffer Views, Stream Output Views and the
creation of non-root Constant Buffer Views in a descriptor heap, the
view desc can be passed as NULL at the API to result in the unbound
behavior. For Vertex Buffers this can be handy for instance when
unbinding all VBs since NULL can be passed for the view array to
SetVertexBuffers(). Alternatively the view size for individual
VBV/IBV/SOV/CBV descriptors can be set to 0 to achieve the same behavior
-- in this case the buffer address passed in is ignored and can be NULL
without risk of crashing.

## Root Arguments

The *root arguments* are an application defined data structure used by
shaders to locate the resources they need access*.* These arguments
exist as a binding space on a command list for the collection of
resources the application needs to make available to shaders.

The root arguments can include descriptor tables (pointer into
descriptor heap), where the layout of the descriptor table has been
pre-defined.

The root arguments can also include user defined constants (root
constants) directly to shaders without having to go through descriptors
/ descriptor tables.

Thirdly, the root arguments can include a very small amount of
descriptors directly inside it (such as a CBV that is changing per
draw), also saving the application from having to put those descriptors
in a descriptor heap.

The layout of the root arguments is quite flexible, with some
constraints imposed on less capable hardware. Regardless of the level of
hardware, applications should try to make the root arguments as small as
needed for maximum efficiency -- how small exactly works best might
depend on the hardware (more specifics detailed later). Applications can
trade off placing more descriptor tables in the root arguments but fewer
room for root constants, or vice versa.

The contents of the root arguments (the descriptor tables, root
constants and root descriptors) that the application has bound
automatically get versioned by the hardware whenever any part of the
contents change between draw/dispatch calls. So each draw/dispatch gets
a unique full set of root argument state when any argument has changed.

One implication of this is that if the root arguments is large and an
application is only changing a small amount of it, each change can cost
the size of the full root signature in memory overhead (depending on the
implementation). Some hardware has a small amount of dedicated buffering
for root argument versioning though, so any versioning within that size
is the same cost. In general, applications should likely use the root
arguments as sparingly as possible, relying on application controlled
memory such as heaps and descriptor heaps pointing into them to
represent bulk data.

Furthermore, applications should generally sort the layout of the root
arguments in decreasing order of change frequency. This way if some
implementations need to switch to a different memory storage scheme to
version parts of a heavily populated root arguments, the data that is
changing at the highest frequency (near the start of the root arguments)
is most likely to run as efficiently as possible. For very large sets of
root arguments different performance tradeoffs across hardware
architectures can be revealed that can suggest per-architecture tuning
between the size of the root arguments versus the amount of memory the
application is manually versioning in descriptor heaps or other memory
referenced by the root arguments.

Exact size limits for the root arguments are detailed later.

If valuable, D3D could expose a hint from the driver about the native
root argument storage in the hardware if it is less than the maximum
that D3D supports. This would indicate that on this hardware root
arguments that are larger than the native size require some alternate
indirection by the hardware for the portion larger than the minimum.
Hardware would be allowed to report a native root argument size no
larger than the maximum D3D supports, and no less than some (to be
defined) minimum guaranteed size.

## Root Signature

The *root signature* is the definition of an arbitrarily arranged
collection of descriptor tables (including their layout), root constants
and root descriptors. Each entry has a cost towards a maximum limit, so
the application can trade off the balance between how many of each type
of entry the root signature will contain.

The root signature is an object that can be created by manual
specification at the API. All shaders in a Pipeline State must be
compatible with the root signature specified with the Pipeline State, or
else the individual shaders must include embedded root signatures that
match each other. Otherwise Pipeline State creation will fail.

One property of the root signature is that shaders don't have to know
about it when authored, although root signatures can also be authored
directly in shaders if desired. Existing shader assets do not require
any changes to be compatible with root signatures. Shader Model 5.1 is
introduced to provide some extra flexibility (dynamic indexing of
descriptors from within shaders), and can be incrementally adopted
starting from existing shader assets as desired.

### Command List Semantics

At the beginning of a command list, the root signature is undefined.

Graphics shaders have a separate root signature from the compute shader
each independently assigned on a command list.

The root signature set on a command list or bundle must also match the
currently set Pipeline State at Draw/Dispatch otherwise behavior is
undefined. Transient root signature mismatches before Draw/Dispatch are
fine -- such as setting an incompatible Pipeline State before switching
to a compatible root signature (as long as these are compatible by the
time Draw/Dispatch is called).

Setting a PSOPipeline State does not change the root signature. The
application must call a dedicated API for setting the root signature.

Once a root signature has been set on a command list, the signature
defines the set of bindings the application is expected to provide, and
which Pipeline States can be used (those compiled with the same
signature) for the next draw/dispatch calls.

For example a root signature could be defined by the application to have
the following parameters:

[0] A CBV descriptor inline (root descriptor)

[1] A descriptor table containing 2 SRVs, 1 CBVs and 1 UAV

[2] A descriptor table containing 1 sampler

[3] A 4x32-bit collection of root constants

[4] A descriptor table containing an unknown number of SRVs

In this case, before being able to issue a Draw/Dispatch the application
is expected to set the appropriate arguments to each of the slots
[0..4] that the application defined with its current root signature.
For instance at slot [1] a descriptor table must be bound which is a
contiguous region in a descriptor heap that contains (or will contain at
execution) 2 SRVs, 1 CBVs and 1 UAV. Similarly, descriptor tables must
be set at slots [2] and [4], etc.

The application can change part of the root arguments at a time (the
rest remain unchanged). For example if the only thing that needs to
change between draws is one of the constants at slot [3], that is all
the application needs to rebind. As discussed previously, the
driver/hardware versions all root arguments as they are modified
automatically.

If a root signature is changed on a command list, all previous root
arguments become stale and all newly expected arguments must be set
before Draw/Dispatch otherwise behavior is undefined. If the root
signature is redundantly set to the same one currently set, existing
root signature bindings do not become stale.

### Bundle Semantics

Bundles inherit in and return back all command list state except for
primitive topology and Pipeline State. Pipeline State doesn't get
inherited into a bundle, but it does return back out after a bundle
finishes.

That means bundles inherit the command list's root arguments (what is
bound to the various slots in the example above). If a bundle needs to
change some of the inherited root arguments it must first set the root
signature to be the same as the calling command list (the inherited
bindings do not become stale). If the bundle sets the root signature to
be different than the calling command list, that has the same effect as
changing the root signature on the command list described above: all
previous root arguments are stale and newly expected arguments must be
set before Draw/Dispatch, otherwise behavior is undefined. If a bundle
does not need to change any root arguments it does not need to bother
setting the root signature.

Coming out of a bundle, any root signature changes and/or argument
changes a bundle makes are inherited back to the calling command list
when a bundle finishes executing.

The API syntax for authoring/referencing root signatures is described
later.

## Using Descriptor Tables

Descriptor tables, each identifying a range in a descriptor heap, are
bound at slots defined by the current root signature on a command list /
bundle.

If the root signature that gets paired with the shader defines that a
given resource (SRV, UAV, CBV or Sampler) comes from a location in a
descriptor table, then when the shader needs to access such a resource
it will be compiled to find the descriptor by looking in the descriptor
heap range that the matching descriptor table setting on the commandList
has defined.

As a reminder, other resource bindings -- Index Buffers, Vertex Buffer,
Stream Output Buffers, Render Targets and Depth Stencil are done
directly on a command list rather than via descriptor tables (which
point into a descriptor heap). This different handling is simply a
better match for the breadth of hardware. Additionally there are the
non-descriptor table based ways of binding certain resources, such as
using root descriptors. For samplers the alternative binding option is
statically defining them in the root signature declaration (described
later).

### Indexing Descriptor Tables

Shaders cannot dynamically index across descriptor table boundaries from
a given call-site in the shader. However the selection of a descriptor
*within* a descriptor table is allowed to be dynamically indexed in
shader code within ranges of the same descriptor type (such as indexing
across a contiguous region of SRVs).

### Restrictions on Changing State Pointed to by Descriptor Tables

Once command lists / bundles that set descriptor tables have been
submitted to a queue for execution, the application must not edit from
the CPU the portions of descriptor heaps that the GPU might reference
until the application knows the GPU has finished executing the
references.

Work completion can be determined at a tight bound using API exposed
mechanisms for tracking GPU progress, or more coarse mechanisms like
waiting to see that rendering has been sent to display -- whatever suits
the application.

If an application knows that only a subset of the region a descriptor
table points to will be accessed (say due to flow control in the
shader), the other unreferenced descriptors are still free to be
changed.

If an application needs to switch between different descriptor
references between rendering calls, there are a few of approaches the
application can choose from.

(1) Descriptor Table Versioning: Create (or reuse) a separate descriptor
    table for every unique collection of descriptors that is to be
    referenced by a command list / bundle. When editing and reusing
    previously populated areas on descriptor heaps, applications must
    first ensure that the GPU has finished referencing any portion of
    memory that will be recycled.

(2) Dynamic Indexing: Applications can arrange objects that vary across
    draw/dispatch (or even vary within a draw) in a range of a
    descriptor heap, define a descriptor table spanning all of them, and
    from the shader use dynamic indexing of the table during shader
    execution to select which object to use.

(3) Putting descriptors in the root signature directly. Only a very
    small number of descriptors can be managed this way because root
    signature space is limited.

The implication of using descriptor table versioning to manage state
changes is that descriptor memory out of a descriptor heap must be
burned through for every unique set of state referenced by the graphics
pipeline for every command list / bundle that could be either executing,
queued for execution or being recorded at any given time.

Previous graphics APIs hid the state versioning from the application
(drivers were doing this behind the scenes). D3D12 leaves the burden of
managing state versioning to the application for the object types
managed via descriptor heaps and descriptor tables. One benefit of this
is that applications can choose to reuse descriptor table contents as
much as possible rather than always defining a new descriptor table
version for every state switch. By contrast the root arguments are
something that the driver automatically versions.

The ability to set multiple descriptor tables to the pipeline at a time
allows applications to group and switch sets of descriptor references at
different frequencies if desired. For example an application could use a
small number (perhaps just 1) large static descriptor tables that rarely
change or in which regions in the underlying descriptor heap memory are
being populated as needed, with the use of dynamic indexing from the
shader to select textures. At the same time the application could
maintain another class of resources where the set referenced by each
draw call is switched from the CPU using the descriptor table versioning
technique.

The ability to set some state other than descriptor tables in the root
arguments, such as user constants, can also relieve some pressure from
having to burn too many (or any) new descriptors for every rendering call
that needs different data.

### Out of Bounds Indexing

Out of bounds indexing of any descriptor table from the shader results
in a largely undefined memory access, including the possibility of
reading arbitrary in-process memory as if it is a hardware state
descriptor and living with the consequence of what the hardware does
with that. This could produce a device reset, but no worse (e.g. no blue
screen).

### Shader Derivatives and Divergent Indexing

Suppose pixel shader invocations that are executing in a 2x2 stamp (to
support derivative calculations) choose different texture indices to
sample from out of a descriptor table. And suppose the selected sampler
configuration and texture for any given pixel requires an LOD
calculation from texture coordinate derivatives. The LOD calculation and
texture sampling process is done by the hardware independently for each
texture lookup in the 2x2 stamp, which will impact performance.

By default, resource index expressions in HLSL are assumed to be
uniform, as this is the typical case. The HLSL language supports the
'NonUniformResourceIndex(index_expression)' hint, which is applied to
the indexing expression. The hint allows applications to indicate that
the index is dynamic. Knowing that an index is uniform might result in
more efficient code generation on some hardware.

## Using Constants Directly in the Root Arguments

Applications can define root constants in the root arguments, each as a
set of 32-bit values. They appear in HLSL as a constant buffer. Note
that constant buffers for historical reasons are viewed as sets of
4x32-bit values.

Each set of user constants is treated as a scalar array of 32 bit
values, statically indexable and read-only from the shader. Out of
bounds indexing a given set of root constants produces undefined
results. In HLSL, data structure definitions can be provided for the
user constants to give them types.

For example if the root signature defines a set of 4 root constants,
HLSL can overlay the following struct on them.

```C++
struct DrawConstants
{
    uint foo;
    float2 bar;
    int moo;
};
ConstantBuffer<DrawConstants> myDrawConstants : register(b1, space0);
```

Arrays are in cbuffers, such as having entry "float myArray[2];" that 
get mapped onto root constants can only be accessed using static/literal
into the array so the driver compiler can directly map each access 
to a root constant, given the underlying root constant storage 
may not be contiguous and linearly indexable.

Similarly if a cbuffer that is mapped to root constants is an array,
such as "cbuffer myCBArray[2]", access to the cbuffer array must use 
static/literal indexing.

## Using Descriptors Directly in the Root Arguments

Applications can put descriptors directly in the root arguments to avoid
having to go through a descriptor heap. These descriptors take a lot of
space in the root arguments (see the root argument limits section), so
applications have to use them sparingly.

An example use would be to place a CBV that is changing per draw in the
root arguments so that descriptor heap space doesn't have to be burned
by the application per draw (plus pointing a descriptor table at the new
location in the descriptor heap). Of course by including something in
the root arguments, the application is merely handing the versioning
burden to the driver, but this is infrastructure that they already have.

For rendering that uses extremely few resources, descriptor table / heap
use may not be needed at all if all the needed descriptors can be placed
directly in the root arguments.

The only types of descriptors supported in the root arguments are CBVs
and SRV/UAVs of Buffer resources, where the SRV/UAV is either a raw or
structured buffer. UAVs in the root cannot have counters associated with
them.

Unlike full descriptors in descriptor heaps, root descriptors are each
defined via single 64-bit value - a GPU virtual address of the data.
Applications can obtain the base GPU virtual address for a buffer
resource via ID3D12Resource::GetGPUVirtualAddress() and manually offset
the address to use it as a root descriptor, subject to buffer address
alignment constraints. Notably, there is no size parameter in root
descriptors defining where out of bounds behavior would kick in, the way
full descriptors behave. For root descriptors it is up to the
application to stay within the bounds of the underlying allocation they
are referencing. Additionally, for root constant buffer views, the
shader cannot read past 4096 4*32-bit elements from the specified view
base address otherwise behavior is undefined -- some hardware cannot
support larger CBVs and will produce out of bounds behavior like a full
CBV would, while other hardware will not clamp at all. For SRV or UAV
root descriptors, accessing out of bounds of the underlying resource
allocation produces undefined results as well -- the difference with
root CBVs is that for root SRV/UAVs there is no fixed size span that the
shader can access -- the limit is only determined by the size of the
underlying allocation.

Descriptors in root arguments do not support shader instructions that
return status information (mapped/unmapped pages). The instruction will
work fine overall except the mapped status return is undefined.

Descriptors in the root arguments appear each as individual separate
descriptors -- they cannot be dynamically indexed.

```C++
struct SceneData
{
    uint foo;
    float bar[2];
    int moo;
};

ConstantBuffer<SceneData> mySceneData : register(b6);
```

In the above example, mySceneData cannot be declared as an array, as in
"cbuffer mySceneData[2]" if it is going to be mapped onto a descriptor
in the root signature, since indexing across descriptors is not
supported in the root arguments. The application can define separate
individual constant buffers each as a separate parameter in the root
signature if desired.

Note that within mySceneData above there is an array bar[2]. Dynamic
indexing within the constant buffer is valid -- a descriptor in the root
arguments behaves just like the same descriptor would behave if accessed
through a descriptor heap. This is in contrast with inlining constants
directly in the root arguments, which also appears like a constant
buffer except with the constraint that dynamic indexing within the
inlined constants is not permitted, so bar[2] would not be allowed
there.

## Root Argument Limits

The maximum size of a root arguments is 64 DWORDs. This maximum is
chosen to prevent abuse of the root arguments as a way of storing bulk
data. Each parameter in the root signature has a cost towards this 64
DWORD limit. These costs may not exactly match what any given hardware
has to do, but no matter what the tight limit minimizes the hardware
expense for supporting the root arguments. Descriptor tables cost 1
DWORD each.

Root constants cost 1 DWORD * NumConstants, by definition since they
are collections of 32-bit values.

Raw/Structured Buffer SRVs/UAVs and CBVs cost 2 DWORDs.

### Additional Root Argument Capacity For System Instrumentation

During debugging or other system instrumentation scenarios, the OS has
the option to add root arguments (of any type) past the API limit
imposted on the application, up to 128 DWORDs total (app + debug). These
extra arguments are used, for instance, in combination with patching
shaders debug shader validation that can support applications that
happen to use all of their available root signature capacity.

Drivers don't see the distinction between which arguments came from the
app vs which were injected by the system, by design. All a driver has to
know is that it can see root signatures larger than 64 DWORDs (up to 128
DWORDs). And it is fair to treat any root arguments past 64 DWORDS
lowest priority in terms of needing to be as performant as the API
visible root parameters.

For low tier hardware with CBV bind limits, no more than one CBV per
shader stage will be appended - D3D has always reserved one CBV on such
hardware. Since root UAVs/SRVs are more constrained than full UAVs/SRVs,
hardware Tier based limits on resource bindings are not affected by the
system adding these descriptors to a root signature.

If there are to be extra root arguments showing up in root signatures
there needs to be a way to guarantee that they can be consumed by
instrumented shader code without conflicting with whatever bindings the
original application / shader happened to choose. To enable this, an
additional reservation is in the RegisterSpace field in root parameter
definition and HLSL binding definition, such as register(t0,space#).
Some of the register space values (which appear as the # in the example
here) are reserved, from the high end of the number range, 0xfffffff0 to
0xffffffff. See "Note about Register Space" elsewhere in the spec --
some of the range is for driver use and some for the OS.

This register space reservation leaves room for drivers and/or the OS to
do instrumentation on shaders (such as during debugging) easily by
adding bindings in the reserved register space range without any risk of
conflict with whatever binding locations the application's shader chose
to use for joining root arguments to shaders. The HLSL resources
declared in these reserved register spaces can be fed by the system
added root signature entries described above.

## Static Samplers

Many applications only need a fixed set of samplers, and these are often
common across many pipeline states.  Another view of this is that it
would be convenient in many cases for HLSL authors to be to be able to
define samplers directly in shader code, near the use of them.

One issue is that some hardware is not set up to take advantage of
knowing the set of samplers to be used in shaders and instead needs to
manage the sampler externally in a descriptor heap.  Other hardware, by
contrast, does benefit from knowing what samplers will be used in a
shader at compile time.

To enable all these types of hardware to operate efficiently while
providing applications additional convenience for shader authors, a set
of static samplers can be defined in the root signature.  These are
independent of the root parameters in the root signature.  Root
parameters define a binding space where arguments can be provided at
runtime, whereas static samplers are by definition unchanging.

Since root signatures can be authored directly in HLSL, samplers can be
authored in HLSL too - as static samplers in a root signature.

The presence of the root signature in pipeline state creation means that
hardware that prefers to compile static sampler state directly into the
shader can do so.

The presence of static samplers in the root signature also works for
hardware that needs to manage samplers outside the shader.  Recall that
root signatures are objects that applications must create at the D3D API
for use in command lists, and any pipeline states that are used must
match the currently set root signature.  Drivers can take advantage of
this to place static samplers in a reserved area in all sampler heaps
the application has created (as well as a hidden one in case the
application does not use a sampler heap on a given command list at
all).

To maintain the currently live set of static samplers, drivers that need
to can use a critical section on root signature creation / destruction
and on sampler descriptor heap creation destruction.  These operations
should be quite rare during execution, so the impact of any shadowing of
static samplers on high performance rendering should not be noticeable.

To help limit the maximum amount of memory involved to shadow static
samplers (also to fit within some hardware constraints) the total number
of unique static samplers that can be declared across all root
signatures live on a D3D device at a time is limited to 2032. This is
slightly less than a power of 2 (2048) to leave some room for drivers
that need to allocate some samplers internally.  This is separate from
the 2048 samplers that an application can manage manually in a sampler
descriptor heap.  

Dynamic indexing of static samplers not permitted from within shader
code.  This way drivers can manage the maximum limit of 2032 static
samplers as a heap of individually allocated samplers, such as in a
hidden portion of any application created sampler descriptor heap,
without any consequence from heap fragmentation as samplers may come and
go.   If an application has samplers A and B in one root signature, and
samplers A and C in a second root signature, the total cost against the
2032 limit is 3, not 4, since A appears twice.  If the second root
signature is freed, only A and B are left allocated, leaving 2030 free.

The static samplers defined in a root signature are independent of
samplers an application chooses to put in a descriptor heap -- both
mechanisms can be used at the same time.  A root signature simply must
not declare that a sampler in a shader comes from both a static sampler
and from a sampler descriptor table.  That will fail compilation since
it doesn't make sense.

Even with the convenience of static samplers, there are reasons for an
app to manage samplers in a sampler descriptor heap (via descriptor
tables) instead of or in addition to static samplers: the selection of
samplers is truly dynamic and unknown at shader compile, the application
wants to use dynamic indexing of samplers, or the type of sampler needed
is not supported in a static sampler.  Restrictions on static samplers
are detailed below.

## Limitations on Static Samplers

To make static sampler management within shaders directly viable, a
minor restriction is imposed on what types of samplers can be created.
This limits the amount of data required to fully represent a sampler.

BorderColor must be one of: {0.0, 0.0, 0.0, 0.0}, {0.0, 0.0, 0.0, 1.0},
{1.0, 1.0, 1.0, 1.0}; {0u, 0u, 0u, 1u}, {1u, 1u, 1u, 1u}. 
Where the unsigned integer colors are available  with SM6.7 or higher, 
and require adding `D3D12_SAMPLER_FLAG_UINT_BORDER_COLOR` 
to the Flags field in the sampler description.

In the static sampler definition, BorderColor is chosen via an 
enumeration listing just the 5 possibilities rather than allowing 
arbitrary floats.

In the highly unlikely case this restriction doesn't work for an
application it can always use the full samplers in a sampler descriptor
heap via a descriptor table.

# Levels of Hardware Support

The table below shows a progression of increasing flexibility in the
amount of resources available to the pipeline based on level of
hardware.

**Bold** entries highlight improvements over the previous tier.

|   | <p>Tier 1</p><p>FL 9.4, 11.0+</p> | <p>Tier 2</p><p>FL 11.0+</p> | <p>Tier 3<p><p>FL 11.1+</p>
|---|:---:|:---:|:---:|
| Max # descriptors in a shader visible CBV/SRV/UAV heap           | 1000000         | 1000000         | 1000000 **+**
| Max CBVs in all descriptor tables per shader stage | 14              | 14              | **full heap**
| Max SRVs in all descriptor tables per shader stage | 128             | **full heap**   | full heap
| Max UAVs in all descriptor tables across all stages | 8 (64 for FL 11.1+)    | **64**          | **full heap**
| Max Samplers in all descriptor tables per shader stage | 16              | **full heap**   | full heap

For Tier 3, the max # descriptors is listed as 1000000+. The +
indicates that the runtime allows applications to try creating
descriptor heaps with more than 1000000 descriptors, leaving the driver
to decide whether it can support the request or fail the call. There is
no cap exposed indicating how large of a descriptor heap the hardware
could support -- applications can just try what they want and fall back
to 1000000 if larger doesn't work.

## Limits Invariant on Hardware

Max # of samplers in a shader visible descriptor heap: 2048

Max # of unique static samplers across live root signatures: 2032
(leaves 16 for drivers that need their own samplers)

# API

## Capability Querying

Applications can discover the level of support for resource binding
(Resource Binding Tier) via CheckFeatureSupport() call. Each tier is a
superset of lower tiers in functionality, so code that works on a given
tier works on any higher tier unchanged.

```C++
typedef enum D3D12_FEATURE
{
    ...
    D3D12_FEATURE_D3D12_OPTIONS = ( D3D11_FEATURE_D3D9_OPTIONS1 + 1 )
} D3D12_FEATURE;

typedef enum D3D12_RESOURCE_BINDING_TIER
{
    D3D12_RESOURCE_BINDING_TIER_1 = 1,
    D3D12_RESOURCE_BINDING_TIER_2 = 2,
    D3D12_RESOURCE_BINDING_TIER_3 = 3,
} D3D12_RESOURCE_BINDING_TIER;

typedef struct D3D12_FEATURE_DATA_D3D12_OPTIONS
{
    D3D12_RESOURCE_BINDING_TIER ResourceBindingTier;
    // Add other D3D12 capability values as needed
} D3D12_FEATURE_DATA_D3D12_OPTIONS;

interface ID3D12Device
{
    ...
    HRESULT CheckFeatureSupport(
        D3D12_FEATURE Feature,
        _Out_writes_bytes_(FeatureSupportDataSize) void *pFeatureSupportData,
        UINT FeatureSupportDataSize);
}
```

## Creating Descriptor Heaps

```C++
typedef enum D3D12_DESCRIPTOR_HEAP_TYPE
{
    D3D12_CBV_SRV_UAV_DESCRIPTOR_HEAP,
    D3D12_SAMPLER_DESCRIPTOR_HEAP,
    D3D12_RTV_DESCRIPTOR_HEAP,
    D3D12_DSV_DESCRIPTOR_HEAP,
    D3D12_NUM_DESCRIPTOR_HEAP_TYPES
} D3D12_DESCRIPTOR_HEAP_TYPE;
```

### Descriptor Heap Properties

Configuring a descriptor heap involves selecting a descriptor heap type,
how many descriptors it contains and Flags that indicate whether it is
CPU visible and/or shader visible. Advanced configurations options may
be allowed in the future to fine tune the memory preferences to some
degree, though they must be consistent with the Flags choices.

```C++
typedef enum D3D12_DESCRIPTOR_HEAP_FLAGS
{
    D3D12_DESCRIPTOR_HEAP_SHADER_VISIBLE = 0x1,
} D3D12_DESCRIPTOR_HEAP_FLAGS;

typedef struct D3D12_DESCRIPTOR_HEAP_DESC
{
    D3D12_DESCRIPTOR_HEAP_TYPE Type;
    UINT NumDescriptors;
    UINT Flags;
    UINT NodeMask;
} D3D12_DESCRIPTOR_HEAP_DESC;
```

For `CBV_SRV_UAV` descriptor heaps and SAMPLER descriptor heaps
`D3D12_DESCRIPTOR_HEAP_SHADER_VISIBLE` can optionally be set.

The flag `D3D12_DESCRIPTOR_HEAP_SHADER_VISIBLE` indicates that the
heap is intended to be bound on a command list for reference by shaders.
This flag doesn't apply to other descriptor heap types since shaders
don't directly reference the other types. Use of this flag means that
the CPU can only write to the descriptor heap (attempting to read
produces undefined behavior).

With the shader visible flag set, the memory pool used for the heap is
whatever the driver decides is the best for shader access -- most likely
system memory for integrated/shared memory GPUs and video memory for
discrete memory GPUs. Future hardware may have other memory pools that
could get used if they would be better for shader access, but they would
have to be CPU visible as well. CPU page properties may set to
`WRITE_COMBINE` if the implementation needs it, so therefore reading from
a shader visible descriptor heap (such as using it as the source for a
copy call) on the CPU is not allowed.

Without the shader visible flag, CPU page properties on a descriptor
heap are always set to `WRITE_BACK`.

#### Descriptor Heap Configurability Summary

|   | Shader Visible Descriptor Heap        | Non Shader Visible Descriptor Heap
---|---|---
Heap Types Supported  | `CBV_SRV_UAV`,Sampler        | All
Memory Pools Supported          | Most likely L0+ for integrated, L+ for discrete, but up to driver (such as if other pools become options)  | L0
CPU Page Property     | `WRITE_COMBINE` possible        | `WRITE_BACK`
Residency Management By App  | Yes, app responsible  | Not applicable (not GPU visible).
Descriptor Edit Support       | Write only.           | CPU read and write only. No direct GPU access.  Can be used for immediate CPU copying (as a source and dest).    |

#### Shader Visible Descriptor Heap Pitfall

Some architectures have limited video memory resources for optimal
storage of shader visible descriptor heaps - CPU visible video memory/L1
which the OS prioritizes for descriptor heaps. Over time hardware will
improve, but at the moment there are even extremely high end GPU
configurations including many GB of video memory that still have an
extremely small amount of CPU visible video memory (\~96MB). Because of
the diversity of architectures, there also isn't a clean way to report
the nature of the limitations of a given system with caps, particularly
as their meaning may quickly become stale over time.

If descriptors can be roughly 32 bytes in size, a 1 million entry
descriptor heap can take \~32MB. Making a large number of these that are
shader visible (say for n-buffering of rendering) can therefore easily
gobble up the available space. The video memory manager can demote
shader visible descriptor heaps to system memory in this case (and bring
them back). But if contention on the limited space does force less ideal
memory placement this can produce a visible perf hit due to extra
latency on descriptor access.

A bad case would be if multiple descriptor heap size intensive DX apps
are running on a system at a time. The hit would be at least minimized,
however, if each of them at least tries to limit shader visible
descriptor heap space to what is actually needed to run efficiently.
While it may not be often that multiple high fidelity games are running
simultaneously, if even smaller applications are authored on the side
that use unnecessary shader visible descriptor heap space could
noticeably tax the game a user is playing. There isn't any more concrete
advice to be given (for now at least) than please only use what's needed
to work well - the OS doesn't impose any hard limit on descriptor heap
footprint on apps.

### Descriptor Handles

`D3D12_*_DESCRIPTOR_HANDLE`, shown below, identifies a specific
descriptor in a descriptor heap. It is a bit like a pointer but the
application must not dereference it manually otherwise behavior is
undefined. Use of the handles must go through the API. A handle itself
can be copied freely or passed into APIs that operate on/use
descriptors. There is no ref counting, so the application must ensure it
does not use a handle after the underlying descriptor heap has been
deleted.

Applications can find out increment size of the descriptors for a given
descriptor heap type so that they can generate handles to any location
in a descriptor heap manually starting from the handle to the base.
Applications must never hardcode descriptor handle increment sizes --
always query them for a given device instance, otherwise behavior is
undefined. Applications must also not use the increment sizes and
handles to do their own examination or manipulation of descriptor heap
data, as the results from doing so are undefined, an in fact the handles
may not actually be pointers but proxies for pointers to avoid
accidental dereferencing.

```C++
typedef struct D3D12_CPU_DESCRIPTOR_HANDLE
{
    SIZE_T ptr;
} D3D12_CPU_DESCRIPTOR_HANDLE;

typedef struct D3D12_GPU_DESCRIPTOR_HANDLE
{
    UINT64 ptr;
} D3D12_GPU_DESCRIPTOR_HANDLE;
```

### Descriptor Heap Methods

Descriptor heaps inherit from ID3D12Pageable, shown below. This imposes
on applications responsibility for residency management on descriptor
heaps just like resource heaps. The residency management methods only
apply to shader visible heaps, since the non shader visible heaps are
not visible to the GPU directly.

```C++
interface ID3D12DescriptorHeap : ID3D12Pageable
{
    D3D12_DESCRIPTOR_HEAP_DESC GetDesc(
    _Out_ D3D12_DESCRIPTOR_HEAP_DESC* pDesc );
    D3D12_CPU_DESCRIPTOR_HANDLE GetCPUDescriptorHandleForHeapStart();
    D3D12_GPU_DESCRIPTOR_HANDLE GetGPUDescriptorHandleForHeapStart();
};

interface ID3D12Device
{
    ...
        HRESULT CreateDescriptorHeap(
    _In_ const D3D12_DESCRIPTOR_HEAP_DESC* pDesc,
    REFIID riid, // Expected: ID3D12DescriptorHeap
    _Out_ void** ppvHeap);
    UINT GetDescriptorHandleIncrementSize(
    _In_ D3D12_DESCRIPTOR_HEAP_TYPE DescriptorHeapType);
};
```

GetDescriptorHandleIncrementSize() above allows applications to manually
offset handles into a heap (producing handles into anywhere in a
descriptor heap). The heap start location's handle comes from
GetCPUDescriptorHandleForHeapStart()/GetGPUDescriptorHandleForHeapStart(). Offsetting is
done by adding to the descriptor heap start the increment size * number
of descriptors to offset. Note the increment size cannot be thought of
as a byte size since applications must not dereference handles as if
they are memory -- the memory pointed to has a nonstandardized layout
and can vary even for a given device.

GetCPUDescriptorHandleForHeapStart() returns a CPU handle for CPU manipulation of
a descriptor heap.

GetGPUDescriptorHandleForHeapStart() returns a GPU handle for shader visible
descriptor heaps. It returns a NULL handle (and the debug layer will
report an error) if the descriptor heap is not shader visible.

### Example: Minimal descriptor heap wrapper

Applications will likely want to build their own helper code for
managing descriptor handles and heaps. A basic example is shown below.
This is not part of any D3D code release/header, just listed as-is --
cut and paste if you want to start with it or just ignore this section.
More sophisticated wrappers might try to keep track of what types of
descriptors are where in a heap and remember the descriptor creation
arguments etc. Each app will have its own needs, so D3D obviously
doesn't attempt to dictate any approach.

Helper structs `CD3D12_CPU_DESCRIPTOR_HANDLE` and
`CD3D12_GPU_DESCRIPTOR_HANDLE` are defined in d3dx12.h.

```C++
class CDescriptorHeapWrapper
{
public:
    CDescriptorHeapWrapper() { memset(this, 0, sizeof(*this)); }

    HRESULT Create(
        ID3D12Device* pDevice,
        D3D12_DESCRIPTOR_HEAP_TYPE Type,
        UINT NumDescriptors,
        bool bShaderVisible = false)
    {
        Desc.Type = Type;
        Desc.NumDescriptors = NumDescriptors;
        Desc.Flags = (bShaderVisible ? D3D12_DESCRIPTOR_HEAP_SHADER_VISIBLE : 0);
        pDH = NULL; // release any previous heap

        HRESULT hr = pDevice->CreateDescriptorHeap(&Desc,
                                __uuidof(ID3D12DescriptorHeap),
                                    (void**)&pDH);
        if (FAILED(hr)) return hr;

        hCPUHeapStart = pDH->GetCPUDescriptorHandleForHeapStart();
        if (bShaderVisible)
        {
            hGPUHeapStart = pDH->GetGPUDescriptorHandleForHeapStart();
        }
        else
        {
            hGPUHeapStart.ptr = 0;
        }
        HandleIncrementSize =
            pDevice->GetDescriptorHandleIncrementSize(Desc.Type);

        return hr;
    }

    operator ID3D12DescriptorHeap*() { return pDH; }

    CD3D12_CPU_DESCRIPTOR_HANDLE hCPU(UINT index)
    {
        return
            CD3D12_CPU_DESCRIPTOR_HANDLE(hCPUHeapStart,index,HandleIncrementSize);
    }

    CD3D12_GPU_DESCRIPTOR_HANDLE hGPU(UINT index)
    {
        assert(Desc.Flags&D3D12_DESCRIPTOR_HEAP_SHADER_VISIBLE);
        return
            CD3D12_GPU_DESCRIPTOR_HANDLE(hGPUHeapStart,index,HandleIncrementSize);
    }

    D3D12_DESCRIPTOR_HEAP_DESC Desc;
    CComPtr<ID3D12DescriptorHeap> pDH;
    D3D12_CPU_DESCRIPTOR_HANDLE hCPUHeapStart;
    D3D12_GPU_DESCRIPTOR_HANDLE hGPUHeapStart;
    UINT HandleIncrementSize;
};
```

## Setting Descriptor Heaps

The descriptor heap types that can be set on a command list are those
that contain descriptors for which descriptor tables can be used (at
most one of each at a time):

`D3D12_CBV_SRV_UAV_DESCRIPTOR_HEAP`

`D3D12_SAMPLER_DESCRIPTOR_HEAP`

The heaps being set on the command list must also have been created as
shader visible.

Once a descriptor heap set on a command list, subsequent calls that
define descriptor tables refer to the current descriptor heap.
Descriptor table state is undefined at the beginning of a command list
and after descriptor heaps are changed on a command list. Redundantly
setting the same descriptor heap does not cause descriptor table
settings to be undefined.

In a bundle, by contrast, the descriptor heaps can only be set at most
once (redundant calls setting the same heap are ok) otherwise behavior
is undefined. The descriptor heaps that are set must match the state
when any command list calls the bundle otherwise behavior is undefined.
This allows bundles to inherit and edit the command list's descriptor
table settings.

Bundles that don't change descriptor tables (only inherit them) don't
need to set a descriptor heap at all and will just inherit from the
calling command list.

```C++
// [Command list types: DIRECT, BUNDLE, COMPUTE]
interface ID3D12CommandList
{
    ...
    void SetDescriptorHeaps(_In_ ID3D12DescriptorHeap** ppDescriptorHeaps,
                            _In_ UINT NumDescriptorHeaps );
}
```

When descriptor heaps are set, all the heaps being used are set in a
single call (and all previously set heaps are unset by the call). At
most one heap of each type listed above can be set in the call.

## Creating Descriptors

All methods for creating descriptors are free threaded.

### Shader Resource View

Note below that float ResourceMinLODClamp has been added to SRVs For
Tex1D/2D/3D/Cube. In D3D11 it was a property of a resource, but this did
not match how it was implemented in hardware.

StructureByteStride has been added to Buffer SRVs, where in D3D11 it was
a property of the resource. If the stride is nonzero, that indicates a
structured buffer view, and the format must be set to
`DXGI_FORMAT_UNKNOWN`.

Shader4ComponentMapping has been added to SRVs to allow the SRV to
choose how memory gets routed to the 4 return components in a shader
after a memory fetch. The options for each shader component [0..3]
(RGBA) are: component 0..3 from the SRV fetch result or force 0 or force 1. The value of forcing 1 is either 0x1 or 1.0f depending on the format
type for that component in the source format.

The default 1:1 mapping can be indicated by specifying
`D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING`, otherwise an arbitrary
mapping can be specified using the macro
`D3D12_ENCODE_SHADER_4_COMPONENT_MAPPING`. See below.

```C++
typedef enum D3D12_SHADER_COMPONENT_MAPPING
{
    D3D12_SHADER_COMPONENT_FROM_MEMORY_COMPONENT_0 = 0,
    D3D12_SHADER_COMPONENT_FROM_MEMORY_COMPONENT_1 = 1,
    D3D12_SHADER_COMPONENT_FROM_MEMORY_COMPONENT_2 = 2,
    D3D12_SHADER_COMPONENT_FROM_MEMORY_COMPONENT_3 = 3,
    D3D12_SHADER_COMPONENT_FORCE_VALUE_0 = 4,
    D3D12_SHADER_COMPONENT_FORCE_VALUE_1 = 5
} D3D12_SHADER_COMPONENT_MAPPING;

#define D3D12_SHADER_COMPONENT_MAPPING_MASK 0x7

#define D3D12_SHADER_COMPONENT_MAPPING_SHIFT 3

#define D3D12_SHADER_COMPONENT_MAPPING_ALWAYS_SET_BIT_AVOIDING_ZEROMEM_MISTAKES
        (1<<(D3D12_SHADER_COMPONENT_MAPPING_SHIFT*4))

#define D3D12_ENCODE_SHADER_4_COMPONENT_MAPPING(Src0,Src1,Src2,Src3)
        ((((Src0)&D3D12_SHADER_COMPONENT_MAPPING_MASK)| \
        (((Src1)&D3D12_SHADER_COMPONENT_MAPPING_MASK)<<D3D12_SHADER_COMPONENT_MAPPING_SHIFT)|\
        (((Src2)&D3D12_SHADER_COMPONENT_MAPPING_MASK)<<(D3D12_SHADER_COMPONENT_MAPPING_SHIFT*2))|\
        (((Src3)&D3D12_SHADER_COMPONENT_MAPPING_MASK)<<(D3D12_SHADER_COMPONENT_MAPPING_SHIFT*3))|\
        D3D12_SHADER_COMPONENT_MAPPING_ALWAYS_SET_BIT_AVOIDING_ZEROMEM_MISTAKES))

#define D3D12_DECODE_SHADER_4_COMPONENT_MAPPING(ComponentToExtract,Mapping)
        ((D3D12_SHADER_COMPONENT_MAPPING)(Mapping >>
        (D3D12_SHADER_COMPONENT_MAPPING_SHIFT*ComponentToExtract) &
        D3D12_SHADER_COMPONENT_MAPPING_MASK))

#define D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING
    D3D12_ENCODE_SHADER_4_COMPONENT_MAPPING(0,1,2,3)

typedef enum D3D12_BUFFER_SRV_FLAG
{
    D3D12_BUFFER_SRV_FLAG_RAW = 0x00000001, // allow device multi-
    // component reads with DWORD addressing
} D3D12_BUFFER_SRV_FLAG;

typedef struct D3D12_BUFFER_SRV
{
    UINT FirstElement;
    UINT NumElements;
    UINT StructureByteStride;
    UINT Flags;
} D3D12_BUFFER_SRV;

typedef struct D3D12_TEX1D_SRV
{
    UINT MostDetailedMip;
    UINT MipLevels;
    FLOAT ResourceMinLODClamp;
} D3D12_TEX1D_SRV;

typedef struct D3D12_TEX1D_ARRAY_SRV
{
    UINT MostDetailedMip;
    UINT MipLevels;
    UINT FirstArraySlice;
    UINT ArraySize;
    FLOAT ResourceMinLODClamp;
} D3D12_TEX1D_ARRAY_SRV;

typedef struct D3D12_TEX2D_SRV
{
    UINT MostDetailedMip;
    UINT MipLevels;
    UINT PlaneSlice;
    FLOAT ResourceMinLODClamp;
} D3D12_TEX2D_SRV;

typedef struct D3D12_TEX2D_ARRAY_SRV
{
    UINT MostDetailedMip;
    UINT MipLevels;
    UINT FirstArraySlice;
    UINT ArraySize;
    UINT PlaneSlice;
    FLOAT ResourceMinLODClamp;
} D3D12_TEX2D_ARRAY_SRV;

typedef struct D3D12_TEX3D_SRV
{
    UINT MostDetailedMip;
    UINT MipLevels;
    FLOAT ResourceMinLODClamp;
} D3D12_TEX3D_SRV;

typedef struct D3D12_TEXCUBE_SRV
{
    UINT MostDetailedMip;
    UINT MipLevels;
    FLOAT ResourceMinLODClamp;
} D3D12_TEXCUBE_SRV;

typedef struct D3D12_TEXCUBE_ARRAY_SRV
{
    UINT MostDetailedMip;
    UINT MipLevels;
    UINT First2DArrayFace;
    UINT NumCubes;
    FLOAT ResourceMinLODClamp;
} D3D12_TEXCUBE_ARRAY_SRV;

typedef struct D3D12_TEX2DMS_SRV
{
    // don\'t need to define anything specific for this view dimension
    UINT UnusedField_NothingToDefine;
} D3D12_TEX2DMS_SRV;

typedef struct D3D12_TEX2DMS_ARRAY_SRV
{
    UINT FirstArraySlice;
    UINT ArraySize;
} D3D12_TEX2DMS_ARRAY_SRV;

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
        D3D12_BUFFEREX_SRV BufferEx;
    };
} D3D12_SHADER_RESOURCE_VIEW_DESC;

interface ID3D12Device
{
    ...
    void CreateShaderResourceView (
        _In_opt_ ID3D12Resource* pResource,
        _In_opt_ const D3D12_SHADER_RESOURCE_VIEW_DESC* pDesc,
        _In_ D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor);
};
```

### Constant Buffer View

```C++
typedef struct D3D12_CONSTANT_BUFFER_VIEW_DESC
{
    D3D12_GPU_VIRTUAL_ADDRESS BufferLocation; // 0 fine only if SizeInBytes is 0
    UINT SizeInBytes; // 0 means nothing bound
} D3D12_CONSTANT_BUFFER_VIEW_DESC;

interface ID3D12Device
{
    ...
    void CreateConstantBufferView (
        _In_opt_ ID3D12Resource* pResource,
        _In_ const D3D12_CONSTANT_BUFFER_VIEW_DESC * pDesc,
        _In_ D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor);
};
```

Note that root CBVs don't use the above descriptor. Instead they are
defined just as GPU virtual address -- discussed elsewhere.

### Sampler

```C++
typedef enum D3D12_FILTER
{
    // Bits used in defining enumeration of valid filters:
    // bits [1:0] - mip: 0 == point, 1 == linear, 2,3 unused
    // bits [3:2] - mag: 0 == point, 1 == linear, 2,3 unused
    // bits [5:4] - min: 0 == point, 1 == linear, 2,3 unused
    // bit [6] - aniso
    // bits [8:7] - reduction type:
    // 0 == standard filtering
    // 1 == comparison
    // 2 == min
    // 3 == max
    // bit [31] - mono 1-bit (narrow-purpose filter) [no longer supported in D3D12]

    D3D12_FILTER_MIN_MAG_MIP_POINT = 0x00000000,
    D3D12_FILTER_MIN_MAG_POINT_MIP_LINEAR = 0x00000001,
    D3D12_FILTER_MIN_POINT_MAG_LINEAR_MIP_POINT = 0x00000004,
    D3D12_FILTER_MIN_POINT_MAG_MIP_LINEAR = 0x00000005,
    D3D12_FILTER_MIN_LINEAR_MAG_MIP_POINT = 0x00000010,
    D3D12_FILTER_MIN_LINEAR_MAG_POINT_MIP_LINEAR = 0x00000011,
    D3D12_FILTER_MIN_MAG_LINEAR_MIP_POINT = 0x00000014,
    D3D12_FILTER_MIN_MAG_MIP_LINEAR = 0x00000015,
    D3D12_FILTER_ANISOTROPIC = 0x00000055,
    D3D12_FILTER_COMPARISON_MIN_MAG_MIP_POINT = 0x00000080,
    D3D12_FILTER_COMPARISON_MIN_MAG_POINT_MIP_LINEAR = 0x00000081,
    D3D12_FILTER_COMPARISON_MIN_POINT_MAG_LINEAR_MIP_POINT = 0x00000084,
    D3D12_FILTER_COMPARISON_MIN_POINT_MAG_MIP_LINEAR = 0x00000085,
    D3D12_FILTER_COMPARISON_MIN_LINEAR_MAG_MIP_POINT = 0x00000090,
    D3D12_FILTER_COMPARISON_MIN_LINEAR_MAG_POINT_MIP_LINEAR = 0x00000091,
    D3D12_FILTER_COMPARISON_MIN_MAG_LINEAR_MIP_POINT = 0x00000094,
    D3D12_FILTER_COMPARISON_MIN_MAG_MIP_LINEAR = 0x00000095,
    D3D12_FILTER_COMPARISON_ANISOTROPIC = 0x000000d5,
    D3D12_FILTER_MINIMUM_MIN_MAG_MIP_POINT = 0x00000100,
    D3D12_FILTER_MINIMUM_MIN_MAG_POINT_MIP_LINEAR = 0x00000101,
    D3D12_FILTER_MINIMUM_MIN_POINT_MAG_LINEAR_MIP_POINT = 0x00000104,
    D3D12_FILTER_MINIMUM_MIN_POINT_MAG_MIP_LINEAR = 0x00000105,
    D3D12_FILTER_MINIMUM_MIN_LINEAR_MAG_MIP_POINT = 0x00000110,
    D3D12_FILTER_MINIMUM_MIN_LINEAR_MAG_POINT_MIP_LINEAR = 0x00000111,
    D3D12_FILTER_MINIMUM_MIN_MAG_LINEAR_MIP_POINT = 0x00000114,
    D3D12_FILTER_MINIMUM_MIN_MAG_MIP_LINEAR = 0x00000115,
    D3D12_FILTER_MINIMUM_ANISOTROPIC = 0x00000155,
    D3D12_FILTER_MAXIMUM_MIN_MAG_MIP_POINT = 0x00000180,
    D3D12_FILTER_MAXIMUM_MIN_MAG_POINT_MIP_LINEAR = 0x00000181,
    D3D12_FILTER_MAXIMUM_MIN_POINT_MAG_LINEAR_MIP_POINT = 0x00000184,
    D3D12_FILTER_MAXIMUM_MIN_POINT_MAG_MIP_LINEAR = 0x00000185,
    D3D12_FILTER_MAXIMUM_MIN_LINEAR_MAG_MIP_POINT = 0x00000190,
    D3D12_FILTER_MAXIMUM_MIN_LINEAR_MAG_POINT_MIP_LINEAR = 0x00000191,
    D3D12_FILTER_MAXIMUM_MIN_MAG_LINEAR_MIP_POINT = 0x00000194,
    D3D12_FILTER_MAXIMUM_MIN_MAG_MIP_LINEAR = 0x00000195,
    D3D12_FILTER_MAXIMUM_ANISOTROPIC = 0x000001d5
} D3D12_FILTER;

typedef enum D3D12_FILTER_TYPE
{
    D3D12_FILTER_TYPE_POINT = 0,
    D3D12_FILTER_TYPE_LINEAR = 1,
} D3D12_FILTER_TYPE;

typedef enum D3D12_FILTER_REDUCTION_TYPE
{
    D3D12_FILTER_REDUCTION_TYPE_STANDARD = 0,
    D3D12_FILTER_REDUCTION_TYPE_COMPARISON = 1,
    D3D12_FILTER_REDUCTION_TYPE_MINIMUM = 2,
    D3D12_FILTER_REDUCTION_TYPE_MAXIMUM = 3,
} D3D12_FILTER_REDUCTION_TYPE;

#define D3D12_FILTER_REDUCTION_TYPE_MASK ( 0x3 )
#define D3D12_FILTER_REDUCTION_TYPE_SHIFT ( 7 )
#define D3D12_FILTER_TYPE_MASK ( 0x3 )
#define D3D12_MIN_FILTER_SHIFT ( 4 )
#define D3D12_MAG_FILTER_SHIFT ( 2 )
#define D3D12_MIP_FILTER_SHIFT ( 0 )
#define D3D12_ANISOTROPIC_FILTERING_BIT ( 0x40 )
#define D3D12_ENCODE_BASIC_FILTER( min, mag, mip, reduction ) \
    ( ( D3D12_FILTER ) ( \
    ( ( ( min ) & D3D12_FILTER_TYPE_MASK ) << D3D12_MIN_FILTER_SHIFT) | \
    ( ( ( mag ) & D3D12_FILTER_TYPE_MASK ) << D3D12_MAG_FILTER_SHIFT) | \
    ( ( ( mip ) & D3D12_FILTER_TYPE_MASK ) << D3D12_MIP_FILTER_SHIFT) | \
    ( ( ( reduction ) & D3D12_FILTER_REDUCTION_TYPE_MASK ) << D3D12_FILTER_REDUCTION_TYPE_SHIFT ) ) )

#define D3D12_ENCODE_ANISOTROPIC_FILTER( reduction ) \
    ( ( D3D12_FILTER ) ( \
    D3D12_ANISOTROPIC_FILTERING_BIT | \
    D3D12_ENCODE_BASIC_FILTER( D3D12_FILTER_TYPE_LINEAR, \
    D3D12_FILTER_TYPE_LINEAR, \
    D3D12_FILTER_TYPE_LINEAR, \
    reduction ) ) )

#define D3D12_DECODE_MIN_FILTER( D3D12Filter ) \
    ( ( D3D12_FILTER_TYPE ) \
    ( ( ( D3D12Filter ) >> D3D12_MIN_FILTER_SHIFT ) & D3D12_FILTER_TYPE_MASK ) )

#define D3D12_DECODE_MAG_FILTER( D3D12Filter ) \
    ( ( D3D12_FILTER_TYPE ) \
    ( ( ( D3D12Filter ) >> D3D12_MAG_FILTER_SHIFT ) & D3D12_FILTER_TYPE_MASK ) )

#define D3D12_DECODE_MIP_FILTER( D3D12Filter ) \
    ( ( D3D12_FILTER_TYPE ) \
    ( ( ( D3D12Filter ) >> D3D12_MIP_FILTER_SHIFT ) & D3D12_FILTER_TYPE_MASK ) )

#define D3D12_DECODE_FILTER_REDUCTION( D3D12Filter ) \
    ( ( D3D12_FILTER_REDUCTION_TYPE ) \
    ( ( ( D3D12Filter ) >> D3D12_FILTER_REDUCTION_TYPE_SHIFT ) &D3D12_FILTER_REDUCTION_TYPE_MASK ) )

#define D3D12_DECODE_IS_COMPARISON_FILTER( D3D12Filter ) \
    ( D3D12_DECODE_FILTER_REDUCTION( D3D12Filter ) == D3D12_FILTER_REDUCTION_TYPE_COMPARISON )

#define D3D12_DECODE_IS_ANISOTROPIC_FILTER( D3D12Filter ) \
    ( ( ( D3D12Filter ) & D3D12_ANISOTROPIC_FILTERING_BIT ) && \
    ( D3D12_FILTER_TYPE_LINEAR == D3D12_DECODE_MIN_FILTER( D3D12Filter) ) && \
    ( D3D12_FILTER_TYPE_LINEAR == D3D12_DECODE_MAG_FILTER( D3D12Filter) ) && \
    ( D3D12_FILTER_TYPE_LINEAR == D3D12_DECODE_MIP_FILTER( D3D12Filter) ) )

typedef enum D3D12_TEXTURE_ADDRESS_MODE
{
    D3D12_TEXTURE_ADDRESS_WRAP = 1,
    D3D12_TEXTURE_ADDRESS_MIRROR = 2,
    D3D12_TEXTURE_ADDRESS_CLAMP = 3,
    D3D12_TEXTURE_ADDRESS_BORDER = 4,
    D3D12_TEXTURE_ADDRESS_MIRROR_ONCE = 5
} D3D12_TEXTURE_ADDRESS_MODE;

typedef struct D3D12_SAMPLER_DESC
{
    D3D12_FILTER Filter;
    D3D12_TEXTURE_ADDRESS_MODE AddressU;
    D3D12_TEXTURE_ADDRESS_MODE AddressV;
    D3D12_TEXTURE_ADDRESS_MODE AddressW;
    FLOAT MipLODBias;
    UINT MaxAnisotropy;
    D3D12_COMPARISON_FUNC ComparisonFunc;
    FLOAT BorderColor[4]; // RGBA
    FLOAT MinLOD;
    FLOAT MaxLOD;
} D3D12_SAMPLER_DESC;

typedef struct D3D12_SAMPLER_DESC2
{
    D3D12_FILTER Filter;
    D3D12_TEXTURE_ADDRESS_MODE AddressU;
    D3D12_TEXTURE_ADDRESS_MODE AddressV;
    D3D12_TEXTURE_ADDRESS_MODE AddressW;
    FLOAT MipLODBias;
    UINT MaxAnisotropy;
    D3D12_COMPARISON_FUNC ComparisonFunc;
    union
    {
        FLOAT FloatBorderColor[4]; // RGBA
        UINT  UintBorderColor[4];
    };
    FLOAT MinLOD;
    FLOAT MaxLOD;
    D3D12_SAMPLER_FLAGS Flags;
} D3D12_SAMPLER_DESC;

interface ID3D12Device
{
    ...
    HRESULT CreateSampler(
    _In_ const D3D12_SAMPLER_DESC* pDesc,
    _In_ D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor);
};

interface ID3D12Device11
{
    ...
    HRESULT CreateSampler2(
    _In_ const D3D12_SAMPLER_DESC2* pDesc,
    _In_ D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor);
};
```

Note that static samplers in the root signature use a different
definition -- search for D3D12_STATIC_SAMPLER.

### Unordered Access View

StructureByteStride has been added to Buffer UAVs, where in D3D11 it was
a property of the resource. If the stride is nonzero, that indicates a
structured buffer view, and the format must be set to
DXGI_FORMAT_UNKNOWN.

```C++
typedef enum D3D12_BUFFER_UAV_FLAG
{
    D3D12_BUFFER_UAV_FLAG_RAW = 0x00000001,
    D3D12_BUFFER_UAV_FLAG_APPEND = 0x00000002,
    D3D12_BUFFER_UAV_FLAG_COUNTER = 0x00000004,
} D3D12_BUFFER_UAV_FLAG;

typedef struct D3D12_BUFFER_UAV
{
    UINT FirstElement;
    UINT NumElements;
    UINT StructureByteStride;
    ID3D12Query* pUAVCounter; // NULL if flags don't specify
    // APPEND or COUNTER
    UINT Flags; // See D3D12_BUFFER_UAV_FLAG_*
} D3D12_BUFFER_UAV;

typedef struct D3D12_TEX1D_UAV
{
    UINT MipSlice;
} D3D12_TEX1D_UAV;

typedef struct D3D12_TEX1D_ARRAY_UAV
{
    UINT MipSlice;
    UINT FirstArraySlice;
    UINT ArraySize;
} D3D12_TEX1D_ARRAY_UAV;

typedef struct D3D12_TEX2D_UAV
{
    UINT MipSlice;
    UINT PlaneSlice;
} D3D12_TEX2D_UAV;

typedef struct D3D12_TEX2D_ARRAY_UAV
{
    UINT MipSlice;
    UINT FirstArraySlice;
    UINT ArraySize;
    UINT PlaneSlice;
} D3D12_TEX2D_ARRAY_UAV;

typedef struct D3D12_TEX2DMS_UAV
{
    // don't need to define anything specific for this view dimension
    UINT UnusedField_NothingToDefine;
} D3D12_TEX2DMS_UAV;

typedef struct D3D12_TEX2DMS_ARRAY_UAV
{
    UINT FirstArraySlice;
    UINT ArraySize;
} D3D12_TEX2DMS_ARRAY_UAV;

typedef struct D3D12_TEX3D_UAV
{
    UINT MipSlice;
    UINT FirstWSlice;
    UINT WSize;
} D3D12_TEX3D_UAV;

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
// The MS options above are only available if the
// WriteableMSAATexturesSupported cap is TRUE, 
// and using shader model 6.7+

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

interface ID3D12Device
{
    ...
    void CreateUnorderedAccessView (
        _In_opt_ ID3D12Resource* pResource,
        _In_opt_ const D3D12_UNORDERED_ACCESS_VIEW_DESC* pDesc,
        _In_ D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor);
};
```

### Stream Output View

```C++
typedef struct D3D12_STREAM_OUTPUT_BUFFER_VIEW_DESC
{
    D3D12_GPU_VIRTUAL_ADDRESS BufferLocation;
    UINT64 SizeInBytes;
    D3D12_GPU_VIRTUAL_ADDRESS BufferFilledSizeLocation;
} D3D12_STREAM_OUTPUT_BUFFER_VIEW_DESC;

interface ID3D12Device
{
...
HRESULT CreateStreamOutputView(
    _In_opt_ ID3D12Resource* pBuffer,
    _In_opt_ const D3D12_STREAM_OUTPUT_BUFFER_VIEW_DESC* pDesc,
    _In_ D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor);
};
```

Above: BufferFilledSizeLocation can't be NULL -- a filled size location
must be supplied (which the hardware will increment as data is output).
The exception is if SizeInBytes is 0, which is effectively unbinding the
buffer, in which case the other two parameters can be anything and are
not used.

### Render Target View

```C++
typedef struct D3D12_BUFFER_RTV
{
    UINT FirstElement;
    UINT NumElements;
} D3D12_BUFFER_RTV;

typedef struct D3D12_TEX1D_RTV
{
    UINT MipSlice;
} D3D12_TEX1D_RTV;

typedef struct D3D12_TEX1D_ARRAY_RTV
{
    UINT MipSlice;
    UINT FirstArraySlice;
    UINT ArraySize;
} D3D12_TEX1D_ARRAY_RTV;

typedef struct D3D12_TEX2D_RTV
{
    UINT MipSlice;
    UINT PlaneSlice;
} D3D12_TEX2D_RTV;

typedef struct D3D12_TEX2DMS_RTV
{
    UINT UnusedField_NothingToDefine;
} D3D12_TEX2DMS_RTV;

typedef struct D3D12_TEX2D_ARRAY_RTV
{
    UINT MipSlice;
    UINT FirstArraySlice;
    UINT ArraySize;
    UINT PlaneSlice;
} D3D12_TEX2D_ARRAY_RTV;

typedef struct D3D12_TEX2DMS_ARRAY_RTV
{
    UINT FirstArraySlice;
    UINT ArraySize;
} D3D12_TEX2DMS_ARRAY_RTV;

typedef struct D3D12_TEX3D_RTV
{
    UINT MipSlice;
    UINT FirstWSlice;
    UINT WSize;
} D3D12_TEX3D_RTV;

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

interface ID3D12Device
{
    ...
    HRESULT CreateRenderTargetView(
        _In_opt_ ID3D12Resource* pResource,
        _In_opt_ const D3D12_RENDER_TARGET_VIEW_DESC* pDesc,
        _In_ D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor);
};

### Depth Stencil View

typedef struct D3D12_TEX1D_DSV
{
    UINT MipSlice;
} D3D12_TEX1D_DSV;

typedef struct D3D12_TEX1D_ARRAY_DSV
{
    UINT MipSlice;
    UINT FirstArraySlice;
    UINT ArraySize;
} D3D12_TEX1D_ARRAY_DSV;

typedef struct D3D12_TEX2D_DSV
{
    UINT MipSlice;
} D3D12_TEX2D_DSV;

typedef struct D3D12_TEX2D_ARRAY_DSV
{
    UINT MipSlice;
    UINT FirstArraySlice;
    UINT ArraySize;
} D3D12_TEX2D_ARRAY_DSV;

typedef struct D3D12_TEX2DMS_DSV
{
    UINT UnusedField_NothingToDefine;
} D3D12_TEX2DMS_DSV;

typedef struct D3D12_TEX2DMS_ARRAY_DSV
{
    UINT FirstArraySlice;
    UINT ArraySize;
} D3D12_TEX2DMS_ARRAY_DSV;

typedef enum D3D12_DSV_FLAG
{
    D3D12_DSV_READ_ONLY_DEPTH = 0x1L,
    D3D12_DSV_READ_ONLY_STENCIL = 0x2L,
} D3D12_DSV_FLAG;

typedef struct D3D12_DEPTH_STENCIL_VIEW_DESC
{
    DXGI_FORMAT Format;
    D3D12_DSV_DIMENSION ViewDimension;
    UINT Flags; // D3D12_DSV_FLAG
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

interface ID3D12Device
{
    ...
    HRESULT CreateDepthStencilView(
        _In_opt_ ID3D12Resource* pResource,
        _In_opt_ const D3D12_DEPTH_STENCIL_VIEW_DESC* pDesc,
        _In_ D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor);
};
```

## Copying Descriptors

CopyDescriptors on the device interface uses the CPU to immediately copy
descriptors. This can be called free threaded as long as multiple
threads on the CPU or GPU do not perform any potentially conflicting
writes.

The number of source descriptors (to copy from), specified as a set of
descriptor ranges, must equal the number of dest descriptors (to copy
to), specified as a separate set of descriptor ranges. The source and
destination ranges do not otherwise have to line up. For example, a
sparse set of descriptors could be copied to a contiguous destination,
vice versa, or some combination.

Multiple descriptor heaps can be involved in the copy, both as source
and destination. The use of descriptor handles as parameters means the
copy methods don't care about which heap(s) any given descriptor lies in
-- they are all just memory.

The descriptor heap types being copied from and to must match, so the
methods take a single descriptor heap type as input. The driver needs to
know the heap type that all the descriptors in the given copy operation
so it knows what size of data is involved in the copy. The driver might
also need to do custom copying work if a given descriptor heap type
warrants it -- an implementation detail. Note that descriptor handles
themselves do not otherwise identify what type they are pointing to,
hence the need for an additional parameter to the copy.

An alternative API is provided for the simple case of copying a single
range of descriptors from one location to another --
CopyDescriptorsSimple().

Copies with source and destination overlapping are invalid and will
produce undefined results in overlapping regions.

```C++
interface ID3D12Device
{
    ...
    void CopyDescriptors(
        _In_ UINT NumDestDescriptorRanges,
        _In_reads_(NumDestDescriptorRanges)
        const D3D12_CPU_DESCRIPTOR_HANDLE* pDestDescriptorRangeStarts,
        _In_reads_opt_(NumDestDescriptorRanges)
        const UINT* pDestDescriptorRangeSizes, // NULL means all ranges 1
        _In_reads_(NumSrcDescriptorRanges)
        const D3D12_CPU_DESCRIPTOR_HANDLE* pSrcDescriptorRangeStarts,
        _In_reads_opt_(NumSrcDescriptorRanges)
        const UINT* pSrcDescriptorRangeSizes, // NULL means all ranges 1
        _In_ D3D12_DESCRIPTOR_HEAP_TYPE DescriptorHeapsType);

    void CopyDescriptorsSimple(
        _In_ D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptorRangeStart,
        _In_ D3D12_CPU_DESCRIPTOR_HANDLE SrcDescriptorRangeStart,
        _In_ UINT NumDescriptors,
        _In_ D3D12_DESCRIPTOR_HEAP_TYPE DescriptorHeapsType);
}
```

For these descriptor copy methods, source descriptors must come from a
non-shader visible descriptor heap. The destination descriptors can be
in any descriptor heap (shader visible or not).

## Creating a Root Signature

Root signatures are a complex data structure containing nested
structures. These can be defined programmatically using the data
structure definition below (which includes Init() methods to help
initialize members). Alternatively they can be authored in HLSL --
giving the advantage that the compiler will validate early that the
layout is compatible with the shader. (HLSL syntax to be defined later).

The API for creating a root signature takes in a serialized (self
contained, pointer free) version of the layout description described
below. A method will be provided for generating this serialized version
from the C++ data structure, but another way to obtain a serialized root
signature definition is to retrieve it from a shader that has been
compiled with a root signature. An HLSL syntax alternative for
pre-authoring root signatures will be defined later.

### Root Signature Data Structure

#### Descriptor Table Bind Types

These are the types of descriptors that can be referenced as part of a
descriptor table layout definition. It is a range so that, for example
if part of a descriptor table a descriptor table has 100 SRVs, that
range can be declared in one entry rather than 100. So a descriptor
table definition is a collection of ranges.

```C++
typedef enum D3D12_DESCRIPTOR_RANGE_TYPE
{
    D3D12_DESCRIPTOR_RANGE_SRV,
    D3D12_DESCRIPTOR_RANGE_UAV,
    D3D12_DESCRIPTOR_RANGE_CBV,
    D3D12_DESCRIPTOR_RANGE_SAMPLER
} D3D12_DESCRIPTOR_RANGE_TYPE;
```

#### Descriptor Range

Defines a range of descriptors of a given type (e.g. SRVs) within a
descriptor table.

`#define D3D12_DESCRIPTOR_RANGE_OFFSET_APPEND -1`

`D3D12_DESCRIPTOR_RANGE_OFFSET_APPEND` can typically be used for the
OffsetInDescriptorsFromTableStart below. This means append the
descriptor range being defined after the previous one in the descriptor
table. If the application wants to alias descriptors or for some reason
skip slots it can set OffsetInDescriptorsFromTableStart to whatever
offset is desired. Defining overlapping ranges of different RangeType is
invalid.

The set of shader registers specified by the combination of RangeType,
NumDescriptors, BaseShaderRegister, and RegisterSpace cannot
conflict/overlap across any declarations in a root signature that have
common `D3D12_SHADER_VISIBILITY` (visibility defined a bit later).

```C++
typedef struct D3D12_DESCRIPTOR_RANGE
{
    D3D12_DESCRIPTOR_RANGE_TYPE RangeType;
    UINT NumDescriptors; // -1 means unbounded size.
                        // Only the last entry in a table can have
                        // unbounded size
    UINT BaseShaderRegister; // e.g. for SRVs, 3 maps to
                            // \": register(t3);\" in HLSL
    UINT RegisterSpace; // Can usually be 0, but allows multiple descriptor
                        // arrays of unknown size to not appear to overlap.
                        // e.g. for SRVs, extending example above, 5 for
                        // RegisterSpace maps to \": register(t3,space5);\"
                        // in HLSL. See the Note about Register Space later on.
    UINT OffsetInDescriptorsFromTableStart;
            // Can be D3D12_DESCRIPTOR_RANGE_OFFSET_APPEND, see above.
            // Initialize struct

    void Init(D3D12_DESCRIPTOR_RANGE_TYPE rangeType,
            UINT numDescriptors,
            UINT baseShaderRegister,
            UINT registerSpace = 0,
            UINT offsetInDescriptorsFromTableStart =
            D3D12_DESCRIPTOR_RANGE_OFFSET_APPEND)
    {
        RangeType = rangeType;
        NumDescriptors = numDescriptors;
        BaseShaderRegister = baseShaderRegister;
        RegisterSpace = registerSpace;
        OffsetInDescriptorsFromTableStart = offsetInDescriptorsFromTableStart;
    };
} D3D12_DESCRIPTOR_RANGE;
```

#### Root Descriptor Table

Declares the layout of a descriptor table as a collection of descriptor
ranges that appear one after the other in a descriptor heap.

Samplers are not allowed in the same descriptor table as CBV/UAV/SRVs.

This struct is a member of `D3D12_ROOT_PARAMETER`, and is used when its
ParameterType is set to `D3D12_ROOT_PARAMETER_DESCRIPTOR_TABLE`.

```C++
typedef struct D3D12_ROOT_DESCRIPTOR_TABLE
{
    UINT NumDescriptorRanges;
    const D3D12_DESCRIPTOR_RANGE* pDescriptorRanges;
} D3D12_ROOT_DESCRIPTOR_TABLE;
```

#### Root Constants

Declares constants inline in the root signature that appear in shaders
as one constant buffer.

This struct is a member of `D3D12_ROOT_PARAMETER`, and is used when its
SlotType is set to `D3D12_PARAMETER_32BIT_CONSTANTS`.

```C++
typedef struct D3D12_ROOT_CONSTANTS
{
    UINT Num32BitValues; // How many constants will occupy this single
                        // shader slot (appearing like a single constant
                        // buffer).
                        // All the values occupy a single root signature bind slot
    UINT ShaderRegister;
    UINT RegisterSpace;
} D3D12_ROOT_CONSTANTS;
```

#### Root Descriptor

Declares descriptors inline in the root signature that appear in
shaders.

This struct is a member of `D3D12_ROOT_TABLE_SLOT_RANGE`, and is used
when its SlotType is set to `D3D12_ROOT_TABLE_SLOT_CBV` / _UAV, _SRV
or _Sampler.

```C++
typedef struct D3D12_ROOT_DESCRIPTOR
{
    UINT ShaderRegister;
    UINT RegisterSpace;
} D3D12_ROOT_DESCRIPTOR;
```

#### Note About Register Space

Root parameter definitions and HLSL bindings specify both shader
register, e.g. register(t0), and optionally a register space,e.g.
register(t0,space3). The default register space is 0, so the first
example is the same as register(t0,space0).

The purpose of the register space field is to expand the namespace for
register bindings, so there is no hardware meaning to it. Register space
only affects linkage work done by both driver and driver shader
compiler. This has multiple purposes:

One use is in the case where a descriptor table has been declared with a
descriptor range of unbounded size, for instance an unbounded array of
SRVs appearing in a shader starting at register(t4). This means that
bindings t4.. t"INFINITY" are now occupied by the unbounded size
descriptor table. There are no more binding spots available without
appearing to overlap the unbounded array. That would be limiting -- what
if the application wants more bindings? Register space, for example,
register(t5,space1), gets past the issue by taking advantage of a second
dimension in the namespace. The register space field is nothing more
than that -- a way to help uniquely identify a bindpoint without
appearing to overlap with others.

Another use of register space is that the system reserves register space
values 0xfffffff0... 0xffffffff for internal use, such as for
instrumenting shaders during debug scenarios. This way the system can
add bindings to a shader in these reserves space without conflicting
with whatever register bindings the original shader used. The
reservation is split between driver and OS: register Space
0xfffffff0..0xffffff7 are reserved for driver use and
0xfffffff8..0xffffffff are reserved for OS use.

#### Shader visibility

Which shaders see the contents of a given root signature slot. Compute
always uses _ALL (since there is only one active stage). Graphics can
choose, but if it uses _ALL, all shader stages see whatever is bound at
the root signature slot.

```C++
typedef enum D3D12_SHADER_VISIBILITY
{
    D3D12_SHADER_VISIBILITY_ALL = 0,
    D3D12_SHADER_VISIBILITY_VERTEX = 1,
    D3D12_SHADER_VISIBILITY_HULL = 2,
    D3D12_SHADER_VISIBILITY_DOMAIN = 3,
    D3D12_SHADER_VISIBILITY_GEOMETRY = 4,
    D3D12_SHADER_VISIBILITY_PIXEL = 5
} D3D12_SHADER_VISIBILITY;
```

One use of shader visibility is to help with shaders that are authored
expecting different bindings per shader stage using an overlapping
namespace.

E.g. a VS may declare

```C++
Texture2D foo : register(t0);
```

and the PS may also declare:

```C++
Texture2D bar : register(t0);
```

If the application makes a root signature binding to t0 `VISIBILITY_ALL`,
both shaders see the same texture. If the shader defines actually wants
each shader to see different textures, it can define 2 root signature
slots with `VISIBILITY_VERTEX` and _PIXEL. No matter what the visibility
is on a root signature slot, it always has the same cost (cost only
depending on what the SlotTyype is) towards one fixed maximum root
signature size.

On low end D3D11 hardware, `SHADER_VISIBILITY` is also taken into account
used when validating the sizes of descriptor tables in a root signature,
since some D3D11 hardware can only support a maximum amount of bindings
per-stage. These restrictions are only imposed when running on low tier
hardware and do not limit more modern hardware at all.

If a root signature has multiple descriptor tables defined that overlap
each other in namespace (the register bindings to the shader) and any
one of them specifies _ALL for visibility, the layout is invalid
(creation will fail).

#### Root SIGNATURE Definition

The root signature can contain root constants, root descriptors and
descriptor tables.

```C++
typedef enum D3D12_ROOT_PARAMETER_TYPE
{
    D3D12_ROOT_PARAMETER_DESCRIPTOR_TABLE,
    D3D12_ROOT_PARAMETER_32BIT_CONSTANTS,
    D3D12_ROOT_PARAMETER_CBV,
    D3D12_ROOT_PARAMETER_SRV,
    D3D12_ROOT_PARAMETER_UAV
} D3D12_ROOT_PARAMETER_TYPE;

typedef struct D3D12_ROOT_PARAMETER
{
    D3D12_ROOT_PARAMETER_TYPE ParameterType;
    union
    {
        D3D12_ROOT_DESCRIPTOR_TABLE DescriptorTable;
        D3D12_ROOT_CONSTANTS Constants;
        D3D12_ROOT_DESCRIPTOR Descriptor;
    };
    D3D12_SHADER_VISIBILITY ShaderVisibility;
} D3D12_ROOT_PARAMETER;

typedef enum D3D12_ROOT_SIGNATURE_FLAGS
{
    D3D12_ROOT_SIGNATURE_ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT = 0x1,
    D3D12_ROOT_SIGNATURE_DENY_VERTEX_SHADER_ROOT_ACCESS = 0x2,
    D3D12_ROOT_SIGNATURE_DENY_HULL_SHADER_ROOT_ACCESS = 0x4,
    D3D12_ROOT_SIGNATURE_DENY_DOMAIN_SHADER_ROOT_ACCESS = 0x8,
    D3D12_ROOT_SIGNATURE_DENY_GEOMETRY_SHADER_ROOT_ACCESS = 0x10,
    D3D12_ROOT_SIGNATURE_DENY_PIXEL_SHADER_ROOT_ACCESS = 0x20,
    D3D12_ROOT_SIGNATURE_ALLOW_STREAM_OUTPUT = 0x40,
} D3D12_ROOT_SIGNATURE_FLAGS;

// The _DENY_*_ROOT_ACCESS flags above cannot be used with a root signature
// that has any parameters that set SHADER_VISIBILITY to the same
// shader stage (as that would be conflicting).
// The purpose of the SHADER_VISIBILITY flags is to limit a parameter to a single
// shader stage, while the purpose of the _DENY_*_ROOT_ACCESS flags above is
// to limit arguments that have visibility across shader all stages from being
// visible to specific shader stages. On some hardware this can result in lower
// cost for setting arguments by only broadcasting them to stages that actually need
// them.

typedef enum D3D12_STATIC_BORDER_COLOR
{
    D3D12_STATIC_BORDER_COLOR_TRANSPARENT_BLACK, // 0.0f,0.0f,0.0f,0.0f
    D3D12_STATIC_BORDER_COLOR_OPAQUE_BLACK, // 0.0f,0.0f,0.0f,1.0f
    D3D12_STATIC_BORDER_COLOR_OPAQUE_WHITE, // 1.0f,1.0f,1.0f,1.0f
    D3D12_STATIC_BORDER_COLOR_OPAQUE_BLACK_UINT, // 0u,0u,0u,1u
    D3D12_STATIC_BORDER_COLOR_OPAQUE_WHITE_UINT  // 1u,1u,1u,1u
};

typedef struct D3D12_STATIC_SAMPLER
{
    D3D12_FILTER Filter;
    D3D12_TEXTURE_ADDRESS_MODE AddressU;
    D3D12_TEXTURE_ADDRESS_MODE AddressV;
    D3D12_TEXTURE_ADDRESS_MODE AddressW;
    FLOAT MipLODBias;
    UINT MaxAnisotropy;
    D3D12_COMPARISON_FUNC ComparisonFunc;
    D3D12_STATIC_BORDER_COLOR BorderColor;
    FLOAT MinLOD;
    FLOAT MaxLOD;
    UINT ShaderRegister;
    UINT RegisterSpace;
    D3D12_SHADER_VISIBILITY ShaderVisibility;
} D3D12_STATIC_SAMPLER;

typedef struct D3D12_ROOT_SIGNATURE
{
    UINT NumParameters;
    const D3D12_ROOT_PARAMETER* pParameters;
    UINT NumStaticSamplers;
    const D3D12_STATIC_SAMPLER* pStaticSamplers;
    UINT Flags; // D3D12_ROOT_SIGNATURE_FLAGS
} D3D12_ROOT_SIGNATURE;
```

### Root Signature Data Structure Serialization / Deserialization

*[**NOTE:** The methods described here are still supported for
compatibility, but have been superseded by more functional variants
along with the instruction of Root Signature version 1.1, described
later. The methods here are only useful for manipulating version 1.0
Root Signatures.]*

The following methods are exported by D3D12Core.dll and provide methods
for serializing the above root signature data structure as well as
deserializing.

The serialized form is what is passed into the API when creating a root
signature. If a shader has been authored with a root signature in it,
the compiled shader will contain a serialized root signature in it
already.

If an application procedurally generates the above
`D3D12_ROOT_SIGNATURE` data structure, it must make the serialized form
using D3D12SerializeRootSignature(). The output of that can be passed
into ID3D12Device::CreateRootSignature().

If an application has a serialized root signature already, or has a
compiled shader that contains a root signature and wishes to
programmatically discover the layout definition (aka reflection),
D3D12CreateRootSignatureDeserializer() can be called. This generates an
interface that can returns `D3D12_ROOT_SIGNATURE`* - the deserialized
data structure. The interface just owns the lifetime of the memory for
the deserialized data structure.

```C++
HRESULT WINAPI D3D12SerializeRootSignature(
    _In_ const D3D12_ROOT_SIGNATURE* pRootSignature,
    _In_ D3D_ROOT_SIGNATURE_VERSION Version,
    _Out_ ID3DBlob** ppBlob,
    _Always_(_Outptr_opt_result_maybenull_) ID3DBlob**
    ppErrorBlob);

interface ID3D12RootSignatureDeserializer : public IUnknown
{
    const D3D12_ROOT_SIGNATURE* GetRootSignature();
};

HRESULT WINAPI D3D12CreateRootSignatureDeserializer(
    _In_reads_bytes_(SrcDataSizeInBytes) LPCVOID
    pSrcData,
    _In_ SIZE_T SrcDataSizeInBytes,
    _In_ REFIID pRootSignatureDeserializerInterface,
    _Out_ void** ppRootSignatureDeserializer);
```

### Root Signature Creation API

The following API takes in a serialized version of the root signature
described above.

```C++
interface ID3D12RootSignature : ID3D12DeviceChild
{
};

HRESULT ID3D12Device::CreateRootSignature(
    UINT nodeMask,
    void* pBlobWithRootSignature,
    SIZE_T BlobLengthInBytes,
    REFIID riid, // Expected: ID3D12RootSignature
    _Out_ void** ppvRootSignature);
```

### Root Signature in Pipeline State

The CreatePipelineState() API (documented separately) takes an optional
ID3D12RootSignature* as an input parameter.

If a root signature is passed into CreatePipelineState(), this root
signature is validated against all the shaders in the pipeline state for
compatibility and given to the driver to use with all the shaders. If
any of the shaders has a different root signature in it, it gets
replaced by the root signature passed in at the API.

If a root signature is not passed into CreatePipelineState(), all
shaders passed in must have a root signature and they must match -- this
will be given to the driver.

Setting a pipeline state on a command list or bundle does not change the
root signature. That is accomplished by the below methods. By the time
Draw*()/Dispatch*() is invoked, the application must ensure that the
current pipeline state matches the current root signature, otherwise
behavior is undefined.

## Setting a Root Signature

```C++
// [Command list types: DIRECT, BUNDLE, COMPUTE (except *Graphics* methods)]
interface ID3D12CommandList
{
    ...
    void SetComputeRootSignature(
        ID3D12RootSignature* pRootSignature);
    void SetGraphicsRootSignature(
        ID3D12RootSignature* pRootSignature);
};
```

## Setting Descriptor Tables in the Root Arguments

```C++
// [Command list types: DIRECT, BUNDLE, COMPUTE (except *Graphics* methods)]
interface ID3D12CommandList
{
    ...
    void SetComputeRootDescriptorTable(
    UINT RootParameterIndex,
    D3D12_GPU_DESCRIPTOR_HANDLE BaseDescriptor);
    void SetGraphicsRootDescriptorTable(
    UINT RootParameterIndex,
    D3D12_GPU_DESCRIPTOR_HANDLE BaseDescriptor);
}
```

For Tier 1 hardware CBV, UAV, SRV and Samplers and Tier 2 hardware CBV
and UAV descriptors, the application must put the full number of
descriptors defined in the root signature for the corresponding
descriptor table being set into the pointed to location in the
descriptor heap by the time the command list executes. This is even if
the shaders executing may not reference all of the descriptors. In all
other cases, the application is only responsible for initializing the
descriptor heap with valid descriptors in areas that will actually be
referenced during shader execution (by the time shaders actually
execute).

## Setting Constants in the Root Arguments

Note that constants can be partially set. So if the root signature
defines say 4 32-bit values at Parameter [2], then any subset of the 4
constants can be set at a time (the others remain unchanged). This can
be useful for instance in bundles which inherit root signature state and
can partially change it.

```C++
// [Command list types: DIRECT, BUNDLE, COMPUTE (except *Graphics* methods)]
interface ID3D12CommandList
{
...
// Single constant
void SetComputeRoot32BitConstant(
    UINT RootParameterIndex,
    UINT SrcData,
    UINT DestOffsetIn32BitValues);
    void SetGraphicsRoot32BitConstant(
    UINT RootParameterIndex,
    UINT SrcData,
    UINT DestOffsetIn32BitValues);

// Group of constants
void SetComputeRoot32BitConstants(
    UINT RootParameterIndex,
    const void* pSrcData,
    UINT DestOffsetIn32BitValues,
    UINT Num32BitValuesToSet);

void SetGraphicsRoot32BitConstants(
    UINT RootParameterIndex,
    const void* pSrcData,
    UINT DestOffsetIn32BitValues,
    UINT Num32BitValuesToSet);
}
```

## Setting Descriptors in the Root Arguments

The following APIs are for setting descriptors directly on the root
arguments. These descriptors are just a GPU Virtual Address which can be
obtained from ID3D12Resoruce::GetGPUVirtualAddress() and offsetted as
desired.

```C++
// [Command list types: DIRECT, BUNDLE, COMPUTE (except *Graphics* methods)]

interface ID3D12CommandList
{
    ...
    // CBV
    void SetComputeRootConstantBufferView (
        UINT RootParameterIndex,
        _In_ D3D12_GPU_VIRTUAL_ADDRESS BufferLocation);
        void SetGraphicsRootConstantBufferView (
        UINT RootParameterIndex,
        _In_ D3D12_GPU_VIRTUAL_ADDRESS BufferLocation);

    // SRV
    void SetComputeRootShaderResourceView (
        UINT RootParameterIndex,
        _In_ D3D12_GPU_VIRTUAL_ADDRESS BufferLocation);
        void SetGraphicsRootShaderResourceView (
        UINT RootParameterIndex,
        _In_ D3D12_GPU_VIRTUAL_ADDRESS BufferLocation);

    // UAV
    void SetComputeRootUnorderedAccessView (
        UINT RootParameterIndex,
        _In_ D3D12_GPU_VIRTUAL_ADDRESS BufferLocation);
        void SetGraphicsRootUnorderedAccessView (
        UINT RootParameterIndex,
        _In_ D3D12_GPU_VIRTUAL_ADDRESS BufferLocation);
}
```

## Setting IB/VB/SO/RT/DS On A Command List or Bundle

These methods take transparent (app visible) descriptors, or for
RTV/DSV, CPU descriptors from descriptor heaps. All of these methods
record/snapshot the current descriptor contents, so after the methods
return, the application's descriptor heap contents (or application
memory in the case of transparent descriptor types) are free to be
edited by the app again. In other words the driver does not hold a
reference to the source data.

SO/RT/DS can only be set on Command Lists, not bundles (though they are
inherited into bundles).

```C++
typedef struct D3D12_INDEX_BUFFER_VIEW
{
    D3D12_GPU_VIRTUAL_ADDRESS BufferLocation; // 0 fine only if SizeInBytes is 0
    UINT SizeInBytes; // 0 means nothing bound
    DXGI_FORMAT Format;
} D3D12_INDEX_BUFFER_VIEW;

typedef struct D3D12_VERTEX_BUFFER_VIEW
{
    D3D12_GPU_VIRTUAL_ADDRESS BufferLocation; // 0 fine only if SizeInBytes is 0
    UINT SizeInBytes; // 0 means nothing bound
    UINT StrideInBytes;
} D3D12_VERTEX_BUFFER_VIEW;

typedef struct D3D12_STREAM_OUTPUT_BUFFER_VIEW
{
    D3D12_GPU_VIRTUAL_ADDRESS BufferLocation; // 0 fine only if SizeInBytes is 0
    UINT64 SizeInBytes; // 0 means nothing bound
    D3D12_GPU_VIRTUAL_ADDRESS BufferFilledSizeLocation; // 0 fine only if SizeInBytes
                                                        // is 0
} D3D12_STREAM_OUTPUT_BUFFER_VIEW;

// [Command list types: DIRECT, BUNDLE (exceptions listed individually)]

interface ID3D12CommandList
{
    ...
    void SetIndexBuffer(
        _In_opt_ const D3D12_INDEX_BUFFER_VIEW* pDesc); // 0 GPUVA or NULL pDesc means
                        // "nothing bound"
                        // Partial updates of vertex buffer bindings are allowed.

    void SetVertexBuffers(
        _In_ UINT StartSlot,
        _In_reads_opt_(NumBuffers) const D3D12_VERTEX_BUFFER_VIEW* pDesc, // 0 GPUVA or
                                    // NULL pDesc means "nothing bound"
        _In_ UINT NumBuffers);
                // Partial updates of stream output buffer bindings are allowed.

    void SetStreamOutputBuffers(
        _In_ UINT StartSlot,
        _In_reads_opt_(NumBuffers) const
        D3D12_STREAM_OUTPUT_BUFFER_VIEW* pDesc, // 0
                                    // GPUVA or NULL pDesc means "nothing bound"
        _In_ UINT NumBuffers);

    // RenderTarget/DepthStencil bind setting always fully replaces any
    // previous binding for the entire bind space.
    // [Command list types: DIRECT only]
    void SetRenderTargets(
        _In_ const D3D12_CPU_DESCRIPTOR_HANDLE* pRenderTargetDescriptors,
        _In_ BOOL RTsSingleHandleToDescriptorRange,
        _In_ UINT NumRenderTargetDescriptors,
        _In_opt_ const D3D12_CPU_DESCRIPTOR_HANDLE
        *pDepthStencilDescriptor)
};
```

## View Manipulation APIs

For some of the Clear APIs below, like ClearUnorderedAccessView*(),
multiple handles -- CPU, GPU handle and resource pointer must be passed
to identify the view to operate on, whereas others, like
ClearRenderTargetView() only take a CPU descriptor handle.

CPU handles are used for descriptor types whose only purpose is
identifying descriptors to command lists as opposed to shaders
referencing them directly.

For descriptors that have shader access, both the CPU and GPU handle and
the resource underlying the view all need to be passed into APIs for
Clearing. Further, the GPU handle must come from the currently bound
descriptor heap on the command list. This requirement to pass multiple
seemingly redundant handles is because some implementations need
different combinations of the handles to perform the clear operation.

```C++
// If rects are supplied in D3D12_DISCARD_REGION, below, the resource
// must have 2D subresources with all specified subresources the same dimension.

typedef struct D3D12_DISCARD_REGION
{
    UINT NumRects;
    _In_reads_(NumRects) const D3D12_RECT* pRects;
    UINT FirstSubresource;
    UINT NumSubresources;
} D3D12_DISCARD_REGION;

interface ID3D12CommandList
{
...
// [Command list types: DIRECT]
void ClearDepthStencilView(
    _In_ D3D12_CPU_DESCRIPTOR_HANDLE DepthStencilView,
    _In_ UINT ClearFlags,
    _In_ FLOAT Depth,
    _In_ UINT8 Stencil,
    _In_ UINT NumRects,
    _In_reads_(NumRects) const D3D12_RECT *pRects);

// [Command list types: DIRECT]
void ClearRenderTargetView(
    _In_ D3D12_CPU_DESCRIPTOR_HANDLE ViewCPUHandle,
    _In_ const FLOAT ColorRGBA[4],
    _In_ UINT NumRects,
    _In_reads_(NumRects) const D3D12_RECT *pRects);

// [Command list types: DIRECT, COMPUTE]
void ClearUnorderedAccessViewUint(
    _In_ D3D12_GPU_DESCRIPTOR_HANDLE ViewGPUHandleInCurrentHeap,
    _In_ D3D12_CPU_DESCRIPTOR_HANDLE ViewCPUHandle,
    _In_ ID3D12Resource* pResource,
    _In_ const UINT Values[4],
    _In_ UINT NumRects,
    _In_reads_(NumRects) const D3D12_RECT *pRects);

// [Command list types: DIRECT, COMPUTE]
void ClearUnorderedAccessViewFloat(
    _In_ D3D12_GPU_DESCRIPTOR_HANDLE ViewGPUHandleInCurrentHeap,
    _In_ D3D12_CPU_DESCRIPTOR_HANDLE ViewCPUHandle,
    _In_ ID3D12Resource* pResource,
    _In_ const FLOAT Values[4],
    _In_ UINT NumRects,
    _In_reads_(NumRects) const D3D12_RECT *pRects);

// [Command list types: DIRECT, COMPUTE]
void DiscardResource(
    _In_ ID3D12Resource* pResource,
    _In_opt_ const D3D12_DISCARD_REGION* pDesc
    );
};
```

## Root Signature Version 1.1

This section describes the first revision to the Root Signature, version
1.1. These are a superset of the first Root Signature version shipped
with the original Windows 10 and D3D12 -- Root Signature version 1.0.

Root Signature version 1.0 continues to function unchanged, though
applications that recompile root signatures will default to Root
Signature 1.1 now (with an option to force version 1.0 if desired).

The purpose of Root Signature version 1.1 is to enable applications to
indicate to drivers when descriptors in a descriptor heap won't change
or the data descriptors point to won't change. This allows the option
for drivers to make optimizations that might be possible knowing that
something (like a descriptor or the memory it points to) is static for
some period of time. The specific optimizations drivers might do are
hardware vendor specific, and importantly they do not change behavior
other than possibly improving performance. The point is it doesn't hurt
to preserve as much knowledge about application intent as possible,
particularly given that both: the burden on applications is negligible
and it is very cheap for drivers to perform many optimizations they
might find interesting.

### Background

D3D12 allows the contents of descriptor heaps and the memory they point
at to be freely changed by applications any time that command lists /
bundles referencing them are potentially in flight on the GPU.

There is an advantage to this property: It gives applications one way to
have freedom to specialize how command lists / bundles behave after they
are recorded. For example, suppose an application is using dynamic
indexing in the descriptor heap to locate descriptors that represent the
latest set of mipmap levels that have been loaded for a texture. A
bundle referencing the descriptor heap doesn't have to be re-recorded to
use new descriptor(s) and instead can be fed a root constant at command
list record indicating where the latest descriptor(s) to use are.

Very often, however, applications don't actually need the flexibility to
change descriptors or memory after commands that reference them have
been recorded, for some duration of time that might extend all the way
until the command list / bundle hasn't finished executing for its last
time.

Applications are often trivially able to:

1. set up descriptors (and possible the memory they point to) before
    binding descriptor tables or root descriptors on a command list /
    bundle

2. ensure that these descriptors will not change for as long as the
    command list /bundles referencing them have not finished executing
    for the last time

3. ensure the data the descriptors point to does not change for the
    same full duration.

Alternatively, an application may only be able to honor guarantee (3),
that data doesn't change, for a shorter duration in time. In particular
data might be static for the window in time during command list
execution that a root parameter binding (descriptor table or root
descriptor) currently points to the data. In other words, an application
may wish to perform execution (GPU) timeline updates to some data in
between time periods where it is set via root parameter, knowing that
when it is set it will be static.

### Optimization Opportunity

What is interesting is that many drivers can produce more efficient
memory accesses by shaders if they know the promises an application can
make about the static-ness of descriptors / data.

As an example, knowing a descriptor in the heap is static, some drivers
could reduce a level of indirection for accessing a descriptor in a heap
by converting it into a root descriptor if the particular hardware is
not sensitive to root argument size.

In another example, if a driver knows the contents of memory pointed to
by a descriptor is static, and a shader fetches from a predictable
location in the memory, the driver could choose to copy the static data
into some location that would be more efficient for the shader to access
versus going through a descriptor / descriptor heap. The driver may be
able to make a better judgement about this than an application.

The application developer's usual job is unchanged: always design its
root signature as cleanly as it can: techniques like using root
descriptors and root constants when they are an obvious win, while not
making the root signature size too big if possible, given some hardware
prefers this to be kept small. The additional task for the developer is
to make promises about static-ness of data wherever possible so that
drivers can make further optimizations if they make sense. Of course if
applications do not want any meddling by drivers, for some reason, they
don't have to make any promises about static-ness.

### Flags Added in Root Signature version 1.1

Descriptor ranges (which make up descriptor tables) and root descriptors
now each support a Flags field. The new structs that have the flags
fields added are detailed later, but first a definition of the new
flags. The reason these flags are part of the root signature is to allow
drivers to choose a strategy for how to best handle individual root
arguments when they are set, based on the flags and also embed the same
assumptions to into PSOs when they are originally compiled (since the
root signature is part of a PSO).

#### Descriptor Range Flags

On each range of descriptors comprising a descriptor table declaration,
the following flags can be specified:

```C++
typedef enum D3D12_DESCRIPTOR_RANGE_FLAGS
{
    D3D12_DESCRIPTOR_RANGE_FLAG_NONE = 0,
    D3D12_DESCRIPTOR_RANGE_FLAG_DESCRIPTORS_VOLATILE = 0x1,
    D3D12_DESCRIPTOR_RANGE_FLAG_DATA_VOLATILE = 0x2,
    D3D12_DESCRIPTOR_RANGE_FLAG_DATA_STATIC_WHILE_SET_AT_EXECUTE = 0x4,
    D3D12_DESCRIPTOR_RANGE_FLAG_DATA_STATIC = 0x8,
    D3D12_DESCRIPTOR_RANGE_FLAG_DESCRIPTORS_STATIC_KEEPING_BUFFER_BOUNDS_CHECKS = 0x10000,
} D3D12_DESCRIPTOR_RANGE_FLAGS;
```

**DESCRIPTORS_VOLATILE**:

The descriptors in a descriptor heap pointed to by a root descriptor
table can be changed by the application any time except while the
command list / bundles that bind the descriptor table have been
submitted and have not finished executing. For instance, recording a
command list and subsequently changing descriptors in a descriptor heap
it refers to before submitting the command list for execution is valid.
This is the only behavior that Root Signature version 1.0 supported (it
didn't have a way to choose).

**Absence of DESCRIPTORS_VOLATILE:**

Descriptors are **static.** There is no flag for this mode. Static
descriptors mean the descriptors in a descriptor heap pointed to by a
root descriptor table have been initialized by the time the descriptor
table is set on a command list / bundle (during recording), and the
descriptors cannot be changed until the command list / bundle has
finished executing for the last time. For Root Signature version 1.1,
static descriptors are the default assumption, given the application has
to go out of its way to specify the `DESCRIPTORS_VOLATILE` flag when
needed.

For bundles using descriptor tables with static descriptors, the
descriptors have to be ready starting at the time the bundle is recorded
(as opposed to when the bundle is called), and not change until the
bundle has finished executing for the last time. Descriptor tables
pointing to static descriptors have to be set during bundle recording
and not inherited into the bundle. It is ok for a command list to use a
descriptor table with static descriptors that has been set in a bundle
and returned back to the command list.

When descriptors are static there is another change in behavior vs
`DESCRIPTORS_VOLATILE`: Out of bounds accesses to any Buffer views (as
opposed to Texture1D/2D/3D/Cube views) are invalid and produce undefined
results, including possible device reset, rather than returning default
values for reads or dropping writes. The purpose for removing the
ability for applications to depend on hardware out of bounds access
checking is to allow drivers to choose to promote static descriptor
accesses to root descriptor accesses if they deem that more efficient.
Root descriptors don't support any out of bounds checking. If
applications depend on safe out of bounds memory access behavior when
accessing descriptors, they need to mark the descriptor ranges that
access those descriptors as `DESCRIPTORS_VOLATILE`.

**DESCRIPTORS_STATIC_KEEPING_BUFFER_BOUNDS_CHECKS:**

An additional flag is added to Root Signature 1.1 in the Windows 10
Spring Creator's Update (1804), which indicates that descriptors should
have all of the above static properties **except** that out of bounds
accesses to Buffer views remain valid, and continue to return zeroes.
This still enables several optimizations, but does require the driver to
maintain the size information of the buffer views.

**DATA_VOLATILE**:

(This applies to both descriptor range flags and root descriptor flags
shown later.)

The data pointed to by descriptors can be changed by the CPU any time
except while the command list / bundles that bind the descriptor table
have been submitted and have not finished executing. This is the only
behavior that Root Signature version 1.0 supported (it didn't have a way
to choose).

**DATA_STATIC_WHILE_SET_AT_EXECUTE:**

(This applies to both descriptor range flags and root descriptor flags
shown later.)

The data pointed to by descriptors cannot change starting from when the
underlying root descriptor or descriptor table is set on a command list
/ bundle during execution (GPU timeline), and ending when subsequent
draws/dispatches will no longer reference the data.

Before a root descriptor or descriptor table has been set on the GPU,
this data can be changed even by the same command list / bundle. The
data can also be changed while a root descriptor or descriptor table
pointing to it is still set on the command list / bundle (as mentioned
above, draw/dispatches referencing it must have completed), however
doing so requires the descriptor table be rebound to the command list
again before the next time the root descriptor or descriptor table is
dereferenced. This allows the driver to know that data pointed to by a
root descriptor or descriptor table has changed.

The essential difference between `DATA_STATIC_WHILE_SET_AT_EXECUTE`
and `DATA_VOLATILE` is with `DATA_VOLATILE` a driver can't tell whether
data copies in a command list have changed the data pointed to by a
descriptor, without doing extra state tracking which D3D12 tries to
eliminate the need for. So if, for instance, a driver can insert any
sort of data prefetching commands into their command list (to make
shader access to known data more efficient somehow),
`DATA_STATIC_WHILE_SET_AT_EXECUTE` lets the driver know it only needs
to bother to data prefetching at the moment it is set via
Set*DescriptorTable() or Set*RootCBV/SRV/UAV().

For bundles, the promise that data is static while set at execute
applies uniquely to each execution of the bundle.

**DATA_STATIC:**

(This applies to both descriptor range flags and root descriptor flags
shown later.)

The data pointed to by descriptors has been initialized by the time a
root descriptor or descriptor table referencing the memory has been set
on a command list / bundle (during recording), and the data cannot be
changed until the command list / bundle has finished executing for the
last time.

For bundles, to clarify, the static duration starts at root descriptor
or descriptor table setting during the recording of the bundle, as
opposed to recording of a calling command list. In addition, a
descriptor table pointing to static data must be set in the bundle and
not inherited in. It is ok for a command list to use a descriptor table
pointing to static data that has been set in a bundle and returned back
to the command list.

**Remarks:**

The absence of the `DESCRIPTORS_VOLATILE` flag indicates that descriptors
are **static**. This means the descriptors in a descriptor heap pointed
to by a root descriptor table have been initialized by the time the
descriptor table is set on a command list / bundle (during recording),
and the descriptors cannot be changed until the command list / bundle
has finished executing for the last time.

At most one of the `DATA_*` flags can be specified at a time. The
exception is Sampler descriptor ranges which don't support `DATA_*`
flags at all since samplers do not point to data.

The absence of any `DATA_*` flags for SRV and CBV descriptor ranges
means a default of `DATA_STATIC_WHILE_SET_AT_EXECUTE` behavior is
assumed. The reason this default is chosen rather than `DATA_STATIC` is
that `DATA_STATIC_WHILE_SET_AT_EXECUTE` is much more likely to be a
safe default for the vast majority of cases (where a developer may not
have put thought into setting the root signature flags), while still
yielding some optimization opportunity better than defaulting to
`DATA_VOLATILE`.

The absence of DATA* flags for UAV descriptor ranges means a default of
`DATA_VOLATILE` behavior is assumed, given typically UAVs are written to.

`DESCRIPTORS_VOLATILE` cannot be combined with `DATA_STATIC` since they
would be at odds: saying that during command list /bundle record the
descriptors are not known yet what they point to is already known makes
no sense. On the other hand, `DESCRIPTORS_VOLATILE` can be combined with
the other `DATA_*` flags. The reason `DESCRIPTORS_VOLATILE` can be
combined with `DATA_STATIC_WHILE_SET_AT_EXECUTE` is that volatile
descriptors still require the descriptors be ready during command list /
bundle execution, and `DATA_STATIC_WHILE_SET_AT_EXECUTE` is only
making promises about the static-ness within a subset of command list /
bundle execution.

**Valid Descriptor Range Flags Settings**    | **Remarks**
---|---
| none                              | <p>Descriptors static (default).</p><p>Default assumptions for data:</p><p>**For SRV/CBV**: `DATA_STATIC_WHILE_SET_AT_EXECUTE`</p><p>**For UAV**: `DATA_VOLATILE`</p><p>The goal is these defaults for SRV/CBV will safely fit the usage patterns for the majority of root signatures where applications have not thought about the flag settings at all, giving drivers ample optimization opportunity for free that wasn't captured by root signature version 1.0.</p>
`DATA_STATIC`                      | Descriptors static (default) + data static
`DATA_VOLATILE`                    | Descriptors static (default) + data volatile
`DATA_STATIC_WHILE_SET_AT_EXECUTE` | Descriptors static (default) + data static while set at execute
`DESCRIPTORS_VOLATILE`             | <p>Descriptors volatile + Default assumptions for data:</p><p>**For SRV/CBV**: `DATA_STATIC_WHILE_SET_AT_EXECUTE`</p><p>**For UAV**: `DATA_VOLATILE`</p>
`DESCRIPTORS_VOLATILE | DATA_VOLATILE` | Both descriptors and data volatile, equivalent to Root Signature 1.0
`DESCRIPTORS_VOLATILE | DATA_STATIC_WHILE_SET_AT_EXECUTE`         | Descriptors volatile,but note that still doesn't allow them to change during command list execution. So it is valid to combine the additional declaration that data is static while set via root descriptor table during execution -- the underlying descriptors are effectively static for longer than the data is being promised to be static.

#### Root Descriptor Flags

```C++
typedef enum D3D12_ROOT_DESCRIPTOR_FLAGS
{
    D3D12_ROOT_DESCRIPTOR_FLAG_NONE = 0,
    D3D12_ROOT_DESCRIPTOR_FLAG_DATA_VOLATILE = 0x2,
    D3D12_ROOT_DESCRIPTOR_FLAG_DATA_STATIC_WHILE_SET_AT_EXECUTE = 0x4,
    D3D12_ROOT_DESCRIPTOR_FLAG_DATA_STATIC = 0x8
} D3D12_ROOT_DESCRIPTOR_FLAGS;
```

These flags have the same semantics as descriptor range flags described
earlier, except that for root descriptors only `DATA_*` flags apply. By
definition, root descriptors are static, as they are directly set into
command lists / bundles, so there is no root descriptor equivalent to
the flag `D3D12_DESCRIPTOR_RANGE_FLAG_DESCRIPTORS_VOLATILE`.

**Valid Root Descriptor Flags Settings**     | **Remarks**
---|---
| none                              | <p>Default assumptions for data:</p><p>**For SRV/CBV**: `DATA_STATIC_WHILE_SET_AT_EXECUTE`</p><p>**For UAV**: `DATA_VOLATILE`</p><p>The goal is these defaults for SRV/CBV will safely fit the usage patterns for the majority of root signatures where applications have not thought about the flag settings at all, giving drivers ample optimization opportunity for free that wasn't captured by root signature version 1.0.</p>
`DATA_STATIC`  | \-
`DATA_VOLATILE`  | Equivalent to Root Signature 1.0
`DATA_STATIC_WHILE_SET_AT_EXECUTE` | \-

#### Consequences of Violating Promises From Static-ness Flags

The `DESCRIPTORS_*` and `DATA_*` flags described above (as well as the
defaults implied by the absence of particular flags) define a promise by
the application to the driver about how it is going to behave. If an
application violates the promise, this is invalid behavior: results are
undefined and might be different across different drivers and hardware.

For example, with no flags set for a CBV descriptor range in a
descriptor table, the defaults described above are that the descriptors
are static and the data they point to is static while set at execute. So
it would be invalid to record a command list that sets this descriptor
table and then changes a descriptor in the heap after that (assuming the
command list has not finished executing for the last time). Similarly it
would be invalid to issue a copy command on the command list that writes
to data pointed to by the descriptors while a descriptor table points to
the descriptors, unless the copy happens after draw/dispatches using the
descriptor table are complete (enforced by issuing appropriate resource
barrier/transition API calls before copying). After this copying
scenario, once the resource is transitioned back into an appropriate
state for access by draw/dispatch the descriptor table pointing to the
data must be rebound again -- even though this may appear to be a
redundant state setting, it informs the driver that something promised
to be static has changed -- drivers do not track data flow.

The debug layer will have options for validating that applications honor
their promises, including the default promises that come with using Root
Signature version 1.1 without setting any flags.

### Root Signature Version 1.1 API

The following structures define a new versioned root signature
de-serialized format, `D3D12_VERSIONED_ROOT_SIGNATURE_DESC`, which can
hold any root signature version.

The new version, 1.1, is defined via `D3D12_ROOT_SIGNATURE_DESC1`
(which will be further detailed below). Root Signature version 1.1
simply introduces new flags parameters described earlier to descriptor
ranges and root descriptors, allowing the level of staticness of
descriptors and data to be declared.

```C++
typedef enum D3D_ROOT_SIGNATURE_VERSION
{
    D3D_ROOT_SIGNATURE_VERSION_1 = 0x1,
    D3D_ROOT_SIGNATURE_VERSION_1_0 = 0x1,
    D3D_ROOT_SIGNATURE_VERSION_1_1 = 0x2
} D3D_ROOT_SIGNATURE_VERSION;

typedef struct D3D12_FEATURE_DATA_ROOT_SIGNATURE
{
    _Inout_ D3D_ROOT_SIGNATURE_VERSION HighestVersion;
} D3D12_FEATURE_DATA_ROOT_SIGNATURE;

typedef struct D3D12_VERSIONED_ROOT_SIGNATURE_DESC
{
D3D_ROOT_SIGNATURE_VERSION Version;
    union
    {
        D3D12_ROOT_SIGNATURE_DESC Desc_1_0;
        D3D12_ROOT_SIGNATURE_DESC1 Desc_1_1;
    };
} D3D12_VERSIONED_ROOT_SIGNATURE_DESC;
```

### Versioned Root Signature Data Structure Serialization / Deserialization

The following methods are exported by D3D12Core.dll and provide methods
for serializing the above root signature data structure as well as
deserializing: D3D12Serialize**Versioned**RootSignature() and
D3D12Deserialize**Versioned**RootSignature(). These methods supersede
the original
D3D12SerializeRootSignature()/D3D12DeserializedRootSignature()
functions, which only operate on version 1.0 root signatures -- they
were intended to scale to support new versions but not correctly
designed for it, hence new Versioned functions for serializing and
deserializing.

The serialized form is what is passed into the API when creating a root
signature. If a shader has been authored with a root signature in it,
the compiled shader will contain a serialized root signature in it
already.

If an application procedurally generates the above
`D3D12_VERSIONED_ROOT_SIGNATURE` data structure, it must make the
serialized form using D3D12SerializeVersionedRootSignature(). The output
of that can be passed into ID3D12Device::CreateRootSignature().

```C++
HRESULT WINAPI D3D12SerializeVersionedRootSignature(
    _In_ const D3D12_VERSIONED_ROOT_SIGNATURE_DESC*
    pRootSignature,
    _Out_ ID3DBlob** ppBlob,
    _Always_(_Outptr_opt_result_maybenull_) ID3DBlob**
    ppErrorBlob);

interface ID3D12VersionedRootSignatureDeserializer : public IUnknown
{
    HRESULT GetRootSignatureDescAtVersion(
        D3D_ROOT_SIGNATURE_VERSION convertToVersion,
        _Out_ const D3D12_VERSIONED_ROOT_SIGNATURE_DESC **ppDesc;
        const D3D12_VERSIONED_ROOT_SIGNATURE_DESC*);

    GetUnconvertedRootSignatureDesc(void);
};

HRESULT WINAPI D3D12CreateVersionedRootSignatureDeserializer(
    _In_reads_bytes_(SrcDataSizeInBytes) LPCVOID pSrcData,
    _In_ SIZE_T SrcDataSizeInBytes,
    _In_ REFIID pRootSignatureDeserializerInterface,
    _Out_ void** ppRootSignatureDeserializer);
```

If an application has a serialized root signature already, or has a
compiled shader that contains a root signature and wishes to
programmatically discover the layout definition (aka reflection),
**D3D12CreateVersionedRootSignatureDeserializer()** can be used. This
generates an interface that can return
`D3D12_VERSIONED_ROOT_SIGNATURE*` - the deserialized data structure,
via **GetUncovertedRootSignature()**. The interface just owns the
lifetime of the memory for the deserialized data structure.

The deserializer can also be asked to convert a root signature to a
particular version, via **GetRootSignatureDescAtVersion().** This
allocates additional storage if needed for the converted root signature
(memory owned by the deserializer interface), and can fail with
`E_OUTOFMEMORY`. If conversion is done, the deserializer interface
doesn't free the original deserialized root signature memory -- all
versions the interface has been asked to convert to stay alive until the
deserializer is destroyed.

Converting a root signature from 1.1 to 1.0 will drop all descriptor
range flags and root descriptor flags -- this doesn't change behavior as
it only loses optimization opportunity, and can be handy for generating
compatible root signatures that need to run on old operating systems.
For instance multiple root signature versions can be serialized and
stored with application assets, with the appropriate version used at
runtime based on the operating system capabilities. A capability query
for device root signature support is described later.

Converting a root signature from 1.0 to 1.1 just adds the appropriate
flags to match 1.0 semantics.

### Root Signature Version 1.1 Structures

The following structures, used by `D3D12_ROOT_SIGNATURE_DESC1` (shown
earlier) are equivalent to structures used for version 1.0 root
signatures -- `D3D12_ROOT_SIGNATURE_DESC` with the addition of new
flags fields for descriptor ranges and root descriptors. The "HLSL Root
Signature Language" section later on has been updated to show how the
new flags appear in HLSL.

```C++
DEFINE_ENUM_FLAG_OPERATORS( D3D12_DESCRIPTOR_RANGE_FLAGS );

typedef struct D3D12_DESCRIPTOR_RANGE1
{
    D3D12_DESCRIPTOR_RANGE_TYPE RangeType;
    UINT NumDescriptors;
    UINT BaseShaderRegister;
    UINT RegisterSpace;
    D3D12_DESCRIPTOR_RANGE_FLAGS Flags;
    UINT OffsetInDescriptorsFromTableStart;
} D3D12_DESCRIPTOR_RANGE1;

typedef struct D3D12_ROOT_DESCRIPTOR_TABLE1
{
    UINT NumDescriptorRanges;
    _Field_size_full_(NumDescriptorRanges)
    const D3D12_DESCRIPTOR_RANGE1 *pDescriptorRanges;
} D3D12_ROOT_DESCRIPTOR_TABLE1;

DEFINE_ENUM_FLAG_OPERATORS( D3D12_ROOT_DESCRIPTOR_FLAGS );

typedef struct D3D12_ROOT_DESCRIPTOR1
{
    UINT ShaderRegister;
    UINT RegisterSpace;
    D3D12_ROOT_DESCRIPTOR_FLAGS Flags;
} D3D12_ROOT_DESCRIPTOR1;

typedef struct D3D12_ROOT_PARAMETER1
{
    D3D12_ROOT_PARAMETER_TYPE ParameterType;
    union
    {
        D3D12_ROOT_DESCRIPTOR_TABLE1 DescriptorTable;
        D3D12_ROOT_CONSTANTS Constants;
        D3D12_ROOT_DESCRIPTOR1 Descriptor;
    };
    D3D12_SHADER_VISIBILITY ShaderVisibility;
} D3D12_ROOT_PARAMETER1;
```

## Querying Root Signature Version Support

To determine the level of Root Signature support on a system, call
CheckFeatureSupport() with `D3D12_FEATURE_ROOT_SIGNATURE`. The data
associated with this is:

```C++
typedef struct D3D12_FEATURE_DATA_ROOT_SIGNATURE
{
    _Inout_ D3D_ROOT_SIGNATURE_VERSION HighestVersion;
} D3D12_FEATURE_DATA_ROOT_SIGNATURE;
```

To use this structure, first fill in HighestVersion with the highest
Root Signature version the application understands, and then pass the
struct into CheckFeatureSupport(). If the OS preceded Root Signature
version 1.1 support, the call to
`CheckFormatSupport(D3D12_FEATURE_ROOT_SIGNATURE,...)` will simply
always fail with `E_INVALIDARG` since old operating systems don't even
know about this new capability query. In this case the highest version
of Root Signature support is 1.0.

If the OS supports the `D3D12_FEATURE_ROOT_SIGNATURE` query, the
runtime will return the highest root signature version it supports that
does not exceed what the application said it is aware of. If an
application is aware of Root Signature 1.1, it can set HighestVersion to
this value, and the runtime will confirm this by returning 1.1 out in
the same field. In a hypothetical future where there is a version 1.2
supported, but the application is only aware of 1.1 (initializing
HighestVersion to 1.1), the runtime will only return 1.1 instead of 1.2.

# Resource Binding In HLSL

The existing SM5 (shader model 5) resource syntax uses the 'register'
keyword to relay important information about the resource to the HLSL
compiler. For example:

Texture2D<float4> tex1[4] : register(t3)

declares an array of four textures bound at slots t3, t4, t5, and t6.

The new SM5.1 resource syntax in HLSL is based on pre-D3D12 'register'
resource syntax, mainly to allow easier porting. D3D12 resources in HLSL
are bound to virtual registers within logical register spaces:

- t -- for shader resource views (SRV)

- s -- for samplers

- u -- for unordered access views (UAV)

- b -- for constant buffer views (CBV)

A resource declaration may be a scalar, a 1D array or a multidimensional
array:

```C++
Texture2D<float4> tex1 : register(t3, space0)
Texture2D<float4> tex2[4] : register(t10)
Texture2D<float4> tex3[7][5][3] : register(t20, space1)
```

SM5.1 uses the same resource types and element types as SM5.0.
Declaration limits are much more permissive now and constrained by the
runtime/hardware limits, which makes the maximum range size to be 2^27^
entries. The 'space' keyword specifies to which logical register space
the declared variable is bound too. If space is omitted, the default
space index of 0 is implicitly assigned to the range (so tex2 range
above resides in space0).

An array resource may have an unbounded size, which is declared by
specifying the very first dimension to be empty or 0:

```C++
Texture2D<float4> tex2[] : register(t0, space0)
Texture2D<float4> tex3[0][5][3] : register(t5, space1)
```

Aliasing of resource ranges is not allowed. In other words, for each
resource type (t,s,u,b), declared register ranges must not overlap. This
includes unbounded ranges too. Ranges declared in different register
spaces never overlap. Note that unbounded tex2 resides in space0, while
unbounded tex3 resides in space1, such that they do not overlap.

By default, the compiler does not accept unbounded size descriptor
tables, because use of unbounded (or large) size descriptor tables can
produce unusually large and potentially unusable frame captures in
graphics tools. Support for unbounded ranges can be enabled by supplying
/enable_unbounded_descriptor_tables to fxc.exe or passing the
`D3DCOMPILE_ENABLE_UNBOUNDED_DESCRIPTOR_TABLES` compilation flag to
d3dcompiler_47.dll.

## Resource aliasing

The resource ranges specified in the HLSL shaders are "logical ranges".
They must be bound to concrete heap ranges at runtime via the root
signature mechanism. Normally, a logical range maps to a heap range that
does not overlap with other heap ranges. However, the root signature
mechanism makes it possible to alias (overlap) heap ranges of compatible
types. For example, tex2 and tex3 ranges from the above example may be
mapped to the same (or overlapping) heap range, which has the effect of
aliasing textures in the HLSL program. If such aliasing is desired, the
shader must be compiled with `D3D10_SHADER_RESOURCES_MAY_ALIAS` option
(/res_may_alias option for fxc.exe). The option makes the compiler
produce correct code by preventing certain load/store optimizations
under the assumption that resources may alias. In the future, we may
consider a finer-grain mechanism to specify which resources may alias,
assuming there is interest.

## Divergence and derivatives

SM5.1 does not impose limitations on the resource index; i.e.,
tex2[idx].Sample(...) -- the index idx can be a literal constant, a
cbuffer constant, or an interpolated value. While the programming model
provides such great flexibility, there are pitfalls to be aware of:

- If index diverges across a quad, the hardware-computed derivative
    and derived quantities such as LOD may be undefined. The HLSL
    compiler will make the best effort to issue a warning in this case,
    but will not prevent shader from compiling. This behavior is similar
    to computing derivatives in divergent control flow.

- If resource index is divergent, the performance is diminished
    compared to the case of a uniform index, because the hardware needs
    to perform operations on several resources.

The HLSL compiler assumes resource index expressions to be uniform, as
this is the most typical usage case. If a resource index may be
non-uniform (meaning varying anywhere within a draw or dispatch call --
instancing counts as varying), programmers must use the
'NonUniformResourceIndex' intrinsic to convey this fact to the compiler;
otherwise, the result is undefined. For example:

```C++
Texture2D tex1[4][8];
...
... = tex1[i1][ NonUniformResourceIndex (i2 * 2)].Sample(...);
```

For a multi-dimensional resource, it is sufficient to apply
NonUniformResourceIndex to any index.

The corresponding non-uniform index operands get annotated with the
non-uniform bit, e.g.,

```C++
sample r2.xyzw, v0.xyxx, t0[r1.w + 0].xyzw { nonuniform }, s1[r1.z +
1] { nonuniform }
```

## UAVs in pixel shaders

SM5.1 does not impose constraints on UAV ranges in pixel shaders as was
the case for SM5.0. If needed, driver compilers are responsible for
remapping UAVs in such a way that RTV and UAV ranges do not overlap.

## Constant buffers

SM5.1 constant buffers (cbuffer) syntax needs some changes to enable
developers to index cbuffers. To enable indexable cbuffers, SM5.1
introduces the ConstantBuffer "template" construct:

```C++
struct Foo
{
    float4 a;
    int2 b;
};

ConstantBuffer<Foo> myCB1[2][3] : register(b2, space1);
ConstantBuffer<Foo> myCB2 : register(b0, space1);
```

The above code declares cbuffer variable myCB1 of type Foo and size 6,
and a "scalar", cbuffer variable myCB2. A cbuffer variable can now be
indexed in the shader as:

```C++
myCB1[i][j].a.xyzw
myCB2.b.yy
```

Fields 'a' and 'b' do not become "global" variables, but rather must be
treated as fields.

For backward compatibility, SM5.1 will support the old cbuffer concept
for "scalar" cbuffers, e.g.:

```C++
cbuffer : register(b1)
{
    float4 a;
    int2 b;
};
```

makes 'a' and 'b' global, read-only variables as in SM5.0. However, such
an old-style cbuffer cannot be indexable.

Currently, the compiler will support ConstantBuffer template of only
user-defined structs. We may extend template argument to be primitive
types, vectors, etc. in the future.

For compatibility reasons, the HLSL compiler may automatically assign
resource registers for ranges declared in space0. If 'space' is omitted
in the register clause, the default space0 is used. The compiler uses
first-hole-fits heuristic to assign the registers. The assignment can be
retrieved via the reflection API, which has been extended to add the
"Space" field for space, while "BindPoint" filed indicates the lower
bound of the resource register range.

## Bytecode changes in SM5.1

SM5.1 changes how resource registers are declared and referenced in
instructions. We moved towards declaring a register "variable", similar
to how it is done for group shared memory registers. It is best to
illustrate with an example (only declarations really matter):

```C++
Texture2D<float4> tex0 : register(t5, space0);
Texture2D<float4> tex1[][5][3] : register(t10, space0);
Texture2D<float4> tex2[8] : register(t0, space1);
SamplerState samp0 : register(s5, space0);

float4 main(float4 coord : COORD) : SV_TARGET
{
    float4 r = coord;
    r += tex0.Sample(samp0, r.xy);
    r += tex2[r.x].Sample(samp0, r.xy);
    r += tex1[r.x][r.y][r.z].Sample(samp0, r.xy);
    return r;
}
```

The disassembly:

```C++
// ----------------------------------------------------
// Resource Bindings:
//
// Name Type Format Dim ID HLSL Bind Count
// ----------------------------------------------------
// samp0 sampler NA NA S0 s5 1
// tex0 texture float4 2d T0 t5 1
// tex1 texture float4 2d T1 t10 unbounded
// tex2 texture float4 2d T2 t0,space1 8
//
//
//
// Input signature:
//
// Name Index Mask Register SysValue Format Used
// ----------------------------------------------------
// COORD 0 xyzw 0 NONE float xyzw
//
//
// Output signature:
//
// Name Index Mask Register SysValue Format Used
// ----------------------------------------------------
// SV_TARGET 0 xyzw 0 TARGET float xyzw
//
ps_5_1
dcl_globalFlags refactoringAllowed
dcl_sampler S0[5:5], mode_default, space=0
dcl_resource_texture2d (float,float,float,float) T0[5:5], space=0
dcl_resource_texture2d (float,float,float,float) T1[10:*], space=0
dcl_resource_texture2d (float,float,float,float) T2[0:7], space=1
dcl_input_ps linear v0.xyzw
dcl_output o0.xyzw
dcl_temps 2
sample r0.xyzw, v0.xyxx, T0[5].xyzw, S0[5]
add r0.xyzw, r0.xyzw, v0.xyzw
ftou r1.x, r0.x
sample r1.xyzw, r0.xyxx, T2[r1.x + 0].xyzw, S0[5]
add r0.xyzw, r0.xyzw, r1.xyzw
ftou r1.xyz, r0.xyzx
imul null, r1.xy, r1.xyxx, l(15, 3, 0, 0)
iadd r1.x, r1.y, r1.x
iadd r1.x, r1.z, r1.x
sample r1.xyzw, r0.xyxx, T1[r1.x + 10].xyzw, S0[5]
add o0.xyzw, r0.xyzw, r1.xyzw
ret
```

Each shader resource range now has an ID (a name) in the shader
bytecode. For example, tex1 texture array becomes 'T1' in the shader
byte code. Giving unique IDs to each resource range allows two things:

- Unambiguously identify which resource range (see
    dcl_resource_texture2d) is being indexed in an instruction (see
    sample instruction).

- Attach set of attributes to the declaration, e.g., element type,
    stride size, raster operation mode, etc.

Note that the ID of the range is *not* related to the HLSL lower bound
declaration.

The order of reflection resource bindings and shader declaration
instructions is the same to aid in identifying the correspondence
between HLSL variables and bytecode IDs.

Each declaration instruction in SM5.1 uses a 3D operand to define: range
ID, lower and upper bounds. An additional token is emitted to specify
the register space. Other tokens may be emitted as well to convey
additional properties of the range, e.g., cbuffer or structured buffer
declaration instruction emits the size of the cbuffer or structure. The
exact details of encoding can be found in d3d12TokenizedProgramFormat.h
and D3D10ShaderBinary::CShaderCodeParser.

SM5.1 instructions will not emit additional resource operand information
as part of the instruction (as in SM5.0). This information is now moved
to the declaration instructions. In SM5.0, instructions indexing
resources required resource attributes to be described in extended
opcode tokens, since indexing obfuscated the association to the
declaration. In SM5.1 each ID (such as 'T1') is unambiguously associated
with a single declaration that describes the required resource
information. Therefore, the extended opcode tokens used on instructions
to describe resource information are no longer emitted.

In non-declaration instructions, a resource operand for samplers, SRVs,
and UAVs is a 2D operand. The first index is a literal constant that
specifies the range ID. The second index represents the linearized value
of the index. The value is computed relative to the beginning of the
corresponding register space (*not* relative to the beginning of the
logical range) to better correlate with the root signature and to reduce
the driver compiler burden of adjusting the index.

A resource operand for CBVs is a 3D operand: literal ID of the range,
index of the cbuffer, offset into the particular instance of cbuffer.

# HLSL Root Signature Language

A root signature can be specified in HLSL as a string. The string
contains a collection of comma-separated clauses that describe root
signature constituent components, similarly to how it is done in C++
APIs. Here is an example:

```C++
#define MyRS1 "RootFlags( ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT | " \
            "DENY_VERTEX_SHADER_ROOT_ACCESS), " \
            "CBV(b0, space = 1, flags = DATA_STATIC), " \
            "SRV(t0), " \
            "UAV(u0), " \
            "DescriptorTable( CBV(b1), " \
                             "SRV(t1, numDescriptors = 8, " \
                               " flags = DESCRIPTORS_VOLATILE), " \
                             "UAV(u1, numDescriptors = unbounded, " \
                            " flags = DESCRIPTORS_VOLATILE)), " \
            "DescriptorTable(Sampler(s0, space=1, numDescriptors = 4)), " \
            "RootConstants(num32BitConstants=3, b10), " \
            "StaticSampler(s1)," \
            "StaticSampler(s2, " \
                              "addressU = TEXTURE_ADDRESS_CLAMP, " \
                            "filter = FILTER_MIN_MAG_MIP_LINEAR )"
```

There are two mechanisms to compile an HLSL root signature. First, it is
possible to attach a root signature string to a particular shader via
the RootSignature attribute:

```C++
[RootSignature(MyRS1)]

float4 main(float4 coord : COORD) : SV_Target
{
    ...
}
```

The compiler will create and verify the root signature blob for the
shader and embed it alongside the shader byte code into the shader blob.

The compiler supports root signature syntax for shader model 5.0 and
higher. If a root signature is embedded in a shader model 5.0 shader and
that shader is sent to the D3D11 runtime (which doesn't know about root
signatures), as opposed to D3D12, the root signature portion will get
silently ignored by D3D11.

The other mechanism is to create a standalone root signature blob,
perhaps to reuse it with a large set of shaders, saving space. The
compiler supports a ***rootsig_1_0*** and (with newer HLSL compilers)
***rootsig_1_1*** shader models. The name of the define string is
specified via the usual /E argument, e.g.,

`fxc.exe /T rootsig_1_1 MyRS1.hlsl /E MyRS1 /Fo MyRS1.fxo`

Note that the root signature string define can also be passed on the
command line, e.g, `/D MyRS1="..."`.

## Version Management

When compiling root signatures attached to shaders (the first mechanism
described above), newer HLSL compilers will default to compiling the
root signature at version 1.1, whereas old HLSL compilers only support
1.0. Note that 1.1 root signatures will not work on OS's that don't
support root signature 1.1. The root signature version compiled with a
shader can be forced to a particular version using /force_rootsig_ver
\<version\>. Forcing the version will succeed if the compiler can
preserve the behavior of the root signature being compiled at the forced
version, for example by dropping unsupported flags in the root signature
that serve only for optimization purposes but do not affect behavior.

This way an application can, for instance, compile a 1.1 root signature
to both 1.0 and 1.1 when building the application and select the
appropriate version at runtime depending on the level of OS support. It
would be most space efficient, however, for an application to compile
root signatures individually (particularly if multiple versions are
needed), separately from shaders. Even if shaders aren't initially
compiled with a root signature attached, the benefit of compiler
validation of root signature compatibility with a shader can be
preserved by using the /verifyrootsignature compiler option. Later at
runtime, PSOs can be created using shaders that don't have root
signatures in them while passing the desired root signature (perhaps the
appropriate version supported by the OS) as a separate parameter.

## Language Structure

The HLSL root signature language closely corresponds to the C++ root
signature APIs and has equivalent expressive power. The root signature
is specified as a sequence of clauses, separated by comma. The order of
clauses is important, as the order of parsing determines the slot
position in the root signature. Each clause takes one or more named
parameters. The order of parameters is not important, however. The
detailed description of the clauses and their parameters follow:

## RootFlags

```C++
RootFlags(0) // default value -- no flags
RootFlags(ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT)
RootFlags(ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT | DENY_VERTEX_SHADER_ROOT_ACCESS)
```

The optional RootFlags clause takes either 0 (the default value to
indicate no flags), or one or several of predefined root flags values,
connected via the OR '|' operator. The allowed root flag values are:

- `ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT`
- `DENY_VERTEX_SHADER_ROOT_ACCESS`
- `DENY_HULL_SHADER_ROOT_ACCESS`
- `DENY_DOMAIN_SHADER_ROOT_ACCESS`
- `DENY_GEOMETRY_SHADER_ROOT_ACCESS`
- `DENY_PIXEL_SHADER_ROOT_ACCESS`
- `ALLOW_STREAM_OUTPUT`

## RootConstants

```C++
RootConstants(num32BitConstants=N, bReg [, space=0,
                visibility=SHADER_VISIBILITY_ALL ])
```

The RootConstants clause specifies root constants in the root signature.
Two mandatory parameters are: num32BitConstants and b-register Reg
(corresponding to BaseShaderRegister in C++ APIs) of the cbuffer. The
space (RegisterSpace in C++ APIs) and visibility (ShaderVisibility in
C++) parameters are optional, and the default values are specified
above.

## Visibility

Visibility is an optional parameter that can have the following values:

- `SHADER_VISIBILITY_ALL`
- `SHADER_VISIBILITY_VERTEX`
- `SHADER_VISIBILITY_HULL`
- `SHADER_VISIBILITY_DOMAIN`
- `SHADER_VISIBILITY_GEOMETRY`
- `SHADER_VISIBILITY_PIXEL`

The default value is `SHADER_VISIBILITY_ALL`.

## HLSL Root Descriptor Flags

- `DATA_VOLATILE`
- `DATA_STATIC_WHILE_SET_AT_EXECUTE`
- `DATA_STATIC`

## Root-level CBV

Version 1.0:

```C++
CBV(bReg [, space=0, visibility=SHADER_VISIBILITY_ALL ])
```

Version 1.1:

```C++
CBV(bReg [, space=0, visibility=SHADER_VISIBILITY_ALL
    flags=DATA_STATIC_WHILE_SET_AT_EXECUTE ])
```

The CBV (constant buffer view) clause specifies a root-level cbuffer
b-register Reg entry. Note that this is a scalar entry; it is not
possible to specify a range for the root level.

## Root-level SRV

Version 1.0:

```C++
SRV(tReg [, space=0, visibility=SHADER_VISIBILITY_ALL ])
```

Version 1.1:

```C++
SRV(tReg [, space=0, visibility=SHADER_VISIBILITY_ALL,
    flags=DATA_STATIC_WHILE_SET_AT_EXECUTE ])
```

The SRV (shader resource view) clause specifies a root-level SRV
t-register Reg entry. Note that this is a scalar entry; it is not
possible to specify a range for the root level.

## Root-level UAV

Version 1.0:

```C++
UAV(uReg [, space=0, visibility=SHADER_VISIBILITY_ALL ])
```

Version 1.1:

```C++
UAV(uReg [, space=0, visibility=SHADER_VISIBILITY_ALL,
    flags=DATA_VOLATILE ])
```

The UAV (unordered access view) clause specifies a root-level UAV
u-register Reg entry. Note that this is a scalar entry; it is not
possible to specify a range for the root level.

## Descriptor Table

```C++
DescriptorTable( DTClause1, [ DTClause2, ... DTClauseN,
    visibility=SHADER_VISIBILITY_ALL ] )
```

The DescriptorTable clause is itself a list of comma-separated
descriptor table clauses, as well as an optional visibility parameter.
The DescriptorTable clauses include CBV, SRV, UAV, and Sampler. Note
that their parameters differ from those of the root-level clauses.

### HLSL Descriptor Range Flags

- `DESCRIPTORS_VOLATILE`
- `DATA_VOLATILE`
- `DATA_STATIC_WHILE_SET_AT_EXECUTE`
- `DATA_STATIC`

### Descriptor Table CBV

Version 1.0:

```C++
CBV(bReg [, numDescriptors=1, space=0,
    offset=DESCRIPTOR_RANGE_OFFSET_APPEND ])
```

Version 1.1:

```C++
CBV(bReg [, numDescriptors=1, space=0,
    offset=DESCRIPTOR_RANGE_OFFSET_APPEND
    , flags=DATA_STATIC_WHILE_SET_AT_EXECUTE ])
```

The mandatory parameter bReg specifies the start Reg of the cbuffer
range. The numDescriptors parameter specifies the number of descriptors
in the contiguous cbuffer range; the default value being 1. The entry
declares a cbuffer range [Reg, Reg + numDescriptors - 1], when
numDescriptors is a number. If numDescriptors is equal to 'unbounded',
the range is [Reg, `UINT_MAX`]. The offset field represents the
OffsetInDescriptorsFromTableStart field in C++ APIs. The default value
is `DESCRIPTOR_RANGE_OFFSET_APPEND` that corresponds to the value of
`D3D12_DESCRIPTOR_RANGE_OFFSET_APPEND`.

### Descriptor Table SRV

Version 1.0:

```C++
SRV(tReg [, numDescriptors=1, space=0,
    offset=DESCRIPTOR_RANGE_OFFSET_APPEND ])
```

Version 1.1:

```C++
SRV(tReg [, numDescriptors=1, space=0,
    offset=DESCRIPTOR_RANGE_OFFSET_APPEND,
    flags=DATA_STATIC_WHILE_SET_AT_EXECUTE ])
```

This is similar to the descriptor table CBV entry, except the specified
range is for shader resource views.

### Descriptor Table UAV

Version 1.0:

```C++
UAV(uReg [, numDescriptors=1, space=0,
    offset=DESCRIPTOR_RANGE_OFFSET_APPEND ])
```

Version 1.1:

```C++
UAV(uReg [, numDescriptors=1, space=0,
    offset=DESCRIPTOR_RANGE_OFFSET_APPEND,
    flags=DATA_VOLATILE ])
```

This is similar to the descriptor table CBV entry, except the specified
range is for unordered access views.

### Descriptor Table Sampler

Version 1.0:

```C++
Sampler(sReg [, numDescriptors=1, space=0,
    offset=DESCRIPTOR_RANGE_OFFSET_APPEND ])
```

Version 1.1:

```C++
Sampler(sReg [, numDescriptors=1, space=0,
    offset=DESCRIPTOR_RANGE_OFFSET_APPEND,
    flags=0 ])
```

This is similar to the descriptor table CBV entry, except the specified
range is for shader samplers. Note that Samplers can't be mixed with
other types of descriptors in the same descriptor table (since they are
in a separate descriptor heap).

## Static Sampler

```C++
StaticSampler( sReg,
    [ filter = FILTER_ANISOTROPIC,
    addressU = TEXTURE_ADDRESS_WRAP,
    addressV = TEXTURE_ADDRESS_WRAP,
    addressW = TEXTURE_ADDRESS_WRAP,
    mipLODBias = 0.f,
    maxAnisotropy = 16,
    comparisonFunc = COMPARISON_LESS_EQUAL,
    borderColor = STATIC_BORDER_COLOR_OPAQUE_WHITE,
    minLOD = 0.f,
    maxLOD = 3.402823466e+38f,
    space = 0,
    visibility = SHADER_VISIBILITY_ALL ])
```

Static sampler represents C++ API `D3D12_STATIC_SAMPLER` structure. The
mandatory parameter for StaticSampler is a scalar, sampler s-register
Reg. Other parameters are optional with default values given above. Each
field accepts a set of predefined enums.

### Filter field

C++ API equivalent is the 'filter' field.

- `FILTER_MIN_MAG_MIP_POINT`
- `FILTER_MIN_MAG_POINT_MIP_LINEAR`
- `FILTER_MIN_POINT_MAG_LINEAR_MIP_POINT`
- `FILTER_MIN_POINT_MAG_MIP_LINEAR`
- `FILTER_MIN_LINEAR_MAG_MIP_POINT`
- `FILTER_MIN_LINEAR_MAG_POINT_MIP_LINEAR`
- `FILTER_MIN_MAG_LINEAR_MIP_POINT`
- `FILTER_MIN_MAG_MIP_LINEAR`
- `FILTER_ANISOTROPIC`
- `FILTER_COMPARISON_MIN_MAG_MIP_POINT`
- `FILTER_COMPARISON_MIN_MAG_POINT_MIP_LINEAR`
- `FILTER_COMPARISON_MIN_POINT_MAG_LINEAR_MIP_POINT`
- `FILTER_COMPARISON_MIN_POINT_MAG_MIP_LINEAR`
- `FILTER_COMPARISON_MIN_LINEAR_MAG_MIP_POINT`
- `FILTER_COMPARISON_MIN_LINEAR_MAG_POINT_MIP_LINEAR`
- `FILTER_COMPARISON_MIN_MAG_LINEAR_MIP_POINT`
- `FILTER_COMPARISON_MIN_MAG_MIP_LINEAR`
- `FILTER_COMPARISON_ANISOTROPIC`
- `FILTER_MINIMUM_MIN_MAG_MIP_POINT`
- `FILTER_MINIMUM_MIN_MAG_POINT_MIP_LINEAR`
- `FILTER_MINIMUM_MIN_POINT_MAG_LINEAR_MIP_POINT`
- `FILTER_MINIMUM_MIN_POINT_MAG_MIP_LINEAR`
- `FILTER_MINIMUM_MIN_LINEAR_MAG_MIP_POINT`
- `FILTER_MINIMUM_MIN_LINEAR_MAG_POINT_MIP_LINEAR`
- `FILTER_MINIMUM_MIN_MAG_LINEAR_MIP_POINT`
- `FILTER_MINIMUM_MIN_MAG_MIP_LINEAR`
- `FILTER_MINIMUM_ANISOTROPIC`
- `FILTER_MAXIMUM_MIN_MAG_MIP_POINT`
- `FILTER_MAXIMUM_MIN_MAG_POINT_MIP_LINEAR`
- `FILTER_MAXIMUM_MIN_POINT_MAG_LINEAR_MIP_POINT`
- `FILTER_MAXIMUM_MIN_POINT_MAG_MIP_LINEAR`
- `FILTER_MAXIMUM_MIN_LINEAR_MAG_MIP_POINT`
- `FILTER_MAXIMUM_MIN_LINEAR_MAG_POINT_MIP_LINEAR`
- `FILTER_MAXIMUM_MIN_MAG_LINEAR_MIP_POINT`
- `FILTER_MAXIMUM_MIN_MAG_MIP_LINEAR`
- `FILTER_MAXIMUM_ANISOTROPIC`

### AddressU, AddressV, AddressW field

C++ API equivalents are the 'AddressU', 'AddressV', and 'AddressW'
fields.

- `TEXTURE_ADDRESS_WRAP`
- `TEXTURE_ADDRESS_MIRROR`
- `TEXTURE_ADDRESS_CLAMP`
- `TEXTURE_ADDRESS_BORDER`
- `TEXTURE_ADDRESS_MIRROR_ONCE`

### ComparisonFunc field

C++ API equivalent is the 'comparisonFunc' field.

- `COMPARISON_NEVER`
- `COMPARISON_LESS`
- `COMPARISON_EQUAL`
- `COMPARISON_LESS_EQUAL`
- `COMPARISON_GREATER`
- `COMPARISON_NOT_EQUAL`
- `COMPARISON_GREATER_EQUAL`
- `COMPARISON_ALWAYS`

### BorderColor field

C++ API equivalent is the 'borderColor' field.

- `STATIC_BORDER_COLOR_TRANSPARENT_BLACK`
- `STATIC_BORDER_COLOR_OPAQUE_BLACK`
- `STATIC_BORDER_COLOR_OPAQUE_WHITE`
- `STATIC_BORDER_COLOR_OPAQUE_BLACK_UINT`
- `STATIC_BORDER_COLOR_OPAQUE_WHITE_UINT`

# API Example

The following example shows a snippet of HLSL declaration code, followed
by a root signature that is compatible, defined via C++ code. A way to
author root signatures directly in HLSL code will also be provided. That
would allow author-time verification that root signatures are compatible
with shader code as well as additional convenience.

## Example HLSL Declarations

HLSL programs do not need to know anything about root signatures. They
can assign bindings to the virtual "register" binding space, t# for
SRVs, u# for UAVs, b# for CBVs, s# for samplers, or rely on the
compiler to pick assignments (and query the resulting mappings using
shader reflection afterwards). The root signature maps descriptor
tables, root descriptors and root constants to this virtual register
space.

Below are some example declarations an HLSL shader might have. Observe
that there is no knowledge here about root signatures, descriptor tables
etc.

```C++
Texture2D foo[5] : register(t2);
Buffer bar : register(t7);
RWBuffer dataLog : register(u1);
Sampler samp[2] : register(s0);
Sampler aniso : register(s3);

struct Data
{
    UINT index;
    float4 color;
};

ConstantBuffer<Data> myData : register(b0);
Texture2D terrain[] : register(t8); // unbounded array
Texture2D misc[] : register(t0,space1); // another unbounded array,
// space1 avoids overlap with above t#

struct MoreData
{
    float4x4 xform;
};

ConstantBuffer<MoreData> myMoreData : register(b1);

struct Stuff
{
    float2 factor;
    UINT drawID;
};

ConstantBuffer<Stuff> myStuff[][3][8] : register(b2, space3)
```

## Example C++ Code for Defining a Root Signature

The example below makes the following root signature compatible with the
above HLSL code. Note that it defines more than the above shader uses,
which is fine (another shader could use different parts). If most parts
of the root signature get used most of the time it can be better than
having to switch the root signature too frequently. Applications should
sort entries in the root signature from most frequently changing to
least. When an app changes the bindings to any part of the root
signature, the driver may have to make a copy of some or all of root
signature state, which can become a nontrivial cost when multiplied
across many state changes.

RootParameterIndex                | Contents
---|---
[0]                             | Root constants: { b2 } (1 CBV)
[1]                             | Descriptor table: { t2-t7, u0-u3} (6 SRVs + 4 UAVs)
[2]                             | Root CBV: { b0 } (1 CBV, static data)
[3]                             | Descriptor table: { s0-s1 } (2 Samplers)
[4]                             | Descriptor table: { t8 - unbounded } (unbounded # of SRVs, volatile descriptors)
[5]                             | Descriptor table: { (t0, space1) - unbounded } (unbounded # of SRVs, volatile descriptors)
[6]                             | Descriptor table: { b1 } (1 CBV, static data)

In addition, the root signature will define a static sampler that does
anisotropic texture filtering at shader register s3.

Helper structs `CD3DX12_DESCRIPTOR_RANGE1`, `CD3DX12_ROOT_PARAMETER1`,
`CD3DX12_STATIC_SAMPLER` and `CD3DX12_VERSIONED_ROOT_SIGNATURE_DESC`
are defined in d3dx12.h.

Once this root signature is bound, descriptor tables, root CBV and
constants can be assigned to the [0..6] parameter space. e.g.
descriptor tables (ranges in a descriptor heap) can be bound at each of
root parameters [1] and [3..6].

```C++
CD3DX12_DESCRIPTOR_RANGE1 DescRange[6];

DescRange[0].Init(D3D12_DESCRIPTOR_RANGE_SRV,6,2); // t2-t7
DescRange[1].Init(D3D12_DESCRIPTOR_RANGE_UAV,4,0); // u0-u3
DescRange[2].Init(D3D12_DESCRIPTOR_RANGE_SAMPLER,2,0); // s0-s1
DescRange[3].Init(D3D12_DESCRIPTOR_RANGE_SRV,-1,8, 0,
                  D3D12_DESCRIPTOR_RANGE_FLAG_DESCRIPTORS_VOLATILE); // t8-unbounded
DescRange[4].Init(D3D12_DESCRIPTOR_RANGE_SRV,-1,0,1,
                D3D12_DESCRIPTOR_RANGE_FLAG_DESCRIPTORS_VOLATILE);
                                                // (t0,space1)-unbounded
DescRange[5].Init(D3D12_DESCRIPTOR_RANGE_CBV,1,1,
                    D3D12_DESCRIPTOR_RANGE_FLAG_DATA_STATIC); // b1

CD3DX12_ROOT_PARAMETER1 RP[7];

RP[0].InitAsConstants(3,2); // 3 constants at b2
RP[1].InitAsDescriptorTable(2,&DescRange[0]); // 2 ranges t2-t7 and u0-u3
RP[2].InitAsConstantBufferView(0, 0,D3D12_ROOT_DESCRIPTOR_FLAG_DATA_STATIC); // b0
RP[3].InitAsDescriptorTable(1,&DescRange[2]); // s0-s1
RP[4].InitAsDescriptorTable(1,&DescRange[3]); // t8-unbounded
RP[5].InitAsDescriptorTable(1,&DescRange[4]); // (t0,space1)-unbounded
RP[6].InitAsDescriptorTable(1,&DescRange[5]); // b1

CD3DX12_STATIC_SAMPLER StaticSamplers[1];
StaticSamplers[0].Init(3, D3D12_FILTER_ANISOTROPIC); // s3
CD3DX12_VERSIONED_ROOT_SIGNATURE_DESC RootSig(7,RP,1,StaticSamplers);
ID3DBlob* pSerializedRootSig;
CheckHR(D3D12SerializeVersionedRootSignature(&RootSig,pSerializedRootSig));

ID3D12RootSignature* pRootSignature;
CheckHR(pDevice->CreateRootSignature(
    pSerializedRootSig->GetBufferPointer(),pSerializedRootSig->GetBufferSize(),
    __uuidof(ID3D12RootSignature),
    &pRootSignature));
```

## Using a Root Signature in a Command List

The following illustrates how the above root signature might be used on
a command list.

```C++
InitializeMyDescriptorHeapContentsAheadOfTime(); // for simplicity of the
                                                    // example

CreatePipelineStatesAhreadOfTime(pRootSignature); // The root signature is passed into
                                                    // shader / pipeline state creation

...

ID3D12DescriptorHeap* pHeaps[2] = {pCommonHeap, pSamplerHeap};

pCommandList->SetDescriptorHeaps(pHeaps,2);
pCommandList->SetGraphicsRootSignature(pRootSignature);
pCommandList->SetGraphicsRootDescriptorTable(
    6,heapOffsetForMoreData,DescRange[5].NumDescriptors);
pCommandList->SetGraphicsRootDescriptorTable(5,heapOffsetForMisc,5000);
pCommandList->SetGraphicsRootDescriptorTable(4,heapOffsetForTerrain,20000);
pCommandList->SetGraphicsRootDescriptorTable(
    3,heapOffsetForSamplers,DescRange[2].NumDescriptors);
pCommandList->SetComputeRootConstantBufferView(2,pDynamicCBHeap,&CBVDesc);

MY_PER_DRAW_STUFF stuff;

InitMyPerDrawStuff(&stuff);

pCommandList->SetSetGraphicsRoot32BitConstants(
    0,&stuff,0,RTSlot[0].Constants.Num32BitValues);

SetMyRTVAndOtherMiscBindings();

for(UINT i = 0; i < numObjects; i++)
{
    pCommandList->SetPipelineState(PSO[i]);
    pCommandList->SetGraphicsRootDescriptorTable(
    1,heapOffsetForFooAndBar[i],DescRange[1].NumDescriptors);
    pCommandList->SetGraphicsRoot32BitConstant(0,&i,1,drawIDOffset);
    SetMyIndexBuffers(i);
    pCommandList->DrawIndexedInstanced(...);
}
```

# DDI

## Capability Query DDIs

```C++
typedef enum D3D12DDICAPS_TYPE
{
    ...
    D3D12DDICAPS_D3D12_OPTIONS = 138,
} D3D12DDICAPS_TYPE;

typedef enum D3D12DDI_RESOURCE_BINDING_TIER
{
    D3D12DDI_RESOURCE_BINDING_TIER_1 = 1,
    D3D12DDI_RESOURCE_BINDING_TIER_2 = 2,
    D3D12DDI_RESOURCE_BINDING_TIER_3 = 3,
} D3D12DDI_RESOURCE_BINDING_TIER;
// D3D12DDICAPS_D3D12_OPTIONS

typedef struct D3D12DDI_D3D12_OPTIONS_DATA
{
    D3D12DDI_RESOURCE_BINDING_TIER ResourceBindingTier;
    // Add other D3D12 capability values as needed
} D3D12DDI_D3D12_OPTIONS_DATA;

// The above caps are queried via the GETCAPS DDI
```

The runtime enforces that applications don't exceed the capabilities of
the resource binding tier reported by the driver.

## DDI Descriptor Heaps

```C++
typedef enum D3D12DDI_DESCRIPTOR_HEAP_TYPE
{
    D3D12DDI_CBV_SRV_UAV_DESCRIPTOR_HEAP,
    D3D12DDI_SAMPLER_DESCRIPTOR_HEAP,
    D3D12DDI_RTV_DESCRIPTOR_HEAP,
    D3D12DDI_DSV_DESCRIPTOR_HEAP,
    D3D12DDI_NUM_DESCRIPTOR_HEAP_TYPES
} D3D12DDI_DESCRIPTOR_HEAP_TYPE;

typedef enum D3D12DDI_DESCRIPTOR_HEAP_FLAGS
{
    D3D12DDI_DESCRIPTOR_HEAP_SHADER_VISIBLE = 0x1,
} D3D12DDI_DESCRIPTOR_HEAP_FLAGS;

typedef struct D3D12DDIARG_CREATE_DESCRIPTOR_HEAP_0001
{
    D3D12DDI_DESCRIPTOR_HEAP_TYPE Type;
    UINT NumDescriptors;
    UINT Flags;
    UINT NodeMask;
} D3D12DDIARG_CREATE_DESCRIPTOR_HEAP_0001;

D3D12DDI_H( D3D12DDI_HDESCRIPTORHEAP )

typedef SIZE_T ( APIENTRY*
    PFND3D12DDI_CALC_PRIVATE_DESCRIPTOR_HEAP_SIZE_0001 )(
        D3D12DDI_HDEVICE, _In_ CONST
        D3D12DDIARG_CREATE_DESCRIPTOR_HEAP_0001* );

// Heap creation DDIs are free threaded, so if for a particular heap type
// the driver needs to suballocate out of a hardware heap, the driver
// needs to take a critical section (only around the part of the codepath
// that needs it, not the entire DDI), or implement a lock-free heap
// allocator.

typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATE_DESCRIPTOR_HEAP_0001) (
    D3D12DDI_HDEVICE, _In_ CONST
    D3D12DDIARG_CREATE_DESCRIPTOR_HEAP_0001*,
    D3D12DDI_HDESCRIPTORHEAP );

typedef VOID ( APIENTRY* PFND3D12DDI_DESTROY_DESCRIPTOR_HEAP ) (
    D3D12DDI_HDEVICE, D3D12DDI_HDESCRIPTORHEAP );
```

`D3D12DDI_*_DESCRIPTOR_HANDLE` identifies a specific descriptor in a descriptor heap.

The driver should ideally define `D3D12DDI_CPU_DESCRIPTOR_HANDLE` as a
CPU address to a location in a descriptor heap. Obviously this only
applies to descriptor heaps that are CPU visible.

The driver should ideally define `D3D12DDI_GPU_DESCRIPTOR_HANDLE` as a
GPU address to a location in a descriptor heap.

All descriptor heaps regardless of memory pool must be GPU visible (e.g.
the driver must allocate GPU VA for all for all descriptor heaps).

The reason the preceding sentences say "should ideally" instead of
"must" is to allow for situations where a given implementation has no
choice but to do some sort of descriptor shadowing that doesn't
perfectly match the model. In that event, the driver must still honor
the semantics that the application is expecting -- that CPU handles can
always be used for immediate CPU descriptor heap manipulation and GPU
handles can always be used to reference descriptor heap locations on
command list methods.

```C++
typedef struct D3D12DDI_CPU_DESCRIPTOR_HANDLE
{
    SIZE_T ptr;
} D3D12DDI_CPU_DESCRIPTOR_HANDLE;

typedef struct D3D12DDI_GPU_DESCRIPTOR_HANDLE
{
    UINT64 ptr;
} D3D12DDI_GPU_DESCRIPTOR_HANDLE;
```

GetDescriptorSizeInBytes allows the applicaition/runtime to discover the
descriptor sizes for each descriptor heap type. This lets applications
efficiently identify locations in a descriptor heap by manually
offsetting handles (starting from the handle to the beginning of a heap
obtained via another DDI further below). Applications must not manually
dereference the addresses, otherwise behavior is undefined -- actual
manipulation/use of descriptor heap memory must always go through
API/DDIs taking handles. To avoid apps inadvertently dereferencing the
pointers directly (or avoid the appearance that dereferencing is safe),
the runtime may do a cheap scale/shift on the handles passed from the
application to the driver as addresses. So at the API the application
sees a descriptor increment, which isn't described in terms of a
specific byte size, even though at the DDI descriptor sizes are
expressed in bytes.

```C++
typedef UINT ( APIENTRY* PFND3D12DDI_GET_DESCRIPTOR_SIZE_IN_BYTES) (
    D3D12DDI_HDEVICE,
    D3D12DDI_DESCRIPTOR_HEAP_TYPE );
```

The below methods retrieve a handle to the start of a descriptor heap.
Applications can manually generate handles to locations within the
descriptor heap by offsetting a handle to the start location by
multiples of the descriptor size. This way APIs and DDIs that manipulate
descriptor heap contents can pass these addresses directly to the driver
in high frequency call paths without requiring any translation.

```C++
typedef D3D12DDI_CPU_DESCRIPTOR_HANDLE ( APIENTRY* PFND3D12DDI_GET_CPU_DESCRIPTOR_HANDLE_FOR_HEAP_START ) (
    D3D12DDI_HDEVICE, D3D12DDI_HDESCRIPTORHEAP);

typedef D3D12DDI_GPU_DESCRIPTOR_HANDLE ( APIENTRY* PFND3D12DDI_GET_GPU_DESCRIPTOR_HANDLE_FOR_HEAP_START) (
    D3D12DDI_HDEVICE, D3D12DDI_HDESCRIPTORHEAP);
```

If an allocation is not CPU visible, there is no CPU address, so
GetCPUDescriptorHandleForHeapStart must return 0 for the handle. All
descriptor heaps are GPU visible so there must always be a non-NULL GPU
address to return.

## DDI Setting Descriptor Heaps

Note that this call replaces all previously set descriptor heaps (even
if it doesn't set any or all of them). So for example if
NumDescriptorHeaps is 0, that would be unbinding all descriptor heaps.
The runtime validates that at most one of any given shader visible
descriptor heap type can be set.

```C++
typedef VOID ( APIENTRY* PFND3D12DDI_SET_DESCRIPTOR_HEAPS_0003 )(
    D3D12DDI_HCOMMANDLIST,
    D3D12DDI_HDESCRIPTORHEAP* pDescriptorHeaps,
    UINT NumDescriptorHeaps );
```

## DDI Creating Descriptors

All methods for generating descriptors are free threaded.

Note that there is no "destroy" for a descriptor -- any external
allocations a descriptor may refer to in the driver/hardware (such as a
texture) already have a separate object owning its lifetime.

### DDI Shader Resource View

```C++
typedef enum D3D12DDI_SHADER_COMPONENT_MAPPING
{
    D3D12DDI_SHADER_COMPONENT_FROM_MEMORY_COMPONENT_0 = 0,
    D3D12DDI_SHADER_COMPONENT_FROM_MEMORY_COMPONENT_1 = 1,
    D3D12DDI_SHADER_COMPONENT_FROM_MEMORY_COMPONENT_2 = 2,
    D3D12DDI_SHADER_COMPONENT_FROM_MEMORY_COMPONENT_3 = 3,
    D3D12DDI_SHADER_COMPONENT_FORCE_VALUE_0 = 4,
    D3D12DDI_SHADER_COMPONENT_FORCE_VALUE_1 = 5,
    D3D12DDI_SHADER_COMPONENT_MAPPING_MAX_VALID = 6 // ;internal
} D3D12DDI_SHADER_COMPONENT_MAPPING;

#define D3D12DDI_SHADER_COMPONENT_MAPPING_MASK 0x7
#define D3D12DDI_SHADER_COMPONENT_MAPPING_SHIFT 3

#define D3D12DDI_SHADER_COMPONENT_MAPPING_ALWAYS_SET_BIT_AVOIDING_ZEROMEM_MISTAKES
    (1<<(D3D12DDI_SHADER_COMPONENT_MAPPING_SHIFT*4))

#define D3D12DDI_ENCODE_SHADER_4_COMPONENT_MAPPING(Src0,Src1,Src2,Src3)
    ((((Src0)&D3D12DDI_SHADER_COMPONENT_MAPPING_MASK)| \
    (((Src1)&D3D12DDI_SHADER_COMPONENT_MAPPING_MASK)<<D3D12DDI_SHADER_COMPONENT_MAPPING_SHIFT)| \
    (((Src2)&D3D12DDI_SHADER_COMPONENT_MAPPING_MASK)<<(D3D12DDI_SHADER_COMPONENT_MAPPING_SHIFT*2))| \
    (((Src3)&D3D12DDI_SHADER_COMPONENT_MAPPING_MASK)<<(D3D12DDI_SHADER_COMPONENT_MAPPING_SHIFT*3))| \
    D3D12DDI_SHADER_COMPONENT_MAPPING_ALWAYS_SET_BIT_AVOIDING_ZEROMEM_MISTAKES)

#define D3D12DDI_DECODE_SHADER_4_COMPONENT_MAPPING(ComponentToExtract,Mapping)
    ((D3D12DDI_SHADER_COMPONENT_MAPPING)(Mapping >>
    (D3D12DDI_SHADER_COMPONENT_MAPPING_SHIFT*ComponentToExtract) &
    D3D12DDI_SHADER_COMPONENT_MAPPING_MASK))

#define D3D12DDI_DEFAULT_SHADER_4_COMPONENT_MAPPING
    D3D12DDI_ENCODE_SHADER_4_COMPONENT_MAPPING(0,1,2,3)

typedef enum D3D12DDI_BUFFER_SRV_FLAG
{
    D3D12_DDI_BUFFER_SRV_FLAG_RAW = 0x00000001,
} D3D12DDI_BUFFER_SRV_FLAG;

typedef struct D3D12DDIARG_BUFFER_SHADER_RESOURCE_VIEW
{
    UINT FirstElement;
    UINT NumElements;
    UINT StructureByteStride; // if nonzero, format must be
    DXGI_FORMAT_UNKNOWN
    UINT Flags; // D3D12DDI_BUFFER_SRV_FLAG
} D3D12DDIARG_BUFFER_SHADER_RESOURCE_VIEW;

typedef struct D3D12DDIARG_TEX1D_SHADER_RESOURCE_VIEW
{
    UINT MostDetailedMip;
    UINT FirstArraySlice;
    UINT MipLevels;
    UINT ArraySize;
    FLOAT ResourceMinLODClamp;
} D3D12DDIARG_TEX1D_SHADER_RESOURCE_VIEW;

typedef struct D3D12DDIARG_TEX2D_SHADER_RESOURCE_VIEW_0002
{
    UINT MostDetailedMip;
    UINT FirstArraySlice;
    UINT MipLevels;
    UINT ArraySize;
    UINT PlaneSlice;
    FLOAT ResourceMinLODClamp;
} D3D12DDIARG_TEX2D_SHADER_RESOURCE_VIEW_0002;

typedef struct D3D12DDIARG_TEX3D_SHADER_RESOURCE_VIEW
{
    UINT MostDetailedMip;
    UINT MipLevels;
    FLOAT ResourceMinLODClamp;
} D3D12DDIARG_TEX3D_SHADER_RESOURCE_VIEW;

typedef struct D3D12DDIARG_TEXCUBE_SHADER_RESOURCE_VIEW
{
    UINT MostDetailedMip;
    UINT MipLevels;
    UINT First2DArrayFace;
    FLOAT ResourceMinLODClamp;
} D3D12DDIARG_TEXCUBE_SHADER_RESOURCE_VIEW;

typedef enum D3D12DDI_RESOURCE_TYPE
{
    D3D12DDI_RESOURCE_BUFFER = 1,
    D3D12DDI_RESOURCE_TEXTURE1D = 2,
    D3D12DDI_RESOURCE_TEXTURE2D = 3,
    D3D12DDI_RESOURCE_TEXTURE3D = 4,
    D3D12DDI_RESOURCE_TEXTURECUBE = 5,
} D3D12DDI_RESOURCE_TYPE;

typedef struct D3D12DDIARG_CREATE_SHADER_RESOURCE_VIEW_0002
{
    D3D12DDI_HRESOURCE hDrvResource;
    DXGI_FORMAT Format;
    D3D12DDI_RESOURCE_DIMENSION ResourceDimension;
    UINT Shader4ComponentMapping;
    union
    {
        D3D12DDIARG_BUFFER_SHADER_RESOURCE_VIEW Buffer;
        D3D12DDIARG_TEX1D_SHADER_RESOURCE_VIEW Tex1D;
        D3D12DDIARG_TEX2D_SHADER_RESOURCE_VIEW_0002 Tex2D;
        D3D12DDIARG_TEX3D_SHADER_RESOURCE_VIEW Tex3D;
        D3D12DDIARG_TEXCUBE_SHADER_RESOURCE_VIEW TexCube;
    };
} D3D12DDIARG_CREATESHADERRESOURCEVIEW_0002;

typedef VOID ( APIENTRY* PFND3D12DDI_CREATE_SHADER_RESOURCE_VIEW_0002 )(
    D3D12DDI_HDEVICE, _In_ CONST
    D3D12DDIARG_CREATE_SHADER_RESOURCE_VIEW_0002*,
    _In_ D3D12DDI_CPU_DESCRIPTOR_HANDLE DestDescriptor);
```

### DDI Constant Buffer View

```C++
typedef struct D3D12DDI_CONSTANT_BUFFER_VIEW_DESC
{
    D3D12DDI_GPU_VIRTUAL_ADDRESS BufferLocation;
    UINT SizeInBytes;
    UINT Padding;
} D3D12DDI_CONSTANT_BUFFER_VIEW_DESC;

typedef VOID ( APIENTRY* PFND3D12DDI_CREATE_CONSTANT_BUFFER_VIEW )(
    D3D12DDI_HDEVICE, _In_ CONST D3D12DDI_CREATE_CONSTANT_BUFFER_VIEW*,
    _In_ D3D12DDI_CPU_DESCRIPTOR_HANDLE DestDescriptor);
```

### DDI Sampler

```C++

typedef struct D3D12DDI_SAMPLER_DESC
{
    D3D12DDI_FILTER Filter;
    D3D12DDI_TEXTURE_ADDRESS_MODE AddressU;
    D3D12DDI_TEXTURE_ADDRESS_MODE AddressV;
    D3D12DDI_TEXTURE_ADDRESS_MODE AddressW;
    FLOAT MipLODBias;
    UINT MaxAnisotropy;
    D3D12DDI_COMPARISON_FUNC ComparisonFunc;
    FLOAT BorderColor[4]; // RGBA
    FLOAT MinLOD;
    FLOAT MaxLOD;
} D3D12DDI_SAMPLER_DESC;

typedef struct D3D12DDIARG_CREATE_SAMPLER
{
    CONST D3D12_DDI_SAMPLER_DESC* pSamplerDesc;
} D3D12DDIARG_CREATE_SAMPLER;

typedef VOID ( APIENTRY* PFND3D12DDI_CREATE_SAMPLER )(
    D3D12DDI_HDEVICE,
    _In_ CONST D3D12DDIARG_CREATE_SAMPLER*,
    _In_ D3D12DDI_CPU_DESCRIPTOR_HANDLE DestDescriptor);




typedef enum D3D12DDI_SAMPLER_FLAGS_0096
{
    D3D12DDI_SAMPLER_FLAG_NONE = 0x0,
    D3D12DDI_SAMPLER_FLAG_UINT_BORDER_COLOR = 0x01
} D3D12DDI_SAMPLER_FLAGS_0096;
DEFINE_ENUM_FLAG_OPERATORS(D3D12DDI_SAMPLER_FLAGS_0096);

typedef struct D3D12DDI_SAMPLER_DESC_0096
{
    D3D12DDI_FILTER Filter;
    D3D12DDI_TEXTURE_ADDRESS_MODE AddressU;
    D3D12DDI_TEXTURE_ADDRESS_MODE AddressV;
    D3D12DDI_TEXTURE_ADDRESS_MODE AddressW;
    FLOAT MipLODBias;
    UINT MaxAnisotropy;
    D3D12DDI_COMPARISON_FUNC ComparisonFunc;
    union
    {
        FLOAT FloatBorderColor[4]; // RGBA
        UINT  UintBorderColor[4];
    };
    FLOAT MinLOD;
    FLOAT MaxLOD;
    D3D12DDI_SAMPLER_FLAGS_0096 Flags;
} D3D12DDI_SAMPLER_DESC_0096;


typedef struct D3D12DDIARG_CREATE_SAMPLER_0096
{
    CONST D3D12DDI_SAMPLER_DESC_0096* pSamplerDesc;
} D3D12DDIARG_CREATE_SAMPLER_0096;

typedef VOID(APIENTRY* PFND3D12DDI_CREATE_SAMPLER_0096)(
    D3D12DDI_HDEVICE, 
    _In_ CONST D3D12DDIARG_CREATE_SAMPLER_0096*, 
    _In_ D3D12DDI_CPU_DESCRIPTOR_HANDLE DestDescriptor);

```

### DDI Unordered Access View

```C++
typedef enum D3D12DDI_BUFFER_UAV_FLAG
{
    D3D12DDI_BUFFER_UAV_FLAG_RAW     = 0x00000001,
    D3D12DDI_BUFFER_UAV_FLAG_APPEND  = 0x00000002,
    D3D12DDI_BUFFER_UAV_FLAG_COUNTER = 0x00000004,
} D3D12DDI_BUFFER_UAV_FLAG;

typedef struct D3D12DDIARG_BUFFER_UNORDERED_ACCESS_VIEW
{
    D3D10DDI_HRESOURCE hDrvCounterResource;
    UINT64 FirstElement;
    UINT NumElements;
    UINT StructureByteStride; // if nonzero, format must be
    DXGI_FORMAT_UNKNOWN
    UINT64 CounterOffsetInBytes;
    UINT Flags; // Only D3D12DDI_BUFFER_UAV_FLAG_RAW is supported}
} D3D12DDIARG_BUFFER_UNORDERED_ACCESS_VIEW;

typedef struct D3D12DDIARG_TEX1D_UNORDERED_ACCESS_VIEW
{
    UINT MipSlice;
    UINT FirstArraySlice;
    UINT ArraySize;
} D3D12DDIARG_TEX1D_UNORDERED_ACCESS_VIEW;

typedef struct D3D12DDIARG_TEX2D_UNORDERED_ACCESS_VIEW_0002
{
    UINT MipSlice;
    UINT FirstArraySlice;
    UINT ArraySize;
    UINT PlaneSlice;
} D3D12DDIARG_TEX2D_UNORDERED_ACCESS_VIEW_0002;

typedef struct D3D12DDIARG_TEX3D_UNORDERED_ACCESS_VIEW
{
    UINT MipSlice;
    UINT FirstW;
    UINT WSize;
} D3D12DDIARG_TEX3D_UNORDERED_ACCESS_VIEW;

typedef struct D3D12DDIARG_CREATE_UNORDERED_ACCESS_VIEW_0002
{
    D3D12DDI_HRESOURCE hDrvResource;
    DXGI_FORMAT Format;
    D3D12DDI_RESOURCE_DIMENSION ResourceDimension; // Runtime will never set
                                                    // this to TexCube
    union
    {
        D3D12DDIARG_BUFFER_UNORDERED_ACCESS_VIEW Buffer;
        D3D12DDIARG_TEX1D_UNORDERED_ACCESS_VIEW Tex1D;
        D3D12DDIARG_TEX2D_UNORDERED_ACCESS_VIEW_0002 Tex2D;
        D3D12DDIARG_TEX3D_UNORDERED_ACCESS_VIEW Tex3D;
    };
} D3D12DDIARG_CREATE_UNORDERED_ACCESS_VIEW_0002;

typedef VOID ( APIENTRY*
    PFND3D12DDI_CREATE_UNORDERED_ACCESS_VIEW_0002 )(
    D3D12DDI_HDEVICE, _In_ CONST
    D3D12DDIARG_CREATE_UNORDERED_ACCESS_VIEW_0002*,
    _In_ D3D12DDI_CPU_DESCRIPTOR_HANDLE DestDescriptor);
```

### DDI Render Target View

```C++
typedef struct D3D12DDIARG_BUFFER_RENDER_TARGET_VIEW
{
    UINT FirstElement;
    UINT NumElements;
} D3D12DDIARG_BUFFER_RENDER_TARGET_VIEW;

typedef struct D3D12DDIARG_TEX1D_RENDER_TARGET_VIEW
{
    UINT MipSlice;
    UINT FirstArraySlice;
    UINT ArraySize;
} D3D12DDIARG_TEX1D_RENDER_TARGET_VIEW;

typedef struct D3D12DDIARG_TEX2D_RENDER_TARGET_VIEW_0002
{
    UINT MipSlice;
    UINT FirstArraySlice;
    UINT ArraySize;
    UINT PlaneSlice;
} D3D12DDIARG_TEX2D_RENDER_TARGET_VIEW_0002;

typedef struct D3D12DDIARG_TEX3D_RENDER_TARGET_VIEW
{
    UINT MipSlice;
    UINT FirstW;
    UINT WSize;
} D3D12DDIARG_TEX3D_RENDER_TARGET_VIEW;

typedef struct D3D12DDIARG_TEXCUBE_RENDER_TARGET_VIEW
{
    UINT MipSlice;
    UINT FirstArraySlice;
    UINT ArraySize;
} D3D12DDIARG_TEXCUBE_RENDER_TARGET_VIEW;

typedef struct D3D12DDIARG_CREATE_RENDER_TARGET_VIEW_0002
{
    D3D12DDI_HRESOURCE hDrvResource;
    DXGI_FORMAT Format;
    D3D12DDI_RESOURCE_DIMENSION ResourceDimension;
    union
    {
        D3D12DDIARG_BUFFER_RENDER_TARGET_VIEW Buffer;
        D3D12DDIARG_TEX1D_RENDER_TARGET_VIEW Tex1D;
        D3D12DDIARG_TEX2D_RENDER_TARGET_VIEW_0002 Tex2D;
        D3D12DDIARG_TEX3D_RENDER_TARGET_VIEW Tex3D;
        D3D12DDIARG_TEXCUBE_RENDER_TARGET_VIEW TexCube;
    };
} D3D12DDIARG_CREATE_RENDER_TARGET_VIEW_0002;

typedef VOID ( APIENTRY* PFND3D12DDI_CREATE_RENDER_TARGET_VIEW_0002 )(
    D3D10DDI_HDEVICE,
    _In_ CONST D3D10DDIARG_CREATE_RENDER_TARGET_VIEW_0002*,
    _In_ D3D12DDI_CPU_DESCRIPTOR_HANDLE DestDescriptor);
```

### DDI Depth Stencil View

```C++
typedef struct D3D12DDIARG_TEX1D_DEPTH_STENCIL_VIEW
{
    UINT MipSlice;
    UINT FirstArraySlice;
    UINT ArraySize;
} D3D12DDIARG_TEX1D_DEPTH_STENCIL_VIEW;

typedef struct D3D12DDIARG_TEX2D_DEPTH_STENCIL_VIEW
{
    UINT MipSlice;
    UINT FirstArraySlice;
    UINT ArraySize;
} D3D12DDIARG_TEX2D_DEPTH_STENCIL_VIEW;

typedef struct D3D12DDIARG_TEXCUBE_DEPTH_STENCIL_VIEW
{
    UINT MipSlice;
    UINT FirstArraySlice;
    UINT ArraySize;
} D3D12DDIARG_TEXCUBE_DEPTH_STENCIL_VIEW;

typedef enum D3D12_DDI_CREATE_DEPTH_STENCIL_VIEW_FLAG
{
    D3D12_DDI_CREATE_DSV_READ_ONLY_DEPTH = 0x01L,
    D3D12_DDI_CREATE_DSV_READ_ONLY_STENCIL = 0x02L,
    D3D12_DDI_CREATE_DSV_FLAG_MASK = 0x03L,
} D3D12_DDI_CREATE_DEPTH_STENCIL_VIEW_FLAG;

typedef struct D3D12DDIARG_CREATE_DEPTH_STENCIL_VIEW
{
    D3D12DDI_HRESOURCE hDrvResource;
    DXGI_FORMAT Format;
    D3D12DDI_RESOURCE_DIMENSION ResourceDimension;
    UINT Flags;
    union
    {
        D3D12DDIARG_TEX1D_DEPTH_STENCIL_VIEW Tex1D;
        D3D12DDIARG_TEX2D_DEPTH_STENCIL_VIEW Tex2D;
        D3D12DDIARG_TEXCUBE_DEPTH_STENCIL_VIEW TexCube;
    };
} D3D12DDIARG_CREATE_DEPTH_STENCIL_VIEW;

typedef VOID ( APIENTRY* PFND3D12DDI_CREATE_DEPTH_STENCIL_VIEW )(
    D3D12DDI_HDEVICE,
    _In_ CONST D3D12DDIARG_CREATE_DEPTH_STENCIL_VIEW*,
    _In_ D3D12DDI_CPU_DESCRIPTOR_HANDLE DestDescriptor);
```

## DDI Copying Descriptors

Parameters are directly passed through from API to DDI, other than that
the handle values may be minimally processed to avoid applications
inadvertently dereferencing handles directly (or making it appear that
it is safe).

Copies with source and destination overlapping are invalid and will
produce undefined results in overlapping regions.

```C++
typedef VOID ( APIENTRY* PFND3D12DDI_COPY_DESCRIPTORS_0003 )(
    D3D12DDI_HDEVICE,
    _In_ UINT NumDestDescriptorRanges,
    _In_reads_(NumDestDescriptorRanges)
    CONST D3D12DDI_CPU_DESCRIPTOR_HANDLE* pDestDescriptorRangeStarts,
    _In_reads_(NumDestDescriptorRanges) CONST UINT* pDestDescriptorRangeSizes,
    // NULL means all ranges 1  
    _In_reads_(NumSrcDescriptorRanges)
    CONST D3D12DDI_CPU_DESCRIPTOR_HANDLE* pSrcDescriptorRangeStarts,
    _In_reads_opt_(NumSrcDescriptorRanges)
    CONST UINT* pSrcDescriptorRangeSizes, // NULL means all ranges 1
    _In_ D3D12DDI_DESCRIPTOR_HEAP_TYPE DescriptorHeapsType);

typedef VOID ( APIENTRY* PFND3D12DDI_COPY_DESCRIPTORS_SIMPLE_0003)(
    D3D12DDI_HDEVICE,
    _In_ D3D12DDI_CPU_DESCRIPTOR_HANDLE DestDescriptorRangeStart,
    _In_ D3D12DDI_CPU_DESCRIPTOR_HANDLE SrcDescriptorRangeStart,
    _In_ UINT NumDescriptors,
    _In_ D3D12DDI_DESCRIPTOR_HEAP_TYPE DescriptorHeapsType);
```

## DDI Creating a Root Signature

See the API reference for the definition of the root signature data
structure. What comes through the DDI is a serialized version of the
data structure below (since there are nested pointers). The DDK will
include source code for deserializing the root signature data structure
to the following definition.

### DDI Descriptor Table Bind Types

```C++
typedef enum D3D12DDI_DESCRIPTOR_RANGE_TYPE
{
    D3D12DDI_DESCRIPTOR_RANGE_SRV,
    D3D12DDI_DESCRIPTOR_RANGE_UAV,
    D3D12DDI_DESCRIPTOR_RANGE_CBV,
    D3D12DDI_DESCRIPTOR_RANGE_SAMPLER
} D3D12DDI_DESCRIPTOR_RANGE_TYPE;
```

### DDI Descriptor Range Flags

The runtime will fill in defaults for these flags if the application
specified none. The defaults are documented with the API version of
these flags earlier.

```C++
typedef enum D3D12DDI_DESCRIPTOR_RANGE_FLAGS
{
D3D12DDI_DESCRIPTOR_RANGE_FLAG_0013_NONE = 0x0,
D3D12DDI_DESCRIPTOR_RANGE_FLAG_0013_DESCRIPTORS_VOLATILE = 0x1,
D3D12DDI_DESCRIPTOR_RANGE_FLAG_0013_DATA_VOLATILE = 0x2,
D3D12DDI_DESCRIPTOR_RANGE_FLAG_0013_DATA_STATIC_WHILE_SET_AT_EXECUTE = 0x4,
D3D12DDI_DESCRIPTOR_RANGE_FLAG_0013_DATA_STATIC = 0x8,
D3D12DDI_DESCRIPTOR_RANGE_FLAG_0052_DESCRIPTORS_STATIC_KEEPING_BUFFER_BOUNDS_CHECKS = 0x10000,
} D3D12DDI_DESCRIPTOR_RANGE_FLAGS;

DEFINE_ENUM_FLAG_OPERATORS( D3D12DDI_DESCRIPTOR_RANGE_FLAGS );
```

### DDI Descriptor Range

```C++
#define D3D12DDI_DESCRIPTOR_RANGE_OFFSET_APPEND -1

typedef struct D3D12DDI_DESCRIPTOR_RANGE_0013
{
    D3D12DDI_DESCRIPTOR_RANGE_TYPE RangeType;
    UINT NumDescriptors; // -1 means unbounded size.
    // Only the last entry in a table can have
    // unbounded size
    UINT BaseShaderRegister; // e.g. for SRVs, 3 maps to
    // t3 in shader bytecode
    UINT RegisterSpace; // Can usually be 0, but allows multiple descriptor
    // arrays of unknown size to not appear to overlap.
    // e.g. for SRVs, extending example above, 5 for
    // RegisterSpace maps to t[3][5] in shader bytecode
    D3D12DDI_DESCRIPTOR_RANGE_FLAGS Flags;
    UINT OffsetInDescriptorsFromTableStart;
    // Can be D3D12_DESCRIPTOR_RANGE_OFFSET_APPEND
} D3D12DDI_DESCRIPTOR_RANGE_0013;
```

### DDI Root Descriptor Table Layout

```C++
typedef struct D3D12DDI_ROOT_DESCRIPTOR_TABLE_0013
{
    UINT NumDescriptorRanges;
    CONST D3D12DDI_DESCRIPTOR_RANGE_0013* pDescriptorRanges;
} D3D12DDI_ROOT_DESCRIPTOR_TABLE_0013;
```

### DDI Root Constants

```C++
typedef struct D3D12DDI_ROOT_CONSTANTS
{
    UINT ShaderRegister;
    UINT RegisterSpace;
    UINT Num32BitValues; // How many constants will occupy this single
    // shader slot (appearing like a single constant
    // buffer).
    // All the values occupy a single root signature bind slot
} D3D12DDI_ROOT_CONSTANTS;
```

### DDI Root Descriptor Flags

The runtime will fill in defaults for these flags if the application
specified none. The defaults are documented with the API version of
these flags earlier.

```C++
typedef enum D3D12DDI_ROOT_DESCRIPTOR_FLAGS
{
    D3D12DDI_ROOT_DESCRIPTOR_FLAG_0013_NONE = 0x0,
    D3D12DDI_ROOT_DESCRIPTOR_FLAG_0013_DATA_VOLATILE = 0x2,
    D3D12DDI_ROOT_DESCRIPTOR_FLAG_0013_DATA_STATIC_WHILE_SET_AT_EXECUTE = 0x4,
    D3D12DDI_ROOT_DESCRIPTOR_FLAG_0013_DATA_STATIC = 0x8,
} D3D12DDI_ROOT_DESCRIPTOR_FLAGS;

DEFINE_ENUM_FLAG_OPERATORS( D3D12DDI_ROOT_DESCRIPTOR_FLAGS );
```

### DDI Root Descriptor

```C++
typedef struct D3D12DDI_ROOT_DESCRIPTOR_0013
{
    UINT ShaderRegister;
    UINT RegisterSpace;
    D3D12DDI_ROOT_DESCRIPTOR_FLAGS_0013 Flags;
} D3D12DDI_ROOT_DESCRIPTOR_0013;
```

### DDI Shader visibility

```C++
typedef enum D3D12DDI_SHADER_VISIBILITY
{
    D3D12DDI_SHADER_VISIBILITY_ALL = 0,
    D3D12DDI_SHADER_VISIBILITY_VERTEX = 1,
    D3D12DDI_SHADER_VISIBILITY_HULL = 2,
    D3D12DDI_SHADER_VISIBILITY_DOMAIN = 3,
    D3D12DDI_SHADER_VISIBILITY_GEOMETRY = 4,
    D3D12DDI_SHADER_VISIBILITY_PIXEL = 5
} D3D12DDI_SHADER_VISIBILITY;
```

### DDI Root Signature Definition

```C++
typedef enum D3D12DDI_ROOT_PARAMETER_TYPE
{
    D3D12DDI_ROOT_PARAMETER_DESCRIPTOR_TABLE,
    D3D12DDI_ROOT_PARAMETER_32BIT_CONSTANTS, // Root constants
    D3D12DDI_ROOT_PARAMETER_CBV, // Root descriptor
    D3D12DDI_ROOT_PARAMETER_SRV, // Root descriptor
    D3D12DDI_ROOT_PARAMETER_UAV // Root descriptor
} D3D12DDI_ROOT_PARAMETER_TYPE;

typedef struct D3D12DDI_ROOT_PARAMETER_0013
{
    D3D12DDI_ROOT_PARAMETER_TYPE ParameterType;
    union
    {
    D3D12DDI_ROOT_DESCRIPTOR_TABLE_0013 DescriptorTable;
    D3D12DDI_ROOT_CONSTANTS Constants;
    D3D12DDI_ROOT_DESCRIPTOR_0013 Descriptor;
    }
    D3D12DDI_SHADER_VISIBILITY ShaderVisibility;
} D3D12DDI_ROOT_PARAMETER_0013;

typedef enum D3D12DDI_ROOT_SIGNATURE_FLAGS
{
    D3D12DDI_ROOT_SIGNATURE_ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT = 0x1,
    D3D12DDI_ROOT_SIGNATURE_DENY_VERTEX_SHADER_ROOT_ACCESS = 0x2,
    D3D12DDI_ROOT_SIGNATURE_DENY_HULL_SHADER_ROOT_ACCESS = 0x4,
    D3D12DDI_ROOT_SIGNATURE_DENY_DOMAIN_SHADER_ROOT_ACCESS = 0x8,
    D3D12DDI_ROOT_SIGNATURE_DENY_GEOMETRY_SHADER_ROOT_ACCESS = 0x10,
    D3D12DDI_ROOT_SIGNATURE_DENY_PIXEL_SHADER_ROOT_ACCESS = 0x20,
    D3D12DDI_ROOT_SIGNATURE_ALLOW_STREAM_OUTPUT = 0x40,
} D3D12DDI_ROOT_SIGNATURE_FLAGS;

typedef enum D3D12DDI_STATIC_BORDER_COLOR
{
    D3D12DDI_STATIC_BORDER_COLOR_TRANSPARENT_BLACK, //0.0f,0.0f,0.0f,0.0f
    D3D12DDI_STATIC_BORDER_COLOR_OPAQUE_BLACK, // 0.0f,0.0f,0.0f,1.0f
    D3D12DDI_STATIC_BORDER_COLOR_OPAQUE_WHITE, // 1.0f,1.0f,1.0f,1.0f
    D3D12DDI_STATIC_BORDER_COLOR_OPAQUE_BLACK_UINT, // 0u,0u,0u,1u
    D3D12DDI_STATIC_BORDER_COLOR_OPAQUE_WHITE_UINT  // 1u,1u,1u,1u
} D3D12_DDI_STATIC_BORDER_COLOR;

typedef struct D3D12DDI_STATIC_SAMPLER
{
    D3D12_DDI_FILTER Filter;
    D3D12_DDI_TEXTURE_ADDRESS_MODE AddressU;
    D3D12_DDI_TEXTURE_ADDRESS_MODE AddressV;
    D3D12_DDI_TEXTURE_ADDRESS_MODE AddressW;
    FLOAT MipLODBias;
    UINT MaxAnisotropy;
    D3D12_DDI_COMPARISON_FUNC ComparisonFunc;
    D3D12DDI_STATIC_BORDER_COLOR BorderColor;
    FLOAT MinLOD;
    FLOAT MaxLOD;
    UINT ShaderRegister;
    UINT RegisterSpace;
    D3D12DDI_SHADER_VISIBILITY ShaderVisibility;
} D3D12DDI_STATIC_SAMPLER;

typedef struct D3D12DDI_ROOT_SIGNATURE_0013
{
    UINT NumParameters;
    CONST D3D12DDI_ROOT_PARAMETER* pRootParameters;
    UINT NumStaticSamplers;
    CONST D3D12DDI_STATIC_SAMPLER* pStaticSamplers;
    UINT Flags;
} D3D12DDI_ROOT_SIGNATURE_0013;
```

### Root Signature Creation DDI

The runtime upconverts version 1.0 root signatures to 1.1, so drivers
will only see root signatures at the latest version, 1.1.

```C++
D3D12DDI_H( D3D12DDIARG_HROOTSIGNATURE )

typedef struct D3D12DDIARG_CREATE_ROOT_SIGNATURE_0013
{
    D3D12DDI_ROOT_SIGNATURE_VERSION Version;
    // Pointer contents valid for lifetime of the root signature
    union
    {
        CONST D3D12DDI_ROOT_SIGNATURE_0013* pRootSignature_1_1;
    };
    UINT NodeMask;
} D3D12DDIARG_CREATE_ROOT_SIGNATURE_0013;

typedef SIZE_T ( APIENTRY*
    PFND3D12DDI_CALC_PRIVATE_ROOT_SIGNATURE_SIZE_0013 )(
    D3D12DDI_HDEVICE, _In_ CONST
    D3D12DDIARG_CREATE_ROOT_SIGNATURE_0013* );

typedef HRESULT ( APIENTRY* PFND3D12DDI_CREATE_ROOT_SIGNATURE_0013) (
    D3D12DDI_HDEVICE, _In_ CONST
    D3D12DDIARG_CREATE_ROOT_SIGNATURE_0013*,
    D3D12DDI_HROOTSIGNATURE );

typedef VOID ( APIENTRY* PFND3D12DDI_DESTROY_ROOT_SIGNATURE ) (
    D3D12DDI_HDEVICE, D3D12DDI_HROOTSIGNATURE );
```

## DDI Setting a Root Signature

See the API reference for details on the flags and inheritance behavior
between command lists and bundles.

Parameters are directly passed through from API to DDI. Same function
prototype repeated for compute and graphics entrypoints:

```C++
typedef VOID ( APIENTRY* PFND3D12DDI_SET_ROOT_SIGNATURE )(
    D3D12DDI_HCOMMANDLIST,
    _In_ D3D12DDI_HROOTSIGNATURE);
```

## DDI Setting Descriptor Tables in the Root Signature

Parameters are directly passed through from API to DDI. Same function
prototype repeated for compute and graphics entrypoints:

```C++
typedef VOID ( APIENTRY* PFND3D12DDI_SET_ROOT_DESCRIPTOR_TABLE )(
    D3D12DDI_HCOMMANDLIST,
    _In_ UINT RootParameterIndex,
    _In_ D3D12DDI_GPU_DESCRIPTOR_HANDLE BaseDescriptor);
```

## DDI Setting Constants in the Root Signature

Parameters are directly passed through from API to DDI. Same function
prototypes repeated for compute and graphics entrypoints:

```C++
// Single constant
typedef VOID ( APIENTRY* PFND3D12DDI_SET_ROOT_32BIT_CONSTANT )(
    D3D12DDI_HCOMMANDLIST,
    UINT RootParameterIndex,
    UINT SrcData,
    UINT DestOffsetIn32BitValues);

    // Group of constants
typedef VOID ( APIENTRY* PFND3D12DDI_SET_ROOT_32BIT_CONSTANTS_0003)(
    D3D12DDI_HCOMMANDLIST,
    UINT RootParameterIndex,
    UINT Num32BitValuesToSet,
    CONST void* pSrcData,
    UINT DestOffsetIn32BitValues);
```

## DDI Setting Descriptors in the Root Signature (Bypassing Descriptor Heap/Tables)

For the methods below, the API passes parameters directly through to the
DDI.

```C++
typedef VOID ( APIENTRY* PFND3D12DDI_SET_ROOT_BUFFER_VIEW )(
    D3D12DDI_HCOMMANDLIST,
    UINT RootParameterIndex,
    _In_ D3D12DDI_GPU_VIRTUAL_ADDRESS BufferLocation);

// The above signature is used for the following command list
// DDI methods for root CBV/SRV/UAVs:

PFND3D12DDI_SET_ROOT_BUFFER_VIEW pfnSetComputeRootConstantBufferView;
PFND3D12DDI_SET_ROOT_BUFFER_VIEW pfnSetGraphicsRootConstantBufferView;
PFND3D12DDI_SET_ROOT_BUFFER_VIEW pfnSetComputeRootShaderResourceView;
PFND3D12DDI_SET_ROOT_BUFFER_VIEW pfnSetGraphicsRootShaderResourceView;
PFND3D12DDI_SET_ROOT_BUFFER_VIEW pfnSetComputeRootUnorderedAccessView;
PFND3D12DDI_SET_ROOT_BUFFER_VIEW pfnSetGraphicsRootUnorderedAccessView;
```

## DDI Setting IA/VB/SO/RT/DS Descriptors On A Command List / Bundle

These methods take transparent (app visible) descriptors, or for
RTV/DSV, CPU descriptors from descriptor heaps. All of these methods
record/snapshot the current descriptor contents, so after the methods
return, the application's descriptor heap contents (or application
memory in the case of transparent descriptor types) are free to be
edited by the app again. In other words the driver does not hold a
reference to the source data.

SO/RT/DS can only be set on Command Lists, not bundles (though they are
inherited into bundles).

These methods pass parameters directly through from API to DDI.

```C++
// Index Buffers
typedef struct D3D12DDI_INDEX_BUFFER_VIEW
{
    D3D12DDI_GPU_VIRTUAL_ADDRESS BufferLocation;
    UINT SizeInBytes;
    DXGI_FORMAT Format;
} D3D12DDI_INDEX_BUFFER_VIEW;

typedef VOID ( APIENTRY* PFND3D12DDI_SET_INDEX_BUFFER )(
    D3D12DDI_HCOMMANDLIST,
    _In_ CONST D3D12DDI_INDEX_BUFFER_VIEW* pDesc);

// Vertex Buffers
typedef struct D3D12DDI_VERTEX_BUFFER_VIEW
{
    D3D12DDI_GPU_VIRTUAL_ADDRESS BufferLocation;
    UINT SizeInBytes;
    UINT StrideInBytes;
} D3D12DDI_VERTEX_BUFFER_VIEW;

typedef VOID ( APIENTRY* PFND3D12DDI_SET_VERTEX_BUFFERS_0003 )(
    D3D12DDI_HCOMMANDLIST,
    _In_ UINT StartSlot,
    _In_ UINT NumViews,
    _In_reads_opt_(NumViews) CONST D3D12DDI_VERTEX_BUFFER_VIEW *
    pViews );

// Stream Output Buffers
typedef struct D3D12DDI_STREAM_OUTPUT_BUFFER_VIEW
{
    D3D12DDI_GPU_VIRTUAL_ADDRESS BufferLocation;
    UINT64 SizeInBytes;
    D3D12DDI_GPU_VIRTUAL_ADDRESS BufferFilledSizeLocation;
} D3D12DDI_STREAM_OUTPUT_BUFFER_VIEW;

typedef VOID ( APIENTRY* PFND3D12DDI_SO_SET_TARGETS_0003 )(
    D3D12DDI_HCOMMANDLIST,
    _In_ UINT StartSlot,
    _In_ UINT NumViews,
    _In_reads_opt_(NumViews) CONST
    D3D12DDI_STREAM_OUTPUT_BUFFER_VIEW* pViews);

// Render Targets (no single-use version of this DDI)
typedef VOID ( APIENTRY* PFND3D12DDI_SET_RENDER_TARGETS_0003 )(
    D3D12DDI_HCOMMANDLIST,
    _In_ UINT NumRenderTargetDescriptors,
    _In_ CONST D3D12DDI_CPU_DESCRIPTOR_HANDLE*
    pRenderTargetDescriptors,
    _In_ BOOL RTsSingleHandleToDescriptorRange,
    _In_opt_ CONST D3D12DDI_CPU_DESCRIPTOR_HANDLE*
    pDepthStencilDescriptor );
```

## DDI View Manipulation

Parameters are passed directly through from API to DDI.

```C++
typedef VOID ( APIENTRY* PFND3D12DDI_CLEAR_UNORDERED_ACCESS_VIEW_UINT_0003 )(
    D3D12DDI_HCOMMANDLIST,
    D3D12DDI_GPU_DESCRIPTOR_HANDLE ViewGPUHandleInCurrentHeap,
    D3D12DDI_CPU_DESCRIPTOR_HANDLE ViewCPUHandle,
    D3D12DDI_HRESOURCE hDrvResource,
    CONST UINT[4],
    UINT NumRects,
    _In_reads_opt_(NumRects) CONST D3D12DDI_RECT* pRects );

typedef VOID ( APIENTRY* PFND3D12DDI_CLEAR_UNORDERED_ACCESS_VIEW_FLOAT_0003 )(
    D3D12DDI_HCOMMANDLIST,
    D3D12DDI_GPU_DESCRIPTOR_HANDLE ViewGPUHandleInCurrentHeap,
    D3D12DDI_CPU_DESCRIPTOR_HANDLE ViewCPUHandle,
    D3D12DDI_HRESOURCE hDrvResource,
    CONST FLOAT[4],
    UINT NumRects,
    _In_reads_opt_(NumRects) CONST D3D12DDI_RECT* pRects );

typedef VOID ( APIENTRY* PFND3D12DDI_CLEAR_RENDER_TARGET_VIEW_0003)(
    D3D12DDI_HCOMMANDLIST,
    D3D12DDI_CPU_DESCRIPTOR_HANDLE ViewCPUHandle,
    CONST FLOAT[4],
    UINT NumRects,
    _In_reads_opt_(NumRects) CONST D3D12DDI_RECT* pRects );

typedef VOID ( APIENTRY* PFND3D12DDI_CLEAR_DEPTH_STENCIL_VIEW_0003)(
    D3D12DDI_HCOMMANDLIST,
    D3D12DDI_CPU_DESCRIPTOR_HANDLE ViewCPUHandle;
    UINT, FLOAT, UINT8,
    UINT NumRects,
    _In_reads_opt_(NumRects) CONST D3D12DDI_RECT* pRects );

typedef struct D3D12DDIARG_DISCARD_RESOURCE_0003
{
    UINT NumRects;
    CONST _In_reads_(NumRects) D3D12DDI_RECT *pRects;
    UINT FirstSubresource;
    UINT NumSubresources;
} D3D12DDIARG_DISCARD_RESOURCE_0003;

typedef VOID ( APIENTRY* PFND3D12DDI_DISCARD_RESOURCE_0003 )(
D3D12DDI_HCOMMANDLIST,
D3D12DDI_HRESOURCE hDrvResource,
_In_opt_ CONST D3D12DDI_DISCARD_RESOURCE_0003* );
```

## DDI Clearing root arguments

```C++
typedef VOID ( APIENTRY* PFND3D12DDI_CLEAR_ROOT_ARGUMENTS)(D3D12DDI_HCOMMANDLIST);
```

This DDI zero-initializes root arguments. The purpose is to ensure that
applications cannot leak root arguments (root constants, root views,
descriptor tables) from 1 command list to the next. The runtime calls
this DDI when creating a new command list, during
ID3D12CommandList::Reset, and during ID3D12CommandList::ClearState. Note
that there are separate DDI calls to clear other command list state
(vertex buffers, render targets, PSO, etc). Also note that this DDI
should apply the same operation regardless of the currently set root
signature.

# Change History

v1.22 Feb 4, 2025
- For constant buffers that can map to root constants, the spec disallowed
    array struct members or arrays of constant buffers.  Changed to allow
    these, as long as indexing into the arrays is static/literal so the 
    driver compiler can resolve each access directly to which root constant
    needs to be accessed (given the underlying storage isn't guaranteed to
    be contiguous and linearly indexable).  The HLSL compiler or 
    root signature validation never enforced the old rule that arrays could 
    not be used, so that rule ended up being meaningless given apps already
    doing this.

V1.21 Mar 11, 2022
- Updated [Limitations on Static Samplers](#limitations-on-static-samplers); removing the mention
of border color being restricted to 2 bits, and adding new integer border colors to the list.
- Added declarations and DDIs for 
  - D3D12_SAMPLER_DESC2
  - D3D12_SAMPLER_FLAGS
  - CreateSampler2
  - D3D12DDI_SAMPLER_DESC_0096
  - D3D12DDI_SAMPLER_FLAGS_0096
  - D3D12DDI_SAMPLER_FLAGS_0096
  - D3D12DDIARG_CREATE_SAMPLER_0096
  - PFND3D12DDI_CREATE_SAMPLER_0096

V1.20 Feb 3, 2022

- Added MSAA UAVs, supported if WriteableMSAATexturesSupported cap is TRUE.
  e.g. D3D12_UAV_DIMENSION_TEXTURE2DMS and D3D12_UAV_DIMENSION_TEXTURE2DMSARRAY

V1.19 April 10, 2019

- Markdown bugfix
- GPU descriptor handle is UINT64 not SIZE_T

V1.18 March 26, 2019

- Ported spec to markdown format.

V1.17 April 13, 2018

- Added DESCRIPTORS_STATIC_KEEPINB_BUFFER_BOUNDS_CHECKS flag.

V1.16 June 9, 2017

- Corrected inaccuracy in "Using Constants Directly In The Root
    Arguments". A sentence mentioned that root constnats are dynamically
    indexable, corrected to say they are statically indexable. Other
    sections in the spec already pointed out that indexing in the root
    constants is disallowed, so this clears up a contradiction.

V1.15 April 16, 2017

- Added to Using Descriptors Directly In Root Arguments section:

    Descriptors in root arguments do not support shader instructions
    that return status information (mapped/unmapped pages). The
    instruction will work fine overall except the mapped status return
    is undefined.

V1.1 March 16, 2016

- Added Root Signature Version 1.1 at the end of the API chapter. This
    adds flags to the Root Signature for applications to tell drivers
    about timespans when descriptors in descriptor heaps will be static,
    as well as when data pointed to by descriptors will be static. This
    lets drivers make optimizations for their hardware (if applicable)
    based on knowing when descriptors and/or data aren't changing.
    Conditions like these are often true just naturally in an
    application's flow but were not visible to drivers (lost
    information) with Root Signature 1.0.

  - Updated the HLSL Root Signature Language section to include Root
        Signature 1.1 additions.

  - Updated the API Example section to include specifying some of
        the new flags. The example doesn't do anything beyond that, like
        attempting to show application flow around honoring the flags,
        as they don't affect behavior and are just promises about when
        data/descriptors will not change.

  - Updated the DDI section to show the new Root Signature creation
        DDIs. The runtime will always upconvert root signatures from the
        application to Version 1.1 at the DDI.

- Freshened some APIs and DDIs for the bind model that were slightly
    stale even with respect to original Windows 10 launch -- so no
    behavior changes here. Examples of these minor cleanups: Fixed
    API/DDI parameter ordering for various methods, adding NodeMask to a
    few methods, adding PlaneSlice parameter for various 2D views to
    handle planar surfaces.

V1.02 Sept 2, 2015

- Corrected statement in "Bundle Semantics" section to indicate that,
    while PSO state is not inherited into a bundle, it does get returned
    out of a bundle back to the calling command list. Previously the
    spec stated PSO state neither gets inherited into a bundle or gets
    returned out.

V1.01 August 17, 2015

- Changed the default value of the offset field (corresponding to
    OffsetInDescriptorsFromTableStart) to
    DESCRIPTOR_RANGE_OFFSET_APPEND. Added support for
    DESCRIPTOR_RANGE_OFFSET_APPEND to the root signature language.

V1.00 July 16, 2015

- Removed restriction on Tier 1 and Tier 2 that there could only be at
    most 5 descriptor tables with SRVs in them. The IHV that had this
    restriction can simply emulate additional descriptor table pointers
    using root constants as offsets into a descriptor heap. The runtime
    initially shipping with Windows 10 has this now unnecessary
    validation in place on root signatures, but an updated runtime
    removing it should be shipped within months.

V0.96 May 5, 2015

- Clarified NonUniformResourceIndex intrinsic usage in HLSL: The HLSL
    compiler assumes resource index expressions to be uniform, as this
    is the most typical usage case. If a resource index may be
    non-uniform (meaning varying anywhere within a draw or dispatch call
    -- instancing counts as varying), programmers must use the
    'NonUniformResourceIndex' intrinsic to convey this fact to the
    compiler; otherwise, the result is undefined.

- Clarified for Tier 3 resource binding what it means to say that
    descriptor heaps can be 1000000+ in size. The + indicates that the
    runtime allows applications to try creating descriptor heaps with
    more than 1000000 descriptors, leaving the driver to decide whether
    it can support the request or fail the call. There is no cap exposed
    indicating how large of a descriptor heap the hardware could support
    -- applications can just try what they want and fall back to 1000000
    if larger doesn't work.

V0.95 Apr 14, 2015

- Added "ClearRootArguments" DDI

V0.94 Apr 07, 2015

- Typo fixes in section 5.4

V0.93 Mar 25, 2015

- Removed helper functions D3D12_ structs

- Updates sample code snippets to use new CD3D12_ helper structs now
    defined in d3dx12.h

- Clarification for descriptor copying methods: Copies with source and
    destination overlapping are invalid and will produce undefined
    results in overlapping regions.

V0.92 Mar 20, 2015

- Adjusted SM5.1 HLSL disassembly syntax and example.

- Added mipLODBias, minLOD, and maxLOD static sampler fields to HLSL
    root signature language

- Tier 1 supports 8 UAVs if Feature Level is 11 and 64 if Feature
    Level is 11.1+

- Added "shader visible descriptor heap pitfalls" section warning
    about the limited amount of cpu visible vidmem on many systems (even
    high end ones)

V0.91 Jan 23, 2015

- Changed 'nonuniform' HLSL intrinsic to 'NonUniformResourceIndex'

- Fixed D3D12DDI_STATIC_SAMPLER struct which accidentally was
    missing fields like MinLOD. These were correctly listed in the API
    struct D3D12_STATIC_SAMPLER already.

- Reduced maximum number of static samplers from 2048 to 2032 to leave
    room for drivers that need to allocate some samplers internally.

- Fleshed out "NULL Descriptors" section a bit more.

- Fixed a bug in the example descriptor heap wrapper code (memory
    leak)

V0.9 Nov 21, 2014

- Added a new chapter on HLSL root signature language.

- Added description of the nonuniform(expression) hint for D3D12
    resource index expressions.

- Added description of the /enable_unbounded_descriptor_tables
    compiler switch.

- Added transparent descriptors for IBV,VBV,SOV and root SRV/UAV/CBV.
    These remove the need for having IBV/VBV/SOV descriptor heaps, since
    apps can generate these descriptors manually. For root SRV/UAV/CBV
    the descriptor is just a GPU VA pointer (no size or other
    decoration).

  - This matches the descriptors that ExecuteIndirect uses

  - The IBV descriptor is now the GPU VA + size + format

  - Index buffer strip cut behavior is now decoupled from the format
        in the IBV descriptor above.  It is now defined in a new field
        in the PipeleineState: IndexBufferProperties.

    - Options are:
        D3D12_INDEX_BUFFER_STRIP_CUT_VALUE_DISABLED,
        _STRIP_CUT_VALUE_0xFFFF and
          _STRIP_CUT_VALUE_0xFFFFFFFF

  - For root SRV/UAV, the buffer must be raw or structured only
        (structure stride comes from shader declaration). Root UAVs
        sacrifice the ability to have an automatic counter associated
        with them like full UAVs support.

  - For root CBV, the application must not index past
        4096\*4\*32-bits of data within the shader else behavior is
        undefined (some implementations may produce out of bounds
        behavior like normal descriptor heap based CBVs, while others
        will just read whatever address is requested).

  - For root SRV/UAV/CBV, behavior is undefined if the application
        reads past the end of the underlying allocation (now that there
        is no size as part of the root descriptor). Eventually there
        will be debug validation during shader execution that will be
        able to log errors on attempts to read out of bounds of the
        memory pointed to by root descriptors..

- Constant Buffer Views can still go in CBV_SRV_UAV descriptor
    heaps.  The definition of these CBVs is just a GPUVA pointer + size
    now (versus root CBV which is just a GPUVA).

- Root descriptors, being just a 64 bit pointer now, cost 2 DWORDs in
    the root signature (was 3 before with size).

- Static samplers supported in the root signature

- Component swizzle field added to SRV descriptors, like the
    TEXTURE_SWIZZLE_RGBA that is in OpenGL

- Added the ability for the system to add up to 64 DWORDs to any API
    created root signature (which itself can be 64 DWORDs in size). This
    enables instrumentation of shaders, such as in debugging scenarios,
    without any conflict with application usage. See "Additional Root
    Argument Capacity For System Instrumentation"

V0.8 Sept 22, 2014

- Updated description for constant buffer support in HLSL. SM5.1 uses
    old-style cbuffer and new ConstantBuffer constructs to represent
    constant buffers in HLSL.

- Renamed Root Table Layout to Root Signature. Root Table became Root
    Parameters (the fields in the signature) and Root Arguments (the
    values passed for the parameters at runtime).

- Removed the NumDescriptors parameter to Set*DescriptorTable. This
    is redundant now that there is a root signature that lists the size
    of descriptor tables. For low tier hardware that has limits for any
    given descriptor type on how many may be bound to the pipeline at a
    time across a root signature (e.g. constant buffers on Tier 1 and
    2), when an application sets a descriptor table pointing to an area
    in the heap, they must ensure that the entire descriptor table
    declaration size from the root signature has valid descriptors in
    the descriptor heap at command list execution time. For descriptor
    types that don't have bind count limits, the application only needs
    to initialize the descriptor heap with valid descriptors in the
    places where the shader will actually reference the heap during
    shader execution (which may not be all of a descriptor table --
    could be a sparse subset).

- Added flags (D3D11_ROOT_SIGNATURE_DENY_*_SHADER_ROOT_ACCESS)
    to the root signature definition letting applications limit
    arguments that have visibility across all shader stages from being
    visible to specific shader stages. On some hardware this can result
    in lower cost for setting arguments by only broadcasting them to
    stages that actually need them.

- Increased the shader visibible descriptor heap size for Tier 1 to
    1,000,000 (from 55000). This matches Tier 2 and Tier 3 (Tier 3 is
    1,000,000+). These numbers are slightly less than 2\^20 to give IHVs
    some room if they actually support 2\^20 for placing any hidden
    descriptors they might need for emulation / workarounds.

- Increased Root Signature size limit to 64 DWORDS from 16. Also
    decreased Root Signature cost from 4 DWORDS to 3. (This update was
    missing from the change long for this version that was given to
    IHVs.)

V 0.7 July 29 2014

- After some measurements done on various hardware there are a few of
    simplifications to the resource binding spec we implemented.  These
    are all just cuts from the existing spec that should simplify driver
    development noticeably without significant loss of effectiveness in
    the D3D12 API.  Should any of these cuts become a problem in the
    long run, we always have the option in the future of bringing back
    functionality when there is a proven need for it:

  - Remove Set*DescriptorTableStatic() APIs and corresponding DDIs
        (leaving the non-static versions only)

    - We had methods for setting descriptor tables with the
            application promising the contents of the descriptor heap
            were static.  This allowed the descriptor choice to be baked
            in the command list rather than dereferenced at command list
            execute for certain hardware.  For the hardware that
            intended to take advantage of this we did an experiment to
            reveal the value of a static mode.  From the experiment it
            turns out that there is no justification to have the static
            APIs.  For most IHVs cutting these Static() methods means
            nothing anyway since the "static" property would have just
            been ignored and the methods would behave like the
            non-static versions -- Set*DescriptorTable().

  - Require descriptor heaps to be CPU visible

    - The second experiment was to measure the performance
            difference on discrete GPU systems of descriptors living in
            L0 (sysmem) vs L1 (vidmem).  The result was that fetching
            descriptors over PCIe during shader execution did not
            produce any particularly significant penalties.  In extreme
            scenarios where different descriptors are being referenced
            by tiny triangles there tended to be a bit of a perf cliff
            that GPUs fell off regardless of whether the descriptors
            were in sysmem or vidmem.  Being in sysmem just made the
            cliff slightly worse but a cliff had already been fallen off
            anyway.  The upshot of this is that we are considering
            requiring all shader visible descriptor heaps to be CPU
            visible.  VidMM will try to place them in BAR when possible,
            but if it has to demote them to sysmem if somehow BAR is
            under pressure, this should not be catastrophic.

    - This change means applications no longer have to worry about
            how to differentiate between integrated and discrete memory
            GPU systems when managing descriptors on D3D12.

    - The following flag can be removed from
            D3D12_DESCRIPTOR_HEAP_FLAGS (and corresponding DDI)
            passed to CreateDescriptorHeap(), since descriptor heaps
            would always be CPU visible:

      - D3D12_DESCRIPTOR_HEAP_CPU_VISIBLE

    - Remove GPU timeline descriptor creation / copying

      - Because we can make descriptor heaps are all CPU visible we
            have less need for command list based methods for
            creating/copying UAV/SRV/CBV/Sampler descriptors.  The only
            potential value for command list descriptor copying would be
            as a convenience for an application.  However given the
            synchronization cost on a GPU to be able to reference
            descriptors after copying them on a command list, the real
            utility of GPU timeline descriptor updates is questionable.
            There was a NO_HAZARD option for descriptor copies, which
            allowed drivers to move copies to the beginning of a command
            list and mitigate intra-command list synchronization, but if
            applications will be submitting 10s to hundreds of command
            lists per frame it can be argued that the app should just
            stage all of its descriptors up front on the CPU before
            submission or use dynamic shader indexing.

      - Some implementations need to maintain CPU shadow copies of
            descriptors, so having methods for copying descriptors on
            the GPU becomes a nuisance since at command list execution
            CPU shadows need to be kept up to date.  This becomes more
            complicated when out of order GPU execution is considered
            (with multi-engine support).  It can be difficult for the
            CPU to determine the order that the GPU will execute a
            collection of command lists submitted on separate engines,
            and this would need to be resolved to be able to maintain
            CPU shadow copies of descriptor heap state.  By removing
            command list descriptor heap copying altogether, there is no
            longer a difficult task for drivers to be able to shadow
            descriptors.

      - Command list APIs that can be removed (along with
            corresponding DDIs):

            -   UpdateDescriptors()

            -   UpdateDescriptorsSimpleNoHazard()

            -   CreateConstantBufferViewNoHazard()

            -   CreateShaderResourceViewNoHazard()

            -   CreateUnorderedAccessViewNoHazard()

            -   CreateSamplerNoHazard()

- CopyDescriptors() and CopyDescriptorsImmediate() had the source and
    destination parameters in the wrong order (inconsistent with all
    other Copy APIs that list destination first). Fixed the parameter
    order

  - Also for the DDI, removed COPY_DESCRIPTORS_IMMEDATE and
        COPY_DESCRIPTORS_SIMPLE_IMMEDIATE and replaced them with
        COPY_DESCSRIPTORS and COPY_DESCRIPTORS_SIMPLE (without
        "immediate" in the name). No behavior change, just the
        "immediate" isn't needed now that there aren't command list copy
        methods conflicting any longer. Just like with the APIs, fixed
        the order of the src and dest parameters for these DDIs

- Note to IHVs preparing drivers -- the current DDIs in OS builds are
    unchanged from the bits matching the previous spec (v0.6 resource
    binding spec, v18 D3D12 bits). So COPY_DESCRIPTORS_IMMEDIATE
    above, for example, still gets called. This is to avoid breaking
    drivers for now until a point some time in the future when breaking
    changes across features will be collected together and done once.
    The APIs are at least fixed to reflect the changes above already
    (for any D3D12 release after July 29 2014).

- For "Levels of Hardware Support" (the Tier definitions):

  - Tier 1: Reduced the number of UAVs in descriptor tables across
      stages to 8 from 64

  - Tier 2: Reduced the number of UAVs in descriptor tables across
      stages from "full heap" to 64

  - Tier 2: Reduced max simultaneous descriptor tables containing
      SRVs from "no limit" to 5

  - All tiers: Removed "descriptors combinable in a descriptor
      table" row since it didn't have anything to distinguish across
      Tiers any more

V0.6 June 19 2014

- A bit more detail about HLSL from our compiler folks -- chapter 5

- Small tweaks to the feature Tiers (highlighting the most likely
    candidates for changes)

- A few wording clarifications and code tweaks to match the codebase

V0.55 June 13 2014

- Descriptor heaps are now split out per descriptor type, with the
    exception of CBV, SRV, UAV which all live in a shared descriptor
    heap (in which you can intermingle descriptors).

- Descriptor heaps can be created with visibility: CPU visible,
    GPU(Shader) visible or CPU + GPU(Shader) visible.

- Only CBV_SRV_UAV or Sampler descriptor heaps can be GPU visible
    since these are accessed by shaders at execution.

- Other descriptor heaps (RTV, DSV, IBV, VBV, SOV) are CPU only just
    for staging what you want to bind - the actual binding of these
    types works more like D3D11.

- A single descriptor table (a pointers into a descriptor heap) can
    point to a mix of CBV/SRV/UAVs.

- Locations in descriptor heaps are identified by handle.  If it is a
    CPU visible heap, you can get a CPU handle and increment the handle
    (after querying the increment amount) manually to produce handles
    anywhere in the heap.  If it is a GPU visible descriptor heap you
    can get a GPU handle for identifying heap locations on the command
    list (such as setting a descriptor table).

- Descriptor heap management can be done on the CPU timeline
    (immediate) for CPU visible descriptor heaps, and GPU timeline (on
    the command list) for GPU visible descriptor heaps. CPU+GPU visible
    descriptor heaps can therefore be updated on either timeline -
    whichever one you want.

- The root of your binding space is called the root table layout.  It
    is where you bind things on a command list that show up in your
    shader.  In the root table layout you can place any of the
    following: descriptor table pointers (cost 1 DWORD), inline
    descriptors (cost 4 DWORDs), constants (cost n DWORDs for n
    constants), with 16 DWORDs total.  You can change any subset of
    these as you issue draw commands.  If you only need to change a
    \"drawID\" you can just set a constant between draws.  The driver
    versions the root table layout for you.

- The configuration of the root table layout is completely up to you -
    defined by a \"root table layout\".  When you create pipeline state
    objects you have to specify a root table layout the driver can
    compile the shaders against (or you can embed a root table layout in
    shaders directly during authoring if you prefer).  When you are
    rendering, you set a root table layout on the command list in order
    to configure your current binding space where you bind the things
    your shader expects to see from the root table layout - descriptor
    tables, inline descriptors, constants.

- Shaders don\'t have to know about root table layouts, unless you
    want to put the layout definition in your shader for convenience /
    early validation.  The root table layout definition itself specifies
    how it will feed the entities declared in your shader like CBs,
    textures etc.  You want to share root table layouts across many
    pipeline state objects since changing the root table layout means
    you are resetting your \"binding space\".

- Reduced the number of hardware feature tiers to 3.  Still some
    refinement left to do, but the capability matrix is already far
    simplified.
