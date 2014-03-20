//
//  PopOverMenuViewController.m
//  FaceSpy
//
//  Created by Siarhei on 10/6/13.
//  Copyright (c) 2013 SYCompany. All rights reserved.
//

#import "PopOverMenuViewController.h"

@interface PopOverMenuViewController ()

@end

@implementation PopOverMenuViewController
@synthesize delegate;

#pragma mark - Tableview

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _isHaveDelete ? 4 : 3;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //appropriate cell
    switch (indexPath.row)
    {
        case 0:
            return _tableViewCellPlay;
        case 1:
            return _tableViewCellSave;
        case 2:
            return _tableViewCellRemove;
        case 3:
            return _tableViewCellDelete;
    }
    
    //if can't find appropriate cell, return a default cell
    static NSString *cellIdentifier = @"CellIdentifier";
    UITableViewCell *tableViewCell_ = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (tableViewCell_ == nil)
    {
        tableViewCell_ = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    return tableViewCell_;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [delegate menuSelected:indexPath.row];
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
