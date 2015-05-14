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
//    self.firstDisplayPackageContainer.userInteractionEnabled = YES;
    self.firstDisplayPackageContainer.tag = 0;
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(firstPackageTapped:)];
    tapRecognizer.delegate = self;
    [self.firstDisplayPackageContainer addGestureRecognizer:tapRecognizer];

    
//    self.secondDisplayPackageContainer.userInteractionEnabled = YES;
    self.secondDisplayPackageContainer.tag = 1;
    tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(secondPackageTapped:)];
    tapRecognizer.delegate = self;
    [self.secondDisplayPackageContainer addGestureRecognizer:tapRecognizer];
    
//    self.thirdDisplayPackageContainer.userInteractionEnabled = YES;
    self.thirdDisplayPackageContainer.tag = 2;
    tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(thirdPackageTapped:)];
    tapRecognizer.delegate=self;
    [self.thirdDisplayPackageContainer addGestureRecognizer:tapRecognizer];
    
    // Adjusting text view insets
    [self.okButton addTarget:self action:@selector(okTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelButton addTarget:self action:@selector(cancelTapped:) forControlEvents:UIControlEventTouchUpInside];
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Actions
-(void)packageTapped:(NSInteger)index {
    if(self.delegate != nil) {
        [self.delegate bannerEditor:self packageSelected:index];
    }
}
- (void)firstPackageTapped:(UIGestureRecognizer*)recognizer {
    self.firstDisplayPackageContainer.backgroundColor = kColorSelected;
    self.secondDisplayPackageContainer.backgroundColor = kColorUnselected;
    self.thirdDisplayPackageContainer.backgroundColor = kColorUnselected;
    [self packageTapped:0];
}
- (void)secondPackageTapped:(UIGestureRecognizer*)recognizer {
    self.firstDisplayPackageContainer.backgroundColor = kColorUnselected;
    self.secondDisplayPackageContainer.backgroundColor = kColorSelected;
    self.thirdDisplayPackageContainer.backgroundColor = kColorUnselected;
    [self packageTapped:1];
}
- (void)thirdPackageTapped:(UIGestureRecognizer*)recognizer {
    self.firstDisplayPackageContainer.backgroundColor = kColorUnselected;
    self.secondDisplayPackageContainer.backgroundColor = kColorUnselected;
    self.thirdDisplayPackageContainer.backgroundColor = kColorSelected;
    [self packageTapped:2];
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
