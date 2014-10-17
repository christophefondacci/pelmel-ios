//
//  LikeableStrategyObjectWithLiked.m
//  togayther
//
//  Created by Christophe Fondacci on 22/01/13.
//  Copyright (c) 2013 Christophe Fondacci. All rights reserved.
//

#import "LikeableStrategyObjectWithLiked.h"
#import "TogaytherService.h"

@implementation LikeableStrategyObjectWithLiked {
    UserService *userService;
    DataService *dataService;
}

- (id)init
{
    self = [super init];
    if (self) {
        userService = [TogaytherService userService];
        dataService = [TogaytherService dataService];
    }
    return self;
}

- (void)likeTapped:(CALObject*)likedObject callback:(LikeCompletionBlock)callback {
    [dataService genericLike:likedObject like:YES callback:callback];
}

@end
