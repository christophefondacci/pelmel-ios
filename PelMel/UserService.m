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


#define kLoginUrlFormat @"%@/mobileLogin" //?email=%@&password=%@&highRes=%@"
#define kParamEmail @"email"
#define kParamPassword @"password"
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

#define kLoginParamsFormat      @"email=%@&password=%@&highRes=%@"
#define kDisconnectUrlFormat    @"%@/mobileDisconnect?nxtpUserToken=%@"
#define kRegisterUrlFormat      @"%@/mobileRegister"
#define kCheckinUrlFormat       @"%@/mobileCheckin"
#define kLikeStatsUrlFormat       @"%@/mobileLikeInfo"
#define kRegisterParamsFormat   @"userKey=%@&name=%@&height=%d&weight=%d&birthDD=%d&birthMM=%d&birthYYYY=%d&lat=%f&lng=%f&nxtpUserToken=%@"
#define kRegisterCreationParamsFormat @"email=%@&password=%@&name=%@&lat=%f&lng=%f&highRes=%@&birthDD=%d&birthMM=%d&birthYYYY=%d" //2


#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) //1
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

-(void)authenticateWithLastLogin:(NSObject<PMLUserCallback>*)callback {
    
    // Fetching email & password from properties
    NSString *email = (NSString *)[userDefaults objectForKey:kUserEmailKey];
    NSString *passw = (NSString *)[userDefaults objectForKey:kUserPasswordKey];
    
    // Authenticating
    [self authenticateWithLogin:email password:passw callback:callback];
}

- (void)authenticateWithLogin:(NSString *)login password:(NSString *)password callback:(NSObject<PMLUserCallback>*)callback {
    
    // Notifying that we are about to start
    [self notifyWillStartAuthentication:callback];
    
    if(login == nil || password ==nil) {
        [self notifyUserAuthenticationFailed:callback];
        return ;
    }
    // Preparing parameters
    BOOL isRetina = [TogaytherService isRetina];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *deviceId = [defaults objectForKey:PML_PROP_DEVICE_TOKEN];
    NSNumber *pushEnabled = [defaults objectForKey:PML_PROP_PUSH_ENABLED];
    if(pushEnabled != nil && ![pushEnabled boolValue]) {
        deviceId = nil;
    }
    
    // Building param structure
    NSMutableDictionary * params = [[NSMutableDictionary alloc] init];
    [params setObject:login forKey:kParamEmail];
    [params setObject:password forKey:kParamPassword];
    [params setObject:(isRetina ? @"true" : @"false") forKey:kParamHighRes];
    if(deviceId != nil) {
        [params setObject:deviceId forKey:kParamDeviceToken];
        [params setObject:kPushProvider forKey:kParamPushProvider];
    }
    
    // Building URL
    NSString *url = [[NSString alloc] initWithFormat:kLoginUrlFormat, togaytherServer];
    
    // POSTing request
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *jsonLoginInfo = (NSDictionary*)responseObject;
        
        // Retrieving authentication token
        NSString *token     =[jsonLoginInfo objectForKey:kParamUserToken];
        
        if(token != nil) {
            // Creating user
            _currentUser = [[CurrentUser alloc] initWithLogin:login password:password token:token];
            [jsonService fillUser:_currentUser fromJson:jsonLoginInfo];
            //                _currentUser.hasOverviewData = YES;
            [cacheService setObject:_currentUser forKey:_currentUser.key];
            
            
            [self notifyUserAuthenticated:callback];
        } else {
            [self notifyUserAuthenticationFailed:callback];
        }
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
    [self authenticateWithLastLogin:nil];
}

- (BOOL)isAuthenticated {
    return _currentUser != nil;
}
- (CurrentUser *)getCurrentUser {
    return _currentUser;
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
        NSDictionary *jsonRegisterInfo = (NSDictionary*)responseObject;
        
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
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"User creation failed: %@",error.localizedDescription);
        [self notifyUserRegistrationFailed:callback];
    }];

}
- (void)updateCurrentUser {

//    NSString *url = @"%@/userRegister?userKey=%@&height=%d&weight=%d&birthDD=%d&birthMM=%d&birthYYYY=%d&tagKeys=%@&descriptionLanguageCodes=%@&descriptionItemKeys=%@&descriptions=%@";
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
    
    // Building tag list
    NSMutableString *tagKeys = [[NSMutableString alloc] init];
    NSString *format = @"&tags=%@";
    for(NSString *tag in _currentUser.tags) {
        [tagKeys appendFormat:format,tag];
    }

    // Building description components
    NSMutableString *descriptionLanguageCodes = [[NSMutableString alloc] init];
    NSMutableString *descriptionItemKeys = [[NSMutableString alloc] init];
    NSMutableString *descriptions = [[NSMutableString alloc] init];
    NSString *formatLang = @"&descriptionLanguageCode=%@";
    NSString *formatKey = @"&descriptionKey=%@";
    NSString *formatDesc = @"&description=%@";
    
    for(Description *desc in _currentUser.descriptions) {
        [descriptionLanguageCodes appendFormat:formatLang,[desc.languageCode lowercaseString]];
        [descriptionItemKeys appendFormat:formatKey, desc.key == nil ? @"" : desc.key];
        [descriptions appendFormat:formatDesc, desc.descriptionText];
    }
    
    // Building the URL
    NSString *url = [[NSString alloc] initWithFormat:kRegisterUrlFormat,togaytherServer ];
    NSMutableString *params = [[NSMutableString alloc] initWithFormat:kRegisterParamsFormat,userKey,pseudo,height,weight,(int)birthDD,(int)birthMM,(int)birthYYYY,_currentLocation.coordinate.latitude,_currentLocation.coordinate.longitude,nxtpUserToken];
    [params appendString:tagKeys];
    [params appendString:descriptionLanguageCodes];
    [params appendString:descriptionItemKeys];
    [params appendString:descriptions];
    
    // Preparing data to post
    NSData *postData = [params dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld", (unsigned long)[postData length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    [NSURLConnection connectionWithRequest:request delegate:self];

    // Calling the update URL
//    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    NSLog(@"User updated");
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    NSLog(@"Can authenticate against");
    return NO;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Fail with error");
}

-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSLog(@"Will send for auth challenge");
}
- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection {
    NSLog(@"Should use credential storage");
    return NO;
}
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"Did receive response");
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSLog(@"Did receive data");
    NSError *error;
    if(data == nil) {
        NSLog(@"userRegistration: JSON data is null, aborting");
        return;
    }
    NSDictionary *jsonRegisterInfo = [NSJSONSerialization
                                   JSONObjectWithData:data //1
                                   options:kNilOptions
                                   error:&error];
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
#pragma mark - Checkin
- (void)checkin:(CALObject *)place completion:(Completor)completor {
    if(_currentUser.token!=nil && place.key != nil) {
        
        // Building params map
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        [params setObject:_currentUser.token forKey:kParamUserToken];
        if(_currentLocation != nil) {
            [params setObject:[NSNumber numberWithDouble:_currentLocation.coordinate.latitude] forKey:kParamLat];
            [params setObject:[NSNumber numberWithDouble:_currentLocation.coordinate.longitude] forKey:kParamLng];
        }
        [params setObject:place.key forKey:kParamCheckinKey];
        
        // Building URL
        NSString *url = [NSString stringWithFormat:kCheckinUrlFormat,togaytherServer];
        
        // Posting to server
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self notifyUserCheckedIn:completor to:place];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self notifyUserFailedCheckedInTo:place];
        }];
    }
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
-(void)notifyUserCheckedIn:(Completor)completion to:(CALObject*)object {
    NSMutableSet *callbacks = [NSMutableSet setWithSet:_listeners];
    if(completion != nil) {
        completion(object);
    }
    for(NSObject<PMLUserCallback> *c in callbacks) {
        if([c respondsToSelector:@selector(user:didCheckInTo:)]) {
            [c user:_currentUser didCheckInTo:object];
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
@end
