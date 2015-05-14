//
//  PMLBannerEditorTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 12/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PMLBannerEditorTableViewCell;

@protocol PMLBannerEditorDelegate <NSObject>

/**
 * Called when the user tapped on a package button
 * @param bannerEditorCell the current cell which received the touch action
 * @param packageIndex the index of the package that has been selected
 */
-(void)bannerEditor:(PMLBannerEditorTableViewCell*)bannerEditorCell packageSelected:(NSInteger)packageIndex;
/**
 * Ok button tapped
 * @param bannerEditorCell the current cell
 */
-(void)bannerEditorDidTapOk:(PMLBannerEditorTableViewCell*)bannerEditorCell;
/**
 * Cancel button tapped
 * @param bannerEditorCell the current cell
 */
-(void)bannerEditorDidTapCancel:(PMLBannerEditorTableViewCell*)bannerEditorCell;
@end
@interface PMLBannerEditorTableViewCell : UITableViewCell <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *displaysLabel;
@property (weak, nonatomic) IBOutlet UILabel *targetLabel;
@property (weak, nonatomic) IBOutlet UIView *firstDisplayPackageContainer;
@property (weak, nonatomic) IBOutlet UILabel *firstDisplayPackageCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *firstDisplayPackagePriceLabel;

@property (weak, nonatomic) IBOutlet UIView *secondDisplayPackageContainer;
@property (weak, nonatomic) IBOutlet UILabel *secondDisplayPackageCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondDisplayPackagePriceLabel;

@property (weak, nonatomic) IBOutlet UIView *thirdDisplayPackageContainer;
@property (weak, nonatomic) IBOutlet UILabel *thirdDisplayPackageCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *thirdDisplayPackagePriceLabel;

@property (weak, nonatomic) IBOutlet UIImageView *targetItemImage;
@property (weak, nonatomic) IBOutlet UILabel *targetItemLabel;
@property (weak, nonatomic) IBOutlet UITextField *targetUrlTextField;


@property (weak, nonatomic) IBOutlet UIButton *bannerUploadButton;

@property (weak, nonatomic) IBOutlet UIButton *okButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak,nonatomic) id<PMLBannerEditorDelegate> delegate;

-(void)hookActions;
@end
