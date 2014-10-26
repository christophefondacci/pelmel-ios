//
//  PMLPickerProvider.h
//  PelMel
//
//  Created by Christophe Fondacci on 26/10/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifndef PelMel_PMLPickerProvider_h
#define PelMel_PMLPickerProvider_h

@protocol PMLPickerProvider <UIPickerViewDataSource,UIPickerViewDelegate>

/**
 * Sets the picker view
 */
-(void)setPickerView:(UIPickerView*)picker;

@end
#endif
