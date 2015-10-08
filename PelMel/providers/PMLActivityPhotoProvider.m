//
//  PMLActivityPhotoProvider.m
//  PelMel
//
//  Created by Christophe Fondacci on 03/06/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLActivityPhotoProvider.h"
#import "TogaytherService.h"
#import "PMLSnippetTableViewController.h"

@interface PMLActivityPhotoProvider()
@property (nonatomic,retain) NSString* activityType;
@property (nonatomic,retain) NSArray* activities;
@property (nonatomic,retain) PMLPhotosCollectionViewController *controller;
@end

@implementation PMLActivityPhotoProvider

- (instancetype)initWithActivityType:(NSString *)activityType
{
    self = [super init];
    if (self) {
        self.activityType = activityType;
    }
    return self;
}

- (void)photoControllerStartContentLoad:(PMLPhotosCollectionViewController *)controller {
    self.controller = controller;
    controller.loadFullImage=YES;
    [[TogaytherService getMessageService] getNearbyActivitiesFor:self.activityType hd:YES callback:self];
}

- (CALImage *)photoController:(PMLPhotosCollectionViewController *)controller imageForObject:(NSObject *)object inSection:(NSInteger)section{
    return ((Activity*)object).extraImage;
}

- (NSString *)photoController:(PMLPhotosCollectionViewController *)controller labelForObject:(NSObject *)object inSection:(NSInteger)section {
    return [[TogaytherService uiService] delayStringFrom:((Activity*)object).activityDate];
}
- (void)photoController:(PMLPhotosCollectionViewController *)controller objectTapped:(NSObject *)object inSection:(NSInteger)section{
    PMLSnippetTableViewController *snippetController = (PMLSnippetTableViewController*)[[TogaytherService uiService] instantiateViewController:SB_ID_SNIPPET_CONTROLLER];
    snippetController.snippetItem = ((Activity*)object).activityObject;
    [controller.navigationController pushViewController:snippetController animated:YES];
}
-(NSArray *)objectsForSection:(NSInteger)section {
    if(section == 0) {
        return self.activities;
    }
    return 0;
}
- (NSInteger)sectionsCount {
    return 1;
}
- (NSString *)title {
    return NSLocalizedString(@"activity.title.photoGrid", @"activity.title.photoGrid");
}
-(void)photoControllerDidTapCloseMenu:(PMLPhotosCollectionViewController *)controller {
//    [controller.parentMenuController dismissControllerSnippet];
    [[TogaytherService uiService] presentSnippetFor:nil opened:NO];
}
#pragma mark - ActivitiesCallback

-(void)activityFetched:(NSArray *)activities {
    self.activities = activities;
    [self.controller updateData];
}
-(void)activityFetchFailed:(NSString *)errorMessage {
    [[TogaytherService uiService] alertError];
}

@end
