//
//  GCWebImagesIndexVC.m
//  Creative Hub
//
//  Created by 顾超 on 14-6-23.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import "GUCWebImagesIndexVC.h"
#import "GUCWebImageCell.h"
#import <SAMCache/SAMCache.h>
#import <HTMLReader/HTMLReader.h>

@interface GUCWebImagesIndexVC ()

@property(weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property(weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property(nonatomic) UIView *shaderView;
@property(nonatomic) UIActivityIndicatorView *activityIndicator;
@property(weak, nonatomic) IBOutlet UILabel *noImageLabel;

@end

@implementation GUCWebImagesIndexVC

- (NSMutableArray *)imageAddresses {
  if (!_imageAddresses) {
    _imageAddresses = [[NSMutableArray alloc] init];
  }
  return _imageAddresses;
}

- (UIView *)shaderView {
  if (!_shaderView) {
    _shaderView = [[UIView alloc] initWithFrame:self.collectionView.frame];
    _shaderView.backgroundColor = [UIColor blackColor];
    _shaderView.alpha = 0.3f;
    _shaderView.opaque = NO;
  }
  return _shaderView;
}

- (UIActivityIndicatorView *)activityIndicator {
  if (!_activityIndicator) {
    _activityIndicator = [[UIActivityIndicatorView alloc]
        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicator.frame =
        CGRectMake(self.collectionView.frame.size.width / 2 - 22,
                   self.collectionView.frame.size.height / 2 - 22, 44, 44);
    _activityIndicator.hidesWhenStopped = YES;
    [self.shaderView addSubview:_activityIndicator];
  }
  return _activityIndicator;
}

#pragma mark -

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
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

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:
                 (UICollectionView *)collectionView {
  return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
  return [self.imageAddresses count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  GUCWebImageCell *cell =
      [collectionView dequeueReusableCellWithReuseIdentifier:@"WebImageCell"
                                                forIndexPath:indexPath];

  UIImageView *imageView = cell.imageView;
  imageView.image = nil;
  NSString *imageAddressString =
      [self.imageAddresses objectAtIndex:indexPath.row];

  UIActivityIndicatorView *activityIndicator = cell.activityIndicator;
  [activityIndicator startAnimating];

  UIImage *image = [[SAMCache sharedCache] imageForKey:imageAddressString];
  if (image) {
    [activityIndicator stopAnimating];
    imageView.image = image;
  } else {
    NSURL *url = [[NSURL alloc] initWithString:imageAddressString];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    NSURLSessionDownloadTask *task = [session
        downloadTaskWithRequest:request
              completionHandler:^(NSURL *location, NSURLResponse *response,
                                  NSError *error) {
                  if (error) {
                    NSLog(@"🔹ERROR: %@", [error userInfo]);
                  } else {
                    NSData *data =
                        [[NSData alloc] initWithContentsOfURL:location];
                    UIImage *image = [[UIImage alloc] initWithData:data];
                    if (image) {
                      [[SAMCache sharedCache] setImage:image
                                                forKey:imageAddressString];
                      dispatch_async(dispatch_get_main_queue(), ^{
                          [activityIndicator stopAnimating];
                          imageView.image = image;
                      });
                    } else {
                      dispatch_async(dispatch_get_main_queue(), ^{
                          [activityIndicator stopAnimating];
                          imageView.image = [UIImage imageNamed:@"noImage"];
                      });
                    }
                  }
              }];
    [task resume];
  }

  [cell.layer setBorderWidth:2.0f];
  [cell.layer setBorderColor:[UIColor whiteColor].CGColor];

  return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  UIImage *image = [[SAMCache sharedCache]
      imageForKey:[self.imageAddresses objectAtIndex:indexPath.row]];
  NSLog(@"🔹image: %@", image);
  if (image) {
    [self.delegate webImagesIndexVC:self didSelectCellWithImage:image];
  } else {
    UIAlertView *alertView = [[UIAlertView alloc]
            initWithTitle:@"Error"
                  message:@"Error when retrieving image, please try again!"
                 delegate:nil
        cancelButtonTitle:@"OK"
        otherButtonTitles:nil];
    [alertView show];
  }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
  /*
   *  Search the web based on the given url, store image address into an array,
   *  then refresh collection view data
   */
  [self.view sendSubviewToBack:self.noImageLabel];
  [self.view addSubview:self.shaderView];
  [self.activityIndicator startAnimating];

  [self.searchBar resignFirstResponder];
  self.imageAddresses = nil;

  NSString *urlString = self.searchBar.text;

  NSURLSessionConfiguration *defaultConfigObject =
      [NSURLSessionConfiguration defaultSessionConfiguration];
  NSURLSession *session =
      [NSURLSession sessionWithConfiguration:defaultConfigObject
                                    delegate:nil
                               delegateQueue:[NSOperationQueue mainQueue]];
  [[session
        dataTaskWithURL:[NSURL URLWithString:urlString]
      completionHandler:^(NSData *data, NSURLResponse *response,
                          NSError *error) {
          if (error) {
            NSLog(@"🔹Error: %@", error);
            NSLog(@"🔹User Info: %@", [error userInfo]);
            // TODO: prompt the user what the error is
          } else {
            NSString *html =
                [[NSString alloc] initWithData:data
                                      encoding:NSASCIIStringEncoding];

            HTMLDocument *document = [HTMLDocument documentWithString:html];

            NSArray *imgNodes = [document nodesMatchingSelector:@"img"];

            for (HTMLNode *imgNode in imgNodes) {
              NSString *imageHTMLSourceString = imgNode.description;
              NSError *error = NULL;
              NSRegularExpression *regex = [NSRegularExpression
                  regularExpressionWithPattern:
                      @"(<img\\s[\\s\\S]*?src\\s*?=\\s*?['\"](.*?)['\"][\\s\\S]"
                  @"*?>)+?" options:NSRegularExpressionCaseInsensitive
                                         error:&error];

              [regex
                  enumerateMatchesInString:imageHTMLSourceString
                                   options:0
                                     range:NSMakeRange(
                                               0,
                                               [imageHTMLSourceString length])
                                usingBlock:^(NSTextCheckingResult *result,
                                             NSMatchingFlags flags,
                                             BOOL *stop) {
                                    NSString *
                                    imgURLString = [imageHTMLSourceString
                                        substringWithRange:[result
                                                               rangeAtIndex:2]];
                                    NSString *prefix =
                                        [imgURLString substringToIndex:4];

                                    // if the url doesn't start with "http",
                                    // then it is a relative address
                                    if (![prefix isEqualToString:@"http"]) {
                                      imgURLString = [self.searchBar.text
                                          stringByAppendingPathComponent:
                                              imgURLString];
                                    }

                                    // will not add duplicated image url to the
                                    // array
                                    if (![self.imageAddresses
                                            containsObject:imgURLString]) {
                                      [self.imageAddresses
                                          addObject:imgURLString];
                                    }
                                }];

              if (error) {
                NSLog(@"🔹Error: %@", [error userInfo]);
                //                    [self.activityIndicator stopAnimating];
                return;
              }
            }
          }
          [self.collectionView reloadData];
          if ([self.imageAddresses count] < 1) {
            [self.view bringSubviewToFront:self.noImageLabel];
          }

          [self.shaderView removeFromSuperview];
          [self.activityIndicator stopAnimating];
      }] resume];
}

@end
