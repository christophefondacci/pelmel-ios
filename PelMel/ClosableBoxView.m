//
//  ClosableBoxView.m
//  togayther
//
//  Created by Christophe Fondacci on 17/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "ClosableBoxView.h"

@implementation ClosableBoxView
@synthesize titleLabel;
@synthesize scrollView;

-(void)configure {
    // Registering us as a listener to our button tap event
    [_closableViewButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
}
- (id)init
{
    self = [super init];
    if (self) {
        [self configure];
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self configure];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self configure];
    }
    return self;
}

-(void)buttonTapped:(id)sender {
    // Delegating if we have someone to delegate to
//    if(_delegate != nil) {
//        [_delegate closeableButtonTapped:self];
//    }
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
