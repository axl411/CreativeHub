//
//  GUCColorPickerVC.h
//  Creative Hub
//
//  Created by 顾超 on 14-7-6.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <HRColorPickerView.h>

@protocol HRColorPickerViewControllerDelegate
- (void)setSelectedColor:(UIColor *)color;
@end

@interface GUCColorPickerVC : UIViewController

@property(weak, nonatomic) IBOutlet HRColorPickerView *colorPickerView;
@property(weak) id<HRColorPickerViewControllerDelegate> delegate;

@end
