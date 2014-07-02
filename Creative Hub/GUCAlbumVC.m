//
//  GCAlbumVC.m
//  Creative Hub
//
//  Created by 顾超 on 14-6-22.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import "GUCAlbumVC.h"

@interface GUCAlbumVC ()

@end

@implementation GUCAlbumVC
{
    NSMutableArray *array;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    array = [[NSMutableArray alloc] init];
    
    [array addObject:@"Hello"];
    [array addObject:@"Nice"];
    [array addObject:@"EMM"];
    [array addObject:@"help"];
    [array addObject:@"that"];
    [array addObject:@"dude"];
    [array addObject:@"Stan"];
    [array addObject:@"Kyle"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [array count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AblumCell" forIndexPath:indexPath];
    
    UILabel *label = (UILabel *)[cell viewWithTag:100];
    label.text = [array objectAtIndex:indexPath.row];
    [cell.layer setBorderWidth:2.0f];
    [cell.layer setBorderColor:[UIColor whiteColor].CGColor];
    
    return cell;
}

@end
