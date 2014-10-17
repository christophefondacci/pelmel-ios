//
//  UITableTagViewCell.m
//  togayther
//
//  Created by Christophe Fondacci on 08/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "UITableTagViewCell.h"

@implementation UITableTagViewCell
@synthesize icon;
@synthesize label;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
