//
//  RTCEngine+Internal.h
//  RTCEngine
//
//  Created by xiang on 08/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

@import WebRTC;
@import SocketIO;

//#import <SocketIO/SocketIO-Swift.h>

@interface RTCEngine () {
    
}

@property (nonatomic, strong) SocketManager* manager;
@property (nonatomic, strong) SocketIOClient *socket;
@property (nonatomic, strong) RTCPeerConnectionFactory *connectionFactory;


@end

