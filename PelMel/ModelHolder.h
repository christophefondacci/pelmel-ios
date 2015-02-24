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

typedef enum {
    PLACES_LISTVIEW,
    EVENTS_LISTVIEW
} ListviewType;




@interface ModelHolder : NSObject

@property (strong) NSArray *places;
@property (strong) NSArray *cities;
@property (strong) NSArray *events;
@property (strong) NSArray *activities;
@property (strong) NSArray *users;
@property (strong) NSMutableArray *allPlaces; // All places ever loaded
@property (strong) City *localizedCity;
@property (strong) CLLocation *userLocation;
@property (strong) CALObject *parentObject;
@property (strong) NSString *searchedText;
@property (strong) NSDate *dataTime;
@property (nonatomic) ListviewType currentListviewType;

-(void)updatePlaces:(NSArray *)places location:(CLLocation *)userLocation dataTime:(NSDate *)dataTime;
-(NSArray*)getCALObjects;

@end
