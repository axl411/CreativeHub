//
//  GUCCollectionViewDataSource.m
//  Creative Hub
//
//  Created by 顾超 on 14-7-11.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import "GUCCollectionViewDataSource.h"

@interface GUCCollectionViewDataSource ()

@property(nonatomic) NSArray *items;
@property(nonatomic, copy) NSString *cellIdentifier;
@property(nonatomic, copy) CollectionViewCellConfigureBlock configureCellBlock;

@end

@implementation GUCCollectionViewDataSource

- (instancetype)initWithItems:(NSArray *)anItems
               cellIdentifier:(NSString *)aCellIdentifier
           configureCellBlock:
               (CollectionViewCellConfigureBlock)aConfigureCellBlock {
  self = [super init];
  if (self) {
    self.items = anItems;
    self.cellIdentifier = aCellIdentifier;
    self.configureCellBlock = aConfigureCellBlock;
  }
  return self;
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath {
  return self.items[(NSUInteger)indexPath.row];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:
                 (UICollectionView *)collectionView {
  return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
  return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  UICollectionViewCell *cell =
      [collectionView dequeueReusableCellWithReuseIdentifier:self.cellIdentifier
                                                forIndexPath:indexPath];
  id item = [self itemAtIndexPath:indexPath];
  self.configureCellBlock(cell, item);
  return cell;
}

@end
