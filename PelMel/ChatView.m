//
//  ChatView.m
//  togayther
//
//  Created by Christophe Fondacci on 29/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "ChatView.h"
#import "TogaytherService.h"

@implementation ChatView {
    Message *_message;
    CALObject *_currentObject;
    UserService *userService;
    ImageService *imageService;
    UIService *_uiService;
}
@synthesize dateLabel;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)setup:(Message *)message forObject:(CALObject *)object snippet:(BOOL)snippet {
    _message = message;
    _currentObject = object;
    // Initialization code
    userService = [TogaytherService userService];
    imageService = [TogaytherService imageService];
    _uiService = [TogaytherService uiService];

    UIImageView *currentThumb;
    UITextView *currentBubbleText;
    UILabel *currentUsernameLabel;
    UIImageView *currentMessageImage;
    UIActivityIndicatorView *currentActivity;
    
    // Selecting right or left positioning
    CurrentUser *user = userService.getCurrentUser;
    if([object.key isEqualToString:user.key]) {
        currentThumb = _thumbImageSelf;
        currentBubbleText = _bubbleTextSelf;
        currentUsernameLabel = _rightUsernameLabel;
        [_bubbleText setHidden:YES];
        [_thumbImage setHidden:YES];
        [_leftActivity setHidden:YES];
        [_leftUsernameLabel setHidden:YES];
        [_rightUsernameLabel setHidden:YES];
        [_messageImage setHidden:YES];
        [dateLabel setTextAlignment:NSTextAlignmentLeft];
        currentActivity = _rightActivity;
        currentMessageImage = _messageImageSelf;
    } else {
        currentThumb = _thumbImage;
        currentBubbleText = _bubbleText;
        currentUsernameLabel = _leftUsernameLabel;
        [_bubbleTextSelf setHidden:YES];
        [_thumbImageSelf setHidden:YES];
        [_rightActivity setHidden:YES];
        [_rightUsernameLabel setHidden:YES];
        [_messageImageSelf setHidden:YES];
        [dateLabel setTextAlignment:NSTextAlignmentRight];
        currentActivity = _leftActivity;
        currentMessageImage = _messageImage;
    }
    
    dateLabel.text = [_uiService delayStringFrom:message.date]; //[dateFormatter stringFromDate:message.date];
    
    // Thumb image setup
    if(object.mainImage.thumbImage != nil) {
        currentThumb.image = object.mainImage.thumbImage;
        [currentActivity setHidden:YES];
    } else {
        if(object == nil) {
            currentThumb.image = [UIImage imageNamed:@"logoMob"];
            currentThumb.contentMode = UIViewContentModeScaleAspectFit;
        } else {
            currentThumb.image = [CALImage getDefaultUserThumb];
        }
        [currentActivity setHidden:NO];
        [currentActivity startAnimating];
    }
    
    // Decorating thumb
    User *fromUser = (User*)message.from;
    if(fromUser.isOnline) {
        currentThumb.layer.borderColor = [_uiService colorForObject:fromUser].CGColor;
    }
    currentUsernameLabel.text = fromUser.pseudo;
    
    // Setting the message's textual contents
    NSString *msgText = nil;
    if(snippet && message.text.length > 70) {
        msgText = [NSString stringWithFormat:@"%@...",[message.text substringToIndex:70]];
    } else {
        msgText = message.text;
    }
    currentBubbleText.text = msgText; //[NSString stringWithFormat:@"\"%@\"",message.text];
    
    // Setting the message's image content
    CALImage *image = message.mainImage;
    if(image != nil) {
        currentMessageImage.hidden=NO;
        currentBubbleText.hidden=YES;
        [[TogaytherService imageService] load:image to:currentMessageImage thumb:NO];
    } else {
        currentMessageImage.hidden=YES;
    }
    
    // Getting minimum height
    CGSize size = [currentBubbleText sizeThatFits:CGSizeMake(currentBubbleText.frame.size.width,FLT_MAX)];
    int minHeight = MAX(size.height,_thumbImage.frame.size.height);
    if(image!=nil) {
        minHeight = MAX(currentMessageImage.bounds.size.height,minHeight);
    }
    _textHeightConstraint.constant = minHeight+1; // Adding 1 for fractional height !!
}

- (Message *)getMessage {
    return _message;
}
@end
