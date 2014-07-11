//
//  GUCCollectionViewDataSource.h
//  Creative Hub
//
//  Created by 顾超 on 14-7-11.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^CollectionViewCellConfigureBlock)(id cell, id item);

@interface GUCCollectionViewDataSource : NSObject <UICollectionViewDataSource>

- (instancetype)initWithItems:(NSArray *)anItems
     cellIdentifier:(NSString *)aCellIdentifier
 configureCellBlock:(CollectionViewCellConfigureBlock)aConfigureCellBlock;

- (id)itemAtIndexPath:(NSIndexPath *)indexPath;

@end
