//
//  ModelHolder.h
//  nativeTest
//
//  Created by Christophe Fondacci on 25/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "CALObject.h"
#import "Special.h"
#import "City.h"
#import "PMLInfoProvider.h"
#import "PMLBanner.h"

typedef enum {
    PLACES_LISTVIEW,
    EVENTS_LISTVIEW
} ListviewType;




@interface ModelHolder : NSObject

@property (nonatomic,strong) NSArray *places;
@property (nonatomic,strong) NSArray *cities;
@property (nonatomic,strong) NSArray *events;
@property (nonatomic,strong) NSArray *activities;
@property (nonatomic,strong) NSArray *activityStats;
@property (nonatomic,strong) NSArray *users;
@property (nonatomic,strong) PMLBanner *banner;
@property (nonatomic,retain) NSDate *lastBannerDate;
@property (nonatomic) long maxLikes;
@property (nonatomic,strong) NSMutableArray *allPlaces; // All places ever loaded
@property (nonatomic,strong) City *localizedCity;
@property (nonatomic,strong) CLLocation *userLocation;
@property (nonatomic,strong) CALObject *parentObject;
@property (nonatomic,strong) NSString *searchedText;
@property (nonatomic,strong) NSDate *dataTime;
@property (nonatomic) ListviewType currentListviewType;
@property (nonatomic) int totalPlacesCount;
@property (nonatomic) int totalUsersCount;

-(void)updatePlaces:(NSArray *)places location:(CLLocation *)userLocation dataTime:(NSDate *)dataTime;
-(NSArray*)getCALObjects;

@end
