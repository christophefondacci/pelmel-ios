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
- (void)startPaymentFor:(PMLBanner*)banner;
@end
