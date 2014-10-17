//
//  EventsMasterProvider.m
//  togayther
//
//  Created by Christophe Fondacci on 18/12/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "EventMasterProvider.h"
#import "../Event.h"

@implementation EventMasterProvider {
    NSDateFormatter *dateFormatter;
}

- (id)init
{
    self = [super init];
    if (self) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm";
    }
    return self;
}
- (NSString *)getDistanceLabel:(CALObject *)obj {
    return ((Event*)obj).distance;
}
- (NSString *)getLikeLabel:(CALObject *)obj {
    return [NSString stringWithFormat:NSLocalizedString(@"list.places.men", @""),obj.likeCount];

}
- (NSString *)getMenLabel:(CALObject *)obj {
    return nil;
}
- (NSString *)getTitle:(CALObject *)obj {
    return ((Event*)obj).name;
}
- (NSString *)getTypeLabel:(CALObject *)obj {
    return [dateFormatter stringFromDate:((Event*)obj).startDate];
}
- (BOOL)isMenLabelVisible:(CALObject *)obj {
    return NO;
}
- (BOOL)isLikeLabelVisible:(CALObject *)obj {
    return obj.likeCount>0;
}
- (BOOL)isDisplayed:(CALObject *)obj {
    return YES;
}
-(double) getRawDistance:(CALObject*)obj {
    return ((Event*)obj).rawDistance;
}
@end
