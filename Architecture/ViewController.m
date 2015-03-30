//
//  ViewController.m
//  Architecture
//
//  Created by Tomas Virgl on 18/02/2015.
//  Copyright (c) 2015 Tomas Virgl. All rights reserved.
//

#import "ViewController.h"
#import "raycast.h"


@import Metal;

void ImageProviderReleaseData(void *info, const void *data, size_t size);

@interface ViewController (){
     UILabel *label;
}
//    @property (nonatomic, weak) IBOutlet UILabel *label;

//    @property (nonatomic, weak) IBOutlet UIImageView *imageView;
    @property (nonatomic, strong) IBOutlet UIImageView *imageView;
    @property (nonatomic, strong) id<MTLDevice> device;
    @property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
    @property (nonatomic, strong) id<MTLComputePipelineState> pipeline;

@end

@implementation ViewController

- (void) aMethod:(id)sender {
//    UILabel *label =  [[UILabel alloc] initWithFrame: CGRectMake(20,20,500,350)];
    //self->label =  [[UILabel alloc] initWithFrame: CGRectMake(20,20,500,350)];
    
    label.lineBreakMode = NSLineBreakByWordWrapping;

    [self.view addSubview:label];
    label.text = @"done";

    float3 qq;
    float3 *qa = &qq;
//    const char* c = run_sim(&(&(qq)));
    const char* c = run_sim(&qa);

    int x = 640;
    int y = 480;
    size_t total = x*y;


    NSInteger width = 640;
    NSInteger height = 480;
    NSInteger dataLength = width * height * 4;
    UInt8 *data = (UInt8*)malloc(dataLength * sizeof(UInt8));

    //Fill pixel buffer with color data
    for (int j=0; j<height; j++) {
        for (int i=0; i<width; i++) {

            float3 asd = qa[j*width+i];

            //Here I'm just filling every pixel with red
            // float red   = 1.0f;
            // float green = 0.0f;
            // float blue  = 0.0f;
            // float alpha = 1.0f;
            float red   = asd.x +1;
            float green = asd.y +1;
            float blue  = asd.z +1;
            float alpha = 1.0f;


            int index = 4*(i+j*width);
            data[index]  =255*red;
            data[++index]=255*green;
            data[++index]=255*blue;
            data[++index]=255*alpha;
        }
    }

    // Create a CGImage with the pixel data
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, data, dataLength, NULL);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef image = CGImageCreate(width, height, 8, 32, width * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,

                            provider, NULL, true, kCGRenderingIntentDefault);


    UIImage *filteredImage = [UIImage imageWithCGImage:image];
    self.imageView.image = filteredImage;

    
    NSString* fff = [[NSString alloc] initWithCString:c];
    label.text = fff;
    label.lineBreakMode = UILineBreakModeWordWrap;
    label.numberOfLines = 0;
    [label sizeToFit];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self->label =  [[UILabel alloc] initWithFrame: CGRectMake(20,20,500,350)];
    // self->label =  [[UILabel alloc] initWithFrame: CGRectMake(720,20,800,40)];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button addTarget:self
               action:@selector(aMethod:)
     forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Show View" forState:UIControlStateNormal];
    // button.frame = CGRectMake(80.0, 210.0, 160.0, 40.0);
    // button.frame = CGRectMake(350.0, 500.0, 160.0, 40.0);
    button.frame = CGRectMake(720.0,20.0, 160.0, 40.0);
    [self.view addSubview:button];
    
    
    
    [self setup];
    
    // self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(50,50,500,350)];
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(50,50,690,530)];
    self.imageView.image = [UIImage imageNamed:@"Lenna"];
    [self.view addSubview:self.imageView];
    
    [self filterImage:[UIImage imageNamed:@"Lenna"] completion:^(UIImage *filteredImage) {
        NSLog(@"Rendering done");
        self.imageView.image = filteredImage;
        
    }];
}

/*
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setup];
    
    [self filterImage:[UIImage imageNamed:@"AMG_GT"] completion:^(UIImage *filteredImage) {
        self.imageView.image = filteredImage;
    }];
}*/

- (void)setup
{
    self.device = MTLCreateSystemDefaultDevice();
    
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    id<MTLFunction> grayscaleFunction = [library newFunctionWithName:@"grayscale"];
    
    self.commandQueue = [self.device newCommandQueue];
    
    NSError *error = nil;
    self.pipeline = [self.device newComputePipelineStateWithFunction:grayscaleFunction error:&error];
    
    if (self.pipeline == nil) {
        NSLog(@"Failed to create pipeline: %@", error);
    }
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
    
    //[commandEncoder setBuffer:<#(id<MTLBuffer>)#> offset:<#(NSUInteger)#> atIndex:<#(NSUInteger)#>];
    
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

void ImageProviderReleaseData(void *info, const void *data, size_t size)
{
    free((void *)data);
}
