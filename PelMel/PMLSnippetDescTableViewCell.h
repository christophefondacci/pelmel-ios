//
//  PMLSnippetDescTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 11/03/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMLSnippetDescTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet UIButton *descriptionTextViewButton;
@property (weak, nonatomic) IBOutlet UIButton *descriptionTextViewCancelButton;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLanguageLabel;

@end
