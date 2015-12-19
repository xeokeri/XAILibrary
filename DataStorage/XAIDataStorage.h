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
    
}

@property (nonatomic, copy, readonly)   NSString                     *managedObjectModelName;
@property (nonatomic, strong, readonly) NSManagedObjectContext       *managedObjectContext;
@property (nonatomic, strong, readonly) NSManagedObjectModel         *managedObjectModel;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

/**
 * For the first call, use this. Must be called before using any XAIDataStorageQuery loading.
 *
 * NOTE: The "modelName" is the name of the CoreData .xcdatamodeld file, excluding the .xcdatamodeld extension.
 */
+ (XAIDataStorage *)sharedStorageWithModelName:(NSString *)modelName;

/**
 * For all subsequent calls, use this. Uses the "XAIDataStorage" model name by default, if the previous method with model name was not called.
 */
+ (XAIDataStorage *)sharedStorage;

- (void)mergeChanges:(NSNotification *)notification;
- (void)saveContext;

@end
