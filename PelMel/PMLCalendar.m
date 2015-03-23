//
//  PMLCalendar.m
//  PelMel
//
//  Created by Christophe Fondacci on 17/02/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLCalendar.h"

@implementation PMLCalendar


- (instancetype)init
{
    self = [super init];
    if (self) {
        // Setting start / end hour based on now
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
        NSDateComponents *components = [gregorian components: (NSCalendarUnitHour | NSCalendarUnitMinute) fromDate: [NSDate date]];
        self.startHour = components.hour + 1;
        self.startMinute = 0;
        self.endHour = self.startHour+2;
        self.endMinute = 0;
    }
    return self;
}
- (BOOL)isEnabledFor:(NSInteger)index {
    BOOL checked = NO;
    if([self isSunday] && index == 0) {
        checked = YES;
    } else if([self isMonday] && index == 1) {
        checked = YES;
    } else if([self isTuesday] && index == 2) {
        checked = YES;
    } else if([self isWednesday] && index == 3) {
        checked = YES;
    } else if([self isThursday] && index == 4) {
        checked = YES;
    } else if([self isFriday] && index == 5) {
        checked = YES;
    } else if([self isSaturday] && index == 6) {
        checked = YES;
    }
    return checked;
}

- (BOOL)toggleEnablementFor:(NSInteger)index {
    switch(index) {
        case 1:
            self.isMonday = !self.isMonday;
            break;
        case 2:
            self.isTuesday = !self.isTuesday;
            break;
        case 3:
            self.isWednesday = !self.isWednesday;
            break;
        case 4:
            self.isThursday = !self.isThursday;
            break;
        case 5:
            self.isFriday = !self.isFriday;
            break;
        case 6:
            self.isSaturday = !self.isSaturday;
            break;
        case 0:
            self.isSunday = !self.isSunday;
            break;
    }
    return [self isEnabledFor:index];
}

@end
