//
//  PhotoPreviewViewController.h
//  togayther
//
//  Created by Christophe Fondacci on 11/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CALImage.h"
#import "Imaged.h"

@interface PhotoPreviewViewController : UIViewController

@property (strong) Imaged *imaged;
@property (strong) CALImage *currentImage;

@end
