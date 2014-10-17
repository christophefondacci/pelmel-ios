//
//  ShootStatusInputTableViewCell.h
//  ShootStudio
//
//  Created by Tom Fewster on 18/10/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PickerInputTableViewCell;


@interface PickerInputTableViewCell : UITableViewCell <UIKeyInput, UIPopoverControllerDelegate> {
	// For iPad
	UIPopoverController *popoverController;
	UIToolbar *inputAccessoryView;
}

@property (weak, nonatomic) IBOutlet UILabel *languageCodeLabel;
@property (nonatomic, strong) UIPickerView *picker;
@property (nonatomic, weak) NSIndexPath *rowPath;

@end
