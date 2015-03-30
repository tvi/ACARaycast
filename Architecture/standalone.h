#include <iostream>
#include <fstream>
#include <sstream>
#include <cassert>
#include "vector_types.h"
#include "cutil_math.h"

#import <Foundation/Foundation.h>

void init(){};
void clean(){};


#define INVALID -2
// DATA TYPE


void hexDump (char *desc, void *addr, int len) {
    int i;
    unsigned char buff[17];
    unsigned char *pc = (unsigned char*)addr;
    
    // Output description if given.
    if (desc != NULL)
        printf ("%s:\n", desc);
    
    // Process every byte in the data.
    for (i = 0; i < len; i++) {
        // Multiple of 16 means new line (with line offset).
        
        if ((i % 16) == 0) {
            // Just don't print ASCII for the zeroth line.
            if (i != 0)
                printf ("  %s\n", buff);
            
            // Output the offset.
            printf ("  %04x ", i);
        }
        
        // Now the hex code for the specific character.
        printf (" %02x", pc[i]);
        
        // And store a printable ASCII character for later.
        if ((pc[i] < 0x20) || (pc[i] > 0x7e))
            buff[i % 16] = '.';
        else
            buff[i % 16] = pc[i];
        buff[(i % 16) + 1] = '\0';
    }
    
    // Pad out last line if not exactly 16 characters.
    while ((i % 16) != 0) {
        printf ("   ");
        i++;
    }
    
    // And print the final ASCII bit.
    printf ("  %s\n", buff);
}


void printBuf(char * c, uint len) {
    while (len){
//        printf("%X \n", c);
//        NSLog("%X \n", c);
        
        

        NSString *log = [NSString stringWithFormat:@"%X \n", *c];
        NSLog(@"%@", log);
        
        
        c++;
        len--;
    }
}

template<typename T>
void read_input(std::string inputfile, T * in) {
	size_t isize;
//    long long isize;

	NSBundle *b = [NSBundle mainBundle];
	NSString *dir = [b resourcePath];
	// NSArray *parts = [NSArray arrayWithObjects:
	//                   dir, @"assets", @"shaders", @"RaycastInPos", @"RaycastInVolume", @"RaycastOutNormal", @"RaycastOutVertex", (void *)nil];
//	NSArray *parts = [NSArray arrayWithObjects:dir, @"RaycastInVolume", (void *)nil];
    // NSArray *parts = [NSArray arrayWithObjects:dir, @"RaycastInVolume", (void *)nil];
    
//    NSString*f = inputfile.;
    NSString*f = [[NSString alloc] initWithUTF8String:inputfile.c_str()];

    NSArray *parts = [NSArray arrayWithObjects:dir, f, (void *)nil];
	NSString *path = [NSString pathWithComponents:parts];
	const char *cpath = [path fileSystemRepresentation];

	std::string vertFile(cpath);
	// std::ifstream file(vertFile); 

	std::ifstream file(vertFile,
			std::ios::in | std::ios::binary | std::ios::ate);


//    char * inn[10000000];
	// std::ifstream file(inputfile.c_str(),
	// 		std::ios::in | std::ios::binary | std::ios::ate);
	if (file.is_open()) {
		isize = file.tellg();
		//file.seekg(0, std::ios::beg);
        //std::cout << isize << " " << cpath << "\n";
        file.seekg(0, file.beg);
		file.read((char*) in, isize);
//        memcpy(inn, in, isize);
		file.close();
	} else {
		std::cout << "File opening failed : " << inputfile << std::endl;
		exit(1);
	}
    
    /*
    return;
    std::ifstream file2(vertFile,
                       std::ios::in | std::ios::binary | std::ios::ate);
    
    if (file2.is_open()) {
        isize = file2.tellg();
        file2.seekg(0, file2.end);
        char * cc = (char *)malloc(isize*sizeof(char));
        file2.read((char*) cc, isize);
        printBuf(cc, isize);

//        std::cerr << "\n" << cc << "\n";
//        hexDump("", cc, isize);

        file2.close();
    } else {
        std::cout << "File opening failed : " << inputfile << std::endl;
        exit(1);
    }*/

    
//    std::cerr << "\n" << *inn << "\n";
}


struct Volume {
	uint3 size;
	float3 dim;
	short2 * data;

	Volume() {
		size = make_uint3(0);
		dim = make_float3(1);
		data = NULL;
	}

	float2 operator[](const uint3 & pos) const {
		const short2 d = data[pos.x + pos.y * size.x + pos.z * size.x * size.y];
		return make_float2(d.x * 0.00003051944088f, d.y); //  / 32766.0f
	}

	float v(const uint3 & pos) const {
		return operator[](pos).x;
	}

	float vs(const uint3 & pos) const {
		return data[pos.x + pos.y * size.x + pos.z * size.x * size.y].x;
	}
	inline float vs2(const uint x, const uint y, const uint z) const {
		return data[x + y * size.x + z * size.x * size.y].x;
	}

	void setints(const unsigned x, const unsigned y, const unsigned z,
			const float2 &d) {
		data[x + y * size.x + z * size.x * size.y] = make_short2(d.x * 32766.0f,
				d.y);
	}

	void set(const uint3 & pos, const float2 & d) {
		data[pos.x + pos.y * size.x + pos.z * size.x * size.y] = make_short2(
				d.x * 32766.0f, d.y);
	}
	float3 pos(const uint3 & p) const {
		return make_float3((p.x + 0.5f) * dim.x / size.x,
				(p.y + 0.5f) * dim.y / size.y, (p.z + 0.5f) * dim.z / size.z);
	}

	float interp(const float3 & pos) const {

		const float3 scaled_pos = make_float3((pos.x * size.x / dim.x) - 0.5f,
				(pos.y * size.y / dim.y) - 0.5f,
				(pos.z * size.z / dim.z) - 0.5f);
		const int3 base = make_int3(floorf(scaled_pos));
		const float3 factor = fracf(scaled_pos);
		const int3 lower = max(base, make_int3(0));
		const int3 upper = min(base + make_int3(1),
				make_int3(size) - make_int3(1));
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

	float3 grad(const float3 & pos) const {
		const float3 scaled_pos = make_float3((pos.x * size.x / dim.x) - 0.5f,
				(pos.y * size.y / dim.y) - 0.5f,
				(pos.z * size.z / dim.z) - 0.5f);
		const int3 base = make_int3(floorf(scaled_pos));
		const float3 factor = fracf(scaled_pos);
		const int3 lower_lower = max(base - make_int3(1), make_int3(0));
		const int3 lower_upper = max(base, make_int3(0));
		const int3 upper_lower = min(base + make_int3(1),
				make_int3(size) - make_int3(1));
		const int3 upper_upper = min(base + make_int3(2),
				make_int3(size) - make_int3(1));
		const int3 & lower = lower_upper;
		const int3 & upper = upper_lower;

		float3 gradient;

		gradient.x = (((vs2(upper_lower.x, lower.y, lower.z)
				- vs2(lower_lower.x, lower.y, lower.z)) * (1 - factor.x)
				+ (vs2(upper_upper.x, lower.y, lower.z)
						- vs2(lower_upper.x, lower.y, lower.z)) * factor.x)
				* (1 - factor.y)
				+ ((vs2(upper_lower.x, upper.y, lower.z)
						- vs2(lower_lower.x, upper.y, lower.z)) * (1 - factor.x)
						+ (vs2(upper_upper.x, upper.y, lower.z)
								- vs2(lower_upper.x, upper.y, lower.z))
								* factor.x) * factor.y) * (1 - factor.z)
				+ (((vs2(upper_lower.x, lower.y, upper.z)
						- vs2(lower_lower.x, lower.y, upper.z)) * (1 - factor.x)
						+ (vs2(upper_upper.x, lower.y, upper.z)
								- vs2(lower_upper.x, lower.y, upper.z))
								* factor.x) * (1 - factor.y)
						+ ((vs2(upper_lower.x, upper.y, upper.z)
								- vs2(lower_lower.x, upper.y, upper.z))
								* (1 - factor.x)
								+ (vs2(upper_upper.x, upper.y, upper.z)
										- vs2(lower_upper.x, upper.y, upper.z))
										* factor.x) * factor.y) * factor.z;

		gradient.y = (((vs2(lower.x, upper_lower.y, lower.z)
				- vs2(lower.x, lower_lower.y, lower.z)) * (1 - factor.x)
				+ (vs2(upper.x, upper_lower.y, lower.z)
						- vs2(upper.x, lower_lower.y, lower.z)) * factor.x)
				* (1 - factor.y)
				+ ((vs2(lower.x, upper_upper.y, lower.z)
						- vs2(lower.x, lower_upper.y, lower.z)) * (1 - factor.x)
						+ (vs2(upper.x, upper_upper.y, lower.z)
								- vs2(upper.x, lower_upper.y, lower.z))
								* factor.x) * factor.y) * (1 - factor.z)
				+ (((vs2(lower.x, upper_lower.y, upper.z)
						- vs2(lower.x, lower_lower.y, upper.z)) * (1 - factor.x)
						+ (vs2(upper.x, upper_lower.y, upper.z)
								- vs2(upper.x, lower_lower.y, upper.z))
								* factor.x) * (1 - factor.y)
						+ ((vs2(lower.x, upper_upper.y, upper.z)
								- vs2(lower.x, lower_upper.y, upper.z))
								* (1 - factor.x)
								+ (vs2(upper.x, upper_upper.y, upper.z)
										- vs2(upper.x, lower_upper.y, upper.z))
										* factor.x) * factor.y) * factor.z;

		gradient.z = (((vs2(lower.x, lower.y, upper_lower.z)
				- vs2(lower.x, lower.y, lower_lower.z)) * (1 - factor.x)
				+ (vs2(upper.x, lower.y, upper_lower.z)
						- vs2(upper.x, lower.y, lower_lower.z)) * factor.x)
				* (1 - factor.y)
				+ ((vs2(lower.x, upper.y, upper_lower.z)
						- vs2(lower.x, upper.y, lower_lower.z)) * (1 - factor.x)
						+ (vs2(upper.x, upper.y, upper_lower.z)
								- vs2(upper.x, upper.y, lower_lower.z))
								* factor.x) * factor.y) * (1 - factor.z)
				+ (((vs2(lower.x, lower.y, upper_upper.z)
						- vs2(lower.x, lower.y, lower_upper.z)) * (1 - factor.x)
						+ (vs2(upper.x, lower.y, upper_upper.z)
								- vs2(upper.x, lower.y, lower_upper.z))
								* factor.x) * (1 - factor.y)
						+ ((vs2(lower.x, upper.y, upper_upper.z)
								- vs2(lower.x, upper.y, lower_upper.z))
								* (1 - factor.x)
								+ (vs2(upper.x, upper.y, upper_upper.z)
										- vs2(upper.x, upper.y, lower_upper.z))
										* factor.x) * factor.y) * factor.z;

		return gradient
				* make_float3(dim.x / size.x, dim.y / size.y, dim.z / size.z)
				* (0.5f * 0.00003051944088f);
	}

	void init(uint3 s, float3 d) {
		size = s;
		dim = d;
		data = (short2 *) malloc(size.x * size.y * size.z * sizeof(short2));
		assert(data != NULL);

	}

	void release() {
		free(data);
		data = NULL;
	}
};

typedef struct sMatrix4 {
	float4 data[4];
} Matrix4;

inline float3 get_translation(const Matrix4 view) {
	return make_float3(view.data[0].w, view.data[1].w, view.data[2].w);
}

inline float3 rotate(const Matrix4 & M, const float3 & v) {
	return make_float3(dot(make_float3(M.data[0]), v),
			dot(make_float3(M.data[1]), v), dot(make_float3(M.data[2]), v));
}
