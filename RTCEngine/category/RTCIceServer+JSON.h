//
//  RTCIceServer+JSON.h
//  RTCEngine
//
//  Created by xiang on 06/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import <Foundation/Foundation.h>

@import WebRTC;

@interface RTCIceServer (JSON)

+ (RTCIceServer *)serverFromJSONDictionary:(NSDictionary *)dictionary;

@end
