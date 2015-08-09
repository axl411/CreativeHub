//
//  GCSketchingVC.h
//  Creative Hub
//
//  Created by 顾超 on 14-6-28.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GCSketchingView;

@interface GCSketchingVC : UIViewController

@property(weak, nonatomic) IBOutlet GCSketchingView *sketchingView;
@property (weak, nonatomic) IBOutlet UIButton *undoButton;
@property (weak, nonatomic) IBOutlet UIButton *redoButton;

@end
