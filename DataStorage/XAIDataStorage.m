//
//  XAIDataStorage.m
//  XAIDataStorage
//
//  Created by Xeon Xai <xeonxai@me.com> on 2/15/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "XAIDataStorage.h"
#import "XAIDataStorageDefines.h"
#import "XAIDataStorageNotification.h"

/** XAILogging */
#import "NSError+XAILogging.h"
#import "NSException+XAILogging.h"

/** XAIUtilities */
#import "NSString+XAIUtilities.h"
#import "NSURL+XAIUtilities.h"

/** Shared Instance */
static XAIDataStorage *dataStorageInstance;

@interface XAIDataStorage()

- (void)contextDidSaveWithNotification:(NSNotification *)notification;
- (void)contextObjectsDidChangeWithNotification:(NSNotification *)notification;

@end

@implementation XAIDataStorage

@synthesize managedObjectContext       = __managedObjectContext;
@synthesize managedObjectModel         = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

#pragma mark - Init

+ (XAIDataStorage *)sharedStorage {
    if (dataStorageInstance != nil) {
        return dataStorageInstance;
    }
    
    @synchronized(self) {
        if (!dataStorageInstance) {
            dataStorageInstance = [[XAIDataStorage alloc] init];
        }
    }
    
    return dataStorageInstance;
}

- (id)init {
    self = [super init];
    
    if (self) {
        /** Begin observing notifications for data changes. */
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidSaveWithNotification:) name:NSManagedObjectContextDidSaveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextObjectsDidChangeWithNotification:) name:NSManagedObjectContextObjectsDidChangeNotification object:nil];
    }
    
    return self;
}

#pragma mark - Memory Management

- (void)dealloc {
    /** End notifications. */
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    #if !__has_feature(objc_arc)
        [__managedObjectContext release];
        [__managedObjectModel release];
        [__persistentStoreCoordinator release];
    
        [super dealloc];
    #endif
}

#pragma mark - NSNotification

- (void)mergeChanges:(NSNotification *)notification {
    if (kXAIDataStorageDebugging) {
        NSLog(@"Merging changes.");
    }
    
    [self.managedObjectContext performSelector:@selector(mergeChangesFromContextDidSaveNotification:) onThread:[NSThread mainThread] withObject:notification waitUntilDone:NO];
}

- (void)contextDidSaveWithNotification:(NSNotification *)notification {
    /** Check if the context is different before forcing save. */
    if (![notification.object isEqual:self.managedObjectContext]) {
        /** Save the context. */
        [self performSelector:@selector(saveContext) onThread:[NSThread mainThread] withObject:nil waitUntilDone:YES];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:XAIDataStorageManagedObjectContextDidSaveNotification object:notification.object];
}

- (void)contextObjectsDidChangeWithNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] postNotificationName:XAIDataStorageManagedObjectContextObjectsDidChangeNotification object:notification.object];
}

#pragma mark - NSManagedObjectContext Save

- (void)saveContext {
    NSError *error = nil;
    NSManagedObjectContext *moc = self.managedObjectContext;
    
    if (moc != nil) {
        @try {
            if ([moc hasChanges] && ![moc save:&error]) {
                [error logDetailsFailedOnSelector:_cmd line:__LINE__];
            }
        } @catch (NSException *exception) {
            [exception logDetailsFailedOnSelector:_cmd line:__LINE__ onClass:[[self class] description]];
        }
    }
}

#pragma mark - NSManagedObjectContext Lock

- (void)lockContext {
    [self.managedObjectContext lock];
}

#pragma mark - NSManagedObjectContext Unlock

- (void)unlockContext {
    [self.managedObjectContext unlock];
}

#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
    if (__managedObjectContext != nil) {
        return __managedObjectContext;
    }
    
    // TODO: Migrate to use dispatch_once across the whole library code base.
    @synchronized(self) {
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        
        if (coordinator != nil) {
            NSUndoManager *undoManager = [[NSUndoManager alloc] init];
            
            __managedObjectContext = [[NSManagedObjectContext alloc] init];
            
            [__managedObjectContext setUndoManager:undoManager];
            [__managedObjectContext setPersistentStoreCoordinator:coordinator];
            [__managedObjectContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
            
            #if !__has_feature(objc_arc)
                [undoManager release];
            #endif
        }
    }
    
    return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel {
    if (__managedObjectModel != nil) {
        return __managedObjectModel;
    }
    
    // TODO: Migrate to use dispatch_once across the whole library code base.
    @synchronized(self) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:kXAIDataStorageModelName withExtension:@"momd"];
        
        __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (__persistentStoreCoordinator != nil) {
        return __persistentStoreCoordinator;
    }
    
    // TODO: Migrate to use dispatch_once across the whole library code base.
    @synchronized(self) {
        __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        
        // Disabling the WAL setting.
        // TODO: Update to handle the iOS 7 WAL settings and remove this in the future.
        NSMutableDictionary *pragmaOptions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"DELETE", @"journal_mode", nil];
        
        // Base persistance settings.
        NSDictionary *storageOptions       = @{NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES, NSSQLitePragmasOption: pragmaOptions};
        NSError *persistantStoreLoadError  = nil;
        NSString *persistantStorePath      = [NSString applicationPathForFileName:kXAIDataStorageModelName ofType:@"sqlite"];
        NSURL *persistantStoreURL          = [[NSURL alloc] initFileURLWithPath:persistantStorePath];
        
        if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:persistantStoreURL options:storageOptions error:&persistantStoreLoadError]) {
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
             [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
             
             Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
             
             */
            NSLog(@"Unresolved error %@, %@", persistantStoreLoadError, [persistantStoreLoadError userInfo]);
            abort();
        }
    }
    
    return __persistentStoreCoordinator;
}

@end
