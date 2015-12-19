//
//  XAIDataStorageNotification.h
//  XAIDataStorage
//
//  Created by Xeon Xai <xeonxai@me.com> on 6/8/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

COREDATA_EXTERN NSString * const XAIDataStorageManagedObjectContextDidSaveNotification;
COREDATA_EXTERN NSString * const XAIDataStorageManagedObjectContextObjectsDidChangeNotification;

@interface XAIDataStorageNotification : NSObject

@end
