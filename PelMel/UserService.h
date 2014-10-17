//
//  UserService.h
//  nativeTest
//
//  Created by Christophe Fondacci on 27/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "CurrentUser.h"
#import "ImageService.h"
#import "JsonService.h"


typedef void(^Completor)(id obj);

@protocol PMLUserCallback

@optional
- (void)userAuthenticated:(CurrentUser *)user;
- (void)willStartAuthentication;
- (void)authenticationFailed:(NSString *)reason;
- (void)authenticationImpossible;
- (void)userRegistered:(CurrentUser *)user;
- (void)userRegistrationFailed;
- (void)user:(CurrentUser*)user didCheckInTo:(CALObject*)object;
- (void)user:(CurrentUser*)user didFailCheckInTo:(CALObject*)object;

@end

@interface UserService : NSObject <NSURLConnectionDelegate,NSURLConnectionDataDelegate>

@property (strong, nonatomic) ImageService *imageService;
@property (strong, nonatomic) JsonService *jsonService;
@property (strong, nonatomic) CLLocation *currentLocation;
/**
 * Whether our not our user is authenticated
 */
- (BOOL)isAuthenticated;

/**
 * Authenticates the user on the server using its login and password
 */
- (void)authenticateWithLogin:(NSString*)login password:(NSString *)password callback:(NSObject<PMLUserCallback>*)callback;
- (void)authenticateWithLastLogin:(NSObject<PMLUserCallback>*)callback;

-(void)registerListener:(NSObject<PMLUserCallback>*)listener;
-(void)unregisterListener:(NSObject<PMLUserCallback>*)listener;
/**
 * Provides the currently logged in user
 */
- (CurrentUser *)getCurrentUser;

/**
 * Registers the new user using provided login / password 
 */
- (void)registerWithLogin:(NSString*)login password:(NSString*)password pseudo:(NSString*)pseudo birthDate:(NSDate*)birthDate callback:(id<PMLUserCallback>)callback;

/**
 * Registers the given device token for the current user
 */
-(void)registerDeviceToken:(NSString*)deviceToken;

/**
 * Registers every change of the current user to the server 
 */
- (void)updateCurrentUser;

/**
 * Disconnects the current user from the server
 */
-(void)disconnect;
-(int) getAge:(User*)user;
-(int) getAgeFromDate:(NSDate*)date;

/**
 * Checkin of the current user to the specified place or event
 */
-(void)checkin:(CALObject*)place completion:(Completor)completor;

/**
 * Fetches the like statistics for the current user and sends it back to the completor
 */
-(void)likeStatistics:(Completor)completion failure:(Completor)failure;

@end
