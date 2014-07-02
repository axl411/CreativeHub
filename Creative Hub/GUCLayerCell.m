//
//  GUCLayerCell.m
//  Creative Hub
//
//  Created by 顾超 on 14-6-30.
//  Copyright (c) 2014年 Chao Gu. All rights reserved.
//

#import "GUCLayerCell.h"

@implementation GUCLayerCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
