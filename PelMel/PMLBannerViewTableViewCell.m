//
//  PMLBannerViewTableViewCell.m
//  PelMel
//
//  Created by Christophe Fondacci on 22/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLBannerViewTableViewCell.h"

@interface PMLBannerViewTableViewCell()
@property (nonatomic,retain) MKCircle *bannerCircle;
@end
@implementation PMLBannerViewTableViewCell

- (void)awakeFromNib {
    // Initialization code
    // Selection color
//    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor colorWithRed:0.92 green:0.46 blue:0 alpha:1];
    [self setSelectedBackgroundView:bgColorView];
    
    self.mapView.delegate = self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


-(void)setBanner:(PMLBanner *)banner {
    if(![banner.key isEqualToString:self.banner.key]) {
        _banner = banner;
        [self refreshBannerArea];
    }
}

-(void)refreshBannerArea {
    if(self.bannerCircle != nil) {
        [self.mapView removeOverlay:self.bannerCircle];
    }
    // Creating circular shape
    CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(self.banner.lat,self.banner.lng);
    self.bannerCircle = [MKCircle circleWithCenterCoordinate:coords radius:kPMLBannerMilesRadius*METERS_PER_MILE];
    [self.mapView addOverlay:self.bannerCircle];
    
    // Centering map
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(coords, kPMLBannerMilesRadius*4.0f*METERS_PER_MILE, kPMLBannerMilesRadius*4.0f*METERS_PER_MILE);
    MKCoordinateRegion adjustedRegion = [_mapView regionThatFits:viewRegion];
    MKMapRect mapRect = [self MKMapRectForCoordinateRegion:adjustedRegion];
    [_mapView setVisibleMapRect:mapRect animated:NO];
    
}
- (MKMapRect) MKMapRectForCoordinateRegion:(MKCoordinateRegion) region
{
    MKMapPoint a = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
                                                                      region.center.latitude + region.span.latitudeDelta / 2,
                                                                      region.center.longitude - region.span.longitudeDelta / 2));
    MKMapPoint b = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
                                                                      region.center.latitude - region.span.latitudeDelta / 2,
                                                                      region.center.longitude + region.span.longitudeDelta / 2));
    return MKMapRectMake(MIN(a.x,b.x), MIN(a.y,b.y), ABS(a.x-b.x), ABS(a.y-b.y));
}

#pragma mark - MKMapViewDelegate
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    
    MKCircleRenderer *renderer = [[MKCircleRenderer alloc] initWithCircle:self.bannerCircle];
    renderer.fillColor = [UIColor colorWithRed:0.92 green:0.46 blue:0 alpha:0.4f];
    renderer.strokeColor = [UIColor colorWithRed:0.92 green:0.46 blue:0 alpha:1];
    
    return renderer;
}
@end
