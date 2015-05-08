//
//  PMLActivityStatTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 01/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MKNumberBadgeView.h"

@interface PMLActivityStatTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *activityImage;
@property (weak, nonatomic) IBOutlet UIView *activityImageContainer;
@property (weak, nonatomic) IBOutlet UILabel *activityTitle;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *activityHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *activityLeftMarginConstraint;
@property (retain, nonatomic) MKNumberBadgeView *badgeView;
@property (weak, nonatomic) IBOutlet UIImageView *activityImageBackground;

- (void)showBadge:(BOOL)visible;
@end
