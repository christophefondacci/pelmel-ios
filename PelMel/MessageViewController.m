//
//  MessageViewController.m
//  togayther
//
//  Created by Christophe Fondacci on 29/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "MessageViewController.h"
#import "Message.h"
#import "TogaytherService.h"
#import "ChatView.h"
#import "MessageService.h"
#import "Event.h"
#import "HPGrowingTextView.h"
#import "PMLSnippetTableViewController.h"
#import "PMLFakeViewController.h"
#import <MBProgressHUD.h>
#import "PhotoPreviewViewController.h"

@interface MessageViewController ()

@end

@implementation MessageViewController {
    UserService *userService;
    MessageService *messageService;
    ImageService *imageService;
    UIService *uiService;
    NSMutableDictionary *imageViewsMap;
    int messagesFetchedCount;
    
//    HPGrowingTextView *_chatTextView;
    
    NSArray *_messagesList;
    NSMutableDictionary *_messagesViewsKeys;
    
    BOOL _keyboardVisible;
    CGPoint _dragStartOffset;
    
    // Photo management
    CALImage *_pendingPhotoUpload;
}
@synthesize scrollView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [TogaytherService applyCommonLookAndFeel:self];

    self.view.backgroundColor =UIColorFromRGB(0x272a2e);
    self.scrollView.backgroundColor = UIColorFromRGB(0x272a2e);

    userService = [TogaytherService userService];
    messageService = [TogaytherService getMessageService];
    imageService = [TogaytherService imageService];
    uiService = [TogaytherService uiService];
    
    _messagesList = @[];
    _messagesViewsKeys = [[NSMutableDictionary alloc] init];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if([userDefaults objectForKey:@"pushProposedForMessages"] == nil) {
        [userDefaults setObject:@"Done" forKey:@"pushProposedForMessages"];
        [messageService handlePushNotificationProposition:^(BOOL pushActive) {
            if(!pushActive) {
                NSString *title = NSLocalizedString(@"push.refused.title",@"");
                NSString *message = NSLocalizedString(@"push.refused.msg",@"");
                NSString *yes = NSLocalizedString(@"push.yes",@"");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:yes otherButtonTitles:nil,nil];
                [alert show];
            }
        }];
    }
    // Displaying wait message and animation
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = NSLocalizedString(@"messages.wait", @"The wait message which appears while loading messages");

    // Checking if we have an input, otherwise current user is our input
    if(_withObject == nil) {
        _withObject = [userService getCurrentUser];
    }
    
    // Allocating internal cache structures for storing image thumbs map
    imageViewsMap =  [[NSMutableDictionary alloc] init];
    messagesFetchedCount = 0;
    
    // Fetching messages
    if([_withObject isKindOfClass:[User class]]) {
        [messageService getMessagesWithUser:_withObject.key messageCallback:self];
    } else if([_withObject isKindOfClass:[CALObject class]]){
        [messageService getReviewsAsMessagesFor:_withObject.key messageCallback:self];
    }

    if(_withObject==nil || _withObject == [userService getCurrentUser]) {
        self.navigationController.navigationBar.barTintColor = UIColorFromRGB(0x2d3134);
    }
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mnuIconClose"] style:UIBarButtonItemStylePlain target:self action:@selector(closeMenu:)];
    [self.navigationController.navigationBar setTitleTextAttributes: @{
                                                                       NSFontAttributeName:[UIFont fontWithName:PML_FONT_DEFAULT size:18],
                                                                       NSForegroundColorAttributeName:[UIColor whiteColor]}];
    CurrentUser *currentUser = [userService getCurrentUser];
    self.chatTextView.textContainerInset = UIEdgeInsetsMake(2, 0, 2, 0);
    self.chatTextView.maxHeight = 120;
    self.chatTextView.text = nil;
    self.scrollView.delegate = self;
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
    
}

- (void)viewDidUnload
{
    [self setScrollView:nil];
    [self setActivityIndicator:nil];
    [self setActivityText:nil];
    [self setActivityBackground:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [TogaytherService applyCommonLookAndFeel:self];
    if(_withObject==nil || _withObject == [userService getCurrentUser]) {
        self.navigationController.navigationBar.barTintColor = UIColorFromRGB(0x2d3134);
    } else {
        [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:0.92 green:0.46 blue:0 alpha:1]];
        self.navigationController.navigationBar.translucent=NO;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [self configureChatInput];
    
    [[TogaytherService uiService] setProgressView:self.view];
}
-(void)viewDidAppear:(BOOL)animated {
    [self.navigationController setToolbarHidden:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appBecameActive:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    // Registering for notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushNotificationReceived:) name:PML_NOTIFICATION_PUSH_RECEIVED object:nil];
}
- (void)viewWillDisappear:(BOOL)animated {
    [_chatTextView resignFirstResponder];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}
#pragma mark - Keyboard notifications
- (void)keyboardWillShow:(NSNotification*)notification {
    [self updateKeyboard:notification up:YES];
    _keyboardVisible = YES;
}
- (void)keyboardWillHide:(NSNotification*)notification {
    [self updateKeyboard:notification up:NO];
    _keyboardVisible = NO;
}
- (void)updateKeyboard:(NSNotification*)notification up:(BOOL)up {
    NSDictionary *userInfo = [notification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardEndFrame;
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];

    [self.view layoutIfNeeded];
    self.bottomTextInputConstraint.constant = up ? keyboardEndFrame.size.height : 0;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [self.view layoutIfNeeded];
    if(up) {
//        scrollView.contentOffset = CGPointMake(0, MIN(scrollView.contentSize.height,scrollView.contentOffset.y+keyboardEndFrame.size.height));
        CGPoint bottomOffset = CGPointMake(0, MAX(scrollView.contentSize.height - scrollView.bounds.size.height,0));
        [scrollView setContentOffset:bottomOffset animated:NO];
    }

    [UIView commitAnimations];

}
#pragma mark - Chat Button
-(void)configureChatInput {
    [self.sendButton addTarget:self action:@selector(sendMsg:) forControlEvents:UIControlEventTouchUpInside];
    [self.sendButton setTitle:NSLocalizedString(@"message.action.send",@"Send") forState:UIControlStateNormal];
    self.sendButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [imageService registerTappable:self.addPhotoButton forViewController:self callback:self];
}

#pragma mark - HPGrowingTextViewDelegate
- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    float diff = (growingTextView.frame.size.height - height);
    
    CGRect r = _footerView.frame;
    r.size.height -= diff;
    r.origin.y += diff;
    _footerView.frame = r;
    
    r = scrollView.frame;
    r.size.height+=diff;
    scrollView.frame=r;
    
}

#pragma mark - MessageCallback
- (void)messagesFetched:(NSArray *)messagesList {
    _messagesList = messagesList;
    // In case it is empty, generating a first message
    [self autoFillMessageList];
    int totalHeight = 0;
    if(messagesFetchedCount == 0) {
        
    }
    
    // Clearing everything
    for(UIView *subview in scrollView.subviews) {
        [subview removeFromSuperview];
    }

    // A map of all image views hashed by the image key
//    NSMutableArray *images = [[NSMutableArray alloc] init];
    int i = 0;
    for(Message *message in _messagesList) {
        NSInteger messageHeight = [self addMessageToScrollView:message atHeight:totalHeight forIndex:i++];
        totalHeight+= messageHeight;
    }
    
    // Updating our scroll view
    if(![_withObject.key isEqualToString:[[userService getCurrentUser] key]]) {
        CGPoint bottomOffset = CGPointMake(0, scrollView.contentSize.height - scrollView.bounds.size.height);
        if(bottomOffset.y>0) {
            [scrollView setContentOffset:bottomOffset animated:NO];
        }
    }
    
    // Dismissing progress
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}
- (void)loadMessageFailed {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    [uiService alertError];
}
- (void) autoFillMessageList {
    if(_messagesList.count == 0) {
        id<PMLInfoProvider> provider  = [[TogaytherService uiService] infoProviderFor:_withObject];
        NSString *msg;
        if([_withObject isKindOfClass:[User class]]) {
            CurrentUser *currentUser = [[TogaytherService userService] getCurrentUser];
            // Only if not listing our own message (inbox)
            if(![currentUser.key isEqualToString:_withObject.key]) {
                msg = NSLocalizedString(@"message.user.dummyMessage", @"Intro message");
            }
        } else if([_withObject isKindOfClass:[Place class]]) {
            msg = NSLocalizedString(@"message.place.dummyMessage", @"Intro message");
        } else if([_withObject isKindOfClass:[Event class]]) {
            msg = NSLocalizedString(@"message.event.dummyMessage", @"Intro message");
        }
        if(msg != nil) {
            Message *message = [[Message alloc] init];
            message.from = nil;
            message.date = [NSDate new];
            NSString *title = [provider title];
            message.text = [NSString stringWithFormat:msg,title == nil ? @"" : title ];
            _messagesList = @[message];
        }
    }
}
- (NSInteger)addMessageToScrollView:(Message*)message atHeight:(NSInteger)height forIndex:(NSInteger)index {
    CurrentUser *currentUser = [userService getCurrentUser];
    BOOL isAllMessageView = [_withObject.key isEqualToString:currentUser.key];
    
    ChatView * view = [_messagesViewsKeys objectForKey:message.key];
    if(view==nil) {
        // Instantiating the Chat view to display current message
        NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"ChatView" owner:self options:nil];
        view = [views objectAtIndex:0];
        // Registering view
        if(message.key!=nil) {
            [_messagesViewsKeys setObject:view forKey:message.key];
        }
    }
    
    // Adjusting position (mostly width because it is used for height computation
    CGRect frame = view.frame;
    [view setFrame:CGRectMake(frame.origin.x, height, scrollView.bounds.size.width, frame.size.height)];
    [view layoutIfNeeded];
    
    // Setuping chat view
    [view setup:message forObject:message.from snippet:isAllMessageView];
    if(isAllMessageView) {
        [view.detailMessageButton setHidden:NO];
        [view.detailMessageButton addTarget:self action:@selector(showMessageTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    // Handling tap on thumb
    UIButton *thumbButton;
    if(message.from != nil) {
        if(![message.from.key isEqualToString:currentUser.key]) {
            thumbButton = view.leftThumbButton;
        } else {
            thumbButton = view.rightThumbButton;
        }
        [thumbButton addTarget:self action:@selector(showFromUserTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    // Handling photo tap
    view.messageImage.tag = index;
    [view.messageImage addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(messageImageTapped:)]];
    view.messageImage.userInteractionEnabled=YES;
    view.messageImageSelf.tag = index;
    [view.messageImageSelf addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(messageImageTapped:)]];
    view.messageImageSelf.userInteractionEnabled=YES;
    
    // Adding
    [scrollView addSubview:view];
    
    // Adjusting position
    frame = view.frame;
    CGSize viewSize = [view systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    [view setFrame:CGRectMake(frame.origin.x, height, scrollView.bounds.size.width, viewSize.height)];

    
    // Setuping image
    CALImage *image = message.from.mainImage;
    [imageService load:image to:view.thumbImage thumb:YES];
    [imageService load:image to:view.thumbImageSelf thumb:YES];
    [view.leftActivity setHidden:YES];
    [view.rightActivity setHidden:YES];
    
    // Stripping lines
    if(index % 2 > 0) {
        view.backgroundColor = UIColorFromRGB(0x343c42);
    } else {
        view.backgroundColor = UIColorFromRGB(0x272a2e);
    }
    
    // DEBUG
    NSLog(@"Height : %d - Width : %d",(int)view.bubbleText.bounds.size.height,(int)view.bubbleText.bounds.size.width);
    int totalHeight = height + view.frame.size.height;
    [scrollView setContentSize:CGSizeMake(frame.size.width,totalHeight)];
    return view.frame.size.height;
}
- (void)messageSent:(Message *)message {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    // Adding a new bubble for this sent message
    [self addMessageToScrollView:message atHeight:scrollView.contentSize.height forIndex:_messagesList.count];

    _messagesList = [_messagesList arrayByAddingObject:message];
    // Scrolling down
    CGPoint bottomOffset = CGPointMake(0, scrollView.contentSize.height - scrollView.bounds.size.height);
    [scrollView setContentOffset:bottomOffset animated:YES];
    
    [_chatTextView endEditing:YES];
    _chatTextView.text=nil;
    if(![_withObject isKindOfClass:[User class]]){
        _withObject.reviewsCount++;
    }
}
- (void)messageSendFailed {
    NSLog(@"Message sent failed");
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    [[TogaytherService uiService] alertWithTitle:@"message.sending.failed.title" text:@"message.sending.failed"];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendMsg:textField];
    return YES;
}

- (BOOL)shouldAutorotate {
    return NO;
}
#pragma mark - Message actions
- (void)sendMsg:(id)sender {
    [self sendMessage:_chatTextView.text withImage:nil];
}

-(void)sendMessage:(NSString*)text withImage:(CALImage*)image {
//    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    hud.mode = MBProgressHUDModeIndeterminate;
//    hud.labelText = NSLocalizedString(@"message.sending", @"Wait message displayed while sending");
    
    if([_withObject isKindOfClass:[User class]]) {
        [messageService sendMessage:text toUser:(User*)_withObject withImage:image messageCallback:self];
    } else {
        [messageService postComment:text forObject:_withObject withImage:image messageCallback:self];
    }
    [_chatTextView resignFirstResponder];
}
-(void)showMessageTapped:(id)sender {
    UIButton *button = (UIButton*)sender;
    UIView *view = button.superview;
    if([view isKindOfClass:[ChatView class]]) {
        ChatView *chatView = (ChatView*)view;
        Message *message = chatView.getMessage;
//        [self performSegueWithIdentifier:@"showDetailMessage" sender:message.from];
        MessageViewController *targetController = (MessageViewController*)[uiService instantiateViewController:SB_ID_MESSAGES];
        [targetController setWithObject:message.from];
        if(self.navigationController == self.parentMenuController.currentSnippetViewController) {
            [self.navigationController pushViewController:targetController animated:YES];
        } else {
            [self.parentMenuController.navigationController pushViewController:targetController animated:YES];
        }

    }
}
-(void)showFromUserTapped:(UIView*)sender {
    ChatView *chatView = (ChatView*)sender.superview;
    NSLog(@"Height : %d - Width : %d - Font : %@ - %d",(int)chatView.bubbleText.bounds.size.height,(int)chatView.bubbleText.bounds.size.width,chatView.bubbleText.font.fontName,(int)chatView.bubbleText.font.pointSize);
    if([_withObject.key isEqualToString:[[userService getCurrentUser] key]]) {
        [self showMessageTapped:sender];
    } else {
        UIButton *button = (UIButton*)sender;
        UIView *view = button.superview;
        if([view isKindOfClass:[ChatView class]]) {
            ChatView *chatView = (ChatView*)view;
            Message *message = chatView.getMessage;
            
            [[TogaytherService uiService] presentSnippetFor:message.from opened:YES root:YES];
        }
    }
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([[segue identifier] isEqualToString:@"showDetailMessage"]) {
        MessageViewController *targetController = [segue destinationViewController];
        [targetController setWithObject:sender];
    } else if([[segue identifier] isEqualToString:@"showUserSnippet"]) {
        PMLSnippetTableViewController *controller = [segue destinationViewController];
        controller.snippetItem = sender;
    }
}
-(void)refresh:(id)sender {
    [_activityIndicator startAnimating];
    [_activityIndicator setHidden:NO];
    [_activityBackground setHidden:NO];
    _activityText.text = NSLocalizedString(@"messages.wait", @"Wait message displayed while sending");
    [_activityText setHidden:NO];
    
    for(UIView *view in scrollView.subviews) {
        [view removeFromSuperview];
    }
    // Fetching messages
    [messageService getMessagesWithUser:_withObject.key messageCallback:self];
}
-(void)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void)closeMenu:(id)sender {
    if(self.navigationController == self.parentMenuController.currentSnippetViewController) {
//        PMLMenuManagerController *menuController = self.parentMenuController;
//        [self.parentMenuController dismissControllerSnippet];
        [[TogaytherService uiService] presentSnippetFor:nil opened:NO];
    } else {
        [self.parentMenuController.navigationController popToRootViewControllerAnimated:YES];
        [self.parentMenuController dismissControllerMenu:YES];
    }
}
#pragma mark - Notifications
- (void)appBecameActive:(NSNotification*)notification {
    [self refreshContents];
}
-(void)pushNotificationReceived:(NSNotification*)notification {
    [self refreshContents];
}
- (void)refreshContents {
    if([_withObject isKindOfClass:[User class]]) {
        [messageService getMessagesWithUser:_withObject.key messageCallback:self];
    } else if([_withObject isKindOfClass:[CALObject class]]){
        [messageService getReviewsAsMessagesFor:_withObject.key messageCallback:self];
    }
}
#pragma mark Message Images
- (void)messageImageTapped:(UIGestureRecognizer*)recognizer {
    // Tag is the index of image
    NSMutableArray *images = [[NSMutableArray alloc] init];
    int index = 0;
    CALImage *initialImage=nil;
    for(Message *m in _messagesList) {
        if(m.mainImage != nil) {
            // Adding to image list
            [images addObject:m.mainImage];
            
            // If this is our current tapped index, we save the corresponding index of the image array
            if(index == recognizer.view.tag) {
                initialImage = m.mainImage;
            }
        }
        index++;
    }
    // Building new imaged from images
    Imaged *imaged = [[Imaged alloc] init];
    imaged.mainImage = [images objectAtIndex:0];
    imaged.otherImages = [[images subarrayWithRange:NSMakeRange(1, images.count-1)] mutableCopy];
    PhotoPreviewViewController *photoController = (PhotoPreviewViewController*)[uiService instantiateViewController:SB_ID_PHOTO_GALLERY];
    photoController.currentImage = initialImage;
    photoController.imaged = imaged;

    [self.navigationController pushViewController:photoController animated:YES];
}
#pragma mark - UIScrollViewDelegate
-(void)scrollViewWillBeginDragging:(UIScrollView *)sView {
    _dragStartOffset = sView.contentOffset;
}
- (void)scrollViewDidScroll:(UIScrollView *)sView {
    if(sView.contentOffset.y < _dragStartOffset.y) {
        [self.chatTextView resignFirstResponder];
    }
}

#pragma mark - PMLImagePickerCallback
- (void)imagePicked:(CALImage *)image {
    [self sendMessage:@"" withImage:image];
}
@end;
