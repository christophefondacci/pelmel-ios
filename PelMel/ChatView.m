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

    UIImageView *currentBubbleImage;
    UIImageView *currentThumb;
    UITextView *currentBubbleText;
    UIActivityIndicatorView *currentActivity;
    
    // Selecting right or left positioning
    CurrentUser *user = userService.getCurrentUser;
    if([object.key isEqualToString:user.key]) {
        currentBubbleImage = _bubbleImageSelf;
        currentThumb = _thumbImageSelf;
        currentBubbleText = _bubbleTextSelf;
        [_bubbleImage setHidden:YES];
        [_bubbleText setHidden:YES];
        [_thumbImage setHidden:YES];
        [_leftActivity setHidden:YES];
        [dateLabel setTextAlignment:NSTextAlignmentLeft];
        UIEdgeInsets insets = UIEdgeInsetsMake(27, 2, 27, 17);
        currentBubbleImage.image = [[UIImage imageNamed:@"bubble-gradient-right.png"] resizableImageWithCapInsets:insets];
        currentActivity = _rightActivity;
    } else {
        currentBubbleImage = _bubbleImage;
        currentThumb = _thumbImage;
        currentBubbleText = _bubbleText;
        [_bubbleImageSelf setHidden:YES];
        [_bubbleTextSelf setHidden:YES];
        [_thumbImageSelf setHidden:YES];
        [_rightActivity setHidden:YES];
        [dateLabel setTextAlignment:NSTextAlignmentRight];
        UIEdgeInsets insets = UIEdgeInsetsMake(27, 13, 27, 2);
        currentBubbleImage.image = [[UIImage imageNamed:@"bubble-gradient-left.png"] resizableImageWithCapInsets:insets];
        currentActivity = _leftActivity;
    }

//    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
//    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    dateLabel.text = [_uiService delayStringFrom:message.date]; //[dateFormatter stringFromDate:message.date];
    
    // Thumb image setup
    if(object.mainImage.thumbImage != nil) {
        currentThumb.image = object.mainImage.thumbImage;
        [currentActivity setHidden:YES];
    } else {
        currentThumb.image = [CALImage getDefaultUserThumb];
        [currentActivity setHidden:NO];
        [currentActivity startAnimating];
    }
    
    // Decorating thumb
    User *fromUser = (User*)message.from;
    if(fromUser.isOnline) {
        currentThumb.layer.borderColor = [_uiService colorForObject:fromUser].CGColor;
//        UIImage *decorator = [imageService getOnlineImage:fromUser.isOnline];
//        [imageService decorate:currentThumb decorator:decorator];
    }
    
    // Setting the message's textual contents
    NSString *msgText = nil;
    if(snippet && message.text.length > 70) {
        msgText = [NSString stringWithFormat:@"%@...",[message.text substringToIndex:70]];
    } else {
        msgText = message.text;
    }
    currentBubbleText.text = msgText; //[NSString stringWithFormat:@"\"%@\"",message.text];
    
    // Getting minimum height
    CGSize size = [currentBubbleText sizeThatFits:CGSizeMake(currentBubbleText.frame.size.width,FLT_MAX)];
    int minHeight = MAX(size.height,_thumbImage.frame.size.height);
    
    // Adjusting whole view
    CGRect viewFrame = self.frame;
    [self setFrame:CGRectMake(viewFrame.origin.x, viewFrame.origin.y, viewFrame.size.width, minHeight + _topTextViewConstraint.constant + _bottomTextViewConstraint.constant)];

    

}

- (Message *)getMessage {
    return _message;
}
@end
