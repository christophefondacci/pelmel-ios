//
//  PhotoManagerViewController.h
//  togayther
//
//  Created by Christophe Fondacci on 10/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageService.h"

@interface PhotoManagerViewController : UITableViewController <PMLImagePickerCallback, PMLImageUploadCallback, ImageManagementCallback>

@end
