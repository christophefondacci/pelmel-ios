//
//  PMLBannerEditorTableViewCell.m
//  PelMel
//
//  Created by Christophe Fondacci on 12/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLBannerEditorTableViewCell.h"
#import "TogaytherService.h"

#define kColorSelected UIColorFromRGB(0xec7501)
#define kColorUnselected UIColorFromRGBAlpha(0xec7501,0.5f)

@implementation PMLBannerEditorTableViewCell {
}

- (void)awakeFromNib {
    // Initialization code
    [self hookActions];
    
    

//    self.targetItemUrlTextView.textContainerInset = UIEdgeInsetsMake(2, 2, 2, 2);
}

-(void)hookActions {
    [self.placeButton addTarget:self action:@selector(placeTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.eventButton addTarget:self action:@selector(eventTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.urlButton addTarget:self action:@selector(urlTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    // Adjusting text view insets
    [self.okButton addTarget:self action:@selector(okTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelButton addTarget:self action:@selector(cancelTapped:) forControlEvents:UIControlEventTouchUpInside];
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
-(void)refreshWithBanner:(PMLBanner*)banner {
    if(banner.targetObject != nil) {
        // Adjusting visibility
        self.targetUrlTextField.hidden=YES;
        self.targetItemImage.hidden = NO;
        self.targetItemLabel.hidden = NO;
        
        // Loading place thumb
        CALImage *image = [[TogaytherService imageService] imageOrPlaceholderFor:banner.targetObject allowAdditions:NO];
        self.targetItemImage.image = [[CALImage defaultNoPhotoCalImage] fullImage];
        [[TogaytherService imageService] load:image to:self.targetItemImage thumb:YES];
        
        // Setting up title
        self.targetItemLabel.text = [[[TogaytherService uiService] infoProviderFor:banner.targetObject ] title];
        
        // Refreshing type buttons enablement
        [self refreshWithTargetType:([banner.targetObject isKindOfClass:[Place class]] ? PMLTargetTypePlace : PMLTargetTypeEvent)];
        
    } else {
        // Adjusting visibility
        self.targetUrlTextField.hidden = NO;
        self.targetItemImage.hidden=YES;
        self.targetItemLabel.hidden = YES;
        
        // Filling URL
        self.targetUrlTextField.text = banner.targetUrl;
        self.targetUrlTextField.placeholder = NSLocalizedString(@"banner.url.placeholder", @"banner.url.placeholder");
        [self refreshWithTargetType:PMLTargetTypeURL];
    }
    


}
-(void)refreshWithTargetType:(PMLTargetType)targetType {
    self.placeButton.backgroundColor    = UIColorFromRGBAlpha(0x039ebd,targetType == PMLTargetTypePlace ? 1 : 0.15);
    self.eventButton.backgroundColor    = UIColorFromRGBAlpha(0x3ba414,targetType == PMLTargetTypeEvent ? 1 : 0.15);
    self.urlButton.backgroundColor      = UIColorFromRGBAlpha(0xe8791f,targetType == PMLTargetTypeURL ? 1 : 0.15);

}
#pragma mark - Actions
-(void)targetTypeTapped:(PMLTargetType)targetType {
    
    // Updating buttons color
    [self refreshWithTargetType:targetType];
    
    // Calling delegate
    if(self.delegate != nil) {
        [self.delegate bannerEditor:self targetTypeSelected:targetType];
    }
}
- (void)placeTapped:(UIButton*)button {
    [self targetTypeTapped:PMLTargetTypePlace];
}
- (void)eventTapped:(UIButton*)button {
    [self targetTypeTapped:PMLTargetTypeEvent];
}
- (void)urlTapped:(UIButton*)button {
    [self targetTypeTapped:PMLTargetTypeURL];
}

- (void)okTapped:(id)sender {
    NSLog(@"OK tapped");
    if(self.delegate!=nil) {
        [self.delegate bannerEditorDidTapOk:self];
    }
}
- (void)cancelTapped:(id)sender {
    NSLog(@"Cancel tapped");
    if(self.delegate!=nil) {
        [self.delegate bannerEditorDidTapCancel:self];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}
@end
