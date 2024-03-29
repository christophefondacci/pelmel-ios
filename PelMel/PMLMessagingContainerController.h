//
//  PMLMessagingContainerControllerViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 15/06/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AUIAutoGrowingTextView.h"
#import "CALObject.h"
#import "ImageService.h"
#import "MessageService.h"
#import "PMLThumbCollectionViewController.h"

@interface PMLMessagingContainerController : UIViewController <MessageCallback,PMLImagePickerCallback,PMLThumbsCollectionViewActionDelegate>
@property (weak, nonatomic) IBOutlet UIView *messageTableView;
@property (weak, nonatomic) IBOutlet UIView *footerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomTextInputConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topHeaderConstraint;
@property (weak, nonatomic) IBOutlet UIView *topHeaderContainerView;
@property (weak, nonatomic) IBOutlet AUIAutoGrowingTextView *chatTextView;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIButton *addPhotoButton;

@property (strong,nonatomic) CALObject *withObject;
@property (nonatomic) BOOL showComments;

@end
