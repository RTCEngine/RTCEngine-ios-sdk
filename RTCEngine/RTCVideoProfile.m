//
//  RTCVideoProfile.m
//  RTCEngine
//
//  Created by xiang on 06/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import "RTCVideoProfile.h"

@implementation RTCVideoProfile

+(NSUInteger)widthForProfile:(RTCEngineVideoProfile)profile
{
    
    return  1;
}


+(NSDictionary*)infoForProfile:(RTCEngineVideoProfile)profile
{
    
    NSUInteger minWidth,minHeight,frameRate,maxVideoBitrate;
    
    switch (profile) {
        case RTCEngine_VideoProfile_120P:
            minWidth = 160;
            minHeight = 120;
            frameRate = 15;
            maxVideoBitrate = 80;
            break;
        case RTCEngine_VideoProfile_120P_2:
            minWidth = 120; minHeight = 160;
            frameRate = 15;
            maxVideoBitrate = 80;
            break;
        case RTCEngine_VideoProfile_120P_3:
            minWidth = 120; minHeight = 120;
            frameRate = 15;
            maxVideoBitrate = 60;
            break;
        case RTCEngine_VideoProfile_180P:
            minWidth = 320; minHeight = 180;
            frameRate = 15;
            maxVideoBitrate = 160;
        case RTCEngine_VideoProfile_180P_2:
            minWidth = 180; minHeight = 320;
            frameRate = 15;
            maxVideoBitrate = 160;
        case RTCEngine_VideoProfile_180P_3:
            minWidth = 180; minHeight = 180;
            frameRate = 15;
            maxVideoBitrate = 120;
            break;
        case RTCEngine_VideoProfile_240P:
            minWidth = 320; minHeight = 240;
            frameRate = 15;
            maxVideoBitrate = 200;
            break;
        case RTCEngine_VideoProfile_240P_2:
            minWidth = 240; minHeight = 320;
            frameRate = 15;
            maxVideoBitrate = 200;
            break;
        case RTCEngine_VideoProfile_240P_3:
            minWidth = 240; minHeight = 240;
            frameRate = 15;
            maxVideoBitrate = 160;
            break;
        case RTCEngine_VideoProfile_360P:
            minWidth = 640; minHeight = 360;
            frameRate = 15;
            maxVideoBitrate = 400;
            break;
        case RTCEngine_VideoProfile_360P_2:
            minWidth = 360; minHeight = 640;
            frameRate = 15;
            maxVideoBitrate = 400;
            break;
        case RTCEngine_VideoProfile_360P_3:
            minWidth = 360; minHeight = 360;
            frameRate = 15;
            maxVideoBitrate = 300;
            break;
        case RTCEngine_VideoProfile_360P_4:
            minWidth = 640; minHeight = 360;
            frameRate = 30;
            maxVideoBitrate = 800;
            break;
        case RTCEngine_VideoProfile_360P_5:
            minWidth = 360; minHeight = 640;
            frameRate = 30;
            maxVideoBitrate = 800;
            break;
            
        case RTCEngine_VideoProfile_360P_6:
            minWidth = 360; minHeight = 360;
            frameRate = 30;
            maxVideoBitrate = 600;
            break;
            
        case RTCEngine_VideoProfile_480P:
            frameRate = 15;
            minWidth = 640; minHeight = 480;
            maxVideoBitrate = 500;
            break;
            
        case RTCEngine_VideoProfile_480P_2:
            minWidth = 480; minHeight = 640;
            frameRate = 15;
            maxVideoBitrate = 500;
            break;
            
        case RTCEngine_VideoProfile_480P_3:
            minWidth = 480; minHeight = 480;
            frameRate = 15;
            maxVideoBitrate = 400;
            break;
        case RTCEngine_VideoProfile_480P_4:
            minWidth = 640; minHeight = 480;
            frameRate = 30;
            maxVideoBitrate = 750;
            break;
        case RTCEngine_VideoProfile_480P_5:
            minWidth = 480; minHeight = 640;
            frameRate = 30;
            maxVideoBitrate = 750;
            break;
        case RTCEngine_VideoProfile_480P_6:
            minWidth = 480; minHeight = 480;
            frameRate = 30;
            maxVideoBitrate = 680;
            break;
        case RTCEngine_VideoProfile_480P_7:
            minWidth = 640; minHeight = 480;
            frameRate = 15;
            maxVideoBitrate = 1000;
            break;
        case RTCEngine_VideoProfile_720P:
            frameRate = 15;
            minWidth = 1280; minHeight = 720;
            maxVideoBitrate = 1000;
            break;
        case RTCEngine_VideoProfile_720P_2:
            frameRate = 15;
            minWidth = 720; minHeight = 1280;
            maxVideoBitrate = 1000;
            break;
        case RTCEngine_VideoProfile_720P_3:
            minWidth = 1280; minHeight = 720;
            frameRate = 25;
            maxVideoBitrate = 1700;
            break;
        case RTCEngine_VideoProfile_720P_4:
            minWidth = 720; minHeight = 1280;
            frameRate = 25;
            maxVideoBitrate = 1700;
            break;
        default:
            break;
    }
    NSDictionary* info = @{
                           @"minWidth":@(minWidth),
                           @"minHeight":@(minHeight),
                           @"frameRate":@(frameRate),
                           @"maxVideoBitrate":@(maxVideoBitrate)
                           };
    return info;
}
@end
