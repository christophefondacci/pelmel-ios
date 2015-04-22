//
//  PMLChatInputBarView.h
//  PelMel
//
//  Created by Christophe Fondacci on 21/04/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AUIAutoGrowingTextView.h"

@interface PMLChatInputBarView : UIView
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIButton *addPhotoButton;
@property (weak, nonatomic) IBOutlet AUIAutoGrowingTextView *chatTextView;

@end
