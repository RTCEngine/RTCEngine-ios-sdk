//
//  AuthToken.h
//  RTCEngine
//
//  Created by xiang on 07/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <WebRTC/RTCIceServer.h>
#import "StringUtils.h"

static NSString* _Nonnull kAuthTokenRoomKey = @"room";
static NSString* _Nonnull kAuthTokenUserKey = @"user";
static NSString* _Nonnull kAuthTokenAppkeyKey = @"appkey";
static NSString* _Nonnull kAuthTokenExpiresKey = @"expires";
static NSString* _Nonnull kAuthTokenRoleKey = @"role";
static NSString* _Nonnull kAuthTokenIceServerKey = @"iceServers";
static NSString* _Nonnull kAuthTokenWsUrlKey = @"wsUrl";
static NSString* _Nonnull kAuthTokenIceTransportPolicy = @"iceTransportPolicy";

@interface AuthToken : NSObject

@property(nonnull, strong) NSString*  wsURL;
@property(nonnull, strong) NSString*  user;
@property(nonnull, strong) NSString*  room;
@property(nonnull, strong) NSString*  token;
@property(nonnull, strong) NSString*  iceTransportPolicy;
@property(nonnull, strong) NSArray<RTCIceServer *>* iceServers;

+(instancetype _Nullable)parseToken:(NSString* _Nonnull)token;

@end
