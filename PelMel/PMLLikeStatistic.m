//
//  PMLLikeStatistic.m
//  PelMel
//
//  Created by Christophe Fondacci on 08/10/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PMLLikeStatistic.h"

@implementation PMLLikeStatistic

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.likeActivities = [[NSMutableArray alloc] init];
        self.likerActivities = [[NSMutableArray alloc] init];
    }
    return self;
}
@end
