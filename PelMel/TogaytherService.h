//
//  TogaytherService.h
//  nativeTest
//
//  Created by Christophe Fondacci on 25/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataService.h"
#import "UserService.h"
#import "ConversionService.h"
#import "ImageService.h"
#import "MessageService.h"
#import "SizedTTLCacheService.h"
#import "JsonService.h"
#import "UIService.h"
#import "SettingsService.h"
#import "PMLHelpService.h"

@interface TogaytherService : NSObject

+ (void)start;

// Provides the DataService instance
+ (DataService*)dataService;

// Provides the UserService instance
+ (UserService*)userService;

// Provides the current language of the iOS device
+ (NSString*)getLanguageIso6391Code;

// Provides a service for unit conversion
+ (ConversionService *)getConversionService;

// Provides the image service
+ (ImageService *)imageService;

// Provides the JSON helper service
+ (JsonService*)getJsonService;

// Provides the UI service
+ (UIService*) uiService;

// Provides the Settings service
+ (SettingsService*)settingsService;

// Provides the help management service
+(PMLHelpService*)helpService;

+ (MessageService*)getMessageService;
+ (void)applyCommonLookAndFeel:(UIViewController*)controller;
+ (BOOL) isRetina;
+ (void) setHDMode:(BOOL)hdEnabled;
+ (NSString*)propertyFor:(NSString*)prop;
+ (NSNumber*)propertyAsNumberFor:(NSString*)prop;
+ (UIColor*)propertyAsColorFor:(NSString*)prop;
@end
