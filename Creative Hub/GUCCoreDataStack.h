//
//  GUCCoreDataStack.h
//  Creative Hub
//
//  Created by 顾超 on 14-7-10.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GUCCoreDataStack : NSObject

+ (instancetype)defaultStack;

@property(readonly, strong, nonatomic)
    NSManagedObjectContext *managedObjectContext;
@property(readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property(readonly, strong, nonatomic)
    NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
