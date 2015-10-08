//
//  AppDelegate.h
//  nativeTest
//
//  Created by Christophe Fondacci on 20/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataService.h"
#import <EAIntroView.h>
@interface AppDelegate : UIResponder <UIApplicationDelegate,PMLDataListener, EAIntroDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
