//
//  PlaceTypesThumbPreviewProvider.m
//  PelMel
//
//  Created by Christophe Fondacci on 03/09/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PMLPlaceTypesThumbProvider.h"
#import "TogaytherService.h"

@implementation PMLPlaceTypesThumbProvider {
    NSArray *_placeTypes;
    Place *_place;
    
    UIService *_uiService;
    SettingsService *_settingsService;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _uiService          = [TogaytherService uiService];
        _settingsService    = [TogaytherService settingsService];
        
        _placeTypes = [_settingsService listPlaceTypes];
    }
    return self;
}
- (instancetype)initWithPlace:(Place*)place
{
    self = [self init];
    if (self) {
        _place = place;
    }
    return self;
}
- (CALImage*)imageAtIndex:(NSInteger)index forType:(PMLThumbType)type {
    PlaceType *placeType = [_placeTypes objectAtIndex:index];
    CALImage *calImage;
    if(placeType.icon) {
        calImage= [CALImage calImageWithImage:placeType.icon];
    }
    return calImage;
}
- (UIImage*)topLeftDecoratorForIndex:(NSInteger)index forType:(PMLThumbType)type{
    return nil;
}
- (UIImage*)bottomRightDecoratorForIndex:(NSInteger)index forType:(PMLThumbType)type {
    return nil;
}

- (NSArray*)itemsForType:(PMLThumbType)thumbType {
    return  _placeTypes;
}
- (NSString*)titleAtIndex:(NSInteger)index forType:(PMLThumbType)type{
    PlaceType *placeType = [_placeTypes objectAtIndex:index];
    return placeType.label;
}

- (BOOL)rounded {
    return NO;
}

- (NSArray *)thumbTypes {
    return @[[NSNumber numberWithInt:PMLThumbsOther]];
}
- (PMLThumbType)thumbTypeAtIndex:(NSInteger)index {
    return PMLThumbsOther;
}
-(BOOL)isSelected:(NSInteger)index forType:(PMLThumbType)type{
    PlaceType *placeType = [_placeTypes objectAtIndex:index];
    return [placeType.code isEqualToString:_place.placeType];
}

- (NSInteger)fontSize {
    return 7;
}
@end
