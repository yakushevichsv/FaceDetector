//
//  AlertSettingViewController.h
//  FaceSpy
//
//  Created by Siarhei on 10/7/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AlertSettingViewController : UIViewController

@property (nonatomic, retain) NSIndexPath *selectedIndexPath;
@property (nonatomic, retain) NSArray *arrayOptions;
@property (weak, nonatomic) IBOutlet UITableView *tableViewAlertOptions;

@end
