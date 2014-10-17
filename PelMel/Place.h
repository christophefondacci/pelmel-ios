//
//  Place.h
//  nativeTest
//
//  Created by Christophe Fondacci on 21/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CALObject.h"


@interface Place : CALObject

@property (strong) NSString *title;
@property (strong) NSString *address;
@property (strong) NSString *distance;
@property (nonatomic) double rawDistance;
@property (strong) NSString *placeType;
@property (nonatomic) NSInteger inUserCount; // Number of users currently in this place
@property (readonly) NSMutableArray *inUsers;
@property (readonly) NSMutableArray *events;
@property (strong,nonatomic) NSArray *specials;
@property (nonatomic) int closedReportsCount;


- (id)initFull:(NSString*)title distance:(NSString *)distance miniDesc:(NSString*)desc;
- (id)init:(NSString*)title;

@end
