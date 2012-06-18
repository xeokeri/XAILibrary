//
//  XAIImageCacheStorage.m
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 4/15/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "XAIImageCacheStorage.h"
#import "XAIImageCacheDefines.h"
#import "NSString+XAIImageCache.h"

/** XAILogging */
#import "NSError+XAILogging.h"

@implementation XAIImageCacheStorage

#pragma mark - Init XAIImageCache

+ (XAIImageCacheStorage *)sharedStorage {
    static XAIImageCacheStorage *instanceStorage;
    
    @synchronized(self) {
        if (!instanceStorage) {
            NSAssert(instanceStorage == nil, @"InstanceStorage should be nil.");
            
            instanceStorage = [[self alloc] init];
            
            /** Create the image cache folder. */
            NSError *error             = nil;
            NSArray *cachePaths        = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSString *cacheFolder      = [[cachePaths lastObject] stringByAppendingPathComponent:kXAIImageCacheDirectoryPath];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            if (![fileManager fileExistsAtPath:cacheFolder]) {
                
                [fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:NO attributes:nil error:&error];
                
                if (error != nil) {
                    [error logDetailsFailedOnSelector:_cmd line:__LINE__];
                }
            }
        }
    }
    
    NSAssert(instanceStorage, @"InstanceStorage should not be nil.");
    
    return instanceStorage;
}

- (void)saveImage:(UIImage *)image forURL:(NSString *)imageURL {
    NSData *imageData   = [NSData dataWithData:UIImagePNGRepresentation(image)];
    NSArray *cachePath  = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *imagePath = [[cachePath lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:kXAIImageCacheFileNamePath, kXAIImageCacheDirectoryPath, [imageURL md5HexEncode]]];
    
    [imageData writeToFile:imagePath atomically:YES];
}

@end
