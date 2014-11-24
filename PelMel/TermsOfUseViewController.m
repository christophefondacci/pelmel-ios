//
//  TermsOfUseViewController.m
//  togayther
//
//  Created by Christophe Fondacci on 25/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "TermsOfUseViewController.h"
#import "TogaytherService.h"
@interface TermsOfUseViewController ()

@end

@implementation TermsOfUseViewController
@synthesize termsText;
@synthesize scrollView;

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
    [TogaytherService applyCommonLookAndFeel:self];
    termsText.text = NSLocalizedString(_labelKey, @"Terms of use");
    self.title = NSLocalizedString(@"terms.title",@"terms.title");

}
- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:YES];

//    [termsText sizeToFit];

//    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
//        [termsText.layoutManager ensureLayoutForTextContainer:termsText.textContainer];
//        [termsText layoutIfNeeded];
//    }
    

    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
    
    CGSize textSize = [termsText sizeThatFits:CGSizeMake(screenRect.size.width, MAXFLOAT)];
    self.textHeightConstraint.constant = textSize.height+200;
    self.textWidthConstraint.constant = self.view.bounds.size.width;
    
//    CGRect frame = termsText.frame;
//    frame.size.height = MAX(termsText.contentSize.height+20,screenRect.size.height);
//    termsText.frame = frame;
//    scrollView.contentSize = frame.size;
}
- (void)viewDidUnload
{
    [self setTermsText:nil];
    [self setScrollView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
