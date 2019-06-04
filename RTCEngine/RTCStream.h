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
#import "RTCVideoProfile.h"


typedef NS_ENUM(NSInteger, VideoRotation){
    
    VideoRoation_0 = 0,
    VideoRoation_90 = 90,
    VideoRoation_180 = 180,
    VideoRoation_270 = 270,
};


@class RTCStream;
@class RTCVideoCapturer;

@protocol RTCStreamDelegate <NSObject>


-(void)stream:(RTCStream* _Nullable)stream  didMutedVideo:(BOOL)muted;
-(void)stream:(RTCStream* _Nullable)stream  didMutedAudio:(BOOL)muted;

@end

@interface RTCStream : NSObject

@property (nonatomic,readonly) BOOL local;
@property (nonatomic,readonly) NSString* _Nonnull streamId;
@property (nonatomic,readonly) RTCView* _Nullable view;

@property (nonatomic,assign) float beautyLevel;
@property (nonatomic,assign) float brightLevel;
@property (nonatomic,assign) BOOL useFaceBeauty;

@property (nonatomic,assign) NSDictionary* _Nonnull attributes;
@property (nonatomic,assign) RTCEngineVideoProfile  videoProfile;
@property (nonatomic,weak) id<RTCStreamDelegate> _Nullable delegate;


- (nonnull instancetype)initWithAudio:(BOOL)audio video:(BOOL)video;

- (nonnull instancetype)initWithAudio:(BOOL)audio video:(BOOL)video delegate:(nullable id<RTCStreamDelegate>)delegate;



- (void)setupVideoProfile:(RTCEngineVideoProfile)profile;

- (void)setupLocalMedia;
- (void)shutdownLocalMedia;

- (void)switchCamera;

- (void)muteAudio:(BOOL)muting;

- (void)muteVideo:(BOOL)muting;


- (void)useExternalVideoSource:(BOOL)external;

- (void)sendCVPixelBuffer:(CVPixelBufferRef _Nonnull)pixelBuffer rotation:(VideoRotation)rotation;


@end
