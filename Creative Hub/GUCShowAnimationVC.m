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

@interface GUCShowAnimationVC ()

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

@end
