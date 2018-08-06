//
//  RTCVideoCapturer.h
//  RTCEngine
//
//  Created by xiang on 06/08/2018.
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


@protocol DotCapturerConsumer <NSObject>

-(void) gotCVPixelBuffer:(CVPixelBufferRef _Nonnull) sampleBuffer
                rotation:(VideoRotation)rotation;

@end


@interface RTCVideoCapturer : NSObject

@end
