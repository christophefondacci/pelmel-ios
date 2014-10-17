//
//  ModelHolder.m
//  nativeTest
//
//  Created by Christophe Fondacci on 25/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "ModelHolder.h"
#import "PlaceMasterProvider.h"
#import "EventMasterProvider.h"
#import "Event.h"

@implementation ModelHolder {
    NSObject<MasterProvider> *placeMasterProvider;
    NSObject<MasterProvider> *eventMasterProvider;
}

@synthesize places = _places;
@synthesize userLocation = _userLocation;
@synthesize dataTime = _dataTime;

- (id)init
{
    self = [super init];
    if (self) {
        // Default list is list of places
        _currentListviewType = PLACES_LISTVIEW;
    }
    return self;
}

-(void)updatePlaces:(NSArray *)places location:(CLLocation *)userLocation dataTime:(NSDate *)dataTime {
    _places = places;
    _userLocation = userLocation;
    _dataTime = dataTime;
}
- (NSArray *)getCALObjects {
    switch( _currentListviewType) {
        case PLACES_LISTVIEW:
            return _places;
        case EVENTS_LISTVIEW:
            return _events;
    }
    return nil;
}

- (NSObject<MasterProvider>*)getMasterProvider {
    switch(_currentListviewType) {
        case PLACES_LISTVIEW:
            // Initializing providers
            if(placeMasterProvider == nil) {
                placeMasterProvider = [[PlaceMasterProvider alloc] init];
            }
            return placeMasterProvider;
        case EVENTS_LISTVIEW:
            if(eventMasterProvider == nil) {
                eventMasterProvider = [[EventMasterProvider alloc] init];
            }
            return eventMasterProvider;
    }
    return nil;
}


@end
