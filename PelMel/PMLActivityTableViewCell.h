//
//  PMLActivityTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 31/08/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMLActivityTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *activityTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *activitySubtitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *activityThumbImageView;
@property (weak, nonatomic) IBOutlet UILabel *cityLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *checkinLabel;
@property (weak, nonatomic) IBOutlet UIImageView *checkinImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightTitleConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthSubtitleLabelConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthCityLabelConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthDistanceLabelConstraint;

@end
