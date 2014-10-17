//
//  ImageService.h
//  nativeTest
//
//  Created by Christophe Fondacci on 30/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Imaged.h"
#import "ImageService.h"

@interface GalleryService : NSObject <UIGestureRecognizerDelegate,UIActionSheetDelegate, ImageManagementCallback, ImageLoaderCallback>

@property (nonatomic,retain) UIActivityIndicatorView *activityIndicator;

- (id)initWithController:(UIViewController*)controller imaged:(Imaged*)imaged initialImage:(CALImage*)initialImg panEnabled:(BOOL)pannable tapEnabled:(BOOL)tappable mode:(UIViewContentMode)contentMode;
- (id)initWithController:(UIViewController*)controller imaged:(Imaged*)imaged initialImage:(CALImage*)initialImg panEnabled:(BOOL)pannable tapEnabled:(BOOL)tappable;
- (id)initWithController:(UIViewController*)controller imaged:(Imaged*)imaged ;
- (void)imagePan:(UIPanGestureRecognizer *)panrecognizer;
- (void)updateImages;
- (void)orientationChanged:(UIInterfaceOrientation)orientation;
- (UIView*)getTopView;
- (void)prepareSegue;
- (void)viewVisible;
- (void)setInitialContentMode:(UIViewContentMode)mode;
- (void)refresh;
- (BOOL)isPreviewing;
- (void)viewWillDisappear;
@end
