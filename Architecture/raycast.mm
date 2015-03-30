
#include "standalone.h"
#include <iostream>
#include <iomanip>
#include <stdint.h> /* for uint64 definition */
#include <sstream> 

#include "raycast.h"

#include "Engine.h"

#define BILLION 1000000000L


#ifdef __MACH__
#include <sys/time.h>
#define CLOCK_MONOTONIC 0
//clock_gettime is not implemented on OSX
int clock_gettime(int /*clk_id*/, struct timespec* t) {
    struct timeval now;
    int rv = gettimeofday(&now, NULL);
    if (rv) return rv;
    t->tv_sec  = now.tv_sec;
    t->tv_nsec = now.tv_usec * 1000;
    return 0;
}
#endif


inline bool nequal(float a , float b) {return abs(a-b) >   0.0001;}

float4 raycast(const Volume volume, const uint2 pos, const Matrix4 view,
		const float nearPlane, const float farPlane, const float step,
		const float largestep) {

	const float3 origin = get_translation(view);
	const float3 direction = rotate(view, make_float3(pos.x, pos.y, 1.f));

	// intersect ray with a box
	// http://www.siggraph.org/education/materials/HyperGraph/raytrace/rtinter3.htm
	// compute intersection of ray with all six bbox planes
	const float3 invR = make_float3(1.0f) / direction;
	const float3 tbot = -1 * invR * origin;
	const float3 ttop = invR * (volume.dim - origin);

//    std::cerr << tbot.x << " " << tbot.y << " " << tbot.z << " "
//              << ttop.x << " " << ttop.y << " " << ttop.z << "\n";

	// re-order intersections to find smallest and largest on each axis
	const float3 tmin = fminf(ttop, tbot);
	const float3 tmax = fmaxf(ttop, tbot);

	// find the largest tmin and the smallest tmax
	const float largest_tmin = fmaxf(fmaxf(tmin.x, tmin.y),
			fmaxf(tmin.x, tmin.z));
	const float smallest_tmax = fminf(fminf(tmax.x, tmax.y),
			fminf(tmax.x, tmax.z));

	// check against near and far plane
	const float tnear = fmaxf(largest_tmin, nearPlane);
	const float tfar = fminf(smallest_tmax, farPlane);

    // std::cerr << tnear << " " << tfar << "\n";

	if (tnear < tfar) {
		// first walk with largesteps until we found a hit
		float t = tnear;
		float stepsize = largestep;
		float f_t = volume.interp(origin + direction * t);
		float f_tt = 0;
		if (f_t > 0) { // ups, if we were already in it, then don't render anything here
			for (; t < tfar; t += stepsize) {
				f_tt = volume.interp(origin + direction * t);
				if (f_tt < 0)                  // got it, jump out of inner loop
					break;
				if (f_tt < 0.8f)               // coming closer, reduce stepsize
					stepsize = step;
				f_t = f_tt;
			}
			if (f_tt < 0) {           // got it, calculate accurate intersection
				t = t + stepsize * f_tt / (f_t - f_tt);
				return make_float4(origin + direction * t, t);
			}
		}
	}
	return make_float4(0);

}

/*
device const Volume* volumep [[buffer(0)]],
device const Matrix4* viewp [[buffer(1)]],
device const float* nearPlanep [[buffer(2)]],
device const float* farPlanep [[buffer(3)]],
device const float* stepp [[buffer(4)]],
device const float* largestepp [[buffer(5)]]
*/

void raycastKernelGPU(float3* vertex, float3* normal, uint2 inputSize,
        const Volume integration, const Matrix4 view, const float nearPlane,
        const float farPlane, const float step, const float largestep, int memory) {

    uint2 poss = make_uint2(inputSize.x, inputSize.y);
    MMEngine *m = [[MMEngine alloc] init];
    [m rayCastvolume:integration 
                pos:poss 
                view:view
                nearPlane:nearPlane 
                farPlane:farPlane 
                step:step
                largestep:largestep
                vertex:vertex
                normal:normal
                Image:nil
                memory:memory
                completion:nil];

}
int a = 0;
int b = 0;
/*
 * raycastKernel function
 *
 * Output arguments
 * vertex: a 2D matrix containing 3D points (called vertices)
 * normal: a 2D matrix containing normal vectors of a 3D point
 *
 * Inputs arguments 
 * inputSize: the size of the vertex and normal matrices
 * integration: a 3D cube containing a Truncated Signed Distance Function (TSDF)
 * view: the 4x4 matrix that represents the view point
 * nearPlane: distance from the plane that delimitate the near scene
 * farPlane: distance from the plane that delimitate the far scene
 * step: the small step used in the raycast walk when we are close to the surface
 * largestep: the large step used in the raycast walk when we are far from the surface
 */
void raycastKernel(float3* vertex, float3* normal, uint2 inputSize,
		const Volume integration, const Matrix4 view, const float nearPlane,
		const float farPlane, const float step, const float largestep) {

    // uint2 poss = make_uint2(inputSize.x, inputSize.y);
    // MMEngine *m = [[MMEngine alloc] init];
    // const float4 hitq =[m rayCastvolume:integration 
    //                         pos:poss 
    //                         view:view
    //                         nearPlane:nearPlane 
    //                         farPlane:farPlane 
    //                         step:step
    //                         largestep:largestep
    //                         Image:nil
    //                         completion:nil];


	unsigned int y;

	// Add this line and add the openmp compilation flag to the Makefile if you want to run the OpenMP version

#ifdef ASD
	#pragma omp parallel for shared(normal, vertex), private(y)
#endif
	for (y = 0; y < inputSize.y; y++)
		for (unsigned int x = 0; x < inputSize.x; x++) {
            
//            if (x == 0 && y == 0) {
            
//                const float4 hits = raycast(integration, poss, view, nearPlane,
//                                           farPlane, step, largestep);
                
                // MMEngine *m = [[MMEngine alloc] init];
                // const float4 hitq =[m rayCastvolume:integration pos:poss view:view
                //        nearPlane:nearPlane farPlane:farPlane step:step largestep:largestep
                //            Image:nil completion:nil];

//                std::cout << " hits: "<< hits.x
//                         << "\n hitq: " << hitq.x
//                         << "\n";
                // std::cout << "hits: "<< hits << " hitq: " << hitq << "\n";
//            }

			uint2 pos = make_uint2(x, y);

			const float4 hit = raycast(integration, pos, view, nearPlane,
					farPlane, step, largestep);
            // std::cerr << hit.w;
			if (hit.w > 0.0) {
                a++;
				vertex[pos.x + pos.y * inputSize.x] = make_float3(hit);
				float3 surfNorm = integration.grad(make_float3(hit));
				if (length(surfNorm) == 0) {
					normal[pos.x + pos.y * inputSize.x].x = INVALID;
				} else {
					normal[pos.x + pos.y * inputSize.x] = normalize(surfNorm);
				}
			} else {
                b++;
				// std::cerr<< "RAYCAST MISS "<<  pos.x << " " << pos.y <<"  " << hit.w <<"\n";
				vertex[pos.x + pos.y * inputSize.x] = make_float3(0);
				normal[pos.x + pos.y * inputSize.x] = make_float3(INVALID, INVALID,INVALID);
			}
		}
}

//int main2(int argc, char ** argv) {
const char* main2(int argc, char ** argv, float3 ** f) {

    for (int i = 0; i < 14; ++i) {
        std::cerr << argv[i] << " ";
    }
    // std::cerr << argv;

    uint64_t timeDiff; 
    struct timespec start, end;

    Volume inputVolume;
    Matrix4 inputPos;
    float nearPlane ;
    float farPlane ;
    float step ;
    float mu ;
    uint2 computationSize;
    uint3 vSize;
    float3 vDim;
    uint tvSize;
    float tvDim;
    int nRepeats; // number of times to repeat the computation (for ACA exercise)

    std::string inputVolumeFile;
    std::string inputPosFile;
    std::string goldVertexFile;
    std::string goldNormalFile;

    std::stringstream ss;

    ss << "********** RETRIEVE INPUTS AND GOLD VERSION **************" << std::endl;

    if (argc < 11) {
        ss << "Please set args ./" << argv[0] << " inputVolumeFile  inputPosFile goldVertexFile goldNormalFile imageSize.x imageSize.y nearPlane farPlane step mu tvSize tvDim nRepeats" << std::endl;
        exit(1);
    }

    inputVolumeFile = argv[1];
    inputPosFile    = argv[2];
    goldVertexFile  = argv[3];
    goldNormalFile  = argv[4];

    std::istringstream(argv[5]) >> computationSize.x;
    std::istringstream(argv[6]) >> computationSize.y;
    std::istringstream(argv[7]) >> nearPlane;
    std::istringstream(argv[8]) >> farPlane;
    std::istringstream(argv[9]) >> step;
    std::istringstream(argv[10]) >> mu;
    std::istringstream(argv[11]) >> tvSize;
    std::istringstream(argv[12]) >> tvDim;
    std::istringstream(argv[13]) >> nRepeats;
    vSize = make_uint3(tvSize);
    vDim = make_float3(tvDim);


    inputVolume.init(vSize,vDim);

    read_input<short2>(inputVolumeFile, inputVolume.data);
    read_input<Matrix4>(inputPosFile, &inputPos);

    std::cout << "\n";

    
    std::cout << "pica\n";
    NSString *log = [NSString stringWithFormat:@"%X \n", *(unsigned int*)&inputVolume.data[0].x];
    NSLog(@"%@", log);

//    std::cout << inputVolume.data << "\n";
//    std::cout << inputPos.data[0].x << inputPos.data[0].y << inputPos.data[0].z << inputPos.data[0].w << "\n";
//    std::cout << inputPos.data[1].x << inputPos.data[1].y << inputPos.data[1].z << inputPos.data[1].w << "\n";
//    std::cout << inputPos.data[2].x << inputPos.data[2].y << inputPos.data[2].z << inputPos.data[2].w << "\n";
//    std::cout << inputPos.data[3].x << inputPos.data[3].y << inputPos.data[3].z << inputPos.data[3].w << "\n";

    float3 * vertex = (float3*) malloc(sizeof(float3) * computationSize.x * computationSize.y);
    float3 * normal = (float3*) malloc(sizeof(float3) * computationSize.x * computationSize.y);

    ss << "********** INIT AND DO THE JOB **************" << std::endl;

    ss << "computationSize.x = " << computationSize.x  << " pixels" << std::endl;
    ss << "computationSize.y = " << computationSize.y  << " pixels" <<  std::endl;
    ss << "nearPlane = " <<nearPlane <<  " meters" << std::endl;
    ss << "farPlane = " << farPlane <<  " meters" << std::endl;
    ss << "step = " << step <<  " meters" << std::endl;
    //ss << "mu * 0.75f = " << mu << std::endl;

    ss << "nRepeats = " << nRepeats << std::endl;

    ss << "********** EXECUTION TIME **************" << std::endl;
    // outputs: vertex and normal



    // DEBUG
    std::cerr << "********** INIT AND DO THE JOB **************" << std::endl;
    std::cerr << "computationSize.x = " << computationSize.x  << " pixels" << std::endl;
    std::cerr << "computationSize.y = " << computationSize.y  << " pixels" <<  std::endl;
    std::cerr << "nearPlane = " <<nearPlane <<  " meters" << std::endl;
    std::cerr << "farPlane = " << farPlane <<  " meters" << std::endl;
    std::cerr << "step = " << step <<  " meters" << std::endl;
    //std::cerr << "mu * 0.75f = " << mu << std::endl;
    std::cerr << "nRepeats = " << nRepeats << std::endl;
    std::cerr << "********** EXECUTION TIME **************" << std::endl;
    // outputs: vertex and normal

    //const int memory = 1;
    const int memory = 1;

    // Start clock
    clock_gettime(CLOCK_MONOTONIC, &start); 
    for (int i=0; i<nRepeats; ++i) {
      raycastKernelGPU(vertex, normal, computationSize, inputVolume, inputPos, nearPlane, farPlane, step, mu, memory);
      // raycastKernel(vertex, normal, computationSize, inputVolume, inputPos, nearPlane, farPlane, step, mu);
    }
    
    // Stop clock
    clock_gettime(CLOCK_MONOTONIC, &end); 

    timeDiff = BILLION * (end.tv_sec - start.tv_sec) + end.tv_nsec - start.tv_nsec;
    ss << "Elapsed time = " << timeDiff << " nanoseconds" << std::endl;
    ss << "Elapsed time = " << (double) timeDiff / BILLION << " seconds" << std::endl;
    ss << "Elapsed time = " << timeDiff/nRepeats << " nanoseconds per repeat" << std::endl;

    ss << "********** COMPARE WITH GOLD **************" << std::endl;


    std::cerr << "Elapsed time = " << timeDiff << " nanoseconds" << std::endl;
    std::cerr << "Elapsed time = " << (double) timeDiff / BILLION << " seconds" << std::endl;
    std::cerr << "Elapsed time = " << timeDiff/nRepeats << " nanoseconds per repeat" << std::endl;
    std::cerr << "Elapsed time = " << (double) timeDiff / nRepeats / BILLION << " seconds per repeat" << std::endl;

    std::cerr << "********** COMPARE WITH GOLD **************" << std::endl;

    float3 *  goldVertex = (float3*) malloc(sizeof(float3) * computationSize.x * computationSize.y);
    float3 *  goldNormal = (float3*) malloc(sizeof(float3) * computationSize.x * computationSize.y);

    read_input(goldVertexFile, goldVertex);
    read_input(goldNormalFile, goldNormal);

    if (memory == 0) {
        normal = goldNormal;
        vertex = goldVertex;
    }

    // std::cerr << goldVertex[];
    // std::cerr << goldNormal;

    // *f = goldNormal;
    *f = normal;
    // *f = vertex;

    size_t diff = 0;
    size_t total = computationSize.x * computationSize.y  ;

    for (unsigned int i = 0; i < total; i++) {
//        std::cerr << i << std::endl;
      if (nequal(goldVertex[i].x , vertex[i].x) || nequal(goldVertex[i].y , vertex[i].y) || nequal(goldVertex[i].z , vertex[i].z)  ) {
//	  if (diff == 0) {
          	  if (diff <= 10) {
                ss << "Failed vertex pixel X " << i << ": expected " << goldVertex[i].x << " and observed " << vertex[i].x << std::endl;
                ss << "Failed vertex pixel Y " << i << ": expected " << goldVertex[i].y << " and observed " << vertex[i].y << std::endl;
                ss << "Failed vertex pixel Z " << i << ": expected " << goldVertex[i].z << " and observed " << vertex[i].z << std::endl;

                std::cerr << "Failed vertex pixel X " << i << ": expected " << goldVertex[i].x << " and observed " << vertex[i].x << std::endl;
                std::cerr << "Failed vertex pixel Y " << i << ": expected " << goldVertex[i].y << " and observed " << vertex[i].y << std::endl;
                std::cerr << "Failed vertex pixel Z " << i << ": expected " << goldVertex[i].z << " and observed " << vertex[i].z << std::endl;
	  }
          diff++;
        }
      if (nequal(goldNormal[i].x , normal[i].x) || nequal(goldNormal[i].y , normal[i].y) || nequal(goldNormal[i].z , normal[i].z)  ) {
//	  if (diff == 0) {
                    	  if (diff <= 10) {
                ss << "Failed normal pixel X " << i << ": expected " << goldNormal[i].x << " and observed " << normal[i].x << std::endl;
                ss << "Failed normal pixel Y " << i << ": expected " << goldNormal[i].y << " and observed " << normal[i].y << std::endl;
                ss << "Failed normal pixel Z " << i << ": expected " << goldNormal[i].z << " and observed " << normal[i].z << std::endl;

                std::cerr << "Failed normal pixel X " << i << ": expected " << goldNormal[i].x << " and observed " << normal[i].x << std::endl;
                std::cerr << "Failed normal pixel Y " << i << ": expected " << goldNormal[i].y << " and observed " << normal[i].y << std::endl;
                std::cerr << "Failed normal pixel Z " << i << ": expected " << goldNormal[i].z << " and observed " << normal[i].z << std::endl;
	  }
          diff++;
        }
    }
    if (diff > 0) {
        ss << "End of check " << total - diff << "/" << total << " fail" << std::endl;
        std::cerr << "End of check " << total - diff << "/" << total << " fail" << std::endl;
    } else {
        ss << "End of check " << total - diff << "/" << total << " success" << std::endl;
        std::cerr << "End of check " << total - diff << "/" << total << " success" << std::endl;
    }
    
    ss << std::endl;

    inputVolume.release();

    std::cerr << a << " " << b << std::endl;

    std::string *s = new std::string(ss.str());
//    s = ss.str();
    //return (diff != 0);
//    return ss.str().c_str();
    return s->c_str();
}

const char* run_sim(float3 ** f) {
    char* strings[14];
    strings[0] = "./raycast";
    strings[1] = "RaycastInVolume";
    strings[2] = "RaycastInPos";
    strings[3] = "RaycastOutVertex";
    strings[4] = "RaycastOutNormal";
    strings[5] = "640";
    strings[6] = "480";
    strings[7] = "0.400000006";
    strings[8] = "4";
    strings[9] = "0.0078125";
    strings[10] = "0.07500000298 ";
    strings[11] = "256";
    strings[12] = "2";
    // strings[13] = "2";
    // strings[13] = "1";
    strings[13] = "10";
    return main2(14, strings, f);
}