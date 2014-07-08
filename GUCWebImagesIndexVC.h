//
//  GCWebImagesIndexVC.h
//  Creative Hub
//
//  Created by 顾超 on 14-6-23.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

@import UIKit;

@class GUCWebImagesIndexVC;

@protocol GUCWebImagesIndexVCDelegate <NSObject>

- (void)webImagesIndexVC:(GUCWebImagesIndexVC *)webImagesIndexVC
    didSelectCellWithImage:(UIImage *)image;

@end

@interface GUCWebImagesIndexVC
    : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource,
                        UISearchBarDelegate>

@property(nonatomic) NSMutableArray *imageAddresses;
@property(nonatomic, weak) id<GUCWebImagesIndexVCDelegate> delegate;

@end
