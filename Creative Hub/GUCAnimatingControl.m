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
/** A dictionary whose key is the time slot object (array of numbers) and whose
 *  value is an image view which represents the transformated image from the
 *  previous image of that time slot */
@property(nonatomic) NSMutableDictionary *timeSlotToImageViewMap;
/** Stores all timeslots as an array, in ascending order */
@property(nonatomic) NSMutableArray *sortedTimeSlots;
@property(nonatomic) CGPoint accumulatedTranslateValue;

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

- (UIGestureRecognizer *)panRecognizerForTranslation {
  if (!_panRecognizerForTranslation) {
    _panRecognizerForTranslation = [[UIPanGestureRecognizer alloc]
        initWithTarget:self
                action:@selector(panForTranslation:)];
  }
  return _panRecognizerForTranslation;
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
    } else { // tapped on a timeslot not activated
      self.activatedTimeSlotKey =
          [self timeSlotKeyForTimePieceIndex:timePieceIndex];

      // apply all transformation to imageviews before selected imageview
      for (int i = 0;
           i <= [self.sortedTimeSlots indexOfObject:self.activatedTimeSlotKey];
           i++) {
        [self applyTransformationToImageView:self.timeSlotToImageViewMap
                                                 [self.sortedTimeSlots[i]]
                            atAndBeforeIndex:i];
      }

      [self preparationForTimeSlotKeyActivated:self.activatedTimeSlotKey];
    }
  }
  NSLog(@"🔹%@", NSStringFromCGPoint(self.accumulatedTranslateValue));
}

- (void)translatePressed {
  self.selectedAction = GUCTransformationTranslation;
  [self.delegate animatingControlDidChooseTranslation:self];
  // TODO: remove other gesture recognizers
  [self.animatingView addGestureRecognizer:self.panRecognizerForTranslation];
}

- (void)rotatePressed {
  self.selectedAction = GUCTransformationRotation;
  [self.delegate animatingControlDidChooseRotation:self];
}

- (void)scalePressed {
  self.selectedAction = GUCTransformationScaling;
  [self.delegate animatingControlDidChooseScaling:self];
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
  NSLog(@"🔹%@", NSStringFromCGPoint(self.accumulatedTranslateValue));

  imageView.center = imageViewPosition;
  [panRecognizer setTranslation:CGPointZero inView:self.animatingView];

  if (panRecognizer.state == UIGestureRecognizerStateCancelled ||
      panRecognizer.state == UIGestureRecognizerStateEnded) {
    NSMutableDictionary *transformation = [self currentTransformation];
    [transformation
        setObject:[NSValue valueWithCGPoint:self.accumulatedTranslateValue]
           forKey:kTIME_SLOT_VALUE_TRANSFORMATION_TRANSLATION];
  }
}

#pragma mark - Helper

- (NSMutableDictionary *)currentTransformation {
  NSMutableArray *timeSlotValue = self.timeSlots[self.activatedTimeSlotKey];
  NSMutableDictionary *transformation =
      timeSlotValue[kTIME_SLOT_VALUE_TRANSFORMATION];
  return transformation;
}

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

  // create an imageview representing the new position of the image after
  // transformation is applied, initially it overlaps with the original image
  UIImageView *imageView = [[UIImageView alloc]
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
  for (int i = steps; i < self.sortedTimeSlots.count; i++) {
    UIImageView *imageView =
        self.timeSlotToImageViewMap[self.sortedTimeSlots[i]];
    [UIView animateWithDuration:0.3 animations:^{ imageView.alpha = 0.0; }];
  }
}

- (void)applyTransformationToImageView:(UIImageView *)imageView
                      atAndBeforeIndex:(NSInteger)index {
  imageView.center = self.animatingView.rootImageView.center;
  imageView.transform = CGAffineTransformIdentity;

  NSLog(@"🔹apply all transformation before %d", index);
  for (int i = 0; i <= index; i++) {
    [self applyTransformationToImageView:imageView atIndex:i];
  }
}

- (void)applyTransformationToImageView:(UIImageView *)imageView
                               atIndex:(NSInteger)index {
  NSMutableDictionary *transformation =
      [self transformationForTimeslotAtIndex:index];
  NSString *transformationType = [transformation.allKeys firstObject];
  if ([transformationType
          isEqualToString:kTIME_SLOT_VALUE_TRANSFORMATION_TRANSLATION]) {
    NSValue *pointValue = transformation.allValues.firstObject;
    CGPoint translation = [pointValue CGPointValue];
    CGPoint imageViewPosition = imageView.center;
    imageViewPosition.x += translation.x;
    imageViewPosition.y += translation.y;
    imageView.center = imageViewPosition;
    NSLog(@"🔹apply translation: %@", NSStringFromCGPoint(translation));
  } else if ([transformationType
                 isEqualToString:kTIME_SLOT_VALUE_TRANSFORMATION_ROTATION]) {
    // TODO: rotation
  } else if ([transformationType
                 isEqualToString:kTIME_SLOT_VALUE_TRANSFORMATION_SCALING]) {
    // TODO: scaling
  }
}

- (void)restoreAccumulatedTransformationValue {
  // restore accumulated transformation value
  NSValue *pointValue = [self currentTransformation].allValues.firstObject;
  CGPoint translation = [pointValue CGPointValue];
  self.accumulatedTranslateValue = translation;
  // TODO: restore rotation and scaling
}

- (NSMutableDictionary *)transformationForTimeslotAtIndex:(NSInteger)index {
  NSMutableArray *timeSlotValue = self.timeSlots[self.sortedTimeSlots[index]];
  NSMutableDictionary *transformation =
      timeSlotValue[kTIME_SLOT_VALUE_TRANSFORMATION];
  return transformation;
}

@end
