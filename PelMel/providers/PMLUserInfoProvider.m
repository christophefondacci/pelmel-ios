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
#import "LikeableStrategyObjectWithLiked.h"
#import "PMLSnippetTableViewController.h"
#import "PMLCountersView.h"
#import "UIImage+IPImageUtils.h"

@implementation PMLUserInfoProvider {
    User *_user;
    ItemsThumbPreviewProvider *_thumbsProvider;
    UIService *_uiService;
    PMLUserActionsView *_actionsView;
    PMLSnippetTableViewController *_snippetController;
    PMLPopupActionManager *_actionManager;
    id<Likeable> _likeableDelegate;
}

- (instancetype)initWithUser:(User *)user
{
    self = [super init];
    if (self) {
        _user = user;
        _uiService = TogaytherService.uiService;
        _likeableDelegate = [[LikeableStrategyObjectWithLiked alloc] init];
    }
    return self;
}
// The element being represented
-(CALObject*) item {
    return _user;
}
- (CALImage *)snippetImage {
    if(_user.mainImage != nil) {
        return _user.mainImage;
    } else {
        return [CALImage getDefaultUserCalImage];
    }
}
// Title of the element
-(NSString*) title {
    return _user.pseudo;
}
- (NSString *)subtitle {
    return _user.isOnline ? NSLocalizedString(@"user.status.online", @"online") : NSLocalizedString(@"user.status.offline",@"offline");
}
- (UIImage *)subtitleIcon {
    NSString *imageName = _user.isOnline ? @"online" : @"offline";
    return [UIImage imageNamed:imageName];
}
// Icon representing the type of item being displayed
-(UIImage*) titleIcon {
    return nil;
}
- (NSString *)itemTypeLabel {
    return [self snippetRightTitleText];
}
- (NSString *)city {
    return _user.cityName;
}
// Global theme color for element
-(UIColor*) color {
    return [self thumbSubtitleColor];
}
// Provider of thumb displayed in the main snippet section
-(NSObject<PMLThumbsPreviewProvider>*) thumbsProvider {
    _thumbsProvider = [[ItemsThumbPreviewProvider alloc] initWithParent:_user items:_user.likedPlaces forType:PMLThumbsLike];
    [_thumbsProvider addItems:_user.likers forType:PMLThumbsUserLike];
//    [_thumbsProvider addItems:_user.checkedInPlaces forType:PMLThumbsCheckin];
//    [_thumbsProvider setIntroLabelCode:@"thumbView.section.user.checkin" forType:PMLThumbsCheckin];
    [_thumbsProvider setIntroLabelCode:@"thumbView.section.user.like" forType:PMLThumbsLike];
    return _thumbsProvider;
}
- (NSObject<PMLThumbsPreviewProvider> *)thumbsProviderFor:(ThumbPreviewMode)mode atIndex:(NSInteger)row {
    switch(mode) {
        case ThumbPreviewModeLikes:
            return [self likesThumbsProviderAtIndex:row];
        case ThumbPreviewModeCheckins:
            return [self checkinsThumbsProvider];
        default:
            return nil;
    }
}
- (NSObject<PMLThumbsPreviewProvider> *)likesThumbsProviderAtIndex:(NSInteger)row {
    NSArray *items;
    NSString *labelCode;
    switch(row-1) {
        case 0:
            if(_user.likers.count>0) {
                items = _user.likers;
                labelCode =@"snippet.thumbIntro.userLikes";
            } else {
                items = _user.likedPlaces;
                labelCode = @"snippet.thumbIntro.userPlaceLikes";
            }
            break;
        case 1:
            items = _user.likedPlaces;
            labelCode = @"snippet.thumbIntro.userPlaceLikes";
            break;
    }
    
    
    ItemsThumbPreviewProvider *provider =  [[ItemsThumbPreviewProvider alloc] initWithParent:_user items:items forType:PMLThumbsLike];
    return provider;
}
- (NSInteger)thumbsRowCountForMode:(ThumbPreviewMode)mode {
    switch (mode) {
        case ThumbPreviewModeLikes:
            return [self likesThumbsRowCount];
//        case ThumbPreviewModeCheckins:
//            return _user.checkedInPlaces.count>0 ? 1 : 0;
        default:
            return 0;
    }
}
- (NSInteger)likesThumbsRowCount {
    int likeCount = _user.likers.count>0 ? 1 : 0;
    likeCount += _user.likedPlaces.count>0 ? 1 : 0;
    return likeCount;
}
- (NSObject<PMLThumbsPreviewProvider> *)checkinsThumbsProvider {
    ItemsThumbPreviewProvider *provider = [[ItemsThumbPreviewProvider alloc] initWithParent:_user items:_user.checkedInPlaces forType:PMLThumbsCheckin];
    return provider;

}
// Number of reviews
-(NSInteger)reviewsCount {
    return _user.reviewsCount;
}
// Number of likes
-(NSInteger)likesCount {
    return _user.likers.count + (int)_user.likedPlaces.count; //likeCount;
}
// Number of checkins (if applicable)
-(NSInteger)checkinsCount {
    return _user.checkedInPlaces.count;
}
// Description of elements
-(NSString*)descriptionText {
    return _user.miniDesc;
}
- (NSString *)thumbSubtitleText {
    return nil;
}
-(UIColor *)thumbSubtitleColor {
    return [_uiService colorForObject:_user];
}
- (NSArray *)addressComponents {
//    if(_user.lastLocation != nil) {
//        NSString *delayLabel = [_uiService delayStringFrom:_user.lastLocationDate];
//        
//        return @[delayLabel];
//    }
    return @[];
}
- (NSString*)addressLine2 {
    return nil;
}

- (void)snippetRightActionTapped:(UIViewController *)controller {
    
}


-(void)chatButtonTapped:(id)sender {
    MessageViewController *msgController = (MessageViewController*)[_uiService instantiateViewController:SB_ID_MESSAGES];
    msgController.withObject = _user;
    [_snippetController.navigationController pushViewController:msgController animated:YES];
}

-(void)refreshLikeButton {
    if(_user.isLiked) {
        [_actionsView.likeButton setTitle:NSLocalizedString(@"action.unlike",@"Unlike") forState:UIControlStateNormal];
    } else {
        [_actionsView.likeButton setTitle:NSLocalizedString(@"action.like",@"Like") forState:UIControlStateNormal];
    }
}
-(void)likeButtonTapped:(id)sender {
    [[TogaytherService dataService] like:_user callback:^(int likes, int dislikes,BOOL liked) {
        _user.isLiked = liked;
        [self refreshLikeButton];
    }];
}
- (NSString *)commentsCounterTitle {
    //TODO: implement message count
    return [_uiService localizedString:@"counters.chat" forCount:0];

}
#pragma mark - right section
- (BOOL)hasSnippetRightSection {
    return YES;
}
-(UIImage *)snippetRightIcon {
    return nil;
}
- (NSString *)snippetRightTitleText {
    return nil;
}
-(UIColor *)snippetRightColor {
    return [_uiService colorForObject:_user];
}
-(NSString *)snippetRightSubtitleText {
    return nil;
}

#pragma mark - Likeable
- (void)likeTapped {
    PopupAction *action = [_snippetController.actionManager actionForType:PMLActionTypeLike];
    action.actionCommand();
}
- (void)likeTapped:(CALObject *)likedObject callback:(LikeCompletionBlock)callback {
    [_likeableDelegate likeTapped:likedObject callback:callback];
}

#pragma mark - Actions
- (BOOL)canAddPhoto {
    return NO;
}
- (NSString *)actionSubtitleFor:(PMLActionType)actionType {
    switch (actionType) {
        case PMLActionTypeLike:
            if(_user.isLiked) {
                return NSLocalizedString(@"action.unlike",@"Unlike");
            } else {
                return NSLocalizedString(@"action.like",@"Like");
            }
            break;
        case PMLActionTypeComment:
            return NSLocalizedString(@"action.chat",@"Chat");
        default:
            break;
    }
    return nil;
}
- (PMLActionType)secondaryActionType {
    if(![_user.key isEqualToString:[[[TogaytherService userService] getCurrentUser] key]]) {
        return PMLActionTypeComment;
    } else {
        return -1;
    }
}
#pragma mark - PMLCounterDataSource
- (id<PMLCountersDatasource>)countersDatasource:(PMLPopupActionManager *)actionManager {
    _actionManager = actionManager;
    return self;
}
- (NSString *)counterLabelAtIndex:(NSInteger)index {
    switch(index) {
        case kPMLCounterIndexLike:
            return [_uiService localizedString:@"counters.likes.user" forCount:_user.likeCount];
        case kPMLCounterIndexCheckin:
            return nil; //[_uiService localizedString:@"counters.checkins" forCount:_user.checkedInPlacesCount];
        case kPMLCounterIndexComment:
            return nil; //[_uiService localizedString:@"counters.chat" forCount:0];
    }
    return nil;
}
- (PMLActionType)counterActionAtIndex:(NSInteger)index {
    switch(index) {
        case kPMLCounterIndexLike:
            return PMLActionTypeLike;
        case kPMLCounterIndexCheckin:
            return PMLActionTypeNoAction;
        case kPMLCounterIndexComment:
            return PMLActionTypeComment;
    }
    return PMLActionTypeNoAction;
}
- (NSString *)counterActionLabelAtIndex:(NSInteger)index {
    NSString *code;
    switch(index) {
        case kPMLCounterIndexLike:
            code = _user.isLiked ? @"action.unlike" : @"action.like";
            break;
        case kPMLCounterIndexCheckin:
            code = nil;
            break;
        case kPMLCounterIndexComment:
            code= @"counters.chat";
    }
    if(code!=nil) {
        return NSLocalizedString(code,code);
    }
    return nil;
}
- (UIColor *)counterColorAtIndex:(NSInteger)index selected:(BOOL)selected {
    if(selected) {
        switch(index) {
            case kPMLCounterIndexLike:
                return UIColorFromRGB(0xffcc80);
            default:
                return [UIColor colorWithWhite:1 alpha:0.3];
                
        }
    } else {
        switch (index) {
            case kPMLCounterIndexLike:
                return UIColorFromRGB(0xe9791e);
            default:
                return [UIColor colorWithWhite:1 alpha:0.3];
        }
    }
}
- (NSString *)counterImageNameAtIndex:(NSInteger)index {
    switch(index) {
        case kPMLCounterIndexLike:
            return PML_ICON_LIKE;
        case kPMLCounterIndexCheckin:
            return nil;// PML_ICON_CHECKIN;
        case kPMLCounterIndexComment:
            return PML_ICON_COMMENT;
    }
    return nil;
}
- (BOOL)isCounterSelectedAtIndex:(NSInteger)index {
    switch(index) {
        case kPMLCounterIndexLike:
            return _user.isLiked;
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
-(NSArray *)events {
    return _user.events;
}
- (CALImage *)imageForEvent:(Event *)event {
    if(event.mainImage != nil) {
        return event.mainImage;
    } else {
        return event.place.mainImage;
    }
}
- (NSString *)eventsSectionTitle {
    if(_user.events.count>0) {
        return NSLocalizedString(@"snippet.title.events.user", @"He will attend");
    }
    return nil;
}
-(CALObject *)mapObjectForLocalization {
    if(_user.lastLocation!=nil) {
        NSTimeInterval locationLastTime =_user.lastLocationDate.timeIntervalSince1970;
        NSTimeInterval checkinTimeout = [[NSDate new] timeIntervalSince1970]-10800;
        return locationLastTime > checkinTimeout   ? _user.lastLocation : nil;
    }
    return nil;
}
- (NSString *)localizationSectionTitle {
    return NSLocalizedString(@"snippet.title.localization.user", @"Checked in at");
}
@end
