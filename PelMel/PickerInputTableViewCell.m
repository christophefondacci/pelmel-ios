//
//  PickerInputTableViewCell.m
//  ShootStudio
//
//  Created by Tom Fewster on 18/10/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PickerInputTableViewCell.h"

@implementation PickerInputTableViewCell {
    UIViewController *_popoverContentController;
    BOOL _firstResponder;
}

@synthesize languageCodeLabel;
@synthesize picker;

- (void)initalizeInputView {
	self.picker = [[UIPickerView alloc] initWithFrame:CGRectZero];
	self.picker.showsSelectionIndicator = YES;
	self.picker.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	
//	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
//		_popoverContentController = [[UIViewController alloc] init];
//		_popoverContentController.view = self.picker;
//		popoverController = [[UIPopoverController alloc] initWithContentViewController:_popoverContentController];
//		popoverController.delegate = self;
//	}
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
		[self initalizeInputView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
		[self initalizeInputView];
    }
    return self;
}

- (UIView *)inputView {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return nil;
	} else {
		return self.picker;
	}
}

- (UIView *)inputAccessoryView {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return nil;
	} else {
		if (!inputAccessoryView) {
			inputAccessoryView = [[UIToolbar alloc] init];
			inputAccessoryView.barStyle = UIBarStyleBlackTranslucent;
			inputAccessoryView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
			[inputAccessoryView sizeToFit];
			CGRect frame = inputAccessoryView.frame;
			frame.size.height = 44.0f;
			inputAccessoryView.frame = frame;
			
			UIBarButtonItem *doneBtn =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
			UIBarButtonItem *flexibleSpaceLeft = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
			
			NSArray *array = [NSArray arrayWithObjects:flexibleSpaceLeft, doneBtn, nil];
			[inputAccessoryView setItems:array];
		}
		return inputAccessoryView;
	}
}

- (void)done:(id)sender {
	[self resignFirstResponder];
}

- (BOOL)becomeFirstResponder {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceDidRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && !_firstResponder) {
        _firstResponder = YES;
		CGSize pickerSize = [self.picker sizeThatFits:CGSizeZero];
		CGRect frame = self.picker.frame;
		frame.size = pickerSize;
        _popoverContentController.preferredContentSize = pickerSize;
		self.picker.frame = frame;
//		popoverController.popoverContentSize = pickerSize;
		[popoverController presentPopoverFromRect:self.detailTextLabel.frame inView:self permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		// resign the current first responder
		for (UIView *subview in self.superview.subviews) {
			if ([subview isFirstResponder]) {
				[subview resignFirstResponder];
			}
		}
		return NO;
	} else {
		[self.picker setNeedsLayout];
	}
	return [super becomeFirstResponder];
}
- (UITableView*)parentTableViewFor:(UIView*)currentView {
    // View hierarchy is not consistent between iOS 6, 7 and 8 so we browse the superview hierarchy
    // looking for the first UITableView instance we find
    UITableView *tableView = nil;
    while(tableView == nil && currentView.superview != nil) {
        currentView = currentView.superview;
        if([currentView isKindOfClass:[UITableView class]]) {
            tableView = (UITableView*)currentView;
        }
    }
    return tableView;
}
- (BOOL)resignFirstResponder {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    UITableView *tableView = [self parentTableViewFor:self];

    // Trying to unselect row
    NSIndexPath *selectedPath = self.rowPath;
    if(self.rowPath == nil) {
        if([tableView respondsToSelector:@selector(indexPathForCell:)]) {
            selectedPath = [tableView indexPathForCell:self];
        }
    }
    if(selectedPath != nil) {
        [tableView deselectRowAtIndexPath:selectedPath animated:YES];
    }
    
    _firstResponder = NO;
	return [super resignFirstResponder];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
	if (selected) {
		[self becomeFirstResponder];
	}
}

- (void)deviceDidRotate:(NSNotification*)notification {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		// we should only get this call if the popover is visible
		[popoverController presentPopoverFromRect:self.detailTextLabel.frame inView:self permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	} else {
		[self.picker setNeedsLayout];
	}
}

#pragma mark -
#pragma mark Respond to touch and become first responder.

- (BOOL)canBecomeFirstResponder {
	return YES;
}

#pragma mark -
#pragma mark UIKeyInput Protocol Methods

- (BOOL)hasText {
	return YES;
}

- (void)insertText:(NSString *)theText {
}

- (void)deleteBackward {
}

#pragma mark -
#pragma mark UIPopoverControllerDelegate Protocol Methods

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	UITableView *tableView = [self parentTableViewFor:self];
	[tableView deselectRowAtIndexPath:[tableView indexPathForCell:self] animated:YES];
	[self resignFirstResponder];
}

@end
