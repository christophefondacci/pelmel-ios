//
//  PMLTimePickerDataSource.h
//  PelMel
//
//  Created by Christophe Fondacci on 18/02/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PMLPickerProvider.h"


/**
 * Callback definition for time change notifications
 */
@protocol PMLTimePickerCallback
-(void)timePickerChangedForTag:(NSInteger)tag hours:(NSInteger)hours minutes:(NSInteger)minutes;
@end

@interface PMLTimePickerDataSource : NSObject <PMLPickerProvider, UIPickerViewDataSource, UIPickerViewDelegate>

/**
 * Initializes the time picker with the given callback that will be notified of changes
 */
- (instancetype)initWithCallback:(NSObject<PMLTimePickerCallback>*)callback;

/**
 * Sets the value for this picker
 */
- (void)setHours:(NSInteger)hours minutes:(NSInteger)minutes forTag:(NSInteger)tag;

@end
