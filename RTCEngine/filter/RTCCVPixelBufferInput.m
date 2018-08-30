//
//  RTCCVPixelBufferInput.m
//  RTCEngine
//
//  Created by xiang on 13/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import "RTCCVPixelBufferInput.h"

@interface RTCCVPixelBufferInput()

@property (nonatomic) CVOpenGLESTextureRef textureRef;

@property (nonatomic, strong) dispatch_semaphore_t frameRenderingSemaphore;

@end

@implementation RTCCVPixelBufferInput

- (instancetype)init {
    if (self = [super init]) {
        self.frameRenderingSemaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)dealloc {
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        
        if (self.textureRef) {
            CFRelease(self.textureRef);
        }
    });
}


- (BOOL)processCVPixelBuffer:(CVPixelBufferRef)pixelBuffer rotation:(RTCVideoRotation)rotation
{
    
    if (dispatch_semaphore_wait(self.frameRenderingSemaphore, DISPATCH_TIME_NOW) != 0) {
        return NO;
    }
    
    OSType pixelFormatType = CVPixelBufferGetPixelFormatType(pixelBuffer);
    
    if (!(pixelFormatType == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange || pixelFormatType == kCVPixelFormatType_32BGRA)) {
        NSLog(@"only support 32BGRA and NV12");
        return NO;
    }
    
    size_t bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
    size_t bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        
        if (self.textureRef) {
            CFRelease(self.textureRef);
        }
        
        CVOpenGLESTextureRef textureRef = NULL;
        CVReturn result = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                       [[GPUImageContext sharedImageProcessingContext] coreVideoTextureCache],
                                                                       pixelBuffer,
                                                                       NULL,
                                                                       GL_TEXTURE_2D,
                                                                       GL_RGBA,
                                                                       (GLsizei)bufferWidth,
                                                                       (GLsizei)bufferHeight,
                                                                       GL_BGRA,
                                                                       GL_UNSIGNED_BYTE,
                                                                       0,
                                                                       &textureRef);
        
        NSAssert(result == kCVReturnSuccess, @"CVOpenGLESTextureCacheCreateTextureFromImage error: %@",@(result));
        
        if (result == kCVReturnSuccess && textureRef) {
            self.textureRef = textureRef;
            
            glActiveTexture(GL_TEXTURE4);
            glBindTexture(CVOpenGLESTextureGetTarget(textureRef), CVOpenGLESTextureGetName(textureRef));
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            outputFramebuffer = [[GPUImageFramebuffer alloc] initWithSize:CGSizeMake(bufferWidth, bufferHeight) overriddenTexture:CVOpenGLESTextureGetName(textureRef)];
            
            for (id<GPUImageInput> currentTarget in targets) {
                if ([currentTarget enabled]) {
                    NSInteger indexOfObject = [targets indexOfObject:currentTarget];
                    NSInteger targetTextureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
                    if (currentTarget != self.targetToIgnoreForUpdates) {
                        [currentTarget setInputSize:CGSizeMake(bufferWidth, bufferHeight) atIndex:targetTextureIndex];
                        [currentTarget setInputFramebuffer:outputFramebuffer atIndex:targetTextureIndex];
                        [currentTarget newFrameReadyAtTime:kCMTimeIndefinite atIndex:targetTextureIndex];
                    } else {
                        [currentTarget setInputFramebuffer:outputFramebuffer atIndex:targetTextureIndex];
                    }
                }
            }
        }
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
        CVPixelBufferRelease(pixelBuffer);
        
        dispatch_semaphore_signal(self.frameRenderingSemaphore);
    });
    
    return YES;
    
}


void NV12TOARGB(const unsigned char *src,const unsigned int *dst,int width,int height)
{
    int frameSize = width * height;
    
    int i = 0, j = 0,yp = 0;
    int uvp = 0, u = 0, v = 0;
    int y1192 = 0, r = 0, g = 0, b = 0;
    unsigned int *target=dst;
    for (j = 0, yp = 0; j < height; j++)
    {
        uvp = frameSize + (j >> 1) * width;
        u = 0;
        v = 0;
        for (i = 0; i < width; i++, yp++)
        {
            int y = (0xff & ((int) src[yp])) - 16;
            if (y < 0)
                y = 0;
            if ((i & 1) == 0)
            {
                u = (0xff & src[uvp++]) - 128;
                v = (0xff & src[uvp++]) - 128;
            }
            
            y1192 = 1192 * y;
            r = (y1192 + 1634 * v);
            g = (y1192 - 833 * v - 400 * u);
            b = (y1192 + 2066 * u);
            
            if (r < 0) r = 0; else if (r > 262143) r = 262143;
            if (g < 0) g = 0; else if (g > 262143) g = 262143;
            if (b < 0) b = 0; else if (b > 262143) b = 262143;
            target[yp] = 0xff000000 | ((r << 6) & 0xff0000) | ((g >> 2) & 0xff00) | ((b >> 10) & 0xff);
        }
    }
}


@end
