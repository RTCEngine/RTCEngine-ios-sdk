//
//  ViewController.m
//  RTCEngine-ios-sdk
//
//  Created by xiang on 03/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import "ViewController.h"

@import AVFoundation;
@import ReplayKit;

#import "UIView+Toast.h"

#import "RTCEngine.h"
#import "RTCStream.h"
#import "RTCView.h"



#import "CVPixelBufferResize.h"



static NSString* SignallingsServer = @"http://192.168.202.208:3888/";

static NSString* ROOM = @"tes_troom";


@interface ViewController () <RTCEngineDelegate, RTCStreamDelegate>
{
    
    BOOL connected;
    NSString* joinToken;

    UIView*  cameraPreview;
    
    BOOL   audioEable;
    BOOL   videoEable;
    
    BOOL process;
    NSDate* lastDate;
    CVPixelBufferResize* resize;
}


@property (weak, nonatomic) IBOutlet UILabel *userLabel;

@property (weak, nonatomic) IBOutlet UIButton *joinButton;
@property (weak, nonatomic) IBOutlet UIButton *audioMuteButton;
@property (weak, nonatomic) IBOutlet UIButton *videoMuteButton;
@property (weak, nonatomic) IBOutlet UIButton *switchCamButton;


@property (nonatomic, strong) RTCEngine* rtcEngine;
@property (nonatomic, strong) RTCStream* localStream;

@property (nonatomic,strong) NSString *userId;
@property (nonatomic,strong) NSString *room;

@property (nonatomic,strong) NSMutableArray  *publishers;

@property (nonatomic,strong) NSMutableDictionary *remoteVideoViews;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    RTCConfig* config = [[RTCConfig alloc] init];
    config.signallingServer = SignallingsServer;
    
    _rtcEngine = [[RTCEngine alloc] initWichConfig:config delegate:self];
    
    
    _localStream = [_rtcEngine createLocalStreamWithAudio:TRUE video:TRUE];
    _localStream.delegate = self;
    
    
    resize = [[CVPixelBufferResize alloc] init];
    
    connected = FALSE;
    audioEable = TRUE;
    videoEable = TRUE;
    
    self.room = ROOM;
    
    
    [_localStream setupLocalMedia];
    
    _localStream.view.frame = CGRectMake(0, 0, self.view.bounds.size.width/2, self.view.bounds.size.width/2);
    
    [self.view addSubview:_localStream.view];
    
    [self hideMenuButtons];
    
     _remoteVideoViews = [NSMutableDictionary dictionary];
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(BOOL)prefersStatusBarHidden{
    return NO;
}

-(void) hideMenuButtons
{
    self.audioMuteButton.hidden = YES;
    self.videoMuteButton.hidden = YES;
    self.switchCamButton.hidden = YES;
}


-(void)showMenuButtons
{
    self.audioMuteButton.hidden = NO;
    self.videoMuteButton.hidden = NO;
    self.switchCamButton.hidden = NO;
}


#pragma UI EVENT

- (IBAction)joinClick:(id)sender {
    
    if (!connected) {
        [sender setTitle:@"joining" forState:UIControlStateNormal];
        [self joinRoom];
    } else {
        
        [self leaveRoom];
    }
    
    self.joinButton.enabled = false;
}



- (IBAction)audioToggle:(id)sender {
    
}

- (IBAction)videoToggle:(id)sender {
    
}

- (IBAction)cameraSwitch:(id)sender {
    
    if (_localStream) {
        [_localStream switchCamera];
    }
}


-(void)leaveRoom
{
    
    if (_localStream) {
        [_rtcEngine unpublish:_localStream];
    }
    [_rtcEngine leaveRoom];
    [_remoteVideoViews removeAllObjects];
    
    [_joinButton setTitle:@"leave" forState:UIControlStateNormal];
    
    _joinButton.enabled = NO;
}

-(void)joinRoom
{
    
    [_rtcEngine joinRoom:ROOM];
}


-(void)viewWillLayoutSubviews
{
    
    [super viewWillLayoutSubviews];
    
    [self layoutVideoViews];
}


-(void)layoutVideoViews
{
    
    NSMutableArray *videoViews = [NSMutableArray array];
    
    if (self.localStream) {
        [videoViews addObject:self.localStream.view];
    }
    
    [videoViews addObjectsFromArray:[self.remoteVideoViews allValues]];
    
    if (videoViews.count == 1) {
        
        ((RTCView*)videoViews[0]).frame = CGRectMake(0, 0, self.view.bounds.size.width/2, self.view.bounds.size.width/2);
        return;
    }
    
    for (int i=0; i < [videoViews count]; i++) {
        
        CGRect frame = [self frameAtPosition:i];
        
        ((UIView*)videoViews[i]).frame = frame;
    }
}



-(CGRect)frameAtPosition:(int)postion
{
    
    CGRect bounds = self.view.bounds;
    
    CGFloat width = bounds.size.width / 2;
    CGFloat height = bounds.size.width / 2;
    
    CGFloat x = (postion%2) * width;
    CGFloat y = (postion/2) * height;
    
    CGRect frame = CGRectMake(x, y, width, height);
    
    return frame;
}





#pragma delegate


-(void) rtcengine:(RTCEngine* _Nonnull) engine  didAddRemoteStream:(RTCStream *) stream
{
    [stream setDelegate:self];
    
    UIView* view = stream.view;
    
    [self.view addSubview:view];
    
    [self.remoteVideoViews setObject:view forKey:stream.streamId];
    
    [self.view setNeedsLayout];
    
    NSLog(@"attributes %@", stream.attributes);
}

-(void) rtcengine:(RTCEngine* _Nonnull) engine  didRemoveRemoteStream:(RTCStream *) stream
{
    
    if ([_remoteVideoViews objectForKey:stream.streamId]) {
        
        UIView* view = stream.view;
        
        [view removeFromSuperview];
        
        [_remoteVideoViews removeObjectForKey:stream.streamId];
        
        [self.view setNeedsLayout];
    }
}



- (void) rtcengineDidJoined
{
    
}

- (void) rtcengine:(RTCEngine* _Nonnull) engine  didStateChange:(RTCEngineStatus) state
{
    NSLog(@"stateChange %ld", state);
    
    if (state == RTCEngineStatusConnected) {
        [self.joinButton setTitle:@"leave" forState:UIControlStateNormal];
        // here, we add Stream
        self.joinButton.enabled = TRUE;
        connected = TRUE;
        
        [self.rtcEngine publish:self.localStream];
    }
    
    if (state == RTCEngineStatusDisConnected) {
        self.joinButton.enabled = TRUE;
        connected = FALSE;
    }
}

- (void) rtcengine:(RTCEngine* _Nonnull) engine  didLocalStreamPublished:(RTCStream *) stream
{
    
    NSLog(@"Local stream published %@", stream.streamId);
}

- (void) rtcengine:(RTCEngine* _Nonnull) engine  didLocalStreamUnPublished:(RTCStream *) stream
{
    NSLog(@"Local stream unpublished %@", stream.streamId);
}

- (void) rtcengine:(RTCEngine* _Nonnull) engine  didStreamPublished:(NSString *) streamId
{
    NSLog(@"Remote stream published %@", streamId);
    [_rtcEngine subscribe:streamId];
    
}

- (void) rtcengine:(RTCEngine* _Nonnull) engine  didStreamUnpublished:(NSString *) streamId
{
    
    NSLog(@"Remote stream unpublished %@", streamId);
    [_rtcEngine unpublish:streamId];
}



- (void) rtcengine:(RTCEngine* _Nonnull) engine  didStreamSubscribed:(RTCStream *) stream
{
    
    [stream setDelegate:self];
    
    UIView* view = stream.view;
    
    [self.view addSubview:view];
    
    [self.remoteVideoViews setObject:view forKey:stream.streamId];
    
    [self.view setNeedsLayout];
    
}

- (void) rtcengine:(RTCEngine* _Nonnull) engine  didStreamUnsubscribed:(RTCStream *) stream
{
    
    if ([_remoteVideoViews objectForKey:stream.streamId]) {
        
        UIView* view = stream.view;
        
        [view removeFromSuperview];
        
        [_remoteVideoViews removeObjectForKey:stream.streamId];
        
        [self.view setNeedsLayout];
    }
}

- (void) rtcengine:(RTCEngine* _Nonnull) engine  didOccurError:(RTCEngineErrorCode) code
{
    NSLog(@"didOccurError");
}

- (void) rtcengine:(RTCEngine* _Nonnull) engine  didReceiveMessage:(NSDictionary*) message
{
    
    NSLog(@"didReceiveMessage %@", message);
}


#pragma stream delegate


-(void)stream:(RTCStream* _Nullable)stream  didMutedVideo:(BOOL)muted
{
    NSLog(@"didMuteVideo");
}

-(void)stream:(RTCStream* _Nullable)stream  didMutedAudio:(BOOL)muted
{
    NSLog(@"didMutedAudio");
}


@end
