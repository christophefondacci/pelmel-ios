//
//  PMLBannerEditorTableViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 12/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PMLBannerEditorTableViewCell.h"
#import "PMLBanner.h"
#import "ImageService.h"
#import <StoreKit/StoreKit.h>

@interface PMLBannerEditorTableViewController : UITableViewController <PMLBannerEditorDelegate, PMLImagePickerCallback, UITextFieldDelegate, SKProductsRequestDelegate>

@property (nonatomic,retain) PMLBanner *banner;
@end
