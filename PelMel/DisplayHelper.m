//
//  DisplayHelper.m
//  PelMel
//
//  Created by Christophe Fondacci on 27/01/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "DisplayHelper.h"
#import "User.h"
#import "Place.h"
#import "Event.h"


@implementation DisplayHelper

+ (NSString *)getName:(CALObject *)object {
    if([object isKindOfClass:[User class]]) {
        return ((User*)object).pseudo;
    } else if([object isKindOfClass:[Place class]]) {
        return ((Place*)object).title;
    } else if([object isKindOfClass:[Event class]]) {
        return ((Event*)object).name;
    }
    return @"";
}
@end
