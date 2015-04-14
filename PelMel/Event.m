//
//  Event.m
//  togayther
//
//  Created by Christophe Fondacci on 18/12/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "Event.h"

@implementation Event


- (instancetype)init
{
    self = [super init];
    if (self) {
        // Setting start / end hour based on now
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
        NSDateComponents *components = [gregorian components: (NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitTimeZone) fromDate: [NSDate date]];
        components.hour = components.hour+1 % 24;
        components.minute = 0;
        components.second = 0;

        if([gregorian respondsToSelector:@selector(dateBySettingHour:minute:second:ofDate:options:)]) {
            self.startDate = [gregorian dateBySettingHour:((components.hour+1)%24) minute:0 second:0 ofDate:[NSDate new] options:NSCalendarWrapComponents];
        } else {
            self.startDate = [gregorian dateFromComponents:components];
        }

        
        // 1 day after 
        if(components.hour+1>23) {
            self.startDate = [self.startDate dateByAddingTimeInterval:86400];
        }
        
        // End date
        components.hour =(components.hour+3) % 24;
        
        if([gregorian respondsToSelector:@selector(dateBySettingHour:minute:second:ofDate:options:)]) {
            self.endDate = [gregorian dateBySettingHour:((components.hour+3) % 24) minute:0 second:0 ofDate:[NSDate new] options:NSCalendarWrapComponents];
        } else {
            self.endDate = [gregorian dateFromComponents:components];
        }
        
        if(components.hour+3>23) {
            self.endDate = [self.endDate dateByAddingTimeInterval:86400];
        }
        
    }
    return self;
}
- (instancetype)initWithPlace:(Place *)place
{
    self = [self init];
    if (self) {
        self.place = place;
    }
    return self;
}

@end
