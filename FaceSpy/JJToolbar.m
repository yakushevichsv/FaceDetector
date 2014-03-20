//
//  JJToolbar.m
//  FastestTranslator
//
//  Created by Nguyen Thanh Hung on 9/26/13.
//  Copyright (c) 2013 Nguyen Thanh Hung. All rights reserved.
//

#import "JJToolbar.h"


@implementation JJToolbar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        

    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [self setTranslucent:YES];
    [super drawRect:rect];
    [_bgImage drawInRect:rect];
    
}

- (void)moveSelectedMaskToItem:(UIBarButtonItem *)item{
    CGRect rect = [[item valueForKey:@"view"] frame];
    rect.origin = CGPointMake(rect.origin.x - 15, rect.origin.y + 2.5);
    rect.size = CGSizeMake(60, rect.size.height - 5);
    
    if (!self.selectedMaskView) {
        
        UIView *view = [[UIView alloc] initWithFrame:rect];
        view.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:.3f];
        [view.layer setCornerRadius:8.0f];
        [view.layer setMasksToBounds:YES];
        [view setUserInteractionEnabled:YES];
        [self addSubview:view];
        
        self.selectedMaskView = view;
        view = nil;
    } else {
        [UIView beginAnimations:@"" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDuration:.3f];
        
        _selectedMaskView.frame = rect;
        
        [UIView commitAnimations];
    }
    [self bringSubviewToFront:_selectedMaskView];
}

- (void)setTransparentWithAlpha:(CGFloat)alpha{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0f);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect area = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -area.size.height);
    
    CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
    
    CGContextSetAlpha(ctx, alpha);
    
    CGContextDrawImage(ctx, area, [self.bgImage CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    self.bgImage = newImage;
    [self setNeedsDisplay];
}

@end
