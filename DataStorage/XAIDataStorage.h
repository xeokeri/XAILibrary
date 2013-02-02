//
//  XAIDataStorage.h
//  XAIDataStorage
//
//  Created by Xeon Xai <xeonxai@me.com> on 2/15/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface XAIDataStorage : NSObject {
    NSManagedObjectContext       *managedObjectContext;
    NSManagedObjectModel         *managedObjectModel;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSString                     *modelStorageName;
}

@property (nonatomic, strong, readonly) NSManagedObjectContext       *managedObjectContext;
@property (nonatomic, strong, readonly) NSManagedObjectModel         *managedObjectModel;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readonly) NSString                     *modelStorageName;

/**
 * For the first time, use this.
 * The default is "CoreDataModel" for the model storage name.
 */
+ (XAIDataStorage *)sharedStorageWithName:(NSString *)storageName;

/**
 * For all subsequent calls, use this.
 */
+ (XAIDataStorage *)sharedStorage;

- (void)mergeChanges:(NSNotification *)notification;
- (void)saveContext;
- (void)lockContext;
- (void)unlockContext;
- (NSURL *)applicationDocumentsDirectory;

@end