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
#import "PMLThumbCollectionViewController.h"
#import "PMLSnippetTableViewController.h"
#import "PMLPhotosCollectionViewController.h"
#import "PMLObjectsPhotoProvider.h"

@implementation PMLContextInfoProvider {
    
    // Services
    UIService *_uiService;
    DataService *_dataService;
    ModelHolder *_modelHolder;
    
    // Controllers
    PMLSnippetTableViewController *_snippetController;
    PMLThumbCollectionViewController *_thumbController;
    
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _uiService = [TogaytherService uiService];
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
    if(_modelHolder.events.count == 0) {
        NSString *titleTemplate = @"places.section.inZone";
        title = [NSString stringWithFormat:NSLocalizedString(titleTemplate, titleTemplate),_modelHolder.totalPlacesCount];
    } else {
        NSString *titleTemplate = @"places.section.inZoneWithEvents";
        title = [NSString stringWithFormat:NSLocalizedString(titleTemplate, titleTemplate),_modelHolder.events.count,_modelHolder.totalPlacesCount];
    }
    return title;

}
- (NSString *)subtitle {
    NSString *subtitle = nil;
    if(_modelHolder.users.count>0) {
        NSString *templateCode = nil;
        if(_dataService.searchTerm==nil) {
            templateCode = @"snippet.users.count";
        } else {
            templateCode = @"snippet.users.textSearchCount";
        }
        subtitle = [_uiService localizedString:templateCode forCount:_modelHolder.totalUsersCount];
    }
    return subtitle;
}
- (UIImage *)subtitleIcon {
    return [UIImage imageNamed:@"snpIconEvent"];
}
// Icon representing the type of item being displayed
-(UIImage*) titleIcon {
//    return [UIImage imageNamed:@"snpIconBar"];
    return nil;
}
// Global theme color for element
-(UIColor*) color {
    return UIColorFromRGB(0xec7700);
}
// Provider of thumb displayed in the main snippet section
-(NSObject<PMLThumbsPreviewProvider>*) thumbsProvider {
    NSArray *objects = _modelHolder.users;
    if(objects.count==0) {
        objects = _modelHolder.places;
    }
    // Building provider
    return [[ItemsThumbPreviewProvider alloc] initWithParent:nil items:objects moreSegueId:nil labelKey:nil icon:nil];
}
- (NSObject<PMLThumbsPreviewProvider> *)thumbsProviderFor:(ThumbPreviewMode)mode atIndex:(NSInteger)row {
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
    if(_dataService.searchTerm==nil) {
        return NSLocalizedString(@"snippet.distance.intro", @"Within");
    } else {
        return [NSString stringWithFormat:@"'%@'",_dataService.searchTerm];
    }
}

- (NSString *)subtitleIntro {
    // If no textual search we display distance box
    if(_dataService.searchTerm==nil) {
        CLLocationDistance distance = 50;
        if(_dataService.currentRadius>0) {
            distance = _dataService.currentRadius;
        }
        return [[TogaytherService getConversionService] distanceStringForMeters:distance*1609.34];
    } else {
        return NSLocalizedString(@"snippet.distance.textSearch", @"snippet.distance.textSearch");
    }
}
// Color of the short thumb subtitle text
-(UIColor*)thumbSubtitleColor {
    return UIColorFromRGB(0x969696);
}
-(NSArray *)addressComponents {
    return @[];
}
- (NSArray *)activities {
    return _modelHolder.activities;
}
- (NSArray *)topPlaces {
    return _modelHolder.places;
}

- (NSObject<PMLThumbsPreviewProvider> *)likesThumbsProviderAtIndex:(NSInteger)row {
    return nil;
}
-(NSObject<PMLThumbsPreviewProvider> *)checkinsThumbsProvider {
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
- (CALImage *)imageForEvent:(Event *)event {
    if(event.mainImage != nil) {
        return event.mainImage;
    } else {
        return event.place.mainImage;
    }
}
- (BOOL)canAddPhoto {
    return NO;
}
- (BOOL)canAddEvent {
    return NO;
}
- (NSString *)eventsSectionTitle {
    return NSLocalizedString(@"snippet.title.events", @"Upcoming events");
}
-(id<PMLCountersDatasource>)countersDatasource {
    return nil;
}
- (BOOL)hasNavigation {
    return NO;
}
#pragma mark - Custom view
- (void)configureCustomViewIn:(UIView *)parentView forController:(UIViewController *)controller {
    _snippetController = (PMLSnippetTableViewController*)controller;
    // Configuring thumb controller
    if(parentView.subviews.count == 0) {
        // Initializing thumb controller
        _thumbController = (PMLThumbCollectionViewController*)[_uiService instantiateViewController:@"thumbCollectionCtrl"];
        
        // Setting up max cells
        _thumbController.hasShowMore = YES;
        
        [controller addChildViewController:_thumbController];
        [parentView addSubview:_thumbController.view];
        [_thumbController didMoveToParentViewController:controller];
    }
    // Building provider
    _thumbController.thumbProvider = [self thumbsProvider];
    _thumbController.actionDelegate = self;
    _thumbController.view.frame = parentView.bounds;
//    _thumbController.size = @30;
    [_thumbController.collectionView reloadData];

}

#pragma mark - ThumbPreviewActionDelegate
- (void)thumbsTableView:(PMLThumbCollectionViewController*)controller thumbTapped:(int)thumbIndex forThumbType:(PMLThumbType)type {
    if(type!= PMLThumbShowMore) {
        id selectedItem = [[controller.thumbProvider itemsForType:type] objectAtIndex:thumbIndex];
        [_uiService presentSnippetFor:(CALObject*)selectedItem opened:YES];
    } else {
        
        PMLPhotosCollectionViewController *photosController = (PMLPhotosCollectionViewController*)[_uiService instantiateViewController:SB_ID_PHOTOS_COLLECTION];
        NSArray *objects = _modelHolder.users.count > 0 ? _modelHolder.users : _modelHolder.places;
        PMLObjectsPhotoProvider *provider = [[PMLObjectsPhotoProvider alloc] initWithObjects:objects];
        if(_modelHolder.searchedText != nil) {
            provider.title = NSLocalizedString(@"grid.title.searchResults", @"grid.title.searchResults");
        }
        photosController.provider = provider;
        [controller.navigationController pushViewController:photosController animated:YES];
        [[[TogaytherService uiService] menuManagerController] openCurrentSnippet:YES];
    }
}
@end
