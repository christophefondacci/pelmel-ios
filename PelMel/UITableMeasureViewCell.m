//
//  UITableMeasureViewCell.m
//  nativeTest
//
//  Created by Christophe Fondacci on 07/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "UITableMeasureViewCell.h"

@implementation UITableMeasureViewCell {
    id<MeasureSliderDelegate> _delegate;
    NSString *_identifier;
}

@synthesize measureSlider;
@synthesize measureLabel;
@synthesize measureInternationalLabel;
@synthesize measureImperialLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)sliderValueChanged:(UISlider*)sender {
    if(_delegate != nil) {
        [_delegate measureChanged:self id:_identifier];
    }
}

- (void)setDelegate:(id<MeasureSliderDelegate>)delegate id:(NSString*)identifier{
    _delegate = delegate;
    _identifier = identifier;
    [self sliderValueChanged:measureSlider];

}
@end
