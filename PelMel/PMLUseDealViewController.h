//
//  PMLUseDealViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 18/08/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PMLDeal.h"

@interface PMLUseDealViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *circleExternalImage;
@property (weak, nonatomic) IBOutlet UIImageView *circleCenterImage;
@property (weak, nonatomic) IBOutlet UIImageView *circleBackgroundImage;
@property (weak, nonatomic) IBOutlet UIImageView *userThumbImage;
@property (weak, nonatomic) IBOutlet UILabel *userNicknameLabel;
@property (weak, nonatomic) IBOutlet UILabel *presentLabel;
@property (weak, nonatomic) IBOutlet UILabel *legalLabel;
@property (weak, nonatomic) IBOutlet UIView *greenOverlay;
@property (weak, nonatomic) IBOutlet UIButton *dealButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *circleWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *circleHeightConstraint;
@property (weak, nonatomic) IBOutlet UILabel *dealCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *reportProblemButton;
@property (weak, nonatomic) IBOutlet UIButton *helpButton;

@property (nonatomic,weak) PMLDeal *deal;

@end
