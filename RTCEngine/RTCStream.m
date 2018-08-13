//
//  RTCStream.m
//  RTCEngine
//
//  Created by xiang on 06/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import "RTCStream.h"


#import "RTCStream+Internal.h"
#import "RTCView+Internal.h"
#import "RTCExternalCapturer.h"
#import "RTCVideoFilterManager.h"
#import "RTCVideoFrameConsumer.h"

@interface RTCStream() <RTCVideoFrameDelegate,RTCExternalCapturerConsumer,RTCVideoFilterOutputDelegate>
{
    NSString*  sessionPreset;
    NSUInteger minWidth;
    NSUInteger minHeight;
    NSUInteger maxWidth;
    NSUInteger maxHeight;
    NSUInteger maxVideoBitrate;
    NSUInteger frameRate;
    
    int cameraWidth;
    int cameraHeight;
    
    RTCCameraVideoCapturer* cameraCapturer;
    RTCVideoSource* videoSource;
    
    NSOperationQueue*  operationQueue;
    
    RTCVideoFrameConsumer* videoFrameConsumer;
    RTCVideoFilterManager* filterNanager;
    
    BOOL usingFrontCamera;
    
    void (^snapshotBlockCopy)(UIImage*);
}


@property (nonatomic,strong) RTCVideoTrack*  videoTrack;
@property (nonatomic,strong) RTCAudioTrack*  audioTrack;

@end

@implementation RTCStream

-(instancetype) initWithAudio:(BOOL)audio video:(BOOL)video
{
    self = [self initWithAudio:audio video:video delegate:NULL];
    return self;
}

-(instancetype)initWithAudio:(BOOL)audio video:(BOOL)video delegate:(id<RTCStreamDelegate>)delegate
{
    
    self = [super init];
    _local = true;
    _video = video;
    _audio = audio;
    _streamId = [[NSUUID UUID] UUIDString];
    operationQueue = [[NSOperationQueue alloc] init];
    [operationQueue setMaxConcurrentOperationCount:1];
    usingFrontCamera = YES;
    
    [self setupVideoProfile:RTCEngine_VideoProfile_240P];
    _delegate = delegate;
    _view = [[RTCView alloc] initWithFrame:CGRectZero];
    return self;
}


-(NSString*)streamId
{
    return _streamId;
}


-(NSString*)peerId
{
    return _peerId;
}


-(DotView*)view
{
    return _view;
}



-(void)setUseFaceBeauty:(BOOL)useFaceBeauty
{
    _useFaceBeauty = useFaceBeauty;
}

-(void)setBeautyLevel:(float)beautyLevel
{
    if (beautyLevel < 0.0f || beautyLevel > 1.0f) {
        return;
    }
    _beautyLevel = beautyLevel;
}

-(void)setBrightLevel:(float)brightLevel
{
    if (brightLevel < 0.0f || brightLevel > 1.0f) {
        return;
    }
    _brightLevel = brightLevel;
}


-(void)setupVideoProfile:(RTCEngineVideoProfile)profile
{
    // todo
}


-(void) setupLocalMedia
{
    if (_stream != nil) {
        return;
    }
    
    
}


#pragma delegate


-(void) gotExternalCVPixelBuffer:(CVPixelBufferRef _Nonnull) sampleBuffer
                rotation:(VideoRotation)rotation
{
    
}


-(void)newFilterFrameAvailable:(CVPixelBufferRef)pixelBuffer
{
    
    
}


- (void)didGotVideoFrame:(RTCVideoFrame *)frame
{
    
}

@end
