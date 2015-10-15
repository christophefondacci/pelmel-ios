//
//  StoreService.h
//  PelMel
//
//  Created by Christophe Fondacci on 15/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "PMLBanner.h"
#import "UserService.h"

@interface PMLStoreService : NSObject <SKPaymentTransactionObserver,SKProductsRequestDelegate, PMLUserCallback>
@property (nonatomic,retain) UserService *userService;
- (void)loadProducts:(NSArray*)productIds;
- (SKProduct*)productFromId:(NSString*)productId;
/**
 * Starts the App Store payment for the given banner
 * @param banner the banner to pay for
 */
- (void)startPaymentFor:(PMLBanner*)banner;
/**
 * Starts the payment process for the claim a place feature
 * @param place the Place to claim
 * @param productId the productId to pay (membership type)
 */
- (void)startPaymentForClaim:(Place*)place productId:(NSString*)productId;
- (void)startPaymentForPremium:(NSString *)productId;
-(NSString*)priceFromProduct:(SKProduct *)product;
@end
