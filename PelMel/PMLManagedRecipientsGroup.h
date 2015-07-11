//
//  PMLManagedRecipientsGroup.h
//  PelMel
//
//  Created by Christophe Fondacci on 09/07/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "PMLManagedRecipient.h"

@class PMLManagedRecipientsGroupUser;

@interface PMLManagedRecipientsGroup : PMLManagedRecipient

@property (nonatomic, retain) NSSet *groupUsers;
@end

@interface PMLManagedRecipientsGroup (CoreDataGeneratedAccessors)

- (void)addGroupUsersObject:(PMLManagedRecipientsGroupUser *)value;
- (void)removeGroupUsersObject:(PMLManagedRecipientsGroupUser *)value;
- (void)addGroupUsers:(NSSet *)values;
- (void)removeGroupUsers:(NSSet *)values;

@end
