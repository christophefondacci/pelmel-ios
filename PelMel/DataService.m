//
//  DataService.m
//  nativeTest
//
//  Created by Christophe Fondacci on 25/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "DataService.h"
#import "CALObject.h"
#import "Place.h"
#import "Event.h"
#import "City.h"
#import "TogaytherService.h"
#import "ImageService.h"
#import "MessageService.h"
#import "Special.h"
#import "Activity.h"
#import "NSString+HTML.h"
#import <AFNetworking.h>
#import "PMLEditor.h"
#import "PMLBanner.h"


#define kPlaceListUrlFormat @"%@/mapPlaces.action?lat=%f&lng=%f&nxtpUserToken=%@&highRes=%@&searchLat=%f&searchLng=%f"
#define kEventListUrlFormat @"%@/mobileEvents.action?lat=%f&lng=%f&nxtpUserToken=%@&highRes=%@"
#define kOverviewDataUrlFormat @"%@/mobileOverview?id=%@&nxtpUserToken=%@&highRes=%@&lat=%f&lng=%f"
#define kOverviewPlaceUrlFormat @"%@/api/place"
#define kOverviewEventUrlFormat @"%@/api/event"
#define kOverviewUserUrlFormat @"%@/api/user"
#define kBannersListUrlFormat @"%@/api/banners"
#define kBannersCycleUrlFormat @"%@/api/banner"
#define kLikeUrlFormat @"%@/mobileIlike?id=%@&nxtpUserToken=%@&type=%@"
#define kPlaceUpdateUrlFormat @"%@/mobileUpdatePlace"
#define kBannerUpdateUrlFormat @"%@/mobileUpdateBanner"
#define kBannerUpdateStatusUrlFormat @"%@/mobileUpdateBannerStatus"
#define kCalendarUpdateUrlFormat @"%@/mobileUpdateEvent"
#define kCalendarDeleteUrlFormat @"%@/mobileDeleteEvent"
#define kReportAbuseUrl @"%@/mobileReport?key=%@&nxtpUserToken=%@&type=%d"

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
#define kTopQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)

#define kMaxLocalization 6
#define kMaxInterval 10



// Main data service implementation
@implementation DataService {
    CLLocationManager *locationManager;
    CLLocation *location;
    NSDate *lastLocationDate;


    NSString *togaytherServer;
    NSInteger localizationCount;

    // Caching data structures
    NSCache *overviewCache;
    
//    id<DataRefreshCallback> __weak _callback;
    
    BOOL shouldFetchObjectsContinue;
    NSMutableArray *dataListeners;
    
    NSMutableDictionary *connectionPlacesMap;

}

@synthesize modelHolder = _modelHolder;
@synthesize userService = userService;
@synthesize imageService = imageService;
@synthesize jsonService = jsonService;
@synthesize messageService = messageService;

/*
 * Initializes the location manager
 */
- (id)init {
    if( self = [super init] ) {
        // Instantiating location manager
        [self createLocationManager];
        
        
        // Storing server
        togaytherServer = [TogaytherService propertyFor:PML_PROP_SERVER];
        _reachabilityManager = [AFNetworkReachabilityManager managerForDomain:[togaytherServer stringByReplacingOccurrencesOfString:@"http://" withString:@""]];
        [_reachabilityManager startMonitoring];
        
        // Allocating model holder
        _modelHolder = [[ModelHolder alloc] init];
        
        // Building first entry (=wait message)
        NSMutableArray *docs = [[NSMutableArray alloc] init];
        _modelHolder.places = docs;
        

        // Initializing list of listeners
        dataListeners = [[NSMutableArray alloc] init];

        // Initializing location manager
        localizationCount = 0;
        [locationManager startUpdatingLocation];
        lastLocationDate = [NSDate date];
        
        // Initializing cache
        overviewCache = [[NSCache alloc] init];
        
        // Preparing maps
        connectionPlacesMap = [[NSMutableDictionary alloc ] init];


    }
    return self;
}



#pragma mark - Nearby data management
-(void)fetchNearbyPlaces {
    [self fetchPlacesFor:nil searchTerm:nil];
}
-(void)fetchPlacesFor:(CALObject *)parent {
    [self fetchPlacesFor:parent searchTerm:nil];
}

/*
 * Starting a refresh 
 */
-(void)fetchPlacesFor:(CALObject *)parent searchTerm:(NSString *)searchTerm {
    [PMLEditor purgeEditors];

    dispatch_async(kBgQueue, ^{
        BOOL isLocalized = NO;
        while(!isLocalized) {
            NSDate *date = [NSDate date];
            if( ([date timeIntervalSince1970] - [lastLocationDate timeIntervalSince1970] > 3.0) || (localizationCount>=kMaxLocalization)) {
                // We have a quite precise localization
                isLocalized = YES;
                
                // Callbacking on main thread
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    // Notifying every registered listener
                    for(NSObject<PMLDataListener> *callback in dataListeners) {
                        
                        // Notifying if responding to method
                        if([callback respondsToSelector:@selector(didLocalizeDevice:)]) {
                            [callback didLocalizeDevice:location];
                        }
                    }
                    // Fetching
                    [self fetchPlacesAtLatitude:location.coordinate.latitude longitude:location.coordinate.longitude for:parent searchTerm:searchTerm];
                });

            } else {
                [NSThread sleepForTimeInterval:1.0];
            }
        }
    });
}
+ (NSString *) urlencode: (NSString *) stringToEncode
{
    NSString *encodedString = [stringToEncode stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    return [encodedString stringByReplacingOccurrencesOfString: @"&" withString: @"%26"];
}
-(void)fetchPlacesAtLatitude:(double)latitude longitude:(double)longitude for:(CALObject *)parent searchTerm:(NSString *)searchTerm {
    [self fetchPlacesAtLatitude:latitude longitude:longitude for:parent searchTerm:searchTerm radius:_currentRadius silent:NO];
}

-(void)fetchPlacesAtLatitude:(double)latitude longitude:(double)longitude for:(CALObject *)parent searchTerm:(NSString *)searchTerm radius:(double)radius silent:(BOOL)isSilent {
    self.searchTerm = searchTerm;
    self.currentLatitude = latitude;
    self.currentLongitude = longitude;
    self.currentRadius = radius;
    
    [self startOp:@""];
    [self notify:@selector(willLoadData) with:nil mainThread:YES];
    BOOL retina = [TogaytherService isRetina];
    // Fetching data from JSON from an URL
    dispatch_async(kBgQueue, ^{
        // Updating our model
        [_modelHolder setUserLocation:location];
        [_modelHolder setDataTime:lastLocationDate];
        switch(_modelHolder.currentListviewType) {
            case PLACES_LISTVIEW:
                [_modelHolder setParentObject:parent];
                [_modelHolder setSearchedText:searchTerm];
            default:
                break;
        }
        CurrentUser *user = userService.getCurrentUser;
        
        // Getting URL template for Event or Place list depending on current mode
        NSString *template = nil;
        switch(_modelHolder.currentListviewType) {
            case PLACES_LISTVIEW:
                template = kPlaceListUrlFormat;
                break;
            case EVENTS_LISTVIEW:
                template = kEventListUrlFormat;
                break;
        }
        // Fallbacking lat/lng to user location if 0/0
        double searchLat, searchLng;
        if(latitude == 0 && longitude == 0) {
            searchLat = location.coordinate.latitude;
            searchLng = location.coordinate.longitude;
        } else {
            searchLat=latitude;
            searchLng=longitude;
        }
        
        NSString *url = [[NSString alloc] initWithFormat:template,togaytherServer, location.coordinate.latitude, location.coordinate.longitude, user.token, retina ? @"true" : @"false",searchLat,searchLng];
        if(searchTerm != nil) {
            NSString *encodedSearchTerm = [DataService urlencode:[searchTerm stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
            url = [NSString stringWithFormat:@"%@&searchText=%@",url,encodedSearchTerm];
        }
        if(parent!=nil) {
            url = [NSString stringWithFormat:@"%@&parentKey=%@",url,parent.key];
        }
        if(radius>0) {
            url = [NSString stringWithFormat:@"%@&radius=%d",url,(int)radius /*MAX(radius,50)*/];
        }
        NSLog(@"Objects list : calling URL %@",url);
        shouldFetchObjectsContinue = YES;
        NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        
        // If we got objects returned we initialize the corresponding info
        if(data != nil) {
            
            if(shouldFetchObjectsContinue) {
                
                
                // Calling appropriate callback
                switch(_modelHolder.currentListviewType) {
                    case PLACES_LISTVIEW:
                        [self placesDataFetched:data silent:isSilent];
                        break;
                    case EVENTS_LISTVIEW:
                        [self eventsDataFetched:data silent:isSilent];
                        break;
                }
            }
        } else {
            [self performSelectorOnMainThread:@selector(notifyConnectionLost) withObject:nil waitUntilDone:NO];
        }

    });
}

- (void)getNearbyPlaces {
    [self getNearbyPlacesFor:nil searchTerm:nil];
}
- (void)getNearbyPlacesFor:(CALObject *)parent {
    [self getNearbyPlacesFor:parent searchTerm:nil];
}
- (void)getNearbyPlacesFor:(CALObject *)parent searchTerm:(NSString *)searchTerm {
    switch(_modelHolder.currentListviewType) {
        case PLACES_LISTVIEW:
            if(_modelHolder.places.count>0) {
                [self doCallback:NO];
            } else {
                [self fetchPlacesFor:parent searchTerm:searchTerm];
            }
            break;
        case EVENTS_LISTVIEW:
            if(_modelHolder.events.count>0) {
                [self doCallback:NO];
            } else {
                [self fetchPlacesFor:parent searchTerm:searchTerm];
            }
            break;
    }
}
- (void)placesDataFetched:(NSData *)responseData silent:(BOOL)isSilent {
    NSLog(@"JSON place data fetched");
    //parse out the json data
    NSError* error;
    if(responseData == nil) {
        NSLog(@"JSON data null for placesDataFetched");
        return;
    }
    NSDictionary *json = [NSJSONSerialization
                          JSONObjectWithData:responseData //1
                          options:kNilOptions
                          error:&error];
    
    NSArray *jsonPlaces = [json objectForKey:@"places"];
    NSMutableArray *docs = [[NSMutableArray alloc] initWithCapacity:[jsonPlaces count]];
    
    NSMutableArray *happyHoursEvents = [[NSMutableArray alloc] init];
    NSMutableArray *themeNightsEvents = [[NSMutableArray alloc] init];
    long maxLikes = 0;
    // Preparing the no image thumb (default for every place at first)
    for(NSDictionary *jsonPlace in jsonPlaces) {
        Place *place = [jsonService convertFullJsonPlaceToPlace:jsonPlace];
        [place setHasOverviewData:NO];
        
        // Computing max likes
        if(place.likeCount > maxLikes ) {
            maxLikes = place.likeCount;
        }
        // Appending to the document list
        [docs addObject:place];
        // Building specials as events
        NSDate *now= [NSDate date];
        for(PMLCalendar *special in place.hours) {
            if(![special.calendarType isEqualToString:SPECIAL_TYPE_OPENING]) {
                special.hasOverviewData = NO;
                if([special.endDate compare:now] == NSOrderedDescending) {
                    if([special.calendarType isEqualToString:SPECIAL_TYPE_HAPPY]) {
                        [happyHoursEvents addObject:special];
                    } else if([special.calendarType isEqualToString:SPECIAL_TYPE_THEME]) {
                        [themeNightsEvents addObject:special];
                    }
                }
            }
        }
    }
    [happyHoursEvents sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        Event *e1 = (Event*)obj1;
        Event *e2 = (Event*)obj2;
        return [e1.startDate compare:e2.startDate];
    }];
    NSArray *jsonCities = [json objectForKey:@"cities"];
    NSMutableArray *cities = [[NSMutableArray alloc] initWithCapacity:jsonCities.count];
    for(NSDictionary *jsonCity in jsonCities) {
        City *city = [jsonService convertJsonCityToCity:jsonCity];
        [cities addObject:city];
    }
    
    // Parsing activities
    NSArray *jsonActivities = [json objectForKey:@"nearbyActivities"];
    NSArray *activities = [jsonService convertJsonActivitiesToActivities:jsonActivities];

    // Parsing users
    NSArray *jsonUsers = [json objectForKey:@"nearbyUsers"];
    NSArray *users = [jsonService convertJsonUsersToUsers:jsonUsers];
    for(User *user in users) {
        [user setHasOverviewData:NO];
    }
    // Parsing events
    NSArray *jsonEvents = [json objectForKey:@"nearbyEvents"];
    NSMutableArray *events = [[[jsonService convertJsonEventsToEvents:jsonEvents] arrayByAddingObjectsFromArray:themeNightsEvents ] mutableCopy];
    [events sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        Event *e1 = (Event*)obj1;
        Event *e2 = (Event*)obj2;
        return [e1.startDate compare:e2.startDate];
    }];
    for(Event *event in events) {
        [event setHasOverviewData:NO];
    }
    // Parsing localized city
    NSDictionary *jsonCity = [json objectForKey:@"localizedCity"];
    City *localizedCity = nil;
    if(jsonCity != nil && jsonCity!=(id)[NSNull null]) {
        localizedCity = [jsonService convertJsonCityToCity:jsonCity];
    }
    
    // Parsing counts
    NSNumber *totalPlacesCount = [json objectForKey:@"nearbyPlacesCount"];
    NSNumber *totalUsersCount = [json objectForKey:@"nearbyUsersCount"];
    
    // ACtivities count
    NSNumber *maxActivityId = [json objectForKey:@"maxActivityId"];
    [[TogaytherService getMessageService] setMaxActivityId:maxActivityId.longValue];
    
    // Banners
    NSDictionary *jsonBanner = [json objectForKey:@"banner"];
    if(jsonBanner != nil && (id)jsonBanner != [NSNull null]) {
        PMLBanner *banner = [jsonService convertJsonBannerToBanner:jsonBanner];
        [_modelHolder setBanner:banner];
    } else {
        [_modelHolder setBanner:nil];
    }
    
    // Assigning to model holder for all-view synch
    [_modelHolder setPlaces:docs];
    [_modelHolder setEvents:events];
    [_modelHolder setHappyHours:happyHoursEvents];
    [[_modelHolder allPlaces] addObjectsFromArray:docs];
    [_modelHolder setCities:cities];
    [_modelHolder setActivities:activities];
    [_modelHolder setUsers:users];
    [_modelHolder setLocalizedCity:localizedCity];
    [_modelHolder setMaxLikes:maxLikes];

    if(totalPlacesCount!=nil) {
        [_modelHolder setTotalPlacesCount:[totalPlacesCount intValue]];
    }
    if(totalUsersCount != nil) {
        [_modelHolder setTotalUsersCount:[totalUsersCount intValue]];
    }
    
    // Callback on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [self doCallback:isSilent];
    });
    
}

- (void)eventsDataFetched:(NSData *)responseData silent:(BOOL)isSilent {
    NSLog(@"JSON events data fetched");
    //parse out the json data
    NSError* error;
    if(responseData == nil) {
        NSLog(@"JSON data null for eventsDataFetched");
        return;
    }
    NSArray *jsonEvents = [NSJSONSerialization
                           JSONObjectWithData:responseData //1
                           options:kNilOptions
                           error:&error];
    NSMutableArray *events = [[NSMutableArray alloc] initWithCapacity:[jsonEvents count]];
    // Preparing the no image thumb (default for every place at first)
    for(NSDictionary *jsonEvent in jsonEvents) {
        Event *event = [jsonService convertJsonEventToEvent:jsonEvent defaultEvent:nil];
        
        // Appending to the document list
        [events addObject:event];
    }
    // Assigning to model holder for all-view synch
    [_modelHolder setEvents:events];
    
    // Callback on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [self doCallback:isSilent];
    });
}



#pragma mark Location Manager and CLLocationManagerDelegate
/*
 * Creates the location manager
 */
- (void) createLocationManager {
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    if([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [locationManager requestWhenInUseAuthorization];
    }
}
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if(status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [locationManager startUpdatingLocation];
    }
}
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    localizationCount++;
    
//    location = [[CLLocation alloc] initWithLatitude:37.7833 longitude:-122.4167];
    // DEBUG: uncomment me
    location = newLocation;
    _modelHolder.userLocation = newLocation;
    CurrentUser *user = userService.getCurrentUser;
    user.lat = location.coordinate.latitude;
    user.lng = location.coordinate.longitude;
    userService.currentLocation = newLocation;
    
    // Saving for future app starts
    NSNumber *lat = [NSNumber numberWithDouble:user.lat];
    NSNumber *lng = [NSNumber numberWithDouble:user.lng];
    [[NSUserDefaults standardUserDefaults] setObject:lat forKey:kPMLKeyLastLatitude];
    [[NSUserDefaults standardUserDefaults] setObject:lng forKey:kPMLKeyLastLongitude];
}

#pragma mark - Overview data management

- (void)getOverviewData:(CALObject*)object {
    // Not very useful for now, might become cache based if we do not
    // transmit partial data in nearby list
    if(object.hasOverviewData) {
        [self notifyOverviewDataAvailable:object];
    } else {
        // Ensuring only one overview fetched at a time
        if([overviewCache objectForKey:object.key] == nil) {
            [overviewCache setObject:object forKey:object.key];
            [self fetchOverviewData:object];
        }
    }
}
- (void)getObject:(NSString *)key callback:(OverviewCompletionBlock)callback {
    CALObject *obj = [jsonService.objectCache objectForKey:key];
    callback(obj);
}
-(NSString*)overviewUrlTemplateFor:(CALObject*)object {
    if([object isKindOfClass:[Place class]]) {
        return kOverviewPlaceUrlFormat;
    } else if([object isKindOfClass:[User class]]) {
        return kOverviewUserUrlFormat;
    } else if([object isKindOfClass:[Event class]]) {
        return kOverviewEventUrlFormat;
    }
    return nil;
}
-(void)fetchOverviewData:(CALObject *)object {
    [self startOp:@""];
    
    if(!object.hasOverviewData && object.key != nil) {
        // Loading object's full data
        CurrentUser *user = userService.getCurrentUser;
        BOOL isRetina = [TogaytherService isRetina];
        
        // Getting appropriate URL
        NSString *template = [self overviewUrlTemplateFor:object];
        NSString *url = [[NSString alloc] initWithFormat:template,togaytherServer ];
        if(url != nil) {
            // Filling arguments
            NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
            [params setObject:object.key forKey:@"id"];
            NSString *token = user.token;
            if(token == nil) {
                // Trying with last known token
                token = [[NSUserDefaults standardUserDefaults] objectForKey:PML_PROP_USER_LAST_TOKEN];
            }
            [params setObject:token forKey:@"nxtpUserToken"];
            [params setObject:(isRetina ? @"true" : @"false") forKey:@"highRes"];
            [params setObject:[NSString stringWithFormat:@"%f",location.coordinate.latitude] forKey:@"lat"];
            [params setObject:[NSString stringWithFormat:@"%f",location.coordinate.longitude] forKey:@"lng"];
            
            NSLog(@"Overview data : calling URL %@/id=%@&nxtpUserToken=%@",url,object.key,user.token);
            AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
            [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSDictionary *json = (NSDictionary*)responseObject;
                if([object isKindOfClass:[Place class]]) {
                    [self placeOverviewDataFetched:json object:object];
                } else if([object isKindOfClass:[User class]]) {
                    [self userOverviewDataFetched:json object:object];
                } else if([object isKindOfClass:[Event class]]) {
                    [self eventOverviewDataFetched:json object:object];
                }
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [self notifyConnectionLost];
            }];
        }
        // Clearing cache action
        [overviewCache removeObjectForKey:object.key];
    } else {
        [self notifyOverviewDataAvailable:object];
    }
}
- (void)eventOverviewDataFetched:(NSDictionary*)json object:(CALObject*)object {
    Event *event = (Event*)object;
    
    // Checking any login error
    NSString *loginFailed = [json objectForKey:@"loginFailed"];
    if(loginFailed != nil) {
        [self notifyLoginFailed];
        return;
    }
    
    // Getting unread message count
    NSNumber *unreadMsgCount = [json objectForKey:@"unreadMsgCount"];
    NSNumber *unreadNetworkCount=[json objectForKey:@"unreadNetworkNotificationsCount"];
    [messageService setUnreadMessageCount:[unreadMsgCount intValue]];
    [messageService setUnreadNetworkCount:unreadNetworkCount.intValue];
    
    // Building event from JSON
    event = [jsonService convertJsonEventToEvent:json defaultEvent:event];

    // Flagging our bean as having overview data
    [event setHasOverviewData:YES];
    
    // Calling our callback
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyOverviewDataAvailable:event];
    });
}
- (void)userOverviewDataFetched:(NSDictionary*)json object:(CALObject*)object {
    // Checking any login error
    NSString *loginFailed = [json objectForKey:@"loginFailed"];
    if(loginFailed != nil) {
        [self notifyLoginFailed];
        return;
    }

    // Filling user from JSon

    User *user = [jsonService convertJsonOverviewUserToUser:json defaultUser:(User*)object];
    [jsonService fillUser:user fromJson:json];
    
    // Calling our callback
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyOverviewDataAvailable:user];
    });
}

- (void)placeOverviewDataFetched:(NSDictionary*)json object:(CALObject*)object {
    
    // Checking any login error
    NSString *loginFailed = [json objectForKey:@"loginFailed"];
    if(loginFailed != nil) {
        [self notifyLoginFailed];
        return;
    }
    
    Place *place = [jsonService convertJsonOverviewPlaceToPlace:json defaultPlace:(Place*)object];
    assert(place == object);
    
    // Notifying callback
    // Calling our callback
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyOverviewDataAvailable:place];
    });
    
}

#pragma mark - Like management

- (void)like:(CALObject *)object callback:(LikeCompletionBlock)callback {
    [self genericLike:object like:YES callback:callback];
}

- (void)dislike:(CALObject *)object callback:(LikeCompletionBlock)callback {
    [self genericLike:object like:NO callback:callback];
}

-(void)genericLike:(CALObject*)object like:(BOOL)like callback:(LikeCompletionBlock)callback {
    CurrentUser *user = [userService getCurrentUser];
    NSString *url = [[NSString alloc] initWithFormat:kLikeUrlFormat,togaytherServer, object.key,user.token,like ? @"1" : @"-1"];
    dispatch_async(kTopQueue, ^{
        // Calling like URL
        NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        NSError* error;
        
        if(data == nil) {
            NSLog(@"genericLike: JSON data is null, aborting");
            return;
        }
        // Deserializing JSON
        NSDictionary *json = [NSJSONSerialization
                              JSONObjectWithData:data //1
                              options:kNilOptions
                              error:&error];
        
        // Extracting new counts
        NSNumber *likeCount = [json objectForKey:@"likeCount"];
        NSNumber *dislikeCount = [json objectForKey:@"dislikeCount"];
        NSNumber *liked = [json objectForKey:@"liked"];
        
        // Calling callback
        dispatch_async(dispatch_get_main_queue(), ^{
            int myLikeCount = [likeCount intValue];
            int myDislikeCount = [dislikeCount intValue];
            callback(myLikeCount,myDislikeCount,liked.boolValue);
            [self notifyLike:object likes:myLikeCount dislikes:myDislikeCount liked:liked.boolValue];
        });
    });
}
- (void)cancelRunningProcesses {
//    [locationManager stopUpdatingLocation];
    shouldFetchObjectsContinue = NO;
}
#pragma mark - Report management
- (void)sendReportFor:(CALObject *)object reportType:(PMLReportType)reportType {

    // About to start
    [self notify:@selector(willSendReportFor:) with:object mainThread:YES];
    
    dispatch_async(kTopQueue, ^{
        CurrentUser *user = [userService getCurrentUser];
        NSString *url = [NSString stringWithFormat:kReportAbuseUrl,togaytherServer,object.key,user.token,reportType];
        
        NSData *response = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        if(response != nil) {
            NSError *error;
            NSDictionary *jsonInfo = [NSJSONSerialization
                                      JSONObjectWithData:response //1
                                      options:kNilOptions
                                      error:&error];
            NSNumber *isError  = [jsonInfo objectForKey:@"error"];
            BOOL hasError = [isError boolValue];
            NSString *errorMsg = [jsonInfo objectForKey:@"message"];
            dispatch_async(dispatch_get_main_queue(), ^{
                if(!hasError) {
                    [self notify:@selector(didSendReportFor:) with:object mainThread:YES];
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self notifySendReportFailed:object reason:errorMsg];
                    });
                }
            });
        }
        
    });
}

#pragma mark - Listeners and callback management

- (void)registerDataListener:(NSObject<PMLDataListener>*)callback {
    if(![dataListeners containsObject:callback]) {
        [dataListeners addObject:callback];
        
        // If registering a listener while we already have data, we callback immediately
        if(_modelHolder != nil && _modelHolder.places.count>0) {
            
            // Checking if implemented
            if([callback respondsToSelector:@selector(didLoadData:silent:)]) {
                [callback didLoadData:_modelHolder silent:NO];
            }
        }
    }
}
- (void)unregisterDataListener:(id<PMLDataListener>)callback {
    [dataListeners removeObject:callback];
}
-(void)startOp:(NSString*)msg {
    // Notifying that we are starting a data op
    for(NSObject<PMLDataListener> *callback in [NSArray arrayWithArray:dataListeners]) {
        
        // Only notifying if supported
        if([callback respondsToSelector:@selector(didStartDataOperation:)]) {
            [callback didStartDataOperation:@""];
        }
    }
}


- (void)notifyOverviewDataAvailable:(CALObject*)object {
    for(NSObject<PMLDataListener> *callback in [NSArray arrayWithArray:dataListeners]) {
        if([callback respondsToSelector:@selector(didLoadOverviewData:)]) {
            [callback didLoadOverviewData:object];
        }
    }
    [self cycleBanner];
}
-(void)notifyLoginFailed {
    for(NSObject<PMLDataListener> *callback in dataListeners) {
        if([callback respondsToSelector:@selector(loginFailed)]) {
            [callback loginFailed];
        }
    }
}
-(void)notifyLike:(CALObject*)object likes:(int)likes dislikes:(int)dislikes liked:(BOOL)liked {
    for(NSObject<PMLDataListener> *callback in [NSArray arrayWithArray:dataListeners]) {
        if([callback respondsToSelector:@selector(didLike:newLikes:newDislikes:liked:)]) {
            [callback didLike:object newLikes:likes newDislikes:dislikes liked:liked];
        }
    }
}
- (void) doCallback:(BOOL)silent {
    
    // Iterating over all listeners
    for(NSObject<PMLDataListener> *callback in [NSArray arrayWithArray:dataListeners] ) {
        
        // Optional callback method
        if([callback respondsToSelector:@selector(didLoadData:silent:)]) {
            [callback didLoadData:_modelHolder silent:silent];
        }
    }
}
-(void)notifyWillUpdatePlace:(Place*)place {
    for(NSObject<PMLDataListener> *callback in [NSArray arrayWithArray:dataListeners]) {
        if([callback respondsToSelector:@selector(willUpdatePlace:)]) {
            [callback willUpdatePlace:place];
        }
    }
}
-(void)notifyPlaceUpdated:(Place*)place {
    for(NSObject<PMLDataListener> *callback in [NSArray arrayWithArray:dataListeners]) {
        if([callback respondsToSelector:@selector(didUpdatePlace:)]) {
            [callback didUpdatePlace:place];
        }
    }
}
-(void)notifyObjectCreated:(CALObject*)object {
    for(NSObject<PMLDataListener> *callback in [NSArray arrayWithArray:dataListeners]) {
        if([callback respondsToSelector:@selector(objectCreated:)]) {
            [callback objectCreated:object];
        }
    }
}
-(void)notifyConnectionLost {
    for(NSObject<PMLDataListener> *callback in dataListeners) {
        if([callback respondsToSelector:@selector(didLooseConnection)]) {
            [callback didLooseConnection];
        }
    }
}
-(void)notify:(SEL)selector with:(CALObject*)object mainThread:(BOOL)mainThread {
    for(NSObject<PMLDataListener> *callback in [NSArray arrayWithArray:dataListeners]) {
        if([callback respondsToSelector:selector]) {
            if(mainThread) {
                [callback performSelectorOnMainThread:selector withObject:object waitUntilDone:NO];
            } else {
                [callback performSelector:selector withObject:object];
            }
        }
    }
}
-(void)notifySendReportFailed:(CALObject*)object reason:(NSString*)reason {
    for(NSObject<PMLDataListener> *callback in dataListeners) {
        if([callback respondsToSelector:@selector(didFailSendReportFor:reason:)]) {
            [callback didFailSendReportFor:object reason:reason];
        }
    }
}
#pragma mark - Data modification methods
-(void)setIfDefined:(NSString *)value forKey:(NSString*)key fill:(NSMutableDictionary*)dic {
    if(value != nil) {
        [dic setObject:value forKey:key];
    }
}
-(void)setIfTrue:(BOOL)myBool forKey:(NSString*)key fill:(NSMutableDictionary*)dic {
    if(myBool) {
        [dic setObject:@"true" forKey:key];
    }
}
-(void)fillDescriptionsFor:(CALObject*)object inParams:(NSMutableDictionary*)paramValues {
    [self setIfDefined:object.miniDesc   forKey:@"description" fill:paramValues];
    if(object.miniDesc) {
        NSString *key = object.miniDescKey == nil ? @"" : object.miniDescKey;
        [paramValues setObject:key forKey:@"descriptionKey"];
    }
    if(object.miniDescLang==nil) {
        object.miniDescLang= [TogaytherService getLanguageIso6391Code];
    }
    [self setIfDefined:object.miniDescLang forKey:@"descriptionLanguageCode" fill:paramValues];
}
- (void)updatePlace:(Place *)place callback:(UpdatePlaceCompletionBlock)callback {
    NSLog(@"updatePlace called");
    [self notifyWillUpdatePlace:place];
    dispatch_async(kTopQueue, ^{
        // Building the URL

        NSString *url = [[NSString alloc] initWithFormat:kPlaceUpdateUrlFormat,togaytherServer ];
//        BOOL isHighRes = [TogaytherService isRetina];
        
        // Flag storing whether this is a new place
        BOOL isNew = place.key == nil;
        
        // Getting birth date components
        NSMutableDictionary *paramValues = [[NSMutableDictionary alloc] init];
        CurrentUser *user = userService.getCurrentUser;
        [self setIfDefined:place.title      forKey:@"name"      fill:paramValues];
        [self setIfDefined:place.key        forKey:@"placeId"   fill:paramValues];
        [self setIfDefined:place.address    forKey:@"address"   fill:paramValues];
        [self setIfDefined:place.placeType  forKey:@"placeType" fill:paramValues];
        [self setIfDefined:[NSString stringWithFormat:@"%f",place.lat]  forKey:@"latitude"  fill:paramValues];
        [self setIfDefined:[NSString stringWithFormat:@"%f",place.lng]  forKey:@"longitude" fill:paramValues];
        [self setIfDefined:place.placeType  forKey:@"placeType" fill:paramValues];
        [self setIfDefined:user.token       forKey:@"nxtpUserToken" fill:paramValues];
        

        // Filling descriptions
        [self fillDescriptionsFor:place inParams:paramValues];
        // Preparing POST request
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager POST:url parameters:paramValues success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"JSON: %@", responseObject);
            NSDictionary *json = (NSDictionary*)responseObject;
            
            // Checking any login error
            NSString *loginFailed = [json objectForKey:@"loginFailed"];
            if(loginFailed != nil) {
                [self notifyLoginFailed];
                return;
            }
            
            // Now processing
            Place *newPlace = [jsonService convertJsonOverviewPlaceToPlace:json defaultPlace:place];
            place.key = newPlace.key;
            place.editing = NO;
            // Adding new place to model holder places list
            if(isNew) {
                NSMutableArray *newPlaces = [NSMutableArray arrayWithArray:_modelHolder.places];
                [newPlaces addObject:place];
                _modelHolder.places = newPlaces;
            }
            // We want to refretch all data after an update
            dispatch_async(dispatch_get_main_queue(), ^{
                [self notifyPlaceUpdated:newPlace];
                callback(newPlace);
                
                // If the place does not have a picture, prompt to add one
                if(place.mainImage==nil) {
                    [[TogaytherService actionManager] execute:PMLActionTypeAddPhoto onObject:newPlace];
                }
            });
            

            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
        
    });
    
}
-(void)updateBanner:(PMLBanner*)banner callback:(UpdateBannerCompletionBlock)callback failure:(UpdateBannerCompletionBlock)failureCallback {

//    NSString *title = 
//    [_uiService alertWithTitle:@"banner.purchase.title" text:@"banner.purchase.confirm" textObjectName:<#(NSString *)#>]
    // Building server URL for banner update
    NSString *url = [NSString stringWithFormat:kBannerUpdateUrlFormat,togaytherServer];
    CurrentUser *user = [userService getCurrentUser];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [_uiService reportProgress:(float)0.05f];
    AFHTTPRequestOperation *operation = [manager POST:url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        if(banner.mainImage!=nil) {
            NSData *imageData = UIImageJPEGRepresentation(banner.mainImage.fullImage, 1.0);
            NSString *fileParam = @"media";
            [formData appendPartWithFileData:imageData
                                        name:fileParam
                                    fileName:@"bannerImg" mimeType:@"image/jpeg"];
        }
        [formData appendPartWithFormData:[user.token dataUsingEncoding:NSUTF8StringEncoding]
                                    name:@"nxtpUserToken"];
        [formData appendPartWithFormData:[([TogaytherService isRetina] ? @"true" : @"false") dataUsingEncoding:NSUTF8StringEncoding]   name:@"highRes"];
        if(banner.key != nil) {
            [formData appendPartWithFormData:[banner.key dataUsingEncoding:NSUTF8StringEncoding]
                                    name:@"bannerKey"];
        }
        if(banner.targetObject!=nil) {
            [formData appendPartWithFormData:[banner.targetObject.key dataUsingEncoding:NSUTF8StringEncoding]
                                    name:@"targetItemKey"];
        }
        if(banner.targetUrl!=nil) {
            [formData appendPartWithFormData:[banner.targetUrl dataUsingEncoding:NSUTF8StringEncoding] name:@"targetUrl"];
        }
        [formData appendPartWithFormData:[[NSString stringWithFormat:@"%f",banner.lat] dataUsingEncoding:NSUTF8StringEncoding]   name:@"lat"];
        [formData appendPartWithFormData:[[NSString stringWithFormat:@"%f",banner.lng] dataUsingEncoding:NSUTF8StringEncoding]
                                    name:@"lng"];
        [formData appendPartWithFormData:[[NSString stringWithFormat:@"%f",[banner.radius doubleValue]]dataUsingEncoding:NSUTF8StringEncoding]
                                    name:@"radius"];
        [formData appendPartWithFormData:[[NSString stringWithFormat:@"%ld",(long)banner.targetDisplayCount] dataUsingEncoding:NSUTF8StringEncoding]
                                    name:@"targetDisplayCount"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        banner.key = [((NSDictionary*)responseObject) objectForKey:@"key"];
        callback(banner);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(failureCallback!=NULL) {
            failureCallback(banner);
        }
    }];
    
    [_uiService reportProgress:(float)0.1f];
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        double progressPct = (double)totalBytesWritten/(double)totalBytesExpectedToWrite;
        [_uiService reportProgress:0.1f+0.5f*(float)progressPct];
    }];
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        double progressPct = (double)totalBytesRead/(double)totalBytesExpectedToRead;
        [_uiService reportProgress:0.6f+0.4f*(float)progressPct];
    }];

}

-(void)listBanners:(ListBannerCompletionBlock)completion onFailure:(ErrorCompletionBlock)errorCompletion {
    NSString *url = [NSString stringWithFormat:kBannersListUrlFormat,togaytherServer];
    CurrentUser *user = [userService getCurrentUser];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:@{@"nxtpUserToken":user.token} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Getting JSON array
        NSArray *jsonBanners = (NSArray*)responseObject;
        
        // Converting to bean array
        NSArray *banners = [jsonService convertJsonBannersToBanners:jsonBanners];
        
        // Calling completion
        completion(banners);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        if(errorCompletion!=nil) {
            NSString *description = error.localizedDescription;
            NSString *reason = error.localizedFailureReason;
            NSString *errorMessage = [NSString stringWithFormat:@"%@ %@", description, reason];
            errorCompletion(error.code, errorMessage);
        }
    }];
    
}
- (void)updateBanner:(PMLBanner*)banner withStatus:(NSString*)status onSuccess:(UpdateBannerCompletionBlock)successCallback onFailure:(ErrorCompletionBlock)failureCallback {
    // Building URL
    NSString *url = [NSString stringWithFormat:kBannerUpdateStatusUrlFormat,togaytherServer];
    CurrentUser *user = [userService getCurrentUser];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:@{@"nxtpUserToken":user.token, @"bannerKey":banner.key,@"status":status} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *json = (NSDictionary*)responseObject;
        
        // Unserializing
        PMLBanner *resultBanner = [jsonService convertJsonBannerToBanner:json];
        
        // Calling back
        successCallback(resultBanner);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(failureCallback!=nil) {
            NSString *description = error.localizedDescription;
            NSString *reason = error.localizedFailureReason;
            NSString *errorMessage = [NSString stringWithFormat:@"%@ %@", description, reason];
            failureCallback(error.code, errorMessage);
        }
    }];
}
-(void)cycleBanner {
    CurrentUser *user = [userService getCurrentUser];
    if(user.token == nil) {
        return;
    }
    if(_modelHolder.banner == nil || _modelHolder.lastBannerDate == nil ||[[NSDate date] timeIntervalSinceDate:_modelHolder.lastBannerDate]>kPMLBannerCycleTimeSeconds) {
        // Building URL
        NSString *url = [NSString stringWithFormat:kBannersCycleUrlFormat,togaytherServer];

        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        
        // Building params map
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        [params setObject:user.token forKey:@"nxtpUserToken"];
        if(_modelHolder.banner.key != nil) {
            [params setObject:_modelHolder.banner.key forKey:@"currentBannerKey"];
        }
        [params setObject:[NSString stringWithFormat:@"%f",_modelHolder.userLocation.coordinate.latitude] forKey:@"lat"];
        [params setObject:[NSString stringWithFormat:@"%f",_modelHolder.userLocation.coordinate.longitude] forKey:@"lng"];
        
        // Webservice call
        [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSDictionary *json = (NSDictionary*)responseObject;
            if(json.allKeys.count >0) {
                // Unserializing
                PMLBanner *newBanner = [jsonService convertJsonBannerToBanner:json];
                _modelHolder.banner = newBanner;
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSString *description = error.localizedDescription;
            NSString *reason = error.localizedFailureReason;
            NSString *errorMessage = [NSString stringWithFormat:@"%@ %@", description, reason];
            NSLog(@"ERROR: %ld: %@",(long)error.code, errorMessage);
        }];
    }
}
- (void)createPlaceAtLatitude:(double)latitude longitude:(double)longitude {
    // Building place
    Place *newPlace = [[Place alloc] init];
    newPlace.lat = latitude;
    newPlace.lng = longitude;
    newPlace.editing = YES;
    newPlace.placeType = [[[TogaytherService settingsService] defaultPlaceType] code];
    
    // Sending request
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyObjectCreated:newPlace];
    });
}
- (void)createBannerAtLatitude:(double)latitude longitude:(double)longitude forObject:(CALObject *)target {
    PMLBanner *banner = [[PMLBanner alloc] init];
    banner.targetObject = target;
    banner.lat = latitude;
    banner.lng = longitude;
    // Sending request
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyObjectCreated:banner];
    });
}
- (CALObject *)objectForKey:(NSString *)key {
    CALObject *object = [overviewCache objectForKey:key];
    if(object == nil) {
        if([key hasPrefix:@"PLAC"]) {
            object = [[Place alloc] init];
        } else if([key hasPrefix:@"CITY"] || [key hasPrefix:@"ADMS"] || [key hasPrefix:@"CNTY"]) {
            object = [[City alloc] init];
        } else if([key hasPrefix:@"USER"]) {
            object = [[User alloc] init];
        } else if([key hasPrefix:@"EVNT"]) {
            object = [[Event alloc] init];
        }
        object.key = key;
        [overviewCache setObject:object forKey:key];
    }
    return object;
}

- (void)updateCalendar:(PMLCalendar *)calendar callback:(UpdateCalendarCompletionBlock)callback errorCallback:(ErrorCompletionBlock)errorCallback {
    dispatch_async(kTopQueue, ^{
        // Building the URL
        
        NSString *url = [[NSString alloc] initWithFormat:kCalendarUpdateUrlFormat,togaytherServer ];
        
        // Getting birth date components
        NSMutableDictionary *paramValues = [[NSMutableDictionary alloc] init];
        CurrentUser *user = userService.getCurrentUser;
        [self setIfDefined:calendar.key     forKey:@"eventId"   fill:paramValues];
        [self setIfDefined:calendar.name    forKey:@"name"      fill:paramValues];
        [self setIfDefined:[NSString stringWithFormat:@"%d",(int)calendar.startHour]   forKey:@"startHour"   fill:paramValues];
        [self setIfDefined:[NSString stringWithFormat:@"%d",(int)calendar.startMinute] forKey:@"startMinute" fill:paramValues];
        [self setIfDefined:[NSString stringWithFormat:@"%d",(int)calendar.endHour]     forKey:@"endHour"     fill:paramValues];
        [self setIfDefined:[NSString stringWithFormat:@"%d",(int)calendar.endMinute]   forKey:@"endMinute"   fill:paramValues];
        
        [self setIfTrue:calendar.isMonday       forKey:@"monday"    fill:paramValues];
        [self setIfTrue:calendar.isTuesday      forKey:@"tuesday"   fill:paramValues];
        [self setIfTrue:calendar.isWednesday    forKey:@"wednesday" fill:paramValues];
        [self setIfTrue:calendar.isThursday     forKey:@"thursday"  fill:paramValues];
        [self setIfTrue:calendar.isFriday       forKey:@"friday"    fill:paramValues];
        [self setIfTrue:calendar.isSaturday     forKey:@"saturday"  fill:paramValues];
        [self setIfTrue:calendar.isSunday       forKey:@"sunday"    fill:paramValues];

        [self setIfDefined:calendar.calendarType    forKey:@"calendarType" fill:paramValues];
        [self setIfDefined:calendar.place.key       forKey:@"placeId" fill:paramValues];
        [self setIfDefined:[NSString stringWithFormat:@"%d",calendar.recurrency.intValue]               forKey:@"monthRecurrency" fill:paramValues];
        [self setIfDefined:user.token               forKey:@"nxtpUserToken" fill:paramValues];
        [self fillDescriptionsFor:calendar inParams:paramValues];
        // Preparing POST request
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager POST:url parameters:paramValues success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"JSON: %@", responseObject);
            NSDictionary *json = (NSDictionary*)responseObject;
            PMLCalendar *newCalendar = [jsonService convertJsonCalendarToCalendar:json forPlace:calendar.place defaultCalendar:calendar];
            callback(newCalendar);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            errorCallback(error.code,@"Cannot update calendar");
        }];
    });
}
- (void)deleteCalendar:(PMLCalendar *)calendar callback:(UpdateCalendarCompletionBlock)callback errorCallback:(ErrorCompletionBlock)errorCallback {
    dispatch_async(kTopQueue, ^{
        // Building the URL
        
        NSString *url = [[NSString alloc] initWithFormat:kCalendarDeleteUrlFormat,togaytherServer ];
        
        // Getting birth date components
        NSMutableDictionary *paramValues = [[NSMutableDictionary alloc] init];
        CurrentUser *user = userService.getCurrentUser;
        [self setIfDefined:user.token               forKey:@"nxtpUserToken" fill:paramValues];
        [self setIfDefined:calendar.key             forKey:@"eventKey" fill:paramValues];
        // Preparing POST request
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager POST:url parameters:paramValues success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"JSON: %@", responseObject);
            callback(calendar);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            errorCallback(error.code,@"Cannot delete calendar");
        }];
    });
}

- (void)updateEvent:(Event *)event callback:(UpdateEventCompletionBlock)callback errorCallback:(ErrorCompletionBlock)errorCallback {
    dispatch_async(kTopQueue, ^{
        // Building the URL
        
        NSString *url = [[NSString alloc] initWithFormat:kCalendarUpdateUrlFormat,togaytherServer ];
        
        // Getting birth date components
        NSMutableDictionary *paramValues = [[NSMutableDictionary alloc] init];
        CurrentUser *user = userService.getCurrentUser;
        [self setIfDefined:event.key     forKey:@"eventId"   fill:paramValues];
        [self setIfDefined:event.name    forKey:@"name"      fill:paramValues];
        
        // Extracting date components
        NSDateFormatter *formatter = [NSDateFormatter new];
        
        [formatter setDateFormat:@"yyyy/MM/dd"];
        NSString *startDay  = [formatter stringFromDate:event.startDate];
        NSString *endDay    = [formatter stringFromDate:event.endDate];
        
        [formatter setDateFormat:@"HH"];
        NSString *startHour = [formatter stringFromDate:event.startDate];
        NSString *endHour   = [formatter stringFromDate:event.endDate];

        [formatter setDateFormat:@"mm"];
        NSString *startMinute   = [formatter stringFromDate:event.startDate];
        NSString *endMinute     = [formatter stringFromDate:event.startDate];
        
        // Filling POST structure
        [self setIfDefined:[NSString stringWithFormat:@"%@",startDay]    forKey:@"startDate"   fill:paramValues];
        [self setIfDefined:[NSString stringWithFormat:@"%@",startHour]   forKey:@"startHour"   fill:paramValues];
        [self setIfDefined:[NSString stringWithFormat:@"%@",startMinute] forKey:@"startMinute" fill:paramValues];
        [self setIfDefined:[NSString stringWithFormat:@"%@",endDay]      forKey:@"endDate"     fill:paramValues];
        [self setIfDefined:[NSString stringWithFormat:@"%@",endHour]     forKey:@"endHour"     fill:paramValues];
        [self setIfDefined:[NSString stringWithFormat:@"%@",endMinute]   forKey:@"endMinute"   fill:paramValues];

        
        [self setIfDefined:event.place.key       forKey:@"placeId" fill:paramValues];
        [self setIfDefined:user.token            forKey:@"nxtpUserToken" fill:paramValues];
        
        // Filling descriptions
        [self fillDescriptionsFor:event inParams:paramValues];
        
        // Preparing POST request
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager POST:url parameters:paramValues success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"JSON: %@", responseObject);
            NSDictionary *json = (NSDictionary*)responseObject;
            Event *newEvent = [jsonService convertJsonEventToEvent:json defaultEvent:event];
            callback(newEvent);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            errorCallback(error.code,@"Cannot update event");
        }];
    });

}
@end
