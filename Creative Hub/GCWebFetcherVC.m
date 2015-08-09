//
//  GCWebFetcherVC.m
//  Creative Hub
//
//  Created by 顾超 on 14-6-22.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import "GCWebFetcherVC.h"
#import "GCWebImagesIndexVC.h"
#import <HTMLReader/HTMLReader.h>

@interface GCWebFetcherVC ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UITextField *urlTextField;
@property (nonatomic) NSMutableArray *imageAddresses;

@end

@implementation GCWebFetcherVC

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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"WebFetcherToWebImagesIndex"]) {
        GCWebImagesIndexVC *webImagesIndexVC = (GCWebImagesIndexVC *)[segue destinationViewController];
        webImagesIndexVC.imageAddresses = [NSArray arrayWithArray:self.imageAddresses];
        [self.activityIndicator stopAnimating];
    }
}

#pragma mark - Properties

- (NSMutableArray *)imageAddresses
{
    if (!_imageAddresses) {
        _imageAddresses = [[NSMutableArray alloc] init];
    }
    return _imageAddresses;
}

#pragma mark - IBAction

/**
 *  Retrieving images from the url provided, push a collection view to display the images
 *
 *  @param sender
 */
- (IBAction)searchWeb:(UIButton *)sender
{
    [self.urlTextField resignFirstResponder];
    [self.activityIndicator startAnimating];
    self.imageAddresses = nil;
    NSString *urlString = self.urlTextField.text;
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
//    NSLog(@"🔹task starting...");
    [[session dataTaskWithURL:[NSURL URLWithString:urlString] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"🔹Error: %@", error);
            NSLog(@"🔹User Info: %@", [error userInfo]);
        } else {
            NSString *html = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
            
            HTMLDocument *document = [HTMLDocument documentWithString:html];
            
            NSArray *imgNodes = [document nodesMatchingSelector:@"img"];
            
            for (HTMLNode *imgNode in imgNodes) {
                NSString *imageHTMLSourceString = imgNode.description;
                NSError *error = NULL;
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(<img\\s[\\s\\S]*?src\\s*?=\\s*?['\"](.*?)['\"][\\s\\S]*?>)+?" options:NSRegularExpressionCaseInsensitive error:&error];
                
                [regex enumerateMatchesInString:imageHTMLSourceString options:0 range:NSMakeRange(0, [imageHTMLSourceString length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                    NSString *imgURLString = [imageHTMLSourceString substringWithRange:[result rangeAtIndex:2]];
                    NSString *prefix = [imgURLString substringToIndex:4];
                    // if the url doesn't start with "http", then it is a relative address
                    if (![prefix isEqualToString:@"http"]) {
                        imgURLString = [self.urlTextField.text stringByAppendingPathComponent:imgURLString];
                    }
                    [self.imageAddresses addObject:imgURLString];
                }];
                
                if (error) {
                    NSLog(@"🔹Error: %@", [error userInfo]);
                    [self.activityIndicator stopAnimating];
                    return;
                }

            }
            NSLog(@"🔹finished traversing");
            
            [self performSegueWithIdentifier:@"WebFetcherToWebImagesIndex" sender:nil];

            
//            NSError *error = nil;
//            HTMLParser *parser = [[HTMLParser alloc] initWithString:html error:&error];
//            
//            if (error) {
//                NSLog(@"Error: %@", error);
//                [self.activityIndicator stopAnimating];
//                return;
//            } else {
//                HTMLNode *bodyNode = [parser body];
//                
//                NSArray *imgNodes = [bodyNode findChildTags:@"img"];
//                
//                for (HTMLNode *imgNode in imgNodes) {
//                    NSString *imgURLString = [imgNode getAttributeNamed:@"src"];
//                    NSString *prefix = [imgURLString substringToIndex:4];
//                    // if the url doesn't start with "http", then it is a relative address
//                    if (![prefix isEqualToString:@"http"]) {
//                        imgURLString = [self.urlTextField.text stringByAppendingPathComponent:imgURLString];
//                    }
//                    [self.imageAddresses addObject:imgURLString];
//                }
//                
//                [self performSegueWithIdentifier:@"WebFetcherToWebImagesIndex" sender:nil];
//            }
        }
    }] resume];
//    NSLog(@"🔹task started");
}

@end
