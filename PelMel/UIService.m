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
#import "PMLPlaceInfoProvider.h"
#import "PMLUserInfoProvider.h"
#import "PMLSnippetTableViewController.h"
#import "PMLContextInfoProvider.h"
#import "PMLCityInfoProvider.h"
#import "PMLEventInfoProvider.h"
#import "PMLEventTableViewCell.h"
#import "UIImage+ImageEffects.h"
#import <MBProgressHUD.h>

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
    UIView *_progressView;
    MBProgressHUD *_progressHUD;
    
    // Cache
    NSCache *nibCache;
}

- (id)init
{
    self = [super init];
    if (self) {
        storyboard = [UIStoryboard storyboardWithName:[[NSBundle mainBundle].infoDictionary objectForKey:@"UIMainStoryboardFile"] bundle:[NSBundle mainBundle]];

        // Cache for nib objects
        nibCache = [[NSCache alloc] init];
        
        // Loading profile header view
        waitingView = (UIWaitingView*)[self loadView:@"UIWaitingView"];
        

    }
    return self;
}
- (void)start:(UIWindow *)window {
    
}
- (UIColor *)colorForObject:(NSObject *)obj {
    NSString *placeType = @"";
    NSString *colorPrefKey;
    if([obj isKindOfClass:[Place class]]) {
        return [UIColor whiteColor];
//        NSString *placeType = ((Place*)obj).placeType;
//        if(placeType == nil) {
//            placeType = @"bar";
//        }
//        placeType = [NSString stringWithFormat:@"placeType.%@",placeType];
//        colorPrefKey = [NSString stringWithFormat:kColorPrefKeyTemplate, placeType];
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
//    // Are we split ?
//    if(controller.splitViewController != nil) {
//        // Getting leftmost navigation controller
//        UINavigationController *navController = [controller.splitViewController.viewControllers objectAtIndex:0];
//        if(filtersViewController == nil) {
//            // Creating filters controller if not yet created
//            filtersViewController = [self instantiateViewController:SB_ID_FILTERS_CONTROLLER];
//        } else {
//            [filtersViewController removeFromParentViewController];
//        }
//        [navController pushViewController:filtersViewController animated:YES];
//    } else {
//        [self.revealViewController revealToggleAnimated:YES];
//    }
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
    UINib *nib = [nibCache objectForKey:nibName];
    if(nib==nil) {
        nib = [UINib nibWithNibName:nibName bundle:[NSBundle mainBundle]];
        [nibCache setObject:nib forKey:nibName];
    }
    NSArray *nibViews = [nib instantiateWithOwner:self options:nil];
    return [nibViews objectAtIndex:0];
}
#pragma mark - Providers
- (NSObject<PMLInfoProvider> *)infoProviderFor:(CALObject *)object {
    NSObject<PMLInfoProvider> *infoProvider;
    
    if([object isKindOfClass:[Place class]]) {
        infoProvider = [[PMLPlaceInfoProvider alloc] initWith:(Place*)object];
    } else if([object isKindOfClass:[User class]]) {
        infoProvider = [[PMLUserInfoProvider alloc] initWithUser:(User *)object];
    } else if([object isKindOfClass:[Event class]]) {
        infoProvider = [[PMLEventInfoProvider alloc] initWithEvent:(Event*)object];
    } else if([object isKindOfClass:[City class]]) {
        infoProvider = [[PMLCityInfoProvider alloc] initWithCity:(City *)object];
    } else if(object== nil) {
        infoProvider = [[PMLContextInfoProvider alloc] init];
    }
    return infoProvider;
}
- (PMLProperty *)propertyFrom:(id<PMLInfoProvider>)infoProvider forCode:(NSString *)propertyCode {
    if([infoProvider respondsToSelector:@selector(properties)]) {
        for(PMLProperty *property in infoProvider.properties) {
            if([property.propertyCode isEqualToString:propertyCode]) {
                return property;
            }
        }
    }
    return nil;
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
    NSString *template = NSLocalizedString(@"time.formatter", nil);
    if(delta < 0) {
        template = NSLocalizedString(@"time.formatter.future",nil);
        delta = ABS(delta);
    }
    
    if(delta < 60) {
        delta = 60;
    }
    NSString *timeStr;
    long value;
    if(delta < 3600 || delta > 999999999) {
        // Display in minutes
        value = delta / 60;
        timeStr = [self localizedString:@"user.loc.minutes" forCount:value];
    } else if(delta < 86400) {
        // Display in hours
        value = delta / 3600;
        timeStr = [self localizedString:@"user.loc.hours" forCount:value];
    } else {
        // Display in days
        value = delta / 86400;
        timeStr = [self localizedString:@"user.loc.days" forCount:value];
    }
    
    NSString *line = [NSString stringWithFormat:template,timeStr];
    return line;
}

-(UIView*)addProgressTo:(UINavigationController *)controller {
    // Do any additional setup after loading the view.
    _progressView = controller.view;
    return nil;
}
-(void)setProgressView:(UIView *)progressView {
    if(progressView == nil) {
        _progressView = _menuManagerController.view;
    } else {
        _progressView = progressView;
    }
}
- (void)reportProgress:(float)progress {
    if(_progressHUD == nil) {
        _progressHUD = [MBProgressHUD showHUDAddedTo:_progressView animated:YES];
        _progressHUD.mode = MBProgressHUDModeAnnularDeterminate;
    }
    _progressHUD.progress = progress;
    if(progress >= 1.0f) {
        [self progressDone];
    }
}
-(void)progressDone {
    if(_progressHUD != nil) {
        [MBProgressHUD hideHUDForView:_progressView animated:YES];
        _progressHUD = nil;
    }
}

- (void)presentSnippetFor:(CALObject *)object opened:(BOOL)opened {
    [self presentSnippetFor:object opened:opened root:NO];
}
- (void)presentSnippetFor:(CALObject *)object opened:(BOOL)opened root:(BOOL)root {
    // Building controller
    PMLSnippetTableViewController *snippetController = (PMLSnippetTableViewController*)[self instantiateViewController:SB_ID_SNIPPET_CONTROLLER];
    snippetController.snippetItem = object;
    
    // Presenting in snippet
    [self presentSnippet:snippetController opened:opened root:root];
    if(!opened && object.key != nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PML_HELP_SNIPPET object:self];
    }
}
- (void)presentSnippet:(UIViewController *)snippetController opened:(BOOL)opened root:(BOOL)root {
    
    if(_menuManagerController.navigationController.topViewController != _menuManagerController) {
        [_menuManagerController presentControllerSnippet:snippetController animated:NO];
        [_menuManagerController openCurrentSnippet:NO];
        [_menuManagerController.navigationController popToRootViewControllerAnimated:YES];
    } else {
        BOOL isOpened = _menuManagerController.snippetFullyOpened;
        if(isOpened) {
            if(opened) {
                [self pushSnippetNavigationController:snippetController];
            } else {
                [_menuManagerController presentControllerSnippet:snippetController animated:YES];
            }
        } else {
            if(_menuManagerController.currentSnippetViewController != nil && !root) {
                [self pushSnippetNavigationController:snippetController];
                [_menuManagerController dismissControllerMenu:YES];
                if(opened) {
                    [_menuManagerController openCurrentSnippet:!isOpened];
                }
            } else {
                [_menuManagerController presentControllerSnippet:snippetController animated:YES opened:opened];
            }
            
        }
    }
    if(!opened) {
        [_menuManagerController minimizeCurrentSnippet:YES];
    }
}
- (void)presentController:(UIViewController *)controller {
    if(self.menuManagerController.navigationController.topViewController != self.menuManagerController) {
        [self.menuManagerController.navigationController pushViewController:controller animated:YES];
    } else {
        [(UINavigationController*)self.menuManagerController.currentSnippetViewController pushViewController:controller animated:YES];
        [self.menuManagerController openCurrentSnippet:YES];
    }
}
/**
 * Pushes the snippet controller on the current navigation stack presented in the snippet. It handles
 * situations when a view controller with the same object may already be presented by removing it from hierarchy 
 * and places it on top
 */
-(void)pushSnippetNavigationController:(UIViewController*)controller {
    UINavigationController *navigationController = (UINavigationController*)_menuManagerController.currentSnippetViewController;
    UIViewController *controllerToPush = controller;
    BOOL isRoot = navigationController.childViewControllers.count == 1;
    
    // Preparing array of child view controllers
    NSMutableArray *childViewControllers =  [navigationController.childViewControllers mutableCopy];
    if([controller isKindOfClass:[PMLSnippetTableViewController class]]) {
        PMLSnippetTableViewController *snippetController = (PMLSnippetTableViewController*)controller;
        for(UIViewController *controller in navigationController.childViewControllers) {
            
            // Checking snippet controllers
            if([controller isKindOfClass:[PMLSnippetTableViewController class]]) {
                PMLSnippetTableViewController *childSnippet = (PMLSnippetTableViewController*)controller;
                
                // Is this controller presenting the same object?
                if([childSnippet.snippetItem.key isEqualToString:snippetController.snippetItem.key]) {
                    
                    // Just in case we have 2 different objects (memory NSCache flush maybe)
                    // This call will also do a refresh
                    childSnippet.snippetItem = snippetController.snippetItem;
                    if(!isRoot && childSnippet!=navigationController.topViewController) {
                        [childViewControllers removeObject:childSnippet];
                        controllerToPush = childSnippet;
                    } else {
                        controllerToPush = nil;
                    }
                }
            }
        }
    }
    // Replacing Nav controller hierarchy (as we may have removed one)
    [navigationController setViewControllers:childViewControllers animated:NO];
    if(controllerToPush != nil) {
        [navigationController pushViewController:controllerToPush animated:YES];
        // Resetting offset to the top for table view controllers (to avoid a minimized snippet not showing its top content)
        if([controllerToPush isKindOfClass:[UITableViewController class]]) {
            ((UITableViewController*)controllerToPush).tableView.contentOffset=CGPointMake(0, 0);
        }
    }
}

- (void)alertWithTitle:(NSString *)titleKey text:(NSString *)textKey {
    [self alertWithTitle:titleKey text:textKey textObjectName:nil];
}
- (void)alertWithTitle:(NSString *)titleKey text:(NSString *)textKey textObjectName:(NSString *)textObjName {
    NSString *title = NSLocalizedString(titleKey,titleKey);
    NSString *msg = NSLocalizedString(textKey,textKey);
    if(textObjName!=nil) {
        msg = [NSString stringWithFormat:msg,textObjName];
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}
- (void)alertError {
    [self alertWithTitle:NSLocalizedString(@"action.failure.title", "Error") text:NSLocalizedString(@"action.failure.message", @"An error has occurred")];
}

- (NSString *)localizedString:(NSString *)translateKey forCount:(NSInteger)count {
    NSString *template = NSLocalizedString(translateKey,translateKey);
    if(count==1) {
        NSString *singularKey = [translateKey stringByAppendingString:@".singular"];
        NSString *singular = NSLocalizedString(singularKey,@"singular");
        if(![singular isEqualToString:singularKey]) {
            template = singular;
        }
    }
    return [NSString stringWithFormat:template,count];
}
#pragma mark - Image effects
- (UIImage *)takeSnapshotOfView:(UIView *)view
{
//    return [view snapshotViewAfterScreenUpdates:YES]
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

#pragma mark - Naming
-(NSString*)nameForEvent:(Event*)event {
    NSString *name = event.name;
    if([event isKindOfClass:[PMLCalendar class]]) {
        if(event.name==nil || event.name.length<=3) {
            NSString *template = [NSString stringWithFormat:@"special.label.%@",((PMLCalendar*)event).calendarType];
            name= NSLocalizedString(template,template);
        }
    }
    return [name uppercaseString];
}

#pragma mark - Factorized component display
-(void)configureRowOvEvents:(PMLEventTableViewCell*)cell forEvent:(Event*)event usingInfoProvider:(id<PMLInfoProvider>)infoProvider {
    cell.image.image = nil;
    
    CALImage *calEventImage;
    if([infoProvider respondsToSelector:@selector(imageForEvent:)]) {
        calEventImage = [infoProvider imageForEvent:event];
    } else {
        calEventImage = [[TogaytherService imageService] imageOrPlaceholderFor:event allowAdditions:YES];
    }
    [[TogaytherService imageService] load:calEventImage to:cell.image thumb:NO];
    
    cell.titleLabel.text = [self nameForEvent:event];
    cell.dateLabel.text = [[TogaytherService getConversionService] eventDateLabel:event isStart:YES];
    cell.locationIcon.image = [UIImage imageNamed:@"snpIconMarker"];
    if(event.place.cityName != nil) {
        cell.locationLabel.text = [NSString stringWithFormat:@"%@, %@",event.place.title,event.place.cityName];
    } else {
        cell.locationLabel.text = event.place.title;
    }
    if(event.likeCount>0) {
        cell.countLabel.text = [self localizedString:@"snippet.event.inUsers" forCount:event.likeCount];
        cell.countIcon.image=[UIImage imageNamed:@"snpIconEvent"];
    } else {
        cell.countIcon.image = nil;
        cell.countLabel.text = nil;
    }
    
    // Separator
    cell.separatorImage.image = [UIImage imageNamed:@"ovvSeparatorV"];
    cell.separatorImage.layer.borderWidth=0;
    cell.bgBorderImage.image = nil;
    cell.bgBorderImage.backgroundColor = UIColorFromRGB(0x31363a);
}

-(void)configureRowPlace:(PMLEventTableViewCell*)cell place:(Place*)place {
    cell.dateLabel.text = place.title;
    NSString *distanceStr = [[TogaytherService getConversionService] distanceTo:place];
    NSString *placeType = [[[TogaytherService settingsService] getPlaceType:place.placeType] label];
    cell.titleLabel.text = [NSString stringWithFormat:@"%@ - %@",distanceStr,placeType];
    
    // Subtitle (like count)
    cell.countIcon.image = [UIImage imageNamed:@"snpIconLikeWhite"];
    cell.countLabel.text = [self localizedString:@"counters.likes" forCount:place.likeCount];
    cell.locationLabel.text = place.cityName;
    
    cell.separatorImage.image = nil;
    cell.separatorImage.layer.borderWidth=1;
    cell.separatorImage.layer.borderColor = [UIColorFromRGB(0x22405a) CGColor];
    //    // Checkins count
    //    if(place.inUserCount>0) {
    //        cell.checkinLabel.text = [_uiService localizedString:@"counters.arehere" forCount:place.inUserCount];
    //        cell.checkinImageView.image = [UIImage imageNamed:@"snpIconMarker"];
    //    } else {
    //        cell.checkinImageView.image = nil;
    //        cell.checkinLabel.text = nil;
    //    }
    
    // Setting distance
    //    NSString *distance = [_conversionService distanceTo:place];
    //    cell.distanceLabel.text = distance;
    //    size = [cell.distanceLabel sizeThatFits:CGSizeZero];
    //    cell.widthDistanceLabelConstraint.constant = size.width;
    
    // Loading image
    cell.image.image = [CALImage getDefaultThumb];
    [[TogaytherService imageService] load:place.mainImage to:cell.image thumb:NO];
    cell.bgBorderImage.image = [UIImage imageNamed:@"bgTopHang2"];
    cell.bgBorderImage.backgroundColor = nil;
}

@end
