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
/**
 *  Called by delegate when in the layers VC the add new layer button is
 *  pressed. It is used to inform the delegate that a new layer(sketching view)
 *  should be created using the biggestTagNumber + 1 as the new sketching view's
 *  tag.
 *
 *  @param layersVC         the layersVC itself
 *  @param biggestTagNumber current biggest tag number of layer
 *  objects(sketching views), should plus 1 when used to create a new sketching
 *  view in the delegate
 */
- (void)layersVC:(GUCLayersVC *)layersVC
    didPressAddLayerButtonWithCurrentBiggestTagNumber:
        (NSInteger)biggestTagNumber;
- (void)layersVCDidPressDeleteButton:(GUCLayersVC *)layersVC;
- (void)layersVC:(GUCLayersVC *)layersVC
    didMoveRowFromIndexPath:(NSIndexPath *)sourceIndexPath
                toIndexPath:(NSIndexPath *)destinationIndexPath;
- (void)layersVC:(GUCLayersVC *)layersVC
    didPressTransformButtonWithLayerTagNumber:(NSInteger)tag;

@end

@interface GUCLayersVC
    : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property(nonatomic) NSMutableArray *layers;
@property(nonatomic, weak) id<GUCLayersVCDelegate> delegate;
@property(nonatomic) NSInteger initiallySelectedLayerTag;

@end
