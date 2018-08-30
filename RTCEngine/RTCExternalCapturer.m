//
//  RTCExternalCapturer.m
//  RTCEngine
//
//  Created by xiang on 13/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import "RTCExternalCapturer.h"

@implementation RTCExternalCapturer

-(void)sendCVPixelBuffer:(CVPixelBufferRef)pixelBuffer rotation:(VideoRotation)rotation
{
    if(_videoConsumer != nil) {
        [_videoConsumer gotExternalCVPixelBuffer:pixelBuffer rotation:rotation];
    }
}

@end
