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
        title = [NSString stringWithFormat:NSLocalizedString(titleTemplate, titleTemplate),_modelHolder.places.count];
    } else {
        NSString *titleTemplate = @"places.section.inZoneWithEvents";
        title = [NSString stringWithFormat:NSLocalizedString(titleTemplate, titleTemplate),_modelHolder.places.count,_modelHolder.events.count];
    }
    return title;

}
- (NSString *)subtitle {
    NSString *subtitle = nil;
    if(_modelHolder.users.count>0) {
         subtitle = [NSString stringWithFormat:NSLocalizedString(@"snippet.users.count","# guys nearby"),_modelHolder.users.count ];
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
- (BOOL)canAddPhoto {
    return NO;
}
- (BOOL)canAddEvent {
    return NO;
}
- (NSString *)eventsSectionTitle {
    return NSLocalizedString(@"snippet.title.events", @"Upcoming events");
}
-(id<PMLCountersDatasource>)countersDatasource:(PMLPopupActionManager *)actionManager {
    return nil;
}
#pragma mark - Custom view
- (void)configureCustomViewIn:(UIView *)parentView forController:(UIViewController *)controller {
    _snippetController = (PMLSnippetTableViewController*)controller;
    // Configuring thumb controller
    if(parentView.subviews.count == 0) {
        // Initializing thumb controller
        _thumbController = (PMLThumbCollectionViewController*)[_uiService instantiateViewController:@"thumbCollectionCtrl"];
        [controller addChildViewController:_thumbController];
        [parentView addSubview:_thumbController.view];
        [_thumbController didMoveToParentViewController:controller];
    }
    // Building provider
    _thumbController.thumbProvider = [self thumbsProvider];
    _thumbController.actionDelegate = self;
    _thumbController.view.frame = parentView.bounds;
    _thumbController.size = @30;
    [_thumbController.collectionView reloadData];

}

#pragma mark - ThumbPreviewActionDelegate
- (void)thumbsTableView:(PMLThumbCollectionViewController*)controller thumbTapped:(int)thumbIndex forThumbType:(PMLThumbType)type {
    id selectedItem = [[controller.thumbProvider itemsForType:type] objectAtIndex:thumbIndex];
    [_uiService presentSnippetFor:(CALObject*)selectedItem opened:YES];
}
@end
