//
//  PopOverMenuViewControllerDelegate.h
//  FaceSpy
//
//  Created by Siarhei on 10/6/13.
//  Copyright (c) 2013 SYCompany. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HistoryObject.h"

@protocol PopOverMenuViewControllerDelegate <NSObject>

- (void) menuSelected: (NSInteger) menuIndex;

@end
