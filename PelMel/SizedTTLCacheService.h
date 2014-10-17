//
//  CacheService.h
//  togayther
//
//  Created by Christophe Fondacci on 22/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CacheService <NSObject>

- (id)getObject:(NSString*)key;
- (void)putObject:(id)object forKey:(NSString*)key;
- (void)evict:(NSString*)key;

@end

@interface SizedTTLCacheService : NSObject <CacheService>

-(id)initWithTTL:(int)ttlSeconds maxObjects:(int)maxObjects;

@end
