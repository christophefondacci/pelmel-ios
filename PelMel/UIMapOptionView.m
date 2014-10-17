//
//  UIMapOptionView.m
//  PelMel
//
//  Created by Christophe Fondacci on 20/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "UIMapOptionView.h"

@implementation UIMapOptionView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}
- (instancetype)initWithImage:(UIImage *)image title:(NSString *)title
{
    self = [super init];
    if (self) {
        self.optionImage.image = image;
        self.optionText.text = title;
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

@end
