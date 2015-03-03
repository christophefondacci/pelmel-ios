//
//  PMLCalendarTableViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 17/02/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//
#import "Place.h"
#import "PMLAddTableViewCell.h"
#import <UIKit/UIKit.h>

@interface PMLCalendarTableViewController : UITableViewController 

// The parent place which this calendar editor is handling
@property (nonatomic,retain) Place *place;

@end
