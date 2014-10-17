//
//  SnippetViewController.m
//  PelMel
//
//  Created by Christophe Fondacci on 26/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PMLSnippetViewController.h"
#import "TogaytherService.h"
#import "ThumbTableViewController.h"
#import "Constants.h"
#import "ItemsThumbPreviewProvider.h"
#import "UITouchBehavior.h"
#import "Activity.h"
#import "PMLSubNavigationController.h"
#import "PMLImageTableViewController.h"
#import "PMLDataManager.h"

@interface PMLSnippetViewController ()

@end

@implementation PMLSnippetViewController {
    // Inner controller for thumb listview
    ThumbTableViewController *thumbController;
    
    // UI Animation related
    UIDynamicAnimator *_animator;
    NSMutableArray *_observedProperties;
    
    // Content Providers
//    NSObject<DetailProvider> *_detailProvider;
    NSObject<MasterProvider> *_masterProvider;
    NSObject<PMLInfoProvider> *_infoProvider;
    
    // Services
    UIService *_uiService;
    DataService *_dataService;
    ImageService *_imageService;
    
    // Gallery
    PMLImageTableViewController *_galleryController;
    BOOL _galleryFullscreen;
    CGRect _galleryFrame;
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
    // Setting up services
    _uiService = TogaytherService.uiService;
    _dataService = TogaytherService.dataService;
    _imageService = TogaytherService.imageService;
    
    // Setting up fonts
    _likesCounterLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:17];
    _checkinsCounterLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:17];
    _commentsCounterLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:17];
    self.hoursBadgeTitleLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:10];
    self.hoursBadgeSubtitleLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:8];
    _titleLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:16];
    self.hoursBadgeView.hidden=YES;
    
    // Do any additional setup after loading the view.
    _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    _observedProperties = [[NSMutableArray alloc] init];
    _galleryView.delegate=self;
    _galleryView.dataSource=self;
    
    // Initializing thumb controller
    thumbController = (ThumbTableViewController*)[_uiService instantiateViewController:SB_ID_THUMBS_CONTROLLER];
    [self addChildViewController:thumbController];
    [self.peopleView addSubview:thumbController.view];
    [thumbController didMoveToParentViewController:self];
    




    if(_snippetItem != nil) {
        _infoProvider = [_uiService infoProviderFor:_snippetItem];
        
        //        _detailProvider = [TogaytherService.uiService buildProviderFor:_snippetItem];
        _masterProvider = [_uiService masterProviderFor:_snippetItem];

        // Listening to edit mode
        [self.snippetItem addObserver:self forKeyPath:@"editing" options:NSKeyValueObservingOptionNew context:NULL];
        [_observedProperties addObject:@"editing"];
        
        // Setting title
        _titleLabel.text = _infoProvider.title;
        
        // If snippet of a new object
        if(self.snippetItem.key == nil) {
            
            // Tappable label for name edition
            _titleLabel.userInteractionEnabled=YES;
            UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(labelTapped:)];
            [_titleLabel addGestureRecognizer:tapRecognizer];
            
            // No subtitle
            _subtitleLabel.text = nil;
            
            // Observing address
            Place *place = (Place*)_snippetItem;
            if(place.address != nil) {
                _subtitleLabel.text = place.address;
            } else {
                [self.snippetItem addObserver:self forKeyPath:@"address" options:   NSKeyValueObservingOptionNew context:NULL];
                [_observedProperties addObject:@"address"];
            }
        }

        // Updating UI elements
        [self updateHours];
        [self updateColors];
        [self updateThumbSubtitle];
        [self updateCounters];
        [self updateThumb];

    } else {
        // Otherwise, showing current context
        ModelHolder *modelHolder = [_dataService modelHolder];
        
        if(modelHolder.localizedCity) {
            _titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"places.section.inZone", @"places.section.inZone"),modelHolder.places.count]; //modelHolder.localizedCity.name;
        }
        if(modelHolder.activities.count>0) {
            self.subtitleLabel.text = NSLocalizedString(@"snippet.activity", @"Nearby users");
            [_imageService load:modelHolder.localizedCity.mainImage to:self.thumbView thumb:YES];
            [self loadNearbyActivity:modelHolder.activities];
        } else {
            self.subtitleLabel.text = nil;
        }

    }
//    [TogaytherService.getDataService getOverviewData:_snippetItem];
}
-(void)viewWillAppear:(BOOL)animated {
    self.parentMenuController.contextObject = _snippetItem;
}
- (void)willMoveToParentViewController:(UIViewController *)parent {
    if(parent == nil) {
        // Unregistering data listener
        [_dataService unregisterDataListener:self];
        
        // Unregistering any observed property
        for(NSString *observedProperty in _observedProperties) {
            // Removing us as observer
            [_snippetItem removeObserver:self forKeyPath:observedProperty];
        }
        
        // No more editing
        _snippetItem.editing=NO;
        
        // Purging props
        [_observedProperties removeAllObjects];
    }
}
- (void)viewDidAppear:(BOOL)animated {
//    _galleryController.view.frame = self.galleryView.bounds;
//    _galleryController.tableView.frame = self.galleryView.bounds;
    // Getting data
    [_dataService registerDataListener:self];
    if(_snippetItem != nil) {
        [_dataService getOverviewData:_snippetItem];
    }
}

-(void)viewDidDisappear:(BOOL)animated {
    [_dataService unregisterDataListener:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)loadNearbyActivity:(NSArray*)activities {
    
    NSMutableArray *people = [[NSMutableArray alloc] init];
    NSMutableSet *peopleKeys = [[NSMutableSet alloc] init];
    for(Activity *activity in activities) {
        if(activity.user != nil && ![peopleKeys containsObject:activity.user.key]) {
            [people addObject:activity.user];
            [peopleKeys addObject:activity.user.key];
        }
    }
    // Building provider
    thumbController.size = @30;
    thumbController.thumbProvider = [[ItemsThumbPreviewProvider alloc] initWithParent:nil items:people moreSegueId:nil labelKey:nil icon:nil];
    thumbController.actionDelegate = self;
    thumbController.view.frame = _peopleView.bounds;
    [thumbController.tableView reloadData];

}


#pragma mark - PMLDataListener
- (void)didLoadOverviewData:(CALObject *)object {
    if([object.key isEqualToString:_snippetItem.key]) {
        
        // Building provider
        thumbController.size = @30;
        thumbController.thumbProvider = _infoProvider.thumbsProvider;
        thumbController.actionDelegate = self;
        thumbController.view.frame = _peopleView.bounds;
        [thumbController.tableView reloadData];
        
        // Updating gallery
        [_galleryView reloadData];
        
        // Updating counters
        [self updateCounters];
    }
}

#pragma mark - Snippet data update
-(void) updateCounters {
    // Counters
    self.likesCounterLabel.text = [NSString stringWithFormat:@"%d",_infoProvider.likesCount];
    self.checkinsCounterLabel.text = [NSString stringWithFormat:@"%d",_infoProvider.checkinsCount];
    self.commentsCounterLabel.text = [NSString stringWithFormat:@"%d",_infoProvider.reviewsCount];
    // Gradient on counters view
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.countersView.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)UIColorFromRGB(0x636466).CGColor, (id)UIColorFromRGB(0x2c2d2f).CGColor, nil];
    [self.countersView.layer insertSublayer:gradient atIndex:0];
    self.countersView.layer.masksToBounds=YES;
}
-(void) updateHours {
    // Setting opening hours badge
    Special *special = [_masterProvider getSpecialFor:_snippetItem];
    if(special!=nil) {
        self.hoursBadgeView.hidden=NO;
        self.hoursBadgeTitleLabel.text = [_masterProvider getSpecialsMainLabel:special];
        self.hoursBadgeSubtitleLabel.text = [_masterProvider getSpecialIntroLabel:special];
        self.hoursBadgeTitleLabel.textColor = [_masterProvider getSpecialsColor:special];
        self.hoursBadgeSubtitleLabel.textColor = [_masterProvider getSpecialsColor:special];
    } else {
        self.hoursBadgeView.hidden = YES;
    }
}
-(void) updateColors {
    // Setting colored line
    UIColor *color = _infoProvider.color;
    self.colorLineView.backgroundColor = color;
    // Thumb border
    self.thumbView.layer.borderColor = color.CGColor;
    // Subtitle
    self.subtitleLabel.textColor = color;
}
-(void) updateThumbSubtitle {
    self.thumbSubtitleLabel.text = _infoProvider.thumbSubtitleText;
    self.thumbSubtitleLabel.textColor = _infoProvider.thumbSubtitleColor;
    self.thumbSubtitleLabel.font = [UIFont fontWithName:PML_FONT_DEFAULT size:11];
}
-(void) updateThumb {
    // Loading thumb
    [_imageService load:_snippetItem.mainImage to:_thumbView thumb:YES];
    // Image touch events
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
    [self.thumbView addGestureRecognizer:tapRecognizer];
    self.thumbView.userInteractionEnabled=YES;
}
#pragma mark - Touch events
- (void) labelTapped:(UIGestureRecognizer*)sender {

    self.titleTextField.placeholder = NSLocalizedString(@"edit.title",@"Enter a name");
    self.titleTextField.hidden=NO;
    self.titleTextField.delegate = self;
    [self.titleTextField becomeFirstResponder];

}
-(void)imageTapped:(UITapGestureRecognizer*)sender {
    if(_snippetItem.mainImage==nil) {
        // Prompting for upload
        [self.parentMenuController.dataManager promptUserForPhotoUploadOn:_snippetItem];
    } else {
        [self.parentMenuController openCurrentSnippet];
        [self toggleFullscreenGallery];
    }
}

#pragma mark - KVO Observing implementation
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([@"addess" isEqualToString:keyPath]) {
        if([object isKindOfClass:[Place class]]) {
            _subtitleLabel.text = ((Place*)object).address;
        }
    } else if([@"editing" isEqualToString:keyPath]) {
        if(_snippetItem.editing) {
            self.titleTextField.delegate = self;
            self.titleTextField.hidden=NO;
            self.titleTextField.text = _infoProvider.title;
            [self.titleTextField becomeFirstResponder];
        } else {
            self.titleTextField.hidden=YES;
            self.titleLabel.text = _infoProvider.title;
        }
    }
}

#pragma mark - ThumbPreviewActionDelegate
- (void)thumbsTableView:(id<ThumbsPreviewProvider>)sender thumbTapped:(int)thumbIndex {
    PMLSnippetViewController *childSnippet = (PMLSnippetViewController*)[TogaytherService.uiService instantiateViewController:SB_ID_SNIPPET_CONTROLLER];
    childSnippet.snippetItem = [[sender items] objectAtIndex:thumbIndex];
    [self.subNavigationController pushViewController:childSnippet animated:YES];
}
#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    // Retrieving text
    NSString *inputText = self.titleTextField.text;
    
    // Removing current input
    self.titleTextField.hidden=YES;
    self.titleTextField.text = nil;
    
    // Calling back
    if([_snippetItem isKindOfClass:[Place class]]) {
        // Only doing something if we have a valid text
        NSString *title = [inputText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if(title.length>0) {
            ((Place*)_snippetItem).title = inputText;
            self.titleLabel.text = inputText;
            self.editing=NO;
        }
    }
    [self.titleTextField resignFirstResponder];
    return YES;
}

#pragma mark - PMLImageGalleryDelegate
- (void)imageTappedAtIndex:(int)index image:(CALImage *)image {
    [self toggleFullscreenGallery];
}
-(void)toggleFullscreenGallery {
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if(_galleryFullscreen) {
            self.galleryView.frame = _galleryFrame;
        } else {
            _galleryFrame = self.galleryView.frame;
            self.galleryView.frame = self.parentMenuController.view.bounds;
        }
        [self.galleryView updateFrames];
    } completion:^(BOOL finished) {
        _galleryFullscreen = !_galleryFullscreen;
    }];
}
#pragma mark - KIImagePagerDatasource
- (NSArray *)arrayWithImages {
    NSMutableArray *_images = [[NSMutableArray alloc] init ];
    if(_snippetItem.mainImage!=nil) {
        [_images addObject:_snippetItem.mainImage];
        for(CALImage *img in _snippetItem.otherImages) {
            [_images addObject:img];
        }
    }
    return _images;
}
- (UIViewContentMode)contentModeForImage:(NSUInteger)image {
    return UIViewContentModeScaleAspectFit;
}
-(UIImage *)placeHolderImageForImagePager {
    return [CALImage getDefaultImage];
}
- (void)imagePager:(KIImagePager *)imagePager didSelectImageAtIndex:(NSUInteger)index {
    [self imageTappedAtIndex:(int)index image:nil];
}
@end
