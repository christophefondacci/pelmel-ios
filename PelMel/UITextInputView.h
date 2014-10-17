//
//  UITextInputView.h
//  PelMel
//
//  Created by Christophe Fondacci on 27/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextInputView : UIView

@property (weak, nonatomic) IBOutlet UILabel *inputTitleLabel;
@property (weak, nonatomic) IBOutlet UITextField *inputText;
@property (weak, nonatomic) IBOutlet UIButton *inputButton;

@end
