//
//  PMLListedDealTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 24/08/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMLListedDealTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *placeImage;
@property (weak, nonatomic) IBOutlet UILabel *placeLabel;
@property (weak, nonatomic) IBOutlet UILabel *dealLabel;
@property (weak, nonatomic) IBOutlet UILabel *dealConditionLabel;
@property (weak, nonatomic) IBOutlet UILabel *useDealButtonLabel;
@property (weak, nonatomic) IBOutlet UIImageView *useDealButtonIcon;

@end
