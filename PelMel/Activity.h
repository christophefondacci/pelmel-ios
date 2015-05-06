//
//  Activity.h
//  PelMel
//
//  Created by Christophe Fondacci on 28/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "CALObject.h"
#import "User.h"
#import "Place.h"

@interface Activity : CALObject

@property (nonatomic,strong) User *user;
// The target of the activity 
@property (nonatomic,strong) CALObject *activityObject;
@property (nonatomic,strong) NSDate *activityDate;
@property (nonatomic,strong) NSString *activityType;
@property (nonatomic,copy) NSString *message;
@property (nonatomic,copy) NSNumber *activitiesCount;

@end
