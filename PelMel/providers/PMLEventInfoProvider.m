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
    PMLPopupActionManager *_actionManager;
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
    return nil;
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
-(NSObject<PMLThumbsPreviewProvider>*) thumbsProvider {
    return [[ItemsThumbPreviewProvider alloc] initWithParent:_event items:_event.likers forType:PMLThumbsUsersInEvent];
}
-(NSObject<PMLThumbsPreviewProvider>*) thumbsProviderFor:(ThumbPreviewMode)mode atIndex:(NSInteger)row {
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
    return [_uiService localizedString:@"counters.arein" forCount:_event.likeCount];
}
#pragma mark - Likeable
- (void)likeTapped:(CALObject *)likedObject callback:(LikeCompletionBlock)callback {
    [_likeableDelegate likeTapped:likedObject callback:callback];
}

#pragma mark - Actions
- (PMLActionType)editActionType {
    return PMLActionTypeEditEvent;
}
- (PMLActionType)primaryActionType {
    if([_event isLiked]) {
        return PMLActionTypeAttendCancel;
    } else {
        return PMLActionTypeAttend;
    }
}
- (NSString *)actionSubtitleFor:(PMLActionType)actionType {
    switch (actionType) {
        case PMLActionTypeAttend:
            return NSLocalizedString(@"action.attend",@"Attend");
            break;
        case PMLActionTypeAttendCancel:
            return NSLocalizedString(@"cancel",@"Cancel");
        default:
            break;
    }
    return nil;
}
#pragma mark - PMLCounterDataSource
- (id<PMLCountersDatasource>)countersDatasource:(PMLPopupActionManager *)actionManager {
    _actionManager = actionManager;
    return self;
}
- (NSString *)counterLabelAtIndex:(NSInteger)index {
    switch(index) {
        case kPMLCounterIndexLike:
            return [_uiService localizedString:@"counters.arein" forCount:_event.likeCount];
        case kPMLCounterIndexCheckin:
            return nil;
        case kPMLCounterIndexComment:
            return [_uiService localizedString:@"counters.comments" forCount:_event.reviewsCount];
    }
    return nil;
}
- (PMLActionType)counterActionAtIndex:(NSInteger)index {
    switch(index) {
        case kPMLCounterIndexLike:
            return PMLActionTypeAttend;
        case kPMLCounterIndexCheckin:
            return PMLActionTypeNoAction;
        case kPMLCounterIndexComment:
            return PMLActionTypeComment;
    }
    return PMLActionTypeNoAction;
}
- (BOOL)isCounterSelectedAtIndex:(NSInteger)index {
    switch(index) {
        case kPMLCounterIndexLike:
            return _event.isLiked;
        case kPMLCounterIndexCheckin:
            return NO;
        case kPMLCounterIndexComment:
            // TODO return selected when messages with user
            return NO;
    }
    return NO;
}
- (PMLPopupActionManager *)actionManager {
    return _actionManager;
}
@end
