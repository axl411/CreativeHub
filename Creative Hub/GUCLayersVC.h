//
//  GUCLayersVC.h
//  Creative Hub
//
//  Created by 顾超 on 14-6-30.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

@import UIKit;

@class GUCLayersVC, GUCLayer;

@protocol GUCLayersVCDelegate <NSObject>

- (void)layersVCDidPressCanvasButton:(GUCLayersVC *)layersVC;
- (void)layersVC:(GUCLayersVC *)layersVC
    didChangeActivateLayer:(GUCLayer *)layer;
- (void)layersVC:(GUCLayersVC *)layersVC
    didPressAddLayerButtonWithCurrentBiggestTagNumber:
        (NSInteger)biggestTagNumber;

@end

@interface GUCLayersVC
    : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property(nonatomic) NSMutableArray *layers;
@property(nonatomic) id<GUCLayersVCDelegate> delegate;
@property(nonatomic) NSInteger initiallySelectedLayerTag;

@end
