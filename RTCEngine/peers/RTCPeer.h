//
//  RTCPeer.h
//  RTCEngine
//
//  Created by xiang on 14/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RTCPeer : NSObject

@property (nonatomic,copy) NSString* peerid;
@property (nonatomic,copy) NSArray* streams;

-(instancetype)initFromDictionary:(NSDictionary*)dict;

-(NSDictionary*) getStream:(NSString*) streamId;

@end
