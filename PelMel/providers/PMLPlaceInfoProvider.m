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
    UIService *_uiService;
    
    // Parent controller
    PMLSnippetTableViewController *_snippetController;
    PMLPopupActionManager *_actionManager;
    
    // Main place object
    Place *_place;
    BOOL _initWithOverviewAvailable;

    // Related ingo
    Special *_bestSpecial;
    
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
        [self configureSpecials];
        [self configureAddress];
        _initWithOverviewAvailable = _place.hasOverviewData;
        
        // Initializing like behaviour
        _likeableDelegate = [[LikeableStrategyObjectWithLikers alloc] init];

    }
    return self;
}
-(void) configureSpecials {
    NSArray *specials = _place.specials;
    _bestSpecial = nil;
    for(Special *special in specials) {
        if(_bestSpecial == nil ||[special.type isEqualToString:SPECIAL_TYPE_OPENING] || [_bestSpecial.nextStart compare:special.nextStart] == NSOrderedDescending) {
            _bestSpecial = special;
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
    _thumbsProvider = [[ItemsThumbPreviewProvider alloc] initWithParent:_place items:_place.likers forType:PMLThumbsLike];
    [_thumbsProvider addItems:_place.inUsers forType:PMLThumbsCheckin];
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
    return _place.inUsers.count;
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

#pragma mark - Specials

- (BOOL)hasSnippetRightSection {
    return _bestSpecial != nil;
}
-(UIImage *)snippetRightIcon {
    Special *special = _bestSpecial;
    if(special!=nil) {
        switch([_conversionService specialModeFor:special]) {
            case CURRENT:
                return [UIImage imageNamed:@"ovvIconHours"];
            default:
                return [UIImage imageNamed:@"ovvIconHoursClosed"];
        }
    }
    return nil;
}

- (NSString *)snippetRightSubtitleText {
    Special *special = _bestSpecial;
    if(special != nil) {
        
        // If next end date is < to next start and is not yet
        switch([_conversionService specialModeFor:special]) {
            case CURRENT:
            if([special.type isEqualToString:SPECIAL_TYPE_OPENING]) {
                return NSLocalizedString(@"specials.opened", @"specials.opened");
            } else {
                return NSLocalizedString(@"specials.happy", @"specials.happy");
            }
            break;
            case SOON: {
//                NSString *deltaStr = [self getDeltaString:special.nextStart];
                return NSLocalizedString(@"specials.closed", @"specials.closed");;
            }
            default:
            return nil;
        }
    }
    return nil;
}

- (UIColor *)snippetRightColor {
    Special *special = _bestSpecial;
    switch([_conversionService specialModeFor:special]) {
        case CURRENT:
        //            return UIColorFromRGB(0xa5d170);
        return UIColorFromRGB(0x72ff00);
        case SOON:
        return UIColorFromRGB(0xffbb56);
        case PAST:
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
    if(_bestSpecial != nil) {
        SpecialMode specialMode = [_conversionService specialModeFor:_bestSpecial];
        switch(specialMode) {
            case CURRENT: {
                NSString *deltaStr = [self getDeltaString:_bestSpecial.nextEnd];
                label = [NSString stringWithFormat:NSLocalizedString(@"specials.open.leftHours",@"specials.open.leftHours"),deltaStr];
                break;
            }
            case SOON: {
                if([_bestSpecial.type isEqualToString:SPECIAL_TYPE_OPENING]) {
                    label = NSLocalizedString(@"specials.open.in",@"specials.open.in");
                } else {
                    label = NSLocalizedString(@"specials.start.in",@"specials.start.in");
                }
                NSString *deltaStr = [self getDeltaString:_bestSpecial.nextStart];
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
    for(Special *special in _place.specials) {
        Event *event = [[TogaytherService getJsonService] convertSpecial:special toEventForPlace:_place];
        if(event != nil) {
            [allEvents addObject:event];
        }
    }
    [allEvents sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        Event *e1 = (Event*)obj1;
        Event *e2 = (Event*)obj2;
        return [e1.startDate compare:e2.startDate];
    }];
    return allEvents;
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
- (id<PMLCountersDatasource>)countersDatasource:(PMLPopupActionManager *)actionManager {
    _actionManager = actionManager;
    return self;
}
- (NSString *)counterLabelAtIndex:(NSInteger)index {
    switch(index) {
        case kPMLCounterIndexLike:
            return [_uiService localizedString:@"counters.likes" forCount:_place.likeCount];
        case kPMLCounterIndexCheckin:
            return [_uiService localizedString:@"counters.checkins" forCount:_place.inUserCount];
        case kPMLCounterIndexComment:
            return [_uiService localizedString:@"counters.comments" forCount:_place.reviewsCount];
    }
    return nil;
}
- (PMLActionType)counterActionAtIndex:(NSInteger)index {
    switch(index) {
        case kPMLCounterIndexLike:
            return PMLActionTypeLike;
        case kPMLCounterIndexCheckin:
            return PMLActionTypeCheckin;
        case kPMLCounterIndexComment:
            return PMLActionTypeComment;
    }
    return PMLActionTypeNoAction;
}
- (UIColor *)counterColorAtIndex:(NSInteger)index selected:(BOOL)selected {
//    if(selected) {
//        switch(index) {
//            case kPMLCounterIndexLike:
//            case kPMLCounterIndexCheckin:
//                return UIColorFromRGB(0xffcc80);
//            default:
//                return [UIColor colorWithWhite:1 alpha:0.3];
//
//        }
//    } else {
    if(!selected) {
        switch (index) {
            case kPMLCounterIndexLike:
            case kPMLCounterIndexCheckin:
                return UIColorFromRGB(0xe9791e);
        }
    }
    return [UIColor colorWithWhite:1 alpha:0.3];
//    }
}
- (NSString *)counterActionLabelAtIndex:(NSInteger)index {
    NSString *code;
    switch(index) {
        case kPMLCounterIndexLike:
            code = _place.isLiked ? @"action.unlike" : @"action.like";
            break;
        case kPMLCounterIndexCheckin:
            code = [self isCheckedIn] ? @"action.checkout" : @"action.checkin";
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
    CurrentUser *user=[[TogaytherService userService] getCurrentUser];
    return [user.lastLocation.key isEqualToString:_place.key] && [user.lastLocationDate timeIntervalSinceNow]>-3600;
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
- (PMLPopupActionManager *)actionManager {
    return _actionManager;
}
#pragma mark Localization
-(CALObject *)mapObjectForLocalization {
    if(_place.lat!=0 && _place.lng!=0 && _place.key!=nil) {
        return _place;
    } else {
        return nil;
    }
}
@end
