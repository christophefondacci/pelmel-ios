//
//  StoreService.m
//  PelMel
//
//  Created by Christophe Fondacci on 15/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLStoreService.h"

@implementation PMLStoreService

- (instancetype)init {
    self = [super init];
    if (self) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}


#pragma mark SKPaymentTransactionObserver
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
}
-(void)failedTransaction:(SKPaymentTransaction*)transaction {
    NSLog(@"failedTransaction");
}
@end
