//
//  RTCVideoFaceBeautyFilter.h
//  RTCEngine
//
//  Created by xiang on 13/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GPUImage.h>

@interface RTCVideoFaceBeautyFilter : GPUImageFilter

@property (nonatomic, assign) CGFloat beautyLevel;
@property (nonatomic, assign) CGFloat brightLevel;
@property (nonatomic, assign) CGFloat toneLevel;

@end
