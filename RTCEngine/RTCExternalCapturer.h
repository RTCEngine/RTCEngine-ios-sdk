//
//  RTCExternalCapturer.h
//  RTCEngine
//
//  Created by xiang on 13/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import <Foundation/Foundation.h>

@import CoreVideo;

typedef NS_ENUM(NSInteger, VideoRotation){
    
    VideoRoation_0 = 0,
    VideoRoation_90 = 90,
    VideoRoation_180 = 180,
    VideoRoation_270 = 270,
};


@protocol RTCExternalCapturerConsumer <NSObject>

-(void) gotExternalCVPixelBuffer:(CVPixelBufferRef _Nonnull) pixelBuffer
                rotation:(VideoRotation)rotation;

@end

@interface RTCExternalCapturer : NSObject

@property(atomic, assign) id<RTCExternalCapturerConsumer> _Nullable videoConsumer;

-(void) sendCVPixelBuffer:(CVPixelBufferRef _Nonnull)pixelBuffer rotation:(VideoRotation)rotation;

@end
