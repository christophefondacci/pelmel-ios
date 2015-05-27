//
//  PMLEventTableViewCell.m
//  PelMel
//
//  Created by Christophe Fondacci on 21/02/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLEventTableViewCell.h"

@implementation PMLEventTableViewCell

- (void)awakeFromNib {
    // Initialization code
    self.separatorImage.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ovvSeparatorV"]];
    self.separatorImage.image = nil;
    self.image.clipsToBounds=YES;
    
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor colorWithRed:0.92 green:0.46 blue:0 alpha:1];
    [self setSelectedBackgroundView:bgColorView];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
