//
//  RTCEngine.m
//  RTCEngine
//
//  Created by xiang on 06/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import "RTCEngine.h"

@import WebRTC;


static RTCEngine *sharedRTCEngineInstance = nil;


@interface RTCEngine () <>
{
    NSString    *roomId;
    NSString    *localUserId;
}

@end

@implementation RTCEngine


-(instancetype) initWithDelegate:(id<RTCEngineDelegate>) delegate
{
    
    if (self = [super init]) {
        self.delegate = delegate;
        _status = RTCEngineStatusNew;
        RTCInitializeSSL();
        
        // TODO  init logger
    }
    
    return self;
}


+(instancetype) sharedInstanceWithDelegate:(id<RTCEngineDelegate>)delegate
{
    
    @synchronized(self) {
        if (!sharedRTCEngineInstance) {
            sharedRTCEngineInstance = [[self alloc] initWithDelegate: delegate];
        }
    }
    return  sharedRTCEngineInstance;
}


+(instancetype) sharedInstance
{
    @synchronized(self) {
        if (!sharedRTCEngineInstance) {
            sharedRTCEngineInstance = [[self alloc] initWithDelegate: nil];
        }
    }
    return  sharedRTCEngineInstance;
}


-(void)joinRoomWithToken:(NSString *)token
{
    
}

-(void) addStream:(RTCStream *)stream
{
    if (_status != RTCEngineStatusConnected) {
        return
    }
    
    
}






@end






