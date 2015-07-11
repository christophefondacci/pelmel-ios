//
//  PMLManagedRecipientsGroupUser.h
//  PelMel
//
//  Created by Christophe Fondacci on 09/07/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PMLManagedRecipientsGroup, PMLManagedUser;

@interface PMLManagedRecipientsGroupUser : NSManagedObject

@property (nonatomic, retain) PMLManagedRecipientsGroup *recipientsGroup;
@property (nonatomic, retain) PMLManagedUser *user;

@end
