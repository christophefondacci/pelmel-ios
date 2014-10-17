//
//  DescriptionEditorViewController.m
//  togayther
//
//  Created by Christophe Fondacci on 08/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "DescriptionEditorViewController.h"

@interface DescriptionEditorViewController ()

@end

@implementation DescriptionEditorViewController
@synthesize descriptionTextView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if(_editedDescription != nil) {
        descriptionTextView.text = _editedDescription.descriptionText;
    }

    [descriptionTextView becomeFirstResponder];
}

- (void)viewDidUnload
{
    [self setDescriptionTextView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    NSLog(@"Description updated");
    _editedDescription.descriptionText = textView.text;
}
@end
