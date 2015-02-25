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

@implementation PMLPlaceInfoProvider {
    
    // Services
    ConversionService *_conversionService;
    UIService *_uiService;
    
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
// Icon representing the type of item being displayed
-(UIImage*) titleIcon {
    PlaceType *placeType = [[TogaytherService settingsService] getPlaceType:_place.placeType];
    return placeType.icon;
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
-(NSObject<ThumbsPreviewProvider>*) thumbsProvider {
    _thumbsProvider = [[ItemsThumbPreviewProvider alloc] initWithParent:_place items:_place.inUsers forType:PMLThumbsCheckin];
    [_thumbsProvider addItems:_place.likers forType:PMLThumbsLike];
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
                NSString *deltaStr = [self getDeltaString:special.nextStart];
                return deltaStr;
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
            case SOON:
            if([_bestSpecial.type isEqualToString:SPECIAL_TYPE_OPENING]) {
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

-(void)thumbTapped:(PMLMenuManagerController *)menuController {
    // Prompting for upload
    [menuController.dataManager promptUserForPhotoUploadOn:_place];
}

#pragma mark - Thumbs preview management
- (NSObject<ThumbsPreviewProvider> *)thumbsProviderFor:(ThumbPreviewMode)mode atIndex:(NSInteger)row {
    switch(mode) {
        case ThumbPreviewModeLikes:
            return [self likesThumbsProviderAtIndex:row];
        case ThumbPreviewModeCheckins:
            return [self checkinsThumbsProvider];
        default:
            return [self thumbsProvider];
    }
}

- (NSObject<ThumbsPreviewProvider> *)likesThumbsProviderAtIndex:(NSInteger)row {
    ItemsThumbPreviewProvider *provider = [[ItemsThumbPreviewProvider alloc] initWithParent:_place items:_place.likers forType:PMLThumbsLike];
    [provider setIntroLabel:[NSString stringWithFormat:NSLocalizedString(@"snippet.thumbIntro.placeLikes",@"he likes"),_place.title]];
    return provider;
    
}
- (NSObject<ThumbsPreviewProvider> *)checkinsThumbsProvider {
    ItemsThumbPreviewProvider *provider = [[ItemsThumbPreviewProvider alloc] initWithParent:_place items:_place.inUsers forType:PMLThumbsCheckin];
    [provider setIntroLabel:[NSString stringWithFormat:NSLocalizedString(@"snippet.thumbIntro.placeCheckins",@"he likes"),_place.title]];
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
    return _place.events;
}
- (NSString *)eventsSectionTitle {
    return NSLocalizedString(@"snippet.title.events", @"Upcoming events");
}

#pragma mark - Likeable
- (void)likeTapped:(CALObject *)likedObject callback:(LikeCompletionBlock)callback {
    [_likeableDelegate likeTapped:likedObject callback:callback];
}
@end
