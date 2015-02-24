//
//  PMLEventTableViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 22/02/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Event.h"

@interface PMLEventTableViewController : UITableViewController <UITextFieldDelegate>

@property (nonatomic,retain) Event *event;

@end
