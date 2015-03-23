//
//  PMLCalendar.h
//  PelMel
//
//  Created by Christophe Fondacci on 17/02/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Event.h"

@class Place;

@interface PMLCalendar : Event

@property (nonatomic,retain) NSString *calendarType;
@property (nonatomic) NSInteger startHour;
@property (nonatomic) NSInteger startMinute;
@property (nonatomic) NSInteger endHour;
@property (nonatomic) NSInteger endMinute;

@property (nonatomic) BOOL isMonday;
@property (nonatomic) BOOL isTuesday;
@property (nonatomic) BOOL isWednesday;
@property (nonatomic) BOOL isThursday;
@property (nonatomic) BOOL isFriday;
@property (nonatomic) BOOL isSaturday;
@property (nonatomic) BOOL isSunday;
@property (nonatomic) NSNumber *recurrency;

/**
 * Checks enablement passing a day index (0 = sunday)
 */
- (BOOL)isEnabledFor:(NSInteger)index;
/**
 * Toggles enablement for day index (0 = sunday) and returns the new state for this day
 */
- (BOOL)toggleEnablementFor:(NSInteger)index;

/**
 * Creates a copy of the given calendar
 */
-(instancetype)initWithCalendar:(PMLCalendar*)calendar;

/**
 * Copies all information from given calendar into current instance
 */
-(void)refreshFrom:(PMLCalendar*)calendar;
@end
