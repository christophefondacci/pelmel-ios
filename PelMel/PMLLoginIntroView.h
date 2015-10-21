//
//  PMLLoginIntroView.h
//  PelMel
//
//  Created by Christophe Fondacci on 06/10/2015.
//  Copyright © 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "UserService.h"

@interface PMLLoginIntroView : UIView <PMLUserCallback,FBLoginViewDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *pelmelLogo;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *registerButton;
@property (weak, nonatomic) IBOutlet FBLoginView *facebookLoginButton;
@property (weak, nonatomic) IBOutlet UIView *loginActionsContainer;
@property (weak, nonatomic) IBOutlet UIView *loginMessageContainer;
@property (weak, nonatomic) IBOutlet UILabel *loginLabel;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;

@property (weak, nonatomic) UIViewController *parentController;
-(void)login;
@end
