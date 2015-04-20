//
//  PMLPropertyTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 16/04/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMLPropertyTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UITextView *propertyTextView;
@property (weak, nonatomic) IBOutlet UILabel *propertyLabel;
@property (weak, nonatomic) IBOutlet UIImageView *propertyIcon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *propertyLabelWidthConstraint;

@end
