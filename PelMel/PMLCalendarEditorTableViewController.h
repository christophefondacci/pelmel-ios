//
//  PMLCalendarEditorTableViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 18/02/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PMLCalendar.h"
#import "PMLTimePickerDataSource.h"

@interface PMLCalendarEditorTableViewController : UITableViewController <PMLTimePickerCallback>

@property (nonatomic,retain) PMLCalendar *calendar;

@end
