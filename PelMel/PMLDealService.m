//
//  PMLDealService.m
//  PelMel
//
//  Created by Christophe Fondacci on 28/08/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import "PMLDealService.h"
#import "TogaytherService.h"
#import <AFNetworking.h>
#import <MKNumberBadgeView.h>
#import "UserService.h"

#define kActivateDealUrlFormat @"%@/mobileActivateDeal"
#define kUseDealUrlFormat @"%@/mobileUseDeal"

@interface PMLDealService()
@property (nonatomic,retain) NSString *server;

@end

@implementation PMLDealService

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.server = [TogaytherService propertyFor:PML_PROP_SERVER];
    }
    return self;
}
- (void)activateDealFor:(Place *)place onSuccess:(Completor)successCallback onFailure:(ErrorCompletionBlock)errorCompletion {
    [self updateDealWithKey:nil place:place status:nil maxUses:0 onSuccess:successCallback onFailure:errorCompletion];
}
-(void)updateDealWithKey:(NSString*)dealKey place:(Place*)place status:(NSString*)newStatus maxUses:(NSInteger)maxUses onSuccess:(Completor)successCallback onFailure:(ErrorCompletionBlock)errorCompletion {
    NSString *url = [[NSString alloc] initWithFormat:kActivateDealUrlFormat,_server ];
    
    // Getting birth date components
    NSMutableDictionary *paramValues = [[NSMutableDictionary alloc] init];
    CurrentUser *user = _userService.getCurrentUser;
    
    // Injecting parameters
    if(dealKey != nil) {
        [paramValues setObject:dealKey forKey:@"dealKey"];
    }
    [paramValues setObject:place.key forKey:@"placeKey"];
    [paramValues setObject:user.token forKey:@"nxtpUserToken"];
    if(newStatus != nil) {
        [paramValues setObject:newStatus forKey:@"status"];
    }
    [paramValues setObject:[NSNumber numberWithInt:maxUses] forKey:@"maxUses"];
    
    // Preparing POST request
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:paramValues success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        PMLDeal *deal = [_jsonService convertJsonDealToDeal:(NSDictionary*)responseObject forPlace:place];
        if(successCallback) {
            successCallback(deal);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(errorCompletion) {
            errorCompletion(-1, error.localizedDescription);
        }
    }];
}

- (void)updateDeal:(PMLDeal *)deal onSuccess:(Completor)successCallback onFailure:(ErrorCompletionBlock)errorCompletion {
    [self updateDealWithKey:deal.key place:(Place*)deal.relatedObject status:deal.dealStatus maxUses:deal.maxUses onSuccess:successCallback onFailure:errorCompletion];
    
}

- (void)useDeal:(PMLDeal *)deal onSuccess:(Completor)successCallback onFailure:(ErrorCompletionBlock)errorCompletion {
    [self useDeal:deal dryRun:NO onSuccess:successCallback onFailure:errorCompletion];
}

- (void)useDeal:(PMLDeal *)deal dryRun:(BOOL)dryRun onSuccess:(Completor)successCallback onFailure:(ErrorCompletionBlock)errorCompletion {
    NSString *url = [[NSString alloc] initWithFormat:kUseDealUrlFormat,_server ];
    
    // Getting birth date components
    NSMutableDictionary *paramValues = [[NSMutableDictionary alloc] init];
    CurrentUser *user = _userService.getCurrentUser;
    
    // Injecting parameters
    [paramValues setObject:deal.key forKey:@"dealKey"];
    [paramValues setObject:user.token forKey:@"nxtpUserToken"];
    [paramValues setObject:(dryRun ? @"true" : @"false") forKey:@"dryRun"];
    
    // Preparing POST request
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:paramValues success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        PMLDeal *newDeal = [_jsonService convertJsonDealToDeal:(NSDictionary*)responseObject forPlace:(Place*)deal.relatedObject];
        if(successCallback) {
            successCallback(newDeal);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(errorCompletion) {
            errorCompletion(-1, error.localizedDescription);
        }
    }];
}
- (void)refreshDeal:(PMLDeal*)deal onSuccess:(Completor)successCallback onFailure:(ErrorCompletionBlock)errorCompletion {
    [self useDeal:deal dryRun:YES onSuccess:successCallback onFailure:errorCompletion];
}

-(void)setDealsBadgeView:(MKNumberBadgeView *)dealsBadgeView {
    _dealsBadgeView = dealsBadgeView;
    [self updateDealsBadge];
}
-(void)updateDealsBadge {
    dispatch_async(dispatch_get_main_queue(), ^{
        _dealsBadgeView.value = [[[[TogaytherService dataService] modelHolder] deals] count];
        _dealsBadgeView.hidden = _dealsBadgeView.value<=0;
        _dealsBadgeView.superview.hidden = _dealsBadgeView.hidden;
    });
}
-(NSString*)dealConditionLabel:(PMLDeal *)deal {
    NSString *label = nil;
    if([deal.lastUsedDate timeIntervalSinceNow] > -PML_DEAL_MIN_REUSE_SECONDS) {
        NSDate *nextTime = [deal.lastUsedDate dateByAddingTimeInterval:PML_DEAL_MIN_REUSE_SECONDS];
        NSString *delay = [[TogaytherService uiService] delayStringFrom:nextTime];
        NSString *template = NSLocalizedString(@"deal.delay", @"deal.delay");
        label = [NSString stringWithFormat:template,[delay lowercaseString]];
    } else if(deal.maxUses>0) {
        NSString *template = NSLocalizedString(@"deal.quota.label", @"deal.quota.label");
        label = [NSString stringWithFormat:template, deal.maxUses - deal.usedToday, deal.maxUses];
    } else {
        label = NSLocalizedString(@"deal.available", @"deal.available");
    }
    return label;
}
-(BOOL)isDealUsable:(PMLDeal*)deal considerCheckinDistance:(BOOL)checkDistance {
    // Checking if not used in the 24 hours and whether deal quota has been reached
    BOOL usable = (deal.lastUsedDate == nil || [deal.lastUsedDate timeIntervalSinceNow] < -PML_DEAL_MIN_REUSE_SECONDS ) && (deal.maxUses == 0 || deal.maxUses>deal.usedToday);
    
    // Checking distance if requested
    if(usable && checkDistance) {
        usable &= [[TogaytherService getConversionService] numericDistanceTo:deal.relatedObject] < PML_CHECKIN_DISTANCE;
    }
    return usable;
}
@end
