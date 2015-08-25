//
//  PMLListedDealTableViewCell.m
//  PelMel
//
//  Created by Christophe Fondacci on 24/08/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLListedDealTableViewCell.h"

@implementation PMLListedDealTableViewCell

- (void)awakeFromNib {
    // Initialization code
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor colorWithRed:0.92 green:0.46 blue:0 alpha:1];
    [self setSelectedBackgroundView:bgColorView];
    
    self.placeImage.layer.masksToBounds=YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
