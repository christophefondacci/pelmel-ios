//
//  PMLBannerViewTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 22/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMLBannerViewTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *bannerImageView;

@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UILabel *startedOnLabel;
@property (weak, nonatomic) IBOutlet UILabel *startDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *usageLabel;
@property (weak, nonatomic) IBOutlet UILabel *usageCounterLabel;

@end
