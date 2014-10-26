//
//  WeightPickerDataSource.h
//  nativeTest
//
//  Created by Christophe Fondacci on 05/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PMLPickerProvider.h"

@protocol LanguageCallback

- (void)languageChanged:(NSString*)languageCode index:(int)index;

@end
@interface LanguagePickerDataSource : NSObject <PMLPickerProvider>

- (id) initWithCallback:(id<LanguageCallback>)callback;
- (void)setLanguage:(NSString*)languageCode forIndex:(int)index;

@end
