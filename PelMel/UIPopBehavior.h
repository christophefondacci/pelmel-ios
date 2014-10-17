//
//  UIPopBehavior.h
//  DynamicsTest
//
//  Created by Christophe Fondacci on 13/07/14.
//  Copyright (c) 2014 Pelmel. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^PopCompletionBlock)();

@interface UIPopBehavior : UIDynamicBehavior <UICollisionBehaviorDelegate>

@property (nonatomic) double elasticity; // Elasticity, defaults to 0.7
@property (nonatomic) double gravityStrength; // Strength of gravity, defaults to 3

-(instancetype)initWithViews:(NSArray*)view pop:(BOOL)pop delay:(BOOL)delayed;
-(instancetype)initWithViews:(NSArray*)view pop:(BOOL)pop delay:(BOOL)delayed completion:(PopCompletionBlock)completionBlock;
-(void)addViews:(NSArray*)views;
@end
