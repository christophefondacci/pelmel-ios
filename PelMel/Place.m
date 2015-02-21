//
//  ScaryBugData.m
//  nativeTest
//
//  Created by Christophe Fondacci on 21/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "Place.h"
#import "Event.h"

@implementation Place

@synthesize distance = _distance;
@synthesize title = _title;
@synthesize miniDesc = _miniDesc;
@synthesize tags = _tags;
@synthesize placeType = _placeType;
@synthesize inUserCount = _inUserCount;
@synthesize inUsers = _inUsers;

- (void) configure {
    _inUsers = [[NSMutableArray alloc] init];
    _events = [[NSMutableArray alloc] init];
    _hours = [[NSMutableArray alloc] init];
}

- (id)initFull:(NSString *)title distance:(NSString *)distance miniDesc:(NSString *)desc {
    if( self = [super init]) {
        _title = title;
        _distance = distance;
        _miniDesc = desc;
        [self configure];
    }
    return self;
}
- (id)init:(NSString *)title {
    if( self = [super init]) {
        _title = title;
        _distance = nil;
        _miniDesc = nil;
        [self configure];
    }
    return self;
}
- (id)init
{
    self = [super init];
    if (self) {
        [self configure];
    }
    return self;
}

- (void)addEvent:(Event *)event {
    [_events addObject:event];
}
@end
