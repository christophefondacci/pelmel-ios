//
//  PlaceMasterProvider.m
//  togayther
//
//  Created by Christophe Fondacci on 11/12/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "PlaceMasterProvider.h"
#import "../Place.h"
#import "../TogaytherService.h"
#import "Special.h"
#import "Constants.h"



@implementation PlaceMasterProvider {
    DataService *dataService;
    SettingsService *settingsService;
}

- (id)init
{
    self = [super init];
    if (self) {
        dataService = [TogaytherService dataService];
        settingsService = [TogaytherService settingsService];
    }
    return self;
}

-(NSString *)getTitle:(CALObject *)obj {
    return ((Place*)obj).title;
}

- (NSString *)getTypeLabel:(CALObject *)obj {
    Place *place = (Place*)obj;
    PlaceType *placeType = [settingsService getPlaceType:place.placeType];
    if(place.adBoost>0) {
        return placeType.sponsoredLabel;
    } else {
        return placeType.label;
    }
}

- (NSString *)getDistanceLabel:(CALObject *)obj {
    Place *p = (Place*)obj;
    return [TogaytherService.getConversionService distanceTo:p];
}

- (BOOL)isMenLabelVisible:(CALObject *)obj {
    return ((Place*)obj).inUserCount > 0;
}

- (BOOL)isLikeLabelVisible:(CALObject *)obj {
    return ((Place*)obj).likeCount > 0;
}

- (NSString *)getMenLabel:(CALObject *)obj {
   return [NSString stringWithFormat:NSLocalizedString(@"list.places.men", @""),((Place*)obj).inUserCount];
}

-(NSString *)getLikeLabel:(CALObject *)obj {
    return [NSString stringWithFormat:NSLocalizedString(@"list.places.likes", @""),((Place*)obj).likeCount];
}
- (BOOL)isDisplayed:(CALObject *)obj {
    Place *place = (Place*)obj;
    PlaceType *placeType = [settingsService getPlaceType:place.placeType];
    // The place is displayed only if we got a valid place type which is not tagged as filtered
    return (placeType != nil && placeType.visible);
}
-(double)getRawDistance:(CALObject *)obj {
    return ((Place*)obj).rawDistance;
}

#pragma mark - Specials implementation

-(Special*)getSpecialFor:(CALObject *)obj {
    NSArray *specials = ((Place*)obj).specials;
    Special *bestSpecial = nil;
    for(Special *special in specials) {
        if(bestSpecial == nil ||[special.type isEqualToString:SPECIAL_TYPE_OPENING] || [bestSpecial.nextStart compare:special.nextStart] == NSOrderedDescending) {
            bestSpecial = special;
        }
    }
    return bestSpecial;
}
-(NSString *)getSpecialIntroLabel:(Special *)special {
    NSString *label = nil;
    if(special != nil) {
        SpecialMode specialMode = [self getSpecialMode:special];
        switch(specialMode) {
            case CURRENT: {
                NSString *deltaStr = [self getDeltaString:special.nextEnd];
                label = [NSString stringWithFormat:NSLocalizedString(@"specials.open.leftHours",@"specials.open.leftHours"),deltaStr];
                break;
            }
            case SOON:
                if([special.type isEqualToString:SPECIAL_TYPE_OPENING]) {
                    label = NSLocalizedString(@"specials.open.in",@"specials.open.in");
                } else {
                    label = NSLocalizedString(@"specials.start.in",@"specials.start.in");
                }
                break;
            default:
                label = nil;
                break;
        }
    }
    return label;
}

/**
 * Informs whether the special is currently valid or not
 */
-(SpecialMode) getSpecialMode:(Special*)special {
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

-(NSString*)getDeltaString:(NSDate*)date {
    NSTimeInterval delta = date.timeIntervalSinceNow;
    
    if(delta < 60) {
        delta = 60;
    }
    int value;
    if(delta < 3600 || delta > 999999999) {
        // Display in minutes
        value = delta / 60;
        NSString *minStr = NSLocalizedString(@"time.minutes", @"time.minutes");
        return [NSString stringWithFormat:@"%d %@",value,minStr];
    } else if(delta < 86400) {
        // Display in hours
        value = delta / 3600;
        NSString *hourStr = NSLocalizedString(@"time.hours", @"time.hours");
        return [NSString stringWithFormat:@"%d %@",value,hourStr];
    } else {
        // Display in days
        value = delta / 86400;
        NSString *dayStr = NSLocalizedString(@"time.days", @"time.days");
        return [NSString stringWithFormat:@"%d %@",value,dayStr];
    }
}

- (NSString *)getSpecialsMainLabel:(Special *)special {
    if(special != nil) {

        // If next end date is < to next start and is not yet
        switch([self getSpecialMode:special]) {
            case CURRENT:
                if([special.type isEqualToString:SPECIAL_TYPE_OPENING]) {
                    return NSLocalizedString(@"specials.opened", @"specials.opened");
                } else {
                    return NSLocalizedString(@"specials.happy", @"specials.happy");
                }
                break;
            case SOON: {
                NSString *deltaStr = [self getDeltaString:special.nextStart];
                return deltaStr;
            }
            default:
                return nil;
        }
    }
    return nil;
}

- (UIColor *)getSpecialsColor:(Special *)special {
    switch([self getSpecialMode:special]) {
        case CURRENT:
//            return UIColorFromRGB(0xa5d170);
            return UIColorFromRGB(0x72ff00);
        case SOON:
            return UIColorFromRGB(0xffbb56);
        case PAST:
            return [UIColor clearColor]; //UIColorFromRGB(0xc5595d);
    }
}
- (BOOL)hasSubtitle:(CALObject *)obj {
    NSArray *specials = ((Place*)obj).specials;
    BOOL happyHourAvailable = NO;
    // Checking if we have opening definition
    for(Special *special in specials) {
        if([SPECIAL_TYPE_HAPPY isEqualToString:special.type]) {
            happyHourAvailable = YES;
        }
    }
    // We display subtitle if we have opening hours or more than 1 upcoming special
    return happyHourAvailable;
}
- (Special *)getSpecialSubtitleFor:(CALObject *)obj currentBestSpecial:(Special *)currentBestSpecial {
    // Processing specials
    NSArray *specials = ((Place*)obj).specials;
    Special *bestSpecial = nil;
    // Looking for 2nd best special
    for(Special *special in specials) {
        if((special != currentBestSpecial || [SPECIAL_TYPE_HAPPY isEqualToString:currentBestSpecial.type])&& (bestSpecial == nil || [bestSpecial.nextEnd compare:special.nextStart] == NSOrderedDescending)) {
            bestSpecial = special;
        }
    }
    // If no other special, and if we got opening hours, then we keep it for subtitle
//    if(bestSpecial == nil &&  [SPECIAL_TYPE_OPENING isEqualToString:currentBestSpecial.type]) {
//        bestSpecial = currentBestSpecial;
//    }
    return bestSpecial;
}
- (NSString *)getSpecialsSubtitleLabel:(Special *)bestSpecial {
    NSString *subtitle = nil;
    if(![SPECIAL_TYPE_OPENING isEqualToString:bestSpecial.type]) {
        SpecialMode mode = [self getSpecialMode:bestSpecial];
        NSDate *specialDate;
        NSString *templateCode;
        switch(mode) {
            case CURRENT:
                specialDate = bestSpecial.nextEnd;
                templateCode =@"specials.subtitleTemplate.current";
                break;
            case SOON:
                specialDate = bestSpecial.nextStart;
                templateCode = @"specials.subtitleTemplate.soon";
                break;
            default:
                specialDate = nil;
                templateCode = nil;
        }
        if(templateCode != nil) {
            NSString *timeDeltaString = [self getDeltaString:specialDate];
            subtitle = [NSString stringWithFormat:NSLocalizedString(templateCode,templateCode),timeDeltaString, bestSpecial.name ];
        }
    } else {
        // If opening hours definition we display the full description of opening times
        // as our subtitle
        subtitle = bestSpecial.descriptionText;
    }
    return subtitle;
}
@end
