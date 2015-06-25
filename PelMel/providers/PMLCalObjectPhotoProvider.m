
//
//  PMLCalObjectPhotoProvider.m
//  PelMel
//
//  Created by Christophe Fondacci on 03/06/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLCalObjectPhotoProvider.h"
#import "PhotoPreviewViewController.h"
#import "TogaytherService.h"


#define kSectionPhotos 0
#define kSectionLikers 1
#define kSectionLikedPlaces 2

@interface PMLCalObjectPhotoProvider()
@property (nonatomic,retain) UIService *uiService;
@property (nonatomic,retain) CALObject *object;
@property (nonatomic,retain) NSArray *likers;
@property (nonatomic,retain) NSArray *likedPlaces;
@property (nonatomic,retain) NSMutableArray *images;
@property (nonatomic,retain) id<PMLInfoProvider> infoProvider;
@property (nonatomic,weak) PMLPhotosCollectionViewController *controller;

@end

@implementation PMLCalObjectPhotoProvider

- (instancetype)initWithObject:(CALObject *)object 
{
    self = [super init];
    if (self) {
        self.uiService = [TogaytherService uiService];
        self.object = object;
        // Listening to data changes
        [[TogaytherService dataService] registerDataListener:self];
    }
    return self;
}
- (void)setObject:(CALObject *)object {
    _object = object;
    self.infoProvider = [self.uiService infoProviderFor:object];
    self.likers = [self.uiService sortObjectsWithImageFirst:object.likers];
    if([object isKindOfClass:[User class]]) {
        self.likedPlaces = [self.uiService sortObjectsWithImageFirst:((User*)object).likedPlaces];
    }
    // Building an array with all images
    self.images = [[NSMutableArray alloc] init];
    if(self.object.mainImage != nil) {
        [self.images addObject:self.object.mainImage];
    }
    for(CALImage *image in self.object.otherImages) {
        [self.images addObject:image];
    }
}
- (NSString *)title {
    return [self.infoProvider title];
}
- (void)photoControllerStartContentLoad:(PMLPhotosCollectionViewController *)controller {
    self.controller = controller;
    controller.loadFullImage = YES;
    // Everything is ready from the beginning
    [controller updateData];
}
- (NSArray *)objectsForSection:(NSInteger)section {
    switch(section) {
        case kSectionPhotos:
            return self.images;
        case kSectionLikers:
            return self.likers;
        case kSectionLikedPlaces:
            return self.likedPlaces;
    }
    return nil;
}

- (CALImage *)photoController:(PMLPhotosCollectionViewController *)controller imageForObject:(NSObject *)object inSection:(NSInteger)section {
    switch(section) {
        case kSectionPhotos:
            return (CALImage*)object;
        case kSectionLikers:
        case kSectionLikedPlaces:
            return ((CALObject*)object).mainImage;
    }
    return nil;
}
- (NSString *)photoController:(PMLPhotosCollectionViewController *)controller labelForObject:(NSObject *)object inSection:(NSInteger)section{
    switch(section) {
        case kSectionPhotos:
            return nil;
        case kSectionLikers:
            return ((User*)object).pseudo;
        case kSectionLikedPlaces:
            return ((Place*)object).title;
    }
    return nil;
    
}
- (void)photoController:(PMLPhotosCollectionViewController *)controller objectTapped:(NSObject *)object inSection:(NSInteger)section {

    switch(section) {
        case kSectionPhotos: {
            PhotoPreviewViewController *photoController = (PhotoPreviewViewController*)[[TogaytherService uiService] instantiateViewController:SB_ID_PHOTO_GALLERY];
            photoController.currentImage = (CALImage*)object;
            photoController.imaged = self.object;
            
            [controller.navigationController pushViewController:photoController animated:YES];
            break;
        }
        case kSectionLikedPlaces:
        case kSectionLikers: {
            [[TogaytherService uiService] presentSnippetFor:(CALObject*)object opened:YES];
        }
            
    }
}
-(void)photoControllerDidTapCloseMenu:(PMLPhotosCollectionViewController *)controller {
    [controller.navigationController popViewControllerAnimated:YES];
    [controller.parentMenuController minimizeCurrentSnippet:YES];
}
- (NSInteger)sectionsCount {
//    NSInteger sections = 1;
//    if(self.likers.count>0) {
//        sections++;
//    }
//    if(self.likedPlaces.count>0) {
//        sections++;
//    }
    return 3;
}
- (NSString *)labelForSection:(NSInteger)sectionCount {
    switch(sectionCount) {
        case kSectionPhotos:
            return NSLocalizedString(@"profile.photo.header",@"Photos");
        case kSectionLikers:
            if(self.likers.count>0) {
                if([self.object isKindOfClass:[User class]]) {
                    return NSLocalizedString(@"thumbView.section.user.likeUser", @"He likes");
                } else {
                    return NSLocalizedString(@"thumbView.section.like", @"thumbView.section.like");
                }
            } else {
                return nil;
            }
            break;
        case kSectionLikedPlaces:
            if(self.likedPlaces.count>0) {
                return NSLocalizedString(@"thumbView.section.user.like", @"Hangouts he likes");
            }
            
            
    }
    return nil;
}
- (UIImage *)iconForSection:(NSInteger)sectionCount {
    switch(sectionCount) {
        case kSectionPhotos:
            return [UIImage imageNamed:@"chatButtonAddPhoto"];
            break;
        case kSectionLikers:
            return [UIImage imageNamed:@"snpIconLikeWhite"];
        case kSectionLikedPlaces:
            return [UIImage imageNamed:@"snpIconEvent"];
    }
    return nil;
}
- (void)controllerWillDealloc:(PMLPhotosCollectionViewController *)controller {
    [[TogaytherService dataService] unregisterDataListener:self];
}
- (UIColor *)borderColorFor:(NSObject *)object {
    if([object isKindOfClass:[User class]]) {
        User *user = (User*)object;
        if(user.isOnline) {
            UIColor *color = [[TogaytherService uiService] colorForObject:object];
            return [color colorWithAlphaComponent:0.5];
        }
    }
    return nil;
}
#pragma mark - PMLDataListener
- (void)didLoadOverviewData:(CALObject *)object {
    if([object.key isEqualToString:self.object.key]) {
        [self setObject:object];
        [self.controller updateData];
    }
}
@end
