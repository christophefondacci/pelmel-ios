//
//  LoginViewController.m
//  nativeTest
//
//  Created by Christophe Fondacci on 27/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "LoginViewController.h"
#import "TogaytherService.h"
#import "TogaytherHeaderView.h"
#import "TermsOfUseViewController.h"
#import "PickerInputTableViewCell.h"
#import "UIPelmelTitleView.h"

#define kUserEmailKey @"userEmail"
#define kUserPasswordKey @"userPassword"

#define kSectionsCount 2

#define kSectionLogin 0
#define kSectionRegister 1

#define kRowsLogin 5
#define kRowsRegister 6

#define kRowLoginIntro 0
#define kRowLoginFacebook 1
#define kRowLoginEmail 2
#define kRowLoginPassword 3
#define kRowLoginButton 4

#define kRowRegisterWhy 7
#define kRowRegisterIntro 0
#define kRowRegisterEmail 1
#define kRowRegisterPassword 2
#define kRowRegisterPseudo 3
//#define kRowRegisterBirthday 4
#define kRowRegisterTerms 4
#define kRowRegisterButton 5

#define kFieldOffsetX 20

@interface LoginViewController ()

@end

@implementation LoginViewController {
    UserService *_userService;
    NSUserDefaults *userDefaults;
    
    TogaytherHeaderView *headerView;
    UIPelmelTitleView *registerTitleView;
    
    UIPickerView *datePicker;
    DatePickerDataSource *datePickerDataSource;
    
    NSDate *registerDate;
}
@synthesize loginEmailCell;
@synthesize loginPasswordCell;
@synthesize loginButtonCell;
@synthesize registerEmailCell;
@synthesize registerPasswordCell;
@synthesize registerPseudoCell;
@synthesize registerTermsCell;
@synthesize registerButtonCell;
@synthesize registerActivity;
@synthesize registerIntroCell;
@synthesize registerBirthDateCell;
@synthesize registeringLabel;
@synthesize registerLabel;
@synthesize loginInfo;
@synthesize loginFailed;
@synthesize loginButton;
@synthesize loginActivity;
@synthesize loginWaitText;

@synthesize loginEmail;
@synthesize loginPassword;
@synthesize registerEmail;
@synthesize registerPassword;
@synthesize registerPseudo;



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.backgroundColor = UIColorFromRGB(0xec7700);
    self.tableView.opaque=YES;
    _userService = [TogaytherService userService];
    userDefaults = [NSUserDefaults standardUserDefaults];
    datePickerDataSource = [[DatePickerDataSource alloc] initWithCallback:self];
    
    // Configuring birth date picker
    datePicker = [[UIPickerView alloc] init];
    datePicker.dataSource = datePickerDataSource;
    datePicker.delegate = datePickerDataSource;
    [datePicker setShowsSelectionIndicator:YES];
    datePicker.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [loginFailed setHidden:YES];
    [loginInfo setHidden:NO];
    [loginButton setEnabled:YES];
    [loginActivity setHidden:YES];
    [loginWaitText setHidden:YES];
    
    // Fetching email & password from properties
    NSString *email = (NSString *)[userDefaults objectForKey:kUserEmailKey];
    NSString *passw = (NSString *)[userDefaults objectForKey:kUserPasswordKey];
    
    // Pre-filling login email and password fields from user default settings
    loginEmail.text = email;
    loginPassword.text = passw;
    
    
    // Loading profile header view
    NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"TogaytherHeaderView" owner:self options:nil];
    headerView = [views objectAtIndex:0];
    headerView.togaytherSlogan.text = NSLocalizedString(@"togayther.slogan", "Togayther intro slogan");
    headerView.loginLabel.text = NSLocalizedString(@"login.section.title", "Title of the login section");
    
    views = [[NSBundle mainBundle] loadNibNamed:@"UIPelmelTitleView" owner:self options:nil];
    registerTitleView = [views objectAtIndex:0];
    registerTitleView.titleLabel.text = NSLocalizedString(@"login.section.register.title", @"login.section.register.title");

    // Preparing labels
    registerLabel.text = NSLocalizedString(@"register.label", @"Register info label");
    loginInfo.text = NSLocalizedString(@"logging.label", @"Label next to the login button");
    
    loginEmail.delegate = self;
    loginPassword.delegate = self;
    registerEmail.delegate = self;
    registerPassword.delegate = self;
    registerPseudo.delegate = self;

    // Facebook init
    self.loginFacebookButton.readPermissions = @[@"public_profile", @"email", @"user_friends"];
    self.loginFacebookButton.delegate=self;
}

- (void)viewDidUnload
{
    [self setLoginEmail:nil];
    [self setLoginPassword:nil];
    [self setRegisterEmail:nil];
    [self setRegisterPassword:nil];
    [self setLoginEmailCell:nil];
    [self setLoginPasswordCell:nil];
    [self setLoginButtonCell:nil];
    [self setRegisterEmailCell:nil];
    [self setRegisterPasswordCell:nil];
    [self setRegisterPseudoCell:nil];
    [self setRegisterTermsCell:nil];
    [self setLoginInfo:nil];
    [self setLoginFailed:nil];
    [self setRegisterButtonCell:nil];
    [self setLoginButton:nil];
    [self setRegisterActivity:nil];
    [self setRegisterPseudo:nil];
    [self setRegisteringLabel:nil];
    [self setRegisterLabel:nil];
    [self setLoginActivity:nil];
    [self setLoginWaitText:nil];
    [self setRegisterIntroLabel:nil];
    [self setRegisterIntroCell:nil];
    [self setBirthDateLabel:nil];
    [self setBirthDateText:nil];
    [self setRegisterBirthDateCell:nil];
    [self setTermsOfUseLabel:nil];
    [self setRegisterButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}
- (void)viewDidAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kSectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section) {
        case kSectionLogin:
            return kRowsLogin;
        case kSectionRegister:
            return kRowsRegister;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    
    switch(indexPath.section) {
        case kSectionLogin:
            switch(indexPath.row) {
                case kRowLoginIntro:
                    return self.loginIntroCell;
                case kRowLoginFacebook:
                    
                    return self.loginFacebookCell;
                case kRowLoginEmail: {
                    CGRect frame = self.loginEmailCell.frame;
                    self.loginEmail.frame = CGRectMake(kFieldOffsetX, 6, frame.size.width-2*kFieldOffsetX, 31);
                    return self.loginEmailCell;
                }
                case kRowLoginPassword: {
                    CGRect frame = self.loginPasswordCell.frame;
                    self.loginPassword.frame = CGRectMake(kFieldOffsetX, 6, frame.size.width-2*kFieldOffsetX, 31);
                    return self.loginPasswordCell;
                }
                case kRowLoginButton:
                    return self.loginButtonCell;
            }
            break;
        case kSectionRegister:
            switch(indexPath.row ) {
                case kRowRegisterWhy:
                    _registerIntroLabel.text = NSLocalizedString(@"register.why.intro", nil);
                    return registerIntroCell;
                case kRowRegisterIntro:
                    return self.registerIntroCell;
                case kRowRegisterEmail:
                {
                    CGRect frame = self.registerEmail.frame;
                    self.registerEmail.frame = CGRectMake(kFieldOffsetX, 6, frame.size.width-2*kFieldOffsetX, 31);

                    registerEmail.placeholder = NSLocalizedString(@"login.field.email", @"login.field.email");
                    return registerEmailCell;
                }
                case kRowRegisterPassword:
                {
                    CGRect frame = self.registerPassword.frame;
                    self.registerPassword.frame = CGRectMake(kFieldOffsetX, 6, frame.size.width-2*kFieldOffsetX, 31);
                    

                    registerPassword.placeholder = NSLocalizedString(@"login.field.password", @"login.field.password");
                    return registerPasswordCell;
                }
                case kRowRegisterPseudo:
                {
                    CGRect frame = self.registerPseudo.frame;
                    self.registerPseudo.frame = CGRectMake(kFieldOffsetX, 6, frame.size.width-2*kFieldOffsetX, 31);
                    
                    
                    registerPseudo.placeholder = NSLocalizedString(@"login.field.pseudo", @"login.field.pseudo");
                    return registerPseudoCell;
                }
//                case kRowRegisterBirthday: {
//                    _birthDateLabel.text = NSLocalizedString(@"register.birth.label", nil);
//                    if(registerDate == nil) {
//                        registerDate = [NSDate date];
//                    }
//                    [self dateUpdated:registerDate label:_birthDateText];
//                    [datePickerDataSource registerTargetLabel:_birthDateText];
//
//                    PickerInputTableViewCell *pickerCell = (PickerInputTableViewCell*) registerBirthDateCell;
//                    pickerCell.rowPath = indexPath;
//                    [pickerCell setPicker:datePicker];
//                    return registerBirthDateCell;
//                }
                case kRowRegisterTerms:
                    _termsOfUseLabel.text = NSLocalizedString(@"register.terms.accept", nil);
                    registerTermsCell.accessoryType = UITableViewCellAccessoryNone;
                    return registerTermsCell;
                case kRowRegisterButton:
                    [_registerButton setTitle:NSLocalizedString(@"register.button", @"REGISTER button label") forState:UIControlStateNormal];
                    return registerButtonCell;
            }
            break;
    }
    return cell;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    switch(section) {
        case 0:
            return headerView;
        case 1:
            return registerTitleView;
    }
    return [super tableView:tableView viewForHeaderInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch(section) {
        case 0:
            return headerView.bounds.size.height;
        case 1:
            return registerTitleView.bounds.size.height;
    }
    return [super tableView:tableView heightForHeaderInSection:section];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.section) {
        case kSectionLogin:
            switch(indexPath.row) {
                case kRowLoginIntro:
                    return [loginInfo sizeThatFits:CGSizeMake(loginInfo.bounds.size.width, 2000)].height;
            }
        case kSectionRegister:
            switch(indexPath.row) {
                case kRowRegisterWhy:
                    return 76;
                case kRowRegisterIntro:
                    return 28;
            }
    }
    return 44; //[super tableView:tableView heightForRowAtIndexPath:indexPath];
}

#pragma mark - Table view delegate
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == kSectionRegister && indexPath.row == kRowRegisterTerms;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

- (IBAction)loginPressed:(id)sender {
    [self login];
}
-(void)login {

    
    // Storing login & password in user defaults
    [userDefaults setObject:loginEmail.text forKey:kUserEmailKey];
    [userDefaults setObject:loginPassword.text forKey:kUserPasswordKey];
    
    // Processing with authentication
    [_userService authenticateWithLogin:loginEmail.text password:loginPassword.text callback:self];
}
- (IBAction)registerPressed:(id)sender {
    // Checking valid information
    if([registerEmail.text isEqualToString:@""] || [registerPassword.text isEqualToString:@""] || [registerPseudo.text isEqualToString:@""] || registerPassword.text.length<6 || [registerEmail.text rangeOfString:@"@"].location==NSNotFound) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"register.invalid.title", @"Invalid registration info title")
                                                        message:NSLocalizedString(@"register.invalid.text", @"Invalid registration info text")
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    // Checking age > 12
//    int age = [_userService getAgeFromDate:registerDate];
//    if(age<12) {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"profile.mustBe18.title", @"profile.mustBe18.title")
//                                                        message:NSLocalizedString(@"profile.mustBe18", @"profile.mustBe18")
//                                                       delegate:nil
//                                              cancelButtonTitle:@"OK"
//                                              otherButtonTitles:nil];
//        [alert show];
//        return;
//    }
    [registerActivity startAnimating];
    [registerLabel setHidden:YES];
    registeringLabel.text = NSLocalizedString(@"registering", @"Registering wait message");
    [registeringLabel setHidden:NO];
    NSString *login = registerEmail.text;
    NSString *password = registerPassword.text;
    NSString *pseudo = registerPseudo.text;
    [_userService registerWithLogin:login password:password pseudo:pseudo birthDate:registerDate callback:self];
}

- (IBAction)dismiss:(id)sender {
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([@"terms" isEqualToString:segue.identifier]) {
        TermsOfUseViewController *controller = segue.destinationViewController;
        controller.labelKey = @"terms";
    } else if([@"whyRegister" isEqualToString:segue.identifier]) {
        TermsOfUseViewController *controller = segue.destinationViewController;
        controller.labelKey = @"register.why";
    }
}
-(void)dateUpdated:(NSDate *)date {
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
//    label.text = [dateFormatter stringFromDate:date];
//    [label sizeToFit];
    
    registerDate = date;
    // Unselecting cell
    [registerBirthDateCell setSelected:NO animated:YES];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == loginEmail) {
        [loginPassword becomeFirstResponder];
    } else if(textField == loginPassword) {
        [self loginPressed:self];
    } else if(textField == registerEmail) {
        [registerPassword becomeFirstResponder];
    } else if(textField == registerPassword) {
        [registerPseudo becomeFirstResponder];
    } else if(textField == registerPseudo) {
        [self registerPressed:self];
    }
    return YES;
}


#pragma mark - FBLoginViewDelegate
- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)user {
    NSString *accessToken = [[[FBSession activeSession] accessTokenData] accessToken];
    NSString *email = [user objectForKey:@"email"] ? [user objectForKey:@"email"] : [NSString stringWithFormat:@"%@@facebook.com", user.username];
    
    [_userService authenticateWithFacebook:accessToken email:email callback:self];
}
- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    NSLog(@"Showing logged in user");
}
- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    NSLog(@"Showing logged out user");
}

#pragma mark - PMLUserCallback
- (void)willStartAuthentication {
    [loginFailed setHidden:YES];
    //    [loginInfo setHidden:YES];
    
    // Preventing to login multiple times
    [loginButton setEnabled:NO];
    
    // Activating the activity wait animation
    [loginActivity setHidden:NO];
    [loginActivity startAnimating];
    // Displaying the "logging" message to inform user that something is happening
    loginWaitText.text = NSLocalizedString(@"login.logging", @"Waiting text displayed when the user press 'login' to inform the user that we are processing the login");
    [loginWaitText setHidden:NO];
}
- (void)userAuthenticated:(CurrentUser *)user {
    [loginFailed setHidden:YES];
    [loginInfo setHidden:NO];
    [loginButton setEnabled:YES];
    [loginActivity setHidden:YES];
    [loginActivity stopAnimating];
    [loginWaitText setHidden:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)authenticationFailed:(NSString *)reason {
    
    [self loginError: NSLocalizedString(@"login.failed", @"login.failed")];
    NSLog(@"Login Failed");
}
- (void) loginError:(NSString *)reason {
    loginFailed.text = reason;
    [loginFailed setHidden:NO];
    //    [loginInfo setHidden:YES];
    [loginButton setEnabled:YES];
    [loginActivity setHidden:YES];
    [loginActivity stopAnimating];
    [loginWaitText setHidden:YES];
}
- (void)authenticationImpossible {
    [self loginError:NSLocalizedString(@"login.noconnection", @"login.noconnection")];
}
- (void)userRegistered:(CurrentUser *)user {
    [registerActivity stopAnimating];
    [registerLabel setHidden:NO];
    [registeringLabel setHidden:YES];
    
    // Storing login & password in user defaults
    [userDefaults setObject:user.login forKey:kUserEmailKey];
    [userDefaults setObject:user.password forKey:kUserPasswordKey];
    loginEmail.text = user.login;
    loginPassword.text = user.password;
    
    // Calling edit profile Segue
    [self performSegueWithIdentifier:@"editProfile" sender:self];
}
- (void)userRegistrationFailed {
    [registerActivity stopAnimating];
    registerLabel.text=@"Registration failed";
    [registerLabel setHidden:NO];
    [registeringLabel setHidden:YES];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"register.failed.title", @"register.failed.title")
                                                    message:NSLocalizedString(@"register.failed", @"register.failed")
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}
@end
