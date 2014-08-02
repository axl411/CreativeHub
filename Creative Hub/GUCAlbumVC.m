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
#import "GUCAnimatingVC.h"
#import "GUCColors.h"

@interface GUCAlbumVC ()

@property(nonatomic) NSMutableArray *sketchingSaves;
@property(nonatomic) GUCCollectionViewDataSource *sketchSaveDataSource;
@property(weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *deleteButton;

@property(nonatomic) BOOL isDeleteActive;

@end

@implementation GUCAlbumVC

- (void)viewDidLoad {
  [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  [self loadSketchingSaves];

  [self setUpCollectionView];

  [self.navigationController.navigationBar
      setBarTintColor:NavigationBarNormalColor];
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

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"albumVCToAnimatingVC"]) {
    GUCAnimatingVC *animatingVC =
        (GUCAnimatingVC *)segue.destinationViewController;
    GUCSketchSave *save = (GUCSketchSave *)sender;
    animatingVC.save = save;
  } else if ([segue.identifier isEqualToString:@"albumToSketchingVC"]) {
    if (self.isDeleteActive) {
      self.isDeleteActive = NO;
      [self.navigationController.navigationBar
          setBarTintColor:NavigationBarNormalColor];
      [UIView animateWithDuration:0.3
                       animations:^{
                           [self.collectionView
                               setBackgroundColor:BackgroundNormalColor];
                       }];
      [self.deleteButton setTitle:@"Edit"];
      [self setTitle:@"Animation Album"];
    }
  }
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  GUCSketchSave *save = [self.sketchSaveDataSource itemAtIndexPath:indexPath];
  if (!self.isDeleteActive) {
    [self performSegueWithIdentifier:@"albumVCToAnimatingVC" sender:save];
  } else {
    [self.sketchingSaves removeObject:save];
    GUCCoreDataStack *coreDataStack = [GUCCoreDataStack defaultStack];
    NSManagedObjectContext *context = coreDataStack.managedObjectContext;
    [context deleteObject:save];
    [coreDataStack saveContext];
    [self.collectionView deleteItemsAtIndexPaths:@[ indexPath ]];
  }
}

- (BOOL)collectionView:(UICollectionView *)collectionView
    shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

- (void)collectionView:(UICollectionView *)collectionView
         performAction:(SEL)action
    forItemAtIndexPath:(NSIndexPath *)indexPath
            withSender:(id)sender {
}

#pragma mark - Actions

- (IBAction)deleteButtonPressed:(UIBarButtonItem *)sender {
  if (self.isDeleteActive) {
    self.isDeleteActive = NO;
    [self.navigationController.navigationBar
        setBarTintColor:NavigationBarNormalColor];
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.collectionView.backgroundColor =
                             BackgroundNormalColor;
                     }];
    [sender setTitle:@"Edit"];
    [self setTitle:@"Animation Album"];
  } else {
    self.isDeleteActive = YES;
    [self.navigationController.navigationBar
        setBarTintColor:NavigationBarDeleteColor];
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.collectionView.backgroundColor =
                             BackgroundDeleteColor;
                     }];
    [self setTitle:@"Tap to Delete..."];
    [sender setTitle:@"Done"];
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
  self.sketchingSaves =
      [[context executeFetchRequest:fetchRequest error:&error] mutableCopy];
}

@end
