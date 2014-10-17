//
//  Thumb.h
//  PelMel
//
//  Created by Christophe Fondacci on 27/01/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ThumbCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *thumbImage;
@property (weak, nonatomic) IBOutlet UIImageView *onlineImage;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *bottomDecorator;
@property (weak, nonatomic) IBOutlet UIView *containerView;

@end
