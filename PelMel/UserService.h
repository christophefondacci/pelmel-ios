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
#import "Services.h"

typedef enum {
    PMLUserPrivateNetworkNotInNetwork,
    PMLUserPrivateNetworkPendingApproval,
    PMLUserPrivateNetworkPendingRequest,
    PMLUserPrivateNetworkInNetwork
} PMLUserPrivateNetworkStatus;

typedef enum {
    PMLPrivateNetworkActionRequest,
    PMLPrivateNetworkActionAccept,
    PMLPrivateNetworkActionCancel,
    PMLPrivateNetworkActionInvite
} PMLPrivateNetworkAction;



@protocol PMLUserCallback

@optional
- (void)userAuthenticated:(CurrentUser *)user;
- (void)willStartAuthentication;
- (void)authenticationFailed:(NSString *)reason;
- (void)authenticationImpossible;
- (void)userRegistered:(CurrentUser *)user;
- (void)userRegistrationFailed;
- (void)user:(CurrentUser*)user didCheckInTo:(CALObject*)object previousLocation:(Place*)previousLocation;
- (void)user:(CurrentUser*)user didCheckOutFrom:(Place*)object;
- (void)user:(CurrentUser*)user didFailCheckInTo:(CALObject*)object;
- (void)userDidChangePrivateNetwork:(CurrentUser*)user ;
@end

@interface UserService : NSObject 

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
/**
 * Authenticates with the last known authentication method. The method returns YES if authentication was tried
 * or NO to indicate that there was no last authentication method or it cannot be used. The caller should offer
 * login options in that case.
 * @param callback the login callback
 * @return YES when authentication has been tried (and thus callback methods will be called), or NO if no authentication could be started
 */
- (BOOL)authenticateWithLastLogin:(NSObject<PMLUserCallback>*)callback;
- (void)authenticateWithFacebook:(NSString*)accessToken email:(NSString*)email callback:(NSObject<PMLUserCallback>*)callback;

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
 * Asks for a reset password email for the given email
 * @param success the callback block called if the call succeeds
 * @param failure the callback block called if the call fails
 */
-(void)resetPasswordFor:(NSString*)email success:(Completor)success failure:(Completor)failure;

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
 * Checkout of the current user from the specified place or event
 */
-(void)checkout:(CALObject*)place completion:(Completor)completor;

/**
 * Fetches the like statistics for the current user and sends it back to the completor
 */
-(void)likeStatistics:(Completor)completion failure:(Completor)failure;

/**
 * Tells whether current user is checked in at the given place
 */
-(BOOL)isCheckedInAt:(Place*)place;
-(BOOL)user:(User*)user isCheckedInAt:(Place *)place;
-(Place*)checkedInPlace;
/**
 * Indicates the status of this user regarding the currently connected user private network.
 * @param user the user to check against logged in user private network
 * @return a PMLUserPrivateNetworkStatus indicating the current state of the connection
 */
-(PMLUserPrivateNetworkStatus)privateNetworkStatusFor:(User*)user;
//-(void)sendPrivateNetworkRequestTo:(User*)user success:(Completor)success failure:(Completor)failure;
-(void)privateNetworkAction:(PMLPrivateNetworkAction)action withUser:(CALObject*)user success:(Completor)success failure:(Completor)failure;
-(void)privateNetworkListWithSuccess:(Completor)success failure:(Completor)failure;

/**
 * Handles anonymous authentication through the "skip" intro button
 */
-(void)skipLoginRegister:(NSObject<PMLUserCallback>*)userCallback;
@end
