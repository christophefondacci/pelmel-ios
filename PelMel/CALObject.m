//
//  CALObject.m
//  nativeTest
//
//  Created by Christophe Fondacci on 28/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "CALObject.h"

@implementation CALObject

@synthesize key = _key;
@synthesize lat = _lat;
@synthesize lng = _lng;
@synthesize tags = _tags;
@synthesize likeCount = _likeCount;
@synthesize dislikeCount = _dislikeCount;
@synthesize isLiked = _isLiked;
@synthesize likers = _likers;
@synthesize hasOverviewData = _hasOverviewData;

- (id)init {
    if(self = [super init]) {
        _likers = [[NSMutableArray alloc] init];
        _tags = [[NSMutableArray alloc] init];
        _reviews = [[NSMutableArray alloc] init];
        _timestamp = [NSDate date];
    }
    return self;
}
- (void)addLiker:(NSObject *)liker {
    [_likers addObject:liker];
}

- (void)setHasOverviewData:(BOOL)hasOverviewData {
    _hasOverviewData = hasOverviewData;
}
@end
