//
//  PostDelegate.h
//  PelMel
//
//  Created by Christophe Fondacci on 13/02/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * A simple post callback that gets notified when post is complete with full
 * data.
 */
@protocol PostCallback <NSObject>

/**
 * Informs that the POST call succeeded and provides the returned data
 * @param fullData the data returned by the server
 * @param actionCode the code of the action used when delegate was initialized
 */
-(void)postComplete:(NSData*)fullData action:(NSString*)actionCode;

/**
 * Informs that the POST call failed.
 */
-(void)postFailed:(NSError*)error action:(NSString*)actionCode;

@end


/**
 * This interface provides default implementation for POST calls. It typically handles error,
 * data concatenation and some other standard use case. In the end, it notifies the callback
 * with the given code.
 *
 * This delegate should be used only once and needs to be reinstantiated when needed.
 */
@interface PostDelegate : NSObject<NSURLConnectionDelegate,NSURLConnectionDataDelegate>

/**
 * Initializes this delegate with a callback and action code
 * @param callback the PostCallback instance to notify of success/error
 * @param actionCode the code to pass to the callback so that the caller knows which action caused the problem
 */
-(id) initWithCallback:(id<PostCallback>)callback forAction:(NSString*)actionCode;

@end
