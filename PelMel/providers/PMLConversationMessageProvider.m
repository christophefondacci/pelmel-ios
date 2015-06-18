
//
//  PMLConversationMessageProvider.m
//  PelMel
//
//  Created by Christophe Fondacci on 16/06/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLConversationMessageProvider.h"
#import "TogaytherService.h"
#import <CoreData/CoreData.h>
#import "PMLManagedMessage.h"
#import "PMLManagedUser.h"


@interface PMLConversationMessageProvider()
@property (nonatomic,retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic,retain) DataService *dataService;
@property (nonatomic,retain) NSString *fromItemKey;
@property (nonatomic,retain) NSString *toItemKey;
@end



@implementation PMLConversationMessageProvider

- (instancetype)initWithFromUserKey:(NSString*)fromUserKey toUserKey:(NSString*)toUserKey
{
    self = [super init];
    if (self) {
        self.dataService = [TogaytherService dataService];
        self.fromItemKey = fromUserKey;
        self.toItemKey = toUserKey;
        self.numberOfResults = 20;
    }
    return self;
}
- (NSFetchedResultsController *)fetchedResultsController:(NSManagedObjectContext *)managedObjectContext delegate:(id<NSFetchedResultsControllerDelegate>)delegate {
    
    
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"PMLManagedMessage" inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"from.itemKey = %@ or toItemKey = %@",self.fromItemKey,self.fromItemKey];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setFetchLimit:self.numberOfResults];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc]
                              initWithKey:@"messageDate" ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    [fetchRequest setFetchBatchSize:20];
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:managedObjectContext sectionNameKeyPath:nil
                                                   cacheName:self.fromItemKey];
    self.fetchedResultsController = theFetchedResultsController;
    _fetchedResultsController.delegate = delegate;
    
    return _fetchedResultsController;

}

- (Message *)messageFromIndexPath:(NSIndexPath *)indexPath {
    // Getting result (might be dictionary or PMLManagedMessage)
    PMLManagedMessage *msg = [_fetchedResultsController objectAtIndexPath:indexPath];
    Message *message = [[Message alloc] init];
    
    message.key = msg.messageKey;
    message.date = msg.messageDate;
    
    //    message.from = [[User alloc] init];
    NSString *fromItemKey = msg.from.itemKey;
    [_dataService getObject:fromItemKey callback:^(CALObject *overviewObject) {
        message.from = overviewObject;
        if(message.from == nil) {
            message.from = [[User alloc] init];
            message.from.key = fromItemKey;
            [_dataService.jsonService.objectCache setObject:message.from forKey:fromItemKey];
        }
    }];
    NSString *toItemKey = msg.toItemKey;
    [_dataService getObject:toItemKey callback:^(CALObject *overviewObject) {
        message.to = overviewObject;
        if(message.to == nil) {
            message.to = [[User alloc] init];
            message.to.key = toItemKey;
            [_dataService.jsonService.objectCache setObject:message.to forKey:toItemKey];
        }
    }];
    message.text = msg.messageText;
    NSString *imageUrl = msg.messageImageUrl;
    if(imageUrl != nil) {
        CALImage *image = [[CALImage alloc] initWithKey:msg.messageImageKey url:imageUrl thumbUrl:msg.messageImageThumbUrl];
        message.mainImage = image;
    }
    message.unread = [msg.isUnread boolValue];
    message.unreadCount = message.unread ? 1 : 0;
    return message;
}

- (void)setNumberOfResults:(NSInteger)numberOfResults {
    _numberOfResults = numberOfResults;
    [NSFetchedResultsController deleteCacheWithName:self.fromItemKey];
    _fetchedResultsController = nil;
//    [_fetchedResultsController.fetchRequest setFetchLimit:_numberOfResults];
}
@end
