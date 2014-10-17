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
    UILabel *_label;
    int _index;
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
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSString *selectedLangCode = [languagesArray objectAtIndex:row];
    [_callback languageChanged:[selectedLangCode uppercaseString] label:_label index:_index];
}

- (void)registerLabel:(UILabel *)label forIndex:(int)index{
    _label = label;
    _index = index;
}
- (void)setLanguage:(NSString *)languageCode picker:(UIPickerView *)picker {
    int selectedIndex = -1;
    for(int i = 0 ; i < languagesArray.count ; i++) {
        NSString *currentLangCode = [languagesArray objectAtIndex:i];
        if([currentLangCode isEqualToString:languageCode]) {
            selectedIndex = i;
        }
    }
    if(selectedIndex!=-1) {
        [picker selectRow:selectedIndex inComponent:0 animated:NO];
    }
}
@end
