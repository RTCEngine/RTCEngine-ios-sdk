//
//  StringUtils.m
//  RTCEngine
//
//  Created by xiang on 07/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import "StringUtils.h"

#import <mach/mach.h>

@implementation NSDictionary(Utilites)

+ (NSDictionary *)dictionaryWithJSONString:(NSString *)jsonString {
    NSParameterAssert(jsonString.length > 0);
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *dict =
    [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    return dict;
}

+ (NSDictionary *)dictionaryWithJSONData:(NSData *)jsonData {
    NSError *error = nil;
    NSDictionary *dict =
    [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    return dict;
}

@end


NSString* createGUID()
{
    return [[NSUUID UUID] UUIDString];
}


NSDictionary* jwtDecodeToken(NSString *tokenStr)
{
    NSArray* tokenSplit = [tokenStr componentsSeparatedByString:@"."];
    NSString *token = base64StringFromBase64UrlEncodedString(tokenSplit[1]);
    NSData *data = [[NSData alloc] initWithBase64EncodedString:token options:0];
    NSDictionary*  dict =  [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return dict;
}


NSString* base64StringFromBase64UrlEncodedString(NSString *base64UrlEncodedString)
{
    NSString *s = base64UrlEncodedString;
    s = [s stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
    s = [s stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
    switch (s.length % 4) {
        case 2:
            s = [s stringByAppendingString:@"=="];
            break;
        case 3:
            s = [s stringByAppendingString:@"="];
            break;
        default:
            break;
    }
    return s;
}



