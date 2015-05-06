//
//  PMLActivityStatistic.h
//  PelMel
//
//  Created by Christophe Fondacci on 30/04/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CALImage.h"

@interface PMLActivityStatistic : NSObject

@property (nonatomic) NSInteger totalCount;
@property (nonatomic) NSInteger partialCount;
@property (nonatomic,strong) NSString *partialNames;
@property (nonatomic,strong) NSString *activityType;
@property (nonatomic,strong) CALImage *statImage;
@property (nonatomic,strong) NSNumber *maxActivityId;
@end
