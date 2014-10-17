//
//  WeightPickerDataSource.h
//  nativeTest
//
//  Created by Christophe Fondacci on 05/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LanguageCallback

- (void)languageChanged:(NSString*)languageCode label:(UILabel*)label index:(int)index;

@end
@interface LanguagePickerDataSource : NSObject <UIPickerViewDataSource, UIPickerViewDelegate>

- (id) initWithCallback:(id<LanguageCallback>)callback;
- (void)setLanguage:(NSString*)languageCode picker:(UIPickerView*)picker;
- (void)registerLabel:(UILabel*)label forIndex:(int)index;
@end
