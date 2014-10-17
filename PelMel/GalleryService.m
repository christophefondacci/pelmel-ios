//
//  ImageService.m
//  nativeTest
//
//  Created by Christophe Fondacci on 30/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "GalleryService.h"
#import "TogaytherService.h"
#import "Place.h"
#import <SDWebImage/UIImageView+WebCache.h>

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
#define kTopQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)

@implementation GalleryService {
    UIViewController *_controller;
    Imaged *_imaged;
    UIImageView *_currentView;
    UIImageView *_nextView;
    UIImageView *_previousView;
    CGPoint lastTranslation;
    int currentImageIndex;
    UIInterfaceOrientation _currentOrientation;
    BOOL subviewsHidden;
    NSMutableArray *hiddenViews;
    ImageService *imageService;
    UIViewContentMode initialContentMode;
    NSMutableDictionary *subviewsOpacityMap;
    
    UIButton *reportButton;
    UIImage *reportImage;
    
    BOOL tapInProgress;
    BOOL running;
}
static UIImage *defaultImage;
static UIImage *defaultThumb;

@synthesize activityIndicator = activityIndicator;

- (id)initWithController:(UIViewController*)controller imaged:(Imaged*)imaged {
    CALImage *initialImage = imaged.mainImage;
    return [self initWithController:controller imaged:imaged initialImage:initialImage panEnabled:YES tapEnabled:YES];
}

- (id)initWithController:(UIViewController*)controller imaged:(Imaged*)imaged initialImage:(CALImage *)initialImg panEnabled:(BOOL)pannable tapEnabled:(BOOL)tappable {
    return [self initWithController:controller imaged:imaged initialImage:initialImg panEnabled:pannable tapEnabled:tappable mode:UIViewContentModeScaleToFill];
}
- (id)initWithController:(UIViewController*)controller imaged:(Imaged*)imaged initialImage:(CALImage *)initialImg panEnabled:(BOOL)pannable tapEnabled:(BOOL)tappable mode:(UIViewContentMode)contentMode {
    if(self = [super init]) {

        tapInProgress = NO;
        initialContentMode = UIViewContentModeScaleAspectFit; // ll; // contentMode;
        imageService = [TogaytherService imageService];
        [imageService prepareLoad:imaged];
        hiddenViews = [[NSMutableArray alloc] init];
        defaultImage = [CALImage getDefaultImage];
        defaultThumb= [CALImage getDefaultThumb];
        reportImage = [UIImage imageNamed:@"report-icon.png"];
        _controller = controller;
        _imaged = imaged;
        subviewsOpacityMap = [[NSMutableDictionary alloc] init];

        CGRect frame = [[UIScreen mainScreen] bounds];
        CGRect viewFrame = _controller.view.bounds;

//        CGFloat x = frame.origin.x;
//        frame.origin.x=0;
//        frame.origin.y=0;
//        // Fix for iPad split view, we only consider current view width
//        frame.size.width=viewFrame.size.width;
//        frame.size.width-=x;

        // Building current view
        _currentView = [[UIImageView alloc] initWithFrame:viewFrame];
        _currentView.backgroundColor = [UIColor blackColor];
        _currentView.image = [CALImage getDefaultImage];
        _currentView.contentMode=initialContentMode;
        _currentView.clipsToBounds=YES;
        _currentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        // Initializing activity indicator
        running = NO;
        
        // Building next view
        frame = _currentView.frame;
        frame.origin.x=frame.size.width;
        _nextView = [[UIImageView alloc] initWithFrame:frame];
        _nextView.clipsToBounds=YES;
        _nextView.backgroundColor = [UIColor blackColor];
        _nextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        [_nextView setContentMode:initialContentMode ];
        
        // Building previous view
        frame.origin.x = -frame.size.width;
        _previousView = [[UIImageView alloc] initWithFrame:frame];
        _previousView.backgroundColor = [UIColor blackColor];
        _previousView.clipsToBounds = YES;
        _previousView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_previousView setContentMode:initialContentMode ];

        // Initializing current image index
        if(initialImg == imaged.mainImage) {
            currentImageIndex = 0;
        } else {
            for(int i = 0 ; i < imaged.otherImages.count ; i++) {
                CALImage *image = [imaged.otherImages objectAtIndex:i];
                if(initialImg == image) {
                    currentImageIndex = i+1;
                }
            }
        }
        
        // Adjusting images
        [self updateImages];
        [controller.view insertSubview:_currentView atIndex:0];
        [controller.view insertSubview:_nextView atIndex:0];
        [controller.view insertSubview:_previousView atIndex:0];
        
        // Hiding previous & next for clean transitions
        [self prepareSegue];
        
        // Adding pan recognizer
        if(pannable) {
            UIPanGestureRecognizer *panrecognizer = [[UIPanGestureRecognizer alloc] init];
            [controller.view addGestureRecognizer:panrecognizer];
            // Adding pan recognizer target
            [panrecognizer addTarget:self action:@selector(imagePan:)];
        }
        
        
        // Handling tap gesture
        if(tappable) {
            UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] init];
            [controller.view addGestureRecognizer:tapRecognizer];
            [tapRecognizer addTarget:self action:@selector(imageTap:)];
            [tapRecognizer setDelegate:self];
        }
        
        // Listening to orientation change
        _currentOrientation = UIInterfaceOrientationPortrait;
        
        // Loading thumbs for current imaged object
        [self updateView:_currentView image:initialImg];
        [controller.view setNeedsDisplay];
    }
    return self;
}
-(NSString*)buildKey:(id)pointer {
    return [[NSString alloc] initWithFormat:@"%p",pointer];
}
- (void)refreshImages:(id)sender {
    [self updateImages];
}
- (void)orientationChanged:(UIInterfaceOrientation)orientation {
    CGRect myFrame ;
    if(orientation != _currentOrientation) {
//        CGRect appBounds = SYSTEM_VERSION_LESS_THAN(@"7.0") ? [[UIScreen mainScreen] applicationFrame] : [[UIScreen mainScreen] bounds];
//        CGRect appBounds = [[UIScreen mainScreen] bounds];
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
//        CGRect viewBounds = _controller.view.bounds;
        CGRect tabBarBounds = _controller.tabBarController.tabBar.bounds;
        switch(orientation) {
            case UIInterfaceOrientationLandscapeLeft:
            case UIInterfaceOrientationLandscapeRight: {
                myFrame = _nextView.frame;
                myFrame.size.width = screenBounds.size.height;
//                float navBarHeight = subviewsHidden ? 0 : 32; // _controller.navigationController.navigationBarHidden ? 0 : 32;
                myFrame.size.height = _controller.view.frame.size.height; //appBounds.size.width - navBarHeight;
                if(subviewsHidden) {
                    myFrame.size.height += tabBarBounds.size.height;
                }
                myFrame.origin.x = myFrame.size.width;
                [_nextView setFrame:myFrame];
                myFrame.origin.x = -myFrame.size.width;
                [_previousView setFrame:myFrame];
                myFrame.origin.x = 0;
                [_currentView setFrame:myFrame];
                break;
            }
            case UIInterfaceOrientationPortrait:
            case UIInterfaceOrientationPortraitUpsideDown: {
                myFrame = _nextView.frame;
                myFrame.size.width = screenBounds.size.width;
//                float navBarHeight = _controller.navigationController.navigationBarHidden ? 0 : 44;
                myFrame.size.height = _controller.view.frame.size.height; // appBounds.size.height - navBarHeight;
                if(subviewsHidden) {
                    myFrame.size.height += tabBarBounds.size.height;
                }
                myFrame.origin.x = myFrame.size.width;
                [_nextView setFrame:myFrame];
                myFrame.origin.x = -myFrame.size.width;
                [_previousView setFrame:myFrame];
                myFrame.origin.x = 0;
                [_currentView setFrame:myFrame];
                break;
            default:
                break;
            }
        }
        _currentOrientation = orientation;
    }
}
#pragma mark - Fullscreen switch for image preview
- (void)imageTap:(UITapGestureRecognizer *)tapRecognizer {
    UIView *parentView = tapRecognizer.view;
    CGPoint point = [tapRecognizer locationInView:parentView];
    UIView *tappedView = [parentView hitTest:point withEvent:nil];
    if((tappedView == _previousView || tappedView == _currentView || tappedView == _nextView || tappedView == parentView) && !tapInProgress) {
        // Tap is occurring
        tapInProgress = YES;
        // Getting all view child
        NSArray *subviews = parentView.subviews;
        // We iterate over all of them and hide everything but our gallery views
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            if(!subviewsHidden) {
                for(UIView *subview in subviews) {
                    if(subview != _previousView && subview != _currentView && subview != _nextView) {
                        if(subview.hidden && !subviewsHidden) {
                            [hiddenViews addObject:subview];
                        } else {
                            if(![hiddenViews containsObject:subview]) {
                                NSNumber *alpha = [NSNumber numberWithFloat:subview.alpha];
                                [subviewsOpacityMap setObject:alpha forKey:[self buildKey:subview]];
                                subview.alpha=0;
                                
                            }
                        }
                    }
                }
            } else {
                // Removing the report button
                if(reportButton != nil) {
                    [reportButton removeFromSuperview];
                    reportButton = nil;
                }
                // Setting the proper content mode to its inital value
                [_currentView setContentMode:initialContentMode];
                [_nextView setContentMode:initialContentMode];
                [_previousView setContentMode:initialContentMode];
                [hiddenViews removeAllObjects];
                
                // Showing tab bar
                [self showTabBar];
                
                // Fitting image size
//                CGRect tabBarBounds = _controller.tabBarController.tabBar.bounds;
//                CGRect frame = _currentView.frame;
//                _currentView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height-tabBarBounds.size.height);
//                frame = _previousView.frame;
//                _previousView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height-tabBarBounds.size.height);
//                frame = _nextView.frame;
//                _nextView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height-tabBarBounds.size.height);
            }
        } completion:^(BOOL finished) {
            
            [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                if(!subviewsHidden) {
                    // Hiding tab bar
                    [self hideTabBar];
                } else {
                    for(UIView *subview in subviews) {
                        NSNumber *alpha = [subviewsOpacityMap objectForKey:[self buildKey:subview]];
                        if(alpha != nil) {
                            subview.alpha = [alpha floatValue];
                        }
                    }
                }
            } completion:^(BOOL finished){
                // Toggling the status
                subviewsHidden = !subviewsHidden;
                if(subviewsHidden) {
                    [_controller.navigationController setNavigationBarHidden:YES animated:YES];

                    // Adding the report button
//                    reportButton = [UIButton buttonWithType:UIButtonTypeCustom];
//                    [reportButton addTarget:self action:@selector(reportButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
//                    [reportButton setImage:reportImage forState:UIControlStateNormal];
//                    CGRect bounds = [_currentView bounds];
//                    bounds.origin.x = bounds.size.width - 60;
//                    bounds.origin.y = bounds.size.height - 60;
//                    bounds.size.width=50;
//                    bounds.size.height=50;
//                    [reportButton setFrame:bounds];
//                    [_controller.view addSubview:reportButton];
                } else {
                    [_controller.navigationController setNavigationBarHidden:NO animated:YES ];
                }
                // Now, we're done
                tapInProgress = NO;
            }];
        }];
    }
}
-(void)hideTabBar {

    if(![TogaytherService.uiService isIpad:_controller]) {
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        
        float fHeight = screenRect.size.height;
        if(  UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) ) {
            fHeight = screenRect.size.width;
        }
        
        CGRect tabFrame = _controller.tabBarController.tabBar.frame;
        [_controller.tabBarController.tabBar setFrame:CGRectMake(tabFrame.origin.x, fHeight, tabFrame.size.width, tabFrame.size.height)];
        CGRect imageFrame = _currentView.frame;
        float heightDelta = 0;
        if(SYSTEM_VERSION_LESS_THAN(@"7.0")) {
            //        heightDelta = _controller.navigationController.navigationBar.frame.size.height;
            for(UIView *view in _controller.tabBarController.view.subviews) {
                if(![view isKindOfClass:[UITabBar class]]) {
                    [view setFrame:CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, fHeight)];
                    view.backgroundColor = [UIColor blackColor];
                }
            }
        }
        _currentView.frame = CGRectMake(imageFrame.origin.x, imageFrame.origin.y, imageFrame.size.width, imageFrame.size.height+tabFrame.size.height+heightDelta);
        imageFrame = _nextView.frame;
        _nextView.frame = CGRectMake(imageFrame.origin.x, imageFrame.origin.y, imageFrame.size.width, imageFrame.size.height+tabFrame.size.height+heightDelta);
        imageFrame = _previousView.frame;
        _previousView.frame = CGRectMake(imageFrame.origin.x, imageFrame.origin.y, imageFrame.size.width, imageFrame.size.height+tabFrame.size.height+heightDelta);
    }
    

}
-(void)showTabBar {
    if(![TogaytherService.uiService isIpad:_controller]) {
        CGRect tabFrame = _controller.tabBarController.tabBar.frame;
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        float heightDelta = tabFrame.size.height;
        float fHeight = screenRect.size.height - heightDelta;
        
        if(  UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) ) {
            fHeight = screenRect.size.width  - heightDelta;
        }
        
        [_controller.tabBarController.tabBar setFrame:CGRectMake(tabFrame.origin.x, fHeight, tabFrame.size.width, tabFrame.size.height)];
        CGRect imageFrame = _currentView.frame;
        _currentView.frame = CGRectMake(imageFrame.origin.x, imageFrame.origin.y, imageFrame.size.width, imageFrame.size.height-tabFrame.size.height);
        imageFrame = _nextView.frame;
        _nextView.frame = CGRectMake(imageFrame.origin.x, imageFrame.origin.y, imageFrame.size.width, imageFrame.size.height-tabFrame.size.height);
        imageFrame = _previousView.frame;
        _previousView.frame = CGRectMake(imageFrame.origin.x, imageFrame.origin.y, imageFrame.size.width, imageFrame.size.height-tabFrame.size.height);
        
        _currentView.backgroundColor=[UIColor whiteColor];
        // Specific pre iOS7
        if(SYSTEM_VERSION_LESS_THAN(@"7.0")) {
            for(UIView *view in _controller.tabBarController.view.subviews) {
                if([view isKindOfClass:[UITabBar class]]) {
                    NSLog(@"Tab bar Y=%d / height=%d",(int)fHeight,(int)view.frame.size.height);
                    [view setFrame:CGRectMake(view.frame.origin.x, fHeight, view.frame.size.width, view.frame.size.height)];
                } else {
                    NSLog(@"Other Class Y=%d / height=%d",(int)view.frame.origin.y,(int)view.frame.size.height);
                    [view setFrame:CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, fHeight)];
                }
            }
        }
    }

}
- (void)imagePan:(UIPanGestureRecognizer *)panrecognizer {
    CGPoint translation = [panrecognizer translationInView:_controller.view];
    int delta = translation.x-lastTranslation.x;
    
    // Sliding current frame
    CGRect frame = _currentView.frame;
    frame.origin.x += delta; //[panrecognizer translationInView:self.view].x/10;
    [_currentView setFrame:frame];
    
    // Sliding next frame
    frame = _nextView.frame;
    frame.origin.x +=delta;
    [_nextView setFrame:frame];
    
    // Sliding previous frame
    frame = _previousView.frame;
    frame.origin.x += delta;
    [_previousView setFrame:frame];
    
    
    lastTranslation = translation;
    if(panrecognizer.state == UIGestureRecognizerStateEnded) {
        [UIView animateWithDuration:0.33f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            CGRect screenBounds = [[UIScreen mainScreen] bounds];
            
            CGRect currentFrame     = _currentView.frame;
            CGRect nextFrame        = _nextView.frame;
            CGRect previousFrame    = _previousView.frame;
            
            // Handling switch to next page
            if( (currentFrame.origin.x + currentFrame.size.width) < (screenBounds.size.width/2)
                && _imaged.otherImages.count > currentImageIndex) {
                currentFrame.origin.x = -currentFrame.size.width;
                nextFrame.origin.x = 0;
                previousFrame.origin.x = -previousFrame.size.width*2;
            } else if(currentFrame.origin.x > screenBounds.size.width/2 && currentImageIndex > 0) {
                currentFrame.origin.x = currentFrame.size.width;
                previousFrame.origin.x = 0;
                nextFrame.origin.x = 2*nextFrame.size.width;
            } else {
                currentFrame.origin.x = 0;
                previousFrame.origin.x = -previousFrame.size.width;
                nextFrame.origin.x = nextFrame.size.width;
            }
            [_currentView setFrame:currentFrame];
            [_nextView setFrame:nextFrame];
            [_previousView setFrame:previousFrame];
        } completion:^(BOOL finished){
            CGRect nextFrame        = _nextView.frame;
            CGRect previousFrame    = _previousView.frame;

            // Based on current origin, we reorganize previous, next and current frames
            CGPoint currentOrigin = _currentView.frame.origin;
            if(currentOrigin.x < 0) {
                // Incrementing current index
                if(currentImageIndex < _imaged.otherImages.count) {
                    currentImageIndex++;
                    // Previous becomes next
                    previousFrame.origin.x = previousFrame.size.width;
                    
                    UIImageView *oldPrevious = _previousView;
                    _previousView = _currentView;
                    _currentView = _nextView;
                    _nextView = oldPrevious;
                    
                    [_nextView setFrame:previousFrame];
                    
                    // Loading image
                    CALImage *currentImage = [self getImage:currentImageIndex];
                    if(currentImage.fullImage == nil) {
                        [imageService load:currentImage to:_currentView thumb:NO];
                        // Preparing next image
//                        if(currentImageIndex< _imaged.otherImages.count) {
//                            [imageService load:[self getImage:currentImageIndex+1] to:_nextView thumb:YES];
//                        }
//                        [_currentView setImageWithURL:[NSURL URLWithString:currentImage.imageUrl] placeholderImage:currentImage.thumbImage];
//                        [imageService getFullImage:currentImage callback:self];
                    }
                }
            } else if(currentOrigin.x > 0) {
                if(currentImageIndex>0) {
                    currentImageIndex--;
                    // Next becomes previous
                    nextFrame.origin.x = -nextFrame.size.width;
                    
                    UIImageView *oldNext = _nextView;
                    _nextView = _currentView;
                    _currentView = _previousView;
                    _previousView = oldNext;
                    [_previousView setFrame:nextFrame];
                }
            }
            // Updating images
            [self updateImages];
        }];
        lastTranslation.x=0;
        lastTranslation.y=0;
    }
}

-(CALImage *)getImage:(int)index {
    CALImage *img;
    if(index == 0) {
        img = _imaged.mainImage;
    } else {
        if(_imaged.otherImages != nil && _imaged.otherImages.count>index-1) {
            img = [_imaged.otherImages objectAtIndex:index-1];
        }
    }
    return img;
}
-(void)updateImages {
    CALImage *currentImg;
    CALImage *nextImg;
    CALImage *prevImg;
    // Current image is main : no prev
    if(currentImageIndex == 0) {
        currentImg = _imaged.mainImage;
        prevImg = nil;
    } else {
        // Current image is > main image
        currentImg = [_imaged.otherImages objectAtIndex:currentImageIndex-1];
        // If this is the first other, our previous is main image
        if(currentImageIndex==1) {
            prevImg = _imaged.mainImage;
        } else {
            prevImg = [_imaged.otherImages objectAtIndex:currentImageIndex-2];
        }
    }
    // Next image is always in other images, if there is one
    if(_imaged.otherImages.count>currentImageIndex) {
        nextImg = [_imaged.otherImages objectAtIndex:currentImageIndex];
    } else {
        nextImg = nil;
    }
    // Updating our 3 views
    [self updateView:_previousView image:prevImg];
    [self updateView:_currentView image:currentImg];
    [self updateView:_nextView image:nextImg];
}

-(void)updateView:(UIImageView*)view image:(CALImage*)image {
    if(image != nil) {
        if(image.fullImage != nil) {
            view.image = image.fullImage;
        } else {
            if(image.thumbImage!=nil) {
                view.image=image.thumbImage;
            }
            running = YES;
            [activityIndicator startAnimating];
            activityIndicator.hidden=NO;
            [imageService load:image to:view thumb:NO callback:^(CALImage *image) {
                running = NO;
                [activityIndicator stopAnimating];
                [activityIndicator setHidden:YES];
                [self updateImages];
            }];
        }
    } else {
        if(view == _currentView) {
            view.image = [CALImage getDefaultImage];
        } else {
            view.image = nil;
        }
    }
}

-(void)fetchFullImage:(CALImage *)image {
    dispatch_async(kBgQueue, ^{
        UIImage *myImage = [UIImage imageWithData:
                   [NSData dataWithContentsOfURL:
                    [NSURL URLWithString: image.imageUrl]]];
        if(myImage == nil) {
            [image setFullImage:[CALImage getDefaultImage]];
        } else {
            [image setFullImage:myImage];
        }
        [self performSelectorOnMainThread:@selector(fetchedImage:)
                               withObject:image waitUntilDone:NO];

    });
}
-(void)fetchedImage:(id)image {
    [self updateImages];
}

- (UIView *)getTopView {
    return _currentView;
}

- (void)prepareSegue {
    [_previousView setHidden:YES];
    [_nextView setHidden:YES];
}

- (void)viewVisible {
    [_previousView setHidden:NO];
    [_nextView setHidden:NO];
    [_controller.view sendSubviewToBack:_previousView];
    [_controller.view sendSubviewToBack:_currentView];
    [_controller.view sendSubviewToBack:_nextView];
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)tapRecognizer shouldReceiveTouch:(UITouch *)touch {
    UIView *parentView = tapRecognizer.view;
    UIView *tappedView = touch.view;
    return tappedView == _previousView || tappedView == _currentView || tappedView == _nextView || tappedView == parentView;
    
}

-(void)setInitialContentMode:(UIViewContentMode)mode {
    mode = UIViewContentModeScaleAspectFit;//ll;
    initialContentMode = mode;
    if(!subviewsHidden) {
        [_previousView setContentMode:mode];
        [_currentView setContentMode:mode];
        [_nextView setContentMode:mode];
    }
}
- (void)refresh {
    [self updateImages];
}
- (BOOL)isPreviewing {
    return subviewsHidden;
}

-(void)viewWillDisappear {
    if(subviewsHidden) {
        [self showTabBar];
    }
    _previousView.hidden = YES;
}
-(void)reportButtonTapped:(id)sender {
    // Ask the user the photo source
    NSString *title = NSLocalizedString(@"gallery.report.title",@"Actions on this image");
    NSString *cancel= NSLocalizedString(@"cancel","cancel");
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:cancel destructiveButtonTitle:nil otherButtonTitles:nil];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"gallery.report.remove", "Remove this photo")];
    if([_imaged isKindOfClass:[Place class]]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"gallery.report.closed", "Place has closed")];
    } else {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"gallery.report.abuse", "Photo contains abuse")];
    }
    [actionSheet showInView:_controller.view];
}
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    CALImage *img;
    if(currentImageIndex == 0) {
        img = _imaged.mainImage;
    } else {
        img = [_imaged.otherImages objectAtIndex:currentImageIndex-1];
    }
    switch(buttonIndex) {
        case 1:
            [activityIndicator setHidden:NO];
            [activityIndicator startAnimating];
            [imageService remove:img callback:self];
            break;
        case 2:
            [activityIndicator setHidden:NO];
            [activityIndicator startAnimating];
            if([_imaged isKindOfClass:[Place class]]) {
//                [imageService reportPlaceClosed:(Place*)_imaged callback:self];
            } else {
//                [imageService reportAbuse:img callback:self];
            }
            break;
            
    }
}

#pragma mark ImageManagementCallback
- (void)imageRemoved:(CALImage *)image {
    if(image == _imaged.mainImage) {
        if(_imaged.otherImages!=nil && _imaged.otherImages.count>0) {
            _imaged.mainImage = [_imaged.otherImages objectAtIndex:0];
            [_imaged.otherImages removeObjectAtIndex:0];
        }
    } else {
        NSInteger index = [_imaged.otherImages indexOfObject:image];
        [_imaged.otherImages removeObjectAtIndex:index];
    }
    [self updateImages];
    [activityIndicator setHidden:YES];
    [activityIndicator stopAnimating];
}
-(void)imageRemovalFailed:(CALImage *)image message:(NSString *)message {
    [activityIndicator setHidden:YES];
    [activityIndicator stopAnimating];
    NSString *title = NSLocalizedString(@"gallery.removalFailed.title",@"");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}
- (void)imageReordered:(CALImage *)image {
    
}

#pragma mark ImageAbuseCallback
- (void)reportDone {
    [activityIndicator setHidden:YES];
    [activityIndicator stopAnimating];
    NSString *title = NSLocalizedString(@"gallery.abuse.title",@"");
    NSString *message = NSLocalizedString(@"gallery.abuse.done",@"");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}
- (void)reportFailedWithMessage:(NSString *)message {
    [activityIndicator setHidden:YES];
    [activityIndicator stopAnimating];
    NSString *title = NSLocalizedString(@"gallery.abuse.title",@"");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

#pragma mark - ImageLoaderCallback
- (void)imageLoaded:(CALImage *)calImage {
    running = NO;
    [activityIndicator stopAnimating];
    [activityIndicator setHidden:YES];
    [self updateImages];
}
- (void)setActivityIndicator:(UIActivityIndicatorView *)anActivityIndicator {
    activityIndicator = anActivityIndicator;
    // Handling registration of activity indicator after a process has been started
    if(running) {
        activityIndicator.hidden=NO;
        [activityIndicator startAnimating];
    }
}
@end

