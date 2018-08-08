//
//  RTCMediaConstraintUtil.m
//  RTCEngine
//
//  Created by xiang on 08/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import "RTCMediaConstraintUtil.h"

@implementation RTCMediaConstraintUtil

+ (RTCMediaConstraints *)offerConstraints
{
    
    NSDictionary *mandatoryConstraints;
    mandatoryConstraints = @{
                             @"OfferToReceiveAudio":@"true",
                             @"OfferToReceiveVideo":@"true"
                             };
    
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc]
                                        initWithMandatoryConstraints:mandatoryConstraints
                                        optionalConstraints:nil];
    return constraints;
}

+ (RTCMediaConstraints *)answerConstraints
{
    NSDictionary *mandatoryConstraints;
    mandatoryConstraints = @{
                             @"OfferToReceiveAudio":@"true",
                             @"OfferToReceiveVideo":@"true"
                             };
    
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc]
                                        initWithMandatoryConstraints:mandatoryConstraints
                                        optionalConstraints:nil];
    return constraints;
}

+ (RTCMediaConstraints *)connectionConstraints
{
    NSDictionary *optionalConstraints = @{
                                          //@"DtlsSrtpKeyAgreement":@"true",
                                          };
    
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc]
                                        initWithMandatoryConstraints:nil
                                        optionalConstraints:optionalConstraints];
    
    return constraints;
}

@end
