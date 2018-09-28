//
//  RTCIceServer+JSON.m
//  RTCEngine
//
//  Created by xiang on 06/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import "RTCIceServer+JSON.h"

@implementation RTCIceServer (JSON)


static NSString const *kRTCICEServerUsernameKey = @"username";
static NSString const *kRTCICEServerUrlsKey = @"urls";
static NSString const *kRTCICEServerCredentialKey = @"credential";


+ (RTCIceServer *)serverFromJSONDictionary:(NSDictionary *)dictionary {
    NSArray<NSString *> *urls = dictionary[kRTCICEServerUrlsKey];
    NSString *username = dictionary[kRTCICEServerUsernameKey];
    NSString *credential = dictionary[kRTCICEServerCredentialKey];
    username = username ? username : @"";
    credential = credential ? credential : @"";
    return [[RTCIceServer alloc] initWithURLStrings:urls
                                           username:username
                                         credential:credential];
}

@end
