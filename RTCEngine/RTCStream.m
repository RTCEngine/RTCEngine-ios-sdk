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
#import "RTCVideoFilterManager.h"
#import "RTCVideoFrameConsumer.h"
#import "RTCEngine+Internal.h"
#import "RTCEngine.h"

@interface RTCStream() <RTCVideoFrameDelegate,RTCVideoFilterOutputDelegate,RTCPeerConnectionDelegate>
{
    NSInteger minWidth;
    NSInteger minHeight;
    NSInteger maxWidth;
    NSInteger maxHeight;
    NSInteger maxVideoBitrate;
    NSInteger frameRate;
    
    int cameraWidth;
    int cameraHeight;
    
    RTCCameraVideoCapturer* cameraCapturer;
    
    RTCVideoSource* videoSource;
    RTCAudioSource* audioSource;
    
    RTCVideoFrameConsumer* videoFrameConsumer;
    RTCVideoFilterManager* filterManager;
    
    BOOL usingFrontCamera;
    BOOL usingExternalVideo;
    
    
}


@end

@implementation RTCStream


-(instancetype)init
{
    self = [super init];
    
    return self;
}

-(instancetype) initWithAudio:(BOOL)audio video:(BOOL)video
{
    self = [self initWithAudio:audio video:video delegate:NULL];
    return self;
}

-(nonnull instancetype)initWithAudio:(BOOL)audio video:(BOOL)video  delegate:(id<RTCStreamDelegate>)delegate
{
    self = [super init];
    _local = true;
    _video = video;
    _audio = audio;
    _attributes = [NSDictionary dictionary];
    _streamId = [[NSUUID UUID] UUIDString];
    
    usingFrontCamera = YES;
    usingExternalVideo = NO;
    [self setupVideoProfile:RTCEngine_VideoProfile_240P];
    _view = [[RTCView alloc] initWithFrame:CGRectZero];
    return self;
}


-(NSString*)streamId
{
    return _streamId;
}


-(RTCView*)view
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

-(void)setAttributes:(NSDictionary *)attributes
{
    if (attributes == nil) {
        return;
    }
    _attributes = attributes;
}

-(void)setupVideoProfile:(RTCEngineVideoProfile)profile
{
    _videoProfile = profile;
    NSDictionary *info = [RTCVideoProfile infoForProfile:profile];
    minWidth = [[info objectForKey:@"minWidth"] integerValue];
    minHeight = [[info objectForKey:@"minHeight"] integerValue];
    frameRate = [[info objectForKey:@"frameRate"] integerValue];
    maxVideoBitrate = [[info objectForKey:@"maxVideoBitrate"] integerValue];
}


-(void) setupLocalMedia
{
    
    
    if (_video) {
        videoFrameConsumer = [[RTCVideoFrameConsumer alloc] initWithDelegate:self];
        videoSource = [_factory videoSource];
        _videoTrack = [_factory videoTrackWithSource:videoSource trackId:[[NSUUID UUID] UUIDString]];
        if (!usingExternalVideo) {
            cameraCapturer = [[RTCCameraVideoCapturer alloc] initWithDelegate:videoFrameConsumer];
            [self startCapture];
        }
        
        [_view setVideoTrack:_videoTrack];
    }
    
    if (_audio) {
        audioSource = [_factory audioSourceWithConstraints:nil];
        _audioTrack = [_factory audioTrackWithSource:audioSource trackId:[[NSUUID UUID] UUIDString]];
        NSLog(@"audio track %@", _audioTrack.trackId);
    }
    
}


-(void)shutdownLocalMedia
{
    
    if (_video) {
        if (!usingExternalVideo) {
            [self stopCapture];
        }
    }
}


- (void)useExternalVideoSource:(BOOL)external
{
    usingExternalVideo = external;
}

- (void)sendCVPixelBuffer:(CVPixelBufferRef)pixelBuffer rotation:(VideoRotation)rotation
{
    
    NSLog(@"sendCVPixelBuffer");
}

-(void)close
{
    
    if (cameraCapturer != nil) {
         [self stopCapture];
    }
    
    if (_videoTrack ) {
        _videoTrack = nil;
    }
    
    if (_audioTrack) {
        _audioTrack = nil;
    }
    
    if (_peerconnection != nil) {
        [_peerconnection close];
        _peerconnection = nil;
    }
}


- (void) muteAudio:(BOOL)muting
{
    
    if (_audioTrack) {
        
        if(_audioTrack.isEnabled == !muting) {
            return;
        }
        
        [_audioTrack setIsEnabled:!muting];
        
        if (_local) {
            
            if (_engine) {
                NSDictionary* data = @{};
                
                [_engine sendConfigure:data];
            }
        } else {
            if(_engine) {
                NSDictionary* data = @{
                                       };
                [_engine sendConfigure:data];
            }
        }
    }
}


-(void) muteVideo:(BOOL)muting
{
    
    if (_videoTrack) {
        
        if(_videoTrack.isEnabled == !muting){
            return;
        }
        
        [_videoTrack setIsEnabled:!muting];
        
        if (_local) {
            
            if (_engine) {
                NSDictionary* data = @{
                                       };
                [_engine sendConfigure:data];
            }
        } else {
            
            if (_engine) {
                NSDictionary* data = @{
                                       };
                [_engine sendConfigure:data];
            }
        }
    }
}



- (AVCaptureDevice *)findDeviceForPosition:(AVCaptureDevicePosition)position {
    NSArray<AVCaptureDevice *> *captureDevices = [RTCCameraVideoCapturer captureDevices];
    for (AVCaptureDevice *device in captureDevices) {
        if (device.position == position) {
            return device;
        }
    }
    return captureDevices[0];
}

- (AVCaptureDeviceFormat *)selectFormatForDevice:(AVCaptureDevice *)device {
    NSArray<AVCaptureDeviceFormat *> *formats = [RTCCameraVideoCapturer supportedFormatsForDevice:device];
    int targetWidth = (int)minWidth;
    int targetHeight = (int)minHeight;
    AVCaptureDeviceFormat *selectedFormat = nil;
    int currentDiff = INT_MAX;
    for (AVCaptureDeviceFormat *format in formats) {
        CMVideoDimensions dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
        int diff = abs(targetWidth - dimension.width) + abs(targetHeight - dimension.height);
        if (diff < currentDiff) {
            selectedFormat = format;
            currentDiff = diff;
        }
    }
    NSAssert(selectedFormat != nil, @"No suitable capture format found.");
    CMVideoDimensions dimension = CMVideoFormatDescriptionGetDimensions(selectedFormat.formatDescription);
    cameraWidth = dimension.width;
    cameraHeight = dimension.height;
    return selectedFormat;
}


-(void)startCapture
{
    AVCaptureDevicePosition position =
    usingFrontCamera ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    AVCaptureDevice *device = [self findDeviceForPosition:position];
    AVCaptureDeviceFormat *format = [self selectFormatForDevice:device];
    [cameraCapturer startCaptureWithDevice:device format:format fps:frameRate];
}


-(void)stopCapture {
    [cameraCapturer stopCapture];
}

-(void)switchCamera
{
    
    usingFrontCamera = !usingFrontCamera;
    if (cameraCapturer != nil && [cameraCapturer isKindOfClass:[RTCCameraVideoCapturer class]]) {
        [self startCapture];
    }
}



-(void)setMaxBitrate
{
    // todo
}



-(void)onMuteAudio:(BOOL)muting
{
    if (_delegate) {
        if ([_delegate respondsToSelector:@selector(stream:didMutedAudio:)]) {
            [_delegate stream:self didMutedAudio:muting];
        }
    }
}


-(void)onMuteVideo:(BOOL)muting
{
    if (_delegate) {
        if ([_delegate respondsToSelector:@selector(stream:didMutedVideo:)]) {
            [_delegate stream:self didMutedVideo:muting];
        }
    }
}



-(NSDictionary*)dumps
{
    return @{
             @"msid":_streamId,
             @"local":@(_local),
             @"bitrate":@(maxVideoBitrate),
             @"attributes":_attributes
             };
}

#pragma delegate


-(void) gotExternalCVPixelBuffer:(CVPixelBufferRef _Nonnull) pixelBuffer
                rotation:(VideoRotation)rotation
{
    
//    if (_videoCaptuer != nil && videoSource != nil) {
//        NSTimeInterval timeStampSeconds = CACurrentMediaTime();
//        int64_t timeStampNs = lroundf(timeStampSeconds * NSEC_PER_SEC);
//        
//        RTCCVPixelBuffer *rtcPixelBuffer = [[RTCCVPixelBuffer alloc] initWithPixelBuffer:pixelBuffer];
//
//        RTCVideoFrame *videoFrame = [[RTCVideoFrame alloc] initWithBuffer:rtcPixelBuffer
//                                                                 rotation:(int)rotation
//                                                              timeStampNs:timeStampNs];
//
//        [videoSource capturer:NULL didCaptureVideoFrame:videoFrame];
//
//    }
    
}


-(void)newFilterFrameAvailable:(CVPixelBufferRef)pixelBuffer rotation:(RTCVideoRotation)rotation
{
    if (_useFaceBeauty) {
        
        NSTimeInterval timeStampSeconds = CACurrentMediaTime();
        int64_t timeStampNs = lroundf(timeStampSeconds * NSEC_PER_SEC);
        
        RTCVideoFrame *videoFrame = [[RTCVideoFrame alloc] initWithPixelBuffer:pixelBuffer
                                                                      rotation:rotation
                                                                   timeStampNs:timeStampNs];
        
        if (cameraCapturer != nil && videoSource != nil) {
            [videoSource capturer:cameraCapturer didCaptureVideoFrame:videoFrame];
            
        }
    }
}


- (void)didGotVideoFrame:(RTCVideoFrame *)frame
{
    
    if(_useFaceBeauty) {
        if (filterManager == nil) {
            filterManager = [[RTCVideoFilterManager alloc] initWithSize:CGSizeMake(frame.width, frame.height) delegate:self];
        }
        
        // todo
        if ([frame.buffer isKindOfClass:[RTCCVPixelBuffer class]]) {
            RTCCVPixelBuffer* buffer = (RTCCVPixelBuffer*)frame.buffer;
            [filterManager processCVPixelBuffer:buffer.pixelBuffer rotation:frame.rotation];
        }
       
    } else {
        if(cameraCapturer != nil && videoSource != nil) {
            [videoSource capturer:cameraCapturer didCaptureVideoFrame:frame];
        }
    }
}

@end
