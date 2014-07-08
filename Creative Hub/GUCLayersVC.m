//
//  GUCLayersVC.m
//  Creative Hub
//
//  Created by 顾超 on 14-6-30.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import "GUCLayersVC.h"
#import "GUCLayerCell.h"
#import "GUCLayer.h"

#define kMaxLayerNumber 10

@interface GUCLayersVC ()

@property(weak, nonatomic) IBOutlet UITableView *tableView;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *trashButton;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property(nonatomic) NSInteger currentSelectedRowNumber;

@end

@implementation GUCLayersVC

- (void)viewDidLoad {
  [super viewDidLoad];

  // Uncomment the following line to preserve selection between presentations.
  // self.clearsSelectionOnViewWillAppear = NO;

  // Uncomment the following line to display an Edit button in the navigation
  // bar for this view controller.
  // self.navigationItem.rightBarButtonItem = self.editButtonItem;

  self.tableView.allowsSelectionDuringEditing = YES;
  self.tableView.editing = YES;

  self.currentSelectedRowNumber = [self initiallySelectedRowNumber];
  NSInteger selectedRowNumber = self.currentSelectedRowNumber;
  [self.tableView
      selectRowAtIndexPath:[NSIndexPath indexPathForRow:selectedRowNumber
                                              inSection:0]
                  animated:YES
            scrollPosition:UITableViewScrollPositionNone];

  [self updateButtonStatus];
}

- (NSInteger)initiallySelectedRowNumber {
  for (GUCLayer *layer in self.layers) {
    if (layer.tag == self.initiallySelectedLayerTag) {
      NSUInteger index = [self.layers indexOfObject:layer];
      return index;
    }
  }
  return -1;
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  // Return the number of sections.
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  if (section == 0) {
    return [self.layers count];
  } else {
    return 0;
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSLog(@"🔹called");
  GUCLayerCell *cell =
      [tableView dequeueReusableCellWithIdentifier:@"Layer Cell"
                                      forIndexPath:indexPath];

  // Configure the cell...
  cell.imageView.image = nil;
  GUCLayer *layer = [self.layers objectAtIndex:indexPath.row];
  cell.layerImageView.image = layer.image;
  cell.layerImageView.alpha = layer.alpha;
  cell.tag = layer.tag;

  return cell;
}

- (void)tableView:(UITableView *)tableView
    moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath
           toIndexPath:(NSIndexPath *)destinationIndexPath {
  [self.delegate layersVC:self
      didMoveRowFromIndexPath:sourceIndexPath
                  toIndexPath:destinationIndexPath];
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section {
  if (section == 0) {
    return @"Closer to front";
  } else {
    return @"Closer to back";
  }
}

- (BOOL)tableView:(UITableView *)tableView
    canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

- (BOOL)tableView:(UITableView *)tableView
    canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

#pragma mark - Table View Delegate

- (BOOL)tableView:(UITableView *)tableView
    shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
  return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
  return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  self.currentSelectedRowNumber = indexPath.row;
  [self.delegate layersVC:self
      didChangeActivateLayer:[self.layers objectAtIndex:indexPath.row]];
}

#pragma mark - Actions

- (IBAction)didPressCanvasButton:(UIBarButtonItem *)sender {
  [self.delegate layersVCDidPressCanvasButton:self];
}

- (IBAction)didPressAdd:(UIBarButtonItem *)sender {
  NSInteger biggestTagNumber = [self biggestLayerTagNumber];
  NSLog(@"🔹Biggest tag number of Sketching View is %d",
        (int)(biggestTagNumber));
  [self.delegate layersVC:self
      didPressAddLayerButtonWithCurrentBiggestTagNumber:biggestTagNumber];
  NSLog(@"🔹Start inserting a new row at row 0");
  [self.tableView beginUpdates];
  [self.tableView
      insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:0 inSection:0] ]
            withRowAnimation:UITableViewRowAnimationMiddle];
  [self.tableView endUpdates];
  NSLog(@"🔹Finished inserting new row.");

  [self manuallySelectFirstRow];

  [self updateButtonStatus];
}

- (IBAction)didPressDelete:(UIBarButtonItem *)sender {
  [self.delegate layersVCDidPressDeleteButton:self];
  [self.tableView beginUpdates];
  [self.tableView
      deleteRowsAtIndexPaths:
          @[
            [NSIndexPath indexPathForRow:self.currentSelectedRowNumber
                               inSection:0]
          ] withRowAnimation:UITableViewRowAnimationMiddle];
  [self.tableView endUpdates];

  [self manuallySelectFirstRow];

  [self updateButtonStatus];
}

- (void)updateButtonStatus {
  if (self.layers.count <= 1) {
    self.trashButton.enabled = NO;
  } else {
    self.trashButton.enabled = YES;
  }

  if (self.layers.count >= kMaxLayerNumber) {
    self.addButton.enabled = NO;
  } else {
    self.addButton.enabled = YES;
  }
}

- (IBAction)transformButtonPressed:(UIButton *)sender {
  GUCLayerCell *cell = (GUCLayerCell *)sender.superview.superview.superview;
  NSInteger tag = cell.tag;
  [self.delegate layersVC:self didPressTransformButtonWithLayerTagNumber:tag];
}

#pragma mark - Helper

/**
 *  Return the biggest tag number of layers (actually Sketching Views), so can
 *  inform GUCSketchingVC to create a new Sketching View with the biggest number
 *  + 1 as  the tag, when the adding layer button is pressed
 *
 *  @return The biggest tag number of Sketching Views
 */
- (NSInteger)biggestLayerTagNumber {
  NSInteger biggest = 0;
  for (GUCLayer *layer in self.layers) {
    if (layer.tag > biggest) {
      biggest = layer.tag;
    }
  }
  return biggest;
}

- (void)manuallySelectFirstRow {
  NSIndexPath *firstRowIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
  [self.tableView selectRowAtIndexPath:firstRowIndexPath
                              animated:YES
                        scrollPosition:UITableViewScrollPositionMiddle];
  [self tableView:self.tableView didSelectRowAtIndexPath:firstRowIndexPath];
}

@end
