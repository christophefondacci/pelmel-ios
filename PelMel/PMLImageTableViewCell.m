//
//  PMLImageTableViewCell.m
//  PelMel
//
//  Created by Christophe Fondacci on 13/08/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PMLImageTableViewCell.h"

@implementation PMLImageTableViewCell

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
