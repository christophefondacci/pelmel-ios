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
    
    // Facebook init
    self.facebookLoginButton.readPermissions = @[@"public_profile", @"email", @"user_friends"];
    self.facebookLoginButton.delegate=self;

}
-(void)login {
    self.loginActionsContainer.hidden=YES;
    self.loginMessageContainer.hidden=NO;
    [[TogaytherService userService] authenticateWithLastLogin:self];
}
- (void) didTapLogin:(UIButton*)button {
    UIViewController *loginController = [[TogaytherService uiService] instantiateViewController:@"userLogin"];
    UINavigationController *navController = (UINavigationController*)[[[[UIApplication sharedApplication] windows] objectAtIndex:0] rootViewController];
    [navController pushViewController:loginController animated:YES];
}

- (void) didTapRegister:(UIButton*)button {
    LoginViewController *loginController = (LoginViewController*)[[TogaytherService uiService] instantiateViewController:@"userLogin"];
    loginController.loginMode = PMLLoginModeSignUp;
    UINavigationController *navController = (UINavigationController*)[[[[UIApplication sharedApplication] windows] objectAtIndex:0] rootViewController];
    [navController pushViewController:loginController animated:YES];
}

#pragma mark - PMLUserCallback
- (void)userAuthenticated:(CurrentUser *)user {
    [[TogaytherService uiService] startMenuManager];
}
- (void)authenticationFailed:(NSString *)reason {
    self.loginActionsContainer.hidden=NO;
    self.loginMessageContainer.hidden=YES;
//    [self didTapLogin:nil];
}
- (void)authenticationImpossible {
    self.loginActionsContainer.hidden=NO;
    self.loginMessageContainer.hidden=YES;
//    [self didTapLogin:nil];
}

#pragma mark - FBLoginViewDelegate
- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)user {
    NSString *accessToken = [[[FBSession activeSession] accessTokenData] accessToken];
    NSString *email = [user objectForKey:@"email"] ? [user objectForKey:@"email"] : [NSString stringWithFormat:@"%@@facebook.com", user.username];
    
    [[TogaytherService userService] authenticateWithFacebook:accessToken email:email callback:self];
}

@end
