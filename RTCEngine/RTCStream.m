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
#import "RTCEngine+Internal.h"
#import "RTCEngine.h"

@interface RTCStream() <RTCVideoFrameDelegate,RTCExternalCapturerConsumer,RTCVideoFilterOutputDelegate>
{
    NSString*  sessionPreset;
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
    
    NSOperationQueue*  operationQueue;
    
    RTCVideoFrameConsumer* videoFrameConsumer;
    RTCVideoFilterManager* filterManager;
    
    BOOL usingFrontCamera;
    
    void (^snapshotBlockCopy)(UIImage*);
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
    operationQueue = [[NSOperationQueue alloc] init];
    [operationQueue setMaxConcurrentOperationCount:1];
    usingFrontCamera = YES;
    [self setupVideoProfile:RTCEngine_VideoProfile_240P];
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
    if (_stream != nil) {
        return;
    }
    
    RTCPeerConnectionFactory* factory = [RTCEngine sharedInstance].connectionFactory;
    
    _stream = [factory mediaStreamWithStreamId:_streamId];
    
    videoFrameConsumer = [[RTCVideoFrameConsumer alloc] initWithDelegate:self];
    
    videoSource = [factory videoSource];
    
    // when we use external captuer
    if(_videoCaptuer != nil) {
        
        [_videoCaptuer setVideoConsumer:self];
        _videoTrack = [factory videoTrackWithSource:videoSource trackId:[[NSUUID UUID] UUIDString]];
        [_stream addVideoTrack:_videoTrack];
    } else if (_video) {
        // todo adapter
        //[videoSource adaptOutputFormatToWidth:<#(int)#> height:<#(int)#> fps:<#(int)#>];
        
        cameraCapturer = [[RTCCameraVideoCapturer alloc] initWithDelegate:videoFrameConsumer];
        _videoTrack = [factory videoTrackWithSource:videoSource trackId:[[NSUUID UUID] UUIDString]];
        [_stream addVideoTrack:_videoTrack];
        [self startCapture];
    }
    
    if (_audio) {
        RTCAudioSource* audioSource = [factory audioSourceWithConstraints:nil];
        _audioTrack = [factory audioTrackWithSource:audioSource trackId:[[NSUUID UUID] UUIDString]];
        
        [_stream addAudioTrack:_audioTrack];
    }
    
    if (_view != nil) {
        [_view setStream:self];
    }
}


-(void)shutdownLocalMedia
{
    
    [self close];
    
}


-(void)close
{
    [self stopCapture];
    
    if (_videoTrack ) {
        _videoTrack = nil;
    }
    
    if (_audioTrack) {
        _audioTrack = nil;
    }
    
    if (_stream) {
        _stream = nil;
    }
}


- (void) muteAudio:(BOOL)muted
{
    
}


-(void) muteVideo:(BOOL)muted
{
    
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
    if ([cameraCapturer isKindOfClass:[RTCCameraVideoCapturer class]]) {
        [self startCapture];
    }
}


-(void)snapshot:(void (^)(UIImage * _Nullable))snapshotBlock
{
    // todo
}

-(void)setMaxBitrate
{
    // todo
}

- (void)setMaxBitrate:(NSUInteger)maxBitrate forVideoSender:(RTCRtpSender *)sender {
    if (maxBitrate <= 0) {
        return;
    }
    
    RTCRtpParameters *parametersToModify = sender.parameters;
    for (RTCRtpEncodingParameters *encoding in parametersToModify.encodings) {
        encoding.maxBitrateBps = @(maxBitrate);
    }
    [sender setParameters:parametersToModify];
}



-(void)onMuteAudio:(BOOL)muted
{
    if (_delegate) {
        if ([_delegate respondsToSelector:@selector(stream:didMutedAudio:)]) {
            [_delegate stream:self didMutedAudio:muted];
        }
    }
}


-(void)onMuteVideo:(BOOL)muted
{
    if (_delegate) {
        if ([_delegate respondsToSelector:@selector(stream:didMutedVideo:)]) {
            [_delegate stream:self didMutedVideo:muted];
        }
    }
}



-(NSDictionary*)dumps
{
    return @{
             @"id":_peerId,
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
    
    if (_videoCaptuer != nil && videoSource != nil) {
        NSTimeInterval timeStampSeconds = CACurrentMediaTime();
        int64_t timeStampNs = lroundf(timeStampSeconds * NSEC_PER_SEC);
        
        RTCVideoFrame *videoFrame = [[RTCVideoFrame alloc] initWithPixelBuffer:pixelBuffer
                                                                      rotation:(int)rotation
                                                                   timeStampNs:timeStampNs];
        [videoSource capturer:NULL didCaptureVideoFrame:videoFrame];
        
    }
    
}


-(void)newFilterFrameAvailable:(CVPixelBufferRef)pixelBuffer
{
    if (_useFaceBeauty) {
        
        NSTimeInterval timeStampSeconds = CACurrentMediaTime();
        int64_t timeStampNs = lroundf(timeStampSeconds * NSEC_PER_SEC);
        
        RTCVideoFrame *videoFrame = [[RTCVideoFrame alloc] initWithPixelBuffer:pixelBuffer
                                                                      rotation:90
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
            filterManager = [[RTCVideoFilterManager alloc] initWithSize:CGSizeMake(cameraWidth, cameraHeight) delegate:self];
        }
        
        // todo
        if ([frame.buffer isKindOfClass:[RTCCVPixelBuffer class]]) {
            
        }
       
    } else {
        if(cameraCapturer != nil && videoSource != nil) {
              [videoSource capturer:cameraCapturer didCaptureVideoFrame:frame];
        }
    }
}

@end
