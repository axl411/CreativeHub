//
//  GUCSketchSaveDetail.h
//  Creative Hub
//
//  Created by 顾超 on 14-7-10.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GUCSketchSave;

@interface GUCSketchSaveDetail : NSManagedObject

@property (nonatomic, retain) NSData * image;
@property (nonatomic, retain) NSNumber * viewTag;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) GUCSketchSave *save;

@end
