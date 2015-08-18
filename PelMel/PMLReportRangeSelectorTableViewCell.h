//
//  PMLReportRangeSelectorTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 17/08/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PMLReportConstants.h"

@protocol PMLRangeSelectorDelegate
-(void)didSelectRange:(PMLReportRange)range;
@end

@interface PMLReportRangeSelectorTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *rangeMaxButton;
@property (weak, nonatomic) IBOutlet UIButton *rangeMediumHighButton;
@property (weak, nonatomic) IBOutlet UIButton *rangeMediumButton;
@property (weak, nonatomic) IBOutlet UIButton *rangeMediumLowButton;
@property (weak, nonatomic) IBOutlet UIButton *rangeMinButton;
@property (weak, nonatomic) id<PMLRangeSelectorDelegate> delegate ;

-(void)selectRange:(PMLReportRange)range;
@end
