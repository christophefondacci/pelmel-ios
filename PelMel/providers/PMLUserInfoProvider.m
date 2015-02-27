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

@implementation PMLUserInfoProvider {
    User *_user;
    ItemsThumbPreviewProvider *_thumbsProvider;
    UIService *_uiService;
    PMLUserActionsView *_actionsView;
    PMLSnippetTableViewController *_snippetController;
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
    return nil;
}
- (UIImage *)subtitleIcon {
    return nil;
}
// Icon representing the type of item being displayed
-(UIImage*) titleIcon {
    return [UIImage imageNamed:@"snpIconEvent"];
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
-(NSObject<ThumbsPreviewProvider>*) thumbsProvider {
    _thumbsProvider = [[ItemsThumbPreviewProvider alloc] initWithParent:_user items:_user.likers forType:PMLThumbsLike];
    [_thumbsProvider addItems:_user.likedPlaces forType:PMLThumbsCheckin];

    return _thumbsProvider;
}
- (NSObject<ThumbsPreviewProvider> *)thumbsProviderFor:(ThumbPreviewMode)mode atIndex:(NSInteger)row {
    switch(mode) {
        case ThumbPreviewModeLikes:
            return [self likesThumbsProviderAtIndex:row];
        case ThumbPreviewModeCheckins:
            return [self checkinsThumbsProvider];
        default:
            return nil;
    }
}
- (NSObject<ThumbsPreviewProvider> *)likesThumbsProviderAtIndex:(NSInteger)row {
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
    [provider setIntroLabel:[NSString stringWithFormat:NSLocalizedString(labelCode,@"he likes"),_user.pseudo]];
    return provider;
}
- (NSInteger)thumbsRowCountForMode:(ThumbPreviewMode)mode {
    switch (mode) {
        case ThumbPreviewModeLikes:
            return [self likesThumbsRowCount];
        case ThumbPreviewModeCheckins:
            return _user.checkedInPlaces.count>0 ? 1 : 0;
        default:
            return 0;
    }
}
- (NSInteger)likesThumbsRowCount {
    int likeCount = _user.likers.count>0 ? 1 : 0;
    likeCount += _user.likedPlaces.count>0 ? 1 : 0;
    return likeCount;
}
- (NSObject<ThumbsPreviewProvider> *)checkinsThumbsProvider {
    ItemsThumbPreviewProvider *provider = [[ItemsThumbPreviewProvider alloc] initWithParent:_user items:_user.checkedInPlaces forType:PMLThumbsCheckin];
    [provider setIntroLabel:[NSString stringWithFormat:NSLocalizedString(@"snippet.thumbIntro.userCheckins",@"he likes"),_user.pseudo]];
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
    if(_user.lastLocation != nil) {
        NSString *delayLabel = [_uiService delayStringFrom:_user.lastLocationDate];
        
        return @[delayLabel];
    }
    return @[];
}
- (NSString*)addressLine2 {
    return nil;
}

- (void)snippetRightActionTapped:(UIViewController *)controller {
    
}

//- (void)configureCustomViewIn:(UIView *)parentView forController:(UIViewController *)controller {
//    // Saving snippet controller for later
//    _snippetController = (PMLSnippetTableViewController*)controller;
//    
//    // Configuring custom view
//    if(_actionsView == nil) {
//        // Loading profile header view
//        NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"PMLUserActionsView" owner:self options:nil];
//        _actionsView = (PMLUserActionsView*)[views objectAtIndex:0];
//        [parentView addSubview:_actionsView];
//        [_actionsView.chatButton addTarget:self action:@selector(chatButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
//        [_actionsView.likeButton addTarget:self action:@selector(likeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
//        // Right aligning view
//        CGRect parentBounds = parentView.bounds;
//        CGRect actionsFrame = _actionsView.frame;
//        _actionsView.frame = CGRectMake(parentBounds.size.width-actionsFrame.size.width, actionsFrame.origin.y, actionsFrame.size.width, actionsFrame.size.height);
//    } else if(_actionsView.superview != parentView) {
//        [_actionsView removeFromSuperview];
//        [parentView addSubview:_actionsView];
//    }
//    [self refreshLikeButton];
//}

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
    return NSLocalizedString(@"counters.chat",@"Chat");
}
#pragma mark - right section
- (BOOL)hasSnippetRightSection {
    return YES;
}
-(UIImage *)snippetRightIcon {
    NSString *imageName = _user.isOnline ? @"online" : @"offline";
    return [UIImage imageNamed:imageName];
}
- (NSString *)snippetRightTitleText {
    return _user.isOnline ? NSLocalizedString(@"user.status.online", @"online") : NSLocalizedString(@"user.status.offline",@"offline");
}
-(UIColor *)snippetRightColor {
    return [_uiService colorForObject:_user];
}
-(NSString *)snippetRightSubtitleText {
    return nil;
}

#pragma mark - Likeable
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
@end
