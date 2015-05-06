//
//  PMLActivityDetailTableViewCell.m
//  PelMel
//
//  Created by Christophe Fondacci on 04/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLActivityDetailTableViewCell.h"

@implementation PMLActivityDetailTableViewCell {

}

- (void)awakeFromNib {
    // Left image tap
    UITapGestureRecognizer *leftTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(leftImageTapped:)];
    [self.leftImage addGestureRecognizer:leftTapRecognizer];
    self.leftImage.userInteractionEnabled=YES;
    
    // Right image tap
    UITapGestureRecognizer *rightTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(rightImageTapped:)];
    [self.rightImage addGestureRecognizer:rightTapRecognizer];
    self.rightImage.userInteractionEnabled = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)leftImageTapped:(id)sender {
    if(self.leftActionCallback != NULL) {
        self.leftActionCallback();
    }
}

- (void)rightImageTapped:(id)sender {
    if(self.rightActionCallback != NULL) {
        self.rightActionCallback();
    }
}

@end
