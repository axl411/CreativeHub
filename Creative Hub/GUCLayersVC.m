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

@interface GUCLayersVC ()

@property(weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation GUCLayersVC

- (void)viewDidLoad {
  [super viewDidLoad];

  // Uncomment the following line to preserve selection between presentations.
  // self.clearsSelectionOnViewWillAppear = NO;

  // Uncomment the following line to display an Edit button in the navigation
  // bar for this view controller.
  // self.navigationItem.rightBarButtonItem = self.editButtonItem;

  NSInteger selectedRowNumber = [self initiallySelectedRowNumber];
  [self.tableView
      selectRowAtIndexPath:[NSIndexPath indexPathForRow:selectedRowNumber
                                              inSection:0]
                  animated:YES
            scrollPosition:UITableViewScrollPositionNone];
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
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  // Return the number of rows in the section.
  return [self.layers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSLog(@"🔹called");
  GUCLayerCell *cell =
      [tableView dequeueReusableCellWithIdentifier:@"Layer Cell"
                                      forIndexPath:indexPath];

  // Configure the cell...
  cell.imageView.image = nil;
  cell.layerNameLabel.text = nil;
  GUCLayer *layer = [self.layers objectAtIndex:indexPath.row];
  cell.layerImageView.image = layer.image;

  return cell;
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
  // TODO: delete the layer in delegate and in tableview
  NSLog(@"🔹row deleted");
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
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
}

- (IBAction)didPressDelete:(UIBarButtonItem *)sender {
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

@end
