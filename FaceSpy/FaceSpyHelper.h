//
//  FaceSpyHelper.h
//  FaceSpy
//
//  Created by Nguyen Thanh Hung on 10/12/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Video.h"

#define kKeyVideoInfoDuration                   @"kKeyVideoInfoDuration"
#define kKeyVideoInfoSize                       @"kKeyVideoInfoSize"
#define kKeyVideoInfoNoFace                     @"kKeyVideoInfoNoFace"

@interface FaceSpyHelper : NSObject

+ (void)getInfoOfVideo:(Video *)video;

+ (NSString *)getDurationString:(NSInteger)duration;
+ (BOOL)checkImageIsBlack:(UIImage *)image;
+ (void)getThumbnailWithFirstFrameofVideo:(Video *)video;
@end
