//
//  RTCEngine.h
//  RTCEngine
//
//  Created by xiang on 03/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for RTCEngine.
FOUNDATION_EXPORT double RTCEngineVersionNumber;

//! Project version string for RTCEngine.
FOUNDATION_EXPORT const unsigned char RTCEngineVersionString[];



@import WebRTC;

#import "RTCView.h"
#import "RTCStream.h"
#import "RTCVideoProfile.h"


typedef NS_ENUM(NSInteger, RTCEngineErrorCode) {
    RTCEngine_Error_NoError = 0,
    RTCEngine_Error_Failed = 1,
    RTCEngine_Error_InvalidArgument = 2,
    RTCEngine_Error_NotReady = 3,
    RTCEngine_Error_NotSupported = 4,
    RTCEngine_Error_Refused = 5,
    RTCEngine_Error_TokenExpire =  6,
    RTCEngine_Error_TokenError = 7,
    RTCEngine_Error_AccountDisableError = 8,
    RTCEngine_Error_MediaPermissionRefused = 9,
    RTCEngine_Error_ServerError = 10,
    RTCEngine_Error_RoomFullError = 11,
    
};



typedef NS_ENUM(NSUInteger,RTCEngineLogLevel){
    RTCEngine_Log_Verbose,
    RTCEngine_Log_Info,
    RTCEngine_Log_Warning,
    RTCEngine_Log_Error
};



typedef NS_ENUM(NSInteger,RTCEngineCaptureMode){
    
    RTCEngine_Capture_Default,
    RTCEngine_Capture_Custom_Video,
    RTCEngine_Capture_Custom_Video_Audio
};



typedef NS_ENUM(NSInteger, RTCEngineStatus) {
    RTCEngineStatusNew,
    RTCEngineStatusConnecting,
    RTCEngineStatusConnected,
    RTCEngineStatusDisConnected,
};


@interface RTCConfig : NSObject

@property(nonnull, strong) NSString*  signallingServer;
@property(nonnull, strong) NSString*  iceTransportPolicy;
@property(nonnull, strong) NSArray<RTCIceServer *>* iceServers;

@end



@protocol  RTCEngineDelegate;

@interface RTCEngine : NSObject


@property (nonatomic, weak) id<RTCEngineDelegate> _Nullable delegate;

@property (nonatomic, readonly) RTCEngineStatus status;


- (nonnull instancetype) initWichConfig:(RTCConfig*)config delegate:(id<RTCEngineDelegate>) delegate;

- (RTCStream*) createLocalStreamWithAudio:(BOOL)audio video:(BOOL)video;

- (void) publish:(RTCStream* _Nonnull) localStream;

- (void) unpublish:(RTCStream* _Nonnull) localStream;

- (void) subscribe:(RTCStream* _Nonnull) remoteStream;

- (void) unsubscribe:(RTCStream* _Nonnull) remoteStream;

- (void) joinRoom:(NSString* _Nonnull) roomId;

- (void) leaveRoom;

@end



@protocol RTCEngineDelegate <NSObject>


- (void) rtcengineDidJoined;

- (void) rtcengine:(RTCEngine* _Nonnull) engine  didStateChange:(RTCEngineStatus) state;

- (void) rtcengine:(RTCEngine* _Nonnull) engine  didLocalStreamPublished:(RTCStream *) stream;

- (void) rtcengine:(RTCEngine* _Nonnull) engine  didLocalStreamUnPublished:(RTCStream *) stream;


- (void) rtcengine:(RTCEngine* _Nonnull) engine  didStreamAdded:(RTCStream *) stream;

- (void) rtcengine:(RTCEngine* _Nonnull) engine  didStreamRemoved:(RTCStream *) stream;

- (void) rtcengine:(RTCEngine* _Nonnull) engine  didStreamSubscribed:(RTCStream *) stream;

- (void) rtcengine:(RTCEngine* _Nonnull) engine  didStreamUnsubscribed:(RTCStream *) stream;

- (void) rtcengine:(RTCEngine* _Nonnull) engine  didOccurError:(RTCEngineErrorCode) code;

- (void) rtcengine:(RTCEngine* _Nonnull) engine  didReceiveMessage:(NSDictionary*) message;

@end



