//
//  DynamicObject.h
//
//  Created by Christophe Fondacci on 12/07/14.
//  Copyright (c) 2014 Pelmel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DynamicObject : NSObject<UIDynamicItem>

/**
 * Initializes this dynamic object whose Y value will be bound to view size. The object is located at a height of 100
 * and could be manipulated with dynamics while synching the size of the UIView. 100 means 100% of original size.
 
 * @param view the view to control
 * @param index the index of the object (if several objects in same scene, they all need a distinct index)
 * @param reverse if YES indicates that Y=0 corresponds to full initial size, otherwise if NO then Y=100 will be full size
 */
-(id) initWithView:(UIView*)view withIndex:(int)index reverse:(BOOL)reverse;

/**
 * Resets any change applied by this object on the target UIView
 */
-(void)reset;
@end
