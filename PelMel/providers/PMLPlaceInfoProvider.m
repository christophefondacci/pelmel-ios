//
//  PMLPlaceInfoProvider.m
//  PelMel
//
//  Created by Christophe Fondacci on 22/08/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PMLPlaceInfoProvider.h"
#import "CALObject.h"
#import "Place.h"
#import "TogaytherService.h"
#import "ItemsThumbPreviewProvider.h"
#import "LikeableStrategyObjectWithLikers.h"
#import "PMLDataManager.h"
#import "PMLCountersView.h"
#import "PMLSnippetTableViewController.h"

@implementation PMLPlaceInfoProvider {
    
    // Services
    ConversionService *_conversionService;
    SettingsService *_settingsService;
    UIService *_uiService;
    
    // Parent controller
    PMLSnippetTableViewController *_snippetController;
    
    // Main place object
    Place *_place;
    BOOL _initWithOverviewAvailable;

    // Related ingo
    PMLCalendar *_openingCalendar;
    
    // Address management
    NSArray *_addressComponents;
    
    // Strategies
    id<Likeable> _likeableDelegate;
}

- (instancetype)initWith:(id)place
{
    self = [super init];
    if (self) {
        _place = place;
        _uiService = TogaytherService.uiService;
        _conversionService = [TogaytherService getConversionService];
        _settingsService = [TogaytherService settingsService];
        [self configureOpening];
        [self configureAddress];
        _initWithOverviewAvailable = _place.hasOverviewData;
        
        // Initializing like behaviour
        _likeableDelegate = [[LikeableStrategyObjectWithLikers alloc] init];

    }
    return self;
}
-(void) configureOpening {
    _openingCalendar = nil;
    for(PMLCalendar *special in _place.hours) {
        if([special.calendarType isEqualToString:SPECIAL_TYPE_OPENING] && (_openingCalendar==nil || [_openingCalendar.startDate compare:special.startDate] == NSOrderedDescending)) {
            _openingCalendar = special;
        }
    }
}
-(void)configureAddress {
    NSMutableArray *components = [[NSMutableArray alloc] init];
    if(_place.address != nil ) {
        // Splitting address by comma
        NSArray *addrComp = [_place.address componentsSeparatedByString:@","];
        NSString *currentComponent = @"";
        for(NSString *comp in addrComp) {
            currentComponent = [currentComponent stringByAppendingString:comp];
            if(currentComponent.length>=5) {
                [components addObject:currentComponent];
                currentComponent = @"";
            }
        }
    }
    _addressComponents = components;
}
// The element being represented
-(CALObject*) item {
    return _place;
}
- (CALImage *)snippetImage {
    return [[TogaytherService imageService] imageOrPlaceholderFor:_place allowAdditions:YES ];
}
// Title of the element
-(NSString*) title {
    return _place.title;
}
- (NSString *)subtitle {
    return [self itemTypeLabel];
}
- (UIImage *)subtitleIcon {
    PlaceType *placeType = [[TogaytherService settingsService] getPlaceType:_place.placeType];
    return placeType.icon;
}
// Icon representing the type of item being displayed
-(UIImage*) titleIcon {

    return nil;
}

- (NSString *)itemTypeLabel {
    PlaceType *placeType = [[TogaytherService settingsService] getPlaceType:_place.placeType];
    return placeType.label;
}
-(NSString *)city {
    return _place.cityName;
}
// Global theme color for element
-(UIColor*) color {
    return [_uiService colorForObject:_place];
}
// Provider of thumb displayed in the main snippet section
-(NSObject<PMLThumbsPreviewProvider>*) thumbsProvider {
    _thumbsProvider = [[ItemsThumbPreviewProvider alloc] initWithParent:_place items:_place.inUsers forType:PMLThumbsCheckin];
    NSArray *likers = [_uiService sortObjectsForDisplay:_place.likers];
    [_thumbsProvider addItems:likers forType:PMLThumbsLike];
    return _thumbsProvider;
}


// Number of reviews
-(NSInteger)reviewsCount {
    return _place.reviewsCount;
}
// Number of likes
-(NSInteger)likesCount {
    return _place.likeCount;
}
// Number of checkins (if applicable)
-(NSInteger)checkinsCount {
    return _place.inUserCount;
}
// Description of elements
-(NSString*)descriptionText {
    return _place.miniDesc;
}
- (NSString *)thumbSubtitleText {
    return [TogaytherService.getConversionService distanceTo:_place];
}
-(UIColor *)thumbSubtitleColor {
    return [UIColor whiteColor];
}

-(NSArray *)addressComponents {
    if(_initWithOverviewAvailable != _place.hasOverviewData) {
        [self configureAddress];
    }
    return _addressComponents;
}

- (NSArray *)properties {
    return _place.properties;
}

#pragma mark - Specials

- (BOOL)hasSnippetRightSection {
    return _openingCalendar != nil;
}
-(UIImage *)snippetRightIcon {
    if(_openingCalendar!=nil) {
        switch([_conversionService eventStartStateFor:_openingCalendar]) {
            case PMLEventStateCurrent:
                return [UIImage imageNamed:@"ovvIconHours"];
            default:
                return [UIImage imageNamed:@"ovvIconHoursClosed"];
        }
    }
    return nil;
}

- (NSString *)snippetRightSubtitleText {
    if(_openingCalendar != nil) {
        
        // If next end date is < to next start and is not yet
        switch([_conversionService eventStartStateFor:_openingCalendar]) {
            case PMLEventStateCurrent:
                return NSLocalizedString(@"specials.opened", @"specials.opened");
            case PMLEventStateSoon:
                return NSLocalizedString(@"specials.closed", @"specials.closed");;
            default:
            return nil;
        }
        
    }
    return nil;
}

- (UIColor *)snippetRightColor {
    switch([_conversionService eventStartStateFor:_openingCalendar]) {
        case PMLEventStateCurrent:
        //            return UIColorFromRGB(0xa5d170);
        return UIColorFromRGB(0x72ff00);
        case PMLEventStateSoon:
        return UIColorFromRGB(0xffbb56);
        case PMLEventStatePast:
        return [UIColor clearColor]; //UIColorFromRGB(0xc5595d);
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

- (NSString *)snippetRightTitleText {
    NSString *label = nil;
    if(_openingCalendar != nil) {
        PMLEventState specialMode = [_conversionService eventStartStateFor:_openingCalendar];
        switch(specialMode) {
            case PMLEventStateCurrent: {
                NSString *deltaStr = [self getDeltaString:_openingCalendar.endDate];
                label = [NSString stringWithFormat:NSLocalizedString(@"specials.open.leftHours",@"specials.open.leftHours"),deltaStr];
                break;
            }
            case PMLEventStateSoon: {
                label = NSLocalizedString(@"specials.open.in",@"specials.open.in");
                NSString *deltaStr = [self getDeltaString:_openingCalendar.startDate];
                label = [NSString stringWithFormat:@"%@ %@",label,deltaStr];
                break;
            }
            default:
                label = nil;
                break;
        }
    }
    return label;
}

-(void)thumbTapped:(PMLMenuManagerController *)menuController {
    // Prompting for upload
    [menuController.dataManager promptUserForPhotoUploadOn:_place];
}

#pragma mark - Thumbs preview management
- (NSObject<PMLThumbsPreviewProvider> *)thumbsProviderFor:(ThumbPreviewMode)mode atIndex:(NSInteger)row {
    switch(mode) {
        case ThumbPreviewModeLikes:
            return [self likesThumbsProviderAtIndex:row];
        case ThumbPreviewModeCheckins:
            return [self checkinsThumbsProvider];
        default:
            return [self thumbsProvider];
    }
}

- (NSObject<PMLThumbsPreviewProvider> *)likesThumbsProviderAtIndex:(NSInteger)row {
    ItemsThumbPreviewProvider *provider = [[ItemsThumbPreviewProvider alloc] initWithParent:_place items:_place.likers forType:PMLThumbsLike];
    return provider;
    
}
- (NSObject<PMLThumbsPreviewProvider> *)checkinsThumbsProvider {
    ItemsThumbPreviewProvider *provider = [[ItemsThumbPreviewProvider alloc] initWithParent:_place items:_place.inUsers forType:PMLThumbsCheckin];
    return provider;
}

-(NSInteger)thumbsRowCountForMode:(ThumbPreviewMode)mode {
    switch (mode) {
        case ThumbPreviewModeLikes:
            return _place.likers.count>0 ? 1 : 0;
        case ThumbPreviewModeCheckins:
            return _place.inUsers.count>0 ? 1:0;
        default:
            return 0;
    }
}
- (NSArray *)events {
    NSMutableArray *allEvents = [_place.events mutableCopy];

    for(PMLCalendar *special in _place.hours) {
//        Event *event = [[TogaytherService getJsonService] convertSpecial:special toEventForPlace:_place];
//        if(event != nil) {
        if(![special.calendarType isEqualToString:SPECIAL_TYPE_OPENING]) {
            [allEvents addObject:special];
        }
    }
    [allEvents sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        Event *e1 = (Event*)obj1;
        Event *e2 = (Event*)obj2;
        return [e1.startDate compare:e2.startDate];
    }];
    return allEvents;
}
- (BOOL)canAddEvent {
    return YES;
}
- (BOOL)canAddPhoto {
    return YES;
}
- (NSString *)eventsSectionTitle {
    return NSLocalizedString(@"snippet.title.events", @"Upcoming events");
}

#pragma mark - Likeable
- (void)likeTapped:(CALObject *)likedObject callback:(LikeCompletionBlock)callback {
    [_likeableDelegate likeTapped:likedObject callback:callback];
}

#pragma mark - Actions

- (PMLActionType)editActionType {
    return PMLActionTypeEditPlace;
}
- (PMLActionType)primaryActionType {
    return PMLActionTypeNoAction;
}
- (PMLActionType)secondaryActionType {
    CLLocationDistance distance = [_conversionService numericDistanceTo:_place];
    if(distance < kPMLCheckinDistanceMeters) {
        return PMLActionTypeCheckin;
    } else {
        return -1;
    }
}
- (NSString *)actionSubtitleFor:(PMLActionType)actionType {
    switch (actionType) {
        case PMLActionTypeLike:
            if(_place.isLiked) {
                return NSLocalizedString(@"action.unlike",@"Unlike");
            } else {
                return NSLocalizedString(@"action.like",@"Like");
            }
            break;
        case PMLActionTypeCheckin:
            return NSLocalizedString(@"action.checkin",@"Checkin");
        default:
            break;
    }
    return nil;
}
#pragma mark - PMLCounterDataSource
- (id<PMLCountersDatasource>)countersDatasource {
    return self;
}
- (NSString *)counterLabelAtIndex:(NSInteger)index {
    switch(index) {
        case kPMLCounterIndexLike:
            return [_uiService localizedString:@"counters.likes" forCount:_place.likeCount];
        case kPMLCounterIndexCheckin:
            if([self isCheckinEnabled]) {
                return [_uiService localizedString:@"counters.checkins" forCount:_place.inUserCount];
            } else {
                return nil;
            }
        case kPMLCounterIndexComment:
            return [_uiService localizedString:@"counters.comments" forCount:_place.reviewsCount];
    }
    return nil;
}
-(BOOL)isCheckinEnabled {
    return [self isCheckedIn] ||[_settingsService isCheckinEnabledFor:_place];
}
- (PMLActionType)counterActionAtIndex:(NSInteger)index {
    switch(index) {
        case kPMLCounterIndexLike:
            return PMLActionTypeLike;
        case kPMLCounterIndexCheckin:
            if([self isCheckinEnabled]) {
                if(![self isCheckedIn]) {
                    // Second help hint when the user is less than 100 meters away
                    if([_conversionService numericDistanceTo:_place]<=100) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:PML_HELP_CHECKIN_CLOSE object:self];
                    }
                }
                return PMLActionTypeCheckin;
            } else {
                return PMLActionTypeNoAction;
            }
        case kPMLCounterIndexComment:
            return PMLActionTypeComment;
    }
    return PMLActionTypeNoAction;
}
//- (UIColor *)counterColorAtIndex:(NSInteger)index selected:(BOOL)selected {
//    if(!selected) {
//        switch (index) {
//            case kPMLCounterIndexLike:
//            case kPMLCounterIndexCheckin:
//                return UIColorFromRGB(0xe9791e);
//        }
//    }
//    return [UIColor colorWithWhite:1 alpha:0.3];
//}
- (NSString *)counterActionLabelAtIndex:(NSInteger)index {
    NSString *code;
    switch(index) {
        case kPMLCounterIndexLike:
            code = _place.isLiked ? @"action.unlike" : @"action.like";
            break;
        case kPMLCounterIndexCheckin:
            if([self isCheckinEnabled]) {
                code = [self isCheckedIn] ? @"action.checkout" : @"action.checkin";
            } else {
                return nil;
            }
            break;
        case kPMLCounterIndexComment:
            code= @"action.comment";
    }
    if(code!=nil) {
        return NSLocalizedString(code,code);
    }
    return nil;
}
-(BOOL)isCheckedIn {
    return [[TogaytherService userService] isCheckedInAt:_place];
}
- (BOOL)isCounterSelectedAtIndex:(NSInteger)index {
    switch(index) {
        case kPMLCounterIndexLike:
            return _place.isLiked;
        case kPMLCounterIndexCheckin:
            return [self isCheckedIn];
        case kPMLCounterIndexComment:
            // TODO return selected when messages with user
            return NO;
    }
    return NO;
}

-(CALObject *)counterObject {
    return _place;
}


#pragma mark Localization
-(CALObject *)mapObjectForLocalization {
    if(_place.lat!=0 && _place.lng!=0 && _place.key!=nil) {
        return _place;
    } else {
        return nil;
    }
}
#pragma mark Report
- (NSInteger)footerButtonsCount {
    return 2;
}
- (PMLActionType)footerButtonActionAtIndex:(NSInteger)buttonIndex {
    switch(buttonIndex) {
        case 0:
            return PMLActionTypeClaim;
        case 1:
            return PMLActionTypeReport;
    }
    return PMLActionTypeNoAction;
}
- (UIImage *)footerButtonIconAtIndex:(NSInteger)buttonIndex {
    switch(buttonIndex) {
        case 0:
        case 1:
            return [UIImage imageNamed:@"snpButtonReport"];
    }
        return PMLActionTypeNoAction;

}
- (NSString *)footerButtonTextAtIndex:(NSInteger)buttonIndex {
    switch(buttonIndex) {
        case 0:
            return NSLocalizedString(@"snippet.button.claim", @"Claim this place");
        case 1:
            return NSLocalizedString(@"snippet.button.report", @"Report a problem");
    }
    return nil;
}
- (UIColor *)footerButtonColorAtIndex:(NSInteger)buttonIndex {
    switch(buttonIndex) {
        case 0:
            return nil;
        case 1:
            return UIColorFromRGBAlpha(0xc50000,0.2);
    }
    return nil;
}

-(PMLActionType)advertisingActionType {
    return PMLActionTypeAddBanner;
}
@end
