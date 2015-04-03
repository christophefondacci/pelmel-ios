//
//  TogaytherService.m
//  nativeTest
//
//  Created by Christophe Fondacci on 25/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "TogaytherService.h"
#import "DataService.h"
#import "UserService.h"
#import "ImageService.h"
#import "MessageService.h"
#import "PMLMenuManagerController.h"
#import "PMLSnippetTableViewController.h"

#define CONFIG_FILE_NAME @"PelMel-config"

#define kCacheTTL 600
#define kImageCacheTTL 999999999
#define kCacheMaxObjects 500
#define kCacheMaxImages 300

#define kHDModeKey @"hdEnabled"


@implementation TogaytherService
    static DataService *_dataService;
    static UserService *_userService;
    static NSString *_language;
    static ConversionService *_conversionService;
    static ImageService *_imageService;
    static MessageService *_messageService;
    static JsonService *_jsonService;
    static UIService *_uiService;
    static SettingsService *_settingsService;
    static PMLHelpService *_helpService;
    static NSDictionary *properties;

    static BOOL hdModeLoaded;
    static BOOL hdModeEnabled;

+ (void) start {
    NSString *defaultPrefsFile = [[NSBundle mainBundle] pathForResource:CONFIG_FILE_NAME ofType:@"plist"];
    properties = [NSDictionary dictionaryWithContentsOfFile:defaultPrefsFile];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:properties];
    
    _dataService = [[DataService alloc] init];
    _userService = [[UserService alloc] init];
    _language = [[NSLocale preferredLanguages] objectAtIndex:0];
    _conversionService = [[ConversionService alloc] init];
    _imageService = [[ImageService alloc] init];
    _messageService = [[MessageService alloc] init];
    _jsonService = [[JsonService alloc] init];
    _uiService = [[UIService alloc] init];
    _settingsService = [[SettingsService alloc] init];
    _helpService = [[PMLHelpService alloc] init];
    
    // Injecting data service
    _dataService.userService = [TogaytherService userService];
    _dataService.imageService= [TogaytherService imageService];
    _dataService.messageService = [TogaytherService getMessageService];
    _dataService.jsonService = [TogaytherService getJsonService];
    
    
    // Injecting user services
    _userService.imageService = _imageService;
    _userService.jsonService = _jsonService;
    
    // Injecting image service
    _imageService.uiService = _uiService;
    
    // Injecting message service
    _messageService.userService = _userService;
    _messageService.jsonService = _jsonService;
    
    // Injecting JSON Service
    _jsonService.imageService = _imageService;
    
    // Injecting settings service
    _settingsService.conversionService = _conversionService;
    
}
+(DataService *)dataService {
    return _dataService;
}

+ (UserService *)userService {
    return _userService;
}

+ (NSString *)getLanguageIso6391Code {
    return _language;
}

+ (ConversionService *)getConversionService {
    return _conversionService;
}
+ (BOOL)isRetina {
    if (!hdModeLoaded) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSNumber *hdNumericMode = [defaults objectForKey:kHDModeKey];
        if(hdNumericMode != nil) {
            hdModeEnabled = [hdNumericMode boolValue];
        } else {
            hdModeEnabled = NO;
        }
        hdModeLoaded=YES;
    }
    return [[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0) && hdModeEnabled;
}

+ (ImageService *)imageService {
    return _imageService;
}

+ (MessageService *)getMessageService {
    return _messageService;
}
+ (void)applyCommonLookAndFeel:(UIViewController *)controller {
    if([controller isKindOfClass:[PMLMenuManagerController class]] || [controller isKindOfClass:[PMLSnippetTableViewController class]]) {
        controller.edgesForExtendedLayout = UIRectEdgeAll;
    } else {
        controller.edgesForExtendedLayout = UIRectEdgeNone;
    }
    controller.automaticallyAdjustsScrollViewInsets=NO;

    controller.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    // Adjusting tint
    controller.navigationController.navigationBar.alpha=1;
    controller.navigationController.navigationBar.backgroundColor =[UIColor colorWithRed:0.92 green:0.46 blue:0 alpha:1];
    controller.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [controller.navigationController.navigationBar setBackgroundImage:nil
                                                  forBarMetrics:UIBarMetricsDefault];
    [controller.navigationController.navigationBar setTranslucent:YES];
    [controller.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:0.92 green:0.46 blue:0 alpha:1]];
    [controller.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    NSDictionary *barButtonAppearanceDict = @{NSFontAttributeName : [UIFont fontWithName:PML_FONT_DEFAULT size:19.0], NSForegroundColorAttributeName: [UIColor whiteColor]};
    [[UIBarButtonItem appearance] setTitleTextAttributes:barButtonAppearanceDict forState:UIControlStateNormal];
}

+ (void)setHDMode:(BOOL)hdEnabled {
    hdModeEnabled = hdEnabled;
    hdModeLoaded = YES;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:hdEnabled] forKey:kHDModeKey];
}
+ (JsonService *)getJsonService {
    return _jsonService;
}
+ (NSString*)propertyFor:(NSString *)prop {
    return [properties objectForKey:prop];
}
+ (NSNumber*)propertyAsNumberFor:(NSString *)prop {
    NSString *propVal = [TogaytherService propertyFor:prop];
    if(propVal) {
        return [NSNumber numberWithFloat:[propVal floatValue]];
    } else {
        return nil;
    }
}
+(UIColor *)propertyAsColorFor:(NSString *)prop {
    NSString *colorHex = [self propertyFor:prop];
    // Parsing hex color
    NSScanner *scanner = [NSScanner scannerWithString:colorHex];
    unsigned int rgb;
    [scanner scanHexInt:&rgb];
    
    // Building RGB
    return UIColorFromRGB(rgb);
}
+ (UIService *)uiService {
    return _uiService;
}
+ (SettingsService*)settingsService {
    return _settingsService;
}
+ (PMLHelpService *)helpService {
    return _helpService;
}
@end
