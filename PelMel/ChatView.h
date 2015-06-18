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
@property (weak, nonatomic) IBOutlet UITextView *bubbleText;
@property (weak, nonatomic) IBOutlet UIImageView *bubbleTail;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bubbleTextWidthConstraint;
@property (weak, nonatomic) IBOutlet UITextView *bubbleTextSelf;
@property (weak, nonatomic) IBOutlet UIImageView *bubbleTailSelf;
@property (weak, nonatomic) IBOutlet UIImageView *thumbImageSelf;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bubbleTextSelfWidthConstraint;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *rightActivity;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *leftActivity;
@property (weak, nonatomic) IBOutlet UIButton *detailMessageButton;
@property (weak, nonatomic) IBOutlet UIButton *leftThumbButton;
@property (weak, nonatomic) IBOutlet UIButton *rightThumbButton;
@property (weak, nonatomic) IBOutlet UILabel *leftUsernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightUsernameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *messageImage;
@property (weak, nonatomic) IBOutlet UIImageView *messageImageSelf;
@property (weak, nonatomic) IBOutlet UIImageView *chatDisclosureImage;
@property (weak, nonatomic) IBOutlet UILabel *threadNicknameLabel;
@property (strong, nonatomic) Message *message;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textBottomConstraint;
// Indicates whether this view is a template view to de-activate time-consuming operations
@property (nonatomic) BOOL isTemplate;
/**
 * Sets up the chat view for the given message and user.
 * @param message the message that will be displayed in this view
 * @param object the sender of the message
 * @param snippet whether the view is a grouped message view or not
 * @return the required height of the view
 */
- (NSInteger) setup:(Message*)message forObject:(CALObject*)object snippet:(BOOL)snippet;
- (Message*)getMessage;
@end
