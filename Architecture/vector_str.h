//
//  vector_str.h
//  Architecture
//
//  Created by Tomas Virgl on 26/02/2015.
//  Copyright (c) 2015 Tomas Virgl. All rights reserved.
//

#ifndef Architecture_vector_str_h
#define Architecture_vector_str_h


/*******************************************************************************
 *                                                                              *
 *                                                                              *
 *                                                                              *
 *******************************************************************************/

/*******************************************************************************
 *                                                                              *
 *                                                                              *
 *                                                                              *
 *******************************************************************************/

struct __device_builtin__char1 {
    signed char x;
};

struct __device_builtin__uchar1 {
    unsigned char x;
};

struct __device_builtin__char2 {
    signed char x, y;
};

struct __device_builtin__uchar2 {
    unsigned char x, y;
};

struct __device_builtin__char3 {
    signed char x, y, z;
};

struct __device_builtin__uchar3 {
    unsigned char x, y, z;
};

struct __device_builtin__char4 {
    signed char x, y, z, w;
};

struct __device_builtin__uchar4 {
    unsigned char x, y, z, w;
};

struct __device_builtin__short1 {
    short x;
};

struct __device_builtin__ushort1 {
    unsigned short x;
};

struct __device_builtin__short2 {
    short x, y;
};

struct __device_builtin__ushort2 {
    unsigned short x, y;
};

struct __device_builtin__short3 {
    short x, y, z;
};

struct __device_builtin__ushort3 {
    unsigned short x, y, z;
};

//__cuda_builtin_vector_align8(short4, short x; short y; short z; short w;);
//__cuda_builtin_vector_align8(ushort4, unsigned short x; unsigned short y; unsigned short z; unsigned short w;);

struct __device_builtin__int1 {
    int x;
};
struct __device_builtin__int2 {
    int x;
    int y;
};

struct __device_builtin__uint1 {
    unsigned int x;
};
struct __device_builtin__uint2 {
    unsigned int x;
    unsigned int y;
};

//__cuda_builtin_vector_align8(int2, int x; int y;);
//__cuda_builtin_vector_align8(uint2, unsigned int x; unsigned int y;);

struct __device_builtin__int3 {
    int x, y, z;
};

struct __device_builtin__uint3 {
    unsigned int x, y, z;
};

struct __device_builtin__int4 {
    int x, y, z, w;
};

struct __device_builtin__uint4 {
    unsigned int x, y, z, w;
};

struct __device_builtin__long1 {
    long int x;
};

struct __device_builtin__ulong1 {
    unsigned long x;
};

struct __device_builtin__long2 {
    long int x, y;
};

struct __device_builtin__ulong2 {
    unsigned long int x, y;
};

struct __device_builtin__long3 {
    long int x, y, z;
};

struct __device_builtin__ulong3 {
    unsigned long int x, y, z;
};

struct __device_builtin__long4 {
    long int x, y, z, w;
};

struct __device_builtin__ulong4 {
    unsigned long int x, y, z, w;
};

struct __device_builtin__float1 {
    float x;
};

struct __device_builtin__float2 {
    float x;
    float y;
};

struct __device_builtin__float3 {
    float x, y, z;
};

struct __device_builtin__float4 {
    float x, y, z, w;
};

struct __device_builtin__longlong1 {
    long long int x;
};

struct __device_builtin__ulonglong1 {
    unsigned long long int x;
};

struct __device_builtin__longlong2 {
    long long int x, y;
};

struct __device_builtin__ulonglong2 {
    unsigned long long int x, y;
};

struct __device_builtin__longlong3 {
    long long int x, y, z;
};

struct __device_builtin__ulonglong3 {
    unsigned long long int x, y, z;
};

struct __device_builtin__longlong4 {
    long long int x, y, z, w;
};

struct __device_builtin__ulonglong4 {
    unsigned long long int x, y, z, w;
};

struct __device_builtin__double1 {
    double x;
};

struct __device_builtin__double2 {
    double x, y;
};

struct __device_builtin__double3 {
    double x, y, z;
};

struct __device_builtin__double4 {
    double x, y, z, w;
};

/*******************************************************************************
 *                                                                              *
 *                                                                              *
 *                                                                              *
 *******************************************************************************/

typedef struct __device_builtin__char1 char1;
typedef struct __device_builtin__uchar1 uchar1;
typedef struct __device_builtin__char2 char2;
typedef struct __device_builtin__uchar2 uchar2;
typedef struct __device_builtin__char3 char3;
typedef struct __device_builtin__uchar3 uchar3;
typedef struct __device_builtin__char4 char4;
typedef struct __device_builtin__uchar4 uchar4;
typedef struct __device_builtin__short1 short1;
typedef struct __device_builtin__ushort1 ushort1;
typedef struct __device_builtin__short2 short2;
typedef struct __device_builtin__ushort2 ushort2;
typedef struct __device_builtin__short3 short3;
typedef struct __device_builtin__ushort3 ushort3;
typedef struct __device_builtin__short4 short4;
typedef struct __device_builtin__ushort4 ushort4;
typedef struct __device_builtin__int1 int1;
typedef struct __device_builtin__uint1 uint1;
typedef struct __device_builtin__int2 int2;
typedef struct __device_builtin__uint2 uint2;
typedef struct __device_builtin__int3 int3;
typedef struct __device_builtin__uint3 uint3;
typedef struct __device_builtin__int4 int4;
typedef struct __device_builtin__uint4 uint4;
typedef struct __device_builtin__long1 long1;
typedef struct __device_builtin__ulong1 ulong1;
typedef struct __device_builtin__long2 long2;
typedef struct __device_builtin__ulong2 ulong2;
typedef struct __device_builtin__long3 long3;
typedef struct __device_builtin__ulong3 ulong3;
typedef struct __device_builtin__long4 long4;
typedef struct __device_builtin__ulong4 ulong4;
typedef struct __device_builtin__float1 float1;
typedef struct __device_builtin__float2 float2;
typedef struct __device_builtin__float3 float3;
typedef struct __device_builtin__float4 float4;

typedef struct __device_builtin__longlong1 longlong1;
typedef struct __device_builtin__ulonglong1 ulonglong1;
typedef struct __device_builtin__longlong2 longlong2;
typedef struct __device_builtin__ulonglong2 ulonglong2;
typedef struct __device_builtin__longlong3 longlong3;
typedef struct __device_builtin__ulonglong3 ulonglong3;
typedef struct __device_builtin__longlong4 longlong4;
typedef struct __device_builtin__ulonglong4 ulonglong4;
typedef struct __device_builtin__double1 double1;
typedef struct __device_builtin__double2 double2;
typedef struct __device_builtin__double3 double3;
typedef struct __device_builtin__double4 double4;

/*******************************************************************************
 *                                                                              *
 *                                                                              *
 *                                                                              *
 *******************************************************************************/

inline uint4 make_uint4(unsigned int x, unsigned int y, unsigned int z,
                        unsigned int w) {
    
    uint4 val;
    val.x = x;
    val.y = y;
    val.z = z;
    val.w = w;
    return val;
}

inline int4 make_int4(int x, int y, int z, int w) {
    
    int4 val;
    val.x = x;
    val.y = y;
    val.z = z;
    val.w = w;
    return val;
}
inline uint3 make_uint3(unsigned int x, unsigned int y, unsigned int z) {
    
    uint3 val;
    val.x = x;
    val.y = y;
    val.z = z;
    return val;
}
inline short2 make_short2(short x, short y) {
    short2 val;
    val.x = x;
    val.y = y;
    return val;
}

inline int3 make_int3(int x, int y, int z) {
    
    int3 val;
    val.x = x;
    val.y = y;
    val.z = z;
    return val;
}
inline float4 make_float4(float x, float y, float z, float w) {
    
    float4 val;
    val.x = x;
    val.y = y;
    val.z = z;
    val.w = w;
    return val;
}
inline float3 make_float3(float x, float y, float z) {
    
    float3 val;
    val.x = x;
    val.y = y;
    val.z = z;
    return val;
}
inline float2 make_float2(float x, float y) {
    
    float2 val;
    val.x = x;
    val.y = y;
    return val;
}
inline int2 make_int2(int x, int y) {
    int2 val;
    val.x = x;
    val.y = y;
    return val;
}
inline uint2 make_uint2(unsigned int x, unsigned int y) {
    uint2 val;
    val.x = x;
    val.y = y;
    return val;
}
inline uchar3 make_uchar3(unsigned char x, unsigned char y, unsigned char z) {
    uchar3 val;
    val.x = x;
    val.y = y;
    val.z = z;
    return val;
}
inline uchar4 make_uchar4(unsigned char x, unsigned char y, unsigned char z,
                          unsigned char w) {
    uchar4 val;
    val.x = x;
    val.y = y;
    val.z = z;
    val.w = w;
    return val;
}


#endif
