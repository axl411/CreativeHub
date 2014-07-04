//
//  GCSketchingTools.h
//  Creative Hub
//
//  Created by 顾超 on 14-6-28.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

@import Foundation;

@protocol GUCSketchingTool <NSObject>
@property(nonatomic) UIColor *lineColor;
@property(nonatomic) CGFloat lineAlpha;
@property(nonatomic) CGFloat lineWidth;

- (void)setInitialPoint:(CGPoint)firstPoint;
- (void)moveFromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint;

- (void)draw;

@end

#pragma mark -
@interface GUCSketchingPenTool : UIBezierPath <GUCSketchingTool>
@end