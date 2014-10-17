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

#define kMessagesListUrlFormat @"%@/mobileMyMessagesReply?lat=%f&lng=%f&nxtpUserToken=%@&highRes=%@&from=%@"
#define kMyMessagesListUrlFormat @"%@/mobileMyMessages?lat=%f&lng=%f&nxtpUserToken=%@&highRes=%@"
#define kReviewsListUrlFormat @"%@/mobileComments?lat=%f&lng=%f&nxtpUserToken=%@&highRes=%@&id=%@"
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
    }
    return self;
}

-(void)getReviewsAsMessagesFor:(NSString *)itemKey messageCallback:(id<MessageCallback>)callback {
    // Getting current user and some device settings
    CurrentUser *user = userService.getCurrentUser;
    BOOL retina = [TogaytherService isRetina];
    
    // Building URL
    NSString *url;
    url = [[NSString alloc] initWithFormat:kReviewsListUrlFormat,togaytherServer, user.lat, user.lng, user.token, retina ? @"true" : @"false", itemKey];
    NSLog(@"Fetching reviews for '%@' : %@",itemKey,url);
    dispatch_async(kTopQueue, ^{
        // Calling URL
        NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        
        // Extracting JSON
        NSLog(@"JSON reviews data fetched");
        
        // Parse JSON
        NSError* error;
        if(data == nil) {
            NSLog(@"JSON data null for getReviewsAsMessagesFor");
            return;
        }
        // Unwrapping JSON
        NSDictionary *jsonMessageList = [NSJSONSerialization
                                         JSONObjectWithData:data //1
                                         options:kNilOptions
                                         error:&error];
        
        // Processing JSON message response
        [self processJsonMessage:jsonMessageList messageCallback:callback forUserKey:nil];
    });
}
- (void)getMessagesWithUser:(NSString *)userKey messageCallback:(id<MessageCallback>)callback {
    // Getting current user and some device settings
    CurrentUser *user = userService.getCurrentUser;
    BOOL retina = [TogaytherService isRetina];
    
    // Building URL
    NSString *url;
    if([userKey isEqualToString:user.key]) {
        url = [[NSString alloc] initWithFormat:kMyMessagesListUrlFormat,togaytherServer, user.lat, user.lng, user.token, retina ? @"true" : @"false"];
    } else {
        url = [[NSString alloc] initWithFormat:kMessagesListUrlFormat,togaytherServer, user.lat, user.lng, user.token, retina ? @"true" : @"false", userKey];
    }
    NSLog(@"URL: %@",url);
    dispatch_async(kTopQueue, ^{
        // Calling URL
        NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        // Extracting JSON
        NSLog(@"JSON messages data fetched");
        // Parse JSON
        NSError* error;
        if(data == nil) {
            NSLog(@"JSON data null for getMessagesWithUser");
            return;
        }
        NSDictionary *jsonMessageList = [NSJSONSerialization
                               JSONObjectWithData:data //1
                               options:kNilOptions
                               error:&error];
        
        // Processing JSON message response
        [self processJsonMessage:jsonMessageList messageCallback:callback forUserKey:userKey];
    });
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
    
    // Getting message list
    NSArray *messages = [jsonMessageList objectForKey:@"messages"];
    NSMutableArray *calMessages = [[NSMutableArray alloc] initWithCapacity:messages.count];
    for(NSDictionary *message in messages) {
        NSString *fromKey   = [message objectForKey:@"fromKey"];
        NSString *toKey     = [message objectForKey:@"toKey"];
        NSString *text      = [message objectForKey:@"message"];
        NSNumber *msgTime   = [message objectForKey:@"time"];
        long time = [msgTime longValue];
        NSDate *msgDate = [[NSDate alloc] initWithTimeIntervalSince1970:time];
        
        Message *m = [[Message alloc] init];
        
        User *fromUser = [usersMap objectForKey:fromKey];
        [m setFrom:fromUser];
        User *toUser = [usersMap objectForKey:toKey];
        [m setTo:toUser];
        [m setText:text];
        [m setDate:msgDate];
        
        // Augmenting our collection of messages
        [calMessages addObject:m];
    }
    
    if([userKey isEqualToString:user.key]) {
        // Reversing array and eliminating duplicates
        NSMutableArray *filteredArray = [NSMutableArray arrayWithCapacity:calMessages.count];
        NSMutableSet *keysSet = [[NSMutableSet alloc] init];
        for(Message *msg in [calMessages reverseObjectEnumerator]) {
            if(![keysSet containsObject:msg.from.key]) {
                [keysSet addObject:msg.from.key];
                [filteredArray addObject:msg];
            }
        }
        // Switching
        calMessages = filteredArray;
    }
    // Now invoking callback
    dispatch_async(dispatch_get_main_queue(), ^{
        [callback messagesFetched:calMessages];
    });
}

- (void)sendMessage:(NSString *)message toUser:(User *)user messageCallback:(id<MessageCallback>)callback {
    [self sendMessageOrComment:message forObject:user isComment:NO messageCallback:callback];
}

- (void)postComment:(NSString *)comment forObject:(CALObject *)object messageCallback:(id<MessageCallback>)callback {
    [self sendMessageOrComment:comment forObject:object isComment:YES messageCallback:callback];
}

-(void)sendMessageOrComment:(NSString*)message forObject:(CALObject*)object isComment:(BOOL)isComment messageCallback:(id<MessageCallback>)callback {
    CurrentUser *currentUser = [userService getCurrentUser];
    NSString *template;
    // Selecting URL template
    if(isComment) {
        template = kPostCommentUrlFormat;
    } else {
        template = kSendMessageUrlFormat;
    }
    NSString *url = [[NSString alloc] initWithFormat:template,togaytherServer];

    // Building request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPShouldHandleCookies:NO];
    [request setTimeoutInterval:30];
    [request setHTTPMethod:@"POST"];
    
    // Preparing post data
    NSString *boundary= @"----WebKitFormBoundaryr6P6NJ5NfEfBhSCe";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    
    // Initializing HTTP header
    [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:currentUser.token forKey:@"nxtpUserToken"];
    if(isComment) {
        [params setObject:message forKey:@"comment"];
        [params setObject:object.key forKey:@"commentItemKey"];
    } else {
        [params setObject:object.key forKey:@"to"];
        [params setObject:message forKey:@"msgText"];
    }
    
    // Adding parameters
    for (NSString *param in params) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", param] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%@\r\n", [params objectForKey:param]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    // Closing our body
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setHTTPBody:body];
    NSString *postLength = [NSString stringWithFormat:@"%ld", (long)[body length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    // Sending request
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    NSString *cacheKey =[self buildKeyFromPointer:conn];
    [uploadConnectionCallbacksMap setValue:callback forKey:cacheKey];
    Message *msg = [[Message alloc] init];
    [msg setFrom:currentUser];
    [msg setTo:object];
    [msg setText:message];
    [msg setDate:[NSDate date]];
    [uploadMessagesMap setValue:msg forKey:cacheKey];
    NSLog(@"Sending message...");
    [conn start];
}
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
    NSLog(@"WillSendRequest");
    return request;
}


- (NSInputStream *)connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)request {
    NSLog(@"needNewBodyStream");
    return nil;
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    NSLog(@"willCacheResponse");
    return cachedResponse;
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    NSLog(@"Can authenticate against");
    return NO;
}
- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSLog(@"Did cancel auth challenge");
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Fail with error");
    NSString *cacheKey = [self buildKeyFromPointer:connection];
    id<MessageCallback> callback = [uploadConnectionCallbacksMap objectForKey:cacheKey];
    dispatch_async(dispatch_get_main_queue(), ^{
        [callback messageSendFailed];
    });
    [uploadConnectionCallbacksMap removeObjectForKey:cacheKey];
    [uploadMessagesMap removeObjectForKey:cacheKey];
}
-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSLog(@"Authentication challenge");
}
-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSLog(@"Will send for auth challenge");
}
- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection {
    NSLog(@"Should use credential storage");
    return NO;
}
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"Did receive response");
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)receivedData {
    NSLog(@"Did receive data");
}
-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"Did finish loading");
    NSString *cacheKey = [self buildKeyFromPointer:connection];
    id<MessageCallback> callback = [uploadConnectionCallbacksMap objectForKey:cacheKey];
    Message *msg = [uploadMessagesMap objectForKey:cacheKey];
    dispatch_async(dispatch_get_main_queue(), ^{
        [callback messageSent:msg];
    });
    [uploadConnectionCallbacksMap removeObjectForKey:cacheKey];
    [uploadMessagesMap removeObjectForKey:cacheKey];

}
- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    NSLog(@"Did send body data");
}
-(NSString*)buildKeyFromPointer:(id)pointer {
    return [[NSString alloc] initWithFormat:@"%p",pointer];
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
    [_userDefaults setObject:hexToken forKey:PML_PROP_DEVICE_TOKEN];
    [_userDefaults synchronize];
    [self pushCompletion:YES];
}
- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [self pushCompletion:NO];
}

#pragma mark - UIAlertViewDelegate (for push)
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 1:
            // Let the device know we want to receive push notifications, the system will ask the user
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
             (UIRemoteNotificationTypeBadge  | UIRemoteNotificationTypeAlert)];
            break;
        default:
            [self pushCompletion:NO];
            break;
    }
}
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self pushCompletion:NO];
}
-(void)alertViewCancel:(UIAlertView *)alertView {
    [self pushCompletion:NO];
}
@end
