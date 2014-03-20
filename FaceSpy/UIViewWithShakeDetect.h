//
//  UIViewWithShakeDetect.h
//  FaceSpy
//
//  Created by Nguyen Thanh Hung on 10/11/13.
//  Copyright (c) 2013 SYCompany. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UIViewWithShakeDetectDelegate;

@interface UIViewWithShakeDetect : UIView
@property (weak, nonatomic) IBOutlet id<UIViewWithShakeDetectDelegate> shakeDelegate;
@end

@protocol UIViewWithShakeDetectDelegate <NSObject>

- (void)viewWithShakeDetected;

@end
