//
//  PMLDealService.h
//  PelMel
//
//  Created by Christophe Fondacci on 28/08/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PMLDeal.h"
#import "DataService.h"

@interface PMLDealService : NSObject

@property (nonatomic,retain) UserService *userService;
@property (nonatomic,retain) JsonService *jsonService;
@property (nonatomic,retain) MKNumberBadgeView *dealsBadgeView;

/**
 * Updates the deals badge based on the curren model holder definition of deals
 */
-(void)updateDealsBadge;

/**
 * Activates the deal for the given place
 * @param place the Place to activate the deal for
 * @param successCallback the completor to call when the call succeeds
 * @param errorCompletion called whenever a problem occurred (deal already activated, not owner of place, connection issues)
 */
-(void)activateDealFor:(Place*)place onSuccess:(Completor)successCallback onFailure:(ErrorCompletionBlock)errorCompletion;
-(void)updateDeal:(PMLDeal*)deal onSuccess:(Completor)successCallback onFailure:(ErrorCompletionBlock)errorCompletion;
/**
 * Uses this deal for the current user. Deal transaction will be logged and will lock any further use
 * for this user for 24hours.
 * @param deal the PMLDeal to use
 * @param successCallback the block to call upon success, the updated deal bean will be passed through
 * @param errorCompletion the block called whenever something goes wrong
 */
-(void)useDeal:(PMLDeal*)deal onSuccess:(Completor)successCallback onFailure:(ErrorCompletionBlock)errorCompletion;

/**
 * Contacts the server to get up to date deal information. Should be called before granting access to the
 * use a deal feature to avoid unnecessary sollicitations of the bartenders when deal is not available.
 * @param deal the deal to refresh
 * @param successCallback the block to call when the call succeeds, where updated PMLDeal is passed as arg
 * @param errorCompletion the block called when the call fails
 */
- (void)refreshDeal:(PMLDeal*)deal onSuccess:(Completor)successCallback onFailure:(ErrorCompletionBlock)errorCompletion;

-(NSString*)dealConditionLabel:(PMLDeal*)deal;
-(BOOL)isDealUsable:(PMLDeal*)deal considerCheckinDistance:(BOOL)checkDistance ;
@end
