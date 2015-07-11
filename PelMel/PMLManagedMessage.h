//
//  PMLManagedMessage.h
//  PelMel
//
//  Created by Christophe Fondacci on 09/07/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PMLManagedRecipient, PMLManagedUser;

@interface PMLManagedMessage : NSManagedObject

@property (nonatomic, retain) NSNumber * isUnread;
@property (nonatomic, retain) NSDate * messageDate;
@property (nonatomic, retain) NSString * messageImageKey;
@property (nonatomic, retain) NSString * messageImageThumbUrl;
@property (nonatomic, retain) NSString * messageImageUrl;
@property (nonatomic, retain) NSString * messageKey;
@property (nonatomic, retain) NSString * messageText;
@property (nonatomic, retain) NSString * toItemKey;
@property (nonatomic, retain) PMLManagedUser *from;
@property (nonatomic, retain) PMLManagedRecipient *replyTo;

@end
