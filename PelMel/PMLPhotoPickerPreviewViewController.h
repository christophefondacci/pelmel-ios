//
//  PhotoPickerPreviewViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 16/04/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^PMLPhotoPickerPreviewCompletion)(UIImage *image );

@interface PMLPhotoPickerPreviewViewController : UIViewController <UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *previewImage;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (strong, nonatomic) UIImage *image;
@property (nonatomic,copy) PMLPhotoPickerPreviewCompletion completion;
@end
