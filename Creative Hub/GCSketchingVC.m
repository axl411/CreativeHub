//
//  GCSketchingVC.m
//  Creative Hub
//
//  Created by 顾超 on 14-6-28.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import "GCSketchingVC.h"
#import "GCSketchingView.h"

@interface GCSketchingVC () <GCSketchingViewDelegate>

@end

@implementation GCSketchingVC

#pragma mark -

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.

  // set the delegate for Sketching View
  self.sketchingView.delegate = self;
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

#pragma mark - Sketching View Delegate

- (void)sketchingView:(GCSketchingView *)view
    didEndDrawUsingTool:(id<GUCSketchingTool>)tool {
  [self updateButtonStatus];
}

#pragma mark - Actions

- (void)updateButtonStatus {
  self.undoButton.enabled = [self.sketchingView canUndo];
  self.redoButton.enabled = [self.sketchingView canRedo];
}

- (IBAction)clear:(UIButton *)sender {
  [self.sketchingView clear];
  [self updateButtonStatus];
}

- (IBAction)undo:(UIButton *)sender {
  [self.sketchingView undoLatestStep];
  [self updateButtonStatus];
}
- (IBAction)redo:(UIButton *)sender {
  [self.sketchingView redoLatestStep];
  [self updateButtonStatus];
}

@end
