//
//  CityDetailProvider.m
//  PelMel
//
//  Created by Christophe Fondacci on 17/08/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "CityDetailProvider.h"

@implementation CityDetailProvider {
    City *_city;
}

- (instancetype)initWithCity:(City *)city
{
    self = [super init];
    if (self) {
        _city = city;
    }
    return self;
}
- (NSString *)getTitle {
    return [NSString stringWithFormat:NSLocalizedString(@"detail.city.title", @"City: N gay hangouts"),_city.name,_city.placesCount];
}
-(NSString *)getSecondDetailLine {
    return nil;
}
-(int)likesCount {
    return 0;
}

- (int)reviewsCount {
    return 0;
}
- (int)checkinsCount {
    return 0;
}
- (void)likeTapped:(CALObject *)likedObject callback:(LikeCompletionBlock)callback {
    NSLog(@"City log tapped");
}
@end
