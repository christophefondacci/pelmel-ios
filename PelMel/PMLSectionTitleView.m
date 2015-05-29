//
//  PMLSectionTitleView.m
//  PelMel
//
//  Created by Christophe Fondacci on 22/02/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLSectionTitleView.h"
#import "PopupAction.h"
#import "CALImage.h"

@implementation PMLSectionTitleView {
    NSArray *_popupActions;
}

- (void)awakeFromNib {
    [self.primaryAction setImage:nil forState:UIControlStateNormal];
    [self.primaryAction setTitle:nil forState:UIControlStateNormal];
    [self.secondaryAction setImage:nil forState:UIControlStateNormal];
    [self.secondaryAction setTitle:nil forState:UIControlStateNormal];
    [self.thirdAction setImage:nil forState:UIControlStateNormal];
    [self.thirdAction setTitle:nil forState:UIControlStateNormal];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)setTitleLocalized:(NSString*)localizationCode {
    [self setTitle:NSLocalizedString(localizationCode,@"section title")];
}
- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
    // Adjusting label width to fit label size
    CGSize fitSize = [self.titleLabel sizeThatFits:CGSizeMake(MAXFLOAT, self.titleLabel.bounds.size.height)];
    self.titleLabelWidthConstraint.constant = fitSize.width;
    self.backgroundColor=UIColorFromRGB(0x272a2e); //, 0.2f);
}
- (void)installPopupActions:(NSArray *)popupActions {
    if(popupActions.count>0) {
        [self installPopupAction:popupActions[0] onButton:self.primaryAction forIndex:0];
    }
    if(popupActions.count>1) {
        [self installPopupAction:popupActions[1] onButton:self.secondaryAction forIndex:1];
    }
    if(popupActions.count>2) {
        [self installPopupAction:popupActions[2] onButton:self.thirdAction forIndex:2];
    }
    _popupActions = popupActions;
}

-(void)installPopupAction:(PopupAction*)action onButton:(UIButton*)button forIndex:(NSInteger)index {
    [button setImage:action.icon forState:UIControlStateNormal];
    button.layer.cornerRadius = button.frame.size.width/2;
    button.layer.masksToBounds = YES;
//    button.layer.borderWidth=1;
//    button.layer.borderColor = [action.color CGColor];
    button.tag = index;
    [button addTarget:self action:@selector(actionTapped:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Action callbacks
-(void)actionTapped:(UIButton*)button {
//    PopupAction *action = [_popupActions objectAtIndex:button.tag];
//    action.actionCommand();
}
@end
