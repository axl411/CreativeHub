//
//  GCSketchingVC.m
//  Creative Hub
//
//  Created by 顾超 on 14-6-28.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import "GUCSketchingVC.h"
#import "GUCSketchingView.h"
#import "GUCLayersVC.h"
#import "GUCLayer.h"

#define kInitialSketchingViewTag 100

@interface GUCSketchingVC () <GUCSketchingViewDelegate, GUCLayersVCDelegate>

@property(weak, nonatomic) IBOutlet GUCSketchingView *initialSketchingView;
@property(nonatomic) NSMutableArray *sketchingViews;
@property(nonatomic) UIView *backgroundView;
@property(weak, nonatomic) IBOutlet UIButton *undoButton;
@property(weak, nonatomic) IBOutlet UIButton *redoButton;
@property(weak, nonatomic) IBOutlet UIButton *clearButton;
@property(weak, nonatomic) IBOutlet UIButton *layersButton;

@property(nonatomic) NSMutableArray *layers;
@property(nonatomic) NSInteger currentActivatedSketchingViewTag;

@end

@implementation GUCSketchingVC

#pragma mark -

- (void)viewDidLoad {
  [super viewDidLoad];
  // initial setup
  self.sketchingViews = [[NSMutableArray alloc] init];
  [self.sketchingViews addObject:self.initialSketchingView];
  self.initialSketchingView.delegate = self;
  self.initialSketchingView.tag = kInitialSketchingViewTag;
  self.currentActivatedSketchingViewTag = kInitialSketchingViewTag;

  // put a view with white background color at the bottom, to make the
  // background of sketching view appears white
  self.backgroundView =
      [[UIView alloc] initWithFrame:self.initialSketchingView.frame];
  self.backgroundView.backgroundColor = [UIColor whiteColor];
  [self.view insertSubview:self.backgroundView
              belowSubview:[self.sketchingViews lastObject]];
}

- (void)viewDidAppear:(BOOL)animated {
  // disable swipe to right to dismiss view
  self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)viewDidDisappear:(BOOL)animated {
  // enable swipe to right to dismiss view
  self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"sketchingVCToLayersVC"]) {
    if ([segue.destinationViewController
            isKindOfClass:[UINavigationController class]]) {
      [self refreshLayerContents];
      UINavigationController *navigationVC = segue.destinationViewController;
      GUCLayersVC *layersVC = (GUCLayersVC *)navigationVC.viewControllers[0];
      layersVC.layers = self.layers;
      layersVC.initiallySelectedLayerTag =
          self.currentActivatedSketchingViewTag;
      layersVC.delegate = self;
    }
  }
}

#pragma mark - Sketching View Delegate

- (void)sketchingView:(GUCSketchingView *)view
    didEndDrawUsingTool:(id<GUCSketchingTool>)tool {
  [self updateButtonStatus];
  NSLog(@"🔹updated button status for sketching view with tag %d",
        (int)(view.tag));
}

#pragma mark - Layers VC Delegate

- (void)layersVCDidPressCanvasButton:(GUCLayersVC *)layersVC {
  [self dismissViewControllerAnimated:YES completion:nil];
  [self updateButtonStatus];
  NSLog(@"🔹current activated tag: %d",
        (int)self.currentActivatedSketchingViewTag);
}

- (void)layersVC:(GUCLayersVC *)layersVC
    didChangeActivateLayer:(GUCLayer *)layer {
  self.currentActivatedSketchingViewTag = layer.tag;
  NSLog(@"🔹Activated sketching view tag changed to %d", (int)layer.tag);
  for (GUCSketchingView *sketchingView in self.sketchingViews) {
    if (sketchingView.tag != self.currentActivatedSketchingViewTag) {
      sketchingView.userInteractionEnabled = NO;
    } else {
      sketchingView.userInteractionEnabled = YES;
    }
  }
  NSLog(@"🔹Did disable other sketching view receiving touch event");
}

- (void)layersVC:(GUCLayersVC *)layersVC
    didPressAddLayerButtonWithCurrentBiggestTagNumber:
        (NSInteger)biggestTagNumber {
  CGRect sketchingViewFrame =
      ((GUCSketchingView *)[self.sketchingViews firstObject]).frame;
  GUCSketchingView *newSketchingView =
      [[GUCSketchingView alloc] initWithFrame:sketchingViewFrame];
  newSketchingView.tag = biggestTagNumber + 1;
  newSketchingView.delegate = self;
  newSketchingView.userInteractionEnabled = NO;
  [self.view addSubview:newSketchingView];
  [self.sketchingViews insertObject:newSketchingView atIndex:0];

  [self refreshLayerContents];
  layersVC.layers = self.layers;
}

#pragma mark - Actions

- (void)updateButtonStatus {
  GUCSketchingView *sketchingView = [self currentActivatedSketchingView];
  self.undoButton.enabled = [sketchingView canUndo];
  self.redoButton.enabled = [sketchingView canRedo];
}

- (IBAction)clear:(UIButton *)sender {
  GUCSketchingView *sketchingView = [self currentActivatedSketchingView];
  [sketchingView clear];
  [self updateButtonStatus];
}

- (IBAction)undo:(UIButton *)sender {
  GUCSketchingView *sketchingView = [self currentActivatedSketchingView];
  [sketchingView undoLatestStep];
  [self updateButtonStatus];
}

- (IBAction)redo:(UIButton *)sender {
  GUCSketchingView *sketchingView = [self currentActivatedSketchingView];
  [sketchingView redoLatestStep];
  [self updateButtonStatus];
}

#pragma mark - Helper

/**
 *  Get currently activated Sketching View based on the value of
 *  self.currentActivatedSketchingViewTag
 *
 *  @return Currently activated Sketching View
 */
- (GUCSketchingView *)currentActivatedSketchingView {
  GUCSketchingView *sketchingView = (GUCSketchingView *)
      [self.view viewWithTag:self.currentActivatedSketchingViewTag];
  return sketchingView;
}

/**
 *  Regenerate layer objects based on Sketching Views in the array, then these
 *  layer objects can passed to the LayersVC
 */
- (void)refreshLayerContents {
  self.layers = [[NSMutableArray alloc] init];
  for (GUCSketchingView *sketchingView in self.sketchingViews) {
    [self.layers addObject:[[GUCLayer alloc] initWithImage:sketchingView.image
                                                       tag:sketchingView.tag]];
  }
}

@end
