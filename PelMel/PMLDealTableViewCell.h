//
//  PMLDealTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 12/08/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMLDealTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *dealHeadlineLabel;
@property (weak, nonatomic) IBOutlet UIButton *dealActivationButton;
@property (weak, nonatomic) IBOutlet UILabel *statusIntroLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *dealQuotaLabelButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *dealQuotaWidthConstraint;
@property (weak, nonatomic) IBOutlet UIButton *dealQuotaEditButton;

@end
