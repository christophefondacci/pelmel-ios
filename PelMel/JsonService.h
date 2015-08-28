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
#import "PMLCalendar.h"
#import "PMLBanner.h"
#import "CurrentUser.h"
#import "PMLDeal.h"

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
-(PMLBanner*)convertJsonBannerToBanner:(NSDictionary*)jsonBanner;
-(NSArray*)convertJsonBannersToBanners:(NSArray*)jsonBanners;
/**
 * Fills information regarding private network definition from the given dictionary into the given user.
 * @param privateNetworkContainer a dictionary with pendingApprovals, pendingRequests and pendingNetworkUsers to extract data from 
 * @param currentUser the CurrentUser to fill with private network definitions
 */
-(void)fillPrivateNetworkInfo:(NSDictionary*)privateNetworkContainer inUser:(CurrentUser*)currentUser;
/**
 * Converts a JsonHour bean (recurring event, opening hours) to a PMLCalendar object
 * @param jsonHour a dictionary representing JSON contents
 * @param place the place defining this calendar
 * @param calendar the default calendar bean to use when no entry exists in cache
 * @return the corresponding model as a PMLCalendar bean
 */
- (PMLCalendar*)convertJsonCalendarToCalendar:(NSDictionary*)jsonHour forPlace:(Place*)place defaultCalendar:(PMLCalendar*)calendar;
/**
 * Converts a JsonDeal bean to a Deal model object
 * @param jsonDeal the JSON map structure
 * @param place the place for this deal (/!\ place is not yet extracted from JSON)
 * @return the corresponding Deal object (refreshed from cache or new instance)
 */
-(PMLDeal*)convertJsonDealToDeal:(NSDictionary*)jsonDeal forPlace:(Place*)place;
/**
 * Retrieves an object instance from its key
 */
- (CALObject*)objectForKey:(NSString*)key;
@end
