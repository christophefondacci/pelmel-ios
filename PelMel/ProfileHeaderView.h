//
//  ProfileHeaderView.h
//  nativeTest
//
//  Created by Christophe Fondacci on 05/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageService.h"

@interface ProfileHeaderView : UIView
@property (weak, nonatomic) IBOutlet UILabel *pseudoLabel;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UIView *profileImageOutline;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nicknameLabelWidthConstraint;


@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIImageView *editButtonIcon;

/**
 * Sets the nickname to display while ensuring proper sizing of constraints for centering the edit icon
 */
-(void)setNickname:(NSString*)nickname parentWidth:(NSInteger)width;

@end
