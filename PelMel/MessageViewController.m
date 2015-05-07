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
#import "MKNumberBadgeView.h"
#import "PMLChatLoaderView.h"

@interface MessageViewController ()

@end

@implementation MessageViewController {
    UserService *userService;
    MessageService *messageService;
    ImageService *imageService;
    UIService *uiService;
    NSMutableDictionary *imageViewsMap;
    int messagesFetchedCount;
    PMLChatLoaderView *_loaderView;
    
    NSArray *_messagesList;
    NSMutableDictionary *_messagesFromKeys;
    NSMutableDictionary *_messagesViewsKeys;
    
    BOOL _keyboardVisible;
    CGPoint _dragStartOffset;
    
    // Photo management
    CALImage *_pendingPhotoUpload;
    
    // Height
    int _totalHeight;
    NSInteger _currentPage;
    BOOL _loading;
    BOOL _newMessageReceived;
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
    _totalHeight = 0;
    _messagesViewsKeys = [[NSMutableDictionary alloc] init];
    _messagesFromKeys = [[NSMutableDictionary alloc] init];
    
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
    
    // Setting the "new messages" flag to force scroll to the bottom
    _newMessageReceived = YES;
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
    [self refreshContents];
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


#pragma mark - MessageCallback
-(void)appendMessageList:(NSArray*)messagesList {
    BOOL isThread = [self isThreadView];
    // First appending all messages that we don't have yet
    NSMutableArray *msgList = [_messagesList mutableCopy];
    for(Message *msg in messagesList) {
        ChatView *prevMsgView = [_messagesViewsKeys objectForKey:msg.key];
        if(prevMsgView == nil) {
            [msgList addObject:msg];
            if(!isThread) {
                msg.unreadCount=0;
                msg.unread=NO;
            }
        } else {
            [msgList removeObject:prevMsgView.message];
            prevMsgView.message = msg;
            [msgList addObject:msg];
        }
    }

    // If we are on a thread we stack them
    if(isThread) {
        // Building all messages list by date DESC
        NSArray *allMessages = [msgList copy];
        allMessages = [self messagesBySortingDate:allMessages ascending:NO];
        
        // Preparing threaded list
        msgList = [[NSMutableArray alloc ] init];
        _messagesFromKeys = [[NSMutableDictionary alloc] init];
        
        // Folding messages by sender
        for(Message *msg in allMessages) {
            Message *message = [_messagesFromKeys objectForKey:msg.from.key];
            if(message==nil) {
                [msgList addObject:msg];
                [_messagesFromKeys setObject:msg forKey:msg.from.key];
            } else {
                ChatView *prevMsgView = [_messagesViewsKeys objectForKey:msg.key];
                if(prevMsgView != nil) {
                    [prevMsgView removeFromSuperview];
                    [_messagesViewsKeys removeObjectForKey:msg.key];
                }
            }
        }
    }
   
    _messagesList = [self messagesBySortingDate:msgList ascending:!isThread];

}
-(NSArray*)messagesBySortingDate:(NSArray*)messages ascending:(BOOL)ascending {
    return [messages sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(id obj1, id obj2) {
        Message *m1 = (Message*)obj1;
        Message *m2 = (Message*)obj2;
        return ascending ? [m1.date compare:m2.date] : [m2.date compare:m1.date];
    }];

}
-(void)addLoaderButtonAtOffset:(NSInteger)offset {
    if(_loaderView == nil) {
        // Instantiating
        _loaderView = (PMLChatLoaderView*)[uiService loadView:@"PMLChatLoaderView"];
        
        // Localized labels for loading message and load button
        _loaderView.loaderLabel.text = NSLocalizedString(@"message.loading",@"Loading");
        [_loaderView.loadMessagesButton setTitle:NSLocalizedString(@"message.loadEarlier",@"Load earlier messages") forState:UIControlStateNormal];
        
        // Load button action
        [_loaderView.loadMessagesButton addTarget:self action:@selector(loadEarlierMessages:) forControlEvents:UIControlEventTouchUpInside];
        
        // Adjusting loading message width to fit text
        CGSize fitSize = [_loaderView.loaderLabel sizeThatFits:CGSizeMake(self.view.bounds.size.width, _loaderView.loaderLabel.bounds.size.height)];
        _loaderView.loaderWidthConstraint.constant = fitSize.width;
        
        // Adding to scroll view
        [scrollView addSubview:_loaderView];
    }
    // Positioning at offset
    _loaderView.frame = CGRectMake(0, offset, self.view.bounds.size.width, _loaderView.bounds.size.height);
    _loaderView.loadMessagesButton.hidden=NO;
}

- (void)messagesFetched:(NSArray *)messagesList totalCount:(NSInteger)totalCount page:(NSInteger)page pageSize:(NSInteger)pageSize {
    [self appendMessageList:messagesList ];

    // In case it is empty, generating a first message
    [self autoFillMessageList];
    
    BOOL isConversation = ![[userService getCurrentUser].key isEqualToString:_withObject.key];
    BOOL isInitialLoad = (_totalHeight == 0);
    BOOL isPartial = ((page*pageSize+messagesList.count) < totalCount );
    
    // Resetting total height
    _totalHeight = 0;
    
    if(!isPartial) {
        [_loaderView removeFromSuperview];
        _loaderView = nil;
    } else if(isConversation) {
        // If partial and conversation then the loader is the first to be displayed
        [self addLoaderButtonAtOffset:_totalHeight];
        _totalHeight = _loaderView.bounds.size.height;
    }
    
    // A map of all image views hashed by the image key
    int i = 0;
    int addedHeight = 0;
    
    // Storing contentOffset
    CGPoint contentOffset = self.scrollView.contentOffset;
    
    // Processing messages
    for(Message *message in _messagesList) {
        BOOL isAdded = NO;
        if([_messagesViewsKeys objectForKey:message.key]==nil ) {
            isAdded = YES;
        }
        
        // Adding or adjusting message view
        ChatView *chatView = [self addMessageToScrollView:message atHeight:_totalHeight forIndex:i];
        _totalHeight= CGRectGetMaxY(chatView.frame);
        if(isAdded) {
            addedHeight += chatView.frame.size.height;
        }

        // Tags for image tap
        chatView.messageImage.tag = i;
        chatView.messageImageSelf.tag = i;
        i++;
    }
    
    // Adding load button to the end if this is the thread view
    if(isPartial && !isConversation) {
        [self addLoaderButtonAtOffset:_totalHeight];
        _totalHeight += _loaderView.bounds.size.height;
    }
    
    // Ensuring content size is set and restoring original content offset
    [scrollView setContentSize:CGSizeMake(scrollView.bounds.size.width, _totalHeight)];
    [scrollView setContentOffset:contentOffset animated:NO];
    
    // Updating our scroll view
    if(isConversation) {
        // Will be 0 for the first display of view
        if( _newMessageReceived || addedHeight+_loaderView.bounds.size.height == _totalHeight) {
            CGPoint bottomOffset = CGPointMake(0, scrollView.contentSize.height - scrollView.bounds.size.height);
            if(bottomOffset.y>0) {
                [scrollView setContentOffset:bottomOffset animated:(addedHeight>0 && !isInitialLoad)];
            }
        } else {
            // Otherwise we only shift by added height
            [scrollView setContentOffset:CGPointMake(0, scrollView.contentOffset.y+addedHeight) animated:NO];
        }
    } else if(_newMessageReceived) {
        [scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    }
    _newMessageReceived = NO;
    // Updating page
    _currentPage = MAX(_currentPage, page);
    
    // Dismissing progress
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    _loading = NO;
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
- (ChatView*)addMessageToScrollView:(Message*)message atHeight:(NSInteger)height forIndex:(NSInteger)index {
    CurrentUser *currentUser = [userService getCurrentUser];
    BOOL isAllMessageView = [_withObject.key isEqualToString:currentUser.key];
    
    ChatView * view = [_messagesViewsKeys objectForKey:message.key];
    if(view==nil) {
        // Instantiating the Chat view to display current message
        view = (ChatView*)[uiService loadView:@"ChatView"];
//        view.bubbleTextSelfWidthConstraint.constant=150;
//        view.bubbleTextWidthConstraint.constant=150;
        // Registering view
        if(message.key!=nil) {
            [_messagesViewsKeys setObject:view forKey:message.key];
        }
    }
    
    // Adjusting position (mostly width because it is used for height computation
    CGRect frame = view.frame;
    [view setFrame:CGRectMake(frame.origin.x, MAX(height,frame.origin.y), scrollView.bounds.size.width, frame.size.height)];
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
    
    // Uniform background color
    view.backgroundColor = UIColorFromRGB(0x272a2e);
    
    // Thread view, displaying badge for unread messages
    if(_withObject == currentUser) {
        if(message.unreadCount>0) {
            CGRect frame = view.leftThumbButton.bounds;

            // Getting or creating badge view
            MKNumberBadgeView *badge = [self badgeViewFor:view];
            if(badge == nil) {
                badge = [[MKNumberBadgeView alloc] initWithFrame:CGRectMake(frame.size.width-10, -5, 20, 20)];
            }
            badge.shadow = NO;
            badge.shine=NO;
            badge.font = [UIFont fontWithName:PML_FONT_BADGES size:10];
            badge.value = message.unreadCount;
            [view.leftThumbButton addSubview:badge];
        } else {
            [self removeBadgeFrom:view];
        }
    } else {
        message.unread = NO;
        message.unreadCount = 0;
    }
    
    // DEBUG
    NSLog(@"Height : %d - Width : %d",(int)view.bubbleText.bounds.size.height,(int)view.bubbleText.bounds.size.width);
    int totalHeight = height + view.frame.size.height;
    [scrollView setContentSize:CGSizeMake(frame.size.width,totalHeight)];
    return view;
}
-(void)removeBadgeFrom:(ChatView*)view {
    MKNumberBadgeView *badgeView = [self badgeViewFor:view];
    if(badgeView) {
        [badgeView removeFromSuperview];
    }
}
-(MKNumberBadgeView*)badgeViewFor:(ChatView*)view {
    for(UIView *subview in view.leftThumbButton.subviews) {
        if([subview isKindOfClass:[MKNumberBadgeView class]]) {
            return (MKNumberBadgeView*)subview;
        }
    }
    return nil;
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
    if(message.mainImage==nil) {
        _chatTextView.text=nil;
    }
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
    
    // Checking that message is not empty
    if(image==nil && (text ==nil || [[text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""])) {
        return;
    }
    
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
-(void)loadEarlierMessages:(id)sender {
    _loaderView.loadMessagesButton.hidden=YES;
    [self refreshContentsForPage:_currentPage+1];
}
#pragma mark - Notifications
- (void)appBecameActive:(NSNotification*)notification {
    [self refreshContents];
}
-(void)pushNotificationReceived:(NSNotification*)notification {
    _newMessageReceived = YES;
    [self refreshContents];
}
- (void)refreshContents {
    [self refreshContentsForPage:0];
}
-(void)refreshContentsForPage:(NSInteger)page {
    if(!_loading) {
        _loading = YES ;
        if([_withObject isKindOfClass:[User class]]) {
            [messageService getMessagesWithUser:_withObject.key messageCallback:self page:page];
        } else if([_withObject isKindOfClass:[CALObject class]]){
            [messageService getReviewsAsMessagesFor:_withObject.key messageCallback:self page:page];
        }
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
    
    // Checking if loader view is visible
//    CGPoint offset = scrollView.contentOffset;
//    CGRect frame = scrollView.bounds;
//    if(_loaderView != nil && CGRectIntersectsRect(CGRectMake(0, offset.y, frame.size.width, frame.size.height), _loaderView.frame)) {
//        [self refreshContentsForPage:_currentPage+1];
//    }
}

#pragma mark - PMLImagePickerCallback
- (void)imagePicked:(CALImage *)image {
    [self sendMessage:@"" withImage:image];
}
#pragma mark - State
-(BOOL) isThreadView {
    return _withObject==nil || _withObject == [userService getCurrentUser];
}
@end;
