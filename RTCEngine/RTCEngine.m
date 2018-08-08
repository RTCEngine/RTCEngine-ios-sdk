//
//  RTCEngine.m
//  RTCEngine
//
//  Created by xiang on 06/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import "RTCEngine.h"


#import "AuthToken.h"

@import WebRTC;


static RTCEngine *sharedRTCEngineInstance = nil;


@interface RTCEngine () <RTCPeerConnectionDelegate>
{
    NSString    *roomId;
    NSString    *localUserId;
}

@end

@implementation RTCEngine


-(instancetype) initWithDelegate:(id<RTCEngineDelegate>) delegate
{
    
    if (self = [super init]) {
        self.delegate = delegate;
        _status = RTCEngineStatusNew;
        RTCInitializeSSL();
        
        // TODO  init logger
    }
    
    return self;
}


+(instancetype) sharedInstanceWithDelegate:(id<RTCEngineDelegate>)delegate
{
    
    @synchronized(self) {
        if (!sharedRTCEngineInstance) {
            sharedRTCEngineInstance = [[self alloc] initWithDelegate: delegate];
        }
    }
    return  sharedRTCEngineInstance;
}


+(instancetype) sharedInstance
{
    @synchronized(self) {
        if (!sharedRTCEngineInstance) {
            sharedRTCEngineInstance = [[self alloc] initWithDelegate: nil];
        }
    }
    return  sharedRTCEngineInstance;
}


-(void)joinRoomWithToken:(NSString *)token
{
    NSParameterAssert(token);
    
    AuthToken* authToken = [AuthToken parseToken:token];
    
    if (AuthToken == nil) {
        [self.delegate rtcengine:self didOccurError:RTCEngine_Error_TokenError];
        return;
    }
    
    if (_status == RTCEngineStatusConnected) {
        return;
    }
    
    roomId = authToken.room;
    localUserId = authToken.userid;
    
}

-(void) addStream:(RTCStream *)stream
{
    if (_status != RTCEngineStatusConnected) {
        return
    }
    
    
}




#pragma mark - internal






#pragma mark - delegate


- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeSignalingState:(RTCSignalingState)stateChanged
{
    
    
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didAddStream:(RTCMediaStream *)stream
{
    
    
}


- (void)peerConnection:(RTCPeerConnection *)peerConnection didRemoveStream:(RTCMediaStream *)stream
{
    
    
}

/** Called when negotiation is needed, for example ICE has restarted. */
- (void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection
{
    
    
}


- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceConnectionState:(RTCIceConnectionState)newState
{
    
    
}

/** Called any time the IceGatheringState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceGatheringState:(RTCIceGatheringState)newState
{
    // do nothing
}


- (void)peerConnection:(RTCPeerConnection *)peerConnection
didGenerateIceCandidate:(RTCIceCandidate *)candidate
{
    // do nothing
}


- (void)peerConnection:(RTCPeerConnection *)peerConnection
didRemoveIceCandidates:(NSArray<RTCIceCandidate *> *)candidates
{
    // do nothing
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didOpenDataChannel:(RTCDataChannel *)dataChannel
{
    // do nothing
}



@end






