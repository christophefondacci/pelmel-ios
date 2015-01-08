//
//  UIPelmelTitleView.h
//  PelMel
//
//  Created by Christophe Fondacci on 21/02/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIPelmelTitleView : UIView
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalSpacingConstraint;

@end
