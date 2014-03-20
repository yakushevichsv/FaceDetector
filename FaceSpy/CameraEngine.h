//
//  CameraEngine.h
//  Encoder Demo
//
//  Created by Geraint Davies on 19/02/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import <Foundation/Foundation.h>
#import "AVFoundation/AVCaptureSession.h"
#import "AVFoundation/AVCaptureOutput.h"
#import "AVFoundation/AVCaptureDevice.h"
#import "AVFoundation/AVCaptureInput.h"
#import "AVFoundation/AVCaptureVideoPreviewLayer.h"
#import "AVFoundation/AVMediaFormat.h"

#define kKeyHaveCaptureImage        @"kKeyHaveCaptureImage"
#define MaxScaleAndCropFactor   10.0f

@protocol CameraEngineDataSource;
@interface CameraEngine : NSObject

@property (weak, atomic)id<CameraEngineDataSource>dataSource;
@property (assign, atomic) CGFloat scale;

+ (CameraEngine*) engine;

- (void) startup;
- (void) shutdown;
- (AVCaptureVideoPreviewLayer*) getPreviewLayer;

- (void) startCapture;
- (void) pauseCapture;
- (void) stopCapture;
- (void) resumeCapture;

- (void)takePicture;
- (IBAction)takePicture:(id)sender;
- (void) focusAtPoint:(CGPoint)point;
- (void)addAudio;
- (void)removeAudio;
- (void)changeCamera;
- (void)setVideoScale:(CGFloat)scale;

@property (atomic, readwrite) BOOL isCapturing;
@property (atomic, readwrite) BOOL isPaused;
@property (strong, nonatomic) NSThread *faceDetectThread;
@property (assign, nonatomic) BOOL isFrontCamera;

@end

@protocol CameraEngineDataSource <NSObject>
- (void)cameraEngineStartupComplete:(CameraEngine *)cameraEngine;
- (NSString *)tempFolderPathForCameraEngine:(CameraEngine *)cameraEngine;
- (void)cameraEngine:(CameraEngine *)cameraEngine beginRecordFileAtPath:(NSString *)filePath;
- (void)cameraEngineCaptureImage:(CIImage *)ciImage;

@end