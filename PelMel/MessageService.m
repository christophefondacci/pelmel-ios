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
#import "PMLActivityStatistic.h"
#import <AFNetworking/AFNetworking.h>
#import "PMLMessageCacheEntry.h"
#import <CoreData/CoreData.h>
#import "PMLManagedMessage.h"
#import "PMLManagedUser.h"
#import "PMLManagedRecipientsGroup.h"
#import "PMLManagedRecipientsGroupUser.h"
#import "PMLRecipientsGroup.h"
#import "PMLMessagingContainerController.h"

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
//#define kMessagesListUrlFormat @"%@/mobileMyMessagesReply?lat=%f&lng=%f&nxtpUserToken=%@&highRes=%@&from=%@"
//#define kMyMessagesListUrlFormat @"%@/mobileMyMessages?lat=%f&lng=%f&nxtpUserToken=%@&highRes=%@"
//#define kReviewsListUrlFormat @"%@/mobileComments?lat=%f&lng=%f&nxtpUserToken=%@&highRes=%@&id=%@"
#define kMessagesListUrlFormat @"%@/mobileMyMessagesReply"
#define kMyMessagesListUrlFormat @"%@/mobileMyMessages"
#define kReviewsListUrlFormat @"%@/mobileComments"
#define kActivitiesStatsUrlFormat @"%@/api/activityStats"
#define kActivitiesUrlFormat @"%@/api/activityDetails"
#define kActivitiesGroupedUrlFormat @"%@/api/groupedActivityDetails"
#define kMessageAudienceUrlFormat @"%@/admin/messageAudience"
#define kParamLat @"lat"
#define kParamLng @"lng"
#define kParamToken @"nxtpUserToken"
#define kParamRetina @"highRes"
#define kParamId @"id"
#define kParamFrom @"from"
#define kParamPage @"page"
#define kParamPageSize @"messagesPerPage"
#define kParamUnreadMaxId @"unreadMaxId"
#define kParamMarkUnreadOnly @"markUnreadOnly"
#define kParamFromMessageId @"fromMessageId"
#define kParamStatActivityType @"statActivityType"
#define kParamLastActivityTime @"lastActivityTime"

#define kSendMessageUrlFormat @"%@/mobileSendMsg"
#define kPostCommentUrlFormat @"%@/mobilePostComment"
#define kTopQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)

#define kSettingMaxActivityId @"activity.maxId"
#define kSettingMaxMessageId @"message.maxId26"
#define kSettingLastRecipientsGroup @"message.lastRecipientsGroup"
#define kCacheKeyMessages @"allMessages"

@interface MessageService()
@property (nonatomic,retain) PMLStorageService *storageService;
@property (nonatomic) BOOL messageFetchInProgress;
@end

@implementation MessageService {

    NSString *togaytherServer;
    NSMutableDictionary *uploadConnectionCallbacksMap;
    NSMutableDictionary *uploadMessagesMap;
    UIViewController *currentViewController;
    MKNumberBadgeView *numberBadge;
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
        _messageCache = [[NSCache alloc] init];
        _storageService = [TogaytherService storageService];
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
    [params setObject:[NSString stringWithFormat:@"%ld",(long)page] forKey:kParamPage];
    
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
- (NSString*)cacheKeyFor:(NSString*)userKey page:(NSInteger)page {
    return [NSString stringWithFormat:@"%@.%d",userKey,(int)page];
}
- (void)getMessagesWithUser:(NSString *)userKey messageCallback:(id<MessageCallback>)callback page:(NSInteger)page{
    // Getting current user and some device settings
    CurrentUser *user = userService.getCurrentUser;
    if(user == nil) {
        return;
    }
    if(self.messageFetchInProgress && [userKey isEqualToString:user.key]) {
        return;
    } else {
        self.messageFetchInProgress = YES;
    }

    
    // Preparing params
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    // Building URL
    NSString *url = [[NSString alloc] initWithFormat:kMyMessagesListUrlFormat,togaytherServer ];
    
    // Filling params
    BOOL retina = [TogaytherService isRetina];
    [params setObject:[NSString stringWithFormat:@"%f",user.lat] forKey:kParamLat];
    [params setObject:[NSString stringWithFormat:@"%f",user.lng] forKey:kParamLng];
    [params setObject:user.token forKey:kParamToken];
    [params setObject:[NSNumber numberWithInt:300] forKey:kParamPageSize];
    [params setObject:(retina ? @"true" : @"false") forKey:kParamRetina];
    [params setObject:[NSString stringWithFormat:@"%ld",(long)page] forKey:kParamPage];
    [params setObject:[self maxMessageId] forKey:kParamFromMessageId];
    
    NSLog(@"URL: %@, maxId=%ld",url,[[self maxMessageId] longValue]);
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Processing JSON message response
        [self processJsonMessage:(NSDictionary*)responseObject messageCallback:callback forUserKey:userKey];
        if(userKey != nil ) {
            [self markReadConversationWithUser:userKey];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.messageFetchInProgress = NO;
        [callback loadMessageFailed];
    }];
}
- (void)markReadConversationWithUser:(NSString*)userKey {
    CurrentUser *user = userService.getCurrentUser;
    
    // Preparing params
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[NSString stringWithFormat:@"%f",user.lat] forKey:kParamLat];
    [params setObject:[NSString stringWithFormat:@"%f",user.lng] forKey:kParamLng];
    [params setObject:user.token forKey:kParamToken];
    [params setObject:userKey forKey:kParamFrom];
    [params setObject:[self maxMessageId] forKey:kParamUnreadMaxId];
    [params setObject:@"true" forKey:kParamMarkUnreadOnly];
    NSString *url = [[NSString alloc] initWithFormat:kMessagesListUrlFormat,togaytherServer ];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *json = (NSDictionary*)responseObject;
        NSNumber *unreadMsg = [json objectForKey:@"unreadMsgCount"];
        [self setUnreadMessageCount:unreadMsg.intValue];
        NSLog(@"Marked as read!");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to mark as read, will be next time");
    }];
    
}
- (NSString *)maxMessageKey {
    CurrentUser *user = [userService getCurrentUser];
    NSString *key = [NSString stringWithFormat:@"%@.%@",kSettingMaxMessageId,user.key];
    return key;
}
- (NSNumber *)maxMessageId {
    NSNumber *maxMessageId = [_userDefaults objectForKey:[self maxMessageKey]];
    if(maxMessageId == nil) {
        maxMessageId = @0;
    }
    return maxMessageId;
}

/**
 * Converts an array of JSON users into an array of managed users stored in database
 */
-(NSArray*)managedUsersFromJson:(NSArray*)jsonUsers usingMap:(NSMutableDictionary*)managedUsersMap {
    
    NSMutableDictionary *usersMap = [[NSMutableDictionary alloc] init];
    NSMutableArray *users = [[NSMutableArray alloc] init];
    // Iterating over all JSON structures
    for(NSDictionary *jsonUser in jsonUsers) {
        
        // Have we already got this managed object?
        NSString *key = [jsonUser objectForKey:@"key"];
        PMLManagedUser *user = [managedUsersMap objectForKey:key];
        
        if(user == nil) {
            if([key hasPrefix:@"PLAC"]) {
                User *placeUser = [[User alloc] init];
                placeUser.key = key;
                placeUser.pseudo = [jsonUser objectForKey:@"pseudo"];
                NSDictionary *jsonThumb = [jsonUser objectForKey:@"thumb"];
                CALImage *thumb = [[TogaytherService imageService] convertJsonImageToImage:jsonThumb];
                placeUser.mainImage = thumb;
                [usersMap setObject:placeUser forKey:key];
            } else {
                // If not then we deserialize
                User *aUser = [_jsonService convertJsonUserToUser:jsonUser];
                [usersMap setObject:aUser forKey:aUser.key];
            }
        } else {
            [users addObject:user];
        }
    }
    
    // Now we query the database
    CurrentUser *currentUser = [[TogaytherService userService] getCurrentUser];
    NSManagedObjectContext *context = [[TogaytherService storageService] managedObjectContext];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"PMLManagedUser"
                         inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"currentUserKey=%@ and itemKey IN %@",currentUser.key,usersMap.allKeys];
    [fetchRequest setPredicate:predicate];
    
    // Fetching objects and storing users in a map
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (PMLManagedUser *managedUser in fetchedObjects) {
        [managedUsersMap setObject:managedUser forKey:managedUser.itemKey];
        
        User *user = [usersMap objectForKey:managedUser.itemKey];
        if(user != nil) {
            [self fillManagedUser:managedUser fromUser:user];
        }
        [users addObject:managedUser];
        [usersMap removeObjectForKey:managedUser.itemKey];
    }
    
    // Remaining users, we create managed object
    for(NSString *userKey in usersMap.allKeys) {
        
        User *user = [usersMap objectForKey:userKey];
        PMLManagedUser *managedUser = [NSEntityDescription insertNewObjectForEntityForName:@"PMLManagedUser" inManagedObjectContext:context];
        [self fillManagedUser:managedUser fromUser:user];

        [managedUsersMap setObject:managedUser forKey:userKey];
        [users addObject:managedUser];
    }
    return users;
}
-(void)fillManagedUser:(PMLManagedUser*)managedUser fromUser:(User*)user {
    CurrentUser *currentUser = [userService getCurrentUser];
    managedUser.currentUserKey = currentUser.key;
    managedUser.itemKey = user.key;
    managedUser.name = user.pseudo;
    managedUser.imageKey = user.mainImage.key;
    managedUser.imageUrl = user.mainImage.imageUrl;
    managedUser.thumbUrl = user.mainImage.thumbUrl;
}
-(NSMutableDictionary *)managedRecipientsGroupsFromJson:(NSArray*)jsonRecipientsGroups usingMap:(NSMutableDictionary*)usersMap {
    
    NSMutableDictionary *recipientsGroupMap = [[NSMutableDictionary alloc] init];
    
    // Hashing groups by key and converting users to managed users
    for(NSDictionary *jsonRecipientsGroup in jsonRecipientsGroups) {
        
        // Extracting JSON info
        NSString *key = [jsonRecipientsGroup objectForKey:@"key"];
        NSArray *jsonUsers = [jsonRecipientsGroup objectForKey:@"users"];
        
        // Converting user
        NSArray *managedUsers = [self managedUsersFromJson:jsonUsers usingMap:usersMap];
        
        // Filling map
        [recipientsGroupMap setObject:managedUsers forKey:key];
    }
    
    // Fetching already existing groups
    CurrentUser *currentUser = [[TogaytherService userService] getCurrentUser];
    NSManagedObjectContext *context = [[TogaytherService storageService] managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc ] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"PMLManagedRecipientsGroup" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"currentUserKey=%@ and itemKey IN %@",currentUser.key,recipientsGroupMap.allKeys];
    [fetchRequest setPredicate:predicate];
    
    // Executing query
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    // Hashing existing groups by key
    NSMutableDictionary *recipientsGroupKeysMap = [[NSMutableDictionary alloc] init];
    for(PMLManagedRecipientsGroup *group in fetchedObjects) {
        [recipientsGroupKeysMap setObject:group forKey:group.itemKey];
    }

    for(NSString *key in recipientsGroupMap.allKeys) {
        PMLManagedRecipientsGroup *group = [recipientsGroupKeysMap objectForKeyedSubscript:key];
        if(group == nil) {
            
            // Getting managed users
            NSArray *managedUsers = [recipientsGroupMap objectForKey:key];
            
            // Creating the group
            group = [NSEntityDescription insertNewObjectForEntityForName:@"PMLManagedRecipientsGroup" inManagedObjectContext:context];
            [recipientsGroupKeysMap setObject:group forKey:key];
            group.itemKey = key;
            group.currentUserKey = currentUser.key;
            
            // Associating users with this group
            for(PMLManagedUser *user in managedUsers) {
                // Creating new user / group intersection
                PMLManagedRecipientsGroupUser *groupUser = [NSEntityDescription insertNewObjectForEntityForName:@"PMLManagedRecipientsGroupUser" inManagedObjectContext:context];
                groupUser.user = user;
                groupUser.recipientsGroup = group;
            }
        }
    }
    return recipientsGroupKeysMap;
}
-(void)processJsonMessage:(NSDictionary*)jsonMessageList messageCallback:(id<MessageCallback>)callback forUserKey:(NSString*)userKey {

    // Building a map of users
    NSMutableDictionary *managedUsersMap = [[NSMutableDictionary alloc] init];
    NSArray *jsonUsers = [jsonMessageList objectForKey:@"users"];
    [self managedUsersFromJson:jsonUsers usingMap:managedUsersMap];
    
    // Getting current user
    CurrentUser *currentUser = [userService getCurrentUser];
//    [usersMap setValue:currentUser forKey:currentUser.key];
    
    // Hashing recipients group per group key
    NSArray *jsonRecipientsGroups = [jsonMessageList objectForKey:@"recipientsGroups"];
    NSMutableDictionary *recipientsGroupMap = [self managedRecipientsGroupsFromJson:jsonRecipientsGroups usingMap:managedUsersMap];
    
    
    // Getting unread message count
    NSNumber *unreadMsgCount = [jsonMessageList objectForKey:@"unreadMsgCount"];
    [self setUnreadMessageCount:[unreadMsgCount intValue]];
    NSNumber *totalMsgCount = [jsonMessageList objectForKey:@"totalMsgCount"];
    NSNumber *page          = [jsonMessageList objectForKey:@"page"];
    NSNumber *pageSize      = [jsonMessageList objectForKey:@"pageSize"];
    
    // Getting message list
    NSArray *messages = [jsonMessageList objectForKey:@"messages"];

    NSMutableDictionary *messagesKeyMap = [[NSMutableDictionary alloc] init];
    NSNumber *maxId;
    for(NSDictionary *message in messages) {
        NSString *key       = [message objectForKey:@"key"];

        // Registering collections and maps
        [messagesKeyMap setObject:message forKey:key];

        // Augmenting our collection of messages
        NSNumber *msgId = [self idFromKey:key];
        if(maxId == nil || maxId.longValue<msgId.longValue) {
            maxId = msgId;
        }
    }
    
    // Checking already existing messages
    NSManagedObjectContext *context = [[TogaytherService storageService] managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"PMLManagedMessage"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageKey IN %@",messagesKeyMap.allKeys];
    [fetchRequest setPredicate:predicate];
    // Fetching objects
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    NSMutableDictionary *existingMessagesKeys = [[NSMutableDictionary alloc] init];
    for (PMLManagedMessage *msg in fetchedObjects) {
        // Removing the objects which we already have in database
        [existingMessagesKeys setObject:msg forKey:msg.messageKey];
    }
    
    // Processing remaining messages
    for(NSString *key in messagesKeyMap.allKeys) {
        
        // Getting message
        NSDictionary *message = [messagesKeyMap objectForKey:key];
        NSString *fromKey   = [message objectForKey:@"fromKey"];
        NSString *toKey     = [message objectForKey:@"toKey"];
        NSString *text      = [message objectForKey:@"message"];
        NSNumber *msgTime   = [message objectForKey:@"time"];
        NSNumber *unread    = [message objectForKey:@"unread"];
        NSDictionary *media = [message objectForKey:@"media"];
        NSString *recipientsGroupKey=[message objectForKey:@"recipientsGroupKey"];
        
        long time = [msgTime longValue];
        NSDate *msgDate = [[NSDate alloc] initWithTimeIntervalSince1970:time];
        CALImage *msgImage = nil;
        if(media != nil) {
            msgImage = [[TogaytherService imageService] convertJsonImageToImage:media];
        }
        
        // For group messages, we only consider messages to self
        if(recipientsGroupKey != nil && recipientsGroupKey.length>0 && (id)recipientsGroupKey != [NSNull null] && ![toKey isEqualToString:currentUser.key]) {
            continue;
        }
        
        PMLManagedMessage *msg = [existingMessagesKeys objectForKey:key];
        BOOL newMsg = NO;
        if(msg == nil) {
            msg = [NSEntityDescription
                   insertNewObjectForEntityForName:@"PMLManagedMessage"
                   inManagedObjectContext:context];
            newMsg = YES;
        }
        
        msg.messageKey = key;
        msg.messageDate = msgDate;
        msg.toItemKey = toKey;
        msg.messageImageKey = msgImage.key;
        msg.messageImageThumbUrl = msgImage.thumbUrl;
        msg.messageImageUrl = msgImage.imageUrl;
        msg.messageText = text;
        msg.isUnread = unread;

        PMLManagedUser *fromUser = [managedUsersMap objectForKey:fromKey];
        if(fromUser == nil) {
            
        }
        msg.from = fromUser;
        PMLManagedRecipientsGroup *group = [recipientsGroupMap objectForKey:recipientsGroupKey];
        if(group != nil) {
            msg.replyTo = group;
        } else {
            msg.replyTo = fromUser;
        }
        

        if(newMsg && unread.boolValue) {
            if(group == nil) {
                fromUser.unreadCount = fromUser.unreadCount == nil ? @1 : [NSNumber numberWithInt:fromUser.unreadCount.intValue + 1];
            } else {
                group.unreadCount = group.unreadCount == nil ? @1 : [NSNumber numberWithInt:group.unreadCount.intValue+1];
            }
        }
        if( group != nil) {
            if(group.lastMessageDate ==nil || [msg.messageDate compare:group.lastMessageDate]==NSOrderedDescending) {
                group.lastMessageDate = msg.messageDate;
            }
        } else if(fromUser.lastMessageDate == nil || [msg.messageDate compare:fromUser.lastMessageDate] == NSOrderedDescending) {
            // Only if user key specified
            if(userKey != nil) {
                fromUser.lastMessageDate = msg.messageDate;
            }
        }
    }
    // Saving entries
    BOOL saveError = NO;
    if(messagesKeyMap.allKeys.count>0) {
        if (![context save:&error]) {
            saveError = YES;
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        } else {
            // Registering ID
            if([[self maxMessageId] longValue]<[maxId longValue]) {
                [_userDefaults setObject:maxId forKey:[self maxMessageKey]];
            }
        }
    }
    

    
    // Now invoking callback
    dispatch_async(dispatch_get_main_queue(), ^{
        [callback messagesFetchedWithTotalCount:[totalMsgCount integerValue] page:[page integerValue] pageSize:[pageSize integerValue]];
        for(id<MessageCallback> callback in _messageCallbacks) {
            [callback messagesFetchedWithTotalCount:[totalMsgCount integerValue] page:[page integerValue] pageSize:[pageSize integerValue]];
        }
    });
    
    if([totalMsgCount intValue]>0 && !saveError) {
        dispatch_async(kBgQueue, ^{
            self.messageFetchInProgress = NO;
            [self getMessagesWithUser:userKey messageCallback:callback];
        });
    } else {
        self.messageFetchInProgress = NO;
    }

}

-(void)storeMessage:(Message*)m {
    NSManagedObjectContext *context = [[TogaytherService storageService] managedObjectContext];
    
    // Fetching message user from store
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"PMLManagedUser"
                         inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemKey = %@",m.from.key];
    [fetchRequest setPredicate:predicate];
    
    // Fetching objects (should be 0 or 1)
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    PMLManagedUser *user;
    if(fetchedObjects.count == 1) {
        user = [fetchedObjects objectAtIndex:0];
    } else {
        user = [NSEntityDescription insertNewObjectForEntityForName:@"PMLManagedUser" inManagedObjectContext:context];
        NSLog(@"Storing user %@ in CoreData",m.key);
    }

    if(m.toItemKey==nil) {
        m.toItemKey = m.to.key;
    }
    // Storing message
    [self storeMessage:m fromUser:user context:context using:nil];
    if(![context save:&error]) {
        NSLog(@"Error saving message: %@",error.localizedDescription);
    }
    
}
-(void)storeMessage:(Message*)m fromUser:(PMLManagedUser*)user context:(NSManagedObjectContext*)context using:(PMLManagedMessage*)msg {
    BOOL newMsg = NO;
    if(msg == nil) {
        msg = [NSEntityDescription
                              insertNewObjectForEntityForName:@"PMLManagedMessage"
                              inManagedObjectContext:context];
        newMsg = YES;
    }
    msg.messageKey = m.key;
    msg.messageDate = m.date;
    msg.toItemKey = m.toItemKey;
    msg.messageImageKey = m.mainImage.key;
    msg.messageImageThumbUrl = m.mainImage.thumbUrl;
    msg.messageImageUrl = m.mainImage.imageUrl;
    msg.messageText = m.text;
    msg.isUnread = [NSNumber numberWithBool:m.unread];
    
    // Getting from user
    user.currentUserKey = [[[TogaytherService userService] getCurrentUser] key];
    user.itemKey = m.from.key;
    user.name=((User*)m.from).pseudo;
    CALImage *image = ((User*)m.from).mainImage;
    user.imageKey = image.key;
    user.imageUrl = image.imageUrl;
    user.thumbUrl = image.thumbUrl;
    msg.from = user;
    if(m.recipientsGroupKey != nil) {

        PMLManagedRecipientsGroup *group = [self managedRecipientsGroupForKey:m.recipientsGroupKey];
        if(group == nil) {
            group = [NSEntityDescription insertNewObjectForEntityForName:@"PMLManagedUser" inManagedObjectContext:context];
            group.itemKey = m.recipientsGroupKey;
            NSLog(@"Storing user %@ in CoreData",m.key);
        }
        if(m.unread && newMsg) {
            group.unreadCount = group.unreadCount == nil ? @1 : [NSNumber numberWithInt:group.unreadCount.intValue+1];
        }
        if(group.lastMessageDate ==nil || [msg.messageDate compare:group.lastMessageDate]==NSOrderedDescending) {
            group.lastMessageDate = msg.messageDate;
        }
        msg.replyTo = group;
    } else {
        msg.replyTo=user;
        if(m.unread && newMsg) {
            user.unreadCount = user.unreadCount == nil ? @1 : [NSNumber numberWithInt:user.unreadCount.intValue + 1];
        }
        if(user.lastMessageDate == nil || [msg.messageDate compare:user.lastMessageDate] == NSOrderedDescending) {
            user.lastMessageDate = msg.messageDate;
        }
    }
    NSLog(@"Storing message %@ in CoreData",m.key);
}
-(PMLManagedRecipientsGroup*)managedRecipientsGroupForKey:(NSString*)recipientsGroupKey {
    NSManagedObjectContext *context = [[TogaytherService storageService] managedObjectContext];
    // Fetching message user from store
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"PMLManagedRecipientsGroup"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemKey = %@ and currentUserKey = %@",recipientsGroupKey,[[userService getCurrentUser] key] ];
    [fetchRequest setPredicate:predicate];
    
    // Fetching objects (should be 0 or 1)
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if(fetchedObjects.count==1) {
        return [fetchedObjects objectAtIndex:0];
    } else {
        return nil;
    }
}
-(PMLRecipientsGroup *)recipientsGroupForKey:(NSString *)recipientsGroupKey {
    PMLManagedRecipientsGroup *managedGroup = [self managedRecipientsGroupForKey:recipientsGroupKey];
    NSMutableArray *users = [[NSMutableArray alloc] init];
    
    // Iterating over all database users
    NSMutableDictionary *userKeys = [[NSMutableDictionary alloc] init];
    for(PMLManagedRecipientsGroupUser *groupUser in managedGroup.groupUsers) {

        // Converting to model
        User *user = [self userFromManagedUser:groupUser.user];
        if([userKeys objectForKey:user.key]==nil) {
            [users addObject:user];
        }
        [userKeys setObject:user forKey:user.key];
    }
    PMLRecipientsGroup *group = [[PMLRecipientsGroup alloc] initWithUsers:users];
    group.key = recipientsGroupKey;
    return group;
}
-(NSNumber*)idFromKey:(NSString*)key {
    NSString *maxIdStr = [key substringFromIndex:4];
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    return [f numberFromString:maxIdStr];
}
- (void)sendMessage:(NSString *)message toRecipient:(CALObject *)recipient withImage:(CALImage*)image messageCallback:(id<MessageCallback>)callback {
    [self sendMessageOrComment:message forObject:recipient withImage:image isComment:NO messageCallback:callback];
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
        if([object isKindOfClass:[PMLRecipientsGroup class]]) {
            
            // Getting recipients group
            PMLRecipientsGroup *group = (PMLRecipientsGroup *)object;
            NSMutableString *keysList = [[NSMutableString alloc] init];
            
            // If we have a key we use it, the server will know the list
            if(group.key !=nil) {
                [keysList appendString:group.key];
            } else {
                // Otherwise we build the list of recipients user keys
                NSString *separator = @"";
                for(User *user in ((PMLRecipientsGroup*)object).users) {
                    [keysList appendString:separator];
                    [keysList appendString:user.key];
                    separator = @",";
                }
            }
            // Passing argument
            [formData appendPartWithFormData:[keysList dataUsingEncoding:NSUTF8StringEncoding]
                                        name:(isComment ? @"commentItemKey" : @"to")];
        } else {
            [formData appendPartWithFormData:[object.key dataUsingEncoding:NSUTF8StringEncoding]
                                    name:(isComment ? @"commentItemKey" : @"to")];
        }
        [formData appendPartWithFormData:[message dataUsingEncoding:NSUTF8StringEncoding]
                                    name:(isComment ? @"comment" : @"msgText")];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *jsonMsg = (NSDictionary*)responseObject;
        NSString *msgKey = [jsonMsg objectForKey:@"key"];
        NSString *recipientsGroupKey = [jsonMsg objectForKey:@"recipientsGroupKey"];
        
        Message *msg = [[Message alloc] init];
        [msg setKey:msgKey];
        [msg setFrom:currentUser];
        if([object isKindOfClass:[PMLRecipientsGroup class]]) {
            [msg setTo:[userService getCurrentUser]];
        } else {
            [msg setTo:object];
        }
        [msg setText:message];
        [msg setDate:[NSDate date]];
        [msg setMainImage:image];
        if((id)recipientsGroupKey != [NSNull null] && recipientsGroupKey.length>0) {
            [msg setRecipientsGroupKey:recipientsGroupKey];
        }
        
        // Storing message locally
        [self storeMessage:msg];
        
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

- (void)releaseToobar:(UIViewController *)view {
    
}
-(void)messageActionTouched:(id)sender {
    if(currentViewController != nil) {
        [currentViewController performSegueWithIdentifier:@"showMyMessages" sender:self];
    }
}
-(void)setUnreadMessageCount:(NSInteger)unreadMessageCount {
    _unreadMessageCount = MAX(unreadMessageCount,0);
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:_unreadMessageCount+_unreadNetworkCount];
    [self refresh];
}
-(void)setUnreadNetworkCount:(NSInteger)unreadNetworkCount {
    _unreadNetworkCount = MAX(unreadNetworkCount,0);
    [self refresh];
}
-(void)setMaxActivityId:(long)maxActivityId {
    _maxActivityId = maxActivityId;
    [self refresh];
}
-(void)clearNewActivities {
    [_userDefaults setObject:[NSNumber numberWithLong:_maxActivityId] forKey:kSettingMaxActivityId];
    [self refresh];
}
-(void) refresh {
    dispatch_async(dispatch_get_main_queue(), ^{
        _messageCountBadgeView.value = _unreadMessageCount;
        _messageCountBadgeView.hidden = (_unreadMessageCount <= 0);
        _networkCountBadgeView.value = _unreadNetworkCount;
        _networkCountBadgeView.hidden = (_unreadNetworkCount <=0);
        NSNumber *maxActivityId = [_userDefaults objectForKey:kSettingMaxActivityId];
        if(_maxActivityId > maxActivityId.longValue) {
            _activityCountBadgeView.label = @"NEW";
            _activityCountBadgeView.hidden=NO;
        } else {
            _activityCountBadgeView.hidden=YES;
        }
    });

}
-(void)setMessageCountBadgeView:(MKNumberBadgeView *)messageCountBadgeView {
    _messageCountBadgeView = messageCountBadgeView;
    [self refresh];
}
-(void)setActivityCountBadgeView:(MKNumberBadgeView *)activityCountBadgeView {
    _activityCountBadgeView = activityCountBadgeView;
    [self refresh];
}
-(void) setNetworkCountBadgeView:(MKNumberBadgeView *)networkCountBadgeView {
    if(_networkCountBadgeView==nil) {
        _networkCountBadgeView = networkCountBadgeView;
        [self refresh];
    }
}
-(void)startChat:(NSArray*)usersList {
    
    CurrentUser *currentUser = [[TogaytherService userService] getCurrentUser];
    
    // Making a copy to not alter input list
    NSMutableArray *chatUsers = [usersList mutableCopy];
    
    // Checking if current user is already part of the list
    BOOL hasCurrentUser = NO;
    CALObject *otherObject = nil;
    for(User *user in usersList) {
        if([user.key isEqualToString:currentUser.key]) {
            hasCurrentUser = YES;
            break;
        } else {
            otherObject = user;
        }
    }
    // If not part of the list, we add current user
    if(!hasCurrentUser) {
        [chatUsers addObject:currentUser];
    }
    
    // Is it a group chat or a conversation?
    if(chatUsers.count == 2) {
        PMLMessagingContainerController *msgController = (PMLMessagingContainerController*)[_uiService instantiateViewController:SB_ID_MESSAGES];
        msgController.withObject = otherObject;
        [_uiService presentSnippet:msgController opened:YES root:NO];
    } else {
        // Building new group for group message
        PMLRecipientsGroup *group = [self lastRecipientsGroup];
        
        // Checking if last used group has same user definition
        if(group != nil) {
            if(chatUsers.count == group.users.count) {
                
                // Hashing user keys
                NSMutableDictionary *userKeys = [[NSMutableDictionary alloc] init];
                for(User *user in chatUsers) {
                    [userKeys setObject:user forKey:user.key];
                }
                
                // Checking group definition
                for(User *user in group.users) {
                    User *otherUser = [userKeys objectForKey:user.key];
                    // If not existing, then we should not use this group
                    if(otherUser == nil && ![user.key isEqualToString:currentUser.key]) {
                        group = nil;
                    }
                }
            } else {
                group = nil;
            }
        }
        if(group == nil) {
            group = [[PMLRecipientsGroup alloc] initWithUsers:chatUsers];
        }
        
        PMLMessagingContainerController *msgController = (PMLMessagingContainerController*)[_uiService instantiateViewController:SB_ID_MESSAGES];
        msgController.withObject = group;
        [_uiService presentSnippet:msgController opened:YES root:NO];
    }

}
#pragma mark - Activity management
- (void)getNearbyActivitiesStats:(id<ActivitiesStatsCallback>)callback {

    // Building URL
    NSString *url = [[NSString alloc] initWithFormat:kActivitiesStatsUrlFormat,togaytherServer];
    
    // Building arguments
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    CurrentUser *user = [userService getCurrentUser];
    BOOL retina = [TogaytherService isRetina];
    
    [params setObject:user.token forKey:kParamToken];
    CLLocation *location = [[[TogaytherService dataService] modelHolder] userLocation];
    [params setObject:[NSString stringWithFormat:@"%.5f",location.coordinate.latitude] forKey:kParamLat];
    [params setObject:[NSString stringWithFormat:@"%.5f",location.coordinate.longitude] forKey:kParamLng];
    [params setObject:(retina ? @"true" : @"false") forKey:kParamRetina];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSLog(@"%@?nxtpUserToken=%@&lat=%.5f&lng=%.5f",url,user.token,user.lat,user.lng);
    
    [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSArray *jsonStats = (NSArray*)responseObject;
        NSMutableArray *stats = [[NSMutableArray alloc] init];
        
        // Iterating over JSON entries of the result array
        NSNumber *maxActivityId = [NSNumber numberWithInt:0];
        for(NSDictionary *jsonStat in jsonStats) {
            
            // Parsing JSON data
            NSString *activityType  = [jsonStat objectForKey:@"activityType"];
            NSNumber *totalCount    = [jsonStat objectForKey:@"totalCount"];
            NSNumber *partialCount  = [jsonStat objectForKey:@"partialCount"];
            NSNumber *lastId        = [jsonStat objectForKey:@"lastId"];
            NSString *partialNames  = [jsonStat objectForKey:@"partialNames"];
            NSDictionary *media     = [jsonStat objectForKey:@"media"];
            
            // Building model object
            PMLActivityStatistic *stat = [[PMLActivityStatistic alloc] init];
            [stat setActivityType:activityType];
            [stat setTotalCount:[totalCount integerValue]];
            [stat setPartialCount:[partialCount integerValue]];
            [stat setPartialNames:partialNames];
            [stat setMaxActivityId:lastId];
            
            if(media != nil && (NSObject*)media != [NSNull null]) {
                CALImage *image = [[TogaytherService imageService] convertJsonImageToImage:media];
                [stat setStatImage:image];
            }
            
            // Storing current activity ID
            [_userDefaults setObject:lastId forKey:activityType];
            if(maxActivityId.longValue  < lastId.longValue) {
                maxActivityId = lastId;
            }
            // Appending to global list
            [stats addObject:stat];
        }
        
        // Sorting
        NSArray *sortedStats = [stats sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(id obj1, id obj2) {
            PMLActivityStatistic *stat1 = (PMLActivityStatistic*)obj1;
            PMLActivityStatistic *stat2 = (PMLActivityStatistic*)obj2;
            NSInteger index1 = [PML_ACTIVITY_PRIORITY indexOfObject:stat1.activityType];
            NSInteger index2 = [PML_ACTIVITY_PRIORITY indexOfObject:stat2.activityType];
            if(index2 == NSNotFound) {
                return NSOrderedAscending;
            } else if(index1 == NSNotFound) {
                return NSOrderedDescending;
            } else {
                return index1-index2 < 0 ? NSOrderedAscending : NSOrderedDescending;
            }
        }];
        
        [[[TogaytherService dataService] modelHolder] setActivityStats:sortedStats];
        [callback activityStatsFetched:sortedStats];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [callback activityStatsFetchFailed:error.domain];
    }];


}
- (void)registerMaxActivityId:(NSNumber*)maxActivityId {
    // Setting current max activity ID and refreshing badges
    NSNumber *currentMaxId = [_userDefaults objectForKey:kSettingMaxActivityId];
    if(currentMaxId == nil || currentMaxId.longValue < maxActivityId.longValue) {
        [_userDefaults setObject:maxActivityId forKey:kSettingMaxActivityId];
        [self refresh];
    }
}
-(NSNumber*)activityMaxId {
    NSNumber *maxId = [_userDefaults objectForKey:kSettingMaxActivityId];
    return maxId == nil ? @0 : maxId;
}

- (void)getNearbyActivitiesFor:(NSString *)statActivityType callback:(id<ActivitiesCallback>)callback {
    [self getNearbyActivitiesFor:statActivityType hd:[TogaytherService isRetina] callback:callback];
}
- (void)getNearbyActivitiesFor:(NSString *)statActivityType hd:(BOOL)isHd callback:(id<ActivitiesCallback>)callback {

    // Building URL
    BOOL isLikeActivity = [statActivityType hasPrefix:@"I_"] && ![statActivityType isEqualToString:@"I_EVNT"];
    NSString *url = [[NSString alloc] initWithFormat:(isLikeActivity ? kActivitiesGroupedUrlFormat : kActivitiesUrlFormat),togaytherServer];
    
    // Building arguments
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    CurrentUser *user = [userService getCurrentUser];
    
    CLLocation *location = [[[TogaytherService dataService] modelHolder] userLocation];
    [params setObject:user.token forKey:kParamToken];
    [params setObject:[NSString stringWithFormat:@"%.5f",location.coordinate.latitude] forKey:kParamLat];
    [params setObject:[NSString stringWithFormat:@"%.5f",location.coordinate.longitude] forKey:kParamLng];
    [params setObject:(isHd ? @"true" : @"false") forKey:kParamRetina];
    [params setObject:statActivityType forKey:kParamStatActivityType];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *json = (NSArray*)responseObject;
        NSArray *activities = [[TogaytherService getJsonService] convertJsonActivitiesToActivities:json];
        [callback activityFetched:activities];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [callback activityFetchFailed:error.domain];
    }];
}

-(User*)userFromManagedUser:(PMLManagedUser*)user {
    User *fromUser = [[TogaytherService dataService].jsonService.objectCache objectForKey:user.itemKey];
    if(fromUser == nil) {
        fromUser = [[User alloc] init];
        fromUser.key = user.itemKey;
        fromUser.pseudo = user.name;
        if(user.imageUrl !=nil) {
            fromUser.mainImage = [[CALImage alloc] initWithKey:user.imageKey url:user.imageUrl thumbUrl:user.thumbUrl];
        }
        [[TogaytherService dataService].jsonService.objectCache setObject:fromUser forKey:user.itemKey];
    }
    return fromUser;
}
-(void)setLastRecipientsGroup:(PMLRecipientsGroup*)group {
    [_userDefaults setObject:group.key forKey:kSettingLastRecipientsGroup];
}
-(PMLRecipientsGroup*)lastRecipientsGroup {
    NSString *groupKey = [_userDefaults objectForKey:kSettingLastRecipientsGroup];
    if(groupKey != nil) {
        PMLRecipientsGroup *group = [self recipientsGroupForKey:groupKey];
        return group;
    }
    return nil;
}
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

#pragma mark - Announcement
- (void)countAudienceOf:(Place *)place onSuccess:(MessageAudienceCallback)successCallback onFailure:(MessageAudienceFailureCallback)errorCallback {
    [self messageOrCountAudienceOf:place message:nil countOnly:YES onSuccess:successCallback onFailure:errorCallback];
}
- (void)messageAudienceOf:(Place *)place message:(NSString *)message onSuccess:(MessageAudienceCallback)successCallback onFailure:(MessageAudienceFailureCallback)errorCallback {
    [self messageOrCountAudienceOf:place message:message countOnly:NO onSuccess:successCallback onFailure:errorCallback];
}
-(void)messageOrCountAudienceOf:(Place *)place message:(NSString *)message countOnly:(BOOL)countOnly onSuccess:(MessageAudienceCallback)successCallback onFailure:(MessageAudienceFailureCallback)errorCallback {
    
    // Building URL
    NSString *url = [[NSString alloc] initWithFormat:kMessageAudienceUrlFormat,togaytherServer];
    
    // Building arguments
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    CurrentUser *user = [userService getCurrentUser];
    
    [params setObject:user.token forKey:kParamToken];
    [params setObject:place.key forKey:@"placeKey"];
    if(message != nil) {
        [params setObject:message forKey:@"message"];
    }
    if(countOnly) {
        [params setObject:@"true" forKey:@"countReach"];
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *json = (NSDictionary*)responseObject;
        NSNumber *usersReached          = [json objectForKey:@"usersReached"];
        NSNumber *nextAnnouncementTime  = [json objectForKey:@"nextAnnouncementDate"];
        NSDate *nextAnnouncementDate = nil;
        if(nextAnnouncementTime != nil && (id)nextAnnouncementTime != [NSNull null]) {
            nextAnnouncementDate = [NSDate dateWithTimeIntervalSince1970:nextAnnouncementTime.longValue];
        }
        // Calling back
        successCallback(usersReached.integerValue,nextAnnouncementDate);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSData *response = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
        NSError *jsonError;
        
        @try {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:response options:kNilOptions error:&jsonError];
            NSNumber    *ownershipError         = [json objectForKey:@"ownershipError"];
            NSNumber    *nextAnnouncementTime   = [json objectForKey:@"nextAnnouncementDate"];
            NSNumber    *usersReached           = [json objectForKey:@"usersReached"];
            NSDate * nextAnnouncementDate = nil;
            if(nextAnnouncementTime != nil && (id)nextAnnouncementTime != [NSNull null]) {
                nextAnnouncementDate = [NSDate dateWithTimeIntervalSince1970:nextAnnouncementTime.longValue];
            }
            
            errorCallback(ownershipError.boolValue,nextAnnouncementDate, usersReached.integerValue);
        } @catch(NSException *ex) {
            errorCallback(NO, nil, 0);
        }
    }];
}

@end
