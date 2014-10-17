//
//  PMLTagsTableViewCell.m
//  PelMel
//
//  Created by Christophe Fondacci on 24/09/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PMLTagsTableViewCell.h"

@implementation PMLTagsTableViewCell

- (void)awakeFromNib {
    // Initialization code
    _tagViews = [[NSMutableArray alloc ] init];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
