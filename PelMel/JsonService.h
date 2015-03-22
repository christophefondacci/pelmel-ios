//
//  JsonService.h
//  togayther
//
//  Created by Christophe Fondacci on 13/02/13.
//  Copyright (c) 2013 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Place.h"
#import "ImageService.h"
#import "City.h"
#import "Event.h"
#import "User.h"
#import "Activity.h"
#import "Special.h"

@interface JsonService : NSObject

@property (strong,nonatomic) ImageService *imageService;
@property (strong,nonatomic) NSCache *objectCache;

-(Place*)convertJsonPlaceToPlace:(NSDictionary*)jsonPlace;
/**
 * Converts the JSON structure to a Place object.
 * The default place will be used when provided if place not resolved in cache.
 * This allows to re-use a newly created object even though its key is fresh since we
 * already have an instance for it and we don't want to have 2 versions of a same object
 */
-(Place*)convertJsonOverviewPlaceToPlace:(NSDictionary*)json  defaultPlace:(Place*)place;
-(NSArray*)convertJsonEventsToEvents:(NSArray*)jsonEvents;
-(Event*)convertJsonEventToEvent:(NSDictionary*)obj defaultEvent:(Event*)defaultEvent;
-(City*)convertJsonCityToCity:(NSDictionary*)jsonCity ;
-(Place*)convertFullJsonPlaceToPlace:(NSDictionary*)obj ;
-(Activity*)convertJsonActivityToActivity:(NSDictionary*)activity;
-(NSArray*)convertJsonActivitiesToActivities:(NSArray*)activities;
/**
 * Fills the user with information extracted from user-JSON information
 */
- (void)fillUser:(User*)user fromJson:(NSDictionary*)jsonLoginInfo;
/**
 * Converts a JSON light user information to a User bean
 */
- (User*)convertJsonUserToUser:(NSDictionary*)jsonUser;
/**
 * Converts a JSON Overview user information to a User bean. If a bean is not yet
 * in cache (or has been excluded), the defaultUser bean will be used.
 */
- (User*)convertJsonOverviewUserToUser:(NSDictionary*)json  defaultUser:(User*)defaultUser;
/**
 * Helper method that batch converts an array of JsonLightUser
 */
- (NSArray *)convertJsonUsersToUsers:(NSArray *)jsonUsers;
/**
 * Converts a JsonHour bean (recurring event, opening hours) to a PMLCalendar object
 * @param jsonHour a dictionary representing JSON contents
 * @param calendar the default calendar bean to use when no entry exists in cache
 * @return the corresponding model as a PMLCalendar bean
 */
- (PMLCalendar*)convertJsonCalendarToCalendar:(NSDictionary*)jsonHour defaultCalendar:(PMLCalendar*)calendar;

/**
 * Converts the given special information to an event, using cache to seamlessly 
 * reuse already converted instances.
 * This method may return a nil object when no event could be generated for the given
 * special so callers should always check the result for nullity
 * @param special the Special instance to convert, generally coming from a nearby search
 * @param place the place to which the event needs to be associated (the current parent of the special)
 */
- (Event*)convertSpecial:(Special*)special toEventForPlace:(Place*)place;
/**
 * Retrieves an object instance from its key
 */
- (CALObject*)objectForKey:(NSString*)key;
@end
