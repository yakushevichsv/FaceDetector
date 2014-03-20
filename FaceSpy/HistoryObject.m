//
//  HistoryObject.m
//  FaceSpy
//
//  Created by Siarhei on 10/6/13.
//  Copyright (c) 2013 SYCompany. All rights reserved.
//

#import "HistoryObject.h"

@implementation HistoryObject

- (void)dealloc
{
    self.imagePathStr = nil;
    self.videoLengthStr = nil;
    self.timeStampStr = nil;
}

@end
