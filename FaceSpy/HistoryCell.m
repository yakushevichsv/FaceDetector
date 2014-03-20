//
//  HistoryCell.m
//  FaceSpy
//
//  Created by Nguyen Thanh Hung on 10/13/13.
//  Copyright (c) 2013 JujubeSoftware. All rights reserved.
//

#import "HistoryCell.h"

@interface HistoryCell ()
@property (strong, nonatomic) UIButton *moreButton;
@property (strong, nonatomic) UIView *viewForButton;

- (void)handleSwipe:(UISwipeGestureRecognizer *)swipeGesture;

@end

@implementation HistoryCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.moreButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        self.viewForButton = [[UIView alloc] initWithFrame:CGRectMake(self.bounds.size.width, 0, 100, 76)];
        [_viewForButton setBackgroundColor:[UIColor blueColor]];
        [self addSubview:_viewForButton];
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (UITableView *)tableView {
    UIView *tableView = self.superview;
    while(tableView) {
        if(![tableView isKindOfClass:[UITableView class]]) {
			tableView = tableView.superview;
		}
        else {
            return (UITableView *)tableView;
        }
	}
    return nil;
}

- 

//- (void)willTransitionToState:(UITableViewCellStateMask)state{
//    [super willTransitionToState:state];
//    if (state == UITableViewCellStateShowingDeleteConfirmationMask) {
//        for (UIView *view in self.subviews) {
//            
//            if ([view isKindOfClass:NSClassFromString(@"UITableViewCellDeleteConfirmationControl")]) {
//                
//                
//                
//                view.backgroundColor = [UIColor blueColor];
//                CGRect deleteViewFrame = view.frame;
//                deleteViewFrame.origin.x -= deleteViewFrame.size.width;
//                deleteViewFrame.size.width *= 2;
//                
//                view.frame = deleteViewFrame;
//                
//                for (UIView *subView in view.subviews) {
//                    if ([subView isKindOfClass:NSClassFromString(@"_UITableViewCellDeleteConfirmationControl")]) {
//                        if ([_delegate respondsToSelector:@selector(tableView:titleForMoreOptionButtonForRowAtIndexPath:)]) {
//                            [_moreButton setTitle:[_delegate tableView:[self tableView] titleForMoreOptionButtonForRowAtIndexPath:[[self tableView] indexPathForCell:self]] forState:UIControlStateNormal];
//                        } else {
//                            [_moreButton setTitle:@"More" forState:UIControlStateNormal];
//                        }
//                        
//                        [_moreButton addTarget:_delegate action:@selector(tableView:moreOptionButtonPressedInRowAtIndexPath:) forControlEvents:UIControlEventTouchUpOutside];
//                        
//                        UIButton *bt = subView;
//                        
//                        for (id obj in [bt actionsForTarget:self forControlEvent:UIControlEventTouchUpOutside]) {
//                            NSLog(@"action: %@", obj);
//                        }
//                        
//                        CGRect moreButtonRect = subView.frame;
////                        moreButtonRect.origin = CGPointMake(moreButtonRect.origin.x - moreButtonRect.size.width, (deleteViewFrame.size.height - moreButtonRect.size.height) / 2);
//                        [_moreButton setEnabled:YES];
//                        [_moreButton setUserInteractionEnabled:YES];
//                        _moreButton.frame = moreButtonRect;
//                        [self addSubview:_moreButton];
//                        [subView removeFromSuperview];
//                        break;
//                    }
//                    
//                    
//                }
//                
//                break;
//                
//            }
//        }
//    }
//    
//}
//
//- (void)didTransitionToState:(UITableViewCellStateMask)state{
//    [super didTransitionToState:state];
//    
//}

- (void)handleSwipe:(UISwipeGestureRecognizer *)swipeGesture{
    if (swipeGesture.state == UIGestureRecognizerStateBegan) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.3];
        CGRect rect = _viewForButton.frame;
        if (swipeGesture.direction == UISwipeGestureRecognizerDirectionLeft) {
            rect.origin.x = 50;
        } else if (swipeGesture.direction == UISwipeGestureRecognizerDirectionRight){
            rect.origin.x = self.bounds.size.width;
        }
        
        _viewForButton.frame = rect;
        
        [UIView commitAnimations];
    }
}
@end
