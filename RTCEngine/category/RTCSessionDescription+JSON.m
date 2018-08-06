//
//  RTCSessionDescription+JSON.m
//  RTCEngine
//
//  Created by xiang on 06/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import "RTCSessionDescription+JSON.h"

static NSString const *kRTCSessionDescriptionTypeKey = @"type";
static NSString const *kRTCSessionDescriptionSdpKey = @"sdp";


@implementation RTCSessionDescription (JSON)



+ (RTCSessionDescription *)descriptionFromJSONDictionary:
(NSDictionary *)dictionary {
    NSString *typeString = dictionary[kRTCSessionDescriptionTypeKey];
    RTCSdpType type = [[self class] typeForString:typeString];
    NSString *sdp = dictionary[kRTCSessionDescriptionSdpKey];
    return [[RTCSessionDescription alloc] initWithType:type sdp:sdp];
}


-(NSDictionary *) jsonData {
    
    NSString *type = [[self class] stringForType:self.type];
    NSDictionary *json = @{
                           kRTCSessionDescriptionTypeKey : type,
                           kRTCSessionDescriptionSdpKey : self.sdp
                           };
    
    return json;
}




@end
