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
#import "RTCVideoCapturer.h"


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
    RTCEngineStatusConnecting,
    RTCEngineStatusConnected,
    RTCEngineStatusDisConnected,
};

@protocol  RTCEngineDelegate;

@interface RTCEngine : NSObject


@property (nonatomic, weak) id<RTCEngineDelegate> _Nullable delegate;

@property (nonatomic, readonly) RTCEngineStatus status;

+ (instancetype _Nonnull)sharedInstanceWithDelegate:(id<RTCEngineDelegate> _Nonnull)delegate;

+ (instancetype _Nonnull)sharedInstance;

-(void)addStream:(RTCStream* _Nonnull)stream;

-(void)removeStream:(RTCStream* _Nonnull)stream;

-(void)joinRoomWithToken:(NSString* _Nonnull)token;

-(void)leaveRoom;

-(void)enableSpeakerphone:(BOOL)enable;


-(void)generateToken:(NSString* _Nonnull)tokenUrl
               appkey:(NSString* _Nonnull )appkey
                    room:(NSString* _Nonnull )room
                  userId:(NSString* _Nonnull )userId
               withBlock:(void (^_Nonnull)(NSString* token,NSError* error))tokenBlock;

@end



@protocol RTCEngineDelegate <NSObject>

-(void) rtcengine:(RTCEngine* _Nonnull) engine didJoined:(NSString *) peerId;

-(void) rtcengine:(RTCEngine* _Nonnull) engine didLeave:(NSString *) peerId;

-(void) rtcengine:(RTCEngine* _Nonnull) engine  didStateChange:(RTCEngineStatus) state;

-(void) rtcengine:(RTCEngine* _Nonnull) engine  didAddLocalStream:(RTCStream *) stream;

-(void) rtcengine:(RTCEngine* _Nonnull) engine  didRemoveLocalStream:(RTCStream *) stream;

-(void) rtcengine:(RTCEngine* _Nonnull) engine  didAddRemoteStream:(RTCStream *) stream;

-(void) rtcengine:(RTCEngine* _Nonnull) engine  didRemoveRemoteStream:(RTCStream *) stream;

-(void) rtcengine:(RTCEngine* _Nonnull) engine  didOccurError:(RTCEngineErrorCode) code;

@end



