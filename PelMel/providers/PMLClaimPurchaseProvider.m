//
//  ClaimPurchaseProvider.m
//  PelMel
//
//  Created by Christophe Fondacci on 11/08/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLClaimPurchaseProvider.h"
#import "TogaytherService.h"

#define kFeaturesCount 4
#define kFeatureStatistics 0
#define kFeatureLock 1
#define kFeatureDeals 2
#define kFeatureMessage 3

@implementation PMLClaimPurchaseProvider

- (instancetype)initWithPlace:(id)place
{
    self = [super init];
    if (self) {
        _place = place;
    }
    return self;
}
- (NSString *)headerFirstLine {
    return NSLocalizedString(@"purchase.claim.header", @"Is this your");
}
- (NSString *)headerSecondLine {
    PlaceType *placeType = [[TogaytherService settingsService] getPlaceType:_place.placeType];
    NSString *template = NSLocalizedString(@"purchase.claim.headerPlaceTypeTemplate", @"%@?");
    return [NSString stringWithFormat:template,placeType.label];
}
- (NSString *)featureIntroLabel {
    PlaceType *placeType = [[TogaytherService settingsService] getPlaceType:_place.placeType];
    NSString *template = NSLocalizedString(@"purchase.claim.intro", @"intro");
    
    return [NSString stringWithFormat:template,placeType.label];
}
- (NSString *)featureLabelAtIndex:(NSInteger)index {
    NSString *labelCode = [NSString stringWithFormat:@"purchase.claim.feature.%d",(int)index];
    return NSLocalizedString(labelCode, @"feature");
}
- (UIImage *)featureIconAtIndex:(NSInteger)index {
    return [UIImage imageNamed:@"icoBulletRibbon"];
}
- (NSInteger)featuresCount {
    return kFeaturesCount;
}

- (UIImage *)purchaseButtonIcon {
    return [UIImage imageNamed:@"icoDealKey"];
}
- (NSString *)purchaseButtonLabel {
    NSString *title = NSLocalizedString(@"purchase.claim.button", @"purchase.claim.button");
    return [NSString stringWithFormat:title,@"$19.99"];
}
- (BOOL)didCancel {
    return NO;
}
- (void)didTapPurchaseButton {
    [[TogaytherService storeService] startPaymentForClaim:_place productId:kPMLProductClaim30];
}

@end
