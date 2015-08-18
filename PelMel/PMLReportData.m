
//
//  PMLReportData.m
//  PelMel
//
//  Created by Christophe Fondacci on 15/08/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLReportData.h"

@implementation PMLReportData


- (instancetype)initWithDate:(NSDate *)date type:(NSString *)type count:(NSNumber *)count
{
    self = [super init];
    if (self) {
        self.date = date;
        self.type = type;
        self.count = count;
    }
    return self;
}
@end
