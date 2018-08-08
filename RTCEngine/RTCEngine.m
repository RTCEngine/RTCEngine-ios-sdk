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
@import SocketIO;

#import <SocketIO/SocketIO-Swift.h>

#import "RTCMediaConstraintUtil.h"
#import "RTCSessionDescription+JSON.h"
#import "RTCStream+Internal.h"

static RTCEngine *sharedRTCEngineInstance = nil;


@interface RTCEngine () <RTCPeerConnectionDelegate>
{
    NSString    *roomId;
    NSString    *localUserId;
}

@property (nonatomic, strong) RTCVideoSource* videoSource;

@property (nonatomic, strong) NSMutableDictionary* localStreams;
@property (nonatomic, strong) NSMutableDictionary* remoteStreams;

@property (nonatomic, assign) NSUInteger retryCount;
@property (nonatomic, strong) RTCPeerConnection *peerconnection;
@property (nonatomic, strong) AuthToken*  authToken;
@property (nonatomic, strong) NSArray<RTCIceServer*> *iceServers;
@property (nonatomic)   BOOL   closed;
@property (nonatomic)  NSOperationQueue*  operationQueue;
@property (atomic)  BOOL iceConnected;

@property (nonatomic, strong) SocketIOClient *socket;
@property (nonatomic, strong) RTCPeerConnectionFactory *connectionFactory;

@end

@implementation RTCEngine


-(instancetype) initWithDelegate:(id<RTCEngineDelegate>) delegate
{
    
    if (self = [super init]) {
        _delegate = delegate;
        _status = RTCEngineStatusNew;
        
        RTCInitializeSSL();
        
        _localStreams = [NSMutableDictionary dictionary];
        _remoteStreams = [NSMutableDictionary dictionary];
        
        _operationQueue = [[NSOperationQueue alloc] init];
        [_operationQueue setMaxConcurrentOperationCount:1];
        
        _connectionFactory = [[RTCPeerConnectionFactory alloc] init];
        _iceConnected = false;
        _closed = false;
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
    _authToken = authToken;
    
    [self setupSignlingClient];
}

- (void) addStream:(RTCStream *)stream
{
    if (_status != RTCEngineStatusConnected) {
        return
    }
    
    if ([_localStreams objectForKey:stream.streamId]) {
        NSLog(@"stream already in");
        return;
    }
    
    NSBlockOperation *blockOP = [NSBlockOperation blockOperationWithBlock:^{
        
        [stream setupLocalMedia];
        
        [_localStreams setObject:stream forKey:stream.streamId];
        
        if (stream.stream != nil) {
            if (stream.videoTrack) {
                [_peerconnection addTrack:stream.videoTrack streamIds:@[stream.streamId]];
            }
            if (stream.audioTrack) {
                [_peerconnection addTrack:stream.audioTrack streamIds:@[stream.streamId]];
            }
        }
        
        stream.peerId = _authToken.userid;
        [stream setMaxBitrate];
        
        [self addStreamInternal:stream];
    }];
    
    [_operationQueue addOperation:blockOP];
}




#pragma mark - internal

- (void) setupSignlingClient
{
    
    NSURL* url = [[NSURL alloc] initWithString:_authToken.wsURL];
    SocketManager* manager = [[SocketManager alloc] initWithSocketURL:url
                                                               config:@{@"log": @YES,
                                                                        @"compress": @YES,
                                                                        @"forceWebsockets":@YES,
                                                                        @"reconnectAttempts":@5,
                                                                        @"reconnectWait":@10000}];
    
    _socket = manager.defaultSocket;
    __weak id weakSelf = self;
    [_socket on:@"connect" callback:^(NSArray * _Nonnull, SocketAckEmitter * _Nonnull) {
        [weakSelf join];
    }];
    
    
    [_socket on:@"error" callback:^(NSArray * _Nonnull, SocketAckEmitter * _Nonnull) {
        
    }]
    
    [_socket on:@"disconnect" callback:^(NSArray * _Nonnull, SocketAckEmitter * _Nonnull) {
        
    }]
    
    [_socket on:@"reconnect" callback:^(NSArray * _Nonnull, SocketAckEmitter * _Nonnull) {
        
    }]
    
    [_socket on:@"joined" callback:^(NSArray * _Nonnull, SocketAckEmitter * _Nonnull) {
        
    }]
    
    [_socket on:@"offer" callback:^(NSArray * _Nonnull, SocketAckEmitter * _Nonnull) {
        
    }]
    
    [_socket on:@"answer" callback:^(NSArray * _Nonnull, SocketAckEmitter * _Nonnull) {
        
    }]
    
    [_socket on:@"peerRemoved" callback:^(NSArray * _Nonnull, SocketAckEmitter * _Nonnull) {
        
    }]
    
    [_socket on:@"peerConnected" callback:^(NSArray * _Nonnull, SocketAckEmitter * _Nonnull) {
        
    }]
    
    [_socket on:@"streamAdded" callback:^(NSArray * _Nonnull, SocketAckEmitter * _Nonnull) {
        
    }]
    
    [_socket on:@"configure" callback:^(NSArray * _Nonnull, SocketAckEmitter * _Nonnull) {
        
    }]
    
    [_socket on:@"message" callback:^(NSArray * _Nonnull, SocketAckEmitter * _Nonnull) {
        
    }]
}


-(void) join
{
    BOOL planb = TRUE;
    RTCConfiguration *config = [[RTCConfiguration alloc] init];
    config.iceServers = @[];
    config.bundlePolicy = RTCBundlePolicyMaxBundle;
    config.rtcpMuxPolicy = RTCRtcpMuxPolicyRequire;
    config.iceTransportPolicy = RTCIceTransportPolicyAll;
    
    
    RTCMediaConstraints *connectionconstraints = [RTCMediaConstraintUtil connectionConstraints];
    RTCPeerConnection* peerconnection = [_connectionFactory peerConnectionWithConfiguration:config
                                                                                constraints:connectionconstraints
                                                                                   delegate:nil];
    
    peerconnection.delegate = self;
    RTCMediaConstraints *offerConstraints = [RTCMediaConstraintUtil offerConstraints];
    __weak id weakSelf = self;
    [peerconnection offerForConstraints:offerConstraints completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        
        if (error) {
            return;
        }
        
        [peerconnection setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
            NSDictionary *data = @{
                                   @"appkey":@"appkey",
                                   @"room":_authToken.room,
                                   @"user":_authToken.userid,
                                   @"token":_authToken.token,
                                   @"planb":@(planb),
                                   @"sdp":[sdp sdp]
                                   };
            
            [_socket emit:@"join" with:@[data]];
        }]
        
    }];
    
    _peerconnection = peerconnection;
}


- (void) handleJoined:(NSDictionary* data)
{
    
    // todo handle peers
    NSString* sdp = data[@"sdp"];
    
    RTCSessionDescription *answer = [RTCSessionDescription
                                     descriptionFromJSONDictionary:@{
                                                                     @"sdp":sdp,
                                                                     @"type":@"answer"}];
    __weak id weakSelf = self;
    
    [_peerconnection setRemoteDescription:answer completionHandler:^(NSError * _Nullable error) {
        if (error) {
            return;
        }
    }];
    
    // todo change the state
}

-(void) addStreamInternal:(RTCStream *)stream
{
    
}

-(void) removeStreamInternal:(RTCStream *)stream
{
    
}

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






