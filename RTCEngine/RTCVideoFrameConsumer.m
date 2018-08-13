//
//  RTCVideoFrameConsumer.m
//  RTCEngine
//
//  Created by xiang on 13/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import "RTCVideoFrameConsumer.h"

@implementation RTCVideoFrameConsumer

-(instancetype)initWithDelegate:(id<RTCVideoFrameDelegate>)delegate
{
    self = [super init];
    _delegate = delegate;
    return self;
}


-(void)capturer:(RTCVideoCapturer *)capturer didCaptureVideoFrame:(RTCVideoFrame *)frame
{
    if (self.delegate != nil && frame != nil) {
        [self.delegate didGotVideoFrame:frame];
    }
}


@end
