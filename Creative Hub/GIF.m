//
//  GIF.m
//  MakingGIF
//
//  Created by 顾超 on 14-7-21.
//
//

#import "GIF.h"
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>

@implementation GIF

+ (NSURL *)makeAnimatedGifFromImages:(NSArray *)images {
  NSInteger kFrameCount = images.count;

  NSDictionary *fileProperties = @{
    (__bridge id)kCGImagePropertyGIFDictionary : @{
      (__bridge id)kCGImagePropertyGIFLoopCount : @0, // 0 means loop forever
    }
  };

  NSDictionary *frameProperties = @{
    (__bridge id)kCGImagePropertyGIFDictionary : @{
      (__bridge id)kCGImagePropertyGIFDelayTime :
          @0.025f, // a float (not double!) in seconds, rounded to
                   // centiseconds
                   // in the GIF data
    }
  };

  NSURL *documentsDirectoryURL =
      [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory
                                             inDomain:NSUserDomainMask
                                    appropriateForURL:nil
                                               create:YES
                                                error:nil];
  NSURL *fileURL =
      [documentsDirectoryURL URLByAppendingPathComponent:@"animated.gif"];

  CGImageDestinationRef destination = CGImageDestinationCreateWithURL(
      (__bridge CFURLRef)fileURL, kUTTypeGIF, kFrameCount, NULL);
  CGImageDestinationSetProperties(destination,
                                  (__bridge CFDictionaryRef)fileProperties);

  for (NSUInteger i = 0; i < kFrameCount; i++) {
    UIImage *image = [images objectAtIndex:i];
    CGImageDestinationAddImage(destination, image.CGImage,
                               (__bridge CFDictionaryRef)frameProperties);
  }

  if (!CGImageDestinationFinalize(destination)) {
    NSLog(@"failed to finalize image destination");
  }
  CFRelease(destination);

  NSLog(@"url=%@", fileURL);
  return fileURL;
}

@end