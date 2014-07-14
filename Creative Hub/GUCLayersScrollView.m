//
//  GUCLayersScrollView.m
//  Creative Hub
//
//  Created by 顾超 on 14-7-13.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import "GUCLayersScrollView.h"

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
  self.contentSize =
      CGSizeMake(self.imageWidth * self.imageViews.count, self.imageWidth);

  for (UIImageView *imageView in self.imageViews) {
    imageView.frame =
        CGRectMake(self.imageWidth * [self.imageViews indexOfObject:imageView],
                   0, self.imageWidth, self.imageWidth);
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
  NSLog(@"🔹%@", NSStringFromCGPoint(location));

  NSUInteger selectedImageViewIndex =
      (NSUInteger)(location.x / self.bounds.size.height);
  [self selectImageViewAtIndex:selectedImageViewIndex];
}

- (void)selectImageViewAtIndex:(NSUInteger)index {
  for (UIImageView *imageView in self.imageViews) {
    if ([self.imageViews indexOfObject:imageView] == index) {
      imageView.backgroundColor = [UIColor grayColor];
    } else {
      imageView.backgroundColor = [UIColor colorWithRed:247.0 / 255.0
                                                  green:247.0 / 255.0
                                                   blue:247.0 / 255.0
                                                  alpha:1.0];
    }
  }

  [self.layersScrollViewDelegate layersScrollView:self
                        didSelectImageViewAtIndex:index];
}

@end
