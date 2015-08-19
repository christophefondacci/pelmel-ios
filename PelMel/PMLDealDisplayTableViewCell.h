//
//  PMLDealDisplayTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 18/08/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMLDealDisplayTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *dealTitle;
@property (weak, nonatomic) IBOutlet UILabel *dealConditionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *dealIcon;
@property (weak, nonatomic) IBOutlet UIButton *useDealButton;

@end
