//
//  UITableSegmentViewCell.h
//  togayther
//
//  Created by Christophe Fondacci on 18/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITableSegmentViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@end
