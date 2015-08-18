//
//  PMLGraphTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 15/08/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JBLineChartView.h>

@interface PMLGraphTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet JBLineChartView *chartView;
@property (weak, nonatomic) IBOutlet UILabel *reportTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *minYLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxYLabel;
@property (weak, nonatomic) IBOutlet UILabel *selectionDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *selectionValueLabel;

@end
