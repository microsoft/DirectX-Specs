<h1>D3D12 Depth Bounds Test</h1>

Version 1.3

---

<h1>Contents</h1>

- [Motivation](#motivation)
- [Detailed Design](#detailed-design)
- [API](#api)
  - [New Create PSO Concepts](#new-create-pso-concepts)
  - [Stream Padding Assumptions](#stream-padding-assumptions)
  - [Base Create PSO API](#base-create-pso-api)
  - [D3DX12 Helpers](#d3dx12-helpers)
  - [New DXGI_FORMAT[] wrapper for RTVFormats](#new-dxgi_format-wrapper-for-rtvformats)
  - [Component Interop](#component-interop)
  - [Example Stream Construction](#example-stream-construction)
    - [Using the Core API](#using-the-core-api)
    - [Using CD3DX12 Helpers](#using-cd3dx12-helpers)
  - [Versioning a Subobject](#versioning-a-subobject)
  - [Versioning the Full Graphics/Compute Streams](#versioning-the-full-graphicscompute-streams)
  - [DepthBoundsTest API](#depthboundstest-api)
- [DDI](#ddi)
- [Runtime Code](#runtime-code)
  - [Runtime Validation](#runtime-validation)
  - [SDK Layers Validation](#sdk-layers-validation)
  - [D3DDbg Considerations](#d3ddbg-considerations)
- [Testing](#testing)
  - [Functional](#functional)
  - [Conformance](#conformance)
- [Change Log](#change-log)

---

# Motivation

Many graphics rendering techniques can be optimized via this feature, which has been in hardware for a few years now. One specific example is deferred rendering can avoid processing lighting for pixels that fall outside a light's influence.

Also, this supports Xbox/Windows D3D parity.

# Detailed Design

The Depth Bounds Test API will be added to D3D12 as an optional
feature.

This feature allows a programmer to discard pixels (or samples) based
on a minimum and maximum depth value: if the current depth value in
the depth buffer is inclusively within the specified range, then the
pixel (or sample) has passed the Depth Bounds Test and is rendered,
otherwise the pixel (or sample) has failed the Depth Bounds Test and
is discarded. It is important to note that this feature is independent
of the depth output by a given pixel shader invocation: only the
currently stored depth value and the programmer-specified Depth Bounds
values are relevant.

This API will be exposed as a PSO enable/disable toggle in order to
support hardware that sets depth buffer read state in the PSO, and
Command List method in order to support dynamically changing the Depth
Bounds. It will allow the setting of two floating point values: a
minimum floating point depth value and a maximum floating point depth
value. The runtime will not clamp or validate the input, but
implementations may clamp to the range \[0,1\] if necessary. NaNs must
be treated as 0, but the runtime will convert NaNs to 0 on behalf of
the implementation. If the range is inverted (i.e. min \max), then
implementations must treat the Depth Bounds Test as always failing.
The default values are 0 and 1 for the minimum and maximum,
respectively.

The state of the DBT range will persist into and out-of Bundles. This
means that a Bundle must inherit the DBT range of the executing
Command List, and setting the DBT range in a Bundle will persist on
the executing Command List after the Bundle is executed.

Any Pixel Shader invocation that fails the Depth Bounds Test (i.e.
whose stored depth buffer value falls exclusively outside the Depth
Bounds range) cannot affect the render target, depth, or stencil
buffer. However, UAV writes by a pixel shader invocation that fails
the Depth Bounds Test are determined by the ForceEarlyDepthStencil
flag. When the ForceEarlyDepthStencil flag is present an
implementation must perform the Depth/Stencil tests, the Depth Bounds
Test, and Depth/Stencil writes before executing the Pixel Shader,
which prohibits any external effects (e.g. UAV writes) from the Pixel
Shader invocation. In the absence of the ForceEartlyDepthStencil flag
an implementation may perform optimizations, but must appear to have
executed the Depth/Stencil Tests and Depth Bounds Test after the Pixel
Shader invocation and must reflect any memory updates (e.g. oDepth and
UAV writes) performed by the invocation. Note that while a Pixel
Shader invocation's oDepth is honored in the absence of the
ForceEarlyDepthStencil flag, the Depth Bounds Test for a given Pixel
Shader invocation does not use the depth written by that invocation:
it uses the current depth buffer value prior to its own writes.

When a depth buffer is not bound (e.g. when TIR is enabled), the Depth
Bounds Test must always pass. This is consistent with the behavior of
the Depth Test in this configuration.

The Depth Bounds Test affects the following queries: Occlusion, Binary
Occlusion, and Pipeline Statistics. These queries must exclude
counting samples that failed the Depth Bounds Test.

---

# API

The Depth Stencil State Desc will be revised to include an
enable/disable DBT toggle, which will necessitate revising the PSO Desc
and Creation API. In order to support fast iterations on pipeline state,
we will move away from the existing design that requires a PSO Desc
revision and Creation interface/method revision per update, and
implement one that is more dynamic: a token stream. This design
describes the pipeline state in a much more flexible manner and can be
extended without revising the CreatePSO interface or method. The API
would consist of an enumeration type that describes the following token
to parse from the stream.

---

## New Create PSO Concepts

Subobjects will now be the constituent components of a pipeline state
object. A pipeline state stream is constructed from a grouping (within a
struct) of these subobjects, which from a technical perspective are
structs that contain a pair of subobject type enum followed by the
respective subobject desc. The D3DX12 stream elements (described later)
represent these pairs, and allow short-form construction of custom
streams. An important note is that the runtime assumes the stream is
constructed from structs of enum+desc pairs, which defines the padding
expected by the runtime.

---

## Stream Padding Assumptions

As an example of how the runtime assumes the stream is constructed with
respect to subobject-internal padding, we can look at a Root Signature
subobject:

```C++
MY_PIPELINE_STATE_STREAM_ROOT_SIGNATURE
+0x000 _Type : D3D12_PIPELINE_STATE_SUBOBJECT_TYPE
+0x008 _Inner : Ptr64 ID3D12RootSignature

sizeof(MY_PIPELINE_STATE_STREAM_ROOT_SIGNATURE) unsigned int64 0x10
sizeof(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE) unsigned int64 4
sizeof(ID3D12RootSignature*) unsigned int64 8
```

Simply adding the type and root signature pointer sizes would not
account for the padding of four bytes between the enum and pointer, thus
the runtime parses this subobject from the stream as a full subobject
struct, rather than as a type and pointer separately.

When subobjects are combined into a stream the parsing code assumes
alignas(void*) is used for each subobject (if alignas() is unavailable,
then an alternative such as unioning the data with a void* is a valid
workaround). This is necessary because the parsing code requires an enum
to be packed tightly against the end of the previous element as
determined by sizeof(previous element). If an element is not void*
aligned, but the subsequent element is, then there will be padding
inserted between them and the parser will read that instead of the enum
type. Because of this, all helpers are declared as such:

```C++
template <...>
class alignas(void*) CD3DX12_PIPELINE_STATE_STREAM_SUBOBJECT
```

---

## Base Create PSO API

Listed here is the standard D3D12 API exposed to create a PSO. It
consists of the subobject type enum, the subobject desc structs (as they
exist today), and the device function for CreatePipelineState().

```C++
typedef struct D3D12_PIPELINE_STATE_STREAM_DESC
{
    SIZE_T SizeInBytes;
    void* pPipelineStateSubobjectStream;
} D3D12_PIPELINE_STATE_STREAM_DESC;

typedef enum D3D12_PIPELINE_STATE_SUBOBJECT_TYPE
{
    D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_VS,
    D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_VS_INLINE,
    D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_DEPTH_STENCIL,
    D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_RASTERIZER,
    ...
    D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_DEPTH_STENCIL1
} D3D12_PIPELINE_STATE_SUBOBJECT_TYPE;

// Desc for D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_DEPTH_STENCIL
typedef struct D3D12_DEPTH_STENCIL_DESC
{
    BOOL DepthEnable;
    ...
} D3D12_DEPTH_STENCIL_DESC;

// Desc for D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_DEPTH_STENCIL1
typedef struct D3D12_DEPTH_STENCIL_DESC1
{
    BOOL DepthEnable;
    ...
    BOOL DepthBoundsTestEnable;
} D3D12_DEPTH_STENCIL_DESC1;

interface ID3D12Device1 : ID3D12Device
{
    ...
    HRESULT CreatePipelineState(
        D3D12_PIPELINE_STATE_STREAM_DESC Desc,
        REFIID riid, // Can be any pipeline interface, provided the pipeline subobjects match
        void** ppPipelineState
        );
}
```

For any pipeline state subobjects not found in the stream, defaults will
be used. Defaults will also be used if an old version of a subobject is
found in the stream, e.g. an old DepthStencil State desc would not
contain DBT information so the default of disabled would be used. The
same CreatePSO validation that exists now will be used.

---

## D3DX12 Helpers

D3DX12 will be leveraged to create helper classes for developers to more
easily construct a pipeline stream. We want to use C++ features, and
thus we must put these helpers in D3DX12 rather than the base D3D12 API.

As a foundation, we will create a set of classes that pair enum with
struct that can be combined as members of a struct to form a stream.
Note that these are the actual types used to parse the stream and define
the padding assumptions detailed earlier. The three examples shown here
illustrate the three types of subobjects: a simple D3D12-API POD type, a
primitive type, and a Desc that should have defaults.

```C++
template <typename InnerStructType,
D3D12_PIPELINE_STATE_SUBOBJECT_TYPE Type, typename DefaultArg = InnerStructType> class CD3DX12_PIPELINE_STATE_STREAM_ELEMENT
{
private:
    D3D12_PIPELINE_STATE_SUBOBJECT_TYPE _Type;
    InnerStructType _Inner;

public:
    CD3DX12_PIPELINE_STATE_STREAM_ELEMENT() : _Type(Type), _Inner(DefaultArg()) { }

    CD3DX12_PIPELINE_STATE_STREAM_ELEMENT(InnerStructType const& i) : _Type(Type), _Inner(i) { }

    CD3DX12_PIPELINE_STATE_STREAM_ELEMENT& operator=(InnerStructType const& i) { _Inner = i; return *this; }

    operator InnerStructType() { return _Inner; }

};

typedef CD3DX12_PIPELINE_STATE_STREAM_ELEMENT<D3D12_PIPELINE_STATE_FLAGS,D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_FLAGS>
    CD3DX12_PIPELINE_STATE_STREAM_FLAGS;

typedef CD3DX12_PIPELINE_STATE_STREAM_ELEMENT\<UINT,D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_NODE_MASK>
    CD3DX12_PIPELINE_STATE_STREAM_NODE_MASK;

typedef CD3DX12_PIPELINE_STATE_STREAM_ELEMENT\<CD3DX12_RASTERIZER_DESC,D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_RASTERIZER,CD3DX12_DEFAULT>
  CD3DX12_PIPELINE_STATE_STREAM_RASTERIZER;

struct MyPSOStream
{
    CD3DX12_PIPELINE_STATE_STREAM_FLAGS Flags;
    CD3DX12_PIPELINE_STATE_STREAM_RASTERIZER RasterizerState;
};
```

One important note about these classes is that they hide the
InnerStructType behind constructors and a cast operator. This can be
leveraged in the future when we want to update an InnerStructType (e.g.
rasterizer state) but allow backwards compatibility. This would be
useful to avoid breaking changes if someone recompiles with the latest
header and we've updated one of the constituent parts of the full
graphics pipeline struct (described later). One downside of this is that
accessing member data within a stream struct requires a cast, e.g.
D3D12_SHADER_BYTECODE(GraphicsPSOStream.VS).pShaderBytecode, although
we don't expect that to be a very common use case since typically the
dev will be assigning rather than accessing.

Additionally, we will provide prebuilt pipeline stream definitions for a
Full Pipeline Stream.

```C++
struct CD3DX12_PIPELINE_STATE_STREAM
{
    CD3DX12_PIPELINE_STATE_STREAM() {}
    CD3DX12_PIPELINE_STATE_STREAM(const D3D12_GRAPHICS_PIPELINE_STATE_DESC& Desc)
        : Flags(Desc.Flags)
        , NodeMask(Desc.NodeMask)
        , pRootSignature(Desc.pRootSignature)
        , InputLayout(Desc.InputLayout)
        , IBStripCutValue(Desc.IBStripCutValue)
        , PrimitiveTopologyType(Desc.PrimitiveTopologyType)
        , VS(Desc.VS)
        , GS(Desc.GS)
        , StreamOutput(Desc.StreamOutput)
        , HS(Desc.HS)
        , DS(Desc.DS)
        , PS(Desc.PS)
        , BlendState(CD3DX12_BLEND_DESC(Desc.BlendState))
        , DepthStencilState(CD3DX12_DEPTH_STENCIL_DESC1(Desc.DepthStencilState))
        , DSVFormat(Desc.DSVFormat)
        , RasterizerState(CD3DX12_RASTERIZER_DESC(Desc.RasterizerState))
        , RTVFormats(CD3DX12_RT_FORMAT_ARRAY(Desc.RTVFormats, Desc.NumRenderTargets))
        , SampleDesc(Desc.SampleDesc)
        , SampleMask(Desc.SampleMask)
        , CachedPSO(Desc.CachedPSO)
    {}

    CD3DX12_PIPELINE_STATE_STREAM(const D3D12_COMPUTE_PIPELINE_STATE_DESC& Desc)
        : Flags(Desc.Flags)
        , NodeMask(Desc.NodeMask)
        , pRootSignature(Desc.pRootSignature)
        , CS(CD3DX12_SHADER_BYTECODE(Desc.CS))
        , CachedPSO(Desc.CachedPSO)
    {}

    CD3DX12_PIPELINE_STATE_STREAM_FLAGS Flags;
    CD3DX12_PIPELINE_STATE_STREAM_NODE_MASK NodeMask;
    CD3DX12_PIPELINE_STATE_STREAM_ROOT_SIGNATURE pRootSignature;
    CD3DX12_PIPELINE_STATE_STREAM_INPUT_LAYOUT InputLayout;
    CD3DX12_PIPELINE_STATE_STREAM_IB_STRIP_CUT_VALUE IBStripCutValue;
    CD3DX12_PIPELINE_STATE_STREAM_PRIMITIVE_TOPOLOGY PrimitiveTopologyType;
    CD3DX12_PIPELINE_STATE_STREAM_VS VS;
    CD3DX12_PIPELINE_STATE_STREAM_GS GS;
    CD3DX12_PIPELINE_STATE_STREAM_STREAM_OUTPUT StreamOutput;
    CD3DX12_PIPELINE_STATE_STREAM_HS HS;
    CD3DX12_PIPELINE_STATE_STREAM_DS DS;
    CD3DX12_PIPELINE_STATE_STREAM_PS PS;
    CD3DX12_PIPELINE_STATE_STREAM_CS CS;
    CD3DX12_PIPELINE_STATE_STREAM_BLEND_DESC BlendState;
    CD3DX12_PIPELINE_STATE_STREAM_DEPTH_STENCIL1 DepthStencilState;
// Only contains latest
    CD3DX12_PIPELINE_STATE_STREAM_DEPTH_STENCIL_FORMAT DSVFormat;
    CD3DX12_PIPELINE_STATE_STREAM_RASTERIZER RasterizerState;
    CD3DX12_PIPELINE_STATE_STREAM_RENDER_TARGET_FORMATS RTVFormats;
    CD3DX12_PIPELINE_STATE_STREAM_SAMPLE_DESC SampleDesc;
    CD3DX12_PIPELINE_STATE_STREAM_SAMPLE_MASK SampleMask;
    CD3DX12_PIPELINE_STATE_STREAM_CACHED_PSO CachedPSO;

    D3D12_GRAPHICS_PIPELINE_STATE_DESC GraphicsDescV0() const
    {
        D3D12_GRAPHICS_PIPELINE_STATE_DESC D;
        D.Flags                 = this->Flags;
        ...
        D.NumRenderTargets      = D3D12_RT_FORMAT_ARRAY(this->RTVFormats).NumRenderTargets;
        memcpy(D.RTVFormats,D3D12_RT_FORMAT_ARRAY(this->RTVFormats).RTFormats,sizeof(D.RTVFormats));
        ...
        D.CachedPSO             = this->CachedPSO;
        return D;
    }

    D3D12_COMPUTE_PIPELINE_STATE_DESC ComputeDescV0() const
    {
        D3D12_COMPUTE_PIPELINE_STATE_DESC D;
        D.Flags                 = this->Flags;
        ...
        D.CachedPSO             = this->CachedPSO;
        return D;
    }
};
```

---

## New DXGI_FORMAT[] wrapper for RTVFormats

Having a raw array in our stream is cumbersome. We will add a new type
to our core API for wrapping RT format arrays.

```C++
struct D3D12_RT_FORMAT_ARRAY
{
  DXGI_FORMAT
  RTFormats[_countof(D3D12_GRAPHICS_PIPELINE_STATE_DESC::RTVFormats)];
  UINT NumRenderTargets;
};
```

Here's the CD3DX12 helpers:

```C++
struct CD3DX12_RT_FORMAT_ARRAY : public D3D12_RT_FORMAT_ARRAY
{
    CD3DX12_RT_FORMAT_ARRAY() = default;
    explicit CD3DX12_RT_FORMAT_ARRAY(const D3D12_RT_FORMAT_ARRAY& o)
        : D3D12_RT_FORMAT_ARRAY(o)
    {}

    explicit CD3DX12_RT_FORMAT_ARRAY(const DXGI_FORMAT* pFormats, UINT
        NumFormats)
            : NumRenderTargets(NumFormats)
    {
        memcpy(RTFormats, pFormats, sizeof(RTFormats));
        // assumes ARRAY_SIZE(pFormats) == ARRAY_SIZE(RTFormats)
    }

    operator const D3D12_RT_FORMAT_ARRAY&() const { return *this; }

};

typedef CD3DX12_PIPELINE_STATE_STREAM_ELEMENT<D3D12_RT_FORMAT_ARRAY,D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_RENDER_TARGET_FORMATS>
    CD3DX12_PIPELINE_STATE_STREAM_RENDER_TARGET_FORMATS;
```

This allows us to easily copy the array using the operator=
implementation and such:

```C++
auto RTVFormats =
    *reinterpret_cast\<CD3DX12_PIPELINE_STATE_STREAM_RENDER_TARGET_FORMATS*\>(pStream);

pStream += sizeof(RTVFormats);
```

---

## Component Interop

Due to the ambiguous nature of a PSO Stream, passing it across component
boundaries with any sort of type-safety is impossible. The expected
scenario is for components to pass
D3D12_PIPELINE_STATE_STREAM_DESCs, which is just a void* and size.
To alleviate the inconvenience, we will expose the parsing code and a
callback interface in the D3DX12 header so components can pass PSO
Streams to each other without having to implement their own parsing
functionality every time.

```C++
struct ID3DX12PipelineParserCallbacks
{
    // Subobject Callbacks
    virtual void FlagsCb(D3D12_PIPELINE_STATE_FLAGS) {}
    virtual void NodeMaskCb(UINT) {}
    virtual void RootSignatureCb(ID3D12RootSignature*) {}
    virtual void InputLayoutCb(const D3D12_INPUT_LAYOUT_DESC&) {}
    virtual void IBStripCutValueCb(D3D12_INDEX_BUFFER_STRIP_CUT_VALUE) {}
    virtual void PrimitiveTopologyTypeCb(D3D12_PRIMITIVE_TOPOLOGY_TYPE) {}
    virtual void VSCb(const D3D12_SHADER_BYTECODE&) {}
    virtual void GSCb(const D3D12_SHADER_BYTECODE&) {}
    virtual void StreamOutputCb(const D3D12_STREAM_OUTPUT_DESC&) {}
    virtual void HSCb(const D3D12_SHADER_BYTECODE&) {}
    virtual void DSCb(const D3D12_SHADER_BYTECODE&) {}
    virtual void PSCb(const D3D12_SHADER_BYTECODE&) {}
    virtual void CSCb(const D3D12_SHADER_BYTECODE&) {}
    virtual void BlendStateCb(const D3D12_BLEND_DESC&) {}
    virtual void DepthStencilStateCb(const D3D12_DEPTH_STENCIL_DESC&) {}
    virtual void DepthStencilState1Cb(const D3D12_DEPTH_STENCIL_DESC1&) {}
    virtual void DSVFormatCb(DXGI_FORMAT) {}
    virtual void RasterizerStateCb(const D3D12_RASTERIZER_DESC&) {}
    virtual void RTVFormatsCb(const D3D12_RT_FORMAT_ARRAY&) {}
    virtual void SampleDescCb(const DXGI_SAMPLE_DESC&) {}
    virtual void SampleMaskCb(UINT) {}
    virtual void CachedPSOCb(const D3D12_CACHED_PIPELINE_STATE&) {}

    // Error Callbacks
    virtual void ErrorBadInputParameter(UINT /*ParameterIndex*/) {}
    virtual void ErrorDuplicateSubobject(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE
    /*DuplicateType*/) {}
    virtual void ErrorUnknownSubobject(UINT /*UnknownTypeValue*/) {}
};

HRESULT D3DX12ParsePipelineStream(const D3D12_PIPELINE_STATE_STREAM_DESC& Desc,
    ID3DX12PipelineParserCallbacks* pCallbacks)
{
    ...
}
```

To facilitate duplicate subobject detection in the presence of subobject
versioning, we will need a concept of a "base" subobject and a utility
function to provide the mapping.

```C++
D3D12_PIPELINE_STATE_SUBOBJECT_TYPE D3DX12GetBaseSubobjectType(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE SubobjectType)
{
    switch (SubobjectType)
    {
    case D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_DEPTH_STENCIL1:
        return D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_DEPTH_STENCIL;
    default:
        return SubobjectType;
    }
}
```

Lastly, we will provide a Stream Parse Helper that contains a Full
Pipeline Stream as well as implements the callback interface. This can
be used as-is, or can be derived from to override only certain
functionality like the Error callbacks.

```C++
struct CD3DX12_PIPELINE_STATE_STREAM_PARSE_HELPER : public
    ID3DX12PipelineParserCallbacks
{
    CD3DX12_PIPELINE_STATE_STREAM PipelineStream;

    // ID3DX12PipelineParserCallbacks
    void FlagsCb(D3D12_PIPELINE_STATE_FLAGS Flags)
        {PipelineStream.Flags = Flags;}
    void NodeMaskCb(UINT NodeMask) {PipelineStream.NodeMask = NodeMask;}
    void RootSignatureCb(ID3D12RootSignature* pRootSignature)
        {PipelineStream.pRootSignature = pRootSignature;}
    void InputLayoutCb(const D3D12_INPUT_LAYOUT_DESC& InputLayout)
        {PipelineStream.InputLayout = InputLayout;}
    void IBStripCutValueCb(D3D12_INDEX_BUFFER_STRIP_CUT_VALUE IBStripCutValue)
        {PipelineStream.IBStripCutValue = IBStripCutValue;}
    void PrimitiveTopologyTypeCb(D3D12_PRIMITIVE_TOPOLOGY_TYPE
        PrimitiveTopologyType)
        {PipelineStream.PrimitiveTopologyType = PrimitiveTopologyType;}
    void VSCb(const D3D12_SHADER_BYTECODE& VS) {PipelineStream.VS = VS;}
    void GSCb(const D3D12_SHADER_BYTECODE& GS) {PipelineStream.GS = GS;}
    void StreamOutputCb(const D3D12_STREAM_OUTPUT_DESC& StreamOutput)
        {PipelineStream.StreamOutput = StreamOutput;}
    void HSCb(const D3D12_SHADER_BYTECODE& HS) {PipelineStream.HS = HS;}
    void DSCb(const D3D12_SHADER_BYTECODE& DS) {PipelineStream.DS = DS;}
    void PSCb(const D3D12_SHADER_BYTECODE& PS) {PipelineStream.PS = PS;}
    void CSCb(const D3D12_SHADER_BYTECODE& CS) {PipelineStream.CS = CS;}
    void BlendStateCb(const D3D12_BLEND_DESC& BlendState)
        {PipelineStream.BlendState = CD3DX12_BLEND_DESC(BlendState);}
    void DepthStencilStateCb(const D3D12_DEPTH_STENCIL_DESC& DepthStencilState)
        {PipelineStream.DepthStencilState =
        CD3DX12_DEPTH_STENCIL_DESC1(DepthStencilState);}
    void DepthStencilState1Cb(const D3D12_DEPTH_STENCIL_DESC1&
        DepthStencilState)
        {PipelineStream.DepthStencilState =
        CD3DX12_DEPTH_STENCIL_DESC1(DepthStencilState);}
    void DSVFormatCb(DXGI_FORMAT DSVFormat) {PipelineStream.DSVFormat =
        DSVFormat;}
    void RasterizerStateCb(const D3D12_RASTERIZER_DESC& RasterizerState)
        {PipelineStream.RasterizerState = CD3DX12_RASTERIZER_DESC(RasterizerState);}
    void RTVFormatsCb(const D3D12_RT_FORMAT_ARRAY& RTVFormats)
        {PipelineStream.RTVFormats = RTVFormats;}
    void SampleDescCb(const DXGI_SAMPLE_DESC& SampleDesc)
        {PipelineStream.SampleDesc = SampleDesc;}
    void SampleMaskCb(UINT SampleMask) {PipelineStream.SampleMask = SampleMask;}
    void CachedPSOCb(const D3D12_CACHED_PIPELINE_STATE& CachedPSO)
        {PipelineStream.CachedPSO = CachedPSO;}
    void ErrorBadInputParameter(UINT) {}
    void ErrorDuplicateSubobject(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE)
        {}
    void ErrorUnknownSubobject(UINT) {}
};
```

---

## Example Stream Construction

---

### Using the Core API

One of the simplest pipeline configurations is the one outlined in the
D3D11 hardware spec for IA + VS + No PS + Writes to Depth/Stencil
Enabled. Here is an example of how this would be done using the core
API.

```C++
struct MY_PIPELINE_STREAM
{
    D3D12_PIPELINE_STATE_SUBOBJECT_TYPE PTType = D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_PRIMITIVE_TOPOLOGY_TYPE;
    D3D12_PRIMITIVE_TOPOLOGY_TYPE PrimitiveToplogyType;
    D3D12_PIPELINE_STATE_SUBOBJECT_TYPE VSType = D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_VS;
    D3D12_SHADER_BYTECODE VS;
    D3D12_PIPELINE_STATE_SUBOBJECT_TYPE DSVType = D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_DSV_FORMAT;
    DXGI_FORMAT DSVFormat;
}

MY_PIPELINE_STREAM MyStream;

MyStream.PrimitiveToplogyType = D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE;

MyStream.VS = ...

MyStream.DSVFormat = DXGI_FORMAT_D32_FLOAT;

D3D12_PIPELINE_STATE_STREAM_DESC MyPipelineState =
    {D3D12_PIPELINE_STATE_STREAM_TYPE_GRAPHICS, sizeof(MyStream), &MyStream};

pDevice->CreatePipelineState(&MyPipelineState, ...);
```

---

### Using CD3DX12 Helpers

Using the same example as before, here's how it's done with CD3DX12
Helpers.

```C++
struct MY_PIPELINE_STREAM
{
  CD3DX12_PIPELINE_STATE_STREAM_PRIMITIVE_TOPOLOGY_TYPE PrimitiveTopologyType;
  CD3DX12_PIPLEINE_STATE_STREAM_VS VS;
  CD3DX12_PIPELINE_STATE_STREAM_DEPTH_STENCIL_FORMAT DSVFormat;\
}

MY_PIPLINE_STREAM MyStream;

MyStream.PrimitiveTopologyType = D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE;
MyStream.VS = ...
MyStream.DSVFormat = DXGI_FORMAT_D32_FLOAT;

D3D12_PIPELINE_STATE_STREAM_DESC MyPipelineState =
    {D3D12_PIPELINE_STATE_STREAM_TYPE_GRAPHICS, sizeof(MyStream),
    &MyStream};

pDevice->CreatePipelineState(&MyPipelineState, ...);
```

The difference here might not look huge for a minimal pipeline like this
one, but it is much more compact for a full pipeline consisting of all
21 subobjects.

---

## Versioning a Subobject

When we need to version a subobject, e.g. Depth Stencil State, we'll
have to create a new subobject struct since the runtime's stream parsing
implementation will still need to understand how to parse the old
version. Just updating the subobject struct to always use the latest
desc along with back-compat operators and constructors would necessitate
the runtime to keep around some hidden struct definitions for parsing,
so it seems simpler to just version the whole subobject struct,
essentially as we have done in previous D3D APIs.

```C++
// New subobject Type
typedef enum D3D12_PIPELINE_STATE_SUBOBJECT_TYPE
{
    ...
    D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_DEPTH_STENCIL1
} D3D12_PIPELINE_STATE_SUBOBJECT_TYPE;

// New desc with new feature
typedef struct D3D12_DEPTH_STENCIL_DESC1
{
    ...
    BOOL DepthBoundsTestEnable;
} D3D12_DEPTH_STENCIL_DESC1;

// Original subobject
typedef CD3DX12_PIPELINE_STATE_STREAM_ELEMENT<D3D12_PIPELINE_STATE_DEPTH_STENCIL_DESC,
    D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_DEPTH_STENCIL,CD3DX12_DEFAULT>
        CD3DX12_PIPELINE_STATE_STREAM_DEPTH_STENCIL;

// V1 subobject
typedef
CD3DX12_PIPELINE_STATE_STREAM_ELEMENT\<D3D12_PIPELINE_STATE_DEPTH_STENCIL_DESC1,
    D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_DEPTH_STENCIL1,CD3DX12_DEFAULT>
        CD3DX12_PIPELINE_STATE_STREAM_DEPTH_STENCIL1;
```

## Versioning the Full Graphics/Compute Streams

To version the full stream definitions, e.g.
CD3DX12_GRAPHICS_PIPELINE_STATE_STREAM, we will replace the old
subobject with the latest and no attempt at backwards compatibility of
this specific object will be made. We don't expect the full pipeline
streams to be used heavily and the information density cost of keeping
around old versions will be high due their lengthy nature. If need be,
we can add operators/constructors to the subobjects that allow for the
new subobject to compile seamlessly against code that is trying to
assign the old subobject desc.

## DepthBoundsTest API

The DBT range setting API will be exposed as a Graphics Command List
method in order to support dynamically changing the Depth Bounds. This
requires a new ID3D12GraphicsCommandList interface.

```C++
interface ID3D12GraphicsCommandList1
: ID3D12GraphicsCommandList
{
    ...
    void OMSetDepthBounds(
    FLOAT Min,
    FLOAT Max
    );
}
```

The default values are 0 and 1 for the Min and Max, respectively, and
NaNs are converted to 0.

We will add a CheckFeatureSupport query, e.g.
D3D12_FEATURE_D3D12_OPTIONS2, to determine whether this feature is
supported based on UMD version.

In addition to the setting of the Depth Bounds, an enable/disable toggle
will be added to the PSO in order to support hardware implementations
that configure their depth buffer reads in the PSO.

```C++
// Desc for D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_DEPTH_STENCIL1
typedef struct D3D12_DEPTH_STENCIL_DESC1
{
    BOOL DepthEnable;
    ...
    BOOL DepthBoundsTestEnable;
} D3D12_DEPTH_STENCIL_DESC1;
```

---

# DDI

A new Depth Stencil State Creation and Set Depth Bounds DDI will be
added to the set of 3D Command List DDIs. We will use the DDI versioning
scheme for a non-breaking build bump change (as detailed in
DDIHelper.hpp).

For the Depth Stencil State Creation DDI:

```C++
typedef struct D3D12DDI_DEPTH_STENCIL_DESC_0011
{
    ...
    BOOL DepthBoundsTestEnable;
} D3D12DDI_DEPTH_STENCIL_DESC_0011;

typedef SIZE_T ( APIENTRY* PFND3D12DDI_CALCPRIVATEDEPTHSTENCILSTATESIZE_0011 )(
    D3D12DDI_HDEVICE, _In_ CONST D3D12DDI_DEPTH_STENCIL_DESC_0011*
);

typedef VOID ( APIENTRY* PFND3D12DDI_CREATEDEPTHSTENCILSTATE_0011 )(
    D3D12DDI_HDEVICE, _In_ CONST D3D12DDI_DEPTH_STENCIL_DESC_0011*,
    D3D12DDI_HDEPTHSTENCILSTATE );

typedef struct D3D12DDI_DEVICE_FUNCS_CORE_0011
{
    ...
    PFND3D12DDI_CALCPRIVATEDEPTHSTENCILSTATESIZE_0011 pfnCalcPrivateDepthStencilStateSize;
    PFND3D12DDI_CREATEDEPTHSTENCILSTATE_0011 pfnCreateDepthStencilState;
    ...
} D3D12DDI_DEVICE_FUNCS_CORE_0011;
```

For the Set Depth Bounds DDI:

```C++
typedef VOID ( APIENTRY* PFND3D12DDI_OM_SETDEPTHBOUNDS_0011 )(
    D3D12DDI_HCOMMANDLIST, FLOAT Min, FLOAT Max);

typedef struct D3D12DDI_COMMAND_LIST_FUNCS_3D_0011 {
    ...
    PFND3D12DDI_OM_SETDEPTHBOUNDS pfnOMSetDepthBounds;
} D3D12DDI_COMMAND_LIST_FUNCS_3D_0011;
```

The default values are 0 and 1 for the minimum and maximum,
respectively.

A new D3D12DDICAPS_TYPE_D3D12_OPTIONS query will be added to the
GetCaps DDI to retrieve support information.

---

# Runtime Code

The implementation work in the runtime will consist of versioning the
device interface to add the new PSO Creation API implementation and
versioning command list interface to add the DBT range setting method.
Ideally, the DBT range setting API would have one implementation that
does a simple DDI call, and one that does a version/caps check and
removes the command list when the OMSetDepthBounds DDI is not supported.

The existing command list v-table design does not support optional DDIs.
Therefore, we need to add the ability for the DDI-filling code to query
the runtime to provide implementations for optional DDIs that a driver
doesn't want to support, e.g. the set for DBT range. The code would
consist of the UpdateGlobalDDITable function using the recursive
template parameter parsing mechanism to call a templated function that
looks like this (in pseudo code):

```C++
template<TableType TT, typename T>
FillUnsupportedDDIs(T& table)
{
    if (TT == command_list && DBTNotSupported())
    {
        __if_exists(T::pfnSetDBTRange)
        {
            Table.pfnSetDBTRange = pfnSetDBTRangeUnsupported;
        }
    }
}
```

## Runtime Validation

The API validation in the SDK layers will consist of a min-max inversion
check: min \max generates a warning message when SDK layers are
present.

The runtime will convert NaNs to 0.

---

## SDK Layers Validation

The API validation in the SDK layers will consist of a min-max inversion
check: min \> max generates a warning message when SDK layers are
present.

---

## D3DDbg Considerations

The D3DDbg windbg extension is able understand PSOs Descs. We will
update the SmallDepthStencilStateDesc to the latest (with the Depth
Bounds).

---

# Testing

---

## Functional

Functional tests will be written using the TAEF framework, use
driver-type WARP, integrate into D3DFunc_12_Core.dll, and verify
matching parameters at the DDI. This consists of using the TAEF mocking
functionality to check the DDI parameters passed to WARP. These tests
will be added to the RI-TP automatically by being included in
D3DFunc_12_Core.dll.

To enumerate the functional test cases:

- Verify min-max inversion validation, the following must still call
    WARP but generate a warning message

  - Min \> Max

- Verify the runtime calls WARP with matching values, and generates no
    error messages

  - Min \> 0, Max \< 1, Min \< Max

- Verify the runtime converts NaNs to Zero, calls WARP with Zeros, and
    generates no error messages

  - Min = NaN, Max = NaN

---

## Conformance

Conformance tests will be written using the TAEF framework, use
driver-type hardware, integrate into D3DConf_12_core.dll, and verify
driver and hardware behavior when Depth Bounds are set. These tests must
be integrated into the HLK (which requires Display Gatherer work), as
well as support being dropped to IHVs as a private binary.

The important hardware-behaviors to test are:

- the programmer-specified depth range is properly considered
    exclusive wrt to discarding

- DBT-failing pixel shader invocations do not affect a bound RT or
    depth stencil, and do not affect UAVs when ForceEarlyDepthStencil is
    enabled

- Depth Bounds Test affects Occlusion, Binary Occlusion, and Pipeline
    Statistics queries.

- Depth Bounds Test Behavior with respect to Bundles

The conformance test cases are:

1. Verify Depth Bounds Test correctly limits writes to the Render
    Target as well as UAVs
  - Bind a zeroed 1x5 RT with depth buffer, and a zeroed
        UINT-per-pixel sized UAV.
  - Enable ForceEarlyDepthStencil flag
  - Set the Depth Bounds to range \[0.3,0.6\]
  - Fill depth buffer with values: 0, 0.3, 0.5, 0.6, 1
    - 0 \< Min, so must be discarded
    - 0.3 == Min, so must affect memory
    - Min \< 0.5 \< Max, so must affect memory
    - 0.6 == Max, so must affect memory
    - 1 \> Max, so must be discarded
  - Render to all pixels
    - PS must output \<1,1,1,1\> to RT and 1 to the corresponding
            UAV address
  - Ensure only the pixels at \<0,1\>,\<0,2\>,\<0,3\> updated memory
        for both the RT and UAV
  - Ensure occlusion query reports 3 pixels passed
  - Ensure binary occlusion query reports true (pixels passed)
  - Ensure Pipeline Statistics PSInvocations reports 3 pixels

2. Run test \#1 but set Depth Bounds via a Bundle
  - Expect same result as \#1

3. Run test \#1 with no depth buffer bound
  - Expect no pixels updated, and matching query data

4. Run test \#1 with no depth buffer bound and Depth Bounds set to
    range \[0, 1\]
  - Expect all pixels updated, and matching query data

5. Run test \#1 with Depth Bounds set to range \[-FLT_MAX, FLT_MAX\]
  - Expect all pixels updated, and matching query data

6. Run test \#1 with Depth Bounds set to range \[FLT_MAX, -FLT_MAX\]
  - Expect no pixels updated (due to min-max inversion), and
        matching query data

---

# Change Log

- V1.0 -- First Draft

- V1.1 -- Updated behavior wrt to external effects (e.g. UAV writes)
    when the DBT fails: before external effects were prohibited, now
    they are prohibited or not based on early or late depth stencil.

- V1.2 -- Updated behavior when depth buffer is not bound: before DBT
    could be enabled and depth reads return 0, now it must always pass
    (which is now consistent with the Depth Test).

- V1.3 -- Removed note about Conservative oDepth since it was more
    confusing than helpful
