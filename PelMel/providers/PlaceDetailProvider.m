//
//  PlaceDetailProvider.m
//  togayther
//
//  Created by Christophe Fondacci on 18/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "PlaceDetailProvider.h"
#import "../TogaytherService.h"
#import "../MosaicListViewController.h"
#import "LikeableStrategyObjectWithLikers.h"
#import "ItemsThumbPreviewProvider.h"
#import "Constants.h"

@implementation PlaceDetailProvider {
    Place *_place;
    DataService *_dataService;
    SettingsService *_settingsService;
    ImageService *_imageService;
    UIImage *localizationIcon;
    UIImage *likeIcon;
    UIImage *userIcon;
    UIImage *eventIcon;
    ItemsThumbPreviewProvider *delegateEvents;
    ItemsThumbPreviewProvider *delegateLikers;
    ItemsThumbPreviewProvider *delegateInUsers;
    DetailViewController *_controller;
    
    id<Likeable> likeableDelegate;
    
}

- (id)initWithPlace:(Place *)place {
    self = [super init];
    if (self) {
        _place = place;
        _dataService = [TogaytherService dataService];
        _settingsService = [TogaytherService settingsService];
        _imageService = [TogaytherService imageService];
        
        // Initializing icons
        localizationIcon = [UIImage imageNamed:@"place-marker.png"];
        likeIcon = [UIImage imageNamed:@"like-button.png"];
        userIcon = [UIImage imageNamed:@"user-button.png"];
        eventIcon =[UIImage imageNamed:@"calendar-button.png"];
        
        // Setting up delegates (we don't know yet which one we should show)
        delegateEvents = [[ItemsThumbPreviewProvider alloc] initWithParent:place items:_place.events moreSegueId:nil labelKey:@"overview.events" icon:eventIcon];
        delegateInUsers= [[ItemsThumbPreviewProvider alloc] initWithParent:place items:_place.inUsers moreSegueId:@"showGuys" labelKey:@"overview.inUser" icon:userIcon];
        delegateLikers = [[ItemsThumbPreviewProvider alloc] initWithParent:place items:_place.likers moreSegueId:@"showLikers" labelKey:@"overview.likeUser" icon:likeIcon];
        
        // Initializing like behaviour
        likeableDelegate = [[LikeableStrategyObjectWithLikers alloc] init];

    }
    return self;
}

-(NSString *)getTitle {
    return _place.title;
}
- (NSString *)getFirstDetailLine {
    return [TogaytherService.getConversionService distanceTo:_place];
}

- (NSString *)getSecondDetailLine {
    PlaceType *placeType = [_settingsService getPlaceType:_place.placeType];
    return placeType.label;
}

- (NSString *)getThirdDetailLine {
    return _place.address;
}

- (UIImage *)getStatusIcon {
    return nil;
}
- (UIImage *)getLikeIcon {
    return likeIcon;
}
- (BOOL)hasClosableBox {
    return YES;
}
- (NSString *)getClosableBoxTitle {
    return NSLocalizedString(@"description", @"Description title");
}
- (NSString *)getClosableBoxText {
    return _place.miniDesc;
}
- (id<ThumbsPreviewProvider>)getPreview1Delegate {
    if(_place.events!=nil && _place.events.count>0) {
        return delegateEvents;
    } else {
        return delegateLikers;
    }
}
- (id<ThumbsPreviewProvider>)getPreview2Delegate {
    if(_place.events!=nil && _place.events.count>0) {
        if(_place.inUsers.count>0) {
            return delegateInUsers;
        } else {
            return delegateLikers;
        }
    } else {
        return delegateInUsers;
    }
}
- (CALObject *)getCALObject {
    return _place;
}
-(UIViewContentMode)getInitialViewContentMode {
    return UIViewContentModeScaleAspectFit; //UIViewContentModeScaleToFill;
}
- (void)prepareButton1:(UIButton *)button controller:(DetailViewController *)controller {
    // Initializing camera events
    [_imageService registerTappable:button forViewController:controller callback:self];
    UIImage *image = [UIImage imageNamed:@"camera-button.png"];
    [button setImage:image forState:UIControlStateNormal];
    [button setHidden:NO];
    _controller = controller;
}

- (void)imagePicked:(CALImage *)image {
    // Setting title
    _controller.title = NSLocalizedString(@"photos.uploading", @"Uploading wait message");
    
    // Uploading
    [_imageService upload:image forObject:_controller.detailItem callback:_controller];
}

- (void)likeTapped:(CALObject *)likedObject callback:(LikeCompletionBlock)callback {
    [likeableDelegate likeTapped:likedObject callback:callback];
}

- (BOOL)hasReviews {
    return YES;
}

- (int)reviewsCount {
    return (int)_place.reviewsCount;
}
- (int)checkinsCount {
    if(_place.inUserCount>0) {
        // Preparing for when server will provide this info
        return (int)_place.inUserCount;
    } else {
        return (int)_place.inUsers.count;
    }
}
- (int)likesCount {
    return (int)_place.likeCount;
}
- (void)headingBlockTapped:(DetailViewController *)controller {
    if(controller.splitViewController==nil) {
        [controller performSegueWithIdentifier:@"seeOnAMap" sender:self];
    }
}

- (NSString *)getFourthDetailLine {
    NSMutableString *buffer = [[NSMutableString alloc] init];
    NSString *sep = @"";
    for(Special *special in _place.specials) {
        if([SPECIAL_TYPE_OPENING isEqualToString:special.type]) {
            [buffer appendFormat:@"%@%@",sep,special.descriptionText];
            sep = @" / ";
        }
    }
    return buffer;
}
@end
