//
//  AuthToken.m
//  RTCEngine
//
//  Created by xiang on 07/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import "AuthToken.h"

#import "RTCIceServer+JSON.h"

@implementation AuthToken

+(instancetype)parseToken:(NSString *)token
{
    
    NSArray* tokenSplit = [token componentsSeparatedByString:@"."];
    
    if ([tokenSplit count] != 3) {
        NSLog(@"parseToken error");
        return nil;
    }
    
    NSString *tokenData = base64StringFromBase64UrlEncodedString([tokenSplit objectAtIndex:1]);
    NSData *data = [[NSData alloc] initWithBase64EncodedString:tokenData options:0];
    NSDictionary*  dict =  [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    if (!dict) {
        NSLog(@"parseToken error");
        return nil;
    }
    
    AuthToken* auth = [[AuthToken alloc] init];
    
    auth.room = [dict objectForKey:kAuthTokenRoomKey];
    auth.userid = [dict objectForKey:kAuthTokenUseridKey];
    auth.wsURL = [dict objectForKey:kAuthTokenWsUrlKey];
    auth.token = token;
    
    if (auth.room == nil || auth.userid == nil || auth.wsURL == nil) {
        NSLog(@"parseToken error,  can not find room appkey userid");
        return nil;
    }
    
    NSArray* iceServers = [dict objectForKey:@"iceServers"];
    
    NSMutableArray *serverObjects = [NSMutableArray array];
    
    for (NSDictionary *serverJSON in iceServers) {
        RTCIceServer *server = [RTCIceServer serverFromJSONDictionary:serverJSON];
        [serverObjects addObject:server];
    }
    auth.iceServers = serverObjects;
    
    
    return auth;
}


@end
