//
//  PMLThumbsPreviewProvider.h
//  PelMel
//
//  Created by Christophe Fondacci on 04/03/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CALImage.h"
#import "CALObject.h"

typedef enum {
    PMLThumbNone, PMLThumbsLike,PMLThumbsCheckin,PMLThumbsUserLike, PMLThumbsUsersInEvent, PMLThumbsOther, PMLThumbsLocation
} PMLThumbType;



@protocol PMLThumbsPreviewProvider <NSObject>
- (CALImage*)imageAtIndex:(NSInteger)index forType:(PMLThumbType)type;
- (UIImage*)topLeftDecoratorForIndex:(NSInteger)index forType:(PMLThumbType)type;
- (UIImage*)bottomRightDecoratorForIndex:(NSInteger)index forType:(PMLThumbType)type;
- (NSArray*)itemsForType:(PMLThumbType)thumbType;
- (NSString*)titleAtIndex:(NSInteger)index forType:(PMLThumbType)type;
- (NSArray*)thumbTypes;
- (PMLThumbType)thumbTypeAtIndex:(NSInteger)index;

// Optional
@optional
- (CALObject*)objectAtIndex:(NSInteger)index forType:(PMLThumbType)type;
- (NSString*)labelForType:(PMLThumbType)type;
- (UIImage*)imageForType:(PMLThumbType)type;
- (NSInteger)fontSize;
- (BOOL)rounded; // Whether or not images are rounded corners (defaults to YES)
- (BOOL)isSelected:(NSInteger)index forType:(PMLThumbType)type;
- (UIColor*) colorFor:(NSInteger)index forType:(PMLThumbType)type; // Color to use when displaying element (border color), defaults to white

@end