//
//  PMLOpenActionBehavior.h
//  PelMel
//
//  Created by Christophe Fondacci on 18/08/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^OpenCompletionBlock)();
@interface PMLOpenActionBehavior : UIDynamicBehavior <UICollisionBehaviorDelegate>

@property (nonatomic,strong) OpenCompletionBlock completionCallback;

-(instancetype)initWithViews:(NSArray*)views forActions:(NSArray*)actions center:(CGPoint)center radius:(CGFloat)radius open:(BOOL)open;

-(void)addViews:(NSArray*)views forActions:(NSArray*)actions;
@end
