//
//  AuthToken.h
//  RTCEngine
//
//  Created by xiang on 07/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "StringUtils.h"


static NSString* _Nonnull kAuthTokenRoomKey = @"room";
static NSString* _Nonnull kAuthTokenUseridKey = @"user";
static NSString* _Nonnull kAuthTokenAppkeyKey = @"appkey";
static NSString* _Nonnull kAuthTokenExpiresKey = @"expires";
static NSString* _Nonnull kAuthTokenRoleKey = @"role";
static NSString* _Nonnull kAuthTokenIceServerKey = @"iceServers";
static NSString* _Nonnull kAuthTokenWsUrlKey = @"wsUrl";

@interface AuthToken : NSObject

@property(nonnull, strong) NSString*  wsURL;
@property(nonnull, strong) NSString*  userid;
@property(nonnull, strong) NSString*  room;
@property(nonnull, strong) NSString*  token;


+(instancetype _Nullable)parseToken:(NSString* _Nonnull)token;

@end
