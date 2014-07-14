//
//  GUCLayersScrollView.h
//  Creative Hub
//
//  Created by 顾超 on 14-7-13.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GUCLayersScrollViewDelegate;

@interface GUCLayersScrollView : UIScrollView

@property(nonatomic) NSArray *imageViews;
@property(nonatomic, weak)
    id<GUCLayersScrollViewDelegate> layersScrollViewDelegate;

- (void)configSelf;
- (void)selectImageViewAtIndex:(NSUInteger)index;

@end

@protocol GUCLayersScrollViewDelegate <NSObject>

- (void)layersScrollView:(GUCLayersScrollView *)layersScrollView
    didSelectImageViewAtIndex:(NSUInteger)index;

@end