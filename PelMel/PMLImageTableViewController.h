//
//  PMLImageTableViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 10/08/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CALImage.h"
#import "CALObject.h"

@protocol PMLImageGalleryDelegate <NSObject>

-(void)imageTappedAtIndex:(int)index image:(CALImage*)image;

@end

@interface PMLImageTableViewController : UITableViewController

@property (nonatomic,strong) CALObject *calObject;
@property (nonatomic,retain) NSObject<PMLImageGalleryDelegate> *delegate;

//- (instancetype)initWithImages:(NSArray*)images inView:(UIView*)view;
//- (instancetype)initWithCALObject:(CALObject*)object inView:(UIView*)view;
@end
