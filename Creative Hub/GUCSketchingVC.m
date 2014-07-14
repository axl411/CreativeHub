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
#import "GUCWebImagesIndexVC.h"
#import "GUCColorPickerVC.h"
#import "GUCAlbumVC.h"
#import "GUCCoreDataStack.h"
#import "GUCSketchSave.h"
#import "GUCSketchSaveDetail.h"
#import "DoActionSheet.h"

#import <MobileCoreServices/UTCoreTypes.h>

#define kInitialSketchingViewTag 100
#define kCanvasFrame CGRectMake(0, 115, 320, 320)

@interface GUCSketchingVC () <
    GUCSketchingViewDelegate, GUCLayersVCDelegate, GUCWebImagesIndexVCDelegate,
    UIGestureRecognizerDelegate, UIImagePickerControllerDelegate,
    UINavigationControllerDelegate, HRColorPickerViewControllerDelegate,
    UIAlertViewDelegate>

@property(weak, nonatomic) IBOutlet GUCSketchingView *initialSketchingView;
@property(weak, nonatomic) IBOutlet UIButton *undoButton;
@property(weak, nonatomic) IBOutlet UIButton *redoButton;
@property(weak, nonatomic) IBOutlet UIButton *clearButton;
@property(weak, nonatomic) IBOutlet UIButton *layersButton;
@property(weak, nonatomic) IBOutlet UIButton *addImageButton;
@property(weak, nonatomic) IBOutlet UIButton *alphaButton;
@property(weak, nonatomic) IBOutlet UISlider *alphaSlider;
@property(weak, nonatomic) IBOutlet UIButton *colorButton;

@property(nonatomic) NSMutableArray *sketchingViews;
@property(nonatomic) UIView *backgroundView;
@property(nonatomic) NSMutableArray *layers;
@property(nonatomic) NSInteger currentActivatedSketchingViewTag;
@property(nonatomic) CGRect canvasFrame;
/** The image view for embedding an image, it is used when user exports
 *  an external image */
@property(nonatomic) UIImageView *imageView;
/** The view for embeding the image view which is used for importing external
 *  image, to clip the image if it is outside the canvas frame */
@property(nonatomic) UIView *embedView;

@property(nonatomic) UIPinchGestureRecognizer *pinchRecognizer;
@property(nonatomic) UIPanGestureRecognizer *panRecognizer;
@property(nonatomic) UIRotationGestureRecognizer *rotationRecognizer;

@property(nonatomic) GUCSketchingVCStatus currentStatus;
@property(nonatomic) NSInteger currentBiggestSketchingViewTag;

@property(nonatomic) UIImagePickerController *imagePicker;
/** The index of the sketching view being re positioned in the sketching views
 *  array, which is used to placing the view back */
@property(nonatomic) NSUInteger indexOfSketchingViewBeingRePositioned;
/** The sketching view being re positioned in the sketching views
 *  array, which is used to placing the view back if user chooses cancel when re
 *  position the view */
@property(nonatomic) GUCSketchingView *sketchingViewBeingRePositioned;
@property(nonatomic) GUCSketchSave *save;

@end

@implementation GUCSketchingVC

- (UIImagePickerController *)imagePicker {
  if (!_imagePicker) {
    _imagePicker = [[UIImagePickerController alloc] init];
    _imagePicker.delegate = self;
    _imagePicker.allowsEditing = NO;
    _imagePicker.mediaTypes = @[ (NSString *)kUTTypeImage ];
    _imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
  }
  return _imagePicker;
}

- (UIPinchGestureRecognizer *)pinchRecognizer {
  if (!_pinchRecognizer) {
    _pinchRecognizer =
        [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                  action:@selector(scale:)];
    _pinchRecognizer.delegate = self;
  }
  return _pinchRecognizer;
}

- (UIRotationGestureRecognizer *)rotationRecognizer {
  if (!_rotationRecognizer) {
    _rotationRecognizer =
        [[UIRotationGestureRecognizer alloc] initWithTarget:self
                                                     action:@selector(rotate:)];
    _rotationRecognizer.delegate = self;
  }
  return _rotationRecognizer;
}

- (UIPanGestureRecognizer *)panRecognizer {
  if (!_panRecognizer) {
    _panRecognizer =
        [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(move:)];
    _panRecognizer.delegate = self;
  }
  return _panRecognizer;
}

- (UIView *)embedView {
  if (!_embedView) {
    _embedView = [[UIView alloc] initWithFrame:self.canvasFrame];
    [_embedView setClipsToBounds:YES];
  }
  return _embedView;
}

#pragma mark -

- (void)viewDidLoad {
  [super viewDidLoad];
  // initial setup
  self.canvasFrame = kCanvasFrame;
  self.sketchingViews = [[NSMutableArray alloc] init];
  [self.sketchingViews addObject:self.initialSketchingView];
  self.initialSketchingView.delegate = self;
  self.initialSketchingView.tag = kInitialSketchingViewTag;
  self.currentActivatedSketchingViewTag = kInitialSketchingViewTag;
  self.currentBiggestSketchingViewTag = kInitialSketchingViewTag;

  self.currentStatus = GUCSketchingVCStatusDrawing;

  [self.undoButton
      setTitleColor:[UIColor colorWithRed:0.82 green:0.933 blue:0.988 alpha:1]
           forState:UIControlStateDisabled];
  [self.redoButton
      setTitleColor:[UIColor colorWithRed:0.82 green:0.933 blue:0.988 alpha:1]
           forState:UIControlStateDisabled];
  [self.clearButton
      setTitleColor:[UIColor colorWithRed:0.82 green:0.933 blue:0.988 alpha:1]
           forState:UIControlStateDisabled];
  [self.layersButton
      setTitleColor:[UIColor colorWithRed:0.82 green:0.933 blue:0.988 alpha:1]
           forState:UIControlStateDisabled];
  [self.alphaButton
      setTitleColor:[UIColor colorWithRed:0.82 green:0.933 blue:0.988 alpha:1]
           forState:UIControlStateDisabled];
  [self.addImageButton
      setTitleColor:[UIColor colorWithRed:0.82 green:0.933 blue:0.988 alpha:1]
           forState:UIControlStateDisabled];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  // put a view with white background color at the bottom of the hierarchy,
  // which is used to make the background of sketching view appears white
  self.backgroundView =
      [[UIView alloc] initWithFrame:self.initialSketchingView.frame];
  self.backgroundView.backgroundColor = [UIColor whiteColor];
  [self.view insertSubview:self.backgroundView
              belowSubview:[self.sketchingViews lastObject]];
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

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];

  [self saveSketch];
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
  } else if ([segue.identifier isEqualToString:@"canvasToWebImagesIndex"]) {
    if ([segue.destinationViewController
            isKindOfClass:[GUCWebImagesIndexVC class]]) {
      GUCWebImagesIndexVC *webImagesIndexVC = segue.destinationViewController;
      webImagesIndexVC.delegate = self;
    }
  } else if ([segue.identifier isEqualToString:@"canvasToColorPickerVC"]) {
    if ([segue.destinationViewController
            isKindOfClass:[UINavigationController class]]) {
      UINavigationController *navigationVC = segue.destinationViewController;
      GUCColorPickerVC *colorPickerVC =
          (GUCColorPickerVC *)navigationVC.viewControllers[0];
      colorPickerVC.delegate = self;
      colorPickerVC.colorPickerView.color = self.colorButton.backgroundColor;
    }
  }
}

#pragma mark - Sketching View Delegate

- (void)sketchingView:(GUCSketchingView *)view
    didEndDrawUsingTool:(id<GUCSketchingTool>)tool {
  [self updateButtonStatus];

  [self saveSketch];
}

#pragma mark - GUCLayersVCDelegate

- (void)layersVCDidPressCanvasButton:(GUCLayersVC *)layersVC {
  [self dismissViewControllerAnimated:YES completion:nil];
  [self updateButtonStatus];
  NSLog(@"🔹current activated tag: %d",
        (int)self.currentActivatedSketchingViewTag);
}

- (void)layersVC:(GUCLayersVC *)layersVC
    didChangeActivateLayer:(GUCLayer *)layer {
  self.alphaSlider.hidden = YES;
  [self changeActivatedSketchingViewWithTag:layer.tag];
}

- (void)layersVC:(GUCLayersVC *)layersVC
    didPressAddLayerButtonWithCurrentBiggestTagNumber:
        (NSInteger)biggestTagNumber {
  self.currentBiggestSketchingViewTag = biggestTagNumber + 1;

  GUCSketchingView *sketchingView =
      [self addNewSketchingViewWithTag:self.currentBiggestSketchingViewTag
                                 alpha:1.0
                                toView:self.view];

  [self.sketchingViews insertObject:sketchingView atIndex:0];

  [self refreshLayerContents];
  layersVC.layers = self.layers;
}

- (void)layersVCDidPressDeleteButton:(GUCLayersVC *)layersVC {
  GUCSketchingView *sketchingView = (GUCSketchingView *)
      [self.view viewWithTag:self.currentActivatedSketchingViewTag];
  [sketchingView removeFromSuperview];
  [self.sketchingViews removeObject:sketchingView];

  [self refreshLayerContents];
  [self reorderSketchingViewsBasedOnSketchingViewArrayOrder];
  layersVC.layers = self.layers;

  [self saveSketch];
}

- (void)layersVC:(GUCLayersVC *)layersVC
    didMoveRowFromIndexPath:(NSIndexPath *)sourceIndexPath
                toIndexPath:(NSIndexPath *)destinationIndexPath {
  GUCSketchingView *sketchingViewToInsert = (GUCSketchingView *)
      [self.sketchingViews objectAtIndex:sourceIndexPath.row];
  [self.sketchingViews removeObjectAtIndex:sourceIndexPath.row];
  [self.sketchingViews insertObject:sketchingViewToInsert
                            atIndex:destinationIndexPath.row];
  [self refreshLayerContents];
  layersVC.layers = self.layers;

  [self reorderSketchingViewsBasedOnSketchingViewArrayOrder];
}

- (void)layersVC:(GUCLayersVC *)layersVC
    didPressTransformButtonWithLayerTagNumber:(NSInteger)tag {
  self.currentStatus = GUCSketchingVCStatusPlacingSketchingView;

  GUCSketchingView *sketchingView =
      (GUCSketchingView *)[self.view viewWithTag:tag];
  NSUInteger index = [self.sketchingViews indexOfObject:sketchingView];
  [self.sketchingViews removeObjectAtIndex:index];
  self.indexOfSketchingViewBeingRePositioned = index;
  self.sketchingViewBeingRePositioned = sketchingView;
  UIImage *image = sketchingView.image;

  [self dismissViewControllerAnimated:YES
                           completion:^{
                               [sketchingView removeFromSuperview];
                               [self prepareForPlacingImageWithImage:image];
                           }];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:
        (UIGestureRecognizer *)otherGestureRecognizer {
  return YES;
}

#pragma mark - GUCWebImagesIndexVCDelegate

- (void)webImagesIndexVC:(GUCWebImagesIndexVC *)webImagesIndexVC
    didSelectCellWithImage:(UIImage *)image {
  [self.navigationController popViewControllerAnimated:YES];
  NSLog(@"🔹image received by sketching VC");

  self.currentStatus = GUCSketchingVCStatusPlacingImage;

  [self prepareForPlacingImageWithImage:image];
}

#pragma mark - Image Picker Controller delegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker
    didFinishPickingMediaWithInfo:(NSDictionary *)info {
  NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];

  if ([mediaType isEqualToString:(NSString *)
                 kUTTypeImage]) { // a  photo was taken/selected
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    // save the image
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);

    self.currentStatus = GUCSketchingVCStatusPlacingImage;

    [self prepareForPlacingImageWithImage:image];
  }

  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - HRColorPickerViewControllerDelegate

- (void)setSelectedColor:(UIColor *)color {
  for (GUCSketchingView *sketchingView in self.sketchingViews) {
    sketchingView.lineColor = color;
  }
  self.colorButton.backgroundColor = color;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView
    clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex == 1) {

    if (self.save) {
      GUCAlbumVC *albumVC =
          (GUCAlbumVC *)self.navigationController.viewControllers[0];

      [self.navigationController popToRootViewControllerAnimated:NO];

      [albumVC performSegueWithIdentifier:@"albumVCToAnimatingVC"
                                   sender:self.save];
    } else {
      UIAlertView *alert =
          [[UIAlertView alloc] initWithTitle:@"No drawing"
                                     message:@"You havn't drawn anything!"
                                    delegate:nil
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil];
      [alert show];
    }
  }
}

#pragma mark - Importing External Images

- (void)disableNormalButtonsAndAddButtonsForPlacingSelectedImage {
  self.layersButton.hidden = YES;
  self.addImageButton.hidden = YES;
  self.undoButton.hidden = YES;
  self.redoButton.hidden = YES;
  self.clearButton.hidden = YES;
  self.alphaButton.hidden = YES;

  if (self.currentStatus == GUCSketchingVCStatusPlacingImage) {
    self.alphaSlider.value = 1.0;
    self.alphaSlider.hidden = NO;
  }

  UIBarButtonItem *acceptButton =
      [[UIBarButtonItem alloc] initWithTitle:@"Accept"
                                       style:UIBarButtonItemStyleBordered
                                      target:self
                                      action:@selector(acceptPlacingImage)];
  self.navigationItem.rightBarButtonItem = acceptButton;

  UIBarButtonItem *cancelButton =
      [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                       style:UIBarButtonItemStyleBordered
                                      target:self
                                      action:@selector(cancelPlacingImage)];
  self.navigationItem.leftBarButtonItem = cancelButton;

  self.navigationItem.title = @"Reposition...";
}

- (void)enableNormalButtonsAndRemoveButtonsForPlacingSelectedImage {
  self.layersButton.hidden = NO;
  self.addImageButton.hidden = NO;
  self.undoButton.hidden = NO;
  self.redoButton.hidden = NO;
  self.clearButton.hidden = NO;
  self.alphaButton.hidden = NO;
  self.alphaSlider.hidden = YES;

  UIBarButtonItem *animatingBarButton = [[UIBarButtonItem alloc]
      initWithImage:[UIImage imageNamed:@"Animate"]
              style:UIBarButtonItemStyleBordered
             target:self
             action:@selector(didPressAnimatingButton:)];
  self.navigationItem.rightBarButtonItem = animatingBarButton;

  self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;

  self.navigationItem.title = @"Canvas";
}

- (void)embedImageInImageView:(UIImage *)image {
  // add image to image view, then add image view to embed view, finally add
  // embed view to self.view to present the image to the user so the user can
  // see the image
  self.imageView = [[UIImageView alloc] initWithFrame:self.canvasFrame];
  NSLog(@"🔹canvas frame: %f, %f", self.canvasFrame.size.width,
        self.canvasFrame.size.height);
  self.imageView.image = image;
  self.imageView.contentMode = UIViewContentModeCenter;
  NSLog(@"🔹imageview size: %f, %f", self.imageView.bounds.size.width,
        self.imageView.bounds.size.height);
  NSLog(@"🔹image view content mode: center");
  if (self.imageView.bounds.size.width < image.size.width ||
      self.imageView.bounds.size.height < image.size.height) {
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    NSLog(@"🔹image view content mode: scale aspect fit");
  }
  NSLog(@"🔹image size: %f, %f", image.size.width, image.size.height);
  [self.embedView addSubview:self.imageView];
  self.imageView.center = CGPointMake(self.embedView.frame.size.width / 2,
                                      self.embedView.frame.size.height / 2);
  [self.view addSubview:self.embedView];
}

- (void)scale:(UIPinchGestureRecognizer *)pinchRecognizer {
  CGFloat scale = pinchRecognizer.scale;
  self.imageView.transform =
      CGAffineTransformScale(self.imageView.transform, scale, scale);
  pinchRecognizer.scale = 1.0;
}

- (void)rotate:(UIRotationGestureRecognizer *)rotationRecognizer {
  CGFloat angle = rotationRecognizer.rotation;
  self.imageView.transform =
      CGAffineTransformRotate(self.imageView.transform, angle);
  rotationRecognizer.rotation = 0.0;
}

- (void)move:(UIPanGestureRecognizer *)panRecognizer {
  CGPoint translation = [panRecognizer translationInView:self.view];
  CGPoint imageViewPosition = self.imageView.center;
  imageViewPosition.x += translation.x;
  imageViewPosition.y += translation.y;

  self.imageView.center = imageViewPosition;
  [panRecognizer setTranslation:CGPointZero inView:self.view];
}

- (void)acceptPlacingImage {
  GUCSketchingView *sketchingView =
      [self addNewSketchingViewWithTag:++self.currentBiggestSketchingViewTag
                                 alpha:self.imageView.alpha
                                toView:self.view];
  if (self.currentStatus == GUCSketchingVCStatusPlacingImage) {
    [self.sketchingViews addObject:sketchingView];
  } else if (self.currentStatus == GUCSketchingVCStatusPlacingSketchingView) {
    [self.sketchingViews
        insertObject:sketchingView
             atIndex:self.indexOfSketchingViewBeingRePositioned];
  }
  [self reorderSketchingViewsBasedOnSketchingViewArrayOrder];
  sketchingView.image = [self captureImageInView:self.embedView];
  [self changeActivatedSketchingViewWithTag:sketchingView.tag];

  [self processForCancelPlacingImage];
}

- (void)cancelPlacingImage {
  if (self.currentStatus == GUCSketchingVCStatusPlacingSketchingView) {
    GUCSketchingView *sketchingView =
        [self addNewSketchingViewWithTag:++self.currentBiggestSketchingViewTag
                                   alpha:self.imageView.alpha
                                  toView:self.view];
    [self.sketchingViews
        insertObject:sketchingView
             atIndex:self.indexOfSketchingViewBeingRePositioned];
    [self reorderSketchingViewsBasedOnSketchingViewArrayOrder];
    sketchingView.image = self.sketchingViewBeingRePositioned.image;
    [self changeActivatedSketchingViewWithTag:sketchingView.tag];
  }

  [self processForCancelPlacingImage];
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

- (IBAction)importExternalImageSource:(UIButton *)sender {
  [self initAndShowActionSheet];
}

- (IBAction)didPressAnimatingButton:(UIBarButtonItem *)sender {
  UIAlertView *alert = [[UIAlertView alloc]
          initWithTitle:@"Are you sure?"
                message:@"You will start animating the scene using the current "
                @"drawing, once proceed, you will not be able to "
                @"alter the drawing."
               delegate:self
      cancelButtonTitle:@"Cancel"
      otherButtonTitles:@"Proceed", nil];
  [alert show];
}

- (IBAction)alphaSliderValueChanged:(UISlider *)sender {
  if (self.currentStatus == GUCSketchingVCStatusPlacingImage) {
    self.imageView.alpha = sender.value;
  } else if (self.currentStatus == GUCSketchingVCStatusDrawing) {
    GUCSketchingView *sketchingView = [self currentlyActivatedSketchingView];
    sketchingView.alpha = sender.value;
  }
}

- (IBAction)didPressAlphaButton:(UIButton *)sender {
  if (self.alphaSlider.hidden == YES) {
    GUCSketchingView *sketchingView = [self currentlyActivatedSketchingView];
    self.alphaSlider.value = sketchingView.alpha;

    self.alphaSlider.hidden = NO;
  } else {
    self.alphaSlider.hidden = YES;
  }
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
    [self.layers
        addObject:[[GUCLayer alloc] initWithImage:sketchingView.image
                                              tag:sketchingView.tag
                                            alpha:sketchingView.alpha]];
  }
}

/**
 *  Initialize a customizable action sheet using DoActionSheet and display it
 */
- (void)initAndShowActionSheet {
  DoActionSheet *vActionSheet = [[DoActionSheet alloc] init];
  vActionSheet.nAnimationType = 0;
  vActionSheet.doBackColor = DO_RGB(232, 229, 222);
  vActionSheet.doButtonColor = DO_RGB(52, 152, 219);
  vActionSheet.doCancelColor = DO_RGB(231, 76, 60);
  vActionSheet.doDestructiveColor = DO_RGB(46, 204, 113);

  vActionSheet.doTitleTextColor = DO_RGB(95, 74, 50);
  vActionSheet.doButtonTextColor = DO_RGB(255, 255, 255);
  vActionSheet.doCancelTextColor = DO_RGB(255, 255, 255);
  vActionSheet.doDestructiveTextColor = DO_RGB(255, 255, 255);

  vActionSheet.doDimmedColor = DO_RGBA(0, 0, 0, 0.7);

  vActionSheet.doTitleFont = [UIFont fontWithName:@"Avenir-Heavy" size:14];
  vActionSheet.doButtonFont = [UIFont fontWithName:@"Avenir-Medium" size:14];
  vActionSheet.doCancelFont = [UIFont fontWithName:@"Avenir-Medium" size:14];

  vActionSheet.doTitleInset = UIEdgeInsetsMake(10, 20, 10, 20);
  vActionSheet.doButtonInset = UIEdgeInsetsMake(5, 20, 5, 20);

  vActionSheet.doButtonHeight = 40.0f;

  [vActionSheet showC:@"How would you like to add external images?"
               cancel:@"Cancel"
              buttons:@[ @"From Web URL", @"From Camera" ]
               result:^(int nResult) {

                   if (nResult == 0) {
                     [self performSegueWithIdentifier:@"canvasToWebImagesIndex"
                                               sender:nil];
                   } else if (nResult == 1) {
                     [self presentViewController:self.imagePicker
                                        animated:NO
                                      completion:nil];
                   }
               }];
}

/**
 *  Add recognizers to self.view, these recognizers are for placing an imported
 *  image.
 */
- (void)addRecognizers {
  // add gestures
  if (self.currentStatus == GUCSketchingVCStatusPlacingImage) {
    [self.view addGestureRecognizer:self.pinchRecognizer];
  }
  [self.view addGestureRecognizer:self.rotationRecognizer];
  [self.view addGestureRecognizer:self.panRecognizer];
}

/**
 *  Remove recognizers for placing an imported image when user is done placing
 *  the image to a position
 */
- (void)removeRecognizers {
  if (self.currentStatus == GUCSketchingVCStatusPlacingImage) {
    [self.view removeGestureRecognizer:self.pinchRecognizer];
  }
  [self.view removeGestureRecognizer:self.rotationRecognizer];
  [self.view removeGestureRecognizer:self.panRecognizer];
}

/**
 *  Return currently activated sketching view (the sketching view that is being
 *  drawn onto
 *
 *  @return currently activated sketching view
 */
- (GUCSketchingView *)currentlyActivatedSketchingView {
  GUCSketchingView *activatedSketchingView = (GUCSketchingView *)
      [self.view viewWithTag:self.currentActivatedSketchingViewTag];
  return activatedSketchingView;
}

/**
 *  Add a new sketch view with the given tag and alpha value into the given
 *  view.
 *
 *  @param tag   tag number
 *  @param alpha alpha value
 *  @param view  the view to be added to
 *
 *  @return the newly created sketch view itself
 */
- (GUCSketchingView *)addNewSketchingViewWithTag:(NSInteger)tag
                                           alpha:(CGFloat)alpha
                                          toView:(UIView *)view {
  GUCSketchingView *newSketchingView =
      [[GUCSketchingView alloc] initWithFrame:self.canvasFrame];
  newSketchingView.tag = tag;
  newSketchingView.delegate = self;
  newSketchingView.userInteractionEnabled = NO;
  newSketchingView.lineColor =
      ((GUCSketchingView *)[self.sketchingViews firstObject]).lineColor;
  [view addSubview:newSketchingView];

  return newSketchingView;
}

/**
 *  In the view hierachy, the sketching views should be ordered as the sequence
 *  in the sketching views array, this method does the job
 */
- (void)reorderSketchingViewsBasedOnSketchingViewArrayOrder {
  for (NSInteger i = self.sketchingViews.count - 1; i >= 0; i--) {
    [self.view bringSubviewToFront:self.sketchingViews[i]];
  }

  // on 3.5 inch devices some controls need to be on top of the canvas
  [self.view bringSubviewToFront:self.alphaSlider];
  [self.view bringSubviewToFront:self.layersButton];
  [self.view bringSubviewToFront:self.alphaButton];
  [self.view bringSubviewToFront:self.addImageButton];
}

/**
 *  Capture the embed view as an image after tapping "accept" when placing an
 *  imported image
 *
 *  @return the captured image of embed view
 */
- (UIImage *)captureImageInView:(UIView *)view {
  UIGraphicsBeginImageContext(view.frame.size);
  [view.layer renderInContext:UIGraphicsGetCurrentContext()];
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

/**
 *  When user has selected an external image, this method is called with that
 *  image to setup the interface for placing the image
 *
 *  @param image the external image selected by user
 */
- (void)prepareForPlacingImageWithImage:(UIImage *)image {
  [self disableNormalButtonsAndAddButtonsForPlacingSelectedImage];

  [self embedImageInImageView:image];

  [self addRecognizers];
}

- (void)processForCancelPlacingImage {
  [self.imageView removeFromSuperview];
  [self.embedView removeFromSuperview];
  //  self.imageView = nil;

  [self enableNormalButtonsAndRemoveButtonsForPlacingSelectedImage];

  [self removeRecognizers];

  self.currentStatus = GUCSketchingVCStatusDrawing;
}

- (void)changeActivatedSketchingViewWithTag:(NSInteger)tag {
  self.currentActivatedSketchingViewTag = tag;
  for (GUCSketchingView *sketchingView in self.sketchingViews) {
    if (sketchingView.tag != self.currentActivatedSketchingViewTag) {
      sketchingView.userInteractionEnabled = NO;
    } else {
      sketchingView.userInteractionEnabled = YES;
    }
  }
  NSLog(@"🔹Did disable other sketching view receiving touch event");
}

/**
 *  Save sketch information into Core Data
 */
- (void)saveSketch {
  GUCCoreDataStack *coreDataStack = [GUCCoreDataStack defaultStack];
  NSManagedObjectContext *context = coreDataStack.managedObjectContext;

  if (self.save) {
    [context deleteObject:self.save];
  }

  GUCSketchSave *save =
      [NSEntityDescription insertNewObjectForEntityForName:@"GUCSketchSave"
                                    inManagedObjectContext:context];
  save.date = [NSDate date];
  UIImage *image = [self imageCombinedWithAllSketchingViews];
  save.image = UIImagePNGRepresentation(image);

  for (GUCSketchingView *sketchingView in self.sketchingViews) {
    GUCSketchSaveDetail *detail = [NSEntityDescription
        insertNewObjectForEntityForName:@"GUCSketchSaveDetail"
                 inManagedObjectContext:context];
    NSData *imageData = UIImagePNGRepresentation(sketchingView.image);
    detail.image = imageData;
    detail.viewTag = [NSNumber numberWithInteger:sketchingView.tag];
    NSNumber *index = [NSNumber
        numberWithInteger:[self.sketchingViews indexOfObject:sketchingView]];
    detail.index = index;
    [save addDetailsObject:detail];
  }

  [coreDataStack saveContext];

  self.save = save;
}

- (UIImage *)imageCombinedWithAllSketchingViews {
  self.embedView = nil;
  [self.view addSubview:self.embedView];
  for (int i = self.sketchingViews.count - 1; i >= 0; i--) {
    UIImageView *imageView = [[UIImageView alloc]
        initWithFrame:CGRectMake(0.0, 0.0, self.embedView.frame.size.width,
                                 self.embedView.frame.size.height)];
    imageView.image = ((GUCSketchingView *)self.sketchingViews[i]).image;
    [self.embedView addSubview:imageView];
  }

  UIImage *capturedImage = [self captureImageInView:self.embedView];
  [self.embedView removeFromSuperview];
  self.embedView = nil;
  return capturedImage;
}

@end
