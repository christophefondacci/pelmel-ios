//
//  SettingsService.h
//  PelMel
//
//  Created by Christophe Fondacci on 12/02/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlaceType.h"
#import "Place.h"
@class ConversionService;

@class CALObject;

@protocol SettingsListener <NSObject>

/**
 * This callback method is called when the filter of the given place type
 * is modified
 */
-(void)filtersChanged;

@end


typedef enum {
    PMLFilterOpeningHours, PMLFilterHappyHours, PMLFilterEvents, PMLFilterCheckins
} FilterCode;

@interface SettingsService : NSObject

// A quick access to the information telling that everything is active
@property (nonatomic) BOOL allFiltersActive;
@property (nonatomic,retain) ConversionService *conversionService;
@property (nonatomic) BOOL leftHandedMode;

/**
 * Provides a list of defined PlaceType objects
 */
- (NSArray*)listPlaceTypes;

/**
 * Provides the place type registered under the provided place type code
 */
- (PlaceType*)getPlaceType:(NSString*)placeTypeCode;
-(PlaceType*)defaultPlaceType;
/**
 * Stores the value of the "filter" state of the given place type
 * for memorization
 */
-(void)storePlaceTypeFilter:(PlaceType*)placeType ;

/**
 * Indicates whether or not the place should be displayed, based on current settings
 */
-(BOOL)isVisible:(CALObject*)object;
/**
 * Provides the list of defined tags
 */
- (NSArray*)listTags;

/**
 * Adds the provided object as a listener to settings modifications
 */
-(void)addSettingsListener:(NSObject<SettingsListener>*)listener;

/**
 * Removed the provided argument from listeners of settings modifications
 */
-(void)removeSettingsListener:(NSObject<SettingsListener>*)listener;

/**
 * Informs whether or not this filter is enabled
 */
- (BOOL) isFilterEnabled:(FilterCode)filter;

/**
 * Sets the given filter enablement
 */
- (void)enableFilter:(FilterCode)setting enablement:(BOOL)enabled;
/** 
 * Returns whether checkin is allowed for the given place
 */
-(BOOL)isCheckinEnabledFor:(Place*)place;
@end
