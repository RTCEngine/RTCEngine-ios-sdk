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

#import "RTCEngine.h"
#import "RTCStream.h"
#import "RTCView.h"


#import "CVPixelBufferResize.h"


@interface ViewController () <RTCEngineDelegate, RTCStreamDelegate>
{
    
    
}


@property (weak, nonatomic) IBOutlet UILabel *userLabel;

@property (weak, nonatomic) IBOutlet UIButton *joinButton;
@property (weak, nonatomic) IBOutlet UIButton *audioMuteButton;
@property (weak, nonatomic) IBOutlet UIButton *videoMuteButton;
@property (weak, nonatomic) IBOutlet UIButton *switchCamButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma UI EVENT

- (IBAction)joinClick:(id)sender {
}



- (IBAction)audioToggle:(id)sender {
    
}

- (IBAction)videoToggle:(id)sender {
    
}

- (IBAction)cameraSwitch:(id)sender {
    
}


#pragma delegate


-(void) rtcengine:(RTCEngine* _Nonnull) engine didJoined:(NSString *) peerId
{
    
}

-(void) rtcengine:(RTCEngine* _Nonnull) engine didLeave:(NSString *) peerId
{
    
}

-(void) rtcengine:(RTCEngine* _Nonnull) engine  didStateChange:(RTCEngineStatus) state
{
    
}

-(void) rtcengine:(RTCEngine* _Nonnull) engine  didAddLocalStream:(RTCStream *) stream
{
    
}

-(void) rtcengine:(RTCEngine* _Nonnull) engine  didRemoveLocalStream:(RTCStream *) stream
{
    
}

-(void) rtcengine:(RTCEngine* _Nonnull) engine  didAddRemoteStream:(RTCStream *) stream
{
    
}

-(void) rtcengine:(RTCEngine* _Nonnull) engine  didRemoveRemoteStream:(RTCStream *) stream
{
    
}

-(void) rtcengine:(RTCEngine* _Nonnull) engine  didOccurError:(RTCEngineErrorCode) code
{
    
}

-(void) rtcengine:(RTCEngine* _Nonnull) engine  didReceiveMessage:(NSDictionary*) message
{
    
    
}


#pragma stream delegate


-(void)stream:(RTCStream* _Nullable)stream  didMutedVideo:(BOOL)muted
{
    
    
}

-(void)stream:(RTCStream* _Nullable)stream  didMutedAudio:(BOOL)muted
{
    
    
}


@end
