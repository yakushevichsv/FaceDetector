//
//  AlertSettingViewController.m
//  FaceSpy
//
//  Created by Siarhei on 10/7/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "AlertSettingViewController.h"
#import "AppDelegate.h"

@interface AlertSettingViewController ()

@end

@implementation AlertSettingViewController

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
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Default cell
    static NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    cell.textLabel.text = [_arrayOptions objectAtIndex:indexPath.row];
    

    //userdefault
    NSUserDefaults *pref_ = [NSUserDefaults standardUserDefaults];
    
    //set checkmark
    if ([pref_ boolForKey:kKeyFaceDetectAlert])
    {
        if (indexPath.row == 0) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            _selectedIndexPath = indexPath;
        }
        
    } else {
        
        if (indexPath.row == 1) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            _selectedIndexPath = indexPath;
        }
        
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_selectedIndexPath)
    {
        UITableViewCell *previousSelectedCell = [tableView cellForRowAtIndexPath:_selectedIndexPath];
        previousSelectedCell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (selectedCell.accessoryType == UITableViewCellAccessoryNone)
    {
        selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        selectedCell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    NSUserDefaults *pref_ = [NSUserDefaults standardUserDefaults];
    if (indexPath.row == 0) {
        [pref_ setBool:YES forKey:kKeyFaceDetectAlert];
    } else {
        [pref_ setBool:NO forKey:kKeyFaceDetectAlert];
    }
    
    [pref_ synchronize];
    
    _selectedIndexPath = indexPath;
}

#pragma mark - View lifecycle

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = YES;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.navigationController.navigationBarHidden = NO;
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
    
    if (isIOS7)
    {
        CGRect tableViewAlertOptionsFrame = _tableViewAlertOptions.frame;
        
        _tableViewAlertOptions.frame = CGRectMake(0,
        self.navigationController.navigationBar.frame.size.height - [UIApplication sharedApplication].statusBarFrame.size.height,
                                                  tableViewAlertOptionsFrame.size.width, tableViewAlertOptionsFrame.size.height);
    }
    
    _arrayOptions = @[@"Confirm", @"Automatic"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
