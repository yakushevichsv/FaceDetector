//
//  UICustomRecordButtonBase.h
//  FaceSpy
//
//  Created by Siarhei Yakushevich on 1/20/14.
//  Copyright (c) 2014 SY's PC. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface UICustomRecordButtonBase : UIButton

- (void)stopRecording;
- (void)record;
- (void)pause;
- (void)minimize;

@end
