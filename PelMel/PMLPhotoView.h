//
//  PMLPhotoView.h
//  PelMel
//
//  Created by Christophe Fondacci on 06/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMLPhotoView : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@end
