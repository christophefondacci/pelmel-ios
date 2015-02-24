//
//  Event.m
//  togayther
//
//  Created by Christophe Fondacci on 18/12/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "Event.h"

@implementation Event

- (instancetype)initWithPlace:(Place *)place
{
    self = [super init];
    if (self) {
        self.place = place;
        self.startDate = [NSDate new];
        self.endDate = [self.startDate dateByAddingTimeInterval:7200];
    }
    return self;
}

@end
