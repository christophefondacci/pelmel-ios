//
//  DataService.h
//  nativeTest
//
//  Created by Christophe Fondacci on 25/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ModelHolder.h"
#import "PlaceType.h"
#import "CALObject.h"
#import "ImageService.h"
#import "UserService.h"
#import "MessageService.h"
#import "JsonService.h"
#import "SizedTTLCacheService.h"

@class AFNetworkReachabilityManager;

typedef enum {
    PMLReportTypeAbuse = 1,
    PMLReportTypeClosed = 2,
    PMLReportTypeLocation = 3,
    PMLReportTypeNotGay = 4,
} PMLReportType;

@protocol PMLDataListener
@optional

// Informs that a data operation has just started
- (void)didStartDataOperation:(NSString*)msg;

// Informs listeners that data is about to be refreshed
-(void)willLoadData;

// Method called as soon as the data is ready
-(void)didLoadData:(ModelHolder*)modelHolder;

// Method called after the device has been located
-(void)didLocalizeDevice:(CLLocation*)location;

// Login failed
-(void)loginFailed;

// Overview data has been fetched and is available
// /!\ This method is called on the MAIN QUEUE
-(void)didLoadOverviewData:(CALObject*)object;
-(void)didLooseConnection;

// A like has been successfully done
-(void)didLike:(CALObject*)likedObject newLikes:(int)likeCount newDislikes:(int)dislikesCount liked:(BOOL)liked;

// About to update a place
-(void)willUpdatePlace:(Place*)place;
// Place was updated successfully
-(void)didUpdatePlace:(Place*)place;

-(void)didFailPlaceUpdate:(NSError*)error;

// A new object has just been created
-(void)objectCreated:(CALObject*)object;

//Report management
-(void)willSendReportFor:(CALObject*)object;
-(void)didSendReportFor:(CALObject*)object;
-(void)didFailSendReportFor:(CALObject*)object reason:(NSString*)reason;

@end

typedef void (^OverviewCompletionBlock)(CALObject*overviewObject);

typedef void (^UpdatePlaceCompletionBlock)(Place *place );
typedef void (^UpdateCalendarCompletionBlock)(PMLCalendar *calendar );
typedef void (^UpdateEventCompletionBlock)(Event *calendar );
typedef void (^ErrorCompletionBlock)(NSInteger errorCode,NSString *errorMessage );

@interface DataService : NSObject <CLLocationManagerDelegate>

@property (strong, nonatomic) UserService *userService;
@property (strong, nonatomic) ImageService *imageService;
@property (strong, nonatomic) MessageService *messageService;
@property (strong, nonatomic) JsonService *jsonService;
@property (strong, nonatomic) id<CacheService> cacheService;
@property (strong, nonatomic) AFNetworkReachabilityManager *reachabilityManager;
@property (strong) ModelHolder *modelHolder;
@property (nonatomic) double currentRadius;

/**
 * Registers a listener that will be notified of data changes.
 * Registering a listener will fire the 'dataReady' callback method
 * if there is already some data available.
 */
- (void)registerDataListener:(id<PMLDataListener>)callback;

/**
 * Unregisters the given listener from data events notifications
 */
- (void)unregisterDataListener:(id<PMLDataListener>)callback;

/*
 * Refreshes the current location and fetches new points from server,
 * notifying the caller through the passed callback.
 * Those methods will always fetch data from server. Please consider calling
 * getNearbyPlaces instead as it will transparently use a cached version.
 */
- (void)fetchNearbyPlaces;
- (void)fetchPlacesFor:(CALObject*)parent;
- (void)fetchPlacesFor:(CALObject*)parent searchTerm:(NSString*)searchTerm;
- (void)fetchPlacesAtLatitude:(double)latitude longitude:(double)longitude for:(CALObject*)parent searchTerm:(NSString*)searchTerm;

/**
 * Gets places near current position (or in a parent city if specified), optionally
 * filtered by a search term. Those methods use caching and may return a cached result.
 * Calling one of these method may result in several callbacks being made: 1st for the cache
 * result when available, and if a server call is made (when data is too old or location changed)
 * a second with updated information
 */
-(void)getNearbyPlaces;
-(void)getNearbyPlacesFor:(CALObject*)parent;
-(void)getNearbyPlacesFor:(CALObject*)parent searchTerm:(NSString*)searchTerm;

/**
 * Get full information on this place from the server
 */
-(void)fetchOverviewData:(CALObject*)object;
/**
 * Gets full information on this place. Information might come from cache or server
 */
-(void)getOverviewData:(CALObject*)object;
/**
 * Gets the object referenced by the given key. If object does not exist it will be
 * loaded, if it is in cache, the cached object will be returned. No listeners will be triggered
 */
-(void)getObject:(NSString*)key callback:(OverviewCompletionBlock)callback;

// Like management
-(void)like:(CALObject*)object callback:(LikeCompletionBlock)callback;
-(void)dislike:(CALObject*)object callback:(LikeCompletionBlock)callback;
-(void)genericLike:(CALObject*)object like:(BOOL)like callback:(LikeCompletionBlock)callback;

/**
 * Sends a report on the given object
 */
-(void)sendReportFor:(CALObject*)object reportType:(PMLReportType)reportType;

// Place update
-(void)updatePlace:(Place*)place callback:(UpdatePlaceCompletionBlock)callback;

// Place creation
- (void)createPlaceAtLatitude:(double)latitude longitude:(double)longitude;

-(void)cancelRunningProcesses;

/**
 * Retrieves an already loaded object matching this key or creates a new empty
 * object for this key which could then be loaded
 */
-(CALObject*)objectForKey:(NSString*)key;

/**
 * Save calendar to the backend server
 */
-(void)updateCalendar:(PMLCalendar*)calendar callback:(UpdateCalendarCompletionBlock)callback errorCallback:(ErrorCompletionBlock)errorCallback;

- (void)deleteCalendar:(PMLCalendar *)calendar callback:(UpdateCalendarCompletionBlock)callback errorCallback:(ErrorCompletionBlock)errorCallback;

-(void)updateEvent:(Event*)event callback:(UpdateEventCompletionBlock)callback errorCallback:(ErrorCompletionBlock)errorCallback;
@end


