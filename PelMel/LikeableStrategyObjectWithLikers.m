//
//  LikeableStrategyObjectWithLikers.m
//  togayther
//
//  Created by Christophe Fondacci on 22/01/13.
//  Copyright (c) 2013 Christophe Fondacci. All rights reserved.
//

#import "LikeableStrategyObjectWithLikers.h"
#import "TogaytherService.h"

@implementation LikeableStrategyObjectWithLikers {
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

    [dataService genericLike:likedObject like:!likedObject.isLiked callback:^(int likes, int dislikes, BOOL isLiked) {
        User *likedUser;
        CurrentUser *currentUser = [userService getCurrentUser];
        for(User *user in likedObject.likers) {
            if([user.key isEqualToString:currentUser.key]) {
                likedUser = user;
                break;
            }
        }
        if(isLiked) {
            [likedObject.likers addObject:currentUser];
        } else {
            [likedObject.likers removeObject:likedUser];
        }
        likedObject.likeCount = likes;
        
        // Calling back our real callback
        callback(likes,dislikes,isLiked);
    }];
}

@end
