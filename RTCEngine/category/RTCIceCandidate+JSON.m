//
//  RTCIceCandidate.m
//  RTCEngine
//
//  Created by xiang on 06/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import "RTCIceCandidate+JSON.h"



@implementation RTCIceCandidate (JSON)


+ (RTCIceCandidate *)candidateFromJSONDictionary:(NSDictionary *)dictionary
{
    
    NSString* sdp = [dictionary valueForKey:@"sdp"];
    NSString* mid = [dictionary valueForKey:@"sdpMid"];
    NSNumber* mLineIndex = [dictionary valueForKey:@"sdpMLineIndex"];
    
    RTCIceCandidate* candidate = [[RTCIceCandidate alloc]
                                  initWithSdp:sdp
                                  sdpMLineIndex:mLineIndex.intValue
                                  sdpMid:mid];
    return candidate;
}

- (NSDictionary *)jsonDict
{
    
    NSDictionary *json = @{
                           @"sdpMLineIndex" : @(self.sdpMLineIndex),
                           @"sdpMid" : self.sdpMid,
                           @"sdp" : self.sdp
                           };
    
    return json;
}

@end
