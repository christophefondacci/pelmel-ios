//
//  HeightPickerDataSource.h
//  nativeTest
//
//  Created by Christophe Fondacci on 05/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HeightCallback
-(void)heightUpdated:(double)heightInCm;
@end
@interface HeightPickerDataSource : NSObject <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic) BOOL imperial;

- (id)initWithCallback:(id<HeightCallback>)callback imperialSystem:(BOOL)isImperial;

- (void)setHeight:(int)heightInCm picker:(UIPickerView*)picker;

@end
