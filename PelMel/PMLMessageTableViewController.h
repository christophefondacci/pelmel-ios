//
//  MessageTableViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 21/04/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CALObject.h"
#import "MessageService.h"

@interface PMLMessageTableViewController : UITableViewController <MessageCallback, PMLImagePickerCallback>

@property (strong,nonatomic) CALObject *withObject;

@end
