//
//  GUCLayer.h
//  Creative Hub
//
//  Created by 顾超 on 14-6-30.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GUCLayer : NSObject

@property(nonatomic) UIImage *image;
@property(nonatomic) NSInteger tag;

- (id)initWithImage:(UIImage *)image tag:(NSInteger)tag;

@end
