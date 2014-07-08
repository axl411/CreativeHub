//
//  GUCSketchingView.h
//  Creative Hub
//
//  Created by 顾超 on 14-6-28.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

@import UIKit;

@protocol GUCSketchingTool
, GUCSketchingViewDelegate;

typedef enum {
  GUCSketchingToolTypePen,
  GUCSketchingToolTypeLine,
  GUCSketchingToolTypeRectagleStroke,
  GUCSketchingToolTypeRectagleFill,
  GUCSketchingToolTypeEllipseStroke,
  GUCSketchingToolTypeEllipseFill,
} GUCSketchingToolType;

@interface GUCSketchingView : UIView

@property(nonatomic) GUCSketchingToolType drawTool;
@property(nonatomic, weak) id<GUCSketchingViewDelegate> delegate;
/** Image that caches the drawing on the Sketching View */
@property(nonatomic) UIImage *image;
/** Current line color */
@property(nonatomic) UIColor *lineColor;
/** Current line width */
@property(nonatomic) CGFloat lineWidth;
/** Current line alpha value */
@property(nonatomic) CGFloat lineAlpha;

/** Erase all drawings */
- (void)clear;
/** Undo */
- (void)undoLatestStep;
- (BOOL)canUndo;
/** Redo */
- (void)redoLatestStep;
- (BOOL)canRedo;

@end

#pragma mark -

@protocol GUCSketchingViewDelegate <NSObject>

@optional
- (void)sketchingView:(GUCSketchingView *)view
    willBeginDrawUsingTool:(id<GUCSketchingTool>)tool;
- (void)sketchingView:(GUCSketchingView *)view
    didEndDrawUsingTool:(id<GUCSketchingTool>)tool;

@end
