//
//  UserService.m
//  nativeTest
//
//  Created by Christophe Fondacci on 27/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//


#import "UserService.h"
#import "Description.h"
#import "TogaytherService.h"
#import <AFNetworking.h>
#import "PMLLikeStatistic.h"
#import <FacebookSDK/FacebookSDK.h>

#define kFBLoginUrlFormat @"%@/mobileFacebookLogin"
#define kLoginUrlFormat @"%@/mobileLogin" //?email=%@&password=%@&highRes=%@"
#define kPrivateNetworkUrlFormat @"%@/mobilePrivateList" //?email=%@&password=%@&highRes=%@"
#define kResetPasswordUrlFormat @"%@/lostPassword"
#define kParamEmail @"email"
#define kParamPassword @"password"
#define kParamVersion @"deviceInfo"
#define kParamHighRes @"highRes"
#define kParamDeviceToken @"pushDeviceId"
#define kParamPushProvider @"pushProvider"
#define kPushProvider @"APPLE"
#define kParamName @"name"
#define kParamLat @"lat"
#define kParamLng @"lng"
#define kParamBirthDD @"birthDD"
#define kParamBirthMM @"birthMM"
#define kParamBirthYYYY @"birthYYYY"
#define kParamUserToken @"nxtpUserToken"
#define kParamCheckinKey @"checkInKey"
#define kParamCheckout @"checkout"
#define kParamFBAccessToken @"fbAccessToken"
#define kParamUserKey @"userKey"
#define kParamAction @"action"

#define kPrivateNetworkActionRequest @"REQUEST"
#define kPrivateNetworkActionCancel @"CANCEL"
#define kPrivateNetworkActionConfirm @"CONFIRM"
#define kPrivateNetworkActionInvite @"INVITE"

#define kLoginParamsFormat      @"email=%@&password=%@&highRes=%@"
#define kDisconnectUrlFormat    @"%@/mobileDisconnect?nxtpUserToken=%@"
#define kRegisterUrlFormat      @"%@/mobileRegister"
#define kRegisterTokenUrlFormat      @"%@/mobileRegisterToken"
#define kCheckinUrlFormat       @"%@/mobileCheckin"
#define kLikeStatsUrlFormat       @"%@/mobileLikeInfo"
#define kRegisterParamsFormat   @"userKey=%@&name=%@&height=%d&weight=%d&birthDD=%d&birthMM=%d&birthYYYY=%d&lat=%f&lng=%f&nxtpUserToken=%@"
#define kRegisterCreationParamsFormat @"email=%@&password=%@&name=%@&lat=%f&lng=%f&highRes=%@&birthDD=%d&birthMM=%d&birthYYYY=%d" //2


#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) //1
#define kUserFacebookTokenKey @"userFbToken"
#define kUserFacebookEmailKey @"userFbEmail"
#define kUserEmailKey @"userEmail"
#define kUserPasswordKey @"userPassword"

@implementation UserService {

    CurrentUser *_currentUser;
    NSString *togaytherServer;
    NSUserDefaults *userDefaults;

    
    NSObject<PMLUserCallback> *currentCallback;
    NSCache *cacheService;
    
    // Listeners management
    NSMutableSet *_listeners;
}

@synthesize imageService = imageService;
@synthesize jsonService = jsonService;

- (id)init {
    if(self = [super init]) {
        togaytherServer = [TogaytherService propertyFor:PML_PROP_SERVER];
        userDefaults = [NSUserDefaults standardUserDefaults];
        
        cacheService = [[NSCache alloc] init];
        _listeners = [[NSMutableSet alloc] init];
    }
    return self;
}

#pragma mark - Authentication

-(BOOL)authenticateWithLastLogin:(NSObject<PMLUserCallback>*)callback {
    NSString *fbToken = nil; //[[[FBSession activeSession] accessTokenData] accessToken];
    NSString *email = nil;
    if(fbToken == nil) {
        fbToken = (NSString*)[userDefaults objectForKey:kUserFacebookTokenKey];
        email = (NSString *)[userDefaults objectForKey:kUserFacebookEmailKey];
    }

    if(fbToken != nil) {
//        [self authenticateWithFacebook:fbToken email:email callback:callback];
    } else {
        // Fetching email & password from properties
        NSString *passw = (NSString *)[userDefaults objectForKey:kUserPasswordKey];
        email = (NSString *)[userDefaults objectForKey:kUserEmailKey];
        
        // Authenticating
        [self authenticateWithLogin:email password:passw callback:callback];
    }
}

- (void)authenticateWithLogin:(NSString *)login password:(NSString *)password callback:(NSObject<PMLUserCallback>*)callback {
    
    // Notifying that we are about to start
    [self notifyWillStartAuthentication:callback];
    
    if(login == nil || password ==nil) {
        [self notifyUserAuthenticationFailed:callback];
        return ;
    }
    
    // Building param structure
    BOOL isRetina = [TogaytherService isRetina];
    NSMutableDictionary * params = [[NSMutableDictionary alloc] init];
    [params setObject:login forKey:kParamEmail];
    [params setObject:password forKey:kParamPassword];
    [params setObject:(isRetina ? @"true" : @"false") forKey:kParamHighRes];
    
    // Building version string
    NSString *appVersionString  = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *appBuildString    = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *iosVersion        = [[UIDevice currentDevice] systemVersion];
    NSString *deviceName        = [[UIDevice currentDevice] model];
    NSString *versionBuildString = [NSString stringWithFormat:@"%@;%@;%@;%@",appVersionString, appBuildString, deviceName, iosVersion];
    [params setObject:versionBuildString forKey:kParamVersion];
    [self fillPushInformation:params];
    
    // Building URL
    NSString *url = [[NSString alloc] initWithFormat:kLoginUrlFormat, togaytherServer];
    
    // POSTing request
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self handleAuthenticationSuccess:(NSDictionary*)responseObject callback:callback login:login password:password];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSHTTPURLResponse *response = operation.response;
        if(response.statusCode == 401) {
            [self notifyUserAuthenticationFailed:callback];
        } else {
            [self notifyUserAuthenticationImpossible:callback];
        }
    }];
}


- (void)registerDeviceToken:(NSString *)deviceToken {
    
    NSMutableDictionary * params = [[NSMutableDictionary alloc] init];
    [params setObject:_currentUser.token forKey:kParamUserToken];
    [self fillPushInformation:params];
    
    // Building URL
    NSString *url = [[NSString alloc] initWithFormat:kRegisterTokenUrlFormat, togaytherServer];
    
    // POSTing request
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(deviceToken == nil) {
            [[TogaytherService uiService] alertWithTitle:@"push.disabled.registerSuccessTitle" text:@"push.disabled.registerSuccess"];
        } else {
            [[TogaytherService uiService] alertWithTitle:@"push.registerSuccessTitle" text:@"push.registerSuccess"];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[TogaytherService uiService] alertWithTitle:@"push.registerFailedTitle" text:@"push.registerFailed"];
    }];
}

- (BOOL)isAuthenticated {
    return _currentUser != nil;
}
- (CurrentUser *)getCurrentUser {
    return _currentUser;
}

- (void)authenticateWithFacebook:(NSString *)accessToken email:(NSString*)email callback:(NSObject<PMLUserCallback> *)callback {
    // Notifying that we are about to start
    [self notifyWillStartAuthentication:callback];

    // Storing facebook info
    [userDefaults setObject:nil forKey:kUserEmailKey];
    [userDefaults setObject:nil forKey:kUserPasswordKey];
    [userDefaults setObject:accessToken forKey:kUserFacebookTokenKey];
    [userDefaults setObject:email forKey:kUserFacebookEmailKey];
    
    // Building param structure
    NSMutableDictionary * params = [[NSMutableDictionary alloc] init];
    [params setObject:accessToken forKey:kParamFBAccessToken];
    [self fillPushInformation:params];
    
    // Building URL
    NSString *url = [[NSString alloc] initWithFormat:kFBLoginUrlFormat, togaytherServer];

    // POSTing request
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *json = (NSDictionary*)responseObject;
        NSNumber *isNewUser  =[json objectForKey:@"newUser"];
        if([isNewUser boolValue]) {
            [self userRegistered:(NSDictionary*)responseObject login:email password:nil callback:callback];
        } else {
            [self handleAuthenticationSuccess:(NSDictionary*)responseObject callback:callback login:email password:nil];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [userDefaults setObject:nil forKey:kUserEmailKey];
        [userDefaults setObject:nil forKey:kUserFacebookTokenKey];
        NSHTTPURLResponse *response = operation.response;
        if(response.statusCode == 401 || response.statusCode == 500) {
            [self notifyUserAuthenticationFailed:callback];
        } else {
            [self notifyUserAuthenticationImpossible:callback];
        }
    }];

}

-(void) handleAuthenticationSuccess:(NSDictionary*)jsonLoginResponse callback:(NSObject<PMLUserCallback>*)callback login:(NSString*)login password:(NSString*)password {
    
    [[TogaytherService settingsService] storeSettingBoolValue:YES forName:PML_PROP_INTRO_DONE];
    // Retrieving authentication token
    NSString *token     =[jsonLoginResponse objectForKey:kParamUserToken];
    
    if(token != nil) {
        // Creating user
        _currentUser = [[CurrentUser alloc] initWithLogin:login password:password token:token];
        [jsonService fillUser:_currentUser fromJson:jsonLoginResponse];
        

        
        
        //                _currentUser.hasOverviewData = YES;
        [cacheService setObject:_currentUser forKey:_currentUser.key];
        
        [self notifyUserAuthenticated:callback];
    } else {
        [self notifyUserAuthenticationFailed:callback];
    }
}

-(void) fillPushInformation:(NSMutableDictionary*)params {
    // Getting push information
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *deviceId = [defaults objectForKey:PML_PROP_DEVICE_TOKEN];
    NSNumber *pushEnabled = [defaults objectForKey:PML_PROP_PUSH_ENABLED];
    if(pushEnabled != nil && ![pushEnabled boolValue]) {
        deviceId = nil;
    }
    if(deviceId != nil) {
        [params setObject:deviceId forKey:kParamDeviceToken];
        [params setObject:kPushProvider forKey:kParamPushProvider];
    }
}

#pragma mark - Registration

-(void)registerWithLogin:(NSString *)login password:(NSString *)password pseudo:(NSString *)pseudo birthDate:(NSDate*)birthDate callback:(NSObject<PMLUserCallback>*)callback {
    // Building the URL
    NSString *url = [[NSString alloc] initWithFormat:kRegisterUrlFormat,togaytherServer ];
    BOOL isHighRes = [TogaytherService isRetina];
    
    // Preparing post dictionary
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    // Filling variables to POST to the server
    [params setObject:login forKey:kParamEmail];
    [params setObject:password forKey:kParamPassword];
    [params setObject:pseudo forKey:kParamName];
    [params setObject:[NSNumber numberWithDouble:_currentLocation.coordinate.latitude] forKey:kParamLat];
    [params setObject:[NSNumber numberWithDouble:_currentLocation.coordinate.longitude] forKey:kParamLng];
    [params setObject:(isHighRes ? @"true" : @"false") forKey:kParamHighRes];

    // POSTing request
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self userRegistered:(NSDictionary*)responseObject login:login password:password callback:callback];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"User creation failed: %@",error.localizedDescription);
        [self notifyUserRegistrationFailed:callback];
    }];

}
-(void) userRegistered:(NSDictionary*)jsonRegisterInfo login:(NSString*)login password:(NSString*)password callback:(NSObject<PMLUserCallback>*)callback {

    
    // Retrieving authentication token
    NSString *token     =[jsonRegisterInfo objectForKey:@"nxtpUserToken"];
    
    if(token != nil) {
        _currentUser = [[CurrentUser alloc] initWithLogin:login password:password token:token];
        [jsonService fillUser:_currentUser fromJson:jsonRegisterInfo];
        [self notifyUserRegistered:callback];
    } else {
        if(currentCallback != nil) {
            _currentUser = nil;
            [self notifyUserRegistrationFailed:callback];
        }
    }
}
- (void)updateCurrentUser {
    NSString *userKey = _currentUser.key;
    NSString *pseudo = _currentUser.pseudo;
    int weight = (int)_currentUser.weightInKg;
    int height = (int)_currentUser.heightInCm;

    // Getting birth date components
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:_currentUser.birthDate]; // Get necessary date components
    NSInteger birthYYYY = [components year];
    NSInteger birthMM = [components month];
    NSInteger birthDD = [components day];
    NSString *nxtpUserToken = _currentUser.token;

    // Building description components
    NSMutableArray *descLanguageCodes = [[NSMutableArray alloc] init];
    NSMutableArray *descKeys = [[NSMutableArray alloc] init];
    NSMutableArray *descTexts = [[NSMutableArray alloc] init];
    for(Description *desc in _currentUser.descriptions) {
        [descLanguageCodes addObject:[desc.languageCode lowercaseString]];
        [descKeys addObject:(desc.key == nil ? @"" : desc.key)];
        [descTexts addObject:desc.descriptionText];
    }
    
    // Building parameters
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:userKey forKey:@"userKey"];
    [params setObject:pseudo forKey:@"name"];
    [params setObject:[NSNumber numberWithInt:weight] forKey:@"weight"];
    [params setObject:[NSNumber numberWithInt:height] forKey:@"height"];
    [params setObject:[NSNumber numberWithInteger:birthDD] forKey:@"birthDD"];
    [params setObject:[NSNumber numberWithInteger:birthMM] forKey:@"birthMM"];
    [params setObject:[NSNumber numberWithInteger:birthYYYY] forKey:@"birthYYYY"];
    [params setObject:[NSNumber numberWithDouble:_currentLocation.coordinate.latitude] forKey:@"lat"];
    [params setObject:[NSNumber numberWithDouble:_currentLocation.coordinate.longitude] forKey:@"lng"];
    [params setObject:nxtpUserToken forKey:@"nxtpUserToken"];
    [params setObject:_currentUser.tags forKey:@"tags"];
    [params setObject:descLanguageCodes forKey:@"descriptionLanguageCode"];
    [params setObject:descKeys forKey:@"descriptionKey"];
    [params setObject:descTexts forKey:@"description"];
    
    // Building the URL
    NSString *url = [[NSString alloc] initWithFormat:kRegisterUrlFormat,togaytherServer ];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {

        
        NSDictionary *jsonRegisterInfo = (NSDictionary*)responseObject;
        // Retrieving authentication token
        NSString *token     =[jsonRegisterInfo objectForKey:@"nxtpUserToken"];
        
        
        if(token != nil) {
            [_currentUser setToken:token];
            [jsonService fillUser:_currentUser fromJson:jsonRegisterInfo];
            [self performSelectorOnMainThread:@selector(notifyUserRegistered:) withObject:currentCallback waitUntilDone:NO];
        } else {
            if(currentCallback != nil) {
                _currentUser = nil;
                [self performSelectorOnMainThread:@selector(notifyUserRegistrationFailed:) withObject:currentCallback waitUntilDone:NO];
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self notifyUserRegistrationFailed:currentCallback];
    }];
    NSLog(@"User updated");
}

- (void)mainThumbAvailableFor:(NSArray *)imagedObjects {
    
}
- (void)overviewImageFetched:(Imaged *)imaged {
    
}
- (void)allThumbsAvailableFor:(NSArray *)imagedObjects {
    
}

- (void)disconnect {
    NSString *url = [NSString stringWithFormat:kDisconnectUrlFormat,togaytherServer,_currentUser.token];
    // Calling URL, we don't expect a response
    dispatch_async(kBgQueue, ^{
        [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    });
    [[TogaytherService imageService] cancelRunningProcesses];
    [[TogaytherService dataService] cancelRunningProcesses];
    _currentUser = nil;
    
    // Facebook signout
    NSString * fbToken = [userDefaults objectForKey:kUserFacebookTokenKey];
    if(fbToken != nil) {
        [[FBSession activeSession] closeAndClearTokenInformation];
        [FBSession.activeSession close];
        [FBSession setActiveSession:nil];
        [userDefaults removeObjectForKey:kUserFacebookTokenKey];
    }
    // Voiding password
    [userDefaults removeObjectForKey:kUserPasswordKey];
    [userDefaults synchronize];
}


- (int)getAge:(User *)user {
    NSDate *birthDate = user.birthDate;
    return [self getAgeFromDate:birthDate];
}
- (int)getAgeFromDate:(NSDate *)date {
    NSDate *currentDate = [NSDate date];
    NSTimeInterval delta = [currentDate timeIntervalSinceDate:date];
    long secondsInYear = 31557600;
    NSInteger years = delta / secondsInYear;
    return (int) years;
}
- (void)likeStatistics:(Completor)completion failure:(Completor)failure{
    if(_currentUser.token!=nil) {
        
        // Building params map
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        [params setObject:_currentUser.token forKey:kParamUserToken];
        
        // Building URL
        NSString *url = [NSString stringWithFormat:kLikeStatsUrlFormat,togaytherServer];
        
        // Posting to server
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSDictionary *json = (NSDictionary*)responseObject;
            NSArray *jsonLikes = [json objectForKey:@"likes"];
            NSArray *jsonLikers = [json objectForKey:@"likers"];
            
            // Converting JSON to model
            NSArray *likeActivities = [jsonService convertJsonActivitiesToActivities:jsonLikes];
            NSArray *likerActivities = [jsonService convertJsonActivitiesToActivities:jsonLikers];
            
            // Building bean
            PMLLikeStatistic *stat = [[PMLLikeStatistic alloc] init];
            stat.likeActivities = likeActivities;
            stat.likerActivities = likerActivities;
            
            // Calling block
            completion(stat);

        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            failure(error);
        }];


    }
}
#pragma mark - Checkin / checkout
- (void)checkin:(CALObject *)place completion:(Completor)completor {
    [self checkInOrOut:place completion:completor checkout:NO];
}

- (void)checkout:(CALObject *)place completion:(Completor)completor {
    [self checkInOrOut:place completion:completor checkout:YES];
}

-(void)checkInOrOut:(CALObject*)place completion:(Completor)completor checkout:(BOOL)checkout {
    if(_currentUser.token!=nil && place.key != nil) {
        
        // Building params map
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        [params setObject:_currentUser.token forKey:kParamUserToken];
        if(_currentLocation != nil) {
            [params setObject:[NSNumber numberWithDouble:_currentLocation.coordinate.latitude] forKey:kParamLat];
            [params setObject:[NSNumber numberWithDouble:_currentLocation.coordinate.longitude] forKey:kParamLng];
        }
        [params setObject:place.key forKey:kParamCheckinKey];
        if(checkout) {
            [params setObject:@"true" forKey:kParamCheckout];
        }
        
        // Building URL
        NSString *url = [NSString stringWithFormat:kCheckinUrlFormat,togaytherServer];
        
        // Posting to server
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSDictionary *checkinResponse = (NSDictionary*)responseObject;
            
            NSString *previousPlaceKey      = [checkinResponse objectForKey:@"previousPlaceKey"];
            NSNumber *previousPlaceCheckinCount=[checkinResponse objectForKey:@"previousPlaceUsersCount"];
            NSString *newPlaceKey           = [checkinResponse objectForKey:@"newPlaceKey"];
            NSNumber *newPlaceCheckinCount  = [checkinResponse objectForKey:@"newPlaceUsersCount"];
            
            Place *previousLocation = _currentUser.lastLocation;
            if(!checkout) {
                _currentUser.lastLocation = (Place*)place;
            } else {
                _currentUser.lastLocation = nil;
            }
            _currentUser.lastLocationDate = [NSDate new];
            
            // Updating counts
            if(previousLocation != nil && [previousLocation.key isEqualToString:previousPlaceKey]) {
                previousLocation.hasOverviewData=NO;
                previousLocation.inUserCount = previousPlaceCheckinCount.intValue;
            }
            if([newPlaceKey isEqualToString:place.key]) {
                place.hasOverviewData=NO;
                ((Place*)place).inUserCount = newPlaceCheckinCount.intValue;
            }
            // Notifying
            if(!checkout) {
                [self notifyUserCheckedIn:completor to:place previousLocation:previousLocation];
            } else {
                [self notifyUserCheckedOut:completor from:(Place*)place ];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self notifyUserFailedCheckedInTo:place];
        }];
    }
}
-(void)notifyUserCheckedIn:(Completor)completion to:(CALObject*)object previousLocation:(Place*)previousLocation {
    NSMutableSet *callbacks = [NSMutableSet setWithSet:_listeners];
    if(completion != nil) {
        completion(object);
    }
    for(NSObject<PMLUserCallback> *c in callbacks) {
        if([c respondsToSelector:@selector(user:didCheckInTo:previousLocation:)]) {
            [c user:_currentUser didCheckInTo:object previousLocation:previousLocation];
        }
    }
}
-(void)notifyUserCheckedOut:(Completor)completion from:(Place*)object {
    NSMutableSet *callbacks = [NSMutableSet setWithSet:_listeners];
    if(completion != nil) {
        completion(object);
    }
    for(NSObject<PMLUserCallback> *c in callbacks) {
        if([c respondsToSelector:@selector(user:didCheckOutFrom:)]) {
            [c user:_currentUser didCheckOutFrom:object];
        }
    }
}
#pragma mark - Private network
-(void)sendPrivateNetworkRequestTo:(User*)user success:(Completor)success failure:(Completor)failure {
    [self privateNetworkAction:PMLPrivateNetworkActionRequest withUser:user success:success failure:failure];
}

-(void)cancelPrivateNetworkWith:(User*)user success:(Completor)success failure:(Completor)failure {
    [self privateNetworkAction:PMLPrivateNetworkActionCancel withUser:user success:success failure:failure];
}

-(void)confirmPrivateNetworkWith:(User*)user success:(Completor)success failure:(Completor)failure {
    [self privateNetworkAction:PMLPrivateNetworkActionAccept withUser:user success:success failure:failure];
}

-(void)privateNetworkAction:(PMLPrivateNetworkAction)action withUser:(CALObject*)user success:(Completor)success failure:(Completor)failure {
    NSString *url = [NSString  stringWithFormat:kPrivateNetworkUrlFormat,togaytherServer];
    
    CurrentUser *currentUser = [[TogaytherService userService] getCurrentUser];
    if([currentUser.key isEqualToString:user.key]) {
        [[TogaytherService uiService] alertWithTitle:@"network.error.addSelfTitle" text:@"network.error.addSelfMsg"];
        return;
    }
    // Assigning action code
    NSString *actionCode ;
    switch(action) {
        case PMLPrivateNetworkActionRequest:
            actionCode = kPrivateNetworkActionRequest;
            break;
        case PMLPrivateNetworkActionAccept:
            actionCode = kPrivateNetworkActionConfirm;
            break;
        case PMLPrivateNetworkActionCancel:
            actionCode = kPrivateNetworkActionCancel;
            break;
        case PMLPrivateNetworkActionInvite:
            actionCode = kPrivateNetworkActionInvite;
            break;
    }
    

    NSDictionary *params = @{ kParamUserKey : user.key,kParamUserToken : currentUser.token, kParamAction : actionCode};
    
    AFHTTPRequestOperationManager *manager= [AFHTTPRequestOperationManager manager];
    [manager GET:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {

        // Filling new private network definition into current user
        CurrentUser *currentUser = [[TogaytherService userService] getCurrentUser];
        [jsonService fillPrivateNetworkInfo:(NSDictionary*)responseObject inUser:currentUser];
        
        // Calling back
        success(responseObject);
        [self notifyUserChangedPrivateNetwork];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];

}
-(void)privateNetworkListWithSuccess:(Completor)success failure:(Completor)failure {
    NSString *url = [NSString  stringWithFormat:kPrivateNetworkUrlFormat,togaytherServer];
    CurrentUser *currentUser = [[TogaytherService userService] getCurrentUser];
    NSDictionary *params = @{ kParamUserKey : currentUser.key,kParamUserToken : currentUser.token};
    
    AFHTTPRequestOperationManager *manager= [AFHTTPRequestOperationManager manager];
    [manager GET:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        // Filling new private network definition into current user
        CurrentUser *currentUser = [[TogaytherService userService] getCurrentUser];
        [jsonService fillPrivateNetworkInfo:(NSDictionary*)responseObject inUser:currentUser];
        
        // Calling back
        if(success != nil) {
            success(responseObject);
        }
        [self notifyUserChangedPrivateNetwork];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(failure != nil) {
            failure(error);
        }
    }];
}

- (PMLUserPrivateNetworkStatus)privateNetworkStatusFor:(User *)user {
    for(User *u in _currentUser.networkPendingApprovals) {
        if([u.key isEqualToString:user.key]) {
            return PMLUserPrivateNetworkPendingApproval;
        }
    }
    for(User *u in _currentUser.networkPendingRequests) {
        if([u.key isEqualToString:user.key]) {
            return PMLUserPrivateNetworkPendingRequest;
        }
    }
    for(User *u in _currentUser.networkUsers) {
        if([u.key isEqualToString:user.key]) {
            return PMLUserPrivateNetworkInNetwork;
        }
    }
    return PMLUserPrivateNetworkNotInNetwork;
}
#pragma mark - Tools
- (void)resetPasswordFor:(NSString *)email success:(Completor)success failure:(Completor)failure {
    NSString *url = [NSString  stringWithFormat:kResetPasswordUrlFormat,togaytherServer];
    
    NSDictionary *params = @{ @"email" : email };
    
    AFHTTPRequestOperationManager *manager= [AFHTTPRequestOperationManager manager];
    [manager GET:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}


#pragma mark - Listeners and callback management
-(void)registerListener:(NSObject<PMLUserCallback> *)listener {
    [_listeners addObject:listener];
}
-(void)unregisterListener:(NSObject<PMLUserCallback> *)listener {
    [_listeners removeObject:listener];
}
-(void)notifyWillStartAuthentication:(NSObject<PMLUserCallback>*)callback {
    NSMutableSet *callbacks = [NSMutableSet setWithSet:_listeners];
    if(callback != nil) {
        [callbacks addObject:callback];
    }
    for(NSObject<PMLUserCallback> *c in callbacks) {
        if([c respondsToSelector:@selector(willStartAuthentication)]) {
            [c willStartAuthentication];
        }
    }
}
-(void)notifyUserAuthenticated:(NSObject<PMLUserCallback>*)callback {
    NSMutableSet *callbacks = [NSMutableSet setWithSet:_listeners];
    if(callback != nil) {
        [callbacks addObject:callback];
    }
    for(NSObject<PMLUserCallback> *c in callbacks) {
        if([c respondsToSelector:@selector(userAuthenticated:)]) {
            [c userAuthenticated:_currentUser];
        }
    }
}

-(void)notifyUserFailedCheckedInTo:(CALObject*)object {
    NSMutableSet *callbacks = [NSMutableSet setWithSet:_listeners];
    for(NSObject<PMLUserCallback> *c in callbacks) {
        if([c respondsToSelector:@selector(user:didFailCheckInTo:)]) {
            [c user:_currentUser didFailCheckInTo:object];
        }
    }
}
-(void)notifyUserAuthenticationFailed:(NSObject<PMLUserCallback>*)callback {
    NSMutableSet *callbacks = [NSMutableSet setWithSet:_listeners];
    if(callback != nil) {
        [callbacks addObject:callback];
    }
    for(NSObject<PMLUserCallback> *c in callbacks) {
        if([c respondsToSelector:@selector(authenticationFailed:)]) {
            [c authenticationFailed:nil];
        }
    }
}
-(void)notifyUserAuthenticationImpossible:(NSObject<PMLUserCallback>*)callback {
    NSMutableSet *callbacks = [NSMutableSet setWithSet:_listeners];
    if(callback != nil) {
        [callbacks addObject:callback];
    }
    for(NSObject<PMLUserCallback> *c in callbacks) {
        if([c respondsToSelector:@selector(authenticationImpossible)]) {
            [c authenticationImpossible];
        }
    }
}
-(void)notifyUserChangedPrivateNetwork {
    for(NSObject<PMLUserCallback> *c in _listeners) {
        if([c respondsToSelector:@selector(userDidChangePrivateNetwork:)]) {
            [c userDidChangePrivateNetwork:_currentUser];
        }
    }
}
-(void)notifyUserRegistered:(NSObject<PMLUserCallback>*)callback {
    NSMutableSet *callbacks = [NSMutableSet setWithSet:_listeners];
    if(callback != nil) {
        [callbacks addObject:callback];
    }
    for(NSObject<PMLUserCallback> *c in callbacks) {
        if([c respondsToSelector:@selector(userRegistered:)]) {
            [c userRegistered:_currentUser];
        }
    }
}
-(void)notifyUserRegistrationFailed:(NSObject<PMLUserCallback>*)callback {
    NSMutableSet *callbacks = [NSMutableSet setWithSet:_listeners];
    if(callback != nil) {
        [callbacks addObject:callback];
    }
    for(NSObject<PMLUserCallback> *c in callbacks) {
        if([c respondsToSelector:@selector(userRegistrationFailed)]) {
            [c userRegistrationFailed];
        }
    }
}
- (BOOL)user:(User*)user isCheckedInAt:(Place *)place {
    return [user.lastLocation.key isEqualToString:place.key] && [user.lastLocationDate timeIntervalSinceNow]>-PML_CHECKIN_SECONDS;
}
- (BOOL)isCheckedInAt:(Place *)place {
    return [self user:_currentUser isCheckedInAt:place];
}
-(Place *)checkedInPlace {
    if([_currentUser.lastLocationDate timeIntervalSinceNow]>-PML_CHECKIN_SECONDS) {
        return _currentUser.lastLocation;
    }
    return nil;
}


@end
