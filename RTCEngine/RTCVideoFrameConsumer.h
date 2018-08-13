//
//  RTCVideoFrameConsumer.h
//  RTCEngine
//
//  Created by xiang on 13/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import <Foundation/Foundation.h>

@import WebRTC;

@protocol RTCVideoFrameDelegate <NSObject>

- (void)didGotVideoFrame:(RTCVideoFrame *)frame;

@end

@interface RTCVideoFrameConsumer : NSObject <RTCVideoCapturerDelegate>

@property (nonatomic, weak) id<RTCVideoFrameDelegate> _Nullable delegate;

-(instancetype)initWithDelegate:(id<RTCVideoFrameDelegate>)delegate;

@end
