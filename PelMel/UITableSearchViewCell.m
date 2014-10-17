//
//  UITableSearchViewCell.m
//  togayther
//
//  Created by Christophe Fondacci on 18/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "UITableSearchViewCell.h"

@implementation UITableSearchViewCell
@synthesize searchBar;

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
