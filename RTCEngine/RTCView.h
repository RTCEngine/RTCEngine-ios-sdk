//
//  RTCView.h
//  RTCEngine
//
//  Created by xiang on 06/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import <Foundation/Foundation.h>

@import CoreGraphics;
@import UIKit;

@class RTCView;
@class RTCStream;

typedef NS_ENUM(NSUInteger, RTCVideoViewScaleMode)
{
    
    RTCVideoViewScaleModeFit = 0,
    RTCVideoViewScaleModeFill = 1,
};



// TODO move to METAL

@protocol RTCViewDelegate <NSObject>

- (void)videoViewDidReceiveData:(RTCView *)renderer withSize:(CGSize)dimensions;
- (void)videoView:(RTCView *)renderer streamDimensionsDidChange:(CGSize)dimensions;

@end


@interface RTCView : UIView

@property (nonatomic, readonly) CGSize videoSize;
@property (nonatomic, readonly) BOOL hasVideoData;
@property (nonatomic, weak)     id<RTCViewDelegate>  dotViewDelegate;
@property (nonatomic, assign)   RTCVideoViewScaleMode scaleMode;
@property (nonatomic, assign)   BOOL mirror;

- (instancetype)initWithFrame:(CGRect)frame;

- (void)setStream:(RTCStream *)stream;

@end
