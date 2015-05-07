//
//  PMLActivityDetailTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 04/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MKNumberBadgeView.h"

typedef void(^ActionCallback)();

@interface PMLActivityDetailTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *leftImage;
@property (weak, nonatomic) IBOutlet UIView *leftImageContainer;
@property (weak, nonatomic) IBOutlet UIImageView *rightImage;
@property (weak, nonatomic) IBOutlet UILabel *activityText;
@property (weak, nonatomic) IBOutlet UILabel *activityTimeLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *activityTextHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *activityTextRightConstraint;
@property (copy, nonatomic) ActionCallback leftActionCallback;
@property (copy, nonatomic) ActionCallback rightActionCallback;
@property (nonatomic,retain) MKNumberBadgeView *badgeView;

-(void)showBadge:(BOOL)visible;
@end
