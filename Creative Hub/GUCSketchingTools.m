//
//  GCSketchingTools.m
//  Creative Hub
//
//  Created by 顾超 on 14-6-28.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import "GUCSketchingTools.h"

#pragma mark - GCSketchingTool

CGPoint midPoint(CGPoint p1, CGPoint p2) {
  return CGPointMake((p1.x + p2.x) * 0.5, (p1.y + p2.y) * 0.5);
}

@implementation GUCSketchingPenTool

@synthesize lineColor = _lineColor;
@synthesize lineAlpha = _lineAlpha;

- (id)init {
  self = [super init];
  if (self != nil) {
    self.lineCapStyle = kCGLineCapRound;
  }
  return self;
}

- (void)setInitialPoint:(CGPoint)firstPoint {
  [self moveToPoint:firstPoint];
}

- (void)moveFromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint {
  [self addQuadCurveToPoint:midPoint(endPoint, startPoint)
               controlPoint:startPoint];
}

- (void)draw {
  [self.lineColor setStroke];
  [self strokeWithBlendMode:kCGBlendModeNormal alpha:self.lineAlpha];
}

@end
