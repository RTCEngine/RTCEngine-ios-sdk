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

static NSString*  APP_SECRET = @"test_secret";

static NSString* TOKEN_URL = @"http://192.168.203.213:3888/api/generateToken";

static NSString* ROOM = @"test";


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
    
    self.rtcEngine = [RTCEngine sharedInstanceWithDelegate:self];
    
    _localStream = [[RTCStream alloc] initWithAudio:TRUE video:TRUE delegate:self];
    
    resize = [[CVPixelBufferResize alloc] init];
    
    connected = FALSE;
    audioEable = TRUE;
    videoEable = TRUE;
    
    uint32_t randomNum = arc4random_uniform(10000);
    self.userId = [NSString stringWithFormat:@"ios%d",randomNum];
    self.room = ROOM;
    
    [_userLabel setText:self.userId];
    
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
    
    [_rtcEngine leaveRoom];
    [_remoteVideoViews removeAllObjects];
    
    [_joinButton setTitle:@"leave" forState:UIControlStateNormal];
    
    _joinButton.enabled = NO;
}

-(void)joinRoom
{
    
    [self.rtcEngine generateTestToken:TOKEN_URL appsecret:APP_SECRET room:ROOM userId:_userId withBlock:^(NSString *token, NSError *error) {
        
        if (error) {
            [self.joinButton setTitle:@"join" forState:UIControlStateNormal];
            
            self.joinButton.enabled = TRUE;
            
            [self.view makeToast:@"can not get token"];
            
            return;
        }
        
        joinToken = token;
        
        [_rtcEngine joinRoomWithToken:joinToken];
    }];
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


-(void) rtcengine:(RTCEngine* _Nonnull) engine didJoined:(NSString *) peerId
{
    NSLog(@"joined %@", peerId);
}

-(void) rtcengine:(RTCEngine* _Nonnull) engine didLeave:(NSString *) peerId
{
    NSLog(@"leave %@", peerId);
}

-(void) rtcengine:(RTCEngine* _Nonnull) engine  didStateChange:(RTCEngineStatus) state
{
    NSLog(@"stateChange %ld", state);
    
    if (state == RTCEngineStatusConnected) {
        [self.joinButton setTitle:@"leave" forState:UIControlStateNormal];
    }
}

-(void) rtcengine:(RTCEngine* _Nonnull) engine  didAddLocalStream:(RTCStream *) stream
{
    NSLog(@"addLocalStream %@", stream.streamId);
}

-(void) rtcengine:(RTCEngine* _Nonnull) engine  didRemoveLocalStream:(RTCStream *) stream
{
    NSLog(@"RemoveLocalStream %@", stream.streamId);
}

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

-(void) rtcengine:(RTCEngine* _Nonnull) engine  didOccurError:(RTCEngineErrorCode) code
{
    NSLog(@"occurError %ld", code);
}

-(void) rtcengine:(RTCEngine* _Nonnull) engine  didReceiveMessage:(NSDictionary*) message
{
    NSLog(@"receiveMessage %@", message);
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
