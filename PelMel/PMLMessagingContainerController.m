//
//  PMLMessagingContainerControllerViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 15/06/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLMessagingContainerController.h"
#import "PMLMessageTableViewController.h"
#import "TogaytherService.h"

@interface PMLMessagingContainerController ()
@property (nonatomic,retain) PMLMessageTableViewController *messageTableController;
@property (nonatomic,retain) UIService *uiService;
@property (nonatomic,retain) ImageService *imageService;
@property (nonatomic,retain) MessageService *messageService;
@property (nonatomic) BOOL keyboardShown;
@end

@implementation PMLMessagingContainerController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Service init
    self.uiService = [TogaytherService uiService];
    self.imageService = [TogaytherService imageService];
    self.messageService = [TogaytherService getMessageService];
    
    // Setting up current user
    CurrentUser *currentUser = [[TogaytherService userService] getCurrentUser];
    if(_withObject == nil) {
        _withObject = currentUser;
    }
    
    // Look'n feel
    [self.navigationController setNavigationBarHidden:NO animated:YES];

    self.chatTextView.textContainerInset = UIEdgeInsetsMake(2, 0, 2, 0);
    self.chatTextView.maxHeight = 120;
    self.chatTextView.text = nil;

    // Setting up chat input field constraint and title
    if([_withObject.key isEqualToString:currentUser.key]) {
        CGRect textFrame = _footerView.frame;
        self.bottomTextInputConstraint.constant = -textFrame.size.height-6;
        self.title = NSLocalizedString(@"messages.my.title",@"Title of the my messages view");
    } else if([_withObject isKindOfClass:[User class]]){
        self.title = ((User*)_withObject).pseudo;
    } else if([_withObject isKindOfClass:[Place class]]){
        NSString *title = NSLocalizedString(@"message.reviews.title", nil);
        self.title = title;
    }
    
    // Wiring chat actions
    [self configureChatActions];
}

- (void)viewWillAppear:(BOOL)animated {
    if(self.messageTableController == nil) {
        [TogaytherService applyCommonLookAndFeel:self];
        self.edgesForExtendedLayout = UIRectEdgeNone;
        // Child controllers init
        self.messageTableController = (PMLMessageTableViewController*)[self.uiService instantiateViewController:SB_ID_MESSAGES_TABLE];
        self.messageTableController.withObject = self.withObject;
        [self.messageTableView addSubview:self.messageTableController.view];
        UIView *messageView = self.messageTableController.view;
        [messageView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.messageTableView addConstraints:[NSLayoutConstraint
                                     constraintsWithVisualFormat:@"H:|-0-[messageView]-0-|"
                                     options:NSLayoutFormatDirectionLeadingToTrailing
                                     metrics:nil
                                     views:NSDictionaryOfVariableBindings(messageView)]];
        [self.messageTableView addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"V:|-0-[messageView]-0-|"
                                   options:NSLayoutFormatDirectionLeadingToTrailing
                                   metrics:nil
                                   views:NSDictionaryOfVariableBindings(messageView)]];
        [self addChildViewController:self.messageTableController];
        [self.messageTableController didMoveToParentViewController:self];
    }
    [self registerForKeyboardNotifications];
}
- (void)viewWillDisappear:(BOOL)animated {
    [self unregisterForKeyboardNotifications];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Keyboard management
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}
-(void)unregisterForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(void)keyboardWillShow:(NSNotification*)aNotification
{
    
    NSDictionary* info = [aNotification userInfo];
    CGSize _kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    NSNumber *duration = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    CGRect snippetBounds = self.footerView.frame;
    if(snippetBounds.origin.y>_kbSize.height) {
        self.keyboardShown = YES;
        
        // Changing the constraint
        self.bottomTextInputConstraint.constant = _kbSize.height;
        [self.footerView setNeedsUpdateConstraints];
        [self.messageTableView setNeedsUpdateConstraints];
        // Then we move it above keyboard
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:duration.doubleValue];
        [UIView setAnimationCurve:curve.intValue];
        [UIView setAnimationBeginsFromCurrentState:YES];
        // Computing proper Y
        [self.footerView layoutIfNeeded];
        [self.messageTableView layoutIfNeeded];
        CGPoint contentOffset = self.messageTableController.tableView.contentOffset;
        [self.messageTableController.tableView setContentOffset:CGPointMake(contentOffset.x,contentOffset.y+_kbSize.height)];
//        self.footerView.frame = CGRectMake(snippetBounds.origin.x, snippetBounds.origin.y-_kbSize.height, snippetBounds.size.width, snippetBounds.size.height);
        
        [UIView commitAnimations];
        
    }
}
-(void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    
    
    NSDictionary* info = [aNotification userInfo];
    NSNumber *duration = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    CGRect snippetBounds = self.footerView.frame;
    
    if(snippetBounds.origin.y>0 && _keyboardShown) {
        
        // Then we move it above keyboard
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:duration.doubleValue];
        [UIView setAnimationCurve:curve.intValue];
        [UIView setAnimationBeginsFromCurrentState:YES];
        self.bottomTextInputConstraint.constant=0;
        [UIView commitAnimations];
    }
    _keyboardShown = NO;

    
}
#pragma mark - Chat actions
-(void)configureChatActions {
    [self.sendButton addTarget:self action:@selector(sendMsg:) forControlEvents:UIControlEventTouchUpInside];
    [self.sendButton setTitle:NSLocalizedString(@"message.action.send",@"Send") forState:UIControlStateNormal];
    self.sendButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.imageService registerTappable:self.addPhotoButton forViewController:self callback:self];
}
-(void)sendMsg:(UIButton*)sender {
    [self sendMessage:self.chatTextView.text withImage:nil];
}
-(void)sendMessage:(NSString*)text withImage:(CALImage*)image {
    //    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    //    hud.mode = MBProgressHUDModeIndeterminate;
    //    hud.labelText = NSLocalizedString(@"message.sending", @"Wait message displayed while sending");
    
    // Checking that message is not empty
    if(image==nil && (text ==nil || [[text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""])) {
        return;
    }
    
    if([_withObject isKindOfClass:[User class]]) {
        [self.messageService sendMessage:text toUser:(User*)_withObject withImage:image messageCallback:self];
    } else {
        [self.messageService postComment:text forObject:_withObject withImage:image messageCallback:self];
    }
    [_chatTextView resignFirstResponder];
}
#pragma mark - PMLImagePickerCallback
- (void)imagePicked:(CALImage *)image {
    [self sendMessage:@"" withImage:image];
}
#pragma mark - MessageCallback
- (void)messageSent:(Message *)message {
    [self.uiService progressDone ]; //MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    [self.messageTableController messageSent:message];
    
    [_chatTextView endEditing:YES];
    if(message.mainImage==nil) {
        _chatTextView.text=nil;
    }
    if(![_withObject isKindOfClass:[User class]]){
        _withObject.reviewsCount++;
    }
}
- (void)messageSendFailed {
    NSLog(@"Message sent failed");
    [self.uiService progressDone ];
    [[TogaytherService uiService] alertWithTitle:@"message.sending.failed.title" text:@"message.sending.failed"];
}
@end
