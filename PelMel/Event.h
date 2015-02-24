//
//  Event.h
//  togayther
//
//  Created by Christophe Fondacci on 18/12/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "CALObject.h"
#import "Place.h"

@interface Event : CALObject

@property (strong) NSString *name;
@property (strong) NSDate *startDate;
@property (strong) NSDate *endDate;
@property (strong) Place *place;
@property (strong) NSString *distance;
@property (nonatomic) double rawDistance;

-(instancetype)initWithPlace:(Place*)place;
@end
