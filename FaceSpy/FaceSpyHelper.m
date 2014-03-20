//
//  FaceSpyHelper.m
//  FaceSpy
//
//  Created by Nguyen Thanh Hung on 10/12/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "FaceSpyHelper.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "AppDelegate.h"

@implementation FaceSpyHelper

+ (void)getInfoOfVideo:(Video *)video{
    @synchronized(self){
        @autoreleasepool {
            if (video == nil) {
                return;
            }
            NSString *videoPath = [[[[AppDelegate instance] videoURL] URLByAppendingPathComponent:video.fileName] relativePath];
            
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:videoPath] == NO) {
                return;
            }
            
            NSDictionary *attribute = [fileManager attributesOfItemAtPath:videoPath error:nil];
            NSNumber *size = [attribute valueForKey:NSFileSize];
            
            video.size = size;
            
            NSURL *sourceMovieURL = [NSURL fileURLWithPath:videoPath];
            AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:sourceMovieURL options:nil];
            CMTime duration = sourceAsset.duration;
            
            
            video.duration = [NSNumber numberWithInt:CMTimeGetSeconds(duration)];
            
            NSError *error = nil;
            if (![[AppDelegate instance].managedObjectContext save:&error]) {
                NSLog(@"Get info fail: %@", error);
            }
            
        }
    }
}

+ (void)getThumbnailWithFirstFrameofVideo:(Video *)video{
    @autoreleasepool {
        
        if (video == nil) {
            return;
        }
        
        AppDelegate *app = [AppDelegate instance];
        NSURL *url = [[app videoURL] URLByAppendingPathComponent:video.fileName];
        
        if (url == nil) {
            return;
        }
        
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
        AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        gen.appliesPreferredTrackTransform = YES;
        CMTime time = CMTimeMakeWithSeconds(1.0, 600);
        NSError *error = nil;
        CMTime actualTime;
        
        gen.maximumSize = CGSizeMake(60, 60);
        
        CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
        UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
        CGImageRelease(image);
        
        if ([self checkImageIsBlack:thumb]) {
            video.thumbnail = kKeyVideoInfoNoFace;
        } else {
            NSString *fileName = [[video.fileName stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
            
            url = [[app thumbnailURL] URLByAppendingPathComponent:fileName];
            if (url) {
                video.thumbnail = fileName;
                [UIImagePNGRepresentation(thumb) writeToURL:url atomically:YES];
            }
        }
        
        [app.managedObjectContext save:nil];
        
    }
}

+ (NSString *)getDurationString:(NSInteger)duration{
    int hour, minutes, second;
    hour = duration / 3600;
    second = (duration % 3600); // Temp store
    minutes =  second / 60;
    second = second % 60;
    
    return [NSString stringWithFormat:@"%02d:%02d:%02d", hour, minutes, second];
}

+ (BOOL)checkImageIsBlack:(UIImage *)image{
    @autoreleasepool {
        
        if (image == nil) {
            return YES;
        }
        
        CFDataRef dataRef = CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
        if (dataRef == nil) {
            return YES;
        }
        
        CGSize size = image.size;
        
        
        const UInt8 *pixels = CFDataGetBytePtr(dataRef);
        UInt8 blackThreshold = 10; // or some value close to 0
        int bytesPerPixel = 4;
        for(int x = 0; x < size.width; x++) {
            for(int y = 0; y < size.height; y++) {
                int pixelStartIndex = (x + (y * size.width)) * bytesPerPixel;
                //UInt8 alphaVal = pixels[pixelStartIndex]; // can probably ignore this value
                UInt8 redVal = pixels[pixelStartIndex + 1];
                UInt8 greenVal = pixels[pixelStartIndex + 2];
                UInt8 blueVal = pixels[pixelStartIndex + 3];
                if(redVal > blackThreshold && blueVal > blackThreshold && greenVal > blackThreshold) {
                    return NO;
                }
            }
        }
        
        return YES;
    }
}

@end
