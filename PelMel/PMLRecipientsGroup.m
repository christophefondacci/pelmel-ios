//
//  PMLRecipientsGroup.m
//  PelMel
//
//  Created by Christophe Fondacci on 09/07/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLRecipientsGroup.h"

@implementation PMLRecipientsGroup

- (instancetype)initWithUsers:(NSArray *)users
{
    self = [super init];
    if (self) {
        self.users = [users mutableCopy];
    }
    return self;
}
@end
