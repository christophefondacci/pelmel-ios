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
#import "PMLManagedUser.h"
#import "PMLManagedRecipientsGroup.h"
#import "PMLRecipientsGroup.h"

#define kPMLNotificationActivityChanged @"PMLActivityChanged"

typedef void(^PushPropositionCallback)(BOOL pushActive);

@protocol MessageCallback
@optional
// Method called to inform that a list of messages have been fetched from the server
-(void)messagesFetchedWithTotalCount:(NSInteger)totalCount page:(NSInteger)page pageSize:(NSInteger)pageSize;
-(void)loadMessageFailed;
-(void)messageSent:(Message*)message;
-(void)messageSendFailed;
@end
@protocol ActivitiesStatsCallback
-(void)activityStatsFetched:(NSArray*)activityStats;
-(void)activityStatsFetchFailed:(NSString*)errorMessage;
@end
@protocol ActivitiesCallback
-(void)activityFetched:(NSArray*)activities;
-(void)activityFetchFailed:(NSString*)errorMessage;
@end
@interface MessageService : NSObject <NSURLConnectionDelegate,NSURLConnectionDataDelegate, UIAlertViewDelegate>

@property (strong,nonatomic) UserService *userService;
@property (strong,nonatomic) JsonService *jsonService;
@property (strong,nonatomic) UIService *uiService;
@property (strong,nonatomic) MKNumberBadgeView *messageCountBadgeView;
@property (strong,nonatomic) MKNumberBadgeView *activityCountBadgeView;
@property (strong,nonatomic) MKNumberBadgeView *networkCountBadgeView;
@property (nonatomic) long maxActivityId;
@property (nonatomic) BOOL pushEnabled;
@property (nonatomic) NSInteger unreadMessageCount;
@property (nonatomic) NSInteger unreadNetworkCount;
@property (strong,nonatomic) NSCache *messageCache;

// Gets the list of messages exchanged with this user
-(void)getMessagesWithUser:(NSString*)userKey messageCallback:(id<MessageCallback>)callback;
-(void)getMessagesWithUser:(NSString*)userKey messageCallback:(id<MessageCallback>)callback page:(NSInteger)page;


// Gets the list of reviews as messages
-(void)getReviewsAsMessagesFor:(NSString*)itemKey messageCallback:(id<MessageCallback>)callback;
-(void)getReviewsAsMessagesFor:(NSString *)itemKey messageCallback:(id<MessageCallback>)callback page:(NSInteger)page;

// Sends an instant message to the given user or recipient (PMLRecipientsGroup)
-(void)sendMessage:(NSString*)message toRecipient:(CALObject*)user withImage:(CALImage*)image messageCallback:(id<MessageCallback>)callback;

// Stores the message
-(void)storeMessage:(Message*)m;

// Posts a comment on the given item 
- (void)postComment:(NSString *)comment forObject:(CALObject *)object withImage:(CALImage*)image messageCallback:(id<MessageCallback>)callback;

// Handles the toolbar of a view containing message icon
-(void)handleToolbar:(UIViewController*)view;
-(void)releaseToobar:(UIViewController*)view;

-(void)registerCallback:(id<MessageCallback>)callback;
-(void)unregisterCallback:(id<MessageCallback>)callback;

// Downloads the delta of new activity around the current location, sending the kPMLNotificationActivityChanged notification when
// ready
-(void)getNearbyActivitiesStats:(id<ActivitiesStatsCallback>)callback;
-(void)getNearbyActivitiesFor:(NSString*)statActivityType callback:(id<ActivitiesCallback>)callback;
-(void)getNearbyActivitiesFor:(NSString *)statActivityType hd:(BOOL)isHd callback:(id<ActivitiesCallback>)callback;

// Registers a max activity ID and updates any badge if needed
-(void)registerMaxActivityId:(NSNumber*)maxActivityId;
-(void)clearNewActivities;
-(NSNumber*)activityMaxId;

// Asks the user to enable push if needed
-(void)handlePushNotificationProposition:(PushPropositionCallback)completion;
// Delegate for the AppDelegate method (handling proper callback / completion)
-(void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
-(void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
-(User*)userFromManagedUser:(PMLManagedUser*)user;

/**
 * Provides the recipients group associated with the given key
 */
-(PMLManagedRecipientsGroup*)managedRecipientsGroupForKey:(NSString*)recipientsGroupKey;
/**
 * Provides the recipients group as a model object from its key.
 * @param recipientsGroupKey the item key of the group to retrieve
 * @return a PMLRecipientsGroup instance with the declaration of this group
 */
-(PMLRecipientsGroup *)recipientsGroupForKey:(NSString *)recipientsGroupKey;
/**
 * Stores the last created recipients group
 * @param group the recipients group newly created
 */
-(void)setLastRecipientsGroup:(PMLRecipientsGroup*)group;
/**
 * Retrieves the last created recipients group, if any
 * @return the last PMLRecipientsGroup used, or nil if none
 */
-(PMLRecipientsGroup*)lastRecipientsGroup;
@end
