//
//  PMLActivityTableViewCell.m
//  PelMel
//
//  Created by Christophe Fondacci on 31/08/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PMLActivityTableViewCell.h"

@implementation PMLActivityTableViewCell

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
