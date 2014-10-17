//
//  CALObject.h
//  nativeTest
//
//  Created by Christophe Fondacci on 28/09/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Imaged.h"

@interface CALObject : Imaged

@property (strong) NSString *key;

@property (nonatomic) NSInteger likeCount; // Number of people liking this
@property (nonatomic) NSInteger dislikeCount; // Number of people not liking this
@property (nonatomic) BOOL isLiked; // Whether or not the current user likes this element
@property (nonatomic) double lat;
@property (nonatomic) double lng;
@property (strong) NSMutableArray *tags;
@property (readonly) NSMutableArray *likers;
@property (nonatomic) BOOL hasOverviewData;
@property (strong) NSString *miniDesc;
@property (strong) NSString *miniDescKey;
@property (strong) NSString *miniDescLang;
@property (nonatomic) NSInteger adBoost;
@property (readonly) NSMutableArray *reviews;
@property (nonatomic) NSInteger reviewsCount;
@property (nonatomic,strong) NSDate *timestamp;
@property (nonatomic) BOOL editing;
@property (nonatomic) BOOL editingDesc;

-(void)addLiker:(NSObject*)liker;

@end
