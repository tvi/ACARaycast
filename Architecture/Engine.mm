#include "Engine.h"


void ImageProviderReleaseData(void *info, const void *data, size_t size);

@interface MMEngine ()

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLComputePipelineState> pipeline;

@end

@implementation MMEngine

- (void)setup
{
    self.device = MTLCreateSystemDefaultDevice();
    
    id<MTLLibrary> library = [self.device newDefaultLibrary];
   // id<MTLFunction> grayscaleFunction = [library newFunctionWithName:@"grayscale"];
    id<MTLFunction> grayscaleFunction = [library newFunctionWithName:@"raycastKernel"];
    
    self.commandQueue = [self.device newCommandQueue];
    
    [self.commandQueue insertDebugCaptureBoundary];
    
    NSError *error = nil;
    self.pipeline = [self.device newComputePipelineStateWithFunction:grayscaleFunction error:&error];
    
    if (self.pipeline == nil) {
        NSLog(@"Failed to create pipeline: %@", error);
    }
}

typedef struct sVolume {
    uint3 size;
    float3 dim;
    short2 * data;
} TVolume;

typedef union cstFloat {
    float f;
    struct {
        uint16_t a;
        uint16_t b;
    };
} MFloat;

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
                completion:(void (^)(UIImage *filteredImage))completion
{
    NSLog(@"Before setup");
    [self setup];
    NSLog(@"After setup");

    image = [UIImage imageNamed:@"Lenna"];
    
    CGImageRef CGImage = image.CGImage;
    NSUInteger width = CGImageGetWidth(CGImage);
    NSUInteger height = CGImageGetHeight(CGImage);
    width = pos.x;
    height = pos.y;
    
    //NSLog(@"%@", width);
    //NSLog(@"%@", height);
    
    NSUInteger bitsPerComponent = 8;
//    NSUInteger bitsPerComponent = 16;
//    NSUInteger bitsPerComponent = 32;
    NSUInteger bytesPerRow = width * 4;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedFirst|kCGBitmapByteOrder32Little);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), CGImage);
    GLubyte *textureData = (GLubyte *)CGBitmapContextGetData(context);
    NSLog(@"Metadata");

//    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA32Float width:width height:height mipmapped:NO];
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA16Uint width:width height:height mipmapped:NO];
    id<MTLTexture> inputTexture = [self.device newTextureWithDescriptor:textureDescriptor];
    // id<MTLTexture> outputTexture = [self.device newTextureWithDescriptor:textureDescriptor];
    // id<MTLTexture> outputTexture2 = [self.device newTextureWithDescriptor:textureDescriptor];
    // id<MTLTexture> outputTexture3 = [self.device newTextureWithDescriptor:textureDescriptor];
    // id<MTLTexture> outputTexture4 = [self.device newTextureWithDescriptor:textureDescriptor];
    
    MTLRegion region = MTLRegionMake2D(0, 0, width, height);
//    [inputTexture replaceRegion:region mipmapLevel:0 withBytes:textureData bytesPerRow:bytesPerRow];
//    MTLTextureDescriptor *textureDescriptor2 = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA32Float width:width height:height mipmapped:NO];
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    NSLog(@"Textures Finished");
    
    id <MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    id <MTLComputeCommandEncoder> commandEncoder = [commandBuffer computeCommandEncoder];
    [commandEncoder setComputePipelineState:self.pipeline];
    [commandEncoder setTexture:inputTexture atIndex:0];
    // [commandEncoder setTexture:outputTexture atIndex:1];
    // [commandEncoder setTexture:outputTexture2 atIndex:2];
    // [commandEncoder setTexture:outputTexture3 atIndex:3];
    // [commandEncoder setTexture:outputTexture4 atIndex:4];
        
    id<MTLBuffer> viewBuffer = [self.device newBufferWithBytes:&view  length:sizeof(view) options:0];
    id<MTLBuffer> nearPlaneBuffer = [self.device newBufferWithBytes:&nearPlane  length:sizeof(nearPlane) options:0];
    id<MTLBuffer> farPlaneBuffer = [self.device newBufferWithBytes:&farPlane  length:sizeof(farPlane) options:0];
    id<MTLBuffer> stepBuffer = [self.device newBufferWithBytes:&step  length:sizeof(step) options:0];
    id<MTLBuffer> largestepBuffer = [self.device newBufferWithBytes:&largestep  length:sizeof(largestep) options:0];

    [commandEncoder setBuffer:viewBuffer offset:0 atIndex:0];
    [commandEncoder setBuffer:nearPlaneBuffer offset:0 atIndex:1];
    [commandEncoder setBuffer:farPlaneBuffer offset:0 atIndex:2];
    [commandEncoder setBuffer:stepBuffer offset:0 atIndex:3];
    [commandEncoder setBuffer:largestepBuffer offset:0 atIndex:4];
    
    uint volsizex = volume.size.x;
    uint volsizey = volume.size.x;
    uint volsizez = volume.size.z;
    float voldimx = volume.dim.x;
    float voldimy = volume.dim.y;
    float voldimz = volume.dim.z;
    

     short2* voldata = volume.data;

//    short2* voldata2 = volume.data;
//
//    void *fqdata = malloc(256*256*256*4);
//    float* voldata = (float *) fqdata;
//    
//    for (int i= 0; i < 256*256*256; ++i){
//        voldata[i] = float(voldata2[i].x);
//    }
//    


    id<MTLBuffer> volsizexBuf = [self.device newBufferWithBytes:&volsizex  length:sizeof(volsizex) options:0]; [commandEncoder setBuffer:volsizexBuf offset:0 atIndex:5];
    id<MTLBuffer> volsizeyBuf = [self.device newBufferWithBytes:&volsizey  length:sizeof(volsizey) options:0]; [commandEncoder setBuffer:volsizeyBuf offset:0 atIndex:6];
    id<MTLBuffer> volsizezBuf = [self.device newBufferWithBytes:&volsizez  length:sizeof(volsizez) options:0]; [commandEncoder setBuffer:volsizezBuf offset:0 atIndex:7];
    id<MTLBuffer> voldimxBuf = [self.device newBufferWithBytes:&voldimx  length:sizeof(voldimx) options:0]; [commandEncoder setBuffer:voldimxBuf offset:0 atIndex:8];
    id<MTLBuffer> voldimyBuf = [self.device newBufferWithBytes:&voldimy  length:sizeof(voldimy) options:0]; [commandEncoder setBuffer:voldimyBuf offset:0 atIndex:9];
    id<MTLBuffer> voldimzBuf = [self.device newBufferWithBytes:&voldimz  length:sizeof(voldimz) options:0]; [commandEncoder setBuffer:voldimzBuf offset:0 atIndex:10];
    //id<MTLBuffer> voldataBuf = [self.device newBufferWithBytes:voldata  length:63073980 options:0]; [commandEncoder setBuffer:voldataBuf offset:0 atIndex:11]; // <-------------------------- MASSSIVE TODO
    id<MTLBuffer> voldataBuf = [self.device newBufferWithBytes:voldata  length:256*256*256*4 options:0]; [commandEncoder setBuffer:voldataBuf offset:0 atIndex:11]; // <-------------------------- MASSSIVE TODO

    NSLog(@"Input buffers finished");
    // size_t fsize = width * height * 4*2;
    size_t fsize = width * height * 4*4;
    void *fbytes = malloc(fsize);
    void *fbytes2 = malloc(fsize);
    id<MTLBuffer> outBuf = [self.device newBufferWithBytes:fbytes  length:fsize options:0]; [commandEncoder setBuffer:outBuf offset:0 atIndex:12];
    id<MTLBuffer> outBuf2 = [self.device newBufferWithBytes:fbytes2  length:fsize options:0]; [commandEncoder setBuffer:outBuf2 offset:0 atIndex:13];
    
    void * cc = [outBuf contents];
    float4 * fff = (float4 *) cc;
    void * cc2 = [outBuf2 contents];
    float4 * fff2 = (float4 *) cc2;
    
    NSLog(@"Output buffers finished");

//    MTLSize threadsPerGroup = MTLSizeMake(2, 256, 1);
//    MTLSize threadsPerGroup = MTLSizeMake(4, 128, 1);
//    MTLSize threadsPerGroup = MTLSizeMake(128, 4, 1);
//    MTLSize threadsPerGroup = MTLSizeMake(16, 16, 1);
    
//    NSLog(@"heigh %d", height);
    
//    MTLSize threadsPerGroup = MTLSizeMake(4, 128, 1);

    MTLSize threadsPerGroup = MTLSizeMake(1, 480, 1);
//    MTLSize threadsPerGroup = MTLSizeMake(800, 1, 1);
//    MTLSize threadsPerGroup = MTLSizeMake(320, 1, 1);
    
    MTLSize numThreadgroups = MTLSizeMake(width/threadsPerGroup.width, height/threadsPerGroup.height, 1);
    [commandEncoder dispatchThreadgroups:numThreadgroups threadsPerThreadgroup:threadsPerGroup];
    [commandEncoder endEncoding];


    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    // [self methodWithABlock:^(id result){
    //     //put code here
    //     dispatch_semaphore_signal(sem);
    // }];

    
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> cb) {
        NSLog(@"First Finish");
        if (memory == 0) {
            return;
        }
        size_t size = width * height * 4*2;
        // void *bytes = malloc(size);
        // [outputTexture getBytes:bytes bytesPerRow:bytesPerRow*2 fromRegion:region mipmapLevel:0];

        // void *bytes4 = malloc(size);
        // [outputTexture4 getBytes:bytes4 bytesPerRow:bytesPerRow*2 fromRegion:region mipmapLevel:0];
        
        // void *bytes3 = malloc(size);
        // [outputTexture3 getBytes:bytes3 bytesPerRow:bytesPerRow*2 fromRegion:region mipmapLevel:0];
        
        // void *bytes2 = malloc(size);
        // [outputTexture2 getBytes:bytes2 bytesPerRow:bytesPerRow*2 fromRegion:region mipmapLevel:0];

        // NSLog(@"Done");
        uint2 inputSize = pos;
        // size_t bpr = bytesPerRow;
        // size_t bytes_per_pixel = 1;
        
        // const uint16_t* ibytes = (const uint16_t*)bytes;
        // const uint16_t* ibytes2 = (const uint16_t*)bytes2;
        // const uint16_t* ibytes3 = (const uint16_t*)bytes3;
        // const uint16_t* ibytes4 = (const uint16_t*)bytes4;

        // //13 vertex
        // //24 normal
        
        // MFloat px;
        // MFloat py;
        // MFloat pz;

        // MFloat p2x;
        // MFloat p2y;
        // MFloat p2z;
        const int ssize = 1;
        for (unsigned int y = 0; y < inputSize.y; y++){
            for (unsigned int x = 0; x < inputSize.x; x++) {
                uint2 pos = make_uint2(x, y);
// //                const uint16_t* pixl1 =  &ibytes[y * bpr + x * bytes_per_pixel];
// //                const uint16_t* pixl3 = &ibytes3[y * bpr + x * bytes_per_pixel];
//                 const uint16_t* pixl1 =  &ibytes[pos.x + pos.y * inputSize.x];
//                 const uint16_t* pixl3 = &ibytes3[pos.x + pos.y * inputSize.x];
                
//                 px.a = pixl1[0*ssize];
//                 px.b = pixl3[0*ssize];
//                 py.a = pixl1[1*ssize];
//                 py.b = pixl3[1*ssize];
//                 pz.a = pixl1[2*ssize];
//                 pz.b = pixl3[2*ssize];
                
//                 const uint16_t* pixl2 = &ibytes2[pos.x + pos.y * inputSize.x];
//                 const uint16_t* pixl4 = &ibytes4[pos.x + pos.y * inputSize.x];
//                 p2x.a = pixl2[0*ssize];
//                 p2x.b = pixl4[0*ssize];
//                 p2y.a = pixl2[1*ssize];
//                 p2y.b = pixl4[1*ssize];
//                 p2z.a = pixl2[2*ssize];
//                 p2z.b = pixl4[2*ssize];

//                vertex[pos.x + pos.y * inputSize.x] = make_float3(px.f,py.f,pz.f);
                // normal[pos.x + pos.y * inputSize.x] = make_float3(p2x.f,p2y.f,p2z.f);

//                normal[pos.x + pos.y * inputSize.x] = make_float3(p2x.f,p2y.f,p2z.f);
                vertex[pos.x + pos.y * inputSize.x] =  make_float3(fff2[pos.x + pos.y * inputSize.x]);
                normal[pos.x + pos.y * inputSize.x] =  make_float3(fff[pos.x + pos.y * inputSize.x]);
            }
        }

       // free(bytes);
       // free(bytes2);
       // free(bytes3);
       // free(bytes4);
        dispatch_semaphore_signal(sem);
        free(fbytes2);
        free(fbytes);
        NSLog(@"Done2");
        /*
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(filteredImage);
        });*/
    }];

    NSLog(@"Last Start");
    [commandBuffer commit];
    
    if (memory == 0) {
        return;
    }

    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

   // int qq = 0;
   // while (qq < 200000000) {
   //     qq = qq +1;
   // }
//   qq = 0;
//   while (qq < 200000000) {
//       qq = qq +1;
//   }
//   qq = 0;
//   while (qq < 200000000) {
//       qq = qq +1;
//   }
//   qq = 0;
//   while (qq < 200000000) {
//       qq = qq +1;
//   }
//   qq = 0;
//   while (qq < 200000000) {
//       qq = qq +1;
//   }

    NSLog(@"Exit");
}

- (void)filterImage:(UIImage *)image completion:(void (^)(UIImage *filteredImage))completion
{
    CGImageRef CGImage = image.CGImage;
    NSUInteger width = CGImageGetWidth(CGImage);
    NSUInteger height = CGImageGetHeight(CGImage);
    NSUInteger bitsPerComponent = 8;
    NSUInteger bytesPerRow = width * 4;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedFirst|kCGBitmapByteOrder32Little);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), CGImage);
    GLubyte *textureData = (GLubyte *)CGBitmapContextGetData(context);
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:width height:height mipmapped:NO];
    id<MTLTexture> inputTexture = [self.device newTextureWithDescriptor:textureDescriptor];
    id<MTLTexture> outputTexture = [self.device newTextureWithDescriptor:textureDescriptor];
    
    MTLRegion region = MTLRegionMake2D(0, 0, width, height);
    [inputTexture replaceRegion:region mipmapLevel:0 withBytes:textureData bytesPerRow:bytesPerRow];
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    id <MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    id <MTLComputeCommandEncoder> commandEncoder = [commandBuffer computeCommandEncoder];
    [commandEncoder setComputePipelineState:self.pipeline];
    [commandEncoder setTexture:inputTexture atIndex:0];
    [commandEncoder setTexture:outputTexture atIndex:1];
    
    
    MTLSize threadsPerGroup = MTLSizeMake(16, 16, 1);
    MTLSize numThreadgroups = MTLSizeMake(width/threadsPerGroup.width, height/threadsPerGroup.height, 1);
    [commandEncoder dispatchThreadgroups:numThreadgroups threadsPerThreadgroup:threadsPerGroup];
    [commandEncoder endEncoding];
    
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> cb) {
        size_t size = width * height * 4;
        void *bytes = malloc(size);
        [outputTexture getBytes:bytes bytesPerRow:bytesPerRow fromRegion:region mipmapLevel:0];
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
        CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, bytes, size, ImageProviderReleaseData);
        CGImageRef cgImage = CGImageCreate(width, height, bitsPerComponent, bitsPerComponent * 4, bytesPerRow, colorSpace, bitmapInfo, provider, NULL, FALSE, kCGRenderingIntentDefault);
        CGDataProviderRelease(provider);
        
        UIImage *filteredImage = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
        CGColorSpaceRelease(colorSpace);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(filteredImage);
        });
    }];
    [commandBuffer commit];
}

@end

void ImageProviderReleaseData(void *info, const void *data, size_t size)
{
    free((void *)data);
}


/*
        NSInteger www =[outputTexture height];
//        outputTexture 
        NSLog(@"%ld", (long)www);
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
        CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, bytes, size, ImageProviderReleaseData);
        CGImageRef cgImage = CGImageCreate(width, height, bitsPerComponent, bitsPerComponent * 4, bytesPerRow, colorSpace, bitmapInfo, provider, NULL, FALSE, kCGRenderingIntentDefault);
        CGDataProviderRelease(provider);
        
        UIImage *filteredImage = [UIImage imageWithCGImage:cgImage];
        //CGImageRelease(cgImage);
        //CGColorSpaceRelease(colorSpace);
        
        
        NSLog(@"Done");
        uint2 inputSize = pos;

        CGImageRef cgimage = cgImage;

        size_t bpr = CGImageGetBytesPerRow(cgimage);
        size_t bpp = CGImageGetBitsPerPixel(cgimage);
        size_t bpc = CGImageGetBitsPerComponent(cgimage);
        size_t bytes_per_pixel = bpp / bpc;

        CGBitmapInfo info = CGImageGetBitmapInfo(cgimage);

        CGDataProviderRef pprovider = CGImageGetDataProvider(cgimage);
        NSData* data = (id)CFBridgingRelease(CGDataProviderCopyData(pprovider));
        const uint8_t* bytess = (const uint8_t*)[data bytes];

///////////////////////////////OUT2
        
        
        CGColorSpaceRef colorSpace2 = CGColorSpaceCreateDeviceRGB();
        CGBitmapInfo bitmapInfo2 = kCGBitmapByteOrderDefault;
        CGDataProviderRef provider2 = CGDataProviderCreateWithData(NULL, bytes2, size, ImageProviderReleaseData);
        CGImageRef cgImage2 = CGImageCreate(width, height, bitsPerComponent, bitsPerComponent * 4, bytesPerRow, colorSpace2, bitmapInfo2, provider2, NULL, FALSE, kCGRenderingIntentDefault);
        CGDataProviderRelease(provider2);
        
        UIImage *filteredImage2 = [UIImage imageWithCGImage:cgImage2];
        // CGImageRelease(cgImage);
        // CGColorSpaceRelease(colorSpace);
        
        
        NSLog(@"Done");
        // uint2 inputSize = pos;

        CGImageRef cgimage2 = cgImage2;

        size_t bpr2 = CGImageGetBytesPerRow(cgimage2);
        size_t bpp2 = CGImageGetBitsPerPixel(cgimage2);
        size_t bpc2 = CGImageGetBitsPerComponent(cgimage2);
        size_t bytes_per_pixel2 = bpp2 / bpc2;

        CGBitmapInfo info2 = CGImageGetBitmapInfo(cgimage2);

        CGDataProviderRef pprovider2 = CGImageGetDataProvider(cgimage2);
        NSData* data2 = (id)CFBridgingRelease(CGDataProviderCopyData(pprovider2));
        const uint8_t* bytess2 = (const uint8_t*)[data2 bytes];
*/



/*
 float4 raycast(const Volume volume, const uint2 pos, const Matrix4 view,
 const float nearPlane, const float farPlane, const float step,
 const float largestep)

- (void) test
{
    //    MTLDataTypeFloat4x4 m = [MTLDataTypeFloat4x4 alloc];

}


float4 raycastasdfsdf(const Volume volume,
               const uint2 pos,
               const Matrix4 view,
               const float nearPlane,
               const float farPlane,
               const float step,
               const float largestep){
    
    // this.setup();
    
    
    self.device = MTLCreateSystemDefaultDevice();
    
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    id<MTLFunction> grayscaleFunction = [library newFunctionWithName:@"grayscale"];
    
    self.commandQueue = [self.device newCommandQueue];
    
    NSError *error = nil;
    self.pipeline = [self.device newComputePipelineStateWithFunction:grayscaleFunction error:&error];
    
    if (self.pipeline == nil) {
        NSLog(@"Failed to create pipeline: %@", error);
    }


    return make_float4(0);
}
 */

/*
               volume:(const Volume) volume
               pos:(const uint2) pos
               view:(const Matrix4) view
               nearPlane:(const float) nearPlane
               farPlane:(const float) farPlane
               step:(const float) step
               largestep:(const float) largestep
*/