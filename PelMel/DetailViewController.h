//
//  DetailViewController.h
//  nativeTest
//
//  Created by Christophe Fondacci on 20/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataService.h"
#import "Place.h"
#import "ThumbsPreviewView.h"
#import "UserService.h"
#import "Likeable.h"
#import "ClosableBoxView.h"
#import "ThumbTableViewController.h"

@class DetailViewController;

@protocol DetailProvider <Likeable>




// V2 used info
-(NSString*)getTitle;
-(int)reviewsCount;
-(int)likesCount;
-(int)checkinsCount;
-(NSString*)getSecondDetailLine;

@optional
-(NSString*)getFourthDetailLine;
-(UIImage*)getStatusIcon;
-(NSString*)getFirstDetailLine;

-(NSString*)getThirdDetailLine;
-(BOOL)hasClosableBox;
-(NSString*)getClosableBoxTitle;
-(NSString*)getClosableBoxText;
-(BOOL)hasReviews;

-(UIImage*)getLikeIcon;
-(id<ThumbsPreviewProvider>)getPreview1Delegate;
-(id<ThumbsPreviewProvider>)getPreview2Delegate;
-(CALObject*)getCALObject;
-(UIViewContentMode)getInitialViewContentMode;
-(void)prepareButton1:(UIButton*)button controller:(DetailViewController*)controller;
-(void)headingBlockTapped:(DetailViewController*)controller;
@end

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PMLDataListener, PMLThumbsTableViewActionDelegate, PMLImageUploadCallback, ClosableBoxDelegate>

@property (strong, nonatomic) CALObject *detailItem;

@property (weak, nonatomic) IBOutlet UILabel *placeTypeLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *openingsLabel;

@property (weak, nonatomic) IBOutlet UILabel *distance;
@property (strong, nonatomic) UIImagePickerController * picker;
@property (weak, nonatomic) IBOutlet UILabel *likeCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *dislikeCountLabel;

@property (weak, nonatomic) IBOutlet ThumbsPreviewView *likersPreviewView;
@property (weak, nonatomic) IBOutlet ThumbsPreviewView *clientsPreviewView;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *likeActivity;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *dislikeActivity;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet UIImageView *tagImage1;
@property (weak, nonatomic) IBOutlet UIImageView *tagImage2;
@property (weak, nonatomic) IBOutlet UIImageView *tagImage3;
@property (weak, nonatomic) IBOutlet UIImageView *statusImage;

- (IBAction)likeTapped:(id)sender;
- (IBAction)dislikeTapped:(id)sender;
- (IBAction)headingBlockTapped:(id)sender;


@end
