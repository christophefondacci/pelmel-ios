//
//  User.m
//  PelMel
//
//  Created by Christophe Fondacci on 28/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "User.h"
#import "Description.h"

@implementation User

@synthesize pseudo = _pseudo;
@synthesize lastLocationDate = _lastLocationDate;

- (id)init {
    self = [super init];
    if (self) {
        _descriptions = [[NSMutableArray alloc] init];
        _likedPlaces = [[NSMutableArray alloc] init];
        _checkedInPlaces = [[NSMutableArray alloc] init];
        _events = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addDescription:(NSString *)description language:(NSString *)language {
    Description *desc = [[Description alloc] initWithDescription:description language:language];
    [_descriptions addObject:desc];
}

- (void)addDescriptionWithKey:(NSString *)key description:(NSString *)description language:(NSString *)language {
    Description *desc = [[Description alloc] initWithKey:key description:description language:language];
    [_descriptions addObject:desc];
}

@end
