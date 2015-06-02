//
//  ModelHolder.m
//  nativeTest
//
//  Created by Christophe Fondacci on 25/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "ModelHolder.h"
#import "Event.h"

@implementation ModelHolder {
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
        _allPlaces = [[NSMutableArray alloc] init];
        _activityStats = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)updatePlaces:(NSArray *)places location:(CLLocation *)userLocation dataTime:(NSDate *)dataTime {
    _places = places;
    _userLocation = userLocation;
    _dataTime = dataTime;
}
-(void)refreshPlaces:(NSArray*)places {
    // Hashing all current places by their key
    NSMutableDictionary *placesKeyMap = [[NSMutableDictionary alloc ] init];
    for(Place *place in self.places) {
        [placesKeyMap setObject:place forKey:place.key];
    }
    // Preparing new places array
    NSMutableArray *newPlaces = [self.places mutableCopy];
    // Iterating over places to refresh
    for(Place *place in places) {
        // Does it exist?
        Place *currentPlace = [placesKeyMap objectForKey:place.key];
        // If yes
        if(currentPlace != nil) {
            if(currentPlace!= place) {
                // We replace the occurrence by the new one
                NSInteger index = [newPlaces indexOfObject:currentPlace];
                if(index!=NSNotFound) {
                    [newPlaces removeObject:currentPlace];
                    [newPlaces insertObject:place atIndex:index];
                }
            }
        } else {
            [newPlaces addObject:place];
        }
    }
    // Switching
    self.places = newPlaces;
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
- (void)setBanner:(PMLBanner *)banner {
    _banner = banner;
    _lastBannerDate = [NSDate date];
}

@end
