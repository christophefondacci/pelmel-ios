//
//  DescriptionEditorViewController.h
//  togayther
//
//  Created by Christophe Fondacci on 08/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Description.h"

@interface DescriptionEditorViewController : UIViewController <UITextViewDelegate>

@property (strong) Description *editedDescription;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;

@end
