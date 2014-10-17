//
//  PMLLikeStatistic.h
//  PelMel
//
//  Created by Christophe Fondacci on 08/10/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PMLLikeStatistic : NSObject

// The list of activities of like events
@property (nonatomic,strong) NSArray *likeActivities;
// The list of activities of likers
@property (nonatomic,strong) NSArray *likerActivities;

@end
