//
//  PostDelegate.m
//  PelMel
//
//  Created by Christophe Fondacci on 13/02/14.
//  Copyright (c) 2014 Christophe Fondacci. All rights reserved.
//

#import "PostDelegate.h"

@implementation PostDelegate {
    id<PostCallback> callback;
    NSString *actionCode;
    
    NSMutableData *data;
}

- (id)initWithCallback:(id<PostCallback>)aCallback forAction:(NSString *)aActionCode
{
    self = [super init];
    if (self) {
        callback = aCallback;
        actionCode = aActionCode;
    }
    return self;
}
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    NSLog(@"Can authenticate against");
    return NO;
}
- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSLog(@"Did cancel auth challenge");
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Fail with error");
    [callback postFailed:error action:actionCode];
}
-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSLog(@"Authentication challenge");
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

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)someData {
    if(data == nil) {
        data = [NSMutableData dataWithData:someData];
    } else {
        [data appendData:someData];
    }
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [callback postComplete:data action:actionCode];
}
@end
