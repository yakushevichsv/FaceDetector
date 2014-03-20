//
//  CameraEngine.m
//  Encoder Demo
//
//  Created by Geraint Davies on 19/02/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import "CameraEngine.h"
#import "VideoEncoder.h"
#import "AssetsLibrary/ALAssetsLibrary.h"
#import "AppDelegate.h"

static CameraEngine* theEngine;

static const NSString *AVCaptureStillImageIsCapturingStillImageContext = @"AVCaptureStillImageIsCapturingStillImageContext";


@interface CameraEngine  () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
{
    AVCaptureSession* _session;
    
    dispatch_queue_t _captureQueue;
    AVCaptureConnection* _audioConnection;
    AVCaptureConnection* _videoConnection;
    AVCaptureDevice* _backCamera;
    
    AVCaptureStillImageOutput *stillImageOutput;
    
    VideoEncoder* _encoder;
    BOOL _isCapturing;
    BOOL _isPaused;
    BOOL _discont;
    BOOL _isNeedTake;
    long _currentFile;
    CMTime _timeOffset;
    CMTime _lastVideo;
    CMTime _lastAudio;
    
    int _cx;
    int _cy;
    int _channels;
    Float64 _samplerate;
}

@property (strong, nonatomic) AVCaptureVideoPreviewLayer* preview;
@property (strong, nonatomic) NSString *videoSavePath;

@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) AVCaptureVideoDataOutput *videoOut;

@end


@implementation CameraEngine

@synthesize isCapturing = _isCapturing;
@synthesize isPaused = _isPaused;

+ (void) initialize
{
    // test recommended to avoid duplicate init via subclass
    if (self == [CameraEngine class])
    {
        theEngine = [[CameraEngine alloc] init];
    }
}

+ (CameraEngine*) engine
{
    return theEngine;
}

- (void)setSavePath:(NSString *)savePath{
    self.videoSavePath = savePath;
}

- (void) startup
{
    if (_session == nil)
    {
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
            
            _scale = 1;
            NSLog(@"Starting up server");
            
            self.isCapturing = NO;
            self.isPaused = NO;
            _currentFile = 0;
            _discont = NO;
            
            _captureQueue = dispatch_queue_create("com.nguyenhunga5.facedetect", DISPATCH_QUEUE_SERIAL);
            // create capture device with video input
            _session = [[AVCaptureSession alloc] init];
            
            // audio input from default mic
            AVCaptureDevice* mic = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
            AVCaptureDeviceInput* micinput = [AVCaptureDeviceInput deviceInputWithDevice:mic error:nil];
            [_session addInput:micinput];
        
        stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        stillImageOutput.outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
        if ([_session canAddOutput:stillImageOutput]) {
            [_session addOutput:stillImageOutput];
        }
        
            // Create Camera
            [self initCamera];
            
            
            
            NSLog(@"Start up server complete!");
            
            if ([_dataSource respondsToSelector:@selector(cameraEngineStartupComplete:)]) {
                [_dataSource cameraEngineStartupComplete:self];
            }
            
//        });
    }
}

- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

// Find a front facing camera, returning nil if one is not found
- (AVCaptureDevice *) frontFacingCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

- (void)initCamera{
    
    @autoreleasepool {
        [_session stopRunning];
        if (_videoInput) {
            [_session removeInput:_videoInput];
            self.videoInput = nil;
            _backCamera = nil;
            
            [_session removeOutput:_videoOut];
            _videoConnection = nil;
            self.videoOut = nil;
        }
        
        if (self.isFrontCamera) {
            _backCamera = [AVCaptureDevice deviceWithUniqueID:@"com.apple.avfoundation.avcapturedevice.built-in_video:1"];
        } else {
            _backCamera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        }
        
        

        AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:_backCamera error:nil];
        [_session addInput:input];
        self.videoInput = input;
        input = nil;
        
        // create an output for YUV output with self as delegate
        AVCaptureVideoDataOutput* videoout = [[AVCaptureVideoDataOutput alloc] init];
        [videoout setSampleBufferDelegate:self queue:_captureQueue];
        NSDictionary* setcapSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], kCVPixelBufferPixelFormatTypeKey,
                                        nil];
        
        videoout.videoSettings = setcapSettings;
        [_session addOutput:videoout];
        self.videoOut = videoout;
        _videoConnection = [videoout connectionWithMediaType:AVMediaTypeVideo];
        [_videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        [_videoConnection setVideoMirrored:_isFrontCamera];
        // find the actual dimensions used so we can set up the encoder to the same.
        NSDictionary* actual = videoout.videoSettings;
        _cy = [[actual objectForKey:@"Width"] intValue];
        _cx = [[actual objectForKey:@"Height"] intValue];
        if (_cx > _cy) {
            int temp = _cx;
            _cx = _cy;
            _cy = temp;
        }
        
        videoout = nil;
        
        [_session startRunning];
    }
}

- (void)setVideoScale:(CGFloat)scale{
    if (isIOS7) {
        CGFloat maxScale = _backCamera.activeFormat.videoMaxZoomFactor;
        
        if (scale < 1.0f) {
            scale = 1.0f;
        }
        
        if (scale > maxScale) {
            scale = maxScale;
        }
        
        NSError *error;
        [_backCamera lockForConfiguration:&error];
        [_backCamera rampToVideoZoomFactor:scale withRate:.5f];
        [_backCamera unlockForConfiguration];
        
        self.scale = scale;
    }
}

- (void)changeCamera{
    self.isFrontCamera = !_isFrontCamera;
    [self performSelectorInBackground:@selector(initCamera) withObject:nil];
}

- (void)addAudio{
    dispatch_async(_captureQueue, ^{
        for (id obj in [_session outputs]) {
            if ([obj isKindOfClass:[AVCaptureAudioDataOutput class]]) {
                [_session removeOutput:obj];
                break;
            }
        }
        
        AVCaptureAudioDataOutput* audioout = [[AVCaptureAudioDataOutput alloc] init];
        [audioout setSampleBufferDelegate:self queue:_captureQueue];
        [_session addOutput:audioout];
        _audioConnection = [audioout connectionWithMediaType:AVMediaTypeAudio];
    });
}

- (void)removeAudio{
        if (_audioConnection) {
            [_session removeOutput:[_audioConnection output]];
            _audioConnection = nil;
        }
        
}

- (void) startCapture
{
    @synchronized(self)
    {
        dispatch_async(_captureQueue, ^{
            if (!self.isCapturing)
            {
                NSLog(@"Add audio");
                
                dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    [self addAudio];
                });
                
                NSLog(@"starting capture");
                
                // create the encoder once we have the audio params
                _encoder = nil;
                self.isPaused = NO;
                _discont = NO;
                _timeOffset = CMTimeMake(0, 0);
                self.isCapturing = YES;
                
            }
        });
    }
}

- (void) stopCapture
{
    @synchronized(self)
    {
        if (self.isCapturing)
        {
            
            dispatch_async(_captureQueue, ^{
//                [_encoder finishWithCompletionHandler:^{
//                    self.isCapturing = NO;
//                    _encoder = nil;
//                }];
                self.isCapturing = NO;
                [_encoder finishWithCompletionHandler:^
                {
                    _encoder = nil;
                }];
                [self removeAudio];
            });
            
            /*
            NSString* filename = [NSString stringWithFormat:@"capture%ld.mp4", _currentFile];
            NSString* path = [[_dataSource tempFolderPathForCameraEngine:self] stringByAppendingPathComponent:filename];
            NSURL* url = [NSURL fileURLWithPath:path];
            
            
            // serialize with audio and video capture
            
            self.isCapturing = NO;
            dispatch_async(_captureQueue, ^{
                [_encoder finishWithCompletionHandler:^{
                    self.isCapturing = NO;
                    _encoder = nil;
                    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                    [library writeVideoAtPathToSavedPhotosAlbum:url completionBlock:^(NSURL *assetURL, NSError *error){
                        NSLog(@"save completed");
                        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                    }];
                }];
            });
            
             */
        }
    }
}

- (void) pauseCapture
{
    @synchronized(self)
    {
        if (self.isCapturing)
        {
            NSLog(@"Pausing capture");
            self.isPaused = YES;
            _discont = YES;
        }
    }
}

- (void) resumeCapture
{
    @synchronized(self)
    {
        if (self.isPaused)
        {
            NSLog(@"Resuming capture");
            self.isPaused = NO;
        }
    }
}

- (CMSampleBufferRef) adjustTime:(CMSampleBufferRef) sample by:(CMTime) offset
{
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    CMSampleTimingInfo* pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    for (CMItemCount i = 0; i < count; i++)
    {
        pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset);
        pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
    }
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
    free(pInfo);
    return sout;
}

- (void) setAudioFormat:(CMFormatDescriptionRef) fmt
{
    const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmt);
    _samplerate = asbd->mSampleRate;
    _channels = asbd->mChannelsPerFrame;
    
}

- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (_isNeedTake && connection == _videoConnection) {
        _isNeedTake = NO;
        CIImage *image = [self imageFromSampleBuffer2:sampleBuffer];
        if (image) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kKeyHaveCaptureImage object:image];
        }
    }
    BOOL bVideo = YES;
    @synchronized(self)
    {
        
        if (!self.isCapturing  || self.isPaused)
        {
            return;
        }
        if (connection != _videoConnection)
        {
            bVideo = NO;
        }
        if ((_encoder == nil) && !bVideo)
        {
            CMFormatDescriptionRef fmt = CMSampleBufferGetFormatDescription(sampleBuffer);
            [self setAudioFormat:fmt];
            _currentFile = (long)[[NSDate date] timeIntervalSince1970];
            NSString* filename = [NSString stringWithFormat:@"capture%ld.mp4", _currentFile];
            NSString* path = [[_dataSource tempFolderPathForCameraEngine:self] stringByAppendingPathComponent:filename];
            _encoder = [VideoEncoder encoderForPath:path Height:_cy width:_cx channels:_channels samples:_samplerate];
            
            [_dataSource cameraEngine:self beginRecordFileAtPath:path];
        }
        if (_discont)
        {
            if (bVideo)
            {
                return;
            }
            _discont = NO;
            // calc adjustment
            CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            CMTime last = bVideo ? _lastVideo : _lastAudio;
            if (last.flags & kCMTimeFlags_Valid)
            {
                if (_timeOffset.flags & kCMTimeFlags_Valid)
                {
                    pts = CMTimeSubtract(pts, _timeOffset);
                }
                CMTime offset = CMTimeSubtract(pts, last);
                NSLog(@"Setting offset from %s", bVideo?"video": "audio");
                NSLog(@"Adding %f to %f (pts %f)", ((double)offset.value)/offset.timescale, ((double)_timeOffset.value)/_timeOffset.timescale, ((double)pts.value/pts.timescale));
                
                // this stops us having to set a scale for _timeOffset before we see the first video time
                if (_timeOffset.value == 0)
                {
                    _timeOffset = offset;
                }
                else
                {
                    _timeOffset = CMTimeAdd(_timeOffset, offset);
                }
            }
            _lastVideo.flags = 0;
            _lastAudio.flags = 0;
        }
        
        // retain so that we can release either this or modified one
        CFRetain(sampleBuffer);
        
        if (_timeOffset.value > 0)
        {
            CFRelease(sampleBuffer);
            sampleBuffer = [self adjustTime:sampleBuffer by:_timeOffset];
        }
        
        // record most recent time so we know the length of the pause
        CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        CMTime dur = CMSampleBufferGetDuration(sampleBuffer);
        if (dur.value > 0)
        {
            pts = CMTimeAdd(pts, dur);
        }
        if (bVideo)
        {
            _lastVideo = pts;
        }
        else
        {
            _lastAudio = pts;
        }
        
    }
    
    // pass frame to encoder
    [_encoder encodeFrame:sampleBuffer isVideo:bVideo];
    CFRelease(sampleBuffer);
}

- (void) shutdown
{
    NSLog(@"shutting down server");
    [self.preview removeFromSuperlayer];
    self.preview = nil;
    
    if (_session)
    {
        [_session stopRunning];
        _session = nil;
    }
    
    self.isCapturing = NO;
    dispatch_sync(_captureQueue, ^{
        //                [_encoder finishWithCompletionHandler:^{
        //                    self.isCapturing = NO;
        //                    _encoder = nil;
        //                }];
        self.isCapturing = NO;
        [_encoder finishWithCompletionHandler:nil];
        
        _encoder = nil;
    });
    
    dispatch_release(_captureQueue);
}


- (AVCaptureVideoPreviewLayer*) getPreviewLayer
{
    // start capture and a preview layer
    if (_preview == nil) {
        self.preview = [AVCaptureVideoPreviewLayer layerWithSession:_session];
        self.preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _preview;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ( context == (__bridge void *)(AVCaptureStillImageIsCapturingStillImageContext) ) {
		BOOL isCapturingStillImage = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		
		if ( isCapturingStillImage ) {
	
		}
		else {
		
		}
	}
}

- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    
    // Get the number of bytes per row for the pixel buffer
    u_int8_t *baseAddress = (u_int8_t *)malloc(bytesPerRow*height);
    memcpy( baseAddress, CVPixelBufferGetBaseAddress(imageBuffer), bytesPerRow * height     );
    
    // size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    
    //The context draws into a bitmap which is `width'
    //  pixels wide and `height' pixels high. The number of components for each
    //      pixel is specified by `space'
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);
    
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1.0 orientation:UIImageOrientationRight];
    
    free(baseAddress);
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    
    return (image);
}

- (CIImage*)imageFromSampleBuffer2:(CMSampleBufferRef) sampleBuffer;
{
	@autoreleasepool {
        // got an image
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
        CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
        if (attachments)
            CFRelease(attachments);
        return ciImage;
    }
}



- (IBAction)takePicture:(id)sender
{
	// Find out the current orientation and tell the still image output.
	AVCaptureConnection *stillImageConnection = [stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
	
	[stillImageConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
	
    [stillImageOutput setOutputSettings:[NSDictionary dictionaryWithObject:AVVideoCodecJPEG
                                                                    forKey:AVVideoCodecKey]];
	
	[stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection
                                                  completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                                                      if (error) {
                                                          
                                                      }
                                                      else {
                                                          
//                                                          // trivial simple JPEG case
//                                                          NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
//                                                          if (jpegData) {
//                                                              
//                                                              UIImage *image = [UIImage imageWithData:jpegData];
////                                                              [_dataSource cameraEngine:self image:image];
//                                                              image = nil;
//                                                              
//                                                              jpegData = nil;
//                                                          }
                                                          
                                                      }
                                                  }
	 ];
}


- (void)takePicture{
    _isNeedTake = YES;
}

- (void) focusAtPoint:(CGPoint)point

{

    AVCaptureDevice *device = [_videoInput device];
    
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            
            [device setFocusPointOfInterest:point];
            
            [device setFocusMode:AVCaptureFocusModeAutoFocus];
            
            [device unlockForConfiguration];
            
        } else {
        }        
        
    }
    
    [self exposureAtPoint:point];
    
}

- (void) exposureAtPoint:(CGPoint)point {
    AVCaptureDevice *device = [_videoInput device];

    if (device.isExposurePointOfInterestSupported && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.exposurePointOfInterest = point;
            device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
            [device unlockForConfiguration];
        } else {
            
        }
    }
    
}
@end
