//
//  UITablePlaceViewCell.h
//  nativeTest
//
//  Created by Christophe Fondacci on 24/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITablePlaceViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *placeName;
@property (weak, nonatomic) IBOutlet UIView *nameBackground;
@property (weak, nonatomic) IBOutlet UIImageView *thumb;
@property (weak, nonatomic) IBOutlet UIImageView *thumbBackground;
@property (weak, nonatomic) IBOutlet UILabel *distance;
@property (weak, nonatomic) IBOutlet UIImageView *tag1;
@property (weak, nonatomic) IBOutlet UIImageView *tag2;
@property (weak, nonatomic) IBOutlet UIImageView *tag3;
@property (weak, nonatomic) IBOutlet UIImageView *tag4;
@property (weak, nonatomic) IBOutlet UIImageView *tag5;
@property (weak, nonatomic) IBOutlet UILabel *waitingLabel;
@property (weak, nonatomic) IBOutlet UILabel *placeType;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong) NSArray *tags;
@property (weak, nonatomic) IBOutlet UIView *menViewGroup;
@property (weak, nonatomic) IBOutlet UILabel *menInfoLabel;
@property (weak, nonatomic) IBOutlet UIImageView *menInfoIcon;
@property (weak, nonatomic) IBOutlet UILabel *likeInfoLabel;
@property (weak, nonatomic) IBOutlet UIImageView *likeInfoIcon;

@property (weak, nonatomic) IBOutlet UIView *specialsContainer;
@property (weak, nonatomic) IBOutlet UILabel *specialsMainLabel;
@property (weak, nonatomic) IBOutlet UILabel *specialsIntro;
@property (weak, nonatomic) IBOutlet UILabel *specialsSubtitleLabel;
@property (weak, nonatomic) IBOutlet UIView *specialsSubtitleGroup;

@end
