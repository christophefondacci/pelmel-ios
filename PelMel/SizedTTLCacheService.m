//
//  CacheService.m
//  togayther
//
//  Created by Christophe Fondacci on 22/10/12.
//  Copyright (c) 2012 Christophe Fondacci. All rights reserved.
//

#import "SizedTTLCacheService.h"



@implementation SizedTTLCacheService  {
    int _ttlSeconds;
    int _size;
    NSMutableDictionary *objectsMap;
    NSMutableDictionary *objectsCreationTimeMap;
    NSMutableArray *allKeys;
    
    NSString *lock;
}

- (id)initWithTTL:(int)ttlSeconds maxObjects:(int)maxObjects {
    self = [super init];
    if (self) {
        _ttlSeconds = ttlSeconds;
        _size = maxObjects;
        objectsMap = [[NSMutableDictionary alloc] init];
        objectsCreationTimeMap = [[NSMutableDictionary alloc] init];
        allKeys = [[NSMutableArray alloc] init];
        // Initializing our lock
        lock = [NSString stringWithFormat:@"%p",allKeys];
    }
    return self;
}

- (id)getObject:(NSString *)key {
    NSNumber *creationTime = [objectsCreationTimeMap objectForKey:key];
    NSTimeInterval i = [[NSDate date ] timeIntervalSince1970];
    
    if( i - [creationTime doubleValue] > _ttlSeconds) {
        // We know it has expired so we evict it
        [self evict:key];
        // We don't have this entry
        return nil;
    } else {
        return [objectsMap objectForKey:key];
    }
}
-(void)evict:(NSString*)key {
    @synchronized(lock) {
        if(key != nil) {
            [objectsMap removeObjectForKey:key];
            [objectsCreationTimeMap removeObjectForKey:key];
            [allKeys removeObject:key];
        }
    }
}
- (void)putObject:(id)object forKey:(NSString *)key {
    @synchronized(lock) {
        // Getting the time of creation
        NSTimeInterval i = [[NSDate date ] timeIntervalSince1970];
        NSNumber *creationTime = [NSNumber numberWithDouble:i];
        
        BOOL alreadyInCache = [allKeys containsObject:key];
        if(!alreadyInCache) {
            long cacheSize = allKeys.count;
            // If this object make the cache grow bigger than allowed size
            if(cacheSize+1 >= _size) {
                // Then we need to evict our last key
                NSString *oldestKey = [allKeys objectAtIndex:0];
                [self evict:oldestKey];
            }
            if(key != nil) {
                [allKeys addObject:key];
            }
        } else {
            // We remove / re-add the key so that it goes to the tail
            if(key!=nil) {
                [allKeys removeObject:key];
                [allKeys addObject:key];
            }
        }
        
        if(key != nil) {
            // Timestamping key
            [objectsCreationTimeMap setObject:creationTime forKey:key];
            
            // Putting cache value
            [objectsMap setObject:object forKey:key];
        }
    }
}
@end
