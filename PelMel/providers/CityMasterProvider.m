//
//  CityMasterProvider.m
//  togayther
//
//  Created by Christophe Fondacci on 16/01/13.
//  Copyright (c) 2013 Christophe Fondacci. All rights reserved.
//

#import "CityMasterProvider.h"
#import "MasterViewController.h"
#import "City.h"

@implementation CityMasterProvider

- (NSString *)getDistanceLabel:(CALObject *)obj {
    return ((City*)obj).localization;
}
- (NSString *)getLikeLabel:(CALObject *)obj {
    return [NSString stringWithFormat:@"%d",((City*)obj).placesCount];
}
- (NSString *)getMenLabel:(CALObject *)obj {
    return nil;
}
- (NSString *)getTitle:(CALObject *)obj {
    return ((City*)obj).name;
}
- (NSString *)getTypeLabel:(CALObject *)obj {
    City *city = (City*)obj;
    if(city.placesCount>0) {
        NSString *template = NSLocalizedString(@"city.withbars",@"Number of bars template");
        NSString *label= [NSString stringWithFormat:template,city.placesCount];
        return label;
    } else {
        return NSLocalizedString(@"city.label", @"City");
    }
}
- (BOOL)isMenLabelVisible:(CALObject *)obj {
    return NO;
}
- (BOOL)isLikeLabelVisible:(CALObject *)obj {
    return YES;
}
- (BOOL)isDisplayed:(CALObject *)obj {
    return YES;
}
-(double) getRawDistance:(CALObject*)obj {
    return 0;
}

@end
