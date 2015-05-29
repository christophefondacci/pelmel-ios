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
