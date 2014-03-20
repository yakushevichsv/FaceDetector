//
//  MinimizedModeViewController.m
//  FaceSpy
//
//  Created by Siarhei on 10/5/13.
//  Copyright (c) 2013 SYCompany. All rights reserved.
//

#import "MinimizedModeViewController.h"
#import "AppDelegate.h"

@interface MinimizedModeViewController ()

@end

@implementation MinimizedModeViewController

#pragma mark - View lifecycle

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    CGRect frame_ = self.view.frame;
    CGRect statusFrame_ = [UIApplication sharedApplication].statusBarFrame;
    
    
    //If is iOS 7 or later
    if (isIOS7)
    {
        _imageViewBackground.frame = frame_;
    }
    else
    {
        _imageViewBackground.frame = CGRectMake(0, -statusFrame_.size.height, frame_.size.width,
                                                frame_.size.height + statusFrame_.size.height);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonMaximized_tapped:(id)sender
{
    CGRect frame_ = self.view.frame;
    AppDelegate *appDelegate_ = (AppDelegate *) [UIApplication sharedApplication].delegate;
    CGRect toolbarFrame_ = appDelegate_.toolbar.frame;
    CGRect statusFrame_ = [UIApplication sharedApplication].statusBarFrame;

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.75f];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    
    if (isIOS7)
    {
        appDelegate_.toolbar.frame = CGRectMake(0, frame_.size.height - toolbarFrame_.size.height, toolbarFrame_.size.width, toolbarFrame_.size.height);
    }
    else
    {
        appDelegate_.toolbar.frame = CGRectMake(0, frame_.size.height - toolbarFrame_.size.height + statusFrame_.size.height, toolbarFrame_.size.width, toolbarFrame_.size.height);
    }
    
    [appDelegate_.toolbar setTransparentWithAlpha:.1f];
    
    [UIView commitAnimations];
    [self.navigationController popViewControllerAnimated:NO];
}

@end
