//
//  GUCShowAnimationVC.m
//  Creative Hub
//
//  Created by 顾超 on 14-7-21.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import "GUCShowAnimationVC.h"
#import "GUCColors.h"
#import <FLAnimatedImage.h>
#import <FLAnimatedImageView.h>
#import <MessageUI/MessageUI.h>

@interface GUCShowAnimationVC () <MFMailComposeViewControllerDelegate>

@end

@implementation GUCShowAnimationVC

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.navigationController.navigationBar
      setBarTintColor:NavigationBarNormalColor];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.

  FLAnimatedImage *image = [[FLAnimatedImage alloc]
      initWithAnimatedGIFData:[NSData dataWithContentsOfURL:self.gifURL]];
  FLAnimatedImageView *imageView = [[FLAnimatedImageView alloc] init];
  imageView.animatedImage = image;
  imageView.frame = CGRectMake(0.0, 100, 320.0, 320.0);
  [self.view addSubview:imageView];
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

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error {
  switch (result) {
  case MFMailComposeResultCancelled:
    NSLog(@"Mail cancelled");
    break;
  case MFMailComposeResultSaved:
    NSLog(@"Mail saved");
    break;
  case MFMailComposeResultSent:
    NSLog(@"Mail sent");
    break;
  case MFMailComposeResultFailed:
    NSLog(@"Mail sent failure: %@", [error localizedDescription]);
    break;
  default:
    break;
  }

  // Close the Mail Interface
  [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Actions

- (IBAction)donePressed:(UIBarButtonItem *)sender {
  [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)showEmail:(UIBarButtonItem *)sender {
  NSString *emailTitle = @"Funny animation made with Creative Hub";
  NSString *messageBody =
      @"Hey, check this funny animation out! It is made with Creative Hub!";

  MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
  [mc.navigationBar
      setTintColor:[UIColor colorWithRed:0.969 green:0.969 blue:0.969 alpha:1]];
  [mc.navigationBar
      setTitleTextAttributes:[NSDictionary
                                 dictionaryWithObjectsAndKeys:
                                     [UIColor colorWithRed:245.0 / 255.0
                                                     green:245.0 / 255.0
                                                      blue:245.0 / 255.0
                                                     alpha:1.0],
                                     NSForegroundColorAttributeName, nil]];
  mc.mailComposeDelegate = self;
  [mc setSubject:emailTitle];
  [mc setMessageBody:messageBody isHTML:NO];

  // Determine the file name and extension
  NSString *filename = @"Animation";
  NSString *extension = @"gif";

  // Get the resource path and read the file using NSData
  NSString *filePath = [self.gifURL path];
  NSData *fileData = [NSData dataWithContentsOfFile:filePath];

  // Determine the MIME type
  NSString *mimeType;
  if ([extension isEqualToString:@"gif"]) {
    mimeType = @"image/gif";
  }

  // Add attachment
  [mc addAttachmentData:fileData mimeType:mimeType fileName:filename];

  // Present mail view controller on screen
  [self presentViewController:mc
                     animated:YES
                   completion:^{
                       if (([[[UIDevice
                                    currentDevice] systemVersion] floatValue] >=
                            7) &&
                           [[UIApplication sharedApplication]
                               respondsToSelector:NSSelectorFromString(
                                                      @"setStatusBarStyle:")]) {
                         [[UIApplication sharedApplication]
                             setStatusBarStyle:UIStatusBarStyleLightContent];
                       }
                   }];
}

@end
