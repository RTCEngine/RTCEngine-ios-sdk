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

@interface RTCStream() <RTCVideoFrameDelegate,RTCPeerConnectionDelegate>
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

- (NSString*) peerConnectionState:(RTCPeerConnectionState)newState
{
    
    NSString* state;
    switch (newState) {
        case RTCPeerConnectionStateNew:
            state = @"RTCPeerConnectionStateNew";
            break;
        case RTCPeerConnectionStateConnecting:
            state = @"RTCPeerConnectionStateConnecting";
            break;
        case RTCPeerConnectionStateConnected:
            state = @"RTCPeerConnectionStateConnected";
            break;
        case RTCPeerConnectionStateDisconnected:
            state = @"RTCPeerConnectionStateDisconnected";
            break;
        case RTCPeerConnectionStateFailed:
            state = @"RTCPeerConnectionStateFailed";
            break;
        case RTCPeerConnectionStateClosed:
            state = @"RTCPeerConnectionStateClosed";
            break;
        default:
            state = @"";
            break;
    }
    return state;
}


#pragma peerconnection delegate





/** Called when the SignalingState changed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeSignalingState:(RTCSignalingState)stateChanged
{
    
}

/** Called when media is received on a new stream from remote peer. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didAddStream:(RTCMediaStream *)stream
{
    
    NSLog(@"peerConnection didAddStream");
}

/** Called when a remote peer closes a stream.
 *  This is not called when RTCSdpSemanticsUnifiedPlan is specified.
 */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didRemoveStream:(RTCMediaStream *)stream
{
    NSLog(@"peerConnection didRemoveStream");
}

/** Called when negotiation is needed, for example ICE has restarted. */
- (void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection
{
    NSLog(@"peerConnectionShouldNegotiate");
}

/** Called any time the IceConnectionState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceConnectionState:(RTCIceConnectionState)newState
{
    NSString* state = [self iceConnectionState:newState];
    
    NSLog(@"ice state %@", state);
    
}

/** Called any time the IceGatheringState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceGatheringState:(RTCIceGatheringState)newState
{
    
}

/** New ice candidate has been found. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didGenerateIceCandidate:(RTCIceCandidate *)candidate
{
    NSLog(@"IceCandidate %@", candidate.sdp);
    
}

/** Called when a group of local Ice candidates have been removed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didRemoveIceCandidates:(NSArray<RTCIceCandidate *> *)candidates
{
    
}

/** New data channel has been opened. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didOpenDataChannel:(RTCDataChannel *)dataChannel
{
}

/** Called when signaling indicates a transceiver will be receiving media from
 *  the remote endpoint.
 *  This is only called with RTCSdpSemanticsUnifiedPlan specified.
 */

/** Called any time the PeerConnectionState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeConnectionState:(RTCPeerConnectionState)newState
{
    
    NSString* state = [self peerConnectionState:newState];
    
    NSLog(@"peer connection state %@", state);
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
didStartReceivingOnTransceiver:(RTCRtpTransceiver *)transceiver
{
    
    NSLog(@"startReceiving %@", transceiver.receiver.receiverId);
}

/** Called when a receiver and its track are created. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
        didAddReceiver:(RTCRtpReceiver *)rtpReceiver
               streams:(NSArray<RTCMediaStream *> *)mediaStreams
{
    
    NSLog(@"AddReceiver %@", rtpReceiver.receiverId);
    
}

/** Called when the receiver and its track are removed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
     didRemoveReceiver:(RTCRtpReceiver *)rtpReceiver
{
    
    NSLog(@"RemoveReceiver %@", rtpReceiver.receiverId);
}

@end
