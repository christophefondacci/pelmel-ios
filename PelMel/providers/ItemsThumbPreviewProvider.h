//
//  ItemsThumbPreviewProvider.h
//  togayther
//
//  Created by Christophe Fondacci on 23/01/13.
//  Copyright (c) 2013 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CALObject.h"

#import "PMLThumbsPreviewProvider.h"




@interface ItemsThumbPreviewProvider : NSObject <PMLThumbsPreviewProvider>
- (id)initWithParent:(CALObject *)place items:(NSArray*)items moreSegueId:(NSString*)segueId labelKey:(NSString*)labelKey icon:(UIImage*)icon;

/**
 * Initializes this thumb preview provider for a given type (like, checkin, ...)
 * @param place the parent item
 * @param items the list of elements being displayed as thumbs
 * @param type the type of these thumbs
 */
- (id)initWithParent:(CALObject *)place items:(NSArray*)items forType:(PMLThumbType)type;

/**
 * Defines the label to use as an intro when displaying the contents
 * @param label the label to use as intro text
 */
-(void)setIntroLabelCode:(NSString*)label forType:(PMLThumbType)thumbType;

/**
 * Adds items to this thumb provider under a specific type. If type is unknown, use the PMLThumbsOther enum.
 */
-(void)addItems:(NSArray*)items forType:(PMLThumbType)type;
@end
