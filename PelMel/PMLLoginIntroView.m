//
//  PMLLoginIntroView.m
//  PelMel
//
//  Created by Christophe Fondacci on 06/10/2015.
//  Copyright © 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLLoginIntroView.h"
#import "TogaytherService.h"
#import "LoginViewController.h"
#import <MBProgressHUD.h>

@implementation PMLLoginIntroView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)awakeFromNib {
    [self configure];
}
- (void)configure {
    [self.loginButton addTarget:self action:@selector(didTapLogin:) forControlEvents:UIControlEventTouchUpInside];
    [self.registerButton addTarget:self action:@selector(didTapRegister:) forControlEvents:UIControlEventTouchUpInside];
    [self.skipButton addTarget:self action:@selector(didTapSkipButton:) forControlEvents:UIControlEventTouchUpInside];
    self.skipButton.hidden=YES;
    // Facebook init
    self.facebookLoginButton.readPermissions = @[@"public_profile", @"email", @"user_friends"];
    self.facebookLoginButton.delegate=self;
}
-(void)showLoginActions:(BOOL)actionsShown {
    self.loginActionsContainer.hidden=!actionsShown;
    self.skipButton.hidden=YES;
    self.loginMessageContainer.hidden=actionsShown;
}
-(void)login {
    [self showLoginActions:NO];
    BOOL authenticationStarted = [[TogaytherService userService] authenticateWithLastLogin:self];
    if(!authenticationStarted) {
        [self showLoginActions:YES];
    }
}
- (void) didTapLogin:(UIButton*)button {
    UIViewController *loginController = [[TogaytherService uiService] instantiateViewController:@"userLogin"];
    UINavigationController *navController = _parentController.navigationController;
    [navController pushViewController:loginController animated:YES];
}

- (void) didTapRegister:(UIButton*)button {
    LoginViewController *loginController = (LoginViewController*)[[TogaytherService uiService] instantiateViewController:@"userLogin"];
    loginController.loginMode = PMLLoginModeSignUp;
    UINavigationController *navController = _parentController.navigationController;
    [navController pushViewController:loginController animated:YES];
}

-(void)didTapSkipButton:(UIButton*)skipButton {
    NSLog(@"Skipped");
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = NSLocalizedString(@"action.wait", @"action.wait");
    [[TogaytherService userService] skipLoginRegister:self];
}

#pragma mark - PMLUserCallback
- (void)userAuthenticated:(CurrentUser *)user {
    [MBProgressHUD hideAllHUDsForView:self animated:YES];
    [[TogaytherService uiService] startMenuManager];
}
-(void)userRegistered:(CurrentUser *)user {
    [MBProgressHUD hideAllHUDsForView:self animated:YES];
    [[TogaytherService uiService] startMenuManager];
}
- (void)userRegistrationFailed {
    [MBProgressHUD hideAllHUDsForView:self animated:YES];
    [[TogaytherService uiService] alertError];
    [self showLoginActions:YES];
}
- (void)authenticationFailed:(NSString *)reason {
    [MBProgressHUD hideAllHUDsForView:self animated:YES];
    [self showLoginActions:YES];
//    [self didTapLogin:nil];
}
- (void)authenticationImpossible {
    [MBProgressHUD hideAllHUDsForView:self animated:YES];
    [self showLoginActions:YES];
//    [self didTapLogin:nil];
}

#pragma mark - FBLoginViewDelegate
- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)user {
    NSString *accessToken = [[[FBSession activeSession] accessTokenData] accessToken];
    NSString *email = [user objectForKey:@"email"] ? [user objectForKey:@"email"] : [NSString stringWithFormat:@"%@@facebook.com", user.username];
    
    [[TogaytherService userService] authenticateWithFacebook:accessToken email:email callback:self];
}

@end
