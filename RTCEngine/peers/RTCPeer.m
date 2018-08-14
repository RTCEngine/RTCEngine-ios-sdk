//
//  RTCPeer.m
//  RTCEngine
//
//  Created by xiang on 14/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import "RTCPeer.h"

@implementation RTCPeer

-(instancetype)initWithId:(NSString*)peerId
{
    self = [super init];
    if (self) {
        _peerid = peerId;
    }
    return self;
}

-(instancetype) initFromDictionary:(NSDictionary *)dict
{
    self = [super init];
    _peerid = [dict objectForKey:@"id"];
    _streams  = [dict objectForKey:@"streams"];
    return self;
}

-(NSDictionary*) getStream:(NSString*) streamId
{
    NSDictionary* stream = [NSDictionary dictionary];
    for (NSDictionary* _stream in _streams) {
        NSString* _streamId = [_stream objectForKey:@"id"]
        if ([streamId isEqualToString:_streamId]) {
            stream = _stream;
            break;
        }
    }
    return stream;
}

-(BOOL) isEqual:(RTCPeer*)object
{
    
    return [object.peerid isEqual:_peerid];
}

-(NSUInteger)hash
{
    return [self.peerid hash];
}

@end
