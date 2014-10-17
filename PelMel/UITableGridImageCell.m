//
//  UITableGridImageCell.m
//  togayther
//
//  Created by Christophe Fondacci on 15/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "UITableGridImageCell.h"

@implementation UITableGridImageCell
@synthesize image1;
@synthesize image2;
@synthesize image3;
@synthesize label1;
@synthesize label2;
@synthesize label3;
@synthesize online1;
@synthesize online2;
@synthesize online3;

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
