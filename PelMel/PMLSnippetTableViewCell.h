//
//  PMLSnippetTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 30/08/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMLSnippetTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *thumbSubtitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *thumbView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UIView *peopleView;
@property (weak, nonatomic) IBOutlet UIView *colorLineView;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet UIButton *descriptionTextViewButton;
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UIView *hoursBadgeView;
@property (weak, nonatomic) IBOutlet UILabel *hoursBadgeTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *hoursBadgeSubtitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *titleDecorationImage;
@property (weak, nonatomic) IBOutlet UIImageView *hoursBadgeImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rightLabelHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rightIconHeight;

@end
