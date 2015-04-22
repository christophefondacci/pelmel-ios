//
//  PMLChatLoaderView.h
//  PelMel
//
//  Created by Christophe Fondacci on 20/04/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMLChatLoaderView : UIView
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loaderActivity;
@property (weak, nonatomic) IBOutlet UILabel *loaderLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *loaderWidthConstraint;
@property (weak, nonatomic) IBOutlet UIButton *loadMessagesButton;

@end
