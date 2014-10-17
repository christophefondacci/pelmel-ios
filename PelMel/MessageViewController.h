//
//  MessageViewController.h
//  togayther
//
//  Created by Christophe Fondacci on 29/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CALObject.h"
#import "MessageService.h"
#import "ImageService.h"
#import "HPGrowingTextView.h"

@interface MessageViewController : UIViewController <MessageCallback, UITextFieldDelegate,HPGrowingTextViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong,nonatomic) CALObject *withObject;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *activityText;
@property (weak, nonatomic) IBOutlet UIButton *activityBackground;
@property (weak, nonatomic) IBOutlet UIView *footerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomTextInputConstraint;

@end
