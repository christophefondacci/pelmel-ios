//
//  MessageService.h
//  togayther
//
//  Created by Christophe Fondacci on 27/12/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "Message.h"
#import "UserService.h"
#import "MKNumberBadgeView.h"

typedef void(^PushPropositionCallback)(BOOL pushActive);

@protocol MessageCallback
// Method called to inform that a list of messages have been fetched from the server
-(void)messagesFetched:(NSArray*)messagesList;
-(void)messageSent:(Message*)message;
-(void)messageSendFailed;
@end

@interface MessageService : NSObject <NSURLConnectionDelegate,NSURLConnectionDataDelegate, UIAlertViewDelegate>

@property (strong,nonatomic) UserService *userService;
@property (strong,nonatomic) JsonService *jsonService;
@property (strong,nonatomic) MKNumberBadgeView *messageCountBadgeView;
@property (nonatomic) BOOL pushEnabled;
@property (nonatomic) int unreadMessageCount;

// Gets the list of messages exchanged with this user
-(void)getMessagesWithUser:(NSString*)userKey messageCallback:(id<MessageCallback>)callback;

// Gets the list of reviews as messages
-(void)getReviewsAsMessagesFor:(NSString*)itemKey messageCallback:(id<MessageCallback>)callback;

// Sends an instant message to the given user
-(void)sendMessage:(NSString*)message toUser:(User*)user messageCallback:(id<MessageCallback>)callback;

// Posts a comment on the given item 
- (void)postComment:(NSString *)comment forObject:(CALObject *)object messageCallback:(id<MessageCallback>)callback;

// Handles the toolbar of a view containing message icon
-(void)handleToolbar:(UIViewController*)view;
-(void)releaseToobar:(UIViewController*)view;

-(void)registerCallback:(id<MessageCallback>)callback;
-(void)unregisterCallback:(id<MessageCallback>)callback;

// Asks the user to enable push if needed
-(void)handlePushNotificationProposition:(PushPropositionCallback)completion;
// Delegate for the AppDelegate method (handling proper callback / completion)
-(void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
-(void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
@end
