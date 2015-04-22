//
//  MessageTableViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 21/04/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "MessageTableViewController.h"
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
#import "PMLChatInputBarView.h"

@interface MessageTableViewController ()

@end

@implementation MessageTableViewController {
    UserService *userService;
    MessageService *messageService;
    ImageService *imageService;
    UIService *uiService;
    NSMutableDictionary *imageViewsMap;
    int messagesFetchedCount;
    PMLChatLoaderView *_loaderView;
    PMLChatInputBarView *_chatInputBarView;
    
    NSMutableArray *_messagesList;
    NSMutableDictionary *_messagesViewsKeys;
    
    BOOL _keyboardVisible;
    CGPoint _dragStartOffset;
    
    // Photo management
    CALImage *_pendingPhotoUpload;
    
    // Height
    int _totalHeight;
    NSInteger _currentPage;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [TogaytherService applyCommonLookAndFeel:self];
    
    self.view.backgroundColor =UIColorFromRGB(0x272a2e);
    self.tableView.backgroundColor = UIColorFromRGB(0x272a2e);
    
    userService = [TogaytherService userService];
    messageService = [TogaytherService getMessageService];
    imageService = [TogaytherService imageService];
    uiService = [TogaytherService uiService];
    
    _messagesList = [[NSMutableArray alloc] init];
    _totalHeight = 0;
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
    
    if(_withObject==nil || _withObject == [userService getCurrentUser]) {
        self.navigationController.navigationBar.barTintColor = UIColorFromRGB(0x2d3134);
    }
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mnuIconClose"] style:UIBarButtonItemStylePlain target:self action:@selector(closeMenu:)];
    [self.navigationController.navigationBar setTitleTextAttributes: @{
                                                                       NSFontAttributeName:[UIFont fontWithName:PML_FONT_DEFAULT size:18],
                                                                       NSForegroundColorAttributeName:[UIColor whiteColor]}];
    CurrentUser *currentUser = [userService getCurrentUser];
    
    // Loading chat input bar view
    if(![_withObject.key isEqualToString:currentUser.key]) {
        _chatInputBarView = (PMLChatInputBarView*)[uiService loadView:@"PMLChatInputBarView"];
        _chatInputBarView.chatTextView.textContainerInset = UIEdgeInsetsMake(2, 0, 2, 0);
        _chatInputBarView.chatTextView.maxHeight = 120;
        _chatInputBarView.chatTextView.text = nil;
        self.tableView.tableFooterView = _chatInputBarView;
    } else {
        self.tableView.tableFooterView = [[UIView alloc] init];
    }
    
    if([_withObject.key isEqualToString:currentUser.key]) {
        self.title = NSLocalizedString(@"messages.my.title",@"Title of the my messages view");
    } else if([_withObject isKindOfClass:[User class]]){
        self.title = ((User*)_withObject).pseudo;
    } else if([_withObject isKindOfClass:[Place class]]){
        NSString *title = NSLocalizedString(@"message.reviews.title", nil);
        self.title = title;
    }
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ChatViewCell" bundle:nil] forCellReuseIdentifier:@"chatView"];
    
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
    self.tableView.estimatedRowHeight = 122;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    // Disabled for now as table view might handle this natively
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
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
    [_chatInputBarView.chatTextView resignFirstResponder];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - Chat Button
-(void)configureChatInput {
    [_chatInputBarView.sendButton addTarget:self action:@selector(sendMsg:) forControlEvents:UIControlEventTouchUpInside];
    [_chatInputBarView.sendButton setTitle:NSLocalizedString(@"message.action.send",@"Send") forState:UIControlStateNormal];
    _chatInputBarView.sendButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [imageService registerTappable:_chatInputBarView.addPhotoButton forViewController:self callback:self];
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
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return _messagesList.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"chatView" forIndexPath:indexPath];
    
    // Configure the cell...
    [self configureChatView:(ChatView*)cell forRow:indexPath.row];
    return cell;
}

-(void) configureChatView:(ChatView*)view forRow:(NSInteger)row {
    
    Message *message = [_messagesList objectAtIndex:row];
    CurrentUser *currentUser = [userService getCurrentUser];
    BOOL isAllMessageView = [_withObject.key isEqualToString:currentUser.key];
    
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
    view.messageImage.tag = row;
    [view.messageImage addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(messageImageTapped:)]];
    view.messageImage.userInteractionEnabled=YES;
    view.messageImageSelf.tag = row;
    [view.messageImageSelf addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(messageImageTapped:)]];
    view.messageImageSelf.userInteractionEnabled=YES;
    
    if(row % 2 > 0) {
        view.backgroundColor = UIColorFromRGB(0x343c42);
    } else {
        view.backgroundColor = UIColorFromRGB(0x272a2e);
    }
    // Setuping image
    CALImage *image = message.from.mainImage;
    [imageService load:image to:view.thumbImage thumb:YES];
    [imageService load:image to:view.thumbImageSelf thumb:YES];
    [view.leftActivity setHidden:YES];
    [view.rightActivity setHidden:YES];
    // Thread view, displaying badge for unread messages
    if(_withObject == currentUser) {
        if(message.unreadCount>0) {
            CGRect frame = view.leftThumbButton.bounds;
            MKNumberBadgeView *badge = [[MKNumberBadgeView alloc] initWithFrame:CGRectMake(frame.size.width-10, -5, 20, 20)];
            badge.shadow = NO;
            badge.shine=NO;
            badge.font = [UIFont fontWithName:PML_FONT_BADGES size:10];
            badge.value = message.unreadCount;
            [view.leftThumbButton addSubview:badge];
        } else {
            for(UIView *subview in view.leftThumbButton.subviews) {
                if([subview isKindOfClass:[MKNumberBadgeView class]]) {
                    [subview removeFromSuperview];
                }
            }
        }
    } else {
        message.unread = NO;
        message.unreadCount = 0;
    }

}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Message management
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
            _messagesList = [@[message] mutableCopy];
        }
    }
}
- (void)messagesFetched:(NSArray *)messagesList totalCount:(NSInteger)totalCount page:(NSInteger)page pageSize:(NSInteger)pageSize {
    for(Message *msg in messagesList) {
        Message *prevMsg = [_messagesViewsKeys objectForKey:msg.key];
        if(prevMsg == nil) {
            [_messagesList addObject:msg];
            [_messagesViewsKeys setObject:msg forKey:msg.key];
        }
    }
    _messagesList = [[_messagesList sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(id obj1, id obj2) {
        Message *m1 = (Message*)obj1;
        Message *m2 = (Message*)obj2;
        return [m1.key compare:m2.key];
    }] mutableCopy];
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    [self.tableView reloadData];
}
- (void)messageSent:(Message *)message {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    // Adding a new bubble for this sent message
    [_messagesList addObject:message];
    
    [_chatInputBarView.chatTextView endEditing:YES];
    if(message.mainImage==nil) {
        _chatInputBarView.chatTextView.text=nil;
    }
    if(![_withObject isKindOfClass:[User class]]){
        _withObject.reviewsCount++;
    }
    
    // Adding this view
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_messagesList.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
}
- (void)messageSendFailed {
    NSLog(@"Message sent failed");
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    [[TogaytherService uiService] alertWithTitle:@"message.sending.failed.title" text:@"message.sending.failed"];
}

#pragma mark - Message actions
- (void)sendMsg:(id)sender {
    [self sendMessage:_chatInputBarView.chatTextView.text withImage:nil];
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
    [_chatInputBarView.chatTextView resignFirstResponder];
}
-(void)showMessageTapped:(id)sender {
    UIButton *button = (UIButton*)sender;
    
    UIView *view = button.superview;
    while(view != nil ) {
        if([view isKindOfClass:[ChatView class]]) {
            ChatView *chatView = (ChatView*)view;
            Message *message = chatView.getMessage;
            //        [self performSegueWithIdentifier:@"showDetailMessage" sender:message.from];
            MessageTableViewController *targetController = (MessageTableViewController*)[uiService instantiateViewController:@"messageTableView"];
            [targetController setWithObject:message.from];
            if(self.navigationController == self.parentMenuController.currentSnippetViewController) {
                [self.navigationController pushViewController:targetController animated:YES];
            } else {
                [self.parentMenuController.navigationController pushViewController:targetController animated:YES];
            }
            return ;
        }
        view = view.superview;
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
@end
