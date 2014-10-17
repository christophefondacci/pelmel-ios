//
//  TermsOfUseViewController.h
//  togayther
//
//  Created by Christophe Fondacci on 25/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TermsOfUseViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextView *termsText;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) NSString *labelKey;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textWidthConstraint;


@end
