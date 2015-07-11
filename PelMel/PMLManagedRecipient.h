//
//  PMLManagedRecipient.h
//  PelMel
//
//  Created by Christophe Fondacci on 09/07/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PMLManagedMessage;

@interface PMLManagedRecipient : NSManagedObject

@property (nonatomic, retain) NSString * currentUserKey;
@property (nonatomic, retain) NSDate * lastMessageDate;
@property (nonatomic, retain) NSString * itemKey;
@property (nonatomic, retain) NSNumber * unreadCount;
@property (nonatomic, retain) NSSet *recipientMessages;
@end

@interface PMLManagedRecipient (CoreDataGeneratedAccessors)

- (void)addRecipientMessagesObject:(PMLManagedMessage *)value;
- (void)removeRecipientMessagesObject:(PMLManagedMessage *)value;
- (void)addRecipientMessages:(NSSet *)values;
- (void)removeRecipientMessages:(NSSet *)values;

@end
