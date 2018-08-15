//
//  RTCVideoFilterManager.h
//  RTCEngine
//
//  Created by xiang on 13/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import <Foundation/Foundation.h>

@import GPUImage;

#import "RTCCVPixelBufferInput.h"
#import "RTCVideoFaceBeautyFilter.h"
#import "RTCCVPixelBufferConverter.h"

@import CoreVideo;

@protocol RTCVideoFilterOutputDelegate <NSObject>

-(void)newFilterFrameAvailable:(CVPixelBufferRef)pixelBuffer;

@end


@interface RTCVideoFilterManager : NSObject

@property (nonatomic, assign) CGFloat beautyLevel;
@property (nonatomic, assign) CGFloat brightLevel;
@property (nonatomic, weak) id<RTCVideoFilterOutputDelegate> delegate;


-(instancetype)initWithSize:(CGSize)size delegate:(id<RTCVideoFilterOutputDelegate>)delegate;

-(void)updateSize:(CGSize)size;

-(BOOL)processCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;


@end
