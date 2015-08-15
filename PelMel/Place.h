//
//  Place.h
//  nativeTest
//
//  Created by Christophe Fondacci on 21/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CALObject.h"
#import "PMLProperty.h"

@interface Place : CALObject

@property (strong) NSString *title;
@property (strong) NSString *address;
@property (strong) NSString *distance;
@property (strong) NSString *cityName;
@property (strong) NSString *timezoneId;
@property (nonatomic,strong) NSString *ownerKey;
@property (nonatomic) double rawDistance;
@property (strong) NSString *placeType;
@property (nonatomic) NSInteger inUserCount; // Number of users currently in this place
@property (strong,nonatomic) NSMutableArray *inUsers;
@property (strong,nonatomic) NSMutableArray *events;
@property (nonatomic) int closedReportsCount;
@property (strong,nonatomic) NSMutableArray *hours;
@property (strong,nonatomic) NSMutableArray *deals;
@property (strong,nonatomic) NSMutableArray *properties;

- (id)initFull:(NSString*)title distance:(NSString *)distance miniDesc:(NSString*)desc;
- (id)init:(NSString*)title;

@end
