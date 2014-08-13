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
#import "GIF.h"
#import "GUCShowAnimationVC.h"

#define CanvasFrame CGRectMake(0, 64, 320, 320)
#define WhiteBackgroundColor                                                   \
  [UIColor colorWithRed:0.969 green:0.969 blue:0.969 alpha:1]

#define ANIMATION_STEPS 3

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
/** Frames of animation in a single time piece */
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

  // make the activated animating view index meaningless, so the first select on
  // index 0 of animating scroll view will always work
  self.activatedAnimatingViewIndex = -1;
  [self layersScrollView:self.layersScrollView didSelectImageViewAtIndex:0];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  [self setupAnimatingVC];
  [self setupLayersView];

  // set time bar delegate
  self.timeBar.delegate = self;

  [self.view bringSubviewToFront:self.timeBar];

  // add the playBarButton to navigation bar
  self.navigationItem.rightBarButtonItem = self.playBarButton;

  self.steps = ANIMATION_STEPS;
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

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"animatingVCToShowAnimationVC"]) {
    GUCShowAnimationVC *showAnimationVC = segue.destinationViewController;
    showAnimationVC.gifURL = sender;
  }
}

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

- (void)animatingControlDidToggleActionsView:
            (GUCAnimatingControl *)animatingControl {
  self.playBarButton.enabled = !self.playBarButton.enabled;
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
  self.view.userInteractionEnabled = NO;
  UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc]
      initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  activityIndicator.center = self.view.center;
  UIView *shaderView = [[UIView alloc] initWithFrame:self.view.frame];
  shaderView.backgroundColor = [UIColor blackColor];
  shaderView.alpha = 0.5;
  [self.view addSubview:shaderView];
  [shaderView addSubview:activityIndicator];
  [activityIndicator startAnimating];

  dispatch_queue_t animationGeneratingQueue =
      dispatch_queue_create("edu.self.AnimationGeneratingQueue", NULL);
  dispatch_async(animationGeneratingQueue, ^{

      NSURL *fileURL = [self generateGIF];
      NSLog(@"🔹loading complete");
      dispatch_async(dispatch_get_main_queue(), ^{
          [self performSegueWithIdentifier:@"animatingVCToShowAnimationVC"
                                    sender:fileURL];
          [activityIndicator removeFromSuperview];
          [shaderView removeFromSuperview];
          self.view.userInteractionEnabled = YES;
      });
  });
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

#pragma mark - GIF generating related methods

- (NSURL *)generateGIF {
  NSArray *images = [self sequentialImagesOfAnimation];
  NSURL *gifURL = [GIF makeAnimatedGifFromImages:images];
  return gifURL;
}

- (NSArray *)sequentialImagesOfAnimation {
  NSMutableArray *images = [NSMutableArray array];

  NSArray *allTransformations = [self allTransformations];

  for (GUCAnimatingControl *control in self.animatingControls) {
    [control.pulsingHeloLayer removeFromSuperlayer];
    [control.anchorPointView removeFromSuperview];
  }

  for (GUCAnimatingView *view in self.animatingViews) {
    view.containerView.hidden = YES;
    view.rootImageView.alpha = 1.0f;
    view.alpha = 1.0f;
  }

  for (int i = 0; i < NUMBER_OF_TIME_PIECES * self.steps; i++) {
    for (int j = 0; j < allTransformations.count; j++) {
      GUCAnimatingControl *animatingControl = self.animatingControls[j];
      UIImageView *imageView = animatingControl.animatingView.rootImageView;

      NSArray *transformations = allTransformations[j];

      if (i / self.steps < transformations.count) {
        NSMutableDictionary *stepTransformation =
            transformations[i / self.steps];

        if (![stepTransformation isKindOfClass:[NSNull class]]) {
          [self applyTransformation:stepTransformation toView:imageView];
        }
      }
    }

    UIImage *image = [self captureImageInView:self.embedView];
    [images addObject:image];
  }

  for (GUCAnimatingView *view in self.animatingViews) {
    view.containerView.hidden = NO;
    view.transform = CGAffineTransformIdentity;
    view.rootImageView.center = view.center;
    view.rootImageView.layer.anchorPoint = CGPointMake(0.5f, 0.5f);
    view.rootImageView.transform = CGAffineTransformIdentity;
  }

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
      if (timeSlotValue) {
        NSMutableDictionary *transformation =
            timeSlotValue[kTIME_SLOT_VALUE_TRANSFORMATION];
        //      NSLog(@"🔹transformation: %@", transformation);

        NSArray *transformationKeys = transformation.allKeys;
        for (NSString *key in transformationKeys) {
          if (![key isEqualToString:
                        kTIME_SLOT_VALUE_TRANSFORMATION_ANCHOR_POINT_OFFSET]) {
            NSString *transformationType = key;
            if ([transformationType
                    isEqualToString:
                        kTIME_SLOT_VALUE_TRANSFORMATION_TRANSLATION]) {
              NSValue *pointValue = [transformation
                  objectForKey:kTIME_SLOT_VALUE_TRANSFORMATION_TRANSLATION];
              CGPoint translation = [pointValue CGPointValue];
              CGPoint translationEachStep =
                  CGPointMake(translation.x / (self.steps * timeSlotKey.count),
                              translation.y / (self.steps * timeSlotKey.count));
              NSMutableDictionary *stepTranslation =
                  [NSMutableDictionary dictionary];
              [stepTranslation
                  setObject:[NSValue valueWithCGPoint:translationEachStep]
                     forKey:kTIME_SLOT_VALUE_TRANSFORMATION_TRANSLATION];
              [stepTranslation setObject:@"translation" forKey:@"type"];
              [transformations addObject:stepTranslation];
            } else if ([transformationType
                           isEqualToString:
                               kTIME_SLOT_VALUE_TRANSFORMATION_ROTATION]) {
              NSMutableDictionary *rotation = [transformation
                  objectForKey:kTIME_SLOT_VALUE_TRANSFORMATION_ROTATION];
              CGPoint anchorPoint =
                  [((NSValue *)[rotation objectForKey:kROTATION_ANCHOR_POINT])
                      CGPointValue];
              CGPoint center =
                  [((NSValue *)[rotation objectForKey:kROTATION_CENTER])
                      CGPointValue];
              CGFloat rotationValue =
                  [((NSNumber *)[rotation objectForKey:kROTATION_VALUE])
                      floatValue];
              CGFloat stepRotationValue =
                  rotationValue / (self.steps * timeSlotKey.count);

              NSMutableDictionary *stepRotation =
                  [NSMutableDictionary dictionary];
              [stepRotation
                  setObject:[NSNumber numberWithFloat:stepRotationValue]
                     forKey:kROTATION_VALUE];
              [stepRotation setObject:[NSValue valueWithCGPoint:anchorPoint]
                               forKey:kROTATION_ANCHOR_POINT];
              [stepRotation setObject:[NSValue valueWithCGPoint:center]
                               forKey:kROTATION_CENTER];
              [stepRotation setObject:@"rotation" forKey:@"type"];
              [transformations addObject:stepRotation];
            } else if ([transformationType
                           isEqualToString:
                               kTIME_SLOT_VALUE_TRANSFORMATION_SCALING]) {
              NSMutableDictionary *scaling = [transformation
                  objectForKey:kTIME_SLOT_VALUE_TRANSFORMATION_SCALING];
              CGPoint anchorPoint =
                  [((NSValue *)[scaling objectForKey:kSCALING_ANCHOR_POINT])
                      CGPointValue];
              CGPoint center =
                  [((NSValue *)[scaling objectForKey:kSCALING_CENTER])
                      CGPointValue];
              CGFloat scaleValue = [(
                  (NSNumber *)[scaling objectForKey:kSCALING_VALUE])floatValue];

              NSInteger a = (NSInteger)(self.steps * timeSlotKey.count);
              CGFloat b = scaleValue;
              CGFloat stepScaleValue = pow(10, log10(b) / a);

              NSMutableDictionary *stepScaling =
                  [NSMutableDictionary dictionary];
              [stepScaling setObject:[NSNumber numberWithFloat:stepScaleValue]
                              forKey:kSCALING_VALUE];
              [stepScaling setObject:[NSValue valueWithCGPoint:anchorPoint]
                              forKey:kSCALING_ANCHOR_POINT];
              [stepScaling setObject:[NSValue valueWithCGPoint:center]
                              forKey:kSCALING_CENTER];
              [stepScaling setObject:@"scaling" forKey:@"type"];
              [transformations addObject:stepScaling];
            }
          } else {
            // get offset
          }
        }
      }
    } else {
      [transformations addObject:[NSNull null]];
    }
  }

  return [NSArray arrayWithArray:transformations];
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

- (void)applyTransformation:(NSMutableDictionary *)stepTransformation
                     toView:(UIView *)view {
  NSString *type = [stepTransformation objectForKey:@"type"];
  if ([type isEqualToString:@"translation"]) {
    CGPoint viewLocation = view.center;
    NSValue *value = [stepTransformation
        objectForKey:kTIME_SLOT_VALUE_TRANSFORMATION_TRANSLATION];
    CGPoint translation = [value CGPointValue];

    viewLocation.x += translation.x;
    viewLocation.y += translation.y;

    view.center = viewLocation;
  } else if ([type isEqualToString:@"rotation"]) {
    NSNumber *rotationValueObject =
        [stepTransformation objectForKey:kROTATION_VALUE];
    NSValue *anchorPointValue =
        [stepTransformation objectForKey:kROTATION_ANCHOR_POINT];
    NSValue *centerPointValue =
        [stepTransformation objectForKey:kROTATION_CENTER];
    CGFloat rotationValue = [rotationValueObject floatValue];
    CGPoint anchorPoint = [anchorPointValue CGPointValue];
    CGPoint centerPoint = [centerPointValue CGPointValue];

    [view.layer setAnchorPoint:anchorPoint];
    view.transform = CGAffineTransformRotate(view.transform, rotationValue);
    view.center = centerPoint;
  } else if ([type isEqualToString:@"scaling"]) {
    NSNumber *scalingValueObject =
        [stepTransformation objectForKey:kSCALING_VALUE];
    NSValue *anchorPointValue =
        [stepTransformation objectForKey:kSCALING_ANCHOR_POINT];
    NSValue *centerPointValue =
        [stepTransformation objectForKey:kSCALING_CENTER];
    CGFloat scaleValue = [scalingValueObject floatValue];
    CGPoint anchorPoint = [anchorPointValue CGPointValue];
    CGPoint centerPoint = [centerPointValue CGPointValue];

    [view.layer setAnchorPoint:anchorPoint];
    view.transform =
        CGAffineTransformScale(view.transform, scaleValue, scaleValue);
    view.center = centerPoint;
  }
}

- (UIImage *)captureImageInView:(UIView *)view {
  UIGraphicsBeginImageContext(view.frame.size);
  [view.layer renderInContext:UIGraphicsGetCurrentContext()];
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

@end
