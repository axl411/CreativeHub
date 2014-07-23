//
//  GIF.h
//  MakingGIF
//
//  Created by 顾超 on 14-7-21.
//
//

#import <Foundation/Foundation.h>

@interface GIF : NSObject

+ (NSURL *)makeAnimatedGifFromImages:(NSArray *)images;

@end
