//
//  Raycast.metal
//  Architecture
//
//  Created by Tomas Virgl on 22/02/2015.
//  Copyright (c) 2015 Tomas Virgl. All rights reserved.
//

#include <metal_stdlib>
#include <metal_integer>
#include <metal_math>

using namespace metal;

#define fminf min
#define fmaxf max
#define make_float3 float3
#define make_float4 float4
#define Matrix4 float4x4
#define __global device
#define convert_int3 int3

#define INVALID -2

typedef struct sVolume {
    uint3 size;
    float3 dim;
   device short2 * data;
    // device float* data;
//    __global short2 * data;
} Volume;

inline float interp(const float3 pos, const Volume v);
inline float3 grad(float3 pos, const Volume v);

inline float3 get_translation(const Matrix4 view) {
    //return (float3)(view.data[0].w, view.data[1].w, view.data[2].w);
    // return (float3)(view[0].w, view[1].w, view[2].w);
  return float3(view[0].w, view[1].w, view[2].w);
}

inline float3 myrotate(const Matrix4 M, const float3 v) {
//    return (float3)(dot((float3)(M.data[0].x, M.data[0].y, M.data[0].z), v),
//                    dot((float3)(M.data[1].x, M.data[1].y, M.data[1].z), v),
//                    dot((float3)(M.data[2].x, M.data[2].y, M.data[2].z), v));
    
    // return (float3)(dot((float3)(M[0].x, M[0].y, M[0].z), v),
    //                 dot((float3)(M[1].x, M[1].y, M[1].z), v),
    //                 dot((float3)(M[2].x, M[2].y, M[2].z), v));
  return float3(dot((float3)(M[0].x, M[0].y, M[0].z), v),
                    dot((float3)(M[1].x, M[1].y, M[1].z), v),
                    dot((float3)(M[2].x, M[2].y, M[2].z), v));
}

float4 raycast(const Volume v, const uint2 pos, const Matrix4 view,
               const float nearPlane, const float farPlane, const float step,
               const float largestep);

float4 raycast(const Volume v, const uint2 pos, const Matrix4 view,
               const float nearPlane, const float farPlane, const float step,
               const float largestep) {
    
    // return float4(nearPlane, farPlane, step, 0);

    const float3 origin = get_translation(view);
//    const float3 direction = myrotate(view, (float3)(pos.x, pos.y, 1.f));
    const float3 direction = myrotate(view, float3(pos.x, pos.y, 1.f));
    
    // return float4(direction.x, direction.y, 0, 0);
    // intersect ray with a box
    //
    // www.siggraph.org/education/materials/HyperGraph/raytrace/rtinter3.htm
    // compute intersection of ray with all six bbox planes

    // const float3 invR = float3(1.0f) / direction;
    // const float3 tbot = float3( - 1 * invR * origin);
    // const float3 ttop = invR * (v.dim - origin);

    const float3 invR = float3(1.0f) / direction;
    const float3 tbot = float3( - 1 * invR * origin);
    const float3 ttop = invR * (v.dim - origin);

    // const float3 invR = float3(1.0f) / direction;
    // const float3 tbot = float3( (-origin) / direction);

    // const float3 invR = float3(1.0f) / direction;
    // const float3 ttop = float3(1.0f) / direction * (v.dim - origin);

    // a * (c-b) = ac - ab
    
    
    // re-order intersections to find smallest and largest on each axis
    const float3 tmin = fmin(ttop, tbot);
    const float3 tmax = fmax(ttop, tbot);
//    return //float4(ttop, tbot, 0, 0);
//    return float4(ttop);
//    return tbot;
    
    // find the largest tmin and the smallest tmax
    const float largest_tmin = fmax(fmax(tmin.x, tmin.y), fmax(tmin.x, tmin.z));
    const float smallest_tmax = fmin(fmin(tmax.x, tmax.y),
                                     fmin(tmax.x, tmax.z));
    
    // check against near and far plane
    const float tnear = fmax(largest_tmin, nearPlane);
    const float tfar = fmin(smallest_tmax, farPlane);
    

     // return float4(tnear, tfar, 0, 0);
    if (tnear < tfar) {
        // first walk with largesteps until we found a hit
        float t = tnear;
        float stepsize = largestep;
        float f_t = interp(origin + direction * t, v);

        // return float4(-7);
//        float f_t = 0;
        // return float4(f_t);
        // f_t = 0.1;
        float f_tt = 0;
        if (f_t > 0) { // ups, if we were already in it, then don't render anything here
            for (; t < tfar; t += stepsize) {
                // return float4(-7);
                f_tt = interp(origin + direction * t, v);
                // f_tt = 0;
                // return float4(f_tt);
                if (f_tt < 0)                  // got it, jump out of inner loop
                    break;
                if (f_tt < 0.8f)               // coming closer, reduce stepsize
                    stepsize = step;
                f_t = f_tt;
            }
            // return float4(-3);
            if (f_tt < 0) {           // got it, calculate accurate intersection
                // t = t + stepsize * f_tt / (f_t - f_tt);

                // t += stepsize * f_tt / (f_t - f_tt);
                t += stepsize * f_tt / (f_t - f_tt);
                return float4(origin + direction * t, t);
            }
        }
    }
    
    return float4(0);
}

//a* (b/ (c-b))

inline thread uint ror(uint inp, int rot) {
    uint2 q = uint2(inp, inp);
    return rotate(q, rot).x;
}

inline thread ushort convertToHalf1(float f){
//    ushort qq;
    float q = f;
//    float q = as_type<float>(0xf3c5210c);
    uint qx = as_type<uint>(q);
    ushort q1 = ushort(qx);
    uint rr = ror(qx, 16);
    ushort q2 = ushort(rr);
//    qq[0] = q1;
    return q1;
}


inline thread ushort convertToSecondHalf1(float f){
//    ushort4 qq;
//    float q = as_type<float>(0xf3c5210c);
    float q = f;
    uint qx = as_type<uint>(q);
    ushort q1 = ushort(qx);
    uint rr = ror(qx, 16);
    ushort q2 = ushort(rr);
//    qq[0] = q2;
    return q2;
}


inline thread ushort4 convertToHalf(float4 f){
    ushort4 qq;
    qq.x = convertToHalf1(f.x);
    qq.y = convertToHalf1(f.y);
    qq.z = convertToHalf1(f.z);
    qq.w = convertToHalf1(f.w);
    return qq;
}

inline thread ushort4 convertToSecondHalf(float4 f){
    ushort4 qq;
    qq.x = convertToSecondHalf1(f.x);
    qq.y = convertToSecondHalf1(f.y);
    qq.z = convertToSecondHalf1(f.z);
    qq.w = convertToSecondHalf1(f.w);
    return qq;
}


kernel void raycastKernel(
                          texture2d<float, access::read> inputTexture [[texture(0)]],

                          // texture2d<ushort, access::write> pos3D [[texture(1)]],
                          // texture2d<ushort, access::write> normal [[texture(2)]],
                          // texture2d<ushort, access::write> pos3D1 [[texture(3)]],
                          // texture2d<ushort, access::write> normal1 [[texture(4)]],

                          uint2 pos [[thread_position_in_grid]],
                          
                          device const Matrix4* viewp [[buffer(0)]],
                          device const float* nearPlanep [[buffer(1)]],
                          device const float* farPlanep [[buffer(2)]],
                          device const float* stepp [[buffer(3)]],
                          device const float* largestepp [[buffer(4)]],

                          device const uint* volsizex [[buffer(5)]],
                          device const uint* volsizey [[buffer(6)]],
                          device const uint* volsizez [[buffer(7)]],

                          device const float* voldimx [[buffer(8)]],
                          device const float* voldimy [[buffer(9)]],
                          device const float* voldimz [[buffer(10)]],

                          device short2* voldata [[buffer(11)]],
                          // device float* voldata [[buffer(11)]],
                          device float3* outBuf [[buffer(12)]],
                          device float3* outBuf2 [[buffer(13)]]
                          ) {
    Volume volume;
    volume.size = uint3(*volsizex,*volsizey,*volsizez);
    volume.dim  = float3(*voldimx,*voldimy,*voldimz);
    volume.data = voldata;

    Matrix4 view = *viewp;
    float nearPlane = *nearPlanep;
    float farPlane = *farPlanep;
    float step = *stepp;
    float largestep = *largestepp;
    
    // uint2 fpos;
    // fpos.x = 0;
    // fpos.y = 0;


    // float4 qq = float4(-1);

    // pos3D.write(convertToHalf(qq), pos);
    // pos3D1.write(convertToSecondHalf(qq), pos);
    // normal.write(convertToHalf(qq), pos);
    // normal1.write(convertToSecondHalf(qq), pos);    


   const float4 hit = raycast(volume, pos, view, nearPlane, farPlane, step, largestep);//TODO
//      const float4 hit = raycast(volume, pos, view, nearPlane, farPlane, step, largestep);//TODO
     // float4 hit = raycast(volume, fpos, view, nearPlane, farPlane, step, largestep);
   // qq = float4(hit.w);

   //  pos3D.write(convertToHalf(qq), pos);
   //  pos3D1.write(convertToSecondHalf(qq), pos);
   //  normal.write(convertToHalf(qq), pos);
   //  normal1.write(convertToSecondHalf(qq), pos);    
    // return;

    float4 ret;
    float4 ret2;
    if (hit.w > 0) {
        // pos3D.write(convertToHalf(hit), pos);
        // pos3D1.write(convertToSecondHalf(hit), pos);
        float3 surfNorm = grad(make_float3(hit), volume);
        
        float4 rt;
        if (length(surfNorm) == 0) {
            rt = float4(INVALID,0,0,0);
        } else {
            rt = float4(normalize(surfNorm));
        }
        // normal.write(convertToHalf(rt), pos);
        // normal1.write(convertToSecondHalf(rt), pos);
        // return;
        ret = rt;
        ret2 = hit;
    } else {
        float4 ps = float4(0);
        // pos3D.write(convertToHalf(ps), pos);
        // pos3D1.write(convertToSecondHalf(ps), pos);
        float4 inv = float4(-2);
        // normal.write(convertToHalf(inv), pos);
        // normal1.write(convertToSecondHalf(inv), pos);
        // return;
        ret = inv;
        ret2 = ps;
    }

    outBuf[pos.x + 640 * pos.y] = float3(ret);
    outBuf2[pos.x + 640 * pos.y] = float3(ret2);
}

// inline int3 convert_int3(float3 f) {
//     return (int3) f;
// }

// inline int3 convert_int3(uint3 f) {
//     return (int3) f;
// }

inline float vs(const uint3 pos, const Volume v) {
   return v.data[pos.x + pos.y * v.size.x + pos.z * v.size.x * v.size.y].x;
    // return v.data[pos.x + pos.y * v.size.x + pos.z * v.size.x * v.size.y];
}


// inline float3 fract(float3 x, thread float3* ipt) {
//     *ipt = floor(x);
//     return fract(x);
// }

// inline float interp(const float3 pos, const Volume v) {
float interp(const float3 pos, const Volume v) {
    // const float3 scaled_pos = (float3)((pos.x * v.size.x / v.dim.x) - 0.5f,
    //                                    (pos.y * v.size.y / v.dim.y) - 0.5f,
    //                                    (pos.z * v.size.z / v.dim.z) - 0.5f);
    
    const float3 scaled_pos = (pos * float3(v.size) / v.dim) - float3(0.5);
    const int3 base = convert_int3(floor(scaled_pos));

// float3 basef = (float3)(0);

//    const float3 factor = float3(fract(scaled_pos, (float3 *) &basef)); // TODO
    // const float3 factor = float3(fract(scaled_pos, (thread float3 *) &basef)); // TODO
//    const int3 lower = max(base, (int3)(0));
//    const int3 upper = min(base + (int3)(1), convert_int3(v.size) - (int3)(1));

    const float3 factor = fract(scaled_pos);
    const uint3 lower = (uint3)max(base, (int3)(0));
    const uint3 upper = (uint3)min(base + (int3)(1), convert_int3(v.size) - (int3)(1));
    // return  upper.x;
    return (((vs((uint3)(lower.x, lower.y, lower.z), v) * (1 - factor.x)
              + vs((uint3)(upper.x, lower.y, lower.z), v) * factor.x)
             * (1 - factor.y)
             + (vs((uint3)(lower.x, upper.y, lower.z), v) * (1 - factor.x)
                + vs((uint3)(upper.x, upper.y, lower.z), v) * factor.x)
             * factor.y) * (1 - factor.z)
            + ((vs((uint3)(lower.x, lower.y, upper.z), v) * (1 - factor.x)
                + vs((uint3)(upper.x, lower.y, upper.z), v) * factor.x)
               * (1 - factor.y)
               + (vs((uint3)(lower.x, upper.y, upper.z), v)
                  * (1 - factor.x)
                  + vs((uint3)(upper.x, upper.y, upper.z), v)
                  * factor.x) * factor.y) * factor.z)
    * 0.00003051944088f;

    // return factor.x;

    // return vs(uint3(lower.x, lower.y, lower.z), v);
    
    // return (vs(uint3(lower.x, lower.y, lower.z), v) * (1 - factor.x)
    //           + vs(uint3(upper.x, lower.y, lower.z), v) * factor.x);

    // return (vs(uint3(lower.x, lower.y, lower.z), v) * (1 - factor.x)
    //           + vs(uint3(upper.x, lower.y, lower.z), v) * factor.x);

  // return (((vs((uint3)(lower.x, lower.y, lower.z), v) * (1 - factor.x)
  //             + vs((uint3)(upper.x, lower.y, lower.z), v) * factor.x)
  //            * (1 - factor.y)
  //            + (vs((uint3)(lower.x, upper.y, lower.z), v) * (1 - factor.x)
  //               + vs((uint3)(upper.x, upper.y, lower.z), v) * factor.x)
  //            * factor.y) * (1 - factor.z)
  //           + ((vs((uint3)(lower.x, lower.y, upper.z), v) * (1 - factor.x)
  //               + vs((uint3)(upper.x, lower.y, upper.z), v) * factor.x)
  //              * (1 - factor.y)
  //              + (vs((uint3)(lower.x, upper.y, upper.z), v)
  //                 * (1 - factor.x)
  //                 + vs((uint3)(upper.x, upper.y, upper.z), v)
  //                 * factor.x) * factor.y) * factor.z);
       
}

inline float3 grad(float3 pos, const Volume v) {
    // const float3 scaled_pos = (float3)((pos.x * v.size.x / v.dim.x) - 0.5f,
    //                                    (pos.y * v.size.y / v.dim.y) - 0.5f,
    //                                    (pos.z * v.size.z / v.dim.z) - 0.5f);
    const float3 scaled_pos = (pos * float3(v.size) / v.dim) - float3(0.5);
//    const int3 base = (int3)(floor(scaled_pos.x), floor(scaled_pos.y),
//                             floor(scaled_pos.z));
    
    const int3 base = convert_int3(float3(floor(scaled_pos.x), floor(scaled_pos.y), floor(scaled_pos.z)));
    
    // const float3 basef = (float3)(0);
    // const float3 factor = (float3) fract(scaled_pos, (thread float3 *) &basef);

    const float3 factor = fract(scaled_pos);
//    const int3 lower_lower = max(base - (int3)(1), (int3)(0));
//    const int3 lower_upper = max(base, (int3)(0));
//    const int3 upper_lower = min(base + (int3)(1),
//                                 convert_int3(v.size) - (int3)(1));
//    const int3 upper_upper = min(base + (int3)(2),
//                                 convert_int3(v.size) - (int3)(1));
//    const int3 lower = lower_upper;
//    const int3 upper = upper_lower;
//
//    const uint3 lower = (uint3)lower_upper;
//    const uint3 upper = (uint3)upper_lower;
    
    const uint3 lower_lower = (uint3)max(base - (int3)(1), (int3)(0));
    const uint3 lower_upper = (uint3)max(base, (int3)(0));
    const uint3 upper_lower = (uint3)min(base + (int3)(1),
                                 convert_int3(v.size) - (int3)(1));
    const uint3 upper_upper = (uint3)min(base + (int3)(2),
                                 convert_int3(v.size) - (int3)(1));
    const uint3 lower = lower_upper;
    const uint3 upper = upper_lower;


    float3 gradient;
    
    gradient.x = (((vs((uint3)(upper_lower.x, lower.y, lower.z), v)
                    - vs((uint3)(lower_lower.x, lower.y, lower.z), v)) * (1 - factor.x)
                   + (vs((uint3)(upper_upper.x, lower.y, lower.z), v)
                      - vs((uint3)(lower_upper.x, lower.y, lower.z), v))
                   * factor.x) * (1 - factor.y)
                  + ((vs((uint3)(upper_lower.x, upper.y, lower.z), v)
                      - vs((uint3)(lower_lower.x, upper.y, lower.z), v))
                     * (1 - factor.x)
                     + (vs((uint3)(upper_upper.x, upper.y, lower.z), v)
                        - vs((uint3)(lower_upper.x, upper.y, lower.z), v))
                     * factor.x) * factor.y) * (1 - factor.z)
    + (((vs((uint3)(upper_lower.x, lower.y, upper.z), v)
         - vs((uint3)(lower_lower.x, lower.y, upper.z), v))
        * (1 - factor.x)
        + (vs((uint3)(upper_upper.x, lower.y, upper.z), v)
           - vs((uint3)(lower_upper.x, lower.y, upper.z), v))
        * factor.x) * (1 - factor.y)
       + ((vs((uint3)(upper_lower.x, upper.y, upper.z), v)
           - vs((uint3)(lower_lower.x, upper.y, upper.z), v))
          * (1 - factor.x)
          + (vs((uint3)(upper_upper.x, upper.y, upper.z), v)
             - vs(
                  (uint3)(lower_upper.x, upper.y,   
                          upper.z), v)) * factor.x)
							* factor.y) * factor.z;
    
    gradient.y = (((vs((uint3)(lower.x, upper_lower.y, lower.z), v)
                    - vs((uint3)(lower.x, lower_lower.y, lower.z), v)) * (1 - factor.x)
                   + (vs((uint3)(upper.x, upper_lower.y, lower.z), v)
                      - vs((uint3)(upper.x, lower_lower.y, lower.z), v))
                   * factor.x) * (1 - factor.y)
                  + ((vs((uint3)(lower.x, upper_upper.y, lower.z), v)
                      - vs((uint3)(lower.x, lower_upper.y, lower.z), v))
                     * (1 - factor.x)
                     + (vs((uint3)(upper.x, upper_upper.y, lower.z), v)
                        - vs((uint3)(upper.x, lower_upper.y, lower.z), v))
                     * factor.x) * factor.y) * (1 - factor.z)
    + (((vs((uint3)(lower.x, upper_lower.y, upper.z), v)
         - vs((uint3)(lower.x, lower_lower.y, upper.z), v))
        * (1 - factor.x)
        + (vs((uint3)(upper.x, upper_lower.y, upper.z), v)
           - vs((uint3)(upper.x, lower_lower.y, upper.z), v))
        * factor.x) * (1 - factor.y)
       + ((vs((uint3)(lower.x, upper_upper.y, upper.z), v)
           - vs((uint3)(lower.x, lower_upper.y, upper.z), v))
          * (1 - factor.x)
          + (vs((uint3)(upper.x, upper_upper.y, upper.z), v)
             - vs(
                  (uint3)(upper.x, lower_upper.y,
                          upper.z), v)) * factor.x)
							* factor.y) * factor.z;
    
    gradient.z = (((vs((uint3)(lower.x, lower.y, upper_lower.z), v)
                    - vs((uint3)(lower.x, lower.y, lower_lower.z), v)) * (1 - factor.x)
                   + (vs((uint3)(upper.x, lower.y, upper_lower.z), v)
                      - vs((uint3)(upper.x, lower.y, lower_lower.z), v))
                   * factor.x) * (1 - factor.y)
                  + ((vs((uint3)(lower.x, upper.y, upper_lower.z), v)
                      - vs((uint3)(lower.x, upper.y, lower_lower.z), v))
                     * (1 - factor.x)
                     + (vs((uint3)(upper.x, upper.y, upper_lower.z), v)
                        - vs((uint3)(upper.x, upper.y, lower_lower.z), v))
                     * factor.x) * factor.y) * (1 - factor.z)
    + (((vs((uint3)(lower.x, lower.y, upper_upper.z), v)
         - vs((uint3)(lower.x, lower.y, lower_upper.z), v))
        * (1 - factor.x)
        + (vs((uint3)(upper.x, lower.y, upper_upper.z), v)
           - vs((uint3)(upper.x, lower.y, lower_upper.z), v))
        * factor.x) * (1 - factor.y)
       + ((vs((uint3)(lower.x, upper.y, upper_upper.z), v)
           - vs((uint3)(lower.x, upper.y, lower_upper.z), v))
          * (1 - factor.x)
          + (vs((uint3)(upper.x, upper.y, upper_upper.z), v)
             - vs(
                  (uint3)(upper.x, upper.y,
                          lower_upper.z), v))
          * factor.x) * factor.y) * factor.z;
    
    return gradient
    * (float3)(v.dim.x / v.size.x, v.dim.y / v.size.y,
               v.dim.z / v.size.z) * (0.5f * 0.00003051944088f);
}


/*
 inline thread ushort4 convertToHalf(float4 f){
 ushort4 qq;
 float q = as_type<float>(0xf3c5210c);
 uint qx = as_type<uint>(q);
 ushort q1 = ushort(qx);
 uint rr = ror(qx, 16);
 ushort q2 = ushort(rr);
 qq[0] = q1;
 return qq;
 }
 
 inline thread ushort4 convertToSecondHalf(float4 f){
 ushort4 qq;
 float q = as_type<float>(0xf3c5210c);
 uint qx = as_type<uint>(q);
 ushort q1 = ushort(qx);
 uint rr = ror(qx, 16);
 ushort q2 = ushort(rr);
 qq[0] = q2;
 return qq;
 }
 */
/*
 inline thread ushort4 convertToSecondHalf(float4 f){
 ushort4 q;
 float x = f[0];
 float y = f[1];
 float z = f[2];
 float w = f[3];
 
 //    q[0] = *(((thread ushort*)&x)+16);
 //    q[1] = *(((thread ushort*)&y)+16);
 //    q[2] = *(((thread ushort*)&z)+16);
 //    q[3] = *(((thread ushort*)&w)+16);
 
 convert_ushort_saturate()
 
 
 q[0] = 0x1112;
 q[1] = 0x1314;
 q[2] = 0x1516;
 q[3] = 0x1718;
 
 return q;
 //return 0xBEEF;
 }*/

/*
 inline thread ushort4 convertToHalf(float4 f){
 ushort4 q;
 //    float x = f[0];
 //    float x = -2;
 half x = -2;
 float y = f[1];
 float z = f[2];
 float w = f[3];
 
 //    q[0] = *(thread ushort*)&x;
 //    q[0] = *(reinterpret_cast<thread ushort *>(&x));
 
 
 float q = -1;
 uint qx = as_type<uint>(q);
 ushort q1 = as_type<ushort>(qx);
 ushort q2 = as_type<ushort>(rotate(qx, 16));
 
 //q[1] = *(thread ushort*)&y;
 //q[2] = *(thread ushort*)&z;
 //q[3] = *(thread ushort*)&w;
 
 return q;
 //return 0xFFFF;
 }
 
 inline thread ushort4 convertToSecondHalf(float4 f){
 ushort4 q;
 float x = f[0];
 float y = f[1];
 float z = f[2];
 float w = f[3];
 
 q[0] = *(((thread ushort*)&x)+16);
 q[1] = *(((thread ushort*)&y)+16);
 q[2] = *(((thread ushort*)&z)+16);
 q[3] = *(((thread ushort*)&w)+16);
 
 
 q[0] = 0x1112;
 q[1] = 0x1314;
 q[2] = 0x1516;
 q[3] = 0x1718;
 
 return q;
 //return 0xBEEF;
 }
 */

/*
 union UTemp{
 float fl;
 struct strct {
 ushort a;
 ushort b;
 };
 };
 
 inline void convertToHalf(float4 f, thread ushort4* a, thread ushort4* b){
 //    *a = (thread ushort *) &f;
 //*(a[0]) = (thread ushort *) (f[0]);
 //    ushort x = a[0][0];
 
 *(a[0][0]) = (thread ushort *) (f[0]);
 //    *b =
 }*/



/*kernel void raycastKernel(Image<float3> pos3D,
 Image<float3> normal,
 const Volume volume,
 const Matrix4 view,
 const float nearPlane,
 const float farPlane,
 const float step,
 const float largestep) {*/
/*
 
 
 typedef struct sVolume {
 uint3 size;
 float3 dim;
 __global short2 * data;
 } Volume;
 
 */
/*
 kernel void raycastKernel2(texture2d<float, access::read> inputTexture [[texture(0)]],
 texture2d<float, access::write> pos3D [[texture(1)]],
 texture2d<float, access::write> normal [[texture(2)]],
 uint2 pos [[thread_position_in_grid]],
 
 device const Matrix4* viewp [[buffer(0)]],
 device const float* nearPlanep [[buffer(1)]],
 device const float* farPlanep [[buffer(2)]],
 device const float* stepp [[buffer(3)]],
 device const float* largestepp [[buffer(4)]],
 
 device const uint* volsizex [[buffer(5)]],
 device const uint* volsizey [[buffer(6)]],
 device const uint* volsizez [[buffer(7)]],
 
 device const float* voldimx [[buffer(8)]],
 device const float* voldimy [[buffer(9)]],
 device const float* voldimz [[buffer(10)]],
 
 device short2* voldata [[buffer(11)]]
 ) {
 
 //pos3D.write(float4(2), pos);
 pos3D.write(float4(255,0,0,0), pos);
 normal.write(float4(255,0,0,0), pos);
 //      normal.write(float4(2), pos);
 
 }
 */