//
//  PMLUserInfoProvider.m
//  PelMel
//
//  Created by Christophe Fondacci on 22/08/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PMLUserInfoProvider.h"
#import "ItemsThumbPreviewProvider.h"
#import "TogaytherService.h"
#import "MessageViewController.h"
#import "PMLUserActionsView.h"

@implementation PMLUserInfoProvider {
    User *_user;
    ItemsThumbPreviewProvider *_thumbsProvider;
    UIService *_uiService;
    PMLUserActionsView *_actionsView;
}

- (instancetype)initWithUser:(User *)user
{
    self = [super init];
    if (self) {
        _user = user;
        _uiService = TogaytherService.uiService;

    }
    return self;
}
// The element being represented
-(CALObject*) item {
    return _user;
}
- (CALImage *)snippetImage {
    return _user.mainImage;
}
// Title of the element
-(NSString*) title {
    return _user.pseudo;
}
// Icon representing the type of item being displayed
-(UIImage*) titleIcon {
    return [UIImage imageNamed:@"snpIconEvent"];
}
// Global theme color for element
-(UIColor*) color {
    return [self thumbSubtitleColor];
}
// Provider of thumb displayed in the main snippet section
-(NSObject<ThumbsPreviewProvider>*) thumbsProvider {
    _thumbsProvider = [[ItemsThumbPreviewProvider alloc] initWithParent:_user items:_user.likers forType:PMLThumbsLike];
    [_thumbsProvider addItems:_user.likedPlaces forType:PMLThumbsCheckin];

    return _thumbsProvider;
}
- (NSObject<ThumbsPreviewProvider> *)likesThumbsProvider {
    return [[ItemsThumbPreviewProvider alloc] initWithParent:_user items:_user.likers forType:PMLThumbsLike];
}
- (NSObject<ThumbsPreviewProvider> *)checkinsThumbsProvider {
    return [[ItemsThumbPreviewProvider alloc] initWithParent:_user items:_user.likedPlaces forType:PMLThumbsCheckin];
}
// Number of reviews
-(int)reviewsCount {
    return (int)_user.reviewsCount;
}
// Number of likes
-(int)likesCount {
    return (int)_user.likeCount;
}
// Number of checkins (if applicable)
-(int)checkinsCount {
    return (int)_user.likedPlacesCount;
}
// Description of elements
-(NSString*)descriptionText {
    return _user.miniDesc;
}
- (NSString *)thumbSubtitleText {
    return _user.isOnline ? NSLocalizedString(@"user.status.online", @"online") : NSLocalizedString(@"user.status.offline",@"offline");
}
-(UIColor *)thumbSubtitleColor {
    return [_uiService colorForObject:_user];
}
- (NSArray *)addressComponents {
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
        return @[line];
    }
    return @[];
}
- (NSString*)addressLine2 {
    return nil;
}

- (BOOL)hasSnippetRightSection {
    return YES;
}
-(UIImage *)snippetRightIcon {
    return [UIImage imageNamed:@"mnuIconMessage"];
}
- (NSString *)snippetRightTitleText {
    return nil;
}
-(NSString *)snippetRightSubtitleText {
    return nil;
}
-(UIColor *)snippetRightColor {
    return UIColorFromRGB(0xa8a7a5);
}

- (void)snippetRightActionTapped:(UIViewController *)controller {
    MessageViewController *msgController = (MessageViewController*)[_uiService instantiateViewController:SB_ID_MESSAGES];
    msgController.withObject = _user;
    [controller.navigationController pushViewController:msgController animated:YES];
}

- (void)configureCustomViewIn:(UIView *)parentView {
    if(_actionsView == nil) {
        // Loading profile header view
        NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"PMLUserActionsView" owner:self options:nil];
        _actionsView = (PMLUserActionsView*)[views objectAtIndex:0];
        [parentView addSubview:_actionsView];
    } else if(_actionsView.superview != parentView) {
        [_actionsView removeFromSuperview];
        [parentView addSubview:_actionsView];
    }
    
}
@end
