//
//  UITableDescriptionViewCell.h
//  togayther
//
//  Created by Christophe Fondacci on 08/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIInteractiveLabel.h"
#import "PickerInputTableViewCell.h"

@interface UITableDescriptionViewCell : PickerInputTableViewCell

@property (weak, nonatomic) IBOutlet UILabel *languageCodeLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *editButton;

//- (BOOL) isUserInteractionEnabled;
//- (BOOL)canBecomeFirstResponder;
@end
