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

#import <SocketIO/SocketIO-Swift.h>

#import "RTCEngine+Internal.h"
#import "RTCMediaConstraintUtil.h"
#import "RTCSessionDescription+JSON.h"
#import "RTCStream.h"
#import "RTCStream+Internal.h"
#import "RTCNetUtils.h"
#import "RTCPeer.h"
#import "RTCPeerManager.h"

static RTCEngine *sharedRTCEngineInstance = nil;


@interface RTCEngine () <RTCPeerConnectionDelegate,RTCVideoCapturerDelegate>
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
        //_connectionFactory = [[RTCPeerConnectionFactory alloc] init];
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
    
    if (authToken == nil) {
        [self.delegate rtcengine:self didOccurError:RTCEngine_Error_TokenError];
        return;
    }
    
    if (_status == RTCEngineStatusConnected) {
        return;
    }
    
    roomId = authToken.room;
    localUserId = authToken.userid;
    _authToken = authToken;
    _iceServers = authToken.iceServers;
    
    [self setupSignlingClient];
}


- (void) addStream:(RTCStream *)stream
{
    if (_status != RTCEngineStatusConnected) {
        return;
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
                stream.videoSender = [_peerconnection addTrack:stream.videoTrack streamIds:@[stream.streamId]];
                NSLog(@"videosender %@",stream.videoSender);
            }
            if (stream.audioTrack) {
                stream.audioSender = [_peerconnection addTrack:stream.audioTrack streamIds:@[stream.streamId]];
                NSLog(@"audiosender %@", stream.audioSender);
            }
            
        }
        
        stream.peerId = _authToken.userid;
        stream.engine = self;
        [stream setMaxBitrate];

        
        [self addStreamInternal:stream];
    }];
    
    [_operationQueue addOperation:blockOP];
}


-(void)removeStream:(RTCStream *)stream
{
    if (_status != RTCEngineStatusConnected) {
        return;
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


-(void)leaveRoom
{
    
    [self sendLeave];
    [self close];
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
    _manager = [[SocketManager alloc] initWithSocketURL:url
                                                               config:@{
                                                                        @"compress": @YES,
                                                                        @"forceWebsockets":@YES,
                                                                        @"reconnectAttempts":@5,
                                                                        @"reconnectWait":@10000}];
    
    _socket = _manager.defaultSocket;
    __weak id weakSelf = self;
    [_socket on:@"connect" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        [weakSelf join];
    }];
    
    
    [_socket on:@"error" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        
    }];
    
    [_socket on:@"disconnect" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        
    }];
    
    [_socket on:@"reconnect" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        
    }];
    
    [_socket on:@"joined" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        NSDictionary* _data = [data objectAtIndex:0];
        [weakSelf handleJoined:_data];
    }];
    
    [_socket on:@"offer" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        NSDictionary* _data = [data objectAtIndex:0];
        [weakSelf handleOffer:_data];
    }];
    
    [_socket on:@"answer" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        NSDictionary* _data = [data objectAtIndex:0];
        [weakSelf handleAnswer:_data];
    }];
    
    [_socket on:@"peerRemoved" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        NSDictionary* _data = [data objectAtIndex:0];
        [weakSelf handlePeerRemoved:_data];
    }];
    
    [_socket on:@"peerConnected" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        NSDictionary* _data = [data objectAtIndex:0];
        [weakSelf handlePeerConnected:_data];
    }];
    
    [_socket on:@"streamAdded" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        NSDictionary* _data = [data objectAtIndex:0];
        [weakSelf handleStreamAdded:_data];
    }];
    
    [_socket on:@"configure" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        NSDictionary* _data = [data objectAtIndex:0];
        [weakSelf handleConfigure:_data];
    }];
    
    [_socket on:@"message" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        NSDictionary* _data = [data objectAtIndex:0];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate rtcengine:self didReceiveMessage:_data];
        });
    }];
    
    [_socket connect];
}


-(void) join
{
    BOOL planb = TRUE;
    RTCConfiguration *config = [[RTCConfiguration alloc] init];
    config.iceServers = @[];
    config.bundlePolicy = RTCBundlePolicyMaxBundle;
    config.rtcpMuxPolicy = RTCRtcpMuxPolicyRequire;
    config.iceTransportPolicy = RTCIceTransportPolicyAll;
    config.sdpSemantics = RTCSdpSemanticsPlanB;
    
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
        
        NSLog(@"offer %@", sdp.sdp);
        
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
        }];
        
    }];
    
    _peerconnection = peerconnection;
}


- (void) sendLeave
{
    
    NSDictionary *data = @{};
    [_socket emit:@"leave" with:@[data]];
}


- (void) sendConfigure:(NSDictionary *)data
{
    [_socket emit:"configure" with:@[data]];
}


- (void) close
{
    
    if (_closed) {
        return;
    }
    
    _closed = true;
    
    [_socket disconnect];
    
    for (RTCStream* stream in [_localStreams allValues]) {
        
        if (stream.stream) {
            [_peerconnection removeStream:stream.stream];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate rtcengine:self didRemoveLocalStream:stream];
            });
        }
        
        // todo  use new api
    }
    
    for (RTCStream* stream in [_remoteStreams allValues]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate rtcengine:self didRemoveRemoteStream:stream];
        });
        
        [stream close];
    }
    
    [_remoteStreams removeAllObjects];
    [_localStreams removeAllObjects];
    
    [peerManager clearAll];
    
    if (_peerconnection != nil) {
        [_peerconnection close];
        _peerconnection = nil;
    }
    
    // do we need release factory ?
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
            NSLog(@"setRemoteDescription: %@", error.description);
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
        if (self->_peerconnection.signalingState == RTCSignalingStateStable) {
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
                            }];
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
    
    
    NSLog(@"answer %@\n", answer.sdp);
    
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
    RTCStream* localStream = [_localStreams objectForKey:msid];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate rtcengine:self didAddLocalStream:localStream];
    });
}


-(void) handleConfigure:(NSDictionary*)data
{
    NSString* msid = [data objectForKey:@"msid"];
    if(!msid){
        return;
    }
    
    RTCStream* remoteStream = [_remoteStreams objectForKey:msid];
    
    if(!remoteStream) {
        return;
    }
    
    if([data objectForKey:@"video"]){
        BOOL muted = ![[data objectForKey:@"video"] boolValue];
        [remoteStream onMuteVideo:muted];
    }
    
    if([data objectForKey:@"audio"]) {
        BOOL muted = ![[data objectForKey:@"audio"] boolValue];
        [remoteStream onMuteAudio:muted];
    }
}


-(void) addStreamInternal:(RTCStream *)stream
{
    
    RTCMediaConstraints *offerConstraints = [RTCMediaConstraintUtil offerConstraints];
    [_peerconnection offerForConstraints:offerConstraints completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        if (error) {
            return;
        }
        [self->_peerconnection setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
            
            NSLog(@"offer %@\n", sdp.sdp);
            
            NSDictionary *data = @{
                                   @"stream":[stream dumps],
                                   @"sdp": [sdp sdp]
                                   };
            [self->_socket emit:@"addStream" with:@[data]];
        }];
    }];
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
                                   };
            [_socket emit:@"removeStream" with:@[data]];
        }];
    }];
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


-(NSString*)iceConnectionState:(RTCIceConnectionState)newState
{
    
    NSString*  state;
    switch (newState) {
        case RTCIceConnectionStateNew:
            state = @"RTCIceConnectionStateNew";
            break;
        case RTCIceConnectionStateCompleted:
            state = @"RTCIceConnectionStateCompleted";
            break;
        case RTCIceConnectionStateChecking:
            state = @"RTCIceConnectionStateChecking";
            break;
        case RTCIceConnectionStateConnected:
            state = @"RTCIceConnectionStateConnected";
            break;
        case RTCIceConnectionStateClosed:
            state = @"RTCIceConnectionStateClosed";
            break;
        case RTCIceConnectionStateFailed:
            state = @"RTCIceConnectionStateFailed";
            break;
        case RTCIceConnectionStateDisconnected:
            state = @"RTCIceConnectionStateDisconnected";
            break;
        default:
            state = @"";
            break;
    }
    return state;
}


#pragma mark - delegate


- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeSignalingState:(RTCSignalingState)stateChanged
{
     NSLog(@"didChangeSignalingState %ld", stateChanged);
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didAddStream:(RTCMediaStream *)stream
{
    
    RTCPeer* peer = [peerManager peerForStream:stream.streamId];
    if(!peer) {
        NSLog(@"can not find stream %@", stream.streamId);
        return;
    }
    
    BOOL audio = stream.audioTracks.count > 0;
    BOOL video = stream.videoTracks.count > 0;
    
    RTCStream* rtcStream = [[RTCStream alloc] init];
    rtcStream.audio = audio;
    rtcStream.video = video;
    rtcStream.stream = stream;
    rtcStream.streamId = stream.streamId;
    rtcStream.local = false;
    rtcStream.peerId = peer.peerid;
    rtcStream.engine = self;
    
    [_remoteStreams setObject:rtcStream forKey:rtcStream.streamId];
    
    for (NSDictionary* streamData in peer.streams){
        if([streamData[@"id"] isEqualToString:rtcStream.streamId]) {
            NSDictionary* attributes =streamData[@"attributes"];
            rtcStream.attributes = attributes;
        }
    }
    
    // init view here
    dispatch_async(dispatch_get_main_queue(), ^{
        RTCView* view = [[RTCView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        [view setStream:rtcStream];
        rtcStream.view = view;
        [self->_delegate rtcengine:self didAddRemoteStream:rtcStream];
    });
    
}


- (void)peerConnection:(RTCPeerConnection *)peerConnection didRemoveStream:(RTCMediaStream *)stream
{
    // remove remote stream
    
    RTCPeer* peer = [peerManager peerForStream:stream.streamId];
    if(!peer) {
        NSLog(@"can not find stream %@", stream.streamId);
        return;
    }
    
    RTCStream* remoteStream = [_remoteStreams objectForKey:stream.streamId];
    
    if(!remoteStream){
        return;
    }
    
    [_remoteStreams removeObjectForKey:stream.streamId];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate rtcengine:self didRemoveRemoteStream:remoteStream];
    });
}

/** Called when negotiation is needed, for example ICE has restarted. */
- (void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection
{
    NSLog(@"peerConnectionShouldNegotiate");
}


- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceConnectionState:(RTCIceConnectionState)newState
{
    NSLog(@"IceConnectionState %@", [self iceConnectionState:newState]);
    
    switch (newState) {
        case RTCIceConnectionStateNew:
        case RTCIceConnectionStateChecking:
            break;
        case RTCIceConnectionStateCompleted:
            break;
        case RTCIceConnectionStateConnected:
            _iceConnected = true;
            break;
        case RTCIceConnectionStateClosed:
        case RTCIceConnectionStateFailed:
        case RTCIceConnectionStateDisconnected:
            _iceConnected = false;
            //[self close:false];
            break;
        default:
            break;
    }
}

/** Called any time the IceGatheringState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceGatheringState:(RTCIceGatheringState)newState
{
    // do nothing
    NSLog(@"didChangeIceGatheringState %ld", newState);
}


- (void)peerConnection:(RTCPeerConnection *)peerConnection
didGenerateIceCandidate:(RTCIceCandidate *)candidate
{
    NSLog(@"didGenerateIceCandidate  %@", candidate.sdp);
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
    NSLog(@"didStartReceivingOnTransceiver");
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
        didAddReceiver:(RTCRtpReceiver *)rtpReceiver
               streams:(NSArray<RTCMediaStream *> *)mediaStreams
{
    NSLog(@"didAddReceiver %@", rtpReceiver.receiverId);
}



@end






