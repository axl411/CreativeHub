//
//  GUCAnimatingControl.m
//  Creative Hub
//
//  Created by 顾超 on 14-7-17.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import "GUCAnimatingControl.h"
#import "GUCAnimatingVC.h"
#import "GUCAnimatingView.h"
#import "GUCColors.h"
#import "GUCLayersScrollView.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

@interface GUCAnimatingControl ()

/** Current selected action (translation, rotation, scaling or none) */
@property(nonatomic) NSInteger selectedAction;
/** Currently selected time slot (array of numbers) */
@property(nonatomic) NSMutableArray *activatedTimeSlotKey;
/** Simply means if the state now is in choosing action (of transformation) or
 *  not */
@property(nonatomic) BOOL isChoosingAction;
/** Gesture recognizer for dealing with dragging when the selected action is
 *  translation */
@property(nonatomic) UIPanGestureRecognizer *panRecognizerForTranslation;
/** Gesture recognizer for moving the anchor point when the selected action is
 *  rotation or scaling */
@property(nonatomic) UIPanGestureRecognizer *panRecognizerForRotationAndScaling;
@property(nonatomic) UIRotationGestureRecognizer *rotationRecognizer;
@property(nonatomic) UIPinchGestureRecognizer *pinchRecognizer;
/** A dictionary whose key is the time slot object (array of numbers) and whose
 *  value is an image view which represents the transformated image from the
 *  previous image of that time slot */
@property(nonatomic) NSMutableDictionary *timeSlotToImageViewMap;
@property(nonatomic) CGPoint accumulatedTranslateValue;
@property(nonatomic) CGFloat accumulatedRotationAngle;
@property(nonatomic) CGPoint anchorPointOffset;
@property(nonatomic) CGPoint animatingViewInitialCenter;

@end

@implementation GUCAnimatingControl

#pragma mark -

- (instancetype)initWithTimeBarView:(GUCTimeBar *)timeBar
                      animatingView:(GUCAnimatingView *)animatingView
                           animator:(UIDynamicAnimator *)animator
                  actionButtonsView:(UIView *)actionButtonsView
                   layersScrollView:(GUCLayersScrollView *)layersScrollView {
  self = [super init];
  if (self) {
    self.layersScrollView = layersScrollView;
    self.actionButtonsView = actionButtonsView;
    self.animator = animator;
    self.animatingView = animatingView;
    self.timeBar = timeBar;
    self.timeSlots = [NSMutableDictionary dictionary];
    self.availableTimePieces = [self initialAvailableTimePieces];
    self.timeSlotToImageViewMap = [NSMutableDictionary dictionary];
    self.sortedTimeSlots = [NSMutableArray array];
  }
  return self;
}

#pragma mark - Properties

- (void)setAnimatingView:(GUCAnimatingView *)animatingView {
  _animatingView = animatingView;
  self.animatingViewInitialCenter = animatingView.center;
}

- (UIGestureRecognizer *)panRecognizerForTranslation {
  if (!_panRecognizerForTranslation) {
    _panRecognizerForTranslation = [[UIPanGestureRecognizer alloc]
        initWithTarget:self
                action:@selector(panForTranslation:)];
  }
  return _panRecognizerForTranslation;
}

- (UIPanGestureRecognizer *)panRecognizerForRotationAndScaling {
  if (!_panRecognizerForRotationAndScaling) {
    _panRecognizerForRotationAndScaling = [[UIPanGestureRecognizer alloc]
        initWithTarget:self
                action:@selector(panForMovingAnchorPoint:)];
  }
  return _panRecognizerForRotationAndScaling;
}

- (UIRotationGestureRecognizer *)rotationRecognizer {
  if (!_rotationRecognizer) {
    _rotationRecognizer = [[UIRotationGestureRecognizer alloc]
        initWithTarget:self
                action:@selector(rotationDetected:)];
  }
  return _rotationRecognizer;
}

- (UIPinchGestureRecognizer *)pinchRecognizer {
  if (!_pinchRecognizer) {
    _pinchRecognizer = [[UIPinchGestureRecognizer alloc]
        initWithTarget:self
                action:@selector(pinchDetected:)];
  }
  return _pinchRecognizer;
}

- (UIView *)anchorPointView {
  if (!_anchorPointView) {
    _anchorPointView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    _anchorPointView.center =
        CGPointMake(self.animatingView.frame.size.width / 2,
                    self.animatingView.frame.size.height / 2);
    [_anchorPointView.layer setCornerRadius:5];
    _anchorPointView.backgroundColor = ANIMATING_VIEW_ANCHOR_POINT_COLOR;
  }

  return _anchorPointView;
}

- (PulsingHaloLayer *)pulsingHeloLayer {
  if (!_pulsingHeloLayer) {
    _pulsingHeloLayer = [PulsingHaloLayer layer];
    _pulsingHeloLayer.radius = 20;
    _pulsingHeloLayer.backgroundColor =
        ANIMATING_VIEW_ANCHOR_POINT_COLOR.CGColor;
    [_pulsingHeloLayer setAnimationDuration:1];
  }
  return _pulsingHeloLayer;
}

#pragma mark - Animating Timebar related Actions

- (void)unloadUI {
  for (UIView *view in self.timeBar.subviews) {
    [view removeFromSuperview];
    [self.animator removeAllBehaviors];
  }
}

- (void)loadUI {
  for (NSMutableArray *timeSlotValue in self.timeSlots.allValues) {
    for (UIView *view in timeSlotValue[kTIME_SLOT_VALUE_VIEWS]) {
      [self.timeBar addSubview:view];
      [self addSnapBehaviorOnView:view toAnimator:self.animator];
    }
  }
}

- (void)longPressedAtX:(CGFloat)x {
  NSInteger timePieceIndex = (NSInteger)(x / [self widthOfSingleTimePiece]);
  if ([self timePieceIndexIsEmpty:timePieceIndex]) {
    [self createTimeSlotAtIndex:timePieceIndex];
    [self preparationForTimeSlotKeyActivated:self.activatedTimeSlotKey];
  }
}

- (void)tappedAtX:(CGFloat)x {
  NSInteger timePieceIndex = (NSInteger)(x / [self widthOfSingleTimePiece]);
  if (![self timePieceIndexIsEmpty:timePieceIndex]) { // only respond to tap if
                                                      // the tap is on a
                                                      // timeslot
    if ([self.activatedTimeSlotKey
            containsObject:
                [NSNumber numberWithInteger:timePieceIndex]]) { // tapped on an
                                                                // activated
                                                                // timeslot
      [self toggleActionButtonsView];
      [self.delegate animatingControlDidToggleActionsView:self];

      [self.anchorPointView removeFromSuperview];
      [self.pulsingHeloLayer removeFromSuperlayer];
    } else { // tapped on a timeslot not activated
      self.activatedTimeSlotKey =
          [self timeSlotKeyForTimePieceIndex:timePieceIndex];

      UIImageView *imageView =
          self.timeSlotToImageViewMap[self.activatedTimeSlotKey];
      imageView.center = self.animatingViewInitialCenter;
      imageView.transform = CGAffineTransformIdentity;
      imageView.layer.anchorPoint = CGPointMake(0.5f, 0.5f);

      [self applyTransformationsBeforeActivatedTimeSlot];

      [self clearAccumulatedValue];

      [self preparationForTimeSlotKeyActivated:self.activatedTimeSlotKey];
    }
  }
  NSLog(@"🔹%@", NSStringFromCGPoint(self.accumulatedTranslateValue));
}

- (void)translatePressed {
  self.selectedAction = GUCTransformationTranslation;
  [self.delegate animatingControlDidChooseTranslation:self];

  // remove other gesture recognizers,
  [self.animatingView
      removeGestureRecognizer:self.panRecognizerForRotationAndScaling];
  [self.animatingView removeGestureRecognizer:self.rotationRecognizer];
  [self.animatingView removeGestureRecognizer:self.pinchRecognizer];

  // remove anchor point
  [self.anchorPointView removeFromSuperview];
  [self.pulsingHeloLayer removeFromSuperlayer];

  [self clearCurrentImageViewTransformation];

  [self.animatingView addGestureRecognizer:self.panRecognizerForTranslation];
}

- (void)rotatePressed {
  self.selectedAction = GUCTransformationRotation;
  [self.delegate animatingControlDidChooseRotation:self];

  // remove other gesture recognizers
  [self.animatingView removeGestureRecognizer:self.panRecognizerForTranslation];
  [self.animatingView removeGestureRecognizer:self.pinchRecognizer];

  [self clearCurrentImageViewTransformation];

  // add gesture recognizer
  [self.animatingView
      addGestureRecognizer:self.panRecognizerForRotationAndScaling];
  [self.animatingView addGestureRecognizer:self.rotationRecognizer];

  // add anchor point
  self.anchorPointView.center = self.animatingViewInitialCenter;
  self.pulsingHeloLayer.position = self.animatingViewInitialCenter;
  [self.animatingView addSubview:self.anchorPointView];
  self.pulsingHeloLayer.position = self.anchorPointView.center;
  [self.animatingView.layer insertSublayer:self.pulsingHeloLayer
                                     below:self.anchorPointView.layer];
}

- (void)scalePressed {
  self.selectedAction = GUCTransformationScaling;
  [self.delegate animatingControlDidChooseScaling:self];

  // remove other gesture recognizers
  [self.animatingView removeGestureRecognizer:self.panRecognizerForTranslation];
  [self.animatingView removeGestureRecognizer:self.rotationRecognizer];

  [self clearCurrentImageViewTransformation];

  // add gesture recognizer
  [self.animatingView
      addGestureRecognizer:self.panRecognizerForRotationAndScaling];
  [self.animatingView addGestureRecognizer:self.pinchRecognizer];

  // add anchor point
  self.anchorPointView.center = self.animatingViewInitialCenter;
  self.pulsingHeloLayer.position = self.animatingViewInitialCenter;
  [self.animatingView addSubview:self.anchorPointView];
  self.pulsingHeloLayer.position = self.anchorPointView.center;
  [self.animatingView.layer insertSublayer:self.pulsingHeloLayer
                                     below:self.anchorPointView.layer];
}

#pragma mark - Gesture Methods for Translation, Rotation and Scaling

- (void)panForTranslation:(UIPanGestureRecognizer *)panRecognizer {
  UIImageView *imageView =
      self.timeSlotToImageViewMap[self.activatedTimeSlotKey];

  CGPoint translation = [panRecognizer translationInView:self.animatingView];
  CGPoint imageViewPosition = imageView.center;
  imageViewPosition.x += translation.x;
  imageViewPosition.y += translation.y;

  CGPoint tempPoint = self.accumulatedTranslateValue;
  tempPoint.x += translation.x;
  tempPoint.y += translation.y;
  self.accumulatedTranslateValue = tempPoint;

  imageView.center = imageViewPosition;
  [panRecognizer setTranslation:CGPointZero inView:self.animatingView];

  if (panRecognizer.state == UIGestureRecognizerStateCancelled ||
      panRecognizer.state == UIGestureRecognizerStateEnded) {
    NSMutableDictionary *transformation = [self currentTransformation];
    [transformation removeAllObjects];
    [transformation
        setObject:[NSValue valueWithCGPoint:self.accumulatedTranslateValue]
           forKey:kTIME_SLOT_VALUE_TRANSFORMATION_TRANSLATION];
  }
}

- (void)panForMovingAnchorPoint:(UIPanGestureRecognizer *)panRecognizer {
  UIImageView *imageView =
      self.timeSlotToImageViewMap[self.activatedTimeSlotKey];

  if (panRecognizer.state == UIGestureRecognizerStateBegan) {
    [self clearCurrentImageViewTransformation];
    //    self.anchorPointOffset = CGPointZero;
  }

  CGPoint translation = [panRecognizer translationInView:self.animatingView];
  CGPoint anchorPointPosition = self.anchorPointView.center;
  anchorPointPosition.x += translation.x;
  anchorPointPosition.y += translation.y;

  if (anchorPointPosition.x < 0) {
    anchorPointPosition.x = 0;
  }
  if (anchorPointPosition.x > 320) {
    anchorPointPosition.x = 320;
  }
  if (anchorPointPosition.y < 0) {
    anchorPointPosition.y = 0;
  }
  if (anchorPointPosition.y > 320) {
    anchorPointPosition.y = 320;
  }

  self.anchorPointView.center = anchorPointPosition;
  [panRecognizer setTranslation:CGPointZero inView:self.animatingView];

  [self.pulsingHeloLayer setPosition:anchorPointPosition];

  if (panRecognizer.state == UIGestureRecognizerStateEnded ||
      panRecognizer.state == UIGestureRecognizerStateCancelled) {

    [self applyTransformationsBeforeActivatedTimeSlot];

    NSLog(@"🔹before converting: %f, %f", self.anchorPointView.center.x,
          self.anchorPointView.center.y);

    anchorPointPosition = [imageView convertPoint:self.anchorPointView.center
                                         fromView:self.animatingView];

    NSLog(@"🔹after converting: %f, %f", anchorPointPosition.x,
          anchorPointPosition.y);

    CGPoint newAnchorPoint = CGPointMake(
        anchorPointPosition.x / self.animatingView.frame.size.width,
        anchorPointPosition.y / self.animatingView.frame.size.height);

    [imageView.layer setAnchorPoint:newAnchorPoint];

    // the view will be moved if the anchor point position is changed, add the
    // offset so the view seems stands still
    self.anchorPointOffset = CGPointMake(
        self.anchorPointView.center.x - self.animatingView.center.x,
        self.anchorPointView.center.y - self.animatingView.center.y);
    CGPoint animatingViewPosition = self.animatingView.center;
    animatingViewPosition.x += self.anchorPointOffset.x;
    animatingViewPosition.y += self.anchorPointOffset.y;
    imageView.center = animatingViewPosition;

    NSLog(@"🔹new anchor point offset: %@",
          NSStringFromCGPoint(self.anchorPointOffset));

    CGPoint previousTraslation = [self totalTranslationBeforeCurrentTimeSlot];
    CGPoint adjustedOffset = self.anchorPointOffset;
    adjustedOffset.x -= previousTraslation.x;
    adjustedOffset.y -= previousTraslation.y;
    self.anchorPointOffset = adjustedOffset;
  }
}

- (void)rotationDetected:(UIRotationGestureRecognizer *)rotationRecognizer {
  UIImageView *imageView =
      self.timeSlotToImageViewMap[self.activatedTimeSlotKey];

  CGFloat angle = rotationRecognizer.rotation;
  self.accumulatedRotationAngle += angle;
  imageView.transform = CGAffineTransformRotate(imageView.transform, angle);
  rotationRecognizer.rotation = 0.0;

  if (rotationRecognizer.state == UIGestureRecognizerStateCancelled ||
      rotationRecognizer.state == UIGestureRecognizerStateEnded) {
    NSMutableDictionary *transformation = [self currentTransformation];
    [transformation removeAllObjects];
    NSLog(@"🔹to set:\nanchor point: %@, angle: %f",
          NSStringFromCGPoint(imageView.layer.anchorPoint),
          self.accumulatedRotationAngle);
    NSMutableDictionary *rotation = [NSMutableDictionary dictionary];
    [rotation setObject:[NSValue valueWithCGPoint:imageView.layer.anchorPoint]
                 forKey:kROTATION_ANCHOR_POINT];
    [rotation setObject:[NSNumber numberWithFloat:self.accumulatedRotationAngle]
                 forKey:kROTATION_VALUE];
    [rotation setObject:[NSValue valueWithCGPoint:imageView.center]
                 forKey:kROTATION_CENTER];
    [transformation
        setObject:[NSValue valueWithCGPoint:self.anchorPointOffset]
           forKey:kTIME_SLOT_VALUE_TRANSFORMATION_ANCHOR_POINT_OFFSET];
    [transformation setObject:rotation
                       forKey:kTIME_SLOT_VALUE_TRANSFORMATION_ROTATION];
  }
}

- (void)pinchDetected:(UIPinchGestureRecognizer *)pinchRecognizer {
  UIImageView *imageView =
      self.timeSlotToImageViewMap[self.activatedTimeSlotKey];

  CGFloat scale = pinchRecognizer.scale;
  imageView.transform =
      CGAffineTransformScale(imageView.transform, scale, scale);
  pinchRecognizer.scale = 1.0;

  if (pinchRecognizer.state == UIGestureRecognizerStateCancelled ||
      pinchRecognizer.state == UIGestureRecognizerStateEnded) {
    NSMutableDictionary *transformation = [self currentTransformation];
    [transformation removeAllObjects];

    CGAffineTransform t = imageView.transform;
    CGFloat scaleToSet = sqrt(t.a * t.a + t.c * t.c);

    NSLog(@"🔹to set:\nanchor point: %@, scale: %f",
          NSStringFromCGPoint(imageView.layer.anchorPoint), scaleToSet);

    NSLog(@"🔹transform: %@",
          NSStringFromCGAffineTransform(imageView.transform));

    NSMutableDictionary *scaling = [NSMutableDictionary dictionary];
    [scaling setObject:[NSValue valueWithCGPoint:imageView.layer.anchorPoint]
                forKey:kSCALING_ANCHOR_POINT];
    [scaling setObject:[NSNumber numberWithFloat:scaleToSet]
                forKey:kSCALING_VALUE];
    [scaling setObject:[NSValue valueWithCGPoint:imageView.center]
                forKey:kSCALING_CENTER];
    [transformation
        setObject:[NSValue valueWithCGPoint:self.anchorPointOffset]
           forKey:kTIME_SLOT_VALUE_TRANSFORMATION_ANCHOR_POINT_OFFSET];
    [transformation setObject:scaling
                       forKey:kTIME_SLOT_VALUE_TRANSFORMATION_SCALING];
  }
}

#pragma mark - Helper

- (void)toggleActionButtonsView {
  if (self.isChoosingAction) {
    [self hideActionButtonsView];
  } else {
    [self showActionButtonsView];
  }
}

- (void)showActionButtonsView {
  self.isChoosingAction = YES;
  [UIView animateWithDuration:0.2
      animations:^{
          self.layersScrollView.center =
              CGPointMake(self.layersScrollView.center.x,
                          self.layersScrollView.center.y +
                              self.layersScrollView.bounds.size.height);
      }
      completion:^(BOOL finished) {
          [UIView animateWithDuration:0.2
                           animations:^{
                               self.actionButtonsView.center =
                                   CGPointMake(self.actionButtonsView.center.x,
                                               self.actionButtonsView.center.y -
                                                   self.actionButtonsView.bounds
                                                       .size.height);
                           }];
      }];
}

- (void)hideActionButtonsView {
  self.isChoosingAction = NO;
  self.selectedAction = GUCTransformationNon;
  [self.delegate animatingControlDidUnchooseAction:self];
  [UIView animateWithDuration:0.2
      animations:^{
          self.actionButtonsView.center =
              CGPointMake(self.actionButtonsView.center.x,
                          self.actionButtonsView.center.y +
                              self.actionButtonsView.bounds.size.height);
      }
      completion:^(BOOL finished) {
          [UIView animateWithDuration:0.2
                           animations:^{
                               self.layersScrollView.center =
                                   CGPointMake(self.layersScrollView.center.x,
                                               self.layersScrollView.center.y -
                                                   self.layersScrollView.bounds
                                                       .size.height);
                           }];
      }];

  for (UIGestureRecognizer *gestureRecognizer in self.animatingView
           .gestureRecognizers) {
    [self.animatingView removeGestureRecognizer:gestureRecognizer];
  }
}

- (void)preparationForTimeSlotKeyActivated:
            (NSMutableArray *)activatedTimeSlotKey {
  [self restoreAccumulatedTransformationValue];

  // set alpha values for all images before the timeslot
  [self setAlphasForAllImages];

  // decrease alpha values of views of other timeslots, increase the activated
  // one
  for (NSMutableArray *timeSlotKey in self.timeSlots.allKeys) {
    NSMutableArray *views = ((
        NSMutableArray *)(self.timeSlots[timeSlotKey]))[kTIME_SLOT_VALUE_VIEWS];
    for (UIView *view in views) {
      if ([timeSlotKey isEqualToArray:activatedTimeSlotKey]) {
        [UIView animateWithDuration:0.3 animations:^{ view.alpha = 1.0; }];
      } else {
        [UIView animateWithDuration:0.3 animations:^{ view.alpha = 0.3; }];
      }
    }
  }
}

- (BOOL)timePieceIndex:(NSInteger)index
    isInsideTimeSlotKey:(NSMutableArray *)timeSlotKey {
  for (NSNumber *number in timeSlotKey) {
    if ([number integerValue] == index) {
      return YES;
    }
  }
  return NO;
}

- (NSMutableArray *)timeSlotKeyForTimePieceIndex:(NSInteger)index {
  for (NSMutableArray *timeSlotKey in self.timeSlots.allKeys) {
    if ([self timePieceIndex:index isInsideTimeSlotKey:timeSlotKey]) {
      return timeSlotKey;
    }
  }
  return nil;
}

- (NSMutableArray *)initialAvailableTimePieces {
  NSMutableArray *newTimePieces = [[NSMutableArray alloc] init];
  for (int i = 0; i < NUMBER_OF_TIME_PIECES; i++) {
    [newTimePieces addObject:[NSNumber numberWithInteger:i]];
  }

  return newTimePieces;
}

- (CGFloat)widthOfSingleTimePiece {
  return 320 / NUMBER_OF_TIME_PIECES;
}

- (BOOL)timePieceIndexIsEmpty:(NSInteger)index {
  return [self.availableTimePieces
      containsObject:[NSNumber numberWithInteger:index]];
}

- (void)createTimeSlotAtIndex:(NSInteger)index {
  NSInteger lowerEndIndex = [self availableLowerEndIndexForIndex:index];
  NSInteger upperEndIndex = [self availableUpperEndIndexForIndex:index];

  // create a time slot key
  NSMutableArray *timeSlotKey = [NSMutableArray array];
  for (NSInteger i = lowerEndIndex; i <= upperEndIndex; i++) {
    [timeSlotKey addObject:self.availableTimePieces[i]];
    self.availableTimePieces[i] = [NSNull null];
  }

  // set it active if no active timeslot exists
  if (!self.activatedTimeSlotKey) {
    self.activatedTimeSlotKey = timeSlotKey;
  }

  // put this newly created timeslot into sorted timeslot array
  [self.sortedTimeSlots addObject:timeSlotKey];
  [self.sortedTimeSlots
      sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
          NSMutableArray *array1 = (NSMutableArray *)obj1;
          NSMutableArray *array2 = (NSMutableArray *)obj2;
          NSNumber *a = [array1 firstObject];
          NSNumber *b = [array2 firstObject];
          if ([a integerValue] > [b integerValue]) {
            return NSOrderedDescending;
          } else if ([a integerValue] < [b integerValue]) {
            return NSOrderedAscending;
          } else {
            return NSOrderedSame;
          }
      }];

  /*  // create an imageview representing the new position of the image after
    // transformation is applied, initially it overlaps with the original image
    UIImageView *imageView;
    NSInteger timeSlotIndex = [self.sortedTimeSlots indexOfObject:timeSlotKey];
    if (timeSlotIndex == 0) {
      imageView = [[UIImageView alloc]
          initWithImage:self.animatingView.rootImageView.image];
      imageView.frame = CGRectMake(0, 0, self.animatingView.frame.size.width,
                                   self.animatingView.frame.size.height);
    } else {
      UIImageView *previousImageView =
          self.timeSlotToImageViewMap.allValues[timeSlotIndex - 1];
      imageView = [[UIImageView alloc]
          initWithImage:self.animatingView.rootImageView.image];
      imageView.frame = CGRectMake(0, 0, self.animatingView.frame.size.width,
                                   self.animatingView.frame.size.height);
      imageView.layer.anchorPoint = previousImageView.layer.anchorPoint;
      imageView.center = previousImageView.center;
      //
      //    CGPoint centerOffset =
      //        CGPointMake((imageView.layer.anchorPoint.x - 0.5) *
      //                        self.animatingView.frame.size.width,
      //                    (imageView.layer.anchorPoint.y - 0.5) *
      //                        self.animatingView.frame.size.height);
      //    CGPoint imageViewLocation = imageView.center;
      //    imageViewLocation.x -= centerOffset.x;
      //    imageViewLocation.y -= centerOffset.y;
      //    imageView.center = imageViewLocation;
    } */

  UIImageView *imageView;
  imageView = [[UIImageView alloc]
      initWithImage:self.animatingView.rootImageView.image];
  imageView.frame = CGRectMake(0, 0, self.animatingView.frame.size.width,
                               self.animatingView.frame.size.height);

  imageView.alpha = 0.0;
  [self.animatingView.containerView addSubview:imageView];
  self.timeSlotToImageViewMap[timeSlotKey] = imageView;

  // create views for a time slot
  UIView *body =
      [self timeSlotBodyViewFromIndex:lowerEndIndex toIndex:upperEndIndex];
  body.backgroundColor = TIME_SLOT_BODY_COLOR;
  [self.timeBar addSubview:body];
  [self addSnapBehaviorOnView:body toAnimator:self.animator];

  UIView *lowerHandle = [self timeSlotHandleViewAtIndex:lowerEndIndex];
  lowerHandle.backgroundColor = TIME_SLOT_LOWER_HANDLE_COLOR;
  [self.timeBar addSubview:lowerHandle];
  [self addSnapBehaviorOnView:lowerHandle toAnimator:self.animator];

  UIView *upperHandle = [self timeSlotHandleViewAtIndex:upperEndIndex];
  upperHandle.backgroundColor = TIME_SLOT_UPPER_HANDLE_COLOR;
  [self.timeBar addSubview:upperHandle];
  [self addSnapBehaviorOnView:upperHandle toAnimator:self.animator];

  // add time slot views into data
  NSMutableArray *timeSlotValue =
      [@[ [NSNull null], [NSNull null] ] mutableCopy];
  NSMutableArray *timeSlotValueViews =
      [@[ [NSNull null], [NSNull null], [NSNull null] ] mutableCopy];
  timeSlotValueViews[kTIME_SLOT_VALUE_VIEWS_BODY] = body;
  timeSlotValueViews[kTIME_SLOT_VALUE_VIEWS_LOWER_HANDLE] = lowerHandle;
  timeSlotValueViews[kTIME_SLOT_VALUE_VIEWS_UPPER_HANDLE] = upperHandle;
  timeSlotValue[kTIME_SLOT_VALUE_VIEWS] = timeSlotValueViews;
  NSMutableDictionary *transformation = [NSMutableDictionary dictionary];
  timeSlotValue[kTIME_SLOT_VALUE_TRANSFORMATION] = transformation;
  [self.timeSlots setObject:timeSlotValue forKey:timeSlotKey];
}

- (NSInteger)availableLowerEndIndexForIndex:(NSInteger)index {
  NSInteger step = DEFAULT_TIME_SLOT_LENGTH / 2;
  for (NSInteger i = index; i >= index - step; i--) {
    if (i == 0) {
      return 0;
    }
    if (self.availableTimePieces[i] == [NSNull null]) {
      return i + 1;
    }
  }
  return index - step;
}

- (NSInteger)availableUpperEndIndexForIndex:(NSInteger)index {
  NSInteger step = DEFAULT_TIME_SLOT_LENGTH / 2;
  for (NSInteger i = index; i <= index + step; i++) {
    if (i == NUMBER_OF_TIME_PIECES - 1) {
      return NUMBER_OF_TIME_PIECES - 1;
    }
    if (self.availableTimePieces[i] == [NSNull null]) {
      return i - 1;
    }
  }
  return index + step;
}

- (UIView *)timeSlotBodyViewFromIndex:(NSInteger)lowerEndIndex
                              toIndex:(NSInteger)upperEndIndex {
  CGRect rect = CGRectMake(lowerEndIndex * [self widthOfSingleTimePiece], 0,
                           (upperEndIndex - lowerEndIndex + 1) *
                               [self widthOfSingleTimePiece],
                           self.timeBar.bounds.size.height);
  UIView *view = [[UIView alloc] initWithFrame:rect];

  return view;
}

- (void)addSnapBehaviorOnView:(UIView *)view
                   toAnimator:(UIDynamicAnimator *)animator {
  UISnapBehavior *snap =
      [[UISnapBehavior alloc] initWithItem:view snapToPoint:view.center];
  view.center =
      CGPointMake(self.timeBar.center.x, 0 - self.timeBar.bounds.size.height -
                                             self.timeBar.frame.origin.y);
  snap.damping = 1.0;
  [animator addBehavior:snap];
}

- (UIView *)timeSlotHandleViewAtIndex:(NSInteger)index {
  UIView *view = [[UIView alloc]
      initWithFrame:CGRectMake(index * [self widthOfSingleTimePiece], 0,
                               [self widthOfSingleTimePiece],
                               self.timeBar.bounds.size.height)];
  return view;
}

- (void)setAlphasForAllImages {
  CGFloat initialAlpha = 0.1;
  self.animatingView.rootImageView.alpha = initialAlpha;
  CGFloat finalAlpha = 1.0;
  NSInteger steps =
      [self.sortedTimeSlots indexOfObject:self.activatedTimeSlotKey] + 1;
  CGFloat alphaStep = (finalAlpha - initialAlpha) / steps;
  for (int i = 0; i < steps; i++) {
    initialAlpha += alphaStep;
    UIImageView *imageView =
        self.timeSlotToImageViewMap[self.sortedTimeSlots[i]];
    [UIView animateWithDuration:0.3
                     animations:^{ imageView.alpha = initialAlpha; }];
  }
  for (int i = (int)steps; i < self.sortedTimeSlots.count; i++) {
    UIImageView *imageView =
        self.timeSlotToImageViewMap[self.sortedTimeSlots[i]];
    [UIView animateWithDuration:0.3 animations:^{ imageView.alpha = 0.0; }];
  }
}

- (void)applyTransformationToImageView:(UIImageView *)imageView
                      atAndBeforeIndex:(NSInteger)index {
  imageView.center = self.animatingView.rootImageView.center;
  imageView.transform = CGAffineTransformIdentity;

  NSLog(@"🔹transformation for imageview of index %d", index);
  for (int i = 0; i <= index; i++) {
    [self applyTransformationToImageView:imageView atIndex:i];
  }

  CGPoint anchorPointOffset = CGPointZero;
  for (NSInteger i = index; i >= 0; i--) {
    NSMutableArray *timeSlotValue = self.timeSlots[self.sortedTimeSlots[i]];
    NSMutableDictionary *timeSlotValueTransformation =
        timeSlotValue[kTIME_SLOT_VALUE_TRANSFORMATION];
    NSValue *anchorPointOffsetValue = timeSlotValueTransformation
        [kTIME_SLOT_VALUE_TRANSFORMATION_ANCHOR_POINT_OFFSET];
    CGPoint offset = [anchorPointOffsetValue CGPointValue];
    if (!CGPointEqualToPoint(offset, CGPointZero)) {
      anchorPointOffset = offset;
      break;
    }
  }

  CGPoint animatingViewPosition = imageView.center;
  animatingViewPosition.x += anchorPointOffset.x;
  animatingViewPosition.y += anchorPointOffset.y;
  imageView.center = animatingViewPosition;
  NSLog(@"🔹anchor point offset: %f, %f", anchorPointOffset.x,
        anchorPointOffset.y);
}

- (void)applyTransformationToImageView:(UIImageView *)imageView
                               atIndex:(NSInteger)index {
  NSMutableDictionary *transformation =
      [self transformationForTimeslotAtIndex:index];
  NSArray *transformationKeys = transformation.allKeys;
  for (NSString *key in transformationKeys) {
    if (![key isEqualToString:
                  kTIME_SLOT_VALUE_TRANSFORMATION_ANCHOR_POINT_OFFSET]) {
      NSString *transformationType = key;
      if ([transformationType
              isEqualToString:kTIME_SLOT_VALUE_TRANSFORMATION_TRANSLATION]) {
        NSValue *pointValue = [transformation
            objectForKey:kTIME_SLOT_VALUE_TRANSFORMATION_TRANSLATION];
        CGPoint translation = [pointValue CGPointValue];
        CGPoint imageViewPosition = imageView.center;
        imageViewPosition.x += translation.x;
        imageViewPosition.y += translation.y;
        imageView.center = imageViewPosition;
        NSLog(@"🔹apply translation: %@", NSStringFromCGPoint(translation));
      } else if ([transformationType
                     isEqualToString:
                         kTIME_SLOT_VALUE_TRANSFORMATION_ROTATION]) {
        NSMutableDictionary *rotation = [transformation
            objectForKey:kTIME_SLOT_VALUE_TRANSFORMATION_ROTATION];
        CGPoint anchorPoint =
            [((NSValue *)[rotation objectForKey:kROTATION_ANCHOR_POINT])
                CGPointValue];
        CGFloat rotationValue =
            [((NSNumber *)[rotation objectForKey:kROTATION_VALUE])floatValue];
        imageView.layer.anchorPoint = anchorPoint;

        imageView.transform =
            CGAffineTransformRotate(imageView.transform, rotationValue);

        NSLog(@"🔹applied rotation at anchor point %f, %f",
              imageView.layer.anchorPoint.x, imageView.layer.anchorPoint.y);
      } else if ([transformationType
                     isEqualToString:kTIME_SLOT_VALUE_TRANSFORMATION_SCALING]) {
        NSMutableDictionary *scaling = [transformation
            objectForKey:kTIME_SLOT_VALUE_TRANSFORMATION_SCALING];
        CGPoint anchorPoint =
            [((NSValue *)[scaling objectForKey:kSCALING_ANCHOR_POINT])
                CGPointValue];
        CGFloat scaleValue =
            [((NSNumber *)[scaling objectForKey:kSCALING_VALUE])floatValue];
        imageView.layer.anchorPoint = anchorPoint;

        CGFloat rotation = asin(imageView.transform.b);
        imageView.transform = CGAffineTransformIdentity;
        imageView.transform =
            CGAffineTransformScale(imageView.transform, scaleValue, scaleValue);
        imageView.transform =
            CGAffineTransformRotate(imageView.transform, rotation);

        NSLog(@"🔹applied scale %f at anchor point %f, %f", scaleValue,
              imageView.layer.anchorPoint.x, imageView.layer.anchorPoint.y);
      }
    }
  }
}

- (void)restoreAccumulatedTransformationValue {
  NSString *transformationType =
      [[self currentTransformation].allKeys firstObject];
  if ([transformationType
          isEqualToString:kTIME_SLOT_VALUE_TRANSFORMATION_TRANSLATION]) {
    // restore accumulated transformation value
    NSValue *pointValue = [self currentTransformation].allValues.firstObject;
    CGPoint translation = [pointValue CGPointValue];
    self.accumulatedTranslateValue = translation;
  } else if ([transformationType
                 isEqualToString:kTIME_SLOT_VALUE_TRANSFORMATION_ROTATION]) {

    // TODO: restore rotation
  } else if ([transformationType
                 isEqualToString:kTIME_SLOT_VALUE_TRANSFORMATION_SCALING]) {
    // TODO: scaling
  }
}

- (void)clearCurrentImageViewTransformation {
  NSMutableArray *timeSlotValue = self.timeSlots[self.activatedTimeSlotKey];
  timeSlotValue[kTIME_SLOT_VALUE_TRANSFORMATION] =
      [NSMutableDictionary dictionary];

  UIImageView *imageView =
      self.timeSlotToImageViewMap[self.activatedTimeSlotKey];
  imageView.center = self.animatingViewInitialCenter;
  imageView.transform = CGAffineTransformIdentity;
  imageView.layer.anchorPoint = CGPointMake(0.5f, 0.5f);

  [self applyTransformationsBeforeActivatedTimeSlot];

  [self clearAccumulatedValue];
}

- (void)clearAccumulatedValue {
  self.accumulatedTranslateValue = CGPointZero;
  self.accumulatedRotationAngle = 0.0f;
}

- (void)applyTransformationsBeforeActivatedTimeSlot {
  // apply all transformation to imageviews before selected imageview
  for (int i = 0;
       i <= [self.sortedTimeSlots indexOfObject:self.activatedTimeSlotKey];
       i++) {
    [self applyTransformationToImageView:self.timeSlotToImageViewMap
                                             [self.sortedTimeSlots[i]]
                        atAndBeforeIndex:i];
  }
}

- (CGPoint)totalTranslationBeforeCurrentTimeSlot {
  CGPoint totalTranslation = CGPointZero;
  for (int i = 0;
       i <= [self.sortedTimeSlots indexOfObject:self.activatedTimeSlotKey];
       i++) {
    NSMutableDictionary *transformation =
        [self transformationForTimeslotAtIndex:i];
    NSString *transformationType = [transformation.allKeys firstObject];
    if ([transformationType
            isEqualToString:kTIME_SLOT_VALUE_TRANSFORMATION_TRANSLATION]) {
      NSValue *pointValue = transformation.allValues.firstObject;
      CGPoint translation = [pointValue CGPointValue];
      totalTranslation.x += translation.x;
      totalTranslation.y += translation.y;
    }
  }
  return totalTranslation;
}

#pragma mark - Quick getters for time slots

- (NSMutableDictionary *)transformationForTimeslotAtIndex:(NSInteger)index {
  return [self transformationInfoForTimeSlot:self.sortedTimeSlots[index]];
}

- (NSMutableDictionary *)transformationInfoForTimeSlot:
                             (NSMutableArray *)timeSlot {
  NSMutableArray *timeSlotValue = self.timeSlots[timeSlot];
  NSMutableDictionary *transformation =
      timeSlotValue[kTIME_SLOT_VALUE_TRANSFORMATION];
  return transformation;
}

- (NSMutableDictionary *)currentTransformation {
  NSMutableArray *timeSlotValue = self.timeSlots[self.activatedTimeSlotKey];
  NSMutableDictionary *transformation =
      timeSlotValue[kTIME_SLOT_VALUE_TRANSFORMATION];
  return transformation;
}

@end
