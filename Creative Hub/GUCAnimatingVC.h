//
//  GUCAnimatingVC.h
//  Creative Hub
//
//  Created by 顾超 on 14-7-12.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GUCLayersScrollView.h"

@class GUCSketchSave;

@interface GUCAnimatingVC
    : UIViewController <GUCLayersScrollViewDelegate>

@property(nonatomic) GUCSketchSave *save;

@end
