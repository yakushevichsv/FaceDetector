//
//  ScanViewController.h
//  FaceSpy
//
//  Created by Siarhei on 10/4/13.
//  Copyright (c) 2013 SYCompany. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MinimizedModeViewController.h"
#import "UIViewWithShakeDetect.h"
#import "ScanFaceDetectedViewController.h"

#define ONE_MINUTE      60
#define TEN_SECOND      10

@interface ScanViewController : UIViewController <UIViewWithShakeDetectDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIWebView *webview;

@property (assign, nonatomic) BOOL isMinimizedMode;
@property (strong, nonatomic) ScanFaceDetectedViewController *sfdvc;

- (IBAction)pauseButtonAction:(id)sender;
- (IBAction)playButtonAction:(id)sender;
- (IBAction)buttonMinimize_tapped:(id)sender;
- (IBAction)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer;

- (void)installCamera;
- (void)goMinimized;
- (void)goNormal;
@end
