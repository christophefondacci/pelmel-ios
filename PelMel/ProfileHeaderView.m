//
//  ProfileHeaderView.m
//  nativeTest
//
//  Created by Christophe Fondacci on 05/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "ProfileHeaderView.h"

@implementation ProfileHeaderView
@synthesize pseudoLabel;
@synthesize profileImageView;
@synthesize activityIndicator;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
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


- (void)setNickname:(NSString *)nickname parentWidth:(NSInteger)width {

    // Updating header title with user pseudo
    self.pseudoLabel.text=nickname;
    
    // Sizing label to fit its width (so the edit button will be next to the text
    CGSize optimalSize = [self.pseudoLabel sizeThatFits:CGSizeMake(width, self.pseudoLabel.bounds.size.height)];
    self.nicknameLabelWidthConstraint.constant = optimalSize.width;

}

@end
