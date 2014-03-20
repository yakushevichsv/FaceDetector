//
//  PopOverMenuViewController.h
//  FaceSpy
//
//  Created by Siarhei on 10/6/13.
//  Copyright (c) 2013 SYCompany. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PopOverMenuViewControllerDelegate.h"

@interface PopOverMenuViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
    id <PopOverMenuViewControllerDelegate> delegate;
}

@property (nonatomic, retain) NSArray *arrayMenuStr;
@property (strong, nonatomic) IBOutlet UITableViewCell *tableViewCellSave;
@property (strong, nonatomic) IBOutlet UITableViewCell *tableViewCellPlay;
@property (strong, nonatomic) IBOutlet UITableViewCell *tableViewCellDelete;
@property (strong, nonatomic) IBOutlet UITableViewCell *tableViewCellRemove;
@property (assign, nonatomic) BOOL isHaveDelete;
@property (nonatomic, retain) id delegate;

@end
