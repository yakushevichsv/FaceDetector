//
//  SettingsViewController.m
//  FaceSpy
//
//  Created by Siarhei on 10/4/13.
//  Copyright (c) 2013 SYCompany. All rights reserved.
//

#import "SettingsViewController.h"

#import "AppDelegate.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

#pragma mark - Tableview

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Recording";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row)
    {
        case 0:
            return _tableViewVibration;
            break;
            
        case 1:
            return _tableViewAlert;
            break;
    }
    
    //Default cell
    static NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 1)
    {
        AlertSettingViewController *alertSettingViewController_=  [[AlertSettingViewController alloc] init];
        [self.navigationController pushViewController:alertSettingViewController_ animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark - View lifecycle

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void) viewDidUnload
{
    [super viewDidUnload];
    
    NSLog(@"viewDidUnload");
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSUserDefaults *pref_ = [NSUserDefaults standardUserDefaults];
    
    //alert option
    if ([pref_ boolForKey:kKeyFaceDetectAlert])
    {
        _labelOptionAlert.text = @"Confirm";
    }
    else
    {
        _labelOptionAlert.text = @"Automatic";
    }
    
    _switchVibration.on = [pref_ boolForKey:kKeyFaceDetectVibration];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)switchVibrationValueChanged:(id)sender
{
    NSUserDefaults *pref_ = [NSUserDefaults standardUserDefaults];
    [pref_ setBool:_switchVibration.on forKey:kKeyFaceDetectVibration];
    [pref_ synchronize];
}

@end
