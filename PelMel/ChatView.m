//
//  ChatView.m
//  togayther
//
//  Created by Christophe Fondacci on 29/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "ChatView.h"
#import "TogaytherService.h"
#import "PMLManagedRecipientsGroupUser.h"

@implementation ChatView {
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

- (NSInteger)setup:(Message *)message forObject:(CALObject *)object snippet:(BOOL)snippet {
    _message = message;
    _currentObject = object;
    // Initialization code
    userService = [TogaytherService userService];
    imageService = [TogaytherService imageService];
    _uiService = [TogaytherService uiService];
    CALObject *fromUser = message.from;
    
    UIImageView *currentThumb;
    UITextView *currentBubbleText;
    UILabel *currentUsernameLabel;
    UIImageView *currentMessageImage;
    UIActivityIndicatorView *currentActivity;
    NSLayoutConstraint *textWidthConstraint;
    
    // Selecting right or left positioning
    CurrentUser *user = userService.getCurrentUser;
    UIColor *bubbleColor;

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
        [_bubbleTextSelf setHidden:NO];
        [_thumbImageSelf setHidden:NO];
        [_rightActivity setHidden:NO];
        [_rightUsernameLabel setHidden:NO];
        [_messageImageSelf setHidden:NO];
        [dateLabel setTextAlignment:NSTextAlignmentRight];
        currentActivity = _rightActivity;
        currentMessageImage = _messageImageSelf;
        bubbleColor = UIColorFromRGB(0x057efe);
        currentMessageImage.layer.borderColor = [bubbleColor CGColor];
        currentBubbleText.textColor = UIColorFromRGB(0xffffff);
        self.bubbleTailSelf.hidden=NO;
        self.bubbleTail.hidden=YES;
        textWidthConstraint = _bubbleTextSelfWidthConstraint;
    } else {
        currentThumb = _thumbImage;
        currentBubbleText = _bubbleText;
        currentUsernameLabel = _leftUsernameLabel;
        [_bubbleTextSelf setHidden:YES];
        [_thumbImageSelf setHidden:YES];
        [_rightActivity setHidden:YES];
        [_rightUsernameLabel setHidden:YES];
        [_messageImageSelf setHidden:YES];
        [_rightUsernameLabel setHidden:YES];
        [_bubbleText setHidden:NO];
        [_thumbImage setHidden:NO];
        [_leftActivity setHidden:NO];
        [_leftUsernameLabel setHidden:NO];
        [_rightThumbButton setHidden:YES];
        
        [_messageImage setHidden:NO];
        [dateLabel setTextAlignment:NSTextAlignmentLeft];
        currentActivity = _leftActivity;
        currentMessageImage = _messageImage;
        bubbleColor = UIColorFromRGB(0xe5e5e5);
        currentMessageImage.layer.borderColor = [bubbleColor CGColor];
        if(!snippet) {
            currentBubbleText.textColor = UIColorFromRGB(0x0);
        }
        self.bubbleTailSelf.hidden=YES;
        self.bubbleTail.hidden=NO;
        textWidthConstraint = _bubbleTextWidthConstraint;
    }
    if(!self.isTemplate) {
        if(snippet) {
            self.bubbleTailSelf.hidden=YES;
            self.bubbleTail.hidden=YES;
        }
        dateLabel.text = [_uiService delayStringFrom:message.date]; //[dateFormatter stringFromDate:message.date];
        
        // Thumb image setup
        currentThumb.alpha=1;
        if(object.mainImage.thumbImage != nil) {
            currentThumb.image = object.mainImage.thumbImage;
            [currentActivity setHidden:YES];
        } else {
            if(object == nil) {
                if(message.recipientsGroupKey == nil) {
                    currentThumb.image = [UIImage imageNamed:@"logoMob"];
                } else {
                    currentThumb.image = [UIImage imageNamed:@"imgChatGroup"];
                    currentThumb.alpha=0.6;
                }
                currentThumb.contentMode = UIViewContentModeScaleAspectFit;
            } else {
                currentThumb.image = [CALImage getDefaultUserThumb];
            }
            [currentActivity setHidden:NO];
            [currentActivity startAnimating];
        }
        
        // Decorating thumb
        if([fromUser isKindOfClass:[User class]]) {
            if(((User*)fromUser).isOnline) {
                currentThumb.layer.borderColor = [_uiService colorForObject:fromUser].CGColor;
            } else {
                currentThumb.layer.borderColor = [UIColor whiteColor].CGColor;
            }
            currentUsernameLabel.text = ((User*)fromUser).pseudo;
            currentThumb.layer.cornerRadius = currentThumb.bounds.size.width/2;
        } else if([fromUser isKindOfClass:[Place class]]) {
            currentThumb.layer.borderColor = [UIColor whiteColor].CGColor;
            currentUsernameLabel.text = ((Place*)fromUser).title;
            currentThumb.layer.cornerRadius = 0;
        }
    }
    // Setting the message's textual contents
    NSString *msgText = nil;
    if(snippet) {
        msgText = [NSString stringWithFormat:NSLocalizedString(@"message.thread.message", @"message.thread.message"),message.messageCount];
        self.threadNicknameLabel.hidden=NO;
        if(message.recipientsGroupKey == fromUser.key || message.recipientsGroupKey == nil) {
            if([fromUser respondsToSelector:@selector(pseudo)]) {
                self.threadNicknameLabel.text = [(User*)fromUser pseudo];
            } else if([fromUser respondsToSelector:@selector(title)]) {
                self.threadNicknameLabel.text = [(Place*)fromUser title];
            }
        } else {
            PMLManagedRecipientsGroup *group = [[TogaytherService getMessageService] managedRecipientsGroupForKey:message.recipientsGroupKey];
            // Building comma seperated list of recipients
            NSMutableString *fromStr = [[NSMutableString alloc] init];
            NSString *separator = @"";
            for(PMLManagedRecipientsGroupUser *groupUser in group.groupUsers) {
                [fromStr appendString:separator];
                [fromStr appendString:groupUser.user.name];
                separator = @", ";
            }
            self.threadNicknameLabel.text = fromStr;
        }
        UIEdgeInsets insets = currentBubbleText.textContainerInset;
        currentBubbleText.textContainerInset = UIEdgeInsetsMake(15, insets.left, insets.bottom, insets.right);
        currentUsernameLabel.text = nil;
    } else {
        self.threadNicknameLabel.hidden=YES;
        msgText = message.text;
    }
    currentBubbleText.text=nil; // Link detection bug workaround
    currentBubbleText.text = msgText; //[NSString stringWithFormat:@"\"%@\"",message.text];
    
    // Setting up the bubble
    if(!snippet) {
        currentBubbleText.backgroundColor = bubbleColor;
        currentBubbleText.layer.cornerRadius = 8;
        currentBubbleText.layer.masksToBounds=YES;
    }

    // Setting the message's image content
    CALImage *image = message.mainImage;
    if(image != nil && !snippet && !self.isTemplate) {
        currentMessageImage.hidden=NO;
        currentBubbleText.hidden=YES;
        [[TogaytherService imageService] load:image to:currentMessageImage thumb:NO];
    } else {
        currentMessageImage.hidden=YES;
    }
    
    // Getting minimum height
    UIEdgeInsets insets = currentBubbleText.textContainerInset;
    currentBubbleText.textContainerInset = UIEdgeInsetsMake(insets.top, insets.top, insets.bottom, insets.bottom);
    CGFloat maxHeight = snippet ? 30 : FLT_MAX;
    [self layoutIfNeeded];
    CGSize size = [currentBubbleText sizeThatFits:CGSizeMake(_threadNicknameLabel.bounds.size.width,maxHeight)];
    int minHeight = size.height; //MAX(size.height,_thumbImage.frame.size.height);
    if(image==nil || snippet) {
        _textHeightConstraint.constant = minHeight+1; // Adding 1 for fractional height !!
    } else {
        _textHeightConstraint.constant = currentMessageImage.bounds.size.height;
    }
    textWidthConstraint.constant = size.width+1;
    return _textHeightConstraint.constant + _textTopConstraint.constant + _textBottomConstraint.constant;
}

- (Message *)getMessage {
    return _message;
}
@end
