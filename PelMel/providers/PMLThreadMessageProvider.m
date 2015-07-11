//
//  PMLThreadMessageProvider.m
//  PelMel
//
//  Created by Christophe Fondacci on 16/06/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLThreadMessageProvider.h"
#import "TogaytherService.h"
#import "PMLManagedUser.h"
#import "PMLManagedMessage.h"

@interface PMLThreadMessageProvider()
@property (nonatomic,retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic,retain) DataService *dataService;

@end

@implementation PMLThreadMessageProvider


- (instancetype)init
{
    self = [super init];
    if (self) {
        _dataService = [TogaytherService dataService];
        self.numberOfResults = 20;
    }
    return self;
}

- (NSFetchedResultsController *)fetchedResultsController:(NSManagedObjectContext*)managedObjectContext delegate:(id<NSFetchedResultsControllerDelegate>)delegate {
    
    
    if (_fetchedResultsController != nil) {
        _fetchedResultsController.delegate = delegate;
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"PMLManagedRecipient" inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    CurrentUser *user = [[TogaytherService userService] getCurrentUser];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"currentUserKey=%@ and itemKey != %@ and lastMessageDate!=nil", user.key,user.key];
    [fetchRequest setPredicate:predicate];

    NSSortDescriptor *sort = [[NSSortDescriptor alloc]
                              initWithKey:@"lastMessageDate" ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    [fetchRequest setFetchLimit:self.numberOfResults];
    [fetchRequest setFetchBatchSize:20];
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:managedObjectContext sectionNameKeyPath:nil
                                                   cacheName:@"Root"];
    self.fetchedResultsController = theFetchedResultsController;
    _fetchedResultsController.delegate = delegate;
    
    return _fetchedResultsController;

}

- (Message*)messageFromIndexPath:(NSIndexPath*)indexPath {
    // Getting result (might be dictionary or PMLManagedMessage)
    PMLManagedRecipient *recipient = [_fetchedResultsController objectAtIndexPath:indexPath];
    Message *message = [[Message alloc] init];
    
    message.key = nil;
    message.date = recipient.lastMessageDate;
    
    //    message.from = [[User alloc] init];
    if([recipient isKindOfClass:[PMLManagedUser class]]) {
        message.from = [[TogaytherService getMessageService] userFromManagedUser:(PMLManagedUser*)recipient];
    } else {
        message.recipientsGroupKey = ((PMLManagedRecipientsGroup*)recipient).itemKey;
    }
    message.to = [[TogaytherService userService] getCurrentUser];
    message.text = nil;
    message.unreadCount = recipient.unreadCount.integerValue;
    message.unread = recipient.unreadCount >0;
    message.messageCount = recipient.recipientMessages.count;
    return message;
}

- (void)setNumberOfResults:(NSInteger)numberOfResults {
    _numberOfResults = numberOfResults;
    [NSFetchedResultsController deleteCacheWithName:@"Root"];
    [_fetchedResultsController.fetchRequest setFetchLimit:_numberOfResults];
}
@end
