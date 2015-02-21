//
//  UIService.m
//  PelMel
//
//  Created by Christophe Fondacci on 30/01/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "UIService.h"
#import "TogaytherService.h"
#import "Event.h"
#import "PlaceType.h"
#import "Constants.h"
#import "UIWaitingView.h"
#import "PlaceDetailProvider.h"
#import "EventDetailProvider.h"
#import "UserDetailProvider.h"
#import "PlaceMasterProvider.h"
#import "EventMasterProvider.h"
#import "CityDetailProvider.h"
#import "PMLPlaceInfoProvider.h"
#import "PMLUserInfoProvider.h"
#import "PMLSnippetTableViewController.h"
#import "PMLContextInfoProvider.h"
#import "PMLCityInfoProvider.h"
#import "UIImage+ImageEffects.h"


#define kColorPrefKeyTemplate @"color.%@"
#define kPMLMarkerPrefKeyTemplate @"marker.%@"
#define kPMLMarkerDisabledPrefKeyTemplate @"marker.%@.closed"
#define kPMLMarkerOffsetPrefKeyTemplate @"marker.offset.%@.%@"
#define kDefaultColorHex @"ff8000"
#define OFFSET  0.003

@implementation UIService {
    UIStoryboard *storyboard;
    UIViewController *filtersViewController;
    float currentAngle;
    
    // Our view for displaying a waiting overlay
    UIWaitingView *waitingView;
    
    UIWindow *currentWindow;
    UIImageView *insideMarker;
    UIImageView *outsideMarker;
    BOOL isWaiting;
    
    UIDynamicAnimator *animator;
    UIProgressView *_progressView;
}

- (id)init
{
    self = [super init];
    if (self) {
        storyboard = [UIStoryboard storyboardWithName:[[NSBundle mainBundle].infoDictionary objectForKey:@"UIMainStoryboardFile"] bundle:[NSBundle mainBundle]];
        
        // Loading profile header view
        NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"UIWaitingView" owner:self options:nil];
        waitingView = [views objectAtIndex:0];
    }
    return self;
}
- (void)start:(UIWindow *)window {
    
}
- (UIColor *)colorForObject:(NSObject *)obj {
    NSString *placeType = @"";
    NSString *colorPrefKey;
    if([obj isKindOfClass:[Place class]]) {
        placeType = [NSString stringWithFormat:@"placeType.%@",((Place*)obj).placeType];
        colorPrefKey = [NSString stringWithFormat:kColorPrefKeyTemplate, placeType];
    } else if([obj isKindOfClass:[Event class]]) {
        colorPrefKey = [NSString stringWithFormat:kColorPrefKeyTemplate, @"event"];
    } else if([obj isKindOfClass:[PlaceType class]]) {
        placeType = [NSString stringWithFormat:@"placeType.%@",((PlaceType*)obj).code];
        colorPrefKey = [NSString stringWithFormat:kColorPrefKeyTemplate, placeType];
    } else if([obj isKindOfClass:[User class]]) {
        User *user = (User*)obj;
        if(user.isOnline) {
            colorPrefKey = @"color.user.online";
        } else {
            colorPrefKey = @"color.user.offline";
        }
    }
    // Looking for color definition in config file
    UIColor *color = [TogaytherService propertyAsColorFor:colorPrefKey];
    // Building RGB
    return color;
}

-(NSString*)hexColorForPlaceType:(NSString*)placeType {
    NSString *colorKey = [NSString stringWithFormat:kColorPrefKeyTemplate, placeType];
    NSString *colorHex = [TogaytherService propertyFor:colorKey];
    return colorHex;
}
- (MapViewController *)mapControllerFromSplitView:(UISplitViewController *)splitViewController {
    return self.splitMapController;
}

- (UIViewController *)instantiateViewController:(NSString *)controllerId {
    return [storyboard instantiateViewControllerWithIdentifier:controllerId];
}
- (BOOL)isIpad:(UIViewController *)controller {
    return controller.splitViewController!=nil;
}
-(void)showFiltersViewControllerFor:(UIViewController *)controller {
    // Are we split ?
    if(controller.splitViewController != nil) {
        // Getting leftmost navigation controller
        UINavigationController *navController = [controller.splitViewController.viewControllers objectAtIndex:0];
        if(filtersViewController == nil) {
            // Creating filters controller if not yet created
            filtersViewController = [self instantiateViewController:SB_ID_FILTERS_CONTROLLER];
        } else {
            [filtersViewController removeFromParentViewController];
        }
        [navController pushViewController:filtersViewController animated:YES];
    } else {
        [self.revealViewController revealToggleAnimated:YES];
    }
}

#pragma mark - UISplitViewControllerDelegate
- (void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)pc {
    self.popoverBarButtonItem = barButtonItem;
    self.popoverController = pc;
}

//-(void)setCompassObject:(CALObject*)obj {
//    UserService *userService = TogaytherService.userService;
//    CLLocation *location = userService.currentLocation;
//    CLLocationCoordinate2D objLocation = CLLocationCoordinate2DMake(obj.lat, obj.lng);
//    
//    float compassAngle = [self getHeadingForDirectionFromCoordinate:location.coordinate toCoordinate:objLocation];
//    float currentBearing = location.course / 180.0f * M_PI;
////    if(currentAngle != 0) {
////        
////    }
//
//    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//        _pelmelCompass.transform = CGAffineTransformMakeRotation(compassAngle-currentBearing);
//    } completion:nil];
//    
//    // Assigning angle
//    currentAngle = compassAngle;
//    if(obj != nil) {
//        [locationManager startUpdatingHeading];
//    }
//}
- (float) getHeadingForDirectionFromCoordinate:(CLLocationCoordinate2D)fromLoc toCoordinate:(CLLocationCoordinate2D)toLoc
{
    float fLat = fromLoc.latitude/180.0f * M_PI;
    float fLng = fromLoc.longitude/180.0f * M_PI;
    float tLat = toLoc.latitude/180.0f * M_PI;
    float tLng = toLoc.longitude/180.0f * M_PI;
    
    return atan2(sin(tLng-fLng)*cos(tLat), cos(fLat)*sin(tLat)-sin(fLat)*cos(tLat)*cos(tLng-fLng));
}
-(UIView *)loadView:(NSString *)nibName {
    NSArray *nibViews = [[NSBundle mainBundle] loadNibNamed:nibName owner:self options:nil];
    return [nibViews objectAtIndex:0];
}
#pragma mark - Providers
- (NSObject<DetailProvider>*)buildProviderFor:(CALObject *)object {
    id<DetailProvider> detailProvider = nil;
    if([object isKindOfClass:[Place class]]) {
        detailProvider = [[PlaceDetailProvider alloc] initWithPlace:(Place*)object];
    } else if([object isKindOfClass:[User class]]) {
        detailProvider = [[UserDetailProvider alloc] initWithUser:(User *)object];
    } else if([object isKindOfClass:[Event class]]) {
        detailProvider = [[EventDetailProvider alloc] initWithEvent:(Event*)object];
    } else if([object isKindOfClass:[City class]]) {
        detailProvider = [[CityDetailProvider alloc] initWithCity:(City*)object];
    }
    return detailProvider;
}
- (NSObject<MasterProvider>*)masterProviderFor:(CALObject *)object {
    if([object isKindOfClass:[Place class]]) {
        return [[PlaceMasterProvider alloc] init];
    } else if([object isKindOfClass:[Event class]]) {
        return [[EventMasterProvider alloc] init];
    } else {
        return nil;
    }
}
- (NSObject<PMLInfoProvider> *)infoProviderFor:(CALObject *)object {
    NSObject<PMLInfoProvider> *infoProvider;
    
    if([object isKindOfClass:[Place class]]) {
        infoProvider = [[PMLPlaceInfoProvider alloc] initWith:(Place*)object];
    } else if([object isKindOfClass:[User class]]) {
        infoProvider = [[PMLUserInfoProvider alloc] initWithUser:(User *)object];
    } else if([object isKindOfClass:[City class]]) {
        infoProvider = [[PMLCityInfoProvider alloc] initWithCity:(City *)object];
    } else if(object== nil) {
        infoProvider = [[PMLContextInfoProvider alloc] init];
    }
    return infoProvider;
}
#pragma mark - Map / markers
-(UIImage *)mapMarkerFor:(CALObject *)object enabled:(BOOL)enabled {
    UIImage *marker;
    NSString *imageName;
    if([object isKindOfClass:[Place class]]) {
        Place *place = (Place*)object;
        NSString *prop = [NSString stringWithFormat:enabled ? kPMLMarkerPrefKeyTemplate : kPMLMarkerDisabledPrefKeyTemplate,place.placeType];
        
        imageName = [TogaytherService propertyFor:prop];
    } else if([object isKindOfClass:[City class]] ) {
        imageName = @"mapMarkerCity";
    }
    if(imageName == nil) {
        imageName = enabled ? @"mapMarkerDefault" : @"mapMarkerDefaultOff";
    }
    marker = [UIImage imageNamed:imageName];

    return marker;
}
-(CGPoint)mapMarkerCenterOffsetFor:(CALObject *)object {
    CGPoint offset;
    NSNumber *offsetX;
    NSNumber *offsetY;
    NSString *propX;
    NSString *propY;
    if([object isKindOfClass:[Place class]]) {
        Place *place = (Place*)object;

        propX = [NSString stringWithFormat:kPMLMarkerOffsetPrefKeyTemplate,place.placeType,@"x"];
        propY = [NSString stringWithFormat:kPMLMarkerOffsetPrefKeyTemplate,place.placeType,@"y"];
        offsetX = [TogaytherService propertyAsNumberFor:propX];
        offsetY = [TogaytherService propertyAsNumberFor:propY];
    }
    if(offsetX == nil || offsetY == nil) {
        propX = [NSString stringWithFormat:kPMLMarkerOffsetPrefKeyTemplate,@"default",@"x"];
        propY = [NSString stringWithFormat:kPMLMarkerOffsetPrefKeyTemplate,@"default",@"y"];
        offsetX = [TogaytherService propertyAsNumberFor:propX];
        offsetY = [TogaytherService propertyAsNumberFor:propY];
    }
    
    offset = CGPointMake(offsetX.floatValue, offsetY.floatValue);

    return offset;
}
//#pragma mark - CLLocationManagerDelegate
//- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
//    float currentBearing = newHeading.trueHeading / 180.0f * M_PI;
//    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//        _pelmelCompass.transform = CGAffineTransformMakeRotation(currentAngle-currentBearing);
//    } completion:nil];
//}

-(NSString*)delayStringFrom:(NSDate *)date {
    long now = [[NSDate date] timeIntervalSince1970];
    long locTime = [date timeIntervalSince1970];
    long delta = now -locTime;
    if(delta < 60) {
        delta = 60;
    }
    NSString *timeScale;
    long value;
    if(delta < 3600 || delta > 999999999) {
        // Display in minutes
        value = delta / 60;
        timeScale = NSLocalizedString(@"user.loc.minutes", nil);
    } else if(delta < 86400) {
        // Display in hours
        value = delta / 3600;
        timeScale = NSLocalizedString(@"user.loc.hours", nil);
    } else {
        // Display in days
        value = delta / 86400;
        timeScale = NSLocalizedString(@"user.loc.days", nil);
    }
    NSString *template = NSLocalizedString(@"time.formatter", nil);
    NSString *line = [NSString stringWithFormat:template,value,timeScale];
    return line;
}

-(UIProgressView*)addProgressTo:(UINavigationController *)controller {
    // Do any additional setup after loading the view.
    
    _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];

    UINavigationBar *navBar = [controller navigationBar];
    [navBar layoutIfNeeded];
    [controller.view addSubview:_progressView];
    
    NSLayoutConstraint *constraint;
    constraint = [NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:navBar attribute:NSLayoutAttributeBottom multiplier:1 constant:-0.5];
    [controller.view addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:navBar attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
    [controller.view addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:navBar attribute:NSLayoutAttributeRight multiplier:1 constant:0];
    [controller.view addConstraint:constraint];
    
    [_progressView setTranslatesAutoresizingMaskIntoConstraints:NO];
    _progressView.hidden = YES;
    return _progressView;
}
-(void)setProgressView:(UIProgressView *)progressView {
    _progressView = progressView;
}
- (void)reportProgress:(float)progress {
    _progressView.hidden=NO;
    [_progressView setProgress:progress];
}
-(void)progressDone {
    _progressView.hidden=YES;
}

- (void)presentSnippetFor:(CALObject *)object opened:(BOOL)opened {
    PMLSnippetTableViewController *snippetController = (PMLSnippetTableViewController*)[self instantiateViewController:SB_ID_SNIPPET_CONTROLLER];
    snippetController.snippetItem = object;
    [_menuManagerController presentControllerSnippet:snippetController];
    if(opened) {
        [_menuManagerController openCurrentSnippet];
    }
}

- (void)alertWithTitle:(NSString *)titleKey text:(NSString *)textKey {
    NSString *title = NSLocalizedString(titleKey,titleKey);
    NSString *msg = NSLocalizedString(textKey,textKey);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}
- (void)alertError {
    [self alertWithTitle:NSLocalizedString(@"action.failure.title", "Error") text:NSLocalizedString(@"action.failure.message", @"An error has occurred")];
}
#pragma mark - Image effects
- (UIImage *)takeSnapshotOfView:(UIView *)view
{
    CGFloat reductionFactor = 1;
    UIGraphicsBeginImageContext(CGSizeMake(view.frame.size.width/reductionFactor, view.frame.size.height/reductionFactor));
    [view drawViewHierarchyInRect:CGRectMake(0, 0, view.frame.size.width/reductionFactor, view.frame.size.height/reductionFactor) afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIImage *)blurWithImageEffects:(UIView *)view
{
    // Taking snapshot
    UIImage *image = [self takeSnapshotOfView:view];
    // Bluring
    return [image applyBlurWithRadius:5 tintColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.2] saturationDeltaFactor:1.0 maskImage:nil];
}
@end
