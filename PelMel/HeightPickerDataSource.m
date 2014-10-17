//
//  HeightPickerDataSource.m
//  nativeTest
//
//  Created by Christophe Fondacci on 05/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "HeightPickerDataSource.h"
#import "TogaytherService.h"

@implementation HeightPickerDataSource {
    id<HeightCallback> _callback;
    NSMutableArray *heightsArray;
    NSMutableArray *feetArray;
    NSMutableArray *inchesArray;
    ConversionService *conversionService;
}


- (id)initWithCallback:(id<HeightCallback>)callback imperialSystem:(BOOL)isImperial {
    if(self = [super init]) {
        _callback = callback;
        // Initializing available choices for height (in cm, conversion will be made at display time)
        heightsArray = [[NSMutableArray alloc] init];
        for(int i = 120 ; i <=220 ; i++) {
            [heightsArray addObject:[[NSNumber alloc] initWithInt:i]];
        }
        feetArray = [[NSMutableArray alloc] init];
        for(int i=1 ; i<=7 ; i++) {
            [feetArray addObject:[[NSNumber alloc] initWithInt:i]];
        }
        inchesArray = [[NSMutableArray alloc] init];
        for(int i = 1; i <12 ; i++) {
            [inchesArray addObject:[[NSNumber alloc] initWithInt:i]];
        }
        conversionService = [TogaytherService getConversionService];
        _imperial = isImperial;
    }
    return self;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return _imperial ? 2 : 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if(_imperial) {
        switch(component) {
            case 0:
                return [feetArray count];
            default:
                return [inchesArray count];
        }
    } else {
        return [heightsArray count];
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if(_imperial) {
        NSNumber *n;
        NSString *s;
        switch(component) {
            case 0:
                n = [feetArray objectAtIndex:row];
                s = [[NSString alloc] initWithFormat:@"%d '",[n intValue]];
                return s;
            case 1:
                n = [inchesArray objectAtIndex:row];
                s = [[NSString alloc] initWithFormat:@"%d ''",[n intValue]];
                return s;
        }
    } else {
        NSNumber *cm = [heightsArray objectAtIndex:row];
        NSString *label = [[NSString alloc] initWithFormat:@"%d cm",[cm intValue]];
        return label;
    }
    return nil;
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    if(_imperial) {
        NSInteger feetSelIndex = [pickerView selectedRowInComponent:0];
        NSInteger inchesSelIndex = [pickerView selectedRowInComponent:1];
        int feets = [[feetArray objectAtIndex:feetSelIndex] intValue];
        int inches = [[inchesArray objectAtIndex:inchesSelIndex] intValue];
        
        double heightInCm = [conversionService getCmFromFeet:feets inches:inches];
        [_callback heightUpdated:heightInCm];
    } else {
        int height = [[heightsArray objectAtIndex:row] intValue];
        [_callback heightUpdated:(double)height];
    }
}

- (void)setHeight:(int)heightInCm picker:(UIPickerView *)picker {
    if(_imperial) {
        int feets = [conversionService getFeetFromCm:(double)heightInCm];
        int inches = [conversionService getInchesFromCm:(double)heightInCm];
        [picker selectRow:feets-1 inComponent:0 animated:NO];
        [picker selectRow:inches-1 inComponent:1 animated:NO];
    } else {
        [picker selectRow:heightInCm-120 inComponent:0 animated:NO];
    }
}
@end
