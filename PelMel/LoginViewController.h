//
//  LoginViewController.h
//  nativeTest
//
//  Created by Christophe Fondacci on 27/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserService.h"
#import "DatePickerDataSource.h"

@interface LoginViewController : UITableViewController <PMLUserCallback, DateCallback, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *loginEmail;
@property (weak, nonatomic) IBOutlet UITextField *loginPassword;
@property (weak, nonatomic) IBOutlet UITextField *registerEmail;
@property (weak, nonatomic) IBOutlet UITextField *registerPassword;
@property (weak, nonatomic) IBOutlet UITextField *registerPseudo;
@property (weak, nonatomic) IBOutlet UILabel *loginInfo;
@property (weak, nonatomic) IBOutlet UILabel *loginFailed;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loginActivity;
@property (weak, nonatomic) IBOutlet UILabel *loginWaitText;

- (IBAction)loginPressed:(id)sender;
- (IBAction)registerPressed:(id)sender;
- (IBAction)dismiss:(id)sender;

@property (weak, nonatomic) IBOutlet UITableViewCell *loginIntroCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *loginEmailCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *loginPasswordCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *loginButtonCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *registerIntroCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *registerEmailCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *registerPasswordCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *registerPseudoCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *registerTermsCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *registerButtonCell;
//@property (weak, nonatomic) IBOutlet UITableViewCell *registerIntroCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *registerBirthDateCell;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *registerActivity;
@property (weak, nonatomic) IBOutlet UILabel *registeringLabel;
@property (weak, nonatomic) IBOutlet UILabel *registerLabel;
@property (weak, nonatomic) IBOutlet UIButton *registerButton;

@property (weak, nonatomic) IBOutlet UILabel *registerIntroLabel;
@property (weak, nonatomic) IBOutlet UILabel *birthDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *birthDateText;
@property (weak, nonatomic) IBOutlet UILabel *termsOfUseLabel;

@end
