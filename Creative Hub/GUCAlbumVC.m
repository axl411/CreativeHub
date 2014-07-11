//
//  GCAlbumVC.m
//  Creative Hub
//
//  Created by 顾超 on 14-6-22.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import "GUCAlbumVC.h"
#import "GUCCoreDataStack.h"
#import "GUCSketchingView.h"
#import "GUCSketchSave.h"
#import "GUCSketchSaveDetail.h"
#import "GUCCollectionViewDataSource.h"
#import "GUCAlbumCell.h"

@interface GUCAlbumVC ()

@property(nonatomic) NSArray *sketchingSaves;
@property(nonatomic) GUCCollectionViewDataSource *sketchSaveDataSource;
@property(weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation GUCAlbumVC

- (void)viewDidLoad {
  [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  [self loadSketchingSaves];

  [self setUpCollectionView];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)setUpCollectionView {
  CollectionViewCellConfigureBlock configureCell =
      ^(GUCAlbumCell *cell, GUCSketchSave *save) {
      cell.imageView.image = [UIImage imageWithData:save.image];
  };
  self.sketchSaveDataSource =
      [[GUCCollectionViewDataSource alloc] initWithItems:self.sketchingSaves
                                          cellIdentifier:@"AblumCell"
                                      configureCellBlock:configureCell];
  self.collectionView.dataSource = self.sketchSaveDataSource;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little
preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  GUCSketchSave *save = [self.sketchSaveDataSource itemAtIndexPath:indexPath];
  NSSet *details = save.details;
  for (GUCSketchSaveDetail *detail in details) {
    NSLog(@"🔹%@", detail.viewTag);
  }
}

#pragma mark - Helper

- (void)loadSketchingSaves {
  GUCCoreDataStack *coreDataStack = [GUCCoreDataStack defaultStack];
  NSManagedObjectContext *context = coreDataStack.managedObjectContext;

  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  NSEntityDescription *entity =
      [NSEntityDescription entityForName:@"GUCSketchSave"
                  inManagedObjectContext:context];
  [fetchRequest setEntity:entity];
  NSError *error;
  self.sketchingSaves = [context executeFetchRequest:fetchRequest error:&error];
}

@end
