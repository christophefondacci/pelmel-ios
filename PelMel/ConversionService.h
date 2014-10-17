//
//  ConversionService.h
//  PelMel
//
//  Created by Christophe Fondacci on 05/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Place.h"
#import "Special.h"

typedef enum {
    CURRENT, SOON, PAST
} SpecialMode;

typedef void(^AddressClosure)(NSString*address);

@interface ConversionService : NSObject

- (int) getFeetFromCm:(double)cm;
- (int) getInchesFromCm:(double)cm;
- (double) getCmFromFeet:(int)feet inches:(int)inches;
-(NSString*)getHeightLabel:(double)measureInCm imperial:(BOOL)isImperial;

-(NSString*)getWeightLabel:(float)weightInKg imperial:(BOOL)isImperial;
/**
 * Computes the distance from current user location to the given object.
 * The result is a distance string to be used in UILabel
 */
-(NSString*)distanceTo:(CALObject*)object;
/**
 * Computes the address at the location of the given object and invokes the block passing
 * the resolved and formatted address.
 */
-(void)geocodeAddressFor:(CALObject*)object completion:(AddressClosure)closure;

/**
 * Converts the special object into a real-time information about whether it is past, present or future
 */
-(SpecialMode)specialModeFor:(Special*)special;
-(Special*)specialFor:(CALObject*)place ofType:(NSString *)specialType;
@end
