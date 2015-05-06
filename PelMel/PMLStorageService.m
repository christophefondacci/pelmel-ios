//
//  StorageService.m
//  ProvinceSudLCS
//
//  Created by Christophe Fondacci on 05/08/13.
//  Copyright (c) 2013 Christophe Fondacci. All rights reserved.
//

#import "PMLStorageService.h"
#import <CoreData/CoreData.h>
#import <sys/xattr.h>

#define kDatastoreFilenameType @"sqlite"
#define kDatastoreInitFilename @"ProvinceSudLCS"
#define kDatastoreFilename @"dataStoreFilename"
#define kDatastoreFileVersion @"dataStoreFileVersion"
#define kKeyManagedContext @"managedContext"
#define kKeyManagedContextForUpdate @"managedContext-update"

#define kKeyPersistenceCoordinator @"persistenceCoordinator"

@implementation PMLStorageService {
    NSUserDefaults *userDefaults;
    NSManagedObjectModel *managedObjectModel;
    //    NSManagedObjectContext *context;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSString *_datastoreFilename;
    NSString *_datastoreFilenameWithExt;
    NSManagedObjectContext *context;
    
    BOOL autoCreate;
}

- (id)init
{
    self = [super init];
    if (self) {
        userDefaults = [NSUserDefaults standardUserDefaults];
        // The default storage service created this way should be autocreated if non-existing
        autoCreate = YES;
        [self registerDataStoreFilename:[self datastoreFilename]];
    }
    return self;
}

- (id)initWithDatastoreFilename:(NSString *)datastoreFilename {
    self = [super init];
    if (self) {
        // The storage service created with explicit filename should not be autocreated
        autoCreate = NO;
        userDefaults = [NSUserDefaults standardUserDefaults];
        [self registerDataStoreFilename:datastoreFilename];
    }
    return self;
}


- (void)registerDataStoreFilename: (NSString*)datastoreFilename {
    _datastoreFilename = datastoreFilename;
    _datastoreFilenameWithExt = [NSString stringWithFormat:@"%@.%@",datastoreFilename,kDatastoreFilenameType];
}

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    // Checking if not already initialized.
    // Warning : this method is not thread safe because thread safety was de-activated (and buggyfied)
    // The same context returns for all thread, it is the callers responsability to use a storage service per thread
    if (context != nil) {
        return context;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [context setPersistentStoreCoordinator:coordinator];
    }
    
    return context;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"LCSModel" withExtension:@"momd"];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return managedObjectModel;
}
-(void)copyInitialDataStoreIfNotExists {
    if(autoCreate) {
        // Getting a handle on the file manager
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        NSString *txtPath = [self appendPathToDirectoryPath:_datastoreFilenameWithExt];
        
        if ([fileManager fileExistsAtPath:txtPath] == NO) {
            NSLog(@"Initializing data store");
            NSString *resourcePath = [[NSBundle mainBundle] pathForResource:kDatastoreInitFilename  ofType:kDatastoreFilenameType];
            if (resourcePath) {
                [fileManager copyItemAtPath:resourcePath toPath:txtPath error:&error];
                // Removing file from backup
                [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:txtPath]];
            }
        }
    }
}
- (NSString*) appendPathToDirectoryPath:(NSString*) mypath {
    //NSFileManager *fileManager = [NSFileManager defaultManager];
    // Path lookup setup
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    // Getting documents dir
    NSString *documentsDirectory = [paths objectAtIndex:0];
    //remove update sqlite if exists
    return [documentsDirectory stringByAppendingPathComponent:mypath];
}
// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    
    if (persistentStoreCoordinator == nil) {
        
        // First run check
        [self copyInitialDataStoreIfNotExists];
        persistentStoreCoordinator = [self createPersistentStoreCoordinator];
    }
    
    // Returning
    return persistentStoreCoordinator;
}

// Reload the sqlite file
- (void)reloadPersistentStoreCoordinator
{
//    [self.managedObjectContext processPendingChanges];
//    
//    // remove old store from coordinator
//    NSError *error = nil;
//    [self removePersistentStoreCoordinatorAndContext:NO];
//    
//    //replace sqlite
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSString *oldPath = [Utils appendPathToDirectoryPath:kDatastoreFilename];
//    NSString *newPath = [Utils appendPathToDirectoryPath:kDatastoreFilenameForUpdate];
//    [fileManager removeItemAtPath:oldPath error:&error];
//    [fileManager copyItemAtPath:newPath toPath:oldPath error:&error];
//    [Services.uiService updateProgressBar:90 ];
//    
//    // then update
//    NSMutableDictionary *pragmaOptions = [NSMutableDictionary dictionary];
//    [pragmaOptions setObject:@"FULL" forKey:@"synchronous"];
//    [pragmaOptions setObject:@"1" forKey:@"fullfsync"];
//    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:_dataStoreFIlenameWithExt];
//    [self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:pragmaOptions error:&error];
}


// Reload the sqlite file
- (void)removePersistentStoreCoordinatorAndContext:(BOOL)flag
{
//    NSError *error = nil;
//    
//    if ([self.persistentStoreCoordinator persistentStores] == nil)
//        return ;
//    
//    // dirty. If there are many stores...
//    NSPersistentStore *store = [[self.persistentStoreCoordinator persistentStores] lastObject];
//    
//    if (![self.persistentStoreCoordinator removePersistentStore:store error:&error]) {
//        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//        abort();
//    }
//    
//    if (flag){
//        NSManagedObjectContext *localContext = [NSThread.currentThread.threadDictionary objectForKey:_keyManagedContext];
////        localContext = nil;
//        [NSThread.currentThread.threadDictionary removeObjectForKey:_keyManagedContext  ];
//        
//        // Delete file
//        if ([[NSFileManager defaultManager] fileExistsAtPath:store.URL.path]) {
//            if (![[NSFileManager defaultManager] removeItemAtPath:store.URL.path error:&error]) {
//                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//                abort();
//            }
//        }
//        
//        // Delete the reference to non-existing store
//        persistentStoreCoordinator = nil;
//        
//    }
}


- (NSPersistentStoreCoordinator *)createPersistentStoreCoordinator {
    // If not found we instantiate a new coordinator
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:_datastoreFilenameWithExt];
    
    NSError *error = nil;
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSMutableDictionary *pragmaOptions = [NSMutableDictionary dictionary];
    [pragmaOptions setObject:@"FULL" forKey:@"synchronous"];
    [pragmaOptions setObject:@"1" forKey:@"fullfsync"];
    
    if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:pragmaOptions error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    } else {
        // Removing new store from backup
        [self addSkipBackupAttributeToItemAtURL:storeURL];
    }
    return coordinator;
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}
#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

/**
 * This generic method fetches a unique object identified by its unique ID.
 * It needs the entity name, the name of the id column to query and the ID of the object to fetch.
 * If no object is found, this method can instantiate a new object from the store (depending on the 'autoCreate' flag)
 */
-(id)getGenericObject:(NSString*)entityName forId:(int)idValue predicateFormat:(NSString*)predicateFormat autocreate:(BOOL)autocreate context:(NSManagedObjectContext*)context{
    // Get the current managed object context
    //    NSManagedObjectContext *context = storageService.managedObjectContext;
    
    // Preparing a request that will fetch our product
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *productEntity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
    [request setEntity:productEntity];
    
    // Preparing request
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat, idValue];
    [request setPredicate:predicate];
    
    // Executing request
    NSError *error = nil;
    NSArray *objects = [context executeFetchRequest:request error:&error];
    
    id object = nil;
    if(error!=nil) {
        NSLog(@"Error while trying to fetch '%@' with id=%d from Core Data", entityName, idValue);
    } else {
        
        // Have we got something ?
        if(objects.count>0) {
            // If so we return our occurrence
            object = [objects objectAtIndex:0];
        } else {
            // Otherwise we add a new object
            if(autocreate) {
                object = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:context];
            } else {
                NSLog(@"Element not found (entity '%@' id=%d) and autocreate=NO",entityName,idValue);
            }
        }
    }
    return object;
}

- (NSArray *)getAllObjects:(Class)entityName {
    NSManagedObjectContext *managedContext = [self managedObjectContext];
    
    // Checking if our store has some data
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:NSStringFromClass(entityName) inManagedObjectContext:managedContext];
    [request setEntity:entityDesc];
    NSError *error = nil;
    return [managedContext executeFetchRequest:request error:&error];
}

- (NSArray *)getFilteredObjects:(Class)entityName withPredicate:(NSPredicate*)predicate{
    NSManagedObjectContext *managedContext = [self managedObjectContext];
    
    // Checking if our store has some data
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:NSStringFromClass(entityName) inManagedObjectContext:managedContext];
    [request setEntity:entityDesc];
    [request setPredicate:predicate];
    NSError *error = nil;
    return [managedContext executeFetchRequest:request error:&error];
}
- (int)datastoreVersion {
    NSString *versionStr = [userDefaults objectForKey:kDatastoreFileVersion];
    if(versionStr == nil || [@"" isEqualToString:versionStr]) {
        versionStr = @"1";
    }
    return [versionStr intValue];
}
- (void)incrementDatastoreVersion {
    int currentVersion = [self datastoreVersion];
    int newVersion = currentVersion+1;
    [userDefaults setObject:[NSString stringWithFormat:@"%d",newVersion] forKey:kDatastoreFileVersion];
}
- (NSString *)datastoreFilename {
    int version = [self datastoreVersion];
    return [self datastoreFilenameForVersion:version];
}
- (NSString *)datastoreFilenameForVersion:(int)version {
    NSString *basename = [userDefaults objectForKey:kDatastoreFilename];
    return [NSString stringWithFormat:@"%@_%d",basename,version];
}

- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)url {
    if([[NSFileManager defaultManager] fileExistsAtPath: [url path]]) {
        BOOL success;
        NSError *error = nil;
        if(SYSTEM_VERSION_LESS_THAN(@"5.1")) {
            const char* filePath = [[url path] fileSystemRepresentation];
            
            const char* attrName = "com.apple.MobileBackup";
            u_int8_t attrValue = 1;
            
            int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
            success = (result == 0);
        } else {
            success = [url setResourceValue: [NSNumber numberWithBool: YES]
                                     forKey: NSURLIsExcludedFromBackupKey error: &error];
        }
        if(!success){
            NSLog(@"Error excluding %@ from backup %@", [url lastPathComponent], error == nil ? @"" : error);
        } else {
            NSLog(@"File %@ excluded from backup", [url lastPathComponent]);
        }
        return success;
    }
    return NO;
}
@end
