//
//  PMLSectionTitleView.h
//  PelMel
//
//  Created by Christophe Fondacci on 22/02/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMLSectionTitleView : UITableViewHeaderFooterView
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLabelWidthConstraint;
@property (weak, nonatomic) IBOutlet UIView *rightSeparator;
@property (weak, nonatomic) IBOutlet UIView *leftSeparator;
@property (weak, nonatomic) IBOutlet UIButton *primaryAction;
@property (weak, nonatomic) IBOutlet UIButton *secondaryAction;
@property (weak, nonatomic) IBOutlet UIButton *thirdAction;

/** 
 * Sets the label from the localization code and adjusts the layout
 */
- (void)setTitleLocalized:(NSString*)localizationCode;
- (void)setTitle:(NSString*)title;
/**
 * Installs the popup actions on the section
 * @param popupActions the array of PopupAction instances to install, in the order they should be displayed
 */
- (void)installPopupActions:(NSArray*)popupActions;
@end
