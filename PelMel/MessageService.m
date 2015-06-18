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
#define kSettingMaxMessageId @"message.maxId"
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
    if(self.messageFetchInProgress) {
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
        if(![userKey isEqualToString:user.key]) {
            [self markReadConversationWithUser:userKey];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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
- (NSNumber *)maxMessageId {
    NSNumber *maxMessageId = [_userDefaults objectForKey:kSettingMaxMessageId];
    if(maxMessageId == nil) {
        maxMessageId = @0;
    }
    return maxMessageId;
}
-(void)processJsonMessage:(NSDictionary*)jsonMessageList messageCallback:(id<MessageCallback>)callback forUserKey:(NSString*)userKey {
    CurrentUser *user = userService.getCurrentUser;
    NSMutableDictionary *usersMap = [[NSMutableDictionary alloc] init];
//    if([userKey isEqualToString:user.key] || userKey == nil) {
        NSArray *jsonUsers = [jsonMessageList objectForKey:@"users"];
        for(NSDictionary *jsonUser in jsonUsers) {
            User *aUser = [_jsonService convertJsonUserToUser:jsonUser];
            [usersMap setValue:aUser forKey:aUser.key];
        }
        
//    } else {
//        // Getting other user
//        NSDictionary *jsonOtherUser = [jsonMessageList objectForKey:@"toUser"];
//        User *otherUser = [_jsonService convertJsonUserToUser:jsonOtherUser];
//        [usersMap setValue:otherUser forKey:otherUser.key];
//    }
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

    NSMutableDictionary *messagesKeyMap = [[NSMutableDictionary alloc] init];
    NSMutableSet *messagesKeys = [[NSMutableSet alloc] init];
    NSMutableSet *messagesFromKeys = [[NSMutableSet alloc] init];
    NSMutableDictionary *messagesFromKeysMap = [[NSMutableDictionary alloc] init];
    NSNumber *maxId;
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
        [m setToItemKey:toKey];
        [m setText:text];
        [m setDate:msgDate];
        [m setUnread:[unread boolValue]];
        [m setUnreadCount:[unread integerValue]];
        
        if(media != nil) {
            CALImage *image = [[TogaytherService imageService] convertJsonImageToImage:media];
            [m setMainImage:image];
        }
        // Registering collections and maps
        [messagesKeyMap setObject:m forKey:key];
        [messagesKeys addObject:key];
        if(![messagesFromKeys containsObject:fromKey]) {
            [messagesFromKeys addObject:fromKey];
        }
        
        // Augmenting our collection of messages
        [calMessages addObject:m];
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
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageKey IN %@",messagesKeys];
    [fetchRequest setPredicate:predicate];
    // Fetching objects
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (PMLManagedMessage *msg in fetchedObjects) {
        // Removing the objects which we already have in database
        [messagesKeys removeObject:msg.messageKey];
        NSLog(@"Skipping message %@ already in CoreData",msg.messageKey);
    }
    
    // Fetching already existing users
    fetchRequest = [[NSFetchRequest alloc] init];
    entity = [NSEntityDescription entityForName:@"PMLManagedUser"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    predicate = [NSPredicate predicateWithFormat:@"itemKey IN %@",messagesFromKeys];
    [fetchRequest setPredicate:predicate];
    
    // Fetching objects and storing users in a map
    fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (PMLManagedUser *user in fetchedObjects) {
        [messagesFromKeysMap setObject:user forKey:user.itemKey];
    }
    
    // Processing remaining messages
    for(NSString *key in messagesKeys) {
        Message *m = [messagesKeyMap objectForKey:key];
        PMLManagedMessage *msg = [NSEntityDescription
                                  insertNewObjectForEntityForName:@"PMLManagedMessage"
                                  inManagedObjectContext:context];
        msg.messageKey = m.key;
        msg.messageDate = m.date;
        msg.toItemKey = m.toItemKey;
        msg.messageImageKey = m.mainImage.key;
        msg.messageImageThumbUrl = m.mainImage.thumbUrl;
        msg.messageImageUrl = m.mainImage.imageUrl;
        msg.messageText = m.text;
        msg.isUnread = [NSNumber numberWithBool:m.unread];
        
        // Getting from user
        PMLManagedUser *user = [messagesFromKeysMap objectForKey:m.from.key];
        if(user == nil) {
            user = [NSEntityDescription insertNewObjectForEntityForName:@"PMLManagedUser" inManagedObjectContext:context];
            [messagesFromKeysMap setObject:user forKey:m.from.key];
            NSLog(@"Storing user %@ in CoreData",m.key);
        }
        user.itemKey = m.from.key;
        user.name=((User*)m.from).pseudo;
        CALImage *image = ((User*)m.from).mainImage;
        user.imageUrl = image.imageUrl;
        user.thumbUrl = image.thumbUrl;
        if(m.unread) {
            user.unreadCount = user.unreadCount == nil ? @0 : [NSNumber numberWithInt:user.unreadCount.intValue + 1];
        }
        if(user.lastMessageDate == nil || [msg.messageDate compare:user.lastMessageDate] == NSOrderedDescending) {
            user.lastMessageDate = msg.messageDate;
        }
        msg.from = user;
        NSLog(@"Storing message %@ in CoreData",m.key);
    }
    // Saving entries
    if(messagesKeys.count>0) {
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        }
    }
    
    // Registering ID
    if([[self maxMessageId] longValue]<[maxId longValue]) {
        [_userDefaults setObject:maxId forKey:kSettingMaxMessageId];
    }
    
//    
//    
//    if([userKey isEqualToString:user.key]) {
//        // Reversing array and eliminating duplicates
//        NSMutableArray *filteredArray = [NSMutableArray arrayWithCapacity:calMessages.count];
//        NSMutableDictionary *keysMessageMap = [[NSMutableDictionary alloc] init];
//        for(Message *msg in [calMessages reverseObjectEnumerator]) {
//            Message *thread = [keysMessageMap objectForKey:msg.from.key];
//            if(thread == nil) {
//                msg.messageCount = 1;
//                [keysMessageMap setObject:msg forKey:msg.from.key];
//                [filteredArray addObject:msg];
//            } else {
//                thread.messageCount++;
//                thread.unreadCount+=msg.unreadCount;
//            }
//        }
//        // Switching
//        calMessages = filteredArray;
//    }
//    // Storing cache
//    PMLMessageCacheEntry *cacheEntry =  [[PMLMessageCacheEntry alloc] init];
//    cacheEntry.messages = calMessages;
//    cacheEntry.totalCount = [totalMsgCount integerValue];
//    cacheEntry.page = [page integerValue];
//    cacheEntry.pageSize = [pageSize integerValue];
//    [_messageCache setObject:cacheEntry forKey:[self cacheKeyFor:userKey page:[page integerValue]]];
//    
    // Now invoking callback
    dispatch_async(dispatch_get_main_queue(), ^{
        [callback messagesFetched:calMessages totalCount:[totalMsgCount integerValue] page:[page integerValue] pageSize:[pageSize integerValue]];
        for(id<MessageCallback> callback in _messageCallbacks) {
            [callback messagesFetched:calMessages totalCount:[totalMsgCount integerValue] page:[page integerValue] pageSize:[pageSize integerValue]];
        }
    });
    
    if([totalMsgCount intValue]>0) {
        dispatch_async(kBgQueue, ^{
            self.messageFetchInProgress = NO;
            [self getMessagesWithUser:userKey messageCallback:callback];
        });
    } else {
        self.messageFetchInProgress = NO;
    }

}
-(NSNumber*)idFromKey:(NSString*)key {
    NSString *maxIdStr = [key substringFromIndex:4];
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    return [f numberFromString:maxIdStr];
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

- (void)releaseToobar:(UIViewController *)view {
    
}
-(void)messageActionTouched:(id)sender {
    if(currentViewController != nil) {
        [currentViewController performSegueWithIdentifier:@"showMyMessages" sender:self];
    }
}
-(void)setUnreadMessageCount:(int)unreadMessageCount {
    _unreadMessageCount = MAX(unreadMessageCount,0);
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:unreadMessageCount];
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
