# HLSL Pack/Unpack Math Intrinsics

v1.00 2021-04-20

A new set of intrinsics are being added to HLSL for processing of packed 8bit data such as colors.

## Packed Datatypes

New packed datatype are added to HLSL's front end to symbolize a vector of packed 8bit values. 
```C++
uint8_t4_packed   // 4 packed uint8_t values in a uint32_t 
int8_t4_packed    // 4 packed int8_t values in a uint32_t 
```
These new packed datatypes are front end constructs to aid in the proper use of the new intrinsics. They can be cast to and from uint32_t values without a change in the bit representation. 

The new datatypes and assosiated intrinsics are a required feature for SM6.6.

## Unpack Intrinsics
A set of unpack intrinsics are being added to unpack 4 signed or unsigned 8-bit values into a vector of 16 bit values or a 32 bit values. The 32 bit vector will not require the 16 bit native support.

```C++
int16_t4 unpack_s8s16(int8_t4_packed packedVal);        // Sign Extended
uint16_t4 unpack_u8u16(uint8_t4_packed packedVal);      // Non-Sign Extended

int32_t4 unpack_s8s32(int8_t4_packed packedVal);        // Sign Extended
uint32_t4 unpack_u8u32(uint8_t4_packed packedVal);      // Non-Sign Extended
```

## Pack Intrinsics
Pack intrinsics will pack a vector of 4 signed or unsigned values into a packed 32 bit uint32_t represented by one of the new packed datatypes. Two versions of the pack intrinsics are defined. A version which performs a datatype clamp and a version which simply drops the unused bits.

```C++
uint8_t4_packed pack_u8(uint32_t4 unpackedVal);         // Pack lower 8 bits, drop unused bits
int8_t4_packed pack_s8(int32_t4  unpackedVal);          // Pack lower 8 bits, drop unused bits

uint8_t4_packed pack_u8(uint16_t4 unpackedVal);         // Pack lower 8 bits, drop unused bits
int8_t4_packed pack_s8(int16_t4  unpackedVal);          // Pack lower 8 bits, drop unused bits

uint8_t4_packed pack_clamp_u8(int32_t4  unpackedVal);   // Pack and Clamp [0, 255]
int8_t4_packed pack_clamp_s8(int32_t4  unpackedVal);    // Pack and Clamp [-128, 127]

uint8_t4_packed pack_clamp_u8(int16_t4  unpackedVal);   // Pack and Clamp [0, 255]
int8_t4_packed pack_clamp_s8(int16_t4  unpackedVal);    // Pack and Clamp [-128, 127]
```

## Quantized Multiply HLSL Shader

Dequantize linear equation is defined dequantizeValue = (X - Z_p) * S

```C++
int16_t4 x0 = unpack_u8s16(Read())
int16_t4 x1 = unpack_u8s16(Read())

int16_t z0 = unpack_u8s16(Read()).x
int16_t z1 = unpack_u8s16(Read()).x
int32_t z_output = unpack_u8s32(Read()).x

float s0 = Read()
float s1 = Read()
float s2 = Read()

float s_output = (s0 * s1)/s2;

int16_t4 x2 = x0 - z0.xxxx;
int16_t4 x3 = x1 - z1.xxxx;

int32_t4 x_mul = (int32_t4)x2 * (int32_t4)x3;

float4 x_float = x_mul * s_output.xxxx;
int32_t4 x_output = round(x_float);

x_output = x_output + z_output.xxxx;

uint8_t4_packed y = pack_clamp_u8(x_output);

write(y);
```

### DXIL Backend Example

```C++
%vec4.i16 = type { i16, i16, i16, i16 }

...

%read1 = ...
%read2 = ...
// unpack x0
%x0 = call %vec4.i16 @dx.unpack_u8s16(i32 <op>, i32 %read1)
%x0.0 = i16 extractelement %vec4.i16 %x0, 0
%x0.1 = i16 extractelement %vec4.i16 %x0, 1
%x0.2 = i16 extractelement %vec4.i16 %x0, 2
%x0.3 = i16 extractelement %vec4.i16 %x0, 3

// unpack x1
%z0 = call %vec4.i16 @dx.unpack_u8s16(i32 <op>, i32 %read3)
%z0.1 = i16 extractelement %vec4.i16 %z0, 0

// subtract x0 - z0.xxxx
%13 = i16 sub %x0.0, %z0.1
%14 = i16 sub %x0.1, %z0.1
%15 = i16 sub %x0.2, %z0.1
%16 = i16 sub %x0.3, %z0.1

...
```

# Change Log


Version|Date|Description
-|-|-
1.00|20 Apr 2021|Minor Edits for Publication