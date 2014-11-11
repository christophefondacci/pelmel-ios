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
@property (strong,nonatomic) NSDate *date;
@property (strong,nonatomic) NSString *text;
@property (strong,nonatomic) NSString *key;
@end
