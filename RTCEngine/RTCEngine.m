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

#import "RTCEngine+Internal.h"
#import "RTCMediaConstraintUtil.h"
#import "RTCSessionDescription+JSON.h"
#import "RTCStream+Internal.h"
#import "RTCNetUtils.h"
#import "RTCPeer.h"
#import "RTCPeerManager.h"

static RTCEngine *sharedRTCEngineInstance = nil;


@interface RTCEngine () <RTCPeerConnectionDelegate>
{
    NSString    *roomId;
    NSString    *localUserId;
    RTCDefaultVideoDecoderFactory* decoderFactory;
    RTCDefaultVideoEncoderFactory* encoderFactory;
    RTCPeerManager* peerManager;
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
        
        decoderFactory = [[RTCDefaultVideoDecoderFactory alloc] init];
        encoderFactory = [[RTCDefaultVideoEncoderFactory alloc] init];
        peerManager = [[RTCPeerManager alloc] init];
        
        _connectionFactory = [[RTCPeerConnectionFactory alloc] initWithEncoderFactory:encoderFactory decoderFactory:decoderFactory];
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
        // just in case
        if (!sharedRTCEngineInstance.delegate) {
            sharedRTCEngineInstance.delegate = delegate;
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


-(void)removeStream:(RTCStream *)stream
{
    if (_status != RTCEngineStatusConnected) {
        return
    }
    
    if (![_localStreams objectForKey:stream.streamId]) {
        return;
    }
    
    [_localStreams removeObjectForKey:stream.streamId];
    
    if (!_peerconnection) {
        return;
    }
    
    if (stream.audioSender) {
        [_peerconnection removeTrack:stream.audioSender];
    }
    if (stream.videoSender){
        [_peerconnection removeTrack:stream.videoSender];
    }
    
    [self removeStreamInternal:stream];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate rtcengine:self didRemoveLocalStream:stream];
    });
}



-(void)generateTestToken:(NSString *)tokenUrl
               appsecret:(NSString *)appsecret
                    room:(NSString *)room
                  userId:(NSString *)userId
               withBlock:(void (^)(NSString *, NSError *))tokenBlock
{
    NSDictionary *params = @{
                             @"secret":appsecret,
                             @"room":room,
                             @"user":userId};
    
    void (^tokenBlockCopy)(NSString*, NSError *) = tokenBlock;
    
    [RTCNetUtils postWithParams:params url:tokenUrl withBlock:^(NSString *token, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            tokenBlockCopy(token, error);
        });
    }];
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
    [_socket on:@"connect" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        [weakSelf join];
    }];
    
    
    [_socket on:@"error" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        
    }]
    
    [_socket on:@"disconnect" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        
    }]
    
    [_socket on:@"reconnect" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        
    }]
    
    [_socket on:@"joined" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        NSDictionary* _data = [data objectAtIndex:0];
        [weakSelf handleJoined:_data];
    }]
    
    [_socket on:@"offer" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        NSDictionary* _data = [data objectAtIndex:0];
        [weakSelf handleOffer:_data];
    }]
    
    [_socket on:@"answer" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        NSDictionary* _data = [data objectAtIndex:0];
        [weakSelf handleAnswer:_data];
    }]
    
    [_socket on:@"peerRemoved" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        
    }]
    
    [_socket on:@"peerConnected" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        
    }]
    
    [_socket on:@"streamAdded" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        
    }]
    
    [_socket on:@"configure" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        
    }]
    
    [_socket on:@"message" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        
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
    config.sdpSemantics = RTCSdpSemanticsUnifiedPlan;
    
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


- (void) handleJoined:(NSDictionary*) data
{
    
    NSArray* peers = [data valueForKeyPath:@"room.peers"];
    
    for(NSDictionary* peerDict in peers){
        [peerManager updatePeer:peerDict];
    }
    
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
    
    [self setStatus:RTCEngineStatusConnected];
    
}

- (void) handleOffer:(NSDictionary*)data
{
    NSArray* peers = [data valueForKeyPath:@"room.peers"];
    
    for(NSDictionary* peerDict in peers){
        [peerManager updatePeer:peerDict];
    }
    
    NSString* sdp = data[@"sdp"];
    
    RTCSessionDescription *offer = [RTCSessionDescription
                                     descriptionFromJSONDictionary:@{
                                                                     @"sdp":sdp,
                                                                     @"type":@"offer"}];
    
    [_peerconnection setRemoteDescription:offer completionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"error %@", error);
        }
        if (_peerconnection.signalingState == RTCSignalingStateStable) {
            return;
        }
        RTCMediaConstraints* constrainst = [RTCMediaConstraintUtil answerConstraints];
        [_peerconnection answerForConstraints:constrainst
                            completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
                                if (error) {
                                    NSLog(@"error %@", error);
                                }
                                
                                [_peerconnection setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
                                    if (error) {
                                        NSLog(@"error %@", error);
                                    }
                                }];
                            }]
    }];
}

-(void) handleAnswer:(NSDictionary*)data
{
    NSArray* peers = [data valueForKeyPath:@"room.peers"];
    
    for(NSDictionary* peerDict in peers){
        [peerManager updatePeer:peerDict];
    }
    
    NSString* sdp = data[@"sdp"];
    
    RTCSessionDescription *answer = [RTCSessionDescription
                                     descriptionFromJSONDictionary:@{
                                                                     @"sdp":sdp,
                                                                     @"type":@"answer"}];
    
    [_peerconnection setRemoteDescription:answer completionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"error %@", error);
        }
    }];
}

-(void) handlePeerRemoved:(NSDictionary*)data
{
    NSString* peer = [data valueForKeyPath:@"peer.id"];
    
    if(!peer) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate rtcengine:self didLeave:peer];
    });
}

-(void) handlePeerConnected:(NSDictionary*)data
{
    NSString* peer = [data valueForKeyPath:@"peer.id"];
    
    if(!peer) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate rtcengine:self didJoined:peer];
    });
}

-(void) handleStreamAdded:(NSDictionary*)data
{
    NSString* msid = [data objectForKey:@"msid"];
    if(!msid){
        return;
    }
    RTCStream* stream = [_localStreams objectForKey:msid];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate rtcengine:self didAddLocalStream:stream];
    });
}


-(void) handleConfigure:(NSDictionary*)data
{
    
}


-(void) addStreamInternal:(RTCStream *)stream
{
    
    RTCMediaConstraints *offerConstraints = [RTCMediaConstraintUtil offerConstraints];
    [_peerconnection offerForConstraints:offerConstraints completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        if (error) {
            return;
        }
        [_peerconnection setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
            NSDictionary *data = @{
                                   @"stream":[stream dumps],
                                   @"sdp": [sdp sdp]
                                   }
            [_socket emit:@"addStream" with:@[data]];
        }]
    }]
}

-(void) removeStreamInternal:(RTCStream *)stream
{
    RTCMediaConstraints *offerConstraints = [RTCMediaConstraintUtil offerConstraints];
    [_peerconnection offerForConstraints:offerConstraints completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        if (error) {
            return;
        }
        [_peerconnection setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
            NSDictionary *data = @{
                                   @"stream":[stream dumps],
                                   @"sdp": [sdp sdp]
                                   }
            [_socket emit:@"removeStream" with:@[data]];
        }]
    }]
}


-(void) setStatus:(RTCEngineStatus)newStatus
{
    if (_status == newStatus) {
        return;
    }
    
    _status = newStatus;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate rtcengine:self didStateChange:_status];
    });
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

- (void)peerConnection:(RTCPeerConnection *)peerConnection
didStartReceivingOnTransceiver:(RTCRtpTransceiver *)transceiver
{
    
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
        didAddReceiver:(RTCRtpReceiver *)rtpReceiver
               streams:(NSArray<RTCMediaStream *> *)mediaStreams
{
    
}

@end






