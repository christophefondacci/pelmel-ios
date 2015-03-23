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
        NSDateComponents *components = [gregorian components: (NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute) fromDate: [NSDate date]];
        components.hour = components.hour+1;
        components.minute = 0;
        components.second = 0;
        self.startDate = [gregorian dateBySettingHour:((components.hour+1)%24) minute:0 second:0 ofDate:[NSDate new] options:NSCalendarWrapComponents];
        // 1 day after 
        if(components.hour+1>23) {
            self.startDate = [self.startDate dateByAddingTimeInterval:86400];
        }
        self.endDate = [gregorian dateBySettingHour:((components.hour+3) % 24) minute:0 second:0 ofDate:[NSDate new] options:NSCalendarWrapComponents];
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
