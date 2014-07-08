//
//  GCSketchingVC.h
//  Creative Hub
//
//  Created by 顾超 on 14-6-28.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

@import UIKit;

@class GUCSketchingView;

typedef enum {
  GUCSketchingVCStatusDrawing = 1,
  GUCSketchingVCStatusPlacingImage = 2,
  GUCSketchingVCStatusPlacingSketchingView = 3
} GUCSketchingVCStatus;

@interface GUCSketchingVC : UIViewController

@end
