//
//  GUCColorPickerVC.m
//  Creative Hub
//
//  Created by 顾超 on 14-7-6.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import "GUCColorPickerVC.h"

@interface GUCColorPickerVC ()

@end

@implementation GUCColorPickerVC

- (void)viewDidLoad {
  [super viewDidLoad];

  UIBarButtonItem *backBarButton =
      [[UIBarButtonItem alloc] initWithTitle:@"Canvas"
                                       style:UIBarButtonItemStyleBordered
                                      target:self
                                      action:@selector(toCanvas)];
  self.navigationItem.leftBarButtonItem = backBarButton;
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  if (self.delegate) {
    [self.delegate setSelectedColor:self.colorPickerView.color];
  }
}

- (void)toCanvas {
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end
