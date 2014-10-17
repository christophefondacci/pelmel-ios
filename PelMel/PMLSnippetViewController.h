//
//  SnippetViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 26/07/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataService.h"
#import "ThumbsPreviewView.h"
#import "PMLImageTableViewController.h"
#import "KIImagePager.h"
#import "ThumbsPreviewView.h"
#import "ThumbTableViewController.h"




@interface PMLSnippetViewController : UIViewController <PMLDataListener, PMLThumbsTableViewActionDelegate, UITextFieldDelegate, PMLImageGalleryDelegate, KIImagePagerDataSource, KIImagePagerDelegate>

@property (weak,nonatomic) CALObject *snippetItem;

@property (weak, nonatomic) IBOutlet UILabel *thumbSubtitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *thumbView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UIView *peopleView;
@property (weak, nonatomic) IBOutlet UIView *colorLineView;
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UIView *hoursBadgeView;
@property (weak, nonatomic) IBOutlet UILabel *hoursBadgeTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *hoursBadgeSubtitleLabel;
@property (weak, nonatomic) IBOutlet KIImagePager *galleryView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIImageView *titleDecorationImage;

@property (weak, nonatomic) IBOutlet UILabel *likesCounterLabel;
@property (weak, nonatomic) IBOutlet UILabel *checkinsCounterLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentsCounterLabel;
@property (weak, nonatomic) IBOutlet UIView *countersView;

@property (weak, nonatomic) IBOutlet UIView *gestureView;

@end
