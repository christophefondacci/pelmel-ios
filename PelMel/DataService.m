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

#define kPlaceListUrlFormat @"%@/mapPlaces.action?lat=%f&lng=%f&nxtpUserToken=%@&highRes=%@&searchLat=%f&searchLng=%f"
#define kEventListUrlFormat @"%@/mobileEvents.action?lat=%f&lng=%f&nxtpUserToken=%@&highRes=%@"
#define kOverviewDataUrlFormat @"%@/mobileOverview?id=%@&nxtpUserToken=%@&highRes=%@&lat=%f&lng=%f"
#define kLikeUrlFormat @"%@/mobileIlike?id=%@&nxtpUserToken=%@&type=%@"
#define kPlaceUpdateUrlFormat @"%@/mobileUpdatePlace"
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
@synthesize cacheService = cacheService;
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
    [self fetchPlacesAtLatitude:latitude longitude:longitude for:parent searchTerm:searchTerm radius:_currentRadius];
}

-(void)fetchPlacesAtLatitude:(double)latitude longitude:(double)longitude for:(CALObject *)parent searchTerm:(NSString *)searchTerm radius:(double)radius {

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
            NSString *encodedSearchTerm = [DataService urlencode:searchTerm];
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
                        [self placesDataFetched:data];
                        break;
                    case EVENTS_LISTVIEW:
                        [self eventsDataFetched:data];
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
                [self doCallback];
            } else {
                [self fetchPlacesFor:parent searchTerm:searchTerm];
            }
            break;
        case EVENTS_LISTVIEW:
            if(_modelHolder.events.count>0) {
                [self doCallback];
            } else {
                [self fetchPlacesFor:parent searchTerm:searchTerm];
            }
            break;
    }
}
- (void)placesDataFetched:(NSData *)responseData {
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
    
    // Preparing the no image thumb (default for every place at first)
    for(NSDictionary *jsonPlace in jsonPlaces) {
        Place *place = [jsonService convertFullJsonPlaceToPlace:jsonPlace];
        // Appending to the document list
        [docs addObject:place];
    }
    
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
    
    // Parsing localized city
    NSDictionary *jsonCity = [json objectForKey:@"localizedCity"];
    City *localizedCity = nil;
    if(jsonCity != nil && jsonCity!=(id)[NSNull null]) {
        localizedCity = [jsonService convertJsonCityToCity:jsonCity];
    }
    
    // Assigning to model holder for all-view synch
    [_modelHolder setPlaces:docs];
    [[_modelHolder allPlaces] addObjectsFromArray:docs];
    [_modelHolder setCities:cities];
    [_modelHolder setActivities:activities];
    [_modelHolder setUsers:users];
    [_modelHolder setLocalizedCity:localizedCity];
    
    // Callback on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [self doCallback];
    });
    
}

- (void)eventsDataFetched:(NSData *)responseData {
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
    NSMutableArray *docs = [[NSMutableArray alloc] initWithCapacity:[jsonEvents count]];
    NSDictionary *obj;
    // Preparing the no image thumb (default for every place at first)
    for(obj in jsonEvents) {
        NSString *itemKey = [obj objectForKey:@"key"];
        // Building JSON event
        Event *data = [cacheService getObject:itemKey];
        if(data == nil) {
            data = [[Event alloc] init];
            [cacheService putObject:data forKey:itemKey];
        }
        [jsonService fillEvent:data fromJson:obj];
        
        // Appending to the document list
        [docs addObject:data];
    }
    // Assigning to model holder for all-view synch
    [_modelHolder setEvents:docs];
    // Callback on main thread
    [self performSelectorOnMainThread:@selector(doCallback)
                           withObject:nil waitUntilDone:NO];
    // Downloading image if needed
//    [imageService getThumbsMulti:_modelHolder.events mainImageOnly:YES callback:_imageCallback];
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

-(void)fetchOverviewData:(CALObject *)object {
    [self startOp:@""];
    
    if(!object.hasOverviewData && object.key != nil) {
        // Loading object's full data
        dispatch_async(kTopQueue, ^{
            CurrentUser *user = userService.getCurrentUser;
            BOOL isRetina = [TogaytherService isRetina];
            NSString *url = [[NSString alloc] initWithFormat:kOverviewDataUrlFormat,togaytherServer,object.key,user.token, (isRetina ? @"true" : @"false"),location.coordinate.latitude, location.coordinate.longitude];
            NSLog(@"Overview data : calling URL %@",url);
            NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
            if(data!=nil) {
                if([object isKindOfClass:[Place class]]) {
                    [self placeOverviewDataFetched:data object:object];
                } else if([object isKindOfClass:[User class]]) {
                    [self userOverviewDataFetched:data object:object];
                } else if([object isKindOfClass:[Event class]]) {
                    [self eventOverviewDataFetched:data object:object];
                }
            } else {
                [self performSelectorOnMainThread:@selector(notifyConnectionLost) withObject:nil waitUntilDone:NO];
            }
            // Clearing cache action
            [overviewCache removeObjectForKey:object.key];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self notifyOverviewDataAvailable:object];
        });
    }
}
- (void)eventOverviewDataFetched:(NSData*)data object:(CALObject*)object {
    Event *event = (Event*)object;
    NSError* error;
    if(data == nil) {
        NSLog(@"eventOverviewDataFetched: JSON data is null, aborting");
        return;
    }
    NSDictionary *json = [NSJSONSerialization
                          JSONObjectWithData:data //1
                          options:kNilOptions
                          error:&error];
    
    // Checking any login error
    NSString *loginFailed = [json objectForKey:@"loginFailed"];
    if(loginFailed != nil) {
        [self notifyLoginFailed];
        return;
    }
    
    // Getting unread message count
    NSNumber *unreadMsgCount = [json objectForKey:@"unreadMsgCount"];
    [messageService setUnreadMessageCount:[unreadMsgCount intValue]];
    
    // Building event from JSON
    [jsonService fillEvent:event fromJson:json];
    NSString *description = [json objectForKey:@"description"];
    [event setMiniDesc:description];
    
    // Likes management
    NSNumber *likeCount     = [json objectForKey:@"likes"];
    NSArray *jsonLikeUsers  = [json objectForKey:@"likeUsers"];
    [event setLikeCount:[likeCount integerValue]];
    [event.likers removeAllObjects];
    for(NSDictionary *jsonUser in jsonLikeUsers) {
        // Building User bean (liked user) from JSON
        User *likedUser = [jsonService convertJsonUserToUser:jsonUser];
        
        // Adding this liked user
        [event.likers addObject:likedUser];
    }

    // Flagging our bean as having overview data
    [event setHasOverviewData:YES];
    
    // Calling our callback
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyOverviewDataAvailable:event];
    });
}
- (void)userOverviewDataFetched:(NSData*)data object:(CALObject*)object {
    NSError* error;
    if(data == nil) {
        NSLog(@"userOverviewDataFetched: JSON data is null, aborting");
        return;
    }
    NSDictionary *json = [NSJSONSerialization
                          JSONObjectWithData:data //1
                          options:kNilOptions
                          error:&error];
    
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

- (void)placeOverviewDataFetched:(NSData*)data object:(CALObject*)object {
//    Place *place = (Place*)object;
    NSError* error;
    if(data == nil) {
        NSLog(@"placesOverviewDataFetched: JSON data is null, aborting");
        return;
    }
    NSDictionary *json = [NSJSONSerialization
                          JSONObjectWithData:data //1
                          options:kNilOptions
                          error:&error];
    
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
            if([callback respondsToSelector:@selector(didLoadData:)]) {
                [callback didLoadData:_modelHolder];
            }
        }
    }
}
- (void)unregisterDataListener:(id<PMLDataListener>)callback {
    [dataListeners removeObject:callback];
}
-(void)startOp:(NSString*)msg {
    // Notifying that we are starting a data op
    for(NSObject<PMLDataListener> *callback in dataListeners) {
        
        // Only notifying if supported
        if([callback respondsToSelector:@selector(didStartDataOperation:)]) {
            [callback didStartDataOperation:@""];
        }
    }
}


- (void)notifyOverviewDataAvailable:(CALObject*)object {
    for(NSObject<PMLDataListener> *callback in dataListeners) {
        if([callback respondsToSelector:@selector(didLoadOverviewData:)]) {
            [callback didLoadOverviewData:object];
        }
    }
}
-(void)notifyLoginFailed {
    for(NSObject<PMLDataListener> *callback in dataListeners) {
        if([callback respondsToSelector:@selector(loginFailed)]) {
            [callback loginFailed];
        }
    }
}
-(void)notifyLike:(CALObject*)object likes:(int)likes dislikes:(int)dislikes liked:(BOOL)liked {
    for(NSObject<PMLDataListener> *callback in dataListeners) {
        if([callback respondsToSelector:@selector(didLike:newLikes:newDislikes:liked:)]) {
            [callback didLike:object newLikes:likes newDislikes:dislikes liked:liked];
        }
    }
}
- (void) doCallback {
    
    // Iterating over all listeners
    for(NSObject<PMLDataListener> *callback in dataListeners) {
        
        // Optional callback method
        if([callback respondsToSelector:@selector(didLoadData:)]) {
            [callback didLoadData:_modelHolder];
        }
    }
}
-(void)notifyWillUpdatePlace:(Place*)place {
    for(NSObject<PMLDataListener> *callback in dataListeners) {
        if([callback respondsToSelector:@selector(willUpdatePlace:)]) {
            [callback willUpdatePlace:place];
        }
    }
}
-(void)notifyPlaceUpdated:(Place*)place {
    for(NSObject<PMLDataListener> *callback in dataListeners) {
        if([callback respondsToSelector:@selector(didUpdatePlace:)]) {
            [callback didUpdatePlace:place];
        }
    }
}
-(void)notifyObjectCreated:(CALObject*)object {
    for(NSObject<PMLDataListener> *callback in dataListeners) {
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
    for(NSObject<PMLDataListener> *callback in dataListeners) {
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
        

        [self setIfDefined:place.miniDesc   forKey:@"description" fill:paramValues];
        if(place.miniDesc) {
            NSString *key = place.miniDescKey == nil ? @"" : place.miniDescKey;
            [paramValues setObject:key forKey:@"descriptionKey"];
        }
        if(place.miniDescLang==nil) {
            place.miniDescLang= [TogaytherService getLanguageIso6391Code];
        }
        [self setIfDefined:place.miniDescLang forKey:@"descriptionLanguageCode" fill:paramValues];
        
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
            });
            

            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
        
    });
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
        [self setIfDefined:[NSString stringWithFormat:@"%d",calendar.startHour]   forKey:@"startHour"   fill:paramValues];
        [self setIfDefined:[NSString stringWithFormat:@"%d",calendar.startMinute] forKey:@"startMinute" fill:paramValues];
        [self setIfDefined:[NSString stringWithFormat:@"%d",calendar.endHour]     forKey:@"endHour"     fill:paramValues];
        [self setIfDefined:[NSString stringWithFormat:@"%d",calendar.endMinute]   forKey:@"endMinute"   fill:paramValues];
        
        [self setIfTrue:calendar.isMonday       forKey:@"monday"    fill:paramValues];
        [self setIfTrue:calendar.isTuesday      forKey:@"tuesday"   fill:paramValues];
        [self setIfTrue:calendar.isWednesday    forKey:@"wednesday" fill:paramValues];
        [self setIfTrue:calendar.isThursday     forKey:@"thursday"  fill:paramValues];
        [self setIfTrue:calendar.isFriday       forKey:@"friday"    fill:paramValues];
        [self setIfTrue:calendar.isSaturday     forKey:@"saturday"  fill:paramValues];
        [self setIfTrue:calendar.isSunday       forKey:@"sunday"    fill:paramValues];

        [self setIfDefined:calendar.calendarType    forKey:@"calendarType" fill:paramValues];
        [self setIfDefined:calendar.place.key       forKey:@"placeId" fill:paramValues];
        [self setIfDefined:@"0"               forKey:@"monthRecurrency" fill:paramValues];
        [self setIfDefined:user.token               forKey:@"nxtpUserToken" fill:paramValues];
        
        // Preparing POST request
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager POST:url parameters:paramValues success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"JSON: %@", responseObject);
            NSDictionary *json = (NSDictionary*)responseObject;
            PMLCalendar *newCalendar = [jsonService convertJsonCalendarToCalendar:json defaultCalendar:calendar];
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
@end
