//
//  UITablePhotoViewCell.h
//  togayther
//
//  Created by Christophe Fondacci on 11/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITablePhotoViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIImageView *photo;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activity;

@end
