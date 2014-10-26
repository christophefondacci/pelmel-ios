//
//  WeightPickerDataSource.m
//  nativeTest
//
//  Created by Christophe Fondacci on 05/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "LanguagePickerDataSource.h"

@implementation LanguagePickerDataSource {
    id<LanguageCallback> _callback;
    NSMutableArray *languagesArray;
    int _index;
    
    UIPickerView *_pickerView;
    NSString *_languageCode;
}


- (id)initWithCallback:(id<LanguageCallback>)callback {
    if(self = [super init]) {
        _callback = callback;
        languagesArray = [[NSMutableArray alloc] initWithObjects:@"fr",@"en",@"es",@"de",@"it",@"nl", nil];
        [languagesArray sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSString *formatStr1 = [[NSString alloc] initWithFormat:@"language.%@",(NSString*)obj1];
            NSString *label1 = NSLocalizedString(formatStr1,@"Language label");
            
            NSString *formatStr2 = [[NSString alloc] initWithFormat:@"language.%@",(NSString*)obj2];
            NSString *label2 = NSLocalizedString(formatStr2,@"Language label");
            
            return [label1 compare:label2];
        }];
    }
    return self;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return languagesArray.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSString *langCode = [languagesArray objectAtIndex:row];
    NSString *formatStr = [[NSString alloc] initWithFormat:@"language.%@",langCode];
    NSString *langLabel = NSLocalizedString(formatStr,@"language label");
    return langLabel;
}
- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSString *title = [self pickerView:pickerView titleForRow:row forComponent:component];
    NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    return attString;
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSString *selectedLangCode = [languagesArray objectAtIndex:row];
    [_callback languageChanged:[selectedLangCode uppercaseString] index:_index];
}

- (void)setLanguage:(NSString *)languageCode forIndex:(int)index {
    _languageCode = languageCode;
    _index = index;
}
-(void)setPickerView:(UIPickerView *)picker {
    _pickerView = picker;
    int _selectedIndex = -1;
    for(int i = 0 ; i < languagesArray.count ; i++) {
        NSString *currentLangCode = [languagesArray objectAtIndex:i];
        if([currentLangCode isEqualToString:_languageCode]) {
            _selectedIndex = i;
            break;
        }
    }
    if(_selectedIndex!=-1) {
        [_pickerView selectRow:_selectedIndex inComponent:0 animated:NO];
    }
}

@end
