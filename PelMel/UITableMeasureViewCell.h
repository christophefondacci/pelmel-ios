//
//  UITableMeasureViewCell.h
//  nativeTest
//
//  Created by Christophe Fondacci on 07/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UITableMeasureViewCell;

@protocol MeasureSliderDelegate
// Called on delegate of a measure view cell when the slider's value changed
- (void)measureChanged:(UITableMeasureViewCell*)cell id:(NSString*)identifier;
@end

@interface UITableMeasureViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UISlider *measureSlider;
@property (weak, nonatomic) IBOutlet UILabel *measureLabel;
@property (weak, nonatomic) IBOutlet UILabel *measureInternationalLabel;
@property (weak, nonatomic) IBOutlet UILabel *measureImperialLabel;

- (IBAction)sliderValueChanged:(id)sender;
- (void)setDelegate:(id<MeasureSliderDelegate>)delegate id:(NSString*)identifier;

@end
