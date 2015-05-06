//
//  PMLActivityDetailTableViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 04/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MessageService.h"
#import "PMLActivityStatistic.h"

@interface PMLActivityDetailTableViewController : UITableViewController <ActivitiesCallback>

@property (nonatomic,retain) PMLActivityStatistic *activityStatistic;

@end
