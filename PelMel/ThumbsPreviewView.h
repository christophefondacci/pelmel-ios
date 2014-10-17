//
//  ThumbsPreviewView.h
//  togayther
//
//  Created by Christophe Fondacci on 16/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CALImage.h"

@class ThumbsPreviewView;
@protocol ThumbsPreviewProvider;
@protocol PMLThumbsTableViewActionDelegate;



@interface ThumbsPreviewView : UIView 

@property (weak,nonatomic) id<ThumbsPreviewProvider> provider;
@property (weak,nonatomic) UIViewController *parentController;
@property (weak,nonatomic) id<PMLThumbsTableViewActionDelegate> actionDelegate;

-(void)setThumbsCount:(int)count;
-(void)setTitle:(NSString*)title;
-(void)setIcon:(UIImage*)icon;
-(UIImageView*)getImageView:(int)index;
@end
