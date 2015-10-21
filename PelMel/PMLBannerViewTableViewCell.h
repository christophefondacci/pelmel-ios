//
//  PMLBannerViewTableViewCell.h
//  PelMel
//
//  Created by Christophe Fondacci on 22/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "PMLBanner.h"

@interface PMLBannerViewTableViewCell : UITableViewCell <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *bannerImageView;

@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UILabel *startedOnLabel;
@property (weak, nonatomic) IBOutlet UILabel *startDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *usageLabel;
@property (weak, nonatomic) IBOutlet UILabel *usageCounterLabel;
@property (weak, nonatomic) IBOutlet UILabel *targetLinkLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic,retain) PMLBanner *banner;
@end
