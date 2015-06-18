//
//  StorageService.h
//  PelMel
//
//  Created by Christophe Fondacci on 05/08/13.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * This service provides simple methods that exposes the managed object context when 
 * working in a mutli-threaded environment where data could be retrieved / written from
 * various threads. 
 */
@interface PMLStorageService : NSObject

- (NSManagedObjectContext *)managedObjectContext;
@end
