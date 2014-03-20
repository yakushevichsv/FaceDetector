//
//  JJViewController.m
//  FastestTranslator
//
//  Created by Nguyen Thanh Hung on 9/26/13.
//  Copyright (c) 2013 Nguyen Thanh Hung. All rights reserved.
//

#import "JJViewController.h"
#import "AppDelegate.h"

@interface JJViewController ()

@end

@implementation JJViewController



#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //Kiem tra co phai iOS7 khong
    if (isIOS7)
    {
        self.navigationController.navigationBar.translucent = FALSE;
    }
}

@end
