//
//  PMLEventDescriptionTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 13/03/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMLEventDescriptionTableViewCell : UITableViewCell <UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionPlaceholderLabel;
@property (strong, nonatomic) NSString *placeholderLocalizedCode;
@end
