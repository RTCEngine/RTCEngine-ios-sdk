//
//  RTCCVPixelBufferConverter.h
//  RTCEngine
//
//  Created by xiang on 13/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import <Foundation/Foundation.h>

@import AVFoundation;

@interface RTCCVPixelBufferConverter : NSObject

+(CVPixelBufferRef)NV12TOARGB:(CVPixelBufferRef)pixelBuffer;
+(CVPixelBufferRef)ARGBTONV12:(uint8_t*)rawbyte width:(int)width height:(int)height;

@end
