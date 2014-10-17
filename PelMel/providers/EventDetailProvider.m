//
//  EventDetailProvider.m
//  togayther
//
//  Created by Christophe Fondacci on 20/12/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "EventDetailProvider.h"
#import "TogaytherService.h"
#import "MosaicListViewController.h"
#import "LikeableStrategyObjectWithLikers.h"
#import "PlaceDetailProvider.h"
#import "ItemsThumbPreviewProvider.h"

@implementation EventDetailProvider {
    ImageService *imageService;
    
    Event *_event;
    NSDateFormatter *dateFormatter;
    UIImage *placeIcon;
    UIImage *likeIcon;
    UIImage *localizationIcon;
    id<ThumbsPreviewProvider> thumbComersDelegate;
    id<ThumbsPreviewProvider> thumbPlaceDelegate;
    
    id<Likeable> likeableDelegate;
    
    DetailViewController *detailController;
}

- (id)initWithEvent:(Event *)event {
    self = [super init];
    if (self) {
        imageService = [TogaytherService imageService];
        _event = event;
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"dd MMMM yyyy HH:mm";
        likeIcon = [UIImage imageNamed:@"like-button.png"];
        placeIcon = [UIImage imageNamed:@"marker-button.png"];
        localizationIcon = [UIImage imageNamed:@"date-marker.png"];
        thumbComersDelegate = [[ItemsThumbPreviewProvider alloc] initWithParent:event items:event.likers moreSegueId:@"showLikers" labelKey:@"overview.event.inUser" icon:likeIcon];
        NSArray *placesArray = [NSArray arrayWithObject:event.place];
        thumbPlaceDelegate = [[ItemsThumbPreviewProvider alloc] initWithParent:event items:placesArray moreSegueId:nil labelKey:@"overview.event.place" icon:placeIcon];
        likeableDelegate = [[LikeableStrategyObjectWithLikers alloc] init];
    }
    return self;
}

- (CALObject *)getCALObject {
    return _event;
}
- (NSString *)getTitle {
    return _event.name;
}
- (NSString *)getSecondDetailLine {
    return [dateFormatter stringFromDate:_event.startDate];
}
- (NSString *)getFirstDetailLine {
    Place *place = _event.place;
    if(place != nil) {
        return [NSString stringWithFormat:@"@ %@",place.title];
    }
    return nil;
}
- (NSString *)getClosableBoxTitle {
    return NSLocalizedString(@"description", @"Description title");
}
- (BOOL)hasClosableBox {
    return YES;
}
- (NSString *)getClosableBoxText {
    return _event.miniDesc;
}
- (UIImage *)getStatusIcon {
    return nil;
}
- (UIImage *)getLikeIcon {
    return likeIcon;
}
- (id<ThumbsPreviewProvider>)getPreview1Delegate {
    return thumbComersDelegate;
}
- (NSString *)getThirdDetailLine {
    return @"";
}
-(id<ThumbsPreviewProvider>)getPreview2Delegate {
    return thumbPlaceDelegate;
}
-(UIViewContentMode)getInitialViewContentMode {
    return UIViewContentModeScaleToFill;
}
- (void)prepareButton1:(UIButton *)button controller:(DetailViewController *)controller {
    // Initializing camera events
    [imageService registerTappable:button forViewController:controller callback:self];
    UIImage *image = [UIImage imageNamed:@"camera-button.png"];
    [button setImage:image forState:UIControlStateNormal];
    [button setHidden:NO];
    detailController = controller;
}


- (void)likeTapped:(CALObject *)likedObject callback:(LikeCompletionBlock)callback {
    [likeableDelegate likeTapped:likedObject callback:callback];
}
- (BOOL)hasReviews {
    return YES;
}
- (int)reviewsCount {
    return (int)_event.reviews.count;
}
- (void)headingBlockTapped:(DetailViewController *)controller {
    
}
-(int)likesCount {
    return (int)_event.likeCount;
}
-(int)checkinsCount {
    return 0;
}

#pragma mark - TappableCallback
- (void)imagePicked:(CALImage *)image {
    // Setting title
    detailController.title = NSLocalizedString(@"photos.uploading", @"Uploading wait message");
    
    // Uploading
    [imageService upload:image forObject:detailController.detailItem callback:detailController];

}
@end
