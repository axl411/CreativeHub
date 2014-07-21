//
//  GUCAnimatingView.m
//  Creative Hub
//
//  Created by 顾超 on 14-7-20.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import "GUCAnimatingView.h"

@implementation GUCAnimatingView

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    // Initialization code
    self.rootImageView = [[UIImageView alloc] initWithFrame:frame];
    self.containerView = [[UIView alloc] initWithFrame:frame];
    [self addSubview:self.rootImageView];
    [self addSubview:self.containerView];
  }
  return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
