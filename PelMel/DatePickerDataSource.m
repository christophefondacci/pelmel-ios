//
//  DatePickerDataSource.m
//  nativeTest
//
//  Created by Christophe Fondacci on 05/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "DatePickerDataSource.h"

@implementation DatePickerDataSource {
    id<DateCallback> _callback;
    NSMutableArray *yearsArray;
    NSMutableArray *monthArray;
}

-(id)initWithCallback:(id<DateCallback>)callback {
    if(self = [super init]) {
        _callback = callback;
        
        // Extracting current year
        NSDate *curentDate = [NSDate date];
        NSCalendar* calendar = [NSCalendar currentCalendar];
        NSDateComponents* compoNents = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:curentDate]; // Get necessary date components
        NSInteger currentYear = [compoNents year];
        
        // Filling our array
        yearsArray = [[NSMutableArray alloc] init];
        for(int i = 1920 ; i <= currentYear ; i++) {
            [yearsArray addObject:[[NSNumber alloc] initWithInt:i]];
        }
        
        // Preparing our month array
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        monthArray = [[NSMutableArray alloc] initWithCapacity:12];
        for(int i = 0 ; i < 12 ; i++) {
            NSString *monthName = [[formatter monthSymbols] objectAtIndex:i];
            [monthArray addObject:monthName];
        }
    }
    return self;
}
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 3;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    switch(component) {
        case 0:
            return 31;
        case 1:
            return 12;
        case 2:
            return yearsArray.count;
            
    }
    return 0;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    switch(component) {
        case 0:
            return [[NSString alloc] initWithFormat:@"%d",(int)row+1];
        case 1:
            return [monthArray objectAtIndex:row];
        case 2: {
            NSInteger year = [[yearsArray objectAtIndex:row] integerValue];
            return [[NSString alloc] initWithFormat:@"%d",(int)year];
        }
    }
    return nil;
}
- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSString *title = [self pickerView:pickerView titleForRow:row forComponent:component];
    NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    return attString;
}
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    NSInteger day = [pickerView selectedRowInComponent:0]+1;
    NSInteger month = [pickerView selectedRowInComponent:1]+1;
    NSNumber *yearNum = [yearsArray objectAtIndex:[pickerView selectedRowInComponent:2]];
    NSInteger year = [yearNum integerValue];
    
    [components setDay:day];
    [components setMonth:month];
    [components setYear:year];
    
    NSDate *date = [cal dateFromComponents:components];
    [_callback dateUpdated:date];
}
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    CGRect bounds = [[UIScreen mainScreen] bounds];
    int width = bounds.size.width-20;
    switch(component) {
        case 0:
            return width*0.2;
        case 1:
            return width*0.4;
        case 2:
            return width*0.3;
    }
    return 0;
}

-(void)setPickerView:(UIPickerView *)picker {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* compoNents = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:_dateValue]; // Get necessary date components
    NSInteger year = [compoNents year];
    NSInteger month = [compoNents month];
    NSInteger day = [compoNents day];
    
    [picker selectRow:day-1 inComponent:0 animated:NO];
    [picker selectRow:month-1 inComponent:1 animated:NO];
    [picker selectRow:(year-1920) inComponent:2 animated:NO];
}
@end
