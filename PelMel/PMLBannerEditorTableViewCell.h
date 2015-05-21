//
//  PMLBannerEditorTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 12/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PMLBanner.h"

typedef enum {
    PMLTargetTypePlace,
    PMLTargetTypeEvent,
    PMLTargetTypeURL
} PMLTargetType;

@class PMLBannerEditorTableViewCell;

@protocol PMLBannerEditorDelegate <NSObject>

/**
 * Called when the user tapped on a package button
 * @param bannerEditorCell the current cell which received the touch action
 * @param packageIndex the index of the package that has been selected
 */
-(void)bannerEditor:(PMLBannerEditorTableViewCell*)bannerEditorCell targetTypeSelected:(PMLTargetType)targetType;
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

@property (weak, nonatomic) IBOutlet UIButton *placeButton;
@property (weak, nonatomic) IBOutlet UIButton *eventButton;
@property (weak, nonatomic) IBOutlet UIButton *urlButton;

@property (weak, nonatomic) IBOutlet UIImageView *targetItemImage;
@property (weak, nonatomic) IBOutlet UILabel *targetItemLabel;
@property (weak, nonatomic) IBOutlet UITextField *targetUrlTextField;


@property (weak, nonatomic) IBOutlet UIButton *bannerUploadButton;

@property (weak, nonatomic) IBOutlet UIButton *okButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak,nonatomic) id<PMLBannerEditorDelegate> delegate;

-(void)hookActions;
-(void)refreshWithBanner:(PMLBanner*)banner;
@end
