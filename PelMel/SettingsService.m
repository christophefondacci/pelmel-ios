//
//  SettingsService.m
//  PelMel
//
//  Created by Christophe Fondacci on 12/02/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "SettingsService.h"
#import "CALObject.h"
#import "Place.h"
#import "TogaytherService.h"
#import "PMLInfoProvider.h"
#import "ConversionService.h"
#import "UIService.h"

#define kKeyFilterFormat @"filter.%d"
#define kPlaceTypeLabelFormat @"placetype.%@"
#define kPlaceTypePropertyFormat @"placeType.active.%@"
#define kPlaceTypeIconFormat @"icon.%@"
#define kPlaceTypeFilterIconFormat @"icon.filter.%@"
#define kPlaceTypeSponsoredFormat @"placetype.sponsored"

@implementation SettingsService {
    NSMutableDictionary *placeTypesMap;
    NSArray *definedPlaceTypes;
    NSArray *definedTags;
    
    NSMutableSet *listeners;
    NSUserDefaults *_defaults;
}

- (id)init
{
    self = [super init];
    if (self) {
        listeners = [[NSMutableSet alloc] init];
        placeTypesMap = [[NSMutableDictionary alloc] init];
        _defaults = [NSUserDefaults standardUserDefaults];
        
        // Initializing place types from constant definition
        NSString *strPlaceTypes = NSLocalizedString(@"placetypes",nil);
        NSArray *placeCodes = [strPlaceTypes componentsSeparatedByString:@","];
        NSMutableArray *placeTypes = [[NSMutableArray alloc] initWithCapacity:[placeCodes count]];
        NSString *placeCode;
        
        self.allFiltersActive = YES;
        _leftHandedMode = [[_defaults objectForKey:PML_PROP_LEFTHANDED] boolValue];
        
        for(placeCode in placeCodes) {
            PlaceType *placeType = [[PlaceType alloc] initWithCode:placeCode];
            
            // Remembering last filter state
            placeType.visible = [self isPlaceTypeActive:placeCode];
            
            // Injecting icon
            NSString *icon = [TogaytherService propertyFor:[NSString stringWithFormat:kPlaceTypeIconFormat,placeCode] ];
            if(icon == nil) {
                icon = [TogaytherService propertyFor:[NSString stringWithFormat:kPlaceTypeIconFormat,@"default"] ];
            }
            UIImage *placeIcon = [UIImage imageNamed:icon];
            [placeType setIcon:placeIcon];
            
            // Injecting filter icon
            NSString *filterIcon = [TogaytherService propertyFor:[NSString stringWithFormat:kPlaceTypeFilterIconFormat,placeCode] ];
            if(filterIcon == nil) {
                filterIcon = [TogaytherService propertyFor:[NSString stringWithFormat:kPlaceTypeFilterIconFormat,@"default"] ];
            }
            UIImage *placeFilterIcon = [UIImage imageNamed:filterIcon];
            [placeType setFilterIcon:placeFilterIcon];
            
            // Computing and injecting label
            NSString *labelCode = [[NSString alloc] initWithFormat:kPlaceTypeLabelFormat,placeType.code];
            NSString *placeTypeLabel = NSLocalizedString(labelCode, nil);
            [placeType setLabel:placeTypeLabel];
            
            // Computing the corresponding "sponsored" label
            NSString *sponsoredLabelTemplate =NSLocalizedString(kPlaceTypeSponsoredFormat,nil);
            NSString *sponsoredLabel = [NSString stringWithFormat:sponsoredLabelTemplate,placeTypeLabel];
            [placeType setSponsoredLabel:sponsoredLabel];
            
            // Registering our local structures
            [placeTypes addObject:placeType];
            [placeTypesMap setValue:placeType forKey:placeCode];
        }
        
        definedPlaceTypes = [placeTypes sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSString *label1 = [(PlaceType *)obj1 label];
            NSString *label2 = [(PlaceType *)obj2 label];
            return [label1 compare:label2];
        }];
        
        // Building tags
        NSString *strTags = NSLocalizedString(@"tags",nil);
        definedTags = [strTags componentsSeparatedByString:@","];
        [self updateAllFiltersFlag];
    }
    return self;
}
-(void)updateAllFiltersFlag {
//    self.allFiltersActive = YES;
    BOOL allFiltersActive = YES;
    BOOL noFilterActive = YES;
    for(PlaceType *pt in definedPlaceTypes) {
        allFiltersActive &= pt.visible;
        noFilterActive &= !pt.visible;
    }
    self.allFiltersActive = allFiltersActive || noFilterActive;
    self.allFiltersActive &= ![self isFilterEnabled:PMLFilterHappyHours];
    self.allFiltersActive &= ![self isFilterEnabled:PMLFilterOpeningHours];
    self.allFiltersActive &= ![self isFilterEnabled:PMLFilterEvents];
}
-(BOOL)isPlaceTypeActive:(NSString*)code {

    id prop = [_defaults objectForKey:[NSString stringWithFormat:kPlaceTypePropertyFormat,code]];
    if(prop != nil && [prop isKindOfClass:[NSNumber class]]) {
        return ((NSNumber*)prop).integerValue == 1;
    } else {
        return NO;
    }
}
- (BOOL)isVisible:(CALObject*)object {
    BOOL filtersActive = NO;
    BOOL placeActive = NO;
    if([object isKindOfClass:[Place class]]) {
        Place *place = (Place*)object;
        for(PlaceType *t in definedPlaceTypes) {
            if(t.visible) {
                filtersActive=YES;
                if([t.code isEqualToString:place.placeType]) {
                    placeActive = YES;
                    break;
                }
            }
        }
        // No need to apply other filter if place has already been filtered out
        if(placeActive || !filtersActive) {
            if([self isFilterEnabled:PMLFilterOpeningHours]) {
                filtersActive=YES;
                placeActive = [self isOpened:place];
            }
            if([self isFilterEnabled:PMLFilterHappyHours] && (placeActive|| !filtersActive)) {
                filtersActive = YES;
                placeActive = [self isHappyHour:place];
            }
            if([self isFilterEnabled:PMLFilterEvents] && (placeActive|| !filtersActive)) {
                filtersActive = YES;
                placeActive = [self hasEvent:place];;
            }
            if([self isFilterEnabled:PMLFilterCheckins] && (placeActive|| !filtersActive)) {
                filtersActive = YES;
                placeActive = [self hasCheckin:place];;
            }
        }
    }
    // If nothing filtered, everything visible, else we check place type filter
    return !filtersActive || placeActive;
}

-(BOOL)isOpened:(Place*)place {
    return [_conversionService calendarType:SPECIAL_TYPE_OPENING isCurrentFor:place noDataResult:NO];
}

-(BOOL)isHappyHour:(Place*)place {
    return [_conversionService calendarType:SPECIAL_TYPE_HAPPY isCurrentFor:place noDataResult:NO];
}
-(BOOL)hasEvent:(Place*)place {
    if(place.events.count>0) {
        return YES;
    } else {
        for(Event *e in [[[TogaytherService dataService] modelHolder] events]) {
            if([e.place.key isEqualToString:place.key]){
                return YES;
            }
        }
    }
    return NO;
}
-(BOOL)hasCheckin:(Place*)place {
    return place.inUserCount>0 || place.inUsers.count>0;
}
-(void)storePlaceTypeFilter:(PlaceType*)placeType {
    NSNumber *val = [NSNumber numberWithBool:placeType.visible];
    // Saving property
    [_defaults setObject:val forKey:[NSString stringWithFormat:kPlaceTypePropertyFormat,placeType.code]];
    [_defaults synchronize];
    [self updateAllFiltersFlag];
    [self notifyFiltersChanged];
}

- (NSArray *)listPlaceTypes {
    return definedPlaceTypes;
}
- (NSArray *)listTags {
    return definedTags;
}

- (PlaceType *)getPlaceType:(NSString *)placeTypeCode {
    return [placeTypesMap valueForKey:placeTypeCode];
}
- (PlaceType *)defaultPlaceType {
    return [self getPlaceType:@"bar"];
}
- (void)addSettingsListener:(NSObject<SettingsListener> *)listener {
    [listeners addObject:listener];
}
- (void)removeSettingsListener:(NSObject<SettingsListener> *)listener {
    [listeners removeObject:listener];
}

- (BOOL)isFilterEnabled:(FilterCode)filter {
    NSString *key = [NSString stringWithFormat:kKeyFilterFormat,filter];
    return [[_defaults objectForKey:key] boolValue];
}
-(void)enableFilter:(FilterCode)filter enablement:(BOOL)enabled {
    NSString *key = [NSString stringWithFormat:kKeyFilterFormat,filter];
    [_defaults setObject:[NSNumber numberWithBool:enabled] forKey:key];
    [_defaults synchronize];
    [self updateAllFiltersFlag];
    [self notifyFiltersChanged];
}

-(void)notifyFiltersChanged {
    // Notifying listeners
    for(NSObject<SettingsListener> *listener in listeners) {
        
        // Optional method, so we check existence
        if([listener respondsToSelector:@selector(filtersChanged)]) {
            [listener filtersChanged];
        }
    }
}

- (void)setLeftHandedMode:(BOOL)leftHandedMode {
    _leftHandedMode = leftHandedMode;
    [_defaults setObject:[NSNumber numberWithBool:leftHandedMode] forKey:PML_PROP_LEFTHANDED];
}

- (BOOL)isCheckinEnabledFor:(id)place {
    return [_conversionService numericDistanceTo:place] <= PML_CHECKIN_DISTANCE;
}
@end
