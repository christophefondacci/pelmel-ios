//
//  PMLMessageCacheEntry.h
//  PelMel
//
//  Created by Christophe Fondacci on 08/05/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PMLMessageCacheEntry : NSObject
@property (nonatomic,retain) NSArray *messages;
@property (nonatomic) NSInteger totalCount;
@property (nonatomic) NSInteger page;
@property (nonatomic) NSInteger pageSize;
@end
