//
//  RTCCVPixelBufferConverter.m
//  RTCEngine
//
//  Created by xiang on 13/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import "RTCCVPixelBufferConverter.h"

#import <libyuv.h>

@implementation RTCCVPixelBufferConverter

+(CVPixelBufferRef)NV12TOARGB:(CVPixelBufferRef)pixelBuffer
{
    
    NSAssert(CVPixelBufferGetPixelFormatType(pixelBuffer) ==kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, @"%@: only kCVPixelFormatType_32BGRA is supported currently.",self);
    
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    
    CVPixelBufferRef copyPixelBuffer = NULL;
    CVPixelBufferCreate(kCFAllocatorDefault,
                        width, height, kCVPixelFormatType_32BGRA, NULL, &copyPixelBuffer);
    
    CVPixelBufferLockBaseAddress(copyPixelBuffer, 0);
    
    uint8_t *copyAddress = CVPixelBufferGetBaseAddress(copyPixelBuffer);
    
    
    uint8_t *ysrc = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer,0);
    uint8_t *uvsrc = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer,1);
    
    NV12ToARGB(ysrc, width,
               uvsrc, width,
               copyAddress, width * 4,
               width, height);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    CVPixelBufferUnlockBaseAddress(copyPixelBuffer, 0);
    
    return copyPixelBuffer;
}


+(CVPixelBufferRef)ARGBTONV12:(uint8_t*)srcAddress width:(int)width height:(int)height
{
    int half_width = (width + 1) / 2;
    int half_height = (height + 1) / 2;
    
    const int y_size = width * height;
    const int uv_size = half_width * half_height * 2 ;
    const size_t total_size = y_size + uv_size;
    
    
    CVPixelBufferRef pixelBuffer = NULL;
    
    CVPixelBufferCreate(kCFAllocatorDefault, width , height,
                        kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                        NULL, &pixelBuffer);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    uint8_t *yplan = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer,0);
    uint8_t *uvplan = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer,1);
    ARGBToNV12(srcAddress, width * 4,
               yplan, half_width * 2,
               uvplan,  half_width * 2,
               width, height);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return pixelBuffer;
}

@end
