//
//  SettingsViewController.h
//  FaceSpy
//
//  Created by Siarhei on 10/4/13.
//  Copyright (c) 2013 SYCompany. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AlertSettingViewController.h"

@interface SettingsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableViewCell *tableViewSound;
@property (strong, nonatomic) IBOutlet UITableViewCell *tableViewVibration;
@property (strong, nonatomic) IBOutlet UITableViewCell *tableViewAlert;

@property (weak, nonatomic) IBOutlet UILabel *labelOptionAlert;
@property (weak, nonatomic) IBOutlet UISwitch *switchVibration;


- (IBAction)switchVibrationValueChanged:(id)sender;

@end
