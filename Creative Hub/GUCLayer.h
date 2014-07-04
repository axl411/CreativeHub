//
//  GUCLayer.h
//  Creative Hub
//
//  Created by 顾超 on 14-6-30.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

@import Foundation;

@interface GUCLayer : NSObject

@property(nonatomic) UIImage *image;
@property(nonatomic) NSInteger tag;

- (instancetype)initWithImage:(UIImage *)image tag:(NSInteger)tag;

@end
