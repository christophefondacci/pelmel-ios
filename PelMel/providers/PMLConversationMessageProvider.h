//
//  PMLConversationMessageProvider.h
//  PelMel
//
//  Created by Christophe Fondacci on 16/06/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PMLMessageTableViewController.h"

@interface PMLConversationMessageProvider : NSObject<PMLMessageProvider>

@property (nonatomic) NSInteger numberOfResults;

- (instancetype)initWithFromUserKey:(NSString*)fromUserKey toUserKey:(NSString*)toUserKey;

@end
