//
//  PMLBannerEditorBehavior.m
//  PelMel
//
//  Created by Christophe Fondacci on 18/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLBannerEditorBehavior.h"
#import "TogaytherService.h"
#import "PMLBanner.h"
#import <MBProgressHUD.h>

#define kIndexOption1000 0
#define kIndexOption2500 1
#define kIndexOption6000 2
#define kIndexCancel 3

@interface PMLBannerEditorBehavior()
@property (nonatomic,retain) PMLBanner *banner;
@property (nonatomic,retain) PMLEditor *editor;
@end

@implementation PMLBannerEditorBehavior

- (BOOL)editor:(PMLEditor *)popupEditor shouldValidate:(CALObject *)object {
    PMLBanner *banner = (PMLBanner*)object;
    
    // We need a target URL or a target object
    BOOL isValid = banner.targetObject != nil || ([[banner.targetUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] > 0);
    if(!isValid) {
        [[TogaytherService uiService] alertWithTitle:@"validation.errorTitle" text:@"validation.banner.missingTarget"];
    }
    return isValid;
}

- (void)editor:(PMLEditor *)editor submitEditedObject:(CALObject *)object {
    
    // Saving as we need this in alert view callback
    self.banner = (PMLBanner*)object;
    self.editor = editor;
    PMLStoreService *storeService = [TogaytherService storeService];
    
    // First saving the banner to the server (will be in pending state)
    [[TogaytherService dataService] updateBanner:self.banner callback:^(PMLBanner *banner) {
        
        SKProduct *product1000 = [storeService productFromId:kPMLProductBanner1000];
        SKProduct *product2500 = [storeService productFromId:kPMLProductBanner2500];
        SKProduct *product6000 = [storeService productFromId:kPMLProductBanner6000];
        if(product1000 == nil || product2500 == nil || product6000 == nil) {
            [[TogaytherService storeService] loadProducts:@[kPMLProductBanner1000,kPMLProductBanner2500,kPMLProductBanner6000]];
            [[TogaytherService uiService] alertWithTitle:@"banner.store.notReadyTitle" text:@"banner.store.notReadyMsg"];
            return;
        }
        
        NSString *alertTitle = NSLocalizedString(@"banner.purchase.title", @"Select a product");
        NSString *alertMsg = NSLocalizedString(@"banner.purchase.msg", @"Select a product");
        NSString *cancel = NSLocalizedString(@"cancel", @"cancel");
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        NSString *str1000 = [numberFormatter stringFromNumber:@1000];
        NSString *str2500 = [numberFormatter stringFromNumber:@2500];
        NSString *str6000 = [numberFormatter stringFromNumber:@6000];
        NSString *price1000 = [storeService priceFromProduct:product1000];
        NSString *price2500 = [storeService priceFromProduct:product2500];
        NSString *price6000 = [storeService priceFromProduct:product6000];
        NSString *template = NSLocalizedString(@"banner.purchase.productTemplate", @"banner.purchase.productTemplate");
        NSString *option1000 = [NSString stringWithFormat:template,str1000,price1000];
        NSString *option2500 = [NSString stringWithFormat:template,str2500,price2500];
        NSString *option6000 = [NSString stringWithFormat:template,str6000,price6000];
        
        UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMsg delegate:self cancelButtonTitle:nil otherButtonTitles:option1000,option2500,option6000, cancel,nil];
        alertview.cancelButtonIndex = kIndexCancel;
        [alertview show];
        
    } failure:^(PMLBanner *banner) {
        [editor applyCancelActions];
        [MBProgressHUD hideAllHUDsForView:[[TogaytherService uiService] menuManagerController].view animated:YES];
        
    }];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch(buttonIndex) {
        case kIndexOption1000:
            self.banner.targetDisplayCount = 1000;
            self.banner.storeProductId = kPMLProductBanner1000;
            break;
        case kIndexOption2500:
            self.banner.targetDisplayCount = 2500;
            self.banner.storeProductId = kPMLProductBanner2500;
            break;
        case kIndexOption6000:
            self.banner.targetDisplayCount = 6000;
            self.banner.storeProductId = kPMLProductBanner6000;
            break;
        default:
            return;
    }
    [MBProgressHUD hideAllHUDsForView:[[TogaytherService uiService] menuManagerController].view animated:YES];
    MBProgressHUD *hud=[MBProgressHUD showHUDAddedTo:[[TogaytherService uiService] menuManagerController].view animated:YES];
    hud.labelText = NSLocalizedString(@"banner.store.payment.inprogress", @"banner.store.payment.inprogress");
    hud.mode = MBProgressHUDModeIndeterminate;
    
    // Initiating App Store payment
    [[TogaytherService storeService] startPaymentFor:self.banner];
    
    // Terminating edition
    [self.editor applyCommitActions];
    

}

@end
