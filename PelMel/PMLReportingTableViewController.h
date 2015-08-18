//
//  PMLReportingTableViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 15/08/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Place.h"
#import <JBLineChartView.h>
#import "PMLReportRangeSelectorTableViewCell.h"

@interface PMLReportingTableViewController : UITableViewController <JBLineChartViewDelegate,JBLineChartViewDataSource,PMLRangeSelectorDelegate>

@property (nonatomic,retain) Place *reportingPlace;
@end
