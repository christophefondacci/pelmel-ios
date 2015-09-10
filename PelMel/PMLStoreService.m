//
//  StoreService.m
//  PelMel
//
//  Created by Christophe Fondacci on 15/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLStoreService.h"
#import "TogaytherService.h"
#import <AFNetworking.h>
#import <MBProgressHUD.h>
#define kURLUpdateBannerPayment @"%@/mobileUpdateBannerPayment"
#define kURLSubscribe @"%@/mobileSubscribe"
#define kPMLKeyPendingBannerPayment @"banner.pendingPayment"
#define kPMLKeyPendingClaimedPlacePayment @"placeClaimed.pendingPayment"

typedef enum {
    PMLPaymentTypeBanner, PMLPaymentTypeClaim
} PMLPaymentType;

@interface PMLStoreService ()

@property (nonatomic,retain) NSMutableArray *requests;
@property (nonatomic,retain) NSMutableDictionary *storeProducts;

@end

@implementation PMLStoreService {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.requests = [[NSMutableArray alloc] init];
        self.storeProducts = [[NSMutableDictionary alloc] init];
        
//        // take current payment queue
//        SKPaymentQueue* currentQueue = [SKPaymentQueue defaultQueue];
//        // finish ALL transactions in queue
//        [currentQueue.transactions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//            [currentQueue finishTransaction:(SKPaymentTransaction *)obj];
//        }];
    }
    return self;
}

- (SKProduct *)productFromId:(NSString *)productId {
    return [self.storeProducts objectForKey:productId];
}
-(void)loadProducts:(NSArray*)productIds {
    
    // First checking if we already have the definition
    NSMutableSet *productsToLoad = [[NSMutableSet alloc] init];
    for(NSString *productId in productIds) {
        // If we don't yet have this product
        if([self.storeProducts objectForKey:productId] == nil) {
            // We add it to the list of products to load from the store
            [productsToLoad addObject:productId];
        }
    }
    
    // Requesting products from Store Kit
    SKProductsRequest *skProductsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productsToLoad];
    skProductsRequest.delegate = self;
    [self.requests addObject:skProductsRequest];
    [skProductsRequest start];
}

-(void)startPaymentFor:(PMLBanner*)banner {
    
    // Retrieving banner product
    SKProduct *product = [self productFromId:banner.storeProductId];
    
    // Processing only if product loaded
    if(product != nil) {
        
        // Storing the banner for asynchronous retrieval once payment is confirmed by Apple
        [[NSUserDefaults standardUserDefaults] setObject:banner.key forKey:kPMLKeyPendingBannerPayment];
        
        // App store payment
        SKPayment *payment = [SKPayment paymentWithProduct:product];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}
- (void)startPaymentForClaim:(Place *)place productId:(NSString *)productId {
    SKProduct *product = [self productFromId:productId];
    
    if(product != nil) {
        // Storing the banner for asynchronous retrieval once payment is confirmed by Apple
        [[NSUserDefaults standardUserDefaults] setObject:place.key forKey:kPMLKeyPendingClaimedPlacePayment];
        
        // App store payment
        SKPayment *payment = [SKPayment paymentWithProduct:product];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

-(NSString*)defaultsKeyForProduct:(NSString*)productId {
    return [NSString stringWithFormat:@"bannerProduct.%@",productId ];
}

-(NSString*)priceFromProduct:(SKProduct *)product {
    if(product.price.doubleValue == 0.0f) {
        return NSLocalizedString(@"banner.price.free", @"banner.price.free");
    } else {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [formatter setLocale:product.priceLocale];
        NSString *localizedMoneyString = [formatter stringFromNumber:product.price];
        return localizedMoneyString;
    }
}

#pragma mark - SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {

    for(SKProduct *product in response.products) {
        [self.storeProducts setObject:product forKey:product.productIdentifier];
    }

    // Broadcasting notification
    [[NSNotificationCenter defaultCenter] postNotificationName:PML_NOTIFICATION_PRODUCTS_LOADED object:self];
}
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    [[TogaytherService uiService] alertWithTitle:@"banner.store.failureTitle" text:@"banner.store.failure"];
}
#pragma mark - SKPaymentTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for(SKPaymentTransaction *transaction in transactions) {
        switch(transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            default:
                break;
        }
    }
}
-(void)completeTransaction:(SKPaymentTransaction*)transaction {
    NSLog(@"completeTransaction");
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receipt = [NSData dataWithContentsOfURL:receiptURL];
    if (!receipt) {
        /* No local receipt -- handle the error. */
        NSLog(@"ERROR: No receipt");
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    } else {
        
        switch([self paymentType:transaction]) {
            case PMLPaymentTypeBanner:
                [self completeBannerPayment:transaction receipt:receipt];
                break;
            case PMLPaymentTypeClaim:
                [self completeClaimPayment:transaction receipt:receipt];
                break;
        }

    }
}
-(PMLPaymentType)paymentType:(SKPaymentTransaction*)transaction {
    if([transaction.payment.productIdentifier hasPrefix:kPMLProductBannerPrefix]) {
        return PMLPaymentTypeBanner;
    } else {
        return PMLPaymentTypeClaim;
    }
}
-(void)completeClaimPayment:(SKPaymentTransaction*)transaction receipt:(NSData*)receipt {
    // Building URL string
    NSString *serverUrl = [TogaytherService propertyFor:PML_PROP_SERVER];
    NSString *url = [NSString stringWithFormat:kURLSubscribe,serverUrl];
    
    // Current user for auth
    CurrentUser *user = [[TogaytherService userService] getCurrentUser];
    
    // Getting pending purchase
    NSString *placeKey = [[NSUserDefaults standardUserDefaults] objectForKey:kPMLKeyPendingClaimedPlacePayment];
    
    // We might be called before login so we need to check if we have a token
    if(user.token != nil) {
        // Building params list
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        [params setObject:user.token forKey:@"nxtpUserToken"];
        [params setObject:[receipt base64EncodedStringWithOptions:0] forKey:@"appStoreReceipt"];
        [params setObject:transaction.transactionIdentifier forKey:@"transactionId"];
        if(placeKey != nil) {
            [params setObject:placeKey forKey:@"subscribedKey"];
        }
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"success");
            // Parsing place response
            Place *place = [[TogaytherService getJsonService] convertJsonOverviewPlaceToPlace:(NSDictionary*)responseObject defaultPlace:nil];
            
            // Ensuring place is part of owned user places
            BOOL owned = NO;
            for(Place *ownedPlace in user.ownedPlaces) {
                if([ownedPlace.key isEqualToString:place.key]) {
                    owned = YES;
                    break;
                }
            }
            // Adding place
            if(!owned) {
                user.ownedPlaces = [user.ownedPlaces arrayByAddingObject:place];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:PML_NOTIFICATION_PAYMENT_DONE object:place];
//            [[TogaytherService uiService] alertWithTitle:@"store.claim.paymentDone.title" text:@"store.claim.paymentDone"];
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            [MBProgressHUD hideAllHUDsForView:[[TogaytherService uiService] menuManagerController].view animated:YES];
            
            // Resetting overview info
//            if(placeKey!=nil) {
//                CALObject *place = [[TogaytherService getJsonService] objectForKey:placeKey];
//                place.hasOverviewData = NO;
//                [[TogaytherService dataService] getOverviewData:place];
//            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"failure");
            [MBProgressHUD hideAllHUDsForView:[[TogaytherService uiService] menuManagerController].view animated:YES];
        }];
    }

}
-(void)completeBannerPayment:(SKPaymentTransaction*)transaction receipt:(NSData*)receipt {
    // Building URL string
    NSString *serverUrl = [TogaytherService propertyFor:PML_PROP_SERVER];
    NSString *url = [NSString stringWithFormat:kURLUpdateBannerPayment,serverUrl];
    
    // Current user for auth
    CurrentUser *user = [[TogaytherService userService] getCurrentUser];
    
    // Getting pending purchase
    NSString *bannerKey = [[NSUserDefaults standardUserDefaults] objectForKey:kPMLKeyPendingBannerPayment];
    
    if(bannerKey!=nil) {
        // We might be called before login so we need to check if we have a token
        if(user.token != nil) {
            // Building params list
            NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
            [params setObject:user.token forKey:@"nxtpUserToken"];
            [params setObject:[receipt base64EncodedStringWithOptions:0] forKey:@"appStoreReceipt"];
            [params setObject:bannerKey forKey:@"bannerKey"];
            
            AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
            [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"success");
                [[TogaytherService uiService] alertWithTitle:@"banner.store.paymentDone.title" text:@"banner.store.paymentDone"];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [MBProgressHUD hideAllHUDsForView:[[TogaytherService uiService] menuManagerController].view animated:YES];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"failure");
                [MBProgressHUD hideAllHUDsForView:[[TogaytherService uiService] menuManagerController].view animated:YES];
            }];
        }
        
    } else {
        [MBProgressHUD hideAllHUDsForView:[[TogaytherService uiService] menuManagerController].view animated:YES];
        // TODO: We should log back to the server as the client may have paid and got nothing
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }
}
-(void)failedTransaction:(SKPaymentTransaction*)transaction {
    NSLog(@"failedTransaction");
    NSString *msg = nil;
    switch([self paymentType:transaction]) {
        case PMLPaymentTypeBanner:
            msg = @"banner.store.paymentFailed";
            break;
        case PMLPaymentTypeClaim:
        default:
            msg = @"store.paymentFailed";
            break;
    }
    [[TogaytherService uiService] alertWithTitle:@"banner.store.paymentFailed.title" text:msg];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    [MBProgressHUD hideAllHUDsForView:[[TogaytherService uiService] menuManagerController].view animated:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:PML_NOTIFICATION_PAYMENT_FAILED object:self];
}

- (void)setUserService:(UserService *)userService {
    _userService = userService;
    [userService registerListener:self];
}

#pragma mark - PMLUserCallback
-(void)userAuthenticated:(CurrentUser *)user {
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

@end
