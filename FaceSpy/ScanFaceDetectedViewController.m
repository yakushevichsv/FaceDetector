//
//  ScanFaceDetectedViewController.m
//  FaceSpy
//
//  Created by Nguyen Thanh Hung on 10/15/13.
//  Copyright (c) 2013 SYCompany. All rights reserved.
//

#import "ScanFaceDetectedViewController.h"

#import <QuartzCore/QuartzCore.h>
#define degreesToRadians(deg) (deg / 180.0 * M_PI)

@interface ScanFaceDetectedViewController ()

- (void)findImageMove;

@end

@implementation ScanFaceDetectedViewController

- (id)init{
    self = [super init];
    
    if (self) {
        
        [[NSBundle mainBundle] loadNibNamed:@"ScanFaceDetectedViewController" owner:self options:nil];
        
        CGRect bt1 = _cancelButton.frame;
        CGRect bt2 = _acceptButton.frame;
        
        [_cancelButton removeFromSuperview];
        _cancelButton = nil;
        [_acceptButton removeFromSuperview];
        _acceptButton = nil;
        
        _cancelButton = [UIButton buttonWithType:117];
        _cancelButton.frame = bt1;
        [_cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.alertView addSubview:_cancelButton];
        
        _acceptButton = [UIButton buttonWithType:115];
        _acceptButton.frame = bt2;
        [_acceptButton setTitle:@"Record" forState:UIControlStateNormal];
        [_acceptButton addTarget:self action:@selector(acceptAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.alertView addSubview:_acceptButton];
        
        self.findingView.layer.masksToBounds = YES;
        self.findingView.layer.cornerRadius = 8.0f;
        self.findingView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.5f];
        self.view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.2f];
    }
    
    return self;
}

- (IBAction)acceptAction:(id)sender {
    if ([_delegate respondsToSelector:@selector(scanFaceDetectedViewControllerDidSelectedAtIndex:)]) {
        [_delegate scanFaceDetectedViewControllerDidSelectedAtIndex:1];
    }
    
    [self dismissAlert];
}

- (IBAction)cancelAction:(id)sender {
    if ([_delegate respondsToSelector:@selector(scanFaceDetectedViewControllerDidSelectedAtIndex:)]) {
        [_delegate scanFaceDetectedViewControllerDidSelectedAtIndex:0];
    }
    [self dismissAlert];
}

static NSString *transKey = @"Transition";
- (void)showAlertFromView:(UIView *)fromView{
    [self removeFindingView];
    
    CGRect parentRect = fromView.bounds;
    
    self.view.frame = parentRect;
    [fromView addSubview:self.view];
    [_contentView addSubview:_alertView];
    
    CATransition *transition = [CATransition animation];
    [transition setType:kCATransitionReveal];
    [transition setDuration:0.5f];
    [transition setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [transition setSubtype:kCATransitionFromLeft];
    [_contentView.layer addAnimation:transition forKey:@"Transition"];
}

- (void)dismissAlert{
    CATransition *transition = [CATransition animation];
    [transition setType:kCATransitionFade];
    [transition setDuration:0.5f];
    [transition setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
//    [transition setSubtype:kCATransitionFromRight];
    [_contentView.layer addAnimation:transition forKey:@"Transition"];
    [self.alertView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:.5f];
    [self.view performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:.5f];
    
}

- (void)showFindingFromView:(UIView *)fromView atPoint:(CGPoint)point{

    CGRect findingRect = _findingImage.frame;
    findingRect.origin = point;
    _findingImage.frame = findingRect;
    [fromView addSubview:_findingImage];
    
    
    [self findImageMove];
}

- (void)removeFindingView{
    [self.findingImage removeFromSuperview];
}

-(CGPoint)setPointToAngle:(int)angle center:(CGPoint)centerPoint radius:(double)radius
{
    return CGPointMake(radius*cos(degreesToRadians(angle)) + centerPoint.x, radius*sin(degreesToRadians(angle)) + centerPoint.y);
}

- (void)findImageMove{
    
    if (_findingImage.superview == nil) {
        return;
    }
    
    CGMutablePathRef circularPath = CGPathCreateMutable();
    CGRect pathRect = _findingImage.frame;
    
    pathRect.size.width = 20;
    pathRect.size.height = 20;
    pathRect.origin.x += 20;
    pathRect.origin.y += 30;
    
    CGPathAddEllipseInRect(circularPath, NULL, pathRect);

    
    CAKeyframeAnimation *pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    pathAnimation.removedOnCompletion = NO;
    pathAnimation.path = circularPath;
    [pathAnimation setCalculationMode:kCAAnimationCubic];
    [pathAnimation setFillMode:kCAFillModeForwards];
    pathAnimation.duration = 3;

    CGPathRelease(circularPath);
    [_findingImage.layer addAnimation:pathAnimation forKey:nil];
    [self performSelector:@selector(findImageMove) withObject:nil afterDelay:2];
}
@end
