//
//  DatePickerDataSource.h
//  nativeTest
//
//  Created by Christophe Fondacci on 05/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DateCallback
-(void)dateUpdated:(NSDate*)date label:(UILabel*)label;
@end

@interface DatePickerDataSource : NSObject <UIPickerViewDataSource,UIPickerViewDelegate>

-(id)initWithCallback:(id<DateCallback>)callback;

-(void)setDate:(NSDate*)date picker:(UIPickerView*)picker;
-(void)registerTargetLabel:(UILabel*)label;

@end
