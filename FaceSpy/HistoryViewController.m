//
//  HistoryViewController.m
//  FaceSpy
//
//  Created by Siarhei on 10/4/13.
//  Copyright (c) 2013 SYCompany. All rights reserved.
//

#import "HistoryViewController.h"

#import <MediaPlayer/MediaPlayer.h>
#import <AssetsLibrary/AssetsLibrary.h>


#import "AppDelegate.h"
#import "Video.h"
#import "UISwipeGestureRecognizerWithData.h"
#import "UIViewWithData.h"
#import "UIButtonWithData.h"
#import "UITapGestureRecognizerWithData.h"
#import "SWTableViewCell.h"

@interface HistoryViewController ()<SWTableViewCellDelegate>

@property (strong, nonatomic) UIImage *noThumbnailImage;
@property (strong, nonatomic) MPMoviePlayerViewController *mpvc;
@property (strong, nonatomic) IBOutlet UIViewWithData *viewExtraButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (strong, nonatomic) UIButtonWithData *maskButton;
@property (strong, nonatomic) NSMutableArray *videos;

- (IBAction)saveTapHandle:(id)sender;
- (IBAction)deleteCell:(id)sender;
- (IBAction)editAction:(id)sender;

- (void)handleTapToPlay:(UITapGestureRecognizer *)tapGesture;

@end

@implementation HistoryViewController

#pragma mark - Menu selected

- (void) saveVideo
{

    Video *video = [self.videos objectAtIndex:_currentIndexPath.row];
    
    if ([video.alreadySave boolValue]) {
        return;
    }
    
    NSURL *fileURL = [[[AppDelegate instance] videoURL] URLByAppendingPathComponent:video.fileName];
    [[AppDelegate instance] showSavingView:YES];
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:fileURL completionBlock:^(NSURL *assetURL, NSError *error) {
        
        if (!error) {
            video.alreadySave = [NSNumber numberWithBool:YES];
            video.libraryURL = [assetURL relativeString];
            
            [[AppDelegate instance].managedObjectContext save:nil];
            
            [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
            
            [_tableViewHistory reloadRowsAtIndexPaths:[NSArray arrayWithObject:_currentIndexPath] withRowAnimation:UITableViewRowAnimationRight];
        }
        
        [[AppDelegate instance] showSavingView:NO];
    }];
    library = nil;
}

- (void) playVideo
{
    Video *video = [self.videos objectAtIndex:_currentIndexPath.row];
    
    NSURL *url = nil;
    
    if ([video.alreadySave boolValue]) {
        url = [NSURL URLWithString:video.libraryURL];
    } else {
        url = [[[AppDelegate instance] videoURL] URLByAppendingPathComponent:video.fileName];
    }
    
    self.mpvc = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
    
    [[[AppDelegate instance] toolbar] setHidden:YES];
    [[[AppDelegate instance] navigationController] presentModalViewController:_mpvc animated:YES];

}

- (void) RemoveVideo
{
    Video *video = [self.videos objectAtIndex:_currentIndexPath.row];
    
    NSURL *fileURL = [[[AppDelegate instance] videoURL] URLByAppendingPathComponent:video.fileName];
    
    if ([video.alreadySave boolValue]) {
        
    } else {
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
    }
    if (video.thumbnail && [video.thumbnail isEqualToString:kKeyVideoInfoNoFace] == NO) {
        fileURL = [[[AppDelegate instance] thumbnailURL] URLByAppendingPathComponent:video.thumbnail];
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
    }
    
    
    [[AppDelegate instance].managedObjectContext deleteObject:video];
    [[AppDelegate instance].managedObjectContext save:nil];
    
    [_tableViewHistory beginUpdates];
    [_videos removeObjectAtIndex:_currentIndexPath.row];
    [_tableViewHistory deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:_currentIndexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
    
    [_tableViewHistory endUpdates];
    
    [[AppDelegate instance] showSavingView:NO];
}

- (void) deleteVideo
{
//    Video *video = [self.fetchedResultsController objectAtIndexPath:_currentIndexPath];
//    
//    NSURL *fileURL = [NSURL URLWithString:video.fileName];
//    
//    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//    [library rem
//    library = nil;
}

- (void) menuSelected:(NSInteger)menuIndex
{
    [self.fpPopoverController dismissPopoverAnimated:YES];
    
    switch (menuIndex) {
        case 0:
            [self playVideo];
            break;
            
        case 1:
            [self saveVideo];
            break;
            
        case 2:
            [self RemoveVideo];
            break;
            
        case 3:
            [self deleteVideo];
            break;
            
        default:
            break;
    }
}

#pragma mark - Tableview

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 75;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
    if (_fpPopoverController == nil)
    {
        PopOverMenuViewController *popOverMenuViewController_ =
            [[PopOverMenuViewController alloc] initWithNibName:@"PopOverMenuViewController" bundle:nil];
        
        popOverMenuViewController_.delegate = self;
        self.fpPopoverController = [[FPPopoverController alloc] initWithViewController:popOverMenuViewController_];
    }
    
    
    [(PopOverMenuViewController *)[self.fpPopoverController viewController] setIsHaveDelete:NO];
    
    self.fpPopoverController.title = nil;
    self.fpPopoverController.arrowDirection = FPPopoverNoArrow;
    self.fpPopoverController.contentSize = CGSizeMake(120, 160);
    _fpPopoverController.contentView.title = @"Menu";
    
    UITableViewCell *tableviewCell_ = [tableView cellForRowAtIndexPath:indexPath];
    [self.fpPopoverController presentPopoverFromView:tableviewCell_];
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];

    
     */
    self.currentIndexPath = indexPath;
    [self playVideo];
}
/*
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    if (isIOS7) {
        return YES;
    } else {
        return NO;
    }

}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        self.currentIndexPath = indexPath;
        [self RemoveVideo];
    }
}

*/

#pragma mark - Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
//	NSInteger count = [[self.fetchedResultsController sections] count];
//	return count;
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//	id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
//    
//	NSInteger count = [sectionInfo numberOfObjects];
//	return count;
    return [self.videos count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifierUnSave = @"CellIdUnSave";
    static NSString *cellIdentifierSaved = @"CellIdSaved";
    
    
    static NSDateFormatter *formatter = nil;
    
    if (!formatter)
    {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MM/dd/yyyy hh:mm:ss a"];
    }
    
    Video *video = [self.videos objectAtIndex:indexPath.row];
    
    SWTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[[video alreadySave] boolValue] ? cellIdentifierSaved : cellIdentifierUnSave];
    if (cell == nil) {
        
//        if (isIOS7) {
        
        NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    
        NSString *cellIdentify = nil;
        if ([[video alreadySave] boolValue]) {
            [rightUtilityButtons addUtilityButtonWithColor:
             [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                     title:@"Delete"];
            cellIdentify = cellIdentifierSaved;
        } else {
            [rightUtilityButtons addUtilityButtonWithColor:
             [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0]
                                                     title:@"Save"];
            [rightUtilityButtons addUtilityButtonWithColor:
             [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                     title:@"Delete"];
            cellIdentify = cellIdentifierUnSave;
        }
        
        
            
            cell = [[SWTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentify containingTableView:_tableViewHistory leftUtilityButtons:nil rightUtilityButtons:rightUtilityButtons];
            
            [cell setDelegate:self];
//        }

    }
    

    
    if ([video.duration integerValue] == 0) {
        [FaceSpyHelper getInfoOfVideo:video];
    }
	cell.textLabel.text = [FaceSpyHelper getDurationString:[video.duration integerValue]];
    cell.detailTextLabel.text = [formatter stringFromDate:video.date];
    
    if (video.thumbnail == nil) {
        [FaceSpyHelper getThumbnailWithFirstFrameofVideo:video];
    }
    
    if ([video.thumbnail isEqualToString:kKeyVideoInfoNoFace] == NO) {
        NSURL *thumbnailURL = [[[AppDelegate instance] thumbnailURL] URLByAppendingPathComponent:video.thumbnail];
        cell.imageView.image = [UIImage imageWithContentsOfFile:[thumbnailURL relativePath]];
    } else {
        cell.imageView.image = _noThumbnailImage;
    }
    
    cell.imageView.userInteractionEnabled = YES;
    UITapGestureRecognizerWithData *tap = [[UITapGestureRecognizerWithData alloc] initWithTarget:self action:@selector(handleTapToPlay:)];
    tap.data = indexPath;
    [cell.imageView addGestureRecognizer:tap];
    
    return cell;
}

- (void)swippableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index{
    self.currentIndexPath = [_tableViewHistory indexPathForCell:cell];
    
    Video *video = [self.videos objectAtIndex:_currentIndexPath.row];
    
    if (index == 1) {
        [self RemoveVideo];
    } else {
        if ([video.alreadySave boolValue]) {
            [self RemoveVideo];
            return;
        }
        [self saveVideo];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    /*
    if (isIOS7 == NO) {
        UISwipeGestureRecognizerWithData *swipe = [[UISwipeGestureRecognizerWithData alloc] initWithTarget:self action:@selector(swipeHandler:)];
        swipe.direction = UISwipeGestureRecognizerDirectionRight;
        [cell addGestureRecognizer:swipe];
        swipe.data = cell;
        
        swipe = [[UISwipeGestureRecognizerWithData alloc] initWithTarget:self action:@selector(swipeHandler:)];
        swipe.direction = UISwipeGestureRecognizerDirectionLeft;
        [cell addGestureRecognizer:swipe];
        swipe.data = cell;
        
        [cell addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeMaskButton:)]];
    }
    */
    
    
    Video *video = [self.videos objectAtIndex:indexPath.row];
    if ([video.duration integerValue] == 0) {
        [FaceSpyHelper getInfoOfVideo:video];
    }
    
    if (video.thumbnail == nil) {
        [FaceSpyHelper getThumbnailWithFirstFrameofVideo:video];
    }
    
    if ([video.thumbnail isEqualToString:kKeyVideoInfoNoFace] == NO) {
        NSURL *thumbnailURL = [[[AppDelegate instance] thumbnailURL] URLByAppendingPathComponent:video.thumbnail];
        cell.imageView.image = [UIImage imageWithContentsOfFile:[thumbnailURL relativePath]];
    } else {
        cell.imageView.image = _noThumbnailImage;
    }
    
    if (isIOS7 == NO) {
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
    }
    
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    NSLog(@"scroll view did begin dragging");
}

- (void)removeMaskButton:(id)sender{

    if (_maskButton == nil) {
        return;
    }
    
    [_maskButton removeFromSuperview];
    self.maskButton = nil;
    
    UITableViewCell *cell = _viewExtraButton.data;
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView setAnimationDuration:.3f];
    
    CGRect viewButtonRect = _viewExtraButton.frame;
    CGRect cellRect = cell.frame;
    
    [cell.imageView setHidden:NO];
    cellRect.origin.x += viewButtonRect.size.width;
    cellRect.size.width -= viewButtonRect.size.width;
    cell.frame = cellRect;
    
    [UIView commitAnimations];
    
    [_viewExtraButton performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:.3f];
    _viewExtraButton.tag = 0;
    
}

- (void)swipeHandler:(UISwipeGestureRecognizerWithData *)swipe{

    if (swipe.direction == UISwipeGestureRecognizerDirectionLeft) {
        
        if (_viewExtraButton.tag == 1) {
            return;
        }
        _viewExtraButton.tag = 1;
        
        UIButtonWithData *bt = [UIButtonWithData buttonWithType:UIButtonTypeCustom];
        
        
        self.maskButton = bt;
        bt.frame = _tableViewHistory.bounds;
        [bt addTarget:self action:@selector(removeMaskButton:) forControlEvents:UIControlEventTouchDown];
        [_tableViewHistory addSubview:bt];
        [_tableViewHistory bringSubviewToFront:swipe.data];
        
        UITableViewCell *cell = swipe.data;
        CGRect viewButtonRect = _viewExtraButton.frame;
        CGRect cellBounds = [cell bounds];
        viewButtonRect.origin = CGPointMake(cellBounds.size.width, 0);
        _viewExtraButton.frame = viewButtonRect;
        _viewExtraButton.data = cell;
        
        [cell addSubview:_viewExtraButton];
        [_tableViewHistory bringSubviewToFront:_viewExtraButton];
        [UIView beginAnimations:@"" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDuration:.3f];
        
        [cell.imageView setHidden:YES];
        cellBounds = [cell frame];
        cellBounds.origin.x -= viewButtonRect.size.width;
        cellBounds.size.width += viewButtonRect.size.width;
        cell.frame = cellBounds;
        
        [UIView commitAnimations];
        
        
    } else if (swipe.direction == UISwipeGestureRecognizerDirectionRight) {
        [self removeMaskButton:_maskButton];
    }
    
}

- (IBAction)saveTapHandle:(id)sender {
    NSLog(@"Save!");
    self.currentIndexPath = [_tableViewHistory indexPathForCell:_viewExtraButton.data];
    [self removeMaskButton:nil];
    
    [self saveVideo];
}

- (IBAction)deleteCell:(id)sender {
    NSLog(@"Delete!");
    self.currentIndexPath = [_tableViewHistory indexPathForCell:_viewExtraButton.data];
    [self removeMaskButton:nil];
//    [_maskButton removeFromSuperview];
//    self.maskButton = nil;
//    
//    UITableViewCell *cell = _viewExtraButton.data;
//    CGRect rect = cell.frame;
//    rect.origin.x = 0;
//    rect.size.width = _tableViewHistory.bounds.size.width;
//    cell.frame = rect;
//    
//    [_viewExtraButton removeFromSuperview];
    [[AppDelegate instance] showSavingView:YES];
    [self performSelector:@selector(RemoveVideo) withObject:nil afterDelay:.5f];
}

- (IBAction)editAction:(id)sender {
    [self.tableViewHistory setEditing:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{    
	return @"";
}
 


- (void)controller:(NSFetchedResultsController*)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath*)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath*)newIndexPath
{
    switch(type) {
        case NSFetchedResultsChangeDelete:
        {
            NSLog(@"Delete row: %d", indexPath.row);
            [_tableViewHistory deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight
             ];
        }
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController*)controller
{
    [_tableViewHistory endUpdates];
}

- (void)controllerWillChangeContent:(NSFetchedResultsController*)controller
{
    [_tableViewHistory beginUpdates];
}


- (void)handleTapToPlay:(UITapGestureRecognizerWithData *)tapGesture{
    self.currentIndexPath = tapGesture.data;
    [self playVideo];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (isIOS7) {
//        [self.tableViewHistory setContentInset:UIEdgeInsetsMake(5, 0, 44, 0)];
        _tableViewHistory.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }
    _tableViewHistory.rowHeight = [self tableView:_tableViewHistory heightForRowAtIndexPath:nil];
    self.noThumbnailImage = [UIImage imageNamed:@"no-face.png"];
    
    _tableViewHistory.dataSource = self;
    _tableViewHistory.delegate = self;
    
//    NSError *error = nil;
//    if (![self.fetchedResultsController performFetch:&error])
//    {
//        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//        
//	}
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    AppDelegate *app = [AppDelegate instance];
    
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Video" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Sort with date property
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [fetchRequest setSortDescriptors:@[sortDescriptor ]];
    
    NSArray *arr = [app.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if (arr) {
        self.videos = [NSMutableArray arrayWithArray:arr];
    } else {
        self.videos = [NSMutableArray array];
    }
    
    fetchRequest = nil;
    
    [_tableViewHistory beginUpdates];
    
    NSMutableArray *indexPaths = [NSMutableArray array];
    int i = 0;
    for (Video *video in _videos) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:i++ inSection:0]];
    }
    
    [_tableViewHistory insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationLeft];
    [_tableViewHistory endUpdates];
    
    
    //    self.fetchedResultsController.delegate = self;
    
    
    
    
    [[[AppDelegate instance] toolbar] setHidden:NO];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [_videos removeAllObjects];
    [_tableViewHistory reloadData];
    [super viewWillDisappear:animated];
    
    self.fetchedResultsController.delegate = nil;
    [self.fpPopoverController dismissPopoverAnimated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil)
    {
        return _fetchedResultsController;
    }
    
    /*
	 Set up the fetched results controller.
     */
	// Create the fetch request for the entity.
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	// Edit the entity name as appropriate.
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Video" inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];
    
	// Set the batch size to a suitable number.
	[fetchRequest setFetchBatchSize:20];
    
	// Sort using the timeStamp property.
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
	[fetchRequest setSortDescriptors:@[sortDescriptor ]];
    

    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    
	return _fetchedResultsController;
}    



@end
