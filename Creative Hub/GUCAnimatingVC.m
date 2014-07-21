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
#import "GUCColors.h"

#define CanvasFrame CGRectMake(0, 64, 320, 320)
#define WhiteBackgroundColor                                                   \
  [UIColor colorWithRed:0.969 green:0.969 blue:0.969 alpha:1]

@interface GUCAnimatingVC ()

@property(weak, nonatomic) IBOutlet GUCTimeBar *timeBar;
@property(nonatomic) NSArray *animatingViews;
@property(nonatomic) UIView *embedView;
@property(weak, nonatomic) IBOutlet GUCLayersScrollView *layersScrollView;
@property(nonatomic) NSInteger activatedAnimatingViewIndex;
@property(nonatomic) NSMutableArray *animatingControls;
@property(nonatomic) UIDynamicAnimator *animator;
@property(weak, nonatomic) IBOutlet UIView *actionButtonsView;
@property(nonatomic) UIBarButtonItem *playBarButton;
@property(nonatomic) NSInteger steps;

@end

@implementation GUCAnimatingVC

#pragma mark -

- (NSMutableArray *)animatingControls {
  if (!_animatingControls) {
    _animatingControls = [[NSMutableArray alloc] init];
    for (GUCAnimatingView *animatingView in self.animatingViews) {
      GUCAnimatingControl *animatingControl = [[GUCAnimatingControl alloc]
          initWithTimeBarView:self.timeBar
                animatingView:animatingView
                     animator:self.animator
            actionButtonsView:self.actionButtonsView
             layersScrollView:self.layersScrollView];
      animatingControl.delegate = self;
      [_animatingControls addObject:animatingControl];
    }
  }

  return _animatingControls;
}

- (UIDynamicAnimator *)animator {
  if (!_animator) {
    _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.timeBar];
  }
  return _animator;
}

- (UIView *)embedView {
  if (!_embedView) {
    _embedView = [[UIView alloc] initWithFrame:CanvasFrame];
    _embedView.backgroundColor = WhiteBackgroundColor;
    _embedView.clipsToBounds = YES;
  }

  return _embedView;
}

- (UIBarButtonItem *)playBarButton {
  if (!_playBarButton) {
    _playBarButton = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                             target:self
                             action:@selector(playPressed)];
  }
  return _playBarButton;
}

#pragma mark -

- (void)setupAnimatingVC {
  self.automaticallyAdjustsScrollViewInsets = NO;

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

- (void)viewWillAppear:(BOOL)animated {
  [self.navigationController.navigationBar
      setBarTintColor:NavigationBarAnimatingColor];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  [self setupAnimatingVC];
  [self setupLayersView];

  // set time bar delegate
  self.timeBar.delegate = self;

  [self.view bringSubviewToFront:self.timeBar];

  // make the activated animating view index meaningless, so the first select on
  // index 0 of animating scroll view will always work
  self.activatedAnimatingViewIndex = -1;
  [self layersScrollView:self.layersScrollView didSelectImageViewAtIndex:0];

  // add the playBarButton to navigation bar
  self.navigationItem.rightBarButtonItem = self.playBarButton;

  self.steps = 5;
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  // disable swipe to right to dismiss view
  self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  // enable swipe to right to dismiss view
  self.navigationController.interactivePopGestureRecognizer.enabled = YES;
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
  if (index != self.activatedAnimatingViewIndex) {
    if (![self.animator isRunning]) {
      for (UIImageView *imageView in self.layersScrollView.imageViews) {
        if ([self.layersScrollView.imageViews indexOfObject:imageView] ==
            index) {
          imageView.backgroundColor = [UIColor colorWithRed:220.0 / 255.0
                                                      green:220.0 / 255.0
                                                       blue:220.0 / 255.0
                                                      alpha:1.0];
        } else {
          imageView.backgroundColor = [UIColor colorWithRed:247.0 / 255.0
                                                      green:247.0 / 255.0
                                                       blue:247.0 / 255.0
                                                      alpha:1.0];
        }
      }

      self.activatedAnimatingViewIndex = index;
      [self highlightAnimatingViewWithIndex:index];
      [self enableActivatedAnimatingViewUserInteraction];

      for (GUCAnimatingControl *animatingControl in self.animatingControls) {
        [animatingControl unloadUI];
      }

      [[self activatedAnimatingControl] loadUI];
    }
  }
}

#pragma mark - GUCAnimatingControlDelegate

- (void)animatingControlDidChooseTranslation:
            (GUCAnimatingControl *)animatingControl {
  [self setupNavigationBarTranslationState];
}

- (void)animatingControlDidChooseRotation:
            (GUCAnimatingControl *)animatingControl {
  [self setupNavigationBarRotationState];
}

- (void)animatingControlDidChooseScaling:
            (GUCAnimatingControl *)animatingControl {
  [self setupNavigationBarScalingState];
}

- (void)animatingControlDidUnchooseAction:
            (GUCAnimatingControl *)animatingControl {
  [self setupNavigationBarNormalState];
}

#pragma mark - Actions

- (IBAction)translatePressed:(UIButton *)sender {
  [[self activatedAnimatingControl] translatePressed];
}

- (IBAction)rotatePressed:(UIButton *)sender {
  [[self activatedAnimatingControl] rotatePressed];
}

- (IBAction)scalePressed:(UIButton *)sender {
  [[self activatedAnimatingControl] scalePressed];
}

- (void)playPressed {
  NSURL *fileURL = [self generateGIF];
}

#pragma mark - GUCTimeBarDelegate

- (void)timeBar:(GUCTimeBar *)timeBar
    longPressAtLocationInTimeBar:(CGPoint)location
                  withRecognizer:
                      (UILongPressGestureRecognizer *)longPressRecognizer {
  if (longPressRecognizer.state == UIGestureRecognizerStateBegan) {
    CGFloat tappedX = location.x;
    [[self activatedAnimatingControl] longPressedAtX:tappedX];
  }
}

- (void)timeBar:(GUCTimeBar *)timeBar
    tappedAtLocationInTimeBar:(CGPoint)location
               withRecognizer:(UITapGestureRecognizer *)tapRecognizer {
  if (!self.animator.isRunning) {
    if (tapRecognizer.state == UIGestureRecognizerStateRecognized) {
      CGFloat tappedX = location.x;
      [[self activatedAnimatingControl] tappedAtX:tappedX];
    }
  }
}

- (void)timeBar:(GUCTimeBar *)timeBar
    draggedAtLocationInTimeBar:(CGPoint)location
                withRecognizer:(UIPanGestureRecognizer *)panRecognizer {
  if (!self.animator.isRunning) {
    NSLog(@"🔹dragged");
    // TODO: drag to modify the time period
  }
}

#pragma mark - Helper

- (void)setupNavigationBarNormalState {
  [self.navigationController.navigationBar
      setBarTintColor:NavigationBarAnimatingColor];
  self.title = @"Animating";
}

- (void)setupNavigationBarTranslationState {
  [self.navigationController.navigationBar
      setBarTintColor:NavigationBarTranslationColor];
  self.title = @"Translation";
}

- (void)setupNavigationBarRotationState {
  [self.navigationController.navigationBar
      setBarTintColor:NavigationBarRotationColor];
  self.title = @"Rotation";
}

- (void)setupNavigationBarScalingState {
  [self.navigationController.navigationBar
      setBarTintColor:NavigationBarScalingColor];
  self.title = @"Scaling";
}

- (GUCAnimatingControl *)activatedAnimatingControl {
  return self.animatingControls[self.activatedAnimatingViewIndex];
}

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
    GUCAnimatingView *animatingView =
        [[GUCAnimatingView alloc] initWithFrame:CGRectMake(0, 0, 320, 320)];
    animatingView.rootImageView.image = [UIImage imageWithData:detail.image];
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

- (void)enableActivatedAnimatingViewUserInteraction {
  GUCAnimatingView *activatedAnimatingView =
      self.animatingViews[self.activatedAnimatingViewIndex];
  for (GUCAnimatingView *animatingView in self.animatingViews) {
    if (activatedAnimatingView == animatingView) {
      animatingView.userInteractionEnabled = YES;
    } else {
      animatingView.userInteractionEnabled = NO;
    }
  }
}

- (NSURL *)generateGIF {
  NSArray *images = [self sequentialImagesOfAnimation];
  return nil;
}

- (NSArray *)sequentialImagesOfAnimation {
  NSMutableArray *images = [NSMutableArray array];

  NSArray *allTransformations = [self allTransformations];
  //  for (NSArray *transformations in allTransformations) {
  //    NSLog(@"🔹%@", transformations);
  //  }

  return [NSArray arrayWithArray:images];
}

- (NSArray *)allTransformations {
  NSMutableArray *allTransformations = [NSMutableArray array];

  for (GUCAnimatingControl *animatingControl in self.animatingControls) {
    NSArray *transformations =
        [self transformationsForAnimatingControl:animatingControl];
    [allTransformations addObject:transformations];
    //    NSLog(@"⛔️⛔️⛔️⛔️⛔️⛔️⛔️⛔️⛔️⛔️");
    //    NSLog(@"🔹key: %d", [self.animatingControls
    //    indexOfObject:animatingControl]);
    //    NSLog(@"🔹value: %@", transformations);
  }

  return [NSArray arrayWithArray:allTransformations];
}

- (NSArray *)transformationsForAnimatingControl:
                 (GUCAnimatingControl *)animatingControl {
  NSMutableArray *transformations = [NSMutableArray array];

  for (int i = 0; i < NUMBER_OF_TIME_PIECES; i++) {
    NSMutableArray *timeSlotKey =
        [self timeSlotForTimePiece:i inAnimatingControl:animatingControl];
    if (timeSlotKey) {
      //      NSLog(@"⛔️⛔️⛔️⛔️⛔️⛔️⛔️⛔️⛔️⛔️");
      //      NSLog(@"🔹in %@", timeSlotKey);
      NSMutableArray *timeSlotValue = animatingControl.timeSlots[timeSlotKey];
      NSMutableDictionary *transformation =
          timeSlotValue[kTIME_SLOT_VALUE_TRANSFORMATION];
      //      NSLog(@"🔹transformation: %@", transformation);
      NSString *type = transformation.allKeys.firstObject;
      //      NSLog(@"🔹type: %@", type);
      if ([type isEqualToString:kTIME_SLOT_VALUE_TRANSFORMATION_TRANSLATION]) {
        NSValue *pointValue = transformation.allValues.firstObject;
        CGPoint translation = [pointValue CGPointValue];
        CGPoint translationEachStep =
            CGPointMake(translation.x / self.steps, translation.y / self.steps);
        NSMutableDictionary *stepTranslation = [NSMutableDictionary dictionary];
        [stepTranslation
            setObject:[NSValue valueWithCGPoint:translationEachStep]
               forKey:[NSNumber numberWithInt:i]];
        [transformations addObject:stepTranslation];
        //        NSLog(@"🔹%d is %@, value: %@", i, type,
        //              NSStringFromCGPoint(translationEachStep));
      }
    } else {
      [transformations addObject:[NSNull null]];
    }
  }

  return [NSMutableArray arrayWithArray:transformations];
}

- (NSMutableArray *)timeSlotForTimePiece:(int)i
                      inAnimatingControl:
                          (GUCAnimatingControl *)animatingControl {
  for (NSMutableArray *timeSlotKey in animatingControl.sortedTimeSlots) {
    for (NSNumber *number in timeSlotKey) {
      if ([number intValue] == i) {
        return timeSlotKey;
      }
    }
  }
  return nil;
}

@end
