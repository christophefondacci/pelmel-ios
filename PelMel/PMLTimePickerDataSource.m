//
//  PMLTimePickerDataSource.m
//  PelMel
//
//  Created by Christophe Fondacci on 18/02/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLTimePickerDataSource.h"

@implementation PMLTimePickerDataSource {
    UIPickerView *_pickerView;
    NSObject<PMLTimePickerCallback> *_callback;
    NSInteger _tag;
    NSInteger _hours;
    NSInteger _minutes;
}

- (instancetype)initWithCallback:(NSObject<PMLTimePickerCallback> *)callback
{
    self = [super init];
    if (self) {
        _callback = callback;
    }
    return self;
}

/**
 * Sets the picker view
 */
-(void)setPickerView:(UIPickerView*)picker {
    _pickerView = picker;
    _pickerView.dataSource = self;
    _pickerView.delegate = self;
    [self update];
}

- (void)setHours:(NSInteger)hours minutes:(NSInteger)minutes forTag:(NSInteger)tag {
    _hours = hours;
    _minutes = minutes;
    _tag = tag;
    [self update];
}
-(void)update {
    if(_pickerView != nil) {
        [_pickerView selectRow:_hours   inComponent:0 animated:NO];
        [_pickerView selectRow:_minutes/5 inComponent:1 animated:NO];
    }
}
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if(component == 0) {
        return 24;
    } else {
        return 12;
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if(component == 0) {
        return [ NSString stringWithFormat:@"%02ld",(long)row ];
    } else {
        return [NSString stringWithFormat:@"%02d",(int)row*5];
    }
}
- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSString *title = [self pickerView:pickerView titleForRow:row forComponent:component];
    NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    return attString;
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSInteger hours = [pickerView selectedRowInComponent:0];
    NSInteger minutes = [pickerView selectedRowInComponent:1]*5;
    [_callback timePickerChangedForTag:_tag hours:hours minutes:minutes];
}

@end
