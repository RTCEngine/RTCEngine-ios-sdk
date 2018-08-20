//
//  CVPixelBufferResize.h
//  RTCEngine-ios-sdk
//
//  Created by xiang on 20/08/2018.
//  Copyright © 2018 RTCEngine. All rights reserved.
//

#import <Foundation/Foundation.h>

@import CoreImage;

@interface CVPixelBufferResize : NSObject

-(CVPixelBufferRef)processCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;
@end

