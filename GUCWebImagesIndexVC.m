//
//  GCWebImagesIndexVC.m
//  Creative Hub
//
//  Created by 顾超 on 14-6-23.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import "GUCWebImagesIndexVC.h"
#import <SAMCache/SAMCache.h>

@interface GUCWebImagesIndexVC ()

@end

@implementation GUCWebImagesIndexVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.imageAddresses count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"WebImageCell" forIndexPath:indexPath];
    
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:100];
    imageView.image = nil;
    NSString *imageAddressString = [self.imageAddresses objectAtIndex:indexPath.row];
    
    UIImage *image = [[SAMCache sharedCache] imageForKey:imageAddressString];
    if (image) {
        imageView.image = image;
    } else {
        NSURL *url = [[NSURL alloc] initWithString:imageAddressString];
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
        NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            NSData *data = [[NSData alloc] initWithContentsOfURL:location];
            UIImage *image = [[UIImage alloc] initWithData:data];
            [[SAMCache sharedCache] setImage:image forKey:imageAddressString];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                imageView.image = image;
            });
        }];
        [task resume];
    }
    
    
    [cell.layer setBorderWidth:2.0f];
    [cell.layer setBorderColor:[UIColor whiteColor].CGColor];
    
    return cell;
}

@end
