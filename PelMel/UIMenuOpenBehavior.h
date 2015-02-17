//
//  UIMenuOpenBehaviour.h
//  PelMel
//
//  Created by Christophe Fondacci on 13/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^MenuOpenCompletion)();

@interface UIMenuOpenBehavior : UIDynamicBehavior <UICollisionBehaviorDelegate>

@property (nonatomic,copy) MenuOpenCompletion completion;

- (instancetype)initWithViews:(NSArray *)views open:(BOOL)shouldOpenMenu boundary:(int)yBoundary;

- (instancetype)initWithViews:(NSArray *)views open:(BOOL)shouldOpenMenu boundary:(int)yBoundary horizontal:(BOOL)horizontal;

/**
 * A list of menu actions which might be pushed (or pulled) by the menu when it opens or closes
 * @param pushedViews a list of MenuAction that are pushed when menu opens
 * @param bounds the bounds of the screen to consider when putting back pushed views (when menu closes)
 */
-(void)addPushedActions:(NSArray*)pushedMenuActions inBounds:(CGRect)bounds;

-(void)setIntensity:(float)intensity;
@end
