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

/**
 * Initializes the storage service with this explicit datastore filename
 */
-(id)initWithDatastoreFilename:(NSString*)datastoreFilename;

/**
 * Provides a thread local NSManagedObjectContext that could be used
 * on the current thread. The context will be initialized the first time
 * a context is requested for a given thread.
 */
- (NSManagedObjectContext *)managedObjectContext;

-(NSPersistentStoreCoordinator*)createPersistentStoreCoordinator;

/**
 * reloads the persistence coordinator
 *
 */
- (void)reloadPersistentStoreCoordinator;
- (void)removePersistentStoreCoordinatorAndContext:(BOOL)flag;

-(NSPersistentStoreCoordinator*)persistentStoreCoordinator;

/**
 * Saves the context for the current thread and sends appropriate notifications
 * for proper multi-thread synchro.
 */
- (void)saveContext;

/**
 * Fetches an object with the given predicate
 */
-(id)getGenericObject:(NSString*)entityName forId:(int)idValue predicateFormat:(NSString*)predicateFormat autocreate:(BOOL)autocreate context:(NSManagedObjectContext*)context;

/**
 * Lists all objects for the specified entity
 */
- (NSArray *)getAllObjects:(Class)entityName;

/**
 * Lists all objects for the specified entity
 */
- (NSArray *)getFilteredObjects:(Class)entityName withPredicate:(NSPredicate*)predicate;

/**
 * Provides the current version of datastore
 */
- (int) datastoreVersion;
/**
 * Increments the current version of datastore
 */
- (void)incrementDatastoreVersion;
/**
 * Retrieves the filename for the current version of the datastore
 */
- (NSString*)datastoreFilename;
/**
 * Retrieves the filename for the given version of the datastore
 */
- (NSString*)datastoreFilenameForVersion:(int)version;

/**
 * Excludes the given URL from iCloud backup
 */
- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)url;
@end
