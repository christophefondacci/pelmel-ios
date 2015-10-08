//
//  UIIntroViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 07/10/2015.
//  Copyright © 2015 Christophe Fondacci. All rights reserved.
//

#import "UIIntroViewController.h"

@implementation UIIntroViewController

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES];
}
- (void)viewDidDisappear:(BOOL)animated {
    self.loginIntroView.loginActionsContainer.hidden=NO;
    self.loginIntroView.loginMessageContainer.hidden=YES;
}

@end
