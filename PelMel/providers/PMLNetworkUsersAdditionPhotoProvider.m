//
//  PMLNetworkUsersAdditionPhotoProvider.m
//  PelMel
//
//  Created by Christophe Fondacci on 15/07/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLNetworkUsersAdditionPhotoProvider.h"
#import "TogaytherService.h"
#import <MBProgressHUD.h>

@interface PMLNetworkUsersAdditionPhotoProvider()
@property (nonatomic,retain) NSMutableArray *users;
@property (nonatomic,weak) PMLPhotosCollectionViewController *controller;
@end

@implementation PMLNetworkUsersAdditionPhotoProvider

- (instancetype)init
{
    self = [super init];
    if (self) {
        CurrentUser *currentUser = [[TogaytherService userService] getCurrentUser];
        _users = [[NSMutableArray alloc] init];
        
        // Building list of non eligible user keys
        NSMutableSet *notEligibleKeys = [[NSMutableSet alloc] init];
        NSMutableArray *notEligibleUsers = [[NSMutableArray alloc] init];
        [notEligibleUsers addObjectsFromArray:currentUser.networkUsers];
        [notEligibleUsers addObjectsFromArray:currentUser.networkPendingRequests];
        [notEligibleUsers addObjectsFromArray:currentUser.networkPendingApprovals];
        
        // Comparing user keys is safest because of memory recylce issues
        for(User *user in notEligibleUsers) {
            [notEligibleKeys addObject:user.key];
        }
        [notEligibleKeys addObject:currentUser.key];
        // Building list
        for(User *user in [[[TogaytherService dataService] modelHolder] users]) {
            if(![notEligibleKeys containsObject:user.key]) {
                [_users addObject:user];
            }
        }
        _users = [[[TogaytherService uiService] sortObjectsWithImageFirst:_users] mutableCopy];
    }
    return self;
}
/**
 * The provider is expected to initialize its data, synchronously or asynchronously.
 * When the data is ready, it should call [controller updateData] to ask controller to fetch the data
 */
-(void)photoControllerStartContentLoad:(PMLPhotosCollectionViewController*)controller {
    _controller = controller;
    controller.loadFullImage=YES;
    controller.navigationController.view.layer.cornerRadius = 10;
    controller.navigationController.view.layer.masksToBounds = YES;
    controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(close:)];
    [controller updateData];
}
/**
 * Provides all objects that this provider wants to display in the photo grid
 */
-(NSArray*)objectsForSection:(NSInteger)section {
    return _users;
}
/**
 * Provides the image to display for this object
 * @param controller the photo grid controller
 * @param object the object to get the CALImage for
 * @return the CALImage to display
 */
-(CALImage*)photoController:(PMLPhotosCollectionViewController*)controller imageForObject:(NSObject*)object inSection:(NSInteger)section {
    return ((CALObject*)object).mainImage;
}
/**
 * Provides the label to display for this object
 * @param controller the photo grid controller
 * @param object the object to get the label for
 * @return the label to display below the image
 */
-(NSString*)photoController:(PMLPhotosCollectionViewController*)controller labelForObject:(NSObject*)object inSection:(NSInteger)section {
    return ((User*)object).pseudo;
}
/**
 * Asks the provider to react on a user tap on the given element
 * @param controller the photo grid controller
 * @param object the object that received the tap
 */
-(void)photoController:(PMLPhotosCollectionViewController*)controller objectTapped:(NSObject*)object inSection:(NSInteger)section {
//    [[TogaytherService actionManager] execute:PMLActionTypePrivateNetworkRequest onObject:(User*)object];
//
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:controller.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    [hud show:YES];
    [[TogaytherService userService] privateNetworkAction:PMLPrivateNetworkActionRequest withUser:(User*)object success:^(id obj) {
        [MBProgressHUD hideAllHUDsForView:controller.view animated:YES];
        [controller dismissViewControllerAnimated:YES completion:nil];
    } failure:^(id obj) {
        [MBProgressHUD hideAllHUDsForView:controller.view animated:YES];
        [[TogaytherService uiService] alertError];
    }];
}
/**
 * Provide the number of sections
 */
-(NSInteger)sectionsCount {
    return 1;
}
/**
 * The title of the view
 */
-(NSString*)title {
    return NSLocalizedString(@"grid.title.networkUsers", @"grid.title.networkUsers");
}
//@optional
-(UIImage*)defaultImageFor:(NSObject*)object {
    return [[CALImage getDefaultUserCalImage] fullImage];
}
-(UIColor*)borderColorFor:(NSObject*)object {

    User *user = (User*)object;
    if(user.isOnline) {
        UIColor *color = [[TogaytherService uiService] colorForObject:object];
        return [color colorWithAlphaComponent:0.5];
    }
    return nil;
}
-(void)photoControllerDidTapCloseMenu:(PMLPhotosCollectionViewController *)controller {
    [self.controller dismissViewControllerAnimated:YES completion:nil];
}
-(void)close:(id)sender {
    [self.controller dismissViewControllerAnimated:YES completion:nil];
}
@end
