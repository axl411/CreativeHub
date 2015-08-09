//
//  GCSketchingView.m
//  Creative Hub
//
//  Created by 顾超 on 14-6-28.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import "GCSketchingView.h"
#import "GCSketchingTools.h"

#import <QuartzCore/QuartzCore.h>

#define kDefaultLineColor [UIColor blackColor]
#define kDefaultLineWidth 5.0f;
#define kDefaultLineAlpha 1.0f

@interface GCSketchingView ()

/** current tool */
@property(nonatomic) id<GUCSketchingTool> currentTool;
@property(nonatomic) UIImage *image;
/** Stores an array of all drawn paths */
@property(nonatomic) NSMutableArray *pathArray;
/** Stores an array of un-done paths, which can then be re-done later */
@property(nonatomic) NSMutableArray *bufferArray;

@end

@implementation GCSketchingView

#pragma mark -

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self configure];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    [self configure];
  }
  return self;
}

/**
 *  Initial setup
 */
- (void)configure {
  // init arrays
  self.pathArray = [[NSMutableArray alloc] init];
  self.bufferArray = [[NSMutableArray alloc] init];

  // set the default values for the public properties
  self.lineColor = kDefaultLineColor;
  self.lineWidth = kDefaultLineWidth;
  self.lineAlpha = kDefaultLineAlpha;

  // set white background
  self.backgroundColor = [UIColor whiteColor];
}

#pragma mark - Sketching

- (void)drawRect:(CGRect)rect {
  [self.image drawInRect:self.bounds];
  [self.currentTool draw];
}

- (id<GUCSketchingTool>)toolWithCurrentSettings {
  switch (self.drawTool) {
  case GCSketchingToolTypePen:
    return [[GUCSketchingPenTool alloc] init];
    break;
  default:
    return [[GUCSketchingPenTool alloc] init];
    break;
  }
}

- (void)updateCacheImage:(BOOL)redraw {
  // init a context
  UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);

  if (redraw) {
    // erase the previous image
    self.image = nil;

    // redraw all the lines
    for (id<GUCSketchingTool> tool in self.pathArray) {
      [tool draw];
    }

  } else {
    // set the draw point
    [self.image drawAtPoint:CGPointZero];
    [self.currentTool draw];
  }

  // store the image
  self.image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
}

#pragma mark - Touch events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  // init the bezier path
  self.currentTool = [self toolWithCurrentSettings];
  self.currentTool.lineWidth = self.lineWidth;
  self.currentTool.lineColor = self.lineColor;
  self.currentTool.lineAlpha = self.lineAlpha;
  [self.pathArray addObject:self.currentTool];

  // add the first touch
  UITouch *touch = [touches anyObject];
  [self.currentTool setInitialPoint:[touch locationInView:self]];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  // save all touches in the path
  UITouch *touch = [touches anyObject];

  // add the current point to the path
  CGPoint currentLocation = [touch locationInView:self];
  CGPoint previousLocation = [touch previousLocationInView:self];
  [self.currentTool moveFromPoint:previousLocation toPoint:currentLocation];

  [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  // make sure a point is recorded
  [self touchesMoved:touches withEvent:event];

  [self updateCacheImage:NO];

  // clear current tool
  self.currentTool = nil;

  // clear the redo queue
  [self.bufferArray removeAllObjects];

  // call the delegate
  if ([self.delegate
          respondsToSelector:@selector(sketchingView:didEndDrawUsingTool:)]) {
    [self.delegate sketchingView:self didEndDrawUsingTool:self.currentTool];
  }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  // make sure a point is recorded
  [self touchesEnded:touches withEvent:event];
}

#pragma mark - Actions

/**
 *  Clear the canvas
 */
- (void)clear {
  [self.bufferArray removeAllObjects];
  [self.pathArray removeAllObjects];
  [self updateCacheImage:YES];
  [self setNeedsDisplay];
}

#pragma mark - Undo / Redo

- (NSUInteger)undoSteps {
  return [self.bufferArray count];
}

- (void)undoLatestStep {
  if ([self canUndo]) {
    id<GUCSketchingTool> tool = [self.pathArray lastObject];
    [self.bufferArray addObject:tool];
    [self.pathArray removeLastObject];
    [self updateCacheImage:YES];
    [self setNeedsDisplay];
  }
}

- (BOOL)canUndo {
  return [self.pathArray count] > 0;
}

- (void)redoLatestStep {
  if ([self canRedo]) {
    id<GUCSketchingTool> tool = [self.bufferArray lastObject];
    [self.pathArray addObject:tool];
    [self.bufferArray removeLastObject];
    [self updateCacheImage:YES];
    [self setNeedsDisplay];
  }
}

- (BOOL)canRedo {
  return [self.bufferArray count] > 0;
}

@end
