//
//  RTCView+Internal.h
//  RTCEngine
//
//  Created by xiang on 06/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import "RTCView.h"

@import WebRTC;

@interface RTCView() <RTCVideoRenderer>

-(UIImage*) snapshot;


- (void)setVideoTrack:(RTCVideoTrack*)track;

- (void)changeVideoSize:(CGSize)size;

@end
