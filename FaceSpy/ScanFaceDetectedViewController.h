//
//  ScanFaceDetectedViewController.h
//  FaceSpy
//
//  Created by Nguyen Thanh Hung on 10/15/13.
//  Copyright (c) 2013 SYCompany. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ScanFaceDetectedViewControllerDelegate;

@interface ScanFaceDetectedViewController : NSObject

@property (weak, nonatomic) id<ScanFaceDetectedViewControllerDelegate> delegate;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) IBOutlet UIButton *acceptButton;
@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIView *alertView;
@property (strong, nonatomic) IBOutlet UIView *findingView;
@property (strong, nonatomic) IBOutlet UIImageView *findingImage;
@property (strong, nonatomic) IBOutlet UIView *view;
 
- (IBAction)acceptAction:(id)sender;
- (IBAction)cancelAction:(id)sender;

- (void)showAlertFromView:(UIView *)fromView;
- (void)showFindingFromView:(UIView *)fromView atPoint:(CGPoint)point;
- (void)removeFindingView;
- (void)dismissAlert;

@end


@protocol ScanFaceDetectedViewControllerDelegate <NSObject>

- (void)scanFaceDetectedViewControllerDidSelectedAtIndex:(NSInteger)index;

@end