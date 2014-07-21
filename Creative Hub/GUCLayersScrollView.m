//
//  GUCLayersScrollView.m
//  Creative Hub
//
//  Created by 顾超 on 14-7-13.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import "GUCLayersScrollView.h"
#import "GUCColors.h"

@interface GUCLayersScrollView ()

@property(nonatomic) UITapGestureRecognizer *tapRecognizer;

@end

@implementation GUCLayersScrollView

- (UITapGestureRecognizer *)tapRecognizer {
  if (!_tapRecognizer) {
    _tapRecognizer =
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(tapDetected:)];
  }
  return _tapRecognizer;
}

- (CGFloat)imageWidth {
  return self.bounds.size.height;
}

- (void)configSelf {
  self.contentSize = CGSizeMake(self.imageWidth * self.imageViews.count,
                                self.bounds.size.height);

  for (UIImageView *imageView in self.imageViews) {
    imageView.frame =
        CGRectMake(self.imageWidth * [self.imageViews indexOfObject:imageView],
                   0, self.imageWidth, self.imageWidth);
    imageView.layer.borderColor = [BackgroundAnimatingColor CGColor];
    imageView.layer.borderWidth = 3;
    [self addSubview:imageView];
  }

  [self addGestureRecognizer:self.tapRecognizer];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)tapDetected:(UITapGestureRecognizer *)tapGestureRecognizer {
  CGPoint location = [tapGestureRecognizer locationInView:self];

  NSUInteger selectedImageViewIndex =
      (NSUInteger)(location.x / self.bounds.size.height);
  [self selectImageViewAtIndex:selectedImageViewIndex];
}

- (void)selectImageViewAtIndex:(NSUInteger)index {
  [self.layersScrollViewDelegate layersScrollView:self
                        didSelectImageViewAtIndex:index];
}

@end
