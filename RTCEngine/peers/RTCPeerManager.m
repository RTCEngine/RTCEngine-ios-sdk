//
//  RTCPeerManager.m
//  RTCEngine
//
//  Created by xiang on 14/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import "RTCPeerManager.h"

@implementation RTCPeerManager

-(instancetype)init
{
    self = [super init];
    
    _peers = [NSMutableDictionary dictionary];
    
    return self;
}


-(RTCPeer*)getPeer:(NSString *)peerId
{
    
    RTCPeer* peer = [_peers objectForKey:peerId];
    return peer;
}


-(void)updatePeer:(NSDictionary*)dict
{
    RTCPeer *peer = [[RTCPeer alloc] initFromDictionary:dict];
    [_peers setObject:peer forKey:peer.peerid];
}

-(void)removePeer:(NSString*)peerId
{
    [_peers removeObjectForKey:peerId];
    
}


-(RTCPeer*)peerForStream:(NSString *)streamId
{
    RTCPeer* peer = nil;
    for (NSString* _peerid in _peers) {
        RTCPeer* _peer = [_peers objectForKey:_peerid];
        for (NSDictionary* _stream in _peer.streams) {
            NSString* _streamId = [_stream objectForKey:@"id"];
            if ([streamId isEqualToString:_streamId]) {
                peer = _peer;
                break;
            }
        }
    }
    return peer;
}

-(void)clearAll
{
    [_peers removeAllObjects];
}

@end
