//
//  PMLAddTableViewCell.m
//  PelMel
//
//  Created by Christophe Fondacci on 20/10/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PMLAddTableViewCell.h"

@implementation PMLAddTableViewCell

- (void)awakeFromNib {
    // Initialization code
    [self.addButton setTitle:NSLocalizedString(@"map.option.add", @"Add") forState:UIControlStateNormal];
    [self.modifyButton setTitle:NSLocalizedString(@"modify", @"modify") forState:UIControlStateNormal];
    
    [self.addButton addTarget:self action:@selector(addTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.addButtonIcon addTarget:self action:@selector(addTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.modifyButton addTarget:self action:@selector(modifyTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.modifyButtonIcon addTarget:self action:@selector(modifyTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    // Colors (a bug reverts colors of buttons to blue
    self.addButton.titleLabel.textColor = UIColorFromRGB(0x2db024);
    self.modifyButton.titleLabel.textColor = [UIColor whiteColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)addTapped:(UIButton*)button {
    [self.delegate addTapped:self];
}
-(void)modifyTapped:(UIButton*)button {
    [self.delegate modifyTapped:self];
}
@end
