//
//  UITablePlaceViewCell.m
//  nativeTest
//
//  Created by Christophe Fondacci on 24/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "UITablePlaceViewCell.h"

@implementation UITablePlaceViewCell
@synthesize placeName;
@synthesize thumb;
@synthesize distance;
@synthesize tag1;
@synthesize tag2;
@synthesize tag3;
@synthesize tag4;
@synthesize tag5;
@synthesize waitingLabel;
@synthesize placeType;
@synthesize activityIndicator;
@synthesize tags =_tags;
@synthesize menInfoLabel;
@synthesize menInfoIcon;
@synthesize likeInfoLabel;
@synthesize likeInfoIcon;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        _tags = [[NSArray alloc] initWithObjects:tag1,tag2,tag3,tag4,tag5, nil];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
