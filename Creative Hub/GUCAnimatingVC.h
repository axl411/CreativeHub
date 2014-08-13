//
//  GUCAnimatingVC.h
//  Creative Hub
//
//  Created by 顾超 on 14-7-12.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GUCLayersScrollView.h"
#import "GUCTimeBar.h"
#import "GUCAnimatingControl.h"

// 320 points devided by number of time pieces should be an integer
#define NUMBER_OF_TIME_PIECES 20
// the default length (time pieces) of a time slot, this value should be odd
#define DEFAULT_TIME_SLOT_LENGTH 5

#define kTIME_SLOT_VALUE_TRANSFORMATION 0
#define kTIME_SLOT_VALUE_VIEWS 1

#define kTIME_SLOT_VALUE_TRANSFORMATION_TRANSLATION @"translation"
#define kTIME_SLOT_VALUE_TRANSFORMATION_ROTATION @"rotation"
#define kTIME_SLOT_VALUE_TRANSFORMATION_SCALING @"scaling"
#define kTIME_SLOT_VALUE_TRANSFORMATION_ANCHOR_POINT_OFFSET                    \
  @"anchor point offset"

#define kROTATION_ANCHOR_POINT @"anchor point"
#define kROTATION_VALUE @"value"
#define kROTATION_CENTER @"center"

#define kSCALING_ANCHOR_POINT @"anchor point"
#define kSCALING_VALUE @"value"
#define kSCALING_CENTER @"center"

#define kTIME_SLOT_VALUE_VIEWS_BODY 0
#define kTIME_SLOT_VALUE_VIEWS_LOWER_HANDLE 1
#define kTIME_SLOT_VALUE_VIEWS_UPPER_HANDLE 2

@class GUCSketchSave;
@protocol GUCAnimatingControlDelegate;

typedef enum {
  GUCTransformationNon = 0,
  GUCTransformationTranslation = 1,
  GUCTransformationRotation = 2,
  GUCTransformationScaling = 3
} GUCTransformation;

@interface GUCAnimatingVC
    : UIViewController <GUCLayersScrollViewDelegate, GUCTimeBarDelegate,
                        GUCAnimatingControlDelegate>

@property(nonatomic) GUCSketchSave *save;

@end
