//
//  JJToolbar.h
//  FastestTranslator
//
//  Created by Nguyen Thanh Hung on 9/26/13.
//  Copyright (c) 2013 Nguyen Thanh Hung. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface JJToolbar : UIToolbar<UIToolbarDelegate>

@property (strong, nonatomic) IBOutlet UIImage *bgImage;
@property (strong, nonatomic) UIView *selectedMaskView;

- (void)moveSelectedMaskToItem:(UIBarButtonItem *)item;
- (void)setTransparentWithAlpha:(CGFloat )alpha;
@end
