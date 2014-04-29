//
//  NSString+XAIUtilities.m
//  XAILibrary Category
//
//  Created by Xeon Xai <xeonxai@me.com> on 4/28/14.
//  Copyright (c) 2014 Black Panther White Leopard. All rights reserved.
//

#import "NSString+XAIUtilities.h"

@implementation NSString (XAIUtilities)

#pragma mark - Application's Documents Directory

/**
 Returns the base path to the applications's Document directory. (For use with prepoplated SQLite file)
 */
+ (NSString *)applicationPathForDocumentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *basePath = ([paths count] > 0) ? paths[0] : nil;
    
    return basePath;
}

+ (NSString *)applicationPathForFileName:(NSString *)fileName ofType:(NSString *)fileType {
    NSString *storeName        = [NSString stringWithFormat:@"%@.%@", fileName, fileType];
    NSString *storePath        = [[self applicationPathForDocumentsDirectory] stringByAppendingPathComponent:storeName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error             = nil;
    
    if (![fileManager fileExistsAtPath:storePath]) {
        NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:fileName ofType:fileType];
        
        if (defaultStorePath) {
            if (![fileManager copyItemAtPath:defaultStorePath toPath:storePath error:&error]) {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            }
        }
    }
    
    return storePath;
}

@end
