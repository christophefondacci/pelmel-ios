//
//  TabBarDelegate.m
//  togayther
//
//  Created by Christophe Fondacci on 07/01/13.
//  Copyright (c) 2013 Christophe Fondacci. All rights reserved.
//

#import "TogaytherTabBarController.h"
#import "Constants.h"
#import "TogaytherService.h"

@implementation TogaytherTabBarController 

- (void)viewDidLoad {
    self.delegate = self;
}
- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    
    NSUInteger viewIndex  = [tabBarController.tabBar.items indexOfObject:viewController.tabBarItem];
    ModelHolder *modelHolder = [[TogaytherService dataService] modelHolder];
    switch(viewIndex) {
        case VIEW_INDEX_EVENTS:
            [modelHolder setCurrentListviewType:EVENTS_LISTVIEW];
            break;
        case VIEW_INDEX_PLACES:
            [modelHolder setCurrentListviewType:PLACES_LISTVIEW];
            break;
    }
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}
@end
