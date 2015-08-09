//
//  GUCAnimatingControl.h
//  Creative Hub
//
//  Created by 顾超 on 14-7-17.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PulsingHaloLayer.h>

@class GUCTimeBar, GUCAnimatingView, GUCLayersScrollView;
@protocol GUCAnimatingControlDelegate;

@interface GUCAnimatingControl : NSObject

@property(nonatomic, weak) GUCAnimatingView *animatingView;
@property(nonatomic, weak) GUCTimeBar *timeBar;
@property(nonatomic, weak) UIDynamicAnimator *animator;
@property(nonatomic, weak) UIView *actionButtonsView;
@property(nonatomic, weak) GUCLayersScrollView *layersScrollView;
@property(nonatomic, weak) id<GUCAnimatingControlDelegate> delegate;
@property(nonatomic) NSMutableDictionary *timeSlots;
@property(nonatomic) NSMutableArray *availableTimePieces;
/** Stores all timeslots as an array, in ascending order */
@property(nonatomic) NSMutableArray *sortedTimeSlots;
/** The view at the location of the anchor point of the animating view */
@property(nonatomic) UIView *anchorPointView;
@property(nonatomic) PulsingHaloLayer *pulsingHeloLayer;

- (instancetype)initWithTimeBarView:(GUCTimeBar *)timeBar
                      animatingView:(GUCAnimatingView *)animatingView
                           animator:(UIDynamicAnimator *)animator
                  actionButtonsView:(UIView *)actionButtonsView
                   layersScrollView:(GUCLayersScrollView *)layersScrollView;
- (void)unloadUI;
- (void)loadUI;
- (void)longPressedAtX:(CGFloat)x;
- (void)tappedAtX:(CGFloat)x;
- (CGFloat)widthOfSingleTimePiece;
- (void)translatePressed;
- (void)rotatePressed;
- (void)scalePressed;
- (void)panBeganAtLocation:(CGPoint)location;
- (void)panChangedAtLocation:(CGPoint)location;
- (void)panEndedAtLocation:(CGPoint)location;

@end

@protocol GUCAnimatingControlDelegate <NSObject>

- (void)animatingControlDidChooseTranslation:
        (GUCAnimatingControl *)animatingControl;
- (void)animatingControlDidChooseRotation:
        (GUCAnimatingControl *)animatingControl;
- (void)animatingControlDidChooseScaling:
        (GUCAnimatingControl *)animatingControl;
- (void)animatingControlDidUnchooseAction:
        (GUCAnimatingControl *)animatingControl;
- (void)animatingControlDidToggleActionsView:
        (GUCAnimatingControl *)animatingControl;

@end