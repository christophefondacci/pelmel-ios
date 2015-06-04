//
//  PMLActivityDetailTableViewCell.m
//  PelMel
//
//  Created by Christophe Fondacci on 04/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLActivityDetailTableViewCell.h"

@implementation PMLActivityDetailTableViewCell {

}

- (void)awakeFromNib {
    // Left image tap
    UITapGestureRecognizer *leftTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(leftImageTapped:)];
    [self.leftImage addGestureRecognizer:leftTapRecognizer];
    self.leftImage.userInteractionEnabled=YES;
    
    // Right image tap
    UITapGestureRecognizer *rightTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(rightImageTapped:)];
    [self.rightImage addGestureRecognizer:rightTapRecognizer];
    self.rightImage.userInteractionEnabled = YES;
    
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor colorWithRed:0.92 green:0.46 blue:0 alpha:1];
    [self setSelectedBackgroundView:bgColorView];

}
- (void)showBadge:(BOOL)visible {
    if(_badgeView != nil) {
        [_badgeView removeFromSuperview];
    }
    if(visible) {
        // Badge
        CGRect frame = self.leftImageContainer.bounds;
        _badgeView =[[MKNumberBadgeView alloc] initWithFrame:CGRectMake(frame.size.width-20, -5, 30, 20)];
        self.leftImageContainer.clipsToBounds = NO;
        _badgeView.shadow = NO;
        _badgeView.shine=NO;
        _badgeView.font = [UIFont fontWithName:PML_FONT_BADGES size:7];
        _badgeView.label = @"NEW";
        _badgeView.layer.zPosition=1;
        [self.leftImageContainer addSubview:_badgeView];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)leftImageTapped:(id)sender {
    if(self.leftActionCallback != NULL) {
        self.leftActionCallback();
    }
}

- (void)rightImageTapped:(id)sender {
    if(self.rightActionCallback != NULL) {
        self.rightActionCallback();
    }
}

@end
