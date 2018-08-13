//
//  RTCVideoProfile.h
//  RTCEngine
//
//  Created by xiang on 06/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

@import Foundation;

typedef NS_ENUM(NSInteger)
{
    
    RTCEngine_VideoProfile_120P = 0,            // 160x120   15   80
    RTCEngine_VideoProfile_120P_2 = 1,          // 120x160   15   80
    RTCEngine_VideoProfile_120P_3 = 2,          // 120x120   15   60
    
    RTCEngine_VideoProfile_180P = 10,           // 320x180   15   160
    RTCEngine_VideoProfile_180P_2 = 11,         // 180x320   15   160
    RTCEngine_VideoProfile_180P_3 = 12,         // 180x180   15   120
    
    RTCEngine_VideoProfile_240P = 20,           // 320x240   15   200
    RTCEngine_VideoProfile_240P_2 = 21,         // 240x320   15   200
    RTCEngine_VideoProfile_240P_3 = 22,         // 240x240   15   160
    
    RTCEngine_VideoProfile_360P = 30,           // 640x360   15   400
    RTCEngine_VideoProfile_360P_2 = 31,         // 360x640   15   400
    RTCEngine_VideoProfile_360P_3 = 32,         // 360x360   15   300
    
    RTCEngine_VideoProfile_360P_4 = 33,         // 640x360   30   800
    RTCEngine_VideoProfile_360P_5 = 34,         // 360x640   30   800
    RTCEngine_VideoProfile_360P_6 = 35,         // 360x360   30   600
    
    RTCEngine_VideoProfile_480P = 40,           // 640x480   15   500
    RTCEngine_VideoProfile_480P_2 = 41,         // 480x640   15   500
    RTCEngine_VideoProfile_480P_3 = 42,         // 480x480   15   400
    
    RTCEngine_VideoProfile_480P_4 = 43,         // 640x480   30   750
    RTCEngine_VideoProfile_480P_5 = 44,         // 480x640   30   750
    RTCEngine_VideoProfile_480P_6 = 45,         // 480x480   30   680
    RTCEngine_VideoProfile_480P_7 = 46,         // 640x480   15   1000
    
    RTCEngine_VideoProfile_720P = 50,           // 1280x720  15   1000
    RTCEngine_VideoProfile_720P_2 = 51,         // 720x1280  15   1000
    RTCEngine_VideoProfile_720P_3 = 52,         // 1280x720  30   1700
    RTCEngine_VideoProfile_720P_4 = 53,         // 720x1280  30   1700
    
} RTCEngineVideoProfile;


@interface RTCVideoProfile : NSObject
+(NSDictionary*)infoForProfile:(RTCEngineVideoProfile)profile;
@end
