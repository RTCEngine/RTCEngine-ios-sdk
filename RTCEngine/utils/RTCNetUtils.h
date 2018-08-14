//
//  RTCNetUtils.h
//  RTCEngine
//
//  Created by xiang on 14/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (UrlEncoding)

-(NSString*) urlEncodedString;

@end

@interface RTCNetUtils : NSObject

+(void)postWithParams:(NSDictionary*)params url:(NSString*)url  withBlock:(void (^)(NSString* token, NSError* error))block;

@end
