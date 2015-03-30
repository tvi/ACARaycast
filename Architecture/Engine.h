#ifndef Engine_h
#define Engine_h

#import <Metal/Metal.h>
#import <UIKit/UIKit.h>

#import <Metal/MTLTypes.h>

#import "vector_types.h"
#import "cutil_math.h"
#import "standalone.h"

@interface MMEngine : NSObject

- (void)   rayCastvolume:(const Volume) volume
                       pos:(const uint2) pos
                      view:(const Matrix4) view
                 nearPlane:(const float) nearPlane
                  farPlane:(const float) farPlane
                      step:(const float) step
                 largestep:(const float) largestep
                    vertex:(float3 *) vertex
                    normal:(float3 *) normal
                     Image:(UIImage *)image
                     memory:(int)memory
                completion:(void (^)(UIImage *filteredImage))completion;

@end

#endif