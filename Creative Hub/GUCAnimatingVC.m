//
//  GUCAnimatingVC.m
//  Creative Hub
//
//  Created by 顾超 on 14-7-12.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import "GUCAnimatingVC.h"
#import "GUCSketchSave.h"
#import "GUCSketchSaveDetail.h"
#import "GUCAnimatingVC.h"
#import "GUCAnimatingView.h"

#define CanvasFrame CGRectMake(0, 124, 320, 320)
#define WhiteBackgroundColor                                                   \
  [UIColor colorWithRed:0.969 green:0.969 blue:0.969 alpha:1]

@interface GUCAnimatingVC ()

@property(nonatomic) NSArray *animatingViews;
@property(nonatomic) UIView *embedView;
@property(weak, nonatomic) IBOutlet GUCLayersScrollView *layersScrollView;
@property(nonatomic) NSInteger activatedAnimatingViewIndex;

@end

@implementation GUCAnimatingVC

- (UIView *)embedView {
  if (!_embedView) {
    _embedView = [[UIView alloc] initWithFrame:CanvasFrame];
    _embedView.backgroundColor = WhiteBackgroundColor;
  }

  return _embedView;
}

- (void)setupAnimatingVC {
  [self.view addSubview:self.embedView];

  NSSet *saveDetails = self.save.details;
  self.animatingViews = [self animatingViewsWithSaveDetails:saveDetails];

  for (NSInteger i = self.animatingViews.count - 1; i >= 0; i--) {
    [self.embedView addSubview:self.animatingViews[i]];
  }
}

- (void)setupLayersView {
  NSArray *imageViews = [self imageViewsWithSaveDetails:self.save.details];
  self.layersScrollView.imageViews = imageViews;
  [self.layersScrollView configSelf];
  self.layersScrollView.layersScrollViewDelegate = self;
  [self.layersScrollView selectImageViewAtIndex:0];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  [self setupAnimatingVC];
  [self setupLayersView];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little
preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - GUCLayersScrollViewDelegate

- (void)layersScrollView:(GUCLayersScrollView *)layersScrollView
    didSelectImageViewAtIndex:(NSUInteger)index {
  self.activatedAnimatingViewIndex = index;
  [self highlightAnimatingViewWithIndex:index];
}

#pragma mark - Helper

- (void)highlightAnimatingViewWithIndex:(NSInteger)index {
  [self.animatingViews
      enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
          GUCAnimatingView *animatingView = (GUCAnimatingView *)obj;
          if (index == idx) {
            [UIView animateWithDuration:0.5
                             animations:^{ animatingView.alpha = 1.0; }];
          } else {
            [UIView animateWithDuration:0.5
                             animations:^{ animatingView.alpha = 0.075; }];
          }
      }];
}

/**
 *  Create an array of GUCAnimatingView from the given GUCSketchSaveDetail set,
 *  this method is used when setup this view controller
 *
 *  @param details the given GUCSketchSaveDetails set
 *
 *  @return an array of GUCAnimatingView
 */
- (NSArray *)animatingViewsWithSaveDetails:(NSSet *)details {
  NSMutableArray *animatingViews = [[NSMutableArray alloc] init];
  for (int i = 0; i < details.count; i++) {
    [animatingViews addObject:[NSNull null]];
  }

  for (GUCSketchSaveDetail *detail in details) {
    GUCAnimatingView *animatingView = [[GUCAnimatingView alloc]
        initWithImage:[UIImage imageWithData:detail.image]];
    animatingView.frame = CGRectMake(0, 0, 320, 320);
    [animatingViews replaceObjectAtIndex:[detail.index intValue]
                              withObject:animatingView];
  }

  return [NSArray arrayWithArray:animatingViews];
}

- (NSArray *)imageViewsWithSaveDetails:(NSSet *)details {
  NSMutableArray *imageViews = [NSMutableArray array];
  for (int i = 0; i < details.count; i++) {
    [imageViews addObject:[NSNull null]];
  }

  for (GUCSketchSaveDetail *detail in details) {
    UIImageView *imageView = [[UIImageView alloc]
        initWithImage:[UIImage imageWithData:detail.image]];
    imageView.contentMode = UIViewContentModeScaleToFill;
    [imageViews replaceObjectAtIndex:[detail.index intValue]
                          withObject:imageView];
  }

  return [NSArray arrayWithArray:imageViews];
}

@end
