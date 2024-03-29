//
//  Message.h
//  togayther
//
//  Created by Christophe Fondacci on 29/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CALObject.h"

@interface Message : NSObject
@property (strong,nonatomic) CALObject *from;
@property (strong,nonatomic) CALObject *to;
@property (strong,nonatomic) NSString *toItemKey;
@property (strong,nonatomic) NSDate *date;
@property (strong,nonatomic) NSString *text;
@property (strong,nonatomic) NSString *key;
@property (strong,nonatomic) NSString *recipientsGroupKey;
@property (strong,nonatomic) CALImage *mainImage;
@property (nonatomic) BOOL unread;
@property (nonatomic) NSInteger unreadCount;    // Unread message count in thread (if thread)
@property (nonatomic) NSInteger messageCount;    // Messages count in thread (if thread)
@end
