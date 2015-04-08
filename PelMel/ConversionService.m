//
//  ConversionService.m
//  nativeTest
//
//  Created by Christophe Fondacci on 05/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "ConversionService.h"
#import <CoreLocation/CoreLocation.h>
#import "TogaytherService.h"

@implementation ConversionService {
    CLGeocoder *_geocoder;
    NSDateFormatter *_eventDateFormatter;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _geocoder = [[CLGeocoder alloc] init];
        _eventDateFormatter = [[NSDateFormatter alloc] init];
        NSString *formatString = [NSDateFormatter dateFormatFromTemplate:@"EdMMMhmma" options:0
                                                                  locale:[NSLocale currentLocale]];

        [_eventDateFormatter setDateFormat:formatString];
    }
    return self;
}

-(int)getFeetFromCm:(double)cm {
    double inches = cm/2.54f;
    
    return (int) (inches / 12);
}
-(int)getInchesFromCm:(double)cm {
    double inches = cm/2.54f;
    return ((int)inches % 12);
}
- (double)getCmFromFeet:(int)feets inches:(int)inches {
    double cm = ((double)feets)*30.48f+((double)inches)*2.54f;
    return cm;
}
- (NSString *)getHeightLabel:(double)measureInCm imperial:(BOOL)isImperial {
    if(isImperial) {
        int feet = [self getFeetFromCm:measureInCm];
        int inches = [self getInchesFromCm:measureInCm];
        return [[NSString alloc] initWithFormat:@"%d ' %d ''",feet,inches];
    } else {
        return [[NSString alloc] initWithFormat:@"%d cm",(int)measureInCm];
    }
}
- (NSString *)getWeightLabel:(float)weightInKg imperial:(BOOL)isImperial {
    if(isImperial) {
        float pounds = weightInKg / 0.45359237;
        return [[NSString alloc]initWithFormat:@"%d lb",(int)pounds];
    } else {
        return [[NSString alloc] initWithFormat:@"%d kg",(int)weightInKg];
    }
}
- (CLLocationDistance)numericDistanceTo:(CALObject*)object {
    CLLocation *objectLocation = [[CLLocation alloc] initWithLatitude:object.lat longitude:object.lng];
    CLLocationDistance distance = [[[TogaytherService userService] currentLocation] distanceFromLocation:objectLocation];
    return distance;

}
- (NSString *)distanceTo:(CALObject *)p {
    CLLocation *placeLoc = [[CLLocation alloc] initWithLatitude:p.lat longitude:p.lng];
    CLLocation *userLoc = TogaytherService.userService.currentLocation;
    if(userLoc != nil) {
        CLLocationDistance distance = [placeLoc distanceFromLocation:userLoc];
        return [self distanceStringForMeters:distance];

    } else {
        return nil;
    }
}
-(NSString*)distanceStringForMeters:(CLLocationDistance)distance {
    NSLocale *locale = [NSLocale currentLocale];
    BOOL isMetric = [[locale objectForKey:NSLocaleUsesMetricSystem] boolValue];
    
    NSString *currentTemplate;
    double currentValue = 0;
    if(isMetric) {
        if(distance > 1000) {
            currentTemplate = @"distance.template.kilometers";
            currentValue = distance/100;
            currentValue = (double)(int)currentValue;
            currentValue = currentValue/10;
        } else {
            currentTemplate =@"distance.template.meters";
            currentValue = (double)(int)distance;
        }
    } else {
        double miles = distance / 1609.34;
        if(miles < 0.5) {
            double feet = distance / 0.3048;
            currentTemplate = @"distance.template.feet";
            currentValue = (double)(int)feet;
        } else {
            currentTemplate = @"distance.template.miles";
            currentValue = (double)(int)(miles*10.0);
            currentValue = round(currentValue);
            currentValue = currentValue / 10.0;
        }
    }
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    NSString *formattedNumberString = [numberFormatter stringFromNumber:[NSNumber numberWithDouble:currentValue]];
    return [NSString stringWithFormat:NSLocalizedString(currentTemplate,@"template"),formattedNumberString];
}
-(void)reverseGeocodeAddressFor:(CALObject *)object completion:(AddressClosure)closure {
    // Geocoding
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:object.lat longitude:object.lng];
    [_geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
        if(error == nil && placemarks.count>0) {
            // Getting first result
            CLPlacemark *placemark = placemarks[0];
            NSString *address= [self addressFromPlacemark:placemark];
            
            // Calling back
            if(closure != nil) {
                closure(address);
            }
        }
    }];
}
- (void)geocodeAddress:(NSString*)address intoObject:(Place *)place completion:(LatLngClosure)closure {
    // Adding cancel action that reverts address and latitude / longitude
//    PMLPopupEditor *editor = [PMLPopupEditor editorFor:place on:[[[TogaytherService uiService] menuManagerController] rootViewController]];
//    NSString *oldAddress = place.address;
//    double oldLat = place.lat;
//    double oldLng = place.lng;
//    [[editor pendingCancelActions] addObject:^{
//        place.address = oldAddress;
//        place.lat = oldLat;
//        place.lng = oldLng;
//    }];
    

    
    _geocoder = [[CLGeocoder alloc] init];
    [_geocoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error) {
        if(error == nil && placemarks.count>0) {
            // Computing current place location to compare distance
            CLLocation *currentPlaceLocation = [[CLLocation alloc] initWithLatitude:place.lat longitude:place.lng];
            for(CLPlacemark *placemark in placemarks) {
                place.address = [[TogaytherService getConversionService] addressFromPlacemark:placemark];
                // If address is more than 100 meters from current place, we relocate place
                if([placemark.location distanceFromLocation:currentPlaceLocation]>100) {
                    place.lat = placemark.location.coordinate.latitude;
                    place.lng = placemark.location.coordinate.longitude;
                    [[[[TogaytherService uiService] menuManagerController] rootViewController].mapView setCenterCoordinate:placemark.location.coordinate];

                    [[TogaytherService uiService] alertWithTitle:@"action.edit.address.geocodingMovedPlaceTitle" text:@"action.edit.address.geocodingMovedPlace"];
                }
                break;
            }
            closure(place,place.lat,place.lng,YES);
        } else {
            if([address stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length>5) {
                place.address = address;
            }
            [[TogaytherService uiService] alertWithTitle:@"action.edit.address.geocodingFailedTitle" text:@"action.edit.address.geocodingFailed"];
            
            // Error callback
            closure(place,0,0,NO);
        }
    }];
}
-(NSString*)addressFromPlacemark:(CLPlacemark*)placemark {
    NSArray *addressLines = [placemark.addressDictionary objectForKey:@"FormattedAddressLines"];
    NSMutableString *address = [[NSMutableString alloc ] init];
    NSString *separator = @"";
    for(NSString *addressLine in addressLines) {
        [address appendString:separator];
        [address appendString:addressLine];
        separator = @", ";
    }
    return address;
}
/**
 * Informs whether the special is currently valid or not
 */
-(PMLEventState) eventStartStateFor:(Event*)special {
    NSDate *date = [NSDate date];
    if(([special.startDate compare:special.endDate] == NSOrderedDescending ||[date compare:special.startDate] == NSOrderedDescending)) {
        if([date compare:special.endDate] == NSOrderedAscending) {
            return PMLEventStateCurrent;
        } else {
            return PMLEventStatePast;
        }
    } else {
        return PMLEventStateSoon;
    }
}
-(BOOL)calendarType:(NSString*)calendarType isCurrentFor:(Place*)place noDataResult:(BOOL)defaultResult {
    BOOL hasData = NO;
    for(PMLCalendar *calendar in place.hours) {
        if([calendar.calendarType isEqualToString:calendarType]) {
            hasData = YES;
            // Get the current mode PAST, CURRENT or SOON
            PMLEventState mode = [self eventStartStateFor:calendar];
            if(mode == PMLEventStateCurrent) {
                // It is current, we found it!
                return YES;
            }
        }
    }
    // If no data found for this type, we return default result, otherwise false
    return hasData ? NO : defaultResult;
}
-(NSString *)stringFromCalendar:(PMLCalendar *)calendar {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSArray *daySymbols = [formatter shortStandaloneWeekdaySymbols];
    
    
    // Building a list from days
    NSMutableArray *enabledList = [[NSMutableArray alloc] init];
    [enabledList addObject:([calendar isSunday] ? @1 : @0)];
    [enabledList addObject:([calendar isMonday] ? @1 : @0)];
    [enabledList addObject:([calendar isTuesday] ? @1 : @0)];
    [enabledList addObject:([calendar isWednesday] ? @1 : @0)];
    [enabledList addObject:([calendar isThursday] ? @1 : @0)];
    [enabledList addObject:([calendar isFriday] ? @1 : @0)];
    [enabledList addObject:([calendar isSaturday] ? @1 : @0)];

    
    int i = 0;
    NSNumber *start = nil;
    NSString *buf = @"";
    NSString *sep = @"";
    BOOL allTrue = YES;
    while (i < [enabledList count]) {
        // Is this day active?
        BOOL enabled = [[enabledList objectAtIndex:i] boolValue];
        allTrue = allTrue && enabled;
        // If yes and no start, we register it
        if (start == nil && enabled) {
            start = [NSNumber numberWithInt:i];
        }
        // If not enabled we print last range
        if (!enabled && start != nil) {
            buf = [buf stringByAppendingFormat:@"%@%@",sep,daySymbols[start.intValue ]];
            if (i > start.intValue + 1) {
                buf = [buf stringByAppendingFormat:@"-%@",daySymbols[i-1]];
            }
            sep = @",";
            start = nil;
        }
        i++;
    }
    // Last part may not have been added
    if (start != nil) {
        buf = [buf stringByAppendingFormat:@"%@%@",sep,daySymbols[start.intValue ]];
        if (i > start.intValue + 1) {
            buf = [buf stringByAppendingFormat:@"-%@",daySymbols[i-1]];
        }
    }
    if (allTrue) {
        buf = NSLocalizedString(@"calendar.daily",@"Daily");
    }
    
    // Handling US / european dates
    NSString *localStartTime = [self stringForHours:[calendar startHour] minutes:[calendar startMinute]];
    NSString *localEndTime = [self stringForHours:[calendar endHour] minutes:[calendar endMinute]];

    
    buf = [buf stringByAppendingFormat:@" %@-%@",localStartTime,localEndTime];
    
    return buf;
}

- (NSString *)stringForHours:(NSInteger)hours minutes:(NSInteger)minutes {
    NSDateFormatter *fullClockFormatter = [[NSDateFormatter alloc]init];
    [fullClockFormatter setDateFormat:@"HH:mm"];

    NSDate *startTime = [fullClockFormatter dateFromString:[NSString stringWithFormat:@"%02d:%02ld",(int)hours%24,(long)minutes]];

    [fullClockFormatter setDateStyle:NSDateFormatterNoStyle];
    [fullClockFormatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *localStartTime = [fullClockFormatter stringFromDate:startTime];
    return localStartTime;
}

-(NSDictionary*)hashHoursByType:(CALObject*)object {
    NSArray *hours = nil;
    if([object isKindOfClass:[Place class]]) {
        hours = ((Place*)object).hours;
    }
    // Processing hours hashmap
    NSMutableDictionary *hoursTypeMap = [[NSMutableDictionary alloc] init];
    for(PMLCalendar *calendar in hours) {
        
        // Retrieving previous list registered for this type
        NSMutableArray *typedCalendars = [hoursTypeMap objectForKey:calendar.calendarType];
        
        // Creating a new entry if not yet defined
        if(typedCalendars == nil) {
            typedCalendars = [[NSMutableArray alloc] init];
            [hoursTypeMap setObject:typedCalendars forKey:calendar.calendarType];
        }
        
        // Appending this calendar to the typed list
        [typedCalendars addObject:calendar];
    }
    return hoursTypeMap;
}

- (NSString *)eventDateLabel:(Event*)event isStart:(BOOL)start {

    BOOL timeOnly = NO;
    NSDate *date;
    if(start) {
        date = event.startDate;
    } else {
        if(event.startDate != nil) {
            NSTimeInterval delta = [event.endDate timeIntervalSinceDate:event.startDate];
            if(delta < 86400) {
                timeOnly = YES;
            }
        }
        date= event.endDate;
    }
    return [self stringForEventDate:date timeOnly:timeOnly];
}
-(NSString *)stringForEventDate:(NSDate*)date timeOnly:(BOOL)timeOnly {
    NSString *template=@"EdMMMhmma";
    if(timeOnly) {
        template = @"hmma";
    }
    NSString *formatString = [NSDateFormatter dateFormatFromTemplate:template options:0
                                                              locale:[NSLocale currentLocale]];
    [_eventDateFormatter setDateFormat:formatString];
    return [_eventDateFormatter stringFromDate:date];
}
@end
