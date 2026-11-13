# Resource binding and root signatures

<a id="foundations"></a>

## Binding foundations

Descriptors are the primary unit of binding in D3D12.

A descriptor is a relatively small block of data that fully describes an
object to the GPU, in a GPU specific format that may be opaque or
visible to the application depending on the circumstance.

There are many different types of descriptors. Shader Resource Views
(SRVs), Unordered Access Views (UAVs) and Samplers are a few examples.

The size of a descriptor varies by hardware/driver and by object type.
There is no guaranteed upper bound.

> ![NOTE]
> In practice, descriptors that reside in GPU-visible memory have historically been <= 64 bytes, though this is not a hard requirement.

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
use at Draw/Dispatch time. Descriptor tables and heaps are defined below.

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

Unless otherwise specified, "root signature" means a global root signature,
whose arguments are set on the command list. [Raytracing pipelines](raytracing-pipelines.md)
and [work graphs](work-graphs.md) can use local root signatures.
See [Local and global root signatures](#local-signatures).

<a id="descriptor-tables"></a>

### Descriptor tables

A descriptor table is logically an array of descriptors. Each descriptor
table stores descriptors of one or more types - SRVs, UAVs, CBVs and
Samplers. The graphics and compute pipelines gain access to resources by
referencing into descriptor tables by index.

A descriptor table is actually just a subrange of a descriptor heap.
Descriptor heaps are described in detail later, but basically they
represent the underlying memory allocation for a collection of
descriptors. Since memory allocation is a property of creating a
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

Descriptor heaps are bound to command lists before descriptor tables are set.
Each table refers to a range in the currently bound heap of the matching type.
See [Binding changes](command-list-state.md#binding-changes) for how changing
heaps affects table bindings.

Descriptor tables also allow representing the fact that depending on the
hardware certain object types may only have a limited number visible to
the pipeline at a given time. This may be much smaller than the overall
descriptor heap size.

Before going into more specifics about descriptor table use, the next
section covers underlying storage for descriptor tables - descriptor
heaps - in detail.

<a id="descriptor-heaps"></a>

### Descriptor heaps

A descriptor heap from the API point of view is a contiguous allocation of descriptor storage for one descriptor heap type. Descriptor heaps
contain many object types that are not part of a Pipeline State, such as
SRVs, UAVs, Constant Buffer Views (CBVs), Samplers.

The primary point of a descriptor heap is to encompass the bulk of
memory allocation required for storing the descriptor specifications of
object types that shaders reference, for as large of a window of
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
heaps that are purely for staging purposes (non shader visible) whose sizes are not constrained by shader-visible heap limits, copying to descriptor heaps that are used for
rendering as necessary.

Levels of functionality in the hardware with respect to heap
configuration is grouped into Tiers of increasing generality, described
later.

Descriptor heaps that can be referenced by shaders through descriptor
tables come in a couple flavors:

One heap type, `D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV` can hold Shader
Resource Views, Unordered Access Views and Constant Buffer Views all
intermixed. So any given location in the heap can be any one of the
listed types of descriptors.

Another heap type, `D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER` only stores
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

The only purpose of descriptor heaps for descriptor types that are not
shader accessible, such as RTVs, is to identify descriptors that the
driver needs to copy/interpret during command list recording (e.g.
OMSetRenderTargets()) to define what the GPU will later reference during
execution. RTVs and DSVs get bound to the pipeline by having their
contents recorded into / interpreted by the command list directly,
rather than being pointed to via descriptor tables which reference the
descriptor heap at command list execution on the GPU. As soon as a bind
call, like OMSetRenderTargets() on the command list, returns back to the
app, the source (non shader visible) descriptor heap location is free to
be immediately changed by the application in preparation for the next
call. In other words the driver doesn't hold a reference to application
provided memory.

Non shader visible descriptor heaps are not constrained by shader-visible heap size limits. It is
perfectly reasonable for an application to create non shader visible
descriptor heaps of any size, tiny or huge, whatever is convenient for
how an application might wish to stage descriptors.

An application might even choose to use non shader visible descriptor
heaps to store descriptors that can be used in shaders --
SRV/UAV/CBV/Sampler. This might be convenient for having per-object
descriptor storage in a scene graph that is gathered from as needed at
command list record (rendering) time into a shader visible descriptor
heap.

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
via descriptor tables. As soon as a bind call, like IASetVertexBuffers()
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
once. `ExecuteIndirect` state effects are defined in [indirect execution](command-list-state.md#indirect).

<a id="descriptor-population"></a>

### Descriptor population and CPU access

Now back to discussing opaque descriptors that live in descriptor heaps:
fully general SRV / UAV / CBV and Samplers.

When an application has created a descriptor heap it can use methods on
the device to either generate descriptors directly into the heap or copy
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

<a id="null-descriptors"></a>

### Null descriptors

#### Creation and access compatibility

To create a null SRV or UAV descriptor, applications pass NULL for the resource pointer and provide a valid view description. The description must specify the view type, such as Texture2D or Texture1D. Numerical parameters, such as the number of mipmaps, must have values that could have been valid for a resource. [Acceleration structure SRVs](#acceleration-structure-srv) use a GPU address in the description rather than a resource pointer and have their own [null-address rule](#acceleration-structure-srvs).

A null description passed to `CreateConstantBufferView` creates a null CBV. This differs from passing a null description with a non-null resource to an [SRV or UAV creation method](#descriptor-creation), which requests a default view of that resource.

#### Shader access results

The shader access must be compatible with the null descriptor's type. The [array/non-array texture compatibility rules](#texture-view-dimension-compatibility) also apply to null SRVs and UAVs. For example, accessing a null Texture1D SRV as a Texture2D is undefined and could result in device reset. An uninitialized descriptor or an [out-of-bounds descriptor-table index](#table-indexing) is not a null descriptor.

The following table defines compatible accesses through null descriptors. TODO entries identify gaps in this manuscript, not undefined API behavior.

| Access | Result |
|---|---|
| Constant-buffer load through a null CBV | Zero |
| Load through a null SRV or UAV | Zero in all returned components, including components absent from the view format. [Missing component defaults](formats.md#missing-components) are not substituted |
| Non-comparison texture sampling or gathering through a null SRV | Zero in all returned components, including components absent from the view format. [Missing component defaults](formats.md#missing-components) are not substituted |
| Comparison texture sampling or gathering through a null SRV | Zero, rather than the result of comparing the reference value against a zero texel |
| Store through a null UAV | The write is discarded |
| Atomic operation through a null UAV | Writes are discarded, **TODO: return value contract not yet established** |
| UAV counter operation | A null UAV cannot have an associated counter resource, so operations requiring a counter cannot use a null UAV. See the [UAV creation contract](#id3d12device-createunorderedaccessview). |
| Texture dimension and mip-count queries through a null SRV or UAV | Zero for width, height, depth or array size, and mip count. Result conversions still apply: DXBC `resinfo_rcpFloat` produces infinity for dimensions whose reciprocal is requested. |
| Buffer dimension or structure-stride query through a null SRV or UAV | Zero for all returned fields |
| Multisample count or sample-position query through a null SRV | Zero |
| LOD query through a null SRV | Zero |

#### Root descriptor addresses

Except for acceleration structure SRVs (see below), [descriptors placed directly in the root arguments](#root-descriptors) behave differently. If the pointer value for one of these descriptors is
0 and the GPU dereferences it, behavior is undefined (including device
reset).

<a id="acceleration-structure-srvs"></a>

For acceleration structure SRVs, a root SRV address of `0` or a descriptor heap SRV whose `Location` is `0` represents a NULL acceleration structure and forces a miss. The resource parameter is always NULL when creating these SRVs and does not determine whether the acceleration structure is NULL. An unset root argument is uninitialized state, not a GPUVA of `0`.

A NULL acceleration structure binding (i.e. a NULL TLAS pointer) is distinct from an instance whose `AccelerationStructure` pointer is NULL (a null BLAS pointer), which is an inactive instance discarded at build time. See [Inactive primitives and instances](acceleration-structures.md#inactive-primitives-and-instances).

#### Vertex, index and stream output views

Vertex Buffer Views, Index Buffer Views and Stream Output Views are supplied directly to command-list methods rather than stored in descriptor heaps. A null view pointer clears the corresponding binding or binding range. For example, passing NULL for the view array to `IASetVertexBuffers` clears the specified vertex buffer slots.

| Access with no buffer view bound | Result |
|---|---|
| Input assembler vertex or index fetch | Zero for all expected components, without [missing component defaults](formats.md#missing-components). |
| Stream output to a slot selected by the stream output declaration | The slot is treated as a full buffer. Writes stop for the entire stream, including its other buffer slots, while shader execution and the stream's storage-needed count continue. Other streams are unaffected. |

Setting the view size to zero in an individual VBV, IBV, SOV or descriptor-heap CBV has the same access behavior as its null form. The buffer address is ignored and can be NULL. Stream output capacity and statistics follow the [overflow rules](geometry-shaders-and-stream-output.md#overflow-and-statistics).

<a id="root-signatures"></a>

## Root arguments and signatures

The *root arguments* are an application defined data structure used by
shaders to locate the resources they need access. These arguments
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
trade off placing more descriptor tables in the root arguments but less
room for root constants, or vice versa.

The contents of the root arguments (the descriptor tables, root
constants and root descriptors) that the application has bound
automatically get versioned by the hardware whenever any part of the
contents change between draw/dispatch calls. So each draw/dispatch gets
a unique full set of root argument state when any argument has changed.

One implication of this is that if the root arguments are large and an
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

The *root signature* is the definition of an arbitrarily arranged
collection of descriptor tables (including their layout), root constants
and root descriptors. Each entry has a cost towards a maximum limit, so
the application can trade off the balance between how many of each type
of entry the root signature will contain.

The root signature is an object that can be created by manual
specification at the API. All shaders in a pipeline state must be compatible with its selected root signature. The [pipeline-compatibility contract](#pipeline-compatibility) defines how a root signature is selected and validated against multiple possibilities, including explicit API parameters and embedded root signatures.

One property of the root signature is that shaders don't have to know
about it when authored, although root signatures can also be authored
directly in shaders if desired. Shader assets authored for D3D10 or D3D11 do not require
any changes to be compatible with root signatures.

<a id="recording-state"></a>

### Recording and bundle state

See [initial binding state](command-list-state.md#initial-bindings), [binding-change invalidation](command-list-state.md#binding-changes), and [bundle binding rules](command-list-state.md#bundle-bindings) for how bindings are set and inherited on command lists. Note that setting a pipeline state on a command list does not automatically apply that root signature. Root arguments are independently maintained for graphics and compute.

<a id="table-indexing"></a>

### Table indexing and descriptor lifetime

<!-- d3d12-review-alert:end:binding:N-common-resource-operation-boundary:0 -->

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

Shaders cannot dynamically index across descriptor table boundaries from
a given call-site in the shader. However the selection of a descriptor
*within* a descriptor table is allowed to be dynamically indexed in
shader code within ranges of the same descriptor type (such as indexing
across a contiguous region of SRVs).

Once command lists / bundles that set descriptor tables have been
submitted to a queue for execution, the application must not edit from
the CPU the portions of descriptor heaps that the GPU might reference
until the application knows the GPU has finished executing the
references.

Completion is established by the [submission and fence contracts](execution.md#submission).

If an application knows that only a subset of the region a descriptor
table points to will be accessed (say due to flow control in the
shader), the other unreferenced descriptors are still free to be
changed.

If an application needs to switch between different descriptor
references between rendering calls, there are a few approaches the
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

The preceding update freedom is subject to the stricter [static-descriptor and static-data promises](#static-promises) of root-signature versions 1.1 and 1.2. An unreferenced descriptor still has to adhere to any static promises that were made about it.

Out of bounds indexing of any descriptor table from the shader results
in a largely undefined memory access, including the possibility of
reading arbitrary in-process memory as if it is a hardware state
descriptor and living with the consequence of what the hardware does
with that. This could produce a device reset, but no worse (e.g. no blue
screen).

<a id="root-constants"></a>

### Root constants

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

Arrays in cbuffers, such as having entry "float myArray[2];" that
get mapped onto root constants can only be accessed using static/literal
indices into the array so the driver compiler can directly map each access
to a root constant, given the underlying root constant storage
may not be contiguous and linearly indexable.

A cbuffer that is mapped to root constants cannot itself be an array. So
it is invalid to map "cbuffer myCBArray[2]" into root constants.

<a id="root-descriptors"></a>

### Root descriptors

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

The buffer descriptors supported in the root arguments are CBVs
and SRV/UAVs of Buffer resources, where the SRV/UAV is either a raw or
structured buffer. [Acceleration-structure SRVs](#acceleration-structure-srv) are also supported. They use the acceleration structure's GPUVA directly, with no additional root-descriptor type indication. UAVs in the root cannot have counters associated with
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
inlined constants is not permitted, so indexing bar requires a static/literal index there.

Root CBV addresses must satisfy `D3D12_CONSTANT_BUFFER_DATA_PLACEMENT_ALIGNMENT` (256 bytes). Root buffer SRV/UAV addresses must be at least 4-byte aligned and also satisfy the requirements of the accesses performed. Acceleration structure SRVs retain their [acceleration structure address requirements](../Raytracing.md#additional-srv-type).

<a id="root-limits"></a>

### Root argument limits

The maximum size of the root arguments for a global root signature is 64 DWORDs. This maximum is
chosen to prevent abuse of the root arguments as a way of storing bulk
data. Each parameter in the root signature has a cost towards this 64
DWORD limit. These costs may not exactly match what any given hardware
has to do, but no matter what the tight limit minimizes the hardware
expense for supporting the root arguments. Descriptor tables cost 1
DWORD each.

Root constants cost 1 DWORD * NumConstants, by definition since they
are collections of 32-bit values.

Raw/Structured Buffer SRVs/UAVs and CBVs cost 2 DWORDs.

During debugging or other system instrumentation scenarios, the OS has
the option to add root arguments (of any type) past the API limit
imposed on the application, up to 128 DWORDs total (app + debug). These
extra arguments are used, for instance, in combination with patching
shaders for debug shader validation that can support applications that
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
0xffffffff. See [register spaces](#register-spaces) --
some of the range is for driver use and some for the OS.

This register space reservation leaves room for drivers and/or the OS to
do instrumentation on shaders (such as during debugging) easily by
adding bindings in the reserved register space range without any risk of
conflict with whatever binding locations the application's shader chose
to use for joining root arguments to shaders. The HLSL resources
declared in these reserved register spaces can be fed by the system
added root signature entries described above.

<a id="local-signatures"></a>

### Local and global root signatures

For [raytracing shaders](raytracing-pipelines.md) and [work graphs](work-graphs.md),
bindings can be defined by one or both of the following root signatures:

- A *local* root signature, whose arguments come from [shader tables](raytracing-pipelines.md#shader-tables) for raytracing shaders or the [node-local root arguments table](state-objects.md#d3d12_set_work_graph_desc) for work graphs, enabling each shader or node to have unique arguments.

- A *global* root signature whose arguments are shared across all
  raytracing shaders, work graphs and compute PSOs on CommandLists, set via
  `SetComputeRootSignature()`.

Raytracing shaders used together, or nodes within a work graph, can use different local root
signatures but must use the same global root signature. The "global"
root signature is identical to the root signature used for compute state on
command lists.

Different sets of shaders collected together in a [State object](state-objects.md#object-model),
may have different global root signatures, as long as during a [DispatchRays()](raytracing-pipelines.md#id3d12graphicscommandlist4dispatchrays)
call any shaders that get
invoked use the same global root signature that is set on the CommandList
as described above. The same requirement applies to nodes invoked by a
[DispatchGraph()](work-graphs.md#dispatchgraph) call.

Local root signatures are not subject to the global root signature's 64-DWORD limit.

For raytracing, the maximum local root argument footprint is 4064 bytes:
the maximum shader record stride of 4096 bytes minus the 32-byte shader
identifier. For work graphs, the maximum local root argument footprint is
4096 bytes. Both use the [local root argument layout](#local-root-argument-layout)
defined below. Table stride and base alignment requirements are defined
with [raytracing shader tables](raytracing-pipelines.md#shader-tables) and
[work-graph node-local argument tables](state-objects.md#d3d12_set_work_graph_desc).

The shader "register" bindings (e.g. t0, u0 etc.) specified by a local
root signature can't overlap with those in a global root signature for a
given shader.

Note about static samplers: Local root signatures can define static
samplers (just like global root signatures can), except that each local
root signature used in a raytracing pipeline or work-graph [state object](state-objects.md#object-model)
must define any static samplers it uses identically as other local root
signatures that define the same ones. So if any local root signature makes
a definition for, say, sampler s0, all local root signatures that define
s0 must use the same definition. Further, the total number of unique
static samplers across local root signature and global root signature
must fit in the static sampler limit for D3D12's resource binding model.

[State object associations](state-objects.md#subobject-association-behavior) determine which root signature subobjects apply to each export. [Node-local table selection](state-objects.md#d3d12_set_work_graph_desc) defines the work graph selection interface.

<a id="local-root-argument-layout"></a>

#### Local root argument layout

Raytracing shader records and work graph node-local argument tables use the same local root argument layout. Arguments are packed in the order declared in the local root signature, with padding as needed to align each argument:

| Argument | Size | Alignment |
|---|---|---|
| Root constants | 4 bytes per DWORD | 4 bytes |
| Root descriptor | 8 bytes | 8 bytes |
| Descriptor table GPU handle | 8 bytes | 8 bytes |

The footprint includes this padding.

> In the global root signature cost function, a descriptor table is
> considered to be one DWORD (4 bytes), despite the API handle type being
> an 8 byte value. For hardware that is constrained in their root argument
> space, they are able to compress this value by diffing it against the
> currently-bound root descriptor table to produce a 32-bit offset. Note
> that for a local root signature, the full 64-bit value should be placed
> in the shader table, which makes the local root signature size calculation
> different than the global root signature cost function.

<a id="raytracing-shader-visibility"></a>
<a id="raytracing-and-work-graph-shader-visibility"></a>

### Raytracing and work graph shader visibility

Root signatures used with raytracing and work graphs share command list state with
compute, as described in [Local and global root signatures](#local-signatures). As such,
the only root parameter shader visibility that applies is
`D3D12_SHADER_VISIBILITY_ALL`, meaning the root arguments set as part
of compute command list state are also visible to raytracing shaders and work graph node shaders.

Local root signatures can also only use `D3D12_SHADER_VISIBILITY_ALL`.

In other words, for both root signatures and local root signatures,
there's nothing interesting to narrow down with shader visibility flags
-- local root arguments are visible to the associated raytracing shader or
work graph node, without filtering by shader visibility flags.

<a id="signature-descriptions"></a>

## Root signature descriptions

`D3D12_VERSIONED_ROOT_SIGNATURE_DESC.Version` selects `Desc_1_0`, `Desc_1_1`, or `Desc_1_2`. Version 1.1 adds descriptor/data promise flags. Version 1.2 retains them and uses `D3D12_STATIC_SAMPLER_DESC1` for sampler flags. Array counts select the corresponding parameter, descriptor range, and static sampler arrays.

<a id="d3d-root-signature-version"></a>

```cpp
typedef enum D3D_ROOT_SIGNATURE_VERSION
{
    D3D_ROOT_SIGNATURE_VERSION_1 = 0x1,
    D3D_ROOT_SIGNATURE_VERSION_1_0 = 0x1,
    D3D_ROOT_SIGNATURE_VERSION_1_1 = 0x2,
    D3D_ROOT_SIGNATURE_VERSION_1_2 = 0x3,
} D3D_ROOT_SIGNATURE_VERSION;
```

```cpp
typedef struct D3D12_FEATURE_DATA_ROOT_SIGNATURE
{
    D3D_ROOT_SIGNATURE_VERSION HighestVersion;
} D3D12_FEATURE_DATA_ROOT_SIGNATURE;
```

`D3D12_FEATURE_ROOT_SIGNATURE` uses `D3D12_FEATURE_DATA_ROOT_SIGNATURE.HighestVersion`: its input is the highest version understood by the caller and its output is the highest supported version not exceeding that input.

```cpp
typedef enum D3D12_DESCRIPTOR_RANGE_TYPE
{
    D3D12_DESCRIPTOR_RANGE_TYPE_SRV,
    D3D12_DESCRIPTOR_RANGE_TYPE_UAV,
    D3D12_DESCRIPTOR_RANGE_TYPE_CBV,
    D3D12_DESCRIPTOR_RANGE_TYPE_SAMPLER
} D3D12_DESCRIPTOR_RANGE_TYPE;
```

```cpp
typedef struct D3D12_DESCRIPTOR_RANGE
{
    D3D12_DESCRIPTOR_RANGE_TYPE RangeType;
    UINT NumDescriptors;
    UINT BaseShaderRegister;
    UINT RegisterSpace;
    UINT OffsetInDescriptorsFromTableStart;
} D3D12_DESCRIPTOR_RANGE;
```

```cpp
typedef struct D3D12_ROOT_DESCRIPTOR_TABLE
{
    UINT NumDescriptorRanges;
    const D3D12_DESCRIPTOR_RANGE* pDescriptorRanges;
} D3D12_ROOT_DESCRIPTOR_TABLE;
```

```cpp
typedef struct D3D12_ROOT_CONSTANTS
{
    UINT ShaderRegister;
    UINT RegisterSpace;
    UINT Num32BitValues;
} D3D12_ROOT_CONSTANTS;
```

```cpp
typedef struct D3D12_ROOT_DESCRIPTOR
{
    UINT ShaderRegister;
    UINT RegisterSpace;
} D3D12_ROOT_DESCRIPTOR;
```

```cpp
typedef enum D3D12_ROOT_PARAMETER_TYPE
{
    D3D12_ROOT_PARAMETER_TYPE_DESCRIPTOR_TABLE,
    D3D12_ROOT_PARAMETER_TYPE_32BIT_CONSTANTS,
    D3D12_ROOT_PARAMETER_TYPE_CBV,
    D3D12_ROOT_PARAMETER_TYPE_SRV,
    D3D12_ROOT_PARAMETER_TYPE_UAV
} D3D12_ROOT_PARAMETER_TYPE;
```

```cpp
typedef enum D3D12_SHADER_VISIBILITY
{
    D3D12_SHADER_VISIBILITY_ALL = 0,
    D3D12_SHADER_VISIBILITY_VERTEX = 1,
    D3D12_SHADER_VISIBILITY_HULL = 2,
    D3D12_SHADER_VISIBILITY_DOMAIN = 3,
    D3D12_SHADER_VISIBILITY_GEOMETRY = 4,
    D3D12_SHADER_VISIBILITY_PIXEL = 5,
    D3D12_SHADER_VISIBILITY_AMPLIFICATION = 6,
    D3D12_SHADER_VISIBILITY_MESH = 7,
} D3D12_SHADER_VISIBILITY;
```

```cpp
typedef struct D3D12_ROOT_PARAMETER
{
    D3D12_ROOT_PARAMETER_TYPE ParameterType;
    union
    {
        D3D12_ROOT_DESCRIPTOR_TABLE    DescriptorTable;
        D3D12_ROOT_CONSTANTS           Constants;
        D3D12_ROOT_DESCRIPTOR          Descriptor;
    };
    D3D12_SHADER_VISIBILITY ShaderVisibility;
} D3D12_ROOT_PARAMETER;
```

```cpp
typedef enum D3D12_ROOT_SIGNATURE_FLAGS
{
    D3D12_ROOT_SIGNATURE_FLAG_NONE                                  = 0x0,
    D3D12_ROOT_SIGNATURE_FLAG_ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT    = 0x1,
    D3D12_ROOT_SIGNATURE_FLAG_DENY_VERTEX_SHADER_ROOT_ACCESS        = 0x2,
    D3D12_ROOT_SIGNATURE_FLAG_DENY_HULL_SHADER_ROOT_ACCESS          = 0x4,
    D3D12_ROOT_SIGNATURE_FLAG_DENY_DOMAIN_SHADER_ROOT_ACCESS        = 0x8,
    D3D12_ROOT_SIGNATURE_FLAG_DENY_GEOMETRY_SHADER_ROOT_ACCESS      = 0x10,
    D3D12_ROOT_SIGNATURE_FLAG_DENY_PIXEL_SHADER_ROOT_ACCESS         = 0x20,
    D3D12_ROOT_SIGNATURE_FLAG_ALLOW_STREAM_OUTPUT                   = 0x40,
    D3D12_ROOT_SIGNATURE_FLAG_LOCAL_ROOT_SIGNATURE                  = 0x80,
    D3D12_ROOT_SIGNATURE_FLAG_DENY_AMPLIFICATION_SHADER_ROOT_ACCESS = 0x100,
    D3D12_ROOT_SIGNATURE_FLAG_DENY_MESH_SHADER_ROOT_ACCESS          = 0x200,
    D3D12_ROOT_SIGNATURE_FLAG_CBV_SRV_UAV_HEAP_DIRECTLY_INDEXED     = 0x400,
    D3D12_ROOT_SIGNATURE_FLAG_SAMPLER_HEAP_DIRECTLY_INDEXED         = 0x800,
} D3D12_ROOT_SIGNATURE_FLAGS;
```

```cpp
typedef struct D3D12_DESCRIPTOR_RANGE1
{
    D3D12_DESCRIPTOR_RANGE_TYPE RangeType;
    UINT NumDescriptors;
    UINT BaseShaderRegister;
    UINT RegisterSpace;
    D3D12_DESCRIPTOR_RANGE_FLAGS Flags;
    UINT OffsetInDescriptorsFromTableStart;
} D3D12_DESCRIPTOR_RANGE1;
```

```cpp
typedef struct D3D12_ROOT_DESCRIPTOR_TABLE1
{
    UINT NumDescriptorRanges;
    const D3D12_DESCRIPTOR_RANGE1* pDescriptorRanges;
} D3D12_ROOT_DESCRIPTOR_TABLE1;
```

```cpp
typedef struct D3D12_ROOT_DESCRIPTOR1
{
    UINT ShaderRegister;
    UINT RegisterSpace;
    D3D12_ROOT_DESCRIPTOR_FLAGS Flags;
} D3D12_ROOT_DESCRIPTOR1;
```

```cpp
typedef struct D3D12_ROOT_PARAMETER1
{
    D3D12_ROOT_PARAMETER_TYPE ParameterType;
    union
    {
        D3D12_ROOT_DESCRIPTOR_TABLE1   DescriptorTable;
        D3D12_ROOT_CONSTANTS           Constants;
        D3D12_ROOT_DESCRIPTOR1         Descriptor;
    };
    D3D12_SHADER_VISIBILITY ShaderVisibility;
} D3D12_ROOT_PARAMETER1;
```

<a id="d3d12-root-signature-desc"></a>

```cpp
typedef struct D3D12_ROOT_SIGNATURE_DESC
{
    UINT NumParameters;
    const D3D12_ROOT_PARAMETER* pParameters;
    UINT NumStaticSamplers;
    const D3D12_STATIC_SAMPLER_DESC* pStaticSamplers;
    D3D12_ROOT_SIGNATURE_FLAGS Flags;
} D3D12_ROOT_SIGNATURE_DESC;
```

```cpp
typedef struct D3D12_ROOT_SIGNATURE_DESC1
{
    UINT NumParameters;
    const D3D12_ROOT_PARAMETER1* pParameters;
    UINT NumStaticSamplers;
    const D3D12_STATIC_SAMPLER_DESC* pStaticSamplers;
    D3D12_ROOT_SIGNATURE_FLAGS Flags;
} D3D12_ROOT_SIGNATURE_DESC1;
```

```cpp
typedef struct D3D12_ROOT_SIGNATURE_DESC2
{
    UINT NumParameters;
    const D3D12_ROOT_PARAMETER1* pParameters;
    UINT NumStaticSamplers;
    const D3D12_STATIC_SAMPLER_DESC1* pStaticSamplers;
    D3D12_ROOT_SIGNATURE_FLAGS Flags;
} D3D12_ROOT_SIGNATURE_DESC2;
```

<a id="d3d12-versioned-root-signature-desc"></a>

```cpp
typedef struct D3D12_VERSIONED_ROOT_SIGNATURE_DESC
{
    D3D_ROOT_SIGNATURE_VERSION Version;
    union
    {
        D3D12_ROOT_SIGNATURE_DESC   Desc_1_0;
        D3D12_ROOT_SIGNATURE_DESC1  Desc_1_1;
        D3D12_ROOT_SIGNATURE_DESC2  Desc_1_2;
    };
} D3D12_VERSIONED_ROOT_SIGNATURE_DESC;
```

<a id="descriptor-ranges"></a>

### Descriptor ranges

`D3D12_DESCRIPTOR_RANGE` defines a range of descriptors of a given type (e.g. SRVs) within a
descriptor table.

```c++
#define D3D12_DESCRIPTOR_RANGE_OFFSET_APPEND -1
```

`D3D12_DESCRIPTOR_RANGE_OFFSET_APPEND` can typically be used for the
`OffsetInDescriptorsFromTableStart` below. This means append the
descriptor range being defined after the previous one in the descriptor
table. If the application wants to alias descriptors or for some reason
skip slots it can set `OffsetInDescriptorsFromTableStart` to whatever
offset is desired. Defining overlapping ranges of different `RangeType` is
invalid.

The set of shader registers specified by the combination of `RangeType`,
NumDescriptors, BaseShaderRegister, and RegisterSpace cannot
conflict/overlap across any declarations in a root signature that have
common `D3D12_SHADER_VISIBILITY` (visibility defined a bit later).

`NumDescriptors == UINT_MAX` declares an unbounded range. Such a range must be last in the table or followed by a range with an explicit `OffsetInDescriptorsFromTableStart` rather than `D3D12_DESCRIPTOR_RANGE_OFFSET_APPEND`.

`D3D12_ROOT_DESCRIPTOR_TABLE` declares the layout of a descriptor table as a collection of descriptor
ranges, each located at an offset relative to the table’s base descriptor.

Samplers are not allowed in the same descriptor table as CBV/UAV/SRVs.

`D3D12_ROOT_DESCRIPTOR_TABLE` is a member of `D3D12_ROOT_PARAMETER`, and is used when its
ParameterType is set to `D3D12_ROOT_PARAMETER_TYPE_DESCRIPTOR_TABLE`.

<a id="register-spaces"></a>

### Register spaces

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
add bindings to a shader in these reserved spaces without conflicting
with whatever register bindings the original shader used. The
reservation is split between driver and OS: register Space
0xfffffff0..0xfffffff7 are reserved for driver use and
0xfffffff8..0xffffffff are reserved for OS use.

<a id="shader-visibility"></a>

### Shader visibility and access flags

`D3D12_SHADER_VISIBILITY` identifies which shaders see the contents of a given root signature slot. Compute
always uses _ALL (since there is only one active stage). Graphics can
choose, but if it uses _ALL, all shader stages see whatever is bound at
the root signature slot.

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
both shaders see the same texture. If the application actually wants
each shader to see different textures, it can define 2 root signature
slots with `VISIBILITY_VERTEX` and _PIXEL. No matter what the visibility
is on a root signature slot, it always has the same cost (cost only
depending on what the parameter type is) towards one fixed maximum root
signature size.

On lower resource binding tiers, `SHADER_VISIBILITY` is also taken into account
when validating the sizes of descriptor tables in a root signature,
since some hardware can only support a maximum amount of bindings
per-stage. These restrictions are only imposed when running on low tier
hardware and do not limit more modern hardware at all.

If a root signature has multiple descriptor tables defined that overlap
each other in namespace (the register bindings to the shader) and any
one of them specifies _ALL for visibility, the layout is invalid
(creation will fail).

| Flag | Meaning |
|---|---|
| `DENY_*_SHADER_ROOT_ACCESS` | Prevents the named stage from accessing root arguments. Must not conflict with a parameter explicitly visible to that stage. |
| `ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT` | Required for root signatures used in graphics pipelines that include an input layout. |
| `ALLOW_STREAM_OUTPUT` | Required for root signatures used in graphics pipelines that include stream output. |
| `LOCAL_ROOT_SIGNATURE` | Identifies a local signature. Cannot be combined with other root signature flags. |
| `CBV_SRV_UAV_HEAP_DIRECTLY_INDEXED`, `SAMPLER_HEAP_DIRECTLY_INDEXED` | Defined under [Direct heap indexing](#direct-indexing). |

<a id="static-promises"></a>

## Descriptor and data promises

The purpose of Root Signature version 1.1 is to enable applications to
indicate to drivers when descriptors in a descriptor heap won't change
or the data descriptors point to won't change. This allows the option
for drivers to make optimizations that might be possible knowing that
something (like a descriptor or the memory it points to) is static for
some period of time. The specific optimizations drivers might do are
hardware vendor specific, and importantly they do not change behavior
other than possibly improving performance.

```cpp
typedef enum D3D12_DESCRIPTOR_RANGE_FLAGS
{
    D3D12_DESCRIPTOR_RANGE_FLAG_NONE = 0x0,
    D3D12_DESCRIPTOR_RANGE_FLAG_DESCRIPTORS_VOLATILE = 0x1,
    D3D12_DESCRIPTOR_RANGE_FLAG_DATA_VOLATILE = 0x2,
    D3D12_DESCRIPTOR_RANGE_FLAG_DATA_STATIC_WHILE_SET_AT_EXECUTE = 0x4,
    D3D12_DESCRIPTOR_RANGE_FLAG_DATA_STATIC = 0x8,
    D3D12_DESCRIPTOR_RANGE_FLAG_DESCRIPTORS_STATIC_KEEPING_BUFFER_BOUNDS_CHECKS = 0x10000,
} D3D12_DESCRIPTOR_RANGE_FLAGS;
```

```cpp
typedef enum D3D12_ROOT_DESCRIPTOR_FLAGS
{
    D3D12_ROOT_DESCRIPTOR_FLAG_NONE = 0x0,
    D3D12_ROOT_DESCRIPTOR_FLAG_DATA_VOLATILE = 0x2,
    D3D12_ROOT_DESCRIPTOR_FLAG_DATA_STATIC_WHILE_SET_AT_EXECUTE = 0x4,
    D3D12_ROOT_DESCRIPTOR_FLAG_DATA_STATIC = 0x8,
} D3D12_ROOT_DESCRIPTOR_FLAGS;
```

<a id="table-initialization"></a>
<a id="descriptor-table-initialization"></a>

### Descriptor initialization and population

The descriptor mode and resource binding tier together determine which entries must be initialized and when:

| Descriptor mode | Binding tier and descriptor types | Entries that must be initialized | Deadline |
|---|---|---|---|
| Static | All tiers and descriptor types | Every descriptor in the static range, even if shaders will not reference it | Before the descriptor table is set during command list or bundle recording |
| Volatile | Tier 1: CBV, SRV, UAV and sampler. Tier 2: CBV and UAV | Every descriptor of these types declared in the table, even if shaders will not reference it | Before the command list executes |
| Volatile | Tier 2: SRV and sampler. Tier 3: all descriptor types | Descriptors that shaders will actually reference | Before the shader accesses them |

The higher-tier allowance to leave unused entries uninitialized does not apply to static descriptor ranges. A required entry can contain a compatible [null descriptor](#null-descriptors).

The descriptor mode also determines when entries may be modified, as specified below. The `DATA_*` flags instead constrain the resource data pointed to by descriptors.

### Descriptor range flags

On each range of descriptors comprising a descriptor table declaration,
the following flags can be specified:

**DESCRIPTORS_VOLATILE**:

The descriptors in a descriptor heap pointed to by a root descriptor
table can be changed by the application any time except while the
command list / bundles that bind the descriptor table have been
submitted and have not finished executing. For instance, recording a
command list and subsequently changing descriptors in a descriptor heap
it refers to before submitting the command list for execution is valid.
This is the only behavior that Root Signature version 1.0 supported (it
didn't have a way to choose).

Volatile descriptors follow the tier-dependent [initialization and population requirements](#table-initialization). Volatility does not permit shaders to access uninitialized descriptors.

**Absence of DESCRIPTORS_VOLATILE:**

Descriptors are **static.** There is no flag for this mode.
The [initialization and population requirements](#table-initialization) require the static ranges to be initialized when the table is set during recording, regardless of binding tier.
The descriptors cannot be changed until the command list / bundle has
finished executing for the last time. For Root Signature version 1.1,
static descriptors are the default assumption, given the application has
to go out of its way to specify the `DESCRIPTORS_VOLATILE` flag when
needed.

See [static descriptor bundle requirements](command-list-state.md#static-descriptors) for rules about using static descriptors in bundles.

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
accessing descriptors, they need to use `DESCRIPTORS_VOLATILE` or `DESCRIPTORS_STATIC_KEEPING_BUFFER_BOUNDS_CHECKS`.

**DESCRIPTORS_STATIC_KEEPING_BUFFER_BOUNDS_CHECKS:**

This flag indicates that descriptors should
have all of the above static properties **except** that out-of-bounds Buffer view reads return zero and out-of-bounds writes are discarded.
This still enables several optimizations, but does require the driver to
maintain the size information of the buffer views.

**DATA_VOLATILE**:

(This applies to both descriptor range flags and root descriptor flags.)

The data pointed to by descriptors can be changed by the CPU any time
except while the command list / bundles that bind the descriptor table
have been submitted and have not finished executing. This is the only
behavior that Root Signature version 1.0 supported (it didn't have a way
to choose).

**DATA_STATIC_WHILE_SET_AT_EXECUTE:**

(This applies to both descriptor range flags and root descriptor flags.)

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

<a id="data-static"></a>

**DATA_STATIC:**

(This applies to both descriptor range flags and root descriptor flags.)

The data pointed to by descriptors has been initialized by the time a
root descriptor or descriptor table referencing the memory has been set
on a command list / bundle (during recording), and the data cannot be
changed until the command list / bundle has finished executing for the
last time.

The [static data bundle requirements](command-list-state.md#static-data) apply.

**Remarks:**

At most one of the `DATA_*` flags can be specified at a time. The
exception is Sampler descriptor ranges which don't support `DATA_*`
flags at all since samplers do not point to data.

For static SRV and CBV descriptor ranges, the absence of any `DATA_*` flags
means a default of `DATA_STATIC_WHILE_SET_AT_EXECUTE` behavior is
assumed. The reason this default is chosen rather than `DATA_STATIC` is
that `DATA_STATIC_WHILE_SET_AT_EXECUTE` is much more likely to be a
safe default for the vast majority of cases (where a developer may not
have put thought into setting the root signature flags), while still
yielding some optimization opportunity better than defaulting to
`DATA_VOLATILE`.

With `DESCRIPTORS_VOLATILE` and no explicit `DATA_*` flag, CBV, SRV, and UAV ranges default to `DATA_VOLATILE`.

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

<a id="descriptor-range-defaults"></a>

**Valid Descriptor Range Flags Settings**    | **Remarks**
---|---
| none                              | Descriptors static (default).<br><br>Default assumptions for data:<br><br>**For SRV/CBV**: `DATA_STATIC_WHILE_SET_AT_EXECUTE`<br><br>**For UAV**: `DATA_VOLATILE`<br><br>The goal is these defaults for SRV/CBV will safely fit the usage patterns for the majority of root signatures where applications have not thought about the flag settings at all, giving drivers ample optimization opportunity for free that wasn't captured by root signature version 1.0.
`DATA_STATIC`                      | Descriptors static (default) + data static
`DATA_VOLATILE`                    | Descriptors static (default) + data volatile
`DATA_STATIC_WHILE_SET_AT_EXECUTE` | Descriptors static (default) + data static while set at execute
`DESCRIPTORS_VOLATILE`             | Descriptors volatile + Default assumptions for data:<br><br>**For SRV/CBV/UAV**: `DATA_VOLATILE`
`DESCRIPTORS_VOLATILE \| DATA_VOLATILE` | Both descriptors and data volatile, equivalent to Root Signature 1.0
`DESCRIPTORS_VOLATILE \| DATA_STATIC_WHILE_SET_AT_EXECUTE`         | Descriptors volatile, but note that still does not allow them to change during command list execution unless rebound. So it is valid to combine the additional declaration that data is static while set via root descriptor table during execution -- the underlying descriptors are effectively static for longer than the data is being promised to be static. |

`DESCRIPTORS_STATIC_KEEPING_BUFFER_BOUNDS_CHECKS` cannot be combined with `DESCRIPTORS_VOLATILE` and is not valid for sampler ranges. Each descriptor range must contain at least one descriptor, and range offsets/register arithmetic must not overflow.

`DATA_STATIC_WHILE_SET_AT_EXECUTE` requires data to be finalized before the relevant root binding executes, not merely before a later draw/dispatch. The [root binding synchronization requirement](synchronization.md#barrier-sync) defines the required barrier placement and synchronization scopes for both descriptor tables and root descriptors.

### Root descriptor flags

These flags have the same semantics as descriptor range flags described
earlier, except that for root descriptors only `DATA_*` flags apply. By
definition, root descriptors are static, as they are directly set into
command lists / bundles, so there is no root descriptor equivalent to
the flag `D3D12_DESCRIPTOR_RANGE_FLAG_DESCRIPTORS_VOLATILE`.

<a id="root-descriptor-defaults"></a>

**Valid Root Descriptor Flags Settings**     | **Remarks**
---|---
| none                              | Default assumptions for data:<br><br>**For SRV/CBV**: `DATA_STATIC_WHILE_SET_AT_EXECUTE`<br><br>**For UAV**: `DATA_VOLATILE`<br><br>The goal is these defaults for SRV/CBV will safely fit the usage patterns for the majority of root signatures where applications have not thought about the flag settings at all, giving drivers ample optimization opportunity for free that wasn't captured by root signature version 1.0.
`DATA_STATIC`  | \-
`DATA_VOLATILE`  | Equivalent to Root Signature 1.0
`DATA_STATIC_WHILE_SET_AT_EXECUTE` | \-

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

The debug layer has options for validating that applications honor
their promises, including the default promises that come with using Root
Signature version 1.1 without setting any flags.

<a id="direct-indexing"></a>

## Direct heap indexing

Global root signature flags indicate when heap addresses must be made available to shaders for direct heap indexing.

The two global root signature flags are only allowed on a device supporting this feature.
Support requires Resource Binding Tier 3 and Shader Model 6.6 or higher.
These new flags are not allowed on local root signatures
(`D3D12_ROOT_SIGNATURE_FLAG_LOCAL_ROOT_SIGNATURE`).

The `CBV_SRV_UAV_HEAP_DIRECTLY_INDEXED` flag must be set
to allow shaders using `ResourceDescriptorHeap`
to assign CBV, SRV, or UAV objects.

The `SAMPLER_HEAP_DIRECTLY_INDEXED` flag must be set
to allow shaders using `SamplerDescriptorHeap`
to assign Sampler objects.

Shader to Root Signature validation
will fail if the shader creates resources from one of these heaps and
the corresponding flag is not set in the root signature.
This validation is run at shader compilation time
if a root signature is attached to the entry point.
It is also run in D3D12 during pipeline state creation
when a root signature is attached to the pipeline
for every shader that wasn't already validated
with a matching root signature.

The [direct heap binding order](command-list-state.md#direct-heaps) applies to `SetDescriptorHeaps` and the corresponding graphics/compute root signature setter. Direct indexing uses the selected shader-visible resource or sampler heap. It does not select a separate heap.

In Shader Model 6.6,
the descriptor and data for a resource or sampler
created from `ResourceDescriptorHeap` or `SamplerDescriptorHeap`
must both be considered **volatile** -
equivalent to `DESCRIPTORS_VOLATILE | DATA_VOLATILE`
in the root signature descriptor range flags.

`DESCRIPTORS_VOLATILE`
does not mean that the descriptor can be changed
during execution (draw/dispatch).
In addition, the volatility of read-only SRVs and CBVs with `DATA_VOLATILE` is also limited,
since modification and subsequent use require the applicable [synchronization](synchronization.md#foundations).

<a id="samplers"></a>

## Static and dynamic samplers

See [common sampler/filtering model](common-shader-internals.md#sampler-model) for more details about what the sampler fields actually do.

Many applications only need a fixed set of samplers, and these are often
common across many pipeline states.  Another view of this is that it
would be convenient in many cases for HLSL authors to be able to
define samplers directly in shader code, near the use of them.

One issue is that some hardware is not set up to take advantage of
knowing the set of samplers to be used in shaders and instead needs to
manage the sampler externally in a descriptor heap.  Other hardware, by
contrast, does benefit from knowing what samplers will be used in a
shader at compile time.

To enable all these types of hardware to operate efficiently while
providing applications additional convenience for shader authors, a set
of static samplers can be defined in the root signature.  These are
independent of the root parameters in the root signature.  Root
parameters define a binding space where arguments can be provided at
runtime, whereas static samplers are by definition unchanging.

Since root signatures can be authored directly in HLSL, samplers can be
authored in HLSL too - as static samplers in a root signature.

The presence of the root signature in pipeline state creation means that
hardware that prefers to compile static sampler state directly into the
shader can do so.

The presence of static samplers in the root signature also works for
hardware that needs to manage samplers outside the shader.  Recall that
root signatures are objects that applications must create at the D3D API
for use in command lists, and any pipeline states that are used must
match the currently set root signature.  Drivers can take advantage of
this to place static samplers in a reserved area in all sampler heaps
the application has created (as well as a hidden one in case the
application does not use a sampler heap on a given command list at
all).

To maintain the currently live set of static samplers, drivers that need
to can use a critical section on root signature creation / destruction
and on sampler descriptor heap creation destruction.  These operations
should be quite rare during execution, so the impact of any shadowing of
static samplers on high performance rendering should not be noticeable.

To help limit the maximum amount of memory involved to shadow static
samplers (also to fit within some hardware constraints) the total number
of unique static samplers that can be declared across all root
signatures live on a D3D device at a time is limited to 2032. This is
slightly less than a power of 2 (2048) to leave some room for drivers
that need to allocate some samplers internally.  This is separate from
the samplers that an application can manage manually in a sampler
descriptor heap, whose capacity is [capability-dependent](#binding-capabilities).

Arrays of static samplers are not permitted.
This way drivers can manage the maximum limit of 2032 static
samplers as a heap of individually allocated samplers, such as in a
hidden portion of any application created sampler descriptor heap,
without any consequence from heap fragmentation as samplers may come and
go.   If an application has samplers A and B in one root signature, and
samplers A and C in a second root signature, the total cost against the
2032 limit is 3, not 4, since A appears twice.  If the second root
signature is freed, only A and B are left allocated, leaving 2030 free.

The static samplers defined in a root signature are independent of
samplers an application chooses to put in a descriptor heap -- both
mechanisms can be used at the same time.  A root signature simply must
not declare that a sampler in a shader comes from both a static sampler
and from a sampler descriptor table.  That will fail compilation since
it doesn't make sense.

Even with the convenience of static samplers, there are reasons for an
app to manage samplers in a sampler descriptor heap (via descriptor
tables) instead of or in addition to static samplers: the selection of
samplers is truly dynamic and unknown at shader compile, the application
wants to use dynamic indexing of samplers, or the type of sampler needed
is not supported in a static sampler. See [static sampler border color restrictions](#static-sampler-border-colors).

```cpp
typedef enum D3D12_FILTER
{
    D3D12_FILTER_MIN_MAG_MIP_POINT                              = 0x00000000,
    D3D12_FILTER_MIN_MAG_POINT_MIP_LINEAR                       = 0x00000001,
    D3D12_FILTER_MIN_POINT_MAG_LINEAR_MIP_POINT                 = 0x00000004,
    D3D12_FILTER_MIN_POINT_MAG_MIP_LINEAR                       = 0x00000005,
    D3D12_FILTER_MIN_LINEAR_MAG_MIP_POINT                       = 0x00000010,
    D3D12_FILTER_MIN_LINEAR_MAG_POINT_MIP_LINEAR                = 0x00000011,
    D3D12_FILTER_MIN_MAG_LINEAR_MIP_POINT                       = 0x00000014,
    D3D12_FILTER_MIN_MAG_MIP_LINEAR                             = 0x00000015,
    D3D12_FILTER_MIN_MAG_ANISOTROPIC_MIP_POINT                  = 0x00000054,
    D3D12_FILTER_ANISOTROPIC                                    = 0x00000055,
    D3D12_FILTER_COMPARISON_MIN_MAG_MIP_POINT                   = 0x00000080,
    D3D12_FILTER_COMPARISON_MIN_MAG_POINT_MIP_LINEAR            = 0x00000081,
    D3D12_FILTER_COMPARISON_MIN_POINT_MAG_LINEAR_MIP_POINT      = 0x00000084,
    D3D12_FILTER_COMPARISON_MIN_POINT_MAG_MIP_LINEAR            = 0x00000085,
    D3D12_FILTER_COMPARISON_MIN_LINEAR_MAG_MIP_POINT            = 0x00000090,
    D3D12_FILTER_COMPARISON_MIN_LINEAR_MAG_POINT_MIP_LINEAR     = 0x00000091,
    D3D12_FILTER_COMPARISON_MIN_MAG_LINEAR_MIP_POINT            = 0x00000094,
    D3D12_FILTER_COMPARISON_MIN_MAG_MIP_LINEAR                  = 0x00000095,
    D3D12_FILTER_COMPARISON_MIN_MAG_ANISOTROPIC_MIP_POINT       = 0x000000d4,
    D3D12_FILTER_COMPARISON_ANISOTROPIC                         = 0x000000d5,
    D3D12_FILTER_MINIMUM_MIN_MAG_MIP_POINT                      = 0x00000100,
    D3D12_FILTER_MINIMUM_MIN_MAG_POINT_MIP_LINEAR               = 0x00000101,
    D3D12_FILTER_MINIMUM_MIN_POINT_MAG_LINEAR_MIP_POINT         = 0x00000104,
    D3D12_FILTER_MINIMUM_MIN_POINT_MAG_MIP_LINEAR               = 0x00000105,
    D3D12_FILTER_MINIMUM_MIN_LINEAR_MAG_MIP_POINT               = 0x00000110,
    D3D12_FILTER_MINIMUM_MIN_LINEAR_MAG_POINT_MIP_LINEAR        = 0x00000111,
    D3D12_FILTER_MINIMUM_MIN_MAG_LINEAR_MIP_POINT               = 0x00000114,
    D3D12_FILTER_MINIMUM_MIN_MAG_MIP_LINEAR                     = 0x00000115,
    D3D12_FILTER_MINIMUM_MIN_MAG_ANISOTROPIC_MIP_POINT          = 0x00000154,
    D3D12_FILTER_MINIMUM_ANISOTROPIC                            = 0x00000155,
    D3D12_FILTER_MAXIMUM_MIN_MAG_MIP_POINT                      = 0x00000180,
    D3D12_FILTER_MAXIMUM_MIN_MAG_POINT_MIP_LINEAR               = 0x00000181,
    D3D12_FILTER_MAXIMUM_MIN_POINT_MAG_LINEAR_MIP_POINT         = 0x00000184,
    D3D12_FILTER_MAXIMUM_MIN_POINT_MAG_MIP_LINEAR               = 0x00000185,
    D3D12_FILTER_MAXIMUM_MIN_LINEAR_MAG_MIP_POINT               = 0x00000190,
    D3D12_FILTER_MAXIMUM_MIN_LINEAR_MAG_POINT_MIP_LINEAR        = 0x00000191,
    D3D12_FILTER_MAXIMUM_MIN_MAG_LINEAR_MIP_POINT               = 0x00000194,
    D3D12_FILTER_MAXIMUM_MIN_MAG_MIP_LINEAR                     = 0x00000195,
    D3D12_FILTER_MAXIMUM_MIN_MAG_ANISOTROPIC_MIP_POINT          = 0x000001d4,
    D3D12_FILTER_MAXIMUM_ANISOTROPIC                            = 0x000001d5
} D3D12_FILTER;
```

```cpp
typedef enum D3D12_TEXTURE_ADDRESS_MODE
{
    D3D12_TEXTURE_ADDRESS_MODE_WRAP = 1,
    D3D12_TEXTURE_ADDRESS_MODE_MIRROR = 2,
    D3D12_TEXTURE_ADDRESS_MODE_CLAMP = 3,
    D3D12_TEXTURE_ADDRESS_MODE_BORDER = 4,
    D3D12_TEXTURE_ADDRESS_MODE_MIRROR_ONCE = 5
} D3D12_TEXTURE_ADDRESS_MODE;
```

```cpp
typedef enum D3D12_COMPARISON_FUNC
{
    D3D12_COMPARISON_FUNC_NONE = 0,
    D3D12_COMPARISON_FUNC_NEVER = 1,
    D3D12_COMPARISON_FUNC_LESS = 2,
    D3D12_COMPARISON_FUNC_EQUAL = 3,
    D3D12_COMPARISON_FUNC_LESS_EQUAL = 4,
    D3D12_COMPARISON_FUNC_GREATER = 5,
    D3D12_COMPARISON_FUNC_NOT_EQUAL = 6,
    D3D12_COMPARISON_FUNC_GREATER_EQUAL = 7,
    D3D12_COMPARISON_FUNC_ALWAYS = 8
} D3D12_COMPARISON_FUNC;
```

```cpp
typedef enum D3D12_STATIC_BORDER_COLOR
{
    D3D12_STATIC_BORDER_COLOR_TRANSPARENT_BLACK,
    D3D12_STATIC_BORDER_COLOR_OPAQUE_BLACK,
    D3D12_STATIC_BORDER_COLOR_OPAQUE_WHITE,
    D3D12_STATIC_BORDER_COLOR_OPAQUE_BLACK_UINT,
    D3D12_STATIC_BORDER_COLOR_OPAQUE_WHITE_UINT,
} D3D12_STATIC_BORDER_COLOR;
```

```cpp
typedef enum D3D12_SAMPLER_FLAGS
{
    D3D12_SAMPLER_FLAG_NONE = 0x0,
    D3D12_SAMPLER_FLAG_UINT_BORDER_COLOR = 0x01,
    D3D12_SAMPLER_FLAG_NON_NORMALIZED_COORDINATES = 0x02,
} D3D12_SAMPLER_FLAGS;
```

<a id="d3d12-sampler-desc"></a>

```cpp
typedef struct D3D12_SAMPLER_DESC
{
    D3D12_FILTER Filter;
    D3D12_TEXTURE_ADDRESS_MODE AddressU;
    D3D12_TEXTURE_ADDRESS_MODE AddressV;
    D3D12_TEXTURE_ADDRESS_MODE AddressW;
    FLOAT MipLODBias;
    UINT MaxAnisotropy;
    D3D12_COMPARISON_FUNC ComparisonFunc;
    FLOAT BorderColor[4];
    FLOAT MinLOD;
    FLOAT MaxLOD;
} D3D12_SAMPLER_DESC;
```

```cpp
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
        FLOAT FloatBorderColor[4];
        UINT  UintBorderColor[4];
    };
    FLOAT MinLOD;
    FLOAT MaxLOD;
    D3D12_SAMPLER_FLAGS Flags;
} D3D12_SAMPLER_DESC2;
```

```cpp
typedef struct D3D12_STATIC_SAMPLER_DESC
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
} D3D12_STATIC_SAMPLER_DESC;
```

```cpp
typedef struct D3D12_STATIC_SAMPLER_DESC1
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
    D3D12_SAMPLER_FLAGS Flags;
} D3D12_STATIC_SAMPLER_DESC1;
```

<a id="sampler-fields"></a>

### Sampler fields


`Filter`

A [`D3D12_FILTER`](common-shader-internals.md#sampler-model)-typed value that specifies the filtering method to use when sampling a texture.

<a id="filter-encoding"></a>

`D3D12_FILTER` values use the following bit fields:

| Bits | Field | Encoding |
|---|---|---|
| `[1:0]` | Mip filtering | `0` = point, `1` = linear. `2` and `3` are unused |
| `[3:2]` | Magnification filtering | `0` = point, `1` = linear. `2` and `3` are unused |
| `[5:4]` | Minification filtering | `0` = point, `1` = linear. `2` and `3` are unused |
| `[6]` | Anisotropic filtering bit | `1` = anisotropic, `0` = isotropic. Must use linear min/mag filtering. |
| `[8:7]` | Reduction type | `0` = standard filtering, `1` = comparison, `2` = minimum, `3` = maximum |
| `[31]` | Legacy monochrome filtering bit | Not supported in D3D12 |

The header's `D3D12_ENCODE_BASIC_FILTER(min, mag, mip, reduction)` constructs a basic filter as:

```cpp
((min & 0x3) << 4) |
((mag & 0x3) << 2) |
((mip & 0x3) << 0) |
((reduction & 0x3) << 7)
```

The `min`, `mag` and `mip` arguments use `D3D12_FILTER_TYPE_POINT` (`0`) or `D3D12_FILTER_TYPE_LINEAR` (`1`). The `reduction` argument uses `D3D12_FILTER_REDUCTION_TYPE`, with the values shown above. `D3D12_ENCODE_ANISOTROPIC_FILTER(reduction)` and `D3D12_ENCODE_MIN_MAG_ANISOTROPIC_MIP_POINT_FILTER(reduction)` combine `0x40` with linear minification and magnification, and specified mip filtering, giving `0x55` or `0x54` respectively before the reduction bits are included.

<a id="anisotropic-point-mip"></a>
<a id="anisotropic-filtering-with-point-mip-selection"></a>

`D3D12_FEATURE_DATA_D3D12_OPTIONS19.AnisoFilterWithPointMipSupported` enables `D3D12_FILTER_MIN_MAG_ANISOTROPIC_MIP_POINT`, `D3D12_FILTER_COMPARISON_MIN_MAG_ANISOTROPIC_MIP_POINT`, `D3D12_FILTER_MINIMUM_MIN_MAG_ANISOTROPIC_MIP_POINT`, and `D3D12_FILTER_MAXIMUM_MIN_MAG_ANISOTROPIC_MIP_POINT`. These use [point mip selection with anisotropic minification/magnification filtering](common-shader-internals.md#anisotropic-point-mip).

`AddressU`

A [`D3D12_TEXTURE_ADDRESS_MODE`](common-shader-internals.md#archive-7-18-9)-typed value that specifies the method to use for resolving a u texture coordinate that is outside the 0 to 1 range.

`AddressV`

A [`D3D12_TEXTURE_ADDRESS_MODE`](common-shader-internals.md#archive-7-18-9)-typed value that specifies the method to use for resolving a v texture coordinate that is outside the 0 to 1 range.

`AddressW`

A [`D3D12_TEXTURE_ADDRESS_MODE`](common-shader-internals.md#archive-7-18-9)-typed value that specifies the method to use for resolving a w texture coordinate that is outside the 0 to 1 range.

[`MipLODBias`](common-shader-internals.md#sampler-lod-bias-and-clamping)

Offset from the calculated mipmap level. For example, if the runtime calculates that a texture should be sampled at mipmap level 3 and **MipLODBias** is 2, the texture will be sampled at mipmap level 5.

[`MaxAnisotropy`](common-shader-internals.md#anisotropic-lod-calculation)

Clamping value used for anisotropic filtering. Valid values are between 1 and 16.

`ComparisonFunc`

A [`D3D12_COMPARISON_FUNC`](common-shader-internals.md#comparison-sampling)-typed value that specifies a function that compares sampled data against existing sampled data.

[`BorderColor[4]`](common-shader-internals.md#archive-7-18-9-1)

RGBA border color to use if [`D3D12_TEXTURE_ADDRESS_MODE_BORDER`](common-shader-internals.md#archive-7-18-9) is specified for **AddressU**, **AddressV**, or **AddressW**. Range must be between 0.0 and 1.0 inclusive.

[`MinLOD`](common-shader-internals.md#sampler-lod-bias-and-clamping)

Lower end of the mipmap range to clamp access to, where 0 is the largest and most detailed mipmap level and any level higher than that is less detailed.

[`MaxLOD`](common-shader-internals.md#sampler-lod-bias-and-clamping)

Upper end of the mipmap range to clamp access to, where 0 is the largest and most detailed mipmap level and any level higher than that is less detailed. This value must be greater than or equal to **MinLOD**. To have no upper limit on LOD, set this member to a large value.

---

Values from unsigned integer formats can
 be used by texture retrieval intrinsics
 with certain restrictions on filtering.
Integer samples may not use any `LINEAR` or `ANISOTROPIC` filtering modes.
These `D3D12_FILTER` options are allowed:

- `D3D12_FILTER_MIN_MAG_MIP_POINT`
- `D3D12_FILTER_MINIMUM_MIN_MAG_MIP_POINT`
- `D3D12_FILTER_MAXIMUM_MIN_MAG_MIP_POINT`

Setting the `D3D12_SAMPLER_FLAG_UINT_BORDER_COLOR` bit
 in the `Flags` field indicates that the sampler should be
 treated as having integer border color values
 and the `UintBorderColor` field should
 contain valid integer values representing those border colors.
Otherwise, the sampler has float border color values
and the `FloatBorderColor` field should be used.

For signed texture formats, the border color values are treated
as 32-bit signed integers instead. For texture formats where the
components are smaller than 32 bits, it is undefined whether the
hardware will truncate or clamp.

**Note**: D3D does not currently define an ordering between retrieving
border color values and applying SRV swizzles, and different hardware
may apply these in opposite orders. Additionally, for stencil data,
D3D defines that the shader should retrieve the value in the G channel,
which some hardware may achieve by using SRV swizzles. Therefore, it
is possible that when sampling stencil and passing out-of-bounds coordinates
to return a border color, the border value returned to the shader in the G
channel (unless otherwise redirected via an SRV swizzle) may be the value
specified in the sampler's border color in *either* the R or G channel.

<a id="static-sampler-border-colors"></a>

Static sampler border colors select transparent black, opaque black, or opaque white in floating-point form, or opaque black/white in unsigned-integer form. Integer border colors require the applicable SM6.7 support. They are selected by `D3D12_STATIC_BORDER_COLOR`. They do not require a sampler flags member in root signature versions 1.0/1.1.

For opaque borders, static samplers used with unsigned integer formats must use
 either `D3D12_STATIC_BORDER_COLOR_OPAQUE_BLACK_UINT` for black borders
 or `D3D12_STATIC_BORDER_COLOR_OPAQUE_WHITE_UINT` for white borders.

`D3D12_STATIC_SAMPLER_DESC1` has a `Flags`
member of type `D3D12_SAMPLER_FLAGS`. In
the context of static samplers, `D3D12_SAMPLER_FLAG_UINT_BORDER_COLOR`
is shadowed by the static border color, and not applicable. However, root
signature creation fails if this flag is used with `D3D12_STATIC_BORDER_COLOR_OPAQUE_BLACK` or `D3D12_STATIC_BORDER_COLOR_OPAQUE_WHITE`. `D3D12_STATIC_BORDER_COLOR_TRANSPARENT_BLACK` is also allowed: all four zero components have the same representation. With a uint border color the flag is redundant, but not an error.

<a id="non-normalized-samplers"></a>

### Non-normalized coordinate samplers and version 1.2

Samplers with `D3D12_SAMPLER_FLAG_NON_NORMALIZED_COORDINATES` set must sample from the target texture at the coordinates specified, unscaled by the texture's dimensions.

When non-normalized coordinates are used, the following restrictions apply:
* The SRV being sampled must be `D3D12_SRV_DIMENSION_TEXTURE1D` or `D3D12_SRV_DIMENSION_TEXTURE2D`
* The SRV's mip count must be 1.
* The sampling coordinate valid range is `x:[0, width)` and `y:[0, height)`
* The `Offset` parameter in `Sample*` functions must not be used
* The `D3D12_FILTER` must be one of
  * `D3D12_FILTER_MIN_MAG_MIP_POINT`
  * `D3D12_FILTER_MIN_MAG_LINEAR_MIP_POINT`
  * `D3D12_FILTER_MINIMUM_MIN_MAG_MIP_POINT`
  * `D3D12_FILTER_MINIMUM_MIN_MAG_LINEAR_MIP_POINT`
  * `D3D12_FILTER_MAXIMUM_MIN_MAG_MIP_POINT`
  * `D3D12_FILTER_MAXIMUM_MIN_MAG_LINEAR_MIP_POINT`

  Where the `min` and `mag` filters are equal, `mip` is `POINT`, and comparison and anisotropy are disabled.
* `MinLOD`, `MaxLOD`, and `MipLODBias` must be 0
* `AddressU` and `AddressV` must be `D3D12_TEXTURE_ADDRESS_MODE_CLAMP` or `D3D12_TEXTURE_ADDRESS_MODE_BORDER`

The result of sampling outside of the valid range is generally undefined in terms of what value may be returned.

[`CreateSampler2`](#id3d12device11-createsampler2) validates support for non-normalized coordinate sampling and the `Filter`, `MinLOD`, `MaxLOD`, `MipLODBias`, `AddressU` and `AddressV` restrictions above. Violating any of these requirements causes device removal. The same requirements are checked for static samplers, with failure reported by root signature creation.

Support for non-normalized texture sampling is implied by, and must be supported on, drivers that report their DDI version to be 0100 or greater.

`D3D12_FEATURE_DATA_D3D12_OPTIONS17.NonNormalizedCoordinateSamplersSupported` reports non-normalized coordinate sampler support.

<a id="binding-capabilities"></a>

## Capabilities and limits

The table below shows a progression of increasing flexibility in the
amount of resources available to the pipeline based on level of
hardware.

`D3D12_FEATURE_DATA_D3D12_OPTIONS.ResourceBindingTier`, queried with `D3D12_FEATURE_D3D12_OPTIONS`, indicates which binding tier the driver supports, described below.

**Bold** entries highlight improvements over the previous tier.

|   | Tier 1 | Tier 2 | Tier 3
|---|:---:|:---:|:---:|
| Max CBVs in all descriptor tables per shader stage | 14              | 14              | **full heap**
| Max SRVs in all descriptor tables per shader stage | 128             | **full heap**   | full heap
| Max UAVs in all descriptor tables across all stages | 8 (64 for FL 11.1+)    | **64**          | **full heap**
| Max Samplers in all descriptor tables per shader stage | 16              | **full heap**   | full heap

The finite lower-tier binding limits count the combined visible bindings. Root CBV/SRV/UAV descriptors consume their corresponding binding counts. Each root constant parameter consumes one CBV binding. Static samplers consume sampler bindings. Shader visibility determines which stages a binding counts against. These binding counts are separate from root argument DWORD cost and descriptor heap capacity.

`D3D12_FEATURE_DATA_D3D12_OPTIONS19` reports these limits:
| Option | Description |
|--|--|
| `MaxSamplerDescriptorHeapSize` | For drivers implementing DDI 0102 or newer, this will come from the driver, and must be at least 4000. For earlier drivers, D3D will set this to 2048. Attempting to create a shader-visible sampler descriptor heap with more than this many descriptors will fail. |
| `MaxSamplerDescriptorHeapSizeWithStaticSamplers` | For drivers implementing DDI 0102 or newer, this will come from the driver, and must be at least 2048. For earlier drivers, D3D will set this to 2048. Attempting to draw/dispatch (compute, mesh, rays) with a root signature bound that includes static samplers, and with a sampler descriptor heap bound with more than this many descriptors, is undefined behavior and will produce a debug layer error. |
| `MaxViewDescriptorHeapSize` | For drivers implementing DDI 0102 or newer, this will come from the driver, and must be at least 1,000,000. For earlier drivers, D3D will set this to 1,000,000. Attempting to create a shader-visible view descriptor heap with more than this many descriptors will fail for DDI 0102 or newer drivers. For earlier drivers reporting `D3D12_RESOURCE_BINDING_TIER_3`, requests for heaps larger than 1,000,000 will still be sent to the driver, with the expectation that they may fail. |

The device-wide limit is 2032 unique static samplers across live root signatures.

<a id="heap-apis"></a>

## Descriptor heap and copy APIs

<a id="d3d12-descriptor-heap-type"></a>

```cpp
typedef enum D3D12_DESCRIPTOR_HEAP_TYPE
{
    D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV,
    D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER,
    D3D12_DESCRIPTOR_HEAP_TYPE_RTV,
    D3D12_DESCRIPTOR_HEAP_TYPE_DSV,
    D3D12_DESCRIPTOR_HEAP_TYPE_NUM_TYPES
} D3D12_DESCRIPTOR_HEAP_TYPE;
```

```cpp
typedef enum D3D12_DESCRIPTOR_HEAP_FLAGS
{
    D3D12_DESCRIPTOR_HEAP_FLAG_NONE = 0x0,
    D3D12_DESCRIPTOR_HEAP_FLAG_SHADER_VISIBLE = 0x1,
} D3D12_DESCRIPTOR_HEAP_FLAGS;
```

<a id="descriptor-heap-description"></a>

<a id="d3d12-descriptor-heap-desc"></a>

```cpp
typedef struct D3D12_DESCRIPTOR_HEAP_DESC
{
    D3D12_DESCRIPTOR_HEAP_TYPE Type;
    UINT NumDescriptors;
    D3D12_DESCRIPTOR_HEAP_FLAGS Flags;
    UINT NodeMask;
} D3D12_DESCRIPTOR_HEAP_DESC;
```

All descriptor heaps support CPU descriptor writes.

`Type`

Selects the descriptor heap type.

`NumDescriptors`

The heap's capacity in descriptors. The count must satisfy the applicable [heap limits](#binding-capabilities).

`Flags`

For `CBV_SRV_UAV` descriptor heaps and SAMPLER descriptor heaps
`D3D12_DESCRIPTOR_HEAP_FLAG_SHADER_VISIBLE` can optionally be set.

The flag `D3D12_DESCRIPTOR_HEAP_FLAG_SHADER_VISIBLE` indicates that the
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

<a id="heap-node-selection"></a>
<a id="descriptor-heap-node-selection"></a>

`NodeMask`

Selects the descriptor heap's creation node. For single-adapter operation, set this to zero. If there are multiple adapter nodes, select exactly one node bit. See [Adapter identity and linked nodes](devices-and-capabilities.md#identity) for node numbering and mask interpretation.

<a id="d3d12-cpu-descriptor-handle"></a>

```cpp
typedef struct D3D12_CPU_DESCRIPTOR_HANDLE
{
    SIZE_T ptr;
} D3D12_CPU_DESCRIPTOR_HANDLE;
```

```cpp
typedef struct D3D12_GPU_DESCRIPTOR_HANDLE
{
    UINT64 ptr;
} D3D12_GPU_DESCRIPTOR_HANDLE;
```

`D3D12_*_DESCRIPTOR_HANDLE`, defined above, identifies a specific
descriptor in a descriptor heap. It is a bit like a pointer but the
application must not dereference it manually otherwise behavior is
undefined. Use of the handles must go through the API. A handle itself
can be copied freely or passed into APIs that operate on/use
descriptors. There is no ref counting, so the application must ensure it
does not use a handle after the underlying descriptor heap has been
deleted.

Applications query the descriptor handle increment for a given device instance and descriptor heap type using `GetDescriptorHandleIncrementSize()`. The heap start handle comes from `GetCPUDescriptorHandleForHeapStart()` or `GetGPUDescriptorHandleForHeapStart()`. To obtain a descriptor's handle, add the increment size multiplied by its zero-based index to the heap start handle. Applications must never hardcode descriptor handle increment sizes, otherwise behavior is undefined.

The increment describes handle arithmetic, not the descriptor memory layout. Applications must not use increment sizes and handles to examine or manipulate descriptor heap data, otherwise behavior is undefined. Handles may be proxies rather than pointers. Descriptor memory layout is not standardized and can vary even for a given device.

GetCPUDescriptorHandleForHeapStart() returns a CPU handle for CPU manipulation of
a descriptor heap.

GetGPUDescriptorHandleForHeapStart() returns a GPU handle for shader visible
descriptor heaps. The heap must be shader visible. The debug layer reports an error otherwise.

Descriptor heaps inherit from ID3D12Pageable. This imposes
on applications responsibility for residency management on descriptor
heaps just like resource heaps. The residency management methods only
apply to shader visible heaps, since the non shader visible heaps are
not visible to the GPU directly.

<a id="id3d12device-createdescriptorheap"></a>

### ID3D12Device::CreateDescriptorHeap

#### Declaration

```cpp
HRESULT CreateDescriptorHeap(
    const D3D12_DESCRIPTOR_HEAP_DESC* pDescriptorHeapDesc,
    REFIID riid,
    void** ppvHeap);
```

#### Behavior

Creates a descriptor heap object.

#### Parameters

`[in] pDescriptorHeapDesc`

A pointer to a [`D3D12_DESCRIPTOR_HEAP_DESC`](#descriptor-heap-description) structure that describes the heap.

`riid`

The globally unique identifier (**GUID**) for the descriptor heap interface. An input parameter.

`[out] ppvHeap`

A pointer to a memory block that receives a pointer to the descriptor heap. *ppvHeap* can be NULL. When *ppvHeap* is NULL, no object will be created and S\_FALSE will be returned when *pDescriptorHeapDesc* is valid.

#### Return values

This method returns **E\_OUTOFMEMORY** if there is insufficient memory to create the descriptor heap object. See [Direct3D 12 Return Codes](devices-and-capabilities.md#api-result-codes) for other possible return values.

<a id="id3d12device-getdescriptorhandleincrementsize"></a>

### ID3D12Device::GetDescriptorHandleIncrementSize

#### Declaration

```cpp
UINT GetDescriptorHandleIncrementSize(
    D3D12_DESCRIPTOR_HEAP_TYPE DescriptorHeapType);
```

#### Behavior

Gets the size of the handle increment for the given type of descriptor heap. This value is typically used to increment a handle into a descriptor array by the correct amount.

#### Parameters

`[in] DescriptorHeapType`

The [`D3D12_DESCRIPTOR_HEAP_TYPE`](#d3d12-descriptor-heap-type)-typed value that specifies the type of descriptor heap to get the size of the handle increment for.

#### Return values

Returns the size of the handle increment for the given type of descriptor heap, including any necessary padding.

<a id="id3d12descriptorheap-getdesc"></a>

### ID3D12DescriptorHeap::GetDesc

#### Declaration

```cpp
D3D12_DESCRIPTOR_HEAP_DESC GetDesc();
```

#### Behavior

Gets the descriptor heap description.

#### Return values

The description of the descriptor heap, as a [`D3D12_DESCRIPTOR_HEAP_DESC`](#d3d12-descriptor-heap-desc) structure.

<a id="id3d12descriptorheap-getcpudescriptorhandleforheapstart"></a>

### ID3D12DescriptorHeap::GetCPUDescriptorHandleForHeapStart

#### Declaration

```cpp
D3D12_CPU_DESCRIPTOR_HANDLE GetCPUDescriptorHandleForHeapStart();
```

#### Behavior

Gets the CPU descriptor handle that represents the start of the heap.

#### Return values

Returns the CPU descriptor handle that represents the start of the heap.

<a id="id3d12descriptorheap-getgpudescriptorhandleforheapstart"></a>

### ID3D12DescriptorHeap::GetGPUDescriptorHandleForHeapStart

#### Declaration

```cpp
D3D12_GPU_DESCRIPTOR_HANDLE GetGPUDescriptorHandleForHeapStart();
```

#### Behavior

Gets the GPU descriptor handle that represents the start of the heap.

#### Return values

Returns the GPU descriptor handle that represents the start of the heap. The heap must be shader-visible. The debug layer reports an error otherwise.

<a id="copy-behavior"></a>

### Shared copy behavior

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

For these descriptor copy methods, source descriptors must come from a
non-shader visible descriptor heap. The destination descriptors can be
in any descriptor heap (shader visible or not).

If either range size array is null, every range in that array has size one. The source and destination totals must match. Source reads must not race with descriptor writes. Destination writes must not conflict with other CPU/GPU accesses.

<a id="id3d12device-copydescriptors"></a>

### ID3D12Device::CopyDescriptors

#### Declaration

```cpp
void CopyDescriptors(
    UINT NumDestDescriptorRanges,
    const D3D12_CPU_DESCRIPTOR_HANDLE* pDestDescriptorRangeStarts,
    const UINT* pDestDescriptorRangeSizes,
    UINT NumSrcDescriptorRanges,
    const D3D12_CPU_DESCRIPTOR_HANDLE* pSrcDescriptorRangeStarts,
    const UINT* pSrcDescriptorRangeSizes,
    D3D12_DESCRIPTOR_HEAP_TYPE DescriptorHeapsType);
```

#### Behavior

Copies descriptors from a source to a destination.

The [shared copy rules](#copy-behavior) apply. This is an immediate CPU operation, not a queued GPU resource copy.

#### Parameters

`[in] NumDestDescriptorRanges`

The number of destination descriptor ranges to copy to.

`[in] pDestDescriptorRangeStarts`

An array of **[`D3D12_CPU_DESCRIPTOR_HANDLE`](#d3d12-cpu-descriptor-handle)** objects to copy to.

All the destination and source descriptors must be in heaps of the same [`D3D12_DESCRIPTOR_HEAP_TYPE`](#d3d12-descriptor-heap-type).

`[in, optional] pDestDescriptorRangeSizes`

An array of destination descriptor range sizes to copy to.

`[in] NumSrcDescriptorRanges`

The number of source descriptor ranges to copy from.

`[in] pSrcDescriptorRangeStarts`

An array of **[`D3D12_CPU_DESCRIPTOR_HANDLE`](#d3d12-cpu-descriptor-handle)** objects to copy from.

Important

All elements in the *pSrcDescriptorRangeStarts* parameter must be in a non shader-visible descriptor heap. This is because shader-visible descriptor heaps may be created in **WRITE\_COMBINE** memory or GPU local memory, which is prohibitively slow to read from. If your application manages descriptor heaps via copying the descriptors required for a given pass or frame from local "storage" descriptor heaps to the GPU-bound descriptor heap, use shader-opaque heaps for the storage heaps and copy into the GPU-visible heap as required.

`[in, optional] pSrcDescriptorRangeSizes`

An array of source descriptor range sizes to copy from.

`[in] DescriptorHeapsType`

The [`D3D12_DESCRIPTOR_HEAP_TYPE`](#d3d12-descriptor-heap-type)-typed value that specifies the type of descriptor heap to copy with. This is required as different descriptor types may have different sizes.

Both the source and destination descriptor heaps must have the same type, else the debug layer will emit an error.

#### Return values

None

<a id="id3d12device-copydescriptorssimple"></a>

### ID3D12Device::CopyDescriptorsSimple

#### Declaration

```cpp
void CopyDescriptorsSimple(
    UINT NumDescriptors,
    D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptorRangeStart,
    D3D12_CPU_DESCRIPTOR_HANDLE SrcDescriptorRangeStart,
    D3D12_DESCRIPTOR_HEAP_TYPE DescriptorHeapsType);
```

#### Behavior

Copies descriptors from a source to a destination.

The [shared copy rules](#copy-behavior) apply. This is an immediate CPU operation, not a queued GPU resource copy.

#### Parameters

`[in] NumDescriptors`

The number of descriptors to copy.

`[in] DestDescriptorRangeStart`

A **[`D3D12_CPU_DESCRIPTOR_HANDLE`](#d3d12-cpu-descriptor-handle)** that describes the destination descriptors to start to copy to.

The destination and source descriptors must be in heaps of the same [`D3D12_DESCRIPTOR_HEAP_TYPE`](#d3d12-descriptor-heap-type).

`[in] SrcDescriptorRangeStart`

A **[`D3D12_CPU_DESCRIPTOR_HANDLE`](#d3d12-cpu-descriptor-handle)** that describes the source descriptors to start to copy from.

Important

The *SrcDescriptorRangeStart* parameter must be in a non shader-visible descriptor heap. This is because shader-visible descriptor heaps may be created in **WRITE\_COMBINE** memory or GPU local memory, which is prohibitively slow to read from. If your application manages descriptor heaps via copying the descriptors required for a given pass or frame from local "storage" descriptor heaps to the GPU-bound descriptor heap, then use shader-opaque heaps for the storage heaps and copy into the GPU-visible heap as required.

`[in] DescriptorHeapsType`

The [`D3D12_DESCRIPTOR_HEAP_TYPE`](#d3d12-descriptor-heap-type)-typed value that specifies the type of descriptor heap to copy with. This is required as different descriptor types may have different sizes.

Both the source and destination descriptor heaps must have the same type, else the debug layer will emit an error.

#### Return values

None

<a id="descriptor-creation"></a>

## Descriptor creation APIs

All methods for creating descriptors are free threaded.

`DestDescriptor` identifies the destination descriptor slot, not necessarily the first slot of a heap. SRV/UAV/CBV creation requires a CBV/SRV/UAV heap, sampler creation a sampler heap, RTV creation an RTV heap, and DSV creation a DSV heap. Destination storage must already exist and remain free of conflicting CPU/GPU accesses. Creating a descriptor does not retain the referenced resource or make it resident.

In order to indirectly bind a Resource to certain stages of the graphics
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
pipeline stage. Resource creation flags impose the applicable view restrictions independently of descriptor binding. Views are represented by descriptors. The [binding contract](#foundations) provides more details about how views/descriptors are accessed by the hardware.

A resource view is distinct from the underlying resource from which the view was
created, so where views are used, the view properties (number of mipmaps, number
of array elements, type, etc.) are always used in place of the properties of the
original resource.  Thus, for example, a render target array index of zero always
indicates the first array element in the view, even if the first array element in
the view is not the first array element in the underlying resource.  Out of range
behaviors are also always with respect to the view properties where views are used.

These methods create descriptors immediately on the CPU at `DestDescriptor`. Creating a view does not allocate backing storage for its resource or synchronize its accesses. Null resource descriptors and null description defaults are both possible in most cases but have different semantics. [Null binding](#null-descriptors) and the parameter rules below provide more details.

The SRV/UAV/RTV/DSV creators don't have an `HRESULT` return, so any validation failures result in device removal, in addition to any debug layer errors that are produced. Device removal status is exposed by `ID3D12Device::GetDeviceRemovedReason`.

<a id="view-descriptions"></a>

`ViewDimension` selects the matching description union member. Texture dimensions must match the resource's kind and sample configuration. Cube views use appropriate groups of faces in 2D arrays. SRVs can select a mip range, while RTVs, DSVs and UAVs select a single mip, while multisampled views do not select a mip level.

Mip and array starts must lie within the resource's corresponding extent. Counts must be nonzero and fit the remaining extent.

For SRV/UAV/RTV/DSV creation, a null `pDesc` requests a default view inferred from the supplied resource, where supported.

When a default description can be inferred from a texture resource, SRV defaults expose its mip chain and applicable array, with identity mapping and zero minimum LOD clamp. Array resources do not implicitly become cube SRVs. RTV/UAV/DSV defaults select mip zero and the applicable array, or all W slices of that mip for 3D RTV/UAVs. Applicable 2D defaults select plane zero, and default DSV flags are NONE. These defaults do not make otherwise unsupported formats or resource kinds valid.

SRV creation requires that the resource not include `D3D12_RESOURCE_FLAG_DENY_SHADER_RESOURCE`. RTV, DSV and UAV creation require `D3D12_RESOURCE_FLAG_ALLOW_RENDER_TARGET`, `D3D12_RESOURCE_FLAG_ALLOW_DEPTH_STENCIL` and `D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS`, respectively. The [resource flag constraints](resources.md#resource-flags) indicate when these flags can be set.

<a id="d3d12-constant-buffer-view-desc"></a>

### D3D12_CONSTANT_BUFFER_VIEW_DESC

```cpp
typedef struct D3D12_CONSTANT_BUFFER_VIEW_DESC
{
    D3D12_GPU_VIRTUAL_ADDRESS BufferLocation;
    UINT SizeInBytes;
} D3D12_CONSTANT_BUFFER_VIEW_DESC;
```

For a non-null `D3D12_CONSTANT_BUFFER_VIEW_DESC`, `BufferLocation` and `SizeInBytes` must each be a multiple of `D3D12_CONSTANT_BUFFER_DATA_PLACEMENT_ALIGNMENT` (256). `SizeInBytes` must not exceed `D3D12_REQ_CONSTANT_BUFFER_ELEMENT_COUNT * 16` bytes (4096 16-byte elements, or 65536 bytes). This size limit is distinct from a root CBV, which supplies only an address and retains the [root CBV access bound](#root-descriptors). A null description creates the unbound descriptor described under [null descriptors](#null-descriptors).

<a id="id3d12device-createconstantbufferview"></a>

### ID3D12Device::CreateConstantBufferView

#### Declaration

```cpp
void CreateConstantBufferView(
    const D3D12_CONSTANT_BUFFER_VIEW_DESC* pDesc,
    D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor);
```

#### Behavior

Creates a constant-buffer view for accessing resource data.

#### Parameters

`[in, optional] pDesc`

A pointer to a [`D3D12_CONSTANT_BUFFER_VIEW_DESC`](#d3d12-constant-buffer-view-desc) structure that describes the constant-buffer view.

`[in] DestDescriptor`

Describes the CPU descriptor handle that represents the descriptor slot that holds the constant-buffer view.

#### Return values

None

<a id="srv-types"></a>

### Shader resource view types

#### D3D12_SRV_DIMENSION

<a id="d3d12-srv-dimension"></a>

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

<a id="d3d12-buffer-srv-flags"></a>

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

<a id="d3d12-tex1d-srv"></a>

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

<a id="acceleration-structure-srv"></a>

#### D3D12_RAYTRACING_ACCELERATION_STRUCTURE_SRV

```cpp
typedef struct D3D12_RAYTRACING_ACCELERATION_STRUCTURE_SRV
{
    D3D12_GPU_VIRTUAL_ADDRESS Location;
} D3D12_RAYTRACING_ACCELERATION_STRUCTURE_SRV;
```

#### D3D12_SHADER_RESOURCE_VIEW_DESC

<a id="d3d12-shader-resource-view-desc"></a>

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

`Format`

The view's [format interpretation](formats.md#interpretation), subject to [casting compatibility](formats.md#casting).

<a id="buffer-view-kinds"></a>

### Buffer view kinds

Buffer SRV and UAV descriptors select one of the following interpretations. These interpretations are view properties rather than buffer creation bind flags. Read-only HLSL forms use SRVs. Read/write and append/consume forms use UAVs. In the flags column, `NONE` and `RAW` refer to the corresponding [`D3D12_BUFFER_SRV_FLAGS`](#d3d12-buffer-srv-flags) or [`D3D12_BUFFER_UAV_FLAGS`](#d3d12-buffer-uav-flags) values.

| Kind | View format | `StructureByteStride` | Flags | Common HLSL declarations | Semantics |
|---|---|---|---|---|---|
| Typed buffer | Supported [typed buffer format](formats.md#support) | 0 | `NONE` | `Buffer<T>`, `RWBuffer<T>` | `FirstElement` and `NumElements` count elements of the view format. The format determines each element's byte size and component interpretation. Shader coordinates select elements relative to the view. Typed loads and stores apply the format's conversions between stored components and shader values. |
| Structured buffer | `DXGI_FORMAT_UNKNOWN` | Nonzero structure stride | `NONE` | `StructuredBuffer<T>`, `RWStructuredBuffer<T>`, `AppendStructuredBuffer<T>`, `ConsumeStructuredBuffer<T>` | `FirstElement` and `NumElements` count structures, each occupying `StructureByteStride` bytes. Shader accesses select a structure and address members within that fixed stride. The shader structure layout must agree with the view's stride. The view does not specify a typed format for the members. Append/consume forms use a [separately associated UAV counter](#id3d12device-createunorderedaccessview). |
| Raw / byte-address buffer | `DXGI_FORMAT_R32_TYPELESS` | 0 | `RAW` | `ByteAddressBuffer`, `RWByteAddressBuffer` | `FirstElement` and `NumElements` count 32-bit elements, selecting a byte range starting at `4 * FirstElement` with length `4 * NumElements`. Shader raw loads and stores use byte offsets relative to that view, rather than format-element or structure indices. The view does not impose a typed numeric interpretation or perform typed-format conversion. Access widths and alignment depend on the shader operation. |

Rasterizer-ordered buffer declarations use the same view kinds, with the additional [rasterizer ordered view contract](pixel-shaders.md#rovs).

Buffer SRVs and UAVs require a nonzero element count and a nonoverflowing byte range within the buffer. Raw view starting addresses must satisfy `D3D12_RAW_UAV_SRV_BYTE_ALIGNMENT` (16 bytes).

<a id="buffer-srv"></a>

### Buffer SRV fields

`FirstElement`

The index of the first element to be accessed by the view.

`NumElements`

The number of elements exposed by the view.

`StructureByteStride`

The size of each element in the buffer structure (in bytes) when the buffer represents a structured buffer. The size must match the struct size declared in shaders that access the view.

`Flags`

A [`D3D12_BUFFER_SRV_FLAGS`](#d3d12-buffer-srv-flags)-typed value that identifies view options for the buffer. Currently, the only option is to identify a raw view of the buffer. See [buffer view kinds](#buffer-view-kinds) for the RAW interpretation.

<a id="texture-srv"></a>

### Texture SRV fields

`MostDetailedMip`

Index of the most detailed mipmap level to use; this number is between 0 and **MipLevels** -1 (where **MipLevels** is from the original Texture2D for which [ID3D12Device::CreateShaderResourceView](#id3d12device-createshaderresourceview) creates a view).

`MipLevels`

The maximum number of mipmap levels for the view of the texture. See the remarks in [`D3D12_TEX1D_SRV`](#d3d12-tex1d-srv).

Set to `UINT_MAX` (-1) to indicate all the mipmap levels from `MostDetailedMip` down to the resource's least detailed mip.

`FirstArraySlice`

The index of the first texture to use in an array of textures.

`ArraySize`

Number of textures in the array.

`UINT_MAX` selects all remaining array slices from `FirstArraySlice`.

`NumCubes`

The number of cubes, each comprising six consecutive 2D array faces. `First2DArrayFace` identifies the first face in the view. `UINT_MAX` selects all remaining cubes from that face.

`PlaneSlice`

The index (plane slice number) of the plane to use in an array of textures.

[`ResourceMinLODClamp`](common-shader-internals.md#resource-lod-clamp)

Specifies the minimum mipmap level that you can access. Specifying 0.0f means that you can access all of the mipmap levels. Specifying 3.0f means that you can access mipmap levels from 3.0f to *MipCount - 1*.

The SRV's `ResourceMinLODClamp` considers the most detailed mipmap on the resource as LOD 0, so specifying a MinLOD clamp of 1 causes miplevel 0 on the resource to be ignored.
On the other hand, the [Sampler’s MinLOD clamp](common-shader-internals.md#sampler-lod-bias-and-clamping) defines most detailed mipmap in the current Shader Resource View as LOD 0.
So on a Shader Resource View that, for example, limits a mipmap chain to exclude the most detailed 3 mips from a resource, setting the Sampler MinLOD to 1
causes miplevel [3] (the fourth mip) in the resource to be ignored.

<a id="component-mapping"></a>

### Component mapping

`Shader4ComponentMapping` allows the SRV to
choose how memory gets routed to the 4 return components in a shader
after a memory fetch. The options for each shader component [0..3]
(RGBA) are: component 0..3 from the SRV fetch result or force 0 or force 1. The value of forcing 1 is either 0x1 or 1.0f depending on the format
type for that component in the source format.

The default 1:1 mapping can be indicated by specifying
`D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING`, otherwise an arbitrary
mapping can be specified using the macro
`D3D12_ENCODE_SHADER_4_COMPONENT_MAPPING`. The encoding macros are shown below.

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

Each of the four three-bit selectors must use a declared `D3D12_SHADER_COMPONENT_MAPPING` value. The always-set bit is required, and bits outside the selectors and that marker must be zero.

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

Raw and structured buffer SRVs must use `D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING`. No ordering is defined between SRV component mapping and [border color selection](common-shader-internals.md#border-color-component-mapping-order). For [comparison sampling](common-shader-internals.md#comparison-component-mapping), the component mapping applies post-comparison intermediate `(result, 0.0f, 0.0f, 1.0f)`, rather than using the mapping to select which source component is compared. For [gather](common-shader-internals.md#gather-component-mapping), SRV component mapping applies independently to each texel tap, not to the packed vector of gathered values.

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

A pointer to the [ID3D12Resource](resources.md#resource-storage) object that represents the shader resource.

At least one of *pResource* or *pDesc* must be provided. Except for acceleration structure SRVs, a null *pResource* initializes a null descriptor with a valid *pDesc* defining its type; see [null descriptors](#null-descriptors) and [acceleration structure SRVs](#acceleration-structure-srv).

For `D3D12_SRV_DIMENSION_RAYTRACING_ACCELERATION_STRUCTURE`, *pResource* must be NULL. The GPU virtual address is supplied in `pDesc->RaytracingAccelerationStructure.Location`.

`[in, optional] pDesc`

A pointer to a [`D3D12_SHADER_RESOURCE_VIEW_DESC`](#d3d12-shader-resource-view-desc) structure that describes the shader-resource view.

A null *pDesc* is used to initialize a default descriptor, if possible. This behavior inherits the resource format and dimension (if not typeless) and for textures SRVs target a full texture, all mips and all array slices. Buffer SRVs require an explicit description; their resource description does not supply a typed view format or structure stride. Not all texture resources support null description initialization.

`[in] DestDescriptor`

Describes the CPU descriptor handle that represents the shader-resource view. This handle can be created in a shader-visible or non-shader-visible descriptor heap.

#### Return values

None

<a id="uav-types"></a>

### Unordered access view types

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

<a id="d3d12-buffer-uav-flags"></a>

```cpp
typedef enum D3D12_BUFFER_UAV_FLAGS
{
    D3D12_BUFFER_UAV_FLAG_NONE =   0,
    D3D12_BUFFER_UAV_FLAG_RAW  =   0x00000001,
} D3D12_BUFFER_UAV_FLAGS;
```

#### D3D12_BUFFER_UAV

<a id="d3d12-buffer-uav"></a>

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

<a id="d3d12-unordered-access-view-desc"></a>

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

`Format`

The view's [format interpretation](formats.md#interpretation), subject to [casting compatibility](formats.md#casting).

<a id="buffer-uav"></a>

### Buffer UAV fields and counters

`FirstElement`

The zero-based index of the first element to be accessed.

`NumElements`

The number of elements exposed by the view. For structured buffers, this is the number of structures in the buffer.

`StructureByteStride`

The size of each element in the buffer structure (in bytes) when the buffer represents a structured buffer.

<a id="uav-counter-offset"></a>

`CounterOffsetInBytes`

The counter offset, in bytes.

A counter is associated by the `pCounterResource` creation parameter, not an APPEND/COUNTER bit in `D3D12_BUFFER_UAV_FLAGS`. `CounterOffsetInBytes` identifies its offset within the counter resource.

When a counter resource is supplied, `CounterOffsetInBytes` must satisfy `D3D12_UAV_COUNTER_PLACEMENT_ALIGNMENT` (4096 bytes) and leave four bytes available in its backing buffer. Both data and counter buffers require UAV permission. With no counter resource, `CounterOffsetInBytes` is zero.

`Flags`

A [`D3D12_BUFFER_UAV_FLAGS`](#d3d12-buffer-uav-flags)-typed value that specifies the view options for the resource. See [buffer view kinds](#buffer-view-kinds) for the RAW interpretation.

<a id="texture-uav"></a>

### Texture UAV fields

#### Array and plane fields

`MipSlice`

The mipmap slice index.

`FirstArraySlice`

The zero-based index of the first array slice to be accessed.

`ArraySize`

The number of slices in the array.

`UINT_MAX` selects all remaining array slices from `FirstArraySlice`.

`PlaneSlice`

The index (plane slice number) of the plane to use in an array of textures.

#### Volume depth slice fields

`MipSlice`

The mipmap slice index.

`FirstWSlice`

The zero-based index of the first depth slice to be accessed.

This index must be less than the depth of the mip selected by `MipSlice`, as defined by the [resource mip dimensions](resources.md#subresources).

`WSize`

The number of depth slices.

The count must be nonzero and fit the depth remaining from `FirstWSlice` in the selected mip. `UINT_MAX` (-1) selects all remaining depth slices from `FirstWSlice`.

<a id="texture-view-dimension-compatibility"></a>

### Shader and texture view dimension compatibility

The following array and non-array texture dimensions are compatible in either direction between a shader declaration and its view:

| Non-array dimension | Array dimension | View types |
|---|---|---|
| Texture1D | Texture1DArray | SRV, UAV |
| Texture2D | Texture2DArray | SRV, UAV |
| Texture2DMS | Texture2DMSArray | SRV, UAV |
| TextureCube | TextureCubeArray | SRV |

For example, `RWTexture2D` and `RWTexture2DArray` shader objects can access either a Texture2D or Texture2DArray UAV.

A non-array shader declaration accesses the first array element exposed by an array view. For example, a `Texture1D` shader object used with a Texture1DArray SRV accesses array index zero within the view, corresponding to the view's `FirstArraySlice` in the resource. Conversely, an array shader declaration used with a non-array view sees an array of one element at index zero. For cube textures, an array element is one cube.

These rules concern the shader declaration and the descriptor, not which views can be created for a resource. The [view-description and format requirements](#view-descriptions), including the texture's multisample configuration and applicable UAV capabilities, remain applicable.

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

Creates an unordered access view.

#### Parameters

`pResource`

A pointer to the [ID3D12Resource](resources.md#resource-storage) object that represents the unordered access.

At least one of *pResource* or *pDesc* must be provided.

A null *pResource* is used to initialize a [null descriptor](#null-descriptors), which guarantees defined null binding behavior (reading 0s, writes are discarded), but must have a valid *pDesc* in order to determine the descriptor type.

`pCounterResource`

The buffer resource supplying the counter, if any. When supplied, the UAV must be a [structured buffer view](#buffer-view-kinds) and cannot be a [null descriptor](#null-descriptors). The counter offset and resource requirements are defined under [`CounterOffsetInBytes`](#uav-counter-offset).

`pDesc`

A pointer to a [`D3D12_UNORDERED_ACCESS_VIEW_DESC`](#d3d12-unordered-access-view-desc) structure that describes the unordered-access view.

A null *pDesc* is used to initialize a default descriptor, if possible. This behavior inherits the resource format and dimension (if not typeless) and for textures UAVs target the first mip and all array slices. Buffer UAVs require an explicit description; their resource description does not supply a typed view format or structure stride. Not all texture resources support null description initialization.

`[in] DestDescriptor`

Describes the CPU descriptor handle that represents the descriptor slot that holds the unordered-access view.

#### Return values

None

<a id="sampler-feedback-descriptors"></a>

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

At least one of `pTargetedResource` and `pFeedbackResource` must be non-null. When both are present, their logical width, height, mip count and array size must match the feedback pairing requirements. The feedback resource uses one of the opaque sampler feedback formats, see [feedback resource creation](resources.md#extended-description). `D3D12_FEATURE_DATA_D3D12_OPTIONS7.SamplerFeedbackTier` must report sampler feedback support, as defined by the [feature capability](common-shader-internals.md#feedback-capability-tiers). A permitted null resource parameter is not an uninitialized descriptor binding.

Feedback map UAVs may be created against a NULL paired texture. Writes through a feedback UAV descriptor created with a NULL paired texture have no effect.

#### Parameters

`pTargetedResource`

The targeted resource, such as a texture, to create a descriptor for.

`pFeedbackResource`

The feedback resource, such as a texture, to create a descriptor for.

`DestDescriptor`

The CPU descriptor handle.

#### Return values

This method does not return a value.

<a id="rtv-types"></a>

### Render target view types and fields

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

<a id="d3d12-render-target-view-desc"></a>

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

`Format`

The view's [format interpretation](formats.md#interpretation), subject to [casting compatibility](formats.md#casting).

#### Buffer RTV fields

`FirstElement`

Number of elements between the beginning of the buffer and the first element to access.

`NumElements`

The total number of elements in the view.

A buffer RTV's `NumElements` must not exceed `D3D12_REQ_TEXTURE1D_U_DIMENSION` (16384), even when the backing buffer is larger. `FirstElement` and `NumElements` still define a valid typed element range within that buffer.

#### Array and plane RTV fields

`MipSlice`

The index of the mipmap level to use.

`FirstArraySlice`

The index of the first texture to use in an array of textures.

`ArraySize`

Number of textures in the array to use in the render target view, starting from **FirstArraySlice**.

`UINT_MAX` selects all remaining array slices from `FirstArraySlice`.

`PlaneSlice`

The index (plane slice number) of the plane to use in an array of textures.

#### Volume depth slice RTV fields

`MipSlice`

The index of the mipmap level to use.

`FirstWSlice`

First depth level to use.

This is a depth slice index in the mip selected by `MipSlice`. It must be less than that mip's depth, as defined by the [resource mip dimensions](resources.md#subresources).

`WSize`

Number of depth levels to use in the render-target view, starting from **FirstWSlice**.

The count must be nonzero and fit the depth remaining from `FirstWSlice` in the selected mip. `UINT_MAX` (-1) selects all remaining depth slices from `FirstWSlice`.

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

A pointer to the [ID3D12Resource](resources.md#resource-storage) object that represents the render target.

At least one of *pResource* or *pDesc* must be provided. A null *pResource* is used to initialize a [null descriptor](#null-descriptors), which guarantees defined null binding behavior (reading 0s, writes are discarded), but must have a valid *pDesc* in order to determine the descriptor type.

`[in, optional] pDesc`

A pointer to a [`D3D12_RENDER_TARGET_VIEW_DESC`](#d3d12-render-target-view-desc) structure that describes the render-target view.

A null *pDesc* is used to initialize a default descriptor, if possible. This behavior inherits the resource format and dimension (if not typeless) and RTVs target the first mip and all array slices. Not all resources support null description initialization.

`[in] DestDescriptor`

Describes the CPU descriptor handle that represents the destination where the newly-created render target view will reside.

#### Return values

None

<a id="dsv-types"></a>

### Depth-stencil view types and fields


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

<a id="d3d12-dsv-flags"></a>

```cpp
typedef enum D3D12_DSV_FLAGS
{
    D3D12_DSV_FLAG_NONE              = 0x0,
    D3D12_DSV_FLAG_READ_ONLY_DEPTH   = 0x1,
    D3D12_DSV_FLAG_READ_ONLY_STENCIL = 0x2,
} D3D12_DSV_FLAGS;
```

Depth/stencil view flags participate in the [output merger read-only write controls](output-merger.md#read-only-depth-stencil). [Render pass read-only binding](output-merger.md#read-only-depth-stencil-pass) has additional flag/access conditions.

`D3D12_DSV_FLAG_READ_ONLY_DEPTH` and `D3D12_DSV_FLAG_READ_ONLY_STENCIL` independently prohibit writes to their components. They do not select a different physical plane or change resource access/layout requirements. A read-only DSV can coexist with compatible SRV access to the read-only aspect when [synchronization requirements](synchronization.md#foundations) are satisfied. There is still only one output merger DSV binding.

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

<a id="d3d12-depth-stencil-view-desc"></a>

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

`Format`

The view's [format interpretation](formats.md#interpretation), subject to [casting compatibility](formats.md#casting).

`MipSlice`

The index of the first mipmap level to use.

`FirstArraySlice`

The index of the first texture to use in an array of textures.

`ArraySize`

Number of textures to use.

`UINT_MAX` selects all remaining array slices from `FirstArraySlice`.

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

A pointer to the [ID3D12Resource](resources.md#resource-storage) object that represents the depth stencil.

At least one of *pResource* or *pDesc* must be provided. A null *pResource* is used to initialize a [null descriptor](#null-descriptors), which guarantees defined null binding behavior (reading 0s, writes are discarded), but must have a valid *pDesc* in order to determine the descriptor type.

`[in, optional] pDesc`

A pointer to a [`D3D12_DEPTH_STENCIL_VIEW_DESC`](#d3d12-depth-stencil-view-desc) structure that describes the depth-stencil view.

A null *pDesc* is used to initialize a default descriptor, if possible. This behavior inherits the resource format and dimension (if not typeless) and DSVs target the first mip and all array slices. Not all resources support null description initialization.

`[in] DestDescriptor`

Describes the CPU descriptor handle that represents the descriptor slot that holds the depth-stencil view.

#### Return values

None

<a id="id3d12device-createsampler"></a>

### ID3D12Device::CreateSampler

#### Declaration

```cpp
void CreateSampler(
    const D3D12_SAMPLER_DESC* pDesc,
    D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor);
```

#### Behavior

Create a sampler object that encapsulates sampling information for a texture.

#### Parameters

`[in] pDesc`

A pointer to a [`D3D12_SAMPLER_DESC`](#d3d12-sampler-desc) structure that describes the sampler.

`[in] DestDescriptor`

Describes the CPU descriptor handle that represents the descriptor slot that holds the sampler.

#### Return values

None

<a id="id3d12device11-createsampler2"></a>

### ID3D12Device11::CreateSampler2

#### Declaration

```cpp
void CreateSampler2(
    const D3D12_SAMPLER_DESC2* pDesc,
    D3D12_CPU_DESCRIPTOR_HANDLE DestDescriptor);
```

#### Behavior

Creates a sampler at `DestDescriptor` from `pDesc`, using `D3D12_SAMPLER_DESC2` to select floating-point or integer border colors and sampler flags. [Sampler requirements](#samplers) apply.

#### Parameters

`pDesc` points to the sampler description. Its fields and flags follow the [sampler contract](#samplers). `DestDescriptor` selects a slot in a sampler heap as defined by the [shared destination requirements](#descriptor-creation).

#### Return values

This method does not return a value.

<a id="root-apis"></a>

## Root signature creation and serialization APIs

<ins><!-- d3d12-review-inline:begin:binding:B-create-signature:0 -->Root signatures are a complex data structure containing nested
structures. These can be defined programmatically using the [description structures](#signature-descriptions). Alternatively they can be authored in HLSL --
giving the advantage that the compiler will validate early that the
layout is compatible with the shader. (see the [root signature language](../ResourceBinding.md#hlsl-root-signature-language)).<!-- d3d12-review-inline:end:binding:B-create-signature:0 --></ins>

<ins><!-- d3d12-review-inline:begin:binding:B-create-signature:1 -->The API for creating a root signature takes in a serialized (self
contained, pointer free) version of the layout description. `D3D12SerializeVersionedRootSignature` generates this serialized version
from the C++ data structure, but another way to obtain a serialized root
signature definition is to retrieve it from a shader that has been
compiled with a root signature. The [root signature language](../ResourceBinding.md#hlsl-root-signature-language) also supports pre-authoring root signatures.<!-- d3d12-review-inline:end:binding:B-create-signature:1 --></ins>

<a id="id3d12device-createrootsignature"></a>

### ID3D12Device::CreateRootSignature

#### Declaration

```cpp
HRESULT CreateRootSignature(
    UINT nodeMask,
    const void* pBlobWithRootSignature,
    SIZE_T blobLengthInBytes,
    REFIID riid,
    void** ppvRootSignature);
```

#### Behavior

Creates a root signature layout.

<!-- d3d12-review-alert:begin:binding:N-id3d12device-createrootsignature:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The serialized blob contains the versioned root signature definition. Shader blobs containing an embedded root signature are also accepted. The resulting object is an `ID3D12RootSignature`. [Pipeline compatibility](#pipeline-compatibility) remains a separate requirement.

<!-- d3d12-review-alert:end:binding:N-id3d12device-createrootsignature:0 -->

#### Parameters

`[in] nodeMask`

For single GPU operation, set this to zero. If there are multiple GPU nodes, set bits to identify the nodes (the device's physical adapters) to which the root signature is to apply. Each bit in the mask corresponds to a single node. Refer to [Adapter identity and linked nodes](devices-and-capabilities.md#identity).

`[in] pBlobWithRootSignature`

A pointer to the source data for the serialized signature.

`[in] blobLengthInBytes`

The size, in bytes, of the block of memory that *pBlobWithRootSignature* points to.

`riid`

<ins><!-- d3d12-review-inline:begin:binding:Q-id3d12device-createrootsignature:8 -->The globally unique identifier (**GUID**) for the root signature interface. An input parameter.<!-- d3d12-review-inline:end:binding:Q-id3d12device-createrootsignature:8 --></ins>

`[out] ppvRootSignature`

A pointer to a memory block that receives a pointer to the root signature.

#### Return values

Returns **S\_OK** if successful; otherwise, returns one of the [Direct3D 12 Return Codes](devices-and-capabilities.md#api-result-codes).

This method returns **E\_INVALIDARG** if the blob that *pBlobWithRootSignature* points to is invalid.

<a id="d3d12serializerootsignature"></a>

### D3D12SerializeRootSignature

#### Declaration

```cpp
HRESULT WINAPI D3D12SerializeRootSignature(
    const D3D12_ROOT_SIGNATURE_DESC* pRootSignature,
    D3D_ROOT_SIGNATURE_VERSION Version,
    ID3DBlob** ppBlob,
    ID3DBlob** ppErrorBlob);
```

#### Behavior

Serializes a root signature version 1.0 that can be passed to [ID3D12Device::CreateRootSignature](#id3d12device-createrootsignature).

#### Parameters

`[in] pRootSignature`

<ins><!-- d3d12-review-inline:begin:binding:Q-d3d12serializerootsignature:2 -->The description of the root signature, as a pointer to a [`D3D12_ROOT_SIGNATURE_DESC`](#d3d12-root-signature-desc) structure.<!-- d3d12-review-inline:end:binding:Q-d3d12serializerootsignature:2 --></ins>

`[in] Version`

<ins><!-- d3d12-review-inline:begin:binding:Q-d3d12serializerootsignature:4 -->A [`D3D_ROOT_SIGNATURE_VERSION`](#d3d-root-signature-version)-typed value that specifies the version of root signature.<!-- d3d12-review-inline:end:binding:Q-d3d12serializerootsignature:4 --></ins>

`[out] ppBlob`

A pointer to a memory block that receives a pointer to the [ID3DBlob](devices-and-capabilities.md#binary-data-blobs) interface that you can use to access the serialized root signature.

`[out, optional] ppErrorBlob`

A pointer to a memory block that receives a pointer to the [ID3DBlob](devices-and-capabilities.md#binary-data-blobs) interface that you can use to access serializer error messages, or **NULL** if there are no errors.

#### Return values

Returns **S\_OK** if successful; otherwise, returns one of the [Direct3D 12 Return Codes](devices-and-capabilities.md#api-result-codes).

<a id="d3d12serializeversionedrootsignature"></a>

### D3D12SerializeVersionedRootSignature

#### Declaration

```cpp
HRESULT WINAPI D3D12SerializeVersionedRootSignature(
    const D3D12_VERSIONED_ROOT_SIGNATURE_DESC* pRootSignature,
    ID3DBlob** ppBlob,
    ID3DBlob** ppErrorBlob);
```

#### Behavior

Serializes a root signature of any version that can be passed to [ID3D12Device::CreateRootSignature](#id3d12device-createrootsignature).

<!-- d3d12-review-alert:begin:binding:D126-compiler-root-serialization-forward:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The separate compiler host export [D3D12CompilerSerializeVersionedRootSignature](offline-compilation.md#d3d12compilerserializeversionedrootsignature) defines offline serialization and its compiler host validation context. It is not an alias of this runtime export. Serialization alone does not establish device creation support.

<!-- d3d12-review-alert:end:binding:D126-compiler-root-serialization-forward:0 -->

<!-- d3d12-review-alert:begin:binding:D131-compiler-root-inputs:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> [Offline compilation inputs](compiler-invocation-and-cache-output.md#input-ownership) define how serialized roots and shader-embedded roots are consumed without live device root signature objects. Root contents, shader compatibility and ordinary device root creation remain subject to this chapter.

<!-- d3d12-review-alert:end:binding:D131-compiler-root-inputs:0 -->

#### Parameters

`[in] pRootSignature`

<ins><!-- d3d12-review-inline:begin:binding:Q-d3d12serializeversionedrootsignature:2 -->Specifies a [`D3D12_VERSIONED_ROOT_SIGNATURE_DESC`](#d3d12-versioned-root-signature-desc) that contains a description of any version of a root signature.<!-- d3d12-review-inline:end:binding:Q-d3d12serializeversionedrootsignature:2 --></ins>

`[out] ppBlob`

A pointer to a memory block that receives a pointer to the [ID3DBlob](devices-and-capabilities.md#binary-data-blobs) interface that you can use to access the serialized root signature.

`[out, optional] ppErrorBlob`

A pointer to a memory block that receives a pointer to the [ID3DBlob](devices-and-capabilities.md#binary-data-blobs) interface that you can use to access serializer error messages, or **NULL** if there are no errors.

#### Return values

Returns **S\_OK** if successful; otherwise, returns one of the [Direct3D 12 Return Codes](devices-and-capabilities.md#api-result-codes).

<a id="d3d12createrootsignaturedeserializer"></a>

### D3D12CreateRootSignatureDeserializer

#### Declaration

```cpp
HRESULT WINAPI D3D12CreateRootSignatureDeserializer(
    LPCVOID pSrcData,
    SIZE_T SrcDataSizeInBytes,
    REFIID pRootSignatureDeserializerInterface,
    void** ppRootSignatureDeserializer);
```

#### Behavior

<ins><!-- d3d12-review-inline:begin:binding:P-d3d12createrootsignaturedeserializer:0 -->Deserializes a root signature so you can determine the layout definition ([`D3D12_ROOT_SIGNATURE_DESC`](#d3d12-root-signature-desc)).<!-- d3d12-review-inline:end:binding:P-d3d12createrootsignaturedeserializer:0 --></ins>

#### Parameters

`[in] pSrcData`

A pointer to the source data for the serialized root signature.

`[in] SrcDataSizeInBytes`

The size, in bytes, of the block of memory that *pSrcData* points to.

`[in] pRootSignatureDeserializerInterface`

<ins><!-- d3d12-review-inline:begin:binding:Q-d3d12createrootsignaturedeserializer:6 -->The globally unique identifier (**GUID**) for the root signature deserializer interface.<!-- d3d12-review-inline:end:binding:Q-d3d12createrootsignaturedeserializer:6 --></ins>

`[out] ppRootSignatureDeserializer`

A pointer to a memory block that receives a pointer to the root signature deserializer.

#### Return values

Returns **S\_OK** if successful; otherwise, returns one of the [Direct3D 12 Return Codes](devices-and-capabilities.md#api-result-codes).

<a id="d3d12createversionedrootsignaturedeserializer"></a>

### D3D12CreateVersionedRootSignatureDeserializer

#### Declaration

```cpp
HRESULT WINAPI D3D12CreateVersionedRootSignatureDeserializer(
    LPCVOID pSrcData,
    SIZE_T SrcDataSizeInBytes,
    REFIID pRootSignatureDeserializerInterface,
    void** ppRootSignatureDeserializer);
```

#### Behavior

Generates an interface that can return the deserialized data structure, via [GetUnconvertedRootSignatureDesc](#id3d12versionedrootsignaturedeserializer-getunconvertedrootsignaturedesc).

#### Parameters

`[in] pSrcData`

A pointer to the source data for the serialized root signature.

`[in] SrcDataSizeInBytes`

The size, in bytes, of the block of memory that *pSrcData* points to.

`[in] pRootSignatureDeserializerInterface`

<ins><!-- d3d12-review-inline:begin:binding:Q-d3d12createversionedrootsignaturedeserializer:6 -->The globally unique identifier (**GUID**) for the root signature deserializer interface.<!-- d3d12-review-inline:end:binding:Q-d3d12createversionedrootsignaturedeserializer:6 --></ins>

`[out] ppRootSignatureDeserializer`

A pointer to a memory block that receives a pointer to the root signature deserializer.

#### Return values

Returns **S\_OK** if successful; otherwise, returns one of the [Direct3D 12 Return Codes](devices-and-capabilities.md#api-result-codes).

<!-- d3d12-review-alert:begin:binding:N-serialized-version:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12SerializeRootSignature` accepts version 1.0 descriptions and requires `Version` to select 1.0. The versioned serializer uses the description's `Version` discriminant. Serialization validates and encodes a description. It does not create a device root signature object or establish device support.

<!-- d3d12-review-alert:end:binding:N-serialized-version:0 -->

<a id="id3d12rootsignaturedeserializer-getrootsignaturedesc"></a>

### ID3D12RootSignatureDeserializer::GetRootSignatureDesc

#### Declaration

```cpp
const D3D12_ROOT_SIGNATURE_DESC * GetRootSignatureDesc();
```

#### Behavior

Gets the layout of the root signature.

#### Return values

<ins><!-- d3d12-review-inline:begin:binding:Q-id3d12rootsignaturedeserializer-getrootsignaturedesc:1 -->This method returns a deserialized root signature in a [`D3D12_ROOT_SIGNATURE_DESC`](#d3d12-root-signature-desc) structure that describes the layout of the root signature.<!-- d3d12-review-inline:end:binding:Q-id3d12rootsignaturedeserializer-getrootsignaturedesc:1 --></ins>

<a id="id3d12versionedrootsignaturedeserializer-getrootsignaturedescatversion"></a>

### ID3D12VersionedRootSignatureDeserializer::GetRootSignatureDescAtVersion

#### Declaration

```cpp
HRESULT GetRootSignatureDescAtVersion(
    D3D_ROOT_SIGNATURE_VERSION convertToVersion,
    const D3D12_VERSIONED_ROOT_SIGNATURE_DESC** ppDesc);
```

#### Behavior

Converts root signature description structures to a requested version.

#### Parameters

`convertToVersion`

<ins><!-- d3d12-review-inline:begin:binding:Q-id3d12versionedrootsignaturedeserializer-getrootsignaturedescatversion:2 -->Specifies the required [`D3D_ROOT_SIGNATURE_VERSION`](#d3d-root-signature-version).<!-- d3d12-review-inline:end:binding:Q-id3d12versionedrootsignaturedeserializer-getrootsignaturedescatversion:2 --></ins>

`[out] ppDesc`

<ins><!-- d3d12-review-inline:begin:binding:Q-id3d12versionedrootsignaturedeserializer-getrootsignaturedescatversion:4 -->Contains the deserialized root signature in a [`D3D12_VERSIONED_ROOT_SIGNATURE_DESC`](#d3d12-versioned-root-signature-desc) structure.<!-- d3d12-review-inline:end:binding:Q-id3d12versionedrootsignaturedeserializer-getrootsignaturedescatversion:4 --></ins>

#### Return values

This method returns an HRESULT success or error code. The method can fail with E\_OUTOFMEMORY.

<a id="id3d12versionedrootsignaturedeserializer-getunconvertedrootsignaturedesc"></a>

### ID3D12VersionedRootSignatureDeserializer::GetUnconvertedRootSignatureDesc

#### Declaration

```cpp
const D3D12_VERSIONED_ROOT_SIGNATURE_DESC* GetUnconvertedRootSignatureDesc();
```

#### Behavior

Gets the layout of the root signature, without converting between root signature versions.

#### Return values

<ins><!-- d3d12-review-inline:begin:binding:Q-id3d12versionedrootsignaturedeserializer-getunconvertedrootsignaturedesc:1 -->This method returns a deserialized root signature in a [`D3D12_VERSIONED_ROOT_SIGNATURE_DESC`](#d3d12-versioned-root-signature-desc) structure that describes the layout of the root signature.<!-- d3d12-review-inline:end:binding:Q-id3d12versionedrootsignaturedeserializer-getunconvertedrootsignaturedesc:1 --></ins>

<!-- d3d12-review-alert:begin:binding:N-conversion:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returned description memory is owned by the deserializer. Conversions retain both the original description and converted versions until that object is destroyed. Version 1.0 to 1.1 conversion adds flags matching 1.0 volatility semantics; 1.1 to 1.0 drops descriptor range and root descriptor flags. This does not authorize an application to violate either version's requirements. Version 1.2 sampler flags cannot be assumed representable by earlier sampler descriptions.

<!-- d3d12-review-alert:end:binding:N-conversion:0 -->

<a id="pipeline-compatibility"></a>

### Pipeline compatibility

<ins><!-- d3d12-review-inline:begin:binding:B-pipeline:0 -->Pipeline state creation takes an optional
ID3D12RootSignature* as an input parameter.<!-- d3d12-review-inline:end:binding:B-pipeline:0 --></ins>

<ins><!-- d3d12-review-inline:begin:binding:B-pipeline:1 -->If a root signature is passed into pipeline state creation, this root
signature is validated against all the shaders in the pipeline state for
compatibility and given to the driver to use with all the shaders. If
any of the shaders has a different root signature in it, it gets
replaced by the root signature passed in at the API.<!-- d3d12-review-inline:end:binding:B-pipeline:1 --></ins>

<ins><!-- d3d12-review-inline:begin:binding:B-pipeline:2 -->If no explicit root signature is passed to pipeline state creation, at least one selected shader must supply an embedded root signature. Embedded root signatures that are supplied must match; selected stages without an embedded signature are checked for compatibility with the discovered signature.<!-- d3d12-review-inline:end:binding:B-pipeline:2 --></ins>

<ins><!-- d3d12-review-inline:begin:binding:B-pipeline:3 -->Setting a pipeline state on a command list or bundle does not change the
root signature. That is accomplished by the [root signature setters](#binding-apis). By the time
Draw*()/Dispatch*() is invoked, the application must ensure that the
current pipeline state matches the current root signature, otherwise
behavior is undefined.<!-- d3d12-review-inline:end:binding:B-pipeline:3 --></ins>

<!-- d3d12-review-alert:begin:binding:N-indirect-canonical-owner:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Indirect root argument changes use [command signature parameter validation](indirect-execution.md#signature-validation). At execution, the selected root signature must [match the signature-associated root signature](indirect-execution.md#execute-debug). That requirement is distinct from pipeline/root compatibility.

<!-- d3d12-review-alert:end:binding:N-indirect-canonical-owner:0 -->

<a id="binding-apis"></a>

## Command list binding APIs

<a id="root-setter-parameters"></a>

### Shared setter parameters and recording rules

<!-- d3d12-review-alert:begin:binding:N-setter-rules:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `SetDescriptorHeaps` and the root setters return `void`. Graphics setters apply to DIRECT/BUNDLE recordings. Compute setters apply to DIRECT/BUNDLE/COMPUTE recordings. `RootParameterIndex` is the zero-based parameter index in the corresponding current root signature and must select the appropriate table/constants/CBV/SRV/UAV parameter type. All accesses must satisfy the signature's visibility, capability, bounds, and lifetime requirements. Initial validity, invalidation, and bundle inheritance are defined in [recording state](#recording-state).

<!-- d3d12-review-alert:end:binding:N-setter-rules:0 -->

<a id="id3d12graphicscommandlist-setdescriptorheaps"></a>

### ID3D12GraphicsCommandList::SetDescriptorHeaps

#### Declaration

```cpp
void SetDescriptorHeaps(
    UINT NumDescriptorHeaps,
    ID3D12DescriptorHeap* const* ppDescriptorHeaps);
```

#### Behavior

<!-- d3d12-review-alert:begin:binding:N-id3d12graphicscommandlist-setdescriptorheaps:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Replaces the complete current shader-visible heap set with `NumDescriptorHeaps` entries from `ppDescriptorHeaps`. Zero unsets all heaps; at most one CBV/SRV/UAV heap and one sampler heap may be selected. The [canonical heap change and bundle rules](command-list-state.md#binding-changes) and [direct-indexing order](command-list-state.md#direct-heaps) apply.

<!-- d3d12-review-alert:end:binding:N-id3d12graphicscommandlist-setdescriptorheaps:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:binding:N-parameters-id3d12graphicscommandlist-setdescriptorheaps:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `NumDescriptorHeaps` gives the number of entries in `ppDescriptorHeaps`. Each entry must be a non-null shader-visible heap of a distinct bindable type. Zero entries unsets all current heaps. [Bundle heap matching](command-list-state.md#bundle-bindings) remains required.

<!-- d3d12-review-alert:end:binding:N-parameters-id3d12graphicscommandlist-setdescriptorheaps:0 -->

#### Return values

<!-- d3d12-review-alert:begin:binding:N-return-id3d12graphicscommandlist-setdescriptorheaps:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:binding:N-return-id3d12graphicscommandlist-setdescriptorheaps:0 -->

<a id="id3d12graphicscommandlist-setgraphicsrootsignature"></a>

### ID3D12GraphicsCommandList::SetGraphicsRootSignature

#### Declaration

```cpp
void SetGraphicsRootSignature(
    ID3D12RootSignature* pRootSignature);
```

#### Behavior

<!-- d3d12-review-alert:begin:binding:N-id3d12graphicscommandlist-setgraphicsrootsignature:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Sets `pRootSignature` as the graphics root signature. Changing it invalidates prior arguments. Redundantly setting the same signature preserves them. A null pointer unsets that root signature. Compatibility is required when work executes. See [pipeline compatibility](#pipeline-compatibility) and [canonical binding changes](command-list-state.md#binding-changes).

<!-- d3d12-review-alert:end:binding:N-id3d12graphicscommandlist-setgraphicsrootsignature:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:binding:N-parameters-id3d12graphicscommandlist-setgraphicsrootsignature:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pRootSignature` is the root signature to select for the named graphics/compute bind set, or null to unset it. The [shared recording state rules](#recording-state) define invalidation and inheritance.

<!-- d3d12-review-alert:end:binding:N-parameters-id3d12graphicscommandlist-setgraphicsrootsignature:0 -->

#### Return values

<!-- d3d12-review-alert:begin:binding:N-return-id3d12graphicscommandlist-setgraphicsrootsignature:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:binding:N-return-id3d12graphicscommandlist-setgraphicsrootsignature:0 -->

<a id="id3d12graphicscommandlist-setgraphicsrootdescriptortable"></a>

### ID3D12GraphicsCommandList::SetGraphicsRootDescriptorTable

#### Declaration

```cpp
void SetGraphicsRootDescriptorTable(
    UINT RootParameterIndex,
    D3D12_GPU_DESCRIPTOR_HANDLE BaseDescriptor);
```

#### Behavior

<!-- d3d12-review-alert:begin:binding:N-id3d12graphicscommandlist-setgraphicsrootdescriptortable:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Sets the descriptor table parameter at `RootParameterIndex` to `BaseDescriptor`, a GPU handle in the currently selected shader-visible heap of the matching type. The table's ranges, offsets, [initialization requirements](#table-initialization), and [static promises](#static-promises) apply.

<!-- d3d12-review-alert:end:binding:N-id3d12graphicscommandlist-setgraphicsrootdescriptortable:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:binding:N-parameters-id3d12graphicscommandlist-setgraphicsrootdescriptortable:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `RootParameterIndex` follows the [shared setter parameter contract](#root-setter-parameters). `BaseDescriptor` identifies the beginning of the table relative to which its declared descriptor range offsets are applied. It must belong to the matching current shader-visible heap.

<!-- d3d12-review-alert:end:binding:N-parameters-id3d12graphicscommandlist-setgraphicsrootdescriptortable:0 -->

#### Return values

<!-- d3d12-review-alert:begin:binding:N-return-id3d12graphicscommandlist-setgraphicsrootdescriptortable:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:binding:N-return-id3d12graphicscommandlist-setgraphicsrootdescriptortable:0 -->

<a id="id3d12graphicscommandlist-setgraphicsroot32bitconstant"></a>

### ID3D12GraphicsCommandList::SetGraphicsRoot32BitConstant

#### Declaration

```cpp
void SetGraphicsRoot32BitConstant(
    UINT RootParameterIndex,
    UINT SrcData,
    UINT DestOffsetIn32BitValues);
```

#### Behavior

<!-- d3d12-review-alert:begin:binding:N-id3d12graphicscommandlist-setgraphicsroot32bitconstant:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Writes the 32-bit `SrcData` value to `DestOffsetIn32BitValues` within the root constant parameter at `RootParameterIndex`. Other constants remain unchanged. The destination must fit the parameter's declared `Num32BitValues`.

<!-- d3d12-review-alert:end:binding:N-id3d12graphicscommandlist-setgraphicsroot32bitconstant:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:binding:N-parameters-id3d12graphicscommandlist-setgraphicsroot32bitconstant:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `RootParameterIndex` follows the [shared setter parameter contract](#root-setter-parameters). `SrcData` supplies one 32-bit value. `DestOffsetIn32BitValues` is its destination DWORD offset within that parameter.

<!-- d3d12-review-alert:end:binding:N-parameters-id3d12graphicscommandlist-setgraphicsroot32bitconstant:0 -->

#### Return values

<!-- d3d12-review-alert:begin:binding:N-return-id3d12graphicscommandlist-setgraphicsroot32bitconstant:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:binding:N-return-id3d12graphicscommandlist-setgraphicsroot32bitconstant:0 -->

<a id="id3d12graphicscommandlist-setgraphicsroot32bitconstants"></a>

### ID3D12GraphicsCommandList::SetGraphicsRoot32BitConstants

#### Declaration

```cpp
void SetGraphicsRoot32BitConstants(
    UINT RootParameterIndex,
    UINT Num32BitValuesToSet,
    const void* pSrcData,
    UINT DestOffsetIn32BitValues);
```

#### Behavior

<!-- d3d12-review-alert:begin:binding:N-id3d12graphicscommandlist-setgraphicsroot32bitconstants:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Copies `Num32BitValuesToSet` 32-bit values from `pSrcData` into the root constant parameter at `RootParameterIndex`, starting at `DestOffsetIn32BitValues`. The destination span must fit `Num32BitValues`. Other constants remain unchanged. The source values are captured during recording.

<!-- d3d12-review-alert:end:binding:N-id3d12graphicscommandlist-setgraphicsroot32bitconstants:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:binding:N-parameters-id3d12graphicscommandlist-setgraphicsroot32bitconstants:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `RootParameterIndex` follows the [shared setter parameter contract](#root-setter-parameters). `pSrcData` supplies `Num32BitValuesToSet` 32-bit values. `DestOffsetIn32BitValues` gives their starting DWORD offset within that parameter.

<!-- d3d12-review-alert:end:binding:N-parameters-id3d12graphicscommandlist-setgraphicsroot32bitconstants:0 -->

#### Return values

<!-- d3d12-review-alert:begin:binding:N-return-id3d12graphicscommandlist-setgraphicsroot32bitconstants:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:binding:N-return-id3d12graphicscommandlist-setgraphicsroot32bitconstants:0 -->

<a id="id3d12graphicscommandlist-setgraphicsrootconstantbufferview"></a>

### ID3D12GraphicsCommandList::SetGraphicsRootConstantBufferView

#### Declaration

```cpp
void SetGraphicsRootConstantBufferView(
    UINT RootParameterIndex,
    D3D12_GPU_VIRTUAL_ADDRESS BufferLocation);
```

#### Behavior

<!-- d3d12-review-alert:begin:binding:N-id3d12graphicscommandlist-setgraphicsrootconstantbufferview:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Sets `BufferLocation` as the GPU virtual address for the CBV root descriptor parameter at `RootParameterIndex`. This is not a descriptor heap handle. [Root descriptor](#root-descriptors) resource kind, bounds, alignment and null address restrictions apply.

<!-- d3d12-review-alert:end:binding:N-id3d12graphicscommandlist-setgraphicsrootconstantbufferview:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:binding:N-parameters-id3d12graphicscommandlist-setgraphicsrootconstantbufferview:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `RootParameterIndex` follows the [shared setter parameter contract](#root-setter-parameters). `BufferLocation` supplies the resource data's GPU virtual address, subject to the [root descriptor address requirements](#root-descriptors).

<!-- d3d12-review-alert:end:binding:N-parameters-id3d12graphicscommandlist-setgraphicsrootconstantbufferview:0 -->

#### Return values

<!-- d3d12-review-alert:begin:binding:N-return-id3d12graphicscommandlist-setgraphicsrootconstantbufferview:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:binding:N-return-id3d12graphicscommandlist-setgraphicsrootconstantbufferview:0 -->

<a id="id3d12graphicscommandlist-setgraphicsrootshaderresourceview"></a>

### ID3D12GraphicsCommandList::SetGraphicsRootShaderResourceView

#### Declaration

```cpp
void SetGraphicsRootShaderResourceView(
    UINT RootParameterIndex,
    D3D12_GPU_VIRTUAL_ADDRESS BufferLocation);
```

#### Behavior

<!-- d3d12-review-alert:begin:binding:N-id3d12graphicscommandlist-setgraphicsrootshaderresourceview:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Sets `BufferLocation` as the GPU virtual address for the SRV root descriptor parameter at `RootParameterIndex`. This is not a descriptor heap handle. [Root descriptor](#root-descriptors) resource kind, bounds, alignment and null address restrictions apply. SRVs also have the [acceleration structure case](#acceleration-structure-srvs).

<!-- d3d12-review-alert:end:binding:N-id3d12graphicscommandlist-setgraphicsrootshaderresourceview:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:binding:N-parameters-id3d12graphicscommandlist-setgraphicsrootshaderresourceview:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `RootParameterIndex` follows the [shared setter parameter contract](#root-setter-parameters). `BufferLocation` supplies the resource data's GPU virtual address, subject to the [root descriptor address requirements](#root-descriptors).

<!-- d3d12-review-alert:end:binding:N-parameters-id3d12graphicscommandlist-setgraphicsrootshaderresourceview:0 -->

#### Return values

<!-- d3d12-review-alert:begin:binding:N-return-id3d12graphicscommandlist-setgraphicsrootshaderresourceview:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:binding:N-return-id3d12graphicscommandlist-setgraphicsrootshaderresourceview:0 -->

<a id="id3d12graphicscommandlist-setgraphicsrootunorderedaccessview"></a>

### ID3D12GraphicsCommandList::SetGraphicsRootUnorderedAccessView

#### Declaration

```cpp
void SetGraphicsRootUnorderedAccessView(
    UINT RootParameterIndex,
    D3D12_GPU_VIRTUAL_ADDRESS BufferLocation);
```

#### Behavior

<!-- d3d12-review-alert:begin:binding:N-id3d12graphicscommandlist-setgraphicsrootunorderedaccessview:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Sets `BufferLocation` as the GPU virtual address for the UAV root descriptor parameter at `RootParameterIndex`. This is not a descriptor heap handle. [Root descriptor](#root-descriptors) resource kind, bounds, alignment and null address restrictions apply.

<!-- d3d12-review-alert:end:binding:N-id3d12graphicscommandlist-setgraphicsrootunorderedaccessview:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:binding:N-parameters-id3d12graphicscommandlist-setgraphicsrootunorderedaccessview:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `RootParameterIndex` follows the [shared setter parameter contract](#root-setter-parameters). `BufferLocation` supplies the resource data's GPU virtual address, subject to the [root descriptor address requirements](#root-descriptors).

<!-- d3d12-review-alert:end:binding:N-parameters-id3d12graphicscommandlist-setgraphicsrootunorderedaccessview:0 -->

#### Return values

<!-- d3d12-review-alert:begin:binding:N-return-id3d12graphicscommandlist-setgraphicsrootunorderedaccessview:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:binding:N-return-id3d12graphicscommandlist-setgraphicsrootunorderedaccessview:0 -->

<a id="id3d12graphicscommandlist-setcomputerootsignature"></a>

### ID3D12GraphicsCommandList::SetComputeRootSignature

#### Declaration

```cpp
void SetComputeRootSignature(
    ID3D12RootSignature* pRootSignature);
```

#### Behavior

<!-- d3d12-review-alert:begin:binding:N-id3d12graphicscommandlist-setcomputerootsignature:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Sets `pRootSignature` as the compute root signature. Changing it invalidates prior arguments. Redundantly setting the same signature preserves them. A null pointer unsets that root signature. Compatibility is required when work executes. See [pipeline compatibility](#pipeline-compatibility) and [canonical binding changes](command-list-state.md#binding-changes).

<!-- d3d12-review-alert:end:binding:N-id3d12graphicscommandlist-setcomputerootsignature:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:binding:N-parameters-id3d12graphicscommandlist-setcomputerootsignature:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pRootSignature` is the root signature to select for the named graphics/compute bind set, or null to unset it. The [shared recording state rules](#recording-state) define invalidation and inheritance.

<!-- d3d12-review-alert:end:binding:N-parameters-id3d12graphicscommandlist-setcomputerootsignature:0 -->

#### Return values

<!-- d3d12-review-alert:begin:binding:N-return-id3d12graphicscommandlist-setcomputerootsignature:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:binding:N-return-id3d12graphicscommandlist-setcomputerootsignature:0 -->

<a id="id3d12graphicscommandlist-setcomputerootdescriptortable"></a>

### ID3D12GraphicsCommandList::SetComputeRootDescriptorTable

#### Declaration

```cpp
void SetComputeRootDescriptorTable(
    UINT RootParameterIndex,
    D3D12_GPU_DESCRIPTOR_HANDLE BaseDescriptor);
```

#### Behavior

<!-- d3d12-review-alert:begin:binding:N-id3d12graphicscommandlist-setcomputerootdescriptortable:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Sets the descriptor table parameter at `RootParameterIndex` to `BaseDescriptor`, a GPU handle in the currently selected shader-visible heap of the matching type. The table's ranges, offsets, [initialization requirements](#table-initialization), and [static promises](#static-promises) apply.

<!-- d3d12-review-alert:end:binding:N-id3d12graphicscommandlist-setcomputerootdescriptortable:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:binding:N-parameters-id3d12graphicscommandlist-setcomputerootdescriptortable:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `RootParameterIndex` follows the [shared setter parameter contract](#root-setter-parameters). `BaseDescriptor` identifies the beginning of the table relative to which its declared descriptor range offsets are applied. It must belong to the matching current shader-visible heap.

<!-- d3d12-review-alert:end:binding:N-parameters-id3d12graphicscommandlist-setcomputerootdescriptortable:0 -->

#### Return values

<!-- d3d12-review-alert:begin:binding:N-return-id3d12graphicscommandlist-setcomputerootdescriptortable:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:binding:N-return-id3d12graphicscommandlist-setcomputerootdescriptortable:0 -->

<a id="id3d12graphicscommandlist-setcomputeroot32bitconstant"></a>

### ID3D12GraphicsCommandList::SetComputeRoot32BitConstant

#### Declaration

```cpp
void SetComputeRoot32BitConstant(
    UINT RootParameterIndex,
    UINT SrcData,
    UINT DestOffsetIn32BitValues);
```

#### Behavior

<!-- d3d12-review-alert:begin:binding:N-id3d12graphicscommandlist-setcomputeroot32bitconstant:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Writes the 32-bit `SrcData` value to `DestOffsetIn32BitValues` within the root constant parameter at `RootParameterIndex`. Other constants remain unchanged. The destination must fit the parameter's declared `Num32BitValues`.

<!-- d3d12-review-alert:end:binding:N-id3d12graphicscommandlist-setcomputeroot32bitconstant:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:binding:N-parameters-id3d12graphicscommandlist-setcomputeroot32bitconstant:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `RootParameterIndex` follows the [shared setter parameter contract](#root-setter-parameters). `SrcData` supplies one 32-bit value. `DestOffsetIn32BitValues` is its destination DWORD offset within that parameter.

<!-- d3d12-review-alert:end:binding:N-parameters-id3d12graphicscommandlist-setcomputeroot32bitconstant:0 -->

#### Return values

<!-- d3d12-review-alert:begin:binding:N-return-id3d12graphicscommandlist-setcomputeroot32bitconstant:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:binding:N-return-id3d12graphicscommandlist-setcomputeroot32bitconstant:0 -->

<a id="id3d12graphicscommandlist-setcomputeroot32bitconstants"></a>

### ID3D12GraphicsCommandList::SetComputeRoot32BitConstants

#### Declaration

```cpp
void SetComputeRoot32BitConstants(
    UINT RootParameterIndex,
    UINT Num32BitValuesToSet,
    const void* pSrcData,
    UINT DestOffsetIn32BitValues);
```

#### Behavior

<!-- d3d12-review-alert:begin:binding:N-id3d12graphicscommandlist-setcomputeroot32bitconstants:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Copies `Num32BitValuesToSet` 32-bit values from `pSrcData` into the root constant parameter at `RootParameterIndex`, starting at `DestOffsetIn32BitValues`. The destination span must fit `Num32BitValues`. Other constants remain unchanged. The source values are captured during recording.

<!-- d3d12-review-alert:end:binding:N-id3d12graphicscommandlist-setcomputeroot32bitconstants:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:binding:N-parameters-id3d12graphicscommandlist-setcomputeroot32bitconstants:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `RootParameterIndex` follows the [shared setter parameter contract](#root-setter-parameters). `pSrcData` supplies `Num32BitValuesToSet` 32-bit values. `DestOffsetIn32BitValues` gives their starting DWORD offset within that parameter.

<!-- d3d12-review-alert:end:binding:N-parameters-id3d12graphicscommandlist-setcomputeroot32bitconstants:0 -->

#### Return values

<!-- d3d12-review-alert:begin:binding:N-return-id3d12graphicscommandlist-setcomputeroot32bitconstants:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:binding:N-return-id3d12graphicscommandlist-setcomputeroot32bitconstants:0 -->

<a id="id3d12graphicscommandlist-setcomputerootconstantbufferview"></a>

### ID3D12GraphicsCommandList::SetComputeRootConstantBufferView

#### Declaration

```cpp
void SetComputeRootConstantBufferView(
    UINT RootParameterIndex,
    D3D12_GPU_VIRTUAL_ADDRESS BufferLocation);
```

#### Behavior

<!-- d3d12-review-alert:begin:binding:N-id3d12graphicscommandlist-setcomputerootconstantbufferview:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Sets `BufferLocation` as the GPU virtual address for the CBV root descriptor parameter at `RootParameterIndex`. This is not a descriptor heap handle. [Root descriptor](#root-descriptors) resource kind, bounds, alignment and null address restrictions apply.

<!-- d3d12-review-alert:end:binding:N-id3d12graphicscommandlist-setcomputerootconstantbufferview:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:binding:N-parameters-id3d12graphicscommandlist-setcomputerootconstantbufferview:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `RootParameterIndex` follows the [shared setter parameter contract](#root-setter-parameters). `BufferLocation` supplies the resource data's GPU virtual address, subject to the [root descriptor address requirements](#root-descriptors).

<!-- d3d12-review-alert:end:binding:N-parameters-id3d12graphicscommandlist-setcomputerootconstantbufferview:0 -->

#### Return values

<!-- d3d12-review-alert:begin:binding:N-return-id3d12graphicscommandlist-setcomputerootconstantbufferview:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:binding:N-return-id3d12graphicscommandlist-setcomputerootconstantbufferview:0 -->

<a id="id3d12graphicscommandlist-setcomputerootshaderresourceview"></a>

### ID3D12GraphicsCommandList::SetComputeRootShaderResourceView

#### Declaration

```cpp
void SetComputeRootShaderResourceView(
    UINT RootParameterIndex,
    D3D12_GPU_VIRTUAL_ADDRESS BufferLocation);
```

#### Behavior

<!-- d3d12-review-alert:begin:binding:N-id3d12graphicscommandlist-setcomputerootshaderresourceview:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Sets `BufferLocation` as the GPU virtual address for the SRV root descriptor parameter at `RootParameterIndex`. This is not a descriptor heap handle. [Root descriptor](#root-descriptors) resource kind, bounds, alignment and null address restrictions apply. SRVs also have the [acceleration structure case](#acceleration-structure-srvs).

<!-- d3d12-review-alert:end:binding:N-id3d12graphicscommandlist-setcomputerootshaderresourceview:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:binding:N-parameters-id3d12graphicscommandlist-setcomputerootshaderresourceview:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `RootParameterIndex` follows the [shared setter parameter contract](#root-setter-parameters). `BufferLocation` supplies the resource data's GPU virtual address, subject to the [root descriptor address requirements](#root-descriptors).

<!-- d3d12-review-alert:end:binding:N-parameters-id3d12graphicscommandlist-setcomputerootshaderresourceview:0 -->

#### Return values

<!-- d3d12-review-alert:begin:binding:N-return-id3d12graphicscommandlist-setcomputerootshaderresourceview:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:binding:N-return-id3d12graphicscommandlist-setcomputerootshaderresourceview:0 -->

<a id="id3d12graphicscommandlist-setcomputerootunorderedaccessview"></a>

### ID3D12GraphicsCommandList::SetComputeRootUnorderedAccessView

#### Declaration

```cpp
void SetComputeRootUnorderedAccessView(
    UINT RootParameterIndex,
    D3D12_GPU_VIRTUAL_ADDRESS BufferLocation);
```

#### Behavior

<!-- d3d12-review-alert:begin:binding:N-id3d12graphicscommandlist-setcomputerootunorderedaccessview:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Sets `BufferLocation` as the GPU virtual address for the UAV root descriptor parameter at `RootParameterIndex`. This is not a descriptor heap handle. [Root descriptor](#root-descriptors) resource kind, bounds, alignment and null address restrictions apply.

<!-- d3d12-review-alert:end:binding:N-id3d12graphicscommandlist-setcomputerootunorderedaccessview:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:binding:N-parameters-id3d12graphicscommandlist-setcomputerootunorderedaccessview:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `RootParameterIndex` follows the [shared setter parameter contract](#root-setter-parameters). `BufferLocation` supplies the resource data's GPU virtual address, subject to the [root descriptor address requirements](#root-descriptors).

<!-- d3d12-review-alert:end:binding:N-parameters-id3d12graphicscommandlist-setcomputerootunorderedaccessview:0 -->

#### Return values

<!-- d3d12-review-alert:begin:binding:N-return-id3d12graphicscommandlist-setcomputerootunorderedaccessview:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> This method does not return a value.

<!-- d3d12-review-alert:end:binding:N-return-id3d12graphicscommandlist-setcomputerootunorderedaccessview:0 -->

<a id="driver"></a>

## Driver interfaces and responsibilities

The runtime enforces that applications don't exceed the capabilities of
the resource binding tier reported by the driver.

<a id="driver-heaps"></a>

### Descriptor heaps and handles

```C++
typedef enum D3D12DDI_DESCRIPTOR_HEAP_TYPE
{
    D3D12DDI_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV,
    D3D12DDI_DESCRIPTOR_HEAP_TYPE_SAMPLER,
    D3D12DDI_DESCRIPTOR_HEAP_TYPE_RTV,
    D3D12DDI_DESCRIPTOR_HEAP_TYPE_DSV,
    D3D12DDI_DESCRIPTOR_HEAP_TYPE_NUM_TYPES
} D3D12DDI_DESCRIPTOR_HEAP_TYPE;

typedef enum D3D12DDI_DESCRIPTOR_HEAP_FLAGS
{
    D3D12DDI_DESCRIPTOR_HEAP_FLAG_NONE = 0x0,
    D3D12DDI_DESCRIPTOR_HEAP_FLAG_CPU_VISIBLE = 0x1,
    D3D12DDI_DESCRIPTOR_HEAP_FLAG_SHADER_VISIBLE = 0x2,
} D3D12DDI_DESCRIPTOR_HEAP_FLAGS;

typedef struct D3D12DDIARG_CREATE_DESCRIPTOR_HEAP_0001
{
    D3D12DDI_DESCRIPTOR_HEAP_TYPE Type;
    UINT NumDescriptors;
    D3D12DDI_DESCRIPTOR_HEAP_FLAGS Flags;
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

<ins><!-- d3d12-review-inline:begin:binding:D-heaps:4 -->Shader-visible descriptor heaps require GPU-addressable storage.<!-- d3d12-review-inline:end:binding:D-heaps:4 --></ins>

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

<ins><!-- d3d12-review-inline:begin:binding:D-heaps:7 -->GetDescriptorSizeInBytes allows the runtime to discover the
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
expressed in bytes.<!-- d3d12-review-inline:end:binding:D-heaps:7 --></ins>

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

<ins><!-- d3d12-review-inline:begin:binding:D-heaps:11 -->If an allocation is not CPU visible, there is no CPU address, so
GetCPUDescriptorHandleForHeapStart must return 0 for the handle. Shader-visible heaps must provide a GPU handle; this DDI requirement does not make non-shader-visible heaps bindable at the API.<!-- d3d12-review-inline:end:binding:D-heaps:11 --></ins>

<!-- d3d12-review-alert:begin:binding:N-ddi-visibility:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> API and DDI visibility flags are not numerically interchangeable. The runtime supplies DDI CPU visibility independently of the application's shader-visible choice. All public API descriptor heaps support CPU descriptor access.

<!-- d3d12-review-alert:end:binding:N-ddi-visibility:0 -->

<!-- d3d12-review-alert:begin:binding:DV-H01:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The runtime supplies the private storage reported by the size query through `D3D12DDI_HDESCRIPTORHEAP`. The driver owns any additional backing allocations, not that private region. Private object size need not equal descriptor count times descriptor stride.

<!-- d3d12-review-alert:end:binding:DV-H01:0 -->

<!-- d3d12-review-alert:begin:binding:DV-H02:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> On failed creation, the driver unwinds its partial state and additional allocations. DestroyDescriptorHeap is called only after successful creation, including when later runtime initialization fails. It releases driver-owned backing without freeing runtime-supplied private storage.

<!-- d3d12-review-alert:end:binding:DV-H02:0 -->

<!-- d3d12-review-alert:begin:binding:DV-H04:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The runtime may cache or translate the driver heap start handles before exposing them through the corresponding API queries.

<!-- d3d12-review-alert:end:binding:DV-H04:0 -->

<a id="driver-descriptors"></a>

### Heap binding and descriptor creation

<ins><!-- d3d12-review-inline:begin:binding:D-set-heaps:0 -->`PFND3D12DDI_SET_DESCRIPTOR_HEAPS_0003` replaces all previously set descriptor heaps (even
if it doesn't set any or all of them). So for example if
NumDescriptorHeaps is 0, that would be unbinding all descriptor heaps.
The runtime validates that at most one of any given shader visible
descriptor heap type can be set.<!-- d3d12-review-inline:end:binding:D-set-heaps:0 --></ins>

```C++
typedef VOID ( APIENTRY* PFND3D12DDI_SET_DESCRIPTOR_HEAPS_0003 )(
    D3D12DDI_HCOMMANDLIST,
    UINT NumDescriptorHeaps,
    _In_reads_(NumDescriptorHeaps) D3D12DDI_HDESCRIPTORHEAP* pDescriptorHeaps );
```

<!-- d3d12-review-alert:begin:binding:RB-H01:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `SetDescriptorHeaps` receives driver descriptor heap handles after the runtime resolves the API objects.

<!-- d3d12-review-alert:end:binding:RB-H01:0 -->

All methods for generating descriptors are free threaded.

Note that there is no "destroy" for a descriptor -- any external
allocations a descriptor may refer to in the driver/hardware (such as a
texture) already have a separate object owning its lifetime.

<a id="driver-views"></a>

### View creation

<!-- d3d12-review-alert:begin:formats:N-driver:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The runtime translates API view descriptions into the negotiated driver representation. The driver writes hardware-specific descriptors into the supplied CPU descriptor handles. Descriptor creation does not allocate separately owned objects. See [descriptor ownership](#driver-descriptors).

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
> | Resource and view format | Resolve the driver resource handle and the permitted format interpretation. Descriptor storage remains driver-specific |
> | Default descriptions and remaining-range sentinels | Expand into the appropriate selected mip/array/depth extent before descriptor creation |
> | API dimension and resource sample configuration | Select the corresponding driver view representation; API array/MS/cube variants are not an interchangeable numeric DDI enum |
> | `Shader4ComponentMapping` and `ResourceMinLODClamp` | Preserve the specified component and mip coordinate interpretation |
> | UAV counter resource and byte offset | Carry the counter association separately from the data buffer and apply the validated storage offset |
> | Depth/stencil plane selection | Preserve logical aspect selection without exposing a physical texture layout |

<!-- d3d12-review-alert:end:formats:N-driver-translation:0 -->

<!-- d3d12-review-alert:begin:formats:DV-V01:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The following table associates descriptor creation DDIs with their API operations.

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

<!-- d3d12-review-alert:begin:formats:N-driver-defaults:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Before calling the driver, the runtime resolves omitted view descriptions from the resource and selects the driver-facing view kind.

<!-- d3d12-review-alert:end:formats:N-driver-defaults:0 -->

<a id="driver-sampler-feedback-view"></a>

#### Paired sampler feedback descriptor

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_CREATE_SAMPLER_FEEDBACK_UNORDERED_ACCESS_VIEW_0075 ) ( _In_ D3D12DDI_HDEVICE hDrvDevice, _In_ D3D12DDI_HRESOURCE hDrvTargetedResource, _In_ D3D12DDI_HRESOURCE hDrvFeedbackResource, _In_ D3D12DDI_CPU_DESCRIPTOR_HANDLE DestDescriptor );
```

<!-- d3d12-review-alert:begin:formats:DV-F02:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Sampler feedback descriptor creation receives separate driver handles for the targeted and feedback resources.

<!-- d3d12-review-alert:end:formats:DV-F02:0 -->

<a id="driver-cbv-samplers"></a>

### CBV and sampler creation

```cpp
typedef struct D3D12DDI_CONSTANT_BUFFER_VIEW_DESC
{
    D3D12DDI_GPU_VIRTUAL_ADDRESS BufferLocation;
    UINT SizeInBytes;
    UINT Padding;
} D3D12DDI_CONSTANT_BUFFER_VIEW_DESC;

typedef VOID ( APIENTRY* PFND3D12DDI_CREATE_CONSTANT_BUFFER_VIEW )( D3D12DDI_HDEVICE, _In_ CONST D3D12DDI_CONSTANT_BUFFER_VIEW_DESC*, _In_ D3D12DDI_CPU_DESCRIPTOR_HANDLE DestDescriptor );

typedef struct D3D12DDIARG_CREATE_SAMPLER_0096
{
    CONST D3D12DDI_SAMPLER_DESC_0096* pSamplerDesc;
} D3D12DDIARG_CREATE_SAMPLER_0096;

typedef VOID(APIENTRY* PFND3D12DDI_CREATE_SAMPLER_0096)(D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATE_SAMPLER_0096*, _In_ D3D12DDI_CPU_DESCRIPTOR_HANDLE DestDescriptor);
```

<!-- d3d12-review-alert:begin:binding:DV-C02:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Driver entry | Logical API contract and adaptation |
> |---|---|
> | `PFND3D12DDI_CREATE_CONSTANT_BUFFER_VIEW` | [CreateConstantBufferView](#id3d12device-createconstantbufferview): encode the validated buffer address/byte size interpretation at the supplied driver CPU descriptor handle |
> | `PFND3D12DDI_CREATE_SAMPLER_0096` | [CreateSampler](#id3d12device-createsampler) and [CreateSampler2](#id3d12device11-createsampler2): the outer argument points to the extended driver description. Its flags select unsigned versus floating-point border color and the applicable coordinate mode |

<!-- d3d12-review-alert:end:binding:DV-C02:0 -->

<!-- d3d12-review-alert:begin:binding:DV-C03:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> For a null CBV API description, the runtime supplies zero `BufferLocation` and `SizeInBytes` values to the driver. `Padding` has no semantic input.

<!-- d3d12-review-alert:end:binding:DV-C03:0 -->

<!-- d3d12-review-alert:begin:binding:DV-C04:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> CreateSampler uses the extended driver representation with no additional flags. CreateSampler2 also supplies typed border color and flags.

<!-- d3d12-review-alert:end:binding:DV-C04:0 -->

<!-- d3d12-review-alert:begin:binding:DV-C05:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Descriptor generation failures use `PFND3D12DDI_SETERROR_CB`, not the command list recording error channel.

<!-- d3d12-review-alert:end:binding:DV-C05:0 -->

<a id="driver-copies"></a>

### Descriptor copies

Parameters are directly passed through from API to DDI, other than that
the handle values may be minimally processed to avoid applications
inadvertently dereferencing handles directly (or making it appear that
it is safe).

Copies with source and destination overlapping are invalid and will
produce undefined results in overlapping regions.

```cpp
typedef VOID (APIENTRY* PFND3D12DDI_COPY_DESCRIPTORS_0003)(
    D3D12DDI_HDEVICE unnamedParam1,
    UINT NumDestDescriptorRanges,
    const D3D12DDI_CPU_DESCRIPTOR_HANDLE *pDestDescriptorRangeStarts,
    const UINT *pDestDescriptorRangeSizes,
    UINT NumSrcDescriptorRanges,
    const D3D12DDI_CPU_DESCRIPTOR_HANDLE *pSrcDescriptorRangeStarts,
    const UINT *pSrcDescriptorRangeSizes,
    D3D12DDI_DESCRIPTOR_HEAP_TYPE DescriptorHeapsType
);
```

```cpp
typedef VOID (APIENTRY* PFND3D12DDI_COPY_DESCRIPTORS_SIMPLE_0003)(
    D3D12DDI_HDEVICE unnamedParam1,
    UINT NumDescriptors,
    D3D12DDI_CPU_DESCRIPTOR_HANDLE DestDescriptorRangeStart,
    D3D12DDI_CPU_DESCRIPTOR_HANDLE SrcDescriptorRangeStart,
    D3D12DDI_DESCRIPTOR_HEAP_TYPE DescriptorHeapsType
);
```

<!-- d3d12-review-alert:begin:binding:DV-P01:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The descriptor copy DDIs implement [CopyDescriptors](#id3d12device-copydescriptors) and [CopyDescriptorsSimple](#id3d12device-copydescriptorssimple).

<!-- d3d12-review-alert:end:binding:DV-P01:0 -->

<!-- d3d12-review-alert:begin:binding:DV-P02:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The runtime may translate handles and route shadowed descriptors before invoking the driver.

<!-- d3d12-review-alert:end:binding:DV-P02:0 -->

<a id="driver-signatures"></a>

### Root signature versions and promises

<ins><!-- d3d12-review-inline:begin:binding:D-root-range-flags:0 -->The runtime will fill in defaults for these flags if the application
specified none. The defaults are documented with the [API version of
these flags](#descriptor-range-defaults).<!-- d3d12-review-inline:end:binding:D-root-range-flags:0 --></ins>

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

<ins><!-- d3d12-review-inline:begin:binding:D-root-flags:0 -->The runtime will fill in defaults for these flags if the application
specified none. The defaults are documented with the [API version of
these flags](#root-descriptor-defaults).<!-- d3d12-review-inline:end:binding:D-root-flags:0 --></ins>

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

<a id="driver-root-descriptions"></a>

#### Driver root description types

<!-- d3d12-review-alert:begin:binding:RB-T01:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The driver root description representations are:

<!-- d3d12-review-alert:end:binding:RB-T01:0 -->

```cpp
typedef enum D3D12DDI_DESCRIPTOR_RANGE_TYPE
{
    D3D12DDI_DESCRIPTOR_RANGE_TYPE_SRV,
    D3D12DDI_DESCRIPTOR_RANGE_TYPE_UAV,
    D3D12DDI_DESCRIPTOR_RANGE_TYPE_CBV,
    D3D12DDI_DESCRIPTOR_RANGE_TYPE_SAMPLER
} D3D12DDI_DESCRIPTOR_RANGE_TYPE;

typedef enum D3D12DDI_ROOT_PARAMETER_TYPE
{
    D3D12DDI_ROOT_PARAMETER_TYPE_DESCRIPTOR_TABLE,
    D3D12DDI_ROOT_PARAMETER_TYPE_32BIT_CONSTANTS,
    D3D12DDI_ROOT_PARAMETER_TYPE_CBV,
    D3D12DDI_ROOT_PARAMETER_TYPE_SRV,
    D3D12DDI_ROOT_PARAMETER_TYPE_UAV
} D3D12DDI_ROOT_PARAMETER_TYPE;

typedef enum D3D12DDI_SHADER_VISIBILITY
{
    D3D12DDI_SHADER_VISIBILITY_ALL = 0,
    D3D12DDI_SHADER_VISIBILITY_VERTEX = 1,
    D3D12DDI_SHADER_VISIBILITY_HULL = 2,
    D3D12DDI_SHADER_VISIBILITY_DOMAIN = 3,
    D3D12DDI_SHADER_VISIBILITY_GEOMETRY = 4,
    D3D12DDI_SHADER_VISIBILITY_PIXEL = 5,
    D3D12DDI_SHADER_VISIBILITY_AMPLIFICATION = 6,
    D3D12DDI_SHADER_VISIBILITY_MESH = 7,
} D3D12DDI_SHADER_VISIBILITY;

typedef enum D3D12DDI_ROOT_SIGNATURE_FLAGS
{
    D3D12DDI_ROOT_SIGNATURE_FLAG_NONE                                   = 0x0,
    D3D12DDI_ROOT_SIGNATURE_FLAG_ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT     = 0x1,
    D3D12DDI_ROOT_SIGNATURE_FLAG_DENY_VERTEX_SHADER_ROOT_ACCESS         = 0x2,
    D3D12DDI_ROOT_SIGNATURE_FLAG_DENY_HULL_SHADER_ROOT_ACCESS           = 0x4,
    D3D12DDI_ROOT_SIGNATURE_FLAG_DENY_DOMAIN_SHADER_ROOT_ACCESS         = 0x8,
    D3D12DDI_ROOT_SIGNATURE_FLAG_DENY_GEOMETRY_SHADER_ROOT_ACCESS       = 0x10,
    D3D12DDI_ROOT_SIGNATURE_FLAG_DENY_PIXEL_SHADER_ROOT_ACCESS          = 0x20,
    D3D12DDI_ROOT_SIGNATURE_FLAG_ALLOW_STREAM_OUTPUT                    = 0x40,
    D3D12DDI_ROOT_SIGNATURE_FLAG_LOCAL_ROOT_SIGNATURE                   = 0x80,
    D3D12DDI_ROOT_SIGNATURE_FLAG_DENY_AMPLIFICATION_SHADER_ROOT_ACCESS  = 0x100,
    D3D12DDI_ROOT_SIGNATURE_FLAG_DENY_MESH_SHADER_ROOT_ACCESS           = 0x200,
    D3D12DDI_ROOT_SIGNATURE_FLAG_CBV_SRV_UAV_HEAP_DIRECTLY_INDEXED      = 0x400,
    D3D12DDI_ROOT_SIGNATURE_FLAG_SAMPLER_HEAP_DIRECTLY_INDEXED          = 0x800,
} D3D12DDI_ROOT_SIGNATURE_FLAGS;

typedef enum D3D12DDI_STATIC_BORDER_COLOR
{
    D3D12DDI_STATIC_BORDER_COLOR_TRANSPARENT_BLACK, // 0.0f,0.0f,0.0f,0.0f
    D3D12DDI_STATIC_BORDER_COLOR_OPAQUE_BLACK, // 0.0f,0.0f,0.0f,1.0f
    D3D12DDI_STATIC_BORDER_COLOR_OPAQUE_WHITE, // 1.0f,1.0f,1.0f,1.0f
    D3D12DDI_STATIC_BORDER_COLOR_OPAQUE_BLACK_UINT, // 0u,0u,0u,1u
    D3D12DDI_STATIC_BORDER_COLOR_OPAQUE_WHITE_UINT  // 1u,1u,1u,1u
} D3D12DDI_STATIC_BORDER_COLOR;

typedef enum D3D12DDI_ROOT_SIGNATURE_VERSION
{
    D3D12DDI_ROOT_SIGNATURE_VERSION_1_1  = 0x2,
    D3D12DDI_ROOT_SIGNATURE_VERSION_1_2  = 0x3,
} D3D12DDI_ROOT_SIGNATURE_VERSION;

#define D3D12DDI_DESCRIPTOR_RANGE_OFFSET_APPEND -1

typedef struct D3D12DDI_ROOT_CONSTANTS
{
    UINT ShaderRegister;
    UINT RegisterSpace;
    UINT Num32BitValues;
} D3D12DDI_ROOT_CONSTANTS;

typedef struct D3D12DDI_DESCRIPTOR_RANGE_0013
{
    D3D12DDI_DESCRIPTOR_RANGE_TYPE RangeType;
    UINT NumDescriptors;
    UINT BaseShaderRegister;
    UINT RegisterSpace;
    D3D12DDI_DESCRIPTOR_RANGE_FLAGS Flags;
    UINT OffsetInDescriptorsFromTableStart;
} D3D12DDI_DESCRIPTOR_RANGE_0013;

typedef struct D3D12DDI_ROOT_DESCRIPTOR_TABLE_0013
{
    UINT NumDescriptorRanges;
    CONST D3D12DDI_DESCRIPTOR_RANGE_0013* pDescriptorRanges;
} D3D12DDI_ROOT_DESCRIPTOR_TABLE_0013;

typedef struct D3D12DDI_ROOT_DESCRIPTOR_0013
{
    UINT ShaderRegister;
    UINT RegisterSpace;
    D3D12DDI_ROOT_DESCRIPTOR_FLAGS Flags;
} D3D12DDI_ROOT_DESCRIPTOR_0013;

typedef struct D3D12DDI_ROOT_PARAMETER_0013
{
    D3D12DDI_ROOT_PARAMETER_TYPE ParameterType;
    union
    {
        D3D12DDI_ROOT_DESCRIPTOR_TABLE_0013 DescriptorTable;
        D3D12DDI_ROOT_CONSTANTS             Constants;
        D3D12DDI_ROOT_DESCRIPTOR_0013       Descriptor;
    };
    D3D12DDI_SHADER_VISIBILITY ShaderVisibility;
} D3D12DDI_ROOT_PARAMETER_0013;

```

<!-- d3d12-review-alert:begin:binding:RB-T02:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12DDI_DESCRIPTOR_RANGE_OFFSET_APPEND` represents the API append-offset sentinel. The driver description carries normalized descriptor/data flags.

<!-- d3d12-review-alert:end:binding:RB-T02:1 -->

<!-- d3d12-review-alert:begin:binding:RB-T02:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> DDI root signature version 1.2 uses the version-1.1 parameter representation with the new static sampler representation shown below.

<!-- d3d12-review-alert:end:binding:RB-T02:2 -->

To support static samplers, `D3D12DDI_STATIC_SAMPLER_0100` includes a flags field.

```c++
typedef struct D3D12DDI_STATIC_SAMPLER_0100
{
    D3D12DDI_FILTER Filter;
    D3D12DDI_TEXTURE_ADDRESS_MODE AddressU;
    D3D12DDI_TEXTURE_ADDRESS_MODE AddressV;
    D3D12DDI_TEXTURE_ADDRESS_MODE AddressW;
    FLOAT MipLODBias;
    UINT MaxAnisotropy;
    D3D12DDI_COMPARISON_FUNC ComparisonFunc;
    D3D12DDI_STATIC_BORDER_COLOR BorderColor;
    FLOAT MinLOD;
    FLOAT MaxLOD;
    UINT ShaderRegister;
    UINT RegisterSpace;
    D3D12DDI_SHADER_VISIBILITY ShaderVisibility;

    // Sampler flags
    D3D12DDI_SAMPLER_FLAGS_0096 Flags;
} D3D12DDI_STATIC_SAMPLER_0100;
```

<ins><!-- d3d12-review-inline:begin:binding:D-root-12:2 -->The version-1.2 root signature description uses `D3D12DDI_STATIC_SAMPLER_0100`.<!-- d3d12-review-inline:end:binding:D-root-12:2 --></ins>

```c++
typedef struct D3D12DDI_ROOT_SIGNATURE_0100
{
    UINT NumParameters;
    CONST D3D12DDI_ROOT_PARAMETER_0013* pRootParameters;
    UINT NumStaticSamplers;

    // Version 1.2 static samplers
    CONST D3D12DDI_STATIC_SAMPLER_0100* pStaticSamplers;

    D3D12DDI_ROOT_SIGNATURE_FLAGS Flags;
} D3D12DDI_ROOT_SIGNATURE_0100;

typedef struct D3D12DDIARG_CREATE_ROOT_SIGNATURE_0100
{
    D3D12DDI_ROOT_SIGNATURE_VERSION Version;
    union
    {
        CONST D3D12DDI_ROOT_SIGNATURE_0100* pRootSignature_1_2;
    };
    UINT NodeMask;
} D3D12DDIARG_CREATE_ROOT_SIGNATURE_0100;
```

<ins><!-- d3d12-review-inline:begin:binding:D-root-12:4 -->The corresponding core functions size and create a version-1.2 root signature.<!-- d3d12-review-inline:end:binding:D-root-12:4 --></ins>

```c++

typedef SIZE_T(APIENTRY* PFND3D12DDI_CALC_PRIVATE_ROOT_SIGNATURE_SIZE_0100)(D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATE_ROOT_SIGNATURE_0100*);
typedef HRESULT(APIENTRY* PFND3D12DDI_CREATE_ROOT_SIGNATURE_0100) (D3D12DDI_HDEVICE, _In_ CONST D3D12DDIARG_CREATE_ROOT_SIGNATURE_0100*, D3D12DDI_HROOTSIGNATURE);

```

<a id="driver-root-lifecycle"></a>

#### Root object lifecycle and ownership

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_DESTROY_ROOT_SIGNATURE ) ( D3D12DDI_HDEVICE, D3D12DDI_HROOTSIGNATURE );
```

<!-- d3d12-review-alert:begin:binding:RB-L02:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The runtime supplies the private storage reported by the size query through `D3D12DDI_HROOTSIGNATURE`. These DDIs do not receive a separate runtime root signature handle.

<!-- d3d12-review-alert:end:binding:RB-L02:0 -->

<!-- d3d12-review-alert:begin:binding:RB-L03:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> On failed creation, the driver unwinds its partial state and additional allocations. DestroyRootSignature is called only after successful creation and releases driver-owned state without freeing runtime-supplied private storage.

<!-- d3d12-review-alert:end:binding:RB-L03:0 -->

<!-- d3d12-review-alert:begin:binding:RB-L05:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Before driver creation, the runtime deserializes and validates the root signature, converts its version and normalizes explicit defaults. The driver receives this normalized description rather than the serialized blob. The `_0100` pair uses the static sampler representation shown above.

<!-- d3d12-review-alert:end:binding:RB-L05:0 -->

<a id="driver-binding"></a>

### Root binding

<!-- d3d12-review-alert:begin:binding:RB-B01:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Graphics and compute slots select separate bind sets even where they share a function pointer type.

<!-- d3d12-review-alert:end:binding:RB-B01:0 -->

<!-- d3d12-review-alert:begin:binding:RB-B02:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Driver entry / slots | Canonical API contracts |
> |---|---|
> | `PFND3D12DDI_SET_ROOT_SIGNATURE` | [SetGraphicsRootSignature](#id3d12graphicscommandlist-setgraphicsrootsignature), [SetComputeRootSignature](#id3d12graphicscommandlist-setcomputerootsignature) |
> | `PFND3D12DDI_SET_ROOT_DESCRIPTOR_TABLE` | [SetGraphicsRootDescriptorTable](#id3d12graphicscommandlist-setgraphicsrootdescriptortable), [SetComputeRootDescriptorTable](#id3d12graphicscommandlist-setcomputerootdescriptortable) |
> | `PFND3D12DDI_SET_ROOT_32BIT_CONSTANT` | [SetGraphicsRoot32BitConstant](#id3d12graphicscommandlist-setgraphicsroot32bitconstant), [SetComputeRoot32BitConstant](#id3d12graphicscommandlist-setcomputeroot32bitconstant) |
> | `PFND3D12DDI_SET_ROOT_32BIT_CONSTANTS_0003` | [SetGraphicsRoot32BitConstants](#id3d12graphicscommandlist-setgraphicsroot32bitconstants), [SetComputeRoot32BitConstants](#id3d12graphicscommandlist-setcomputeroot32bitconstants) |
> | `PFND3D12DDI_SET_ROOT_BUFFER_VIEW`, CBV slots | [SetGraphicsRootConstantBufferView](#id3d12graphicscommandlist-setgraphicsrootconstantbufferview), [SetComputeRootConstantBufferView](#id3d12graphicscommandlist-setcomputerootconstantbufferview) |
> | `PFND3D12DDI_SET_ROOT_BUFFER_VIEW`, SRV slots | [SetGraphicsRootShaderResourceView](#id3d12graphicscommandlist-setgraphicsrootshaderresourceview), [SetComputeRootShaderResourceView](#id3d12graphicscommandlist-setcomputerootshaderresourceview) |
> | `PFND3D12DDI_SET_ROOT_BUFFER_VIEW`, UAV slots | [SetGraphicsRootUnorderedAccessView](#id3d12graphicscommandlist-setgraphicsrootunorderedaccessview), [SetComputeRootUnorderedAccessView](#id3d12graphicscommandlist-setcomputerootunorderedaccessview) |

<!-- d3d12-review-alert:end:binding:RB-B02:0 -->

See the API reference for details on the flags and inheritance behavior
between command lists and bundles.

Parameters are directly passed through from API to DDI. Same function
prototype repeated for compute and graphics entrypoints:

```C++
typedef VOID ( APIENTRY* PFND3D12DDI_SET_ROOT_SIGNATURE )(
    D3D12DDI_HCOMMANDLIST,
    _In_ D3D12DDI_HROOTSIGNATURE);
```

Parameters are directly passed through from API to DDI. Same function
prototype repeated for compute and graphics entrypoints:

```C++
typedef VOID ( APIENTRY* PFND3D12DDI_SET_ROOT_DESCRIPTOR_TABLE )(
    D3D12DDI_HCOMMANDLIST,
    _In_ UINT RootParameterIndex,
    _In_ D3D12DDI_GPU_DESCRIPTOR_HANDLE BaseDescriptor);
```

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

<!-- d3d12-review-alert:begin:binding:RB-B03:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The group constant DDI copies `pSrcData` values during the call. Descriptor table bases use driver GPU descriptor handles.

<!-- d3d12-review-alert:end:binding:RB-B03:0 -->

<a id="driver-root-binding-forms"></a>

#### Current handle representations

<!-- d3d12-review-alert:begin:binding:RF-representations:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The `_0114` root binding entries participate in [runtime bypass](execution.md#work-command-handles).

<!-- d3d12-review-alert:end:binding:RF-representations:0 -->

<!-- d3d12-review-alert:begin:binding:RF-role-map:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> The same member names select the graphics and compute operations in both tables.

<!-- d3d12-review-alert:end:binding:RF-role-map:0 -->

<!-- d3d12-review-alert:begin:binding:RF-role-map:1 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> | Ordinary type / API handle type | Graphics member / API contract | Compute member / API contract |
> |---|---|---|
> | `PFND3D12DDI_SET_ROOT_SIGNATURE` / `PFND3D12DDI_SET_ROOT_SIGNATURE_0114` | `pfnSetGraphicsRootSignature` / [SetGraphicsRootSignature](#id3d12graphicscommandlist-setgraphicsrootsignature) | `pfnSetComputeRootSignature` / [SetComputeRootSignature](#id3d12graphicscommandlist-setcomputerootsignature) |
> | `PFND3D12DDI_SET_ROOT_DESCRIPTOR_TABLE` / `PFND3D12DDI_SET_ROOT_DESCRIPTOR_TABLE_0114` | `pfnSetGraphicsRootDescriptorTable` / [SetGraphicsRootDescriptorTable](#id3d12graphicscommandlist-setgraphicsrootdescriptortable) | `pfnSetComputeRootDescriptorTable` / [SetComputeRootDescriptorTable](#id3d12graphicscommandlist-setcomputerootdescriptortable) |
> | `PFND3D12DDI_SET_ROOT_32BIT_CONSTANT` / `PFND3D12DDI_SET_ROOT_32BIT_CONSTANT_0114` | `pfnSetGraphicsRoot32BitConstant` / [SetGraphicsRoot32BitConstant](#id3d12graphicscommandlist-setgraphicsroot32bitconstant) | `pfnSetComputeRoot32BitConstant` / [SetComputeRoot32BitConstant](#id3d12graphicscommandlist-setcomputeroot32bitconstant) |
> | `PFND3D12DDI_SET_ROOT_32BIT_CONSTANTS_0003` / `PFND3D12DDI_SET_ROOT_32BIT_CONSTANTS_0114` | `pfnSetGraphicsRoot32BitConstants` / [SetGraphicsRoot32BitConstants](#id3d12graphicscommandlist-setgraphicsroot32bitconstants) | `pfnSetComputeRoot32BitConstants` / [SetComputeRoot32BitConstants](#id3d12graphicscommandlist-setcomputeroot32bitconstants) |
> | `PFND3D12DDI_SET_ROOT_BUFFER_VIEW` / `PFND3D12DDI_SET_ROOT_BUFFER_VIEW_0114` | `pfnSetGraphicsRootConstantBufferView` / [SetGraphicsRootConstantBufferView](#id3d12graphicscommandlist-setgraphicsrootconstantbufferview) | `pfnSetComputeRootConstantBufferView` / [SetComputeRootConstantBufferView](#id3d12graphicscommandlist-setcomputerootconstantbufferview) |
> | `PFND3D12DDI_SET_ROOT_BUFFER_VIEW` / `PFND3D12DDI_SET_ROOT_BUFFER_VIEW_0114` | `pfnSetGraphicsRootShaderResourceView` / [SetGraphicsRootShaderResourceView](#id3d12graphicscommandlist-setgraphicsrootshaderresourceview) | `pfnSetComputeRootShaderResourceView` / [SetComputeRootShaderResourceView](#id3d12graphicscommandlist-setcomputerootshaderresourceview) |
> | `PFND3D12DDI_SET_ROOT_BUFFER_VIEW` / `PFND3D12DDI_SET_ROOT_BUFFER_VIEW_0114` | `pfnSetGraphicsRootUnorderedAccessView` / [SetGraphicsRootUnorderedAccessView](#id3d12graphicscommandlist-setgraphicsrootunorderedaccessview) | `pfnSetComputeRootUnorderedAccessView` / [SetComputeRootUnorderedAccessView](#id3d12graphicscommandlist-setcomputerootunorderedaccessview) |

<!-- d3d12-review-alert:end:binding:RF-role-map:1 -->

<!-- d3d12-review-alert:begin:binding:RF-root-handles:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `D3D12DDI_API_HROOTSIGNATURE` uses the runtime bypass header. The helper below converts its `pDriverObject` to the ordinary driver root signature handle and maps a null API root handle to a null driver handle.

<!-- d3d12-review-alert:end:binding:RF-root-handles:0 -->

```cpp
D3D10DDI_H( D3D12DDI_API_HROOTSIGNATURE )

inline D3D12DDI_HROOTSIGNATURE GetDriverRootSignatureHandle(D3D12DDI_API_HROOTSIGNATURE ApiHandle)
{
    D3D12DDI_RUNTIME_BYPASS_HEADER* pBypassHeader = (D3D12DDI_RUNTIME_BYPASS_HEADER*)ApiHandle.pDrvPrivate;
    D3D12DDI_HROOTSIGNATURE hRootSignature;

    hRootSignature.pDrvPrivate = (pBypassHeader) ? pBypassHeader->pDriverObject : NULL;
    return hRootSignature;
}
```

```cpp
typedef VOID ( APIENTRY* PFND3D12DDI_SET_ROOT_SIGNATURE_0114 )(D3D12DDI_API_HCOMMANDLIST, _In_ D3D12DDI_API_HROOTSIGNATURE);
typedef VOID ( APIENTRY* PFND3D12DDI_SET_ROOT_DESCRIPTOR_TABLE_0114 )(D3D12DDI_API_HCOMMANDLIST, _In_ UINT RootParameterIndex,_In_ D3D12DDI_GPU_DESCRIPTOR_HANDLE BaseDescriptor );
typedef VOID ( APIENTRY* PFND3D12DDI_SET_ROOT_32BIT_CONSTANT_0114 )(D3D12DDI_API_HCOMMANDLIST, UINT RootParameterIndex, UINT SrcData, UINT DestOffsetIn32BitValues);
typedef VOID ( APIENTRY* PFND3D12DDI_SET_ROOT_32BIT_CONSTANTS_0114 )(D3D12DDI_API_HCOMMANDLIST, UINT RootParameterIndex, UINT Num32BitValuesToSet, CONST void* pSrcData, UINT DestOffsetIn32BitValues );
typedef VOID ( APIENTRY* PFND3D12DDI_SET_ROOT_BUFFER_VIEW_0114 )(D3D12DDI_API_HCOMMANDLIST, UINT RootParameterIndex, _In_ D3D12DDI_GPU_VIRTUAL_ADDRESS BufferLocation);
```

<a id="driver-clearing"></a>

### Root clearing

```C++
typedef VOID ( APIENTRY* PFND3D12DDI_CLEAR_ROOT_ARGUMENTS)(D3D12DDI_HCOMMANDLIST);
```

<ins><!-- d3d12-review-inline:begin:binding:D-clear:1 -->This DDI zero-initializes root arguments. The purpose is to ensure that
applications cannot leak root arguments (root constants, root views,
descriptor tables) from 1 command list to the next. For DIRECT and COMPUTE recordings, the runtime calls
this DDI when creating a new command list, during
ID3D12GraphicsCommandList::Reset, and during ID3D12GraphicsCommandList::ClearState. Note
that there are separate DDI calls to clear other command list state
(vertex buffers, render targets, PSO, etc). Also note that this DDI
should apply the same operation regardless of the currently set root
signature.<!-- d3d12-review-inline:end:binding:D-clear:1 --></ins>

<!-- d3d12-review-alert:begin:binding:N-clear-not-valid:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Driver zero-initialization prevents cross-recording leakage. It does not establish valid application bindings. The [canonical initial state rules](command-list-state.md#initial-bindings) still require the applicable root signature and arguments. Bundles instead follow the [bundle binding inheritance rules](command-list-state.md#bundle-bindings).

<!-- d3d12-review-alert:end:binding:N-clear-not-valid:0 -->

<a id="root-signature-serialized-retrieval"></a>

## Retrieving a root signature's serialized representation

<a id="api-id3d12rootsignature1-getserializedsize"></a>

### ID3D12RootSignature1::GetSerializedSize

#### Declaration

```cpp
SIZE_T GetSerializedSize();
```

#### Behavior

<!-- d3d12-review-alert:begin:binding:AB-id3d12rootsignature1-getserializedsize-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns the required byte size for the object's serialized DXBC container, including the root signature chunk and container overhead. It is not a shader bytecode or driver-private object size.

<!-- d3d12-review-alert:end:binding:AB-id3d12rootsignature1-getserializedsize-contract:0 -->

#### Return values

<!-- d3d12-review-alert:begin:binding:AB-id3d12rootsignature1-getserializedsize-contract:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Returns SIZE_T bytes. The immutable object's serialized representation can be retrieved through GetSerializedData.

<!-- d3d12-review-alert:end:binding:AB-id3d12rootsignature1-getserializedsize-contract:2 -->

<a id="api-id3d12rootsignature1-getserializeddata"></a>

### ID3D12RootSignature1::GetSerializedData

#### Declaration

```cpp
HRESULT GetSerializedData(
    void *pData,
    SIZE_T Size);
```

#### Behavior

<!-- d3d12-review-alert:begin:binding:AB-id3d12rootsignature1-getserializeddata-contract:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Copies a serialized root signature DXBC container into CPU storage. This need not reproduce the original application's container bytes identically. It represents the root signature object. The caller's storage is not retained and no GPU work is submitted.

<!-- d3d12-review-alert:end:binding:AB-id3d12rootsignature1-getserializeddata-contract:0 -->

#### Parameters

<!-- d3d12-review-alert:begin:binding:AB-id3d12rootsignature1-getserializeddata-contract:2 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> `pData` is the required output buffer. `Size` is its capacity in bytes, obtained from GetSerializedSize.

<!-- d3d12-review-alert:end:binding:AB-id3d12rootsignature1-getserializeddata-contract:2 -->

#### Return values

<!-- d3d12-review-alert:begin:binding:AB-id3d12rootsignature1-getserializeddata-contract:4 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> Null data returns `E_INVALIDARG`; capacity smaller than the required container returns `DXGI_ERROR_MORE_DATA`. Success returns `S_OK`; container-building/allocation failures remain HRESULT failures.

<!-- d3d12-review-alert:end:binding:AB-id3d12rootsignature1-getserializeddata-contract:4 -->
