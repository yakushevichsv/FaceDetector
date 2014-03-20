//
//  UIViewWithShakeDetect.m
//  FaceSpy
//
//  Created by Nguyen Thanh Hung on 10/11/13.
//  Copyright (c) 2013 SYCompany. All rights reserved.
//

#import "UIViewWithShakeDetect.h"

@implementation UIViewWithShakeDetect

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if ( event.subtype == UIEventSubtypeMotionShake )
    {
        if ([self.shakeDelegate respondsToSelector:@selector(viewWithShakeDetected)]) {
            [self.shakeDelegate viewWithShakeDetected];
        }
    }
    
    if ( [super respondsToSelector:@selector(motionEnded:withEvent:)] )
        [super motionEnded:motion withEvent:event];
}

- (BOOL)canBecomeFirstResponder
{ return YES; }

@end
