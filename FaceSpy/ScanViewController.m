//
//  ScanViewController.m
//  FaceSpy
//
//  Created by Siarhei on 10/4/13.
//  Copyright (c) 2013 SYCompany. All rights reserved.
//

#import "ScanViewController.h"
#import "UICustomRecordButtonBase.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <math.h>

#import "AppDelegate.h"
#import "CameraEngine.h"
#import "FaceView.h"
#import "Video.h"
#import "FPPopoverController.h"


#define MIN_DETECT_LOST     100
#define FACE_RECT_TAG       999
#define TIME_REMAINING      45
#define LITE_MAX_VIDEO      10
#define FAKE_WEBSITE        @"http://en.wikipedia.org/wiki/Main_Page"

enum CurrentState {
    State_None      = 0,
    State_Recording = 1,
    State_Pause = 2,
    State_waitToRecord = 3,
};

@interface UIAlertView (AlertViewWithAutoDismiss)

- (void)showAndDismissAfter:(NSTimeInterval)seconds;
- (void)dismissWithTimer:(NSTimer *)timer;
@end

@implementation UIAlertView (AlertViewWithAutoDismiss)

- (void)showAndDismissAfter:(NSTimeInterval)seconds{
    [self show];
    [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(dismissWithTimer:) userInfo:nil repeats:NO];
}
- (void)dismissWithTimer:(NSTimer *)timer{
    [self dismissWithClickedButtonIndex:-1 animated:YES];
}

@end

@interface ScanViewController ()<CameraEngineDataSource, FPPopoverControllerDelegate, ScanFaceDetectedViewControllerDelegate,AVAudioPlayerDelegate>
{
    dispatch_queue_t _faceDetectQueue;
    
    CGFloat beginGestureScale;
	CGFloat effectiveScale;
    CGRect ivSmallRect;
}

@property (assign, nonatomic) enum CurrentState state;
@property (assign, nonatomic) CGPoint lastPoint;
@property (assign, nonatomic) BOOL isShowingCaptureAlert;
@property (assign, nonatomic) BOOL isNeedDetect;
@property (assign, nonatomic) BOOL isNeedCaptureFace;
@property (assign, nonatomic) NSInteger secondRemaining;

@property (strong, nonatomic) NSThread *threadDetect;
@property (strong, nonatomic) NSTimer *captureTimer;
@property (strong, nonatomic) NSTimer *remainingTimer;
@property (strong, nonatomic) CIDetector *detector;
@property (strong, nonatomic) CIImage *facesImage;
@property (strong, nonatomic) NSDate *lastAlertDate;
@property (strong, nonatomic) AVAudioPlayer *alertSound;
@property (strong, nonatomic) Video *currentVideo;
@property (strong, nonatomic) UIImage *lastImage;
@property (strong, nonatomic) FPPopoverController *fpPopoverController;
@property (weak, nonatomic) IBOutlet UIButton *switchCameraButton;
@property (weak, nonatomic) IBOutlet UILabel *lblState;


@property (weak, nonatomic) IBOutlet UIImageView *containtView;
@property (weak, nonatomic) IBOutlet UIImageView *arrowTopImageView;
@property (weak, nonatomic) IBOutlet UIImageView *arrowLeftImageView;
@property (weak, nonatomic) IBOutlet UIImageView *arrowRightImageView;
@property (weak, nonatomic) IBOutlet UIImageView *arrowBottomImageView;
@property (weak, nonatomic) IBOutlet UIView *viewForButton;
@property (weak, nonatomic) IBOutlet UICustomRecordButtonBase *pauseButton;// Pause/Resume
@property (weak, nonatomic) IBOutlet UICustomRecordButtonBase *playButton;
@property (weak, nonatomic) IBOutlet UICustomRecordButtonBase *normalButton;

- (void)faceDetectThreadRunloop;
- (void)capture;
- (void)calculatorTimeRemaining:(NSTimer *)timer;
- (void)cameraEngineHaveCaptureImage:(NSNotification *)notification;
- (void)tapHandler:(UITapGestureRecognizer *)tapGesture;
- (IBAction)normalButtonAction:(id)sender;
- (IBAction)switchCameraAction:(id)sender;

@end

@implementation ScanViewController

#pragma mark - Go to ViewControllers

#pragma mark - View lifecyle

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.pauseButton pause];
    [self.normalButton minimize];
    
    [self.containtView setTransform:CGAffineTransformMakeScale(1, -1)];
    [self.imageView setTransform:CGAffineTransformMakeScale(1, -1)];
    
//    _faceDetectQueue = dispatch_queue_create("com.nguyenhunga5.facedetect", 0);
    
    self.detector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyLow forKey:CIDetectorAccuracy]];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandler:)];
    [_containtView addGestureRecognizer:tap];
    tap = nil;
    
    effectiveScale = 1.0;
    [self installCamera];
    
    [_webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:FAKE_WEBSITE]]];

}


- (void)tapHandler:(UITapGestureRecognizer *)tapGesture{
    
    return;
    CGPoint p = [tapGesture locationInView:_containtView];
    
    p.y = _containtView.bounds.size.height - p.y;
    
    [[CameraEngine engine] focusAtPoint:p];
    
}

- (IBAction)normalButtonAction:(id)sender {
    [self goNormal];
}

- (IBAction)switchCameraAction:(id)sender {
    [[CameraEngine engine] changeCamera];
}

- (void)faceDetectThreadRunloop{
    
    @autoreleasepool {
        while ([[NSThread currentThread] isCancelled] == NO) {
            @autoreleasepool {
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantFuture]];
            }
        }
        
        NSLog(@"Exit thread detect!");
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)installCamera {
    
    [self.remainingTimer invalidate];
    self.remainingTimer = nil;
    
    effectiveScale = 1.0f;
    [[CameraEngine engine] setDataSource:self];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kKeyHaveCaptureImage object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraEngineHaveCaptureImage:) name:kKeyHaveCaptureImage object:nil];
    
    
    [_playButton stopRecording];
    
    [_pauseButton setEnabled:NO];
    
    self.state = State_None;
    if (_isMinimizedMode == NO) {
        AVCaptureVideoPreviewLayer* preview = [[CameraEngine engine] getPreviewLayer];
        [preview removeFromSuperlayer];
        preview.frame = self.containtView.bounds;
        [[preview connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];
        [preview setTransform:CATransform3DMakeAffineTransform(CGAffineTransformMakeScale(effectiveScale, -effectiveScale))];
        [self.imageView.layer addSublayer:preview];
//        [self goNormal];
    }
    
//    [_switchCameraButton setHidden:NO];
}

- (void)viewWillAppear:(BOOL)animated{
    [self.view becomeFirstResponder];
    [super viewWillAppear:animated];
    if (!_isMinimizedMode) {
//        [[CameraEngine engine] performSelector:@selector(addAudio) withObject:nil afterDelay:.5f];
    }
    self.isNeedDetect = YES;
    self.isShowingCaptureAlert = NO;
    
    [self.threadDetect cancel];
    self.threadDetect = nil;
    self.threadDetect = [[NSThread alloc] initWithTarget:self selector:@selector(faceDetectThreadRunloop) object:nil];
    [_threadDetect start];
    
    self.captureTimer = [NSTimer scheduledTimerWithTimeInterval:.1f target:self selector:@selector(capture) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated{
    [self.view resignFirstResponder];
    [super viewWillDisappear:animated];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:kKeyHaveCaptureImage object:nil];
    self.isNeedDetect = NO;
    [self.captureTimer invalidate];
    self.captureTimer = nil;
    
    if (_state != State_None) {
        [self playButtonAction:nil];
    }
//    [[CameraEngine engine] removeAudio];
    [self.threadDetect cancel];
    self.threadDetect = nil;
    
}

- (void)scheduleLabelAnimation
{
    [_lblState setAlpha:0.0];
    [UIView animateWithDuration:0.7 delay:0.0 options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
                    animations:^{
    [_lblState setAlpha:1.0]; } completion:nil];
    
}


- (void)setState:(enum CurrentState)state
{
    _state = state;
    
    if (!_isMinimizedMode)
        return;
    
    switch (state) {
        case State_None:
            _lblState.hidden = YES;
            _lblState.text = nil;
            break;
        case State_Recording:
            _lblState.hidden = FALSE;
            _lblState.text = @"Recording Video";
            
            [self scheduleLabelAnimation];
            
            break;
        case State_Pause:
            _lblState.hidden = FALSE;
            _lblState.text = @"Paused";
            
            [self scheduleLabelAnimation];
            
            break;
        case State_waitToRecord:
            _lblState.hidden = FALSE;
            _lblState.text = @"Searching faces";
            
            [self scheduleLabelAnimation];
            break;
        default:
            break;
    }
    
}

- (void)capture{
    if (_isNeedDetect) {
        [[CameraEngine engine] takePicture];
    }
    
}

- (IBAction)buttonMinimize_tapped:(id)sender
{
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;

    
    CGRect frame_ = app.window.frame;
    CGRect toolbarFrame_ = app.toolbar.frame;
    CGRect statusFrame_ = [UIApplication sharedApplication].statusBarFrame;
    
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.75f];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    
    if (isIOS7)
    {
        app.toolbar.frame = CGRectMake(toolbarFrame_.origin.x, frame_.size.height, toolbarFrame_.size.width, toolbarFrame_.size.height);
    }
    else
    {
        app.toolbar.frame = CGRectMake(toolbarFrame_.origin.x, frame_.size.height + statusFrame_.size.height, toolbarFrame_.size.width, toolbarFrame_.size.height);
    }
    
    CGRect viewForButtonRect = _viewForButton.frame;
    viewForButtonRect.origin.y = frame_.size.height - viewForButtonRect.size.height;
    
    if (isIOS7 == NO) {
        viewForButtonRect.origin.y -= statusFrame_.size.height;
    }
    
    viewForButtonRect.origin.x = frame_.size.width - viewForButtonRect.size.width;
    _viewForButton.frame = viewForButtonRect;
    
    [UIView commitAnimations];
}

#pragma mark Camera
- (IBAction)pauseButtonAction:(id)sender{
    if (_state == State_Recording) {
        [[CameraEngine engine] pauseCapture];
        [self setState:State_Pause];
        [self.remainingTimer invalidate];
        self.remainingTimer = nil;
    } else {
        [[CameraEngine engine] resumeCapture];
        [self setState:State_Recording];
        self.remainingTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(calculatorTimeRemaining:) userInfo:nil repeats:YES];
    }
}
- (IBAction)playButtonAction:(id)sender{
    
    if (_state == State_None) {
#if LiteVersion == 1
        AppDelegate *app = [AppDelegate instance];
        
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *dateComponents = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:[NSDate date]];
        NSDate *startDate = [calendar dateFromComponents:dateComponents];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"date >= %@", startDate];
        
        // Create the fetch request for the entity.
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        // Edit the entity name as appropriate.
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Video" inManagedObjectContext:app.managedObjectContext];
        [fetchRequest setEntity:entity];
        
        [fetchRequest setPredicate:predicate];
        
        NSArray *arr = [app.managedObjectContext executeFetchRequest:fetchRequest error:nil];
        
        if ([arr count] > LITE_MAX_VIDEO) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Face Spy lite" message:@"This's free version, please download the full one" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
            [alertView showAndDismissAfter:5];
            return;
        }
#endif
        if (_isMinimizedMode) {

            [self setState:State_waitToRecord];
            if (_sfdvc == nil) {
                self.sfdvc = [[ScanFaceDetectedViewController alloc] init];
                _sfdvc.delegate = self;
                
            }
            
            CGPoint point = _viewForButton.frame.origin;
            point.x -= 60;
            
            [_sfdvc showFindingFromView:self.view atPoint:point];
        } else {
            [_switchCameraButton setHidden:YES];
            [_pauseButton setEnabled:YES];
            [self setState:State_Recording];
            [[CameraEngine engine] startCapture];
        }
        
        [_playButton record];
        
    } else {
        [_playButton stopRecording];
        
        
        
        [self.remainingTimer invalidate];
        self.remainingTimer = nil;
        
        if (_state == State_waitToRecord) {
            [_sfdvc removeFindingView];
            _isNeedCaptureFace = NO;
            _isShowingCaptureAlert = NO;
            self.lastAlertDate = nil;
            [self setState:State_None];
            return;
        }
        
        [self setState:State_None];
        [[CameraEngine engine] stopCapture];
        [_pauseButton setEnabled:NO];
        
        self.lastPoint = CGPointZero;
        self.lastAlertDate = [NSDate date];
        [FaceSpyHelper getInfoOfVideo:_currentVideo];
       
        [[[AppDelegate instance] managedObjectContext] save:nil];
        self.currentVideo = nil;
        
        if (_isMinimizedMode) {
//            [[CameraEngine engine] removeAudio];
        }
        
        [_switchCameraButton setHidden:NO];
    }
    
}

- (void)calculatorTimeRemaining:(NSTimer *)timer{
    
    _secondRemaining --;
    if (_secondRemaining == 0) {
        [self playButtonAction:nil];
        [self.remainingTimer invalidate];
        self.remainingTimer = nil;
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Face Spy lite" message:@"This's free version, please download the full one" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        [alertView showAndDismissAfter:5];
        
    }
}

- (void)cameraEngineStartupComplete:(CameraEngine *)cameraEngine{
//    [self performSelectorOnMainThread:@selector(installCamera) withObject:nil waitUntilDone:NO];
}

- (NSString *)tempFolderPathForCameraEngine:(CameraEngine *)cameraEngine{
    return [[[AppDelegate instance] videoURL] relativePath];
}

- (void)cameraEngine:(CameraEngine *)cameraEngine beginRecordFileAtPath:(NSString *)filePath{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Begin Record: %@", filePath);
        AppDelegate *app = [AppDelegate instance];
        Video *video = [NSEntityDescription insertNewObjectForEntityForName:@"Video" inManagedObjectContext:app.managedObjectContext];
        if (video) {
            self.currentVideo = video;
            
            video.date = [NSDate date];
            video.fileName = [filePath lastPathComponent];
            
            if (_isMinimizedMode) {
                
                UIImage *faceImage = _sfdvc.imageView.image;
                if (faceImage) {
                    
                    NSData *imageData = UIImagePNGRepresentation(faceImage);
                    NSString *fileName = [[self.currentVideo.fileName stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
                    
                    if (fileName == nil || [FaceSpyHelper checkImageIsBlack:faceImage]) {
                        _isNeedCaptureFace = YES;
                    } else {
                        NSURL *fileURL = [[[AppDelegate instance] thumbnailURL] URLByAppendingPathComponent:fileName];
                        
                        if (fileURL && [imageData writeToURL:fileURL atomically:YES]) {
                            self.currentVideo.thumbnail = fileName;
                        }
                    }
                    
                    
                }
                
            } else {
                self.isNeedCaptureFace = YES;
            }
            
            [app.managedObjectContext save:nil];
            
            
            
            video = nil;
            
#if LiteVersion == 1
            CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^{
                _secondRemaining = TIME_REMAINING;
                self.remainingTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(calculatorTimeRemaining:) userInfo:nil repeats:YES];
            });
#endif
            
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Cannot create video, please try again!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            alert = nil;
        }
    });
    
}

- (void)closeAlertView:(UIAlertView *)alertView{
    self.lastAlertDate = [NSDate date];
    [alertView dismissWithClickedButtonIndex:-1 animated:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    self.lastAlertDate = [NSDate date];
    self.isShowingCaptureAlert = NO;
    
    if (buttonIndex == 1) {
        [self playButtonAction:nil];
    }
    
}

- (void)startRecordWithMinimizedMode{
    [_sfdvc removeFindingView];
    [_switchCameraButton setHidden:YES];
    [_pauseButton setEnabled:YES];
   [self setState:State_Recording];
    [[CameraEngine engine] startCapture];
}

- (void)scanFaceDetectedViewControllerDidSelectedAtIndex:(NSInteger)index{
    self.lastAlertDate = [NSDate date];
    self.isShowingCaptureAlert = NO;
    
    if (index == 1) {
        [self startRecordWithMinimizedMode];
    } else {
        _isShowingCaptureAlert = NO;
        self.lastAlertDate = [NSDate date];
        
        CGPoint point = _viewForButton.frame.origin;
        point.x -= 60;
        
        [_sfdvc showFindingFromView:self.view atPoint:point];
    }
}

//static BOOL isCanPlayAudio = NO;

- (void)playSound{
    @autoreleasepool {

        if (!self.alertSound.isPlaying)
        {
            NSURL* musicFile = [NSURL fileURLWithPath:[[NSBundle mainBundle]
                                                   pathForResource:@"shutter"
                                                   ofType:@"wav"]];
            [self.alertSound stop];
            self.alertSound = [[AVAudioPlayer alloc] initWithContentsOfURL:musicFile error:nil];
            self.alertSound.delegate = self;
            [self.alertSound prepareToPlay];
            [self.alertSound play];
        }
        
       /* if (isCanPlayAudio) {
            [self performSelector:@selector(playSound) withObject:nil afterDelay:.5f];
        }
        isCanPlayAudio = !isCanPlayAudio;*/
        
    }
}

- (UIImage *)extrackFaceImage:(CIFaceFeature *)faceFeature needImage:(CIImage *)needImage scale:(CGFloat)scale {
    
    CGRect faceRect = faceFeature.bounds;
//    faceRect.origin.x /= scale;
//    faceRect.origin.y /= scale;
//    faceRect.size.width /= scale;
//    faceRect.size.height /= scale;
    
    needImage = [needImage imageByCroppingToRect:faceRect];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef ref = [context createCGImage:needImage fromRect:needImage.extent];
    
    UIImage *faceImage = [UIImage imageWithCGImage:ref];
    CGImageRelease(ref);
    return faceImage;
}

- (void)calculatorLostFaceArrows:(CGRect)contentRect features:(NSArray *)features {
    [_arrowBottomImageView setHidden:YES];
    [_arrowTopImageView  setHidden:YES];
    [_arrowLeftImageView  setHidden:YES];
    [_arrowRightImageView  setHidden:YES];
    
    if (_isMinimizedMode && _state == State_Recording) {
        if ([features count] == 0) {
            if (_lastPoint.x == 0 && _lastPoint.y == 0) {
                
            } else {
                if (_lastPoint.y > contentRect.size.height / 2) {
                    if (_lastPoint.y >= contentRect.size.height - MIN_DETECT_LOST) {
                        [_arrowTopImageView setHidden:NO];
                    }
                } else {
//                    if (_lastPoint.y <= MIN_DETECT_LOST) {
                        [_arrowBottomImageView setHidden:NO];
//                    }
                }
                
                if (_lastPoint.x < contentRect.size.width / 2) {
//                    if (_lastPoint.x <= MIN_DETECT_LOST) {
                        [_arrowLeftImageView setHidden:NO];
//                    }
                } else {
                    if (_lastPoint.x >= contentRect.size.width - MIN_DETECT_LOST) {
                        [_arrowRightImageView setHidden:NO];
                    }
                }
            }
            
            
        }
    }
}

- (void)setThumbnailNameForVideo:(NSString *)fileName {
    self.currentVideo.thumbnail = fileName;
    [[AppDelegate instance].managedObjectContext save:nil];
}

- (void)createFaceViewWithRectStr:(NSString *)rectStr{
    @autoreleasepool {
        CGRect rect = CGRectFromString(rectStr);
        FaceView* faceView = [[FaceView alloc] initWithFrame:rect];
        
        faceView.tag = FACE_RECT_TAG;
        [self.imageView addSubview:faceView];
        faceView = nil;
    }
}

- (void)processFaces:(NSArray *)features scale:(CGFloat)scale ciimage:(CIImage *)needImage{
    @autoreleasepool {
        CGRect contentRect = _containtView.bounds;
        
            [self calculatorLostFaceArrows:contentRect features:features];
            
            
            for (UIView *view in self.imageView.subviews) {
                if (view.tag == FACE_RECT_TAG) {
                    [view performSelectorOnMainThread:@selector(removeFromSuperview) withObject:nil waitUntilDone:NO];
                }
            }
        
        CGRect faceRect;
        
        CGFloat fixX, fixY;
        
        fixY = ((needImage.extent.size.height * scale * effectiveScale) - contentRect.size.height) / 2.0f;
        fixX = ((needImage.extent.size.width * scale * effectiveScale) - contentRect.size.width) / 2.0f;
        
        for (CIFaceFeature *faceFeature in features) {
            // get the width of the face
            NSLog(@"Have face at: %@ with ID: %d:", NSStringFromCGRect(faceFeature.bounds), faceFeature.trackingID);
            
            
            faceRect = faceFeature.bounds;
            
            
            faceRect.size.height *= scale * effectiveScale;
            faceRect.size.width *= scale * effectiveScale;
            faceRect.origin.x *= scale * effectiveScale;
            faceRect.origin.y *= scale * effectiveScale;
            
            
            // Fix origin
            faceRect.origin.x -= fixX;
            faceRect.origin.y -= fixY;
            
            self.lastPoint = faceRect.origin;
            
            if (_isNeedCaptureFace && _currentVideo) {
                _isNeedCaptureFace = NO;
                
                UIImage *faceImage;
                faceImage = [self extrackFaceImage:faceFeature needImage:needImage scale:scale];
                needImage = nil;
//                originImage = nil;
                if (faceImage) {
                    
                        NSData *imageData = UIImagePNGRepresentation(faceImage);
                        NSString *fileName = [[self.currentVideo.fileName stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
                        
                        if (fileName == nil || [FaceSpyHelper checkImageIsBlack:faceImage]) {
                            _isNeedCaptureFace = YES;
                        } else {
                            NSURL *fileURL = [[[AppDelegate instance] thumbnailURL] URLByAppendingPathComponent:fileName];
                            
                            if (fileURL && [imageData writeToURL:fileURL atomically:YES]) {
                                [self performSelectorOnMainThread:@selector(setThumbnailNameForVideo:) withObject:fileName waitUntilDone:NO];
                            }
                        }
                }
            }
            
            if (_isMinimizedMode == NO) {
                // create a UIView using the bounds of the face
                [self performSelectorOnMainThread:@selector(createFaceViewWithRectStr:) withObject:NSStringFromCGRect(faceRect) waitUntilDone:NO];

            } else {
                
                
                
                NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
                
                if (_state == State_waitToRecord) {
                    
                    NSDate *compareDate = [self.lastAlertDate dateByAddingTimeInterval:TEN_SECOND];
                    if ((compareDate == nil || [compareDate compare:[NSDate date]] == NSOrderedAscending)) {
                       
                        [[CameraEngine engine] takePicture:nil];
                            
                            {
                                [self performSelectorOnMainThread:@selector(playSound) withObject:nil waitUntilDone:NO];
                                
                            }
                        
                            if ([userDefault boolForKey:kKeyFaceDetectVibration]) {
                                //AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
                                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                            }
                        
                        self.lastAlertDate = [NSDate date];
                        
                        
                        
                        UIImage *faceImage;
                        faceImage = [self extrackFaceImage:faceFeature needImage:needImage scale:scale];
                        
//                        originImage = nil;
                        if (faceImage == nil) {
                            return;
                        }

                        [_sfdvc.imageView performSelectorOnMainThread:@selector(setImage:) withObject:faceImage waitUntilDone:NO];
                        
                        if (self.isShowingCaptureAlert == NO ) {
                            if ([userDefault boolForKey:kKeyFaceDetectAlert]) {
                            
                                [_sfdvc performSelectorOnMainThread:@selector(showAlertFromView:) withObject:[[AppDelegate instance] window] waitUntilDone:NO];
                                
                                self.isShowingCaptureAlert = YES;
                            } else {
                                [self performSelectorOnMainThread:@selector(startRecordWithMinimizedMode) withObject:nil waitUntilDone:NO];
                            }
                            
                            
                        }
                        
                    }
                }
            }
            
            
            
            
        }
        
     
    }
}

- (void)faceDetectWithCIImage:(CIImage *)image {
    @autoreleasepool {
        _isNeedDetect = NO;
        if (_facesImage == nil) {
            _isNeedDetect = YES;
            return;
        }
        
        self.facesImage = [self.facesImage imageByApplyingTransform:CGAffineTransformMakeScale(effectiveScale, effectiveScale)];
        
//        CIFilter *scaleFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
//        [scaleFilter setValue:self.facesImage forKey:@"inputImage"];
//        [scaleFilter setValue:[NSNumber numberWithFloat:effectiveScale] forKey:@"inputScale"];
//        [scaleFilter setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputAspectRatio"];
//        self.facesImage = [scaleFilter valueForKey:@"outputImage"];
        
        CGRect imageRect = self.facesImage.extent;
        
        CGRect contentRect = _containtView.bounds;
        CGFloat scale = contentRect.size.width / (float)imageRect.size.width;
        
        NSArray *features = [_detector featuresInImage:self.facesImage];
        NSMutableArray *faces = [NSMutableArray array];
        [features enumerateObjectsUsingBlock:^void(CIFeature *obj, NSUInteger idx, BOOL *stop)
        {
            if ([obj.type isEqualToString:CIFeatureTypeFace])
            {
                /*if (!faces.count)
                {
                    if (!self.shutterId)
                    {
                        NSURL *buttonURL = [[NSBundle mainBundle] URLForResource:@"shutter" withExtension:@"wav"];
                        AudioServicesCreateSystemSoundID((__bridge CFURLRef)buttonURL, &_shutterId);
                    
                    
                        AudioServicesAddSystemSoundCompletion(self.shutterId, NULL, NULL, &StopAudioProc, (__bridge void *)(self));
                    }
                    AudioServicesPlaySystemSound(self.shutterId);
                }*/
                [faces addObject:obj];
            }
        }];
        
        
        
        [self processFaces:faces scale:scale ciimage:self.facesImage];

        
        self.facesImage = nil;

        _isNeedDetect = YES;
    }
}


/*void StopAudioProc (
                                         SystemSoundID  ssID,
                                         void           *clientData
                                         )
{
    AudioServicesRemoveSystemSoundCompletion(ssID);
    AudioServicesDisposeSystemSoundID(ssID);
    ScanViewController *vc = (__bridge ScanViewController *)clientData;
    if (ssID == vc.shutterId)
    {
        vc.shutterId =0;
    }
}*/

- (void)cameraEngineCaptureImage:(CIImage *)ciImage{
    
}

- (void)cameraEngineHaveCaptureImage:(NSNotification *)notification{
    self.facesImage = notification.object;
    [self performSelector:@selector(faceDetectWithCIImage:) onThread:_threadDetect withObject:nil waitUntilDone:NO];
    
}
#pragma mark -

#pragma mark Switch Mode
- (void)goMinimized{
    
    //[_imageView setHidden:YES];
    ivSmallRect = _imageView.frame;
    CGSize size = CGSizeMake(roundf(100*CGRectGetWidth(ivSmallRect)/CGRectGetHeight(ivSmallRect)), 100);
    CGRect minRect = CGRectMake(roundf(CGRectGetMidX(_imageView.bounds)-size.width*0.5), roundf(CGRectGetMidY(_imageView.bounds)-size.height*0.5),size.width, size.height);
    
    _imageView.frame = minRect;
    
    [_imageView.layer.sublayers enumerateObjectsUsingBlock:^(CALayer *layer, NSUInteger idx, BOOL *stop)
    {
        if ([layer isKindOfClass:[AVCaptureVideoPreviewLayer class]])
        {
            layer.frame = _imageView.bounds;
        }
        else
        {
            CGRect oldRect = layer.frame;
            CGFloat wCoeff = CGRectGetWidth(ivSmallRect)/CGRectGetWidth(minRect);
            CGFloat hCoeff = CGRectGetHeight(ivSmallRect)/CGRectGetHeight(minRect);
            oldRect.size.width*=wCoeff;
            oldRect.size.height*=hCoeff;
            
            oldRect.origin.x *=wCoeff;
            oldRect.origin.y*=hCoeff;
            
            oldRect = CGRectIntegral(oldRect);
            layer.frame = oldRect;
        }
    }];
    
    //[_imageView.layer.sublayers.lastObject setFrame: _imageView.bounds];
    
    if (_sfdvc == nil) {
        self.sfdvc = [[ScanFaceDetectedViewController alloc] init];
        _sfdvc.delegate = self;
        
    }
    [self buttonMinimize_tapped:nil];
    self.isMinimizedMode = YES;
    self.isNeedCaptureFace = NO;
    for (UIView *view in self.containtView.subviews) {
        if (view.tag == FACE_RECT_TAG) {
            [view removeFromSuperview];
        }
    }
}
- (void)goNormal{
    
    if (_isMinimizedMode == NO) {
        return;
    }
    [_lblState setHidden:YES];
    //[_imageView setHidden:NO];
    NSLog(@"Restoring frame %@",NSStringFromCGRect(ivSmallRect));
    if (!CGRectEqualToRect(ivSmallRect, CGRectZero))
    {
        CGRect minRect =_imageView.frame;
        _imageView.frame = ivSmallRect;
        
        [_imageView.layer.sublayers enumerateObjectsUsingBlock:^(CALayer *layer, NSUInteger idx, BOOL *stop)
         {
             if ([layer isKindOfClass:[AVCaptureVideoPreviewLayer class]])
             {
                 layer.frame = _imageView.bounds;
             }
             else
             {
                 CGRect oldRect = layer.frame;
                 CGFloat wCoeff = CGRectGetWidth(ivSmallRect)/CGRectGetWidth(minRect);
                 CGFloat hCoeff = CGRectGetHeight(ivSmallRect)/CGRectGetHeight(minRect);
                 oldRect.size.width*=wCoeff;
                 oldRect.size.height*=hCoeff;
                 
                 oldRect.origin.x*=wCoeff;
                 oldRect.origin.y*=hCoeff;
                 oldRect = CGRectIntegral(oldRect);
                 layer.frame = oldRect;
             }
         }];
        
        
        ivSmallRect = CGRectZero;
    }

    if (_state == State_waitToRecord) {
        [_sfdvc removeFindingView];
        [self playButtonAction:nil];
    }
    
    self.sfdvc = nil;
    
    self.isMinimizedMode = NO;
    self.lastAlertDate = nil;
    
    CGRect frame_ = self.view.frame;
    AppDelegate *appDelegate_ = (AppDelegate *) [UIApplication sharedApplication].delegate;
    
    [appDelegate_.toolbar moveSelectedMaskToItem:[[appDelegate_.toolbar items] objectAtIndex:3]];
    
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
    
    CGRect viewForButtonRect = _viewForButton.frame;
    viewForButtonRect.origin.y -= viewForButtonRect.size.height;
    
    if (isIOS7 == NO) {
        viewForButtonRect.origin.y += statusFrame_.size.height;
    }
    
    viewForButtonRect.origin.x += viewForButtonRect.size.width - (_pauseButton.frame.origin.x + _pauseButton.frame.size.width);
    
    _viewForButton.frame = viewForButtonRect;
    
    [appDelegate_.toolbar setTransparentWithAlpha:.1f];
    
    [UIView commitAnimations];
}
#pragma mark -

#pragma mark Shake
- (void)viewWithShakeDetected{
    switch (_state) {
        case State_Recording:
            [self pauseButtonAction:nil];
            break;
            
        case State_Pause:
            [self playButtonAction:nil];
            break;
        case State_None:
        {
            [[CameraEngine engine] shutdown];
            exit(0);
        }
            break;
            
        default:
            break;
    }
}
#pragma makr -

#pragma mark zoom
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
	if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
		beginGestureScale = effectiveScale;
	}
	return YES;
}



- (IBAction)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer{
//    [[CameraEngine engine] setVideoScale:beginGestureScale * recognizer.scale];

     effectiveScale = beginGestureScale * recognizer.scale;
     if (effectiveScale < 1.0)
         effectiveScale = 1.0;
     
     if (effectiveScale > MaxScaleAndCropFactor)
     effectiveScale = MaxScaleAndCropFactor;
     
     AVCaptureVideoPreviewLayer* preview = [[CameraEngine engine] getPreviewLayer];
     
     [CATransaction begin];
     [CATransaction setAnimationDuration:.025];
     [preview setAffineTransform:CGAffineTransformMakeScale(effectiveScale, -effectiveScale)];
     [CATransaction commit];

    
}
#pragma mark -


- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    self.alertSound = nil;
}

@end
