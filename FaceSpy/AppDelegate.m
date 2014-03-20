//
//  AppDelegate.m
//  FaceSpy
//
//  Created by Siarhei on 10/4/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "CameraEngine.h"

static AppDelegate *instance_;
@implementation AppDelegate

#pragma mark - Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    instance_ = self;
    
    [[CameraEngine engine] startup];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    

    // Override point for customization after application launch.
    
    ScanViewController *scanViewController_ = [[ScanViewController alloc] init];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:scanViewController_];
    self.window.rootViewController = self.navigationController;
    self.navigationController.navigationBarHidden = YES;
    
    //Toolbar size
    float toolbarWidth_ = _toolbar.frame.size.width;
    float toolbarHeight_ = _toolbar.frame.size.height;
    float height_ = self.window.frame.size.height;
    [_toolbar setFrame:CGRectMake(0, height_-toolbarHeight_, toolbarWidth_, toolbarHeight_)];
    _toolbar.bgImage = [[UIImage imageNamed:@"tabbar_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    
    //set selected index to scan
    _currentViewTag = -1;
//    [self toolbarItem_tapped:[[self.toolbar items] objectAtIndex:3]];
    [self gotoScanViewController];
    [_toolbar moveSelectedMaskToItem:[[self.toolbar items] objectAtIndex:3]];
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    //Add toolbar to UI
    [self.window addSubview:_toolbar];
    
    [self managedObjectContext];
    
    for (UIView *subView in _saveView.subviews) {
        subView.layer.masksToBounds = YES;
        subView.layer.cornerRadius = 10;
        subView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.3f];
    }

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    [[CameraEngine engine] shutdown];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[self.scanViewController sfdvc] removeFindingView];
    [[self.scanViewController sfdvc] dismissAlert];
    [[CameraEngine engine] startup];
    [self.scanViewController installCamera];

}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[CameraEngine engine] stopCapture];
    [[CameraEngine engine] shutdown];
}

#pragma mark - Toolbar item tapped

//Go to History
- (void) gotoHistoryViewController
{
    if ([self.navigationController.viewControllers containsObject:_historyViewController])
    {
        [self.navigationController popToViewController:_historyViewController animated:NO];
    }
    else
    {
        _historyViewController = [[HistoryViewController alloc] init];
        self.historyViewController.managedObjectContext = self.managedObjectContext;
        [self.navigationController pushViewController:_historyViewController animated:NO];
    }
}

//Go to Scan
- (void) gotoScanViewController
{
    if ([self.navigationController.viewControllers containsObject:_scanViewController])
    {
        [self.navigationController popToViewController:_scanViewController animated:NO];
    }
    else
    {
        _scanViewController = [[ScanViewController alloc] init];
        [self.navigationController pushViewController:_scanViewController animated:NO];
    }
}

//Go to Settings
- (void) gotoSettingsViewController
{
    if ([self.navigationController.viewControllers containsObject:_settingsViewController])
    {
        [self.navigationController popToViewController:_settingsViewController animated:NO];
    }
    else
    {
        _settingsViewController = [[SettingsViewController alloc] init];
        [self.navigationController pushViewController:_settingsViewController animated:NO];
    }
}

//Go to minimize
- (void) gotoMinimizeModeViewController
{
    
    
    
    if ([self.navigationController.viewControllers containsObject:_scanViewController])
    {
        [self.navigationController popToViewController:_scanViewController animated:NO];
    }
    else
    {
        _scanViewController = [[ScanViewController alloc] init];
        [self.navigationController pushViewController:_scanViewController animated:NO];
    }
    
    [self.scanViewController goMinimized];
    
    /*
    CGRect frame_ = self.window.frame;
    CGRect toolbarFrame_ = _toolbar.frame;
    CGRect statusFrame_ = [UIApplication sharedApplication].statusBarFrame;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.75f];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    
    if (isIOS7)
    {
        _toolbar.frame = CGRectMake(toolbarFrame_.origin.x, frame_.size.height, toolbarFrame_.size.width, toolbarFrame_.size.height);
    }
    else
    {
        _toolbar.frame = CGRectMake(toolbarFrame_.origin.x, frame_.size.height + statusFrame_.size.height, toolbarFrame_.size.width, toolbarFrame_.size.height);
    }
    
    [UIView commitAnimations];
     */
}

//Toolbar's item tapped
- (IBAction)toolbarItem_tapped:(id)sender
{
    if (_currentViewTag == [sender tag])
    {
        return;
    }

    
    CATransition *transition = [CATransition animation];
    [transition setType:kCATransitionPush];
    [transition setDuration:0.5f];
    [transition setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    
    switch ([sender tag])
    {
        case 1:
            //Go to corresponding view controller
            [transition setSubtype:kCATransitionFromLeft];
            [self gotoHistoryViewController];
            [self.navigationController.view.layer addAnimation:transition forKey:@"Transition"];

            //assign _currentViewTag to current item's tag
            _currentViewTag = [sender tag];
            
            //animation with mask
            [_toolbar moveSelectedMaskToItem:sender];
            
            break;
            
        case 2:
            //Go to corresponding view controller
            if (_currentViewTag < [sender tag])
            {
                [transition setSubtype:kCATransitionFromRight];
            }
            else
            {
                [transition setSubtype:kCATransitionFromLeft];
            }
            
            [self gotoScanViewController];
            [self.navigationController.view.layer addAnimation:transition forKey:@"Transition"];
            
            //assign _currentViewTag to current item's tag
            _currentViewTag = [sender tag];
            
            //animation with mask
            [_toolbar moveSelectedMaskToItem:sender];
            
            break;
            
        case 3:
            //Go to corresponding view controller
            [transition setSubtype:kCATransitionFromRight];
            [self gotoSettingsViewController];
            [self.navigationController.view.layer addAnimation:transition forKey:@"Transition"];
            
            //assign _currentViewTag to current item's tag
            _currentViewTag = [sender tag];
            
            //animation with mask
            [_toolbar moveSelectedMaskToItem:sender];

            break;
        case 4:
            //Go to corresponding view controller
            [self gotoMinimizeModeViewController];
            _currentViewTag = [[[self.toolbar items] objectAtIndex:3] tag];
            break;
    }
}

+ (AppDelegate *)instance{
    @synchronized(instance_){
        return instance_;
    }
}


- (void)saveContext
{
    NSError *error;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil)
    {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil)
    {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil)
    {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"db.storedata"];
    
    BOOL firstRun = ![storeURL checkResourceIsReachableAndReturnError:NULL];
    
    if (firstRun) {
        
        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
        
        
        [userDefault setBool:YES forKey:kKeyFaceSpyAlreadyConfig];
        [userDefault setBool:YES forKey:kKeyFaceDetectAlert];
        [userDefault setBool:YES forKey:kKeyFaceDetectVibration];
        
        [userDefault synchronize];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:[[self thumbnailURL] relativePath]] == NO) {
            [fm createDirectoryAtURL:[self thumbnailURL] withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        if ([fm fileExistsAtPath:[[self videoURL] relativePath]] == NO) {
            [fm createDirectoryAtURL:[self videoURL] withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    
    NSError *error;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
	
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSURL *)thumbnailURL{
    return [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"thumbnail" isDirectory:YES];
}
- (NSURL *)videoURL{
    return [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"video" isDirectory:YES];
}
- (void)showSavingView:(BOOL)isShow{
    if (isShow) {
        [self.window addSubview:_saveView];
    } else {
        [_saveView removeFromSuperview];
    }
}
@end
