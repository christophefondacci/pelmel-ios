//
//  PMLManagedUser.h
//  PelMel
//
//  Created by Christophe Fondacci on 25/06/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PMLManagedMessage;

@interface PMLManagedUser : NSManagedObject

@property (nonatomic, retain) NSString * itemKey;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDate * lastMessageDate;
@property (nonatomic, retain) NSString * imageUrl;
@property (nonatomic, retain) NSString * thumbUrl;
@property (nonatomic, retain) NSNumber * unreadCount;
@property (nonatomic, retain) NSString * currentUserKey;
@property (nonatomic, retain) NSSet *messages;
@end

@interface PMLManagedUser (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(PMLManagedMessage *)value;
- (void)removeMessagesObject:(PMLManagedMessage *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
