//
//  ConversionService.h
//  PelMel
//
//  Created by Christophe Fondacci on 05/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Place.h"
#import "Special.h"
#import "Event.h"
#import <CoreLocation/CoreLocation.h>

typedef enum {
    CURRENT, SOON, PAST
} SpecialMode;

typedef void(^AddressClosure)(NSString*address);

@interface ConversionService : NSObject

- (int) getFeetFromCm:(double)cm;
- (int) getInchesFromCm:(double)cm;
- (double) getCmFromFeet:(int)feet inches:(int)inches;
-(NSString*)getHeightLabel:(double)measureInCm imperial:(BOOL)isImperial;

-(NSString*)getWeightLabel:(float)weightInKg imperial:(BOOL)isImperial;
/**
 * Computes the distance from current user location to the given object.
 * The result is a distance string to be used in UILabel
 */
-(NSString*)distanceTo:(CALObject*)object;
- (CLLocationDistance)numericDistanceTo:(CALObject*)object;
/**
 * Provides a localized (miles / km) compact distance string (meters, kilometers, feet, etc.)
 * of the given miles distance. The method will use current locale to determine whether
 * the results should be metric or imperial.
 */
-(NSString*)distanceStringForMeters:(CLLocationDistance)distance;
/**
 * Computes the address at the location of the given object and invokes the block passing
 * the resolved and formatted address.
 */
-(void)geocodeAddressFor:(CALObject*)object completion:(AddressClosure)closure;

/**
 * Converts the special object into a real-time information about whether it is past, present or future
 */
-(SpecialMode)specialModeFor:(Special*)special;
-(Special*)specialFor:(CALObject*)place ofType:(NSString *)specialType;

/**
 * Converts a calendar definition into a human readable string
 * @param calendar the PMLCalendar to convert
 * @return the human-readable string corresponding to the calendar definition
 */
-(NSString*)stringFromCalendar:(PMLCalendar*)calendar;
-(NSString*)stringForHours:(NSInteger)hours minutes:(NSInteger)minutes;
/**
 * Hashes an array of PMLCalendar instances by their corresponding calendar type
 * @param object the object to get hours from
 * @return a dictionary of all PMLCalendar instances hashed by their calendar type
 */
-(NSDictionary*)hashHoursByType:(CALObject*)object;

/**
 * Generates the start/end date label for this event
 * @param event the Event to generate a date label for
 * @param start set to YES for start date label, or NO for end date label
 * @return the corresponding date label
 */
-(NSString *)eventDateLabel:(Event*)event isStart:(BOOL)start;
-(NSString *)stringForEventDate:(NSDate*)date timeOnly:(BOOL)timeOnly ;
@end
