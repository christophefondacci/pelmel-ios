//
//  ChatViewCell.m
//  PelMel
//
//  Created by Christophe Fondacci on 15/06/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "ChatViewCell.h"

@implementation ChatViewCell

- (void)awakeFromNib {
    // Initialization code
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor colorWithRed:0.92 green:0.46 blue:0 alpha:1];
    [self setSelectedBackgroundView:bgColorView];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
