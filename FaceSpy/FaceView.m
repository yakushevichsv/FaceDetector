//
//  FaceView.m
//  FaceDetection
//
//  Created by Nguyen Thanh Hung on 10/9/13.
//  Copyright (c) 2013 Nguyen Thanh Hung. All rights reserved.
//

#import "FaceView.h"

@interface FaceView ()
@property (strong, nonatomic) UIImage *rectImage;
@end

static UIImage *rectImage_ = nil;

@implementation FaceView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        if (rectImage_ == nil) {
            rectImage_ = [[UIImage imageNamed:@"FaceRect"] resizableImageWithCapInsets:UIEdgeInsetsMake(20, 20, 20, 20)];
        }
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    [rectImage_ drawInRect:rect];
}


@end
