//
//  Shader.metal
//  Architecture
//
//  Created by Tomas Virgl on 20/02/2015.
//  Copyright (c) 2015 Tomas Virgl. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void grayscale(texture2d<float, access::read> inputTexture [[texture(0)]],
                      texture2d<float, access::write> outputTexture [[texture(1)]],
                      uint2 gid [[thread_position_in_grid]])
{
    float4 color = inputTexture.read(gid);
//    float gray = dot(color.xyz, float3(0.3, 0.59, 0.11));
    float gray = dot(color.xyz, float3(0.9, 0, 0));
    float f = dot(color.xyz, float3(0.2, 0.8, 0.3));
    float h = dot(color.xyz, float3(0.9, 0, 0.5));
    float q = dot(color.xyz, float3(0.9, 0.8, 0));

    outputTexture.write(float4(gray,f,h,q), gid);
//    outputTexture.write(float4(0,0,255,0), gid);

    //outputTexture.write(float4(gray), gid);
}

/*
(const Volume volume, -- TODO
 const uint2 pos, -- TODO
 const Matrix4 view,  ==> float4x4
 const float nearPlane,
 const float farPlane, 
 const float step,
 const float largestep) {
*/


/*notes
 inline float3 get_translation(const Matrix4 view) {
	return make_float3(view.data[0].w, view.data[1].w, view.data[2].w);
 }

 
 inline float3 rotate(const Matrix4 & M, const float3 & v) {
	return make_float3(dot(make_float3(M.data[0]), v),
 dot(make_float3(M.data[1]), v), dot(make_float3(M.data[2]), v));
 }
 
 */
//                    const device float4 *inA [[ buffer(0) ]],

//kernel void raycast(

/*
inline float vs2(const uint x, const uint y, const uint z, short2 data, uint3 size) {
    //return data[x + y * size.x + z * size.x * size.y].x;
    return data[x + y * size.x + z * size.x * size.y];
}

float interp(const float3 pos, float3 dim, uint3 size);
float interp(const float3 pos, float3 dim, uint3 size){
    
    const float3 scaled_pos = float3((pos.x * size.x / dim.x) - 0.5f,
                                          (pos.y * size.y / dim.y) - 0.5f,
                                          (pos.z * size.z / dim.z) - 0.5f);
    const int3 base = int3(floor(scaled_pos));
    const float3 factor = fract(scaled_pos);
    const int3 lower = max(base, int3(0));
    const int3 upper = min(base + int3(1),
                           int3(size) - int3(1));
    return (((vs2(lower.x, lower.y, lower.z) * (1 - factor.x)
              + vs2(upper.x, lower.y, lower.z) * factor.x) * (1 - factor.y)
             + (vs2(lower.x, upper.y, lower.z) * (1 - factor.x)
                + vs2(upper.x, upper.y, lower.z) * factor.x) * factor.y)
            * (1 - factor.z)
            + ((vs2(lower.x, lower.y, upper.z) * (1 - factor.x)
                + vs2(upper.x, lower.y, upper.z) * factor.x)
               * (1 - factor.y)
               + (vs2(lower.x, upper.y, upper.z) * (1 - factor.x)
                  + vs2(upper.x, upper.y, upper.z) * factor.x)
               * factor.y) * factor.z) * 0.00003051944088f;
    
}*/

/*
struct Volume {
    uint3 size;
    float3 dim;
    device short2 * data;
    
//    Volume() {
//        size = uint3(0);
//        dim = float3(1);
//        data = NULL;
//    }
    
    inline float vs2(const uint x, const uint y, const uint z) const {
        //return data[x + y * size.x + z * size.x * size.y].x;
        //return data[x + y * size.x + z * size.x * size.y]; // Masive TODO
        return data[x + y * size.x + z * size.x * size.y][0]; // Masive TODO
    }
    
    const float interp(const float3 pos) const {
        const float3 scaled_pos = float3((pos.x * size.x / dim.x) - 0.5f,
                                         (pos.y * size.y / dim.y) - 0.5f,
                                         (pos.z * size.z / dim.z) - 0.5f);
        const int3 base = int3(floor(scaled_pos));
        const float3 factor = fract(scaled_pos);
        const int3 lower = max(base, int3(0));
        const int3 upper = min(base + int3(1),
                               int3(size) - int3(1));
        return (((vs2(lower.x, lower.y, lower.z) * (1 - factor.x)
                  + vs2(upper.x, lower.y, lower.z) * factor.x) * (1 - factor.y)
                 + (vs2(lower.x, upper.y, lower.z) * (1 - factor.x)
                    + vs2(upper.x, upper.y, lower.z) * factor.x) * factor.y)
                * (1 - factor.z)
                + ((vs2(lower.x, lower.y, upper.z) * (1 - factor.x)
                    + vs2(upper.x, lower.y, upper.z) * factor.x)
                   * (1 - factor.y)
                   + (vs2(lower.x, upper.y, upper.z) * (1 - factor.x)
                      + vs2(upper.x, upper.y, upper.z) * factor.x)
                   * factor.y) * factor.z) * 0.00003051944088f;
        
    }
};*/

#define vs2(x,y,z) vs22(x,y,z,size,data)

inline float vs22(const uint x, const uint y, const uint z, uint3 size, device short2 * data) {
    return data[x + y * size.x + z * size.x * size.y][0]; // Masive TODO
}

const float interp(const float3 pos, uint3 size, float3 dim, device short2 * data);
const float interp(const float3 pos, uint3 size, float3 dim, device short2 * data) {
    const float3 scaled_pos = float3((pos.x * size.x / dim.x) - 0.5f,
                                     (pos.y * size.y / dim.y) - 0.5f,
                                     (pos.z * size.z / dim.z) - 0.5f);
    const int3 base = int3(floor(scaled_pos));
    const float3 factor = fract(scaled_pos);
    const int3 lower = max(base, int3(0));
    const int3 upper = min(base + int3(1),
                           int3(size) - int3(1));
    return (((vs2(lower.x, lower.y, lower.z) * (1 - factor.x)
              + vs2(upper.x, lower.y, lower.z) * factor.x) * (1 - factor.y)
             + (vs2(lower.x, upper.y, lower.z) * (1 - factor.x)
                + vs2(upper.x, upper.y, lower.z) * factor.x) * factor.y)
            * (1 - factor.z)
            + ((vs2(lower.x, lower.y, upper.z) * (1 - factor.x)
                + vs2(upper.x, lower.y, upper.z) * factor.x)
               * (1 - factor.y)
               + (vs2(lower.x, upper.y, upper.z) * (1 - factor.x)
                  + vs2(upper.x, upper.y, upper.z) * factor.x)
               * factor.y) * factor.z) * 0.00003051944088f;
    
}



kernel void raycast(
                    const device float4x4 *view [[ buffer(0) ]],
                    const device float *nearPlane [[ buffer(1) ]],
                    const device float *farPlane [[ buffer(2) ]],
                    const device float *step [[ buffer(3) ]],
                    const device float *largestep [[ buffer(4) ]],
                    const device uint2 *pos [[ buffer(5) ]],
                    
                   // const device uint3 *sizep [[ buffer(6) ]],
                   // const device float3 *dimp [[ buffer(7) ]],
                   // device short2 * data [[ buffer(8) ]],
                    
                    texture2d<float, access::read> inputTexture [[texture(0)]],
                    texture2d<float, access::write> outputTexture [[texture(1)]],
                      uint2 gid [[thread_position_in_grid]])
{
	
//    uint3 size = *sizep;
    uint3 size;
    //float3 dim = *dimp;
    float3 dim;
    device short2* data = 0;

    
	//    const float3 origin = get_translation(view);
    const float3 origin = float3(view[0][0][3],view[0][1][3],view[0][2][3]);
//    const float3 direction = rotate(view, float3(pos.x, pos.y, 1.f));
    //const float3 direction = rotate(view, float3(pos[0][0], pos[0][1], 1.f));
    
    const float3 v = float3(pos[0][0], pos[0][1], 1.f);
    const float3 direction = float3(dot(float3(view[0][0]), v),
                                    dot(float3(view[0][1]), v),
                                    dot(float3(view[0][2]), v));
    
    
    
	//const float3 direction = rotate(view, make_float3(pos.x, pos.y, 1.f));

	// intersect ray with a box
	// http://www.siggraph.org/education/materials/HyperGraph/raytrace/rtinter3.htm
	// compute intersection of ray with all six bbox planes
	//const float3 invR = make_float3(1.0f) / direction;
    const float3 invR = float3(1.0f) / direction;
	const float3 tbot = -1 * invR * origin;
//	const float3 ttop = invR * (volume.dim - origin);
//    	const float3 ttop = invR * (volume->dim - origin);
    
    const float3 ttop = invR * (dim - origin);

    

//    std::cerr << tbot.x << " " << tbot.y << " " << tbot.z << " "
//              << ttop.x << " " << ttop.y << " " << ttop.z << "\n";

	// re-order intersections to find smallest and largest on each axis
	const float3 tmin = fmin(ttop, tbot);
	const float3 tmax = fmax(ttop, tbot);

	// find the largest tmin and the smallest tmax
	const float largest_tmin = fmax(fmax(tmin.x, tmin.y),
			fmax(tmin.x, tmin.z));
	const float smallest_tmax = fmin(fmin(tmax.x, tmax.y),
			fmin(tmax.x, tmax.z));

	// check against near and far plane
	const float tnear = fmax(largest_tmin, *nearPlane);
	const float tfar = fmin(smallest_tmax, *farPlane);

    // std::cerr << tnear << " " << tfar << "\n";

	if (tnear < tfar) {
		// first walk with largesteps until we found a hit
		float t = tnear;
		float stepsize = *largestep;
//		float f_t = volume.interp(origin + direction * t);
//        float f_t = volume->interp(origin + direction * t);
        
//        float f_t = volume->interp(origin + direction * t);
        float f_t = interp(origin + direction * t, size, dim, data);
//		float f_t = 0;
        
		float f_tt = 0;
		if (f_t > 0) { // ups, if we were already in it, then don't render anything here
			for (; t < tfar; t += stepsize) {
                
				//f_tt = volume.interp(origin + direction * t);
                f_t = interp(origin + direction * t, size, dim, data);
				
                if (f_tt < 0)                  // got it, jump out of inner loop
					break;
				if (f_tt < 0.8f)               // coming closer, reduce stepsize
					stepsize = *step;
				f_t = f_tt;
			}
			if (f_tt < 0) {           // got it, calculate accurate intersection
				t = t + stepsize * f_tt / (f_t - f_tt);
//				return float4(origin + direction * t, t);
                outputTexture.write(float4(origin + direction * t, t), gid);
			}
		}
	}
//	return float4(0);
    //outputTexture.write(float4(0), gid);
    outputTexture.write(float4(1), gid);
}














