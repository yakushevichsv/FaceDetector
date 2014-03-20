//
//  UICustomRecordButtonBase.m
//  FaceSpy
//
//  Created by Siarhei Yakushevich on 1/20/14.
//  Copyright (c) 2014 SY's PC. All rights reserved.
//

#import "UICustomRecordButtonBase.h"

enum CustomButtonState {
    CustomButtonStateStop = 0x00,
    CustomButtonStateRecord = 0x01,
    CustomButtonStatePause = 0x02,
    CustomButtonStateMinimize =0x04
};
typedef enum CustomButtonState CustomButtonState;


@interface UICustomRecordButtonBase()

@property (nonatomic) CustomButtonState buttonState;

@end

@implementation UICustomRecordButtonBase


- (void)stopRecording
{
    self.buttonState = CustomButtonStateStop;
}

- (void)record
{
    self.buttonState = CustomButtonStateRecord;
}

- (void)pause
{
    self.buttonState = CustomButtonStatePause;
}

- (void)minimize
{
    self.buttonState = CustomButtonStateMinimize;
}

- (CGFloat)getRadiusFromRect:(CGRect)rect
{
    const CGFloat widthR = MIN(CGRectGetMidX(rect)-CGRectGetMinX(rect), CGRectGetMaxX(rect)-CGRectGetMidX(rect));
    const CGFloat heightR = MIN(CGRectGetMidY(rect)-CGRectGetMinY(rect), CGRectGetMaxY(rect)-CGRectGetMidY(rect));
    return MIN(widthR,heightR);
}

- (void)setButtonState:(CustomButtonState)buttonState
{
    if (_buttonState != buttonState)
    {
        _buttonState = buttonState;
        [self setNeedsDisplay];
    }
}

- (void)appendCirclePartInRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    const CGFloat r = [self getRadiusFromRect:rect];
    
    CGFloat innerR = roundf(0.7*r);
    
    CGPoint center = CGPointMake(CGRectGetMidX(rect),CGRectGetMidY(rect));
    CGRect innerRect = CGRectMake(center.x - innerR, center.y - innerR, innerR*2, innerR*2);
    
    CGContextAddEllipseInRect(context, innerRect);
    CGRect outerRect = CGRectMake(center.x-r, center.y-r, r*2, r*2);
    CGContextAddEllipseInRect(context, outerRect);
    
    CGColorRef whiteColor = CGColorCreateCopyWithAlpha([UIColor whiteColor].CGColor, 0.8);
    CGContextSetFillColorWithColor(context, whiteColor);
    CGColorRelease(whiteColor);
    
    CGContextEOFillPath(context);
    
    CGContextFillPath(context);
    
    CGContextRestoreGState(context);
    
    CGContextSaveGState(context);
    
    CGContextSetLineWidth(context, 2);
    CGContextSetStrokeColorWithColor(context, [UIColor darkGrayColor].CGColor);
    
    CGContextStrokeEllipseInRect(context, CGRectInset(outerRect, 1, 1));
    CGContextStrokeEllipseInRect(context, CGRectInset(innerRect, 1, 1));
    
    CGContextRestoreGState(context);
}



- (void)displayRecordButtonInRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    CGColorRef redColor = CGColorCreateCopyWithAlpha([UIColor redColor].CGColor, 0.8);
    CGContextSetFillColorWithColor(context, redColor);
    CGColorRelease(redColor);
    
    const CGFloat r = [self getRadiusFromRect:rect];
    CGFloat innerR = roundf(0.7*r);
    
    CGPoint center = CGPointMake(CGRectGetMidX(rect),CGRectGetMidY(rect));
    CGRect innerRect = CGRectMake(center.x - innerR, center.y - innerR, innerR*2, innerR*2);
    CGContextAddEllipseInRect(context, innerRect);
    CGContextFillPath(context);
    
    CGContextRestoreGState(context);
}

- (void)displayStopButtonInRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    
    CGColorRef redColor = CGColorCreateCopyWithAlpha([UIColor redColor].CGColor, 0.8);
    CGContextSetFillColorWithColor(context, redColor);
    CGColorRelease(redColor);
    
    const CGFloat r = [self getRadiusFromRect:rect];
    CGFloat innerR = roundf(0.3*r);
    
    CGPoint center = CGPointMake(CGRectGetMidX(rect),CGRectGetMidY(rect));
    CGRect innerRect = CGRectMake(center.x - innerR, center.y - innerR, innerR*2, innerR*2);
    
    CGContextAddRect(context, innerRect);
    CGContextFillPath(context);
    
    CGContextRestoreGState(context);
    
}

- (void)drawStipWithIndex:(NSUInteger)index inRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    
    CGColorRef redColor = CGColorCreateCopyWithAlpha([UIColor redColor].CGColor, 0.8);
    CGContextSetFillColorWithColor(context, redColor);
    CGColorRelease(redColor);
    
    const CGFloat r = [self getRadiusFromRect:rect];
    CGFloat innerR = roundf(0.2*r);
    CGFloat innerR2 = roundf(0.5*r);
    
    CGPoint center = CGPointMake(CGRectGetMidX(rect),CGRectGetMidY(rect));
    CGRect innerRect = CGRectMake(center.x + innerR*(index == 0 ? -2 :1), center.y- (r-innerR2), innerR, 2*(r-innerR2));
    
    CGContextAddRect(context, innerRect);
    CGContextFillPath(context);
    
    CGContextRestoreGState(context);
}

- (void)displayRects:(CGRect)rect
{
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    CGColorRef redColor = CGColorCreateCopyWithAlpha([UIColor redColor].CGColor, 0.8);
    CGContextSetFillColorWithColor(context, redColor);
    CGColorRelease(redColor);

    
    const CGFloat r = [self getRadiusFromRect:rect];
    
    CGFloat innerR = roundf(0.2*r);
    
    CGPoint center = CGPointMake(CGRectGetMidX(rect),CGRectGetMidY(rect));
    CGRect innerRect = CGRectMake(center.x - innerR, center.y - innerR, innerR*2, innerR*2);
    
    CGContextAddRect(context, innerRect);
    
    innerR = roundf(0.4*r);
    innerRect = CGRectMake(center.x - innerR, center.y - innerR, innerR*2, innerR*2);
    
    CGContextAddRect(context, innerRect);
    
    CGContextEOFillPath(context);
    
    CGContextFillPath(context);
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [self appendCirclePartInRect:rect];
    if (self.buttonState == CustomButtonStateStop)
    {
        [self displayRecordButtonInRect:rect];
    } else if (self.buttonState == CustomButtonStateRecord)
    {
        [self appendCirclePartInRect:rect];
        [self displayStopButtonInRect:rect];
    }
    else if (self.buttonState == CustomButtonStatePause)
    {
        [self drawStipWithIndex:0 inRect:rect];
        [self drawStipWithIndex:1 inRect:rect];
    }
    else if (self.buttonState == CustomButtonStateMinimize)
    {
        [self displayRects:rect];
    }
}



@end
