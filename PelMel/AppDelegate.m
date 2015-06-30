//
//  AppDelegate.m
//  nativeTest
//
//  Created by Christophe Fondacci on 20/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "AppDelegate.h"
#import "MapViewController.h"
#import "MessageViewController.h"
#import "FiltersViewController.h"
#import "TogaytherTabBarController.h"
#import "TogaytherService.h"
#import "MainMenuTableViewController.h"
#import "PMLMenuManagerController.h"
#import "UIMenuManagerMainDelegate.h"
#import "MenuAction.h"
#import "Constants.h"
#import "NSData+Conversion.h"
#import "PMLDataManager.h"
#import <FacebookSDK/FacebookSDK.h>
#import <AFNetworkActivityLogger.h>
#import <iRate.h>

typedef void (^Callback)(CALObject *obj);

@interface AppDelegate()

// For deep linking state
@property (nonatomic,retain) CALObject *deepLinkObject;
@property (nonatomic,copy) Callback deepLinkCallback;

@end
@implementation AppDelegate

static BOOL isStarted;

+ (void)initialize
{
    //set the bundle ID. normally you wouldn't need to do this
    //as it is picked up automatically from your Info.plist file
    //but we want to test with an app that's actually on the store
    [iRate sharedInstance].applicationBundleID = @"com.nextep.PelMel";
    [iRate sharedInstance].onlyPromptIfLatestVersion = NO;
    [iRate sharedInstance].usesUntilPrompt=5;
    
    //enable preview mode
//    [iRate sharedInstance].previewMode = YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//    [[AFNetworkActivityLogger sharedLogger] startLogging];
//    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelDebug];
//    for (NSString* family in [UIFont familyNames])
//    {
//        NSLog(@"%@", family);
//        
//        for (NSString* name in [UIFont fontNamesForFamilyName: family])
//        {
//            NSLog(@"  %@", name);
//        }
//    }
    
    // Starting services
    [TogaytherService start];
    UIService *uiService = TogaytherService.uiService;
    MapViewController *mapView = (MapViewController*)[uiService instantiateViewController:@"mapItemsView"];
    
    // Facebook init
    [FBLoginView class];
    // ------------ NEW PELMEL NAV

    UIMenuManagerMainDelegate *mainDelegate = [[UIMenuManagerMainDelegate alloc] init];
    PMLMenuManagerController * menuManagerController = (PMLMenuManagerController*)[uiService instantiateViewController:SB_ID_MENU_MANAGER];
//[[PMLMenuManagerController alloc] initWithViewController:mapView with:mainDelegate];
    menuManagerController.menuManagerDelegate = mainDelegate;
    menuManagerController.rootViewController = mapView;
    UINavigationController *rootNavMenuController = [[UINavigationController alloc] initWithRootViewController:menuManagerController];
    self.window.rootViewController = rootNavMenuController;
    
//    CGRect winFrame = self.window.frame;
//    UIView *view=[[UIView alloc] initWithFrame:CGRectMake(0, 0,winFrame.size.width, 20)];
//    view.backgroundColor=[UIColor blackColor];
//    view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//    [self.window.rootViewController.view addSubview:view];
    
    [TogaytherService.uiService start:self.window];
    TogaytherService.uiService.menuManagerController = menuManagerController;
    
    // Checking if we are started with an URL
    NSURL *url = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];

    if(url != nil) {
        [self openURL:url searchCallback:^(CALObject *object) {
            [menuManagerController.dataManager setInitialContext:object isSearch:YES];
        } overviewCallback:^(CALObject *object) {
            [menuManagerController.dataManager setInitialContext:object isSearch:NO];
        }];
    }
    
    
    [[UITableView appearance] setSeparatorInset:UIEdgeInsetsZero];
    [[UITableViewCell appearance] setSeparatorInset:UIEdgeInsetsZero];
    
    if ([UITableView instancesRespondToSelector:@selector(setLayoutMargins:)]) {
//        [[UITableView appearance] setLayoutMargins:UIEdgeInsetsZero];
        [[UITableViewCell appearance] setLayoutMargins:UIEdgeInsetsZero];
        [[UITableViewCell appearance] setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Registering ourselves as a listener for deeplinking
    [[TogaytherService dataService] registerDataListener:self];
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    if(!isStarted) {
        isStarted = YES;
    } else {
        // Downloading messages for proper count display
        User *currentUser = [[TogaytherService userService] getCurrentUser];
        [[TogaytherService getMessageService] getMessagesWithUser:currentUser.key messageCallback:nil];

        // Refreshing places data
        DataService *dataService = [TogaytherService dataService];
//        [dataService setCurrentRadius:0];
        if([dataService modelHolder].places.count>0) {
//            [[[[TogaytherService uiService] menuManagerController] rootViewController] setZoomUpdateType:PMLZoomUpdateNone];
            [dataService fetchPlacesAtLatitude:dataService.currentLatitude longitude:dataService.currentLongitude for:nil searchTerm:dataService.searchTerm radius:dataService.currentRadius silent:YES];
        }

    }

}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    // Delegating to message service
    [[TogaytherService getMessageService] didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Delegating to message service
    [[TogaytherService getMessageService] didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"didReceiveRemoteNotification");
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"didReceiveRemoteNotification:fetchCompletionHandler");
    if(application.applicationState == UIApplicationStateInactive) {
        
        NSLog(@"Inactive");
        
    } else if (application.applicationState == UIApplicationStateBackground) {
        
        NSLog(@"Background");
        
    } else {
        
        NSLog(@"Active");
        NSDictionary *aps = [userInfo objectForKey:@"aps"];
        if(aps != nil) {
            NSNumber *unreadMsgCount = [aps objectForKey:@"badge"];
            [[TogaytherService getMessageService] setUnreadMessageCount:unreadMsgCount.intValue];
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:PML_NOTIFICATION_PUSH_RECEIVED object:self];
        
    }
    completionHandler(UIBackgroundFetchResultNewData);
}

-(void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler {
    NSLog(@"handleActionWithIdentifier");
}
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    ModelHolder *holder = [[TogaytherService dataService] modelHolder];
    NSMutableArray *allPlaces = [holder allPlaces];
    [allPlaces removeAllObjects];
    [allPlaces addObjectsFromArray:[holder places]];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    BOOL fbUrlHandled = [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
    if(!fbUrlHandled) {
        PMLMenuManagerController *menuController = [[TogaytherService uiService] menuManagerController];
        [self openURL:url searchCallback:^(CALObject *object) {
            // Opening a context means fitting results
            ((MapViewController*)menuController.rootViewController).zoomUpdateType = PMLZoomUpdateFitResults;
            [[TogaytherService dataService] fetchPlacesFor:object];
        } overviewCallback:^(CALObject *object) {
            [[menuController dataManager] setInitialContext:object isSearch:NO];
            [[TogaytherService dataService] fetchOverviewData:object];
        }];
    }
    return YES;
}
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [self application:application openURL:url sourceApplication:nil annotation:nil];
}

-(void)openURL:(NSURL*)url searchCallback:(void (^)(CALObject *obj))searchCallback overviewCallback:(void(^)(CALObject *obj))overviewCallback{
    
    NSString *absoluteUrl = [url absoluteString];
    NSString *lastComponent = [absoluteUrl lastPathComponent];
    NSRange range = [lastComponent rangeOfString:@"-"];
    NSString *key;
    BOOL isSearch = NO;
    if(range.length>0) {
        NSUInteger loc = range.location;
        key = [lastComponent substringToIndex:loc];
        isSearch = NO;
    }
    if([absoluteUrl rangeOfString:@"/s-"].length>0) {
        key = lastComponent;
        isSearch = YES;
    }
    if(key != nil) {
        CALObject *object = [[TogaytherService dataService] objectForKey:key];
        if(object != nil) {
            self.deepLinkObject = object;
            if(isSearch) {
                // Search
                self.deepLinkCallback = searchCallback;
            } else {
                // Overview
                self.deepLinkCallback = overviewCallback;
            }
        }
    }
}

#pragma mark - PMLDataListener
- (void)didLoadData:(ModelHolder *)modelHolder silent:(BOOL)isSilent {
    if(self.deepLinkObject != nil) {
        self.deepLinkCallback(self.deepLinkObject);
        self.deepLinkObject = nil;
        self.deepLinkCallback = nil;
    }
}
@end
