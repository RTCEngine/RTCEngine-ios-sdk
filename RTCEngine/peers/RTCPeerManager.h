//
//  RTCPeerManager.h
//  RTCEngine
//
//  Created by xiang on 14/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RTCPeer.h"

@interface RTCPeerManager : NSObject

@property (nonatomic,strong) NSMutableDictionary* peers;

-(RTCPeer*)getPeer:(NSString*)peerId;

-(void)updatePeer:(NSDictionary*)dict;

-(void)removePeer:(NSString*)peerId;

-(void)clearAll;

-(RTCPeer*)peerForStream:(NSString*)streamId;

@end
