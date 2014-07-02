//
//  GUCLayer.m
//  Creative Hub
//
//  Created by 顾超 on 14-6-30.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import "GUCLayer.h"

@implementation GUCLayer

- (id)initWithImage:(UIImage *)image tag:(NSInteger)tag {
  self = [super init];
  if (self) {
    _image = image;
    _tag = tag;
  }
  return self;
}

@end
