//
//  PMLTagsTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 24/09/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMLTagsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *tagsContainerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tagsContainerWidthConstraint;
@property (nonatomic,strong) NSMutableArray *tagViews;
@end
