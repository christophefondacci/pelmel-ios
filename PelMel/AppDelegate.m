//
//  AppDelegate.m
//  nativeTest
//
//  Created by Christophe Fondacci on 20/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "AppDelegate.h"
#import "MasterViewController.h"
#import "MapViewController.h"
#import "MessageViewController.h"
#import "FiltersViewController.h"
#import "TogaytherTabBarController.h"
#import "TogaytherService.h"
#import "SWRevealViewController.h"
#import "MainMenuTableViewController.h"
#import "PMLMenuManagerController.h"
#import "UIMenuManagerMainDelegate.h"
#import "MenuAction.h"
#import "Constants.h"
#import "NSData+Conversion.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
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
    
    // ------------ NEW PELMEL NAV

    UIMenuManagerMainDelegate *mainDelegate = [[UIMenuManagerMainDelegate alloc] init];
    PMLMenuManagerController * menuManagerController = (PMLMenuManagerController*)[uiService instantiateViewController:SB_ID_MENU_MANAGER];
//[[PMLMenuManagerController alloc] initWithViewController:mapView with:mainDelegate];
    menuManagerController.menuManagerDelegate = mainDelegate;
    menuManagerController.rootViewController = mapView;
    UINavigationController *rootNavMenuController = [[UINavigationController alloc] initWithRootViewController:menuManagerController];
    self.window.rootViewController = rootNavMenuController;
    
    CGRect winFrame = self.window.frame;
    UIView *view=[[UIView alloc] initWithFrame:CGRectMake(0, 0,winFrame.size.width, 20)];
    view.backgroundColor=[UIColor blackColor];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.window.rootViewController.view addSubview:view];
    
    [TogaytherService.uiService start:self.window];
    

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
    User *currentUser = [[TogaytherService userService] getCurrentUser];
    [[TogaytherService getMessageService] getMessagesWithUser:currentUser.key messageCallback:nil];

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
    User *currentUser = [[TogaytherService userService] getCurrentUser];
    [[TogaytherService getMessageService] getMessagesWithUser:currentUser.key messageCallback:nil];
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
@end
