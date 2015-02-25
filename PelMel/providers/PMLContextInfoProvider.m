//
//  PMLContextInfoProvider.m
//  PelMel
//
//  Created by Christophe Fondacci on 31/08/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PMLContextInfoProvider.h"
#import "TogaytherService.h"
#import "Activity.h"
#import "ItemsThumbPreviewProvider.h"

@implementation PMLContextInfoProvider {
    DataService *_dataService;
    ModelHolder *_modelHolder;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _dataService = [TogaytherService dataService];
        _modelHolder = _dataService.modelHolder;
    }
    return self;
}
// The element being represented
-(CALObject*) item {
    return _modelHolder.localizedCity;
}
- (CALImage *)snippetImage {
    if(_modelHolder.localizedCity.mainImage) {
        return _modelHolder.localizedCity.mainImage;
    } else {
        return [CALImage calImageWithImage:[UIImage imageNamed:@"logoMob"]];
    }
}
// Title of the element
-(NSString*) title {
    NSString *title;
    if(_modelHolder.users.count == 0) {
        NSString *titleTemplate = @"places.section.inZone";
        title = [NSString stringWithFormat:NSLocalizedString(titleTemplate, titleTemplate),_modelHolder.places.count];
    } else {
        NSString *titleTemplate = @"places.section.inZoneWithUsers";
        title = [NSString stringWithFormat:NSLocalizedString(titleTemplate, titleTemplate),_modelHolder.places.count,_modelHolder.users.count];
    }
    return title;

}
// Icon representing the type of item being displayed
-(UIImage*) titleIcon {
    return [UIImage imageNamed:@"snpIconBar"];
}
// Global theme color for element
-(UIColor*) color {
    return UIColorFromRGB(0xec7700);
}
// Provider of thumb displayed in the main snippet section
-(NSObject<ThumbsPreviewProvider>*) thumbsProvider {
    // Building provider
    return [[ItemsThumbPreviewProvider alloc] initWithParent:nil items:_modelHolder.users moreSegueId:nil labelKey:nil icon:nil];
}
- (NSObject<ThumbsPreviewProvider> *)thumbsProviderFor:(ThumbPreviewMode)mode atIndex:(NSInteger)row {
    return nil;
}
// Number of reviews
-(NSInteger)reviewsCount {
    return 0;
}
// Number of likes
-(NSInteger)likesCount {
    return 0;
}
// Number of checkins (if applicable)
-(NSInteger)checkinsCount {
    return 0;
}
// Description of elements
-(NSString*)descriptionText {
    if(_modelHolder.localizedCity!=nil) {
        // Should return city description when available
        return _modelHolder.localizedCity.miniDesc;
    }
    return nil;
}
// Short text displayed with thumb
-(NSString*)thumbSubtitleText {
    return nil;
}
// Color of the short thumb subtitle text
-(UIColor*)thumbSubtitleColor {
    return [self color];
}
-(NSArray *)addressComponents {
    return @[];
}
- (NSArray *)activities {
    return _modelHolder.activities;
}
- (NSArray *)topPlaces {
    int topPlacesCount = MIN((int)_modelHolder.places.count,10);
    if(topPlacesCount>0) {
        NSRange range;
        range.location = 0;
        range.length=topPlacesCount;
        return [_modelHolder.places subarrayWithRange:range];;
    } else {
        return nil;
    }
}

- (NSObject<ThumbsPreviewProvider> *)likesThumbsProviderAtIndex:(NSInteger)row {
    return nil;
}
-(NSObject<ThumbsPreviewProvider> *)checkinsThumbsProvider {
    return nil;
}

- (NSString *)itemTypeLabel {
    return nil;
}
- (NSString *)city {
    return nil;
}
-(NSInteger)thumbsRowCountForMode:(ThumbPreviewMode)mode {
    return 0;
}
- (NSArray *)events {
    return _modelHolder.events;
}
- (NSString *)eventsSectionTitle {
    return NSLocalizedString(@"snippet.title.events", @"Upcoming events");
}
@end
