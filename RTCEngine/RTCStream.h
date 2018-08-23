//
//  RTCStream.h
//  RTCEngine
//
//  Created by xiang on 06/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RTCView.h"
#import "RTCEngine.h"
#import "RTCExternalCapturer.h"
#import "RTCVideoProfile.h"



@class RTCStream;
@class RTCVideoCapturer;

@protocol RTCStreamDelegate <NSObject>

-(void)stream:(RTCStream* _Nullable)stream  didMutedVideo:(BOOL)muted;

-(void)stream:(RTCStream* _Nullable)stream  didMutedAudio:(BOOL)muted;

@end

@interface RTCStream : NSObject

@property (nonatomic,readonly) BOOL local;
@property (nonatomic,readonly) BOOL audio;
@property (nonatomic,readonly) BOOL video;
@property (nonatomic,readonly) NSString* _Nonnull streamId;
@property (nonatomic,readonly) NSString* _Nullable peerId;
@property (nonatomic,readonly) RTCView* _Nullable view;

@property (nonatomic,assign) float beautyLevel;
@property (nonatomic,assign) float brightLevel;
@property (nonatomic,assign) BOOL useFaceBeauty;

@property (nonatomic,assign) NSDictionary* _Nonnull attributes;
@property (nonatomic,assign) RTCEngineVideoProfile  videoProfile;
@property (nonatomic,assign) RTCExternalCapturer* _Nullable videoCaptuer;
@property (nonatomic,weak) id<RTCStreamDelegate> _Nullable delegate;


-(nonnull instancetype)initWithAudio:(BOOL)audio video:(BOOL)video;

-(nonnull instancetype)initWithAudio:(BOOL)audio video:(BOOL)video delegate:(nullable id<RTCStreamDelegate>)delegate;

-(nonnull instancetype)initWithAudio:(BOOL)audio video:(BOOL)video videoProfile:(RTCEngineVideoProfile)profile delegate:(nullable id<RTCStreamDelegate> )delegate;

-(void)setupVideoProfile:(RTCEngineVideoProfile)profile;

-(void)setupLocalMedia;

-(void)shutdownLocalMedia;

-(void)switchCamera;

-(void)muteAudio:(BOOL)muted;

-(void)muteVideo:(BOOL)muted;

-(void)snapshot:(void (^_Nonnull)(UIImage* _Nullable image))snapshotBlock;


@end
