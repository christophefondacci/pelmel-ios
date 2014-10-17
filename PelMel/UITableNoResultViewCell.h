//
//  UITableNoResultViewCell.h
//  togayther
//
//  Created by Christophe Fondacci on 16/01/13.
//  Copyright (c) 2013 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITableNoResultViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *noResultTitle;
@property (weak, nonatomic) IBOutlet UILabel *noResultSubtitle;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *searchActivity;
@property (weak, nonatomic) IBOutlet UILabel *searchLabel;

@end
