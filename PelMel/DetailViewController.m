//
//  DetailViewController.m
//  nativeTest
//
//  Created by Christophe Fondacci on 20/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "DetailViewController.h"
#import "Place.h"
#import "Event.h"
#import "UIImageExtras.h"
#import "TogaytherService.h"
#import "GalleryService.h"
#import "MapViewController.h"
#import "MosaicListViewController.h"
#import "ThumbsPreviewView.h"
#import "ClosableBoxView.h"
#import "providers/PlaceDetailProvider.h"
#import "providers/UserDetailProvider.h"
#import "providers/EventDetailProvider.h"
#import "MessageViewController.h"
#import "ThumbTableViewController.h"

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) //1

@interface DetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@end

@implementation DetailViewController {
    
    DataService *_dataService;
    GalleryService *_galleryService;
    UserService *_userService;
    ImageService *_imageService;
    UIService *_uiService;
    
    BOOL isInitialized;
    BOOL isAnimationDone;
    BOOL likeInProgress;
    BOOL viewAppeared;
    int likeIncrement;
    
    ClosableBoxView *descriptionBox;
    UITextView      *descTextView;
    
    id<DetailProvider> detailProvider;
    id<ThumbsPreviewProvider> lastSelectedPreviewProvider;
    UIInterfaceOrientation currentOrientation;
    
    int animationHeightDelta;
}

#pragma mark - Managing the detail item
@synthesize detailItem = _detailItem;
@synthesize placeTypeLabel = _placeTypeLabel;
@synthesize addressLabel = _addressLabel;
@synthesize distance = _distance;
@synthesize picker = _picker;
@synthesize likeCountLabel = _likeCountLabel;
@synthesize dislikeCountLabel = _dislikeCountLabel;
@synthesize likersPreviewView = _likersPreviewView;
@synthesize clientsPreviewView = _clientsPreviewView;
@synthesize likeActivity = _likeActivity;
@synthesize dislikeActivity = _dislikeActivity;
@synthesize cameraButton = _cameraButton;

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        NSLog(@"setDetailItem: hasOverviewData=%@",_detailItem.hasOverviewData ? @"YES" : @"NO");
        if([_detailItem isKindOfClass:[Place class]]) {
            detailProvider = [[PlaceDetailProvider alloc] initWithPlace:(Place*)_detailItem];
        } else if([_detailItem isKindOfClass:[User class]]) {
            detailProvider = [[UserDetailProvider alloc] initWithUser:(User *)_detailItem];
        } else if([_detailItem isKindOfClass:[Event class]]) {
            detailProvider = [[EventDetailProvider alloc] initWithEvent:(Event*)_detailItem];
        }
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
    // Assigning compass object
//    [TogaytherService.uiService setCompassObject:(CALObject*)newDetailItem];
}



- (void) updateViewFromModel {
    [_likersPreviewView setProvider:[detailProvider getPreview1Delegate]];
    [_clientsPreviewView setProvider:[detailProvider getPreview2Delegate]];
//    Place * place = (Place*)self.detailItem;
//    self.titleField.text = place.title;
    self.title = [detailProvider getTitle];
    
    // Place type management
    self.placeTypeLabel.text = [detailProvider getFirstDetailLine];
    
    // Updating distance
    self.distance.text = [detailProvider getSecondDetailLine];
    
    // Updating address
    self.addressLabel.text = [detailProvider getThirdDetailLine];
    
    // Updating opening hours
    if([detailProvider respondsToSelector:@selector(getFourthDetailLine)]) {
        self.openingsLabel.text =[detailProvider getFourthDetailLine];
        if(self.openingsLabel.text.length == 0) {
            self.openingsLabel.hidden=YES;
        } else {
            self.openingsLabel.hidden=NO;
        }
    } else {
        self.openingsLabel.text = nil;
        self.openingsLabel.hidden=YES;
    }
    // Updating status icon
    UIImage *imgStatus = [detailProvider getStatusIcon];
    if(imgStatus != nil) {
        _statusImage.image = imgStatus;
        CGRect frame = _distance.frame;
        CGRect statusFrame = _statusImage.frame;
        _distance.frame = CGRectMake(statusFrame.origin.x+statusFrame.size.width, frame.origin.y, frame.size.width, frame.size.height);
    }
    
    // Updating review icon
    if([detailProvider hasReviews]) {
        [descriptionBox.closableViewButton setHidden:NO];
        [descriptionBox.reviewsCountLabel setHidden:NO];
        descriptionBox.reviewsCountLabel.text = [NSString stringWithFormat:@"%d",[detailProvider reviewsCount]];
//        descriptionBox.closableViewButton.imageView.image = [UIImage imageNamed:@"chat-button.png"];
        descriptionBox.delegate = self;
    } else {
        [descriptionBox.reviewsCountLabel setHidden:YES];
        [descriptionBox.closableViewButton setHidden:YES];
        descriptionBox.delegate = nil;
    }
//    self.localizationIcon.imageView.image = [detailProvider getLocalizationIcon];
    
    // Updating likes
    self.likeCountLabel.text = [[NSString alloc] initWithFormat:@"%d",(int)_detailItem.likeCount];
    self.dislikeCountLabel.text = [[NSString alloc] initWithFormat:@"%d",(int)_detailItem.dislikeCount];
    
    // Handling closable box for descriptions
    if([detailProvider hasClosableBox]) {
        descTextView.text = [detailProvider getClosableBoxText];
        CGRect boxFrame = descriptionBox.scrollView.frame;
        descriptionBox.scrollView.contentSize = CGSizeMake(boxFrame.size.width, descTextView.contentSize.height);
    }
    [self updateDescriptionBoxVisibility];
        
    if(!isInitialized && _detailItem.hasOverviewData) {
        NSLog(@"Updating boxes : %@", [[detailProvider getCALObject] hasOverviewData] ? @"YES" : @"NO");
        animationHeightDelta = 0;
        CGRect frame = [_likersPreviewView frame];
        BOOL showPreview1 = [[detailProvider getPreview1Delegate] shouldShow];
        BOOL showPreview2 = [[detailProvider getPreview2Delegate] shouldShow];
        if(showPreview1) {
            [_likersPreviewView setHidden:NO];
            animationHeightDelta += frame.size.height;
        } else {
            [_likersPreviewView setHidden:YES];
        }
        frame = [_clientsPreviewView frame];
        if(showPreview2) {
            animationHeightDelta += frame.size.height;
            if(showPreview1) {
                animationHeightDelta += 3;
            }
            [_clientsPreviewView setHidden:NO];
        } else {
            [_clientsPreviewView setHidden:YES];
            // And if first preview is visible then we switch positions
            if(showPreview1) {
                [_likersPreviewView setFrame:frame];
            }
        }
        
        // Managing tags
        for(NSString *tag in _detailItem.tags) {
            UIImage *tagIcon = [_imageService getTagImage:tag];
            if(_tagImage1.image == nil) {
                _tagImage1.image = tagIcon;
            } else if(_tagImage2.image == nil) {
                _tagImage2.image = tagIcon;
            } else if(_tagImage3.image == nil) {
                _tagImage3.image = tagIcon;
            }
        }
        if(viewAppeared) {
            [self animateBoxes];
        }
        isInitialized = YES;
    }
    // Filling boxes information (we don't care if visible or not)
    [_likersPreviewView setTitle:[[detailProvider getPreview1Delegate] getLabel]];
    // Filling image for every user liking the place
    [_likersPreviewView setThumbsCount:(int)[[[detailProvider getPreview1Delegate] items] count]];
    [_likersPreviewView setIcon:[[detailProvider getPreview1Delegate] getIcon]];
    [_clientsPreviewView setTitle:[[detailProvider getPreview2Delegate] getLabel]];
    [_clientsPreviewView setThumbsCount:(int)[[[detailProvider getPreview2Delegate] items] count]];
    [_clientsPreviewView setIcon:[[detailProvider getPreview2Delegate] getIcon]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [TogaytherService applyCommonLookAndFeel:self];
    // Do any additional setup after loading the view, typically from a nib.
    _dataService = [TogaytherService dataService];
    _userService = [TogaytherService userService];
    _imageService = [TogaytherService imageService];
    _uiService = TogaytherService.uiService;
    
    // Requesting overview data
    [_dataService registerDataListener:self];
    [_dataService getOverviewData:self.detailItem];
    
    // Adding the refresh button
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)];
    self.navigationItem.rightBarButtonItem = refreshButton;

    

    animationHeightDelta = 0;
    
    _likersPreviewView.parentController = self;
    [_likersPreviewView setProvider:[detailProvider getPreview1Delegate]];
    [_likersPreviewView setActionDelegate:self];
    _clientsPreviewView.parentController = self;
    [_clientsPreviewView setProvider:[detailProvider getPreview2Delegate]];
    [_clientsPreviewView setActionDelegate:self];
    
    // Initializing description box
    NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"ClosableBoxView" owner:self options:nil];
    descriptionBox = [views objectAtIndex:0];
    descriptionBox.titleLabel.text=@"Description";
    [descriptionBox setHidden:YES];

//    NSLog(@"Description hidden");
    [self.view addSubview:descriptionBox];
    
    // Sizing and positioning box
    CGRect bounds = descriptionBox.bounds;
    if([_uiService isIpad:self]) {
//        bounds.size.width = bounds.size.width*2;
        bounds.size.height = bounds.size.height*2;
    }
    [descriptionBox setFrame:CGRectMake(-bounds.size.width, 95, bounds.size.width, bounds.size.height)];
    [descriptionBox.closableViewButton addTarget:self action:@selector(closeableButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    descTextView = [[UITextView alloc] init];
    [descTextView setEditable:NO];
    [descTextView setBackgroundColor:[UIColor clearColor]];
    [descTextView setTextColor:[UIColor whiteColor]];
    [descriptionBox.scrollView addSubview:descTextView];
    
    CGRect frame = descriptionBox.scrollView.bounds;
    [descTextView setFrame:frame];
    
    // Configuring button
    [detailProvider prepareButton1:_cameraButton controller:self];
    
    // Putting our 2 bottom boxes outside the screen
    CGRect frameBottom = [_likersPreviewView frame];
    CGRect frameTop = [_clientsPreviewView frame];
    
    // Adding 2x their height to put them outside the screen at the bottom
    frameBottom.origin.y += frameBottom.size.height*2+3;
    frameTop.origin.y += frameTop.size.height*2+3;
    
    // Specific fix for tab bar height
    if(SYSTEM_VERSION_LESS_THAN(@"7.0") && ! [TogaytherService.uiService isIpad:self]) {
        CGRect tabFrame = self.tabBarController.tabBar.frame;
        frameBottom.origin.y-= tabFrame.size.height;
        frameTop.origin.y-=tabFrame.size.height;
    }
    // Assigning changes
    [_likersPreviewView setFrame:frameBottom];
    [_likersPreviewView setIcon:[[detailProvider getPreview1Delegate] getIcon]];
    [_clientsPreviewView setFrame:frameTop];
    [_clientsPreviewView setIcon:[[detailProvider getPreview2Delegate] getIcon]];
    
    // IPAD context => update map
    if([TogaytherService.uiService isIpad:self]) {
        MapViewController *mapController = [TogaytherService.uiService mapControllerFromSplitView:self.splitViewController];
        [mapController setCentralObject:self.detailItem];
    }

}
- (void)viewDidAppear:(BOOL)animated {
    [self.navigationController setToolbarHidden:YES];
    [_galleryService viewVisible];
    viewAppeared = YES;
    [self animateBoxes];
}

-(void)animateBoxes {
    // Animating the boxes to make them appear from the bottom
    if(!isAnimationDone && _detailItem.hasOverviewData) {
        NSLog(@"Animating");
    //    NSLog([NSString stringWithFormat:@"Description size is %d",self.detailItem.miniDesc.length]);
        NSString *desc = [detailProvider getClosableBoxText];
        if(![detailProvider hasClosableBox] || (desc!=nil && desc.length>0)) {
//            NSLog(@"Description visible");
            [descriptionBox setHidden:NO];
        }
        [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            CGRect frame = [_likersPreviewView frame];
//            NSLog([NSString stringWithFormat:@"Setting likers frame origin Y: original = %f / delta = %f / final = %f",frame.origin.y,-2*frame.size.height,frame.origin.y-2*frame.size.height]);
            NSLog(@"Animating delta=%d",animationHeightDelta);
            frame.origin.y -= animationHeightDelta;

            [_likersPreviewView setFrame:frame];
            
            frame = [_clientsPreviewView frame];
//            NSLog([NSString stringWithFormat:@"Setting clients frame origin Y: original = %f / delta = %f / final = %f",frame.origin.y,-2*frame.size.height,frame.origin.y-2*frame.size.height]);
            frame.origin.y -= animationHeightDelta;
            [_clientsPreviewView setFrame:frame];
            
            frame = [descriptionBox frame];
            frame.origin.x=0;
//            NSLog([NSString stringWithFormat:@"Setting description frame origin X = %f",frame.origin.x]);
            [descriptionBox setFrame:frame];
        } completion:^(BOOL finished) {
//            NSLog(@"Description animation finished");
        }];
        isAnimationDone=YES;
    }
}
- (void)viewWillAppear:(BOOL)animated {
    if(_galleryService == nil) {
        _galleryService = [[GalleryService alloc] initWithController:self imaged:self.detailItem];
        [_galleryService setInitialContentMode:[detailProvider getInitialViewContentMode]];
        _galleryService.activityIndicator = _dislikeActivity;
    }
    // Assigning compass object
//    [TogaytherService.uiService setCompassObject:(CALObject*)_detailItem];
    [self updateViewFromModel];
}
-(void)viewWillDisappear:(BOOL)animated {
    [_galleryService viewWillDisappear];
}
- (void)viewDidUnload
{
    [self setDistance:nil];
    [self setPlaceTypeLabel:nil];
    [self setAddressLabel:nil];
    [self setLikeCountLabel:nil];
    [self setDislikeCountLabel:nil];
    _dataService = nil;
    _galleryService = nil;
    _userService = nil;
    isInitialized = NO;
    isAnimationDone = NO;
    viewAppeared = NO;
//    _detailItem = nil;
    _likersPreviewView=nil;
    _clientsPreviewView =nil;
    _likeActivity=nil;
    _dislikeActivity=nil;
    _cameraButton=nil;
    [self setTagImage1:nil];
    [self setTagImage2:nil];
    [self setTagImage3:nil];
    [self setStatusImage:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)interfaceOrientationChanged:(UIInterfaceOrientation)interfaceOrientation
{
    [_galleryService orientationChanged:interfaceOrientation];
    currentOrientation = interfaceOrientation;
    if(viewAppeared) {
        [self updateDescriptionBoxVisibility];
        return YES;
    } else {
        return NO;
    }

//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
//        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
//    } else {
//        return YES;
//    }
}

// iOS 6 orientation management
//- (BOOL)shouldAutorotate {
//    // Getting orientation
//    UIInterfaceOrientation orientation = [[UIDevice currentDevice] orientation];
//    
//    return [self shouldAutorotateToInterfaceOrientation:orientation];
//}
//- (NSUInteger)supportedInterfaceOrientations {
//    return UIInterfaceOrientationLandscapeLeft | UIInterfaceOrientationLandscapeRight | UIInterfaceOrientationPortrait;
//}
- (void)updateDescriptionBoxVisibility {
    NSString *desc = [detailProvider getClosableBoxText];
    if(viewAppeared) { // && ! [_galleryService isPreviewing]) {
        if([_galleryService isPreviewing] && currentOrientation== UIInterfaceOrientationPortrait) {
            // Doing nothing, no solution found for proper hidden state to NO without appearing since alpha is 0
            
//            [descriptionBox setHidden:NO];
//            [descriptionBox setAlpha:0];
        } else if([TogaytherService.uiService isIpad:self]) {
            descriptionBox.hidden=NO;
        } else {
            [descriptionBox setHidden:currentOrientation == UIInterfaceOrientationLandscapeLeft || currentOrientation == UIInterfaceOrientationLandscapeRight || desc==nil || desc.length==0 || ![detailProvider hasClosableBox]];
        }

//    } else {
//        [descriptionBox setHidden:YES];
    }
}

- (void)viewWillLayoutSubviews {
    UIInterfaceOrientation orientation = [self interfaceOrientation];
    [self interfaceOrientationChanged:orientation];
}
#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

- (IBAction)addPictureTapped:(id)sender {
    if(self.picker == nil) {
        self.picker = [[UIImagePickerController alloc] init];
        self.picker.delegate = self;
        self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        self.picker.allowsEditing=NO;
    }
    [self.navigationController presentViewController:_picker animated:YES completion:nil];
}



#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

//-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
//    [self dismissModalViewControllerAnimated:YES];
//    
//    UIImage *fullImage = (UIImage*) [info objectForKey:UIImagePickerControllerOriginalImage];
//    UIImage *thumbImage = [fullImage imageByScalingAndCroppingForSize:CGSizeMake(44, 44)];
//    self.detailItem.fullImage=fullImage;
//    self.detailItem.thumbImage = thumbImage;
//    self.currentImageView.image=fullImage;
//}

- (void)overviewImageFetched {
    // Assigning the image and flagging the view as requiring refresh
//    self.currentImageView.image = self.detailItem.mainImage.fullImage;
//    [self.view setNeedsDisplay];
}

-(void)didLoadOverviewData:(CALObject *)object {
    // Getting thumbs for gallery service
//    [_imageService getThumbs:_detailItem mainImageOnly:NO callback:_galleryService];
    if([object.key isEqualToString:_detailItem.key]) {
        [self updateViewFromModel];
    }
}

- (IBAction)imagePan:(UIPanGestureRecognizer *)panrecognizer {
//    [_imageService imagePan:panrecognizer];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    [_galleryService prepareSegue];
    if([segue.identifier isEqualToString:@"seeOnAMap"]) {
        MapViewController *controller = [segue destinationViewController];
        CLLocationCoordinate2D coords;
        coords.latitude = self.detailItem.lat;
        coords.longitude = self.detailItem.lng;
        [controller setCentralObject:self.detailItem];
        [controller setCenter:coords];

    } else if([segue.identifier isEqualToString:@"chat"]) {
        MessageViewController *controller = [segue destinationViewController];
        controller.withObject = _detailItem;
    } else if([segue.identifier isEqualToString:@"showUserPlace"]) {
        DetailViewController *controller = segue.destinationViewController;
        controller.detailItem = ((User*)_detailItem).lastLocation;
    } else {
        UIViewController *controller = [segue destinationViewController];
        [lastSelectedPreviewProvider prepareSegue:controller];
    }
}
- (IBAction)likeTapped:(id)sender {
    if(!likeInProgress) {
        likeInProgress = YES;
        [_likeActivity startAnimating];
        [detailProvider likeTapped:self.detailItem callback:^(int likes, int dislikes) {
            [self likeDone:self.detailItem newLikes:likes newDislikes:dislikes];
        }];
    }
}

- (IBAction)dislikeTapped:(id)sender {
    if(!likeInProgress) {
        likeInProgress = YES;
        [_dislikeActivity startAnimating];
        [_dataService dislike:self.detailItem callback:^(int likes, int dislikes) {
            [self likeDone:self.detailItem newLikes:likes newDislikes:dislikes];
        }];
    }
}

- (IBAction)headingBlockTapped:(id)sender {
    [detailProvider headingBlockTapped:self];
}

- (void)likeDone:(CALObject *)likedObject newLikes:(int)likeCount newDislikes:(int)dislikesCount {
    [_likeActivity stopAnimating];
    [_dislikeActivity stopAnimating];
    likeInProgress = NO;
    self.detailItem.likeCount = likeCount;
    [self updateViewFromModel];

}

-(void)refresh:(id)sender {
    // Forcing refresh by unflagging CAL object
    [self.detailItem setHasOverviewData:NO];
    [_dataService getOverviewData:self.detailItem];
}
#pragma mark ThumbsPreviewActionDelegate
-(void)thumbsTableView:(id<ThumbsPreviewProvider>)provider thumbTapped:(int)thumbIndex {
    lastSelectedPreviewProvider = provider;
    NSString *segueId = [lastSelectedPreviewProvider getPreviewSegueIdForThumb:thumbIndex];
    if(segueId != nil) {
        [self performSegueWithIdentifier:segueId sender:self];
    }
}
- (void)moreTapped:(id<ThumbsPreviewProvider>)provider {
    lastSelectedPreviewProvider = provider;
    NSString *segueId = [lastSelectedPreviewProvider getMoreSegueId];
    [self performSegueWithIdentifier:segueId sender:self];
}

#pragma mark ImageUploadCallback
- (void)imageUploaded:(CALImage *)image {
    // Setting current main image as first other image
    CALImage *currentMainImg = _detailItem.mainImage;
    if(currentMainImg != nil) {
        if(_detailItem.otherImages == nil) {
            _detailItem.otherImages = [[NSMutableArray alloc] init];
        }
        if(_detailItem.otherImages.count == 0) {
            [_detailItem.otherImages addObject:currentMainImg];
        } else {
            [_detailItem.otherImages insertObject:currentMainImg atIndex:0];
        }
    }
    
    // Assigning new image as main
    _detailItem.mainImage = image;
    
    // Refreshing view
    [self updateViewFromModel];
    [_galleryService refresh];
}
- (void)imageUploadFailed:(CALImage *)image {
    self.title = @"Failed";
}

#pragma mark CloseableBoxDelegate
- (void)closeableButtonTapped:(id)source {
    
    [self performSegueWithIdentifier:@"chat" sender:self];
}

@end
