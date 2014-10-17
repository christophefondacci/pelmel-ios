//
//  UITableGridImageCell.h
//  togayther
//
//  Created by Christophe Fondacci on 15/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITableGridImageCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *image1;
@property (weak, nonatomic) IBOutlet UIImageView *image2;
@property (weak, nonatomic) IBOutlet UIImageView *image3;
@property (weak, nonatomic) IBOutlet UILabel *label1;
@property (weak, nonatomic) IBOutlet UILabel *label2;
@property (weak, nonatomic) IBOutlet UILabel *label3;
@property (weak, nonatomic) IBOutlet UIImageView *online1;
@property (weak, nonatomic) IBOutlet UIImageView *online2;
@property (weak, nonatomic) IBOutlet UIImageView *online3;
@property (weak, nonatomic) IBOutlet UIButton *tapButton1;
@property (weak, nonatomic) IBOutlet UIButton *tapButton2;
@property (weak, nonatomic) IBOutlet UIButton *tapButton3;

@end
