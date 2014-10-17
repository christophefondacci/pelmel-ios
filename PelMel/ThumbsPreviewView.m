//
//  ThumbsPreviewView.m
//  togayther
//
//  Created by Christophe Fondacci on 16/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "ThumbsPreviewView.h"
#import "CALImage.h"
#import "TogaytherService.h"
#import "ThumbTableViewController.h"

@implementation ThumbsPreviewView {
    NSMutableArray *_images;
    NSMutableArray *_buttons;
    UIView *_backgroundView;
    UILabel *_introLabel;
    
    UILabel *_countLabel;
    UIImageView *_iconView;
    
    UIButton *_detailButton;
    int _thumbsCount;
    int _title;
    ImageService *imageService;
    ThumbTableViewController *thumbController;
}


- (void) configure {
    
    // Service initialization
    imageService = [TogaytherService imageService];
    
    // Filling the array of all images
    _images = [[NSMutableArray alloc] initWithCapacity:5];
    _buttons = [[NSMutableArray alloc] initWithCapacity:5];
    
    
    // Adding background
    _backgroundView = [[UIView alloc] initWithFrame:[self bounds]];
    _backgroundView.backgroundColor = [UIColor blackColor];
    _backgroundView.alpha = 0.4;
    [self addSubview:_backgroundView];
    
    // Adding intro label
    _introLabel = [[UILabel alloc] init];
    CGRect bounds = CGRectMake(48,-2,320,21);
    [_introLabel setFrame:bounds];
    [self addSubview:_introLabel];
    _introLabel.textColor = [UIColor whiteColor];
    _introLabel.backgroundColor = [UIColor clearColor];
    _introLabel.font = [UIFont systemFontOfSize:13];
    
    // Adding count
    _countLabel = [[UILabel alloc] init];
    bounds = CGRectMake(4, -2, 19, 21);
    [_countLabel setFrame:bounds];
    [self addSubview:_countLabel];
    _countLabel.textColor = [UIColor whiteColor];
    _countLabel.backgroundColor = [UIColor clearColor];
    _iconView = [[UIImageView alloc] init];
    bounds = CGRectMake(21,0,19,19);
    [_iconView setFrame:bounds];
    [self addSubview:_iconView];

    // Adding table view controller
    UIStoryboard *st = [UIStoryboard storyboardWithName:[[NSBundle mainBundle].infoDictionary objectForKey:@"UIMainStoryboardFile"] bundle:[NSBundle mainBundle]];
    thumbController = [st instantiateViewControllerWithIdentifier:@"thumbTableController"];
    thumbController.thumbProvider = self.provider;
    thumbController.actionDelegate = self.actionDelegate;
    [self addSubview:thumbController.view];
    
    // Adding button
//    _detailButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
//    [self addSubview:_detailButton];
    
    // Clearing background
    self.backgroundColor = nil;
}
- (UIImageView *)getImageView:(int)index {
    if(_images.count>index) {
        return [_images objectAtIndex:index];
    }
    return nil;
}
- (id)init
{
    self = [super init];
    if (self) {
        [self configure];
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self configure];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self configure];
    }
    return self;
}
 
- (void)layoutSubviews {
    CGRect frame = [self frame];
    [_backgroundView setFrame:[self bounds]];
    CGRect tableFrame = CGRectMake(0, 18, frame.size.width, 50);
    thumbController.tableView.frame = tableFrame;
//    CGRect buttonFrame = CGRectMake(frame.size.width-46, 27, 29, 31);
//    [_detailButton setFrame:buttonFrame];
//    [_detailButton addTarget:self action:@selector(detailButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
//    [_detailButton setHidden:![_provider showMoreButton]];
//    for(int i = 0 ; i < _images.count ; i++) {
//        UIImage *image = [_provider thumbsPreview:self getImageAtIndex:i];
//        UIImageView *imageView = [_images objectAtIndex:i];
//        UIButton *imageButton = [_buttons objectAtIndex:i];
//        CGRect bounds = CGRectMake(i+1 + (50*i), 18, 50, 50);
//        [imageView setFrame:bounds];
//        [imageButton setFrame:bounds];
//        if(image == nil) {
//            imageView.image = [CALImage getDefaultThumb];
//        } else {
//            imageView.image = image;
//        }
////        [self handleDecorator:i];
//    }
}

- (void)setThumbsCount:(int)count {
    _thumbsCount = count;
    _countLabel.text = [NSString stringWithFormat:@"%d",count];
    
//    // Removing every image view
//    for(UIImageView *imageView in _images) {
//        [imageView removeFromSuperview];
//    }
//    for(UIButton *button in _buttons) {
//        [button removeFromSuperview];
//    }
//    
//    // Clearing array
//    [_images removeAllObjects];
//    [_buttons removeAllObjects];
//    
//    // Adding new images
//    for(int i = 0 ; i < MIN(5,count) ; i++) {
//        // Initializing image
//        UIImageView *imageView = [[UIImageView alloc] init];
//        imageView.contentMode = UIViewContentModeScaleAspectFit;
//        
//        // Initializing button (over image
//        UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
//
//        // Filling arrays
//        [_images addObject:imageView];
//        [_buttons addObject:imageButton];
//        
//        // Adding button detector
//        [imageButton addTarget:self action:@selector(imageTapped:) forControlEvents:UIControlEventTouchUpInside];
//        
//        // Adding controls to view
//        [self addSubview:imageView];
//        [self addSubview:imageButton];
//        
//        // Adding decorator
//        [self handleDecorator:i];
//    }
    
    // Relayout
//    [thumbController.tableView reloadData];
    [thumbController.tableView reloadData];
    [self setNeedsLayout];
}

-(void)handleDecorator:(int)index {
    // The image view where the decorator will be placed
    UIImageView *parentView = [self getImageView:index];
    UIImage *imgDecorator = [_provider topLeftDecoratorForIndex:index];
    // Decorating
    [imageService decorate:parentView decorator:imgDecorator];

}
- (void)setTitle:(NSString *)title {
    _introLabel.text = title;
}
- (void)detailButtonTapped:(id)sender {
//    [_actionDelegate moreTapped:self.provider];
}
-(void)imageTapped:(id)sender {
    int i = (int)[_buttons indexOfObject:sender];
    NSLog(@"NO LONGER SUPPORTED Image tapped at index %d",i);
//    [_actionDelegate thumbsTableView:self.provider thumbTapped:i];
}
- (void)setIcon:(UIImage *)icon {
    _iconView.image=icon;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)setParentController:(UIViewController *)parentController {
    [parentController addChildViewController:thumbController];
    _parentController = parentController;
}

- (void)setProvider:(id<ThumbsPreviewProvider>)provider {
    thumbController.thumbProvider = provider;
    _provider = provider;
}
- (void)setActionDelegate:(id<PMLThumbsTableViewActionDelegate>)actionDelegate {
    thumbController.actionDelegate = actionDelegate;
    _actionDelegate = actionDelegate;
}
@end
