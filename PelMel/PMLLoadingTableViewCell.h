//
//  PMLLoadingTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 30/04/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMLLoadingTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *loadingWidthConstraint;

@end
