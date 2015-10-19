//
//  PMLPremiumPurchaseProvider.m
//  PelMel
//
//  Created by Christophe Fondacci on 08/10/2015.
//  Copyright © 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLPremiumPurchaseProvider.h"
#import <StoreKit/StoreKit.h>
#import "TogaytherService.h"

@implementation PMLPremiumPurchaseProvider

- (NSString*)headerFirstLine {
    return NSLocalizedString(@"purchase.premium.header", @"purchase.premium.header");
}
- (NSString*)headerSecondLine {
    return NSLocalizedString(@"purchase.premium.headerSubtitle", @"purchase.premium.headerSubtitle");
}
- (NSString*)featureIntroLabel {
    return NSLocalizedString(@"purchase.premium.intro", @"purchase.premium.intro");
}
- (NSInteger)featuresCount {
    return 1;
}
- (NSString*)featureLabelAtIndex:(NSInteger)index {
    return NSLocalizedString(@"purchase.premium.feature.0", @"purchase.premium.feature.0");
}
- (UIImage*)featureIconAtIndex:(NSInteger)index {
    return [UIImage imageNamed:@"icoClaimDeal"];
}
- (NSString*)purchaseButtonLabel {
    NSString *title = NSLocalizedString(@"purchase.premium.button", @"purchase.premium.button");
    SKProduct *productPremium30 = [[TogaytherService storeService] productFromId:kPMLProductPremium30];
    if(productPremium30 != nil) {
        NSString *price = [[TogaytherService storeService] priceFromProduct:productPremium30];
        return [NSString stringWithFormat:title,price];
    } else {
        return [NSString stringWithFormat:title,@"n/a"];
    }
}
- (UIImage*)purchaseButtonIcon {
    return nil;
}
- (void)didTapPurchaseButton {
    [[TogaytherService storeService] startPaymentForPremium:kPMLProductPremium30];
}
- (BOOL)didCancel {
    return NO;
}

- (BOOL)freeFirstMonth {
    return NO;
}
- (void)didCompletePayment {
    [[TogaytherService uiService] alertWithTitle:@"purchase.premium.paymentCompleteTitle" text:@"purchase.premium.paymentComplete"];
}
@end
