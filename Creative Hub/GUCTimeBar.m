//
//  GUCTimeBar.m
//  Creative Hub
//
//  Created by 顾超 on 14-7-15.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import "GUCTimeBar.h"

@interface GUCTimeBar ()

@end

@implementation GUCTimeBar

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];

  // add gestures
  if (self) {
    UILongPressGestureRecognizer *longPressGestureRecognizer =
        [[UILongPressGestureRecognizer alloc]
            initWithTarget:self
                    action:@selector(longPressDetected:)];
    [self addGestureRecognizer:longPressGestureRecognizer];

    UITapGestureRecognizer *tapGestureRecognizer =
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(tapDetected:)];
    [self addGestureRecognizer:tapGestureRecognizer];

    UIPanGestureRecognizer *panGestureRecognizer =
        [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(panDetected:)];
    [self addGestureRecognizer:panGestureRecognizer];
  }
  return self;
}

#pragma mark - Gesture Actions

- (void)longPressDetected:
            (UILongPressGestureRecognizer *)longPressGestureRecognizer {
  [self.delegate timeBar:self
      longPressAtLocationInTimeBar:[longPressGestureRecognizer
                                       locationInView:self]
                    withRecognizer:longPressGestureRecognizer];
}

- (void)tapDetected:(UITapGestureRecognizer *)tapRecognizer {
  [self.delegate timeBar:self
      tappedAtLocationInTimeBar:[tapRecognizer locationInView:self]
                 withRecognizer:tapRecognizer];
}

- (void)panDetected:(UIPanGestureRecognizer *)panRecognizer {
  [self.delegate timeBar:self
      draggedAtLocationInTimeBar:[panRecognizer locationInView:self]
                  withRecognizer:panRecognizer];
}

@end
