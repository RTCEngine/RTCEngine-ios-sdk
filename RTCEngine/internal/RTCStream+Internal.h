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

@property(nonatomic, strong) RTCMediaStream* stream;

@property (nonatomic, strong) RTCAudioTrack* audioTrack;
@property (nonatomic, strong) RTCVideoTrack* videoTrack;

@property (nonatomic, strong) RTCRtpSender* audioSender;
@property (nonatomic, strong) RTCRtpSender* videoSender;

@property(nonatomic, copy, readwrite) NSString* peerId;
@property(nonatomic, copy, readwrite) NSString* streamId;

@property (nonatomic,assign,readwrite) BOOL local;
@property (nonatomic,assign,readwrite) BOOL video;
@property (nonatomic,assign,readwrite) BOOL audio;
@property (nonatomic,retain,readwrite) RTCView* view;


@property (nonatomic,weak) RTCPeerConnection* peerconnection;
@property (nonatomic,weak) RTCEngine* engine;

-(void)onMuteAudio:(BOOL)muted;

-(void)onMuteVideo:(BOOL)muted;


-(void)close;

-(void)setMaxBitrate;

-(NSDictionary*)dumps;

@end

