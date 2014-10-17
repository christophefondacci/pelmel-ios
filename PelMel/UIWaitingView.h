//
//  UIWaitingView.h
//  PelMel
//
//  Created by Christophe Fondacci on 07/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIWaitingView : UIView
@property (weak, nonatomic) IBOutlet UIImageView *insideImageView;
@property (weak, nonatomic) IBOutlet UIImageView *outsideImageView;
@property (weak, nonatomic) IBOutlet UILabel *label;

- (void)animate;
- (void)stopAnimation;
@end
