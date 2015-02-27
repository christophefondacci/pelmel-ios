//
//  PMLEventInfoProvider.m
//  PelMel
//
//  Created by Christophe Fondacci on 24/02/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLEventInfoProvider.h"
#import "TogaytherService.h"
#import "ItemsThumbPreviewProvider.h"
#import "PMLPlaceInfoProvider.h"
#import "LikeableStrategyObjectWithLikers.h"
#import "PMLDataManager.h"

@implementation PMLEventInfoProvider {
    ImageService *_imageService;
    ConversionService *_conversionService;
    UIService *_uiService;
    NSObject<PMLInfoProvider> *_placeInfoProvider;
    Event *_event;
    id<Likeable> _likeableDelegate;
}

- (instancetype)initWithEvent:(Event *)event
{
    self = [super init];
    if (self) {
        _imageService = [TogaytherService imageService];
        _conversionService = [TogaytherService getConversionService];
        _uiService = [TogaytherService uiService];
        _event = event;
        if(_event.place!=nil) {
            _placeInfoProvider = [_uiService infoProviderFor:_event.place];
            if(!_event.place.hasOverviewData) {
                [[TogaytherService dataService] getOverviewData:_event.place];
            }
        }
        _likeableDelegate = [[LikeableStrategyObjectWithLikers alloc] init];
    }
    return self;
}
// The element being represented
-(CALObject*) item {
    return _event;
}
// Title of the element
-(NSString*) title {
    return _event.name;
}
- (NSString *)subtitle {
    return [_conversionService eventDateLabel:_event isStart:YES];
}
- (UIImage *)subtitleIcon {
    return [UIImage imageNamed:@"snpIconTicket"];
}
// Icon representing the type of item being displayed
-(UIImage*) titleIcon {
    return [UIImage imageNamed:@"snpIconEvent"];
}
- (PMLActionType)editActionType {
    return PMLActionTypeEditEvent;
}
// The snippet image
-(CALImage*) snippetImage {
    return [_imageService imageOrPlaceholderFor:_event allowAdditions:YES];
}
// Global theme color for element
-(UIColor*) color {
    return [UIColor whiteColor];
}

// Provider of thumb displayed in the main snippet section
-(NSObject<ThumbsPreviewProvider>*) thumbsProvider {
    return [[ItemsThumbPreviewProvider alloc] initWithParent:_event items:_event.likers moreSegueId:@"showLikers" labelKey:@"overview.event.inUser" icon:nil];
}
-(NSObject<ThumbsPreviewProvider>*) thumbsProviderFor:(ThumbPreviewMode)mode atIndex:(NSInteger)row {
    switch(mode) {
        case ThumbPreviewModeCheckins:
            return [self thumbsProvider];
        default:
            return nil;
    }
}
// Implement to say how many rows of likes need to be displayed
-(NSInteger)thumbsRowCountForMode:(ThumbPreviewMode)mode {
    switch(mode) {
        case ThumbPreviewModeCheckins:
            return 1;
        default:
            return 0;
    }
}
// Number of reviews
-(NSInteger)reviewsCount {
    return _event.reviewsCount;
}
// Number of likes
-(NSInteger)likesCount {
    return 0;
}
// Number of checkins (if applicable)
-(NSInteger)checkinsCount {
    return _event.likeCount;
}
// Description of elements
-(NSString*)descriptionText {
    return _event.miniDesc;
}
// Short text displayed with thumb
-(NSString*)thumbSubtitleText {
    return [[TogaytherService uiService] delayStringFrom:_event.startDate];
}
// Color of the short thumb subtitle text
-(UIColor*)thumbSubtitleColor {
    return [UIColor whiteColor];
}
-(NSArray*)addressComponents {
    NSArray *adrComponents = @[_event.place.title];
    NSArray *placeComponents = [_placeInfoProvider addressComponents];
    return [adrComponents arrayByAddingObjectsFromArray:placeComponents];

}
// The label of the type of element being displayed
- (NSString*)itemTypeLabel {
    return [_conversionService eventDateLabel:_event isStart:YES];
}
- (NSString*)city {
    return _event.place.cityName;
}

- (void)thumbTapped:(PMLMenuManagerController *)menuController {
    [menuController.dataManager promptUserForPhotoUploadOn:_event];
}
#pragma mark - Counters
-(NSString *)checkinsCounterTitle {
    return NSLocalizedString(@"counters.arein", @"Are in");
}
#pragma mark - Likeable
- (void)likeTapped:(CALObject *)likedObject callback:(LikeCompletionBlock)callback {
    [_likeableDelegate likeTapped:likedObject callback:callback];
}
@end
