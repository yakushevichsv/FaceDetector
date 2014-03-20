//
//  Video.h
//  FaceSpy
//
//  Created by Nguyen Thanh Hung on 10/12/13.
//  Copyright (c) 2013 SYCompany. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Video : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSNumber * size;
@property (nonatomic, retain) NSString * thumbnail;
@property (nonatomic, retain) NSNumber * alreadySave;
@property (nonatomic, retain) NSString * libraryURL;
@property (nonatomic, retain) NSString * fileName;

@end
