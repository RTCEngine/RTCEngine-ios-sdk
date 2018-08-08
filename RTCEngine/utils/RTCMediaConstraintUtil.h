//
//  RTCMediaConstraintUtil.h
//  RTCEngine
//
//  Created by xiang on 08/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import <Foundation/Foundation.h>

@import WebRTC;

@interface RTCMediaConstraintUtil : NSObject

+ (RTCMediaConstraints *)offerConstraints;

+ (RTCMediaConstraints *)answerConstraints;

+ (RTCMediaConstraints *)connectionConstraints;

@end
