//
//  RTCVideoFilterManager.m
//  RTCEngine
//
//  Created by xiang on 13/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import "RTCVideoFilterManager.h"

@interface RTCVideoFilterManager()
{
    CGSize videoSize;
    RTCCVPixelBufferInput* input;
    RTCVideoFaceBeautyFilter* filter;
    GPUImageRawDataOutput* output;
    
    RTCVideoRotation  currentRotation;
}

@end

@implementation RTCVideoFilterManager

-(instancetype)initWithSize:(CGSize)size delegate:(id<RTCVideoFilterOutputDelegate>)delegate
{
    self = [super init];
    videoSize = size;
    input = [[RTCCVPixelBufferInput alloc] init];
    filter = [[RTCVideoFaceBeautyFilter alloc] init];
    output = [[GPUImageRawDataOutput alloc] initWithImageSize:videoSize resultsInBGRAFormat:YES];
    _delegate = delegate;
    [input addTarget:filter];
    [filter addTarget:output];
    
    currentRotation = RTCVideoRotation_0;
    
    __unsafe_unretained GPUImageRawDataOutput * weakOutput = output;
    
    [output setNewFrameAvailableBlock:^{
        
        [weakOutput lockFramebufferForReading];
        
        if (delegate != nil) {
            CVPixelBufferRef pixelBuffer = [RTCCVPixelBufferConverter ARGBTONV12:[weakOutput rawBytesForImage] width:size.width height:size.height];
            [delegate newFilterFrameAvailable:pixelBuffer];
            CVPixelBufferRelease(pixelBuffer);
        }
        
        [weakOutput unlockFramebufferAfterReading];
    }];
    
    return self;
}


-(void)setBeautyLevel:(CGFloat)level
{
    _beautyLevel = level;
    [filter setBeautyLevel:level];
}

-(void)setBrightLevel:(CGFloat)level
{
    _brightLevel = level;
    [filter setBrightLevel:level];
}

-(void)updateSize:(CGSize)size
{
    
    // todo
}

-(BOOL)processCVPixelBuffer:(CVPixelBufferRef)pixelBuffer rotation:(RTCVideoRotation)rotation
{
    
    if (currentRotation != rotation) {
        currentRotation = rotation;
    }
    OSType pixelFormatType = CVPixelBufferGetPixelFormatType(pixelBuffer);
    BOOL ret;
    if (pixelFormatType == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
        CVPixelBufferRef copypixelBuffer = [RTCCVPixelBufferConverter NV12TOARGB:pixelBuffer];
        ret = [input processCVPixelBuffer:copypixelBuffer rotation:currentRotation];
        return ret;
    }
    
    ret = [input processCVPixelBuffer:pixelBuffer rotation:currentRotation];
    return ret;
}

@end
