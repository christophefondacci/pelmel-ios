//
//  DatePickerDataSource.h
//  nativeTest
//
//  Created by Christophe Fondacci on 05/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PMLPickerProvider.h"

@protocol DateCallback
-(void)dateUpdated:(NSDate*)date;
@end

@interface DatePickerDataSource : NSObject <PMLPickerProvider>

@property (nonatomic,retain) NSDate *dateValue;

-(id)initWithCallback:(id<DateCallback>)callback;

/**
 * Sets the date information that this datasource will edit (must be set BEFORE picker view)
 */
//-(void)setDate:(NSDate*)date;


@end
