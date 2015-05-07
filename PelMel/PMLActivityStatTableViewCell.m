//
//  PMLActivityStatTableViewCell.m
//  PelMel
//
//  Created by Christophe Fondacci on 01/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLActivityStatTableViewCell.h"

@implementation PMLActivityStatTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)showBadge:(BOOL)visible {
    if(_badgeView != nil) {
        [_badgeView removeFromSuperview];
    }
    if(visible) {
        // Badge
        CGRect frame = self.activityImageContainer.bounds;
        _badgeView =[[MKNumberBadgeView alloc] initWithFrame:CGRectMake(frame.size.width-20, -5, 30, 20)];
        self.activityImageContainer.clipsToBounds = NO;
        _badgeView.shadow = NO;
        _badgeView.shine=NO;
        _badgeView.font = [UIFont fontWithName:PML_FONT_BADGES size:7];
        _badgeView.label = @"NEW";
        _badgeView.layer.zPosition=1;
        [self.activityImageContainer addSubview:_badgeView];
    }
}

@end
