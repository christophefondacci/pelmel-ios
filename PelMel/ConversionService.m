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
    } else {
        return nil;
    }
}

-(void)geocodeAddressFor:(CALObject *)object completion:(AddressClosure)closure {
    // Geocoding
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:object.lat longitude:object.lng];
    [_geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
        if(error == nil && placemarks.count>0) {
            // Getting first result
            CLPlacemark *placemark = placemarks[0];
            
            NSArray *addressLines = [placemark.addressDictionary objectForKey:@"FormattedAddressLines"];
            NSMutableString *address = [[NSMutableString alloc ] init];
            NSString *separator = @"";
            for(NSString *addressLine in addressLines) {
                [address appendString:separator];
                [address appendString:addressLine];
                separator = @", ";
            }
            // Calling back
            if(closure != nil) {
                closure(address);
            }
        }
    }];

}
/**
 * Informs whether the special is currently valid or not
 */
-(SpecialMode) specialModeFor:(Special*)special {
    NSDate *date = [NSDate date];
    if(([special.nextStart compare:special.nextEnd] == NSOrderedDescending ||[date compare:special.nextStart] == NSOrderedDescending)) {
        if([date compare:special.nextEnd] == NSOrderedAscending) {
            return CURRENT;
        } else {
            return PAST;
        }
    } else {
        return SOON;
    }
}
-(Special*)specialFor:(CALObject*)place ofType:(NSString *)specialType{
    Special *bestSpecial = nil;
    if([place isKindOfClass:[Place class]]) {
        NSArray *specials = ((Place*)place).specials;
        for(Special *special in specials) {
            if([special.type isEqualToString:specialType]) {
                bestSpecial = special;
            }
        }
    }
    return bestSpecial;
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

    NSDate *startTime = [fullClockFormatter dateFromString:[NSString stringWithFormat:@"%02d:%02d",hours%24,minutes]];

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
    NSString *template=@"EdMMMhmma";
    NSDate *date;
    if(start) {
        date = event.startDate;
    } else {
        if(event.startDate != nil) {
            NSTimeInterval delta = [event.endDate timeIntervalSinceDate:event.startDate];
            if(delta < 86400) {
                template = @"hmma";
            }
        }
        date= event.endDate;
    }
    NSString *formatString = [NSDateFormatter dateFormatFromTemplate:template options:0
                                                              locale:[NSLocale currentLocale]];
    [_eventDateFormatter setDateFormat:formatString];
    return [_eventDateFormatter stringFromDate:date];
}
@end
