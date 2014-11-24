//
//  PMLAddTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 20/10/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMLAddTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *addLabel;
@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (weak, nonatomic) IBOutlet UIButton *addButtonIcon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthLabelConstaint;
@property (weak, nonatomic) IBOutlet UIButton *modifyButton;
@property (weak, nonatomic) IBOutlet UIButton *modifyButtonIcon;

@end
