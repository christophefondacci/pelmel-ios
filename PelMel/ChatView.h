//
//  ChatView.h
//  togayther
//
//  Created by Christophe Fondacci on 29/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CALObject.h"
#import "Message.h"

@interface ChatView : UIView
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIImageView *thumbImage;
@property (weak, nonatomic) IBOutlet UIImageView *bubbleImage;
@property (weak, nonatomic) IBOutlet UITextView *bubbleText;
@property (weak, nonatomic) IBOutlet UIImageView *bubbleImageSelf;
@property (weak, nonatomic) IBOutlet UITextView *bubbleTextSelf;
@property (weak, nonatomic) IBOutlet UIImageView *thumbImageSelf;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *rightActivity;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *leftActivity;
@property (weak, nonatomic) IBOutlet UIButton *detailMessageButton;
@property (weak, nonatomic) IBOutlet UIButton *leftThumbButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topTextViewConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomTextViewConstraint;
- (void) setup:(Message*)message forObject:(CALObject*)object snippet:(BOOL)snippet;
- (Message*)getMessage;
@end
