//
//  UserDetailProvider.m
//  togayther
//
//  Created by Christophe Fondacci on 19/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "UserDetailProvider.h"
#import "../TogaytherService.h"
#import "../MosaicListViewController.h"
#import "LikeableStrategyObjectWithLiked.h"
#import "ItemsThumbPreviewProvider.h"

@implementation UserDetailProvider {
    User *_user;
    
    ImageService *imageService;
    
    UIImage *likeIcon;
    UIImage *placeIcon;
    id<ThumbsPreviewProvider> userThumbDelegate;
    id<ThumbsPreviewProvider> placeThumbDelegate;
    
    DetailViewController *_controller;
    id<Likeable> likeableDelegate;
}

- (id)initWithUser:(User *)user
{
    self = [super init];
    if (self) {
        _user = user;
        imageService = [TogaytherService imageService];
        likeIcon = [UIImage imageNamed:@"like-button.png"];
        placeIcon = [UIImage imageNamed:@"marker-button.png"];
        userThumbDelegate = [[ItemsThumbPreviewProvider alloc] initWithParent:user items:user.likers moreSegueId:@"showLikers" labelKey:@"overview.user.likeUser" icon:likeIcon];
        placeThumbDelegate= [[ItemsThumbPreviewProvider alloc] initWithParent:user items:user.likedPlaces moreSegueId:@"showLikers" labelKey:@"overview.user.likePlace" icon:placeIcon];

        
        likeableDelegate = [[LikeableStrategyObjectWithLiked alloc] init];
    }
    return self;
}

- (CALObject *)getCALObject {
    return _user;
}
-(NSString *)getFirstDetailLine {
//    int years = [[TogaytherService getUserService] getAge:_user];
//    return [NSString stringWithFormat:NSLocalizedString(@"age", "Age"),years];
    return nil;
}
- (NSString *)getSecondDetailLine {
    NSString *msgKey = _user.isOnline ? @"user.status.online" : @"user.status.offline";
    NSString *statusLabel = NSLocalizedString(msgKey,nil);
    return statusLabel;
}
- (NSString *)getThirdDetailLine {
    if(_user.lastLocation != nil) {
        long now = [[NSDate date] timeIntervalSince1970];
        long locTime = [_user.lastLocationDate timeIntervalSince1970];
        long delta = now -locTime;
        if(delta < 60) {
            delta = 60;
        }
        NSString *timeScale;
        long value;
        if(delta < 3600 || delta > 999999999) {
            // Display in minutes
            value = delta / 60;
            timeScale = NSLocalizedString(@"user.loc.minutes", nil);
        } else if(delta < 86400) {
            // Display in hours
            value = delta / 3600;
            timeScale = NSLocalizedString(@"user.loc.hours", nil);
        } else {
            // Display in days
            value = delta / 86400;
            timeScale = NSLocalizedString(@"user.loc.days", nil);
        }
        NSString *template = NSLocalizedString(@"user.lastlocation", nil);
        NSString *line = [NSString stringWithFormat:template,_user.lastLocation.title,value,timeScale];
        return line;
    }
    return @"";
}

-(NSString *)getTitle {
    return _user.pseudo;
}
- (NSString *)getClosableBoxTitle {
    return NSLocalizedString(@"description", @"description");
}
-(NSString *)getClosableBoxText {
    return _user.miniDesc;
}
- (BOOL)hasClosableBox {
    return YES;
}
- (UIImage *)getStatusIcon {
//    NSArray *tags = _user.tags;
//    if(tags.count>0) {
//        NSString *firstTag = [tags objectAtIndex:0];
//        UIImage *tagImage = [imageService getTagImage:firstTag];
//        return tagImage;
//    } else {
//        return userIcon;
//    }
    return [imageService getOnlineImage:_user.isOnline];
}

- (id<ThumbsPreviewProvider>)getPreview1Delegate {
    return userThumbDelegate;
}
- (id<ThumbsPreviewProvider>)getPreview2Delegate {
    return placeThumbDelegate;
}
- (UIViewContentMode)getInitialViewContentMode {
    return UIViewContentModeScaleAspectFit;
}
-(void)prepareButton1:(UIButton *)button controller:(DetailViewController *)controller {
    // Setting chat icon on button
    UIImage *image= [UIImage imageNamed:@"chat-button.png"];
    [button setImage:image forState:UIControlStateNormal];
    [button setHidden:NO];
    
    // Adding button handler
    _controller = controller;
    [button addTarget:self action:@selector(chatTapped:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)chatTapped:(id)sender {
    NSLog(@"Chat touched");
    [_controller performSegueWithIdentifier:@"chat" sender:self];
}

- (void)likeTapped:(CALObject *)likedObject callback:(LikeCompletionBlock)callback {
    [likeableDelegate likeTapped:likedObject callback:callback];
}
- (UIImage *)getLikeIcon {
    return likeIcon;
}
- (BOOL)hasReviews {
    return NO;
}
-(int)reviewsCount {
    return 0;
}
-(int)likesCount {
    return (int)_user.likeCount;
}
-(int)checkinsCount {
    // TODO: not the right number here
    return (int)_user.likedPlacesCount;
}
- (void)headingBlockTapped:(DetailViewController *)controller {
    Place *place = _user.lastLocation;
    if(place != nil) {
        [controller performSegueWithIdentifier:@"showUserPlace" sender:self];
    }
}


@end
