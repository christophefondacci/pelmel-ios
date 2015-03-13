//
//  PMLEventDescriptionTableViewCell.m
//  PelMel
//
//  Created by Christophe Fondacci on 13/03/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLEventDescriptionTableViewCell.h"

@implementation PMLEventDescriptionTableViewCell

- (void)awakeFromNib {
    // Initialization code
    self.descriptionTextView.delegate = self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - UITextViewDelegate
- (void)textViewDidBeginEditing:(UITextView *)textView {
    self.descriptionPlaceholderLabel.text = nil;
}

- (void)textViewDidEndEditing:(UITextView *)textView {

}

-(void)updatePlaceholder {
    if(self.descriptionTextView.text.length == 0) {
        self.descriptionPlaceholderLabel.text = NSLocalizedString(self.placeholderLocalizedCode, @"Description placeholder");
    }
}
- (void)setPlaceholderLocalizedCode:(NSString *)placeholderLocalizedCode {
    _placeholderLocalizedCode = placeholderLocalizedCode;
    [self updatePlaceholder];
}

@end
