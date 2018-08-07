//
//  StringUtils.h
//  RTCEngine
//
//  Created by xiang on 07/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Utilites)

+ (NSDictionary *)dictionaryWithJSONString:(NSString *)jsonString;
+ (NSDictionary *)dictionaryWithJSONData:(NSData *)jsonData;

@end


NSString *createGUID();

NSDictionary* jwtDecodeToken(NSString *tokenStr);

NSString* base64StringFromBase64UrlEncodedString(NSString *base64UrlEncodedString);
