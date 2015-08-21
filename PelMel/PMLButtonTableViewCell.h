//
//  PMLAddEventTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 22/02/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMLButtonTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *buttonLabel;
@property (weak, nonatomic) IBOutlet UIImageView *buttonImageView;
@property (weak, nonatomic) IBOutlet UIView *buttonContainer;
@property (weak, nonatomic) IBOutlet UIButton *button;

@end
