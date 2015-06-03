
//
//  PMLCalObjectPhotoProvider.m
//  PelMel
//
//  Created by Christophe Fondacci on 03/06/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLCalObjectPhotoProvider.h"
#import "PhotoPreviewViewController.h"
#import "TogaytherService.h"

@interface PMLCalObjectPhotoProvider()

@property (nonatomic,retain) CALObject *object;

@end

@implementation PMLCalObjectPhotoProvider

- (instancetype)initWithObject:(CALObject *)object
{
    self = [super init];
    if (self) {
        self.object = object;
    }
    return self;
}
- (void)photoControllerStartContentLoad:(PMLPhotosCollectionViewController *)controller {
    controller.loadFullImage = YES;
    // Everything is ready from the beginning
    [controller updateData];
}
- (NSArray *)allObjects {
    // Building an array with all images
    NSMutableArray *images = [[NSMutableArray alloc] init];
    if(self.object.mainImage != nil) {
        [images addObject:self.object.mainImage];
    }
    for(CALImage *image in self.object.otherImages) {
        [images addObject:image];
    }
    return images;
}

- (CALImage *)photoController:(PMLPhotosCollectionViewController *)controller imageForObject:(NSObject *)object {
    return (CALImage*)object;
}
- (NSString *)photoController:(PMLPhotosCollectionViewController *)controller labelForObject:(NSObject *)object {
    return nil;
}
- (void)photoController:(PMLPhotosCollectionViewController *)controller objectTapped:(NSObject *)object {

    PhotoPreviewViewController *photoController = (PhotoPreviewViewController*)[[TogaytherService uiService] instantiateViewController:SB_ID_PHOTO_GALLERY];
    photoController.currentImage = (CALImage*)object;
    photoController.imaged = self.object;
    
    [controller.navigationController pushViewController:photoController animated:YES];
}
-(void)photoControllerDidTapCloseMenu:(PMLPhotosCollectionViewController *)controller {
    [controller.parentMenuController.navigationController popToRootViewControllerAnimated:YES];
}
@end
