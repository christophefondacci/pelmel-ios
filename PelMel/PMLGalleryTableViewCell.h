//
//  PMLGalleryTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 30/08/2014.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KIImagePager.h"


@interface PMLGalleryTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet KIImagePager *galleryView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rightConstraint;
@property (weak, nonatomic) IBOutlet UIButton *addPhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *secondaryButton;
@property (weak, nonatomic) IBOutlet UILabel *secondaryButtonTitle;

@end
