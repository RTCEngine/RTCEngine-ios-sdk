//
//  RTCStream+Internal.h
//  RTCEngine
//
//  Created by xiang on 06/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import "RTCStream.h"


@import WebRTC;

#import "RTCEngine.h"

@class RTCView;

@interface RTCStream() {
    
}



@property (nonatomic, strong) RTCAudioTrack* audioTrack;
@property (nonatomic, strong) RTCVideoTrack* videoTrack;


@property (nonatomic, strong) RTCRtpTransceiver* audioTransceiver;
@property (nonatomic, strong) RTCRtpTransceiver* videoTransceiver;
@property (nonatomic, strong) RTCPeerConnection* peerconnection;


@property(nonatomic, copy, readwrite) NSString* streamId;
@property(nonatomic, copy) NSString* publisherId;

@property (nonatomic,assign,readwrite) BOOL local;

@property (nonatomic,assign,readwrite) BOOL video;
@property (nonatomic,assign,readwrite) BOOL audio;
@property (nonatomic,retain,readwrite) RTCView* view;


@property (nonatomic,weak) RTCPeerConnectionFactory* factory;
@property (nonatomic,weak) RTCEngine* engine;


- (nonnull instancetype)initWithAudio:(BOOL)audio video:(BOOL)video;


- (void)onMuteAudio:(BOOL)muting;

- (void)onMuteVideo:(BOOL)muting;


- (void)close;

- (void)setMaxBitrate;

- (NSDictionary*)dumps;

@end

