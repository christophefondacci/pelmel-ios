//
//  PMLPurchaseTableViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 11/08/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PMLPurchaseProvider <NSObject>

- (NSString*)headerFirstLine;
- (NSString*)headerSecondLine;
- (NSString*)featureIntroLabel;
- (NSInteger)featuresCount;
- (NSString*)featureLabelAtIndex:(NSInteger)index;
- (UIImage*)featureIconAtIndex:(NSInteger)index;
- (NSString*)purchaseButtonLabel;
- (UIImage*)purchaseButtonIcon;
- (void)didTapPurchaseButton;
- (BOOL)didCancel;
@end
@interface PMLPurchaseTableViewController : UITableViewController

@property (nonatomic,retain) id<PMLPurchaseProvider> provider;
@end
