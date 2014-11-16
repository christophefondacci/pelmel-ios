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
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightTitleConstraint;

@end
