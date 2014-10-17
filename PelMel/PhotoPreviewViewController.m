//
//  PhotoPreviewViewController.m
//  togayther
//
//  Created by Christophe Fondacci on 11/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "PhotoPreviewViewController.h"
#import "GalleryService.h"

@interface PhotoPreviewViewController ()

@end

@implementation PhotoPreviewViewController {
    UIPanGestureRecognizer *recognizer;
    GalleryService *galleryService;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    galleryService = [[GalleryService alloc] initWithController:self imaged:_imaged initialImage:_currentImage panEnabled:YES tapEnabled:NO mode:UIViewContentModeScaleAspectFit];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    recognizer = nil;
    galleryService = nil;
}
-(void)viewWillDisappear:(BOOL)animated {
    [galleryService viewWillDisappear];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    [galleryService orientationChanged:interfaceOrientation];
    return YES;
}
- (void)viewDidAppear:(BOOL)animated {
    [galleryService viewVisible];
}
@end
