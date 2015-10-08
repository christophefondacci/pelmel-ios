//
//  PMLPrivateNetworkPhotoProvider.m
//  PelMel
//
//  Created by Christophe Fondacci on 03/07/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLPrivateNetworkPhotoProvider.h"
#import "TogaytherService.h"
#import "PMLNetworkUsersAdditionPhotoProvider.h"

#define kSectionCount 4
#define kSectionActions 0
#define kSectionToApprove 1
#define kSectionMyNetwork 2
#define kSectionPendingRequests 3

@interface PMLPrivateNetworkPhotoProvider()
@property (nonatomic,retain) UserService *userService;
@property (nonatomic,weak) PMLPhotosCollectionViewController *controller;
@end

@implementation PMLPrivateNetworkPhotoProvider

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.userService = [TogaytherService userService];
    }
    return self;
}
-(void)photoControllerStartContentLoad:(PMLPhotosCollectionViewController*)controller {
    _controller = controller;
    controller.loadFullImage=YES;
    [controller updateData];
}
/**
 * Provides all objects that this provider wants to display in the photo grid
 */
-(NSArray*)objectsForSection:(NSInteger)section {
    CurrentUser *user = [_userService getCurrentUser];
    switch(section) {
        case kSectionActions:
            return user.networkUsers.count>0 ? @[[NSNumber numberWithInt:PMLActionTypeGroupChat]] : nil;
        case kSectionToApprove:
            return user.networkPendingApprovals;
        case kSectionPendingRequests:
            return user.networkPendingRequests;
        case kSectionMyNetwork:
            return user.networkUsers;
            
    }
    return nil;
}

-(PMLActionType)actionFromObject:(NSObject*)object {
    // Unwrapping action type
    PMLActionType actionType = ((NSNumber*)object).intValue;

    return actionType;
}
/**
 * Provides the image to display for this object
 * @param controller the photo grid controller
 * @param object the object to get the CALImage for
 * @return the CALImage to display
 */
-(CALImage*)photoController:(PMLPhotosCollectionViewController*)controller imageForObject:(NSObject*)object inSection:(NSInteger)section {
    
    // Actions specific
    if(section == kSectionActions) {
        
        // Unwrapping action type
        PMLActionType actionType = [self actionFromObject:object];
        
        // Selecting tile image
        if(actionType == PMLActionTypeGroupChat) {
            return [CALImage calImageWithImage:[UIImage imageNamed:@"btnThumbChat"]];
        }
        return nil;
    } else {
        
        // Default is the main CAL image
        return ((CALObject*)object).mainImage;
    }
}
/**
 * Provides the label to display for this object
 * @param controller the photo grid controller
 * @param object the object to get the label for
 * @return the label to display below the image
 */
-(NSString*)photoController:(PMLPhotosCollectionViewController*)controller labelForObject:(NSObject*)object inSection:(NSInteger)section {
    if(section == kSectionActions) {
        // Unwrapping action type
        PMLActionType actionType = [self actionFromObject:object];
        if(actionType == PMLActionTypeGroupChat) {
            return NSLocalizedString(@"grid.action.groupChat", @"grid.action.groupChat");
        }
        return nil;
    } else {
        return ((User*)object).pseudo;
    }
}
/**
 * Asks the provider to react on a user tap on the given element
 * @param controller the photo grid controller
 * @param object the object that received the tap
 */
-(void)photoController:(PMLPhotosCollectionViewController*)controller objectTapped:(NSObject*)object inSection:(NSInteger)section {
    
    if(section == kSectionActions) {
        
        // Unwrapping action type
        PMLActionType actionType = [self actionFromObject:object];
        
        // Executing action on network users
        [[TogaytherService actionManager] execute:actionType onObject:[_userService getCurrentUser]];
    } else {
        [[TogaytherService uiService] presentSnippetFor:(CALObject*)object opened:YES];
    }

}
/**
 * Provide the number of sections
 */
-(NSInteger)sectionsCount {
    return kSectionCount;
}
/**
 * The title of the view
 */
-(NSString*)title {
    return NSLocalizedString(@"grid.title.privateNetwork", @"grid.title.privateNetwork");
}
/**
 * Whether or not an element could be added to the given section. If implemented and returning YES then a
 * "plus" button will be appended to this section. Tapping this button will call the other method photoController:addToSectionTapped
 * @param section the section index
 */
-(BOOL)canAddToSection:(NSInteger)section {
    return section == kSectionMyNetwork;
}
/**
 * Called when the "add" button of a section has been tapped.
 * @param controller the current PMLPhotosCollectionViewController
 * @param section the section index
 */
-(void)photoController:(PMLPhotosCollectionViewController*)controller didTapAddToSection:(NSInteger)section {

    [[TogaytherService actionManager] execute:PMLActionTypePrivateNetworkAddUsers onObject:nil];
}

/**
 * Notifies that the user has tapped the close menu button
 */
-(void)photoControllerDidTapCloseMenu:(PMLPhotosCollectionViewController*)controller {
    [[TogaytherService uiService] popNavigationToMenuManager];
//    [[[TogaytherService uiService] menuManagerController] dismissControllerSnippet];
    [[TogaytherService uiService] presentSnippetFor:nil opened:NO root:YES];
}
/**
 * The label of the title for this section
 * @param section number of the section to get a title for
 * @return the section title
 */
-(NSString*)labelForSection:(NSInteger)section {
    switch(section) {
        case kSectionToApprove:
            return NSLocalizedString(@"grid.section.networkApprovals", @"To approve");
        case kSectionPendingRequests:
            return NSLocalizedString(@"grid.section.networkRequests", @"grid.section.networkRequests");
        case kSectionMyNetwork:
            return NSLocalizedString(@"grid.section.networkUsers", @"grid.section.networkUsers");
    }
    return nil;
}
/**
 * Icon of the section title
 * @param sectionCount number of the section for which we need an icon
 * @return the UIImage for the icon
 */
-(UIImage*)iconForSection:(NSInteger)section {
    switch(section) {
        case kSectionMyNetwork:
            return [UIImage imageNamed:@"icoNetworkMember"];
        case kSectionPendingRequests:
            return [UIImage imageNamed:@"icoNetworkRequested"];
        case kSectionToApprove:
            return [UIImage imageNamed:@"icoNetworkAwaiting"];
    }
    return nil;
}
-(UIImage*)defaultImageFor:(NSObject*)object {
    return [[CALImage getDefaultUserCalImage] fullImage];
}

-(void)controllerWillDealloc:(PMLPhotosCollectionViewController *)controller {
    _controller= nil;
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
