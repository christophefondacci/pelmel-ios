//
//  PMLImagedTitleTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 20/11/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMLImagedTitleTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *titleImage;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthTitleConstraint;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@end
