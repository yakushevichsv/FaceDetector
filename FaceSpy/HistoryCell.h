//
//  HistoryCell.h
//  FaceSpy
//
//  Created by Nguyen Thanh Hung on 10/13/13.
//  Copyright (c) 2013 JujubeSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MSCMoreOptionTableViewCellDelegate.h"

@interface HistoryCell : UITableViewCell

@property (nonatomic, weak) id<MSCMoreOptionTableViewCellDelegate> delegate;

@end
