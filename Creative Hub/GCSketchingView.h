//
//  GCSketchingView.h
//  Creative Hub
//
//  Created by 顾超 on 14-6-28.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GUCSketchingTool
, GCSketchingViewDelegate;

typedef enum {
  GCSketchingToolTypePen,
  GCSketchingToolTypeLine,
  GCSketchingToolTypeRectagleStroke,
  GCSketchingToolTypeRectagleFill,
  GCSketchingToolTypeEllipseStroke,
  GCSketchingToolTypeEllipseFill,
} GCSketchingToolType;

@interface GCSketchingView : UIView

@property(nonatomic) GCSketchingToolType drawTool;
@property(nonatomic) id<GCSketchingViewDelegate> delegate;

// public properties
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

@protocol GCSketchingViewDelegate <NSObject>

@optional
- (void)sketchingView:(GCSketchingView *)view
    willBeginDrawUsingTool:(id<GUCSketchingTool>)tool;
- (void)sketchingView:(GCSketchingView *)view
    didEndDrawUsingTool:(id<GUCSketchingTool>)tool;

@end
