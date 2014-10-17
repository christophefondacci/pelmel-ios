//
//  PMLCountersTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 30/08/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMLCountersTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *likesCounterLabel;
@property (weak, nonatomic) IBOutlet UILabel *checkinsCounterLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentsCounterLabel;
@property (weak, nonatomic) IBOutlet UIView *countersView;
@property (weak, nonatomic) IBOutlet UILabel *likesTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *checkinsTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentsTitleLabel;
@property (weak, nonatomic) IBOutlet UIView *likesContainerView;
@property (weak, nonatomic) IBOutlet UIView *checkinsContainerView;
@property (weak, nonatomic) IBOutlet UIView *commentsContainerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomMargin;

@end
