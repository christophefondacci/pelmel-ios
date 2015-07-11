//
//  PMLManagedUser.h
//  PelMel
//
//  Created by Christophe Fondacci on 09/07/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "PMLManagedRecipient.h"

@class PMLManagedMessage, PMLManagedRecipientsGroupUser;

@interface PMLManagedUser : PMLManagedRecipient

@property (nonatomic, retain) NSString * imageKey;
@property (nonatomic, retain) NSString * imageUrl;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * thumbUrl;
@property (nonatomic, retain) NSSet *messages;
@property (nonatomic, retain) NSSet *recipientsGroups;
@end

@interface PMLManagedUser (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(PMLManagedMessage *)value;
- (void)removeMessagesObject:(PMLManagedMessage *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

- (void)addRecipientsGroupsObject:(PMLManagedRecipientsGroupUser *)value;
- (void)removeRecipientsGroupsObject:(PMLManagedRecipientsGroupUser *)value;
- (void)addRecipientsGroups:(NSSet *)values;
- (void)removeRecipientsGroups:(NSSet *)values;

@end
