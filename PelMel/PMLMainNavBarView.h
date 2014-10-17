//
//  PMLMainNavBarView.h
//  PelMel
//
//  Created by Christophe Fondacci on 06/08/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMLMainNavBarView : UIView
@property (weak, nonatomic) IBOutlet UITextField *searchTextField;
@property (weak, nonatomic) IBOutlet UIImageView *appIconView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIView *leftContainerView;
@property (weak, nonatomic) IBOutlet UIView *filtersView;

@end
