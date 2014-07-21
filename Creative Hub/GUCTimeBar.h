//
//  GUCTimeBar.h
//  Creative Hub
//
//  Created by 顾超 on 14-7-15.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GUCTimeBarDelegate;

@interface GUCTimeBar : UIView

@property(nonatomic, weak) id<GUCTimeBarDelegate> delegate;

@end

@protocol GUCTimeBarDelegate <NSObject>

- (void)timeBar:(GUCTimeBar *)timeBar
longPressAtLocationInTimeBar:(CGPoint)location withRecognizer:(UILongPressGestureRecognizer *)longPressRecognizer;
- (void)timeBar:(GUCTimeBar *)timeBar
    tappedAtLocationInTimeBar:(CGPoint)location withRecognizer:(UITapGestureRecognizer *)tapRecognizer;
- (void)timeBar:(GUCTimeBar *)timeBar
    draggedAtLocationInTimeBar:(CGPoint)location withRecognizer:(UIPanGestureRecognizer *)panRecognizer;

@end