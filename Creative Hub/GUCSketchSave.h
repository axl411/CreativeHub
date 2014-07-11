//
//  GUCSketchSave.h
//  Creative Hub
//
//  Created by 顾超 on 14-7-10.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GUCSketchSaveDetail;

@interface GUCSketchSave : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSData * image;
@property (nonatomic, retain) NSSet *details;
@end

@interface GUCSketchSave (CoreDataGeneratedAccessors)

- (void)addDetailsObject:(GUCSketchSaveDetail *)value;
- (void)removeDetailsObject:(GUCSketchSaveDetail *)value;
- (void)addDetails:(NSSet *)values;
- (void)removeDetails:(NSSet *)values;

@end
