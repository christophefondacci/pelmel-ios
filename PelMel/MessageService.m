//
//  MessageService.m
//  togayther
//
//  Created by Christophe Fondacci on 27/12/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "MessageService.h"
#import "TogaytherService.h"
#import "Message.h"
#import "MKNumberBadgeView.h"
#import <QuartzCore/QuartzCore.h>
#import "NSData+Conversion.h"
#import <AFNetworking/AFNetworking.h>

//#define kMessagesListUrlFormat @"%@/mobileMyMessagesReply?lat=%f&lng=%f&nxtpUserToken=%@&highRes=%@&from=%@"
//#define kMyMessagesListUrlFormat @"%@/mobileMyMessages?lat=%f&lng=%f&nxtpUserToken=%@&highRes=%@"
//#define kReviewsListUrlFormat @"%@/mobileComments?lat=%f&lng=%f&nxtpUserToken=%@&highRes=%@&id=%@"
#define kMessagesListUrlFormat @"%@/mobileMyMessagesReply"
#define kMyMessagesListUrlFormat @"%@/mobileMyMessages"
#define kReviewsListUrlFormat @"%@/mobileComments"
#define kParamLat @"lat"
#define kParamLng @"lng"
#define kParamToken @"nxtpUserToken"
#define kParamRetina @"highRes"
#define kParamId @"id"
#define kParamFrom @"from"
#define kParamPage @"page"
#define kSendMessageUrlFormat @"%@/mobileSendMsg"
#define kPostCommentUrlFormat @"%@/mobilePostComment"
#define kTopQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)

@implementation MessageService {

    NSString *togaytherServer;
    NSMutableDictionary *uploadConnectionCallbacksMap;
    NSMutableDictionary *uploadMessagesMap;
    UIViewController *currentViewController;
    MKNumberBadgeView *numberBadge;
    int _unreadMessageCount;
    UIButton *badgeButton;
    
    NSUserDefaults *_userDefaults;
    // Push dialog
    PushPropositionCallback _pushCompletion;
    
    NSMutableArray *_messageCallbacks;
}

@synthesize userService = userService;

- (id)init
{
    self = [super init];
    if (self) {
        togaytherServer = [TogaytherService propertyFor:PML_PROP_SERVER];
        _userDefaults = [NSUserDefaults standardUserDefaults];
        uploadConnectionCallbacksMap= [[NSMutableDictionary alloc] init];
        uploadMessagesMap = [[NSMutableDictionary alloc] init];
        _unreadMessageCount = 0;
        _messageCallbacks = [[NSMutableArray alloc] init];
    }
    return self;
}
-(void)getReviewsAsMessagesFor:(NSString *)itemKey messageCallback:(id<MessageCallback>)callback {
    [self getReviewsAsMessagesFor:itemKey messageCallback:callback page:0];
}
-(void)getReviewsAsMessagesFor:(NSString *)itemKey messageCallback:(id<MessageCallback>)callback page:(NSInteger)page {
    // Getting current user and some device settings
    CurrentUser *user = userService.getCurrentUser;
    BOOL retina = [TogaytherService isRetina];
    
    // Building URL
    NSString *url;
    url = [[NSString alloc] initWithFormat:kReviewsListUrlFormat,togaytherServer ];//, user.lat, user.lng, user.token, retina ? @"true" : @"false", itemKey];
    
    // Building parameters
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[NSString stringWithFormat:@"%f",user.lat] forKey:kParamLat];
    [params setObject:[NSString stringWithFormat:@"%f",user.lng] forKey:kParamLng];
    [params setObject:user.token forKey:kParamToken];
    [params setObject:(retina ? @"true" : @"false") forKey:kParamRetina];
    [params setObject:itemKey forKey:kParamId];
    [params setObject:[NSString stringWithFormat:@"%d",page] forKey:kParamPage];
    
    NSLog(@"Fetching reviews for '%@' : %@",itemKey,url);
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Processing JSON message response
        [self processJsonMessage:(NSDictionary*)responseObject messageCallback:callback forUserKey:nil];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [callback loadMessageFailed];
    }];

}
- (void)getMessagesWithUser:(NSString *)userKey messageCallback:(id<MessageCallback>)callback {
    [self getMessagesWithUser:userKey messageCallback:callback page:0];
}
- (void)getMessagesWithUser:(NSString *)userKey messageCallback:(id<MessageCallback>)callback page:(NSInteger)page{
    // Getting current user and some device settings
    CurrentUser *user = userService.getCurrentUser;
    if(user == nil) {
        return;
    }
    
    // Preparing params
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    // Building URL
    NSString *url;
    if([userKey isEqualToString:user.key]) {
        url = [[NSString alloc] initWithFormat:kMyMessagesListUrlFormat,togaytherServer ];
    } else {
        url = [[NSString alloc] initWithFormat:kMessagesListUrlFormat,togaytherServer];
        [params setObject:userKey forKey:kParamFrom];
    }
    
    // Filling params
    BOOL retina = [TogaytherService isRetina];
    [params setObject:[NSString stringWithFormat:@"%f",user.lat] forKey:kParamLat];
    [params setObject:[NSString stringWithFormat:@"%f",user.lng] forKey:kParamLng];
    [params setObject:user.token forKey:kParamToken];
    [params setObject:(retina ? @"true" : @"false") forKey:kParamRetina];
    [params setObject:[NSString stringWithFormat:@"%d",page] forKey:kParamPage];
    
    NSLog(@"URL: %@",url);
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Processing JSON message response
        [self processJsonMessage:(NSDictionary*)responseObject messageCallback:callback forUserKey:userKey];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [callback loadMessageFailed];
    }];
}
-(void)processJsonMessage:(NSDictionary*)jsonMessageList messageCallback:(id<MessageCallback>)callback forUserKey:(NSString*)userKey {
    CurrentUser *user = userService.getCurrentUser;
    NSMutableDictionary *usersMap = [[NSMutableDictionary alloc] init];
    if([userKey isEqualToString:user.key] || userKey == nil) {
        NSArray *jsonUsers = [jsonMessageList objectForKey:@"users"];
        for(NSDictionary *jsonUser in jsonUsers) {
            User *aUser = [_jsonService convertJsonUserToUser:jsonUser];
            [usersMap setValue:aUser forKey:aUser.key];
        }
        
    } else {
        // Getting other user
        NSDictionary *jsonOtherUser = [jsonMessageList objectForKey:@"toUser"];
        User *otherUser = [_jsonService convertJsonUserToUser:jsonOtherUser];
        [usersMap setValue:otherUser forKey:otherUser.key];
    }
    // Getting current user
    CurrentUser *currentUser = [userService getCurrentUser];
    [usersMap setValue:currentUser forKey:currentUser.key];
    
    // Getting unread message count
    NSNumber *unreadMsgCount = [jsonMessageList objectForKey:@"unreadMsgCount"];
    [self setUnreadMessageCount:[unreadMsgCount intValue]];
    NSNumber *totalMsgCount = [jsonMessageList objectForKey:@"totalMsgCount"];
    NSNumber *page          = [jsonMessageList objectForKey:@"page"];
    NSNumber *pageSize      = [jsonMessageList objectForKey:@"pageSize"];
    
    // Getting message list
    NSArray *messages = [jsonMessageList objectForKey:@"messages"];
    NSMutableArray *calMessages = [[NSMutableArray alloc] initWithCapacity:messages.count];
    for(NSDictionary *message in messages) {
        NSString *key       = [message objectForKey:@"key"];
        NSString *fromKey   = [message objectForKey:@"fromKey"];
        NSString *toKey     = [message objectForKey:@"toKey"];
        NSString *text      = [message objectForKey:@"message"];
        NSNumber *msgTime   = [message objectForKey:@"time"];
        NSNumber *unread    = [message objectForKey:@"unread"];
        NSDictionary *media = [message objectForKey:@"media"];
        
        long time = [msgTime longValue];
        NSDate *msgDate = [[NSDate alloc] initWithTimeIntervalSince1970:time];
        
        Message *m = [[Message alloc] init];
        m.key = key;
        User *fromUser = [usersMap objectForKey:fromKey];
        [m setFrom:fromUser];
        User *toUser = [usersMap objectForKey:toKey];
        [m setTo:toUser];
        [m setText:text];
        [m setDate:msgDate];
        [m setUnread:[unread boolValue]];
        [m setUnreadCount:[unread integerValue]];
        
        if(media != nil) {
            CALImage *image = [[TogaytherService imageService] convertJsonImageToImage:media];
            [m setMainImage:image];
        }
        // Augmenting our collection of messages
        [calMessages addObject:m];
    }
    
    if([userKey isEqualToString:user.key]) {
        // Reversing array and eliminating duplicates
        NSMutableArray *filteredArray = [NSMutableArray arrayWithCapacity:calMessages.count];
        NSMutableDictionary *keysMessageMap = [[NSMutableDictionary alloc] init];
        for(Message *msg in [calMessages reverseObjectEnumerator]) {
            Message *thread = [keysMessageMap objectForKey:msg.from.key];
            if(thread == nil) {
                msg.messageCount = 1;
                [keysMessageMap setObject:msg forKey:msg.from.key];
                [filteredArray addObject:msg];
            } else {
                thread.messageCount++;
                thread.unreadCount+=msg.unreadCount;
            }
        }
        // Switching
        calMessages = filteredArray;
    }
    // Now invoking callback
    dispatch_async(dispatch_get_main_queue(), ^{
        [callback messagesFetched:calMessages totalCount:[totalMsgCount integerValue] page:[page integerValue] pageSize:[pageSize integerValue]];
        for(id<MessageCallback> callback in _messageCallbacks) {
            [callback messagesFetched:calMessages totalCount:[totalMsgCount integerValue] page:[page integerValue] pageSize:[pageSize integerValue]];
        }
    });
}

- (void)sendMessage:(NSString *)message toUser:(User *)user withImage:(CALImage*)image messageCallback:(id<MessageCallback>)callback {
    [self sendMessageOrComment:message forObject:user withImage:image isComment:NO messageCallback:callback];
}

- (void)postComment:(NSString *)comment forObject:(CALObject *)object withImage:(CALImage*)image messageCallback:(id<MessageCallback>)callback {
    [self sendMessageOrComment:comment forObject:object withImage:image isComment:YES messageCallback:callback];
}

-(void)sendMessageOrComment:(NSString*)message forObject:(CALObject*)object withImage:(CALImage*)image isComment:(BOOL)isComment messageCallback:(id<MessageCallback>)callback {
    CurrentUser *currentUser = [userService getCurrentUser];
    NSString *template;
    // Selecting URL template
    if(isComment) {
        template = kPostCommentUrlFormat;
    } else {
        template = kSendMessageUrlFormat;
    }
    NSString *url = [[NSString alloc] initWithFormat:template,togaytherServer];

    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:currentUser.token forKey:@"nxtpUserToken"];
    if(isComment) {
        [params setObject:message forKey:@"comment"];
        [params setObject:object.key forKey:@"commentItemKey"];
    } else {
        [params setObject:object.key forKey:@"to"];
        [params setObject:message forKey:@"msgText"];
    }
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [_uiService reportProgress:(float)0.05f];
    AFHTTPRequestOperation *operation = [manager POST:url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        if(image!=nil) {
            NSData *imageData = UIImageJPEGRepresentation(image.fullImage, 1.0);
            NSString *fileParam = @"media";
            [formData appendPartWithFileData:imageData
                                    name:fileParam
                                fileName:@"msgPhoto" mimeType:@"image/jpeg"];
        }
        [formData appendPartWithFormData:[currentUser.token dataUsingEncoding:NSUTF8StringEncoding]
                                    name:@"nxtpUserToken"];
        [formData appendPartWithFormData:[object.key dataUsingEncoding:NSUTF8StringEncoding]
                                    name:(isComment ? @"commentItemKey" : @"to")];
        [formData appendPartWithFormData:[message dataUsingEncoding:NSUTF8StringEncoding]
                                    name:(isComment ? @"comment" : @"msgText")];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *jsonMsg = (NSDictionary*)responseObject;
        NSString *msgKey = [jsonMsg objectForKey:@"key"];
        
        Message *msg = [[Message alloc] init];
        [msg setKey:msgKey];
        [msg setFrom:currentUser];
        [msg setTo:object];
        [msg setText:message];
        [msg setDate:[NSDate date]];
        [msg setMainImage:image];

        [callback messageSent:msg];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [callback messageSendFailed];
    }];
    
    [_uiService reportProgress:(float)0.1f];
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        double progressPct = (double)totalBytesWritten/(double)totalBytesExpectedToWrite;
        [_uiService reportProgress:0.1f+0.5f*(float)progressPct];
    }];
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        double progressPct = (double)totalBytesRead/(double)totalBytesExpectedToRead;
        [_uiService reportProgress:0.6f+0.4f*(float)progressPct];
    }];

}

-(void)handleToolbar:(UIViewController *)view {

    
    currentViewController = view;
    [self refresh];

}
//-(void) initNumberBadge {
//    // instantiating badge
//    if(_unreadMessageCount > 0) {
//        if(numberBadge == nil) {
//            numberBadge = [[MKNumberBadgeView alloc] initWithFrame:CGRectMake(25, 13, 30,24)];
//            numberBadge.font = [UIFont systemFontOfSize:10];
//            [badgeButton addSubview: numberBadge]; //Add NKNumberBadgeView as a subview on UIButton
//        }
//        numberBadge.value = _unreadMessageCount;
//    } else {
//        [numberBadge removeFromSuperview];
//        numberBadge = nil;
//    }
//    
//}
- (void)releaseToobar:(UIViewController *)view {
    
}
-(void)messageActionTouched:(id)sender {
    if(currentViewController != nil) {
        [currentViewController performSegueWithIdentifier:@"showMyMessages" sender:self];
    }
}
-(void)setUnreadMessageCount:(int)unreadMessageCount {
    _unreadMessageCount = unreadMessageCount;
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:unreadMessageCount];
    [self refresh];
}

-(void) refresh {
//    UITabBarItem *tabbarItem = [currentViewController.tabBarController.tabBar.items objectAtIndex:3];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        NSString *val = _unreadMessageCount > 0 ? [NSString stringWithFormat:@"%d",_unreadMessageCount] : nil;
//        [tabbarItem setBadgeValue:val];
//    });
    dispatch_async(dispatch_get_main_queue(), ^{
        _messageCountBadgeView.value = _unreadMessageCount;
        _messageCountBadgeView.hidden = (_unreadMessageCount == 0);
    });

}
-(void)setMessageCountBadgeView:(MKNumberBadgeView *)messageCountBadgeView {
    _messageCountBadgeView = messageCountBadgeView;
    [self refresh];
}
////    if(numberBadge != nil) {
//    [self initNumberBadge];
//    if(numberBadge != nil) {
//        [numberBadge setNeedsDisplay];
//    }
//    [badgeButton setNeedsDisplay];
////        UIView *button = [[[currentViewController toolbarItems] objectAtIndex:1] customView];
////        if(button != nil) {
////            [button layoutSubviews];
////        }
////    }
//}

#pragma mark - Push notification management
- (void)setPushEnabled:(BOOL)pushEnabled {
    [_userDefaults setObject:[NSNumber numberWithBool:pushEnabled] forKey:PML_PROP_PUSH_ENABLED];
    [_userDefaults synchronize];
    NSString *hexToken = nil;
    if(pushEnabled) {
        hexToken = [_userDefaults objectForKey:PML_PROP_DEVICE_TOKEN];
    }
    [[TogaytherService userService] registerDeviceToken:hexToken];

}
- (BOOL)pushEnabled {
    NSNumber *enabled = [_userDefaults objectForKey:PML_PROP_PUSH_ENABLED];
    NSString *deviceToken = [_userDefaults objectForKey:PML_PROP_DEVICE_TOKEN];
    return enabled != nil && [enabled boolValue] && deviceToken != nil;
}
- (void)handlePushNotificationProposition:(PushPropositionCallback)completion {
    // Storing our current completion
    _pushCompletion = completion;
    if([_userDefaults objectForKey:PML_PROP_DEVICE_TOKEN] == nil) {
        
        // We ask ourselve for push permission so that user won't cancel our only chance
        // to ask the system for push permission. We will only ask the system if the user
        // says YES.
        NSString *title = NSLocalizedString(@"push.permission.title",@"");
        NSString *message = NSLocalizedString(@"push.permission.msg",@"");
        NSString *okLabel =NSLocalizedString(@"push.yes",@"");
        NSString *cancelLabel =NSLocalizedString(@"push.no",@"");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelLabel otherButtonTitles:okLabel,nil];
        

        [alert show];
    } else {
        [self pushCompletion:YES];
    }

}
-(void)pushCompletion:(BOOL)pushActivated {
    if(_pushCompletion != nil) {
        [self setPushEnabled:pushActivated];
        _pushCompletion(pushActivated);
    }
    _pushCompletion = nil;
}
- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {

    NSString *hexToken = [deviceToken hexadecimalString];
    NSLog(@"didRegisterForRemoteNotificationsWithDeviceToken: %@",hexToken);
    [_userDefaults setObject:hexToken forKey:PML_PROP_DEVICE_TOKEN];
    [_userDefaults synchronize];
    [self pushCompletion:YES];
}
- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"didFailToRegisterForRemoteNotificationsWithError: code=%ld domain=%@",(long)error.code,error.domain);
    
    [self pushCompletion:NO];
}

#pragma mark - UIAlertViewDelegate (for push)
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    UIApplication *application = [UIApplication sharedApplication];
    switch (buttonIndex) {
        case 1:
            // Let the device know we want to receive push notifications, the system will ask the user
            
            // iOS 8 push notifications
            if([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
                [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:( UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
                
                [application registerForRemoteNotifications];
            } else {
                // iOS 7 and older notifications
                [application registerForRemoteNotificationTypes:
                    (UIRemoteNotificationTypeBadge  | UIRemoteNotificationTypeAlert)];
            }
            break;
        default:
            [self pushCompletion:NO];
            break;
    }
}
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(alertView.cancelButtonIndex == buttonIndex) {
        [self pushCompletion:NO];
    }
}
-(void)alertViewCancel:(UIAlertView *)alertView {
    [self pushCompletion:NO];
}

#pragma mark - Listeners management
- (void)registerCallback:(id<MessageCallback>)callback {
    [_messageCallbacks addObject:callback];
}
- (void)unregisterCallback:(id<MessageCallback>)callback {
    [_messageCallbacks removeObject:callback];
}
@end
