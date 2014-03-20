//
//  AppDelegate.h
//  FaceSpy
//
//  Created by Siarhei on 10/4/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "ScanViewController.h"
#import "HistoryViewController.h"
#import "SettingsViewController.h"
#import "JJToolbar.h"

#define kKeyFaceSpyAlreadyConfig        @"kKeyFaceSpyAlreadyConfig"
#define kKeyFaceDetectAlert             @"kKeyFaceDetectAlert"
#define kKeyFaceDetectVibration         @"kKeyFaceDetectVibration"

#define isIOS7 [[[UIDevice currentDevice] systemVersion] floatValue] >= 7

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, retain) SettingsViewController *settingsViewController;
@property (nonatomic, retain) HistoryViewController *historyViewController;
@property (nonatomic, retain) ScanViewController *scanViewController;
@property (nonatomic, retain) MinimizedModeViewController *minimizedModeViewController;

@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) NSManagedObjectModel *managedObjectModel;
@property (nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) IBOutlet JJToolbar *toolbar;
@property (nonatomic, assign) int currentViewTag;
@property (weak, nonatomic) IBOutlet UIView *saveView;

- (IBAction)toolbarItem_tapped:(id)sender;

- (NSURL *)thumbnailURL;
- (NSURL *)videoURL;
- (void)saveContext;
- (void)showSavingView:(BOOL)isShow;

+ (AppDelegate *)instance;

@end
