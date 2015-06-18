//
//  MessageTableViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 21/04/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLMessageTableViewController.h"
#import "Message.h"
#import "TogaytherService.h"
#import "ChatView.h"
#import "MessageService.h"
#import "Event.h"
#import "HPGrowingTextView.h"
#import "PMLSnippetTableViewController.h"
#import "PMLFakeViewController.h"
#import "PhotoPreviewViewController.h"
#import "MKNumberBadgeView.h"
#import "PMLChatLoaderView.h"
#import "PMLChatInputBarView.h"
#import "ChatViewCell.h"
#import "PMLManagedMessage.h"
#import "PMLThreadMessageProvider.h"
#import "PMLConversationMessageProvider.h"
#import "PMLManagedUser.h"
#import "PMLChatLoaderViewCell.h"

#define kRowIdLoad @"loader"
#define kRowIdChatView @"chatView"

#define kSectionCount 3
#define kSectionLoadMore 0
#define kSectionMessages 1
#define kSectionLoadMoreFooter 2

@interface PMLMessageTableViewController ()
@property (nonatomic,retain) ChatView *templateChatView;
@property (nonatomic,retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,retain) DataService *dataService;
@property (nonatomic,retain) NSCache *heightCache;
@end

@implementation PMLMessageTableViewController {
    UserService *userService;
    MessageService *messageService;
    ImageService *imageService;
    UIService *uiService;
    int messagesFetchedCount;

    
    PMLChatLoaderView *_loaderView;
    
    BOOL _keyboardVisible;
    CGPoint _dragStartOffset;
    
    // Photo management
    CALImage *_pendingPhotoUpload;
    
    // Height
    NSInteger _currentPage;

    // Scrolling
    BOOL shouldScrollToBottom;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [TogaytherService applyCommonLookAndFeel:self];
    
    self.view.backgroundColor =UIColorFromRGB(0x272a2e);
    self.tableView.backgroundColor = UIColorFromRGB(0x272a2e);
    self.tableView.separatorColor = UIColorFromRGB(0x272a2e);
    
    userService = [TogaytherService userService];
    messageService = [TogaytherService getMessageService];
    imageService = [TogaytherService imageService];
    uiService = [TogaytherService uiService];
    _dataService = [TogaytherService dataService];
    _managedObjectContext = [[TogaytherService storageService] managedObjectContext];
    self.heightCache = [[NSCache alloc] init];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if([userDefaults objectForKey:@"pushProposedForMessages"] == nil) {
        [userDefaults setObject:@"Done" forKey:@"pushProposedForMessages"];
        [messageService handlePushNotificationProposition:^(BOOL pushActive) {}];
    }
    // Displaying wait message and animation
//    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    hud.mode = MBProgressHUDModeIndeterminate;
//    hud.labelText = NSLocalizedString(@"messages.wait", @"The wait message which appears while loading messages");
    
    // Checking if we have an input, otherwise current user is our input
    if(_withObject == nil) {
        _withObject = [userService getCurrentUser];
    }
    
    // Allocating internal cache structures for storing image thumbs map
    messagesFetchedCount = 0;
    
    if(_withObject==nil || _withObject == [userService getCurrentUser]) {
        self.navigationController.navigationBar.barTintColor = UIColorFromRGB(0x2d3134);
    }


    [self.tableView registerNib:[UINib nibWithNibName:@"ChatViewCell" bundle:nil] forCellReuseIdentifier:kRowIdChatView];
    [self.tableView registerNib:[UINib nibWithNibName:@"PMLChatLoaderViewCell" bundle:nil] forCellReuseIdentifier:kRowIdLoad];
    
    self.templateChatView = (ChatView*)[[TogaytherService uiService] loadView:@"ChatView"];
    self.templateChatView.isTemplate = YES;

    // Message provider
    if([self isAllMessageView] ) {
        self.messageProvider = [[PMLThreadMessageProvider alloc] init];
    } else {
        self.messageProvider = [[PMLConversationMessageProvider alloc] initWithFromUserKey:_withObject.key toUserKey:[[userService getCurrentUser] key]];
        [self readConversationWith:_withObject.key];
    }
    
    // Scrolling
    shouldScrollToBottom = ![self isAllMessageView];

}
-(void)readConversationWith:(NSString*)itemKey {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *context = [[TogaytherService storageService] managedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"PMLManagedUser" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemKey == %@", itemKey];
    [fetchRequest setPredicate:predicate];

    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for(PMLManagedUser *user in fetchedObjects) {
        user.unreadCount = @0;
    }
    if(![context save:&error]) {
        NSLog(@"Failed to save messages as read: %@", error.localizedDescription);
    }
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
    
    [[TogaytherService uiService] setProgressView:self.view];
    [self refreshContents];
}
- (void)scrollToBottom {
    [self.tableView setContentOffset:CGPointMake(0,self.tableView.contentSize.height-self.tableView.bounds.size.height)];
}
-(void)viewDidLayoutSubviews {
    if(shouldScrollToBottom) {
        shouldScrollToBottom = NO;
        [self scrollToBottom];
    }
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
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    [self refreshTable];
}
- (void)refreshTable {
    NSError *error;
    if(![[self.messageProvider fetchedResultsController:self.managedObjectContext delegate:self ] performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        [uiService alertError];
    }

}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id  sectionInfo =
    [[[self.messageProvider fetchedResultsController:self.managedObjectContext delegate:self ] sections] objectAtIndex:0];
    NSInteger maxRows = [self.messageProvider numberOfResults];
    NSInteger sectionRows = [sectionInfo numberOfObjects];
    NSInteger msgRows = MIN(sectionRows,maxRows);

    switch(section) {
        case kSectionLoadMore:
            return [self isAllMessageView] ? 0 : (msgRows == maxRows ? 1 : 0);
        case kSectionMessages:
            return msgRows;
        case kSectionLoadMoreFooter:
            return [self isAllMessageView] ? (msgRows == maxRows ? 1 : 0) : 0;

    }
    return 0;

    // Return the number of rows in the section.
//    return _messagesList.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:(indexPath.section == kSectionMessages ?   kRowIdChatView : kRowIdLoad) forIndexPath:indexPath];
//    NSLog(@"Displaying cell %ld" ,(long)indexPath.row);
    
    switch(indexPath.section) {
        case kSectionLoadMore:
        case kSectionLoadMoreFooter:
            [self configureLoaderView:(PMLChatLoaderViewCell*)cell];
            break;
        case kSectionMessages:
            [self configureChatView:(ChatViewCell*)cell forRow:indexPath];
    }

 
    return cell;
}
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self isAllMessageView];
}
- (Message*)messageFromIndexPath:(NSIndexPath*)indexPath {
    if(![self isAllMessageView]) {
        NSInteger rows = [self tableView:self.tableView numberOfRowsInSection:kSectionMessages];
        return [self.messageProvider messageFromIndexPath:[NSIndexPath indexPathForRow:rows-(indexPath.row+1) inSection:0]];
    } else {
        return [self.messageProvider messageFromIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    Message *message = [self messageFromIndexPath:indexPath];
    PMLMessageTableViewController *targetController = (PMLMessageTableViewController*)[uiService instantiateViewController:SB_ID_MESSAGES];
    [targetController setWithObject:message.from];
    if(self.navigationController == self.parentMenuController.currentSnippetViewController) {
        [self.navigationController pushViewController:targetController animated:YES];
    } else {
        [self.parentMenuController.navigationController pushViewController:targetController animated:YES];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"Height for row: %ld",(long)indexPath.row);

    switch(indexPath.section) {
        case kSectionLoadMore:
        case kSectionLoadMoreFooter:
            return 48;
        case kSectionMessages:
            if([self isAllMessageView]) {
                return 86;
            } else {
                NSNumber *height = [self.heightCache objectForKey:indexPath];
                if(height == nil) {
                    Message *message = [self messageFromIndexPath:indexPath];
                    NSInteger rowHeight = [self.templateChatView setup:message forObject:message.from snippet:[self isAllMessageView]];
                    height = [NSNumber numberWithLong:rowHeight];
                    [self.heightCache setObject:height forKey:indexPath];
                }
                return height.floatValue;
            }
    }
    return 0;
}
-(BOOL) isAllMessageView {
    CurrentUser *currentUser = [userService getCurrentUser];
    BOOL isAllMessageView = [_withObject.key isEqualToString:currentUser.key];
    return isAllMessageView;
}
- (void)configureLoaderView:(PMLChatLoaderViewCell*)cell {
    _loaderView = cell.chatLoaderView;
    
    // Localized labels for loading message and load button
    _loaderView.loaderLabel.text = NSLocalizedString(@"message.loading",@"Loading");
    [_loaderView.loadMessagesButton setTitle:NSLocalizedString(@"message.loadEarlier",@"Load earlier messages") forState:UIControlStateNormal];
    
    // Load button action
    [_loaderView.loadMessagesButton addTarget:self action:@selector(loadEarlierMessages:) forControlEvents:UIControlEventTouchUpInside];
    
    // Adjusting loading message width to fit text
    CGSize fitSize = [_loaderView.loaderLabel sizeThatFits:CGSizeMake(self.view.bounds.size.width, _loaderView.loaderLabel.bounds.size.height)];
    _loaderView.loaderWidthConstraint.constant = fitSize.width;
    
    
    // Positioning at offset
    _loaderView.loadMessagesButton.hidden=NO;
}
-(void) configureChatView:(ChatViewCell*)cell forRow:(NSIndexPath*)indexPath {
    if([self isAllMessageView]) {
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    } else {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    // Configure the cell...
    cell.backgroundColor = BACKGROUND_COLOR;
    if([self isAllMessageView]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    Message *message = [self messageFromIndexPath:indexPath];
    CurrentUser *currentUser = [userService getCurrentUser];
    BOOL isAllMessageView = [self isAllMessageView];
    
    // Setuping chat view
    ChatView *view = cell.chatView;
    [view setup:message forObject:message.from snippet:isAllMessageView];
    if(isAllMessageView) {
        view.bubbleText.userInteractionEnabled=NO;
        view.bubbleTextSelf.userInteractionEnabled=NO;
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
    view.messageImage.tag = indexPath.row;
    [view.messageImage addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(messageImageTapped:)]];
    view.messageImage.userInteractionEnabled=YES;
    view.messageImageSelf.tag = indexPath.row;
    [view.messageImageSelf addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(messageImageTapped:)]];
    view.messageImageSelf.userInteractionEnabled=YES;
    
//    if(indexPath.row % 2 > 0) {
//        view.backgroundColor = UIColorFromRGB(0x343c42);
//    } else {
        view.backgroundColor = UIColorFromRGB(0x272a2e);
//    }
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
//    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    [uiService alertError];
}
- (void) autoFillMessageList {
//    if(_messagesList.count == 0) {
//        id<PMLInfoProvider> provider  = [[TogaytherService uiService] infoProviderFor:_withObject];
//        NSString *msg;
//        if([_withObject isKindOfClass:[User class]]) {
//            CurrentUser *currentUser = [[TogaytherService userService] getCurrentUser];
//            // Only if not listing our own message (inbox)
//            if(![currentUser.key isEqualToString:_withObject.key]) {
//                msg = NSLocalizedString(@"message.user.dummyMessage", @"Intro message");
//            }
//        } else if([_withObject isKindOfClass:[Place class]]) {
//            msg = NSLocalizedString(@"message.place.dummyMessage", @"Intro message");
//        } else if([_withObject isKindOfClass:[Event class]]) {
//            msg = NSLocalizedString(@"message.event.dummyMessage", @"Intro message");
//        }
//        if(msg != nil) {
//            Message *message = [[Message alloc] init];
//            message.from = nil;
//            message.date = [NSDate new];
//            NSString *title = [provider title];
//            message.text = [NSString stringWithFormat:msg,title == nil ? @"" : title ];
//            _messagesList = [@[message] mutableCopy];
//        }
//    }
}
- (void)messagesFetched:(NSArray *)messagesList totalCount:(NSInteger)totalCount page:(NSInteger)page pageSize:(NSInteger)pageSize {

//    for(Message *msg in messagesList) {
//        Message *prevMsg = [_messagesViewsKeys objectForKey:msg.key];
//        if(prevMsg == nil) {
//            [_messagesList addObject:msg];
//            [_messagesViewsKeys setObject:msg forKey:msg.key];
//        }
//    }
//    _messagesList = [[_messagesList sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(id obj1, id obj2) {
//        Message *m1 = (Message*)obj1;
//        Message *m2 = (Message*)obj2;
//        return [m1.key compare:m2.key];
//    }] mutableCopy];
//    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    [self refreshTable ];
//    if(![self isAllMessageView]) {
//        [self.tableView setContentOffset:CGPointMake(0,self.tableView.contentSize.height-self.tableView.bounds.size.height)];
//    }
}
//- (void)messageSent:(Message *)message {
//    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    // Adding a new bubble for this sent message
//    [_messagesList addObject:message];
    
//    [_chatInputBarView.chatTextView endEditing:YES];
//    if(message.mainImage==nil) {
//        _chatInputBarView.chatTextView.text=nil;
//    }
//    if(![_withObject isKindOfClass:[User class]]){
//        _withObject.reviewsCount++;
//    }
    
    // Adding this view
//    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_messagesList.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
//}
//- (void)messageSendFailed {
//    NSLog(@"Message sent failed");
//    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
//    [[TogaytherService uiService] alertWithTitle:@"message.sending.failed.title" text:@"message.sending.failed"];
//}

#pragma mark - Message actions
//- (void)sendMsg:(id)sender {
//    [self sendMessage:_chatInputBarView.chatTextView.text withImage:nil];
//}

//-(void)sendMessage:(NSString*)text withImage:(CALImage*)image {
//    //    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    //    hud.mode = MBProgressHUDModeIndeterminate;
//    //    hud.labelText = NSLocalizedString(@"message.sending", @"Wait message displayed while sending");
//    
//    if([_withObject isKindOfClass:[User class]]) {
//        [messageService sendMessage:text toUser:(User*)_withObject withImage:image messageCallback:self];
//    } else {
//        [messageService postComment:text forObject:_withObject withImage:image messageCallback:self];
//    }
//    [_chatInputBarView.chatTextView resignFirstResponder];
//}

-(void)showFromUserTapped:(UIView*)sender {
//    ChatView *chatView = (ChatView*)sender.superview;
//    NSLog(@"Height : %d - Width : %d - Font : %@ - %d",(int)chatView.bubbleText.bounds.size.height,(int)chatView.bubbleText.bounds.size.width,chatView.bubbleText.font.fontName,(int)chatView.bubbleText.font.pointSize);
    UIButton *button = (UIButton*)sender;
    UIView *view = button.superview;
    if([view isKindOfClass:[ChatView class]]) {
        ChatView *chatView = (ChatView*)view;
        Message *message = chatView.getMessage;
        
        [[TogaytherService uiService] presentSnippetFor:message.from opened:YES root:YES];
    }

}

-(void)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)messageImageTapped:(UIGestureRecognizer*)recognizer {
    // Tag is the index of image
    NSMutableArray *images = [[NSMutableArray alloc] init];
    int index = 0;
    CALImage *initialImage=nil;
    Message *msg= [self messageFromIndexPath:[NSIndexPath indexPathForRow:recognizer.view.tag inSection:kSectionMessages]];
//    for(Message *m in _messagesList) {
        if(msg.mainImage != nil) {
            // Adding to image list
            [images addObject:msg.mainImage];
            
            // If this is our current tapped index, we save the corresponding index of the image array
            if(index == recognizer.view.tag) {
                initialImage = msg.mainImage;
            }
        }
        index++;
//    }
    // Building new imaged from images
    Imaged *imaged = [[Imaged alloc] init];
    imaged.mainImage = [images objectAtIndex:0];
    imaged.otherImages = [[images subarrayWithRange:NSMakeRange(1, images.count-1)] mutableCopy];
    PhotoPreviewViewController *photoController = (PhotoPreviewViewController*)[uiService instantiateViewController:SB_ID_PHOTO_GALLERY];
    photoController.currentImage = initialImage;
    photoController.imaged = imaged;
    
    [self.navigationController pushViewController:photoController animated:YES];
}


-(void)loadEarlierMessages:(id)sender {
//    _loaderView.loadMessagesButton.hidden=YES;
    NSInteger offsetFromBottom = self.tableView.contentSize.height - self.tableView.contentOffset.y;
    [self.messageProvider setNumberOfResults:[self.messageProvider numberOfResults]+20];
    [self.heightCache removeAllObjects];
    [self refreshTable];
    [self.tableView reloadData];
    if(![self isAllMessageView]) {
        [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentSize.height-offsetFromBottom)];
    }
}
#pragma mark - fetchedResultsController


- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
//    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
//    UITableView *tableView = self.tableView;
//    NSIndexPath *shiftedNewIndexPath = [NSIndexPath indexPathForRow:newIndexPath.row inSection:kSectionMessages];
//    NSIndexPath *shiftedIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:kSectionMessages];
//    NSInteger maxResults = [self.messageProvider numberOfResults];
//
//    switch(type) {
//            
//        case NSFetchedResultsChangeInsert:
//            if(newIndexPath.row < maxResults) {
//                [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:shiftedNewIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//            }
//            if (rowsMessages == controller.fetchRequest.fetchLimit) {
//                //Determining which row to delete depends on your sort descriptors
//                [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:controller.fetchRequest.fetchLimit - 1 inSection:kSectionMessages]] withRowAnimation:UITableViewRowAnimationFade];
//            }
//            break;
//            
//        case NSFetchedResultsChangeDelete:
//            if(indexPath.row < maxResults) {
//                [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:shiftedIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//            }
//            break;
//            
//        case NSFetchedResultsChangeUpdate:
//            if(indexPath.row < maxResults) {
//                [self.tableView cellForRowAtIndexPath:shiftedIndexPath];
//            }
//            break;
//            
//        case NSFetchedResultsChangeMove:
//            if(shiftedIndexPath.row< maxResults) {
//                [tableView deleteRowsAtIndexPaths:[NSArray
//                                                   arrayWithObject:shiftedIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//            }
//            if(newIndexPath.row<maxResults) {
//                [tableView insertRowsAtIndexPaths:[NSArray
//                                                   arrayWithObject:shiftedNewIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//                if (rowsMessages == controller.fetchRequest.fetchLimit) {
//                    //Determining which row to delete depends on your sort descriptors
//                    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:controller.fetchRequest.fetchLimit - 1 inSection:kSectionMessages]] withRowAnimation:UITableViewRowAnimationFade];
//                }
//            }
//            break;
//
//    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        default:
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    
//    id  sectionInfo =
//    [[[self.messageProvider fetchedResultsController:self.managedObjectContext delegate:self ] sections] objectAtIndex:0];
//    NSInteger maxRows = [self.messageProvider numberOfResults];
//    NSInteger sectionRows = [sectionInfo numberOfObjects];
//    
//    if(!hasLoadingFooter && [self isAllMessageView] && sectionRows > maxRows) {
//        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:kSectionLoadMoreFooter]] withRowAnimation:UITableViewRowAnimationFade];
//    }
//    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
//    [self.tableView endUpdates];
    [self refreshContents];
    [self.tableView reloadData];
}

@end
