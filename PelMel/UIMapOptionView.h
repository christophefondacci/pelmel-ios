//
//  UIMapOptionView.h
//  PelMel
//
//  Created by Christophe Fondacci on 20/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIMapOptionView : UIView
@property (weak, nonatomic) IBOutlet UIImageView *optionImage;
@property (weak, nonatomic) IBOutlet UILabel *optionText;

-(instancetype)initWithImage:(UIImage*)image title:(NSString*)title;

@end
