//
//  HistoryViewController.h
//  FaceSpy
//
//  Created by Siarhei on 10/4/13.
//  Copyright (c) 2013 SYCompany. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FPPopoverController.h"
#import "PopOverMenuViewController.h"
#import "HistoryObject.h"

@interface HistoryViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, PopOverMenuViewControllerDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, retain) NSMutableArray *arrayHistory;
@property (nonatomic, retain) NSIndexPath *currentIndexPath;
@property (weak, nonatomic) IBOutlet UITableView *tableViewHistory;
@property (strong, nonatomic) FPPopoverController *fpPopoverController;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
