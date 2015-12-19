//
//  XAIDataStorage.m
//  XAIDataStorage
//
//  Created by Xeon Xai <xeonxai@me.com> on 2/15/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "XAIDataStorage.h"
#import "XAIDataStorageNotification.h"

/** XAILogging */
#import "NSError+XAILogging.h"
#import "NSException+XAILogging.h"

/** XAIUtilities */
#import "NSString+XAIUtilities.h"
#import "NSURL+XAIUtilities.h"

@interface XAIDataStorage()

- (void)contextDidSaveWithNotification:(NSNotification *)notification;
- (void)contextObjectsDidChangeWithNotification:(NSNotification *)notification;

@property (nonatomic, copy, readwrite) NSString *managedObjectModelName;

@end

@implementation XAIDataStorage

@synthesize managedObjectContext       = _managedObjectContext;
@synthesize managedObjectModel         = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModelName     = _managedObjectModelName;

/** Shared Instance */
static XAIDataStorage *_dataStorageInstance;

#pragma mark - Init

+ (XAIDataStorage *)sharedStorage {
    if (_dataStorageInstance != nil ) {
        if (_dataStorageInstance.managedObjectModelName == nil) {
            NSString *reasonString = [[NSString alloc] initWithFormat:@"The method `%@` was called out of order.", NSStringFromSelector(_cmd)];

            @throw([NSException exceptionWithName:@"XAIDataStorageException" reason:reasonString userInfo:nil]);
        }
        
        return _dataStorageInstance;
    }
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _dataStorageInstance = [[XAIDataStorage alloc] initWithModelName:[[self class] description]];
    });
    
    return _dataStorageInstance;
}

+ (XAIDataStorage *)sharedStorageWithModelName:(NSString *)modelName {
    if (_dataStorageInstance != nil) {
        NSString *reasonString = [[NSString alloc] initWithFormat:@"The method `%@` was called out of order.", NSStringFromSelector(_cmd)];
        
        @throw([NSException exceptionWithName:@"XAIDataStorageException" reason:reasonString userInfo:nil]);
        
        return _dataStorageInstance;
    }
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _dataStorageInstance = [[XAIDataStorage alloc] initWithModelName:modelName];
    });
    
    return _dataStorageInstance;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        /** Begin observing notifications for data changes. */
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidSaveWithNotification:) name:NSManagedObjectContextDidSaveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextObjectsDidChangeWithNotification:) name:NSManagedObjectContextObjectsDidChangeNotification object:nil];
    }
    
    return self;
}

- (instancetype)initWithModelName:(NSString *)modelName {
    self = [self init];
    
    if (self) {
        _managedObjectModelName = modelName;
    }
    
    return self;
}

#pragma mark - Memory Management
- (void)dealloc {
    /** End notifications. */
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    #if !__has_feature(objc_arc)
        [_managedObjectContext release];
        [_managedObjectModel release];
        [_persistentStoreCoordinator release];
    
        [super dealloc];
    #endif
}

#pragma mark - NSNotification

- (void)mergeChanges:(NSNotification *)notification {
    if (DEBUG) {
        NSLog(@"Merging changes with notification: %@", notification);
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
    NSManagedObjectContext *moc = self.managedObjectContext;
    
    if (moc != nil) {
        [moc performBlockAndWait:^{
            @try {
                NSError *error = nil;
                
                if ([moc hasChanges] && ![moc save:&error]) {
                    [error logDetailsFailedOnSelector:_cmd line:__LINE__];
                }
            } @catch (NSException *exception) {
                [exception logDetailsFailedOnSelector:_cmd line:__LINE__ onClass:[[self class] description]];
            }
        }];
    }
}

#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        
        if (coordinator != nil) {
            NSUndoManager *undoManager = [[NSUndoManager alloc] init];
            
            _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            
            [_managedObjectContext setUndoManager:undoManager];
            [_managedObjectContext setPersistentStoreCoordinator:coordinator];
            [_managedObjectContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
            
            #if !__has_feature(objc_arc)
                [undoManager release];
            #endif
        }
    });
    
    return _managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:self.managedObjectModelName withExtension:@"momd"];
        
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    });
    
    return _managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        
        // Disabling the WAL setting.
        // TODO: Update to handle the iOS 7 WAL settings and remove this in the future.
        NSMutableDictionary *pragmaOptions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"DELETE", @"journal_mode", nil];
        
        // Base persistance settings.
        NSDictionary *storageOptions       = @{NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES, NSSQLitePragmasOption: pragmaOptions};
        NSError *persistantStoreLoadError  = nil;
        NSString *persistantStorePath      = [NSString applicationPathForFileName:self.managedObjectModelName ofType:@"sqlite"];
        NSURL *persistantStoreURL          = [[NSURL alloc] initFileURLWithPath:persistantStorePath];
        
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:persistantStoreURL options:storageOptions error:&persistantStoreLoadError]) {
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
    });
    
    return _persistentStoreCoordinator;
}

@end
