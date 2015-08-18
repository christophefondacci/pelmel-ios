//
//  PMLReportRangeSelectorTableViewCell.m
//  PelMel
//
//  Created by Christophe Fondacci on 17/08/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLReportRangeSelectorTableViewCell.h"

@interface PMLReportRangeSelectorTableViewCell ()

@property (nonatomic,retain) UIButton *selectedButton;
@property (nonatomic,retain) NSArray *allButtons;
@end

@implementation PMLReportRangeSelectorTableViewCell

- (void)awakeFromNib {
    
    // Initialization code
    self.rangeMinButton.tag         = PMLReportRangeDay;
    self.rangeMediumLowButton.tag   = PMLReportRangeWeek;
    self.rangeMediumButton.tag      = PMLReportRangeMonth;
    self.rangeMediumHighButton.tag  = PMLReportRangeTrimester;
    self.rangeMaxButton.tag         = PMLReportRangeSemester;
    self.allButtons = @[self.rangeMinButton,self.rangeMediumLowButton,self.rangeMediumButton,self.rangeMediumHighButton,self.rangeMaxButton];
    
    [self.rangeMinButton addTarget:self action:@selector(rangeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.rangeMediumLowButton addTarget:self action:@selector(rangeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.rangeMediumButton addTarget:self action:@selector(rangeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.rangeMediumHighButton addTarget:self action:@selector(rangeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.rangeMaxButton addTarget:self action:@selector(rangeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)rangeButtonTapped:(UIButton*)button {
    if(self.delegate != nil) {
        [self.delegate didSelectRange:(PMLReportRange)button.tag];
    }
    [_selectedButton setBackgroundColor:[UIColor clearColor]];
    [button setBackgroundColor:UIColorFromRGB(0x00469F)];
    _selectedButton = button;
}
-(void)selectRange:(PMLReportRange)range {
    for(UIButton *button in self.allButtons) {
        if(button.tag == range) {
            [self rangeButtonTapped:button];
        }
    }
    NSLog(@"Invalid range: %d", range);
}
@end
