//
//  raycast.h
//  Test1
//
//  Created by Tomas Virgl on 18/02/2015.
//  Copyright (c) 2015 Tomas Virgl. All rights reserved.
//

#ifndef Test1_raycast_h
#define Test1_raycast_h

//typedef struct afloat3 {
//    float x, y, z;
//} float3;
#include "vector_str.h"

#ifdef __cplusplus
extern "C" {
#endif
    
// const char* run_sim();
const char* run_sim(float3 ** f);
    
#ifdef __cplusplus
}
#endif

#endif
